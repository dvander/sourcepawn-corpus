/**
 * vim: set ai et ts=4 sw=4 :
 * File: jetpack.sp
 * Description: Jetpack for source.
 * Author(s): Knagg0
 * Modified by: -=|JFH|=-Naris (Murray Wilson)
 *              -- Added Fuel & Refueling Time
 *              -- Added AdminOnly
 *              -- Added Give/Take Jetpack 
 *              -- Added Admin Interface
 *              -- Added Native Interface
 *              -- Added sm_jetpack_team
 *              -- Added sm_jetpack_max_refuels
 *              -- Added sm_jetpack_noflag
 *
 * Fixed by: iggythepop/-SinCO-
 *           -- Fixed jetpack sticking to the ground
 *
 * Added by: Grrrrrrrrrrrrrrrrrrr
 *           -- Added Flame Effect
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

/**
 * Description: Use the SourceCraft API, if available.
 */
#undef REQUIRE_PLUGIN
#tryinclude <damage>
#tryinclude "ztf2grab"
#tryinclude <sc/SourceCraft>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION          "3.1"

#define MOVECOLLIDE_DEFAULT	    0
#define MOVECOLLIDE_FLY_BOUNCE	1

#define COLOR_DEFAULT           0x01
#define COLOR_GREEN             0x04

#define MIN_JUMP_TIME           0.1

//#define ADMFLAG_JETPACK       ADMFLAG_GENERIC
#define ADMFLAG_JETPACK         ADMFLAG_CUSTOM2

#define START_SOUND             ""
#define START_SOUND_TF2         "weapons/flame_thrower_airblast.wav"

#define STOP_SOUND              ""
//#define STOP_SOUND_TF2        "weapons/flame_thrower_end.wav"
#define STOP_SOUND_TF2          "weapons/flame_thrower_dg_end.wav"

#define LOOP_SOUND              "vehicles/airboat/fan_blade_fullthrottle_loop1.wav"
//#define LOOP_SOUND_TF2        "weapons/flame_thrower_loop.wav"
#define LOOP_SOUND_TF2          "weapons/flame_thrower_dg_loop.wav"
#define CRIT_SOUND              "weapons/flame_thrower_dg_loop_crit.wav"
#define SOUND_EXPLODE           "ambient/explosions/explode_8.wav"

//Use SourceCraft sounds if it is present
#if defined SOURCECRAFT
	#define EMPTY_SOUND  	    "sc/outofgas.wav"
	#define EMPTY_SOUND_TF2     "sc/outofgas.wav"

	#define REFUEL_SOUND        "sc/transmission.wav"
	#define REFUEL_SOUND_TF2    "sc/transmission.wav"
#else
	#define EMPTY_SOUND         "common/bugreporter_failed.wav"
	#define EMPTY_SOUND_TF2     "weapons/syringegun_reload_air2.wav"

	#define REFUEL_SOUND        "hl1/fvox/activated.wav"
	#define REFUEL_SOUND_TF2    "hl1/fvox/activated.wav"
#endif

#define EFFECT_BURNER_RED       "flamethrower"
#define EFFECT_BURNER_RED_CRIT  "flamethrower_crit_red"
#define EFFECT_BURNER_BLU       "flamethrower_blue"
#define EFFECT_BURNER_BLU_CRIT  "flamethrower_crit_blue"

#define EFFECT_BURNER_EMPTY     "muzzle_minigun"
#define EFFECT_BURNER_WARP      "pyro_blast_warp"
#define EFFECT_BURNER_WARP2     "pyro_blast_warp2"

#define EFFECT_TRAIL            "rockettrail_!"

#define EXPLOSION_MODEL         "sprites/sprite_fire01.vmt"

// TF2 Classes

#define SCOUT                   1
#define SNIPER                  2
#define SOLDIER                 3
#define DEMO                    4
#define MEDIC                   5
#define HEAVY                   6
#define PYRO                    7
#define SPY                     8
#define ENGIE                   9
#define CLS_MAX                10

// DOD Classes

#define RIFLEMAN                0
#define ASSAULT                 1
#define SUPPORT                 2
#define DODSNIPER               3
#define MG                      4
#define ROCKETMAN               5

// ConVars
new Handle:sm_jetpack		        = INVALID_HANDLE;
new Handle:sm_jetpack_start_sound	= INVALID_HANDLE;
new Handle:sm_jetpack_stop_sound	= INVALID_HANDLE;
new Handle:sm_jetpack_loop_sound	= INVALID_HANDLE;
new Handle:sm_jetpack_crit_sound	= INVALID_HANDLE;
new Handle:sm_jetpack_empty_sound	= INVALID_HANDLE;
new Handle:sm_jetpack_refuel_sound	= INVALID_HANDLE;
new Handle:sm_jetpack_speed	        = INVALID_HANDLE;
new Handle:sm_jetpack_volume        = INVALID_HANDLE;
new Handle:sm_jetpack_fuel	        = INVALID_HANDLE;
new Handle:sm_jetpack_team          = INVALID_HANDLE;
new Handle:sm_jetpack_onspawn	    = INVALID_HANDLE;
new Handle:sm_jetpack_announce	    = INVALID_HANDLE;
new Handle:sm_jetpack_adminonly	    = INVALID_HANDLE;
new Handle:sm_jetpack_refueling_time= INVALID_HANDLE;
new Handle:sm_jetpack_max_refuels   = INVALID_HANDLE;
new Handle:sm_jetpack_noflag        = INVALID_HANDLE;
new Handle:sm_jetpack_gravity       = INVALID_HANDLE;
new Handle:sm_jetpack_burn       	= INVALID_HANDLE;
new Handle:sm_jetpack_burn_range 	= INVALID_HANDLE;
new Handle:sm_jetpack_burn_damage	= INVALID_HANDLE;
new Handle:sm_jetpack_explode       = INVALID_HANDLE;
new Handle:sm_jetpack_explode_fuel  = INVALID_HANDLE;
new Handle:sm_jetpack_explode_range = INVALID_HANDLE;
new Handle:sm_jetpack_explode_damage= INVALID_HANDLE;
new Handle:sm_jetpack_allow[CLS_MAX]= { INVALID_HANDLE, ...};
new Handle:sm_jetpack_rate[CLS_MAX] = { INVALID_HANDLE, ...};
new Handle:tf_weapon_criticals      = INVALID_HANDLE;
new Handle:mp_friendlyfire       	= INVALID_HANDLE;

new Handle:hCookie                  = INVALID_HANDLE;
new Handle:hAdminMenu               = INVALID_HANDLE;
new TopMenuObject:oGiveJetpack      = INVALID_TOPMENUOBJECT;
new TopMenuObject:oTakeJetpack      = INVALID_TOPMENUOBJECT;

// SendProp Offsets
new g_iMoveCollide	                = -1;
new g_iVelocity		                = -1;

new g_JetpackLight[MAXPLAYERS + 1]  = { INVALID_ENT_REFERENCE, ... };
new g_JetpackParticle[MAXPLAYERS + 1][3];

// Soundfiles
new String:g_StartSound[PLATFORM_MAX_PATH];
new String:g_StopSound[PLATFORM_MAX_PATH];
new String:g_LoopSound[PLATFORM_MAX_PATH];
new String:g_CritSound[PLATFORM_MAX_PATH];
new String:g_EmptySound[PLATFORM_MAX_PATH];
new String:g_RefuelSound[PLATFORM_MAX_PATH];

// Is Jetpack Enabled
new bool:g_bHasJetpack[MAXPLAYERS + 1];
new bool:g_bUseJetpack[MAXPLAYERS + 1];
new bool:g_bFromNative[MAXPLAYERS + 1];
new bool:g_bJetpackOn[MAXPLAYERS + 1];
new bool:g_bCrits[MAXPLAYERS + 1];

// Fuel for the Jetpacks
new g_iFuel[MAXPLAYERS + 1];
new g_iRate[MAXPLAYERS + 1];
new g_iMaxRefuels[MAXPLAYERS + 1];
new g_iRefuelCount[MAXPLAYERS + 1];
new g_iRefuelAmount[MAXPLAYERS + 1];
new Float:g_JumpPushedTime[MAXPLAYERS+1];
new Float:g_fRefuelingTime[MAXPLAYERS + 1];

// Jetpack burn
new bool:g_bBurn[MAXPLAYERS + 1];
new Float:g_BurnRange[MAXPLAYERS+1];
new g_BurnDamage[MAXPLAYERS + 1];

// Jetpack explosions
new bool:g_bExplode[MAXPLAYERS + 1];
new Float:g_ExplodeRange[MAXPLAYERS+1];
new g_iExplodeDamage[MAXPLAYERS + 1];
new g_iExplodeFuel[MAXPLAYERS + 1];

// Timer For GameFrame
new Float:g_fTimer	= 0.0;
new Float:g_fCheck	= 0.0;

// Native interface settings
new g_iNativeRate[MAXPLAYERS + 1];
new bool:g_bNativeOverride = false;
new g_iNativeJetpacks      = 0;
new g_FilteredEntity       = -1;
new g_ExplosionIndex;

// Forward handles
new Handle:fwdOnJetpack;
new Handle:fwdOnJetpackBurn;
new Handle:fwdOnJetpackExplode;

#if defined _ztf2grab_included
    stock bool:m_GravgunAvailable = false;
#endif

#if defined SOURCECRAFT
    stock bool:m_SourceCraftAvailable = false;
#endif

public Plugin:myinfo =
{
    name = "Jetpack",
    author = "Knagg0,Naris",
    description = "Adds a jetpack to fly around the map with",
    version = PLUGIN_VERSION,
    url = "http://www.mfzb.de"
};

/**
 * Description: Stocks to damage a player or an entity using a point_hurt entity.
 */
//#tryinclude <damage>
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
 * Description: Stocks to return information about TF2 player condition, etc.
 */
