//  PropHunt by Darkimmortal
//   - GamingMasters.co.uk -

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

//--------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------- MAIN PROPHUNT CONFIGURATION -------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------

// Enable for global stats support (.inc file available on request due to potential for cheating and database abuse)
// Default: OFF
//#define STATS

// Give last prop a scattergun and apply jarate to all pyros on last prop alive
// Default: ON
#define SCATTERGUN

// Prop Lock/Unlock sounds
// Default: OFF
//#define LOCKSOUND

// New classes as demanded by Shinkz
// Default: ON
#define SHINX

// Event and query logging for debugging purposes
// Default: OFF
//#define LOG

// Allow props to Targe Charge with enemy collisions disabled by pressing reload - pretty shit tbh.
// Default: OFF
//#define CHARGE

//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------

#define TEAM_BLUE 3
#define TEAM_RED 2
#define TEAM_SPEC 1
#define TEAM_UNASSIGNED 0

#define SOUND_BEGIN "vo/announcer_am_gamestarting04.wav"
#define SOUND_LASTPLAYER "vo/announcer_am_lastmanalive01.wav"
#define SOUND_BONUS "vo/demoman_positivevocalization04.wav"
#define SOUND_INTERNET "vo/pyro_positivevocalization01.wav"
#define SOUND_SNAAAKE "prophunt/snaaake.mp3"
#define SOUND_FOUND "prophunt/found.mp3"
#define SOUND_ONEANDONLY "prophunt/oneandonly.mp3"
#define SOUND_COUNT30 "vo/announcer_begins_30sec.wav"
#define SOUND_COUNT20 "vo/announcer_begins_20sec.wav"
#define SOUND_COUNT10 "vo/announcer_begins_10sec.wav"
#define SOUND_COUNT5 "vo/announcer_begins_5sec.wav"
#define SOUND_COUNT4 "vo/announcer_begins_4sec.wav"
#define SOUND_COUNT3 "vo/announcer_begins_3sec.wav"
#define SOUND_COUNT2 "vo/announcer_begins_2sec.wav"
#define SOUND_COUNT1 "vo/announcer_begins_1sec.wav"
#define SOUND_BUTTON_DISABLED "buttons/button10.wav"
#define SOUND_BUTTON_UNLOCK "buttons/button24.wav"
#define SOUND_BUTTON_LOCK "buttons/button3.wav"

#define FLAMETHROWER "models/weapons/w_models/w_flamethrower.mdl"

#define STATE_WAT -1
#define STATE_IDLE 0
#define STATE_RUNNING 1
#define STATE_SWING 2
#define STATE_CROUCH 3

#define CLASS_BLU TFClass_Pyro
#define CLASS_RED 1
#define PLAYER_ONFIRE (1 << 14)

#define PL_VERSION "1.5"

#define WEP_TARGE 131
#define WEP_EYELANDER 132
#define WEP_NATASCHA 41
#define WEP_SNIPER 14
#define WEP_JARATE 58

enum ScReason {
	ScReason_TeamWin = 0,
	ScReason_TeamLose,
	ScReason_Death,
	ScReason_Kill,
	ScReason_Time,
	ScReason_Friendly
};

// SORRY THE VARIABLES ARE RANDOMLY NAMED BUT IT WORKS FOR ME

new bool:g_RoundOver = true;
//new bool:g_RoundStarted = false;
new bool:g_Attacking[MAXPLAYERS+1] = {false, ...};
new bool:g_SetClass[MAXPLAYERS+1] = {false, ...};
new bool:g_Spawned[MAXPLAYERS+1] = {false, ...};
new bool:g_TouchingCP[MAXPLAYERS+1] = {false, ...};
new bool:g_Charge[MAXPLAYERS+1] = {false, ...};
new bool:g_Locked[MAXPLAYERS+1] = {false, ...};
new bool:g_RotLocked[MAXPLAYERS+1] = {false, ...};
new bool:g_Hit[MAXPLAYERS+1] = {false, ...};
new String:g_PlayerModel[MAXPLAYERS+1][96];
new g_AnimeModel[MAXPLAYERS+1] = {-1, ...};

//new Float:Hat_Angles[3] = {0.0, 90.0, 0.0};
new String:g_Mapname[128];
new String:g_ServerIP[32];
new String:g_Version[8];
#if defined CHARGE
new g_offsCollisionGroup;
#endif
new g_Message_red;
new g_Message_blue;
new g_RoundTime = 175;
new g_Message_bit = 0;
new g_iVelocity = -1;

new Handle:g_TimerSound30 = INVALID_HANDLE;
new Handle:g_TimerSound20 = INVALID_HANDLE;
new Handle:g_TimerSound10 = INVALID_HANDLE;
new Handle:g_TimerSound5 = INVALID_HANDLE;
new Handle:g_TimerSound4 = INVALID_HANDLE;
new Handle:g_TimerSound3 = INVALID_HANDLE;
new Handle:g_TimerSound2 = INVALID_HANDLE;
new Handle:g_TimerSound1 = INVALID_HANDLE;
new Handle:g_TimerStart = INVALID_HANDLE;

new bool:g_Doors = false;
new bool:g_Relay = false;
new bool:g_Freeze = true;

new g_oFOV;
new g_oDefFOV;

new Handle:g_ModelName = INVALID_HANDLE;
new Handle:g_Text1 = INVALID_HANDLE;
new Handle:g_Text2 = INVALID_HANDLE;
new Handle:g_Text3 = INVALID_HANDLE;

new Handle:GameConf;
new Handle:hGiveNamedItem;
new Handle:hWeaponEquip;
new Handle:hKV = INVALID_HANDLE;
new Handle:g_RoundTimer = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "PropHunt",
	author = "Darkimmortal",
	description = "For GamingMasters.co.uk",
	version = PL_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=107104"
}

enum {
	COLLISION_GROUP_NONE  = 0,
    COLLISION_GROUP_DEBRIS,            // Collides with nothing but world and static stuff
    COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
    COLLISION_GROUP_INTERACTIVE_DEB,    // Collides with everything except other interactive debris or debris
    COLLISION_GROUP_INTERACTIVE,    // Collides with everything except interactive debris or debris
    COLLISION_GROUP_PLAYER,
    COLLISION_GROUP_BREAKABLE_GLASS,
    COLLISION_GROUP_VEHICLE,
    COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player
    COLLISION_GROUP_NPC,            // Generic NPC group
    COLLISION_GROUP_IN_VEHICLE,        // for any entity inside a vehicle
    COLLISION_GROUP_WEAPON,            // for any weapons that need collision detection
    COLLISION_GROUP_VEHICLE_CLIP,    // vehicle clip brush to restrict vehicle movement
    COLLISION_GROUP_PROJECTILE,        // Projectiles!
    COLLISION_GROUP_DOOR_BLOCKER,    // Blocks entities not permitted to get near moving doors
    COLLISION_GROUP_PASSABLE_DOOR,    // Doors that the player shouldn't collide with
    COLLISION_GROUP_DISSOLVING,        // Things that are dissolving are in this group
    COLLISION_GROUP_PUSHAWAY,        // Nonsolid on client and server, pushaway in player code
	COLLISION_GROUP_NPC_ACTOR,        // Used so NPCs in scripts ignore the player.
}


