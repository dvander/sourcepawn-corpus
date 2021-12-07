#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "L4D2 Witch Fire Fix"

new Handle:g_cvarEnable;
new bool:g_bEnabled;
new Handle:g_cvarDebug;
new bool:g_bDebug;
new Handle:g_adtRespawnedWitches;
new bool:g_witchRespawnFlag;
new g_witchRespawnHP;
new Float:g_witchRespawnPos[3];

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "dcx2",
	description = "Fixes the Witch so she loses her target if she lights herself on fire",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
}

public OnPluginStart()
{
	g_cvarEnable = CreateConVar("sm_witchfirefix_enable", "1.0", "Enables this plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarDebug = CreateConVar("sm_witchfirefix_debug", "0.0", "Print debug output.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("sm_witchfirefix_version", PLUGIN_VERSION, "Witch Fire Fix", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d2_witchfirefix");

	HookConVarChange(g_cvarEnable, OnWFFEnableChanged);
	HookConVarChange(g_cvarDebug, OnWFFDebugChanged);
	
	g_bEnabled = GetConVarBool(g_cvarEnable);
	g_bDebug = GetConVarBool(g_cvarDebug);

	g_adtRespawnedWitches = CreateArray();
	g_witchRespawnFlag = false;

	HookEvent("round_start", Event_Round_Start);
	HookEvent("witch_spawn", Event_Witch_Spawn);
	HookEvent("witch_killed", Event_Witch_Killed);
	HookEvent("infected_hurt", Event_Infected_Hurt);
}

public OnWFFEnableChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bEnabled = StringToInt(newVal) == 1;
}

public OnWFFDebugChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bDebug = StringToInt(newVal) == 1;
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	// always do this, even if plugin disabled
	ClearArray(g_adtRespawnedWitches);
	g_witchRespawnFlag = false;
	
	return Plugin_Continue;
}

public Action:Event_Infected_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled || !(GetEventInt(event, "type") & 0x8))		return;	// if disabled or does not have fire flag, return

	new victim = GetEventInt(event, "entityid");
	decl String:victimName[20];
	GetEntityClassname(victim, victimName, sizeof(victimName));
	if (StrContains(victimName, "witch", false) < 0) 	return;			// if not a witch, return

	new witchIndex = FindValueInArray(g_adtRespawnedWitches, victim);	// Have we already respawned this entity?
	if (witchIndex >= 0)	return;
	
	new igniter = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (igniter > 0)
	{
		// if igniter is a player, pretend the witch has been respawned
		// This way we can't respawn a witch who was already lit by a player
		PushArrayCell(g_adtRespawnedWitches, victim);
		return;		
	}
	
	// By now, a witch has been ignited from something that's not a player and we have not respawned her yet
	// Grab her health and position, then kill her, set the respawn flag, and spawn a new witch
	g_witchRespawnHP = GetEntProp(victim, Prop_Data, "m_iHealth");
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", g_witchRespawnPos);
	AcceptEntityInput(victim, "kill");
	g_witchRespawnFlag = true;
	if (g_bDebug)		PrintToChatAll("Witch %d (hp: %d, pos: %f, %f, %f) ignited", victim, g_witchRespawnHP, g_witchRespawnPos[0], g_witchRespawnPos[1], g_witchRespawnPos[2]);
	SpawnCommand("z_spawn", "witch");					// Respawn her (continue in Event_Witch_Spawn)
}

public Action:Event_Witch_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled || !g_witchRespawnFlag)	return Plugin_Continue;

	// We are supposed to respawn a previous witch

	// Remember her so that we don't respawn her again
	new witchid = GetEventInt(event, "witchid");
	PushArrayCell(g_adtRespawnedWitches, witchid);

	// Then restore her previous HP and position
	SetEntProp(witchid, Prop_Data, "m_iHealth", g_witchRespawnHP);
	TeleportEntity(witchid, g_witchRespawnPos, NULL_VECTOR, NULL_VECTOR);
	if (g_bDebug)	PrintToChatAll("Witch %d (hp: %d, pos: %f, %f, %f) respawned", witchid, g_witchRespawnHP, g_witchRespawnPos[0], g_witchRespawnPos[1], g_witchRespawnPos[2]);

	// Finally, reset all the respawn fields
	g_witchRespawnFlag = false;
	g_witchRespawnHP = 1000;
	g_witchRespawnPos[0] = 0.0;
	g_witchRespawnPos[1] = 0.0;
	g_witchRespawnPos[2] = 0.0;

	return Plugin_Continue;
}

public Action:Event_Witch_Killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEnabled)
	{
		new witchid = GetEventInt(event, "witchid");
		
		// If a respawned witch dies, remove her from the array
		new witchIndex = FindValueInArray(g_adtRespawnedWitches, witchid);
		if (witchIndex >= 0)
		{
			RemoveFromArray(g_adtRespawnedWitches, witchIndex);
		}
		if (g_bDebug)	PrintToChatAll("Witch %d killed", witchid);
	}
}

// We need some in-game client to execute the command for us
stock SpawnCommand(String:command[], String:arguments[] = "")
{
	new client;
	for(client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))	break;
	}
	if (client<=MaxClients)
	{ 
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}
