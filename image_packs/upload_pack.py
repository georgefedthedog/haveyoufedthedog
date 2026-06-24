#!/usr/bin/env python3
"""
One-off uploader: publish the foldered character art in this directory to
PocketBase, grouped into sellable/giftable **packs**.

This is a manual publishing helper, NOT part of any committed pipeline. It talks
to the LIVE server, so you run it yourself with superuser credentials.

Model (pack_manifest.json):
  - `packs` list = the groups: all_dogs / all_cats / all_small_pets / all_pets.
    Each is one catalog_packs row (code, enabled, redeemable) + one
    catalog_products row that grants it.
  - Each PAID character lists the pack *keys* it belongs to (e.g. husky ->
    ["all_dogs","all_pets"]); the uploader writes those ids into the character's
    multi-relation `packs` field. A character resolves/sells if the household
    owns ANY of its packs.
  - FREE characters have no packs (general catalog: selectable by everyone).

Price is NOT set here - it lives on each product's store listing in Play Console
+ App Store Connect (see store_products.csv). A product only appears in-app once
the store knows its sku and it's activated.

Idempotent (safe to re-run): packs matched by code, products by sku, characters
by slug; existing rows get text/membership refreshed; images only (re)upload on
create, or with --reupload.

Credentials (never hard-code - read from the environment):
  PB_ADMIN_EMAIL, PB_ADMIN_PASSWORD   (PowerShell: $env:PB_ADMIN_EMAIL=...)

Usage:
  python upload_pack.py --dry-run                 # show the plan, write nothing
  python upload_pack.py                           # create/update everything
  python upload_pack.py --reupload                # also re-push images
  python upload_pack.py --only husky,meds         # just these slugs (packs still ensured)
  python upload_pack.py --verify                  # report live state vs manifest
  python upload_pack.py --set-packs on|off        # bulk enable/disable the group packs
"""
import argparse
import json
import os
import sys

import requests

EXPRESSIONS = ["idle", "happy", "sad", "celebrate", "sleeping", "award"]
DEFAULT_BASE = "https://api.haveyoufedthedog.com"
HERE = os.path.dirname(os.path.abspath(__file__))


