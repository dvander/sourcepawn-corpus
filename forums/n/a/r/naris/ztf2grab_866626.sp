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

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

//Define the enabled bits
#define ENABLE_ALT_SHOTGUN      (1 << 0)
#define ENABLE_RELOAD_WRENCH    (1 << 1)

#define MASK_GRABBERSOLID       (MASK_PLAYERSOLID|MASK_NPCSOLID|MASK_SHOT)

#define PLUGIN_VERSION          "6.0"

#define MAXENTITIES             2048

enum grabType { dispenser, teleporter, sentrygun, teleporter_entry, teleporter_exit, sapper, object, prop, unknown, none };

// globals
new gObj[MAXPLAYERS+1];                 // what object the player is holding
new Handle:gTrackTimers[MAXENTITIES+1]; // entity track timers
new bool:gDisabled[MAXENTITIES+1];      // entity disabled flags
new grabType:gType[MAXPLAYERS+1];       // type of grabbed object
new MoveType:gMove[MAXPLAYERS+1];       // movetype of grabbed object
new Float:gGrabTime[MAXPLAYERS+1];      // when the object was grabbed
new Float:gMaxDuration[MAXPLAYERS+1];   // max time allow to hold onto buildings
new bool:gJustGrabbed[MAXPLAYERS+1];    // object was grabbed when button was pushed
new Float:gGravity[MAXPLAYERS+1];       // gravity of grabbed object
new Float:gThrow[MAXPLAYERS+1];         // throw charge state 
new gHealth[MAXPLAYERS+1];              // health of grabbed object

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

// forwards
new Handle:fwdOnPickupObject = INVALID_HANDLE;
new Handle:fwdOnCarryObject = INVALID_HANDLE;
new Handle:fwdOnThrowObject = INVALID_HANDLE;
new Handle:fwdOnDropObject = INVALID_HANDLE;
new Handle:fwdOnObjectStop = INVALID_HANDLE;

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
new Handle:cvThrowGravity = INVALID_HANDLE;
new Handle:cvDropGravity = INVALID_HANDLE;
new Handle:cvStopSpeed = INVALID_HANDLE;
new Handle:cvMovetype = INVALID_HANDLE;
new Handle:cvDebug = INVALID_HANDLE;

new Handle:cvProps = INVALID_HANDLE;
new Handle:cvBuildings = INVALID_HANDLE;
new Handle:cvDispenserEnabled = INVALID_HANDLE;
new Handle:cvOtherBuildings = INVALID_HANDLE;
new Handle:cvThrowBuildings = INVALID_HANDLE;
new Handle:cvThrowSetDisabled = INVALID_HANDLE;
new Handle:cvGrabSetDisabled = INVALID_HANDLE;
new Handle:cvDropOnSapped = INVALID_HANDLE;
new Handle:cvAllowRepair = INVALID_HANDLE;
new Handle:cvEnableBits = INVALID_HANDLE;

new g_EnableBits = 0; 

public Plugin:myinfo = {
	name = "Grab:TF2",
    author = "L. Duke,-=|JFH|=-Naris,Dragonshadow",
	description = "Grab engineer buildings and/or props, move them about and throw them (AKA Gravgun)",
    version = PLUGIN_VERSION,
    url = "http://www.lduke.com/"
};

/**
 * Description: Define the grabber permissions
 */
#define _zgrabber_plugin
#tryinclude "ztf2grab"
#if !defined _ztf2grab_included
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
#endif

/**
 * Description: Function to determine game/mod type
 */
#tryinclude <gametype>
#if !defined _gametype_included
    enum Game { undetected, tf2, cstrike, dod, hl2mp, insurgency, zps, l4d, l4d2, other_game };
    stock Game:GameType = undetected;

    stock Game:GetGameType()
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
            else if (StrEqual(modname,"left4dead", false)) 
                GameType=l4d;
            else if (StrEqual(modname,"left4dead2", false)) 
                GameType=l4d2;
            else if (StrEqual(modname,"zps",false)) 
                GameType=zps;
            else
                GameType=other_game;
        }
        return GameType;
    }
#endif

/**
 * Description: Functions to return information about TF2 player condition.
 */
#tryinclude <tf2_player>
#if !defined _tf2_player_included
    #define TF2_IsPlayerDisguised(%1)    TF2_IsPlayerInCondition(%1,TFCond_Disguised)
    #define TF2_IsPlayerCloaked(%1)      TF2_IsPlayerInCondition(%1,TFCond_Cloaked)
    #define TF2_IsPlayerUbercharged(%1)  TF2_IsPlayerInCondition(%1,TFCond_Ubercharged)
    #define TF2_IsPlayerDeadRingered(%1) TF2_IsPlayerInCondition(%1,TFCond_DeadRingered)
    #define TF2_IsPlayerBonked(%1)       TF2_IsPlayerInCondition(%1,TFCond_Bonked)
#endif

/**
 * Description: Manage precaching resources.
 */
