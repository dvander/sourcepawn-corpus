#include <sourcemod>

#define PLUGIN_VERSION "1.4"

#define BU_WARNING_MSG "Do not use the unassigned team on this server. Thank you."

/* Enable the entire plugin */
new Handle:cvar_Enabled;

/* Enable the BLOCKING */
new Handle:cvar_Prevent;

/* In minutes */
new Handle:cvar_Ban_Time;

/* Available actions:
0 = Do nothing.
1 = Privately warn that user (similar to sm_psay)
2 = Publically warn that user (similar to sm_say)
3 = Kick that user
4 = sm_ban that user
5 = Force that user to join team SPECTATOR - sm_bu_prevent MUST be > 0
*/
new Handle:cvar_Action;

/* Should admins be alerted? */
new Handle:cvar_Admin_Chat_Warn;

/* How long before another alert, to prevent spam. */
new Handle:cvar_Alert_Delay;

/* This is so it does not flood warnings */
new Handle:AdminAlertTimers[MAXPLAYERS+1];
new Handle:OtherAlertTimers[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Block unassigned team",
	author = "=(eG)=TM Use My Teleporter",
	description = "Use My Teleporter's Block Unassigned Team Exploit",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnMapStart() {
	for (new i = 0; i <= MAXPLAYERS; i++) {
		AdminAlertTimers[i] = INVALID_HANDLE
		OtherAlertTimers[i] = INVALID_HANDLE
	}
}

public Action:Timer_BU_AdminAlert(Handle:timer, any:client) {
	AdminAlertTimers[client] = INVALID_HANDLE;
}

public Action:Timer_BU_OtherAlert(Handle:timer, any:client) {
	OtherAlertTimers[client] = INVALID_HANDLE;
}

public Action:Command_Jointeam(client, args) {
	if (GetConVarInt(cvar_Enabled) <= 0) {
		return Plugin_Continue;
	}
	new String:vall[32];
	GetCmdArg(1, vall, sizeof(vall));

	if (strcmp(vall, "red") == 0 || strcmp(vall, "blue") == 0 || strcmp(vall, "Spectator") == 0 || strcmp(vall, "spectate") == 0 ||
		strcmp(vall, "auto") == 0 || strcmp(vall, "spectatearena") == 0) {
		return Plugin_Continue;
	}
	else {
		if (GetConVarInt(cvar_Admin_Chat_Warn) > 0) {
			decl String:name[64];
			GetClientName(client, name, sizeof(name));
			decl String:alert[128];
			
			if (AdminAlertTimers[client] == INVALID_HANDLE) {
				Format(alert, sizeof(alert), "\x03%s\x01 is POSSIBLY attempting to use unassigned team exploit. Args: %s", name, vall);
				SendChatToAdmins("Exploit", alert);
				AdminAlertTimers[client] = CreateTimer(GetConVarFloat(cvar_Alert_Delay), Timer_BU_AdminAlert, client);
			}
		}
		if (GetConVarInt(cvar_Action) > 0)
			DoClientSentence(client);
		if (GetConVarInt(cvar_Prevent) <= 0)
			return Plugin_Continue;
		else
			return Plugin_Handled;
	}
}

public DoClientSentence(client) {
	new sentence = GetConVarInt(cvar_Action);
	decl String:name[64];
	GetClientName(client, name, sizeof(name));
		
	// PRIVATELY WARN
	if (sentence == 1) {
		PrintToChat(client, "\x04(Warning to %s) \x01%s", name, BU_WARNING_MSG);
	} else if (sentence == 2) {
		if (OtherAlertTimers[client] == INVALID_HANDLE) {
			OtherAlertTimers[client] = CreateTimer(GetConVarFloat(cvar_Alert_Delay), Timer_BU_OtherAlert, client);
			SendWarningChatToAll(name, BU_WARNING_MSG);
		}
	} else if (sentence == 3) {
		KickClient(client, BU_WARNING_MSG);
	} else if (sentence == 4) {
		ServerCommand("sm_ban #%d %d \"%s\"", GetClientUserId(client), GetConVarInt(cvar_Ban_Time), BU_WARNING_MSG);
	} else if (sentence == 5 && GetConVarInt(cvar_Prevent) > 0) {
		ChangeClientTeam(client, 1);
		PrintToChat(client, "\x04(Warning to %s) \x01%s \x03- Moved to spectator.", name, BU_WARNING_MSG);
	}
	else {
		// Do nothing
	}
}

public OnPluginStart() {
	CreateConVar("sm_bu_version", PLUGIN_VERSION, "Block unassigned team version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cvar_Enabled = CreateConVar("sm_bu_enabled", "1", "Enable this entire plugin");
	cvar_Prevent = CreateConVar("sm_bu_prevent", "1", "Prevent users from exploiting");
	
	cvar_Alert_Delay = CreateConVar("sm_bu_alert_delay", "15.0", "No warnings for X seconds");
	cvar_Ban_Time = CreateConVar("sm_bu_ban_time", "1440", "If action is at 4, ban for X minutes");
	cvar_Action = CreateConVar("sm_bu_action", "0", "Action to take on that user. Default: Nothing.");
	cvar_Admin_Chat_Warn = CreateConVar("sm_bu_admin_chat_warn", "1", "Alert in admin chat who may be attempting the exploit.");

	RegConsoleCmd("jointeam", Command_Jointeam, "Jointeam");
}

// Ripped from basechat.sp
SendChatToAdmins(String:name[], String:message[])
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT))
			{
				PrintToChat(i, "\x04(ADMINS) %s: \x01%s", name, message);
			}
		}	
	}
}

// Slightly modded
SendWarningChatToAll(String:name[], String:message[])
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}

		PrintToChat(i, "\x04(ALL) Warning: \x03%s - \x01%s", name, message);
	}
}