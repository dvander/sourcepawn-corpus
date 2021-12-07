/*****************************************************************


C O M P I L E   O P T I O N S


*****************************************************************/
// enforce semicolons after each code statement
#pragma semicolon 1

/*****************************************************************


P L U G I N   I N C L U D E S


*****************************************************************/
#include <sourcemod>
#include <sdktools>


/*****************************************************************


P L U G I N   I N F O


*****************************************************************/
#define PLUGIN_NAME				"OnPlayerRunCmd Test"
#define PLUGIN_TAG				"sm"
#define PLUGIN_AUTHOR			"Chanz"
#define PLUGIN_DESCRIPTION		"spams the chat with a message if OnPlayerRunCmd is working!"
#define PLUGIN_VERSION 			"1.0.0"
#define PLUGIN_URL				"<url>"

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

/*****************************************************************


		P L U G I N   D E F I N E S


*****************************************************************/


/*****************************************************************


		G L O B A L   V A R S


*****************************************************************/


/*****************************************************************


		F O R W A R D   P U B L I C S


*****************************************************************/

public Action:OnPlayerRunCmd(client,&buttons,&impulse,Float:vel[3],Float:angles[3],&weapon){
	
	PrintToChatAll("OnPlayerRunCmd works for client: %d",client);
	return Plugin_Continue;
}

/****************************************************************


		C A L L B A C K   F U N C T I O N S


****************************************************************/


/*****************************************************************


		P L U G I N   F U N C T I O N S


*****************************************************************/




