"""pyRevit MCP bridge for MCP SuperAssistant (Gemini / ChatGPT web).
Starts the real pyRevit MCP server as a child process and re-exposes its tools.
READ_ONLY = True  -> only safe read tools are visible/callable.
READ_ONLY = False -> all tools pass through (incl. execute_revit_code)."""
import asyncio, os
from contextlib import AsyncExitStack
from mcp import ClientSession, StdioServerParameters, types
from mcp.client.stdio import stdio_client
from mcp.server.lowlevel import Server
from mcp.server.stdio import stdio_server

READ_ONLY = False   # <- change to True for a safe, read-only setup

ALLOW = {"get_revit_status", "get_revit_model_info", "list_levels", "list_revit_views",
         "get_current_view_info", "get_current_view_elements", "list_families",
         "list_family_categories", "list_category_parameters"}

UV = os.path.join(os.environ.get("USERPROFILE", ""), r".local\bin\uv.exe")
MAIN = os.path.join(os.environ.get("APPDATA", ""),
                    r"pyRevit\Extensions\mcp-server-for-revit-python.extension\main.py")
UPSTREAM = StdioServerParameters(
    command=UV, args=["run", "--with", "mcp[cli]<2", "--with", "httpx", "mcp", "run", MAIN])


# ---------------------------------------------------------------------------
# CUSTOM TOOLS (Winner Tools)
# Each custom tool = a fixed, tested IronPython template sent to
# execute_revit_code. Gemini only fills in simple arguments, so it can't
# write wrong or dangerous code. Add your own by copying one entry.
# ---------------------------------------------------------------------------
CUSTOM = {
    "wt_count_by_category": {
        "description": "Count all instances of a Revit category in the whole project, grouped by family and type. "
                       "category = BuiltInCategory name, e.g. OST_MechanicalControlDevices, OST_DuctCurves, OST_MechanicalEquipment.",
        "schema": {"type": "object", "properties": {"category": {"type": "string"}}, "required": ["category"]},
        "code": """
cat = getattr(DB.BuiltInCategory, {category!r})
els = DB.FilteredElementCollector(doc).OfCategory(cat).WhereElementIsNotElementType().ToElements()
def tname(t):
    p = t.get_Parameter(DB.BuiltInParameter.SYMBOL_NAME_PARAM) if t else None
    return p.AsString() if p else ''
groups = {{}}
for e in els:
    t = doc.GetElement(e.GetTypeId())
    fam = getattr(t, 'FamilyName', '') if t else ''
    key = (fam, tname(t))
    groups[key] = groups.get(key, 0) + 1
print('Family | Type | Count')
for (f, n), c in sorted(groups.items()):
    print('%s | %s | %d' % (f, n, c))
print('TOTAL | | %d' % len(els))
""",
    },
    "wt_list_instances": {
        "description": "List every instance of a category in the whole project with Id, Family, Type, Level and the "
                       "requested parameters (e.g. ['Mark','Width','Height','Depth']). Lengths are converted to mm.",
        "schema": {"type": "object", "properties": {
            "category": {"type": "string"},
            "params": {"type": "array", "items": {"type": "string"}}}, "required": ["category"]},
        "code": """
cat = getattr(DB.BuiltInCategory, {category!r})
params = {params!r}
els = DB.FilteredElementCollector(doc).OfCategory(cat).WhereElementIsNotElementType().ToElements()
def tname(t):
    p = t.get_Parameter(DB.BuiltInParameter.SYMBOL_NAME_PARAM) if t else None
    return p.AsString() if p else ''
def val(e, name):
    p = e.LookupParameter(name)
    if p is None:
        t = doc.GetElement(e.GetTypeId())
        p = t.LookupParameter(name) if t else None
    if p is None or not p.HasValue: return ''
    if p.StorageType == DB.StorageType.Double:
        try:
            if p.Definition.GetDataType() == DB.SpecTypeId.Length: return '%.0f' % (p.AsDouble() * 304.8)
        except Exception: pass
        return p.AsValueString() or str(p.AsDouble())
    return p.AsString() or p.AsValueString() or ''
print(' | '.join(['Id', 'Family', 'Type', 'Level'] + params))
for e in els:
    t = doc.GetElement(e.GetTypeId())
    lv = doc.GetElement(e.LevelId) if e.LevelId != DB.ElementId.InvalidElementId else None
    row = [str(e.Id.IntegerValue), getattr(t, 'FamilyName', '') if t else '', tname(t),
           lv.Name if lv else ''] + [val(e, n) for n in params]
    print(' | '.join(row))
print('TOTAL: %d' % len(els))
""",
    },
}

server = Server("pyrevit-bridge")
upstream: ClientSession | None = None

def allowed(name: str) -> bool:
    return (not READ_ONLY) or name in ALLOW

@server.list_tools()
async def list_tools():
    tools = (await upstream.list_tools()).tools
    # drop outputSchema so results pass through as plain text content
    out = [t.model_copy(update={"outputSchema": None}) for t in tools if allowed(t.name)]
    out += [types.Tool(name=n, description=c["description"], inputSchema=c["schema"]) for n, c in CUSTOM.items()]
    return out

@server.call_tool()
async def call_tool(name: str, arguments: dict | None):
    if name in CUSTOM:   # custom tools are read-only templates -> allowed in both modes
        a = arguments or {}
        code = CUSTOM[name]["code"].format(category=str(a.get("category", "")),
                                           params=[str(p) for p in a.get("params", [])])
        name, arguments = "execute_revit_code", {"code": code, "description": name}
    elif not allowed(name):
        raise ValueError(f"BLOCKED: '{name}' is not allowed in read-only mode.")
    res = await upstream.call_tool(name, arguments or {})
    if res.isError:
        text = " ".join(getattr(c, "text", str(c)) for c in res.content)
        raise RuntimeError(text or f"{name} failed")
    return res.content

async def main():
    global upstream
    async with AsyncExitStack() as stack:
        r, w = await stack.enter_async_context(stdio_client(UPSTREAM))
        upstream = await stack.enter_async_context(ClientSession(r, w))
        await upstream.initialize()
        async with stdio_server() as (sr, sw):
            await server.run(sr, sw, server.create_initialization_options())

if __name__ == "__main__":
    asyncio.run(main())
