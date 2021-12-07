#include <sourcemod>

public Plugin myinfo = {
	name = "Firstperson Blocker",
	author = "Statistician",
	description = "Simply blocks the firstperson command",
	version = "1.0",
	url = ""
};

public void OnPluginStart() {
    AddCommandListener(Cmd_Firstperson, "firstperson"); // hook a listener to the command
}

public Action Cmd_Firstperson(int client, const char[] cmd, int argc) {
    return Plugin_Handled;
}