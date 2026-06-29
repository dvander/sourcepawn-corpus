#include <sourcemod>
#include <tf2_stocks>
#include <tf2>

#pragma semicolon 1

#define PLUGIN_VERSION	"1.1"
new Handle:cEnabled	= INVALID_HANDLE;
new Handle:cTeams	= INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Engineer vs Spy WAR",
	author = "404: User Not Found",
	description = "Sets RED team to Engineers, BLU team to Spies. WAR!!!",
	version = PLUGIN_VERSION,
	url = "http://www.unfgaming.net"
}
 
public OnPluginStart()
{
	CreateConVar("sm_engispywar_version", PLUGIN_VERSION, "Engineer vs Spy WAR Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cEnabled = CreateConVar("sm_engispywar_enabled", "1", "Enable/disable the plugin", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cTeams = CreateConVar("sm_engispywar_team", "1", "Switch teams", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cEnabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(IsValidClient(client))
		{
			new team = GetClientTeam(client);
			if(team == _:TFTeam_Red)
			{
				new cTeam = GetConVarBool(cTeams);
				if (cTeam == 0)
				{
					TF2_SetPlayerClass(client, TFClass_Engineer);
				}
				if (cTeam == 1)
				{
					TF2_SetPlayerClass(client, TFClass_Spy);
				}
			}
			if(team == _:TFTeam_Blue)
			{
				new cTeam = GetConVarBool(cTeams);
				if (cTeam == 0)
				{
					TF2_SetPlayerClass(client, TFClass_Spy);
				}
				if (cTeam == 1)
				{
					TF2_SetPlayerClass(client, TFClass_Engineer);
				}
			}
			if(IsPlayerAlive(client))
			{
				SetEntityHealth(client, 25);
				TF2_RegeneratePlayer(client);
				new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				if(IsValidEntity(weapon))
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
				}
			}
		}
	}
}

stock bool:IsValidClient(client, bool:replay = true)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client)) return false;
	if(replay && (IsClientSourceTV(client) || IsClientReplay(client))) return false;
	return true;
}