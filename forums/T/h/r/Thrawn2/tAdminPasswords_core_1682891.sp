#pragma semicolon 1
#include <sourcemod>
#include <connect>

#define VERSION 		"0.0.1"

new String:g_sPassword[255];

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled;

new Handle:g_hForwardRefillRequest = INVALID_HANDLE;

new Handle:g_hArrayPasswords = INVALID_HANDLE;
new Handle:g_hTriePasswordStorage = INVALID_HANDLE;
new Handle:g_hTrieUsedPasswords = INVALID_HANDLE;


public Plugin:myinfo = {
	name 		= "tAdminPasswords",
	author 		= "Thrawn",
	description = "Allows users to get admin rights by using a different server password",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tadminpasswords_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tadminpasswords_enable", "1", "Enable tAdminPasswords", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);

	new Handle:hCvarPassword = FindConVar("sv_password");
	HookConVarChange(hCvarPassword, SVPassword_Changed);
	GetConVarString(hCvarPassword, g_sPassword, sizeof(g_sPassword));

	g_hForwardRefillRequest = CreateGlobalForward("SVP_OnRefillRequest", ET_Ignore);

	g_hArrayPasswords = CreateArray(128);
	g_hTriePasswordStorage = CreateTrie();
	g_hTrieUsedPasswords = CreateTrie();

	RegAdminCmd("sm_reloadpasswords", Command_ReloadPasswords, ADMFLAG_ROOT);

	IssueRefillRequest();
	ReapplyClientRights();
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public SVPassword_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	strcopy(g_sPassword, sizeof(g_sPassword), newValue);
}

public Action:Command_ReloadPasswords(iClient,args) {
	if(!g_bEnabled) {
		ReplyToCommand(iClient, "Plugin is disabled.");
		return Plugin_Handled;
	}

	ClearPasswordStorage();
	IssueRefillRequest();
	ReapplyClientRights();

	return Plugin_Handled;
}



/* -----------------------------------------------------------------
** Remember passwords of users when they are connecting.
** Also let every player in if he's using one of the passwords.
** ----------------------------------------------------------------- */
public bool:OnClientPreConnect(const String:name[], String:password[255], const String:ip[], const String:steamID[], String:rejectReason[255]) {
	if(!g_bEnabled)return true;
	if(strlen(password) == 0)return true;

	SetTrieString(g_hTrieUsedPasswords, steamID, password);

	new Handle:hTrieOptions = INVALID_HANDLE;
	if(GetTrieValue(g_hTriePasswordStorage, password, hTrieOptions)) {
		// Password is ok
		password = g_sPassword;
	}

	return true;
}



/* ----------------------------------------------
** Password check + actual setting of permissions
** ------------------------------------------- */
public OnClientPostAdminCheck(iClient) {
	if(!g_bEnabled)return;

	CheckAndApplyPassword(iClient);
}

public ReapplyClientRights() {
	for(new iClient = 1; iClient <= MaxClients; iClient++) {
		CheckAndApplyPassword(iClient);
	}
}

public CheckAndApplyPassword(iClient) {
	if(!IsClientAuthorized(iClient))return;

	decl String:sAuth[64];
	GetClientAuthString(iClient, sAuth, sizeof(sAuth));

	decl String:sPassword[128];
	if(GetTrieString(g_hTrieUsedPasswords, sAuth, sPassword, sizeof(sPassword))) {
		// iClient connected using a password

		new Handle:hTrieOptions = INVALID_HANDLE;
		if(GetTrieValue(g_hTriePasswordStorage, sPassword, hTrieOptions)) {
			// The password is valid and has settings stored.

			// Make sure our client is an "admin", don't overwrite
			// permissions the admin got from the core-defined admin checks.
			new AdminId:xAdmin = GetUserAdmin(iClient);
			if(xAdmin == INVALID_ADMIN_ID) {
				xAdmin = CreateAdmin("");
				SetUserAdmin(iClient, xAdmin, true);
			}

			// Then apply the groups stored with the password
			new Handle:hArrayGroups = INVALID_HANDLE;
			if(GetTrieValue(hTrieOptions, "groups", hArrayGroups) && hArrayGroups != INVALID_HANDLE) {
				decl String:sGroup[255];
				for(new iGroup = 0; iGroup < GetArraySize(hArrayGroups); iGroup++) {
					GetArrayString(hArrayGroups, iGroup, sGroup, sizeof(sGroup));

					// Check for each group whether it exists
					new GroupId:xGroup = FindAdmGroup(sGroup);
					if(xGroup != INVALID_GROUP_ID) {
						// Yay, it does. Assign to the client.
						AdminInheritGroup(xAdmin, xGroup);
					}
				}
			}

			// Then apply the flags specified for the password
			new iFlags;
			if(GetTrieValue(hTrieOptions, "flags", iFlags)) {
				SetUserFlagBits(iClient, iFlags);
			}

			// And the immunity level
			new iImmunity;
			if(GetTrieValue(hTrieOptions, "immunity", iImmunity)) {
				SetAdminImmunityLevel(xAdmin, iImmunity);
			}
		} else {
			// Password is invalid. Use the core-defined admin authorization checks.
			SetUserAdmin(iClient, INVALID_ADMIN_ID);
			RunAdminCacheChecks(iClient);
		}
	}
}

