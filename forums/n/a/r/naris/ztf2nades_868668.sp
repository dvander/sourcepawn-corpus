/**
 * vim: set ai ts=4 sw=4 :
 * File: tf2nades.sp
 * Description: dis is z tf2nades.
 * Author(s): L. Duke
 * Modified by: -=|JFH|=-Naris (Murray Wilson)
 *              -- Added native interface
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0.7"

public Plugin:myinfo = {
	name = "tf2nades",
	author = "L. Duke",
	description = "adds nades to TF2",
	version = PLUGIN_VERSION,
	url = "http://www.lduke.com/"
};

// *************************************************
// defines
// *************************************************

new bool:gDebug = false;

#define MAX_PLAYERS 33   // maxplayers + sourceTV

#define SCOUT 1
#define SNIPER 2
#define SOLDIER 3
#define DEMO 4
#define MEDIC 5
#define HEAVY 6
#define PYRO 7
#define SPY 8
#define ENGIE 9
#define CLS_MAX 10

enum NadeType
{
	DefaultNade = 0, // use class for nade type
	ConcNade,
	BearTrap,
	NailNade,
	MirvNade,
	HealthNade,
	HeavyNade,
	NapalmNade,
	HallucNade,
	EmpNade,
	Bomblet,
	TargetingDrone,
	FragNade
};

enum HoldType
{
	HoldNone = 0,
	HoldFrag,
	HoldSpecial,
	HoldOther
};

#define MIRV_PARTS 5

#define MDL_FRAG "models/weapons/nades/duke1/w_grenade_frag.mdl"
#define MDL_CONC "models/weapons/nades/duke1/w_grenade_conc.mdl"
#define MDL_NAIL "models/weapons/nades/duke1/w_grenade_nail.mdl"
#define MDL_MIRV1 "models/weapons/nades/duke1/w_grenade_mirv.mdl"
#define MDL_MIRV2 "models/weapons/nades/duke1/w_grenade_bomblet.mdl"
#define MDL_HEALTH "models/weapons/nades/duke1/w_grenade_heal.mdl"
#define MDL_NAPALM "models/weapons/nades/duke1/w_grenade_napalm.mdl"
#define MDL_HALLUC "models/weapons/nades/duke1/w_grenade_gas.mdl"
#define MDL_EMP "models/weapons/nades/duke1/w_grenade_emp.mdl"
#define MDL_TRAP "models/weapons/w_models/w_grenade_beartrap.mdl"

#define MDL_RING_MODEL "sprites/laser.vmt"
#define MDL_NAPALM_SPRITE "sprites/floorfire4_.vmt"
#define MDL_BEAM_SPRITE "sprites/laser.vmt"
#define MDL_EMP_SPRITE "sprites/laser.vmt"

// sounds
#define SND_THROWNADE "weapons/grenade_throw.wav"
#define SND_NADE_FRAG "weapons/explode1.wav"
#define SND_NADE_CONC "weapons/explode5.wav"
#define SND_NADE_NAIL "ambient/levels/labs/teleport_rings_loop2.wav"
#define SND_NADE_NAIL_EXPLODE "weapons/explode1.wav"
#define SND_NADE_NAIL_SHOOT1 "npc/turret_floor/shoot1.wav"
#define SND_NADE_NAIL_SHOOT2 "npc/turret_floor/shoot2.wav"
#define SND_NADE_NAIL_SHOOT3 "npc/turret_floor/shoot3.wav"
#define SND_NADE_MIRV1 "weapons/sentry_explode.wav"
#define SND_NADE_MIRV2 "weapons/explode1.wav"
#define SND_NADE_NAPALM "ambient/fire/gascan_ignite1.wav"
#define SND_NADE_HEALTH "items/suitchargeok1.wav"
#define SND_NADE_HALLUC "weapons/flame_thrower_airblast.wav"
#define SND_NADE_EMP "npc/scanner/scanner_electric2.wav"
#define SND_NADE_TRAP "weapons/grenade_impact.wav"


new String:sndPain[128] = "player/pain.wav";


#define STRLENGTH 128

// *************************************************
// globals 
// *************************************************

// global data for current nade
new Float:gnSpeed;
new Float:gnDelay;
new String:gnModel[256];
new String:gnSkin[16];
new String:gnParticle[256];

#define OFFSIZE 4000
//new gOff[OFFSIZE];

new bool:gCanRun = false;
new bool:gWaitOver = false;
new Float:gMapStart;
new gRemaining1[MAX_PLAYERS+1];						// how many nades player has this spawn
new gRemaining2[MAX_PLAYERS+1];						// how many nades player has this spawn
new HoldType:gHolding[MAX_PLAYERS+1];				// what kind od nade player is holding
new Handle:gNadeTimer[MAX_PLAYERS+1];				// pointer to nade timer
new Handle:gNadeTimer2[MAX_PLAYERS+1];
new bool:gTriggerTimer[MAX_PLAYERS+1];
new gNade[MAX_PLAYERS+1];							// pointer to the player's nade
new gNadeTemp[MAX_PLAYERS+1];						// temp nade entity (like for nail nade)
new gTargeted[MAX_PLAYERS+1];                      // flag is player is targetted and by whom.
new gRingModel;										// model for beams
new Float:PlayersInRange[MAX_PLAYERS+1];			// players are in radius ?
new gKilledBy[MAX_PLAYERS+1];						// player that killed
new String:gKillWeapon[MAX_PLAYERS+1][STRLENGTH];	// weapon that killed
new Float:gKillTime[MAX_PLAYERS+1];					// time plugin requested kill
new gNapalmSprite;									// sprite index
new gBeamSprite;									// sprite index
new gEmpSprite;
new gStopInfoPanel[MAX_PLAYERS+1];

new Float:gHoldingArea[3] = {-10000.0, -10000.0, -10000.0};	// point to store unused objects

new Handle:g_precacheTrie = INVALID_HANDLE;

new g_FragModelIndex;
new g_ConcModelIndex;
new g_NailModelIndex;
new g_Mirv1ModelIndex;
new g_Mirv2ModelIndex;
new g_HealthModelIndex;
new g_NapalmModelIndex;
new g_HallucModelIndex;
new g_TrapModelIndex;
new g_EmpModelIndex;

#pragma unused g_TrapModelIndex

// global "temps"
new String:tName[256];

// *************************************************
// convars
// *************************************************
new Handle:cvWaitPeriod = INVALID_HANDLE;
new Handle:cvNadeType[CLS_MAX];
new Handle:cvFragNum[CLS_MAX];
new Handle:cvFragRadius = INVALID_HANDLE;
new Handle:cvFragDamage = INVALID_HANDLE;
new Handle:cvConcNum = INVALID_HANDLE;
new Handle:cvConcRadius = INVALID_HANDLE;
new Handle:cvConcForce = INVALID_HANDLE;
new Handle:cvConcDamage = INVALID_HANDLE;
new Handle:cvNailNum = INVALID_HANDLE;
new Handle:cvNailRadius = INVALID_HANDLE;
new Handle:cvNailDamageNail = INVALID_HANDLE;
new Handle:cvNailDamageExplode = INVALID_HANDLE;
new Handle:cvMirvNum = INVALID_HANDLE;
new Handle:cvMirvRadius = INVALID_HANDLE;
new Handle:cvMirvDamage1 = INVALID_HANDLE;
new Handle:cvMirvDamage2 = INVALID_HANDLE;
new Handle:cvMirvSpread = INVALID_HANDLE;
new Handle:cvHealthNum = INVALID_HANDLE;
new Handle:cvHealthRadius = INVALID_HANDLE;
new Handle:cvHealthDelay = INVALID_HANDLE;
new Handle:cvNapalmNum = INVALID_HANDLE;
new Handle:cvNapalmRadius = INVALID_HANDLE;
new Handle:cvNapalmDamage = INVALID_HANDLE;
new Handle:cvHallucNum = INVALID_HANDLE;
new Handle:cvHallucRadius = INVALID_HANDLE;
new Handle:cvHallucDelay = INVALID_HANDLE;
new Handle:cvHallucDamage = INVALID_HANDLE;
new Handle:cvTrapNum = INVALID_HANDLE;
new Handle:cvTrapRadius = INVALID_HANDLE;
new Handle:cvTrapDamage = INVALID_HANDLE;
new Handle:cvTrapDelay = INVALID_HANDLE;
new Handle:cvBombNum = INVALID_HANDLE;
new Handle:cvBombRadius = INVALID_HANDLE;
new Handle:cvBombDamage = INVALID_HANDLE;
new Handle:cvEmpNum = INVALID_HANDLE;
new Handle:cvEmpRadius = INVALID_HANDLE;
new Handle:cvHelpLink = INVALID_HANDLE;
new Handle:cvAnnounce = INVALID_HANDLE;
new Handle:cvShowHelp = INVALID_HANDLE;
new Handle:cvDroneDamage = INVALID_HANDLE;
//new Handle:cvTest = INVALID_HANDLE;

// *************************************************
// native interface variables
// *************************************************

new gAllowed1[MAX_PLAYERS+1];   		// how many frag nades player given each spawn
new gAllowed2[MAX_PLAYERS+1];   		// how many special nades player given each spawn
new bool:gCanRestock[MAX_PLAYERS+1];   	// is the player allowed to restock at a cabinet
new NadeType:gSpecialType[MAX_PLAYERS+1];		// what nade type the special nade is

new bool:gNativeOverride = false;
new bool:gTargetOverride = false;

// *************************************************
// main plugin
// *************************************************

public OnPluginStart() {
	// events
	HookEvent("player_spawn",PlayerSpawn);
	HookEvent("player_hurt",PlayerHurt);
	HookEvent("player_death",PlayerDeath, EventHookMode_Pre);
	HookEvent("player_changeclass", ChangeClass);

	HookEvent("arena_round_start", MainEvents);
	HookEvent("teamplay_round_start", MainEvents);
	HookEvent("teamplay_round_active", MainEvents);
	HookEvent("teamplay_restart_round", MainEvents);

	HookEvent("teamplay_round_stalemate", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_game_over", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", RoundEnd, EventHookMode_PostNoCopy);
	
	
	// convars
	cvWaitPeriod = CreateConVar("sm_tf2nades_waitperiod", "1", "server waits for players on map start (1=true 0=false)");
	cvShowHelp = CreateConVar("sm_tf2nades_showhelp", "0", "show help link at player spawn (until they say !stop) (1=yes 0=no)");
	cvHelpLink = CreateConVar("sm_tf2nades_helplink", "http://www.tf2nades.com/motd/plugin/tf2nades.1.0.0.6.html", "web page with info on the TF2NADES plugin");
	cvAnnounce = CreateConVar("sm_tf2nades_announce", "1", "show what keys to bind when players connect (1=yes 0=no)");
	cvEmpRadius = CreateConVar("sm_tf2nades_emp_radius", "256", "radius for emp nade", 0, true, 1.0, true, 2048.0);
	cvEmpNum = CreateConVar("sm_tf2nades_emp", "3", "number of emp nades given", 0, true, 0.0, true, 10.0); 
	cvHallucDamage = CreateConVar("sm_tf2nades_halluc_damage", "5", "damage done by hallucination nade");
	cvHallucDelay = CreateConVar("sm_tf2nades_hallucination_time", "5.0", "delay in seconds that effects last", 0, true, 1.0, true, 10.0);	
	cvHallucRadius = CreateConVar("sm_tf2nades_hallucination_radius", "256", "radius for hallucination nade", 0, true, 1.0, true, 2048.0);
	cvHallucNum = CreateConVar("sm_tf2nades_hallucination", "3", "number of hallucination nades given", 0, true, 0.0, true, 10.0); 
	cvNapalmDamage = CreateConVar("sm_tf2nades_napalm_damage", "25", "initial damage for napalm nade", 0, true, 1.0, true, 500.0);
	cvNapalmRadius = CreateConVar("sm_tf2nades_napalm_radius", "256", "radius for napalm nade", 0, true, 1.0, true, 2048.0);
	cvNapalmNum = CreateConVar("sm_tf2nades_napalm", "2", "number of napalm nades given", 0, true, 0.0, true, 10.0); 
	cvHealthDelay = CreateConVar("sm_tf2nades_health_delay", "5.0", "delay in seconds before nade explodes", 0, true, 1.0, true, 10.0);
	cvHealthRadius = CreateConVar("sm_tf2nades_health_radius", "256", "radius for health nade", 0, true, 1.0, true, 2048.0);
	cvHealthNum = CreateConVar("sm_tf2nades_health", "2", "number of health nades given", 0, true, 0.0, true, 10.0); 
	cvMirvSpread = CreateConVar("sm_tf2nades_mirv_spread", "384.0", "spread of secondary explosives (max speed)", 0, true, 1.0, true, 2048.0);	
	cvMirvDamage2 = CreateConVar("sm_tf2nades_mirv_damage2", "50.0", "damage done by secondary explosion of mirv nade", 0, true, 1.0, true, 500.0);	
	cvMirvDamage1 = CreateConVar("sm_tf2nades_mirv_damage1", "25.0", "damage done by main explosion of mirv nade", 0, true, 1.0, true, 500.0);
	cvMirvRadius = CreateConVar("sm_tf2nades_mirv_radius", "128", "radius for demo's nade", 0, true, 1.0, true, 2048.0);
	cvMirvNum = CreateConVar("sm_tf2nades_mirv", "2", "number of MIRV nades given", 0, true, 0.0, true, 10.0); 
	cvNailDamageExplode = CreateConVar("sm_tf2nades_nail_explodedamage", "100.0", "damage done by final explosion", 0, true, 1.0, true,1000.0);
	cvNailDamageNail = CreateConVar("sm_tf2nades_nail_naildamage", "8.0", "damage done by nail projectile", 0, true, 1.0, true, 500.0);
	cvNailRadius = CreateConVar("sm_tf2nades_nail_radius", "256", "radius for nail nade", 0, true, 1.0, true, 2048.0);
	cvNailNum = CreateConVar("sm_tf2nades_nail", "2", "number of nail nades given", 0, true, 0.0, true, 10.0);
	cvConcDamage = CreateConVar("sm_tf2nades_conc_damage", "10", "damage done by concussion nade");
	cvConcForce = CreateConVar("sm_tf2nades_conc_force", "750", "force applied by concussion nade");
	cvConcRadius = CreateConVar("sm_tf2nades_conc_radius", "256", "radius for concussion nade", 0, true, 1.0, true, 2048.0);
	cvConcNum = CreateConVar("sm_tf2nades_conc", "3", "number of concussion nades given", 0, true, 0.0, true, 10.0);
	cvBombNum = CreateConVar("sm_tf2nades_bomblet", "2", "number of bomblets given", 0, true, 0.0, true, 10.0); 
	cvBombRadius = CreateConVar("sm_tf2nades_bomblet_radius", "128", "radius for bomblets", 0, true, 1.0, true, 2048.0);
	cvBombDamage = CreateConVar("sm_tf2nades_bomblet_damage", "50.0", "damage done by bomblets", 0, true, 1.0, true, 500.0);	
	cvTrapRadius = CreateConVar("sm_tf2nades_trap_radius", "128", "radius for beartrap", 0, true, 1.0, true, 2048.0);
	cvTrapDamage = CreateConVar("sm_tf2nades_trap_damage", "10", "damage done by beartrap");
	cvTrapNum = CreateConVar("sm_tf2nades_trap", "2", "number of traps given", 0, true, 0.0, true, 10.0); 
	cvTrapDelay = CreateConVar("sm_tf2nades_trap_time", "5.0", "delay in seconds that effects last", 0, true, 1.0, true, 10.0);	
	cvFragDamage = CreateConVar("sm_tf2nades_frag_damage", "100", "damage done by concussion nade");
	cvFragRadius = CreateConVar("sm_tf2nades_frag_radius", "256", "radius for concussion nade", 0, true, 1.0, true, 2048.0);
	cvDroneDamage = CreateConVar("sm_tf2nades_drone_damage", "50", "damage bonus done by targetting drone");	
	cvNadeType[ENGIE] = CreateConVar("sm_tf2nades_engineer_type", "9", "type of special nades given to engineers (0=none, 9=Emp, etc)", 0, true, 0.0, true, 11.0);
	cvNadeType[SPY] = CreateConVar("sm_tf2nades_spy_type", "8", "type of special nade given to spys (0=none, 8=Hallucination, etc)", 0, true, 0.0, true, 11.0);
	cvNadeType[PYRO] = CreateConVar("sm_tf2nades_pyro_type", "7", "type of special nade given to pyros (0=none, 7=Napalm, etc)", 0, true, 0.0, true, 11.0);
	cvNadeType[HEAVY] = CreateConVar("sm_tf2nades_heavy_type", "6", "type of special nade given to heavys (0=none, 6=Heavy Mirv, etc)", 0, true, 0.0, true, 11.0);
	cvNadeType[MEDIC] = CreateConVar("sm_tf2nades_medic_type", "5", "type of special nade given to medics (0=none, 5=Health, etc)", 0, true, 0.0, true, 11.0);
	cvNadeType[DEMO] = CreateConVar("sm_tf2nades_demo_type", "4", "type of special nade given to demo men (0=none, 4=Mirv, etc)", 0, true, 0.0, true, 11.0);
	cvNadeType[SOLDIER] = CreateConVar("sm_tf2nades_soldier_type", "3", "type of special nade given to soldiers (0=none, 3=Nail, etc)", 0, true, 0.0, true, 11.0);
	cvNadeType[SNIPER] = CreateConVar("sm_tf2nades_sniper_type", "2", "type of special nade given to snipers (0=none, 2=Beartrap, 10=Bomblet, 11=Frag, etc)", 0, true, 0.0, true, 11.0);
	cvNadeType[SCOUT] = CreateConVar("sm_tf2nades_scout_type", "1", "type of special nade given to scouts (0=none, 1=Concussion, etc)", 0, true, 0.0, true, 11.0);
	cvFragNum[ENGIE] = CreateConVar("sm_tf2nades_frag_engineer", "2", "number of frag nades given to engineers", 0, true, 0.0, true, 10.0);
	cvFragNum[SPY] = CreateConVar("sm_tf2nades_frag_spy", "2", "number of frag nades given to spys", 0, true, 0.0, true, 10.0);
	cvFragNum[PYRO] = CreateConVar("sm_tf2nades_frag_pyro", "2", "number of frag nades given to pyros", 0, true, 0.0, true, 10.0);
	cvFragNum[HEAVY] = CreateConVar("sm_tf2nades_frag_heavy", "2", "number of frag nades given to heavys", 0, true, 0.0, true, 10.0);
	cvFragNum[MEDIC] = CreateConVar("sm_tf2nades_frag_medic", "2", "number of frag nades given to medics", 0, true, 0.0, true, 10.0);
	cvFragNum[DEMO] = CreateConVar("sm_tf2nades_frag_demo", "2", "number of frag nades given to demo men", 0, true, 0.0, true, 10.0);
	cvFragNum[SOLDIER] = CreateConVar("sm_tf2nades_frag_soldier", "2", "number of frag nades given to soldiers", 0, true, 0.0, true, 10.0);
	cvFragNum[SNIPER] = CreateConVar("sm_tf2nades_frag_sniper", "2", "number of frag nades given to snipers", 0, true, 0.0, true, 10.0);
	cvFragNum[SCOUT] = CreateConVar("sm_tf2nades_frag_scout", "2", "number of frag nades given to scouts", 0, true, 0.0, true, 10.0);
	CreateConVar("sm_tf2nades_version", PLUGIN_VERSION, "TF2NADES version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//cvTest = CreateConVar("sm_tf2nades_test", "3.0");
	
	
	// commands
	RegConsoleCmd("+nade1", Command_Nade1);
	RegConsoleCmd("-nade1", Command_UnNade1);
	RegConsoleCmd("+nade2", Command_Nade2);
	RegConsoleCmd("-nade2", Command_UnNade2);
	
	RegConsoleCmd("testpart", Command_TestPart);
	RegConsoleCmd("testtel", Command_TestTel);
	RegConsoleCmd("testnades", Command_TestNades);
	RegConsoleCmd("testscore", Command_TestScore);
	RegConsoleCmd("testbuild", Command_TestBuild);
	
	RegConsoleCmd("sm_stop", Command_Stop, "stop the info panel from showing");
	RegConsoleCmd("sm_nades", Command_NadeInfo, "view info on tf2nades plugin");

	RegConsoleCmd("say",SayCommand);
	RegConsoleCmd("say_team",SayCommand);
	
	// misc setup
	LoadTranslations("tf2nades.phrases");
	
	// hooks
	HookEntityOutput("prop_dynamic", "OnAnimationBegun", EntityOutput_OnAnimationBegun);
}


/*
public OnPluginEnd()
{
	UnhookEvent("player_spawn",PlayerSpawn);
	UnhookEvent("player_death",PlayerDeath);
}
*/


