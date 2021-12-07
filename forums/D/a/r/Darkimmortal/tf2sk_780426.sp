#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <dukehacks>

// Plugin version :P
#define PL_VERSION "0.1.5"


// No longer used
#define GIVER_OF_LIFE "[TF2 SK] Giver of Life"
#define TAKER_OF_LIFE "[TF2 SK] Taker of Life"
#define LIFE_WEAPON 1
#define FOV 90

// Team IDs
#define TEAM_RED 2
#define TEAM_BLUE 3
#define TEAM_SPEC 1

// Bits for various HUD elements
#define HIDEHUD_WEAPONSELECTION     ( 1<<0 )    // Hide ammo count & weapon selection
#define HIDEHUD_FLASHLIGHT          ( 1<<1 )
#define HIDEHUD_ALL                 ( 1<<2 )
#define HIDEHUD_HEALTH              ( 1<<3 )    // Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD          ( 1<<4 )    // Hide when local player's dead
#define HIDEHUD_NEEDSUIT            ( 1<<5 )    // Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS          ( 1<<6 )    // Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT                ( 1<<7 )    // Hide all communication elements (saytext, voice icon, etc)
#define HIDEHUD_CROSSHAIR           ( 1<<8 )    // Hide crosshairs
#define HIDEHUD_VEHICLE_CROSSHAIR   ( 1<<9 )    // Hide vehicle crosshair
#define HIDEHUD_INVEHICLE           ( 1<<10 )
#define HIDEHUD_BONUS_PROGRESS      ( 1<<11 )   // Hide bonus progress display (for bonus map challenges)



new Handle:g_hNoScope = INVALID_HANDLE;
new bool:g_NoScope = false;

new Handle:g_hHealth = INVALID_HANDLE;
new bool:g_Health = false;

new Handle:g_hMaxLives = INVALID_HANDLE;
new g_MaxLives;

new Handle:g_hMeleeDistance = INVALID_HANDLE;
new g_MeleeDistance;

new Handle:g_hBots = INVALID_HANDLE;
new g_Bots;

new bool:g_TimeLimitZero = true;

new Handle:g_hSpawn = INVALID_HANDLE;
new g_iSpawn = 5;
new bool:prot[MAXPLAYERS+1] = {false, ...};
new Handle:g_hFall = INVALID_HANDLE;
new Float:g_fFall = 1.0;
new Handle:g_hMult = INVALID_HANDLE;
new bool:g_bMult = true;
new Handle:g_hAccel = INVALID_HANDLE;
new Float:traceData[MAXPLAYERS+1][6];
new Handle:accel = INVALID_HANDLE;
new Handle:mpff = INVALID_HANDLE;
new bool:bmpff = false;
new bool:roundend = false;
new g_BeamSprite;
new g_HaloSprite;
new g_ExplosionSprite;
new offsActiveWeapon = -1;
new offsClip1 = -1;

new Handle:g_Audience = INVALID_HANDLE;
new Float:g_Podium[3][3][3];
new g_AudienceNum = 0;
new bool:g_Dead[MAXPLAYERS+1] = {false, ...};
new bool:g_Blind[MAXPLAYERS+1] = {false, ...};
new bool:g_DeadATM[MAXPLAYERS+1] = {false, ...};
new bool:g_Crit[MAXPLAYERS+1] = {false, ...};
new g_Lives[MAXPLAYERS+1] = {0, ...};
new g_Kills[MAXPLAYERS+1] = {0, ...};
new g_ArraySize;
new bool:g_Restarting = false;
new bool:g_RoundEnd = false;
new Handle:HudMessage;
new Handle:HudMessage2;
new g_OldHUD[MAXPLAYERS+1] = {0, ...};
new bool:g_JustStarted = true;
new Handle:g_scores = INVALID_HANDLE;
new UserMsg:g_FadeUserMsgId;
new g_TakerOfLife;
new g_GiverOfLife;
new Float:g_MilesAway[3] = {99999.0, 99999.0, 99999.0};
new bool:g_Madness = false;
new bool:g_Failbot = false;

new Handle:GameConf;
new Handle:hGiveNamedItem;
new Handle:hWeaponEquip;
new Handle:hKV = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "TF2 SK",
	author = "Darkimmortal",
	description = "Team Fortress 2 Scoutzknivez Mod",
	version = PL_VERSION,
	url = "http://www.gamingmasters.co.uk/"
}

public Action:Timer_AutoRestart(Handle:Timer_AutoRestart){
	OnMapStart2();
	PrintHintTextAll("Live restart successful. Enjoy! :D");
}

