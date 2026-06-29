#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2b"
#define PLUGIN_LINK "https://forums.alliedmods.net/showthread.php?t=322846"

public Plugin myinfo =
{
	name = "Stroke Strike",
	author = "ZooL Smith",
	description = "Play golf on any map!",
	version = PLUGIN_VERSION,
	url = ""
};

// PLAYER LOGIC
int playerHasDecoy[MAXPLAYERS+1];
int playerCurrentDecoyProj[MAXPLAYERS+1];
int playerScores[MAXPLAYERS+1];
int playerViewmodel[MAXPLAYERS+1];
int playerModel[MAXPLAYERS+1];
bool playerHookedViewmodel[MAXPLAYERS+1];
float playerPrevPos[MAXPLAYERS+1][3];
Handle playerCurrentDecoyProjTimer;

// GAMEMODE LOGIC
int turnTime = 0;
int turn = 0;
int whoWon = -1;
int holeCount = -1;
int holeCountFile[512];
int holePar = 3;
int currentHole = -1;
char holeFileName[48];
bool holeOver = false;
bool gamemodeUnavailable = false;
bool gamemodeEnabled = false;
bool mapHasStroke = false;
bool stopTimers = false;
int waitPostTurnCount = 0;				// in case the decoy gets stuck
const int waitPostTurnCountMax = 30;	// tested every 0.5s -> waiting 15s until timeout
const int niceShotDistance = 320;
Handle turnTimer;

// POINTS
const int pointsHoleInOne = 20;
const int pointsNiceShot = 5;
const int pointsNormal = 1;

// HOLE MDL
int hole_mdl = -1;
int flag_mdl = -1;
int indicator_mdl = -1;

// BALL MDL
int golfViewmodel = -1;

// CONFIG PATHS
char dirPath[PLATFORM_MAX_PATH];
char mapname[PLATFORM_MAX_PATH];
char mapConfigPath[PLATFORM_MAX_PATH];

// CONFIG DATA
char holeName[48];
char holeAuthor[48];
float holePosition[3];
float holeRadius;
float spawnPosition[3];
float spawnAngles[3];
float spawnRadius;
float winPosition[3];
float winAngles[3];

// EDIT MODE
int editwin_mdl = -1;
int editwin_cam = -1;
int editspawn_mdl = -1;
int editspawn_cam = -1;
int editspawn_rad = -1;
int edithole_rad = -1;
bool editEnabled = false;

// COMMANDS
int turnTimeMax = 5;
int winnerHealthFactor = 50;
int loserHealth = 50;
char weaponLose[32] = "weapon_usp_silencer";
char weaponWin[32] = "weapon_deagle";
bool gamemodeDisabledEntirely = false;
bool commandsAltered = false;
bool debugMode = false;
bool holeIsRandom = false;
bool allowTeleportBack = true;
bool keepPlayerModel = true;
bool forceCT = true;
bool forceConfig = false;
bool enablePar = true;


public void OnMapStart()
{		
	makeConfigPaths();
	precacheDownload();
	gamemodeEnabled = true;
	loadMapConfig();
	resetMatch();
	
	if(editEnabled) 
		setGamemode(0, 2);
}

public void precacheDownload()
{
	// MODELS
	PrecacheModel("models/props/props_gameplay/capture_flag_pole.mdl",false);
	PrecacheModel("models/editor/playerstart.mdl");
	PrecacheModel("models/editor/camera.mdl");
	
	AddFileToDownloadsTable("models/zool/strokestrike/trashcan.vvd");
	AddFileToDownloadsTable("models/zool/strokestrike/trashcan.dx90.vtx");
	AddFileToDownloadsTable("models/zool/strokestrike/trashcan.mdl");
	AddFileToDownloadsTable("models/zool/strokestrike/trashcan.phy");
	PrecacheModel("models/zool/strokestrike/trashcan.mdl",false);
	
	AddFileToDownloadsTable("models/zool/strokestrike/indicator.vvd");
	AddFileToDownloadsTable("models/zool/strokestrike/indicator.dx90.vtx");
	AddFileToDownloadsTable("models/zool/strokestrike/indicator.mdl");
	PrecacheModel("models/zool/strokestrike/indicator.mdl",false);
	
	AddFileToDownloadsTable("models/zool/strokestrike/v_club.vvd");
	AddFileToDownloadsTable("models/zool/strokestrike/v_club.dx90.vtx");
	AddFileToDownloadsTable("models/zool/strokestrike/v_club.mdl");
	AddFileToDownloadsTable("materials/models/zool/strokestrike/club/c_golfclub.vmt");
	AddFileToDownloadsTable("materials/models/zool/strokestrike/club/c_golfclub.vtf");
	AddFileToDownloadsTable("materials/models/zool/strokestrike/club/hud_bar.vmt");
	AddFileToDownloadsTable("materials/models/zool/strokestrike/club/hud_base.vmt");
	
	golfViewmodel = PrecacheModel("models/zool/strokestrike/v_club.mdl");
	
	AddFileToDownloadsTable("models/zool/strokestrike/radius.vvd");
	AddFileToDownloadsTable("models/zool/strokestrike/radius.dx90.vtx");
	AddFileToDownloadsTable("models/zool/strokestrike/radius.mdl");
	
	PrecacheModel("models/zool/strokestrike/radius.mdl");
	PrecacheModel("models/zool/strokestrike/radius.mdl");
	
	// SOUNDS
	PrecacheSound("weapons/flashbang/grenade_hit1.wav", true); 
	PrecacheSound("survival/select_drop_location.wav", true); 
	PrecacheSound("survival/creep_exit_01.wav", true); 
	
	AddFileToDownloadsTable("sound/zool/strokestrike/hole.wav");
	AddFileToDownloadsTable("sound/zool/strokestrike/hole_in_one.wav");
	AddFileToDownloadsTable("sound/zool/strokestrike/hole_nice_shot.wav");
	AddFileToDownloadsTable("sound/zool/strokestrike/swing_0.wav");
	AddFileToDownloadsTable("sound/zool/strokestrike/swing_1.wav");
	AddFileToDownloadsTable("sound/zool/strokestrike/swing_2.wav"); 
	AddFileToDownloadsTable("sound/zool/strokestrike/swing_3.wav");
	
	PrecacheSound("zool/strokestrike/hole.wav", true); 
	PrecacheSound("zool/strokestrike/hole_in_one.wav", true); 
	PrecacheSound("zool/strokestrike/hole_nice_shot.wav", true); 
	PrecacheSound("zool/strokestrike/swing_0.wav", true); 
	PrecacheSound("zool/strokestrike/swing_1.wav", true);
	PrecacheSound("zool/strokestrike/swing_2.wav", true); 
	PrecacheSound("zool/strokestrike/swing_3.wav", true); 
	
	PrecacheSound("survival/zone_chosen_by_other.wav", true); 	
	PrecacheSound("survival/bonus_award_01.wav", true); 	
}

public void noConfigPrint()
{
	PrintToServer("\n----- [STROKE STRIKE] ---------------------------------------\n");
	PrintToServer("\t ERROR: no config file for '%s'", mapname);
	PrintToServer("  Add or create 'configs/strokestrike/%s/ANYTHING.txt'", mapname);
	PrintToServer("  Using 'sm_golf 2' with editing commands or manually.");
	PrintToServer("\t The gamemode is now disabled.");
	PrintToServer("\n-------------------------------------------------------------\n");
}

public void OnPluginStart()
{
	ServerCommand("mp_restartgame 1");
	
	RegisterCmds();
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	HookEvent("grenade_bounce", Event_GrenadeBounce, EventHookMode_Pre);
	HookEvent("decoy_started", Event_DecoyStarted, EventHookMode_Pre);	// grenade_bounce fail if stuck
	HookEvent("inspect_weapon", Event_InspectWeapon, EventHookMode_Pre);
	
	HookEvent("round_end", Event_End, EventHookMode_Pre);
	HookEvent("round_freeze_end", Event_Start, EventHookMode_Pre);
	HookEvent("cs_pre_restart", Event_PreStart, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);	
	HookEvent("announce_phase_end", Event_ScoreboardEnd, EventHookMode_Pre);	
}

void RegisterCmds()
{
	RegAdminCmd("sm_golfers", Command_printGolfers, ADMFLAG_SLAY, "StrokeStrike - [DEBUG] Display available players");
	RegAdminCmd("sm_golfdebug", Command_setDebug, ADMFLAG_SLAY, "StrokeStrike - Enable/Disable Debug Mode");
	
	RegAdminCmd("sm_golfstroketime", Command_strokeTime, ADMFLAG_SLAY, "sm_golfstroketime <time>");
	RegAdminCmd("sm_golf", Command_setGamemode, ADMFLAG_SLAY, "sm_golf <0-2>");
	RegAdminCmd("sm_golfrandom", Command_setRandom, ADMFLAG_SLAY, "sm_golfrandom <0/1>");
	RegAdminCmd("sm_golfgoto", Command_setHole, ADMFLAG_SLAY, "sm_golfgoto <hole number>");
	RegAdminCmd("sm_golfrestart", Command_restartCourse, ADMFLAG_SLAY, "sm_golfrestart");
	RegAdminCmd("sm_golfwinhp", Command_healthPerPlayerWin, ADMFLAG_SLAY, "sm_golfwinhp <health factor>");
	RegAdminCmd("sm_golflosehp", Command_healthLoser, ADMFLAG_SLAY, "sm_golflosehp <health factor>");
	RegAdminCmd("sm_golfweapons", Command_weapons, ADMFLAG_SLAY, "sm_golfweapons <loser weapon entity> <winner weapon entity>");
	RegAdminCmd("sm_golfallowback", Command_allowBack, ADMFLAG_SLAY, "sm_golfallowback <0/1>");
	RegAdminCmd("sm_golfkeeppm", Command_keepplayermodel, ADMFLAG_SLAY, "sm_golfkeeppm <0/1>");
	RegAdminCmd("sm_golfforcect", Command_forceCT, ADMFLAG_SLAY, "sm_golfforcect <0/1>");
	RegAdminCmd("sm_golfforceconfig", Command_forceconfig, ADMFLAG_SLAY, "sm_golfforceconfig <0/1>");
	RegAdminCmd("sm_golfpar", Command_enablePar, ADMFLAG_SLAY, "sm_golfpar <0/1>");
	
	// Config editing. This should at least be less painful than doing getpos_exact 
	// Needs to be used by a client.
	RegAdminCmd("sm_golfeditinfo", Command_golfeditinfo, ADMFLAG_SLAY, "sm_golfeditinfo <name> <author> [par]");
	
	RegAdminCmd("sm_golfeditspawn", Command_golfeditspawn, ADMFLAG_SLAY, "sm_golfeditspawn");
	RegAdminCmd("sm_golfedithole", Command_golfedithole, ADMFLAG_SLAY, "sm_golfedithole");
	RegAdminCmd("sm_golfeditwin", Command_golfeditwin, ADMFLAG_SLAY, "sm_golfeditwin");
	RegAdminCmd("sm_golfeditspawnradius", Command_golfeditspawnradius, ADMFLAG_SLAY, "sm_golfeditspawnradius <size>");
	RegAdminCmd("sm_golfeditholeradius", Command_golfeditholeradius, ADMFLAG_SLAY, "sm_golfeditholeradius <size>");
	
	RegAdminCmd("sm_golfeditsave", Command_golfeditsave, ADMFLAG_SLAY, "sm_golfeditsave <filename>");
	RegAdminCmd("sm_golfeditdel", Command_golfeditdel, ADMFLAG_SLAY, "sm_golfeditdel <filename>");
	RegAdminCmd("sm_golfeditload", Command_golfeditload, ADMFLAG_SLAY, "alias: sm_golfgoto <hole number>");
	
	RegAdminCmd("sm_golfedit", Menu_edit, ADMFLAG_SLAY, "sm_golfedit");
	
	RegAdminCmd("sm_golfhelp", Command_golfhelp, ADMFLAG_SLAY, "sm_golfhelp");
	RegAdminCmd("sm_golfedithelp", Command_golfedithelp, ADMFLAG_SLAY, "sm_golfedithelp");
}

public void OnMapEnd(){	End();}

public void setCommands()
{	
	if(gamemodeDisabledEntirely || gamemodeUnavailable)
		return;
	
	ServerCommand("mp_give_player_c4 0");
	ServerCommand("mp_teammates_are_enemies 1");
	ServerCommand("mp_radar_showall 1");
	ServerCommand("mp_roundtime 99"); 
	ServerCommand("mp_roundtime_defuse 99");
	ServerCommand("mp_roundtime_hostage 99");
	ServerCommand("mp_default_team_winner_no_objective 0");
	ServerCommand("mp_hostages_max 0");
	ServerCommand("mp_freezetime 2");
	ServerCommand("mp_defuser_allocation 0");
	ServerCommand("sv_ignoregrenaderadio 1");
	ServerCommand("mp_solid_teammates 1");
	ServerCommand("mp_playercashawards 0");
	ServerCommand("mp_teamcashawards 0");
	ServerCommand("mp_randomspawn 1");
	ServerCommand("mp_t_default_secondary weapon_deagle");
	ServerCommand("mp_ct_default_secondary weapon_deagle");
	ServerCommand("mp_respawn_on_death_ct 0");
	ServerCommand("mp_respawn_on_death_t 0");
	ServerCommand("mp_ct_default_grenades \"\"");
	ServerCommand("mp_t_default_grenades \"\"");
	ServerCommand("sv_infinite_ammo 0");
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("mp_limitteams 256");
	ServerCommand("mp_defuser_allocation 0");
	ServerCommand("mp_buytime 0");
	commandsAltered = true;
}
public void resetCommands()
{
	ServerCommand("mp_give_player_c4 1");
	ServerCommand("mp_teammates_are_enemies 0");
	ServerCommand("mp_radar_showall 0");
	ServerCommand("mp_roundtime 5");
	ServerCommand("mp_roundtime_defuse 2.25");
	ServerCommand("mp_roundtime_hostage 2");
	ServerCommand("mp_default_team_winner_no_objective -1");
	ServerCommand("mp_hostages_max 2");
	ServerCommand("mp_freezetime 5");
	ServerCommand("mp_defuser_allocation 2");
	ServerCommand("sv_ignoregrenaderadio 0");
	ServerCommand("mp_solid_teammates 0");
	ServerCommand("mp_playercashawards 1");
	ServerCommand("mp_teamcashawards 1");
	ServerCommand("mp_randomspawn 0");
	ServerCommand("mp_t_default_secondary weapon_glock");
	ServerCommand("mp_ct_default_secondary weapon_hkp2000");
	ServerCommand("mp_respawn_on_death_ct 0");
	ServerCommand("mp_respawn_on_death_t 0");
	ServerCommand("mp_ct_default_grenades \"\"");
	ServerCommand("mp_t_default_grenades \"\"");
	ServerCommand("sv_infinite_ammo 0");
	ServerCommand("mp_autoteambalance 1");
	ServerCommand("mp_limitteams 2");
	ServerCommand("mp_buytime 45");
	ServerCommand("mp_defuser_allocation 2");
	
	ServerCommand("mp_scrambleteams");
	commandsAltered = false;
	if(!editEnabled) PrintToServer("[STROKE STRIKE] Setting back to default unaltered csgo server commands");
}

