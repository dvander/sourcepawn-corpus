/**
 * vim: set ai et ts=4 sw=4 :
 * File: ztf2grab.sp
 * Description: dis is z grabber (gravgun) for TF2.
 * Author(s): L. Duke
 * Modified by: -=|JFH|=-Naris (Murray Wilson)
 *              -- Added support for grabbing TF2 buildings
* Modified Again by: Dragonshadow & DaSh, And a ton of help from MikeJS
*              -- Added Engineer Shotgun Right-Click support
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks> 

#define MASK_GRABBERSOLID (MASK_PLAYERSOLID|MASK_NPCSOLID|MASK_SHOT)

//#define _zgrabber_plugin
//#include <zgrabber>
// These define the permissions
#define HAS_GRABBER		            (1 << 0)
#define CAN_STEAL		            (1 << 1)
#define CAN_GRAB_PROPS		        (1 << 2)
#define CAN_GRAB_BUILDINGS		    (1 << 3)
#define CAN_GRAB_OTHER_BUILDINGS    (1 << 4)
#define CAN_THROW_BUILDINGS         (1 << 5)
#define CAN_HOLD_ENABLED_BUILDINGS  (1 << 6)
#define CAN_THROW_ENABLED_BUILDINGS (1 << 7)
#define CAN_JUMP_WHILE_HOLDING      (1 << 8)
#define DISABLE_OPPONENT_BUILDINGS  (1 << 9)
#define CAN_REPAIR_WHILE_HOLDING    (1 << 10)
#define CAN_HOLD_WHILE_SAPPED       (1 << 11)

//Define the enabled bits
#define ENABLE_ALT_SHOTGUN          (1 << 0)
#define ENABLE_ALT_WRENCH           (1 << 1)
#define ENABLE_RELOAD_WRENCH        (1 << 2)

#define PLUGIN_VERSION "3.0.1.0"

#define MAXENTITIES 2048

enum grabType { none, dispenser, teleporter_entry, teleporter_exit, sentrygun, sapper, object, prop };

// globals
new gObj[MAXPLAYERS+1];                 // what object the player is holding
new Handle:gTrackTimers[MAXENTITIES+1]; // entity track timers
new bool:gDisabled[MAXENTITIES+1];      // entity disabled flags
new grabType:gType[MAXPLAYERS+1];       // type of object grabbed
new MoveType:gMove[MAXPLAYERS+1];       // movetype of object grabbed
new Float:gGrabTime[MAXPLAYERS+1];      // when the object was grabbed
new Float:gMaxDuration[MAXPLAYERS+1];   // max time allow to hold onto buildings
new bool:gJustGrabbed[MAXPLAYERS+1];    // object was grabbed when button was pushed
new Float:gGravity[MAXPLAYERS+1];       // gravity of object grabbed
new Float:gThrow[MAXPLAYERS+1];         // throw charge state 
new gHealth[MAXPLAYERS+1];              // health of object grabbed

new gPermissions[MAXPLAYERS+1];         // Permissions for each player
new Float:gThrowSpeed[MAXPLAYERS+1];    // speed of objects thrown by player
new Float:gThrowGravity[MAXPLAYERS+1];  // gravity of objects thrown by player
new Float:gRotation[MAXPLAYERS+1];      // rotation of object held by player
new bool:g_EngiButtonDown[MAXPLAYERS+1];// Engineer is pressing alt-attack with the shotgun
new bool:g_ReloadButtonDown[MAXPLAYERS+1];// Engineer is pressing reload with the shotgun

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
new Handle:cvDropOnJump = INVALID_HANDLE;
new Handle:cvProps = INVALID_HANDLE;
new Handle:cvBuildings = INVALID_HANDLE;
new Handle:cvDispenserEnabled = INVALID_HANDLE;
new Handle:cvOtherBuildings = INVALID_HANDLE;
new Handle:cvThrowBuildings = INVALID_HANDLE;
new Handle:cvThrowGravity = INVALID_HANDLE;
new Handle:cvDropGravity = INVALID_HANDLE;
new Handle:cvThrowSetDisabled = INVALID_HANDLE;
new Handle:cvGrabSetDisabled = INVALID_HANDLE;
new Handle:cvStopSpeed = INVALID_HANDLE;
new Handle:cvDropOnSapped = INVALID_HANDLE;
new Handle:cvAllowRepair = INVALID_HANDLE;
new Handle:cvMovetype = INVALID_HANDLE;
new Handle:cvDebug = INVALID_HANDLE;
new Handle:g_hEnabled = INVALID_HANDLE;
new g_bitsEnabled = true; 

public Plugin:myinfo = {
	name = "Grab:TF2",
    author = "L. Duke,-=|JFH|=-Naris,Dragonshadow",
	description = "Grab engineer buildings and/or props, move them about and throw them (AKA Gravgun)",
    version = PLUGIN_VERSION,
    url = "http://www.lduke.com/"
};

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    // Register Natives
    CreateNative("ControlZtf2grab",Native_ControlZtf2grab);
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
    CreateNative("RotateObject",Native_RotateObject);
    CreateNative("DropEntity",Native_DropEntity);

    // Register Forwards
    fwdOnPickupObject=CreateForward(ET_Hook,Param_Cell,Param_Cell,Param_Cell);
    fwdOnThrowObject=CreateForward(ET_Hook,Param_Cell,Param_Cell);
    fwdOnDropObject=CreateForward(ET_Ignore,Param_Cell,Param_Cell);
    fwdOnObjectStop=CreateForward(ET_Ignore,Param_Cell);

    RegPluginLibrary("ztf2grab");
    return true;
}


public OnPluginStart() 
{
    // events
    HookEvent("player_death", PlayerDeath);
    HookEvent("player_spawn",PlayerSpawn);

    // convars
    CreateConVar("sm_grab_version", PLUGIN_VERSION, "Grab:TF2", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    cvSpeed = CreateConVar("sm_grab_speed", "25.0", "Speed at which held objects move (Default 25) -WARNING- Don't set too high or objects start flying all over the place", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvDistance = CreateConVar("sm_grab_distance", "100.0", "Distance an object is held at (Default 100)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvTeamRestrict = CreateConVar("sm_grab_teams", "0", "restrict usage based on teams (0=all can use, 2 or 3 to restrict red or blu", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvSound = CreateConVar("sm_grab_sound", "weapons/physcannon/hold_loop.wav", "sound to play, change takes effect on map change", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvBuildingSound = CreateConVar("sm_grab_buildingsound", "weapons/physcannon/superphys_hold_loop.wav", "sound to play, change takes effect on map change", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvMissSound = CreateConVar("sm_grab_misssound", "weapons/physcannon/physcannon_dryfire.wav", "sound to play for misses, change takes effect on map change", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvInvalidSound = CreateConVar("sm_grab_invalidsound", "weapons/physcannon/physcannon_tooheavy.wav", "sound to play for errors, change takes effect on map change", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvPickupSound = CreateConVar("sm_grab_pickupsound", "weapons/physcannon/physcannon_pickup.wav", "sound to play for pickup, change takes effect on map change", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvThrowSound = CreateConVar("sm_grab_throwsound", "weapons/physcannon/superphys_launch1.wav", "sound to play for throw, change takes effect on map change", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvDropSound = CreateConVar("sm_grab_dropsound", "weapons/physcannon/physcannon_drop.wav", "sound to play for drop, change takes effect on map change", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvGround = CreateConVar("sm_grab_soccer", "0", "soccer (ground mode) (1/0 = on/off)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvThrowTime = CreateConVar("sm_grab_throwcharge", "2.0", "Time to charge throw to full (default 2.0)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvThrowMinTime = CreateConVar("sm_grab_mincharge", "0.2", "minimum charge time, anything less drops (default 0.2)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvThrowSpeed = CreateConVar("sm_grab_throwspeed", "1000.0", "speed at which an object is thrown. (default 1000)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvMaxDistance = CreateConVar("sm_grab_reach", "512.0", "maximum distance from which you can grab an object (default 512)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvMaxDuration = CreateConVar("sm_grab_fatiguetime", "0.0", "maximum time buildings can be held before being dropped in seconds (default 0.0 is infinite)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvSteal = CreateConVar("sm_grab_thief", "1", "Can buildings be stolen from another player who is holding it? (1/0 = yes/no)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvDropOnJump = CreateConVar("sm_grab_jumpdrop", "1", "drop buildings when jumping to prevent glitch-flying? (1/0 = yes/no)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvProps = CreateConVar("sm_grab_props", "0", "can props be picked up? (1/0 = yes/no)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvBuildings = CreateConVar("sm_grab_buildings", "1", "can engi buildings be picked up? (1/0 = yes/no)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvDispenserEnabled = CreateConVar("sm_grab_dispenser", "1", "Can engie dispeners be grabbed? (0=no 1=yes)");
    cvOtherBuildings = CreateConVar("sm_grab_teamgrab", "1", "can teammates buildings be picked up? (1/0 = yes/no)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvThrowBuildings = CreateConVar("sm_grab_throw", "1", "can buildings be thrown? (1/0 = yes/no)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvThrowSetDisabled = CreateConVar("sm_grab_throwdisable", "1", "set buildings disabled when thrown? (1/0 = yes/no)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvThrowGravity = CreateConVar("sm_grab_throwgrav", "1.0", "gravity of thrown buildings (default 1.0)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvDropGravity = CreateConVar("sm_grab_dropgrav", "10.0", "gravity of dropped buildings (default 10.0)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvGrabSetDisabled = CreateConVar("sm_grab_grabdisable", "1", "set buildings disabled when grabbed? (1/0 = yes/no)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvStopSpeed = CreateConVar("sm_grab_stopspeed", "10.0", "speed buildings are considered stopped", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvDropOnSapped = CreateConVar("sm_grab_sapped", "1", "drop objects if they are sapped? (1/0 = yes/no)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvAllowRepair = CreateConVar("sm_grab_norepair", "1", "Allow objects to be repaired while held? (0 allows, 1 disallows)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    cvDebug = CreateConVar("sm_grab_debug", "0", "display object classtype on grab attempt");
    cvMovetype = CreateConVar("sm_grab_movetype", "1", "change the movetype of grabbed/thrown objects (1/0 = yes/no)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
    g_hEnabled = CreateConVar("sm_grab_altenable", "7", "Enable/Disable Engi Alt-Fire/Reload Support (1=shotgun,2=wrench,4=wrench-reload)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

    // convarchange
    HookConVarChange(g_hEnabled, Cvar_enabled); 

    // commands
    RegConsoleCmd("+grav", Command_Grab);
    RegConsoleCmd("-grav", Command_UnGrab2);
    RegConsoleCmd("+throw", Command_Throw);
    RegConsoleCmd("-throw", Command_UnThrow);
    RegConsoleCmd("rotate", Command_Rotate);
}

public OnConfigsExecuted() {
    g_bitsEnabled = GetConVarInt(g_hEnabled);
} 

public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
    g_bitsEnabled = GetConVarInt(g_hEnabled);
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
    if (client && !IsFakeClient(client))
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

public OnGameFrame()
{
    // running GetConVarBool every frame is not good...
    if (g_bitsEnabled) 
    {
        new buttons;
        decl String:wpn[32];
        for (new i=1;i<=MaxClients;i++) 
        {
            if (IsClientConnected(i) && IsClientInGame(i) &&
                IsPlayerAlive(i) && TF2_GetPlayerClass(i)==TFClass_Engineer) 
            {
                GetClientWeapon(i, wpn, sizeof(wpn));
                if((g_bitsEnabled & ENABLE_ALT_SHOTGUN) &&
                   StrEqual(wpn, "tf_weapon_shotgun_primary")) 
                {
                    buttons = GetEntProp(i, Prop_Data, "m_nButtons", buttons);
                    if(buttons & IN_ATTACK2) 
                    {
                        if(!g_EngiButtonDown[i]) 
                        {
                            Command_Grab(i, 0);
                            g_EngiButtonDown[i] = true;
                        }
                    } 
                    else 
                    {
                        g_EngiButtonDown[i] = false;
                    }
                }
                else if((g_bitsEnabled & (ENABLE_ALT_WRENCH | ENABLE_RELOAD_WRENCH)) &&
                        StrEqual(wpn, "tf_weapon_wrench")) 
                {
                    buttons = GetEntProp(i, Prop_Data, "m_nButtons", buttons);
                    if (g_bitsEnabled & ENABLE_ALT_WRENCH)
                    {
                        if (buttons & IN_ATTACK2)
                        {
                            if(!g_EngiButtonDown[i]) 
                            {
                                Command_Grab(i, 0);
                                g_EngiButtonDown[i] = true;
                            }
                        } 
                        else 
                        {
                            g_EngiButtonDown[i] = false;
                        }
                    }

                    if (g_bitsEnabled & ENABLE_RELOAD_WRENCH)
                    {
                        if (buttons & IN_RELOAD)
                        {
                            if(!g_ReloadButtonDown[i]) 
                            {
                                g_ReloadButtonDown[i] = true;
                                gRotation[i] += 90.0;
                                if (gRotation[i] > 180.0)
                                    gRotation[i] = -90.0;
                            }
                        } 
                        else 
                        {
                            g_ReloadButtonDown[i] = false;
                        }
                    }
                }
            }
        }
    }
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

            if (GetConVarBool(cvSteal))
                gPermissions[client] |= CAN_STEAL;

            if (GetConVarBool(cvProps))
                gPermissions[client] |= CAN_GRAB_PROPS;

            if (GetConVarBool(cvBuildings))
                gPermissions[client] |= CAN_GRAB_BUILDINGS;

            if (GetConVarBool(cvOtherBuildings))
                gPermissions[client] |= CAN_GRAB_OTHER_BUILDINGS;

            if (GetConVarBool(cvThrowBuildings))
                gPermissions[client] |= CAN_THROW_BUILDINGS;

            if (!GetConVarBool(cvGrabSetDisabled))
                gPermissions[client] |= CAN_HOLD_ENABLED_BUILDINGS;

            if (!GetConVarBool(cvThrowSetDisabled))
                gPermissions[client] |= CAN_THROW_ENABLED_BUILDINGS;

            if (!GetConVarBool(cvDropOnJump))
                gPermissions[client] |= CAN_JUMP_WHILE_HOLDING;

            if (!GetConVarBool(cvDropOnSapped))
                gPermissions[client] |= CAN_HOLD_WHILE_SAPPED;

            if (!GetConVarBool(cvAllowRepair))
                gPermissions[client] |= CAN_REPAIR_WHILE_HOLDING;
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

public Action:Command_Rotate(client, args)
{
	// check if EngiButtonDown is true
    if (g_ReloadButtonDown[client] == true)
        return Plugin_Handled;

    // if an object is being held
    else if (gObj[client]>0)
    {
        gRotation[client] += 90.0;
        if (gRotation[client] > 180.0)
            gRotation[client] = -90.0;
    }

    return Plugin_Handled;
}

public Action:Command_Grab(client, args)
{
	// check if EngiButtonDown is true
    if (g_EngiButtonDown[client] == true)
        return Plugin_Handled;

    // if an object is being held, go to UnGrab
    else if (gObj[client]>0)
        return Command_UnGrab(client, args);

    // make sure client is not spectating
    else if (!client || !IsPlayerAlive(client))
        return Plugin_Handled;

    // check if client has a grabber
    else if (!(gPermissions[client] & HAS_GRABBER))
        return Plugin_Handled;

    new bool:groundmode = GetConVarBool(cvGround);

    // find entity
    new ent = TraceToEntity(client);
    if (ent == -1)
    {
        if (!groundmode)
            EmitSoundToAll(gMissSound, client);

        return Plugin_Handled;
    }

    new builder=0;
    new grabType:grab = GetGrabType(ent);

    if (ent > 0 && GetConVarBool(cvDebug))
    {
        new String:edictname[128];
        GetEdictClassname(ent, edictname, 128);
        LogMessage("%N target is %d:%s", client, grab, edictname);
        PrintToChat(client, ">%d:%s", grab, edictname);
    }

    // Check for known TF2 objects
    if (grab >= dispenser && grab <= sentrygun)
    {
        builder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");

        new permissions = gPermissions[client];
        if (!(permissions & CAN_GRAB_BUILDINGS) ||
            ((grab == dispenser) &&
             !GetConVarBool(cvDispenserEnabled)))
        {
            if (!groundmode)
                EmitSoundToAll(gInvalidSound, client);

            return Plugin_Handled;
        }
        else
        {
            new Float:complete = GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed");
            if (complete < 1.0)
            {
                if (!groundmode)
                    EmitSoundToAll(gInvalidSound, client);

                return Plugin_Handled;
            }
            else if (!(permissions & CAN_GRAB_OTHER_BUILDINGS) &&
                     builder != client)
            {
                if (!groundmode)
                    EmitSoundToAll(gInvalidSound, client);

                return Plugin_Handled;
            }
            else if (!(permissions & CAN_HOLD_WHILE_SAPPED) &&
                     GetEntProp(ent, Prop_Send, "m_bHasSapper") &&
                     GetEntProp(ent, Prop_Send, "m_iTeamNum") == GetClientTeam(client))
            {
                if (!groundmode)
                    EmitSoundToAll(gInvalidSound, client);

                return Plugin_Handled;
            }
        }
    }
    else
    {
        if (grab != prop || !(gPermissions[client] & CAN_GRAB_PROPS))
        {
            if (!groundmode)
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
                    if (!groundmode)
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
            new bool:moveFlag=GetConVarBool(cvMovetype);

            // grab entity
            gObj[client] = ent;
            gType[client] = grab;
            gThrow[client] = 0.0;
            gRotation[client] = 0.0;
            gGrabTime[client] = GetEngineTime();
            gGravity[client] = (gThrowGravity[client] != 1.0) ? GetEntityGravity(ent) : 1.0;
            gMove[client] = (moveFlag) ? GetEntityMoveType(ent) : MOVETYPE_NONE;
            gJustGrabbed[client] = true;

            if (grab >= dispenser && grab <= sentrygun)
            {
                gHealth[client] = GetEntProp(ent, Prop_Send, "m_iHealth");

                if (gTrackTimers[ent] != INVALID_HANDLE)
                {
                    KillTimer(gTrackTimers[ent]);
                    gTrackTimers[ent] = INVALID_HANDLE;
                }
                else
                    gDisabled[ent] = false;

                if (GetEntProp(ent, Prop_Send, "m_iTeamNum") != GetClientTeam(client))
                {
                    if ((gPermissions[client] & DISABLE_OPPONENT_BUILDINGS))
                    {
                        if (!GetEntProp(ent, Prop_Send, "m_bDisabled"))
                        {
                            SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
                            gDisabled[ent] = true;
                        }
                    }
                }
                else
                {
                    if (!(gPermissions[client] & CAN_HOLD_ENABLED_BUILDINGS))
                    {
                        if (!GetEntProp(ent, Prop_Send, "m_bDisabled"))
                        {
                            SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
                            gDisabled[ent] = true;
                        }
                    }
                }

            }

            if (!groundmode)
            {
                // "pop" the object up a little to prevent stickage.
                new Float:vecPos[3];
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPos);
                vecPos[2] += 30.0;

                // and "rotate it to match where the client is facing.
                new Float:vecAngles[3];
                GetClientAbsAngles(client, vecAngles);
                vecAngles[1] += gRotation[client];
                if (vecAngles[1] < -180.0)
                    vecAngles[1] += 360.0;
                else if (vecAngles[1] > 180.0)
                    vecAngles[1] -= 360.0;

                TeleportEntity(ent, vecPos, vecAngles, NULL_VECTOR);

                if (moveFlag)
                    SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);

                EmitSoundToAll(gPickupSound, client);
                if (grab >= dispenser && grab <= sentrygun)
                    EmitSoundToAll(gBuildingSound, client);
                else
                    EmitSoundToAll(gSound, client);
            }
        }
        else
        {
            if (!groundmode)
                EmitSoundToAll(gInvalidSound, client);
        }
    }
    else
    {
        if (!groundmode)
            EmitSoundToAll(gMissSound, client);
    }

    return Plugin_Handled;
}

public Action:Command_UnGrab(client, args)
{
    if (gThrow[client]>0.0)
        PrintHintText(client, " ");

    new ent = gObj[client];
    if (ent < 1)
        return Plugin_Handled;

    if (IsValidEdict(ent) && IsValidEntity(ent))
        Drop(client, false);

    return Plugin_Handled;
}

Drop(client, bool:throw)
{
    new bool:groundmode = GetConVarBool(cvGround);
    if (!groundmode) // no sound in ground mode
    {
        StopSound(client, SNDCHAN_AUTO, gSound);
        StopSound(client, SNDCHAN_AUTO, gBuildingSound);
    }

    new ent = gObj[client];
    new grabType:gt = gType[client];
    if (GetGrabType(ent) == gt)
    {
        if (!throw)
        {
            if (!groundmode)
                EmitSoundToAll(gDropSound, client);

            new Float:dropGravity = GetConVarFloat(cvDropGravity);
            if (dropGravity != gGravity[client])
                SetEntityGravity(ent, dropGravity);

            if (GetConVarBool(cvMovetype))
                SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);

            new Float:speed[3] = { 0.0, 0.0, -1.0 };
            TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, speed);
        }

        if (gt >= dispenser && gt <= sentrygun)
        {
            new bool:disable = gDisabled[ent];
            if (throw && !disable && (gt >= dispenser && gt <= sentrygun) &&
                !(gPermissions[client] & CAN_THROW_ENABLED_BUILDINGS))
            {
                disable = !GetEntProp(ent, Prop_Send, "m_bDisabled");
                if (disable)
                    SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
            }
        }

        new Handle:pack;
        gTrackTimers[ent] = CreateDataTimer(0.2,TrackObject,pack,TIMER_REPEAT);
        if (gTrackTimers[ent] != INVALID_HANDLE)
        {
            new Float:vecPos[3];
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPos);
            WritePackCell(pack, ent);
            WritePackCell(pack, _:gt);
            WritePackCell(pack, _:gMove[client]);
            WritePackFloat(pack, gGravity[client]);
            WritePackFloat(pack, vecPos[0]);
            WritePackFloat(pack, vecPos[1]);
            WritePackFloat(pack, vecPos[2]);
            WritePackFloat(pack, gThrowSpeed[client]);
            WritePackCell(pack, 0);
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
    gType[client] = none;
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
    if (!client || !IsPlayerAlive(client))
        return Plugin_Handled;
    // has an object?
    else if (gObj[client]<1)
        return Command_Grab(client, args);

    // is it a object that can't be thrown? 
    else if (gType[client] >= object && !(gPermissions[client] & CAN_THROW_BUILDINGS))
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

    // has an object?
    new ent = gObj[client];
    if (ent < 1)
        return Plugin_Handled;

    if (IsValidEdict(ent) && IsValidEntity(ent))
    {
        // is it the same object and can it be thrown? 
        new grabType:grab = gType[client];
        if (grab != GetGrabType(ent) ||
            ((grab >= dispenser && grab <= sentrygun) &&
             !(gPermissions[client] & CAN_THROW_BUILDINGS)))
        {
            return Command_UnGrab(client, args);
        }

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
            speed[0]*=throwspeed;
            speed[1]*=throwspeed;
            speed[2]*=throwspeed;

            if (throwgravity != gGravity[client])
                SetEntityGravity(ent, throwgravity);

            if (GetConVarBool(cvMovetype))
                SetEntityMoveType(ent, (throwgravity <= 0.0) ? MOVETYPE_FLY : MOVETYPE_FLYGRAVITY);

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

    // check if the object is still the same type we picked up
    new grabType:gt = grabType:ReadPackCell(pack);
    if (GetGrabType(ent) == gt)
    {
        new MoveType:mt = MoveType:ReadPackCell(pack);
        new Float:gravity = ReadPackFloat(pack);

        decl Float:lastPos[3];
        lastPos[0] = ReadPackFloat(pack);
        lastPos[1] = ReadPackFloat(pack);
        lastPos[2] = ReadPackFloat(pack);

        new Float:lastSpeed = ReadPackFloat(pack);
        new stopCount = ReadPackCell(pack);

        decl Float:vecPos[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPos);

        decl Float:vecVel[3];
        SubtractVectors(lastPos, vecPos, vecVel);

        new Float:vecGround[3];
        vecGround[0] = vecPos[0];
        vecGround[1] = vecPos[1];
        vecGround[2] = vecPos[2];

        new Float:stopSpeed = GetConVarFloat(cvStopSpeed);
        new Float:negStopSpeed = stopSpeed * -1;
        new bool:bStop = ((vecVel[0] >= negStopSpeed && vecVel[0] <= stopSpeed) &&
                          (vecVel[1] >= negStopSpeed && vecVel[1] <= stopSpeed) &&
                          (vecVel[2] >= negStopSpeed && vecVel[2] <= stopSpeed) );

        //Check below the object for the ground
        new Float:height;
        decl Float:vecBelow[3];
        decl Float:vecCheckBelow[3];
        vecCheckBelow[0] = vecPos[0];
        vecCheckBelow[1] = vecPos[1];
        vecCheckBelow[2] = vecPos[2] - 1000.0;

        TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                          RayType_EndPoint, TraceRayDontHitSelf, ent);
        if (TR_DidHit(INVALID_HANDLE))
        {
            TR_GetEndPosition(vecBelow, INVALID_HANDLE);
            vecGround[2] = vecBelow[2];
            height = (vecPos[2] - vecBelow[2]);
            if (bStop)
            {
                // Don't Stop if it's more than 10 units off ground.
                bStop = (height < 10.0);
            }
            else
            {
                // Stop if it's within 5 units of the ground.
                bStop = (height <= 5.0);
            }

        }
        else
            bStop = false;

        if (!bStop && lastSpeed == 0.0)
        {
            if (vecVel[0] == 0.0 && vecVel[1] == 0.0 && vecVel[2] == 0.0)
            {
                stopCount++;
                if (stopCount > 6)
                    bStop = true; // it's stuck real good :(
                else if (stopCount >= 3)
                {
                    if (gt >= dispenser && gt <= sentrygun)
                    {
                        if (gDisabled[ent] && !GetEntProp(ent, Prop_Send, "m_bHasSapper"))
                        {
                            SetEntProp(ent, Prop_Send, "m_bDisabled", 0);
                            gDisabled[ent] = false;
                        }
                    }

                    if (height > 10.0)
                    {
                        // it's stuck, try to knock it loose.
                        stopSpeed *= 3.0;
                        negStopSpeed *= 3.0;
                        decl Float:vecKnock[3];
                        vecKnock[0]= GetRandomFloat(negStopSpeed, stopSpeed);
                        vecKnock[1]= GetRandomFloat(negStopSpeed, stopSpeed);
                        vecKnock[2]= GetRandomFloat(negStopSpeed, stopSpeed);
                        TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, vecKnock);
                    }
                    else
                        bStop = true;
                }
            }
            else
                stopCount = 0;
        }

        if (bStop || height <= 0.0)
        {
            new Float:vecAngles[3];
            GetEntPropVector(ent, Prop_Send, "m_angRotation", vecAngles);
            if (vecAngles[0] != 0.0 || vecAngles[2] != 0.0)
            {
                vecAngles[0] = 0.0;
                vecAngles[2] = 0.0;
                TeleportEntity(ent, NULL_VECTOR, vecAngles, NULL_VECTOR);
            }
        }

        if (bStop)
        {
            if (GetConVarBool(cvMovetype))
                SetEntityMoveType(ent, mt);

            if (gravity != GetConVarFloat(cvDropGravity))
                SetEntityGravity(ent, gravity);

            if (gt >= dispenser && gt <= sentrygun)
            {
                if (gDisabled[ent] && !GetEntProp(ent, Prop_Send, "m_bHasSapper"))
                    SetEntProp(ent, Prop_Send, "m_bDisabled", 0);
            }

            //Check the right side
            vecPos[0] += 30.0;
            vecCheckBelow[0] += 30.0;
            TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                              RayType_EndPoint, TraceRayDontHitSelf, ent);
            if (TR_DidHit(INVALID_HANDLE))
            {
                TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                if (vecGround[2] < vecBelow[2])
                    vecGround[2] = vecBelow[2];
            }

            //Check the top right corner
            vecPos[1] += 30.0;
            vecCheckBelow[1] += 30.0;
            if (TR_DidHit(INVALID_HANDLE))
            {
                TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                if (vecGround[2] < vecBelow[2])
                    vecGround[2] = vecBelow[2];
            }

            //Check the top middle
            vecPos[0] -= 30.0;
            vecCheckBelow[0] -= 30.0;
            if (TR_DidHit(INVALID_HANDLE))
            {
                TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                if (vecGround[2] < vecBelow[2])
                    vecGround[2] = vecBelow[2];
            }

            //Check the top left corner
            vecPos[0] -= 30.0;
            vecCheckBelow[0] -= 30.0;
            TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                              RayType_EndPoint, TraceRayDontHitSelf, ent);
            if (TR_DidHit(INVALID_HANDLE))
            {
                TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                if (vecGround[2] < vecBelow[2])
                    vecGround[2] = vecBelow[2];
            }

            //Check the left side
            vecPos[1] -= 30.0;
            vecCheckBelow[1] -= 30.0;
            TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                              RayType_EndPoint, TraceRayDontHitSelf, ent);
            if (TR_DidHit(INVALID_HANDLE))
            {
                TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                if (vecGround[2] < vecBelow[2])
                    vecGround[2] = vecBelow[2];
            }

            //Check the bottom left corner
            vecPos[1] -= 30.0;
            vecCheckBelow[1] -= 30.0;
            TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                              RayType_EndPoint, TraceRayDontHitSelf, ent);
            if (TR_DidHit(INVALID_HANDLE))
            {
                TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                if (vecGround[2] < vecBelow[2])
                    vecGround[2] = vecBelow[2];
            }

            //Check the bottom middle
            vecPos[0] += 30.0;
            vecCheckBelow[0] += 30.0;
            TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                              RayType_EndPoint, TraceRayDontHitSelf, ent);
            if (TR_DidHit(INVALID_HANDLE))
            {
                TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                if (vecGround[2] < vecBelow[2])
                    vecGround[2] = vecBelow[2];
            }

            //Check the bottom right corner
            vecPos[0] += 30.0;
            vecCheckBelow[0] += 30.0;
            TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                              RayType_EndPoint, TraceRayDontHitSelf, ent);
            if (TR_DidHit(INVALID_HANDLE))
            {
                TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                if (vecGround[2] < vecBelow[2])
                    vecGround[2] = vecBelow[2];
            }

            new Float:delta = vecPos[2] - vecGround[2];
            if (delta > 5.0)
            {
                // Move building down to ground (or whatever it hit).
                TeleportEntity(ent, vecGround, NULL_VECTOR, NULL_VECTOR);
            }

            if (gObjectStopHooked)
            {
                new Action:res = Plugin_Continue;
                Call_StartForward(fwdOnObjectStop);
                Call_PushCell(ent);
                Call_Finish(res);
            }
        }
        else
        {
            ResetPack(pack, true);
            WritePackCell(pack, ent);
            WritePackCell(pack, _:gt);
            WritePackCell(pack, _:mt);
            WritePackFloat(pack, gravity);
            WritePackFloat(pack, vecPos[0]);
            WritePackFloat(pack, vecPos[1]);
            WritePackFloat(pack, vecPos[2]);
            WritePackFloat(pack, vecVel[0] + vecVel[1] + vecVel[2]);
            WritePackCell(pack, stopCount);
            return Plugin_Continue;
        }
    }

    gDisabled[ent] = false;
    gTrackTimers[ent] = INVALID_HANDLE;
    return Plugin_Stop;
}

public Action:UpdateObjects(Handle:timer)
{
    new ent;
    new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];      // vectors
    new Float:viewang[3];                                       // angles
    new Float:speed = GetConVarFloat(cvSpeed);
    new Float:distance = GetConVarFloat(cvDistance);
    new bool:groundmode = GetConVarBool(cvGround);
    new Float:throwtime = GetConVarFloat(cvThrowTime);
    new Float:throwmintime = GetConVarFloat(cvThrowMinTime);
    new Float:time = GetEngineTime();
    new maxplayers = GetMaxClients();
    for (new i=0; i<=maxplayers; i++)
    {
        ent = gObj[i];
        if (ent > 0)
        {
            new grabType:gt = gType[i];
            if (GetGrabType(ent) == gt)
            {
                if (IsValidEdict(ent) && IsValidEntity(ent))
                {
                    new permissions = gPermissions[i];
                    if (!(permissions & CAN_JUMP_WHILE_HOLDING) &&
                        (GetClientButtons(i) & IN_JUMP))
                    {
                        Drop(i, false);
                        continue;
                    }

                    if (gt >= dispenser && gt <= sentrygun)
                    {
                        if (!(permissions & CAN_HOLD_WHILE_SAPPED) &&
                            GetEntProp(ent, Prop_Send, "m_bHasSapper") &&
                            GetEntProp(ent, Prop_Send, "m_iTeamNum") == GetClientTeam(i))
                        {
                            Drop(i, false);
                            continue;
                        }

                        new health = gHealth[i];
                        if (!(permissions & CAN_REPAIR_WHILE_HOLDING) &&
                            GetEntProp(ent, Prop_Send, "m_iHealth") > health)
                        {
                            SetEntProp(ent, Prop_Send, "m_iHealth", health);
                        }
                    }

                    // get client info
                    GetClientEyeAngles(i, viewang);
                    GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
                    if (groundmode)
                        GetClientAbsOrigin(i, vecPos);
                    else
                        GetClientEyePosition(i, vecPos);

                    // update object 
                    vecPos[0]+=vecDir[0]*distance;
                    vecPos[1]+=vecDir[1]*distance;
                    if (!groundmode)
                        vecPos[2]+=vecDir[2]*distance;    // don't change up/down in ground mode

                    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecDir);

                    SubtractVectors(vecPos, vecDir, vecVel);

                    ScaleVector(vecVel, speed);
                    if (groundmode)
                        vecVel[2]=0.0;

                    viewang[1] += gRotation[i];
                    if (viewang[1] < -180.0)
                        viewang[1] += 360.0;
                    else if (viewang[1] > 180.0)
                        viewang[1] -= 360.0;

                    // push object and "rotate it to match where the client is facing.
                    TeleportEntity(ent, NULL_VECTOR, viewang, vecVel);

                    // update throw time
                    if (gThrow[i] > 0.0)
                    {
                        new Float:thetime = time - gThrow[i];
                        if (thetime > throwmintime)
                            ShowBar(i, thetime, throwtime);
                    }
                    else if  (gMaxDuration[i] > 0.0 &&
                              (gType[i] >= dispenser && gType[i] <= sentrygun))
                    {
                        new Float:thetime = time - gGrabTime[i];
                        if (thetime > gMaxDuration[i])
                            Command_UnGrab(i, 0);
                    }
                }
                else
                {
                    gObj[i] = -1;
                    Drop(i, false);
                }
            }
        }
    }
    return Plugin_Continue;
}

TraceToEntity(client)
{
    new Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
    GetClientEyePosition(client, vecClientEyePos); // Get the position of the player's eyes
    GetClientEyeAngles(client, vecClientEyeAng); // Get the angle the player is looking    

    //Check for colliding entities
    TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_GRABBERSOLID,
                      RayType_Infinite, TraceRayDontHitSelf, client);

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

grabType:GetGrabType(ent)
{
    if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
    {
        new String:edictname[128];
        GetEdictClassname(ent, edictname, 128);

        if (strcmp("obj_dispenser", edictname, false)==0)
            return dispenser; // ent is a dispenser
        else if (strcmp("obj_sentrygun", edictname, false)==0)
            return sentrygun; // ent is a dispenser
        else if (strcmp("obj_teleporter_entrance", edictname, false)==0)
            return teleporter_entry; // ent is a teleporter_entry
        else if (strcmp("obj_teleporter_exit", edictname, false)==0)
            return teleporter_exit; // ent is a teleporter_exit
        else if (strcmp("obj_sapper", edictname, false)==0)
            return sapper; // ent is a teleporter_exit
        else if (strncmp("obj_", edictname, 4, false)==0)
            return object; // ent is an object
        else if (strncmp("prop_", edictname, 5, false)==0)
            return prop; // ent is a physics entities
    }
    return none;
}

public Native_ControlZtf2grab(Handle:plugin,numParams)
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

            if (GetConVarBool(cvSteal))
                gPermissions[client] |= CAN_STEAL;

            if (GetConVarBool(cvProps))
                gPermissions[client] |= CAN_GRAB_PROPS;

            if (GetConVarBool(cvBuildings))
                gPermissions[client] |= CAN_GRAB_BUILDINGS;

            if (GetConVarBool(cvOtherBuildings))
                gPermissions[client] |= CAN_GRAB_OTHER_BUILDINGS;

            if (GetConVarBool(cvThrowBuildings))
                gPermissions[client] |= CAN_THROW_BUILDINGS;

            if (!GetConVarBool(cvGrabSetDisabled))
                gPermissions[client] |= CAN_HOLD_ENABLED_BUILDINGS;

            if (!GetConVarBool(cvThrowSetDisabled))
                gPermissions[client] |= CAN_THROW_ENABLED_BUILDINGS;

            if (!GetConVarBool(cvDropOnJump))
                gPermissions[client] |= CAN_JUMP_WHILE_HOLDING;
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

public Native_RotateObject(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        Command_Rotate(client, 0);
    }
}

public Native_DropEntity(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new ent = GetNativeCell(1);
        if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
        {
            new Float:speed[3] = { 0.0, 0.0, -1.0 };
            new Float:gravity = (numParams >= 3) ? (Float:GetNativeCell(3)) : GetConVarFloat(cvDropGravity);
            new Float:oldGravity = GetEntityGravity(ent);
            new grabType:gt = GetGrabType(ent);
            new MoveType:mt = GetEntityMoveType(ent);

            if (numParams >= 2)
                speed[2] = Float:GetNativeCell(2);

            if (gravity != oldGravity)
                SetEntityGravity(ent, gravity);

            if (GetConVarBool(cvMovetype))
                SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);

            TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, speed);

            new Handle:pack;
            gTrackTimers[ent] = CreateDataTimer(0.2,TrackObject,pack,TIMER_REPEAT);
            if (gTrackTimers[ent] != INVALID_HANDLE)
            {
                new Float:vecPos[3];
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPos);
                WritePackCell(pack, ent);
                WritePackCell(pack, _:gt);
                WritePackCell(pack, _:mt);
                WritePackFloat(pack, oldGravity);
                WritePackFloat(pack, vecPos[0]);
                WritePackFloat(pack, vecPos[1]);
                WritePackFloat(pack, vecPos[2]);
                WritePackFloat(pack, speed[0] + speed[1] + speed[2]);
                WritePackCell(pack, 0);
            }
        }
    }
}

