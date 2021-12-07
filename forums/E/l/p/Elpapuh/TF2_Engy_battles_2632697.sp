#define PL_AUTHOR "ElPapuh"
#define PL_VERSION "1.6.4"
#define PL_DESC "My first sourcemod plugin"
#define PL_URL "https://jlovers.ml"
#define UPDATE_URL "https://jlovers.ml/plugins/engybattle.txt"

#define TF_CLASS_OTHER		4|6|7|5|1|2|3|8
#define TF_CLASS_ENGINEER		9
#define TF_CLASS_SCOUT			1
#define TF_TEAM_BLU					3
#define TF_TEAM_RED					2

int OwnerOffset;
ConVar sm_dispensers;
ConVar sm_sentrys;
ConVar sm_instant;

new bool:g_bIsRoundActive = true;
new bool:bEnabled;
new ammoOffset;

new g_iClass[MAXPLAYERS + 1];
new Handle:g_hEnabled;
new Handle:g_cvarAmmo = INVALID_HANDLE;
new Handle:g_cvarAmmoSentry = INVALID_HANDLE;
new Handle:g_cvarAmmoMetal = INVALID_HANDLE;
new Handle:g_cvarFAmmo = INVALID_HANDLE;
new Handle:g_cvarInfinite = INVALID_HANDLE;
new Handle:g_cvarOpenDoors = INVALID_HANDLE;
new Handle:g_cvarMapTime = INVALID_HANDLE;
new Handle:g_cvarMessage = INVALID_HANDLE;
new Handle:g_hFlags;
new Handle:g_hLimits[4][20];
new String:g_sSounds[10][24] = {"", "vo/scout_no03.wav",   "vo/sniper_no04.wav", "vo/soldier_no01.wav",
																		"vo/demoman_no03.wav", "vo/medic_no03.wav",  "vo/heavy_no02.wav",
																		"vo/pyro_no01.wav",    "vo/spy_no02.wav",    "vo/engineer_no03.wav"};

#include <updater>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <sdkhooks>
#include <sdktools>
#include <clients>
#include <SteamWorks>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN

public Plugin myinfo =
{
	name = "EngieBattles",
	author = PL_AUTHOR,
	description = PL_DESC,
	version = PL_VERSION,
	url = PL_URL
};

