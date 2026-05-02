#!/bin/bash

# Default values
START_DATE=""
END_DATE=""
USERNAME=$(gh api user --jq .login)

get_month_num() {
    case "$1" in
        Jan) echo "01" ;;
        Feb) echo "02" ;;
        Mar) echo "03" ;;
        Apr) echo "04" ;;
        May) echo "05" ;;
        Jun) echo "06" ;;
        Jul) echo "07" ;;
        Aug) echo "08" ;;
        Sep) echo "09" ;;
        Oct) echo "10" ;;
        Nov) echo "11" ;;
        Dec) echo "12" ;;
        *) echo "" ;;
    esac
}

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

echo ""
echo "## Meetings"
declare -A unique_meetings
current_date=""
in_range=false
day=""
while IFS= read -r line; do
    if [[ -z $day ]] && echo "$line" | grep -qE "^[0-9]+$"; then
        day="$line"
    elif [[ -n $day ]] && echo "$line" | grep -qE "^[A-Z][a-z]{2} [0-9]{4}, [A-Z][a-z]+$"; then
        month=$(echo "$line" | cut -d' ' -f1)
        year=$(echo "$line" | cut -d' ' -f2 | cut -d',' -f1)
        month_num=$(get_month_num "$month")
        if [[ -n $month_num ]]; then
            day_padded=$(printf "%02d" "$day")
            parsed_date="$year-$month_num-$day_padded"
            if [ "$parsed_date" \> "$START_DATE" -o "$parsed_date" = "$START_DATE" ] && [ "$parsed_date" \< "$END_DATE" -o "$parsed_date" = "$END_DATE" ]; then
                in_range=true
            else
                in_range=false
            fi
            current_date="$parsed_date"
        fi
        day=""
    else
        if $in_range && [[ -n $line ]]; then
            if ! echo "$line" | grep -qE "^[0-9]{1,2}:[0-9]{2}" && ! echo "$line" | grep -q "Microsoft" && ! echo "$line" | grep -qE "^https://" && ! echo "$line" | grep -qE "^[A-Z][a-z]+ [0-9]+" && ! echo "$line" | grep -qE "^[a-z]" && ! echo "$line" | grep -qiE "office|event|floor|jl\.|rt\."; then
                if ! echo "$line" | grep -qi "reminder"; then
                    unique_meetings["$line"]=1
                fi
            fi
        fi
        day=""
    fi
done < meeting.txt
printf '%s\n' "${!unique_meetings[@]}" | sort | while IFS= read -r meeting; do
    echo "- $meeting"
done

} | tee "$OUT_MD"

echo ""
echo "✅ Report saved to: $OUT_MD"