// =====================================================================
// EVENTS


public OnEntityCreated(entity, const String:classname[])
{
    if(StrEqual(classname, "decoy_projectile"))
    {
        SDKHook(entity, SDKHook_SpawnPost, SpawnPost_Decoy);
    }
}

public Action Event_Start(Event event, const char[] name, bool dontBroadcast){FreezeTimeEnd();}
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast){RoundStart();}
public Action Event_PreStart(Event event, const char[] name, bool dontBroadcast){PreStart();}
public Action Event_End(Event event, const char[] name, bool dontBroadcast){End();}
public Action Event_ScoreboardEnd(Event event, const char[] name, bool dontBroadcast){ stopTimers = true; }


public OnClientWeaponSwitchPost(client, wpnid)	// When switching guns
{	
	char szWpn[64];
	GetEntityClassname(wpnid,szWpn,sizeof(szWpn));
    
	if(StrEqual(szWpn, "weapon_decoy"))
	{
		SetEntProp(wpnid, Prop_Send, "m_nModelIndex", 0);
		SetEntProp(playerViewmodel[client], Prop_Send, "m_nModelIndex", golfViewmodel);
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));	
	playerViewmodel[client] = Weapon_GetViewModelIndex(client, -1);
	
	if((!gamemodeEnabled || gamemodeDisabledEntirely || GameRules_GetProp("m_bWarmupPeriod")) && !editEnabled)
	{
		viewmodelHooker(client, false);
		return;
	}
	
	if(holeOver)
		return;
	
	if(editEnabled)
		SetEntProp(client, Prop_Data, "m_nSolidType", 1);
	else
		setupPlayer(client);
	viewmodelHooker(client, true); 
}

public void viewmodelHooker(int client, bool hook)
{	
	if(!hook && playerHookedViewmodel[client])
	{
		SDKUnhook(client, SDKHook_WeaponSwitchPost, OnClientWeaponSwitchPost);
	}
	else if(hook && !playerHookedViewmodel[client])
	{
		SDKHook(client, SDKHook_WeaponSwitchPost, OnClientWeaponSwitchPost);
	}
	playerHookedViewmodel[client] = hook;
}

	
public void detonateDecoy(int decoy, int client)
{	
	if((holeOver || !gamemodeEnabled) && !editEnabled)
		return;
	
	float clientAngles[3];
	GetClientAbsAngles(client, clientAngles);
	playerHasDecoy[client] = false;
	playerCurrentDecoyProj[client] = 0;
	GetClientAbsOrigin(client, playerPrevPos[client]);
	
	float decoyPosition[3];
	GetEntPropVector(decoy, Prop_Send, "m_vecOrigin", decoyPosition);
	
// If all players have played, don't wait, just go to the next turn
	if (checkAllPlayersPlayed() && turnTime && !editEnabled)	
		allPlayersPlayed();
	
	float decoyPositionPlayerSpawn[3] = {0.0, 0.0, 4.0};
	AddVectors(decoyPosition,decoyPositionPlayerSpawn,decoyPositionPlayerSpawn);
	
	if(GetEntityMoveType(client) != MOVETYPE_NOCLIP) TeleportEntity(client, decoyPositionPlayerSpawn, clientAngles, NULL_VECTOR);	// was annoying when noclipping... you're not supposed to be in noclip but..
	EmitAmbientSound("survival/creep_exit_01.wav", playerPrevPos[client], client, 60, 0, 0.5, 130);
	
	SetEntityRenderMode(client, RENDER_NORMAL);
	
	CreateParticle
	(		
		decoyPosition[0],decoyPosition[1],decoyPosition[2],	
		0.0,0.0,0.0, 	
		"explosion_child_snow07a", 2.0
	);
	
	RemoveEntity(decoy);
}	
public Action Event_DecoyStarted(Event event, const char[] name, bool dontBroadcast){
	detonateDecoy(event.GetInt("entityid"), GetClientOfUserId(event.GetInt("userid")));}

public Action Event_GrenadeBounce(Event event, const char[] name, bool dontBroadcast)
{	
	if((holeOver || !gamemodeEnabled) && !editEnabled)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(removeDecoyIfPlayerDead(client))
		return;
	
	int decoy = playerCurrentDecoyProj[client];
	float decoyPosition[3];
	GetEntPropVector(decoy, Prop_Send, "m_vecOrigin", decoyPosition);
	
	CreateParticle
	(		
		decoyPosition[0],decoyPosition[1],decoyPosition[2],	
		0.0,0.0,0.0, 	
		"impact_metal_cheap", 1.0
	);
	
	float holeGoalOffset[3] = {0.0,0.0,24.0};
	AddVectors(holeGoalOffset, holePosition, holeGoalOffset);
	if(isInRadius(decoyPosition, holeGoalOffset, 12.0) && !editEnabled)
	{
		EmitAmbientSound("zool/strokestrike/hole.wav", holePosition, hole_mdl, 80, 0, 1.0, 100);
		whoWon = client;
		End();
	}
	
	float velocity[3];
	GetEntPropVector(decoy, Prop_Data, "m_vecVelocity", velocity);
	
	if(GetVectorLength(velocity) == 0)
		detonateDecoy(decoy, client);
}


public SpawnPost_Decoy(entity)
{
	if((holeOver || !gamemodeEnabled) && !editEnabled)
		return;
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if(!IsPlayerAlive(client) || IsPlayerNotInATeam(client))
		return;
	
	if(!IsValidEdict(entity) || !IsValidEntity(entity))		// bot issue (dies when round ends, doesn't get reset or too late?)
		return;
	
	int oldDecoy = playerCurrentDecoyProj[client];
	if(oldDecoy && IsValidEdict(oldDecoy) && IsValidEntity(oldDecoy))
		RemoveEntity(oldDecoy);
	
	playerCurrentDecoyProj[client] = entity;
	
	CreateTimer(0.0, SpawnPost_Decoy_Delayed, entity);
	
}
public Action SpawnPost_Decoy_Delayed(Handle timer, int entity)
{
	if(!IsValidEdict(entity) || !IsValidEntity(entity))		// bot issue (dies when round ends, doesn't get reset or too late?)
		return;
	
	float velocity[3];
	float pos[3];
	
	GetEntPropVector(entity, Prop_Data, "m_vecVelocity", velocity);
	
	float speed = GetVectorLength(velocity);
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(debugMode) 
	{
		char name[32];
		GetClientName(client, name, 32);
		PrintToServer("%s's Initial Decoy Velocity: %f", name, speed);
	}
	
	// SND
	if(speed < 230)
		EmitAmbientSound("zool/strokestrike/swing_0.wav", pos, entity, 70, 0, 0.6, 100);
	else if(speed < 460)
		EmitAmbientSound("zool/strokestrike/swing_1.wav", pos, entity, 75, 0, 1.0, 100);
	else if(speed < 700)
		EmitAmbientSound("zool/strokestrike/swing_2.wav", pos, entity, 75, 0, 1.0, 85);
	else
		EmitAmbientSound("zool/strokestrike/swing_3.wav", pos, entity, 80, 0, 1.0, 100);
	
	SetHudTextParams(0.6, 0.9, 2.5, 255, 200, 100, 255, 0, 0.0, 0.1, 0.5); 
	ShowHudText(client, 4, "Speed: %d u/s", RoundToNearest(speed)); 
}

public Action Event_InspectWeapon(Event event, const char[] name, bool dontBroadcast)
{
	if((holeOver || !gamemodeEnabled || !allowTeleportBack) && !editEnabled)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(editEnabled && !IsPlayerHoldingDecoy(client))
		return;
	
	float clientPos[3];
	float clientAngles[3];
	GetClientAbsAngles(client, clientAngles);
	GetClientAbsOrigin(client, clientPos);
	
	if(!playerCanRollBack(client))
		return;
	
	TeleportEntity(client, playerPrevPos[client], clientAngles, NULL_VECTOR);
	
	CreateParticle
	(		
		playerPrevPos[client][0],playerPrevPos[client][1],playerPrevPos[client][2],	
		0.0,0.0,0.0, 	
		"explosion_child_snow07a", 3.0
	);
	
	EmitAmbientSound("survival/select_drop_location.wav", playerPrevPos[client], client, 60, 0, 0.6);
}

public void hurtStartTouch(const String:output[], int caller, int activator, float delay)
{
	char classname[32];
	GetEdictClassname(activator, classname, sizeof(classname));
	if(StrEqual("decoy_projectile", classname))
	{
		int owner = GetEntPropEnt(activator, Prop_Send, "m_hThrower");
		playerHasDecoy[owner] = false;
		playerCurrentDecoyProj[owner] = 0;
		RemoveEntity(activator);
		
		char playerName[32];
		GetClientName(owner, playerName, sizeof(playerName));
		
		PrintToChatAll("%s's decoy fell out the map!", playerName);
		
		if (checkAllPlayersPlayed() && turnTime)	
			allPlayersPlayed();
	}
}

public void OnClientDisconnect_Post(int client)
{
	playerScores[client] = 0;
	playerModel[client] = 0;
	playerHookedViewmodel[client] = false;
}



// =====================================================================
// TURNS

public Action startTurnDelay(Handle timer){startTurn();}
public void startTurn()
{
	if(holeOver || !gamemodeEnabled)
		return;
	
	if(!stopTimers) CreateTimer(2.0, clockTurn, 0, TIMER_FLAG_NO_MAPCHANGE);
	turnTime = turnTimeMax;
	waitPostTurnCount = 0;
	turn++;
	
	SetHudTextParams(-1.0, 0.7, 1.5, 0, 255, 0, 255, 0, 0.0, 0.01, 0.2); 
	for(int i = 1; i < MAXPLAYERS; i++)
	{
		if(IsClientInGame(i))
		{
			ShowHudText(i, 3, "❯   Stroke %d   ❮", turn); 
			if(IsPlayerAlive(i) && !IsPlayerNotInATeam(i)) giveBall(i);
			showInspectHint(i,2.2);
		}
	}
}

public Action clockTurn(Handle timer)
{
	if(!turnTime || holeOver || !gamemodeEnabled)
	{
		endTurn();
		return;
	}
	
	for(int i = 1; i < MAXPLAYERS; i++)
		if(IsClientInGame(i))
		{
			if(turnTime < 4)
				SetHudTextParams(-1.0, 0.7, 0.9, 255, 20, 0, 255, 0, 0.0, 0.05, 0.05);
			else
				SetHudTextParams(-1.0, 0.7, 1.0, 255, 255, 255, 255, 0, 0.0, 0.01, 0.01);
			
			ShowHudText(i, 3, "❱  %d  ❰", turnTime); 
			if(debugMode) showInfoHUD(); 
			showInspectHint(i,1.1);
		}
		
	turnTime--;
	if(!stopTimers) turnTimer = CreateTimer(1.0, clockTurn);
}

public void showInspectHint(int client, float duration)
{
	if(!allowTeleportBack || IsPlayerNotInATeam(client) || !IsPlayerHoldingDecoy(client) || !playerCanRollBack(client))
		return;
	
	SetHudTextParams(-1.0, 0.85, duration, 200, 255, 200, 255, 0, 0.0, 0.0, 0.5);
	ShowHudText(client, 1, "[INSPECT] to fallback to the last position"); 
}
public void showInfoHUD()
{
	char buffer[8];
	char info[256] = "Info:  <";
	StrCat(info,sizeof(info),holeName); StrCat(info,sizeof(info),"> <");
	StrCat(info,sizeof(info),holeAuthor); StrCat(info,sizeof(info),"> (");
	IntToString(holePar,buffer,sizeof(buffer)); StrCat(info,sizeof(info),buffer); StrCat(info,sizeof(info),")");
	StrCat(info,sizeof(info),"\nFile:   <");
	StrCat(info,sizeof(info),holeFileName); StrCat(info,sizeof(info),">");
	StrCat(info,sizeof(info),"\n\nSpawn: [");
	IntToString(RoundToNearest(spawnPosition[0]),buffer,sizeof(buffer)); StrCat(info,sizeof(info),buffer); StrCat(info,sizeof(info)," ");
	IntToString(RoundToNearest(spawnPosition[1]),buffer,sizeof(buffer)); StrCat(info,sizeof(info),buffer); StrCat(info,sizeof(info)," ");
	IntToString(RoundToNearest(spawnPosition[2]),buffer,sizeof(buffer)); StrCat(info,sizeof(info),buffer); StrCat(info,sizeof(info),"] (");
	IntToString(RoundToNearest(spawnRadius),buffer,sizeof(buffer)); StrCat(info,sizeof(info),buffer); StrCat(info,sizeof(info),")");
	
	StrCat(info,sizeof(info),"\nHole:    [");
	IntToString(RoundToNearest(holePosition[0]),buffer,sizeof(buffer)); StrCat(info,sizeof(info),buffer); StrCat(info,sizeof(info)," ");
	IntToString(RoundToNearest(holePosition[1]),buffer,sizeof(buffer)); StrCat(info,sizeof(info),buffer); StrCat(info,sizeof(info)," ");
	IntToString(RoundToNearest(holePosition[2]),buffer,sizeof(buffer)); StrCat(info,sizeof(info),buffer); StrCat(info,sizeof(info),"] (");
	IntToString(RoundToNearest(holeRadius),buffer,sizeof(buffer)); StrCat(info,sizeof(info),buffer); StrCat(info,sizeof(info),")");
	StrCat(info,sizeof(info),"\nWin:     [");
	IntToString(RoundToNearest(winPosition[0]),buffer,sizeof(buffer)); StrCat(info,sizeof(info),buffer); StrCat(info,sizeof(info)," ");
	IntToString(RoundToNearest(winPosition[1]),buffer,sizeof(buffer)); StrCat(info,sizeof(info),buffer); StrCat(info,sizeof(info)," ");
	IntToString(RoundToNearest(winPosition[2]),buffer,sizeof(buffer)); StrCat(info,sizeof(info),buffer); StrCat(info,sizeof(info),"]");
	
	for(int i = 1; i < MAXPLAYERS; i++)
		if(IsClientInGame(i))
		{
			SetHudTextParams(0.3, 0.1, 2.0, 255, 200, 100, 255, 0, 0.0, 0.0, 0.0);
			ShowHudText(i, 2, info); 
			showInspectHint(i,0.6);
		}
}
public Action editDisplayTimer(Handle timer)
{
	showInfoHUD();
	if(!stopTimers) turnTimer = CreateTimer(0.5, editDisplayTimer);
}