public OnMapStart()
{
	// initialize model for nades (until class is chosen)
	gnSpeed = 100.0;
	gnDelay = 2.0;
	
	// precache models
	gRingModel = 0; // PrecacheModel(MDL_RING_MODEL, true);
	gNapalmSprite = 0; // PrecacheModel(MDL_NAPALM_SPRITE, true);
	gBeamSprite = 0; // PrecacheModel(MDL_BEAM_SPRITE, true);
	gEmpSprite = 0; // PrecacheModel(MDL_EMP_SPRITE, true);
	PrecacheNadeModels();
	
	// precache sounds
	//PrecacheSound(SND_THROWNADE, true);
	//PrecacheSound(SND_NADE_FRAG, true);
	//PrecacheSound(SND_NADE_CONC, true);
	//PrecacheSound(SND_NADE_NAIL, true);
	//PrecacheSound(SND_NADE_NAIL_EXPLODE, true);
	//PrecacheSound(SND_NADE_NAIL_SHOOT1, true);
	//PrecacheSound(SND_NADE_NAIL_SHOOT2, true);
	//PrecacheSound(SND_NADE_NAIL_SHOOT3, true);
	//PrecacheSound(SND_NADE_MIRV1, true);
	//PrecacheSound(SND_NADE_MIRV2, true);
	//PrecacheSound(SND_NADE_HEALTH, true);
	//PrecacheSound(SND_NADE_NAPALM, true);
	//PrecacheSound(SND_NADE_HALLUC, true);
	//PrecacheSound(SND_NADE_EMP, true);
	//PrecacheSound(sndPain, true);
	SetupPreloadTrie();
	
	// reset status
	gCanRun = false;
	gWaitOver = false;
	gMapStart = GetEngineTime();
	MainEvents(INVALID_HANDLE, "map_start", true);
}

public OnConfigsExecuted()
{
	TagsCheck("tf2nades");
}

public OnClientPutInServer(client)
{
	FireTimers(client);
	
	// kill hooks
	gKilledBy[client]=0;
	gKillTime[client] = 0.0;
	gKillWeapon[client][0]='\0';
	if (GetConVarInt(cvShowHelp)==1)
	{
		gStopInfoPanel[client] = false;
	}
	else
	{
		gStopInfoPanel[client] = true;
	}

	// Reset the targeted flags
	for (new index=1;index<=MaxClients;index++)
	{
		if (gTargeted[index] == client)
			gTargeted[index] = 0;
	}

	if (!gNativeOverride && GetConVarInt(cvAnnounce)==1)
		CreateTimer(45.0, Timer_Anounce, client);
}

public Action:Timer_Anounce(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		if (!gNativeOverride && GetConVarInt(cvAnnounce)==1)
		{
			PrintToChat(client, "[SM] Bind a key to +nade1 to throw a frag nade");
			PrintToChat(client, "[SM] Bind a key to +nade2 to throw a special nade");
			PrintToChat(client, "[SM] Type !nade for more information");
		}
	}
}

