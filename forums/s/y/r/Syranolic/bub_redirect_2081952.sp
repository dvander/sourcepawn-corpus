#include <sourcemod> 

new Handle:NewIP = INVALID_HANDLE;
new Handle:Timer = INVALID_HANDLE;
new Handle:STime = INVALID_HANDLE;
new Handle:MaxFree = INVALID_HANDLE;
new Handle:g_hTimers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };  

public Plugin:myinfo =
{
    name = "New IP Redirect",
    author = "Bubka3",
    description = "Redirects client to your New IP with a message.",
    version = "1.0.2",
    url = "http://www.bubka3.com/"
};

static DoRedirect(client)
{
	new max = GetConVarInt(MaxFree);
	if (max !=0 && MaxClients-getPlayerCount() > max)
		return;
	new String:ip[32]; 
	GetConVarString(NewIP, ip, sizeof(ip));
	new Float:stime = GetConVarFloat(STime); 
	DisplayAskConnectBox(client, stime, ip);
	PrintToChat(client, "[SM] We have a new server at IP: %s", ip);
	if (max != 0)
		PrintToChat(client, "[SM] This one is almost full.");
	PrintToChat(client, "[SM] Press F3 to connect to the new server.");
	new Float:timer = GetConVarFloat(Timer); 
	if (timer > 0.0)
	{
		PrintToChat(client, "[SM] If you do not connect, you will be kicked from this server.");
		if (g_hTimers[client] == INVALID_HANDLE)
			g_hTimers[client] = CreateTimer(timer, IdlerKick, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

static getPlayerCount()
{
	new c = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
			c++;
	}
	return c;
}

public OnPluginStart()
{
	NewIP = CreateConVar("re_newip", "0.0.0.0", "Set to your new IP.", FCVAR_PLUGIN);
	Timer = CreateConVar("re_time", "120", "Seconds to kick after not leaving.", FCVAR_PLUGIN);
	STime = CreateConVar("re_stime", "120", "Seconds to show connection display box.", FCVAR_PLUGIN);
	MaxFree = CreateConVar("re_maxfree", "0", "Max number of free slots left before redirect is shown.", FCVAR_PLUGIN);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("player_changeclass", Event_PlayerClass, EventHookMode_Post);
}

public OnClientDisconnect(client)
{
	if (g_hTimers[client] == INVALID_HANDLE)
		return;
	KillTimer(g_hTimers[client]);
	g_hTimers[client] = INVALID_HANDLE;
}

public OnClientPutInServer(client)
{
	if (client<1 || client>MaxClients || IsFakeClient(client))
		return;
	g_hTimers[client] = INVALID_HANDLE;
	new String:ip[32]; 
	GetConVarString(NewIP, ip, sizeof(ip));
	PrintToChat(client, "[SM] We have a new server at IP: %s", ip);
}

public Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client<1 || client>MaxClients)
		return;
	if (!IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client))
		return;

	DoRedirect(client);
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	if (team != 1)
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client<1 || client>MaxClients)
		return;
	if (!IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client))
		return;
	if (bool:GetEventBool(event, "disconnect"))
		return;

	DoRedirect(client);
}

public Action:IdlerKick(Handle:timer, any:client)
{
	if (client<1 || client>MaxClients)
		return;
	if (!IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client))
		return;

	decl String:buffer[32];
	GetConVarString(NewIP, buffer, sizeof(buffer));
	KickClient(client, "Get out! Moved to \"%s\"", buffer);
}