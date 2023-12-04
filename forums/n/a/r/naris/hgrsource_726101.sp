/* 
 * vim: set ai et ts=4 sw=4 :
 * File: hgrsource.sp
 * Description: Allows admins (or all players) to hook on to walls,
 *              grab other players, or swing on a rope
 * Author: SumGuy14 (Aka SoccerDude)
 * Modifications by: Naris (Murray Wilson)
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>

// Define _TRACE to enable trace logging for debugging
//#define _TRACE
#tryinclude <trace>
#if !defined _trace_included
    #define TraceInto(%1);
    #define TraceDump(%1);
    #define TraceReturn(%1);
    #define SetTraceCat(%1);
    #define SetTraceCategory(%1);
    #define ResetTraceCategory(%1);

    #define TraceAudit(%1);
    #define TraceCritical(%1);
    #define TraceError(%1);
    #define TraceProblem(%1);
    #define TraceWarning(%1);
    #define TraceInfo(%1);
    #define TraceDecision(%1);
    #define TraceDebug(%1);
    #define TraceDetail(%1);
    #define TraceCat(%1,%2);
    #define Trace(%1);
#endif

#define IsValidClient(%1) (%1 > 0 && %1 <= MaxClients && IsClientInGame(%1))
#define ValidClientIndex(%1) (IsValidClient(%1) ? %1 : 0)

#define SEEKING_SOUND       "weapons/crossbow/bolt_fly4.wav" // "weapons/tripwire/ropeshoot.wav";
#define GRABHIT_SOUND       "weapons/crossbow/bolt_skewer1.wav"
#define PULLER_SOUND        "weapons/crowwbow/hitbod2.wav"
#define DENIED_SOUND        "buttons/combine_button_locked.wav"
#define ERROR_SOUND         "player/suit_denydevice.wav"

#define SC_SEEKING_SOUND    "sc/ropeshoot2.wav"
#define SC_GRABHIT_SOUND  	"sc/zluhit00.mp3"
#define SC_PULLER_SOUND     "sc/intonydus.mp3"
#define SC_DENIED_SOUND     "sc/buzz.wav"
#define SC_ERROR_SOUND      "sc/perror.mp3"

#define LASER_MODEL         "materials/sprites/laserbeam.vmt"

#define ACTION_HOOK 0
#define ACTION_GRAB 1
#define ACTION_ROPE 2
#define NUM_ACTIONS 3

#define COLOR_DEFAULT 0x01
#define COLOR_GREEN 0x04

#define VERSION "2.1.8d"

enum Collision_Group_t
{
    COLLISION_GROUP_NONE  = 0,
    COLLISION_GROUP_DEBRIS,            // Collides with nothing but world and static stuff
    COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
    COLLISION_GROUP_INTERACTIVE_DEB, // RIS, // Collides with everything except other interactive debris or debris
    COLLISION_GROUP_INTERACTIVE,    // Collides with everything except interactive debris or debris
    COLLISION_GROUP_PLAYER,
    COLLISION_GROUP_BREAKABLE_GLASS,
    COLLISION_GROUP_VEHICLE,
    COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player
                                        
    COLLISION_GROUP_NPC,            // Generic NPC group
    COLLISION_GROUP_IN_VEHICLE,        // for any entity inside a vehicle
    COLLISION_GROUP_WEAPON,            // for any weapons that need collision detection
    COLLISION_GROUP_VEHICLE_CLIP,    // vehicle clip brush to restrict vehicle movement
    COLLISION_GROUP_PROJECTILE,        // Projectiles!
    COLLISION_GROUP_DOOR_BLOCKER,    // Blocks entities not permitted to get near moving doors
    COLLISION_GROUP_PASSABLE_DOOR,    // Doors that the player shouldn't collide with
    COLLISION_GROUP_DISSOLVING,        // Things that are dissolving are in this group
    COLLISION_GROUP_PUSHAWAY,        // Nonsolid on client and server, pushaway in player code

    COLLISION_GROUP_NPC_ACTOR,        // Used so NPCs in scripts ignore the player.

    LAST_SHARED_COLLISION_GROUP
};

enum HGRSourceAction
{
    Hook = 0, /** User is using hook */
    Grab = 1, /** User is using grab */
    Rope = 2, /** User is using rope */
};

enum HGRSourceAccess
{
    Give = 0, /** Gives access to user */
    Take = 1, /** Takes access from user */
};

public Plugin:myinfo = 
{
    name = "HGR:Source",
    author = "SumGuy14 (Aka Soccerdude)",
    description = "Allows admins (or all players) to hook on to walls, grab other players, or swing on a rope",
    version = VERSION,
    url = "http://sourcemod.net/"
};

// General handles
new Handle:cvarAnnounce;
// Sound handles
new Handle:cvarGrabHitSound;
new Handle:cvarSeekingSound;
new Handle:cvarErrorSound;
new Handle:cvarPullSound;
new Handle:cvarDeniedSound;
new Handle:cvarFireSound;
new Handle:cvarHitSound;
// Hook handles
new Handle:cvarHookEnable;
new Handle:cvarHookAdminOnly;
new Handle:cvarHookNoFlag;
new Handle:cvarHookSpeed;
new Handle:cvarHookBeamColor;
new Handle:cvarHookRed;
new Handle:cvarHookGreen;
new Handle:cvarHookBlue;
// Grab handles
new Handle:cvarGrabEnable;
new Handle:cvarGrabAdminOnly;
new Handle:cvarGrabSpeed;
new Handle:cvarGrabBeamColor;
new Handle:cvarGrabRed;
new Handle:cvarGrabGreen;
new Handle:cvarGrabBlue;
// Rope handles
new Handle:cvarRopeEnable;
new Handle:cvarRopeAdminOnly;
new Handle:cvarRopeNoFlag;
new Handle:cvarRopeSpeed;
new Handle:cvarRopeBeamColor;
new Handle:cvarRopeRed;
new Handle:cvarRopeGreen;
new Handle:cvarRopeBlue;
// Forward handles
new Handle:fwdOnGrab;
new Handle:fwdOnDrag;
new Handle:fwdOnDrop;
new Handle:fwdOnHook;
new Handle:fwdOnRope;

// Hook array
new Float:gHookEndloc[MAXPLAYERS+1][3];

// Grab arrays
new gTargetUserId[MAXPLAYERS+1];
new Float:gGrabDist[MAXPLAYERS+1];
new bool:gGrabbed[MAXPLAYERS+1];
new gGrabCounter[MAXPLAYERS+1];
//new Float:gMaxSpeed[MAXPLAYERS+1];
new Float:gGravity[MAXPLAYERS+1];

// Rope arrays
new Float:gRopeEndloc[MAXPLAYERS+1][3];
new Float:gRopeDist[MAXPLAYERS+1];

// Client status arrays
new bool:gStatus[MAXPLAYERS+1][NUM_ACTIONS];

// Clients that have access to hook, grab or rope
new bool:gAllowedClients[MAXPLAYERS+1][NUM_ACTIONS];
new Float:gAllowedRange[MAXPLAYERS+1][NUM_ACTIONS];
new Float:gCooldown[MAXPLAYERS+1][NUM_ACTIONS];
new Float:gLastUsed[MAXPLAYERS+1][NUM_ACTIONS];
new gAllowedDuration[MAXPLAYERS+1][NUM_ACTIONS];
new gFlags[MAXPLAYERS+1][NUM_ACTIONS];
new gRemainingDuration[MAXPLAYERS+1];

// Offset variables
new gGetVelocityOffset;

// Precache variables
new precache_laser = 0;

// Native interface settings
new bool:g_bIsTF2 = false;
new bool:g_bNativeOverride = false;
new g_iNativeHooks;
new g_iNativeGrabs;
new g_iNativeRopes;

// Sounds
new String:fireWav[PLATFORM_MAX_PATH]           = "weapons/crossbow/fire1.wav";
new String:hitWav[PLATFORM_MAX_PATH]            = "weapons/crossbow/hit1.wav";

//Use SourceCraft sounds if it is present
#tryinclude "../SourceCraft/sc/version"
#if defined SOURCECRAFT_VERSION
    new String:errorWav[PLATFORM_MAX_PATH]      = SC_ERROR_SOUND;
    new String:pullerWav[PLATFORM_MAX_PATH]     = SC_PULLER_SOUND;
    new String:deniedWav[PLATFORM_MAX_PATH]     = SC_DENIED_SOUND;
    new String:grabberHitWav[PLATFORM_MAX_PATH] = SC_GRABHIT_SOUND;
    new String:seekingWav[PLATFORM_MAX_PATH]    = SC_SEEKING_SOUND;
#else
    new String:errorWav[PLATFORM_MAX_PATH]      = ERROR_SOUND;
    new String:pullerWav[PLATFORM_MAX_PATH]     = PULLER_SOUND;
    new String:deniedWav[PLATFORM_MAX_PATH]     = DENIED_SOUND;
    new String:grabberHitWav[PLATFORM_MAX_PATH] = GRABHIT_SOUND;
    new String:seekingWav[PLATFORM_MAX_PATH]    = SEEKING_SOUND;
#endif

/**
 * Stocks to return information about TF2 player condition, etc.
 */
