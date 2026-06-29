#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new bool:p_canHop[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_jump", EventPlayerJump);
}

public OnClientPutInServer(client){SDKHook(client, SDKHook_PreThink, OnPreThink);}

public OnPreThink(client)
{
	new iButtons = GetClientButtons(client);
	if ((iButtons & IN_JUMP) && !p_canHop[client])
	{
		/* this gets called but doesnt have any effect. you still jump.
		it appears the method is flawed. */
		iButtons &= ~IN_JUMP;
		SetEntProp(client, Prop_Data, "m_nButtons", iButtons);
	}
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

	/* this works fine. the second timer gets called when you land. however, even if i dont allow jumping
	for another 10 seconds, players can still jump :( */
	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		CreateTimer(0.5, allowHop, client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:allowHop(Handle:timer, any:client){p_canHop[client] = true;}