public void endTurn()
{
	if(!gamemodeEnabled)
		return;

	SetHudTextParams(-1.0, -1.0, 1.5, 255, 0, 0, 255); 
	for(int i = 1; i < MAXPLAYERS; i++)
	{
		if(IsClientInGame(i) && !IsPlayerNotInATeam(i))
		{
			if(playerHasDecoy[i] && IsPlayerAlive(i) && !playerCurrentDecoyProj[i])
			{
				SDKHooks_TakeDamage(i, i, i, 50.0, 0, -1, NULL_VECTOR, NULL_VECTOR);
				
				if(!holeOver)
					ShowHudText(i, 5, "TIME'S UP!");
				if(IsPlayerAlive(i))
					removeWeapons(i);
			}
		}
	}
	
	if(!noNadesInTheAir() && waitPostTurnCount <= waitPostTurnCountMax)
	{
		if(!stopTimers)	playerCurrentDecoyProjTimer = CreateTimer(0.0, waitPostTurn);
		return;
	}
	
	for(int i = 1; i < MAXPLAYERS; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i) && playerCurrentDecoyProj[i] && !holeOver && !IsPlayerNotInATeam(i))
		{
			SetHudTextParams(-1.0, 0.40, 3.0, 255, 0, 0, 255); 
			ShowHudText(i, 5, "Something bad has probably happened to your decoy.");
		}
	
	removeDecoys();

	if(turnTimer && turnTime && !holeOver) 
		KillTimer(turnTimer);
	
	if(!stopTimers) CreateTimer(1.0, startTurnDelay);
}
public Action waitPostTurn(Handle timer)
{
	if(!gamemodeEnabled || holeOver)
		return;
	
	if(noNadesInTheAir() || waitPostTurnCount > waitPostTurnCountMax)
	{
		KillTimer(playerCurrentDecoyProjTimer);		
		allPlayersPlayed();
	}
	else
	{	
		SetHudTextParams(-1.0, 0.7, 2.0, 255, 180, 0, 255, 0, 0.0, 0.0, 0.0);
		
		for(int i = 1; i < MAXPLAYERS; i++)
		{
			if(IsClientInGame(i) && !noNadesInTheAir())
				ShowHudText(i, 3, "WAITING FOR THE LATE PLAYS..."); 
		}
		playerCurrentDecoyProjTimer = CreateTimer(0.5, waitPostTurn);
	}
	
	waitPostTurnCount++;
}

// =====================================================================
// GAME LOGIC

public void FreezeTimeEnd()
{
	setupMapEntities();
	
	if(holeOver || !gamemodeEnabled)
		return;
	
	stopTimers = false;
	
	turn = 0;
	startTurn();
}

public void RoundStart()
{	
	clearHoleInfo();
	setGamemodeEnableState();
	stopTimers = true;
	
	if(editEnabled)
	{
		resetPlayerArrays();
		editEnabledPrint();
		createHole();
		editCreateObjects();
		stopTimers = false;
		turnTimer = CreateTimer(1.0, editDisplayTimer);
	}
	
	if(!countPlayers() && !GameRules_GetProp("m_bWarmupPeriod"))
	{
		PrintToChatAll(" \x10[STROKE STRIKE] No player is willing to play.");
		ServerCommand("mp_warmup_start");
		return;
	}
	
	if(gamemodeEnabled)
		readConfig();
	
	setupMapEntities();
	
	if(!gamemodeUnavailable && !gamemodeDisabledEntirely)	// making sure bots don't join every round.. weird things happen if they do.
		ServerCommand("bot_kick");
	
	if(!gamemodeEnabled)
		return;
	
	setCommands();
	
	for(int i = 1; i < MAXPLAYERS; i++)
	{
		if(IsClientInGame(i))
		{
			playerCurrentDecoyProj[i] = 0;
			playerPrevPos[i] = NULL_VECTOR;
			if(!IsPlayerNotInATeam(i))
			{
				removeWeapons(i);
				SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 0.000001);
				if(forceCT) CS_SwitchTeam(i, 3);
			}
		}
	}
	holeOver = false;
	whoWon = -1;
	
	if(holeOver || !gamemodeEnabled)
		return;
	
	printChatHoleInfo();
	
	randomizePositions();
	createHole();
	
	for(int i = 1; i < MAXPLAYERS; i++)
		if(IsClientInGame(i))
		{
			if(GetEntProp(i, Prop_Data, "m_nSolidType") == 2)	// First round after warmup doesn't register correctly #ducttapefix
				setupPlayer(i);
			
			CS_SetClientContributionScore(i, playerScores[i]);
			TeleportEntity(i, spawnPosition, spawnAngles, NULL_VECTOR);
			viewmodelHooker(i, true);
		}
}

public void PreStart()	// I've fucked up somehow.
{	
	if(holeOver && gamemodeEnabled && !gamemodeUnavailable && !gamemodeDisabledEntirely)
	{
		int currentScore = CS_GetTeamScore(3)+1;
		SetTeamScore(3, currentScore);
		CS_SetTeamScore(3, currentScore);
	}
	
	holeOver = false;
}

public void setupMapEntities()
{
	char szClass[65];
	for (int i = MaxClients; i <= GetMaxEntities(); i++)
    {
        if(IsValidEdict(i) && IsValidEntity(i))
        {
            GetEdictClassname(i, szClass, sizeof(szClass));
            if(	StrEqual("hostage_entity", szClass) ||
				StrEqual("func_breakable", szClass) ||
				StrEqual("weapon_c4", szClass)
			)
			{
				if(gamemodeEnabled)	RemoveEdict(i);
			}
			else if(StrEqual("func_buyzone", szClass) || 
				StrEqual("func_bomb_target", szClass) ||
				StrEqual("func_hostage_rescue", szClass)
			)
			{
				if(!gamemodeEnabled)
				{
					AcceptEntityInput(i, "Enable");
					AcceptEntityInput(i, "SetEnabled");
				}
				else
				{
					AcceptEntityInput(i, "Disable");
					AcceptEntityInput(i, "SetDisabled");
				}
			}
			else if(StrEqual("trigger_hurt", szClass))
			{
				DispatchKeyValue(i, "spawnflags", "4160");
			}
				
        }
    }
	
	// TRIGGER_HURT
	HookEntityOutput("trigger_hurt", "OnStartTouch", hurtStartTouch);
	HookEntityOutput("trigger_hurt", "OnTrigger", hurtStartTouch);
	// ----------
}
public void setGamemodeEnableState()
{
	if(gamemodeDisabledEntirely || gamemodeUnavailable)
	{
		gamemodeEnabled = false;
		return;
	}
	
	if(GameRules_GetProp("m_bWarmupPeriod"))
	{
		setCommands();
		if(gamemodeEnabled == true)
		{
			resetMatch();
			ServerCommand("mp_restartgame 1");	
			PrintToChatAll(" \x10[STROKE STRIKE] The golf course will begin once the warmup is over!");
		}
		gamemodeEnabled = false;
		return;
	}
	gamemodeEnabled = true;
}

public void End()
{	
	if(holeOver || !gamemodeEnabled || gamemodeDisabledEntirely)
		return;
	
	float restartDelay = GetConVarFloat(FindConVar("mp_round_restart_delay"));
	if(whoWon > 0 && IsClientInGame(whoWon))
	{
		float winPos[3];
		char winName[32];
		GetClientName(whoWon, winName, sizeof(winName));
		
		GetClientAbsOrigin(whoWon, winPos);
		if(debugMode) PrintToServer("%s's Shot had a distance of %f", winName, GetVectorDistance(winPos,holePosition));
		
		if(turn == 1)
		{
			playerScores[whoWon] += pointsHoleInOne; CS_SetClientContributionScore(whoWon, playerScores[whoWon]);
			SetHudTextParams(-1.0, 0.7, restartDelay, 100, 255, 100, 255); 
			
			for(int i = 1; i < MAXPLAYERS; i++) if(IsClientInGame(i))
				ShowHudText(i, 3, "HOLE IN ONE!!!!\n\n%s has won!", winName);
			
			PrintToChatAll(" \x04%s did an hole in one! +%d points!", winName, pointsHoleInOne);
			for(int p = 0; p<4; p++) 
				CreateParticle
				(		
					holePosition[0],holePosition[1],holePosition[2] - p*6,	
					-90.0,0.0,0.0, 	
					"weapon_confetti", 5.0
				);
			EmitAmbientSound("zool/strokestrike/hole_in_one.wav", holePosition, whoWon, 110, 0, 0.7, 100);
		}
		else if(GetVectorDistance(winPos,holePosition) > niceShotDistance)
		{
			playerScores[whoWon] += pointsNiceShot; CS_SetClientContributionScore(whoWon, playerScores[whoWon]);
			SetHudTextParams(-1.0, 0.7, restartDelay, 200, 100, 255, 255); 
			
			for(int i = 1; i < MAXPLAYERS; i++) if(IsClientInGame(i))
				ShowHudText(i, 3, "INSANE SHOT!!\n\n%s has won!", winName);
			
			PrintToChatAll(" \x0E%s did an amazing shot! \x04+%d points!", winName, pointsNiceShot);
			for(int p = 0; p<2; p++) 
				CreateParticle
				(		
					holePosition[0],holePosition[1],holePosition[2] - p*6,	
					-90.0,0.0,0.0, 	
					"weapon_confetti", 5.0
				);
			EmitAmbientSound("zool/strokestrike/hole_nice_shot.wav", holePosition, whoWon, 110, 0, 0.7, 100);
		}
		else
		{
			char scoreName[24] = "";
			int ptsMult = 1;
			
			if(holePar>0)
			{
				if(turn == holePar){		scoreName = "Par"; ptsMult = 1;	}
				else if(turn == holePar-1){	scoreName = "Birdie"; ptsMult = 2;	}
				else if(turn <= holePar-2){	scoreName = "Albatros"; ptsMult = 3;	}
				else if(turn == holePar+1){	scoreName = "Bogey"; ptsMult = 1;	}
				else if(turn == holePar+2){	scoreName = "Double Bogey"; ptsMult = 1;	}
				else if(turn >= holePar+3){	scoreName = "Triple Bogey"; ptsMult = 1;	}
			}
			
			char theS = '\0';	if(pointsNormal*ptsMult > 1) theS = 's';
			
			playerScores[whoWon] += pointsNormal*ptsMult; CS_SetClientContributionScore(whoWon, playerScores[whoWon]);
			SetHudTextParams(-1.0, 0.7, restartDelay, 255, 180, 0, 255); 
			
			for(int i = 1; i < MAXPLAYERS; i++) if(IsClientInGame(i))
				if(holePar>0) 	ShowHudText(i, 3, "ROUND OVER\n\n%s has scored a %s!", winName, scoreName);
				else			ShowHudText(i, 3, "ROUND OVER\n\n%s has scored!", winName);
			
			if(holePar>0) 	PrintToChatAll(" \x10%s has scored a\x08 %s\x04 +%d point%c.", winName, scoreName, pointsNormal*ptsMult, theS);
			else			PrintToChatAll(" \x10%s has scored! \x04+%d point%c.", winName, pointsNormal*ptsMult, theS);
			CreateParticle
			(		
				holePosition[0],holePosition[1],holePosition[2],	
				0.0,0.0,0.0, 	
				"impact_gas_rocket_child07a", 2.0
			);
		}
	}
	else
	{
		SetHudTextParams(-1.0, 0.7, restartDelay, 255, 0, 0, 255); 
		for(int i = 1; i < MAXPLAYERS; i++) if(IsClientInGame(i))
			ShowHudText(i, 3, "ROUND OVER", turn); 
	}
	
	
	
	
	for(int i = 1; i < MAXPLAYERS; i++)
	{
		if(!IsClientInGame(i) || IsPlayerNotInATeam(i))
			continue;
		
		removeWeapons(i);
		playerPrevPos[i] = NULL_VECTOR;
		SetEntProp(i, Prop_Data, "m_nSolidType", 2);
		SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 500.0);
		SetEntityRenderMode(i, RENDER_NORMAL);
		GivePlayerItem(i, "weapon_knife", 0);
		
		if(i != whoWon)
		{
			GivePlayerItem(i, weaponLose, 0);
			SetEntityHealth(i, loserHealth);
		}
	}
	
	if(whoWon > 0 && IsClientInGame(whoWon))
	{
		GivePlayerItem(whoWon, weaponWin, 0);
		SetEntityHealth(whoWon, countPlayers()*winnerHealthFactor);
		
		float clientAngles[3] = {0.0,0.0,0.0};
		
		if(GetVectorLength(winPosition) == 0.0)						// No Win Position
			AddVectors(holePosition, winPosition, winPosition);
			
		if(GetVectorLength(winAngles) == 0.0)
			GetClientAbsAngles(whoWon, clientAngles);
		else
			AddVectors(winAngles, clientAngles, clientAngles);
		
		TeleportEntity(whoWon, winPosition, clientAngles, NULL_VECTOR); // obj, pos, angle, vel

		RemoveEdict(hole_mdl);
		setGlow(indicator_mdl, false);
	}
	
	holeOver = true;
	removeDecoys();
	
	// PreStart() for the actual score
	CS_TerminateRound(restartDelay, CSRoundEnd_TerroristsPlanted, false);
}

