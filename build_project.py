"""
High-level build system for Blip projects.

Key features:
- Preserves arbitrary folder structure (no forced /modules,/textures,...).
- Single global `_DIR` with nested tables mirroring your folders.
- Scripts are registered as lazy loader functions and initialized only by `_INIT_ALL()`.
- Assets are downloaded via HTTP with a progress bar; models (`.glb`) are loaded via `Assets:Load`.
- Deterministic ordering, duplicate-key detection, colored logs, rich error reporting.
- Entry flow: `Client.OnStart()` → `_INIT_ALL()` → (kickoff downloads) → `_start_game()` after all assets ready.
- `main.lua` entrypoints `_ON_START_CLIENT` and `_ON_START` are extracted and wired automatically.
- Predictable name mapping: each path segment is lowercased and slugified; assets become `<stem>_<ext>` to avoid collisions with scripts.

Example mapping:
  source/player/player.lua        → _DIR.player.player
  source/player/texture.png       → _DIR.player.texture_png
  source/physics/drop.mp3         → _DIR.physics.drop_mp3
  source/world/map.glb            → _DIR.world.map_glb   -- stores loaded asset array

"""
import os
import re
import random
from dataclasses import dataclass
from typing import List, Tuple
from colorama import init, Fore, Style
init(autoreset=True)

# -----------------------------
# Console colors for the builder
# -----------------------------
class Color:
    RESET = Style.RESET_ALL
    RED = Fore.RED
    GREEN = Fore.GREEN
    YELLOW = Fore.YELLOW
    BLUE = Fore.BLUE
    CYAN = Fore.CYAN



def log_info(msg: str):
    print(f"{Color.BLUE}[INFO]{Color.RESET} {msg}")


def log_ok(msg: str):
    print(f"{Color.GREEN}[OK]{Color.RESET}   {msg}")


def log_warn(msg: str):
    print(f"{Color.YELLOW}[WARN]{Color.RESET} {msg}")


def log_err(msg: str):
    print(f"{Color.RED}[ERROR]{Color.RESET} {msg}")


# -----------------------------
# Config
# -----------------------------
@dataclass
class BuildConfig:
    source_dir: str = "source"
    output_file: str = "build/build.lua"
    github_base_url: str = "https://raw.githubusercontent.com/Nanskip/the-button/refs/heads/main"
    strip_lua_comments: bool = True
    ignore_dirs: Tuple[str, ...] = (".git", "build", ".idea", ".vscode")
    # File extensions considered scripts/assets
    script_ext: Tuple[str, ...] = (".lua",)
    model_ext: Tuple[str, ...] = (".glb",)
    blob_ext: Tuple[str, ...] = (".png", ".jpg", ".jpeg", ".mp3", ".wav", ".ogg", ".json", ".txt")


# -----------------------------
# Helpers
# -----------------------------

def slugify(segment: str) -> str:
    s = segment.lower()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = re.sub(r"_+", "_", s)
    return s.strip("_") or "_"


def relpath_unix(path: str, root: str) -> str:
    rel = os.path.relpath(path, root)
    return rel.replace("\\", "/")


# -----------------------------
# Lua utilities
# -----------------------------

def remove_lua_comments(code: str) -> str:
    """Remove -- line comments while keeping strings intact."""
    out = []
    in_string = False
    string_char = ''
    i = 0
    while i < len(code):
        c = code[i]
        if in_string:
            out.append(c)
            if c == string_char and (i == 0 or code[i - 1] != "\\"):
                in_string = False
            i += 1
        else:
            if c in ('"', "'"):
                in_string = True
                string_char = c
                out.append(c)
                i += 1
            elif c == '-' and i + 1 < len(code) and code[i + 1] == '-':
                while i < len(code) and code[i] != '\n':
                    i += 1
            else:
                out.append(c)
                i += 1
    return ''.join(out)