#tryinclude <tf2_player>
#if !defined _dod_included
	#define TF2_IsPlayerSlowed(%1)              TF2_IsPlayerInCondition(%1,TFCond_Slowed)
	#define TF2_IsPlayerZoomed(%1)              TF2_IsPlayerInCondition(%1,TFCond_Zoomed)
	#define TF2_IsPlayerDisguised(%1)           TF2_IsPlayerInCondition(%1,TFCond_Disguised)
	#define TF2_IsPlayerCloaked(%1)             TF2_IsPlayerInCondition(%1,TFCond_Cloaked)
	#define TF2_IsPlayerTaunting(%1)            TF2_IsPlayerInCondition(%1,TFCond_Taunting)
    #define TF2_IsPlayerUbercharged(%1)         TF2_IsPlayerInCondition(%1,TFCond_Ubercharged)
    #define TF2_IsPlayerKritzkrieged(%1)        TF2_IsPlayerInCondition(%1,TFCond_Kritzkrieged)
	#define TF2_IsPlayerDeadRingered(%1)        TF2_IsPlayerInCondition(%1,TFCond_DeadRingered)
	#define TF2_IsPlayerBonked(%1)              TF2_IsPlayerInCondition(%1,TFCond_Bonked)
	#define TF2_IsPlayerDazed(%1)               TF2_IsPlayerInCondition(%1,TFCond_Dazed)
    #define TF2_IsPlayerCritCola(%1)            TF2_IsPlayerInCondition(%1,TFCond_CritCola)
    #define TF2_IsPlayerHalloweenCritCandy(%1)  TF2_IsPlayerInCondition(%1,TFCond_HalloweenCritCandy)
    #define TF2_IsPlayerCritHype(%1)            TF2_IsPlayerInCondition(%1,TFCond_CritHype)
    #define TF2_IsPlayerCritOnFirstBlood(%1)    TF2_IsPlayerInCondition(%1,TFCond_CritOnFirstBlood)
    #define TF2_IsPlayerCritOnWin(%1)           TF2_IsPlayerInCondition(%1,TFCond_CritOnWin)
    #define TF2_IsPlayerCritOnFlagCapture(%1)   TF2_IsPlayerInCondition(%1,TFCond_CritOnFlagCapture)
    #define TF2_IsPlayerCritOnKill(%1)          TF2_IsPlayerInCondition(%1,TFCond_CritOnKill)

    #define TF2_IsPlayerCrit(%1) (TF2_IsPlayerKritzkrieged(%1)       || \
                                  TF2_IsPlayerCritCola(%1)           || \
                                  TF2_IsPlayerHalloweenCritCandy(%1) || \
                                  TF2_IsPlayerCritHype(%1)           || \
                                  TF2_IsPlayerCritOnFirstBlood(%1)   || \
                                  TF2_IsPlayerCritOnWin(%1)          || \
                                  TF2_IsPlayerCritOnFlagCapture(%1)  || \
                                  TF2_IsPlayerCritOnKill(%1))
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

/**
 * Description: stock for SendTopMessage
 */
#tryinclude <topmessage>
#if !defined _topmessage_included
	stock SendTopMessage(client, level, time, r, g, b, a, String:text[], any:...)
	{
		new String:message[100];
		VFormat(message,sizeof(message),text, 9);
		
		new Handle:kv = CreateKeyValues("message", "title", message);
		KvSetColor(kv, "color", r, g, b, a);
		KvSetNum(kv, "level", level);
		KvSetNum(kv, "time", time);

		CreateDialog(client, kv, DialogType_Msg);

		CloseHandle(kv);
	}
#endif

/**
 * Description: Functions to show TF2 particles
 */
#tryinclude "particle"
#if !defined _particle_included
	// Particle Attachment Types  -------------------------------------------------
	enum ParticleAttachmentType
	{
		NoAttach = 0,
		Attach,
		AttachMaintainOffset
	};

	// Particles ------------------------------------------------------------------

	/* CreateParticle()
	**
	** Creates a particle at an entity's position. Attach determines the attachment
	** type (0 = not attached, 1 = normal attachment, 2 = head attachment). Allows
	** offsets from the entity's position.
	** ------------------------------------------------------------------------- */
	stock CreateParticle(const String:particleType[], Float:time=5.0, entity=0,
						 ParticleAttachmentType:attach=Attach,
						 const String:attachToBone[]="head",
						 const Float:pos[3]=NULL_VECTOR,
						 const Float:ang[3]=NULL_VECTOR,
						 Timer:deleteFunc=Timer:0,
						 &Handle:timerHandle=INVALID_HANDLE)
	{
		new particle = CreateEntityByName("info_particle_system");
		if (particle > 0 && IsValidEdict(particle))
		{
			decl String:tName[32];
			Format(tName, sizeof(tName), "target%i", entity);
			DispatchKeyValue(entity, "targetname", tName);

			DispatchKeyValue(particle, "targetname", "sc2particle");
			DispatchKeyValue(particle, "parentname", tName);
			DispatchKeyValue(particle, "effect_name", particleType);

			if (attach > NoAttach)
			{
				SetVariantString("!activator");
				AcceptEntityInput(particle, "SetParent", entity, particle, 0);

				if (attachToBone[0] != '\0')
				{
					SetVariantString(attachToBone);
					AcceptEntityInput(particle, (attach >= AttachMaintainOffset)
												? "SetParentAttachmentMaintainOffset"
												: "SetParentAttachment",
									  particle, particle, 0);
				}
			}

			DispatchSpawn(particle);
			ActivateEntity(particle);

			TeleportEntity(particle, pos, ang, NULL_VECTOR);
			AcceptEntityInput(particle, "start");

			if (time > 0.0)
			{
				timerHandle = CreateTimer(time, deleteFunc ? deleteFunc : DeleteParticles,
										  EntIndexToEntRef(particle));
			}
		}
		else
			LogError("CreateParticle: could not create info_particle_system");

		return particle;
	}

	stock DeleteParticle(&particleRef)
	{
        if (particleRef != INVALID_ENT_REFERENCE)
        {
            new particle = EntRefToEntIndex(particleRef);
            if (particle > 0 && IsValidEntity(particle))
                AcceptEntityInput(particle, "kill");

            particleRef = INVALID_ENT_REFERENCE;
        }
    }

	public Action:DeleteParticles(Handle:timer, any:particleRef)
	{
		DeleteParticle(particleRef);
		return Plugin_Stop;
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

/**
 * Description: Manage precaching resources.
 */
#tryinclude "ResourceManager"
#if !defined _ResourceManager_included
    #define AUTO_DOWNLOAD   -1
	#define DONT_DOWNLOAD    0
	#define DOWNLOAD         1
	#define ALWAYS_DOWNLOAD  2

	stock SetupSound(const String:sound[], bool:force=false, download=AUTO_DOWNLOAD,
	                 bool:precache=false, bool:preload=false)
	{
        #pragma unused force, precache, preload

        if (download != DONT_DOWNLOAD)
        {
            decl String:dl[PLATFORM_MAX_PATH+1];
            Format(dl, sizeof(dl), "sound/%s", sound);

            if (FileExists(dl))
            {
                if (download < 0)
                {
                    if (!strncmp(dl, "ambient", 7) ||
                        !strncmp(dl, "beams", 5) ||
                        !strncmp(dl, "buttons", 7) ||
                        !strncmp(dl, "coach", 5) ||
                        !strncmp(dl, "combined", 8) ||
                        !strncmp(dl, "commentary", 10) ||
                        !strncmp(dl, "common", 6) ||
                        !strncmp(dl, "doors", 5) ||
                        !strncmp(dl, "friends", 7) ||
                        !strncmp(dl, "hl1", 3) ||
                        !strncmp(dl, "items", 5) ||
                        !strncmp(dl, "midi", 4) ||
                        !strncmp(dl, "misc", 4) ||
                        !strncmp(dl, "music", 5) ||
                        !strncmp(dl, "npc", 3) ||
                        !strncmp(dl, "physics", 7) ||
                        !strncmp(dl, "pl_hoodoo", 9) ||
                        !strncmp(dl, "plats", 5) ||
                        !strncmp(dl, "player", 6) ||
                        !strncmp(dl, "resource", 8) ||
                        !strncmp(dl, "replay", 6) ||
                        !strncmp(dl, "test", 4) ||
                        !strncmp(dl, "ui", 2) ||
                        !strncmp(dl, "vehicles", 8) ||
                        !strncmp(dl, "vo", 2) ||
                        !strncmp(dl, "weapons", 7))
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
                    AddFileToDownloadsTable(dl);
                }
            }
        }

        PrecacheSound(sound, preload);
    }

    #define PrepareAndEmitSoundToClient EmitSoundToClient
    #define PrepareAndEmitSoundToAll    EmitSoundToAll

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
/*****************************************************************/

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Natives
    CreateNative("ControlJetpack",Native_ControlJetpack);
    CreateNative("HasJetpack",Native_HasJetpack);
    CreateNative("IsJetpackOn",Native_IsJetpackOn);
    CreateNative("GetJetpackFuel",Native_GetJetpackFuel);
    CreateNative("GetJetpackRate",Native_GetJetpackRate);
    CreateNative("GetJetpackRefuelingTime",Native_GetJetpackRefuelingTime);
    CreateNative("SetJetpackFuel",Native_SetJetpackFuel);
    CreateNative("SetJetpackRate",Native_SetJetpackRate);
    CreateNative("SetJetpackRefuelingTime",Native_SetJetpackRefuelingTime);
    CreateNative("GiveJetpack",Native_GiveJetpack);
    CreateNative("TakeJetpack",Native_TakeJetpack);
    CreateNative("GiveJetpackFuel",Native_GiveJetpackFuel);
    CreateNative("TakeJetpackFuel",Native_TakeJetpackFuel);
    CreateNative("StartJetpack",Native_StartJetpack);
    CreateNative("StopJetpack",Native_StopJetpack);

    fwdOnJetpack=CreateGlobalForward("OnJetpack",ET_Hook,Param_Cell);
    fwdOnJetpackBurn=CreateGlobalForward("OnJetpackBurn",ET_Hook,Param_Cell,Param_Cell,Param_CellByRef);
    fwdOnJetpackExplode=CreateGlobalForward("OnJetpackExplode",ET_Hook,Param_Cell,Param_Cell,Param_CellByRef);

    RegPluginLibrary("jetpack");

    return APLRes_Success;
}