public bool checkAllPlayersPlayed()
{
	int amountOfDecoys = 0;
	for(int i = 1; i < MAXPLAYERS; i++)
	{
		if(IsClientInGame(i) && playerHasDecoy[i] && IsPlayerAlive(i) && !IsPlayerNotInATeam(i))
			amountOfDecoys++;
	}
	if(amountOfDecoys)
		return false;
	return true;
}
public bool noNadesInTheAir()
{
	int amountOfDecoys = 0;
	for(int i = 1; i < MAXPLAYERS; i++)
	{
		if(IsClientInGame(i) && playerCurrentDecoyProj[i] && !IsPlayerNotInATeam(i))
			amountOfDecoys++;
	}
	if(amountOfDecoys)
		return false;
	return true;
}
public void allPlayersPlayed()
{
	endTurn();
}



// =====================================================================
// HOLE

public void randomizePositions()
{
	holePosition[0] += randomPositionOffsetRadius(holeRadius);
	holePosition[1] += randomPositionOffsetRadius(holeRadius);
	spawnPosition[0] += randomPositionOffsetRadius(spawnRadius);
	spawnPosition[1] += randomPositionOffsetRadius(spawnRadius);
}

public void createHole()
{	
	float randAngles[3] = {0.0, 0.0, 0.0}; randAngles[1] = GetURandomFloat() * 360.0;
	float indicatorOff[3] = {0.0, 0.0, 192.0};
	AddVectors(holePosition, indicatorOff, indicatorOff);

	hole_mdl = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(hole_mdl, "model", "models/zool/strokestrike/trashcan.mdl");
	DispatchKeyValue(hole_mdl, "Solid", "6");
	DispatchSpawn(hole_mdl);
	TeleportEntity(hole_mdl, holePosition, randAngles, NULL_VECTOR); // obj, pos, angle, vel
	
	flag_mdl = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(flag_mdl, "model", "models/props/props_gameplay/capture_flag_pole.mdl");
	DispatchKeyValue(flag_mdl, "Solid", "0");
	DispatchKeyValue(flag_mdl, "DefaultAnim", "idle");
	DispatchSpawn(flag_mdl);
	TeleportEntity(flag_mdl, holePosition, randAngles, NULL_VECTOR); // obj, pos, angle, vel
	
	indicator_mdl = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(indicator_mdl, "model", "models/zool/strokestrike/indicator.mdl");
	DispatchKeyValue(indicator_mdl, "Solid", "0");
	DispatchKeyValue(indicator_mdl, "DefaultAnim", "challenge_coin_idle");
	DispatchSpawn(indicator_mdl);
	TeleportEntity(indicator_mdl, indicatorOff, NULL_VECTOR, NULL_VECTOR); // obj, pos, angle, vel
	setGlowColor(indicator_mdl, 0, 255, 0);	
}


// =====================================================================
// PLAYERS

public void removeWeapons(int client)
{
	for (int i = 0; i < 6; i++)
	{
		int weapon = GetPlayerWeaponSlot(client, i);
		if(weapon != -1)
			RemovePlayerItem(client, weapon);
	}
	playerHasDecoy[client] = false;
}
public void giveBall(int client)
{
	removeWeapons(client);
	GivePlayerItem(client, "weapon_decoy", 0);	
	playerHasDecoy[client] = true;
}
public void setupPlayer(int client)
{	
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || IsPlayerNotInATeam(client))
		return;
		
	SetEntProp(client, Prop_Data, "m_nSolidType", 1);
	TeleportEntity(client, spawnPosition, spawnAngles, NULL_VECTOR);
	SetEntityHealth(client, 100);
	GetClientAbsOrigin(client, playerPrevPos[client]);
	SetEntityRenderMode(client, RENDER_NONE);	// HIDE EM FOR THE FIRST THROW
	removeWeapons(client);
	
	if(keepPlayerModel)
	{
		
		if(playerModel[client] == 0)
		{
			char pm[128];
			GetClientModel(client,pm,sizeof(pm));
			playerModel[client] = PrecacheModel(pm, false);
		}
		SetEntProp(client, Prop_Send, "m_nModelIndex", playerModel[client]);
	}
}

// =====================================================================
// UTILITY

