#define PLUGIN_VERSION	"1.2"
#define PLUGIN_NAME		"Map Change"
#define PLUGIN_PREFIX   "map_change"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "Alex Dragokas, fdxx, sorallll, little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344329"
};

char Data_path[PLATFORM_MAX_PATH];

bool is_valid_map(const char[] map)
{
	char path[PLATFORM_MAX_PATH];
	return FindMap(map, path, sizeof(path)) == FindMap_Found;
}

bool change_map()
{
    if(!FileExists(Data_path))
    {
        return false;
    }
    bool changed = false;
    KeyValues kv = new KeyValues(PLUGIN_PREFIX);
    if(kv.ImportFromFile(Data_path))
    {
        char current_map[128];
        GetCurrentMap(current_map, sizeof(current_map));
        if(kv.JumpToKey(current_map))
        {
            char next[128];
            kv.GetString("next", next, sizeof(next));
            if(is_valid_map(next))
            {
                changed = true;
                L4D_RestartScenarioFromVote(next);
            }
        }
    }
    delete kv;
    return changed;
}

Action on_um_DisconnectToLobby(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if(change_map())
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/%s.cfg", PLUGIN_PREFIX);

    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);

    HookUserMessage(GetUserMessageId("DisconnectToLobby"), on_um_DisconnectToLobby, true);
}