#!/usr/bin/env python3
"""
One-off uploader: publish the foldered character art in this directory to
PocketBase as individual, sellable image packs.

This is a manual publishing helper, NOT part of any committed pipeline. It talks
to the LIVE server, so you run it yourself with superuser credentials.

Model (per pack_manifest.json):
  - PAID character  -> its own catalog_packs row (enabled, redeemable, gift code)
                       + its own catalog_products row (sku, grants -> that pack)
                       + the catalog_characters row, pack = that pack.
  - FREE character  -> just the catalog_characters row with NO pack
                       (general catalog: selectable by everyone).

Price (79p) is NOT set here - it lives on each product's store listing in Play
Console + App Store Connect. See store_products.csv for the bulk list. A product
only appears in-app once the store knows its sku and it's activated.

Everything is idempotent (safe to re-run):
  - packs matched by code, products by sku, characters by slug;
  - existing rows get text/messages/grants refreshed; images only (re)upload on
    create, or with --reupload.

Credentials (never hard-code - read from the environment):
  PB_ADMIN_EMAIL, PB_ADMIN_PASSWORD   (PowerShell: $env:PB_ADMIN_EMAIL=...)

Usage:
  python upload_pack.py --dry-run                 # show the plan, write nothing
  python upload_pack.py                           # create/update everything
  python upload_pack.py --reupload                # also re-push images
  python upload_pack.py --only husky,meds         # just these slugs
  python upload_pack.py --base-url https://api.haveyoufedthedog.com
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
                  params={"perPage": 200, "page": page, "sort": "created"},
                  timeout=30)
        r.raise_for_status()
        data = r.json()
        out += data.get("items", [])
        if page >= data.get("totalPages", 1):
            return out
        page += 1


def verify(s, base, manifest, only):
    chars = fetch_all(s, base, "catalog_characters")
    packs = {p["id"]: p for p in fetch_all(s, base, "catalog_packs")}
    live = {c["slug"]: c for c in chars}
    print(f"Live: {len(chars)} catalog_characters, {len(packs)} catalog_packs, "
          f"{len(fetch_all(s, base, 'catalog_products'))} catalog_products\n")

    want = manifest["characters"]
    if only:
        sel = {x.strip() for x in only.split(",") if x.strip()}
        want = [c for c in want if c["slug"] in sel]

    print(f"{'slug':22} {'state':9} {'kind':6} {'idle':4} imgs")
    print("-" * 64)
    for c in want:
        slug = c["slug"]
        row = live.get(slug)
        if not row:
            print(f"{slug:22} {'MISSING':9} {'-':6}")
            continue
        pack_id = row.get("pack") or ""
        if not pack_id:
            kind = "free"
        elif packs.get(pack_id, {}).get("enabled"):
            kind = "paid"
        else:
            kind = "DISABL"  # pack disabled -> won't resolve in app
        imgs = [e for e in EXPRESSIONS if row.get(e)]
        idle = "yes" if row.get("idle") else "NO!"  # missing idle => app drops the row
        print(f"{slug:22} {'live':9} {kind:6} {idle:4} {','.join(imgs)}")

    missing = [c["slug"] for c in want if c["slug"] not in live]
    no_idle = [c["slug"] for c in want if c["slug"] in live and not live[c["slug"]].get("idle")]
    print()
    print(f"Summary: {len(want) - len(missing)}/{len(want)} live"
          + (f"; MISSING: {', '.join(missing)}" if missing else "")
          + (f"; NO IDLE (app will drop): {', '.join(no_idle)}" if no_idle else ""))


def ensure_pack(s, base, packdef, dry):
    """Find-or-create a catalog_packs row by code. Returns its id."""
    code = packdef["code"]
    existing = find_one(s, base, "catalog_packs", f"code='{code}'")
    if existing:
        return existing["id"], "exists"
    if dry:
        return "<pack-id>", "create"
    r = s.post(f"{base}/api/collections/catalog_packs/records", json=packdef, timeout=30)
    if r.status_code not in (200, 201):
        die(f"pack '{code}' create failed ({r.status_code}): {r.text[:300]}")
    return r.json()["id"], "create"


def leaf_code_for(manifest, slug):
    """The gift code of a paid character's individual (leaf) pack, or None."""
    for c in manifest["characters"]:
        if c["slug"] == slug and c.get("paid"):
            return c["pack"]["code"]
    return None