public OnPluginStart() {
	//decl String:hostname[1024];
	/*GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname)); 
	if(GetConVarInt(FindConVar("hostport")) != 27031 && !StrEqual(hostname, "Team Fortress 2 Arena Server"))
		SetFailState("TF2 SK has automatically terminated as it is not running on a server with port 27031.");*/
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	//if(GetConVarInt(FindConVar("hostport")) != 27031 && !StrEqual(mapname, "tf_scoutzknivez_v1")){
	if(StrContains(mapname, "sk_", false) == -1){
		SetFailState("TF2 SK has automatically terminated as it is not running on an sk_ map [%s].", mapname);
	} else {		
		PrintHintTextAll("Live restart will occur in 5 seconds. Server may crash.");
		CreateTimer(5.0, Timer_AutoRestart);
	}
	
	g_ArraySize = ByteCountToCells(40);	
	g_Audience = CreateArray(g_ArraySize);
	
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
	
	offsActiveWeapon = FindSendPropInfo("CTFPlayer", "m_hActiveWeapon");
	offsClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	
	CreateConVar("tf2sk_version", PL_VERSION, "TF2 SK version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hSpawn = CreateConVar("tf2sk_spawn", "5", "Spawn protection time, in seconds.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hFall = CreateConVar("tf2sk_fall", "0.0", "Fall damage multiplier (float).", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hMult = CreateConVar("tf2sk_mult", "1", "Change whether the beam will pass through targets on a hit, allowing multikills.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hAccel = CreateConVar("tf2sk_accel", "40", "sv_airaccelerate value.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	g_hNoScope = CreateConVar("tf2sk_noscope", "0", "Prevent use of the sniper scope by temporarily blinding players who use it.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hHealth = CreateConVar("tf2sk_health", "1", "Change whether players will die in two hits from the sniper rather than one.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hMaxLives = CreateConVar("tf2sk_maxlives", "3", "The number of lives each player gets per round.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hMeleeDistance = CreateConVar("tf2sk_meleedistance", "125", "The distance to register melee attacks within.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hBots = CreateConVar("tf2sk_bots", "2", "The number of bots to put in the server when it has < 3 human players.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	accel = FindConVar("sv_airaccelerate");
	mpff = FindConVar("mp_friendlyfire");
	
	new Handle:tl = FindConVar("mp_timelimit");
	g_TimeLimitZero = GetConVarInt(tl) == 0;
	
	RegConsoleCmd("equip", Command_Equip);
	RegConsoleCmd("score", Command_Score);
	HookConVarChange(g_hSpawn, Cvar_spawn);
	HookConVarChange(g_hFall, Cvar_fall);
	HookConVarChange(g_hMult, Cvar_mult);
	HookConVarChange(g_hAccel, Cvar_accel);
	HookConVarChange(g_hNoScope, Cvar_noscope);
	HookConVarChange(g_hHealth, Cvar_health);
	HookConVarChange(g_hMaxLives, Cvar_maxlives);
	HookConVarChange(g_hMeleeDistance, Cvar_meleedistance);
	HookConVarChange(g_hBots, Cvar_bots);
	HookConVarChange(mpff, Cvar_ff);
	
	RegAdminCmd("sk_epicwin", Command_SK_EpicWin, ADMFLAG_ROOT, "sk_epicwin");	
	RegAdminCmd("sk_madness", Command_SK_Madness, ADMFLAG_ROOT, "sk_madness");	
	RegAdminCmd("sk_restart", Command_SK_Restart, ADMFLAG_ROOT, "sk_restart");	
	
	HudMessage = CreateHudSynchronizer();
	HudMessage2 = CreateHudSynchronizer();
	
	HookEvent("player_death", Event_player_death);
	HookEvent("player_death", Event_player_death_before, EventHookMode_Pre);
	//HookEvent("player_death", Event_player_death_after);
	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("player_disconnect", Event_player_disconnect);
	HookEvent("player_activate", Event_player_authorized);
	HookEvent("player_spawn", Event_player_spawn_before, EventHookMode_Pre);
	HookEvent("player_team", Event_player_team_before, EventHookMode_Pre);
	//HookEvent("teamplay_round_start", Event_teamplay_round_start);
	//HookEvent("teamplay_restart_round", Event_teamplay_round_start);
	HookEvent("teamplay_round_win", Event_teamplay_round_win, EventHookMode_Pre);
	dhAddClientHook(CHK_PreThink, PreThinkHook);
	dhAddClientHook(CHK_TakeDamage, TakeDamageHook);	
	
	g_scores = CreateMenu(scoresHandler);	
	g_FadeUserMsgId = GetUserMessageId("Fade");
	
	new Handle:infoTimer = CreateTimer(300.0, Timer_Info, infoTimer, TIMER_REPEAT);		
	new Handle:hudTimer = CreateTimer(1.0, Timer_HUD, hudTimer, TIMER_REPEAT);
	new Handle:epicTimer = CreateTimer(1.0, EpicWin, epicTimer, TIMER_REPEAT);
	new Handle:menuTimer = CreateTimer(4.0, Timer_Menu, menuTimer, TIMER_REPEAT);
	
	//ServerCommand("hostname \"GamingMasters.co.uk #6 -- TF2 Scoutzknivez -- v%s\"", PL_VERSION);
	
}


public OnConfigsExecuted() {
	g_iSpawn = GetConVarInt(g_hSpawn);
	g_fFall = GetConVarFloat(g_hFall);
	g_bMult = GetConVarBool(g_hMult);
	
	g_NoScope = GetConVarBool(g_hNoScope);
	g_Health = GetConVarBool(g_hHealth);
	g_MaxLives = GetConVarInt(g_hMaxLives);
	g_MeleeDistance = GetConVarInt(g_hMeleeDistance);
	g_Bots = GetConVarInt(g_hBots);
	
	SetConVarInt(accel, GetConVarInt(g_hAccel), true);
	bmpff = GetConVarBool(mpff);
}
public Action:Timer_DestroyEntity(Handle:Timer_DestroyEntity, any:shopid){
	new Float:milesAway[3] = {-1500.0, -1500.0, -1500.0};
	TeleportEntity(shopid, milesAway, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(shopid, "kill");
}


public OnMapStart() {
	OnMapStart2();
}
	
public OnMapStart2() {
	//maxplayers = GetMaxClients();
	new ent, Float:position[3], Float:angle[3], String:propName[128];
	/*while ((ent = FindEntityByClassname(ent, "team_control_point")) != -1){
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
		GetEntPropVector(ent, Prop_Send, "m_angRotation", angle);
		g_AudienceNum += 1;
		PushArrayCell(g_Audience, position[0]);
		PushArrayCell(g_Audience, position[1]);
		PushArrayCell(g_Audience, position[2]);
		PushArrayCell(g_Audience, angle[0]);
		PushArrayCell(g_Audience, angle[1]);
		PushArrayCell(g_Audience, angle[2]);
	}*/
	
	new playas;
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			playas ++;
		}
	}
	
	ServerCommand("stb_enabled 0");
	ServerCommand("sv_cheats 1");
	ServerCommand("sm_kick @bots");
	if(playas < 3){
		for(new i=1; i <= g_Bots; i++){
			ServerCommand("bot -class \"scout\" -team \"blu\" -name \"[TF2 SK] Punchbag #%i\"", i);
		}
	}
	if(g_Failbot){
		ServerCommand("bot -class \"medic\" -team \"blu\" -name \"%s\"", TAKER_OF_LIFE);
		ServerCommand("bot -class \"medic\" -team \"red\" -name \"%s\"", GIVER_OF_LIFE);
		g_TakerOfLife = FindClientByName(TAKER_OF_LIFE);
		g_GiverOfLife = FindClientByName(GIVER_OF_LIFE);
		PrintToChatAll("[%i] [%i]", g_TakerOfLife, g_GiverOfLife);
		TeleportEntity(g_TakerOfLife, g_MilesAway, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(g_GiverOfLife, g_MilesAway, NULL_VECTOR, NULL_VECTOR);
	}
	//ServerCommand("sv_cheats 0");
	ServerCommand("mp_waitingforplayers_cancel 1");
	
	
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
	
	
	
	g_Restarting = false;
	
	
	/*while ((ent = FindEntityByClassname(ent, "info_player_teamspawn")) != -1){
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
		GetEntPropVector(ent, Prop_Send, "m_angRotation", angle);
		g_SpawnNum += 1;
		PushArrayCell(g_SpawnPoints, position[0]);
		PushArrayCell(g_SpawnPoints, position[1]);
		PushArrayCell(g_SpawnPoints, position[2]);
		PushArrayCell(g_SpawnPoints, angle[0]);
		PushArrayCell(g_SpawnPoints, angle[1]);
		PushArrayCell(g_SpawnPoints, angle[2]);	
	}*/
	g_RoundEnd = false;
	g_JustStarted = true;
	CreateTimer(15.0, JustStarted);
	
	
	//remove shooters just in case it's a live restart
	/*while ((ent = FindEntityByClassname(ent, "env_shooter")) != -1){
		CreateTimer(4.0, Timer_DestroyEntity, ent);
	}*/
	
	ClearArray(g_Audience);
	g_AudienceNum = 0;
		
		
	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1){
		if(IsValidEntity(ent)){
			GetEntPropString(ent, Prop_Data, "m_ModelName", propName, sizeof(propName));
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
			GetEntPropVector(ent, Prop_Send, "m_angRotation", angle);
			//PrintToServer(propName);
			if(StrEqual(propName, "models/props_2fort/chimney001.mdl")){
				g_Podium[0][0][0] = position[0];
				g_Podium[0][0][1] = position[1];
				g_Podium[0][0][2] = position[2];
				g_Podium[0][1][0] = angle[0];
				g_Podium[0][1][1] = angle[1];
				g_Podium[0][1][2] = angle[2];
				//env_shooter(0, position);
				//CreateTimer(4.0, Timer_DestroyEntity, ent);
				//AcceptEntityInput(ent, "kill");			
			} else if(StrEqual(propName, "models/props_2fort/chimney002.mdl")){
				g_Podium[1][0][0] = position[0];
				g_Podium[1][0][1] = position[1];
				g_Podium[1][0][2] = position[2];
				g_Podium[1][1][0] = angle[0];
				g_Podium[1][1][1] = angle[1];
				g_Podium[1][1][2] = angle[2];
				//env_shooter(1, position);
				//CreateTimer(4.0, Timer_DestroyEntity, ent);
			} else if(StrEqual(propName, "models/props_2fort/chimney003.mdl")){
				g_Podium[2][0][0] = position[0];
				g_Podium[2][0][1] = position[1];
				g_Podium[2][0][2] = position[2];
				g_Podium[2][1][0] = angle[0];
				g_Podium[2][1][1] = angle[1];
				g_Podium[2][1][2] = angle[2];
				//env_shooter(2, position);
				//CreateTimer(4.0, Timer_DestroyEntity, ent);
			} else if(StrEqual(propName, "models/props_2fort/chimney004.mdl")){
				g_AudienceNum += 12;
				PushArrayCell(g_Audience, position[0]);
				PushArrayCell(g_Audience, position[1]);
				PushArrayCell(g_Audience, position[2]);
				/*PushArrayCell(g_Audience, angle[0]);
				PushArrayCell(g_Audience, angle[1]);
				PushArrayCell(g_Audience, angle[2]);*/
				PushArrayCell(g_Audience, 180.0);
				PushArrayCell(g_Audience, 180.0);
				PushArrayCell(g_Audience, 180.0);
				PushArrayCell(g_Audience, position[0]-120);
				PushArrayCell(g_Audience, position[1]);
				PushArrayCell(g_Audience, position[2]);
				PushArrayCell(g_Audience, 180.0);
				PushArrayCell(g_Audience, 180.0);
				PushArrayCell(g_Audience, 180.0);
				//CreateTimer(4.0, Timer_DestroyEntity, ent);
			}	
		}
	}
	
	//fragst[0] = 0;
	//fragst[1] = 0;
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");		
	PrecacheSound("buttons/button14.wav");
	PrecacheSound("buttons/button17.wav");
	PrecacheSound("vo/intel_teamreturned.wav");
	PrecacheSound("vo/intel_enemyreturned.wav");
	PrecacheSound("vo/intel_enemyreturned2.wav");
	PrecacheSound("vo/intel_enemyreturned3.wav");
	PrecacheSound("misc/your_team_won.wav");
	PrecacheSound("misc/your_team_lost.wav");
}

public Action:JustStarted(Handle:infoTimer){
	g_JustStarted = false;
}


public Action:Timer_Info(Handle:infoTimer){
	// Hopefully this isn't too much advertising :P
	PrintToChatAll("\x05[TF2 SK] \x03This server is running \x04TF2 SK Mod by Darkimmortal\x03, created for GamingMasters.co.uk.");
	PrintToChatAll("\x05[TF2 SK] \x03Type \x04!score\x03 to see the scores (Spectators only).");
}


public OnClientPutInServer(client) {
	//frags[client] = 0;
	//lives[client] = 0;
	g_Dead[client] = false;
	g_DeadATM[client] = false;
	g_Blind[client] = false;
	g_Lives[client] = g_MaxLives;
	if(g_Failbot && IsClientInGame(client) && !IsFakeClient(client))
		ResetClientScore(client);
	g_Kills[client] = 0;
	prot[client] = false;
	/*new playas = 0;
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)){
			playas ++;
		}
	}
	if(playas > 2 && IsClientInGame(client))
		ChangeClientTeam(client, TEAM_BLUE);*/
}

stock GetClientScore(client){
	return TF2_GetPlayerResourceData(client, TFResource_TotalScore);
}

public ResetClientScore(client){
	if(IsClientInGame(client)){
		for(new i = GetClientScore(client); i < g_Lives[client]; i++){		
			new Handle:newEvent = CreateEvent("player_hurt", true);
			SetEventInt(newEvent, "userid", GetClientUserId(g_GiverOfLife));
			SetEventInt(newEvent, "attacker", GetClientUserId(client));
			SetEventInt(newEvent, "health", 500);
			//SetEventString(newEvent, "weapon", "syringegun_medic");
			FireEvent(newEvent, false);
		}
	}
}

public DecClientScore(client){
	new Handle:newEvent = CreateEvent("player_death", true);
	SetEventInt(newEvent, "userid", GetClientUserId(g_TakerOfLife));
	SetEventInt(newEvent, "attacker", GetClientUserId(client));
	SetEventInt(newEvent, "health", 500);
	//SetEventString(newEvent, "syringegun_medic", "syringegun_medic");    
	SetEventBool(newEvent, "headshot", false);
	FireEvent(newEvent, false);
}

public FindClientByName(String:dName[255]){
	decl String:cName[255];
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i)){
			GetClientName(i, cName, sizeof(cName));
			PrintToChatAll("[%s] == [%s]", cName, dName);
			if(strcmp(cName, dName) == 0){
				return i;
			}
		}
	}
	return -1;		
}



stock blind(client, amount){
	new targets[2];
	targets[0] = client;
	new Handle:message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);		
	//if (amount == 0)
	//{
	BfWriteShort(message, (0x0001 | 0x0010));
	//}
	//else
	//{
	//	BfWriteShort(message, (0x0002 | 0x0008));
	//}		
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);		
	EndMessage();
}


