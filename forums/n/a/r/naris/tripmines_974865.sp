/**
 * vim: set ai et ts=4 sw=4 :
 * File: tripmines.sp
 * Description: Tripmines for TF2
 * Author(s): L. Duke
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "2.0.1.7"

#define MAXENTITIES 2048

#define TRACE_START 24.0
#define TRACE_END 64.0

#define MDL_LASER "sprites/laser.vmt"
#define MDL_MINE "models/props_lab/tpplug.mdl"

#define SND_MINEPUT "npc/roller/blade_cut.wav"
#define SND_MINEACT "npc/roller/mine/rmine_blades_in2.wav"
#define SND_MINEERR "common/wpn_denyselect.wav"
#define SND_MINEREM "ui/hint.wav"
#define SND_BUYMINE "items/itempickup.wav"
#define SND_CANTBUY "buttons/weapon_cant_buy.wav"

#define TEAM_T 2
#define TEAM_CT 3

#define COLOR_T "255 0 0"
#define COLOR_CT "0 0 255"
#define COLOR_DEF "0 255 255"

#define MAX_LINE_LEN 256

// globals
new gRemaining[MAXPLAYERS+1];    // how many tripmines player has this spawn
new gMaximum[MAXPLAYERS+1];      // how many tripmines player can have active at once
new gCount = 1;

// for buy
new gInBuyZone = -1;
new gAccount = -1;

new bool:gNativeControl = false;
new bool:gChangingClass[MAXPLAYERS+1];
new gAllowed[MAXPLAYERS+1];    // how many tripmines player allowed

new gTripmineModelIndex;
new gLaserModelIndex;

new g_TripminesBeam[MAXENTITIES];
new g_BeamsTripmine[MAXENTITIES];

new String:mdlMine[256];

new Handle:g_precacheTrie = INVALID_HANDLE;

new bool:gSetTripmineHooked = false;

// forwards
new Handle:fwdOnSetTripmine;

// convars
new Handle:cvActTime = INVALID_HANDLE;
new Handle:cvModel = INVALID_HANDLE;
new Handle:cvMineCost = INVALID_HANDLE;
new Handle:cvTeamRestricted = INVALID_HANDLE;
new Handle:cvTeamSpecific = INVALID_HANDLE;
new Handle:cvRadius = INVALID_HANDLE;
new Handle:cvDamage = INVALID_HANDLE;
new Handle:cvType = INVALID_HANDLE;
new Handle:cvStay = INVALID_HANDLE;
new Handle:cvFriendlyFire = INVALID_HANDLE;
//new Handle:cvTurboPhysics = INVALID_HANDLE;

new Handle:cvMaxMines = INVALID_HANDLE;
new Handle:cvNumMines = INVALID_HANDLE;
new Handle:cvNumMinesScout = INVALID_HANDLE;
new Handle:cvNumMinesSniper = INVALID_HANDLE;
new Handle:cvNumMinesSoldier = INVALID_HANDLE;
new Handle:cvNumMinesDemoman = INVALID_HANDLE;
new Handle:cvNumMinesMedic = INVALID_HANDLE;
new Handle:cvNumMinesHeavy = INVALID_HANDLE;
new Handle:cvNumMinesPyro = INVALID_HANDLE;
new Handle:cvNumMinesSpy = INVALID_HANDLE;
new Handle:cvNumMinesEngi = INVALID_HANDLE;

//#include <tf2_player>
/**
 * Description: Functions to return information about TF2 player condition.
 */
#define TF2_PLAYER_SLOWED  1 // (1 << 0)    // 1
#define TF2_PLAYER_ZOOMED       (1 << 1)    // 2
#define TF2_PLAYER_DISGUISING   (1 << 2)    // 4
#define TF2_PLAYER_DISGUISED	(1 << 3)    // 8
#define TF2_PLAYER_CLOAKED      (1 << 4)    // 16
#define TF2_PLAYER_INVULN       (1 << 5)    // 32
#define TF2_PLAYER_HEALING	    (1 << 6)    // 64
#define TF2_PLAYER_TAUNTING	    (1 << 7)    // 128
#define TF2_PLAYER_ONFIRE	    (1 << 14)   // 16384
//#define TF2_PLAYER_??	        (1 << 8)    // 256

#define TF2_IsZoomed(%1)        (((%1) & TF2_PLAYER_ZOOMED) != 0)
#define TF2_IsSlowed(%1)        (((%1) & TF2_PLAYER_SLOWED) != 0)
#define TF2_IsDisguised(%1)     (((%1) & TF2_PLAYER_DISGUISED) != 0)
#define TF2_IsCloaked(%1)       (((%1) & TF2_PLAYER_CLOAKED) != 0)
#define TF2_IsInvuln(%1)        (((%1) & TF2_PLAYER_INVULN) != 0)
#define TF2_IsHealing(%1)       (((%1) & TF2_PLAYER_HEALING) != 0)
#define TF2_IsTaunting(%1)      (((%1) & TF2_PLAYER_TAUNTING) != 0)
#define TF2_IsOnFire(%1)        (((%1) & TF2_PLAYER_ONFIRE) != 0)

stock TF2_GetNumHealers(client)
{
    return GetEntProp(client, Prop_Send, "m_nNumHealers");
}

stock TF2_GetPlayerCond(client)
{
    return GetEntProp(client, Prop_Send, "m_nPlayerCond");
}

stock TF2_SetPlayerCond(client,playerCond)
{
    SetEntProp(client, Prop_Send, "m_nPlayerCond", playerCond);
}

stock bool:TF2_IsPlayerZoomed(client)
{
    return TF2_IsZoomed(TF2_GetPlayerCond(client));
}

stock bool:TF2_IsPlayerSlowed(client)
{
    return TF2_IsSlowed(TF2_GetPlayerCond(client));
}

stock bool:TF2_IsPlayerDisguised(client)
{
    return TF2_IsDisguised(TF2_GetPlayerCond(client));
}

stock bool:TF2_IsPlayerInvuln(client)
{
    return TF2_IsInvuln(TF2_GetPlayerCond(client));
}

stock bool:TF2_IsPlayerHealing(client)
{
    return TF2_IsHealing(TF2_GetPlayerCond(client));
}

stock bool:TF2_IsPlayerTaunting(client)
{
    return TF2_IsTaunting(TF2_GetPlayerCond(client));
}

