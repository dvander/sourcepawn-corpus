#define VERSION "1.1"

public Plugin:myinfo = 
{
	name        = "Mscript",
	author      = "Bottiger",
	description = "Map specific plugin loading script",
	version     = VERSION,
	url         = "https://www.skial.com"
};

StringMap g_plugins;

public void OnPluginStart() 
{
    CreateConVar("sm_mscript_version", VERSION, "mscript version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_plugins = new StringMap();

    RegServerCmd("mscript_load", Cmd_Load, "load an mscript file");
    RegServerCmd("mscript_reload", Cmd_Reload, "reload all loaded mscripts");
    RegServerCmd("mscript_unload", Cmd_Unload, "unload all loaded mscripts");
}

public void OnMapStart()
{
    char map[64];
    GetCurrentMap(map, sizeof(map));

    if(PluginExists(map))
    {
        PrintToServer("[mscript] Loading mscript for map");
        ServerCommand("mscript_load %s", map);
    }
}

public void OnMapEnd()
{
    StringMapSnapshot snapshot = g_plugins.Snapshot();
    for(int i=0;i<snapshot.Length;i++)
    {
        char name[64];
        snapshot.GetKey(i, name, sizeof(name));
        ServerCommand("sm plugins unload disabled/mscript/%s", name);
    }
    delete snapshot;
    g_plugins.Clear();
}

public Action Cmd_Load(int args)
{
    char name[64];
    GetCmdArgString(name, sizeof(name));
    TrimString(name);

    if(!PluginExists(name))
    {
        PrintToServer("[mscript] plugin does not exist: %s", name);
        return Plugin_Handled;
    }

    int junk;
    if(g_plugins.GetValue(name, junk))
    {
        PrintToServer("[mscript] mscript already loaded: %s", name);
        return Plugin_Handled;
    }

    g_plugins.SetValue(name, 1);
    ServerCommand("sm plugins load disabled/mscript/%s", name);
    return Plugin_Handled;
}

public Action Cmd_Reload(int args)
{
    StringMapSnapshot snapshot = g_plugins.Snapshot();
    for(int i=0;i<snapshot.Length;i++)
    {
        char name[64];
        snapshot.GetKey(i, name, sizeof(name));
        ServerCommand("sm plugins reload disabled/mscript/%s", name);
    }
    delete snapshot;
}

public Action Cmd_Unload(int args)
{
    StringMapSnapshot snapshot = g_plugins.Snapshot();
    for(int i=0;i<snapshot.Length;i++)
    {
        char name[64];
        snapshot.GetKey(i, name, sizeof(name));
        ServerCommand("sm plugins unload disabled/mscript/%s", name);
    }
    delete snapshot;
    g_plugins.Clear();
}

bool PluginExists(char[] plugin_name)
{
    char path[256];
    BuildPath(Path_SM, path, sizeof(path), "plugins/disabled/mscript/%s.smx", plugin_name);
    return FileExists(path);
}