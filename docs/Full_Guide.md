# How to Control Revit from Gemini Web Chat — Full Guide

*Winner Tools · Revit 2023 · pyRevit MCP · MCP SuperAssistant · tested October 2026*

---

## 1. What this does (in simple words)

Gemini in your browser **cannot see your computer**. It can only write text.
So we put three small helpers between Gemini and Revit:

```
 Gemini (browser)
     │  Gemini writes a "tool call" in the chat
     ▼
 MCP SuperAssistant  (Chrome extension)
     │  sees the tool call, you click Run, it sends it to your PC
     ▼
 SuperAssistant Proxy  (http://localhost:3006/mcp, on your laptop)
     │
     ▼
 pyrevit_bridge.py → pyRevit MCP server  (on your laptop)
     │
     ▼
 pyRevit Routes  (http://localhost:48884, inside Revit)
     │
     ▼
 Revit 2023 → result goes back up the same way → Gemini reads it
```

- Everything after the Chrome extension runs **only on your laptop** (`localhost`). No ngrok, no cloud server, no cost.
- The connection type is **Streamable HTTP**. It is stable (SSE mode crashed when the page reconnected, so don't use it).
- **You stay in control.** Gemini only *suggests* a tool call. Nothing happens in Revit until **you click Run**.

---

## 2. What you need

### On the laptop
| # | Item | Why | Check |
|---|---|---|---|
| 1 | Windows 10/11 | — | — |
| 2 | **Google Chrome** (or Edge) | Runs Gemini and the extension | — |
| 3 | **uv** (Python runner) | Runs the MCP servers, downloads Python packages by itself | `uv --version` |
| 4 | **Node.js LTS** | Runs the SuperAssistant proxy (`npx`) | `node --version` |
| 5 | **MCP SuperAssistant** Chrome extension | Connects the Gemini page to the proxy | Icon in Chrome toolbar |
| 6 | A Google account with **Gemini** | The chat | gemini.google.com |

### In Revit
| # | Item | Why |
|---|---|---|
| 1 | **Revit 2023** (2022–2026 also OK) | — |
| 2 | **pyRevit 7 (latest)** | Gives the Routes web server inside Revit |
| 3 | **pyRevit Routes enabled** (port **48884**) | The door that the MCP server knocks on |
| 4 | **pyRevit MCP extension** (`mcp-server-for-revit-python`) | Provides the Revit tools (list levels, run code, …) |
| 5 | A model **open** in Revit | Tools read from the active document |

---

## 3. One-time installation

### Repo files
| File | What it's for |
|---|---|
| `install.ps1` | One installer that does everything it can automatically |
| `src/pyrevit_bridge.py` | The bridge between the proxy and the pyRevit MCP server (+ the `wt_` custom tools) |
| `src/start-gemini-proxy.ps1` | Starts the SuperAssistant proxy (the Desktop shortcut runs this) |
| `docs/PowerShell_Commands.md` | Every PowerShell command in numbered copy boxes (step by step, checks, safe mode, uninstall) |
| `README.md` | Quick start |

### PowerShell-only route
Prefer to see every command? Open **docs/PowerShell_Commands.md** and paste **STEP 1 → STEP 12** in order. It installs everything except pyRevit and ends with a full check (STEP 10). The steps below do the same thing with the installer script.

### Step 1 — pyRevit 7 (manual)
1. Close Revit. Install the latest **pyRevit 7** from <https://github.com/pyrevitlabs/pyRevit/releases>.
2. Open Revit once so pyRevit finishes setting up.

### Step 2 — Run the installer
Open **Windows PowerShell** and paste **one** of these:

**Option A — one line** (downloads the files of release v1.0.0):
```powershell
irm https://raw.githubusercontent.com/kyawswar-22/gemini-revit-mcp/v1.0.0/install.ps1 | iex
```

**Option B — download first, read, then run** (use this if your company blocks Option A):
1. On GitHub: **Code → Download ZIP** → unzip it, e.g. to **Downloads**.
2. Read `install.ps1` if you like, then:
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\gemini-revit-mcp-main\install.ps1"
```
What it does (6 steps, each prints **[OK]** or **[TODO]**):

| # | Step | Automatic? | If [TODO] |
|---|---|---|---|
| 1 | Install **uv** to `%USERPROFILE%\.local\bin\uv.exe` | Yes | Paste STEP 2 of `docs/PowerShell_Commands.md` |
| 2 | Install **Node.js LTS** with `winget` | Yes (if winget exists) | Install LTS from <https://nodejs.org> |
| 3 | Check **pyRevit** and run `pyrevit configs routes enable` | Yes | Revit → pyRevit → Settings → **Routes ON** |
| 4 | Download the **pyRevit MCP extension** into `%APPDATA%\pyRevit\Extensions\mcp-server-for-revit-python.extension` | Yes (skips if already there) | Download it from GitHub and copy it there |
| 5 | Copy/download `pyrevit_bridge.py` and `start-gemini-proxy.ps1` to `C:\WinnerTools`, create `superassistant\config.json` | Yes | Download the ZIP and run Option B |
| 6 | Create Desktop shortcut **Start Gemini-Revit** | Yes | Start with the command in *DAILY USE* |

- Safe to run again and again — it only adds missing things.
- It doesn't delete your other files. Only the 3 files in `C:\WinnerTools` are refreshed; if you had edited `pyrevit_bridge.py`, your old copy is kept as `pyrevit_bridge.py.bak`.
- Run it until every line is **[OK]**. Close and reopen PowerShell if `uv`/`node` were just installed.

### Step 3 — Finish in Revit
1. **pyRevit** tab → **Settings** → **Routes** → make sure it's **ON** (port **48884**) → **Save Settings and Reload**.
2. **pyRevit** → **Reload** so the MCP extension loads.
3. Test (model open): in PowerShell
   **▶ COPY this box into PowerShell** (everything inside the box = one paste → Right-click → Enter):
```powershell
   Invoke-RestMethod http://localhost:48884/revit_mcp/status/
   ```
   A reply = Revit side is ready. An error = Routes is off or the extension isn't loaded.

### Step 4 — Chrome extension
Chrome Web Store → **MCP SuperAssistant** → **Add to Chrome** → pin it.

---

## 4. Every time you use it

### Step 1 — Open Revit and a model
Wait until the model is fully loaded.

### Step 2 — Start the proxy
Double-click **Start Gemini-Revit** on the Desktop, or:
**▶ COPY this box into PowerShell** (everything inside the box = one paste → Right-click → Enter):
```powershell
powershell -NoExit -ExecutionPolicy Bypass -File "C:\WinnerTools\start-gemini-proxy.ps1"
```
- **Keep this window open** while you use Gemini. Closing it = disconnect.
- Run only **one** proxy window at a time (two windows fight over port 3006).

### Step 3 — Connect the extension (first time only, it remembers)
1. Open <https://gemini.google.com> → click the **MCP SuperAssistant** icon (or the **MCP** button in the Gemini input bar) to open the sidebar.
2. Click the ⚙ / server settings:
   - Transport: **Streamable HTTP**
   - URL: `http://localhost:3006/mcp`
   - **Connect**
3. You should see **Server Connected**.
4. **Available Tools** tab → **Enable All** → **Save Changes**. It should say **22 of 22** (20 pyRevit + 2 custom), or 11 in read-only mode.
5. **Settings** tab: keep **Auto Execute OFF** (so you approve every run). Auto Insert / Auto Submit may be ON or OFF — your choice.

### Step 4 — Start a new chat and insert the instructions
1. Click **New chat** in Gemini.
2. Sidebar → **Instructions** tab → **Insert** (or MCP button → Insert).
   The long "[SuperAssistant Operational Instructions]…" text appears **in the Gemini prompt box**.
   - Do **not** type your question into the sidebar's **Edit** box. If you clicked Edit by mistake → **Cancel**.
3. At the very end of that text (after `User Interaction Starts here:`), type your request. Example:
   ```
   Call execute_revit_code with Python code that counts all Mechanical Control Devices
   in the whole project, grouped by family and type, and prints each instance's
   Id, Level, Mark, Width, Height and Depth. Read-only: no Transaction.
   ```
4. Send.

> Do this **once per new chat**. Without the instructions, Gemini doesn't know the tools exist and will just write a script for you to run yourself.

### Step 5 — Check, then Run
1. Gemini replies with a box like **`pyrevit.execute_revit_code`** with **Show Raw Info** and **Run**.
2. Click **Show Raw Info** and read the code first (see Section 5).
3. Click **Run**. Revit does the work, and the result appears under the box.

### Step 6 — Send the result back to Gemini
- If **Auto Insert** is OFF: click **Insert** (or **Attach** for long results) under the result → add e.g. `Summarize this as a table` → Send.
- Gemini then answers with the table. ✅

If Gemini says *"please provide the output"*, the result was not inserted yet — do Step 6.

---

## 5. Safety rules (important)

`execute_revit_code` can do **anything** Revit can do, including deleting elements in a central model. Before clicking **Run**, check the code in **Show Raw Info**:

| OK for read-only | Stop and don't Run if you see |
|---|---|
| `FilteredElementCollector(doc)` | `Transaction(` / `t.Start()` (unless you really want a change) |
| `.LookupParameter(...).AsString()` | `.Delete(`, `doc.Delete` |
| `print(...)` | `.Set(` on parameters |
| `BuiltInCategory.OST_...` | `Save`, `SynchronizeWithCentral`, `Close` |

Extra tips:
- In the code, use the ready-made variables **`doc`**, **`uidoc`**, **`DB`**. Don't use `__revit__`.
- Test on a **copy / detached model** first, not the live central file.
- Want it fully safe? Use **Safe mode ON** in `docs/PowerShell_Commands.md` (or open `C:\WinnerTools\pyrevit_bridge.py`, set `READ_ONLY = True`, save), then close the proxy window and start it again. Then only 9 read tools + the 2 custom tools are visible (levels, views, families, categories, parameters, model info…). `execute_revit_code`, `place_family`, `save_document`, `sync_with_central` etc. are hidden and blocked.
- Gemini can see the data you send it. Don't send confidential project data if your company doesn't allow it.

---

## 6. Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| Extension shows **Disconnected** | Proxy not running | Start `start-gemini-proxy.ps1`, then click the 🔄 reconnect icon |
| Proxy window error **"Already connected to a transport"** | Using SSE mode | Use **Streamable HTTP** + `http://localhost:3006/mcp` (the script already does) |
| **0 tools** or **Partial** (e.g. 10 of 22) | Tools disabled in the extension | Available Tools → **Enable All** → **Save Changes** |
| Gemini writes a script instead of a tool call | Instructions not inserted in this chat | New chat → Instructions → **Insert** → then ask |
| Gemini says it doesn't have `execute_revit_code` | Old instructions / read-only mode | Check `READ_ONLY = False`, restart proxy, refresh the Gemini page, new chat, Insert again |
| Gemini: *"please provide the output"* | Result not inserted | Click **Insert/Attach** under the result |
| Gemini refuses to summarise the result | Gemini safety quirk | Regenerate, or say "Summarize the tool result above as a table" |
| Tool error **connection refused / 48884** | Revit closed, Routes off, or no model open | Open Revit + model; check `http://localhost:48884/revit_mcp/status/` |
| `uv` / `npx` **not recognized** | PATH not refreshed | Close and reopen PowerShell (or restart the PC) |
| Numbers look strange (e.g. 59.06) | Revit API uses **feet** internally | Ask Gemini to convert to mm (`× 304.8`) |
| Port 3006 busy | A second proxy window is open | Close all proxy windows, start one |

---

## 7. Quick checklist (daily use)

1. ☐ Revit open + model loaded
2. ☐ **Start Gemini-Revit** running (one window)
3. ☐ Gemini → sidebar → **Server Connected**, tools **Enabled**
4. ☐ **New chat** → **Insert** instructions → type question → Send
5. ☐ **Show Raw Info** → check code → **Run**
6. ☐ **Insert** result → "Summarize as a table" → Send

---

## 8. The weak point: tools — and how to get more

Gemini can only do what the tools let it do. With **zero tools** it can only write text. So the number and quality of tools decide how useful this is.

But there's one important detail:

| Tool type | Example | Good | Bad |
|---|---|---|---|
| **Specific tools** | `list_levels`, `list_families` | Fast, safe, always correct | Can only do that one job |
| **Generic tool** | `execute_revit_code` | Can do **almost anything** the Revit API can | Gemini must write correct IronPython each time; can make mistakes; risky (can delete/modify) |

So you are not stuck with "only 20 things" — `execute_revit_code` is a master key. The real goal is: **turn the jobs you do often into specific, tested tools**, so Gemini doesn't have to invent code every time.

### Ways to get more tools (easiest first)

**Way 1 — Custom tools inside `pyrevit_bridge.py` (recommended, already included)**
The bridge now has a `CUSTOM` section. Each custom tool is a **fixed, tested code template** that runs through `execute_revit_code`. Gemini only fills in simple inputs (like a category name), so it can't write wrong or dangerous code. Already included:

| Tool | Input | Output |
|---|---|---|
| `wt_count_by_category` | `category` e.g. `OST_MechanicalControlDevices` | Count per Family / Type + total (whole project) |
| `wt_list_instances` | `category`, `params` e.g. `["Mark","Width","Height","Depth"]` | Id, Family, Type, Level + params (lengths in mm) |

*Tested on a real project model: the count matched a Revit schedule.*
Custom tools are read-only, so they also work when `READ_ONLY = True`.
To add one: copy an entry in `CUSTOM`, change the name, description, input schema and code → save → restart the proxy → in the extension **Enable All → Save Changes**.

Ideas for MEP / ACMV work: duct size summary by system, untagged elements in active view, elements missing a `Mark`, equipment schedule export, clash-prone duct vs beam level check.

**Way 2 — Save good `execute_revit_code` scripts**
When Gemini writes code that works well, copy it from **Show Raw Info** into a file like `C:\WinnerTools\snippets\*.py`. Later, turn the best ones into Way 1 tools. (This is how your tool library grows naturally.)

**Way 3 — Add more MCP servers to the same proxy**
`C:\WinnerTools\superassistant\config.json` can hold **several servers**; the extension shows all their tools together. For example:
- `@modelcontextprotocol/server-filesystem` — read/write files in one folder (e.g. save CSV exports)
- an Excel MCP server — write results straight into `.xlsx`

Add another entry under `"mcpServers"` (same format as Claude Desktop config) → restart the proxy.

**Way 4 — New routes in the pyRevit MCP extension (advanced)**
Add a new route in the extension's `startup.py` (runs inside Revit) and a matching `@mcp.tool()` in `main.py`. More work, but best for heavy or complex tools. ⚠️ Updating the extension from Git can overwrite your changes — keep a copy.

**Way 5 — Build your own Revit MCP server (most work)**
A C# add-in with an `ExternalEvent` bridge + a Python `mcp` server, with `dry_run` / confirm for write tools. Best control, but a real software project.

### Other weak points to know
- **Manual clicks**: every tool call needs Run + Insert (Auto Execute is possible but not safe).
- **Instructions per chat**: you must Insert the instructions in every new chat.
- **Big results**: very long outputs can be cut or refused — ask for summaries/counts, or use `Attach`.
- **Gemini is not built for MCP**: it's a browser trick. Claude Desktop (native MCP) is more reliable for daily work.

---

## 9. Sharing with a colleague

1. Send them the link to this repo.
2. They follow the **README** Quick Start. This guide is for when something goes wrong.
3. Nothing is tied to one user name — all paths use `%USERPROFILE%` / `%APPDATA%`.
4. Ask your IT team first if company laptops don't allow installing software or running PowerShell scripts.
5. Remind them: test on a **copy** of a model, and never Run code that saves or syncs a central file without checking it.
