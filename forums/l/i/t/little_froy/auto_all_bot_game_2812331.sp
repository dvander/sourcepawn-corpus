#define PLUGIN_VERSION	"1.0"
#define PLUGIN_NAME		"Auto All Bot Game"
#define PLUGIN_PREFIX   "auto_all_bot_game"

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

public void ConnectedCounter_OnDisconnect(int userid, int count, const int userids[MAXPLAYERS])
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

void get_cvars()
{
    O_enable = C_enable.BoolValue;
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
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
    C_enable = CreateConVar(PLUGIN_PREFIX ... "_enable", "1", "1 = enable the plugin, 0 = disable");
    C_enable.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    get_cvars();
}