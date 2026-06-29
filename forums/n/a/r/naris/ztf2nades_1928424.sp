/**
 * vim: set ai et ts=4 sw=4 :
 * File: tf2nades.sp
 * Description: dis is z tf2nades.
 * Author(s): L. Duke
 * Modified by: -=|JFH|=-Naris (Murray Wilson)
 *              -- Added native interface
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "3.3"

public Plugin:myinfo = {
    name = "tf2nades",
    author = "L. Duke",
    description = "adds nades to TF2",
    version = PLUGIN_VERSION,
    url = "http://www.lduke.com/"
};

// *************************************************
// defines
// *************************************************

#define MAX_PLAYERS 33   // maxplayers + sourceTV
//#define MAXPLAYERS     // uncomment for more than 32 players + sourceTV

// TF2 Classes

#define SCOUT 1
#define SNIPER 2
#define SOLDIER 3
#define DEMO 4
#define MEDIC 5
#define HEAVY 6
#define PYRO 7
#define SPY 8
#define ENGIE 9
#define CLS_MAX 10

// DOD Classes

#define RIFLEMAN 0
#define ASSAULT 1
#define SUPPORT 2
#define DODSNIPER 3
#define MG 4
#define ROCKETMAN 5

enum NadeType
{
    DefaultNade = 0, // use class for nade type
    ConcNade,
    BearTrap,
    NailNade,
    MirvNade,
    HealthNade,
    HeavyNade,
    NapalmNade,
    HallucNade,
    EmpNade,
    Bomblet,
    SmokeNade,
    GasNade,
    TargetingDrone,
    FragNade
};

enum HoldType
{
    HoldNone = 0,
    HoldFrag,
    HoldSpecial,
    HoldOther
};

#define MIRV_PARTS 5

#define MDL_FRAG "models/weapons/nades/duke1/w_grenade_frag.mdl"
#define MDL_CONC "models/weapons/nades/duke1/w_grenade_conc.mdl"
#define MDL_NAIL "models/weapons/nades/duke1/w_grenade_nail.mdl"
#define MDL_MIRV1 "models/weapons/nades/duke1/w_grenade_mirv.mdl"
#define MDL_MIRV2 "models/weapons/nades/duke1/w_grenade_bomblet.mdl"
#define MDL_HEALTH "models/weapons/nades/duke1/w_grenade_heal.mdl"
#define MDL_NAPALM "models/weapons/nades/duke1/w_grenade_napalm.mdl"
#define MDL_HALLUC "models/weapons/nades/duke1/w_grenade_gas.mdl"
#define MDL_EMP "models/weapons/nades/duke1/w_grenade_emp.mdl"
#define MDL_TRAP "models/weapons/w_models/w_grenade_beartrap.mdl"
#define MDL_DRONE "models/combine_scanner.mdl"
#define MDL_SMOKE "models/weapons/nades/duke1/w_grenade_gas.mdl"
#define MDL_GAS "models/weapons/nades/duke1/w_grenade_gas.mdl"

#define MDL_RING_MODEL "sprites/laser.vmt"
#define MDL_NAPALM_SPRITE "sprites/floorfire4_.vmt"
#define MDL_BEAM_SPRITE "sprites/laser.vmt"
#define MDL_EMP_SPRITE "sprites/laser.vmt"
#define MDL_SMOKE_SPRITE "sprites/smoke.vmt"
#define MDL_EXPLOSION_SPRITE "sprites/zerogxplode.vmt"

// sounds
#define SND_THROWNADE "weapons/grenade_throw.wav"
#define SND_COUNTDOWN "weapons/grenade/tick1.wav"
#define SND_NADE_FRAG "ambient/explosions/explode_4.wav"
#define SND_NADE_FRAG_TF2 "weapons/explode1.wav"
#define SND_NADE_CONC "weapons/explode5.wav"
#define SND_NADE_NAIL "ambient/levels/labs/teleport_rings_loop2.wav"
#define SND_NADE_NAIL_EXPLODE "explosions/explode_4.wav"
#define SND_NADE_NAIL_EXPLODE_TF2 "weapons/explode1.wav"
#define SND_NADE_NAIL_SHOOT1 "npc/turret_floor/shoot1.wav"
#define SND_NADE_NAIL_SHOOT2 "npc/turret_floor/shoot2.wav"
#define SND_NADE_NAIL_SHOOT3 "npc/turret_floor/shoot3.wav"
#define SND_NADE_MIRV1 "weapons/mortar/mortar_explode1.wav"
#define SND_NADE_MIRV1_TF2 "weapons/sentry_explode.wav"
#define SND_NADE_MIRV2 "weapons/explode3.wav"
#define SND_NADE_MIRV2_TF2 "weapons/explode1.wav"
#define SND_NADE_NAPALM "ambient/fire/gascan_ignite1.wav"
#define SND_NADE_HEALTH "items/suitchargeok1.wav"
#define SND_NADE_HALLUC_TF2 "weapons/flame_thrower_airblast.wav"
#define SND_NADE_HALLUC "ambient/machines/spinup.wav"
#define SND_NADE_EMP "npc/scanner/scanner_electric2.wav"
#define SND_NADE_TRAP "weapons/grenade_impact.wav"
#define SND_NADE_SMOKE "ambient/fire/ignite.wav"
#define SND_NADE_GAS "ambient/fire/ignite.wav"

#define SND_CHARGED "player/medic_charged_death.wav"
#define SND_IMPACT  "player/pl_impact_airblast2.wav"
#define SND_SAPPER  "weapons/sapper_removed.wav"

new String:sndPain[][] = 
{   "player/pl_pain5.wav",
    "player/pl_pain6.wav",
    "player/pl_pain7.wav",
    "player/pain.wav"
};


#define STRLENGTH 128

// *************************************************
// globals 
// *************************************************

// global data for current nade
new Float:gnSpeed;
new Float:gnDelay;
new String:gnSkin[16];
new String:gnModel[256];
new String:gnParticle[256];

new bool:gCanRun = false;
new bool:gWaitOver = false;
new Float:gMapStart;
new gNade[MAX_PLAYERS+1]                            = { INVALID_ENT_REFERENCE, ... };   // pointer to the player's nade
new gKilledBy[MAX_PLAYERS+1];                       // player that killed
new gTargeted[MAX_PLAYERS+1];                       // flag is player is targetted and by whom.
new gCountdown[MAX_PLAYERS+1];                      // countdown before the nade explodes
new gRemaining1[MAX_PLAYERS+1];                     // how many nades player has this spawn
new gRemaining2[MAX_PLAYERS+1];                     // how many nades player has this spawn
new HoldType:gHolding[MAX_PLAYERS+1];               // what kind of nade player is holding
new Handle:gNadeTimer[MAX_PLAYERS+1];               // pointer to nade timer
new Handle:gNadeTimer2[MAX_PLAYERS+1];              // pointer to 2nd nade timer
new bool:gTriggerTimer[MAX_PLAYERS+1];              // flags that timer was triggered
new Float:PlayersInRange[MAX_PLAYERS+1];            // players are in radius ?
new String:gKillWeapon[MAX_PLAYERS+1][STRLENGTH];   // weapon that killed
new Float:gKillTime[MAX_PLAYERS+1];                 // time plugin requested kill
new gStopInfoPanel[MAX_PLAYERS+1];                  // flag to disable help
new gRingModel;                                     // model for beams
new gNapalmSprite;                                  // sprite index
new gBeamSprite;                                    // sprite index
new gEmpSprite;
new gSmokeSprite;
new gExplosionSprite;

new Float:gHoldingArea[3] = {-10000.0, -10000.0, -10000.0}; // point to store unused objects

new g_FragModelIndex;
new g_ConcModelIndex;
new g_NailModelIndex;
new g_DroneModelIndex;
new g_Mirv1ModelIndex;
new g_Mirv2ModelIndex;
new g_HealthModelIndex;
new g_NapalmModelIndex;
new g_HallucModelIndex;
new g_SmokeModelIndex;
new g_TrapModelIndex;
new g_EmpModelIndex;
new g_GasModelIndex;

#pragma unused g_TrapModelIndex, g_SmokeModelIndex, g_GasModelIndex

// global "temps"
new String:tName[256];

// *************************************************
// convars
// *************************************************
new Handle:cvNadeType[CLS_MAX];
new Handle:cvFragNum[CLS_MAX];
new Handle:cvFragRadius = INVALID_HANDLE;
new Handle:cvFragDamage = INVALID_HANDLE;
new Handle:cvConcNum = INVALID_HANDLE;
new Handle:cvConcRadius = INVALID_HANDLE;
new Handle:cvConcForce = INVALID_HANDLE;
new Handle:cvConcDamage = INVALID_HANDLE;
new Handle:cvNailNum = INVALID_HANDLE;
new Handle:cvNailRadius = INVALID_HANDLE;
new Handle:cvNailDamageNail = INVALID_HANDLE;
new Handle:cvNailDamageExplode = INVALID_HANDLE;
new Handle:cvMirvNum = INVALID_HANDLE;
new Handle:cvMirvRadius = INVALID_HANDLE;
new Handle:cvMirvDamage1 = INVALID_HANDLE;
new Handle:cvMirvDamage2 = INVALID_HANDLE;
new Handle:cvMirvSpread = INVALID_HANDLE;
new Handle:cvHealthNum = INVALID_HANDLE;
new Handle:cvHealthRadius = INVALID_HANDLE;
new Handle:cvHealthDelay = INVALID_HANDLE;
new Handle:cvNapalmNum = INVALID_HANDLE;
new Handle:cvNapalmRadius = INVALID_HANDLE;
new Handle:cvNapalmDamage = INVALID_HANDLE;
new Handle:cvHallucNum = INVALID_HANDLE;
new Handle:cvHallucRadius = INVALID_HANDLE;
new Handle:cvHallucDelay = INVALID_HANDLE;
new Handle:cvHallucDamage = INVALID_HANDLE;
new Handle:cvTrapNum = INVALID_HANDLE;
new Handle:cvTrapRadius = INVALID_HANDLE;
new Handle:cvTrapDamage = INVALID_HANDLE;
new Handle:cvTrapDelay = INVALID_HANDLE;
new Handle:cvBombNum = INVALID_HANDLE;
new Handle:cvBombRadius = INVALID_HANDLE;
new Handle:cvBombDamage = INVALID_HANDLE;
new Handle:cvEmpNum = INVALID_HANDLE;
new Handle:cvEmpRadius = INVALID_HANDLE;
new Handle:cvDroneRadius = INVALID_HANDLE;
new Handle:cvDroneDamage = INVALID_HANDLE;
new Handle:cvSmokeNum = INVALID_HANDLE;
new Handle:cvSmokeRadius = INVALID_HANDLE;
new Handle:cvSmokeDelay = INVALID_HANDLE;
new Handle:cvGasNum = INVALID_HANDLE;
new Handle:cvGasRadius = INVALID_HANDLE;
new Handle:cvGasDelay = INVALID_HANDLE;
new Handle:cvGasDamage = INVALID_HANDLE;
new Handle:cvWaitPeriod = INVALID_HANDLE;
new Handle:cvCountdown = INVALID_HANDLE;
new Handle:cvHelpLink = INVALID_HANDLE;
new Handle:cvShowHelp = INVALID_HANDLE;
new Handle:cvAnnounce = INVALID_HANDLE;
new Handle:cvRestock = INVALID_HANDLE;

// *************************************************
// native interface variables
// *************************************************

new gAllowed1[MAX_PLAYERS+1];               // how many frag nades player given each spawn
new gAllowed2[MAX_PLAYERS+1];               // how many special nades player given each spawn
new bool:gCanRestock[MAX_PLAYERS+1];        // is the player allowed to restock at a cabinet
new NadeType:gSpecialType[MAX_PLAYERS+1];   // what nade type the special nade is

new bool:gNativeOverride = false;
new bool:gTargetOverride = false;

// forwards
new Handle:fwdOnNadeExplode = INVALID_HANDLE;

/**
 * Description: Stocks to damage a player or an entity using a point_hurt entity.
 */
#tryinclude <damage>
#if !defined _damage_included
    #define DMG_GENERIC                 0
    #define DMG_BURN                    (1 << 3)
    #define DMG_BLAST                   (1 << 6)
    #define DMG_NERVEGAS                (1 << 16)

    stock g_damagePointRef = INVALID_ENT_REFERENCE;

    stock DamagePlayer(victim,damage,attacker=0,dmg_type=DMG_GENERIC,const String:weapon[]="")
    {
        if (damage > 0 && victim > 0 && IsClientInGame(victim) && IsPlayerAlive(victim))
        {
            decl String:dmg_str[16];
            IntToString(damage,dmg_str,sizeof(dmg_str));

            decl String:dmg_type_str[32];
            IntToString(dmg_type,dmg_type_str,sizeof(dmg_type_str));

            new pointHurt = EntRefToEntIndex(g_damagePointRef);
            if (pointHurt < 1)
            {
                if (!IsEntLimitReached(.message="Unable to create point_hurt in DamagePlayer()"))
                {
                    pointHurt=CreateEntityByName("point_hurt");
                    if (pointHurt > 0 && IsValidEdict(pointHurt))
                    {
                        //DispatchSpawn(pointHurt);
                        g_damagePointRef = EntIndexToEntRef(pointHurt);
                    }
                    else
                    {
                        LogError("Unable to create point_hurt in DamagePlayer()");
                        return;
                    }
                }
            }

            if (pointHurt > 0 && IsValidEdict(pointHurt))
            {
                decl String:targetname[16];
                Format(targetname,sizeof(targetname), "target%d", victim);

                DispatchKeyValue(victim,"targetname",targetname);
                DispatchKeyValue(pointHurt,"DamageTarget",targetname);
                DispatchKeyValue(pointHurt,"Damage",dmg_str);
                DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);

                if (weapon[0] != '\0')
                    DispatchKeyValue(pointHurt,"classname",weapon);

                DispatchSpawn(pointHurt);

                AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
                DispatchKeyValue(pointHurt,"classname","point_hurt");

                IntToString(victim,targetname,sizeof(targetname));
                DispatchKeyValue(victim,"targetname",targetname);
            }
            else
                LogError("Unable to spawn point_hurt in DamagePlayer()");
        }
    }

    stock CleanupDamageEntity()
    {
        if (g_damagePointRef != INVALID_ENT_REFERENCE)
        {
            new pointHurt = EntRefToEntIndex(g_damagePointRef);
            if (pointHurt > 0)
                AcceptEntityInput(pointHurt, "kill");

            g_damagePointRef = INVALID_ENT_REFERENCE;
        }
    }
#endif

/**
 * Description: Use the SourceCraft API, if available.
 */
#undef REQUIRE_PLUGIN
#tryinclude <sc/SourceCraft>
#define REQUIRE_PLUGIN

#if defined SOURCECRAFT
    stock bool:m_SourceCraftAvailable = false;
    new DamageFrom:gCategory[MAX_PLAYERS+1];// what category to use in HurtPlayer()
#else    

/**
 * Description: Function to determine game/mod type
 */
