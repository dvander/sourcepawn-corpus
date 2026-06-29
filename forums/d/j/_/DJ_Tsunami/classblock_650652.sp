#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "0.5"

public Plugin:myinfo = {
	name        = "DoD:S Class Block",
	author      = "Tsunami",
	description = "Block classes in DoD:S.",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

new g_iBlocks[MAXPLAYERS + 1];
new g_iClass[MAXPLAYERS + 1];
new g_iClasses[6]           = {1, 2, 4, 8, 16, 32};
new Handle:g_hEnabled;
new Handle:g_hBlocks        = INVALID_HANDLE;
new String:g_sSounds[4][32] = {"", "", "player/american/us_negative.wav", "player/german/ger_negative2.wav"};

public OnPluginStart() {
	CreateConVar("sm_classblock_version", PL_VERSION, "Block classes in DoD:S.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_classblock_enabled", "1", "Enable/disable blocking classes in DoD:S.");
	
	HookEvent("player_changeclass", Event_ChangeClass);
	RegConsoleCmd("joinclass",      Command_JoinClass, "Block classes in DoD:S.");
}

public OnMapStart() {
	decl i, String:sPath[256], String:sSound[40];
	for (i = 2; i < sizeof(g_sSounds); i++) {
		Format(sSound, sizeof(sSound), "sound/%s", g_sSounds[i]);
		PrecacheSound(g_sSounds[i]);
		AddFileToDownloadsTable(sSound);
	}
	
	if (g_hBlocks != INVALID_HANDLE) {
		CloseHandle(g_hBlocks);
	}
	
	g_hBlocks = CreateKeyValues("Blocks");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/classblock.txt");
	FileToKeyValues(g_hBlocks, sPath);
}

public OnClientAuthorized(client, const String:auth[]) {
	KvRewind(g_hBlocks);
	
	g_iBlocks[client] = KvGetNum(g_hBlocks, auth);
	g_iClass[client]  = 0;
}

public Action:Command_JoinClass(client, args) {
	decl String:sClass[2];
	GetCmdArg(1, sClass, sizeof(sClass));
	g_iClass[client] = StringToInt(sClass);
	
	if (IsBlocked(client, g_iClass[client])) {
		for (new i = 0; i < 6; i++) {
			if (!IsBlocked(client, i)) {
				FakeClientCommand(client, "joinclass %d", i);
				break;
			}
		}
	}
}

public Event_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast) {
	new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
			iClass  = GetEventInt(event, "class"),
			iTeam   = GetClientTeam(iClient);
	
	if (IsBlocked(iClient, iClass)) {
		ShowVGUIPanel(iClient, iTeam == 3 ? "class_ger" : "class_us");
		EmitSoundToClient(iClient, g_sSounds[iTeam]);
		FakeClientCommand(iClient, "joinclass %d", g_iClass[iClient]);
	} else {
		g_iClass[iClient] = iClass;
	}
}

bool:IsBlocked(iClient, iClass) {
	if (GetConVarBool(g_hEnabled) && iClass >= 0 && iClass < 6 && g_iBlocks[iClient] & g_iClasses[iClass]) {
		return true;
	} else {
		return false;
	}
}