public OnPluginStart()
{
    // Initialize g_JetpackParticle[][] array
    for (new i= 0; i < sizeof(g_JetpackParticle); i++)
    {
        for (new j = 0; j < sizeof(g_JetpackParticle[]); j++)
            g_JetpackParticle[i][j] = INVALID_ENT_REFERENCE;
    }

    // Create ConCommands
    RegConsoleCmd("+jetpack", JetpackPressed, "use jetpack (keydown)", FCVAR_GAMEDLL);
    RegConsoleCmd("-jetpack", JetpackReleased, "use jetpack (keyup)", FCVAR_GAMEDLL);

    // Register admin cmds
    RegAdminCmd("sm_jetpack_give",Command_GiveJetpack,ADMFLAG_JETPACK,"","give a jetpack to a player");
    RegAdminCmd("sm_jetpack_take",Command_TakeJetpack,ADMFLAG_JETPACK,"","take the jetpack from a player");

    // Hook events
    HookEvent("player_spawn", PlayerSpawnEvent);
    HookEvent("player_death", PlayerDeathEvent, EventHookMode_Pre);

    // Find SendProp Offsets
    if((g_iMoveCollide = FindSendPropOffs("CBaseEntity", "movecollide")) == -1)
        LogError("Could not find offset for CBaseEntity::movecollide");

    if((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
        LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");

    // Create ConVars
    sm_jetpack = CreateConVar("sm_jetpack", "0", "enable jetpacks on the server", FCVAR_PLUGIN);
    sm_jetpack_speed = CreateConVar("sm_jetpack_speed", "100", "speed of the jetpack", FCVAR_PLUGIN);
    sm_jetpack_volume = CreateConVar("sm_jetpack_volume", "0.5", "volume of the jetpack sound", FCVAR_PLUGIN);
    sm_jetpack_fuel = CreateConVar("sm_jetpack_fuel", "-1", "amount of fuel to start with (-1 == unlimited)", FCVAR_PLUGIN);
    sm_jetpack_max_refuels = CreateConVar("sm_jetpack_max_refuels", "-1", "number of times the jetpack can be refueled (-1 == unlimited)", FCVAR_PLUGIN);
    sm_jetpack_refueling_time = CreateConVar("sm_jetpack_refueling_time", "30.0", "amount of time to wait before refueling", FCVAR_PLUGIN);
    sm_jetpack_onspawn = CreateConVar("sm_jetpack_onspawn", "0", "enable giving players a jetpack when they spawn", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    sm_jetpack_team = CreateConVar("sm_jetpack_team", "0", "team restriction (0=all use, 2 or 3 to only allowed specified team to have a jetpack", FCVAR_PLUGIN, true, 0.0, true, 3.0);
    sm_jetpack_burn = CreateConVar("sm_jetpack_burn", "1", "Burn enemies that a jetpack's flame hits", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    sm_jetpack_burn_range = CreateConVar("sm_jetpack_burn_range", "500.0", "Range of the jetpack's flame hits", FCVAR_PLUGIN);
    sm_jetpack_burn_damage = CreateConVar("sm_jetpack_burn_damage", "7", "Damage of the jetpack's flame hits", FCVAR_PLUGIN);
    sm_jetpack_explode = CreateConVar("sm_jetpack_explode", "1", "Players with a jetpack explode when they die", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    sm_jetpack_explode_fuel = CreateConVar("sm_jetpack_explode_fuel", "10", "Minimum fuel to explode", FCVAR_PLUGIN);
    sm_jetpack_explode_range = CreateConVar("sm_jetpack_explode_range", "1000.0", "Range of jetpack explosions");
    sm_jetpack_explode_damage = CreateConVar("sm_jetpack_explode_damage", "1", "Damage of jetpack explosons");

    sm_jetpack_gravity = CreateConVar("sm_jetpack_gravity", "1", "Set to 1 to have gravity affect the jetpack (MOVETYPE_FLYGRAVITY), 0 for no gravity (MOVETYPE_FLY).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    sm_jetpack_announce = CreateConVar("sm_jetpack_announce","0","This will enable announcements that jetpacks are available", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    sm_jetpack_adminonly = CreateConVar("sm_jetpack_adminonly", "0", "only allows admins to have jetpacks when set to 1", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    tf_weapon_criticals = FindConVar("tf_weapon_criticals");
    mp_friendlyfire = FindConVar("mp_friendlyfire");

    // Disable noflag if the game isn't TF2.
    if (GetGameType() == tf2)
    {
        sm_jetpack_start_sound = CreateConVar("sm_jetpack_start_sound", START_SOUND_TF2, "the jetpack start sound", FCVAR_PLUGIN);
        sm_jetpack_stop_sound = CreateConVar("sm_jetpack_stop_sound", STOP_SOUND_TF2, "the jetpack stop sound", FCVAR_PLUGIN);
        sm_jetpack_loop_sound = CreateConVar("sm_jetpack_loop_sound", LOOP_SOUND_TF2, "the jetpack loop sound", FCVAR_PLUGIN);
        sm_jetpack_crit_sound = CreateConVar("sm_jetpack_crit_sound", CRIT_SOUND, "the jetpack crit loop sound", FCVAR_PLUGIN);
        sm_jetpack_empty_sound = CreateConVar("sm_jetpack_empty_sound", EMPTY_SOUND_TF2, "the jetpack empty sound", FCVAR_PLUGIN);
        sm_jetpack_refuel_sound = CreateConVar("sm_jetpack_refuel_sound", REFUEL_SOUND_TF2, "the jetpack refuel sound", FCVAR_PLUGIN);
        sm_jetpack_noflag = CreateConVar("sm_jetpack_noflag", "1", "When enabled, prevents TF2 flag carrier from using the jetpack", FCVAR_PLUGIN);

        sm_jetpack_rate[SCOUT] = CreateConVar("sm_jetpack_rate_scout", "1", "rate at which the jetpack consumes fuel for scouts");
        sm_jetpack_rate[SNIPER] = CreateConVar("sm_jetpack_rate_sniper", "1", "rate at which the jetpack consumes fuel for snipers");
        sm_jetpack_rate[SOLDIER] = CreateConVar("sm_jetpack_rate_soldier", "1", "rate at which the jetpack consumes fuel for soldiers");
        sm_jetpack_rate[DEMO] = CreateConVar("sm_jetpack_rate_demo", "1", "rate at which the jetpack consumes fuel for demo men");
        sm_jetpack_rate[MEDIC] = CreateConVar("sm_jetpack_rate_medic", "1", "rate at which the jetpack consumes fuel for medics");
        sm_jetpack_rate[HEAVY] = CreateConVar("sm_jetpack_rate_heavy", "2", "rate at which the jetpack consumes fuel for heavys");
        sm_jetpack_rate[PYRO] = CreateConVar("sm_jetpack_rate_pyro", "1", "rate at which the jetpack consumes fuel for pyros");
        sm_jetpack_rate[SPY] = CreateConVar("sm_jetpack_rate_spy", "1", "rate at which the jetpack consumes fuel for spys");
        sm_jetpack_rate[ENGIE] = CreateConVar("sm_jetpack_rate_engineer", "1", "rate at which the jetpack consumes fuel for engineers");

        sm_jetpack_allow[SCOUT] = CreateConVar("sm_jetpack_allow_scout", "1", "allow scouts to have a jetpack");
        sm_jetpack_allow[SNIPER] = CreateConVar("sm_jetpack_allow_sniper", "1", "allow snipers to have a jetpack");
        sm_jetpack_allow[SOLDIER] = CreateConVar("sm_jetpack_allow_soldier", "1", "allow soldiers to have a jetpack");
        sm_jetpack_allow[DEMO] = CreateConVar("sm_jetpack_allow_demo", "1", "allow demo men to have a jetpack");
        sm_jetpack_allow[MEDIC] = CreateConVar("sm_jetpack_allow_medic", "1", "allow medics to have a jetpack");
        sm_jetpack_allow[HEAVY] = CreateConVar("sm_jetpack_allow_heavy", "1", "allow heavys to have a jetpack");
        sm_jetpack_allow[PYRO] = CreateConVar("sm_jetpack_allow_pyro", "1", "allow pyros to have a jetpack");
        sm_jetpack_allow[SPY] = CreateConVar("sm_jetpack_allow_spy", "1", "allow spys to have a jetpack");
        sm_jetpack_allow[ENGIE] = CreateConVar("sm_jetpack_allow_engineer", "1", "allow engineers to have a jetpack");
    }
    else
    {
        sm_jetpack_start_sound = CreateConVar("sm_jetpack_start_sound", START_SOUND, "the jetpack start sound", FCVAR_PLUGIN);
        sm_jetpack_stop_sound = CreateConVar("sm_jetpack_stop_sound", STOP_SOUND, "the jetpack stop sound", FCVAR_PLUGIN);
        sm_jetpack_loop_sound = CreateConVar("sm_jetpack_loop_sound", LOOP_SOUND, "the jetpack loop sound", FCVAR_PLUGIN);
        sm_jetpack_empty_sound = CreateConVar("sm_jetpack_empty_sound", EMPTY_SOUND, "the jetpack empty sound", FCVAR_PLUGIN);
        sm_jetpack_refuel_sound = CreateConVar("sm_jetpack_refuel_sound", REFUEL_SOUND, "the jetpack refuel sound", FCVAR_PLUGIN);

        if (GameType == dod)
        {
            sm_jetpack_rate[RIFLEMAN] = CreateConVar("sm_jetpack_rate_rifleman", "1", "rate at which the jetpack consumes fuel for riflemen");
            sm_jetpack_rate[ASSAULT] = CreateConVar("sm_jetpack_rate_assault", "1", "rate at which the jetpack consumes fuel for assault");
            sm_jetpack_rate[SUPPORT] = CreateConVar("sm_jetpack_rate_support", "1", "rate at which the jetpack consumes fuel for support");
            sm_jetpack_rate[DODSNIPER] = CreateConVar("sm_jetpack_rate_sniper", "1", "rate at which the jetpack consumes fuel for snipers");
            sm_jetpack_rate[MG] = CreateConVar("sm_jetpack_rate_mg_type", "2", "rate at which the jetpack consumes fuel for machine gunners");
            sm_jetpack_rate[ROCKETMAN] = CreateConVar("sm_jetpack_rate_rocket", "1", "rate at which the jetpack consumes fuel for rocket men");

            sm_jetpack_allow[RIFLEMAN] = CreateConVar("sm_jetpack_allow_rifleman", "1", "allow riflemen to have a jetpack");
            sm_jetpack_allow[ASSAULT] = CreateConVar("sm_jetpack_allow_assault", "1", "allow assault to have a jetpack");
            sm_jetpack_allow[SUPPORT] = CreateConVar("sm_jetpack_allow_support", "1", "allow support to have a jetpack");
            sm_jetpack_allow[DODSNIPER] = CreateConVar("sm_jetpack_allow_sniper", "1", "allow snipers to have a jetpack");
            sm_jetpack_allow[MG] = CreateConVar("sm_jetpack_allow_mg_type", "1", "allow gunners to have a jetpack");
            sm_jetpack_allow[ROCKETMAN] = CreateConVar("sm_jetpack_allow_rocket", "1", "allow rocket men to have a jetpack");
        }
        else
        {
            sm_jetpack_rate[0] = CreateConVar("sm_jetpack_rate", "1", "rate at which the jetpack consumes fuel");
        }
    }

    //Setup preferences cookie
    hCookie = RegClientCookie("jetpack", "Jetpack can be activated with +JUMP", CookieAccess_Private);
    SetCookieMenuItem(PrefsMenu, 0, "JetPack Prefs");

    AutoExecConfig();

    CreateConVar("sm_jetpack_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);

    /* Account for late loading */
    new Handle:topmenu;
    if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
    {
        OnAdminMenuReady(topmenu);
    }

    #if defined _ztf2grab_included
        m_GravgunAvailable = LibraryExists("ztf2grab");
    #endif

    #if defined SOURCECRAFT
        m_SourceCraftAvailable = LibraryExists("SourceCraft");
    #endif
}

#if defined _ztf2grab_included || defined SOURCECRAFT
public OnLibraryAdded(const String:name[])
{
#if defined _ztf2grab_included
    if (StrEqual(name, "ztf2grab"))
    {
        if (!m_GravgunAvailable)
            m_GravgunAvailable = true;
    }
#endif

#if defined SOURCECRAFT
    if (StrEqual(name, "SourceCraft"))
    {
        if (!m_SourceCraftAvailable)
            m_SourceCraftAvailable = true;
    }
#endif
}
#endif

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "adminmenu"))
        hAdminMenu = INVALID_HANDLE;

#if defined _ztf2grab_included
    else if (StrEqual(name, "ztf2grab"))
        m_GravgunAvailable = false;
#endif

#if defined SOURCECRAFT
    else if (StrEqual(name, "SourceCraft"))
        m_SourceCraftAvailable = false;
#endif
}

public OnMapStart()
{
    g_fTimer = g_fCheck = 0.0;

    SetupSound(SOUND_EXPLODE, true, DONT_DOWNLOAD, true, true);

    SetupModel(EXPLOSION_MODEL, g_ExplosionIndex, false, true);
}

public OnMapEnd()
{
    CleanupDamageEntity();
}

public OnConfigsExecuted()
{
    GetConVarString(sm_jetpack_empty_sound, g_EmptySound, sizeof(g_EmptySound));
    SetupSound(g_EmptySound, true, AUTO_DOWNLOAD, true, true);

    GetConVarString(sm_jetpack_refuel_sound, g_RefuelSound, sizeof(g_RefuelSound));
    SetupSound(g_RefuelSound, true, AUTO_DOWNLOAD, true, true);

    GetConVarString(sm_jetpack_start_sound, g_StartSound, sizeof(g_StartSound));
    SetupSound(g_StartSound, true, AUTO_DOWNLOAD, true, true);

    GetConVarString(sm_jetpack_stop_sound, g_StopSound, sizeof(g_StopSound));
    SetupSound(g_StopSound, true, AUTO_DOWNLOAD, true, true);

    GetConVarString(sm_jetpack_loop_sound, g_LoopSound, sizeof(g_LoopSound));
    SetupSound(g_LoopSound, true, AUTO_DOWNLOAD, true, true);

    if (sm_jetpack_crit_sound == INVALID_HANDLE)
        g_CritSound[0] = '\0';
    else
    {
        GetConVarString(sm_jetpack_crit_sound, g_CritSound, sizeof(g_CritSound));
        SetupSound(g_CritSound, true, AUTO_DOWNLOAD, true, true);
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new index=GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index

    if (g_bHasJetpack[index] && g_bFromNative[index])
    {
        g_bCrits[index] = false;
        g_iRefuelCount[index] = 0;
        g_JumpPushedTime[index] = 0.0;
        g_iFuel[index] = g_iRefuelAmount[index];

        if (g_iNativeRate[index] < 0)
        {
            new class = 0;
            switch (GameType)
            {
                case tf2: class = _:TF2_GetPlayerClass(index);
                case dod: class = _:DOD_GetPlayerClass(index); 
            }
            new Handle:rate_cvar = sm_jetpack_rate[class];
            g_iRate[index] = rate_cvar ? GetConVarInt(rate_cvar) : 1;
        }
        else
            g_iRate[index] = g_iNativeRate[index];
    }
    else if (GetConVarBool(sm_jetpack) && GetConVarBool(sm_jetpack_onspawn))
    {
        // Check for Admin Only
        if (GetConVarBool(sm_jetpack_adminonly))
        {
            new AdminId:aid = GetUserAdmin(index);
            if (aid == INVALID_ADMIN_ID || !GetAdminFlag(aid, Admin_Generic, Access_Effective))
            {
                g_bHasJetpack[index] = false;
                return;
            }
        }

        // Check for allowed teams.
        new team = GetConVarInt(sm_jetpack_team);
        if (team > 0 && team != GetClientTeam(index))
        {
            g_bHasJetpack[index] = false;
            return;
        }

        new class = 0;
        switch (GameType)
        {
            case tf2: class = _:TF2_GetPlayerClass(index);
            case dod: class = _:DOD_GetPlayerClass(index); 
        }

        // Check for allowed classes.
        new Handle:allow_cvar = sm_jetpack_allow[class];
        if (allow_cvar != INVALID_HANDLE && !GetConVarBool(allow_cvar))
        {
            g_bHasJetpack[index] = false;
            return;
        }

        new Handle:rate_cvar = sm_jetpack_rate[class];
        g_iRate[index] = rate_cvar ? GetConVarInt(rate_cvar) : 1;
        g_iFuel[index] = g_iRefuelAmount[index] = GetConVarInt(sm_jetpack_fuel);
        g_fRefuelingTime[index] = GetConVarFloat(sm_jetpack_refueling_time);
        g_iMaxRefuels[index] = GetConVarInt(sm_jetpack_max_refuels);
        g_bBurn[index] = GetConVarBool(sm_jetpack_burn);
        g_BurnRange[index] = GetConVarFloat(sm_jetpack_burn_range);
        g_BurnDamage[index] = GetConVarInt(sm_jetpack_burn_damage);
        g_bExplode[index] = GetConVarBool(sm_jetpack_explode);
        g_iExplodeFuel[index] = GetConVarInt(sm_jetpack_explode_fuel);
        g_ExplodeRange[index] = GetConVarFloat(sm_jetpack_explode_range);
        g_iExplodeDamage[index] = GetConVarInt(sm_jetpack_explode_damage);
        g_bCrits[index] = false;
        g_bHasJetpack[index] = true;
        g_iRefuelCount[index] = 0;
        g_JumpPushedTime[index] = 0.0;

        if (GetConVarBool(sm_jetpack_announce))
        {
            PrintToChat(index,"%c[Jetpack] %cIs enabled, valid commands are: [%c+jetpack%c] [%c-jetpack%c]",
                        COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
        }
    }
    else
        g_bHasJetpack[index] = false;
}

public Action:PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    new index = GetClientOfUserId(userid); // Get clients index
    if (index > 0 && g_bHasJetpack[index])
        CreateTimer(0.1, HookRagdoll, userid);

    return Plugin_Continue;
}	

public Action:HookRagdoll(Handle:hTimer, any:userid)
{
    new index=GetClientOfUserId(userid); // Get clients index
    if (index > 0 && g_bExplode[index] && g_iFuel[index] > g_iExplodeFuel[index])
    {
        new bool:burning = false;
        new iRagdoll = GetEntPropEnt(index, Prop_Send, "m_hRagdoll");
        if (IsValidEdict(iRagdoll))
        {
            burning = bool:GetEntProp(iRagdoll, Prop_Send, "m_bBurning");

            decl String:sDissolveName[32];
            Format(sDissolveName, sizeof(sDissolveName), "dis_%d", index);
            DispatchKeyValue(iRagdoll, "targetname", sDissolveName);

            new iDissolver = CreateEntityByName("env_entity_dissolver");
            if (IsValidEdict(iDissolver))
            {
                DispatchKeyValue(iDissolver, "dissolvetype", "0");
                DispatchKeyValue(iDissolver, "target", sDissolveName);
                AcceptEntityInput(iDissolver, "Dissolve");
                AcceptEntityInput(iDissolver, "kill");
            }
        }

        new Handle:hTimerData;
        CreateDataTimer(burning ? 0.1 : 2.0, Explode, hTimerData);

        WritePackCell(hTimerData, index);
        WritePackCell(hTimerData, g_iFuel[index]);

        decl Float:fOrigin[3];
        GetEntPropVector(index, Prop_Send, "m_vecOrigin", fOrigin);
        WritePackFloat(hTimerData, fOrigin[0]);
        WritePackFloat(hTimerData, fOrigin[1]);
        WritePackFloat(hTimerData, fOrigin[2]);
    }
}

public Action:Explode(Handle:hTimer, Handle:hData)
{
    new bool:bFF = GetConVarBool(mp_friendlyfire);

    ResetPack(hData);
    new index = ReadPackCell(hData);

    new fuel = ReadPackCell(hData);

    decl Float:fOrigin[3];
    fOrigin[0] = ReadPackFloat(hData);
    fOrigin[1] = ReadPackFloat(hData);
    fOrigin[2] = ReadPackFloat(hData);

    PrepareAndEmitSoundToAll(SOUND_EXPLODE, .origin=fOrigin);

    PrepareModel(EXPLOSION_MODEL, g_ExplosionIndex, true);
    TE_SetupExplosion(fOrigin, g_ExplosionIndex, 10.0, 1, 0, 1250, 500);
    TE_SendToAll();

    TE_SetupExplosion(fOrigin, g_ExplosionIndex, 10.0, 1, 0, 200, 1250);
    TE_SendToAll();

    if (GetClientTeam(index) > 1)
    {
        for (new victim = 1; victim <= MaxClients; victim++)
        {
            if (victim != index && IsClientInGame(victim) && IsPlayerAlive(victim) && GetClientTeam(victim) > 1 )
            {
                if (bFF || GetClientTeam(victim) != GetClientTeam(index) )
                {
                    decl Float:victimPos[3];
                    GetClientAbsOrigin(victim, victimPos);

                    new Float:fuelRatio = float(fuel) / 100.0;
                    if (fuelRatio > 1.0)
                        fuelRatio = 1.0;

                    new Float:distance;
                    new Float:range = g_ExplodeRange[index] * fuelRatio;
                    if (CanTarget(index, fOrigin, victim, victimPos, range, distance))
                    {
                        #if defined SOURCECRAFT
                            if (m_SourceCraftAvailable && GetImmunity(victim, Immunity_Explosion))
                                continue;
                        #endif

                        new max = g_iExplodeDamage[index];
                        new damage = RoundFloat(((range - distance) / 5.0) * fuelRatio);
                        if (damage < 1)
                            damage = 1;
                        else if (damage > max)
                            damage = max;

                        new Action:res = Plugin_Continue;
                        Call_StartForward(fwdOnJetpackExplode);
                        Call_PushCell(victim);
                        Call_PushCell(index);
                        Call_PushCellRef(damage);
                        Call_Finish(res);

                        if (res != Plugin_Stop && damage > 0)
                        {
                            CreateFlameAttack(victim, index, damage, true);
                        }
                    }
                }
            }
        }
    }
}	

public OnGameFrame()
{
    new Float:gameTime = GetGameTime();
    if ((g_iNativeJetpacks > 0 || GetConVarBool(sm_jetpack)) && g_fTimer < gameTime - 0.075)
    {
        g_fTimer = gameTime;

        new bool:checkCond = (GameType == tf2 && g_fCheck < gameTime - 0.5);
        if (checkCond)
            g_fCheck = gameTime;

        for (new client = 1; client <= MaxClients; client++)
        {
            if (g_bJetpackOn[client])
            {
                new entityFlags = GetEntityFlags(client);
                if(!IsPlayerAlive(client))
                    StopJetpack(client);
                else if (g_iFuel[client] == 0)
                {
                    StopJetpack(client);
                    SendTopMessage(client, 1, 1, 255,0,0,128, "[] Your jetpack has run out of fuel");
                    PrintToChat(client,"%c[Jetpack] %cYour jetpack has run out of fuel",
                                COLOR_GREEN,COLOR_DEFAULT);

                    EmptyEffect(client);

                    if (g_EmptySound[0])
                    {
                        PrepareAndEmitSoundToClient(client, g_EmptySound);
                    }

                    new refuels = g_iMaxRefuels[client];
                    if (refuels < 0 || g_iRefuelCount[client] < refuels)
                        CreateTimer(g_fRefuelingTime[client],RefuelJetpack,client);
                }
                else if (GetEntityMoveType(client) == MOVETYPE_NONE)
                    StopJetpack(client);
                else if (checkCond && (TF2_IsPlayerSlowed(client)  || TF2_IsPlayerZoomed(client) ||
                                       TF2_IsPlayerTaunting(client)|| TF2_IsPlayerDazed(client) ||
                                       TF2_IsPlayerCloaked(client) || TF2_IsPlayerDeadRingered(client)))
                {
                    StopJetpack(client);
                }
                else if (g_bUseJetpack[client] && g_JumpPushedTime[client] > 0.0 &&
                         ((entityFlags & FL_ONGROUND) || (entityFlags & FL_INWATER) ||
                          (entityFlags & FL_SWIM) || !(GetClientButtons(client) & IN_JUMP)))
                {
                    StopJetpack(client);
                }
                else if ((entityFlags & FL_INWATER) || (entityFlags & FL_SWIM))
                {
                    StopJetpack(client);
                }
                else if (sm_jetpack_noflag && GetConVarBool(sm_jetpack_noflag) && TF2_HasTheFlag(client))
                    StopJetpack(client);
                else
                {
                    if (g_iFuel[client] > 0 && g_iFuel[client] < 25)
                    {
                        // Low on Fuel, Make it sputter.
                        StopJetpackSound(client);
                        DeleteLightEntity(g_JetpackLight[client]);
                        for (new j = 0; j < sizeof(g_JetpackParticle[]); j++)
                            DeleteParticle(g_JetpackParticle[client][j]);

                        if (g_iFuel[client] % 2)
                            SetMoveCollideType(client, MOVETYPE_WALK, MOVECOLLIDE_DEFAULT);
                        else
                        {
                            EmitJetpackSound(INVALID_HANDLE, client);

                            new MoveType:movetype = GetConVarInt(sm_jetpack_gravity) ? MOVETYPE_FLYGRAVITY : MOVETYPE_FLY;
                            SetMoveCollideType(client, movetype, MOVECOLLIDE_FLY_BOUNCE);

                            AddVelocity(client, GetConVarFloat(sm_jetpack_speed));
                            AddFireEffect(client);
                        }
                    }
                    else
                    {
                        AddVelocity(client, GetConVarFloat(sm_jetpack_speed));
                        AddFireEffect(client);
                    }

                    if (g_bBurn[client])
                        BurnEnemies(client);

                    if (g_iFuel[client] > 0)
                    {
                        g_iFuel[client] -= g_iRate[client];
                        if (g_iFuel[client] < 0)
                            g_iFuel[client] = 0;

                        /* Display the Fuel Gauge */
                        new String:gauge[30] = "[====+=====|=====+====]";
                        new Float:percent = float(g_iFuel[client]) / float(g_iRefuelAmount[client]);
                        new pos = RoundFloat(percent * 20.0)+1;
                        if (pos < 21)
                        {
                            gauge{pos} = ']';
                            gauge{pos+1} = 0;
                        }

                        new r,g,b;
                        if (percent <= 0.25 || g_iFuel[client] < 25)
                        {
                            r = 255;
                            g = 0;
                            b = 0;
                        }
                        else if (percent >= 0.50)
                        {
                            r = 0;
                            g = 255;
                            b = 0;
                        }
                        else
                        {
                            r = 255;
                            g = 255;
                            b = 0;
                        }
                        SendTopMessage(client, pos+2, 1, r,g,b,255, gauge);
                    }
                }
            }
            else if (g_bHasJetpack[client] && g_bUseJetpack[client] &&
                     IsClientInGame(client) && IsPlayerAlive(client))
            {
                new entityFlags = GetEntityFlags(client);
                if (!(entityFlags & FL_ONGROUND) && !(entityFlags & FL_INWATER) &&
                    !(entityFlags & FL_SWIM) && (GetClientButtons(client) & IN_JUMP))
                {
                    if (g_JumpPushedTime[client] <= 0.0)
                        g_JumpPushedTime[client] = gameTime;
                    else if (gameTime - g_JumpPushedTime[client] >= MIN_JUMP_TIME)
                        StartJetpack(client);
                }
                else
                    g_JumpPushedTime[client] = 0.0;
            }
        }
    }
}

public Action:RefuelJetpack(Handle:timer,any:client)
{
    if (client && g_bHasJetpack[client] && IsClientInGame(client) && IsPlayerAlive(client))
    {
        new refuels = g_iMaxRefuels[client];
        if (refuels < 0 || g_iRefuelCount[client] < refuels)
        {
            new tank_size = g_iRefuelAmount[client];
            if (g_iFuel[client] < tank_size)
            {
                g_iRefuelCount[client]++;
                g_iFuel[client] = tank_size;

                SendTopMessage(client, 30, 2, 0,255,0,128, "[====+=====|=====+====]");
                PrintToChat(client,"%c[Jetpack] %cYour jetpack has been refueled",
                            COLOR_GREEN,COLOR_DEFAULT);

                if (g_RefuelSound[0])
                {
                    PrepareAndEmitSoundToClient(client, g_RefuelSound);
                }
            }
        }
    }
    return Plugin_Handled;
}

public OnClientPutInServer(client)
{
    g_bHasJetpack[client] = false;

    if (g_bFromNative[client])
    {
        g_bFromNative[client] = false;
        g_iNativeJetpacks--;
    }

    if (!IsFakeClient(client) && AreClientCookiesCached(client))
    {
        decl String:buffer[5];
        GetClientCookie(client, hCookie, buffer, sizeof(buffer));
        g_bUseJetpack[client] = buffer[0] ? (bool:StringToInt(buffer)) : true;
    }
    else
        g_bUseJetpack[client] = true;
}

public OnClientDisconnect(client)
{
    StopJetpack(client);
    g_bHasJetpack[client] = false;
    if (g_bFromNative[client])
    {
        g_bFromNative[client] = false;
        g_iNativeJetpacks--;
    }
}

public Action:JetpackPressed(client, args)
{
    if (g_iNativeJetpacks > 0 || GetConVarBool(sm_jetpack))
        StartJetpack(client);

    return Plugin_Continue;
}

public Action:JetpackReleased(client, args)
{
    StopJetpack(client);
    return Plugin_Continue;
}

StartJetpack(client)
{
    if (g_bHasJetpack[client] && !g_bJetpackOn[client] && g_iFuel[client] != 0 &&
        IsPlayerAlive(client) && GetEntityMoveType(client) != MOVETYPE_NONE &&
        !(sm_jetpack_noflag && GetConVarBool(sm_jetpack_noflag) && TF2_HasTheFlag(client)))
    {
        #if defined _ztf2grab_included
            if (m_GravgunAvailable && HasObject(client))
                return;
        #endif

        new Action:res = Plugin_Continue;
        Call_StartForward(fwdOnJetpack);
        Call_PushCell(client);
        Call_Finish(res);
        if (res != Plugin_Stop)
        {
            g_bCrits[client] = TF2_IsPlayerCrit(client) ||
                               (GetConVarBool(tf_weapon_criticals) &&
                                GetRandomInt(1,100) < 5);

            new MoveType:movetype = GetConVarInt(sm_jetpack_gravity) ? MOVETYPE_FLYGRAVITY : MOVETYPE_FLY;
            SetMoveCollideType(client, movetype, MOVECOLLIDE_FLY_BOUNCE);

            g_bJetpackOn[client] = true;

            if (g_StartSound[0])
            {
                decl Float:vecPos[3];
                GetClientAbsOrigin(client, vecPos);
                EmitSoundToAll(g_StartSound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,
                               GetConVarFloat(sm_jetpack_volume), SNDPITCH_NORMAL, -1,
                               vecPos, NULL_VECTOR, true, 0.0);

                if (g_LoopSound[0])
                    CreateTimer(0.02, EmitJetpackSound, client);
            }
            else if (g_LoopSound[0])
                EmitJetpackSound(INVALID_HANDLE, client);

            if (GameType == tf2 && !IsEntLimitReached(.client=client,.message="unable to create flame particles"))
            {
                static const Float:pos[3] = {   0.0, 10.0, 1.0 };
                static const Float:ang[3] = { -25.0, 90.0, 0.0 };

                if (g_JetpackParticle[client][0] == INVALID_ENT_REFERENCE)
                {
                    g_JetpackParticle[client][0] = CreateParticle(EFFECT_BURNER_EMPTY, 0.15, client, Attach, "flag", pos, ang);
                }

                if (g_JetpackParticle[client][1] == INVALID_ENT_REFERENCE)
                {
                    //static const Float:ang1[3] = { -25.0, 75.0, 0.0 };

                    if (TFTeam:GetClientTeam(client) == TFTeam_Red)
                    {
                        if (g_bCrits[client])
                        {
                            g_JetpackParticle[client][1] = EntIndexToEntRef(CreateParticle(EFFECT_BURNER_RED_CRIT, 0.0,
                                                                                           client, Attach, "flag",
                                                                                           pos, ang));
                        }
                        else
                        {
                            g_JetpackParticle[client][1] = EntIndexToEntRef(CreateParticle(EFFECT_BURNER_RED, 0.0,
                                                                                           client, Attach, "flag",
                                                                                           pos, ang));
                        }
                    }
                    else
                    {
                        if (g_bCrits[client])
                        {
                            g_JetpackParticle[client][1] = EntIndexToEntRef(CreateParticle(EFFECT_BURNER_BLU_CRIT, 0.0,
                                                                                           client, Attach, "flag",
                                                                                           pos, ang));
                        }
                        else
                        {
                            g_JetpackParticle[client][1] = EntIndexToEntRef(CreateParticle(EFFECT_BURNER_BLU, 0.0,
                                                                                           client, Attach, "flag",
                                                                                           pos, ang));
                        }
                    }
                }

                if (g_JetpackParticle[client][2] == INVALID_ENT_REFERENCE)
                {
                    g_JetpackParticle[client][2] = EntIndexToEntRef(CreateParticle(EFFECT_TRAIL, 0.0,
                                                                                   client, Attach, "flag",
                                                                                   pos, ang));
                }

                if (g_JetpackLight[client] == INVALID_ENT_REFERENCE)
                {
                    g_JetpackLight[client] = EntIndexToEntRef(CreateLightEntity(client));
                }
            }
        }
    }
}

StopJetpack(client)
{
    StopJetpackSound(client);

    DeleteLightEntity(g_JetpackLight[client]);
    for (new j = 0; j < sizeof(g_JetpackParticle[]); j++)
        DeleteParticle(g_JetpackParticle[client][j]);

    g_JumpPushedTime[client] = 0.0;

    if (g_bJetpackOn[client])
    {
        g_bJetpackOn[client] = false;

        if (IsPlayerAlive(client))
        {
            if (GetEntityMoveType(client) != MOVETYPE_NONE)
                SetMoveCollideType(client, MOVETYPE_WALK, MOVECOLLIDE_DEFAULT);

            if (g_StopSound[0])
            {
                decl Float:vecPos[3];
                GetClientAbsOrigin(client, vecPos);
                EmitSoundToAll(g_StopSound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,
                               GetConVarFloat(sm_jetpack_volume), SNDPITCH_NORMAL, -1,
                               vecPos, NULL_VECTOR, true, 0.0);
            }
        }
    }
}

public Action:EmitJetpackSound(Handle:timer, any:client)
{
    if (g_bJetpackOn[client])
    {
        if (g_bCrits[client] && g_CritSound[0])
        {
            decl Float:vecPos[3];
            GetClientAbsOrigin(client, vecPos);
            EmitSoundToAll(g_CritSound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,
                           GetConVarFloat(sm_jetpack_volume), SNDPITCH_NORMAL, -1,
                           vecPos, NULL_VECTOR, true, 0.0);
        }
        else if (g_LoopSound[0])
        {
            decl Float:vecPos[3];
            GetClientAbsOrigin(client, vecPos);
            EmitSoundToAll(g_LoopSound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,
                           GetConVarFloat(sm_jetpack_volume), SNDPITCH_NORMAL, -1,
                           vecPos, NULL_VECTOR, true, 0.0);
        }
    }
}

StopJetpackSound(client)
{
    if (g_StartSound[0])
        StopSound(client, SNDCHAN_AUTO, g_StartSound);

    if (g_LoopSound[0])
        StopSound(client, SNDCHAN_AUTO, g_LoopSound);

    if (g_CritSound[0])
        StopSound(client, SNDCHAN_AUTO, g_CritSound);

    if (g_EmptySound[0])
        StopSound(client, SNDCHAN_AUTO, g_EmptySound);
}

SetMoveCollideType(client, MoveType:movetype, movecollide)
{
    SetEntityMoveType(client,movetype);
    if(g_iMoveCollide != -1)
        SetEntData(client, g_iMoveCollide, movecollide);
}

AddVelocity(client, Float:speed)
{
    if (g_iVelocity == -1) return;

    decl Float:vecVelocity[3];
    GetEntDataVector(client, g_iVelocity, vecVelocity);

    vecVelocity[2] += speed;

    //give the player a little push if they're on the ground
    //(fixes stuck issue from pyro/medic updates)
    if (GetEntityFlags(client) & FL_ONGROUND)
    {
        decl Float:vecOrigin[3];
        GetClientAbsOrigin(client, vecOrigin);
        vecOrigin[2] += 1.0; //gets player off the ground if they're not in the air
        TeleportEntity(client, vecOrigin, NULL_VECTOR, vecVelocity);
    }
    else
        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

// Updated by Grrrrrrrrrrrrrrrrrrr
AddFireEffect(client)
{
    if (GameType != tf2 && GameType != l4d && GameType != l4d2)
    {
        decl Float:vecPos[3],Float:vecDir[3];
        GetClientAbsOrigin(client, vecPos);
        GetClientEyePosition(client,vecDir);

        vecDir[0] = 80.0;
        if(vecDir[1]==0.0)
            vecDir[1] = 179.8;
        else if(vecDir[1]==90.0||vecDir[1]==-90.0)
            vecDir[1] = (vecDir[1]*-1.0);
        else if(vecDir[1]>90.0)
            vecDir[1] = ((vecDir[1]-90.0)*-1.0);
        else if(vecDir[1]<-90.0)
            vecDir[1] = ((vecDir[1]+90.0)*-1.0);
        else if(vecDir[1]<90.0&&vecDir[1]>0.0)
            vecDir[1] = ((vecDir[1]+90.0)*-1.0);
        else if(vecDir[1]<0.0&&vecDir[1]>-90.0)
            vecDir[1] = ((vecDir[1]-90.0)*-1.0);

        TE_SetupEnergySplash(vecPos, vecDir, false);
        TE_SendToAll();
    }
}

BurnEnemies(client)
{
    decl Float:clientPos[3];
    GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", clientPos);

    decl Float:clientAng[3];
    GetEntPropVector(client, Prop_Data, "m_angRotation", clientAng);

    new bool:ff = GetConVarBool(mp_friendlyfire);
    for (new victim = 1; victim <= MaxClients; victim++)
    {
        if (victim!=client && IsClientInGame(victim) && IsPlayerAlive(victim) &&
            (ff || GetClientTeam(victim) != GetClientTeam(client)))
        {
            decl Float:victimPos[3];
            GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", victimPos);

            decl Float:victimAng[3];
            SubtractVectors(clientPos, victimPos, victimAng);
            GetVectorAngles(victimAng, victimAng);	

            new Float:diffYaw = FloatAbs((victimAng[1] - 180.0) - clientAng[1]);
            if (diffYaw >= 135.0 && diffYaw < 225.0)
            {
                new fuel = g_iFuel[client];
                new Float:fuelRatio = float(fuel) / 100.0;
                if (fuelRatio > 1.0)
                    fuelRatio = 1.0;

                new Float:distance;
                new Float:range = g_BurnRange[client] * fuelRatio;
                if (CanTarget(client, clientPos, victim, victimPos, range, distance))
                {
                    #if defined SOURCECRAFT
                        if (m_SourceCraftAvailable && GetImmunity(victim, Immunity_Burning))
                            continue;
                    #endif

                    new max = g_BurnDamage[client];
                    new damage = RoundFloat(((range - distance) / 5.0) * fuelRatio);
                    if (damage < 1)
                        damage = 1;
                    else if (damage > max)
                        damage = max;

                    new Action:res = Plugin_Continue;
                    Call_StartForward(fwdOnJetpackBurn);
                    Call_PushCell(victim);
                    Call_PushCell(client);
                    Call_PushCellRef(damage);
                    Call_Finish(res);

                    if (res != Plugin_Stop && damage > 0)
                    {
                        g_bCrits[client] = TF2_IsPlayerCrit(client) ||
                                           (GetConVarBool(tf_weapon_criticals) &&
                                            GetRandomInt(1,100) < 5);

                        CreateFlameAttack(victim, client, damage, false, g_bCrits[client]);
                    }
                }
            }
        }
    }
}

stock bool:CanTarget(origin, const Float:pos[3], target, const Float:targetPos[3],
                     Float:range, &Float:distance=0.0, bool:throughPlayer=true,
                     bool:throughBuild=false )
{
    distance = GetVectorDistance(pos, targetPos);
    if (distance >= range)
        return false;

    g_FilteredEntity = origin;
    new Handle:hTrace = TR_TraceRayFilterEx(pos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
    if (!TR_DidHit(hTrace))
    {
        CloseHandle(hTrace);
        return true;
    }
    else
    {
        new hitEnt = TR_GetEntityIndex(hTrace);
        if (hitEnt == target)
        {
            CloseHandle(hTrace);
            return true;
        }
        else if (!throughPlayer && !throughBuild)
        {
            CloseHandle(hTrace);
            return false;
        }
        else
        {
            decl Float:hitPos[3];
            TR_GetEndPosition(hitPos, hTrace);
            CloseHandle(hTrace);

            if (GetVectorDistance(hitPos, targetPos) <= 50.0)
            {
                decl String:edictName[64];
                GetEdictClassname( hitEnt, edictName, sizeof( edictName ) );

                if ((throughPlayer && StrEqual(edictName, "player")) ||
                    (throughBuild && (StrEqual(edictName, "obj_dispenser") ||
                                      StrEqual(edictName, "obj_sentrygun") ||
                                      StrEqual(edictName, "obj_teleporter_entrance") ||
                                      StrEqual(edictName, "obj_teleporter_exit") ||
                                      StrEqual(edictName, "obj_attachment_sapper"))))
                {
                    decl Float:entPos[3];
                    GetEntPropVector(hitEnt, Prop_Data, "m_vecAbsOrigin", entPos);

                    if (GetVectorDistance(entPos, targetPos) > 50.0)
                    {
                        g_FilteredEntity = hitEnt;
                        hTrace = TR_TraceRayFilterEx(hitPos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
                        TR_GetEndPosition(hitPos, hTrace);
                        CloseHandle(hTrace);
                    }

                    return (GetVectorDistance(hitPos, targetPos) <= 50.0);
                }
                else
                    return false;
            }
        }
    }
    return false;
}

public bool:TraceFilter(ent, contentMask)
{
	return (ent == g_FilteredEntity) ? false : true;
}

bool:CreateFlameAttack(any:victim, any:attacker, damage, bool:bExplosion=false,
                       bool:bCrits=false, bool:bMiniCrits=false)
{
    if (!(GetEntityFlags(victim) & FL_INWATER) && !TF2_IsPlayerUbercharged(victim))
    {
        if (bCrits)
            damage *= GetRandomFloat(2.1,3.1);
        else if (bMiniCrits)
            damage *= GetRandomFloat(1.1,2.1);

        TF2_IgnitePlayer(victim, attacker);

        #if defined SOURCECRAFT
        if (m_SourceCraftAvailable)
        {
            new dmg_type = DMG_BURN;
            new DamageFrom:category = DamageFrom_Burning;
            if (bExplosion)
            {
                dmg_type |= DMG_BLAST;
                category |= DamageFrom_Explosion;
            }

            HurtPlayer(victim, damage, attacker, "jetpack", .explode=bExplosion,
                       .type=dmg_type, .category=category);
        }
        else
        #endif
        {
            new dmg_type = DMG_BURN;
            if (bExplosion)
                dmg_type |= DMG_BLAST;

            DamagePlayer(victim, damage, attacker, dmg_type, "jetpack");
        }
    }
    return false;
}

EmptyEffect(client)
{
	if (GameType == tf2 && !IsEntLimitReached(.client=client,.message="unable to create empty particle"))
	{
		static const Float:ang[3] = { -25.0, 90.0, 0.0 };
		static const Float:pos[3] = {   0.0, 10.0, 1.0 };
		CreateParticle(EFFECT_BURNER_EMPTY, 0.15, client, Attach, "flag", pos, ang);
		CreateParticle(EFFECT_BURNER_WARP2, 0.15, client, Attach, "flag", pos, ang);
		CreateParticle(EFFECT_BURNER_WARP, 0.15, client, Attach, "flag", pos, ang);
	}
	else
	{
		decl Float:vecPos[3],Float:vecDir[3];
		GetClientAbsOrigin(client, vecPos);
		GetClientEyePosition(client,vecDir);

		vecDir[0] = 80.0;
		if(vecDir[1]==0.0)
			vecDir[1] = 179.8;
		else if(vecDir[1]==90.0||vecDir[1]==-90.0)
			vecDir[1] = (vecDir[1]*-1.0);
		else if(vecDir[1]>90.0)
			vecDir[1] = ((vecDir[1]-90.0)*-1.0);
		else if(vecDir[1]<-90.0)
			vecDir[1] = ((vecDir[1]+90.0)*-1.0);
		else if(vecDir[1]<90.0&&vecDir[1]>0.0)
			vecDir[1] = ((vecDir[1]+90.0)*-1.0);
		else if(vecDir[1]<0.0&&vecDir[1]>-90.0)
			vecDir[1] = ((vecDir[1]-90.0)*-1.0);

		TE_SetupDust(vecPos,vecDir,15.0,100.0);
		TE_SendToAll();
	}
}

CreateLightEntity(client)
{
    new entity = CreateEntityByName("light_dynamic");
    if (IsValidEntity(entity))
    {
        DispatchKeyValue(entity, "inner_cone", "0");
        DispatchKeyValue(entity, "cone", "80");
        DispatchKeyValue(entity, "brightness", "6");
        DispatchKeyValueFloat(entity, "spotlight_radius", 240.0);
        DispatchKeyValueFloat(entity, "distance", 250.0);
        DispatchKeyValue(entity, "_light", "255 100 10 41");
        DispatchKeyValue(entity, "pitch", "-90");
        DispatchKeyValue(entity, "style", "5");
        DispatchSpawn(entity);

        decl Float:fAngle[3];
        GetClientEyeAngles(client, fAngle);

        decl Float:fAngle2[3];
        fAngle2[0] = 0.0;
        fAngle2[1] = fAngle[1];
        fAngle2[2] = 0.0;

        decl Float:fForward[3];
        GetAngleVectors(fAngle2, fForward, NULL_VECTOR, NULL_VECTOR);
        ScaleVector(fForward, -50.0);
        fForward[2] = 0.0;

        decl Float:fPos[3];
        GetClientEyePosition(client, fPos);

        decl Float:fOrigin[3];
        AddVectors(fPos, fForward, fOrigin);

        fAngle[0] += 90.0;
        fOrigin[2] -= 120.0;
        TeleportEntity(entity, fOrigin, fAngle, NULL_VECTOR);

        decl String:strName[32];
        Format(strName, sizeof(strName), "target%i", client);
        DispatchKeyValue(client, "targetname", strName);

        DispatchKeyValue(entity, "parentname", strName);
        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", client, entity, 0);
        SetVariantString("head");
        AcceptEntityInput(entity, "SetParentAttachmentMaintainOffset", client, entity, 0);
        AcceptEntityInput(entity, "TurnOn");
    }
    return entity;
}

DeleteLightEntity(&entityRef)
{
    if (entityRef != INVALID_ENT_REFERENCE)
    {
        new entity = EntRefToEntIndex(entityRef);
        if (entity > 0 && IsValidEntity(entity))
        {
            AcceptEntityInput(entity, "kill");
        }
        entityRef = INVALID_ENT_REFERENCE;
    }
}

public Native_StartJetpack(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MAXPLAYERS+1)
        StartJetpack(client);
}

public Native_StopJetpack(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MAXPLAYERS+1)
        StopJetpack(client);
}

public Native_GiveJetpack(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MAXPLAYERS+1)
    {
        g_iNativeJetpacks++;
        g_bHasJetpack[client] = true;
        g_bFromNative[client] = true;
        g_iRefuelCount[client] = 0;

        g_iFuel[client] = g_iRefuelAmount[client] = GetNativeCell(2);
        g_fRefuelingTime[client] = GetNativeCell(3);
        g_iMaxRefuels[client] = GetNativeCell(4);
        g_iNativeRate[client] = GetNativeCell(5);
        g_bBurn[client] = bool:GetNativeCell(6);
        g_bExplode[client] = bool:GetNativeCell(7);

        g_BurnRange[client] = GetConVarFloat(sm_jetpack_burn_range);
        g_BurnDamage[client] = GetConVarInt(sm_jetpack_burn_damage);

        g_iExplodeFuel[client] = GetConVarInt(sm_jetpack_explode_fuel);
        g_ExplodeRange[client] = GetConVarFloat(sm_jetpack_explode_range);
        g_iExplodeDamage[client] = GetConVarInt(sm_jetpack_explode_damage);

        if (g_iNativeRate[client] < 0)
        {
            new class = 0;
            switch (GameType)
            {
                case tf2: class = _:TF2_GetPlayerClass(client);
                case dod: class = _:DOD_GetPlayerClass(client); 
            }
            new Handle:rate_cvar = sm_jetpack_rate[class];
            g_iRate[client] = rate_cvar ? GetConVarInt(rate_cvar) : 1;
        }
        else
            g_iRate[client] = g_iNativeRate[client];

        return g_iFuel[client];
    }
    return -1;
}

public Native_TakeJetpack(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MAXPLAYERS+1)
    {
        StopJetpack(client);
        g_bHasJetpack[client] = false;
        if (g_bFromNative[client])
        {
            g_bFromNative[client] = false;
            g_iNativeJetpacks--;
        }
    }
}

public Native_GiveJetpackFuel(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MAXPLAYERS+1)
    {
        new amount = GetNativeCell(2);
        if (amount >= 0)
            g_iFuel[client] += amount;
        else
            g_iFuel[client] = amount;

        new refuels = GetNativeCell(3);
        if (refuels >= 0)
            g_iMaxRefuels[client] += refuels;
        else
            g_iMaxRefuels[client] = refuels;

        return g_iFuel[client];
    }
    return -1;
}

public Native_TakeJetpackFuel(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MAXPLAYERS+1)
    {
        new amount = GetNativeCell(2);
        if (amount >= 0)
        {
            g_iFuel[client] -= amount;
            if (g_iFuel[client] < 0)
                g_iFuel[client] = 0;
        }
        else
            g_iFuel[client] = 0;

        new refuels = GetNativeCell(3);
        if (refuels >= 0)
        {
            g_iMaxRefuels[client] -= refuels;
            if (g_iMaxRefuels[client] < 0)
                g_iMaxRefuels[client] = 0;
        }
        else
            g_iMaxRefuels[client] = 0;

        return g_iFuel[client];
    }
    return -1;
}

public Native_SetJetpackFuel(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MAXPLAYERS+1)
    {
        g_iFuel[client] = g_iRefuelAmount[client] = GetNativeCell(2);
        g_iMaxRefuels[client] = GetNativeCell(3);
    }
    else
    {
        SetConVarInt(sm_jetpack_fuel, GetNativeCell(2));
        SetConVarInt(sm_jetpack_max_refuels, GetNativeCell(3));
    }
}

public Native_SetJetpackRate(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MAXPLAYERS+1)
    {
        g_iNativeRate[client] = GetNativeCell(2);
        if (g_iNativeRate[client] < 0)
        {
            new class = 0;
            switch (GameType)
            {
                case tf2: class = _:TF2_GetPlayerClass(client);
                case dod: class = _:DOD_GetPlayerClass(client); 
            }
            new Handle:rate_cvar = sm_jetpack_rate[class];
            g_iRate[client] = rate_cvar ? GetConVarInt(rate_cvar) : 1;
        }
        else
            g_iRate[client] = g_iNativeRate[client];
    }
}

