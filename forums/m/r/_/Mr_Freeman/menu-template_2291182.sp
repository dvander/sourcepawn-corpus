#pragma semicolon 1

#include <sourcemod>
#include <adminmenu>

//----------------------------------//
// 	Plugin: Display of Information	//
//----------------------------------//
public Plugin:myinfo =
{
	name 			= "MENU TEMPLATE",
	author 			= "Mr. Freeman",
	description		= "Describe Me",
	version 		= "1.00",
	url 			= "http://alliedmods.net"
};

//------------------//
// 	Plugin: Start	//
//------------------//
public OnPluginStart()
{
	// Generate In-game Command
	RegConsoleCmd("sm_command", Command_INSERTNAME, "Describe my Function / Purpose");
	// OR For Admin Command Menu
	RegAdminCmd("sm_admincommand", Command_INSERTNAME2, 0); 
}

//---------------------------//
//	CONSOLE COMMAND OPTIONS	 //
//---------------------------//
public Action:Command_INSERTNAME(client, args)
{
	// CHECK IF CLIENT IS REALLY THERE
	if(IsClientInGame(client) || !IsFakeClient(client)) {
		MainMenu(client);
	}
}

//---------------------------//
//	ADMIN COMMAND OPTIONS	 //
//---------------------------//
public Action:Command_INSERTNAME2(client, args)
{
	// CHECK IF CLIENT IS REALLY THERE
	if(IsClientInGame(client) || !IsFakeClient(client)) {
		MainMenu(client);
	}
	// You can also include checkaccess inorder to make sure they are admins.
}

/*
 ##################################################################################
#  __  __                         ___     _   _                 _ _                #
# |  \/  | ___ _ __  _   _ ___   ( _ )   | | | | __ _ _ __   __| | | ___ _ __ ___  #
# | |\/| |/ _ \ '_ \| | | / __|  / _ \/\ | |_| |/ _` | '_ \ / _` | |/ _ \ '__/ __| #
# | |  | |  __/ | | | |_| \__ \ | (_>  < |  _  | (_| | | | | (_| | |  __/ |  \__ \ #
# |_|  |_|\___|_| |_|\__,_|___/  \___/\/ |_| |_|\__,_|_| |_|\__,_|_|\___|_|  |___/ #
#																				   #
 ################################################################################## 
*/
MainMenu(client) {
	new Handle:menu = CreateMenu(Handler_FirstMenu);
	// MENU TITLE
	SetMenuTitle(menu, "INSERT TITLE HERE");

	// Explanation: 	OPTION	 |  CLIENT SEES
	AddMenuItem(menu, "function1", "Function 1");
	AddMenuItem(menu, "function2", "Function 2");
	AddMenuItem(menu, "function3", "Function 3");
	AddMenuItem(menu, "function4", "Function 4");

	// CREATE EXIT BUTTON
	SetMenuExitBackButton(menu, true);

	// SEND THE MENU TO THE CLIENT
	// To: CLIENT | Time: Forever (0)
	DisplayMenu(menu, client, 0);
}

public Handler_FirstMenu(Handle:menu, MenuAction:action, client, param) {
	// IF CLIENT HITS CLOSEMENU OPTION
	if(action == MenuAction_End) {
		CloseHandle(menu);
	} 
	// IF THEY SELECT A NONE EXISTANT BUTTON
	if(action != MenuAction_Select) {
		return;
	}
	
	decl String:selection[16];
	GetMenuItem(menu, param, selection, sizeof(selection));
	// -- Function 1
	// If the client selects this button
	if(StrEqual(selection, "function1")) {
		// Do Something Here
		// Example:
		PrintToChat(client, "You've selected Function 1"); 
	} 
	// -- Function 2
	// If the client selects this button
	if(StrEqual(selection, "function2")) {
		// Do Something Here
		// Example:
		PrintToChat(client, "You've selected Function 2"); 
	}
	// -- Function 3
	// If the client selects this button
	if(StrEqual(selection, "function3")) {
		// Do Something Here
		// Example:
		PrintToChat(client, "You've selected Function 3");  
	} 
	// -- Function 4
	// If the client selects this button
	if(StrEqual(selection, "function4")) {
		// Do Something Here
		// Example:
		PrintToChat(client, "You've selected Function 4"); 
	} 
}