public Action:Timer_Unblind(Handle:Timer_Unblind, any:client){
	g_Blind[client] = false;
	PrintHintText(client, "You were blinded for attempting to use the sniper scope, which is cheating.");
	blind(client, 0);
}

public Action:PreThinkHook(client) {
	new buttons = GetEntProp(client, Prop_Data, "m_nButtons", buttons);
	if(g_NoScope && (buttons & IN_ATTACK2) == IN_ATTACK2){		
		if(!g_Blind[client]){
			decl String:wep[255];
			GetClientWeapon(client, wep, sizeof(wep));
			ReplaceString(wep, sizeof(wep), "tf_weapon_", "");
			if(StrEqual(wep, "sniperrifle")){				
				g_Blind[client] = true;
				blind(client, 255);		
				CreateTimer(2.0, Timer_Unblind, client);
			}
		}
		//ForcePlayerSuicide(client);		
		//PrintHintText(client, "You were killed for attempting to use the sniper scope, which is cheating.");
		buttons &= ~(IN_ATTACK2);
		SetEntProp(client, Prop_Data, "m_nButtons", buttons);
	}
	return Plugin_Continue;
}
public Action:TakeDamageHook(client, attacker, inflictor, Float:damage, &Float:multiplier, damagetype) {
	if(damagetype & DMG_FALL) {
		multiplier *= g_fFall;
		return Plugin_Changed;
	}
	if(attacker>0 && attacker<=MaxClients && !roundend) {
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Cvar_fall(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fFall = GetConVarFloat(g_hFall);
}
public Cvar_spawn(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iSpawn = GetConVarInt(g_hSpawn);
}
public Cvar_mult(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bMult = GetConVarBool(g_hMult);
}
public Cvar_accel(Handle:convar, const String:oldValue[], const String:newValue[]) {
	SetConVarInt(accel, GetConVarInt(g_hAccel), true);
}
public Cvar_ff(Handle:convar, const String:oldValue[], const String:newValue[]) {
	bmpff = GetConVarBool(mpff);
}

public Cvar_maxlives(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_MaxLives = GetConVarInt(g_hMaxLives);
}
public Cvar_bots(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_Bots = GetConVarInt(g_hBots);
}
public Cvar_meleedistance(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_MeleeDistance = GetConVarInt(g_hMeleeDistance);
}
public Cvar_noscope(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_NoScope = GetConVarBool(g_hNoScope);
}
public Cvar_health(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_Health = GetConVarBool(g_hHealth);
}

public GiveWep(client, const String:weaponName[]){
	
	if (!KvJumpToKey(hKV, weaponName))
	{
		PrintToChat(client, "\x05[TF2 SK] \x03Invalid weapon name.");
	}

	new weaponSlot = KvGetNum(hKV, "slot");
	//new weaponClip = KvGetNum(hKV, "clip");
	new weaponMax = KvGetNum(hKV, "max");

	KvRewind(hKV);

	TF2_RemoveWeaponSlot(client, weaponSlot - 1);

	new weaponEntity = SDKCall(hGiveNamedItem, client, weaponName, 0, 0);
	SDKCall(hWeaponEquip, client, weaponEntity);

	if (weaponMax != -1)
	{
		SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + weaponSlot * 4, weaponMax);
		//SetEntData(GetPlayerWeaponSlot(client, weaponSlot - 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), weaponClip);
	}
}
/*
public Action:Respawn(Handle:timer, any:client) {
	if(IsClientInGame(client)){
		TF2_RespawnPlayer(client);
	}
}*/
		
public Action:Equip(Handle:timer, any:client) {
	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		TF2_RemoveWeaponSlot(client, 3);	
		TF2_RemoveWeaponSlot(client, 4);	
		TF2_RemoveWeaponSlot(client, 5);
		GiveWep(client, "tf_weapon_club");
		//EquipPlayerWeapon(client, 2);
		if(g_Madness){
			GiveWep(client, "tf_weapon_minigun");
			GiveWep(client, "tf_weapon_pipebomblauncher");
		} else {
			GiveWep(client, "tf_weapon_sniperrifle");
		}
		//EquipPlayerWeapon(client, 0);
		
	}
}


