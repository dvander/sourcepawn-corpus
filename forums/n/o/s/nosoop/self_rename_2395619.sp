#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define PLUGIN_VERSION "0.0.0"
public Plugin myinfo = {
    name = "[ANY] Change Name",
    author = "nosoop",
    description = "Basically a client command wrapper for SetClientName",
    version = PLUGIN_VERSION,
    url = "https://github.com/nosoop/sm-plugins"
}

public void OnPluginStart() {
	RegConsoleCmd("sm_changename", ConCmd_ChangeName);
}

public Action ConCmd_ChangeName(int client, int argc) {
	char name[MAX_NAME_LENGTH];
	GetCmdArgString(name, sizeof(name));
	StripQuotes(name);
	
	if (strlen(name) > 0) {
		SetClientName(client, name);
	}
	
	return Plugin_Handled;
}