#tryinclude <tf2_player>
#if !defined _tf2_player_included

    #define TF2_IsPlayerTaunting(%1)            TF2_IsPlayerInCondition(%1,TFCond_Taunting)
    #define TF2_IsPlayerBonked(%1)              TF2_IsPlayerInCondition(%1,TFCond_Bonked)
    #define TF2_IsPlayerDazed(%1)               TF2_IsPlayerInCondition(%1,TFCond_Dazed)
    #define TF2_IsPlayerCharging(%1)            TF2_IsPlayerInCondition(%1,TFCond_Charging)
    #define TF2_IsPlayerCritCola(%1)            TF2_IsPlayerInCondition(%1,TFCond_CritCola)

    #define TF2_IsSlowed(%1)                    (((%1) & TF_CONDFLAG_SLOWED) != TF_CONDFLAG_NONE)
    #define TF2_IsZoomed(%1)                    (((%1) & TF_CONDFLAG_ZOOMED) != TF_CONDFLAG_NONE)
    #define TF2_IsDisguising(%1)                (((%1) & TF_CONDFLAG_DISGUISING) != TF_CONDFLAG_NONE)
    #define TF2_IsDisguised(%1)                 (((%1) & TF_CONDFLAG_DISGUISED) != TF_CONDFLAG_NONE)
    #define TF2_IsCloaked(%1)                   (((%1) & TF_CONDFLAG_CLOAKED) != TF_CONDFLAG_NONE)
    #define TF2_IsUbercharged(%1)               (((%1) & TF_CONDFLAG_UBERCHARGED) != TF_CONDFLAG_NONE)
    #define TF2_IsTeleportedGlow(%1)            (((%1) & TF_CONDFLAG_TELEPORTGLOW) != TF_CONDFLAG_NONE)
    #define TF2_IsTaunting(%1)                  (((%1) & TF_CONDFLAG_TAUNTING) != TF_CONDFLAG_NONE)
    #define TF2_IsUberchargeFading(%1)          (((%1) & TF_CONDFLAG_UBERCHARGEFADE) != TF_CONDFLAG_NONE)
    #define TF2_IsCloakFlicker(%1)              (((%1) & TF_CONDFLAG_CLOAKFLICKER) != TF_CONDFLAG_NONE)
    #define TF2_IsTeleporting(%1)               (((%1) & TF_CONDFLAG_TELEPORTING) != TF_CONDFLAG_NONE)
    #define TF2_IsKritzkrieged(%1)              (((%1) & TF_CONDFLAG_KRITZKRIEGED) != TF_CONDFLAG_NONE)
    #define TF2_IsDeadRingered(%1)              (((%1) & TF_CONDFLAG_DEADRINGERED) != TF_CONDFLAG_NONE)
    #define TF2_IsBonked(%1)                    (((%1) & TF_CONDFLAG_BONKED) != TF_CONDFLAG_NONE)
    #define TF2_IsDazed(%1)                     (((%1) & TF_CONDFLAG_DAZED) != TF_CONDFLAG_NONE)
    #define TF2_IsBuffed(%1)                    (((%1) & TF_CONDFLAG_BUFFED) != TF_CONDFLAG_NONE)
    #define TF2_IsCharging(%1)                  (((%1) & TF_CONDFLAG_CHARGING) != TF_CONDFLAG_NONE)
    #define TF2_IsDemoBuff(%1)                  (((%1) & TF_CONDFLAG_DEMOBUFF) != TF_CONDFLAG_NONE)
    #define TF2_IsCritCola(%1)                  (((%1) & TF_CONDFLAG_CRITCOLA) != TF_CONDFLAG_NONE)
    #define TF2_IsInHealRadius(%1)              (((%1) & TF_CONDFLAG_INHEALRADIUS) != TF_CONDFLAG_INHEALRADIUS)
    #define TF2_IsHealing(%1)                   (((%1) & TF_CONDFLAG_HEALING) != TF_CONDFLAG_NONE)
    #define TF2_IsOnFire(%1)                    (((%1) & TF_CONDFLAG_ONFIRE) != TF_CONDFLAG_NONE)
    #define TF2_IsOverhealed(%1)                (((%1) & TF_CONDFLAG_OVERHEALED) != TF_CONDFLAG_NONE)
    #define TF2_IsJarated(%1)                   (((%1) & TF_CONDFLAG_JARATED) != TF_CONDFLAG_NONE)
    #define TF2_IsBleeding(%1)                  (((%1) & TF_CONDFLAG_BLEEDING) != TF_CONDFLAG_NONE)
    #define TF2_IsDefenseBuffed(%1)             (((%1) & TF_CONDFLAG_DEFENSEBUFFED) != TF_CONDFLAG_NONE)
    #define TF2_IsMilked(%1)                    (((%1) & TF_CONDFLAG_MILKED) != TF_CONDFLAG_NONE)
    #define TF2_IsMegaHealed(%1)                (((%1) & TF_CONDFLAG_MEGAHEAL) != TF_CONDFLAG_MEGAHEAL)
    #define TF2_IsRegenBuffed(%1)               (((%1) & TF_CONDFLAG_REGENBUFFED) != TF_CONDFLAG_REGENBUFFED)
    #define TF2_IsMarkedForDeath(%1)            (((%1) & TF_CONDFLAG_MARKEDFORDEATH) != TF_CONDFLAG_MARKEDFORDEATH)

    #define TF_CONDFLAGEX_SPEEDBUFFALLY         (1 << (_:TFCond_SpeedBuffAlly-32))

    #define TF2_IsSpeedBuffAlly(%1)             (((%1) & TF_CONDFLAGEX_SPEEDBUFFALLY) != TF_CONDFLAGEX_SPEEDBUFFALLY)

    /**
     * Gets a player's lower 32 condition bits
     *
     * @param client		Player's index.
     * @return				Player's lower 32 condition bits
     */
    stock TF2_GetPlayerConditionLowBits(client)
    {
        return GetEntProp(client, Prop_Send, "m_nPlayerCond")|GetEntProp(client, Prop_Send, "_condition_bits");
    }

    /**
     * Gets a player's upper 32 condition bits
     *
     * @param client		Player's index.
     * @return				Player's upper 32 condition bits
     */
    stock TF2_GetPlayerConditionHighBits(client)
    {
        return GetEntProp(client, Prop_Send, "m_nPlayerCondEx");
    }

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

	stock bool:PrepareSound(const String:sound[], bool:force=false, bool:preload=true)
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

	stock PrepareAndEmitSoundToClient(client,
					 const String:sample[],
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
		    EmitSoundToClient(client, sample, entity, channel,
				              level, flags, volume, pitch, speakerentity,
				              origin, dir, updatePos, soundtime);
	    }
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

    stock SetupModel(const String:model[], &index=0, bool:download=false,
                     bool:precache=false, bool:preload=false)
    {
        if (download && FileExists(model))
            AddFileToDownloadsTable(model);

        if (precache)
            index = PrecacheModel(model,preload);
        else
            index = 0;
    }

    stock PrepareModel(const String:model[], &index=0, bool:preload=true)
    {
        if (index <= 0)
            index = PrecacheModel(model,preload);

        return index;
    }
#endif

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Natives
    CreateNative("ControlHookGrabRope",Native_ControlHookGrabRope);

    CreateNative("GiveHook",Native_GiveHook);
    CreateNative("TakeHook",Native_TakeHook);

    CreateNative("GiveGrab",Native_GiveGrab);
    CreateNative("TakeGrab",Native_TakeGrab);

    CreateNative("GiveRope",Native_GiveRope);
    CreateNative("TakeRope",Native_TakeRope);

    CreateNative("Hook",Native_Hook);
    CreateNative("UnHook",Native_UnHook);
    CreateNative("HookToggle",Native_HookToggle);

    CreateNative("Grab",Native_Grab);
    CreateNative("Drop",Native_Drop);
    CreateNative("GrabToggle",Native_GrabToggle);

    CreateNative("Rope",Native_Rope);
    CreateNative("Detach",Native_Detach);
    CreateNative("RopeToggle",Native_RopeToggle);

    CreateNative("HGRState",Native_HGRState);
    CreateNative("IsGrabbed",Native_IsGrabbed);
    CreateNative("GrabTarget",Native_GrabTarget);

    fwdOnGrab=CreateGlobalForward("OnGrabPlayer",ET_Hook,Param_Cell,Param_Cell);
    fwdOnDrag=CreateGlobalForward("OnDragPlayer",ET_Hook,Param_Cell,Param_Cell);
    fwdOnDrop=CreateGlobalForward("OnDropPlayer",ET_Ignore,Param_Cell,Param_Cell);
    fwdOnHook=CreateGlobalForward("OnHook",ET_Hook,Param_Cell);
    fwdOnRope=CreateGlobalForward("OnRope",ET_Hook,Param_Cell);

    RegPluginLibrary("hgrsource");
    return APLRes_Success;
}

