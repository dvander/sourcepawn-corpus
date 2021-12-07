#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION 		"1.2.0.0"

public Plugin:myinfo = 
{
	name = "Server Redirector",
	author = "Wazz",
	description = "Uses server slots to redirect players to another server",
	version = PLUGIN_VERSION,
};

new Handle:Visiblemaxplayers;

new Handle:sm_redirect_slots;
new Handle:sm_redirect_server;
new Handle:sm_redirect_announce;
new Handle:sm_redirect_time;

new String:message[120] = "\x04This server is full. Please press F3 to be redirected to our second server or you will be kicked.\x01";

public OnPluginStart()
{
	Visiblemaxplayers = FindConVar("sv_visiblemaxplayers");
		
	sm_redirect_announce = CreateConVar("sm_redirect_announce", "1", "Announces when the server redirects a player", 0, true, 0.0);
	sm_redirect_server = CreateConVar("sm_redirect_server", "127.0.0.1:27050", "IP of the server to redirect to.", 0, true, 0.0);
	sm_redirect_slots = CreateConVar("sm_redirect_slots", "2", "Number of slots to use for redirecting players.", 0, true, 0.0);
	sm_redirect_time = CreateConVar("sm_redirect_time", "35", "Time until a player in a redirect slot is kicked.", 0, true, 0.0);
	
	CreateConVar("sm_redirect_version", PLUGIN_VERSION, "Server Redirector version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new limit = getLimit();
		
	if (client > limit)
	{
		ChangeClientTeam(client, 1);
	}
}

public OnClientPostAdminCheck(client)
{
	new String:serverIP[128];
	GetConVarString(sm_redirect_server, serverIP, sizeof(serverIP));
	new limit = getLimit();

	if ((client > limit) && (StrContains(serverIP, "127.0.0.1") == -1))
	{
		CreateTimer(2.0, VGUITimer, client, TIMER_REPEAT);
		
		PrintToChat(client, message);
		PrintCenterText(client, message);
		ChangeClientTeam(client, 1);
		
		new String:time[64];
		GetConVarString(sm_redirect_time, time, 64);
		new Handle:kv = CreateKeyValues("msg");
		KvSetString(kv, "time", time); 
		KvSetString(kv, "title", serverIP); 

		CreateDialog(client, kv, DialogType_AskConnect);
		CreateTimer(5.0, MessageTimer, client, TIMER_REPEAT);
		CreateTimer(GetConVarFloat(sm_redirect_time), KickTimer, client);
	}
}

public Action:VGUITimer(Handle:timer, any:client)
{
	static c = 0;
	
	if (!client || !IsClientInGame(client))
	{
		c = 0;
		return Plugin_Stop;
	}

	ShowVGUIPanel(client, "info", _, false);
	ShowVGUIPanel(client, "team", _, false);
	ShowVGUIPanel(client, "active", _, false);
	c++;
	
	if (c == (GetConVarInt(sm_redirect_time) / 2))
	{
		c = 0;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}


public Action:MessageTimer(Handle:timer, any:client)
{
	static i = 0;
	
	if (!client || !IsClientInGame(client))
	{
		i = 0;
		return Plugin_Stop;
	}
	
	PrintToChat(client, message);
	PrintCenterText(client, message);
	i++;
	
	if (i == 6)
	{
		i = 0;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:KickTimer(Handle:timer, any:client)
{	
	decl String:serverIP[128];
	GetConVarString(sm_redirect_server, serverIP, sizeof(serverIP));
	new limit = getLimit();
	
	if (!client || !IsClientInGame(client))
	{
		LogMessage( "Client was redirected to %s.", serverIP );
		if (GetConVarBool(sm_redirect_announce))
		{
			PrintToChatAll("x01Player was redirected to \x04%s\x01.", client, serverIP);	
		}
		return Plugin_Handled;
	}
			
	if (client > limit)
	{         
		LogMessage( "\"%L\" was offered redirect and did not accept.", client, serverIP );
		if (GetConVarBool(sm_redirect_announce))
		{
			PrintToChatAll("\x04%N \x01did not accept redirect. Please accept to allow for expansion.", client);
		}
	}
	return Plugin_Handled;
}

getLimit()
{
	new visibleSlots;
	if (Visiblemaxplayers==INVALID_HANDLE || GetConVarInt(Visiblemaxplayers)==-1) 	
	{
		visibleSlots = GetMaxClients();
	}
	else
	{
		visibleSlots = GetConVarInt(Visiblemaxplayers);
	}
	
	new redirectSlots = GetConVarInt(sm_redirect_slots);
	new limit = visibleSlots - redirectSlots;
	
	return limit;
}