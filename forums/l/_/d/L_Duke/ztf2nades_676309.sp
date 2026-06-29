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

new bool:gDebug = true;

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
new gHolding[MAX_PLAYERS+1];
new Handle:gNadeTimer[MAX_PLAYERS+1];				// pointer to nade timer
new Handle:gNadeTimer2[MAX_PLAYERS+1];
new bool:gTriggerTimer[MAX_PLAYERS+1];
new gNade[MAX_PLAYERS+1];							// pointer to the player's nade
new gNadeTemp[MAX_PLAYERS+1];						// temp nade entity (like for nail nade)
new gRingModel;										// model for beams
new Float:gHoldingArea[3];							// point to store unused objects
new Float:PlayersInRange[MAX_PLAYERS+1];			// players are in radius ?
new gKilledBy[MAX_PLAYERS+1];						// player that killed
new String:gKillWeapon[MAX_PLAYERS+1][STRLENGTH];	// weapon that killed
new Float:gKillTime[MAX_PLAYERS+1];					// time plugin requested kill
new gNapalmSprite;									// sprite index
new gEmpSprite;
new gStopInfoPanel[MAX_PLAYERS+1];

#define HOLD_NONE 0
#define HOLD_FRAG 1
#define HOLD_SPECIAL 2

// global "temps"
new String:tName[256];

// *************************************************
// convars
// *************************************************
new Handle:cvWaitPeriod = INVALID_HANDLE;
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
new Handle:cvEmpNum = INVALID_HANDLE;
new Handle:cvEmpRadius = INVALID_HANDLE;
new Handle:cvHelpLink = INVALID_HANDLE;
new Handle:cvShowHelp = INVALID_HANDLE;
//new Handle:cvTest = INVALID_HANDLE;


native TF2_IgnitePlayer(client, attacker);

// *************************************************
// main plugin
// *************************************************