public Native_SetJetpackRefuelingTime(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (client > 0 && client <= MAXPLAYERS+1)
        g_fRefuelingTime[client] =  Float:GetNativeCell(2);
    else
        SetConVarFloat(sm_jetpack_refueling_time, Float:GetNativeCell(2));
}

public Native_GetJetpackFuel(Handle:plugin,numParams)
{
    return g_iFuel[GetNativeCell(1)];
}

public Native_GetJetpackRate(Handle:plugin,numParams)
{
    return g_iRate[GetNativeCell(1)];
}

public Native_GetJetpackRefuelingTime(Handle:plugin,numParams)
{
    return _:(g_fRefuelingTime[GetNativeCell(1)]);
}

public Native_HasJetpack(Handle:plugin,numParams)
{
    return g_bHasJetpack[GetNativeCell(1)];
}

public Native_IsJetpackOn(Handle:plugin,numParams)
{
    return g_bJetpackOn[GetNativeCell(1)];
}

public Native_ControlJetpack(Handle:plugin,numParams)
{
    g_bNativeOverride = GetNativeCell(1);
}

public Action:Command_GiveJetpack(client,argc)
{
    if (argc>=1)
    {
        decl String:target[64];
        GetCmdArg(1,target,64);
        new count = SetJetpack(client,target,true);
        if (!count)
            ReplyToTargetError(client, count);
    }
    else
    {
        ReplyToCommand(client,"%c[Jetpack] Usage: %csm_jetpack_give <@userid/partial name>",
                       COLOR_GREEN,COLOR_DEFAULT);
    }
    return Plugin_Handled;
}

