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
#include <tf2_player>
#define REQUIRE_EXTENSIONS

#include <gametype>

#define PLUGIN_VERSION "1.1.0.3"

#define TRACE_START 24.0
#define TRACE_END 64.0

#define MDL_LASER "sprites/laser.vmt"
#define MDL_MINE "models/props_lab/tpplug.mdl"

#define SND_MINEPUT "npc/roller/blade_cut.wav"
#define SND_MINEACT "npc/roller/mine/rmine_blades_in2.wav"
#define SND_MINEERR "common/wpn_denyselect.wav"

#define TEAM_T 2
#define TEAM_CT 3

#define COLOR_T "255 0 0"
#define COLOR_CT "0 0 255"
#define COLOR_DEF "0 255 255"

#define MAX_LINE_LEN 256

// globals
new gRemaining[MAXPLAYERS+1];    // how many tripmines player has this spawn
new gCount = 1;
new String:mdlMine[256];

new bool:gNativeControl = false;
new gAllowed[MAXPLAYERS+1];    // how many tripmines player allowed

new Handle:gMineList[MAXPLAYERS+1];
new gTripmineModelIndex;

// convars
new Handle:cvNumMines = INVALID_HANDLE;
new Handle:cvActTime = INVALID_HANDLE;
new Handle:cvModel = INVALID_HANDLE;
new Handle:cvTeamRestricted = INVALID_HANDLE;
new Handle:cvDestruct = INVALID_HANDLE;
new Handle:cvRadius = INVALID_HANDLE;
new Handle:cvDamage = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Tripmines",
    author = "L. Duke (mod by user)",
    description = "Plant a trip mine",
    version = PLUGIN_VERSION,
    url = "http://www.lduke.com/"
};

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    // Register Natives
    CreateNative("ControlTripmines",Native_ControlTripmines);
    CreateNative("GiveTripmine",Native_GiveTripmine);
    CreateNative("HasTripmine",Native_HasTripmine);
    CreateNative("SetTripmine",Native_SetTripmine);
    RegPluginLibrary("tripmines");
    return true;
}

public OnPluginStart() 
{
    GetGameType();

    // events
    HookEvent("player_death", PlayerDeath);
    HookEvent("player_spawn",PlayerSpawn);

    // convars
    CreateConVar("sm_tripmines_version", PLUGIN_VERSION, "Tripmines", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    cvNumMines = CreateConVar("sm_tripmines_allowed", "3", "Number of tripmines allowed per life (-1=unlimited)");
    cvActTime = CreateConVar("sm_tripmines_activate_time", "2.0", "Tripmine activation time.");
    cvModel = CreateConVar("sm_tripmines_model", MDL_MINE, "Tripmine model");
    cvTeamRestricted = CreateConVar("sm_tripmines_restrictedteam", "0", "Team that does NOT get any tripmines");
    cvDestruct = CreateConVar("sm_tripmines_destruct", "1", "Tripmines self-destruct when owner dies");
    cvRadius = CreateConVar("sm_tripmines_radius", "256", "Tripmines Explosion Radius");
    cvDamage = CreateConVar("sm_tripmines_radius", "200", "Tripmines Explosion Damage");

    // commands
    RegConsoleCmd("sm_tripmine", Command_TripMine);
}

public OnEventShutdown()
{
    UnhookEvent("player_death", PlayerDeath);
    UnhookEvent("player_spawn", PlayerSpawn);
}

public OnMapStart()
{
    // set model based on cvar
    GetConVarString(cvModel, mdlMine, sizeof(mdlMine));

    // precache models
    PrecacheModel(mdlMine, true);
    PrecacheModel(MDL_LASER, true);

    // precache sounds
    PrecacheSound(SND_MINEPUT, true);
    PrecacheSound(SND_MINEACT, true);
    PrecacheSound(SND_MINEERR, true);
}

// When a new client is put in the server we reset their mines count
public OnClientPutInServer(client)
{
    if(client && !IsFakeClient(client))
        gRemaining[client] = 0;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (gNativeControl)
        gRemaining[client] = gAllowed[client];
    else
        gRemaining[client] = gAllowed[client] = GetConVarInt(cvNumMines);

    return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetConVarBool(cvDestruct))
    {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        gRemaining[client] = 0;

        if (gMineList[client] != INVALID_HANDLE)
        {
            new size = GetArraySize(gMineList[client]);
            for (new i = 0;  i < size; i++)
            {
                CreateTimer(float(i)*0.1, ExplodeMine, GetArrayCell(gMineList[client], i));
            }
            ClearArray(gMineList[client]);
        }
    }
    return Plugin_Continue;
}

