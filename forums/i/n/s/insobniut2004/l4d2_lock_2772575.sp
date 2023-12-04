#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <glow>
#include <multicolors>


#define FENCE_MODEL01 "models/props_wasteland/exterior_fence003b.mdl"
#define FENCE_MODEL02 "models/props_street/police_barricade.mdl"
#define FENCE_MODEL03 "models/props_street/police_barricade3.mdl"
#define FENCE_MODEL04 "models/props_street/police_barricade4.mdl"
#define FENCE_MODEL05 "models/props_wasteland/exterior_fence001a.mdl"
#define FENCE_MODEL06 "models/props_fortifications/barricade001_128_reference.mdl"
#define FENCE_MODEL07 "models/props_wasteland/exterior_fence_notbarbed002c.mdl"
#define FENCE_MODEL08 "models/props_wasteland/exterior_fence_notbarbed002b.mdl"
#define FENCE_MODEL09 "models/props_wasteland/exterior_fence_notbarbed002d.mdl"
#define FENCE_MODEL10 "models/props_wasteland/exterior_fence_notbarbed002f.mdl"
#define FENCE_MODEL11 "models/props_wasteland/exterior_fence_notbarbed002e.mdl"
#define FENCE_MODEL12 "models/props_urban/fence_cover001_256.mdl"
#define FENCE_MODEL13 "models/props_exteriors/roadsidefence_512.mdl"
#define FENCE_MODEL14 "models/props_exteriors/roadsidefence_64.mdl"


int OFFSET_LOCKED,
SaferoomDoor,
g_iCooldown,
g_iRoundCounter,
clientTimeout[66];

bool g_bLocked,
g_bTempBlock,
gbFirstItemPickedUp,
isClientLoading[66];

ConVar cvarLockRoundOne,
cvarLockRoundTwo,
cvarLockGlowRange,
cvarLockHintText,
cvarLockNotify,
cvarClientTimeOut,
g_hStopbots;
Handle g_IsCheckpointDoorOpened;

char cmap[64];

public Plugin myinfo = {
 name = "L4D2 Lock",
 author = "Foxhound27",
 description = "This plugin allows you to control - lock the doors and path (Coop Only)",
 version = "2020",
 url = "https://forums.alliedmods.net/showthread.php?t=303311"
};


//Some sources used to make this plugin > drow, eyal282, Legend < & > me ofc lol ><>.


