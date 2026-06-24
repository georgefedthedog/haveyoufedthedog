#!/usr/bin/env python3
"""
Split generated avatar pose/grid sheets into individual square avatars.

Context / why this exists
-------------------------
We generate avatars as 5x5 contact sheets (one big square PNG, 25 avatars per
sheet, thin white gutters between cells) using an image model, then need them
as individual square files named free_avatar_NNN.png for the catalog.

Two non-obvious things this handles (both learned the hard way):

1. The grid is NOT uniform. Columns land on a clean ~250px step, but the
   ROW gutters drift per sheet (the model doesn't space rows evenly). Cutting
   on an assumed uniform grid offsets every face - clips the top of the head
   and includes a slice of the neighbour below. So we DETECT the white
   gutter lines per sheet (whiteness profile -> bands) and cut between them.

2. The cells are portrait (taller than wide). Squaring by centre-cropping to
   the short side lops off hair-buns on top and shoulders on the bottom.
   Instead we keep the FULL cell content and pad the short side to square with
   edge-replicate padding (mode='edge'), so the fill matches the pastel
   background / shoulders seamlessly with no white border and zero crop loss.

Output is 500x500 (matches the existing catalog avatars) full-bleed, no border.

Usage
-----
  python split_avatar_sheets.py                       # temp/avatars_raw_*.png -> temp/free_avatars/
  python split_avatar_sheets.py --in DIR --out DIR    # custom folders
  python split_avatar_sheets.py --shuffle 1-125       # randomise numbering over a
                                                       #   slot range so the model's
                                                       #   per-sheet grouping (similar
                                                       #   faces/ages clustered together)
                                                       #   doesn't show up in sort order

Input  : <in>/avatars_raw_1.png, avatars_raw_2.png, ...  (numeric order = output order)
Output : <out>/free_avatar_001.png ...                   (zero-padded, sequential)

Note: sheets can be people OR object/icon avatars - the split is identical
either way. When we last ran this there were 7 sheets: 1-5 people, 6-7 icons.

Naming convention for the catalog (all FREE, no packs):
  - people  -> human_avatar_NNN     (manifest sort_order 1000+, shuffled)
  - icons    -> non_human_avatar_NNN (manifest sort_order 2000+, in order)
Produce that by running each group separately, e.g. (people sheets in temp/):
  python split_avatar_sheets.py --prefix human_avatar_ --shuffle 1-125
  python split_avatar_sheets.py --prefix non_human_avatar_     # icon sheets
"""
import argparse
import glob
import os
import random
import re
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
GRID = 5            # 5x5 sheet
OUT_SIZE = 500      # match existing catalog avatars
WHITE = 235         # a pixel is "white-ish" if all channels exceed this
GUTTER_FRAC = 0.55  # a row/col is gutter if this fraction of it is white-ish
MERGE_GAP = 10      # merge gutter pixels separated by <= this many px
INSET = 1           # shave this many px off each cell edge (dodge antialiased white)


def _bands(frac):
    """Group indices where whiteness > GUTTER_FRAC into (start, end) bands."""
    idx = np.where(frac > GUTTER_FRAC)[0]
    if len(idx) == 0:
        return []
    bands, s, p = [], idx[0], idx[0]
    for i in idx[1:]:
        if i <= p + MERGE_GAP:
            p = i
        else:
            bands.append((int(s), int(p)))
            s, p = i, i
    bands.append((int(s), int(p)))
    return bands


def split_sheet(path):
    """Return 25 square PIL.Images, row-major, cut on detected gutters."""
    im = Image.open(path).convert("RGB")
    a = np.asarray(im)
    white = (a > WHITE).all(axis=2)
    cols = _bands(white.mean(axis=0))
    rows = _bands(white.mean(axis=1))
    if len(cols) != GRID + 1 or len(rows) != GRID + 1:
        sys.exit(f"ERROR: {os.path.basename(path)}: detected {len(cols)} col / "
                 f"{len(rows)} row gutters, expected {GRID + 1} each. "
                 f"Tune WHITE / GUTTER_FRAC.")
    out = []
    for r in range(GRID):
        for c in range(GRID):
            x0, x1 = cols[c][1] + 1 + INSET, cols[c + 1][0] - INSET
            y0, y1 = rows[r][1] + 1 + INSET, rows[r + 1][0] - INSET
            cell = a[y0:y1, x0:x1]
            h, w = cell.shape[:2]
            side = max(h, w)
            ph, pw = side - h, side - w
            padded = np.pad(cell,
                            ((ph // 2, ph - ph // 2), (pw // 2, pw - pw // 2), (0, 0)),
                            mode="edge")
            out.append(Image.fromarray(padded).resize((OUT_SIZE, OUT_SIZE), Image.LANCZOS))
    return out


def parse_range(spec):
    """'1-125' -> (1, 125)."""
    m = re.fullmatch(r"\s*(\d+)\s*-\s*(\d+)\s*", spec)
    if not m:
        sys.exit(f"ERROR: --shuffle expects 'A-B', got {spec!r}")
    a, b = int(m.group(1)), int(m.group(2))
    if a > b:
        a, b = b, a
    return a, b


def main():
    ap = argparse.ArgumentParser(description="Split 5x5 avatar sheets into squares.")
    ap.add_argument("--in", dest="indir", default=os.path.join(HERE, "temp"),
                    help="folder of avatars_raw_*.png (default: temp/)")
    ap.add_argument("--out", dest="outdir", default=os.path.join(HERE, "temp", "free_avatars"),
                    help="output folder (default: temp/free_avatars/)")
    ap.add_argument("--prefix", default="free_avatar_", help="output filename prefix")
    ap.add_argument("--shuffle", default="", metavar="A-B",
                    help="randomise the numbering across slots A..B (e.g. 1-125)")
    ap.add_argument("--seed", type=int, default=None, help="RNG seed for reproducible shuffle")
    args = ap.parse_args()

    sheets = sorted(glob.glob(os.path.join(args.indir, "avatars_raw_*.png")),
                    key=lambda p: int(re.search(r"(\d+)", os.path.basename(p)).group(1)))
    if not sheets:
        sys.exit(f"ERROR: no avatars_raw_*.png in {args.indir}")
    os.makedirs(args.outdir, exist_ok=True)

    cells = []
    for s in sheets:
        c = split_sheet(s)
        print(f"  {os.path.basename(s):20} -> {len(c)} avatars")
        cells += c
    print(f"Total: {len(cells)} avatars from {len(sheets)} sheets")

    # Default numbering is sequential (slot i -> cell i). A --shuffle range
    # reorders which cell lands in each slot within that range only.
    order = list(range(len(cells)))
    if args.shuffle:
        a, b = parse_range(args.shuffle)
        a, b = max(1, a), min(len(cells), b)
        if args.seed is not None:
            random.seed(args.seed)
        window = order[a - 1:b]
        random.shuffle(window)
        order[a - 1:b] = window
        print(f"Shuffled slots {a}-{b} (seed={args.seed})")

    for slot, cell_idx in enumerate(order, start=1):
        cells[cell_idx].save(os.path.join(args.outdir, f"{args.prefix}{slot:03d}.png"))
    print(f"Wrote {len(order)} files to {args.outdir}")


if __name__ == "__main__":
    main()