public Action:Command_SK_EpicWin(client, args){
	PrintToChat(client, "\x05[TF2 SK] \x03Enjoy!");
	TF2_RemoveWeaponSlot(client, 0);
	GiveWep(client, "tf_weapon_minigun");
}

public Action:Command_SK_Madness(client, args){
	//PrintToChat(client, "\x05[TF2 SK] \x03Enjoy!");
	g_Madness = true;
	
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i)) {
			TF2_RemoveWeaponSlot(i, 0);
			GiveWep(i, "tf_weapon_minigun");
			g_Lives[i] = 40;
		}
	}
	
	PrintHintTextAll("MADNESS MODE INITIATED BY AN ADMIN UNTIL END OF ROUND!");
}
	
public Action:Command_SK_Restart(client, args){
	PrintToChatAll("\x05[TF2 SK] \x03An automatic round restart was just triggered by an admin.");
	CreateTimer(0.1, RestartRound);
}
	
public Action:Respawn(Handle:timer, any:client) {
	if(IsClientInGame(client) && !IsPlayerAlive(client)/* && !roundend*/) {
		TF2_RespawnPlayer(client);
	}
}
public Action:SpawnProt(Handle:timer, any:client) {
	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		SetEntityRenderMode(client, RENDER_NORMAL);
		//SetEntityRenderColor(client, g_bFullB&&GetClientTeam(client)==3?0:255, g_bFullB?0:255, g_bFullB&&GetClientTeam(client)==2?0:255, 255);
		prot[client] = false;
	}
}
public Action:WelcomeMessage(Handle:timer, any:client) {
	if(IsClientInGame(client)) {
		PrintToChat(client, "\x05[TF2 SK] \x03Welcome to \x04TF2 Scoutzknivez\x03 v%s.", PL_VERSION);
		PrintToChat(client, "\x05[TF2 SK] \x03Plugin by Darkimmortal. Map by Darkimmortal and Geitiegg.");
	}
}
/*
OnlyPlayerAlive(client) {
	//new team = GetClientTeam(client);
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i) && IsPlayerAlive(i) && client != i) {
			//if(GetClientTeam(i)==team) {
			return false;
			//}
		}
	}
	return true;
}*/
GetOnlyPlayerAlive() {
	//new team = GetClientTeam(client);
	new playas = 0;
	new client;
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i)/* && !IsFakeClient(i) */&& GetClientTeam(i) == TEAM_BLUE/* && g_Lives[i] > 0*/) {
			playas ++;
			client = i;
		}
	}
	if(playas == 1)
		return client;
	else
		return -1;
	/*if(playas > 1 || playas == 0)
		return -1;
	else
		return client;*/
}

public Action:RestartRound(Handle:restartTimer){	
	
	new timeleft;
	GetMapTimeLeft(timeleft);
	g_Madness = false;
	if(timeleft < 1 && !g_TimeLimitZero){
		//PrintHintTextAll("Please be patient while TF2 SK triggers teamplay_round_win so the next map can begin...");
		PrintToChatAll("\x05[TF2 SK] \x03Please be patient while TF2 SK triggers a round end so the next map can begin...");
		new edict_index = FindEntityByClassname(-1, "team_control_point_master");
		if (edict_index == -1){
			new g_ctf = CreateEntityByName("team_control_point_master");
			DispatchSpawn(g_ctf);
			AcceptEntityInput(g_ctf, "Enable");
		}
		new control = FindEntityByClassname(-1, "team_control_point_master");
		SetVariantInt(TEAM_BLUE);
		AcceptEntityInput(control, "SetWinner");
	} else {
		for(new i=1;i<=MaxClients;i++) {
			if(IsClientInGame(i)){
				g_Dead[i] = false;
				g_DeadATM[i] = false;
				g_Blind[i] = false;
				//g_Lives[
				OnClientPutInServer(i);
				TF2_RespawnPlayer(i);			
				/*new hudflags = GetEntProp(i, Prop_Send, "m_iHideHUD");
				hudflags |= HIDEHUD_CROSSHAIR;
				hudflags |= HIDEHUD_MISCSTATUS;
				SetEntProp(i, Prop_Send, "m_iHideHUD", hudflags);*/
				new hudflags = GetEntProp(i, Prop_Send, "m_iHideHUD");
				hudflags |= HIDEHUD_CROSSHAIR;
				hudflags |= HIDEHUD_MISCSTATUS;
				hudflags |= HIDEHUD_VEHICLE_CROSSHAIR;				
				SetEntProp(i, Prop_Send, "m_iHideHUD", hudflags);
				SetEntityMoveType(i, MOVETYPE_WALK);
			}
		}
		g_RoundEnd = false;
		//ClearArray(g_KillOrder);
		new Handle:newEvent = CreateEvent("teamplay_round_start", true);
		FireEvent(newEvent, false);
		g_Restarting = false;
	}
}

