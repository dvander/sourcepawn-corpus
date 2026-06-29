/************************************************************************
*************************************************************************
Waiting For Players
Description:
	Friendlyfire during waiting for players
*************************************************************************
*************************************************************************
*/

// ========================================================================
// INCLUDES & PRAGMAS
// ========================================================================
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>

#define PL_VERSION "2.0.0"
#define MAX_PARTICLES 3

// ========================================================================
// GLOBAL VARIABLES
// ========================================================================
bool g_bPreGame;
bool g_bBlockLog;
int g_iTimeLeft;

int g_iFrags[MAXPLAYERS + 1];
int g_iMenuSettings[MAXPLAYERS + 1];
int g_iParticles[MAXPLAYERS + 1][MAX_PARTICLES];
float g_fLastBumpTime[MAXPLAYERS + 1];

Handle g_hSizeTimers[MAXPLAYERS + 1];
Handle g_hFireworksTimers[MAXPLAYERS + 1];

ConVar g_hVarTime;
ConVar g_hVarStats;
ConVar g_hVarDoors;
ConVar g_hVarEffect;
ConVar g_hVarVisualGagAll;
ConVar g_hVarVisualGagChaos;
ConVar g_hVarMelee;
ConVar g_hVarDisableLockers;
ConVar g_hVarBumperDamage;
Cookie g_hCookie_ClientMenu;

// ========================================================================
// ENUMS
// ========================================================================
enum e_Door { dontTouch = 0, open, close, randomDoor }

enum e_Effect 
{ 
	effectNone = 0, 
	effectMiniCrit, 
	effectFullCrit, 
	effectSpeed, 
	effectMegaHeal, 
	effectDefense, 
	effectMarkedForDeath, 
	effectRandom 
}

enum e_VisualGag 
{ 
	gagHealRadius = 0, 
	gagTeleportGlow, 
	gagBurning, 
	gagDisguising, 
	gagHearts, 
	gagBalloonHead, 
	gagBumperCar, 
	gagFireworks, 
	gagFlies, 
	gagGhosts, 
	gagConfetti, 
	gagPlanets, 
	gagSunbeams, 
	gagSizeShifter,
	gagRandom 
}

enum e_Melee { allowAll = 0, meleeOnly, randomMelee }

e_Effect g_Effect;
e_VisualGag g_VisualGag;
bool g_bMelee;

public Plugin myinfo = 
{
	name = "[TF2] Pregame Slaughter",
	author = "GOERGE",
	description = "Funtimes for pregame round",
	version = PL_VERSION,
	url = "https://github.com/BrutalGoerge/tf2tmng"
};

// ========================================================================
// CONNECTION & DISCONNECTION HOOKS
// ========================================================================
public void OnClientConnected(int client)
{
	g_iFrags[client] = 0;
	g_hSizeTimers[client] = null;
	g_hFireworksTimers[client] = null;
	g_fLastBumpTime[client] = 0.0;
	
	for (int i = 0; i < MAX_PARTICLES; i++)
	{
		g_iParticles[client][i] = INVALID_ENT_REFERENCE;
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_StartTouch, OnPlayerTouch);
}

public void OnClientDisconnect(int client)
{
	KillSizeTimer(client);
	KillFireworksTimer(client);
	KillParticles(client);
}