public OnPluginStart() {
	
	// events
	HookEvent("player_spawn",PlayerSpawn);
	HookEvent("player_death",PlayerDeath, EventHookMode_Pre);
	HookEvent("player_changeclass", ChangeClass);
	HookEvent("teamplay_round_start", MainEvents);
	HookEvent("teamplay_round_active", MainEvents);
	HookEvent("teamplay_restart_round", MainEvents);
	HookEvent("teamplay_round_stalemate", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_game_over", RoundEnd, EventHookMode_PostNoCopy);
	
	
	// convars
	cvWaitPeriod = CreateConVar("sm_tf2nades_waitperiod", "1", "server waits for players on map start (1=true 0=false)");
	cvShowHelp = CreateConVar("sm_tf2nades_showhelp", "0", "show help link at player spawn (until they say !stop) (1=yes 0=no)");
	cvHelpLink = CreateConVar("sm_tf2nades_helplink", "http://www.tf2nades.com/motd/plugin/tf2nades.1.0.0.6.html", "web page with info on the TF2NADES plugin");
	cvEmpRadius = CreateConVar("sm_tf2nades_emp_radius", "256", "radius for emp nade", 0, true, 1.0, true, 2048.0);
	cvEmpNum = CreateConVar("sm_tf2nades_emp", "3", "number of nades given", 0, true, 0.0, true, 10.0); 
	cvHallucDamage = CreateConVar("sm_tf2nades_halluc_damage", "5", "damage done by hallucination nade");
	cvHallucDelay = CreateConVar("sm_tf2nades_hallucination_time", "5.0", "delay in seconds that effects last", 0, true, 1.0, true, 10.0);	
	cvHallucRadius = CreateConVar("sm_tf2nades_hallucination_radius", "256", "radius for hallincation nade", 0, true, 1.0, true, 2048.0);
	cvHallucNum = CreateConVar("sm_tf2nades_hallucination", "3", "number of nades given", 0, true, 0.0, true, 10.0); 
	cvNapalmDamage = CreateConVar("sm_tf2nades_napalm_damage", "25", "initial damage for napalm nade", 0, true, 1.0, true, 500.0);
	cvNapalmRadius = CreateConVar("sm_tf2nades_napalm_radius", "256", "radius for napalm nade", 0, true, 1.0, true, 2048.0);
	cvNapalmNum = CreateConVar("sm_tf2nades_napalm", "2", "number of nades given", 0, true, 0.0, true, 10.0); 
	cvHealthDelay = CreateConVar("sm_tf2nades_health_delay", "5.0", "delay in seconds before nade explodes", 0, true, 1.0, true, 10.0);
	cvHealthRadius = CreateConVar("sm_tf2nades_health_radius", "256", "radius for health nade", 0, true, 1.0, true, 2048.0);
	cvHealthNum = CreateConVar("sm_tf2nades_health", "2", "number of nades given", 0, true, 0.0, true, 10.0); 
	cvMirvSpread = CreateConVar("sm_tf2nades_mirv_spread", "384.0", "spread of secondary explosives (max speed)", 0, true, 1.0, true, 2048.0);	
	cvMirvDamage2 = CreateConVar("sm_tf2nades_mirv_damage2", "50.0", "damage done by secondary explosion of mirv nade", 0, true, 1.0, true, 500.0);	
	cvMirvDamage1 = CreateConVar("sm_tf2nades_mirv_damage1", "25.0", "damage done by main explosion of mirv nade", 0, true, 1.0, true, 500.0);
	cvMirvRadius = CreateConVar("sm_tf2nades_mirv_radius", "128", "radius for demo's nade", 0, true, 1.0, true, 2048.0);
	cvMirvNum = CreateConVar("sm_tf2nades_mirv", "2", "number of nades given", 0, true, 0.0, true, 10.0); 
	cvNailDamageExplode = CreateConVar("sm_tf2nades_nail_explodedamage", "100.0", "damage done by final explosion", 0, true, 1.0, true,1000.0);
	cvNailDamageNail = CreateConVar("sm_tf2nades_nail_naildamage", "8.0", "damage done by nail projectile", 0, true, 1.0, true, 500.0);
	cvNailRadius = CreateConVar("sm_tf2nades_nail_radius", "256", "radius for nail nade", 0, true, 1.0, true, 2048.0);
	cvNailNum = CreateConVar("sm_tf2nades_nail", "2", "number of nades given", 0, true, 0.0, true, 10.0);
	cvConcDamage = CreateConVar("sm_tf2nades_conc_damage", "10", "damage done by concussion nade");
	cvConcForce = CreateConVar("sm_tf2nades_conc_force", "750", "force applied by concussion nade");
	cvConcRadius = CreateConVar("sm_tf2nades_conc_radius", "256", "radius for concussion nade", 0, true, 1.0, true, 2048.0);
	cvConcNum = CreateConVar("sm_tf2nades_conc", "3", "number of nades given", 0, true, 0.0, true, 10.0);
	cvFragDamage = CreateConVar("sm_tf2nades_frag_damage", "100", "damage done by concussion nade");
	cvFragRadius = CreateConVar("sm_tf2nades_frag_radius", "256", "radius for concussion nade", 0, true, 1.0, true, 2048.0);
	cvFragNum[ENGIE] = CreateConVar("sm_tf2nades_frag_engineer", "2", "number of frag nades given", 0, true, 0.0, true, 10.0);
	cvFragNum[SPY] = CreateConVar("sm_tf2nades_frag_spy", "2", "number of frag nades given", 0, true, 0.0, true, 10.0);
	cvFragNum[PYRO] = CreateConVar("sm_tf2nades_frag_pyro", "2", "number of frag nades given", 0, true, 0.0, true, 10.0);
	cvFragNum[HEAVY] = CreateConVar("sm_tf2nades_frag_heavy", "2", "number of frag nades given", 0, true, 0.0, true, 10.0);
	cvFragNum[MEDIC] = CreateConVar("sm_tf2nades_frag_medic", "2", "number of frag nades given", 0, true, 0.0, true, 10.0);
	cvFragNum[DEMO] = CreateConVar("sm_tf2nades_frag_demo", "2", "number of frag nades given", 0, true, 0.0, true, 10.0);
	cvFragNum[SOLDIER] = CreateConVar("sm_tf2nades_frag_soldier", "2", "number of frag nades given", 0, true, 0.0, true, 10.0);
	cvFragNum[SNIPER] = CreateConVar("sm_tf2nades_frag_sniper", "2", "number of frag nades given", 0, true, 0.0, true, 10.0);
	cvFragNum[SCOUT] = CreateConVar("sm_tf2nades_frag_scout", "2", "number of frag nades given", 0, true, 0.0, true, 10.0);
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
	
	// misc setup
	LoadTranslations("tf2nades.phrases");
	gHoldingArea[0]=-10000.0; gHoldingArea[1]=-10000.0; gHoldingArea[2]=-10000.0;
	
	// hooks
	HookEntityOutput("prop_dynamic", "OnAnimationBegun", EntityOutput_OnAnimationBegun);
}



public OnEventShutdown()
{
	UnhookEvent("player_spawn",PlayerSpawn);
	UnhookEvent("player_death",PlayerDeath);
}



public OnMapStart()
{
	// initialize model for nades (until class is chosen)
	gnSpeed = 100.0;
	gnDelay = 2.0;
	
	// precache models
	gRingModel = PrecacheModel("sprites/laser.vmt", true);
	gNapalmSprite = PrecacheModel("sprites/floorfire4_.vmt", true);
	gEmpSprite = PrecacheModel("sprites/laser.vmt", true);
	PrecacheNadeModels();
	
	// precache sounds
	PrecacheSound(SND_THROWNADE, true);
	PrecacheSound(SND_NADE_FRAG, true);
	PrecacheSound(SND_NADE_CONC, true);
	PrecacheSound(SND_NADE_NAIL, true);
	PrecacheSound(SND_NADE_NAIL_EXPLODE, true);
	PrecacheSound(SND_NADE_NAIL_SHOOT1, true);
	PrecacheSound(SND_NADE_NAIL_SHOOT2, true);
	PrecacheSound(SND_NADE_NAIL_SHOOT3, true);
	PrecacheSound(SND_NADE_MIRV1, true);
	PrecacheSound(SND_NADE_MIRV2, true);
	PrecacheSound(SND_NADE_HEALTH, true);
	PrecacheSound(SND_NADE_NAPALM, true);
	PrecacheSound(SND_NADE_HALLUC, true);
	PrecacheSound(SND_NADE_EMP, true);
	PrecacheSound(sndPain, true);
	
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
	}
	
	
	// reset players
	new i;
	for (i=1;i<=MAX_PLAYERS;i++)
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
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	gCanRun = false;
}


