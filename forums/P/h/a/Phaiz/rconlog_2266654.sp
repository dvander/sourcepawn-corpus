#pragma semicolon 1

#include <sourcemod>
#include <smrcon>

#pragma newdecls required

public Plugin myinfo = {
	name		= "[ANY] Failed Rcon Logger",
	author		= "Dr. McKay",
	description	= "Logs failed rcon auths",
	version		= "1.0.0",
	url			= "http://www.doctormckay.com"
};

ConVar rcon_password;

public void OnPluginStart() {
	rcon_password = FindConVar("rcon_password");
}

public Action SMRCon_OnAuth(int rconId, const char[] address, const char[] password, bool &allow) {
	char realPassword[128];
	rcon_password.GetString(realPassword, sizeof(realPassword));
	
	if(!StrEqual(realPassword, password)) {
		char path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, path, sizeof(path), "logs/rcon_failures.log");
		LogToFile(path, "failed auth from address \"%s\", attempted password \"%s\"", address, password);
	}
}