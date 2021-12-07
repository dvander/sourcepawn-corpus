#pragma semicolon 1
#pragma newdecls required

// ====[ INCLUDES ]============================================================
#include <sourcemod>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <updater>

// ====[ DEFINES ]=============================================================
#define PLUGIN_NAME "Super Target Filters"
#define PLUGIN_VERSION "1.4.1 new syntax test by 404"

// ====[ CONFIG ]==============================================================
#define MAXFILTERS 500
StringMap filterMap;
int maxFilters;
char fltKey[MAXFILTERS][24];
int fltTeam[MAXFILTERS];
int fltClass[MAXFILTERS];
int fltAlive[MAXFILTERS];
int fltBots[MAXFILTERS];
int fltCond[MAXFILTERS];
int fltFlag[MAXFILTERS];
bool fltOnlyFlag[MAXFILTERS];
int fltRnd[MAXFILTERS];
int fltNeg[MAXFILTERS];
int fltSelf[MAXFILTERS];

// ====[ PLAYER ]==============================================================
int clientLastUsed = -1;
float timeLastUsed = -1.0;

// ====[ PLUGIN ]==============================================================
ConVar hCUpdater;
EngineVersion EVGame;

#define Is_iClass() (EVGame == Engine_TF2)
#define Is_iPlayerClass() (EVGame == Engine_DODS || EVGame == Engine_Left4Dead || EVGame == Engine_Left4Dead2)

