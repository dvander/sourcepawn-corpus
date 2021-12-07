#pragma semicolon 1
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#tryinclude <updater>

#define PLUGIN_VERSION "14.0224.0"

new String:g_baseFilters[][9] = {
	"scout", 			"scouts",		"scoot",		"scoot",
	"soldier", 			"soldiers", 	"solly",		"sollies",		"sollys",
	"pyro", 			"pyros", 
	"demo", 			"demos", 		"demoman", 		"demomen", 		"demomans",
	"heavy", 			"heavies", 		"hoovy",		"hoovies",		"hoovys",
	"engie", 			"engies", 		"engineer", 	"engineers", 	"engy",			"engys",
	"medic", 			"medics", 		"doctor",		"doctors",
	"sniper", 			"snipers", 
	"spy", 				"spies"
};
new String:g_filterPrefixes[8][5] = { //order must match g_filterPhrases
	"",
	"!",
	"red",
	"!red",
	"blu",
	"blue",
	"!blu",
	"!blue"
};
new String:g_filterPhrases[8][17] = { //order must match g_filterPrefixes
	"all ",
	"non-",
	"all RED ",
	"everyone but RED ",
	"all BLU ",
	"all BLU ",
	"everyone but BLU ",
	"everyone but BLU "
};
new String:g_tf2ClassNames[9][9] = { //do not change order
	"Scouts",
	"Snipers",
	"Soldiers",
	"Demomen",
	"Medics",
	"Heavies",
	"Pyros",
	"Spies",
	"Engineers"
};

new Handle:hcvar_version = INVALID_HANDLE;
new Handle:hcvar_update = INVALID_HANDLE;

public OnPluginStart() {
	hcvar_version = CreateConVar("sm_classtargeting_version", PLUGIN_VERSION, "Class Targeting Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);
	SetConVarString(hcvar_version, PLUGIN_VERSION);
	HookConVarChange(hcvar_version, cvarChange);
	hcvar_update = CreateConVar("sm_classtargeting_update", "1", "(0/1) Enable automatic updating?", FCVAR_PLUGIN);
	MakeFilters();
}

MakeFilters(bool:create=true) {
	new TFClassType:class;
	decl String:filter[sizeof(g_filterPrefixes)][sizeof(g_baseFilters[]) + sizeof(g_filterPrefixes[]) + 2];
	decl String:phrase[sizeof(g_filterPhrases)][sizeof(g_filterPhrases[]) + sizeof(g_tf2ClassNames[]) + 1];
	for (new i = 0; i < sizeof(g_baseFilters); i++) {
		if ((class = ParseClass(g_baseFilters[i])) == TFClass_Unknown) { 
			if (create) { LogError("No class could be discerned from filter \"%s\"", g_baseFilters[i]); }
			continue;
		}
		for (new x = 0; x < sizeof(g_filterPrefixes); x++) {
			Format(filter[x], sizeof(filter[]), "@%s%s", g_filterPrefixes[x], g_baseFilters[i]);
			if (create) {
				Format(phrase[x], sizeof(phrase[]), "%s%s", g_filterPhrases[x], g_tf2ClassNames[_:class-1]);
				AddMultiTargetFilter(filter[x], t_TF2Classes, phrase[x], false);
				//PrintToChatAll("Created Filter %s : \"%s\"", filter[x], phrase[x]);
			}
			else {
				RemoveMultiTargetFilter(filter[x], t_TF2Classes);
				//PrintToChatAll("Removed Filter %s", filter[x]);
			}
		}
	}
}


public bool:t_TF2Classes(const String:pattern[], Handle:clients) {
	new bool:reverse;
	if (pattern[1] == '!') { reverse = true; }

	new TFTeam:team;
	if (StrContains(pattern, "red", false) != -1) { team = TFTeam_Red;  }
	else if (StrContains(pattern, "blu", false) != -1) { team = TFTeam_Blue; }

	new TFClassType:class = ParseClass(pattern);

	for (new i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) <= _:TFTeam_Spectator || IsClientSourceTV(i) || IsClientReplay(i)) {
			continue;
		}
		if ((TF2_GetPlayerClass(i) == class && (team == TFTeam_Unassigned || TFTeam:GetClientTeam(i) == team)) == !reverse) {
			PushArrayCell(clients, i);
		}
	}
	return true;
}

TFClassType:ParseClass(const String:pattern[]) {
	if (StrContains(pattern, "sco", false) != -1) { return TFClass_Scout; }
	if (StrContains(pattern, "sol", false) != -1) { return TFClass_Soldier; }
	if (StrContains(pattern, "pyr", false) != -1) { return TFClass_Pyro; }
	if (StrContains(pattern, "dem", false) != -1) { return TFClass_DemoMan; }
	if (StrContains(pattern, "hea", false) != -1) { return TFClass_Heavy; }
	if (StrContains(pattern, "hoo", false) != -1) { return TFClass_Heavy; }
	if (StrContains(pattern, "eng", false) != -1) { return TFClass_Engineer; }
	if (StrContains(pattern, "med", false) != -1) { return TFClass_Medic; }
	if (StrContains(pattern, "doc", false) != -1) { return TFClass_Medic; }
	if (StrContains(pattern, "sni", false) != -1) { return TFClass_Sniper; }
	if (StrContains(pattern, "spi", false) != -1) { return TFClass_Spy; }
	if (StrContains(pattern, "spy", false) != -1) { return TFClass_Spy; }
	else { return TFClass_Unknown; }
}






public OnPluginEnd() { MakeFilters(false); }
public Plugin:myinfo = {
	name = "[TF2] Class Targeting",
	author = "Derek D. Howard",
	description = "Provides a number of targeting filters geared towards targeting only certain classes.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=226986"
};
public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLate, String:strError[], iErr_Max) {
	decl String:strGame[32];
	GetGameFolderName(strGame, sizeof(strGame));
	if (!StrEqual(strGame, "tf")) {
		Format(strError, iErr_Max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}
#define UPDATE_URL "http://ddhoward.bitbucket.org/classtargeting.txt"
public OnAllPluginsLoaded() {
	if (LibraryExists("updater"))
		Updater_AddPlugin(UPDATE_URL);
}
public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "updater"))
		Updater_AddPlugin(UPDATE_URL);
}
public Action:Updater_OnPluginDownloading() {
	if (GetConVarBool(hcvar_update)) {
		return Plugin_Continue;
	} else {
		return Plugin_Handled;
	}
}
public Updater_OnPluginUpdated() {
	ReloadPlugin();
}
public cvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	if (hHandle == hcvar_version) {
		SetConVarString(hcvar_version, PLUGIN_VERSION);
	}
}