//──────────────────────────────────────────────────────────────────────────────
/*
    Copyright 2006-2014 AlliedModders LLC
    Copyright 2008-2009 Nicholas Hastings    
    Copyright 2007-2009 TTS Oetzel & Goerz GmbH
    Copyright 2008-2013 pheadxdll http://forums.alliedmods.net/member.php?u=38829
    Copyright 2012 X3Mano https://forums.alliedmods.net/member.php?u=170871
    Copyright 2013 Mitchell http://forums.alliedmods.net/member.php?u=74234
    Copyright 2013-2014 avi9526 <dromaretsky@gmail.com>
    Copyright 2013-2014 FlaminSarge http://forums.alliedmods.net/member.php?u=84304
	ver 3.0.0 in 2024 UPDATED BY [ AKSEL ] https://steamcommunity.com/id/Aksel911/
*/
//──────────────────────────────────────────────────────────────────────────────
/*
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
//──────────────────────────────────────────────────────────────────────────────
#pragma semicolon 1
#pragma newdecls required

//──────────────────────────────────────────────────────────────────────────────
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
//──────────────────────────────────────────────────────────────────────────────
#define PLUGIN_VERSION "3.0.0"
//──────────────────────────────────────────────────────────────────────────────
// Amount of effects
#define EFFECTS     21
// Flags used for separating spells and canteen charges
// Increment is NOT +1, but binary shifting
#define SPELL      1   // spell
#define CHARGE     2   // canteen charge
#define BUILD      4   // building
#define ALL        7   // any
// Spell codes
// Currently not all spells used
#define FIREBALL    0
#define BATS        1
//#define PUMPKIN     2   // not working properly
#define TELE        3
#define LIGHTNING   4
#define BOSS        5
#define METEOR      6
//#define ZOMBIEH     7   // not working properly
#define ZOMBIE      8
//#define PUMPKIN2    9   // useless
// Canteen charge codes
#define UBER        0   // uber charge
#define CRIT        1   // critical charge
#define REGEN      2   // refill ammo and health
#define INVIS      3   // become invisible
#define BASE       4   // teleport to base
#define SPEED      5   // super speed
#define HEAL       6   // add health
// Building codes
#define SENTRY1    0   // sentry level 1
#define SENTRY2    1   // sentry level 2
#define SENTRY3    2   // sentry level 3
#define SENTRYMIN  3   // sentry mini
#define DISP       4   // dispenser
#define KILLAIM    5   // kill building at aim
#define KILLBUILD  6   // kill all owned buildings
//──────────────────────────────────────────────────────────────────────────────
// Some codes
#define READY      0   // effect is ready
#define LIMIT      -1  // limit reached
#define DISABLED   -2  // effect disabled
// Max used strings length
#define STR_LEN    128
// Admin flag
#define ADMFLAG_NONE    0
//──────────────────────────────────────────────────────────────────────────────
#define LOG_PREFIX      "[Effects]"
#define TAG             "effects"
#define CHAT_PREFIX     "\x01[\x07B262FFEffects\x01]"
#define SPELL_PREFIX    "\x01[\x07B262FFSpells\x01]"
#define CHARGE_PREFIX   "\x01[\x07B262FFCanteen\x01]"
#define BUILD_PREFIX    "\x01[\x07B262FFBuilding\x01]"
//──────────────────────────────────────────────────────────────────────────────
// Non-existent commands to check who is admin and who is premium and etc.
#define CMD_ADMIN       "sm_effects_admin"
#define CMD_PREMIUM     "sm_effects_premium"
#define CMD_ACCESS      "sm_effects_access"
//──────────────────────────────────────────────────────────────────────────────

public Plugin myinfo = 
{
    name = "[TF2] Effects",
    author = "avi9526. See source code for more details",
    description = "Allows players to use some effects",
    version = PLUGIN_VERSION,
    url = "/dev/null"
};

//──────────────────────────────────────────────────────────────────────────────
// Global variables
//──────────────────────────────────────────────────────────────────────────────
ConVar g_hVersion;
// Used to limit amount of buildings
int g_BuildLimit;
ConVar g_hBuildLimit;
// Allow to lower wait times for admins and privileged players
// Premium player wait time multiplier (recommended value 0..1)
float g_WaitMultPrem;
ConVar g_hWaitMultPrem;
// Admin player wait time multiplier (recommended value 0..1)
float g_WaitMultAdmin;
ConVar g_hWaitMultAdmin;

// Store individual player data needed to plugin
enum struct PlayerData {
    int TimeUsed[EFFECTS];    // when player last time used spell
}

// Effect info
enum struct Effect {
    // Identifier
    int ID;
    // Group ID (for separation of spells and canteen charges)
    int GID;
    // Name
    char Name[STR_LEN];
    // Description
    char Desc[STR_LEN];
    // Global Handle Console Variable - Delay
    ConVar hDelay;
    // Delay
    int Delay;
    // CVar name
    char DelayCVar[STR_LEN];
}

// Arrays that store info
PlayerData g_Players[MAXPLAYERS + 1];
Effect g_Effects[EFFECTS];

//──────────────────────────────────────────────────────────────────────────────
// Hook functions
//──────────────────────────────────────────────────────────────────────────────
public void OnPluginStart()
{
    g_hVersion = CreateConVar("sm_effects_version", PLUGIN_VERSION, "Effects Version", FCVAR_NOTIFY);
    if(g_hVersion != null)
    {
        g_hVersion.SetString(PLUGIN_VERSION);
    }
    
    InitEffectsData();
    
    for(int i = 0; i < EFFECTS; i++)
    {
        g_Effects[i].hDelay = CreateConVar(g_Effects[i].DelayCVar, "60", "How much player must wait before use effect again", _, true, -1.0, false, 100.0);
        g_Effects[i].Delay = g_Effects[i].hDelay.IntValue;
        g_Effects[i].hDelay.AddChangeHook(OnConVarChanged);
    }
    
    g_hBuildLimit = CreateConVar("sm_buildlimit", "1", "Limit amount of one kind of building that are available for player", _, true, 1.0, true, 100.0);
    g_BuildLimit = g_hBuildLimit.IntValue;
    g_hBuildLimit.AddChangeHook(OnConVarChanged);
    
    g_hWaitMultAdmin = CreateConVar("sm_waitmult_admin", "0.5", "Admin players wait time multiplier for effects", _, true, 0.0, true, 10.0);
    g_WaitMultAdmin = g_hWaitMultAdmin.FloatValue;
    g_hWaitMultAdmin.AddChangeHook(OnConVarChanged);
    
    g_hWaitMultPrem = CreateConVar("sm_waitmult_premium", "0.75", "Premium players wait time multiplier for effects", _, true, 0.0, true, 10.0);
    g_WaitMultPrem = g_hWaitMultPrem.FloatValue;
    g_hWaitMultPrem.AddChangeHook(OnConVarChanged);
    
    // Effects menu
    RegConsoleCmd("sm_spells", Command_Menu, "Spells menu");
    RegConsoleCmd("sm_spell", Command_Menu, "Spells menu");
    RegConsoleCmd("sm_canteen", Command_Menu, "Canteen charges menu");
    RegConsoleCmd("sm_build", Command_Menu, "Building menu");
    RegConsoleCmd("sm_effects", Command_MainMenu, "Spells and Canteen charges menu");
    RegConsoleCmd("sm_effect", Command_MainMenu, "Spells and Canteen charges menu");
}

//──────────────────────────────────────────────────────────────────────────────
public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if(convar == g_hBuildLimit)
    {
        g_BuildLimit = StringToInt(newValue);
        LogAction(-1, -1, "%s %s now is %d", LOG_PREFIX, "sm_buildlimit", g_BuildLimit);
    }
    else if(convar == g_hWaitMultAdmin)
    {
        g_WaitMultAdmin = StringToFloat(newValue);
        LogAction(-1, -1, "%s %s now is %f", LOG_PREFIX, "sm_waitmult_admin", g_WaitMultAdmin);
    }
    else if(convar == g_hWaitMultPrem)
    {
        g_WaitMultPrem = StringToFloat(newValue);
        LogAction(-1, -1, "%s %s now is %f", LOG_PREFIX, "sm_waitmult_premium", g_WaitMultPrem);
    }
    else
    {
        for(int i = 0; i < EFFECTS; i++)
        {
            if(convar == g_Effects[i].hDelay)
            {
                g_Effects[i].Delay = StringToInt(newValue);
                LogAction(-1, -1, "%s %s now is %d", LOG_PREFIX, g_Effects[i].DelayCVar, g_Effects[i].Delay);
            }
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────
public void OnPluginEnd()
{
    ResetAllData();
}

//──────────────────────────────────────────────────────────────────────────────
public void OnMapStart()
{
    ResetAllData();
}

//──────────────────────────────────────────────────────────────────────────────
public void OnClientConnected(int client)
{
    ResetPlayerData(client);
}

//──────────────────────────────────────────────────────────────────────────────
public void OnClientDisconnect(int client)
{
    KillAllDisp(client);
    KillAllSentry(client);
    ResetPlayerData(client);
}

//──────────────────────────────────────────────────────────────────────────────
// Stocks
//──────────────────────────────────────────────────────────────────────────────
// This function returns particle entity reference
stock int ParticleCreate(
    const char[] NameID,                   // unique particle name
    float Position[3] = {0.0, 0.0, 0.0},   // position to spawn (relative to parent if exist)
    float LifeTime = 0.0,                  // life time of particle
    int ParentEntity = 0,                  // parent entity
    bool SetParent = true,                 // if false - parent used only to calculate relative position     
    const char[] AttachTo = ""             // name of part of parent entity where attach particle
)
{
    bool HasParent = false;    // store fact of parent entity presence
    bool Result = true;        // error flag
    int Particle = 0;         // store particle entity ID
    float SpawnPos[3] = {0.0, 0.0, 0.0};   // store position where particle should be spawned
    float SpawnAng[3] = {0.0, 0.0, 0.0};   // store angles for spawn
    int Ref = INVALID_ENT_REFERENCE;        // store reference for created particle entity
    
    // Check parameters
    if (ParentEntity > 0)    
    {
        HasParent = true;    
        Result &= IsValidEntity(ParentEntity);    
    }
    
    if (LifeTime < 0.0)    
    {
        Result = false;
    }
    
    // Create particle
    if (Result)    
    {
        if (HasParent)
        {
            GetEntPropVector(ParentEntity, Prop_Send, "m_vecOrigin", SpawnPos);
            GetEntPropVector(ParentEntity, Prop_Send, "m_angRotation", SpawnAng);
            SpawnPos[0] += Position[0];
            SpawnPos[1] += Position[1];
            SpawnPos[2] += Position[2];
        }
        else
        {
            SpawnPos = Position;
        }
        
        Particle = CreateEntityByName("info_particle_system");
        
        TeleportEntity(Particle, SpawnPos, SpawnAng, NULL_VECTOR);
        
        DispatchKeyValue(Particle, "effect_name", NameID);
        DispatchSpawn(Particle);
        
        if (HasParent && SetParent)
        {
            SetVariantString("!activator");
            AcceptEntityInput(Particle, "SetParent", ParentEntity);
            
            if (strlen(AttachTo) > 0)
            {
                SetVariantString(AttachTo);
                AcceptEntityInput(Particle, "SetParentAttachmentMaintainOffset");
            }
        }
        
        ActivateEntity(Particle);
        AcceptEntityInput(Particle, "start");
        
        Ref = EntIndexToEntRef(Particle);
        
        if (LifeTime > 0.0)
        {
            CreateTimer(LifeTime, Timer_DeleteParticle, Ref);
        }
    }
    
    return Ref;
}

//──────────────────────────────────────────────────────────────────────────────
stock void ParticleDestroy(int Refer)
{
    int Particle = EntRefToEntIndex(Refer);
    if(Particle > MaxClients && IsValidEntity(Particle))
    {
        AcceptEntityInput(Particle, "Kill");
    }
}

//──────────────────────────────────────────────────────────────────────────────
public Action Timer_DeleteParticle(Handle timer, any EntRef)
{
	ParticleDestroy(EntRef);
    return Plugin_Handled;
}

//──────────────────────────────────────────────────────────────────────────────
stock void DecorHeal(int Client)
{
    if (IsPlayerAlive(Client))
    {
        int Team = GetClientTeam(Client);
        if (Team == view_as<int>(TFTeam_Red))
        {
            ParticleCreate("spell_overheal_red", _, 0.0, Client);
        }
        if (Team == view_as<int>(TFTeam_Blue))
        {
            ParticleCreate("spell_overheal_blue", _, 0.0, Client);
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────
stock void DecorSpell(int Client)
{
    if (IsPlayerAlive(Client))
    {
        int Team = GetClientTeam(Client);
        if (Team == view_as<int>(TFTeam_Red))
        {
            ParticleCreate("spell_cast_wheel_red", _, 0.0, Client);
        }
        if (Team == view_as<int>(TFTeam_Blue))
        {
            ParticleCreate("spell_cast_wheel_blue", _, 0.0, Client);
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────
stock void DecorBuild(int Ent)
{
    if (Ent > MaxClients && IsValidEntity(Ent))
    {
        char ClassName[STR_LEN];
        GetEntityClassname(Ent, ClassName, STR_LEN);
        if(StrEqual(ClassName, "obj_dispenser") || StrEqual(ClassName, "obj_sentrygun"))
        {
            ParticleCreate("heavy_ring_of_fire_fp_child03", _, 2.0, Ent);
            int Team = GetEntProp(Ent, Prop_Send, "m_iTeamNum");
            if (Team == view_as<int>(TFTeam_Red))
            {
                ParticleCreate("teleportedin_red", _, 0.0, Ent);
                ParticleCreate("player_recent_teleport_red", _, 1.5, Ent);
            }
            if (Team == view_as<int>(TFTeam_Blue))
            {
                ParticleCreate("teleportedin_blue", _, 0.0, Ent);
                ParticleCreate("player_recent_teleport_blue", _, 1.5, Ent);
            }
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────
stock void DecorBuildKill(int Ent)
{
    if (Ent > MaxClients && IsValidEntity(Ent))
    {
        char ClassName[STR_LEN];
        GetEntityClassname(Ent, ClassName, STR_LEN);
        if(StrEqual(ClassName, "obj_dispenser") || StrEqual(ClassName, "obj_sentrygun"))
        {
            ParticleCreate("bot_death", _, 0.0, Ent, false);
            int Team = GetEntProp(Ent, Prop_Send, "m_iTeamNum");
            if (Team == view_as<int>(TFTeam_Red))
            {
                ParticleCreate("teleported_red", _, 0.0, Ent, false);
                ParticleCreate("player_recent_teleport_red", _, 0.5, Ent, false);
            }
            if (Team == view_as<int>(TFTeam_Blue))
            {
                ParticleCreate("teleported_blue", _, 0.0, Ent, false);
                ParticleCreate("player_recent_teleport_blue", _, 0.5, Ent, false);
            }
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────
public bool TraceFilterIgnorePlayers(int entity, int contentsMask, any client)
{
    return (entity <= 0 || entity > MaxClients);
}

//──────────────────────────────────────────────────────────────────────────────
stock void GetClientEyeTraceVec(int Client, float Position[3], float Angle[3])
{
    float flEndPos[3];
    float flPos[3];
    float flAng[3];
    GetClientEyePosition(Client, flPos);
    GetClientEyeAngles(Client, flAng);
    Handle hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Client);
    if(hTrace != null && TR_DidHit(hTrace))
    {
        TR_GetEndPosition(flEndPos, hTrace);
        flEndPos[2] += 0.1;
    }
    delete hTrace;
    
    Position = flEndPos;
    Angle = flAng;
}

//──────────────────────────────────────────────────────────────────────────────
stock void BuildSentry(int iBuilder, float fOrigin[3], float fAngle[3], int iLevel, bool bMini = false)
{
    fAngle[0] = 0.0;
    char sModel[64];
    int iTeam = GetClientTeam(iBuilder);

    int iShells, iHealth, iRockets;
    switch (iLevel)
    {
        case 1:
        {
            sModel = "models/buildables/sentry1.mdl";
            iShells = 100;
            iHealth = 150;
            if (bMini)
            {
                iShells = 100;
                iHealth = 100;
            }
        }
        case 2:
        {
            sModel = "models/buildables/sentry2.mdl";
            iShells = 120;
            iHealth = 180;
            if (bMini)
            {
                iShells = 120;
                iHealth = 120;
            }
        }
        case 3:
        {
            sModel = "models/buildables/sentry3.mdl";
            iShells = 144;
            iHealth = 216;
            iRockets = 20;
            if (bMini)
            {
                iShells = 144;
                iHealth = 180;
                iRockets = 20;
            }
        }
    }

    int entity = CreateEntityByName("obj_sentrygun");
    if (entity < MaxClients || !IsValidEntity(entity)) return;
    
    DispatchSpawn(entity);
    TeleportEntity(entity, fOrigin, fAngle, NULL_VECTOR);
    SetEntityModel(entity, sModel);

    SetEntProp(entity, Prop_Send, "m_iAmmoShells", iShells);
    SetEntProp(entity, Prop_Send, "m_iHealth", iHealth);
    SetEntProp(entity, Prop_Send, "m_iMaxHealth", iHealth);
    SetEntProp(entity, Prop_Send, "m_iObjectType", view_as<int>(TFObject_Sentry));

    SetEntProp(entity, Prop_Send, "m_iTeamNum", iTeam);
    int iSkin = iTeam - 2;
    if (bMini && iLevel == 1)
    {
        iSkin = iTeam;
    }

    SetEntProp(entity, Prop_Send, "m_nSkin", iSkin);
    SetEntProp(entity, Prop_Send, "m_iUpgradeLevel", iLevel);
    SetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
    SetEntProp(entity, Prop_Send, "m_iAmmoRockets", iRockets);

    SetEntPropEnt(entity, Prop_Send, "m_hBuilder", iBuilder);

    SetEntProp(entity, Prop_Send, "m_iState", 3);
    SetEntPropFloat(entity, Prop_Send, "m_flPercentageConstructed", iLevel == 1 ? 0.99 : 1.0);
    if (iLevel == 1) SetEntProp(entity, Prop_Send, "m_bBuilding", 1);
    SetEntProp(entity, Prop_Send, "m_bPlayerControlled", 1);
    SetEntProp(entity, Prop_Send, "m_bHasSapper", 0);
    
    float vecMaxs[3] = { 24.0, 24.0, 66.0 };
    float vecMins[3] = { -24.0, -24.0, 0.0 };
    SetEntPropVector(entity, Prop_Send, "m_vecBuildMaxs", vecMaxs);
    SetEntPropVector(entity, Prop_Send, "m_vecBuildMins", vecMins);
    
    if (bMini)
    {
        SetEntProp(entity, Prop_Send, "m_bMiniBuilding", 1);
        SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.75);
    }

    int offs = FindSendPropInfo("CObjectSentrygun", "m_iDesiredBuildRotations"); //2608
    if (offs > 0)
    {
        SetEntData(entity, offs-12, 1, 1, true);
    }
    
    Event event = CreateEvent("player_builtobject");
    if (event != null)
    {
        event.SetInt("userid", GetClientUserId(iBuilder));
        event.SetInt("index", entity);
        event.Fire();
    }
    
    DecorBuild(entity);
}

//──────────────────────────────────────────────────────────────────────────────
stock void BuildDispenser(int iBuilder, float flOrigin[3], float flAngles[3], int iLevel)
{
    char strModel[100];
    flAngles[0] = 0.0;
    
    int iTeam = GetClientTeam(iBuilder);
    int iHealth;
    int iAmmo = 400;
    switch (iLevel)
    {
        case 3:
        {
            strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl3.mdl");
            iHealth = 216;
        }
        case 2:
        {
            strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl2.mdl");
            iHealth = 180;
        }
        default:
        {
            strcopy(strModel, sizeof(strModel), "models/buildables/dispenser.mdl");
            iHealth = 150;
        }
    }

    int entity = CreateEntityByName("obj_dispenser");
    if (entity < MaxClients || !IsValidEntity(entity)) return;
    
    DispatchSpawn(entity);
    TeleportEntity(entity, flOrigin, flAngles, NULL_VECTOR);

    SetVariantInt(iTeam);
    AcceptEntityInput(entity, "TeamNum");
    SetVariantInt(iTeam);
    AcceptEntityInput(entity, "SetTeam");

    ActivateEntity(entity);

    SetEntProp(entity, Prop_Send, "m_iAmmoMetal", iAmmo);
    SetEntProp(entity, Prop_Send, "m_iHealth", iHealth);
    SetEntProp(entity, Prop_Send, "m_iMaxHealth", iHealth);
    SetEntProp(entity, Prop_Send, "m_iObjectType", view_as<int>(TFObject_Dispenser));
    SetEntProp(entity, Prop_Send, "m_iTeamNum", iTeam);
    SetEntProp(entity, Prop_Send, "m_nSkin", iTeam-2);
    SetEntProp(entity, Prop_Send, "m_iUpgradeLevel", iLevel);
    SetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
    SetEntProp(entity, Prop_Send, "m_iState", 3);
    
    float vecMaxs[3] = { 24.0, 24.0, 55.0 };
    float vecMins[3] = { -24.0, -24.0, 0.0 };
    SetEntPropVector(entity, Prop_Send, "m_vecBuildMaxs", vecMaxs);
    SetEntPropVector(entity, Prop_Send, "m_vecBuildMins", vecMins);
    
    SetEntPropFloat(entity, Prop_Send, "m_flPercentageConstructed", iLevel == 1 ? 0.99 : 1.0);
    if (iLevel == 1) SetEntProp(entity, Prop_Send, "m_bBuilding", 1);
    SetEntPropEnt(entity, Prop_Send, "m_hBuilder", iBuilder);
    SetEntityModel(entity, strModel);
    
    int offs = FindSendPropInfo("CObjectDispenser", "m_iDesiredBuildRotations"); //2608
    if (offs > 0)
    {
        SetEntData(entity, offs-12, 1, 1, true);
    }
    
    Event event = CreateEvent("player_builtobject");
    if (event != null)
    {
        event.SetInt("userid", GetClientUserId(iBuilder));
        event.SetInt("index", entity);
        event.Fire();
    }
    
    DecorBuild(entity);
}

//──────────────────────────────────────────────────────────────────────────────
stock void KillAllSentry(int Client)
{
    int Ent = -1;
    while((Ent = FindEntityByClassname(Ent, "obj_sentrygun")) != -1)
    {
        if(GetEntPropEnt(Ent, Prop_Send, "m_hBuilder") == Client)
        {
            DecorBuildKill(Ent);
            AcceptEntityInput(Ent, "Kill");
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────
stock bool KillAim(int Client)
{
    bool Result = false;
    int Ent = GetClientAimTarget(Client, false);
    char ClassName[STR_LEN];

    if(IsValidEntity(Ent))
    {
        GetEntityClassname(Ent, ClassName, STR_LEN);
        if(StrEqual(ClassName, "obj_dispenser") || StrEqual(ClassName, "obj_sentrygun"))
        {
            if(GetEntPropEnt(Ent, Prop_Send, "m_hBuilder") == Client)
            {
                DecorBuildKill(Ent);
                AcceptEntityInput(Ent, "Kill");
                Result = true;
            }
            else
            {
                ReplyToCommand(Client, "%s This building is not yours!", CHAT_PREFIX);
            }
        }
        else
        {
            ReplyToCommand(Client, "%s Not a building", CHAT_PREFIX);
        }
    }
    else
    {
        ReplyToCommand(Client, "%s No building found at aim", CHAT_PREFIX);
    }
    return Result;
}

//──────────────────────────────────────────────────────────────────────────────
stock void KillAllDisp(int Client)
{
    int Ent = -1;
    while((Ent = FindEntityByClassname(Ent, "obj_dispenser")) != -1)
    {
        if(GetEntPropEnt(Ent, Prop_Send, "m_hBuilder") == Client)
        {
            DecorBuildKill(Ent);
            AcceptEntityInput(Ent, "Kill");
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────
stock int CountAllSentry(int Client)
{
    int index = -1;
    int Count = 0;
    while((index = FindEntityByClassname(index, "obj_sentrygun")) != -1)
    {
        if(GetEntPropEnt(index, Prop_Send, "m_hBuilder") == Client)
        {
            Count++;
        }
    }
    return Count;
}

//──────────────────────────────────────────────────────────────────────────────
stock int CountAllDisp(int Client)
{
    int index = -1;
    int Count = 0;
    while((index = FindEntityByClassname(index, "obj_dispenser")) != -1)
    {
        if(GetEntPropEnt(index, Prop_Send, "m_hBuilder") == Client)
        {
            Count++;
        }
    }
    return Count;
}

//──────────────────────────────────────────────────────────────────────────────
stock bool IsValidClient(int Client)
{
    if ((Client <= 0) || (Client > MaxClients) || (!IsClientInGame(Client)))
    {
        return false;
    }
    
    if (IsClientSourceTV(Client) || IsClientReplay(Client))
    {
        return false;
    }
    
    return true;
}

//──────────────────────────────────────────────────────────────────────────────
stock bool IsValidBot(int Client)
{
    if(!IsValidClient(Client))
    {
        return false;
    }
    
    if(GetClientTeam(Client) <= 1)    // unassigned or spectators
    {
        return false;
    }
    
    return IsFakeClient(Client);
}

//──────────────────────────────────────────────────────────────────────────────
stock float GetMult(int Client)
{
    float Result = 1.0;
    if (CheckCommandAccess(Client, CMD_ADMIN, ADMFLAG_ROOT, true))
    {
        Result = g_WaitMultAdmin;
    }
    else if (CheckCommandAccess(Client, CMD_PREMIUM, ADMFLAG_ROOT, true))
    {
        Result = g_WaitMultPrem;
    }
    return Result;
}

//──────────────────────────────────────────────────────────────────────────────
stock int IsEffectReady(int client, int Index, float Mult = 1.0)
{
    int Result = READY;
        
    // How much time passed since last use of effect
    int TimePass = GetTime() - g_Players[client].TimeUsed[Index];
    if(g_Players[client].TimeUsed[Index] && TimePass < g_Effects[Index].Delay)
    {
        // If time passed is less than delay - tell player to wait more
        Result = RoundToNearest(float(g_Effects[Index].Delay) * Mult) - TimePass;
        // Avoid errors with negative values here
        if (Result < 0)
        {
            Result = 0;
        }
    }
    
    // If effect is sentry or dispenser building - then check how many buildings player own already
    int Count = 0;
    if(g_Effects[Index].GID == BUILD)
    {
        if(g_Effects[Index].ID == SENTRY1 || g_Effects[Index].ID == SENTRY2 || g_Effects[Index].ID == SENTRY3 || g_Effects[Index].ID == SENTRYMIN)
        {
            Count = CountAllSentry(client);
        }
        else if(g_Effects[Index].ID == DISP)
        {
            Count = CountAllDisp(client);
        }
    }
    if(Count != 0 && Count >= g_BuildLimit)
    {
        Result = LIMIT;
    }
    
    // Check if effect enabled
    if(g_Effects[Index].Delay < 0)
    {
        Result = DISABLED;
    }
    
    return Result;
}

//──────────────────────────────────────────────────────────────────────────────
void PrintHelp(int Client)
{
    PrintToChat(Client, "%s Write \x07FFA500!spells\x01 or \x07FFA500!canteen\x01 or \x07FFA500!build\x01 or \x07FFA500!effects\x01 for menu", CHAT_PREFIX);
    PrintToChat(Client, "Or use following names with any of commands above");
    for(int Index = 0; Index < EFFECTS; Index++)
    {
        PrintToChat(Client, "\x07FFA500%s\x01 - «%s»", g_Effects[Index].Name, g_Effects[Index].Desc);
    }
}

//──────────────────────────────────────────────────────────────────────────────
void InitEffectsData()
{
    int i = 0;
    
    // Amount of this effects must be stored in EFFECTS constant
    
    // Spells
    
    g_Effects[i].ID = TELE;
    g_Effects[i].GID = SPELL;
    g_Effects[i].Delay = 1;
    strcopy(g_Effects[i].Name, STR_LEN, "transpose");
    strcopy(g_Effects[i].Desc, STR_LEN, "Transpose");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_spelldelay_transpose");
    i++;
    
    g_Effects[i].ID = FIREBALL;
    g_Effects[i].GID = SPELL;
    g_Effects[i].Delay = 10;
    strcopy(g_Effects[i].Name, STR_LEN, "fireball");
    strcopy(g_Effects[i].Desc, STR_LEN, "Fireball");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_spelldelay_fireball");
    i++;
    
    g_Effects[i].ID = BATS;
    g_Effects[i].GID = SPELL;
    g_Effects[i].Delay = 12;
    strcopy(g_Effects[i].Name, STR_LEN, "bats");
    strcopy(g_Effects[i].Desc, STR_LEN, "Bats");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_spelldelay_bats");
    i++;
    
    g_Effects[i].ID = LIGHTNING;
    g_Effects[i].GID = SPELL;
    g_Effects[i].Delay = 45;
    strcopy(g_Effects[i].Name, STR_LEN, "lightning");
    strcopy(g_Effects[i].Desc, STR_LEN, "Lightning");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_spelldelay_lightning");
    i++;
    
    g_Effects[i].ID = ZOMBIE;
    g_Effects[i].GID = SPELL;
    g_Effects[i].Delay = 55;
    strcopy(g_Effects[i].Name, STR_LEN, "skeleton");
    strcopy(g_Effects[i].Desc, STR_LEN, "Skeleton");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_spelldelay_skeleton");
    i++;
    
    g_Effects[i].ID = BOSS;
    g_Effects[i].GID = SPELL;
    g_Effects[i].Delay = 240;
    strcopy(g_Effects[i].Name, STR_LEN, "monoculus");
    strcopy(g_Effects[i].Desc, STR_LEN, "Monoculus");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_spelldelay_monoculus");
    i++;
    
    g_Effects[i].ID = METEOR;
    g_Effects[i].GID = SPELL;
    g_Effects[i].Delay = 180;
    strcopy(g_Effects[i].Name, STR_LEN, "meteors");
    strcopy(g_Effects[i].Desc, STR_LEN, "Meteor Shower");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_spelldelay_meteors");
    i++;
    
    // Canteen
    
    g_Effects[i].ID = UBER;
    g_Effects[i].GID = CHARGE; 
    g_Effects[i].Delay = 60;
    strcopy(g_Effects[i].Name, STR_LEN, "uber");
    strcopy(g_Effects[i].Desc, STR_LEN, "Uber Charge");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_chargedelay_uber");
    i++;
    
    g_Effects[i].ID = CRIT;
    g_Effects[i].GID = CHARGE;
    g_Effects[i].Delay = 75;
    strcopy(g_Effects[i].Name, STR_LEN, "crit");
    strcopy(g_Effects[i].Desc, STR_LEN, "Critical Charge");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_chargedelay_crit");
    i++;
    
    g_Effects[i].ID = REGEN;
    g_Effects[i].GID = CHARGE;
    g_Effects[i].Delay = 100;
    strcopy(g_Effects[i].Name, STR_LEN, "regen");
    strcopy(g_Effects[i].Desc, STR_LEN, "Refill Ammo and Health");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_chargedelay_regen");
    i++;
    
    g_Effects[i].ID = INVIS;
    g_Effects[i].GID = CHARGE;
    g_Effects[i].Delay = 15;
    strcopy(g_Effects[i].Name, STR_LEN, "cloak");
    strcopy(g_Effects[i].Desc, STR_LEN, "Cloak");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_chargedelay_cloak");
    i++;
    
    g_Effects[i].ID = BASE;
    g_Effects[i].GID = CHARGE;
    g_Effects[i].Delay = 25;
    strcopy(g_Effects[i].Name, STR_LEN, "base");
    strcopy(g_Effects[i].Desc, STR_LEN, "Teleport to the Base");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_chargedelay_base");
    i++;
    
    g_Effects[i].ID = SPEED;
    g_Effects[i].GID = CHARGE;
    g_Effects[i].Delay = 35;
    strcopy(g_Effects[i].Name, STR_LEN, "speed");
    strcopy(g_Effects[i].Desc, STR_LEN, "Speed-up");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_chargedelay_speed");
    i++;
    
    g_Effects[i].ID = HEAL;
    g_Effects[i].GID = CHARGE;
    g_Effects[i].Delay = 520;
    strcopy(g_Effects[i].Name, STR_LEN, "heal");
    strcopy(g_Effects[i].Desc, STR_LEN, "Add Health");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_chargedelay_heal");
    i++;
    
    // Building
    
    g_Effects[i].ID = SENTRY1;
    g_Effects[i].GID = BUILD;
    g_Effects[i].Delay = 15;
    strcopy(g_Effects[i].Name, STR_LEN, "sentry1");
    strcopy(g_Effects[i].Desc, STR_LEN, "Build Sentry Level 1");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_builddelay_sentry1");
    i++;
    
    g_Effects[i].ID = SENTRY2;
    g_Effects[i].GID = BUILD;
    g_Effects[i].Delay = 30;
    strcopy(g_Effects[i].Name, STR_LEN, "sentry2");
    strcopy(g_Effects[i].Desc, STR_LEN, "Build Sentry Level 2");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_builddelay_sentry2");
    i++;
    
    g_Effects[i].ID = SENTRY3;
    g_Effects[i].GID = BUILD;
    g_Effects[i].Delay = 60;
    strcopy(g_Effects[i].Name, STR_LEN, "sentry3");
    strcopy(g_Effects[i].Desc, STR_LEN, "Build Sentry Level 3");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_builddelay_sentry3");
    i++;
    
    g_Effects[i].ID = SENTRYMIN;
    g_Effects[i].GID = BUILD;
    g_Effects[i].Delay = 15;
    strcopy(g_Effects[i].Name, STR_LEN, "sentrymini");
    strcopy(g_Effects[i].Desc, STR_LEN, "Build Sentry Mini");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_builddelay_sentrymini");
    i++;
    
    g_Effects[i].ID = DISP;
    g_Effects[i].GID = BUILD;
    g_Effects[i].Delay = 10;
    strcopy(g_Effects[i].Name, STR_LEN, "disp");
    strcopy(g_Effects[i].Desc, STR_LEN, "Build Dispenser");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_builddelay_disp");
    i++;
    
    g_Effects[i].ID = KILLAIM;
    g_Effects[i].GID = BUILD;
    g_Effects[i].Delay = 1;
    strcopy(g_Effects[i].Name, STR_LEN, "killaim");
    strcopy(g_Effects[i].Desc, STR_LEN, "Destroy Building at Aim");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_builddelay_killaim");
    i++;
    
    g_Effects[i].ID = KILLBUILD;
    g_Effects[i].GID = BUILD;
    g_Effects[i].Delay = 1;
    strcopy(g_Effects[i].Name, STR_LEN, "killbuild");
    strcopy(g_Effects[i].Desc, STR_LEN, "Destroy All Buildings");
    strcopy(g_Effects[i].DelayCVar, STR_LEN, "sm_builddelay_killbuild");
    i++;
}

//──────────────────────────────────────────────────────────────────────────────
void ResetPlayerData(int client)
{
    for(int Index = 0; Index < EFFECTS; Index++)
    {
        g_Players[client].TimeUsed[Index] = GetTime();
    }
}

//──────────────────────────────────────────────────────────────────────────────
void ResetAllData()
{
    for(int cli = 1; cli <= MaxClients; cli++)
    {
        ResetPlayerData(cli);
    }
}

//──────────────────────────────────────────────────────────────────────────────
// Menu
//──────────────────────────────────────────────────────────────────────────────
public Action Command_MainMenu(int client, int args)
{
    if (!IsValidClient(client))
    {
        LogAction(-1, -1, "%s Wrong client '%L' triggered this function", LOG_PREFIX, client);
        return Plugin_Handled;
    }
    
    if (!CheckCommandAccess(client, CMD_ACCESS, ADMFLAG_NONE, true))
    {
        ReplyToCommand(client, "%s You don't have access to this command", CHAT_PREFIX);
        return Plugin_Handled;
    }
    
    if(!IsPlayerAlive(client))
    {
        PrintToChat(client, "%s You must be alive", CHAT_PREFIX);
        return Plugin_Handled;
    }
    
    ShowMainMenu(client);

    return Plugin_Handled;
}

//──────────────────────────────────────────────────────────────────────────────
void ShowMainMenu(int Client)
{
    Menu menu = new Menu(MainMenuHandler);
    
    menu.SetTitle("!effects");
    
    menu.AddItem("spells", "!spells");
    menu.AddItem("canteen", "!canteen");
    menu.AddItem("build", "!build");
    
    menu.ExitButton = true;
    menu.Display(Client, MENU_TIME_FOREVER);
}

//──────────────────────────────────────────────────────────────────────────────
public int MainMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char Info[STR_LEN];
            menu.GetItem(param2, Info, sizeof(Info));
            
            if(StrEqual(Info, "spells"))
            {
                ShowMenu(param1, SPELL, null);
            }
            else if(StrEqual(Info, "canteen"))
            {
                ShowMenu(param1, CHARGE, null);
            }
            else if(StrEqual(Info, "build"))
            {
                ShowMenu(param1, BUILD, null);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    
    return 0;
}

//──────────────────────────────────────────────────────────────────────────────
public Action Command_Menu(int client, int args)
{
    if (!IsValidClient(client))
    {
        LogAction(-1, -1, "%s Wrong client '%L' triggered this function", LOG_PREFIX, client);
        return Plugin_Handled;
    }
    
    if (!CheckCommandAccess(client, CMD_ACCESS, ADMFLAG_NONE, true))
    {
        ReplyToCommand(client, "%s You don't have access to this command", CHAT_PREFIX);
        return Plugin_Handled;
    }
    
    // Get command name
    char Command[STR_LEN];
    GetCmdArg(0, Command, sizeof(Command));
    
    // Chat prefix
    char ChatPrefix[STR_LEN];
    // Selector for effects (group)
    int Selector = ALL;
    
    if(StrEqual(Command, "sm_spells", false) || StrEqual(Command, "sm_spell", false))
    {
        Selector = SPELL;
        strcopy(ChatPrefix, sizeof(ChatPrefix), SPELL_PREFIX);
    }
    else if(StrEqual(Command, "sm_canteen", false))
    {
        Selector = CHARGE;
        strcopy(ChatPrefix, sizeof(ChatPrefix), CHARGE_PREFIX);
    }
    else if(StrEqual(Command, "sm_build", false))
    {
        Selector = BUILD;
        strcopy(ChatPrefix, sizeof(ChatPrefix), BUILD_PREFIX);
    }
    else
    {
        Selector = ALL;
        strcopy(ChatPrefix, sizeof(ChatPrefix), CHAT_PREFIX);
    }
    
    if(!IsPlayerAlive(client))
    {
        PrintToChat(client, "%s You must be alive", ChatPrefix);
        return Plugin_Handled;
    }
    
    if(args == 0)
    {
        // Command called without arguments - show menu
        ShowMenu(client, Selector, null);
    }
    else
    {
        // Command called with argument - 1st argument must be a effect name
        char EffectName[STR_LEN];
        GetCmdArg(1, EffectName, sizeof(EffectName));
        
        bool Match = false;    // true if 1st argument matched some spell name
        
        // Selector
        // Go through all known spells
        for(int Index = 0; Index < EFFECTS; Index++)
        {
            // Compare for current spell name from list match requested from command line
            if(StrEqual(EffectName, g_Effects[Index].Name, false))
            {
                // We have match - found requested effect
                Match = true;
                UseEffect(client, Index);
                break;
            }
        }
        // If loop above don't find any spell name that match requested in 1st argument
        // then print all spell names to player
        if(!Match)
        {
            PrintHelp(client);
        }
    }
    
    return Plugin_Handled;
}

//──────────────────────────────────────────────────────────────────────────────
void ShowMenu(int client, int Group, Menu Parent)
{
    Menu menu = new Menu(MenuHandler);
    
    // Get player wait time multiplier
    float Mult = GetMult(client);
    
    if(Group == ALL)
    {
        menu.SetTitle("All effects");
    }
    else if(Group == SPELL)
    {
        menu.SetTitle("Spells");
    }
    else if(Group == CHARGE)
    {
        menu.SetTitle("Canteen charges");
    }
    else if(Group == BUILD)
    {
        menu.SetTitle("Buildings");
    }
    
    char Msg[STR_LEN];
    int iDelay = 0;
    
    for(int Index = 0; Index < EFFECTS; Index++)
    {
        // Select only required effects
        if(g_Effects[Index].GID & Group)
        {
            iDelay = IsEffectReady(client, Index, Mult);
            if(iDelay == READY)
            {
                menu.AddItem(g_Effects[Index].Name, g_Effects[Index].Desc);
            }
            else if(iDelay > 0)
            {
                Format(Msg, sizeof(Msg), "%s (%d sec)", g_Effects[Index].Desc, iDelay);
                menu.AddItem(g_Effects[Index].Name, Msg, ITEMDRAW_DISABLED);
            }
            else if(iDelay == LIMIT)
            {
                Format(Msg, sizeof(Msg), "%s (limit)", g_Effects[Index].Desc);
                menu.AddItem(g_Effects[Index].Name, Msg, ITEMDRAW_DISABLED);
            }
            else if(iDelay == DISABLED)
            {
                Format(Msg, sizeof(Msg), "%s (disabled)", g_Effects[Index].Desc);
                menu.AddItem(g_Effects[Index].Name, Msg, ITEMDRAW_DISABLED);
            }
        }
    }
    
    menu.ExitButton = true;
    if(Parent != null)
    {
        menu.ExitBackButton = true;
    }
    menu.Display(client, MENU_TIME_FOREVER);
}

//──────────────────────────────────────────────────────────────────────────────
public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char Info[STR_LEN];
            menu.GetItem(param2, Info, sizeof(Info));
            
            // Go through all known spells
            for(int Index = 0; Index < EFFECTS; Index++)
            {
                // Compare for current spell name from list match selected in menu
                if(StrEqual(Info, g_Effects[Index].Name) && IsPlayerAlive(param1))
                {
                    UseEffect(param1, Index);
                    break;
                }
            }
            ShowMainMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_ExitBack)
            {
                ShowMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    
    return 0;
}

//──────────────────────────────────────────────────────────────────────────────
// Internal routines
//──────────────────────────────────────────────────────────────────────────────
void UseEffect(int Client, int Index)
{
    // Get player wait time multiplier
    float Mult = GetMult(Client);
    // Is it ready?
    int TimeWait = IsEffectReady(Client, Index, Mult);    // 0 - ready; > 0 - time to wait; -1 - limit reached; < -1 - disabled
    if(TimeWait > 0)
    {
        // Effect is not ready - notify player
        PrintToChat(Client, "%s Wait \x07FFA500%d\x01 second(s)", CHAT_PREFIX, TimeWait);
        return;
    }
    else if(TimeWait == LIMIT)
    {
        // Effect limited
        PrintToChat(Client, "%s Limit reached", CHAT_PREFIX);
        return;
    }
    else if(TimeWait == DISABLED)
    {
        // Effect disabled
        PrintToChat(Client, "%s Effect disabled", CHAT_PREFIX);
        return;
    }
    
    if(g_Effects[Index].GID == SPELL)
    {
        ShootProjectile(Client, g_Effects[Index].ID);
        DecorSpell(Client);
    }
    
    else if(g_Effects[Index].GID == CHARGE)
    {
        ShootCharge(Client, g_Effects[Index].ID);
    }
    
    else if(g_Effects[Index].GID == BUILD)
    {
        Build(Client, g_Effects[Index].ID);
    }
    
    // Save time when player used effect
    g_Players[Client].TimeUsed[Index] = GetTime();
}

//──────────────────────────────────────────────────────────────────────────────
void Build(int Client, int BuildingID)
{
    // Variables to store building position and rotation angle
    float Position[3];
    float Angle[3];
    // Select what to do
    switch(BuildingID)
    {
        case SENTRY1:
        {
            GetClientEyeTraceVec(Client, Position, Angle);
            BuildSentry(Client, Position, Angle, 1, false);
        }
        case SENTRY2:
        {
            GetClientEyeTraceVec(Client, Position, Angle);
            BuildSentry(Client, Position, Angle, 2, false);
        }
        case SENTRY3:
        {
            GetClientEyeTraceVec(Client, Position, Angle);
            BuildSentry(Client, Position, Angle, 3, false);
        }
        case SENTRYMIN:
        {
            GetClientEyeTraceVec(Client, Position, Angle);
            BuildSentry(Client, Position, Angle, 1, true);
        }
        case DISP:   
        {
            GetClientEyeTraceVec(Client, Position, Angle);
            BuildDispenser(Client, Position, Angle, 3);
        }
        case KILLBUILD:
        {
            KillAllSentry(Client);
            KillAllDisp(Client);
        }
        case KILLAIM:
        {
            KillAim(Client);
        }
    } 
}

//──────────────────────────────────────────────────────────────────────────────
void ShootCharge(int Client, int Charge)
{
    switch(Charge)
    {
        case UBER:
        {
            TF2_AddCondition(Client, TFCond_UberchargedCanteen, 15.0);
        }
        case CRIT:   
        {
            TF2_AddCondition(Client, TFCond_CritCanteen, 15.0);
        }
        case REGEN:
        {
            TF2_RegeneratePlayer(Client);
        }
        case INVIS:
        {
            TF2_AddCondition(Client, TFCond_Stealthed, 15.0);
        }
        case BASE:
        {
            TF2_RespawnPlayer(Client);
        }
        case SPEED:
        {
            TF2_AddCondition(Client, TFCond_SpeedBuffAlly, 15.0);
            ParticleCreate("sapper_coreflash", _, _, Client);
            ParticleCreate("sapper_flash", _, _, Client);
            ParticleCreate("sapper_flashup", _, _, Client);
            ParticleCreate("sapper_flyingembers", _, _, Client);
            ParticleCreate("sapper_smoke", _, _, Client);
        }
        case HEAL:
        {
            int Health = GetClientHealth(Client) + 5000;
            SetEntityHealth(Client, Health);
            DecorHeal(Client);
        }
    }  
}

//──────────────────────────────────────────────────────────────────────────────
int ShootProjectile(int client, int spell)
{
    float vAngles[3];
    float vPosition[3];
    GetClientEyeAngles(client, vAngles);
    GetClientEyePosition(client, vPosition);
    char strEntname[45] = "";
    
    switch(spell)
    {
        case FIREBALL:     strEntname = "tf_projectile_spellfireball";
        case LIGHTNING:    strEntname = "tf_projectile_lightningorb";
        case BATS:         strEntname = "tf_projectile_spellbats";
        case METEOR:       strEntname = "tf_projectile_spellmeteorshower";
        case TELE:         strEntname = "tf_projectile_spelltransposeteleport";
        case BOSS:          strEntname = "tf_projectile_spellspawnboss";
        case ZOMBIE:        strEntname = "tf_projectile_spellspawnzombie";
    }
    
    int iTeam = GetClientTeam(client);
    int iSpell = CreateEntityByName(strEntname);
    
    if(!IsValidEntity(iSpell))
        return -1;
    
    float vVelocity[3];
    float vBuffer[3];
    
    GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
    
    vVelocity[0] = vBuffer[0] * 1100.0; //Speed of a tf2 rocket.
    vVelocity[1] = vBuffer[1] * 1100.0;
    vVelocity[2] = vBuffer[2] * 1100.0;
    
    SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
    SetEntProp(iSpell, Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5) ? 1 : 0, 1);
    SetEntProp(iSpell, Prop_Send, "m_iTeamNum", iTeam, 1);
    SetEntProp(iSpell, Prop_Send, "m_nSkin", (iTeam-2));
    
    TeleportEntity(iSpell, vPosition, vAngles, NULL_VECTOR);
    
    SetVariantInt(iTeam);
    AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
    SetVariantInt(iTeam);
    AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
    
    DispatchSpawn(iSpell);
    
    TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, vVelocity);
    
    return iSpell;
}