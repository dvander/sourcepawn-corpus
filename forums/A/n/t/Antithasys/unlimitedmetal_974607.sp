#include <sourcemod>
#include <tf2_stocks>

new Handle:g_hPlayerTimers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public Plugin:myinfo =
{
	name = "[TF2] Unlimited Metal",
	author = "John B.",
	description = "Checks engineer's metal amount in every 5 seconds and sets his metal amount to 200 if it's not 200",
	version = "1.0.0",
	url = "http://www.sourcemod.net/",
}

public OnPluginStart ()
{
	HookEvent("player_changeclass", EventPlayerChangeClass);
}

public OnClientDisconnect(client)
{
	if(g_hPlayerTimers[client] != INVALID_HANDLE)
	{
		StopTimer(g_hPlayerTimers[client]);		
	}
}

public Action:EventPlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if(class == TFClass_Engineer)
	{
		if(g_hPlayerTimers[client] == INVALID_HANDLE)
		{
			g_hPlayerTimers[client] = CreateTimer(5.0, MetalCheck, client, TIMER_REPEAT);
			PrintToChat(client, "\x04[Unlimited Metal]: \x03Enabled");
			LogMessage("Timer created");
		}
	}
	else if(class != TFClass_Engineer && g_hPlayerTimers[client] != INVALID_HANDLE)
	{
		StopTimer(g_hPlayerTimers[client]);
	}
	return Plugin_Continue;
}

public Action:MetalCheck(Handle:timer, any:client)
{
	new metalAmount = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 4);

	if(metalAmount != 200)
	{
		SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 200, 4, true);
	}
	return Plugin_Continue;
}

stock StopTimer(Handle:timer)
{
	CloseHandle(timer);
	timer = INVALID_HANDLE;
	LogMessage("Timer killed");
}