def ensure_bundle_pack(s, base, bundle, member_ids, dry):
    """Find-or-create a 'bundle' catalog_packs row (a pack-of-packs). Its
    `grants` are the member leaf-pack ids; redeeming/buying it cascades them to
    the household (the redeem-pack-code / verify-purchase hooks expand grants).
    Existing rows are PATCHed so re-running keeps grants/name/enabled in sync."""
    code = bundle["code"]
    body = {"code": code, "name": bundle["name"],
            "enabled": bundle.get("enabled", True),
            "redeemable": bundle.get("redeemable", True),
            "grants": member_ids}
    existing = find_one(s, base, "catalog_packs", f"code='{code}'")
    if dry:
        return "<bundle-id>", ("update" if existing else "create")
    if existing:
        r = s.patch(f"{base}/api/collections/catalog_packs/records/{existing['id']}",
                    json=body, timeout=30)
        if r.status_code != 200:
            die(f"bundle '{code}' update failed ({r.status_code}): {r.text[:300]}")
        return existing["id"], "update"
    r = s.post(f"{base}/api/collections/catalog_packs/records", json=body, timeout=30)
    if r.status_code not in (200, 201):
        die(f"bundle '{code}' create failed ({r.status_code}): {r.text[:300]}")
    return r.json()["id"], "create"


def set_packs_enabled(s, base, manifest, enabled, only, dry):
    """Bulk-flip enabled on the paid packs (and, on a full run, bundle packs).
    Disabling drops their characters from the catalog fetch entirely (so even an
    old, un-gated client stops showing them) - the hold while a client-side
    picker fix rolls out."""
    targets = [(c["slug"], c["pack"]["code"])
               for c in manifest["characters"] if c.get("paid")]
    if only:
        sel = {x.strip() for x in only.split(",") if x.strip()}
        targets = [t for t in targets if t[0] in sel]
    else:
        targets += [(b["name"], b["code"]) for b in manifest.get("bundles", [])]
    changed = unchanged = 0
    missing = []
    for label, code in targets:
        row = find_one(s, base, "catalog_packs", f"code='{code}'")
        if not row:
            missing.append(label)
            continue
        if bool(row.get("enabled")) == enabled:
            unchanged += 1
            continue
        if not dry:
            r = s.patch(f"{base}/api/collections/catalog_packs/records/{row['id']}",
                        json={"enabled": enabled}, timeout=30)
            if r.status_code != 200:
                die(f"pack '{code}' toggle failed ({r.status_code}): {r.text[:200]}")
        print(f"  {'would set' if dry else 'set'} {code:16} enabled={enabled}  ({label})")
        changed += 1
    print(f"\n{'Would change' if dry else 'Changed'} {changed}, already {('enabled' if enabled else 'disabled')} {unchanged}"
          + (f", MISSING {', '.join(missing)}" if missing else ""))


def ensure_product(s, base, proddef, pack_id, hero_path, dry):
    """Find-or-create a catalog_products row by sku, granting pack_id.

    Optional hero image: if hero_path exists it's uploaded to the product's
    hero_image field (on both create and update, so you can add a hero later
    by dropping the file in and re-running). When absent, hero_image is left
    untouched - a PATCH that omits it never clears an already-set image.
    """
    sku = proddef["sku"]
    name = proddef["name"]
    description = proddef.get("description", "")
    enabled = proddef.get("enabled", True)
    sort_order = proddef.get("sort_order", 0)
    existing = find_one(s, base, "catalog_products", f"sku='{sku}'")
    action = "update" if existing else "create"
    if dry:
        return action

    has_hero = bool(hero_path) and os.path.exists(hero_path)
    files = None
    if has_hero:
        # multipart: relation + bools/numbers as form strings, plus the file
        data = [("sku", sku), ("name", name), ("description", description),
                ("sort_order", str(sort_order)),
                ("enabled", "true" if enabled else "false"), ("grants", pack_id)]
        files = {"hero_image": ("hero.png", open(hero_path, "rb"), "image/png")}
    else:
        data = {"sku": sku, "name": name, "description": description,
                "sort_order": sort_order, "enabled": enabled, "grants": [pack_id]}

    try:
        if existing:
            url = f"{base}/api/collections/catalog_products/records/{existing['id']}"
            r = (s.patch(url, data=data, files=files, timeout=60) if has_hero
                 else s.patch(url, json=data, timeout=30))
        else:
            url = f"{base}/api/collections/catalog_products/records"
            r = (s.post(url, data=data, files=files, timeout=60) if has_hero
                 else s.post(url, json=data, timeout=30))
    finally:
        if files:
            for _, fh, _m in files.values():
                fh.close()
    if r.status_code not in (200, 201):
        die(f"product '{sku}' {action} failed ({r.status_code}): {r.text[:300]}")
    return action


def char_dir(slug):
    return os.path.join(HERE, "characters", slug)