public void OnPluginStart() {

	OFFSET_LOCKED = FindSendPropInfo("CPropDoorRotatingCheckpoint", "m_bLocked");
	RegAdminCmd("sm_lock", CmdLock, ADMFLAG_ROOT, "lock the door");
	RegAdminCmd("sm_unlock", CmdUnLock, ADMFLAG_ROOT, "unlock the door");
	g_IsCheckpointDoorOpened = CreateGlobalForward("Lock_CheckpointDoorStartOpened", ET_Ignore);
	HookEvent("player_left_checkpoint", Event_LeftSaferoom, EventHookMode_Pre);
	HookEvent("player_team", Event_Join_Team, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("door_unlocked", Event_DoorUnlocked, EventHookMode_Pre);
	HookEvent("item_pickup", Event_RoundStartAndItemPickup, EventHookMode_Pre);
	cvarLockRoundOne = CreateConVar("l4d2_lock_roundone", "40", "How long the door is locked on round 1 - this round takes longer to load. (Default: 40)");
	cvarLockRoundTwo = CreateConVar("l4d2_lock_roundtwo", "30", "How long the door is locked on round two. (Default: 30)");
	cvarLockGlowRange = CreateConVar("l4d2_lock_glowrange", "800", "How far the glow ranges off of the saferoom door. (Default: 800)");
	cvarLockHintText = CreateConVar("l4d2_lock_hinttext", "0", "Does the plugin print the countdown in center screen? (Default: 0)");
	cvarLockNotify = CreateConVar("l4d2_lock_notify", "10", "What time to notify the players about the door going to open. (Default: 10)");
	cvarClientTimeOut = CreateConVar("l4d2_lock_timeout", "30", "Seconds will wait after a map starts waiting for players. (Default: 30)");
	g_hStopbots = FindConVar("sb_move");

    AutoExecConfig(true, "l4d2_lock");

	ClearVariables();

}

public void OnMapStart() {

	if (!IsModelPrecached(FENCE_MODEL01)) {
		PrecacheModel(FENCE_MODEL01, true);
	}
	if (!IsModelPrecached(FENCE_MODEL02)) {
		PrecacheModel(FENCE_MODEL02, true);
	}
	if (!IsModelPrecached(FENCE_MODEL03)) {
		PrecacheModel(FENCE_MODEL03, true);
	}
	if (!IsModelPrecached(FENCE_MODEL04)) {
		PrecacheModel(FENCE_MODEL04, true);
	}
	if (!IsModelPrecached(FENCE_MODEL05)) {
		PrecacheModel(FENCE_MODEL05, true);
	}
	if (!IsModelPrecached(FENCE_MODEL06)) {
		PrecacheModel(FENCE_MODEL06, true);
	}
	if (!IsModelPrecached(FENCE_MODEL07)) {
		PrecacheModel(FENCE_MODEL07, true);
	}
	if (!IsModelPrecached(FENCE_MODEL08)) {
		PrecacheModel(FENCE_MODEL08, true);
	}
	if (!IsModelPrecached(FENCE_MODEL09)) {
		PrecacheModel(FENCE_MODEL09, true);
	}
	if (!IsModelPrecached(FENCE_MODEL10)) {
		PrecacheModel(FENCE_MODEL10, true);
	}
	if (!IsModelPrecached(FENCE_MODEL11)) {
		PrecacheModel(FENCE_MODEL11, true);
	}
	if (!IsModelPrecached(FENCE_MODEL12)) {
		PrecacheModel(FENCE_MODEL12, true);
	}
	if (!IsModelPrecached(FENCE_MODEL13)) {
		PrecacheModel(FENCE_MODEL13, true);
	}
	if (!IsModelPrecached(FENCE_MODEL14)) {
		PrecacheModel(FENCE_MODEL14, true);
	}

	GetCurrentMap(cmap, sizeof(cmap));	
	g_iRoundCounter = 1;
	ClearVariables();

}


stock CheatCommand(int client = 0, char[] command, char[] arguments = "") {
	if (!client || !IsClientInGame(client)) {
		for (int target = 1; target <= MaxClients; target++) {
			if (IsClientInGame(target)) {
				client = target;
				break;
			}
		}
		if (!client || !IsClientInGame(client)) {
			return;
		}
	}

	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast) {
	ClearVariables();
	gbFirstItemPickedUp = false;
	g_bLocked = true;
	g_bTempBlock = false;
}

public Action Event_RoundStartAndItemPickup(Handle event, const char[] name, bool dontBroadcast) {
	if (!gbFirstItemPickedUp) {
		gbFirstItemPickedUp = true;
		CreateTimer(0.2, PluginStartSequence01);
	}
	if (!g_bTempBlock) {
		g_bTempBlock = true;
		CreateTimer(1.0, LockSafeRoom);
	}
}


StopBots() {
	SetConVarString(g_hStopbots, "0");
}

StartBots() {
	SetConVarString(g_hStopbots, "1");
}

stock isBugged() {
 char mapname[128];
 GetCurrentMap(mapname, sizeof(mapname));
 if ((StrEqual(mapname, "c1m2_streets", false)) || (StrEqual(mapname, "c1m2d_streets", false)) || (StrEqual(mapname, "c1m3_mall", false)) || (StrEqual(mapname, "c1m3d_mall", false)) || (StrEqual(mapname, "c1m4_atrium", false)) || (StrEqual(mapname, "c1m4d_atrium", false)) ||
  (StrEqual(mapname, "c2m2_fairgrounds", false)) || (StrEqual(mapname, "c2m3_coaster", false)) || (StrEqual(mapname, "c2m4_barns", false)) || (StrEqual(mapname, "c2m5_concert", false)) ||
  (StrEqual(mapname, "c3m2_swamp", false)) || (StrEqual(mapname, "c3m3_shantytown", false)) || (StrEqual(mapname, "c3m4_plantation", false)) ||
  (StrEqual(mapname, "c4m2_sugarmill_a", false)) || (StrEqual(mapname, "c4m3_sugarmill_b", false)) || (StrEqual(mapname, "c4m4_milltown_b", false)) || (StrEqual(mapname, "c4m5_milltown_escape", false)) ||
  (StrEqual(mapname, "c5m2_park", false)) || (StrEqual(mapname, "c5m3_cemetery", false)) || (StrEqual(mapname, "c5m4_quarter", false)) || (StrEqual(mapname, "c5m5_bridge", false)) ||
  (StrEqual(mapname, "c6m2_bedlam", false)) || (StrEqual(mapname, "c6m3_port", false)) ||
  (StrEqual(mapname, "c7m2_barge", false)) || (StrEqual(mapname, "c7m3_port", false)) ||
  (StrEqual(mapname, "cwm2_warehouse", false)) || (StrEqual(mapname, "cwm3_drain", false)) || (StrEqual(mapname, "cwm4_building", false)) ||
  (StrEqual(mapname, "c1_2_jam", false)) || (StrEqual(mapname, "c1_3_school", false)) || (StrEqual(mapname, "c1_4_roof_safe", false)) ||
  (StrEqual(mapname, "gasfever_2", false)) || (StrEqual(mapname, "gasfever_3", false)) ||
  (StrEqual(mapname, "c1_mario1_2", false)) || (StrEqual(mapname, "c1_mario1_3", false)) || (StrEqual(mapname, "c1_mario1_4", false)) ||
  (StrEqual(mapname, "lost02_", false)) || (StrEqual(mapname, "lost03", false)) || (StrEqual(mapname, "lost04", false)) || (StrEqual(mapname, "lost02_1", false)) || (StrEqual(mapname, "lost02_2", false)) ||
  (StrEqual(mapname, "bwm2_city")) || (StrEqual(mapname, "bwm3_forest")) || (StrEqual(mapname, "bwm4_rooftops")) || (StrEqual(mapname, "bwm5_bridge")) ||
  (StrEqual(mapname, "l4d2_pasiri2", false)) || (StrEqual(mapname, "l4d2_pasiri3", false)) || (StrEqual(mapname, "l4d2_pasiri4", false)) ||
  (StrEqual(mapname, "l4d2_forest")) || (StrEqual(mapname, "l4d2_tracks")) || (StrEqual(mapname, "l4d2_cave")) || (StrEqual(mapname, "l4d2_backtoboat")) ||
  (StrEqual(mapname, "cbm2_town")) || (StrEqual(mapname, "cbm3_bunker")) ||
  (StrEqual(mapname, "l4d2_garage02_lots_a")) || (StrEqual(mapname, "l4d2_garage02_lots_b")) || (StrEqual(mapname, "l4d2_garage01_alleys_b")) || (StrEqual(mapname, "l4d2_garage01_alleys_escape")) ||
  (StrEqual(mapname, "rivermotel")) || (StrEqual(mapname, "outskirts")) || (StrEqual(mapname, "cityhall")) ||
  (StrEqual(mapname, "jsarena202_alley")) || (StrEqual(mapname, "jsarena203_roof")) || (StrEqual(mapname, "jsarena204_arena")) ||
  (StrEqual(mapname, "ch_map2_temple")) ||
  (StrEqual(mapname, "devilscorridor")) || (StrEqual(mapname, "surface")) || (StrEqual(mapname, "ftlostonahill")) || (StrEqual(mapname, "goingup")) ||
  (StrEqual(mapname, "l4d2_win2")) || (StrEqual(mapname, "l4d2_win3")) || (StrEqual(mapname, "l4d2_win4")) || (StrEqual(mapname, "l4d2_win5")) || (StrEqual(mapname, "l4d2_win6")) ||
  (StrEqual(mapname, "QE_2_remember_me")) || (StrEqual(mapname, "qe_2_remember_me")) || (StrEqual(mapname, "QE_3_unorthodox_paradox")) || (StrEqual(mapname, "qe_3_unorthodox_paradox")) || (StrEqual(mapname, "QE_4_ultimate_test")) || (StrEqual(mapname, "qe_4_ultimate_test")) ||
  (StrEqual(mapname, "gridmap2")) || (StrEqual(mapname, "gridmap3")) || (StrEqual(mapname, "grid4")) ||
  (StrEqual(mapname, "l4d2_pdmesa02_shafted")) || (StrEqual(mapname, "l4d2_pdmesa03_office")) || (StrEqual(mapname, "l4d2_pdmesa04_pointinsert")) || (StrEqual(mapname, "l4d2_pdmesa05_returntoxen")) || (StrEqual(mapname, "l4d2_pdmesa06_xen")) ||
  (StrEqual(mapname, "carnage_basement", false)) || (StrEqual(mapname, "carnage_warehouse", false)) ||
  (StrEqual(mapname, "l4d2_naniwa02_arcade", false)) || (StrEqual(mapname, "l4d2_naniwa03_highway", false)) || (StrEqual(mapname, "l4d2_naniwa04_subway", false)) || (StrEqual(mapname, "l4d2_naniwa05_tower", false)) ||
  (StrEqual(mapname, "dead_death_03", false)) || (StrEqual(mapname, "dead_death_01", false)) || (StrEqual(mapname, "reactor_02_core", false)) ||
  (StrEqual(mapname, "forest_beta407", false)) ||
  (StrEqual(mapname, "2019_M1b", false)) || (StrEqual(mapname, "2019_m1b", false)) || (StrEqual(mapname, "2019_M2b", false)) || (StrEqual(mapname, "2019_m2b", false)) || (StrEqual(mapname, "2019_M3b", false)) || (StrEqual(mapname, "2019_m3b", false)) ||
  (StrEqual(mapname, "l4d2_ravenholmwar_2", false)) || (StrEqual(mapname, "l4d2_ravenholmwar_3", false)) ||
  (StrEqual(mapname, "c8m2_subway_daytime", false)) || (StrEqual(mapname, "c8m3_sewers_daytime", false)) || (StrEqual(mapname, "c8m4_interior_witchesday", false)) || (StrEqual(mapname, "c8m5_rooftop_daytime", false)) ||
  (StrEqual(mapname, "soi_m2_museum", false)) || (StrEqual(mapname, "soi_m3_biolab", false)) || (StrEqual(mapname, "soi_m4_underground", false))) {
  return true;
 }
 return false;
}

stock isBugged2() {
 char mapname[128];
 GetCurrentMap(mapname, sizeof(mapname));
 if ((StrEqual(mapname, "c8m2_subway", false)) || (StrEqual(mapname, "l4d2_hospital02_subway")) || (StrEqual(mapname, "c8m3_sewers", false)) || (StrEqual(mapname, "l4d2_hospital03_sewers")) || (StrEqual(mapname, "c8m4_interior", false)) || (StrEqual(mapname, "l4d2_hospital04_interior")) || (StrEqual(mapname, "c8m5_rooftop", false)) || (StrEqual(mapname, "l4d2_hospital05_rooftop")) ||
  (StrEqual(mapname, "c9m2_lots", false)) || (StrEqual(mapname, "c9m2_lots_daytime", false)) ||
  (StrEqual(mapname, "c10m2_drainage", false)) || (StrEqual(mapname, "l4d2_smalltown02_drainage", false)) || (StrEqual(mapname, "c10m3_ranchhouse", false)) || (StrEqual(mapname, "l4d2_smalltown03_ranchhouse", false)) || (StrEqual(mapname, "c10m4_mainstreet", false)) || (StrEqual(mapname, "l4d2_smalltown04_mainstreet", false)) || (StrEqual(mapname, "c10m5_houseboat", false)) || (StrEqual(mapname, "l4d2_smalltown05_houseboat", false)) ||
  (StrEqual(mapname, "c11m2_offices", false)) || (StrEqual(mapname, "c11m3_garage", false)) || (StrEqual(mapname, "c11m4_terminal", false)) || (StrEqual(mapname, "c11m5_runway", false)) ||
  (StrEqual(mapname, "c12m2_traintunnel", false)) || (StrEqual(mapname, "c12m3_bridge", false)) || (StrEqual(mapname, "c12m4_barn", false)) || (StrEqual(mapname, "c12m5_cornfield", false)) ||
  (StrEqual(mapname, "c13m2_southpinestream", false)) || (StrEqual(mapname, "c13m3_memorialbridge", false)) || (StrEqual(mapname, "c13m4_cutthroatcreek", false)) ||
  (StrEqual(mapname, "l4d2_city17_02", false)) || (StrEqual(mapname, "l4d2_city17_03", false)) || (StrEqual(mapname, "l4d2_city17_04", false)) || (StrEqual(mapname, "l4d2_city17_05", false)) ||
  (StrEqual(mapname, "jsgone02_end", false)) ||
  (StrEqual(mapname, "wth_2", false)) || (StrEqual(mapname, "wth_3", false)) || (StrEqual(mapname, "wth_4", false)) || (StrEqual(mapname, "wth_5", false)) ||
  (StrEqual(mapname, "l4d2_darkblood02_engine", false)) || (StrEqual(mapname, "l4d2_darkblood03_platform", false)) || (StrEqual(mapname, "l4d2_darkblood04_extraction", false)) ||
  (StrEqual(mapname, "left4cake201_start", false)) || (StrEqual(mapname, "left4cake202_dos", false)) || (StrEqual(mapname, "left4cake203_tres", false)) ||
  (StrEqual(mapname, "c13m2_southpinestream_night", false)) || (StrEqual(mapname, "c13m3_memorialbridge_night", false)) || (StrEqual(mapname, "c13m4_cutthroatcreek_night", false)) ||
  (StrEqual(mapname, "p84m2_train", false)) || (StrEqual(mapname, "p84m3_clubd", false)) || (StrEqual(mapname, "p84m4_precinct", false)) ||
  (StrEqual(mapname, "l4d2_draxmap2", false)) || (StrEqual(mapname, "l4d2_draxmap3", false)) || (StrEqual(mapname, "l4d2_draxmap4", false)) ||
  (StrEqual(mapname, "l4d2_forest_vs")) || (StrEqual(mapname, "l4d2_tracks_vs")) || (StrEqual(mapname, "l4d2_cave_vs")) || (StrEqual(mapname, "l4d2_backtoboat_vs")) ||
  (StrEqual(mapname, "l4d2_coldfear02_factory")) || (StrEqual(mapname, "l4d2_coldfear03_officebuilding")) || (StrEqual(mapname, "l4d2_coldfear04_roffs")) || (StrEqual(mapname, "l4d2_coldfear05_docks")) ||
  (StrEqual(mapname, "hotel")) || (StrEqual(mapname, "station-a")) || (StrEqual(mapname, "station")) ||
  (StrEqual(mapname, "hellishjourney02")) || (StrEqual(mapname, "hellishjourney02_l4d2")) || (StrEqual(mapname, "hellishjourney03")) || (StrEqual(mapname, "hellishjourney03_l4d2")) ||
  (StrEqual(mapname, "uf2_rooftops")) || (StrEqual(mapname, "uf3_harbor")) || (StrEqual(mapname, "uf4_airfield")) ||
  (StrEqual(mapname, "l4d2_orange02_mountain")) || (StrEqual(mapname, "l4d2_orange03_sky")) || (StrEqual(mapname, "l4d2_orange04_rocket")) ||
  (StrEqual(mapname, "l4d2_scream02_goingup")) || (StrEqual(mapname, "l4d2_scream03_rooftops")) || (StrEqual(mapname, "l4d2_scream04_train")) || (StrEqual(mapname, "l4d2_scream05_finale")) ||
  (StrEqual(mapname, "gemarshy02fac")) || (StrEqual(mapname, "gemarshy03aztec")) ||
  (StrEqual(mapname, "QE2_ep2")) || (StrEqual(mapname, "qe2_ep2")) || (StrEqual(mapname, "QE2_ep3")) || (StrEqual(mapname, "qe2_ep3")) || (StrEqual(mapname, "QE2_ep4")) || (StrEqual(mapname, "qe2_ep4")) || (StrEqual(mapname, "QE2_ep5")) || (StrEqual(mapname, "qe2_ep5")) ||
  (StrEqual(mapname, "wfp2_horn")) || (StrEqual(mapname, "wfp3_mill")) || (StrEqual(mapname, "wfp4_commstation")) ||
  (StrEqual(mapname, "l4d2_diescraper2_streets_35")) || (StrEqual(mapname, "l4d2_diescraper3_mid_35")) || (StrEqual(mapname, "l4d2_diescraper4_top_35")) ||
  (StrEqual(mapname, "busbahnhof1", false)) || (StrEqual(mapname, "l4d2_linz_ok", false)) || (StrEqual(mapname, "l4d2_linz_zurueck", false)) || (StrEqual(mapname, "l4d2_linz_bahnhof", false)) ||
  (StrEqual(mapname, "m2_burbs", false)) || (StrEqual(mapname, "m3_crowd_control", false)) || (StrEqual(mapname, "m4_launchpad", false)) || (StrEqual(mapname, "m5_station_finale", false)) ||
  (StrEqual(mapname, "hotel02_sewer_two", false)) || (StrEqual(mapname, "hotel03_ramsey_two", false)) || (StrEqual(mapname, "hotel04_scaling_two", false)) || (StrEqual(mapname, "hotel05_rooftop_two", false)) ||
  (StrEqual(mapname, "blood_hospital_01", false)) || (StrEqual(mapname, "blood_hospital_02", false)) || (StrEqual(mapname, "blood_hospital_03", false)) ||
  (StrEqual(mapname, "c11m2_offices_day", false)) || (StrEqual(mapname, "c11m3_garage_day", false)) || (StrEqual(mapname, "c11m4_terminal_day", false)) || (StrEqual(mapname, "c11m5_runway_day", false)) ||
  (StrEqual(mapname, "l4d2_the_complex_final_02", false)) || (StrEqual(mapname, "l4d2_the_complex_final_03", false)) ||
  (StrEqual(mapname, "l4d2_fallen02_trenches", false)) || (StrEqual(mapname, "l4d2_fallen03_tower", false)) || (StrEqual(mapname, "l4d2_fallen04_cliff", false)) || (StrEqual(mapname, "l4d2_fallen05_shaft", false))) {
  return true;
 }
 return false;
}


public Action LockSafeRoom(Handle timer) {

	if (isBugged() || isBugged2()) {

		char current_map[56];
		GetCurrentMap(current_map, sizeof(current_map));
		if (StrEqual(current_map, "c10m5_houseboat", false)) {
			SaferoomDoor = Now_FindAndLockSaferoomDoor();
		} else {
			decl Float: vSurvivor[3];
			decl Float: vDoor[3];

			for (int i = 1; i <= MaxClients; i++) {

				if (IsClientInGame(i) && GetClientTeam(i) == 2) {
					GetClientAbsOrigin(i, vSurvivor);

					if (vSurvivor[0] != 0 && vSurvivor[1] != 0 && vSurvivor[2] != 0) {
						int iEnt = -1;
						while ((iEnt = FindEntityByClassname(iEnt, "prop_door_rotating_checkpoint")) != -1) {
							if (! (GetEntProp(iEnt, Prop_Data, "m_spawnflags") == 32768)) {
								GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vDoor);
								if (! (GetVectorDistance(vSurvivor, vDoor, false) > 1000)) {
									DispatchKeyValue(iEnt, "spawnflags", "32768");
									if (b_StandartMap()) {
										L4D2_SetEntGlow(iEnt, L4D2Glow_OnLookAt, GetConVarInt(cvarLockGlowRange), 0, {
											255,
											0,
											0
										},
										false);
										SetEntityRenderColor(iEnt, 0, 0, 0, 255);
									}
									HookSingleEntityOutput(iEnt, "OnFullyOpen", OnStartDoorFullyOpened, true);
									SaferoomDoor = iEnt;
								}
							}
						}
					}
				}
			}
			int iEnt = -1;
			while ((iEnt = FindEntityByClassname(iEnt, "prop_door_rotating_checkpoint")) != -1) {
				if (! (GetEntProp(iEnt, Prop_Data, "m_spawnflags") == 32768)) {
					GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vDoor);
					if (! (GetVectorDistance(vSurvivor, vDoor, false) > 1000)) {
						DispatchKeyValue(iEnt, "spawnflags", "32768");
						if (b_StandartMap()) {
							L4D2_SetEntGlow(iEnt, L4D2Glow_OnLookAt, GetConVarInt(cvarLockGlowRange), 0, {
								255,
								0,
								0
							},
							false);
							SetEntityRenderColor(iEnt, 0, 0, 0, 255);
						}
						HookSingleEntityOutput(iEnt, "OnFullyOpen", OnStartDoorFullyOpened, true);
						SaferoomDoor = iEnt;
					}
				}
			}
		}

	} else {
		blockPath();
	}

	return Plugin_Continue;
}