public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	gHolding[client]=HOLD_NONE;
	
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
	
	SetupNade(GiveFullNades(client), GetClientTeam(client), 1);
	
	FireTimers(client);
	gNadeTimer[client]=INVALID_HANDLE;
	
	new i;
	new ents = GetMaxEntities();
	new String:edictname[128];
	for (i=GetMaxClients()+1; i<ents; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, edictname, 128);
			if(StrEqual(edictname, "prop_physics") || StrEqual(edictname, "prop_dynamic_override"))
			{
				if (GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity")==client)
				{
					RemoveEdict(i);
				}
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
			new j;
			new maxplayers = GetMaxClients();
			for (j=1;j<=maxplayers;j++)
			{
				if(PlayersInRange[j]>0.0)
				{
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
	gHolding[client] = HOLD_NONE;
	
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
	gHolding[client] = HOLD_NONE;
	
	FireTimers(client);
	
}

public Action:Command_Nade1(client, args) 
{
	
	if (gHolding[client]>HOLD_NONE)
		return Plugin_Handled;
	
	SetupHudMsg(3.0);
	if (!gCanRun)
	{
		ShowHudText(client, 1, "%t", "WaitingPeriod");
		return Plugin_Handled;
	}
	
	// not while cloaked or taunting
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond&16 || cond&128)
	{
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
			ThrowNade(client, false, true);    
			gRemaining1[client]-=1;
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
	if (gHolding[client]!=HOLD_FRAG)
		return Plugin_Handled;
	
	if (gNadeTimer[client]!=INVALID_HANDLE)
	{
		ThrowNade(client, false, false);
	}
	return Plugin_Handled;
}

public Action:Command_Nade2(client, args) 
{
	if (gHolding[client]>HOLD_NONE)
		return Plugin_Handled;
	
	SetupHudMsg(3.0);
	if (!gCanRun)
	{
		ShowHudText(client, 1, "%t", "WaitingPeriod");
		return Plugin_Handled;
	}
	
	// not while cloaked or taunting
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond&16 || cond&128)
	{
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
			ThrowNade(client, true, true );    
			gRemaining2[client]-=1;
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
	if (gHolding[client]!=HOLD_SPECIAL)
		return Plugin_Handled;
	
	if (gNadeTimer[client]!=INVALID_HANDLE)
	{
		ThrowNade(client, true, false);
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
	
	new maxplayers = GetMaxClients();
	new j;
	for (j=1;j<=maxplayers;j++)
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
	new i;
	for (i=0;i<OFFSIZE;i++)
	{
	gOff[i]=-1;
	}
	ReplyToCommand(client, "offsets reset");
	}
	else
	{
	new i;
	new count=0;
	new tval;
	for (i=1;i<OFFSIZE;i++)
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
		if (strncmp(tName,"tf2nade",7)!=0)
		{
			makenade=true;
		}
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

ThrowNade(client, bool:special=true, bool:Setup)
{
	if (Setup)
	{
		// save priming status
		if (special)
		{
			gHolding[client]=HOLD_SPECIAL;
		}
		else
		{
			gHolding[client]=HOLD_FRAG;
		}
		
		// setup nade if it doesn't exist
		GetNade(client);

		// reset
		gNadeTimer[client] = INVALID_HANDLE;

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
	
	// setup nade variables based on player class
	new class = int:TF2_GetPlayerClass(client);
	SetupNade(class, GetClientTeam(client), special ? 1 : 0);
	
	if (!Setup)
	{
		// reset priming status
		gHolding[client] = HOLD_NONE;
		
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
		Format(gnSkin, sizeof(gnSkin), "%d", GetClientTeam(client)-2);
		DispatchKeyValue(gNade[client], "skin", gnSkin);
		angle[0] = GetRandomFloat(-180.0, 180.0);
		angle[1] = GetRandomFloat(-180.0, 180.0);
		angle[2] = GetRandomFloat(-180.0, 180.0);
		TeleportEntity(gNade[client], startpt, angle, speed);
		if (strlen(gnParticle)>0)
		{
			AttachParticle(gNade[client], gnParticle, gnDelay);
		}
	
		EmitSoundToAll(SND_THROWNADE, client);
	}
	
	if (Setup)
	{
		new Handle:pack;
		gNadeTimer[client] = CreateDataTimer(gnDelay, NadeExplode, pack);
		WritePackCell(pack, client);
		WritePackCell(pack, GetClientTeam(client));
		WritePackCell(pack, class);
		WritePackCell(pack, special ? 1 : 0);
	}
}

public Action:NadeExplode(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new team = ReadPackCell(pack);
	new class = ReadPackCell(pack);
	new special = ReadPackCell(pack);
	
	if (IsValidEdict(gNade[client]))
	{
		GetEntPropString(gNade[client], Prop_Data, "m_iName", tName, sizeof(tName));
		if (strncmp(tName,"tf2nade",7)==0)
		{
			ExplodeNade(client, team, class, special);
		} 
	}
}

public GiveFullNades(client)
{
	new class = int:TF2_GetPlayerClass(client);
	gRemaining1[client] = GetConVarInt(cvFragNum[class]);
	gRemaining2[client] = GetNumNades(class);
	SetupHudMsg(3.0);
	ShowHudText(client, 1, "%t", "GivenNades", gRemaining1[client], gRemaining2[client]);
	return int:class;
}

ExplodeNade(client, team, class, special)
{ 
	if (gHolding[client]>HOLD_NONE)
	{
		ThrowNade(client, gHolding[client]==HOLD_SPECIAL ? true : false, false);
	}
	gNadeTimer[client]=INVALID_HANDLE;
	new Float:radius;
	if (special==0)
	{
		// effects
		new Float:center[3];
		GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
		ShowParticle(center, "ExplosionCore_MidAir", 2.0);
		EmitSoundToAll(SND_NADE_FRAG, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
		// player damage
		radius = GetConVarFloat(cvFragRadius);
		new damage = GetConVarInt(cvFragDamage);
		new oteam;
		if (GetClientTeam(client)==3) {oteam=2;} else {oteam=3;}
		FindPlayersInRange(center, radius, oteam, client, true, gNade[client]);
		new j;
		new maxplayers = GetMaxClients();
		for (j=1;j<=maxplayers;j++)
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
		switch (class)
		{
			case SCOUT:
			{
				radius = GetConVarFloat(cvConcRadius);
				new damage = GetConVarInt(cvConcDamage);
				new Float:center[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "impact_generic_smoke", 2.0);
				PrintToServer("client %d", client);
				EmitSoundToAll(SND_NADE_CONC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				new oteam;
				if (team==3) {oteam=2;} else {oteam=3;}
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client]);
				new j;
				new Float:play[3];
				new Float:playerspeed[3];
				new Float:distance;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
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
			case SNIPER:
			{
				
			}
			case SOLDIER:
			{
				SetupNade(SOLDIER, GetClientTeam(client), 1);
				radius = GetConVarFloat(cvNailRadius);
				new Float:center[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "Explosions_MA_Dustup_2", 2.0);
				center[2]+=32.0;
				new Float:angles[3] = {0.0,0.0,0.0};
				gNadeTemp[client] = CreateEntityByName("prop_dynamic_override");
				if (IsValidEntity(gNadeTemp[client]))
				{
					SetEntPropEnt(gNadeTemp[client], Prop_Data, "m_hOwnerEntity", client);
					SetEntityModel(gNadeTemp[client],gnModel);
					SetEntProp(gNadeTemp[client], Prop_Data, "m_CollisionGroup", 1);
					SetEntProp(gNadeTemp[client], Prop_Data, "m_usSolidFlags", 16);
					Format(gnSkin, sizeof(gnSkin), "%d", GetClientTeam(client)-2);
					DispatchKeyValue(gNadeTemp[client], "skin", gnSkin);
					Format(tName, sizeof(tName), "tf2nailnade", gNade[client]);
					DispatchKeyValue(gNadeTemp[client], "targetname", tName);
					DispatchSpawn(gNadeTemp[client]);
					TeleportEntity(gNadeTemp[client], center, angles, NULL_VECTOR);
					SetVariantString("release");
					AcceptEntityInput(gNadeTemp[client], "SetAnimation");
					//AcceptEntityInput(ent, "SetDefaultAnimation");
					EmitSoundToAll(SND_NADE_NAIL, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
					gNadeTimer[client] = CreateTimer(0.2, SoldierNadeThink, client, TIMER_REPEAT);
					gNadeTimer2[client] = CreateTimer(4.5, SoldierNadeFinish, client); 
				}
			}
			case DEMO:
			{
				radius = GetConVarFloat(cvMirvRadius);
				new damage = GetConVarInt(cvMirvDamage1);
				new Float:center[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);
				EmitSoundToAll(SND_NADE_MIRV1, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				new oteam;
				if (team==3) {oteam=2;} else {oteam=3;}
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client]);
				new j;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						HurtPlayer(j, client, damage, "tf2nade_mirv", true, center);
					}
				}
				DamageBuildings(client, center, radius, damage, gNade[client], true);
				new Float:spread;
				new Float:vel[3], Float:angle[3], Float:rand;
				Format(gnSkin, sizeof(gnSkin), "%d", GetClientTeam(client)-2);
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
			case MEDIC:
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
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.25,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.50,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.75,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				EmitSoundToAll(SND_NADE_HEALTH, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, beamcenter, NULL_VECTOR, false, 0.0);
				FindPlayersInRange(beamcenter, radius, team, client, true, gNade[client]);
				new j;
				new health;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
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
			case HEAVY:
			{
				ExplodeNade(client, team, DEMO, special);
			}
			case PYRO:
			{
				radius = GetConVarFloat(cvNapalmRadius);
				new damage = GetConVarInt(cvNapalmDamage);
				new Float:center[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);
				TE_SetupExplosion(center, gNapalmSprite, 2.0, 1, 4, RoundToCeil(radius), 0);
				TE_SendToAll();
				EmitSoundToAll(SND_NADE_NAPALM, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				new oteam;
				if (team==3) {oteam=2;} else {oteam=3;}
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client]);
				new j;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						new health = GetClientHealth(j);
						if (damage>=health)
						{
							HurtPlayer(j, client, health-1, "tf2nade_napalm", true, center, 2.0);
						}
						else
						{
							HurtPlayer(j, client, damage, "tf2nade_napalm", true, center, 2.0);
						}
						TF2_IgnitePlayer(j, client);
					}
				}
				DamageBuildings(client, center, radius, damage, gNade[client], true);
			}
			case SPY:
			{
				radius = GetConVarFloat(cvHallucRadius);
				new damage = GetConVarInt(cvHallucDamage);
				new Float:center[3], Float:angles[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_sapperdestroyed", 2.0);
				EmitSoundToAll(SND_NADE_HALLUC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				new oteam;
				if (team==3) {oteam=2;} else {oteam=3;}
				FindPlayersInRange(center, radius, oteam, client, true, gNade[client]);
				new rand1;
				new j;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
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
						ClientCommand(j, "r_screenoverlay effects/tp_eyefx/tp_eyefx\n");
						CreateTimer(GetConVarFloat(cvHallucDelay), ResetPlayerView, j);
						HurtPlayer(j, client, damage, "tf2nade_halluc", false, NULL_VECTOR); 
					}
				}
			}
			case ENGIE:
			{
				radius = GetConVarFloat(cvEmpRadius);
				new Float:center[3];
				GetEntPropVector(gNade[client], Prop_Send, "m_vecOrigin", center);
				ShowParticle(center, "ExplosionCore_sapperdestroyed", 2.0);
				EmitSoundToAll(SND_NADE_EMP, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				new oteam;
				if (team==3) {oteam=2;} else {oteam=3;}
				FindPlayersInRange(center, radius, oteam, client, false, -1);
				new j;
				new beamcolor[4];
				if (team==2)
				{
					beamcolor[0]=255;beamcolor[1]=0;beamcolor[2]=0;beamcolor[3]=255;
				}
				else
				{
					beamcolor[0]=0;beamcolor[1]=0;beamcolor[2]=255;beamcolor[3]=255;
				}
				TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite, 1, 1, 0.5, 4.0, 10.0, beamcolor, 100, 0);
				TE_SendToAll();
				TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite, 1, 1, 0.75, 4.0, 10.0, beamcolor, 100, 0);
				TE_SendToAll();
				TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite, 1, 1, 1.0, 4.0, 10.0, beamcolor, 100, 0);
				TE_SendToAll();
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						TF2_RemovePlayerDisguise(j);
					}
				}
				new i;
				radius = radius * radius;
				new Float:orig[3], Float:distance;
				for (i=GetMaxClients()+1; i<GetMaxEntities(); i++)
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
			default:
			{
				
			}
		}
	}
	TeleportEntity(gNade[client], gHoldingArea, NULL_VECTOR, NULL_VECTOR);	
}

