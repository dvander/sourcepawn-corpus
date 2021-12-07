#pragma semicolon 1
#pragma dynamic 645221
#include <sourcemod>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>
#include <tinyxml>

#define PLUGIN_VERSION "1.0"

new String:g_sCommunityGameName[64];
new Handle:g_hCVMinPlayTime;

public Plugin:myinfo = 
{
	name = "Hours Played Kicker",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Kicks players who didn't play the game long enough yet.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_hoursplayed_version", PLUGIN_VERSION, "Hours Played Kicker", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hCVMinPlayTime = CreateConVar("sm_hoursplayed_minplaytime", "0", "How many minutes do players need to have played in order to join?", FCVAR_PLUGIN, true, 0.0);
	
	// From HLX:CE
	decl String:sGameDescription[64];
	GetGameDescription(sGameDescription, sizeof(sGameDescription), true);
	if (StrContains(sGameDescription, "Counter-Strike", false) != -1)
	{
		Format(g_sCommunityGameName, sizeof(g_sCommunityGameName), "CS:S");
	}
	else if (StrContains(sGameDescription, "Day of Defeat", false) != -1)
	{
		Format(g_sCommunityGameName, sizeof(g_sCommunityGameName), "DOD:S");
	}
	else if (StrContains(sGameDescription, "Team Fortress", false) != -1)
	{
		Format(g_sCommunityGameName, sizeof(g_sCommunityGameName), "TF2");
	}
	else if (StrContains(sGameDescription, "L4D2", false) != -1)
	{
		Format(g_sCommunityGameName, sizeof(g_sCommunityGameName), "L4D2");
	}
	else if (StrContains(sGameDescription, "L4D", false) != -1 || StrContains(sGameDescription, "Left 4 D", false) != -1)
	{
		Format(g_sCommunityGameName, sizeof(g_sCommunityGameName), "L4D");
	}
	else
	{
		SetFailState("Unable to determine mod.");
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if(GetConVarInt(g_hCVMinPlayTime) <= 0)
		return;
	
	decl String:sSteamID[65];
	Steam_RenderedIDToCSteamID(auth, sSteamID, sizeof(sSteamID));
	
	decl String:sURL[256];
	Format(sURL, sizeof(sURL), "http://steamcommunity.com/profiles/%s/stats/%s/", sSteamID, g_sCommunityGameName);
	new HTTPRequestHandle:hRequest = Steam_CreateHTTPRequest(HTTPMethod_GET, sURL);
	Steam_SetHTTPRequestGetOrPostParameter(hRequest, "xml", "1");
	Steam_SetHTTPRequestNetworkActivityTimeout(hRequest, 5);
	Steam_SendHTTPRequest(hRequest, HTTP_RequestComplete, GetClientUserId(client));
}

public HTTP_RequestComplete(HTTPRequestHandle:HTTPRequest, bool:requestSuccessful, HTTPStatusCode:statusCode, any:contextData)
{
	if(!requestSuccessful || statusCode != HTTPStatusCode_OK)
	{
		if(requestSuccessful)
			Steam_ReleaseHTTPRequest(HTTPRequest);
		
		LogError("Error requesting steam profile (HTTP status: %d)", statusCode);
		return;
	}
	
	new client = GetClientOfUserId(contextData);
	if(!client)
	{
		Steam_ReleaseHTTPRequest(HTTPRequest);
		return;
	}
	
	// Disabled?
	new iMinPlayTime = GetConVarInt(g_hCVMinPlayTime);
	if(iMinPlayTime <= 0)
	{
		Steam_ReleaseHTTPRequest(HTTPRequest);
		return;
	}
	
	new iBodySize = Steam_GetHTTPResponseBodySize(HTTPRequest);
	decl String:sBody[iBodySize+1];
	Steam_GetHTTPResponseBodyData(HTTPRequest, sBody, iBodySize);

	new Handle:hXML = TinyXml_CreateDocument();
	TinyXml_Parse(hXML, sBody);
	
	new Handle:hRoot = TinyXml_RootElement(hXML);
	if(hRoot != INVALID_HANDLE)
	{
		new Handle:hStats = TinyXml_FirstChildElement(hRoot, "stats");
		if(hStats != INVALID_HANDLE)
		{
			new Handle:hHoursPlayed = TinyXml_FirstChildElement(hStats, "hoursPlayed");
			if(hHoursPlayed != INVALID_HANDLE)
			{
				decl String:sHoursPlayed[32];
				TinyXml_GetText(hHoursPlayed, sHoursPlayed, sizeof(sHoursPlayed));
				
				// Formated "xxh yym"
				if(TimeStringToMinutes(sHoursPlayed) < iMinPlayTime)
				{
					KickClient(client, "You need at least %d minutes played in this game to play on this server", iMinPlayTime);
				}
				CloseHandle(hHoursPlayed);
			}
			else
				LogError("Can't find hoursPlayed element.");
			CloseHandle(hStats);
		}
		else
		{
			//LogError("Can't find stats element.");
			KickClient(client, "You have to set your steam community profile to publicly viewable in order to play on this server");
		}
		CloseHandle(hRoot);
	}
	else
		LogError("Can't get root element.");
	
	CloseHandle(hXML);
	Steam_ReleaseHTTPRequest(HTTPRequest);
}

TimeStringToMinutes(const String:sTime[])
{
	decl String:sBuffer[10];
	new iOffset = 0, iPosition, iMinutes = 0;
	
	if((iPosition = StrContains(sTime, "h", false)) != -1)
	{
		Format(sBuffer, iPosition+1, "%s", sTime);
		iMinutes += StringToInt(sBuffer)*60;
		iOffset += iPosition+1;
	}
	
	if((iPosition = StrContains(sTime[iOffset], "m", false)) != -1)
	{
		Format(sBuffer, iPosition+1, "%s", sTime[iOffset]);
		iMinutes += StringToInt(sBuffer);
	}
	
	return iMinutes;
}