#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>


#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name = "Nades",
	author = "CrancK",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

#define MAX_PLAYERS 33   // maxplayers + sourceTV
#define MAX_NADES 10	//max amount of nades per person
#define MIRV_PARTS 4

//temp??
#define FFADE_IN            0x0001        // Just here so we don't pass 0 into the function
#define FFADE_OUT           0x0002        // Fade out (not in)
#define FFADE_MODULATE      0x0004        // Modulate (don't blend)
#define FFADE_STAYOUT       0x0008        // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE         0x0010        // Purges all other fades, replacing them with this one


// sounds
#define SND_THROWNADE "weapons/grenade_throw.wav"
#define SND_NADE_FRAG "weapons/explode1.wav"
#define SND_NADE_CONC "weapons/explode5.wav"
#define SND_NADE_NAPALM "ambient/fire/gascan_ignite1.wav"
#define SND_NADE_CONC_TIMER "weapons/det_pack_timer.wav"
//#define SND_NADE_NAPALM_TIMER "bush_fire.wav"
#define SND_NADE_NAIL "ambient/levels/labs/teleport_rings_loop2.wav"
#define SND_NADE_NAIL_EXPLODE "weapons/explode1.wav"
#define SND_NADE_NAIL_SHOOT1 "npc/turret_floor/shoot1.wav"
#define SND_NADE_NAIL_SHOOT2 "npc/turret_floor/shoot2.wav"
#define SND_NADE_NAIL_SHOOT3 "npc/turret_floor/shoot3.wav"
#define SND_NADE_MIRV1 "weapons/sentry_explode.wav"
#define SND_NADE_MIRV2 "weapons/explode1.wav"
//#define SND_NADE_HEALTH "items/suitchargeok1.wav"
#define SND_NADE_HALLUC "weapons/flame_thrower_airblast.wav"
#define SND_NADE_EMP "npc/scanner/scanner_electric2.wav"
#define SND_NADE_HEALTH "hallelujah.wav"
//#define SND_NADE_EMP_TIMER "weapons/boxing_gloves_crit_enabled.wav"
#define SND_NADE_HALLUC_TIMER "weapons/sentry_upgrading_steam3.wav"
//#define SND_NADE_TRAP "weapons/grenade_impact.wav"
#define SND_NADE_SMOKE "ambient/fire/ignite.wav"
#define SND_NADE_GAS "ambient/fire/ignite.wav"


//models
#define MDL_FRAG "models/weapons/nades/duke1/w_grenade_frag.mdl"
#define MDL_CONC "models/weapons/nades/duke1/w_grenade_conc.mdl"
#define MDL_NAPALM "models/weapons/nades/duke1/w_grenade_napalm.mdl"
#define MDL_NAIL "models/weapons/nades/duke1/w_grenade_nail.mdl"
#define MDL_MIRV1 "models/weapons/nades/duke1/w_grenade_mirv.mdl"
#define MDL_MIRV2 "models/weapons/nades/duke1/w_grenade_bomblet.mdl"
#define MDL_HEALTH "models/weapons/nades/duke1/w_grenade_heal.mdl"
#define MDL_HALLUC "models/weapons/nades/duke1/w_grenade_gas.mdl"
#define MDL_EMP "models/weapons/nades/duke1/w_grenade_emp.mdl"
#define MDL_SMOKE "models/weapons/nades/duke1/w_grenade_gas.mdl"
#define MDL_GAS "models/weapons/nades/duke1/w_grenade_gas.mdl"
#define MDL_SMOKE_SPRITE "sprites/smoke.vmt"
#define MDL_NAPALM_SPRITE "sprites/floorfire4_.vmt"
#define MDL_BEAM_SPRITE "sprites/laser.vmt"
#define MDL_EMP_SPRITE "sprites/laser.vmt"

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

#define DMG_GENERIC			0
#define DMG_CRUSH			(1 << 0)
#define DMG_BULLET			(1 << 1)
#define DMG_SLASH			(1 << 2)
#define DMG_BURN			(1 << 3)
#define DMG_VEHICLE			(1 << 4)
#define DMG_FALL			(1 << 5)
#define DMG_BLAST			(1 << 6)
#define DMG_CLUB			(1 << 7)
#define DMG_SHOCK			(1 << 8)
#define DMG_SONIC			(1 << 9)
#define DMG_ENERGYBEAM			(1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE	(1 << 11)
#define DMG_NEVERGIB			(1 << 12)
#define DMG_ALWAYSGIB			(1 << 13)
#define DMG_DROWN			(1 << 14)
#define DMG_TIMEBASED			(DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE			(1 << 15)
#define DMG_NERVEGAS			(1 << 16)
#define DMG_POISON			(1 << 17)
#define DMG_RADIATION			(1 << 18)
#define DMG_DROWNRECOVER		(1 << 19)
#define DMG_ACID			(1 << 20)
#define DMG_SLOWBURN			(1 << 21)
#define DMG_REMOVENORAGDOLL		(1 << 22)
#define DMG_PHYSGUN			(1 << 23)
#define DMG_PLASMA			(1 << 24)
#define DMG_AIRBOAT			(1 << 25)
#define DMG_DISSOLVE			(1 << 26)
#define DMG_BLAST_SURFACE		(1 << 27)
#define DMG_DIRECT			(1 << 28)
#define DMG_BUCKSHOT			(1 << 29)

#define HOLD_NONE 0
#define HOLD_PRIMARY 1
#define HOLD_SECONDARY 2
#define HOLD_TERTIARY 3

#define STRLENGTH 128

// global data for nade
new Float:gnSpeed;
new Float:gnDelay;
new String:gnModel[256];
new String:gnSkin[16];
new String:gnParticle[256];
new gNadesUsed[MAX_PLAYERS+1];
new bool:gCanRun = false;
new bool:gWaitOver = false;
new Float:gMapStart;
new gRemaining[3][MAX_PLAYERS+1];
new gHolding[MAX_PLAYERS+1];		
new Float:times[2048];
new gNade[MAX_PLAYERS+1][MAX_NADES+1];	
new gRingModel;		
new gNapalmSprite;
new gEmpSprite;
new gSmokeSprite;
new Float:gHoldingArea[3];										// point to store unused objects
new Float:PlayersInRange[MAX_PLAYERS+1];						// players are in radius ?
new bool:throwTime[MAX_PLAYERS+1];								// can player throw his next nade?
new bool:gThrown[2048];	
new tempId[MAX_PLAYERS+1];
//new Handle:g_precacheTrie = INVALID_HANDLE;

//new g_SmokeModelIndex;
//new g_TrapModelIndex;
//new g_GasModelIndex;

//new UserMsg:g_FadeUserMsgId;
new bool:Drugged[MAX_PLAYERS+1];
//new Handle:DrugTimer[MAX_PLAYERS+1];
//new Float:DrugAngles[20] = {
//	0.0, 10.0, 20.0, 30.0, 40.0, 
//	50.0, 40.0, 30.0, 20.0, 10.0, 
//	0.0, -10.0, -20.0, -30.0, -40.0, 
//	-50.0, -40.0, -30.0, -20.0, -10.0
//	};
	
static const TFClass_MaxAmmo[TFClassType][3] =
{
  {-1, -1, -1}, {32, 36, -1},
  {25, 75, -1}, {20, 32, -1},
  {16, 24, -1}, {150, -1, -1},
  {200, 32, -1}, {200, 32, -1},
  {24, -1, -1}, {32, 200, 200}
};

new Handle:cvPrimary[CLS_MAX][4]; //(4=amountmin, amountmax, damage/power, radius)
new Handle:cvSecondary[CLS_MAX][4];
new Handle:cvTertiary[CLS_MAX][4];
new Handle:cvAmmoMode;
new Handle:cvSoundMode;
new Handle:cvStartNades;
new Handle:cvNadesThrowPhysics;
new Handle:ff;
new Handle:cvConcRings;
new Handle:cvConcIgnore;
new Handle:cvConcBounce;
//new Handle:cvConcHHincrement;
new Handle:cvThrowDelay;
new Handle:cvNadesThrowSpeed;
new Handle:cvNadeTrail;
new Handle:cvRefill;
new Handle:cvBlastDistanceMin;
new Handle:cvWaitPeriod;
new Handle:cvConcBaseSpeed;
new Handle:cvConcBaseHeight;
new Handle:cvNadeDelay;
new Handle:cvNadeHHHeight;
new Handle:cvNadeIcon;
new Handle:cvNadesNailDamageNail;
new Handle:cvNadesNailRadiusNail;
new Handle:cvNadesMirvSpread;
new Handle:cvNadesEmpExplosion;
new Handle:cvEmpIgnore;
new Handle:cvNadeHealthOverHeal;
//new Handle:cvHallucVMT;
new Handle:cvSmokeDelay;
//new Handle:cvTrapDelay;
new Handle:cvDifGrav;
//new Handle:cvNadeHHPower;
//new Handle:cvNadeSolPower;
//new Handle:cvNadeHHMaxH;
new Handle:cvNadesHHMode;
new Handle:cvNadesHHDisDec;

// global "temps"

new Handle:g_hInterval;
new Handle:g_hTimer;
new Handle:HudMessage;

new Handle:SoundTimer[MAX_PLAYERS+1][10];
new Handle:NadeTimer[MAX_PLAYERS+1][6];
new Handle:nailTimer[MAX_PLAYERS+1][9];
new String:tName[256];
new nr = 0;
new nr2 = 0;
new nailnr = 0;
//new nr3 = 0;

//native TF2_IgnitePlayer(client, attacker);

