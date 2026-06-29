#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>

new Handle:CheckTimer[MAXPLAYERS+1] = {	INVALID_HANDLE, ...};

public OnPluginStart()
{
	RegConsoleCmd("sm_colors",color_on);
	RegConsoleCmd("sm_colors_off",color_off);
	HookEvent("player_spawn", EventAdminSpawn, EventHookMode_Post);
	HookEvent("player_death", player_death, EventHookMode_Post);
	HookEvent("player_team", player_team, EventHookMode_Post);
	HookEvent("round_end", RoundEnd);
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	stop_timer();
	return Plugin_Continue;
}

stop_timer()
{	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (CheckTimer[i] != INVALID_HANDLE)
		{
			KillTimer(CheckTimer[i]);
			CheckTimer[i] = INVALID_HANDLE;		
		}
	}
}

public Action:color_on(Client, args)
{
	PerformGlow(Client, 3, 2048, 255, 51, 153);
	SetEntityRenderColor(Client, 200, 20, 15, 255);
	CPrintToChat(Client, "{red}開啟光圈效果,換色功能重生後生效");
}

public Action:color_off(Client, args)
{
	if (CheckTimer[Client] != INVALID_HANDLE)
	{
		KillTimer(CheckTimer[Client]);
		CheckTimer[Client] = INVALID_HANDLE;
	}
	PerformGlow(Client, 0, 2048, 0, 0, 0);
	SetEntityRenderColor(Client, 255, 255, 255, 255);
	CPrintToChat(Client, "{red}關閉光圈效果");
}

public OnClientDisconnect(client)
{	
	if (CheckTimer[client] != INVALID_HANDLE)
	{
		KillTimer(CheckTimer[client]);
		CheckTimer[client] = INVALID_HANDLE;
	}
}

public player_death(Event event, const char[] name, bool dontBroadcast)
{
	int Client2 = event.GetInt("userid");
	int Client = GetClientOfUserId(Client2);
	
	if (Client > 0 && GetClientTeam(Client)==2)
	{
		PerformGlow(Client, 0, 2048, 0, 0, 0);
		
		if (CheckTimer[Client] != INVALID_HANDLE)
		{
			KillTimer(CheckTimer[Client]);
			CheckTimer[Client] = INVALID_HANDLE;
		}
	}
}

public player_team(Event event, const char[] name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(event.GetInt("userid"));

	PerformGlow(Client, 0, 2048, 0, 0, 0);
		
	if (CheckTimer[Client] != INVALID_HANDLE)
	{
		PerformGlow(Client, 0, 2048, 0, 0, 0);

		KillTimer(CheckTimer[Client]);
		CheckTimer[Client] = INVALID_HANDLE;
	}
}

public EventAdminSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientInGame(client) && GetClientTeam(client)==2 && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		if(client)
		{
			PerformGlow(client, 3, 2048, 255, 51, 153);
			SetEntityRenderColor(client, 255, 51, 153, 255);
			CheckTimer[client] = CreateTimer(3.0, CheckItem1, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:CheckItem(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	
	if(client <= 0 || !IsClientConnected(client))
	{
		return Plugin_Handled;
	}
	else if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 && !IsFakeClient(client))
	{
		PerformGlow(client, 3, 2048, 0, 255, 255);	
	}
	CheckTimer[client] = INVALID_HANDLE;
	return Plugin_Handled;
}

public Action:CheckItem1(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);

	new r=GetRandomInt(0,255);
	new g=GetRandomInt(0,255);
	new b=GetRandomInt(0,255);

	if(client <= 0 || !IsClientConnected(client))
	{	
		return Plugin_Handled;
	}
	else if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 && !IsFakeClient(client))
	{
		PerformGlow(client, 3, 2048, r, g, b);
		SetEntityRenderColor(client, r, g, b, 255);
	}
	else
	{
		PerformGlow(client, 0, 2048, 0, 0, 0);
	
		if (CheckTimer[client] != INVALID_HANDLE)
		{
			KillTimer(CheckTimer[client]);
			CheckTimer[client] = INVALID_HANDLE;
		}
	}
	return Plugin_Handled;
}

/* 實體輪廓設置 */
stock PerformGlow(client, Type, Range = 0, Red = 0, Green = 0, Blue = 0)
{
	decl Color;
	Color = Red + Green * 256 + Blue * 65536;
	SetEntProp(client, Prop_Send, "m_iGlowType", Type);
	SetEntProp(client, Prop_Send, "m_nGlowRange", Range);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", Color);
}