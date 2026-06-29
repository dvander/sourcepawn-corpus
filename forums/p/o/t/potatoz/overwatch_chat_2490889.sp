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
#include <sdktools>

public Plugin myinfo =
{
    name = "OVERWATCH:Chat",
    description = "Lets admins monitor all player chat",
    author = "Potatoz",
    version = "1.0",
    url = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("say_team", Command_SayTeam, "", 0);
}

public Action Command_SayTeam(int client, int args)
{		
	char text[192], team[32];
    GetCmdArgString(text, sizeof(text));
	if (text[1] == '@' || text[1] == '!' || text[1] == '/')
        return Plugin_Handled; 

    int startidx = trim_quotes(text);

	if(GetClientTeam(client) == 2)
		Format(team, sizeof(team), "(T)");
	else if(GetClientTeam(client) == 3)
		Format(team, sizeof(team), "(CT)");
	else if(GetClientTeam(client) < 2)
		Format(team, sizeof(team), "(SPEC)")
	
	char current_time[30];
	FormatTime(current_time, sizeof(current_time), "%H:%M:%S", GetTime());
	
	for (int x = 1; x <= MaxClients; x++) 
		if (CheckCommandAccess(x, "generic_admin", ADMFLAG_GENERIC, false) && GetClientTeam(client) != GetClientTeam(x)) 
			PrintToConsole(x, " OVERWATCH-CHAT | %s - \"%N\" %s: %s", current_time, client, team, text[startidx]);

	return Plugin_Continue;
}

public trim_quotes(char[] text)
{
	new startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0';
		}
	}
	
	return startidx;
}