public OnPluginStart() 
{
	HookEvent("player_spawn",PlayerSpawn);
	HookEvent("player_death",PlayerDeath, EventHookMode_Pre);
	HookEvent("player_changeclass", ChangeClass);
	HookEvent("teamplay_round_start", MainEvents);
	HookEvent("teamplay_round_active", MainEvents);
	HookEvent("teamplay_restart_round", MainEvents);
	HookEvent("teamplay_round_stalemate", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_game_over", RoundEnd, EventHookMode_PostNoCopy);
	
	CreateConVar("sm_nades_version", PLUGIN_VERSION, "Nades Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvWaitPeriod = CreateConVar("sm_nades_waitperiod", "1", "server waits for players on map start (1=true 0=false)(RECOMMENDED!)", FCVAR_PLUGIN);
	
	SetupNadeConVars();
	
	cvBlastDistanceMin = CreateConVar("sm_nades_conc_power_min", "0.25", "...");
	cvConcRings = CreateConVar("sm_nades_conc_rings", "10.0", "amount of rings the conc makes");
	cvConcIgnore = CreateConVar("sm_nades_conc_ignorewalls", "1", "enables the conc-blast to push people even through walls");
	//cvConcHHincrement = CreateConVar("sm_nades_conc_handheld_increment", "1.85", "...");
	cvConcBaseSpeed = CreateConVar("sm_nades_conc_base_speed", "1250.0", "base amount of speed concs push people at");
	cvConcBaseHeight = CreateConVar("sm_nades_conc_base_height", "48.0", "height correction for conc blast");
	cvConcBounce = CreateConVar("sm_nades_conc_bounce", "1", "wether fall speed is calculated or not");
	cvAmmoMode = CreateConVar("sm_nades_ammo_mode", "1", "0=only nades on respawn, 1=respawn+ammopacks");
	cvNadeDelay = CreateConVar("sm_nades_arming_time", "4.0", "amount in seconds from the moment you click, untill it explodes");
	cvStartNades = CreateConVar("sm_nades_start_amount", "1", "defines how many nades you get on spawn: 0 = none, 1 = sm_nades_***_amount_min, 2 = sm_nades_***_amount_max");
	cvSoundMode = CreateConVar("sm_nades_sound_mode", "1", "0 = no sound, 1 = full sound, 2 = client sound");
	cvNadesThrowPhysics = CreateConVar("sm_nades_throw_physics", "0", "0 = sm_nades_throw_speed, 1 = ???, 2 = playerspeed+sm_nades_throw_speed");
	cvNadesThrowSpeed = CreateConVar("sm_nades_throw_speed", "950.0", "speed at which nades are throw (heavier nades will still be slower then lighter nades)");
	cvThrowDelay = CreateConVar("sm_nades_throw_delay", "0.5", "delay between throwing nades");
	cvNadeTrail = CreateConVar("sm_nades_trail_enabled", "1", "enables or disables trails following the grenades");
	cvNadeHHHeight = CreateConVar("sm_nades_handheld_height", "24.0", "height correction for handhelds");
	cvRefill = CreateConVar("sm_nades_refill_enabled", "0", "infinite nade ammo");
	cvNadeIcon = CreateConVar("sm_nades_kill_icon", "tf_projectile_rocket", "kill icon for nades");
	cvNadesNailDamageNail = CreateConVar("sm_nades_nail_damage_nail", "10.0", "how much damage max, a nail from the nail nade can do");
	cvNadesNailRadiusNail = CreateConVar("sm_nades_nail_radius_nail", "288.0", "how much range a nail from the nail nade can has");
	cvNadesMirvSpread = CreateConVar("sm_nades_mirv_spread", "256.0", "spread of secondary explosives (max speed)");
	cvEmpIgnore = CreateConVar("sm_nades_emp_ignorewalls", "0", "enables the emp-blast to go through walls");
	cvNadeHealthOverHeal = CreateConVar("sm_nades_health_overheal", "0", "enables the heal nades to overheal");
	cvSmokeDelay = CreateConVar("sm_nades_smoke_lifetime", "10.0", "how long smoke from the smoke nade will last");
	//cvTrapDelay = CreateConVar("sm_nades_trap_lifetime", "10.0", "how long the beartrap stays active");
	cvDifGrav = CreateConVar("sm_nades_gravity", "1.0", "gravity for nades, only change if gravity for people is different");
	//cvNadeHHPower = CreateConVar("sm_nades_handheld_power", "1000.0", "...");
	//cvNadeSolPower = CreateConVar("sm_nades_soldier_pushpower", "1000.0", "..");
	//cvNadeHHMaxH = CreateConVar("sm_nades_handheld_max_height", "300.0", "...");
	cvNadesHHMode = CreateConVar("sm_nades_handheld_mode", "1", "0=off 2 =Soldierspecial");
	cvNadesHHDisDec = CreateConVar("sm_nades_handheld_distance_decrement", "0.1", "higher values = less push from handhelds (though 0.0 is also nearly no push)");
	g_hInterval = CreateConVar("sm_nades_ammo_info_interval", "5", "How often health timer is updated (in tenths of a second).");
	HookConVarChange(g_hInterval, ConVarChange_Interval);
	HudMessage = CreateHudSynchronizer();
	
	ff = FindConVar("mp_friendlyfire");
	
	RegConsoleCmd("+nade1", Command_Nade1);
	RegConsoleCmd("-nade1", Command_UnNade1);
	RegConsoleCmd("+nade2", Command_Nade2);
	RegConsoleCmd("-nade2", Command_UnNade2);
	RegConsoleCmd("+nade3", Command_Nade3);
	RegConsoleCmd("-nade3", Command_UnNade3);
	RegConsoleCmd("sm_nades_refill", Command_RefillNades , "Refill nades");
	
	//SetupPointHurt();
	
	//cvInfoMode = CreateConVar("sm_nades_info_mode", "0", "...");
	//times = 0.0;
	gHoldingArea[0]=-10000.0; gHoldingArea[1]=-10000.0; gHoldingArea[2]=-10000.0;
	for(new i=0;i<MAX_PLAYERS;i++)
	{
		Drugged[i] = false;
		for(new j=0;j<MAX_NADES;j++)
		{
			gNade[i][j] = 0;
		}
		/*for(new k=0;k<3;k++)
		{
			for(new l=0;l<5;l++)
			{
				Caltrop[i][k][l][0] = 0;
				Caltrop[i][k][l][1] = GetConVarInt(cvCaltropDamage);
			}
		}*/
	}
	
	HookEntityOutput("prop_dynamic", "OnAnimationBegun", EntityOutput_OnAnimationBegun);
	HookEntityOutput("item_ammopack_full", "OnPlayerTouch", EntityOutput_OnPlayerTouch);
	HookEntityOutput("item_ammopack_medium", "OnPlayerTouch", EntityOutput_OnPlayerTouch);
	HookEntityOutput("item_ammopack_small", "OnPlayerTouch", EntityOutput_OnPlayerTouch);
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
	
	// precache sounds
	PrecacheSound(SND_THROWNADE, true);
	PrecacheSound(SND_NADE_FRAG, true);
	PrecacheSound(SND_NADE_CONC, true);
	PrecacheSound(SND_NADE_NAPALM, true);
	PrecacheSound(SND_NADE_CONC_TIMER, true);
	PrecacheSound(SND_NADE_NAIL, true);
	PrecacheSound(SND_NADE_NAIL_EXPLODE, true);
	PrecacheSound(SND_NADE_NAIL_SHOOT1, true);
	PrecacheSound(SND_NADE_NAIL_SHOOT2, true);
	PrecacheSound(SND_NADE_NAIL_SHOOT3, true);
	PrecacheSound(SND_NADE_HALLUC, true);
	PrecacheSound(SND_NADE_EMP, true);
	PrecacheSound(SND_NADE_HALLUC_TIMER, true);
	PrecacheSound(SND_NADE_HEALTH, true);
	PrecacheSound(SND_NADE_SMOKE, true);
	PrecacheSound(SND_NADE_GAS, true);
	//PrecacheSound(SND_NADE_TRAP, true);
	
	
	PrecacheNadeModels();
	//SetupPointHurt();
	g_hTimer = CreateTimer(GetConVarInt(g_hInterval) * 0.1, Timer_ShowInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	gCanRun = false;
	gWaitOver = false;
	gMapStart = GetGameTime();
	
	MainEvents(INVALID_HANDLE, "map_start", true);
}

public OnClientPostAdminCheck(client)
{
	// kill hooks
	//gKilledBy[client]=0;
	//gKillTime[client] = 0.0;
	//gKillWeapon[client][0]='\0';
	gNadesUsed[client] = 0;
}

public OnClientDisconnect(client) 
{
	gRemaining[0][client] = 0;
	gRemaining[1][client] = 0;
	//showClientInfo[client] = 0;
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
			//serverMessage();
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
		new j;
		for(j=0;j<MAX_NADES;j++)
		{
			// nades
			gNade[i][j]=0;
		}
	}
	new k;
	for(k=1;k<=MaxClients;k++)
	{
		if(IsValidEntity(k) && i != 34)
		{
			if(IsClientAuthorized(k) && IsClientConnected(k))
			{
				if(IsPlayerAlive(k) && !IsFakeClient(k) && !IsClientObserver(k))
				{
					new class = int:TF2_GetPlayerClass(i);
					if(GetConVarInt(cvStartNades)==1)
					{
						gRemaining[0][k] = GetConVarInt(cvPrimary[class][0]);
						gRemaining[1][k] = GetConVarInt(cvSecondary[class][0]);
					}
					else if(GetConVarInt(cvStartNades)==2)
					{
						gRemaining[0][k] = GetConVarInt(cvPrimary[class][1]);
						gRemaining[1][k] = GetConVarInt(cvSecondary[class][1]);
					}
					else
					{
						gRemaining[0][k] = 0;
						gRemaining[1][k] = 0;
					}
					SetEntityRenderColor(k, 255, 255, 255, 255);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	gCanRun = false;
	/*new i;
	new j;
	for(i=0;i<MAX_PLAYERS+1;i++)
	{
		for(j=0;j<MAX_NADES;j++)
		{
			if(gNadeTimer2[i][j] != INVALID_HANDLE)
			{ KillTimer(gNadeTimer2[i][j]); gNadeTimer2[i][j] = INVALID_HANDLE; }
		}
	}*/
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	new class = int:TF2_GetPlayerClass(client);
	gHolding[client]=HOLD_NONE;
	
	if (!gCanRun)
	{
		if (GetGameTime() > (gMapStart + 60.0))
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
	
	SetupNade(class, GetClientTeam(client), 1);
	
	if(GetConVarInt(cvStartNades)==1)
	{
		gRemaining[0][client] = GetConVarInt(cvPrimary[class][0]);
		gRemaining[1][client] = GetConVarInt(cvSecondary[class][0]);
		gRemaining[2][client] = GetConVarInt(cvTertiary[class][0]);
	}
	else if(GetConVarInt(cvStartNades)==2)
	{
		gRemaining[0][client] = GetConVarInt(cvPrimary[class][1]);
		gRemaining[1][client] = GetConVarInt(cvSecondary[class][1]);
		gRemaining[2][client] = GetConVarInt(cvTertiary[class][1]);
	}
	else
	{
		gRemaining[0][client] = 0;
		gRemaining[1][client] = 0;
		gRemaining[2][client] = 0;
	}
	
	new Float:angles[3];
	GetClientEyeAngles(client, angles);
	angles[2] = 0.0;
	TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
	ClientCommand(client, "r_screenoverlay none\n");
	
	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new client, spec;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!(GetEventInt(event, "death_flags") & 32))
	{
		gRemaining[0][client] = 0;
		gRemaining[1][client] = 0;
		//new class = int:TF2_GetPlayerClass(client);
	}
	if(gHolding[client] != HOLD_NONE)
	{
		new Float:loc[3]; GetClientAbsOrigin(client, loc);
		//new class = int:TF2_GetPlayerClass(client);
		if(gHolding[client] == HOLD_PRIMARY){ spec = 0; }
		if(gHolding[client] == HOLD_SECONDARY){ spec = 1; }
		//if(gHolding[client] == HOLD_SPECIAL && class==MEDIC) { spec = 2; }
		ThrowNade(client, spec, false, tempId[client], true);
		gHolding[client] = HOLD_NONE;
	}
	
	//new weaponid = GetEventInt(event, "weaponid");
	
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
	
	/*if (gKilledBy[client]>0 && weaponid==0)
	{
		if ( (GetEngineTime()-gKillTime[client]) < 0.5)
		{
			SetEventInt(event, "attacker", gKilledBy[client]);
			SetEventInt(event, "weaponid", 100);
			SetEventString(event, "weapon", gKillWeapon[client]);
			SetEventString(event, "weapon_logclassname", gKillWeapon[client]);
		}
	}*/
	
	// kill hooks
	//gKilledBy[client]=0;
	//gKillTime[client] = 0.0;
	//gKillWeapon[client][0]='\0';
	Drugged[client] = false;
	
	SetEntityRenderColor(client, 255, 255, 255, 255);
	
	return Plugin_Continue;
}

public Action:ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new class = GetEventInt(event, "class");
	//gRemaining[0][client] = 0;
	//gRemaining[1][client] = 0;
	//gHolding[client] = HOLD_NONE;	
}

public EntityOutput_OnPlayerTouch(const String:output[], caller, activator, Float:delay)
{
	if(GetConVarInt(cvAmmoMode) == 1){
		if(IsValidEntity(caller))
		{	
			
			new String:modelname[128];
			GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(modelname, "models/items/ammopack_large.mdl"))
			{
				new Float:pos[3];
				GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
				FindPlayersInRange(pos, 96.0, 0, -1, false, -1);
				new j;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						GiveNades(j, 0, 2);
					}
				}
			}
			else if(StrEqual(modelname, "models/items/ammopack_medium.mdl"))
			{
				new Float:pos[3];
				GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
				FindPlayersInRange(pos, 96.0, 0, -1, false, -1);
				new j;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						GiveNades(j, 0, 1);
					}
				}
			}
			else if(StrEqual(modelname, "models/items/ammopack_small.mdl"))
			{
				new Float:pos[3];
				GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
				FindPlayersInRange(pos, 96.0, 0, -1, false, -1);
				new j;
				new maxplayers = GetMaxClients();
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						GiveNades(j, 0, 0);
					}
				}
			}
		}
	}
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
					GiveNades(j, 0 , 3);
				}
			}
		}
	}
}

public Action:Command_Nade1(client, args) 
{
	if (gHolding[client]>HOLD_NONE)
	{
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client) || IsFakeClient(client) || IsClientObserver(client))
	{
		return Plugin_Handled;
	}
	
	SetupHudMsg(3.0);
	if (!gCanRun)
	{
		ShowHudText(client, 1, "no nade throwing yet");
		return Plugin_Handled;
	}
	if(throwTime[client])
	{
		return Plugin_Handled;
	}
	// not while cloaked or taunting
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond&16 || cond&128)
	{
		return Plugin_Handled;
	}
	if(gNadesUsed[client] < 6){
		if(gRemaining[0][client]>0)
		{
			// setup nade if it doesn't exist
			new class = int:TF2_GetPlayerClass(client);
			SetupNade(class, GetClientTeam(client), 0);
			new NadeId = GetNade(client);
			tempId[client] = NadeId;
			//new number = FindNadeToUseBeforeGetNade(client);
			ThrowNade(client, 0, true, NadeId);

			if(GetConVarInt(cvRefill)==0)
			{
				gRemaining[0][client]-=1;
			}
			/*if(showClientInfo[client] == 0 || GetConVarInt(cvForcedShowInfo) == 0)
			{
				ShowHudText(client, 1, "%d normal nades, %d special nades", gRemaining[0][client], gRemaining[1][client]);
			}*/
			gNadesUsed[client]++;
			throwTime[client] = true;
			CreateTimer(GetConVarFloat(cvThrowDelay), throwTimer, client);
		}
		else
		{
			//if(showClientInfo[client] == 0 || GetConVarInt(cvForcedShowInfo)==0)
			//{
			//	ShowHudText(client, 1, "no nades remaining");
			//}
		}
	}
	else
	{
		ShowHudText(client, 1, "Stop spamming you fuckwit!!");
	}
	return Plugin_Handled;
}