public Action:MainEvents(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvWaitPeriod)==1)
	{
		if (StrEqual(name,"teamplay_restart_round", false))
		{
			gCanRun = true;
			gWaitOver = true;
		}
	}
	else
	{
		if (!StrEqual(name, "map_start"))
		{
			gCanRun = true;
			gWaitOver = true;
		}
	}
	
	if (gWaitOver)
	{
		if (StrEqual(name, "teamplay_round_start"))
		{
			gCanRun = false;
		}
		else if (StrEqual(name, "teamplay_round_active"))
		{
			gCanRun = true;
		}
		else if (StrEqual(name, "arena_round_start"))
		{
			gCanRun = true;
		}
	}

	// reset players
	for (new i=1;i<=MAX_PLAYERS;i++)
	{
		// nades
		gNade[i]=0;
		gNadeTemp[i]=0;
		gTriggerTimer[i] = false;
		
		// kill hooks
		gKilledBy[i]=0;
		gKillTime[i] = 0.0;
		gKillWeapon[i][0]='\0';
	}

	// Reset the all the targeted flags
	for (new index=1;index<=MaxClients;index++)
			gTargeted[index] = 0;

	return Plugin_Continue;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	gCanRun = false;
}


public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	gHolding[client]=HoldNone;
	
	if (!gStopInfoPanel[client])
	{
		new String:helplink[512];
		GetConVarString(cvHelpLink, helplink, sizeof(helplink));
		ShowMOTDPanel(client, "TF2NADES", helplink, MOTDPANEL_TYPE_URL);
	}

	if (!gCanRun)
	{
		if (GetEngineTime() > (gMapStart + 60.0))
		{
			gCanRun = true;
		}
		else
		{
			return Plugin_Continue;
		}
	}

	// client info
	new String:clientname[32];
	Format(clientname, sizeof(clientname), "tf2player%d", client);
	DispatchKeyValue(client, "targetname", clientname);

	SetupNade(GiveFullNades(client), GetClientTeam(client), true);

	FireTimers(client);
	gNadeTimer[client]=INVALID_HANDLE;

	decl String:edictname[128];
	new ents = GetMaxEntities();
	for (new i=MaxClients+1; i<ents; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, edictname, sizeof(edictname));
			if (StrEqual(edictname, "prop_physics") || StrEqual(edictname, "prop_dynamic"))
			{
				if (GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity")==client)
				{
					GetEntPropString(i, Prop_Data, "m_ModelName", edictname, sizeof(edictname));
					if (strncmp(edictname, "models/weapons/nades/duke1", 26) == 0)
					{
						RemoveEdict(i);
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:PlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (!gTargetOverride)
	{
		new victim = GetClientOfUserId(GetEventInt(event,"userid"));
		if (victim > 0)
		{
			new client = gTargeted[victim];
			if (client > 0)
			{
				new damage = GetConVarInt(cvDroneDamage);
				HurtPlayer(victim, client, damage, "tf2nade_drone", false, NULL_VECTOR);
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public EntityOutput_OnAnimationBegun(const String:output[], caller, activator, Float:delay)
{
	if (IsValidEntity(caller))
	{
		new String:modelname[128];
		GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, "models/props_gameplay/resupply_locker.mdl"))
		{
			new Float:pos[3];
			GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
			FindPlayersInRange(pos, 128.0, 0, -1, false, -1);
			for (new j=1;j<=MaxClients;j++)
			{
				if (PlayersInRange[j]>0.0)
				{
					if (!gNativeOverride || gCanRestock[j])
						GiveFullNades(j);
				}
			}
		}
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	gRemaining1[client] = 0;
	gRemaining2[client] = 0;
	gHolding[client] = HoldNone;
	
	new weaponid = GetEventInt(event, "weaponid");
	
	/*
	PrintToServer("userid %d", GetEventInt(event, "userid"));
	PrintToServer("attacker %d", GetEventInt(event, "attacker"));
	GetEventString(event, "weapon", tName, sizeof(tName));
	PrintToServer("weapon %s", tName);
	PrintToServer("weaponid %d", GetEventInt(event, "weaponid"));
	PrintToServer("damagebits %d", GetEventInt(event, "damagebits"));
	PrintToServer("dominated %d", GetEventInt(event, "dominated"));
	PrintToServer("assister_dominated %d", GetEventInt(event, "assister_dominated"));
	PrintToServer("revenge %d", GetEventInt(event, "revenge"));
	PrintToServer("assister_revenge %d", GetEventInt(event, "assister_revenge"));
	GetEventString(event, "weapon_logclassname", tName, sizeof(tName));
	PrintToServer("weapon_logclassname %s", tName);
	*/
	
	if (gKilledBy[client]>0 && weaponid==0)
	{
		if ( (GetEngineTime()-gKillTime[client]) < 0.5)
		{
			SetEventInt(event, "attacker", gKilledBy[client]);
			SetEventInt(event, "weaponid", 100);
			SetEventString(event, "weapon", gKillWeapon[client]);
			SetEventString(event, "weapon_logclassname", gKillWeapon[client]);
		}
	}
	
	// kill hooks
	gKilledBy[client]=0;
	gKillTime[client] = 0.0;
	gKillWeapon[client][0]='\0';
	
	return Plugin_Continue;
}

public Action:ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new class = GetEventInt(event, "class");
	gRemaining1[client] = 0;
	gRemaining2[client] = 0;
	gHolding[client] = HoldNone;
	
	FireTimers(client);
}

public Action:Command_Nade1(client, args) 
{
	if (gHolding[client]>HoldNone)
		return Plugin_Handled;
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	// not while cloaked or taunting
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond&16 || cond&128)
	{
		return Plugin_Handled;
	}
	
	SetupHudMsg(3.0);
	if (!gCanRun)
	{
		ShowHudText(client, 1, "%t", "WaitingPeriod");
		return Plugin_Handled;
	}
	
	if (gTriggerTimer[client])
	{
		gTriggerTimer[client] = false;
		gNadeTimer[client]=INVALID_HANDLE;
	}

	if (gNadeTimer[client]==INVALID_HANDLE)
	{
		if (gRemaining1[client]>0)
		{
			if (cond&8)
				TF2_RemovePlayerDisguise(client);

			ThrowNade(client, true, HoldFrag, DefaultNade);
			gRemaining1[client]--;
			ShowHudText(client, 1, "%t", "Nades1Remaining", gRemaining1[client]);
		}
		else
		{
			ShowHudText(client, 1, "%t", "NoNades1");
		}
	}
	else
	{
		ShowHudText(client, 1, "%t", "OnlyOneNade");
	}
	return Plugin_Handled;
}

public Action:Command_UnNade1(client, args)
{
	if (gHolding[client]!=HoldFrag)
		return Plugin_Handled;
	
	if (gNadeTimer[client]!=INVALID_HANDLE)
	{
		ThrowNade(client, false, HoldFrag, DefaultNade);
	}
	return Plugin_Handled;
}

public Action:Command_Nade2(client, args) 
{
	if (gHolding[client]>HoldNone)
		return Plugin_Handled;
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	// not while cloaked or taunting
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond&16 || cond&128)
	{
		return Plugin_Handled;
	}
	
	SetupHudMsg(3.0);
	if (!gCanRun)
	{
		ShowHudText(client, 1, "%t", "WaitingPeriod");
		return Plugin_Handled;
	}
	
	if (gTriggerTimer[client])
	{
		gTriggerTimer[client] = false;
		gNadeTimer[client]=INVALID_HANDLE;
	}

	if (gNadeTimer[client]==INVALID_HANDLE)
	{
		if (gRemaining2[client]>0)
		{
			if (cond&8)
				TF2_RemovePlayerDisguise(client);

			ThrowNade(client, true, HoldSpecial, DefaultNade);
			gRemaining2[client]--;
			ShowHudText(client, 1, "%t", "Nades2Remaining", gRemaining2[client]);
		}
		else
		{
			ShowHudText(client, 1, "%t", "NoNades2");
		}
	}
	else
	{
		ShowHudText(client, 1, "%t", "OnlyOneNade");
	}
	return Plugin_Handled;
}

public Action:Command_UnNade2(client, args)
{
	if (gHolding[client]!=HoldSpecial)
		return Plugin_Handled;
	
	if (gNadeTimer[client]!=INVALID_HANDLE)
	{
		ThrowNade(client, false, HoldSpecial, DefaultNade);
	}
	return Plugin_Handled;
}

public Action:Command_Stop(client, args) 
{
	gStopInfoPanel[client] = true;
	return Plugin_Handled;
}

public Action:Command_NadeInfo(client, args) 
{
	new String:helplink[512];
	GetConVarString(cvHelpLink, helplink, sizeof(helplink));
	ShowMOTDPanel(client, "TF2NADES", helplink, MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}


public Action:Command_TestPart(client, args) {
	if (!gDebug)
	{
		ReplyToCommand(client, "debug only!");
		return Plugin_Handled;
	}
	
	new String:particle[256];
	GetCmdArg(1, particle, sizeof(particle));
	new Float:eyes[3], Float:angle[3], Float:pos[3];
	GetClientEyePosition(client, eyes);
	GetClientEyeAngles(client, angle);
	GetAngleVectors(angle, pos, NULL_VECTOR,NULL_VECTOR);
	pos[0]*=256.0;
	pos[1]*=256.0;
	pos[2]*=256.0;
	AddVectors(eyes, pos, pos);
	ShowParticle(pos, particle, 2.0);

	return Plugin_Handled;
}

public Action:Command_TestTel(client, args) {
	if (!gDebug)
	{
		ReplyToCommand(client, "debug only!");
		return Plugin_Handled;
	}
	new Float:angles[3];
	new String:tmp[64];
	GetCmdArg(1, tmp, sizeof(tmp));
	angles[0] = StringToFloat(tmp);
	GetCmdArg(2, tmp, sizeof(tmp));
	angles[1] = StringToFloat(tmp);
	GetCmdArg(3, tmp, sizeof(tmp));
	angles[2] = StringToFloat(tmp);
	
	TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
	
	return Plugin_Handled;
}

public Action:Command_TestNades(client, args)
{
	if (!gDebug)
	{
		ReplyToCommand(client, "debug only!");
		return Plugin_Handled;
	}
	
	for (new j=1;j<=MaxClients;j++)
	{
		if (IsPlayerAlive(j))
		{
			//new oteam;
			//if (GetClientTeam(client)==3) {oteam=2;} else {oteam=3;}
			//TF2_DisguisePlayer(j, GetClientTeam(client), ENGIE);
			Command_Nade2(j, args);
		}
	}
	return Plugin_Handled;
}

public Action:Command_TestScore(client, args) {
	if (!gDebug)
	{
		ReplyToCommand(client, "debug only!");
		return Plugin_Handled;
	}
	
	new String:strScore[256];
	GetCmdArg(1, strScore, sizeof(strScore));
	//new val = StringToInt(strScore);
	
	/*
	if (val==-1)
	{
	for (new i=0;i<OFFSIZE;i++)
	{
	gOff[i]=-1;
	}
	ReplyToCommand(client, "offsets reset");
	}
	else
	{
	new count=0;
	new tval;
	for (new i=1;i<OFFSIZE;i++)
	{
	tval = GetEntData(client, i, 2);
	if (tval==val)
	{
	if (gOff[0]==-1)
	{
	gOff[i] = val;
	count++;
	}
	else
	{
	if (gOff[i]>-1)
	{
	gOff[i] = val;
	count++;
	}
	}
	}
	else
	{
	gOff[i]=-1;
	}
	}
	if (gOff[0]==-1)
	{
	gOff[0] = 0;
	}
	ReplyToCommand(client, "%d offsets found", count);
	if (count<20)
	{
	for (i=1;i<OFFSIZE;i++)
	{
	if (gOff[i]>-1)
	{
	ReplyToCommand(client, "%d", i);
	}
	}
	}
	}
	*/
	
	return Plugin_Handled;
}

public Action:Command_TestBuild(client, args) {
	if (!gDebug)
	{
		ReplyToCommand(client, "debug only!");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, tName, sizeof(tName));
	new attacker = StringToInt(tName);
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	DamageBuildings(attacker, pos, 256.0, 500, client, true);
	return Plugin_Handled;
	
}

GetNade(client)
{
	// spawn the nade entity if required
	new bool:makenade = false;
	if (gNade[client]>0 && IsValidEntity(gNade[client]))
	{
		GetEntPropString(gNade[client], Prop_Data, "m_iName", tName, sizeof(tName));
		makenade = (strncmp(tName,"tf2nade",7) != 0);
	}
	else
	{ 
		makenade = true;
	}

	if (makenade)
	{
		gNade[client] = CreateEntityByName("prop_physics");
		if (IsValidEntity(gNade[client]))
		{
			SetEntPropEnt(gNade[client], Prop_Data, "m_hOwnerEntity", client);
			SetEntityModel(gNade[client], gnModel);
			SetEntityMoveType(gNade[client], MOVETYPE_VPHYSICS);
			SetEntProp(gNade[client], Prop_Data, "m_CollisionGroup", 1);
			SetEntProp(gNade[client], Prop_Data, "m_usSolidFlags", 16);
			DispatchSpawn(gNade[client]);
			Format(tName, sizeof(tName), "tf2nade%d", gNade[client]);
			DispatchKeyValue(gNade[client], "targetname", tName);
			//SetEntPropString(gNade[client], Prop_Data, "m_iName", "tf2nade");
			TeleportEntity(gNade[client], gHoldingArea, NULL_VECTOR, NULL_VECTOR);
		}
	}
	return gNade[client];
}

ThrowNade(client, bool:Setup=false, HoldType:hold=HoldSpecial, NadeType:type=DefaultNade)
{
	new team = GetClientTeam(client);
	if (team < 2) // dont allow spectators to throw nades!
		return;

	if (Setup)
	{
		// save priming status
		gHolding[client]=hold;
		
		// reset
		gNadeTimer[client] = INVALID_HANDLE;
		//FireTimers(client);

		// setup nade if it doesn't exist
		GetNade(client);

		// check that nade still exists in world
		if (IsValidEdict(gNade[client]))
		{
			GetEntPropString(gNade[client], Prop_Data, "m_iName", tName, sizeof(tName));
			if (strncmp(tName,"tf2nade",7)!=0)
			{
				LogError("tf2nade: player's nade name not found");
				return; 
			}
		}
		else
		{
			LogError("tf2nade: player's nade not found");
			return;
		}
	}

	// get nade type
	new bool:special = (hold >= HoldSpecial);
	if (special && type <= DefaultNade) // setup nade variables based on player class
	{
		type = (gNativeOverride) ? gSpecialType[client] : DefaultNade;
		if (type <= DefaultNade) // setup nade variables based on player class
		{
			new TFClassType:class = TF2_GetPlayerClass(client);
			new Handle:typeVar = cvNadeType[class];
			type = typeVar ? (NadeType:GetConVarInt(typeVar)) : (NadeType:class);
		}
	}

	SetupNade(type, team, special);
	
	if (!Setup)
	{
		// reset priming status
		gHolding[client] = HoldNone;
		
		// get position and angles
		new Float:startpt[3];
		GetClientEyePosition(client, startpt);
		new Float:angle[3];
		new Float:speed[3];
		new Float:playerspeed[3];
		GetClientEyeAngles(client, angle);
		GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
		speed[2]+=0.2;
		speed[0]*=gnSpeed; speed[1]*=gnSpeed; speed[2]*=gnSpeed;
		
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
		AddVectors(speed, playerspeed, speed);
	
		SetEntityModel( gNade[client], gnModel);
		Format(gnSkin, sizeof(gnSkin), "%d", team-2);
		DispatchKeyValue(gNade[client], "skin", gnSkin);
		angle[0] = GetRandomFloat(-180.0, 180.0);
		angle[1] = GetRandomFloat(-180.0, 180.0);
		angle[2] = GetRandomFloat(-180.0, 180.0);
		TeleportEntity(gNade[client], startpt, angle, speed);
		if (strlen(gnParticle)>0)
		{
			AttachParticle(gNade[client], gnParticle, gnDelay);
		}
	
		PrepareSound(SND_THROWNADE);
		EmitSoundToAll(SND_THROWNADE, client);
	}
	
	if (Setup)
	{
		new Handle:pack;
		gNadeTimer[client] = CreateDataTimer(gnDelay, NadeExplode, pack);
		WritePackCell(pack, client);
		WritePackCell(pack, team);
		WritePackCell(pack, _:type);
		WritePackCell(pack, _:special);
	}
}

public Action:NadeExplode(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new team = ReadPackCell(pack);
	new NadeType:type = NadeType:ReadPackCell(pack);
	new bool:special = bool:ReadPackCell(pack);
	
	gNadeTimer[client]=INVALID_HANDLE;

	if (IsValidEdict(gNade[client]))
	{
		GetEntPropString(gNade[client], Prop_Data, "m_iName", tName, sizeof(tName));
		if (strncmp(tName,"tf2nade",7)==0)
		{
			ExplodeNade(client, team, type, special);
		} 
	}
}

public NadeType:GiveFullNades(client)
{
	new NadeType:type;
	new TFClassType:class = TF2_GetPlayerClass(client);
	new Handle:fragVar = cvFragNum[class];
	new Handle:typeVar = cvNadeType[class];

	if (gNativeOverride)
	{
		type = (gSpecialType[client] > DefaultNade) ? gSpecialType[client] : (typeVar ? (NadeType:GetConVarInt(typeVar)) : (NadeType:class));
		gRemaining1[client] = (gAllowed1[client] >= 0) ? gAllowed1[client] : (fragVar ? GetConVarInt(fragVar) : 2);
		gRemaining2[client] = (gAllowed2[client] >= 0) ? gAllowed2[client] : GetNumNades(type);
	}
	else
	{
		type = typeVar ? (NadeType:GetConVarInt(typeVar)) : (NadeType:class);
		gRemaining1[client] = fragVar ? GetConVarInt(fragVar) : 2;
		gRemaining2[client] = GetNumNades(type);
		gSpecialType[client] = type;
	}

	if ((gRemaining1[client] > 0 || gRemaining2[client] > 0) && IsPlayerAlive(client))
	{
		SetupHudMsg(3.0);
		ShowHudText(client, 1, "%t", "GivenNades", gRemaining1[client], gRemaining2[client]);
	}

	return type;
}

ExplodeNade(client, team, NadeType:type, bool:special)
{ 
	if (gHolding[client]>HoldNone)
	{
		ThrowNade(client, false, gHolding[client], DefaultNade);
	}

	new Float:radius;
	if (!special || type >= FragNade)
	{
		// effects
		new Float:center[3];
		GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
		ShowParticle(center, "ExplosionCore_MidAir", 2.0);

		PrepareSound(SND_NADE_FRAG);
		EmitSoundToAll(SND_NADE_FRAG, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
					   SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

		// player damage
		radius = GetConVarFloat(cvFragRadius);
		new damage = GetConVarInt(cvFragDamage);
		new oteam  = (team==3) ? 2 : 3;
		FindPlayersInRange(center, radius, oteam, client, true, gNade[client]);
		for (new j=1;j<=MaxClients;j++)
		{
			if(PlayersInRange[j]>0.0)
			{
				HurtPlayer(j, client, damage, "tf2nade_frag", true, center, 3.0);
			}
		}
		DamageBuildings(client, center, radius, damage, gNade[client], true);
	}
	else
	{
		switch (type)
		{
			case ConcNade:
			{
				radius = GetConVarFloat(cvConcRadius);
				new damage = GetConVarInt(cvConcDamage);
				new Float:center[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "impact_generic_smoke", 2.0);
				PrintToServer("client %d", client);

				PrepareSound(SND_NADE_CONC);
				EmitSoundToAll(SND_NADE_CONC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
				               SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

				new oteam = (team==3) ? 2 : 3;
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client]);
				new Float:play[3];
				new Float:playerspeed[3];
				new Float:distance;
				for (new j=1;j<=MaxClients;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						GetClientAbsOrigin(j, play);
						play[2]+=128.0;
						SubtractVectors(play, center, play);
						distance = GetVectorLength(play);
						if (distance<0.01) { distance = 0.01; }
						ScaleVector(play, 1.0/distance);
						ScaleVector(play, GetConVarFloat(cvConcForce));
						GetEntPropVector(j, Prop_Data, "m_vecVelocity", playerspeed);
						playerspeed[2]=0.0;
						AddVectors(play, playerspeed, play);
						TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, play);
						HurtPlayer(j, client, damage, "tf2nade_conc", false, NULL_VECTOR); 
					}
				}
			}
			case BearTrap:
			{
				new Float:center[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "Explosions_MA_Dustup_2", 2.0);

				#if 0
				SetupNade(BearTrap, team, true);
				gNadeTemp[client] = CreateEntityByName("prop_dynamic_override");
				if (IsValidEntity(gNadeTemp[client]))
				{
					SetEntPropEnt(gNadeTemp[client], Prop_Data, "m_hOwnerEntity", client);
					SetEntityModel(gNadeTemp[client],gnModel);
					SetEntProp(gNadeTemp[client], Prop_Data, "m_CollisionGroup", 1);
					SetEntProp(gNadeTemp[client], Prop_Data, "m_usSolidFlags", 16);
					Format(gnSkin, sizeof(gnSkin), "%d", team-2);
					DispatchKeyValue(gNadeTemp[client], "skin", gnSkin);
					Format(tName, sizeof(tName), "tf2beartrap", gNade[client]);
					DispatchKeyValue(gNadeTemp[client], "targetname", tName);
					DispatchSpawn(gNadeTemp[client]);
					TeleportEntity(gNadeTemp[client], center, NULL_VECTOR, NULL_VECTOR);
					SetVariantString("release");
					AcceptEntityInput(gNadeTemp[client], "SetAnimation");
					//AcceptEntityInput(ent, "SetDefaultAnimation");
				}
				#endif

				PrepareSound(SND_NADE_TRAP);
				EmitSoundToAll(SND_NADE_TRAP, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

				new damage = GetConVarInt(cvTrapDamage);
				new Float:delay=GetConVarFloat(cvTrapDelay);
				radius = GetConVarFloat(cvTrapRadius);

				new oteam = (team==3) ? 2 : 3;
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client]);
				for (new j=1;j<=MaxClients;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						SetEntityMoveType(j,MOVETYPE_NONE); // Freeze client
						CreateTimer(delay, ResetPlayerMotion, j);
						HurtPlayer(j, client, damage, "tf2nade_trap", false, NULL_VECTOR); 
					}
				}
			}
			case NailNade:
			{
				SetupNade(NailNade, team, true);
				new Float:center[3];
				new Float:angles[3] = {0.0,0.0,0.0};
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "Explosions_MA_Dustup_2", 2.0);
				center[2]+=32.0;

				gNadeTemp[client] = CreateEntityByName("prop_dynamic_override");
				if (IsValidEntity(gNadeTemp[client]))
				{
					SetEntPropEnt(gNadeTemp[client], Prop_Data, "m_hOwnerEntity", client);
					SetEntityModel(gNadeTemp[client],gnModel);
					SetEntProp(gNadeTemp[client], Prop_Data, "m_CollisionGroup", 1);
					SetEntProp(gNadeTemp[client], Prop_Data, "m_usSolidFlags", 16);
					Format(gnSkin, sizeof(gnSkin), "%d", team-2);
					DispatchKeyValue(gNadeTemp[client], "skin", gnSkin);
					Format(tName, sizeof(tName), "tf2nailnade%d", gNade[client]);
					DispatchKeyValue(gNadeTemp[client], "targetname", tName);
					DispatchSpawn(gNadeTemp[client]);
					TeleportEntity(gNadeTemp[client], center, angles, NULL_VECTOR);
					SetVariantString("release");
					AcceptEntityInput(gNadeTemp[client], "SetAnimation");
					//AcceptEntityInput(ent, "SetDefaultAnimation");

					PrepareSound(SND_NADE_NAIL);
					EmitSoundToAll(SND_NADE_NAIL, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

					gNadeTimer[client] = CreateTimer(0.2, SoldierNadeThink, client, TIMER_REPEAT);
					gNadeTimer2[client] = CreateTimer(4.5, SoldierNadeFinish, client); 
				}
			}
			case MirvNade:
			{
				radius = GetConVarFloat(cvMirvRadius);
				new damage = GetConVarInt(cvMirvDamage1);
				new Float:center[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);

				PrepareSound(SND_NADE_MIRV1);
				EmitSoundToAll(SND_NADE_MIRV1, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

				new oteam = (team==3) ? 2 : 3;
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client]);
				for (new j=1;j<=MaxClients;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						HurtPlayer(j, client, damage, "tf2nade_mirv", true, center);
					}
				}

				DamageBuildings(client, center, radius, damage, gNade[client], true);
				PrepareModel(MDL_MIRV2, g_Mirv2ModelIndex);

				new Float:spread;
				new Float:vel[3], Float:angle[3], Float:rand;
				Format(gnSkin, sizeof(gnSkin), "%d", team-2);
				new ent[MIRV_PARTS];
				new k;
				for (k=0;k<MIRV_PARTS;k++)
				{
					ent[k] = CreateEntityByName("prop_physics");
					if (IsValidEntity(ent[k]))
					{
						SetEntPropEnt(ent[k], Prop_Data, "m_hOwnerEntity", client);
						SetEntityModel(ent[k],MDL_MIRV2);
						SetEntityMoveType(ent[k], MOVETYPE_VPHYSICS);
						SetEntProp(ent[k], Prop_Data, "m_CollisionGroup", 1);
						SetEntProp(ent[k], Prop_Data, "m_usSolidFlags", 16);
						DispatchKeyValue(ent[k], "skin", gnSkin);
						DispatchSpawn(ent[k]);
						Format(tName, sizeof(tName), "tf2mirv%d", ent[k]);
						DispatchKeyValue(ent[k], "targetname", tName);
						rand = GetRandomFloat(0.0, 314.0);
						spread = GetConVarFloat(cvMirvSpread) * GetRandomFloat(0.2, 1.0);
						vel[0] = spread*Sine(rand);
						vel[1] = spread*Cosine(rand);
						vel[2] = spread;
						GetVectorAngles(vel, angle);
						TeleportEntity(ent[k], center, angle, vel);
					}
				}
				
				
				new Handle:pack;
				gNadeTimer[client] = CreateDataTimer(gnDelay, MirvExplode2, pack);
				WritePackCell(pack, client);
				WritePackCell(pack, team);
				for (k=0;k<MIRV_PARTS;k++)
				{
					WritePackCell(pack, ent[k]);
				}
			}
			case HealthNade:
			{
				radius = GetConVarFloat(cvHealthRadius);
				new Float:beamcenter[3];
				new beamcolor[4];
				if (team==2)
				{
					beamcolor[0]=255; beamcolor[1]=0; beamcolor[2]=0; beamcolor[3]=255;
				}
				else
				{
					beamcolor[0]=0; beamcolor[1]=0; beamcolor[2]=255; beamcolor[3]=255;
				}
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", beamcenter);

				PrepareModel(MDL_RING_MODEL, gRingModel);
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.25,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.50,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.75,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);

				PrepareSound(SND_NADE_HEALTH);
				EmitSoundToAll(SND_NADE_HEALTH, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, beamcenter, NULL_VECTOR, false, 0.0);

				FindPlayersInRange(beamcenter, radius, team, client, true, gNade[client]);
				new health;
				for (new j=1;j<=MaxClients;j++)
				{
					if (PlayersInRange[j]>0.0)
					{
						ShowHealthParticle(j);
						health = GetEntProp(j, Prop_Data, "m_iMaxHealth");
						if (GetClientHealth(j)<health)
						{
							SetEntityHealth(j, health);
						}
					}
				}
			}
			case HeavyNade:
			{
				ExplodeNade(client, team, MirvNade, special);
			}
			case NapalmNade:
			{
				radius = GetConVarFloat(cvNapalmRadius);
				new damage = GetConVarInt(cvNapalmDamage);
				new Float:center[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);

				PrepareModel(MDL_NAPALM_SPRITE, gNapalmSprite);
				TE_SetupExplosion(center, gNapalmSprite, 2.0, 1, 4, RoundToCeil(radius), 0);
				TE_SendToAll();

				PrepareSound(SND_NADE_NAPALM);
				EmitSoundToAll(SND_NADE_NAPALM, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

				new oteam = (team==3) ? 2 : 3;
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client]);
				for (new j=1;j<=MaxClients;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						new bool:hurt;
						new health = GetClientHealth(j);
						if (damage>=health)
						{
							hurt = HurtPlayer(j, client, health-1, "tf2nade_napalm", true, center, 2.0);
						}
						else
						{
							hurt = HurtPlayer(j, client, damage, "tf2nade_napalm", true, center, 2.0);
						}

						if (hurt)
						{
							if (j != client)
								TF2_IgnitePlayer(j, client);
							else
								IgniteEntity(j, 2.5);
						}
					}
				}
				DamageBuildings(client, center, radius, damage, gNade[client], true);
			}
			case HallucNade:
			{
				radius = GetConVarFloat(cvHallucRadius);
				new damage = GetConVarInt(cvHallucDamage);
				new Float:delay = GetConVarFloat(cvHallucDelay);
				new Float:center[3], Float:angles[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_sapperdestroyed", 2.0);

				PrepareSound(SND_NADE_HALLUC);
				EmitSoundToAll(SND_NADE_HALLUC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

				new oteam = (team==3) ? 2 : 3;
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client]);
				new rand1;
				for (new j=1;j<=MaxClients;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						GetClientEyeAngles(j, angles);
						rand1 = GetRandomInt(0, 1);
						if (rand1==0)
						{
							angles[0] = -90.0;
						}
						else
						{
							angles[0] = 90.0;
						}
						angles[2] = GetRandomFloat(-45.0, 45.0);
						TeleportEntity(j, NULL_VECTOR, angles, NULL_VECTOR);	
						ClientCommand(j, "r_screenoverlay effects/tp_eyefx/tp_eyefx");
						CreateTimer(delay, ResetPlayerView, j);
						HurtPlayer(j, client, damage, "tf2nade_halluc", false, NULL_VECTOR); 
					}
				}
			}
			case EmpNade:
			{
				radius = GetConVarFloat(cvEmpRadius);
				new Float:center[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_sapperdestroyed", 2.0);

				PrepareSound(SND_NADE_EMP);
				EmitSoundToAll(SND_NADE_EMP, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

				new oteam = (team==3) ? 2 : 3;
				FindPlayersInRange(center, radius, oteam, client, false, -1);
				new beamcolor[4];
				if (team==2)
				{
					beamcolor[0]=255;beamcolor[1]=0;beamcolor[2]=0;beamcolor[3]=255;
				}
				else
				{
					beamcolor[0]=0;beamcolor[1]=0;beamcolor[2]=255;beamcolor[3]=255;
				}

				PrepareModel(MDL_EMP_SPRITE, gEmpSprite);
				TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite, 1, 1, 0.5, 4.0, 10.0, beamcolor, 100, 0);
				TE_SendToAll();
				TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite, 1, 1, 0.75, 4.0, 10.0, beamcolor, 100, 0);
				TE_SendToAll();
				TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite, 1, 1, 1.0, 4.0, 10.0, beamcolor, 100, 0);
				TE_SendToAll();

				for (new j=1;j<=MaxClients;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						TF2_RemovePlayerDisguise(j);
					}
				}
				radius = radius * radius;
				new Float:orig[3], Float:distance;
				for (new i=MaxClients+1; i<GetMaxEntities(); i++)
				{
					if (IsValidEntity(i))
					{
						GetEdictClassname(i, tName, sizeof(tName));
						if (StrContains(tName, "tf_projectile_")>-1)
						{
							GetEntPropVector(i, Prop_Send, "m_vecOrigin", orig);
							orig[0]-=center[0];
							orig[1]-=center[1];
							orig[2]-=center[2];
							orig[0]*=orig[0];
							orig[1]*=orig[1];
							orig[2]*=orig[2];
							distance = orig[0]+orig[1]+orig[2];
							if (distance<radius)
							{
								RemoveEdict(i);
							}
						}
					}
				}
			}
			case Bomblet:
			{
				// effects
				new Float:center[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);

				PrepareSound(SND_NADE_MIRV2);
				EmitSoundToAll(SND_NADE_MIRV2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
							   SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

				// player damage
				radius = GetConVarFloat(cvBombRadius);
				new damage = GetConVarInt(cvBombDamage);
				new oteam = (team == 3) ? 2 : 3;
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client]);
				for (new j=1;j<=MaxClients;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						HurtPlayer(j, client, damage, "tf2nade_mirv", true, center);
					}
				}
				DamageBuildings(client, center, radius, damage, gNade[client], true);
			}
			case TargetingDrone:
			{
				SetupNade(TargetingDrone, team, true);
				new Float:center[3];
				new Float:angles[3] = {0.0,0.0,0.0};
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "Explosions_MA_Dustup_2", 2.0);
				center[2]+=32.0;

				gNadeTemp[client] = CreateEntityByName("prop_dynamic_override");
				if (IsValidEntity(gNadeTemp[client]))
				{
					SetEntPropEnt(gNadeTemp[client], Prop_Data, "m_hOwnerEntity", client);
					SetEntityModel(gNadeTemp[client],gnModel);
					SetEntProp(gNadeTemp[client], Prop_Data, "m_CollisionGroup", 1);
					SetEntProp(gNadeTemp[client], Prop_Data, "m_usSolidFlags", 16);
					Format(gnSkin, sizeof(gnSkin), "%d", team-2);
					DispatchKeyValue(gNadeTemp[client], "skin", gnSkin);
					Format(tName, sizeof(tName), "tf2drone%d", gNade[client]);
					DispatchKeyValue(gNadeTemp[client], "targetname", tName);
					DispatchSpawn(gNadeTemp[client]);
					TeleportEntity(gNadeTemp[client], center, angles, NULL_VECTOR);
					SetVariantString("release");
					AcceptEntityInput(gNadeTemp[client], "SetAnimation");
					//AcceptEntityInput(ent, "SetDefaultAnimation");

					PrepareSound(SND_NADE_NAIL);
					EmitSoundToAll(SND_NADE_NAIL, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

					gNadeTimer[client] = CreateTimer(0.2, DroneThink, client, TIMER_REPEAT);
					gNadeTimer2[client] = CreateTimer(20.0, DroneFinish, client); 
				}
			}
		}
	}
	TeleportEntity(gNade[client], gHoldingArea, NULL_VECTOR, NULL_VECTOR);	
}