// ========================================================================
// PLUGIN STARTUP
// ========================================================================
public void OnPluginStart()
{
	LoadTranslations("tf2_pregame.phrases");

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	AddGameLogHook(LogHook); 

	g_hVarTime = CreateConVar("tf2_pregame_timelimit", "50", "Time in seconds that pregame lasts", FCVAR_PLUGIN, true, 10.0, false);
	g_hVarStats = CreateConVar("tf2_pregame_stats", "1", "Track the number of kills people get during pregame", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hVarDoors = CreateConVar("tf2_pregame_doors", "3", "0=Do not mess with doors, 1=open all doors, 2=close and lock all doors, 3=random.", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_hVarEffect = CreateConVar("tf2_pregame_effect", "7", "0=None, 1=MiniCrits, 2=FullCrits, 3=WhipSpeed, 4=MegaHeal, 5=Battalions, 6=MarkedForDeath, 7=Random", FCVAR_PLUGIN, true, 0.0, true, 7.0);
	g_hVarVisualGagAll = CreateConVar("tf2_pregame_visual_gag_all", "0", "0=HealRadius, 1=TeleportGlow, 2=VisualFire, 3=Disguising, 4=Hearts, 5=BalloonHead, 6=HalloweenKart, 7=Fireworks, 8=Flies, 9=Ghosts, 10=Confetti, 11=Planets, 12=Sunbeams, 13=SizeShifter, 14=Random", FCVAR_PLUGIN, true, 0.0, true, 14.0);
	g_hVarVisualGagChaos = CreateConVar("tf2_pregame_visual_gag_chaos", "0", "1 = Every player gets a random visual gag on spawn (Overrides tf2_pregame_visual_gag_all)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hVarMelee	= CreateConVar("tf2_pregame_melee", "2", "0=allow all weapons, 1=Melee only, 2=random", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hVarDisableLockers = CreateConVar("tf2_pregame_disable_lockers", "1", "1 = Disable resupply lockers during pregame, 0 = Leave them alone", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hVarBumperDamage = CreateConVar("tf2_pregame_bumper_damage", "25", "Base damage dealt when bumper cars collide (0 to disable)", FCVAR_PLUGIN, true, 0.0);
	
	CreateConVar("sm_pregame_slaughter_version", PL_VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hCookie_ClientMenu = new Cookie("tf2_pregame_menu", "Enables the winners menu on a per-client basis", CookieAccess_Public);
	SetCookieMenuItem(CookieMenu_Handler, g_hCookie_ClientMenu, "TF2 Pregame");
	
	AutoExecConfig();	
}

// ========================================================================
// MAP & CONFIG EXECUTION
// ========================================================================
public void OnConfigsExecuted()
{
	ConVar hWaitTime = FindConVar("mp_waitingforplayers_time");
	if (hWaitTime != null) hWaitTime.IntValue = g_hVarTime.IntValue;

	PrecacheGeneric("particles/item_fx.pcf", true);
	PrecacheGeneric("particles/burningplayer.pcf", true);
	
	PrecacheSound("weapons/bumper_car_jump_land.wav", true);
	PrecacheSound(")weapons/bumper_car_jump_land.wav", true);
	PrecacheSound("weapons/bumper_car_hit1.wav", true);
	PrecacheSound(")weapons/bumper_car_hit1.wav", true);
	PrecacheSound("weapons/bumper_car_hit2.wav", true);
	PrecacheSound(")weapons/bumper_car_hit2.wav", true);
	PrecacheSound("weapons/bumper_car_hit3.wav", true);
	PrecacheSound(")weapons/bumper_car_hit3.wav", true);
	PrecacheSound("weapons/bumper_car_hit4.wav", true);
	PrecacheSound(")weapons/bumper_car_hit4.wav", true);
	PrecacheSound("weapons/bumper_car_hit5.wav", true);
	PrecacheSound(")weapons/bumper_car_hit5.wav", true);
	PrecacheSound("weapons/bumper_car_hit6.wav", true);
	PrecacheSound(")weapons/bumper_car_hit6.wav", true);
	PrecacheSound("weapons/bumper_car_hit7.wav", true);
	PrecacheSound(")weapons/bumper_car_hit7.wav", true);
	PrecacheSound("weapons/bumper_car_hit8.wav", true);
	PrecacheSound(")weapons/bumper_car_hit8.wav", true);
	PrecacheSound("weapons/bumper_car_hit_hard.wav", true);
	PrecacheSound(")weapons/bumper_car_hit_hard.wav", true);
	PrecacheSound("weapons/bumper_car_jump.wav", true);
	PrecacheSound(")weapons/bumper_car_jump.wav", true);
	PrecacheSound("weapons/bumper_car_decelerate.wav", true);
	PrecacheSound(")weapons/bumper_car_decelerate.wav", true);
	PrecacheSound("weapons/bumper_car_accelerate.wav", true);
	PrecacheSound(")weapons/bumper_car_accelerate.wav", true);
	PrecacheSound("weapons/bumper_car_spawn.wav", true);
	PrecacheSound(")weapons/bumper_car_spawn.wav", true);
	// Boost Sounds
	PrecacheSound("weapons/bumper_car_speed_boost_start.wav", true);
	PrecacheSound(")weapons/bumper_car_speed_boost_start.wav", true);
	PrecacheSound("weapons/bumper_car_speed_boost_stop.wav", true);
	PrecacheSound(")weapons/bumper_car_speed_boost_stop.wav", true);
}

public void OnMapStart()
{
	StripNotify("mp_friendlyfire");
	StripNotify("sv_tags");
	StripNotify("tf_avoidteammates");
}

// ========================================================================
// CLIENT SETTINGS (COOKIES)
// ========================================================================
public void OnClientCookiesCached(int client)
{
	if (IsClientConnected(client) && !IsFakeClient(client))
	{
		char sCookieSetting[3];
		g_hCookie_ClientMenu.Get(client, sCookieSetting, sizeof(sCookieSetting));
		g_iMenuSettings[client] = StringToInt(sCookieSetting);
	}
}

public void CookieMenu_Handler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action != CookieMenuAction_DisplayOption)
	{
		Menu hMenu = new Menu(Menu_CookieSettings);
		hMenu.SetTitle("TF2 Pregame Winner Menu (Current Setting)");
		if (g_iMenuSettings[client] != -1) hMenu.AddItem("enable", "Enabled/Disable (Enabled)");		
		else hMenu.AddItem("enable", "Enabled/Disable (Disabled)");
			
		hMenu.ExitBackButton = true;
		hMenu.Display(client, MENU_TIME_FOREVER);
	}
}

public int Menu_CookieSettings(Menu menu, MenuAction action, int param1, int param2)
{
	int client = param1;
	if (action == MenuAction_Select) 
	{
		char sSelection[24];
		menu.GetItem(param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "enable", false))
		{
			Menu hMenu = new Menu(Menu_CookieSettingsEnable);
			hMenu.SetTitle("Enable/Disable Winners Menu");
			if (g_iMenuSettings[client] != -1)
			{
				hMenu.AddItem("enable", "Enable (Set)");
				hMenu.AddItem("disable", "Disable");
			}
			else
			{
				hMenu.AddItem("enable", "Enabled");
				hMenu.AddItem("disable", "Disable (Set)");
			}
			
			hMenu.ExitBackButton = true;
			hMenu.Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack) ShowCookieMenu(client);
	else if (action == MenuAction_End) delete menu;
	return 0;
}

public int Menu_CookieSettingsEnable(Menu menu, MenuAction action, int param1, int param2)
{
	int client = param1;
	if (action == MenuAction_Select) 
	{
		char sSelection[24];
		menu.GetItem(param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "enable", false))
		{
			g_hCookie_ClientMenu.Set(client, "1");
			g_iMenuSettings[client] = 1;
			PrintToChat(client, "[SM] Pregame winner menu ENABLED");
		}
		else
		{
			g_hCookie_ClientMenu.Set(client, "-1");
			g_iMenuSettings[client] = -1;
			PrintToChat(client, "[SM] Pregame winner menu DISABLED");
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack) ShowCookieMenu(client);
	else if (action == MenuAction_End) delete menu;
	return 0;
}

// ========================================================================
// GAME EVENTS
// ========================================================================
public Action Event_PlayerDeathPre(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bPreGame) g_bBlockLog = true;
	return Plugin_Continue;
}

public Action LogHook(const char[] message)
{
	if (g_bBlockLog) return Plugin_Handled;
	return Plugin_Continue;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	g_bBlockLog = false;
	
	int iUserId = event.GetInt("userid");
	int client = GetClientOfUserId(iUserId);
	
	if (client)
	{
		KillSizeTimer(client);
		KillFireworksTimer(client);
		KillParticles(client);
	}
	
	if (g_bPreGame)
	{
		int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
		
		if (iAttacker && g_hVarStats.BoolValue)
		{
			g_iFrags[iAttacker]++;
			if (!IsFakeClient(iAttacker))
			{
				PrintHintText(iAttacker, "Kills: %i", g_iFrags[iAttacker]);
			}
		}
		CreateTimer(0.3, Timer_Spawn, iUserId);
	}
}

public Action Timer_Spawn(Handle timer, any userid)
{
	if (g_bPreGame)
	{
		int client = GetClientOfUserId(userid);
		if (client) TF2_RespawnPlayer(client);
	}
	return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bPreGame)
	{
		CreateTimer(0.1, Timer_Cond, event.GetInt("userid"));
	}
}