stock bool:TF2_IsPlayerOnFire(client)
{
    return TF2_IsOnFire(TF2_GetPlayerCond(client));
}

stock bool:TF2_IsPlayerCloaked(client)
{
    return TF2_IsCloaked(TF2_GetPlayerCond(client));
}

stock TF2_SetPlayerCloak(client, bool:enabled)
{
    new playerCond = TF2_GetPlayerCond(client);
    if (enabled)
        TF2_SetPlayerCond(client, (playerCond | TF2_PLAYER_CLOAKED));
    else
        TF2_SetPlayerCond(client, (playerCond & (~TF2_PLAYER_CLOAKED)));
}

stock TF2_ClassHealth[TFClassType] = { 0, 125, 125, 200, 175, 150, 300, 175, 125, 125 };
#define TF2_GetClassHealth(%1) TF2_ClassHealth[%1]

//stock Float:TF2_ClassSpeeds[TFClassType] = { 0.0, 400.0, 300.0, 240.0, 280.0, 320.0, 230.0, 300.0, 300.0, 300.0 };
stock Float:TF2_ClassSpeeds[10] = { 0.0, 400.0, 300.0, 240.0, 280.0, 320.0, 230.0, 300.0, 300.0, 300.0 };
#define TF2_GetClassSpeed(%1) TF2_ClassSpeeds[%1]

stock Float:TF2_GetPlayerSpeed(client)
{
    if (TF2_IsPlayerSlowed(client))
        return 80.0;
    else
        return TF2_GetClassSpeed(TF2_GetPlayerClass(client));
}

//#include "gametype"
/**
 * Description: Function to determine game/mod type
 */
enum Mod { undetected, tf2, dod, cstrike, hl2mp, insurgency, other };
stock Mod:GameType = undetected;

stock Mod:GetGameType()
{
    if (GameType == undetected)
    {
        new String:modname[30];
        GetGameFolderName(modname, sizeof(modname));
        if (StrEqual(modname,"cstrike",false))
            GameType=cstrike;
        else if (StrEqual(modname,"tf",false)) 
            GameType=tf2;
        else if (StrEqual(modname,"dod",false)) 
            GameType=dod;
        else if (StrEqual(modname,"hl2mp",false)) 
            GameType=hl2mp;
        else if (StrEqual(modname,"Insurgency",false)) 
            GameType=insurgency;
        else
            GameType=other;
    }
    return GameType;
}
/*****************************************************************/

//#include <entlimit>
/**
 * Description: Function to check the entity limit.
 *              Use before spawning an entity.
 * Author(s): Marc Hörsken
 */
stock bool:IsEntLimitReached(num=16)
{
    new max = GetMaxEntities();
    new count = GetEntityCount();
    if (count >= (max-num))
    {
        PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
        LogError("Entity limit is nearly reached: %d/%d", count, max);
        return true;
    }
    else
        return false;
}
/*****************************************************************/

public Plugin:myinfo = {
    name = "Tripmines",
    author = "L. Duke (mod by user)",
    description = "Plant a trip mine",
    version = PLUGIN_VERSION,
    url = "http://www.lduke.com/"
};

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    // To work with all mods
    MarkNativeAsOptional("TF2_IgnitePlayer");
    MarkNativeAsOptional("TF2_RemovePlayerDisguise");

    // Register Natives
    CreateNative("ControlTripmines",Native_ControlTripmines);
    CreateNative("GiveTripmines",Native_GiveTripmines);
    CreateNative("TakeTripmines",Native_TakeTripmines);
    CreateNative("AddTripmines",Native_AddTripmines);
    CreateNative("SubTripmines",Native_SubTripmines);
    CreateNative("HasTripmines",Native_HasTripmines);
    CreateNative("SetTripmine",Native_SetTripmine);
    CreateNative("CountTripmines",Native_CountTripmines);
    CreateNative("HookSetTripmine",Native_HookSetTripmine);

    // Register Forwards
    fwdOnSetTripmine=CreateForward(ET_Hook,Param_Cell);

    RegPluginLibrary("tripmines");
    return true;
}

