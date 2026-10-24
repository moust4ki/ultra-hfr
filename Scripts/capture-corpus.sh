#!/bin/bash
# Télécharge les pages HFR publiques du corpus de test dans Corpus/raw (ignoré par git).
# Usage : Scripts/capture-corpus.sh Scripts/corpus-urls.txt
# Chaque ligne du fichier : <nom-de-fichier> <URL>. Les lignes vides ou commençant par # sont ignorées.
# Les pages brutes contiennent des pseudos et des messages réels : elles ne sont publiées
# qu'après Scripts/anonymiser-corpus.swift.
set -euo pipefail

LIST="${1:?Fichier de liste manquant}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/Corpus/raw"
UA="UltraHFR-corpus/0.1 (+https://github.com/moust4ki/ultra-hfr)"
mkdir -p "$OUT"

while read -r name url; do
    [[ -z "${name:-}" || "$name" == \#* ]] && continue
    if [[ -f "$OUT/$name.html" ]]; then
        echo "déjà là : $name"
        continue
    fi
    code=$(curl -sS -A "$UA" -o "$OUT/$name.html" -w "%{http_code} %{url_effective}" "$url")
    echo "$name → $code"
    # Politesse envers HFR : une requête toutes les 2 secondes.
    sleep 2
done < "$LIST"
