#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = {
	name = "HUD Text Tester",
	author = "Dr. McKay",
	description = "Used to find the position for HUD text",
	version = "1.0.0",
	url = "http://www.doctormckay.com"
}

new Handle:hudText = INVALID_HANDLE;

public OnPluginStart() {
	RegConsoleCmd("sm_hudtest", Command_HudTest, "Usage: sm_hudtest <x> <y>");
	hudText = CreateHudSynchronizer();
}

public Action:Command_HudTest(client, args) {
	if(args != 2) {
		ReplyToCommand(client, "[SM] Usage: sm_hudtest <x> <y>");
		return Plugin_Handled;
	}
	new String:arg1[255], String:arg2[255];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new Float:x = StringToFloat(arg1);
	new Float:y = StringToFloat(arg2);
	SetHudTextParams(x, y, 5.0, 0, 255, 0, 255);
	ShowSyncHudText(client, hudText, "This is your HUD text");
	return Plugin_Handled;
}