public OnPluginStart()
{
    PrintToServer("----------------|         HGR:Source Loading        |---------------");

    // Hook events
    HookEvent("player_spawn",PlayerSpawnEvent);

    // Register client cmds
    RegConsoleCmd("+hook",HookCmd);
    RegConsoleCmd("-hook",UnHookCmd);
    RegConsoleCmd("hook_toggle",HookToggle);

    RegConsoleCmd("+grab",GrabCmd);
    RegConsoleCmd("-grab",DropCmd);
    RegConsoleCmd("grab_toggle",GrabToggle);

    RegConsoleCmd("+rope",RopeCmd);
    RegConsoleCmd("-rope",DetachCmd);
    RegConsoleCmd("rope_toggle",RopeToggle);

    // Register admin cmds
    RegAdminCmd("hgrsource_givehook",GiveHook,ADMFLAG_GENERIC);
    RegAdminCmd("hgrsource_takehook",TakeHook,ADMFLAG_GENERIC);
    RegAdminCmd("hgrsource_givegrab",GiveGrab,ADMFLAG_GENERIC);
    RegAdminCmd("hgrsource_takegrab",TakeGrab,ADMFLAG_GENERIC);
    RegAdminCmd("hgrsource_giverope",GiveRope,ADMFLAG_GENERIC);
    RegAdminCmd("hgrsource_takerope",TakeRope,ADMFLAG_GENERIC);

    // Find offsets
    gGetVelocityOffset=FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    if(gGetVelocityOffset==-1)
        SetFailState("[HGR:Source] Error: Failed to find the GetVelocity offset, aborting");

    // General cvars
    cvarAnnounce=CreateConVar("hgrsource_announce","0","This will enable announcements that the plugin is loaded");

    // Sound cvars
    cvarGrabHitSound = CreateConVar("hgrsource_grab_sound", grabberHitWav, "sound when grab hits", FCVAR_PLUGIN);
    cvarSeekingSound = CreateConVar("hgrsource_seeking_sound", seekingWav, "sound when grab is seeking a target", FCVAR_PLUGIN);
    cvarPullSound = CreateConVar("hgrsource_pull_sound", pullerWav, "sound when grab pulls", FCVAR_PLUGIN);
    cvarDeniedSound = CreateConVar("hgrsource_denied_sound", deniedWav, "access denied sound", FCVAR_PLUGIN);
    cvarErrorSound = CreateConVar("hgrsource_error_sound", errorWav, "error sound", FCVAR_PLUGIN);
    cvarFireSound = CreateConVar("hgrsource_fire_sound", fireWav, "sound when hook or rope or grab is fired", FCVAR_PLUGIN);
    cvarHitSound = CreateConVar("hgrsource_hit_sound", hitWav, "sound when hook or rope hits", FCVAR_PLUGIN);

    // Hook cvars
    cvarHookEnable=CreateConVar("hgrsource_hook_enable","0","This will enable the hook feature of this plugin");
    cvarHookAdminOnly=CreateConVar("hgrsource_hook_adminonly","0","If 1, only admins can use hook");
    cvarHookSpeed=CreateConVar("hgrsource_hook_speed","5.0","The speed of the player using hook");
    cvarHookBeamColor=CreateConVar("hgrsource_hook_color","1","The color of the hook, 0=White, 1=Team color, 2=custom");
    cvarHookRed=CreateConVar("hgrsource_hook_red","255","The red component of the beam (Only if you are using a custom color)");
    cvarHookGreen=CreateConVar("hgrsource_hook_green","0","The green component of the beam (Only if you are using a custom color)");
    cvarHookBlue=CreateConVar("hgrsource_hook_blue","0","The blue component of the beam (Only if you are using a custom color)");

    // Grab cvars
    cvarGrabEnable=CreateConVar("hgrsource_grab_enable","0","This will enable the grab feature of this plugin");
    cvarGrabAdminOnly=CreateConVar("hgrsource_grab_adminonly","0","If 1, only admins can use grab");
    cvarGrabSpeed=CreateConVar("hgrsource_grab_speed","5.0","The speed of the grabbers target");
    cvarGrabBeamColor=CreateConVar("hgrsource_grab_color","1","The color of the grab beam, 0=White, 1=Team color, 2=custom");
    cvarGrabRed=CreateConVar("hgrsource_grab_red","0","The red component of the beam (Only if you are using a custom color)");
    cvarGrabGreen=CreateConVar("hgrsource_grab_green","0","The green component of the beam (Only if you are using a custom color)");
    cvarGrabBlue=CreateConVar("hgrsource_grab_blue","255","The blue component of the beam (Only if you are using a custom color)");

    // Rope cvars
    cvarRopeEnable=CreateConVar("hgrsource_rope_enable","0","This will enable the rope feature of this plugin");
    cvarRopeAdminOnly=CreateConVar("hgrsource_rope_adminonly","0","If 1, only admins can use rope");
    cvarRopeSpeed=CreateConVar("hgrsource_rope_speed","3.0","The speed of the player using rope");
    cvarRopeBeamColor=CreateConVar("hgrsource_rope_color","1","The color of the rope, 0=White, 1=Team color, 2=custom");
    cvarRopeRed=CreateConVar("hgrsource_rope_red","0","The red component of the beam (Only if you are using a custom color)");
    cvarRopeGreen=CreateConVar("hgrsource_rope_green","255","The green component of the beam (Only if you are using a custom color)");
    cvarRopeBlue=CreateConVar("hgrsource_rope_blue","0","The blue component of the beam (Only if you are using a custom color)");

    // Disable noflag if the game isn't TF2.
    decl String:modname[30];
    GetGameFolderName(modname, sizeof(modname));

    g_bIsTF2 = StrEqual(modname,"tf",false);
    if (g_bIsTF2) 
    {
        cvarHookNoFlag = CreateConVar("hgrsource_hook_noflag", "1", "When enabled, prevents TF2 flag carrier from using the hook");
        cvarRopeNoFlag = CreateConVar("hgrsource_rope_noflag", "1", "When enabled, prevents TF2 flag carrier from using the rope");
    }

    // Auto-generate config
    AutoExecConfig();

    // Public cvar
    CreateConVar("hgrsource_version",VERSION,"[HGR:Source] Current version of this plugin",
                 FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

    PrintToServer("----------------|         HGR:Source Loaded         |---------------");
}

public OnMapStart()
{
    // Precache models
    SetupModel(LASER_MODEL, precache_laser);
}

public OnConfigsExecuted()
{
    // Precache & download sounds

    GetConVarString(cvarDeniedSound, deniedWav, sizeof(deniedWav));
    if (!deniedWav[0])
        strcopy(deniedWav, sizeof(deniedWav), DENIED_SOUND);

    SetupSound(deniedWav,true);

    GetConVarString(cvarErrorSound, errorWav, sizeof(errorWav));
    if (!errorWav[0])
        strcopy(errorWav, sizeof(errorWav), ERROR_SOUND);

    SetupSound(errorWav,true);

    GetConVarString(cvarGrabHitSound, grabberHitWav, sizeof(grabberHitWav));
    if (grabberHitWav[0])
        SetupSound(grabberHitWav,true);

    GetConVarString(cvarFireSound, fireWav, sizeof(fireWav));
    if (fireWav[0])
        SetupSound(fireWav,true);

    GetConVarString(cvarHitSound, hitWav, sizeof(hitWav));
    if (hitWav[0])
        SetupSound(hitWav,true);

    GetConVarString(cvarSeekingSound, seekingWav, sizeof(seekingWav));
    if (seekingWav[0])
        SetupSound(seekingWav,true, AUTO_DOWNLOAD, true, true);

    GetConVarString(cvarPullSound, pullerWav, sizeof(pullerWav));
    if (pullerWav[0])
        SetupSound(pullerWav,true, AUTO_DOWNLOAD, true, true);
}

public OnClientDisconnect(client)
{
    if (client>0 && !IsFakeClient(client))
    {
        if (gStatus[client][ACTION_HOOK])
            Action_UnHook(client);
        else if (gStatus[client][ACTION_ROPE])
            Action_Detach(client);
        else if (gStatus[client][ACTION_GRAB])
            Action_Drop(client);
        else if (gGrabbed[client])
        {
            for(new x=0;x<=MAXPLAYERS;x++)
            {
                if (gTargetUserId[x] == GetClientUserId(client))
                {
                    Action_Drop(client);
                    break;
                }
            }
        }

    }
}

/********
 *Events*
 *********/

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new index=GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index
    // Tell plugin they aren't using any of its features
    gStatus[index][ACTION_HOOK]=false;
    gStatus[index][ACTION_GRAB]=false;
    gStatus[index][ACTION_ROPE]=false;
    gLastUsed[index][ACTION_HOOK]=0.0;
    gLastUsed[index][ACTION_GRAB]=0.0;
    gLastUsed[index][ACTION_ROPE]=0.0;
    if (GetConVarBool(cvarAnnounce))
    {
        PrintToChat(index,"%c[HGR:Source] %cIs enabled, valid commands are: [%c+hook%c] [%c+grab%c] [%c+rope%c]",
                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
    }
}

/*********
 *Natives*
 **********/

public Native_ControlHookGrabRope(Handle:plugin,numParams)
{
    if (numParams >= 1)
        g_bNativeOverride = GetNativeCell(1);
    else
        g_bNativeOverride = true;
}

public Native_Hook(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (IsClientInGame(client) && IsPlayerAlive(client))
            Action_Hook(client);
    }
}

public Native_UnHook(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (IsClientInGame(client) && IsPlayerAlive(client))
            Action_UnHook(client);
    }
}

public Native_HookToggle(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            if (gStatus[client][ACTION_HOOK])
                Action_UnHook(client);
            else
                Action_Hook(client);
        }
    }
}

public Native_Grab(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (IsClientInGame(client) && IsPlayerAlive(client))
            Action_Grab(client);
    }
}

public Native_Drop(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (IsClientInGame(client) && IsPlayerAlive(client))
            Action_Drop(client);
    }
}

public Native_GrabToggle(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            if (gStatus[client][ACTION_GRAB])
                Action_Drop(client);
            else
                Action_Grab(client);
        }
    }
}

public Native_Rope(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (IsClientInGame(client) && IsPlayerAlive(client))
            Action_Rope(client);
    }
}

public Native_Detach(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (IsClientInGame(client) && IsPlayerAlive(client))
            Action_Detach(client);
    }
}

public Native_RopeToggle(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            if (gStatus[client][ACTION_ROPE])
                Action_Detach(client);
            else
                Action_Rope(client);
        }
    }
}

public Native_GiveHook(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        new duration = (numParams >= 2) ? GetNativeCell(2) : 0;
        new Float:range = (numParams >= 3) ? (Float:GetNativeCell(3)) : 0.0;
        new Float:cooldown = (numParams >= 4) ? (Float:GetNativeCell(4)) : 0.0;
        new flags = (numParams >= 5) ? GetNativeCell(5) : 0;
        if (!ClientAccess(client,Give,Hook,duration,range,cooldown,flags))
            g_iNativeHooks++;
    }
}

public Native_TakeHook(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (ClientAccess(client,Take,Hook,0,0.0,0.0,0))
        {
            g_iNativeHooks--;
            if (g_iNativeHooks <= 0)
            {
                g_iNativeHooks = 0;
                Action_UnHook(client);
            }
        }
    }
}

public Native_GiveGrab(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        new duration = (numParams >= 2) ? GetNativeCell(2) : 0;
        new Float:range = (numParams >= 3) ? (Float:GetNativeCell(3)) : 0.0;
        new Float:cooldown = (numParams >= 4) ? (Float:GetNativeCell(4)) : 0.0;
        new flags = (numParams >= 5) ? GetNativeCell(5) : 0;
        if (!ClientAccess(client,Give,Grab,duration,range,cooldown,flags))
            g_iNativeGrabs++;
    }
}

