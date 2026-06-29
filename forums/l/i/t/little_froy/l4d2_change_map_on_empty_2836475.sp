#define PLUGIN_VERSION	"1.3"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <l4d2_changelevel>
#include <connected_counter>

#define LITTLE_FROY_INTEGER_MAX	0x7FFFFFFF

public Plugin myinfo =
{
	name = "L4D2 Change Map On Empty",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=350941"
};

ConVar C_enable;
bool O_enable;

char Map_path[PLATFORM_MAX_PATH];

ArrayList Maps;

int G_exit_id = -1;
int Exit_id_current = -1;

bool is_valid_map(const char[] map_get)
{
	char path[PLATFORM_MAX_PATH];
	return FindMap(map_get, path, sizeof(path)) == FindMap_Found;
}

int get_string_comment_index(const char[] str)
{
    int len = strlen(str);
    bool ignoring = false;
    for(int i = 0; i < len; i++)
    {
        if(ignoring)
        {
            if(str[i] == '"')
            {
                ignoring = false;
            }
        }
        else
        {
            if(str[i] == '"')
            {
                ignoring = true;
            }
            else if(str[i] == '/' && i != len - 1 && str[i + 1] == '/')
            {
                return i;
            }
        }
    }
    return -1;
}

void change_map()
{
    char map_get[64];
    if(Maps.Length == 0)
    {
        GetCurrentMap(map_get, sizeof(map_get));
    }
    else
    {
        Maps.GetString(GetRandomInt(0, Maps.Length - 1), map_get, sizeof(map_get));
        if(!is_valid_map(map_get))
        {
            GetCurrentMap(map_get, sizeof(map_get));
        }
    }
    L4D2_ChangeLevel(map_get);
}

public void ConnectedCounter_OnDisconnect(int userid, int count, const int userids[MAXPLAYERS], const char[] reason, const char[] name, const char[] networkid)
{
    if(!O_enable)
    {
        return;
    }
    if(Exit_id_current != -1)
    {
        return;
    }
    if(count == 0)
    {
        change_map();
    }
}

void frame_exit(int id)
{
    if(id == Exit_id_current)
    {
        Exit_id_current = -1;
    }
}

Action on_cmd_exit(int client, const char[] command, int argc)
{
    G_exit_id++;
    if(G_exit_id == LITTLE_FROY_INTEGER_MAX)
    {
        G_exit_id = 0;
    }
    Exit_id_current = G_exit_id;
    RequestFrame(frame_exit, G_exit_id);
    return Plugin_Continue;
}

void load_list()
{
    Maps.Clear();
    File file = OpenFile(Map_path, "rt");
    if(file)
    {
        char line[2048];
        while(file.ReadLine(line, sizeof(line)))
        {
            int delimiter = get_string_comment_index(line);
            if(delimiter != -1)
            {
                line[delimiter] = '\0';
            }
            TrimString(line);
            if(line[0] != '\0')
            {
                Maps.PushString(line);
            }
        }
        delete file;
    }
}

Action cmd_reload(int client, int args)
{
    load_list();
    return Plugin_Handled;
}

void get_all_cvars()
{
    O_enable = C_enable.BoolValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_enable)
    {
        O_enable = C_enable.BoolValue;
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2 || !IsDedicatedServer())
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\" dedicated server");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    Maps = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));

    BuildPath(Path_SM, Map_path, sizeof(Map_path), "data/l4d2_change_map_on_empty.txt");

    C_enable = CreateConVar("l4d2_change_map_on_empty_enable", "1", "1 = enable the plugin, 0 = disable");
    C_enable.AddChangeHook(convar_changed);
    CreateConVar("l4d2_change_map_on_empty_version", PLUGIN_VERSION, "version of L4D2 Change Map On Empty", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, "l4d2_change_map_on_empty");
    get_all_cvars();
    load_list();

    AddCommandListener(on_cmd_exit, "exit");
    AddCommandListener(on_cmd_exit, "quit");

    RegAdminCmd("sm_l4d2_change_map_on_empty_reload", cmd_reload, ADMFLAG_ROOT, "reload config data from file");
}
