#!/usr/bin/env python3
"""
Génère un SQL de test filtré : uniquement les établissements avec wilaya identifiée.
Lit output/establishments_raw.json, applique la résolution géographique si shapely
est disponible, puis écrit output/import_test.sql

Usage:
  source .venv/bin/activate
  python generate_test_sql.py
"""

import json
import os
from collections import Counter

from osm_extract import (
    WILAYAS,
    generate_sql,
    download_wilaya_boundaries,
    build_wilaya_index,
    resolve_wilaya_by_coords,
)

OUTPUT_DIR  = os.path.join(os.path.dirname(__file__), "output")
INPUT_FILE  = os.path.join(OUTPUT_DIR, "establishments_raw.json")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "import_test.sql")


def main():
    print("=" * 60)
    print("  Générateur SQL de test (wilaya identifiée)")
    print("=" * 60)

    print("\n[1/3] Lecture de establishments_raw.json...")
    with open(INPUT_FILE, encoding="utf-8") as f:
        all_establishments = json.load(f)

    total = len(all_establishments)
    with_wilaya_before = sum(1 for e in all_establishments if e.get("wilaya_code"))
    print(f"  Total                   : {total}")
    print(f"  Avec wilaya (addr:state): {with_wilaya_before}")
    print(f"  Sans wilaya             : {total - with_wilaya_before}")

    # ── Résolution géographique ───────────────────────────────
    print("\n[2/3] Résolution géographique des wilayas manquantes...")
    boundary_elements = download_wilaya_boundaries()
    wilaya_index = build_wilaya_index(boundary_elements)

    if wilaya_index:
        resolved = 0
        for e in all_establishments:
            if e.get("wilaya_code"):
                continue
            lat, lon = e.get("latitude"), e.get("longitude")
            if lat is None or lon is None:
                continue
            code = resolve_wilaya_by_coords(lat, lon, wilaya_index)
            if code:
                e["wilaya_code"] = code
                # Compléter l'adresse si elle ne contient pas déjà la wilaya
                wilaya_name = WILAYAS[code]["name"]
                if wilaya_name not in e.get("address", ""):
                    e["address"] = (
                        e.get("address", "").rstrip(", Algérie").rstrip(", ")
                        + f", {wilaya_name}"
                    )
                resolved += 1
        print(f"  Résolus par GEO         : {resolved}")
    else:
        print("  shapely non disponible — résolution géo ignorée.")

    # ── Filtrage final ────────────────────────────────────────
    filtered = [e for e in all_establishments if e.get("wilaya_code")]
    print(f"\n  Total avec wilaya       : {len(filtered)}")
    print(f"  Toujours sans wilaya    : {total - len(filtered)}")

    # Stats par wilaya
    by_wilaya = Counter(e["wilaya_code"] for e in filtered)
    print("\n  Répartition par wilaya :")
    for code, n in sorted(by_wilaya.items(), key=lambda x: -x[1]):
        name = WILAYAS.get(code, {}).get("name", f"Wilaya {code}")
        print(f"    {code} {name:<25} : {n}")

    # Stats par catégorie
    by_cat = Counter(e["category_slug"] for e in filtered)
    print("\n  Répartition par catégorie :")
    for cat, n in sorted(by_cat.items(), key=lambda x: -x[1]):
        print(f"    {cat:<35} : {n}")

    # ── Génération SQL ────────────────────────────────────────
    print("\n[3/3] Génération du SQL...")
    sql = generate_sql(filtered)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(sql)

    size_kb = os.path.getsize(OUTPUT_FILE) / 1024
    print(f"\n✓ Fichier généré : output/import_test.sql ({size_kb:.1f} Ko)")
    print(f"  {len(filtered)} établissements prêts à importer.")
    print("\nPour importer dans PostgreSQL (Docker) :")
    print("  docker exec -i yass_app_postgres psql -U yass_app_user -d annuaire_dz < scripts/output/import_test.sql")


if __name__ == "__main__":
    main()