//public Plugin:myinfo = {
public Plugin myinfo = {
	name = "Super Target Filters",
	author = "Mitch",
	description = "Addition to the classes server owners can now define new target filters based on classes, teams, etc.",
	version = PLUGIN_VERSION,
	url = "https://bitbucket.org/MitchDizzle/super-targeting/"
}
// ====[ EVENTS ]==============================================================
//public OnPluginStart()
public void OnPluginStart()
{
	hCUpdater = CreateConVar("sm_supertargeting_update", "1", "(0/1) Enable automatic updating?"); // Removed FCVAR_PLUGIN, it's deprecated, don't use it
	AutoExecConfig();
	CreateConVar("sm_supertargeting_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY); // Same as above, removed FCVAR_PLUGIN
	LoadFilterConfig();
	EVGame = GetEngineVersion();
	AddCommandListener(ST_CommandListener);
}

//public OnPluginEnd() {
public void OnPluginEnd() {
	for(int k = 0; k < maxFilters; k++) {
		RemoveMultiTargetFilter(fltKey[k], FilterClasses);
	}
	delete filterMap;
}

public Action ST_CommandListener(int client, const char[] command, int argc) {
	clientLastUsed = client;
	timeLastUsed = GetGameTime();
}

// ====[ Filter Event ]========================================================
public bool FilterClasses(const char[] strPattern, Handle hClients) {
	//Get key
	int k = -1;
//	if(!GetTrieValue(filterMap, strPattern, k) || k == -1) {
	if(!filterMap.GetValue(strPattern, k) || k == -1) {
		//Pattern is not found within the trie
		return false;
	}
	
	bool bOpposite = (StrContains(strPattern,"!") == 1 || fltNeg[k]);
	bool PlayerMatchesCriteria;

	/* Used for stored all players, and getting random players that match certain criteria. */
	ArrayList hPlayers;
	int rndPlayers = fltRnd[k];
	if(rndPlayers) {
		hPlayers = new ArrayList();
	}
	
	int oneplayer = fltSelf[k];
	int client = -1;
	if(oneplayer > 0) {
		client = FindIssuer();
		if(client > 0 && oneplayer == 2) {
			client = GetClientAimTarget(client);
		}
	}

	for(int i = 1; i <= MaxClients; i ++) {
		if(!IsClientInGame(i)) continue;
		
		if(client > 0) {
			if(bOpposite && i == client) continue;
			if(!bOpposite && i != client) continue;
		}
		
		PlayerMatchesCriteria = true;
		//Filter Checks
		//Bots
		if(fltBots[k] > -1 && ((fltBots[k] == 1) != IsFakeClient(i))) {
			PlayerMatchesCriteria = false;
		}

		//Alive
		if(fltAlive[k] > -1 && ((fltAlive[k] == 1) != IsPlayerAlive(i))) {
			PlayerMatchesCriteria = false;
		}

		//Class
		if(fltClass[k] != 0 ) {
			if(Is_iPlayerClass() && GetEntProp(i, Prop_Send, "m_iPlayerClass") != fltClass[k]) {
				PlayerMatchesCriteria = false;
			} else if(Is_iClass() && GetEntProp(i, Prop_Send, "m_iClass") != fltClass[k]) {
				PlayerMatchesCriteria = false;
			}
		}

		//Team
		if(fltTeam[k] != 0 && GetClientTeam(i) != fltTeam[k]) {
			PlayerMatchesCriteria = false;
		}

		//TF2: Conditions
//		if(EVGame == Engine_TF2 && fltCond[k] != -1 && !TF2_IsPlayerInCondition(i, TFCond:fltCond[k])) {
		if(EVGame == Engine_TF2 && fltCond[k] != -1 && !TF2_IsPlayerInCondition(i, view_as<TFCond>(fltCond[k]))) {
			PlayerMatchesCriteria = false;
		}

		//Flags
		if(fltFlag[k] != 0 ) {
			if((!fltOnlyFlag[k] && !(GetUserFlagBits(i) & fltFlag[k])) || 
				(fltOnlyFlag[k] && !(GetUserFlagBits(i) == fltFlag[k]))) {
				PlayerMatchesCriteria = false;
			}
		}

		if(bOpposite) {
			PlayerMatchesCriteria = !PlayerMatchesCriteria;
		}

		if(PlayerMatchesCriteria) {
			if(rndPlayers) {
			//	PushArrayCell(hPlayers, i);
				hPlayers.Push(i);
			} else {
			//	PushArrayCell(hClients, i);
				hClients.Push(i);
			}
		}
	}
	
	if(rndPlayers) {
		int rndCell;
		int rndPlayer = -1;
	//	int plySize = GetArraySize(hPlayers);
		int plySize = hPlayers.Length;
		while(rndPlayers > 0 && plySize > 0) {
			rndCell = GetRandomInt(0, plySize-1);
		//	rndPlayer = GetArrayCell(hPlayers, rndCell);
			rndPlayer = hPlayers.Get(rndCell);
		//	PushArrayCell(hClients, rndPlayer);
			hClients.Push(rndPlayer);
		//	RemoveFromArray(hPlayers, rndCell);
			hPlayers.Erase(rndCell);
		//	plySize = GetArraySize(hPlayers);
			plySize = hPlayers.Length;
			rndPlayers--;
		}
	}
	
//	return (GetArraySize(hClients) > 0);
	return (hClients.Length > 0);
}

//public FindIssuer() {
public int FindIssuer() {
	if(GetGameTime() < timeLastUsed+1.0) {
		return clientLastUsed;
	}
	return -1;
}

// ====[ Config Functions ]====================================================
//public LoadFilterConfig() {
public Action LoadFilterConfig() {
	filterMap = new StringMap();
	
	char sPaths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPaths, sizeof(sPaths),"configs/SuperTargeting.cfg");
//	KeyValues kv = CreateKeyValues("SuperTargeting");
	KeyValues kv = new KeyValues("SuperTargeting");
//	FileToKeyValues(kv, sPaths);
	kv.ImportFromFile(sPaths);
	
//	if (!KvGotoFirstSubKey(kv)) {
	if (!kv.GotoFirstSubKey()) {
		return;
	}
	
	char sText[64];
	int k; // Represents the current id for simplicity
	do {
		k = maxFilters;
		
	//	KvGetSectionName(kv, fltKey[k], 24);
		kv.GetSectionName(fltKey[k], 24);
		if(StrEqual(fltKey[k], "")) {
			//Continue to the next filter if this is invalid.
			continue;
		}
		//Add to filter map.
		filterMap.SetValue(fltKey[k], maxFilters);

	//	KvGetString(kv, "text", sText, 32, "TOOL TIP MISSING");
		kv.GetString("text", sText, 32, "TOOL TIP MISSING");
		AddMultiTargetFilter(fltKey[k], FilterClasses, sText, false);
		
	//	fltTeam[k] = KvGetNum(kv, "team", 0);
		fltTeam[k] = kv.GetNum("team", 0);
	//	fltClass[k] = KvGetNum(kv, "class", 0);
		fltClass[k] = kv.GetNum("class", 0);
	//	fltAlive[k] = KvGetNum(kv, "alive", -1);
		fltAlive[k] = kv.GetNum("alive", -1);
	//	fltBots[k] = KvGetNum(kv, "bots", -1);
		fltBots[k] = kv.GetNum("bots", -1);
	//	fltCond[k] = 	KvGetNum(kv, "cond", -1);
		fltCond[k] = kv.GetNum("cond", -1);
	//	fltRnd[k] = KvGetNum(kv, "random", 0);
		fltRnd[k] = kv.GetNum("random", 0);
	//	fltPrem[k] = KvGetNum(kv, "premium", -1);
	//	fltPrem[k] = kv.GetNum("premium", -1);
	//	fltNeg[k] = KvGetNum(kv, "invert", 0);
		fltNeg[k] = kv.GetNum("invert", 0);
	//	fltSelf[k] = KvGetNum(kv, "self", 0); // 0 - Disable, 1 - Self, 2 - Aim
		fltSelf[k] = kv.GetNum("self", 0); // 0 - Disable, 1 - Self, 2 - Aim
		//Get Flags
		kv.GetString("flag", sText, 8, "");
		if(!StrEqual(sText, "", false)) {
			fltOnlyFlag[k] = (StrContains(sText, "#") != -1) ? true : false;
			ReplaceString(sText, sizeof(sText), "#", "");
			fltFlag[k] = ReadFlagString(sText);
		}		
		maxFilters++; //Increase the amount of filters
	} while(kv.GotoNextKey());
	delete kv;
	return;
}

// ====[ Updater ]=============================================================
#define UPDATE_URL "https://bitbucket.org/MitchDizzle/super-targeting/raw/master/supertargeting.txt"
//public OnAllPluginsLoaded() {
public void OnAllPluginsLoaded() {
	if (LibraryExists("updater"))
		Updater_AddPlugin(UPDATE_URL);
}
//public OnLibraryAdded(const String:name[]) {
public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "updater"))
		Updater_AddPlugin(UPDATE_URL);
}
//public Action:Updater_OnPluginDownloading() {
public Action Updater_OnPluginDownloading() {
//	if (GetConVarBool(hCUpdater))
	if (hCUpdater.BoolValue == true)
		return Plugin_Continue;
	return Plugin_Handled;
}
//public Updater_OnPluginUpdated() {
public void Updater_OnPluginUpdated() {
	ReloadPlugin();
}