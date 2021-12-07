#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required; 

#define PLUGIN_VERSION "Build 1.0.1A"
#define FULLNAME 0
#define SPLITNAME 1
#define ENABLE 0
#define DEBUGS 1
#define CFGPATH 2

bool bConVar[3];
bool SPECIFIC;
Handle hConVar[3] = INVALID_HANDLE;
Handle hString;
char ResultSection[PLATFORM_MAX_PATH];
char MapName[2][PLATFORM_MAX_PATH];
char Path[PLATFORM_MAX_PATH];

public Plugin myinfo = {
	name = "[SM] # M&M CFG Expert",
	author = "Rodrigo286",
	description = "Map and Mod configs",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.com"
};

public void OnPluginStart(){
	CreateConVar("sm_mmcfgexpert_version", PLUGIN_VERSION, "\"[SM] # M&M CFG Expert\" version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY);
	hConVar[ENABLE] = CreateConVar("sm_mmcfgexpert_enable", "1", "\"1\" = \"[SM] # M&M CFG Expert\" plugin is enabled, \"0\" = \"[SM] # M&M CFG Expert\" plugin is disabled");
	hConVar[DEBUGS] = CreateConVar("sm_mmcfgexpert_debugs", "1", "\"1\" = \"[SM] # M&M CFG Expert\" debugs is enabled, \"0\" = \"[SM] # M&M CFG Expert\" debugs is disabled");
	hConVar[CFGPATH] = CreateConVar("sm_mmcfgexpert_config", "configs/mm_config.ini", "Path to CFG file.");
	AutoExecConfig(true, "sm_MM_CFG_Expert");

	HookConVarChange(hConVar[ENABLE], ConVarChange);
	HookConVarChange(hConVar[DEBUGS], ConVarChange);
	HookConVarChange(hConVar[CFGPATH], ConVarChange);

	bConVar[ENABLE] = GetConVarBool(hConVar[ENABLE]);
	bConVar[DEBUGS] = GetConVarBool(hConVar[DEBUGS]);
	GetConVarString(hConVar[CFGPATH], Path, sizeof(Path));
}

public void ConVarChange(Handle convar, const char[] oldValue, const char[] newValue){
	bConVar[ENABLE] = GetConVarBool(hConVar[ENABLE]);
	bConVar[DEBUGS] = GetConVarBool(hConVar[DEBUGS]);
	GetConVarString(hConVar[CFGPATH], Path, sizeof(Path));
}

public void OnAutoConfigsBuffered(){
	SPECIFIC = false;
	GetCurrentMap(MapName[FULLNAME], sizeof(MapName[]));

	if(SplitString(MapName[FULLNAME], "_", MapName[SPLITNAME], sizeof(MapName[])) != -1 && bConVar[ENABLE]){
		if(hString != INVALID_HANDLE){
			CloseHandle(hString);
			hString = INVALID_HANDLE;
		}

		hString = CreateTrie();

		char path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, path, sizeof(path), Path);

		if(!FileExists(path))		{
			SetFailState("[M&M Debug - PREFIX MAP or MOD] No file \"%s\"", path);
		}

		Handle smc = SMC_CreateParser();
		SMC_SetReaders(smc, NewSection, KeyValue, EndSection);
		SMCError error = SMC_ParseFile(smc, path);

		if(error != SMCError_Okay){
			char buffer[255];
			if(SMC_GetErrorString(error, buffer, sizeof(buffer)))			{
				LogError("[M&M Debug - PREFIX MAP or MOD] %s", buffer);
			}
		}

		CloseHandle(smc);
	}
}

public SMCResult NewSection(Handle smc, const char[] name, bool opt_quotes){
	strcopy(ResultSection, sizeof(ResultSection), name);
}

public SMCResult EndSection(Handle smc){}

public SMCResult KeyValue(Handle smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes){
	SetTrieString(hString, ResultSection, key); SetTrieString(hString, ResultSection, value);

	if(!StrEqual(key, "") && StrEqual(ResultSection, MapName[FULLNAME])){
		SPECIFIC = true;
		ServerCommand("%s \"%s\"", key, value);
		if(bConVar[DEBUGS])
			PrintToServer("[M&M Debug - SPECIFIC MAP] Command send to server: %s %s", key, value);
	}

	if(!StrEqual(key, "") && StrEqual(ResultSection, MapName[SPLITNAME]) && !SPECIFIC){
		SPECIFIC = false;
		ServerCommand("%s \"%s\"", key, value);
		if(bConVar[DEBUGS])
			PrintToServer("[M&M Debug - PREFIX MAP or MOD] Command send to server: %s %s", key, value);
	}
}