public OnPluginStart()
{
    // translations
    LoadTranslations("plugin.tripmines"); 

    // events
    HookEvent("player_death", PlayerDeath);

    switch (GetGameType())
    {
        case tf2:
        {
            HookEvent("arena_win_panel", RoundEnd);
            HookEvent("teamplay_round_win", RoundEnd);
            HookEvent("teamplay_round_stalemate", RoundEnd);
            HookEvent("player_changeclass", PlayerChange);
        }
        case dod:
        {
            HookEvent("dod_round_win", RoundEnd);
            HookEvent("dod_game_over", RoundEnd);
        }
        case cstrike:
        {
            HookEvent("round_end", RoundEnd);
        }
        case insurgency:
        {
            HookEvent("round_end", RoundEnd);
        }
        case other:
        {
            HookEvent("round_end", RoundEnd);
        }
    }

    if (GameType != cstrike)
        HookEvent("player_spawn",PlayerSpawn);

    // convars
    CreateConVar("sm_tripmines_version", PLUGIN_VERSION, "Tripmines", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    cvActTime = CreateConVar("sm_tripmines_activate_time", "2.0", "Tripmine activation time.");
    cvModel = CreateConVar("sm_tripmines_model", MDL_MINE, "Tripmine model");
    cvTeamRestricted = CreateConVar("sm_tripmines_restrictedteam", "0", "Team that does NOT get any tripmines", _, true, 0.0, true, 3.0);
    cvTeamSpecific = CreateConVar("sm_tripmines_teamspecific", "1", "Allow teammates of planter to pass", _, true, 0.0, true, 1.0);
    cvType = CreateConVar("sm_tripmines_type","1","Explosion type of Tripmines (0 = normal explosion | 1 = fire explosion)", _, true, 0.0, true, 1.0);
    cvStay = CreateConVar("sm_tripmines_stay","1","Firemines stay if the owner dies. (0 = no | 1 = yes | 2 = destruct)", _, true, 0.0, true, 2.0);
    cvRadius = CreateConVar("sm_tripmines_radius", "256", "Tripmines Explosion Radius");
    cvDamage = CreateConVar("sm_tripmines_radius", "200", "Tripmines Explosion Damage");
    cvFriendlyFire = FindConVar("mp_friendlyfire");
    //cvTurboPhysics = FindConVar("sv_turbophysics");

    cvMaxMines = CreateConVar("sm_tripmines_maximum", "6", "Number of tripmines allowed to be active per client (-1=unlimited)");
    cvNumMines = CreateConVar("sm_tripmines_allowed", "3", "Number of tripmines allowed per life (-1=unlimited)");
    cvMineCost = CreateConVar("sm_tripmines_cost", "50", "Tripmines price");

    cvNumMinesScout = CreateConVar("sm_tripmines_scout_limit", "-1", "Number of tripmines allowed per life for Scouts (-1=use generic variable)");
    cvNumMinesSniper = CreateConVar("sm_tripmines_sniper_limit", "-1", "Number of tripmines allowed per life for Snipers");
    cvNumMinesSoldier = CreateConVar("sm_tripmines_soldier_limit", "-1", "Number of tripmines allowed per life For Soldiers");
    cvNumMinesDemoman = CreateConVar("sm_tripmines_demoman_limit", "-1", "Number of tripmines allowed per life for Demomen");
    cvNumMinesMedic = CreateConVar("sm_tripmines_medic_limit", "-1", "Number of tripmines allowed per life for Medics");
    cvNumMinesHeavy = CreateConVar("sm_tripmines_heavy_limit", "-1", "Number of tripmines allowed per life for Heavys");
    cvNumMinesPyro = CreateConVar("sm_tripmines_pyro_limit", "-1", "Number of tripmines allowed per life for Pyros");
    cvNumMinesSpy = CreateConVar("sm_tripmines_spy_limit", "-1", "Number of tripmines allowed per life for Spys");
    cvNumMinesEngi = CreateConVar("sm_tripmines_engi_limit", "-1", "Number of tripmines allowed per life for Engineers");

    // commands
    RegConsoleCmd("sm_tripmine", Command_TripMine);
    RegConsoleCmd("tripmine", Command_TripMine);

    if (GameType == cstrike)
    {
        // prop offset
        gInBuyZone = FindSendPropOffs("CCSPlayer", "m_bInBuyZone");
        gAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
        RegConsoleCmd("sm_buytripmines", Command_BuyTripMines);
    }

    AutoExecConfig( true, "plugin_tripmines");
}

/*
public OnPluginEnd()
{
	UnhookEvent("player_changeclass", PlayerChange);
	UnhookEvent("player_death", PlayerDeath);
	UnhookEvent("player_spawn",PlayerSpawn);
}
*/

public OnMapStart()
{
    // set model based on cvar
    GetConVarString(cvModel, mdlMine, sizeof(mdlMine));

    // precache models
    gTripmineModelIndex = 0; // PrecacheModel(mdlMine, true);
    gLaserModelIndex = 0;    // PrecacheModel(MDL_LASER, true);

    // precache sounds
    //PrecacheSound(SND_MINEPUT, true);
    //PrecacheSound(SND_MINEACT, true);
    //PrecacheSound(SND_MINEERR, true);
    //PrecacheSound(SND_MINEREM, true);
    SetupPreloadTrie();
}

// When a new client is put in the server we reset their mines count
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
    if (client && !IsFakeClient(client))
    {
        gChangingClass[client]=false;
        gRemaining[client] = gAllowed[client] = gMaximum[client] = 0;
    }
    return true;
}

public Action:PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    RemoveTripmines(GetClientOfUserId(GetEventInt(event, "userid")), false);
    return Plugin_Continue;
}    

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new amount = -1;
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (gChangingClass[client])
        gChangingClass[client]=false;
    else
    {
        if (gNativeControl)
            amount = gRemaining[client] = gAllowed[client];

        if (amount == -1)
        {
            if (GameType == tf2)
            {
                switch (TF2_GetPlayerClass(client))
                {
                    case TFClass_Scout: amount = GetConVarInt(cvNumMinesScout);
                    case TFClass_Sniper: amount = GetConVarInt(cvNumMinesSniper);
                    case TFClass_Soldier: amount = GetConVarInt(cvNumMinesSoldier);
                    case TFClass_DemoMan: amount = GetConVarInt(cvNumMinesDemoman);
                    case TFClass_Medic: amount = GetConVarInt(cvNumMinesMedic);
                    case TFClass_Heavy: amount = GetConVarInt(cvNumMinesHeavy);
                    case TFClass_Pyro: amount = GetConVarInt(cvNumMinesPyro);
                    case TFClass_Spy: amount = GetConVarInt(cvNumMinesSpy);
                    case TFClass_Engineer: amount = GetConVarInt(cvNumMinesEngi);
                }
                if (amount < 0)
                    amount = GetConVarInt(cvNumMines);

                gRemaining[client] = gAllowed[client] = amount;
            }
            else
                gRemaining[client] = gAllowed[client] = GetConVarInt(cvNumMines);
        }
    }

    return Plugin_Continue;
}

public Action:PlayerChange(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    gChangingClass[client]=true;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    gChangingClass[client]=false;
    gRemaining[client] = 0;

    new stay = GetConVarInt(cvStay);
    if (stay != 1)
        RemoveTripmines(client, (stay > 1));

    return Plugin_Continue;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl String:classname[64];
    new maxents = GetMaxEntities();
    for (new c = MaxClients; c < maxents; c++)
    {
        if (IsValidEntity(c))
        {
            GetEntityNetClass(c, classname, sizeof(classname));
            //if (StrEqual(classname, "CPhysicsProp"))
            if (StrEqual(classname, "CDynamicProp"))
            {
                // Make sure it's a Tripmine
                if (GetEntProp(c,Prop_Send,"m_nModelIndex") == gTripmineModelIndex)
                {
                    RemoveEdict(c);
                    g_TripminesBeam[c] = 0;

                    new beam = g_TripminesBeam[c];
                    if (beam > 0 && IsValidEntity(beam))
                    {
                        if (GetEntityNetClass(beam, classname, sizeof(classname)) &&
                                StrEqual(classname, "CBeam"))
                        {
                            // Make sure it's a laser beam
                            if (GetEntProp(beam,Prop_Send,"m_nModelIndex") == gLaserModelIndex)
                                RemoveEdict(beam);
                        }
                    }
                    g_BeamsTripmine[beam] = 0;
                    g_TripminesBeam[c] = 0;
                }
            }
            else if (StrEqual(classname, "CBeam"))
            {
                // Make sure it's a laser beam
                if (GetEntProp(c,Prop_Send,"m_nModelIndex") == gLaserModelIndex)
                {
                    RemoveEdict(c);
                    g_BeamsTripmine[c] = 0;
                }
            }
        }
    }
}

