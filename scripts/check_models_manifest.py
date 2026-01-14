#!/usr/bin/env python3
import argparse
import json
import os
import sys


def load_manifest(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    try:
        import yaml  # type: ignore
    except Exception:
        try:
            return json.loads(text)
        except Exception as exc:
            raise SystemExit("PyYAML is not installed. Install it or use JSON manifest.") from exc
    return yaml.safe_load(text)


def iter_items(manifest: dict):
    for group_name, group in manifest.get("groups", {}).items():
        for item in group.get("items", []):
            yield group_name, item


def rel_to_fs(rel: str) -> str:
    return rel.replace("/", os.sep)


def exists(models_dir: str, rel: str) -> bool:
    return os.path.exists(os.path.join(models_dir, rel_to_fs(rel)))


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate models against models_manifest.yaml.")
    parser.add_argument("manifest", help="Path to models_manifest.yaml (YAML or JSON)")
    parser.add_argument("--root", default=os.environ.get("ROOT", "/workspace/data"))
    args = parser.parse_args()

    manifest = load_manifest(args.manifest)
    models_root = manifest.get("models_root", "models")
    models_dir = os.path.join(args.root, models_root)

    if not os.path.isdir(models_dir):
        print(f"ERROR: models dir not found: {models_dir}")
        return 1

    missing = []
    alias_used = []
    missing_optional = []

    for _, item in iter_items(manifest):
        item_id = item.get("id", "unknown")
        prefer = item.get("prefer") or item.get("path")
        if not prefer:
            missing.append((item_id, "<missing path>"))
            continue
        candidates = [prefer] + [p for p in item.get("accept_aliases", []) if p]

        found = None
        for rel in candidates:
            if exists(models_dir, rel):
                found = rel
                break

        if found is None and item.get("optional"):
            missing_optional.append((item_id, prefer))
            continue

        if found is None:
            missing.append((item_id, prefer))
        elif found != prefer:
            alias_used.append((item_id, found, prefer))

    if alias_used:
        print("WARN: alias paths in use (prefer canonical when possible):")
        for item_id, found, prefer in alias_used:
            print(f"  - {item_id}: {found} (prefer {prefer})")

    if missing_optional:
        print("WARN: optional model files are missing:")
        for item_id, prefer in missing_optional:
            print(f"  - {item_id}: {prefer}")

    if missing:
        print("ERROR: required model files are missing:")
        for item_id, prefer in missing:
            print(f"  - {item_id}: {prefer}")
        return 1

    print("OK: all required model files are present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
