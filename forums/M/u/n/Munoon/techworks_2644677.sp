#pragma semicolon 1
#include <sourcemod>

ConVar adminImunity;
ConVar messageAboutKick;
ConVar changeServerName;
ConVar serverName;
ConVar serverNameNoTime;
ConVar hostname;
ConVar whenKick;
new String:message[128];
new String:serverNameStr[128];
new String:serverNameNoTimeStr[128];
char defaultServerName[128];
bool isWork = false, doPlayerJoin = false, doPlayerConnect = false;

public Plugin:myinfo =
{
	name = "Tech Works Plugin",
	author = "Munoon",
	description = "Plugin that provide close server for tech works",
	version = "1.0",
	url = "www.Train4Game.com"
};

public OnPluginStart() {
	RegAdminCmd("sm_techworks", CMD_COMMAND, ADMFLAG_GENERIC, "Command to start tech works");
	adminImunity = CreateConVar("sm_techworks_im", "1", "Adimins immunity: 1 - Enable, 0 - Disable");
	whenKick = CreateConVar("sm_techworks_wk", "1", "Kick 1 - On client connect, 0 - On client join team");
	messageAboutKick = CreateConVar("sm_techworks_km", "Message about kick", "Message about kick");
	changeServerName = CreateConVar("sm_techworks_cn", "1", "Server name: 1 - To be changed, 0 - Not to be chnaged");
	serverName = CreateConVar("sm_techworks_sn", "[TECH WORKS] REMAIN %i MINS", "Server name while tech works active (req sm_techworks_cn 1)");
	serverNameNoTime = CreateConVar("sm_techworks_nt", "[TECH WORKS]", "Server name while tech works active and times up (req sm_techworks_cn 1)");
	AutoExecConfig(true, "techworks");
}

public OnConfigsExecuted() {
	GetConVarString(messageAboutKick, message, sizeof(message));
	GetConVarString(serverName, serverNameStr, sizeof(serverNameStr));
	GetConVarString(serverNameNoTime, serverNameNoTimeStr, sizeof(serverNameNoTimeStr));
	if (GetConVarInt(changeServerName) == 1) {
		hostname = FindConVar("hostname");
		hostname.GetString(defaultServerName, sizeof(defaultServerName));
	}
}

public Action CMD_COMMAND(int client, int args) {
	if (!isAdmin(client)) {
		PrintToConsole(client, "YOU ARE NOT ADMIN!");
		return;
	}
	if (isWork) {
		isWork = false;
		if (GetConVarInt(changeServerName) == 1) hostname.SetString(defaultServerName);
		PrintToConsole(client, "TECH WORKS END");
		return;
	} if (!isWork) {
		isWork = true;
		if (GetConVarInt(whenKick) == 1) doPlayerConnect = true;
		else {
			AddCommandListener(Command_JoinTeam, "jointeam");
			doPlayerJoin = true;
		}
		for (int i = 1; i <= MaxClients; i++) {
	        if(IsClientInGame(i) && !IsFakeClient(i)) {
	            if (GetConVarInt(adminImunity) == 1 && isAdmin(i)) break;
	            KickClient(i, "%s", message);
	        }
	    }
		if (args != 0 && GetConVarInt(changeServerName) == 1){
			char arg[64];
			GetCmdArg(1, arg, sizeof(arg));
			changeName(StringToInt(arg));
		}
		else changeName(0);
		PrintToConsole(client, "TECH WORKS START");
	}
}

public void OnClientPutInServer(int client) {
	if (doPlayerConnect) {
		if (GetConVarInt(adminImunity) == 1 && isWork) {
			if (IsClientConnected(client) && !IsFakeClient(client) && !isAdmin(client))
				KickClient(client, "%s", message);
		} else if (isWork) {
			if (IsClientConnected(client) && !IsFakeClient(client))
				KickClient(client, "%s", message);
		}
	}
}

public Action Command_JoinTeam(int client, const String:command[], int args) {
	if (!doPlayerJoin) return;
	if (GetConVarInt(adminImunity) == 1 && isWork) {
		if (IsClientConnected(client) && !IsFakeClient(client) && !isAdmin(client))
			KickClient(client, "%s", message);
	} else if (isWork) {
		if (IsClientConnected(client) && !IsFakeClient(client))
			KickClient(client, "%s", message);
	}
}

public void changeName(int minutes) {
	if (isWork && GetConVarInt(changeServerName) == 1) {
		if (minutes == 0) hostname.SetString(serverNameNoTimeStr);
		else {
			char nameToChange[128];
			FormatEx(nameToChange, sizeof(nameToChange), serverNameStr, minutes);
			hostname.SetString(nameToChange);
			CreateTimer(60.0, timer, minutes - 1, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action timer(Handle hTimer, any minutes) {
    if (minutes == 0) {
		hostname.SetString(serverNameNoTimeStr);
		return;
	}
	if (!isWork) return;
    int localMin = minutes - 1;
    if (minutes == 1) localMin = minutes; 
    
	char nameToChange[128];
	FormatEx(nameToChange, sizeof(nameToChange), serverNameStr, localMin);
	hostname.SetString(nameToChange);

    CreateTimer(60.0, timer, localMin, TIMER_FLAG_NO_MAPCHANGE);
}

public bool isAdmin(client) {
    if (client == 0) return true;
    if (GetUserFlagBits(client) & ADMFLAG_RESERVATION) 
		return true;
    return false;
}