#tryinclude "ResourceManager"
#if !defined _ResourceManager_included
    #define AUTO_DOWNLOAD   -1
	#define DONT_DOWNLOAD    0
	#define DOWNLOAD         1
	#define ALWAYS_DOWNLOAD  2

	enum State { Unknown=0, Defined, Download, Force, Precached };

	// Trie to hold precache status of sounds
	new Handle:g_soundTrie = INVALID_HANDLE;

	stock bool:PrepareSound(const String:sound[], bool:force=false, bool:preload=false)
	{
        #pragma unused force
        new State:value = Unknown;
        if (!GetTrieValue(g_soundTrie, sound, value) || value < Precached)
        {
            PrecacheSound(sound, preload);
            SetTrieValue(g_soundTrie, sound, Precached);
        }
        return true;
    }

	stock SetupSound(const String:sound[], bool:force=false, download=AUTO_DOWNLOAD,
	                 bool:precache=false, bool:preload=false)
	{
        new State:value = Unknown;
        new bool:update = !GetTrieValue(g_soundTrie, sound, value);
        if (update || value < Defined)
        {
            value  = Defined;
            update = true;
        }

        if (download && value < Download)
        {
            decl String:file[PLATFORM_MAX_PATH+1];
            Format(file, sizeof(file), "sound/%s", sound);

            if (FileExists(file))
            {
                if (download < 0)
                {
                    if (!strncmp(file, "ambient", 7) ||
                        !strncmp(file, "beams", 5) ||
                        !strncmp(file, "buttons", 7) ||
                        !strncmp(file, "coach", 5) ||
                        !strncmp(file, "combined", 8) ||
                        !strncmp(file, "commentary", 10) ||
                        !strncmp(file, "common", 6) ||
                        !strncmp(file, "doors", 5) ||
                        !strncmp(file, "friends", 7) ||
                        !strncmp(file, "hl1", 3) ||
                        !strncmp(file, "items", 5) ||
                        !strncmp(file, "midi", 4) ||
                        !strncmp(file, "misc", 4) ||
                        !strncmp(file, "music", 5) ||
                        !strncmp(file, "npc", 3) ||
                        !strncmp(file, "physics", 7) ||
                        !strncmp(file, "pl_hoodoo", 9) ||
                        !strncmp(file, "plats", 5) ||
                        !strncmp(file, "player", 6) ||
                        !strncmp(file, "resource", 8) ||
                        !strncmp(file, "replay", 6) ||
                        !strncmp(file, "test", 4) ||
                        !strncmp(file, "ui", 2) ||
                        !strncmp(file, "vehicles", 8) ||
                        !strncmp(file, "vo", 2) ||
                        !strncmp(file, "weapons", 7))
                    {
                        // If the sound starts with one of those directories
                        // assume it came with the game and doesn't need to
                        // be downloaded.
                        download = 0;
                    }
                    else
                        download = 1;
                }

                if (download > 0)
                {
                    AddFileToDownloadsTable(file);

                    update = true;
                    value  = Download;
                }
            }
        }

        if (precache && value < Precached)
        {
            PrecacheSound(sound, preload);
            value  = Precached;
            update = true;
        }
        else if (force && value < Force)
        {
            value  = Force;
            update = true;
        }

        if (update)
            SetTrieValue(g_soundTrie, sound, value);
    }

    stock PrepareAndEmitSoundToAll(const String:sample[],
                     entity = SOUND_FROM_PLAYER,
                     channel = SNDCHAN_AUTO,
                     level = SNDLEVEL_NORMAL,
                     flags = SND_NOFLAGS,
                     Float:volume = SNDVOL_NORMAL,
                     pitch = SNDPITCH_NORMAL,
                     speakerentity = -1,
                     const Float:origin[3] = NULL_VECTOR,
                     const Float:dir[3] = NULL_VECTOR,
                     bool:updatePos = true,
                     Float:soundtime = 0.0)
    {
        if (PrepareSound(sample))
        {
            EmitSoundToAll(sample, entity, channel,
                           level, flags, volume, pitch, speakerentity,
                           origin, dir, updatePos, soundtime);
        }
    }
#endif

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Natives
    CreateNative("ControlZtf2grab",Native_ControlZtf2grab);
    CreateNative("GiveGravgun",Native_GiveGravgun);
    CreateNative("TakeGravgun",Native_TakeGravgun);
    CreateNative("PickupObject",Native_PickupObject);
    CreateNative("DropObject",Native_DropObject);
    CreateNative("StartThrowObject",Native_StartThrowObject);
    CreateNative("ThrowObject",Native_ThrowObject);
    CreateNative("RotateObject",Native_RotateObject);
    CreateNative("DropEntity",Native_DropEntity);
    CreateNative("HasObject",Native_HasObject);

    // Register Forwards
    fwdOnPickupObject=CreateGlobalForward("OnPickupObject", ET_Hook,Param_Cell,Param_Cell,Param_Cell);
    fwdOnCarryObject=CreateGlobalForward("OnCarryObject", ET_Hook,Param_Cell,Param_Cell,Param_Cell);
    fwdOnThrowObject=CreateGlobalForward("OnThrowObject", ET_Hook,Param_Cell,Param_Cell);
    fwdOnDropObject=CreateGlobalForward("OnDropObject", ET_Ignore,Param_Cell,Param_Cell);
    fwdOnObjectStop=CreateGlobalForward("OnObjectStop", ET_Ignore,Param_Cell);

    RegPluginLibrary("ztf2grab");

    return APLRes_Success;
}