def extract_function_body(src: str, fname: str) -> str:
    # Matches: _ON_START = function(...) ... end  (greedy safe with DOTALL)
    pattern = rf"{re.escape(fname)}\s*=\s*function\s*\([^)]*\)\s*(.*?)\s*end"
    m = re.search(pattern, src, flags=re.DOTALL)
    if m:
        return m.group(1).strip()
    return ""


# -----------------------------
# Scanning & classification
# -----------------------------
@dataclass
class ScriptFile:
    rel_path: str
    dotted: str  # e.g., player.player
    code: str


@dataclass
class AssetFile:
    rel_path: str
    dotted: str  # e.g., player.texture_png
    url: str
    kind: str    # 'model' or 'blob'


def classify_path(cfg: BuildConfig, rel: str) -> str:
    _, ext = os.path.splitext(rel)
    ext = ext.lower()
    if ext in cfg.script_ext:
        return 'script'
    if ext in cfg.model_ext:
        return 'model'
    if ext in cfg.blob_ext:
        return 'blob'
    return 'blob'  # default: treat as downloadable blob


def dotted_from_rel(rel: str, is_asset: bool) -> str:
    parts = rel.split('/')
    stem, ext = os.path.splitext(parts[-1])
    parts[-1] = slugify(stem)
    parts = [slugify(p) for p in parts]
    dot = '.'.join(parts)
    if is_asset:
        return f"{dot}_{slugify(ext[1:])}" if ext else dot
    else:
        return dot


def collect(cfg: BuildConfig) -> Tuple[List[ScriptFile], List[AssetFile]]:
    scripts: List[ScriptFile] = []
    assets: List[AssetFile] = []

    base_url = cfg.github_base_url.rstrip('/')
    for root, dirs, files in os.walk(cfg.source_dir):
        # prune ignored dirs
        dirs[:] = [d for d in dirs if d not in cfg.ignore_dirs and not d.startswith('.')]
        for f in files:
            full = os.path.join(root, f)
            rel = relpath_unix(full, cfg.source_dir)
            # always skip output file if it sits under source (edge-case)
            if os.path.abspath(full) == os.path.abspath(cfg.output_file):
                continue
            kind = classify_path(cfg, rel)
            if kind == 'script':
                with open(full, 'r', encoding='utf-8') as fp:
                    code = fp.read()
                if cfg.strip_lua_comments:
                    code = remove_lua_comments(code)
                dotted = dotted_from_rel(rel, is_asset=False)
                scripts.append(ScriptFile(rel, dotted, code))
            else:
                dotted = dotted_from_rel(rel, is_asset=True)
                url = f"{base_url}/source/{rel}"
                assets.append(AssetFile(rel, dotted, url, kind if kind in ('model', 'blob') else 'blob'))

    # Deterministic order
    scripts.sort(key=lambda s: s.dotted)
    assets.sort(key=lambda a: a.rel_path)
    return scripts, assets


def assert_no_duplicates(scripts: List[ScriptFile], assets: List[AssetFile]):
    seen = {}
    for s in scripts:
        if s.dotted in seen:
            raise ValueError(f"Duplicate dotted key for scripts: {s.dotted} ({seen[s.dotted]} vs {s.rel_path})")
        seen[s.dotted] = s.rel_path
    for a in assets:
        if a.dotted in seen:
            raise ValueError(f"Asset key collides with script key: {a.dotted} (script: {seen[a.dotted]}, asset: {a.rel_path})\n"
                             f"Use distinct stems or rely on '<stem>_<ext>' asset keys.")
        seen[a.dotted] = a.rel_path


