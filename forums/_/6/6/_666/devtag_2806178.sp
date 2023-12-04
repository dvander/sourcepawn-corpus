#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int		g_iPlayerResource = -1;

bool	g_bLateLoad,
		ga_bDevTag[MAXPLAYERS + 1] = {true, ...},
		ga_bIsAdmin[MAXPLAYERS + 1] = {false, ...},
		g_bHooked = false;

public Plugin myinfo = {
	name		= "devtag",
	author		= "Nullifidian",
	description	= "Enable ins dev tag",
	version		= "1.0",
	url			= ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() {
	RegAdminCmd("sm_devtag", cmd_devtag, ADMFLAG_KICK, "Toggle your dev tag");
}

public void OnMapStart() {
	g_iPlayerResource = GetPlayerResourceEntity();
	if (g_iPlayerResource == -1) {
		SetFailState("\"GetPlayerResourceEntity()\" not found!");
	}

	if (g_bLateLoad) {
		g_bLateLoad = false;
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i)) {
				continue;
			}
			ga_bIsAdmin[i] = CheckCommandAccess(i, "adminaccesscheckKick", ADMFLAG_KICK);
			if (!g_bHooked && ga_bIsAdmin[i]) {
				SDKHook(g_iPlayerResource, SDKHook_ThinkPost, Hook_ThinkPost);
				g_bHooked = true;
			}
		}
	}
}

public void OnMapEnd() {
	g_bHooked = false;
}

public void OnClientPostAdminCheck(int client) {
	if (client && !IsFakeClient(client)) {
		ga_bIsAdmin[client] = CheckCommandAccess(client, "adminaccesscheckKick", ADMFLAG_KICK);
		if (!g_bHooked && ga_bIsAdmin[client]) {
			SDKHook(g_iPlayerResource, SDKHook_ThinkPost, Hook_ThinkPost);
			g_bHooked = true;
		}
	}
}

public void OnClientDisconnect(int client) {
	if (client && ga_bIsAdmin[client]) {
		ga_bIsAdmin[client] = false;
		ga_bDevTag[client] = true;
	}
}

public void Hook_ThinkPost(int entity) {
	bool bChanged = false;
	for (int i = 1; i <= MaxClients; i++) {
		if (!ga_bIsAdmin[i] || !ga_bDevTag[i] || !IsClientInGame(i)) {
			continue;
		}
		SetEntProp(g_iPlayerResource, Prop_Send, "m_bDeveloper", true, _, i);
		bChanged = true;
	}
	if (bChanged) {
		ChangeEdictState(entity);
	} else {
		SDKUnhook(g_iPlayerResource, SDKHook_ThinkPost, Hook_ThinkPost);
		g_bHooked = false;
	}
}

public Action cmd_devtag(int client, int args) {
	if (!client) {
		return Plugin_Handled;
	}
	if (!ga_bDevTag[client]) {
		ga_bDevTag[client] = true;
		if (!g_bHooked) {
			SDKHook(g_iPlayerResource, SDKHook_ThinkPost, Hook_ThinkPost);
			g_bHooked = true;
		}
		ReplyToCommand(client, "DevTag: ON");
	} else {
		ga_bDevTag[client] = false;
		ReplyToCommand(client, "DevTag: OFF");
	}
	return Plugin_Handled;
}