public OnPluginStart() 
{
    // events
    HookEvent("player_death", PlayerDeath);
    HookEvent("player_spawn",PlayerSpawn);

    // convars
    CreateConVar("sm_grab_version", PLUGIN_VERSION, "ZGrab:TF2", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    cvSpeed = CreateConVar("sm_grab_speed", "25.0", "Speed at which held objects move (Default 25) -WARNING- Don't set too high or objects start flying all over the place", FCVAR_PLUGIN);
    cvDistance = CreateConVar("sm_grab_distance", "100.0", "Distance an object is held at (Default 100)", FCVAR_PLUGIN);
    cvTeamRestrict = CreateConVar("sm_grab_teams", "0", "restrict usage based on teams (0=all can use, 2 or 3 to restrict red or blu", FCVAR_PLUGIN);
    cvSound = CreateConVar("sm_grab_sound", "weapons/physcannon/hold_loop.wav", "sound to play, change takes effect on map change", FCVAR_PLUGIN);
    cvMissSound = CreateConVar("sm_grab_misssound", "weapons/physcannon/physcannon_dryfire.wav", "sound to play for misses, change takes effect on map change", FCVAR_PLUGIN);
    cvInvalidSound = CreateConVar("sm_grab_invalidsound", "weapons/physcannon/physcannon_tooheavy.wav", "sound to play for errors, change takes effect on map change", FCVAR_PLUGIN);
    cvPickupSound = CreateConVar("sm_grab_pickupsound", "weapons/physcannon/physcannon_pickup.wav", "sound to play for pickup, change takes effect on map change", FCVAR_PLUGIN);
    cvThrowSound = CreateConVar("sm_grab_throwsound", "weapons/physcannon/superphys_launch1.wav", "sound to play for throw, change takes effect on map change", FCVAR_PLUGIN);
    cvDropSound = CreateConVar("sm_grab_dropsound", "weapons/physcannon/physcannon_drop.wav", "sound to play for drop, change takes effect on map change", FCVAR_PLUGIN);
    cvGround = CreateConVar("sm_grab_soccer", "0", "soccer (ground mode) (1/0 = on/off)", FCVAR_PLUGIN);
    cvThrowTime = CreateConVar("sm_grab_throwcharge", "2.0", "Time to charge throw to full (default 2.0)", FCVAR_PLUGIN);
    cvThrowMinTime = CreateConVar("sm_grab_mincharge", "0.2", "minimum charge time, anything less drops (default 0.2)", FCVAR_PLUGIN);
    cvThrowSpeed = CreateConVar("sm_grab_throwspeed", "1000.0", "speed at which an object is thrown. (default 1000)", FCVAR_PLUGIN);
    cvMaxDistance = CreateConVar("sm_grab_reach", "512.0", "maximum distance from which you can grab an object (default 512)", FCVAR_PLUGIN);
    cvMaxDuration = CreateConVar("sm_grab_fatiguetime", "0.0", "maximum time objects can be held before being dropped in seconds (default 0.0 is infinite)", FCVAR_PLUGIN);
    cvSteal = CreateConVar("sm_grab_thief", "1", "Can objects be stolen from another player who is holding it? (1/0 = yes/no)", FCVAR_PLUGIN);
    cvDropOnJump = CreateConVar("sm_grab_jumpdrop", "1", "drop objects when jumping to prevent glitch-flying? (1/0 = yes/no)", FCVAR_PLUGIN);
    cvThrowGravity = CreateConVar("sm_grab_throwgrav", "1.0", "gravity of thrown buildings (default 1.0)", FCVAR_PLUGIN);
    cvDropGravity = CreateConVar("sm_grab_dropgrav", "10.0", "gravity of dropped buildings (default 10.0)", FCVAR_PLUGIN);
    cvStopSpeed = CreateConVar("sm_grab_stopspeed", "10.0", "speed buildings are considered stopped", FCVAR_PLUGIN);
    cvDebug = CreateConVar("sm_grab_debug", "0", "display object classtype on grab attempt", FCVAR_PLUGIN);
    cvMovetype = CreateConVar("sm_grab_movetype", "1", "change the movetype of grabbed/thrown objects (1/0 = yes/no)", FCVAR_PLUGIN);

    if (GetGameType() == tf2)
    {
        cvBuildingSound = CreateConVar("sm_grab_buildingsound", "weapons/physcannon/superphys_hold_loop.wav", "sound to play, change takes effect on map change", FCVAR_PLUGIN);
        cvBuildings = CreateConVar("sm_grab_buildings", "1", "can engi buildings be picked up? (1/0 = yes/no)", FCVAR_PLUGIN);
        cvOtherBuildings = CreateConVar("sm_grab_teamgrab", "1", "can teammates buildings be picked up? (1/0 = yes/no)", FCVAR_PLUGIN);
        cvThrowBuildings = CreateConVar("sm_grab_throw", "1", "can buildings be thrown? (1/0 = yes/no)", FCVAR_PLUGIN);
        cvThrowSetDisabled = CreateConVar("sm_grab_throwdisable", "1", "set buildings disabled when thrown? (1/0 = yes/no)", FCVAR_PLUGIN);
        cvGrabSetDisabled = CreateConVar("sm_grab_grabdisable", "1", "set buildings disabled when grabbed? (1/0 = yes/no)", FCVAR_PLUGIN);
        cvDropOnSapped = CreateConVar("sm_grab_sapped", "1", "drop objects if they are sapped? (1/0 = yes/no)", FCVAR_PLUGIN);
        cvAllowRepair = CreateConVar("sm_grab_norepair", "1", "Allow objects to be repaired while held? (0 allows, 1 disallows)", FCVAR_PLUGIN);
        cvDispenserEnabled = CreateConVar("sm_grab_dispenser", "1", "Can engie dispeners be grabbed? (0=no 1=yes)", FCVAR_PLUGIN);
        cvEnableBits = CreateConVar("sm_grab_altenable", "7", "Enable/Disable Engi Alt-Fire/Reload Support (1=shotgun,2=wrench,4=wrench-reload)", FCVAR_PLUGIN);

        cvProps = CreateConVar("sm_grab_props", "0", "can props be picked up? (1/0 = yes/no)", FCVAR_PLUGIN);

        // convarchange
        HookConVarChange(cvEnableBits, Cvar_enabled); 
    }

    // commands
    RegConsoleCmd("+grav", Command_Grab);
    RegConsoleCmd("-grav", Command_UnGrab2);
    RegConsoleCmd("+throw", Command_Throw);
    RegConsoleCmd("-throw", Command_UnThrow);
    RegConsoleCmd("rotate", Command_Rotate);
}

public OnConfigsExecuted()
{
    g_EnableBits = cvEnableBits ? GetConVarInt(cvEnableBits) : 0;

    // setup sounds

    #if !defined _ResourceManager_included
        // Setup trie to keep track of precached sounds
        if (g_soundTrie == INVALID_HANDLE)
            g_soundTrie = CreateTrie();
        else
            ClearTrie(g_soundTrie);
    #endif

    GetConVarString(cvSound, gSound, sizeof(gSound));
    GetConVarString(cvMissSound, gMissSound, sizeof(gMissSound));
    GetConVarString(cvInvalidSound, gInvalidSound, sizeof(gInvalidSound));
    GetConVarString(cvPickupSound, gPickupSound, sizeof(gPickupSound));
    GetConVarString(cvThrowSound, gThrowSound, sizeof(gThrowSound));
    GetConVarString(cvDropSound, gDropSound, sizeof(gDropSound));

    SetupSound(gSound, true);
    SetupSound(gMissSound, true);
    SetupSound(gInvalidSound, true);
    SetupSound(gPickupSound, true);
    SetupSound(gThrowSound, true);
    SetupSound(gDropSound, true);

    if (cvBuildingSound)
    {
        GetConVarString(cvBuildingSound, gBuildingSound, sizeof(gBuildingSound));
        SetupSound(gBuildingSound, true);
    }
} 

public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_EnableBits = GetConVarInt(cvEnableBits);
} 

