
// enforce semicolons after each code statement
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.3"



/*****************************************************************


		P L U G I N   I N F O


*****************************************************************/

public Plugin:myinfo = {
	name = "Hide sv_downloadurl",
	author = "Berni",
	description = "Hides the sv_downloadurl",
	version = PLUGIN_VERSION,
	url = "http://www.mannisfunhouse.eu"
}



/*****************************************************************


		G L O B A L   V A R S


*****************************************************************/

// ConVar Handles
new Handle:sv_downloadurl = INVALID_HANDLE;

// Misc



/*****************************************************************


		F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart() {

	sv_downloadurl = FindConVar("sv_downloadurl");
}

public OnClientPutInServer(client) {
	
	SendConVarValue(client, sv_downloadurl, "");
}



/****************************************************************


		C A L L B A C K   F U N C T I O N S


****************************************************************/





/*****************************************************************


		P L U G I N   F U N C T I O N S


*****************************************************************/

