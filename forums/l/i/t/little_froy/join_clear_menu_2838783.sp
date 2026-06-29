#define PLUGIN_VERSION  "1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "Join Clear Menu",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351419"
};

public void OnClientPutInServer(int client)
{
    if(IsFakeClient(client))
    {
        return;
    }
    ClientCommand(client, "slot10");
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
    CreateConVar("join_clear_menu_version", PLUGIN_VERSION, "version of Join Clear Menu", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}