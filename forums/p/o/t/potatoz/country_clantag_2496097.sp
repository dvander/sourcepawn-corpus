/*                                                        
 * 		    Copyright (C) 2018 Adam "Potatoz" Ericsson
 * 
 * 	This program is free software: you can redistribute it and/or modify it
 * 	under the terms of the GNU General Public License as published by the Free
 * 	Software Foundation, either version 3 of the License, or (at your option) 
 * 	any later version.
 *
 * 	This program is distributed in the hope that it will be useful, but WITHOUT 
 * 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * 	FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * 	See http://www.gnu.org/licenses/. for more information
 */

#include <sourcemod>
#include <geoip>
#include <cstrike>

#pragma semicolon 1 
 
public Plugin myinfo =
{
	name = "Country Clantags",
	author = "Potatoz",
	description = "Gives Admins and Players specific Country-Tags on Scoreboard",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	CreateTimer(1.0, Timer_SetClanTag, _, TIMER_REPEAT);
}

public Action Timer_SetClanTag(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++) 
    {
		if(IsValidClient(i) && !IsFakeClient(i))
		{
		
		char ip[16], geocode2[3], auth[32], clantag[45];
		
		GetClientIP(i, ip, sizeof(ip));
		GeoipCode2(ip, geocode2);
		GetClientAuthId(i, AuthId_Steam2, auth, sizeof(auth), false);

		if(StrEqual(auth, "STEAM_1:1:57886172", false))
			Format(clantag, sizeof(clantag), "DEVELOPER | %s", geocode2);
		else if(CheckCommandAccess(i, "root_admin", ADMFLAG_ROOT, false))
			Format(clantag, sizeof(clantag), "HEAD-ADMIN | %s", geocode2);
		else if(CheckCommandAccess(i, "generic_admin", ADMFLAG_GENERIC, false))
			Format(clantag, sizeof(clantag), "ADMIN | %s", geocode2);
		else Format(clantag, sizeof(clantag), "%s", geocode2);
		
		if(geocode2[0] == EOS )
		Format(clantag, sizeof(clantag), "NA");
		
		CS_SetClientClanTag(i, clantag);
		
		}
	}
	return Plugin_Continue;
}

public Action OnClientCommandKeyValues(int client, KeyValues kv) 
{ 
	char sCmd[64];

	if (kv.GetSectionName(sCmd, sizeof(sCmd)) && StrEqual(sCmd, "ClanTagChanged", false)) 
	{ 
		if(IsValidClient(client) && !IsFakeClient(client)) 
		{
		
		char ip[16], geocode2[3], auth[32], clantag[45];
		
		GetClientIP(client, ip, sizeof(ip));
		GeoipCode2(ip, geocode2);
		GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth), false);

		if(StrEqual(auth, "STEAM_1:1:57886172", false))
			Format(clantag, sizeof(clantag), "DEVELOPER | %s", geocode2);
		else if(CheckCommandAccess(client, "root_admin", ADMFLAG_ROOT, false))
			Format(clantag, sizeof(clantag), "HEAD-ADMIN | %s", geocode2);
		else if(CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false))
			Format(clantag, sizeof(clantag), "ADMIN | %s", geocode2);
		else Format(clantag, sizeof(clantag), "%s", geocode2);
			
		if(geocode2[0] == EOS )
		Format(clantag, sizeof(clantag), "NA");
		
		CS_SetClientClanTag(client, clantag);
		
		}
	}
	return Plugin_Continue;
}

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
} 