/**
 * vim: set ai et ts=4 sw=4 :
 * File: zgrabber.sp
 * Description: dis is z grabber (gravgun).
 * Author(s): L. Duke
 * Modified by: -=|JFH|=-Naris (Murray Wilson)
 *              -- Added support for grabbing TF2 buildings
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0.0.2"

// These define the permissions
#define HAS_GRABBER		            (1 << 0)
#define CAN_STEAL		            (1 << 1)
#define CAN_GRAB_PROPS		        (1 << 2)
#define CAN_GRAB_BUILDINGS		    (1 << 3)
#define CAN_GRAB_OTHER_BUILDINGS    (1 << 4)
#define CAN_THROW_BUILDINGS         (1 << 5)

enum grabType { none, prop, building };

// globals
new gObj[MAXPLAYERS+1];                 // what object the player is holding
new grabType:gType[MAXPLAYERS+1];       // type of object grabbed
new MoveType:gMove[MAXPLAYERS+1];       // movetype of object grabbed
new Float:gGrabTime[MAXPLAYERS+1];      // when the object was grabbed
new Float:gMaxDuration[MAXPLAYERS+1];   // max time allow to hold onto buildings
new bool:gJustGrabbed[MAXPLAYERS+1];    // object was grabbed when button was pushed
new Float:gGravity[MAXPLAYERS+1];       // gravity of object grabbed
new Float:gThrow[MAXPLAYERS+1];         // throw charge state 

new gPermissions[MAXPLAYERS+1];         // Permissions for each player
new Float:gThrowSpeed[MAXPLAYERS+1];    // speed of objects thrown by player
new Float:gThrowGravity[MAXPLAYERS+1];  // gravity of objects thrown by player

new Handle:gTimer;       
new String:gSound[256];
new String:gMissSound[256];
new String:gInvalidSound[256];
new String:gBuildingSound[256];
new String:gPickupSound[256];
new String:gThrowSound[256];
new String:gDropSound[256];

new bool:gNativeOverride = false;
new bool:gPickupObjectHooked = false;
new bool:gThrowObjectHooked = false;
new bool:gDropObjectHooked = false;
new bool:gObjectStopHooked = false;

// forwards
new Handle:fwdOnPickupObject;
new Handle:fwdOnThrowObject;
new Handle:fwdOnDropObject;
new Handle:fwdOnObjectStop;

// convars
new Handle:cvSpeed = INVALID_HANDLE;
new Handle:cvDistance = INVALID_HANDLE; 
new Handle:cvTeamRestrict = INVALID_HANDLE;
new Handle:cvSound = INVALID_HANDLE;
new Handle:cvBuildingSound = INVALID_HANDLE;
new Handle:cvInvalidSound = INVALID_HANDLE;
new Handle:cvMissSound = INVALID_HANDLE;
new Handle:cvPickupSound = INVALID_HANDLE;
new Handle:cvThrowSound = INVALID_HANDLE;
new Handle:cvDropSound = INVALID_HANDLE;
new Handle:cvGround = INVALID_HANDLE;
new Handle:cvThrowTime = INVALID_HANDLE;
new Handle:cvThrowMinTime = INVALID_HANDLE;
new Handle:cvThrowSpeed = INVALID_HANDLE;
new Handle:cvMaxDistance = INVALID_HANDLE;
new Handle:cvMaxDuration = INVALID_HANDLE;
new Handle:cvSteal = INVALID_HANDLE;
new Handle:cvProps = INVALID_HANDLE;
new Handle:cvBuildings = INVALID_HANDLE;
new Handle:cvOtherBuildings = INVALID_HANDLE;
new Handle:cvThrowBuildings = INVALID_HANDLE;
new Handle:cvThrowGravity = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Grabber:SM",
    author = "L. Duke",
    description = "grabber (gravgun)",
    version = PLUGIN_VERSION,
    url = "http://www.lduke.com/"
};

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    // Register Natives
    CreateNative("ControlZGrabber",Native_ControlZGrabber);
    CreateNative("HookPickupObject",Native_HookPickupObject);
    CreateNative("HookThrowObject",Native_HookThrowObject);
    CreateNative("HookDropObject",Native_HookDropObject);
    CreateNative("HookObjectStop",Native_HookObjectStop);
    CreateNative("GiveGravgun",Native_GiveGravgun);
    CreateNative("TakeGravgun",Native_TakeGravgun);
    CreateNative("PickupObject",Native_PickupObject);
    CreateNative("DropObject",Native_DropObject);
    CreateNative("StartThrowObject",Native_StartThrowObject);
    CreateNative("ThrowObject",Native_ThrowObject);

    // Register Forwards
    fwdOnPickupObject=CreateForward(ET_Hook,Param_Cell,Param_Cell,Param_Cell);
    fwdOnThrowObject=CreateForward(ET_Hook,Param_Cell,Param_Cell);
    fwdOnDropObject=CreateForward(ET_Ignore,Param_Cell,Param_Cell);
    fwdOnObjectStop=CreateForward(ET_Ignore,Param_Cell);

    RegPluginLibrary("zgrabber");
    return true;
}


public OnPluginStart() 
{
    // events
    HookEvent("player_death", PlayerDeath);
    HookEvent("player_spawn",PlayerSpawn);

    // convars
    CreateConVar("sm_grabber_version", PLUGIN_VERSION, "Grabber:SM Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    cvSpeed = CreateConVar("sm_grabber_speed", "15.0");
    cvDistance = CreateConVar("sm_grabber_distance", "100.0");
    cvTeamRestrict = CreateConVar("sm_grabber_team_restrict", "0", "team restriction (0=all use, 2 or 3 to restrict that team");
    cvSound = CreateConVar("sm_grabber_sound", "weapons/physcannon/hold_loop.wav", "sound to play, change takes effect on map change");
    cvBuildingSound = CreateConVar("sm_grabber_buildingsound", "weapons/physcannon/superphys_hold_loop.wav", "sound to play, change takes effect on map change");
    cvMissSound = CreateConVar("sm_grabber_misssound", "weapons/physcannon/physcannon_dryfire.wav", "sound to play for misses, change takes effect on map change");
    cvInvalidSound = CreateConVar("sm_grabber_invalidsound", "weapons/physcannon/physcannon_tooheavy.wav", "sound to play for errors, change takes effect on map change");
    cvPickupSound = CreateConVar("sm_grabber_pickupsound", "weapons/physcannon/physcannon_pickup.wav", "sound to play for pickup, change takes effect on map change");
    cvThrowSound = CreateConVar("sm_grabber_throwsound", "weapons/physcannon/superphys_launch1.wav", "sound to play for throw, change takes effect on map change");
    cvDropSound = CreateConVar("sm_grabber_dropsound", "weapons/physcannon/physcannon_drop.wav", "sound to play for drop, change takes effect on map change");
    cvGround = CreateConVar("sm_grabber_groundmode", "0", "ground mode (soccer) 0=off 1=on");
    cvThrowTime = CreateConVar("sm_grabber_throwtime", "2.0", "time to charge up to full throw speed");
    cvThrowMinTime = CreateConVar("sm_grabber_throwtimemin", "0.2", "minimum time to throw (less time drops)");
    cvThrowSpeed = CreateConVar("sm_grabber_throwspeed", "1000.0", "speed at which an object is thrown");
    cvMaxDistance = CreateConVar("sm_grabber_maxdistance", "512.0", "maximum distance from which you can grab an object");
    cvMaxDuration = CreateConVar("sm_grabber_duration", "0.0", "maximum time a building can be held (0.0=unlimited)");
    cvSteal = CreateConVar("sm_grabber_steal", "1", "can objects be 'stolen' from other players (0=no 1=yes)");
    cvProps = CreateConVar("sm_grabber_props", "1", "can props be picked up (0=no 1=yes)");
    cvBuildings = CreateConVar("sm_grabber_buildings", "1", "can buildings be picked up (0=no 1=yes)");
    cvOtherBuildings = CreateConVar("sm_grabber_otherbuildings", "1", "can other player's buildings be picked up (0=no 1=yes)");
    cvThrowBuildings = CreateConVar("sm_grabber_throwbuildings", "1", "can buildings be thrown (0=no 1=yes)");
    cvThrowGravity = CreateConVar("sm_grabber_throwgravity", "1.0", "gravity for an object that is thrown");

    // commands
    RegConsoleCmd("+grav", Command_Grab);
    RegConsoleCmd("-grav", Command_UnGrab2);
    RegConsoleCmd("+throw", Command_Throw);
    RegConsoleCmd("-throw", Command_UnThrow);
}

public OnPluginEnd()
{
    UnhookEvent("player_death", PlayerDeath);
    UnhookEvent("player_spawn",PlayerSpawn);
}

public OnMapStart()
{ 
    // reset object list
    for (new i=0; i<=MAXPLAYERS; i++)
    {
        gObj[i]=-1;
        gThrow[i]=0.0;
        gGrabTime[i]=0.0;
        gJustGrabbed[i] = false;
    }

    // start timer
    gTimer = CreateTimer(0.1, UpdateObjects, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

    // precache sounds
    GetConVarString(cvSound, gSound, sizeof(gSound));
    GetConVarString(cvMissSound, gMissSound, sizeof(gMissSound));
    GetConVarString(cvInvalidSound, gInvalidSound, sizeof(gInvalidSound));
    GetConVarString(cvPickupSound, gPickupSound, sizeof(gPickupSound));
    GetConVarString(cvBuildingSound, gBuildingSound, sizeof(gBuildingSound));
    GetConVarString(cvThrowSound, gThrowSound, sizeof(gThrowSound));
    GetConVarString(cvDropSound, gDropSound, sizeof(gDropSound));
    PrecacheSound(gSound, true);
    PrecacheSound(gMissSound, true);
    PrecacheSound(gInvalidSound, true);
    PrecacheSound(gPickupSound, true);
    PrecacheSound(gBuildingSound, true);
    PrecacheSound(gThrowSound, true);
    PrecacheSound(gDropSound, true);
}

public OnMapEnd()
{
    CloseHandle(gTimer);
}

// When a new client is put in the server we reset their status
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
    if(client && !IsFakeClient(client))
    {
        gObj[client] = -1;
        gThrow[client]=0.0;
        gGrabTime[client]=0.0;
        gJustGrabbed[client] = false;
        gPermissions[client] = 0;
    }
    return true;
}

public OnClientDisconnect(client)
{
    if (gObj[client]>0)
        Command_UnGrab(client, 0);
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    // reset object held
    gObj[client] = -1;
    gThrow[client]=0.0;
    gGrabTime[client]=0.0;
    gJustGrabbed[client] = false;

    StopSound(client, SNDCHAN_AUTO, gSound);
    StopSound(client, SNDCHAN_AUTO, gBuildingSound);

    if (!gNativeOverride)
    {
        // check team restrictions
        new restrict = GetConVarInt(cvTeamRestrict);
        if (restrict == 0 || restrict != GetClientTeam(client))
        {
            gThrowSpeed[client] = GetConVarFloat(cvThrowSpeed);
            gThrowGravity[client] = GetConVarFloat(cvThrowGravity);
            gMaxDuration[client] = GetConVarFloat(cvMaxDuration); 

            gPermissions[client] = HAS_GRABBER;

            if (GetConVarInt(cvSteal)==1)
                gPermissions[client] |= CAN_STEAL;

            if (GetConVarInt(cvProps)==1)
                gPermissions[client] |= CAN_GRAB_PROPS;

            if (GetConVarInt(cvBuildings)==1)
                gPermissions[client] |= CAN_GRAB_BUILDINGS;

            if (GetConVarInt(cvOtherBuildings)==1)
                gPermissions[client] |= CAN_GRAB_OTHER_BUILDINGS;

            if (GetConVarInt(cvThrowBuildings)==1)
                gPermissions[client] |= CAN_THROW_BUILDINGS;
        }
        else
            gPermissions[client] = 0;
    }

    return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (gObj[client]>0)
        Command_UnGrab(client, 0);

    // make sure to reset object held
    gObj[client] = -1;
    gThrow[client]=0.0;
    gGrabTime[client]=0.0;
    gJustGrabbed[client] = false;
    StopSound(client, SNDCHAN_AUTO, gSound);
    StopSound(client, SNDCHAN_AUTO, gBuildingSound);
    return Plugin_Continue;
}

public Action:Command_Grab(client, args)
{  
    // if an object is being held, go to UnGrab
    if (gObj[client]>0)
        return Command_UnGrab(client, args);

    // make sure client is not spectating
    else if (!IsPlayerAlive(client))
        return Plugin_Handled;

    // check if client has a grabber
    else if (!(gPermissions[client] & HAS_GRABBER))
        return Plugin_Handled;

    new groundmode = GetConVarInt(cvGround);

    // find entity
    new ent = TraceToEntity(client);
    if (ent == -1)
    {
        if (groundmode!=1)
            EmitSoundToAll(gMissSound, client);

        return Plugin_Handled;
    }

    new String:edictname[128];
    GetEdictClassname(ent, edictname, 128);

    //LogMessage("%N's Target is a %s", client, edictname);
    //PrintToChat(client, "Target is a %s", edictname);

    new builder=0;
    new grabType:grab;
    if (strncmp("prop_", edictname, 5, false)==0)
        grab = prop; // grab physics entities
    else if (strncmp("obj_", edictname, 4, false)==0)
        grab = building; // grab buildings
    else
        grab = none;

    // only grab physics entities?
    if (grab == building)
    {
        builder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");

        if (!(gPermissions[client] & CAN_GRAB_BUILDINGS))
        {
            if (groundmode!=1)
                EmitSoundToAll(gInvalidSound, client);

            return Plugin_Handled;
        }
        else
        {
            new Float:complete = GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed");
            if (complete < 1.0)
            {
                if (groundmode!=1)
                    EmitSoundToAll(gInvalidSound, client);

                return Plugin_Handled;
            }
            else
            {
                if (!(gPermissions[client] & CAN_GRAB_OTHER_BUILDINGS))
                {
                    if (builder != client)
                    {
                        if (groundmode!=1)
                            EmitSoundToAll(gInvalidSound, client);

                        return Plugin_Handled;
                    }
                }
            }
        }
    }
    else
    {
        if (!(gPermissions[client] & CAN_GRAB_PROPS))
        {
            if (groundmode!=1)
                EmitSoundToAll(gInvalidSound, client);

            return Plugin_Handled;
        }
    }

    if (grab)
    {
        // check if another player is holding it
        new maxplayers = GetMaxClients();
        for (new j=1; j<=maxplayers; j++)
        {
            if (gObj[j]==ent)
            {
                if (gPermissions[client] & CAN_STEAL)
                {
                    // steal from other player
                    Command_UnGrab(j, args);
                    break;
                }
                else
                {
                    // already being held - stealing not allowed
                    if (groundmode!=1)
                        EmitSoundToAll(gInvalidSound, client);

                    return Plugin_Handled;
                }
            }
        }

        new Action:res = Plugin_Continue;
        if (gPickupObjectHooked)
        {
            Call_StartForward(fwdOnPickupObject);
            Call_PushCell(client);
            Call_PushCell(builder);
            Call_PushCell(ent);
            Call_Finish(res);
        }

        if (res == Plugin_Continue)
        {
            // grab entity
            gObj[client] = ent;
            gType[client] = grab;
            gThrow[client] = 0.0;
            gGrabTime[client] = GetEngineTime();
            gGravity[client] = GetEntityGravity(ent);
            gMove[client] = GetEntityMoveType(ent);
            gJustGrabbed[client] = true;

            if (groundmode!=1)
            {
                SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);
                EmitSoundToAll(gPickupSound, client);
                if (grab == building)
                    EmitSoundToAll(gBuildingSound, client);
                else
                    EmitSoundToAll(gSound, client);
            }
            else
                SetEntityMoveType(ent, MOVETYPE_FLY);
        }
        else
        {
            if (groundmode!=1)
                EmitSoundToAll(gInvalidSound, client);
        }
    }
    else
    {
        if (groundmode!=1)
            EmitSoundToAll(gMissSound, client);
    }

    return Plugin_Handled;
}

public Action:Command_UnGrab(client, args)
{
    if (gThrow[client]>0.0)
        PrintHintText(client, " ");

    new ent = gObj[client];
    if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
    {
        new Float:speed[3] = { 0.0, 0.0, -1.0 };
        SetEntityGravity(ent, 10.0);
        SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);
        TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, speed);
    }

    Drop(client, false);
    return Plugin_Handled;
}

Drop(client, bool:throw)
{
    if (GetConVarInt(cvGround)!=1)
    {
        StopSound(client, SNDCHAN_AUTO, gSound); // no sound in ground mode
        StopSound(client, SNDCHAN_AUTO, gBuildingSound);
        EmitSoundToAll(gDropSound, client);
    }

    new ent = gObj[client];
    if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
    {
        new Handle:pack;
        if (CreateDataTimer(0.2,TrackObject,pack))
        {
            new Float:vecPos[3];
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPos);
            WritePackCell(pack, ent);
            WritePackCell(pack, _:gType[client]);
            WritePackCell(pack, _:gMove[client]);
            WritePackFloat(pack, gGravity[client]);
            WritePackFloat(pack, vecPos[0]);
            WritePackFloat(pack, vecPos[1]);
            WritePackFloat(pack, vecPos[2]);
        }
    }

    if (!throw)
    {
        new Action:res = Plugin_Continue;
        if (gDropObjectHooked)
        {
            Call_StartForward(fwdOnDropObject);
            Call_PushCell(client);
            Call_PushCell(ent);
            Call_Finish(res);
        }
    }

    gObj[client] = -1;
    gThrow[client] = 0.0;
    gGrabTime[client] = 0.0;
    gJustGrabbed[client] = false;
}

public Action:Command_UnGrab2(client, args)
{
    // changed so Commmand_Ungrab is called from Command_Grab if an object is already held
    // so we need to handle -grab with this function
    gJustGrabbed[client] = false;
    return Plugin_Handled;
}

public Action:Command_Throw(client, args)
{
    // make sure client is not spectating
    if (!IsPlayerAlive(client))
        return Plugin_Handled;
    // has an object?
    else if (gObj[client]<1)
        return Command_Grab(client, args);

    // is it a building that can't be thrown? 
    else if (gType[client] == building && !(gPermissions[client] & CAN_THROW_BUILDINGS))
        return Plugin_Handled;

    // start throw timer
    gThrow[client] = GetEngineTime();

    return Plugin_Handled;
}

public Action:Command_UnThrow(client, args)
{
    // return if the Throw grabbed the object
    if (gJustGrabbed[client])
    {
        gJustGrabbed[client] = false;
        return Plugin_Handled;
    }
    // make sure client is not spectating
    if (!IsPlayerAlive(client))
        return Plugin_Handled;

    // is it a building that can't be thrown? 
    if (gType[client] == building && !(gPermissions[client] & CAN_THROW_BUILDINGS))
        return Command_UnGrab(client, args);

    // has an object?
    new ent = gObj[client];
    if (ent<1)
        return Plugin_Handled;

    if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
    {
        new Action:res = Plugin_Continue;
        if (gThrowObjectHooked)
        {
            Call_StartForward(fwdOnThrowObject);
            Call_PushCell(client);
            Call_PushCell(ent);
            Call_Finish(res);
        }

        if (res == Plugin_Continue)
        {
            // throw object
            new Float:throwtime = GetConVarFloat(cvThrowTime);
            new Float:throwmintime = GetConVarFloat(cvThrowMinTime);
            new Float:throwspeed = gThrowSpeed[client];
            new Float:throwgravity = gThrowGravity[client];
            new Float:time = GetEngineTime();
            new Float:percent;

            time -= gThrow[client];
            if (time < throwmintime)
                return Command_UnGrab(client, args);
            else if ( time > throwtime)
                percent = 1.0;
            else
                percent = time/throwtime;

            throwspeed*=percent;

            if (throwspeed <= 0.0)
                return Command_UnGrab(client, args);

            new Float:start[3];
            GetClientEyePosition(client, start);
            new Float:angle[3];
            new Float:speed[3];
            GetClientEyeAngles(client, angle);
            GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
            speed[0]*=throwspeed; speed[1]*=throwspeed; speed[2]*=throwspeed;

            if (throwgravity <= 0.0)
                SetEntityMoveType(ent, MOVETYPE_FLY);
            else
            {
                SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);
                if (throwgravity != 1.0)
                    SetEntityGravity(ent, throwgravity);
            }
            TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, speed);

            if (GetConVarInt(cvGround)!=1)
                EmitSoundToAll(gThrowSound, client);
        }
    }

    // cleanup
    Drop(client, true);

    return Plugin_Handled;
}

public Action:TrackObject(Handle:timer, Handle:pack)
{
    ResetPack(pack);
    new ent = ReadPackCell(pack);
    if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
    {
        new grabType:gt = grabType:ReadPackCell(pack);
        new String:edictname[128];
        GetEdictClassname(ent, edictname, 128);

        new grabType:grab;
        if (strncmp("prop_", edictname, 5, false)==0)
            grab = prop; // grab physics entities
        else if (strncmp("obj_", edictname, 4, false)==0)
            grab = building; // grab buildings
        else
            grab = none;

        // check if the object is still the same type we picked up
        if (grab == gt)
        {
            new MoveType:mt = MoveType:ReadPackCell(pack);
            new Float:gravity = ReadPackFloat(pack);
            new Float:lastPos[3], Float:vecPos[3], Float:vecVel[3];
            lastPos[0] = ReadPackFloat(pack);
            lastPos[1] = ReadPackFloat(pack);
            lastPos[2] = ReadPackFloat(pack);
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPos);
            SubtractVectors(lastPos, vecPos, vecVel);
            if (vecVel[0] != 0.0 || vecVel[1] != 0.0 || vecVel[2] != 0.0)
            {
                new Handle:new_pack;
                if (CreateDataTimer(0.2,TrackObject,new_pack))
                {
                    WritePackCell(new_pack, ent);
                    WritePackCell(new_pack, _:mt);
                    WritePackFloat(new_pack, gravity);
                    WritePackFloat(new_pack, vecPos[0]);
                    WritePackFloat(new_pack, vecPos[1]);
                    WritePackFloat(new_pack, vecPos[2]);
                    return Plugin_Handled;
                }
            }
            SetEntityGravity(ent, gravity);
            SetEntityMoveType(ent, mt);

            new Action:res = Plugin_Continue;
            if (gObjectStopHooked)
            {
                Call_StartForward(fwdOnObjectStop);
                Call_PushCell(ent);
                Call_Finish(res);
            }
        }
    }
    return Plugin_Stop;
}

public Action:UpdateObjects(Handle:timer)
{
    new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];      // vectors
    new Float:viewang[3];                                       // angles
    new i, ent;
    new Float:speed = GetConVarFloat(cvSpeed);
    new Float:distance = GetConVarFloat(cvDistance);
    new groundmode = GetConVarInt(cvGround);
    new Float:throwtime = GetConVarFloat(cvThrowTime);
    new Float:throwmintime = GetConVarFloat(cvThrowMinTime);
    new Float:time = GetEngineTime();
    new maxplayers = GetMaxClients();
    for (i=0; i<=maxplayers; i++)
    {
        ent = gObj[i];
        if (ent>0)
        {
            if (IsValidEdict(ent) && IsValidEntity(ent))
            {
                // get client info
                GetClientEyeAngles(i, viewang);
                GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
                if (groundmode==1)
                    GetClientAbsOrigin(i, vecPos);
                else
                    GetClientEyePosition(i, vecPos);

                // update object 
                vecPos[0]+=vecDir[0]*distance;
                vecPos[1]+=vecDir[1]*distance;
                if (groundmode!=1)
                    vecPos[2]+=vecDir[2]*distance;    // don't change up/down in ground mode

                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecDir);

                SubtractVectors(vecPos, vecDir, vecVel);

                ScaleVector(vecVel, speed);
                if (groundmode==1)
                    vecVel[2]=0.0;

                TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, vecVel);

                // update throw time
                if (gThrow[i] > 0.0)
                {
                    new Float:thetime = time - gThrow[i];
                    if (thetime > throwmintime)
                        ShowBar(i, thetime, throwtime);
                }
                else if (gType[i] == building && gMaxDuration[i] > 0.0)
                {
                    new Float:thetime = time - gGrabTime[i];
                    if (thetime > gMaxDuration[i])
                        Command_UnGrab(i, 0);
                }
            }
            else
                gObj[i]=-1;
        }
    }
    return Plugin_Continue;
}

public TraceToEntity(client)
{
    new Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
    GetClientEyePosition(client, vecClientEyePos); // Get the position of the player's eyes
    GetClientEyeAngles(client, vecClientEyeAng); // Get the angle the player is looking    

    //Check for colliding entities
    TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);

    if (TR_DidHit(INVALID_HANDLE))
    {
        new TRIndex = TR_GetEntityIndex(INVALID_HANDLE);

        // check max distance
        new Float:pos[3];
        GetEntPropVector(TRIndex, Prop_Send, "m_vecOrigin", pos);
        if (GetVectorDistance(vecClientEyePos, pos)>GetConVarFloat(cvMaxDistance))
            return -1;
        else
            return TRIndex;
    }

    return -1;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
    return (entity != data); // Check if the TraceRay hit the itself.
}

// show a progres bar via hint text
ShowBar(client, Float:curTime, Float:totTime)
{
    new String:gauge[30] = "[=====================]";
    new Float:percent = curTime/totTime;
    if (percent < 1.0)
    {
        new pos = RoundFloat(percent * 20.0) + 1;
        if (pos < 21)
        {
            gauge{pos} = ']';
            gauge{pos+1} = 0;
        }
    }
    PrintHintText(client, gauge);
}

public Native_ControlZGrabber(Handle:plugin,numParams)
{
    gNativeOverride = (numParams >= 1) ? GetNativeCell(1) : true;
}

public Native_HookPickupObject(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        AddToForward(fwdOnPickupObject, plugin, Function:GetNativeCell(1));
        gPickupObjectHooked = true;
    }
}

public Native_HookThrowObject(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        AddToForward(fwdOnThrowObject, plugin, Function:GetNativeCell(1));
        gThrowObjectHooked = true;
    }
}

public Native_HookDropObject(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        AddToForward(fwdOnDropObject, plugin, Function:GetNativeCell(1));
        gDropObjectHooked = true;
    }
}

public Native_HookObjectStop(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        AddToForward(fwdOnObjectStop, plugin, Function:GetNativeCell(1));
        gObjectStopHooked = true;
    }
}

public Native_GiveGravgun(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);

        gMaxDuration[client] = (numParams >= 2) ? (Float:GetNativeCell(2)) : -1.0;
        gThrowSpeed[client] = (numParams >= 3) ? (Float:GetNativeCell(3)) : -1.0;
        gThrowGravity[client] = (numParams >= 4) ? (Float:GetNativeCell(4)) : -1.0;
        gPermissions[client] = (numParams >= 5) ? GetNativeCell(5) : -1;

        if (gMaxDuration[client] < 0.0)
            gMaxDuration[client] = GetConVarFloat(cvMaxDuration); 

        if (gThrowSpeed[client] < 0.0)
            gThrowSpeed[client] = GetConVarFloat(cvThrowSpeed);

        if (gThrowGravity[client] < 0.0)
            gThrowGravity[client] = GetConVarFloat(cvThrowGravity);

        if (gPermissions[client] < 0)
        {
            gPermissions[client] = HAS_GRABBER;

            if (GetConVarInt(cvSteal)==1)
                gPermissions[client] |= CAN_STEAL;

            if (GetConVarInt(cvProps)==1)
                gPermissions[client] |= CAN_GRAB_PROPS;

            if (GetConVarInt(cvBuildings)==1)
                gPermissions[client] |= CAN_GRAB_BUILDINGS;

            if (GetConVarInt(cvOtherBuildings)==1)
                gPermissions[client] |= CAN_GRAB_OTHER_BUILDINGS;

            if (GetConVarInt(cvThrowBuildings)==1)
                gPermissions[client] |= CAN_THROW_BUILDINGS;
        }
    }
}

public Native_TakeGravgun(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        gPermissions[client] = 0;
    }
}

public Native_PickupObject(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        Command_Grab(client, 0);
    }
}

public Native_DropObject(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        Command_UnGrab(client, 0);
    }
}

public Native_StartThrowObject(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        Command_Throw(client, 0);
    }
}

public Native_ThrowObject(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        Command_UnThrow(client, 0);
    }
}
