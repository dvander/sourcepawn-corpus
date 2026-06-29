#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "Dark Goku"

new Handle:hDamageSlowdown;
new Handle:hLandSlowdown;
new Handle:hAutoJump;

new bool:DamageSlowdownEnabled;
new bool:LandSlowdownEnabled;
new bool:AutoJumpEnabled;

public Plugin:myinfo =
{
	name = "Super HOP",
	author = PLUGIN_AUTHOR,
	description = "Allows Clients TO Jump Like Super Man",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("superhop_version", PLUGIN_VERSION, "EZ Hop version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	hLandSlowdown = CreateConVar("superhop_disablelandslowdown", "1", "enables/disables player slowdown caused by landing from a jump", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	hDamageSlowdown = CreateConVar("superhop_disabledamageslowdown", "1", "enables/disables player slowdown caused by damage", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	hAutoJump = CreateConVar("superhop_enableautojump", "1", "enables/disables auto jump by holding down the jump key", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("player_hurt", Event_PlayerHurt);
	
	HookConVarChange(hLandSlowdown, ConVarChange);
	HookConVarChange(hDamageSlowdown, ConVarChange);
	HookConVarChange(hAutoJump, ConVarChange);
	
	DamageSlowdownEnabled = GetConVarBool(hLandSlowdown);
	LandSlowdownEnabled = GetConVarBool(hDamageSlowdown);
	AutoJumpEnabled = GetConVarBool(hAutoJump);
}

public ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == hLandSlowdown) DamageSlowdownEnabled = GetConVarBool(hLandSlowdown);
	if (cvar == hDamageSlowdown) LandSlowdownEnabled = GetConVarBool(hDamageSlowdown);
	if (cvar == hAutoJump) AutoJumpEnabled = GetConVarBool(hAutoJump);
}

// "m_flStamina" was added to an earlier version of cs to try and stop bunny hopping.
public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (LandSlowdownEnabled)
	{
		new UserId = GetEventInt(event, "userid");
		new UserIndex = GetClientOfUserId(UserId);
		SetEntPropFloat(UserIndex, Prop_Send, "m_flStamina", 0.0);
	}
	return Plugin_Continue;
}

// "m_flVelocityModifier" is a multiplier applied to the players speed to slow them down when they take damage.
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (DamageSlowdownEnabled)
	{
		new UserId = GetEventInt(event, "userid");
		new UserIndex = GetClientOfUserId(UserId);
		SetEntPropFloat(UserIndex, Prop_Send, "m_flVelocityModifier", 1.0);
	}
	return Plugin_Continue;
}

// negate the key press as long as the player is in the air so they jump the exact game frame they land.
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (AutoJumpEnabled && IsPlayerAlive(client))
	{
		if (buttons & IN_JUMP)
		{
			if (!(GetEntityFlags(client) & FL_ONGROUND))
			{
				buttons &= ~IN_JUMP;
			}
		}
	}
	return Plugin_Continue;
}