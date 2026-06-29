#include <sourcemod>
#include <cstrike>
#include <multicolors>
#include <clientprefs>

#pragma newdecls required

static const char g_szTag[] = "[{Lime}CHATSPY{default}]";

Handle g_clientcookie;
bool g_bEnabled[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[CS:GO] ChatSpy",
	author = "ESK0",
	version = "1337",
	url = "www.steamcommunity.com/id/esk0"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_chatspy", Command_ChatSpy, ADMFLAG_GENERIC);
	g_clientcookie = RegClientCookie("chatspy_cookie", "", CookieAccess_Private);
}

public void OnClientCookiesCached(int client)
{
	char szValue[4];
	GetClientCookie(client, g_clientcookie, szValue, sizeof(szValue));
	g_bEnabled[client] = szValue[0] ? view_as<bool>(StringToInt(szValue)):true;
}

public Action Command_ChatSpy(int client, int args)
{
	g_bEnabled[client] = !g_bEnabled[client];
	if(g_bEnabled[client])
	{
		SetClientCookie(client, g_clientcookie, "0");
		CPrintToChat(client,"%s ChatSpy {lightred}disabled", g_szTag);
	}
	else
	{
		SetClientCookie(client, g_clientcookie, "1");
		CPrintToChat(client,"%s ChatSpy {lime}enabled", g_szTag);
	}
	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(0 < client && client <= MaxClients && IsClientInGame(client) && StrEqual(command, "say_team") && sArgs[0] != 0 && sArgs[0] != '@' && sArgs[0] != '/' && sArgs[0] != '!')
	{
		int iSenderTeam = GetClientTeam(client);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(g_bEnabled[i] && IsClientInGame(i) && !IsFakeClient(i) && iSenderTeam != GetClientTeam(i) && CheckCommandAccess(i, "", ADMFLAG_GENERIC, true))
			{
				CPrintToChat(i, "%s%s%s %N : %s",
				(iSenderTeam == CS_TEAM_CT) ? "{blue}" : (iSenderTeam == CS_TEAM_T) ? "{orange}" : "{gray}",
				IsPlayerAlive(client) ? "" : (iSenderTeam == CS_TEAM_T) ? "*DEAD*" : (iSenderTeam == CS_TEAM_CT) ? "*DEAD*" : "",
				(iSenderTeam == CS_TEAM_CT) ? "(Counter-Terrorist)" : (iSenderTeam == CS_TEAM_T) ? "(Terrorist)" : "", client, sArgs);
			}
		}
	}
	return Plugin_Continue;
}
