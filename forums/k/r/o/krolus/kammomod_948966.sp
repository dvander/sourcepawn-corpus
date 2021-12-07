/* Этот плагин - попытка воспроизвести закрытый плагин AmmoMod (автор thenoid)
* author: kroleg
* site: http://tf2.kz
* Thanks to AlliedModers community.
****************************************************************/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <entity_prop_stocks>

//#define SM13 //sourcemod version

#define PLUGIN_VERSION "0.4.2"
#define MAX_FILE_LEN 80
#define MAXARENAS 10
#define HUDFADEOUTTIME 120.0
#define MAPCONFIGFILE "configs/kammomod.txt"
//arena slot
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
#define SOUND_COUNT 8

//#define DEBUG_LOG

public Plugin:myinfo ={
  name = "kAmmomod",
  author = "kroleg",
  description = "Duel mod with infinite ammo and buffed HP",
  version = PLUGIN_VERSION,
  url = "http://tf2.kz"
}

static const TFClass_MaxAmmo[TFClassType][3] ={
  {-1, -1, -1}, {32, 36, -1},
  {25, 75, -1}, {20, 32, -1},
  {16, 24, -1}, {150, -1, -1},
  {200, 32, -1}, {200, 32, -1},
  {24, -1, -1}, {32, 200, 200}
};

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

new String:sounds[][]={ "quake/fight.mp3",
						"quake/hit_loud.mp3",
						"quake/perfect_loud.mp3",
						"quake/dominating.mp3",
						"quake/female/rampage.mp3",
						"quake/unstoppable2_loud.mp3",
						"quake/female/godlike.mp3",
						"quake/combowhore_loud.mp3",
						"quake/female/wickedsick.mp3",
						"quake/female/holyshit.mp3"};

//hud handles
new Handle:hm_HP = INVALID_HANDLE,
	//Handle:hm_Airshot = INVALID_HANDLE,
	Handle:hm_Score = INVALID_HANDLE;
	
new bool:g_amEnabled,
	bool:g_infAmmo,
	bool:g_blockFallDamage;

//global cvars
new Handle:gcvar_WfP = INVALID_HANDLE,
	Handle:gcvar_fragLimit = INVALID_HANDLE,
	Handle:gcvar_infAmmo = INVALID_HANDLE,
	Handle:gcvar_hpbuffClasses = INVALID_HANDLE,
	Handle:gcvar_hpbuffRatio = INVALID_HANDLE,
	Handle:gcvar_blockFallDamage = INVALID_HANDLE;
	
//classes hp buff
new bool:g_classHaveHPBuff[TFClassType];
new Float:g_hpRatio;
new g_fragLimit;

//arena cvars
new g_arenaCount,//кол-во арен на карте
	String:g_arenaName[MAXARENAS+1][64],// название арен
	g_arenaScore[MAXARENAS+1][3],// счет фрагов
	g_arenaQueue[MAXARENAS+1][MAXPLAYERS+1],// место хранения клиентских ид участвующих в бое (SLOT_ONE и SLOT_TWO) и ожидающих (>SLOT_TWO)
	g_arenaStatus[MAXARENAS+1], // статус арены, см. #define AS_
	Float:g_arenaSpawnOrigin[MAXARENAS+1][3][3], // арена | слот | 0/1/2 = x/y/z
	Float:g_arenaSpawnAngles[MAXARENAS+1][3][3], // арены | слот | 0/1/2 = pitch/yaw/roll
	g_arenaCd[MAXARENAS+1];//countdown to round start
	
//player vars
new g_playerOnArena[MAXPLAYERS+1],
	g_playerInSlot[MAXPLAYERS+1],
	TFClassType:g_playerClass[MAXPLAYERS+1],
	g_player_old_health[MAXPLAYERS + 1],
	g_playerHP[MAXPLAYERS + 1],
	bool:g_playerRestoringAmmo[MAXPLAYERS+1],//player awaiting full ammo restore
	g_playerTakenAirCount[MAXPLAYERS+1];//airshot counter
	
//for spec hud
new g_offObserverTarget;
new g_playerSpecTarget[MAXPLAYERS+1];

//log
new String:g_sLogFile[PLATFORM_MAX_PATH];

//block shooting
new offsNextPrimaryAttack;

/*TODO**************************************************************
1) фраглимит в описании арены
2) удаление пайп, трупов и т.д а также 
2) тушение дуелянтов в конце раунда
3) hudmsg для аиршотов
4) изменить систему аиршотов, при попадании считать расстояние до пола
	decl Float:vecOrigin[3], Float:vecAng[3], Float:vecPos[3];

	TR_GetEndPosition(vecPos, trace);

	vecOrigin[0] = (x);
	vecOrigin[1] = (y);
	vecOrigin[2] = (z);

. удаление из всех очередей если POA = 0
. отключение статы valve
*********************************************************************/
/*BUGS**************************************************************
(01) сообщение про хп противника при переходе в спеки
******************************************************************/

