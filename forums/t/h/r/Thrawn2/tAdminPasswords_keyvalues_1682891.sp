#pragma semicolon 1
#include <sourcemod>
#include <tadminpasswords>

#define VERSION 		"0.0.1"


public Plugin:myinfo = {
	name 		= "tAdminPasswords - KeyValues",
	author 		= "Thrawn",
	description = "Configure server passwords via keyvalues",
	version 	= VERSION,
};


public OnPluginStart() {
	CreateConVar("sm_tadminpasswords_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public SVP_OnRefillRequest() {
	RegisterPasswords();
}

public OnAllPluginsLoaded() {
	RegisterPasswords();
}

public RegisterPasswords() {
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/admin_passwords.cfg");

	if(!FileExists(sPath)) {
		SetFailState("%s does not exist.", sPath);
		return;
	}

	new Handle:hKVPasswords = CreateKeyValues("Passwords");
	if(!FileToKeyValues(hKVPasswords, sPath)) {
		SetFailState("Could not read: %s", sPath);
		return;
	}

	if (!KvGotoFirstSubKey(hKVPasswords))
		return;

	do {
		KvReadPasswordsBlock(hKVPasswords);
	} while (KvGotoNextKey(hKVPasswords));

	CloseHandle(hKVPasswords);

	/* The following is only needed for asynchronous password storages
	// so we can safely skip this here
	// -------------------------------*/
	// SVP_ReapplyPasswords();
}


KvReadPasswordsBlock(Handle:hKVPasswords) {
	new String:sPassword[128];
	new String:sGroups[255];
	new String:sFlags[255];
	new iImmunity;

	if(KvGetNum(hKVPasswords, "enabled", 1) == 1) {
		KvGetSectionName(hKVPasswords, sPassword, sizeof(sPassword));
		KvGetString(hKVPasswords, "groups", sGroups, sizeof(sGroups), "");
		KvGetString(hKVPasswords, "flags", sFlags, sizeof(sFlags), "");
		iImmunity = KvGetNum(hKVPasswords, "immunity", -1);

		SVP_AddPassword(sPassword, sGroups, sFlags, iImmunity);
	}
}