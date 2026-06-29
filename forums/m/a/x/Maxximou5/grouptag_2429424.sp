#include <cstrike>
#include <sourcemod>
// Defined Variables
#define PLUGIN_VERSION          "1.0.0"
#define PLUGIN_NAME             "Group Tag"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Allows for clients to apply a tag to themselves"
#define PLUGIN_URL              "http://maxximou5.com/"
// Plugin Creater Info
public Plugin myinfo =
{
    name                        = PLUGIN_NAME,
    author                      = PLUGIN_AUTHOR,
    description                 = PLUGIN_DESCRIPTION,
    version                     = PLUGIN_VERSION,
    url                         = PLUGIN_URL
}
// ConVars
ConVar g_hCvar_Group_Tag = null;
char g_sCvar_Group_Tag[64];
// Plugin Start
public void OnPluginStart()
{
	RegConsoleCmd("sm_group", cmd_group, "Sets the client's clan tag to the specified tag");
	g_hCvar_Group_Tag = CreateConVar("sm_group_tag", "[GROUPTAG]", "Group tag name");
	HookConVarChange(g_hCvar_Group_Tag, OnSettingsChange);
	GetConVarString(g_hCvar_Group_Tag, g_sCvar_Group_Tag, sizeof(g_sCvar_Group_Tag));
	AutoExecConfig(true, "grouptag");
}

public void OnConfigsExecuted()
{
	GetConVarString(g_hCvar_Group_Tag, g_sCvar_Group_Tag, sizeof(g_sCvar_Group_Tag));
}

public Action cmd_group(int client, int args)
{
	if (IsValidClient(client))
	{
		CS_SetClientClanTag(client, g_sCvar_Group_Tag);
	}
}

public OnSettingsChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

stock bool IsValidClient(int client)
{
    if (!(0 < client <= MaxClients)) return false;
    if (!IsClientInGame(client)) return false;
    if (IsFakeClient(client)) return false;
    return true;
}