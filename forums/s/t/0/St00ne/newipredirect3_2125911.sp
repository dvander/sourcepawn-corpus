#include <sourcemod> 

new Handle:g_hNewIP = INVALID_HANDLE;
new Handle:g_hTimer = INVALID_HANDLE;
new Handle:g_hShowTime = INVALID_HANDLE;
new Handle:g_hTimers[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:g_hpwd = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = "New IP Redirect",
    author = "Bubka3, St00ne",
    description = "Redirects client to your New IP with a message.",
    version = "1.1.3c",
    url = "http://www.bubka3.com/"
};

public OnPluginStart()
{
    HookEvent("player_spawn", EventSpawn);
    g_hNewIP = CreateConVar("sm_redirect_newip", "0.0.0.0", "Set to your new IP.", FCVAR_PLUGIN);
    g_hTimer = CreateConVar("sm_redirect_kicktimer", "120", "Seconds to kick after not leaving.", FCVAR_PLUGIN);
    g_hShowTime = CreateConVar("sm_redirect_showtimer", "120", "Seconds to show connection display box.", FCVAR_PLUGIN);
    g_hpwd = CreateConVar("sm_redirect_pwd", "", "Set the password for your new server.", FCVAR_PLUGIN);
}


public OnClientPostAdminCheck(client)
{
    if (IsClientInGame(client) && client != 0 && GetConVarInt(g_hTimer) > 0)
        g_hTimers[client] = CreateTimer(GetConVarFloat(g_hTimer), IdlerKick, client, TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientDisconnect(client)
{
	if(g_hTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimers[client]);
		g_hTimers[client] = INVALID_HANDLE;
	}
}

public EventSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client !=0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Float:fTime = GetConVarFloat(g_hShowTime); 
		new String:sIP[32]; 
		GetConVarString(g_hNewIP, sIP, sizeof(sIP));
		new String:fpwd[32]; 
		GetConVarString(g_hpwd, fpwd, sizeof(fpwd));
		DisplayAskConnectBox(client, fTime, sIP, fpwd);
		PrintToChat(client, "[SM] We have a new server at IP: %s", sIP);
		PrintToChat(client, "[SM] Press F3 (unless changed) to connect to the new server.");
		if (GetConVarInt(g_hTimer) > 0)
		{
			PrintToChat(client, "[SM] If you do not connect, you will be kicked from this server.");
		}
	}
}

public Action:IdlerKick(Handle:timer, any:client)
{
    decl String:sBuffer[32];
    GetConVarString(g_hNewIP, sBuffer, sizeof(sBuffer));

    if (IsClientInGame(client) && GetConVarInt(g_hTimer) > 0)
        KickClient(client, "We have moved to a new server!\nPlease update your favorites list:\nNew IP: %s", sBuffer);
}

//**END**//
