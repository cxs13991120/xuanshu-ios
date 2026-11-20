from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


SIZE = 1024
ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "ios/Xuanshu/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
FONT = Path("C:/Windows/Fonts/simkai.ttf")


def vertical_gradient(top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGB", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    for y in range(SIZE):
        ratio = y / (SIZE - 1)
        color = tuple(round(a + (b - a) * ratio) for a, b in zip(top, bottom))
        draw.line((0, y, SIZE, y), fill=color)
    return image


image = vertical_gradient((183, 55, 46), (121, 25, 22)).convert("RGBA")

glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow)
glow_draw.ellipse((-120, -170, 760, 710), fill=(247, 218, 166, 64))
glow_draw.ellipse((610, 640, 1190, 1210), fill=(83, 18, 16, 64))
glow = glow.filter(ImageFilter.GaussianBlur(90))
image = Image.alpha_composite(image, glow)

draw = ImageDraw.Draw(image)
draw.rounded_rectangle((62, 62, 962, 962), radius=118, outline=(238, 210, 159, 132), width=5)
draw.rounded_rectangle((86, 86, 938, 938), radius=100, outline=(238, 210, 159, 62), width=2)

# Quiet corner marks echo the paper-card border in the app.
for x1, y1, x2, y2 in (
    (128, 128, 284, 128),
    (128, 128, 128, 284),
    (896, 128, 740, 128),
    (896, 128, 896, 284),
    (128, 896, 284, 896),
    (128, 896, 128, 740),
    (896, 896, 740, 896),
    (896, 896, 896, 740),
):
    draw.line((x1, y1, x2, y2), fill=(239, 215, 171, 178), width=4)

font = ImageFont.truetype(str(FONT), 600)
text = "玄"
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]
position = ((SIZE - text_width) / 2 - bbox[0], (SIZE - text_height) / 2 - bbox[1] - 12)

shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
shadow_draw = ImageDraw.Draw(shadow)
shadow_draw.text((position[0] + 4, position[1] + 16), text, font=font, fill=(55, 9, 8, 120))
shadow = shadow.filter(ImageFilter.GaussianBlur(14))
image = Image.alpha_composite(image, shadow)

draw = ImageDraw.Draw(image)
draw.text(position, text, font=font, fill=(252, 243, 226, 255), stroke_width=1, stroke_fill=(255, 250, 238, 255))
draw.ellipse((762, 760, 778, 776), fill=(224, 189, 127, 210))

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
image.convert("RGB").save(OUTPUT, "PNG", optimize=True)
print(OUTPUT)