public Action:Command_TakeJetpack(client,argc)
{
    if (argc>=1)
    {
        decl String:target[64];
        GetCmdArg(1,target,64);

        new count=SetJetpack(client,target,false);
        if (!count)
            ReplyToTargetError(client, count);
    }
    else
    {
        ReplyToCommand(client,"%c[Jetpack] Usage: %csm_jetpack_take <@userid/partial name>",
                       COLOR_GREEN,COLOR_DEFAULT);
    }
    return Plugin_Handled;
}

public SetJetpack(client,const String:target[],bool:enable)
{
    decl bool:isml, String:name[64], clients[MAXPLAYERS+1];
    new count=ProcessTargetString(target,client,clients,MAXPLAYERS+1,COMMAND_FILTER_NO_BOTS,
                                  name,sizeof(name),isml);
    if (count)
    {
        for(new x=0;x<count;x++)
        {
            new index = clients[x];
            switch (PerformJetpack(client, index, enable))
            {
                case 0:
                {
                    if (enable)
                        ReplyToCommand(client, "Gave a jetpack to %N", index);
                    else
                        ReplyToCommand(client, "Removed the jetpack from %N", index);
                }
                case 1: ReplyToCommand(client,"%N already has a jetpack", index);
                case 2: ReplyToCommand(client,"Unable to remove the jetpack");
            }
        }
    }
    return count;
}

