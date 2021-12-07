#pragma semicolon 1
#pragma newdecls required

#include <multicolors>

static char TAG[] = "";		// Example: "{darkred}[www.FrmAkDaG.Com] "

int kills[MAXPLAYERS+1], headshots[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name		= "[AWP] No-Scope Detector",
	author		= "Ak0 (improved by Grey83)",
	description	= "Awp Maping No-Scope Detector",
	version		= "1.2.1",
	url			= "https://forums.alliedmods.net/showthread.php?t=290241"
}


public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO && GetEngineVersion() != Engine_CSS) SetFailState("Plugin supports CSS and CS:GO only.");
	LoadTranslations("noscope_gotcha.phrases");
	HookEvent("player_death", OnPlayerDeath);
}

public void OnClientConnected(int client)
{
	kills[client] = headshots[client] = 0;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(!(0 < attacker <= MaxClients && IsClientInGame(attacker))) return;

	char weapon[16];
	event.GetString("weapon", weapon, sizeof(weapon));

	if((StrContains(weapon, "awp") != -1 || StrContains(weapon, "ssg08") != -1 || StrContains(weapon, "scout") != -1) || !(0 < GetEntProp(attacker, Prop_Data, "m_iFOV") < GetEntProp(attacker, Prop_Data, "m_iDefaultFOV")))
	{
		char sName[MAX_NAME_LENGTH];
		GetClientName(attacker, sName, sizeof(sName));
		if(event.GetBool("headshot")) 
		{
			headshots[attacker]++;
			CPrintToChatAll("%T", "HS2All", TAG, sName);
			PrintToChat(attacker, "%t", "HS", headshots[attacker]);
		}
		else
		{
			kills[attacker]++;
			CPrintToChatAll("%T", "Kill2All", TAG, sName);
			PrintToChat(attacker, "%t", "Kill", kills[attacker]);
		}
	}
}