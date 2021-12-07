/*	
 *	============================================================================
 *	
 *	[TF2] Automatic Halloween Boss Spawner
 *	Alliedmodders: http://forums.alliedmods.net/member.php?u=87026
 *	Current Version: 2.1
 *
 *	This plugin is FREE and can be distributed to anyone.  
 *	If you have paid for this plugin, get your money back.
 *	
 *	Version Log:
 *	v.2.2 BETA - NOT RELEASED
 *	- Uses ExplodeString instead of creating my own way of seperating position strings
 *	- Added a map config to specify the position for each map
 *	- Added translation files
 *
 *	v.2.0 -  11/1/2013
 *	- Instead of looping through entities to find and kill off, it uses ent references (safer) ***
 *	- Fixed sm_boss_enabled not working properly ***
 *	- Precache missing files ***
 *	- Fixed changing time interval spawn not taking effect immediately ***
 *	- Fixed round restart spawning 2 bosses ***
 *	- Fixed boss sometimes not respawning ***
 *	- Fixed map change spawning 2 bosses ***
 *	- Code cleanup and bug fixes ***
 *	- Added support for tf2 beta ***
 *	- Added slay command (sm_slayboss)***
 *	- Added morecolors to chat ***
 *	- Added horseman auto-remove with cvar (sm_boss_horseman_remove) ***
 *	- Added force boss spawn command (sm_forceboss) ***
 *	- Added HUD time disply for next spawn ***
 *	- Added cvar to specify how many players before spawning (sm_boss_minplayers) ***
 *	- Removed useless codes ***
 *	- Removed IsValidClient checks ***
 *	
 *	1.0 - Released
 *	
 *	Description:
 *	Automatically spawns a rotation of halloween bosses
 *
 *	============================================================================
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>

#define PLUGIN_VERSION "2.1"
#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255

new Handle:Version = INVALID_HANDLE;
new Handle:cvarEnabled = INVALID_HANDLE;
new Handle:Position = INVALID_HANDLE;
new Handle:Mode = INVALID_HANDLE;
new Handle:Time = INVALID_HANDLE;
new Handle:MinPlayers = INVALID_HANDLE;
new Handle:Remove = INVALID_HANDLE;
new Handle:TimerHandle = INVALID_HANDLE;
new Handle:HorsemanHP = INVALID_HANDLE;
new Handle:MonoHP = INVALID_HANDLE;
new Handle:MerasHP = INVALID_HANDLE;
new Handle:HorsemanScale = INVALID_HANDLE;
new Handle:MonoScale = INVALID_HANDLE;
new Handle:MerasScale = INVALID_HANDLE;
new Handle:Horseman = INVALID_HANDLE;
new Handle:Monoculus = INVALID_HANDLE;
new Handle:Merasmus = INVALID_HANDLE;
new Handle:BossGlow = INVALID_HANDLE;
new Handle:BossSize = INVALID_HANDLE;
new Handle:HorsemanTimer = INVALID_HANDLE;
new Handle:CountDownTimer = INVALID_HANDLE;

new bool:timerVal;
new timeLeft;
new Enabled;
new bossEnt = -1;
new Float:g_pos[3];
new bool:lateLoaded;
new generator;
new bossCounter;
new g_trackEntity = -1;
new g_healthBar = -1;

public Plugin:myinfo =  {
	name = "[TF2] Automatic Halloween Boss Spawner",
	author = "Tak (chaosxk)",
	description = "Spawns a boss under a spawn time interval.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	lateLoaded = late;
	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta")) {
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart() {
	//Adjustable Cvars
	Version = CreateConVar("sm_boss_version", PLUGIN_VERSION, "Halloween Boss Spawner Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnabled = CreateConVar("sm_boss_enabled", "1", "Enable/Disable plugin, 1/0", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	Position = CreateConVar("sm_boss_position", "", "Spawn Position of the boss.");
	Mode = CreateConVar("sm_boss_mode", "1", "What spawn mode should boss spawn? (0 - Random ; 1 - Ordered from HHH - Monoculus - Merasmus");
	Time = CreateConVar("sm_boss_interval", "600", "How many seconds until the next boss spawns?");
	MinPlayers = CreateConVar("sm_boss_minplayers", "12", "How many players are needed before enabling auto-spawning?");
	Remove = CreateConVar("sm_boss_horseman_remove", "210", "How many seconds until the horseman leaves?");

	Horseman = CreateConVar("sm_boss_horseman", "1", "Allow horseman to spawn in rotation?)");
	Monoculus = CreateConVar("sm_boss_monoculus", "1", "Allow monoculus to spawn in rotation?)");
	Merasmus = CreateConVar("sm_boss_merasmus", "1", "Allow merasmus to spawn in rotation?)");

	HorsemanHP = CreateConVar("sm_boss_horsehp", "10000", "Base HP for horseman.");
	MonoHP = CreateConVar("sm_boss_monohp", "10000", "HBase HP for monoculus.");
	MerasHP = CreateConVar("sm_boss_merashp", "10000", "Base HP for merasmus.");

	HorsemanScale = CreateConVar("sm_boss_horsescale", "200", "How much additional health does horseman gain per player on server.");
	MonoScale = CreateConVar("sm_boss_monoscale", "200", "How much additional health does monoculus gain per player on server.");
	MerasScale = CreateConVar("sm_boss_merasscale", "200", "How much additional health does merasmus gain per player on server.");

	BossGlow = CreateConVar("sm_boss_glow", "0", "Should bosses glow through walls?");
	BossSize = CreateConVar("sm_boss_size", "1.0", "Size of boss when they spawn?");

	RegAdminCmd("sm_getcoords", GetCoords, ADMFLAG_GENERIC, "Get the Coordinates of your cursor.");
	RegAdminCmd("sm_forceboss", ForceSpawn, ADMFLAG_GENERIC, "Forces a boss to spawn");
	RegAdminCmd("sm_slayboss", SlayBoss, ADMFLAG_GENERIC, "Forces a boss to die");

	//Event Hooks
	HookEvent("teamplay_round_start", RoundStart);

	//Convar Hooks
	HookConVarChange(Version, cvarChange);
	HookConVarChange(cvarEnabled, cvarChange);
	HookConVarChange(Position, cvarChange);
	HookConVarChange(Horseman, cvarChange);
	HookConVarChange(Monoculus, cvarChange);
	HookConVarChange(Merasmus, cvarChange);
	HookConVarChange(BossGlow, cvarChange);
	HookConVarChange(BossSize, cvarChange);
	HookConVarChange(Time, cvarChange);

	SetUpCoordinateSystem();
	LoadTranslations("common.phrases");
	AutoExecConfig(true, "bossspawner");
}

public OnPluginEnd() {
	RemoveExistingBoss();
}

public OnConfigsExecuted() {
	Enabled = GetConVarBool(cvarEnabled);
	if(!Enabled) return;
	if(!lateLoaded) return;
	PrecacheHorseman();
	PrecacheMonoculus();
	PrecacheMerasmus();			
	ClearTimer(TimerHandle);
	TimerHandle = CreateTimer(GetConVarFloat(Time), spawnTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CPrintToChatAll("{unusual}[Boss Spawner] {default}The next boss will spawn in {unusual}%0.0f {unusual}seconds.", GetConVarFloat(Time));
	ClearTimer(CountDownTimer);
	CountDownTimer = CreateTimer(0.0, startCountDown, _, TIMER_FLAG_NO_MAPCHANGE);
	FindHealthBar();
	lateLoaded = false;
}

public OnMapStart() {
	if(!Enabled) return;
	PrecacheHorseman();
	PrecacheMonoculus();
	PrecacheMerasmus();
	FindHealthBar();
}

public OnMapEnd() {
	if(Enabled) {
		RemoveExistingBoss();
		if(bossCounter == 0) {
			ClearTimer(TimerHandle);
		}
	}
}

public OnClientPostAdminCheck(client) {
	new playerCounter = GetClientCount(true);
	new currentPlayer = GetConVarInt(MinPlayers);
	if(playerCounter == currentPlayer) {
		if(bossCounter == 0) {
			TimerHandle = CreateTimer(GetConVarFloat(Time), spawnTimer, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public OnClientDisconnect(client) {
	new playerCounter = GetClientCount(true);
	new currentPlayer = GetConVarInt(MinPlayers);
	if(playerCounter == currentPlayer) {
		RemoveExistingBoss();
		if(bossCounter == 0) {
			ClearTimer(TimerHandle);
		}
	}
}

public cvarChange(Handle:convar, String:oldValue[], String:newValue[]) {
	if(convar == Version) {
		SetConVarString(Version, PLUGIN_VERSION, false, false);
	}
	else if(convar == cvarEnabled) {
		Enabled = GetConVarBool(cvarEnabled);
		switch(Enabled) {
			case true: {
				if(bossCounter == 0) {
					TimerHandle = CreateTimer(GetConVarFloat(Time), spawnTimer, _, TIMER_FLAG_NO_MAPCHANGE);
					CPrintToChatAll("{unusual}[Boss Spawner] {default}The next boss will spawn in {unusual}%0.0f {unusual}seconds.", GetConVarFloat(Time));
					ClearTimer(CountDownTimer);
					CountDownTimer = CreateTimer(0.0, startCountDown, _, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			case false: {
				RemoveExistingBoss();
				if(bossCounter == 0) {
					ClearTimer(TimerHandle);
					ClearTimer(CountDownTimer);
				}
			}
		}
	}
	if(Enabled) {
		if(convar == Position) {
			SetUpCoordinateSystem();
			ResetTimer();
		}
		else if(convar == Horseman) {
			if(StringToInt(oldValue) == 0) {
				if(GetConVarInt(Horseman) == StringToInt(newValue) 
				&& GetConVarInt(Monoculus) == StringToInt(oldValue) 
				&& GetConVarInt(Merasmus) == StringToInt(oldValue)) {
					ResetTimer();
				}
			}
		}
		else if(convar == Monoculus) {
			if(StringToInt(oldValue) == 0) {
				if(GetConVarInt(Horseman) == StringToInt(oldValue) 
				&& GetConVarInt(Monoculus) == StringToInt(newValue) 
				&& GetConVarInt(Merasmus) == StringToInt(oldValue)) {
					ResetTimer();
				}
			}
		}
		else if(convar == Merasmus) {
			if(StringToInt(oldValue) == 0) {
				if(GetConVarInt(Horseman) == StringToInt(oldValue) 
				&& GetConVarInt(Monoculus) == StringToInt(oldValue) 
				&& GetConVarInt(Merasmus) == StringToInt(newValue)) {
					ResetTimer();
				}
			}
		}
		else if(convar == BossGlow) {
			SetGlow(StringToInt(newValue));
		}
		else if(convar == BossSize) {
			SetSize(StringToFloat(newValue));
		}
		else if(convar == Time) {
			timerVal = false;
			ResetTimer();
		}
	}
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	bossCounter = 0;
	if(!Enabled) return Plugin_Continue;
	ResetTimer();
	return Plugin_Continue;
}

public OnEntityDestroyed(entity) {
	if(Enabled) {
		if(IsValidEntity(entity) && entity > MaxClients) {
			decl String:classname[MAX_NAME_LENGTH];
			GetEntityClassname(entity, classname, sizeof(classname));
			if(entity == bossEnt) { //|| StrEqual(classname, "tf_zombie")
				bossEnt = -1;
				bossCounter--;
				if(bossCounter == 0) {
					TimerHandle = CreateTimer(GetConVarFloat(Time), spawnTimer, _, TIMER_FLAG_NO_MAPCHANGE);
					CPrintToChatAll("{unusual}[Boss Spawner] {default}The next boss will spawn in {unusual}%0.0f {unusual}seconds.", GetConVarFloat(Time));
					ClearTimer(CountDownTimer);
					CountDownTimer = CreateTimer(0.0, startCountDown, _, TIMER_FLAG_NO_MAPCHANGE);
					timerVal = false;
					ClearTimer(CountDownTimer);
					CountDownTimer = CreateTimer(0.0, startCountDown, _, TIMER_FLAG_NO_MAPCHANGE);
				}
				if(StrEqual(classname, "headless_hatman")) {
					ClearTimer(HorsemanTimer);
				}
			}
			if(entity == g_trackEntity) {
				g_trackEntity = FindEntityByClassname(-1, "merasmus");
				if (g_trackEntity == entity) {
					g_trackEntity = FindEntityByClassname(entity, "merasmus");
				}
					
				if (g_trackEntity > -1) {
					SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnBossDamaged);
				}
				UpdateBossHealth(g_trackEntity);
			}
		}
	}
}

public Action:spawnTimer(Handle:hTimer) {
	if(!Enabled) return Plugin_Handled;
	static String:compare[32];
	GetConVarString(Position, compare, sizeof(compare));
	if(!(StrEqual(compare, "", false))) {
		SpawnBoss();
	}
	else {
		LogError("[Boss Spawner] Error: Position is not yet set.");
	}
	TimerHandle = INVALID_HANDLE;
	return Plugin_Handled;
}

public Action:ForceSpawn(client, args) {
	if(!Enabled) return Plugin_Handled;
	if(bossCounter == 0) {
		new String:compare[32];
		GetConVarString(Position, compare, sizeof(compare));
		if(!(StrEqual(compare, "", false))) {
			ClearTimer(TimerHandle);
			SpawnBoss();
		}
		else {
			LogError("[Boss Spawner] Error: Position is not yet set.");
			CReplyToCommand(client, "{unusual}[Boss Spawner] {red}Error: {default}Position is not yet set.");
		}
	}
	else {
		CReplyToCommand(client, "{unusual}[Boss Spawner] {default}A boss is already active!");
	}
	return Plugin_Handled;
}

public Action:GetCoords(client, args) {
	if(!Enabled) return Plugin_Handled;
	if(!IsClientInGame(client) || !IsPlayerAlive(client)) {
		ReplyToCommand(client, "Error: You must be alive or in game to use this command!");
		return Plugin_Handled;
	}
	new Float:l_pos[3];
	GetClientAbsOrigin(client, l_pos);
	CReplyToCommand(client, "{unusual}[Boss Spawner] {default}Coords: %0.0f,%0.0f,%0.0f\n{unusual}[Boss Spawner] {default}Use those coordinates for sm_boss_position", l_pos[0], l_pos[1], l_pos[2]);
	return Plugin_Handled;
}

public Action:SlayBoss(client, args) {
	if(!Enabled) return Plugin_Handled;
	if(bossEnt != -1) {
		decl String:classname[MAX_NAME_LENGTH];
		GetEntityClassname(bossEnt, classname, sizeof(classname));
		if(StrEqual(classname, "headless_hatman")) {
			CPrintToChatAll("{unusual}[Boss Spawner] {default}Horseless Headless Horsemann has been slayed!");
		}
		else if(StrEqual(classname, "eyeball_boss")) {
			CPrintToChatAll("{unusual}[Boss Spawner] {default}Monoculus has been slayed!");
		}
		else if(StrEqual(classname, "merasmus")) {
			CPrintToChatAll("{unusual}[Boss Spawner] {default}Merasmus has been slayed!");
		}
		AcceptEntityInput(bossEnt, "Kill");
	}
	else {
		CReplyToCommand(client, "{unusual}[Boss Spawner] {default}No active boss to slay.");
	}
	//OnEntityDestroyed(bossEnt);
	return Plugin_Handled;
}

//random or ordered spawn manager
SpawnBoss() {
	new mode = GetConVarInt(Mode);
	new bool:horseVal = GetConVarBool(Horseman);
	new bool:monoVal = GetConVarBool(Monoculus);
	new bool:merasVal = GetConVarBool(Merasmus);
	if(mode == 0) {
		generator = GetRandomInt(0,2);
	}
	while(generator == 0 && !horseVal || generator == 1 && !monoVal || generator == 2 && !merasVal) {
		switch(mode) {
			case 0: generator = GetRandomInt(0,2);
			case 1: {
				generator++;
				if(generator == 3) {
					generator = 0;
				}
			}
		}
		if(!horseVal  && !monoVal && !merasVal) {
			generator = 3;
		}
	}
	switch(generator) {
		case 0: {
			spawnHorseman();
			switch(mode) {
				case 0: generator = 0;
				case 1: generator++;
			}
		}
		case 1: {
			spawnMonoculus();
			switch(mode) {
				case 0: generator = 0;
				case 1: generator++;
			}
		}
		case 2: {
			spawnMerasmus();
			switch(mode) {
				case 0: generator = 0;
				case 1: generator++;
			}
		}
		case 3: {
			generator = 0;
			SpawnBoss();
		}
	}
	ClearTimer(CountDownTimer);
}

public Action:RemoveHorseman(Handle:hTimer) {
	AcceptEntityInput(bossEnt, "Kill");
	CPrintToChatAll("{unusual}[Boss Spawner] {default}Horseless Headless Horsemann has left because of boredom.");
	return Plugin_Handled;
}

spawnHorseman() {
	new entity = CreateEntityByName("headless_hatman");
	if(IsValidEntity(entity)) {
		new playerCounter = GetClientCount(true);
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Data, "m_iHealth", (GetConVarInt(HorsemanHP) + GetConVarInt(HorsemanScale)*playerCounter)*4);
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", (GetConVarInt(HorsemanHP) + GetConVarInt(HorsemanScale)*playerCounter)*4);
		bossCounter++;
		bossEnt = entity;
		SetGlow(GetConVarInt(BossGlow));
		SetSize(GetConVarFloat(BossSize));
		HorsemanTimer = CreateTimer(GetConVarFloat(Remove), RemoveHorseman);
	}
}

spawnMonoculus() {
	new entity = CreateEntityByName("eyeball_boss");
	if(IsValidEntity(entity)) {
		new playerCounter = GetClientCount(true);
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Data, "m_iTeamNum", 5);
		SetEntProp(entity, Prop_Data, "m_iHealth", GetConVarInt(MonoHP) + GetConVarInt(MonoScale)*playerCounter);
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", GetConVarInt(MonoHP) + GetConVarInt(MonoScale)*playerCounter);
		decl String:targetname[32];
		GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
		bossCounter++;
		bossEnt = entity;
		SetGlow(GetConVarInt(BossGlow));
		SetSize(GetConVarFloat(BossSize));
	}
}

spawnMerasmus() {
	new entity = CreateEntityByName("merasmus");
	if(IsValidEntity(entity)) {
		new playerCounter = GetClientCount(true);
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Data, "m_iHealth", (GetConVarInt(MerasHP) + GetConVarInt(MerasScale)*playerCounter)*4);
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", (GetConVarInt(MerasHP) + GetConVarInt(MerasScale)*playerCounter)*4);
		bossCounter++;
		bossEnt = entity;
		SetGlow(GetConVarInt(BossGlow));
		SetSize(GetConVarFloat(BossSize));
	}
}

/*spawnMerasmus() { // don't work!
	new entity = CreateEntityByName("tf_zombie_spawner");
	if(IsValidEntity(entity)) {
		DispatchKeyValue(entity, "targetname", "SkeletonKing");
		DispatchKeyValue(entity, "origin", "X Y Z");
		DispatchKeyValue(entity, "angles", "0 0 0");
		DispatchKeyValue(entity, "zombie_lifetime", "0");
		DispatchKeyValue(entity, "max_zombies", "1");
		DispatchKeyValue(entity, "infinite_zombies", "1");
		DispatchKeyValue(entity, "zombie_type", "0");
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "Enable");
		bossCounter++;
		bossEnt = entity;
		AcceptEntityInput(entity, "kill");
	}
}*/