public PerformJetpack(client, target, bool:enable)
{
    if (enable)
    {
        if (!g_bHasJetpack[target])
        {
            new class = 0;
            switch (GameType)
            {
                case tf2: class = _:TF2_GetPlayerClass(client);
                case dod: class = _:DOD_GetPlayerClass(client); 
            }

            new Handle:rate_cvar = sm_jetpack_rate[class];
            g_iRate[target] = rate_cvar ? GetConVarInt(rate_cvar) : 1;
            g_iFuel[target] = g_iRefuelAmount[target] = GetConVarInt(sm_jetpack_fuel);
            g_fRefuelingTime[target] = GetConVarFloat(sm_jetpack_refueling_time);
            g_iMaxRefuels[target] = GetConVarInt(sm_jetpack_max_refuels);
            g_bHasJetpack[target] = true;
            g_iRefuelCount[target] = 0;
            g_JumpPushedTime[target] = 0.0;

            if(GetConVarBool(sm_jetpack_announce))
            {
                PrintToChat(target,"%c[Jetpack] %cIs enabled, valid commands are: [JUMP] [%c+jetpack%c] [%c-jetpack%c]",
                            COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
            }
            LogAction(client, target, "\"%L\" gave a jetpack to \"%L\"", client, target);
            return 0;
        }
        else
            return 1;
    }
    else
    {
        if (!g_bFromNative[target])
        {
            StopJetpack(target);
            g_bHasJetpack[target] = false;
            LogAction(client, target, "\"%L\" took the jetpack from \"%L\"", client, target);
            return 0;
        }
        else
            return 2;
    }
}

public OnAdminMenuReady(Handle:topmenu)
{
    /* Block us from being called twice */
    if (topmenu != hAdminMenu)
    {
        /* Save the Handle */
        hAdminMenu = topmenu;

        if (!g_bNativeOverride)
        {
            new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
            oGiveJetpack = AddToTopMenu(hAdminMenu, "sm_give_jetpack", TopMenuObject_Item, AdminMenu,
                                        server_commands, "sm_give_jetpack", ADMFLAG_JETPACK);
            oTakeJetpack = AddToTopMenu(hAdminMenu, "sm_take_jetpack", TopMenuObject_Item, AdminMenu,
                                        server_commands, "sm_take_jetpack", ADMFLAG_JETPACK);
        }
    }
}

public AdminMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    if (action == TopMenuAction_DisplayOption)
    {
        if (object_id == oGiveJetpack)
            Format(buffer, maxlength, "Give Jetpack");
        else if (object_id == oTakeJetpack)
            Format(buffer, maxlength, "Take Jetpack");
    }
    else if (action == TopMenuAction_SelectOption)
    {
        JetpackMenu(param, object_id);
    }
}

