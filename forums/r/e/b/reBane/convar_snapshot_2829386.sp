#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "24w43a"

public Plugin myinfo = {
	name = "ConVar Snapshot",
	author = "reBane",
	description = "Temporarily edit convars and revert changes",
	version = PLUGIN_VERSION,
	url = "N/A"
};
void SetupVersionConVar(const char[] cvar_name, const char[] cvar_desc)
{
	ConVar version = CreateConVar(cvar_name, PLUGIN_VERSION, cvar_desc, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	version.AddChangeHook(LockVersionConVar);
	version.SetString(PLUGIN_VERSION);
}
void LockVersionConVar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!StrEqual(newValue, PLUGIN_VERSION)) {
		convar.SetString(PLUGIN_VERSION);
	}
}

StringMap changes;

bool mapChanging = false;
bool snapshotActive = false;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.basecommands");
	AddCommandListener(OnCVarCommand, "sm_cvar");
	SetupVersionConVar("sm_cvarsnap_version", "ConVar Snapshot Version");
	changes = new StringMap();
}

public void OnMapStart()
{
	mapChanging = false;
}

public void OnMapEnd()
{
	RestoreSnapshot(-1);
	mapChanging = true;
	snapshotActive = false;
}

Action OnCVarCommand(int client, const char[] command, int argc)
{
	if (client > 0 && (!IsClientInGame(client) || !CheckCommandAccess(client, "sm_cvar", ADMFLAG_CONVARS)))
		return Plugin_Handled;

	if (argc < 1) {
		ReplyToCommand(client, "[SM] Usage: sm_cvar <cvar|snap> [value]");
		return Plugin_Handled;
	}

	char cvar[128];
	char newValue[256];
	GetCmdArg(1, cvar, sizeof(cvar));

	if (argc == 1) {
		if (StrEqual(cvar, "snap")) {
			ReplyToCommand(client, "[SM] Usage: sm_cvar <snap> <begin|commit|restore|show|end>");
			return Plugin_Handled;
		} else
			return Plugin_Continue; // original command can display value
	} else if (argc > 2) {
		ReplyToCommand(client, "[SM] Please quote the convar and value");
		return Plugin_Handled;
	} else if (StrEqual(cvar, "protect")) {
		return Plugin_Continue;
	}

	GetCmdArg(2, newValue, sizeof(newValue));

	if (StrEqual(cvar, "snap")) {
		SnapAction(client, newValue);
		return Plugin_Handled;
	} else if (snapshotActive) {
		ChangeCVarPre(client, cvar, newValue);
		//need to let the original command run to determine protection
	}
	return Plugin_Continue;
}

void SnapAction(int client, const char[] action) {
	if (StrEqual(action, "begin") || StrEqual(action, "start")) {
		if (snapshotActive) {
			ReplyToCommand(client, "[SM] ConVar Snapshot already active!");
		} else {
			snapshotActive = true;
			ReplyToCommand(client, "[SM] ConVar Snapshot activated - Changes need to be committed to persist map changes!");
			LogAction(client, -1, "[SM] \"%L\" started ConVar Snapshot mode", client);
		}
	} else if (!snapshotActive) {
		ReplyToCommand(client, "[SM] ConVar Snapshot not currently active!");
	} else if (StrEqual(action, "end") || StrEqual(action, "stop")) {
		if (changes.Size > 0) {
			ReplyToCommand(client, "[SM] Can't end snapshot mode, %d changes active! Use commit or restore first", changes.Size);
		} else {
			snapshotActive = false;
			ReplyToCommand(client, "[SM] ConVar Snapshot deactivated!");
			LogAction(client, -1, "[SM] \"%L\" ended ConVar Snapshot mode", client);
		}
	} else if (StrEqual(action, "commit")||StrEqual(action, "apply")) {
		changes.Clear();
		ReplyToCommand(client, "[SM] Committed ConVar Snapshot! (Changes will now persist)");
		LogAction(client, -1, "[SM] \"%L\" committed the ConVar Snapshot", client);
	} else if (StrEqual(action, "restore") || StrEqual(action, "drop")) {
		RestoreSnapshot(client);
		ReplyToCommand(client, "[SM] ConVar Snapshot rolled back!");
		LogAction(client, -1, "[SM] \"%L\" rolled back the ConVar Snapshot", client);
	} else if (StrEqual(action, "show") || StrEqual(action, "list")) {
		DumpSnapshot(client);
		if (client && GetCmdReplySource() == SM_REPLY_TO_CHAT) {
			ReplyToCommand(client, "[SM] Check console!");
		}
	} else {
		ReplyToCommand(client, "[SM] Unknown ConVar Snapshot command. Expected begin|commit|restore|show|end");
	}
}

