#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <geoip>

#define PLUGIN_NAME "In/Out Info"
#define PLUGIN_AUTHOR "Avo"
#define PLUGIN_DESCRIPTION "Display player infos on connect/disconnect"
#define PLUGIN_VERSION "1.1"

ConVar g_hCVarAdminOnly;
ConVar g_hCVarLogInOut;
bool g_bCVarAdminOnly = true;
bool g_bCVarLogInOut = true;

enum InfoMode
{
	InfoMode_Connect,
	InfoMode_Disconnect,
	InfoMode_Status
}

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://www.teamvec.fr/"
}

public void OnPluginStart()
{
	CreateConVar("inoutinfo_version", PLUGIN_VERSION, "In/Out Info version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hCVarAdminOnly = CreateConVar("inoutinfo_adminonly", "1", "Send message only to admins.", FCVAR_NONE);
	g_hCVarLogInOut = CreateConVar("inoutinfo_loginout", "1", "Log each connect/disconnect.", FCVAR_NONE);
	
	RegAdminCmd("sm_inoutinfo_status", Status, ADMFLAG_KICK);
	
	AutoExecConfig(true, "inoutinfo");

	LoadTranslations("common.phrases");
	LoadTranslations("inoutinfo.phrases");
	
	PrintToServer("SourceMod In/Out Info %s has been loaded successfully.", PLUGIN_VERSION);
	
	GetConVars();
}

public void OnClientAuthorized(int iClient)
{
	if (g_bCVarLogInOut)
		ShowMessage(iClient, view_as<InfoMode>(InfoMode_Connect));
}

public void OnClientDisconnect(int iClient)
{
	if(g_bCVarLogInOut && IsValidEntity(iClient))
		ShowMessage(iClient, view_as<InfoMode>(InfoMode_Disconnect));
}

public Action Status(int client, int args)
{
	if (args < 1)
	{
		char szText[128];
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			
			GetMessage(i, view_as<InfoMode>(InfoMode_Status), szText, sizeof(szText));
			
			if (client > 0)
				PrintToConsole(client, szText);
			else
				PrintToServer(szText);
		}
	}
	
	if (client > 0)
		PrintToChat(client, "\x01\x0B\x04[InOutInfo] \x01%t", "See console for output!");

	return Plugin_Handled;
}

void ShowMessage(int iClient, InfoMode iMode)
{
	char szText[128];
	GetMessage(iClient, iMode, szText, sizeof(szText));
	SendToAdmins(szText);
}	

void GetMessage(int iClient, InfoMode iMode, char[] szText, int sizeOfSzText)
{
	char szAuthID[22];
	char szIPAddress[18], szCountry[32], szName[32];
	
	GetClientIP(iClient, szIPAddress, sizeof(szIPAddress)-1, true);
	GeoipCountry(szIPAddress, szCountry, sizeof(szCountry)-1);
	
	GetClientAuthId(iClient, AuthId_Steam2, szAuthID, sizeof(szAuthID)-1);
	
	GetClientName(iClient, szName, sizeof(szName)-1);
	
	if (strlen(szCountry) == 0)
		Format(szCountry, sizeOfSzText-1, "%t", "Unknown");
	
	switch (iMode)
	{
		case (view_as<InfoMode>(InfoMode_Connect)):
		{
			Format(szText, sizeOfSzText-1, "%s (%s) %t %s (%s)", szName, szAuthID, "is connecting from", szCountry, szIPAddress);
		}
		case (view_as<InfoMode>(InfoMode_Disconnect)):
		{
			Format(szText, sizeOfSzText-1, "%s (%s) %t %s (%s)", szName, szAuthID, "has disconnected from", szCountry, szIPAddress);
		}
		case (view_as<InfoMode>(InfoMode_Status)):
		{
			Format(szText, sizeOfSzText-1, "%s (%s) : %s (%s)", szName, szAuthID, szCountry, szIPAddress);
		}
	}
}

void SendToAdmins(char[] message)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (!g_bCVarAdminOnly || CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT)))
		{
			PrintToChat(i, "\x01\x0B\x04[InOutInfo] \x01%s", message);
			PrintToConsole(i, "[InOutInfo] %s", message);
		}
	}
}
    
public void OnConVarChange(ConVar convar_hndl, const char[] oldValue, const char[] newValue)
{
	GetConVars();
}

public void OnConfigsExecuted()
{
	GetConVars();
}

public void GetConVars()
{
	g_bCVarAdminOnly = GetConVarBool(g_hCVarAdminOnly);
	g_bCVarLogInOut = GetConVarBool(g_hCVarLogInOut);
}
