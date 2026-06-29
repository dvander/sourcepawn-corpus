/**
 * =============================================================================
 * Show Players (C) 2010
 * Show info (Admin, Ghost, UserID, IP, Country, SteamID, Name) about players on server.
 *
 * Created by AnIHiL <mailto:aanihil@hotmail.com>.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include <sourcemod>
#include <geoip>

#define PLUGIN_VERSION "1.1.0"

public Plugin:myinfo =
{
	name = "Show Players",
	author = "AnIHiL",
	description = "Show info (Admin, Ghost, UserID, IP, Country, SteamID, Name) about players on server",
	version = PLUGIN_VERSION,
	url = "http://bunny-hop.pl"
};

public OnPluginStart()
{
	SetConVarString(CreateConVar("sm_users_version", PLUGIN_VERSION, "Show Players version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT), PLUGIN_VERSION);

	RegAdminCmd("sm_users", Command_SmUsers, ADMFLAG_GENERIC, "Show info (Admin, Ghost, UserID, IP, Country, SteamID, Name) about players on server");
}

public Action:Command_SmUsers(client, args)
{
	if (args < 1)
	{
		// Header
		decl String:h_admin[2];
		decl String:h_userid[7];
		decl String:h_ip[17];
		decl String:h_country[21];
		decl String:h_steamid[21];
		decl String:h_name[35];
		Format(h_admin, sizeof(h_admin), "%s", "A");
		Format(h_userid, sizeof(h_userid), "%s", "UserID");
		Format(h_ip, sizeof(h_ip), "%s", "IP Address");
		Format(h_country, sizeof(h_country), "%s", "Country");
		Format(h_steamid, sizeof(h_steamid), "%s", "Steam ID");
		Format(h_name, sizeof(h_name), "%s", "Name");

		PrintToConsole(client, "%1.1s %-6.6s %-15.15s %-20.20s %-20.20s %-34.34s", h_admin, h_userid, h_ip, h_country, h_steamid, h_name);
		PrintToConsole(client, "----------------------------------------------------------------------------------------------------");

		new String:tmp_admin[2];
		new AdminId:id;
		new tmp_userid;
		new String:tmp_ip[17];
		new String:tmp_steamid[21];
		new String:tmp_country[21];
		new String:tmp_name[35];
		
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			id = GetUserAdmin(i);
			
			if (id != INVALID_ADMIN_ID)
			{
				Format(tmp_admin, sizeof(tmp_admin), "%s", "A");
			}
			
			tmp_userid = GetClientUserId(i);
			
			GetClientIP(i, tmp_ip, 17);

			GeoipCountry(tmp_ip, tmp_country, 20);
			
			GetClientAuthString(i, tmp_steamid, 21);
			
			GetClientName(i, tmp_name, 35);
			PrintToConsole(client, "%1.1s %-6.6d %-15.15s %-20.20s %-20.20s %-34.34s", tmp_admin, tmp_userid, tmp_ip, tmp_country, tmp_steamid, tmp_name);
		}
	}
}
