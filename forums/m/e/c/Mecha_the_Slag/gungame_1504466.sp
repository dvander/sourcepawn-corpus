#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items>
#include <colors>

#define PLUGIN_NAME         "[TF2] TF2 GunGame"
#define PLUGIN_AUTHOR       "Mecha the Slag (Jonas Kaerlev)"
#define PLUGIN_VERSION      "1.02"
#define PLUGIN_CONTACT      "llamabutlermecha@gmail.com"
#define CVAR_FLAGS          FCVAR_PLUGIN

#define SOUND_BELL              "ui/scored.wav"

#define WEAPON_FISTS            0
#define WEAPON_BOTTLE           1
#define WEAPON_KNIFE            2
#define WEAPON_BAT              3
#define WEAPON_PISTOL           4
#define WEAPON_FLAREGUN         5
#define WEAPON_SHOTGUN          6
#define WEAPON_SMG              7
#define WEAPON_SYRINGEGUN       8
#define WEAPON_HUNTSMAN         9
#define WEAPON_SCATTERGUN       10
#define WEAPON_GRENADELAUNCHER  11
#define WEAPON_ROCKETLAUNCHER   12
#define WEAPON_STICKYLAUNCHER   13
#define WEAPON_FLAMETHROWER     14
#define WEAPON_MINIGUN          15
#define WEAPON_BONESAW          16
#define WEAPON_REVOLVER         17
#define WEAPON_SHOVEL           18

//#define DEBUG                   1

new g_iRanking[MAXPLAYERS+1] = 0;
new g_iDamageLife[MAXPLAYERS+1] = 0;
new g_iDeathCount[MAXPLAYERS+1] = 0;
new bool:g_bFixingUp[MAXPLAYERS+1] = false;
new bool:g_bAssist[MAXPLAYERS+1] = false;

new bool:g_bEnabled = true;
new bool:g_bRoundActive = true;
new bool:g_bAnnouncement[MAXPLAYERS+1] = false;

new Handle:g_hWeaponBat = INVALID_HANDLE;
new Handle:g_hWeaponFists = INVALID_HANDLE;
new Handle:g_hWeaponBottle = INVALID_HANDLE;
new Handle:g_hWeaponKnife = INVALID_HANDLE;
new Handle:g_hWeaponPistol = INVALID_HANDLE;
new Handle:g_hWeaponFlaregun = INVALID_HANDLE;
new Handle:g_hWeaponShotgun = INVALID_HANDLE;
new Handle:g_hWeaponSmg = INVALID_HANDLE;
new Handle:g_hWeaponSyringegun = INVALID_HANDLE;
new Handle:g_hWeaponHuntsman = INVALID_HANDLE;
new Handle:g_hWeaponScattergun = INVALID_HANDLE;
new Handle:g_hWeaponGrenadelauncher = INVALID_HANDLE;
new Handle:g_hWeaponRocketlauncher = INVALID_HANDLE;
new Handle:g_hWeaponStickylauncher = INVALID_HANDLE;
new Handle:g_hWeaponFlamethrower = INVALID_HANDLE;
new Handle:g_hWeaponMinigun = INVALID_HANDLE;

/*
new g_iGunGameList[] =
{
    WEAPON_FISTS,
    WEAPON_BAT,
    WEAPON_KNIFE,
    WEAPON_FLAREGUN,
    WEAPON_PISTOL,
    WEAPON_SHOTGUN,
    WEAPON_SYRINGEGUN,
    WEAPON_SMG,
    WEAPON_HUNTSMAN,
    WEAPON_SCATTERGUN,
    WEAPON_GRENADELAUNCHER,
    WEAPON_ROCKETLAUNCHER,
    WEAPON_STICKYLAUNCHER,
    WEAPON_FLAMETHROWER,
    WEAPON_MINIGUN,
    WEAPON_MINIGUN
};
*/


