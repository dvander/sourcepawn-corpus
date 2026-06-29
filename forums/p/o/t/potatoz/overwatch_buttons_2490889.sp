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

bool btn[2048];

public Plugin:myinfo =
{
	name = "OVERWATCH:Buttons",
	author = "Potatoz",
	description = "Displays all button pressed to admins in console",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	HookEntityOutput("func_button", "OnPressed", Button_Pressed);
}

public Button_Pressed(const char[] output, caller, activator, float delay)
{
	if(!IsValidClient(activator)) return;
	
	if(btn[caller]) return;
	
	char entity[512], team[32];
	GetEntPropString(caller, Prop_Data, "m_iName", entity, sizeof(entity));

	if(GetClientTeam(activator) == 2)
		Format(team, sizeof(team), "(T)");
	else if(GetClientTeam(activator) == 3)
		Format(team, sizeof(team), "(CT)");
	else if(GetClientTeam(activator) < 2)
		Format(team, sizeof(team), "(SPEC)")
	
	char current_time[30];
	FormatTime(current_time, sizeof(current_time), "%H:%M:%S", GetTime());
	
	for (int x = 1; x <= MaxClients; x++) 
	{ 
		if (IsValidClient(x) && CheckCommandAccess(x, "generic_admin", ADMFLAG_GENERIC, false)) 
		{ 
			if(StrEqual(entity, ""))
				PrintToConsole(x, " OVERWATCH-BUTTONS | %s - \"%N\" %s pressed button #%i", current_time, activator, team, caller);
			else
				PrintToConsole(x, " OVERWATCH-BUTTONS | %s - \"%N\" %s pressed button #%i [%s]", current_time, activator, team, caller, entity);
		} 
	}
	
	btn[caller] = true;
	CreateTimer(5.0, Reset, caller);
}

public Action Reset(Handle timer, any entity)
{
	btn[entity] = false;
}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client)) 
        return false; 
     
    return true; 
}
