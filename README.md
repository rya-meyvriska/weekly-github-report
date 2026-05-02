# 📝 Weekly GitHub PR Report Script

Easily generate a weekly report of:

- **Pull Requests you created**
- **Pull Requests you reviewed**

Grouped by repository name.

---

## 📦 Requirements

- **GitHub CLI**  
    [Download here](https://cli.github.com)
- **Logged in to GitHub CLI**  
    Run:
    ```bash
    gh auth login
    ```
- **Python 3** and **pip**
- **Google Cloud Project** for Calendar API access (if including meetings)

For meetings (optional):
1. Create a Google Cloud Project: https://console.cloud.google.com/
2. Enable Google Calendar API
3. Create OAuth 2.0 credentials (Desktop app)
4. Download `client_secret.json` and save as `~/.config/weekly-report/client_secret.json`
5. Run authentication: `python3 get_meetings.py --auth`
6. Install Python dependencies: `pip install -r requirements.txt`

---

## ▶️ How to Use

1. **Save the script** as `weekly_report.sh`
2. **Make it executable:**
    ```bash
    chmod +x weekly_report.sh
    ```
3. **Create a `data` directory** to store your reports:
    ```bash
    mkdir -p data
    ```
4. **Run the script** with start and end date (format: `YYYY-MM-DD`). The generated markdown file will be saved in the `data` directory:
    ```bash
    ./weekly_report.sh --start 2026-04-12 --end 2026-04-18
    ```

---

## 🧾 Example Output

```shell
# Weekly Report (2025-06-15 to 2025-06-21)

## Pull Requests You Created
### analytics-engine
- [2025-06-16] PR#123: Fix timezone bug

### demand-sdk
- [2025-06-16] PR#78: Add batch forecast feature

## Pull Requests You Reviewed
### demand-sdk
- [2025-06-16] Review PR#80: Refactor model evaluator

## Meetings
- [2025-06-15] [Attend] Team Standup
- [2025-06-16] [No Respond] Code Review
- [2025-06-17] [Decline] Offsite Meeting
```
