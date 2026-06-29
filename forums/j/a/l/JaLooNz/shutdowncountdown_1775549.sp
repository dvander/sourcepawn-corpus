#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#tryinclude <updater>

#define UPDATE_URL    "http://sm.doctormckay.com/shutdowncountdown.txt"
#define PLUGIN_VERSION "1.7.0"

new shutdownCountdown;
new shutdownTime;
new currentTime;
new String:tag[20];
new String:messageBeginning[100];
new String:messageEnd[100];
new Handle:shutdownCounter = INVALID_HANDLE;
new Handle:notifyCvar = INVALID_HANDLE;
new Handle:tagCvar = INVALID_HANDLE;
new Handle:messageBeginningCvar = INVALID_HANDLE;
new Handle:messageEndCvar = INVALID_HANDLE;
new Handle:updaterCvar = INVALID_HANDLE;

public Plugin:myinfo = {
	name        = "[Any] Shutdown Countdown",
	author      = "Dr. McKay",
	description = "Lets an admin start a countdown to a server shutdown",
	version     = PLUGIN_VERSION,
	url         = "http://www.doctormckay.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	MarkNativeAsOptional("Updater_AddPlugin"); 
	return APLRes_Success;
} 

public OnPluginStart() {
	notifyCvar = CreateConVar("sm_shutdown_notify", "30", "The countdown will also be displayed in the center of the screen when it is below this many seconds.");
	tagCvar = CreateConVar("sm_shutdown_tag", "[SM]", "The tag that will be prepended to command replies");
	messageBeginningCvar = CreateConVar("sm_shutdown_beginning", "WARNING: The server will shut down in", "The beginning of the timer message");
	messageEndCvar = CreateConVar("sm_shutdown_end", "seconds.", "The end of the timer message");
	updaterCvar = CreateConVar("sm_shutdown_auto_update", "1", "Enables automatic updating (has no effect if Updater is not installed)");
	RegAdminCmd("sm_shutdown", Command_ShutdownCountdown, ADMFLAG_RCON, "Start a server shutdown countdown (in seconds)");
	RegAdminCmd("sm_shutdowntime", Command_ShutdownTime, ADMFLAG_RCON, "Start a server shutdown countdown (hhmm)");
	RegAdminCmd("sm_shutdown_confirm", Command_ConfirmShutdown, ADMFLAG_RCON, "Confirms a pending server shutdown countdown");
	RegAdminCmd("sm_shutdown_cancel", Command_CancelShutdown, ADMFLAG_RCON, "Cancels a pending server shutdown countdown");
	shutdownCountdown = 0;
	shutdownTime = 2400;
	GetConVarString(tagCvar, tag, sizeof(tag));
	GetConVarString(messageBeginningCvar, messageBeginning, sizeof(messageBeginning));
	GetConVarString(messageEndCvar, messageEnd, sizeof(messageEnd));
	HookConVarChange(tagCvar, CvarChanged);
	HookConVarChange(messageBeginningCvar, CvarChanged);
	HookConVarChange(messageEndCvar, CvarChanged);
}

public CvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	GetConVarString(tagCvar, tag, sizeof(tag));
	GetConVarString(messageBeginningCvar, messageBeginning, sizeof(messageBeginning));
	GetConVarString(messageEndCvar, messageEnd, sizeof(messageEnd));
}

