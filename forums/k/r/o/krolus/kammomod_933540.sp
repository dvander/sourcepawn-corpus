/*
author: kroleg
url: tf2.kz
Credits: 
	thenoid
	FannyPack aka casvdry
	MikeJS
	DJ Tsunami
	exvel
	box?.Cobby
	
Changelog:
0.7
	+ added diff classlimit for arenas. 
	+ added new mode - midair.
		+ added cvar kammomod_midair_hp (Def. "5") - spawn health for midair
	+ added cvar (kammomod_blockdmg_sticky) for control blocking damage from enemy's stickies (players still can do stickyjumps)
	+ added optional parameter "cdtime"(default = 3) in spawn configs.
	+ added cvar kammomod_airshot_height
	+ improved airshot detection (only direct hits)
0.6
	+ added translation support
	+ added differnt fraglimit for arenas
	+ added rating restrictions for arenas
	+ added optional autoupdate.
	+ added cvar kammomod_dbconfig
	+ added ELO based stats (mysql or sqllite)
	+ added bots support (!botme or /botme). They are stupid for now.
	+ cvar kammomod_hpbuff_classes replaced with list of allowed classes - kammomod_allowed_classes
	+ refined airshot signs
	+ changed spawn config to format "X Y Z yaw" (w/o pitch and roll , which are always zero)
	- fixed bad spawn on am_variety badlands mid (kammomod.txt)
	- fixed infinite ammo didnt work sometimes (with some kind of crutch)
0.5 RC1
	+ changed sounds order to fit airshot signs.
	+ improved airshot detecting. Target must be at least 90 units above the ground.
	+ made some changes in code to comply with last tf2 update 
	+ added: hud message about airshot count (shows to attacker and spectating players)
	+ added: emiting airshot sound to spectating players
	+ added: cvar kammomod_airshot_signs (Def. "1" = enabled) to enable/disable showing airshot count signs above players head when they get airshotted.
0.4
	+ moved shoot detecting from CalcCritical to OnGameFrame.
	+ renamed kammomod_allowed_classes to kammomod_hpbuff_classes
	+ added: cvar kammomod_hpbuff_ratio to control ratio of hp buff (def. 6.0 = 600%)
	+ added: cvar kammomod_inf_ammo to enable/disable infinite ammo (def.  1 = enabled)
	- fixed: spawning with weapons of another class
0.3.1
	- fixed: arena&players list (chat message) length was limited to 128 char
	- fixed: GiveAmmo() dont restore FaN ammo
****************************************************************/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <entity_prop_stocks>
#include <sdkhooks>
#include <colors>

#undef REQUIRE_PLUGIN 
#include <autoupdate> 

#define PL_VERSION "0.7.1"

#define MAX_FILE_LEN 80
#define MAXARENAS 15
#define HUDFADEOUTTIME 120.0
#define MAPCONFIGFILE "configs/kammomod.txt"
#define SLOT_ONE 1 //arena slot 1
#define SLOT_TWO 2 //arena slot 2
//tf teams
#define TEAM_SPEC 1
#define TEAM_RED 2
#define TEAM_BLU 3
//arena status
#define AS_IDLE 0
#define AS_PRECOUNTDOWN 1
#define AS_COUNTDOWN 2
#define AS_FIGHT 3
#define AS_AFTERFIGHT 4
//sounds
#define SOUND_FIGHT 0
#define SOUND_FIRSTAIR 1
#define SOUND_COUNT 10
//weapon flags
#define WF_FAN 1
#define WF_SANDMAN 1>>1
//
#define DEFAULT_CDTIME 3
//
#define BLOCKDMG_STICKY_MIDAIR 1
#define BLOCKDMG_STICKY_CLASSIC 1>>1
#define BLOCKDMG_STICKY_ALL 1>>2

public Plugin:myinfo ={
  name = "kAmmomod",
  author = "kroleg",
  description = "Duel mod with infinite ammo and extra HP",
  version = PL_VERSION,
  url = "http://tf2.kz"
}

/*static const TFClass_MaxAmmo[TFClassType][3] ={
  {-1, -1, -1}, {32, 36, -1},
  {25, 75, -1}, {20, 32, -1},
  {16, 24, -1}, {150, -1, -1},
  {200, 32, -1}, {200, 32, -1},
  {24, -1, -1}, {32, 200, 200}
};
*/
static const TFClass_MaxClip[TFClassType][2] = {
  {-1, -1}, {6, 12}, {25, 0}, {4, 6}, {4, 8}, 
  {40, -1}, {-1, 6}, {-1, 6}, {6, -1}, {6, 12}
}; 
static const TFClass_NormalHP[TFClassType] = {
	-1, // unknown
	125, //scout
	125, // sniper
	200, // soldier
	175, // demo
	150, //medic
	300, //heavy
	175, //pyro
	125, //spy
	125 // engi
 };
new String:sounds[][]={ 	"quake/fight.mp3",
						"quake/hit_loud.mp3",
						"quake/outstand_loud.mp3",
						"quake/dominating.mp3",
						"quake/combowhore_loud.mp3",
						"quake/unstoppable2_loud.mp3",
						"quake/female/godlike.mp3",
						"quake/female/wickedsick.mp3",
						"quake/female/holyshit.mp3",
						"quake/female/rampage.mp3",
						"quake/perfect_loud.mp3"
};

new g_NoStats = false;

//hud handles
new Handle:hm_HP = INVALID_HANDLE,
	Handle:hm_Airshot = INVALID_HANDLE,
	Handle:hm_Score = INVALID_HANDLE;
//global vars	
new bool:g_amEnabled,
	bool:g_infAmmo,
	bool:g_particles,
	bool:g_blockFallDamage,
	bool:g_bUseSqlLite;
//database
new Handle:db = INVALID_HANDLE;
new String:g_sDBConfig[64];
//global cvars
new Handle:gcvar_WfP = INVALID_HANDLE,
	Handle:gcvar_fragLimit = INVALID_HANDLE,
	Handle:gcvar_infAmmo = INVALID_HANDLE,
	Handle:gcvar_allowedClasses = INVALID_HANDLE,
	Handle:gcvar_hpbuffRatio = INVALID_HANDLE,
	Handle:gcvar_blockFallDamage = INVALID_HANDLE,
	Handle:gcvar_airshotSigns = INVALID_HANDLE,
	Handle:gcvar_dbConfig = INVALID_HANDLE,
	Handle:gcvar_midairHP = INVALID_HANDLE,
	Handle:gcvar_airshotHeight = INVALID_HANDLE,
	Handle:gcvar_blockStickyDmg = INVALID_HANDLE	;
	
//classes 
new g_classAllowed[TFClassType];
new Float:g_hpRatio;
new g_defaultFragLimit;
//arena cvars
new 	g_arenaCount,//кол-во арен на карте
	String:g_arenaName[MAXARENAS+1][64],// название арен
	g_arenaScore[MAXARENAS+1][3],// счет фрагов
	g_arenaQueue[MAXARENAS+1][MAXPLAYERS+1],// место хранения клиентских ид участвующих в бое (SLOT_ONE и SLOT_TWO) и ожидающих (>SLOT_TWO)
	g_arenaStatus[MAXARENAS+1], // статус арены, см. #define AS_
	Float:g_arenaSpawnOrigin[MAXARENAS+1][3][3], // арена | слот | 0/1/2 = x/y/z
	Float:g_arenaSpawnAngles[MAXARENAS+1][3][3], // арены | слот | 0/1/2 = pitch/yaw/roll
	g_arenaCd[MAXARENAS+1],//countdown to round start
	g_arenaFraglimit[MAXARENAS+1],
	g_arenaMinRating[MAXARENAS+1],
	g_arenaMaxRating[MAXARENAS+1],
	g_arenaCdTime[MAXARENAS+1],
	g_arenaAllowedClasses[MAXARENAS+1][TFClassType],
	bool:g_arenaMidair[MAXARENAS+1];
	
new g_airshotHeight = 80;

//player vars
new 	g_playerArena[MAXPLAYERS+1],
	g_playerSlot[MAXPLAYERS+1],
	TFClassType:g_playerClass[MAXPLAYERS+1],
	//g_player_old_health[MAXPLAYERS + 1],
	g_playerHP[MAXPLAYERS + 1], //true HP of players
	bool:g_playerRestoringAmmo[MAXPLAYERS+1],//player is awaiting full ammo restore
	g_playerTakenAirCount[MAXPLAYERS+1],//taken airshot counter
	g_playerWeaponFlags[MAXPLAYERS+1],//weapon flags, see WF_
	g_playerSpecTarget[MAXPLAYERS+1],
	g_playerAirshotSign[MAXPLAYERS+1],
	bool:g_playerTakenDirectHit[MAXPLAYERS+1],//player was hitted directly
	String:g_playerStemID[MAXPLAYERS+1][32];//saving steamid
	
new 	bool:g_bHitBlip[MAXPLAYERS+1],
	g_playerWins[MAXPLAYERS+1],
	g_playerLosses[MAXPLAYERS+1],
	g_playerRating[MAXPLAYERS+1];

new 	g_blockStickyDmg;
	
//bot things
new bool:g_playerAskedForBot[MAXPLAYERS+1];
		
//midair
new 	g_midairHP;
	
//debug log
//new String:g_sLogFile[PLATFORM_MAX_PATH];

//offsets
new g_offNextPrimaryAttack,
	g_offObserverTarget,
	g_offAmmo,
	g_offClip;

