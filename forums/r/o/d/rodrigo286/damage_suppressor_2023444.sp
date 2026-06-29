/*
Description:

Allow players to block 100% self damage

CVARs:

sm_damage_suppressor_enabled = 1/0 - Plugin is enabled/disabled.
sm_damage_suppressor_version - Current plugin version

Changelog:

* Version 1.0.0 *
Initial Release

*/

#include <sourcemod>
#include <sdkhooks>

/* 
	Current plugin version
*/
#define PLUGIN_VERSION "Build 1.0.0"

/*
	BOOL
*/
new bool:NoSelfDamage[MAXPLAYERS+1] = true;

/* 
	HANDLES
*/
new Handle:gDamageSuppressorEnabled = INVALID_HANDLE;

/* 
	VARIABLE
*/
new DamageSuppressorEnabled;

/* 
	Plugin information
*/
public Plugin:myinfo =
{
	name = "Damage Suppressor",
	author = "Rodrigo286",
	description = "Allow players to block 100% self damage",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=224819",
}

public OnPluginStart()
{
/*
	Cvars
*/
	CreateConVar("sm_damage_suppressor_version", PLUGIN_VERSION, "\"Damage Suppressor\" version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY);
	gDamageSuppressorEnabled = CreateConVar("sm_damage_suppressor_enabled", "1", "Damage Suppressor plugin is enabled?");
	AutoExecConfig(true, "damage_suppressor");

	HookConVarChange(gDamageSuppressorEnabled, ConVarChange);	
	DamageSuppressorEnabled = GetConVarBool(gDamageSuppressorEnabled);

	RegConsoleCmd("sm_nodamage", suppressorCDM);
}

public Action:suppressorCDM(client, args)
{
	if(DamageSuppressorEnabled != 0)
	{
		if(NoSelfDamage[client] == true)
		{
			NoSelfDamage[client] = false;

			PrintToChat(client, "\x03[\x04SM\x03]\x01 Now you do not get more damage from their own weapons!");
		}
		else
		{
			NoSelfDamage[client] = true;

			PrintToChat(client, "\x03[\x04SM\x03]\x01 Now you receive damage their own weapons!");
		}
	}
	else
	{
		PrintToChat(client, "\x03[\x04SM\x03]\x01 !nodamage is currently disabled!");
	}
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	DamageSuppressorEnabled = GetConVarBool(gDamageSuppressorEnabled);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); // Detect damage using SDKHooks and lock him to 0.0
	NoSelfDamage[client] = true;
}

public OnClientDisconnect(client)
{
	NoSelfDamage[client] = false;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(DamageSuppressorEnabled != 1 || !IsValidClient(attacker) || NoSelfDamage[attacker] != false)
		return Plugin_Continue;

	if(attacker == victim) // Detect if attacker and victim is same people
	{
		damage = 0.0; // Lock damage to 0.0
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public IsValidClient(client) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}