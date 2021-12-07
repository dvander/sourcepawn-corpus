#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.5"

new propinfoghost;
new teleporttarget[MAXPLAYERS+1] = 0;
new bool:teleportdelay[MAXPLAYERS+1];


public Plugin:myinfo = 
{
	name = "Infected Ghost Everywhere SM 1.3",
	author = "AtomicStryker",
	description = "Instead of always teleporting to the lead Survivor, you can iterate them all SM 1.3 ONLY",
	version = "PLUGIN_VERSION",
	url = "http://forums.alliedmods.net/showthread.php?t=97002"
}


public OnPluginStart()
{
	CreateConVar("l4d_infectedghosteverywhere_version", PLUGIN_VERSION, " Version of L4D Infected Ghost Everywhere on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_USE && teleportdelay[client] == false)
	{
		if (!IsClientInGame(client)) return Plugin_Continue;
		if (GetClientTeam(client)!=3) return Plugin_Continue;
		if (!IsPlayerSpawnGhost(client)) return Plugin_Continue;
		
		// Whoever pressed USE must be valid, connected, ingame, Infected and a Ghost
		// Perform the teleport, if target is ingame, alive and a Survivor
		
		//PrintToChatAll("Use was pressed by valid Infected");
		
		// pressing use for prolonged time switches you too fast. add a delay of 1 second
		teleportdelay[client] = true;
		CreateTimer(1.0, ResetTeleportDelay, client);
		
		new any:target = FindNewTarget(client, teleporttarget[client]);
		if (!IsClientInGame(target)) target = FindNewTarget(client, 1);
		if (target == client) target = FindNewTarget(client, target);
		
		decl Float:position[3], Float:anglestarget[3];
		
		if (!IsClientInGame(target)) return Plugin_Continue;
		GetClientAbsOrigin(target, position);
		GetClientAbsAngles(target, anglestarget);
		TeleportEntity(client, position, anglestarget, NULL_VECTOR);
		
		PrintCenterText(client, "Warped to %N", target);
		
		teleporttarget[client] = target;
		
		// block the ingame teleporter
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool:IsPlayerSpawnGhost(client)
{
	if (GetEntData(client, propinfoghost, 1)) return true;
	else return false;
}

public Action:ResetTeleportDelay(Handle:timer, Handle:client)
{
	teleportdelay[client] = false;
}

public Action:FindNewTarget(any:client, any:target)
{
	target++;
	
	for (new i = target; i >= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientHealth(i)>1 && (GetClientTeam(i) == 2) && client != i)
		{
			target = i;
			break;
		}
		if (i >= MaxClients)
		{
			target = 0;
		}
	}
	
	if (!IsClientInGame(target))
	{
		for (new i2 = 1; i2 >= MaxClients; i2++)
		{
			if (IsClientInGame(i2) && GetClientHealth(i2)>1 && (GetClientTeam(i2) == 2) && client != i2)
			{
				target = i2;
				break;
			}
			if (i2 >= MaxClients)
			{
				target = 0;
			}
		}
	}
	return target;
}