public Action:Timer_Menu(Handle:menuTimer){	
	RemoveAllMenuItems(g_scores);
	SetMenuTitle(g_scores, "TF2 SK - Scoreboard");
	decl String:cName[255], String:dName[255];
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i)/* && !IsFakeClient(i)*/){
			GetClientName(i, cName, sizeof(cName));
			Format(dName, sizeof(dName), "%s (%i:%i)", cName, g_Kills[i], g_Lives[i]);
			AddMenuItem(g_scores, dName, dName, (GetClientTeam(i) == TEAM_BLUE ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));			
			
			//little DeadATM fix...
			if(IsPlayerAlive(i)){
				g_DeadATM[i] = false;
			}
		}
	}
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[255];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
        else
        {
           // LogError("DeleteParticles: not removing entity - not a particle '%s'", classname);
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
public AttachParticle(ent, String:particleType[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
		new Float:pos[3];
		decl String:tName[255];
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

public Action:Timer_SpamLol(Handle:spamLolTimer, any:i){
	new Float:paas[3];
	paas = Float:g_Podium[i][0];
	for(new lol = 0; lol < 10; lol+=1){
		paas[2] += 20;
		paas[1] += 30;
		paas[1] += (GetRandomInt(0, 1) == 1 ? -10 : 10);
		ShowParticle(paas, "achieved", 15.0);
		paas[1] -= 60;
		ShowParticle(paas, "achieved", 15.0);
		paas[1] += 30;
	}
}

stock PrintHintTextAll(String:Text[640]){	
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i)){
			PrintHintText(i, Text);
		}
	}
}

public Action:EpicWin(Handle:winTimer, any:fclient){
	
	//if(true || playas > 1){

	new client = GetOnlyPlayerAlive();
	new i;
	//PrintToServer("\n\n---------------------%i]\n\n", client);
	//if(OnlyPlayerAlive(client)){
	if(!g_Restarting && !g_JustStarted && client != -1){
		g_RoundEnd = true;
		new String:KOName[3][255], winners[3] = {1, ...}, KOSize;
		new Handle:KillOrder2 = CreateArray(g_ArraySize);
		
		for(i=1;i<=MaxClients;i++) {
			if(IsClientInGame(i)){
				KOSize++;
				PushArrayCell(KillOrder2, g_Kills[i]);
			}
		}
		SortADTArray(KillOrder2, Sort_Descending, Sort_Integer);
		//PrintToChatAll("\x05[TF2 SK] \x03Debug: \x04[%i] [%i] [%i]", GetArrayCell(KillOrder2, 0), GetArrayCell(KillOrder2, 1), GetArrayCell(KillOrder2, 2));
		
		for(i=1;i<=MaxClients;i++) {
			if(IsClientInGame(i)){
				if(g_Kills[i] == GetArrayCell(KillOrder2, 0))
					winners[0] = i;
				else if(g_Kills[i] == GetArrayCell(KillOrder2, 1))
					winners[1] = i;
				else if(g_Kills[i] == GetArrayCell(KillOrder2, 2))
					winners[2] = i;
			}
		}
		
		
		
		//new KOSize = GetArraySize(g_KillOrder);
		
		/*decl String:KOD[255];
		for(new i = 0; i < KOSize; i++){
			GetClientName(GetArrayCell(g_KillOrder, i), KOD, sizeof(KOD));
			PrintToChatAll("\x05[TF2 SK] \x03Debug: \x04%s", KOD);
		}*/
		/*winners[0] = client;		
		if(KOSize >= 3){
			winners[1] = GetArrayCell(g_KillOrder, KOSize-2);
			winners[2] = GetArrayCell(g_KillOrder, KOSize-1);
		}*/
		new audiencePos = 0;
		decl Float:position[3], Float:angle[3] = {0.0, 180.0, 0.0};
		for(i=1;i<=MaxClients;i++) {
			if(IsClientInGame(i) && i != winners[0] && i != winners[1] && i != winners[2] && audiencePos < g_AudienceNum) {
				position[0] = GetArrayCell(g_Audience, audiencePos+0);
				position[1] = GetArrayCell(g_Audience, audiencePos+1);
				position[2] = GetArrayCell(g_Audience, audiencePos+2);
				/*angle[0] = GetArrayCell(g_Audience, audiencePos+0);
				angle[1] = GetArrayCell(g_Audience, audiencePos+1);
				angle[2] = GetArrayCell(g_Audience, audiencePos+2);*/
				g_Blind[i] = false;
				ChangeClientTeam(i, TEAM_BLUE);
				TF2_RespawnPlayer(i);
				TeleportEntity(i, position, angle, NULL_VECTOR);
				//SetEntityMoveType(i, MOVETYPE_NONE);
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
				audiencePos += 6;
				EmitSoundToClient(i, "misc/your_team_lost.wav");
			}
		}
		new /*Float:paas[3],*/ Float:lol;
		
		for(lol = 0.0; lol < 15.0; lol+=3.0){
			CreateTimer(lol, Timer_SpamLol, 0);
		}
			
		for(i = 0; i <= (KOSize >= 3 ? 2 : 0); i++){
			g_Dead[winners[i]] = false;
			g_DeadATM[winners[i]] = false;
			g_Blind[i] = false;
			GetClientName(winners[i], KOName[i], 255);
			ChangeClientTeam(winners[i], TEAM_BLUE);
			TF2_RespawnPlayer(winners[i]);
			TeleportEntity(winners[i], g_Podium[i][0], g_Podium[i][1], NULL_VECTOR);
			SetEntityMoveType(winners[i], MOVETYPE_NONE);
			EmitSoundToClient(winners[i], "misc/your_team_won.wav");
			SetEntProp(winners[i], Prop_Data, "m_takedamage", 0, 1);
			//shoot_shooter(i, winners[i]);
		}
		if(KOSize >= 3){		
			PrintToChatAll("\x05[TF2 SK] \x04%s\x03 (%i:%i) just won the game; \x04%s\x03 (%i:%i) came second and \x04%s\x03 third (%i:%i).", 
			KOName[0], g_Kills[winners[0]], g_Lives[winners[0]], KOName[1], g_Kills[winners[1]], g_Lives[winners[1]], 
			KOName[2], g_Kills[winners[2]], g_Lives[winners[2]]);
		} else if(KOSize >= 2) {
			PrintToChatAll("\x05[TF2 SK] \x04%s\x03 (%i:%i) just won the game.", KOName[0], g_Kills[winners[0]], g_Lives[winners[0]]);
		}
		PrintToChatAll("\x05[TF2 SK] \x04Next round in 15 seconds.");
		CreateTimer(15.0, RestartRound);
		g_Restarting = true;
		
		new playas = 0;
		new gayplaya;
		for(i=1;i<=MaxClients;i++) {
			if(IsClientInGame(i)){
				playas ++;
				gayplaya = i;
			}
		}
		if(playas == 1){	
			PrintToChatAll("\x05[TF2 SK] \x03Weird things will happen until someone else joins. Please be patient.");		
			PrintHintText(gayplaya, "Weird things will happen until someone else joins. Please be patient.");
		}
		
	}
}

