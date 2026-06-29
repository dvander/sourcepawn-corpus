#pragma semicolon 1
#include <sourcemod>
#define PL_VERSION "1.0"
new Handle:g_hEnabled = INVALID_HANDLE;
new bool:g_bEnabled;
new Handle:g_sMap = INVALID_HANDLE;
new Handle:g_hTime = INVALID_HANDLE;
public Plugin:myinfo = 
{
	name = "AutoMapChange",
	author = "Ffww343",
	description = "Changes SRCDS map if the server is empty after a given time.",
	version = PL_VERSION,
	url = ""
}
public OnPluginStart() {
	CreateConVar("sm_automapchange_version", PL_VERSION, "AutoMapChange version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_automapchange", "1", "Enable AutoMapChange.", FCVAR_PLUGIN);
	g_sMap = CreateConVar("sm_automapchange_map", "l4d_hospital01_apartment", "Map to change server to.", FCVAR_PLUGIN);
	g_hTime = CreateConVar("sm_automapchange_time", "300", "Amount of time between checks in seconds.", FCVAR_PLUGIN);
	HookConVarChange(g_hEnabled, Cvar_enabled);
}
public OnMapStart() {
	new time;
	time = GetConVarInt(g_hTime);
	CreateTimer(float(time), CheckTime, 0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hEnabled);
}
public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hEnabled);
}
public Action:CheckTime(Handle:timer, any:useless) {
	if(g_bEnabled) {
		for(new i=1;i<=MaxClients;i++) {
			if(IsClientConnected(i) && !IsFakeClient(i)) {
				return Plugin_Handled;
			}
		}
		
		static String:map[64];
		GetConVarString(g_sMap,map,sizeof(map));

		if (!IsMapValid(map))
		{
			PrintToServer("Map was not found");
			return Plugin_Handled;
		}	
		LogAction(0, -1, "Map Changed due to empty server.");
		decl String:mapcommand[80];
		mapcommand = "changelevel ";
		StrCat(mapcommand,80,map);
		ServerCommand(mapcommand);
	}
	return Plugin_Handled;
}