public Native_TakeGrab(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (ClientAccess(client,Take,Grab,0,0.0,0.0,0))
        {
            g_iNativeGrabs--;
            if (g_iNativeGrabs <= 0)
            {
                g_iNativeGrabs = 0;
                Action_Drop(client);
            }
        }
    }
}

public Native_GiveRope(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        new duration = (numParams >= 2) ? GetNativeCell(2) : 0;
        new Float:range= (numParams >= 3) ? (Float:GetNativeCell(3)) : 0.0;
        new Float:cooldown = (numParams >= 4) ? (Float:GetNativeCell(4)) : 0.0;
        new flags = (numParams >= 5) ? GetNativeCell(5) : 0;
        if (!ClientAccess(client,Give,Rope,duration,range,cooldown,flags))
            g_iNativeRopes++;
    }
}

public Native_TakeRope(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (ClientAccess(client,Take,Rope,0,0.0,0.0,0))
        {
            g_iNativeRopes--;
            if (g_iNativeRopes <= 0)
            {
                g_iNativeRopes = 0;
                Action_Detach(client);
            }
        }
    }
}

public Native_HGRState(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        new action = GetNativeCell(2);
        return gStatus[client][action];
    }
    return false;
}

public Native_IsGrabbed(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        return gGrabbed[client];
    }
    return false;
}

public Native_GrabTarget(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        return GetClientOfUserId(gTargetUserId[client]);
    }
    return -1;
}

/******
 *Cmds*
 *******/

public Action:HookCmd(client,argc)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
        Action_Hook(client);
    return Plugin_Handled;
}

public Action:UnHookCmd(client,argc)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
        Action_UnHook(client);
    return Plugin_Handled;
}

public Action:HookToggle(client,argc)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
    {
        if (gStatus[client][ACTION_HOOK])
            Action_UnHook(client);
        else
            Action_Hook(client);
    }
    return Plugin_Handled;
}

public Action:GrabCmd(client,argc)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
        Action_Grab(client);
    return Plugin_Handled;
}

public Action:DropCmd(client,argc)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
        Action_Drop(client);
    return Plugin_Handled;
}

public Action:GrabToggle(client,argc)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
    {
        if (gStatus[client][ACTION_GRAB])
            Action_Drop(client);
        else
            Action_Grab(client);
    }
    return Plugin_Handled;
}

public Action:RopeCmd(client,argc)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
        Action_Rope(client);
    return Plugin_Handled;
}

public Action:DetachCmd(client,argc)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
        Action_Detach(client);
    return Plugin_Handled;
}

public Action:RopeToggle(client,argc)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
    {
        if (gStatus[client][ACTION_ROPE])
            Action_Detach(client);
        else
            Action_Rope(client);
    }
    return Plugin_Handled;
}

/*******
 *Admin*
 ********/

public Action:GiveHook(client,argc)
{
    if(argc>=1)
    {
        if(!g_bNativeOverride && IsFeatureEnabled(Hook) && IsFeatureAdminOnly(Hook))
        {
            decl String:target[64];
            GetCmdArg(1,target,sizeof(target));
            new count=Access(target,Give,Hook);
            if(!count)
                ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",
                               COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
        }
    }
    else
        ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_givehook <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
    return Plugin_Handled;
}

public Action:TakeHook(client,argc)
{
    if(argc>=1)
    {
        if(!g_bNativeOverride && IsFeatureEnabled(Hook) && IsFeatureAdminOnly(Hook))
        {
            decl String:target[64];
            GetCmdArg(1,target,sizeof(target));
            new count=Access(target,Take,Hook);
            if(!count)
                ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",
                               COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
        }
    }
    else
        ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_takehook <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
    return Plugin_Handled;
}

public Action:GiveGrab(client,argc)
{
    if(argc>=1)
    {
        if(!g_bNativeOverride && IsFeatureEnabled(Grab) && IsFeatureAdminOnly(Grab))
        {
            decl String:target[64];
            GetCmdArg(1,target,sizeof(target));
            new count=Access(target,Give,Grab);
            if(!count)
                ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",
                               COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
        }
    }
    else
        ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_givegrab <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
    return Plugin_Handled;
}

public Action:TakeGrab(client,argc)
{
    if(argc>=1)
    {
        if(!g_bNativeOverride && IsFeatureEnabled(Grab) && IsFeatureAdminOnly(Grab))
        {
            decl String:target[64];
            GetCmdArg(1,target,sizeof(target));
            new count=Access(target,Take,Grab);
            if(!count)
                ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",
                               COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
        }
    }
    else
        ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_takegrab <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
    return Plugin_Handled;
}

public Action:GiveRope(client,argc)
{
    if(argc>=1)
    {
        if(!g_bNativeOverride && IsFeatureEnabled(Rope) && IsFeatureAdminOnly(Rope))
        {
            decl String:target[64];
            GetCmdArg(1,target,sizeof(target));
            new count=Access(target,Give,Rope);
            if(!count)
                ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",
                               COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
        }
    }
    else
        ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_giverope <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
    return Plugin_Handled;
}

public Action:TakeRope(client,argc)
{
    if(argc>=1)
    {
        if(!g_bNativeOverride && IsFeatureEnabled(Rope) && IsFeatureAdminOnly(Rope))
        {
            decl String:target[64];
            GetCmdArg(1,target,sizeof(target));
            new count=Access(target,Take,Rope);
            if(!count)
                ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",
                               COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
        }
    }
    else
        ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_takerope <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
    return Plugin_Handled;
}

/********
 *Access*
 *********/

Access(const String:target[],HGRSourceAccess:access,HGRSourceAction:action)
{
    new clients[MAXPLAYERS];
    new count=FindMatchingPlayers(target,clients);
    if(count==0)
        return 0;
    for(new x=0;x<count;x++)
        ClientAccess(clients[x],access,action,0,0.0,0.0,0);
    return count;
}

bool:ClientAccess(client,HGRSourceAccess:access,HGRSourceAction:action,duration,Float:range,Float:cooldown,flags)
{
    new bool:prevState = false;
    if(access==Give)
    {
        if(action==Hook)
        {
            prevState = gAllowedClients[client][ACTION_HOOK];
            gAllowedClients[client][ACTION_HOOK]=true;
            gAllowedDuration[client][ACTION_HOOK]=duration;
            gAllowedRange[client][ACTION_HOOK]=range;
            gCooldown[client][ACTION_HOOK]=cooldown;
            gFlags[client][ACTION_HOOK]=flags;
        }
        else if(action==Grab)
        {
            prevState = gAllowedClients[client][ACTION_GRAB];
            gAllowedClients[client][ACTION_GRAB]=true;
            gAllowedDuration[client][ACTION_GRAB]=duration;
            gAllowedRange[client][ACTION_GRAB]=range;
            gCooldown[client][ACTION_GRAB]=cooldown;
            gFlags[client][ACTION_GRAB]=flags;
        }
        else if(action==Rope)
        {
            prevState = gAllowedClients[client][ACTION_ROPE];
            gAllowedClients[client][ACTION_ROPE]=true;
            gAllowedDuration[client][ACTION_ROPE]=duration;
            gAllowedRange[client][ACTION_ROPE]=range;
            gCooldown[client][ACTION_ROPE]=cooldown;
            gFlags[client][ACTION_ROPE]=flags;
        }
    }
    else if(access==Take)
    {
        if(action==Hook)
        {
            prevState = gAllowedClients[client][ACTION_HOOK];
            gAllowedClients[client][ACTION_HOOK]=false;
        }
        else if(action==Grab)
        {
            prevState = gAllowedClients[client][ACTION_GRAB];
            gAllowedClients[client][ACTION_GRAB]=false;
        }
        else if(action==Rope)
        {
            prevState = gAllowedClients[client][ACTION_ROPE];
            gAllowedClients[client][ACTION_ROPE]=false;
        }
    }
    return prevState;
}

bool:HasAccess(client,HGRSourceAction:action)
{
    if (!g_bNativeOverride)
    {
        if(GetAdminFlag(GetUserAdmin(client),Admin_Generic,Access_Real)||
           GetAdminFlag(GetUserAdmin(client),Admin_Generic,Access_Effective)||
           GetAdminFlag(GetUserAdmin(client),Admin_Root,Access_Real)||
           GetAdminFlag(GetUserAdmin(client),Admin_Root,Access_Effective))
            return true;
        else if(!IsFeatureEnabled(action))
            return false;
        else if(!IsFeatureAdminOnly(action))
            return true;
    }

    if(action==Hook)
        return gAllowedClients[client][ACTION_HOOK];
    else if(action==Grab)
        return gAllowedClients[client][ACTION_GRAB];
    else if(action==Rope)
        return gAllowedClients[client][ACTION_ROPE];

    return false;
}

/******
 *CVar*
 *******/

bool:IsFeatureEnabled(HGRSourceAction:action)
{
    if (g_bNativeOverride)
        return true;
    if(action==Hook)
        return (g_iNativeHooks > 0) || GetConVarBool(cvarHookEnable);
    if(action==Grab)
        return (g_iNativeGrabs > 0) || GetConVarBool(cvarGrabEnable);
    if(action==Rope)
        return (g_iNativeRopes > 0) || GetConVarBool(cvarRopeEnable);
    return false;
}

bool:IsFeatureAdminOnly(HGRSourceAction:action)
{
    if (g_bNativeOverride)
        return false;
    if(action==Hook)
        return GetConVarBool(cvarHookAdminOnly);
    if(action==Grab)
        return GetConVarBool(cvarGrabAdminOnly);
    if(action==Rope)
        return GetConVarBool(cvarRopeAdminOnly);
    return false;
}