# -----------------------------
# Lua emitters
# -----------------------------
LUA_PREAMBLE = r'''
-- build.lua autogenerated (refactored)

_DIR = { __loaders = {} }
debug = true

_log = function(level, msg)
    local line = '['..level..'] '..tostring(msg)
    if debug and debug.log then debug.log(line) else print(line) end
    if loading_screen and loading_screen.loading_text_update then
        pcall(function() loading_screen:loading_text_update(msg) end)
    end
end

local function __split(s, sep)
    local t = {}
    for part in string.gmatch(s, "([^"..sep.."]+)") do t[#t+1] = part end
    return t
end

local function __ensure_path(root, parts)
    local cur = root
    for i=1,#parts do
        local k = parts[i]
        if cur[k] == nil then cur[k] = {} end
        cur = cur[k]
    end
    return cur
end

local function __set_dotted(root, dotted, value)
    local parts = __split(dotted, '%.')
    local last = parts[#parts]
    parts[#parts] = nil
    local parent = __ensure_path(root, parts)
    parent[last] = value
end

local function _register(dotted, loader)
    _DIR.__loaders[dotted] = loader
end
'''


def indent_lua(src: str, spaces: int) -> str:
    pad = ' ' * spaces
    return '\n'.join(pad + line if line.strip() else '' for line in src.splitlines())


def emit_script_loader(rel_path: str, dotted: str, code: str, is_main: bool, on_start_client: str, on_start: str) -> str:
    if is_main:
        body_client = on_start_client or ""
        body_start = on_start or ""
        return f"""
-- script: {rel_path}
_register('{dotted}', function()
    local M = {{}}
    M._ON_START_CLIENT = function()\n{indent_lua(body_client, 8)}\n    end
    M._ON_START = function()\n{indent_lua(body_start, 8)}\n    end
    return M
end)
"""
    else:
        return f"""
-- script: {rel_path}
_register('{dotted}', function()
    local __ret = (function()\n{indent_lua(code, 8)}\n    end)()
    if __ret == nil then __ret = {{}} end
    return __ret
end)
"""


def emit_assets_table(assets: List[AssetFile]) -> str:
    rows = []
    for a in assets:
        rows.append(f"        {{ path = '{a.rel_path}', url = '{a.url}', dot = '{a.dotted}', kind = '{a.kind}' }}")
    joined = ",\n".join(rows)
    return f"""
local __assets = {{
{joined}
}}
"""


LUA_ASSET_LOADER = r'''
local to_load, loaded = 0, 0
local function _check_ready()
    if loaded >= to_load then
        _log('OK', 'All assets loaded')
        _start_game()
    end
end

local function _store_asset(dot, value)
    __set_dotted(_DIR, dot, value)
end

function _begin_downloads()
    for i, a in ipairs(__assets) do
        to_load = to_load + 1
        _log('INFO', 'Downloading '..a.path)
        HTTP:Get(a.url, function(res)
            if res.StatusCode ~= 200 then
                _log('ERROR', 'Failed '..a.path..' HTTP '..tostring(res.StatusCode))
                loaded = loaded + 1; _check_ready(); return
            end
            if a.kind == 'model' then
                Assets:Load(res.Body, function(assets)
                    if assets == nil then
                        _log('WARN', 'Load failed '..a.path)
                    else
                        _store_asset(a.dot, assets)
                        for _, asset in ipairs(assets) do asset:SetParent(nil) end
                        _log('OK', 'Loaded model '..a.path)
                    end
                    loaded = loaded + 1; _check_ready()
                end, AssetType.AnyObject)
            else
                _store_asset(a.dot, res.Body)
                _log('OK', 'Downloaded '..a.path)
                loaded = loaded + 1; _check_ready()
            end
        end)
    end
end
'''


