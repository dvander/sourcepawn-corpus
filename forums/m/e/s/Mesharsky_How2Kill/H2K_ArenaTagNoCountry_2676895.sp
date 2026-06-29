/*	Copyright (C) 2019 Mesharsky
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

/*================ Updates ================

04/06/2018
~ Version "0.1" >> First release.
13/12/2019
~ Version "0.2" >> Integrated with VIP plugin and added country TAG.

TODO:

~ Nothing atm

==============================================

//AHH LOVE
http://images6.fanpop.com/image/photos/36600000/Rias-Gremory-image-rias-gremory-36601369-1920-1080.png

*/

#include <sourcemod>
#include <geoip>
#include <cstrike>
#include <multi1v1>

#pragma newdecls required
#pragma semicolon 1

/* << Define >> */
#define PLUGIN_NAME "[CSGO] SPLEWIS ARENA SCOREBOARD MODIFICATION"
#define PLUGIN_DESCRIPTION "[CSGO] SPLEWIS ARENA SCOREBOARD MODIFICATION"
#define PLUGIN_AUTHOR "Mesharsky"
#define PLUGIN_VERSION "0.2"

ConVar g_cvVipFlag;

/* << Information about plugin >> */
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "http://steamcommunity.com/id/MesharskyH2K"
}

public void OnPluginStart()
{
	g_cvVipFlag = FindConVar("vip_flag");
}

public void Multi1v1_AfterPlayerSetup(int client)
{
	int ArenaNum = Multi1v1_GetArenaNumber(client);
	char TagScoreboard[32];
	
	if (IsValidClient(client))
	{
		Format(TagScoreboard, sizeof(TagScoreboard), "Arena %i | %s", ArenaNum);
		CS_SetClientClanTag(client, TagScoreboard);
	}
	if(IsPlayerVip(client))
	{
		Format(TagScoreboard, sizeof(TagScoreboard), "Arena %i | VIP", ArenaNum);
		CS_SetClientClanTag(client, TagScoreboard);
	}
	if (GetAdminFlag(GetUserAdmin(client), Admin_Root)) //z flag
	{
		Format(TagScoreboard, sizeof(TagScoreboard), "Arena %i | H@", ArenaNum);
		CS_SetClientClanTag(client, TagScoreboard);
	}
}

stock bool IsPlayerVip(int client)
{
    char flag[10];
    g_cvVipFlag.GetString(flag, sizeof(flag));
 
    if (GetUserFlagBits(client) & ReadFlagString(flag) || GetAdminFlag(GetUserAdmin(client), Admin_Root))
        return true;
    return false;
}

bool IsValidClient(int client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	if (IsClientReplay(client))return false;
	if (IsFakeClient(client))return false;
	if (IsClientSourceTV(client))return false;
	return IsClientInGame(client);
} 
 
/* © 2019 Coded with ❤ for Rias		  */
/* © 2019 Coded with ❤ for Akame			 */
/* © 2019 Coded with ❤ for Est		   */
/* © 2019 Coded with ❤ for Yoshino	   */
/* © 2019 Coded with ❤ for Koneko			*/
/* © 2019 Coded with ❤ for Erina			 */
/* © 2019 Coded with ❤ for Megumi			*/
/* © 2019 Coded with ❤ for Akeno			 */
/* © 2019 Coded with ❤ for Mero		  */
/* © 2019 Coded with ❤ for Papi		  */
/* © 2019 Coded with ❤ for Suu		   */
/* © 2019 Coded with ❤ for Lilith			*/
/* © 2019 Coded with ❤ for Mitsuha	   */
/* © 2019 Coded with ❤ for Matsuzaka	 */
/* © 2019 Coded with ❤ for Maki		  */
/* © 2019 Coded with ❤ for Alice			 */
/* © 2019 Coded with ❤ for Konno Yuuki   (*) Arigato! :< */