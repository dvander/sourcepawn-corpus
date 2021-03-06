/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "1.2d"
#define INFECTEDTEAM 3
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

new Handle:g_hConVar_JockeyReleaseOn;
new Handle:g_hConVar_HunterReleaseOn;
new Handle:g_hConVar_ChargerReleaseOn;
new bool:g_isJockeyEnabled;
new bool:g_isHunterEnabled;
new bool:g_isChargerEnabled;

new bool:g_ButtonDelay[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[L4D2] Infected Release",
	author = "Thraka",
	description = "Allows infected players to release victims with the melee button.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=109715"
}

public OnPluginStart()
{
	CreateConVar("l4d2_infected_release_ver", PLUGIN_VERSION, "Version of the infected release plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	g_hConVar_JockeyReleaseOn = CreateConVar("l4d2_jockey_dismount_on", "1", "Jockey dismount is on or off. 1 = on", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hConVar_HunterReleaseOn = CreateConVar("l4d2_hunter_release_on", "1", "Hunter release is on or off. 1 = on", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hConVar_ChargerReleaseOn = CreateConVar("l4d2_charger_release_on", "1", "Charger release is on or off. 1 = on", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	HookConVarChange(g_hConVar_JockeyReleaseOn, CVarChange_JockeyRelease);
	HookConVarChange(g_hConVar_HunterReleaseOn, CVarChange_HunterRelease);
	HookConVarChange(g_hConVar_ChargerReleaseOn, CVarChange_ChargerRelease);
	
	AutoExecConfig(true, "l4d2_infected_release");
	
	SetJockeyRelease();
	SetHunterRelease();
	SetChargerRelease();
}

/*
* ===========================================================================================================
* ===========================================================================================================
* 
* CVAR Change events
* 
* ===========================================================================================================
* ===========================================================================================================
*/

public CVarChange_JockeyRelease(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetJockeyRelease();
}

public CVarChange_HunterRelease(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetHunterRelease();
}

public CVarChange_ChargerRelease(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetChargerRelease();
}

SetJockeyRelease()
{
	if (GetConVarInt(g_hConVar_JockeyReleaseOn) == 1)
	{
		g_isJockeyEnabled = true;
	}
	else
	{
		g_isJockeyEnabled = false;
	}	
}

SetHunterRelease()
{
	if (GetConVarInt(g_hConVar_HunterReleaseOn) == 1)
	{
		g_isHunterEnabled = true;
	}
	else
	{
		g_isHunterEnabled = false;
	}	
}

SetChargerRelease()
{
	if (GetConVarInt(g_hConVar_ChargerReleaseOn) == 1)
	{
		g_isChargerEnabled = true;
	}
	else
	{
		g_isChargerEnabled = false;
	}	
}

/*
* ===========================================================================================================
* ===========================================================================================================
* 
* Normal Hooks\Events
* 
* ===========================================================================================================
* ===========================================================================================================
*/

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (client == 0)
		return Plugin_Continue;
	
	if (buttons & IN_ATTACK2 && !g_ButtonDelay[client])
	{
		if (GetClientTeam(client) == INFECTEDTEAM)
		{
			new zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
			
			if (zombieClass == ZOMBIECLASS_JOCKEY && g_isJockeyEnabled)
			{
				new h_vic = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
				
				if (IsValidEntity(h_vic))
				{
					ExecuteCommand(client, "dismount");
					
					CreateTimer(3.0, ResetDelay, client)
					g_ButtonDelay[client] = true;
				}
			}
			else if (zombieClass == ZOMBIECLASS_HUNTER && g_isHunterEnabled)
			{
				new h_vic = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
				
				if (IsValidEntity(h_vic))
				{
					//SetEntProp(client, Prop_Send, "m_pounceVictim", -1);
					//SetEntProp(h_vic, Prop_Send, "m_pounceAttacker", -1);
					SetEntityMoveType(client, MOVETYPE_NOCLIP);
					CreateTimer(0.01, ResetMoveType, client)
					CreateTimer(3.0, ResetDelay, client)
					g_ButtonDelay[client] = true;
				}
			}
			else if (zombieClass == ZOMBIECLASS_CHARGER && g_isChargerEnabled)
			{
				new h_vic = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
				
				if (IsValidEntity(h_vic))
				{
					//SetEntProp(client, Prop_Send, "m_pummelVictim", -1);
					//SetEntProp(h_vic, Prop_Send, "m_pummelAttacker", -1);
					SetEntityMoveType(client, MOVETYPE_NOCLIP);
					CreateTimer(0.01, ResetMoveType, client)
					CreateTimer(3.0, ResetDelay, client)
					g_ButtonDelay[client] = true;
				}
			}
		}
	}
	
	// If delayed, don't let them click
	if (buttons & IN_ATTACK && g_ButtonDelay[client])
	{
		buttons &= ~IN_ATTACK;
	}
	
	// If delayed, don't let them click
	if (buttons & IN_ATTACK2 && g_ButtonDelay[client])
	{
		buttons &= ~IN_ATTACK2;
	}
	
	return Plugin_Continue;
}


public Action:ResetDelay(Handle:timer, any:client)
{
	g_ButtonDelay[client] = false;
}
public Action:ResetMoveType(Handle:timer, any:client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
}
/*
* ===========================================================================================================
* ===========================================================================================================
* 
* Private Methods
* 
* ===========================================================================================================
* ===========================================================================================================
*/

ExecuteCommand(Client, String:strCommand[])
{
	new flags = GetCommandFlags(strCommand);
    
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s", strCommand);
	SetCommandFlags(strCommand, flags);
}