#if defined STATS
#include "prophunt\stats.inc"
#endif


public OnPluginStart(){
	
	
	decl String:hostname[255], String:ip[32], String:port[8];//, String:map[92];
	GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));	
	GetConVarString(FindConVar("ip"), ip, sizeof(ip));
	GetConVarString(FindConVar("hostport"), port, sizeof(port));
	
	Format(g_ServerIP, sizeof(g_ServerIP), "%s:%s", ip, port);
		
	if(StrContains(hostname, "GamingMasters.co.uk", false) != -1){
		if(StrContains(hostname, "PropHunt", false) == -1 && StrContains(hostname, "Arena", false) == -1 && StrContains(hostname, "Dark", false) == -1 && 
		   StrContains(ip, "8.9.4.169", false) == -1)
			SetFailState("PropHunt ftw [%s] [%s]", hostname, ip);
	}
	
	if(GetExtensionFileStatus("sdkhooks.ext") < 1)
		SetFailState("SDK Hooks is not loaded.");
	
	new bool:statsbool = false;
#if defined STATS 
	statsbool = true;
#endif
	
	Format(g_Version, sizeof(g_Version), "%s%s", PL_VERSION, statsbool ? "s" : "");
	CreateConVar("sm_prophunt_version", g_Version, "PropHunt Version (GamingMasters.co.uk)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_Text1 = CreateHudSynchronizer();
	g_Text2 = CreateHudSynchronizer();
	g_Text3 = CreateHudSynchronizer();
	
	AddServerTag("PropHunt");
	
	new Handle:cvar = INVALID_HANDLE;
	cvar = FindConVar("tf_arena_round_time");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("tf_arena_use_queue");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("tf_arena_max_streak");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("mp_tournament");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));	
	cvar = FindConVar("mp_tournament_stopwatch");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));	
	cvar = FindConVar("tf_tournament_hide_domination_icons");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));	
	cvar = FindConVar("mp_teams_unbalance_limit");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));	
	cvar = FindConVar("rtl_arenateamsize");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
		
	SetConVarInt(FindConVar("rtl_arenateamsize"), 16);
	SetConVarInt(FindConVar("tf_weapon_criticals"), 1, true);
	SetConVarInt(FindConVar("mp_idlemaxtime"), 0, true);
	SetConVarInt(FindConVar("mp_tournament_stopwatch"), 0, true);
	SetConVarInt(FindConVar("tf_tournament_hide_domination_icons"), 0, true);
	SetConVarInt(FindConVar("mp_idledealmethod"), 0, true);
	SetConVarInt(FindConVar("mp_maxrounds"), 0, true);
	SetConVarInt(FindConVar("sv_alltalk"), 1, true);
	SetConVarInt(FindConVar("mp_friendlyfire"), 0, true);
	SetConVarInt(FindConVar("sv_gravity"), 500, true);
	SetConVarInt(FindConVar("mp_forcecamera"), 1, true);
	SetConVarInt(FindConVar("tf_arena_override_cap_enable_time"), 1, true);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1, true);
	SetConVarInt(FindConVar("tf_arena_max_streak"), 3, true);
	SetConVarInt(FindConVar("mp_enableroundwaittime"), 0, true);
	SetConVarInt(FindConVar("mp_stalemate_timelimit"), 5, true);
	
	SetConVarInt(FindConVar("mp_stalemate_enable"), 1, true);
	SetConVarInt(FindConVar("mp_bonusroundtime"), 5, true);
	SetConVarInt(FindConVar("tf_arena_preround_time"), 15, true);
	
	SetConVarString(FindConVar("mapcyclefile"), "arena_mapcycle.txt");
	
#if defined STATS
	SetConVarString(FindConVar("motdfile"), "addons/sourcemod/plugins/prophunt.txt");
#endif
	
	SetCommandFlags("host_timescale", GetCommandFlags("host_timescale") & ~(FCVAR_CHEAT));
	
	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("player_death", Event_player_death, EventHookMode_Pre);
	HookEvent("arena_round_start", Event_arena_round_start, EventHookMode_Post);
	HookEvent("arena_win_panel", Event_arena_win_panel);
	HookEvent("player_changeclass", Event_player_changeclass);	
	HookEvent("post_inventory_application", CallCheckInventory, EventHookMode_Post);	
	
#if defined STATS
	Stats_Init();	
#endif	
	
	RegConsoleCmd("help", Command_motd);
	RegConsoleCmd("motd", Command_motd);
	RegConsoleCmd("first", Command_first);
	RegConsoleCmd("third", Command_third);		
	
	AddFileToDownloadsTable("sound/prophunt/found.mp3");
	AddFileToDownloadsTable("sound/prophunt/snaaake.mp3");
	AddFileToDownloadsTable("sound/prophunt/oneandonly.mp3");
	
	SoundLoad();
#if defined CHARGE
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup"); 
#endif
	LoadTranslations("prophunt.phrases");
		
	g_oFOV = FindSendPropOffs("CBasePlayer", "m_iFOV");
	g_oDefFOV = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
	
	RegAdminCmd("ph_respawn", Command_respawn, ADMFLAG_ROOT, "Respawns you");
	RegAdminCmd("ph_switch", Command_switch, ADMFLAG_KICK, "Switches to RED");
	RegAdminCmd("ph_internet", Command_internet, ADMFLAG_KICK, "Spams Internet");
	RegAdminCmd("ph_pyro", Command_pyro, ADMFLAG_KICK, "Switches to BLU");
	RegAdminCmd("ph_debug", Command_debug, ADMFLAG_KICK, "");
	
	GameConf = LoadGameConfigFile("givenameditem.games");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
	hGiveNamedItem = EndPrepSDKCall();
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	hWeaponEquip = EndPrepSDKCall();
	hKV = CreateKeyValues("TF2WeaponData");
	new String:file[128];
	BuildPath(Path_SM, file, sizeof(file), "data/tf2weapondata.txt");
	FileToKeyValues(hKV, file);
	
	if((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
		LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
	
	CreateTimer(7.0, Timer_AntiHack, 0, TIMER_REPEAT);
	CreateTimer(55.0, Timer_Score, 0, TIMER_REPEAT);
	
	
	for(new client=1; client<=MaxClients; client++) {
		if(IsClientInGame(client)){
			RemoveAnimeModel(client);
			ForcePlayerSuicide(client);
		}
	}	
}


public Action:CallCheckInventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, CheckInventory);
}
public Action:CheckInventory(Handle:timer)
{
	new edict;
	while(IsValidEdict(edict) && (edict = FindEntityByClassname(edict, "tf_wearable_item")) != -1)
	{
		RemoveEdict(edict);
	}
}

