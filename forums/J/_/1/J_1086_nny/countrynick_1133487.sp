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
 
#define VERSION "1.1.1"

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

public OnClientPutInServer(client)
{
	decl String:ip[16];
	decl String:country[46];
	
	if(!IsFakeClient(client) && client != 0)
	{
		GetClientIP(client, ip, 16); 
		
		if(GeoipCountry(ip, country, 45))
		{
			PrintToChatAll("\x05Player \x04%N\x05 (%s) has entered the game. Zombies grow stronger!\x03", client, country);
//			PrintToChatAll("\x03%T", "Announcer country found", LANG_SERVER, client, country);
		}
		else
		{
			PrintToChatAll("\x05Player \x04%N\x05 has entered the game. Zombies grow stronger!\x03", client);
//			PrintToChatAll("\x03%T", "Announcer country not found", LANG_SERVER, client);
		}
	}
}