public OnPluginStart()
{
	sm_dispensers = CreateConVar("sm_dispensers", "5", "How many dispensers as max do you want to be able to build");
	sm_sentrys = CreateConVar("sm_sentrys", "5", "How many sentrys as max do you want to be able to build");
	sm_instant = CreateConVar("sm_instant","0","Upgrade buildings with 1 hit only (This doesn't uses metal)");
	RegAdminCmd("sm_disablecp", Command_DisableCP, ADMFLAG_GENERIC);
	RegAdminCmd("sm_disablectf", Command_DisableCTF, ADMFLAG_GENERIC);
	RegAdminCmd("sm_time", Command_Time, ADMFLAG_GENERIC);
	RegAdminCmd("sm_open", Command_OpenDoors, ADMFLAG_GENERIC)
	
	EBOn();
	
	CreateConVar("sm_engybattle", PL_VERSION, "[TF2] Engy Battles version", FCVAR_NOTIFY);
	new Handle:hCvarEnabled = CreateConVar("sm_wrangle", "1", "Enable/Disable wrangling multiple sentries", true, 0.0, true, 1.0);
	g_hEnabled                                = CreateConVar("sm_restrictions",       "1",  "Enable/disable restricting classes in TF2.");
	g_hFlags                                  = CreateConVar("sm_restrictions_flags",         "",   "Admin flags for restricted classes in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_CLASS_OTHER]  = CreateConVar("sm_other",   "0", "Limit for other classes in TF2.", FCVAR_SPONLY);
	g_hLimits[TF_TEAM_BLU][TF_CLASS_ENGINEER] = CreateConVar("sm_engys", "-1", "Limit for engineers in TF2.", FCVAR_SPONLY);
	g_hLimits[TF_TEAM_RED][TF_CLASS_ENGINEER] = CreateConVar("sm_engys", "-1", "Limit for engineers in TF2.", FCVAR_SPONLY);
	g_hLimits[TF_TEAM_RED][TF_CLASS_OTHER]    = CreateConVar("sm_other",   "0", "Limit for other classes in TF2.", FCVAR_SPONLY);

	g_cvarMessage = CreateConVar("sm_message", "1", "Enables/Disables the plugin info welcome message");
	g_cvarAmmo = CreateConVar("sm_ammo", "1", "Enables/Disables the infinite ammo");
	g_cvarAmmoSentry = CreateConVar("sm_ammo_sentry", "0", "Enables/Disables the infinite ammo on sentrys");
	g_cvarAmmoMetal = CreateConVar("sm_ammo_metal", "0", "Enable/Disables the infinite ammo on engineers metal");
	g_cvarFAmmo = CreateConVar("sm_fullammo", "0", "Enable/Disables the full infinite ammo(Shells, sentry and engineers metal) independently from sm_ammo_metal, sm_ammo_sentry and sm_ammo")
	g_cvarInfinite = CreateConVar("sm_infiniter", "1", "Enables/Disables the infinite round plugin system");
	g_cvarOpenDoors = CreateConVar("sm_opendoors", "1", "Enables/Disables the doors opening on pl maps to avoid the struck of some teams");
	g_cvarMapTime = CreateConVar("sm_timelimit", "1", "Enables/Disables the mp_timelimit command idependently from sm_infiniter");
	
	bEnabled = GetConVarBool(hCvarEnabled);
	
	HookConVarChange(hCvarEnabled, cvarchangeEnabled);
	
	HookEvent("player_builtobject",Evt_BuiltObject,EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_changeclass", PlayerClass);
	HookEvent("controlpoint_starttouch", OnPointCap);
	HookEvent("ctf_flag_captured", OnPlayerCTF);
	HookEvent("player_spawn",       OnPlayerSpawn);
	HookEvent("player_team",        PlayerTeam);
	HookEvent("teamplay_round_start", OnRoundStart);
	
	OwnerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
	
	for(int client=1;client<MaxClients;client++){
		if(!IsValidEntity(client)){
			continue;
		}
		if(!IsClientConnected(client)){
			continue;
		}

		SDKUnhook(client, SDKHook_WeaponSwitch, WeaponSwitch);
		SDKHookEx(client, SDKHook_WeaponSwitch, WeaponSwitch);
	}
	if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
	
	ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	
	CreateTimer(0.4, Timer_Refill, _, TIMER_REPEAT);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	EBOn();
}

public OnConfigsExecuted()
{
	EBOn();
}

public cvarchangeEnabled(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	bEnabled = GetConVarBool(cvar);
}

public EBOn()
{
	decl String:gameDesc[64];
	Format(gameDesc, sizeof(gameDesc), "Engy Battles %s", PL_VERSION);
	Steam_SetGameDescription(gameDesc);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:ang[3], &weapon)
{
	if (!bEnabled) return Plugin_Continue;
	decl String:wep[64];
	if (!IsClientInGame(client)) return Plugin_Continue;
	if (!IsPlayerAlive(client)) return Plugin_Continue;
	new offs = FindSendPropInfo("CObjectSentrygun", "m_hEnemy");
	new wepent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (wepent < MaxClients || !IsValidEntity(wepent)) return Plugin_Continue;
	if (GetEntProp(client, Prop_Send, "m_bFeignDeathReady")) return Plugin_Continue;
	if (TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Bonked)) return Plugin_Continue;
	if (TF2_IsPlayerInCondition(client, TFCond_Dazed) && GetEntProp(client, Prop_Send, "m_iStunFlags") & (TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_THIRDPERSON)) return Plugin_Continue;
	new Float:time = GetGameTime();
	if (time < GetEntPropFloat(client, Prop_Send, "m_flNextAttack")) return Plugin_Continue;
	if (time < GetEntPropFloat(client, Prop_Send, "m_flStealthNoAttackExpire")) return Plugin_Continue;
	new bool:nextprim = time >= GetEntPropFloat(wepent, Prop_Send, "m_flNextPrimaryAttack");
	new bool:nextsec = time >= GetEntPropFloat(wepent, Prop_Send, "m_flNextSecondaryAttack");
	if (!nextprim && !nextsec) return Plugin_Continue;
	GetClientWeapon(client, wep, sizeof(wep));
	if (!StrEqual(wep, "tf_weapon_laser_pointer", false)) return Plugin_Continue;
	new i = -1;
	while ((i = FindEntityByClassname(i, "obj_sentrygun")) != -1)
	{
		if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") != client) continue;
		if (GetEntProp(i, Prop_Send, "m_bDisabled")) continue;
		new level = GetEntProp(i, Prop_Send, "m_iUpgradeLevel");
		if (nextsec && level == 3 && buttons & IN_ATTACK2) SetEntData(i, offs+5, 1, 1, true);
		if (nextprim && buttons & IN_ATTACK) SetEntData(i, offs+4, 1, 1, true);
	}
	return Plugin_Continue;
}

public Action:Timer_Refill(Handle:timer)
{
	if(GetConVarInt(g_cvarAmmo) == 1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{	
				RefillAmmo(i);
			}
		}
	}
	if(GetConVarInt(g_cvarAmmoSentry) == 1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{	
				InfiniteSentryAmmo(i);
			}
		}
	}
	if(GetConVarInt(g_cvarAmmoMetal) == 1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{	
				SetEntData(i, FindDataMapInfo(i, "m_iAmmo")+12, 200, 4);
			}
		}
	}
	if(GetConVarInt(g_cvarFAmmo) == 1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{	
				SetEntData(i, FindDataMapInfo(i, "m_iAmmo")+12, 200, 4);
				InfiniteSentryAmmo(i);
				RefillAmmo(i);
			}
		}
	}
}

