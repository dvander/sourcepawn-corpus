/*
SourceMod Country Nick Plugin
Add country of the player near his nick
 
Country Nick Plugin (C)2009-2010 A-L. All rights reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

$Id: countrynick.sp 29 2009-02-23 23:45:22Z aen0 $
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>
 
#define VERSION "1.2"

public Plugin:myinfo =
{
	name = "Country Nick Plugin",
	author = "Antoine LIBERT aka AeN0",
	description = "Add country of the player near his nick",
	version = VERSION,
	url = "http://www.a-l.fr/"
};

public OnPluginStart()
{
	LoadTranslations("countrynick.phrases");
	CreateConVar("countrynick_version", VERSION, "Country Nick Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnClientPostAdminCheck(client)
{
	if (!client)
		return;

	decl String:ip[16];
	decl String:country[46];
	
	if(!IsFakeClient(client) && client != 0)
	{
		GetClientIP(client, ip, 16); 
		new AdminId:AId = GetUserAdmin(client);
		new flags = GetAdminFlags(AId, Access_Effective);
		new AdminLevel = GetAdminImmunityLevel(AId);
		if (AdminLevel > 89)
		{
			AdminLevel = 0;
		}
//		decl String:flagstring[255];	
		if(GeoipCountry(ip, country, 45))
		{
			if (flags & ADMFLAG_GENERIC)
			{
				PrintToChatAll("\x03Admin (level %d) \x04%N\x03 (%s) has entered the game. Zombies grow stronger!", AdminLevel, client, country);
			}
			else
			{
				PrintToChatAll("\x05Player (level %d) \x04%N\x05 (%s) has entered the game. Zombies grow stronger!", AdminLevel, client, country);
			}
		}
		else
		{
			if (flags & ADMFLAG_GENERIC)
			{
				PrintToChatAll("\x03Admin (level %d) \x04%N\x03 has entered the game. Zombies grow stronger!", AdminLevel, client, country);
			}
			else
			{
				PrintToChatAll("\x05Player (level %d) \x04%N\x05 has entered the game. Zombies grow stronger!", AdminLevel, client, country);
			}
		}
	}
}
