#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_VERSION "1.0.0.0"
public Plugin:myinfo =
{
	name 		= "No Tag Flood",
	author 		= "AlexTheRegent",
	description = "",
	version 	= PLUGIN_VERSION,
	url 		= ""
}

#pragma newdecls required
char	g_szOldTag[MAXPLAYERS+1][12];
int 	g_iWarnings[MAXPLAYERS+1] = 0;
int 	g_iMaxWarnings;
int 	g_iBanLength;

public void OnPluginStart() 
{
	CreateConVar("sm_notagflood_maxwarns", 	"3", 	"сколько раз игрок может сменить тэг за одно подключение", 					FCVAR_PLUGIN, true, 1.0);
	CreateConVar("sm_notagflood_banlen", 	"10", 	"время бана в минутах (0 - только кик, -1 (минус один) - бан навсегда)", 	FCVAR_PLUGIN);
}

public void OnConfigsExecuted() 
{
	g_iMaxWarnings 	= FindConVar("sm_notagflood_maxwarns").IntValue;
	g_iBanLength 	= FindConVar("sm_notagflood_banlen").IntValue;
}

public void OnClientPutInServer(int iClient)
{
	CS_GetClientClanTag(iClient, g_szOldTag[iClient], sizeof(g_szOldTag[]));
	g_iWarnings[iClient] = 0;
}

public void OnClientSettingsChanged(int iClient)
{
	if ( 0 < iClient && iClient <= MaxClients && IsClientInGame(iClient) ) {
		char szCurrentTag[12];
		CS_GetClientClanTag(iClient, szCurrentTag, sizeof(szCurrentTag));
		if ( strcmp(szCurrentTag, g_szOldTag[iClient], true) ) {
			if ( ++g_iWarnings[iClient] >= g_iMaxWarnings ) {
				if ( g_iBanLength > 0 ) {
					ServerCommand("sm_ban #%d %d \"Частая смена тэга (бан на %d минут)\"", GetClientUserId(iClient), g_iBanLength, g_iBanLength);
					ServerCommand("sm_kick #%d \"Частая смена тэга (бан на %d минут)\"", GetClientUserId(iClient), g_iBanLength);
				}
				else if ( g_iBanLength == -1 ) {
					ServerCommand("sm_ban #%d 0 \"Вы забанены навсегда за частую смену тэгов\"", GetClientUserId(iClient));
					ServerCommand("sm_kick #%d \"Вы забанены навсегда за частую смену тэгов\"", GetClientUserId(iClient));
				}
				else {
					ServerCommand("sm_kick #%d \"Частая смена тэга\"", GetClientUserId(iClient));
				}
				return;
			}
			strcopy(g_szOldTag[iClient], sizeof(g_szOldTag[]), szCurrentTag);
		}
	}
}