public Action PluginStartSequence01(Handle timer) {
	for (int i = 1; i <= MaxClients; i++) {

		isClientLoading[i] = true;
		clientTimeout[i] = 0;

	}
	CreateTimer(0.2, PluginStartSequence02);
	return Plugin_Continue;
}

stock Now_FindAndLockSaferoomDoor() {
	int ent = -1;
	while ((ent = FindEntityByClassnameEx(ent, "prop_door_rotating_checkpoint")) != -1) {
		if (IsValidEntity(ent)) {
			if (GetEntData(ent, OFFSET_LOCKED, 1)) {
				DispatchKeyValue(ent, "spawnflags", "32768");
				if (b_StandartMap()) {
					L4D2_SetEntGlow(ent, L4D2Glow_OnLookAt, GetConVarInt(cvarLockGlowRange), 0, {
						0,
						255,
						127
					},
					false);
					SetEntityRenderColor(ent, 0, 0, 0, 255);
				}
				HookSingleEntityOutput(ent, "OnFullyOpen", OnStartDoorFullyOpened, true);
				return ent;
			}
		}
	}

	return ent;
}

stock FindEntityByClassnameEx(int startEnt, const char[] classname) {
	while (startEnt > -1 && !IsValidEntity(startEnt)) {
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

stock Now_UnlockSaferoomDoor() {

	if (SaferoomDoor > 0 && IsValidEntity(SaferoomDoor)) {
		DispatchKeyValue(SaferoomDoor, "spawnflags", "8192");
		if (b_StandartMap()) {
			L4D2_SetEntGlow(SaferoomDoor, L4D2Glow_OnLookAt, GetConVarInt(cvarLockGlowRange), 0, {
				0,
				255,
				127
			},
			false);
			SetEntityRenderColor(SaferoomDoor, 0, 0, 0, 255);
		}
	}
	Call_StartForward(g_IsCheckpointDoorOpened);
	Call_Finish();
}

public Action PluginStartSequence02(Handle timer) {
	CreateTimer(1.0, LoadingTimer);
}

public Action LoadingTimer(Handle timer) {

	CreateTimer(1.0, timerLockSwitch, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

}

public Action Event_LeftSaferoom(Handle event, const char[] name, bool dontBroadcast) {
	g_bLocked = false;
}

public Action Event_DoorUnlocked(Handle event, const char[] name, bool dontBroadcast) {
	if (g_bLocked == true) {
		int client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (!IsFakeClient(client) && IsClientInGame(client)) {
			PrintToChat(client, "[DOORLOCK] Door will open in: %i seconds! Please wait.", g_iCooldown);
		}
	}
	return Plugin_Handled;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast) {
	g_iRoundCounter = 2;
	ClearVariables();
	return Plugin_Continue;
}

public Action CmdLock(int client, int args) {
	char class[128];
	int i = MaxClients + 1;
	while (i <= 2048) {
		if (IsValidEntity(i)) {
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "prop_door_rotating_checkpoint", true)) {
				AcceptEntityInput(i, "Close");
				AcceptEntityInput(i, "Lock");
				SetVariantString("spawnflags 40960");
				AcceptEntityInput(i, "AddOutput");
				if (b_StandartMap()) {
					L4D2_SetEntGlow(i, L4D2Glow_OnLookAt, GetConVarInt(cvarLockGlowRange), 0, {
						255,
						0,
						0
					},
					false);
					SetEntityRenderColor(i, 0, 0, 0, 255);
				}
			}
		}
		i++;
	}
	PrintToChat(client, "\x05[\x04DOORLOCK\x05]\x01 Saferoom doors are locked!");
	return Plugin_Handled;
}

stock blockPath() {
	float fnOrigin[3],
	fnAngles[3];
	int fence = CreateEntityByName("prop_dynamic_override");
	SetEntityRenderColor(fence, 0, 0, 0, 255);
	if (StrEqual(cmap, "c1m1_hotel")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL01);

		fnOrigin[0] = 392.003998;
		fnAngles[0] = 0.409058;
		fnOrigin[1] = 5635.555176;
		fnAngles[1] = 178.616119;
		fnOrigin[2] = 2925.031250;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "c2m1_highway")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL04);

		fnOrigin[0] = 10003.427734;
		fnAngles[0] = 6.784813;
		fnOrigin[1] = 7790.717285;
		fnAngles[1] = -179.112259;
		fnOrigin[2] = -516.365295;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "c3m1_plankcountry")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL06);

		fnOrigin[0] = -12486.348633;
		fnAngles[0] = 1.611764;
		fnOrigin[1] = 10438.381836;
		fnAngles[1] = -27.414877;
		fnOrigin[2] = 244.893372;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "c4m1_milltown_a")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL06);

		fnOrigin[0] = -6358.857422;
		fnAngles[0] = 1.356968;
		fnOrigin[1] = 7455.994141;
		fnAngles[1] = 180.000000;
		fnOrigin[2] = 95.031250;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "c5m1_waterfront")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL06);

		fnOrigin[0] = 774.930176;
		fnAngles[0] = 10.659295;
		fnOrigin[1] = 512.853516;
		fnAngles[1] = -89.614487;
		fnOrigin[2] = -468.007050;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "c6m1_riverbank")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL04);

		fnOrigin[0] = 916.505737;
		fnAngles[0] = 0.135685;
		fnOrigin[1] = 3674.522705;
		fnAngles[1] = -89.859390;
		fnOrigin[2] = 93.659073;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "c7m1_docks")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL04);

		fnOrigin[0] = 13365.058594;
		fnAngles[0] = 0.000000;
		fnOrigin[1] = 2152.831299;
		fnAngles[1] = -178.208420;
		fnOrigin[2] = -94.121269;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "c8m1_apartment") || StrEqual(cmap, "l4d2_hospital01_apartment")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL02);

		fnOrigin[0] = 1786.985718;
		fnAngles[0] = -1.221282;
		fnOrigin[1] = 1144.813354;
		fnAngles[1] = -0.271370;
		fnOrigin[2] = 432.031250;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "c9m1_alleys")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL04);

		fnOrigin[0] = -9067.495117;
		fnAngles[0] = -2.968737;
		fnOrigin[1] = -9684.145508;
		fnAngles[1] = -92.191689;
		fnOrigin[2] = -2.509978;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "c11m1_greenhouse")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL08);

		fnOrigin[0] = 6384.835449;
		fnAngles[0] = 0.000000;
		fnOrigin[1] = -437.813385;
		fnAngles[1] = 180.000000;
		fnOrigin[2] = 725.031250;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "c12m1_hilltop") || StrEqual(cmap, "C12m1_hilltop")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL13);

		fnOrigin[0] = -8113.000000;
		fnAngles[0] = 0.000000;
		fnOrigin[1] = -15017.000000;
		fnAngles[1] = 161.000000;
		fnOrigin[2] = 278.000000;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "c13m1_alpinecreek") || StrEqual(cmap, "c13m1_alpinecreek_night")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL04);

		fnOrigin[0] = -2982.207275;
		fnAngles[0] = 4.749351;
		fnOrigin[1] = -404.366333;
		fnAngles[1] = 92.358307;
		fnOrigin[2] = 78.559059;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "l4d2_orange01_city")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL03);

		fnOrigin[0] = -2539.044189;
		fnAngles[0] = -0.306694;
		fnOrigin[1] = -3554.748047;
		fnAngles[1] = -0.295615;
		fnOrigin[2] = 512.031250;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "l4d2_city17_01")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL12);

		fnOrigin[0] = 3776.000000;
		fnAngles[0] = 0.000000;
		fnOrigin[1] = -5044.000000;
		fnAngles[1] = 89.000000;
		fnOrigin[2] = -120.000000;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "bwm1_climb")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL06);

		fnOrigin[0] = -522.000000;
		fnAngles[0] = 0.000000;
		fnOrigin[1] = 702.000000;
		fnAngles[1] = 179.000000;
		fnOrigin[2] = 0.000000;
		fnAngles[2] = 0.000000;
	}
	SetEntProp(fence, Prop_Send, "m_nSolidType", 6);
	DispatchKeyValue(fence, "targetname", "anti-rush_system-l4d2_fence");
	DispatchSpawn(fence);
	TeleportEntity(fence, fnOrigin, fnAngles, NULL_VECTOR);

	float fn2Origin[3],
	fn2Angles[3];
	int fence2 = CreateEntityByName("prop_dynamic_override");
	if (StrEqual(cmap, "c2m1_highway")) {
		DispatchKeyValue(fence2, "model", FENCE_MODEL04);

		fn2Origin[0] = 10003.427734;
		fn2Angles[0] = 6.784813;
		fn2Origin[1] = 8351.467773;
		fn2Angles[1] = -179.112259;
		fn2Origin[2] = -515.465454;
		fn2Angles[2] = 0.000000;
	} else if (StrEqual(cmap, "c4m1_milltown_a")) {
		DispatchKeyValue(fence2, "model", FENCE_MODEL04);

		fn2Origin[0] = -6362.469727;
		fn2Angles[0] = 1.476095;
		fn2Origin[1] = 7397.324707;
		fn2Angles[1] = 180.000000;
		fn2Origin[2] = 306.031250;
		fn2Angles[2] = 0.000000;
	} else if (StrEqual(cmap, "c8m1_apartment") || StrEqual(cmap, "l4d2_hospital01_apartment")) {
		DispatchKeyValue(fence2, "model", FENCE_MODEL07);

		fn2Origin[0] = 2153.561279;
		fn2Angles[0] = 90.000000;
		fn2Origin[1] = 920.078430;
		fn2Angles[1] = -180.000000;
		fn2Origin[2] = 410.024597;
		fn2Angles[2] = 0.000000;
	} else if (StrEqual(cmap, "c9m1_alleys")) {
		DispatchKeyValue(fence2, "model", FENCE_MODEL04);

		fn2Origin[0] = -9617.561523;
		fn2Angles[0] = -0.119123;
		fn2Origin[1] = -9659.479492;
		fn2Angles[1] = -90.020599;
		fn2Origin[2] = -2.663688;
		fn2Angles[2] = 0.000000;
	} else if (StrEqual(cmap, "c11m1_greenhouse")) {
		DispatchKeyValue(fence2, "model", FENCE_MODEL09);

		fn2Origin[0] = 6280.875000;
		fn2Angles[0] = 0.000000;
		fn2Origin[1] = -786.662415;
		fn2Angles[1] = 180.000000;
		fn2Origin[2] = 925.031250;
		fn2Angles[2] = 0.000000;
	} else if (StrEqual(cmap, "c12m1_hilltop") || StrEqual(cmap, "C12m1_hilltop")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL14);

		fnOrigin[0] = -8202.000000;
		fnAngles[0] = 0.000000;
		fnOrigin[1] = -15289.000000;
		fnAngles[1] = 161.000000;
		fnOrigin[2] = 333.000000;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "l4d2_city17_01")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL12);

		fnOrigin[0] = 4015.000000;
		fnAngles[0] = 0.000000;
		fnOrigin[1] = -5022.000000;
		fnAngles[1] = 93.000000;
		fnOrigin[2] = -124.000000;
		fnAngles[2] = 0.000000;
	}
	SetEntProp(fence2, Prop_Send, "m_nSolidType", 6);
	DispatchKeyValue(fence2, "targetname", "anti-rush_system-l4d2_fence");
	DispatchSpawn(fence2);
	TeleportEntity(fence2, fn2Origin, fn2Angles, NULL_VECTOR);

	float fn3Origin[3],
	fn3Angles[3];
	int fence3 = CreateEntityByName("prop_dynamic_override");
	if (StrEqual(cmap, "c4m1_milltown_a")) {
		DispatchKeyValue(fence3, "model", FENCE_MODEL03);

		fn3Origin[0] = -6366.153320;
		fn3Angles[0] = 2.018882;
		fn3Origin[1] = 6976.294922;
		fn3Angles[1] = -1.210750;
		fn3Origin[2] = 232.031265;
		fn3Angles[2] = 0.000000;
	} else if (StrEqual(cmap, "c9m1_alleys")) {
		DispatchKeyValue(fence3, "model", FENCE_MODEL04);

		fn3Origin[0] = -10102.182617;
		fn3Angles[0] = 1.237835;
		fn3Origin[1] = -9660.498047;
		fn3Angles[1] = -90.156395;
		fn3Origin[2] = -5.845541;
		fn3Angles[2] = 0.000000;
	} else if (StrEqual(cmap, "c11m1_greenhouse")) {
		DispatchKeyValue(fence3, "model", FENCE_MODEL11);

		fn3Origin[0] = 6280.875000;
		fn3Angles[0] = 0.000000;
		fn3Origin[1] = -536.662415;
		fn3Angles[1] = 180.000000;
		fn3Origin[2] = 925.031250;
		fn3Angles[2] = 0.000000;
	} else if (StrEqual(cmap, "c12m1_hilltop") || StrEqual(cmap, "C12m1_hilltop")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL14);

		fnOrigin[0] = -8192.000000;
		fnAngles[0] = 0.000000;
		fnOrigin[1] = -15236.000000;
		fnAngles[1] = 161.000000;
		fnOrigin[2] = 382.000000;
		fnAngles[2] = 0.000000;
	} else if (StrEqual(cmap, "l4d2_city17_01")) {
		DispatchKeyValue(fence, "model", FENCE_MODEL12);

		fnOrigin[0] = 4218.000000;
		fnAngles[0] = 0.000000;
		fnOrigin[1] = -5016.000000;
		fnAngles[1] = -93.000000;
		fnOrigin[2] = -124.000000;
		fnAngles[2] = 0.000000;
	}
	SetEntProp(fence3, Prop_Send, "m_nSolidType", 6);
	DispatchKeyValue(fence3, "targetname", "anti-rush_system-l4d2_fence");
	DispatchSpawn(fence3);
	TeleportEntity(fence3, fn3Origin, fn3Angles, NULL_VECTOR);

	g_bLocked = true;
	StopBots();

}