SetupNade(class, team, special)
{
	// setup frag nade if not special
	if (special==0)
	{
		strcopy(gnModel, sizeof(gnModel), MDL_FRAG);
		gnSpeed = 2000.0;
		gnDelay = 2.0;
		gnParticle[0]='\0';
		return;
	}
	
	// setup special nade if not frag
	switch (class)
	{
		case SCOUT:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_CONC);
			gnSpeed = 1500.0;
			gnDelay = 2.0;
			strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
			
		}
		case SNIPER:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_MIRV2);
			gnSpeed = 100.0;
			gnDelay = 2.0;
			gnParticle[0]='\0';
		}
		case SOLDIER:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_NAIL);
			gnSpeed = 1000.0;
			gnDelay = 2.0;
			gnParticle[0]='\0';
		}
		case DEMO:
		{
			SetupNade(ENGIE, team, special);
			strcopy(gnModel, sizeof(gnModel), MDL_MIRV1);
			gnSpeed = 1250.0;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		case MEDIC:
		{
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
		case HEAVY:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_MIRV1);
			gnSpeed = 1250.0;
			gnDelay = 3.0;
			gnParticle[0]='\0';
		}
		case PYRO:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_NAPALM);
			gnSpeed = 2000.0;
			gnDelay = 2.0;
			gnParticle[0]='\0';
		}
		case SPY:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_HALLUC);
			gnSpeed = 1500.0;
			gnDelay = 2.0;
			strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
		}
		case ENGIE:
		{
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
		default:
		{
			strcopy(gnModel, sizeof(gnModel), MDL_FRAG);
			gnSpeed = 2000.0;
			gnDelay = 2.0;
			gnParticle[0]='\0';
		}
	}
	
}