public Action:Command_UnNade1(client, args)
{
	if (gHolding[client]!=HOLD_PRIMARY)
	{
		return Plugin_Handled;
	}
	ThrowNade(client, 0, false, tempId[client]);
	
	return Plugin_Handled;
}

public Action:Command_Nade2(client, args) 
{
	if (gHolding[client]>HOLD_NONE)
	{
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client) || IsFakeClient(client) || IsClientObserver(client))
	{
		return Plugin_Handled;
	}
	
	SetupHudMsg(3.0);
	if (!gCanRun)
	{
		ShowHudText(client, 1, "no nade throwing yet");
		return Plugin_Handled;
	}
	
	if(throwTime[client])
	{
		return Plugin_Handled;
	}
	// not while cloaked or taunting
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond&16 || cond&128)
	{
		return Plugin_Handled;
	}
	if(gNadesUsed[client] < 6){
		if(gRemaining[1][client]>0)
		{
			new class = int:TF2_GetPlayerClass(client);
			SetupNade(class, GetClientTeam(client), 1);
			new NadeId = GetNade(client);
			tempId[client] = NadeId;
			//new number = FindNadeToUseBeforeGetNade(client);
			ThrowNade(client, 1, true, NadeId);
			if(GetConVarInt(cvRefill)==0)
			{
				gRemaining[1][client]-=1;
			}
			//if(showClientInfo[client] == 0 || GetConVarInt(cvForcedShowInfo) == 0)
			//{
			//	ShowHudText(client, 1, "%d normal nades, %d special nades", gRemaining[0][client], gRemaining[1][client]);
			//}
			gNadesUsed[client]++;
			throwTime[client] = true;
			CreateTimer(0.5, throwTimer, client);
		}
		else
		{
			//if(showClientInfo[client] == 0 || GetConVarInt(cvForcedShowInfo) == 0)
			//{
			//	ShowHudText(client, 1, "no nades remaining");
			//}
		}
	}
	else
	{
		ShowHudText(client, 1, "Stop spamming you fuckwit!");
	}
	return Plugin_Handled;
}

public Action:Command_UnNade2(client, args)
{
	if (gHolding[client]!=HOLD_SECONDARY)
	{
		return Plugin_Handled;
	}
	ThrowNade(client, 1, false, tempId[client]);

	return Plugin_Handled;
}

public Action:Command_Nade3(client, args) 
{
	if (gHolding[client]>HOLD_NONE)
	{
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client) || IsFakeClient(client) || IsClientObserver(client))
	{
		return Plugin_Handled;
	}
	
	SetupHudMsg(3.0);
	if (!gCanRun)
	{
		ShowHudText(client, 1, "no nade throwing yet");
		return Plugin_Handled;
	}
	
	if(throwTime[client])
	{
		return Plugin_Handled;
	}
	// not while cloaked or taunting
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	if (cond&16 || cond&128)
	{
		return Plugin_Handled;
	}
	if(gNadesUsed[client] < 6){
		if(gRemaining[2][client]>0)
		{
			new class = int:TF2_GetPlayerClass(client);
			SetupNade(class, GetClientTeam(client), 2);
			new NadeId = GetNade(client);
			tempId[client] = NadeId;
			//new number = FindNadeToUseBeforeGetNade(client);
			ThrowNade(client, 2, true, NadeId);
			if(GetConVarInt(cvRefill)==0)
			{
				gRemaining[2][client]-=1;
			}
			//if(showClientInfo[client] == 0 || GetConVarInt(cvForcedShowInfo) == 0)
			//{
			//	ShowHudText(client, 1, "%d normal nades, %d special nades", gRemaining[0][client], gRemaining[1][client]);
			//}
			gNadesUsed[client]++;
			throwTime[client] = true;
			CreateTimer(0.5, throwTimer, client);
		}
		else
		{
			//if(showClientInfo[client] == 0 || GetConVarInt(cvForcedShowInfo) == 0)
			//{
			//	ShowHudText(client, 1, "no nades remaining");
			//}
		}
	}
	else
	{
		ShowHudText(client, 1, "Stop spamming you fuckwit!");
	}
	return Plugin_Handled;
}

public Action:Command_UnNade3(client, args)
{
	if (gHolding[client]!=HOLD_TERTIARY)
	{
		return Plugin_Handled;
	}
	ThrowNade(client, 2, false, tempId[client]);

	return Plugin_Handled;
}

public Action:Command_RefillNades(client, args)
{
	if(GetConVarFloat(cvRefill) == 1)
	{
		new class = int:TF2_GetPlayerClass(client);
		gRemaining[0][client] = GetConVarInt(cvPrimary[class][1]);
		gRemaining[1][client] = GetConVarInt(cvSecondary[class][1]);
		gRemaining[2][client] = GetConVarInt(cvTertiary[class][1]);
		SetupHudMsg(3.0);
		ShowHudText(client, 1, "%d normal nades, %d special nades", gRemaining[0][client], gRemaining[1][client]);
	}
	return Plugin_Handled;
}

GetNade(client)
{
	new Nade = CreateEntityByName("prop_physics");
	if (IsValidEntity(Nade))
	{
		SetEntPropEnt(Nade, Prop_Data, "m_hOwnerEntity", client);
		SetEntityModel(Nade, gnModel);
		//SetEntityMoveType(Nade, MOVETYPE_VPHYSICS);
		SetEntityMoveType(Nade, MOVETYPE_FLYGRAVITY);
		SetEntProp(Nade, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(Nade, Prop_Data, "m_usSolidFlags", 16);

		DispatchSpawn(Nade);
		Format(tName, sizeof(tName), "tf2nade%d", client);
		DispatchKeyValue(Nade, "targetname", tName);
		AcceptEntityInput(Nade, "DisableDamageForces");
		//SetEntPropString(gNade[client][i], Prop_Data, "m_iName", "tf2nade%d", gNade[client][i]);
		TeleportEntity(Nade, gHoldingArea, NULL_VECTOR, NULL_VECTOR);
	}
	return Nade;
}

ThrowNade(client, special=1, bool:Setup, NadeId, bool:death=false)
{
	new class = int:TF2_GetPlayerClass(client);
	//PrintToChat(client, "thrownade and NadeId = %i", NadeId);
	SetupNade(class, GetClientTeam(client), special);
	if (Setup)
	{
		// save priming status
		if (special==1)
		{
			gHolding[client]=HOLD_SECONDARY;
		}
		else if(special==0)
		{
			gHolding[client]=HOLD_PRIMARY;
		}
		else if(special==2)
		{
			gHolding[client]=HOLD_TERTIARY;
		}
		
		new SMode = GetConVarInt(cvSoundMode);
		// check that nade still exists in world
		if (IsValidEdict(NadeId))
		{
			GetEntPropString(NadeId, Prop_Data, "m_iName", tName, sizeof(tName));
			if (strncmp(tName,"tf2nade",7)!=0)
			{
				LogError("tf2nade: player's nade name not found");
				return; 
			}
			times[NadeId] = 0.0;
			
			new Handle:beeppack[GetConVarInt(cvNadeDelay)-1];
			for(new i=0;i<3;i++)
			{
				if(nr==10){ nr=0; }
				new String:TempString[32];
				new Float:iFloat;
				IntToString(i , TempString, 31);
				iFloat = StringToFloat(TempString);
				SoundTimer[client][nr] = CreateDataTimer(iFloat+1.0, soundTimer, beeppack[i], TIMER_HNDL_CLOSE);
				WritePackCell(beeppack[i], NadeId);
				WritePackCell(beeppack[i], client);
				WritePackCell(beeppack[i], special);
				WritePackCell(beeppack[i], class);
				WritePackCell(beeppack[i], SMode);
				nr++;
			}
			
			
			new Handle:pack;
			//gNadeTimer[client][jN] = 
			if(nr2==6){ nr2=0; }
			NadeTimer[client][nr2] = CreateDataTimer(GetConVarFloat(cvNadeDelay), NadeExplode, pack, TIMER_HNDL_CLOSE);
			WritePackCell(pack, NadeId);
			WritePackCell(pack, client);
			WritePackCell(pack, GetClientTeam(client));
			WritePackCell(pack, class);
			WritePackCell(pack, special);
			nr2++;
		}
		else
		{
			LogError("tf2nade: player's nade not found");
			return;
		}
		EmitClassNadeBeep(client, class, SMode, special);
	}
	
	// setup nade variables based on player class
	
	//SetupNade(class, GetClientTeam(client), special);
	
	if (!Setup)
	{
		if(IsValidEntity(NadeId))
		{
			// reset priming status
			gHolding[client] = HOLD_NONE;
			gThrown[NadeId] = true;
			
			// get position and angles
			new Float:startpt[3];
			GetClientEyePosition(client, startpt);
			new Float:angle[3];
			new Float:speed[3];
			new Float:playerspeed[3];
			
			SetEntityModel(NadeId, gnModel);
			Format(gnSkin, sizeof(gnSkin), "%d", GetClientTeam(client)-2);
			DispatchKeyValue(NadeId, "skin", gnSkin);
			angle[0] = GetRandomFloat(-180.0, 180.0);
			angle[1] = GetRandomFloat(-180.0, 180.0);
			angle[2] = GetRandomFloat(-180.0, 180.0);
			
			if(!death)
			{
				GetClientEyeAngles(client, angle);
				GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
				speed[2]+=0.2;
				speed[0]*=gnSpeed; speed[1]*=gnSpeed; speed[2]*=gnSpeed;
				if(GetConVarInt(cvNadesThrowPhysics)>0)
				{
					GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
					if(GetConVarInt(cvNadesThrowPhysics)==1)
					{
						for(new i=0;i<2;i++)
						{
							if(playerspeed[i] >= 0.0 && speed[i] < 0.0)
							{
								playerspeed[i] = 0.0;
							}
							else if(playerspeed[i] < 0.0 && speed[i] >= 0.0)
							{
								playerspeed[i] = 0.0;
							}
						}
						if(playerspeed[2] < 0.0 )
						{
							playerspeed[2] = 0.0;
						}
					}
					AddVectors(speed, playerspeed, speed);
				}
				TeleportEntity(NadeId, startpt, angle, speed);
			}
			else
			{
				new Float:altstartpt[3];
				GetClientAbsOrigin(client, altstartpt);
				if(GetConVarInt(cvNadesHHMode)>0)
				{
					GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
					ScaleVector(playerspeed, GetConVarFloat(cvNadesHHDisDec));
					SubtractVectors(altstartpt, playerspeed, altstartpt);
				}
				altstartpt[2] += GetConVarFloat(cvNadeHHHeight);
				TeleportEntity(NadeId, altstartpt, angle, NULL_VECTOR);
			}
			if(GetConVarFloat(cvDifGrav)!=1.0)
			{
				SetEntityGravity(NadeId, GetConVarFloat(cvDifGrav));
			}
			
			if (strlen(gnParticle)>0)
			{
				AttachParticle(NadeId, gnParticle, gnDelay);
			}
			
			if(GetConVarInt(cvNadeTrail)==1)
			{
				new color[4];
				if(GetClientTeam(client)==2) //red
				{
					if(special)
					{
						color = { 255, 255, 50, 255};
					}
					else
					{
						color = { 255, 50, 50, 255 };
					}
				}
				else if(GetClientTeam(client)==3)
				{
					if(special)
					{
						color = { 50, 255, 255, 255};
					}
					else
					{
						color = { 50, 50, 255, 255 };
					}
				}
				else
				{
					color = { 50, 255, 50, 255 };
				}
				ShowTrail(NadeId, color);
			}
			EmitSoundToAll(SND_THROWNADE, client);
		}
	}
}

public Action:throwTimer(Handle:timer, any:client)
{
	throwTime[client] = false;
}

public Action:ThrowDelay(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new spec = ReadPackCell(pack);
	new set = ReadPackCell(pack);
	new temp = ReadPackCell(pack);
	new dea = ReadPackCell(pack);
	new bool:death, bool:setup;
	if(set==0){ setup = false; } else if(set==1){ setup = true; }
	if(dea==0){ death = false; } else if(dea==1){ death = true; }
	ThrowNade(client, spec, setup, temp, death);
}

public Action:soundTimer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new NadeId = ReadPackCell(pack);
	new client = ReadPackCell(pack);
	new special = ReadPackCell(pack);
	new class = ReadPackCell(pack);
	new mode = ReadPackCell(pack);
	//playSound(j, client, class, special, SMode);
	if(IsValidEntity(NadeId) && IsValidEntity(client))
	{
		if (gHolding[client]>HOLD_NONE && gThrown[NadeId]==false)
		{
			EmitClassNadeBeep(client, class, mode, special);
		}
		else
		{
			EmitClassNadeBeep(client, class, mode, special, NadeId);
		}
	}
	/*times[NadeId]+=1.0;
	if(times[NadeId]<gnDelay)
	{
		new Handle:beeppack2;
		if(nr3==15){ nr3=0;}
		SoundTimer2[client][nr3] = CreateDataTimer(1.0, soundTimer, beeppack2, TIMER_HNDL_CLOSE);
		WritePackCell(beeppack2, NadeId);
		WritePackCell(beeppack2, client);
		WritePackCell(beeppack2, special);
		WritePackCell(beeppack2, class);
		WritePackCell(beeppack2, mode);
		nr3++;
	}*/
	return Plugin_Continue;
}