new g_iGunGameList[] =
{
    WEAPON_MINIGUN,
    WEAPON_FLAMETHROWER,
    WEAPON_STICKYLAUNCHER,
    WEAPON_ROCKETLAUNCHER,
    WEAPON_GRENADELAUNCHER,
    WEAPON_SCATTERGUN,
    WEAPON_HUNTSMAN,
    WEAPON_SMG,
    WEAPON_SYRINGEGUN,
    WEAPON_SHOTGUN,
    WEAPON_PISTOL,
    WEAPON_FLAREGUN,
    WEAPON_KNIFE,
    WEAPON_BAT,
    WEAPON_FISTS,
    WEAPON_MINIGUN
};

public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_NAME,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Check if the plugin is being run on the proper mod.
    decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
    if (!StrEqual(strModName, "tf"))
    {
        Format(error, err_max, "This plugin is only for Team Fortress 2.");
        return APLRes_Failure;
    }
    return APLRes_Success;
}

public OnPluginStart()
{
    SetupWeapons();
    
    HookEvent("player_spawn", EventPlayerSpawn);
    HookEvent("post_inventory_application", EventPlayerInventory);
    HookEvent("player_death", EventPlayerDeath);
    HookEvent("teamplay_round_start",EventRoundStart);
    HookEvent("teamplay_round_win",EventRoundWin);
    
    for (new i = 1; i <= MaxClients; i++)
    {
        GunGameReset(i);
        if (IsValidClient(i))
        {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
            if (IsPlayerAlive(i)) UpdateHud(i);
        }
        GunGameWeapons(i);
    }
    
    CreateConVar("tfgungame_version", PLUGIN_VERSION, "GunGame version", FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    RemoveFlags();
}

public OnMapStart()
{
    RemoveFlags();
}

public Action:EventPlayerSpawn(Handle:hEvent, const String:strName[], bool:bHidden)
{
    if (!g_bEnabled) return Plugin_Continue;
    
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));    
    if (!IsValidClient(iClient)) return Plugin_Continue;
    
    if (!g_bAnnouncement[iClient])
    {
        CPrintToChat(iClient, "{olive}Welcome to {green}GunGame{olive} by {blue}Mecha the Slag (Jonas Kaerlev){olive}!");
        g_bAnnouncement[iClient] = true;
    }
    
    #if defined DEBUG
    LogMessage("%N: EventPlayerSpawn PRE", iClient);
    #endif
    
    g_iDamageLife[iClient] = 0;
    GunGameWeapons(iClient);
    
    UpdateHud(iClient);
    CreateTimer(0.2, UpdateHudTimer, iClient);
    CreateTimer(1.0, UpdateHudTimer, iClient);
    CreateTimer(5.0, UpdateHudTimer, iClient);
    
    #if defined DEBUG
    LogMessage("%N: EventPlayerSpawn POST", iClient);
    #endif
    
    return Plugin_Continue;
}

public Action:EventPlayerInventory(Handle:hEvent, const String:strName[], bool:bHidden)
{
    if (!g_bEnabled) return Plugin_Continue;
    
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));    
    if (!IsValidClient(iClient)) return Plugin_Continue;
    if (!IsPlayerAlive(iClient)) return Plugin_Continue;
    if (g_bFixingUp[iClient]) return Plugin_Continue;
    
    #if defined DEBUG
    LogMessage("%N: EventPlayerInventory PRE", iClient);
    #endif
    
    UpdateHud(iClient);
    GunGameWeapons(iClient);
    
    #if defined DEBUG
    LogMessage("%N: EventPlayerInventory POST", iClient);
    #endif
    
    return Plugin_Continue;
}

public Action:EventPlayerDeath(Handle:hEvent, const String:strName[], bool:bHidden)
{
    if (!g_bEnabled) return Plugin_Continue;
    
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));    
    new iKiller = GetClientOfUserId(GetEventInt(hEvent, "attacker"));    
    new iAssistant = GetClientOfUserId(GetEventInt(hEvent, "assister"));    
    if (!IsValidClient(iClient)) return Plugin_Continue;
    
    GunGameDeath(iClient);
    UpdateHud(iClient);
    
    if (IsValidClient(iKiller) && iKiller != iClient) UpgradePlayer(iKiller);
    if (IsValidClient(iAssistant) && iAssistant != iClient && iAssistant != iKiller) 
    {
        if (g_bAssist[iAssistant])
        {
            g_bAssist[iAssistant] = false;
            UpgradePlayer(iAssistant);
        }
        else
        {
            g_bAssist[iAssistant] = true;
            UpdateHud(iAssistant);
        }
    }
    
    CreateTimer(8.0, RespawnPlayer, iClient);
    
    return Plugin_Continue;
}