GetNumNades(class)
{
	switch (class)
	{
		case SCOUT:
		{
			return GetConVarInt(cvConcNum);
			
		}
		case SNIPER:
		{
			return 0;
		}
		case SOLDIER:
		{
			return GetConVarInt(cvNailNum);
		}
		case DEMO:
		{
			return GetConVarInt(cvMirvNum);
		}
		case MEDIC:
		{
			return GetConVarInt(cvHealthNum);
		}
		case HEAVY:
		{
			return GetConVarInt(cvMirvNum);
		}
		case PYRO:
		{
			return GetConVarInt(cvNapalmNum);
		}
		case SPY:
		{
			return GetConVarInt(cvHallucNum);
		}
		case ENGIE:
		{
			return GetConVarInt(cvEmpNum);
		}
		default:
		{
			return 0;
		}
	}
	
	return 0;
	
}

FireTimers(client){
	// nades
	if (gNadeTimer[client]!=INVALID_HANDLE)
	{
		gTriggerTimer[client] = true;
		TriggerTimer(gNadeTimer[client]);
		if (gNadeTimer[client]!=INVALID_HANDLE)
		{
			TriggerTimer(gNadeTimer[client]);
		}
		gTriggerTimer[client] = false;
	}
	if (gNadeTimer2[client]!=INVALID_HANDLE)
	{
		gTriggerTimer[client] = true;
		TriggerTimer(gNadeTimer2[client]);
		if (gNadeTimer2[client]!=INVALID_HANDLE)
		{
			TriggerTimer(gNadeTimer2[client]);
		}
		gTriggerTimer[client] = false;
	}
}