// ========================================================================
// COLLISION DETECTOR (BUMPER CAR RAMMING)
// ========================================================================
public Action OnPlayerTouch(int client, int other)
{
	if (!g_bPreGame) return Plugin_Continue;
	if (client < 1 || client > MaxClients || other < 1 || other > MaxClients) return Plugin_Continue;
	if (!IsPlayerAlive(client) || !IsPlayerAlive(other)) return Plugin_Continue;

	float baseDamage = g_hVarBumperDamage.FloatValue;
	if (baseDamage <= 0.0) return Plugin_Continue;

	bool clientInCar = TF2_IsPlayerInCondition(client, TFCond_HalloweenKart);
	bool otherInCar = TF2_IsPlayerInCondition(other, TFCond_HalloweenKart);

	if (!clientInCar) return Plugin_Continue;

	float clientVel[3], otherVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", clientVel);
	GetEntPropVector(other, Prop_Data, "m_vecVelocity", otherVel);

	float clientSpeed = GetVectorLength(clientVel);
	float otherSpeed = GetVectorLength(otherVel);

	if (otherInCar && clientSpeed <= otherSpeed) return Plugin_Continue;

	float currentTime = GetGameTime();
	
	if (currentTime - g_fLastBumpTime[client] > 0.5)
	{
		g_fLastBumpTime[client] = currentTime;
		
		float speedMult = clientSpeed / 300.0;
		if (speedMult < 1.0) speedMult = 1.0; 
		
		float finalDamage = baseDamage * speedMult;
		SDKHooks_TakeDamage(other, client, client, finalDamage, DMG_VEHICLE | DMG_CRUSH);
	}
	
	return Plugin_Continue;
}