public OnAllPluginsLoaded() {
	if(LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
		new String:newVersion[10];
		Format(newVersion, sizeof(newVersion), "%sA", PLUGIN_VERSION);
		CreateConVar("sm_shutdown_version", newVersion, "Shutdown Countdown Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	} else {
		CreateConVar("sm_shutdown_version", PLUGIN_VERSION, "Shutdown Countdown Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);	
	}
}

public Action:Command_ShutdownCountdown(client, args) {
	if(shutdownCounter != INVALID_HANDLE) {
		ReplyToCommand(client, "%s A shutdown countdown is already in progress.", tag);
		return Plugin_Handled;
	}
	if(shutdownCountdown != 0) {
		ReplyToCommand(client, "%s A shutdown countdown is already pending. Use sm_shutdown_confirm or sm_shutdown_cancel", tag);
		return Plugin_Handled;
	}
	if(args != 1) {
		ReplyToCommand(client, "%s Usage: sm_shutdown [time(secs)]", tag);
		return Plugin_Handled;
	}
	decl String:time[10];
	GetCmdArg(1, time, sizeof(time));
	if(!StringToIntEx(time, shutdownCountdown)) {
		ReplyToCommand(client, "%s Usage: sm_shutdown [time(secs)]", tag);
		return Plugin_Handled;
	}
	if(shutdownCountdown < 5) {
		ReplyToCommand(client, "%s The shutdown time must be greater than or equal to 5.", tag);
		return Plugin_Handled;
	}
	shutdownTime = 2400;
	ReplyToCommand(client, "%s You requested a shutdown countdown for %i seconds. sm_shutdown_confirm = confirm, sm_shutdown_cancel = cancel.", tag, shutdownCountdown);
	LogAction(client, -1, "%L requested a server shutdown for %i seconds.", client, shutdownCountdown);
	return Plugin_Handled;
}

public Action:Command_ShutdownTime(client, args) {
	if(shutdownCounter != INVALID_HANDLE) {
		ReplyToCommand(client, "%s A shutdown countdown is already in progress.", tag);
		return Plugin_Handled;
	}
	if(shutdownCountdown != 0) {
		ReplyToCommand(client, "%s A shutdown countdown is already pending. Use sm_shutdown_confirm or sm_shutdown_cancel", tag);
		return Plugin_Handled;
	}
	if(args != 1) {
		ReplyToCommand(client, "%s Usage: sm_shutdowntime [hhmm]", tag);
		return Plugin_Handled;
	}
	decl String:time[10];
	GetCmdArg(1, time, sizeof(time));
	if(StringToIntEx(time, shutdownTime)>4 || (shutdownTime>=2400 || shutdownTime%100>=60)) {
		ReplyToCommand(client, "%s Usage: sm_shutdowntime [hhmm]", tag);
		return Plugin_Handled;
	}
	shutdownCountdown = 0;
	
	ReplyToCommand(client, "%s You requested a shutdown countdown at %i. sm_shutdown_confirm = confirm, sm_shutdown_cancel = cancel.", tag, shutdownTime);
	LogAction(client, -1, "%L requested a server shutdown at %i.", client, shutdownTime);
	return Plugin_Handled;
}

public Action:Command_ConfirmShutdown(client, args) {
	if(shutdownCountdown == 0 && (shutdownTime >= 2400 || shutdownTime % 100 >= 60)) {
		ReplyToCommand(client, "%s You have not requested a shutdown countdown with sm_shutdown yet.", tag);
		return Plugin_Handled;
	}
	if(shutdownCounter != INVALID_HANDLE) {
		ReplyToCommand(client, "%s There is already a shutdown countdown running. Use sm_shutdown_cancel to cancel.", tag);
		return Plugin_Handled;
	}
	if(shutdownTime <2400 && shutdownTime % 100 < 60) {
		decl String:currenttimeStr[8];
		FormatTime(currenttimeStr, sizeof(currenttimeStr), "%H%M%S");
		StringToIntEx(currenttimeStr, currentTime);
		currentTime = (currentTime / 10000 * 3600) + (currentTime % 10000 / 100 * 60) + (currentTime % 100);
		shutdownTime = ((shutdownTime / 100 * 60) + (shutdownTime % 100)) * 60;
		shutdownCountdown = shutdownTime > currentTime ? shutdownTime - currentTime : 86400 - (currentTime - shutdownTime);
	}
	shutdownCounter = CreateTimer(1.0, Timer_Countdown, INVALID_HANDLE, TIMER_REPEAT);
	ReplyToCommand(client, "%s The timer has been started. Use sm_shutdown_cancel to cancel.", tag);
	LogAction(client, -1, "%L confirmed a server shutdown for %i seconds.", client, shutdownCountdown);
	return Plugin_Handled;
}

public Action:Command_CancelShutdown(client, args) {
	if(shutdownCountdown == 0 && (shutdownTime >= 2400 || shutdownTime % 100 >= 60)) {
		ReplyToCommand(client, "%s You have not requested a shutdown countdown with sm_countdown yet.", tag);
		return Plugin_Handled;
	}
	if(shutdownCounter != INVALID_HANDLE) {
		KillTimer(shutdownCounter);
		PrintHintTextToAll("The shutdown has been cancelled.");
	}
	ReplyToCommand(client, "%s The shutdown request has been cancelled.", tag);
	if(shutdownCountdown <= GetConVarFloat(notifyCvar) && shutdownCounter != INVALID_HANDLE) {
		PrintCenterTextAll("The shutdown has been cancelled.");
	}
	shutdownCounter = INVALID_HANDLE;
	shutdownCountdown = 0;
	LogAction(client, -1, "%L cancelled a server shutdown.", client);
	return Plugin_Handled;
}	

public Action:Timer_Countdown(Handle:timer) {
	PrintHintTextToAll("%s %i %s", messageBeginning, shutdownCountdown, messageEnd);
	if(shutdownCountdown <= GetConVarFloat(notifyCvar)) {
		PrintCenterTextAll("%s %i %s", messageBeginning, shutdownCountdown, messageEnd);
		PrintToServer("%s %i %s", messageBeginning, shutdownCountdown, messageEnd);
	}
	shutdownCountdown--;
	if(shutdownCountdown <= -1) {
		LogAction(-1, -1, "Server shutting down...");
		KillTimer(shutdownCounter);
		ServerCommand("quit");
	}
}

public Action:Updater_OnPluginDownloading() {
	if(!GetConVarBool(updaterCvar)) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Updater_OnPluginUpdated() {
	ReloadPlugin();
}