public Action:SoldierNadeThink(Handle:timer, any:client)
{
	if (IsValidEntity(gNadeTemp[client]))
	{
		// effects
		new Float:center[3];
		GetEntPropVector(gNadeTemp[client], Prop_Send, "m_vecOrigin", center);
		new rand = GetRandomInt(1, 3);
		switch (rand)
		{
			case 1:
			{
				Format(tName, sizeof(tName), "%s", SND_NADE_NAIL_SHOOT1);
			}
			case 2:
			{
				Format(tName, sizeof(tName), "%s", SND_NADE_NAIL_SHOOT2);
			}
			default:
			{
				Format(tName, sizeof(tName), "%s", SND_NADE_NAIL_SHOOT3);
			}
			
		}
		EmitSoundToAll(tName, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
		new Float:dir[3];
		dir[0] = GetRandomFloat(-1.0, 1.0);
		dir[1] = GetRandomFloat(-1.0, 1.0);
		dir[2] = GetRandomFloat(-1.0, 1.0);
		TE_SetupMetalSparks(center, dir);
		TE_SendToAll();
		
		// player damage
		new oteam;
		if (GetClientTeam(client)==3) {oteam=2;} else {oteam=3;}
		FindPlayersInRange(center, GetConVarFloat(cvNailRadius), oteam, client, true, gNadeTemp[client]);
		new j;
		new maxplayers = GetMaxClients();
		for (j=1;j<=maxplayers;j++)
		{
			if(PlayersInRange[j]>0.0)
			{
				HurtPlayer(j, client, GetConVarInt(cvNailDamageNail), "tf2nade_nail", false, center);
			}
		}
	}
	return Plugin_Continue;
}

public Action:SoldierNadeFinish(Handle:timer, any:client)
{
	if (gNadeTimer[client]!=INVALID_HANDLE)
	{
		KillTimer(gNadeTimer[client]);
	}
	gNadeTimer[client] = INVALID_HANDLE;
	StopSound(gNadeTemp[client], SNDCHAN_WEAPON, SND_NADE_NAIL);
	if (IsValidEntity(gNadeTemp[client]))
	{
		new damage = GetConVarInt(cvNailDamageExplode);
		GetEntPropString(gNadeTemp[client], Prop_Data, "m_iName", tName, sizeof(tName));
		if (strncmp(tName,"tf2nailnade",11)==0)
		{
			// effects
			new Float:center[3];
			new Float:radius = GetConVarFloat(cvNailRadius);
			GetEntPropVector(gNadeTemp[client], Prop_Send, "m_vecOrigin", center);
			ShowParticle(center, "ExplosionCore_MidAir", 2.0);
			EmitSoundToAll(SND_NADE_NAIL_EXPLODE, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
			// player damage
			new oteam;
			if (GetClientTeam(client)==3) {oteam=2;} else {oteam=3;}
			FindPlayersInRange(center, radius, oteam, client, true, gNadeTemp[client]);
			new j;
			new maxplayers = GetMaxClients();
			for (j=1;j<=maxplayers;j++)
			{
				if(PlayersInRange[j]>0.0)
				{
					HurtPlayer(j, client, damage, "tf2nade_nail", true, center);
				}
			}
			DamageBuildings(client, center, radius, damage, gNadeTemp[client], true);
			RemoveEdict(gNadeTemp[client]);
		}
	}
	gNadeTemp[client] = 0;
}

public Action:MirvExplode2(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new team = ReadPackCell(pack);
	new ent[MIRV_PARTS];
	new k;
	for (k=0;k<MIRV_PARTS;k++)
	{
		ent[k] = ReadPackCell(pack);
	}
	
	gNadeTimer[client] = INVALID_HANDLE;
	
	new Float:radius = GetConVarFloat(cvMirvRadius);
	new Float:center[3];
	
	for (k=0;k<MIRV_PARTS;k++)
	{
		GetEntPropString(ent[k], Prop_Data, "m_iName", tName, sizeof(tName));
		if (strncmp(tName,"tf2mirv",7)==0)
		{
			new damage = GetConVarInt(cvMirvDamage2);
			GetEntPropVector(ent[k], Prop_Send, "m_vecOrigin", center);
			ShowParticle(center, "ExplosionCore_MidAir", 2.0);
			EmitSoundToAll(SND_NADE_MIRV2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, Float:k * 0.25);
			new oteam;
			if (team==3) {oteam=2;} else {oteam=3;}
			FindPlayersInRange(center, radius, oteam, client, true, ent[k]);
			new j;
			new maxplayers = GetMaxClients();
			for (j=1;j<=maxplayers;j++)
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


public Action:ResetPlayerView(Handle:timer, any:client)
{
	new Float:angles[3];
	GetClientEyeAngles(client, angles);
	angles[2] = 0.0;
	TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
	ClientCommand(client, "r_screenoverlay none\n");
}


PrecacheNadeModels()
{
	
	PrecacheModel("models/error.mdl");
	
	PrecacheModel(MDL_FRAG, true);
	PrecacheModel(MDL_CONC, true);
	PrecacheModel(MDL_NAIL, true);
	PrecacheModel(MDL_MIRV1, true);
	PrecacheModel(MDL_MIRV2, true);
	PrecacheModel(MDL_HEALTH, true);
	PrecacheModel(MDL_NAPALM, true);
	PrecacheModel(MDL_HALLUC, true);
	PrecacheModel(MDL_EMP, true);
	
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
		else
		{
			LogError("DeleteParticles: not removing entity - not a particle '%s'", classname);
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
	new maxplayers = GetMaxClients();
	for (j=1;j<=maxplayers;j++)
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
	gKilledBy[client] = GetClientUserId(attacker);
	gKillTime[client] = GetEngineTime();
	strcopy(gKillWeapon[client], STRLENGTH, weapon);
	/*
	if (explode)
	{
	FakeClientCommand(client, "explode\n");
	}
	else
	{
	ForcePlayerSuicide(client);
	}
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

HurtPlayer(client, attacker, damage, String:weapon[256], bool:explosion, Float:pos[3], Float:knockbackmult = 4.0)
{
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond & 32)
	{
		return;
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
		EmitSoundToAll(sndPain, client);
		SetEntityHealth(client, health-damage);
	}
	else
	{
		KillPlayer(client, attacker, weapon);
	}
}

DamageBuildings(attacker, Float:start[3], Float:radius, damage, nade, bool:trace)
{
	new Float:pos[3];
	pos[0]=start[0];pos[1]=start[1];pos[2]=start[2]+16.0;
	new count = GetMaxEntities();
	new i;
	new Float:obj[3], Float:objcalc[3];
	new Float:rad = radius * radius;
	new Float:distance;
	new Handle:tr;
	new team = GetClientTeam(attacker);
	new objteam;
	for (i=GetMaxClients()+1; i<count; i++)
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
	
	if (entity <= GetMaxClients())
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
	
	if (entity <= GetMaxClients())
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