public OnPluginStart(){
	//ConVar's
	CreateConVar("sm_kammomod_version", PLUGIN_VERSION, "kAmmomod version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	gcvar_fragLimit = CreateConVar("kammomod_fraglimit", "3", "Frag limit in duel", FCVAR_PLUGIN);
	gcvar_hpbuffClasses = CreateConVar("kammomod_hpbuff_classes", "soldier demoman scout pyro", "Classes that have buffed HP", FCVAR_PLUGIN);
	gcvar_hpbuffRatio = CreateConVar("kammomod_hpbuff_ratio", "6.0", "HP multiplier", FCVAR_PLUGIN);
	gcvar_infAmmo = CreateConVar("kammomod_infammo", "1", "Give player infinite ammo", FCVAR_PLUGIN);
	gcvar_blockFallDamage = CreateConVar("kammomod_block_falldamage", "1", "Block falldamage 1 = Enabled", FCVAR_PLUGIN);
	gcvar_WfP = FindConVar("mp_waitingforplayers_cancel");
	
	//setting vars
	g_fragLimit = GetConVarInt(gcvar_fragLimit);
	g_hpRatio = GetConVarFloat(gcvar_hpbuffRatio);
	GetConVarInt(gcvar_infAmmo) ? (g_infAmmo = true) : (g_infAmmo = false);
	GetConVarInt(gcvar_blockFallDamage) ? (g_blockFallDamage = true) : (g_blockFallDamage = false);
	
	//parsing allowed classes convar
	decl String:hpbuffed_classes[128];
	GetConVarString(gcvar_hpbuffClasses,hpbuffed_classes,sizeof(hpbuffed_classes));
	new String:a_class[9][8];
	new count = ExplodeString(hpbuffed_classes, " ", a_class, 9, 8);
	for (new i=1;i<=9;i++)
		g_classHaveHPBuff[i] = false;
	for (new i=0;i<count;i++)
		g_classHaveHPBuff[TF2_GetClass(a_class[i])] = true;
		
	//hooking convar changing
	HookConVarChange(gcvar_fragLimit, handler_ConVarChange);
	HookConVarChange(gcvar_hpbuffClasses, handler_ConVarChange);
	HookConVarChange(gcvar_hpbuffRatio, handler_ConVarChange);
	HookConVarChange(gcvar_infAmmo, handler_ConVarChange);
	
	//обрабатываем смену класса
	RegConsoleCmd("joinclass", Command_JoinClass);
	//команды для доступа к меню
	RegConsoleCmd("ammomod", Command_Menu, "kAmmomod Menu");
	RegConsoleCmd("add", Command_Menu, "kAmmomod Menu (alias)");
	//spec
	RegConsoleCmd("spec_next", Command_Spec, "");
	RegConsoleCmd("spec_prev", Command_Spec, "");
	//cfg makin
	RegConsoleCmd("loc", Command_Loc, "Shows client origin and angle vectors");
	//HUD
	hm_HP = CreateHudSynchronizer();
	hm_Score = CreateHudSynchronizer();

	//spec target
	g_offObserverTarget = FindSendPropOffs("CBasePlayer", "m_hObserverTarget");	
	if(g_offObserverTarget == -1) 
		SetFailState("Expected to find the offset to m_hObserverTarget, couldn't.");
	//for blocking shooting
	offsNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");
	if(offsNextPrimaryAttack == -1) 
		SetFailState("Expected to find the offset to offsNextPrimaryAttack, couldn't.");
	BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "logs/kammomod.log");
}

public OnPluginEnd(){
	for(new i=1;i<=MaxClients;i++){
		if (IsClientInGame(i))
			HidePlayerHud(i);
	}
}

