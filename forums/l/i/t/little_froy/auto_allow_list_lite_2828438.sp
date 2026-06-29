#define PLUGIN_VERSION	"1.1"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <allow_list_lite>
#define REQUIRE_PLUGIN
#include <connected_counter>

public Plugin myinfo =
{
	name = "Auto Enable/Disable Allow List Lite Edition",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=349282"
};

ConVar C_enable;
bool O_enable;
ConVar C_enable_allow_list_lite;

public void AllowListLite_OnPassed(int client, const char[] ip, const char[] auth)
{
    if(!C_enable_allow_list_lite || !O_enable)
    {
        return;
    }
    C_enable_allow_list_lite.BoolValue = false;
}

public void ConnectedCounter_OnDisconnect(int userid, int count, const int userids[MAXPLAYERS])
{
    if(!C_enable_allow_list_lite || !O_enable)
    {
        return;
    }
    if(count == 0)
    {
        C_enable_allow_list_lite.BoolValue = true;
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

public void OnPluginStart()
{
    C_enable = CreateConVar("auto_allow_list_lite_enable", "1", "1 = enable the plugin, 0 = disable");
    C_enable.AddChangeHook(convar_changed);
    CreateConVar("auto_allow_list_lite_version", PLUGIN_VERSION, "version of Auto Enable/Disable Allow List Lite Edition", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, "auto_allow_list_lite");
    get_all_cvars();
}

public void OnAllPluginsLoaded()
{
    if(!C_enable_allow_list_lite)
    {
        C_enable_allow_list_lite = FindConVar("allow_list_lite_enable");
    }
}