LUA_STARTUP = r'''
-- Entry points
function _INIT_ALL()
    _log('INFO', 'Initializing modules...')
    local keys = {}
    for k,_ in pairs(_DIR.__loaders) do keys[#keys+1] = k end
    table.sort(keys)
    local okc, errc = 0, 0
    for _,k in ipairs(keys) do
        local ok, ret = pcall(_DIR.__loaders[k])
        if ok then __set_dotted(_DIR, k, ret or {}); okc = okc + 1; _log('INFO', 'loaded '..k)
        else errc = errc + 1; __set_dotted(_DIR, k, { __error = tostring(ret) }); _log('ERROR', k..' -> '..tostring(ret)) end
    end
    _log('OK', ('Modules: %d ok, %d errors'):format(okc, errc))
end

function _start_game()
    if _DIR.main and _DIR.main._ON_START then
        local ok, err = pcall(_DIR.main._ON_START)
        if not ok then _log('ERROR', '_ON_START failed: '..tostring(err)) end
    else
        _log('WARN', 'No main._ON_START provided')
    end
end

Client.OnStart = function()
    _INIT_ALL()
    if _DIR.main and _DIR.main._ON_START_CLIENT then
        local ok, err = pcall(_DIR.main._ON_START_CLIENT)
        if not ok then _log('ERROR', '_ON_START_CLIENT failed: '..tostring(err)) end
    end
    if #__assets == 0 then _log('INFO', 'No assets to load'); _start_game(); return end
    _log('INFO', 'Starting asset downloads ('..tostring(#__assets)..')')
    _begin_downloads()
end
'''

def print_tree(node, prefix=""):
    for name in sorted(k for k in node.keys() if k != "__files__"):
        log_info(f"{prefix}+-- {name}/")
        print_tree(node[name], prefix + "    ")
    for fname in sorted(node.get("__files__", [])):
        log_info(f"{prefix}+-- {fname}")

def generate_build(cfg: BuildConfig) -> str:
    scripts, assets = collect(cfg)
    assert_no_duplicates(scripts, assets)

    # Extract main entry bodies (optional)
    main = next((s for s in scripts if s.rel_path.replace('\\', '/') == 'main.lua'), None)
    on_client, on_start = "", ""
    if main is not None:
        on_client = extract_function_body(main.code, '_ON_START_CLIENT')
        on_start = extract_function_body(main.code, '_ON_START')

    parts = [LUA_PREAMBLE]

    # Register scripts
    for s in scripts:
        is_main = (s is main)
        parts.append(emit_script_loader(s.rel_path, s.dotted, s.code, is_main, on_client, on_start))

    # Assets table + loader
    parts.append(emit_assets_table(assets))
    parts.append(LUA_STARTUP)
    parts.append(LUA_ASSET_LOADER)

    # Final anti-overwrite hash
    parts.append(f"-- hash: {random.randint(100000000, 999999999)}\n")

    return "\n".join(parts)


# -----------------------------
# Entrypoint
# -----------------------------

def build_project(cfg: BuildConfig) -> str:
    try:
        log_info("Collecting project files...")
        scripts, assets = collect(cfg)
        log_ok(f"Found {len(scripts)} scripts, {len(assets)} assets")
        assert_no_duplicates(scripts, assets)

        log_info("Generating build.lua...")
        code = generate_build(cfg)
        os.makedirs(os.path.dirname(cfg.output_file), exist_ok=True)
        with open(cfg.output_file, 'w', encoding='utf-8') as f:
            f.write(code)
        log_info(f"Generated {len(scripts)} modules and {len(assets)} assets")
        log_ok(f"Wrote {cfg.output_file}\n")

        log_info("Project tree:\n")

        def add_path(tree, rel_path: str):
            parts = rel_path.split("/")
            d = tree
            for i, part in enumerate(parts):
                is_last = (i == len(parts) - 1)
                if is_last:
                    d.setdefault("__files__", []).append(part)
                else:
                    d = d.setdefault(part, {})

        tree = {}
        for s in scripts:
            add_path(tree, s.rel_path)
        for a in assets:
            add_path(tree, a.rel_path)

        print_tree(tree)
        print("")

        return cfg.output_file
    except Exception as e:
        log_err(str(e))
        raise

if __name__ == '__main__':
    cfg = BuildConfig(
        source_dir='source',
        output_file='build/build.lua',
        github_base_url='https://raw.githubusercontent.com/Nanskip/NaN-GDK/refs/heads/main',
    )
    out = build_project(cfg)
    log_ok("Build finished.")