public StartTouchHook(entity, other){	
	if(entity <= MaxClients && entity > 0 && !g_TouchingCP[entity] && IsClientInGame(entity) && IsPlayerAlive(entity)){
		if(IsValidEntity(other)){
			decl String:propName[500];
			GetEntPropString(other, Prop_Data, "m_ModelName", propName, sizeof(propName));
			if(StrEqual(propName, "models/props_gameplay/cap_point_base.mdl")){
				FillHealth(entity);				
				PrintToChat(entity, "%t", "cpbonus");		
				EmitSoundToClient(entity, SOUND_BONUS, _, _, SNDLEVEL_AIRCRAFT);		
				g_TouchingCP[entity] = true;
			}
		}
	}
}

stock FillHealth(entity){
	switch(TF2_GetPlayerClass(entity)){
		case TFClass_Heavy:		
			SetEntityHealth(entity, 300);
		case TFClass_Sniper:
			SetEntityHealth(entity, 150);
		case TFClass_Pyro:
			SetEntityHealth(entity, 175);
		case TFClass_Scout:
			SetEntityHealth(entity, 125);
		case TFClass_Soldier:
			SetEntityHealth(entity, 200);	
		case TFClass_Engineer:
			SetEntityHealth(entity, 125);	
		case TFClass_DemoMan:
			SetEntityHealth(entity, 175);	
		case TFClass_Spy:
			SetEntityHealth(entity, 125);
		case TFClass_Medic:
			SetEntityHealth(entity, 150);
	}
}

public OnEntityCreated(entity, const String:classname[]){
	if(strcmp(classname, "team_control_point") == 0 ||
	   strcmp(classname, "team_control_point_master") == 0 || 
	   strcmp(classname, "team_control_point_round") == 0 || 
	   strcmp(classname, "trigger_capture_area") == 0 || 
	   strcmp(classname, "func_respawnroom") == 0 || 
	   strcmp(classname, "func_respawnroomvisualizer") == 0){
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
}

public OnEntitySpawned(entity){
    if(IsValidEntity(entity))
		AcceptEntityInput(entity, "Kill");
}


public SoundLoad(){	
	PrecacheSound(SOUND_BEGIN);
	PrecacheSound(SOUND_LASTPLAYER);
	PrecacheSound(SOUND_BONUS);
	PrecacheSound(SOUND_INTERNET);
	PrecacheSound(SOUND_SNAAAKE);
	PrecacheSound(SOUND_FOUND);
	PrecacheSound(SOUND_ONEANDONLY);
	PrecacheSound(SOUND_COUNT30);
	PrecacheSound(SOUND_COUNT20);
	PrecacheSound(SOUND_COUNT10);
	PrecacheSound(SOUND_COUNT5);
	PrecacheSound(SOUND_COUNT4);
	PrecacheSound(SOUND_COUNT3);
	PrecacheSound(SOUND_COUNT2);
	PrecacheSound(SOUND_COUNT1);	
	PrecacheSound(SOUND_BUTTON_DISABLED);
	PrecacheSound(SOUND_BUTTON_LOCK);
	PrecacheSound(SOUND_BUTTON_UNLOCK);
}

public OnMapStart(){
	
	GetCurrentMap(g_Mapname, sizeof(g_Mapname));	
	
	new arraySize = ByteCountToCells(100);	
	g_ModelName = CreateArray(arraySize);	
	PushArrayString(g_ModelName, "models/props_gameplay/cap_point_base.mdl");
	
	new String:confil[192], String:buffer[256], String:tidyname[2][32], String:maptidyname[128];	
	ExplodeString(g_Mapname, "_", tidyname, 2, 32);
	Format(maptidyname, sizeof(maptidyname), "%s_%s", tidyname[0], tidyname[1]);
	BuildPath(Path_SM, confil, sizeof(confil), "data/prophunt/%s.cfg", maptidyname);	
	new Handle:fl = CreateKeyValues("prophuntmapconfig");
	
	if(!FileToKeyValues(fl, confil)){
		LogMessage("[PH] Config file for map %s not found at %s. Unloading plugin.", maptidyname, confil);
		ServerCommand("sm plugins unload prophunt");
		return;
	} else {
		PrintToServer("Successfully loaded %s", confil);
		KvGotoFirstSubKey(fl);		
		KvJumpToKey(fl, "Props", false);
		KvGotoFirstSubKey(fl);
		do
		{
			KvGetSectionName(fl, buffer, sizeof(buffer));		
			PushArrayString(g_ModelName, buffer);
		} while (KvGotoNextKey(fl));
		KvRewind(fl);
		KvJumpToKey(fl, "Settings", false);
		KvGetString(fl, "doors", buffer, sizeof(buffer), "0");
		g_Doors = strcmp(buffer, "1") == 0;
		KvGetString(fl, "relay", buffer, sizeof(buffer), "0");
		g_Relay = strcmp(buffer, "1") == 0;
		KvGetString(fl, "freeze", buffer, sizeof(buffer), "1");
		g_Freeze = strcmp(buffer, "1") == 0;
		KvGetString(fl, "round", buffer, sizeof(buffer), "175");
		g_RoundTime = StringToInt(buffer);	
		PrintToServer("Successfully parsed %s", confil);
		PrintToServer("Loaded %i models, doors: %i, relay: %i, freeze: %i, round time: %i.", GetArraySize(g_ModelName)-1, g_Doors?1:0, g_Relay?1:0, g_Freeze?1:0, g_RoundTime);	
	}
	CloseHandle(fl);
	
	SoundLoad();
	
	decl String:model[100];
	
	for(new i = 0; i < GetArraySize(g_ModelName); i++){
		GetArrayString(g_ModelName, i, model, sizeof(model));
		PrecacheModel(model, true);	
	}
	
	PrecacheModel(FLAMETHROWER, true);	
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	Format(gameDesc, sizeof(gameDesc), "PropHunt %s (GamingMasters.co.uk)", g_Version);
	return Plugin_Changed;
}

public Action:Timer_TimeUp(Handle:timer, any:lol){
	if(!g_RoundOver){
		DoWin(TEAM_RED);
		g_RoundOver = true;
	}
	g_RoundTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public OnPluginEnd(){	
	PrintCenterTextAll("%t", "plugin reload");	
}

public TakeDamageHook(client, attacker, inflictor, Float:damage, damagetype)
{
	if(client > 0 && attacker > 0 && client < MaxClients && attacker < MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_RED 
	   && IsClientInGame(attacker) && GetClientTeam(attacker) == TEAM_BLUE){		
		if(!g_Hit[client]){
			new Float:pos[3];
			GetClientAbsOrigin(client, pos);
			EmitSoundToClient(client, SOUND_FOUND, _, SNDCHAN_WEAPON, _, _, 0.8, _, client, pos);
			EmitSoundToClient(attacker, SOUND_FOUND, _, SNDCHAN_WEAPON, _, _, 0.8, _, client, pos);
			g_Hit[client] = true;
		}		
	}
}

stock RemoveAnimeModel(client){	
	new anime = GetAnimeEnt(client);
	if(anime > 0 && IsValidEntity(anime))
		AcceptEntityInput(anime, "kill");
	if(anime > 0 && IsValidEdict(anime))
		RemoveEdict(anime);
	g_AnimeModel[client] = -1;
}

public OnClientDisconnect_Post(client){
	RemoveAnimeModel(client);
	ResetPlayer(client);
}

stock SwitchView(target, observer, viewmodel){	
	SetEntPropEnt(target, Prop_Send, "m_hObserverTarget", observer ? target : -1);
	SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1 : 0);
	SetEntData(target, g_oFOV, observer ? 100 : GetEntData(target, g_oDefFOV, 4), 4, true);		
	SetEntProp(target, Prop_Send, "m_bDrawViewmodel", viewmodel ? 1 : 0);
}

public DoWin(team){
	if(!g_RoundOver){
		g_RoundOver = true;

		for(new client=1; client<=MaxClients; client++) {
			if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != team){
				ForcePlayerSuicide(client);
			}
		}
	}
}

