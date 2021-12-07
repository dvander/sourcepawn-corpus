#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo = 
{
	name = "Bullet Penetration Filter",
	author = "Sheepdude",
	description = "Stops bullets from penetrating specific entities",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

new Handle:h_cvarPenetrationPlayers;
new Handle:h_cvarPenetrationGeometry;

new g_cvarPlayers;
new g_cvarGeometry;

new bool:g_TRIgnore[MAXPLAYERS + 1]; // Tells traceray to ignore collisions with certain players
new g_Ignore[MAXPLAYERS + 1]; // Tell plugin to ignore penetrative bullets for a certain player

public OnPluginStart()
{
	CreateConVar("sm_penetration_version", PLUGIN_VERSION, "Bullet Penetration Filter version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY);
	h_cvarPenetrationPlayers = CreateConVar("sm_penetration_players", "1", "Determines which players bullets can penetrate (0 - no players, 1 - enemies only, 2 - teammates only, 3 - any players)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	h_cvarPenetrationGeometry = CreateConVar("sm_penetration_geometry", "1", "Determines whether bullets can penetrate geometry and props (0 - no penetration, 1 - regular penetration)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	HookConVarChange(h_cvarPenetrationPlayers, ConvarChanged);
	HookConVarChange(h_cvarPenetrationGeometry, ConvarChanged);
	UpdateAllConvars();
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	return APLRes_Success;
}

/********
 *Events*
*********/

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if( (g_cvarPlayers == 3 &&
		g_cvarGeometry == 1) || // Plugin is allowing all penetration
		damagetype & DMG_BULLET == 0 || // Damage was not from a bullet
		attacker < 1 ||
		attacker > MaxClients || // Attacker is not a player
		victim < 0 ||
		victim > MaxClients || // Victim is not a player
		!IsClientInGame(attacker) ||
		!IsClientInGame(victim) )
		return Plugin_Continue; // Allow damage to go through
	
	// Init variables
	decl Float:attackerloc[3], Float:bulletvec[3], Float:bulletang[3];
	GetClientEyePosition(attacker, attackerloc);
	MakeVectorFromPoints(attackerloc, damagePosition, bulletvec);
	GetVectorAngles(bulletvec, bulletang);
	
	// Traceray to victim
	g_TRIgnore[attacker] = true; // Tell traceray to ignore collisions with the attacker
	if(g_cvarGeometry)
		TR_TraceRayFilter(attackerloc, bulletang, MASK_ALL, RayType_Infinite, TraceRayHitPlayer); // Try to hit a player
	else
		TR_TraceRayFilter(attackerloc, bulletang, MASK_ALL, RayType_Infinite, TraceRayHitAnything); // Try to hit an entity
	new obstruction = TR_GetEntityIndex(); // Find first entity in traceray path
	g_TRIgnore[attacker] = false;
	
	// If traceray hit an entity beside the victim, then that entity is an obstruction
	if(obstruction != victim)
	{
		g_Ignore[victim] = 0; // Reset case of disappearing obstruction due to player death
		
		// Obstruction is a player
		if( obstruction > 0 &&
			obstruction <= MaxClients &&
			IsClientInGame(obstruction) )
		{
			if(g_cvarPlayers == 0) // Bullets cannot penetrate players
			{
				damage = 0.0;
				return Plugin_Changed;
			}
			else if(g_cvarPlayers == 1 && GetClientTeam(obstruction) == GetClientTeam(attacker)) // Bullets can only penetrate enemy players
			{
				damage = 0.0;
				return Plugin_Changed;
			}
			else if(g_cvarPlayers == 2 && GetClientTeam(obstruction) != GetClientTeam(attacker)) // Bullets can only penetrate teammates
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		
		// Obstruction is not a player
		else
		{
			damage = 0.0; // Since we can only trace to a non-player entity if geometry penetration is disabled, stop the damage
			return Plugin_Changed;
		}
	}
	
	// There is no obstruction
	else
	{
		// Check if there was an obstruction, but the obstructing player died; these bullets are still penetrative and must be blocked
		if(g_Ignore[victim] > 0) 
		{
			damage = 0.0;
			g_Ignore[victim]--;
			return Plugin_Changed;
		}
		
		// Traceray beyond the victim
		g_TRIgnore[attacker] = true;
		g_TRIgnore[victim] = true;
		if(g_cvarGeometry)
			TR_TraceRayFilter(attackerloc, bulletang, MASK_ALL, RayType_Infinite, TraceRayHitPlayer); // Try to hit a player
		else
			TR_TraceRayFilter(attackerloc, bulletang, MASK_ALL, RayType_Infinite, TraceRayHitAnything); // Try to hit an entity
		g_TRIgnore[attacker] = false;
		g_TRIgnore[victim] = false;
		new beyond = TR_GetEntityIndex();
		
		// Entity beyond the victim is a player
		if( beyond > 0 &&
			beyond <= MaxClients &&
			IsClientInGame(beyond) )
		{
			if( g_cvarPlayers == 0 || //  Bullets cannot penetrate any players
				(g_cvarPlayers == 1 &&
				GetClientTeam(victim) == GetClientTeam(attacker)) || // Bullets can only penetrate enemies
				(g_cvarPlayers == 2 &&
				GetClientTeam(victim) != GetClientTeam(attacker))) // Bullets can only penetrate teammates
				g_Ignore[beyond]++; // Increase the count of penetrative bullets that must be blocked for the player beyond the victim, in case victim dies
		}
	}
	return Plugin_Continue;
}

/***************
 *Trace Filters*
****************/

public bool:TraceRayHitPlayer(entity, mask)
{
	// Check if the ray hits an entity, and stop if it does
	if(entity > 0 && entity <= MaxClients && !g_TRIgnore[entity])
		return true;
	return false;
}

public bool:TraceRayHitAnything(entity, mask)
{
	// Check if the ray hits an entity, and stop if it does
	if(entity > MaxClients || entity <= MaxClients && !g_TRIgnore[entity])
		return true;
	return false;
}

/*********
 *Convars*
**********/

UpdateAllConvars()
{
	g_cvarPlayers = GetConVarInt(h_cvarPenetrationPlayers);
	g_cvarGeometry = GetConVarInt(h_cvarPenetrationGeometry);
	for(new i = 0; i < MAXPLAYERS; i++)
	{
		g_TRIgnore[i] = false;
		g_Ignore[i] = 0;
	}
}

public ConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == h_cvarPenetrationPlayers)
		g_cvarPlayers = GetConVarInt(h_cvarPenetrationPlayers);
	else if(cvar == h_cvarPenetrationGeometry)
		g_cvarGeometry = GetConVarInt(h_cvarPenetrationGeometry);
}