public Action:RespawnPlayer(Handle:hTimer, any:iClient)
{
    if (!g_bRoundActive) return Plugin_Handled;
    if (!IsValidClient(iClient)) return Plugin_Handled;
    if (IsPlayerAlive(iClient)) return Plugin_Handled;
    
    TF2_RespawnPlayer(iClient);
    
    return Plugin_Handled;
}

public Action:EventRoundStart(Handle:hEvent, const String:strName[], bool:bHidden)
{
    if (!g_bEnabled) return Plugin_Continue;

    g_bRoundActive = true;
    
    for (new i = 1; i <= MaxClients; i++)
    {
        GunGameReset(i);
        GunGameWeapons(i);
        UpdateHud(i);
        if (IsValidClient(i) && IsPlayerAlive(i)) TF2_RegeneratePlayer(i);
        GunGameWeapons(i);
        UpdateHud(i);
    }
    
    
    RemoveFlags();
        
    return Plugin_Continue; 
}

public Action:EventRoundWin(Handle:hEvent, const String:strName[], bool:bHidden)
{
    if (!g_bEnabled) return Plugin_Continue;
    if (!g_bRoundActive) return Plugin_Continue;
    
    g_bRoundActive = false;
    
    return Plugin_Continue;
}

GunGameMaxRank()
{
    return sizeof(g_iGunGameList)-1;
}

public OnClientPostAdminCheck(iClient)
{
    GunGameReset(iClient);
    g_bAnnouncement[iClient] = false;
    SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(iClient, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType)
{
    if (!g_bEnabled) return Plugin_Continue;
    if (!g_bRoundActive) return Plugin_Continue;
    
    if (IsValidClient(iAttacker))
    {
        GunGameDealDamage(iAttacker, RoundFloat(fDamage));
        UpdateHud(iAttacker);
    }
    
    return Plugin_Continue;
}

stock DamageAtRank(iRank)
{
    return iRank*iRank*2 + 25;
}

/*
DamageUntilNextRank(iClient)
{
    new iRequired = DamageAtRank(g_iRanking[iClient]);
    new iDamage = iRequired - g_iDamageLife[iClient];
    if (iDamage < 0) iDamage = 1;
    return iDamage;
}
*/

GunGameDealDamage(iClient, iAmount)
{
    if (!g_bRoundActive) return;
    if (!IsValidClient(iClient)) return;
    if (!IsPlayerAlive(iClient)) return;
    
    g_iDamageLife[iClient] += iAmount;
    
    //if (g_iDamageLife[iClient] >= DamageAtRank(g_iRanking[iClient])) UpgradePlayer(iClient);
}

UpgradePlayer(iClient)
{
    if (!g_bRoundActive) return;
    // already won
    if (g_iRanking[iClient] >= GunGameMaxRank()) return;
    
    g_iDamageLife[iClient] = 0;
    g_iRanking[iClient]++;
    GunGameWeapons(iClient);
    ClientCommand(iClient, "playgamesound \"%s\"", SOUND_BELL);
    ClientCommand(iClient, "playgamesound \"%s\"", SOUND_BELL);
    
    g_iDeathCount[iClient] = 0;
    
    if (g_iRanking[iClient] >= GunGameMaxRank())
    {
        MakeTeamWin(GetClientTeam(iClient));
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(iClient) && i != iClient)
            {
                TF2_StunPlayer(i, 20.0, 0.2, TF_STUNFLAGS_LOSERSTATE, iClient);
            }
        }
        CPrintToChatAllEx(iClient, "{green}The winner is: {teamcolor}%N{green}!!", iClient);
    }
    else
    {
        CPrintToChat(iClient, "{olive}You upgraded to rank: {green}%d/%d", g_iRanking[iClient]+1, GunGameMaxRank());
        new iMax = GetMaxRank();
        if (g_iRanking[iClient] == iMax && GetRankCount(iMax) <= 1)
        {
            CPrintToChatAllEx(iClient, "{olive}In the lead is {teamcolor}%N{olive} with rank {green}%d{olive}", iClient, iMax+1);
        }
    }
    
    UpdateHud(iClient);
}