// ========================================================================
// PREGAME CONDITION & EFFECT HANDLERS
// ========================================================================
public Action Timer_Cond(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsPlayerAlive(client))
	{
		if (g_bPreGame)
		{
			if (g_bMelee) RemoveWeapons(client);
			else RemoveFlameMedi(client);
		}
		CreateTimer(0.1, Timer_SetCond, GetClientUserId(client));
	}
	return Plugin_Handled;
}

public Action Timer_SetCond(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (g_bPreGame && client && IsPlayerAlive(client))
	{
		KillParticles(client);
		KillSizeTimer(client);
		KillFireworksTimer(client);
		
		e_VisualGag currentGag = g_VisualGag;
		
		if (g_hVarVisualGagChaos.BoolValue)
		{
			currentGag = view_as<e_VisualGag>(GetRandomInt(0, 13));
		}
		
		switch (currentGag)
		{
			case gagHealRadius: 	TF2_AddCondition(client, TFCond_InHealRadius, -1.0);
			case gagTeleportGlow: 	TF2_AddCondition(client, TFCond_TeleportedGlow, -1.0);
			case gagDisguising: 	TF2_AddCondition(client, TFCond_Disguising, -1.0);
			case gagBalloonHead: 	TF2_AddCondition(client, TFCond_BalloonHead, -1.0);
			case gagBumperCar: 		TF2_AddCondition(client, TFCond_HalloweenKart, -1.0);
			case gagBurning:
			{
				if (GetClientTeam(client) == 3) AttachParticle(client, "burningplayer_blue", "", 0);
				else AttachParticle(client, "burningplayer_red", "", 0);
			}
			case gagHearts: 		
			{
				AttachParticle(client, "superrare_circling_heart", "head", 0);
				AttachParticle(client, "superrare_circling_heart", "flag", 1);
				AttachParticle(client, "superrare_circling_heart", "foot_L", 2);
			}
			case gagFireworks: 		StartFireworksTimer(client);
			case gagFlies: 			AttachParticle(client, "superrare_flies", "head", 0);
			case gagGhosts: 		AttachParticle(client, "superrare_ghosts", "head", 0);
			case gagConfetti: 		AttachParticle(client, "superrare_confetti_green", "head", 0);
			case gagPlanets: 		AttachParticle(client, "superrare_orbit_planets", "head", 0);
			case gagSunbeams: 		AttachParticle(client, "superrare_beams1", "head", 0);
			case gagSizeShifter:	StartSizeTimer(client);
		}
		
		switch (g_Effect)
		{
			case effectMiniCrit: 		TF2_AddCondition(client, TFCond_Buffed, -1.0);
			case effectFullCrit: 		TF2_AddCondition(client, TFCond_Kritzkrieged, -1.0);
			case effectSpeed: 			TF2_AddCondition(client, TFCond_SpeedBuffAlly, -1.0);
			case effectMegaHeal: 		TF2_AddCondition(client, TFCond_MegaHeal, -1.0);
			case effectDefense: 		TF2_AddCondition(client, TFCond_DefenseBuffed, -1.0);
			case effectMarkedForDeath: 	TF2_AddCondition(client, TFCond_MarkedForDeath, -1.0);
		}
	}
	return Plugin_Handled;
}

// ========================================================================
// PARTICLE MANAGERS
// ========================================================================
stock void AttachParticle(int client, const char[] effectName, const char[] attachPoint = "", int slot)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		float pos[3];
		GetClientAbsOrigin(client, pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		
		char targetName[64];
		Format(targetName, sizeof(targetName), "pregame_target_%d_%d", client, slot);
		DispatchKeyValue(client, "targetname", targetName);
		
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", client, particle, 0);
		
		if (attachPoint[0] != '\0')
		{
			SetVariantString(attachPoint);
			AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		}
		
		AcceptEntityInput(particle, "Start");
		g_iParticles[client][slot] = EntIndexToEntRef(particle);
	}
}

stock void KillParticles(int client)
{
	for (int i = 0; i < MAX_PARTICLES; i++)
	{
		if (g_iParticles[client][i] != INVALID_ENT_REFERENCE)
		{
			int entity = EntRefToEntIndex(g_iParticles[client][i]);
			if (entity > MaxClients && IsValidEntity(entity))
			{
				AcceptEntityInput(entity, "ClearParent");
				float hidePos[3] = { 0.0, 0.0, -10000.0 };
				TeleportEntity(entity, hidePos, NULL_VECTOR, NULL_VECTOR);
				
				AcceptEntityInput(entity, "Stop");
				SetVariantString("OnUser1 !self:Kill::0.1:1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser1");
			}
			g_iParticles[client][i] = INVALID_ENT_REFERENCE;
		}
	}
}