public bool isInRadius(float[3] entPos, float[3] origin, float radius)
{	
	if(GetVectorDistance(origin, entPos, false) <= radius)
		return true;
	return false;
}
public float randomPositionOffsetRadius(float radius)
{
	if(radius*2 < 32) 
		return 0.0;
	
	float offset = (GetURandomFloat()*radius*2)-radius;
	if(offset > 32)
		offset -= 32;
	else if(offset < -32)
		offset += 32;
	return offset;
}
stock bool:SplitStringR( const String:source[], const String:split[], String:part[], partLen ) 
{ 
	new index = StrContains( source, split );
	if( index == -1 ) 
		return false; 
	index += strlen( split );
	if( index == strlen( source )-1 ) 
		return false;
	strcopy( part, partLen, source[index] );
	return true; 
}
public int countPlayers()
{
	int count;
	for(int i = 1; i<MAXPLAYERS; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i) && !IsPlayerNotInATeam(i))
			count++;
	return count;
}
public void removeDecoys()
{
	char szClass[65];
	for (int i = MaxClients; i <= GetMaxEntities(); i++)
        if(IsValidEdict(i) && IsValidEntity(i))
        {
            GetEdictClassname(i, szClass, sizeof(szClass));
            if(StrEqual("decoy_projectile", szClass))
			{
				int client = GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity");
				playerCurrentDecoyProj[client] = 0;
				RemoveEdict(i);
			}
		}
}
public int nextHole(int current, int max)
{
	if(holeIsRandom) 
		return GetRandomInt(1,max);
	
	if(current == -1)
		return 1;
	
	if(max < 2)
		return 1;
	
	if(current == max)
		return 1;
	
	return ++current;
}
public bool removeDecoyIfPlayerDead(int client)
{
	if(IsClientInGame(client) && !IsPlayerAlive(client) && playerCurrentDecoyProj[client])
	{
		RemoveEdict(playerCurrentDecoyProj[client]);
		playerCurrentDecoyProj[client] = 0;
		return true;
	}
	return false;
}
public bool IsPlayerNotInATeam(int client)
{
	if(!IsClientInGame(client) || (GetClientTeam(client) != 2 && GetClientTeam(client) != 3))
		return true;
	return false;
}
public bool IsPlayerHoldingDecoy(int client)
{
	char weapName[16];
	GetClientWeapon(client, weapName, sizeof(weapName));
	if(!strcmp(weapName, "weapon_decoy", false))
		return true;
	return false;
}
public bool playerCanRollBack(int client)
{	
	float currentPosition[3];
	GetClientAbsOrigin(client, currentPosition);
	
	if(GetVectorLength(playerPrevPos[client]) == 0)
		return false;
	
	if(currentPosition[0] == playerPrevPos[client][0] && currentPosition[1] == playerPrevPos[client][1])
		return false;
	
	return true;
}
public void createMarker(float[3] pos)
{				
	int hole = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(hole, "model", "models/editor/axis_helper_thick.mdl");
	DispatchSpawn(hole);
	TeleportEntity(hole, pos, NULL_VECTOR, NULL_VECTOR); 
}
public bool hasConfigFolder()
{
	if(!DirExists(mapConfigPath, false, NULL_STRING))
	{
		PrintToServer("[STROKE STRIKE] No available configs, the map folder doesn't exist");
		return false;
	}
	return true;
}
public void setGlow(int entity, bool enable)
{
	SetEntProp(entity, Prop_Send, "m_bShouldGlow", enable, true);
}
public void setGlowColor(int entity, int r, int g, int b)
{
	if(r+g+b == 0)
	{
		SetEntProp(entity, Prop_Send, "m_bShouldGlow", false, true);
		return;
	}
	
	SetEntProp(entity, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(entity, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(entity, Prop_Send, "m_flGlowMaxDist", 10000000.0);
	int iOffset; if ((iOffset = GetEntSendPropOffs(entity, "m_clrGlow")) == -1) return;
	SetEntData(entity, iOffset, r, _, true);
	SetEntData(entity, iOffset + 1, g, _, true);
	SetEntData(entity, iOffset + 2, b, _, true);
	SetEntData(entity, iOffset + 3, 255, _, true);
}

public bool hasEmptyConfigFolder()
{	
	if(!hasConfigFolder()) 
		return true;

	int fileIndex = 0;
	char fileBuffer[4][48];
	DirectoryListing dL = OpenDirectory(mapConfigPath);
	
	while (dL.GetNext(fileBuffer[fileIndex], sizeof(fileBuffer)) && fileIndex < 3)
		fileIndex++;
	
	if(fileIndex-2 <= 0)
		return true;
	
	return false;
}

// --------------------------------------
// from TheUnderTaker's spawner, converted from entity to pos/rot
// https://forums.alliedmods.net/showthread.php?p=2331673
public void CreateParticle(float x, float y, float z, float rx, float ry, float rz, const char[] particleName, float time)
{
	float pos[3]; pos[0]=x; pos[1]=y; pos[2]=z;
	float rot[3]; rot[0]=rx; rot[1]=ry; rot[2]=rz;
	int particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, rot, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particleName);
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticle, particle);
    }
}
public Action:DeleteParticle(Handle timer, int particle)
{
    if (IsValidEntity(particle))
    {
        new String:classN[64];
        GetEdictClassname(particle, classN, sizeof(classN));
        if (StrEqual(classN, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
    }
}
// ---------------------------------

// -----------------------------
// functions by by gubka
// Get model index and prevent server from crash
// https://forums.alliedmods.net/showthread.php?t=273104
Weapon_GetViewModelIndex(client, sIndex)
{
    while ((sIndex = FindEntityByClassname2(sIndex, "predicted_viewmodel")) != -1)
    {
        new Owner = GetEntPropEnt(sIndex, Prop_Send, "m_hOwner");
        
        if (Owner != client)
            continue;
        
        return sIndex;
    }
    return -1;
}
// Get entity name
FindEntityByClassname2(sStartEnt, String:szClassname[])
{
    while (sStartEnt > -1 && !IsValidEntity(sStartEnt)) sStartEnt--;
    return FindEntityByClassname(sStartEnt, szClassname);
} 
// -----------------------------

// =====================================================================
// RESETTERS

public void clearHoleInfo()
{
	holeName = "";
	holeAuthor = "";
	holePosition = NULL_VECTOR;
	holeRadius = 0.0;
	holePar = -1;
	spawnPosition = NULL_VECTOR;
	spawnAngles = NULL_VECTOR;
	spawnRadius = 0.0;
	winPosition = NULL_VECTOR;
	winAngles = NULL_VECTOR;
}

public void resetPlayerArrays()
{
	for(int i = 1; i < MAXPLAYERS; i++)
	{
		playerHasDecoy[i] = 0;
		playerScores[i] = 0;
		for(int j = 0; j < 3; j++)
			playerPrevPos[i][j] = 0.0;
	}
}
public void resetMatch()
{
	resetPlayerArrays();
	currentHole = -1;
}




// =====================================================================
// CONFIG LOADER


// ----------------------------
// INIT


public void makeConfigPaths()
{
	BuildPath(Path_SM, dirPath, sizeof(dirPath), "configs/strokestrike/");
	if(!DirExists(dirPath, false, NULL_STRING))	CreateDirectory(dirPath, 511);
	
	GetCurrentMap(mapname, sizeof(mapname));
	SplitStringR(mapname, "/", mapname, sizeof(mapname)); SplitStringR(mapname, "/", mapname, sizeof(mapname));
	SplitStringR(mapname, "\\", mapname, sizeof(mapname)); SplitStringR(mapname, "\\", mapname, sizeof(mapname));
	
	strcopy(mapConfigPath, sizeof(mapConfigPath), dirPath);
	StrCat(mapConfigPath, PLATFORM_MAX_PATH, mapname);
	StrCat(mapConfigPath, PLATFORM_MAX_PATH, "/");
}

public void loadMapConfig()
{
	if(gamemodeDisabledEntirely)
		return;

	mapHasStroke = hasStrokeEntities();
	
	if(!getHoleCountConfig() && !mapHasStroke)
	{
		noConfigPrint();
		gamemodeUnavailable = true;
		gamemodeEnabled = false;
	}
	else
		gamemodeUnavailable = false;
}

public void printChatHoleInfo()
{
	PrintToChatAll(" ");
	PrintToChatAll(" ");
	PrintToChatAll(" ");
	PrintToChatAll(" \x10⠀---- ◁ STROKE STRIKE ▷ ------------------------------------");
	if(holePar > 0)
	PrintToChatAll(" \x01⠀⠀⠀[%d/%d]\x04 %s\x08 <Par %d>", currentHole, holeCount, holeName, holePar);
	else
	PrintToChatAll(" \x01⠀⠀⠀[%d/%d]\x04 %s", currentHole, holeCount, holeName);
	if(strcmp(holeAuthor,""))	
	PrintToChatAll(" \x05⠀⠀⠀⠀⠀by \x06%s", holeAuthor);
	PrintToChatAll(" \x10⠀----------------------------------------------------------------------");
	PrintToChatAll(" ");
	PrintToChatAll(" ");
}



// ----------------------------
// READ

public bool hasStrokeEntities()
{
	if(forceConfig)
		return false;
	
	char szClass[65];
	for (int i = MaxClients; i <= GetMaxEntities(); i++)
        if(IsValidEdict(i) && IsValidEntity(i))
        {
			GetEdictClassname(i, szClass, sizeof(szClass));
			if(!StrEqual("info_teleport_destination", szClass))
				continue;
			
			char targetname[14];
			GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
			
			if(StrEqual("stroke_spawn1", targetname))
				return true;
		}
	return false;
}


public void readConfig()
{	
	holeCount = getHoleCount();
	
	if(holeCount == 0 && gamemodeUnavailable)
		return;
	
	currentHole = nextHole(currentHole, holeCount); //GetRandomInt(1,holeCount);
	
	if(debugMode)
	{
		PrintToServer("\n");
		PrintToServer("[STROKE STRIKE] Config: %s", mapname);
		PrintToServer("- Holes in this map: %d", holeCount);
		PrintToServer("- Hole chosen: %d", currentHole);
		PrintToServer("\n");
	}
	
	getHoleInfo(currentHole);
}



// ----------------------------
// INFO

public void getHoleInfo(int holeNumber)
{
	if(mapHasStroke)
		getMapHoleInfo(holeNumber);
	else
		getConfigHoleInfo(holeNumber);
	
	if(!enablePar) holePar = -1;
}

public void getMapHoleInfo(int holeNumber)
{
	char szClass[65];
	char strHoleNumber[4]; IntToString(holeNumber, strHoleNumber, sizeof(strHoleNumber));
	
	for (int i = MaxClients; i <= GetMaxEntities(); i++) if(IsValidEdict(i) && IsValidEntity(i))
	{
		GetEdictClassname(i, szClass, sizeof(szClass));
		if	(	!StrEqual("info_teleport_destination", szClass) &&
				!StrEqual("info_target", szClass) &&
				!StrEqual("env_message", szClass) 
			)
			continue;
			
		char targetname[30] = ""; GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
		
		if(StrEqual("info_teleport_destination", szClass))
		{
			char targetnameLookingFor[30] = "stroke_spawn";
			StrCat(targetnameLookingFor, sizeof(targetnameLookingFor), strHoleNumber);
			
			if(StrEqual(targetnameLookingFor, targetname))
			{
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", spawnPosition);
				GetEntPropVector(i, Prop_Data, "m_angRotation", spawnAngles);
				continue;
			}
			else
			{
				strcopy(targetnameLookingFor, sizeof(targetnameLookingFor), "stroke_win");
				StrCat(targetnameLookingFor, sizeof(targetnameLookingFor), strHoleNumber);
				
				if(StrEqual(targetnameLookingFor, targetname))
				{
					GetEntPropVector(i, Prop_Data, "m_vecOrigin", winPosition);
					GetEntPropVector(i, Prop_Data, "m_angRotation", winAngles);
					continue;
				}
			}
		}
		
		if(StrEqual("info_target", szClass))
		{
			char targetnameLookingFor[30] = "stroke_hole";
			StrCat(targetnameLookingFor, sizeof(targetnameLookingFor), strHoleNumber);
			
			if(StrEqual(targetnameLookingFor, targetname))
			{
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", holePosition);
				continue;
			}
		}
		
		if(StrEqual("env_message", szClass))
		{
			char targetnameLookingFor[30] = "stroke_info";
			StrCat(targetnameLookingFor, sizeof(targetnameLookingFor), strHoleNumber);
			
			if(StrEqual(targetnameLookingFor, targetname))
			{
				char message[128] = "";
				char parts[3][64] = {"","","-1"};
				GetEntPropString(i, Prop_Data, "m_iszMessage", message, sizeof(message));
				ExplodeString(message, "/", parts, sizeof(parts), 64, false);	
				strcopy(holeName, sizeof(holeName), parts[0]);
				strcopy(holeAuthor, sizeof(holeName), parts[1]);
				StringToInt(parts[2], holePar);
				continue;
			}
		}
	}
}

public int getFileHoleFromHoleNumber(int holeNumber)
{
	if(!hasConfigFolder())
		return -1;
	
	char fileBuffer[512][48];
	DirectoryListing dL = OpenDirectory(mapConfigPath);
	
	int fileIndex = 0;
	int currentHoleCount = 0;
	while (dL.GetNext(fileBuffer[fileIndex], sizeof(fileBuffer))) 
	{
		for(int i = 0; i < holeCountFile[fileIndex]; i++)
		{
			if(++currentHoleCount == holeNumber)
			{
				strcopy(holeFileName, sizeof(holeFileName), fileBuffer[fileIndex]);
				if(debugMode) PrintToServer("[STROKE STRIKE] hole %d is inside %s as its hole %d", holeNumber, fileBuffer[fileIndex], i+1);
				return i;
			}
		}
		fileIndex++;
	}
	return -1;
}

public void getConfigHoleInfo(int globalHoleNumber)
{
	if(!hasConfigFolder() || hasEmptyConfigFolder())
		return;
	
	int holeIndex = 0;
	int holeTest = 0;
	char buffer[256];
	
	int holeNumber = getFileHoleFromHoleNumber(globalHoleNumber);
	
	char filePath[PLATFORM_MAX_PATH];
	strcopy(filePath, sizeof(filePath), mapConfigPath);
	StrCat(filePath, sizeof(filePath), holeFileName);
	
	if(debugMode) PrintToServer("> Loading Hole %d", holeNumber);
	
	File fileHandle = OpenFile(filePath, "r", false, NULL_STRING);
	if(!fileHandle)	PrintToServer("[STROKE STRIKE] Couldn't load %s", filePath);
	
	while(!IsEndOfFile(fileHandle))
	{
		while(holeIndex < holeNumber && !IsEndOfFile(fileHandle))
		{
			ReadFileLine(fileHandle, buffer, sizeof(buffer)); TrimString(buffer);
			if(strcmp(buffer, "hole", false) == 0)
			{
				ReadFileLine(fileHandle, buffer, sizeof(buffer)); TrimString(buffer);
				if(strcmp(buffer, "{", false) == 0)
					holeIndex++;
			}
			
			if(holeTest > 200000)
			{
				PrintToServer("\n[STROKE STRIKE] ERROR: %s has a leak, missing argument or unclosed scope?", filePath);
				CloseHandle(fileHandle);
				return;
			}
			holeTest++;
		}
		if(debugMode) PrintToServer("\tfound Hole %d", holeIndex);
		
		char element[16];
		while(strcmp(buffer, "}", false) != 0 && !IsEndOfFile(fileHandle))
		{
			strcopy(element, sizeof(element), buffer);
			ReadFileLine(fileHandle, buffer, sizeof(buffer)); TrimString(buffer);
			if(strcmp(buffer, "[", false) == 0)
			{
				char key[16];
				while(strcmp(buffer, "]", false) != 0 && !IsEndOfFile(fileHandle))
				{
					ReadFileLine(fileHandle, buffer, sizeof(buffer)); TrimString(buffer);
					SplitString(buffer, ":", key, sizeof(key));	TrimString(key);
					if(!strlen(key))
						continue;
					
					char values[64];
					char vector[3][16];
					float vectorFloat[3];
					
					SplitStringR(buffer, ": ", values, sizeof(values));
					ExplodeString(values, " ", vector, sizeof(vector), 16, false);		

					for(int i = 0; i < sizeof(vectorFloat); i++)
						vectorFloat[i] = StringToFloat(vector[i]);
					
					
					
					// DIFFERENT ELEMENTS					
					if(strcmp(element, "hole", false) == 0)
					{
						if(strcmp(key, "position", false) == 0)
							for(int i = 0; i < sizeof(vectorFloat); i++)
								holePosition[i] = vectorFloat[i];
						else if(strcmp(key, "radius", false) == 0)
							holeRadius = StringToFloat(values);							
					}				
					else if(strcmp(element, "spawn", false) == 0)
					{
						if(strcmp(key, "position", false) == 0)
							for(int i = 0; i < sizeof(vectorFloat); i++)
								spawnPosition[i] = vectorFloat[i];		
						else if(strcmp(key, "rotation", false) == 0)
							for(int i = 0; i < sizeof(vectorFloat); i++)
								spawnAngles[i] = vectorFloat[i];	
						else if(strcmp(key, "radius", false) == 0)
							spawnRadius = StringToFloat(values);								
					}				
					else if(strcmp(element, "win", false) == 0)
					{
						if(strcmp(key, "position", false) == 0)
							for(int i = 0; i < sizeof(vectorFloat); i++)
								winPosition[i] = vectorFloat[i];		
						else if(strcmp(key, "rotation", false) == 0)
							for(int i = 0; i < sizeof(vectorFloat); i++)
								winAngles[i] = vectorFloat[i];							
					}			
					else if(strcmp(element, "info", false) == 0)
					{						
						if(strcmp(key, "name", false) == 0)
							strcopy(holeName, sizeof(holeName), values);
						else if(strcmp(key, "author", false) == 0)
							strcopy(holeAuthor, sizeof(holeAuthor), values);
						else if(strcmp(key, "par", false) == 0)
						{
							SplitStringR(buffer, ":", values, sizeof(values));
							holePar = StringToInt(values, 10);
						}
					}
					
					if(debugMode) 
					{
						if(vectorFloat[0] + vectorFloat[1] + vectorFloat[2] != 0.0)
							PrintToServer("\t\t\t {%s} \t[%s] \t%f %f %f", element, key, vectorFloat[0], vectorFloat[1], vectorFloat[2]);
						else
							PrintToServer("\t\t\t {%s} \t[%s] \t%s", element, key, values);
					}
					key = "";
					
					
					
					if(holeTest > 200000)
					{
						PrintToServer("\n[STROKE STRIKE] ERROR: %s's Config file has a leak, missing argument or unclosed scope? ('[]' ATTRIBUTE PART)", mapname);
						CloseHandle(fileHandle);
						return;
					}
					holeTest++;
					
				}
			}
			
			
			
			
			if(holeTest > 200000)
			{
				PrintToServer("\n[STROKE STRIKE] ERROR: %s's Config file has a leak, missing argument or unclosed scope? ('}' END HOLE PART)", mapname);
				CloseHandle(fileHandle);
				return;
			}
			holeTest++;	
		}
		if(debugMode) PrintToServer("\tfound }");
		
		ReadFileLine(fileHandle, buffer, sizeof(buffer));
		break;
	}
	CloseHandle(fileHandle);
}




// ----------------------------
// COUNT

public int getHoleCount()
{
	if(mapHasStroke)
		return getHoleCountMap();
	else 
		return getHoleCountConfig();
}

public int getHoleCountMap()
{
	int CountHole = 0;
	char szClass[65];
	for (int i = MaxClients; i <= GetMaxEntities(); i++)
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, szClass, sizeof(szClass));
			if(!StrEqual("info_teleport_destination", szClass))
				continue;
			
			char targetname[13];
			GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
			
			if(StrEqual("stroke_spawn", targetname))
				CountHole++;
		}
	return CountHole;
}
public int getHoleCountConfig()
{
	if(!hasConfigFolder() || hasEmptyConfigFolder())
		return 0;

	for(int i = 0; i < sizeof(holeCountFile); i++)	// Reset hole count
		holeCountFile[i] = 0;
	
	int fileCounter = 0;
	char fileBuffer[512][48];
	DirectoryListing dL = OpenDirectory(mapConfigPath);
	
	int fileIndex = 0;
	
	if(debugMode) PrintToServer(" ");
	if(debugMode) PrintToServer("[STROKE STRIKE] Available Configs:");
	
	while (dL.GetNext(fileBuffer[fileIndex], sizeof(fileBuffer)))
	{
		if(StrContains(fileBuffer[fileIndex], ".txt", false) != -1)
		{
			if(fileHasHoleConfig(fileBuffer[fileIndex], fileIndex))
			{
				if(debugMode) PrintToServer("\tFILE: [CONFIG] [%d] %s - %d holes", fileIndex, fileBuffer[fileIndex], holeCountFile[fileIndex]);
				fileCounter++;
			}
			else
				if(debugMode) PrintToServer("\tFILE: [------] [%d] %s", fileIndex, fileBuffer[fileIndex]);
		}
		fileIndex++;
    }
	if(debugMode) PrintToServer("There was %d valid config.", fileCounter);
	
	int CountHole = 0;
	for(int i = 0; i < sizeof(holeCountFile); i++)
		CountHole += holeCountFile[i];
	
	if(debugMode) PrintToServer("%d holes are available to be played on.", fileCounter);
	if(debugMode) PrintToServer(" ", fileCounter);
	
	return CountHole;
}

public bool fileHasHoleConfig(const char[] fileName, int fileIndex)
{
	char filePath[PLATFORM_MAX_PATH];
	strcopy(filePath, sizeof(filePath), mapConfigPath);
	StrCat(filePath, sizeof(filePath), fileName);
	
	File fileHandle = OpenFile(filePath, "r", false, NULL_STRING);
	if(!fileHandle)	PrintToServer("[STROKE STRIKE] Couldn't load %s", filePath);
	
	if(!fileHandle)
	{
		if(debugMode) PrintToServer("%s couldn't be opened", filePath);
		CloseHandle(fileHandle);
		return false;
	}
	
	// -----------------------------------------------------------------------------------
	// CHECK VALID
	bool foundHole = false;
	bool foundOpenBracket = false;
	bool foundClosedBracket = false;
	while(!IsEndOfFile(fileHandle))
	{
		char buffer[16];
		ReadFileLine(fileHandle, buffer, sizeof(buffer)); TrimString(buffer);
		if(!foundHole && StrContains(buffer, "hole", false) != -1) foundHole = true;
		if(!foundOpenBracket && StrContains(buffer, "{", false) != -1) foundOpenBracket = true;
		if(!foundClosedBracket && StrContains(buffer, "{", false) != -1) foundClosedBracket = true;
	}
	
	// -----------------------------------------------------------------------------------
	// Assign Holes Count
	FileSeek(fileHandle, 0, SEEK_SET);
	while(!IsEndOfFile(fileHandle))
	{
		char buffer[16];
		ReadFileLine(fileHandle, buffer, sizeof(buffer)); TrimString(buffer);
		if(strcmp(buffer, "hole", false) == 0)
		{
			ReadFileLine(fileHandle, buffer, sizeof(buffer)); TrimString(buffer);
			if(strcmp(buffer, "{", false) == 0)
				holeCountFile[fileIndex]++;
		}
	}
	CloseHandle(fileHandle);
	
	return (foundHole && foundOpenBracket && foundClosedBracket);
}