#tryinclude <gametype>
#if !defined _gametype_included
    enum Game { undetected, tf2, cstrike, csgo, dod, hl2mp, insurgency, zps, l4d, l4d2, other_game };
    stock Game:GameType = undetected;

    stock Game:GetGameType()
    {
        if (GameType == undetected)
        {
            new String:modname[30];
            GetGameFolderName(modname, sizeof(modname));
            if (StrEqual(modname,"tf",false))
                GameType=tf2;
            else if (StrEqual(modname,"cstrike",false))
                GameType=cstrike;
            else if (StrEqual(modname,"csgo",false))
                GameType=csgo;
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
 * Description: Stocks to return information about TF2 player condition, etc.
 */
#tryinclude <tf2_player>
#if !defined _tf2_player_included
    #define TF2_IsPlayerDisguised(%1)    TF2_IsPlayerInCondition(%1,TFCond_Disguised)
    #define TF2_IsPlayerCloaked(%1)      TF2_IsPlayerInCondition(%1,TFCond_Cloaked)
    #define TF2_IsPlayerUbercharged(%1)  TF2_IsPlayerInCondition(%1,TFCond_Ubercharged)
    #define TF2_IsPlayerTaunting(%1)     TF2_IsPlayerInCondition(%1,TFCond_Taunting)
    #define TF2_IsPlayerDeadRingered(%1) TF2_IsPlayerInCondition(%1,TFCond_DeadRingered)
    #define TF2_IsPlayerBonked(%1)       TF2_IsPlayerInCondition(%1,TFCond_Bonked)
#endif

#endif

/**
 * Description: Functions to return information about TF2 spy cloak.
 */
#tryinclude <tf2_meter>
#if !defined _tf2_meter_included
    stock Float:TF2_GetCloakMeter(client)
    {
        return GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
    }

    stock TF2_SetCloakMeter(client,Float:cloakMeter)
    {
        SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", cloakMeter);
    }

    stock Float:TF2_GetChargeMeter(client)
    {
        return GetEntPropFloat(client, Prop_Send, "m_flChargeMeter");
    }

    stock TF2_SetChargeMeter(client,Float:chargeMeter)
    {
        SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", chargeMeter);
    }

    stock Float:TF2_GetRageMeter(client)
    {
        return GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
    }

    stock TF2_SetRageMeter(client,Float:rageMeter)
    {
        SetEntPropFloat(client, Prop_Send, "m_flRageMeter", rageMeter);
    }

    stock Float:TF2_GetHypeMeter(client)
    {
        return GetEntPropFloat(client, Prop_Send, "m_flHypeMeter");
    }

    stock TF2_SetHypeMeter(client,Float:hypeMeter)
    {
        SetEntPropFloat(client, Prop_Send, "m_flHypeMeter", hypeMeter);
    }

    stock Float:TF2_GetEnergyDrinkMeter(client)
    {
        return GetEntPropFloat(client, Prop_Send, "m_flEnergyDrinkMeter");
    }

    stock TF2_SetEnergyDrinkMeter(client,Float:energyDrinkMeter)
    {
        SetEntPropFloat(client, Prop_Send, "m_flEnergyDrinkMeter", energyDrinkMeter);
    }
#endif

/**
 * Description: Stocks for DoD
 */
#tryinclude <dod>
#if !defined _dod_included
    enum DODClassType
    {
        DODClass_Unassigned = -1,
        DODClass_Rifleman = 0,
        DODClass_Assault,
        DODClass_Support,
        DODClass_Sniper,
        DODClass_MachineGunner,
        DODClass_Rocketman
    };

    /**
     * Get's a Clients current class.
     *
     * @param client		Player's index.
     * @return				Current DODClassType of player.
     * @error				Invalid client index.
     */
    stock DODClassType:DOD_GetPlayerClass(client)
    {
        return DODClassType:GetEntProp(client, Prop_Send, "m_iPlayerClass");
    }
#endif

#undef REQUIRE_PLUGIN
#tryinclude <dod_ignite>
#define REQUIRE_PLUGIN


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

        if (value < Download && download)
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

    stock AddFolderToDownloadTable(const String:Directory[], bool:recursive=false)
    {
        decl String:Path[PLATFORM_MAX_PATH+1];
        decl String:FileName[PLATFORM_MAX_PATH+1];

        new Handle:Dir = OpenDirectory(Directory), FileType:Type;
        while(ReadDirEntry(Dir, FileName, sizeof(FileName), Type))     
        {
            if (Type == FileType_Directory && recursive)         
            {           
                FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
                AddFolderToDownloadTable(FileName);
            }                 
            else if (Type == FileType_File)
            {
                FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
                AddFileToDownloadsTable(Path);
            }
        }
    }
#endif

/**
 * Description: Function to check the entity limit.
 *              Use before spawning an entity.
 */
#tryinclude <entlimit>
#if !defined _entlimit_included
    stock IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
    {
        new max = GetMaxEntities();
        new count = GetEntityCount();
        new remaining = max - count;
        if (remaining <= warn)
        {
            if (count <= critical)
            {
                PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
                LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);

                if (client > 0)
                {
                    PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
                                   count, max, remaining, message);
                }
            }
            else
            {
                PrintToServer("Caution: Entity count is getting high!");
                LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);

                if (client > 0)
                {
                    PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
                                   count, max, remaining, message);
                }
            }
            return count;
        }
        else
            return 0;
    }
#endif

// *************************************************
// main plugin
// *************************************************