SetGlow(value) {
	if(IsValidEntity(bossEnt)) {
		SetEntProp(bossEnt, Prop_Send, "m_bGlowEnabled", value);
	}
}

SetSize(Float:value) {
	if(IsValidEntity(bossEnt)) {
		SetEntPropFloat(bossEnt, Prop_Send, "m_flModelScale", value);
	}
}

ResetTimer() {
	if(bossCounter == 0) {
		ClearTimer(TimerHandle);
		TimerHandle = CreateTimer(GetConVarFloat(Time), spawnTimer, _, TIMER_FLAG_NO_MAPCHANGE);
		CPrintToChatAll("{unusual}[Boss Spawner] {default}The next boss will spawn in {unusual}%0.0f {unusual}seconds.", GetConVarFloat(Time));
		ClearTimer(CountDownTimer);
		CountDownTimer = CreateTimer(0.0, startCountDown, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
new Handle:hudText = INVALID_HANDLE;
public Action:startCountDown(Handle:hTimer) {
	if(!Enabled) return Plugin_Stop;
	if(hudText != INVALID_HANDLE) {
		for(new i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i))
				ClearSyncHud(i, hudText);
		}
		CloseHandle(hudText);
	}
	hudText = CreateHudSynchronizer();
	switch(timerVal) {
		case true: {
			timeLeft--;
			if(timeLeft < 0) {
				timeLeft = 0;
				CountDownTimer = INVALID_HANDLE;
				if(hudText != INVALID_HANDLE) {
					CloseHandle(hudText);
					hudText = INVALID_HANDLE;
				}
				timerVal = false;
				return Plugin_Stop;
			}
			CountDownTimer = CreateTimer(1.0, startCountDown, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		case false: {
			timerVal = true;
			timeLeft = GetConVarInt(Time);
			CountDownTimer = CreateTimer(1.0, startCountDown, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	//Set your HUD Parameters here.
	SetHudTextParams(0.05, 0.05, 1.0, 255, 255, 255, 255);
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i))
			ShowSyncHudText(i, hudText, "Boss: %d seconds", timeLeft);
	}
	return Plugin_Handled;
}

//remove existing boss that has the same targetname so that it doesn't cause an extra spawn point
RemoveExistingBoss() {
	if(IsValidEntity(bossEnt)) {
		AcceptEntityInput(bossEnt, "kill");
	}
}

//Iterates through the convar to seperate the positions and saves it to the global varaiable
SetUpCoordinateSystem() {
	new String:string[64] = "";
	new String:complete[64] = "";
	new counter, n = 0;
	GetConVarString(Position, string, sizeof(string));
	//for loop iterator
	for(new i = 0; i < strlen(string); i++) {
		if(string[i] != ',') {
			complete[n++] += string[i];	
		}
		else if(counter != 2) {
			g_pos[counter++] = StringToFloat(complete);
			new String:temp[64];
			complete = temp;
			n = 0;
		}
		if(i == strlen(string)-1) {
			g_pos[counter++] = StringToFloat(complete);
		}
	}
	//Testing this function
	//ReplyToCommand(client, "[SM] Value is X = %0.0f, Y = %0.0f, Z = %0.0f", g_pos[0], g_pos[1], g_pos[2]);
}

FindHealthBar() {
	g_healthBar = FindEntityByClassname(-1, HEALTHBAR_CLASS);
	if(g_healthBar == -1) {
		g_healthBar = CreateEntityByName(HEALTHBAR_CLASS);
		if(g_healthBar != -1) {
			DispatchSpawn(g_healthBar);
		}
	}
}

public OnEntityCreated(entity, const String:classname[]) {
	if(StrEqual(classname, HEALTHBAR_CLASS)) {
		g_healthBar = entity;
	}
	else if(g_trackEntity == -1 && (StrEqual(classname, "merasmus") 
	|| StrEqual(classname, "headless_hatman"))) {
		g_trackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnBossDamaged);
	}
}

public OnBossDamaged(victim, attacker, inflictor, Float:damage, damagetype) {
	UpdateBossHealth(victim);
	UpdateDeathEvent(victim);
}

public UpdateDeathEvent(entity) {
	if(IsValidEntity(entity)) {
		new maxHP = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		new HP = GetEntProp(entity, Prop_Data, "m_iHealth");
		if(HP <= (maxHP * 0.75)) {
			SetEntProp(entity, Prop_Data, "m_iHealth", 0);
			if(HP <= -1) {
				SetEntProp(entity, Prop_Data, "m_takedamage", 0);
			}
		}
	}
}

public UpdateBossHealth(entity) {
	if(g_healthBar == -1) {
		return;
	}
	new percentage;
	if(IsValidEntity(entity)) {
		new maxHP = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		new HP = GetEntProp(entity, Prop_Data, "m_iHealth");
		if(HP <= 0) {
			percentage = 0;
		}
		else {
			percentage = RoundToCeil((float(HP) / float(maxHP / 4)) * HEALTHBAR_MAX);
		}
	}
	else {
		percentage = 0;
	}	
	SetEntProp(g_healthBar, Prop_Send, HEALTHBAR_PROPERTY, percentage);
}

stock ClearTimer(&Handle:timer) {  
	if(timer != INVALID_HANDLE) {  
		KillTimer(timer);  
	}  
	timer = INVALID_HANDLE;  
}  

//Precaches all models/sounds for the bosses --------------------------------------------------------------------------------------------------------------
PrecacheHorseman() {
	PrecacheModel("models/bots/headless_hatman.mdl", true); 
	PrecacheModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl", true);
	PrecacheSound("ui/halloween_boss_summon_rumble.wav", true);
	PrecacheSound("vo/halloween_boss/knight_alert.wav", true);
	PrecacheSound("vo/halloween_boss/knight_alert01.wav", true);
	PrecacheSound("vo/halloween_boss/knight_alert02.wav", true);
	PrecacheSound("vo/halloween_boss/knight_attack01.wav", true);
	PrecacheSound("vo/halloween_boss/knight_attack02.wav", true);
	PrecacheSound("vo/halloween_boss/knight_attack03.wav", true);
	PrecacheSound("vo/halloween_boss/knight_attack04.wav", true);
	PrecacheSound("vo/halloween_boss/knight_death01.wav", true);
	PrecacheSound("vo/halloween_boss/knight_death02.wav", true);
	PrecacheSound("vo/halloween_boss/knight_dying.wav", true);
	PrecacheSound("vo/halloween_boss/knight_laugh01.wav", true);
	PrecacheSound("vo/halloween_boss/knight_laugh02.wav", true);
	PrecacheSound("vo/halloween_boss/knight_laugh03.wav", true);
	PrecacheSound("vo/halloween_boss/knight_laugh04.wav", true);
	PrecacheSound("vo/halloween_boss/knight_pain01.wav", true);
	PrecacheSound("vo/halloween_boss/knight_pain02.wav", true);
	PrecacheSound("vo/halloween_boss/knight_pain03.wav", true);
	PrecacheSound("vo/halloween_boss/knight_spawn.wav", true);
	PrecacheSound("weapons/halloween_boss/knight_axe_hit.wav", true);
	PrecacheSound("weapons/halloween_boss/knight_axe_miss.wav", true);
}

PrecacheMonoculus() {
	PrecacheModel("models/props_halloween/halloween_demoeye.mdl", true);
	PrecacheModel("models/props_halloween/eyeball_projectile.mdl", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_biglaugh01.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_boss_pain01.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_laugh01.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_laugh02.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_laugh03.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_mad01.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_mad02.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_mad03.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_teleport01.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball01.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball02.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball03.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball04.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball05.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball06.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball07.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball08.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball09.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball10.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball11.wav", true);
	PrecacheSound("ui/halloween_boss_summon_rumble.wav", true);
	PrecacheSound("ui/halloween_boss_chosen_it.wav", true);
	PrecacheSound("ui/halloween_boss_defeated_fx.wav", true);
	PrecacheSound("ui/halloween_boss_defeated.wav", true);
	PrecacheSound("ui/halloween_boss_player_becomes_it.wav", true);
	PrecacheSound("ui/halloween_boss_summoned_fx.wav", true);
	PrecacheSound("ui/halloween_boss_summoned.wav", true);
	PrecacheSound("ui/halloween_boss_tagged_other_it.wav", true);
	PrecacheSound("ui/halloween_boss_escape.wav", true);
	PrecacheSound("ui/halloween_boss_escape_sixty.wav", true);
	PrecacheSound("ui/halloween_boss_escape_ten.wav", true);
	PrecacheSound("ui/halloween_boss_tagged_other_it.wav", true);
}

PrecacheMerasmus() {
	PrecacheModel("models/bots/merasmus/merasmus.mdl", true);
	PrecacheModel("models/prop_lakeside_event/bomb_temp.mdl", true);
	PrecacheModel("models/prop_lakeside_event/bomb_temp_hat.mdl", true);
	
	for(new i = 1; i <= 17; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_appears0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_appears%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 11; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_attacks0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_attacks%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 54; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_headbomb0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_headbomb%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 33; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_held_up0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_held_up%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 2; i <= 4; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_island0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 3; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_skullhat0%d.wav", i);
		PrecacheSound(iString, true);
	}

	for(new i = 1; i <= 2; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_combat_idle0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 12; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_defeated0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_defeated%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 9; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_found0%d.wav", i);
		PrecacheSound(iString, true);
	}

	for(new i = 3; i <= 6; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_grenades0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 26; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_headbomb_hit0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_headbomb_hit%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 19; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_heal10%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_heal1%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 49; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_idles0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_idles%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 16; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_leaving0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_leaving%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 5; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_pain0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 4; i <= 8; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_ranged_attack0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 2; i <= 13; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_staff_magic0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_staff_magic%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles_demo01.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire06.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire07.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire23.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire29.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magicwords11.wav", true);
	
	PrecacheSound("misc/halloween/merasmus_appear.wav", true);
	PrecacheSound("misc/halloween/merasmus_death.wav", true);
	PrecacheSound("misc/halloween/merasmus_disappear.wav", true);
	PrecacheSound("misc/halloween/merasmus_float.wav", true);
	PrecacheSound("misc/halloween/merasmus_hiding_explode.wav", true);
	PrecacheSound("misc/halloween/merasmus_spell.wav", true);
	PrecacheSound("misc/halloween/merasmus_stun.wav", true);
}