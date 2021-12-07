#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "[Any] Entity Logger",
	description = "Log all entities for debugging issues.",
	author = "Tak (Chaosxk)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public OnPluginStart() {
	CreateConVar("sm_entitylogger_version", PLUGIN_VERSION, "Version of Entity Logger.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegServerCmd("sm_logentity", LogEntities, "Log all entities and save them in a config file.");
}

public Action:LogEntities(args) {
	if(args > 0) return Plugin_Continue;
	else {
		LoopEntities();
	}
	return Plugin_Handled;
}

LoopEntities() {
	new ent = -1;
	new counter = 0;
	while((ent = FindEntityByClassname(ent, "*")) != -1) {
		if(IsValidEntity(ent)) {
			decl String:classname[PLATFORM_MAX_PATH];
			GetEdictClassname(ent, classname, sizeof(classname));
			SaveToLog(classname);
			counter++;
		}
	}
	decl String:sCounter[PLATFORM_MAX_PATH];
	IntToString(counter, sCounter, sizeof(sCounter));
	SaveToLog(sCounter);
	PrintToServer("Entities have been logged to sourcemod/logs/entities.log");
	PrintToServer("Total Entities: %d", counter);
	PrintToServer("---------------------------------------------------------");
}

//taken from updater plugin
SaveToLog(const String:format[], any:...) {
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "logs/entities.log");
	LogToFileEx(path, "%s", format);
}