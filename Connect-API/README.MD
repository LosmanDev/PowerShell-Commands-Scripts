# Connect-API Scripts

A collection of PowerShell code blocks that connect to Exchange/MS Graph & Teams APIs.

## Execution Warning

> **Do not execute these files as whole scripts without inspection as their is multiple blocks that do different results.**
---

## Recommended Workflow (VS Code / IDE)

These scripts are structured to work best inside an IDE such as **Visual Studio Code** equipped with the **PowerShell extension**.

1. **Inspect First:** Review the file to locate the exact logic block you need.
2. **Execute Selected Lines:**
   - Highlight only the target block.
   - Press **`F8`** (Run Selection) to load variables or trigger the specific API call.
3. **Comment Out Unused Sections:**
   - Use `#` or `<# ... #>` to suppress code blocks not relevant to your current task before running adjacent code.
4. **Isolate into Separate Files:**
   - Copy only the relevant configuration, headers, and request commands into a dedicated, clean `.ps1` file for standalone execution.

---

## Running in a Terminal (PowerShell 7)

If you must run these outside an IDE directly within a **PowerShell 7 (`pwsh`)** terminal, you **must**:

1. **Extract your specific routine into a standalone script:** Do not pass the raw repo files directly to `./script.ps1` or `pwsh -File`.
2. **Define environment variables/prerequisites manually:** Scripts often rely on session-state variables (tokens, base URLs, headers) established in earlier lines. Running a subset without initializing its dependencies will fail.
3. **Use dot-sourcing or interactive pasting:**
   - Copy and paste the specific code segment into the interactive session.
   - Alternatively, isolate functions and dot-source only what is needed:
     ```powershell
     . ./path/to/extracted-function.ps1
     ```
4. **Verify API payloads:** Confirm that write methods (`POST`, `PUT`, `PATCH`, `DELETE`) have valid targets and parameters before pressing Enter.

---

## Prerequisites

- **PowerShell 7+ (`pwsh`)**
- Valid API credentials/tokens (set these in local variables or environment variables; never commit raw credentials to source control).
