#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "P4UL"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <clientprefs>

#pragma newdecls required

Handle g_hLeaveCookie;

public Plugin myinfo = 
{
	name = "Admin Leave Message",
	author = PLUGIN_AUTHOR,
	description = "Admin leave message",
	version = PLUGIN_VERSION,
	url = "zu-gaming.eu"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_leavemsg", CMD_Leave, ADMFLAG_GENERIC, "Enable or disable admin leave message");
	
	g_hLeaveCookie = RegClientCookie("Leave_Message", "A cookie for enabling/disabling leave message", CookieAccess_Private);
}

public void OnClientDisconnect(int client) {
	
	char sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName));
	
	char sLeaveCookie[4];
	GetClientCookie(client, g_hLeaveCookie, sLeaveCookie, sizeof(sLeaveCookie));

	if (CheckCommandAccess(client, "sm_isAdmin", ADMFLAG_GENERIC, true) && !StrEqual(sLeaveCookie, "0")) {
		CPrintToChatAll("[{darkred}Server{default}] {darkred}%s has left the server.", sName);
	}
}

public Action CMD_Leave(int client, int args) {
	
	int target;
	if (args > 0) {
		char arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		target = FindTarget(client, arg);
	} else {
		target = client;
	}
	
	char sLeaveCookie[4];
	GetClientCookie(client, g_hLeaveCookie, sLeaveCookie, sizeof(sLeaveCookie));
	
	if (StrEqual(sLeaveCookie, "0")) {
		SetClientCookie(target, g_hLeaveCookie, "1");
		CPrintToChat(client, "[{darkred}Leave Message{default}] {darkred}Leave message enabled.");
	} else {
		SetClientCookie(target, g_hLeaveCookie, "0");
		CPrintToChat(client, "[{darkred}Leave Message{default}] {darkred}Leave message disabled.");
	}
	
	return Plugin_Handled;
}