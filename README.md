# gemini-revit-mcp

**Control Autodesk Revit from Gemini web chat** — ask in plain words, check the code, click Run.

*Winner Tools · Revit 2022–2026 (tested on 2023) · pyRevit · MCP SuperAssistant*

<!-- VIDEO: replace with your YouTube link and thumbnail
[![Watch the setup video](docs/images/thumbnail.png)](https://www.youtube.com/watch?v=VIDEO_ID)
-->

```
Gemini (Chrome) → MCP SuperAssistant extension → proxy on your laptop → pyRevit → Revit
```

Gemini can't touch your PC by itself. A Chrome extension and a small program on your laptop pass Gemini's requests to Revit. Everything after the extension runs on **your laptop only** (`localhost`). **Nothing runs in Revit until you click Run.**

---

## What you need

| | Item | Notes |
|---|---|---|
| ☐ | Windows 10/11 laptop | Admin rights help for installing |
| ☐ | Revit 2022–2026 | Tested on Revit 2023 |
| ☐ | **[pyRevit](https://github.com/pyrevitlabs/pyRevit/releases)** | Must already be installed |
| ☐ | Google Chrome + a Google account | For [gemini.google.com](https://gemini.google.com) |

The installer adds the rest: **uv** (Python comes with it), **Node.js**, the **pyRevit MCP extension** and the bridge files.

---

## Install (one time)

**1. Close Revit.**

**2. Open Windows PowerShell and paste one line:**

```powershell
irm https://raw.githubusercontent.com/kyawswar-22/gemini-revit-mcp/v1.0.0/install.ps1 | iex
```

Every line should end green **[OK]**. Fix any yellow **[TODO]** and run it again — it is safe to repeat.

> **Company laptop or prefer to read first?** **Code → Download ZIP**, unzip, read `install.ps1`, then run
> `powershell -ExecutionPolicy Bypass -File .\install.ps1` from that folder.
> Or paste every step yourself with [docs/PowerShell_Commands.md](docs/PowerShell_Commands.md).

**3. In Revit:** pyRevit tab → Settings → **Routes ON** (port 48884) → Save Settings and Reload.

**4. In Chrome:**
1. Chrome Web Store → **MCP SuperAssistant** → **Add to Chrome** → pin it.
2. Double-click **Start Gemini-Revit** on your Desktop (a blue window opens — keep it open).
3. Open [gemini.google.com](https://gemini.google.com) → click the **MCP** button → sidebar opens.
4. Server settings: **Streamable HTTP** · `http://localhost:3006/mcp` → **Connect** → **Server Connected**.
5. **Available Tools** → **Enable All** → **Save Changes** (22 tools).
6. **Settings** → keep **Auto Execute OFF**.

---

## Every day (5 steps)

1. **Open Revit** and a model.
2. Double-click **Start Gemini-Revit** on the Desktop. Keep the window open.
3. Gemini → **New chat** → sidebar **Instructions** → **Insert** → type your question at the end → send.
   Example: `Use wt_count_by_category with category OST_MechanicalEquipment.`
4. Gemini shows a tool box → **Show Raw Info** (check the code) → **Run**.
5. Under the result click **Insert** → type `Summarize as a table` → send.

> **Insert the instructions in every new chat** — otherwise Gemini doesn't know it has tools.

### Good questions to try

| Ask Gemini | Tool it should use |
|---|---|
| "List all levels" | `list_levels` |
| "Count all Mechanical Equipment by family and type" | `wt_count_by_category` (`OST_MechanicalEquipment`) |
| "List all control devices with Mark, Width, Height, Depth" | `wt_list_instances` |
| "What views are in this model?" | `list_revit_views` |

---

## Safety

`execute_revit_code` can **change or delete** things. Always check **Show Raw Info** before **Run**; never run code with `Transaction`, `Delete`, `Save` or `SynchronizeWithCentral` on a live central model. Test on a copy first.

Want read-only? Set `READ_ONLY = True` in `C:\WinnerTools\pyrevit_bridge.py` (or use **Safe mode ON** in [docs/PowerShell_Commands.md](docs/PowerShell_Commands.md)) and restart the proxy window.

Gemini sees whatever results you send it. **Don't send confidential project data if your company doesn't allow it.**

---

## Not working?

| You see | Do this |
|---|---|
| **Disconnected** | Start **Start Gemini-Revit**, then click 🔄 in the sidebar |
| Gemini writes a script instead of a tool box | New chat → **Insert** instructions → ask again |
| Gemini: "please provide the output" | Click **Insert** under the result |
| Tool error **48884** / connection refused | Open Revit + model; check Routes is ON; pyRevit → Reload |
| 0 tools / Partial | **Enable All** → **Save Changes** |

More detail: [docs/Full_Guide.md](docs/Full_Guide.md).

---

## What's in this repo

```
install.ps1                  one-line installer (steps 1–6)
src/pyrevit_bridge.py        bridge + wt_ custom tools (read-only templates)
src/start-gemini-proxy.ps1   starts the proxy (the Desktop shortcut runs this)
docs/Full_Guide.md           how it works, safety, troubleshooting, adding tools
docs/PowerShell_Commands.md  every step as a copy box
```

Add your own tools: copy an entry in the `CUSTOM` section of `src/pyrevit_bridge.py` — see *Full Guide § 8*.

## Credits

This repo only glues these projects together — they do the real work:

- [mcp-server-for-revit-python](https://github.com/mcp-servers-for-revit/mcp-server-for-revit-python) — the pyRevit MCP extension (downloaded by the installer, not included here)
- [MCP SuperAssistant](https://github.com/srbhptl39/MCP-SuperAssistant) — Chrome extension and proxy
- [pyRevit](https://github.com/pyrevitlabs/pyRevit) — Routes web server inside Revit
- [uv](https://github.com/astral-sh/uv) — Python runner

Not affiliated with Autodesk or Google. Use at your own risk — see [LICENSE](LICENSE).