public InfiniteSentryAmmo(client)
{
	new sentrygun = -1; 
	while ((sentrygun = FindEntityByClassname(sentrygun, "obj_sentrygun"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(sentrygun))
		{
			if(GetEntPropEnt(sentrygun, Prop_Send, "m_hBuilder") == client)
			{
				if(GetEntProp(sentrygun, Prop_Send, "m_bMiniBuilding"))
				{
					SetEntProp(sentrygun, Prop_Send, "m_iAmmoShells", 150); 
				}
				else
				{
					switch (GetEntProp(sentrygun, Prop_Send, "m_iUpgradeLevel"))
					{
						case 1:
						{
							SetEntProp(sentrygun, Prop_Send, "m_iAmmoShells", 150);
						}
						case 2:
						{
							SetEntProp(sentrygun, Prop_Send, "m_iAmmoShells", 200);
						}
						case 3:
						{
							SetEntProp(sentrygun, Prop_Send, "m_iAmmoShells", 200);
							SetEntProp(sentrygun, Prop_Send, "m_iAmmoRockets", 20);
						}
					}
				}
			}
		}
	}
}

stock RefillAmmo(i)
{
	if(ammoOffset != -1)
	{
		SetEntData(i, ammoOffset +4, 50);
		SetEntData(i, ammoOffset +8, 50);
	}
}

public OnMapStart()
{
	CreateTimer(35.0, Timer_DisableForPlayers);
	decl i, String:sSound[32];
	for(i = 1; i < sizeof(g_sSounds); i++)
	{
		Format(sSound, sizeof(sSound), "sound/%s", g_sSounds[i]);
		PrecacheSound(g_sSounds[i]);
		AddFileToDownloadsTable(sSound);
	}
	
	HookEntityOutput("func_door", "OnClose", DoorClosing);
}

public OnClientPutInServer(client)
{
	g_iClass[client] = TF_CLASS_ENGINEER;
	CreateTimer(10.0, WelcomeMessage, any:client);
}

public Action:WelcomeMessage(Handle:timer, any:client)
{
	if(!IsFakeClient(client))
	{	
		if(GetConVarInt(g_cvarMessage) == 1)
		{
			CPrintToChat(client, "{red}[{green}Engy Battles{red}] {orange}WARNING: {red}This minigame is new, so, if you like it, support it on:{pink}https://forums.alliedmods.net/showthread.php?t=313287 {red}and invite your friends to play with you on the server")
		}
		CPrintToChat(client, "{red}[{green}Engy Battles{red}] {orange}Engy Battles is just a minigame in there you can place multiple sentrys and then kill the enemy enginneers, all other classes are restricted, have fun");
	}
}

public Action:Timer_DisableForPlayers(Handle:timer)
{
	if(GetConVarInt(g_cvarInfinite) == 1)
	{
		decl String:mapname[128]
		GetCurrentMap(mapname, sizeof(mapname))
		if (!(StrContains( mapname, "cp_", false) == 0))
		{
			CreateTimer(10.0, Timer_Infinite)
			ServerCommand("mp_waitingforplayers_cancel 1");
		}
		if (StrContains( mapname, "pl_", false) == 0)
		{
			CreateTimer(20.0, Timer_Payload);
			CreateTimer(18.0, Timer_OpenDoors);
			if(GetConVarInt(g_cvarOpenDoors) == 1)
			{
				CreateTimer(18.0, Timer_OpenDoors);
			}
		}
	}
}

public Action:Command_OpenDoors(client, args)
{
	if(GetConVarInt(g_cvarOpenDoors) == 1)
	{
		g_bIsRoundActive = false;

		new iDoor = -1;
		while ((iDoor = FindEntityByClassname(iDoor, "func_door")) != -1)
		{
			AcceptEntityInput(iDoor, "Open");
		}
	}
} 

public Action:Timer_OpenDoors(Handle:timer)
{
	g_bIsRoundActive = false;

	new iDoor = -1;
	while ((iDoor = FindEntityByClassname(iDoor, "func_door")) != -1)
	{
		AcceptEntityInput(iDoor, "Open");
	}
} 

public DoorClosing(const String:output[], caller, activator, Float:delay)
{
	if (!g_bIsRoundActive)
		AcceptEntityInput(caller, "Open");
}

public Action:Timer_Payload(Handle:timer)
{
	ServerCommand("sm_time 1000000000000000");
	CPrintToChatAll("{red}[{green}Battle Engy{red}] {orange}The timer has been stoped, fight!");
	if(GetConVarInt(g_cvarMapTime) == 1)
	{
		ServerCommand("mp_timelimit 0");
	}
}

public Action:Timer_Infinite(Handle:timer)
{
	ServerCommand("sm_time 1000000000000000");
	CPrintToChatAll("{red}[{green}Battle Engy{red}] {orange}The timer has been stoped, fight!");
	if(GetConVarInt(g_cvarMapTime) == 1)
	{
		ServerCommand("mp_timelimit 0");
	}
}

public Action:Command_Time(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_time <amount>");
		return Plugin_Handled;
	}

	decl String:cmdArg[32];
	GetCmdArg(1, cmdArg, sizeof(cmdArg));

	new entityTimer = FindEntityByClassname(-1, "team_round_timer");
	if (entityTimer > -1)
	{
		SetVariantInt(StringToInt(cmdArg));
		AcceptEntityInput(entityTimer, "SetTime");
	}
	else
	{
		new Handle:timelimit = FindConVar("mp_timelimit");
		SetConVarFloat(timelimit, StringToFloat(cmdArg) / 60);
		CloseHandle(timelimit);
	}

	return Plugin_Handled;
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public Action:Command_DisableCP(client, args)
{
	DisableControlPoints(true);
	CPrintToChatAll("{red}[{green}Engy Battles{red}] {orange}Game objectives are now disabled");
	UnhookEvent("controlpoint_starttouch", OnPointCap);
	return Plugin_Handled;
}

public Action:Command_DisableCTF(client, args)
{
	DisableAllFlags(true);
	CPrintToChatAll("{red}[{green}Engy Battles{red}] {orange}Game objectives are now disabled");
	ServerCommand("tf_flag_caps_per_round 0");
	UnhookEvent("ctf_flag_captured", OnPlayerCTF);
	return Plugin_Handled;
}

public OnPlayerCTF(Handle:event, const String:name[], bool:dontBroadcast)
{
    ServerCommand("sm_disablectf");
}

public OnPointCap(Handle:event, const String:name[], bool:dontBroadcast)
{
    ServerCommand("sm_disablecp");
}

public DisableAllFlags(bool:capState) {
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "item_teamflag")) != -1) {
		if(IsValidEntity(ent)) {
			AcceptEntityInput(ent, "Disable");
		}
	}
}