// =====================================================================
// COMMANDS

public Action Command_printGolfers(int client, int args)
{
	if (gamemodeNotRunningError())
		return;
	
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if(!IsClientInGame(i) || IsPlayerNotInATeam(i))
			continue;
		
		char name[32];
		GetClientName(i, name, 32);
		
		ReplyToCommand(0, "\t%s: \n\t\tplayerHasDecoy: %d   \n\t\tplayerCurrentDecoyProj: %d   \n\t\tplayerScores: %d    \n\t\tplayerViewmodel: %d   \n\t\tplayerPrevPos: %f %f %f", name, playerHasDecoy[i], playerCurrentDecoyProj[i], playerScores[i],  playerViewmodel[i],   playerPrevPos[i][0],playerPrevPos[i][1],playerPrevPos[i][2]   );
	}
}

public Action Command_setDebug(int client, int args)
{
	if(!GetCmdArgs())
	{
		ReplyToCommand(0,"[STROKE STRIKE] Enable/Disable Debug Mode. 0 to disable, 1 to enable");	
		ReplyToCommand(0, "sm_golfdebug is %d", debugMode);
		return;
	}
	char buffer[2];	GetCmdArg(1,buffer,sizeof(buffer));
	int param = StringToInt(buffer, 10);	
	debugMode = (param != 0);
	
	if(debugMode)
	{
		if(client)ReplyToCommand(0,"[STROKE STRIKE] Debug Mode enabled");
		ReplyToCommand(client,"[STROKE STRIKE] Debug Mode enabled");
	}
	else 
	{
		if(client)ReplyToCommand(0,"[STROKE STRIKE] Debug Mode disabled");
		ReplyToCommand(client,"[STROKE STRIKE] Debug Mode disabled");
	}
}

public Action Command_golfedithelp(int client, int args)
{
	ReplyToCommand(client, "[STROKE STRIKE] Check your console");
	
	golfhelpPart(client,0);
	PrintToConsole(client, "|----------------------------------------- [Edit Cmds] ------------------------------------------|");
	PrintToConsole(client, " ");
	PrintToConsole(client, " sm_golf <0/1/2>\t\t\t-\tEnable/Disable the gamemode. 0: Disabled, 1: Enabled, 2: Edit Mode");
	PrintToConsole(client, " ");
	PrintToConsole(client, " sm_golfedit\t\t\t\t-\tShow edit mode's quick placement menu.");
	PrintToConsole(client, " ");
	PrintToConsole(client, " sm_golfeditspawn\t\t\t-\tPlace the spawn at your current position.");
	PrintToConsole(client, " sm_golfedithole\t\t\t-\tPlace the hole at your current position.");
	PrintToConsole(client, " sm_golfeditwin\t\t\t\t-\tPlace the winner's spawn at your current position.");
	PrintToConsole(client, " ");
	PrintToConsole(client, " sm_golfeditspawnradius <size>\t\t-\tSet the spawn's origin randomizer radius.");
	PrintToConsole(client, " sm_golfeditholeradius <size>\t\t-\tSet the hole's origin randomizer radius.");
	PrintToConsole(client, " ");
	PrintToConsole(client, " sm_golfeditinfo <name> <author> [par]\t-\tSet the Name, the Author(s) and the Par of the current hole.");
	PrintToConsole(client, " sm_golfeditsave <filename>\t\t-\tSave the current hole.");
	PrintToConsole(client, " sm_golfeditdel <filename>\t\t-\tDelete a named hole file.");
	PrintToConsole(client, " sm_golfeditload <hole number>\t\t-\tLoad a specific hole number.");
	PrintToConsole(client, " ");
	PrintToConsole(client, "\tFor a config to be valid, you need at least a Spawn, Hole, Name, Author.");
	PrintToConsole(client, "\tUsing save or del without argument will display the existing names.");
	PrintToConsole(client, " ");
	golfhelpPart(client,1);
	
	return Plugin_Handled;
}
public Action Command_golfhelp(int client, int args)
{
	ReplyToCommand(client, "[STROKE STRIKE] Check your console");
	
	golfhelpPart(client,0);
	PrintToConsole(client, "|----------------------------------------- [Admin Cmds] -----------------------------------------|");
	PrintToConsole(client, " ");
	PrintToConsole(client, " sm_golf <0/1/2>\t\t\t-\tEnable/Disable the gamemode. 0: Disabled, 1: Enabled, 2: Edit Mode");
	PrintToConsole(client, " ");
	PrintToConsole(client, " sm_golfedithelp\t\t\t-\tShow edit mode's help.");
	PrintToConsole(client, " ");
	PrintToConsole(client, " sm_golfstroketime <seconds>\t\t-\tTime between strokes, once time is up, you get damaged and the next throw starts.");
	PrintToConsole(client, " sm_golfgoto <hole>\t\t\t-\tGo to a specific hole number.");
	PrintToConsole(client, " sm_golfrestart\t\t\t\t-\tRestart the course entirely (reset scores, course progress etc..).");
	PrintToConsole(client, " sm_golfwinhp <health>\t\t\t-\tSet the health multiplicator for the winner based on the number of alive golfers.");
	PrintToConsole(client, " sm_golflosehp <health>\t\t\t-\tSet the health for the losing players.");
	PrintToConsole(client, " sm_golfweapons <loser> <winner>\t-\tSet the weapons for the losers and winner. (eg. weapon_ak47).");
	PrintToConsole(client, " sm_golfrandom <0/1>\t\t\t-\tRandomize hole orders. 0 for disabled, 1 for enabled.");
	PrintToConsole(client, " sm_golfpar <0/1>\t\t\t-\tUse Par in scoring. 0 for disabled, 1 for enabled.");
	PrintToConsole(client, " sm_golfallowback <0/1>\t\t\t-\tAllow players to go back to their previous position. 0 disabled, 1 enabled.");
	PrintToConsole(client, " sm_golfforcect <0/1>\t\t\t-\tForce players to be moved to the CT team, it makes the scoreboard more readable for scores");
	PrintToConsole(client, " sm_golfkeeppm <0/1>\t\t\t-\tKeep the playermodel from the first team the player has joined. Used with sm_golfforcect");
	PrintToConsole(client, " ");
	golfhelpPart(client,1);
	
	return Plugin_Handled;
}
public void golfhelpPart(int client, int part)
{
	if(part == 0)
	{
		PrintToConsole(client, " ");
		PrintToConsole(client, " ");
		PrintToConsole(client, " ");
		PrintToConsole(client, "/--------------------------------------- [STROKE STRIKE] ---------------------------------------\\");
		return;
	}
	else if(part == 1)
	{
		PrintToConsole(client, " [v%s] [%s]",PLUGIN_VERSION,PLUGIN_LINK);
		PrintToConsole(client,"\\-----------------------------------------------------------------------------------------------/");
		PrintToConsole(client, " ");
		PrintToConsole(client, " ");
		PrintToConsole(client, " ");
		return;
	}
}

public Action Command_golfeditload(int client, int args)
{
	if(gamemodeNotEditError(client))
		return Plugin_Handled;
	
	Command_setHole(client, args);
	return Plugin_Handled;
}

public Action Command_setHole(int client, int args)
{	
	if(!GetCmdArgs())
	{
		ReplyToCommand(client, "[STROKE STRIKE] Go to a specific hole number.");	
		return Plugin_Handled;
	}
	char buffer[3];
	GetCmdArg(1,buffer,sizeof(buffer));
	int param = StringToInt(buffer, 10);	
	
	if(holeIsRandom)
	{
		ReplyToCommand(client, "[STROKE STRIKE] Impossible to go to a specific hole if the order is random!");
		return Plugin_Handled;
	}
	
	holeCount = getHoleCount();
	
	if(param < 1 || param > holeCount)
	{
		if(!holeCount)
			ReplyToCommand(client, "[STROKE STRIKE] Hole %d doesn't exist. In fact there's no hole available here", param);
		else if(holeCount == 1)
			ReplyToCommand(client, "[STROKE STRIKE] Hole %d doesn't exist. There is only 1 hole", param);
		else
			ReplyToCommand(client, "[STROKE STRIKE] Hole %d doesn't exist. Available holes are between: 1 and %d.", param, holeCount);
		return Plugin_Handled;
	}
	
	currentHole = param-1;
	
	
	if(editEnabled)
	{
		if(editwin_mdl == -1) return Plugin_Handled;	// if you type the command before edit loaded.
		
		clearHoleInfo();
		getHoleInfo(param);
		editMoveObjects();
		PrintToChatAll(" \x0A[STROKE STRIKE] {EDIT} Moving to hole %d...", param);
		EmitSoundToAll("survival/zone_chosen_by_other.wav");
		for(int i = 1; i<MAXPLAYERS; i++)
			if(IsClientInGame(i))
				TeleportEntity(i, spawnPosition, spawnAngles, NULL_VECTOR);
	}
	else 
	{
		PrintToServer("[STROKE STRIKE] Moving to hole %d...", param);
		PrintToChatAll(" \x10[STROKE STRIKE] Moving to hole %d...", param);
		ServerCommand("mp_restartgame 1");
	}
	
	return Plugin_Handled;
}

public Action Command_allowBack(int client, int args)
{
	if(!GetCmdArgs())
	{
		ReplyToCommand(client, "[STROKE STRIKE] Allow teleporting back to your previous position. 0 off, 1 on");	
		ReplyToCommand(client, "sm_golfallowback is %d", allowTeleportBack);
		return Plugin_Handled;
	}
	char buffer[2]; GetCmdArg(1,buffer,sizeof(buffer));
	int param = StringToInt(buffer, 10);
	allowTeleportBack = (param != 0);
	
	if(allowTeleportBack)
		ReplyToCommand(client, "[STROKE STRIKE] Players are now able to teleport back");
	else 
		ReplyToCommand(client, "[STROKE STRIKE] Players cannot teleport back anymore");
	return Plugin_Handled;
}

public Action Command_keepplayermodel(int client, int args)
{
	if(!GetCmdArgs())
	{
		ReplyToCommand(client, "[STROKE STRIKE] Players joining a team will keep the same playermodel after being moved to CT (if sm_golfforcect is enabled). 0 off, 1 on");	
		ReplyToCommand(client, "sm_golfkeeppm is %d", keepPlayerModel);
		return Plugin_Handled;
	}
	char buffer[2]; GetCmdArg(1,buffer,sizeof(buffer));
	int param = StringToInt(buffer, 10);
	keepPlayerModel = (param != 0);
	
	if(keepPlayerModel)
		ReplyToCommand(client, "[STROKE STRIKE] Players are now keeping their first playermodel");
	else 
	{
		for(int i = 1; i<MAXPLAYERS; i++) playerModel[i] = 0;
		ReplyToCommand(client, "[STROKE STRIKE] Players are no longer keeping their playermodel");
	}
	return Plugin_Handled;
}

public Action Command_forceCT(int client, int args)
{
	if(!GetCmdArgs())
	{
		ReplyToCommand(client, "[STROKE STRIKE] Players joining a team will be automatically moved to CT for a better score visibility on the scoreboard. 0 off, 1 on");	
		ReplyToCommand(client, "sm_golfforcect is %d", forceCT);
		return Plugin_Handled;
	}
	char buffer[2]; GetCmdArg(1,buffer,sizeof(buffer));
	int param = StringToInt(buffer, 10);
	forceCT = (param != 0);
	
	if(forceCT)
		ReplyToCommand(client, "[STROKE STRIKE] Players will be moved to the CT team");
	else 
		ReplyToCommand(client, "[STROKE STRIKE] Players will no longer be moved to CT");
	return Plugin_Handled;
}

public Action Command_forceconfig(int client, int args)
{
	if(!GetCmdArgs())
	{
		ReplyToCommand(client, "[STROKE STRIKE] Hole configs will be loaded even if the map has entities for Stroke Strike. 0 off, 1 on");	
		ReplyToCommand(client, "sm_golfforceconfig is %d", forceConfig);
		return Plugin_Handled;
	}
	char buffer[2]; GetCmdArg(1,buffer,sizeof(buffer));
	int param = StringToInt(buffer, 10);
	forceConfig = (param != 0);
	
	if(forceConfig)
		ReplyToCommand(client, "[STROKE STRIKE] Dedicated map entities for Stroke Strike wont be used anymore");
	else 
		ReplyToCommand(client, "[STROKE STRIKE] Hole configs are now determinated by the map's dedicated Stroke Strike entities if present");
	return Plugin_Handled;
}

public Action Command_enablePar(int client, int args)
{
	if(!GetCmdArgs())
	{
		ReplyToCommand(client, "[STROKE STRIKE] Pars wont be loaded, 1 point will be added on a normal scoring. 0 off, 1 on");	
		ReplyToCommand(client, "sm_golfpar is %d", enablePar);
		return Plugin_Handled;
	}
	char buffer[2]; GetCmdArg(1,buffer,sizeof(buffer));
	int param = StringToInt(buffer, 10);
	enablePar = (param != 0);
	
	if(enablePar)
		ReplyToCommand(client, "[STROKE STRIKE] Pars will loaded and used in scoring");
	else 
		ReplyToCommand(client, "[STROKE STRIKE] Pars wont load and wont be used in scoring");
	return Plugin_Handled;
}

public Action Command_setRandom(int client, int args)
{
	if(!GetCmdArgs())
	{
		ReplyToCommand(client, "[STROKE STRIKE] Play holes in a random order. 0 for ordered, 1 for random");
		ReplyToCommand(client, "sm_golfrandom is %d", holeIsRandom);
		return Plugin_Handled;
	}
	char buffer[2];	GetCmdArg(1,buffer,sizeof(buffer));
	int param = StringToInt(buffer, 10);
	holeIsRandom = (param != 0);
	
	if(holeIsRandom)
		ReplyToCommand(client, "[STROKE STRIKE] Holes are now in a random order");
	else 
		ReplyToCommand(client, "[STROKE STRIKE] Holes are now ordered");
	return Plugin_Handled;
}