public OnMapStart()
{ 
    // reset object list
    for (new i=0; i<=MAXPLAYERS; i++)
    {
        gObj[i] = 0;
        gThrow[i] = 0.0;
        gGrabTime[i] = 0.0;
        gJustGrabbed[i] = false;
    }

    // start timer
    gTimer = CreateTimer(0.1, UpdateObjects, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
        gObj[client] = 0;
        gThrow[client]=0.0;
        gGrabTime[client]=0.0;
        gPermissions[client] = 0;
        gJustGrabbed[client] = false;
    }
    return true;
}

public OnClientDisconnect(client)
{
    if (gObj[client] != 0)
        Command_UnGrab(client, 0);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    // running GetConVarBool every frame is not good...
    if (g_EnableBits) 
    {
        if (TF2_GetPlayerClass(client)==TFClass_Engineer) 
        {
            decl String:wpn[32];
            GetClientWeapon(client, wpn, sizeof(wpn));

            if ((g_EnableBits & ENABLE_ALT_SHOTGUN) &&
                StrEqual(wpn, "tf_weapon_shotgun_primary")) 
            {
                if (buttons & IN_ATTACK2) 
                {
                    if (!g_EngiButtonDown[client])
                    {
                        Command_Grab(client, 0);
                        g_EngiButtonDown[client] = true;
                    }
                } 
                else 
                {
                    if (g_EngiButtonDown[client]) 
                    {
                        Command_UnGrab(client, 0);
                        g_EngiButtonDown[client] = false;
                    }
                }
            }
            else if ((g_EnableBits & (ENABLE_RELOAD_WRENCH)) &&
                     StrEqual(wpn, "tf_weapon_wrench")) 
            {
                if (buttons & IN_RELOAD)
                {
                    if(!g_ReloadButtonDown[client]) 
                    {
                        g_ReloadButtonDown[client] = true;
                        gRotation[client] += 90.0;
                        if (gRotation[client] > 180.0)
                            gRotation[client] = -90.0;
                    }
                } 
                else 
                {
                    g_ReloadButtonDown[client] = false;
                }
            }
        }
    }
    return Plugin_Continue;
}  

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    // reset object held
    gObj[client] = 0;
    gThrow[client] = 0.0;
    gGrabTime[client] = 0.0;
    gJustGrabbed[client] = false;

    StopSound(client, SNDCHAN_AUTO, gSound);

    if (cvBuildingSound && gBuildingSound[0])
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

            if (!GetConVarBool(cvDropOnJump))
                gPermissions[client] |= CAN_JUMP_WHILE_HOLDING;

            if (GetGameType() == tf2)
            {
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

                if (!GetConVarBool(cvDropOnSapped))
                    gPermissions[client] |= CAN_HOLD_WHILE_SAPPED;

                if (!GetConVarBool(cvAllowRepair))
                    gPermissions[client] |= CAN_REPAIR_WHILE_HOLDING;

                if (GetConVarBool(cvProps))
                    gPermissions[client] |= CAN_GRAB_PROPS;
            }
            else
                gPermissions[client] |= CAN_GRAB_PROPS;
        }
        else
            gPermissions[client] = 0;
    }

    return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GameType == tf2)
    {
        // Skip feigned deaths.
        if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
            return Plugin_Continue;

        // Skip fishy deaths.
        if (GetEventInt(event, "weaponid") == TF_WEAPON_BAT_FISH &&
            GetEventInt(event, "customkill") != TF_CUSTOM_FISH_KILL)
        {
            return Plugin_Continue;
        }
    }

    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    // Still holding an object?
    if (gObj[client] != 0)
        Command_UnGrab(client, 0);

    // make sure to reset object held
    gObj[client] = 0;
    gThrow[client] = 0.0;
    gGrabTime[client] = 0.0;
    gJustGrabbed[client] = false;
    StopSound(client, SNDCHAN_AUTO, gSound);

    if (cvBuildingSound && gBuildingSound[0])
        StopSound(client, SNDCHAN_AUTO, gBuildingSound);

    return Plugin_Continue;
}

