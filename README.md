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
    ./weekly_report.sh --start 2025-06-15 --end 2025-06-21
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
```