SetupNade(NadeType:type, team, bool:special)
{
	// setup frag nade if not special
	if (!special || type >= FragNade)
	{
		PrepareModel(MDL_FRAG, g_FragModelIndex);
		strcopy(gnModel, sizeof(gnModel), MDL_FRAG);
		gnSpeed = 2000.0;
		gnDelay = 2.0;
		gnParticle[0]='\0';
		return;
	}
	else
	{
		// setup special nade if not frag
		switch (type)
		{
			case ConcNade:
			{
				PrepareModel(MDL_CONC, g_ConcModelIndex);
				strcopy(gnModel, sizeof(gnModel), MDL_CONC);
				gnSpeed = 1500.0;
				gnDelay = 2.0;
				strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
			}
			case BearTrap:
			{
				//PrepareModel(MDL_TRAP, g_TrapModelIndex);
				//strcopy(gnModel, sizeof(gnModel), MDL_TRAP);
				PrepareModel(MDL_HALLUC, g_HallucModelIndex);
				strcopy(gnModel, sizeof(gnModel), MDL_HALLUC);
				gnSpeed = 500.0;
				gnDelay = 2.0;
				gnParticle[0]='\0';
			}
			case NailNade:
			{
				PrepareModel(MDL_NAIL, g_NailModelIndex);
				strcopy(gnModel, sizeof(gnModel), MDL_NAIL);
				gnSpeed = 1000.0;
				gnDelay = 2.0;
				gnParticle[0]='\0';
			}
			case MirvNade:
			{
				SetupNade(EmpNade, team, special);
				PrepareModel(MDL_MIRV1, g_Mirv1ModelIndex);
				strcopy(gnModel, sizeof(gnModel), MDL_MIRV1);
				gnSpeed = 1250.0;
				gnDelay = 3.0;
				gnParticle[0]='\0';
			}
			case HealthNade:
			{
				PrepareModel(MDL_HEALTH, g_HealthModelIndex);
				strcopy(gnModel, sizeof(gnModel), MDL_HEALTH);
				gnSpeed = 2000.0;
				gnDelay = GetConVarFloat(cvHealthDelay);
				if (team==2)
				{
					strcopy(gnParticle, sizeof(gnParticle), "player_recent_teleport_red");
				}
				else
				{
					strcopy(gnParticle, sizeof(gnParticle), "player_recent_teleport_blue");
				}
			}
			case HeavyNade:
			{
				PrepareModel(MDL_MIRV1, g_Mirv1ModelIndex);
				strcopy(gnModel, sizeof(gnModel), MDL_MIRV1);
				gnSpeed = 1250.0;
				gnDelay = 3.0;
				gnParticle[0]='\0';
			}
			case NapalmNade:
			{
				PrepareModel(MDL_NAPALM, g_NapalmModelIndex);
				strcopy(gnModel, sizeof(gnModel), MDL_NAPALM);
				gnSpeed = 2000.0;
				gnDelay = 2.0;
				gnParticle[0]='\0';
			}
			case HallucNade:
			{
				PrepareModel(MDL_HALLUC, g_HallucModelIndex);
				strcopy(gnModel, sizeof(gnModel), MDL_HALLUC);
				gnSpeed = 1500.0;
				gnDelay = 2.0;
				strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
			}
			case EmpNade:
			{
				PrepareModel(MDL_EMP, g_EmpModelIndex);
				strcopy(gnModel, sizeof(gnModel), MDL_EMP);
				gnSpeed = 1500.0;
				gnDelay = 2.0;
				if (team==2)
				{
					strcopy(gnParticle, sizeof(gnParticle), "critgun_weaponmodel_red");
				}
				else
				{
					strcopy(gnParticle, sizeof(gnParticle), "critgun_weaponmodel_blu");
				}
			}
			case Bomblet:
			{
				PrepareModel(MDL_MIRV2, g_Mirv2ModelIndex);
				strcopy(gnModel, sizeof(gnModel), MDL_MIRV2);
				gnSpeed = 500.0;
				gnDelay = 2.0;
				gnParticle[0]='\0';
			}
			case TargetingDrone:
			{
				PrepareModel(MDL_NAIL, g_NailModelIndex);
				strcopy(gnModel, sizeof(gnModel), MDL_NAIL);
				gnSpeed = 1000.0;
				gnDelay = 2.0;
				gnParticle[0]='\0';
			}
		}
	}
}