stock unblockPath() {
	CheatCommand(_, "ent_fire", "anti-rush_system-l4d2_fence KillHierarchy");

	g_bLocked = false;
	StartBots();
}

public Action CmdUnLock(int client, int args) {
	char class[128];
	int i = MaxClients + 1;
	while (i <= 2048) {
		if (IsValidEntity(i)) {
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "prop_door_rotating_checkpoint", true)) {
				SetVariantString("spawnflags 8192");
				AcceptEntityInput(i, "AddOutput");
				AcceptEntityInput(i, "Unlock");
				AcceptEntityInput(i, "Open");
				if (b_StandartMap()) {
					L4D2_SetEntGlow(i, L4D2Glow_OnLookAt, 1000, GetConVarInt(cvarLockGlowRange), {
						0,
						255,
						127
					},
					false);
					SetEntityRenderColor(i, 0, 0, 0, 255);
				}
			}
		}
		i++;
	}
	PrintToChat(client, "\x05[\x04DOORLOCK\x05]\x01 Saferoom doors are unlocked!");
	return Plugin_Handled;
}

public Action timerLockSwitch(Handle timer) {
	if (isFinishedLoading()) {

		if (isBugged() || isBugged2()) {

			if (!bFirstMapOfCampaign()) {
				if (g_iCooldown > 0) {
					g_bLocked = true;
				} else {
					if (g_iCooldown) {

						if (g_iCooldown < 0 || g_bLocked) {

							return Plugin_Stop;
						}
					}

					Now_UnlockSaferoomDoor();
					g_bLocked = false;
					CPrintToChatAll("{blue}[{default}Revenge{blue}]{default} La Puerta esta abierta, NO RUSH POR FAVOR {olive}!");

					if (GetConVarInt(cvarLockHintText) == 1) {
						PrintHintTextToAll("The saferoom doors are open!");
					}
				}
				if (GetConVarInt(cvarLockHintText) == 1) {
					if (g_iCooldown > 0) {
						PrintHintTextToAll("%i second(s) till the saferoom doors open!", g_iCooldown);
						
					}
				}

				if (GetConVarInt(cvarLockHintText) != 1 && g_iCooldown <= GetConVarInt(cvarLockNotify) && g_iCooldown > 0) {
					for (int i = 1; i <= MaxClients; i++) {
						if (IsClientInGame(i) && (GetClientTeam(i) == 2)) PrintCenterText(i, "Door will open in: %i seconds! Please wait.", g_iCooldown);
					}
				}

				g_iCooldown -= 1;
			}

		} else {
			if (g_iCooldown > 0) {
				g_bLocked = true;
			} else {
				if (g_iCooldown) {

					if (g_iCooldown < 0 || g_bLocked) {

						return Plugin_Stop;
					}
				}

				unblockPath();
				g_bLocked = false;
				CPrintToChatAll("{blue}[{default}Revenge{blue}]{default} La Puerta esta abierta, NO RUSH POR FAVOR {olive}!");

				if (GetConVarInt(cvarLockHintText) == 1) {
					PrintHintTextToAll("The path has cleared!");
				}
			}
			if (GetConVarInt(cvarLockHintText) == 1) {
				if (g_iCooldown > 0) {
					PrintHintTextToAll("%i second(s) till the Path Unblocks!", g_iCooldown);
				}
			}

			if (GetConVarInt(cvarLockHintText) != 1 && g_iCooldown <= GetConVarInt(cvarLockNotify) && g_iCooldown > 0) {
				for (int i = 1; i <= MaxClients; i++) {
					if (IsClientInGame(i) && (GetClientTeam(i) == 2)) PrintCenterText(i, "Path will open in: %i seconds! Please wait.", g_iCooldown);
				}
			}

			g_iCooldown -= 1;
		}

	}
	return Plugin_Continue;
}

