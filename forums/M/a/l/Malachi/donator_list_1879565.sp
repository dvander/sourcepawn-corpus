/*
* Filename: donator.list.sp
* Description: Lists donators currently on server to admins
* Dependencies: donator.core.sp            
* Includes: donator.inc
* CVARs: donator_list_version
* Public: -none-
* 
* Changelog:
* 0.0.7 - fix donator number counter
* 0.0.6 - convert chat trigger to cvar, also check for fake player
* 0.0.5 - Changed chat trigger to avoid conflict w/basic donator plugin, removed unneeded cvar
* 0.0.4a - changed earlier admin check to prevent donators from triggering plugin
* 0.0.3a - alpha, added color text, changed admin check to exclude donators (unlike before)
* 0.2 - alpha
* 0.1 - alpha
*
* Restrictions:
* Uses color - cannot be used in game GetGameFolderName() == "hl2mp"
*/

#include <sourcemod>
#include <donator>

#pragma semicolon 1

#define PLUGIN_VERSION	"0.0.7"

public Plugin:myinfo = 
{
	name = "Donator List",
	author = "Malachi",
	description = "List donators for admins.",
	version = PLUGIN_VERSION,
	url = "http://www.necrophix.com/"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_listdonators", Command_Say, "List donators to admins.");
}

public OnAllPluginsLoaded()
{
	if(!LibraryExists("donator.core")) 
		SetFailState("Unable to find plugin: Basic Donator Interface");
}


public Action:Command_Say(iClient, args)
{
	// Is this console?
	if (!iClient)
		return Plugin_Handled;
		
	// Do we really need this check?
	// Are they in game?
	if (!IsClientInGame(iClient))
		return Plugin_Handled;
		
	// Is this client an admin?
	if (GetUserAdmin(iClient) == INVALID_ADMIN_ID)
		return Plugin_Handled;
	
	decl String:donName[MAX_NAME_LENGTH];
	new iCounter = 1;
	
	for (new iDon = 1; iDon <= MaxClients; iDon++)
	{
		// Is client in game?
		if (IsClientInGame(iDon))
		{
			// Is this client fake?
			if (!IsFakeClient(iDon))
			{
				// Is this client a donator?
				if (IsPlayerDonator(iDon))
				{
					// loop through all players to find admins and print only to them
					for (new iAdm = 1; iAdm <= MaxClients; iAdm++)
					{
						if (IsClientInGame(iAdm))
						{
							// print only to admins
							if (GetUserAdmin(iAdm) != INVALID_ADMIN_ID)
							{
								if (GetClientName(iDon, donName, sizeof(donName)))
									PrintToChat(iAdm, "\x04(ADMINS) \x01Donators: %d. %s", iCounter, donName);
							}	
						}
					}
					iCounter++;
				}
			}
		}
	}
	
	return Plugin_Handled;
}