GetNumNades(NadeType:type)
{
	switch (type)
	{
		case ConcNade:
		{
			return GetConVarInt(cvConcNum);
		}
		case BearTrap:
		{
			return GetConVarInt(cvTrapNum);
		}
		case NailNade:
		{
			return GetConVarInt(cvNailNum);
		}
		case MirvNade:
		{
			return GetConVarInt(cvMirvNum);
		}
		case HealthNade:
		{
			return GetConVarInt(cvHealthNum);
		}
		case HeavyNade:
		{
			return GetConVarInt(cvMirvNum);
		}
		case NapalmNade:
		{
			return GetConVarInt(cvNapalmNum);
		}
		case HallucNade:
		{
			return GetConVarInt(cvHallucNum);
		}
		case EmpNade:
		{
			return GetConVarInt(cvEmpNum);
		}
		case Bomblet:
		{
			return GetConVarInt(cvBombNum);
		}
		default:
		{
			return 0;
		}
	}
	return 0;
}

FireTimers(client)
{
	// nades
	new Handle:timer = gNadeTimer[client];
	if (timer != INVALID_HANDLE)
	{
		gTriggerTimer[client] = true;
		TriggerTimer(timer);
		gTriggerTimer[client] = false;
	}

	new Handle:timer2 = gNadeTimer2[client];
	if (timer2 != INVALID_HANDLE)
	{
		gTriggerTimer[client] = true;
		TriggerTimer(timer2);
		gTriggerTimer[client] = false;
	}
}