public OnClientPutInServer(client){
	ResetPlayer(client);
}

public ResetPlayer(client){	
	g_AnimeModel[client] = -1;	
	g_Spawned[client] = false;
	g_Charge[client] = false;
	g_Hit[client] = false;
	g_Attacking[client] = false;
	g_RotLocked[client] = false;
	g_TouchingCP[client] = false;
	g_Locked[client] = false;
	g_PlayerModel[client] = "";
	g_SetClass[client] = false;
}

public Action:Command_respawn(client, args){
	TF2_RespawnPlayer(client);
	return Plugin_Handled;
}

public Action:Command_debug(client, args){
	GetAnimeEnt(client);
	PrintToChat(client, "g_RoundOver = %s", g_RoundOver?"true":"false");
}

public Action:Command_internet(client, args){
	decl String:name[255];
	for(new i = 0; i < 3; i ++){
		EmitSoundToAll(SOUND_INTERNET, _, _, SNDLEVEL_AIRCRAFT);
	}
	GetClientName(client, name, sizeof(name));
	return Plugin_Handled;
}
	
public Action:Command_switch(client, args){
	RemoveAnimeModel(client);
	SwitchView(client, true, false);
	ForcePlayerSuicide(client);
	ChangeClientTeam(client, TEAM_RED);
	TF2_RespawnPlayer(client);
	
	CreateTimer(1.0, Timer_Move, client);
	return Plugin_Handled;
}

public Action:Command_pyro(client, args){
	RemoveAnimeModel(client);
	g_PlayerModel[client] = "";
	SwitchView(client, false, true);
	ForcePlayerSuicide(client);
	ChangeClientTeam(client, TEAM_BLUE);
	TF2_RespawnPlayer(client);	
	CreateTimer(1.0, Timer_Move, client);
	CreateTimer(2.0, Timer_Unfreeze, client);
	return Plugin_Handled;
}

public Action:Timer_Unfreeze(Handle:timer, any:client){
	if(IsClientInGame(client) && IsPlayerAlive(client))
		SetEntityMoveType(client, MOVETYPE_WALK);
}

public Action:Timer_Move(Handle:timer, any:client){
	if(IsClientInGame(client) && IsPlayerAlive(client)){		
		//if(IsValidEdict(GetEntPropEnt(client, Prop_Send, "m_hRagdoll")))
		//	RemoveEdict(GetEntPropEnt(client, Prop_Send, "m_hRagdoll"));
		new rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(IsValidEntity(rag))
			AcceptEntityInput(rag, "Kill");
		SetEntityMoveType(client, MOVETYPE_WALK);
		if(GetClientTeam(client) == TEAM_BLUE){
			CreateTimer(0.1, Timer_DoEquipBlu, client);  
		} else {
			CreateTimer(0.1, Timer_DoEquip, client);  
		}
	}	
}

// much more reliable than an entity index array for cross-round code, since indexes are fucked with between rounds on srcds (only?)
stock GetAnimeEnt(client){
	new client2, ent;
	while(IsValidEntity(ent) && (ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{
		client2 = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if(client2 == client){
			return ent;
		}
	}
	return -1;
}

stock PlayersAlive(){
	new alive = 0;
	for(new i=1; i<=MaxClients; i++) {
		if(IsClientInGame(i) && IsPlayerAlive(i))
			alive++;
	}
	return alive;
}

public Action:Event_arena_win_panel(Handle:event, const String:name[], bool:dontBroadcast){
	//g_RoundStarted = false;
#if defined LOG
	LogMessage("[PH] round end");
#endif
	
	
	//g_RoundStarted = false;	
	g_RoundOver = true;
	
#if defined STATS
	new winner = GetEventInt(event, "winning_team");
	DbRound(winner);
#endif
	
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0, true);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0, true);
		
	new team;
	
	for(new client=1; client<=MaxClients; client++) {
		
		if(IsClientInGame(client)){
			
#if defined STATS
			if(GetClientTeam(client) == winner){
				AlterScore(client, 3, ScReason_TeamWin, 0);
			} else if(GetClientTeam(client) != TEAM_SPEC) {
				AlterScore(client, -1, ScReason_TeamLose, 0);					
			}
#endif
			
			team = GetClientTeam(client);
			if(team == TEAM_RED || team == TEAM_BLUE){
				SetEntProp(client, Prop_Send, "m_lifeState", 2);
				ChangeClientTeam(client, team == TEAM_RED ? TEAM_BLUE : TEAM_RED);		
				SetEntProp(client, Prop_Send, "m_lifeState", 0);		
			}
			
			if(team == TEAM_RED){
				RemoveAnimeModel(client);
			}
		}
	}
	
	for(new client=0; client<=MaxClients; client++) {
		ResetPlayer(client);
	}
	
	SetConVarInt(FindConVar("tf_arena_use_queue"), 1, true);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1, true);
	
	if(g_RoundTimer != INVALID_HANDLE) CloseHandle(g_RoundTimer);
	g_RoundTimer = INVALID_HANDLE;
	if(g_TimerStart != INVALID_HANDLE) CloseHandle(g_TimerStart);
	g_TimerStart = INVALID_HANDLE;
	if(g_TimerSound30 != INVALID_HANDLE) CloseHandle(g_TimerSound30);
	g_TimerSound30 = INVALID_HANDLE;
	if(g_TimerSound20 != INVALID_HANDLE) CloseHandle(g_TimerSound20);
	g_TimerSound20 = INVALID_HANDLE;
	if(g_TimerSound10 != INVALID_HANDLE) CloseHandle(g_TimerSound10);
	g_TimerSound10 = INVALID_HANDLE;
	if(g_TimerSound5 != INVALID_HANDLE) CloseHandle(g_TimerSound5);
	g_TimerSound5 = INVALID_HANDLE;
	if(g_TimerSound4 != INVALID_HANDLE) CloseHandle(g_TimerSound4);
	g_TimerSound4 = INVALID_HANDLE;
	if(g_TimerSound3 != INVALID_HANDLE) CloseHandle(g_TimerSound3);
	g_TimerSound3 = INVALID_HANDLE;
	if(g_TimerSound2 != INVALID_HANDLE) CloseHandle(g_TimerSound2);
	g_TimerSound2 = INVALID_HANDLE;
	if(g_TimerSound1 != INVALID_HANDLE) CloseHandle(g_TimerSound1);
	g_TimerSound1 = INVALID_HANDLE;
}