public OnMapStart(){
	//loadin sounds
	decl String:downloadFile[PLATFORM_MAX_PATH];
	for (new i=0;i<=9;i++){
		if(PrecacheSound(sounds[i], true)){
			Format(downloadFile, PLATFORM_MAX_PATH, "sound/%s", sounds[i]);		
			AddFileToDownloadsTable(downloadFile);
		} else
			LogError("[kAmmomod] Cannot precache sound: %s", sounds[i]);
	}
	//loading spawn config
	new isMapAm = LoadSpawnPoints();
	if (isMapAm){
		if (!g_amEnabled){
			g_amEnabled = true;
			HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
			HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
			HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
			HookEvent("teamplay_round_start", Event_RoundStart);
			AddNormalSoundHook(sound_hook);
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
	if (g_amEnabled && client)
		CreateTimer(5.0, Timer_ShowAdv, client);
}

public OnClientDisconnect(client){
	if (client>0 && g_playerOnArena[client])
		RemoveFromQueue(client);
}

#if defined SM13 //OnPlayerRunCmd
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	if (g_amEnabled && g_infAmmo && (buttons & IN_ATTACK) && !g_playerRestoringAmmo[client]){
		CreateTimer(0.4,Timer_GiveAmmo,client);
		g_playerRestoringAmmo[client] = true;
		//PrintToChatAll("sm13");
	}
}  
#endif

//начинаем новую дуель
StartDuel(arena_index){
	#if defined DEBUG_LOG
	LogToFileEx(g_sLogFile,"A[%d] starting duel",arena_index);
	#endif
	if (StartCountDown(arena_index)){
		g_arenaScore[arena_index][SLOT_ONE] = 0;
		g_arenaScore[arena_index][SLOT_TWO] = 0;
		return 1;
	} else
		return 0;
}

//начинаем отсчет нового раунда
StartCountDown(arena_index){
	new red_f1 = g_arenaQueue[arena_index][SLOT_ONE];
	new blu_f1 = g_arenaQueue[arena_index][SLOT_TWO];
	if (red_f1 && blu_f1) {
		/*if (g_arenaCd[arena_index]>0)
			return 0;*/
		ResetPlayer(red_f1);
		ResetPlayer(blu_f1);
		//SetBuddha(red_f1);
		//SetBuddha(blu_f1);
		new Float:enginetime = GetGameTime();
		for (new i=0;i<=2;i++){
			new ent = GetPlayerWeaponSlot(red_f1, i);
			if(IsValidEntity(ent))
				SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", enginetime+5.0);
			ent = GetPlayerWeaponSlot(blu_f1, i);
			if(IsValidEntity(ent))
				SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", enginetime+5.0);
			//SetEntDataFloat(ent, offsNextPrimaryAttack, enginetime + 5.0, true);
		}
		g_arenaCd[arena_index] = 5;
		g_arenaStatus[arena_index] = AS_PRECOUNTDOWN;
		CreateTimer(1.0,Timer_CountDown,arena_index,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		return 1;
	} else {
		g_arenaStatus[arena_index] = AS_IDLE;
		//if (red_f1) SetMortal(red_f1);
		//if (blu_f1) SetMortal(blu_f1);
		return 0;
	}
}

//ставим игрока на положенное место, респауним если нужно, устанавливаем HP
ResetPlayer(client){
	new arena_index = g_playerOnArena[client];
	new player_slot = g_playerInSlot[client];
	
	if (!arena_index || !player_slot){
		//убиваем и обнуляем класс
		//проверяем, может игрок на арене, и это баг что нет слота и арены
		return 0;
	}
	#if defined DEBUG_LOG
	else
		LogToFileEx(g_sLogFile,"a[%d] (Reset) Begin for <%N><%d> slot {%d}",arena_index,client,client,player_slot);
	#endif
	g_playerSpecTarget[client] = 0;
	
	SetEntProp(client, Prop_Send, "m_lifeState", 2);

	new team = GetClientTeam(client);
	if (player_slot - team != SLOT_ONE - TEAM_RED)
		ChangeClientTeam(client, player_slot + TEAM_RED - SLOT_ONE);
	
	new TFClassType:class = TFClass_Soldier; 
	if (g_playerClass[client]) {
		class = g_playerClass[client];
	}
	if (!IsPlayerAlive(client)){
		new BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(IsValidEdict(BodyRagdoll)){ //removing corpse
			RemoveEdict(BodyRagdoll);
		}
		if (class != TF2_GetPlayerClass(client)) TF2_SetPlayerClass(client,class);
		TF2_RespawnPlayer(client);
	} else //если живой то лечим
		SetEntityHealth(client, TFClass_NormalHP[class]);
	SetEntProp(client, Prop_Send, "m_lifeState", 0);		
		
	if (g_classHaveHPBuff[class])
		g_playerHP[client] = RoundToNearest(float(TFClass_NormalHP[class])*g_hpRatio);
	else
		g_playerHP[client] = TFClass_NormalHP[class];
	ShowPlayerHud(client);
	#if defined DEBUG_LOG
	LogToFileEx(g_sLogFile,"a[%d] (Reset) End (timertele - next) for <%N><%d> slot {%d}",arena_index,client,client,player_slot);
	#endif
	CreateTimer(0.1,Timer_Tele,client);	
	return 1;
}

//удаление игрока из очереди с продвижением ожидающих и заполнением арены при необходимости 
RemoveFromQueue(client,bool:move_spec=true){
	new arena_index = g_playerOnArena[client];
	if (arena_index <= 0)
		return;
	new player_slot = g_playerInSlot[client];
	g_playerOnArena[client] = 0;
	g_playerInSlot[client] = 0;
	g_arenaQueue[arena_index][player_slot] = 0;
	if (IsClientInGame(client) && move_spec){
		ChangeClientTeam(client, TEAM_SPEC);
		#if defined DEBUG_LOG
		LogToFileEx(g_sLogFile,"a[%d] (RFQ) <%N><%d> from slot %d (moved to spec)",arena_index,client,client,player_slot);
		#endif
	} 
	#if defined DEBUG_LOG
	else
		LogToFileEx(g_sLogFile,"a[%d] (RFQ) <%N><%d> from slot %d",arena_index,client,client,player_slot);
	#endif
	
	new after_leaver_slot = player_slot + 1; //если игрок ушел из ожидающих то при сдвиге очереди перемещение начнется со следующего игрока
	if (player_slot==SLOT_ONE || player_slot==SLOT_TWO) {//игрок ушел с арены
		if (g_arenaQueue[arena_index][SLOT_TWO+1]){ // если есть ожидающие
			//перекидываем 1-го(3й слот) из очереди на арену
			new next_client = g_arenaQueue[arena_index][SLOT_TWO+1];
			g_arenaQueue[arena_index][SLOT_TWO+1] = 0;
			g_arenaQueue[arena_index][player_slot] = next_client;
			g_playerInSlot[next_client] = player_slot;
			after_leaver_slot = SLOT_TWO + 2;
			#if defined DEBUG_LOG
			LogToFileEx(g_sLogFile,"a[%d] (RFQ) <%N><%d> leaved arena, replaced by <%N><%d>",arena_index,client,client,next_client,next_client);
			if (g_arenaCd[arena_index]>0)
				LogToFileEx(g_sLogFile,"fail in <remove from queue>: countdown time = %d. arena %d <%d>",g_arenaCd[arena_index],arena_index,g_arenaStatus[arena_index]);
			#endif
			PrintToChatAll("\x03%N \x01joins arena \x04[%s]",next_client,g_arenaName[arena_index]);
			//StartDuel(arena_index);
			CreateTimer(2.0,Timer_StartDuel,arena_index);
			#if defined DEBUG_LOG
			LogToFileEx(g_sLogFile,"a[%d] (RFQ) ct_StartDuel (2.0)",arena_index);
			#endif
		} else {//ожидающих нет
			#if defined DEBUG_LOG
			LogToFileEx(g_sLogFile,"a[%d] (RFQ) <%N><%d> leaved arena and no more player in Q",arena_index,client,client);
			#endif
			g_arenaStatus[arena_index] = AS_IDLE;
			return;
		}
	}	
	//сдвигаем очередь вперед
	#if defined DEBUG_LOG
	LogToFileEx(g_sLogFile,"a[%d] (RFQ) slot[%d] = <%N><%d>",arena_index,after_leaver_slot,g_arenaQueue[arena_index][after_leaver_slot],g_arenaQueue[arena_index][after_leaver_slot]);
	#endif
	if (g_arenaQueue[arena_index][after_leaver_slot]){
		while (g_arenaQueue[arena_index][after_leaver_slot]){
			g_arenaQueue[arena_index][after_leaver_slot-1] = g_arenaQueue[arena_index][after_leaver_slot];
			g_playerInSlot[g_arenaQueue[arena_index][after_leaver_slot]] -= 1;
			after_leaver_slot++;
		}
		g_arenaQueue[arena_index][after_leaver_slot-1] = 0;
	}
	#if defined DEBUG_LOG
	LogToFileEx(g_sLogFile,"a[%d] (RFQ) Q moved",arena_index);
	#endif
	return;
}

//добавление игрока в очередь 
AddPlayerInQueue(client,arena_index, bool:forced = false){
	if (g_playerOnArena[client]) {
		//if (fighting) return
		new old_arena_index = g_playerOnArena[client];
		if (old_arena_index == arena_index && !forced) //добавить на ту же арену, где клиент сейчас, при этом форсед = 0
			return;
		#if defined DEBUG_LOG
		LogToFileEx(g_sLogFile,"a[%d] (ATQ) rem <%N><%d> from Q[%d] ",arena_index,client,client,old_arena_index);
		#endif
		RemoveFromQueue(client,false);
	}
	new player_slot = SLOT_ONE;
	while (g_arenaQueue[arena_index][player_slot])
		player_slot++;
	#if defined DEBUG_LOG
	LogToFileEx(g_sLogFile,"a[%d] (ATQ) adding <%N><%d> to slot {%d}",arena_index,client,client,player_slot);
	#endif
	g_playerOnArena[client] = arena_index;
	g_playerInSlot[client] = player_slot;
	g_arenaQueue[arena_index][player_slot] = client;
	if (!forced)
		PrintToChat(client,"\x01You select arena \x04[%s]",g_arenaName[arena_index]);
	if (player_slot <= SLOT_TWO){
		PrintToChatAll("\x03%N \x01joins arena \x04[%s]",client,g_arenaName[arena_index]);
		if (g_arenaQueue[arena_index][SLOT_ONE] && g_arenaQueue[arena_index][SLOT_TWO]){
			#if defined DEBUG_LOG
			LogToFileEx(g_sLogFile,"a[%d] (ATQ) ct_startduel(1.5). added <%N><%d> to slot {%d} (f)",arena_index,client,client,player_slot);
			#endif
			CreateTimer(1.5,Timer_StartDuel,arena_index);
		} else {
			#if defined DEBUG_LOG
			LogToFileEx(g_sLogFile,"a[%d] (ATQ) ct_resetplayer(0.1). added <%N><%d> to slot {%d} (nf)",arena_index,client,client,player_slot);
			#endif
			CreateTimer(0.1,Timer_ResetPlayer,client);
		}
	} else {
		#if defined DEBUG_LOG
		LogToFileEx(g_sLogFile,"a[%d] (ATQ) mov <%N><%d> spec, slot {%d}",arena_index,client,client,player_slot);
		#endif
		ChangeClientTeam(client, TEAM_SPEC);
		if (player_slot == SLOT_TWO + 1)
			PrintToChat(client,"\x01You are \x04next\x01 in line",g_arenaName[arena_index]);
	 	else //if (player_slot > SLOT_TWO + 1) 
			PrintToChat(client,"\x01You are \x04%d\x01 in line",player_slot-SLOT_TWO);
	}
	#if defined DEBUG_LOG
	LogToFileEx(g_sLogFile,"a[%d] (ATQ) succeed <%N><%d> slot {%d}",arena_index,client,client,player_slot);
	#endif
	return;
}

public handler_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if (convar == gcvar_infAmmo)
		StringToInt(newValue)? (g_infAmmo = true) : (g_infAmmo = false);
	if (convar == gcvar_fragLimit)
		g_fragLimit = StringToInt(newValue);
	if (convar == gcvar_hpbuffClasses){
		decl String:hpbuffed_classes[128];
		GetConVarString(gcvar_hpbuffClasses,hpbuffed_classes,sizeof(hpbuffed_classes));
		new String:a_class[9][8];
		new count = ExplodeString(hpbuffed_classes, " ", a_class, 9, 8);
		for (new i=1;i<=9;i++)
			g_classHaveHPBuff[i] = false;
		for (new i=0;i<count;i++)
			g_classHaveHPBuff[TF2_GetClass(a_class[i])] = true;	
	}
	if (convar == gcvar_hpbuffRatio)
		g_hpRatio = StringToFloat(newValue);
}

//blocking fallpain sound
public Action:sound_hook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags){
//pl_fleshbreak
	if(StrContains(sample,"pl_fallpain")>=0){
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

//handle commands "!ammomod" "!add" and such 
//building queue's menu and list arena's
public Action:Command_Menu(client, args){
	decl String:title[128];
	decl String:menu_item[128];

	new Handle:menu = CreateMenu(Menu_Main);

	Format(title, sizeof(title), "AimMod Menu. Join arena...");
	SetMenuTitle(menu, title);
	new String:si[4];
	for (new i=1;i<=g_arenaCount;i++){
		Format(menu_item,sizeof(menu_item),"%s",g_arenaName[i]);
		IntToString(i,si,sizeof(si));
		AddMenuItem(menu, si, menu_item);
	}
	Format(menu_item,sizeof(menu_item),"Remove from all queues");
	AddMenuItem(menu, "1000", menu_item);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
	
	new String:report[128];
	
	for (new i=1;i<=g_arenaCount;i++){
		new red_f1 = g_arenaQueue[i][SLOT_ONE];
		new blu_f1 = g_arenaQueue[i][SLOT_TWO];
		if (red_f1>0 || blu_f1>0){
			Format(report,sizeof(report),"\x05%s:",g_arenaName[i]);
			if (red_f1>0 && blu_f1>0)
				Format(report,sizeof(report),"%s \x04%N \x05vs \x04%N \x05",report,g_arenaQueue[i][SLOT_ONE],g_arenaQueue[i][SLOT_TWO]);
			else if (red_f1>0)
				Format(report,sizeof(report),"%s \x04%N\x05",report,g_arenaQueue[i][SLOT_ONE]);
			else if (blu_f1>0)
				Format(report,sizeof(report),"%s \x04%N\x05",report,g_arenaQueue[i][SLOT_TWO]);	
			if (g_arenaQueue[i][SLOT_TWO + 1]) {
				Format(report,sizeof(report),"%s Waiting(",report);
				new j = SLOT_TWO + 1;
				while (g_arenaQueue[i][j]){
					Format(report,sizeof(report),"%s\x04%N\x05 ",report,g_arenaQueue[i][j]);
					j++;
				}
				Format(report,sizeof(report),"%s\x05)",report);
			}
			//Format(report,sizeof(report),"%s\n",report);
			PrintToChat(client,"%s",report);
		}
	}
	
	return Plugin_Handled;
}

//handle changing class
public Action:Command_JoinClass(client, args){
	if (!g_amEnabled || !client || IsFakeClient(client))
		return Plugin_Continue;

	if (args) {
		//PrintToChat(client,"joinclass");
		new String:s_class[32];
		GetCmdArg(1, s_class, sizeof(s_class));
		new TFClassType:new_class = TF2_GetClass(s_class);
		new arena_index = g_playerOnArena[client];
		if (arena_index && (g_playerInSlot[client]==SLOT_ONE || g_playerInSlot[client]==SLOT_TWO)){
			if (new_class == g_playerClass[client])
				return Plugin_Handled;
			if (g_arenaStatus[arena_index] == AS_IDLE || g_arenaCd[arena_index] >= 2 || g_arenaStatus[arena_index] == AS_AFTERFIGHT){
				g_playerClass[client] = new_class;
				CreateTimer(0.1,Timer_ResetPlayer,client);
				return Plugin_Continue;
			}
		} else {
			g_playerClass[client] = new_class;
			ChangeClientTeam(client,TEAM_SPEC);
		}
	}
	return Plugin_Handled;
}

//detecting spectator target
public Action:Command_Spec(client, args){
	if (!client) 
		return Plugin_Continue;
	CreateTimer(0.1,Timer_ChangeSpec,client);
	return Plugin_Continue;
}

//showing location
public Action:Command_Loc(client, args){
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	new Float:ang[3];
	GetClientEyeAngles(client, ang);
	PrintToChat(client,"%.1f %.1f %.1f %.1f %.1f %.1f",vec[0],vec[1],vec[2],ang[0],ang[1],ang[2]);
	return Plugin_Handled;
}

//обработка меню !add
public Menu_Main(Handle:menu, MenuAction:action, param1, param2) {
    switch (action) {
		case MenuAction_Select: {
			new client = param1;
			new String:capt[32];
			new String:sanum[32];
			
			GetMenuItem(menu, param2, sanum,sizeof(sanum), _,capt, sizeof(capt));
			new arena_index = StringToInt(sanum);
			if (arena_index>0 && arena_index <=MAXARENAS)
				AddPlayerInQueue(client,arena_index);
			else
				RemoveFromQueue(client);
		}
		case MenuAction_Cancel: {
		}
		case MenuAction_End: {
			CloseHandle(menu);
		}
    }
}

//сохраняем хп для выяснения нанесенного дамага
public OnGameFrame(){
	if (g_amEnabled)
		for (new client = 1; client <= MaxClients; client++) 
			if (IsClientInGame(client) && (g_playerInSlot[client]==SLOT_ONE || g_playerInSlot[client]==SLOT_TWO)) {
				g_player_old_health[client] = GetClientHealth(client);
				if (GetEntityFlags(client) & (FL_ONGROUND))// игрок на земле
					g_playerTakenAirCount[client] = 0;
				#if !defined SM13 //TF2_CalcIsAttackCritical
				if (g_infAmmo){
					new buttons = GetClientButtons(client);
					if ((buttons & IN_ATTACK) && !g_playerRestoringAmmo[client]){
						CreateTimer(0.4,Timer_GiveAmmo,client);
						g_playerRestoringAmmo[client] = true;
						//PrintToChatAll("sm12");
					}
				}
				#endif
			}
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast){	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (attacker || !g_blockFallDamage/*&& g_arenaStatus[g_playerOnArena[attacker]]!=AS_COUNTDOWN*/) 
		g_playerHP[victim] -= g_player_old_health[victim] - GetEventInt(event,"health");
		
	ShowPlayerHud(victim);
	ShowSpecHudToArena(g_playerOnArena[victim]);

	if (g_playerHP[victim] <= 0)
		SetEntityHealth(victim,0);	
	else
		//SetEntityHealth(victim,g_playerHP[victim]);	
		SetEntityHealth(victim,TFClass_NormalHP[TF2_GetPlayerClass(victim)]);	
	if (attacker>0){
		decl String:weapon[32];
		GetClientWeapon(attacker, weapon, sizeof(weapon));
		if ((StrContains(weapon,"rocketlauncher") >= 0 || StrContains(weapon,"grenadelauncher") >= 0) && victim != attacker){
			if (GetEntityFlags(victim) & (FL_ONGROUND)){// не аиршот
				g_playerTakenAirCount[victim] = 0;
			} else { //airshot
				//проигрываем звук аиршота
				if (g_playerTakenAirCount[victim] <= SOUND_COUNT)
					EmitSoundToClient(attacker, sounds[SOUND_FIRSTAIR + g_playerTakenAirCount[victim]], _, _, _, _, 0.9);
				else
					EmitSoundToClient(attacker, sounds[SOUND_FIRSTAIR + SOUND_COUNT], _, _, _, _, 0.9);
				//+1 аир
				g_playerTakenAirCount[victim] += 1;		
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new arena_index = g_playerOnArena[victim];
	#if defined DEBUG_LOG
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	#endif
	/*new team = GetClientTeam(victim);
	if (team==TEAM_SPEC)
		return Plugin_Continue;*/
	
	if (!arena_index) {
		ChangeClientTeam(victim, TEAM_SPEC);
		#if defined DEBUG_LOG
		LogToFileEx(g_sLogFile,"A[%d] V|%d At|%d <victim not on arena>",arena_index,victim,attacker);
		#endif
		return Plugin_Continue;
	}
	
	if (g_arenaStatus[arena_index]!=AS_FIGHT) {
		CreateTimer(0.1,Timer_ResetPlayer,victim);
		return Plugin_Handled;
	}
	
	new victim_slot = g_playerInSlot[victim];
	new enemy_slot = SLOT_ONE;
	if (victim_slot == SLOT_ONE)
		enemy_slot = SLOT_TWO;		
	new enemy = g_arenaQueue[arena_index][enemy_slot];
	if (!enemy) {
		#if defined DEBUG_LOG
		LogToFileEx(g_sLogFile,"A[%d] V|%d At|%d <enemy=0>",arena_index,victim,attacker);
		#endif
		//if (g_arenaStatus[arena_index]==AS_IDLE || g_arenaStatus[arena_index]==AS_PRECOUNTDOWN)
		CreateTimer(0.1,Timer_ResetPlayer,victim);
		//else
			//CreateTimer(3.0,Timer_ResetPlayer,victim);
		return Plugin_Continue;
	}
	if (!IsPlayerAlive(enemy)){
		#if defined DEBUG_LOG
		LogToFileEx(g_sLogFile,"A[%d] V|%d At|%d <enemy dead>",arena_index,victim,attacker);
		#endif
		return Plugin_Handled;
	}
	
	g_arenaScore[arena_index][enemy_slot] += 1;
	PrintCenterText(victim,"Your attacker has %d hp left",g_playerHP[enemy]);
	ShowPlayerHud(victim); 
	ShowPlayerHud(enemy);
	ShowSpecHudToArena(arena_index);
	g_arenaStatus[arena_index] = AS_AFTERFIGHT;
	if (g_fragLimit>0 && g_arenaScore[arena_index][enemy_slot] >= g_fragLimit){
		PrintToChatAll("\x04%N\x01 defeats \x04%N\x01 in duel to \x04%d\x01 on \x03[%s]",
			g_arenaQueue[arena_index][enemy_slot],
			g_arenaQueue[arena_index][victim_slot],
			g_fragLimit,
			g_arenaName[arena_index]);
		if (g_arenaQueue[arena_index][SLOT_TWO+1]){
			#if defined DEBUG_LOG
			LogToFileEx(g_sLogFile,"A[%d] V|%d At|%d <victim looser, moving him to q end>",arena_index,victim,attacker);
			#endif
			AddPlayerInQueue(victim,arena_index,true); //перекидываем жертву в конец очереди
		} else {
			#if defined DEBUG_LOG
			LogToFileEx(g_sLogFile,"A[%d] V|%d At|%d <victim looser, restarting duel>",arena_index,victim,attacker);
			#endif
			CreateTimer(3.0,Timer_StartDuel,arena_index);
		}
	} else {
		#if defined DEBUG_LOG
		if (g_arenaCd[arena_index])
			LogToFileEx(g_sLogFile,"fail in <timer new round>. countdown time = %d. arena %d <%d>",g_arenaCd[arena_index],arena_index,g_arenaStatus[arena_index]);
		LogToFileEx(g_sLogFile,"A[%d] V|%d At|%d <enemy alive, start new round>",arena_index,victim,attacker);
		#endif
		CreateTimer(3.0,Timer_NewRound,arena_index);
		}
	#if defined DEBUG_LOG
	LogToFileEx(g_sLogFile,"A[%d] V|%d At|%d <player_death> ended",arena_index,victim,attacker);
	#endif
	return Plugin_Continue;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new team = GetEventInt(event,"team");
	if (team == TEAM_SPEC){
		HidePlayerHud(client);
		CreateTimer(1.0,Timer_ChangeSpec,client);
		new arena_index = g_playerOnArena[client];
		if (arena_index && g_playerInSlot[client] <= SLOT_TWO) {
			//g_arenaStatus[arena_index] = AS_IDLE;
			RemoveFromQueue(client);
			PrintToChat(client,"\x01Can't go in spec while on arena, removing form queue.",g_arenaName[arena_index]);
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

public Action:Timer_CountDown(Handle:timer, any:arena_index) {
	new red_f1 = g_arenaQueue[arena_index][SLOT_ONE];
	new blu_f1 = g_arenaQueue[arena_index][SLOT_TWO];
	if (red_f1 && blu_f1) {
		g_arenaCd[arena_index]--;
		if (g_arenaCd[arena_index]>0){
			new Float:enginetime = GetGameTime();
			for (new i=0;i<=2;i++){
				new ent = GetPlayerWeaponSlot(red_f1, i);
				if(IsValidEntity(ent))
					SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", enginetime+float(g_arenaCd[arena_index]));
				ent = GetPlayerWeaponSlot(blu_f1, i);
				if(IsValidEntity(ent))
					SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", enginetime+float(g_arenaCd[arena_index]));
				//SetEntDataFloat(ent, offsNextPrimaryAttack, enginetime + 5.0, true);
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
			g_arenaStatus[arena_index] = AS_COUNTDOWN;
			return Plugin_Continue;	
		} else if (g_arenaCd[arena_index] <= 0){
			g_arenaStatus[arena_index] = AS_FIGHT;
			new String:msg[64];
			Format(msg,sizeof(msg),"FIGHT",g_arenaCd[arena_index]);
			PrintCenterText(red_f1,msg);
			PrintCenterText(blu_f1,msg);
			EmitSoundToClient(red_f1, sounds[SOUND_FIGHT], _, _, _, _, 0.9);
			EmitSoundToClient(blu_f1, sounds[SOUND_FIGHT], _, _, _, _, 0.9);
			return Plugin_Stop;
		}
		return Plugin_Continue;	
	} else {
		g_arenaStatus[arena_index] = AS_IDLE;
		g_arenaCd[arena_index] = 0;
		return Plugin_Stop;	
	}
}

public Action:Timer_Tele(Handle:timer, any:client) {
	new arena_index = g_playerOnArena[client];
	
	if (!arena_index) 
		return Plugin_Stop;

	new player_slot = g_playerInSlot[client];
	
	if (player_slot>SLOT_TWO){
		#if defined DEBUG_LOG
		LogToFileEx(g_sLogFile,"tele player fail, player in slot %d, not on arena",player_slot);
		#endif
		return Plugin_Handled;
	}
	new Float:vel[3]={0.0,0.0,0.0};
	//TeleportEntity(client,g_arenaSpawnOrigin[arena_index][player_slot],g_arenaSpawnAngles[arena_index][player_slot],NULL_VECTOR);
	TeleportEntity(client,g_arenaSpawnOrigin[arena_index][player_slot],g_arenaSpawnAngles[arena_index][player_slot],vel);
	ShowPlayerHud(client);
	return Plugin_Handled;
}

public Action:Timer_NewRound(Handle:timer, any:arena_index) {
	StartCountDown(arena_index);
}

public Action:Timer_StartDuel(Handle:timer, any:arena_index) {
	StartDuel(arena_index);
}

public Action:Timer_ResetPlayer(Handle:timer, any:client) {
	ResetPlayer(client);
}

public Action:Timer_ChangeSpec(Handle:timer, any:client) {
	if (!IsValidEntity(client))
		return Plugin_Stop;
	new target = GetEntDataEnt2(client,g_offObserverTarget);
	if (target>0 && target < MaxClients && g_playerOnArena[target]){
		//PrintToChat(client,"%N",target);
		g_playerSpecTarget[client] = target;
		ShowSpecHudToClient(client);
	} else {
		HidePlayerHud(client);
		g_playerSpecTarget[client] = 0;
	}
	return Plugin_Stop;
}

public Action:Timer_ShowAdv(Handle:timer, any:client){
	PrintToChat(client,"\x05Join an arena, type \x01/add");
}

public Action:Timer_GiveAmmo(Handle:timer, any:client){
	GiveAmmo(client);
}

GiveAmmo(client){
	g_playerRestoringAmmo[client] = false;
	new TFClassType:iClass = TF2_GetPlayerClass(client);
	new bool:scout_with_fan = false;
	if (iClass == TFClass_Scout) {
		new weapon = GetPlayerWeaponSlot(client, 0);
		new EntityLevel = GetEntProp(weapon, Prop_Send, "m_iEntityLevel");
		if (EntityLevel > 1)
			scout_with_fan = true;
	}
	for (new i = 0; i <= 2; i++){
		if(!(iClass == TFClass_Heavy && i == 1)){
			if (TFClass_MaxAmmo[iClass][i] != -1)
				SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + ((i+1)*4), TFClass_MaxAmmo[iClass][i]);
			if (i != 2 && TFClass_MaxClip[iClass][i] != -1 && !(scout_with_fan && i == 0))
				SetEntData(GetPlayerWeaponSlot(client, i), FindSendPropInfo("CTFWeaponBase", "m_iClip1"), TFClass_MaxClip[iClass][i]);
		}
	}
	
}

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
								} else //сообщаем об шибке
									SetFailState("Error in cfg file. Not enough parametrs on spawn <1> in arena <%s>",g_arenaName[g_arenaCount]);
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
								} else //сообщаем об шибке
									SetFailState("Error in cfg file. Not enough parametrs of spawn <2> in arena <%s>",g_arenaName[g_arenaCount]);
							} else //сообщаем об шибке
								SetFailState("Error in cfg file. Can't find spawn <2> on arena <%s>",g_arenaName[g_arenaCount]);
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

ShowPlayerHud(client){
	if (!client || !IsClientInGame(client)) 
		return;
	//HP
	SetHudTextParams(0.01, 0.80, HUDFADEOUTTIME, 255,255,255,255);
	ShowSyncHudText(client, hm_HP, "Health : %d", g_playerHP[client]);
	//Score
	new arena_index = g_playerOnArena[client];
	SetHudTextParams(0.01, 0.01, HUDFADEOUTTIME, 255,255,255,255);
	new String:report[128];
	
	if (g_arenaStatus[arena_index] != AS_IDLE){
		if (g_fragLimit)
			Format(report,sizeof(report),"Arena[%s] Frag Limit(%d)",g_arenaName[arena_index],g_fragLimit);
		else
			Format(report,sizeof(report),"Arena[%s] No Frag Limit",g_arenaName[arena_index]);
	} else
		Format(report,sizeof(report),"Arena[%s]",g_arenaName[arena_index]);
	if (g_arenaQueue[arena_index][SLOT_ONE])
		Format(report,sizeof(report),"%s\n%N : %d",report,g_arenaQueue[arena_index][SLOT_ONE],g_arenaScore[arena_index][SLOT_ONE]);
	if (g_arenaQueue[arena_index][SLOT_TWO])
		Format(report,sizeof(report),"%s\n%N : %d",report,g_arenaQueue[arena_index][SLOT_TWO],g_arenaScore[arena_index][SLOT_TWO]);
	ShowSyncHudText(client, hm_Score, "%s",report);
}

ShowSpecHudToClient(client){
	if (!client || !IsClientInGame(client) || g_playerSpecTarget[client] <=0) 
		return;
	new arena_index = g_playerOnArena[g_playerSpecTarget[client]];
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
	//new arena_index = g_playerOnArena[client];
	SetHudTextParams(0.01, 0.01, HUDFADEOUTTIME, 255,255,255,255);
	new String:report[128];
	
	if (g_arenaStatus[arena_index] != AS_IDLE){
		if (g_fragLimit)
			Format(report,sizeof(report),"Arena[%s] Frag Limit(%d)",g_arenaName[arena_index],g_fragLimit);
		else
			Format(report,sizeof(report),"Arena[%s] No Frag Limit",g_arenaName[arena_index]);
	} else
		Format(report,sizeof(report),"Arena[%s]",g_arenaName[arena_index]);
	if (g_arenaQueue[arena_index][SLOT_ONE])
		Format(report,sizeof(report),"%s\n%N : %d",report,g_arenaQueue[arena_index][SLOT_ONE],g_arenaScore[arena_index][SLOT_ONE]);
	if (g_arenaQueue[arena_index][SLOT_TWO])
		Format(report,sizeof(report),"%s\n%N : %d",report,g_arenaQueue[arena_index][SLOT_TWO],g_arenaScore[arena_index][SLOT_TWO]);
	ShowSyncHudText(client, hm_Score, "%s",report);
}

ShowSpecHudToArena(arena_index){
	if (!arena_index)
		return;
	for (new i=1;i<=MaxClients;i++){
		if (IsClientInGame(i) && GetClientTeam(i)==TEAM_SPEC && g_playerSpecTarget[i]>0 && g_playerOnArena[g_playerSpecTarget[i]]==arena_index)
			ShowSpecHudToClient(i);
	}
}

HidePlayerHud(client){
	if (!client || !IsClientInGame(client))
		return;
	ClearSyncHud(client,hm_Score);
	ClearSyncHud(client,hm_HP);
}