#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-}"
REPORT_FILE="${2:-system_audit_report.md}"

if [[ -z "$TARGET_DIR" ]]; then
  echo "Usage: $0 <target_dir> [report_file]" >&2
  exit 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: target directory not found: $TARGET_DIR" >&2
  exit 2
fi

{
  echo "# System Folder Audit Report"
  echo
  echo "- Target: $TARGET_DIR"
  echo "- Timestamp: $(date -Iseconds)"
  echo

  echo "## 1) File Inventory"
  total_files=$(find "$TARGET_DIR" -type f | wc -l)
  total_dirs=$(find "$TARGET_DIR" -type d | wc -l)
  echo "- Files: $total_files"
  echo "- Dirs: $total_dirs"
  echo

  echo "## 2) Largest Files (Top 20)"
  find "$TARGET_DIR" -type f -printf '%s\t%p\n' | sort -nr | head -n 20 | \
    awk '{ printf("- %.2f MB - `%s`\n", $1/1024/1024, $2) }'
  echo

  echo "## 3) Potentially Sensitive Files"
  find "$TARGET_DIR" -type f \( -iname '*.env' -o -iname '*secret*' -o -iname '*password*' -o -iname '*.pem' -o -iname '*.key' \) \
    | head -n 100 | sed 's/^/- `/' | sed 's/$/`/'
  echo

  echo "## 4) Dependency/Runtime Manifests"
  for manifest in package.json requirements.txt pyproject.toml pom.xml build.gradle Dockerfile docker-compose.yml; do
    while IFS= read -r f; do
      [[ -n "$f" ]] && echo "- `$f`"
    done < <(find "$TARGET_DIR" -type f -name "$manifest" | head -n 50)
  done
  echo

  echo "## 5) Upgrade Checklist"
  echo "- [ ] Verify dependency versions and run security scan (npm audit / pip-audit / osv-scanner)."
  echo "- [ ] Add or update automated backup strategy for DB/files."
  echo "- [ ] Confirm logs, metrics, and alerting are enabled for core modules."
  echo "- [ ] Enforce secret management (remove plaintext secrets from files)."
  echo "- [ ] Validate disaster recovery docs and rollback runbooks."
  echo "- [ ] Ensure TLS cert rotation and access control policy are current."
  echo

  echo "## 6) Next Recommended Actions"
  echo "1. Prioritize oversized or orphaned files to reduce storage risk."
  echo "2. Patch outdated dependencies and establish monthly upgrade cadence."
  echo "3. Introduce CI checks for lint/test/security before deployment."
} > "$REPORT_FILE"

echo "Report generated: $REPORT_FILE"