public DisableControlPoints(bool:capState)
{
    new i = -1;
    new CP = 0;

    for (new n = 0; n <= 16; n++)
    {
        CP = FindEntityByClassname(i, "trigger_capture_area");
        if (IsValidEntity(CP))
        {
            if(capState)
            {
                AcceptEntityInput(CP, "Disable");
            }
			else
			{
                AcceptEntityInput(CP, "Enable");
            }
            i = CP;
        }
        else
            break;
    }
} 

public PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
			iClass  = GetEventInt(event, "class"),
			iTeam   = GetClientTeam(iClient);
	
	if(!IsImmune(iClient))
	{
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		EmitSoundToClient(iClient, g_sSounds[iClass]);
		TF2_SetPlayerClass(iClient, TFClassType:TF_CLASS_ENGINEER);
	}
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		RequestFrame(Respawn, GetClientSerial(i));
	}
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
			iTeam   = GetClientTeam(iClient);
	
	if(!(IsImmune(iClient)) && IsFull(iTeam, (g_iClass[iClient] = _:TF2_GetPlayerClass(iClient))))
	{
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		EmitSoundToClient(iClient, g_sSounds[g_iClass[iClient]]);
		PickClass(iClient);
	}
}
/*
public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
			iTeam   = GetClientTeam(iClient);
	
	if(!(IsImmune(iClient)) && IsFull(iTeam, (g_iClass[iClient] = _:TF2_GetPlayerClass(iClient))))
	{
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		EmitSoundToClient(iClient, g_sSounds[g_iClass[iClient]]);
		PickClass(iClient);
	}
}
*/