public Action:Command_Rotate(client, args)
{
	// check if EngiButtonDown is true
    if (g_ReloadButtonDown[client] == true)
        return Plugin_Handled;

    // if an object is being held
    else if (gObj[client] != 0 && EntRefToEntIndex(gObj[client]) > 1)
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
    if (gObj[client] != 0 && EntRefToEntIndex(gObj[client]) < 1)
        return Command_UnGrab(client, args);

    // make sure client is not spectating
    else if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
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
            PrepareAndEmitSoundToAll(gMissSound, client);

        return Plugin_Handled;
    }

    new builder=0;
    new grabType:grab = GetGrabType(ent);

    if (ent > 0 && GetConVarBool(cvDebug))
    {
        new String:edictname[128];
        GetEdictClassname(ent, edictname, 128);
        if (GameType == tf2 && strncmp(edictname, "obj_", 4) == 0)
        {
            LogMessage("%N target is %d:%s, type=%d, mode=%d", client, grab, edictname,
                       GetEntProp(ent, Prop_Send, "m_iObjectType"),
                       GetEntProp(ent, Prop_Send, "m_iObjectMode"));
            PrintToChat(client, ">%d:%s, type=%d, mode=%d", grab, edictname,
                        GetEntProp(ent, Prop_Send, "m_iObjectType"),
                        GetEntProp(ent, Prop_Send, "m_iObjectMode"));
        }
        else
        {
            LogMessage("%N target is %d:%s", client, grab, edictname);
            PrintToChat(client, ">%d:%s", grab, edictname);
        }
    }

    // Check for known TF2 objects
    if (grab >= dispenser && grab <= teleporter_exit)
    {
        builder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
        if (builder > 0)
        {
            new permissions = gPermissions[client];
            if (!(permissions & CAN_GRAB_BUILDINGS) ||
                 (grab == dispenser &&
                  !GetConVarBool(cvDispenserEnabled)))
            {
                if (!groundmode)
                    PrepareAndEmitSoundToAll(gInvalidSound, client);

                return Plugin_Handled;
            }
            else
            {
                new Float:complete = GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed");
                if (complete < 1.0)
                {
                    if (!groundmode)
                        PrepareAndEmitSoundToAll(gInvalidSound, client);

                    return Plugin_Handled;
                }
                else if (!(permissions & CAN_GRAB_OTHER_BUILDINGS) &&
                        builder != client)
                {
                    if (!groundmode)
                        PrepareAndEmitSoundToAll(gInvalidSound, client);

                    return Plugin_Handled;
                }
                else if (!(permissions & CAN_HOLD_WHILE_SAPPED) &&
                        GetEntProp(ent, Prop_Send, "m_bHasSapper") &&
                        GetEntProp(ent, Prop_Send, "m_iTeamNum") == GetClientTeam(client))
                {
                    if (!groundmode)
                        PrepareAndEmitSoundToAll(gInvalidSound, client);

                    return Plugin_Handled;
                }
            }
        }
        else
        {
            if (!groundmode)
                PrepareAndEmitSoundToAll(gInvalidSound, client);

            return Plugin_Handled;
        }
    }
    else
    {
        if (grab != prop || !(gPermissions[client] & CAN_GRAB_PROPS))
        {
            if (!groundmode)
                PrepareAndEmitSoundToAll(gInvalidSound, client);

            return Plugin_Handled;
        }
    }

    if (grab < none)
    {
        // check if another player is holding it
        for (new j=1; j<=MaxClients; j++)
        {
            if (EntRefToEntIndex(gObj[j]) == ent)
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
                        PrepareAndEmitSoundToAll(gInvalidSound, client);

                    return Plugin_Handled;
                }
            }
        }

        new Action:res = Plugin_Continue;
        Call_StartForward(fwdOnPickupObject);
        Call_PushCell(client);
        Call_PushCell(builder);
        Call_PushCell(ent);
        Call_Finish(res);

        if (res == Plugin_Continue)
        {
            new bool:moveFlag=GetConVarBool(cvMovetype);

            // grab entity
            gObj[client] = EntIndexToEntRef(ent);
            gType[client] = grab;
            gThrow[client] = 0.0;
            gRotation[client] = 0.0;
            gGrabTime[client] = GetEngineTime();
            gGravity[client] = (gThrowGravity[client] != 1.0) ? GetEntityGravity(ent) : 1.0;
            gMove[client] = (moveFlag) ? GetEntityMoveType(ent) : MOVETYPE_NONE;
            gJustGrabbed[client] = true;

            if (grab >= dispenser && grab <= teleporter_exit)
            {
                gHealth[client] = GetEntProp(ent, Prop_Send, "m_iHealth");

                new Handle:timer = gTrackTimers[ent];
                if (timer != INVALID_HANDLE)
                {
                    gTrackTimers[ent] = INVALID_HANDLE;
                    //KillTimer(timer, true);
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
                new Float:vecPos[3];
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPos);

                // and "rotate it to match where the client is facing.
                new Float:vecAngles[3];
                GetClientAbsAngles(client, vecAngles);
                vecAngles[1] += gRotation[client];
                if (vecAngles[1] < -180.0)
                    vecAngles[1] += 360.0;
                else if (vecAngles[1] > 180.0)
                    vecAngles[1] -= 360.0;

                if ((gPermissions[client] & CAN_JUMP_WHILE_HOLDING))
                {
                    vecAngles[0] = 0.0;
                    vecAngles[2] = 0.0;

                    // Check if client is within same area(x,y) as object.
                    /*
                    new Float:clientPos[3];
                    GetClientAbsOrigin(client, clientPos);

                    new Float:size[3];
                    GetEntPropVector(ent, Prop_Data, "m_vecBuildMaxs", size);
                    size[0] /= 2.0;
                    size[1] /= 2.0;

                    if ((clientPos[0] >= vecPos[0] - size[0] && clientPos[0] <= vecPos[0] + size[0]) &&
                        (clientPos[1] >= vecPos[1] - size[1] && clientPos[1] <= vecPos[1] + size[1]))
                    {
                        // "pop" the client up a little to prevent sticking in the object
                        clientPos[2] += 30.0;
                        TeleportEntity(client, clientPos, NULL_VECTOR, NULL_VECTOR);
                    }
                    */
                }
                else // "pop" the object up a little to prevent stickage.
                    vecPos[2] += 30.0;

                TeleportEntity(ent, vecPos, vecAngles, NULL_VECTOR);

                if (moveFlag)
                    SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);

                PrepareAndEmitSoundToAll(gPickupSound, client);
                if (cvBuildingSound && gBuildingSound[0] &&
                    grab >= dispenser && grab <= teleporter_exit)
                {
                    PrepareAndEmitSoundToAll(gBuildingSound, client);
                }
                else
                    PrepareAndEmitSoundToAll(gSound, client);
            }
        }
        else
        {
            if (!groundmode)
                PrepareAndEmitSoundToAll(gInvalidSound, client);
        }
    }
    else
    {
        if (!groundmode)
            PrepareAndEmitSoundToAll(gMissSound, client);
    }

    return Plugin_Handled;
}