def hero_source(slug):
    """Hero image for a product: a custom hero.png if present, else idle.png.
    Returns (path, kind) where kind is 'hero', 'idle', or '' (none found)."""
    custom = os.path.join(char_dir(slug), "hero.png")
    if os.path.exists(custom):
        return custom, "hero"
    idle = os.path.join(char_dir(slug), "idle.png")
    return (idle, "idle") if os.path.exists(idle) else (None, "")


def text_fields(c, pack_id):
    with open(os.path.join(char_dir(c["slug"]), "messages.json"), encoding="utf-8") as f:
        messages = f.read()  # already valid JSON; PB parses the json field from string
    base_color = c["base_color"]
    if not base_color.startswith("#"):
        base_color = "#" + base_color  # PB stores/validates as #RRGGBB (min 7 chars)
    return {
        "slug": c["slug"],
        "display_name": c["display_name"],
        "base_color": base_color,
        "sort_order": str(c.get("sort_order", 0)),
        "messages": messages,
        "pack": pack_id,  # "" for free (general catalog)
    }


def open_images(slug):
    files = {}
    for e in EXPRESSIONS:
        p = os.path.join(char_dir(slug), f"{e}.png")
        if os.path.exists(p):
            files[e] = (f"{e}.png", open(p, "rb"), "image/png")
        elif e == "idle":
            die(f"{slug}: idle.png is required but missing")
    return files


def upsert_character(s, base, c, pack_id, dry, reupload):
    slug = c["slug"]
    if not os.path.isdir(char_dir(slug)):
        print(f"    ! {slug}: no folder, skipping")
        return "skip"
    existing = find_one(s, base, "catalog_characters", f"slug='{slug}'")
    fields = text_fields(c, pack_id)
    if existing is None:
        if dry:
            return "create"
        files = open_images(slug)
        try:
            r = s.post(f"{base}/api/collections/catalog_characters/records",
                       data=fields, files=files, timeout=120)
        finally:
            for _, fh, _m in files.values():
                fh.close()
        if r.status_code not in (200, 201):
            die(f"{slug} create failed ({r.status_code}): {r.text[:400]}")
        return "create"
    if dry:
        return "update"
    files = open_images(slug) if reupload else {}
    try:
        r = s.patch(f"{base}/api/collections/catalog_characters/records/{existing['id']}",
                    data=fields, files=files or None, timeout=120)
    finally:
        for _, fh, _m in files.values():
            fh.close()
    if r.status_code != 200:
        die(f"{slug} update failed ({r.status_code}): {r.text[:400]}")
    return "update"