public Action setGamemode(int client, int param)
{
	if(param == -1)
	{
		ReplyToCommand(client, "[STROKE STRIKE] Use sm_golfhelp to list the available commands");
		ReplyToCommand(client, "sm_golf is %d", !gamemodeDisabledEntirely);	
		return Plugin_Handled;
	}
	
	editEnabled = false;
	if(param == 1)
	{
		gamemodeDisabledEntirely = false;
		gamemodeEnabled = true;
		loadMapConfig();
		if(gamemodeUnavailable) 
		{
			ReplyToCommand(client, "[STROKE STRIKE] Impossible, there is no available courses for this map!");
			return Plugin_Handled;
		}
		ReplyToCommand(client, "[STROKE STRIKE] Gamemode Enabled");
		ServerCommand("mp_restartgame 2");
		setCommands();
	}
	else
	{
		if(param == 0) ReplyToCommand(client, "[STROKE STRIKE] Gamemode Disabled");
		if(param == 0) ServerCommand("mp_restartgame 2");
		if(param == 2) editEnabled = true;
		gamemodeDisabledEntirely = true;
		gamemodeEnabled = false;
		if(commandsAltered)
			resetCommands();
		
		for(int i = 1; i<MAXPLAYERS; i++)
			if(IsClientInGame(i))
				SetEntityRenderMode(i, RENDER_NORMAL);
			
		if(param == 2)
		{
			ReplyToCommand(0, "[STROKE STRIKE] Edit Mode Enabled");
			ServerCommand("mp_roundtime 99"); 
			ServerCommand("mp_roundtime_defuse 99");
			ServerCommand("mp_roundtime_hostage 99");
			ServerCommand("mp_freezetime 0");
			ServerCommand("mp_respawn_on_death_ct 1");
			ServerCommand("mp_respawn_on_death_t 1");
			ServerCommand("mp_randomspawn 1");
			ServerCommand("mp_radar_showall 1");
			ServerCommand("mp_warmup_end");
			ServerCommand("bot_kick");
			ServerCommand("mp_ct_default_secondary weapon_deagle");
			ServerCommand("mp_t_default_secondary weapon_deagle");
			ServerCommand("mp_ct_default_grenades weapon_decoy");
			ServerCommand("mp_t_default_grenades weapon_decoy");
			ServerCommand("sv_infinite_ammo 1");
			ServerCommand("mp_give_player_c4 0");
			ServerCommand("mp_hostages_max 0");
			ServerCommand("mp_buytime 0");
			ServerCommand("mp_defuser_allocation 0");
			ServerCommand("sv_ignoregrenaderadio 1");
			ServerCommand("mp_teammates_are_enemies 1");
			ServerCommand("mp_playercashawards 0");
			ServerCommand("mp_teamcashawards 0");
			ServerCommand("mp_restartgame 1");
			commandsAltered = true;
		}
	}
	return Plugin_Handled;
} 
public Action Command_setGamemode(int client, int args)
{
	char buffer[2];	GetCmdArg(1,buffer,sizeof(buffer));
	int param = StringToInt(buffer, 10);
	if(args<1)
		setGamemode(client, -1);
	else
		setGamemode(client, param);
}

public Action Command_restartCourse(int client, int args)
{
	if (gamemodeNotRunningError())
		return Plugin_Handled;
	
	resetMatch();
	ReplyToCommand(0, "[STROKE STRIKE] Restarting the course...");
	ServerCommand("mp_restartgame 1");
	PrintToChatAll(" \x10[STROKE STRIKE] Restarting the course...");
	return Plugin_Handled;
}

public Action Command_weapons(int client, int args)
{
	if(!GetCmdArgs() || args < 2)
	{
		ReplyToCommand(client, "[STROKE STRIKE] Current weapons:");	
		ReplyToCommand(client, "- Loser weapon: [%s]", weaponLose);	
		ReplyToCommand(client, "- Winner weapon: [%s]", weaponWin);	
		ReplyToCommand(client, " ");	
		ReplyToCommand(client, "usage: sm_golfweapons <loser weapon class> <winner weapon class>");	
		return Plugin_Handled;
	}
	
	GetCmdArg(1,weaponLose,sizeof(weaponLose));
	GetCmdArg(2,weaponWin,sizeof(weaponWin));
	
	ReplyToCommand(client, "[STROKE STRIKE] Weapons have been set!");	
	ReplyToCommand(client, "- Loser weapon: [%s]", weaponLose);	
	ReplyToCommand(client, "- Winner weapon: [%s]", weaponWin);	
	
	return Plugin_Handled;
}

public Action Command_healthPerPlayerWin(int client, int args)
{
	if(!GetCmdArgs())
	{
		ReplyToCommand(client, "[STROKE STRIKE] Health per player for the winner");	
		ReplyToCommand(client, "sm_golfwinhp is %d", winnerHealthFactor);		
		return Plugin_Handled;
	}
		
	char buffer[6];	GetCmdArg(1,buffer,sizeof(buffer));
	int param = StringToInt(buffer, 10);
		
	if(param < 1)
		winnerHealthFactor = 1;
	else 
		winnerHealthFactor = param;
	
	ReplyToCommand(client, "[STROKE STRIKE] The winner's health will now be: %d * playercount", winnerHealthFactor);	
	return Plugin_Handled;
}

public Action Command_healthLoser(int client, int args)
{
	if(!GetCmdArgs())
	{
		ReplyToCommand(client, "[STROKE STRIKE] Health count for losers");	
		ReplyToCommand(client, "sm_golflosehp is %d", loserHealth);		
		return Plugin_Handled;
	}
		
	char buffer[6];	GetCmdArg(1,buffer,sizeof(buffer));
	int param = StringToInt(buffer, 10);
		
	if(param < 1)
		loserHealth = 1;
	else 
		loserHealth = param;
	
	ReplyToCommand(client, "[STROKE STRIKE] The losers' health will now be %dhp", loserHealth);	
	return Plugin_Handled;
}

public Action Command_strokeTime(int client, int args)
{
	if(!GetCmdArgs())
	{
		ReplyToCommand(client, "[STROKE STRIKE] Time allowed between strokes, default: 5");		
		ReplyToCommand(client, "sm_golfstroketime is %d", turnTimeMax);				
		return Plugin_Handled;
	}
		
	char buffer[3];	GetCmdArg(1,buffer,sizeof(buffer));
	int param = StringToInt(buffer, 10);
		
	if(param < 3)
		turnTimeMax = 3;
	else if(param > 99)
		turnTimeMax = 99;
	else 
		turnTimeMax = param;
	
	ReplyToCommand(client, "[STROKE STRIKE] Stroke time limit is now: %d", turnTimeMax);	
	return Plugin_Handled;
}

public void Command_golfeditobj(int client, char type)
{	
	if(client == 0 || !IsClientInGame(client))
	{
		ReplyToCommand(client, "[STROKE STRIKE] I can't do that, you're not ingame, I use the client's transforms");	
		return;
	}
	if(gamemodeNotEditError(client)) return;
	
	float position[3];
	float rotation[3];
	bool removed = false;
	GetClientAbsOrigin(client, position);
	GetClientEyeAngles(client, rotation);

	PrintToChatAll(" ");
	switch(type)
	{
		case 's':
		{
			spawnPosition[0]=position[0];spawnPosition[1]=position[1];spawnPosition[2]=position[2];
			spawnAngles[0]=rotation[0];spawnAngles[1]=rotation[1];spawnAngles[2]=rotation[2];
			PrintToChatAll(" \x0A[STROKE STRIKE] {EDIT} Spawn defined");
		}
		case 'w':
		{
			if(GetVectorDistance(position,winPosition))
			{
				winPosition[0]=position[0];winPosition[1]=position[1];winPosition[2]=position[2];
				winAngles[0]=rotation[0];winAngles[1]=rotation[1];winAngles[2]=rotation[2];
				PrintToChatAll(" \x0A[STROKE STRIKE] {EDIT} Win defined");
			}
			else
			{
				winPosition[0]=0.0;winPosition[1]=0.0;winPosition[2]=0.0;
				winAngles[0]=0.0;winAngles[1]=0.0;winAngles[2]=0.0;
				PrintToChatAll(" \x0A[STROKE STRIKE] {EDIT} Win removed");
				removed = true;
			}
		}
		case 'h':
		{
			holePosition[0]=position[0];holePosition[1]=position[1];holePosition[2]=position[2];
			PrintToChatAll(" \x0A[STROKE STRIKE] {EDIT} Hole defined");
		}
	}
	
	if(!removed)
	{
		PrintToChatAll(" \x05.   position: %f %f %f", position[0],position[1],position[2]);
		if(type == 's' || type == 'w')
			PrintToChatAll(" \x05.   rotation: %f %f %f", rotation[0],rotation[1],rotation[2]);
	}
	PrintToChatAll(" ");
	
	EmitSoundToAll("survival/zone_chosen_by_other.wav");
	
	editMoveObjects();
}
public Action Command_golfeditspawn(int client, int args) {Command_golfeditobj(client,'s');}
public Action Command_golfeditwin(int client, int args) {Command_golfeditobj(client,'w');}
public Action Command_golfedithole(int client, int args) {Command_golfeditobj(client,'h');}
public Action Command_golfeditinfo(int client, int args) 
{
	if(client == 0 || !IsClientInGame(client))
	{
		ReplyToCommand(client, "[STROKE STRIKE] I can't do that, you're not ingame, I use the client's transforms");	
		return Plugin_Handled;
	}
	if(gamemodeNotEditError(client)) return Plugin_Handled;
	
	if(!GetCmdArgs() || args < 2)
	{
		ReplyToCommand(client, "[STROKE STRIKE] Current Info:");	
		ReplyToCommand(client,". name: %s", holeName);
		ReplyToCommand(client,". author: %s", holeAuthor);
		ReplyToCommand(client,". par: %d", holePar);
		ReplyToCommand(client, "usage: sm_golfeditinfo <name> <author> [par]");	
		return Plugin_Handled;
	}
	
	GetCmdArg(1,holeName,sizeof(holeName));
	GetCmdArg(2,holeAuthor,sizeof(holeAuthor));
	char charHolePar[3];
	if(args == 3) 
	{
		GetCmdArg(3,charHolePar,sizeof(charHolePar));
		holePar = StringToInt(charHolePar,10);
		if(holePar < 1) holePar = -1;
	}
	
	PrintToChatAll(" ");
	PrintToChatAll(" \x0A[STROKE STRIKE] {EDIT} Info defined");
	PrintToChatAll(" \x05.   name: %s", holeName);	
	PrintToChatAll(" \x05.   author: %s", holeAuthor);	
	PrintToChatAll(" \x05.   par: %d", holePar);	
	PrintToChatAll(" ");
	
	EmitSoundToAll("survival/zone_chosen_by_other.wav");
	
	return Plugin_Handled;
}
public Action Command_golfeditspawnradius(int client, int args) {Command_golfeditradius(client, args,'s',false);}
public Action Command_golfeditholeradius(int client, int args) {Command_golfeditradius(client, args,'h',false);}
public void Command_golfeditradius(int client, args, char type, bool increment)
{	
	const float minRadius = 32.0;
	const float incr = 16.0;
	float fRadius;
	if(GetCmdArgs() && args == 1)	// has it in the params
	{
		char sRadius[8];
		GetCmdArg(1,sRadius, sizeof(sRadius));
		fRadius = StringToFloat(sRadius);	// 0 if error, all good
		if(fRadius < minRadius)
		PrintToChatAll(" \x0A[STROKE STRIKE] {EDIT} Minimum radius is %f", minRadius);
	}
	else if (increment)
	{
		switch(type)
		{
			case 's':
				fRadius = spawnRadius+incr;
			case 'h':
				fRadius = holeRadius+incr;
		}
		if(fRadius > 256)
			fRadius = 0.0;
		else if(fRadius < minRadius)
			fRadius = 32.0+16;
	}
	else
	{
		switch(type)
		{
			case 's':
			{
				ReplyToCommand(client, "[STROKE STRIKE] Current Spawn Random Position Radius: %f", spawnRadius);	
				ReplyToCommand(client, "usage: sm_golfeditspawnradius <radius>");
			}
			case 'h':
			{
				ReplyToCommand(client, "[STROKE STRIKE] Current Hole Random Position Radius: %f", holeRadius);	
				ReplyToCommand(client, "usage: sm_golfeditholeradius <radius>");
			}
		}
		return;
	}
	
	
	if(!increment) PrintToChatAll(" ");
	switch(type)
	{
		case 's':
		{
			spawnRadius = fRadius;
			PrintToChatAll(" \x0A[STROKE STRIKE] {EDIT} Spawn Position Radius set to: %f", spawnRadius);
		}
		case 'h':
		{
			holeRadius = fRadius;
			PrintToChatAll(" \x0A[STROKE STRIKE] {EDIT} Hole Position Radius set to: %f", holeRadius);
		}
	}
	if(!increment) PrintToChatAll(" ");

	EmitSoundToAll("survival/zone_chosen_by_other.wav");
	editMoveObjects();
}

