# Findings: a PNG of each screenshot, drawn by WebKit (#650)

Question (D23 in `features/598-screenshot-capture.md`): which route to WebKit
writes a PNG whose width and height in pixels are the SVG's, Quick Look with
`sips`, or a Swift snapshot helper?

Measured 2026-10-01 on macOS 26.6.2 (Apple silicon, Retina display), on the four
committed images in `images/screenshots/` (1548 x 450, 676.8 x 240 twice,
403.2 x 450: dark background) and one light-background crop of the synthetic
Tomcat fixture's histograms (1548 x 240), written by `build/capture-screenshots.pl`.

## Routes

| Route | How | Files |
|---|---|---|
| Swift snapshot | the SVG loaded as a document in an off-screen `WKWebView` sized to it, `takeSnapshot` of its rectangle, drawn into a bitmap of round(width) x round(height) pixels | `snapshot.swift` |
| Quick Look, fitted to 768 | the SVG's width set to 768 units, its height in proportion (the route in `docs/process/screenshots.md` § Looking at an image), `qlmanage -t -s <width>` | shell, below |
| Quick Look, square canvas | width and height set to 768, the view box made a square of the larger side, `qlmanage -t -s <larger side>`, then `sips -c H W --cropOffset 0 0` | shell, below |

`compare.pl` compares two PNGs pixel by pixel over the image's area, read
through `sips` as BMP.

## Results

**Size.** The Swift route writes exactly round(width) x round(height): 1548 x 450,
677 x 240, 403 x 450. Quick Look writes a square of the size asked for in every
case (677 x 677, 1548 x 1548, 403 x 403); the image sits at the top with blank
space below, so it has to be cropped afterwards.

**Images taller than wide are cut by Quick Look.** The heatmap crop (403.2 x 450),
fitted to 768 wide and drawn at 403, came out 403 x 403, with the bottom 47 rows of
pixels (the scale row under the heatmap) missing. Fitted to 768 high instead, Quick
Look still lays the page out to its width and cut the image at the right.

**The crop after Quick Look is not reliable.** The square-canvas route, cropped with
`sips -c 450 403 --cropOffset 0 0`, came out shifted: the left edge of the heatmap
crop's first column of text was cut off. Against the Swift render, 39,304 of
181,350 pixels differed by more than 64 in a channel (heatmap crop), and 190,460 of
696,600 (whole timeline).

**Where both draw the whole image, they agree in layout but not pixel for pixel.**
Quick Look fitted to 768 (wide images only, compared over the image's area):

| Image | Pixels | Differ by > 8 | Differ by > 64 | Largest |
|---|---|---|---|---|
| access, bytes histogram (677 x 240) | 162,480 | 15,705 | 4,272 | 180 |
| access, duration histogram (677 x 240) | 162,480 | 16,025 | 4,643 | 190 |
| heatmap-5min, timeline (1548 x 450) | 696,600 | 100,665 | 22,954 | 190 |

Looked at side by side, layout, colours and glyphs are the same; the differences
are in antialiasing of text and line edges. Quick Look draws the 768-unit page
scaled to the requested size; the Swift route draws at the display's scale (2x)
and resamples to 1x. The cause was not taken further.

**Colours.** The Swift route's corner pixel is the tool's background exactly:
`#191d27` on the dark images (the "Clear Dark" background in
`build/capture-screenshots.pl`), `#ffffff` on the light one.

**Repeatable.** Each of the four images rendered twice through the Swift route gave
byte-identical PNGs.

**Cost.** Swift route, per image: 0.52 s compiled (5 runs, 0.51 to 0.52), 0.94 s
run as a script with `swift snapshot.swift` (warm; 4.6 s on the very first run).
Compiling with `swiftc -O`: 0.75 to 0.77 s warm, 47 s on the very first compile of
the session (module cache). Quick Look: 0.13 to 0.22 s per image. Both need nothing
installed: `swift` and `swiftc` come with the Xcode command line tools.

**Fractional widths.** A cell is 7.2 units wide, so most images are not a whole
number of units wide (676.8, 403.2). The Swift route rounds to the nearest pixel
and draws the snapshot into that width, a horizontal scale of 677 / 676.8
(0.03%).

## Conclusion

The Swift snapshot route meets the requirement directly: the PNG's size is the
SVG's, rounded, for wide and tall images alike, on the tool's exact background
colours, byte-identical across runs, at about half a second per image. Quick Look
gives a square that must be cropped, cuts images taller than wide, and the crop
through `sips` misplaced the image in the one route that would handle every shape.