def main():
    ap = argparse.ArgumentParser(description="Publish character art as individual paid PocketBase packs.")
    ap.add_argument("--base-url", default=DEFAULT_BASE)
    ap.add_argument("--manifest", default=os.path.join(HERE, "pack_manifest.json"))
    ap.add_argument("--dry-run", action="store_true", help="show the plan, write nothing")
    ap.add_argument("--reupload", action="store_true", help="re-push images on existing rows")
    ap.add_argument("--verify", action="store_true",
                    help="report what's actually live in PB, cross-checked vs the manifest")
    ap.add_argument("--set-packs", choices=["on", "off"],
                    help="bulk enable/disable the paid packs, then exit (off = hide paid "
                         "characters from ALL clients while a picker fix ships)")
    ap.add_argument("--only", default="", help="comma-separated slugs to limit to")
    args = ap.parse_args()

    base = args.base_url.rstrip("/")
    manifest = json.load(open(args.manifest, encoding="utf-8"))

    if args.set_packs:
        email = os.environ.get("PB_ADMIN_EMAIL")
        password = os.environ.get("PB_ADMIN_PASSWORD")
        if not (email and password):
            die("set PB_ADMIN_EMAIL and PB_ADMIN_PASSWORD in the environment")
        enabled = args.set_packs == "on"
        print(f"Target: {base}  (set paid packs enabled={enabled}"
              f"{', DRY RUN' if args.dry_run else ''})\n")
        set_packs_enabled(auth(base, email, password), base, manifest, enabled,
                          args.only, args.dry_run)
        return

    if args.verify:
        email = os.environ.get("PB_ADMIN_EMAIL")
        password = os.environ.get("PB_ADMIN_PASSWORD")
        if not (email and password):
            die("set PB_ADMIN_EMAIL and PB_ADMIN_PASSWORD in the environment")
        print(f"Target: {base}  (verify)\n")
        verify(auth(base, email, password), base, manifest, args.only)
        return

    chars = manifest["characters"]
    if args.only:
        want = {x.strip() for x in args.only.split(",") if x.strip()}
        chars = [c for c in chars if c["slug"] in want]
        if not chars:
            die("--only matched no slugs in the manifest")

    paid = sum(1 for c in chars if c.get("paid"))
    print(f"Target: {base}")
    print(f"Mode:   {'DRY RUN (no writes)' if args.dry_run else 'LIVE'}"
          f"{'  + image reupload' if args.reupload else ''}")
    print(f"Chars:  {len(chars)}  ({paid} paid, {len(chars) - paid} free)\n")

    email = os.environ.get("PB_ADMIN_EMAIL")
    password = os.environ.get("PB_ADMIN_PASSWORD")
    offline = args.dry_run and not (email and password)
    if not args.dry_run and not (email and password):
        die("set PB_ADMIN_EMAIL and PB_ADMIN_PASSWORD in the environment")
    s = None if offline else auth(base, email, password)
    if offline:
        print("(dry run, no creds: planning offline; pack/product/char lookups skipped)\n")

    tally = {"char_create": 0, "char_update": 0, "char_skip": 0,
             "pack_create": 0, "prod_create": 0, "prod_update": 0,
             "bundle_create": 0, "bundle_update": 0, "bundle_prod": 0}
    leaf_ids = {}  # slug -> leaf pack id, used to resolve bundle grants
    for c in chars:
        slug = c["slug"]
        if c.get("paid"):
            _, hkind = hero_source(slug)
            hero = f" +hero({hkind})" if hkind else ""
            tag = f"PAID  {slug:22} sku={c['product']['sku']:38} code={c['pack']['code']}{hero}"
        else:
            tag = f"FREE  {slug:22} (general catalog, no pack)"
        print(f"  {tag}")
        if offline:
            tally["char_create"] += 1
            continue
        pack_id = ""
        if c.get("paid"):
            pack_id, pst = ensure_pack(s, base, c["pack"], args.dry_run)
            if pst == "create":
                tally["pack_create"] += 1
            leaf_ids[slug] = pack_id
            hero_path, _ = hero_source(slug)
            prst = ensure_product(s, base, c["product"], pack_id, hero_path, args.dry_run)
            tally["prod_create" if prst == "create" else "prod_update"] += 1
        cst = upsert_character(s, base, c, pack_id, args.dry_run, args.reupload)
        tally[f"char_{cst}"] += 1

    # Bundle packs (packs-of-packs). Skipped under --only, since a bundle needs
    # all its members. Each grants its members' leaf packs; an optional bundle
    # product grants the bundle pack itself.
    bundles = manifest.get("bundles", [])
    if bundles and args.only:
        print("\n(skipping bundles - --only targets specific characters)")
    elif bundles:
        print()
        for b in bundles:
            members = b.get("members", [])
            if offline:
                print(f"  BUNDLE {b['name']:16} code={b['code']:14} "
                      f"sku={b['product']['sku']:32} grants={len(members)} packs")
                tally["bundle_create"] += 1
                continue
            member_ids, missing = [], []
            for slug in members:
                pid = leaf_ids.get(slug)
                if not pid:
                    code = leaf_code_for(manifest, slug)
                    row = find_one(s, base, "catalog_packs", f"code='{code}'") if code else None
                    pid = row["id"] if row else None
                member_ids.append(pid) if pid else missing.append(slug)
            if missing:
                die(f"bundle '{b['name']}' missing leaf packs for: {', '.join(missing)} "
                    f"(run the full character upload first)")
            bid, bst = ensure_bundle_pack(s, base, b, member_ids, args.dry_run)
            tally["bundle_create" if bst == "create" else "bundle_update"] += 1
            print(f"  BUNDLE {b['name']:16} code={b['code']:14} grants={len(member_ids)} packs ({bst})")
            if b.get("product"):
                ensure_product(s, base, b["product"], bid, None, args.dry_run)
                tally["bundle_prod"] += 1

    print(f"\nDone{' (dry run)' if args.dry_run else ''}.")
    print(f"  characters: {tally['char_create']} created, {tally['char_update']} updated, "
          f"{tally['char_skip']} skipped")
    print(f"  packs:      {tally['pack_create']} created")
    print(f"  products:   {tally['prod_create']} created, {tally['prod_update']} updated")
    print(f"  bundles:    {tally['bundle_create']} created, {tally['bundle_update']} updated"
          f" ({tally['bundle_prod']} bundle products)")
    if not args.dry_run:
        print("\nNext: create + price + activate each sku in Play Console & App Store "
              "Connect (see store_products.csv). Products appear in-app once the store "
              "knows the sku. Gift a pack/bundle free via its code on the Image packs screen.")


if __name__ == "__main__":
    main()