GunGameDeath(iClient)
{
    g_iDamageLife[iClient] = 0;
    g_iDeathCount[iClient]++;
    if (g_iDeathCount[iClient] >= 3)
    {
        g_iDeathCount[iClient] = 0;
        if (g_iRanking[iClient] > 0)
        {
            g_iRanking[iClient]--;
            CPrintToChat(iClient, "You've downgraded to: {green}%d/%d", g_iRanking[iClient]+1, GunGameMaxRank());
        }
    }
}

GunGameReset(iClient)
{
    g_iDamageLife[iClient] = 0;
    g_iRanking[iClient] = 0;
    g_iDeathCount[iClient] = 0;
    g_bFixingUp[iClient] = false;
    g_bAssist[iClient] = false;
}

bool:GunGameWeapons(iClient)
{
    if (!IsValidClient(iClient)) return true;
    if (!IsPlayerAlive(iClient)) return true;
    
    g_bFixingUp[iClient] = true;
    
    #if defined DEBUG
    LogMessage("%N: GunGameWeapons PRE", iClient);
    #endif
    
    new iWeapon = g_iGunGameList[g_iRanking[iClient]];
    
    FixUpClass(iClient, GetWeaponClass(iWeapon));
    
    TF2_RemoveAllWeapons(iClient);
    
    GunGameGiveWeapon(iClient, iWeapon);
    g_bFixingUp[iClient] = false;
    
    #if defined DEBUG
    LogMessage("%N: GunGameWeapons POST", iClient);
    #endif
    
    return true;
}

bool:FixUpClass(iClient, TFClassType:iDesiredClass)
{
    #if defined DEBUG
    LogMessage("%N: FixUpClass PRE", iClient);
    #endif
    new TFClassType:iClass = TF2_GetPlayerClass(iClient);
    if (iClass != iDesiredClass)
    {
        new iHealth = GetClientHealth(iClient);
        TF2_SetPlayerClass(iClient, iDesiredClass, false);
        TF2_RegeneratePlayer(iClient);
        if (iHealth < GetClientHealth(iClient)) SetEntityHealth(iClient, iHealth);
        SetVariantString("");
        AcceptEntityInput(iClient, "SetCustomModel");
        #if defined DEBUG
        LogMessage("%N: FixUpClass true POST", iClient);
        #endif
        return true;
    }
    #if defined DEBUG
    LogMessage("%N: FixUpClass false POST", iClient);
    #endif
    return false;
}

TFClassType:GetWeaponClass(iWeapon)
{
    if (iWeapon == WEAPON_BAT || iWeapon == WEAPON_SCATTERGUN) return TFClass_Scout;
    if (iWeapon == WEAPON_ROCKETLAUNCHER || iWeapon == WEAPON_SHOVEL) return TFClass_Soldier;
    if (iWeapon == WEAPON_FLAREGUN || iWeapon == WEAPON_FLAMETHROWER) return TFClass_Pyro;
    if (iWeapon == WEAPON_BOTTLE || iWeapon == WEAPON_GRENADELAUNCHER || iWeapon == WEAPON_STICKYLAUNCHER) return TFClass_DemoMan;
    if (iWeapon == WEAPON_FISTS || iWeapon == WEAPON_MINIGUN) return TFClass_Heavy;
    if (iWeapon == WEAPON_SHOTGUN || iWeapon == WEAPON_PISTOL) return TFClass_Engineer;
    if (iWeapon == WEAPON_SYRINGEGUN || iWeapon == WEAPON_BONESAW) return TFClass_Medic;
    if (iWeapon == WEAPON_SMG || iWeapon == WEAPON_HUNTSMAN) return TFClass_Sniper;
    if (iWeapon == WEAPON_KNIFE || iWeapon == WEAPON_REVOLVER) return TFClass_Spy;
    
    return TFClass_Scout;
}

