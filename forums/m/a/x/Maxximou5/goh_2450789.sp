#include <sourcemod>

ConVar g_Cvar_goh_name;
ConVar g_Cvar_goh_type;

char g_sCvar_goh_name[MAX_NAME_LENGTH];

int g_iCvar_goh_type;

#define PLUGIN_VERSION          "1.0.0"
#define PLUGIN_NAME             "Get Out of Here!"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Simple kick/ban on client connect for a certain user name."
#define PLUGIN_URL              "https://maxximou5.com/"

public Plugin myinfo =
{
    name                        = PLUGIN_NAME,
    author                      = PLUGIN_AUTHOR,
    description                 = PLUGIN_DESCRIPTION,
    version                     = PLUGIN_VERSION,
    url                         = PLUGIN_URL
}

public void OnPluginStart()
{
	g_Cvar_goh_name = CreateConVar("sm_goh_name", "LOSER", "Name of the user you wish to ban.");
	g_Cvar_goh_type = CreateConVar("sm_goh_type", "1", "Type of punishment for offender: 0 = KICK / 1 = BAN.");

	GetConVarString(g_Cvar_goh_name, g_sCvar_goh_name, sizeof(g_sCvar_goh_name));
	g_iCvar_goh_type = GetConVarInt(g_Cvar_goh_type);

	AutoExecConfig(true, "getout");
}

public void OnConfigsExecuted()
{
	GetConVarString(g_Cvar_goh_name, g_sCvar_goh_name, sizeof(g_sCvar_goh_name));
	g_iCvar_goh_type = GetConVarInt(g_Cvar_goh_type);
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (IsFakeClient(client))
		return;

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	if (StrEqual(g_sCvar_goh_name, name, false))
	{
		if (g_iCvar_goh_type == 1)
			BanClient(client, 0, BANFLAG_AUTO, "User is not allowed here", "You're not welcome here");
		else
			KickClient(client, "You're not welcome here");
	}
}