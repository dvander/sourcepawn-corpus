/**
* Auto Name Changer by MoggieX
*
* Description:
* 	If a player connects with the name "unnamed" we chnage to a helpful name
*	Remember you were a n00b once too!
*
* Usage:
* 	Install and go!
*	Alter the convar sm_autoname_name if needed
*	
* Thanks to:
* 	Tsunami =D
*  	 bl4nk for the layout of the this plugin
*
* Version 3.0
*  - Added checks for any player with "unnamed" in thier name or what ever has been set in sm_autoname_ntc
*
*/

#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "3.0"

//Handles
new Handle:cvarNewName;
new Handle:NameToCheck;	

public Plugin:myinfo = 
{
	name = "Auto Name Changer",
	author = "MoggieX",
	description = "Auto changes players named unnamed",
	version = PLUGIN_VERSION,
	url = "http://www.UKManDown.co.uk"
};

public OnPluginStart()
{
	CreateConVar("sm_autoname_version", PLUGIN_VERSION, "Name Changer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarNewName = CreateConVar("sm_autoname_name", "Press ESC > Options > Set Name", "Default name to chnage to",FCVAR_PRINTABLEONLY);	//|FCVAR_REPLICATED|FCVAR_NOTIFY
	NameToCheck = CreateConVar("sm_autoname_ntc", "unnamed", "Name to check, if css unnamed or Eternal Silence change to ES Newbie",FCVAR_PRINTABLEONLY);	//|FCVAR_REPLICATED|FCVAR_NOTIFY
}

//////////////////////////////////////////////////////////////////
// Player checking on connection (post admin check)
//////////////////////////////////////////////////////////////////

public OnClientPostAdminCheck(client)
{

// Check if a BOT if = then bailout

	if(IsFakeClient(client))
	return true;

// Error Checking Only
//	PrintToChatAll("\x04[Step 1 Auto Name Changer]\x03 Player entered server and is not a bot");

// Declare some stuff
 	decl String:player_name[65];		// Player name
	new String:new_name[65];
	new String:name_to_check[65];
	GetConVarString(cvarNewName,new_name,65);
	GetConVarString(NameToCheck,name_to_check,65);

// Error Checking Only	
//	PrintToChatAll("\x04[Step 1 Auto Name Changer]\x03 Player Name: \x04%s\x03 CVar Name: \x04%s \x03 CVar Name to Check: \x04%s",player_name,new_name,name_to_check);

// Get Client Name
 	GetClientName(client, player_name, sizeof(player_name));

// Check for a Match
	// Old way
  	//if (StrEqual(player_name,  name_to_check))
  	if (StrContains(player_name, name_to_check) != -1)
  	{
		// Do some stuff
		
		// Proper way
		//PrintToChat(client, "\x04[Welcome!]\x03 %t", "Name Changed");

		// Lets hard code it anyway
		PrintToChat(client, "\x04[Welcome!]\x03 You can change your name by %s ",new_name);
		ClientCommand(client, "name \"%s\"", new_name);
		
   		return true;
  	}

   	return true;	
 }