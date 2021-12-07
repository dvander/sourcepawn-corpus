#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = {
	name        = "[ANY] Uptime",
	author      = "Dr. McKay",
	description = "Displays server uptime",
	version     = "1.0.0",
	url         = "http://www.doctormckay.com"
};

new bootTime;

public OnPluginStart() {
	RegAdminCmd("uptime", Command_Uptime, 0, "Displays server uptime");
	bootTime = GetTime();
}

public Action:Command_Uptime(client, args) {
	new diff = GetTime() - bootTime;
	new days = diff / 86400;
	diff %= 86400;
	new hours = diff / 3600;
	diff %= 3600;
	new mins = diff / 60;
	diff %= 60;
	new secs = diff;
	ReplyToCommand(client, "[SM] Server uptime: %i days, %i hours, %i mins, %i secs", days, hours, mins, secs);
	return Plugin_Handled;
}