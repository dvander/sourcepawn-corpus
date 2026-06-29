#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

//sky names https://developer.valvesoftware.com/wiki/Sky_List#Insurgency
char ga_sSkyName[][] = {
	"sky_buhriz_",
	"!_market_",
	"!_ramadinight_",
	"!mastk_test_",
	"af_range_sunset_",
	"af_sky_mountains_",
	"ins_mino",
	"mino_sky01",
	"nightsky_lfw_",
	"sibenik_sql_",
	"sky_ascari01",
	"sky_day01_07_fog",
	"sky_height_",
	"sky_insurgency03",
	"sky_insurgency04",
	"sky_panj_night_",
	"sky_peak",
	"sky_sandstorm01",
	"sky_sunrise_fog",
	"sky_uprising",
	"sky_uprising_hunt",
	"so_sky_01",
	"so_sky_02"
};

bool	g_bEventHooked = false;
char	g_sDefaultSky[32];
ConVar	g_cvWhenToSet;

public Plugin myinfo = {
	name		= "randomsky",
	author		= "Nullifidian & idea by painkiller",
	description	= "set random sky",
	version		= "1.0",
	url			= ""
};

public void OnPluginStart() {
	RegAdminCmd("sm_randomskysetting", cmd_CheckSky, ADMFLAG_BAN, "Print default & current sky setting for this map");
	RegAdminCmd("sm_randomskyrandom", cmd_RandomSky, ADMFLAG_BAN, "Set sky to new random");
	RegAdminCmd("sm_randomskydefault", cmd_DefaultSky, ADMFLAG_BAN, "Set sky to default setting");

	g_cvWhenToSet = CreateConVar("sm_randomsky", "1.0", "0.0 = disable | 1.0 = on map start | 2.0 = on round start", _, true, 0.0, true, 2.0);
	AutoExecConfig(true, "randomsky");
	HookConVarChange(g_cvWhenToSet, ConVarChanged);
}

public void OnMapStart() {
	CreateTimer(1.0, Timer_CheckSetting);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	SetRandomSky();
}

void SetRandomSky() {
	ServerCommand("sv_skyname %s", ga_sSkyName[GetRandomInt(0, ((sizeof(ga_sSkyName)) - 1))]);
}

Action Timer_CheckSetting(Handle timer) {
	GetConVarString(FindConVar("sv_skyname"), g_sDefaultSky, sizeof(g_sDefaultSky));
	switch (g_cvWhenToSet.FloatValue) {
		case 0.0: {
			if (g_bEventHooked) {
				SetupHookEvent(false);
			}
		}
		case 1.0: {
			if (g_bEventHooked) {
				SetupHookEvent(false);
			}
			SetRandomSky();
		}
		case 2.0: {
			if (!g_bEventHooked) {
				SetupHookEvent();
			}
		}
	}
}

void SetupHookEvent(bool bHook = true) {
	if (bHook) {
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		g_bEventHooked = true;
	} else {
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		g_bEventHooked = false;
	}
}

public Action cmd_CheckSky(int client, int args) {
	char sBuffer[32];
	GetConVarString(FindConVar("sv_skyname"), sBuffer, sizeof(sBuffer));
	ReplyToCommand(client, "sv_skyname = %s | default = %s", sBuffer, g_sDefaultSky);
	return Plugin_Handled;
}

public Action cmd_RandomSky(int client, int args) {
	SetRandomSky();
	char sBuffer[32];
	GetConVarString(FindConVar("sv_skyname"), sBuffer, sizeof(sBuffer));
	ReplyToCommand(client, "Set sky to: %s", sBuffer);
	return Plugin_Handled;
}

public Action cmd_DefaultSky(int client, int args) {
	ServerCommand("sv_skyname %s", g_sDefaultSky);
	ReplyToCommand(client, "Set sky to default: %s", g_sDefaultSky);
	return Plugin_Handled;
}

void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (StringToFloat(newValue) == 2.0) {
		if (!g_bEventHooked) {
			SetupHookEvent();
		}
	}
	else if (g_bEventHooked) {
		SetupHookEvent(false);
	}
}