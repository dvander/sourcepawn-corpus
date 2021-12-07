/*	=============================================
*	- NAME:
*	  + FF Connect/Disconnect Messages
*
*	- DESCRIPTION:
*	  + This plugin removes the default connect/disconnect messages and adds new ones.
*
*	  + The new messages show the clients Name, SteamID, Country, and IP Address.
*	  + The messages are colored for easy readability (colors only work for Fortress-Forever).
*
*	  + When players connect/disconnect a bell tone is played throughout the server.
* 	
* 	
*	---------------
*	Credits/Thanks:
*	---------------
*	- [Geokill]: Helped test plugin and had ideas.
*	- [PartialSchism]: Helped test plugin.
* 	
* 	
*	----------
*	Changelog:
*	----------
*	Version 1.0 ( 03-03-2009 )
*	-- Initial release.
* 	
*	Version 1.1 ( 03-05-2009 )
*	-- Optimized the SayText function so it no longer needs the extra name checks.
* 	
*/

#include <sourcemod>
#include <sdktools_sound>
#include <geoip>

#define VERSION "1.1"
public Plugin:myinfo = 
{
	name = "FF Connect/Disconnect Messages",
	author = "hlstriker",
	description = "Removes the default connect/disconnect messages and adds new ones.",
	version = VERSION,
	url = "None"
}

#define SOUND_CONNECT "vox/tfc/fvox/bell.wav"

public OnPluginStart()
{
	CreateConVar("sv_connectmsgver", VERSION, "FF Connect/Disconnect Messages", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_connect", event_connect, EventHookMode_Pre);
	HookEvent("player_disconnect", event_disconnect, EventHookMode_Pre);
}

public OnMapStart()
	PrecacheSound(SOUND_CONNECT);

public OnClientAuthorized(iClient)
	ShowMessage(iClient);

public OnClientDisconnect(iClient)
{
	if(IsValidEntity(iClient))
		ShowMessage(iClient, 1);
}

ShowMessage(iClient, iMode=0)
{
	// [iMode 0 = Connect] [iMode 1 = Disconnect]
	
	decl String:szAuthID[22], String:szText[128];
	decl String:szIPAddress[18], String:szCountry[32], String:szName[32];
	
	GetClientIP(iClient, szIPAddress, sizeof(szIPAddress)-1, true);
	GeoipCountry(szIPAddress, szCountry, sizeof(szCountry)-1);
	
	GetClientAuthString(iClient, szAuthID, sizeof(szAuthID)-1);
	ReplaceString(szAuthID, sizeof(szAuthID)-1, "STEAM_", "");
	
	GetClientName(iClient, szName, sizeof(szName)-1);
	
	if(!iMode)
		Format(szText, sizeof(szText)-1, "^6-^2%s ^6[^5%s^6] ^7is ^9connecting ^7from ^1%s ^6[^5%s^6]", szName, szAuthID, szCountry, szIPAddress);
	else
		Format(szText, sizeof(szText)-1, "^6-^2%s ^6[^5%s^6] ^7has ^8disconnected ^7from ^1%s ^6[^5%s^6]", szName, szAuthID, szCountry, szIPAddress);
	
	SayText(szText, 1);
}

public Action:event_connect(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast)
{
	if(!bDontBroadcast)
    {
		decl String:szName[32], String:szNetworkID[22], String:szAddress[26];
		GetEventString(hEvent, "name", szName, sizeof(szName)-1);
		GetEventString(hEvent, "networkid", szNetworkID, sizeof(szNetworkID)-1);
		GetEventString(hEvent, "address", szAddress, sizeof(szAddress)-1);
		
		new Handle:hNewEvent = CreateEvent("player_connect", true);
		SetEventString(hNewEvent, "name", szName);
		SetEventInt(hNewEvent, "index", GetEventInt(hEvent, "index"));
		SetEventInt(hNewEvent, "userid", GetEventInt(hEvent, "userid"));
		SetEventString(hNewEvent, "networkid", szNetworkID);
		SetEventString(hNewEvent, "address", szAddress);
		
		FireEvent(hNewEvent, true);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:event_disconnect(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast)
{
	if(!bDontBroadcast)
    {
		decl String:szReason[22], String:szName[32], String:szNetworkID[22];
		GetEventString(hEvent, "reason", szReason, sizeof(szReason)-1);
		GetEventString(hEvent, "name", szName, sizeof(szName)-1);
		GetEventString(hEvent, "networkid", szNetworkID, sizeof(szNetworkID)-1);
		
		new Handle:hNewEvent = CreateEvent("player_disconnect", true);
		SetEventInt(hNewEvent, "userid", GetEventInt(hEvent, "userid"));
		SetEventString(hNewEvent, "reason", szReason);
		SetEventString(hNewEvent, "name", szName);
		SetEventString(hNewEvent, "networkid", szNetworkID);
		
		FireEvent(hNewEvent, true);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

stock SayText(const String:szText[], const iColor=1, const iClient=0)
{
	new String:szFormat[1024];
	FormatEx(szFormat, sizeof(szFormat)-1, "\x02%s\x0D\x0A", szText);
	
	new Handle:hBf;
	if(iClient <= 0)
		hBf = StartMessageAll("SayText");
	else
	{
		hBf = StartMessageOne("SayText", iClient);
	}
	BfWriteString(hBf, szFormat);
	BfWriteByte(hBf, iColor);
	EndMessage();
	
	EmitSoundToAll(SOUND_CONNECT);
}