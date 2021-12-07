/*
	DESCRIPTION
		Allows the dropped bomb to be kicked by CTs.
	
	CREDITS:
		Zephyrus (http://forums.alliedmods.net/member.php?u=79786) for his 
		* [ZR] Prop Push/Pull plugin (http://forums.alliedmods.net/showthread.php?p=1491667)
	
	CHANGE LOG
	* Version 1.0
		* Initial release
	
	* Version 1.1
		* Added CVar for kick bomb delay timer (requested by sinblaster (http://forums.alliedmods.net/member.php?u=70389))
		
	* Version 1.2
		* Now using SDKHooks for SDKHook_Touch
		* Changed sm_kickbomb_delay minimum and maximum times
			- from MIN of 1.0 to 0.1 and MAX of 25.0 to 10.0
		* Added some global defines
		
	* Version 1.2a
		* Removed unneeded proximity code since we're using SDKHooks_Touch
		
	* Version 1.2b
		* By request - added the ability to kick the bomb with the USE key
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2b"
#define TEAM_CT 3
#define MIN_DISTANCE 115
#define SCALE_AMOUNT 150.0
#define UP_VELOCITY 350.0

new String:classname[64];
new Float:vangles[3];
new Float:velocity[3];
new Float:playerpos[3];
new Float:entpos[3];

new bool:CanKick = true;
new bool:bomb_kickable = false;
new Float:DelayTime;

public Plugin:myinfo =
{
	name = "Kick Bomb",
	author = "TnTSCS aka ClarkKent",
	description = "Allows CTs to kick the dropped C4",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=166538"
}

public OnPluginStart()
{
	CreateConVar("sm_kickbomb_version", PLUGIN_VERSION, "Kick Bomb version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("sm_kickbomb_buildversion",SOURCEMOD_VERSION, "The version of SourceMod that 'Kick Bomb' was built on ", FCVAR_PLUGIN);
	
	new Handle:hRandom;// KyleS hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_kickbomb_delay", "1.5", "Number of seconds to wait before bomb can be kicked again", _, true, 0.1, true, 10.0)), OnDelayChanged);
	DelayTime = GetConVarFloat(hRandom);
	
	CloseHandle(hRandom); // KyleS hates handles.
	
	HookEvent("bomb_dropped", BombEvent);
	HookEvent("bomb_pickup", BombEvent);
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_Touch, OnTouch);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_Touch, OnTouch);
}

public OnDelayChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DelayTime = GetConVarFloat(cvar);
}

public BombEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(StrEqual(name, "bomb_dropped")) // Check if event was "bomb_dropped"
	{
		bomb_kickable = true;
	}
	else
	{
		bomb_kickable = false;
	}
}

public OnTouch(client, other) 
{
	if(bomb_kickable && CanKick && GetClientTeam(client) == TEAM_CT && other > MaxClients)
	{		
		GetEntityClassname(other, classname, sizeof(classname));
		
		if(StrEqual(classname, "weapon_c4") && CheckCommandAccess(client, "allow_kickbomb", ADMFLAG_RESERVATION))
		{
			GetClientEyeAngles(client, vangles);
			GetAngleVectors(vangles, velocity, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(velocity, velocity);
			ScaleVector(velocity, SCALE_AMOUNT);
			
			// Upward force so the bomb doesn't get buried in a hill
			velocity[2] = UP_VELOCITY;
			
			TeleportEntity(other, NULL_VECTOR, NULL_VECTOR, velocity);
			CanKick = false;
			
			// Need a timer so players can't easily put the bomb in an unreachable spot
			CreateTimer(DelayTime, ResetKickTimer);
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_USE)
	{
		new ent = GetClientAimTarget(client, false);
		
		if(!bomb_kickable || !CanKick || GetClientTeam(client) != TEAM_CT || ent <= MaxClients)
			return Plugin_Continue;

		//GetEdictClassname(ent, classname, sizeof(classname));
		GetEntityClassname(ent, classname, sizeof(classname));
		
		if(StrEqual(classname, "weapon_c4") && CheckCommandAccess(client, "allow_kickbomb", ADMFLAG_RESERVATION))
		{				
			GetClientAbsOrigin(client, playerpos);				
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entpos);
			
			// Need to ensure player is within reasonable distance, otherwise, they can move the bomb just by aiming at it
			if(GetVectorDistance(playerpos, entpos) > MIN_DISTANCE)
				return Plugin_Continue;
				
			GetClientEyeAngles(client, vangles);						
			GetAngleVectors(vangles, velocity, NULL_VECTOR, NULL_VECTOR);						
			NormalizeVector(velocity, velocity);						
			ScaleVector(velocity, SCALE_AMOUNT);
			
			// Upward force so the bomb doesn't get buried in a hill
			velocity[2] = UP_VELOCITY;
			
			TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, velocity);
			CanKick = false;
			
			// Need a timer so players can't easily put the bomb in an unreachable spot
			CreateTimer(DelayTime, ResetKickTimer);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}


public Action:ResetKickTimer(Handle:timer)
{
	CanKick = true;
}