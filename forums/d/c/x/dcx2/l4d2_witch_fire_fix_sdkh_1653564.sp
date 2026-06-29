#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "L4D2 Witch Fire Fix"

new Handle:g_cvarEnable;
new bool:g_bEnabled;
new Handle:g_cvarDebug;
new bool:g_bDebug;
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

	g_witchRespawnFlag = false;

	HookEvent("witch_spawn", Event_Witch_Spawn);
}

public OnWFFEnableChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bEnabled = StringToInt(newVal) == 1;
}

public OnWFFDebugChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bDebug = StringToInt(newVal) == 1;
}
public Action:Event_Witch_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)	return Plugin_Continue;

	new witchid = GetEventInt(event, "witchid");

	if (g_witchRespawnFlag)
	{
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
	}
	else
	{
		// Listen for this witch to take fire damage
		SDKHook(witchid, SDKHook_OnTakeDamage, WitchOnTakeDamage);
		if (g_bDebug)		PrintToChatAll("Hooking witch %d", witchid);
	}
	return Plugin_Continue;
}

public Action:WitchOnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new bool:playerIgnited = (attacker > 0 && attacker < MaxClients);
	if (g_bDebug)
	{
		decl String:attackerName[MAX_NAME_LENGTH];
		
		if (playerIgnited)
		{
			GetClientName(attacker, attackerName, sizeof(attackerName));
		}
		else
		{
			GetEntityClassname(attacker, attackerName, sizeof(attackerName));
		}
	
		PrintToChatAll("Witch (%d) took %f damage (%x type) from %s (%d)", victim, damage, damagetype, attackerName, attacker);
	}
	
	if (damagetype & DMG_BURN)	
	{		
		// Once a witch has been hit with burning damage, unhook her, because she can only ignite once
		SDKUnhook(victim, SDKHook_OnTakeDamage, WitchOnTakeDamage);

		if (!playerIgnited)
		{
			// The witch should lose her target
			// So we will kill her and respawn a copy of her in the same place
			g_witchRespawnHP = GetEntProp(victim, Prop_Data, "m_iHealth");
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", g_witchRespawnPos);
			AcceptEntityInput(victim, "kill");
			g_witchRespawnFlag = true;
			if (g_bDebug)		PrintToChatAll("Witch (%d) (hp: %d, pos: %f, %f, %f) self-ignited", victim, g_witchRespawnHP, g_witchRespawnPos[0], g_witchRespawnPos[1], g_witchRespawnPos[2]);
			SpawnCommand("z_spawn", "witch");					// Respawn her (continue in Event_Witch_Spawn)		
		}
		else if (g_bDebug)
		{
			PrintToChatAll("Witch (%d) burned, unhooking", victim);
		}
	}
	return Plugin_Continue;
}

// We need some in-game client to execute the command for us
stock SpawnCommand(String:command[], String:arguments[] = "")
{
	new client;
	for(client=1; client<=MaxClients; client++) if(IsClientInGame(client)) break;
	
	if (client<=MaxClients)
	{ 
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}