public PlayerTeam(Handle:event,  const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
			iTeam   = GetEventInt(event, "team");
	
	if(!(IsImmune(iClient)) && IsFull(iTeam, g_iClass[iClient]))
	{
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		EmitSoundToClient(iClient, g_sSounds[g_iClass[iClient]]);
		PickClass(iClient);
	}
}

bool:IsFull(iTeam, iClass)
{
	// If plugin is disabled, or team or class is invalid, class is not full
	if(!GetConVarBool(g_hEnabled) || iTeam < TF_TEAM_RED || iClass < TF_CLASS_SCOUT)
		return false;
	
	// Get team's class limit
	new iLimit,
			Float:flLimit = GetConVarFloat(g_hLimits[iTeam][iClass]);
	
	// If limit is a percentage, calculate real limit
	if(flLimit > 0.0 && flLimit < 1.0)
		iLimit = RoundToNearest(flLimit * GetTeamClientCount(iTeam));
	else
		iLimit = RoundToNearest(flLimit);
	
	// If limit is -1, class is not full
	if(iLimit == -1)
		return false;
	// If limit is 0, class is full
	else if(iLimit == 0)
		return true;
	
	// Loop through all clients
	for(new i = 1, iCount = 0; i <= MaxClients; i++)
	{
		// If client is in game, on this team, has this class and limit has been reached, class is full
		if(IsClientInGame(i) && GetClientTeam(i) == iTeam && _:TF2_GetPlayerClass(i) == iClass && ++iCount > iLimit)
			return true;
	}
	
	return false;
}

bool:IsImmune(iClient)
{
	if(!iClient || !IsClientInGame(iClient))
		return false;
	
	decl String:sFlags[32];
	GetConVarString(g_hFlags, sFlags, sizeof(sFlags));
	
	// If flags are specified and client has generic or root flag, client is immune
	return !StrEqual(sFlags, "") && GetUserFlagBits(iClient) & (ReadFlagString(sFlags)|ADMFLAG_ROOT);
}

PickClass(iClient)
{
	// Loop through all classes, starting at random class
	for(new i = GetRandomInt(TF_CLASS_SCOUT, TF_CLASS_ENGINEER), iClass = i, iTeam = GetClientTeam(iClient);;)
	{
		// If team's class is not full, set client's class
		if(!IsFull(iTeam, i))
		{
			TF2_SetPlayerClass(iClient, TFClassType:i);
			TF2_RespawnPlayer(iClient);
			g_iClass[iClient] = i;
			break;
		}
		// If next class index is invalid, start at first class
		else if(++i > TF_CLASS_ENGINEER)
			i = TF_CLASS_SCOUT;
		// If loop has finished, stop searching
		else if(i == iClass)
			break;
	}
}

public Respawn(any:serial)
{
	new client = GetClientFromSerial(serial);
	if(client != 0)
	{
		new team = GetClientTeam(client);
		if(!IsPlayerAlive(client) && team != 1)
		{
			TF2_RespawnPlayer(client);
		}
	}
}

