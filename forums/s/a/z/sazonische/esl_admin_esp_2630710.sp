#include <sourcemod>
#include <sendproxy>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "3.2"

int iFlag;
bool bEnableWeaponGlow;

ConVar sv_competitive_official_5v5,
	mp_weapons_glow_on_ground,
	sv_parallel_send,
	sv_parallel_sendsnapshot,
	sv_parallel_packentities,
	sm_esl_adminesp_flag,
	sm_esl_adminesp_weapons_glow_on_ground;

public Plugin myinfo = {
	name        = "CS:GO Esl Admin ESP (mmcs.pro)",
	author      = "SAZONISCHE",
	description = "ESP/WH for Admins",
	version     = PLUGIN_VERSION,
	url         = "https://mmcs.pro/"
};

public void OnPluginStart() {
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin works only on CS:GO. Disabling plugin...");

	CreateConVar("sm_esl_adminesp_version", PLUGIN_VERSION, "Version of CS:GO Esl Admin ESP", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	(sm_esl_adminesp_flag = CreateConVar("sm_esl_adminesp_flag", "d", "Admin flag, blank=any flag", FCVAR_NOTIFY)).AddChangeHook(OnCvarChanged);
	OnCvarChanged(sm_esl_adminesp_flag, NULL_STRING, NULL_STRING);
	(sm_esl_adminesp_weapons_glow_on_ground = CreateConVar("sm_esl_adminesp_weapons_glow_on_ground", "1", "Enable glow weapons on ground", 0, true, 0.0, true, 1.0)).AddChangeHook(OnCvarChanged);
	OnCvarChanged(sm_esl_adminesp_weapons_glow_on_ground, NULL_STRING, NULL_STRING);
	AutoExecConfig(true, "esl_admin_esp");

	sv_competitive_official_5v5 = FindConVar("sv_competitive_official_5v5");
	mp_weapons_glow_on_ground = FindConVar("mp_weapons_glow_on_ground");

	(sv_parallel_send = FindConVar("sv_parallel_send")).AddChangeHook(OnCvarChanged);
	OnCvarChanged(sv_parallel_send, NULL_STRING, NULL_STRING);
	(sv_parallel_sendsnapshot = FindConVar("sv_parallel_sendsnapshot")).AddChangeHook(OnCvarChanged);
	OnCvarChanged(sv_parallel_sendsnapshot, NULL_STRING, NULL_STRING);
	(sv_parallel_packentities = FindConVar("sv_parallel_packentities")).AddChangeHook(OnCvarChanged);
	OnCvarChanged(sv_parallel_packentities, NULL_STRING, NULL_STRING);

	AutoExecConfig(true, "esl_admin_esp");
	
	HookEvent("player_death", ReloadEvent);
	HookEvent("player_team", ReloadEvent);
	HookEvent("player_spawn", ReloadEvent);
	HookEvent("player_spawned", ReloadEvent); // дебилизм валв происходит только после pending team или в данный момент (обязательно дублировать если используем player_spawn)
}

public void OnClientDisconnect(int client) {
	if (!IsFakeClient(client)) 
		SetEspHook(client, false);
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (convar == sm_esl_adminesp_flag) {
		char szFlag[16];
		convar.GetString(szFlag, sizeof(szFlag));
		iFlag = ReadFlagString(szFlag);

		for (int client = 1; client <= GetMaxHumanPlayers(); client++) {
			if (IsValidClient(client)) {
				SetEspHook(client, false);
				SetEspClient(client, false);
			}
		}

	} else if (convar == sm_esl_adminesp_weapons_glow_on_ground) {
		bEnableWeaponGlow = convar.BoolValue;
	} else if (convar == sv_parallel_send && StringToInt(newValue) == 1) {
		convar.IntValue = 0; 
	} else if (convar == sv_parallel_sendsnapshot && StringToInt(newValue) == 1) {
		convar.IntValue = 0; 
	} else if (convar == sv_parallel_packentities && StringToInt(newValue) == 1) {
		convar.IntValue = 0; 
	}
}

public Action ReloadEvent(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client)) {
		int bits = GetUserFlagBits(client);
		switch (name[7]) {
			case 'd':{
				if(bits & (iFlag|ADMFLAG_ROOT)) {
					SetEspHook(client, true);
					SetEspClient(client, true);
				}
			}
			case 't':{
				int team = event.GetInt("team");
				if (team >= 2 && IsPlayerAlive(client)) {
					SetEspHook(client, false);
					SetEspClient(client, false);
				} else if (team <= 1 && (bits & (iFlag|ADMFLAG_ROOT))) {
					SetEspHook(client, false);
					SetEspClient(client, true);
				} else if (bits & (iFlag|ADMFLAG_ROOT)) {
					SetEspHook(client, true);
					SetEspClient(client, true);
				}
			}
			case 's':{
				if (IsPlayerAlive(client)) {
					SetEspHook(client, false);
					if (bits & (iFlag|ADMFLAG_ROOT))
						SetEspClient(client, false);
				}
			}
		}
	}
	return Plugin_Continue;
}

public bool SetEspHook(int client, bool value) {
	if (value) {
		if (!SendProxy_IsHooked(client, "m_iTeamNum"))
			SendProxy_Hook(client, "m_iTeamNum", Prop_Int, Set_Esp);
	} else {
		if (SendProxy_IsHooked(client, "m_iTeamNum"))
			SendProxy_Unhook(client, "m_iTeamNum", Set_Esp);
	}
}

public bool SetEspClient(int client, bool value) {
	if(bEnableWeaponGlow)
		mp_weapons_glow_on_ground.ReplicateToClient(client, value ? "1" : "0");
	sv_competitive_official_5v5.ReplicateToClient(client, value ? "1" : "0");
}

public Action Set_Esp(int entity, const char[] PropName, int &iValue, int element) {
	if (iValue) {
		iValue = 1;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client) {
	return 0 < client && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}