public Action:SoldierNadeThink(Handle:timer, any:client)
{
	new ent = gNadeTemp[client];
	if (ent > 0 && IsValidEntity(ent))
	{
		decl String:edictname[128];
		GetEdictClassname(ent, edictname, sizeof(edictname));
		if (StrEqual(edictname, "prop_dynamic") || StrEqual(edictname, "prop_physics"))
		{
			if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
			{
				GetEntPropString(ent, Prop_Data, "m_ModelName", edictname, sizeof(edictname));
				if (StrEqual(edictname, MDL_NAIL))
				{
					// effects
					new Float:center[3];
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", center);
					new rand = GetRandomInt(1, 3);
					switch (rand)
					{
						case 1:  Format(tName, sizeof(tName), "%s", SND_NADE_NAIL_SHOOT1);
						case 2:  Format(tName, sizeof(tName), "%s", SND_NADE_NAIL_SHOOT2);
						default: Format(tName, sizeof(tName), "%s", SND_NADE_NAIL_SHOOT3);
					}

					PrepareSound(tName);
					EmitSoundToAll(tName, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
								   SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

					new Float:dir[3];
					dir[0] = GetRandomFloat(-1.0, 1.0);
					dir[1] = GetRandomFloat(-1.0, 1.0);
					dir[2] = GetRandomFloat(-1.0, 1.0);
					TE_SetupMetalSparks(center, dir);
					TE_SendToAll();

					// player damage
					new damage = GetConVarInt(cvNailDamageNail);
					new oteam = (GetClientTeam(client)==3) ? 2 : 3;
					FindPlayersInRange(center, GetConVarFloat(cvNailRadius), oteam, client, true, ent);
					for (new j=1;j<=MaxClients;j++)
					{
						if (PlayersInRange[j]>0.0)
						{
							HurtPlayer(j, client, damage, "tf2nade_nail", false, center);
						}
					}

					return Plugin_Continue;
				}
			}
		}
	}

	gNadeTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:SoldierNadeFinish(Handle:timer, any:client)
{
	gNadeTimer2[client]=INVALID_HANDLE;

	if (gNadeTimer[client]!=INVALID_HANDLE)
	{
		KillTimer(gNadeTimer[client]);
		gNadeTimer[client] = INVALID_HANDLE;
	}

	new ent = gNadeTemp[client];
	StopSound(ent, SNDCHAN_WEAPON, SND_NADE_NAIL);

	if (ent > 0 && IsValidEntity(ent))
	{
		decl String:edictname[128];
		GetEdictClassname(ent, edictname, sizeof(edictname));
		if (StrEqual(edictname, "prop_dynamic") ||
		    StrEqual(edictname, "prop_physics"))
		{
			if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
			{
				GetEntPropString(ent, Prop_Data, "m_ModelName", edictname, sizeof(edictname));
				if (strncmp(edictname, "models/weapons/nades/duke1", 26) == 0)
				{
					GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
					if (strncmp(tName,"tf2nailnade",11)==0)
					{
						// effects
						new Float:center[3];
						new Float:radius = GetConVarFloat(cvNailRadius);
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", center);
						ShowParticle(center, "ExplosionCore_MidAir", 2.0);

						PrepareSound(SND_NADE_NAIL_EXPLODE);
						EmitSoundToAll(SND_NADE_NAIL_EXPLODE, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC,
									   SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

						// player damage
						new damage = GetConVarInt(cvNailDamageExplode);
						new oteam = (GetClientTeam(client) == 3) ? 2 : 3;
						FindPlayersInRange(center, radius, oteam, client, true, ent);
						for (new j=1;j<=MaxClients;j++)
						{
							if (PlayersInRange[j]>0.0)
							{
								HurtPlayer(j, client, damage, "tf2nade_nail", true, center);
							}
						}

						DamageBuildings(client, center, radius, damage, ent, true);
						RemoveEdict(ent);
					}
				}
			}
		}
	}

	gNadeTemp[client] = 0;
	return Plugin_Stop;
}

public Action:MirvExplode2(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new team = ReadPackCell(pack);

	new ent[MIRV_PARTS];
	for (new k=0;k<MIRV_PARTS;k++)
	{
		ent[k] = ReadPackCell(pack);
	}

	gNadeTimer[client] = INVALID_HANDLE;

	new Float:radius = GetConVarFloat(cvMirvRadius);
	new Float:center[3];

	for (new k=0;k<MIRV_PARTS;k++)
	{
		if (IsValidEntity(ent[k]))
		{
			GetEntPropString(ent[k], Prop_Data, "m_iName", tName, sizeof(tName));
			if (strncmp(tName,"tf2mirv",7)==0)
			{
				GetEntPropVector(ent[k], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);

				PrepareSound(SND_NADE_MIRV2);
				EmitSoundToAll(SND_NADE_MIRV2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
							   SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, Float:k * 0.25);

				new damage = GetConVarInt(cvMirvDamage2);
				new oteam = (team == 3) ? 2 : 3;
				FindPlayersInRange(center, radius, oteam, client, true, ent[k]);
				for (new j=1;j<=MaxClients;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						HurtPlayer(j, client, damage, "tf2nade_mirv", true, center);
					}
				}
				DamageBuildings(client, center, radius, damage, ent[k], true);
				RemoveEdict(ent[k]);
			}
		}
	}

	return Plugin_Stop;
}

public Action:DroneThink(Handle:timer, any:client)
{
	new ent = gNadeTemp[client];
	if (ent > 0 && IsValidEntity(ent))
	{
		decl String:edictname[128];
		GetEdictClassname(ent, edictname, sizeof(edictname));
		if (StrEqual(edictname, "prop_dynamic") || StrEqual(edictname, "prop_physics"))
		{
			if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
			{
				GetEntPropString(ent, Prop_Data, "m_ModelName", edictname, sizeof(edictname));
				if (StrEqual(edictname, MDL_NAIL))
				{
					new Float:range=2000.0;
					new Float:center[3];
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", center);

					PrepareModel(MDL_BEAM_SPRITE, gBeamSprite);

					new team = GetClientTeam(client);
					new targetColor[4] = {0, 0, 0, 255};
					if (team==2)
						targetColor[0] = 255;
					else
						targetColor[2] = 255;

					// Find players to target
					new Float:indexLoc[3];
					for (new index=1;index<=MaxClients;index++)
					{
						if (client != index && IsClientInGame(index) &&
							IsPlayerAlive(index) && GetClientTeam(index) != team)
						{
							GetClientAbsOrigin(index, indexLoc);
							if (IsPointInRange(center,indexLoc,range) &&
								TraceTargetIndex(ent, index, center, indexLoc))
							{
								gTargeted[index] = client;
								TE_SetupBeamLaser(ent, index, gBeamSprite, gBeamSprite,
												  0, 1, 10.0, 10.0,10.0,2,50.0,targetColor,255);
								TE_SendToAll();
							}
							else if (gTargeted[index] == client)
								gTargeted[index] = 0;
						}
						else if (gTargeted[index] == client)
							gTargeted[index] = 0;
					}
					return Plugin_Continue;
				}
			}
		}
	}

	// Reset the targeted flags
	for (new index=1;index<=MaxClients;index++)
	{
		if (gTargeted[index] == client)
			gTargeted[index] = 0;
	}

	gNadeTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:DroneFinish(Handle:timer, any:client)
{
	gNadeTimer2[client]=INVALID_HANDLE;

	if (gNadeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(gNadeTimer[client]);
		gNadeTimer[client] = INVALID_HANDLE;
	}

	new ent = gNadeTemp[client];
	StopSound(ent, SNDCHAN_WEAPON, SND_NADE_NAIL);

	if (ent > 0 && IsValidEntity(ent))
	{
		decl String:edictname[128];
		GetEdictClassname(ent, edictname, sizeof(edictname));
		if (StrEqual(edictname, "prop_dynamic") ||
		    StrEqual(edictname, "prop_physics"))
		{
			if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
			{
				GetEntPropString(ent, Prop_Data, "m_ModelName", edictname, sizeof(edictname));
				if (strncmp(edictname, "models/weapons/nades/duke1", 26) == 0)
				{
					GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
					if (strncmp(tName,"tf2drone",8)==0)
					{
						// effects
						new Float:center[3];
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", center);
						ShowParticle(center, "ExplosionCore_MidAir", 2.0);

						PrepareSound(SND_NADE_NAIL_EXPLODE);
						EmitSoundToAll(SND_NADE_NAIL_EXPLODE, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC,
									   SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

						RemoveEdict(ent);
					}
				}
			}
		}
	}

	// Reset the targeted flags
	for (new index=1;index<=MaxClients;index++)
	{
		if (gTargeted[index] == client)
			gTargeted[index] = 0;
	}

	gNadeTemp[client] = 0;
	return Plugin_Stop;
}

public Action:ResetPlayerView(Handle:timer, any:client)
{
	new Float:angles[3];
	GetClientEyeAngles(client, angles);
	angles[2] = 0.0;
	TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
	ClientCommand(client, "r_screenoverlay none");
}

public Action:ResetPlayerMotion(Handle:timer, any:client)
{
	SetEntityMoveType(client,MOVETYPE_WALK); // Unfreeze client
}

PrecacheNadeModels()
{
	PrecacheModel("models/error.mdl"); // In case the models are missing!
	
	g_FragModelIndex = 0; // PrecacheModel(MDL_FRAG, true);
	g_ConcModelIndex = 0; // PrecacheModel(MDL_CONC, true);
	g_NailModelIndex = 0; // PrecacheModel(MDL_NAIL, true);
	g_Mirv1ModelIndex = 0; // PrecacheModel(MDL_MIRV1, true);
	g_Mirv2ModelIndex = 0; // PrecacheModel(MDL_MIRV2, true);
	g_HealthModelIndex = 0; // PrecacheModel(MDL_HEALTH, true);
	g_NapalmModelIndex = 0; // PrecacheModel(MDL_NAPALM, true);
	g_HallucModelIndex = 0; // PrecacheModel(MDL_HALLUC, true);
	g_TrapModelIndex = 0; // PrecacheModel(MDL_EMP, true);
	g_EmpModelIndex = 0; // PrecacheModel(MDL_EMP, true);

	AddFolderToDownloadTable("models/weapons/nades/duke1");
	AddFolderToDownloadTable("materials/models/weapons/nades/duke1");
}


// *************************************************
// helper funcs
// *************************************************

// show a health sign above client's head
ShowHealthParticle(client)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		if (GetClientTeam(client)==2)
		{
			DispatchKeyValue(particle, "effect_name", "healthgained_red");
		}
		else
		{
			DispatchKeyValue(particle, "effect_name", "healthgained_blu");
		}
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetVariantString("head");
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(2.0, DeleteParticles, particle);
	}
	else
	{
		LogError("ShowHealthParticle: could not create info_particle_system");
	}
}
public Action:DeleteParticles(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		new String:classname[STRLENGTH];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}
}
public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
	else
	{
		LogError("ShowParticle: could not create info_particle_system");
	}	
}
AttachParticle(ent, String:particleType[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
	else
	{
		LogError("AttachParticle: could not create info_particle_system");
	}
}

// players in range setup  (self = 0 if doesn't affect self)
FindPlayersInRange(Float:location[3], Float:radius, team, self, bool:trace, donthit)
{
	new Float:rsquare = radius*radius;
	new Float:orig[3];
	new Float:distance;
	new Handle:tr;
	new j;
	for (j=1;j<=MaxClients;j++)
	{
		PlayersInRange[j] = 0.0;
		if (IsClientInGame(j))
		{
			if (IsPlayerAlive(j))
			{
				if ( (team>1 && GetClientTeam(j)==team) || team==0 || j==self)
				{
					GetClientAbsOrigin(j, orig);
					orig[0]-=location[0];
					orig[1]-=location[1];
					orig[2]-=location[2];
					orig[0]*=orig[0];
					orig[1]*=orig[1];
					orig[2]*=orig[2];
					distance = orig[0]+orig[1]+orig[2];
					if (distance < rsquare)
					{
						if (trace)
						{
							GetClientEyePosition(j, orig);
							tr = TR_TraceRayFilterEx(location, orig, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfOrPlayers, donthit);
							if (tr!=INVALID_HANDLE)
							{
								if (TR_GetFraction(tr)>0.98)
								{
									PlayersInRange[j] = SquareRoot(distance)/radius;
								}
								CloseHandle(tr);
							}
							
						}
						else
						{
							PlayersInRange[j] = SquareRoot(distance)/radius;
						}
					}
				}
			}
		}
	}
}

SetupHudMsg(Float:time)
{
	SetHudTextParams(-1.0, 0.8, time, 255, 255, 255, 64, 1, 0.5, 0.0, 0.5);
}


KillPlayer(client, attacker, String:weapon[256])
{
	if (gKilledBy[client] == 0)
	{
		gKilledBy[client] = GetClientUserId(attacker);
		gKillTime[client] = GetEngineTime();
		strcopy(gKillWeapon[client], STRLENGTH, weapon);

		/*
		if (explode)
			FakeClientCommand(client, "explode");
		else
			ForcePlayerSuicide(client);
		*/

		new ent = CreateEntityByName("env_explosion");
		if (IsValidEntity(ent))
		{
			DispatchKeyValue(ent, "iMagnitude", "1000");
			DispatchKeyValue(ent, "iRadiusOverride", "2");
			SetEntPropEnt(ent, Prop_Data, "m_hInflictor", attacker);
			SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", attacker);
			DispatchKeyValue(ent, "spawnflags", "3964");
			DispatchSpawn(ent);
			new Float:pos[3];
			GetClientAbsOrigin(client, pos);
			TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(ent, "explode", client, client);
			CreateTimer(0.2, RemoveExplosion, ent);
		}
	}
}

public Action:RemoveExplosion(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		new String:edictname[128];
		GetEdictClassname(ent, edictname, 128);
		if(StrEqual(edictname, "env_explosion"))
		{
			RemoveEdict(ent);
		}
	}
}

