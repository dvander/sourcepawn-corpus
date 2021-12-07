
// enforce semicolons after each code statement
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"



/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/

public Plugin:myinfo = {
	name = "Cheat Log",
	author = "Berni",
	description = "Plugin by Berni",
	version = PLUGIN_VERSION,
	url = "http://www.mannisfunhouse.eu"
}



/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/

// ConVar Handles

// Misc



/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart() {

    decl String:name[64];
    new Handle:cvar;
    new bool:isCommand;
    new flags;
    
    cvar = FindFirstConCommand(name, sizeof(name), isCommand, flags);
    if (cvar ==INVALID_HANDLE) {
        SetFailState("Could not load cvar list");
    }
    
    do {
        if (!isCommand || !(flags & FCVAR_CHEAT)) {
            continue;
        }
        
        RegConsoleCmd(name, OnCheatCommand);
        
    } while (FindNextConCommand(cvar, name, sizeof(name), isCommand, flags));
}



/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:OnCheatCommand(client, args) {

	decl String:cmd[64], String:cmdArgStr[256];
	GetCmdArg(0, cmd, sizeof(cmd));
	GetCmdArgString(cmdArgStr, sizeof(cmdArgStr));

	LogToFile("cheatcommands_log.txt", "Player %L used command %s %s", client, cmd, cmdArgStr);
}



/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/