public OnStartDoorFullyOpened(const char[] output, int caller, int activator, float delay) {
	AcceptEntityInput(activator, "Lock");
	SetEntProp(activator, Prop_Data, "m_hasUnlockSequence", 1);
}

stock ClearVariables() {
	if (g_iRoundCounter == 1) {
		g_iCooldown = GetConVarInt(cvarLockRoundOne);
	} else {
		if (g_iRoundCounter == 2) {
			g_iCooldown = GetConVarInt(cvarLockRoundTwo);
		}
	}
}

public bool: bFirstMapOfCampaign() {
	char MapName[128];
	GetCurrentMap(MapName, sizeof(MapName));
	if (StrContains(MapName, "c1m1", true) > -1 || StrContains(MapName, "c2m1", true) > -1 || StrContains(MapName, "c3m1", true) > -1 || StrContains(MapName, "c4m1", true) > -1 || StrContains(MapName, "c5m1", true) > -1 || StrContains(MapName, "c6m1", true) > -1 || StrContains(MapName, "c7m1", true) > -1 || StrContains(MapName, "c8m1", true) > -1 || StrContains(MapName, "c9m1", true) > -1 || StrContains(MapName, "c10m1", true) > -1 || StrContains(MapName, "c11m1", true) > -1 || StrContains(MapName, "c12m1", true) > -1 || StrContains(MapName, "c13m1", true) > -1 || StrContains(MapName, "l4d2_zero01_base", true) > -1 || StrContains(MapName, "l4d2_viennacalling2_1", true) > -1 || StrContains(MapName, "eu01_residential_b16", true) > -1 || StrContains(MapName, "bloodtracks_01", true) > -1 || StrContains(MapName, "l4d2_darkblood01_tanker", true) > -1 || StrContains(MapName, "l4d2_dbd2dc_anna_is_gone", true) > -1 || StrContains(MapName, "cdta_01detour", true) > -1 || StrContains(MapName, "l4d2_ihm01_forest", true) > -1 || StrContains(MapName, "l4d2_diescraper1_apartment_31", true) > -1 || StrContains(MapName, "l4d2_149_1", true) > -1 || StrContains(MapName, "gr-mapone-7", true) > -1 || StrContains(MapName, "qe_1_cliche", true) > -1 || StrContains(MapName, "l4d2_stadium1_apartment", true) > -1 || StrContains(MapName, "l4d2_stadium5_stadium", true) > -1 || StrContains(MapName, "eu01_residential_b09", true) > -1 || StrContains(MapName, "wth_1", true) > -1 || StrContains(MapName, "2ee_01", true) > -1 || StrContains(MapName, "l4d2_city17_01", true) > -1 || StrContains(MapName, "l4d2_deathaboard01_prison", true) > -1 || StrContains(MapName, "cwm1_intro", true) > -1 || StrContains(MapName, "2ee_01_deadlybeggining", true) > -1 || StrContains(MapName, "l4d2_orange01_first", true) > -1 || StrContains(MapName, "hf01_theforest", true) > -1 || StrContains(MapName, "l4d2_deadcity01_riverside", true) > -1 || StrContains(MapName, "tutorial01", true) > -1 || StrContains(MapName, "tutorial_standards", true) > -1 || StrContains(MapName, "srocchurch", true) > -1 || StrContains(MapName, "l4d2_ravenholmwar_1", true) > -1 || StrContains(MapName, "l4d2_ravenholmwar_4", true) > -1) {
		return true;
	}
	return false;
}

