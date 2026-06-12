# pb-to-openapi

Node script that reads `server/pb_schema.json` and emits `server/openapi.yaml`.

The OpenAPI doc covers:

- Each PocketBase collection as a resource with CRUD paths
  (`/api/collections/<name>/records` and `/{id}`)
- The standard PB auth endpoint `/api/collections/users/auth-with-password`
- All custom fields per collection mapped to JSON Schema types

This makes `openapi-generator-cli` happy and produces clean Dart types under
`app/lib/api/generated/`.

## Run

From repo root:

```bash
node server/tools/pb-to-openapi/convert.js
```

Writes/overwrites `server/openapi.yaml`. Commit the result.

## Status

Stub. The conversion logic is implemented during Restructure Step 0 (server
project setup) - see the plan.