// ========================================================================
// FIREWORKS GAG LOGIC
// ========================================================================
stock void StartFireworksTimer(int client)
{
	KillFireworksTimer(client);
	SpawnFirework(client);
	g_hFireworksTimers[client] = CreateTimer(1.0, Timer_SpawnFireworks, GetClientUserId(client), TIMER_REPEAT);
}

stock void KillFireworksTimer(int client)
{
	if (g_hFireworksTimers[client] != null)
	{
		KillTimer(g_hFireworksTimers[client]);
		g_hFireworksTimers[client] = null;
	}
}

public Action Timer_SpawnFireworks(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsPlayerAlive(client) && g_bPreGame)
	{
		SpawnFirework(client);
		return Plugin_Continue;
	}
	g_hFireworksTimers[client] = null;
	return Plugin_Stop;
}

stock void SpawnFirework(int client)
{
	int particle = CreateEntityByName("info_particle_system");	
	char tName[128];
	if (IsValidEntity(particle))
	{
		float pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 55.0; 
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", client);
		DispatchKeyValue(client, "targetname", tName);		
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", "mini_fireworks");
		DispatchSpawn(particle);
		
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetVariantString("flag");
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
	}
}

// ========================================================================
// SIZE SHIFTER LOGIC
// ========================================================================
stock void StartSizeTimer(int client)
{
	KillSizeTimer(client);
	ApplyRandomSize(client);
	float delay = GetRandomFloat(0.5, 2.0); 
	g_hSizeTimers[client] = CreateTimer(delay, Timer_SizeShift, GetClientUserId(client));
}

public Action Timer_SizeShift(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsPlayerAlive(client) && g_bPreGame)
	{
		ApplyRandomSize(client);
		float delay = GetRandomFloat(0.5, 2.0);
		g_hSizeTimers[client] = CreateTimer(delay, Timer_SizeShift, userid);
	}
	else g_hSizeTimers[client] = null;
	
	return Plugin_Handled;
}

stock void ApplyRandomSize(int client)
{
	if (GetRandomInt(0, 1) == 0)
	{
		TF2_RemoveCondition(client, TFCond_HalloweenTiny);
		TF2_AddCondition(client, TFCond_HalloweenGiant, -1.0);
	}
	else
	{
		TF2_RemoveCondition(client, TFCond_HalloweenGiant);
		TF2_AddCondition(client, TFCond_HalloweenTiny, -1.0);
	}
}

stock void KillSizeTimer(int client)
{
	if (g_hSizeTimers[client] != null)
	{
		KillTimer(g_hSizeTimers[client]);
		g_hSizeTimers[client] = null;
	}
}

// ========================================================================
// WEAPON MANAGEMENT
// ========================================================================
stock void RemoveFlameMedi(int client)
{
	TFClassType iClass = TF2_GetPlayerClass(client);
	int iWeapon = -1;
	
	if (iClass == TFClass_Pyro)
	{	
		iWeapon = GetPlayerWeaponSlot(client, 0);
		if (iWeapon != -1) TF2_RemoveWeaponSlot(client, 0);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 1));
	}
	if (iClass == TFClass_Medic)
	{
		iWeapon = GetPlayerWeaponSlot(client, 1);
		if (iWeapon != -1) TF2_RemoveWeaponSlot(client, 1);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 0));
	}
}

stock void RemoveWeapons(int client)
{
	for (int i = 0; i < 5; i++)
	{
		if (i != 2) 
		{
			if (GetPlayerWeaponSlot(client, i) != -1) TF2_RemoveWeaponSlot(client, i);
		}
	}
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 2));
}

// ========================================================================
// PREGAME CONTROLLERS
// ========================================================================
public void TF2_OnWaitingForPlayersStart()
{
	StartPreGame();
}

public void TF2_OnWaitingForPlayersEnd()
{
	StopPreGame();
}