public bool: b_StandartMap() {
	char MapName[128];
	GetCurrentMap(MapName, sizeof(MapName));
	if (StrContains(MapName, "c1m1", true) > -1 || StrContains(MapName, "c1m2", true) > -1 || StrContains(MapName, "c1m3", true) > -1 || StrContains(MapName, "c1m4", true) > -1 || StrContains(MapName, "c2m1", true) > -1 || StrContains(MapName, "c2m2", true) > -1 || StrContains(MapName, "c2m3", true) > -1 || StrContains(MapName, "c2m4", true) > -1 || StrContains(MapName, "c2m5", true) > -1 || StrContains(MapName, "c3m1", true) > -1 || StrContains(MapName, "c3m2", true) > -1 || StrContains(MapName, "c3m3", true) > -1 || StrContains(MapName, "c3m4", true) > -1 || StrContains(MapName, "c4m1", true) > -1 || StrContains(MapName, "c4m2", true) > -1 || StrContains(MapName, "c4m3", true) > -1 || StrContains(MapName, "c4m4", true) > -1 || StrContains(MapName, "c4m5", true) > -1 || StrContains(MapName, "c5m1", true) > -1 || StrContains(MapName, "c5m2", true) > -1 || StrContains(MapName, "c5m3", true) > -1 || StrContains(MapName, "c5m4", true) > -1 || StrContains(MapName, "c5m5", true) > -1 || StrContains(MapName, "c6m1", true) > -1 || StrContains(MapName, "c6m2", true) > -1 || StrContains(MapName, "c6m3", true) > -1 || StrContains(MapName, "c7m1", true) > -1 || StrContains(MapName, "c7m2", true) > -1 || StrContains(MapName, "c7m3", true) > -1 || StrContains(MapName, "c8m1", true) > -1 || StrContains(MapName, "c8m2", true) > -1 || StrContains(MapName, "c8m3", true) > -1 || StrContains(MapName, "c8m4", true) > -1 || StrContains(MapName, "c8m5", true) > -1 || StrContains(MapName, "c9m1", true) > -1 || StrContains(MapName, "c9m2", true) > -1 || StrContains(MapName, "c10m1", true) > -1 || StrContains(MapName, "c10m2", true) > -1 || StrContains(MapName, "c10m3", true) > -1 || StrContains(MapName, "c10m4", true) > -1 || StrContains(MapName, "c10m5", true) > -1 || StrContains(MapName, "c11m1", true) > -1 || StrContains(MapName, "c11m2", true) > -1 || StrContains(MapName, "c11m3", true) > -1 || StrContains(MapName, "c11m4", true) > -1 || StrContains(MapName, "c11m5", true) > -1 || StrContains(MapName, "c12m1", true) > -1 || StrContains(MapName, "c12m2", true) > -1 || StrContains(MapName, "c12m3", true) > -1 || StrContains(MapName, "c12m4", true) > -1 || StrContains(MapName, "c12m5", true) > -1 || StrContains(MapName, "c13m1", true) > -1 || StrContains(MapName, "c13m2", true) > -1 || StrContains(MapName, "c13m3", true) > -1 || StrContains(MapName, "c13m4", true) > -1) {
		return true;
	}
	return false;
}

