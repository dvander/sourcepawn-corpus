/**
 * ====================
 *     Zombie Riot
 *   File: zombieriot.sp
 *   Author: Greyscale
 * ==================== 
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#undef REQUIRE_PLUGIN
#include <market>

#define VERSION "1.9.1"

#include "zriot/zombieriot"
#include "zriot/global"
#include "zriot/cvars"
#include "zriot/translation"
#include "zriot/offsets"
#include "zriot/ambience"
#include "zriot/zombiedata"
#include "zriot/daydata"
#include "zriot/targeting"
#include "zriot/overlays"
#include "zriot/zombie"
#include "zriot/hud"
#include "zriot/sayhooks"
#include "zriot/teamcontrol"
#include "zriot/weaponrestrict"
#include "zriot/commands"
//NotD Includes
#include "zriot/notd/specialzombie"
//End NotD Includes
#include "zriot/event"

public Plugin:myinfo =
{
    name = "Zombie Riot", 
    author = "Greyscale", 
    description = "Humans stick together to fight off zombie attacks", 
    version = VERSION, 
    url = ""
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateGlobals();
    
    return APLRes_Success;
}

public OnPluginStart()
{
    LoadTranslations("common.phrases.txt");
    LoadTranslations("zombieriot.phrases.txt");
    
    // ======================================================================
    
    ZRiot_PrintToServer("Plugin loading");
    
    // ======================================================================
    
    ServerCommand("bot_kick");
    
    // ======================================================================
    
    HookEvents();
    HookChatCmds();
    CreateCvars();
    HookCvars();
    CreateCommands();
    HookCommands();
    FindOffsets();
    SetupGameData();
    InitTeamControl();
    InitWeaponRestrict();
    
    // ======================================================================
    
    trieDeaths = CreateTrie();
    
    // ======================================================================
    
    market = LibraryExists("market");
    
    // ======================================================================
    
    CreateConVar("gs_zombieriot_version", VERSION, "[ZRiot] Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    // ======================================================================
    
    ZRiot_PrintToServer("Plugin loaded");
		
		
	//NotD Addons
	repeatTimer = CreateTimer(0.1, SpecialZombie, _, TIMER_REPEAT);
	hNOTDGameConf = LoadGameConfigFile("notd.games");
	if(hNOTDGameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/notd.games.txt not loadable");
	}
	
	// Prep some virtual SDK calls
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hNOTDGameConf, SDKConf_Virtual, "EyePosition");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	hGetEyePosition = EndPrepSDKCall();
	// Prep some virtual SDK calls
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hNOTDGameConf, SDKConf_Virtual, "EyePosition");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	hGetEyePosition = EndPrepSDKCall();
}

public OnPluginEnd()
{
	//NotD Addon
	if (repeatTimer != INVALID_HANDLE) 
		KillTimer(repeatTimer);
	repeatTimer = INVALID_HANDLE;
	if (smokerSpawnTimer != INVALID_HANDLE) 
		KillTimer(smokerSpawnTimer);
	smokerSpawnTimer = INVALID_HANDLE;
	//End NotD Addon
    ZRiotEnd();
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "market"))
	{
		market = false;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "market"))
	{
		market = true;
	}
}

public OnMapStart()
{
    MapChangeCleanup();
    
    LoadModelData();
    LoadDownloadData();
    
    BuildPath(Path_SM, gMapConfig, sizeof(gMapConfig), "configs/zriot");
    
    LoadZombieData(true);
    LoadDayData(true);
    
    CheckMapConfig();
	//NotD Addon
	PrecacheSound("npc/zombie/zombie_alert1.wav", true);
	PrecacheSound("npc/ichthyosaur/snap.wav", true);
	PrecacheSound("player/pl_fallpain3.wav", true);
	PrecacheSound("npc/ichthyosaur/attack_growl3.wav", true);
	PrecacheSound("npc/ichthyosaur/snap.wav", true);
	PrecacheSound("npc/zombie_poison/pz_breathe_loop1.wav", true);
	PrecacheSound("npc/strider/charging.wav", true);
	
	g_Sprite = PrecacheModel("materials/sprites/laser.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	g_FlameHalo = PrecacheModel("sprites/orangeglow1.vtf");
	g_SmokeModel = PrecacheModel("materials/effects/fire_cloud2.vmt");
	PrecacheModel(SMOKERMODEL);
	colorSmoker[0] = 5;
	colorSmoker[1] = 245;
	colorSmoker[2] = 5;
	colorSmoker[3] = 245;
	colorIfrat[0] = 255;
	colorIfrat[1] = 50;
	colorIfrat[2] = 50;
	colorIfrat[3] = 245;
	
}

public OnConfigsExecuted()
{
    UpdateTeams();
    
    FindMapSky();
    FindHostname();
    
    LoadAmbienceData();
    
    decl String:mapconfig[PLATFORM_MAX_PATH];
    
    GetCurrentMap(mapconfig, sizeof(mapconfig));
    Format(mapconfig, sizeof(mapconfig), "sourcemod/zombieriot/%s.cfg", mapconfig);
    
    decl String:path[PLATFORM_MAX_PATH];
    Format(path, sizeof(path), "cfg/%s", mapconfig);
    
    if (FileExists(path))
    {
        ServerCommand("exec %s", mapconfig);
    }
}

public OnClientPutInServer(client)
{
    new bool:fakeclient = IsFakeClient(client);
    
    InitClientDeathCount(client);
    
    new deathcount = GetClientDeathCount(client);
    new deaths_before_zombie = GetDayDeathsBeforeZombie(gDay);
    
    bZombie[client] = !fakeclient ? ((deaths_before_zombie > 0) && (fakeclient || (deathcount >= deaths_before_zombie))) : true;
    
    bZVision[client] = !IsFakeClient(client);
    
    gZombieID[client] = -1;
    
    gTarget[client] = -1;
    RemoveTargeters(client);
    
    tRespawn[client] = INVALID_HANDLE;
    
    ClientHookUse(client);
    
    FindClientDXLevel(client);
}

public OnClientDisconnect(client)
{
    if (!IsPlayerHuman(client))
        return;
    
    new count;
    
    new maxplayers = GetMaxClients();
    for (new x = 1; x <= maxplayers; x++)
    {
        if (!IsClientInGame(x) || !IsPlayerHuman(x) || GetClientTeam(x) <= CS_TEAM_SPECTATOR)
            continue;
        
        count++;
    }
    
    if (count <= 1 && tHUD != INVALID_HANDLE)
    {
        TerminateRound(5.0, Terrorists_Win);
    }
}

MapChangeCleanup()
{
    gDay = 0;
    
    ClearArray(restrictedWeapons);
    ClearTrie(trieDeaths);
    
    tAmbience = INVALID_HANDLE;
    tHUD = INVALID_HANDLE;
    tFreeze = INVALID_HANDLE;
}

CheckMapConfig()
{
    decl String:mapname[64];
    GetCurrentMap(mapname, sizeof(mapname));
    
    Format(gMapConfig, sizeof(gMapConfig), "%s/%s", gMapConfig, mapname);
    
    LoadZombieData(false);
    LoadDayData(false);
}

ZRiotEnd()
{
    TerminateRound(3.0, Game_Commencing);
    
    SetHostname(hostname);
    
    UnhookCvars();
    UnhookEvents();
    
    ServerCommand("bot_all_weapons");
    //ServerCommand("bot_kick");
    
    new maxplayers = GetMaxClients();
    for (new x = 1; x <= maxplayers; x++)
    {
        if (!IsClientInGame(x))
        {
            continue;
        }
        
        if (tRespawn[x] != INVALID_HANDLE)
        {
            CloseHandle(tRespawn[x]);
            tRespawn[x] = INVALID_HANDLE;
        }
    }
}