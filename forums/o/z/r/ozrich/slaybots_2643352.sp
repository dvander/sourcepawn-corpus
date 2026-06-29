
 /**
 *	
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#pragma dynamic 32768	// Increase heap size
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#undef REQUIRE_EXTENSIONS
#define REQUIRE_EXTENSIONS
#define PLUGIN_VERSION "1.6"
#define TEAM_2_INS 3

public Plugin myinfo = 
{
	name = "[INS] Slay Bots",
	author = "ozzy",
	description = "Slay all bots in Insurgency",
	version = PLUGIN_VERSION,
	url = ""
};


// Start plugin
public void OnPluginStart()
{
	RegConsoleCmd("sm_slaybots", slaybots);
}

public Action slaybots(int client, int args)
{
	PrintToChat(client, "All bots will now be killed");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && IsPlayerAlive(i))
		{
			ForcePlayerSuicide(i);
		}
	}
	return Plugin_Handled;
}