void ChangeCVarPre(int client, const char[] cvarname, const char[] newValue) {
	ConVar hndl = FindConVar(cvarname);
	if (hndl == null) {
		ReplyToCommand(client, "[SM] %t", "Unable to find cvar", cvarname);
		return;
	}

	// The server passes the values of these directly into ServerCommand, following exec. Sanitize.
	if (StrEqual(cvarname, "servercfgfile", false) || StrEqual(cvarname, "lservercfgfile", false)) {
		int pos = StrContains(newValue, ";", true);
		if (pos != -1) {
			newValue[pos] = '\0';
		}
	}

	char currentValue[256];
	hndl.GetString(currentValue, sizeof(currentValue));

	if (StrEqual(currentValue, newValue)) {
		return; // no change
	}

	DataPack data = new DataPack();
	int userId;
	if (client) userId = GetClientUserId(client);
	else userId = -1;
	data.WriteCell(userId);
	data.WriteCell(hndl);
	data.WriteString(currentValue);
	data.WriteString(newValue);
	data.Reset();
	RequestFrame(ChangeCVarPost, data);
}

void ChangeCVarPost(DataPack data) {
	char preValue[256];
	char newValue[256];
	int userId = data.ReadCell();
	ConVar hndl = data.ReadCell();
	data.ReadString(preValue, sizeof(preValue));
	data.ReadString(newValue, sizeof(newValue));
	delete data;

	if (mapChanging) {
		return;
	}

	int client = 0;
	if (userId != -1) {
		client = GetClientOfUserId(userId);
		if (client == 0) {
			return; //DCed
		}
	}
	char currentValue[256];
	hndl.GetString(currentValue, sizeof(currentValue));
	if (!StrEqual(currentValue, newValue)) {
		return; // cvar was protected
	}

	char cvar[128];
	hndl.GetName(cvar, sizeof(cvar));

	char storedValue[256];
	bool existed = changes.GetString(cvar, storedValue, sizeof(storedValue));
	if (existed) {
		if (StrEqual(storedValue, newValue)) {
			changes.Remove(cvar);
			PrintToConsole(client, "[SM] Snapshot Restored: %s = \"%s\"", cvar, newValue);
			return;
		} else {
			PrintToConsole(client, "[SM] Snapshot Unchanged: %s = \"%s\" -|- \"%s\"", cvar, storedValue, newValue);
		}
	} else {
		changes.SetString(cvar, preValue);
		PrintToConsole(client, "[SM] Snapshot Added: %s <- \"%s\" -|- \"%s\"", cvar, preValue, newValue);
	}
}

void RestoreSnapshot(int admin) {
	StringMapSnapshot snap = changes.Snapshot();
	char key[128];
	char oldValue[256];
	for (int i; i<snap.Length; i++) {
		snap.GetKey(i, key, sizeof(key));
		changes.GetString(key, oldValue, sizeof(oldValue));

		ConVar cvar = FindConVar(key);
		if (cvar == INVALID_HANDLE) {
			if (admin >= 0) ReplyToCommand(admin, "[SM] The CVar %s has gone away!", key);
		} else {
			cvar.SetString(oldValue, true);
		}
	}
	delete snap;
	changes.Clear();
}

void DumpSnapshot(int client) {
	if (changes.Size == 0) {
		PrintToConsole(client, "[SM] ConVar Snapshot is currently empty - No changes recorded");
		return;
	}
	PrintToConsole(client, "[SM] ConVar Snapshot has %d changes recorded", changes.Size);

	StringMapSnapshot snap = changes.Snapshot();
	char key[128];
	char oldValue[256];
	char currentValue[256];
	for (int i; i<snap.Length; i++) {
		snap.GetKey(i, key, sizeof(key));
		changes.GetString(key, oldValue, sizeof(oldValue));

		ConVar cvar = FindConVar(key);
		if (cvar == INVALID_HANDLE) {
			PrintToConsole(client, "CVar %s : \"%s\" -> <DELETED CONVAR>", key, oldValue);
		} else {
			cvar.GetString(currentValue, sizeof(currentValue));
			PrintToConsole(client, "CVar %s : \"%s\" -> \"%s\"", key, oldValue, currentValue);
		}
	}
	delete snap;
}