stock void StartPreGame()
{
	g_bPreGame = true;
	
	ConVar hFriendlyFire = FindConVar("mp_friendlyfire");
	if (hFriendlyFire != null) hFriendlyFire.BoolValue = true;
	
	ConVar hAvoidTeammates = FindConVar("tf_avoidteammates");
	if (hAvoidTeammates != null) hAvoidTeammates.BoolValue = false;
	
	if (g_hVarDisableLockers.BoolValue)
	{
		CreateTimer(1.5, Timer_DisableLockers, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	RespawnAll();
	
	g_iTimeLeft = g_hVarTime.IntValue;
	CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT);
	
	SetGlobalEffect();
	SetGlobalVisualGag();
	SetGlobalMelee();
	
	CreateTimer(2.0, Timer_AnnounceMode, _, TIMER_FLAG_NO_MAPCHANGE);
	
	// Delayed execution to bypass map logic auto-locking setup gates
	CreateTimer(1.5, Timer_DelayDoors, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DelayDoors(Handle timer)
{
	if (!g_bPreGame) return Plugin_Handled;

	char lock[32];
	char openClose[32];
	bool bLock;
	
	switch (view_as<e_Door>(g_hVarDoors.IntValue))
	{
		case dontTouch: return Plugin_Handled;
		case open: bLock = false;
		case close: bLock = true;
		case randomDoor:
		{
			switch (GetRandomInt(1, 3))
			{
				case 1: bLock = false;
				case 2: bLock = true;
				case 3: return Plugin_Handled;
			}
		}
	}
	
	if (bLock)
	{
		Format(lock, sizeof(lock), "lock");
		Format(openClose, sizeof(openClose), "close");
	}
	else
	{
		Format(lock, sizeof(lock), "unlock");
		Format(openClose, sizeof(openClose), "open");
	}
	ModifyDoors(lock, openClose);
	
	return Plugin_Handled;
}


stock void StopPreGame()
{
	if (g_bPreGame)
	{
		g_bPreGame = false;
		
		CreateTimer(1.0, Timer_RemoveEffects);
		
		ConVar hFriendlyFire = FindConVar("mp_friendlyfire");
		if (hFriendlyFire != null) hFriendlyFire.BoolValue = false;
		
		ConVar hAvoidTeammates = FindConVar("tf_avoidteammates");
		if (hAvoidTeammates != null) hAvoidTeammates.BoolValue = true;
		
		ModifyLockers("Enable");
		UnlockAllDoors();
		
		if (g_hVarStats.BoolValue && GetTeamClientCount(2) > 2 && GetTeamClientCount(3) > 2)
		{
			CreateTimer(0.5, Timer_Winners);
		}
	}
}

public Action Timer_CountDown(Handle timer)
{
	g_iTimeLeft--;
	if (g_iTimeLeft == 0) return Plugin_Stop;
	else return Plugin_Continue;
}

stock void RespawnAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1 && TF2_GetPlayerClass(i) != TFClass_Unknown)
		{
			TF2_RespawnPlayer(i);
		}
	}
}

public Action Timer_RemoveEffects(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		KillSizeTimer(i);
		KillFireworksTimer(i);
		KillParticles(i);
		
		if (IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			TF2_RemoveCondition(i, TFCond_InHealRadius);
			TF2_RemoveCondition(i, TFCond_TeleportedGlow);
			TF2_RemoveCondition(i, TFCond_Disguising);
			TF2_RemoveCondition(i, TFCond_BalloonHead);
			TF2_RemoveCondition(i, TFCond_HalloweenKart);
			TF2_RemoveCondition(i, TFCond_Buffed);
			TF2_RemoveCondition(i, TFCond_Kritzkrieged);
			TF2_RemoveCondition(i, TFCond_SpeedBuffAlly);
			TF2_RemoveCondition(i, TFCond_MegaHeal);
			TF2_RemoveCondition(i, TFCond_DefenseBuffed);
			TF2_RemoveCondition(i, TFCond_HalloweenGiant);
			TF2_RemoveCondition(i, TFCond_HalloweenTiny);
			TF2_RemoveCondition(i, TFCond_MarkedForDeath);
		}
	}
	return Plugin_Handled;
}

