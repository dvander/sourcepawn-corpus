#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"

new	Handle:esmc_enabled = INVALID_HANDLE,
	Handle:esmc_map = INVALID_HANDLE,
	Handle:g_hTimerHandle = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Empty Sever Map Change",
	author = "Antithasys",
	description = "Changes to map when server is empty",
	version = PLUGIN_VERSION,
	url = "http://www.mytf2.com"
}

public OnPluginStart()
{
	CreateConVar("esmc_version", PLUGIN_VERSION, "Empty Sever Map Change", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	esmc_enabled = CreateConVar("esmc_enabled", "1", "Enables/Disables Empty Sever Map Change", _, true, 0.0, true, 1.0);
	esmc_map = CreateConVar("esmc_map", "ctf_2fort", "Map to change to (case sensitive)");
	HookConVarChange(esmc_map, ConVarSettingsChanged);
	AutoExecConfig(true, "plugin.es_mapchanger");
}

public OnConfigsExecuted()
{
	g_hTimerHandle = INVALID_HANDLE;
	if (GetConVarBool(esmc_enabled))
		PrepCheck();
}

public OnClientDisconnect_Post(client)
{
	if (GetConVarBool(esmc_enabled))
		PrepCheck();
}

public ConVarSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(esmc_enabled))
		PrepCheck();
}

public Action:Timer_DoCheck(Handle:timer, any:client)
{
	if (GetClientCount() == 0) {
		decl String:sEmptyMap[64];
		decl String:sCurrentMap[64];
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
		GetConVarString(esmc_map, sEmptyMap, sizeof(sEmptyMap));
		if (!IsMapValid(sEmptyMap)) {
			LogError("[ESMC] Map name in esmc_map (%s) is invalid", sEmptyMap);
			g_hTimerHandle = INVALID_HANDLE;
			return Plugin_Handled;
		}	
		if (!StrEqual(sCurrentMap, sEmptyMap))
			ServerCommand("changelevel %s", sEmptyMap);
	}
	g_hTimerHandle = INVALID_HANDLE;
	return Plugin_Handled;
}

stock PrepCheck()
{
	if (g_hTimerHandle == INVALID_HANDLE)
		CreateTimer(2.0, Timer_DoCheck, _, TIMER_FLAG_NO_MAPCHANGE);
}