public Action:Command_UnGrab(client, args)
{
    if (gThrow[client]>0.0)
        PrintHintText(client, " ");

    // If client is still holding an entity, drop it
    if (gObj[client] != 0)
        Drop(client, false);

    return Plugin_Handled;
}

Drop(client, bool:throw)
{
    new bool:groundmode = GetConVarBool(cvGround);
    if (!groundmode) // no sound in ground mode
    {
        StopSound(client, SNDCHAN_AUTO, gSound);

        if (cvBuildingSound && gBuildingSound[0])
            StopSound(client, SNDCHAN_AUTO, gBuildingSound);
    }

    new ref = gObj[client];
    new ent = EntRefToEntIndex(ref);
    if (ent > 0)
    {
        if (!throw)
        {
            if (!groundmode)
                PrepareAndEmitSoundToAll(gDropSound, client);

            new Float:dropGravity = GetConVarFloat(cvDropGravity);
            if (dropGravity != gGravity[client])
                SetEntityGravity(ent, dropGravity);

            if (GetConVarBool(cvMovetype))
                SetEntityMoveType(ent, MOVETYPE_FLYGRAVITY);

            static const Float:speed[3] = { 0.0, 0.0, -1.0 };
            TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, speed);
        }

        new grabType:gt = gType[client];
        if (gt >= dispenser && gt <= teleporter_exit)
        {
            new bool:disable = gDisabled[ent];
            if (throw && !disable && (gt >= dispenser && gt <= teleporter_exit) &&
                !(gPermissions[client] & CAN_THROW_ENABLED_BUILDINGS) &&
                GetEntProp(ent, Prop_Send, "m_iTeamNum") == GetClientTeam(client))
            {
                disable = !GetEntProp(ent, Prop_Send, "m_bDisabled");
                if (disable)
                    SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
            }

            new Handle:pack;
            gTrackTimers[ent] = CreateDataTimer(0.2,TrackObject,pack,TIMER_REPEAT);
            if (gTrackTimers[ent] != INVALID_HANDLE)
            {
                new Float:vecPos[3];
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPos);
                WritePackCell(pack, ent);
                WritePackCell(pack, ref);
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
            Call_StartForward(fwdOnDropObject);
            Call_PushCell(client);
            Call_PushCell(ent);
            Call_Finish(res);
        }
    }

    gObj[client] = 0;
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
    if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Handled;

    // client doesn't have an object?
    else if (gObj[client] == 0 || EntRefToEntIndex(gObj[client]) < 1)
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
    if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Handled;

    // client doesn't have an object?
    new ent = EntRefToEntIndex(gObj[client]);
    if (ent > 0)
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
        Call_StartForward(fwdOnThrowObject);
        Call_PushCell(client);
        Call_PushCell(ent);
        Call_Finish(res);

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
            ScaleVector(speed, throwspeed);

            if (throwgravity != gGravity[client])
                SetEntityGravity(ent, throwgravity);

            if (GetConVarBool(cvMovetype))
                SetEntityMoveType(ent, (throwgravity <= 0.0) ? MOVETYPE_FLY : MOVETYPE_FLYGRAVITY);

            TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, speed);

            if (GetConVarInt(cvGround)!=1)
                PrepareAndEmitSoundToAll(gThrowSound, client);
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
    new ref = ReadPackCell(pack);

    // check if the object is still the same type we picked up
    if (EntRefToEntIndex(ref) == ent)
    {
        new grabType:gt = grabType:ReadPackCell(pack);
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
        new Float:speed = vecVel[0] + vecVel[1] + vecVel[2];
        if (speed < 0)
            speed *= -1.0;

        new bool:bStop = (speed < stopSpeed);
        new Float:height = 0.0;
        decl Float:vecBelow[3];
        decl Float:vecCheckBelow[3];

        new bool:bGround = ((GetEntityFlags(ent) & FL_ONGROUND) != 0);
        //if (!bGround) // F_ONGROUND flag lies!!!
        {
            //Check below the object for the ground
            vecCheckBelow[0] = vecPos[0];
            vecCheckBelow[1] = vecPos[1];
            vecCheckBelow[2] = vecPos[2] - 1000.0;
            TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                              RayType_EndPoint, TraceRayObject, ent);
            if (TR_DidHit(INVALID_HANDLE))
            {
                TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                vecGround[2] = vecBelow[2];
                height = (vecPos[2] - vecBelow[2]);
                if (bGround && height > 0.0)
                    bGround = false;

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
                bGround = bStop = false;
        }

        if (!bStop && !bGround && lastSpeed < stopSpeed)
        {
            if (speed < stopSpeed)
            {
                stopCount++;
                if (stopCount > 10)
                    bStop = true; // it's stuck real good :(
                else if (stopCount > 2)
                {
                    if (gt >= dispenser && gt <= teleporter_exit)
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
                        stopSpeed *= 5.0;
                        new Float:negSpeed = stopSpeed * -1.0;
                        decl Float:vecKnock[3];
                        vecKnock[0]= GetRandomFloat(negSpeed, stopSpeed);
                        vecKnock[1]= GetRandomFloat(negSpeed, stopSpeed);
                        vecKnock[2]= GetRandomFloat(negSpeed, stopSpeed);
                        TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, vecKnock);
                    }
                    else
                        bStop = true;
                }
            }
            else
                stopCount = 0;
        }

        if (bStop || bGround || height <= 0.0)
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

            if (gt >= dispenser && gt <= teleporter_exit)
            {
                if (gDisabled[ent] && !GetEntProp(ent, Prop_Send, "m_bHasSapper"))
                    SetEntProp(ent, Prop_Send, "m_bDisabled", 0);
            }

            if (!bGround)
            {
                //Check the right side
                vecPos[0] += 30.0;
                vecCheckBelow[0] += 30.0;
                TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                                  RayType_EndPoint, TraceRayObject, ent);
                if (TR_DidHit(INVALID_HANDLE))
                {
                    TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                    if (vecGround[2] < vecBelow[2])
                        vecGround[2] = vecBelow[2];
                }

                //Check the top right corner
                vecPos[1] += 30.0;
                vecCheckBelow[1] += 30.0;
                TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                                  RayType_EndPoint, TraceRayObject, ent);
                if (TR_DidHit(INVALID_HANDLE))
                {
                    TR_GetEndPosition(vecBelow, INVALID_HANDLE);
                    if (vecGround[2] < vecBelow[2])
                        vecGround[2] = vecBelow[2];
                }

                //Check the top middle
                vecPos[0] -= 30.0;
                vecCheckBelow[0] -= 30.0;
                TR_TraceRayFilter(vecPos, vecCheckBelow, MASK_GRABBERSOLID,
                                  RayType_EndPoint, TraceRayObject, ent);
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
                                  RayType_EndPoint, TraceRayObject, ent);
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
                                  RayType_EndPoint, TraceRayObject, ent);
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
                                  RayType_EndPoint, TraceRayObject, ent);
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
                                  RayType_EndPoint, TraceRayObject, ent);
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
                                  RayType_EndPoint, TraceRayObject, ent);
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
            }

            new Action:res = Plugin_Continue;
            Call_StartForward(fwdOnObjectStop);
            Call_PushCell(ent);
            Call_Finish(res);
        }
        else
        {
            ResetPack(pack, true);
            WritePackCell(pack, ent);
            WritePackCell(pack, ref);
            WritePackCell(pack, _:gt);
            WritePackCell(pack, _:mt);
            WritePackFloat(pack, gravity);
            WritePackFloat(pack, vecPos[0]);
            WritePackFloat(pack, vecPos[1]);
            WritePackFloat(pack, vecPos[2]);
            WritePackFloat(pack, speed);
            WritePackCell(pack, stopCount);
            return Plugin_Continue;
        }
    }

    if (ent > 0)
    {
        gDisabled[ent] = false;
        gTrackTimers[ent] = INVALID_HANDLE;
    }
    return Plugin_Stop;
}