public Action:Event_player_disconnect(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//CreateTimer(0.5, EpicWin, client);
	new playas = 0;
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i)){
			playas ++;
		}
	}
	if(playas <= 1){
		ServerCommand("sm_kick @bots");	
		//if(NumPlayers() < 4){
		ServerCommand("sv_cheats 1");
		for(new i=1; i < g_Bots; i++){
			ServerCommand("bot -class \"scout\" -team \"blu\" -name \"[TF2 SK] Punchbag #%i\"", i);
		}
		ServerCommand("sv_cheats 0");	
		//}
	}
	
	g_Kills[client] = 0;
	
	decl String:reason[128], String:cName[255];
	GetClientName(client, cName, sizeof(cName));
	GetEventString(event, "reason", reason, 128);
	if(!IsFakeClient(client) && client!=0 && StrEqual(reason, "Disconnect by user.")){
		//PrintToChatAll("\x01Player %s left the game (\x03Impatient, retarded noob.\x01)", cName);
		//return Plugin_Stop;
		
		//SetEventString(event, "reason", "Impatient, retarded noob.");
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
	
public Action:Event_player_authorized(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new playas = 0;
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)){
			playas ++;
		}
	}
	if(playas > 4 && !g_JustStarted){
		g_Dead[client] = true;
		//g_DeadATM[client] = true;
		g_Lives[client] = 0;
		g_Kills[client] = 0;
		//ChangeClientTeam(client, TEAM_SPEC);
		PrintToChat(client, "\x05[TF2 SK] \x03You just joined so you're sitting out till the next round to maintain fair gameplay.");		
		PrintHintText(client, "You just joined so you're sitting out till the next round to maintain fair gameplay.");
	}
	if(playas <= 1){	
		PrintToChatAll("\x05[TF2 SK] \x03Weird things will happen until someone else joins. Please be patient.");		
		PrintHintTextAll("Weird things will happen until someone else joins. Please be patient.");
	}
	if(playas > 1){
		ServerCommand("sm_kick punchbag");		
		/*if(NumPlayers() < 4){
			ServerCommand("sv_cheats 1");
			ServerCommand("bot -class \"scout\" -team \"blu\" -name \"[TF2 SK] Punchbag\"");
			ServerCommand("sv_cheats 0");	
		}*/
	}
	g_Blind[client] = false;
		
	
	//CreateTimer(0.5, EpicWin, client);
}

public Action:Event_player_death_before(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(client == attacker){
		return Plugin_Handled;
	}
	if(g_Failbot){
		decl String:cName[255];
		GetClientName(client, cName, sizeof(cName));
		if(strcmp(cName, GIVER_OF_LIFE) == 0 || strcmp(cName, TAKER_OF_LIFE) == 0){
			return Plugin_Continue;
		} else {
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}
	
public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast){
	decl String:weaponname[32];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(g_Failbot){
		decl String:cName[255];
		GetClientName(client, cName, sizeof(cName));
		if(strcmp(cName, GIVER_OF_LIFE) == 0 || strcmp(cName, TAKER_OF_LIFE) == 0){
			TF2_RespawnPlayer(client);
			return Plugin_Continue;
		}
	}
	//new bool:headshot = GetEventBool(event, "headshot");
	//PrintToChatAll("Headshot: %i", headshot);
	//ClientCommand(client, "r_screenoverlay 0");
	GetEventString(event, "weapon", weaponname, sizeof(weaponname));
	
	//show hud for !score when speccing etc.
	new hudflags = GetEntProp(client, Prop_Send, "m_iHideHUD");
	//hudflags &= ~(HIDEHUD_CROSSHAIR);
	hudflags &= ~(HIDEHUD_MISCSTATUS);
	SetEntProp(client, Prop_Send, "m_iHideHUD", hudflags);
	
	//new plives = g_Lives[client];
	
	
	//if(strcmp(weaponname, "sniperrifle")!=0 || strcmp(weaponname, "club")!=0) {
	//	return Plugin_Handled;
	//}
	//new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	//new spawn = true;
	if(!g_JustStarted && client != attacker){
		//PushArrayCell(g_KillOrder, attacker);
		g_Kills[attacker] += 1;
		if(g_Kills[attacker] % 5 == 0 && !g_Madness){
			PrintToChat(attacker, "\x05[TF2 SK] \x03You just got an extra life for making 5 kills in one round.");
			g_Lives[attacker] += 1;
		}			
		g_Lives[client] -= 1;
		if(g_Lives[client] < 1){
			g_Dead[client] = true;	
			ChangeClientTeam(client, TEAM_SPEC);
			PrintToChat(client, "\x05[TF2 SK] \x03You just died and you have no lives remaining, so you're staying dead until the next round.");		
			PrintHintText(client, "You just died and you have no lives remaining, so you're staying dead until the next round.");
		} else {
			g_Dead[client] = false;
			PrintToChat(client, "\x05[TF2 SK] \x03You just died; \x04%i\x03 %s remaining.", g_Lives[client], (g_Lives[client] == 1 ? "life" : "lives"));
			g_DeadATM[client] = true;
			CreateTimer(g_Madness ? 0.1 : 1.5, Respawn, client);
			
		}
	}
	//CreateTimer(0.5, EpicWin, client);
	//PrintToChatAll("\x05[TF2 SK] Debug: This was not the last player.");
		
	
	if(prot[client]) {
		prot[client] = false;
	}
	/*if(spawn) {
		CreateTimer(3.0, Respawn, client);
	}*/
	return Plugin_Continue;
}
public Action:Event_player_spawn_before(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(g_RoundEnd){
		return Plugin_Handled;
	}
	if(IsClientInGame(client)) {
		FakeClientCommand(client, "menuselect 0");
		/*if(client != attacker && IsPlayerAlive(client)){
			g_Lives[client] -= 1;
		}*/
		if(g_Dead[client] && !g_RoundEnd){
			//PrintToChat(client, "\x05[TF2 SK] \x03Debug: Kept dead.");
			ForcePlayerSuicide(client);
			return Plugin_Stop;
		} else {
			//PrintToChat(client, "\x05[TF2 SK] \x03Debug: Not kept dead.");			
		}
	}	
	return Plugin_Continue;
}


stock NumPlayers(){
	new i, playas;
	for(i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			playas ++;
		}
	}
	return playas;	
}

public Action:Timer_HUD(Handle:hudTimer){
	new i, playas = NumPlayers();
	for(i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && playas > 1) {
			SetHudTextParams(0.04, 0.53, 1.3, 45, 213, 53, 255);	
			ShowSyncHudText(i, HudMessage, "Kills: %i\nLives: %i", g_Kills[i], g_Lives[i]);
			if(g_Dead[i]){				
				SetHudTextParams(0.25, 0.33, 1.3, 255, 0, 0, 255);	
				ShowSyncHudText(i, HudMessage2, "   You're out of lives or you just joined.\n  Please wait until the next round to play.\n\nUse !score to see how many lives are remaining.");
			}
		}
	}
	/*SetHudTextParams(0.04, 0.55, 5.0, 45, 213, 53, 255);	
	for(i = 1; i <= maxplayers; i++) {
		if(i && IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i)){
			ShowSyncHudText(i, HudMessage, "Kills: %dk", g_Money[i]);
		}
	}*/
}


