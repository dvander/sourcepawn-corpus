#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>

bool g_pPouncing[MAXPLAYERS+1];

ConVar CatchSurvivor;

bool CanCatch;

public Plugin myinfo =
{
	name		= "[L4D2] Hunter Captures Charger Survivor",
	author		= "King_OXO(WhiteFire)",
	description	= "Hunter captures charger's victim when falls on top",
	version		= "1.0",
	url			= "https://forums.alliedmods.net/showthread.php?p=2826510#post2826510"
}

public void OnPluginStart()
{
	HookEvent("ability_use", Event_Ability);
	
	CatchSurvivor = CreateConVar("l4d_hunterpick", "1", "Enable or disable to the hunter catchs the charger's victim", FCVAR_NOTIFY, true, 0.0, true,1.0);
	
	CanCatch = CatchSurvivor.BoolValue;
	
	AutoExecConfig(true, "l4d_hunterpick");
}

void Event_Ability(Event event, char[] name, bool dontBroadcast)
{
	int user = GetClientOfUserId(event.GetInt("userid"));
	char abilityName[64];
	
	GetEventString(event, "ability", abilityName, sizeof(abilityName));
	if(IsValidClient(user, 3) && strcmp(abilityName, "ability_lunge", false) == 0 && !g_pPouncing[user])
	{
		g_pPouncing[user] = true;
		SDKHook(user, SDKHook_TouchPost, HunterTouch);
	}
}

void HunterTouch(int client, int other)
{
	if(other > 0 && other <= MaxClients)
	{
		if(g_pPouncing[client] && CanCatch)
		{
			int charger = L4D_GetAttackerCharger(other);
			if(IsValidClient(charger, 3) && IsValidClient(other, 2))
			{
				L4D2_Charger_EndPummel(other, charger);
				L4D_ForceHunterVictim(other, client);
					
				SDKUnhook(client, SDKHook_TouchPost, HunterTouch);
				g_pPouncing[client] = false;
			}
		}
	}
}

bool IsValidClient(int client, int team)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == team;
}