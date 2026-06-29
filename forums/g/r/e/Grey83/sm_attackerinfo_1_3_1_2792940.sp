#pragma semicolon 1
#pragma newdecls required

#include <multicolors>

#define DEBUG

char
	sPrefix[64];
bool
	bSuicide,
	bKill;

public Plugin myinfo =
{
	name		= "Attacker Info on Chat",
	version		= "1.3.1 (rewritten by Grey83)",
	author		= "LanteJoula",
	url			= "https://steamcommunity.com/id/lantejoula/ https://forums.alliedmods.net/showthread.php?t=332405"
}

public void OnPluginStart()
{
	LoadTranslations("attackerinfo.phrases");

	ConVar cvar;
	cvar = CreateConVar("sm_attackerinfo_chat_prefix", "[{green}TAG{default}]", "Chat Prefix", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CvarChange_Prefix);
	CvarChange_Prefix(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_attackerinfo_suicide_message", "1", "Enable/Disable the Message when Player Suicide(1 - Enable | 0 - Disable)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CvarChange_Suicide);
	bSuicide = cvar.BoolValue;

	cvar = CreateConVar("sm_attackerinfo_message", "1", "Enable/Disable the Message when Player Died with Name and Health of Attacker(1 - Enable | 0 - Disable)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CvarChange_Kill);
	bKill = cvar.BoolValue;

	AutoExecConfig(true, "plugin.attackerinfo");

	HookEvent("player_death", Event_PlayerDeath);
}

public void CvarChange_Prefix(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	cvar.GetString(sPrefix, sizeof(sPrefix));
}

public void CvarChange_Suicide(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bSuicide = cvar.BoolValue;
}

public void CvarChange_Kill(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bKill = cvar.BoolValue;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client)) return;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(!IsValidClient(attacker)) return;

	if(attacker == client) //Suicide
	{
		if(bSuicide) CPrintToChat(attacker, "%s %t", sPrefix, "Suicide Message");
	}
	else if(bKill)
	{
		static char Name3[MAX_NAME_LENGTH];
		GetClientName(attacker, Name3, sizeof(Name3));
		CPrintToChat(client, "%s %t", sPrefix, "Message", Name3, GetClientHealth(attacker));
	}
}

stock bool IsValidClient(int client)
{
	return client && IsClientInGame(client) && !IsClientSourceTV(client);
}