from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path("/Users/bobkitchen/Desktop/CleanShot 2026-06-13 at 21.00.15@2x.png")
OUTPUT = ROOT / "screenshots" / "model-meter-popover-full-graph.png"


def font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    # SFNS is the same family SwiftUI uses for this macOS popover.
    return ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size=size)


def rounded(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], radius: int, fill: tuple[int, int, int, int]) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def tinted_icon(name: str, size: int, color: tuple[int, int, int, int]) -> Image.Image:
    source = Image.open(ROOT / "Assets" / name).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)
    alpha = source.getchannel("A")
    icon = Image.new("RGBA", source.size, color)
    icon.putalpha(alpha)
    return icon


def plot_point(
    left: int,
    top: int,
    width: int,
    height: int,
    hour: float,
    percent: float,
) -> tuple[float, float]:
    return (
        left + width * (hour / 24.0),
        top + height * (1.0 - percent / 100.0),
    )


def draw_series(
    draw: ImageDraw.ImageDraw,
    left: int,
    top: int,
    width: int,
    height: int,
    values: list[tuple[float, float]],
    color: tuple[int, int, int, int],
    background: tuple[int, int, int, int],
) -> None:
    points = [plot_point(left, top, width, height, hour, percent) for hour, percent in values]
    draw.line(points, fill=color, width=4, joint="curve")
    for x, y in points:
        r = 3
        draw.ellipse((x - r, y - r, x + r, y + r), fill=color)
        draw.ellipse((x - r - 1, y - r - 1, x + r + 1, y + r + 1), outline=background, width=1)


def main() -> None:
    image = Image.open(SOURCE).convert("RGBA")
    draw = ImageDraw.Draw(image)

    bg = (30, 30, 30, 255)
    grid = (98, 98, 102, 82)
    axis = (158, 158, 164, 255)
    text = (232, 232, 235, 255)
    control = (59, 59, 61, 255)
    blue = (25, 145, 255, 255)
    green = (48, 220, 97, 255)
    purple = (218, 57, 238, 255)

    title_font = font(28)
    axis_font = font(18)
    control_font = font(28)

    # Redraw only the graph block inside the popover.
    graph_box = (130, 214, 1004, 600)
    draw.rectangle(graph_box, fill=bg)

    # Header.
    draw.text((150, 239), "5-hour usage by hour", fill=text, font=title_font)

    seg_x, seg_y, seg_w, seg_h = 773, 223, 174, 48
    rounded(draw, (seg_x, seg_y, seg_x + seg_w, seg_y + seg_h), 10, control)
    rounded(draw, (seg_x, seg_y, seg_x + seg_w // 2, seg_y + seg_h), 10, blue)
    draw.text((seg_x + 20, seg_y + 8), "24h", fill=(255, 255, 255, 255), font=control_font)
    draw.text((seg_x + 118, seg_y + 8), "7d", fill=(232, 232, 235, 235), font=control_font)

    label_left = 150
    plot_left = 225
    plot_right = 971
    plot_top = 299
    plot_bottom = 487
    plot_width = plot_right - plot_left
    plot_height = plot_bottom - plot_top

    for i, label in enumerate(["100%", "75%", "50%", "25%", "0%"]):
        y = plot_top + round(i * plot_height / 4)
        draw.text((label_left, y - 12), label, fill=axis, font=axis_font)
        draw.line((plot_left, y, plot_right, y), fill=grid, width=1)

    codex = [
        (0.4, 18), (1.8, 22), (3.2, 20), (4.8, 31), (6.2, 35), (7.8, 43),
        (9.3, 40), (10.8, 51), (12.2, 56), (13.8, 63), (15.3, 67),
        (16.8, 74), (18.2, 70), (19.8, 61), (21.3, 54), (23.5, 43),
    ]
    claude = [
        (0.4, 3), (1.8, 5), (3.2, 4), (4.8, 8), (6.2, 9), (7.8, 7),
        (9.3, 13), (10.8, 15), (12.2, 14), (13.8, 18), (15.3, 22),
        (16.8, 25), (18.2, 21), (19.8, 19), (21.3, 17), (23.5, 14),
    ]
    gemini = [
        (0.4, 0), (1.8, 1), (3.2, 1), (4.8, 2), (6.2, 2), (7.8, 3),
        (9.3, 2), (10.8, 3), (12.2, 4), (13.8, 4), (15.3, 5),
        (16.8, 4), (18.2, 3), (19.8, 2), (21.3, 2), (23.5, 1),
    ]
    draw_series(draw, plot_left, plot_top, plot_width, plot_height, codex, green, bg)
    draw_series(draw, plot_left, plot_top, plot_width, plot_height, claude, purple, bg)
    draw_series(draw, plot_left, plot_top, plot_width, plot_height, gemini, blue, bg)

    draw.text((203, 505), "9 PM", fill=axis, font=axis_font)
    draw.text((576, 505), "9 AM", fill=axis, font=axis_font)
    draw.text((915, 505), "9 PM", fill=axis, font=axis_font)

    legend_y = 542
    legend_x = 150
    icon_size = 33
    legend = [
        ("ChatGPT-Logo.png", green),
        ("claude-transparent-custom.png", purple),
        ("google-gemini-logomark-black-24439_32.png", blue),
    ]
    for icon_name, color in legend:
        image.alpha_composite(tinted_icon(icon_name, icon_size, (234, 234, 236, 245)), (legend_x, legend_y))
        draw.ellipse((legend_x + 43, legend_y + 11, legend_x + 59, legend_y + 27), fill=color)
        legend_x += 110

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    main()
