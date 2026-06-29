#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#define NAME "Buyzone range"
#define VERSION "1.0"

public Plugin:myinfo = {
	name = NAME,
	author = "Devzirom",
	description = "Plugin allows to set buyzone range for team specific: everywhere/nowhere/default",
	version = VERSION,
	url = "www.sourcemod.com"
}

new bool:bz_enabled = false;
new bz_t = 0;
new bz_ct = 0;

new Handle:sm_bz_enabled;
new Handle:sm_bz_t;
new Handle:sm_bz_ct;

public OnPluginStart() {
	sm_bz_enabled = CreateConVar("sm_bz_enabled", "1", "\"1\" = \"Buyzone range\" plugin is active, \"0\" = \"Buyzone range\" plugin is disabled");
	sm_bz_t = CreateConVar("sm_bz_t", "0", "To install a buyzone range for the Terrorists team. Use \"sm_bz_help\" for help");
	sm_bz_ct = CreateConVar("sm_bz_ct", "0", "To install a buyzone range for the Counter-Terrorists team. Use \"sm_bz_help\" for help");
	
	CreateConVar("sm_bz_version", VERSION, NAME, FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	HookConVarChange(sm_bz_enabled, BzConVarChanged);
	HookConVarChange(sm_bz_t, BzConVarChanged);
	HookConVarChange(sm_bz_ct, BzConVarChanged);
	
	RegServerCmd("sm_bz_help", CommandHelp, " \"Buyzone range\" plugin help");
	
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

public Action:CommandHelp(args) {
	new String:Info[6][128];
	
	GetPluginInfo(INVALID_HANDLE, PlInfo_Name, Info[PlInfo_Name], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_Author, Info[PlInfo_Author], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_Description, Info[PlInfo_Description], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_Version, Info[PlInfo_Version], 127);
	GetPluginInfo(INVALID_HANDLE, PlInfo_URL, Info[PlInfo_URL], 127);
	
	PrintToServer("-------------------------");
	PrintToServer("\n[Plugin info]");
	PrintToServer("Name: \"%s\"", Info[PlInfo_Name]);
	PrintToServer("Version: \"%s\"", Info[PlInfo_Version]);
	PrintToServer("Description: \"%s\"", Info[PlInfo_Description]);
	PrintToServer("Author: \"%s\"", Info[PlInfo_Author]);
	PrintToServer("URL: \"%s\"", Info[PlInfo_URL]);
	
	PrintToServer("\n[Plugin cvar's]");
	PrintToServer("\"sm_bz_enabled\" \"1\" - \"1\" = \"Buyzone range\" plugin is active, \"0\" = \"Buyzone range\" plugin is disabled");
	PrintToServer("\"sm_bz_t\" \"0\" - To install a buyzone range for the Terrorists team.");
	PrintToServer("\"sm_bz_ct\" \"0\" - To install a buyzone range for the Counter-Terrorists team.");
	PrintToServer("\"sm_bz_help\" - This help");
	PrintToServer("\"sm_bz_version\" - Plugin version");
	
	PrintToServer("\n[Usage examples cvar's]");
	PrintToServer("sm_sw_t 0");
	PrintToServer(" - To install a buyzone range for the Terrorists team is default.");
	PrintToServer("sm_sw_t 1");
	PrintToServer(" - To install a buyzone range for the Terrorists team is nowhere.");
	PrintToServer("sm_sw_t 2");
	PrintToServer(" - To install a buyzone range for the Terrorists team is everywhere.");
	PrintToServer("sm_sw_ct 0");
	PrintToServer(" - To install a buyzone range for the Counter-Terrorists team is default.");
	PrintToServer("sm_sw_ct 1");
	PrintToServer(" - To install a buyzone range for the Counter-Terrorists team is nowhere.");
	PrintToServer("sm_sw_ct 2");
	PrintToServer(" - To install a buyzone range for the Counter-Terrorists team is everywhere.");
	
	PrintToServer("\n-------------------------");
}

public BzConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	PrintToServer("[SM] Restart a map to apply changes!");
}

public OnMapStart() {
	bz_enabled = (GetConVarInt(sm_bz_enabled) == 1);
	
	if(!bz_enabled)
		return;
	
	bz_t = GetConVarInt(sm_bz_t);
	bz_ct = GetConVarInt(sm_bz_ct);

	new entCount = GetMaxEntities();
	decl String:entName[64];
	
	for(new i=0; i<entCount; i++) {
		if(!IsValidEntity(i))
			continue;
		
		GetEdictClassname(i, entName, 63);
		
		if(!StrEqual(entName, "func_buyzone"))
			continue;
		
		new m_iTeamNum = GetEntProp(i, Prop_Data, "m_iTeamNum");
		
		//PrintToServer("--> Detected entity: func_buyzone, m_iTeamNum = %d", m_iTeamNum);

		if((m_iTeamNum == 2 && bz_t > 0) || (m_iTeamNum == 3 && bz_ct > 0)) {
			RemoveEdict(i); //or SetEntProp(i, Prop_Send, "m_iTeamNum", 0);
		}
	}
	
	return;
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!bz_enabled)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	
	if((team != CS_TEAM_T && team != CS_TEAM_CT) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	if((team == CS_TEAM_T && bz_t == 2) || (team == CS_TEAM_CT && bz_ct == 2)) {
		SDKHook(client, SDKHook_Touch, BzUpdate);
	}
	
	return Plugin_Continue;
}

public Action:BzUpdate(client, othor) {
	SetEntProp(client, Prop_Send, "m_bInBuyZone", 1);
	return Plugin_Handled;
}

public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!bz_enabled)
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	SDKUnhook(client, SDKHook_Touch, BzUpdate);
	
	return Plugin_Continue;
}