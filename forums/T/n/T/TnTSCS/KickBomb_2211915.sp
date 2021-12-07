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
		
	* Version 1.3.1
		* Fixed CVar to allow Use and/or auto kick bomb. 
	
	* Version 1.3.2
		* Fixed error of use/touch not working
	
	* Version 1.3.3
		* Went back to hooking player instead of bomb for SDK Touch code.
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_VERSION "1.3.3"
#define MIN_DISTANCE 115
#define SCALE_AMOUNT 150.0
#define UP_VELOCITY 350.0

new String:classname[80];

new Float:vangles[3];
new Float:velocity[3];
new Float:playerpos[3];
new Float:entpos[3];

new bool:CanKick = true;
new bool:bomb_kickable;
new bool:ClientCanKick[MAXPLAYERS+1];
new Float:DelayTime;
new Method;

public Plugin:myinfo =
{
	name = "Kick Bomb",
	author = "TnTSCS aka ClarkKent",
	description = "Allows CTs to kick the dropped C4",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=166538"
}


/**
 * Called when the plugin is fully initialized and all known external references 
 * are resolved. This is only called once in the lifetime of the plugin, and is 
 * paired with OnPluginEnd().
 *
 * If any run-time error is thrown during this callback, the plugin will be marked 
 * as failed.
 *
 * It is not necessary to close any handles or remove hooks in this function.  
 * SourceMod guarantees that plugin shutdown automatically and correctly releases 
 * all resources.
 *
 * @noreturn
 */
public OnPluginStart()
{	
	new Handle:hRandom;// KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_kickbomb_version", PLUGIN_VERSION, 
	"Kick Bomb version.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_kickbomb_delay", "5.0", 
	"Number of seconds to wait before bomb can be kicked again", _, true, 0.1, true, 10.0)), OnDelayChanged);
	DelayTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kickbomb_method", "3",
	"Method of kickbomb to use (add up total options)\n1 = Kick with USE key\n2 = Kick by touching bomb", _, true, 1.0, true, 3.0)), OnMethodChanged);
	Method = GetConVarInt(hRandom);
	
	CloseHandle(hRandom); // KyleS hates handles.
	
	HookEvent("bomb_dropped", Event_BombEvent);
	HookEvent("bomb_pickup", Event_BombEvent);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPostAdminCheck(i);
			}
		}
	}
	
	return APLRes_Success;
}


/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_Touch, OnTouch);
	
	ClientCanKick[client] = CheckCommandAccess(client, "allow_kickbomb", ADMFLAG_RESERVATION);
}

/**
 * Called when a client is disconnecting from the server.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_Touch, OnTouch);
		ClientCanKick[client] = false;
	}
}

public Event_BombEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	bomb_kickable = StrEqual(name, "bomb_dropped");
}

/**
* SDKHooks Function SDKHook_StartTouch
*
* @param entity	Entity index of entity being touched
* @param other		Entity index of entity touching param entity
* @noreturn
*/
public OnTouch(client, other)
{
	if (bomb_kickable && CanKick && Method >= 2 &&
		GetClientTeam(client) == CS_TEAM_CT && other > MaxClients)
	{		
		GetEntityClassname(other, classname, sizeof(classname));
		
		if (StrEqual(classname, "weapon_c4") && ClientCanKick[client])
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
			CreateTimer(DelayTime, ResetKickTimer, other);
		}
	}
}

public Action:ResetKickTimer(Handle:timer, any:entity)
{
	CanKick = true;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_USE && Method != 2)
	{
		new ent = GetClientAimTarget(client, false);
		
		if (!ClientCanKick[client] || !bomb_kickable || !CanKick ||
			GetClientTeam(client) != CS_TEAM_CT || ent <= MaxClients)
		{
			return Plugin_Continue;
		}
		
		//GetEdictClassname(ent, classname, sizeof(classname));
		GetEntityClassname(ent, classname, sizeof(classname));
		
		if (StrEqual(classname, "weapon_c4") && ClientCanKick[client])
		{
			GetClientAbsOrigin(client, playerpos);				
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entpos);
			
			// Need to ensure player is within reasonable distance, otherwise, they can move the bomb just by aiming at it
			if (GetVectorDistance(playerpos, entpos) > MIN_DISTANCE)
			{
				return Plugin_Continue;
			}
				
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
		}
	}
	
	return Plugin_Continue;
}

public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnDelayChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DelayTime = GetConVarFloat(cvar);
}

public OnMethodChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Method = GetConVarInt(cvar);
}