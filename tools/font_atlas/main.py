from PIL import Image, ImageDraw, ImageFont
import json
import math
import logging

# --- Config ---
FONT_PATH = "font.ttf"      # Path to your .ttf or .otf font
FONT_SIZE = 64                   # Font size in px
PADDING = 4                      # Padding around each glyph
OUTPUT_IMAGE = "atlas.png"
OUTPUT_JSON = "atlas.json"

# Character set (Latin, Cyrillic, numbers, special symbols)
CHARS = (
    "abcdefghijklmnopqrstuvwxyz"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "0123456789"
    "абвгдеёжзийклмнопрстуфхцчшщъыьэюяії"
    "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯІЇ"
    "()[]{}.,:;!?+-=*/<>_\"'`~@#$%^&|\\ "
)

logging.basicConfig(level=logging.INFO, format="%(message)s")

def main():
    logging.info("Loading font...")
    font = ImageFont.truetype(FONT_PATH, FONT_SIZE)

    ascent, descent = font.getmetrics()
    logging.info(f"Font metrics: ascent={ascent}, descent={descent}")

    # Estimate glyph sizes
    max_w, max_h = 0, 0
    for ch in CHARS:
        bbox = font.getbbox(ch)
        w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
        max_w = max(max_w, w)
        max_h = max(max_h, h)

    # Estimate atlas size
    cols = int(math.ceil(math.sqrt(len(CHARS))))
    rows = int(math.ceil(len(CHARS) / cols))
    atlas_w = cols * (max_w + PADDING)
    atlas_h = rows * (max_h + PADDING)
    logging.info(f"Atlas size: {atlas_w}x{atlas_h}")

    # Transparent RGBA atlas
    atlas = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))

    glyph_data = {}
    x, y = 0, 0
    row_h = 0

    for ch in CHARS:
        bbox = font.getbbox(ch)
        w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]

        # new row if needed
        if x + w + PADDING > atlas_w:
            x = 0
            y += row_h + PADDING
            row_h = 0

        # Create a mask for the glyph
        mask = font.getmask(ch, mode="L")
        glyph_img = Image.new("L", (w, h), 0)
        glyph_img.putdata(list(mask))

        # Convert to RGBA white
        glyph_rgba = Image.new("RGBA", (w, h), (255, 255, 255, 0))
        glyph_rgba.putalpha(glyph_img)

        # Paste at correct position
        atlas.paste(glyph_rgba, (x, y), glyph_rgba)

        # Save metadata (important: baseline offset!)
        glyph_data[ch] = {
            "x": x,
            "y": y,
            "w": w,
            "h": h,
            "xoffset": bbox[0],
            "yoffset": ascent - bbox[3],   # baseline correction
            "xadvance": font.getlength(ch)
        }

        x += w + PADDING
        row_h = max(row_h, h)

    logging.info("Saving atlas image...")
    atlas.save(OUTPUT_IMAGE)

    logging.info("Saving JSON metadata...")
    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(glyph_data, f, ensure_ascii=False, indent=2)

    logging.info("Done!")

if __name__ == "__main__":
    main()
