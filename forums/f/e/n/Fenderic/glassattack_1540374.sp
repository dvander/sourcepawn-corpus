#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.5"
public Plugin:myinfo = 
{
	name = "Glass Attack",
	author = "Fenderic",
	description = "Sniper-only deathmatch with tons of breakable glass!",
	version = PLUGIN_VERSION,
	url = "http://www.moddb.com/mods/glass-attack"
};
//CVars
new Handle:g_Cvar_GlassEnabled;

public OnPluginStart()
{
	CreateConVar("sm_glass_version", PLUGIN_VERSION, "Glass Attack version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_GlassEnabled = CreateConVar("sm_glass_enabled", "0", "Enables the Glass Attack plugin", 0, false, 0.0, false, 0.0);
	if(GetConVarBool(g_Cvar_GlassEnabled))
	{
		HookEvent("player_changeclass", Event_PlayerClass);
		HookEvent("player_spawn", Event_PlayerSpawn);
	}
}

public Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_Cvar_GlassEnabled))
	{
		return;
	}
	new glass_user = GetClientOfUserId(GetEventInt(event, "userid"));
	new glass_user_class  = GetEventInt(event, "class");
	if(glass_user_class != 2)
	{
		TF2_SetPlayerClass(glass_user, TFClassType:2);
	}
	
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_Cvar_GlassEnabled))
	{
		return;
	}
	new glass_user = GetClientOfUserId(GetEventInt(event, "userid"));
	if(TF2_GetPlayerClass(glass_user) != TFClassType:2)
	{
		TF2_SetPlayerClass(glass_user, TFClassType:2);
		if(IsPlayerAlive(glass_user))
		{
			TF2_RespawnPlayer(glass_user);
		}
	}
	
}