public bool:TraceRayObject(entity, mask, any:data)
{
    // Check if the TraceRay hit itself or a player.
    return (entity != data && (entity <= 0 || entity > MaxClients));
}

public Action:UpdateObjects(Handle:timer)
{
    new ent;
    new Float:viewang[3];                                       // angles
    new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];      // vectors
    new Float:throwmintime = GetConVarFloat(cvThrowMinTime);
    new Float:throwtime = GetConVarFloat(cvThrowTime);
    new Float:distance = GetConVarFloat(cvDistance);
    new bool:groundmode = GetConVarBool(cvGround);
    new Float:speed = GetConVarFloat(cvSpeed);
    new Float:time = GetEngineTime();
    for (new i=0; i<=MaxClients; i++)
    {
        ent = EntRefToEntIndex(gObj[i]);
        if (ent > 0)
        {
            new permissions = gPermissions[i];
            if (!(permissions & CAN_JUMP_WHILE_HOLDING) &&
                    (GetClientButtons(i) & IN_JUMP))
            {
                Drop(i, false);
                continue;
            }

            if (GameType == tf2)
            {
                switch (TF2_GetPlayerClass(i))
                {
                    case TFClass_Spy:
                    {
                        if (TF2_IsPlayerCloaked(i) ||
                            TF2_IsPlayerDeadRingered(i))
                        {
                            Drop(i, false);
                            continue;
                        }
                        else if (TF2_IsPlayerDisguised(i))
                            TF2_RemovePlayerDisguise(i);
                    }
                    case TFClass_Scout:
                    {
                        if (TF2_IsPlayerBonked(i))
                        {
                            Drop(i, false);
                            continue;
                        }
                    }
                }
            }

            new grabType:gt = gType[i];
            if (gt >= dispenser && gt <= teleporter_exit)
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

                if (!(permissions & CAN_HOLD_ENABLED_BUILDINGS) &&
                        GetEntProp(ent, Prop_Send, "m_iTeamNum") == GetClientTeam(i))
                {
                    SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
                }
            }

            new Float:grabTime = gGrabTime[i];
            new Action:res = Plugin_Continue;
            Call_StartForward(fwdOnCarryObject);
            Call_PushCell(i);
            Call_PushCell(ent);
            Call_PushCell(grabTime);
            Call_Finish(res);

            if (res == Plugin_Changed &&
                gt >= dispenser && gt <= teleporter_exit &&
                GetEntProp(ent, Prop_Send, "m_bDisabled"))
            {
                gDisabled[ent] = true;
            }

            if (res == Plugin_Stop)
            {
                Drop(i, false);
                continue;
            }

            // get client info
            GetClientEyeAngles(i, viewang);
            GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);

            /*if (permissions & CAN_JUMP_WHILE_HOLDING)
            {
                new Float:clientPos[3];
                GetClientAbsOrigin(i, clientPos);

                new Float:size[3];
                GetEntPropVector(ent, Prop_Data, "m_vecBuildMaxs", size);
                size[0] /= 2.0;
                size[1] /= 2.0;

                // Check if client is within same area(x,y) as object (on top of it).
                if ((clientPos[0] >= vecPos[0] - size[0] && clientPos[0] <= vecPos[0] + size[0]) &&
                        (clientPos[1] >= vecPos[1] - size[1] && clientPos[1] <= vecPos[1] + size[1]))
                {
                    GetClientAbsOrigin(i, vecPos);
                }
                else
                    GetClientEyePosition(i, vecPos);
            }
            else*/
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

            if (groundmode || (permissions & CAN_JUMP_WHILE_HOLDING))
            {
                viewang[0] = 0.0;
                viewang[2] = 0.0;
            }

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
                new Float:thetime = time - grabTime;
                if (thetime > gMaxDuration[i])
                    Command_UnGrab(i, 0);
            }
        }
        else
        {
            gObj[i] = 0;
            Drop(i, false);
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
    return (entity != data); // Check if the TraceRay hit itself.
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
        else if (strcmp("obj_teleporter", edictname, false)==0)
            return (teleporter_entry + grabType:GetEntProp(ent, Prop_Send, "m_iObjectType"));
        else if (strcmp("obj_sapper", edictname, false)==0)
            return sapper; // ent is a teleporter_exit
        else if (strncmp("obj_", edictname, 4, false)==0)
            return object; // ent is an object
        else if (strncmp("prop_", edictname, 5, false)==0)
            return prop; // ent is a physics entities
        else if (strncmp("prop_", edictname, 5, false)==0)
            return unknown; // ent is a unknown
    }
    return none;
}