RemoveTripmines(client, bool:explode=false)
{
    new Float:time=0.01;
    decl String:classname[64];
    new maxents = GetMaxEntities();
    for (new c = MaxClients; c < maxents; c++)
    {
        if (IsValidEntity(c))
        {
            GetEntityNetClass(c, classname, sizeof(classname));
            //if (StrEqual(classname, "CPhysicsProp"))
            if (StrEqual(classname, "CDynamicProp"))
            {
                if (GetEntPropEnt(c, Prop_Data, "m_hOwnerEntity") == client)
                {
                    // Make sure it's a Tripmine
                    if (GetEntProp(c,Prop_Send,"m_nModelIndex") == gTripmineModelIndex)
                    {
                        if (explode)
                        {
                            CreateTimer(time, ExplodeMine, c);
                            time += 0.02;
                            continue;
                        }
                        else
                        {
                            PrepareSound(SND_MINEREM);
                            EmitSoundToAll(SND_MINEREM, c, _, _, _, 0.75);
                            RemoveEdict(c);
                            g_TripminesBeam[c] = 0;

                            new beam = g_TripminesBeam[c];
                            if (beam > 0 && IsValidEntity(beam))
                            {
                                if (GetEntityNetClass(beam, classname, sizeof(classname)) &&
                                        StrEqual(classname, "CBeam"))
                                {
                                    // Make sure it's a laser beam
                                    if (GetEntProp(beam,Prop_Send,"m_nModelIndex") == gLaserModelIndex)
                                        RemoveEdict(beam);
                                }
                            }
                            g_BeamsTripmine[beam] = 0;
                            g_TripminesBeam[c] = 0;
                        }
                    }
                }
            }
            else if (StrEqual(classname, "CBeam"))
            {
                if (GetEntPropEnt(c, Prop_Data, "m_hOwnerEntity") == client)
                {
                    // Make sure it's a laser beam
                    if (GetEntProp(c,Prop_Send,"m_nModelIndex") == gLaserModelIndex)
                    {
                        RemoveEdict(c);
                        g_BeamsTripmine[c] = 0;
                    }
                }
            }
        }
    }
}

public Action:ExplodeMine(Handle:timer, any:ent)
{
    decl String:class[32];
    if (IsValidEntity(ent) &&
        GetEntityNetClass(ent,class,sizeof(class)))
    {
        //if (StrEqual(class, "CPhysicsProp"))
        if (StrEqual(class, "CDynamicProp"))
        {
            // Make sure it's a tripmine
            if (GetEntProp(ent,Prop_Send,"m_nModelIndex") == gTripmineModelIndex)
            {
                //SetConVarBool(cvTurboPhysics, true);
                //CreateTimer(2.0, RestorePhysics);

                AcceptEntityInput(ent, "Break");
            }
        }
    }
    return Plugin_Stop;
}

/*
public Action:RestorePhysics(Handle:timer, any:ent)
{
    SetConVarBool(cvTurboPhysics, false);
    return Plugin_Stop;
}
*/

public Action:Command_TripMine(client, args)
{
    // make sure client is not spectating
    if (!IsPlayerAlive(client))
        return Plugin_Handled;

    // check restricted team 
    new team = GetClientTeam(client);
    if (team == GetConVarInt(cvTeamRestricted))
    {
        PrintHintText(client, "%t", "notallowed");
        return Plugin_Handled;
    }

    SetMine(client);
    return Plugin_Handled;
}

