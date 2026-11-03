# Persistent verse sidebar

The left verse rail remains visible at rest. Each chapter renders one segment per verse; CSS grid removes the previous minimum segment height and JavaScript derives a bounded gap from the track height and verse count. The track stays between the top reader toolbar and floating dock. ResizeObserver updates the layout when the reader/track resizes. Active verse and total remain visible, with horizontal magnification that cannot stretch segments vertically out of bounds.

Tap, drag, up/down, Home and End navigation are preserved. Browser verification covered Genesis 1 (31 segments), End navigation to verse 31, chapter switching to Psalm 23 (6 segments), and dragging to verse 6. Mathematical layout tests cover 1, 6, 31, 118, 176 and 300 segments across 0/180/350/700px track heights. Chapters beyond the included sample library are layout test cases, not added Bible content.

Files: verse-sidebar.css; railLayout() in reader-scroll.mjs; mountReader() in app.js. Changes apply to the browser demo.
