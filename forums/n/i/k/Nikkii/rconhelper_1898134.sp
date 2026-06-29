#include <smrcon>

#define PLUGIN_VERSION	"0.1"

#define MAX_HOSTS 32

new String:g_aAllowedHosts[MAX_HOSTS][64];

new Handle:g_aSettings = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "RCON Helper",
	author = "Nikki",
	description = "Allows specific passwords for different ip addresses connecting to rcon",
	version = PLUGIN_VERSION,
	url = "http://nikkii.us/"
}

public OnPluginStart() {
	CreateConVar("sm_rconhelper_version", PLUGIN_VERSION, "RCON Helper Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	LoadConfig();
}

public LoadConfig() {
	if(g_aSettings == INVALID_HANDLE) {
		g_aSettings = CreateArray(MAX_HOSTS);
	} else {
		ClearArray(g_aSettings);
	}
	
	decl String:path[PLATFORM_MAX_PATH];
	new Handle:kv;

	BuildPath(Path_SM, path, sizeof(path), "configs/matchserver.cfg");
	kv = CreateKeyValues("RconSources");
	
	if(!FileToKeyValues(kv, path)) {
		SetFailState("Unable to load server configurations");
	}
	
	for(new i = 0; i < MAX_HOSTS; i++) {
		strcopy(g_aAllowedHosts[i], sizeof(g_aAllowedHosts[]), "");
	}
	
	KvGotoFirstSubKey(kv);
	
	do {
		new Handle:trie = CreateTrie();
		decl String:sSettings[2][32];
		KvGetString(kv, "address", sSettings[0], sizeof(sSettings[]));
		KvGetString(kv, "password", sSettings[1], sizeof(sSettings[]));
		
		SetTrieString(trie, "address", sSettings[0]);
		SetTrieString(trie, "password", sSettings[1]);
		
		new idx = PushArrayCell(g_aSettings, trie);
		if(idx != -1 && idx <= MAX_HOSTS) {
			strcopy(g_aAllowedHosts[idx], sizeof(g_aAllowedHosts[]), sSettings[0]);
		}
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);
}

public Action:SMRCon_OnAuth(rconId, const String:address[], const String:password[], &bool:allow) {	
	new idx = InArray(address, g_aAllowedHosts, sizeof(g_aAllowedHosts));
	if(idx != -1) {
		decl String:expectedPassword[64];
		new Handle:trie = GetArrayCell(g_aSettings, idx);
		
		GetTrieString(trie, "password", expectedPassword, sizeof(expectedPassword));
		
		if(StrEqual(password, expectedPassword)) {
			allow = true;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock InArray(const String:needle[], const String:haystack[][], hsize) {
	for (new i = 0; i < hsize; ++i)
		if (strcmp(needle, haystack[i]) == 0)
			return i;
	return -1;
}
