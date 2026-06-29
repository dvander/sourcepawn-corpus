#pragma semicolon 1

#include <sourcemod>
#include <basecomm>
#include <sdktools>

public Plugin:myinfo = {
	name		= "[ANY] Admin Conn",
	author		= "Dr. McKay",
	description	= "Allows admins to mute players",
	version		= "1.0.0",
	url			= "http://www.doctormckay.com"
};

new bool:g_IsInConn;

public OnPluginStart() {
	RegAdminCmd("sm_conn", Command_Conn, ADMFLAG_SLAY);
	RegAdminCmd("sm_deconn", Command_DeConn, ADMFLAG_SLAY);
}

public OnClientPostAdminCheck(client) {
	if(g_IsInConn && !IsFakeClient(client) && !CheckCommandAccess(client, "sm_conn", ADMFLAG_SLAY)) {
		SetClientListeningFlags(client, VOICE_MUTED);
	}
}

public Action:Command_Conn(client, args) {
	if(g_IsInConn) {
		ReplyToCommand(client, "\x04[SM] \x01Admin conn is already enabled.");
		return Plugin_Handled;
	}
	
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i) || CheckCommandAccess(i, "sm_conn", ADMFLAG_SLAY)) {
			continue;
		}
		
		SetClientListeningFlags(i, VOICE_MUTED);
	}
	
	g_IsInConn = true;
	ShowActivity2(client, "\x04[SM] \x03", "\x01Enabled admin conn");
	LogAction(client, -1, "%L enabled admin conn", client);
	return Plugin_Handled;
}

public Action:Command_DeConn(client, args) {
	if(!g_IsInConn) {
		ReplyToCommand(client, "\x04[SM] \x01Admin conn is not enabled.");
		return Plugin_Handled;
	}
	
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i) || BaseComm_IsClientMuted(i)) {
			continue;
		}
		
		SetClientListeningFlags(i, VOICE_NORMAL);
	}
	
	g_IsInConn = false;
	ShowActivity2(client, "\x04[SM] \x03", "\x01Disabled admin conn");
	LogAction(client, -1, "%L disabled admin conn", client);
	return Plugin_Handled;
}