GetBeamColor(client,HGRSourceAction:action,color[4])
{
    new beamtype=0;
    new red=255;
    new green=255;
    new blue=255;
    if(action==Hook)
    {
        beamtype=GetConVarInt(cvarHookBeamColor);
        if(beamtype==2)
        {
            red=GetConVarInt(cvarHookRed);
            green=GetConVarInt(cvarHookGreen);
            blue=GetConVarInt(cvarHookBlue);
        }
    }
    else if(action==Grab)
    {
        beamtype=GetConVarInt(cvarGrabBeamColor);
        if(beamtype==2)
        {
            red=GetConVarInt(cvarGrabRed);
            green=GetConVarInt(cvarGrabGreen);
            blue=GetConVarInt(cvarGrabBlue);
        }
    }
    else if(action==Rope)
    {
        beamtype=GetConVarInt(cvarRopeBeamColor);
        if(beamtype==2)
        {
            red=GetConVarInt(cvarRopeRed);
            green=GetConVarInt(cvarRopeGreen);
            blue=GetConVarInt(cvarRopeBlue);
        }
    }
    if(beamtype==0)
    {
        color[0]=255;color[1]=255;color[2]=255;color[3]=255;
    }
    else if(beamtype==1)
    {
        if(GetClientTeam(client)==2)
        {
            color[0]=255;color[1]=0;color[2]=0;color[3]=255;
        }
        else if(GetClientTeam(client)==3)
        {
            color[0]=0;color[1]=0;color[2]=255;color[3]=255;
        }
    }
    else if(beamtype==2)
    {
        color[0]=red;color[1]=green;color[2]=blue;color[3]=255;
    }
}

/******
 *Hook*
 *******/