public Native_ControlZtf2grab(Handle:plugin,numParams)
{
    gNativeOverride = GetNativeCell(1);
}

public Native_GiveGravgun(Handle:plugin,numParams)
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

        if (!GetConVarBool(cvDropOnJump))
            gPermissions[client] |= CAN_JUMP_WHILE_HOLDING;

        if (GetGameType() == tf2)
        {
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

            if (GetConVarBool(cvProps))
                gPermissions[client] |= CAN_GRAB_PROPS;
        }
        else
            gPermissions[client] |= CAN_GRAB_PROPS;
    }
}

public Native_TakeGravgun(Handle:plugin,numParams)
{
    gPermissions[GetNativeCell(1)] = 0;
}

public Native_PickupObject(Handle:plugin,numParams)
{
    Command_Grab(GetNativeCell(1), 0);
}

public Native_DropObject(Handle:plugin,numParams)
{
    Command_UnGrab(GetNativeCell(1), 0);
}

public Native_StartThrowObject(Handle:plugin,numParams)
{
    Command_Throw(GetNativeCell(1), 0);
}

public Native_ThrowObject(Handle:plugin,numParams)
{
    Command_UnThrow(GetNativeCell(1), 0);
}

public Native_RotateObject(Handle:plugin,numParams)
{
    Command_Rotate(GetNativeCell(1), 0);
}

public Native_DropEntity(Handle:plugin,numParams)
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

            new ref = EntIndexToEntRef(ent);
            WritePackCell(pack, ent);
            WritePackCell(pack, ref);
            WritePackCell(pack, _:gt);
            WritePackCell(pack, _:mt);
            WritePackFloat(pack, oldGravity);
            WritePackFloat(pack, vecPos[0]);
            WritePackFloat(pack, vecPos[1]);
            WritePackFloat(pack, vecPos[2]);
            WritePackFloat(pack, speed[2]);
            WritePackCell(pack, 0);
        }
    }
}

public Native_HasObject(Handle:plugin,numParams)
{
    return gObj[GetNativeCell(1)];
}

/**
 * End of ztf2grab.sp
 */
