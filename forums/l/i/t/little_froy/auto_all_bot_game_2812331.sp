#define PLUGIN_VERSION	"1.1"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <connected_counter>

public Plugin myinfo =
{
	name = "Auto All Bot Game",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344390"
};

ConVar C_sb_all_bot_game;
ConVar C_enable;
bool O_enable;

public void OnClientPutInServer(int client)
{
    if(!O_enable)
    {
        return;
    }
    if(!C_sb_all_bot_game.BoolValue && !IsFakeClient(client))
    {
        C_sb_all_bot_game.BoolValue = true;
    }
}

public void ConnectedCounter_OnDisconnect(int userid, int count, const int userids[MAXPLAYERS], const char[] reason, const char[] name, const char[] networkid)
{
    if(!O_enable)
    {
        return;
    }
    if(count == 0 && C_sb_all_bot_game.BoolValue)
    {
        C_sb_all_bot_game.BoolValue = false;
    }
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
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    C_sb_all_bot_game = FindConVar("sb_all_bot_game");
    C_enable = CreateConVar("auto_all_bot_game_enable", "1", "1 = enable the plugin, 0 = disable");
    C_enable.AddChangeHook(convar_changed);
    CreateConVar("auto_all_bot_game_version", PLUGIN_VERSION, "version of Auto All Bot Game", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, "auto_all_bot_game");
    get_all_cvars();
}
