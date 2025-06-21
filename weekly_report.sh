#!/bin/bash

# Default values
START_DATE=""
END_DATE=""
USERNAME=$(gh api user --jq .login)

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --start) START_DATE="$2"; shift ;;
        --end) END_DATE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Check if dates are provided
if [[ -z "$START_DATE" || -z "$END_DATE" ]]; then
    echo "Usage: $0 --start YYYY-MM-DD --end YYYY-MM-DD"
    exit 1
fi

# Output folder & filename
OUT_DIR="./data"
OUT_MD="$OUT_DIR/${START_DATE}_to_${END_DATE}.md"

mkdir -p "$OUT_DIR"

# Capture output into Markdown buffer
{
echo "# Weekly Report ($START_DATE to $END_DATE)"
echo ""

# PRs you created
echo "## Pull Requests You Created"
gh search prs --author "$USERNAME" --created "$START_DATE..$END_DATE" --limit 100 --json repository,title,number,createdAt,url \
| jq -r '
    group_by(.repository.name)[] |
    "### \(. [0].repository.name)\n" +
    (
        map("- [" + (.createdAt | split("T")[0]) + "] [PR#" + (.number|tostring) + "](" + .url + "): " + .title)
        | unique
        | join("\n")
    )
'

echo ""

# PRs you reviewed
echo "## Pull Requests You Reviewed"
gh search prs --reviewed-by "$USERNAME" --updated "$START_DATE..$END_DATE" --limit 100 --json repository,title,number,updatedAt,url \
| jq -r '
    group_by(.repository.name)[] |
    "### \(. [0].repository.name)\n" +
    (
        map("- [" + (.updatedAt | split("T")[0]) + "] Review [PR#" + (.number|tostring) + "](" + .url + "): " + .title)
        | unique
        | join("\n")
    )
'

} | tee "$OUT_MD"

echo ""
echo "✅ Report saved to: $OUT_DOCX"