public Action:Timer_AntiHack(Handle:timer, any:entity){
	if(!g_RoundOver){
		decl String:name[64];
		for(new client=1; client<=MaxClients; client++) {
			if(IsClientInGame(client) && IsPlayerAlive(client)){				
				if(GetClientTeam(client) == TEAM_RED && TF2_GetPlayerClass(client) == TFClass_Scout && GetPlayerWeaponSlot(client, 1) != -1){					
					GetClientName(client, name, sizeof(name));
					PrintToChatAll("\x04%t", "weapon punish", name);
					RemoveAnimeModel(client);
					SwitchView(client, false, true);
					ForcePlayerSuicide(client);
				}
			}
		}		
	}
}

public Action:Timer_Score(Handle:timer, any:entity){
	for(new client=1; client<=MaxClients; client++) {
#if defined STATS
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_RED){		
			AlterScore(client, 1, ScReason_Time, 0);
		}
#endif
		g_TouchingCP[client] = false;
	}
	PrintToChatAll("\x03%t", "cpbonus refreshed");
}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result) {
	
	if(g_RoundOver)
		return Plugin_Continue;

	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_BLUE){
		new damage = 10;
		
		if(strcmp(weaponname, "tf_weapon_flamethrower") == 0) damage = 1;
		else if(strcmp(weaponname, "tf_weapon_minigun") == 0) damage = 1;
		else if(strcmp(weaponname, "tf_weapon_pistol_scout") == 0) damage = 1;
		else if(strcmp(weaponname, "tf_weapon_pistol") == 0) damage = 1;
		else if(strcmp(weaponname, "tf_weapon_syringegun_medic") == 0) damage = 1;
		else if(strcmp(weaponname, "tf_weapon_smg") == 0) damage = 1;		
		
		new helf = GetClientHealth(client)-damage;
		if(helf < 1)
			ForcePlayerSuicide(client);
		else
			SetEntityHealth(client, GetClientHealth(client)-damage);
		
		if(strcmp(weaponname, "tf_weapon_flamethrower") == 0) AddVelocity(client, 1.0);
	}
	
	result = strcmp(weaponname, "tf_weapon_sniperrifle") == 0;
	return Plugin_Continue;
}

stock AddVelocity(client, Float:speed)
{	
	new Float:velocity[3];
	GetEntDataVector(client, g_iVelocity, velocity);
	
	// fucking win
	if(velocity[0] < 200 && velocity[0] > -200)
		velocity[0] *= (1.08 * speed);
	if(velocity[1] < 200 && velocity[1] > -200)
		velocity[1] *= (1.08 * speed);
	if(velocity[2] > 0 && velocity[2] < 400)
		velocity[2] = velocity[2] * 1.15 * speed;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
}

// Declared outside due to suspected stack bug in SM which drops the server to 1 fps until plugin reload
new Float:client_Origin[3], Float:client_Angles[3];

