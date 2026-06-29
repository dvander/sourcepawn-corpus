#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <tf2jail>
#include <morecolors>

#define PLUGIN_VERSION "1.0"

#define ctag "[Kills]"

ConVar hConVars[3];
bool cv_Chat, cv_Center, cv_Hint;

public Plugin myinfo = {
	name        = "[TF2Jail] Kill Announcer",
	author      = "Riotline & Sgt. Gremulock",
	description = "Announces deaths with TF2Jail with customizable cvars.",
	version     = PLUGIN_VERSION,
	url         = "sourcemod.net"
};

public void OnPluginStart()
{
	CreateConVars();
	HookEvents();
}

CreateConVars()
{
	CreateConVar("tf2jail_killannouncer_version", PLUGIN_VERSION, "Plugin's version.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	hConVars[0]		= CreateConVar("tf2jail_killannouncer_chat", "1", "Announce kills in chat.", _, true, 0.0, true, 1.0);
	hConVars[1]		= CreateConVar("tf2jail_killannouncer_center", "0", "Announce kills in center text (sm_csay).", _, true, 0.0, true, 1.0);
	hConVars[2]		= CreateConVar("tf2jail_killannouncer_hint", "0", "Announce kills in hint text (sm_hsay).", _, true, 0.0, true, 1.0);
	
	for (int i = 0; i <= sizeof(hConVars); i++)
	{
		HookConVarChange(hConVars[i], CvarUpdate);
	}
}

public void CvarUpdate(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	cv_Chat = hConVars[0].BoolValue;
	cv_Center = hConVars[1].BoolValue;
	cv_Hint = hConVars[2].BoolValue;
}

public void OnMapStart()
{
	cv_Chat = hConVars[0].BoolValue;
	cv_Center = hConVars[1].BoolValue;
	cv_Hint = hConVars[2].BoolValue;
}

public void OnConfigsExecuted()
{
	cv_Chat = hConVars[0].BoolValue;
	cv_Center = hConVars[1].BoolValue;
	cv_Hint = hConVars[2].BoolValue;
}

/////////////////////////////////////////////////////////////////////

HookEvents()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	new victim = GetClientOfUserId(event.GetInt("userid"));
	new attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	char attackertag[MAX_NAME_LENGTH], victimtag[MAX_NAME_LENGTH], message[256];
	
	if (IsValidClient(attacker) && IsValidClient(victim))
	{
		if (TF2_GetClientTeam(attacker) == TFTeam_Red)
		{
			attackertag = "(Rebel)";
		}
		else if (TF2_GetClientTeam(attacker) == TFTeam_Blue)
		{
			if (TF2Jail_IsWarden(attacker))
			{
				attackertag = "(Warden)";
			}
			else
			{
				attackertag = "(Guard)";
			}
		}
		
		if (TF2_GetClientTeam(victim) == TFTeam_Red)
		{
			if (TF2Jail_IsRebel(victim))
			{
				victimtag = "(Rebel)";
			}
			else if (!TF2Jail_IsRebel(victim))
			{
				victimtag = "(Non-Rebel)";
			}
			
			if (TF2Jail_IsFreeday(victim))
			{
				victimtag = "(Freeday)";
			}
		}
		else if (TF2_GetClientTeam(victim) == TFTeam_Blue)
		{
			if (TF2Jail_IsWarden(victim))
			{
				victimtag = "(Warden)";
			}
			else
			{
				victimtag = "(Guard)";
			}
		}
		
		if (cv_Chat)
		{
			char chatmsg[256];
			
			if (StrEqual(victimtag, "(Warden)"))
			{
				Format(victimtag, sizeof(victimtag), "{blue}%s{default} %N", victimtag, victim);
			}
			else if (StrEqual(victimtag, "(Guard)"))
			{
				Format(victimtag, sizeof(victimtag), "{cyan}%s{default} %N", victimtag, victim);
			}
			else if (StrEqual(victimtag, "(Rebel)"))
			{
				Format(victimtag, sizeof(victimtag), "{red}%s{default} %N", victimtag, victim);
			}
			else if (StrEqual(victimtag, "(Non-Rebel)"))
			{
				Format(victimtag, sizeof(victimtag), "{orange}%s{default} %N", victimtag, victim);
			}
			else if (StrEqual(victimtag, "(Freeday)"))
			{
				Format(victimtag, sizeof(victimtag), "{lightblue}%s{default} %N", victimtag, victim);
			}
			
			if (StrEqual(attackertag, "(Warden)"))
			{
				Format(attackertag, sizeof(attackertag), "{blue}%s{default} %N", attackertag, attacker);
			}
			else if (StrEqual(attackertag, "(Guard)"))
			{
				Format(attackertag, sizeof(attackertag), "{cyan}%s{default} %N", attackertag, attacker);
			}
			else if (StrEqual(attackertag, "(Rebel)"))
			{
				Format(attackertag, sizeof(attackertag), "{red}%s{default} %N", attackertag, attacker);
			}
			else if (StrEqual(attackertag, "(Non-Rebel)"))
			{
				Format(attackertag, sizeof(attackertag), "{orange}%s{default} %N", attackertag, attacker);
			}
			
			Format(chatmsg, sizeof(chatmsg), "{lightgreen}%s{default} %s killed %s", ctag, attackertag, victimtag);
			
			CPrintToChatAll(chatmsg);
		}
		
		Format(message, sizeof(message), "%s %s %N killed %s %N", ctag, attackertag, attacker, victimtag, victim);
		
		if (cv_Center)
		{
			PrintCenterTextAll(message);
		}
		
		if (cv_Hint)
		{
			PrintHintTextToAll(message);
		}
	}
}

/////////////////////////////////////////////////////////////////////

bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client))
	{
		return false;
	}
	
	return IsClientInGame(client);
}