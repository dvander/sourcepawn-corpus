#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "Temporary blockbuilder Access",
	author      = "Asher \"asherkin\" Baker",
	description = "Provides commands to manage temporary blockbuilder access",
	version     = "0.1.0",
	url         = "https://limetech.org/"
};

int g_HasTempAccess[MAXPLAYERS+1];
int g_TempAccessFlags = ADMFLAG_CUSTOM1;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_givebb", SetOAccess, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_removebb", RemoveOAccess, ADMFLAG_CUSTOM2);
	
	int flags;
	if (GetCommandOverride("temp_donor_access", Override_Command, flags)) {
		g_TempAccessFlags = flags;
	}
}

public void OnClientDisconnect(int client)
{
	g_HasTempAccess[client] = false;
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	int flags;
	
	switch (part) {
		case AdminCache_Overrides:
			if (GetCommandOverride("temp_donor_access", Override_Command, flags)) {
				g_TempAccessFlags = flags;
				
				// Rebuild admins with the new flag.
				DumpAdminCache(AdminCache_Admins, true);
			}
		case AdminCache_Admins:
			for (int i = 1; i <= MaxClients; ++i) {
				if (g_HasTempAccess[i]) {
					SetUserFlagBits(i, GetUserFlagBits(i) | g_TempAccessFlags);
				}
			}
	}
}

public Action SetOAccess(int client, int args)
{
	if (args < 1) {
		ReplyToCommand(client, "Usage: sm_givebb <target>");
		return Plugin_Handled;
	}
	
	char targetString[256];
	GetCmdArg(1, targetString, sizeof(targetString));
	
	int target = FindTarget(client, targetString, true, true);
	if (target == -1) {
		return Plugin_Handled;
	}
	
	if (g_HasTempAccess[target] || CheckCommandAccess(target, "temp_donor_access", g_TempAccessFlags, true)) {
		ReplyToCommand(client, "%N already has %s blockbuilder access.", target, g_HasTempAccess[target] ? "temporary" : "regular");
		return Plugin_Handled;
	}
	
	g_HasTempAccess[target] = true;
	SetUserFlagBits(target, GetUserFlagBits(target) | g_TempAccessFlags);
	
	LogAction(client, target, "\"%L\" granted temporary blockbuilder access to \"%L\"", client, target);
	ShowActivity2(client, "[SM]", "Granted temporary blockbuilder access to %N", target);
	
	return Plugin_Handled;
}

public Action RemoveOAccess(int client, int args)
{
	if (args < 1) {
		ReplyToCommand(client, "Usage: sm_removebb <target> [force]");
		return Plugin_Handled;
	}
	
	char targetString[256];
	GetCmdArg(1, targetString, sizeof(targetString));
	
	int target = FindTarget(client, targetString, true, true);
	if (target == -1) {
		return Plugin_Handled;
	}
	
	bool force = false;
	if (args >= 2) {
		char forceString[8];
		GetCmdArg(2, forceString, sizeof(forceString));
		
		if (forceString[0] == '"') {
			force = (forceString[1] == '1') || (forceString[1] == 't') || (forceString[1] == 'T') || (forceString[1] == 'f') || (forceString[1] == 'F');
		} else {
			force = (forceString[0] == '1') || (forceString[0] == 't') || (forceString[0] == 'T') || (forceString[0] == 'f') || (forceString[0] == 'F');
		}
	}
	
	if (!CheckCommandAccess(target, "temp_donor_access", g_TempAccessFlags, true)) {
		ReplyToCommand(client, "%N does not have blockbuilder access.", target);
		return Plugin_Handled;
	}
	
	if (!g_HasTempAccess[target] && !force) {
		ReplyToCommand(client, "%N does not have temporary blockbuilder access. Add 'force' to remove access anyway.", target);
		return Plugin_Handled;
	}
	
	g_HasTempAccess[target] = false;
	SetUserFlagBits(target, GetUserFlagBits(target) & ~g_TempAccessFlags);
	
	LogAction(client, target, "\"%L\" removed temporary blockbuilder access from \"%L\"", client, target);
	ShowActivity2(client, "[SM]", "removed temporary blockbuilder access from %N", target);
	
	return Plugin_Handled;
}