public Action:ExplodeMine(Handle:timer, any:ent)
{
    decl String:class[32];
    if (IsValidEntity(ent) &&
        GetEntityNetClass(ent,class,sizeof(class)))
    {
        if (StrEqual(class, "CPhysicsProp", false))
        {
            // Make sure it's a tripmine
            if (GetEntProp(ent,Prop_Send,"m_nModelIndex") == gTripmineModelIndex)
                AcceptEntityInput(ent, "Break");
        }
    }
    return Plugin_Stop;
}

public Action:Command_TripMine(client, args)
{  
    // make sure client is not spectating
    if (!IsPlayerAlive(client))
        return Plugin_Handled;

    // check restricted team 
    new team = GetClientTeam(client);
    if(team == GetConVarInt(cvTeamRestricted))
    { 
        PrintHintText(client, "Your team does not have access to this equipment.");
        return Plugin_Handled;
    }

    SetMine(client);
    return Plugin_Handled;
}

SetMine(client)
{
    if (gRemaining[client] <= 0 && gAllowed[client] >= 0)
    {
        PrintHintText(client, "You do not have any tripmines.");
        return;
    }

    if (GameType == tf2)
    {
        if (TF2_GetPlayerClass(client) == TFClass_Spy)
        {
            if (TF2_IsPlayerCloaked(client))
            {
                EmitSoundToClient(client, SND_MINEERR);
                return;
            }
            else
                TF2_RemovePlayerDisguise(client);
        }
    }

    // setup unique target names for entities to be created with
    new String:beam[64];
    new String:beammdl[64];
    new String:tmp[128];
    Format(beam, sizeof(beam), "tmbeam%d", gCount);
    Format(beammdl, sizeof(beammdl), "tmbeammdl%d", gCount);
    gCount++;
    if (gCount>10000)
        gCount = 1;

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
        gRemaining[client]--;

        // find angles for tripmine
        TR_GetEndPosition(end, INVALID_HANDLE);
        TR_GetPlaneNormal(INVALID_HANDLE, normal);
        GetVectorAngles(normal, normal);

        // trace laser beam
        TR_TraceRayFilter(end, normal, CONTENTS_SOLID, RayType_Infinite, FilterAll, 0);
        TR_GetEndPosition(beamend, INVALID_HANDLE);

        // create tripmine model
        new prop_ent = CreateEntityByName("prop_physics_override");
        SetEntityModel(prop_ent,mdlMine);
        DispatchKeyValue(prop_ent, "StartDisabled", "false");
        DispatchSpawn(prop_ent);
        TeleportEntity(prop_ent, end, normal, NULL_VECTOR);
        SetEntProp(prop_ent, Prop_Data, "m_usSolidFlags", 152);
        SetEntProp(prop_ent, Prop_Data, "m_CollisionGroup", 1);
        SetEntityMoveType(prop_ent, MOVETYPE_NONE);
        SetEntProp(prop_ent, Prop_Data, "m_MoveCollide", 0);
        SetEntProp(prop_ent, Prop_Data, "m_nSolidType", 6);
        SetEntPropEnt(prop_ent, Prop_Data, "m_hLastAttacker", client);
        DispatchKeyValue(prop_ent, "targetname", beammdl);
        GetConVarString(cvRadius, tmp, sizeof(tmp));
        DispatchKeyValue(prop_ent, "ExplodeRadius", tmp);
        GetConVarString(cvDamage, tmp, sizeof(tmp));
        DispatchKeyValue(prop_ent, "ExplodeDamage", tmp);
        Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
        DispatchKeyValue(prop_ent, "OnHealthChanged", tmp);
        Format(tmp, sizeof(tmp), "%s,Kill,,0,-1", beam);
        DispatchKeyValue(prop_ent, "OnBreak", tmp);
        SetEntProp(prop_ent, Prop_Data, "m_takedamage", 2);
        AcceptEntityInput(prop_ent, "Enable");

        if (gMineList[client] == INVALID_HANDLE)
            gMineList[client] = CreateArray();

        gTripmineModelIndex = GetEntProp(prop_ent,Prop_Send,"m_nModelIndex");
        PushArrayCell(gMineList[client], prop_ent);

        // create laser beam
        new beam_ent = CreateEntityByName("env_beam");
        TeleportEntity(beam_ent, beamend, NULL_VECTOR, NULL_VECTOR);
        SetEntityModel(beam_ent, MDL_LASER);
        DispatchKeyValue(beam_ent, "texture", MDL_LASER);
        DispatchKeyValue(beam_ent, "targetname", beam);
        DispatchKeyValue(beam_ent, "TouchType", "4");
        DispatchKeyValue(beam_ent, "LightningStart", beam);
        DispatchKeyValue(beam_ent, "BoltWidth", "4.0");
        DispatchKeyValue(beam_ent, "life", "0");
        DispatchKeyValue(beam_ent, "rendercolor", "0 0 0");
        DispatchKeyValue(beam_ent, "renderamt", "0");
        DispatchKeyValue(beam_ent, "HDRColorScale", "1.0");
        DispatchKeyValue(beam_ent, "decalname", "Bigshot");
        DispatchKeyValue(beam_ent, "StrikeTime", "0");
        DispatchKeyValue(beam_ent, "TextureScroll", "35");
        Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
        DispatchKeyValue(beam_ent, "OnTouchedByEntity", tmp);   
        SetEntPropVector(beam_ent, Prop_Data, "m_vecEndPos", end);
        SetEntPropFloat(beam_ent, Prop_Data, "m_fWidth", 4.0);
        AcceptEntityInput(beam_ent, "TurnOff");

        new Handle:data = CreateDataPack();
        CreateTimer(GetConVarFloat(cvActTime), TurnBeamOn, data);
        WritePackCell(data, client);
        WritePackCell(data, beam_ent);
        WritePackFloat(data, end[0]);
        WritePackFloat(data, end[1]);
        WritePackFloat(data, end[2]);

        // play sound
        EmitSoundToAll(SND_MINEPUT, beam_ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, beam_ent, end, NULL_VECTOR, true, 0.0);

        // send message
        PrintHintText(client, "Tripmines remaining: %d", gRemaining[client]);
    }
    else
    {
        PrintHintText(client, "Invalid location for Tripmine");
    }
}

