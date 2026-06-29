#pragma semicolon 1

#define PLUGIN_AUTHOR "Frederikk"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Team Change Detect",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

#define URL "http://example.com"
#define TITLE "Title"

public void OnPluginStart() {
	AddCommandListener(TeamJoin, "jointeam");
}

public Action TeamJoin(int client, const char[] command, int argc) {
	ShowMOTDPanel(client, TITLE, URL, MOTDPANEL_TYPE_URL);
}