public ArenaMode(any:serial)
{
	new client = GetClientFromSerial(serial);
	if(client != 0)
	{
		new team = GetClientTeam(client);
		if(!IsPlayerAlive(client) && team != 1)
		{
			CPrintToChat(client, "{red}[{green}Engy battles{red}] {orange}This is arena mode, the respawn has been disabled");
			if (IsPlayerAlive(client))
			{
				CPrintToChat(client, "{red}[{green}Engy battles{red}] {orange}Oh no, someone died, in arena mode there is not respawn");
			}
		}
	}
}

public void OnClientPostAdminCheck(client){
    SDKHookEx(client, SDKHook_WeaponSwitch, WeaponSwitch);
}
public Action Evt_BuiltObject(Event event, const char[] name, bool dontBroadcast){
	int ObjIndex = event .GetInt("index");

	if(GetConVarInt(sm_instant)>0){

		SetEntProp(ObjIndex, Prop_Send, "m_iUpgradeMetal", 600);
		SetEntProp(ObjIndex,Prop_Send,"m_iUpgradeMetalRequired",0);

	}



	return Plugin_Continue;
}

public Action WeaponSwitch(client, weapon){
	if(!IsClientInGame(client)){
		return Plugin_Continue;
	}
	if(TF2_GetPlayerClass(client)!=TFClass_Engineer){
		return Plugin_Continue;
	}
	if(!IsValidEntity(GetPlayerWeaponSlot(client,1))){
		return Plugin_Continue;
	}
	if(!IsValidEntity(GetPlayerWeaponSlot(client,3))){
		return Plugin_Continue;
	}
	if(!IsValidEntity(GetPlayerWeaponSlot(client,4))){
		return Plugin_Continue;
	}
	if(!IsValidEntity(weapon)){
		return Plugin_Continue;
	}

	if(GetPlayerWeaponSlot(client,3)==weapon){
		function_AllowBuilding(client);
		return Plugin_Continue;
	}
	else if(GetEntProp(weapon,Prop_Send,"m_iItemDefinitionIndex")!=28){
		function_AllowDestroying(client);
		return Plugin_Continue;
	}
	return Plugin_Continue;

}

public void function_AllowBuilding(int client){

	int DispenserLimit = GetConVarInt(sm_dispensers);
	int SentryLimit = GetConVarInt(sm_sentrys);

	int DispenserCount = 0;
	int SentryCount = 0;

	for(int i=0;i<2048;i++){

		if(!IsValidEntity(i)){
			continue;
		}

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		if ( !(strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0) ){
			continue;
		}

		if(GetEntDataEnt2(i, OwnerOffset)!=client){
			continue;
		}


		int type=view_as<int>(function_GetBuildingType(i));

		if(type==view_as<int>(TFObject_Dispenser)){
			DispenserCount=DispenserCount+1;
			SetEntProp(i, Prop_Send, "m_iObjectType", TFObject_Sapper);
			if(DispenserCount>=DispenserLimit){
				SetEntProp(i, Prop_Send, "m_iObjectType", type);

			}

		}else if(type==view_as<int>(TFObject_Sentry)){
			SentryCount++;
			SetEntProp(i, Prop_Send, "m_iObjectType", TFObject_Sapper);
			if(SentryCount>=SentryLimit){
				SetEntProp(i, Prop_Send, "m_iObjectType", type);
			}
		}


	}
}
public void function_AllowDestroying(int client){
	for(int i=1;i<2048;i++){

		if(!IsValidEntity(i)){
			continue;
		}

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if ( !(strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0) ){
			continue;
		}

		if(GetEntDataEnt2(i, OwnerOffset)!=client){
			continue;
		}

		SetEntProp(i, Prop_Send, "m_iObjectType", function_GetBuildingType(i));
	}

}

public TFObjectType function_GetBuildingType(int entIndex){
	
	decl String:netclass[32];
	GetEntityNetClass(entIndex, netclass, sizeof(netclass));

	if(strcmp(netclass, "CObjectSentrygun") == 0){
		return TFObject_Sentry;
	}
	if(strcmp(netclass, "CObjectDispenser") == 0){
		return TFObject_Dispenser;
	}

	return TFObject_Sapper;


}

stock CheckGameType()
{
	new String:sGameType[16];
	GetGameFolderName(sGameType, sizeof(sGameType));
	new bool:IsTeamFortress = StrEqual(sGameType, "tf", true);
	
	if(!IsTeamFortress)
	{
		SetFailState("This plugin is Team Fortress 2 only.");
	}
}