public Action:Event_player_team_before(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientOfUserId(GetEventInt(event, "team"));
	
	if(g_Dead[client] && !g_RoundEnd && (team == TEAM_RED || team == TEAM_BLUE)){
		PrintHintText(client, "Are you blind? YOU'RE DEAD AND YOU HAVE TO WAIT.");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//if() {
		//ClientCommand(client, "r_screenoverlay instagib/crosshairoverlay.vmt");
	new playas = 0;
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i)/* && !IsFakeClient(i)*/){
			playas ++;
		}
	}
	
	decl String:cName[255];
	GetClientName(client, cName, sizeof(cName));
	
	if(!g_JustStarted && playas > 1 && IsClientInGame(client) && !(strcmp(cName, GIVER_OF_LIFE) == 0 || strcmp(cName, TAKER_OF_LIFE) == 0)){
		if(_:TF2_GetPlayerClass(client)!=1) {
			TF2_SetPlayerClass(client, TFClassType:1);
		}
		

		if(g_Dead[client] && !g_RoundEnd && (GetClientTeam(client) == TEAM_RED || GetClientTeam(client) == TEAM_BLUE)){
			PrintHintText(client, "YOU'RE DEAD AND YOU HAVE TO WAIT. Just be patient.");			
			ChangeClientTeam(client, TEAM_SPEC);
		} else {
			ChangeClientTeam(client, TEAM_BLUE);
		}
	
		if(GetClientTeam(client) == TEAM_RED){
			ChangeClientTeam(client, TEAM_BLUE);
			ForcePlayerSuicide(client);
			return Plugin_Handled;
		}	
		
		//SetEntProp(client, Prop_Data, "m_CollisionGroup", 4);
		
		if(!g_RoundEnd) {
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			//SetEntityRenderColor(client, g_bFullB&&GetClientTeam(client)==3?0:255, g_bFullB?0:255, g_bFullB&&GetClientTeam(client)==2?0:255, 192);
			CreateTimer(float(g_iSpawn), SpawnProt, client);
			prot[client] = true;
			new hudflags = GetEntProp(client, Prop_Send, "m_iHideHUD");
			if(g_OldHUD[client] == 0)
				g_OldHUD[client] = hudflags;
			hudflags |= HIDEHUD_CROSSHAIR;
			hudflags |= HIDEHUD_VEHICLE_CROSSHAIR;
			hudflags |= HIDEHUD_MISCSTATUS;
			
			//hudflags = hudflags | HIDEHUD_MISCSTATUS;
			SetEntProp(client, Prop_Send, "m_iHideHUD", hudflags);
		//} else {
		////	SetEntityRenderColor(client, g_bFullB&&GetClientTeam(client)==3?0:255, g_bFullB?0:255, g_bFullB&&GetClientTeam(client)==2?0:255, 255);
		} else {
			/*new hudflags = GetEntProp(client, Prop_Send, "m_iHideHUD");
			//hudflags ~= HIDEHUD_CROSSHAIR;
			//hudflags = hudflags ^ HIDEHUD_MISCSTATUS;
			hudflags = HIDEHUD_MISCSTATUS ~ hudflags;
			//hudflags ^= HIDEHUD_MISCSTATUS;*/
			//SetEntProp(client, Prop_Send, "m_iHideHUD", g_OldHUD[client]);
			new hudflags = GetEntProp(client, Prop_Send, "m_iHideHUD");
			//hudflags &= ~(HIDEHUD_CROSSHAIR);
			hudflags &= ~(HIDEHUD_MISCSTATUS);
			//hudflags = hudflags | HIDEHUD_MISCSTATUS;
			SetEntProp(client, Prop_Send, "m_iHideHUD", hudflags);
		}
		g_DeadATM[client] = false;
		CreateTimer(0.01, Equip, client);
	} else {		
	/*	if(g_Failbot){
			if(strcmp(cName, GIVER_OF_LIFE) == 0 || strcmp(cName, TAKER_OF_LIFE) == 0){
				TF2_ForcePlayerSpawn(client);
			}
		}*/
	}
		
		/*decl Float:position[3], Float:angle[3];
		new spawnPos = GetRandomInt(0, g_SpawnNum);
		
		position[0] = GetArrayCell(g_SpawnPoints, spawnPos+0);
		position[1] = GetArrayCell(g_SpawnPoints, spawnPos+1);
		position[2] = GetArrayCell(g_SpawnPoints, spawnPos+2);
		angle[2] = GetArrayCell(g_SpawnPoints, spawnPos+3);
		angle[2] = GetArrayCell(g_SpawnPoints, spawnPos+4);
		angle[2] = GetArrayCell(g_SpawnPoints, spawnPos+5);
		TeleportEntity(client, position, angle, NULL_VECTOR);*/
	//}
	return Plugin_Continue;
}



public Action:Command_Equip(client, args){
	CreateTimer(0.01, Equip, client);
	return Plugin_Stop;
}


public scoresHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/*switch (action)
	{
		case MenuAction_Select:
		{			
		
		}
	}*/
}

public Action:Command_Score(client, args){
	if(IsClientInGame(client)){	
		if(GetClientTeam(client) != TEAM_SPEC){
			PrintHintText(client, "The scoreboard is only available to spectators.");
		} else {
			DisplayMenu(g_scores, client, MENU_TIME_FOREVER);
			PrintToChat(client, "\x05[TF2 SK] \x03Scores are displayed as:- \x04NAME\x03: (\x04KILLS\x03:\x04LIVES\x03)");				
		}
	}
}