SetMine(client)
{
    if (IsEntLimitReached())
        return;

    if (gRemaining[client] == 0)
    {
        PrintHintText(client, "%t", "nomines");
        return;
    }

    new max = gMaximum[client];
    if (max > 0)
    {
        new count = CountMines(client);
        if (count > max)
        {
            PrintHintText(client, "%t", "toomany", count);
            return;
        }
    }

    if (gSetTripmineHooked)
    {
        new Action:res = Plugin_Continue;
        Call_StartForward(fwdOnSetTripmine);
        Call_PushCell(client);
        Call_Finish(res);
        if (res != Plugin_Continue)
            return;
    }

    if (GameType == tf2)
    {
        if (TF2_GetPlayerClass(client) == TFClass_Spy)
        {
            if (TF2_IsPlayerCloaked(client))
            {
                PrepareSound(SND_MINEERR);
                EmitSoundToClient(client, SND_MINEERR);
                return;
            }
            else
                TF2_RemovePlayerDisguise(client);
        }
    }

    // trace client view to get position and angles for tripmine

    decl Float:start[3], Float:angle[3], Float:end[3], Float:normal[3], Float:beamend[3];
    GetClientEyePosition( client, start );
    GetClientEyeAngles( client, angle );
    GetAngleVectors(angle, end, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(end, end);

    start[0]=start[0]+end[0]*TRACE_START;
    start[1]=start[1]+end[1]*TRACE_START;
    start[2]=start[2]+end[2]*TRACE_START;

    end[0]=start[0]+end[0]*TRACE_END;
    end[1]=start[1]+end[1]*TRACE_END;
    end[2]=start[2]+end[2]*TRACE_END;

    TR_TraceRayFilter(start, end, CONTENTS_SOLID, RayType_EndPoint, FilterAll, 0);

    if (TR_DidHit(INVALID_HANDLE))
    {
        // update client's inventory
        if (gRemaining[client] > 0)
            gRemaining[client]--;

        // find angles for tripmine
        TR_GetEndPosition(end, INVALID_HANDLE);
        TR_GetPlaneNormal(INVALID_HANDLE, normal);
        GetVectorAngles(normal, normal);

        // trace laser beam
        TR_TraceRayFilter(end, normal, CONTENTS_SOLID, RayType_Infinite, FilterAll, 0);
        TR_GetEndPosition(beamend, INVALID_HANDLE);

        new team = GetClientTeam(client);

        // setup unique target names for entities to be created with
        decl String:beamname[16];
        decl String:minename[16];
        decl String:tmp[64];
        Format(beamname, sizeof(beamname), "tripbeam%d", gCount);
        Format(minename, sizeof(minename), "tripmine%d", gCount);
        gCount++;
        if (gCount>10000)
            gCount = 1;


        // create tripmine model
        new prop_ent = CreateEntityByName("prop_dynamic_override"); // ("prop_physics_override");

        PrepareModel(mdlMine, gTripmineModelIndex);
        SetEntityModel(prop_ent,mdlMine);

        DispatchKeyValue(prop_ent, "spawnflags", "152");
        DispatchKeyValue(prop_ent, "StartDisabled", "false");

        if (DispatchSpawn(prop_ent))
        {
            TeleportEntity(prop_ent, end, normal, NULL_VECTOR);
            DispatchKeyValue(prop_ent, "targetname", minename);
            SetEntProp(prop_ent, Prop_Send, "m_iTeamNum", team, 4);
            SetEntProp(prop_ent, Prop_Data, "m_usSolidFlags", 696); // 152);
            SetEntProp(prop_ent, Prop_Data, "m_CollisionGroup", 2);
            SetEntityMoveType(prop_ent, MOVETYPE_NONE);
            SetEntProp(prop_ent, Prop_Data, "m_MoveCollide", 0);
            SetEntProp(prop_ent, Prop_Data, "m_nSolidType", 6);
            SetEntProp(prop_ent, Prop_Data, "m_takedamage", 3); // 2);
            SetEntProp(prop_ent, Prop_Data, "m_iHealth", 100);
            SetEntPropEnt(prop_ent, Prop_Data, "m_hLastAttacker", client);
            SetEntPropEnt(prop_ent, Prop_Data, "m_hPhysicsAttacker", client);
            SetEntPropEnt(prop_ent, Prop_Data, "m_hOwnerEntity", client);
            DispatchKeyValue(prop_ent, "physdamagescale", "1.0");
            DispatchKeyValue(prop_ent, "spawnflags", "696"); // "152");
            DispatchKeyValue(prop_ent, "SetHealth", "100");

            GetConVarString(cvRadius, tmp, sizeof(tmp));
            DispatchKeyValue(prop_ent, "ExplodeRadius", tmp);

            GetConVarString(cvDamage, tmp, sizeof(tmp));
            DispatchKeyValue(prop_ent, "ExplodeDamage", tmp);

            if (GetConVarBool(cvTeamSpecific))
            {
                HookSingleEntityOutput(prop_ent, "OnHealthChanged", mineHealth, true);
                HookSingleEntityOutput(prop_ent, "OnTakeDamage", mineHealth, true);
                HookSingleEntityOutput(prop_ent, "OnAwakened", mineHealth, true);
            }
            else
            {
                //Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beamname);
                //DispatchKeyValue(prop_ent, "OnHealthChanged", tmp);
                DispatchKeyValue(prop_ent, "OnHealthChanged", "!self,Break,,0,-1");
                DispatchKeyValue(prop_ent, "OnTakeDamage", "!self,Break,,0,-1");
                DispatchKeyValue(prop_ent, "OnAwakened", "!self,Break,,0,-1");
            }

            HookSingleEntityOutput(prop_ent, "OnBreak", mineBreak, true);
            AcceptEntityInput(prop_ent, "Enable");

            new beam_ent = CreateBeam(client, prop_ent, minename, beamname,
                                      beamend, end, GetConVarFloat(cvActTime),
                                      false);

            // play sound
            PrepareSound(SND_MINEPUT);
            EmitSoundToAll(SND_MINEPUT, beam_ent, SNDCHAN_AUTO,
                           SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
                           100, beam_ent, end, NULL_VECTOR, true, 0.0);

            // send message
            if (gRemaining[client] >= 0)
                PrintHintText(client, "%t", "left", gRemaining[client]);
        }
        else
            LogError("Unable to spawn a prop_ent");
    }
    else
    {
        PrintHintText(client, "%t", "locationerr");
    }
}

CountMines(client)
{
    new count = 0;
    new String:classname[64];

    new maxents = GetMaxEntities();
    for (new c = MaxClients; c < maxents; c++)
    {
        if (IsValidEntity(c))
        {
            GetEntityNetClass(c, classname, sizeof(classname));
            //if (StrEqual(classname, "CPhysicsProp"))
            if (StrEqual(classname, "CDynamicProp"))
            {
                if (GetEntPropEnt(c, Prop_Data, "m_hOwnerEntity") == client)
                {
                    // Make sure it's a Tripmine
                    if (GetEntProp(c,Prop_Send,"m_nModelIndex") == gTripmineModelIndex)
                    {
                        new beam = g_TripminesBeam[c];
                        if (beam > 0 && IsValidEntity(beam))
                        {
                            if (GetEntityNetClass(beam, classname, sizeof(classname)) &&
                                StrEqual(classname, "CBeam"))
                            {
                                // Make sure it's a laser beam
                                if (GetEntProp(beam,Prop_Send,"m_nModelIndex") == gLaserModelIndex)
                                    count++;
                            }
                        }
                    }
                }
            }
        }
    }
    return count;
}

CreateBeam(client, prop_ent, const String:minename[], const String:beamname[],
           const Float:start[3], const Float:end[3], const Float:delay, bool:force)
{
    // create laser beam
    new beam_ent = CreateEntityByName("env_beam");
    TeleportEntity(beam_ent, start, NULL_VECTOR, NULL_VECTOR);

    PrepareModel(MDL_LASER, gLaserModelIndex);
    SetEntityModel(beam_ent, MDL_LASER);

    DispatchKeyValue(beam_ent, "spawnflags", "152");
    DispatchKeyValue(beam_ent, "texture", MDL_LASER);
    DispatchKeyValue(beam_ent, "parentname", minename);
    DispatchKeyValue(beam_ent, "targetname", beamname);
    AcceptEntityInput(beam_ent, "AddOutput");
    DispatchKeyValue(beam_ent, "TouchType", "4");
    DispatchKeyValue(beam_ent, "LightningStart", beamname);
    DispatchKeyValue(beam_ent, "BoltWidth", "4.0");
    DispatchKeyValue(beam_ent, "life", "0");
    DispatchKeyValue(beam_ent, "rendercolor", "0 0 0");
    DispatchKeyValue(beam_ent, "renderamt", "0");
    DispatchKeyValue(beam_ent, "HDRColorScale", "1.0");
    DispatchKeyValue(beam_ent, "decalname", "Bigshot");
    DispatchKeyValue(beam_ent, "StrikeTime", "0");
    DispatchKeyValue(beam_ent, "TextureScroll", "35");
    SetEntPropEnt(beam_ent, Prop_Data, "m_hOwnerEntity", client);
    SetEntPropVector(beam_ent, Prop_Data, "m_vecEndPos", end);
    SetEntPropFloat(beam_ent, Prop_Data, "m_fWidth", 4.0);

    if (GetConVarBool(cvTeamSpecific))
        HookSingleEntityOutput(beam_ent, "OnTouchedByEntity", beamTouched, true);
    else
    {
        decl String:tmp[64];
        Format(tmp, sizeof(tmp), "%s,Break,,0,-1", minename);
        DispatchKeyValue(beam_ent, "OnTouchedByEntity", tmp);   
    }

    HookSingleEntityOutput(beam_ent, "OnBreak", beamBreak, true);
    AcceptEntityInput(beam_ent, "TurnOff");

    g_TripminesBeam[prop_ent] = beam_ent;
    g_BeamsTripmine[beam_ent] = prop_ent;

    new Handle:data = CreateDataPack();
    CreateTimer(delay, TurnBeamOn, data);
    WritePackCell(data, client);
    WritePackCell(data, prop_ent);
    WritePackCell(data, beam_ent);
    WritePackCell(data, force);
    WritePackFloat(data, end[0]);
    WritePackFloat(data, end[1]);
    WritePackFloat(data, end[2]);

    return beam_ent;
}

public Action:TurnBeamOn(Handle:timer, Handle:data)
{
    decl String:class[32];
    decl String:color[26];

    ResetPack(data);
    new client = ReadPackCell(data);
    new prop_ent = ReadPackCell(data);
    new beam_ent = ReadPackCell(data);
    new force = ReadPackCell(data);

    if (IsClientInGame(client) && IsValidEntity(beam_ent) && IsValidEntity(prop_ent))
    {
        if (force || IsPlayerAlive(client))
        {
            // Ensure the beam_ent is still a beam
            if (GetEntityNetClass(beam_ent,class,sizeof(class)))
            {
                if (StrEqual(class, "CBeam", false))
                {
                    if (GetEntProp(beam_ent,Prop_Send,"m_nModelIndex") == gLaserModelIndex)
                    {
                        // Ensure the prop_ent is still a tripmine
                        if (GetEntityNetClass(prop_ent,class,sizeof(class)))
                        {
                            //if (StrEqual(class, "CPhysicsProp"))
                            if (StrEqual(class, "CDynamicProp"))
                            {
                                if (GetEntProp(prop_ent,Prop_Send,"m_nModelIndex") == gTripmineModelIndex)
                                {
                                    //new team = GetClientTeam(client);
                                    new team = GetEntProp(prop_ent, Prop_Send, "m_iTeamNum");
                                    if(team == TEAM_T) color = COLOR_T;
                                    else if(team == TEAM_CT) color = COLOR_CT;
                                    else color = COLOR_DEF;

                                    DispatchKeyValue(beam_ent, "rendercolor", color);
                                    AcceptEntityInput(beam_ent, "TurnOn");

                                    new Float:end[3];
                                    end[0] = ReadPackFloat(data);
                                    end[1] = ReadPackFloat(data);
                                    end[2] = ReadPackFloat(data);

                                    PrepareSound(SND_MINEACT);
                                    EmitSoundToAll(SND_MINEACT, beam_ent, SNDCHAN_AUTO,
                                                   SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
                                                   100, beam_ent, end, NULL_VECTOR, true, 0.0);

                                    CloseHandle(data);
                                    return Plugin_Stop;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Player died before activation or something happened to the tripmine,
    // remove the tripmine and/or the beam

    g_TripminesBeam[prop_ent] = 0;
    g_BeamsTripmine[beam_ent] = 0;

    // Ensure the entity is still a tripmine
    if (IsValidEntity(prop_ent) &&
        GetEntityNetClass(prop_ent,class,sizeof(class)))
    {
        //if (StrEqual(class, "CPhysicsProp"))
        if (StrEqual(class, "CDynamicProp"))
        {
            if (GetEntProp(prop_ent,Prop_Send,"m_nModelIndex") == gTripmineModelIndex)
            {
                UnhookSingleEntityOutput(prop_ent, "OnBreak", mineBreak);
                AcceptEntityInput(prop_ent, "Kill");
            }
        }
    }

    // Ensure the beam entity is still a beam
    if (IsValidEntity(beam_ent) &&
        GetEntityNetClass(beam_ent,class,sizeof(class)))
    {
        if (StrEqual(class, "CBeam", false))
        {
            if (GetEntProp(beam_ent,Prop_Send,"m_nModelIndex") == gLaserModelIndex)
            {
                if (GetConVarBool(cvTeamSpecific))
                    UnhookSingleEntityOutput(beam_ent, "OnTouchedByEntity", beamTouched);

                AcceptEntityInput(beam_ent, "Kill");
            }
        }
    }

    CloseHandle(data);
    return Plugin_Stop;
}

public beamTouched(const String:output[], caller, activator, Float:delay)
{
    // Ensure the entity is still a beam
    if (IsValidEntity(caller))
    {
        decl String:class[32]; class[0] = '\0';
        if (GetEntityNetClass(caller,class,sizeof(class)) &&
            StrEqual(class, "CBeam", false))
        {
            if (GetEntProp(caller,Prop_Send,"m_nModelIndex") == gLaserModelIndex)
            {
                new tripmine = g_BeamsTripmine[caller];
                new owner = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity");
                new cTeam = (owner > 0 && IsClientInGame(owner)) ? GetClientTeam(owner) : 0;

                if (activator > MaxClients || activator == owner ||
                    cTeam != GetClientTeam(activator))
                {
                    UnhookSingleEntityOutput(caller, "OnTouchedByEntity", beamTouched);

                    new bool:tripmineOK = false;
                    // Ensure the tripmine is still a tripmine
                    if (tripmine > 0 && IsValidEntity(tripmine))
                    {
                        if (GetEntityNetClass(tripmine,class,sizeof(class)) &&
                            StrEqual(class, "CDynamicProp"))
                            //StrEqual(class, "CPhysicsProp"))
                        {
                            if (GetEntProp(tripmine,Prop_Send,"m_nModelIndex") == gTripmineModelIndex)
                            {
                                UnhookSingleEntityOutput(caller, "OnBreak", beamBreak);
                                AcceptEntityInput(caller,"Kill");
                                g_BeamsTripmine[caller] = 0;

                                //SetConVarBool(cvTurboPhysics, true);
                                //CreateTimer(2.0, RestorePhysics);

                                AcceptEntityInput(tripmine,"Break");
                                tripmineOK = true;
                            }
                        }
                    }

                    // Just in case
                    if (!tripmineOK)
                    {
                        decl String:target[16];
                        GetEntPropString(caller, Prop_Data, "m_iName", target, sizeof(target));
                        ReplaceString(target, sizeof(target),"beam","mine");

                        new String:tmp[64];
                        Format(tmp, sizeof(tmp), "%s,Break,,0,-1", target);
                        DispatchKeyValue(caller, "OnTouchedByEntity", tmp);
                    }
                }
                else
                {
                    // Beams seem to be good for only 1 touch,
                    // so re-create it everytime someone touches it!

                    decl Float:start[3];
                    GetEntPropVector(caller, Prop_Data, "m_vecOrigin", start);

                    decl Float:end[3];
                    GetEntPropVector(caller, Prop_Data, "m_vecEndPos", end);

                    AcceptEntityInput(caller,"Kill"); // Kill the old beam
                    g_BeamsTripmine[tripmine] = 0;

                    if (tripmine > 0 && IsValidEntity(tripmine))
                    {
                        if (GetEntityNetClass(tripmine,class,sizeof(class)) &&
                            StrEqual(class, "CDynamicProp"))
                            //StrEqual(class, "CPhysicsProp"))
                        {
                            if (GetEntProp(tripmine,Prop_Send,"m_nModelIndex") == gTripmineModelIndex)
                            {
                                decl String:beamname[16], String:minename[16];
                                GetEntPropString(caller, Prop_Data, "m_iName", beamname, sizeof(beamname));
                                strcopy(minename, sizeof(minename), beamname);
                                ReplaceString(minename, sizeof(minename),"beam","mine");
                                CreateBeam(owner, tripmine, minename, beamname, start, end, 0.5, true);
                            }
                        }
                    }
                }
            }
        }
    }
}

public mineHealth(const String:output[], caller, activator, Float:delay)
{
    // Ensure the entity is still a tripmine
    if (IsValidEntity(caller))
    {
        decl String:class[32]; class[0] = '\0';
        if (GetEntityNetClass(caller,class,sizeof(class)) &&
            StrEqual(class, "CDynamicProp"))
            //StrEqual(class, "CPhysicsProp"))
        {
            if (GetEntProp(caller,Prop_Send,"m_nModelIndex") == gTripmineModelIndex)
            {
                new owner = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity");
                new cTeam = GetEntProp(caller, Prop_Data, "m_iTeamNum");

                if (activator > MaxClients || activator == owner ||
                    cTeam != GetClientTeam(activator))
                {
                    UnhookSingleEntityOutput(caller, "OnHealthChanged", mineHealth);
                    UnhookSingleEntityOutput(caller, "OnTakeDamage", mineHealth);
                    UnhookSingleEntityOutput(caller, "OnAwakened", mineHealth);

                    //SetConVarBool(cvTurboPhysics, true);
                    //CreateTimer(2.0, RestorePhysics);

                    AcceptEntityInput(caller,"Break");
                }
                else
                    HookSingleEntityOutput(caller, output, mineHealth, true);
            }
        }
    }
}

public mineBreak(const String:output[], caller, activator, Float:delay)
{
    new beam = g_TripminesBeam[caller];
    g_TripminesBeam[caller] = 0;
    g_BeamsTripmine[beam] = 0;

    // Ensure the entity is still a tripmine
    decl String:class[32]; class[0] = '\0';
    if (IsValidEntity(caller) &&
        GetEntityNetClass(caller,class,sizeof(class)))
    {
        if (StrEqual(class, "CDynamicProp"))
        //if (StrEqual(class, "CPhysicsProp"))
        {
            if (GetEntProp(caller,Prop_Send,"m_nModelIndex") == gTripmineModelIndex)
            {
                if (GetConVarBool(cvTeamSpecific))
                {
                    UnhookSingleEntityOutput(caller, "OnHealthChanged", mineHealth);
                    UnhookSingleEntityOutput(caller, "OnTakeDamage", mineHealth);
                    UnhookSingleEntityOutput(caller, "OnAwakened", mineHealth);
                }

                UnhookSingleEntityOutput(caller, "OnBreak", mineBreak);
                AcceptEntityInput(caller,"Kill");

                //SetConVarBool(cvTurboPhysics, true);
                //CreateTimer(2.0, RestorePhysics);

                if (GetConVarBool(cvType))
                {
                    // Set everyone in range on fire
                    new owner = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity");
                    new team = 0;
                    if (!GetConVarBool(cvFriendlyFire))
                        team = GetEntProp(caller, Prop_Data, "m_iTeamNum");

                    new Float:vecPos[3];
                    GetEntPropVector(caller, Prop_Send, "m_vecOrigin", vecPos);

                    new Float:PlayerPosition[3];
                    new Float:maxdistance = GetConVarFloat(cvRadius);
                    for (new i = 1; i <= MaxClients; i++)
                    {
                        if (IsClientInGame(i))
                        {
                            GetClientAbsOrigin(i, PlayerPosition);
                            if (GetVectorDistance(PlayerPosition, vecPos) <= maxdistance)
                            {
                                if (i == owner)
                                    IgniteEntity(i, 2.5);
                                else if (team != GetClientTeam(i))
                                {
                                    if (GameType == tf2)
                                    {
                                        new cond = GetEntProp(i, Prop_Send, "m_nPlayerCond");
                                        if (!(cond & 32))
                                        {
                                            if (owner > 0 && IsClientInGame(owner))
                                                TF2_IgnitePlayer(i, owner);
                                            else
                                                IgniteEntity(i, 2.5);
                                        }
                                    }
                                    else
                                        IgniteEntity(i, 2.5);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Ensure the beam entity is still a beam
    if (beam > 0 && IsValidEntity(beam))
    {
        if (GetEntityNetClass(beam,class,sizeof(class)) &&
            StrEqual(class, "CBeam", false))
        {
            if (GetEntProp(beam,Prop_Send,"m_nModelIndex") == gLaserModelIndex)
            {
                if (GetConVarBool(cvTeamSpecific))
                    UnhookSingleEntityOutput(beam, "OnTouchedByEntity", beamTouched);

                UnhookSingleEntityOutput(beam, "OnBreak", beamBreak);
                AcceptEntityInput(beam,"Kill");
            }
        }
    }
}

public beamBreak(const String:output[], caller, activator, Float:delay)
{
    new tripmine = g_BeamsTripmine[caller];
    g_TripminesBeam[tripmine] = 0;
    g_BeamsTripmine[caller] = 0;

    if (IsValidEntity(caller))
    {
        decl String:class[32]; class[0] = '\0';
        if (GetEntityNetClass(caller,class,sizeof(class)) &&
            StrEqual(class, "CBeam", false))
        {
            if (GetEntProp(caller,Prop_Send,"m_nModelIndex") == gLaserModelIndex)
            {
                if (GetConVarBool(cvTeamSpecific))
                    UnhookSingleEntityOutput(caller, "OnTouchedByEntity", beamTouched);

                UnhookSingleEntityOutput(caller, "OnBreak", beamBreak);
                AcceptEntityInput(caller,"Kill");
            }
        }
    }

    if (tripmine > 0 && IsValidEntity(tripmine))
    {
        decl String:class[32]; class[0] = '\0';
        if (GetEntityNetClass(tripmine,class,sizeof(class)) &&
            StrEqual(class, "CDynamicProp"))
            //StrEqual(class, "CPhysicsProp"))
        {
            // Ensure the tripmine is still a tripmine
            if (GetEntProp(tripmine,Prop_Send,"m_nModelIndex") == gTripmineModelIndex)
            {
                //SetConVarBool(cvTurboPhysics, true);
                //CreateTimer(2.0, RestorePhysics);

                AcceptEntityInput(tripmine,"Break");
            }
        }
    }
}

public bool:FilterAll(entity, contentsMask)
{
    return false;
}

public Action:Command_BuyTripMines(client, args)
{
    if (!client || IsFakeClient(client) || !IsPlayerAlive(client) || gInBuyZone == -1 || gAccount == -1)
        return Plugin_Handled;

    // args
    new cnt = 1;
    if (args > 0)
    {
        decl String:txt[MAX_LINE_LEN];
        GetCmdArg(1, txt, sizeof(txt));
        cnt = StringToInt(txt);
    }

    // buy
    if (cnt > 0)
    {
        // check buy zone
        if (!GetEntData(client, gInBuyZone, 1))
        {
            PrintCenterText(client, "%t", "notinbuyzone");
            return Plugin_Handled;
        }

        new max = GetConVarInt(cvNumMines);
        new cost = GetConVarInt(cvMineCost);
        new money = GetEntData(client, gAccount);
        do
        {
            // check max count
            if (gRemaining[client] >= max)
            {
                PrintHintText(client, "%t", "maxmines", max);
                return Plugin_Handled;
            }

            // have money?
            money-= cost;
            if (money < 0)
            {
                PrintHintText(client, "%t", "nomoney", cost, gRemaining[client]);
                EmitSoundToClient(client, SND_CANTBUY);
                return Plugin_Handled;
            }

            // deal
            SetEntData(client, gAccount, money);
            gRemaining[client]++;
            EmitSoundToClient(client, SND_BUYMINE);

        } while(--cnt);
    }

    // info
    PrintHintText(client, "%t", "cntmines", gRemaining[client]);

    return Plugin_Handled;
}
stock SetupPreloadTrie()
{
    if (g_precacheTrie == INVALID_HANDLE)
        g_precacheTrie = CreateTrie();
    else
        ClearTrie(g_precacheTrie);
}

stock PrepareSound(const String:sound[], bool:preload=false)
{
    //if (!IsSoundPrecached(sound))
    new bool:value;
    if (!GetTrieValue(g_precacheTrie, sound, value))
    {
        PrecacheSound(sound,preload);
        SetTrieValue(g_precacheTrie, sound, true);
    }
}

stock PrepareModel(const String:model[], &index, bool:preload=false)
{
    if (index <= 0)
        index = PrecacheModel(model,preload);

    return index;
}

public Native_ControlTripmines(Handle:plugin,numParams)
{
    if (numParams == 0)
        gNativeControl = true;
    else if(numParams == 1)
        gNativeControl = GetNativeCell(1);
}

public Native_GiveTripmines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        gRemaining[client] = (numParams >= 2) ? GetNativeCell(2) : -1;
        gAllowed[client] = (numParams >= 3) ? GetNativeCell(3) : -1;
        gMaximum[client] = (numParams >= 4) ? GetNativeCell(4) : -1;

        if (gMaximum[client] < 0)
            gMaximum[client] = GetConVarInt(cvMaxMines);
    }
}

public Native_TakeTripmines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        gRemaining[client] = gAllowed[client] = gMaximum[client] = 0;
    }
}

public Native_AddTripmines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        new num = (numParams >= 2) ? GetNativeCell(2) : 1;
        gRemaining[client] += num;
    }
}

public Native_SubTripmines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        new num = (numParams >= 2) ? GetNativeCell(2) : 1;

        gRemaining[client] -= num;
        if (gRemaining[client] < 0)
            gRemaining[client] = 0;
    }
}

public Native_HasTripmines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        return ((numParams >= 2) && GetNativeCell(2)) ? gAllowed[client] : gRemaining[client];
    }
    else
        return -1;
}

public Native_SetTripmine(Handle:plugin,numParams)
{
    if (numParams == 1)
        SetMine(GetNativeCell(1));
}

public Native_CountTripmines(Handle:plugin,numParams)
{
    if (numParams == 1)
        return CountMines(GetNativeCell(1));
    else
        return -1;
}

public Native_HookSetTripmine(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        AddToForward(fwdOnSetTripmine, plugin, Function:GetNativeCell(1));
        gSetTripmineHooked = true;
    }
}