GunGameGiveWeapon(iClient, iWeapon)
{
    if (iWeapon == WEAPON_BAT) GiveWeapon(iClient, g_hWeaponBat);
    else if (iWeapon == WEAPON_FISTS) GiveWeapon(iClient, g_hWeaponFists);
    else if (iWeapon == WEAPON_BOTTLE) GiveWeapon(iClient, g_hWeaponBottle);
    else if (iWeapon == WEAPON_KNIFE) GiveWeapon(iClient, g_hWeaponKnife);
    else if (iWeapon == WEAPON_PISTOL) GiveWeapon(iClient, g_hWeaponPistol);
    else if (iWeapon == WEAPON_FLAREGUN) GiveWeapon(iClient, g_hWeaponFlaregun);
    else if (iWeapon == WEAPON_SHOTGUN) GiveWeapon(iClient, g_hWeaponShotgun);
    else if (iWeapon == WEAPON_SMG) GiveWeapon(iClient, g_hWeaponSmg);
    else if (iWeapon == WEAPON_SYRINGEGUN) GiveWeapon(iClient, g_hWeaponSyringegun);
    else if (iWeapon == WEAPON_HUNTSMAN) GiveWeapon(iClient, g_hWeaponHuntsman);
    else if (iWeapon == WEAPON_SCATTERGUN) GiveWeapon(iClient, g_hWeaponScattergun);
    else if (iWeapon == WEAPON_GRENADELAUNCHER) GiveWeapon(iClient, g_hWeaponGrenadelauncher);
    else if (iWeapon == WEAPON_ROCKETLAUNCHER) GiveWeapon(iClient, g_hWeaponRocketlauncher);
    else if (iWeapon == WEAPON_STICKYLAUNCHER) GiveWeapon(iClient, g_hWeaponStickylauncher);
    else if (iWeapon == WEAPON_FLAMETHROWER) GiveWeapon(iClient, g_hWeaponFlamethrower);
    else if (iWeapon == WEAPON_MINIGUN) GiveWeapon(iClient, g_hWeaponMinigun);
}

SetupWeapons()
{
    // Stock
    g_hWeaponBat = CreateStockWeapon("tf_weapon_bat", 0);
    g_hWeaponFists = CreateStockWeapon("tf_weapon_fists", 5);
    g_hWeaponBottle = CreateStockWeapon("tf_weapon_bottle", 1);
    g_hWeaponKnife = CreateStockWeapon("tf_weapon_knife", 4);
    g_hWeaponPistol = CreateStockWeapon("tf_weapon_pistol", 22);
    g_hWeaponFlaregun = CreateStockWeapon("tf_weapon_flaregun", 39);
    g_hWeaponShotgun = CreateStockWeapon("tf_weapon_shotgun_primary", 9);
    g_hWeaponSmg = CreateStockWeapon("tf_weapon_smg", 16);
    g_hWeaponSyringegun = CreateStockWeapon("tf_weapon_syringegun_medic", 17);
    g_hWeaponHuntsman = CreateStockWeapon("tf_weapon_compound_bow", 56);
    g_hWeaponScattergun = CreateStockWeapon("tf_weapon_scattergun", 13);
    g_hWeaponGrenadelauncher = CreateStockWeapon("tf_weapon_pipebomblauncher", 20);
    g_hWeaponRocketlauncher = CreateStockWeapon("tf_weapon_rocketlauncher", 18);
    g_hWeaponStickylauncher = CreateStockWeapon("tf_weapon_grenadelauncher", 19);
    g_hWeaponFlamethrower = CreateStockWeapon("tf_weapon_flamethrower", 21);
    g_hWeaponMinigun = CreateStockWeapon("tf_weapon_minigun", 15);
}

Handle:CreateStockWeapon(String:strClassname[], iIndex)
{
    new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeapon, strClassname);
    TF2Items_SetItemIndex(hWeapon, iIndex);
    TF2Items_SetQuality(hWeapon, 0);
    TF2Items_SetNumAttributes(hWeapon, 0);
    
    return hWeapon;
}


stock bool:IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    return IsClientInGame(iClient);
}

