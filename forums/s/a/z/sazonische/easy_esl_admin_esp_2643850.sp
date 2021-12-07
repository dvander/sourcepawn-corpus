#pragma semicolon 1 
#pragma newdecls required

#define IsValidClient(%0) 				(1 <= %0 <= MaxClients && IsClientInGame(%0) && !IsFakeClient(%0) && !IsClientSourceTV(%0) && !IsClientReplay(%0))

int user_flag;

ConVar AdminESPflag = null;

ConVar sv_competitive_official_5v5;
ConVar mp_weapons_glow_on_ground;

public Plugin myinfo = {
	name        = "CS:GO Easy Esl Admin ESP (mmcs.pro)",
	author      = "SAZONISCHE",
	description = "Spec only ESP/WH for Admins",
	version     = "1.3",
	url         = "https://mmcs.pro/"
};

public void OnPluginStart() {
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin works only on CS:GO");

	sv_competitive_official_5v5 = FindConVar("sv_competitive_official_5v5");
	mp_weapons_glow_on_ground = FindConVar("mp_weapons_glow_on_ground");

	AdminESPflag = CreateConVar("sm_esl_adminesp_flag", "d", "Admin flag, blank=any flag", FCVAR_NOTIFY);
	AdminESPflag.AddChangeHook(OnCvarChanged);
	AutoExecConfig(true, "easy_esl_admin_esp");

	HookEvent("player_team", ReloadEvent);
	HookEvent("player_spawn", ReloadEvent);
}

public void OnMapStart() {
	char m_BaseFlags[32];
	GetConVarString(AdminESPflag, m_BaseFlags, sizeof(m_BaseFlags));
	user_flag = ReadFlagString(m_BaseFlags);
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (convar == AdminESPflag) {
		user_flag = ReadFlagString(newValue);
		for (int client = 1; client <= MaxClients; client++)
			if (IsValidClient(client))
				SetSpecEsp(client, false);
	}
}

public Action ReloadEvent(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && (GetUserFlagBits(client) & (user_flag|ADMFLAG_ROOT))) {
		switch (name[7]) {
			case 't':{

				int team = event.GetInt("team");
				if (team >= 2) {
					SetSpecEsp(client, false);
				} else if (team <= 1) {
					SetSpecEsp(client, true);
				}
			}
			case 's':{
				if (IsPlayerAlive(client)) {
					SetSpecEsp(client, false);
				}
			}			
		}
	}
	return Plugin_Continue;
}

public bool SetSpecEsp(int client, bool value) {
	SendConVarValue(client, mp_weapons_glow_on_ground, value ? "1" : "0");
	SendConVarValue(client, sv_competitive_official_5v5, value ? "1" : "0");
}