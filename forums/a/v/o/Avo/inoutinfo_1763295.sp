#pragma semicolon 1
#include <sourcemod>
#include <geoip>

#define PLUGIN_NAME "In/Out Info"
#define PLUGIN_AUTHOR "Avo"
#define PLUGIN_DESCRIPTION "Display player infos on connect/disconnect"
#define PLUGIN_VERSION "1.1"

new Handle:g_hCVarAdminOnly = INVALID_HANDLE;
new Handle:g_hCVarLogInOut = INVALID_HANDLE;
new bool:g_bCVarAdminOnly = true;
new bool:g_bCVarLogInOut = true;

enum InfoMode
{
	InfoMode_Connect,
	InfoMode_Disconnect,
	InfoMode_Status
}

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://www.teamvec.fr/"
}

public OnPluginStart()
{
	CreateConVar("inoutinfo_version", PLUGIN_VERSION, "In/Out Info version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hCVarAdminOnly = CreateConVar("inoutinfo_adminonly", "1", "Send message only to admins.", FCVAR_PLUGIN);
	g_hCVarLogInOut = CreateConVar("inoutinfo_loginout", "1", "Log each connect/disconnect.", FCVAR_PLUGIN);
	
	RegAdminCmd("sm_inoutinfo_status", Status, ADMFLAG_KICK);
	
	AutoExecConfig(true, "inoutinfo");

	LoadTranslations("common.phrases");
	LoadTranslations("inoutinfo.phrases");
	
	PrintToServer("SourceMod In/Out Info %s has been loaded successfully.", PLUGIN_VERSION);
	
	GetConVars();
}

public OnClientAuthorized(iClient)
{
	if (g_bCVarLogInOut)
		ShowMessage(iClient, InfoMode:InfoMode_Connect);
}

public OnClientDisconnect(iClient)
{
	if(g_bCVarLogInOut && IsValidEntity(iClient))
		ShowMessage(iClient, InfoMode:InfoMode_Disconnect);
}

public Action:Status(client, args) {
	if (args < 1)
	{
		decl String:szText[128];

		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			
			GetMessage(i, InfoMode:InfoMode_Status, szText, sizeof(szText));
			
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

ShowMessage(iClient, InfoMode:iMode)
{
	decl String:szText[128];
	
	GetMessage(iClient, iMode, szText, sizeof(szText));
	
	SendToAdmins(szText);
}	

GetMessage(iClient, InfoMode:iMode, String:szText[], sizeOfSzText)
{
	
	decl String:szAuthID[22];
	decl String:szIPAddress[18], String:szCountry[32], String:szName[32];
	
	GetClientIP(iClient, szIPAddress, sizeof(szIPAddress)-1, true);
	GeoipCountry(szIPAddress, szCountry, sizeof(szCountry)-1);
	
	GetClientAuthString(iClient, szAuthID, sizeof(szAuthID)-1);
	
	GetClientName(iClient, szName, sizeof(szName)-1);
	
	if (strlen(szCountry) == 0)
		Format(szCountry, sizeOfSzText-1, "%t", "Unknown");
	
	switch (iMode)
	{
		case (InfoMode:InfoMode_Connect):
		{
			Format(szText, sizeOfSzText-1, "%s (%s) %t %s (%s)", szName, szAuthID, "is connecting from", szCountry, szIPAddress);
		}
		case (InfoMode:InfoMode_Disconnect):
		{
			Format(szText, sizeOfSzText-1, "%s (%s) %t %s (%s)", szName, szAuthID, "has disconnected from", szCountry, szIPAddress);
		}
		case (InfoMode:InfoMode_Status):
		{
			Format(szText, sizeOfSzText-1, "%s (%s) : %s (%s)", szName, szAuthID, szCountry, szIPAddress);
		}
	}
}	

SendToAdmins(String:message[])
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (!g_bCVarAdminOnly || CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT)))
		{
			PrintToChat(i, "\x01\x0B\x04[InOutInfo] \x01%s", message);
			PrintToConsole(i, "[InOutInfo] %s", message);
		}	
	}
}
    
public OnConVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
  GetConVars();
}

public OnConfigsExecuted()
{
  GetConVars();
}

public GetConVars()
{
  g_bCVarAdminOnly = GetConVarBool(g_hCVarAdminOnly);
  g_bCVarLogInOut = GetConVarBool(g_hCVarLogInOut);
}
