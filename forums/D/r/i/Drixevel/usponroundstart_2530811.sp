//Pragma
#pragma semicolon 1
#pragma newdecls required

//Sourcemod Includes
#include <sourcemod>
#include <sdktools>
#include <cstrike>

//Plugin Info
public Plugin myinfo = 
{
	name = "USP on round start", 
	author = "Keith Warren (Drixevel)", 
	description = "Gives a USP to CT players on round start.", 
	version = "1.0.0", 
	url = "http://www.drixevel.com/"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_OnRoundStart);
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, Timer_GiveUSP, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_GiveUSP(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			int weapon = GivePlayerItem2(i, "weapon_usp_silencer");
			EquipPlayerWeapon(i, weapon);
		}
	}
}

int GivePlayerItem2(int client, const char[] item)
{
	int team = GetClientTeam(client);
	SetEntProp(client, Prop_Send, "m_iTeamNum", team == 3 ? 2 : 3);
	int weapon = GivePlayerItem(client, item);
	SetEntProp(client, Prop_Send, "m_iTeamNum", team);
	return weapon;
}  