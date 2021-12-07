#include <sourcemod>
#define PLUGIN_VERSION "2.1"
#pragma semicolon 1
new Handle:g_sedirector;
new Handle:shutdownTimer;
new shutdownTime;

// Plugin Info
public Plugin:myinfo =
{
    name = "seDirector",
    author = "Asher Software",
    description = "seDirector's SourceMod plugin to assist in updating servers automatically.",
    version = PLUGIN_VERSION,
   url = "http://ashersoftware.com"
};


public OnPluginStart()
{
	ServerCommand("sv_hibernate_when_empty 0");
	CreateConVar("sedirector_version", PLUGIN_VERSION, "seDirector version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_sedirector = CreateConVar("sedirector", "1", "0 = Disabled \n1 = Enabled",FCVAR_PLUGIN);
	RegAdminCmd("sedirector_forcecheck", Command_seDirectorForceCheck, ADMFLAG_RCON, "Forces a check for an update.");
	RegAdminCmd("sedirector_cancel", Command_seDirectorCancel, ADMFLAG_RCON, "Cancels the server shutdown. Server will start the countdown at the next map change.");

	LoadTranslations("seDirector.phrases");
	
}

public OnMapStart()
{
	CreateTimer(30.0, CheckForUpdate, _, TIMER_REPEAT);
}

public Action:CheckForUpdate(Handle:timer) {
	new value = GetConVarInt(g_sedirector);
	if (value == 0) {
		return Plugin_Continue;
	} else {
		if(FileExists("seDirector.update") == true) {
		
			LogMessage("Update detected.");
			shutdownTime = 60;
			shutdownTimer = CreateTimer(1.0, ShutItDown, _, TIMER_REPEAT);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action:Command_seDirectorForceCheck(client, args) {
	new value = GetConVarInt(g_sedirector);
	if (value == 0) {
		return Plugin_Continue;
	} else {
		if(FileExists("seDirector.update") == true) {
			ReplyToCommand(client, "%s", "Force update: detected.");
			LogMessage("Force update: detected.");
		} else {
			ReplyToCommand(client, "%s", "Force update: not detected.");
			LogMessage("Force update: not detected.");	
		}
	}
	return Plugin_Continue;
}

public Action:Command_seDirectorCancel(client, args) {
	if(shutdownTimer == INVALID_HANDLE) {
		ReplyToCommand(client, "%s","An update has not been detected. A countdown will commence when an update is detected.");
		return Plugin_Handled;
	}
	if(shutdownTimer != INVALID_HANDLE) {
		KillTimer(shutdownTimer);
		PrintHintTextToAll("%t", "messagehint_shutdowncancelled" ,shutdownTime);
		PrintCenterTextAll("%t", "messagecenter_shutdowncancelled" ,shutdownTime);
	}
	ReplyToCommand(client, "%s", "The shutdown has been cancelled.");
	shutdownTime = 0;
	shutdownTimer = INVALID_HANDLE;
	LogAction(client, -1, "%L cancelled a server shutdown.",client);
	return Plugin_Handled;
}

public ShutDownPrint() {
	PrintHintTextToAll("%t", "messagehint" ,shutdownTime);
}

public ShutDownFullPrint() {
	PrintToChatAll("%t", "messagechat" ,shutdownTime);
	PrintCenterTextAll("%t", "messagecenter" ,shutdownTime);	
	LogMessage("%i second shutdown reminder",shutdownTime);
}

public Action:ShutItDown(Handle:timer) {
	if(shutdownTime == 60) {
		ShutDownFullPrint();
		ShutDownPrint();
	} else if (shutdownTime == 50) {
		ShutDownPrint();
	} else if (shutdownTime == 40) {
		ShutDownPrint();
	} else if (shutdownTime == 30) {
		ShutDownFullPrint();
		ShutDownPrint();
	} else if (shutdownTime == 20) {
		ShutDownPrint();
	} else if (shutdownTime <= 10) {
		if(shutdownTime == 10) {
			ShutDownFullPrint();
		}
		ShutDownPrint();
	}
	
	shutdownTime--;
	if(shutdownTime <= -1) {
		KillTimer(shutdownTimer);
		DeleteFile("seDirector.update");
		LogMessage("Server shutdown.");
		ServerCommand("quit");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}