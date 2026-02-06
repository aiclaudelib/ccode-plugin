#!/bin/bash
# clean-knowledge.sh — Strip HTML/JSX artifacts from knowledge files
# Converts web-scraped docs to clean markdown for LLM consumption

set -euo pipefail

KNOWLEDGE_DIR="${1:-$(dirname "$0")/../knowledge}"

for file in "$KNOWLEDGE_DIR"/*.md; do
  [ -f "$file" ] || continue
  echo "Cleaning: $(basename "$file")"

  # 1. Remove Documentation Index headers (3 lines)
  perl -i -0pe 's/^> ## Documentation Index\n> Fetch the complete documentation.*?\n> Use this file to discover.*?\n\n//ms' "$file"

  # 2. Convert <Note> / <Tip> / <Warning> to markdown
  perl -i -pe 's/<Note>\s*$/\n/; s/<\/Note>\s*$/\n/; s/<Tip>\s*$/\n/; s/<\/Tip>\s*$/\n/; s/<Warning>\s*$/\n/; s/<\/Warning>\s*$/\n/' "$file"
  # Handle inline versions
  perl -i -pe 's/<Note>//g; s/<\/Note>//g; s/<Tip>//g; s/<\/Tip>//g; s/<Warning>//g; s/<\/Warning>//g' "$file"

  # 3. Convert <Steps><Step title="X"> to numbered lists
  perl -i -pe 's/<Steps>\s*$//; s/<\/Steps>\s*$//; s/<Step title="([^"]*)">/\n**$1**/; s/<\/Step>\s*$//' "$file"

  # 4. Convert <Tabs><Tab title="X"> to #### sections
  perl -i -pe 's/<Tabs>\s*$//; s/<\/Tabs>\s*$//; s/<Tab title="([^"]*)">/\n#### $1\n/; s/<\/Tab>\s*$//' "$file"

  # 5. Remove <Frame> and </Frame>
  perl -i -pe 's/<Frame>\s*$//; s/<\/Frame>\s*$//' "$file"

  # 6. Remove <div style={{...}}> and </div>
  perl -i -pe 's/<div style=\{\{[^}]*\}\}>\s*$//; s/<\/div>\s*$//' "$file"

  # 7. Delete <img ... srcset="..."> blocks (multiline)
  perl -i -0pe 's/\s*<img [^>]*srcset="[^"]*"[^>]*\/>\s*\n?//gs' "$file"

  # 8. Strip theme={null} from code fences
  perl -i -pe 's/```(\w+)\s+theme=\{null\}/```$1/g; s/```\s+theme=\{null\}/```/g' "$file"

  # 9. Remove dead cross-page links: [text](/en/...) → text
  perl -i -pe 's/\[([^\]]+)\]\(\/en\/[^)]*\)/$1/g' "$file"

  # 10. Remove expandable attribute from code fences
  perl -i -pe 's/```(\w+) expandable/```$1/g' "$file"

  # 11. Clean up multiple blank lines (max 2)
  perl -i -0pe 's/\n{4,}/\n\n\n/g' "$file"
done

echo "Done. Review results manually."
