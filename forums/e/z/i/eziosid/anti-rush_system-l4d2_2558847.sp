#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <glow>
#pragma semicolon 1

#define TEAM_SURVIVOR 2

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

new Handle:cvarLockRoundOne;
new Handle:cvarLockRoundTwo;
new Handle:cvarLockGlowRange;
new Handle:cvarLockHintText;
new Handle:cvarLockNotify;
new Handle:cvarLockAutoOpen;
new Handle:handleGameMode = INVALID_HANDLE;

new bool:g_bLocked = true;
new g_iCooldown;
new g_iRoundCounter;

new String:cmap[64];

public Plugin:myinfo = 
{
	name = "[L4D2] Anti-Rush System",
	author = "LEGEND, cravenge",
	description = "Locks Saferoom Doors Over A Period Of Time To Prevent Rushers.",
	version = "6.1",
	url = "http://mgftw.com"
};

public OnPluginStart()
{
	decl String:gameName[64];
	GetGameFolderName(gameName, sizeof(gameName));
	if (!(StrEqual(gameName, "left4dead2", false)))
	{
		SetFailState("[ARS] Plugin Supports L4D2 Only!");
	}
	
	handleGameMode = FindConVar("mp_gamemode");
	decl String:gameMode[16];
	GetConVarString(handleGameMode, gameMode, sizeof(gameMode));
	
	RegAdminCmd("sm_lockall", CmdLockAll, ADMFLAG_UNBAN);
	RegAdminCmd("sm_unlockall", CmdUnLockAll, ADMFLAG_UNBAN);
	
	HookEvent("round_start", OnRoundStart, EventHookMode_Post);
	HookEvent("round_freeze_end", OnRoundFreezeEnd);
	
	cvarLockRoundOne = CreateConVar("anti-rush_doors_roundone", "45", "Time Applied To Lockdown Door", FCVAR_NOTIFY);
	cvarLockRoundTwo = CreateConVar("anti-rush_doors_roundtwo", "45", "Time Applied To Lockdown Door In Round Two", FCVAR_NOTIFY);
	cvarLockAutoOpen = CreateConVar("anti-rush_doors_autoopen", "0", "Enable/Disable Automatic Door Opening", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarLockGlowRange = CreateConVar("anti-rush_doors_glowrange", "550", "Range Door Glows", FCVAR_NOTIFY);
	cvarLockHintText = CreateConVar("anti-rush_doors_hinttext", "1", "Enable/Disable Notifications", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarLockNotify = CreateConVar("anti-rush_doors_notify", "0", "CountDown Time To Notify Players", FCVAR_NOTIFY);
	
	AutoExecConfig(true, "anti-rush_system-l4d2");
}

public OnMapStart()
{
	PrecacheModel(FENCE_MODEL01, true);
	PrecacheModel(FENCE_MODEL02, true);
	PrecacheModel(FENCE_MODEL03, true);
	PrecacheModel(FENCE_MODEL04, true);
	PrecacheModel(FENCE_MODEL05, true);
	PrecacheModel(FENCE_MODEL06, true);
	PrecacheModel(FENCE_MODEL07, true);
	PrecacheModel(FENCE_MODEL08, true);
	PrecacheModel(FENCE_MODEL09, true);
	PrecacheModel(FENCE_MODEL10, true);
	PrecacheModel(FENCE_MODEL11, true);
	
	PrecacheModel("models/props_doors/checkpoint_door_01.mdl", true);
	
	GetCurrentMap(cmap, sizeof(cmap));
	
	g_iRoundCounter = 1;
	clearVariables();
}

public Action:timerUnlock(Handle:timer)
{
	if (g_iCooldown <= 0 || !g_bLocked)
	{
		if(isBugged() || isBugged2())
		{
			checkAndUnlockAll();
		}
		else
		{
			unblockPath();
		}
		
		if (GetConVarInt(cvarLockHintText) == 1)
		{
			if(isBugged() || isBugged2())
			{
				PrintHintTextToAll("Door Opens!");
			}
			else
			{
				PrintHintTextToAll("Path Unblocks!");
			}
		}
		
		if (GetConVarInt(cvarLockNotify) != 0)
		{
			if (GetConVarInt(cvarLockAutoOpen) == 1)
			{
				if(isBugged() || isBugged2())
				{
					PrintToChatAll("\x05[LOCK] \x04Door Opens!");
				}
				else
				{
					PrintToChatAll("\x05[LOCK] \x04Path Clears!");
				}
			}
			else
			{
				if(isBugged() || isBugged2())
				{
					PrintToChatAll("\x05[LOCK] \x04Door Unlocks!");
				}
				else
				{
					PrintToChatAll("\x05[LOCK] \x04Path Unblocks!");
				}
			}
		}
		return Plugin_Stop;
	}
	
	if ((g_iCooldown == GetConVarInt(cvarLockNotify)) && (GetConVarInt(cvarLockNotify) != 0))
	{
		if(isBugged() || isBugged2())
		{
			PrintToChatAll("\x05[LOCK] \x04Door Opens In %i!", g_iCooldown);
		}
		else
		{
			PrintToChatAll("\x05[LOCK] \x04Path Unblocks In %i!", g_iCooldown);
		}
	}
	
	if (GetConVarInt(cvarLockHintText) == 1)
	{
		if(isBugged() || isBugged2())
		{
			PrintHintTextToAll("%i Till The Door Opens!", g_iCooldown);
		}
		else
		{
			PrintHintTextToAll("%i Till Path Gives Way!", g_iCooldown);
		}
	}
	g_iCooldown--;
	return Plugin_Continue;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isBugged() || isBugged2())
	{
		CreateTimer(2.0, timerMapStartLocker);
	}
	else
	{
		CreateTimer(2.0, timerMapStartBlocker);
	}
}

public Action:timerMapStartLocker(Handle:timer)
{
	startLockProcedure();
}

startLockProcedure()
{
	g_bLocked = true;
	clearVariables();
	checkAndLockAll();
	CreateTimer(1.0, timerUnlock, _, TIMER_REPEAT);
}

public Action:timerMapStartBlocker(Handle:timer)
{
	startBlockProcedure();
}

startBlockProcedure()
{
	g_bLocked = true;
	clearVariables();
	blockPath();
	CreateTimer(1.0, timerUnlock, _, TIMER_REPEAT);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{
	if(isBugged() || isBugged2())
	{
		if (g_bLocked)
		{
			if (client <= 0) 
			{
				return Plugin_Handled;
			}
			
			if (IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVOR)
			{
				return Plugin_Continue;
			}

			if ((buttons & IN_USE) == IN_USE)
			{
				new ent = GetClientAimTarget(client, false);
				if (!IsValidEntity(ent))
				{
					return Plugin_Continue;
				}
				
				new String:class[64];
				GetEntityClassname(ent, class, sizeof(class));
				if (StrEqual(class, "prop_door_rotating_checkpoint", false))
				{
					if (GetConVarInt(cvarLockNotify) != 0)
					{
						PrintToChat(client, "\x05[LOCK] \x04Door Opens In %i!", g_iCooldown);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:OnRoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iRoundCounter == 1)
	{
		g_iRoundCounter == 2;
	}
}

public getStartDoorHammerID()
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if (StrEqual(mapname, "c1m2_streets", false))
	{
		return 75531;
	}
	else if (StrEqual(mapname, "c1m3_mall", false))
	{
		return 8443001;
	}
	else if (StrEqual(mapname, "c2m2_fairgrounds", false))
	{
		return 437514;
	}
	else if (StrEqual(mapname, "c2m3_coaster", false))
	{
		return 44268;
	}
	else if (StrEqual(mapname, "c2m4_barns", false))
	{
		return 1682887;
	}
	else if (StrEqual(mapname, "c3m2_swamp", false))
	{
		return 894101;
	}
	else if (StrEqual(mapname, "c3m3_shantytown", false))
	{
		return 1755442;
	}
	else if (StrEqual(mapname, "c4m2_sugarmill_a", false))
	{
		return 37230;
	}
	else if (StrEqual(mapname, "c4m3_sugarmill_b", false))
	{
		return 38123;
	}
	else if (StrEqual(mapname, "c4m4_milltown_b", false))
	{
		return 5031;
	}
	else if (StrEqual(mapname, "c5m2_park", false))
	{
		return 1797205;
	}
	else if (StrEqual(mapname, "c5m3_cemetery", false))
	{
		return 549048;
	}
	else if (StrEqual(mapname, "c5m4_quarter", false))
	{
		return 244882;
	}
	else if (StrEqual(mapname, "c6m2_bedlam", false))
	{
		return 482345;
	}
	else if (StrEqual(mapname, "c7m2_barge", false))
	{
		return 200103;
	}
	else if (StrEqual(mapname, "c8m2_subway", false) || StrEqual(mapname, "l4d2_hospital02_subway", false))
	{
		return 5675135;
	}
	else if (StrEqual(mapname, "c8m3_sewers", false) || StrEqual(mapname, "l4d2_hospital03_sewers", false))
	{
		return 4045682;
	}
	else if (StrEqual(mapname, "c8m4_interior", false) || StrEqual(mapname, "l4d2_hospital04_interior", false))
	{
		return 4078678;
	}
	else if (StrEqual(mapname, "c10m2_drainage", false) || StrEqual(mapname, "l4d2_smalltown02_drainage", false))
	{
		return 827551;
	}
	else if (StrEqual(mapname, "c10m3_ranchhouse", false) || StrEqual(mapname, "l4d2_smalltown03_ranchhouse", false))
	{
		return 1646224;
	}
	else if (StrEqual(mapname, "c10m4_mainstreet", false) || StrEqual(mapname, "l4d2_smalltown04_mainstreet", false))
	{
		return 5271886;
	}
	else if (StrEqual(mapname, "c11m2_offices", false))
	{
		return 6913559;
	}
	else if (StrEqual(mapname, "c11m3_garage", false))
	{
		return 3803428;
	}
	else if (StrEqual(mapname, "c11m4_terminal", false))
	{
		return 4937918;
	}
	else if (StrEqual(mapname, "c12m2_traintunnel", false))
	{
		return 1386152;
	}
	else if (StrEqual(mapname, "c12m3_bridge", false))
	{
		return 1437236;
	}
	else if (StrEqual(mapname, "c12m4_barn", false))
	{
		return 1265104;
	}
	else if (StrEqual(mapname, "c13m2_southpinestream", false) || StrEqual(mapname, "c13m2_southpinestream_night", false))
	{
		return 1916929;
	}
	else if (StrEqual(mapname, "c13m3_memorialbridge", false) || StrEqual(mapname, "c13m3_memorialbridge_night", false))
	{
		return 246095;
	}
	else if (StrEqual(mapname, "c1m2d_streets", false))
	{
		return 1248;
	}
	else if (StrEqual(mapname, "c1m3d_mall", false))
	{
		return 3361;
	}
	else if (StrEqual(mapname, "cwm2_warehouse", false))
	{
		return 968655;
	}
	else if (StrEqual(mapname, "cwm3_drain", false))
	{
		return 1673;
	}
	else if (StrEqual(mapname, "l4d2_city17_02", false))
	{
		return 35457;
	}
	else if (StrEqual(mapname, "l4d2_city17_03", false))
	{
		return 29661;
	}
	else if (StrEqual(mapname, "l4d2_city17_04", false))
	{
		return 103264;
	}
	else if (StrEqual(mapname, "c1_2_jam", false))
	{
		return 816853;
	}
	else if (StrEqual(mapname, "c1_3_school", false))
	{
		return 851052;
	}
	else if (StrEqual(mapname, "gasfever_2", false))
	{
		return 298621;
	}
	else if (StrEqual(mapname, "c1_mario1_2", false))
	{
		return 112;
	}
	else if (StrEqual(mapname, "c1_mario1_3", false))
	{
		return 49;
	}
	else if (StrEqual(mapname, "wth_2", false))
	{
		return 4206;
	}
	else if (StrEqual(mapname, "wth_3", false))
	{
		return 6439;
	}
	else if (StrEqual(mapname, "wth_4", false))
	{
		return 1121;
	}
	else if (StrEqual(mapname, "lost02_", false))
	{
		return 2157;
	}
	else if (StrEqual(mapname, "lost03", false))
	{
		return 46;
	}
	else if (StrEqual(mapname, "lost04", false))
	{
		return 108;
	}
	else if (StrEqual(mapname, "lost02_1", false))
	{
		return 246467;
	}
	else if (StrEqual(mapname, "l4d2_darkblood02_engine", false))
	{
		return 1312704;
	}
	else if (StrEqual(mapname, "l4d2_darkblood03_platform", false))
	{
		return 1060288;
	}
	else if (StrEqual(mapname, "left4cake201_start", false))
	{
		return 749426;
	}
	else if (StrEqual(mapname, "left4cake202_dos", false))
	{
		return 842646;
	}
	else if (StrEqual(mapname, "bwm2_city", false))
	{
		return 138820;
	}
	else if (StrEqual(mapname, "bwm3_forest", false))
	{
		return 3948;
	}
	else if (StrEqual(mapname, "bwm4_rooftops", false))
	{
		return 307;
	}
	else if (StrEqual(mapname, "l4d2_pasiri2", false))
	{
		return 66;
	}
	else if (StrEqual(mapname, "l4d2_pasiri3", false))
	{
		return 386;
	}
	else if (StrEqual(mapname, "p84m2_train", false))
	{
		return 7145160;
	}
	else if (StrEqual(mapname, "p84m3_clubd", false))
	{
		return 4371316;
	}
	else if (StrEqual(mapname, "l4d_draxmap2", false))
	{
		return 134;
	}
	else if (StrEqual(mapname, "l4d_draxmap3", false))
	{
		return 1483983;
	}
	else if (StrEqual(mapname, "l4d2_forest", false) || StrEqual(mapname, "l4d2_forest_vs", false))
	{
		return 89977;
	}
	else if (StrEqual(mapname, "l4d2_tracks", false) || StrEqual(mapname, "l4d2_tracks_vs", false))
	{
		return 41302;
	}
	else if (StrEqual(mapname, "l4d2_cave", false) || StrEqual(mapname, "l4d2_cave_vs", false))
	{
		return 106;
	}
	else if (StrEqual(mapname, "cbm2_town", false))
	{
		return 1041;
	}
	else if (StrEqual(mapname, "l4d_coldfear02_factory", false))
	{
		return 43509;
	}
	else if (StrEqual(mapname, "l4d_coldfear03_officebuilding", false))
	{
		return 44;
	}
	else if (StrEqual(mapname, "l4d_coldfear04_roffs", false))
	{
		return 94;
	}
	else if (StrEqual(mapname, "l4d2_garage02_lots_a", false))
	{
		return 8736;
	}
	else if (StrEqual(mapname, "l4d2_garage02_lots_b", false))
	{
		return 42431;
	}
	else if (StrEqual(mapname, "l4d2_garage01_alleys_b", false))
	{
		return 233599;
	}
	else if (StrEqual(mapname, "hotel", false))
	{
		return 2643371;
	}
	else if (StrEqual(mapname, "station-a", false))
	{
		return 381383;
	}
	else if (StrEqual(mapname, "rivermotel", false))
	{
		return 25567;
	}
	else if (StrEqual(mapname, "outskirts", false))
	{
		return 884256;
	}
	else if (StrEqual(mapname, "cityhall", false))
	{
		return 589;
	}
	else if (StrEqual(mapname, "hellishjourney02", false) || StrEqual(mapname, "hellishjourney02_l4d2", false))
	{
		return 59554;
	}
	else if (StrEqual(mapname, "jsarena202_alley", false))
	{
		return 587554;
	}
	else if (StrEqual(mapname, "jsarena203_roof", false))
	{
		return 432684;
	}
	else if (StrEqual(mapname, "uf2_rooftops", false))
	{
		return 101086;
	}
	else if (StrEqual(mapname, "uf3_harbor", false))
	{
		return 2046962;
	}
	else if (StrEqual(mapname, "ch_map2_temple", false))
	{
		return 178267;
	}
	else if (StrEqual(mapname, "l4d2_orange02_mountain", false))
	{
		return 328;
	}
	else if (StrEqual(mapname, "l4d2_orange03_sky", false))
	{
		return 14;
	}
	else if (StrEqual(mapname, "devilscorridor", false))
	{
		return 97112;
	}
	else if (StrEqual(mapname, "surface", false))
	{
		return 123255;
	}
	else if (StrEqual(mapname, "ftlostonahill", false))
	{
		return 456;
	}
	else if (StrEqual(mapname, "l4d2_scream02_goingup", false))
	{
		return 41027;
	}
	else if (StrEqual(mapname, "l4d2_scream03_rooftops", false))
	{
		return 78095;
	}
	else if (StrEqual(mapname, "l4d2_scream04_train", false))
	{
		return 121597;
	}
	else if (StrEqual(mapname, "l4d2_win2", false))
	{
		return 273776;
	}
	else if (StrEqual(mapname, "l4d2_win3", false))
	{
		return 301930;
	}
	else if (StrEqual(mapname, "l4d2_win4", false))
	{
		return 301953;
	}
	else if (StrEqual(mapname, "l4d2_win5", false))
	{
		return 181688;
	}
	else if (StrEqual(mapname, "QE_2_remember_me", false) || StrEqual(mapname, "qe_2_remember_me", false))
	{
		return 50;
	}
	else if (StrEqual(mapname, "QE_3_unorthodox_paradox", false) || StrEqual(mapname, "qe_3_unorthodox_paradox", false))
	{
		return 8219;
	}
	else if (StrEqual(mapname, "QE2_ep2", false) || StrEqual(mapname, "qe2_ep2", false))
	{
		return 442;
	}
	else if (StrEqual(mapname, "QE2_ep3", false) || StrEqual(mapname, "qe2_ep3", false))
	{
		return 870427;
	}
	else if (StrEqual(mapname, "QE2_ep4", false) || StrEqual(mapname, "qe2_ep4", false))
	{
		return 1604467;
	}
	else if (StrEqual(mapname, "gridmap2", false))
	{
		return 3804077;
	}
	else if (StrEqual(mapname, "gridmap3", false))
	{
		return 2940041;
	}
	else if (StrEqual(mapname, "wfp2_horn", false))
	{
		return 14245;
	}
	else if (StrEqual(mapname, "wfp3_mill", false))
	{
		return 455186;
	}
	else if (StrEqual(mapname, "l4d2_pdmesa02_shafted", false))
	{
		return 190;
	}
	else if (StrEqual(mapname, "l4d2_pdmesa03_office", false))
	{
		return 1366451;
	}
	else if (StrEqual(mapname, "l4d2_pdmesa04_pointinsert", false))
	{
		return 206983;
	}
	else if (StrEqual(mapname, "l4d2_diescraper2_streets_35", false))
	{
		return 1214288;
	}
	else if (StrEqual(mapname, "l4d2_diescraper3_mid_35", false))
	{
		return 1186946;
	}
	else if (StrEqual(mapname, "carnage_basement", false))
	{
		return 19499;
	}
	else if (StrEqual(mapname, "busbahnhof1", false))
	{
		return 918481;
	}
	else if (StrEqual(mapname, "l4d_linz_ok", false))
	{
		return 37;
	}
	else if (StrEqual(mapname, "l4d_linz_zurueck", false))
	{
		return 192;
	}
	else if (StrEqual(mapname, "l4d_naniwa02_arcade", false) || StrEqual(mapname, "l4d_naniwa03_highway", false) || StrEqual(mapname, "l4d_naniwa04_subway", false))
	{
		return 6913559;
	}
	else if (StrEqual(mapname, "m2_burbs", false))
	{
		return 2538;
	}
	else if (StrEqual(mapname, "m3_crowd_control", false))
	{
		return 126;
	}
	else if (StrEqual(mapname, "m4_launchpad", false))
	{
		return 684596;
	}
	else if (StrEqual(mapname, "dead_death_03", false))
	{
		return 756;
	}
	else if (StrEqual(mapname, "dead_death_01", false))
	{
		return 408;
	}
	else if (StrEqual(mapname, "hotel02_sewer_two", false))
	{
		return 12890;
	}
	else if (StrEqual(mapname, "hotel03_ramsey_two", false))
	{
		return 202545;
	}
	else if (StrEqual(mapname, "hotel04_scaling_two", false))
	{
		return 565200;
	}
	else if (StrEqual(mapname, "forest_beta407", false))
	{
		return 2330;
	}
	else if (StrEqual(mapname, "2019_M1b", false) || StrEqual(mapname, "2019_m1b", false))
	{
		return 1741;
	}
	else if (StrEqual(mapname, "2019_M2b", false) || StrEqual(mapname, "2019_m2b", false))
	{
		return 28642;
	}
	else if (StrEqual(mapname, "blood_hospital_01", false))
	{
		return 53;
	}
	else if (StrEqual(mapname, "blood_hospital_02", false) || StrEqual(mapname, "blood_hospital_02", false))
	{
		return 324;
	}
	else if (StrEqual(mapname, "l4d2_ravenholmwar_2", false))
	{
		return 2702;
	}
	else if (StrEqual(mapname, "l4d2_ravenholmwar_3", false))
	{
		return 1321;
	}
	else if (StrEqual(mapname, "c11m2_offices_day", false))
	{
		return 8716;
	}
	else if (StrEqual(mapname, "c11m3_garage_day", false))
	{
		return 17487;
	}
	else if (StrEqual(mapname, "c11m4_terminal_day", false))
	{
		return 25869;
	}
	else if (StrEqual(mapname, "c8m2_subway_daytime", false))
	{
		return 8998;
	}
	else if (StrEqual(mapname, "c8m3_sewers_daytime", false))
	{
		return 17954;
	}
	else if (StrEqual(mapname, "c8m4_interior_witchesday", false))
	{
		return 3078;
	}
	else if (StrEqual(mapname, "l4d2_the_complex_final_02", false))
	{
		return 109432;
	}
	else if (StrEqual(mapname, "soi_m2_museum", false))
	{
		return 2984;
	}
	else if (StrEqual(mapname, "soi_m3_biolab", false))
	{
		return 1483;
	}
	else if (StrEqual(mapname, "l4d_fallen02_trenches", false))
	{
		return 585424;
	}
	else if (StrEqual(mapname, "l4d_fallen03_tower", false))
	{
		return 286486;
	}
	else if (StrEqual(mapname, "l4d_fallen04_cliff", false))
	{
		return 661415;
	}
	else if (StrEqual(mapname, "c1m4_atrium", false))
	{
		return 171930;
	}
	else if (StrEqual(mapname, "c2m5_concert", false))
	{
		return 1717408;
	}
	else if (StrEqual(mapname, "c3m4_plantation", false))
	{
		return 600844;
	}
	else if (StrEqual(mapname, "c4m5_milltown_escape", false))
	{
		return 12253;
	}
	else if (StrEqual(mapname, "c5m5_bridge", false))
	{
		return 955431;
	}
	else if (StrEqual(mapname, "c6m3_port", false))
	{
		return 20429;
	}
	else if (StrEqual(mapname, "c7m3_port", false))
	{
		return 1566706;
	}
	else if (StrEqual(mapname, "c8m5_rooftop", false) || StrEqual(mapname, "l4d2_hospital05_rooftop", false))
	{
		return 3326690;
	}
	else if (StrEqual(mapname, "c9m2_lots", false) || StrEqual(mapname, "c9m2_lots_daytime", false))
	{
		return 51;
	}
	else if (StrEqual(mapname, "c10m5_houseboat", false) || StrEqual(mapname, "l4d2_smalltown05_houseboat", false))
	{
		return 1431968;
	}
	else if (StrEqual(mapname, "c11m5_runway", false))
	{
		return 3666066;
	}
	else if (StrEqual(mapname, "c12m5_cornfield", false))
	{
		return 921494;
	}
	else if (StrEqual(mapname, "c13m4_cutthroatcreek", false) || StrEqual(mapname, "c13m4_cutthroatcreek_night", false))
	{
		return 2008961;
	}
	else if (StrEqual(mapname, "c1m4d_atrium", false))
	{
		return 989;
	}
	else if (StrEqual(mapname, "cwm4_building", false))
	{
		return 4891;
	}
	else if (StrEqual(mapname, "l4d2_city17_05", false))
	{
		return 93012;
	}
	else if (StrEqual(mapname, "c1_4_roof_safe", false))
	{
		return 1090889;
	}
	else if (StrEqual(mapname, "gasfever_3", false))
	{
		return 718566;
	}
	else if (StrEqual(mapname, "jsgone02_end", false))
	{
		return 1039620;
	}
	else if (StrEqual(mapname, "c1_mario1_4", false))
	{
		return 73431;
	}
	else if (StrEqual(mapname, "wth_5", false))
	{
		return 184667;
	}
	else if (StrEqual(mapname, "lost02_2", false))
	{
		return 182;
	}
	else if (StrEqual(mapname, "l4d2_darkblood04_extraction", false))
	{
		return 1225672;
	}
	else if (StrEqual(mapname, "left4cake203_tres", false))
	{
		return 876354;
	}
	else if (StrEqual(mapname, "bwm5_bridge", false))
	{
		return 43573;
	}
	else if (StrEqual(mapname, "l4d2_pasiri4", false))
	{
		return 75;
	}
	else if (StrEqual(mapname, "p84m4_precinct", false))
	{
		return 5216921;
	}
	else if (StrEqual(mapname, "l4d_draxmap4", false))
	{
		return 2353008;
	}
	else if (StrEqual(mapname, "l4d2_backtoboat", false) || StrEqual(mapname, "l4d2_backtoboat_vs", false))
	{
		return 481;
	}
	else if (StrEqual(mapname, "cbm3_bunker", false))
	{
		return 1309;
	}
	else if (StrEqual(mapname, "l4d_coldfear05_docks", false))
	{
		return 72;
	}
	else if (StrEqual(mapname, "l4d2_garage01_alleys_escape", false))
	{
		return 225281;
	}
	else if (StrEqual(mapname, "station", false))
	{
		return 1667187;
	}
	else if (StrEqual(mapname, "hellishjourney03", false) || StrEqual(mapname, "hellishjourney03_l4d2", false))
	{
		return 499769;
	}
	else if (StrEqual(mapname, "jsarena204_arena", false))
	{
		return 235236;
	}
	else if (StrEqual(mapname, "uf4_airfield", false))
	{
		return 84550;
	}
	else if (StrEqual(mapname, "l4d2_orange04_rocket", false))
	{
		return 39;
	}
	else if (StrEqual(mapname, "goingup", false))
	{
		return 43413;
	}
	else if (StrEqual(mapname, "l4d2_scream05_finale", false))
	{
		return 60702;
	}
	else if (StrEqual(mapname, "l4d2_win6", false))
	{
		return 102097;
	}
	else if (StrEqual(mapname, "gemarshy03aztec", false))
	{
		return 1061995;
	}
	else if (StrEqual(mapname, "QE_4_ultimate_test", false) || StrEqual(mapname, "qe_4_ultimate_test", false))
	{
		return 3110;
	}
	else if (StrEqual(mapname, "QE2_ep5", false) || StrEqual(mapname, "qe2_ep5", false))
	{
		return 35;
	}
	else if (StrEqual(mapname, "grid4", false))
	{
		return 3786043;
	}
	else if (StrEqual(mapname, "wfp4_commstation", false))
	{
		return 62319;
	}
	else if (StrEqual(mapname, "l4d2_pdmesa05_returntoxen", false))
	{
		return 72449;
	}
	else if (StrEqual(mapname, "l4d2_pdmesa06_xen", false))
	{
		return 220593;
	}
	else if (StrEqual(mapname, "l4d2_diescraper4_top_35", false))
	{
		return 542565;
	}
	else if (StrEqual(mapname, "carnage_warehouse", false))
	{
		return 225;
	}
	else if (StrEqual(mapname, "l4d_linz_bahnhof", false))
	{
		return 33;
	}
	else if (StrEqual(mapname, "l4d_naniwa05_tower", false))
	{
		return 5675178;
	}
	else if (StrEqual(mapname, "m5_station_finale", false))
	{
		return 67039;
	}
	else if (StrEqual(mapname, "reactor_02_core", false))
	{
		return 63114;
	}
	else if (StrEqual(mapname, "hotel05_rooftop_two", false))
	{
		return 119084;
	}
	else if (StrEqual(mapname, "2019_M3b", false) || StrEqual(mapname, "2019_m3b", false))
	{
		return 84500;
	}
	else if (StrEqual(mapname, "c11m5_runway_day", false))
	{
		return 35343;
	}
	else if (StrEqual(mapname, "c8m5_rooftop_daytime", false))
	{
		return 32439;
	}
	else if (StrEqual(mapname, "l4d2_the_complex_final_03", false))
	{
		return 1528;
	}
	else if (StrEqual(mapname, "soi_m4_underground", false))
	{
		return 3195;
	}
	else if (StrEqual(mapname, "l4d_fallen05_shaft", false))
	{
		return 480896;
	}
	return -1;
}

isBugged()
{
	decl String:mapname[128];
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
		(StrEqual(mapname, "l4d_naniwa02_arcade", false)) || (StrEqual(mapname, "l4d_naniwa03_highway", false)) || (StrEqual(mapname, "l4d_naniwa04_subway", false)) || (StrEqual(mapname, "l4d_naniwa05_tower", false)) || 
		(StrEqual(mapname, "dead_death_03", false)) || (StrEqual(mapname, "dead_death_01", false)) || (StrEqual(mapname, "reactor_02_core", false)) || 
		(StrEqual(mapname, "forest_beta407", false)) || 
		(StrEqual(mapname, "2019_M1b", false)) || (StrEqual(mapname, "2019_m1b", false)) || (StrEqual(mapname, "2019_M2b", false)) || (StrEqual(mapname, "2019_m2b", false)) || (StrEqual(mapname, "2019_M3b", false)) || (StrEqual(mapname, "2019_m3b", false)) || 
		(StrEqual(mapname, "l4d2_ravenholmwar_2", false)) || (StrEqual(mapname, "l4d2_ravenholmwar_3", false)) || 
		(StrEqual(mapname, "c8m2_subway_daytime", false)) || (StrEqual(mapname, "c8m3_sewers_daytime", false)) || (StrEqual(mapname, "c8m4_interior_witchesday", false)) || (StrEqual(mapname, "c8m5_rooftop_daytime", false)) || 
		(StrEqual(mapname, "soi_m2_museum", false)) || (StrEqual(mapname, "soi_m3_biolab", false)) || (StrEqual(mapname, "soi_m4_underground", false)))
	{
		return true;
	}
	return false;
}

isBugged2()
{
	decl String:mapname[128];
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
		(StrEqual(mapname, "l4d_draxmap2", false)) || (StrEqual(mapname, "l4d_draxmap3", false)) || (StrEqual(mapname, "l4d_draxmap4", false)) || 
		(StrEqual(mapname, "l4d2_forest_vs")) || (StrEqual(mapname, "l4d2_tracks_vs")) || (StrEqual(mapname, "l4d2_cave_vs")) || (StrEqual(mapname, "l4d2_backtoboat_vs")) || 
		(StrEqual(mapname, "l4d_coldfear02_factory")) || (StrEqual(mapname, "l4d_coldfear03_officebuilding")) || (StrEqual(mapname, "l4d_coldfear04_roffs")) || (StrEqual(mapname, "l4d_coldfear05_docks")) || 
		(StrEqual(mapname, "hotel")) || (StrEqual(mapname, "station-a")) || (StrEqual(mapname, "station")) || 
		(StrEqual(mapname, "hellishjourney02")) || (StrEqual(mapname, "hellishjourney02_l4d2")) || (StrEqual(mapname, "hellishjourney03")) || (StrEqual(mapname, "hellishjourney03_l4d2")) || 
		(StrEqual(mapname, "uf2_rooftops")) || (StrEqual(mapname, "uf3_harbor")) || (StrEqual(mapname, "uf4_airfield")) || 
		(StrEqual(mapname, "l4d2_orange02_mountain")) || (StrEqual(mapname, "l4d2_orange03_sky")) || (StrEqual(mapname, "l4d2_orange04_rocket")) || 
		(StrEqual(mapname, "l4d2_scream02_goingup")) || (StrEqual(mapname, "l4d2_scream03_rooftops")) || (StrEqual(mapname, "l4d2_scream04_train")) || (StrEqual(mapname, "l4d2_scream05_finale")) || 
		(StrEqual(mapname, "gemarshy02fac")) || (StrEqual(mapname, "gemarshy03aztec")) || 
		(StrEqual(mapname, "QE2_ep2")) || (StrEqual(mapname, "qe2_ep2")) || (StrEqual(mapname, "QE2_ep3")) || (StrEqual(mapname, "qe2_ep3")) || (StrEqual(mapname, "QE2_ep4")) || (StrEqual(mapname, "qe2_ep4")) || (StrEqual(mapname, "QE2_ep5")) || (StrEqual(mapname, "qe2_ep5")) || 
		(StrEqual(mapname, "wfp2_horn")) || (StrEqual(mapname, "wfp3_mill")) || (StrEqual(mapname, "wfp4_commstation")) || 
		(StrEqual(mapname, "l4d2_diescraper2_streets_35")) || (StrEqual(mapname, "l4d2_diescraper3_mid_35")) || (StrEqual(mapname, "l4d2_diescraper4_top_35")) || 
		(StrEqual(mapname, "busbahnhof1", false)) || (StrEqual(mapname, "l4d_linz_ok", false)) || (StrEqual(mapname, "l4d_linz_zurueck", false)) || (StrEqual(mapname, "l4d_linz_bahnhof", false)) || 
		(StrEqual(mapname, "m2_burbs", false)) || (StrEqual(mapname, "m3_crowd_control", false)) || (StrEqual(mapname, "m4_launchpad", false)) || (StrEqual(mapname, "m5_station_finale", false)) || 
		(StrEqual(mapname, "hotel02_sewer_two", false)) || (StrEqual(mapname, "hotel03_ramsey_two", false)) || (StrEqual(mapname, "hotel04_scaling_two", false)) || (StrEqual(mapname, "hotel05_rooftop_two", false)) || 
		(StrEqual(mapname, "blood_hospital_01", false)) || (StrEqual(mapname, "blood_hospital_02", false)) || (StrEqual(mapname, "blood_hospital_03", false)) || 
		(StrEqual(mapname, "c11m2_offices_day", false)) || (StrEqual(mapname, "c11m3_garage_day", false)) || (StrEqual(mapname, "c11m4_terminal_day", false)) || (StrEqual(mapname, "c11m5_runway_day", false)) || 
		(StrEqual(mapname, "l4d2_the_complex_final_02", false)) || (StrEqual(mapname, "l4d2_the_complex_final_03", false)) || 
		(StrEqual(mapname, "l4d_fallen02_trenches", false)) || (StrEqual(mapname, "l4d_fallen03_tower", false)) || (StrEqual(mapname, "l4d_fallen04_cliff", false)) || (StrEqual(mapname, "l4d_fallen05_shaft", false)))
	{
		return true;
	}
	return false;
}

public Action:CmdLockAll(client, args)
{
	if (client <= 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(isBugged() || isBugged2())
	{
		checkAndLockAll();
	}
	else
	{
		blockPath();
	}
	
	return Plugin_Handled;
}

public Action:CmdUnLockAll(client, args)
{
	if (client <= 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(isBugged() || isBugged2())
	{
		checkAndUnlockAll();
	}
	else
	{
		unblockPath();
	}
	
	return Plugin_Handled;
}

checkAndLockAll()
{
	decl String:classname[] = "prop_door_rotating_checkpoint";
	new ent = -1;
	
	if (isBugged() || isBugged2())
	{
		while ((ent = Entity_FindByHammerId(getStartDoorHammerID(), classname)) != -1 || (ent = Entity_FindByHammerId(getStartDoorHammerID(), classname)) == 0)
		{
			if ((ent = Entity_FindByHammerId(getStartDoorHammerID(), classname)) == 0)
			{
				break;
			}
			Lock(ent);
			break;
		}
	}
	g_bLocked = true;
}

checkAndUnlockAll()
{
	decl String:classname[] = "prop_door_rotating_checkpoint";
	new ent = -1;
	if (isBugged() || isBugged2())
	{
		while ((ent = Entity_FindByHammerId(getStartDoorHammerID(), classname)) != -1 || (ent = Entity_FindByHammerId(getStartDoorHammerID(), classname)) == 0)
		{
			if ((ent = Entity_FindByHammerId(getStartDoorHammerID(), classname)) == 0)
			{
				break;
			}
			Unlock(ent);
			break;
		}
	}
	g_bLocked = false;
}

Lock(ent)
{
	AcceptEntityInput(ent, "Close");
	AcceptEntityInput(ent, "Lock");
	SetVariantString("spawnflags 40960");
	AcceptEntityInput(ent, "AddOutput");
	if (GetConVarInt(cvarLockGlowRange) > 0)
	{
		L4D2_SetEntGlow(ent, L4D2Glow_Constant, GetConVarInt(cvarLockGlowRange), 0, {255, 0, 0}, false);
	}
}

Unlock(ent)
{
	SetVariantString("spawnflags 8192");
	AcceptEntityInput(ent, "AddOutput");
	AcceptEntityInput(ent, "Unlock");
	if (GetConVarInt(cvarLockAutoOpen) == 1)
	{
		AcceptEntityInput(ent, "Open");
	}
	
	if (GetConVarInt(cvarLockGlowRange) > 0)
	{
		L4D2_SetEntGlow(ent, L4D2Glow_Constant, GetConVarInt(cvarLockGlowRange), 0, {0, 255, 0}, false);
	}
}

blockPath()
{
	decl Float:fnOrigin[3], Float:fnAngles[3];
	new fence = CreateEntityByName("prop_dynamic_override");
	if(StrEqual(cmap, "c1m1_hotel"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL01);
		
		fnOrigin[0] = 392.003998; fnAngles[0] = 0.409058;
		fnOrigin[1] = 5635.555176; fnAngles[1] = 178.616119;
		fnOrigin[2] = 2925.031250; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c2m1_highway"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL04);
		
		fnOrigin[0] = 10003.427734; fnAngles[0] = 6.784813;
		fnOrigin[1] = 7790.717285; fnAngles[1] = -179.112259;
		fnOrigin[2] = -516.365295; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c3m1_plankcountry"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL06);
		
		fnOrigin[0] = -12486.348633; fnAngles[0] = 1.611764;
		fnOrigin[1] = 10438.381836; fnAngles[1] = -27.414877;
		fnOrigin[2] = 244.893372; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c4m1_milltown_a"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL06);
		
		fnOrigin[0] = -6358.857422; fnAngles[0] = 1.356968;
		fnOrigin[1] = 7455.994141; fnAngles[1] = 180.000000;
		fnOrigin[2] = 95.031250; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c5m1_waterfront"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL06);
		
		fnOrigin[0] = 774.930176; fnAngles[0] = 10.659295;
		fnOrigin[1] = 512.853516; fnAngles[1] = -89.614487;
		fnOrigin[2] = -468.007050; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c6m1_riverbank"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL04);
		
		fnOrigin[0] = 916.505737; fnAngles[0] = 0.135685;
		fnOrigin[1] = 3674.522705; fnAngles[1] = -89.859390;
		fnOrigin[2] = 93.659073; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c7m1_docks"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL04);
		
		fnOrigin[0] = 13365.058594; fnAngles[0] = 0.000000;
		fnOrigin[1] = 2152.831299; fnAngles[1] = -178.208420;
		fnOrigin[2] = -94.121269; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c8m1_apartment") || StrEqual(cmap, "l4d2_hospital01_apartment"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL02);
		
		fnOrigin[0] = 1786.985718; fnAngles[0] = -1.221282;
		fnOrigin[1] = 1144.813354; fnAngles[1] = -0.271370;
		fnOrigin[2] = 432.031250; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c9m1_alleys"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL04);
		
		fnOrigin[0] = -9067.495117; fnAngles[0] = -2.968737;
		fnOrigin[1] = -9684.145508; fnAngles[1] = -92.191689;
		fnOrigin[2] = -2.509978; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c11m1_greenhouse"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL08);
		
		fnOrigin[0] = 6384.835449; fnAngles[0] = 0.000000;
		fnOrigin[1] = -437.813385; fnAngles[1] = 180.000000;
		fnOrigin[2] = 725.031250; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c12m1_hilltop") || StrEqual(cmap, "C12m1_hilltop"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL13);
		
		fnOrigin[0] = -8113.000000; fnAngles[0] = 0.000000;
		fnOrigin[1] = -15017.000000; fnAngles[1] = 161.000000;
		fnOrigin[2] = 278.000000; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c13m1_alpinecreek") || StrEqual(cmap, "c13m1_alpinecreek_night"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL04);
		
		fnOrigin[0] = -2982.207275; fnAngles[0] = 4.749351;
		fnOrigin[1] = -404.366333; fnAngles[1] = 92.358307;
		fnOrigin[2] = 78.559059; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "l4d2_orange01_city"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL03);
		
		fnOrigin[0] = -2539.044189; fnAngles[0] = -0.306694;
		fnOrigin[1] = -3554.748047; fnAngles[1] = -0.295615;
		fnOrigin[2] = 512.031250; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "l4d2_city17_01"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL12);
		
		fnOrigin[0] = 3776.000000; fnAngles[0] = 0.000000;
		fnOrigin[1] = -5044.000000; fnAngles[1] = 89.000000;
		fnOrigin[2] = -120.000000; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "bwm1_climb"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL06);
		
		fnOrigin[0] = -522.000000; fnAngles[0] = 0.000000;
		fnOrigin[1] = 702.000000; fnAngles[1] = 179.000000;
		fnOrigin[2] = 0.000000; fnAngles[2] = 0.000000;
	}
	SetEntProp(fence, Prop_Send, "m_nSolidType", 6);
	DispatchKeyValue(fence, "targetname", "anti-rush_system-l4d2_fence");
	DispatchSpawn(fence);
	TeleportEntity(fence, fnOrigin, fnAngles, NULL_VECTOR);
	
	decl Float:fn2Origin[3], Float:fn2Angles[3];
	new fence2 = CreateEntityByName("prop_dynamic_override");
	if(StrEqual(cmap, "c2m1_highway"))
	{
		DispatchKeyValue(fence2, "model", FENCE_MODEL04);
		
		fn2Origin[0] = 10003.427734; fn2Angles[0] = 6.784813;
		fn2Origin[1] = 8351.467773; fn2Angles[1] = -179.112259;
		fn2Origin[2] = -515.465454; fn2Angles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c4m1_milltown_a"))
	{
		DispatchKeyValue(fence2, "model", FENCE_MODEL04);
		
		fn2Origin[0] = -6362.469727; fn2Angles[0] = 1.476095;
		fn2Origin[1] = 7397.324707; fn2Angles[1] = 180.000000;
		fn2Origin[2] = 306.031250; fn2Angles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c8m1_apartment") || StrEqual(cmap, "l4d2_hospital01_apartment"))
	{
		DispatchKeyValue(fence2, "model", FENCE_MODEL07);
		
		fn2Origin[0] = 2153.561279; fn2Angles[0] = 90.000000;
		fn2Origin[1] = 920.078430; fn2Angles[1] = -180.000000;
		fn2Origin[2] = 410.024597; fn2Angles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c9m1_alleys"))
	{
		DispatchKeyValue(fence2, "model", FENCE_MODEL04);
		
		fn2Origin[0] = -9617.561523; fn2Angles[0] = -0.119123;
		fn2Origin[1] = -9659.479492; fn2Angles[1] = -90.020599;
		fn2Origin[2] = -2.663688; fn2Angles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c11m1_greenhouse"))
	{
		DispatchKeyValue(fence2, "model", FENCE_MODEL09);
		
		fn2Origin[0] = 6280.875000; fn2Angles[0] = 0.000000;
		fn2Origin[1] = -786.662415; fn2Angles[1] = 180.000000;
		fn2Origin[2] = 925.031250; fn2Angles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c12m1_hilltop") || StrEqual(cmap, "C12m1_hilltop"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL14);
		
		fnOrigin[0] = -8202.000000; fnAngles[0] = 0.000000;
		fnOrigin[1] = -15289.000000; fnAngles[1] = 161.000000;
		fnOrigin[2] = 333.000000; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "l4d2_city17_01"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL12);
		
		fnOrigin[0] = 4015.000000; fnAngles[0] = 0.000000;
		fnOrigin[1] = -5022.000000; fnAngles[1] = 93.000000;
		fnOrigin[2] = -124.000000; fnAngles[2] = 0.000000;
	}
	SetEntProp(fence2, Prop_Send, "m_nSolidType", 6);
	DispatchKeyValue(fence2, "targetname", "anti-rush_system-l4d2_fence");
	DispatchSpawn(fence2);
	TeleportEntity(fence2, fn2Origin, fn2Angles, NULL_VECTOR);
	
	decl Float:fn3Origin[3], Float:fn3Angles[3];
	new fence3 = CreateEntityByName("prop_dynamic_override");
	if(StrEqual(cmap, "c4m1_milltown_a"))
	{
		DispatchKeyValue(fence3, "model", FENCE_MODEL03);
		
		fn3Origin[0] = -6366.153320; fn3Angles[0] = 2.018882;
		fn3Origin[1] = 6976.294922; fn3Angles[1] = -1.210750;
		fn3Origin[2] = 232.031265; fn3Angles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c9m1_alleys"))
	{
		DispatchKeyValue(fence3, "model", FENCE_MODEL04);
		
		fn3Origin[0] = -10102.182617; fn3Angles[0] = 1.237835;
		fn3Origin[1] = -9660.498047; fn3Angles[1] = -90.156395;
		fn3Origin[2] = -5.845541; fn3Angles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c11m1_greenhouse"))
	{
		DispatchKeyValue(fence3, "model", FENCE_MODEL11);
		
		fn3Origin[0] = 6280.875000; fn3Angles[0] = 0.000000;
		fn3Origin[1] = -536.662415; fn3Angles[1] = 180.000000;
		fn3Origin[2] = 925.031250; fn3Angles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "c12m1_hilltop") || StrEqual(cmap, "C12m1_hilltop"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL14);
		
		fnOrigin[0] = -8192.000000; fnAngles[0] = 0.000000;
		fnOrigin[1] = -15236.000000; fnAngles[1] = 161.000000;
		fnOrigin[2] = 382.000000; fnAngles[2] = 0.000000;
	}
	else if(StrEqual(cmap, "l4d2_city17_01"))
	{
		DispatchKeyValue(fence, "model", FENCE_MODEL12);
		
		fnOrigin[0] = 4218.000000; fnAngles[0] = 0.000000;
		fnOrigin[1] = -5016.000000; fnAngles[1] = -93.000000;
		fnOrigin[2] = -124.000000; fnAngles[2] = 0.000000;
	}
	SetEntProp(fence3, Prop_Send, "m_nSolidType", 6);
	DispatchKeyValue(fence3, "targetname", "anti-rush_system-l4d2_fence");
	DispatchSpawn(fence3);
	TeleportEntity(fence3, fn3Origin, fn3Angles, NULL_VECTOR);
	
	g_bLocked = true;
}

unblockPath()
{
	CheatCommand(_, "ent_fire", "anti-rush_system-l4d2_fence KillHierarchy");
	
	g_bLocked = false;
}

clearVariables()
{
	g_bLocked = true;
	if (g_iRoundCounter == 1)
	{
		g_iCooldown = GetConVarInt(cvarLockRoundOne);
	}
	else if (g_iRoundCounter == 2)
	{
		g_iCooldown = GetConVarInt(cvarLockRoundTwo);
	}
}

Entity_FindByHammerId(hammerId, const String:class[] = "")
{
	if (class[0] == '\0')
	{
		new realMaxEntities = GetMaxEntities() * 2;
		for (new entity=0; entity < realMaxEntities; entity++)
		{
			if (!IsValidEntity(entity))
			{
				continue;
			}
			
			if (Entity_GetHammerId(entity) == hammerId)
			{
				return entity;
			}
		}
	}
	else
	{
		new entity = INVALID_ENT_REFERENCE;
		while ((entity = FindEntityByClassname(entity, class)) != INVALID_ENT_REFERENCE)
		{
			if (Entity_GetHammerId(entity) == hammerId)
			{
				return entity;
			}
		}
	}
	
	return INVALID_ENT_REFERENCE;
}

Entity_GetHammerId(entity)
{	
	return GetEntProp(entity, Prop_Data, "m_iHammerID");
}

stock CheatCommand(client = 0, String:command[], String:arguments[] = "")
{
	if (!client || !IsClientInGame(client))
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				client = target;
				break;
			}
		}
		if (!client || !IsClientInGame(client))
		{
			return;
		}
	}
	
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}