GiveWeapon(iClient, Handle:hWeapon)
{
    if (hWeapon == INVALID_HANDLE) return -1;
    if (!IsValidClient(iClient)) return -1;
    if (!IsPlayerAlive(iClient)) return -1;
    
    #if defined DEBUG
    LogMessage("%N: GiveWeapon PRE", iClient);
    #endif
    new iWeapon = TF2Items_GiveNamedItem(iClient, hWeapon);
    EquipPlayerWeapon(iClient, iWeapon);
    #if defined DEBUG
    LogMessage("%N: GiveWeapon POST", iClient);
    #endif
    return iWeapon;
}

public MakeTeamWin(iWinner) {
    if (!g_bEnabled) return;
    if (!g_bRoundActive) return;

    new iEntity = GetControlPointMaster();
    if (IsValidEdict(iEntity)) {
        SetVariantInt(iWinner);
        AcceptEntityInput(iEntity, "SetWinner");
        g_bRoundActive = false;
    }
}

GetControlPointMaster() {
    new iControlMaster = FindEntityByClassname(-1, "team_control_point_master");
    if (iControlMaster == -1) {
        iControlMaster = CreateEntityByName("team_control_point_master");
        DispatchSpawn(iControlMaster);
        AcceptEntityInput(iControlMaster, "Enable");
    }
    return iControlMaster;
}

RemoveFlags()
{
    new iEntity = -1;
    while ((iEntity = FindEntityByClassname2(iEntity, "item_teamflag")) > 0)
    {
        if (IsClassname(iEntity, "item_teamflag")) RemoveEdict(iEntity);
    }
    
    iEntity = -1;
    while ((iEntity = FindEntityByClassname2(iEntity, "team_control_point")) > 0)
    {
        if (IsClassname(iEntity, "team_control_point")) RemoveEdict(iEntity);
    }
    
    iEntity = -1;
    while ((iEntity = FindEntityByClassname2(iEntity, "trigger_capture_area")) > 0)
    {
        if (IsClassname(iEntity, "trigger_capture_area")) RemoveEdict(iEntity);
    }
    
    iEntity = -1;
    while ((iEntity = FindEntityByClassname2(iEntity, "team_control_point_master")) > 0)
    {
        if (IsClassname(iEntity, "team_control_point_master")) RemoveEdict(iEntity);
    }
}

stock FindEntityByClassname2(startEnt, const String:classname[]) {
    /* If startEnt isn't valid shifting it back to the nearest valid one */
    while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
    return FindEntityByClassname(startEnt, classname);
}

stock bool:IsClassname(iEntity, String:strClassname[]) {
    if (iEntity <= 0) return false;
    if (!IsValidEdict(iEntity)) return false;
    
    decl String:strClassname2[32];
    GetEdictClassname(iEntity, strClassname2, sizeof(strClassname2));
    if (!StrEqual(strClassname, strClassname2, false)) return false;
    
    return true;
}

GetMaxRank()
{
    new iMax = -1;
    for (new i = 1; i <= MaxClients; i++)
    {
        if (g_iRanking[i] > iMax)
        {
            iMax = g_iRanking[i];
        }
    }
    return iMax;
}

GetRankCount(iValue)
{
    new iCount = 0;
    for (new i = 1; i <= MaxClients; i++)
    {
        if (g_iRanking[i] == iValue)
        {
            iCount++;
        }
    }
    return iCount;
}

public Action:UpdateHudTimer(Handle:hTimer, any:iClient)
{
    UpdateHud(iClient);
    return Plugin_Handled;
}

UpdateHud(iClient)
{
    if (!IsValidClient(iClient)) return;
    if (IsFakeClient(iClient)) return;
    
    SetHudTextParams(-1.0, 0.67, 100.0, 255, 255, 255, 255);
    if (g_iRanking[iClient] >= GunGameMaxRank())
    {
        ShowHudText(iClient, 1, "A winner is you!");
    }
    else
    {
        //ShowHudText(iClient, 1, "Rank %d/%d\nDamage to Rank: %d", g_iRanking[iClient]+1, GunGameMaxRank(), DamageUntilNextRank(iClient));
        new String:strAssist[128];
        if (g_bAssist[iClient]) Format(strAssist, sizeof(strAssist), "\nNext assist will upgrade");
        ShowHudText(iClient, 1, "Rank %d/%d%s", g_iRanking[iClient]+1, GunGameMaxRank(), strAssist);
    }
}