public Action:TurnBeamOn(Handle:timer, Handle:data)
{
    decl String:color[26];

    ResetPack(data);
    new client = ReadPackCell(data);
    new ent = ReadPackCell(data);

    if (IsValidEntity(ent))
    {
        new team = GetClientTeam(client);
        if(team == TEAM_T) color = COLOR_T;
        else if(team == TEAM_CT) color = COLOR_CT;
        else color = COLOR_DEF;

        DispatchKeyValue(ent, "rendercolor", color);
        AcceptEntityInput(ent, "TurnOn");

        new Float:end[3];
        end[0] = ReadPackFloat(data);
        end[1] = ReadPackFloat(data);
        end[2] = ReadPackFloat(data);

        EmitSoundToAll(SND_MINEACT, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, ent, end, NULL_VECTOR, true, 0.0);
    }

    CloseHandle(data);
    return Plugin_Stop;
}

public bool:FilterAll (entity, contentsMask)
{
    return false;
}

public Native_ControlTripmines(Handle:plugin,numParams)
{
    if (numParams == 0)
        gNativeControl = true;
    else if(numParams == 1)
        gNativeControl = GetNativeCell(1);
}

public Native_GiveTripmine(Handle:plugin,numParams)
{
    if (numParams >= 1 && numParams <= 2)
    {
        new client = GetNativeCell(1);
        gRemaining[client] = gAllowed[client] = (numParams >= 2) ? GetNativeCell(2) : GetConVarInt(cvNumMines);
    }
}

public Native_HasTripmine(Handle:plugin,numParams)
{
    if (numParams >= 1 && numParams <= 2)
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