/* ----------------------------------------------
** Functions to modify the password storage
** ------------------------------------------- */
public IssueRefillRequest() {
	Call_StartForward(g_hForwardRefillRequest);
	Call_Finish();
}

public bool:AddPasswordTrie(const String:sPassword[], Handle:hTrieOptions) {
	if(strlen(sPassword) == 0) {
		LogError("Can't add empty password.");
		return false;
	}

	if(PasswordExists(sPassword)) {
		LogMessage("Password already registered, skipping...");
		return false;
	}

	if(hTrieOptions == INVALID_HANDLE) {
		LogError("Invalid argument: invalid trie handle");
		return false;
	}

	PushArrayString(g_hArrayPasswords, sPassword);
	SetTrieValue(g_hTriePasswordStorage, sPassword, hTrieOptions);
	return true;
}

public PasswordExists(const String:sPassword[]) {
	return FindStringInArray(g_hArrayPasswords, sPassword) != -1;
}

public ClearPasswordStorage() {
	for(new iPassword = 0; iPassword < GetArraySize(g_hArrayPasswords); iPassword++) {
		new String:sPassword[128];
		GetArrayString(g_hArrayPasswords, iPassword, sPassword, sizeof(sPassword));

		new Handle:hTrieOptions = INVALID_HANDLE;
		if(GetTrieValue(g_hTriePasswordStorage, sPassword, hTrieOptions)) {
			new Handle:hGroups = INVALID_HANDLE;
			if(GetTrieValue(hTrieOptions, "groups", hGroups)) {
				CloseHandle(hGroups);
			}

			CloseHandle(hTrieOptions);
		}
	}

	ClearArray(g_hArrayPasswords);
	ClearTrie(g_hTriePasswordStorage);
}

/* ----------------------------------------------
** Natives + Forwards to modify the password storage
** ------------------------------------------- */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("svpasswords");

	CreateNative("SVP_ReapplyPasswords", Native_ReapplyPasswords);
	CreateNative("SVP_AddPassword", Native_AddPassword);
	CreateNative("SVP_AddPasswordTrie", Native_AddPasswordTrie);

	CreateNative("SVP_GetClientPassword", Native_GetClientPassword);
	CreateNative("SVP_PasswordExists", Native_PasswordExists);

	return APLRes_Success;
}

public Native_ReapplyPasswords(Handle:hPlugin, iNumParams) {
	ReapplyClientRights();

	return;
}

public Native_AddPassword(Handle:hPlugin, iNumParams) {
	new String:sPassword[128];
	GetNativeString(1, sPassword, sizeof(sPassword));

	new String:sGroups[1024];
	GetNativeString(2, sGroups, sizeof(sGroups));

	new String:sFlags[255];
	GetNativeString(3, sFlags, sizeof(sFlags));

	new iImmunity = GetNativeCell(4);

	new Handle:hTrieOptions = CreateTrie();
	if(strlen(sFlags) > 0) {
		SetTrieValue(hTrieOptions, "flags", ReadFlagString(sFlags));
	}

	if(strlen(sGroups) > 0) {
		new Handle:hGroups = CreateArray(128);
		new String:sGroup[128];

		new iPos = 0;
		for(;;) {
			new iSplitPos = SplitString(sGroups[iPos], ",", sGroup, sizeof(sGroup));
			if(iSplitPos == -1) {
				PushArrayString(hGroups, sGroups[iPos]);
				break;
			}

			iPos += iSplitPos;
			PushArrayString(hGroups, sGroup);
		}

		SetTrieValue(hTrieOptions, "groups", hGroups);
	}

	if(iImmunity != -1)SetTrieValue(hTrieOptions, "immunity", iImmunity);

	return AddPasswordTrie(sPassword, hTrieOptions);
}

public Native_AddPasswordTrie(Handle:hPlugin, iNumParams) {
	new String:sPassword[128];
	GetNativeString(1, sPassword, sizeof(sPassword));
	new Handle:hTrieOptions = GetNativeCell(2);

	return AddPasswordTrie(sPassword, hTrieOptions);
}

public Native_GetClientPassword(Handle:hPlugin, iNumParams) {
	new iClient = GetNativeCell(1);
	new iMaxLen = GetNativeCell(3);

	decl String:sAuth[64];
	GetClientAuthString(iClient, sAuth, sizeof(sAuth));

	decl String:sPassword[128];
	if(GetTrieString(g_hTrieUsedPasswords, sAuth, sPassword, sizeof(sPassword))) {
		SetNativeString(2, sPassword, iMaxLen, false);
		return true;
	}

	return false;
}

public Native_PasswordExists(Handle:hPlugin, iNumParams) {
	new String:sPassword[128];
	GetNativeString(1, sPassword, sizeof(sPassword));

	return PasswordExists(sPassword);
}