bool:HurtPlayer(client, attacker, damage, String:weapon[256], bool:explosion, Float:pos[3], Float:knockbackmult = 4.0)
{
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond & 32)
	{
		return false;
	}
	
	new health = GetClientHealth(client);
	
	if (explosion)
	{
		
		new Float:play[3], Float:playerspeed[3], Float:distance;
		GetClientAbsOrigin(client, play);
		SubtractVectors(play, pos, play);
		distance = GetVectorLength(play);
		if (distance<0.01) { distance = 0.01; }
		ScaleVector(play, 1.0/distance);
		ScaleVector(play, damage * knockbackmult);
		play[2] = damage * knockbackmult;
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
		playerspeed[2]=0.0;
		AddVectors(play, playerspeed, play);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, play);
	}
	
	if (health>damage)
	{
		PrepareSound(sndPain);
		EmitSoundToAll(sndPain, client);
		SetEntityHealth(client, health-damage);
		return true;
	}
	else
	{
		KillPlayer(client, attacker, weapon);
		return false;
	}
}

DamageBuildings(attacker, Float:start[3], Float:radius, damage, nade, bool:trace)
{
	new Float:pos[3];
	pos[0]=start[0];pos[1]=start[1];pos[2]=start[2]+16.0;
	new count = GetMaxEntities();
	new Float:obj[3], Float:objcalc[3];
	new Float:rad = radius * radius;
	new Float:distance;
	new Handle:tr;
	new team = GetClientTeam(attacker);
	new objteam;
	for (new i=MaxClients+1; i<count; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, tName, sizeof(tName));
			if (StrEqual(tName, "obj_sentrygun")
				|| StrEqual(tName, "obj_dispenser") 
				|| StrEqual(tName, "obj_teleporter_entrance")
				|| StrEqual(tName, "obj_teleporter_exit") )
			{
				objteam=GetEntProp(i, Prop_Data, "m_iTeamNum");
				if (team!=objteam)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", obj);
					objcalc[0]=obj[0]-pos[0];
					objcalc[1]=obj[1]-pos[1];
					objcalc[2]=obj[2]-pos[2];
					objcalc[0]*=objcalc[0];
					objcalc[1]*=objcalc[1];
					objcalc[2]*=objcalc[2];
					distance = objcalc[0]+objcalc[1]+objcalc[2];
					if (distance<rad)
					{
						if (trace)
						{
							obj[2]+=16.0;
							tr = TR_TraceRayFilterEx(pos, obj, MASK_SOLID, RayType_EndPoint, TraceRayDontHitObjOrPlayers, nade);
							if (tr!=INVALID_HANDLE)
							{
								if (TR_GetFraction(tr)>0.98 || TR_GetEntityIndex(tr)==i)
								{
									SetVariantInt(damage);
									AcceptEntityInput(i, "RemoveHealth", attacker, attacker);
								}
								CloseHandle(tr);
							}
							
						}
						else
						{
							SetVariantInt(damage);
							AcceptEntityInput(i, "RemoveHealth", attacker, attacker);
						}
					}
				}
			}
		}
	}
}

/*
AddScore(client, val)
{
LogError("Adding %d to client(%d) score was not successful.", val, client);	
}
*/

AddFolderToDownloadTable(const String:Directory[], bool:recursive=false) 
{
	decl String:FileName[64], String:Path[512];
	new Handle:Dir = OpenDirectory(Directory), FileType:Type;
	while(ReadDirEntry(Dir, FileName, sizeof(FileName), Type))     
	{
		if(Type == FileType_Directory && recursive)         
		{           
			FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
			AddFolderToDownloadTable(FileName);
			continue;
			
		}                 
		if (Type != FileType_File) continue;
		FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
		AddFileToDownloadsTable(Path);
	}
	return;	
}


public bool:TraceRayDontHitSelfOrPlayers(entity, mask, any:startent)
{
	if(entity == startent)
	{
		return false; // 
	}
	
	if (entity <= MaxClients)
	{
		return false;
	}
	
	return true; 
}

public bool:TraceRayDontHitObjOrPlayers(entity, mask, any:startent)
{
	if(entity == startent)
	{
		return false; // 
	}
	
	if (entity <= MaxClients)
	{
		return false;
	}
	
	if (IsValidEntity(entity))
	{
		GetEdictClassname(entity, tName, sizeof(tName));
		if (StrEqual(tName, "obj_sentrygun")
			|| StrEqual(tName, "obj_dispenser") 
			|| StrEqual(tName, "obj_teleporter_entrance")
			|| StrEqual(tName, "obj_teleporter_exit")
			|| StrEqual(tName, "tf_ammo_pack") )
		{
			return false;
		}
	}
	
	return true; 
}

TagsCheck(const String:tag[])
{
	new Handle:hTags = FindConVar("sv_tags");
	
	decl String:tags[255];
	GetConVarString(hTags, tags, sizeof(tags));

	if (!(StrContains(tags, tag, false)>-1))
	{
		decl String:newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		SetConVarString(hTags, newTags);
		GetConVarString(hTags, tags, sizeof(tags));
	}

	CloseHandle(hTags);
} 

