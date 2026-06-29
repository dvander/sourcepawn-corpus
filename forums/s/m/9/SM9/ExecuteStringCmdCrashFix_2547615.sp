#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_EXTENSIONS
#include <ptah>

#pragma newdecls required

char g_szLog[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "ExecuteStringCommand Crash Fix", 
	author = "SM9();, Kinsi, Headline", 
	description = "Prevents StringCommands being executed too early.", 
	version = "0.5", 
};

public void OnPluginStart() {
	
	if (LibraryExists("PTaH")) {
		PTaH(PTaH_ExecuteStringCommand, Hook, ExecuteStringCommand);
	}
	
	BuildPath(Path_SM, g_szLog, sizeof(g_szLog), "logs/ExecuteStringCommandFix.log");
	
	AddCommandListener(CommandListener_CallBack, "");
}

public Action CommandListener_CallBack(int iClient, const char[] szCommand, int iArgs) {
	return HandleCommand(iClient, szCommand);
}

public Action ExecuteStringCommand(int iEntity, char szMessage[512]) {
	return HandleCommand(iEntity, szMessage);
}

Action HandleCommand(int iEntity, const char[] szMessage)
{
	if (iEntity < 1 || iEntity > MaxClients) { // Not a client.
		return Plugin_Continue;
	}
	
	if (!IsClientInGame(iEntity)) { // Client is still connecting.
		LogToFileEx(g_szLog, "Blocked %L from running a string command (%s) before being ingame.", iEntity, szMessage);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
} 