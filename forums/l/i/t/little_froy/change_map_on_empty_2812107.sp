#define PLUGIN_VERSION	"1.3"
#define PLUGIN_NAME		"Change Map On Empty"
#define PLUGIN_PREFIX   "change_map_on_empty"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <connected_counter>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344328"
};

ConVar C_enable;
bool O_enable;
ConVar C_log;
bool O_log;

char Map_path[PLATFORM_MAX_PATH];
char Log_path[PLATFORM_MAX_PATH];

bool is_valid_map(const char[] map)
{
	char path[PLATFORM_MAX_PATH];
	return FindMap(map, path, sizeof(path)) == FindMap_Found;
}

void change_map()
{
    ArrayList map_list = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
    if(FileExists(Map_path))
    {
        File fl = OpenFile(Map_path, "r");
        if(fl)
        {
            while(!fl.EndOfFile())
            {
                char line[PLATFORM_MAX_PATH];
                if(fl.ReadLine(line, sizeof(line)))
                {
                    TrimString(line);
                    if(strlen(line) && line[0] != '/' && is_valid_map(line))
                    {
                        map_list.PushString(line);
                    }
                }
            }
            delete fl;
        }
    }
    char map_get[PLATFORM_MAX_PATH];
    bool empty_list = false;
    if(map_list.Length == 0)
    {
        GetCurrentMap(map_get, sizeof(map_get));
        empty_list = true;
    }
    else
    {
        map_list.GetString(GetRandomInt(0, map_list.Length - 1), map_get, sizeof(map_get));
    }
    delete map_list;
    if(O_log)
    {
        LogToFileEx(Log_path, "%s to %s.", empty_list ? "restart map cause empty map list" : "change map", map_get);
    }
	ForceChangeLevel(map_get, "server empty");
}

public void ConnectedCounter_OnDisconnect(int userid, int count, const int userids[MAXPLAYERS])
{
    if(!O_enable)
    {
        return;
    }
    if(count == 0)
    {
        change_map();
    }
}

void get_cvars()
{
    O_enable = C_enable.BoolValue;
    O_log = C_log.BoolValue;
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
}

public void OnPluginStart()
{
    if(!IsDedicatedServer())
    {
        SetFailState("this plugin only run in dedicated server");
    }

    BuildPath(Path_SM, Map_path, sizeof(Map_path), "data/%s.txt", PLUGIN_PREFIX);
    BuildPath(Path_SM, Log_path, sizeof(Log_path), "logs/%s_%d.log", PLUGIN_PREFIX, FindConVar("hostport").IntValue);

    C_enable = CreateConVar(PLUGIN_PREFIX ... "_enable", "1", "1 = enable the plugin, 0 = disable");
    C_enable.AddChangeHook(convar_changed);
    C_log = CreateConVar(PLUGIN_PREFIX ... "_log", "1", "enable log?");
    C_log.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    get_cvars();
}