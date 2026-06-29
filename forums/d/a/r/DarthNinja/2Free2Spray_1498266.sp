#include <sourcemod>
#include <sdktools>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

#define PLUGIN_VERSION "1.1.0"

new Handle:v_ChatNotice = INVALID_HANDLE;

public Plugin:myinfo = {
	name        = "[Any] 2Free2Spray",
	author      = "DarthNinja",
	description = "Prevent free players from using sprays.",
	version     = PLUGIN_VERSION,
	url         = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("sm_nofreesprays_version", PLUGIN_VERSION, "2Free2Spray!", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	v_ChatNotice = CreateConVar("sm_2f2s_chatnotice", "1", "Show a notice when blocking sprays 1/0", 0, true, 0.0, true, 1.0);
	AddTempEntHook("Player Decal", OnClientSpray);
}

public Action:OnClientSpray(const String:te_name[], const clients[], client_count, Float:delay)
{
	new client = TE_ReadNum("m_nPlayer");
	if(client && IsClientInGame(client))
	{		
		if (!IsClientAuthorized(client) || IsFakeClient(client))
		{
			return Plugin_Handled;
		}
		if (CheckCommandAccess(client, "Free2SprayOverride", ADMFLAG_RESERVATION, true))
		{
			return Plugin_Continue;
		}
		if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
		{
			if (GetConVarBool(v_ChatNotice))
				PrintToChat(client, "\x05Sorry! Only premimum players can use sprays!");
				
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}