#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <serverwhitelistadvanced>


public Action:OnClientKickedPre_ServerWhitelistAdvanced( client, bool:isFromBlacklistCache, const String:szSteamId[], const String:szIP[] )
{
	return Action:Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
	new String:steamid[24];
	GetClientAuthString(client, steamid, sizeof(steamid));

	if(IsSteamIdWhitelisted(steamid, true))
		KickClient(client, "Put your reason here");  // edit this
}