public Action:Event_teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	roundend = false;
	new regenc = -1;
	while((regenc = FindEntityByClassname(regenc, "func_regenerate"))!=-1) {
		AcceptEntityInput(regenc, "Disable");
	}	
	
	for(new i=1;i<=MaxClients;i++) {
		g_Dead[i] = false;
		g_Kills[i] = 0;
		g_Lives[i] = g_MaxLives;
		//OnClientPutInServer(i);
	}
}
public Action:Event_teamplay_round_win(Handle:event, const String:name[], bool:dontBroadcast) {
	new timeleft;
	GetMapTimeLeft(timeleft);
	if(timeleft > 1)
		return Plugin_Handled;
	return Plugin_Continue;
}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result) {
	if(prot[client]) {
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		SetEntityRenderMode(client, RENDER_NORMAL);
		//SetEntityRenderColor(client, g_bFullB&&GetClientTeam(client)==3?0:255, g_bFullB?0:255, g_bFullB&&GetClientTeam(client)==2?0:255, 255);
		prot[client] = false;
	}
	
	SetEntData(GetEntDataEnt2(client, offsActiveWeapon), offsClip1, 10);
	decl Float:vecOrigin[3], Float:vecAng[3], Float:vecPos[3];//, Float:darkVec;//, enty;
	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client, vecAng);
	new Handle:trace = TR_TraceRayFilterEx(vecOrigin, vecAng, /*MASK_ALL*/MASK_SHOT_HULL | CONTENTS_TEAM1 | CONTENTS_TEAM2 | CONTENTS_PLAYERCLIP, RayType_Infinite, TraceEntityFilterPlayerNoKill, client);
	
	//if(Admin(client))
	//	PrintToChatAll("HitGroup: [%X]", TR_GetHitGroup(trace));
	//PrintToChatAll("Hit'd");
	if(TR_DidHit(trace)) {
		//new hitbox = TR_GetHitGroup(trace);
		TR_GetEndPosition(vecPos, trace);
		vecOrigin[2] -= 4;
		for(new i=0;i<3;i++) {
			traceData[client][i] = vecOrigin[i];
			traceData[client][i+3] = vecPos[i];
		}
		if(StrEqual(weaponname, "tf_weapon_club")){
			//darkVec = GetVectorDistance(vecOrigin, vecPos);
			//if(darkVec[0] < 50 && darkVec[1] < 50 && darkVec[2] < 50){
			//TR_GetPointContents(vecPos, enty);
			//if(/*enty <= MaxClients && TR_GetEntityIndex(trace) < MAXPLAYERS && */darkVec < 300){
				//PrintToChatAll("\x05[TF2 SK] \x03Hit success. [%i] [%f]", enty, darkVec);						
				//PrintToChatAll("\x05[TF2 SK] \x03Hit success. [%i] [%f]", enty, darkVec);						
			//} else {				
				//PrintToChatAll("\x05[TF2 SK] \x03Hit fail. [%f]", GetVectorDistance(vecOrigin, vecPos));	
				//PrintToChatAll("\x05[TF2 SK] \x03Hit fail. [%i] [%f]", enty, darkVec);					
				//return Plugin_Continue;
			//}
		} else {
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite, g_HaloSprite, 0, 0, 0.5, 4.0, 4.0, 5, 0.0, GetClientTeam(client)==3?{255, 19, 19, 255}:{19, 19, 255, 255}, 30);
			TE_SendToAll();
		}
		g_Crit[client] = result;
	//	PrintToChatAll("\x05[TF2 SK] \x03Crit [%i]", result);					
		TR_TraceRayFilter(vecOrigin, vecPos, MASK_SHOT_HULL | CONTENTS_TEAM1 | CONTENTS_TEAM2 | CONTENTS_PLAYERCLIP, RayType_EndPoint, TraceEntityFilterPlayer, client);
		vecPos[2] += 2;
		if(!StrEqual(weaponname, "tf_weapon_club")){
			TE_SetupExplosion(vecPos, g_ExplosionSprite, 1.0, 0, 0, 192, 500);
			TE_SendToAll();
			for(new i=1;i<=MaxClients;i++) {
				if(IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(client)!=GetClientTeam(i) || bmpff || i==client)) {
					decl Float:vecAbs[3], Float:vecNorm[3], Float:vecVel[3];
					GetClientAbsOrigin(i, vecAbs);
					vecAbs[2] += 20;
					new Float:distance = GetVectorDistance(vecAbs, vecPos);
					if(distance>192 || distance==0) {
						continue;
					}
					SubtractVectors(vecAbs, vecPos, vecNorm);
					for(new n=0;n<3;n++) {
						vecNorm[n] = vecNorm[n]/((distance/10)*(distance/10))*250;
						if(vecNorm[n]>800) {
							vecNorm[n] = 800.0;
						}
					}
					GetEntPropVector(i, Prop_Data, "m_vecVelocity", vecVel);
					AddVectors(vecNorm, vecVel, vecVel);
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vecVel);
				}
			}
		}
	}
	CloseHandle(trace);
	new ent = GetEntDataEnt2(client, offsActiveWeapon);
	if(ent!=-1) {
		//weaponRateQueue[weaponRateQueueLen++] = ent;
	}
	result = false;
	return Plugin_Changed;
	//}
	//return Plugin_Continue;
}
public bool:TraceEntityFilterPlayer(entity, contentsMask, any:client) {
	decl String:wep[255];
	GetClientWeapon(client, wep, sizeof(wep));
	ReplaceString(wep, sizeof(wep), "tf_weapon_", "");
	if(entity<=MaxClients) {
		if(client==entity || prot[entity]) {
			if(prot[entity]) {
				EmitSoundToClient(client, "buttons/button14.wav", _, _, _, _, 0.75);
			}
			return false;
		} else {
			//new team = GetClientTeam(entity);
			//if(team!=GetClientTeam(client) || bmpff) {
			if(!StrEqual(wep, "club"))
				EmitSoundToClient(client, "buttons/button17.wav", _, _, _, _, 0.75);
			//PrintToChatAll("\x05[TF2 SK] \x03Fix'd Weapon: [%s]", wep);	
			new health = GetClientHealth(entity);
			decl Float:vecOrigin[3], Float:vecPos[3], Float:vecEnt[3];
			GetClientEyePosition(entity, vecEnt);
			for(new i=0;i<3;i++) {
				vecOrigin[i] = traceData[client][i];
				vecPos[i] = traceData[client][i+3];
			}
			if(!g_DeadATM[entity] && !g_DeadATM[client]){
				if(health > 1 && !StrEqual(wep, "club") && g_Health && !g_Crit[client]){
					
					SetEntityHealth(entity, 1);
				} else {
				/*if(g_bElim) {
					if(OnlyPlayerAlive(entity)) {
						if(lives[entity]<=0) {
							for(new i=1;i<MaxClients;i++) {
								if(team==GetClientTeam(i) && lives[i]>0) {
									TF2_RespawnPlayer(i);
									break;
								}
							}
							FakeClientCommand(entity, "explode");
						} else {
							TF2_RespawnPlayer(entity);
						}
					} else {
						FakeClientCommand(entity, "explode");
					}
				} else {
					FakeClientCommand(entity, "explode");
				}*/
					if(!StrEqual(wep, "club") || GetVectorDistance(vecOrigin, vecEnt) < g_MeleeDistance){
						if(StrEqual(wep, "club"))
							EmitSoundToClient(client, "buttons/button17.wav", _, _, _, _, 0.75);
						FakeClientCommand(entity, "explode");
						if(g_Failbot){
							DecClientScore(entity);
						} else {					
							new Handle:newEvent = CreateEvent("player_death", true);
							SetEventInt(newEvent, "userid", GetClientUserId(entity));
							SetEventInt(newEvent, "attacker", GetClientUserId(client));
							SetEventString(newEvent, "weapon", wep);
							//ChangeClientTeam(entity, TEAM_RED);
							FireEvent(newEvent, false);
						}
						//ChangeClientTeam(entity, TEAM_BLUE);
						TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite, g_HaloSprite, 0, 0, 3.0, 6.0, 6.0, 5, 0.0, {19, 255, 19, 255}, 30);
						TE_SendToClient(entity);
						if(g_bMult){
							return false;
						} else {
							return true;
						}
					}
				}
			}
			//}
		}
	}
	//return true;
	return !StrEqual(wep, "club");
}
public bool:TraceEntityFilterPlayerNoKill(entity, contentsMask, any:client) {
	decl String:wep[255];
	GetClientWeapon(client, wep, sizeof(wep));
	ReplaceString(wep, sizeof(wep), "tf_weapon_", "");
	if(entity<=MaxClients || StrEqual(wep, "club")) {
		return false;
	}
	return true;
}