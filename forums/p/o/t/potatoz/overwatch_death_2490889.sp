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

public Plugin myinfo = 
{
	name = "OVERWATCH:Death", 
	author = "Potatoz", 
	description = "Show information about all kills", 
	version = "1.0", 
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_death", player_death);
}

public Action player_death(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	char wep[64]
	GetEventString(event, "weapon", wep, 64);
	
	if (client == 0 || attacker == 0)
		return Plugin_Continue
	
	char cname[32], aname[32]
	GetClientName(client, cname, 32)
	GetClientName(attacker, aname, 32)
	
	char cteam[32], ateam[32]
	if(GetClientTeam(client) == 2)
		Format(cteam, sizeof(cteam), "(T)")
	else if(GetClientTeam(client) == 3)
		Format(cteam, sizeof(cteam), "(CT)")
	else if(GetClientTeam(client) < 2)
		Format(cteam, sizeof(cteam), "(SPEC)")
		
	if(GetClientTeam(attacker) == 2)
		Format(ateam, sizeof(ateam), "(T)")
	else if(GetClientTeam(attacker) == 3)
		Format(ateam, sizeof(ateam), "(CT)")
	else if(GetClientTeam(client) < 2)
		Format(ateam, sizeof(ateam), "(SPEC)")
	
	char current_time[30];
	FormatTime(current_time, sizeof(current_time), "%H:%M:%S", GetTime());
	
	if (client != attacker)
	{
		for (int x = 1; x <= MaxClients; x++) 
			if (CheckCommandAccess(x, "generic_admin", ADMFLAG_GENERIC, false)) 
				PrintToConsole(x, " OVERWATCH-DEATH | %s - \"%s\" %s killed \"%s\" %s with %s", current_time, aname, ateam, cname, cteam, wep);
	}
	
	return Plugin_Continue
}