public Action Command_golfeditsave(int client, int args) 
{
	if(gamemodeNotEditError(client)) return Plugin_Handled;
	
	if(!GetCmdArgs() || args < 1)
	{
		editListConfigs(client);
		ReplyToCommand(client, "usage: sm_golfeditsave <filename>");	
		return Plugin_Handled;
	}
	
	bool noInfo = false;
	bool noSpawn = false;
	bool noHole = false;
	if(strlen(holeAuthor) < 2 || strlen(holeName) < 2)
		noInfo = true;
	if(GetVectorLength(holePosition) == 0)
		noHole = true;
	if(GetVectorLength(spawnPosition) == 0)
		noSpawn = true;
	
	if(noInfo || noSpawn || noHole)
	{
		PrintToChatAll(" ");
		PrintToChatAll(" \x07[STROKE STRIKE] {EDIT} Error while saving!");
		if(noInfo) PrintToChatAll(" \x09. No Info!");
		if(noSpawn) PrintToChatAll(" \x09. No Spawn!");
		if(noHole) PrintToChatAll(" \x09. No Hole!");
		EmitSoundToAll("survival/creep_exit_01.wav");
		PrintToChatAll(" ");
		return Plugin_Handled;
	}
	
	char savename[48];
	GetCmdArg(1,savename,sizeof(savename));
	ReplaceString(savename, sizeof(savename), ".txt", "", false);
	StrCat(savename, sizeof(savename), ".txt");
	
	char filePath[PLATFORM_MAX_PATH];
	strcopy(filePath, sizeof(filePath), mapConfigPath);
	StrCat(filePath, sizeof(filePath), savename);
	
	if(!DirExists(mapConfigPath, false, NULL_STRING))
	{
		PrintToServer("Creating the map folder: %s", mapConfigPath);
		CreateDirectory(mapConfigPath, 511);
	}
	
	File fileHandle = OpenFile(filePath, "w", false, NULL_STRING);
	if(!fileHandle)	
	{
		PrintToServer("[STROKE STRIKE] {EDIT} Couldn't create %s", filePath);
		PrintToChatAll(" \x07[STROKE STRIKE] {EDIT} Couldn't create %s", filePath);
		EmitSoundToAll("survival/creep_exit_01.wav");
		return Plugin_Handled;
	}
	
	WriteFileLine(fileHandle, "hole");
	WriteFileLine(fileHandle, "{");
	WriteFileLine(fileHandle, "\tinfo");
	WriteFileLine(fileHandle, "\t[");
	WriteFileLine(fileHandle, "\t\tname: %s", holeName);
	WriteFileLine(fileHandle, "\t\tauthor: %s", holeAuthor);
	if(holePar > 1) 
	WriteFileLine(fileHandle, "\t\tpar: %d", holePar);
	WriteFileLine(fileHandle, "\t]");
	WriteFileLine(fileHandle, " ");
	WriteFileLine(fileHandle, "\tspawn");
	WriteFileLine(fileHandle, "\t[");
	WriteFileLine(fileHandle, "\t\tposition: %f %f %f", spawnPosition[0],spawnPosition[1],spawnPosition[2]);
	WriteFileLine(fileHandle, "\t\trotation: %f %f %f", spawnAngles[0],spawnAngles[1],spawnAngles[2]);
	if(spawnRadius > 0) 
	WriteFileLine(fileHandle, "\t\tradius: %f", spawnRadius);
	WriteFileLine(fileHandle, "\t]");
	WriteFileLine(fileHandle, " ");
	WriteFileLine(fileHandle, "\thole");
	WriteFileLine(fileHandle, "\t[");
	WriteFileLine(fileHandle, "\t\tposition: %f %f %f", holePosition[0],holePosition[1],holePosition[2]);
	if(holeRadius > 0) 
	WriteFileLine(fileHandle, "\t\tradius: %f", holeRadius);
	WriteFileLine(fileHandle, "\t]");
	if(GetVectorLength(winPosition))
	{
	WriteFileLine(fileHandle, " ");
	WriteFileLine(fileHandle, "\twin");
	WriteFileLine(fileHandle, "\t[");
	WriteFileLine(fileHandle, "\t\tposition: %f %f %f", winPosition[0],winPosition[1],winPosition[2]);
	WriteFileLine(fileHandle, "\t\trotation: %f %f %f", winAngles[0],winAngles[1],winAngles[2]);
	WriteFileLine(fileHandle, "\t]");
	}
	WriteFileLine(fileHandle, "}");
	
	CloseHandle(fileHandle);
	
	PrintToChatAll(" \x0A[STROKE STRIKE] {EDIT} Hole saved as %s/%s", mapname, savename);
	ReplyToCommand(0,"[STROKE STRIKE] {EDIT} Hole saved as %s/%s", mapname, savename);
	EmitSoundToAll("survival/bonus_award_01.wav"); 	
	
	strcopy(holeFileName,sizeof(holeFileName),savename);
	
	return Plugin_Handled;
}

public Action Command_golfeditdel(int client, int args) 
{
	if(gamemodeNotEditError(client)) return Plugin_Handled;
	if(!hasConfigFolder) return Plugin_Handled;
	
	if(!GetCmdArgs() || args < 1)
	{
		editListConfigs(client);
		ReplyToCommand(client, "usage: sm_golfeditdel <name>");	
		return Plugin_Handled;
	}
	
	char file[48];
	char filepath[PLATFORM_MAX_PATH];
	GetCmdArg(1,file,sizeof(file));
	ReplaceString(file, sizeof(file), ".txt", "", false);
	StrCat(file, sizeof(file), ".txt");
	strcopy(filepath, sizeof(filepath), mapConfigPath);
	StrCat(filepath, sizeof(filepath), file);
	
	bool deleted = DeleteFile(filepath);
	
	if(deleted)
	{
		PrintToChatAll(" \x0A[STROKE STRIKE] {EDIT} File %s/%s has been removed", mapname, file);
		ReplyToCommand(0,"[STROKE STRIKE] {EDIT} File %s/%s has been removed", mapname, file);
		EmitSoundToAll("survival/bonus_award_01.wav"); 	
	}
	else
	{
		PrintToChatAll(" \x07[STROKE STRIKE] {EDIT} Error while deleting %s", file);
		ReplyToCommand(0,"[STROKE STRIKE] {EDIT} Error while deleting %s", file);
		EmitSoundToAll("survival/creep_exit_01.wav"); 	
	}
	
	if(hasEmptyConfigFolder())
		RemoveDir(mapConfigPath);
	
	return Plugin_Handled;
}

public void editMoveObjects()
{
	if(GetVectorLength(holePosition) == 0) setGlow(indicator_mdl, false);
	else setGlow(indicator_mdl, true);
	
	if(GetVectorLength(winPosition) == 0) setGlow(editwin_mdl, false);
	else setGlow(editwin_mdl, true);
	
	if(GetVectorLength(spawnPosition) == 0) setGlow(editspawn_mdl, false);
	else setGlow(editspawn_mdl, true);
	
	float indicatorOff[3] = {0.0, 0.0, 192.0};
	AddVectors(holePosition, indicatorOff, indicatorOff);
	
	TeleportEntity(flag_mdl, holePosition, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(hole_mdl, holePosition, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(indicator_mdl, indicatorOff, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(hole_mdl, "Solid", "5");
	DispatchKeyValue(flag_mdl, "Solid", "5");
	
	
	float editSpawnAnglesMDL[3] = {0.0,0.0,0.0}; 
	float editWinAnglesMDL[3] = {0.0,0.0,0.0};
	float editSpawnPosCAM[3] = {0.0,0.0,0.0}; 
	float editWinPosCAM[3] = {0.0,0.0,0.0};
	editSpawnAnglesMDL[1] = spawnAngles[1];
	editWinAnglesMDL[1] = winAngles[1];
	AddVectors(spawnPosition, NULL_VECTOR, editSpawnPosCAM); editSpawnPosCAM[2] += 80;
	AddVectors(winPosition, NULL_VECTOR, editWinPosCAM); editWinPosCAM[2] += 80;
	
	TeleportEntity(editspawn_mdl, spawnPosition, editSpawnAnglesMDL, NULL_VECTOR);
	TeleportEntity(editwin_mdl, winPosition, editWinAnglesMDL, NULL_VECTOR);
	
	TeleportEntity(editspawn_cam, editSpawnPosCAM, spawnAngles, NULL_VECTOR);
	TeleportEntity(editwin_cam, editWinPosCAM, winAngles, NULL_VECTOR);
	
	TeleportEntity(edithole_rad, holePosition, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(editspawn_rad, spawnPosition, NULL_VECTOR, NULL_VECTOR);
	
	float holeRadiusEdit = holeRadius; if(holeRadius < 32.0) holeRadiusEdit = 32.0;
	float spawnRadiusEdit = spawnRadius; if(spawnRadius < 32.0) spawnRadiusEdit = 32.0;
	
	char scaleBuffer[8];
	FloatToString(holeRadiusEdit, scaleBuffer, sizeof(scaleBuffer)); DispatchKeyValue(edithole_rad, "modelscale", scaleBuffer);
	FloatToString(spawnRadiusEdit, scaleBuffer, sizeof(scaleBuffer)); DispatchKeyValue(editspawn_rad, "modelscale", scaleBuffer);
}

public void editCreateObjects()
{
	// 				SPAWN
	
	editspawn_mdl = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(editspawn_mdl, "model", "models/editor/playerstart.mdl");
	DispatchKeyValue(editspawn_mdl, "Solid", "5");
	DispatchSpawn(editspawn_mdl);
	setGlowColor(editspawn_mdl, 0, 70, 255);
	
	editspawn_cam = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(editspawn_cam, "model", "models/editor/camera.mdl");
	DispatchKeyValue(editspawn_cam, "Solid", "5");
	DispatchSpawn(editspawn_cam);
	setGlowColor(editspawn_cam, 0, 70, 255);
	
	editspawn_rad = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(editspawn_rad, "model", "models/zool/strokestrike/radius.mdl");
	DispatchKeyValue(editspawn_rad, "rendercolor", "0 150 255");
	DispatchKeyValue(editspawn_rad, "Solid", "5");
	DispatchSpawn(editspawn_rad);
	
	// 				WIN
	
	editwin_mdl = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(editwin_mdl, "model", "models/editor/playerstart.mdl");
	DispatchKeyValue(editwin_mdl, "Solid", "5");
	DispatchSpawn(editwin_mdl);
	setGlowColor(editwin_mdl, 255, 50, 50);
	
	editwin_cam = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(editwin_cam, "model", "models/editor/camera.mdl");
	DispatchKeyValue(editwin_cam, "Solid", "5");
	DispatchSpawn(editwin_cam);
	setGlowColor(editwin_cam, 255, 50, 50);
	
	// 				HOLE
	
	edithole_rad = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(edithole_rad, "model", "models/zool/strokestrike/radius.mdl");
	DispatchKeyValue(edithole_rad, "rendercolor", "50 255 50");
	DispatchKeyValue(edithole_rad, "Solid", "5");
	DispatchSpawn(edithole_rad);
	
	holeFileName = "";
	
	editMoveObjects();
}
public void editListConfigs(int client)
{
	ReplyToCommand(client, "[STROKE STRIKE] List of configs for this map:");	
	int fileIndex = 0;
	char fileBuffer[512][48];    
	DirectoryListing dL = OpenDirectory(mapConfigPath);
	while (dL.GetNext(fileBuffer[fileIndex], sizeof(fileBuffer))) 
	{
		if(StrContains(fileBuffer[fileIndex], ".txt", false) == -1) 
			continue;
		
		ReplyToCommand(client, "\t- %s", fileBuffer[fileIndex]);
	}
}
public void editEnabledPrint()
{
	PrintToChatAll(" ");
	PrintToChatAll(" \x10[STROKE STRIKE] Edit mode is enabled");
	PrintToChatAll(" ");
}

public bool gamemodeNotEditError(int client)
{
	if(!editEnabled)
	{
		ReplyToCommand(client, "[STROKE STRIKE] Edit mode isn't enabled. type 'sm_golf 2' to enable.");
		return true;
	}
	return false;
}
public bool gamemodeNotRunningError()
{
	if(!gamemodeEnabled)
	{
		ReplyToCommand(0, "[STROKE STRIKE] The gamemode isn't running. Command aborted.");
		return true;
	}
	return false;
}



public Action Menu_edit(int client, int args)
{
	if(client == 0)
	{
		ReplyToCommand(0, "[STROKE STRIKE] I can't open this menu, you're not ingame, I use the client's transforms for the commands");
		return Plugin_Handled;
	}
	
	Menu menu;
	if(!editEnabled)
	{
		menu = new Menu(Menu_golfEnableHandler);
		menu.SetTitle("[Stroke Strike] Enable Edit Mode?");
		menu.AddItem("yes", "Yes");
		menu.AddItem("no", "No");
		menu.ExitButton = false;
		menu.Display(client, -1);
		return Plugin_Handled;
	}
	
	char sRadius[32] = "Incr Spawn Radius: ";
	char hRadius[32] = "Incr Hole Radius:  ";
	char rBuffer[8];
	FloatToString(spawnRadius, rBuffer, sizeof(rBuffer)); StrCat(sRadius, sizeof(sRadius), rBuffer);
	FloatToString(holeRadius, rBuffer, sizeof(rBuffer)); StrCat(hRadius, sizeof(hRadius), rBuffer);

	menu = new Menu(Menu_golfHandler);
	menu.SetTitle("[Stroke Strike] Edit Mode");
	menu.AddItem("spawn", "Set Spawn");
	menu.AddItem("hole", "Set Hole");
	menu.AddItem("win", "Set Win");
	menu.AddItem("srad", sRadius);
	menu.AddItem("hrad", hRadius);
	menu.ExitButton = true;
	menu.Display(client, -1);

	return Plugin_Handled;
}


public int Menu_golfHandler(Menu menu, MenuAction action, int client, int option)
{
    if (action == MenuAction_Select)
    {
		char optionName[8];
		menu.GetItem(option, optionName, sizeof(optionName));
		
		if(!strcmp(optionName, "spawn"))		Command_golfeditspawn(client, 0);
		else if(!strcmp(optionName, "hole"))	Command_golfedithole(client, 0);
		else if(!strcmp(optionName, "win"))		Command_golfeditwin(client, 0);
		else if(!strcmp(optionName, "srad"))		Command_golfeditradius(client, 0, 's', true);
		else if(!strcmp(optionName, "hrad"))		Command_golfeditradius(client, 0, 'h', true);
		Menu_edit(client, 0);
    }
    else if (action == MenuAction_End) delete menu;
}

public int Menu_golfEnableHandler(Menu menu, MenuAction action, int client, int option)
{
	if (action == MenuAction_Select) 
	{
		if(option == 0) setGamemode(client, 2);
	}
	else if (action == MenuAction_End) delete menu;
}