JetpackMenu(client, TopMenuObject:object_id)
{
    new Handle:menu = CreateMenu(MenuHandler_Jetpack);

    SetMenuTitle(menu, (object_id == oGiveJetpack)
                       ? "Give a Jetpack to"
                       : "Take the Jetpack from");

    SetMenuExitBackButton(menu, true);

    AddTargetsToMenu(menu, client, true, true);

    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Jetpack(Handle:menu, MenuAction:action, param1, param2)
{
    decl String:title[32];
    GetMenuTitle(menu,title,sizeof(title));

    if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
        {
            DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
        }
    }
    else if (action == MenuAction_Select)
    {
        decl String:info[32];
        new userid, target;

        GetMenuItem(menu, param2, info, sizeof(info));
        userid = StringToInt(info);

        if ((target = GetClientOfUserId(userid)) == 0)
        {
            PrintToChat(param1, "[SM] Player no longer available");
        }
        else if (!CanUserTarget(param1, target))
        {
            PrintToChat(param1, "[SM] Unable to target");
        }
        else
        {
            new String:name[32];
            GetClientName(target, name, sizeof(name));

            if (StrContains(title, "Give") != -1)
            {
                PerformJetpack(param1, target, true);
                ShowActivity2(param1, "[SM] ", "Gave %s a jetpack", name);
            }
            else
            {
                PerformJetpack(param1, target, false);
                ShowActivity2(param1, "[SM] ", "Took the jetpack from %s", name);
            }
        }

        /* Re-draw the menu if they're still valid */
        if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
        {
            if (StrContains(title, "Give") != -1)
            {
                JetpackMenu(param1, oGiveJetpack);
            }
            else
            {
                JetpackMenu(param1, oTakeJetpack);
            }
        }
    }
}

public PrefsMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
    if (action == CookieMenuAction_SelectOption)
    {
        new Handle:menu = CreateMenu(MenuHandler_Prefs);
        SetMenuTitle(menu, "Jetpack Preferences");
        AddMenuItem(menu, "1", "+JUMP activates Jetpack");
        AddMenuItem(menu, "0", "+JUMP does NOT activate Jetpack");
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, 20);
    }
}

public MenuHandler_Prefs(Handle:menu, MenuAction:action, client, selection)
{
    if (action == MenuAction_Select)	
    {
        decl String:SelectionInfo[5];
        GetMenuItem(menu, selection, SelectionInfo, sizeof(SelectionInfo));
        SetClientCookie(client, hCookie, SelectionInfo);
        g_bUseJetpack[client] = bool:StringToInt(SelectionInfo);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
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