public Action:SayCommand(client,args)
{
	decl String:command[128];
	GetCmdArg(1,command,sizeof(command));

	decl String:arg[2][64];
	ExplodeString(command, " ", arg, 2, 64);

	if (CommandCheck(arg[0],"nadeinfo") ||
		CommandCheck(arg[0],"nade"))
	{
		Command_NadeInfo(client, 0);
		return Plugin_Handled;
	}
	else if (CommandCheck(arg[0],"nadestop") ||
			 CommandCheck(arg[0],"stop"))
	{
		Command_Stop(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool:CommandCheck(const String:compare[], const String:command[])
{
	if(!strcmp(compare,command,false))
		return true;
	else
	{
		new String:firstChar[] = " ";
		firstChar{0} = compare{0};
		if (StrContains("!/\\",firstChar) >= 0)
			return !strcmp(compare[1],command,false);
		else
			return false;
	}
}

stock SetupPreloadTrie()
{
    if (g_precacheTrie == INVALID_HANDLE)
        g_precacheTrie = CreateTrie();
    else
        ClearTrie(g_precacheTrie);
}

stock PrepareSound(const String:sound[], bool:preload=false)
{
    //if (!IsSoundPrecached(sound))
    new bool:value;
    if (!GetTrieValue(g_precacheTrie, sound, value))
    {
        PrecacheSound(sound,preload);
        SetTrieValue(g_precacheTrie, sound, true);
    }
}

stock PrepareModel(const String:model[], &index, bool:preload=false)
{
    if (index <= 0)
        index = PrecacheModel(model,preload);

    return index;
}

// *************************************************
// native interface
// *************************************************

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
	// Register Natives
	CreateNative("ControlNades",Native_ControlNades);
	CreateNative("GiveNades",Native_GiveNades);
	CreateNative("TakeNades",Native_TakeNades);
	CreateNative("AddFragNades",Native_AddFragNades);
	CreateNative("SubFragNades",Native_SubFragNades);
	CreateNative("HasFragNades",Native_HasFragNades);
	CreateNative("ThrowFragNade",Native_ThrowFragNade);
	CreateNative("AddSpecialNades",Native_AddSpecialNades);
	CreateNative("SubSpecialNades",Native_SubSpecialNades);
	CreateNative("HasSpecialNades",Native_HasSpecialNades);
	CreateNative("ThrowSpecialNade",Native_ThrowSpecialNade);
	CreateNative("DamageBuildings",Native_DamageBuildings);
	CreateNative("ThrowNade",Native_ThrowNade);
	CreateNative("IsTargeted",Native_IsTargeted);

	RegPluginLibrary("ztf2nades");
	return true;
}

public Native_ControlNades(Handle:plugin,numParams)
{
	gNativeOverride |= (numParams >= 1) ? GetNativeCell(1) : true;
	gTargetOverride |= (numParams >= 2) ? GetNativeCell(2) : false;
}

public Native_GiveNades(Handle:plugin,numParams)
{
	if (numParams >= 1)
	{
		new client = GetNativeCell(1);
		new NadeType:old_type = gSpecialType[client];
		gRemaining1[client] = (numParams >= 2) ? GetNativeCell(2) : -1;
		gAllowed1[client] = (numParams >= 3) ? GetNativeCell(3) : -1;
		gRemaining2[client] = (numParams >= 4) ? GetNativeCell(4) : -1;
		gAllowed2[client] = (numParams >= 5) ? GetNativeCell(5) : -1;
		gCanRestock[client] = (numParams >= 6) ? (bool:GetNativeCell(6)) : false;
		gSpecialType[client] = (numParams >= 7) ? (NadeType:GetNativeCell(7)) : DefaultNade;

		if (IsPlayerAlive(client))
		{
			if (gSpecialType[client] != old_type)
			{
				// get nade type
				new NadeType:type = gSpecialType[client];
				if (type <= DefaultNade) // setup nade variables based on player class
				{
					new TFClassType:class = TF2_GetPlayerClass(client);
					new Handle:typeVar = cvNadeType[class];
					type = typeVar ? (NadeType:GetConVarInt(typeVar)) : (NadeType:class);
				}

				SetupNade(type, GetClientTeam(client), true);
			}

			if ((gRemaining1[client] > 0 || gRemaining2[client] > 0) && IsPlayerAlive(client))
			{
				SetupHudMsg(3.0);
				ShowHudText(client, 1, "%t", "GivenNades", gRemaining1[client], gRemaining2[client]);
			}
		}
	}
}

public Native_TakeNades(Handle:plugin,numParams)
{
	if (numParams >= 1)
	{
		new client = GetNativeCell(1);
		gAllowed1[client] = 0;
		gAllowed2[client] = 0;
		gCanRestock[client] = false;
		gSpecialType[client] = DefaultNade;
	}
}

public Native_AddFragNades(Handle:plugin,numParams)
{
	if (numParams >= 1)
	{
		new client = GetNativeCell(1);
		new num = (numParams >= 2) ? GetNativeCell(2) : 1;
		gRemaining1[client] += num;
	}
}

public Native_SubFragNades(Handle:plugin,numParams)
{
	if (numParams >= 1)
	{
		new client = GetNativeCell(1);
		new num = (numParams >= 2) ? GetNativeCell(2) : 1;
		gRemaining1[client] -= num;
		if (gRemaining1[client] < 0)
			gRemaining1[client] = 0;
	}
}

public Native_HasFragNades(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        return ((numParams >= 2) && GetNativeCell(2)) ? gAllowed1[client] : gRemaining1[client];
    }
    else
        return -1;
}

public Native_AddSpecialNades(Handle:plugin,numParams)
{
	if (numParams >= 1)
	{
		new client = GetNativeCell(1);
		new num = (numParams >= 2) ? GetNativeCell(2) : 1;
		gRemaining2[client] += num;
	}
}

public Native_SubSpecialNades(Handle:plugin,numParams)
{
	if (numParams >= 1)
	{
		new client = GetNativeCell(1);
		new num = (numParams >= 2) ? GetNativeCell(2) : 1;
		gRemaining2[client] -= num;
		if (gRemaining2[client] < 0)
			gRemaining2[client] = 0;
	}
}

public Native_HasSpecialNades(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        return ((numParams >= 2) && GetNativeCell(2)) ? gAllowed2[client] : gRemaining2[client];
    }
    else
        return -1;
}

public Native_ThrowFragNade(Handle:plugin,numParams)
{
	if (numParams >= 1)
	{
		new client = GetNativeCell(1);
		if (GetNativeCell(2))
			Command_Nade1(client, 0);
		else
			Command_UnNade1(client, 0);
	}
}

public Native_ThrowSpecialNade(Handle:plugin,numParams)
{
	if (numParams >= 1)
	{
		new client = GetNativeCell(1);
		if (GetNativeCell(2))
			Command_Nade2(client, 0);
		else
			Command_UnNade2(client, 0);
	}
}

public Native_DamageBuildings(Handle:plugin,numParams)
{
	if (numParams >= 6)
	{
		new Float:start[3];
		new attacker = GetNativeCell(1);
		new Float:radius = Float:GetNativeCell(3);
		new damage = GetNativeCell(4);
		new ent = GetNativeCell(5);
		new bool:trace = bool:GetNativeCell(6);
		GetNativeArray(2, start, 3); 
		DamageBuildings(attacker, start, radius, damage, ent, trace);
	}
}

public Native_ThrowNade(Handle:plugin,numParams)
{
	if (numParams >= 1)
	{
		new client = GetNativeCell(1);
		new NadeType:type = NadeType:GetNativeCell(3);
		if (GetNativeCell(2)) // setup - button pressed
		{
			if (gHolding[client]>HoldNone)
				return;
			else if (!IsClientInGame(client) || !IsPlayerAlive(client))
				return;
			else
			{
				// not while cloaked or taunting
				new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
				if (cond&16 || cond&128)
					return;
				else
				{
					SetupHudMsg(3.0);
					if (!gCanRun)
						ShowHudText(client, 1, "%t", "WaitingPeriod");
					else
					{
						if (gTriggerTimer[client])
						{
							gTriggerTimer[client] = false;
							gNadeTimer[client]=INVALID_HANDLE;
						}

						if (gNadeTimer[client]==INVALID_HANDLE)
						{
							if (cond&8)
								TF2_RemovePlayerDisguise(client);

							ThrowNade(client, true, HoldOther, type);
						}
						else
							ShowHudText(client, 1, "%t", "OnlyOneNade");
					}
				}
			}
		}
		else // if (!setup) // button released
		{
			if (gHolding[client] != HoldOther)
				return;
			else if (gNadeTimer[client]!=INVALID_HANDLE)
				ThrowNade(client, false, HoldOther, type);
		}
	}
}

public Native_IsTargeted(Handle:plugin,numParams)
{
    if (numParams >= 1)
        return gTargeted[GetNativeCell(1)];
    else
        return false;
}

//#include "range"
/**
 * Description: Range and Distance functions and variables
 */
 
stock Float:DistanceBetween(const Float:startvec[3],const Float:endvec[3])
{
	new Float:distance = GetVectorDistance(startvec,endvec);
	if (distance < 0)
		distance *= -1;

	return distance;                                  
}

stock Float:TargetRange(client,index)
{
	new Float:start[3];
	new Float:end[3];
	GetClientAbsOrigin(client,start);
	GetClientAbsOrigin(index,end);
	return DistanceBetween(start,end);
}

stock bool:IsInRange(client,index,Float:maxdistance)
{
	return (TargetRange(client,index)<maxdistance);
}

stock bool:IsPointInRange(const Float:start[3], const Float:end[3],Float:maxdistance)
{
	return (DistanceBetween(start,end)<maxdistance);
}

stock PowerOfRange(Float:location[3],Float:radius,Float:check_location[3],maxhp,
				   Float:factor=0.20,bool:limit=true)
{
	if (radius <= 0.0)
		return maxhp;
	else
	{
		new Float:distance=DistanceBetween(location,check_location);
		if (limit && distance > radius)
			return 0;
		else
		{
			new Float:healthtakeaway=1-FloatDiv(distance,radius)+factor;
			return (healthtakeaway > 0.0) ? RoundFloat(float(maxhp)*healthtakeaway) : 0;
		}
	}
}


//#include "raytrace"
/**
 * Description: Ray Trace functions and variables
 */
 
stock bool:TraceTarget(client, target, Float:clientLoc[3], Float:targetLoc[3])
{
	TR_TraceRayFilter(clientLoc, targetLoc, MASK_SOLID,
					  RayType_EndPoint, TraceRayDontHitSelf,
					  client);
	return (TR_GetEntityIndex() == target);
}

stock bool:TraceTargetIndex(client, target, Float:clientLoc[3], Float:targetLoc[3])
{
	targetLoc[2] += 50.0; // Adjust trace position of target
	TR_TraceRayFilter(clientLoc, targetLoc, MASK_SOLID,
					  RayType_EndPoint, TraceRayDontHitSelf,
					  client);
	return (TR_GetEntityIndex() == target);
}

stock bool:TraceTargetEntity(client, target, Float:clientLoc[3], Float:targetLoc[3])
{
	targetLoc[2] += 10.0; // Adjust trace position of target
	TR_TraceRayFilter(clientLoc, targetLoc, MASK_SOLID,
					  RayType_EndPoint, TraceRayDontHitSelf,
					  client);
	return (TR_GetEntityIndex() == target);
}

stock bool:TraceTargetClients(client, target, Float:clientLoc[3], Float:targetLoc[3])
{
	clientLoc[2] += 50.0; // Adjust trace position to the middle
	targetLoc[2] += 50.0; // of the person instead of the feet.
	TR_TraceRayFilter(clientLoc, targetLoc, MASK_SOLID,
					  RayType_EndPoint, TraceRayDontHitSelf,
					  client);
	return (TR_GetEntityIndex() == target);
}

stock TraceAimTarget(client)
{
	new Float:clientloc[3],Float:clientang[3];
	GetClientEyePosition(client,clientloc);
	GetClientEyeAngles(client,clientang);
	TR_TraceRayFilter(clientloc, clientang, MASK_SOLID,
					  RayType_Infinite, TraceRayDontHitSelf,
					  client);
	return TR_GetEntityIndex();
}

stock bool:TraceAimPosition(client, Float:destLoc[3], bool:hitPlayers)
{
	new Float:clientloc[3],Float:clientang[3];
	GetClientEyePosition(client,clientloc);
	GetClientEyeAngles(client,clientang);

	if (hitPlayers)
	{
		TR_TraceRayFilter(clientloc, clientang, MASK_SOLID,
						  RayType_Infinite, TraceRayDontHitSelf,
						  client);
	}
	else
	{
		TR_TraceRayFilter(clientloc, clientang, MASK_SOLID,
						  RayType_Infinite, TraceRayDontHitPlayers,
						  client);
	}

	TR_GetEndPosition(destLoc);
	return TR_DidHit();
}

/***************
 *Trace Filters*
****************/

public bool:TraceRayDontHitPlayers(entity,mask)
{
  // Check if the beam hit a player and tell it to keep tracing if it did
  return (entity <= 0 || entity > MaxClients);
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return (entity != data); // Check if the TraceRay hit the owning entity.
}