def die(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def auth(base, email, password):
    s = requests.Session()
    for path in ("/api/collections/_superusers/auth-with-password",
                 "/api/admins/auth-with-password"):
        try:
            r = s.post(base + path,
                       json={"identity": email, "email": email, "password": password},
                       timeout=30)
        except requests.RequestException as e:
            die(f"cannot reach {base}: {e}")
        if r.status_code == 200:
            s.headers["Authorization"] = r.json()["token"]
            print(f"Authenticated via {path}")
            return s
    die(f"auth failed ({r.status_code}): {r.text[:300]}")


def find_one(s, base, collection, filt):
    r = s.get(f"{base}/api/collections/{collection}/records",
              params={"filter": filt, "perPage": 1}, timeout=30)
    r.raise_for_status()
    items = r.json().get("items", [])
    return items[0] if items else None


def fetch_all(s, base, collection):
    out, page = [], 1
    while True:
        r = s.get(f"{base}/api/collections/{collection}/records",
                  params={"perPage": 200, "page": page, "sort": "created"}, timeout=30)
        r.raise_for_status()
        data = r.json()
        out += data.get("items", [])
        if page >= data.get("totalPages", 1):
            return out
        page += 1


def ensure_pack(s, base, packdef, dry):
    """Find-or-create a catalog_packs row by code. Returns (id, state)."""
    code = packdef["code"]
    body = {"code": code, "name": packdef["name"],
            "enabled": packdef.get("enabled", False),
            "redeemable": packdef.get("redeemable", True)}
    existing = find_one(s, base, "catalog_packs", f"code='{code}'")
    if existing:
        return existing["id"], "exists"
    if dry:
        return "<pack-id>", "create"
    r = s.post(f"{base}/api/collections/catalog_packs/records", json=body, timeout=30)
    if r.status_code not in (200, 201):
        die(f"pack '{code}' create failed ({r.status_code}): {r.text[:300]}")
    return r.json()["id"], "create"


def pack_hero(key):
    """Inferred hero image for a pack: `packs/<key>_hero.png` (e.g.
    packs/all_cats_hero.png). Returns the path if it exists, else None - a
    missing hero is simply skipped."""
    path = os.path.join(HERE, "packs", f"{key}_hero.png")
    return path if os.path.exists(path) else None


def ensure_product(s, base, proddef, pack_id, hero, dry):
    """Find-or-create a catalog_products row by sku, granting pack_id. Uploads
    `hero` (a resolved file path, or None) to hero_image on both create and
    update; when None, hero_image is left untouched (a PATCH that omits it never
    clears an already-set image)."""
    sku = proddef["sku"]
    name = proddef["name"]
    description = proddef.get("description", "")
    sort_order = proddef.get("sort_order", 0)
    enabled = proddef.get("enabled", True)
    existing = find_one(s, base, "catalog_products", f"sku='{sku}'")
    action = "update" if existing else "create"
    if dry:
        return action

    files = None
    if hero:
        # multipart: relation + bools/numbers as form strings, plus the file
        data = [("sku", sku), ("name", name), ("description", description),
                ("sort_order", str(sort_order)),
                ("enabled", "true" if enabled else "false"), ("grants", pack_id)]
        files = {"hero_image": (os.path.basename(hero), open(hero, "rb"), "image/png")}
    else:
        data = {"sku": sku, "name": name, "description": description,
                "sort_order": sort_order, "enabled": enabled, "grants": [pack_id]}
    try:
        url = (f"{base}/api/collections/catalog_products/records/{existing['id']}"
               if existing else f"{base}/api/collections/catalog_products/records")
        method = s.patch if existing else s.post
        r = (method(url, data=data, files=files, timeout=60) if hero
             else method(url, json=data, timeout=30))
    finally:
        if files:
            for _, fh, _m in files.values():
                fh.close()
    if r.status_code not in (200, 201):
        die(f"product '{sku}' {action} failed ({r.status_code}): {r.text[:300]}")
    return action


def set_packs_enabled(s, base, manifest, enabled, dry):
    """Bulk-flip enabled on the group packs. Disabling drops their characters
    from the catalog fetch entirely - the hold while a build rolls out."""
    changed = unchanged = 0
    missing = []
    for p in manifest.get("packs", []):
        row = find_one(s, base, "catalog_packs", f"code='{p['code']}'")
        if not row:
            missing.append(p["key"])
            continue
        if bool(row.get("enabled")) == enabled:
            unchanged += 1
            continue
        if not dry:
            r = s.patch(f"{base}/api/collections/catalog_packs/records/{row['id']}",
                        json={"enabled": enabled}, timeout=30)
            if r.status_code != 200:
                die(f"pack '{p['code']}' toggle failed ({r.status_code}): {r.text[:200]}")
        print(f"  {'would set' if dry else 'set'} {p['code']:16} enabled={enabled}  ({p['key']})")
        changed += 1
    print(f"\n{'Would change' if dry else 'Changed'} {changed}, already "
          f"{'enabled' if enabled else 'disabled'} {unchanged}"
          + (f", MISSING {', '.join(missing)}" if missing else ""))


def char_dir(slug):
    return os.path.join(HERE, "characters", slug)


def open_images(slug):
    files = {}
    for e in EXPRESSIONS:
        p = os.path.join(char_dir(slug), f"{e}.png")
        if os.path.exists(p):
            files[e] = (f"{e}.png", open(p, "rb"), "image/png")
        elif e == "idle":
            die(f"{slug}: idle.png is required but missing")
    return files


def text_fields(c):
    """Scalar fields for a catalog_characters row (packs handled separately).
    messages.json is optional - a character without one uses the generic voice,
    so the field is simply omitted (a PATCH that omits it leaves it unchanged)."""
    base_color = c["base_color"]
    if not base_color.startswith("#"):
        base_color = "#" + base_color  # PB validates as #RRGGBB (min 7 chars)
    fields = {
        "slug": c["slug"],
        "display_name": c["display_name"],
        "base_color": base_color,
        "sort_order": str(c.get("sort_order", 0)),
    }
    mpath = os.path.join(char_dir(c["slug"]), "messages.json")
    if os.path.exists(mpath):
        with open(mpath, encoding="utf-8") as f:
            fields["messages"] = f.read()  # valid JSON; PB parses the json field
    return fields


def upsert_character(s, base, c, pack_ids, dry, reupload):
    """Create/update a catalog_characters row, setting its multi-relation
    `packs` to pack_ids (empty for free). Images upload on create or --reupload;
    a plain update PATCHes text + membership as JSON."""
    slug = c["slug"]
    if not os.path.isdir(char_dir(slug)):
        print(f"    ! {slug}: no folder, skipping")
        return "skip"
    existing = find_one(s, base, "catalog_characters", f"slug='{slug}'")
    scalars = text_fields(c)
    if dry:
        return "update" if existing else "create"

    # Multipart needs the multi-relation as repeated form fields (a list of
    # tuples); plain JSON updates take a normal list.
    def multipart(url, method):
        files = open_images(slug)
        data = list(scalars.items()) + [("packs", pid) for pid in pack_ids]
        try:
            return method(url, data=data, files=files, timeout=120)
        finally:
            for _, fh, _m in files.values():
                fh.close()

    if existing is None:
        r = multipart(f"{base}/api/collections/catalog_characters/records", s.post)
        if r.status_code not in (200, 201):
            die(f"{slug} create failed ({r.status_code}): {r.text[:400]}")
        return "create"
    url = f"{base}/api/collections/catalog_characters/records/{existing['id']}"
    if reupload:
        r = multipart(url, s.patch)
    else:
        r = s.patch(url, json={**scalars, "packs": pack_ids}, timeout=30)
    if r.status_code != 200:
        die(f"{slug} update failed ({r.status_code}): {r.text[:400]}")
    return "update"


BUCKETS = ["morning", "midday", "afternoon", "evening", "night"]


def avatar_path(slug):
    """The single image for a catalog_avatars row: avatars/<slug>.png."""
    p = os.path.join(HERE, "avatars", f"{slug}.png")
    return p if os.path.exists(p) else None


def picture_buckets(slug):
    """The 5 time-of-day files for a catalog_pictures row, from
    households/<slug>/. Accepts either <bucket>.png or <slug>_<bucket>.png.
    Returns {bucket: path}, or None if any of the five is missing."""
    d = os.path.join(HERE, "households", slug)
    out = {}
    for b in BUCKETS:
        cand = os.path.join(d, f"{b}.png")
        if not os.path.exists(cand):
            cand = os.path.join(d, f"{slug}_{b}.png")
        if not os.path.exists(cand):
            return None
        out[b] = cand
    return out


def upsert_avatar(s, base, a, pack_ids, dry, reupload):
    """Create/update a catalog_avatars row. One `image` file; multi-relation
    packs. Image uploads on create or --reupload; a plain update PATCHes JSON."""
    slug = a["slug"]
    img = avatar_path(slug)
    if not img:
        print(f"    ! {slug}: no avatars/{slug}.png, skipping")
        return "skip"
    existing = find_one(s, base, "catalog_avatars", f"slug='{slug}'")
    scalars = {"slug": slug, "display_name": a["display_name"],
               "sort_order": str(a.get("sort_order", 0))}
    if dry:
        return "update" if existing else "create"

    def multipart(url, method):
        files = {"image": (os.path.basename(img), open(img, "rb"), "image/png")}
        data = list(scalars.items()) + [("packs", pid) for pid in pack_ids]
        try:
            return method(url, data=data, files=files, timeout=60)
        finally:
            for _, fh, _m in files.values():
                fh.close()

    if existing is None:
        r = multipart(f"{base}/api/collections/catalog_avatars/records", s.post)
        if r.status_code not in (200, 201):
            die(f"{slug} create failed ({r.status_code}): {r.text[:400]}")
        return "create"
    url = f"{base}/api/collections/catalog_avatars/records/{existing['id']}"
    r = (multipart(url, s.patch) if reupload
         else s.patch(url, json={**scalars, "packs": pack_ids}, timeout=30))
    if r.status_code != 200:
        die(f"{slug} update failed ({r.status_code}): {r.text[:400]}")
    return "update"


def upsert_picture(s, base, p, pack_ids, dry, reupload):
    """Create/update a catalog_pictures row. Five bucket files
    (morning/midday/afternoon/evening/night); multi-relation packs."""
    slug = p["slug"]
    buckets = picture_buckets(slug)
    if not buckets:
        print(f"    ! {slug}: missing one of {BUCKETS} in households/{slug}/, skipping")
        return "skip"
    existing = find_one(s, base, "catalog_pictures", f"slug='{slug}'")
    scalars = {"slug": slug, "display_name": p["display_name"],
               "sort_order": str(p.get("sort_order", 0))}
    if dry:
        return "update" if existing else "create"

    def multipart(url, method):
        files = {b: (os.path.basename(path), open(path, "rb"), "image/png")
                 for b, path in buckets.items()}
        data = list(scalars.items()) + [("packs", pid) for pid in pack_ids]
        try:
            return method(url, data=data, files=files, timeout=120)
        finally:
            for _, fh, _m in files.values():
                fh.close()

    if existing is None:
        r = multipart(f"{base}/api/collections/catalog_pictures/records", s.post)
        if r.status_code not in (200, 201):
            die(f"{slug} create failed ({r.status_code}): {r.text[:400]}")
        return "create"
    url = f"{base}/api/collections/catalog_pictures/records/{existing['id']}"
    r = (multipart(url, s.patch) if reupload
         else s.patch(url, json={**scalars, "packs": pack_ids}, timeout=30))
    if r.status_code != 200:
        die(f"{slug} update failed ({r.status_code}): {r.text[:400]}")
    return "update"


def verify(s, base, manifest, only):
    chars = fetch_all(s, base, "catalog_characters")
    packs = fetch_all(s, base, "catalog_packs")
    live = {c["slug"]: c for c in chars}
    by_code = {p.get("code"): p for p in packs}
    id_to_key = {}
    for p in manifest.get("packs", []):
        row = by_code.get(p["code"])
        if row:
            id_to_key[row["id"]] = p["key"]

    print("Packs:")
    for p in manifest.get("packs", []):
        row = by_code.get(p["code"])
        print(f"  {p['key']:16} code={p['code']:14} "
              + (f"enabled={row.get('enabled')}" if row else "MISSING"))
    print()

    want = manifest["characters"]
    if only:
        sel = {x.strip() for x in only.split(",") if x.strip()}
        want = [c for c in want if c["slug"] in sel]
    print(f"{'slug':22} {'state':9} {'idle':4} packs")
    print("-" * 60)
    for c in want:
        slug = c["slug"]
        row = live.get(slug)
        if not row:
            print(f"{slug:22} {'MISSING':9}")
            continue
        member = row.get("packs") or []
        if isinstance(member, str):
            member = [member] if member else []
        names = [id_to_key.get(i, i[:6]) for i in member]
        idle = "yes" if row.get("idle") else "NO!"
        print(f"{slug:22} {'live':9} {idle:4} {','.join(names) or '(free)'}")
    missing = [c["slug"] for c in want if c["slug"] not in live]
    print(f"\nSummary: {len(want) - len(missing)}/{len(want)} live"
          + (f"; MISSING: {', '.join(missing)}" if missing else ""))


def main():
    ap = argparse.ArgumentParser(description="Publish character art grouped into PocketBase packs.")
    ap.add_argument("--base-url", default=DEFAULT_BASE)
    ap.add_argument("--manifest", default=os.path.join(HERE, "pack_manifest.json"))
    ap.add_argument("--dry-run", action="store_true", help="show the plan, write nothing")
    ap.add_argument("--reupload", action="store_true", help="re-push images on existing rows")
    ap.add_argument("--verify", action="store_true", help="report live state vs the manifest")
    ap.add_argument("--set-packs", choices=["on", "off"],
                    help="bulk enable/disable the group packs, then exit")
    ap.add_argument("--only", default="", help="comma-separated slugs to limit characters to")
    args = ap.parse_args()

    base = args.base_url.rstrip("/")
    manifest = json.load(open(args.manifest, encoding="utf-8"))

    def need_creds():
        e, p = os.environ.get("PB_ADMIN_EMAIL"), os.environ.get("PB_ADMIN_PASSWORD")
        if not (e and p):
            die("run the following:\n"
                "export PB_ADMIN_EMAIL=georgefedthedog@gmail.com\n"
                "export PB_ADMIN_PASSWORD=[INSERT_PASSWORD]")
        return e, p

    if args.set_packs:
        e, p = need_creds()
        enabled = args.set_packs == "on"
        print(f"Target: {base}  (set group packs enabled={enabled}"
              f"{', DRY RUN' if args.dry_run else ''})\n")
        set_packs_enabled(auth(base, e, p), base, manifest, enabled, args.dry_run)
        return
    if args.verify:
        e, p = need_creds()
        print(f"Target: {base}  (verify)\n")
        verify(auth(base, e, p), base, manifest, args.only)
        return

    chars = manifest["characters"]
    avatars = manifest.get("avatars", [])
    pictures = manifest.get("pictures", [])
    if args.only:
        sel = {x.strip() for x in args.only.split(",") if x.strip()}
        chars = [c for c in chars if c["slug"] in sel]
        avatars = [a for a in avatars if a["slug"] in sel]
        pictures = [p for p in pictures if p["slug"] in sel]
        if not (chars or avatars or pictures):
            die("--only matched no slugs in the manifest")

    paid = sum(1 for c in chars if c.get("packs"))  # "paid" = belongs to any pack
    print(f"Target: {base}")
    print(f"Mode:   {'DRY RUN (no writes)' if args.dry_run else 'LIVE'}"
          f"{'  + image reupload' if args.reupload else ''}")
    print(f"Packs:  {len(manifest.get('packs', []))}   "
          f"Chars: {len(chars)} ({paid} paid, {len(chars) - paid} free)   "
          f"Avatars: {len(avatars)}   Pictures: {len(pictures)}\n")

    email = os.environ.get("PB_ADMIN_EMAIL")
    password = os.environ.get("PB_ADMIN_PASSWORD")
    offline = args.dry_run and not (email and password)
    if not args.dry_run and not (email and password):
        die("set PB_ADMIN_EMAIL and PB_ADMIN_PASSWORD in the environment")
    s = None if offline else auth(base, email, password)
    if offline:
        print("(dry run, no creds: planning offline; server lookups skipped)\n")

    tally = {"char_create": 0, "char_update": 0, "char_skip": 0,
             "pack_create": 0, "prod_create": 0, "prod_update": 0,
             "avatar_create": 0, "avatar_update": 0, "avatar_skip": 0,
             "picture_create": 0, "picture_update": 0, "picture_skip": 0}

    # 1) Packs + their products (always ensured, even under --only). A pack with
    #    no `product` is giftable-only (code redemption, no IAP/store listing).
    print("Packs:")
    pack_id_by_key = {}
    for p in manifest.get("packs", []):
        prod = p.get("product")
        hero = pack_hero(p["key"]) if prod else None
        if offline:
            tail = f"sku={prod['sku']}" if prod else "(giftable only, no product)"
            print(f"  {p['key']:16} code={p['code']:14} {tail}  enabled={p['enabled']}")
            pack_id_by_key[p["key"]] = f"<{p['key']}>"
            continue
        pid, pst = ensure_pack(s, base, p, args.dry_run)
        pack_id_by_key[p["key"]] = pid
        if pst == "create":
            tally["pack_create"] += 1
        if prod:
            hero_tag = " +hero" if hero else " (no hero yet)"
            prst = ensure_product(s, base, prod, pid, hero, args.dry_run)
            tally["prod_create" if prst == "create" else "prod_update"] += 1
            print(f"  {p['key']:16} code={p['code']:14} ({pst}; product {prst}{hero_tag})")
        else:
            print(f"  {p['key']:16} code={p['code']:14} ({pst}; giftable only, no product)")

    # 2) Characters -> their pack memberships.
    print("\nCharacters:")
    for c in chars:
        slug = c["slug"]
        keys = c.get("packs", [])
        bad = [k for k in keys if k not in pack_id_by_key]
        if bad:
            die(f"{slug}: unknown pack keys {bad}")
        label = (f"PAID  {slug:22} packs={','.join(keys)}" if keys
                 else f"FREE  {slug:22} (general catalog)")
        print(f"  {label}")
        if offline:
            tally["char_create"] += 1
            continue
        pack_ids = [pack_id_by_key[k] for k in keys]
        cst = upsert_character(s, base, c, pack_ids, args.dry_run, args.reupload)
        tally[f"char_{cst}"] += 1

    # 3) Avatars (one image each) + 4) Pictures (5 time-of-day buckets).
    def resolve_packs(item):
        keys = item.get("packs", [])
        bad = [k for k in keys if k not in pack_id_by_key]
        if bad:
            die(f"{item['slug']}: unknown pack keys {bad}")
        return keys, (None if offline else [pack_id_by_key[k] for k in keys])

    for label, items, fn in (("Avatars", avatars, upsert_avatar),
                             ("Pictures", pictures, upsert_picture)):
        if not items:
            continue
        kind = label[:-1].lower()  # "avatar" / "picture"
        print(f"\n{label}:")
        for it in items:
            keys, ids = resolve_packs(it)
            print(f"  {it['slug']:24} packs={','.join(keys) or '(free)'}")
            if offline:
                tally[f"{kind}_create"] += 1
                continue
            st = fn(s, base, it, ids, args.dry_run, args.reupload)
            tally[f"{kind}_{st}"] += 1

    print(f"\nDone{' (dry run)' if args.dry_run else ''}.")
    print(f"  packs:      {tally['pack_create']} created")
    print(f"  products:   {tally['prod_create']} created, {tally['prod_update']} updated")
    print(f"  characters: {tally['char_create']} created, {tally['char_update']} updated, "
          f"{tally['char_skip']} skipped")
    print(f"  avatars:    {tally['avatar_create']} created, {tally['avatar_update']} updated, "
          f"{tally['avatar_skip']} skipped")
    print(f"  pictures:   {tally['picture_create']} created, {tally['picture_update']} updated, "
          f"{tally['picture_skip']} skipped")
    if not args.dry_run:
        print("\nGroup packs are created DISABLED. Enable when the new build is the floor:\n"
              "  python upload_pack.py --set-packs on\n"
              "Then create + price + activate each sku in Play / App Store (store_products.csv).")


if __name__ == "__main__":
    main()
