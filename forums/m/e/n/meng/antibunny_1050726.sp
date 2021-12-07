#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.7"

public Plugin:myinfo =
{
	name = "antibunny",
	author = "meng, Greyscale",
	description = "prevents the bhop",
	version = "PLUGIN_VERSION",
	url = ""
}

new Handle:g_cvarDelay;
new bool:p_canHop[MAXPLAYERS+1];

public OnPluginStart()
{
	CreateConVar("sm_antibunny_version", PLUGIN_VERSION, "antibunny Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvarDelay = CreateConVar("sm_antibunny_hopdelay", "0.3");

	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_jump", EventPlayerJump);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((buttons & IN_JUMP) && !p_canHop[client])
	{
		buttons &= ~IN_JUMP;
		SetEntProp(client, Prop_Data, "m_nButtons", buttons);
	}
	return Plugin_Continue;
}

public EventPlayerSpawn(Handle:event, const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	p_canHop[client] = true;
}

public EventPlayerJump(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (p_canHop[client])
	{
		p_canHop[client] = false;
		CreateTimer(0.1, OnGroundCheck, client, TIMER_REPEAT);
	}
}

public Action:OnGroundCheck(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		CreateTimer(GetConVarFloat(g_cvarDelay), allowHop, client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:allowHop(Handle:timer, any:client){p_canHop[client] = true;}