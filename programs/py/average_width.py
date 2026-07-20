import fontforge

font = fontforge.open("Bytesized-Regular.ttf")

font.os2_panose = (2, 11, 5, 9, 2, 2, 2, 2, 2, 2)
# Calculate average width across all glyphs
total_width = 0
count = 0
for glyph in font.glyphs():
    if glyph.width > 0:
        total_width += glyph.width
        count += 1

avg_width = total_width // count

# Apply average width to all glyphs
for glyph in font.glyphs():
    glyph.width = avg_width

font.generate("Bytesized-Regular-Averaged.ttf")