public OnPluginStart()
{
    // events
    HookEvent("player_spawn",PlayerSpawn);
    HookEvent("player_hurt",PlayerHurt);
    HookEvent("player_death",PlayerDeath, EventHookMode_Pre);

    if (GetGameType() == tf2)
    {
        HookEvent("player_changeclass", ChangeClass);

        HookEvent("arena_round_start", MainEvents);
        HookEvent("teamplay_round_start", MainEvents);
        HookEvent("teamplay_round_active", MainEvents);
        HookEvent("teamplay_restart_round", MainEvents);

        HookEvent("teamplay_round_stalemate", RoundEnd, EventHookMode_PostNoCopy);
        HookEvent("teamplay_round_win", RoundEnd, EventHookMode_PostNoCopy);
        HookEvent("teamplay_game_over", RoundEnd, EventHookMode_PostNoCopy);
        HookEvent("arena_win_panel", RoundEnd, EventHookMode_PostNoCopy);

        HookEntityOutput("prop_dynamic", "OnAnimationBegun", EntityOutput_OnAnimationBegun);

        cvRestock = CreateConVar("sm_tf2nades_restock", "1", "restock nades at supply cabinets (1=yes 0=no)");

        cvNadeType[SCOUT] = CreateConVar("sm_tf2nades_scout_type", "1", "type of special nade given to scouts (0=none, 1=Concussion, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[SNIPER] = CreateConVar("sm_tf2nades_sniper_type", "2", "type of special nade given to snipers (0=none, 2=Beartrap, 10=Bomblet, 11=Smoke, 12=Gas, 13=Drone, 14=Frag, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[SOLDIER] = CreateConVar("sm_tf2nades_soldier_type", "3", "type of special nade given to soldiers (0=none, 3=Nail, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[DEMO] = CreateConVar("sm_tf2nades_demo_type", "4", "type of special nade given to demo men (0=none, 4=Mirv, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[MEDIC] = CreateConVar("sm_tf2nades_medic_type", "5", "type of special nade given to medics (0=none, 5=Health, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[HEAVY] = CreateConVar("sm_tf2nades_heavy_type", "6", "type of special nade given to heavys (0=none, 6=Heavy Mirv, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[PYRO] = CreateConVar("sm_tf2nades_pyro_type", "7", "type of special nade given to pyros (0=none, 7=Napalm, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[SPY] = CreateConVar("sm_tf2nades_spy_type", "8", "type of special nade given to spys (0=none, 8=Hallucination, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[ENGIE] = CreateConVar("sm_tf2nades_engineer_type", "9", "type of special nades given to engineers (0=none, 9=Emp, etc)", 0, true, 0.0, true, 11.0);

        cvFragNum[SCOUT] = CreateConVar("sm_tf2nades_frag_scout", "2", "number of frag nades given to scouts", 0, true, 0.0, true, 10.0);
        cvFragNum[SNIPER] = CreateConVar("sm_tf2nades_frag_sniper", "2", "number of frag nades given to snipers", 0, true, 0.0, true, 10.0);
        cvFragNum[SOLDIER] = CreateConVar("sm_tf2nades_frag_soldier", "2", "number of frag nades given to soldiers", 0, true, 0.0, true, 10.0);
        cvFragNum[DEMO] = CreateConVar("sm_tf2nades_frag_demo", "2", "number of frag nades given to demo men", 0, true, 0.0, true, 10.0);
        cvFragNum[MEDIC] = CreateConVar("sm_tf2nades_frag_medic", "2", "number of frag nades given to medics", 0, true, 0.0, true, 10.0);
        cvFragNum[HEAVY] = CreateConVar("sm_tf2nades_frag_heavy", "2", "number of frag nades given to heavys", 0, true, 0.0, true, 10.0);
        cvFragNum[PYRO] = CreateConVar("sm_tf2nades_frag_pyro", "2", "number of frag nades given to pyros", 0, true, 0.0, true, 10.0);
        cvFragNum[SPY] = CreateConVar("sm_tf2nades_frag_spy", "2", "number of frag nades given to spys", 0, true, 0.0, true, 10.0);
        cvFragNum[ENGIE] = CreateConVar("sm_tf2nades_frag_engineer", "2", "number of frag nades given to engineers", 0, true, 0.0, true, 10.0);
    }
    else if (GameType == dod)
    {
        HookEvent("dod_round_start", MainEvents);
        HookEvent("dod_round_active", MainEvents);
        HookEvent("dod_restart_round", MainEvents);
        HookEvent("dod_warmup_begins", MainEvents);
        HookEvent("dod_warmup_ends", MainEvents);

        HookEvent("dod_round_win", RoundEnd, EventHookMode_PostNoCopy);
        HookEvent("dod_game_over", RoundEnd, EventHookMode_PostNoCopy);

        cvNadeType[RIFLEMAN] = CreateConVar("sm_tf2nades_rifleman_type", "3", "type of special nades given to riflemen (0=none, 3=Nail, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[ASSAULT] = CreateConVar("sm_tf2nades_assault_type", "7", "type of special nades given to assault (0=none, 7=Napalm, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[SUPPORT] = CreateConVar("sm_tf2nades_support_type", "8", "type of special nades given to support (0=none, 8=Hallucination, 5=Health, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[DODSNIPER] = CreateConVar("sm_tf2nades_sniper_type", "9", "type of special nades given to snipers (0=none, 9=Emp, 1=Concussion, 2=Beartrap, 10=Bomblet, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[MG] = CreateConVar("sm_tf2nades_mg_type", "4", "type of special nades given to machine gunners (0=none, 4=Mirv, 6=Mirv, etc)", 0, true, 0.0, true, 11.0);
        cvNadeType[ROCKETMAN] = CreateConVar("sm_tf2nades_rocket_type", "12", "type of special nades given to rocket men (0=none, 11=Smoke, 12=Gas, 13=Drone, 14=Frag, etc)", 0, true, 0.0, true, 11.0);

        cvFragNum[RIFLEMAN] = CreateConVar("sm_tf2nades_frag_rifleman", "2", "number of frag nades given to riflemen", 0, true, 0.0, true, 10.0);
        cvFragNum[ASSAULT] = CreateConVar("sm_tf2nades_frag_assault", "2", "number of frag nades given to assault", 0, true, 0.0, true, 10.0);
        cvFragNum[SUPPORT] = CreateConVar("sm_tf2nades_frag_support", "2", "number of frag nades given to support", 0, true, 0.0, true, 10.0);
        cvFragNum[DODSNIPER] = CreateConVar("sm_tf2nades_frag_sniper", "2", "number of frag nades given to snipers", 0, true, 0.0, true, 10.0);
        cvFragNum[MG] = CreateConVar("sm_tf2nades_frag_mg", "2", "number of frag nades given to machine gunners", 0, true, 0.0, true, 10.0);
        cvFragNum[ROCKETMAN] = CreateConVar("sm_tf2nades_frag_rocket", "2", "number of frag nades given to rocket men", 0, true, 0.0, true, 10.0);
    }
    else //if (GameType == cstrike || GameType == csgo)
    {
        HookEvent("round_start", MainEvents);
        HookEvent("round_freeze_end", MainEvents);
        HookEvent("round_end", RoundEnd, EventHookMode_PostNoCopy);
        HookEvent("game_end", RoundEnd, EventHookMode_PostNoCopy);

        cvNadeType[0] = CreateConVar("sm_tf2nades_type", "7", "type of special nades given by default (0=none, 1=Concussion, 2=Beartrap, 3=Nail, 4=Mirv, 5=Health, 6=Mirv, 7=Napalm, 8=Hallucination, 9=Emp, 10=Bomblet, 11=Smoke, 12=Gas, 13=Drone, 14=Frag)", 0, true, 0.0, true, 11.0);
        cvFragNum[0] = CreateConVar("sm_tf2nades_frag", "2", "number of frag nades given by default", 0, true, 0.0, true, 10.0);
    }

    // convars
    cvWaitPeriod = CreateConVar("sm_tf2nades_waitperiod", "1", "server waits for players on map start (1=yes 0=no)");
    cvShowHelp = CreateConVar("sm_tf2nades_showhelp", "0", "show help link at player spawn (until they say !stop) (1=yes 0=no)");
    cvHelpLink = CreateConVar("sm_tf2nades_helplink", "http://www.tf2nades.com/motd/plugin/tf2nades.1.0.0.6.html", "web page with info on the TF2NADES plugin");
    cvAnnounce = CreateConVar("sm_tf2nades_announce", "1", "show what keys to bind when players connect (1=yes 0=no)");
    cvCountdown = CreateConVar("sm_tf2nades_countdown", "3", "start a countdown when a nade is primed? (0=none 1=display 2=tick 3=display&tick)");
    cvEmpRadius = CreateConVar("sm_tf2nades_emp_radius", "384", "radius for emp nade", 0, true, 1.0, true, 2048.0);
    cvEmpNum = CreateConVar("sm_tf2nades_emp", "3", "number of emp nades given", 0, true, 0.0, true, 10.0); 
    cvHallucDamage = CreateConVar("sm_tf2nades_halluc_damage", "5", "damage done by hallucination nade");
    cvHallucDelay = CreateConVar("sm_tf2nades_hallucination_time", "5.0", "delay in seconds that effects last", 0, true, 1.0, true, 10.0);  
    cvHallucRadius = CreateConVar("sm_tf2nades_hallucination_radius", "256", "radius for hallucination nade", 0, true, 1.0, true, 2048.0);
    cvHallucNum = CreateConVar("sm_tf2nades_hallucination", "3", "number of hallucination nades given", 0, true, 0.0, true, 10.0); 
    cvNapalmDamage = CreateConVar("sm_tf2nades_napalm_damage", "25", "initial damage for napalm nade", 0, true, 1.0, true, 500.0);
    cvNapalmRadius = CreateConVar("sm_tf2nades_napalm_radius", "256", "radius for napalm nade", 0, true, 1.0, true, 2048.0);
    cvNapalmNum = CreateConVar("sm_tf2nades_napalm", "2", "number of napalm nades given", 0, true, 0.0, true, 10.0); 
    cvHealthDelay = CreateConVar("sm_tf2nades_health_delay", "5.0", "delay in seconds before nade explodes", 0, true, 1.0, true, 10.0);
    cvHealthRadius = CreateConVar("sm_tf2nades_health_radius", "256", "radius for health nade", 0, true, 1.0, true, 2048.0);
    cvHealthNum = CreateConVar("sm_tf2nades_health", "2", "number of health nades given", 0, true, 0.0, true, 10.0); 
    cvMirvSpread = CreateConVar("sm_tf2nades_mirv_spread", "384.0", "spread of secondary explosives (max speed)", 0, true, 1.0, true, 2048.0);  
    cvMirvDamage2 = CreateConVar("sm_tf2nades_mirv_damage2", "50.0", "damage done by secondary explosion of mirv nade", 0, true, 1.0, true, 500.0); 
    cvMirvDamage1 = CreateConVar("sm_tf2nades_mirv_damage1", "25.0", "damage done by main explosion of mirv nade", 0, true, 1.0, true, 500.0);
    cvMirvRadius = CreateConVar("sm_tf2nades_mirv_radius", "128", "radius for demo's nade", 0, true, 1.0, true, 2048.0);
    cvMirvNum = CreateConVar("sm_tf2nades_mirv", "2", "number of MIRV nades given", 0, true, 0.0, true, 10.0); 
    cvNailDamageExplode = CreateConVar("sm_tf2nades_nail_explodedamage", "100.0", "damage done by final explosion", 0, true, 1.0, true,1000.0);
    cvNailDamageNail = CreateConVar("sm_tf2nades_nail_naildamage", "8.0", "damage done by nail projectile", 0, true, 1.0, true, 500.0);
    cvNailRadius = CreateConVar("sm_tf2nades_nail_radius", "256", "radius for nail nade", 0, true, 1.0, true, 2048.0);
    cvNailNum = CreateConVar("sm_tf2nades_nail", "2", "number of nail nades given", 0, true, 0.0, true, 10.0);
    cvConcDamage = CreateConVar("sm_tf2nades_conc_damage", "10", "damage done by concussion nade");
    cvConcForce = CreateConVar("sm_tf2nades_conc_force", "750", "force applied by concussion nade");
    cvConcRadius = CreateConVar("sm_tf2nades_conc_radius", "256", "radius for concussion nade", 0, true, 1.0, true, 2048.0);
    cvConcNum = CreateConVar("sm_tf2nades_conc", "3", "number of concussion nades given", 0, true, 0.0, true, 10.0);
    cvBombNum = CreateConVar("sm_tf2nades_bomblet", "2", "number of bomblets given", 0, true, 0.0, true, 10.0); 
    cvBombRadius = CreateConVar("sm_tf2nades_bomblet_radius", "128", "radius for bomblets", 0, true, 1.0, true, 2048.0);
    cvBombDamage = CreateConVar("sm_tf2nades_bomblet_damage", "50.0", "damage done by bomblets", 0, true, 1.0, true, 500.0);    
    cvTrapRadius = CreateConVar("sm_tf2nades_trap_radius", "128", "radius for beartrap", 0, true, 1.0, true, 2048.0);
    cvTrapDamage = CreateConVar("sm_tf2nades_trap_damage", "10", "damage done by beartrap");
    cvTrapNum = CreateConVar("sm_tf2nades_trap", "2", "number of traps given", 0, true, 0.0, true, 10.0); 
    cvTrapDelay = CreateConVar("sm_tf2nades_trap_time", "5.0", "delay in seconds that effects last", 0, true, 1.0, true, 10.0); 
    cvFragDamage = CreateConVar("sm_tf2nades_frag_damage", "100", "damage done by concussion nade");
    cvFragRadius = CreateConVar("sm_tf2nades_frag_radius", "256", "radius for concussion nade", 0, true, 1.0, true, 2048.0);
    cvSmokeDelay = CreateConVar("sm_tf2nades_smoke_time", "8.0", "delay in seconds that smoke lasts", 0, true, 1.0, true, 10.0);    
    cvSmokeRadius = CreateConVar("sm_tf2nades_smoke_radius", "256", "radius for smoke nade", 0, true, 1.0, true, 2048.0);
    cvSmokeNum = CreateConVar("sm_tf2nades_smoke", "3", "number of smoke nades given", 0, true, 0.0, true, 10.0); 
    cvGasDamage = CreateConVar("sm_tf2nades_gas_damage", "100", "damage done by gas nade");
    cvGasDelay = CreateConVar("sm_tf2nades_gas_time", "8.0", "delay in seconds that gas lasts", 0, true, 1.0, true, 10.0);  
    cvGasRadius = CreateConVar("sm_tf2nades_gas_radius", "256", "radius for gas nade", 0, true, 1.0, true, 2048.0);
    cvGasNum = CreateConVar("sm_tf2nades_gas", "3", "number of gas nades given", 0, true, 0.0, true, 10.0); 
    cvDroneRadius = CreateConVar("sm_tf2nades_drone_radius", "256", "radius for targetting drone", 0, true, 1.0, true, 2048.0);
    cvDroneDamage = CreateConVar("sm_tf2nades_drone_damage", "50", "damage bonus done by targetting drone");    

    AutoExecConfig(true, "plugin.ztf2nades");

    CreateConVar("sm_tf2nades_version", PLUGIN_VERSION, "TF2NADES version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    // commands
    RegConsoleCmd("+nade1", Command_Nade1);
    RegConsoleCmd("-nade1", Command_UnNade1);
    RegConsoleCmd("+nade2", Command_Nade2);
    RegConsoleCmd("-nade2", Command_UnNade2);
    
    RegConsoleCmd("sm_stop", Command_Stop, "stop the info panel from showing");
    RegConsoleCmd("sm_nades", Command_NadeInfo, "view info on tf2nades plugin");

    RegConsoleCmd("say",SayCommand);
    RegConsoleCmd("say_team",SayCommand);
    
    // misc setup
    LoadTranslations("tf2nades.phrases");

    #if defined SOURCECRAFT
        m_SourceCraftAvailable = LibraryExists("SourceCraft");
    #endif
}

#if defined SOURCECRAFT
public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "SourceCraft"))
    {
        if (!m_SourceCraftAvailable)
            m_SourceCraftAvailable = true;
    }
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "SourceCraft"))
        m_SourceCraftAvailable = false;
}
#endif

public OnMapStart()
{
    // initialize model for nades (until class is chosen)
    gnSpeed = 100.0;
    gnDelay = 2.0;

    #if !defined _ResourceManager_included
        // Setup trie to keep track of precached sounds
        if (g_soundTrie == INVALID_HANDLE)
            g_soundTrie = CreateTrie();
        else
            ClearTrie(g_soundTrie);
    #endif

    // precache models
    SetupModel(MDL_RING_MODEL, gRingModel);
    SetupModel(MDL_NAPALM_SPRITE, gNapalmSprite);
    SetupModel(MDL_BEAM_SPRITE, gBeamSprite);
    SetupModel(MDL_EMP_SPRITE, gEmpSprite);
    SetupModel(MDL_SMOKE_SPRITE, gSmokeSprite);
    SetupModel(MDL_EXPLOSION_SPRITE, gExplosionSprite);

    SetupNadeModels();
    
    // precache sounds
    SetupSound(SND_THROWNADE, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_FRAG, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_CONC, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_NAIL, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_NAIL_EXPLODE, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_NAIL_SHOOT1, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_NAIL_SHOOT2, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_NAIL_SHOOT3, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_MIRV1, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_MIRV2, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_HEALTH, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_NAPALM, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_HALLUC, true, DONT_DOWNLOAD);
    SetupSound(SND_NADE_EMP, true, DONT_DOWNLOAD);

    SetupSound(SND_CHARGED, true, DONT_DOWNLOAD);
    SetupSound(SND_IMPACT, true, DONT_DOWNLOAD);
    SetupSound(SND_SAPPER, true, DONT_DOWNLOAD);

    for(new i=0;i<sizeof(sndPain);i++)
      SetupSound(sndPain[i], true, DONT_DOWNLOAD);
    
    // reset status
    gCanRun = false;
    gWaitOver = false;
    gMapStart = GetEngineTime();
    MainEvents(INVALID_HANDLE, "map_start", true);
}

public OnConfigsExecuted()
{
    TagsCheck("tf2nades");
}

public OnMapEnd()
{
    CleanupDamageEntity();
}

public OnClientPutInServer(client)
{
    FireTimers(client);
    
    // kill hooks
    gKilledBy[client]=0;
    gKillTime[client] = 0.0;
    gKillWeapon[client][0]='\0';

    // Reset native flags
    gSpecialType[client] = DefaultNade;
    gCanRestock[client] = false;
    gRemaining1[client] = 0;
    gRemaining2[client] = 0;
    gAllowed1[client] = 0;
    gAllowed2[client] = 0;

    #if defined SOURCECRAFT
        gCategory[client] = DamageFrom_None;
    #endif

    if (GetConVarInt(cvShowHelp)==1)
    {
        gStopInfoPanel[client] = false;
    }
    else
    {
        gStopInfoPanel[client] = true;
    }

    // Reset the targeted flags
    for (new index=1;index<=MaxClients;index++)
    {
        if (gTargeted[index] == client)
            gTargeted[index] = 0;
    }

    if (!gNativeOverride && GetConVarInt(cvAnnounce)==1)
        CreateTimer(45.0, Timer_Anounce, client);
}

public Action:Timer_Anounce(Handle:timer, any:client)
{
    if (IsClientConnected(client) && IsClientInGame(client))
    {
        if (!gNativeOverride && GetConVarInt(cvAnnounce)==1)
        {
            PrintToChat(client, "[SM] Bind a key to +nade1 to throw a frag nade");
            PrintToChat(client, "[SM] Bind a key to +nade2 to throw a special nade");
            PrintToChat(client, "[SM] Type !nade for more information");
        }
    }
}

public Action:MainEvents(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (StrEqual(name,"dod_warmup_begins", false))
    {
        gCanRun = false;
        gWaitOver = false;
    }
    else if (StrEqual(name,"dod_warmup_ends", false))
    {
        gCanRun = true;
        gWaitOver = true;
    }
    else
    {
        if (GetConVarInt(cvWaitPeriod)==1)
        {
            if (StrEqual(name,"teamplay_restart_round", false))
            {
                gCanRun = true;
                gWaitOver = true;
            }
            else if (StrEqual(name,"round_freeze_end", false))
            {
                gCanRun = true;
                gWaitOver = true;
            }
        }
        else
        {
            if (!StrEqual(name, "map_start"))
            {
                gCanRun = true;
                gWaitOver = true;
            }
        }

        if (gWaitOver)
        {
            if (StrEqual(name, "teamplay_round_start"))
            {
                gCanRun = false;
            }
            else if (StrEqual(name, "teamplay_round_active"))
            {
                gCanRun = true;
            }
            else if (StrEqual(name, "arena_round_start"))
            {
                gCanRun = true;
            }
            else if (StrEqual(name, "dod_round_start"))
            {
                gCanRun = true;
            }
            else if (StrEqual(name, "round_start"))
            {
                gCanRun = true;
            }
        }
    }

    // reset players
    for (new i=1;i<=MAX_PLAYERS;i++)
    {
        // nades
        gNade[i]=INVALID_ENT_REFERENCE;
        gTriggerTimer[i] = false;
        
        // kill hooks
        gKilledBy[i]=0;
        gKillTime[i] = 0.0;
        gKillWeapon[i][0]='\0';
    }

    // Reset the all the targeted flags
    for (new index=1;index<=MaxClients;index++)
            gTargeted[index] = 0;

    return Plugin_Continue;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    gCanRun = false;
}


public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    gHolding[client]=HoldNone;
    
    if (!gStopInfoPanel[client])
    {
        decl String:helplink[512]; helplink[0] = '\0';
        GetConVarString(cvHelpLink, helplink, sizeof(helplink));
        ShowMOTDPanel(client, "TF2NADES", helplink, MOTDPANEL_TYPE_URL);
    }

    if (!gCanRun)
    {
        if (GetEngineTime() > (gMapStart + 60.0))
        {
            gCanRun = true;
        }
        else
        {
            return Plugin_Continue;
        }
    }

    // client info
    decl String:clientname[32]; clientname[0] = '\0';
    Format(clientname, sizeof(clientname), "tf2player%d", client);
    DispatchKeyValue(client, "targetname", clientname);

    SetupNade(GiveFullNades(client), GetClientTeam(client), true);

    FireTimers(client);
    gNadeTimer[client]=INVALID_HANDLE;

    // Remove any leftover nade entities for this player
    decl String:edictname[128];
    new ents = GetMaxEntities();
    for (new i=MaxClients+1; i<ents; i++)
    {
        if (IsValidEdict(i) && IsValidEntity(i))
        {
            if (GetEdictClassname(i, edictname, sizeof(edictname)) &&
                (StrEqual(edictname, "prop_physics") || StrEqual(edictname, "prop_dynamic")))
            {
                if (GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity")==client)
                {
                    GetEntPropString(i, Prop_Data, "m_ModelName", edictname, sizeof(edictname));
                    if (strncmp(edictname, "models/weapons/nades/duke1", 26) == 0)
                    {
                        AcceptEntityInput(i, "kill");
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action:PlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
    if (!gTargetOverride)
    {
        new victim = GetClientOfUserId(GetEventInt(event,"userid"));
        if (victim > 0)
        {
            new client = gTargeted[victim];
            if (client > 0)
            {
                new damage = GetConVarInt(cvDroneDamage);
                NadeHurtPlayer(victim, client, damage, TargetingDrone, "tf2nade_drone");
                return Plugin_Changed;
            }
        }
    }
    return Plugin_Continue;
}

public EntityOutput_OnAnimationBegun(const String:output[], caller, activator, Float:delay)
{
    if (IsValidEntity(caller))
    {
        decl String:modelname[128]; modelname[0] = '\0';
        GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
        if (StrEqual(modelname, "models/props_gameplay/resupply_locker.mdl"))
        {
            new Float:pos[3];
            GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
            FindPlayersInRange(pos, 128.0, 0, -1, false, -1);
            for (new j=1;j<=MaxClients;j++)
            {
                if (PlayersInRange[j]>0.0)
                {
                    if (gCanRestock[j])
                        GiveFullNades(j);
                }
            }
        }
    }
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

    new client;
    client = GetClientOfUserId(GetEventInt(event, "userid"));
    gRemaining1[client] = 0;
    gRemaining2[client] = 0;
    gHolding[client] = HoldNone;
    
    new weaponid = GetEventInt(event, "weaponid");
    
    /*
    PrintToServer("userid %d", GetEventInt(event, "userid"));
    PrintToServer("attacker %d", GetEventInt(event, "attacker"));
    GetEventString(event, "weapon", tName, sizeof(tName));
    PrintToServer("weapon %s", tName);
    PrintToServer("weaponid %d", GetEventInt(event, "weaponid"));
    PrintToServer("damagebits %d", GetEventInt(event, "damagebits"));
    PrintToServer("dominated %d", GetEventInt(event, "dominated"));
    PrintToServer("assister_dominated %d", GetEventInt(event, "assister_dominated"));
    PrintToServer("revenge %d", GetEventInt(event, "revenge"));
    PrintToServer("assister_revenge %d", GetEventInt(event, "assister_revenge"));
    GetEventString(event, "weapon_logclassname", tName, sizeof(tName));
    PrintToServer("weapon_logclassname %s", tName);
    */
    
    if (gKilledBy[client]>0 && weaponid==0)
    {
        if ( (GetEngineTime()-gKillTime[client]) < 0.5)
        {
            SetEventInt(event, "attacker", gKilledBy[client]);
            SetEventInt(event, "weaponid", 100);
            SetEventString(event, "weapon", gKillWeapon[client]);
            SetEventString(event, "weapon_logclassname", gKillWeapon[client]);
        }
    }
    
    // kill hooks
    gKilledBy[client]=0;
    gKillTime[client] = 0.0;
    gKillWeapon[client][0]='\0';
    
    return Plugin_Continue;
}

public Action:ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    //new class = GetEventInt(event, "class");
    gRemaining1[client] = 0;
    gRemaining2[client] = 0;
    gHolding[client] = HoldNone;
    
    FireTimers(client);
}

public Action:Command_Nade1(client, args) 
{
    if (gHolding[client]>HoldNone)
        return Plugin_Handled;
    
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Handled;
    
    if (GameType == tf2)
    {
        // not while cloaked, taunting or bonked
        if (TF2_IsPlayerCloaked(client) || TF2_IsPlayerTaunting(client) || TF2_IsPlayerBonked(client))
            return Plugin_Handled;
    }

    SetupHudMsg(3.0);
    if (!gCanRun || IsEntLimitReached(.client=client, .message="unable to create nade"))
    {
        ShowHudText(client, 1, "%t", "WaitingPeriod");
        return Plugin_Handled;
    }

    if (gTriggerTimer[client])
    {
        gTriggerTimer[client] = false;
        gNadeTimer[client]=INVALID_HANDLE;
    }

    if (gNadeTimer[client]==INVALID_HANDLE)
    {
        if (gRemaining1[client]>0)
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);

            ThrowNade(client, true, HoldFrag, FragNade);
            gRemaining1[client]--;
            ShowHudText(client, 1, "%t", "Nades1Remaining", gRemaining1[client]);
        }
        else
        {
            ShowHudText(client, 1, "%t", "NoNades1");
        }
    }
    else
    {
        ShowHudText(client, 1, "%t", "OnlyOneNade");
    }
    return Plugin_Handled;
}

public Action:Command_UnNade1(client, args)
{
    if (gHolding[client]!=HoldFrag)
        return Plugin_Handled;
    
    if (gNadeTimer[client]!=INVALID_HANDLE)
        ThrowNade(client, false, HoldFrag, FragNade);

    return Plugin_Handled;
}

public Action:Command_Nade2(client, args) 
{
    if (gHolding[client]>HoldNone)
        return Plugin_Handled;
    
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Handled;
    
    if (GameType == tf2)
    {
        // not while cloaked, taunting or bonked
        if (TF2_IsPlayerCloaked(client) || TF2_IsPlayerTaunting(client) || TF2_IsPlayerBonked(client))
            return Plugin_Handled;
    }
    
    SetupHudMsg(3.0);
    if (!gCanRun || IsEntLimitReached(.client=client, .message="unable to create nade"))
    {
        ShowHudText(client, 1, "%t", "WaitingPeriod");
        return Plugin_Handled;
    }
    
    if (gTriggerTimer[client])
    {
        gTriggerTimer[client] = false;
        gNadeTimer[client]=INVALID_HANDLE;
    }

    if (gNadeTimer[client]==INVALID_HANDLE)
    {
        if (gRemaining2[client]>0)
        {
            if (TF2_IsPlayerDisguised(client))
                TF2_RemovePlayerDisguise(client);

            ThrowNade(client, true, HoldSpecial, DefaultNade);
            gRemaining2[client]--;
            ShowHudText(client, 1, "%t", "Nades2Remaining", gRemaining2[client]);
        }
        else
        {
            ShowHudText(client, 1, "%t", "NoNades2");
        }
    }
    else
    {
        ShowHudText(client, 1, "%t", "OnlyOneNade");
    }
    return Plugin_Handled;
}

public Action:Command_UnNade2(client, args)
{
    if (gHolding[client]!=HoldSpecial)
        return Plugin_Handled;
    
    if (gNadeTimer[client]!=INVALID_HANDLE)
        ThrowNade(client, false, HoldSpecial, DefaultNade);

    return Plugin_Handled;
}

public Action:Command_Stop(client, args) 
{
    gStopInfoPanel[client] = true;
    return Plugin_Handled;
}

public Action:Command_NadeInfo(client, args) 
{
    decl String:helplink[512]; helplink[0] = '\0';
    GetConVarString(cvHelpLink, helplink, sizeof(helplink));
    ShowMOTDPanel(client, "TF2NADES", helplink, MOTDPANEL_TYPE_URL);
    return Plugin_Handled;
}

GetNade(client)
{
    // spawn the nade entity if required
    new bool:makenade = false;
    new nade = EntRefToEntIndex(gNade[client]);
    if (nade > 0 && IsValidEntity(nade))
    {
        GetEntPropString(nade, Prop_Data, "m_iName", tName, sizeof(tName));
        makenade = (strncmp(tName,"tf2nade",7) != 0);
    }
    else
    { 
        makenade = true;
    }

    if (makenade)
    {
        nade = CreateEntityByName("prop_physics");
        if (nade > 0 && IsValidEntity(nade))
        {
            SetEntPropEnt(nade, Prop_Data, "m_hOwnerEntity", client);
            SetEntityModel(nade, gnModel);
            SetEntityMoveType(nade, MOVETYPE_VPHYSICS);
            SetEntProp(nade, Prop_Data, "m_CollisionGroup", 1);
            SetEntProp(nade, Prop_Send, "m_usSolidFlags", 16);
            DispatchSpawn(nade);
            Format(tName, sizeof(tName), "tf2nade%d", nade);
            DispatchKeyValue(nade, "targetname", tName);
            //SetEntPropString(nade, Prop_Data, "m_iName", "tf2nade");
            TeleportEntity(nade, gHoldingArea, NULL_VECTOR, NULL_VECTOR);
            gNade[client] = EntIndexToEntRef(nade);
        }
        else
        {
            LogError("Unable to create prop_physics entity");
            gNade[client] = INVALID_ENT_REFERENCE;
            nade = -1;
        }
    }
    return nade;
}

ThrowNade(client, bool:Setup=false, HoldType:hold=HoldSpecial, NadeType:type=DefaultNade)
{
    new team = GetClientTeam(client);
    if (team < 2) // dont allow spectators to throw nades!
        return;

    new nade;
    if (Setup)
    {
        // save priming status
        gHolding[client]=hold;
        
        // reset
        gNadeTimer[client] = INVALID_HANDLE;
        //FireTimers(client);

        // setup nade if it doesn't exist
        nade = GetNade(client);

    }
    else
        nade = EntRefToEntIndex(gNade[client]);

    // check that nade still exists in world
    if (nade > 0 && IsValidEntity(nade))
    {
        // get nade type
        new bool:special = (hold >= HoldSpecial);
        if (special && type <= DefaultNade) // setup nade variables based on player class
        {
            type = (gNativeOverride) ? gSpecialType[client] : DefaultNade;
            if (type <= DefaultNade) // setup nade variables based on player class
            {
                new class = 0;
                switch (GameType)
                {
                    case tf2: class = _:TF2_GetPlayerClass(client);
                    case dod: class = _:DOD_GetPlayerClass(client); 
                }
                new Handle:typeVar = cvNadeType[class];
                type = typeVar ? (NadeType:GetConVarInt(typeVar)) : (NadeType:class);
            }
        }

        SetupNade(type, team, special);

        if (Setup)
        {
            new Handle:pack;
            new userid = GetClientUserId(client);
            gNadeTimer[client] = CreateDataTimer(gnDelay, NadeExplode, pack);
            WritePackCell(pack, userid);
            WritePackCell(pack, client);
            WritePackCell(pack, team);
            WritePackCell(pack, gNade[client]);
            WritePackCell(pack, _:type);
            WritePackCell(pack, _:special);

            if (GetConVarInt(cvCountdown) != 0)
            {
                gCountdown[client] = RoundToNearest(gnDelay / 0.5);
                TriggerTimer(CreateTimer(0.5, NadeCountdown, userid, TIMER_REPEAT));
            }
        }
        else
        {
            // reset priming status
            gHolding[client] = HoldNone;

            // get position and angles
            new Float:startpt[3];
            GetClientEyePosition(client, startpt);
            new Float:angle[3];
            new Float:speed[3];
            new Float:playerspeed[3];
            GetClientEyeAngles(client, angle);
            GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
            speed[2]+=0.2;
            speed[0]*=gnSpeed; speed[1]*=gnSpeed; speed[2]*=gnSpeed;

            GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
            AddVectors(speed, playerspeed, speed);

            SetEntityModel( nade, gnModel);
            Format(gnSkin, sizeof(gnSkin), "%d", team-2);
            DispatchKeyValue(nade, "skin", gnSkin);
            angle[0] = GetRandomFloat(-180.0, 180.0);
            angle[1] = GetRandomFloat(-180.0, 180.0);
            angle[2] = GetRandomFloat(-180.0, 180.0);
            TeleportEntity(nade, startpt, angle, speed);

            if (GameType == tf2 && strlen(gnParticle)>0)
            {
                AttachParticle(nade, gnParticle, gnDelay);
            }

            PrepareAndEmitSoundToAll(SND_THROWNADE, client);
        }
    }
    else
    {
        LogError("tf2nade: player's nade not found in ThrowNade(), Setup=%d, nade=%d",
                 Setup, nade);
    }
}

public Action:NadeCountdown(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client))
    {
        new flag = GetConVarInt(cvCountdown);
        if (gHolding[client] != HoldNone)
        {
            if (flag & 1)
            {
                SetupHudMsg(3.0);
                ShowHudText(client, 1, "%d", gCountdown[client]);
            }

            if (flag & 2)
            {
                PrepareAndEmitSoundToClient(client, SND_COUNTDOWN);
            }
        }
        else
        {
            if (flag & 2)
            {
                new nade = EntRefToEntIndex(gNade[client]);
                if (nade > 0)
                    PrepareAndEmitSoundToAll(SND_THROWNADE, nade);
                else
                    return Plugin_Stop;
            }
            else
                return Plugin_Stop;
        }

        if (--gCountdown[client] > 0)
            return Plugin_Continue;
    }
    return Plugin_Stop;
}

public Action:NadeExplode(Handle:timer, Handle:pack)
{
    ResetPack(pack);
    new userid = ReadPackCell(pack);
    new client = ReadPackCell(pack);
    new team = ReadPackCell(pack);
    new nade = EntRefToEntIndex(ReadPackCell(pack));
    
    gNadeTimer[client]=INVALID_HANDLE;

    if (nade > 0 && IsValidEntity(nade))
    {
        if (GetClientOfUserId(userid) != client ||
            !IsClientInGame(client))
        {
            AcceptEntityInput(nade, "kill");
            gNade[client] = INVALID_ENT_REFERENCE;
        }
        else
        {
            new NadeType:type = NadeType:ReadPackCell(pack);
            new bool:special = bool:ReadPackCell(pack);
            ExplodeNade(client, team, type, special);
        }
    }
}

public NadeType:GiveFullNades(client)
{
    new class = 0;
    switch (GameType)
    {
        case tf2: class = _:TF2_GetPlayerClass(client);
        case dod: class = _:DOD_GetPlayerClass(client); 
    }
    if (class < 0)
        class = 0;

    new NadeType:type;
    new Handle:fragVar = cvFragNum[class];
    new Handle:typeVar = cvNadeType[class];

    if (gNativeOverride)
    {
        type = (gSpecialType[client] > DefaultNade) ? gSpecialType[client] : (typeVar ? (NadeType:GetConVarInt(typeVar)) : (NadeType:class));
        gRemaining1[client] = (gAllowed1[client] >= 0) ? gAllowed1[client] : (fragVar ? GetConVarInt(fragVar) : 2);
        gRemaining2[client] = (gAllowed2[client] >= 0) ? gAllowed2[client] : GetNumNades(type);
    }
    else
    {
        type = typeVar ? (NadeType:GetConVarInt(typeVar)) : (NadeType:class);
        gRemaining1[client] = fragVar ? GetConVarInt(fragVar) : 2;
        gRemaining2[client] = GetNumNades(type);
        gCanRestock[client] = cvRestock ? GetConVarBool(cvRestock) : false;
        gSpecialType[client] = type;
    }

    if ((gRemaining1[client] > 0 || gRemaining2[client] > 0) && IsPlayerAlive(client))
    {
        SetupHudMsg(3.0);
        ShowHudText(client, 1, "%t", "GivenNades", gRemaining1[client], gRemaining2[client]);
    }

    return type;
}

ExplodeNade(client, team, NadeType:type, bool:special)
{ 
    if (gHolding[client]>HoldNone)
    {
        ThrowNade(client, false, gHolding[client], DefaultNade);
    }

    new Float:radius;
    new Float:center[3];
    new nade = EntRefToEntIndex(gNade[client]);
    if (nade <= 0)
    {
        //LogError("Invalid nade %d in ExplodeNade()", gNade[client]);
        return;
    }

    if (!special || type >= FragNade)
    {
        new damage = GetConVarInt(cvFragDamage);
        radius = GetConVarFloat(cvFragRadius);
        GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);

        // effects
        if (GameType == tf2 &&
            !IsEntLimitReached(.client=client, .message="unable to create explode particles"))
        {
            ShowParticle(center, "ExplosionCore_MidAir", 2.0);

            PrepareAndEmitSoundToAll(SND_NADE_FRAG_TF2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                     SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
        }
        else
        {
            PrepareModel(MDL_EXPLOSION_SPRITE, gExplosionSprite, true);
            TE_SetupExplosion(center, gExplosionSprite, 2.0, 1, 4, RoundToCeil(radius), 0);
            TE_SendToAll();

            PrepareAndEmitSoundToAll(SND_NADE_FRAG, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                     SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
        }

        // player damage
        new oteam  = (team==3) ? 2 : 3;
        FindPlayersInRange(center, radius, oteam, client, true, nade);
        for (new j=1;j<=MaxClients;j++)
        {
            if (PlayersInRange[j]>0.0)
            {
                NadeHurtPlayer(j, client, damage, FragNade,
                               "tf2nade_frag", center, 3.0,
                               .explosion=true);
            }
        }
        DamageBuildings(client, center, radius, damage, nade, true);
    }
    else
    {
        switch (type)
        {
            case ConcNade:
            {
                radius = GetConVarFloat(cvConcRadius);
                new damage = GetConVarInt(cvConcDamage);
                GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);

                if (GameType == tf2 &&
                    !IsEntLimitReached(.client=client, .message="unable to create conc particles"))
                {
                    ShowParticle(center, "impact_generic_smoke", 2.0);
                }
                else
                {
                    PrepareModel(MDL_SMOKE_SPRITE, gSmokeSprite, true);
                    TE_SetupSmoke(center,gSmokeSprite,40.0,1);
                    TE_SendToAll();
                }

                PrepareAndEmitSoundToAll(SND_NADE_CONC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                         SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

                new oteam = (team==3) ? 2 : 3;
                FindPlayersInRange(center, radius, oteam, client, true, nade);
                new Float:play[3];
                new Float:playerspeed[3];
                new Float:distance;
                for (new j=1;j<=MaxClients;j++)
                {
                    if (PlayersInRange[j]>0.0)
                    {
                        GetClientAbsOrigin(j, play);
                        play[2]+=128.0;
                        SubtractVectors(play, center, play);
                        distance = GetVectorLength(play);
                        if (distance<0.01) { distance = 0.01; }
                        ScaleVector(play, 1.0/distance);
                        ScaleVector(play, GetConVarFloat(cvConcForce));
                        GetEntPropVector(j, Prop_Data, "m_vecVelocity", playerspeed);
                        playerspeed[2]=0.0;
                        AddVectors(play, playerspeed, play);
                        TeleportEntity(j, NULL_VECTOR, NULL_VECTOR, play);

                        NadeHurtPlayer(j, client, damage, type,
                                       "tf2nade_conc", center); 
                    }
                }
            }
            case BearTrap:
            {
                radius = GetConVarFloat(cvTrapRadius);
                new damage = GetConVarInt(cvTrapDamage);
                new Float:delay=GetConVarFloat(cvTrapDelay);
                GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);

                new bool:entLimitOK = !IsEntLimitReached(.client=client, .message="unable to create bear trap particles");
                if (GameType == tf2 && entLimitOK)
                {
                    ShowParticle(center, "Explosions_MA_Dustup_2", 2.0);
                }
                else
                {
                    new Float:dir[3];
                    dir[0] = 0.0;
                    dir[1] = 0.0;
                    dir[2] = 2.0;
                    TE_SetupDust(center,dir,radius,100.0);
                    TE_SendToAll();
                }

                #if 0
                    if (entLimitOK)
                    {
                        SetupNade(BearTrap, team, true);
                        new ent = CreateEntityByName("prop_dynamic_override");
                        if (ent > 0 && IsValidEntity(ent))
                        {
                            SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
                            SetEntityModel(ent,gnModel);
                            SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
                            SetEntProp(ent, Prop_Send, "m_usSolidFlags", 16);
                            Format(gnSkin, sizeof(gnSkin), "%d", team-2);
                            DispatchKeyValue(ent, "skin", gnSkin);
                            Format(tName, sizeof(tName), "tf2beartrap", nade);
                            DispatchKeyValue(ent, "targetname", tName);
                            DispatchSpawn(ent);
                            TeleportEntity(ent, center, NULL_VECTOR, NULL_VECTOR);
                            SetVariantString("release");
                            AcceptEntityInput(ent, "SetAnimation");
                            //AcceptEntityInput(ent, "SetDefaultAnimation");
                            gNadeTemp[client] = EntIndexToEntRef(ent);
                        }
                    }
                #endif

                PrepareAndEmitSoundToAll(SND_NADE_TRAP, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                         SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

                new oteam = (team==3) ? 2 : 3;
                FindPlayersInRange(center, radius, oteam, client, true, nade);
                for (new j=1;j<=MaxClients;j++)
                {
                    if (PlayersInRange[j]>0.0)
                    {
                        if (NadeHurtPlayer(j, client, damage, type, "tf2nade_trap",
                                           center, .hold=true))
                        {
                            SetEntityMoveType(j,MOVETYPE_NONE); // Freeze client
                            CreateTimer(delay, ResetPlayerMotion, GetClientUserId(j));
                        }
                    }
                }
            }
            case NailNade:
            {
                radius = GetConVarFloat(cvNailRadius);
                GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);
                SetupNade(NailNade, team, true);

                new bool:entLimitOK = !IsEntLimitReached(.client=client, .message="unable to explode nail nade");
                if (GameType == tf2 && entLimitOK)
                    ShowParticle(center, "Explosions_MA_Dustup_2", 2.0);
                else
                {
                    new Float:dir[3];
                    dir[0] = 0.0;
                    dir[1] = 0.0;
                    dir[2] = 2.0;
                    TE_SetupDust(center,dir,radius,100.0);
                    TE_SendToAll();
                }

                center[2]+=32.0;

                if (entLimitOK)
                {
                    new ent = CreateEntityByName("prop_dynamic_override");
                    if (ent > 0 && IsValidEntity(ent))
                    {
                        new Float:angles[3] = {0.0,0.0,0.0};
                        SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
                        SetEntityModel(ent,gnModel);
                        SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
                        SetEntProp(ent, Prop_Send, "m_usSolidFlags", 16);
                        Format(gnSkin, sizeof(gnSkin), "%d", team-2);
                        DispatchKeyValue(ent, "skin", gnSkin);
                        Format(tName, sizeof(tName), "tf2nailnade%d", nade);
                        DispatchKeyValue(ent, "targetname", tName);
                        DispatchSpawn(ent);
                        TeleportEntity(ent, center, angles, NULL_VECTOR);
                        SetVariantString("release");
                        AcceptEntityInput(ent, "SetAnimation");
                        //AcceptEntityInput(ent, "SetDefaultAnimation");

                        PrepareAndEmitSoundToAll(SND_NADE_NAIL, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                                 SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

                        new Handle:pack;
                        new nadeRef = EntIndexToEntRef(ent);
                        new userid = GetClientUserId(client);
                        gNadeTimer2[client] = CreateDataTimer(4.5, SoldierNadeFinish, pack); 
                        gNadeTimer[client] = CreateTimer(0.2, SoldierNadeThink, pack, TIMER_REPEAT);
                        WritePackCell(pack, nadeRef);
                        WritePackCell(pack, client);
                        WritePackCell(pack, userid);
                    }
                }
            }
            case MirvNade:
            {
                new damage = GetConVarInt(cvMirvDamage1);
                radius = GetConVarFloat(cvMirvRadius);
                GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);

                new bool:entLimitOK = !IsEntLimitReached(.client=client, .message="unable to fragment mirv nade");
                if (GameType == tf2 && entLimitOK)
                {
                    ShowParticle(center, "ExplosionCore_MidAir", 2.0);

                    PrepareAndEmitSoundToAll(SND_NADE_MIRV1_TF2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                             SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
                }
                else
                {
                    PrepareModel(MDL_EXPLOSION_SPRITE, gExplosionSprite, true);
                    TE_SetupExplosion(center, gExplosionSprite, 2.0, 1, 4, RoundToCeil(radius), 0);
                    TE_SendToAll();

                    PrepareAndEmitSoundToAll(SND_NADE_MIRV1, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                             SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
                }

                new oteam = (team==3) ? 2 : 3;
                FindPlayersInRange(center, radius, oteam, client, true, nade);
                for (new j=1;j<=MaxClients;j++)
                {
                    if(PlayersInRange[j]>0.0)
                    {
                        NadeHurtPlayer(j, client, damage, type, "tf2nade_mirv",
                                       center, .explosion=true);
                    }
                }

                DamageBuildings(client, center, radius, damage, nade, true);

                if (entLimitOK)
                {
                    PrepareModel(MDL_MIRV2, g_Mirv2ModelIndex, true);

                    new Float:spread;
                    new Float:vel[3], Float:angle[3], Float:rand;
                    Format(gnSkin, sizeof(gnSkin), "%d", team-2);

                    new Handle:pack;
                    gNadeTimer[client] = CreateDataTimer(gnDelay, MirvExplode2, pack);
                    WritePackCell(pack, client);
                    WritePackCell(pack, GetClientUserId(client));
                    WritePackCell(pack, team);

                    for (new k=0;k<MIRV_PARTS;k++)
                    {
                        new ent = CreateEntityByName("prop_physics");
                        if (ent > 0 && IsValidEntity(ent))
                        {
                            SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
                            SetEntityModel(ent,MDL_MIRV2);
                            SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
                            SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
                            SetEntProp(ent, Prop_Send, "m_usSolidFlags", 16);
                            DispatchKeyValue(ent, "skin", gnSkin);
                            DispatchSpawn(ent);
                            Format(tName, sizeof(tName), "tf2mirv%d", ent);
                            DispatchKeyValue(ent, "targetname", tName);
                            rand = GetRandomFloat(0.0, 314.0);
                            spread = GetConVarFloat(cvMirvSpread) * GetRandomFloat(0.2, 1.0);
                            vel[0] = spread*Sine(rand);
                            vel[1] = spread*Cosine(rand);
                            vel[2] = spread;
                            GetVectorAngles(vel, angle);
                            TeleportEntity(ent, center, angle, vel);
                        }
                        WritePackCell(pack, EntIndexToEntRef(ent));
                    }
                }
            }
            case HealthNade:
            {
                radius = GetConVarFloat(cvHealthRadius);
                GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);

                new beamcolor[4];
                if (team==2)
                {
                    beamcolor[0]=255; beamcolor[1]=0; beamcolor[2]=0; beamcolor[3]=255;
                }
                else
                {
                    beamcolor[0]=0; beamcolor[1]=0; beamcolor[2]=255; beamcolor[3]=255;
                }

                PrepareModel(MDL_RING_MODEL, gRingModel, true);
                TE_SetupBeamRingPoint(center,2.0,radius,gRingModel,gRingModel,
                                      0,1,0.25,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
                TE_SendToAll(0.0);
                TE_SetupBeamRingPoint(center,2.0,radius,gRingModel,gRingModel,
                                      0,1,0.50,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
                TE_SendToAll(0.0);
                TE_SetupBeamRingPoint(center,2.0,radius,gRingModel,gRingModel,
                                      0,1,0.75,4.0,0.0,beamcolor,0,FBEAM_FADEOUT);
                TE_SendToAll(0.0);

                PrepareAndEmitSoundToAll(SND_NADE_HEALTH, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                         SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

                new health;
                new bool:entLimitOK = !IsEntLimitReached(.client=client, .message="unable to create health particles");
                FindPlayersInRange(center, radius, team, client, true, nade);
                for (new j=1;j<=MaxClients;j++)
                {
                    if (PlayersInRange[j]>0.0)
                    {
                        health = GetEntProp(j, Prop_Data, "m_iMaxHealth");
                        if (GetClientHealth(j)<health)
                        {
                            SetEntityHealth(j, health);
                            if (entLimitOK)
                                ShowHealthParticle(j);
                        }
                    }
                }
            }
            case HeavyNade:
            {
                ExplodeNade(client, team, MirvNade, special);
                return;
            }
            case NapalmNade:
            {
                radius = GetConVarFloat(cvNapalmRadius);
                new damage = GetConVarInt(cvNapalmDamage);
                GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);

                if (GameType == tf2 &&
                    !IsEntLimitReached(.client=client, .message="unable to create napalm explosion"))
                {
                    ShowParticle(center, "ExplosionCore_MidAir", 2.0);
                }
                else
                {
                    PrepareModel(MDL_EXPLOSION_SPRITE, gExplosionSprite, true);
                    TE_SetupExplosion(center, gExplosionSprite, 2.0, 1, 4, RoundToCeil(radius), 0);
                    TE_SendToAll();
                }

                PrepareModel(MDL_NAPALM_SPRITE, gNapalmSprite, true);
                TE_SetupExplosion(center, gNapalmSprite, 2.0, 1, 4, RoundToCeil(radius), 0);
                TE_SendToAll();

                PrepareAndEmitSoundToAll(SND_NADE_NAPALM, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                         SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

                new oteam = (team==3) ? 2 : 3;
                FindPlayersInRange(center, radius, oteam, client, true, nade);
                for (new j=1;j<=MaxClients;j++)
                {
                    if (PlayersInRange[j]>0.0)
                    {
                        new health = GetClientHealth(j);
                        if (NadeHurtPlayer(j, client, (damage>=health) ? health-1 : damage,
                                           type, "tf2nade_napalm", center, 2.0, true, true))
                        {
                            if (GameType == tf2 && j != client)
                                TF2_IgnitePlayer(j, client);
                            #if defined _dod_ignite_included
                            else if (GameType == dod)
                                DOD_IgniteEntity(j, 10.0);
                            #endif
                            else
                                IgniteEntity(j, 10.0);
                        }
                    }
                }
                DamageBuildings(client, center, radius, damage, nade, true);
            }
            case HallucNade:
            {
                radius = GetConVarFloat(cvHallucRadius);
                new damage = GetConVarInt(cvHallucDamage);
                new Float:delay = GetConVarFloat(cvHallucDelay);
                GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);

                if (GameType == tf2 &&
                    !IsEntLimitReached(.client=client, .message="unable to create hallucination particles"))
                {
                    ShowParticle(center, "ExplosionCore_sapperdestroyed", 2.0);

                    PrepareAndEmitSoundToAll(SND_NADE_HALLUC_TF2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                             SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
                }
                else
                {
                    TE_SetupSparks(center, NULL_VECTOR, 2, 1);
                    TE_SendToAll();

                    PrepareModel(MDL_SMOKE_SPRITE, gSmokeSprite, true);
                    TE_SetupSmoke(center,gSmokeSprite,40.0,1);
                    TE_SendToAll();

                    PrepareAndEmitSoundToAll(SND_NADE_HALLUC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                             SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
                }

                new oteam = (team==3) ? 2 : 3;
                FindPlayersInRange(center, radius, oteam, client, true, nade);
                new rand1;
                new Float:angles[3];
                for (new j=1;j<=MaxClients;j++)
                {
                    if (PlayersInRange[j]>0.0)
                    {
                        GetClientEyeAngles(j, angles);
                        rand1 = GetRandomInt(0, 1);
                        if (rand1==0)
                        {
                            angles[0] = -90.0;
                        }
                        else
                        {
                            angles[0] = 90.0;
                        }
                        angles[2] = GetRandomFloat(-45.0, 45.0);
                        TeleportEntity(j, NULL_VECTOR, angles, NULL_VECTOR);    
                        ClientCommand(j, "r_screenoverlay effects/tp_eyefx/tp_eyefx");
                        CreateTimer(delay, ResetPlayerView, GetClientUserId(j));
                        NadeHurtPlayer(j, client, damage, type, "tf2nade_halluc",
                                       center, .halluc=true); 
                    }
                }
            }
            case EmpNade:
            {
                radius = GetConVarFloat(cvEmpRadius);
                GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);

                new bool:entLimitOK = !IsEntLimitReached(.client=client, .message="unable to create emp particles");
                if (GameType == tf2 && entLimitOK)
                    ShowParticle(center, "ExplosionCore_sapperdestroyed", 2.0);
                else
                {
                    TE_SetupSparks(center, NULL_VECTOR, 2, 1);
                    TE_SendToAll();

                    PrepareModel(MDL_SMOKE_SPRITE, gSmokeSprite, true);
                    TE_SetupSmoke(center,gSmokeSprite,40.0,1);
                    TE_SendToAll();
                }

                PrepareAndEmitSoundToAll(SND_NADE_EMP, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                         SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

                new oteam = (team==3) ? 2 : 3;
                FindPlayersInRange(center, radius, oteam, client, false, -1);
                new beamcolor[4];
                if (team==2)
                {
                    beamcolor[0]=255;beamcolor[1]=0;beamcolor[2]=0;beamcolor[3]=255;
                }
                else
                {
                    beamcolor[0]=0;beamcolor[1]=0;beamcolor[2]=255;beamcolor[3]=255;
                }

                PrepareModel(MDL_EMP_SPRITE, gEmpSprite, true);
                TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite,
                                      1, 1, 0.5, 4.0, 10.0, beamcolor, 100, 0);
                TE_SendToAll();
                TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite,
                                      1, 1, 0.75, 4.0, 10.0, beamcolor, 100, 0);
                TE_SendToAll();
                TE_SetupBeamRingPoint(center, 0.1, radius, gEmpSprite, gEmpSprite,
                                      1, 1, 1.0, 4.0, 10.0, beamcolor, 100, 0);
                TE_SendToAll();

                if (GameType == tf2)
                {
                    for (new j=1;j<=MaxClients;j++)
                    {
                        if(PlayersInRange[j]>0.0)
                        {
                            TF2_RemovePlayerDisguise(j);
                            TF2_SetEnergyDrinkMeter(j, 0.0);
                            TF2_SetChargeMeter(j, 0.0);
                            TF2_SetCloakMeter(j, 0.0);
                            TF2_SetRageMeter(j, 0.0);
                            TF2_SetHypeMeter(j, 0.0);
                            if(TF2_IsPlayerCloaked(j))
                            {
                                //TF2_RemoveCondition(client,TFCond_Cloaked);
                                SetEntPropFloat(j, Prop_Send, "m_flInvisChangeCompleteTime", GetGameTime() + 1.0);
                            }

                            #if defined SOURCECRAFT
                                if (m_SourceCraftAvailable)
                                    SetEnergy(j, 0.0);
                            #endif
                        }
                    }

                    radius = radius * radius;
                    new Float:orig[3], Float:distance, Float:effectPos[3];
                    for (new i=MaxClients+1; i<GetMaxEntities(); i++)
                    {
                        if (IsValidEdict(i) && IsValidEntity(i))
                        {
                            GetEdictClassname(i, tName, sizeof(tName));
                            if (strncmp(tName, "tf_projectile_", 14) == 0)
                            {
                                if (GetEntProp(i, Prop_Data, "m_iTeamNum") == oteam)
                                {
                                    GetEntPropVector(i, Prop_Send, "m_vecOrigin", orig);
                                    orig[0]-=center[0];
                                    orig[1]-=center[1];
                                    orig[2]-=center[2];
                                    orig[0]*=orig[0];
                                    orig[1]*=orig[1];
                                    orig[2]*=orig[2];
                                    distance = orig[0]+orig[1]+orig[2];
                                    if (distance<radius)
                                    {
                                        if (entLimitOK)
                                        {
                                            ShowParticleEntity(i, "Explosions_MA_Smoke_1", 0.5);
                                            ShowParticleEntity(i, "Explosions_MA_Debris001", 0.5);
                                            ShowParticleEntity(i, "teleported_flash", 0.5);
                                        }

                                        PrepareAndEmitSoundToAll(SND_CHARGED, i, _, _, SND_CHANGEPITCH, 1.0, 200);
                                        PrepareAndEmitSoundToAll(SND_IMPACT, i, _, _, SND_CHANGEPITCH, 1.0, 120);

                                        AcceptEntityInput(i, "kill");
                                    }
                                }
                            }
                            else if (StrEqual(tName, "obj_sapper"))
                            {
                                if (GetEntProp(i, Prop_Data, "m_iTeamNum") == oteam)
                                {
                                    GetEntPropVector(i, Prop_Send, "m_vecOrigin", orig);
                                    orig[0]-=center[0];
                                    orig[1]-=center[1];
                                    orig[2]-=center[2];
                                    orig[0]*=orig[0];
                                    orig[1]*=orig[1];
                                    orig[2]*=orig[2];
                                    distance = orig[0]+orig[1]+orig[2];
                                    if (distance<radius)
                                    {
                                        new Float:SapperPos[3];
                                        GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", SapperPos);

                                        if (entLimitOK)
                                        {
                                            ShowParticle(SapperPos, "sapper_coreflash", 1.0);
                                            ShowParticle(SapperPos, "sapper_debris", 1.0);
                                            ShowParticle(SapperPos, "sapper_flash", 1.0);
                                            ShowParticle(SapperPos, "sapper_flashup", 1.0);
                                            ShowParticle(SapperPos, "sapper_flyingembers", 1.0);
                                            ShowParticle(SapperPos, "sapper_smoke", 1.0);
                                        }

                                        PrepareAndEmitSoundToAll(SND_SAPPER, i, _, _, _, 1.0);

                                        AcceptEntityInput(i, "kill");
                                    }
                                }
                            }
                            else if (StrEqual(tName, "obj_sentrygun") ||
                                     StrEqual(tName, "obj_dispenser") ||
                                     StrEqual(tName, "obj_teleporter") )
                            {
                                if (GetEntProp(i, Prop_Data, "m_iTeamNum") == oteam &&
                                    !GetEntProp(i, Prop_Send, "m_bDisabled"))
                                {
                                    GetEntPropVector(i, Prop_Send, "m_vecOrigin", orig);
                                    orig[0]-=center[0];
                                    orig[1]-=center[1];
                                    orig[2]-=center[2];
                                    orig[0]*=orig[0];
                                    orig[1]*=orig[1];
                                    orig[2]*=orig[2];
                                    distance = orig[0]+orig[1]+orig[2];
                                    if (distance<radius)
                                    {
                                        effectPos[0] = GetRandomFloat(-25.0, 25.0);
                                        effectPos[1] = GetRandomFloat(-25.0, 25.0);
                                        effectPos[2] = GetRandomFloat(10.0, 65.0);

                                        if (entLimitOK)
                                        {
                                            ShowParticleEntity(i, "sapper_sentry1_fx", 0.05, effectPos);
                                            ShowParticleEntity(i, "sapper_sentry1_sparks1", 0.05, effectPos);
                                            ShowParticleEntity(i, "sapper_sentry1_sparks2", 0.05, effectPos);
                                        }

                                        SetEntProp(i, Prop_Send, "m_bDisabled", 1);
                                        CreateTimer(7.0, Activate, EntIndexToEntRef(i));
                                    }
                                }
                            }
                        }
                    }
                }
                else
                {
                    for (new j=1;j<=MaxClients;j++)
                    {
                        if (PlayersInRange[j]>0.0)
                            FakeClientCommandEx(j, "drop"); // drop weapon
                    }
                }
            }
            case Bomblet:
            {
                radius = GetConVarFloat(cvBombRadius);
                GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);

                // effects
                if (GameType == tf2 &&
                    !IsEntLimitReached(.client=client, .message="unable to create bomblet particles"))
                {
                    ShowParticle(center, "ExplosionCore_MidAir", 2.0);

                    PrepareAndEmitSoundToAll(SND_NADE_MIRV2_TF2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                             SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
                }
                else
                {
                    PrepareModel(MDL_EXPLOSION_SPRITE, gExplosionSprite, true);
                    TE_SetupExplosion(center, gExplosionSprite, 2.0, 1, 4, RoundToCeil(radius), 0);
                    TE_SendToAll();

                    PrepareAndEmitSoundToAll(SND_NADE_MIRV2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                             SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
                }

                // player damage
                new damage = GetConVarInt(cvBombDamage);
                new oteam = (team == 3) ? 2 : 3;
                FindPlayersInRange(center, radius, oteam, client, true, nade);
                for (new j=1;j<=MaxClients;j++)
                {
                    if(PlayersInRange[j]>0.0)
                    {
                        #if defined SOURCECRAFT
                            if (m_SourceCraftAvailable && GetImmunity(j, Immunity_Explosion))
                                continue;
                        #endif

                        NadeHurtPlayer(j, client, damage, type, "tf2nade_mirv",
                                       center, .explosion=true);
                    }
                }
                DamageBuildings(client, center, radius, damage, nade, true);
            }
            case TargetingDrone:
            {
                radius = GetConVarFloat(cvDroneRadius);
                GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);

                new bool:entLimitOK = !IsEntLimitReached(.client=client, .message="unable to explode targeting drone");
                if (GameType == tf2 && entLimitOK)
                    ShowParticle(center, "Explosions_MA_Dustup_2", 2.0);
                else
                {
                    new Float:dir[3];
                    dir[0] = 0.0;
                    dir[1] = 0.0;
                    dir[2] = 2.0;
                    TE_SetupDust(center,dir,radius,100.0);
                    TE_SendToAll();
                }

                if (entLimitOK)
                {
                    center[2]+=64.0;

                    new ent = CreateEntityByName("prop_dynamic_override");
                    if (ent > 0 && IsValidEntity(ent))
                    {
                        SetupNade(TargetingDrone, team, true);

                        new Float:angles[3] = {0.0,0.0,0.0};
                        SetEntProp(ent, Prop_Data, "m_MoveType", MOVETYPE_FLY);
                        SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
                        SetEntPropFloat(ent, Prop_Data, "m_flGravity", 0.0);
                        SetEntityModel(ent,gnModel);
                        //SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
                        //SetEntProp(ent, Prop_Send, "m_usSolidFlags", 16);
                        //Format(gnSkin, sizeof(gnSkin), "%d", team-2);
                        //DispatchKeyValue(ent, "skin", gnSkin);
                        Format(tName, sizeof(tName), "tf2drone%d", nade);
                        DispatchKeyValue(ent, "targetname", tName);
                        DispatchSpawn(ent);
                        TeleportEntity(ent, center, angles, NULL_VECTOR);
                        //SetVariantString("release");
                        //AcceptEntityInput(ent, "SetAnimation");
                        //AcceptEntityInput(ent, "SetDefaultAnimation");

                        PrepareAndEmitSoundToAll(SND_NADE_NAIL, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                                 SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

                        new Handle:pack;
                        new nadeRef = EntIndexToEntRef(ent);
                        new userid = GetClientUserId(client);
                        gNadeTimer2[client] = CreateDataTimer(20.0, DroneFinish, pack); 
                        gNadeTimer[client] = CreateTimer(0.2, DroneThink, pack, TIMER_REPEAT);
                        WritePackCell(pack, nadeRef);
                        WritePackCell(pack, client);
                        WritePackCell(pack, userid);
                    }
                }
            }
            case SmokeNade:
            {
                radius = GetConVarFloat(cvSmokeRadius);
                new Float:delay = GetConVarFloat(cvSmokeDelay);
                GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);

                TE_SetupSparks(center, NULL_VECTOR, 2, 1);
                TE_SendToAll();

                PrepareModel(MDL_SMOKE_SPRITE, gSmokeSprite, true);
                TE_SetupSmoke(center,gSmokeSprite,40.0,1);
                TE_SendToAll();

                PrepareAndEmitSoundToAll(SND_NADE_SMOKE, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                         SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
                
                // Create the Smoke Cloud
                new String:originData[64];
                Format(originData, sizeof(originData), "%f %f %f", center[0], center[1], center[2]);

                if (IsEntLimitReached(.client=client, .message="unable to explode smoke nade"))
                {
                    new String:size[5];
                    new String:name[128];
                    Format(size, sizeof(size), "%f", radius);
                    Format(name, sizeof(name), "Smoke%i", client);
                    new cloud = CreateEntityByName("env_smokestack");
                    if (cloud > 0 && IsValidEntity(cloud))
                    {
                        DispatchKeyValue(cloud,"targetname", name);
                        DispatchKeyValue(cloud,"Origin", originData);
                        DispatchKeyValue(cloud,"BaseSpread", "100");
                        DispatchKeyValue(cloud,"SpreadSpeed", "10");
                        DispatchKeyValue(cloud,"Speed", "80");
                        DispatchKeyValue(cloud,"StartSize", "100");
                        DispatchKeyValue(cloud,"EndSize", size);
                        DispatchKeyValue(cloud,"Rate", "15");
                        DispatchKeyValue(cloud,"JetLength", "400");
                        DispatchKeyValue(cloud,"Twist", "4");
                        DispatchKeyValue(cloud,"RenderColor", "64 64 64");
                        DispatchKeyValue(cloud,"RenderAmt", "100");
                        DispatchKeyValue(cloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
                        DispatchSpawn(cloud);
                        AcceptEntityInput(cloud, "TurnOn");

                        CreateTimer(delay, RemoveSmoke, EntIndexToEntRef(cloud));
                    }
                }
            }
            case GasNade:
            {
                radius = GetConVarFloat(cvGasRadius);
                new damage = GetConVarInt(cvGasDamage);
                new Float:delay = GetConVarFloat(cvGasDelay);
                GetEntPropVector(nade, Prop_Send, "m_vecOrigin", center);

                TE_SetupSparks(center, NULL_VECTOR, 2, 1);
                TE_SendToAll();

                PrepareModel(MDL_SMOKE_SPRITE, gSmokeSprite, true);
                TE_SetupSmoke(center,gSmokeSprite,40.0,1);
                TE_SendToAll();

                PrepareAndEmitSoundToAll(SND_NADE_GAS, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                         SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

                if (IsEntLimitReached(.client=client, .message="unable to explode gas nade"))
                {
                    // Create the PointHurt
                    new String:originData[64];
                    Format(originData, sizeof(originData), "%f %f %f", center[0], center[1], center[2]);

                    new String:damageData[64];
                    Format(damageData, sizeof(damageData), "%i", damage);

                    new String:radiusData[64];
                    Format(radiusData, sizeof(radiusData), "%f", radius);

                    new pointHurt = CreateEntityByName("point_hurt");
                    if (pointHurt > 0 && IsValidEntity(pointHurt))
                    {
                        DispatchKeyValue(pointHurt,"Origin", originData);
                        DispatchKeyValue(pointHurt,"Damage", damageData);
                        DispatchKeyValue(pointHurt,"DamageRadius", radiusData);
                        DispatchKeyValue(pointHurt,"DamageDelay", "1.0");
                        DispatchKeyValue(pointHurt,"DamageType", "65536");
                        DispatchSpawn(pointHurt);
                        AcceptEntityInput(pointHurt, "TurnOn");

                        // Create the Gas Cloud
                        new String:gas_name[128];
                        Format(gas_name, sizeof(gas_name), "Gas%i", client);

                        new gascloud = CreateEntityByName("env_smokestack");
                        if (gascloud > 0 && IsValidEntity(gascloud))
                        {
                            DispatchKeyValue(gascloud,"targetname", gas_name);
                            DispatchKeyValue(gascloud,"Origin", originData);
                            DispatchKeyValue(gascloud,"BaseSpread", "100");
                            DispatchKeyValue(gascloud,"SpreadSpeed", "10");
                            DispatchKeyValue(gascloud,"Speed", "80");
                            DispatchKeyValue(gascloud,"StartSize", "200");
                            DispatchKeyValue(gascloud,"EndSize", "2");
                            DispatchKeyValue(gascloud,"Rate", "15");
                            DispatchKeyValue(gascloud,"JetLength", "400");
                            DispatchKeyValue(gascloud,"Twist", "4");
                            DispatchKeyValue(gascloud,"RenderColor", "180 210 0");
                            DispatchKeyValue(gascloud,"RenderAmt", "100");
                            DispatchKeyValue(gascloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
                            DispatchSpawn(gascloud);
                            AcceptEntityInput(gascloud, "TurnOn");
                        }

                        new Handle:entitypack = CreateDataPack();
                        CreateTimer(delay, RemoveGas, entitypack);
                        CreateTimer(delay + 5.0, KillGas, entitypack);
                        WritePackCell(entitypack, EntIndexToEntRef(gascloud));
                        WritePackCell(entitypack, EntIndexToEntRef(pointHurt));
                    }
                }
            }
        }
    }

    TeleportEntity(nade, gHoldingArea, NULL_VECTOR, NULL_VECTOR);   
}

SetupNade(NadeType:type, team, bool:special)
{
    // setup frag nade if not special
    if (!special || type >= FragNade)
    {
        PrepareModel(MDL_FRAG, g_FragModelIndex, true);
        strcopy(gnModel, sizeof(gnModel), MDL_FRAG);
        gnSpeed = 2000.0;
        gnDelay = 2.0;
        gnParticle[0]='\0';
        return;
    }
    else
    {
        // setup special nade if not frag
        switch (type)
        {
            case ConcNade:
            {
                PrepareModel(MDL_CONC, g_ConcModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_CONC);
                gnSpeed = 1500.0;
                gnDelay = 2.0;
                strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
            }
            case BearTrap:
            {
                //PrepareModel(MDL_TRAP, g_TrapModelIndex, true);
                //strcopy(gnModel, sizeof(gnModel), MDL_TRAP);
                PrepareModel(MDL_HALLUC, g_HallucModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_HALLUC);
                gnSpeed = 500.0;
                gnDelay = 2.0;
                gnParticle[0]='\0';
            }
            case NailNade:
            {
                PrepareModel(MDL_NAIL, g_NailModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_NAIL);
                gnSpeed = 1000.0;
                gnDelay = 2.0;
                gnParticle[0]='\0';
            }
            case MirvNade:
            {
                SetupNade(EmpNade, team, special);
                PrepareModel(MDL_MIRV1, g_Mirv1ModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_MIRV1);
                gnSpeed = 1250.0;
                gnDelay = 3.0;
                gnParticle[0]='\0';
            }
            case HealthNade:
            {
                PrepareModel(MDL_HEALTH, g_HealthModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_HEALTH);
                gnSpeed = 2000.0;
                gnDelay = GetConVarFloat(cvHealthDelay);
                if (team==2)
                {
                    strcopy(gnParticle, sizeof(gnParticle), "player_recent_teleport_red");
                }
                else
                {
                    strcopy(gnParticle, sizeof(gnParticle), "player_recent_teleport_blue");
                }
            }
            case HeavyNade:
            {
                PrepareModel(MDL_MIRV1, g_Mirv1ModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_MIRV1);
                gnSpeed = 1250.0;
                gnDelay = 3.0;
                gnParticle[0]='\0';
            }
            case NapalmNade:
            {
                PrepareModel(MDL_NAPALM, g_NapalmModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_NAPALM);
                gnSpeed = 2000.0;
                gnDelay = 2.0;
                gnParticle[0]='\0';
            }
            case HallucNade:
            {
                PrepareModel(MDL_HALLUC, g_HallucModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_HALLUC);
                gnSpeed = 1500.0;
                gnDelay = 2.0;
                strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
            }
            case EmpNade:
            {
                PrepareModel(MDL_EMP, g_EmpModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_EMP);
                gnSpeed = 1500.0;
                gnDelay = 2.0;
                if (team==2)
                {
                    strcopy(gnParticle, sizeof(gnParticle), "critgun_weaponmodel_red");
                }
                else
                {
                    strcopy(gnParticle, sizeof(gnParticle), "critgun_weaponmodel_blu");
                }
            }
            case Bomblet:
            {
                PrepareModel(MDL_MIRV2, g_Mirv2ModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_MIRV2);
                gnSpeed = 500.0;
                gnDelay = 2.0;
                gnParticle[0]='\0';
            }
            case SmokeNade:
            {
                PrepareModel(MDL_SMOKE, g_SmokeModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_SMOKE);
                //PrepareModel(MDL_HALLUC, g_HallucModelIndex, true);
                //strcopy(gnModel, sizeof(gnModel), MDL_HALLUC);
                gnSpeed = 1500.0;
                gnDelay = 2.0;
                strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
            }
            case GasNade:
            {
                PrepareModel(MDL_GAS, g_GasModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_GAS);
                //PrepareModel(MDL_HALLUC, g_HallucModelIndex, true);
                //strcopy(gnModel, sizeof(gnModel), MDL_HALLUC);
                gnSpeed = 1500.0;
                gnDelay = 2.0;
                strcopy(gnParticle, sizeof(gnParticle), "buildingdamage_smoke2");
            }
            case TargetingDrone:
            {
                PrepareModel(MDL_DRONE, g_DroneModelIndex, true);
                strcopy(gnModel, sizeof(gnModel), MDL_DRONE);
                gnSpeed = 1500.0;
                gnDelay = 2.0;
                gnParticle[0]='\0';
            }
        }
    }
}

GetNumNades(NadeType:type)
{
    switch (type)
    {
        case ConcNade:
        {
            return GetConVarInt(cvConcNum);
        }
        case BearTrap:
        {
            return GetConVarInt(cvTrapNum);
        }
        case NailNade:
        {
            return GetConVarInt(cvNailNum);
        }
        case MirvNade:
        {
            return GetConVarInt(cvMirvNum);
        }
        case HealthNade:
        {
            return GetConVarInt(cvHealthNum);
        }
        case HeavyNade:
        {
            return GetConVarInt(cvMirvNum);
        }
        case NapalmNade:
        {
            return GetConVarInt(cvNapalmNum);
        }
        case HallucNade:
        {
            return GetConVarInt(cvHallucNum);
        }
        case EmpNade:
        {
            return GetConVarInt(cvEmpNum);
        }
        case Bomblet:
        {
            return GetConVarInt(cvBombNum);
        }
        case SmokeNade:
        {
            return GetConVarInt(cvSmokeNum);
        }
        case GasNade:
        {
            return GetConVarInt(cvGasNum);
        }
        default:
        {
            return 0;
        }
    }
    return 0;
}

FireTimers(client)
{
    // nades
    new Handle:timer = gNadeTimer[client];
    if (timer != INVALID_HANDLE)
    {
        gTriggerTimer[client] = true;
        TriggerTimer(timer);
        gTriggerTimer[client] = false;
    }

    new Handle:timer2 = gNadeTimer2[client];
    if (timer2 != INVALID_HANDLE)
    {
        gTriggerTimer[client] = true;
        TriggerTimer(timer2);
        gTriggerTimer[client] = false;
    }
}

public Action:RemoveSmoke(Handle:timer, any:ref)
{
    new entity = EntRefToEntIndex(ref);
    if (entity > 0 && IsValidEntity(entity))
    {
        AcceptEntityInput(entity, "TurnOff");
        CreateTimer(5.0, KillSmoke, ref);
    }
}

public Action:KillSmoke(Handle:timer, any:ref)
{
    new entity = EntRefToEntIndex(ref);
    if (entity > 0 && IsValidEntity(entity))
        AcceptEntityInput(entity, "Kill");
}

public Action:RemoveGas(Handle:timer, Handle:entitypack)
{
    ResetPack(entitypack);

    new gascloud = EntRefToEntIndex(ReadPackCell(entitypack));
    if (gascloud > 0 && IsValidEntity(gascloud))
        AcceptEntityInput(gascloud, "TurnOff");

    new pointHurt = EntRefToEntIndex(ReadPackCell(entitypack));
    if (pointHurt > 0 && IsValidEntity(pointHurt))
        AcceptEntityInput(pointHurt, "TurnOff");
}

public Action:KillGas(Handle:timer, Handle:entitypack)
{
    ResetPack(entitypack);

    new gascloud = EntRefToEntIndex(ReadPackCell(entitypack));
    if (gascloud > 0 && IsValidEntity(gascloud))
        AcceptEntityInput(gascloud, "Kill");

    new pointHurt = EntRefToEntIndex(ReadPackCell(entitypack));
    if (pointHurt > 0 && IsValidEntity(pointHurt))
        AcceptEntityInput(pointHurt, "Kill");

    CloseHandle(entitypack);
}

public Action:Activate(Handle:timer,any:ref)
{
    new object = EntRefToEntIndex(ref);
    if (object > 0 && IsValidEdict(object) && IsValidEntity(object))
    {
        SetEntProp(object, Prop_Send, "m_bDisabled", 0);
        AcceptEntityInput(object, "TurnOn");
    }                
    return Plugin_Stop;
}

public Action:SoldierNadeThink(Handle:timer, any:pack)
{
    ResetPack(pack);
    new ref = ReadPackCell(pack);
    new client = ReadPackCell(pack);
    new userid = ReadPackCell(pack);

    new ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent) &&
        GetClientOfUserId(userid) == client)
    {
        // effects
        new Float:center[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", center);

        new rand = GetRandomInt(1, 3);
        switch (rand)
        {
            case 1:  Format(tName, sizeof(tName), "%s", SND_NADE_NAIL_SHOOT1);
            case 2:  Format(tName, sizeof(tName), "%s", SND_NADE_NAIL_SHOOT2);
            default: Format(tName, sizeof(tName), "%s", SND_NADE_NAIL_SHOOT3);
        }

        PrepareAndEmitSoundToAll(tName, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                 SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);

        new Float:dir[3];
        dir[0] = GetRandomFloat(-1.0, 1.0);
        dir[1] = GetRandomFloat(-1.0, 1.0);
        dir[2] = GetRandomFloat(-1.0, 1.0);
        TE_SetupMetalSparks(center, dir);
        TE_SendToAll();

        // player damage
        new damage = GetConVarInt(cvNailDamageNail);
        new oteam = (GetClientTeam(client)==3) ? 2 : 3;
        FindPlayersInRange(center, GetConVarFloat(cvNailRadius), oteam, client, true, ent);
        for (new j=1;j<=MaxClients;j++)
        {
            if (PlayersInRange[j]>0.0)
            {
                NadeHurtPlayer(j, client, damage, NailNade, "tf2nade_nail", center);
            }
        }
        return Plugin_Continue;
    }

    gNadeTimer[client] = INVALID_HANDLE;

    new Handle:finishTimer = gNadeTimer2[client];
    if (finishTimer != INVALID_HANDLE)
        TriggerTimer(finishTimer);

    return Plugin_Stop;
}

public Action:SoldierNadeFinish(Handle:timer, any:pack)
{
    ResetPack(pack);
    new ref = ReadPackCell(pack);
    new client = ReadPackCell(pack);
    new userid = ReadPackCell(pack);

    gNadeTimer2[client] = INVALID_HANDLE;

    if (gNadeTimer[client] != INVALID_HANDLE)
    {
        KillTimer(gNadeTimer[client]);
        gNadeTimer[client] = INVALID_HANDLE;
    }

    new ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
    {
        StopSound(ent, SNDCHAN_WEAPON, SND_NADE_NAIL);
        if (GetClientOfUserId(userid) == client)
        {
            // effects
            new Float:center[3];
            new Float:radius = GetConVarFloat(cvNailRadius);
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", center);

            if (GameType == tf2 &&
                !IsEntLimitReached(.client=client, .message="unable to create nail explosion particle"))
            {
                ShowParticle(center, "ExplosionCore_MidAir", 2.0);

                PrepareAndEmitSoundToAll(SND_NADE_NAIL_EXPLODE_TF2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC,
                                         SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
            }
            else
            {
                PrepareModel(MDL_EXPLOSION_SPRITE, gExplosionSprite, true);
                TE_SetupExplosion(center, gExplosionSprite, 2.0, 1, 4, RoundToCeil(radius), 0);
                TE_SendToAll();

                PrepareAndEmitSoundToAll(SND_NADE_NAIL_EXPLODE, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC,
                                         SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
            }

            // player damage
            new damage = GetConVarInt(cvNailDamageExplode);
            new oteam = (GetClientTeam(client) == 3) ? 2 : 3;
            FindPlayersInRange(center, radius, oteam, client, true, ent);
            for (new j=1;j<=MaxClients;j++)
            {
                if (PlayersInRange[j]>0.0)
                {
                    NadeHurtPlayer(j, client, damage, NailNade, "tf2nade_nail",
                                   center, .explosion=true);
                }
            }

            DamageBuildings(client, center, radius, damage, ent, true);
        }
        AcceptEntityInput(ent, "kill");
    }

    return Plugin_Stop;
}

public Action:MirvExplode2(Handle:timer, Handle:pack)
{
    decl Float:center[3];
    new Float:radius = GetConVarFloat(cvMirvRadius);

    ResetPack(pack);
    new client = ReadPackCell(pack);
    new userid = ReadPackCell(pack);
    new team = ReadPackCell(pack);

    gNadeTimer[client] = INVALID_HANDLE;

    new bool:emitSoundOK = true;
    new bool:entLimitOK = !IsEntLimitReached(.client=client, .message="unable to create mirv explode particles");
    new bool:clientInGame = GetClientOfUserId(userid) == client;
    if (clientInGame)
    {
        if (GameType == tf2)
            emitSoundOK = PrepareSound(SND_NADE_MIRV2_TF2);
        else
        {
            emitSoundOK = PrepareSound(SND_NADE_MIRV2);
            PrepareModel(MDL_EXPLOSION_SPRITE, gExplosionSprite, true);
        }
    }

    for (new k=0;k<MIRV_PARTS;k++)
    {
        new ent = EntRefToEntIndex(ReadPackCell(pack));
        if (ent > 0 && IsValidEntity(ent))
        {
            if (clientInGame)
            {
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", center);

                if (GameType == tf2)
                {
                    if (entLimitOK)
                        ShowParticle(center, "ExplosionCore_MidAir", 2.0);

                    if (emitSoundOK)
                    {
                        EmitSoundToAll(SND_NADE_MIRV2_TF2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                       SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, Float:k * 0.25);
                    }
                }
                else
                {
                    TE_SetupExplosion(center, gExplosionSprite, 2.0, 1, 4, RoundToCeil(radius), 0);
                    TE_SendToAll();

                    if (emitSoundOK)
                    {
                        // Apparently, the soundtime parameter doesn't work in dod, it supresses the sound altogether!
                        EmitSoundToAll(SND_NADE_MIRV2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS,
                                       SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
                    }                                   
                }

                new damage = GetConVarInt(cvMirvDamage2);
                new oteam = (team == 3) ? 2 : 3;
                FindPlayersInRange(center, radius, oteam, client, true, ent);
                for (new j=1;j<=MaxClients;j++)
                {
                    if (PlayersInRange[j]>0.0)
                    {
                        NadeHurtPlayer(j, client, damage, MirvNade, "tf2nade_mirv",
                                       center, .explosion=true);
                    }
                }
                DamageBuildings(client, center, radius, damage, ent, true);
            }
            AcceptEntityInput(ent, "kill");
        }
    }

    return Plugin_Stop;
}

public Action:DroneThink(Handle:timer, any:pack)
{
    ResetPack(pack);
    new ref = ReadPackCell(pack);
    new client = ReadPackCell(pack);
    new userid = ReadPackCell(pack);

    if (GetClientOfUserId(userid) == client)
    {
        new ent = EntRefToEntIndex(ref);
        if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
        {
            new Float:range=2000.0;
            new Float:center[3];
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", center);

            PrepareModel(MDL_BEAM_SPRITE, gBeamSprite, true);

            new team = GetClientTeam(client);
            new targetColor[4] = {0, 0, 0, 255};
            if (team==2)
                targetColor[0] = 255;
            else
                targetColor[2] = 255;

            // Find players to target
            new Float:indexLoc[3];
            for (new index=1;index<=MaxClients;index++)
            {
                if (client != index && IsClientInGame(index) &&
                    IsPlayerAlive(index) && GetClientTeam(index) != team)
                {
                    GetClientAbsOrigin(index, indexLoc);
                    if (IsPointInRange(center,indexLoc,range) &&
                            TraceTargetIndex(ent, index, center, indexLoc))
                    {
                        new Float:vector[3], Float:angles[3];
                        MakeVectorFromPoints(center, indexLoc, vector);
                        NormalizeVector(vector, vector);
                        GetVectorAngles(vector, angles);
                        TeleportEntity(ent, NULL_VECTOR, angles, NULL_VECTOR);

                        gTargeted[index] = client;
                        TE_SetupBeamLaser(ent, index, gBeamSprite, gBeamSprite,
                                0, 1, 0.4, 10.0,10.0,2,50.0,targetColor,255);
                        TE_SendToAll();
                    }
                    else if (gTargeted[index] == client)
                        gTargeted[index] = 0;
                }
                else if (gTargeted[index] == client)
                    gTargeted[index] = 0;
            }

            static const Float:vel[3] = {0.0,0.0,105.0};
            TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, vel);
            return Plugin_Continue;
        }
    }

    gNadeTimer[client] = INVALID_HANDLE;

    new Handle:finishTimer = gNadeTimer2[client];
    if (finishTimer != INVALID_HANDLE)
        TriggerTimer(finishTimer);
    else
    {
        // Reset the targeted flags
        for (new index=1;index<=MaxClients;index++)
        {
            if (gTargeted[index] == client)
                gTargeted[index] = 0;
        }
    }

    return Plugin_Stop;
}

public Action:DroneFinish(Handle:timer, any:pack)
{
    ResetPack(pack);
    new ref = ReadPackCell(pack);
    new client = ReadPackCell(pack);
    new userid = ReadPackCell(pack);

    gNadeTimer2[client] = INVALID_HANDLE;

    if (gNadeTimer[client] != INVALID_HANDLE)
    {
        KillTimer(gNadeTimer[client]);
        gNadeTimer[client] = INVALID_HANDLE;
    }

    new ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
    {
        StopSound(ent, SNDCHAN_WEAPON, SND_NADE_NAIL);
        if (GetClientOfUserId(userid) == client)
        {
            // effects
            new Float:center[3];
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", center);

            if (GameType == tf2 &&
                !IsEntLimitReached(.client=client, .message="unable to create drone explosion particle"))
            {
                ShowParticle(center, "ExplosionCore_MidAir", 2.0);
            }
            else
            {
                new Float:radius = GetConVarFloat(cvNailRadius);
                PrepareModel(MDL_EXPLOSION_SPRITE, gExplosionSprite, true);
                TE_SetupExplosion(center, gExplosionSprite, 2.0, 1, 4, RoundToCeil(radius), 0);
                TE_SendToAll();
            }

            PrepareAndEmitSoundToAll(SND_NADE_NAIL_EXPLODE, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC,
                                     SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
        }
        AcceptEntityInput(ent, "kill");
    }

    // Reset the targeted flags
    for (new index=1;index<=MaxClients;index++)
    {
        if (gTargeted[index] == client)
            gTargeted[index] = 0;
    }

    return Plugin_Stop;
}

public Action:ResetPlayerView(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        new Float:angles[3];
        GetClientEyeAngles(client, angles);
        angles[2] = 0.0;
        TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
        ClientCommand(client, "r_screenoverlay none");
    }
}

public Action:ResetPlayerMotion(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
        SetEntityMoveType(client,MOVETYPE_WALK); // Unfreeze client
}

SetupNadeModels()
{
    SetupModel("models/error.mdl", .precache=true); // In case the models are missing!

    SetupModel(MDL_FRAG, g_FragModelIndex);
    SetupModel(MDL_CONC, g_ConcModelIndex);
    SetupModel(MDL_NAIL, g_NailModelIndex);
    SetupModel(MDL_MIRV1, g_Mirv1ModelIndex);
    SetupModel(MDL_MIRV2, g_Mirv2ModelIndex);
    SetupModel(MDL_HEALTH, g_HealthModelIndex);
    SetupModel(MDL_NAPALM, g_NapalmModelIndex);
    SetupModel(MDL_HALLUC, g_HallucModelIndex);
    SetupModel(MDL_SMOKE, g_SmokeModelIndex);
    SetupModel(MDL_TRAP, g_TrapModelIndex);
    SetupModel(MDL_EMP, g_EmpModelIndex);
    SetupModel(MDL_DRONE, g_DroneModelIndex);
    SetupModel(MDL_GAS, g_GasModelIndex);

    AddFolderToDownloadTable("models/weapons/nades/duke1");
    AddFolderToDownloadTable("materials/models/weapons/nades/duke1");
}


// *************************************************
// helper funcs
// *************************************************

// show a health sign above client's head
ShowHealthParticle(client)
{
    new particle = CreateEntityByName("info_particle_system");
    if (particle > 0 && IsValidEntity(particle))
    {
        GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));
        DispatchKeyValue(particle, "targetname", "tf2particle");
        DispatchKeyValue(particle, "parentname", tName);
        if (GetClientTeam(client)==2)
        {
            DispatchKeyValue(particle, "effect_name", "healthgained_red");
        }
        else
        {
            DispatchKeyValue(particle, "effect_name", "healthgained_blu");
        }
        DispatchSpawn(particle);
        SetVariantString(tName);
        AcceptEntityInput(particle, "SetParent", particle, particle, 0);
        SetVariantString("head");
        AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(2.0, DeleteParticles, EntIndexToEntRef(particle));
    }
    else
    {
        LogError("ShowHealthParticle: could not create info_particle_system");
    }
}

public Action:DeleteParticles(Handle:timer, any:ref)
{
    new particle = EntRefToEntIndex(ref);
    if (particle > 0 && IsValidEntity(particle))
        AcceptEntityInput(particle, "kill");
}

stock ShowParticle(Float:pos[3], String:particlename[], Float:time, Float:ang[3]=NULL_VECTOR)
{
    new particle = CreateEntityByName("info_particle_system");
    if (particle > 0 && IsValidEntity(particle))
    {
        TeleportEntity(particle, pos, ang, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, EntIndexToEntRef(particle));
    }
    else
    {
        LogError("ShowParticle: could not create info_particle_system");
    }   
}

stock ShowParticleEntity(ent, String:particleType[], Float:time, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
    new particle = CreateEntityByName("info_particle_system");
    if (particle > 0 && IsValidEntity(particle))
    {
        new Float:pos[3];
        new Float:ang[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
        AddVectors(pos, addPos, pos);
        GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
        AddVectors(ang, addAngle, ang);

        TeleportEntity(particle, pos, ang, NULL_VECTOR);
        GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
        DispatchKeyValue(particle, "targetname", "tf2particle");
        DispatchKeyValue(particle, "parentname", tName);
        DispatchKeyValue(particle, "effect_name", particleType);
        DispatchSpawn(particle);
        SetVariantString(tName);
        AcceptEntityInput(particle, "SetParent", ent, particle, 0);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, EntIndexToEntRef(particle));
    }
    else
    {
        LogError("AttachParticle: could not create info_particle_system");
    }
}

AttachParticle(ent, String:particleType[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");
    if (particle > 0 && IsValidEntity(particle))
    {
        new Float:pos[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
        DispatchKeyValue(particle, "targetname", "tf2particle");
        DispatchKeyValue(particle, "parentname", tName);
        DispatchKeyValue(particle, "effect_name", particleType);
        DispatchSpawn(particle);
        SetVariantString(tName);
        AcceptEntityInput(particle, "SetParent", particle, particle, 0);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, EntIndexToEntRef(particle));
    }
    else
    {
        LogError("AttachParticle: could not create info_particle_system");
    }
}

// players in range setup  (self = 0 if doesn't affect self)
FindPlayersInRange(Float:location[3], Float:radius, team, self, bool:trace, donthit)
{
    new Float:rsquare = radius*radius;
    new Float:orig[3];
    new Float:distance;
    new Handle:tr;
    new j;
    for (j=1;j<=MaxClients;j++)
    {
        PlayersInRange[j] = 0.0;
        if (IsClientInGame(j))
        {
            if (IsPlayerAlive(j))
            {
                if ( (team>1 && GetClientTeam(j)==team) || team==0 || j==self)
                {
                    GetClientAbsOrigin(j, orig);
                    orig[0]-=location[0];
                    orig[1]-=location[1];
                    orig[2]-=location[2];
                    orig[0]*=orig[0];
                    orig[1]*=orig[1];
                    orig[2]*=orig[2];
                    distance = orig[0]+orig[1]+orig[2];
                    if (distance < rsquare)
                    {
                        if (trace)
                        {
                            GetClientEyePosition(j, orig);
                            tr = TR_TraceRayFilterEx(location, orig, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfOrPlayers, donthit);
                            if (tr!=INVALID_HANDLE)
                            {
                                if (TR_GetFraction(tr)>0.98)
                                {
                                    PlayersInRange[j] = SquareRoot(distance)/radius;
                                }
                                CloseHandle(tr);
                            }
                            
                        }
                        else
                        {
                            PlayersInRange[j] = SquareRoot(distance)/radius;
                        }
                    }
                }
            }
        }
    }
}

SetupHudMsg(Float:time)
{
    SetHudTextParams(-1.0, 0.8, time, 255, 255, 255, 64, 1, 0.5, 0.0, 0.5);
}


NadeKillPlayer(client, attacker, const String:weapon[])
{
    if (gKilledBy[client] == 0)
    {
        gKilledBy[client] = GetClientUserId(attacker);
        gKillTime[client] = GetEngineTime();
        strcopy(gKillWeapon[client], STRLENGTH, weapon);

        #if defined SOURCEMOD
            if (m_SourceCraftAvailable)
            {
                KillPlayer(client, attacker, weapon,
                           .explode=true, .type=DMG_BLAST);
            }
            else
        #endif
        {
            new ent = CreateEntityByName("env_explosion");
            if (IsValidEntity(ent))
            {
                DispatchKeyValue(ent, "iMagnitude", "1000");
                DispatchKeyValue(ent, "iRadiusOverride", "2");
                SetEntPropEnt(ent, Prop_Data, "m_hInflictor", attacker);
                SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", attacker);
                DispatchKeyValue(ent, "spawnflags", "3964");
                DispatchSpawn(ent);

                new Float:pos[3];
                GetClientAbsOrigin(client, pos);
                TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
                AcceptEntityInput(ent, "explode", client, client);
                CreateTimer(0.2, RemoveExplosion, EntRefToEntIndex(ent));
            }
        }
    }
}

public Action:RemoveExplosion(Handle:timer, any:ref)
{
    new ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
        AcceptEntityInput(ent, "kill");
}

bool:NadeHurtPlayer(client, attacker, damage, NadeType:type, const String:weapon[],
                    Float:pos[3] = NULL_VECTOR, Float:knockbackmult = 4.0,
                    bool:explosion=false, bool:napalm=false, bool:hold=false,
                    bool:halluc=false)
{
    if (GameType == tf2 && TF2_IsPlayerUbercharged(client))
        return false;

    #if defined SOURCECRAFT
        if (m_SourceCraftAvailable)
        {
            if (explosion && GetImmunity(client, Immunity_Explosion))
                return false;

            if (napalm && GetImmunity(client, Immunity_Burning))
                return false;

            if (hold && GetImmunity(client, Immunity_MotionTaking))
                return false;

            if (halluc && GetImmunity(client, Immunity_Blindness))
                return false;
        }
    #endif

    new Action:res = Plugin_Continue;
    Call_StartForward(fwdOnNadeExplode);
    Call_PushCell(client);
    Call_PushCell(attacker);
    Call_PushCellRef(damage);
    Call_PushCell(type);
    Call_PushArray(pos, sizeof(pos));
    Call_Finish(res);
    if (res != Plugin_Stop)
    {
        if (explosion)
        {
            new Float:play[3], Float:playerspeed[3], Float:distance;
            GetClientAbsOrigin(client, play);
            SubtractVectors(play, pos, play);
            distance = GetVectorLength(play);
            if (distance<0.01) { distance = 0.01; }
            ScaleVector(play, 1.0/distance);
            ScaleVector(play, damage * knockbackmult);
            play[2] = damage * knockbackmult;
            GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
            playerspeed[2]=0.0;
            AddVectors(play, playerspeed, play);
            TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, play);
        }

        if (damage > 0)
        {
            new health = GetClientHealth(client);
            if (health>damage)
            {
                new rand = GetRandomInt(0, (GameType == tf2) ? sizeof(sndPain)-1 : sizeof(sndPain)-2);
                PrepareAndEmitSoundToAll(sndPain[rand], client);

                #if defined SOURCECRAFT
                    if (m_SourceCraftAvailable)
                    {
                        new DamageFrom:category = gCategory[attacker];

                        if (explosion)
                            category |= DamageFrom_Explosion;

                        if (napalm)
                            category |= DamageFrom_Burning;

                        HurtPlayer(client, damage, attacker, weapon, .explode=explosion,
                                   .type=DMG_BLAST, .category=category);
                    }                                   
                    else
                    {
                        DamagePlayer(client, damage, attacker, DMG_BLAST, weapon);
                        //SetEntityHealth(client, health-damage);
                    }
                #else
                    #pragma unused napalm, hold, halluc
                    DamagePlayer(client, damage, attacker, DMG_BLAST, weapon);
                #endif

                return true;
            }
            else
            {
                NadeKillPlayer(client, attacker, weapon);
                return false;
            }
        }
        else
            return true;
    }
    else
        return false;
}

DamageBuildings(attacker, Float:start[3], Float:radius, damage, nade, bool:trace)
{
    if (GameType != tf2)
        return;

    new Float:pos[3];
    pos[0]=start[0];pos[1]=start[1];pos[2]=start[2]+16.0;
    new count = GetMaxEntities();
    new Float:obj[3], Float:objcalc[3];
    new Float:rad = radius * radius;
    new Float:distance;
    new Handle:tr;
    new team = IsClientInGame(attacker) ? GetClientTeam(attacker) : 0;
    new objteam;
    for (new i=MaxClients+1; i<count; i++)
    {
        if (IsValidEdict(i) && IsValidEntity(i))
        {
            GetEdictClassname(i, tName, sizeof(tName));
            if (StrEqual(tName, "obj_sentrygun")
                || StrEqual(tName, "obj_dispenser") 
                || StrEqual(tName, "obj_teleporter") )
            {
                objteam=GetEntProp(i, Prop_Data, "m_iTeamNum");
                if (team!=objteam)
                {
                    GetEntPropVector(i, Prop_Send, "m_vecOrigin", obj);
                    objcalc[0]=obj[0]-pos[0];
                    objcalc[1]=obj[1]-pos[1];
                    objcalc[2]=obj[2]-pos[2];
                    objcalc[0]*=objcalc[0];
                    objcalc[1]*=objcalc[1];
                    objcalc[2]*=objcalc[2];
                    distance = objcalc[0]+objcalc[1]+objcalc[2];
                    if (distance<rad)
                    {
                        if (trace)
                        {
                            obj[2]+=16.0;
                            tr = TR_TraceRayFilterEx(pos, obj, MASK_SOLID, RayType_EndPoint, TraceRayDontHitObjOrPlayers, nade);
                            if (tr!=INVALID_HANDLE)
                            {
                                if (TR_GetFraction(tr)>0.98 || TR_GetEntityIndex(tr)==i)
                                {
                                    SetVariantInt(damage);
                                    AcceptEntityInput(i, "RemoveHealth", attacker, attacker);
                                }
                                CloseHandle(tr);
                            }
                            
                        }
                        else
                        {
                            SetVariantInt(damage);
                            AcceptEntityInput(i, "RemoveHealth", attacker, attacker);
                        }
                    }
                }
            }
        }
    }
}

public bool:TraceRayDontHitSelfOrPlayers(entity, mask, any:startent)
{
    if(entity == startent)
    {
        return false; // 
    }
    
    if (entity <= MaxClients)
    {
        return false;
    }
    
    return true; 
}

public bool:TraceRayDontHitObjOrPlayers(entity, mask, any:startent)
{
    if(entity == startent)
    {
        return false; // 
    }
    
    if (entity <= MaxClients)
    {
        return false;
    }
    
    if (IsValidEdict(entity) && IsValidEntity(entity))
    {
        GetEdictClassname(entity, tName, sizeof(tName));
        if (StrEqual(tName, "obj_sentrygun")
            || StrEqual(tName, "obj_dispenser") 
            || StrEqual(tName, "obj_teleporter")
            || StrEqual(tName, "tf_ammo_pack") )
        {
            return false;
        }
    }
    
    return true; 
}

TagsCheck(const String:tag[])
{
    new Handle:hTags = FindConVar("sv_tags");
    
    decl String:tags[255];
    GetConVarString(hTags, tags, sizeof(tags));

    if (!(StrContains(tags, tag, false)>-1))
    {
        decl String:newTags[255];
        Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
        SetConVarString(hTags, newTags);
        GetConVarString(hTags, tags, sizeof(tags));
    }

    CloseHandle(hTags);
} 

public Action:SayCommand(client,args)
{
    decl String:command[128];
    GetCmdArg(1,command,sizeof(command));

    decl String:arg[2][64];
    ExplodeString(command, " ", arg, 2, 64);

    if (CommandCheck(arg[0],"nadeinfo") ||
        CommandCheck(arg[0],"nade"))
    {
        Command_NadeInfo(client, 0);
        return Plugin_Handled;
    }
    else if (CommandCheck(arg[0],"nadestop") ||
             CommandCheck(arg[0],"stop"))
    {
        Command_Stop(client, 0);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

bool:CommandCheck(const String:compare[], const String:command[])
{
    if(!strcmp(compare,command,false))
        return true;
    else
    {
        new String:firstChar[] = " ";
        firstChar{0} = compare{0};
        if (StrContains("!/\\",firstChar) >= 0)
            return !strcmp(compare[1],command,false);
        else
            return false;
    }
}

// *************************************************
// native interface
// *************************************************

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Natives
    CreateNative("ControlNades",Native_ControlNades);
    CreateNative("AddFragNades",Native_AddFragNades);
    CreateNative("SubFragNades",Native_SubFragNades);
    CreateNative("HasFragNades",Native_HasFragNades);
    CreateNative("ThrowFragNade",Native_ThrowFragNade);
    CreateNative("AddSpecialNades",Native_AddSpecialNades);
    CreateNative("SubSpecialNades",Native_SubSpecialNades);
    CreateNative("HasSpecialNades",Native_HasSpecialNades);
    CreateNative("ThrowSpecialNade",Native_ThrowSpecialNade);
    CreateNative("DamageBuildings",Native_DamageBuildings);
    CreateNative("IsTargeted",Native_IsTargeted);
    CreateNative("GiveNades",Native_GiveNades);
    CreateNative("TakeNades",Native_TakeNades);
    CreateNative("ThrowNade",Native_ThrowNade);

    // Register Forwards
    fwdOnNadeExplode=CreateGlobalForward("OnNadeExplode",ET_Hook,Param_Cell,Param_Cell,Param_CellByRef,
                                                        Param_Cell,Param_Array);

    RegPluginLibrary("ztf2nades");
    return APLRes_Success;
}

public Native_ControlNades(Handle:plugin,numParams)
{
    gNativeOverride |= GetNativeCell(1);
    gTargetOverride |= GetNativeCell(2);
}

public Native_GiveNades(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        new NadeType:old_type = gSpecialType[client];
        gRemaining1[client] = GetNativeCell(2);
        gAllowed1[client] = GetNativeCell(3);
        gRemaining2[client] = GetNativeCell(4);
        gAllowed2[client] = GetNativeCell(5);
        gCanRestock[client] = bool:GetNativeCell(6);
        gSpecialType[client] = NadeType:GetNativeCell(7);

        #if defined SOURCECRAFT
            gCategory[client] = DamageFrom:GetNativeCell(8);
        #endif

        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            if (gSpecialType[client] != old_type)
            {
                // get nade type
                new NadeType:type = gSpecialType[client];
                if (type <= DefaultNade) // setup nade variables based on player class
                {
                    new class = 0;
                    switch (GameType)
                    {
                        case tf2: class = _:TF2_GetPlayerClass(client);
                        case dod: class = _:DOD_GetPlayerClass(client); 
                    }
                    new Handle:typeVar = cvNadeType[class];
                    type = typeVar ? (NadeType:GetConVarInt(typeVar)) : (NadeType:class);
                }

                SetupNade(type, GetClientTeam(client), true);
            }

            if ((gRemaining1[client] > 0 || gRemaining2[client] > 0) && IsPlayerAlive(client))
            {
                SetupHudMsg(3.0);
                ShowHudText(client, 1, "%t", "GivenNades", gRemaining1[client], gRemaining2[client]);
            }
        }
    }
}

public Native_TakeNades(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        gSpecialType[client] = DefaultNade;
        gCanRestock[client] = false;
        gRemaining1[client] = 0;
        gRemaining2[client] = 0;
        gAllowed1[client] = 0;
        gAllowed2[client] = 0;

        #if defined SOURCECRAFT
            gCategory[client] = DamageFrom_None;
        #endif
    }
}

public Native_AddFragNades(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        gRemaining1[client] += GetNativeCell(2);

        #if defined SOURCECRAFT
            gCategory[client] |= DamageFrom:GetNativeCell(3);
        #endif
    }
}

public Native_SubFragNades(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        gRemaining1[client] -= GetNativeCell(2);
        if (gRemaining1[client] < 0)
            gRemaining1[client] = 0;
    }
}

public Native_HasFragNades(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        switch (GetNativeCell(2))
        {
            case 1:  return gAllowed1[client];
#if defined SOURCECRAFT
            case 2:  return _:gCategory[client];
#endif
        }
        return gRemaining1[client];
    }
    else
        return -1;
}

public Native_AddSpecialNades(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        gRemaining2[client] += GetNativeCell(2);

        #if defined SOURCECRAFT
            gCategory[client] |= DamageFrom:GetNativeCell(3);
        #endif
    }
}

public Native_SubSpecialNades(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        gRemaining2[client] -= GetNativeCell(2);
        if (gRemaining2[client] < 0)
            gRemaining2[client] = 0;
    }
}

public Native_HasSpecialNades(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        switch (GetNativeCell(2))
        {
            case 1:  return gAllowed2[client];
#if defined SOURCECRAFT
            case 2:  return _:gCategory[client];
#endif
        }
        return gRemaining2[client];
    }
    else
        return -1;
}

public Native_ThrowFragNade(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        if (GetNativeCell(2))
            Command_Nade1(client, 0);
        else
            Command_UnNade1(client, 0);
    }
}

public Native_ThrowSpecialNade(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        if (GetNativeCell(2))
            Command_Nade2(client, 0);
        else
            Command_UnNade2(client, 0);
    }
}

public Native_DamageBuildings(Handle:plugin,numParams)
{
    new attacker = GetNativeCell(1);
    if (attacker > 0 && attacker <= MaxClients)
    {
        new Float:start[3];
        GetNativeArray(2, start, 3); 

        new Float:radius = Float:GetNativeCell(3);
        new damage = GetNativeCell(4);
        new ent = GetNativeCell(5);
        new bool:trace = bool:GetNativeCell(6);
        DamageBuildings(attacker, start, radius, damage, ent, trace);
    }
}

public Native_ThrowNade(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        new NadeType:type = NadeType:GetNativeCell(3);
        if (GetNativeCell(2)) // setup - button pressed
        {
            if (gHolding[client]>HoldNone)
                return;
            else if (!IsClientInGame(client) || !IsPlayerAlive(client))
                return;
            else
            {
                if (GameType == tf2)
                {
                    // not while cloaked, taunting or bonked
                    if (TF2_IsPlayerCloaked(client) || TF2_IsPlayerTaunting(client) || TF2_IsPlayerBonked(client))
                    {
                        return;
                    }
                }

                SetupHudMsg(3.0);
                if (!gCanRun || IsEntLimitReached(.client=client, .message="unable to create nade"))
                    ShowHudText(client, 1, "%t", "WaitingPeriod");
                else
                {
                    if (gTriggerTimer[client])
                    {
                        gTriggerTimer[client] = false;
                        gNadeTimer[client]=INVALID_HANDLE;
                    }

                    if (gNadeTimer[client]==INVALID_HANDLE)
                    {
                        if (TF2_IsPlayerDisguised(client))
                            TF2_RemovePlayerDisguise(client);

                        ThrowNade(client, true, HoldOther, type);
                    }
                    else
                        ShowHudText(client, 1, "%t", "OnlyOneNade");
                }
            }
        }
        else // if (!setup) // button released
        {
            if (gHolding[client] != HoldOther)
                return;
            else if (gNadeTimer[client]!=INVALID_HANDLE)
                ThrowNade(client, false, HoldOther, type);
        }
    }
}

public Native_IsTargeted(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        return  gTargeted[client];
    }
    else
        return false;
}

/**
 * Description: Range and Distance functions and variables
 */
#tryinclude "sc/range"
#if !defined _range_included
    stock bool:IsPointInRange(const Float:start[3], const Float:end[3],Float:maxdistance)
    {
        return (GetVectorDistance(start,end)<maxdistance);
    }
#endif

/**
 * Description: Ray Trace functions and variables
 */
#tryinclude <raytrace>
#if !defined _raytrace_included
    stock bool:TraceTargetIndex(client, target, Float:clientLoc[3], Float:targetLoc[3])
    {
        targetLoc[2] += 50.0; // Adjust trace position of target
        TR_TraceRayFilter(clientLoc, targetLoc, MASK_SOLID,
                          RayType_EndPoint, TraceRayDontHitSelf,
                          client);

        return (!TR_DidHit() || TR_GetEntityIndex() == target);
    }

    /***************
     *Trace Filters*
    ****************/

    public bool:TraceRayDontHitSelf(entity, mask, any:data)
    {
        return (entity != data); // Check if the TraceRay hit the owning entity.
    }
#endif

