#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PL_VERSION "0.5"

public Plugin:myinfo = {
	name        = "TF2 Class Restrictions",
	author      = "Tsunami",
	description = "Restrict classes in TF2.",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

new g_iClass[MAXPLAYERS + 1];
new g_iClients;
new Handle:g_hEnabled;
new Handle:g_hImmunity;
new Handle:g_hLimits[4][10];
new String:g_sSounds[10][32] = {"", "vo/scout_no03.wav",   "vo/sniper_no04.wav", "vo/soldier_no01.wav",
																		"vo/demoman_no03.wav", "vo/medic_no03.wav",  "vo/heavy_no02.wav",
																		"vo/pyro_no01.wav",    "vo/spy_no02.wav",    "vo/engineer_no03.wav"};

public OnPluginStart() {
	CreateConVar("sm_classrestrict_version", PL_VERSION, "Restrict classes in TF2.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled       = CreateConVar("sm_classrestrict_enabled",       "1",  "Enable/disable restricting classes in TF2.");
	g_hImmunity      = CreateConVar("sm_classrestrict_immunity",      "0",  "Enable/disable admin immunity for restricted classes in TF2.");
	g_hLimits[2][1]  = CreateConVar("sm_classrestrict_red_scouts",    "-1", "Limit for Red scouts in TF2.");
	g_hLimits[2][2]  = CreateConVar("sm_classrestrict_red_snipers",   "-1", "Limit for Red snipers in TF2.");
	g_hLimits[2][3]  = CreateConVar("sm_classrestrict_red_soldiers",  "-1", "Limit for Red soldiers in TF2.");
	g_hLimits[2][4]  = CreateConVar("sm_classrestrict_red_demomen",   "-1", "Limit for Red demomen in TF2.");
	g_hLimits[2][5]  = CreateConVar("sm_classrestrict_red_medics",    "-1", "Limit for Red medics in TF2.");
	g_hLimits[2][6]  = CreateConVar("sm_classrestrict_red_heavies",   "-1", "Limit for Red heavies in TF2.");
	g_hLimits[2][7]  = CreateConVar("sm_classrestrict_red_pyros",     "-1", "Limit for Red pyros in TF2.");
	g_hLimits[2][8]  = CreateConVar("sm_classrestrict_red_spies",     "-1", "Limit for Red spies in TF2.");
	g_hLimits[2][9]  = CreateConVar("sm_classrestrict_red_engineers", "-1", "Limit for Red engineers in TF2.");
	g_hLimits[3][1]  = CreateConVar("sm_classrestrict_blu_scouts",    "-1", "Limit for Blu scouts in TF2.");
	g_hLimits[3][2]  = CreateConVar("sm_classrestrict_blu_snipers",   "-1", "Limit for Blu snipers in TF2.");
	g_hLimits[3][3]  = CreateConVar("sm_classrestrict_blu_soldiers",  "-1", "Limit for Blu soldiers in TF2.");
	g_hLimits[3][4]  = CreateConVar("sm_classrestrict_blu_demomen",   "-1", "Limit for Blu demomen in TF2.");
	g_hLimits[3][5]  = CreateConVar("sm_classrestrict_blu_medics",    "-1", "Limit for Blu medics in TF2.");
	g_hLimits[3][6]  = CreateConVar("sm_classrestrict_blu_heavies",   "-1", "Limit for Blu heavies in TF2.");
	g_hLimits[3][7]  = CreateConVar("sm_classrestrict_blu_pyros",     "-1", "Limit for Blu pyros in TF2.");
	g_hLimits[3][8]  = CreateConVar("sm_classrestrict_blu_spies",     "-1", "Limit for Blu spies in TF2.");
	g_hLimits[3][9]  = CreateConVar("sm_classrestrict_blu_engineers", "-1", "Limit for Blu engineers in TF2.");
	
	HookEvent("player_changeclass", Event_ChangeClass);
	HookEvent("player_spawn",       Event_PlayerSpawn);
	HookEvent("player_team",        Event_ChangeTeam);
}

public OnMapStart() {
	decl i, String:sSound[40];
	for (i = 1; i < sizeof(g_sSounds); i++) {
		Format(sSound, sizeof(sSound), "sound/%s", g_sSounds[i]);
		PrecacheSound(g_sSounds[i]);
		AddFileToDownloadsTable(sSound);
	}
	
	g_iClients       = GetMaxClients();
}

public OnClientPutInServer(client) {
	g_iClass[client] = 0;
}

public Event_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast) {
	new iClient      = GetClientOfUserId(GetEventInt(event, "userid")),
			iClass       = GetEventInt(event, "class"),
			iTeam        = GetClientTeam(iClient);
	
	if (IsFull(iTeam, iClass) && !IsImmune(iClient)) {
		TF2_SetPlayerClass(iClient,TFClass_Unknown);
		ShowVGUIPanel(iClient, iTeam == 3 ? "class_blue" : "class_red");
		EmitSoundToClient(iClient, g_sSounds[iClass]);
	}
}

public Event_ChangeTeam(Handle:event,  const String:name[], bool:dontBroadcast) {
	new iClient      = GetClientOfUserId(GetEventInt(event, "userid")),
			iTeam        = GetEventInt(event, "team");
	
	if (IsFull(iTeam, g_iClass[iClient]) && !IsImmune(iClient)) {
		TF2_SetPlayerClass(iClient,TFClass_Unknown);
		ShowVGUIPanel(iClient, iTeam == 3 ? "class_blue" : "class_red");
		PickClass(iClient);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new iClient      = GetClientOfUserId(GetEventInt(event, "userid")),
			iTeam        = GetClientTeam(iClient);
	g_iClass[iClient] = _:TF2_GetPlayerClass(iClient);
	
	if (IsFull(iTeam, g_iClass[iClient]) && !IsImmune(iClient)) {
		TF2_SetPlayerClass(iClient,TFClass_Unknown);
		ShowVGUIPanel(iClient, iTeam == 3 ? "class_blue" : "class_red");
		PickClass(iClient);
	}
}

bool:IsFull(iTeam, iClass) {
	if (GetConVarBool(g_hEnabled) && iTeam > 1 && iClass > 0) {
		new iCount = 0, iLimit = GetConVarInt(g_hLimits[iTeam][iClass]);
		if (iLimit > 0) {
			for (new i = 1; i <= g_iClients; i++) {
				if (IsClientInGame(i) && GetClientTeam(i) == iTeam && _:TF2_GetPlayerClass(i) == iClass && ++iCount == iLimit) {
					return true;
				}
			}
		} else if (iLimit == 0) {
			return true;
		}
	}
	
	return false;
}

bool:IsImmune(iClient) {
	return GetConVarBool(g_hImmunity) && GetUserFlagBits(iClient) & (ADMFLAG_GENERIC|ADMFLAG_ROOT);
}

PickClass(iClient) {
	new i = GetRandomInt(1, 9), iClass = i, iTeam = GetClientTeam(iClient);
	for (;;) {
		if (!IsFull(iTeam, i))  {
			TF2_SetPlayerClass(iClient, TFClassType:i);
			TF2_RespawnPlayer(iClient);
			g_iClass[iClient] = i;
			break;
		} else if (++i >= 9)    {
			i = 1;
		} else if (i == iClass) {
			break;
		}
	}
}