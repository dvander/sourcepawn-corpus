#include <sourcemod>

public Plugin myinfo =
{
	name = "No Cheats",
	description = "Forces sv_cheats to never be enabled",
	author = "Tiny Desk Engineer",
	version = "1.0",
	url = "https://steamcommunity.com/id/tiny-desk-engineer/"
}

ConVar g_cvEnabled;
ConVar g_cvBroadcast;
ConVar g_cvCheats;

public void OnPluginStart()
{
	g_cvEnabled = CreateConVar("sm_nocheats_enabled", "1", "Is No Cheats enabled?", FCVAR_NOTIFY | FCVAR_PRINTABLEONLY | FCVAR_SERVER_CAN_EXECUTE)
	g_cvBroadcast = CreateConVar("sm_nocheats_broadcast", "1", "Broadcast message on No Cheats trigger?", FCVAR_NOTIFY | FCVAR_PRINTABLEONLY | FCVAR_SERVER_CAN_EXECUTE);
	g_cvCheats = FindConVar("sv_cheats");
	
	g_cvCheats.AddChangeHook(OnCheatsChanged);
}

public void OnCheatsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_cvEnabled.BoolValue)
	{
		if (g_cvCheats.BoolValue)
		{
			g_cvCheats.BoolValue = false;
			
			if (g_cvBroadcast.BoolValue)
			{
				PrintToChatAll("[SM] Cheats enabled on server, Cheats are not allowed and have been auto-disabled");
			}
			
			LogMessage("NoCheats triggered");
		}
	}
}