Action_Hook(client)
{
    if (g_bNativeOverride || GetConVarBool(cvarHookEnable))
    {
        if (client>0)
        {
            if (!gGrabbed[client] && !gStatus[client][ACTION_HOOK] &&
                IsClientInGame(client) && IsPlayerAlive(client))
            {
                if (HasAccess(client,Hook))
                {
                    if (g_bIsTF2 && GetConVarBool(cvarHookNoFlag) && TF2_HasTheFlag(client))
                    {
                        PrepareAndEmitSoundToClient(client,errorWav);
                        PrintToChat(client,"%c[HGR:Source] %cYou can not use the %chook%c while carrying the flag!",
                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                    }
                    else
                    {
                        new Float:cooldown = gCooldown[client][ACTION_HOOK];
                        new Float:lastUsed = gLastUsed[client][ACTION_HOOK];
                        if (cooldown <= 0.0 || lastUsed <= 0.0 ||
                            ((GetGameTime() - lastUsed) >= cooldown))
                        {
                            if (fireWav[0])
                                PrepareAndEmitSoundToAll(fireWav, client); // Emit fire sound

                            new Float:clientloc[3],Float:clientang[3];
                            GetClientEyePosition(client,clientloc); // Get the position of the player's eyes
                            GetClientEyeAngles(client,clientang); // Get the angle the player is looking

                            // Create a ray that tells where the player is looking
                            new Handle:hTrace = TR_TraceRayFilterEx(clientloc,clientang,MASK_SOLID,RayType_Infinite,TraceRayTryToHit);
                            TR_GetEndPosition(gHookEndloc[client], hTrace); // Get the end xyz coordinate of where a player is looking
                            CloseHandle(hTrace);

                            new Float:limit=gAllowedRange[client][ACTION_GRAB];
                            new Float:distance=GetVectorDistance(clientloc,gHookEndloc[client]);
                            if (limit == 0.0 || distance <= limit)
                            {
                                if (gRemainingDuration[client] <= 0)
                                    gRemainingDuration[client] = gAllowedDuration[client][ACTION_HOOK];

                                // Tell plugin the player is hooking
                                gStatus[client][ACTION_HOOK]=true;

                                // Save client's old gravity
                                gGravity[client] = GetEntPropFloat(client,Prop_Data,"m_flGravity");

                                // Set gravity to 0 so client floats in a straight line
                                SetEntPropFloat(client,Prop_Data,"m_flGravity",0.0);

                                Hook_Push(client);

                                // Emit sound from where the hook landed
                                if (hitWav[0] && PrepareSound(hitWav, true, true))
                                    EmitSoundFromOrigin(hitWav, gHookEndloc[client]);

                                // Create hooking loop
                                CreateTimer(0.1, Hooking, GetClientUserId(client),
                                            TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
                            }
                            else
                            {
                                PrepareAndEmitSoundToClient(client,errorWav);
                                PrintToChat(client,"%c[HGR:Source] %cTarget is too far away!",
                                        COLOR_GREEN,COLOR_DEFAULT);
                            }
                        }
                        else
                        {
                            PrepareAndEmitSoundToClient(client,errorWav);
                            PrintToChat(client,"%c[HGR:Source] %cYou have used the %chook%c too recently!",
                                        COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                        }
                    }
                }
                else if (g_bNativeOverride)
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[HGR:Source] %cYou don't have a %chook%c",
                                COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
                else
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[HGR:Source] %cYou don't have permission to use the %chook%c",
                                COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
            }
        }
        else
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            PrintToChat(client,"%c[HGR:Source] %cERROR: Please notify server administrator",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    else
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        PrintToChat(client,"%c[HGR:Source] Hook %cis currently disabled",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
}

Hook_Push(client)
{
    new Float:clientloc[3],Float:velocity[3];
    GetClientAbsOrigin(client,clientloc); // Get the xyz coordinate of the player
    clientloc[2]+=30.0;

    new color[4];
    GetBeamColor(client,Hook,color);
    BeamEffect(clientloc,gHookEndloc[client],0.2,5.0,5.0,color,0.0,0);

    GetForwardPushVec(clientloc,gHookEndloc[client],velocity); // Get how hard and where to push the client

    // Push the client
    TeleportEntity(client,NULL_VECTOR,NULL_VECTOR,velocity);

    new Float:distance=GetVectorDistance(clientloc,gHookEndloc[client]);
    if (distance<30.0)
    {
        SetEntityMoveType(client,MOVETYPE_NONE); // Freeze client

        new Float:gravity = gGravity[client]; // Set gravity back to saved value (or normal)
        SetEntPropFloat(client,Prop_Data,"m_flGravity",(gravity != 0.0) ? gravity : 1.0);
    }
}

public Action:Hooking(Handle:timer,any:userid)
{
    new index = GetClientOfUserId(userid);
    if (index > 0)
    {
        if (gStatus[index][ACTION_HOOK] && !gGrabbed[index] &&
            IsClientInGame(index) && IsPlayerAlive(index) &&
            !(g_bIsTF2 && TF2_HasTheFlag(index)))
        {
            if (gRemainingDuration[index] > 0)
            {
                gRemainingDuration[index]--;
                if (gRemainingDuration[index] <= 0)
                {
                    Action_UnHook(index);
                    return Plugin_Stop;
                }
            }

            new Action:res = Plugin_Continue;
            Call_StartForward(fwdOnHook);
            Call_PushCell(index);
            Call_Finish(res);
            if (res == Plugin_Stop)
            {
                Action_UnHook(index);
                return Plugin_Stop;
            }

            Hook_Push(index);
        }
        else
        {
            Action_UnHook(index);
            return Plugin_Stop;
        }
    }
    return Plugin_Handled;
}

Action_UnHook(client)
{
    if (gStatus[client][ACTION_HOOK])
    {
        gStatus[client][ACTION_HOOK]=false; // Tell plugin the client is not hooking
        gLastUsed[client][ACTION_HOOK]=GetGameTime(); // Tell plugin when client stopped hooking
    }

    if (IsClientInGame(client))
    {
        new Float:gravity = gGravity[client]; // Set gravity back to saved value (or normal)
        SetEntPropFloat(client,Prop_Data,"m_flGravity",(gravity != 0.0) ? gravity : 1.0);
        SetEntityMoveType(client,MOVETYPE_WALK); // Unfreeze client
    }
}

/******
 *Grab*
 *******/

Action_Grab(client)
{
    SetTraceCategory("Grab");
    TraceInto("hgrsource", "Action_Grab", "client=%d:%N", \
              client, ValidClientIndex(client));

    if (g_bNativeOverride || GetConVarBool(cvarGrabEnable))
    {
        if (client>0)
        {
            if (!gGrabbed[client] &&
                !gStatus[client][ACTION_GRAB] &&
                IsClientInGame(client) &&
                IsPlayerAlive(client))
            {
                if (HasAccess(client,Grab))
                {
                    new Float:cooldown = gCooldown[client][ACTION_GRAB];
                    new Float:lastUsed = gLastUsed[client][ACTION_GRAB];
                    if (cooldown <= 0.0 || lastUsed <= 0.0 ||
                        ((GetGameTime() - lastUsed) >= cooldown))
                    {
                        if (fireWav[0])
                            PrepareAndEmitSoundToAll(fireWav, client);

                        // Tell plugin the seeker is grabbing a player
                        gStatus[client][ACTION_GRAB]=true;

                        Trace("%d:%N has started using the grabber", client, client);

                        // Prepare sounds used in GrabSearch()
                        if (grabberHitWav[0])
                            PrepareSound(grabberHitWav, true, true);

                        if (seekingWav[0])
                            PrepareSound(seekingWav, true, true);

                        if (errorWav[0])
                            PrepareSound(errorWav, true, true);

                        // Start a timer that searches for a client to grab
                        CreateTimer(0.1, GrabSearch, GetClientUserId(client),
                                    TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
                    }
                    else
                    {
                        PrepareAndEmitSoundToClient(client,errorWav);
                        PrintToChat(client,"%c[HGR:Source] %cYou have used the %cgrabber%c too recently!",
                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                    }
                }
                else if (g_bNativeOverride)
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[HGR:Source] %cYou don't have a %cgrabber%c",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
                else
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[HGR:Source] %cYou don't have permission to use the %cgrabber%c",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
            }
            else
            {
                PrepareAndEmitSoundToClient(client,deniedWav);
            }
        }
        else
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            PrintToChat(client,"%c[HGR:Source] %cERROR: Please notify server administrator",
                    COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    else
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        PrintToChat(client,"%c[HGR:Source] Grab %cis currently disabled",
                COLOR_GREEN,COLOR_DEFAULT);
    }

    TraceReturn();
}

public Action:GrabSearch(Handle:timer,any:userid)
{
    new index = GetClientOfUserId(userid);

    SetTraceCategory("Grab");
    TraceInto("hgrsource", "GrabSearch", "userid=%d, index=%d:%N", \
              userid, index, ValidClientIndex(index));

    if (index > 0)
    {
        if (!gGrabbed[index] && gStatus[index][ACTION_GRAB] &&
            IsClientInGame(index) && IsPlayerAlive(index))
        {
            // Tell client the plugin is searching for a target
            PrintCenterText(index,"Searching for a target...");
            Trace("%d:%N is searching for a target", index, index);

            decl Float:clientloc[3],Float:clientang[3];
            GetClientEyePosition(index,clientloc); // Get seekers eye coordinate
            GetClientEyeAngles(index,clientang); // Get angle of where the player is looking

            // Create a ray that tells where the player is looking
            new Handle:hTrace = TR_TraceRayFilterEx(clientloc,clientang,MASK_ALL,RayType_Infinite,TraceRayGrabEnt);
            new target = TR_GetEntityIndex(hTrace); // Set the seekers targetindex to the person he picked up

            if (target > 0 && target <= MaxClients && IsClientInGame(target))
            {
                // Found something
                decl String:name[32];
                new bool:bValid = (GetEntityNetClass(target,name,sizeof(name)) &&
                                   StrContains(name, "Player") >= 0);
                if (bValid)
                {
                    // Found a player
                    if (g_bIsTF2)
                    {
                        #if defined _TRACE
                            //                        00000000001111111111222222222233333333334
                            //                        01234567890123456789012345678901234567890
                            new String:condFlags[] = "                                        ";
                            new pcond = TF2_GetPlayerConditionLowBits(client);
                            new pcond2 = TF2_GetPlayerConditionHighBits(client);
                            if (TF2_IsPlayerSlowed(client))
                                condFlags[0]  = 'S';
                            if (TF2_IsPlayerZoomed(client))
                                condFlags[1]  = 'Z';
                            if (TF2_IsPlayerDisguising(client))
                                condFlags[2]  = 'd';
                            if (TF2_IsPlayerDisguised(client))
                                condFlags[3]  = 'D';
                            if (TF2_IsPlayerCloaked(client))
                                condFlags[4]  = 'C';
                            if (TF2_IsPlayerUbercharged(client))
                                condFlags[5]  = 'U';
                            if (TF2_IsPlayerTeleportedGlow(client))
                                condFlags[6]  = 'g';
                            if (TF2_IsPlayerTaunting(client))
                                condFlags[7]  = 'T';
                            if (TF2_IsPlayerUberchargeFading(client))
                                condFlags[8]  = 'f';
                            if (TF2_IsPlayerCloakFlicker(client))
                                condFlags[9]  = 'c';
                            if (TF2_IsPlayerTeleporting(client))
                                condFlags[10] = 'p';
                            if (TF2_IsPlayerKritzkrieged(client))
                                condFlags[11] = 'K';
                            if (TF2_IsPlayerTmpDamageBonus(client))
                                condFlags[12] = '2';
                            if (TF2_IsPlayerDeadRingered(client))
                                condFlags[13] = 'R';
                            if (TF2_IsPlayerBonked(client))
                                condFlags[14] = 'b';
                            if (TF2_IsPlayerDazed(client))
                                condFlags[15] = 'A';
                            if (TF2_IsPlayerBuffed(client))
                                condFlags[16] = 'B';
                            if (TF2_IsPlayerCharging(client))
                                condFlags[17] = '-';
                            if (TF2_IsPlayerDemoBuff(client))
                                condFlags[18] = '>';
                            if (TF2_IsPlayerCritCola(client))
                                condFlags[19] = 'r';
                            if (TF2_IsPlayerInHealRadius(client))
                                condFlags[20] = '+';
                            if (TF2_IsPlayerHealing(client))
                                condFlags[21] = 'H';
                            if (TF2_IsPlayerOnFire(client))
                                condFlags[22] = 'F';
                            if (TF2_IsPlayerOverhealed(client))
                                condFlags[23] = 'O';
                            if (TF2_IsPlayerJarated(client))
                                condFlags[24] = 'J';
                            if (TF2_IsPlayerBleeding(client))
                                condFlags[25] = 'L';
                            if (TF2_IsPlayerDefenseBuffed(client))
                                condFlags[26] = 'E';
                            if (TF2_IsPlayerMilked(client))
                                condFlags[27] = 'M';
                            if (TF2_IsPlayerMegaHealed(client))
                                condFlags[28] = '!';
                            if (TF2_IsPlayerRegenBuffed(client))
                                condFlags[29] = 'G';
                            if (TF2_IsPlayerMarkedForDeath(client))
                                condFlags[30] = 'e';
                            if (TF2_IsPlayerNoHealingDamageBuff(client))
                                condFlags[31] = '3';
                            if (TF2_IsPlayerSpeedBuffAlly(client))
                                condFlags[32] = 'a';
                            if (TF2_IsPlayerHalloweenCritCandy(client))
                                condFlags[33] = 'y';
                            if (TF2_IsPlayerCritHype(client))
                                condFlags[34] = 'h';
                            if (TF2_IsPlayerCritOnFirstBlood(client))
                                condFlags[35] = '1';
                            if (TF2_IsPlayerCritOnWin(client))
                                condFlags[36] = 'W';
                            if (TF2_IsPlayerCritOnFlagCapture(client))
                                condFlags[37] = '#';
                            if (TF2_IsPlayerCritOnKill(client))
                                condFlags[38] = '*';
                            if (TF2_IsPlayerRestrictToMelee(client))
                                condFlags[39] = 'M';
                        #endif

                        new stunFlags = GetEntProp(target, Prop_Send, "m_iStunFlags");
                        if (stunFlags != 0 || TF2_IsPlayerDazed(target) || TF2_IsPlayerBonked(target) ||
                            TF2_IsPlayerCritCola(target) || TF2_IsPlayerTaunting(target) ||
                            TF2_IsPlayerCharging(target) || TF2_HasTheFlag(target))
                        {
                            bValid = false;
                            Trace("%d:%N found invalid target %d:%N with pcond=[%s]-(0x%08x:%08x), stun=0x%08x", \
                                  index, index, target, target, condFlags, pcond, pcond2, \
                                  GetEntProp(target, Prop_Send, "m_iStunFlags"));
                        }
                        else
                        {
                            Trace("%d:%N found %d:%N with pcond=[%s]-(0x%08x:%08x), stun=0x%d", \
                                  index, index, target, target, condFlags, pcond, pcond2, stunFlags);
                        }
                    }
                    else
                    {
                        Trace("%d:%N found %d:%N", index, index, target, target);
                    }

                    if (GetEntityMoveType(target) == MOVETYPE_NONE ||
                        IsPlayerStuck(target))
                    {
                        bValid = false;
                        Trace("%d:%N found stuck target %d", \
                              index, index, target);
                    }
                }
                else
                {
                    Trace("%d:%N found invalid target %d", \
                          index, index, target);
                }

                if (bValid)
                {
                    decl Float:targetloc[3];
                    GetClientAbsOrigin(target,targetloc); // Find the target's xyz coordinate

                    // Found a player that can be grabbed.
                    if (seekingWav[0])
                        StopSound(index,SNDCHAN_AUTO,seekingWav);

                    gGrabCounter[index]=0;

                    new Float:distance=GetVectorDistance(clientloc,targetloc);
                    new Float:limit=gAllowedRange[index][ACTION_GRAB];
                    if (limit <= 0.0 || limit >= distance)
                    {
                        new Action:res = Plugin_Continue;
                        Call_StartForward(fwdOnGrab);
                        Call_PushCell(index);
                        Call_PushCell(target);
                        Call_Finish(res);

                        if (res == Plugin_Continue)
                        {
                            Trace("%d:%N found %d:%N, who is a valid target!", \
                                  index, index, target, target);

                            if (grabberHitWav[0])
                                EmitSoundFromOrigin(grabberHitWav, targetloc); // Emit sound from the entity being grabbed

                            gGrabDist[index]=distance; // Tell plugin the distance between the 2 to maintain
                            gGravity[target] = GetEntPropFloat(target,Prop_Data,"m_flGravity"); // Save target's old gravity
                            SetEntPropFloat(target,Prop_Data,"m_flGravity",0.0); // Set gravity to 0 so the target moves around easy
                            //if (gFlags[index][ACTION_GRAB] != 0) // Grabber is a Puller
                            //{
                            //    gMaxSpeed[target] = GetEntPropFloat(target,Prop_Data,"m_flMaxspeed");
                            //    SetEntPropFloat(target,Prop_Data,"m_flMaxspeed",100.0); // Slow the target down.
                            //}

                            if (gRemainingDuration[index] <= 0)
                                gRemainingDuration[index] = gAllowedDuration[index][ACTION_GRAB];

                            // Tell plugin the target is being grabbed
                            gGrabbed[target]=true;
                            gTargetUserId[index]=GetClientUserId(target);

                            // Prepare sounds used in Grabbing()
                            if (pullerWav[0])
                                PrepareSound(pullerWav, true, true);

                            // Start a repeating timer that will reposition the target in the grabber's crosshairs
                            CreateTimer(0.1, Grabbing, GetClientUserId(index),
                                        TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

                            CloseHandle(hTrace);
                            TraceReturn("Stop Searching and Start Grabbing");
                            return Plugin_Stop;
                        }
                        else
                        {
                            Trace("%d:%N found %d:%N, who was rejected by OnGrab()!", \
                                  index, index, target, target);
                        }
                    }
                    else
                    {
                        Trace("%d:%N found %d:%N, who was too far away!", \
                              index, index, target, target);

                        Action_Drop(index);
                        EmitSoundToClient(index,errorWav);
                        PrintToChat(index,"%c[HGR:Source] %cTarget is too far away!",
                                    COLOR_GREEN,COLOR_DEFAULT);
                    }

                    CloseHandle(hTrace);
                    TraceReturn("Stop Searching");
                    return Plugin_Stop;
                }
                else
                {
                    Trace("%d:%N found %d, which is not a valid target!", \
                          index, index, target);
                }
            }

            if (!gGrabCounter[index] || ++gGrabCounter[index] >= 100)
            {
                Trace("%d:%N timed out while searching for a target", \
                      index, index);

                gGrabCounter[index]=1;
                if (seekingWav[0])
                {
                    StopSound(index,SNDCHAN_AUTO,seekingWav);
                    EmitSoundToClient(index,seekingWav);
                }
            }

            CloseHandle(hTrace);
            TraceReturn("Continue Searching");
            return Plugin_Handled;
        }
        else
        {
            Trace("%d:%N did not find a target", \
                  index, ValidClientIndex(index));

            if (IsClientInGame(index))
                PrintCenterText(index,"No target found");

            Action_Drop(index);
        }
    }

    TraceReturn("Stop Searching");
    return Plugin_Stop;
}

public Action:Grabbing(Handle:timer,any:userid)
{
    new index = GetClientOfUserId(userid);

    SetTraceCategory("Grab");
    TraceInto("hgrsource", "Grabbing", "userid=%d, index=%d:%N", \
              userid, index, ValidClientIndex(index));

    if (index > 0)
    {
        if (gStatus[index][ACTION_GRAB] && !gGrabbed[index] &&
            IsClientInGame(index) && IsPlayerAlive(index))
        {
            new target = GetClientOfUserId(gTargetUserId[index]);
            if (target > 0 && target <= MaxClients &&
                IsClientInGame(target) && IsPlayerAlive(target))
            {
                Trace("%d:%N is grabbing %d:%N", \
                      index, index, target, target);

                if (gRemainingDuration[index] > 0)
                {
                    gRemainingDuration[index]--;
                    if (gRemainingDuration[index] <= 0)
                    {
                        Action_Drop(index);
                        TraceReturn("%d:%N timed out while grabbing %d:%N", \
                                    index, index, target, target);

                        return Plugin_Stop;
                    }
                }

                if (g_bIsTF2)
                {
                    if (GetEntProp(index, Prop_Send, "m_iStunFlags") != 0 ||
                        TF2_IsPlayerDazed(index)    || TF2_IsPlayerBonked(index) ||
                        TF2_IsPlayerCritCola(index) || TF2_IsPlayerTaunting(index) ||
                        TF2_IsPlayerCharging(index) || TF2_HasTheFlag(index))
                    {
                        Action_Drop(index);
                        TraceReturn("%d:%N dropped %d:%N due to TF2 condition", \
                                    index, index, target, target);

                        return Plugin_Stop;
                    }
                }

                if (GetEntityMoveType(index) == MOVETYPE_NONE ||
                    IsPlayerStuck(index))
                {
                    Action_Drop(index);
                    TraceReturn("%d:%N dropped %d:%N, who became stuck", \
                                index, index, target, target);

                    return Plugin_Stop;
                }

                new Action:res = Plugin_Continue;
                Call_StartForward(fwdOnDrag);
                Call_PushCell(index);
                Call_PushCell(target);
                Call_Finish(res);
                if (res == Plugin_Stop)
                {
                    Action_Drop(index);
                    TraceReturn("%d:%N dropped %d:%N, due to OnDrag()", \
                                index, index, target, target);

                    return Plugin_Stop;
                }

                // Find where to push the target
                new Float:clientloc[3],Float:clientang[3],Float:targetloc[3],Float:endvec[3],Float:distance[3];
                GetClientAbsOrigin(index,clientloc);
                GetClientEyeAngles(index,clientang);
                GetClientAbsOrigin(target,targetloc);

                // Grabber is a Puller?
                if (gFlags[index][ACTION_GRAB] != 0)
                {
                    // Adjust the distance if the target is closer, or drag the victim in.
                    new Float:targetDistance=GetVectorDistance(clientloc,targetloc);
                    if (gGrabDist[index] > targetDistance)
                        gGrabDist[index] = targetDistance;
                    else if (gGrabDist[index] > 1)
                        gGrabDist[index]--;

                    if (!gGrabCounter[index] || ++gGrabCounter[index] >= 20)
                    {
                        gGrabCounter[index]=1;
                        if (pullerWav[0])
                            EmitSoundToClient(target,pullerWav);
                    }
                }

                // Find where the player is aiming
                new Handle:hTrace = TR_TraceRayFilterEx(clientloc,clientang,MASK_ALL,RayType_Infinite,TraceRayTryToHit);
                TR_GetEndPosition(endvec, hTrace); // Get the end position of the trace ray
                CloseHandle(hTrace);

                distance[0]=endvec[0]-clientloc[0];
                distance[1]=endvec[1]-clientloc[1];
                distance[2]=endvec[2]-clientloc[2];

                new Float:que=gGrabDist[index]/(SquareRoot(distance[0]*distance[0]+
                                                           distance[1]*distance[1]+
                                                           distance[2]*distance[2]));

                decl Float:velocity[3];
                velocity[0]=(((distance[0]*que)+clientloc[0])-targetloc[0])*(GetConVarFloat(cvarGrabSpeed)/1.666667);
                velocity[1]=(((distance[1]*que)+clientloc[1])-targetloc[1])*(GetConVarFloat(cvarGrabSpeed)/1.666667);
                velocity[2]=(((distance[2]*que)+clientloc[2])-targetloc[2])*(GetConVarFloat(cvarGrabSpeed)/1.666667);

                PrintCenterText(index,"Target found, release key/toggle off to drop");

                Trace("%d:%N teleported %d:%N, vel=%f,%f,%f", index, index, \
                      target, target, velocity[0], velocity[1], velocity[2]);

                TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, velocity);

                Trace("Creating beam from %d:%N to %d:%N", \
                      index, index, target, target);

                // Make a beam from grabber to grabbed
                new color[4];
                GetBeamColor(index,Grab,color);

                clientloc[2]+=45;
                targetloc[2]+=45;

                BeamEffect(clientloc,targetloc,0.2,1.0,10.0,color,0.0,0);

                TraceReturn();
                return Plugin_Handled;
            }
            else
            {
                Trace("%d:%N was grabbing %d, which is no longer valid!", index, index, target);
                Action_Drop(index);
            }
        }
        else
        {
            Trace("%d:%N was grabbing, but is no longer!", index, index);
            Action_Drop(index);
        }
    }
    else
    {
        Trace("User %d(%d) was grabbing, but is no longer a valid client", userid, index);
    }

    TraceReturn();
    return Plugin_Stop;
}

Action_Drop(client)
{
    SetTraceCategory("Grab");
    TraceInto("hgrsource", "Action_Drop", "client=%d:%N", \
              client, ValidClientIndex(client));

    gGrabCounter[client]=0;

    if (gStatus[client][ACTION_GRAB])
    {
        gStatus[client][ACTION_GRAB]=false; // Tell plugin the grabber has dropped his target
        gLastUsed[client][ACTION_GRAB]=GetGameTime(); // Tell plugin when grabber dropped his target
    }

    if (seekingWav[0] && IsClientInGame(client))
    {
        StopSound(client,SNDCHAN_AUTO,seekingWav);
    }

    new target = GetClientOfUserId(gTargetUserId[client]);
    Trace("%d:%N dropped %d:%N", client, ValidClientIndex(client), target, ValidClientIndex(target));

    if (target > 0)
    {
        if (IsClientInGame(client))
            PrintCenterText(client,"Target has been dropped");

        if (IsClientInGame(target))
        {
            new Float:gravity = gGravity[target]; // Set gravity back to saved value (or normal)
            SetEntPropFloat(target,Prop_Data,"m_flGravity",(gravity != 0.0) ? gravity : 1.0);

            if (gFlags[client][ACTION_GRAB] != 0) // Grabber is a Puller
            {
                //SetEntPropFloat(target,Prop_Data,"m_flMaxspeed",gMaxSpeed[target]);
                if (pullerWav[0])
                    StopSound(target,SNDCHAN_AUTO,pullerWav);
            }
        }

        if (target <= MaxClients)
            gGrabbed[target]=false; // Tell plugin the target is no longer being grabbed

        gTargetUserId[client]=-1;
    }
    else if (HasAccess(client,Grab) && IsClientInGame(client))
        PrintCenterText(client,"");

    new Action:res;
    Call_StartForward(fwdOnDrop);
    Call_PushCell(client);
    Call_PushCell(target);
    Call_Finish(res);

    TraceReturn();
}

/******
 *Rope*
 *******/

Action_Rope(client)
{
    if (g_bNativeOverride || GetConVarBool(cvarRopeEnable))
    {
        if (client>0)
        {
            if (!gGrabbed[client] && !gStatus[client][ACTION_ROPE] &&
                IsClientInGame(client) && IsPlayerAlive(client))
            {
                if (HasAccess(client,Rope))
                {
                    if (g_bIsTF2 && GetConVarBool(cvarRopeNoFlag) && TF2_HasTheFlag(client))
                    {
                        PrepareAndEmitSoundToClient(client,errorWav);
                        PrintToChat(client,"%c[HGR:Source] %cYou can not use the %crope%c while carrying the flag!",
                                    COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                    }
                    else
                    {
                        new Float:cooldown = gCooldown[client][ACTION_ROPE];
                        new Float:lastUsed = gLastUsed[client][ACTION_ROPE];
                        if (cooldown <= 0.0 || lastUsed <= 0.0 ||
                            ((GetGameTime() - lastUsed) >= cooldown))
                        {
                            if (fireWav[0])
                                PrepareAndEmitSoundToAll(fireWav, client); // Emit fire sound

                            new Float:clientloc[3],Float:clientang[3];
                            GetClientEyePosition(client,clientloc); // Get the position of the player's eyes
                            GetClientEyeAngles(client,clientang); // Get the angle the player is looking

                            // Create a ray that tells where the player is looking
                            new Handle:hTrace = TR_TraceRayFilterEx(clientloc,clientang,MASK_ALL,RayType_Infinite,TraceRayTryToHit);
                            TR_GetEndPosition(gRopeEndloc[client], hTrace); // Get the end xyz coordinate of where a player is looking
                            CloseHandle(hTrace);

                            new Float:limit=gAllowedRange[client][ACTION_ROPE];
                            new Float:dist=GetVectorDistance(clientloc,gRopeEndloc[client]);
                            if (limit <= 0.0 || limit >= dist)
                            {
                                if (gRemainingDuration[client] == 0)
                                    gRemainingDuration[client] = gAllowedDuration[client][ACTION_ROPE];

                                // Tell plugin the player is roping
                                gStatus[client][ACTION_ROPE]=true;
                                gRopeDist[client]=dist;

                                // Emit sound from the end of the rope
                                if (hitWav[0] && PrepareSound(hitWav, true, true))
                                    EmitSoundFromOrigin(hitWav, gRopeEndloc[client]);

                                // Create roping loop
                                CreateTimer(0.1, Roping, GetClientUserId(client),
                                            TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
                            }
                            else
                            {
                                PrepareAndEmitSoundToClient(client,errorWav);
                                PrintToChat(client,"%c[HGR:Source] %cTarget is too far away!",
                                            COLOR_GREEN,COLOR_DEFAULT);
                            }
                        }
                        else
                        {
                            PrepareAndEmitSoundToClient(client,errorWav);
                            PrintToChat(client,"%c[HGR:Source] %cYou have used the %crope%c too recently!",
                                        COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                        }
                    }
                }
                else if (g_bNativeOverride)
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[HGR:Source] %cYou don't have a %crope%c",
                                COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
                else
                {
                    PrepareAndEmitSoundToClient(client,deniedWav);
                    PrintToChat(client,"%c[HGR:Source] %cYou don't have permission to use the %crope%c",
                                COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
                }
            }
            else
                PrepareAndEmitSoundToClient(client,deniedWav);
        }
        else
        {
            PrepareAndEmitSoundToClient(client,deniedWav);
            PrintToChat(client,"%c[HGR:Source] %cERROR: Please notify server administrator",
                        COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    else
    {
        PrepareAndEmitSoundToClient(client,deniedWav);
        PrintToChat(client,"%c[HGR:Source] Rope %cis currently disabled",
                    COLOR_GREEN,COLOR_DEFAULT);
    }
}

public Action:Roping(Handle:timer,any:userid)
{
    new index = GetClientOfUserId(userid);
    if (index > 0)
    {
        if (!gGrabbed[index] && gStatus[index][ACTION_ROPE] &&
            IsClientInGame(index) && IsPlayerAlive(index) && 
            !(g_bIsTF2 && GetConVarBool(cvarRopeNoFlag) && TF2_HasTheFlag(index)))
        {
            if (gRemainingDuration[index] > 0)
            {
                gRemainingDuration[index]--;
                if (gRemainingDuration[index] <= 0)
                {
                    Action_Detach(index);
                    return Plugin_Stop;
                }
            }

            new Action:res = Plugin_Continue;
            Call_StartForward(fwdOnRope);
            Call_PushCell(index);
            Call_Finish(res);
            if (res == Plugin_Stop)
            {
                Action_Detach(index);
                return Plugin_Stop;
            }

            new Float:clientloc[3],Float:velocity[3],Float:velocity2[3];
            GetClientAbsOrigin(index,clientloc);
            GetVelocity(index,velocity);
            velocity2[0]=(gRopeEndloc[index][0]-clientloc[0])*3.0;
            velocity2[1]=(gRopeEndloc[index][1]-clientloc[1])*3.0;

            new Float:y_coord,Float:x_coord;
            y_coord=velocity2[0]*velocity2[0]+velocity2[1]*velocity2[1];
            x_coord=(GetConVarFloat(cvarRopeSpeed)*20.0)/SquareRoot(y_coord);

            velocity[0]+=velocity2[0]*x_coord;
            velocity[1]+=velocity2[1]*x_coord;

            if (gRopeEndloc[index][2]-clientloc[2]>=gRopeDist[index]&&velocity[2]<0.0)
                velocity[2]*=-1;

            TeleportEntity(index,NULL_VECTOR,NULL_VECTOR,velocity);

            // Make a beam from the client to end of the rope
            new color[4];
            clientloc[2]+=50;
            GetBeamColor(index,Rope,color);
            BeamEffect(clientloc,gRopeEndloc[index],0.2,3.0,3.0,color,0.0,0);
            return Plugin_Handled;
        }
        else
            Action_Detach(index);
    }
    return Plugin_Stop;
}

Action_Detach(client)
{
    if (gStatus[client][ACTION_ROPE])
    {
        gStatus[client][ACTION_ROPE]=false; // Tell plugin the client is not roping
        gLastUsed[client][ACTION_ROPE]=GetGameTime(); // Tell plugin when client stopped roping
    }
}

/***************
 *Trace Filters*
 ****************/

public bool:TraceRayTryToHit(entity,mask)
{
    if(entity>0&&entity<=MaxClients) // Check if the beam hit a player and tell it to keep tracing if it did
        return false;
    return true;
}

public bool:TraceRayGrabEnt(entity,mask)
{
    if(entity>0) // Check if the beam hit an entity other than the grabber, and stop if it does
    {
        if(entity<=MaxClients&&!gStatus[entity][ACTION_GRAB]&&!gGrabbed[entity])
            return true;
        if(entity>64) 
            return true;
    }
    return false;
}

/*********
 *Helpers*
 **********/

EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
    EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,
                   SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,
                   NULL_VECTOR,true,0.0);
}

GetVelocity(client,Float:output[3])
{
    GetEntDataVector(client, gGetVelocityOffset, output);
}

/****************
 *Math (Vectors)*
 *****************/

GetForwardPushVec(const Float:start[3],const Float:end[3],Float:output[3])
{
    CreateVectorFromPoints(start,end,output);
    NormalizeVector(output,output);
    output[0]*=GetConVarFloat(cvarHookSpeed)*140.0;
    output[1]*=GetConVarFloat(cvarHookSpeed)*140.0;
    output[2]*=GetConVarFloat(cvarHookSpeed)*140.0;
}

Float:CreateVectorFromPoints(const Float:vec1[3],const Float:vec2[3],Float:output[3])
{
    output[0]=vec2[0]-vec1[0];
    output[1]=vec2[1]-vec1[1];
    output[2]=vec2[2]-vec1[2];
}

stock AddInFrontOf(Float:orig[3],Float:angle[3],Float:distance,Float:output[3])
{
    new Float:viewvector[3];
    ViewVector(angle,viewvector);
    output[0]=viewvector[0]*distance+orig[0];
    output[1]=viewvector[1]*distance+orig[1];
    output[2]=viewvector[2]*distance+orig[2];
}

stock ViewVector(Float:angle[3],Float:output[3])
{
    output[0]=Cosine(angle[1]/(180/FLOAT_PI));
    output[1]=Sine(angle[1]/(180/FLOAT_PI));
    output[2]=-Sine(angle[0]/(180/FLOAT_PI));
}

/*********
 *Effects*
 **********/

BeamEffect(Float:startvec[3],Float:endvec[3],Float:life,Float:width,
           Float:endwidth,const color[4],Float:amplitude,speed)
{
    PrepareModel(LASER_MODEL, precache_laser);
    TE_SetupBeamPoints(startvec,endvec,precache_laser,0,0,66,life,width,
                       endwidth,0,amplitude,color,speed);
    TE_SendToAll();
} 

/*********************
 *Partial Name Parser*
 **********************/

FindMatchingPlayers(const String:matchstr[],clients[])
{
    new count=0;
    if(StrEqual(matchstr,"@all",false))
    {
        for(new x=1;x<=MaxClients;x++)
        {
            if(IsClientInGame(x))
            {
                clients[count]=x;
                count++;
            }
        }
    }
    else if(StrEqual(matchstr,"@t",false))
    {
        for(new x=1;x<=MaxClients;x++)
        {
            if(IsClientInGame(x)&&GetClientTeam(x)==2)
            {
                clients[count]=x;
                count++;
            }
        }
    }
    else if(StrEqual(matchstr,"@ct",false))
    {
        for(new x=1;x<=MaxClients;x++)
        {
            if(IsClientInGame(x)&&GetClientTeam(x)==3)
            {
                clients[count]=x;
                count++;
            }
        }
    }
    else if(matchstr[0]=='@')
    {
        new userid=StringToInt(matchstr[1]);
        if(userid)
        {
            new index=GetClientOfUserId(userid);
            if(index)
            {
                if(IsClientInGame(index))
                {
                    clients[count]=index;
                    count++;
                }
            }
        }
    }
    else
    {
        for(new x=1;x<=MaxClients;x++)
        {
            if(IsClientInGame(x))
            {
                decl String:name[64];
                GetClientName(x,name,sizeof(name));
                if(StrContains(name,matchstr,false)!=-1)
                {
                    clients[count]=x;
                    count++;
                }
            }
        }
    }
    return count;
}

stock bool:IsPlayerStuck(client)
{
    decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];
    GetClientMins(client, vecMin);
    GetClientMaxs(client, vecMax);
    GetClientAbsOrigin(client, vecOrigin);
    new Handle:hTrace = TR_TraceHullFilterEx(vecOrigin, vecOrigin, vecMin, vecMax,
                                             MASK_PLAYERSOLID, TraceRayHitCollidable,
                                             client);
    new entity = TR_GetEntityIndex(hTrace);
    CloseHandle(hTrace);
    return (entity > 0);
}

public bool:TraceRayHitCollidable(entity, mask)
{
    if (entity > MaxClients)
    {
        new m_CollisionGroup = GetEntProp(entity, Prop_Send, "m_CollisionGroup");
        return (m_CollisionGroup != _:COLLISION_GROUP_DEBRIS &&
                m_CollisionGroup != _:COLLISION_GROUP_DEBRIS_TRIGGER);
    }
    else
        return false;
}

/**
 * Determine if client has the flag
 */
#tryinclude <tf2_flag>
#if !defined _tf2_flag_included
    stock bool:TF2_HasTheFlag(client)
    {
        new ent = -1;
        while ((ent = FindEntityByClassname(ent, "item_teamflag")) != -1)
        {
            if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
                return true;
        }
        return false;
    }
#endif