public PreThinkHook(client) {		
	
	if(IsClientInGame(client)){
		
		if(IsPlayerAlive(client)){			
			
			new buttons = GetClientButtons(client);
			if((buttons & IN_ATTACK) == IN_ATTACK && GetClientTeam(client) == TEAM_BLUE){
				g_Attacking[client] = true;		
			} else {
				g_Attacking[client] = false;
			}
			
			
			if((buttons & IN_ATTACK2) == IN_ATTACK2 && GetClientTeam(client) == TEAM_BLUE && TF2_GetPlayerClass(client) == TFClass_Pyro){			
				buttons &= ~(IN_ATTACK2);
				SetEntProp(client, Prop_Data, "m_nButtons", buttons);
				
				EmitSoundToClient(client, SOUND_BUTTON_DISABLED);//, _, _, _, _, 0.2);
			}
			
			if(GetClientTeam(client) == TEAM_RED &&  g_AnimeModel[client] > -1 && IsValidEntity(g_AnimeModel[client])){
			
				if((buttons & IN_ATTACK2) == IN_ATTACK2 && (buttons & IN_DUCK) != IN_DUCK){
					if(!g_Locked[client]){
						
						new Float:velocity[3];
						GetEntDataVector(client, g_iVelocity, velocity);
						// if the client is moving, don't allow them to lock in place
						if(velocity[0] > -5 && velocity[1] > -5 && velocity[2] > -5 && velocity[0] < 5 && velocity[1] < 5 && velocity[2] < 5){
		
							new Float:ground[3] = {0.0, 0.0, 0.0}, Float:pos[3];
							GetClientAbsOrigin(client, pos);
							TR_TraceRayFilter(pos, Float:{90.0, 90.0, 90.0}, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
							if(TR_DidHit()){
								TR_GetEndPosition(ground);
								if(ground[2] < pos[2]-40){
#if defined LOCKSOUND
									EmitSoundToClient(client, SOUND_BUTTON_DISABLED, _, _, _, _, 0.2);
#endif
									
								} else {
									SetVariantString("");
									AcceptEntityInput(g_AnimeModel[client], "SetParent", g_AnimeModel[client], g_AnimeModel[client], 0);
									TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
									SetEntityMoveType(client, MOVETYPE_NONE);
									g_Locked[client] = true;		
									g_RotLocked[client] = true;
#if defined LOCKSOUND
									EmitSoundToClient(client, SOUND_BUTTON_LOCK, _, _, _, _, 0.2);
#endif
								}
							} else {
								LogError("%N - Traceray failed to detect ground.", client);
							}
							
						}
					}		
				} else if((buttons & IN_ATTACK) == IN_ATTACK){
					
					g_RotLocked[client] = false;
					if(!g_Locked[client]){
						SetVariantString("");
						AcceptEntityInput(g_AnimeModel[client], "SetParent", g_AnimeModel[client], g_AnimeModel[client], 0);
						SetEntityMoveType(client, MOVETYPE_WALK);
						g_Locked[client] = true;
#if defined LOCKSOUND
						EmitSoundToClient(client, SOUND_BUTTON_LOCK, _, _, _, _, 0.2);
#endif
					}
					
				} else {
					
					g_RotLocked[client] = false;
					if(g_Locked[client]){						
						decl String:sWatcher[64];
						Format(sWatcher, sizeof(sWatcher), "target%i", client);
						SetVariantString(sWatcher);
						AcceptEntityInput(g_AnimeModel[client], "SetParent", g_AnimeModel[client], g_AnimeModel[client], 0);
						SetEntityMoveType(client, MOVETYPE_WALK);
#if defined LOCKSOUND
						EmitSoundToClient(client, SOUND_BUTTON_UNLOCK, _, _, _, _, 0.2);
#endif
					}
					g_Locked[client] = false;
					
				}
#if defined CHARGE				
				if((buttons & IN_RELOAD) == IN_RELOAD){
					if(!g_Charge[client]){
						g_Charge[client] = true;
						SetEntData(client, g_offsCollisionGroup, COLLISION_GROUP_DEBRIS_TRIGGER, _, true); 
						TF2_SetPlayerClass(client, TFClass_DemoMan, false);
						TF2_AddCond(client, 17);
						CreateTimer(2.5, Timer_Charge, client);
					}
				}
#endif
				if(g_Locked[client] && !g_RotLocked[client]){
					GetClientAbsOrigin(client, client_Origin);
					GetClientAbsAngles(client, client_Angles);
					
					if(client_Origin[0] == 0 && client_Origin[1] == 0 && client_Origin[2] == 0){
						client_Origin[0]=-9999.0;
						client_Origin[1]=-9999.0;
						client_Origin[2]=-9999.0;
					}
					
					TeleportEntity(g_AnimeModel[client], client_Origin, client_Angles, NULL_VECTOR);
				}
				
			}		
			
			
		} // alive
	} // in game
}

#if defined CHARGE
public Action:Timer_Charge(Handle:timer, any:client){	
	if(IsClientInGame(client) && IsPlayerAlive(client)){
		g_Charge[client] = false;
		SetEntData(client, g_offsCollisionGroup, COLLISION_GROUP_PLAYER, _, true);	
		TF2_SetPlayerClass(client, TFClass_Scout, false);
	}
}
#endif

stock TF2_AddCond(client, cond) {
    new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
    if(!enabled) {
        SetConVarFlags(cvar, flags^FCVAR_NOTIFY);
        SetConVarBool(cvar, true);
    }
    FakeClientCommand(client, "addcond %i", cond);
    if(!enabled) {
        SetConVarBool(cvar, false);
        SetConVarFlags(cvar, flags);
    }
}
stock TF2_RemoveCond(client, cond) {
    new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
    if(!enabled) {
        SetConVarFlags(cvar, flags^FCVAR_NOTIFY);
        SetConVarBool(cvar, true);
    }
    FakeClientCommand(client, "removecond %i", cond);
    if(!enabled) {
        SetConVarBool(cvar, false);
        SetConVarFlags(cvar, flags);
    }
}  

public Action:Event_arena_round_start(Handle:event, const String:name[], bool:dontBroadcast){
#if defined LOG
	LogMessage("[PH] round start");
#endif
	
	if(g_RoundOver){
				
		for(new client=1; client<=MaxClients; client++) {
			if(IsClientInGame(client) && IsPlayerAlive(client)){
				if(GetClientTeam(client) == TEAM_RED)
					Timer_DoEquip(INVALID_HANDLE, client);
				if(GetClientTeam(client) == TEAM_BLUE)
					Timer_DoEquipBlu(INVALID_HANDLE, client);
			}
		}
		
		SetupRoundTime(g_RoundTime);
		
		g_Message_bit = 0;
		
		decl String:message[256];
		Format(message, sizeof(message), "%T", "message blu", LANG_SERVER);		
		
		g_Message_blue = CreateEntityByName("game_text_tf");
		DispatchKeyValue(g_Message_blue, "background", "3");
		DispatchKeyValue(g_Message_blue, "display_to_team", "3");
		DispatchKeyValue(g_Message_blue, "icon", "d_skull_tf");
		DispatchKeyValue(g_Message_blue, "message", message);
		DispatchSpawn(g_Message_blue);
		
		Format(message, sizeof(message), "%T", "message red", LANG_SERVER);
		g_Message_red = CreateEntityByName("game_text_tf");
		DispatchKeyValue(g_Message_red, "background", "2");
		DispatchKeyValue(g_Message_red, "display_to_team", "2");
		DispatchKeyValue(g_Message_red, "icon", "timer_icon");
		DispatchKeyValue(g_Message_red, "message", message);
		DispatchSpawn(g_Message_red);
		
		CreateTimer(0.1, Timer_Info);
		
		g_TimerSound30 = CreateTimer(0.1, Timer_Sound30, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound20 = CreateTimer(10.0, Timer_Sound20, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound10 = CreateTimer(20.0, Timer_Sound10, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound5 = CreateTimer(25.0, Timer_Sound5, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound4 = CreateTimer(26.0, Timer_Sound4, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound3 = CreateTimer(27.0, Timer_Sound3, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound2 = CreateTimer(28.0, Timer_Sound2, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound1 = CreateTimer(29.0, Timer_Sound1, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerStart = CreateTimer(30.0, Timer_Start, _, TIMER_FLAG_NO_MAPCHANGE);		
		
	}
}

public SetupRoundTime(time){
	g_RoundTimer = CreateTimer(float(time-1), Timer_TimeUp, _, TIMER_FLAG_NO_MAPCHANGE);
	SetConVarInt(FindConVar("tf_arena_round_time"), time, true, false);
}

public Action:Timer_Sound30(Handle:timer, any:client){	
	EmitSoundToAll(SOUND_COUNT30, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound30 = INVALID_HANDLE;
}
public Action:Timer_Sound20(Handle:timer, any:client){	
	EmitSoundToAll(SOUND_COUNT20, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound20 = INVALID_HANDLE;
}
public Action:Timer_Sound10(Handle:timer, any:client){	
	EmitSoundToAll(SOUND_COUNT10, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound10 = INVALID_HANDLE;
}
public Action:Timer_Sound5(Handle:timer, any:client){	
	EmitSoundToAll(SOUND_COUNT5, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound5 = INVALID_HANDLE;
}
public Action:Timer_Sound4(Handle:timer, any:client){	
	EmitSoundToAll(SOUND_COUNT4, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound4 = INVALID_HANDLE;
}
public Action:Timer_Sound3(Handle:timer, any:client){	
	EmitSoundToAll(SOUND_COUNT3, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound3 = INVALID_HANDLE;
}
public Action:Timer_Sound2(Handle:timer, any:client){	
	EmitSoundToAll(SOUND_COUNT2, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound2 = INVALID_HANDLE;
}
public Action:Timer_Sound1(Handle:timer, any:client){	
	EmitSoundToAll(SOUND_COUNT1, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound1 = INVALID_HANDLE;
}

public Action:Timer_Info(Handle:timer, any:client){	
	g_Message_bit ++;
	
	if(g_Message_bit == 2){
		SetHudTextParamsEx(-1.0, 0.22, 5.0, {0,204,255,255}, {0,0,0,255}, 2, 1.0, 0.05, 0.5);
		for(new i=1; i<=MaxClients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i)){
				ShowSyncHudText(i, g_Text1, "PropHunt %s", g_Version);
			}
		}			
	} else if(g_Message_bit == 3){
		SetHudTextParamsEx(-1.0, 0.25, 4.0, {255,128,0,255}, {0,0,0,255}, 2, 1.0, 0.05, 0.5);
		for(new i=1; i<=MaxClients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i)){
				ShowSyncHudText(i, g_Text2, "By Darkimmortal");
			}
		}	
	} else if(g_Message_bit == 4){
		SetHudTextParamsEx(-1.0, 0.3, 3.0, {0,220,0,255}, {0,0,0,255}, 2, 1.0, 0.05, 0.5);
		for(new i=1; i<=MaxClients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i)){
				ShowSyncHudText(i, g_Text3, "GamingMasters.co.uk");
			}
		}	
	}
	
	if(g_Message_bit < 10 && IsValidEntity(g_Message_red) && IsValidEntity(g_Message_blue)){		
		AcceptEntityInput(g_Message_red, "Display");
		AcceptEntityInput(g_Message_blue, "Display");
		CreateTimer(1.0, Timer_Info);		
	}
}



public Action:Timer_Start(Handle:timer, any:client){
	//g_RoundStarted = false;
#if defined LOG
	LogMessage("[PH] Timer_Start");
#endif
	g_RoundOver = false;
	
	for(new client2=1; client2<=MaxClients; client2++) {
		if(IsClientInGame(client2) && IsPlayerAlive(client2) && GetClientTeam(client2) == TEAM_BLUE){
			SetEntityMoveType(client2, MOVETYPE_WALK);
		}
	}
	PrintToChatAll("%t", "ready");
	EmitSoundToAll(SOUND_BEGIN, _, _, SNDLEVEL_AIRCRAFT);
	
	new ent;
	if(g_Doors){
		while ((ent = FindEntityByClassname(ent, "func_door")) != -1){
			AcceptEntityInput(ent, "Open");
		}
	}
	
	if(g_Relay){		
		decl String:name[128];
		while ((ent = FindEntityByClassname(ent, "logic_relay")) != -1){
			GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
			if(strcmp(name, "hidingover", false) == 0)
				AcceptEntityInput(ent, "Trigger");
		}
	}
	g_TimerStart = INVALID_HANDLE;	
	
}	

public Action:Event_player_changeclass(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && GetClientTeam(client) == TEAM_RED){
		KickClient(client, "%t", "changing class");
	}
	return Plugin_Stop;
}

public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast){

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	
	SDKHook(client, SDKHook_OnTakeDamagePost, TakeDamageHook);
	SDKHook(client, SDKHook_PreThink, PreThinkHook);
	SDKHook(client, SDKHook_Touch, StartTouchHook);
	
	
	if(IsClientInGame(client) && IsPlayerAlive(client)){	
#if defined LOG
		LogMessage("[PH] Player spawn %N", client);
#endif
		g_Hit[client] = false;
		
		if(GetClientTeam(client) == TEAM_BLUE){
			
			PrintToChat(client, "%t", "wait");
#if defined SHINX			
			if(TF2_GetPlayerClass(client) != TFClass_Pyro && TF2_GetPlayerClass(client) != TFClass_Heavy && TF2_GetPlayerClass(client) != TFClass_Sniper && 
			   TF2_GetPlayerClass(client) != TFClass_DemoMan && TF2_GetPlayerClass(client) != TFClass_Soldier){	
				TF2_SetPlayerClass(client, TFClassType:TFClass_Pyro);
				TF2_RespawnPlayer(client);
				return Plugin_Continue;
			}		
#else 
			if(TF2_GetPlayerClass(client) != TFClass_Pyro && TF2_GetPlayerClass(client) != TFClass_Heavy){
				TF2_SetPlayerClass(client, TFClassType:TFClass_Pyro);
				TF2_RespawnPlayer(client);
				return Plugin_Continue;
			}		
#endif
			CreateTimer(0.1, Timer_DoEquipBlu, client);
			
		} else if(GetClientTeam(client) == TEAM_RED){		
			
			if(_:TF2_GetPlayerClass(client) != CLASS_RED){
				TF2_SetPlayerClass(client, TFClassType:CLASS_RED);
				TF2_RespawnPlayer(client);
				return Plugin_Continue;
			}			
			
			
			if(g_Spawned[client] && !(GetUserFlagBits(client) & ADMFLAG_KICK)){
				PrintToChat(client, "\x05%t", "possible exploit");
				RemoveAnimeModel(client);
				SwitchView(client, false, true);
				ForcePlayerSuicide(client);
				return Plugin_Continue;
			}
			
			g_Spawned[client] = true;
		}
		
	}
	return Plugin_Continue;
}

public Action:Timer_DoEquipBlu(Handle:timer, any:client){
	if(IsClientInGame(client) && IsPlayerAlive(client)){
		
		
		if(g_Freeze)
			SetEntityMoveType(client, MOVETYPE_NONE);
		
		SwitchView(client, false, true);
		SetAlpha(client, 255);	
		
		new slot0 = GetPlayerWeaponSlot(client, 0);
		new slot1 = GetPlayerWeaponSlot(client, 1);
		
		if(TF2_GetPlayerClass(client) == TFClass_Heavy){
			if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_NATASCHA){
				TF2_RemoveWeaponSlot(client, 0);
			}					
		} else if(TF2_GetPlayerClass(client) == TFClass_Sniper){
			if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_SNIPER){
				TF2_RemoveWeaponSlot(client, 0);
			}				
			if(slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_JARATE){
				TF2_RemoveWeaponSlot(client, 1);
			}						
		} else if(TF2_GetPlayerClass(client) == TFClass_DemoMan){
			TF2_RemoveWeaponSlot(client, 0);
			TF2_RemoveWeaponSlot(client, 1);
		} else if(TF2_GetPlayerClass(client) == TFClass_Soldier){
			TF2_RemoveWeaponSlot(client, 0);
		}
	}
}

public GiveWep(client, const String:weaponName[]){	
	if (!KvJumpToKey(hKV, weaponName)){
		LogError("%N - Invalid weapon name.", client);
	}
	new weaponSlot = KvGetNum(hKV, "slot");
	new weaponMax = KvGetNum(hKV, "max");
	KvRewind(hKV);
	TF2_RemoveWeaponSlot(client, weaponSlot - 1);
	new weaponEntity = SDKCall(hGiveNamedItem, client, weaponName, 0, 0);
	SDKCall(hWeaponEquip, client, weaponEntity);
	if (weaponMax != -1){
		SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + weaponSlot * 4, 999);
	}
}

public Action:Command_motd(client, args){
	if(IsClientInGame(client)){
		ShowMOTDPanel(client, "PropHunt Stats", "http://www.gamingmasters.co.uk/prophunt/index.php", MOTDPANEL_TYPE_URL);
	}
	return Plugin_Handled;
}
	
public Action:Command_kill(client, args){
	if(g_RoundOver)
		KickClient(client, "Kill/Explode %t", "permitted");
	return Plugin_Handled;
}
	
public Action:Command_first(client, args){
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_RED)
		SwitchView(client, false, false);
	return Plugin_Handled;
}
public Action:Command_third(client, args){
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_RED)
		SwitchView(client, true, false);
	return Plugin_Handled;
}

public Action:Timer_DoEquip(Handle:timer, any:client){
	
	if(IsClientInGame(client)){
#if defined LOG
		LogMessage("[PH] do equip %N", client);
#endif
		TF2_RemoveAllWeapons(client);
	}
		
	if(IsClientInGame(client) && IsPlayerAlive(client)){
		
		SetEntityHealth(client, 125);
		
		RemoveAnimeModel(client);
		
		g_AnimeModel[client] = CreateEntityByName("prop_dynamic_override");
		
		decl String:sWatcher[64];
		Format(sWatcher, sizeof(sWatcher), "target%i", client);
		DispatchKeyValue(client, "targetname", sWatcher);
		
		if(IsValidEntity(g_AnimeModel[client])){
			
			// fire in a nice random model
			decl String:model[96];
			if(strlen(g_PlayerModel[client]) > 1){
				model = g_PlayerModel[client];
			} else {
				GetArrayString(g_ModelName, GetRandomInt(0, GetArraySize(g_ModelName)-1), model, sizeof(model));
			}
			DispatchKeyValue(g_AnimeModel[client],"model", model);
			DispatchKeyValue(g_AnimeModel[client], "disableshadows", "1");
			
			decl String:nicemodel[128];			
			
			new lastslash = FindCharInString(model, '/', true)+1;
			strcopy(nicemodel, sizeof(nicemodel), model[lastslash]);
			ReplaceString(nicemodel, sizeof(nicemodel), ".mdl", "");
			
			PrintToChat(client, "%t", "now disguised", nicemodel);
			g_PlayerModel[client] = model;
			DispatchKeyValue(g_AnimeModel[client], "solid", "0");			
			
			if(StrContains(model, "oildrum", false) != -1){
				decl String:skin[4];
				IntToString(GetRandomInt(0,6), skin, sizeof(skin));
				DispatchKeyValue(g_AnimeModel[client], "skin", skin);
			} else if(StrContains(model, "computer", false) != -1 || StrContains(model, "console", false) != -1 || StrContains(model, "chair", false) != -1){
				decl String:skin[4];
				IntToString(GetRandomInt(0,1), skin, sizeof(skin));
				DispatchKeyValue(g_AnimeModel[client], "skin", skin);
			} else if(StrContains(model, "player", false) != -1){
				DispatchKeyValue(g_AnimeModel[client], "skin", "1");
			}
			
			SetEntityMoveType(g_AnimeModel[client], MOVETYPE_NOCLIP);			
			
			DispatchSpawn(g_AnimeModel[client]);			
			
			decl Float:origin[3], Float:angles[3];
			GetClientAbsOrigin(client, origin);
			GetClientAbsAngles(client, angles);			
			TeleportEntity(g_AnimeModel[client], origin, angles, NULL_VECTOR);					
			
			SetVariantFloat(1.0);
			AcceptEntityInput(g_AnimeModel[client], "SetScale", g_AnimeModel[client], g_AnimeModel[client], 0);
			
			SetVariantString(sWatcher);
			AcceptEntityInput(g_AnimeModel[client], "SetParent", g_AnimeModel[client], g_AnimeModel[client], 0);
			
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, 255, 255, 255, 0);    
				
			SetWeaponsAlpha(client, 0);	
			
			SetEntityMoveType(client, MOVETYPE_WALK);
			PrintToChat(client, "%t", "gohide");
				
			SwitchView(client, true, false);
			SetEntPropEnt(g_AnimeModel[client], Prop_Send, "m_hOwnerEntity", client);
			
		}
		
	}
}

stock SetAlpha(target, alpha){    
    SetWeaponsAlpha(target,alpha);
    SetEntityRenderMode(target, RENDER_TRANSCOLOR);
    SetEntityRenderColor(target, 255, 255, 255, alpha);    
}

public Action:Timer_Ragdoll(Handle:timer, any:client){
    if(IsClientInGame(client)){
		new rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(rag > MaxClients && IsValidEntity(rag))
			AcceptEntityInput(rag, "Kill");
    }
}

stock SetWeaponsAlpha(target, alpha){
	if(IsPlayerAlive(target)){
		decl String:classname[64];
		new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");            
		for(new i = 0, weapon; i < 47; i += 4){
			weapon = GetEntDataEnt2(target, m_hMyWeapons + i);
			if(weapon > -1 && IsValidEdict(weapon)){
				GetEdictClassname(weapon, classname, sizeof(classname));
				if(StrContains(classname, "tf_weapon", false) != -1){
					SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
					SetEntityRenderColor(weapon, 255, 255, 255, alpha);
				}
			}
		}
	}
}

public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast){
	
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client)){
#if defined LOG
		LogMessage("[PH] Player death %N", client);
#endif		
		RemoveAnimeModel(client);
		CreateTimer(0.1, Timer_Ragdoll, client);  
	}
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	if(!g_RoundOver)
		g_Spawned[client] = false;	
	
	g_Hit[client] = false;
	
	new playas = 0;
	for(new i=1; i<=MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_RED){
			playas ++;
		}
	}
	
	
	if(!g_RoundOver && GetClientTeam(client) == TEAM_RED)
		EmitSoundToClient(client, SOUND_SNAAAKE);
	
	if(!g_RoundOver){
		if(client > 0 && attacker > 0 && IsClientInGame(client) && IsClientInGame(attacker) && client != attacker){
			if(GetClientTeam(client) == GetClientTeam(attacker)){
#if defined STATS
				AlterScore(attacker, -5, ScReason_Friendly, client);	
#endif
			} else {
#if defined STATS
				AlterScore(attacker, 2, ScReason_Kill, client);
				AlterScore(client, -1, ScReason_Death, attacker);
#endif
				if(IsPlayerAlive(attacker)){
					Speedup(attacker, 50);
					FillHealth(attacker);	
				}
			}
			if(assister > 0 && IsClientInGame(assister)){
#if defined STATS
				AlterScore(assister, 1, ScReason_Kill, client);
#endif
				if(IsPlayerAlive(assister)){
					Speedup(assister, 50);	
					FillHealth(assister);	
				}
			}
		}
	}
	
	if(playas == 2 && !g_RoundOver && GetClientTeam(client) == TEAM_RED){
		EmitSoundToAll(SOUND_ONEANDONLY, _, _, SNDLEVEL_AIRCRAFT);
#if defined SCATTERGUN
		for(new client2=1; client2<=MaxClients; client2++) {
			if(IsClientInGame(client2) && !IsFakeClient(client2) && IsPlayerAlive(client2)){				
				if(GetClientTeam(client2) == TEAM_RED){
					GiveWep(client2, "tf_weapon_scattergun");
					SetAlpha(client2, 0);
					EquipPlayerWeapon(client2, GetPlayerWeaponSlot(client2, 0));
					SwitchView(client2, true, false);
					//TF2_AddCond(client2, 16);
				} else if(GetClientTeam(client2) == TEAM_BLUE){
					TF2_AddCond(client2, 22);
				}
			}
		}
#endif
	}
}

stock Speedup(client, inc){
	new Float:speed = GetEntDataFloat(client, FindSendPropInfo("CTFPlayer", "m_flMaxspeed")) + inc;
	if(speed > 400) speed = 400.0;
	SetEntDataFloat(client, FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), speed);	
}

public bool:TraceRayDontHitSelf(entity, mask, any:data){
	return entity != data;
}