public OnClientDisconnect(int client) {
	isClientLoading[client] = false;
	clientTimeout[client] = 0;
}

public Event_Join_Team(Handle event, const char[] event_name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (isClientValid(client)) {
		isClientLoading[client] = false;
		clientTimeout[client] = 0;
	}
}


bool: isFinishedLoading() {
	for (int i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i)) {

			if (!IsClientInGame(i) && !IsFakeClient(i)) {
				clientTimeout[i]++;

				if (isClientLoading[i] && clientTimeout[i] == 1) {

					for (int e = 1; e <= MaxClients; e++) {
						if (IsClientInGame(e) && (GetClientTeam(e) == 2) && e != i) PrintCenterText(e, "Waiting for player %N to join the game", i);
					}

					isClientLoading[i] = true;
				} else if (clientTimeout[i] == GetConVarInt(cvarClientTimeOut)) {
					/* Handling clients timing out */
					for (int e = 1; e <= MaxClients; e++) {
						if (IsClientInGame(e) && (GetClientTeam(e) == 2) && e != i) PrintCenterText(e, "Stopping to wait for player %N (assumed timeout)", i);
					}

					isClientLoading[i] = false;
				}

			} else {

				isClientLoading[i] = false;
			}
		} else isClientLoading[i] = false;
	}

	return ! IsAnyClientLoading();
}


bool: IsAnyClientLoading() {
	for (int i = 1; i <= MaxClients; i++) {
		if (isClientLoading[i]) {
			return true;
		}
	}

	return false;
}

bool: isClientValid(int client) {
	if (client <= 0) {
		return false;
	}
	if (!IsClientConnected(client)) {
		return false;
	}
	if (!IsClientInGame(client)) {
		return false;
	}
	if (IsFakeClient(client)) {
		return false;
	}
	return true;
}