public OnEntityCreated(entity, const String:classname[]){
	//PrintToChatAll("created %s",classname);
	if (StrEqual(classname,"tf_projectile_rocket") || StrEqual(classname,"tf_projectile_pipe")){
		SDKHook(entity, SDKHook_Touch, OnEntityTouch);
	}
}
public OnEntityTouch(entity, other){
	//PrintToChatAll("hit %N by %d",other,entity);
	if (other>0 && other<=MaxClients){
		g_playerTakenDirectHit[other] = true;
		
	}
}
public Action:OnGetGameDescription(String:gameDesc[64]){ //changing game desc
	if (g_amEnabled) {
		Format(gameDesc, sizeof(gameDesc), "kAmmomod v%s",PL_VERSION);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public OnAllPluginsLoaded() { //autoupdate stuff
    if(LibraryExists("pluginautoupdate")) AutoUpdate_AddPlugin("kammomod.googlecode.com", "/version.xml", PL_VERSION); 
} 
public OnPluginStart(){
	LoadTranslations("kammomod.phrases");
	//ConVar's
	CreateConVar("sm_kammomod_version", PL_VERSION, "kAmmomod version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	gcvar_fragLimit = CreateConVar("kammomod_fraglimit", "3", "Default frag limit in duel", FCVAR_PLUGIN,true, 1.0);
	gcvar_allowedClasses = CreateConVar("kammomod_allowed_classes", "soldier demoman scout", "Classes that players allowed to choose by default", FCVAR_PLUGIN);
	gcvar_hpbuffRatio = CreateConVar("kammomod_hpbuff_ratio", "6.0", "HP multiplier for classic mode", FCVAR_PLUGIN, true, 1.0);
	gcvar_infAmmo = CreateConVar("kammomod_infammo", "1", "Give players infinite ammo", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gcvar_blockFallDamage = CreateConVar("kammomod_blockdmg_fall", "1", "Block falldamage? (0 = Disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gcvar_airshotSigns = CreateConVar("kammomod_airshot_signs", "1", "Show airshot signs above players when they get airshotted? (0 = Disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gcvar_dbConfig = CreateConVar("kammomod_dbconfig", "default", "Name of database config", FCVAR_PLUGIN);
	gcvar_airshotHeight = CreateConVar("kammomod_airshot_height", "80", "The minimum height at which it will count airshot", FCVAR_PLUGIN, true, 10.0, true, 500.0);
	gcvar_blockStickyDmg = CreateConVar("kammomod_blockdmg_sticky", "1", "Block dmg from enemy's stickys? (0 = Disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	//
	gcvar_WfP = FindConVar("mp_waitingforplayers_cancel");
	//midair functionality
	gcvar_midairHP = CreateConVar("kammomod_midair_hp", "5", "", FCVAR_PLUGIN, true, 1.0);
	//gcvar_midairEnabled = CreateConVar("kammomod_midair_enabled", "1", "", FCVAR_PLUGIN, true, 0.0);
		
	//setting vars
	g_defaultFragLimit = GetConVarInt(gcvar_fragLimit);	
	g_hpRatio = GetConVarFloat(gcvar_hpbuffRatio);
	g_infAmmo = GetConVarInt(gcvar_infAmmo) ? true : false;
	g_blockFallDamage = GetConVarInt(gcvar_blockFallDamage) ? true : false;
	g_particles = GetConVarInt(gcvar_airshotSigns) ? true : false;
	GetConVarString(gcvar_dbConfig,g_sDBConfig,sizeof(g_sDBConfig));
	g_NoStats = (StrEqual(g_sDBConfig,"")) ? true : false;
	g_airshotHeight = GetConVarInt(gcvar_airshotHeight);
	g_blockStickyDmg = GetConVarInt(gcvar_blockStickyDmg);
	
	ParseAllowedClasses("",g_classAllowed);
	
	//midair stuff
	g_midairHP = GetConVarInt(gcvar_midairHP);
	
	
	if (!g_NoStats) PrepareSQL();

	//hooking convar changes
	HookConVarChange(gcvar_fragLimit, handler_ConVarChange);
	HookConVarChange(gcvar_allowedClasses, handler_ConVarChange);
	HookConVarChange(gcvar_hpbuffRatio, handler_ConVarChange);
	HookConVarChange(gcvar_infAmmo, handler_ConVarChange);
	HookConVarChange(gcvar_blockFallDamage, handler_ConVarChange);
	HookConVarChange(gcvar_airshotSigns, handler_ConVarChange);
	HookConVarChange(gcvar_airshotHeight, handler_ConVarChange);
	HookConVarChange(gcvar_midairHP, handler_ConVarChange);
	HookConVarChange(gcvar_blockStickyDmg, handler_ConVarChange);

	//commandz
	RegConsoleCmd("joinclass", Command_JoinClass); //обрабатываем смену класса
	//RegConsoleCmd("ammomod", Command_Menu, "kAmmomod Menu"); //команды для доступа к меню
	RegConsoleCmd("add", Command_Menu, "kAmmomod Menu (alias)");
	RegConsoleCmd("hitblip", Command_ToogleHitblip, "Toggle hitblip");//hitblip
	RegConsoleCmd("rank", Command_Rank); //rank
	RegConsoleCmd("spec_next", Command_Spec);//spectating handling
	RegConsoleCmd("spec_prev", Command_Spec);//spectating handling
	//RegConsoleCmd("tryme", Command_AddBot, "Add bot to your arena");//bots
	//RegConsoleCmd("botme", Command_AddBot, "Add bot to your arena (alias)");//bots
	RegConsoleCmd("loc", Command_Loc, "Shows client origin and angle vectors"); //cfg makin
	//HUD
	hm_Airshot = CreateHudSynchronizer();
	hm_HP = CreateHudSynchronizer();
	hm_Score = CreateHudSynchronizer();
	//Offsets
	g_offClip = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	if(g_offClip == -1) 
		SetFailState("Expected to find the offset to 'm_iClip1', couldn't.");
	g_offAmmo = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	if(g_offAmmo == -1) 
		SetFailState("Expected to find the offset to 'm_iAmmo', couldn't.");
	//spec target
	g_offObserverTarget = FindSendPropOffs("CBasePlayer", "m_hObserverTarget");	
	if(g_offObserverTarget == -1) 
		SetFailState("Expected to find the offset to 'm_hObserverTarget', couldn't.");
	//for blocking shooting
	g_offNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");
	if(g_offNextPrimaryAttack == -1) 
		SetFailState("Expected to find the offset to 'm_flNextPrimaryAttack', couldn't.");
	
	//BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "logs/kammomod.log");
	
	//AddServerTag("kAmmomod");
	
	if (!g_NoStats) { 
		for (new i=1;i<=MaxClients;i++){
			if (IsClientInGame(i)){
				g_bHitBlip[i] = false;//hitblip is awful
				decl String:steamid[32];
				GetClientAuthString(i, steamid, sizeof(steamid));
				decl String:query[256];
				Format(query, sizeof(query), "SELECT rating,hitblip,wins,losses FROM kammomod_stats WHERE steamid='%s' LIMIT 1", steamid);
				SQL_TQuery(db, T_SQLQueryOnConnect, query, i);
				strcopy(g_playerStemID[i],32,steamid);
				OnClientPostAdminCheck(i);
			}
		}
	}
}
public OnPluginEnd(){
	if(LibraryExists("pluginautoupdate")) AutoUpdate_RemovePlugin(); //autoupdate stuff
	for (new i=1;i<=MaxClients;i++){
		if (IsClientInGame(i))
			HideHud(i);
	}
}
public OnMapStart(){
	//loadin sounds
	decl String:downloadFile[PLATFORM_MAX_PATH];
	for (new i=0;i<=SOUND_COUNT;i++){
		if(PrecacheSound(sounds[i], true)){
			Format(downloadFile, PLATFORM_MAX_PATH, "sound/%s", sounds[i]);		
			AddFileToDownloadsTable(downloadFile);
		} else {
			LogError("[kAmmomod] Cannot precache sound: %s", sounds[i]);
		}
	}
	PrecacheSound("buttons/button17.wav");
	//loading spawn config
	new isMapAm = LoadSpawnPoints();
	if (isMapAm){
		if (!g_amEnabled){
			g_amEnabled = true;
			HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
			HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
			HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
			HookEvent("teamplay_round_start", Event_RoundStart);
			if (g_blockFallDamage)
				AddNormalSoundHook(sound_hook);
			if (g_particles){ // Add the map's particle manifest to the downloads table
				decl String:map[32];
				GetCurrentMap(map,sizeof(map));
				
				decl String:file[96];
				Format(file, sizeof(file), "maps/%s_particles.txt", map);
				
				if (!FileExists(file))
					LogMessage("Error: Particles file does not exist: %s", file);
				else 
					AddFileToDownloadsTable(file);
					
				for (new i = 2;i<=10;i++){
					Format(file, sizeof(file), "materials/effects/midair_%d.vmt", i);
					if (!FileExists(file))
						LogMessage("Error: Particles file does not exist: %s", file);
					else
						AddFileToDownloadsTable(file);
					Format(file, sizeof(file), "materials/effects/midair_%d.vtf", i);
					if (!FileExists(file))
						LogMessage("Error: Particles file does not exist: %s", file);
					else
						AddFileToDownloadsTable(file);
				}
				file = "materials/effects/midair_text.vmt";
				if (!FileExists(file))
						LogMessage("Error: Particles file does not exist: %s", file);
					else
						AddFileToDownloadsTable(file);
				file = "materials/effects/midair_text.vtf";
				if (!FileExists(file)){
					LogMessage("Error: Particles file does not exist: %s", file);
				} else {
					AddFileToDownloadsTable(file);
				}
			}
		}	
	} else if (g_amEnabled){
		g_amEnabled = false;
		UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
		UnhookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
		UnhookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
		UnhookEvent("teamplay_round_start", Event_RoundStart);
		RemoveNormalSoundHook(sound_hook);
	}
}

public OnClientPostAdminCheck(client){
	if (g_amEnabled && client /*&& IsClientInGame(client) && !IsFakeClient(client)*/){
		if (IsFakeClient(client)){
			new bool:botisok = false;
			//смотрим кто же у нас просил бота, если никто - надо бота выгнать нахер, 
			//PrintToChatAll("say hello to our bot %N",client);
			for (new i=1;i<=MaxClients;i++){
				if (g_playerAskedForBot[i]){
					//PrintToChat(i,"I see you");
					new arena_index = g_playerArena[i];
					/*new player_slot = g_playerSlot[i];
					//if (arena_index && (player_slot==SLOT_ONE || player_slot==SLOT_TWO)){
						//new bot_slot = (player_slot==SLOT_ONE) ? SLOT_TWO : SLOT_ONE;
						//if (g_arenaQueue[arena_index][bot_slot]>0){
							//kick bot and msg
						//	PrintToChat(i,"\x05[Advice] Bot trying to join busy arena. Kicking him");
						//} else {
							//PrintToChat(i,"\x05Adding bot to arena %d",arena_index);*/
							
					new Handle:pk;// = CreateDataPack();
					CreateDataTimer(1.5,Timer_AddBotInQueue,pk);
					WritePackCell(pk, GetClientUserId(client));
					WritePackCell(pk, arena_index);
					//testing purpose
					g_playerRating[client] = 1551;
					botisok = true;
					
					/*	}
					//} else {
					//	PrintToChat(i,"\x05[Advice] \x01Your arena is already full");
					//}*/
					g_playerAskedForBot[i] = false;
					break;
				}
			}
			if (!botisok){
				//пока оставим чтобы соуртв не вылетал
				//PrintToChatAll("This bot is impostor , kicking him");
				//KickClient(client,"go away, bot");
			}
		} else {
			CreateTimer(5.0, Timer_ShowAdv, GetClientUserId(client));//show advice to type !add in chat
			g_bHitBlip[client] = false;//hitblip is awful
			if (!g_NoStats) {
				decl String:steamid[32];
				GetClientAuthString(client, steamid, sizeof(steamid));
				decl String:query[256];
				Format(query, sizeof(query), "SELECT rating,hitblip,wins,losses FROM kammomod_stats WHERE steamid='%s' LIMIT 1", steamid);
				SQL_TQuery(db, T_SQLQueryOnConnect, query, client);
				strcopy(g_playerStemID[client],32,steamid);
			}
		}
	}
	//SDKHookz stuff
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	//SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}
public OnClientDisconnect(client){
	if (client>0 && g_playerArena[client])
		RemoveFromQueue(client,true);
}
public OnGameFrame(){//детектим нахождение/ненахождение в воздухе
	if (g_amEnabled){
		for (new client = 1; client <= MaxClients; client++) {
			if (IsClientInGame(client) && IsPlayerAlive(client)/* && (g_playerSlot[client]==SLOT_ONE || g_playerSlot[client]==SLOT_TWO)*/) {
				if (g_playerTakenAirCount[client] > 0 && GetEntityFlags(client) & (FL_ONGROUND)){// игрок на земле
					g_playerTakenAirCount[client] = 0;
				}
			}
		}
	}
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {//SDKHookz OnTakeDamage
	//PrintToChatAll("takdmg");
	if ((damagetype & DMG_FALL) && g_blockFallDamage){
		damage = 0.0;
		return Plugin_Changed;
	}
	if (victim != attacker){
		new arena_index = g_playerArena[victim];
		if ((g_blockStickyDmg & BLOCKDMG_STICKY_ALL) || /*always blocking sticky dmg*/ 
				(g_arenaMidair[arena_index] && (g_blockStickyDmg & BLOCKDMG_STICKY_MIDAIR)) || /*only midair*/
				(!g_arenaMidair[arena_index] && (g_blockStickyDmg & BLOCKDMG_STICKY_CLASSIC))) /*only ammomod*/
		{
			decl String:sWeapon[64];
			GetEdictClassname(inflictor, sWeapon, sizeof(sWeapon));
			if(StrEqual(sWeapon, "tf_projectile_pipe_remote")){
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

StartCountDown(arena_index){ //начинаем отсчет нового раунда
	new red_f1 = g_arenaQueue[arena_index][SLOT_ONE]; //red fighter
	new blu_f1 = g_arenaQueue[arena_index][SLOT_TWO]; //blue fighter
	if (red_f1 && blu_f1) {
		ResetPlayer(red_f1);//respawning
		ResetPlayer(blu_f1);
		new Float:enginetime = GetGameTime();
		for (new i=0;i<=2;i++){
			new ent = GetPlayerWeaponSlot(red_f1, i);
			if(IsValidEntity(ent))
				SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", enginetime+1.1);
			ent = GetPlayerWeaponSlot(blu_f1, i);
			if(IsValidEntity(ent))
				SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", enginetime+1.1);
			//SetEntDataFloat(ent, g_offNextPrimaryAttack, enginetime + 5.0, true);
		}
		g_arenaCd[arena_index] = g_arenaCdTime[arena_index] + 1;
		g_arenaStatus[arena_index] = AS_PRECOUNTDOWN;
		CreateTimer(0.0,Timer_CountDown,arena_index,TIMER_FLAG_NO_MAPCHANGE);
		return 1;
	} else {
		g_arenaStatus[arena_index] = AS_IDLE;
		return 0;
	}
}
ShowSpecHudToArena(arena_index){
	if (!arena_index)
		return;
	for (new i=1;i<=MaxClients;i++){
		if (IsClientInGame(i) && GetClientTeam(i)==TEAM_SPEC && g_playerSpecTarget[i]>0 && g_playerArena[g_playerSpecTarget[i]]==arena_index)
			ShowSpecHudToClient(i);
	}
}
ShowCountdownToSpec(arena_index,String:text[]){
	if (!arena_index)
		return;
	for (new i=1;i<=MaxClients;i++){
		if (IsClientInGame(i) && GetClientTeam(i)==TEAM_SPEC && g_playerArena[g_playerSpecTarget[i]]==arena_index)
			PrintCenterText(i,text);
	}
}
//queue
RemoveFromQueue(client, bool:calcstats=false){ //удаление игрока из очереди с продвижением ожидающих и заполнением арены при необходимости 
	new arena_index = g_playerArena[client];
	if (arena_index == 0) return;
	new player_slot = g_playerSlot[client];
	g_playerArena[client] = 0;
	g_playerSlot[client] = 0;
	g_arenaQueue[arena_index][player_slot] = 0;
	if (IsClientInGame(client) && GetClientTeam(client) != TEAM_SPEC) ChangeClientTeam(client, TEAM_SPEC);
	
	new after_leaver_slot = player_slot + 1; //если игрок ушел из ожидающих то при сдвиге очереди перемещение начнется со следующего игрока
	if (player_slot==SLOT_ONE || player_slot==SLOT_TWO) {//игрок ушел с арены
		new foe_slot = player_slot==SLOT_ONE ? SLOT_TWO : SLOT_ONE;
		new foe = g_arenaQueue[arena_index][foe_slot];
		//если в момент выхода(лива) клиента (не бота) на арене был противник (не бот) и счет был не 0:0
		if (calcstats && !g_NoStats && foe && (g_arenaScore[arena_index][foe_slot]>g_arenaScore[arena_index][player_slot]))
			CalcELO(foe,client);//засчитываем ливеру поражение
			
		if (g_arenaQueue[arena_index][SLOT_TWO+1]){ // если есть ожидающие
			//перекидываем 1-го из очереди(3й слот) на арену
			new next_client = g_arenaQueue[arena_index][SLOT_TWO+1];
			g_arenaQueue[arena_index][SLOT_TWO+1] = 0;//зачищаем 3й слот
			g_arenaQueue[arena_index][player_slot] = next_client; //садим 3й слот на место выбывшего
			g_playerSlot[next_client] = player_slot;
			after_leaver_slot = SLOT_TWO + 2;
			new String:playername[128];
			CreateTimer(2.0,Timer_StartDuel,arena_index);
			GetClientName(next_client,playername,sizeof(playername));
			if (!g_NoStats)
				CPrintToChatAll("%t","JoinsArena",playername,g_playerRating[next_client],g_arenaName[arena_index]);
			else
				CPrintToChatAll("%t","JoinsArenaNoStats",playername,g_arenaName[arena_index]);
			//StartDuel(arena_index);
			
			
		} else {//ожидающих нет
			if (foe && IsFakeClient(foe)) KickClient(foe); //бот остается один на арене то кикаем его
			g_arenaStatus[arena_index] = AS_IDLE;
			return;
		}
	}	
	//сдвигаем очередь вперед
	if (g_arenaQueue[arena_index][after_leaver_slot]){
		while (g_arenaQueue[arena_index][after_leaver_slot]){
			g_arenaQueue[arena_index][after_leaver_slot-1] = g_arenaQueue[arena_index][after_leaver_slot];
			g_playerSlot[g_arenaQueue[arena_index][after_leaver_slot]] -= 1;
			after_leaver_slot++;
		}
		g_arenaQueue[arena_index][after_leaver_slot-1] = 0;
	}
}
AddInQueue(client,arena_index, bool:showmsg = true){ //добавление игрока в очередь 
	if (g_playerArena[client]) { //если игрок уже на арене
		PrintToChatAll("client <%N> is already on arena %d",client,arena_index);
		/*new old_arena_index = g_playerArena[client];
		if (old_arena_index == arena_index && !forced) //добавить на ту же арену, где клиент сейчас и клиент сам пытается это сделать
			return;
		RemoveFromQueue(client,true);*/
	}
	new player_slot = SLOT_ONE;
	while (g_arenaQueue[arena_index][player_slot]) player_slot++;
	g_playerArena[client] = arena_index;
	g_playerSlot[client] = player_slot;
	g_arenaQueue[arena_index][player_slot] = client;
	if (showmsg){
		CPrintToChat(client,"%t","ChoseArena",g_arenaName[arena_index]);
		//PrintToChat(client,"\x01You select arena \x04[%s]",g_arenaName[arena_index]);
	}
	if (player_slot <= SLOT_TWO){
		decl String:name[64];
		GetClientName(client,name,sizeof(name));
		CPrintToChatAll("%t","JoinsArena",name,g_playerRating[client],g_arenaName[arena_index]);
		if (g_arenaQueue[arena_index][SLOT_ONE] && g_arenaQueue[arena_index][SLOT_TWO]){
			CreateTimer(1.5,Timer_StartDuel,arena_index);
		} else
			CreateTimer(0.1,Timer_ResetPlayer,GetClientUserId(client));
	} else {
		if (GetClientTeam(client) != TEAM_SPEC) ChangeClientTeam(client, TEAM_SPEC);
		if (player_slot == SLOT_TWO + 1)
			CPrintToChat(client,"%t","NextInLine");
	 	else //if (player_slot > SLOT_TWO + 1) 
			CPrintToChat(client,"%t","InLine",player_slot-SLOT_TWO);
	}
	return;
}
CalcELO(winner, loser) {
	if (IsFakeClient(winner) || IsFakeClient(loser)) //если один из бойцов бот то стату не считаем
		return;
	decl String:query[512];
	new Float:El = 1/(Pow(10.0, float((g_playerRating[winner]-g_playerRating[loser]))/400)+1);
	//new Float:Eloser = 1/(Pow(10.0, float((g_playerRating[winner]-g_playerRating[loser]))/400)+1);
	new k = (g_playerRating[winner]>=2400) ? 10 : 15;
	new winnerscore = RoundFloat(k*El);
	g_playerRating[winner] += winnerscore;
	k = (g_playerRating[loser]>=2400) ? 10 : 15;
	new loserscore = RoundFloat(k*El);
	g_playerRating[loser] -= loserscore;
	if(IsClientInGame(winner))
		CPrintToChat(winner, "%t","GainedPoints",winnerscore);
	if(IsClientInGame(loser))
		CPrintToChat(loser, "%t","LostPoints",loserscore);
	
	Format(query, sizeof(query), "UPDATE kammomod_stats SET rating=%i,wins=wins+1,lastplayed=%i WHERE steamid='%s'", g_playerRating[winner], GetTime(), g_playerStemID[winner]);
	SQL_TQuery(db, SQLErrorCheckCallback, query);
	Format(query, sizeof(query), "UPDATE kammomod_stats SET rating=%i,losses=losses+1,lastplayed=%i WHERE steamid='%s'", g_playerRating[loser], GetTime(), g_playerStemID[loser]);
	SQL_TQuery(db, SQLErrorCheckCallback, query);
}
//player(client) related
ResetPlayer(client){ //ставим игрока на положенное место, респауним если нужно, устанавливаем HP
	new arena_index = g_playerArena[client];
	new player_slot = g_playerSlot[client];
	
	if (!arena_index || !player_slot){
		//убиваем и обнуляем класс
		//проверяем, может игрок на арене, и это баг что нет слота и арены
		return 0;
	}
	
	//SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
	
	g_playerSpecTarget[client] = 0;
	
	//SetEntProp(client, Prop_Send, "m_lifeState", 2);
	new team = GetClientTeam(client);
	if (player_slot - team != SLOT_ONE - TEAM_RED)
		ChangeClientTeam(client, player_slot + TEAM_RED - SLOT_ONE);
	
	new TFClassType:class;
	class = g_playerClass[client] ? g_playerClass[client]: TFClass_Soldier;

	if (!IsPlayerAlive(client)){
		/*new BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(IsValidEdict(BodyRagdoll)){ //removing corpse
			RemoveEdict(BodyRagdoll);
		}*/ 
		if (class != TF2_GetPlayerClass(client)) 
			TF2_SetPlayerClass(client,class);
		TF2_RespawnPlayer(client);
		
	} else {//если живой то лечим
		TF2_RegeneratePlayer(client);
		ExtinguishEntity(client);
	}
		
	//SetEntProp(client, Prop_Send, "m_lifeState", 0);	
	/*if (g_midairEnabled)
		g_playerHP[client] = g_midairHP;
	else
		g_playerHP[client] = RoundToNearest(float(TFClass_NormalHP[class])*g_hpRatio);*/
	if (g_arenaMidair[arena_index])
		g_playerHP[client] = g_midairHP;
	else
		g_playerHP[client] = RoundToNearest(float(TFClass_NormalHP[class])*g_hpRatio);
		
	ShowPlayerHud(client);
	CreateTimer(0.1,Timer_Tele,GetClientUserId(client));	
	//if (IsFakeClient(client)) FakeClientCommand(client, "say I will pawn u!"); //bot speaking
	return 1;
}
EmitAirshotSound(client,count){
	if (!client)
		return;
	decl String:sound[32];
	if (count < SOUND_COUNT)
		Format(sound,sizeof(sound),"%s",sounds[count]);
	else
		Format(sound,sizeof(sound),"%s",sounds[SOUND_COUNT]);
	for (new i=1;i<=MaxClients;i++)
		if (IsClientInGame(i) && ((GetClientTeam(i)==TEAM_SPEC && g_playerSpecTarget[i]==client) || client == i))
			EmitSoundToClient(i, sound , _, _, _, _, 0.9);
}
ShowPlayerHud(client){
	if (!client || !IsClientInGame(client)) 
		return;
	//HP
	SetHudTextParams(0.01, 0.80, HUDFADEOUTTIME, 255,255,255,255);
	new client_foe = g_arenaQueue[g_playerArena[client]][g_playerSlot[client]==SLOT_ONE ? SLOT_TWO : SLOT_ONE]; //test
	if (client_foe)
		ShowSyncHudText(client, hm_HP, "You : %d\nEnemy : %d", g_playerHP[client],g_playerHP[client_foe]);
	else
		ShowSyncHudText(client, hm_HP, "Health : %d", g_playerHP[client]);
	//Score
	new arena_index = g_playerArena[client];
	SetHudTextParams(0.01, 0.01, HUDFADEOUTTIME, 255,255,255,255);
	new String:report[128];
	new fraglimit = g_arenaFraglimit[arena_index];
	//if (g_arenaStatus[arena_index] != AS_IDLE){
	if (fraglimit>0)
		Format(report,sizeof(report),"Arena %s. Frag Limit(%d)",g_arenaName[arena_index],fraglimit);
	else
		Format(report,sizeof(report),"Arena %s. No Frag Limit",g_arenaName[arena_index]);
	// else
	//	Format(report,sizeof(report),"Arena[%s]",g_arenaName[arena_index]);
	new red_f1 = g_arenaQueue[arena_index][SLOT_ONE];
	new blu_f1 = g_arenaQueue[arena_index][SLOT_TWO];
	if (red_f1)
		if (g_NoStats)
			Format(report,sizeof(report),"%s\n%N : %d",report,red_f1,g_arenaScore[arena_index][SLOT_ONE]);
		else
			Format(report,sizeof(report),"%s\n%N (%d) : %d",report,red_f1,g_playerRating[red_f1],g_arenaScore[arena_index][SLOT_ONE]);
	if (blu_f1)
		if (g_NoStats)
			Format(report,sizeof(report),"%s\n%N : %d",report,blu_f1,g_arenaScore[arena_index][SLOT_TWO]);
		else
			Format(report,sizeof(report),"%s\n%N (%d) : %d",report,blu_f1,g_playerRating[blu_f1],g_arenaScore[arena_index][SLOT_TWO]);
	ShowSyncHudText(client, hm_Score, "%s",report);
}
ShowSpecHudToClient(client){
	if (!client || !IsClientInGame(client) || g_playerSpecTarget[client] <=0) 
		return;
	new arena_index = g_playerArena[g_playerSpecTarget[client]];
	new red_f1 = g_arenaQueue[arena_index][SLOT_ONE];
	new blu_f1 = g_arenaQueue[arena_index][SLOT_TWO];
	new String:hp_report[128];
	if (red_f1)
		Format(hp_report,sizeof(hp_report),"%N : %d", red_f1,g_playerHP[red_f1]);
	if (blu_f1)
		Format(hp_report,sizeof(hp_report),"%s\n%N : %d",hp_report,blu_f1, g_playerHP[blu_f1]);
	
	SetHudTextParams(0.01, 0.80, HUDFADEOUTTIME, 255,255,255,255);
	ShowSyncHudText(client, hm_HP, hp_report);
	//Score
	//new arena_index = g_playerArena[client];
	SetHudTextParams(0.01, 0.01, HUDFADEOUTTIME, 255,255,255,255);
	new String:report[128];
	new fraglimit = g_arenaFraglimit[arena_index];
	if (g_arenaStatus[arena_index] != AS_IDLE){
		if (fraglimit>0)
			Format(report,sizeof(report),"Arena %s. Frag Limit(%d)",g_arenaName[arena_index],fraglimit);
		else
			Format(report,sizeof(report),"Arena %s. No Frag Limit",g_arenaName[arena_index]);
	} else
		Format(report,sizeof(report),"Arena[%s]",g_arenaName[arena_index]);
	if (red_f1)
		if (g_NoStats)
			Format(report,sizeof(report),"%s\n%N : %d",report,red_f1,g_arenaScore[arena_index][SLOT_ONE]);
		else
			Format(report,sizeof(report),"%s\n%N (%d): %d",report,red_f1,g_playerRating[red_f1],g_arenaScore[arena_index][SLOT_ONE]);
	if (g_arenaQueue[arena_index][SLOT_TWO])
		if (g_NoStats)
			Format(report,sizeof(report),"%s\n%N : %d",report,blu_f1,g_arenaScore[arena_index][SLOT_TWO]);
		else
			Format(report,sizeof(report),"%s\n%N (%d): %d",report,blu_f1,g_playerRating[blu_f1],g_arenaScore[arena_index][SLOT_TWO]);
	ShowSyncHudText(client, hm_Score, "%s",report);
}
ShowAirshotHudMsg(client,count){
	if (!client)
		return;
	decl String:msg[128];
	Format(msg,sizeof(msg),"%N\n%d hit",client,count);
	//ClearSyncHud(client,hm_Airshot);
	SetHudTextParams(0.01, -1.0, 3.0, 100,255,255,255);
	for (new i=1;i<=MaxClients;i++)
		if (IsClientInGame(i) && ((GetClientTeam(i)==TEAM_SPEC && g_playerSpecTarget[i]==client) || client == i)){
			ShowSyncHudText(i, hm_Airshot, msg);
			//PrintToChat(i,"%s",msg);
		}
}
HideHud(client){
	if (!client || !IsClientInGame(client))
		return;
	ClearSyncHud(client,hm_Score);
	ClearSyncHud(client,hm_HP);
	ClearSyncHud(client,hm_Airshot);
}
Handle:CreateParticle(client,String:type[]="midair_text"){
	//deleting an old one if its exists
	//DeleteParticle(g_playerAirshotSign[client]);
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle)) { // Check if it was created correctly
		// Generate unique id for the client so we can set the parenting through parentname.
		new Float:pos[3]; 
		new String:tName[32];
		Format(tName, sizeof(tName), "Client%i", client);
		DispatchKeyValue(client, "targetname", tName);
		//GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		GetClientAbsOrigin(client, pos);
		pos[2] += 80;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", type);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle,particle, 0);
		  // Set attachment if possible
		SetVariantString("forawrd");
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
    
		g_playerAirshotSign[client] = particle;
		
		return CreateTimer(10.0, Timer_DeleteParticle, particle);
	} else {
		LogError("CreateParticle: Could not create info_particle_system");
	}
	
	return INVALID_HANDLE;
}
//util
LoadSpawnPoints(){
	new String:txtfile[256];
	BuildPath(Path_SM, txtfile, sizeof(txtfile), MAPCONFIGFILE);

	new String:spawn[64];
	new String:mapname[32];
	
	GetCurrentMap(mapname,sizeof(mapname));
	
	new Handle:kv = CreateKeyValues("SpawnConfig");

	new String:spawnCo[6][16];
	new String:kvmap[32];
	new count;
	new i;
	g_arenaCount = 0;
		
	if (FileToKeyValues(kv, txtfile)){
		if (KvGotoFirstSubKey(kv)) {
			do {
				KvGetSectionName(kv, kvmap, 64);
				if (StrEqual(mapname,kvmap)){
					//if (KvGetString(kv, mapname, spawn, sizeof(s_midair)))
					if (KvGotoFirstSubKey(kv)){
						do {
							g_arenaCount++;
							KvGetSectionName(kv, g_arenaName[g_arenaCount], 64);
							
							if (KvGetString(kv, "spawn_1", spawn, sizeof(spawn))){
								//обратываем координаты респа 1
								count = ExplodeString(spawn, " ", spawnCo, 6, 16);
								if (count==6){
									for (i=0; i<3; i++){
										g_arenaSpawnOrigin[g_arenaCount][SLOT_ONE][i] = StringToFloat(spawnCo[i]);
									}
									for (i=3; i<6; i++){
										g_arenaSpawnAngles[g_arenaCount][SLOT_ONE][i-3] = StringToFloat(spawnCo[i]);
									}
								} else if(count==4){
									for (i=0; i<3; i++){
										g_arenaSpawnOrigin[g_arenaCount][SLOT_ONE][i] = StringToFloat(spawnCo[i]);
									}
									g_arenaSpawnAngles[g_arenaCount][SLOT_ONE][0] = 0.0;
									g_arenaSpawnAngles[g_arenaCount][SLOT_ONE][1] = StringToFloat(spawnCo[3]);
									g_arenaSpawnAngles[g_arenaCount][SLOT_ONE][2] = 0.0;
								} else {//сообщаем об шибке
									SetFailState("Error in cfg file. Wrong number of parametrs (%d) on spawn <1> in arena <%s>",count,g_arenaName[g_arenaCount]);
								}
							} else 	//сообщаем об шибке							
								SetFailState("Error in cfg file. Can't find spawn <1> on arena <%s>",g_arenaName[g_arenaCount]);
							if (KvGetString(kv, "spawn_2", spawn, sizeof(spawn))){
								//обратываем координаты респа 2
								count = ExplodeString(spawn, " ", spawnCo, 6, 16);
								if (count==6){
									for (i=0; i<3; i++){
										g_arenaSpawnOrigin[g_arenaCount][SLOT_TWO][i] = StringToFloat(spawnCo[i]);
									}
									for (i=3; i<6; i++){
										g_arenaSpawnAngles[g_arenaCount][SLOT_TWO][i-3] = StringToFloat(spawnCo[i]);
									}
								} else if(count==4){
									for (i=0; i<3; i++){
										g_arenaSpawnOrigin[g_arenaCount][SLOT_TWO][i] = StringToFloat(spawnCo[i]);
									}
									g_arenaSpawnAngles[g_arenaCount][SLOT_TWO][0] = 0.0;
									g_arenaSpawnAngles[g_arenaCount][SLOT_TWO][1] = StringToFloat(spawnCo[3]);
									g_arenaSpawnAngles[g_arenaCount][SLOT_TWO][2] = 0.0;
								} else //сообщаем об шибке
									SetFailState("Error in cfg file. Wrong number of parametrs (%d) on spawn <2> in arena <%s>",count,g_arenaName[g_arenaCount]);
							} else //сообщаем об шибке
								SetFailState("Error in cfg file. Can't find spawn <2> on arena <%s>",g_arenaName[g_arenaCount]);
							//optional parametrs
							g_arenaFraglimit[g_arenaCount] = KvGetNum(kv, "fraglimit", g_defaultFragLimit);
							g_arenaMinRating[g_arenaCount] = KvGetNum(kv, "minrating", -1);
							g_arenaMaxRating[g_arenaCount] = KvGetNum(kv, "maxrating", -1);
							g_arenaMidair[g_arenaCount] = KvGetNum(kv, "midair", 0) ? true : false ;
							g_arenaCdTime[g_arenaCount] = KvGetNum(kv, "cdtime", DEFAULT_CDTIME);
							//parsing allowed classes for current arena
							decl String:sAllowedClasses[128];
							KvGetString(kv, "classes", sAllowedClasses, sizeof(sAllowedClasses));
							LogAction(0,-1,"<%s>",sAllowedClasses);
							ParseAllowedClasses(sAllowedClasses,g_arenaAllowedClasses[g_arenaCount]); 
						} while (KvGotoNextKey(kv));
					}
					break;
				}
			} while (KvGotoNextKey(kv));
			if (g_arenaCount){
				LogAction(0,-1,"[kAmmomod] Loaded %d arena. kAmmomod enabled",g_arenaCount);
				CloseHandle(kv);
				return true;
			} else {
				LogError("[kAmmomod] Can't find map cfg. kAmmomod disabled");	
				CloseHandle(kv);
				return false;
			}
		} else {
			LogError("[kAmmomod] Error in cfg file.");
			return false;
		}
	} else {
		LogError("[kAmmomod] Error. Can't find cfg file");
		return false;
	}
}
PrepareSQL(){ //conncecting to db ,creating table if not exists
	decl String:error[256];
	if(SQL_CheckConfig(g_sDBConfig)) {
		db = SQL_Connect(g_sDBConfig, true, error, sizeof(error));
	}
	//db = SQL_Connect("storage-local", true, error, sizeof(error));
	if(db==INVALID_HANDLE) {
		LogMessage("Cant use config <%s>, trying sqllite <storage-local>",g_sDBConfig);
		db = SQL_Connect("storage-local", true, error, sizeof(error));
		if(db==INVALID_HANDLE) {
			SetFailState("Could not connect to database: %s", error);
		}
	}
	decl String:ident[16];
	SQL_ReadDriver(db, ident, sizeof(ident));
	if(StrEqual(ident, "mysql", false)) {
		g_bUseSqlLite = false;
	} else if(StrEqual(ident, "sqlite", false)) {
		g_bUseSqlLite = true;
	} else {
		SetFailState("Invalid database.");
	}
	if(g_bUseSqlLite) {
		SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS kammomod_stats (rating INTEGER, steamid TEXT, name TEXT, wins INTEGER, losses INTEGER, lastplayed INTEGER, hitblip INTEGER)");
	} else {
		SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS kammomod_stats (rating INT(4) NOT NULL, steamid VARCHAR(32) NOT NULL, name VARCHAR(64) NOT NULL, wins INT(4) NOT NULL, losses INT(4) NOT NULL, lastplayed INT(11) NOT NULL, hitblip INT(2) NOT NULL)");
	}
}
ParseAllowedClasses(const String:sList[],output[TFClassType]){
	new count, String:a_class[9][8];
	
	if (strlen(sList)>0){
		count = ExplodeString(sList, " ", a_class, 9, 8);
	} else {
		decl String:sDefList[128];
		GetConVarString(gcvar_allowedClasses,sDefList,sizeof(sDefList));
		count = ExplodeString(sDefList, " ", a_class, 9, 8);
	}
	for (new i=1;i<=9;i++)
		output[i] = 0;
	for (new i=0;i<count;i++){
		new TFClassType:c = TF2_GetClass(a_class[i]); 
		if (c) output[c] = 1;
	}
}
stock DALog(const String:format[], any:...) {
	decl String:path[256], String:buffer[192];
	BuildPath(Path_SM, path, sizeof(path), "logs/duelarena.log");
	VFormat(buffer, sizeof(buffer), format, 2);
	LogToFileEx(path, "%s", buffer);
}
//main menu
ShowMainMenu(client,bool:listplayers=true){
	if (client<=0) return;
	
	decl String:title[128];
	decl String:menu_item[128];

	new Handle:menu = CreateMenu(Menu_Main);

	Format(title, sizeof(title), "%T","MenuTitle",client);
	SetMenuTitle(menu, title);
	new String:si[4];
	for (new i=1;i<=g_arenaCount;i++){
		/*decl String:sRating[128];
		new maxrating = g_arenaMaxRating[i];
		new minrating = g_arenaMinRating[i];
		new String:sMidair[8] = ""; 
		if (g_arenaMidair[i]) Format(sMidair,sizeof(sMidair),"%s","[MA] ");
		if (maxrating > 0){
			if (minrating > 0)
				Format(sRating,sizeof(sRating)," (%d - %d)",minrating,maxrating);
			else
				Format(sRating,sizeof(sRating)," (under %d)",maxrating);
		} else if (minrating > 0)
			Format(sRating,sizeof(sRating)," (%d+)",minrating);
		else sRating = "";	
		
		Format(menu_item,sizeof(menu_item),"%s%s%s",sMidair,g_arenaName[i],sRating);*/
		IntToString(i,si,sizeof(si));
		//AddMenuItem(menu, si, menu_item);
		AddMenuItem(menu, si,g_arenaName[i]);
	}
	Format(menu_item,sizeof(menu_item),"%T","MenuRemove",client);
	AddMenuItem(menu, "1000", menu_item);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	new String:report[128];
	//listing players
	if (!listplayers) return;
	for (new i=1;i<=g_arenaCount;i++){
		new red_f1 = g_arenaQueue[i][SLOT_ONE];
		new blu_f1 = g_arenaQueue[i][SLOT_TWO];
		if (red_f1>0 || blu_f1>0){
			Format(report,sizeof(report),"\x05%s:",g_arenaName[i]);
			if (red_f1>0 && blu_f1>0)
				Format(report,sizeof(report),"%s \x04%N \x03(%d) \x05vs \x04%N (%d) \x05",report,red_f1,g_playerRating[red_f1],blu_f1,g_playerRating[blu_f1]);
			else if (red_f1>0)
				Format(report,sizeof(report),"%s \x04%N (%d)\x05",report,red_f1,g_playerRating[red_f1]);
			else if (blu_f1>0)
				Format(report,sizeof(report),"%s \x04%N (%d)\x05",report,blu_f1,g_playerRating[blu_f1]);	
			if (g_arenaQueue[i][SLOT_TWO + 1]) {
				Format(report,sizeof(report),"%s Waiting: ",report);
				new j = SLOT_TWO + 1;
				while (g_arenaQueue[i][j + 1]){
					Format(report,sizeof(report),"%s\x04%N \x05, ",report,g_arenaQueue[i][j]);
					j++;
				}
				Format(report,sizeof(report),"%s\x04%N",report,g_arenaQueue[i][j]);
				//Format(report,sizeof(report),"%s\x05)",report);
			}
			//Format(report,sizeof(report),"%s\n",report);
			PrintToChat(client,"%s",report);
		}
	}
}
//convars changes
public handler_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if (convar == gcvar_infAmmo)
		StringToInt(newValue) ? (g_infAmmo = true) : (g_infAmmo = false);
	else if (convar == gcvar_blockFallDamage) {
		StringToInt(newValue) ? (g_blockFallDamage = true) : (g_blockFallDamage = false);
		if (g_blockFallDamage)
			AddNormalSoundHook(sound_hook);
		else
			RemoveNormalSoundHook(sound_hook);
	}
	else if (convar == gcvar_fragLimit)
		g_defaultFragLimit = StringToInt(newValue);
	else if (convar == gcvar_hpbuffRatio)
		g_hpRatio = StringToFloat(newValue);
	else if (convar == gcvar_airshotSigns)
		StringToInt(newValue) ? (g_particles = true) : (g_particles = false);
	else if (convar == gcvar_airshotHeight)
		g_airshotHeight = StringToInt(newValue);
	else if (convar == gcvar_midairHP)
		g_midairHP = StringToInt(newValue);
	else if (convar == gcvar_blockStickyDmg)
		g_blockStickyDmg = StringToInt(newValue);
}
//commands
public Action:Command_Menu(client, args){ //handle commands "!ammomod" "!add" and such //building queue's menu and listing arena's
	ShowMainMenu(client);
	return Plugin_Handled;
}
public Action:Command_JoinClass(client, args){ //handle changing class
	if (!g_amEnabled || !client)
		return Plugin_Continue;
	//PrintToChatAll("joinclass");
	if (args) {
		//PrintToChat(client,"joinclass");
		new String:s_class[64];
		GetCmdArg(1, s_class, sizeof(s_class));
		new TFClassType:new_class = TF2_GetClass(s_class);
		if (new_class == g_playerClass[client])
			return Plugin_Handled; // no need to do smthn
		
		new arena_index = g_playerArena[client];
		if (arena_index == 0){//if client is on arena
			if (!g_classAllowed[new_class]){ //checking global class restrctions
				CPrintToChat(client,"%t","ClassIsNotAllowed");
				return Plugin_Handled;
			} else {
				g_playerClass[client] = new_class;
				//return Plugin_Handled;
				ChangeClientTeam(client,TEAM_SPEC);
			}
		} else {
			if (!g_arenaAllowedClasses[arena_index][new_class]){
				CPrintToChat(client,"%t","ClassIsNotAllowed");
				return Plugin_Handled;
			}
			if (g_playerSlot[client]==SLOT_ONE || g_playerSlot[client]==SLOT_TWO){
				if (g_arenaStatus[arena_index] < AS_FIGHT){
					g_playerClass[client] = new_class;
					CreateTimer(0.1,Timer_ResetPlayer,GetClientUserId(client));
					return Plugin_Continue;
				} else if (g_arenaStatus[arena_index] > AS_FIGHT){
					g_playerClass[client] = new_class;
					return Plugin_Continue;
				}
			} else {
				g_playerClass[client] = new_class;
				//return Plugin_Handled;
				ChangeClientTeam(client,TEAM_SPEC);
			}
		}
	}
	return Plugin_Handled;
}
public Action:Command_Spec(client, args){ //detecting spectator target
	if (!client) 
		return Plugin_Continue;
	CreateTimer(0.1,Timer_ChangeSpecTarget,GetClientUserId(client));
	return Plugin_Continue;
}
public Action:Command_AddBot(client, args){ //adding bot to client's arena
	if (!client) 
		return Plugin_Continue;
	new arena_index = g_playerArena[client];
	new player_slot = g_playerSlot[client];
	if (arena_index && (player_slot==SLOT_ONE || player_slot==SLOT_TWO)){
		/*new foe_slot = (player_slot==SLOT_ONE) ? SLOT_TWO : SLOT_ONE;
		if (g_arenaQueue[arena_index][foe_slot]){
			PrintToChat(client,"\x05You are already fighting with somebody");
		} else {*/
			//PrintToChat(client,"\x05Adding a Bot.");
		ServerCommand("tf_bot_add");
		g_playerAskedForBot[client] = true;
		/*}*/
	}
	return Plugin_Handled;
}
public Action:Command_Loc(client, args){ //showing location
	new Float:vec[3];
	new Float:ang[3];
	GetClientAbsOrigin(client, vec);
	GetClientEyeAngles(client, ang);
	PrintToChat(client,"%.0f %.0f %.0f %.0f",vec[0],vec[1],vec[2],ang[1]);
	return Plugin_Handled;
}
public Action:Command_ToogleHitblip(client, args) {
	g_bHitBlip[client] = !g_bHitBlip[client];
	if (!g_NoStats) {
		decl String:steamid[32], String:query[256];
		GetClientAuthString(client, steamid, sizeof(steamid));
		Format(query, sizeof(query), "UPDATE kammomod_stats SET hitblip=%i WHERE steamid='%s'", g_bHitBlip[client]?1:0, steamid);
		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}
	PrintToChat(client, "\x01Hitblip is \x04%sabled\x01.", g_bHitBlip[client]?"en":"dis");
	return Plugin_Handled;
}
public Action:Command_Rank(client, args) {
	if(args==0) {
		CPrintToChat(client, "%t","MyRank",g_playerRating[client],g_playerWins[client],g_playerLosses[client]);
	} else {
		decl String:argstr[64];
		GetCmdArgString(argstr, sizeof(argstr));
		new targ = FindTarget(0, argstr, false, false);
		if(targ!=-1) {
			PrintToChat(client, "\x03%N\x01's rating is \x04%i\x01. You have a \x04%i%%\x01 chance of beating him.", targ, g_playerRating[targ], RoundFloat((1/(Pow(10.0, float((g_playerRating[targ]-g_playerRating[client]))/400)+1))*100));
		}
	}
	return Plugin_Handled;
}
//blocking fallpain sound
public Action:sound_hook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags){ 
//pl_fleshbreak
	if(StrContains(sample,"pl_fallpain")>=0){
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
//sql callbacks
public T_SQLQueryOnConnect(Handle:owner, Handle:hndl, const String:error[], any:data) { //SELECT rating,hitblip,wins,losses FROM kammomod_stats WHERE steamid='%s' LIMIT 1
	new client = data;
	if(hndl==INVALID_HANDLE) {
		LogError("Query failed: %s", error);
		return;
	} 	
	decl String:query[512];
	decl String:namesql[MAX_NAME_LENGTH], String:steamid[32];
	GetClientName(client, namesql, sizeof(namesql));
	//strcopy(g_sNames[client], MAX_NAME_LENGTH, namesql);
	ReplaceString(namesql, sizeof(namesql), "'", "");
	GetClientAuthString(client, steamid, sizeof(steamid));
	if(SQL_FetchRow(hndl)) {
		g_playerRating[client] = SQL_FetchInt(hndl, 0);
		g_bHitBlip[client] = SQL_FetchInt(hndl, 1)==1;
		g_playerWins[client] = SQL_FetchInt(hndl, 2);
		g_playerLosses[client] = SQL_FetchInt(hndl, 3);
		
		Format(query, sizeof(query), "UPDATE kammomod_stats SET name='%s' WHERE steamid='%s'", namesql, steamid);
		SQL_TQuery(db, SQLErrorCheckCallback, query);
	} else {
		if(g_bUseSqlLite) {
			Format(query, sizeof(query), "INSERT INTO kammomod_stats VALUES(1600, '%s', '%s', 0, 0, %i, 1)", steamid, namesql, GetTime());
			SQL_TQuery(db, SQLErrorCheckCallback, query);
		} else {
			Format(query, sizeof(query), "INSERT INTO kammomod_stats (rating, steamid, name, wins, losses, lastplayed, hitblip) VALUES (1600, '%s', '%s', 0, 0, %i, 1)", steamid, namesql, GetTime());
			SQL_TQuery(db, SQLErrorCheckCallback, query);
		}
		g_playerRating[client] = 1600;
		g_bHitBlip[client] = false;
	}
	
}
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if(!StrEqual("", error)) {
		LogError("Query failed: %s", error);
	}
}
//menu //обработка меню !add
public Menu_Main(Handle:menu, MenuAction:action, param1, param2) { 
    switch (action) {
		case MenuAction_Select: {
			new client = param1;
			if (!client) return;
			new String:capt[32];
			new String:sanum[32];
			
			GetMenuItem(menu, param2, sanum,sizeof(sanum), _,capt, sizeof(capt));
			new arena_index = StringToInt(sanum);
			
			if (arena_index>0 && arena_index <=MAXARENAS){
				if (arena_index == g_playerArena[client]){
					//show warn msg
					ShowMainMenu(client,false);
					return;
				}
				//checking rating
				new playerrating = g_playerRating[client];
				new minrating = g_arenaMinRating[arena_index];
				new maxrating = g_arenaMaxRating[arena_index];
				if (minrating>0 && playerrating < minrating){
					CPrintToChat(client,"%t","LowRating",playerrating,minrating);
					ShowMainMenu(client,false);
					return;
				} else if (maxrating>0 && playerrating > maxrating){
					CPrintToChat(client,"%t","HighRating",playerrating,maxrating);
					ShowMainMenu(client,false);
					return;
				}
				//checking class
				new TFClassType:player_class = g_playerClass[client];
				if (player_class==TFClassType:0 || !g_arenaAllowedClasses[arena_index][player_class]){
					for(new i=1;i<=9;i++){
						if (g_arenaAllowedClasses[arena_index][i]){
							g_playerClass[client] = TFClassType:i;
							break;
						}
					}
				}
				
				if (g_playerArena[client]) RemoveFromQueue(client);
				AddInQueue(client,arena_index);
			} else
				RemoveFromQueue(client);
		}
		case MenuAction_Cancel: {
		}
		case MenuAction_End: {
			CloseHandle(menu);
		}
    }
}
//events
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast){	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "damageamount");
	//PrintToChatAll("hurt %d(%N) by %d",victim,victim,attacker);
	new arena_index = g_playerArena[victim];
	if (attacker>0 && victim != attacker){
		//decl String:weapon[32];
		//GetClientWeapon(attacker, weapon, sizeof(weapon));
		//if (StrContains(weapon,"rocketlauncher") >= 0 || StrContains(weapon,"grenadelauncher") >= 0)
		if (g_playerTakenDirectHit[victim]){
			if (GetEntityFlags(victim) & (FL_ONGROUND)){// не аиршот
				g_playerTakenAirCount[victim] = 0;
				if(!g_arenaMidair[arena_index] && g_bHitBlip[attacker]) {
					new pitch = 150 - damage;
					if(pitch<45)
						pitch = 45;
					EmitSoundToClient(attacker, "buttons/button17.wav", _, _, _, _, 1.0, pitch);
				}
			} else { //airshot
				decl Float:vStart[3];
				decl Float:vEnd[3];
				new Float:vAngles[3]={90.0,0.0,0.0};
				GetClientAbsOrigin(victim,vStart);
				new Handle:trace = TR_TraceRayFilterEx(vStart, vAngles, MASK_SHOT, RayType_Infinite,TraceEntityFilterPlayer);
				if(TR_DidHit(trace)){   	 
					TR_GetEndPosition(vEnd, trace);
					new Float:dist = GetVectorDistance(vStart, vEnd, false);
					//if (dist>30) PrintToChat(attacker,"%.0f",dist);
					if (dist >= g_airshotHeight){
						//если это midair то отнимает 1 хп
						if (g_arenaMidair[arena_index]) g_playerHP[victim] -= 1;
						//+1 аир
						g_playerTakenAirCount[victim] += 1;	
						//показываем HUD сообщение
						ShowAirshotHudMsg(attacker,g_playerTakenAirCount[victim]);
						if (g_particles){ //рисуем текст над головой
							new String:mc[16] = "midair_text";
							if (g_playerTakenAirCount[victim] > 1 && g_playerTakenAirCount[victim]<=10)
								Format(mc,sizeof(mc),"midair_%d",g_playerTakenAirCount[victim]);
							CreateParticle(victim,mc); //проверке на существование
						}
						//проигрываем звук
						EmitAirshotSound(attacker,g_playerTakenAirCount[victim]);
					}
				} else 
					LogError("trace error. victim %N(%d)",victim,victim);
				CloseHandle(trace);
			}
		}
	}
	
	g_playerTakenDirectHit[victim] = false;
	
	//if (!g_midairEnabled)
	if (!g_arenaMidair[arena_index])
		g_playerHP[victim] -= damage;

	ShowPlayerHud(victim);
	ShowPlayerHud(attacker);
	ShowSpecHudToArena(g_playerArena[victim]);
	
	if (g_playerHP[victim] <= 0)
		SetEntityHealth(victim,0);	
	else
		SetEntityHealth(victim,TFClass_NormalHP[TF2_GetPlayerClass(victim)]);	
		
	//inf ammo crutch here
	//new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	g_playerRestoringAmmo[attacker] = false;
	//end of crutch
	return Plugin_Continue;
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new arena_index = g_playerArena[victim];
	
	//PrintToChatAll("died");
	if (!arena_index)	ChangeClientTeam(victim, TEAM_SPEC);//plugin was reloaded or smthng else
	
	if (g_arenaStatus[arena_index]<AS_FIGHT /*&& g_arenaStatus[arena_index]==AS_AFTERFIGHT*/) {
		CreateTimer(0.1,Timer_ResetPlayer,GetClientUserId(victim));
		return Plugin_Handled;
	}
	
	new victim_slot = g_playerSlot[victim];
	new killer_slot = (victim_slot==SLOT_ONE) ? SLOT_TWO : SLOT_ONE;
	new killer = g_arenaQueue[arena_index][killer_slot];
	/*if (killer==0) {
		//if (g_arenaStatus[arena_index]==AS_IDLE || g_arenaStatus[arena_index]==AS_PRECOUNTDOWN)
		CreateTimer(0.1,Timer_ResetPlayer,victim);
		//else
			//CreateTimer(3.0,Timer_ResetPlayer,victim);
		return Plugin_Continue;
	}*/
	if (!IsPlayerAlive(killer)) return Plugin_Handled;//killer is dead
	
	//if (g_playerHP[client]<=0)  // player died in fight (not just force suicide)
	g_arenaScore[arena_index][killer_slot] += 1;
	PrintCenterText(victim,"%t","HPLeft",g_playerHP[killer]);

	g_arenaStatus[arena_index] = AS_AFTERFIGHT;
	new fraglimit = g_arenaFraglimit[arena_index];
	if (fraglimit>0 && g_arenaScore[arena_index][killer_slot] >= fraglimit){
		new String:killer_name[128];
		new String:victim_name[128];
		GetClientName(killer,killer_name, sizeof(killer_name));
		GetClientName(victim,victim_name, sizeof(victim_name));
		CPrintToChatAll("%t","XdefeatsY", killer_name, victim_name, fraglimit, g_arenaName[arena_index]);
		if (!g_NoStats /* && !g_arenaNoStats[arena_index]*/)
			CalcELO(killer,victim);//начисляем очки

		if (g_arenaQueue[arena_index][SLOT_TWO+1]){//есть ожидающие на арене
			RemoveFromQueue(victim,false);//выкидываем из очереди 
			AddInQueue(victim,arena_index,false); //запихиваем обратно
		} else { // ожидающих нет
			CreateTimer(3.0,Timer_StartDuel,arena_index);
		}
	} else
		CreateTimer(3.0,Timer_NewRound,arena_index);

	ShowPlayerHud(victim); 
	ShowPlayerHud(killer);
	ShowSpecHudToArena(arena_index);
	
	return Plugin_Continue;
}
public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (!client) return Plugin_Continue;
	
	new team = GetEventInt(event,"team");
	
	if (team == TEAM_SPEC){
		//PrintToChatAll("spec");
		HideHud(client);
		CreateTimer(1.0,Timer_ChangeSpecTarget,GetClientUserId(client));
		new arena_index = g_playerArena[client];
		if (arena_index && g_playerSlot[client] <= SLOT_TWO) {
			CPrintToChat(client,"%t","SpecRemove");
			RemoveFromQueue(client);
			//g_playerSingleBlockElo[client] = true;
		}
	} else if (IsClientInGame(client)){ // this code fixing spawn exploit
		//PrintToChat(client,"bad move");
		new arena_index = g_playerArena[client];
		if (arena_index == 0){
			TF2_SetPlayerClass(client,TFClassType:0);
			//ChangeClientTeam(client, TEAM_SPEC);	
		}
	}
	SetEventInt(event, "silent", true);
	return Plugin_Changed;
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	if (g_amEnabled)
		SetConVarInt(gcvar_WfP,1);//cancel waiting for players
	return Plugin_Continue;
}
//timerz
public Action:Timer_CountDown(Handle:timer, any:arena_index) {
	new red_f1 = g_arenaQueue[arena_index][SLOT_ONE];
	new blu_f1 = g_arenaQueue[arena_index][SLOT_TWO];
	if (red_f1 && blu_f1) {
		g_arenaCd[arena_index]--;
		if (g_arenaCd[arena_index]>0){ // blocking +attack
			new Float:enginetime = GetGameTime();
			for (new i=0;i<=2;i++){
				new ent = GetPlayerWeaponSlot(red_f1, i);
				if(IsValidEntity(ent))
					SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", enginetime+float(g_arenaCd[arena_index]));
				ent = GetPlayerWeaponSlot(blu_f1, i);
				if(IsValidEntity(ent))
					SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", enginetime+float(g_arenaCd[arena_index]));
				//SetEntDataFloat(ent, g_offNextPrimaryAttack, enginetime + 5.0, true);
			}
		}
		if (g_arenaCd[arena_index] <= 3 && g_arenaCd[arena_index] >= 1){
			new String:msg[64];
			switch (g_arenaCd[arena_index]){
				case 1: msg = "ONE";
				case 2: msg = "TWO";
				case 3: msg = "THREE";
			}
			PrintCenterText(red_f1,msg);
			PrintCenterText(blu_f1,msg);
			ShowCountdownToSpec(arena_index,msg);
			g_arenaStatus[arena_index] = AS_COUNTDOWN;
			//CreateTimer(1.0,Timer_CountDown,arena_index,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			//return Plugin_Stop;	
		} else if (g_arenaCd[arena_index] <= 0){
			g_arenaStatus[arena_index] = AS_FIGHT;
			new String:msg[64];
			Format(msg,sizeof(msg),"FIGHT",g_arenaCd[arena_index]);
			PrintCenterText(red_f1,msg);
			PrintCenterText(blu_f1,msg);
			ShowCountdownToSpec(arena_index,msg);
			EmitSoundToClient(red_f1, sounds[SOUND_FIGHT], _, _, _, _, 1.0);
			EmitSoundToClient(blu_f1, sounds[SOUND_FIGHT], _, _, _, _, 1.0);
			return Plugin_Stop;
		}
		CreateTimer(1.0,Timer_CountDown,arena_index,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;	
	} else {
		g_arenaStatus[arena_index] = AS_IDLE;
		g_arenaCd[arena_index] = 0;
		return Plugin_Stop;	
	}
}
public Action:Timer_Tele(Handle:timer, any:userid) { //клиент респанулся, "отстоялся" и готов к телепорту
	new client = GetClientOfUserId(userid);
	new arena_index = g_playerArena[client];
	
	if (!arena_index) //фейл
		return;
		
	new player_slot = g_playerSlot[client];
	
	if (player_slot>SLOT_TWO){
		#if defined DEBUG_LOG
		LogToFileEx(g_sLogFile,"tele player fail, player in slot %d, not on arena",player_slot);
		#endif
		return;
	}
	//проверяем наличие FaN'a (в перспективе любого другого оружия)
	g_playerWeaponFlags[client] = 0;
	if (g_playerClass[client] == TFClass_Scout) {
		new weapon = GetPlayerWeaponSlot(client, 0);
		if (IsValidEntity(weapon)){
			new EntityLevel = GetEntProp(weapon, Prop_Send, "m_iEntityLevel");
			if (EntityLevel > 1)
				g_playerWeaponFlags[client] += WF_FAN;
		}
	}
	
	
	new Float:vel[3]={0.0,0.0,0.0}; //0-вектор для прекращения движения на случай если клиент был жив во время телпорта и летел в теплые страны
	TeleportEntity(client,g_arenaSpawnOrigin[arena_index][player_slot],g_arenaSpawnAngles[arena_index][player_slot],vel);
	ShowPlayerHud(client);
	#if defined DEBUG_LOG
	LogToFileEx(g_sLogFile,"A[%d] tele player <%N> OK",arena_index,client);
	#endif
	return;
}
public Action:Timer_NewRound(Handle:timer, any:arena_index) {
	StartCountDown(arena_index);
}
public Action:Timer_StartDuel(Handle:timer, any:arena_index) {
	g_arenaScore[arena_index][SLOT_ONE] = 0;
	g_arenaScore[arena_index][SLOT_TWO] = 0;
	ShowPlayerHud(g_arenaQueue[arena_index][SLOT_ONE]);
	ShowPlayerHud(g_arenaQueue[arena_index][SLOT_TWO]);
	ShowSpecHudToArena(arena_index);	
	StartCountDown(arena_index);
}
public Action:Timer_ResetPlayer(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if (client>0)
		ResetPlayer(client);
}
public Action:Timer_ChangeSpecTarget(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if (client || !IsValidEntity(client))
		return Plugin_Stop;
	new target = GetEntDataEnt2(client,g_offObserverTarget);
	if (target>0 && target < MaxClients && g_playerArena[target]){
		//PrintToChat(client,"%N",target);
		g_playerSpecTarget[client] = target;
		ShowSpecHudToClient(client);
	} else {
		HideHud(client);
		g_playerSpecTarget[client] = 0;
	}
	return Plugin_Stop;
}
public Action:Timer_ShowAdv(Handle:timer, any:userid){
	new client = GetClientOfUserId(userid);
	if (client>0 && g_playerArena[client]==0){
		CPrintToChat(client,"%t","Adv");
		CreateTimer(15.0, Timer_ShowAdv, userid);
	}
}
public Action:Timer_GiveAmmo(Handle:timer, any:userid){
	new client = GetClientOfUserId(userid);
	if (!client || !IsValidEntity(client)) return;
	g_playerRestoringAmmo[client] = false;
	new TFClassType:iClass = TF2_GetPlayerClass(client);
	//if (TFClass_MaxAmmo[iClass][0] != -1)
		//SetEntData(client, g_offAmmo + ((0+1)*4), TFClass_MaxAmmo[iClass][0]);
	new weapon;
	if (TFClass_MaxClip[iClass][0] != -1){
		weapon = GetPlayerWeaponSlot(client, 0);
		if (IsValidEntity(weapon))
			SetEntData(weapon, g_offClip, TFClass_MaxClip[iClass][0]);
	}
	if (TFClass_MaxClip[iClass][1] != -1){
		weapon = GetPlayerWeaponSlot(client, 1);
		if (IsValidEntity(weapon))
			SetEntData(weapon, g_offClip, TFClass_MaxClip[iClass][1]);
	}
	//new weapon = GetEntDataEnt2(client, offsActiveWeapon)
	//SetEntData(weapon, g_offClip, TFClass_MaxClip[iClass][i]);
	/*for (new i = 0; i <= 2; i++){
		if(!(iClass == TFClass_Heavy && i == 1)){
			if (TFClass_MaxAmmo[iClass][i] != -1)
				SetEntData(client, g_offAmmo + ((i+1)*4), TFClass_MaxAmmo[iClass][i]);
			if (i != 2 && TFClass_MaxClip[iClass][i] != -1 && !((g_playerWeaponFlags[client] & WF_FAN) && i == 0)){
				new weapon = GetPlayerWeaponSlot(client, i);
				if (IsValidEntity(weapon))
					SetEntData(weapon, g_offClip, TFClass_MaxClip[iClass][i]);
			}
		}
	}*/
	
}
public Action:Timer_DeleteParticle(Handle:timer, any:particle){
	if (IsValidEdict(particle)) {
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		
		if (StrEqual(classname, "info_particle_system", false)) {
			RemoveEdict(particle);
			//return 1;
		}
	}
}
public Action:Timer_AddBotInQueue(Handle:timer, Handle:pk){
	ResetPack(pk);
	new client = GetClientOfUserId(ReadPackCell(pk));
	new arena_index = ReadPackCell(pk);
	AddInQueue(client,arena_index);
}
//shooting detection
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){ 
	if (g_amEnabled && g_infAmmo){
		if (!g_playerRestoringAmmo[client] && (buttons & IN_ATTACK)){
			g_playerRestoringAmmo[client] = true;
			CreateTimer(0.4,Timer_GiveAmmo,GetClientUserId(client));
		}
	}
}
public bool:TraceEntityFilterPlayer(entity, contentsMask){
	return entity > GetMaxClients() || !entity;
}