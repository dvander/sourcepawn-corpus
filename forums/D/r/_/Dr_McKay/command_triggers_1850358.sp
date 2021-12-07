#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION		"1.0.0"

public Plugin:myinfo = {
	name		= "[ANY] Command Trigger",
	description	= "Allows you to define chat commands that run client or server commands",
	author		= "Dr. McKay",
	version		= PLUGIN_VERSION,
	url			= "http://www.doctormckay.com"
};

new Handle:kv;

public OnPluginStart() {
	decl String:path[512];
	BuildPath(Path_SM, path, sizeof(path), "configs/commandtriggers.cfg");
	kv = CreateKeyValues("Command_Triggers");
	if(!FileToKeyValues(kv, path)) {
		SetFailState("commandtriggers.cfg file missing");
	}
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
}

public Action:Command_Say(client, const String:command[], argc) {
	decl String:message[512];
	GetCmdArgString(message, sizeof(message));
	TrimString(message);
	StripQuotes(message);
	KvRewind(kv);
	if(!KvJumpToKey(kv, message)) {
		return Plugin_Continue;
	}
	decl String:command[512], String:type[32];
	KvGetString(kv, "command", command, sizeof(command));
	if(strlen(command) == 0) {
		LogError("Missing command for chat command %s", message);
		return Plugin_Continue;
	}
	KvGetString(kv, "type", type, sizeof(type));
	if(!StrEqual(type, "client") && !StrEqual(type, "server")) {
		LogError("Invalid type '%s' for chat command %s", type, message);
		return Plugin_Continue;
	}
	decl String:replace[64];
	IntToString(GetClientUserId(client), replace, sizeof(replace));
	ReplaceString(command, sizeof(command), "{USERID}", replace);
	GetClientName(client, replace, sizeof(replace));
	ReplaceString(command, sizeof(command), "{NAME}", replace);
	if(StrEqual(type, "client")) {
		FakeClientCommand(client, command);
	} else {
		ServerCommand(command);
	}
	if(KvGetNum(kv, "hidden") != 0) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}