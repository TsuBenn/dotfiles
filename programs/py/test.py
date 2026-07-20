import fontforge
font = fontforge.open("/home/tsubenn/.local/share/fonts/Bytesized-Regular.ttf")
widths = set()
for glyph in font.glyphs():
    if glyph.width > 0:
        widths.add(glyph.width)
print(widths)
print(f"Number of distinct widths: {len(widths)}")