// ========================================================================
// TRANSLATION ANNOUNCEMENTS
// ========================================================================
public Action Timer_AnnounceMode(Handle timer)
{
	if (!g_bPreGame) return Plugin_Handled;

	char sMeleeKey[32], sEffectKey[32], sGagKey[32];
	
	if (g_bMelee) sMeleeKey = "Melee_Only";
	else sMeleeKey = "All_Weapons";
	
	switch (g_Effect)
	{
		case effectNone: 			sEffectKey = "Effect_None";
		case effectMiniCrit: 		sEffectKey = "Effect_MiniCrit";
		case effectFullCrit: 		sEffectKey = "Effect_FullCrit";
		case effectSpeed: 			sEffectKey = "Effect_Speed";
		case effectMegaHeal: 		sEffectKey = "Effect_MegaHeal";
		case effectDefense: 		sEffectKey = "Effect_Defense";
		case effectMarkedForDeath: 	sEffectKey = "Effect_Marked";
	}
	
	if (g_hVarVisualGagChaos.BoolValue)
	{
		sGagKey = "Gag_Chaos";
	}
	else
	{
		switch (g_VisualGag)
		{
			case gagHealRadius: 	sGagKey = "Gag_HealRadius";
			case gagTeleportGlow: 	sGagKey = "Gag_TeleportGlow";
			case gagBurning: 		sGagKey = "Gag_Burning";
			case gagDisguising: 	sGagKey = "Gag_Disguising";
			case gagHearts: 		sGagKey = "Gag_Hearts";
			case gagBalloonHead: 	sGagKey = "Gag_BalloonHead";
			case gagBumperCar: 		sGagKey = "Gag_BumperCar";
			case gagFireworks: 		sGagKey = "Gag_Fireworks";
			case gagFlies: 			sGagKey = "Gag_Flies";
			case gagGhosts: 		sGagKey = "Gag_Ghosts";
			case gagConfetti: 		sGagKey = "Gag_Confetti";
			case gagPlanets: 		sGagKey = "Gag_Planets";
			case gagSunbeams: 		sGagKey = "Gag_Sunbeams";
			case gagSizeShifter:	sGagKey = "Gag_SizeShifter";
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			char sMeleeBuffer[64], sEffectBuffer[64], sGagBuffer[64];
			
			Format(sMeleeBuffer, sizeof(sMeleeBuffer), "\x03%T\x01", sMeleeKey, i);
			Format(sEffectBuffer, sizeof(sEffectBuffer), "\x03%T\x01", sEffectKey, i);
			Format(sGagBuffer, sizeof(sGagBuffer), "\x03%T\x01", sGagKey, i);
			
			PrintToChat(i, "\x04[Pregame]\x01 %T", "Pregame_Announce", i, sMeleeBuffer, sEffectBuffer, sGagBuffer);
		}
	}
	
	return Plugin_Handled;
}

// ========================================================================
// LOGIC RANDOMIZERS
// ========================================================================
void SetGlobalMelee()
{
	switch (view_as<e_Melee>(g_hVarMelee.IntValue))
	{
		case meleeOnly: g_bMelee = true;
		case randomMelee: g_bMelee = (GetRandomInt(0, 1) == 1);
		case allowAll: g_bMelee = false;
	}
}

void SetGlobalEffect()
{
	int effectVal = g_hVarEffect.IntValue;
	if (effectVal == 7) effectVal = GetRandomInt(1, 6); 
	g_Effect = view_as<e_Effect>(effectVal);
}

void SetGlobalVisualGag()
{
	int gagVal = g_hVarVisualGagAll.IntValue;
	if (gagVal == 14) gagVal = GetRandomInt(0, 13); 
	g_VisualGag = view_as<e_VisualGag>(gagVal);
}

// ========================================================================
// MAP ENTITY MANIPULATION (DOORS & LOCKERS)
// ========================================================================
public Action Timer_DisableLockers(Handle timer)
{
	if (g_bPreGame && g_hVarDisableLockers.BoolValue)
	{
		ModifyLockers("Disable");
	}
	return Plugin_Handled;
}

stock void ModifyLockers(const char[] input) 
{
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "func_regenerate")) != -1) 
	{
		AcceptEntityInput(iEnt, input);
	}
}

