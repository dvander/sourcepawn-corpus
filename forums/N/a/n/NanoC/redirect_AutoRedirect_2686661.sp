#include <sourcemod>
#include <redirect_core>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name		= 		"[Redirect Module] Auto Redirect",
	author		= 		"Rostu, Nano",
	version		= 		"1.0",
	url			= 		"https://vk.com/id226205458 | Discord: Rostu#7917"
};

int g_iIP;
int g_iPort;

ConVar g_hRedirect;

public void OnPluginStart()
{
	(g_hRedirect = CreateConVar("sm_redirect_server", "192.168.0.1:27015", "Which server to automatically redirect players?")).AddChangeHook(Change_);

	AutoExecConfig(true, "AutoRedirect");
	
	HookEvent("player_connect_full", OnClientFullConnect);
}

public void Change_ (ConVar convar, const char[] oldValue, const char[] newValue)
{
	ParseRedirectIP();
}

public void OnConfigsExecuted()
{
	ParseRedirectIP();
}

int IPToNum(const char[] sIP)
{
	char sResult[4][4];
	return (ExplodeString(sIP, ".", sResult, 4, 4) == 4) ? GetIP32FromIPv4(sResult) : 0;
}

void ParseRedirectIP()
{
	char sFullIP[24];
	g_hRedirect.GetString(sFullIP, sizeof sFullIP);

	for(int x = strlen(sFullIP) - 1; x >= 0; x--)
	{
		if(sFullIP[x] == ':')
		{
			g_iPort = StringToInt(sFullIP[x + 1]);
			sFullIP[x] = '\0';

			break;
		}
	}

	g_iIP = IPToNum(sFullIP);
}

public void OnClientFullConnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || IsFakeClient(client))
	{
		return;
	}
	
	CreateTimer(10.0, Timer_MSG, GetClientUserId(client));
	CreateTimer(15.0, Timer_Reconnect, GetClientUserId(client));
}

public Action Timer_MSG(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	
	CPrintToChat(client, "{green}[AutoRedirect]{default} You'll be {green}auto-redirected{default} in {darkred}5 seconds!");
	PrintCenterText(client, "You'll be auto-redirected in 5 seconds!");

	return Plugin_Stop;
}

public Action Timer_Reconnect(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Stop;
	}

	RedirectClientOnServer(client, g_iIP, g_iPort);

	return Plugin_Stop;
}