public Action:NadeExplode(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new j = ReadPackCell(pack);
	new client = ReadPackCell(pack);
	new team = ReadPackCell(pack);
	new class = ReadPackCell(pack);
	new special = ReadPackCell(pack);
	
	if (IsValidEdict(j))
	{
		GetEntPropString(j, Prop_Data, "m_iName", tName, sizeof(tName));
		if (strncmp(tName,"tf2nade",7)==0)
		{
			gNadesUsed[client]--;
			times[j] = 0.0;
			ExplodeNade(client, team, class, special, j);
		} 
	}
}

ExplodeNade(client, team, class, special, NadeId)
{
 
	new bool:HandHeld = false;
	if (gHolding[client]>HOLD_NONE && gThrown[NadeId]==false)
	{
		HandHeld = true; 
		ThrowNade(client, gHolding[client]-1, false, NadeId, true);
	}
	gThrown[NadeId] = false; 

	new Float:radius;
	new Float:center[3];
	GetEntPropVector(NadeId, Prop_Send, "m_vecOrigin", center);
	new oteam;
	//if (GetClientTeam(client)==3) {oteam=2;} else {oteam=3;}
	if(team==3){ oteam=2; } else { oteam=3; }
	new maxplayers = GetMaxClients();
	
	if (special==0)
	{
		radius = GetConVarFloat(cvPrimary[class][3]);
		switch (class)
		{
			case SCOUT:
			{
				/*ShowParticle(center, "impact_generic_smoke", 2.0);
				SetupConcBeams(center, radius);
				EmitSoundToAll(SND_NADE_CONC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				if(GetConVarInt(cvConcIgnore) == 1) { FindPlayersInRange(center, radius, oteam, client, false, -1); }
				else { FindPlayersInRange(center, radius, oteam, client, true, NadeId); }
				for (new j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						ConcPlayer(j, center, radius, client, HandHeld);
					}
				}*/
				
				new Float:delay = GetConVarFloat(cvSmokeDelay);

				TE_SetupSparks(center, NULL_VECTOR, 2, 1);
				TE_SendToAll();

				//PrepareModel(MDL_SMOKE_SPRITE, gSmokeSprite);
				TE_SetupSmoke(center,gSmokeSprite,40.0,1);
				TE_SendToAll();

				//PrepareSound(SND_NADE_SMOKE);
				EmitSoundToAll(SND_NADE_SMOKE, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
							   SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				
				// Create the Smoke Cloud
				new String:originData[64];
				//center[2] -= 36.0;
				Format(originData, sizeof(originData), "%f %f %f", center[0], center[1], center[2]);

				new String:size[5];
				new String:name[128];
				Format(size, sizeof(size), "%f", radius);
				Format(name, sizeof(name), "Smoke%i", client);
				new cloud = CreateEntityByName("env_smokestack");
				DispatchKeyValue(cloud,"targetname", name);
				DispatchKeyValue(cloud,"Origin", originData);
				DispatchKeyValue(cloud,"BaseSpread", "100");
				DispatchKeyValue(cloud,"SpreadSpeed", "10");
				DispatchKeyValue(cloud,"Speed", "80");
				DispatchKeyValue(cloud,"StartSize", "100");
				DispatchKeyValue(cloud,"EndSize", size);
				DispatchKeyValue(cloud,"Rate", "25");
				DispatchKeyValue(cloud,"JetLength", "400");
				DispatchKeyValue(cloud,"Twist", "4");
				DispatchKeyValue(cloud,"RenderColor", "8 8 8");
				DispatchKeyValue(cloud,"RenderAmt", "250");
				DispatchKeyValue(cloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
				DispatchSpawn(cloud);
				AcceptEntityInput(cloud, "TurnOn");

				CreateTimer(delay, RemoveSmoke, cloud);
			}
			case SNIPER, SOLDIER, DEMO, MEDIC, HEAVY, PYRO, SPY, ENGIE:
			{
				// effects
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);
				EmitSoundToAll(SND_NADE_FRAG, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				// player damage
				new damage = GetConVarInt(cvPrimary[SOLDIER][2]);
				FindPlayersInRange(center, radius, oteam, client, true, NadeId);
				//new m = GetConVarInt(cvNadesHHMode);
				for (new j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						new tdamage = CalculateDynamicDamage(damage, j, center, radius);
						if(HandHeld && j==client)
						{
						}
						new String:tempString[32]; GetConVarString(cvNadeIcon, tempString, sizeof(tempString));
						DealDamage(j, tdamage, center, client, DMG_CRUSH, tempString);
					}
				}
				DamageBuildings(client, center, radius, damage, NadeId, true);
			}
		}
	}
	else if(special==1)
	{
		radius = GetConVarFloat(cvSecondary[class][3]);
		switch (class)
		{
			case SCOUT:
			{
				ShowParticle(center, "impact_generic_smoke", 2.0);
				SetupConcBeams(center, radius);
				EmitSoundToAll(SND_NADE_CONC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				if(GetConVarInt(cvConcIgnore) == 1) { FindPlayersInRange(center, radius, oteam, client, false, -1); }
				else { FindPlayersInRange(center, radius, oteam, client, true, NadeId); }
				new damage = 1;
				for (new j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						ConcPlayer(j, center, radius, client, HandHeld);
						new String:tempString[32]; GetConVarString(cvNadeIcon, tempString, sizeof(tempString));
						DealDamage(j, damage, center, client, DMG_CRUSH, tempString);
					}
				}
			}
			case SNIPER:
			{
			}
			case SOLDIER:
			{
				SetupNade(SOLDIER, GetClientTeam(client), 1);
				ShowParticle(center, "Explosions_MA_Dustup_2", 2.0);
				center[2]+=32.0;
				new Float:angles[3] = {0.0,0.0,0.0};
				new gNadeTemp;
				gNadeTemp = CreateEntityByName("prop_dynamic_override");
				if (IsValidEntity(gNadeTemp))
				{
					SetEntPropEnt(gNadeTemp, Prop_Data, "m_hOwnerEntity", client);
					SetEntityModel(gNadeTemp,gnModel);
					SetEntProp(gNadeTemp, Prop_Data, "m_CollisionGroup", 1);
					SetEntProp(gNadeTemp, Prop_Data, "m_usSolidFlags", 16);
					Format(gnSkin, sizeof(gnSkin), "%d", GetClientTeam(client)-2);
					DispatchKeyValue(gNadeTemp, "skin", gnSkin);
					Format(tName, sizeof(tName), "tf2nailnade%d", gNadeTemp);
					DispatchKeyValue(gNadeTemp, "targetname", tName);
					DispatchSpawn(gNadeTemp);
					TeleportEntity(gNadeTemp, center, angles, NULL_VECTOR);
					SetVariantString("release");
					AcceptEntityInput(gNadeTemp, "SetAnimation");
					EmitSoundToAll(SND_NADE_NAIL, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
					if(nailnr == 8)
					{ 
						nailnr = 0; 
					} 
					else
					{
						nailnr++;
					}
					new Handle:pack;
					new Handle:pack2;
					nailTimer[client][nailnr] = INVALID_HANDLE;
					nailTimer[client][nailnr] = CreateDataTimer(0.25, SoldierNadeThink, pack2, TIMER_REPEAT);
					WritePackCell(pack2, client);
					WritePackCell(pack2, gNadeTemp);
					
					CreateDataTimer(5.0, SoldierNadeFinish, pack); 
					WritePackCell(pack, client);
					WritePackCell(pack, nailnr);
					WritePackCell(pack, gNadeTemp);
					
				}
			}
			case DEMO:
			{
				new damage = GetConVarInt(cvSecondary[class][2]);
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);
				EmitSoundToAll(SND_NADE_MIRV1, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				FindPlayersInRange(center, radius, oteam, client, true, NadeId);

				for (new j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						new tdamage = CalculateDynamicDamage(damage, j, center, radius);
						if(HandHeld && j==client)
						{
						}
						new String:tempString[32]; GetConVarString(cvNadeIcon, tempString, sizeof(tempString));
						DealDamage(j, tdamage, center, client, DMG_CRUSH, tempString);
						//HurtPlayer(j, client, damage, "tf2nade_mirv", true, center, 5.0);
					}
				}
				DamageBuildings(client, center, radius, damage, NadeId, true);
				
				CreateSecondaryMirvs(client, center, team);
			}
			case MEDIC:
			{
				ShowParticle(center, "impact_generic_smoke", 2.0);
				SetupConcBeams(center, radius);
				EmitSoundToAll(SND_NADE_CONC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				if(GetConVarInt(cvConcIgnore) == 1) { FindPlayersInRange(center, radius, oteam, client, false, -1); }
				else { FindPlayersInRange(center, radius, oteam, client, true, NadeId); }
				new damage = 1;
				for (new j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						ConcPlayer(j, center, radius, client, HandHeld);
						new String:tempString[32]; GetConVarString(cvNadeIcon, tempString, sizeof(tempString));
						DealDamage(j, damage, center, client, DMG_CRUSH, tempString);
					}
				}
			}
			case HEAVY:
			{
				new damage = GetConVarInt(cvSecondary[class][2]);
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);
				EmitSoundToAll(SND_NADE_MIRV1, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				FindPlayersInRange(center, radius, oteam, client, true, NadeId);

				for (new j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						new tdamage = CalculateDynamicDamage(damage, j, center, radius);
						if(HandHeld && j==client)
						{
						}
						new String:tempString[32]; GetConVarString(cvNadeIcon, tempString, sizeof(tempString));
						DealDamage(j, tdamage, center, client, DMG_CRUSH, tempString);
						//HurtPlayer(j, client, damage, "tf2nade_mirv", true, center, 5.0);
					}
				}
				DamageBuildings(client, center, radius, damage, NadeId, true);
				
				CreateSecondaryMirvs(client, center, team);
			}
			case PYRO:
			{
				new damage = GetConVarInt(cvSecondary[class][2]);
				ShowParticle(center, "ExplosionCore_MidAir", 2.0);
				TE_SetupExplosion(center, gNapalmSprite, 2.0, 1, 4, RoundToCeil(radius), 0);
				TE_SendToAll();
				EmitSoundToAll(SND_NADE_NAPALM, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				FindPlayersInRange(center, radius, oteam, client, true, NadeId);
				
				for (new j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						new tdamage = CalculateDynamicDamage(damage, j, center, radius);
						if(HandHeld && j==client)
						{
						}
						new String:tempString[32]; GetConVarString(cvNadeIcon, tempString, sizeof(tempString));
						DealDamage(j, tdamage, center, client, DMG_CRUSH, tempString);
						//HurtPlayer(j, client, damage, "tf2nade_napalm", true, center, 3.0);
						if(j != client)
						{
							TF2_IgnitePlayer(j, client);
						}
					}
				}
				DamageBuildings(client, center, radius, damage, NadeId, true);
			}
			case SPY:
			{
				new damage = GetConVarInt(cvSecondary[class][2]);
				ShowParticle(center, "ExplosionCore_sapperdestroyed", 2.0);
				EmitSoundToAll(SND_NADE_HALLUC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

				FindPlayersInRange(center, radius, oteam, client, true, NadeId);
				new Float:hDelay = GetConVarFloat(cvSecondary[class][2]);
				new Float:origin[3];
				new Float:distance;
				new Float:dynamic_time;
				for (new j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{	
						if(!Drugged[j])
						{
							new Float:angles[3], rand1;
							GetClientEyeAngles(j, angles);
							Drugged[j] = true;
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
							//ClientCommand(j, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
							//new String:tempString2[32]; GetConVarString(cvHallucVMT, tempString2, sizeof(tempString2));
							//ClientCommand(j, tempString2);
							GetClientAbsOrigin(j, origin);
							SubtractVectors(origin, center, origin);
							distance = GetVectorLength(origin);
							if (distance<0.01) { distance = 0.01; }
							dynamic_time = FloatSub(hDelay, (FloatMul(FloatMul(hDelay, 0.60), FloatDiv(distance, radius))));
							CreateTimer(dynamic_time, ResetPlayerView, j);
							
							//DrugTimer[j] = CreateTimer(2.0, Timer_Drug, j, TIMER_REPEAT);
							new Handle:pack;
							new color[4];
							CreateDataTimer(1.0, Timer_Drug, pack);
							WritePackCell(pack, j);
							for(new i=0;i<3;i++)
							{
								color[i] = GetRandomInt(25,255);
								WritePackCell(pack, color[i]);
							}
							color[3] = GetRandomInt(25, 100);
							WritePackCell(pack, color[3]);
						}
						damage = CalculateDynamicDamage(damage, j, center, radius);
						new String:tempString[32]; GetConVarString(cvNadeIcon, tempString, sizeof(tempString));
						DealDamage(j, damage, center, client, DMG_CRUSH, tempString);
						//HurtPlayer(j, client, damage, "tf2nade_halluc", false, NULL_VECTOR, 4.0, 1); 
					}
				}
			}
			case ENGIE:
			{
				ShowParticle(center, "ExplosionCore_sapperdestroyed", 2.0);
				EmitSoundToAll(SND_NADE_EMP, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
				if(GetConVarInt(cvEmpIgnore) == 1) { FindPlayersInRange(center, radius, oteam, client, false, -1);}
				else { FindPlayersInRange(center, radius, oteam, client, true, NadeId); }
				
				new beamcolor[4];
				if (team==2) 
				{ beamcolor[0]=255;beamcolor[1]=0;beamcolor[2]=0;beamcolor[3]=255; }
				else 
				{ beamcolor[0]=0;beamcolor[1]=0;beamcolor[2]=255;beamcolor[3]=255; }
				
				TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite, 1, 1, 0.5, 4.0, 10.0, beamcolor, 100, 0);
				TE_SendToAll();
				TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite, 1, 1, 0.75, 4.0, 10.0, beamcolor, 100, 0);
				TE_SendToAll();
				TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite, 1, 1, 1.0, 4.0, 10.0, beamcolor, 100, 0);
				TE_SendToAll();
				
				for (new j=1;j<=maxplayers;j++)
				{
					if(j!=client)
					{
						if(PlayersInRange[j]>0.0)
						{
							EmpPlayer(j, center, client);
						}
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
						new String:modelname[128];
						GetEntPropString(i, Prop_Data, "m_ModelName", modelname, 128);
						if (StrContains(tName, "tf_projectile")>-1) // || StrContains(tName, "tf2nade")>-1)
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
		}
	}
	else if(special==2)
	{
		radius = GetConVarFloat(cvTertiary[class][3]);
		switch (class)
		{
			case MEDIC:
			{
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
				GetEntPropVector(NadeId, Prop_Send, "m_vecOrigin", beamcenter);
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.25,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.50,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.75,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
				TE_SendToAll(0.0);
				EmitSoundToAll(SND_NADE_HEALTH, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, beamcenter, NULL_VECTOR, false, 0.0);
				FindPlayersInRange(beamcenter, radius, team, client, true, NadeId);
				new playersOnRegen[32];
				new tNr = 0;
				for (new j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						playersOnRegen[tNr] = j;
						tNr++;
						
						ShowHealthParticle(j);
						//health = GetEntProp(j, Prop_Data, "m_iMaxHealth");
						//if (GetClientHealth(j)<health)
						//{
						//	SetEntityHealth(j, health);
						//}
					}
				}
				new Handle:pack;
				CreateDataTimer(1.0/24.0, HealthExplode, pack);
				WritePackCell(pack, tNr);
				WritePackCell(pack, GetConVarInt(cvTertiary[class][2]));
				for(new k=0;k<tNr;k++)
				{
					WritePackCell(pack, playersOnRegen[k]);
				}
			}
		}
	}
	TeleportEntity(NadeId, gHoldingArea, NULL_VECTOR, NULL_VECTOR);
	RemoveEdict(NadeId);
	//gNade[client][jTemp] = 0;
}

SetupNade(class, team, special)
{
	// setup frag nade if not special
	new Float:tSpeed = GetConVarFloat(cvNadesThrowSpeed);
	new Float:tDelay = GetConVarFloat(cvNadeDelay);
	if (special==0)
	{
		switch (class)
		{
			case SCOUT:
			{
				/*strcopy(gnModel, sizeof(gnModel), MDL_CONC);
				gnSpeed = tSpeed-200.0;
				gnDelay = tDelay;
				strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");*/
				//PrepareModel(MDL_SMOKE, g_SmokeModelIndex);
				strcopy(gnModel, sizeof(gnModel), MDL_SMOKE);
				gnSpeed = tSpeed;
				gnDelay = tDelay;
				strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
			}
			case SNIPER,SOLDIER,DEMO,MEDIC,HEAVY,PYRO,SPY,ENGIE:
			{
				strcopy(gnModel, sizeof(gnModel), MDL_FRAG);
				gnSpeed = tSpeed;
				gnDelay = tDelay;
				gnParticle[0]='\0';
			}
			default:
			{
				strcopy(gnModel, sizeof(gnModel), MDL_FRAG);
				gnSpeed = tSpeed;
				gnDelay = tDelay;
				gnParticle[0]='\0';
			}
		}
	}
	else if(special==1)
	{
		// setup special nade if not frag
		switch (class)
		{
			case SCOUT:
			{
				strcopy(gnModel, sizeof(gnModel), MDL_CONC);
				gnSpeed = tSpeed-200.0;
				gnDelay = tDelay;
				strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
			}
			case SNIPER:
			{
				//PrepareModel(MDL_TRAP, g_TrapModelIndex);
				//strcopy(gnModel, sizeof(gnModel), MDL_TRAP);
				//PrepareModel(MDL_HALLUC, g_HallucModelIndex);
				//strcopy(gnModel, sizeof(gnModel), MDL_HALLUC);
				//gnSpeed = tSpeed;
				//gnDelay = tDelay;
				//gnParticle[0]='\0';
			}
			case SOLDIER:
			{
				strcopy(gnModel, sizeof(gnModel), MDL_NAIL);
				gnSpeed = tSpeed;
				gnDelay = tDelay;
				gnParticle[0]='\0';
			}
			case DEMO:
			{
				strcopy(gnModel, sizeof(gnModel), MDL_MIRV1);
				gnSpeed = tSpeed;
				gnDelay = tDelay;
				gnParticle[0]='\0';
			}
			case MEDIC:
			{
				strcopy(gnModel, sizeof(gnModel), MDL_CONC);
				gnSpeed = tSpeed-200.0;
				gnDelay = tDelay;
				strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
			}
			case HEAVY:
			{
				strcopy(gnModel, sizeof(gnModel), MDL_MIRV1);
				gnSpeed = tSpeed;
				gnDelay = tDelay;
				gnParticle[0]='\0';
			}
			case PYRO:
			{
				strcopy(gnModel, sizeof(gnModel), MDL_NAPALM);
				gnSpeed = tSpeed;
				gnDelay = tDelay;
				gnParticle[0]='\0';
			}
			case SPY:
			{
				strcopy(gnModel, sizeof(gnModel), MDL_HALLUC);
				gnSpeed = tSpeed;
				gnDelay = tDelay;
				strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
			}
			case ENGIE:
			{
				strcopy(gnModel, sizeof(gnModel), MDL_EMP);
				gnSpeed = tSpeed;
				gnDelay = tDelay;
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
				gnSpeed = tSpeed;
				gnDelay = tDelay;
				gnParticle[0]='\0';
			}
		}
	}
	else if(special==2)
	{
		switch (class)
		{
			case MEDIC:
			{
				strcopy(gnModel, sizeof(gnModel), MDL_HEALTH);
				gnSpeed = tSpeed;
				gnDelay = tDelay;
				if (team==2)
				{
					strcopy(gnParticle, sizeof(gnParticle), "player_recent_teleport_red");
				}
				else
				{
					strcopy(gnParticle, sizeof(gnParticle), "player_recent_teleport_blue");
				}
			}
		}
	}
	//return;
}

public Action:SoldierNadeThink(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new gNadeTemp = ReadPackCell(pack);

	if (IsValidEntity(gNadeTemp))
	{
		// effects idea 1
		
		new Float:center[3];
		new Float:radius; radius = GetConVarFloat(cvNadesNailRadiusNail);
		GetEntPropVector(gNadeTemp, Prop_Send, "m_vecOrigin", center);
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
		FindPlayersInRange(center, radius, oteam, client, true, gNadeTemp);
		new j;
		new maxplayers = GetMaxClients();
		
		for (j=1;j<=maxplayers;j++)
		{
			if(PlayersInRange[j]>0.0)
			{
				new damage = CalculateDynamicDamage(GetConVarInt(cvNadesNailDamageNail), j, center, radius);
				new String:tempString[32]; GetConVarString(cvNadeIcon, tempString, sizeof(tempString));
				DealDamage(j, damage, center, client, DMG_CRUSH, tempString);
				//HurtPlayer(j, client, GetConVarInt(cvNadesNailDamageNail), "tf2nade_nail", false, center, 4.0, 1);
			}
		}
		DamageBuildings(client, center, radius, GetConVarInt(cvNadesNailDamageNail), gNadeTemp, true);
	}
	CloseHandle(pack);
	return Plugin_Continue;
}

public Action:SoldierNadeFinish(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new jTemp = ReadPackCell(pack);
	new gNadeTemp = ReadPackCell(pack);
	
	
	KillTimer(nailTimer[client][jTemp]);
	nailTimer[client][jTemp] = INVALID_HANDLE;
	//StopSound(gNadeTemp, SNDCHAN_WEAPON, SND_NADE_NAIL);
	
	if (IsValidEntity(gNadeTemp))
	{
		new damage = GetConVarInt(cvSecondary[SOLDIER][2]);
		GetEntPropString(gNadeTemp, Prop_Data, "m_iName", tName, sizeof(tName));
		if (strncmp(tName,"tf2nailnade",11)==0)
		{
			// effects
			new Float:center[3];
			new Float:radius = GetConVarFloat(cvSecondary[SOLDIER][3]);
			GetEntPropVector(gNadeTemp, Prop_Send, "m_vecOrigin", center);
			ShowParticle(center, "ExplosionCore_MidAir", 2.0);
			EmitSoundToAll(SND_NADE_NAIL_EXPLODE, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
			// player damage
			new oteam;
			if (GetClientTeam(client)==3) {oteam=2;} else {oteam=3;}
			FindPlayersInRange(center, radius, oteam, client, true, gNadeTemp);
			new maxplayers = GetMaxClients();
			
			for (new j=1;j<=maxplayers;j++)
			{
				if(PlayersInRange[j]>0.0)
				{
					new tdamage = CalculateDynamicDamage(damage, j, center, radius);
					new String:tempString[32]; GetConVarString(cvNadeIcon, tempString, sizeof(tempString));
					DealDamage(j, tdamage, center, client, DMG_CRUSH, tempString);
					//HurtPlayer(j, client, damage, "tf2nade_nail", true, center);
				}
			}
			DamageBuildings(client, center, radius, damage, gNadeTemp, true);
			RemoveEdict(gNadeTemp);
		}
	}
	return Plugin_Stop;
}

public Action:MirvExplode2(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new team = ReadPackCell(pack);
	new min = ReadPackCell(pack);
	new ent[MIRV_PARTS-min];
	new k;
	for (k=0;k<MIRV_PARTS-min;k++)
	{
		ent[k] = ReadPackCell(pack);
	}
	//gNadeTimer3[client][jTemp] = INVALID_HANDLE;
	new Float:radius = GetConVarFloat(cvSecondary[DEMO][3]);
	new Float:center[3];
	if(IsValidEntity(ent[0]))
	{
		GetEntPropString(ent[0], Prop_Data, "m_iName", tName, sizeof(tName));
		if (strncmp(tName,"tf2mirv",7)==0)
		{
			new damage = GetConVarInt(cvSecondary[DEMO][2]);
			GetEntPropVector(ent[0], Prop_Send, "m_vecOrigin", center);
			ShowParticle(center, "ExplosionCore_MidAir", 2.0);
			EmitSoundToAll(SND_NADE_MIRV2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
			new oteam;
			if (team==3) {oteam=2;} else {oteam=3;}
			FindPlayersInRange(center, radius, oteam, client, true, ent[0]);
			new maxplayers = GetMaxClients();
			for (new j=1;j<=maxplayers;j++)
			{
				if(PlayersInRange[j]>0.0)
				{
					new tdamage = CalculateDynamicDamage(damage, j, center, radius);
					new String:tempString[32]; GetConVarString(cvNadeIcon, tempString, sizeof(tempString));
					DealDamage(j, tdamage, center, client, DMG_CRUSH, tempString);
					//HurtPlayer(j, client, damage, "tf2nade_mirv", true, center);
				}
			}
			DamageBuildings(client, center, radius, damage, ent[0], true);
			RemoveEdict(ent[0]);
			
			if(min < MIRV_PARTS)
			{		
				CreateDataTimer(0.01, MirvExplode2, pack);
				WritePackCell(pack, client);
				WritePackCell(pack, team);
				WritePackCell(pack, min+1);
				for (k=0;k<MIRV_PARTS-(min+1);k++)
				{
					WritePackCell(pack, ent[k+1]);
				}
			}
			else
			{
				CloseHandle(pack);
				return Plugin_Stop;
			}
		}
	}
	CloseHandle(pack);
	return Plugin_Continue;
}

public Action:RemoveSmoke(Handle:timer, any:entity)
{
    if (entity > 0 && IsValidEntity(entity))
    {
        AcceptEntityInput(entity, "TurnOff");
        CreateTimer(5.0, KillSmoke, entity);
    }
}

public Action:KillSmoke(Handle:timer, any:entity)
{
    if (entity > 0 && IsValidEntity(entity))
        AcceptEntityInput(entity, "Kill");
}

/*
public Action:RemoveGas(Handle:timer, Handle:entitypack)
{
    ResetPack(entitypack);

    new gascloud = ReadPackCell(entitypack);
    if (gascloud > 0 && IsValidEntity(gascloud))
        AcceptEntityInput(gascloud, "TurnOff");

    new pointHurt = ReadPackCell(entitypack);
    if (pointHurt > 0 && IsValidEntity(pointHurt))
        AcceptEntityInput(pointHurt, "TurnOff");
}

public Action:KillGas(Handle:timer, Handle:entitypack)
{
    ResetPack(entitypack);

    new gascloud = ReadPackCell(entitypack);
    if (gascloud > 0 && IsValidEntity(gascloud))
        AcceptEntityInput(gascloud, "Kill");

    new pointHurt = ReadPackCell(entitypack);
    if (pointHurt > 0 && IsValidEntity(pointHurt))
        AcceptEntityInput(pointHurt, "Kill");

    CloseHandle(entitypack);
}
*/

public Action:ResetPlayerMotion(Handle:timer, any:client)
{
	SetEntityMoveType(client,MOVETYPE_WALK); // Unfreeze client
}

public Action:ResetPlayerView(Handle:timer, any:client)
{
	Drugged[client] = false;
	
	new Float:angles[3];
	GetClientEyeAngles(client, angles);
	angles[2] = 0.0;
	TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
	ClientCommand(client, "r_screenoverlay none\n");
	
	PerformFade(client, 5, {0, 0, 0, 0});
}

public Action:Timer_Drug(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new color[4];
	for(new i=0;i<4;i++)
	{
		color[i] = ReadPackCell(pack);
	}
	
	if (!IsClientInGame(client))
	{
		Drugged[client] = false;

		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client))
	{
		CreateTimer(0.01, ResetPlayerView, client);
		return Plugin_Handled;
	}
	if(!Drugged[client])
	{
		CreateTimer(0.01, ResetPlayerView, client);
		return Plugin_Handled;
	}
	
	for(new i=0;i<4;i++)
	{
		color[i] += GetRandomInt(-25,25);
	}
	for(new i=0;i<3;i++)
	{
		if(color[i] > 255){ color[i] -= 255; }
		else if(color[i] < 25){ color[i] += 230; }
	}
	if(color[3] > 100){ color[3] -= 100; }
	else if(color[3] < 25){ color[3] += 75; }
	
	PerformFade(client, 1, color);
	
	new Handle:pack2;
	CreateDataTimer(1.0, Timer_Drug, pack2);
	WritePackCell(pack2, client);
	for(new i=0;i<4;i++)
	{
		WritePackCell(pack2, color[i]);
	}
	
	return Plugin_Handled;
}

public Action:HealthExplode(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new tNr = ReadPackCell(pack);
	new amountHP = ReadPackCell(pack);
	new playersOnRegen[tNr];
	for(new i=0;i<tNr;i++)
	{
		playersOnRegen[i] = ReadPackCell(pack);
	}
	new indiHP = amountHP / tNr;
	new tempHP = amountHP;
	if(indiHP > 1)
	{
		for(new i=0;i<tNr;i++)
		{
			if(IsValidEntity(playersOnRegen[i]) && IsClientInGame(playersOnRegen[i]) && IsPlayerAlive(playersOnRegen[i]))
			{
				new curHP = GetClientHealth(playersOnRegen[i]);
				new maxHP = GetEntProp(playersOnRegen[i], Prop_Data, "m_iMaxHealth");
				if(GetConVarInt(cvNadeHealthOverHeal)==0)
				{
					if (curHP<maxHP)
					{
						SetEntityHealth(playersOnRegen[i], curHP+1);
						tempHP--;
					}
				}
				else if(GetConVarInt(cvNadeHealthOverHeal)==1)
				{
					if(curHP<(maxHP+(maxHP/2)))
					{
						SetEntityHealth(playersOnRegen[i], curHP+1);
						tempHP--;
					}
				}
			}
		}
		if(tempHP < amountHP && tempHP > 0)
		{
			new Handle:pack2;
			CreateDataTimer(1.0/24.0, HealthExplode, pack2);
			WritePackCell(pack2, tNr);
			WritePackCell(pack2, tempHP);
			for(new k=0;k<tNr;k++)
			{
				WritePackCell(pack2, playersOnRegen[k]);
			}
		}
		CloseHandle(pack);
		return Plugin_Continue;
	}
	CloseHandle(pack);
	return Plugin_Handled;
}

public Action:Timer_ShowInfo(Handle:timer) 
{
	for (new i = 1; i <= GetMaxClients(); i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientObserver(i)) 
		{
			new class = int:TF2_GetPlayerClass(i);
			if(class!=MEDIC)
			{
				SetHudTextParams(0.04, 0.37, 1.0, 255, 50, 50, 255);
				ShowSyncHudText(i, HudMessage, "Grenades: %d, %d", gRemaining[0][i], gRemaining[1][i]);
			}
			else
			{
				SetHudTextParams(0.04, 0.37, 1.0, 255, 50, 50, 255);
				ShowSyncHudText(i, HudMessage, "Grenades: %d, %d, %d", gRemaining[0][i], gRemaining[1][i], gRemaining[2][i]);
			}
		}
	}
	return Plugin_Continue;
}

public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
    if (g_hTimer != INVALID_HANDLE) 
	{
        KillTimer(g_hTimer);
    }
    g_hTimer          = CreateTimer(GetConVarInt(g_hInterval) * 0.1, Timer_ShowInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

//*************
SetupNadeConVars()
{
	cvPrimary[SCOUT][0] = CreateConVar("sm_nades_primary_scout_amount_min", "1", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvPrimary[SCOUT][1] = CreateConVar("sm_nades_primary_scout_amount_max", "1", "max amount holdable of this nade");
	cvPrimary[SCOUT][2] = CreateConVar("sm_nades_primary_scout_power", "3.0", "amount damage/power this nade deals/has");
	cvPrimary[SCOUT][3] = CreateConVar("sm_nades_primary_scout_radius", "256.0", "radius of this nade");
	cvPrimary[SNIPER][0] = CreateConVar("sm_nades_primary_sniper_amount_min", "2", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvPrimary[SNIPER][1] = CreateConVar("sm_nades_primary_sniper_amount_max", "3", "max amount holdable of this nade");
	cvPrimary[SNIPER][2] = CreateConVar("sm_nades_primary_sniper_power", "125.0", "amount damage/power this nade deals/has");
	cvPrimary[SNIPER][3] = CreateConVar("sm_nades_primary_sniper_radius", "256.0", "radius of this nade");
	cvPrimary[SOLDIER][0] = CreateConVar("sm_nades_primary_soldier_amount_min", "2", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvPrimary[SOLDIER][1] = CreateConVar("sm_nades_primary_soldier_amount_max", "4", "max amount holdable of this nade");
	cvPrimary[SOLDIER][2] = CreateConVar("sm_nades_primary_soldier_power", "125.0", "amount damage/power this nade deals/has");
	cvPrimary[SOLDIER][3] = CreateConVar("sm_nades_primary_soldier_radius", "256.0", "radius of this nade");
	cvPrimary[DEMO][0] = CreateConVar("sm_nades_primary_demo_amount_min", "1", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvPrimary[DEMO][1] = CreateConVar("sm_nades_primary_demo_amount_max", "3", "max amount holdable of this nade");
	cvPrimary[DEMO][2] = CreateConVar("sm_nades_primary_demo_power", "125.0", "amount damage/power this nade deals/has");
	cvPrimary[DEMO][3] = CreateConVar("sm_nades_primary_demo_radius", "256.0", "radius of this nade");
	cvPrimary[MEDIC][0] = CreateConVar("sm_nades_primary_medic_amount_min", "2", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvPrimary[MEDIC][1] = CreateConVar("sm_nades_primary_medic_amount_max", "2", "max amount holdable of this nade");
	cvPrimary[MEDIC][2] = CreateConVar("sm_nades_primary_medic_power", "125.0", "amount damage/power this nade deals/has");
	cvPrimary[MEDIC][3] = CreateConVar("sm_nades_primary_medic_radius", "256.0", "radius of this nade");
	cvPrimary[HEAVY][0] = CreateConVar("sm_nades_primary_heavy_amount_min", "2", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvPrimary[HEAVY][1] = CreateConVar("sm_nades_primary_heavy_amount_max", "4", "max amount holdable of this nade");
	cvPrimary[HEAVY][2] = CreateConVar("sm_nades_primary_heavy_power", "125.0", "amount damage/power this nade deals/has");
	cvPrimary[HEAVY][3] = CreateConVar("sm_nades_primary_heavy_radius", "256.0", "radius of this nade");
	cvPrimary[PYRO][0] = CreateConVar("sm_nades_primary_pyro_amount_min", "1", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvPrimary[PYRO][1] = CreateConVar("sm_nades_primary_pyro_amount_max", "3", "max amount holdable of this nade");
	cvPrimary[PYRO][2] = CreateConVar("sm_nades_primary_pyro_power", "125.0", "amount damage/power this nade deals/has");
	cvPrimary[PYRO][3] = CreateConVar("sm_nades_primary_pyro_radius", "256.0", "radius of this nade");
	cvPrimary[SPY][0] = CreateConVar("sm_nades_primary_spy_amount_min", "1", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvPrimary[SPY][1] = CreateConVar("sm_nades_primary_spy_amount_max", "2", "max amount holdable of this nade");
	cvPrimary[SPY][2] = CreateConVar("sm_nades_primary_spy_power", "125.0", "amount damage/power this nade deals/has");
	cvPrimary[SPY][3] = CreateConVar("sm_nades_primary_spy_radius", "256.0", "radius of this nade");
	cvPrimary[ENGIE][0] = CreateConVar("sm_nades_primary_engie_amount_min", "1", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvPrimary[ENGIE][1] = CreateConVar("sm_nades_primary_engie_amount_max", "2", "max amount holdable of this nade");
	cvPrimary[ENGIE][2] = CreateConVar("sm_nades_primary_engie_power", "125.0", "amount damage/power this nade deals/has");
	cvPrimary[ENGIE][3] = CreateConVar("sm_nades_primary_engie_radius", "256.0", "radius of this nade");
	
	cvSecondary[SCOUT][0] = CreateConVar("sm_nades_secondary_scout_amount_min", "2", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvSecondary[SCOUT][1] = CreateConVar("sm_nades_secondary_scout_amount_max", "4", "max amount holdable of this nade");
	cvSecondary[SCOUT][2] = CreateConVar("sm_nades_secondary_scout_power", "3.0", "amount damage/power this nade deals/has");
	cvSecondary[SCOUT][3] = CreateConVar("sm_nades_secondary_scout_radius", "288.0", "radius of this nade");
	cvSecondary[SNIPER][0] = CreateConVar("sm_nades_secondary_sniper_amount_min", "0", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvSecondary[SNIPER][1] = CreateConVar("sm_nades_secondary_sniper_amount_max", "0", "max amount holdable of this nade");
	cvSecondary[SNIPER][2] = CreateConVar("sm_nades_secondary_sniper_power", "50.0", "amount damage/power this nade deals/has");
	cvSecondary[SNIPER][3] = CreateConVar("sm_nades_secondary_sniper_radius", "256.0", "radius of this nade");
	cvSecondary[SOLDIER][0] = CreateConVar("sm_nades_secondary_soldier_amount_min", "0", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvSecondary[SOLDIER][1] = CreateConVar("sm_nades_secondary_soldier_amount_max", "1", "max amount holdable of this nade");
	cvSecondary[SOLDIER][2] = CreateConVar("sm_nades_secondary_soldier_power", "80.0", "amount damage/power this nade deals/has");
	cvSecondary[SOLDIER][3] = CreateConVar("sm_nades_secondary_soldier_radius", "256.0", "radius of this nade");
	cvSecondary[DEMO][0] = CreateConVar("sm_nades_secondary_demo_amount_min", "2", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvSecondary[DEMO][1] = CreateConVar("sm_nades_secondary_demo_amount_max", "3", "max amount holdable of this nade");
	cvSecondary[DEMO][2] = CreateConVar("sm_nades_secondary_demo_power", "85.0", "amount damage/power this nade deals/has");
	cvSecondary[DEMO][3] = CreateConVar("sm_nades_secondary_demo_radius", "256.0", "radius of this nade");
	cvSecondary[MEDIC][0] = CreateConVar("sm_nades_secondary_medic_amount_min", "2", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvSecondary[MEDIC][1] = CreateConVar("sm_nades_secondary_medic_amount_max", "4", "max amount holdable of this nade");
	cvSecondary[MEDIC][2] = CreateConVar("sm_nades_secondary_medic_power", "3.0", "amount damage/power this nade deals/has");
	cvSecondary[MEDIC][3] = CreateConVar("sm_nades_secondary_medic_radius", "288.0", "radius of this nade");
	cvSecondary[HEAVY][0] = CreateConVar("sm_nades_secondary_heavy_amount_min", "1", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvSecondary[HEAVY][1] = CreateConVar("sm_nades_secondary_heavy_amount_max", "2", "max amount holdable of this nade");
	cvSecondary[HEAVY][2] = CreateConVar("sm_nades_secondary_heavy_power", "85.0", "amount damage/power this nade deals/has");
	cvSecondary[HEAVY][3] = CreateConVar("sm_nades_secondary_heavy_radius", "256.0", "radius of this nade");
	cvSecondary[PYRO][0] = CreateConVar("sm_nades_secondary_pyro_amount_min", "2", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvSecondary[PYRO][1] = CreateConVar("sm_nades_secondary_pyro_amount_max", "3", "max amount holdable of this nade");
	cvSecondary[PYRO][2] = CreateConVar("sm_nades_secondary_pyro_power", "65.0", "amount damage/power this nade deals/has");
	cvSecondary[PYRO][3] = CreateConVar("sm_nades_secondary_pyro_radius", "256.0", "radius of this nade");
	cvSecondary[SPY][0] = CreateConVar("sm_nades_secondary_spy_amount_min", "2", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvSecondary[SPY][1] = CreateConVar("sm_nades_secondary_spy_amount_max", "4", "max amount holdable of this nade");
	cvSecondary[SPY][2] = CreateConVar("sm_nades_secondary_spy_power", "15.0", "amount damage/power this nade deals/has");
	cvSecondary[SPY][3] = CreateConVar("sm_nades_secondary_spy_radius", "256.0", "radius of this nade");
	cvSecondary[ENGIE][0] = CreateConVar("sm_nades_secondary_engie_amount_min", "1", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvSecondary[ENGIE][1] = CreateConVar("sm_nades_secondary_engie_amount_max", "3", "max amount holdable of this nade");
	cvSecondary[ENGIE][2] = CreateConVar("sm_nades_secondary_engie_power", "3.0", "amount damage/power this nade deals/has");
	cvSecondary[ENGIE][3] = CreateConVar("sm_nades_secondary_engie_radius", "256.0", "radius of this nade");
	
	cvTertiary[SCOUT][0] = CreateConVar("sm_nades_tertiary_scout_amount_min", "0", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvTertiary[SCOUT][1] = CreateConVar("sm_nades_tertiary_scout_amount_max", "0", "max amount holdable of this nade");
	cvTertiary[SCOUT][2] = CreateConVar("sm_nades_tertiary_scout_power", "3.0", "amount damage/power this nade deals/has");
	cvTertiary[SCOUT][3] = CreateConVar("sm_nades_tertiary_scout_radius", "256.0", "radius of this nade");
	cvTertiary[SNIPER][0] = CreateConVar("sm_nades_tertiary_sniper_amount_min", "0", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvTertiary[SNIPER][1] = CreateConVar("sm_nades_tertiary_sniper_amount_max", "0", "max amount holdable of this nade");
	cvTertiary[SNIPER][2] = CreateConVar("sm_nades_tertiary_sniper_power", "3.0", "amount damage/power this nade deals/has");
	cvTertiary[SNIPER][3] = CreateConVar("sm_nades_tertiary_sniper_radius", "256.0", "radius of this nade");
	cvTertiary[SOLDIER][0] = CreateConVar("sm_nades_tertiary_soldier_amount_min", "0", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvTertiary[SOLDIER][1] = CreateConVar("sm_nades_tertiary_soldier_amount_max", "0", "max amount holdable of this nade");
	cvTertiary[SOLDIER][2] = CreateConVar("sm_nades_tertiary_soldier_power", "3.0", "amount damage/power this nade deals/has");
	cvTertiary[SOLDIER][3] = CreateConVar("sm_nades_tertiary_soldier_radius", "256.0", "radius of this nade");
	cvTertiary[DEMO][0] = CreateConVar("sm_nades_tertiary_demo_amount_min", "0", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvTertiary[DEMO][1] = CreateConVar("sm_nades_tertiary_demo_amount_max", "0", "max amount holdable of this nade");
	cvTertiary[DEMO][2] = CreateConVar("sm_nades_tertiary_demo_power", "3.0", "amount damage/power this nade deals/has");
	cvTertiary[DEMO][3] = CreateConVar("sm_nades_tertiary_demo_radius", "256.0", "radius of this nade");
	cvTertiary[MEDIC][0] = CreateConVar("sm_nades_tertiary_medic_amount_min", "1", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvTertiary[MEDIC][1] = CreateConVar("sm_nades_tertiary_medic_amount_max", "1", "max amount holdable of this nade");
	cvTertiary[MEDIC][2] = CreateConVar("sm_nades_tertiary_medic_power", "500.0", "amount damage/power this nade deals/has");
	cvTertiary[MEDIC][3] = CreateConVar("sm_nades_tertiary_medic_radius", "256.0", "radius of this nade");
	cvTertiary[HEAVY][0] = CreateConVar("sm_nades_tertiary_heavy_amount_min", "0", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvTertiary[HEAVY][1] = CreateConVar("sm_nades_tertiary_heavy_amount_max", "0", "max amount holdable of this nade");
	cvTertiary[HEAVY][2] = CreateConVar("sm_nades_tertiary_heavy_power", "3.0", "amount damage/power this nade deals/has");
	cvTertiary[HEAVY][3] = CreateConVar("sm_nades_tertiary_heavy_radius", "256.0", "radius of this nade");
	cvTertiary[PYRO][0] = CreateConVar("sm_nades_tertiary_pyro_amount_min", "0", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvTertiary[PYRO][1] = CreateConVar("sm_nades_tertiary_pyro_amount_max", "0", "max amount holdable of this nade");
	cvTertiary[PYRO][2] = CreateConVar("sm_nades_tertiary_pyro_power", "50.0", "amount damage/power this nade deals/has");
	cvTertiary[PYRO][3] = CreateConVar("sm_nades_tertiary_pyro_radius", "256.0", "radius of this nade");
	cvTertiary[SPY][0] = CreateConVar("sm_nades_tertiary_spy_amount_min", "0", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvTertiary[SPY][1] = CreateConVar("sm_nades_tertiary_spy_amount_max", "0", "max amount holdable of this nade");
	cvTertiary[SPY][2] = CreateConVar("sm_nades_tertiary_spy_power", "3.0", "amount damage/power this nade deals/has");
	cvTertiary[SPY][3] = CreateConVar("sm_nades_tertiary_spy_radius", "256.0", "radius of this nade");
	cvTertiary[ENGIE][0] = CreateConVar("sm_nades_tertiary_engie_amount_min", "0", "amount of nades given on spawn(if sm_nades_start_amount = 1) & spawnlockers");
	cvTertiary[ENGIE][1] = CreateConVar("sm_nades_tertiary_engie_amount_max", "0", "max amount holdable of this nade");
	cvTertiary[ENGIE][2] = CreateConVar("sm_nades_tertiary_engie_power", "3.0", "amount damage/power this nade deals/has");
	cvTertiary[ENGIE][3] = CreateConVar("sm_nades_tertiary_engie_radius", "256.0", "radius of this nade");
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
	//PrecacheModel(MDL_TRAP, true);
	PrecacheModel(MDL_SMOKE, true);
	PrecacheModel(MDL_GAS, true);
	PrecacheModel(MDL_SMOKE_SPRITE, true);
	PrecacheModel(MDL_NAPALM_SPRITE, true);
	PrecacheModel(MDL_EMP_SPRITE, true);
	PrecacheModel(MDL_BEAM_SPRITE, true);

	
	AddFolderToDownloadTable("models/weapons/nades/duke1");
	AddFolderToDownloadTable("materials/models/weapons/nades/duke1");
	AddFileToDownloadsTable("sound/hallelujah.wav");
}

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

ShowTrail(nade, color[4])
{
	TE_SetupBeamFollow(nade, gRingModel, 0, Float:1.0, Float:10.0, Float:10.0, 5, color);
	TE_SendToAll();
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
	if(GetConVarInt(ff)==1){ team = 0; }
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

/*serverMessage()
{
	PrintCenterTextAll("This server is running a Nades mod. for info type /info");
}*/

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

SetupConcBeams(Float:center[3], Float:radius)
{
	new beamcolor[4] = { 255, 255, 255, 255 };
	new Float:beamcenter[3]; beamcenter = center;
	new Float:height = (radius/2.0)/GetConVarFloat(cvConcRings);
	for(new f=0;f<GetConVarInt(cvConcRings);f++)
	{
		TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.35,6.0,0.0,beamcolor,0,FBEAM_FADEOUT);
		TE_SendToAll(0.0);
		beamcenter[2] += height;
	}
}

GiveNades(client, type, size)
{
	new class = int:TF2_GetPlayerClass(client);
	new NadesGiven[2] = {0,0};
	/*
	max prim nades = GetConVarInt(cvFragNum[class])
	max sec nades = GetNumNades(class)
	cur prim nades = gRemaining[0][client]
	cur sec nades = gRemaining[1][client]
	*/
	//nades
	if(type == 0)
	{
		new NadesMax[2], NadesMin[2], rand; rand = GetRandomInt(0,3);
		NadesMax[0] = GetConVarInt(cvPrimary[class][1]); NadesMax[1] = GetConVarInt(cvSecondary[class][1]);
		NadesMin[0] = GetConVarInt(cvPrimary[class][0]); NadesMin[1] = GetConVarInt(cvSecondary[class][0]);
		if(size==3)
		{
			if(gRemaining[0][client] < NadesMin[0])
			{
				gRemaining[0][client] = NadesMin[0];
			}
			if(gRemaining[1][client] < NadesMin[1])
			{
				gRemaining[1][client] = NadesMin[1];
			}
		}
		else if(size==2)
		{
			if(class==MEDIC || class==SCOUT)
			{
				NadesGiven[0] += 1;
				NadesGiven[1] += 2;
			}
			else
			{
				NadesGiven[0] += 2;
				NadesGiven[1] += 1;
			}
		}
		else if(size==1)
		{
			NadesGiven[0] += 1;
			NadesGiven[1] += 1;
		}
		else if(size==0)
		{
			if(class==MEDIC || class==SCOUT)
			{
				NadesGiven[1] += 1;
			}
			else
			{
				NadesGiven[0] += 1;
			}
		}
		
		if(gRemaining[0][client] + NadesGiven[0] < NadesMax[0])
		{
			gRemaining[0][client] += NadesGiven[0];
		}
		else
		{
			gRemaining[0][client] = NadesMax[0];
		}
		
		if(gRemaining[1][client] + NadesGiven[1] < NadesMax[1])
		{
			gRemaining[1][client] += NadesGiven[1];
		}
		else
		{
			gRemaining[1][client] = NadesMax[1];
		}
	}
}

CreateSecondaryMirvs(client, Float:center[3], team)
{
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
			AcceptEntityInput(ent[k], "DisableDamageForces");
			rand = GetRandomFloat(0.0, 314.0);
			spread = GetConVarFloat(cvNadesMirvSpread) * GetRandomFloat(0.2, 1.0);
			vel[0] = spread*Sine(rand);
			vel[1] = spread*Cosine(rand);
			vel[2] = spread;
			GetVectorAngles(vel, angle);
			TeleportEntity(ent[k], center, angle, vel);
		}
	}	
	new Handle:pack;
	CreateDataTimer(gnDelay-1.0, MirvExplode2, pack);
	WritePackCell(pack, client);
	WritePackCell(pack, team);
	WritePackCell(pack, 0);
	for (k=0;k<MIRV_PARTS;k++)
	{
		WritePackCell(pack, ent[k]);
	}
}

CalculateDynamicDamage(damageInt, victim, Float:center[3], Float:radius)
{
	new String:TempString[32], Float:damageFloat, Float:origin[3], Float:distance, Float:dynamic_damage;
	new result;
	IntToString(damageInt , TempString, 31);
	damageFloat = StringToFloat(TempString);
	GetClientAbsOrigin(victim, origin);
	SubtractVectors(origin, center, origin);
	distance = GetVectorLength(origin);
	if (distance<0.01) { distance = 0.01; }
	dynamic_damage = FloatSub(damageFloat, (FloatMul(FloatMul(damageFloat, 0.75), FloatDiv(distance, radius))));
	FloatToString(dynamic_damage, TempString, 31);
	result = StringToInt(TempString);
	
	return result;
}

Float:ConvertSpeed(Float:a, Float:b, Float:c, Float:speed)
{
	new Float:result;
	result = -Pow(speed+a, 2.0)/b+c;
	return result;
}

DealDamage(victim, damage, Float:loc[3],attacker=0,dmg_type=DMG_GENERIC,String:weapon[]="")
{
	if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
	{
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		//PrintToChat(victim, "victim %i is valid and hit by attacker %i", victim, attacker);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			//new Float:vicOri[3];
			//GetClientAbsOrigin(victim, vicOri);
			TeleportEntity(pointHurt, loc, NULL_VECTOR, NULL_VECTOR);
			//Format(tName, sizeof(tName), "hurtme%d", victim);
			DispatchKeyValue(victim,"targetname","hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				//PrintToChat(victim, "weaponname = %s", weapon);
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			//Format(tName, sizeof(tName), "donthurtme%d", victim);
			DispatchKeyValue(victim,"targetname","donthurtme");
			//TeleportEntity(pointHurt[victim], gHoldingArea, NULL_VECTOR, NULL_VECTOR);
			//CreateTimer(0.01, TPHurt, victim);
			RemoveEdict(pointHurt);
		}
	}
}

EmitClassNadeBeep(client, class, BeepMode, special, nadeId=0)
{
	if(BeepMode==1)
	{
		if(nadeId==0)
		{
			if(special==0)
			{
				EmitSoundToAll(SND_NADE_CONC_TIMER, client);
			}
			else if(special==1)
			{
				switch (class)
				{
					case SCOUT:
					{
						EmitSoundToAll(SND_NADE_CONC_TIMER, client);
					}
					case SPY:
					{
						EmitSoundToAll(SND_NADE_HALLUC_TIMER, client);
					}
					default:
					{
						EmitSoundToAll(SND_NADE_CONC_TIMER, client);
					}
				}
			}
			else if(special==2)
			{
				switch (class)
				{
					default:
					{
						EmitSoundToAll(SND_NADE_CONC_TIMER, client);
					}
				}
			}
		}
		else
		{
			if(special==0)
			{
				EmitSoundToAll(SND_NADE_CONC_TIMER, nadeId);
			}
			else if(special==1)
			{
				switch (class)
				{
					case SCOUT:
					{
						EmitSoundToAll(SND_NADE_CONC_TIMER, nadeId);
					}
					case SPY:
					{
						EmitSoundToAll(SND_NADE_HALLUC_TIMER, nadeId);
					}
					default:
					{
						EmitSoundToAll(SND_NADE_CONC_TIMER, nadeId);
					}
				}
			}
			else if(special==2)
			{
				switch (class)
				{
					default:
					{
						EmitSoundToAll(SND_NADE_CONC_TIMER, nadeId);
					}
				}
			}
		}
	}
	else if(BeepMode==2)
	{
		if(special==0)
		{
			EmitSoundToClient(client, SND_NADE_CONC_TIMER);
		}
		else if(special==1)
		{
			switch (class)
			{
				case SCOUT:
				{
					EmitSoundToClient(client, SND_NADE_CONC_TIMER);
				}
				case SPY:
				{
					EmitSoundToClient(client, SND_NADE_HALLUC_TIMER);
				}
				default:
				{
					EmitSoundToClient(client, SND_NADE_CONC_TIMER);
				}
			}
		}
		else if(special==2)
		{
			switch (class)
			{
				default:
				{
					EmitSoundToClient(client, SND_NADE_CONC_TIMER);
				}
			}
		}
	}
}

SetupHudMsg(Float:time)
{
	SetHudTextParams(-1.0, 0.8, time, 255, 255, 255, 64, 1, 0.5, 0.0, 0.5);
}

ConcPlayer(victim, Float:center[3], Float:radius, attacker, bool:hh)
{
	new Float:play[3], Float:pointDist, Float:speed, Float:tempspeed[2], Float:playerspeed[3], Float:distance;
	GetClientAbsOrigin(victim, play);
	GetEntPropVector(victim, Prop_Data, "m_vecVelocity", playerspeed);
	play[2] += GetConVarFloat(cvConcBaseHeight);
	distance = GetVectorDistance(play, center);
	SubtractVectors(play, center, play);
	NormalizeVector(play, play);
	if (distance<GetConVarFloat(cvBlastDistanceMin)*radius) { distance = GetConVarFloat(cvBlastDistanceMin)*radius; }
	pointDist = FloatDiv(distance, radius);
	speed = GetVectorLength(playerspeed);
	new Float:baseSpd = GetConVarFloat(cvConcBaseSpeed);
			
	if(hh && victim==attacker) 
	{ 
		//tempspeed[0] = -Pow(speed-400.0, 2.0)/2000000.0 + (GetConVarFloat(cvConcHHincrement)-0.75);
		//tempspeed[1] = -Pow(speed-400.0, 2.0)/2000000.0 + (GetConVarFloat(cvConcHHincrement));
		tempspeed[0] = ConvertSpeed(600.0, 6700.0, baseSpd, speed);
		tempspeed[1] = tempspeed[0]; // * 1.2;
		if(tempspeed[0] < baseSpd/2.0) { tempspeed[0] = baseSpd/2.0; }
		if(tempspeed[1] < baseSpd/2.0) { tempspeed[1] = baseSpd/2.0; }
		play[0] *= tempspeed[0]; play[1] *= tempspeed[0]; play[2] *= tempspeed[1];
		if(playerspeed[2] < 0.0 && play[2] > 0.0 && GetConVarInt(cvConcBounce)==1) { playerspeed[2] = 0.0; }
		AddVectors(play, playerspeed, play);
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, play);
	}
	else
	{
		//tempspeed[0] = -Pow(speed-800.0, 2.0)/6000.0+GetConVarFloat(cvConcBaseSpeed);
		//tempspeed[1] = -Pow(speed-800.0, 2.0)/6000.0+(GetConVarFloat(cvConcBaseSpeed)*1.2);
		if(speed < 1200.0)
		{
			tempspeed[0] = ConvertSpeed(600.0, 800.0, baseSpd, speed);
			tempspeed[1] = tempspeed[0]; // * 1.2;
		}
		else
		{
			tempspeed[0] = Pow(speed-3500.0, 2.0)/8000.0;
			tempspeed[1] = tempspeed[0]; // * 1.2;
		}
		tempspeed[0] *= pointDist; tempspeed[1] *= pointDist;
		if(tempspeed[0] < baseSpd/2.0) { tempspeed[0] = baseSpd/2.0; }
		if(tempspeed[1] < baseSpd/2.0) { tempspeed[1] = baseSpd/2.0; }
		play[0] *= tempspeed[0]; play[1] *= tempspeed[0]; play[2] *= tempspeed[1];
		if(playerspeed[2] < 0.0 && play[2] > 0.0 && GetConVarInt(cvConcBounce)==1) { playerspeed[2] = 0.0; }
		AddVectors(play, playerspeed, play);
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, play);
	}
}

EmpPlayer(victim, Float:center[3], attacker)
{
	TF2_RemovePlayerDisguise(victim);
	new TFClassType:iClass = TF2_GetPlayerClass(victim);
	new String:weaponName[32]; GetClientWeapon(victim, weaponName, 31);
	new entvalue = 0;
	new m_Offset;
	new ammoLost = 0;
	new ammoLostScale = 0;
	new damage = 0;
	m_Offset=FindSendPropOffs("CTFPlayer","m_iAmmo"); //Find the offset 
	
	if(StrContains(weaponName, "n_scattergun") != -1 || StrContains(weaponName, "n_rocketlauncher") != -1 || StrContains(weaponName, "n_flamethrower") != -1 || StrContains(weaponName, "n_grenadelauncher") != -1 || StrContains(weaponName, "n_minigun") != -1 || StrContains(weaponName, "n_shotgun_primary") != -1 || StrContains(weaponName, "n_syringegun_medic") != -1 || StrContains(weaponName, "n_sniperrifle") != -1 || StrContains(weaponName, "n_revolver") != -1)
	{
		entvalue=GetEntData(victim,m_Offset+4,4);
		//PrintToServer("m_offset = \"%i\")", entvalue); //Print the value to the HLDS console
		if(entvalue > 0)
		{
			ammoLost = entvalue/4;
			ammoLostScale = ammoLost*400/TFClass_MaxAmmo[iClass][0];
			entvalue=(entvalue/4) * 3;
			//PrintToServer("ammoAmount = \"%i\")", entvalue); //Print the value to the HLDS console
			//PrintToServer("ammoLost = \"%i\")", ammoLost); //Print the value to the HLDS console
			SetEntData(victim, m_Offset+((0+1)*4), entvalue, 4, true); //Set the value of m_iAmmo to -25% of what it was
		}
	}
	else if(StrContains(weaponName, "n_pistol_scout") != -1 || StrContains(weaponName, "n_shotgun_soldier") != -1 || StrContains(weaponName, "n_shotgun_pyro") != -1 || StrContains(weaponName, "n_pipebomblauncher") != -1 || StrContains(weaponName, "n_shotgun_hwg") != -1 || StrContains(weaponName, "n_pistol") != -1 || StrContains(weaponName, "n_smg") != -1) //|| StrContains(weaponName, "n_flaregun") != -1)
	{
		entvalue=GetEntData(victim,m_Offset+8,4);
		//PrintToServer("m_offset = \"%i\")", entvalue); //Print the value to the HLDS console
		if(entvalue > 0)
		{
			ammoLost = entvalue/4;
			ammoLostScale = ammoLost*200/TFClass_MaxAmmo[iClass][1];
			entvalue=(entvalue/4) * 3;
			//PrintToServer("ammoAmount = \"%i\")", entvalue); //Print the value to the HLDS console
			//PrintToServer("ammoLost = \"%i\")", ammoLost); //Print the value to the HLDS console
			SetEntData(victim, m_Offset+((1+1)*4), entvalue, 4, true); //Set the value of m_iAmmo to -25% of what it was
		}
	}									
	if(ammoLost > 0)
	{	
		damage = (ammoLost * 2) + ammoLostScale;
		if(damage < 10){ damage = 10; }
		if(damage > 200){ damage = 200; }
		new String:tempString[32]; GetConVarString(cvNadeIcon, tempString, sizeof(tempString));
		DealDamage(victim, damage, center, attacker, DMG_CRUSH, tempString);
		if(GetConVarInt(cvNadesEmpExplosion)==1)
		{
			new Float:tcenter[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", tcenter);
			ShowParticle(tcenter, "ExplosionCore_MidAir", 2.0);
		}
	}			
}

//temp??
PerformFade(client, duration, const color[4]) 
{
	new Handle:hFadeClient=StartMessageOne("Fade",client);
	BfWriteShort(hFadeClient,duration);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration
	BfWriteShort(hFadeClient,0);		// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration until reset (fade & hold)
	BfWriteShort(hFadeClient,(FFADE_PURGE|FFADE_OUT|FFADE_STAYOUT)); // fade type (in / out)
	BfWriteByte(hFadeClient,color[0]);	// fade red
	BfWriteByte(hFadeClient,color[1]);	// fade green
	BfWriteByte(hFadeClient,color[2]);	// fade blue
	BfWriteByte(hFadeClient,color[3]);	// fade alpha
	EndMessage();
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

public bool:TraceRayDontHitSelf(entity, mask, any:startent)
{
	if(entity == startent)
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