#pragma semicolon 1
#pragma newdecls required

#include <multicolors>

static char TAG[] = "☆";		// Example: "{darkred}[www.FrmAkDaG.Com] "

int kills[MAXPLAYERS+1], headshots[MAXPLAYERS+1];
bool enabled;

public Plugin myinfo = 
{
	name		= "[AWP] No-Scope Detector",
	author		= "Ak0 (improved by Grey83)",
	description	= "Awp Maping No-Scope Detector",
	version		= "1.2.2_debug",
	url			= "https://forums.alliedmods.net/showthread.php?t=290241"
}


public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO && GetEngineVersion() != Engine_CSS) SetFailState("Plugin supports CSS and CS:GO only.");

	LoadTranslations("core.phrases");
	LoadTranslations("noscope_gotcha.phrases");

	ConVar CVar;
	HookConVarChange((CVar = CreateConVar("sm_noscope_enable", "1", "0/1 - Disable/Enable messages", FCVAR_NOTIFY, true, 0.0, true, 1.0)), CVarChange);
	enabled = CVar.BoolValue;

	RegConsoleCmd("noscopes", Cmd_NoScopes, "Shows number NoScope kills and HS");

	HookEvent("player_death", OnPlayerDeath);
}

public void CVarChange(ConVar CVar, const char[] oldValue, const char[] newValue)
{ enabled = CVar.BoolValue; }

public void OnClientConnected(int client)
{
	kills[client] = headshots[client] = 0;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	PrintToServer("	Attacker: %i", attacker);
	if(!(0 < attacker <= MaxClients && IsClientInGame(attacker))) return;

	char weapon[16];
	event.GetString("weapon", weapon, sizeof(weapon));
	PrintToServer("	Weapon: %s\n	FOV: %i", weapon, GetEntProp(attacker, Prop_Data, "m_iFOV"));

	if((StrContains(weapon, "awp") != -1 || StrContains(weapon, "ssg08") != -1 || StrContains(weapon, "scout") != -1) || !(0 < GetEntProp(attacker, Prop_Data, "m_iFOV") < GetEntProp(attacker, Prop_Data, "m_iDefaultFOV")))
	{
		char sName[MAX_NAME_LENGTH];
		GetClientName(attacker, sName, sizeof(sName));
		kills[attacker]++;
		static bool bHS;
		if((bHS = event.GetBool("headshot"))) headshots[attacker]++;

		if(enabled)
		{
			if(bHS)
			{
				CPrintToChatAll("%T", "HS2All", TAG, sName);
				PrintToChat(attacker, "%t", "HS", headshots[attacker]);
			}
			else CPrintToChatAll("%T", "Kill2All", TAG, sName);
			PrintToChat(attacker, "%t", "Kill", kills[attacker]);
		}
		PrintToServer("	Name: %s\n	Kills: %i\n HS: %s (%i)", sName, kills[attacker], bHS ? "true" : "false", headshots[attacker]);
	}
}

public Action Cmd_NoScopes(int client, int args)
{
	if(0 < client <= MaxClients && IsClientInGame(client))
	{
		PrintToServer("	%L (%i)\n	Kills: %i\n HS: %i", client, kills[client], headshots[client]);
		if(!enabled) ReplyToCommand(client, "[SM] %t", "No Access");
		else
		{
			PrintToChat(client, "%t", "HS", headshots[client]);
			PrintToChat(client, "%t", "Kill", kills[client]);
		}
	}
	return Plugin_Handled;
}