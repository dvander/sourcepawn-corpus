#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo ={
	name = "List SourceMod Commands",
	author = "denormal",
	description = "Lists SourceMod commands accessible to the client.",
	version = "1.0",
	url = ""
};

public OnPluginStart() {
	RegAdminCmd("sm_listcmd", Command_listcmd, 0);
}

public Action:Command_listcmd(client, args) {
	decl String:name[64];
	new Handle:cvar, bool:isCommand, flags;
	
	cvar = FindFirstConCommand(name, sizeof(name), isCommand, flags);
	
	if(cvar == INVALID_HANDLE) {
		PrintToConsole(client, "Could not load cvar list");
		return Plugin_Handled;
	}
	
	do {
		if(!isCommand) 
			continue;
		
		new bool:isSmCmd = name[0] == 's' && name[1] == 'm' && name[2] == '_';
		
		if (isSmCmd && CheckCommandAccess(client, name, 0, false)) {
			PrintToConsole(client, "%s", name);
		}
	} while(FindNextConCommand(cvar, name, sizeof(name), isCommand, flags));
	
	return Plugin_Handled;
}  