void ModifyDoors(const char[] lockState, const char[] openOrClose)
{
	int ent = -1;
	while((ent = FindEntityByClassname(ent, "func_door")) != -1) 
	{
		AcceptEntityInput(ent, "Unlock");
		AcceptEntityInput(ent, openOrClose);
	}
	
	ent = -1;
	while((ent = FindEntityByClassname(ent, "func_door_rotating")) != -1) 
	{
		AcceptEntityInput(ent, "Unlock");
		AcceptEntityInput(ent, openOrClose);
	}
	
	// Add func_brush check to strip invisible walls blocking the visual doors on Payload maps
	ent = -1;
	while((ent = FindEntityByClassname(ent, "func_brush")) != -1) 
	{
		char tName[64];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		if ((StrContains(tName, "door", false) != -1) || (StrContains(tName, "gate", false) != -1))
		{
			if (StrEqual(openOrClose, "open", false)) AcceptEntityInput(ent, "Disable");
			else AcceptEntityInput(ent, "Enable");
		}
	}
	
	ent = -1;
	while((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1) 
	{
		char tName[64];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		if ((StrContains(tName, "door", false) != -1) || (StrContains(tName, "gate", false) != -1))
		{
			AcceptEntityInput(ent, "Unlock");
			AcceptEntityInput(ent, openOrClose);
		}
	}
	
	if (StrEqual(lockState, "lock", false))
	{
		CreateTimer(2.0, Timer_LockDoors, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_LockDoors(Handle timer)
{
	int ent = -1;
	while((ent = FindEntityByClassname(ent, "func_door")) != -1) AcceptEntityInput(ent, "Lock");
	
	ent = -1;
	while((ent = FindEntityByClassname(ent, "func_door_rotating")) != -1) AcceptEntityInput(ent, "Lock");
	
	ent = -1;
	while((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1) 
	{
		char tName[64];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		if ((StrContains(tName, "door", false) != -1) || (StrContains(tName, "gate", false) != -1))
		{
			AcceptEntityInput(ent, "Lock");
		}
	}
	return Plugin_Handled;
}

stock void UnlockAllDoors()
{
	int ent = -1;
	while((ent = FindEntityByClassname(ent, "func_door")) != -1) AcceptEntityInput(ent, "Unlock");
	
	ent = -1;
	while((ent = FindEntityByClassname(ent, "func_door_rotating")) != -1) AcceptEntityInput(ent, "Unlock");
	
	ent = -1;
	while((ent = FindEntityByClassname(ent, "func_brush")) != -1) 
	{
		char tName[64];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		if ((StrContains(tName, "door", false) != -1) || (StrContains(tName, "gate", false) != -1))
		{
			AcceptEntityInput(ent, "Enable"); // Ensure collision blocks return for actual gameplay
		}
	}
	
	ent = -1;
	while((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1) 
	{
		char tName[64];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		if ((StrContains(tName, "door", false) != -1) || (StrContains(tName, "gate", false) != -1))
		{
			AcceptEntityInput(ent, "Unlock");
		}
	}
}

// ========================================================================
// WINNERS MENU & SORTING
// ========================================================================
public Action Timer_Winners(Handle timer)
{
	int iRedScores[MAXPLAYERS + 1][2],
		iBluScores[MAXPLAYERS + 1][2],
		iRedCount,
		iBluCount;
		
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				iRedScores[iRedCount][0] = i;
				iRedScores[iRedCount++][1] = g_iFrags[i];
			}
			if (GetClientTeam(i) == 3)
			{
				iBluScores[iBluCount][0] = i;
				iBluScores[iBluCount++][1] = g_iFrags[i];
			}
		}
	}
	
	if (iRedCount && iBluCount)
	{
		char sNameBuffer[MAX_NAME_LENGTH + 1];
		char sBuffer[255];
		
		SortCustom2D(iRedScores, iRedCount, SortIntsDesc);
		SortCustom2D(iBluScores, iBluCount, SortIntsDesc);
		
		Panel hMenu = new Panel();
		hMenu.DrawText("Red Team Winners\n");
		
		for (int i = 0; i < 3; i++)
		{
			if (IsClientInGame(iRedScores[i][0]))
			{
				GetClientName(iRedScores[i][0], sNameBuffer, sizeof(sNameBuffer));
				Format(sBuffer, sizeof(sBuffer), "%i  '%i' Frags: %s", i + 1, iRedScores[i][1], sNameBuffer);
				hMenu.DrawText(sBuffer);
			}
		}
		hMenu.DrawText("-----------------");
		hMenu.DrawText("Blue Team Winners\n");
		
		for (int i = 0; i < 3; i++)
		{
			if (IsClientInGame(iBluScores[i][0]))
			{
				GetClientName(iBluScores[i][0], sNameBuffer, sizeof(sNameBuffer));
				Format(sBuffer, sizeof(sBuffer), "%i  '%i' Frags: %s", i + 1, iBluScores[i][1], sNameBuffer);
				hMenu.DrawText(sBuffer);
			}
		}
		hMenu.DrawItem("exit");
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) > 1 && !IsFakeClient(i) && g_iMenuSettings[i] != -1)
			{
				hMenu.Send(i, Panel_Callback, 20);
			}
		}
		
		delete hMenu;
	}
	return Plugin_Handled;
}

public int Panel_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	return 0; 
}

public int SortIntsDesc(int[] x, int[] y, const int[][] array, Handle data)		
{
    if (x[1] > y[1]) return -1;
	else if (x[1] < y[1]) return 1;    
    return 0;
}

// ========================================================================
// CONVAR MODIFIERS
// ========================================================================
stock void StripNotify(const char[] setting)
{
	ConVar hVar = FindConVar(setting);
	if (hVar != null)
	{
		int iFlags = hVar.Flags;
		if (iFlags & FCVAR_NOTIFY)
		{
			hVar.Flags = iFlags & ~FCVAR_NOTIFY;
		}
	}
}

stock void AddNotify(const char[] setting)
{
	ConVar hVar = FindConVar(setting);
	if (hVar != null)
	{
		int iFlags = hVar.Flags;
		if (!(iFlags & FCVAR_NOTIFY))
		{
			hVar.Flags = iFlags | FCVAR_NOTIFY;
		}
	}
}