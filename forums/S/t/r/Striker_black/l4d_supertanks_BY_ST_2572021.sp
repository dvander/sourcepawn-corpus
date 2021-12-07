#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION		"7.0"
#define PARTICLE_SPAWN		"smoker_smokecloud"
#define PARTICLE_FIRE			"aircraft_destroy_fastFireTrail"
#define PARTICLE_WARP			"electrical_arc_01_system"
#define PARTICLE_ICE			"steam_manhole"
#define PARTICLE_SPIT			"spitter_areaofdenial_glow2"
#define PARTICLE_SPITPROJ		"spitter_projectile"
#define PARTICLE_ELEC			"electrical_arc_01_parent"
#define PARTICLE_BLOOD		"boomer_explode_D"
#define PARTICLE_EXPLODE		"boomer_explode"
#define PARTICLE_METEOR		"smoke_medium_01"


new TankAlive[66];
new TankAbility[66];
new Rock[66];
new ShieldsUp[66];
new PlayerSpeed[66];
new iTankWave;
new iNumTanks;
new iFrame;
new iTick;
new Handle:hSuperTanksEnabled;
new Handle:hDisplayHealthCvar;
new Handle:hWave1Cvar;
new Handle:hWave2Cvar;
new Handle:hWave3Cvar;
new Handle:hFinaleOnly;
new Handle:hDefaultTanks;
new Handle:henable_announce;
new Handle:hGamemodeCvar;
new Handle:hDefaultOverride;
new Handle:hDefaultExtraHealth;
new Handle:hDefaultSpeed;
new Handle:hDefaultThrow;
new Handle:hDefaultFireImmunity;
new Handle:hSpawnEnabled;
new Handle:hSpawnExtraHealth;
new Handle:hSpawnSpeed;
new Handle:hSpawnThrow;
new Handle:hSpawnFireImmunity;
new Handle:hSpawnCommonAmount;
new Handle:hSpawnCommonInterval;
new Handle:hSmasherEnabled;
new Handle:hSmasherExtraHealth;
new Handle:hSmasherSpeed;
new Handle:hSmasherThrow;
new Handle:hSmasherFireImmunity;
new Handle:hSmasherMaimDamage;
new Handle:hSmasherCrushDamage;
new Handle:hSmasherRemoveBody;
new Handle:hTrapEnabled;
new Handle:hTrapExtraHealth;
new Handle:hTrapSpeed;
new Handle:hTrapThrow;
new Handle:hTrapFireImmunity;
new Handle:hTrapMaimDamage;
new Handle:hTrapCrushDamage;
new Handle:hTrapRemoveBody;
new Handle:hWarpEnabled;
new Handle:hWarpExtraHealth;
new Handle:hWarpSpeed;
new Handle:hWarpThrow;
new Handle:hWarpFireImmunity;
new Handle:hWarpTeleportDelay;
new Handle:hFeedbackEnabled;
new Handle:hFeedbackExtraHealth;
new Handle:hFeedbackSpeed;
new Handle:hFeedbackThrow;
new Handle:hFeedbackFireImmunity;
new Handle:hFeedbackTeleportDelay;
new Handle:hFeedbackPushForce;
new Handle:hFeedbackStunDamage;
new Handle:hFeedbackStunMovement;
new Handle:hMeteorEnabled;
new Handle:hMeteorExtraHealth;
new Handle:hMeteorSpeed;
new Handle:hMeteorThrow;
new Handle:hMeteorFireImmunity;
new Handle:hMeteorStormDelay;
new Handle:hMeteorStormDamage;
new Handle:hAcidEnabled;
new Handle:hAcidExtraHealth;
new Handle:hAcidSpeed;
new Handle:hAcidThrow;
new Handle:hAcidFireImmunity;
new Handle:hHealthEnabled;
new Handle:hHealthExtraHealth;
new Handle:hHealthSpeed;
new Handle:hHealthThrow;
new Handle:hHealthFireImmunity;
new Handle:hHealthHealthCommons;
new Handle:hHealthHealthSpecials;
new Handle:hHealthHealthTanks;
new Handle:hFireEnabled;
new Handle:hFireExtraHealth;
new Handle:hFireSpeed;
new Handle:hFireThrow;
new Handle:hFireFireImmunity;
new Handle:hIceEnabled;
new Handle:hIceExtraHealth;
new Handle:hIceSpeed;
new Handle:hIceThrow;
new Handle:hIceFireImmunity;
new Handle:hJockeyEnabled;
new Handle:hJockeyExtraHealth;
new Handle:hJockeySpeed;
new Handle:hJockeyThrow;
new Handle:hJockeyFireImmunity;
new Handle:hHunterEnabled;
new Handle:hHunterExtraHealth;
new Handle:hHunterSpeed;
new Handle:hHunterThrow;
new Handle:hHunterFireImmunity;
new Handle:hSmokerEnabled;
new Handle:hSmokerExtraHealth;
new Handle:hSmokerSpeed;
new Handle:hSmokerThrow;
new Handle:hSmokerFireImmunity;
new Handle:hBoomerEnabled;
new Handle:hBoomerExtraHealth;
new Handle:hBoomerSpeed;
new Handle:hBoomerThrow;
new Handle:hBoomerFireImmunity;
new Handle:hChargerEnabled;
new Handle:hChargerExtraHealth;
new Handle:hChargerSpeed;
new Handle:hChargerThrow;
new Handle:hChargerFireImmunity;
new Handle:hGhostEnabled;
new Handle:hGhostExtraHealth;
new Handle:hGhostSpeed;
new Handle:hGhostThrow;
new Handle:hGhostFireImmunity;
new Handle:hGhostDisarm;
new Handle:hShockEnabled;
new Handle:hShockExtraHealth;
new Handle:hShockSpeed;
new Handle:hShockThrow;
new Handle:hShockFireImmunity;
new Handle:hShockStunDamage;
new Handle:hShockStunMovement;
new Handle:hWitchEnabled;
new Handle:hWitchExtraHealth;
new Handle:hWitchSpeed;
new Handle:hWitchThrow;
new Handle:hWitchFireImmunity;
new Handle:hWitchMaxWitches;
new Handle:hShieldEnabled;
new Handle:hShieldExtraHealth;
new Handle:hShieldSpeed;
new Handle:hShieldThrow;
new Handle:hShieldFireImmunity;
new Handle:hShieldShieldsDownInterval;
new Handle:hCobaltEnabled;
new Handle:hCobaltExtraHealth;
new Handle:hCobaltSpeed;
new Handle:hCobaltThrow;
new Handle:hCobaltFireImmunity;
new Handle:hCobaltSpecialSpeed;
new Handle:hJumperEnabled;
new Handle:hJumperExtraHealth;
new Handle:hJumperSpeed;
new Handle:hJumperThrow;
new Handle:hJumperFireImmunity;
new Handle:hJumperJumpDelay;
new Handle:hDistractionEnabled;
new Handle:hDistractionExtraHealth;
new Handle:hDistractionSpeed;
new Handle:hDistractionThrow;
new Handle:hDistractionFireImmunity;
new Handle:hDistractionJumpDelay;
new Handle:hDistractionTeleportDelay;
new Handle:hGravityEnabled;
new Handle:hGravityExtraHealth;
new Handle:hGravitySpeed;
new Handle:hGravityThrow;
new Handle:hGravityFireImmunity;
new Handle:hGravityPullForce;
new Handle:hFlashEnabled;
new Handle:hFlashExtraHealth;
new Handle:hFlashSpeed;
new Handle:hFlashThrow;
new Handle:hFlashFireImmunity;
new Handle:hFlashSpecialSpeed;
new Handle:hFlashTeleportDelay;
new Handle:hReverseFlashEnabled;
new Handle:hReverseFlashExtraHealth;
new Handle:hReverseFlashSpeed;
new Handle:hReverseFlashThrow;
new Handle:hReverseFlashFireImmunity;
new Handle:hReverseFlashSpecialSpeed;
new Handle:hReverseFlashTeleportDelay;
new Handle:hArmageddonEnabled;
new Handle:hArmageddonExtraHealth;
new Handle:hArmageddonSpeed;
new Handle:hArmageddonThrow;
new Handle:hArmageddonFireImmunity;
new Handle:hArmageddonStormDelay;
new Handle:hArmageddonStormDamage;
new Handle:hArmageddonMaimDamage;
new Handle:hArmageddonCrushDamage;
new Handle:hArmageddonRemoveBody;
new Handle:hArmageddonPullForce;
new Handle:hHallucinationEnabled;
new Handle:hHallucinationExtraHealth;
new Handle:hHallucinationSpeed;
new Handle:hHallucinationThrow;
new Handle:hHallucinationFireImmunity;
new Handle:hHallucinationDisarm;
new Handle:hHallucinationTeleportDelay;
new Handle:hMinionEnabled;
new Handle:hMinionExtraHealth;
new Handle:hMinionSpeed;
new Handle:hMinionThrow;
new Handle:hMinionFireImmunity;
new Handle:hBitchEnabled;
new Handle:hBitchExtraHealth;
new Handle:hBitchSpeed;
new Handle:hBitchThrow;
new Handle:hBitchFireImmunity;
new Handle:hPsychoticEnabled;
new Handle:hPsychoticExtraHealth;
new Handle:hPsychoticSpeed;
new Handle:hPsychoticThrow;
new Handle:hPsychoticFireImmunity;
new Handle:hPsychoticTeleportDelay;
new Handle:hPsychoticHealthCommons;
new Handle:hPsychoticHealthSpecials;
new Handle:hPsychoticHealthTanks;
new Handle:hPsychoticStormDelay;
new Handle:hPsychoticStormDamage;
new Handle:hPsychoticJumpDelay;
new Handle:hSpitterEnabled;
new Handle:hSpitterExtraHealth;
new Handle:hSpitterSpeed;
new Handle:hSpitterThrow;
new Handle:hSpitterFireImmunity;
new Handle:hGoliathEnabled;
new Handle:hGoliathExtraHealth;
new Handle:hGoliathSpeed;
new Handle:hGoliathThrow;
new Handle:hGoliathFireImmunity;
new Handle:hGoliathMaimDamage;
new Handle:hGoliathCrushDamage;
new Handle:hGoliathRemoveBody;
new Handle:hGoliathHealthCommons;
new Handle:hGoliathHealthSpecials;
new Handle:hGoliathHealthTanks;
new Handle:hPsykotikEnabled;
new Handle:hPsykotikExtraHealth;
new Handle:hPsykotikSpeed;
new Handle:hPsykotikThrow;
new Handle:hPsykotikFireImmunity;
new Handle:hPsykotikSpecialSpeed;
new Handle:hPsykotikTeleportDelay;
new Handle:hPsykotikHealthCommons;
new Handle:hPsykotikHealthSpecials;
new Handle:hPsykotikHealthTanks;
new Handle:hSpykotikEnabled;
new Handle:hSpykotikExtraHealth;
new Handle:hSpykotikSpeed;
new Handle:hSpykotikThrow;
new Handle:hSpykotikFireImmunity;
new Handle:hSpykotikSpecialSpeed;
new Handle:hSpykotikTeleportDelay;
new Handle:hMemeEnabled;
new Handle:hMemeExtraHealth;
new Handle:hMemeSpeed;
new Handle:hMemeThrow;
new Handle:hMemeFireImmunity;
new Handle:hMemeCommonAmount;
new Handle:hMemeCommonInterval;
new Handle:hMemeMaimDamage;
new Handle:hMemeCrushDamage;
new Handle:hMemeRemoveBody;
new Handle:hMemeTeleportDelay;
new Handle:hMemeStormDelay;
new Handle:hMemeStormDamage;
new Handle:hMemeDisarm;
new Handle:hMemeMaxWitches;
new Handle:hMemeSpecialSpeed;
new Handle:hMemeJumpDelay;
new Handle:hMemePullForce;
new Handle:hBossEnabled;
new Handle:hBossExtraHealth;
new Handle:hBossSpeed;
new Handle:hBossThrow;
new Handle:hBossFireImmunity;
new Handle:hBossMaimDamage;
new Handle:hBossCrushDamage;
new Handle:hBossRemoveBody;
new Handle:hBossTeleportDelay;
new Handle:hBossStormDelay;
new Handle:hBossStormDamage;
new Handle:hBossHealthCommons;
new Handle:hBossHealthSpecials;
new Handle:hBossHealthTanks;
new Handle:hBossDisarm;
new Handle:hBossMaxWitches;
new Handle:hBossSpecialSpeed;
new Handle:hBossJumpDelay;
new Handle:hBossPullForce;
new Handle:hSpypsyEnabled;
new Handle:hSpypsyExtraHealth;
new Handle:hSpypsySpeed;
new Handle:hSpypsyThrow;
new Handle:hSpypsyFireImmunity;
new Handle:hSpypsySpecialSpeed;
new Handle:hSpypsyTeleportDelay;
new Handle:hSipowEnabled;
new Handle:hSipowExtraHealth;
new Handle:hSipowSpeed;
new Handle:hSipowThrow;
new Handle:hSipowFireImmunity;
new Handle:hSipowStormDelay;
new Handle:hSipowStormDamage;
new Handle:hPoltergeistEnabled;
new Handle:hPoltergeistExtraHealth;
new Handle:hPoltergeistSpeed;
new Handle:hPoltergeistThrow;
new Handle:hPoltergeistFireImmunity;
new Handle:hPoltergeistDisarm;
new Handle:hPoltergeistSpecialSpeed;
new Handle:hPoltergeistTeleportDelay;
new Handle:hMirageEnabled;
new Handle:hMirageExtraHealth;
new Handle:hMirageSpeed;
new Handle:hMirageThrow;
new Handle:hMirageFireImmunity;
new Handle:hMirageSpecialSpeed;
new Handle:hMirageTeleportDelay;
new Handle:SDKSpitBurst;
new Handle:SDKVomitOnPlayer;
new Handle:hPluginEnable;
new Handle:hBarLEN;
new prevMAX[66];
new prevHP[66];
new nCharLength;
new String:sCharHealth[8] = "|";
new String:sCharDamage[8] = "-";
new Handle:hCharHealth;
new Handle:hCharDamage;
new Handle:hShowType;
new Handle:hShowNum;
new Handle:hTank;
new nShowType;
new nShowNum;
new nShowTank;
new bool:bSuperTanksEnabled;
new iWave1Cvar;
new iWave2Cvar;
new iWave3Cvar;
new bool:bFinaleOnly;
new bool:bDisplayHealthCvar;
new bool:bDefaultTanks;
new bool:bTankEnabled[41];
new iTankExtraHealth[41];
new Float:flTankSpeed[41];
new Float:flTankThrow[41];
new bool:bTankFireImmunity[41];
new bool:bDefaultOverride;
new iSpawnCommonAmount;
new iSpawnCommonInterval;
new iSmasherMaimDamage;
new iSmasherCrushDamage;
new bool:bSmasherRemoveBody;
new iArmageddonMaimDamage;
new iArmageddonCrushDamage;
new bool:bArmageddonRemoveBody;
new iTrapMaimDamage;
new iTrapCrushDamage;
new bool:bTrapRemoveBody;
new iGoliathMaimDamage;
new iGoliathCrushDamage;
new bool:bGoliathRemoveBody;
new iWarpTeleportDelay;
new iPsychoticTeleportDelay;
new iFlashTeleportDelay;
new iReverseFlashTeleportDelay;
new iDistractionTeleportDelay;
new iHallucinationTeleportDelay;
new iFeedbackTeleportDelay;
new iPsykotikTeleportDelay;
new iSpykotikTeleportDelay;
new iSpypsyTeleportDelay;
new iPoltergeistTeleportDelay;
new iMirageTeleportDelay;
new iMeteorStormDelay;
new Float:flMeteorStormDamage;
new iPsychoticStormDelay;
new Float:flPsychoticStormDamage;
new iArmageddonStormDelay;
new Float:flArmageddonStormDamage;
new iSipowStormDelay;
new Float:flSipowStormDamage;
new iHealthHealthCommons;
new iHealthHealthSpecials;
new iHealthHealthTanks;
new iPsychoticHealthCommons;
new iPsychoticHealthSpecials;
new iPsychoticHealthTanks;
new iGoliathHealthCommons;
new iGoliathHealthSpecials;
new iGoliathHealthTanks;
new iPsykotikHealthCommons;
new iPsykotikHealthSpecials;
new iPsykotikHealthTanks;
new bool:bGhostDisarm;
new bool:bHallucinationDisarm;
new bool:bPoltergeistDisarm;
new iShockStunDamage;
new Float:flShockStunMovement;
new iFeedbackStunDamage;
new Float:flFeedbackStunMovement;
new iWitchMaxWitches;
new Float:flShieldShieldsDownInterval;
new Float:flCobaltSpecialSpeed;
new Float:flFlashSpecialSpeed;
new Float:flReverseFlashSpecialSpeed;
new Float:flPsykotikSpecialSpeed;
new Float:flSpykotikSpecialSpeed;
new Float:flSpypsySpecialSpeed;
new Float:flPoltergeistSpecialSpeed;
new Float:flMirageSpecialSpeed;
new iJumperJumpDelay;
new iPsychoticJumpDelay;
new iDistractionJumpDelay;
new Float:flGravityPullForce;
new Float:flArmageddonPullForce;
new Float:flFeedbackPushForce;
new iMemeCommonAmount;
new iMemeCommonInterval;
new iMemeMaimDamage;
new iMemeCrushDamage;
new bool:bMemeRemoveBody;
new iMemeTeleportDelay;
new iMemeStormDelay;
new Float:flMemeStormDamage;
new bool:bMemeDisarm;
new iMemeMaxWitches;
new Float:flMemeSpecialSpeed;
new iMemeJumpDelay;
new Float:flMemePullForce;
new iBossMaimDamage;
new iBossCrushDamage;
new bool:bBossRemoveBody;
new iBossTeleportDelay;
new iBossStormDelay;
new Float:flBossStormDamage;
new iBossHealthCommons;
new iBossHealthSpecials;
new iBossHealthTanks;
new bool:bBossDisarm;
new iBossMaxWitches;
new Float:flBossSpecialSpeed;
new iBossJumpDelay;
new Float:flBossPullForce;

////////////////////////////////////////////
// Descompilator = "By Striker★BlacK"	  //
////////////////////////////////////////////

// edited by [†×Ą]AYA SUPAY[Ļ×Ø]"

public Plugin:myinfo =
{
	name = "[L4D] Super Tanks",
	description = "Adds 40 unique types of finale Tanks to Coop, Realism, and Survival gamemodes.",
	author = "Machine and Psykotik",
	version = "5.5",
	url = "http://forums.alliedmods.net/showthread.php?t=302140"
};

public void OnPluginStart()
{
	CreateConVar("st_version", "5.5", "Super Tanks Version", 393472, false, 0.0, false, 0.0);
	hSuperTanksEnabled = CreateConVar("st_on", "1.0", "Is Super Tanks enabled?", 262400, true, 0.0, true, 1.0);
	hDisplayHealthCvar = CreateConVar("st_display_health", "1.0", "Display tanks health in crosshair?", 262400, true, 0.0, true, 1.0);
	hWave1Cvar = CreateConVar("st_wave1_tanks", "1.0", "Default number of tanks in the 1st wave of finale.", 262400, true, 0.0, true, 999.0);
	hWave2Cvar = CreateConVar("st_wave2_tanks", "2.0", "Default number of tanks in the 2nd wave of finale.", 262400, true, 0.0, true, 999.0);
	hWave3Cvar = CreateConVar("st_wave3_tanks", "1.0", "Default number of tanks in the finale escape.", 262400, true, 0.0, true, 999.0);
	hFinaleOnly = CreateConVar("st_finale_only", "0.0", "Create Super Tanks in finale only?", 262400, true, 0.0, true, 1.0);
	hDefaultTanks = CreateConVar("st_default_tanks", "0.0", "Only use default tanks?", 262400, true, 0.0, true, 1.0);
	henable_announce = CreateConVar("st_enable_announce", "1.0", "Enable Announcement.(0:OFF 1:ON)", 262400, true, 0.0, true, 1.0);
	hPluginEnable = CreateConVar("st_tankhp", "1", "plugin on/off (on:1 / off:0)", 262464, true, 0.0, true, 1.0);
	hBarLEN = CreateConVar("st_tankhp_bar", "20", "length of health bar (def:100 / min:10 / max:200)", 262464, true, 10.0, true, 200.0);
	hCharHealth = CreateConVar("st_tankhp_health", "|", "show health character", 262464, false, 0.0, false, 0.0);
	hCharDamage = CreateConVar("st_tankhp_damage", "-", "show damage character", 262464, false, 0.0, false, 0.0);
	hShowType = CreateConVar("st_tankhp_type", "1", "health bar type (def:0 / center text:0 / hint text:1)", 262464, true, 0.0, true, 1.0);
	hShowNum = CreateConVar("st_tankhp_num", "1", "health value display (def:0 / hidden:0 / visible:1)", 262464, true, 0.0, true, 1.0);
	hTank = CreateConVar("st_tankhp_tank", "1", "show health bar (def:1 / on:1 / off:0)", 262464, true, 0.0, true, 1.0);
	hGamemodeCvar = FindConVar("mp_gamemode");
	hDefaultOverride = CreateConVar("st_default_override", "0.0", "Setting this to 1 will allow further customization to default tanks.", 262400, true, 0.0, true, 1.0);
	hDefaultExtraHealth = CreateConVar("st_default_extra_health", "0.0", "Default Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hDefaultSpeed = CreateConVar("st_default_speed", "1.0", "Default Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hDefaultThrow = CreateConVar("st_default_throw", "5.0", "Default Tanks rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hDefaultFireImmunity = CreateConVar("st_default_fire_immunity", "0.0", "Are Default Tanks immune to fire?", 262400, true, 0.0, true, 1.0);
	hSpawnEnabled = CreateConVar("st_spawn_enabled", "1.0", "Is Spawn Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hSpawnExtraHealth = CreateConVar("st_spawn_extra_health", "50000.0", "Spawn Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hSpawnSpeed = CreateConVar("st_spawn_speed", "1.0", "Spawn Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hSpawnThrow = CreateConVar("st_spawn_throw", "10.0", "Spawn Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hSpawnFireImmunity = CreateConVar("st_spawn_fire_immunity", "0.0", "Is Spawn Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hSpawnCommonAmount = CreateConVar("st_spawn_common_amount", "10.0", "Number of common infected spawned by the Spawn Tank.", 262400, true, 1.0, true, 50.0);
	hSpawnCommonInterval = CreateConVar("st_spawn_common_interval", "40.0", "Spawn Tanks common infected spawn interval.", 262400, true, 1.0, true, 999.0);
	hSmasherEnabled = CreateConVar("st_smasher_enabled", "1.0", "Is Smasher Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hSmasherExtraHealth = CreateConVar("st_smasher_extra_health", "50000.0", "Smasher Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hSmasherSpeed = CreateConVar("st_smasher_speed", "0.65", "Smasher Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hSmasherThrow = CreateConVar("st_smasher_throw", "30.0", "Smasher Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hSmasherFireImmunity = CreateConVar("st_smasher_fire_immunity", "0.0", "Is Smasher Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hSmasherMaimDamage = CreateConVar("st_smasher_maim_damage", "1.0", "Smasher Tanks maim attack will set victims health to this amount.", 262400, true, 1.0, true, 99.0);
	hSmasherCrushDamage = CreateConVar("st_smasher_crush_damage", "50.0", "Smasher Tanks claw attack damage.", 262400, true, 0.0, true, 1000.0);
	hSmasherRemoveBody = CreateConVar("st_smasher_remove_body", "1.0", "Smasher Tanks crush attack will remove survivors death body?", 262400, true, 0.0, true, 1.0);
	hTrapEnabled = CreateConVar("st_trap_enabled", "1.0", "Is Trap Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hTrapExtraHealth = CreateConVar("st_trap_extra_health", "50000.0", "Trap Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hTrapSpeed = CreateConVar("st_trap_speed", "0.5", "Trap Tanks default movement speed.", 262400, true, 0.0, true, 1.5);
	hTrapThrow = CreateConVar("st_trap_throw", "999.0", "Trap Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hTrapFireImmunity = CreateConVar("st_trap_fire_immunity", "0.0", "Is Trap Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hTrapMaimDamage = CreateConVar("st_trap_maim_damage", "1.0", "Trap Tanks maim attack will set victims health to this amount.", 262400, true, 1.0, true, 99.0);
	hTrapCrushDamage = CreateConVar("st_trap_crush_damage", "1000.0", "Trap Tanks claw attack damage.", 262400, true, 0.0, true, 1000.0);
	hTrapRemoveBody = CreateConVar("st_trap_remove_body", "1.0", "Trap Tanks crush attack will remove survivors death body?", 262400, true, 0.0, true, 1.0);
	hWarpEnabled = CreateConVar("st_warp_enabled", "1.0", "Is Warp Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hWarpExtraHealth = CreateConVar("st_warp_extra_health", "50000.0", "Warp Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hWarpSpeed = CreateConVar("st_warp_speed", "1.0", "Warp Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hWarpThrow = CreateConVar("st_warp_throw", "9.0", "Warp Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hWarpFireImmunity = CreateConVar("st_warp_fire_immunity", "0.0", "Is Warp Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hWarpTeleportDelay = CreateConVar("st_warp_teleport_delay", "20.0", "Warp Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hFeedbackEnabled = CreateConVar("st_feedback_enabled", "1.0", "Is Feedback Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hFeedbackExtraHealth = CreateConVar("st_feedback_extra_health", "50000.0", "Feedback Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hFeedbackSpeed = CreateConVar("st_feedback_speed", "1.25", "Feedback Tanks default movement speed.", 262400, true, 0.0, true, 2.5);
	hFeedbackThrow = CreateConVar("st_feedback_throw", "999.0", "Feedback Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hFeedbackFireImmunity = CreateConVar("st_feedback_fire_immunity", "0.0", "Is Feedback Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hFeedbackTeleportDelay = CreateConVar("st_feedback_teleport_delay", "20.0", "Feedback Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hFeedbackPushForce = CreateConVar("st_feedback_push_force", "50.0", "Feedback Tanks push force value. Higher negative values equals greater push forces.", 262400, true, -200.0, true, 200.0);
	hFeedbackStunDamage = CreateConVar("st_feedback_stun_damage", "15.0", "Feedback Tanks stun damage.", 262400, true, 0.0, true, 1000.0);
	hFeedbackStunMovement = CreateConVar("st_feedback_stun_movement", "0.65", "Feedback Tanks stun reduce survivors speed to this amount.", 262400, true, 0.0, true, 1.0);
	hMeteorEnabled = CreateConVar("st_meteor_enabled", "1.0", "Is Meteor Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hMeteorExtraHealth = CreateConVar("st_meteor_extra_health", "50000.0", "Meteor Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hMeteorSpeed = CreateConVar("st_meteor_speed", "1.0", "Meteor Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hMeteorThrow = CreateConVar("st_meteor_throw", "10.0", "Meteor Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hMeteorFireImmunity = CreateConVar("st_meteor_fire_immunity", "0.0", "Is Meteor Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hMeteorStormDelay = CreateConVar("st_meteor_storm_delay", "30.0", "Meteor Tanks Meteor Storm Delay Interval.", 262400, true, 1.0, true, 999.0);
	hMeteorStormDamage = CreateConVar("st_meteor_storm_damage", "25.0", "Meteor Tanks falling meteor damage.", 262400, true, 0.0, true, 1000.0);
	hAcidEnabled = CreateConVar("st_acid_enabled", "0.0", "Is Acid Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hAcidExtraHealth = CreateConVar("st_acid_extra_health", "0.0", "Acid Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hAcidSpeed = CreateConVar("st_acid_speed", "1.0", "Acid Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hAcidThrow = CreateConVar("st_acid_throw", "6.0", "Acid Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hAcidFireImmunity = CreateConVar("st_acid_fire_immunity", "0.0", "Is Acid Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hHealthEnabled = CreateConVar("st_health_enabled", "1.0", "Is Health Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hHealthExtraHealth = CreateConVar("st_health_extra_health", "10000.0", "Health Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hHealthSpeed = CreateConVar("st_health_speed", "1.0", "Health Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hHealthThrow = CreateConVar("st_health_throw", "15.0", "Health Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hHealthFireImmunity = CreateConVar("st_health_fire_immunity", "0.0", "Is Health Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hHealthHealthCommons = CreateConVar("st_health_health_commons", "50.0", "Health Tanks receive this much health per second from being near a common infected.", 262400, true, 0.0, true, 500.0);
	hHealthHealthSpecials = CreateConVar("st_health_health_specials", "100.0", "Health Tanks receive this much health per second from being near a special infected.", 262400, true, 0.0, true, 1000.0);
	hHealthHealthTanks = CreateConVar("st_health_health_tanks", "500.0", "Health Tanks receive this much health per second from being near another tank.", 262400, true, 0.0, true, 5000.0);
	hFireEnabled = CreateConVar("st_fire_enabled", "1.0", "Is Fire Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hFireExtraHealth = CreateConVar("st_fire_extra_health", "50000.0", "Fire Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hFireSpeed = CreateConVar("st_fire_speed", "1.0", "Fire Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hFireThrow = CreateConVar("st_fire_throw", "6.0", "Fire Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hFireFireImmunity = CreateConVar("st_fire_fire_immunity", "0.0", "Is Fire Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hIceEnabled = CreateConVar("st_ice_enabled", "0.0", "Is Ice Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hIceExtraHealth = CreateConVar("st_ice_extra_health", "0.0", "Ice Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hIceSpeed = CreateConVar("st_ice_speed", "1.0", "Ice Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hIceThrow = CreateConVar("st_ice_throw", "6.0", "Ice Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hIceFireImmunity = CreateConVar("st_ice_fire_immunity", "0.0", "Is Ice Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hJockeyEnabled = CreateConVar("st_jockey_enabled", "0.0", "Is Jockey Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hJockeyExtraHealth = CreateConVar("st_jockey_extra_health", "0.0", "Jockey Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hJockeySpeed = CreateConVar("st_jockey_speed", "1.33", "Jockey Tanks default movement speed.", 262400, true, 0.0, true, 2.5);
	hJockeyThrow = CreateConVar("st_jockey_throw", "7.0", "Jockey Tank jockey throw ability interval.", 262400, true, 0.0, true, 999.0);
	hJockeyFireImmunity = CreateConVar("st_jockey_fire_immunity", "0.0", "Is Jockey Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hHunterEnabled = CreateConVar("st_hunter_enabled", "1.0", "Is Hunter Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hHunterExtraHealth = CreateConVar("st_hunter_extra_health", "50000.0", "Hunter Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hHunterSpeed = CreateConVar("st_hunter_speed", "1.33", "Hunter Tanks default movement speed.", 262400, true, 0.0, true, 2.5);
	hHunterThrow = CreateConVar("st_hunter_throw", "7.0", "Hunter Tank hunter throw ability interval.", 262400, true, 0.0, true, 999.0);
	hHunterFireImmunity = CreateConVar("st_hunter_fire_immunity", "0.0", "Is Hunter Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hSmokerEnabled = CreateConVar("st_smoker_enabled", "1.0", "Is Smoker Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hSmokerExtraHealth = CreateConVar("st_smoker_extra_health", "50000.0", "Smoker Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hSmokerSpeed = CreateConVar("st_smoker_speed", "1.33", "Smoker Tanks default movement speed.", 262400, true, 0.0, true, 2.5);
	hSmokerThrow = CreateConVar("st_smoker_throw", "7.0", "Smoker Tank smoker throw ability interval.", 262400, true, 0.0, true, 999.0);
	hSmokerFireImmunity = CreateConVar("st_smoker_fire_immunity", "0.0", "Is Smoker Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hBoomerEnabled = CreateConVar("st_boomer_enabled", "1.0", "Is Boomer Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hBoomerExtraHealth = CreateConVar("st_boomer_extra_health", "50000.0", "Boomer Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hBoomerSpeed = CreateConVar("st_boomer_speed", "1.33", "Boomer Tanks default movement speed.", 262400, true, 0.0, true, 2.5);
	hBoomerThrow = CreateConVar("st_boomer_throw", "7.0", "Boomer Tank boomer throw ability interval.", 262400, true, 0.0, true, 999.0);
	hBoomerFireImmunity = CreateConVar("st_boomer_fire_immunity", "0.0", "Is Boomer Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hChargerEnabled = CreateConVar("st_charger_enabled", "0.0", "Is Charger Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hChargerExtraHealth = CreateConVar("st_charger_extra_health", "0.0", "Charger Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hChargerSpeed = CreateConVar("st_charger_speed", "1.33", "Charger Tanks default movement speed.", 262400, true, 0.0, true, 2.5);
	hChargerThrow = CreateConVar("st_charger_throw", "7.0", "Charger Tank charger throw ability interval.", 262400, true, 0.0, true, 999.0);
	hChargerFireImmunity = CreateConVar("st_charger_fire_immunity", "0.0", "Is Charger Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hGhostEnabled = CreateConVar("st_ghost_enabled", "1.0", "Is Ghost Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hGhostExtraHealth = CreateConVar("st_ghost_extra_health", "50000.0", "Ghost Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hGhostSpeed = CreateConVar("st_ghost_speed", "1.0", "Ghost Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hGhostThrow = CreateConVar("st_ghost_throw", "15.0", "Ghost Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hGhostFireImmunity = CreateConVar("st_ghost_fire_immunity", "0.0", "Is Ghost Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hGhostDisarm = CreateConVar("st_ghost_disarm", "1.0", "Does Ghost Tank have a chance of disarming an attacking melee survivor?", 262400, true, 0.0, true, 1.0);
	hShockEnabled = CreateConVar("st_shock_enabled", "1.0", "Is Shock Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hShockExtraHealth = CreateConVar("st_shock_extra_health", "50000.0", "Shock Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hShockSpeed = CreateConVar("st_shock_speed", "1.0", "Shock Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hShockThrow = CreateConVar("st_shock_throw", "10.0", "Shock Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hShockFireImmunity = CreateConVar("st_shock_fire_immunity", "0.0", "Is Shock Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hShockStunDamage = CreateConVar("st_shock_stun_damage", "10.0", "Shock Tanks stun damage.", 262400, true, 0.0, true, 1000.0);
	hShockStunMovement = CreateConVar("st_shock_stun_movement", "0.75", "Shock Tanks stun reduce survivors speed to this amount.", 262400, true, 0.0, true, 1.0);
	hWitchEnabled = CreateConVar("st_witch_enabled", "1.0", "Is Witch Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hWitchExtraHealth = CreateConVar("st_witch_extra_health", "50000.0", "Witch Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hWitchSpeed = CreateConVar("st_witch_speed", "1.0", "Witch Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hWitchThrow = CreateConVar("st_witch_throw", "7.0", "Witch Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hWitchFireImmunity = CreateConVar("st_witch_fire_immunity", "0.0", "Is Witch Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hWitchMaxWitches = CreateConVar("st_witch_max_witches", "1.0", "Maximum number of witches converted from common infected by the Witch Tank.", 262400, true, 0.0, true, 100.0);
	hShieldEnabled = CreateConVar("st_shield_enabled", "0.0", "Is Shield Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hShieldExtraHealth = CreateConVar("st_shield_extra_health", "0.0", "Shield Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hShieldSpeed = CreateConVar("st_shield_speed", "1.0", "Shield Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hShieldThrow = CreateConVar("st_shield_throw", "10.0", "Shield Tank propane throw ability interval.", 262400, true, 0.0, true, 999.0);
	hShieldFireImmunity = CreateConVar("st_shield_fire_immunity", "0.0", "Is Shield Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hShieldShieldsDownInterval = CreateConVar("st_shield_shields_down_interval", "15.0", "When Shield Tanks shields are disabled, how long before shields activate again.", 262400, true, 0.1, true, 60.0);
	hCobaltEnabled = CreateConVar("st_cobalt_enabled", "1.0", "Is Cobalt Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hCobaltExtraHealth = CreateConVar("st_cobalt_extra_health", "50000.0", "Cobalt Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hCobaltSpeed = CreateConVar("st_cobalt_speed", "1.0", "Cobalt Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hCobaltThrow = CreateConVar("st_cobalt_throw", "999.0", "Cobalt Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hCobaltFireImmunity = CreateConVar("st_cobalt_fire_immunity", "0.0", "Is Cobalt Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hCobaltSpecialSpeed = CreateConVar("st_cobalt_special_speed", "2.5", "Cobalt Tanks movement value when speeding towards a survivor.", 262400, true, 1.0, true, 5.0);
	hJumperEnabled = CreateConVar("st_jumper_enabled", "1.0", "Is Jumper Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hJumperExtraHealth = CreateConVar("st_jumper_extra_health", "50000.0", "Jumper Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hJumperSpeed = CreateConVar("st_jumper_speed", "1.20", "Jumper Tanks default movement speed.", 262400, true, 0.0, true, 2.5);
	hJumperThrow = CreateConVar("st_jumper_throw", "999.0", "Jumper Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hJumperFireImmunity = CreateConVar("st_jumper_fire_immunity", "0.0", "Is Jumper Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hJumperJumpDelay = CreateConVar("st_jumper_jump_delay", "5.0", "Jumper Tanks delay interval to jump again.", 262400, true, 1.0, true, 999.0);
	hDistractionEnabled = CreateConVar("st_distraction_enabled", "1.0", "Is Distraction Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hDistractionExtraHealth = CreateConVar("st_distraction_extra_health", "50000.0", "Distraction Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hDistractionSpeed = CreateConVar("st_distraction_speed", "1.20", "Distraction Tanks default movement speed.", 262400, true, 0.0, true, 2.5);
	hDistractionThrow = CreateConVar("st_distraction_throw", "999.0", "Distraction Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hDistractionFireImmunity = CreateConVar("st_distraction_fire_immunity", "0.0", "Is Distraction Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hDistractionJumpDelay = CreateConVar("st_distraction_jump_delay", "1.0", "Distraction Tanks delay interval to jump again.", 262400, true, 1.0, true, 999.0);
	hDistractionTeleportDelay = CreateConVar("st_distraction_teleport_delay", "20.0", "Distraction Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hGravityEnabled = CreateConVar("st_gravity_enabled", "1.0", "Is Gravity Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hGravityExtraHealth = CreateConVar("st_gravity_extra_health", "50000.0", "Gravity Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hGravitySpeed = CreateConVar("st_gravity_speed", "1.0", "Gravity Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hGravityThrow = CreateConVar("st_gravity_throw", "10.0", "Gravity Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hGravityFireImmunity = CreateConVar("st_gravity_fire_immunity", "0.0", "Is Gravity Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hGravityPullForce = CreateConVar("st_gravity_pull_force", "-30.0", "Gravity Tanks pull force value. Higher negative values equals greater pull forces.", 262400, true, -100.0, true, 0.0);
	hFlashEnabled = CreateConVar("st_flash_enabled", "1.0", "Is Flash Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hFlashExtraHealth = CreateConVar("st_flash_extra_health", "50000.0", "Flash Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hFlashSpeed = CreateConVar("st_flash_speed", "2.5", "Flash Tanks default movement speed.", 262400, true, 0.0, true, 3.5);
	hFlashThrow = CreateConVar("st_flash_throw", "999.0", "Flash Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hFlashFireImmunity = CreateConVar("st_flash_fire_immunity", "0.0", "Is Flash Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hFlashSpecialSpeed = CreateConVar("st_flash_special_speed", "4.0", "Flash Tanks movement value when speeding towards a survivor.", 262400, true, 1.0, true, 5.0);
	hFlashTeleportDelay = CreateConVar("st_flash_teleport_delay", "15.0", "Flash Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hReverseFlashEnabled = CreateConVar("st_reverseflash_enabled", "1.0", "Is Reverse Flash Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hReverseFlashExtraHealth = CreateConVar("st_reverseflash_extra_health", "50000.0", "Reverse Flash Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hReverseFlashSpeed = CreateConVar("st_reverseflash_speed", "3.0", "Reverse Flash Tanks default movement speed.", 262400, true, 0.0, true, 4.0);
	hReverseFlashThrow = CreateConVar("st_reverseflash_throw", "999.0", "Reverse Flash Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hReverseFlashFireImmunity = CreateConVar("st_reverseflash_fire_immunity", "0.0", "Is Reverse Flash Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hReverseFlashSpecialSpeed = CreateConVar("st_reverseflash_special_speed", "5.0", "Reverse Flash Tanks movement value when speeding towards a survivor.", 262400, true, 1.0, true, 6.0);
	hReverseFlashTeleportDelay = CreateConVar("st_reverseflash_teleport_delay", "20.0", "Reverse Flash Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hArmageddonEnabled = CreateConVar("st_armageddon_enabled", "1.0", "Is Armageddon Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hArmageddonExtraHealth = CreateConVar("st_armageddon_extra_health", "50000.0", "Armageddon Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hArmageddonSpeed = CreateConVar("st_armageddon_speed", "0.65", "Armageddon Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hArmageddonThrow = CreateConVar("st_armageddon_throw", "30.0", "Armageddon Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hArmageddonFireImmunity = CreateConVar("st_armageddon_fire_immunity", "0.0", "Is Armageddon Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hArmageddonMaimDamage = CreateConVar("st_armageddon_maim_damage", "1.0", "Armageddon Tanks maim attack will set victims health to this amount.", 262400, true, 1.0, true, 99.0);
	hArmageddonCrushDamage = CreateConVar("st_armageddon_crush_damage", "25.0", "Armageddon Tanks claw attack damage.", 262400, true, 0.0, true, 100.0);
	hArmageddonRemoveBody = CreateConVar("st_armageddon_remove_body", "1.0", "Armageddon Tanks crush attack will remove survivors death body?", 262400, true, 0.0, true, 1.0);
	hArmageddonStormDelay = CreateConVar("st_armageddon_storm_delay", "15.0", "Armageddon Tanks Meteor Storm Delay Interval.", 262400, true, 1.0, true, 999.0);
	hArmageddonStormDamage = CreateConVar("st_armageddon_storm_damage", "50.0", "Armageddon Tanks falling meteor damage.", 262400, true, 0.0, true, 1000.0);
	hArmageddonPullForce = CreateConVar("st_armageddon_pull_force", "-30.0", "Armageddon Tanks pull force value. Higher negative values equals greater pull forces.", 262400, true, -150.0, true, 0.0);
	hHallucinationEnabled = CreateConVar("st_hallucination_enabled", "1.0", "Is Hallucination Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hHallucinationExtraHealth = CreateConVar("st_hallucination_extra_health", "50000.0", "Hallucination Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hHallucinationSpeed = CreateConVar("st_hallucination_speed", "1.0", "Hallucination Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hHallucinationThrow = CreateConVar("st_hallucination_throw", "999.0", "Hallucination Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hHallucinationFireImmunity = CreateConVar("st_hallucination_fire_immunity", "0.0", "Is Hallucination Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hHallucinationTeleportDelay = CreateConVar("st_hallucination_teleport_delay", "20.0", "Hallucination Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hHallucinationDisarm = CreateConVar("st_hallucination_disarm", "1.0", "Does Hallucination Tank have a chance of disarming an attacking melee survivor?", 262400, true, 0.0, true, 1.0);
	hMinionEnabled = CreateConVar("st_minion_enabled", "1.0", "Is Minion Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hMinionExtraHealth = CreateConVar("st_minion_extra_health", "10000.0", "Minion Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hMinionSpeed = CreateConVar("st_minion_speed", "1.33", "Minion Tanks default movement speed.", 262400, true, 0.0, true, 2.5);
	hMinionThrow = CreateConVar("st_minion_throw", "60.0", "Minion Tank tank throw ability interval.", 262400, true, 0.0, true, 999.0);
	hMinionFireImmunity = CreateConVar("st_minion_fire_immunity", "0.0", "Is Minion Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hBitchEnabled = CreateConVar("st_bitch_enabled", "1.0", "Is Bitch Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hBitchExtraHealth = CreateConVar("st_bitch_extra_health", "0.0", "Bitch Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hBitchSpeed = CreateConVar("st_bitch_speed", "1.33", "Bitch Tanks default movement speed.", 262400, true, 0.0, true, 2.5);
	hBitchThrow = CreateConVar("st_bitch_throw", "7.0", "Bitch Tank witch throw ability interval.", 262400, true, 0.0, true, 999.0);
	hBitchFireImmunity = CreateConVar("st_bitch_fire_immunity", "0.0", "Is Bitch Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hPsychoticEnabled = CreateConVar("st_psychotic_enabled", "1.0", "Is Psychotic Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hPsychoticExtraHealth = CreateConVar("st_psychotic_extra_health", "10000.0", "Psychotic Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hPsychoticSpeed = CreateConVar("st_psychotic_speed", "1.0", "Psychotic Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hPsychoticThrow = CreateConVar("st_psychotic_throw", "10.0", "Psychotic Tank propane throw ability interval.", 262400, true, 0.0, true, 999.0);
	hPsychoticFireImmunity = CreateConVar("st_psychotic_fire_immunity", "0.0", "Is Psychotic Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hPsychoticTeleportDelay = CreateConVar("st_psychotic_teleport_delay", "20.0", "Psychotic Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hPsychoticHealthCommons = CreateConVar("st_psychotic_health_commons", "10.0", "Psychotic Tanks receive this much health per second from being near a common infected.", 262400, true, 0.0, true, 100.0);
	hPsychoticHealthSpecials = CreateConVar("st_psychotic_health_specials", "50.0", "Psychotic Tanks receive this much health per second from being near a special infected.", 262400, true, 0.0, true, 500.0);
	hPsychoticHealthTanks = CreateConVar("st_psychotic_health_tanks", "100.0", "Psychotic Tanks receive this much health per second from being near another tank.", 262400, true, 0.0, true, 1000.0);
	hPsychoticStormDelay = CreateConVar("st_psychotic_storm_delay", "20.0", "Psychotic Tanks Meteor Storm Delay Interval.", 262400, true, 1.0, true, 999.0);
	hPsychoticStormDamage = CreateConVar("st_psychotic_storm_damage", "20.0", "Psychotic Tanks falling meteor damage.", 262400, true, 0.0, true, 1000.0);
	hPsychoticJumpDelay = CreateConVar("st_psychotic_jump_delay", "15.0", "Psychotic Tanks delay interval to jump again.", 262400, true, 1.0, true, 999.0);
	hSpitterEnabled = CreateConVar("st_spitter_enabled", "0.0", "Is Spitter Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hSpitterExtraHealth = CreateConVar("st_spitter_extra_health", "0.0", "Spitter Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hSpitterSpeed = CreateConVar("st_spitter_speed", "1.33", "Spitter Tanks default movement speed.", 262400, true, 0.0, true, 2.5);
	hSpitterThrow = CreateConVar("st_spitter_throw", "7.0", "Spitter Tank spitter throw ability interval.", 262400, true, 0.0, true, 999.0);
	hSpitterFireImmunity = CreateConVar("st_spitter_fire_immunity", "0.0", "Is Spitter Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hGoliathEnabled = CreateConVar("st_goliath_enabled", "1.0", "Is Goliath Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hGoliathExtraHealth = CreateConVar("st_goliath_extra_health", "10000.0", "Goliath Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hGoliathSpeed = CreateConVar("st_goliath_speed", "0.5", "Goliath Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hGoliathThrow = CreateConVar("st_goliath_throw", "7.5", "Goliath Tank propane throw ability interval.", 262400, true, 0.0, true, 999.0);
	hGoliathFireImmunity = CreateConVar("st_goliath_fire_immunity", "0.0", "Is Goliath Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hGoliathMaimDamage = CreateConVar("st_goliath_maim_damage", "1.0", "Goliath Tanks maim attack will set victims health to this amount.", 262400, true, 1.0, true, 99.0);
	hGoliathCrushDamage = CreateConVar("st_goliath_crush_damage", "1000.0", "Goliath Tanks claw attack damage.", 262400, true, 0.0, true, 1000.0);
	hGoliathRemoveBody = CreateConVar("st_goliath_remove_body", "1.0", "Goliath Tanks crush attack will remove survivors death body?", 262400, true, 0.0, true, 1.0);
	hGoliathHealthCommons = CreateConVar("st_goliath_health_commons", "100.0", "Goliath Tanks receive this much health per second from being near a common infected.", 262400, true, 0.0, true, 1000.0);
	hGoliathHealthSpecials = CreateConVar("st_goliath_health_specials", "500.0", "Goliath Tanks receive this much health per second from being near a special infected.", 262400, true, 0.0, true, 5000.0);
	hGoliathHealthTanks = CreateConVar("st_goliath_health_tanks", "1000.0", "Goliath Tanks receive this much health per second from being near another tank.", 262400, true, 0.0, true, 31000.0);
	hPsykotikEnabled = CreateConVar("st_psykotik_enabled", "1.0", "Is Psykotik Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hPsykotikExtraHealth = CreateConVar("st_psykotik_extra_health", "10000.0", "Psykotik Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hPsykotikSpeed = CreateConVar("st_psykotik_speed", "3.5", "Psykotik Tanks default movement speed.", 262400, true, 0.0, true, 5.5);
	hPsykotikThrow = CreateConVar("st_psykotik_throw", "999.0", "Psykotik Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hPsykotikFireImmunity = CreateConVar("st_psykotik_fire_immunity", "0.0", "Is Psykotik Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hPsykotikSpecialSpeed = CreateConVar("st_psykotik_special_speed", "6.0", "Psykotik Tanks movement value when speeding towards a survivor.", 262400, true, 1.0, true, 7.0);
	hPsykotikTeleportDelay = CreateConVar("st_psykotik_teleport_delay", "15.0", "Psykotik Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hPsykotikHealthCommons = CreateConVar("st_psykotik_health_commons", "5.0", "Psykotik Tanks receive this much health per second from being near a common infected.", 262400, true, 0.0, true, 50.0);
	hPsykotikHealthSpecials = CreateConVar("st_psykotik_health_specials", "25.0", "Psykotik Tanks receive this much health per second from being near a special infected.", 262400, true, 0.0, true, 250.0);
	hPsykotikHealthTanks = CreateConVar("st_psykotik_health_tanks", "50.0", "Psykotik Tanks receive this much health per second from being near another tank.", 262400, true, 0.0, true, 500.0);
	hSpykotikEnabled = CreateConVar("st_spykotik_enabled", "1.0", "Is Spykotik Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hSpykotikExtraHealth = CreateConVar("st_spykotik_extra_health", "50000.0", "Spykotik Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hSpykotikSpeed = CreateConVar("st_spykotik_speed", "2.0", "Spykotik Tanks default movement speed.", 262400, true, 0.0, true, 3.0);
	hSpykotikThrow = CreateConVar("st_spykotik_throw", "999.0", "Spykotik Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hSpykotikFireImmunity = CreateConVar("st_spykotik_fire_immunity", "0.0", "Is Spykotik Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hSpykotikSpecialSpeed = CreateConVar("st_spykotik_special_speed", "3.0", "Spykotik Tanks movement value when speeding towards a survivor.", 262400, true, 1.0, true, 4.0);
	hSpykotikTeleportDelay = CreateConVar("st_spykotik_teleport_delay", "15.0", "Spykotik Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hSpypsyEnabled = CreateConVar("st_spypsy_enabled", "1.0", "Is Spypsy Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hSpypsyExtraHealth = CreateConVar("st_spypsy_extra_health", "50000.0", "Spypsy Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hSpypsySpeed = CreateConVar("st_spypsy_speed", "1.0", "Spypsy Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hSpypsyThrow = CreateConVar("st_spypsy_throw", "999.0", "Spypsy Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hSpypsyFireImmunity = CreateConVar("st_spypsy_fire_immunity", "0.0", "Is Spypsy Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hSpypsySpecialSpeed = CreateConVar("st_spypsy_special_speed", "2.0", "Spypsy Tanks movement value when speeding towards a survivor.", 262400, true, 1.0, true, 3.0);
	hSpypsyTeleportDelay = CreateConVar("st_spypsy_teleport_delay", "15.0", "Spypsy Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hSipowEnabled = CreateConVar("st_sipow_enabled", "1.0", "Is Sipow Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hSipowExtraHealth = CreateConVar("st_sipow_extra_health", "50000.0", "Sipow Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hSipowSpeed = CreateConVar("st_sipow_speed", "1.33", "Sipow Tanks default movement speed.", 262400, true, 0.0, true, 2.5);
	hSipowThrow = CreateConVar("st_sipow_throw", "10.0", "Sipow Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hSipowFireImmunity = CreateConVar("st_sipow_fire_immunity", "0.0", "Is Sipow Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hSipowStormDelay = CreateConVar("st_sipow_storm_delay", "8.0", "Sipow Tanks Meteor Storm Delay Interval.", 262400, true, 1.0, true, 999.0);
	hSipowStormDamage = CreateConVar("st_sipow_storm_damage", "50.0", "Sipow Tanks falling meteor damage.", 262400, true, 0.0, true, 1000.0);
	hPoltergeistEnabled = CreateConVar("st_poltergeist_enabled", "1.0", "Is Poltergeist Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hPoltergeistExtraHealth = CreateConVar("st_poltergeist_extra_health", "50000.0", "Poltergeist Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hPoltergeistSpeed = CreateConVar("st_poltergeist_speed", "1.0", "Poltergeist Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hPoltergeistThrow = CreateConVar("st_poltergeist_throw", "999.0", "Poltergeist Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hPoltergeistFireImmunity = CreateConVar("st_poltergeist_fire_immunity", "0.0", "Is Poltergeist Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hPoltergeistSpecialSpeed = CreateConVar("st_poltergeist_special_speed", "2.0", "Poltergeist Tanks movement value when speeding towards a survivor.", 262400, true, 1.0, true, 3.0);
	hPoltergeistTeleportDelay = CreateConVar("st_poltergeist_teleport_delay", "15.0", "Poltergeist Tanks Teleport Delay Interval Value.", 262400, true, 1.0, true, 999.0);
	hPoltergeistDisarm = CreateConVar("st_poltergeist_disarm", "1.0", "Does Poltergeist Tank have a chance of disarming an attacking melee survivor?", 262400, true, 0.0, true, 1.0);
	hMirageEnabled = CreateConVar("st_mirage_enabled", "1.0", "Is Mirage Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hMirageExtraHealth = CreateConVar("st_mirage_extra_health", "50000.0", "Mirage Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hMirageSpeed = CreateConVar("st_mirage_speed", "1.0", "Mirage Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hMirageThrow = CreateConVar("st_mirage_throw", "60.0", "Mirage Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hMirageFireImmunity = CreateConVar("st_mirage_fire_immunity", "0.0", "Is Mirage Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hMirageSpecialSpeed = CreateConVar("st_mirage_special_speed", "3.0", "Mirage Tanks movement value when speeding towards a survivor.", 262400, true, 1.0, true, 4.0);
	hMirageTeleportDelay = CreateConVar("st_mirage_teleport_delay", "15.0", "Mirage Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hMemeEnabled = CreateConVar("st_meme_enabled", "1.0", "Is Meme Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hMemeExtraHealth = CreateConVar("st_meme_extra_health", "50000.0", "Meme Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hMemeSpeed = CreateConVar("st_meme_speed", "0.5", "Meme Tanks default movement speed.", 262400, true, 0.0, true, 1.5);
	hMemeThrow = CreateConVar("st_meme_throw", "25.0", "Meme Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hMemeFireImmunity = CreateConVar("st_meme_fire_immunity", "0.0", "Is Meme Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hMemeCommonAmount = CreateConVar("st_meme_common_amount", "5.0", "Number of common infected spawned by the Meme Tank.", 262400, true, 1.0, true, 50.0);
	hMemeCommonInterval = CreateConVar("st_meme_common_interval", "25.0", "Meme Tanks common infected spawn interval.", 262400, true, 1.0, true, 999.0);
	hMemeMaimDamage = CreateConVar("st_meme_maim_damage", "99.0", "Meme Tanks maim attack will set victims health to this amount.", 262400, true, 1.0, true, 99.0);
	hMemeCrushDamage = CreateConVar("st_meme_crush_damage", "1.0", "Meme Tanks claw attack damage.", 262400, true, 0.0, true, 1000.0);
	hMemeRemoveBody = CreateConVar("st_meme_remove_body", "1.0", "Meme Tanks crush attack will remove survivors death body?", 262400, true, 0.0, true, 1.0);
	hMemeTeleportDelay = CreateConVar("st_meme_teleport_delay", "15.0", "Meme Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hMemeStormDelay = CreateConVar("st_meme_storm_delay", "10.0", "Meme Tanks Meteor Storm Delay Interval.", 262400, true, 1.0, true, 999.0);
	hMemeStormDamage = CreateConVar("st_meme_storm_damage", "1.0", "Meme Tanks falling meteor damage.", 262400, true, 0.0, true, 1000.0);
	hMemeDisarm = CreateConVar("st_meme_disarm", "1.0", "Does Meme Tank have a chance of disarming an attacking melee survivor?", 262400, true, 0.0, true, 1.0);
	hMemeMaxWitches = CreateConVar("st_meme_max_witches", "1.0", "Maximum number of witches converted from common infected by the Meme Tank.", 262400, true, 0.0, true, 100.0);
	hMemeSpecialSpeed = CreateConVar("st_meme_special_speed", "2.0", "Meme Tanks movement value when speeding towards a survivor.", 262400, true, 1.0, true, 3.0);
	hMemeJumpDelay = CreateConVar("st_meme_jump_delay", "15.0", "Meme Tanks delay interval to jump again.", 262400, true, 1.0, true, 999.0);
	hMemePullForce = CreateConVar("st_meme_pull_force", "-25.0", "Meme Tanks pull force value. Higher negative values equals greater pull forces.", 262400, true, -50.0, true, 0.0);
	hBossEnabled = CreateConVar("st_boss_enabled", "1.0", "Is Boss Tank Enabled?", 262400, true, 0.0, true, 1.0);
	hBossExtraHealth = CreateConVar("st_boss_extra_health", "10000.0", "Boss Tanks receive this many additional hitpoints.", 262400, true, 0.0, true, 310000.0);
	hBossSpeed = CreateConVar("st_boss_speed", "1.0", "Boss Tanks default movement speed.", 262400, true, 0.0, true, 2.0);
	hBossThrow = CreateConVar("st_boss_throw", "5.0", "Boss Tank rock throw ability interval.", 262400, true, 0.0, true, 999.0);
	hBossFireImmunity = CreateConVar("st_boss_fire_immunity", "0.0", "Is Boss Tank immune to fire?", 262400, true, 0.0, true, 1.0);
	hBossMaimDamage = CreateConVar("st_boss_maim_damage", "1.0", "Boss Tanks maim attack will set victims health to this amount.", 262400, true, 1.0, true, 99.0);
	hBossCrushDamage = CreateConVar("st_boss_crush_damage", "75.0", "Boss Tanks claw attack damage.", 262400, true, 0.0, true, 1000.0);
	hBossRemoveBody = CreateConVar("st_boss_remove_body", "1.0", "Boss Tanks crush attack will remove survivors death body?", 262400, true, 0.0, true, 1.0);
	hBossTeleportDelay = CreateConVar("st_boss_teleport_delay", "15.0", "Boss Tanks Teleport Delay Interval.", 262400, true, 1.0, true, 999.0);
	hBossStormDelay = CreateConVar("st_boss_storm_delay", "25.0", "Boss Tanks Meteor Storm Delay Interval.", 262400, true, 1.0, true, 999.0);
	hBossStormDamage = CreateConVar("st_boss_storm_damage", "50.0", "Boss Tanks falling meteor damage.", 262400, true, 0.0, true, 1000.0);
	hBossHealthCommons = CreateConVar("st_boss_health_commons", "5.0", "Boss Tanks receive this much health per second from being near a common infected.", 262400, true, 0.0, true, 50.0);
	hBossHealthSpecials = CreateConVar("st_boss_health_specials", "25.0", "Boss Tanks receive this much health per second from being near a special infected.", 262400, true, 0.0, true, 250.0);
	hBossHealthTanks = CreateConVar("st_boss_health_tanks", "50.0", "Boss Tanks receive this much health per second from being near another tank.", 262400, true, 0.0, true, 500.0);
	hBossDisarm = CreateConVar("st_boss_disarm", "1.0", "Does Boss Tank have a chance of disarming an attacking melee survivor?", 262400, true, 0.0, true, 1.0);
	hBossMaxWitches = CreateConVar("st_boss_max_witches", "5.0", "Maximum number of witches converted from common infected by the Boss Tank.", 262400, true, 0.0, true, 100.0);
	hBossSpecialSpeed = CreateConVar("st_boss_special_speed", "2.0", "Boss Tanks movement value when speeding towards a survivor.", 262400, true, 1.0, true, 3.0);
	hBossJumpDelay = CreateConVar("st_boss_jump_delay", "25.0", "Boss Tanks delay interval to jump again.", 262400, true, 1.0, true, 999.0);
	hBossPullForce = CreateConVar("st_boss_pull_force", "-25.0", "Boss Tanks pull force value. Higher negative values equals greater pull forces.", 262400, true, -150.0, true, 0.0);
	bSuperTanksEnabled = GetConVarBool(hSuperTanksEnabled);
	bDisplayHealthCvar = GetConVarBool(hDisplayHealthCvar);
	iWave1Cvar = GetConVarInt(hWave1Cvar);
	iWave2Cvar = GetConVarInt(hWave2Cvar);
	iWave3Cvar = GetConVarInt(hWave3Cvar);
	bFinaleOnly = GetConVarBool(hFinaleOnly);
	bDefaultTanks = GetConVarBool(hDefaultTanks);
	bDefaultOverride = GetConVarBool(hDefaultOverride);
	bTankEnabled[1] = GetConVarBool(hSpawnEnabled);
	bTankEnabled[2] = GetConVarBool(hSmasherEnabled);
	bTankEnabled[3] = GetConVarBool(hWarpEnabled);
	bTankEnabled[4] = GetConVarBool(hMeteorEnabled);
	bTankEnabled[5] = GetConVarBool(hAcidEnabled);
	bTankEnabled[6] = GetConVarBool(hHealthEnabled);
	bTankEnabled[7] = GetConVarBool(hFireEnabled);
	bTankEnabled[8] = GetConVarBool(hIceEnabled);
	bTankEnabled[9] = GetConVarBool(hJockeyEnabled);
	bTankEnabled[10] = GetConVarBool(hHunterEnabled);
	bTankEnabled[11] = GetConVarBool(hSmokerEnabled);
	bTankEnabled[12] = GetConVarBool(hBoomerEnabled);
	bTankEnabled[13] = GetConVarBool(hChargerEnabled);
	bTankEnabled[14] = GetConVarBool(hGhostEnabled);
	bTankEnabled[15] = GetConVarBool(hShockEnabled);
	bTankEnabled[16] = GetConVarBool(hWitchEnabled);
	bTankEnabled[17] = GetConVarBool(hShieldEnabled);
	bTankEnabled[18] = GetConVarBool(hCobaltEnabled);
	bTankEnabled[19] = GetConVarBool(hJumperEnabled);
	bTankEnabled[20] = GetConVarBool(hGravityEnabled);
	bTankEnabled[21] = GetConVarBool(hFlashEnabled);
	bTankEnabled[22] = GetConVarBool(hReverseFlashEnabled);
	bTankEnabled[23] = GetConVarBool(hArmageddonEnabled);
	bTankEnabled[24] = GetConVarBool(hHallucinationEnabled);
	bTankEnabled[25] = GetConVarBool(hMinionEnabled);
	bTankEnabled[26] = GetConVarBool(hBitchEnabled);
	bTankEnabled[27] = GetConVarBool(hTrapEnabled);
	bTankEnabled[28] = GetConVarBool(hDistractionEnabled);
	bTankEnabled[29] = GetConVarBool(hFeedbackEnabled);
	bTankEnabled[30] = GetConVarBool(hPsychoticEnabled);
	bTankEnabled[31] = GetConVarBool(hSpitterEnabled);
	bTankEnabled[32] = GetConVarBool(hGoliathEnabled);
	bTankEnabled[33] = GetConVarBool(hPsykotikEnabled);
	bTankEnabled[34] = GetConVarBool(hSpykotikEnabled);
	bTankEnabled[35] = GetConVarBool(hMemeEnabled);
	bTankEnabled[36] = GetConVarBool(hBossEnabled);
	bTankEnabled[37] = GetConVarBool(hSpypsyEnabled);
	bTankEnabled[38] = GetConVarBool(hSipowEnabled);
	bTankEnabled[39] = GetConVarBool(hPoltergeistEnabled);
	bTankEnabled[40] = GetConVarBool(hMirageEnabled);
	iTankExtraHealth[0] = GetConVarInt(hDefaultExtraHealth);
	iTankExtraHealth[1] = GetConVarInt(hSpawnExtraHealth);
	iTankExtraHealth[2] = GetConVarInt(hSmasherExtraHealth);
	iTankExtraHealth[3] = GetConVarInt(hWarpExtraHealth);
	iTankExtraHealth[4] = GetConVarInt(hMeteorExtraHealth);
	iTankExtraHealth[5] = GetConVarInt(hAcidExtraHealth);
	iTankExtraHealth[6] = GetConVarInt(hHealthExtraHealth);
	iTankExtraHealth[7] = GetConVarInt(hFireExtraHealth);
	iTankExtraHealth[8] = GetConVarInt(hIceExtraHealth);
	iTankExtraHealth[9] = GetConVarInt(hJockeyExtraHealth);
	iTankExtraHealth[10] = GetConVarInt(hHunterExtraHealth);
	iTankExtraHealth[11] = GetConVarInt(hSmokerExtraHealth);
	iTankExtraHealth[12] = GetConVarInt(hBoomerExtraHealth);
	iTankExtraHealth[13] = GetConVarInt(hChargerExtraHealth);
	iTankExtraHealth[14] = GetConVarInt(hGhostExtraHealth);
	iTankExtraHealth[15] = GetConVarInt(hShockExtraHealth);
	iTankExtraHealth[16] = GetConVarInt(hWitchExtraHealth);
	iTankExtraHealth[17] = GetConVarInt(hShieldExtraHealth);
	iTankExtraHealth[18] = GetConVarInt(hCobaltExtraHealth);
	iTankExtraHealth[19] = GetConVarInt(hJumperExtraHealth);
	iTankExtraHealth[20] = GetConVarInt(hGravityExtraHealth);
	iTankExtraHealth[21] = GetConVarInt(hFlashExtraHealth);
	iTankExtraHealth[22] = GetConVarInt(hReverseFlashExtraHealth);
	iTankExtraHealth[23] = GetConVarInt(hArmageddonExtraHealth);
	iTankExtraHealth[24] = GetConVarInt(hHallucinationExtraHealth);
	iTankExtraHealth[25] = GetConVarInt(hMinionExtraHealth);
	iTankExtraHealth[26] = GetConVarInt(hBitchExtraHealth);
	iTankExtraHealth[27] = GetConVarInt(hTrapExtraHealth);
	iTankExtraHealth[28] = GetConVarInt(hDistractionExtraHealth);
	iTankExtraHealth[29] = GetConVarInt(hFeedbackExtraHealth);
	iTankExtraHealth[30] = GetConVarInt(hPsychoticExtraHealth);
	iTankExtraHealth[31] = GetConVarInt(hSpitterExtraHealth);
	iTankExtraHealth[32] = GetConVarInt(hGoliathExtraHealth);
	iTankExtraHealth[33] = GetConVarInt(hPsykotikExtraHealth);
	iTankExtraHealth[34] = GetConVarInt(hSpykotikExtraHealth);
	iTankExtraHealth[35] = GetConVarInt(hMemeExtraHealth);
	iTankExtraHealth[36] = GetConVarInt(hBossExtraHealth);
	iTankExtraHealth[37] = GetConVarInt(hSpypsyExtraHealth);
	iTankExtraHealth[38] = GetConVarInt(hSipowExtraHealth);
	iTankExtraHealth[39] = GetConVarInt(hPoltergeistExtraHealth);
	iTankExtraHealth[40] = GetConVarInt(hMirageExtraHealth);
	flTankSpeed[0] = GetConVarFloat(hDefaultSpeed);
	flTankSpeed[1] = GetConVarFloat(hSpawnSpeed);
	flTankSpeed[2] = GetConVarFloat(hSmasherSpeed);
	flTankSpeed[3] = GetConVarFloat(hWarpSpeed);
	flTankSpeed[4] = GetConVarFloat(hMeteorSpeed);
	flTankSpeed[5] = GetConVarFloat(hAcidSpeed);
	flTankSpeed[6] = GetConVarFloat(hHealthSpeed);
	flTankSpeed[7] = GetConVarFloat(hFireSpeed);
	flTankSpeed[8] = GetConVarFloat(hIceSpeed);
	flTankSpeed[9] = GetConVarFloat(hJockeySpeed);
	flTankSpeed[10] = GetConVarFloat(hHunterSpeed);
	flTankSpeed[11] = GetConVarFloat(hSmokerSpeed);
	flTankSpeed[12] = GetConVarFloat(hBoomerSpeed);
	flTankSpeed[13] = GetConVarFloat(hChargerSpeed);
	flTankSpeed[14] = GetConVarFloat(hGhostSpeed);
	flTankSpeed[15] = GetConVarFloat(hShockSpeed);
	flTankSpeed[16] = GetConVarFloat(hWitchSpeed);
	flTankSpeed[17] = GetConVarFloat(hShieldSpeed);
	flTankSpeed[18] = GetConVarFloat(hCobaltSpeed);
	flTankSpeed[19] = GetConVarFloat(hJumperSpeed);
	flTankSpeed[20] = GetConVarFloat(hGravitySpeed);
	flTankSpeed[21] = GetConVarFloat(hFlashSpeed);
	flTankSpeed[22] = GetConVarFloat(hReverseFlashSpeed);
	flTankSpeed[23] = GetConVarFloat(hArmageddonSpeed);
	flTankSpeed[24] = GetConVarFloat(hHallucinationSpeed);
	flTankSpeed[25] = GetConVarFloat(hMinionSpeed);
	flTankSpeed[26] = GetConVarFloat(hBitchSpeed);
	flTankSpeed[27] = GetConVarFloat(hTrapSpeed);
	flTankSpeed[28] = GetConVarFloat(hDistractionSpeed);
	flTankSpeed[29] = GetConVarFloat(hFeedbackSpeed);
	flTankSpeed[30] = GetConVarFloat(hPsychoticSpeed);
	flTankSpeed[31] = GetConVarFloat(hSpitterSpeed);
	flTankSpeed[32] = GetConVarFloat(hGoliathSpeed);
	flTankSpeed[33] = GetConVarFloat(hPsykotikSpeed);
	flTankSpeed[34] = GetConVarFloat(hSpykotikSpeed);
	flTankSpeed[35] = GetConVarFloat(hMemeSpeed);
	flTankSpeed[36] = GetConVarFloat(hBossSpeed);
	flTankSpeed[37] = GetConVarFloat(hSpypsySpeed);
	flTankSpeed[38] = GetConVarFloat(hSipowSpeed);
	flTankSpeed[39] = GetConVarFloat(hPoltergeistSpeed);
	flTankSpeed[40] = GetConVarFloat(hMirageSpeed);
	flTankThrow[0] = GetConVarFloat(hDefaultThrow);
	flTankThrow[1] = GetConVarFloat(hSpawnThrow);
	flTankThrow[2] = GetConVarFloat(hSmasherThrow);
	flTankThrow[3] = GetConVarFloat(hWarpThrow);
	flTankThrow[4] = GetConVarFloat(hMeteorThrow);
	flTankThrow[5] = GetConVarFloat(hAcidThrow);
	flTankThrow[6] = GetConVarFloat(hHealthThrow);
	flTankThrow[7] = GetConVarFloat(hFireThrow);
	flTankThrow[8] = GetConVarFloat(hIceThrow);
	flTankThrow[9] = GetConVarFloat(hJockeyThrow);
	flTankThrow[10] = GetConVarFloat(hHunterThrow);
	flTankThrow[11] = GetConVarFloat(hSmokerThrow);
	flTankThrow[12] = GetConVarFloat(hBoomerThrow);
	flTankThrow[13] = GetConVarFloat(hChargerThrow);
	flTankThrow[14] = GetConVarFloat(hGhostThrow);
	flTankThrow[15] = GetConVarFloat(hShockThrow);
	flTankThrow[16] = GetConVarFloat(hWitchThrow);
	flTankThrow[17] = GetConVarFloat(hShieldThrow);
	flTankThrow[18] = GetConVarFloat(hCobaltThrow);
	flTankThrow[19] = GetConVarFloat(hJumperThrow);
	flTankThrow[20] = GetConVarFloat(hGravityThrow);
	flTankThrow[21] = GetConVarFloat(hFlashThrow);
	flTankThrow[22] = GetConVarFloat(hReverseFlashThrow);
	flTankThrow[23] = GetConVarFloat(hArmageddonThrow);
	flTankThrow[24] = GetConVarFloat(hHallucinationThrow);
	flTankThrow[25] = GetConVarFloat(hMinionThrow);
	flTankThrow[26] = GetConVarFloat(hBitchThrow);
	flTankThrow[27] = GetConVarFloat(hTrapThrow);
	flTankThrow[28] = GetConVarFloat(hDistractionThrow);
	flTankThrow[29] = GetConVarFloat(hFeedbackThrow);
	flTankThrow[30] = GetConVarFloat(hPsychoticThrow);
	flTankThrow[31] = GetConVarFloat(hSpitterThrow);
	flTankThrow[32] = GetConVarFloat(hGoliathThrow);
	flTankThrow[33] = GetConVarFloat(hPsykotikThrow);
	flTankThrow[34] = GetConVarFloat(hSpykotikThrow);
	flTankThrow[35] = GetConVarFloat(hMemeThrow);
	flTankThrow[36] = GetConVarFloat(hBossThrow);
	flTankThrow[37] = GetConVarFloat(hSpypsyThrow);
	flTankThrow[38] = GetConVarFloat(hSipowThrow);
	flTankThrow[39] = GetConVarFloat(hPoltergeistThrow);
	flTankThrow[40] = GetConVarFloat(hMirageThrow);
	bTankFireImmunity[0] = GetConVarBool(hDefaultFireImmunity);
	bTankFireImmunity[1] = GetConVarBool(hSpawnFireImmunity);
	bTankFireImmunity[2] = GetConVarBool(hSmasherFireImmunity);
	bTankFireImmunity[3] = GetConVarBool(hWarpFireImmunity);
	bTankFireImmunity[4] = GetConVarBool(hMeteorFireImmunity);
	bTankFireImmunity[5] = GetConVarBool(hAcidFireImmunity);
	bTankFireImmunity[6] = GetConVarBool(hHealthFireImmunity);
	bTankFireImmunity[7] = GetConVarBool(hFireFireImmunity);
	bTankFireImmunity[8] = GetConVarBool(hIceFireImmunity);
	bTankFireImmunity[9] = GetConVarBool(hJockeyFireImmunity);
	bTankFireImmunity[10] = GetConVarBool(hHunterFireImmunity);
	bTankFireImmunity[11] = GetConVarBool(hSmokerFireImmunity);
	bTankFireImmunity[12] = GetConVarBool(hBoomerFireImmunity);
	bTankFireImmunity[13] = GetConVarBool(hChargerFireImmunity);
	bTankFireImmunity[14] = GetConVarBool(hGhostFireImmunity);
	bTankFireImmunity[15] = GetConVarBool(hShockFireImmunity);
	bTankFireImmunity[16] = GetConVarBool(hWitchFireImmunity);
	bTankFireImmunity[17] = GetConVarBool(hShieldFireImmunity);
	bTankFireImmunity[18] = GetConVarBool(hCobaltFireImmunity);
	bTankFireImmunity[19] = GetConVarBool(hJumperFireImmunity);
	bTankFireImmunity[20] = GetConVarBool(hGravityFireImmunity);
	bTankFireImmunity[21] = GetConVarBool(hFlashFireImmunity);
	bTankFireImmunity[22] = GetConVarBool(hReverseFlashFireImmunity);
	bTankFireImmunity[23] = GetConVarBool(hArmageddonFireImmunity);
	bTankFireImmunity[24] = GetConVarBool(hHallucinationFireImmunity);
	bTankFireImmunity[25] = GetConVarBool(hMinionFireImmunity);
	bTankFireImmunity[26] = GetConVarBool(hBitchFireImmunity);
	bTankFireImmunity[27] = GetConVarBool(hTrapFireImmunity);
	bTankFireImmunity[28] = GetConVarBool(hDistractionFireImmunity);
	bTankFireImmunity[29] = GetConVarBool(hFeedbackFireImmunity);
	bTankFireImmunity[30] = GetConVarBool(hPsychoticFireImmunity);
	bTankFireImmunity[31] = GetConVarBool(hSpitterFireImmunity);
	bTankFireImmunity[32] = GetConVarBool(hGoliathFireImmunity);
	bTankFireImmunity[33] = GetConVarBool(hPsykotikFireImmunity);
	bTankFireImmunity[34] = GetConVarBool(hSpykotikFireImmunity);
	bTankFireImmunity[35] = GetConVarBool(hMemeFireImmunity);
	bTankFireImmunity[36] = GetConVarBool(hBossFireImmunity);
	bTankFireImmunity[37] = GetConVarBool(hSpypsyFireImmunity);
	bTankFireImmunity[38] = GetConVarBool(hSipowFireImmunity);
	bTankFireImmunity[39] = GetConVarBool(hPoltergeistFireImmunity);
	bTankFireImmunity[40] = GetConVarBool(hMirageFireImmunity);
	iSpawnCommonAmount = GetConVarInt(hSpawnCommonAmount);
	iSpawnCommonInterval = GetConVarInt(hSpawnCommonInterval);
	iSmasherMaimDamage = GetConVarInt(hSmasherMaimDamage);
	iSmasherCrushDamage = GetConVarInt(hSmasherCrushDamage);
	bSmasherRemoveBody = GetConVarBool(hSmasherRemoveBody);
	iArmageddonMaimDamage = GetConVarInt(hArmageddonMaimDamage);
	iArmageddonCrushDamage = GetConVarInt(hArmageddonCrushDamage);
	bArmageddonRemoveBody = GetConVarBool(hArmageddonRemoveBody);
	iTrapMaimDamage = GetConVarInt(hTrapMaimDamage);
	iTrapCrushDamage = GetConVarInt(hTrapCrushDamage);
	bTrapRemoveBody = GetConVarBool(hTrapRemoveBody);
	iGoliathMaimDamage = GetConVarInt(hGoliathMaimDamage);
	iGoliathCrushDamage = GetConVarInt(hGoliathCrushDamage);
	bGoliathRemoveBody = GetConVarBool(hGoliathRemoveBody);
	iWarpTeleportDelay = GetConVarInt(hWarpTeleportDelay);
	iPsychoticTeleportDelay = GetConVarInt(hPsychoticTeleportDelay);
	iFeedbackTeleportDelay = GetConVarInt(hFeedbackTeleportDelay);
	iDistractionTeleportDelay = GetConVarInt(hDistractionTeleportDelay);
	iFlashTeleportDelay = GetConVarInt(hFlashTeleportDelay);
	iReverseFlashTeleportDelay = GetConVarInt(hReverseFlashTeleportDelay);
	iHallucinationTeleportDelay = GetConVarInt(hHallucinationTeleportDelay);
	iPsykotikTeleportDelay = GetConVarInt(hPsykotikTeleportDelay);
	iSpykotikTeleportDelay = GetConVarInt(hSpykotikTeleportDelay);
	iSpypsyTeleportDelay = GetConVarInt(hSpypsyTeleportDelay);
	iPoltergeistTeleportDelay = GetConVarInt(hPoltergeistTeleportDelay);
	iMirageTeleportDelay = GetConVarInt(hMirageTeleportDelay);
	iMeteorStormDelay = GetConVarInt(hMeteorStormDelay);
	flMeteorStormDamage = GetConVarFloat(hMeteorStormDamage);
	iPsychoticStormDelay = GetConVarInt(hPsychoticStormDelay);
	flPsychoticStormDamage = GetConVarFloat(hPsychoticStormDamage);
	iArmageddonStormDelay = GetConVarInt(hArmageddonStormDelay);
	flArmageddonStormDamage = GetConVarFloat(hArmageddonStormDamage);
	iSipowStormDelay = GetConVarInt(hSipowStormDelay);
	flSipowStormDamage = GetConVarFloat(hSipowStormDamage);
	iHealthHealthCommons = GetConVarInt(hHealthHealthCommons);
	iHealthHealthSpecials = GetConVarInt(hHealthHealthSpecials);
	iHealthHealthTanks = GetConVarInt(hHealthHealthTanks);
	iPsychoticHealthCommons = GetConVarInt(hPsychoticHealthCommons);
	iPsychoticHealthSpecials = GetConVarInt(hPsychoticHealthSpecials);
	iPsychoticHealthTanks = GetConVarInt(hPsychoticHealthTanks);
	iGoliathHealthCommons = GetConVarInt(hGoliathHealthCommons);
	iGoliathHealthSpecials = GetConVarInt(hGoliathHealthSpecials);
	iGoliathHealthTanks = GetConVarInt(hGoliathHealthTanks);
	iPsykotikHealthCommons = GetConVarInt(hPsykotikHealthCommons);
	iPsykotikHealthSpecials = GetConVarInt(hPsykotikHealthSpecials);
	iPsykotikHealthTanks = GetConVarInt(hPsykotikHealthTanks);
	bGhostDisarm = GetConVarBool(hGhostDisarm);
	bHallucinationDisarm = GetConVarBool(hHallucinationDisarm);
	bPoltergeistDisarm = GetConVarBool(hPoltergeistDisarm);
	iShockStunDamage = GetConVarInt(hShockStunDamage);
	flShockStunMovement = GetConVarFloat(hShockStunMovement);
	iFeedbackStunDamage = GetConVarInt(hFeedbackStunDamage);
	flFeedbackStunMovement = GetConVarFloat(hFeedbackStunMovement);
	iWitchMaxWitches = GetConVarInt(hWitchMaxWitches);
	flShieldShieldsDownInterval = GetConVarFloat(hShieldShieldsDownInterval);
	flCobaltSpecialSpeed = GetConVarFloat(hCobaltSpecialSpeed);
	flFlashSpecialSpeed = GetConVarFloat(hFlashSpecialSpeed);
	flReverseFlashSpecialSpeed = GetConVarFloat(hReverseFlashSpecialSpeed);
	flPsykotikSpecialSpeed = GetConVarFloat(hPsykotikSpecialSpeed);
	flSpykotikSpecialSpeed = GetConVarFloat(hSpykotikSpecialSpeed);
	flSpypsySpecialSpeed = GetConVarFloat(hSpypsySpecialSpeed);
	flPoltergeistSpecialSpeed = GetConVarFloat(hPoltergeistSpecialSpeed);
	flMirageSpecialSpeed = GetConVarFloat(hMirageSpecialSpeed);
	iJumperJumpDelay = GetConVarInt(hJumperJumpDelay);
	iPsychoticJumpDelay = GetConVarInt(hPsychoticJumpDelay);
	iDistractionJumpDelay = GetConVarInt(hDistractionJumpDelay);
	flGravityPullForce = GetConVarFloat(hGravityPullForce);
	flArmageddonPullForce = GetConVarFloat(hArmageddonPullForce);
	flFeedbackPushForce = GetConVarFloat(hFeedbackPushForce);
	iMemeCommonAmount = GetConVarInt(hMemeCommonAmount);
	iMemeCommonInterval = GetConVarInt(hMemeCommonInterval);
	iMemeMaimDamage = GetConVarInt(hMemeMaimDamage);
	iMemeCrushDamage = GetConVarInt(hMemeCrushDamage);
	bMemeRemoveBody = GetConVarBool(hMemeRemoveBody);
	iMemeTeleportDelay = GetConVarInt(hMemeTeleportDelay);
	iMemeStormDelay = GetConVarInt(hMemeStormDelay);
	flMemeStormDamage = GetConVarFloat(hMemeStormDamage);
	bMemeDisarm = GetConVarBool(hMemeDisarm);
	iMemeMaxWitches = GetConVarInt(hMemeMaxWitches);
	flMemeSpecialSpeed = GetConVarFloat(hMemeSpecialSpeed);
	iMemeJumpDelay = GetConVarInt(hMemeJumpDelay);
	flMemePullForce = GetConVarFloat(hMemePullForce);
	iBossMaimDamage = GetConVarInt(hBossMaimDamage);
	iBossCrushDamage = GetConVarInt(hBossCrushDamage);
	bBossRemoveBody = GetConVarBool(hBossRemoveBody);
	iBossTeleportDelay = GetConVarInt(hBossTeleportDelay);
	iBossStormDelay = GetConVarInt(hBossStormDelay);
	flBossStormDamage = GetConVarFloat(hBossStormDamage);
	iBossHealthCommons = GetConVarInt(hBossHealthCommons);
	iBossHealthSpecials = GetConVarInt(hBossHealthSpecials);
	iBossHealthTanks = GetConVarInt(hBossHealthTanks);
	bBossDisarm = GetConVarBool(hBossDisarm);
	iBossMaxWitches = GetConVarInt(hBossMaxWitches);
	flBossSpecialSpeed = GetConVarFloat(hBossSpecialSpeed);
	iBossJumpDelay = GetConVarInt(hBossJumpDelay);
	flBossPullForce = GetConVarFloat(hBossPullForce);
	HookConVarChange(hSuperTanksEnabled, SuperTanksCvarChanged);
	HookConVarChange(hDisplayHealthCvar, SuperTanksSettingsChanged);
	HookConVarChange(hWave1Cvar, SuperTanksSettingsChanged);
	HookConVarChange(hWave2Cvar, SuperTanksSettingsChanged);
	HookConVarChange(hWave3Cvar, SuperTanksSettingsChanged);
	HookConVarChange(hFinaleOnly, SuperTanksSettingsChanged);
	HookConVarChange(hDefaultTanks, SuperTanksSettingsChanged);
	HookConVarChange(hDefaultOverride, DefaultTanksSettingsChanged);
	HookConVarChange(hGamemodeCvar, GamemodeCvarChanged);
	HookConVarChange(hSpawnEnabled, TanksSettingsChanged);
	HookConVarChange(hSmasherEnabled, TanksSettingsChanged);
	HookConVarChange(hWarpEnabled, TanksSettingsChanged);
	HookConVarChange(hMeteorEnabled, TanksSettingsChanged);
	HookConVarChange(hAcidEnabled, TanksSettingsChanged);
	HookConVarChange(hHealthEnabled, TanksSettingsChanged);
	HookConVarChange(hFireEnabled, TanksSettingsChanged);
	HookConVarChange(hIceEnabled, TanksSettingsChanged);
	HookConVarChange(hJockeyEnabled, TanksSettingsChanged);
	HookConVarChange(hHunterEnabled, TanksSettingsChanged);
	HookConVarChange(hSmokerEnabled, TanksSettingsChanged);
	HookConVarChange(hBoomerEnabled, TanksSettingsChanged);
	HookConVarChange(hChargerEnabled, TanksSettingsChanged);
	HookConVarChange(hGhostEnabled, TanksSettingsChanged);
	HookConVarChange(hShockEnabled, TanksSettingsChanged);
	HookConVarChange(hWitchEnabled, TanksSettingsChanged);
	HookConVarChange(hShieldEnabled, TanksSettingsChanged);
	HookConVarChange(hCobaltEnabled, TanksSettingsChanged);
	HookConVarChange(hJumperEnabled, TanksSettingsChanged);
	HookConVarChange(hDistractionEnabled, TanksSettingsChanged);
	HookConVarChange(hGravityEnabled, TanksSettingsChanged);
	HookConVarChange(hFlashEnabled, TanksSettingsChanged);
	HookConVarChange(hReverseFlashEnabled, TanksSettingsChanged);
	HookConVarChange(hArmageddonEnabled, TanksSettingsChanged);
	HookConVarChange(hHallucinationEnabled, TanksSettingsChanged);
	HookConVarChange(hMinionEnabled, TanksSettingsChanged);
	HookConVarChange(hBitchEnabled, TanksSettingsChanged);
	HookConVarChange(hTrapEnabled, TanksSettingsChanged);
	HookConVarChange(hFeedbackEnabled, TanksSettingsChanged);
	HookConVarChange(hPsychoticEnabled, TanksSettingsChanged);
	HookConVarChange(hSpitterEnabled, TanksSettingsChanged);
	HookConVarChange(hGoliathEnabled, TanksSettingsChanged);
	HookConVarChange(hPsykotikEnabled, TanksSettingsChanged);
	HookConVarChange(hSpykotikEnabled, TanksSettingsChanged);
	HookConVarChange(hMemeEnabled, TanksSettingsChanged);
	HookConVarChange(hBossEnabled, TanksSettingsChanged);
	HookConVarChange(hSpypsyEnabled, TanksSettingsChanged);
	HookConVarChange(hSipowEnabled, TanksSettingsChanged);
	HookConVarChange(hPoltergeistEnabled, TanksSettingsChanged);
	HookConVarChange(hMirageEnabled, TanksSettingsChanged);
	HookConVarChange(hDefaultExtraHealth, TanksSettingsChanged);
	HookConVarChange(hSpawnExtraHealth, TanksSettingsChanged);
	HookConVarChange(hSmasherExtraHealth, TanksSettingsChanged);
	HookConVarChange(hWarpExtraHealth, TanksSettingsChanged);
	HookConVarChange(hMeteorExtraHealth, TanksSettingsChanged);
	HookConVarChange(hAcidExtraHealth, TanksSettingsChanged);
	HookConVarChange(hHealthExtraHealth, TanksSettingsChanged);
	HookConVarChange(hFireExtraHealth, TanksSettingsChanged);
	HookConVarChange(hIceExtraHealth, TanksSettingsChanged);
	HookConVarChange(hJockeyExtraHealth, TanksSettingsChanged);
	HookConVarChange(hHunterExtraHealth, TanksSettingsChanged);
	HookConVarChange(hSmokerExtraHealth, TanksSettingsChanged);
	HookConVarChange(hBoomerExtraHealth, TanksSettingsChanged);
	HookConVarChange(hChargerExtraHealth, TanksSettingsChanged);
	HookConVarChange(hGhostExtraHealth, TanksSettingsChanged);
	HookConVarChange(hShockExtraHealth, TanksSettingsChanged);
	HookConVarChange(hWitchExtraHealth, TanksSettingsChanged);
	HookConVarChange(hShieldExtraHealth, TanksSettingsChanged);
	HookConVarChange(hCobaltExtraHealth, TanksSettingsChanged);
	HookConVarChange(hJumperExtraHealth, TanksSettingsChanged);
	HookConVarChange(hDistractionExtraHealth, TanksSettingsChanged);
	HookConVarChange(hGravityExtraHealth, TanksSettingsChanged);
	HookConVarChange(hFlashExtraHealth, TanksSettingsChanged);
	HookConVarChange(hReverseFlashExtraHealth, TanksSettingsChanged);
	HookConVarChange(hArmageddonExtraHealth, TanksSettingsChanged);
	HookConVarChange(hHallucinationExtraHealth, TanksSettingsChanged);
	HookConVarChange(hMinionExtraHealth, TanksSettingsChanged);
	HookConVarChange(hBitchExtraHealth, TanksSettingsChanged);
	HookConVarChange(hTrapExtraHealth, TanksSettingsChanged);
	HookConVarChange(hFeedbackExtraHealth, TanksSettingsChanged);
	HookConVarChange(hPsychoticExtraHealth, TanksSettingsChanged);
	HookConVarChange(hSpitterExtraHealth, TanksSettingsChanged);
	HookConVarChange(hGoliathExtraHealth, TanksSettingsChanged);
	HookConVarChange(hPsykotikExtraHealth, TanksSettingsChanged);
	HookConVarChange(hSpykotikExtraHealth, TanksSettingsChanged);
	HookConVarChange(hMemeExtraHealth, TanksSettingsChanged);
	HookConVarChange(hBossExtraHealth, TanksSettingsChanged);
	HookConVarChange(hSpypsyExtraHealth, TanksSettingsChanged);
	HookConVarChange(hSipowExtraHealth, TanksSettingsChanged);
	HookConVarChange(hPoltergeistExtraHealth, TanksSettingsChanged);
	HookConVarChange(hMirageExtraHealth, TanksSettingsChanged);
	HookConVarChange(hDefaultSpeed, TanksSettingsChanged);
	HookConVarChange(hSpawnSpeed, TanksSettingsChanged);
	HookConVarChange(hSmasherSpeed, TanksSettingsChanged);
	HookConVarChange(hWarpSpeed, TanksSettingsChanged);
	HookConVarChange(hMeteorSpeed, TanksSettingsChanged);
	HookConVarChange(hAcidSpeed, TanksSettingsChanged);
	HookConVarChange(hHealthSpeed, TanksSettingsChanged);
	HookConVarChange(hFireSpeed, TanksSettingsChanged);
	HookConVarChange(hIceSpeed, TanksSettingsChanged);
	HookConVarChange(hJockeySpeed, TanksSettingsChanged);
	HookConVarChange(hHunterSpeed, TanksSettingsChanged);
	HookConVarChange(hSmokerSpeed, TanksSettingsChanged);
	HookConVarChange(hBoomerSpeed, TanksSettingsChanged);
	HookConVarChange(hChargerSpeed, TanksSettingsChanged);
	HookConVarChange(hGhostSpeed, TanksSettingsChanged);
	HookConVarChange(hShockSpeed, TanksSettingsChanged);
	HookConVarChange(hWitchSpeed, TanksSettingsChanged);
	HookConVarChange(hShieldSpeed, TanksSettingsChanged);
	HookConVarChange(hCobaltSpeed, TanksSettingsChanged);
	HookConVarChange(hJumperSpeed, TanksSettingsChanged);
	HookConVarChange(hDistractionSpeed, TanksSettingsChanged);
	HookConVarChange(hGravitySpeed, TanksSettingsChanged);
	HookConVarChange(hFlashSpeed, TanksSettingsChanged);
	HookConVarChange(hReverseFlashSpeed, TanksSettingsChanged);
	HookConVarChange(hArmageddonSpeed, TanksSettingsChanged);
	HookConVarChange(hHallucinationSpeed, TanksSettingsChanged);
	HookConVarChange(hMinionSpeed, TanksSettingsChanged);
	HookConVarChange(hBitchSpeed, TanksSettingsChanged);
	HookConVarChange(hTrapSpeed, TanksSettingsChanged);
	HookConVarChange(hFeedbackSpeed, TanksSettingsChanged);
	HookConVarChange(hPsychoticSpeed, TanksSettingsChanged);
	HookConVarChange(hSpitterSpeed, TanksSettingsChanged);
	HookConVarChange(hGoliathSpeed, TanksSettingsChanged);
	HookConVarChange(hPsykotikSpeed, TanksSettingsChanged);
	HookConVarChange(hSpykotikSpeed, TanksSettingsChanged);
	HookConVarChange(hMemeSpeed, TanksSettingsChanged);
	HookConVarChange(hBossSpeed, TanksSettingsChanged);
	HookConVarChange(hSpypsySpeed, TanksSettingsChanged);
	HookConVarChange(hSipowSpeed, TanksSettingsChanged);
	HookConVarChange(hPoltergeistSpeed, TanksSettingsChanged);
	HookConVarChange(hMirageSpeed, TanksSettingsChanged);
	HookConVarChange(hDefaultThrow, TanksSettingsChanged);
	HookConVarChange(hSpawnThrow, TanksSettingsChanged);
	HookConVarChange(hSmasherThrow, TanksSettingsChanged);
	HookConVarChange(hWarpThrow, TanksSettingsChanged);
	HookConVarChange(hMeteorThrow, TanksSettingsChanged);
	HookConVarChange(hAcidThrow, TanksSettingsChanged);
	HookConVarChange(hHealthThrow, TanksSettingsChanged);
	HookConVarChange(hFireThrow, TanksSettingsChanged);
	HookConVarChange(hIceThrow, TanksSettingsChanged);
	HookConVarChange(hJockeyThrow, TanksSettingsChanged);
	HookConVarChange(hHunterThrow, TanksSettingsChanged);
	HookConVarChange(hSmokerThrow, TanksSettingsChanged);
	HookConVarChange(hBoomerThrow, TanksSettingsChanged);
	HookConVarChange(hChargerThrow, TanksSettingsChanged);
	HookConVarChange(hGhostThrow, TanksSettingsChanged);
	HookConVarChange(hShockThrow, TanksSettingsChanged);
	HookConVarChange(hWitchThrow, TanksSettingsChanged);
	HookConVarChange(hShieldThrow, TanksSettingsChanged);
	HookConVarChange(hCobaltThrow, TanksSettingsChanged);
	HookConVarChange(hJumperThrow, TanksSettingsChanged);
	HookConVarChange(hDistractionThrow, TanksSettingsChanged);
	HookConVarChange(hGravityThrow, TanksSettingsChanged);
	HookConVarChange(hFlashThrow, TanksSettingsChanged);
	HookConVarChange(hReverseFlashThrow, TanksSettingsChanged);
	HookConVarChange(hArmageddonThrow, TanksSettingsChanged);
	HookConVarChange(hHallucinationThrow, TanksSettingsChanged);
	HookConVarChange(hMinionThrow, TanksSettingsChanged);
	HookConVarChange(hBitchThrow, TanksSettingsChanged);
	HookConVarChange(hTrapThrow, TanksSettingsChanged);
	HookConVarChange(hFeedbackThrow, TanksSettingsChanged);
	HookConVarChange(hPsychoticThrow, TanksSettingsChanged);
	HookConVarChange(hSpitterThrow, TanksSettingsChanged);
	HookConVarChange(hGoliathThrow, TanksSettingsChanged);
	HookConVarChange(hPsykotikThrow, TanksSettingsChanged);
	HookConVarChange(hSpykotikThrow, TanksSettingsChanged);
	HookConVarChange(hMemeThrow, TanksSettingsChanged);
	HookConVarChange(hBossThrow, TanksSettingsChanged);
	HookConVarChange(hSpypsyThrow, TanksSettingsChanged);
	HookConVarChange(hSipowThrow, TanksSettingsChanged);
	HookConVarChange(hPoltergeistThrow, TanksSettingsChanged);
	HookConVarChange(hMirageThrow, TanksSettingsChanged);
	HookConVarChange(hDefaultFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSpawnFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSmasherFireImmunity, TanksSettingsChanged);
	HookConVarChange(hWarpFireImmunity, TanksSettingsChanged);
	HookConVarChange(hMeteorFireImmunity, TanksSettingsChanged);
	HookConVarChange(hAcidFireImmunity, TanksSettingsChanged);
	HookConVarChange(hHealthFireImmunity, TanksSettingsChanged);
	HookConVarChange(hFireFireImmunity, TanksSettingsChanged);
	HookConVarChange(hIceFireImmunity, TanksSettingsChanged);
	HookConVarChange(hJockeyFireImmunity, TanksSettingsChanged);
	HookConVarChange(hHunterFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSmokerFireImmunity, TanksSettingsChanged);
	HookConVarChange(hBoomerFireImmunity, TanksSettingsChanged);
	HookConVarChange(hChargerFireImmunity, TanksSettingsChanged);
	HookConVarChange(hGhostFireImmunity, TanksSettingsChanged);
	HookConVarChange(hShockFireImmunity, TanksSettingsChanged);
	HookConVarChange(hWitchFireImmunity, TanksSettingsChanged);
	HookConVarChange(hShieldFireImmunity, TanksSettingsChanged);
	HookConVarChange(hCobaltFireImmunity, TanksSettingsChanged);
	HookConVarChange(hJumperFireImmunity, TanksSettingsChanged);
	HookConVarChange(hDistractionFireImmunity, TanksSettingsChanged);
	HookConVarChange(hGravityFireImmunity, TanksSettingsChanged);
	HookConVarChange(hFlashFireImmunity, TanksSettingsChanged);
	HookConVarChange(hReverseFlashFireImmunity, TanksSettingsChanged);
	HookConVarChange(hArmageddonFireImmunity, TanksSettingsChanged);
	HookConVarChange(hHallucinationFireImmunity, TanksSettingsChanged);
	HookConVarChange(hMinionFireImmunity, TanksSettingsChanged);
	HookConVarChange(hBitchFireImmunity, TanksSettingsChanged);
	HookConVarChange(hTrapFireImmunity, TanksSettingsChanged);
	HookConVarChange(hFeedbackFireImmunity, TanksSettingsChanged);
	HookConVarChange(hPsychoticFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSpitterFireImmunity, TanksSettingsChanged);
	HookConVarChange(hGoliathFireImmunity, TanksSettingsChanged);
	HookConVarChange(hPsykotikFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSpykotikFireImmunity, TanksSettingsChanged);
	HookConVarChange(hMemeFireImmunity, TanksSettingsChanged);
	HookConVarChange(hBossFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSpypsyFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSipowFireImmunity, TanksSettingsChanged);
	HookConVarChange(hPoltergeistFireImmunity, TanksSettingsChanged);
	HookConVarChange(hMirageFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSpawnCommonAmount, TanksSettingsChanged);
	HookConVarChange(hSpawnCommonInterval, TanksSettingsChanged);
	HookConVarChange(hSmasherMaimDamage, TanksSettingsChanged);
	HookConVarChange(hSmasherCrushDamage, TanksSettingsChanged);
	HookConVarChange(hArmageddonMaimDamage, TanksSettingsChanged);
	HookConVarChange(hArmageddonCrushDamage, TanksSettingsChanged);
	HookConVarChange(hTrapMaimDamage, TanksSettingsChanged);
	HookConVarChange(hTrapCrushDamage, TanksSettingsChanged);
	HookConVarChange(hGoliathMaimDamage, TanksSettingsChanged);
	HookConVarChange(hGoliathCrushDamage, TanksSettingsChanged);
	HookConVarChange(hWarpTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hPsychoticTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hFeedbackTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hDistractionTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hFlashTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hReverseFlashTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hHallucinationTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hPsykotikTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hSpykotikTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hSpypsyTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hPoltergeistTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hMirageTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hMeteorStormDelay, TanksSettingsChanged);
	HookConVarChange(hMeteorStormDamage, TanksSettingsChanged);
	HookConVarChange(hPsychoticStormDelay, TanksSettingsChanged);
	HookConVarChange(hPsychoticStormDamage, TanksSettingsChanged);
	HookConVarChange(hArmageddonStormDelay, TanksSettingsChanged);
	HookConVarChange(hArmageddonStormDamage, TanksSettingsChanged);
	HookConVarChange(hSipowStormDelay, TanksSettingsChanged);
	HookConVarChange(hSipowStormDamage, TanksSettingsChanged);
	HookConVarChange(hHealthHealthCommons, TanksSettingsChanged);
	HookConVarChange(hHealthHealthSpecials, TanksSettingsChanged);
	HookConVarChange(hHealthHealthTanks, TanksSettingsChanged);
	HookConVarChange(hPsychoticHealthCommons, TanksSettingsChanged);
	HookConVarChange(hPsychoticHealthSpecials, TanksSettingsChanged);
	HookConVarChange(hPsychoticHealthTanks, TanksSettingsChanged);
	HookConVarChange(hGoliathHealthCommons, TanksSettingsChanged);
	HookConVarChange(hGoliathHealthSpecials, TanksSettingsChanged);
	HookConVarChange(hGoliathHealthTanks, TanksSettingsChanged);
	HookConVarChange(hPsykotikHealthCommons, TanksSettingsChanged);
	HookConVarChange(hPsykotikHealthSpecials, TanksSettingsChanged);
	HookConVarChange(hPsykotikHealthTanks, TanksSettingsChanged);
	HookConVarChange(hGhostDisarm, TanksSettingsChanged);
	HookConVarChange(hHallucinationDisarm, TanksSettingsChanged);
	HookConVarChange(hPoltergeistDisarm, TanksSettingsChanged);
	HookConVarChange(hShockStunDamage, TanksSettingsChanged);
	HookConVarChange(hShockStunMovement, TanksSettingsChanged);
	HookConVarChange(hFeedbackStunDamage, TanksSettingsChanged);
	HookConVarChange(hFeedbackStunMovement, TanksSettingsChanged);
	HookConVarChange(hWitchMaxWitches, TanksSettingsChanged);
	HookConVarChange(hShieldShieldsDownInterval, TanksSettingsChanged);
	HookConVarChange(hCobaltSpecialSpeed, TanksSettingsChanged);
	HookConVarChange(hFlashSpecialSpeed, TanksSettingsChanged);
	HookConVarChange(hReverseFlashSpecialSpeed, TanksSettingsChanged);
	HookConVarChange(hPsykotikSpecialSpeed, TanksSettingsChanged);
	HookConVarChange(hSpykotikSpecialSpeed, TanksSettingsChanged);
	HookConVarChange(hSpypsySpecialSpeed, TanksSettingsChanged);
	HookConVarChange(hPoltergeistSpecialSpeed, TanksSettingsChanged);
	HookConVarChange(hMirageSpecialSpeed, TanksSettingsChanged);
	HookConVarChange(hJumperJumpDelay, TanksSettingsChanged);
	HookConVarChange(hPsychoticJumpDelay, TanksSettingsChanged);
	HookConVarChange(hDistractionJumpDelay, TanksSettingsChanged);
	HookConVarChange(hGravityPullForce, TanksSettingsChanged);
	HookConVarChange(hArmageddonPullForce, TanksSettingsChanged);
	HookConVarChange(hFeedbackPushForce, TanksSettingsChanged);
	HookConVarChange(hMemeCommonAmount, TanksSettingsChanged);
	HookConVarChange(hMemeCommonInterval, TanksSettingsChanged);
	HookConVarChange(hMemeMaimDamage, TanksSettingsChanged);
	HookConVarChange(hMemeCrushDamage, TanksSettingsChanged);
	HookConVarChange(hMemeTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hMemeStormDelay, TanksSettingsChanged);
	HookConVarChange(hMemeStormDamage, TanksSettingsChanged);
	HookConVarChange(hMemeDisarm, TanksSettingsChanged);
	HookConVarChange(hMemeMaxWitches, TanksSettingsChanged);
	HookConVarChange(hMemeSpecialSpeed, TanksSettingsChanged);
	HookConVarChange(hMemeJumpDelay, TanksSettingsChanged);
	HookConVarChange(hMemePullForce, TanksSettingsChanged);
	HookConVarChange(hBossMaimDamage, TanksSettingsChanged);
	HookConVarChange(hBossCrushDamage, TanksSettingsChanged);
	HookConVarChange(hBossTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hBossStormDelay, TanksSettingsChanged);
	HookConVarChange(hBossStormDamage, TanksSettingsChanged);
	HookConVarChange(hBossHealthCommons, TanksSettingsChanged);
	HookConVarChange(hBossHealthSpecials, TanksSettingsChanged);
	HookConVarChange(hBossHealthTanks, TanksSettingsChanged);
	HookConVarChange(hBossDisarm, TanksSettingsChanged);
	HookConVarChange(hBossMaxWitches, TanksSettingsChanged);
	HookConVarChange(hBossSpecialSpeed, TanksSettingsChanged);
	HookConVarChange(hBossJumpDelay, TanksSettingsChanged);
	HookConVarChange(hBossPullForce, TanksSettingsChanged);
	HookEvent("ability_use", Ability_Use, EventHookMode:1);
	HookEvent("finale_escape_start", Finale_Escape_Start, EventHookMode:1);
	HookEvent("finale_start", Finale_Start, EventHookMode:0);
	HookEvent("finale_vehicle_leaving", Finale_Vehicle_Leaving, EventHookMode:1);
	HookEvent("finale_vehicle_ready", Finale_Vehicle_Ready, EventHookMode:1);
	HookEvent("player_death", Player_Death, EventHookMode:1);
	HookEvent("tank_spawn", Tank_Spawn, EventHookMode:1);
	HookEvent("round_end", Round_End, EventHookMode:1);
	HookEvent("round_start", Round_Start, EventHookMode:1);
	HookEvent("round_start", OnRoundStart, EventHookMode:1);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode:1);
	HookEvent("player_spawn", OnInfectedSpawn, EventHookMode:1);
	HookEvent("player_death", OnInfectedDeath, EventHookMode:0);
	CreateTimer(0.1, TimerUpdate01, any:0, 1);
	CreateTimer(1.0, TimerUpdate1, any:0, 1);
	InitStartUp();
	AutoExecConfig(true, "l4d_supertanks", "sourcemod");
	//return void:0;
}

SDKCallSpitBurst(client)
{
	SDKCall(SDKSpitBurst, client, 1);
	return 0;
}

SDKCallVomitOnPlayer(victim, attacker)
{
	SDKCall(SDKVomitOnPlayer, victim, attacker, 1);
	return 0;
}

InitStartUp()
{
	if (bSuperTanksEnabled)
	{
		decl String:gamemode[24];
		GetConVarString(FindConVar("mp_gamemode"), gamemode, 24);
		
		if (!StrEqual(gamemode, "coop", false) && !StrEqual(gamemode, "realism", false) && !StrEqual(gamemode, "survival", false) && !StrEqual(gamemode, "l4d1coop", false) && !StrEqual(gamemode, "l4d2coop", false) && !StrEqual(gamemode, "realismsurvival", false) && !StrEqual(gamemode, "united", false) && !StrEqual(gamemode, "unitedcoop", false) && !StrEqual(gamemode, "unitedrealism", false))
		{
			PrintToServer("[SuperTanks] This plugin is only compatible in Coop, Realism, and Survival gamemodes.");
			PrintToServer("[SuperTanks] Plugin Disabled.");
			SetConVarBool(hSuperTanksEnabled, false, false, false);
		}
	}
	return 0;
}

public GamemodeCvarChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	if (bSuperTanksEnabled)
	{
		if (hGamemodeCvar == convar)
		{
			if (StrEqual(oldValue, newValue, false))
			{
				return 0;
			}
			
			if (!StrEqual(newValue, "coop", false) && !StrEqual(newValue, "realism", false) && !StrEqual(newValue, "survival", false) && !StrEqual(newValue, "l4d1coop", false) && !StrEqual(newValue, "l4d2coop", false) && !StrEqual(newValue, "realismsurvival", false) && !StrEqual(newValue, "united", false) && !StrEqual(newValue, "unitedcoop", false) && !StrEqual(newValue, "unitedrealism", false))
			{
				PrintToServer("[SuperTanks] This plugin is only compatible in Coop, Realism, and Survival gamemodes.");
				PrintToServer("[SuperTanks] Plugin Disabled.");
				SetConVarBool(hSuperTanksEnabled, false, false, false);
			}
		}
	}
	return 0;
}

public SuperTanksCvarChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	if (hSuperTanksEnabled == convar)
	{
		new oldval = StringToInt(oldValue, 10);
		new newval = StringToInt(newValue, 10);
		if (oldval == newval)
		{
			return 0;
		}
		if (newval == 1)
		{
			decl String:gamemode[24];
			GetConVarString(FindConVar("mp_gamemode"), gamemode, 24);
			
			if (!StrEqual(gamemode, "coop", false) && !StrEqual(gamemode, "realism", false) && !StrEqual(gamemode, "survival", false) && !StrEqual(gamemode, "l4d1coop", false) && !StrEqual(gamemode, "l4d2coop", false) && !StrEqual(gamemode, "realismsurvival", false) && !StrEqual(gamemode, "united", false) && !StrEqual(gamemode, "unitedcoop", false) && !StrEqual(gamemode, "unitedrealism", false))
			{
				PrintToServer("[SuperTanks] This plugin is only compatible in Coop, Realism, and Survival gamemodes.");
				PrintToServer("[SuperTanks] Plugin Disabled.");
				SetConVarBool(hSuperTanksEnabled, false, false, false);
			}
		}
		bSuperTanksEnabled = GetConVarBool(hSuperTanksEnabled);
	}
	return 0;
}

public SuperTanksSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	bDisplayHealthCvar = GetConVarBool(hDisplayHealthCvar);
	iWave1Cvar = GetConVarInt(hWave1Cvar);
	iWave2Cvar = GetConVarInt(hWave2Cvar);
	iWave3Cvar = GetConVarInt(hWave3Cvar);
	bFinaleOnly = GetConVarBool(hFinaleOnly);
	bDefaultTanks = GetConVarBool(hDefaultTanks);
	return 0;
}

public DefaultTanksSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	if (hDefaultOverride == convar)
	{
		new oldval = StringToInt(oldValue, 10);
		new newval = StringToInt(newValue, 10);
		if (oldval == newval)
		{
			return 0;
		}
		if (newval)
		{
		}
		else
		{
			SetConVarInt(hDefaultExtraHealth, 0, false, false);
			SetConVarFloat(hDefaultSpeed, 1.0, false, false);
			SetConVarFloat(hDefaultThrow, 5.0, false, false);
			SetConVarBool(hDefaultFireImmunity, false, false, false);
		}
	}
	bDefaultOverride = GetConVarBool(hDefaultOverride);
	return 0;
}

public TanksSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	bTankEnabled[1] = GetConVarBool(hSpawnEnabled);
	bTankEnabled[2] = GetConVarBool(hSmasherEnabled);
	bTankEnabled[3] = GetConVarBool(hWarpEnabled);
	bTankEnabled[4] = GetConVarBool(hMeteorEnabled);
	bTankEnabled[5] = GetConVarBool(hAcidEnabled);
	bTankEnabled[6] = GetConVarBool(hHealthEnabled);
	bTankEnabled[7] = GetConVarBool(hFireEnabled);
	bTankEnabled[8] = GetConVarBool(hIceEnabled);
	bTankEnabled[9] = GetConVarBool(hJockeyEnabled);
	bTankEnabled[10] = GetConVarBool(hHunterEnabled);
	bTankEnabled[11] = GetConVarBool(hSmokerEnabled);
	bTankEnabled[12] = GetConVarBool(hBoomerEnabled);
	bTankEnabled[13] = GetConVarBool(hChargerEnabled);
	bTankEnabled[14] = GetConVarBool(hGhostEnabled);
	bTankEnabled[15] = GetConVarBool(hShockEnabled);
	bTankEnabled[16] = GetConVarBool(hWitchEnabled);
	bTankEnabled[17] = GetConVarBool(hShieldEnabled);
	bTankEnabled[18] = GetConVarBool(hCobaltEnabled);
	bTankEnabled[19] = GetConVarBool(hJumperEnabled);
	bTankEnabled[20] = GetConVarBool(hGravityEnabled);
	bTankEnabled[21] = GetConVarBool(hFlashEnabled);
	bTankEnabled[22] = GetConVarBool(hReverseFlashEnabled);
	bTankEnabled[23] = GetConVarBool(hArmageddonEnabled);
	bTankEnabled[24] = GetConVarBool(hHallucinationEnabled);
	bTankEnabled[25] = GetConVarBool(hMinionEnabled);
	bTankEnabled[26] = GetConVarBool(hBitchEnabled);
	bTankEnabled[27] = GetConVarBool(hTrapEnabled);
	bTankEnabled[28] = GetConVarBool(hDistractionEnabled);
	bTankEnabled[29] = GetConVarBool(hFeedbackEnabled);
	bTankEnabled[30] = GetConVarBool(hPsychoticEnabled);
	bTankEnabled[31] = GetConVarBool(hSpitterEnabled);
	bTankEnabled[32] = GetConVarBool(hGoliathEnabled);
	bTankEnabled[33] = GetConVarBool(hPsykotikEnabled);
	bTankEnabled[34] = GetConVarBool(hSpykotikEnabled);
	bTankEnabled[35] = GetConVarBool(hMemeEnabled);
	bTankEnabled[36] = GetConVarBool(hBossEnabled);
	bTankEnabled[37] = GetConVarBool(hSpypsyEnabled);
	bTankEnabled[38] = GetConVarBool(hSipowEnabled);
	bTankEnabled[39] = GetConVarBool(hPoltergeistEnabled);
	bTankEnabled[40] = GetConVarBool(hMirageEnabled);
	iTankExtraHealth[0] = GetConVarInt(hDefaultExtraHealth);
	iTankExtraHealth[1] = GetConVarInt(hSpawnExtraHealth);
	iTankExtraHealth[2] = GetConVarInt(hSmasherExtraHealth);
	iTankExtraHealth[3] = GetConVarInt(hWarpExtraHealth);
	iTankExtraHealth[4] = GetConVarInt(hMeteorExtraHealth);
	iTankExtraHealth[5] = GetConVarInt(hAcidExtraHealth);
	iTankExtraHealth[6] = GetConVarInt(hHealthExtraHealth);
	iTankExtraHealth[7] = GetConVarInt(hFireExtraHealth);
	iTankExtraHealth[8] = GetConVarInt(hIceExtraHealth);
	iTankExtraHealth[9] = GetConVarInt(hJockeyExtraHealth);
	iTankExtraHealth[10] = GetConVarInt(hHunterExtraHealth);
	iTankExtraHealth[11] = GetConVarInt(hSmokerExtraHealth);
	iTankExtraHealth[12] = GetConVarInt(hBoomerExtraHealth);
	iTankExtraHealth[13] = GetConVarInt(hChargerExtraHealth);
	iTankExtraHealth[14] = GetConVarInt(hGhostExtraHealth);
	iTankExtraHealth[15] = GetConVarInt(hShockExtraHealth);
	iTankExtraHealth[16] = GetConVarInt(hWitchExtraHealth);
	iTankExtraHealth[17] = GetConVarInt(hShieldExtraHealth);
	iTankExtraHealth[18] = GetConVarInt(hCobaltExtraHealth);
	iTankExtraHealth[19] = GetConVarInt(hJumperExtraHealth);
	iTankExtraHealth[20] = GetConVarInt(hGravityExtraHealth);
	iTankExtraHealth[21] = GetConVarInt(hFlashExtraHealth);
	iTankExtraHealth[22] = GetConVarInt(hReverseFlashExtraHealth);
	iTankExtraHealth[23] = GetConVarInt(hArmageddonExtraHealth);
	iTankExtraHealth[24] = GetConVarInt(hHallucinationExtraHealth);
	iTankExtraHealth[25] = GetConVarInt(hMinionExtraHealth);
	iTankExtraHealth[26] = GetConVarInt(hBitchExtraHealth);
	iTankExtraHealth[27] = GetConVarInt(hTrapExtraHealth);
	iTankExtraHealth[28] = GetConVarInt(hDistractionExtraHealth);
	iTankExtraHealth[29] = GetConVarInt(hFeedbackExtraHealth);
	iTankExtraHealth[30] = GetConVarInt(hPsychoticExtraHealth);
	iTankExtraHealth[31] = GetConVarInt(hSpitterExtraHealth);
	iTankExtraHealth[32] = GetConVarInt(hGoliathExtraHealth);
	iTankExtraHealth[33] = GetConVarInt(hPsykotikExtraHealth);
	iTankExtraHealth[34] = GetConVarInt(hSpykotikExtraHealth);
	iTankExtraHealth[35] = GetConVarInt(hMemeExtraHealth);
	iTankExtraHealth[36] = GetConVarInt(hBossExtraHealth);
	iTankExtraHealth[37] = GetConVarInt(hSpypsyExtraHealth);
	iTankExtraHealth[38] = GetConVarInt(hSipowExtraHealth);
	iTankExtraHealth[39] = GetConVarInt(hPoltergeistExtraHealth);
	iTankExtraHealth[40] = GetConVarInt(hMirageExtraHealth);
	flTankSpeed[0] = GetConVarFloat(hDefaultSpeed);
	flTankSpeed[1] = GetConVarFloat(hSpawnSpeed);
	flTankSpeed[2] = GetConVarFloat(hSmasherSpeed);
	flTankSpeed[3] = GetConVarFloat(hWarpSpeed);
	flTankSpeed[4] = GetConVarFloat(hMeteorSpeed);
	flTankSpeed[5] = GetConVarFloat(hAcidSpeed);
	flTankSpeed[6] = GetConVarFloat(hHealthSpeed);
	flTankSpeed[7] = GetConVarFloat(hFireSpeed);
	flTankSpeed[8] = GetConVarFloat(hIceSpeed);
	flTankSpeed[9] = GetConVarFloat(hJockeySpeed);
	flTankSpeed[10] = GetConVarFloat(hHunterSpeed);
	flTankSpeed[11] = GetConVarFloat(hSmokerSpeed);
	flTankSpeed[12] = GetConVarFloat(hBoomerSpeed);
	flTankSpeed[13] = GetConVarFloat(hChargerSpeed);
	flTankSpeed[14] = GetConVarFloat(hGhostSpeed);
	flTankSpeed[15] = GetConVarFloat(hShockSpeed);
	flTankSpeed[16] = GetConVarFloat(hWitchSpeed);
	flTankSpeed[17] = GetConVarFloat(hShieldSpeed);
	flTankSpeed[18] = GetConVarFloat(hCobaltSpeed);
	flTankSpeed[19] = GetConVarFloat(hJumperSpeed);
	flTankSpeed[20] = GetConVarFloat(hGravitySpeed);
	flTankSpeed[21] = GetConVarFloat(hFlashSpeed);
	flTankSpeed[22] = GetConVarFloat(hReverseFlashSpeed);
	flTankSpeed[23] = GetConVarFloat(hArmageddonSpeed);
	flTankSpeed[24] = GetConVarFloat(hHallucinationSpeed);
	flTankSpeed[25] = GetConVarFloat(hMinionSpeed);
	flTankSpeed[26] = GetConVarFloat(hBitchSpeed);
	flTankSpeed[27] = GetConVarFloat(hTrapSpeed);
	flTankSpeed[28] = GetConVarFloat(hDistractionSpeed);
	flTankSpeed[29] = GetConVarFloat(hFeedbackSpeed);
	flTankSpeed[30] = GetConVarFloat(hPsychoticSpeed);
	flTankSpeed[31] = GetConVarFloat(hSpitterSpeed);
	flTankSpeed[32] = GetConVarFloat(hGoliathSpeed);
	flTankSpeed[33] = GetConVarFloat(hPsykotikSpeed);
	flTankSpeed[34] = GetConVarFloat(hSpykotikSpeed);
	flTankSpeed[35] = GetConVarFloat(hMemeSpeed);
	flTankSpeed[36] = GetConVarFloat(hBossSpeed);
	flTankSpeed[37] = GetConVarFloat(hSpypsySpeed);
	flTankSpeed[38] = GetConVarFloat(hSipowSpeed);
	flTankSpeed[39] = GetConVarFloat(hPoltergeistSpeed);
	flTankSpeed[40] = GetConVarFloat(hMirageSpeed);
	flTankThrow[0] = GetConVarFloat(hDefaultThrow);
	flTankThrow[1] = GetConVarFloat(hSpawnThrow);
	flTankThrow[2] = GetConVarFloat(hSmasherThrow);
	flTankThrow[3] = GetConVarFloat(hWarpThrow);
	flTankThrow[4] = GetConVarFloat(hMeteorThrow);
	flTankThrow[5] = GetConVarFloat(hAcidThrow);
	flTankThrow[6] = GetConVarFloat(hHealthThrow);
	flTankThrow[7] = GetConVarFloat(hFireThrow);
	flTankThrow[8] = GetConVarFloat(hIceThrow);
	flTankThrow[9] = GetConVarFloat(hJockeyThrow);
	flTankThrow[10] = GetConVarFloat(hHunterThrow);
	flTankThrow[11] = GetConVarFloat(hSmokerThrow);
	flTankThrow[12] = GetConVarFloat(hBoomerThrow);
	flTankThrow[13] = GetConVarFloat(hChargerThrow);
	flTankThrow[14] = GetConVarFloat(hGhostThrow);
	flTankThrow[15] = GetConVarFloat(hShockThrow);
	flTankThrow[16] = GetConVarFloat(hWitchThrow);
	flTankThrow[17] = GetConVarFloat(hShieldThrow);
	flTankThrow[18] = GetConVarFloat(hCobaltThrow);
	flTankThrow[19] = GetConVarFloat(hJumperThrow);
	flTankThrow[20] = GetConVarFloat(hGravityThrow);
	flTankThrow[21] = GetConVarFloat(hFlashThrow);
	flTankThrow[22] = GetConVarFloat(hReverseFlashThrow);
	flTankThrow[23] = GetConVarFloat(hArmageddonThrow);
	flTankThrow[24] = GetConVarFloat(hHallucinationThrow);
	flTankThrow[25] = GetConVarFloat(hMinionThrow);
	flTankThrow[26] = GetConVarFloat(hBitchThrow);
	flTankThrow[27] = GetConVarFloat(hTrapThrow);
	flTankThrow[28] = GetConVarFloat(hDistractionThrow);
	flTankThrow[29] = GetConVarFloat(hFeedbackThrow);
	flTankThrow[30] = GetConVarFloat(hPsychoticThrow);
	flTankThrow[31] = GetConVarFloat(hSpitterThrow);
	flTankThrow[32] = GetConVarFloat(hGoliathThrow);
	flTankThrow[33] = GetConVarFloat(hPsykotikThrow);
	flTankThrow[34] = GetConVarFloat(hSpykotikThrow);
	flTankThrow[35] = GetConVarFloat(hMemeThrow);
	flTankThrow[36] = GetConVarFloat(hBossThrow);
	flTankThrow[37] = GetConVarFloat(hSpypsyThrow);
	flTankThrow[38] = GetConVarFloat(hSipowThrow);
	flTankThrow[39] = GetConVarFloat(hPoltergeistThrow);
	flTankThrow[40] = GetConVarFloat(hMirageThrow);
	bTankFireImmunity[0] = GetConVarBool(hDefaultFireImmunity);
	bTankFireImmunity[1] = GetConVarBool(hSpawnFireImmunity);
	bTankFireImmunity[2] = GetConVarBool(hSmasherFireImmunity);
	bTankFireImmunity[3] = GetConVarBool(hWarpFireImmunity);
	bTankFireImmunity[4] = GetConVarBool(hMeteorFireImmunity);
	bTankFireImmunity[5] = GetConVarBool(hAcidFireImmunity);
	bTankFireImmunity[6] = GetConVarBool(hHealthFireImmunity);
	bTankFireImmunity[7] = GetConVarBool(hFireFireImmunity);
	bTankFireImmunity[8] = GetConVarBool(hIceFireImmunity);
	bTankFireImmunity[9] = GetConVarBool(hJockeyFireImmunity);
	bTankFireImmunity[10] = GetConVarBool(hHunterFireImmunity);
	bTankFireImmunity[11] = GetConVarBool(hSmokerFireImmunity);
	bTankFireImmunity[12] = GetConVarBool(hBoomerFireImmunity);
	bTankFireImmunity[13] = GetConVarBool(hChargerFireImmunity);
	bTankFireImmunity[14] = GetConVarBool(hGhostFireImmunity);
	bTankFireImmunity[15] = GetConVarBool(hShockFireImmunity);
	bTankFireImmunity[16] = GetConVarBool(hWitchFireImmunity);
	bTankFireImmunity[17] = GetConVarBool(hShieldFireImmunity);
	bTankFireImmunity[18] = GetConVarBool(hCobaltFireImmunity);
	bTankFireImmunity[19] = GetConVarBool(hJumperFireImmunity);
	bTankFireImmunity[20] = GetConVarBool(hGravityFireImmunity);
	bTankFireImmunity[21] = GetConVarBool(hFlashFireImmunity);
	bTankFireImmunity[22] = GetConVarBool(hReverseFlashFireImmunity);
	bTankFireImmunity[23] = GetConVarBool(hArmageddonFireImmunity);
	bTankFireImmunity[24] = GetConVarBool(hHallucinationFireImmunity);
	bTankFireImmunity[25] = GetConVarBool(hMinionFireImmunity);
	bTankFireImmunity[26] = GetConVarBool(hBitchFireImmunity);
	bTankFireImmunity[27] = GetConVarBool(hTrapFireImmunity);
	bTankFireImmunity[28] = GetConVarBool(hDistractionFireImmunity);
	bTankFireImmunity[29] = GetConVarBool(hFeedbackFireImmunity);
	bTankFireImmunity[30] = GetConVarBool(hPsychoticFireImmunity);
	bTankFireImmunity[31] = GetConVarBool(hSpitterFireImmunity);
	bTankFireImmunity[32] = GetConVarBool(hGoliathFireImmunity);
	bTankFireImmunity[33] = GetConVarBool(hPsykotikFireImmunity);
	bTankFireImmunity[34] = GetConVarBool(hSpykotikFireImmunity);
	bTankFireImmunity[35] = GetConVarBool(hMemeFireImmunity);
	bTankFireImmunity[36] = GetConVarBool(hBossFireImmunity);
	bTankFireImmunity[37] = GetConVarBool(hSpypsyFireImmunity);
	bTankFireImmunity[38] = GetConVarBool(hSipowFireImmunity);
	bTankFireImmunity[39] = GetConVarBool(hPoltergeistFireImmunity);
	bTankFireImmunity[40] = GetConVarBool(hMirageFireImmunity);
	iSpawnCommonAmount = GetConVarInt(hSpawnCommonAmount);
	iSpawnCommonInterval = GetConVarInt(hSpawnCommonInterval);
	iSmasherMaimDamage = GetConVarInt(hSmasherMaimDamage);
	iSmasherCrushDamage = GetConVarInt(hSmasherCrushDamage);
	bSmasherRemoveBody = GetConVarBool(hSmasherRemoveBody);
	iArmageddonMaimDamage = GetConVarInt(hArmageddonMaimDamage);
	iArmageddonCrushDamage = GetConVarInt(hArmageddonCrushDamage);
	bArmageddonRemoveBody = GetConVarBool(hArmageddonRemoveBody);
	iTrapMaimDamage = GetConVarInt(hTrapMaimDamage);
	iTrapCrushDamage = GetConVarInt(hTrapCrushDamage);
	bTrapRemoveBody = GetConVarBool(hTrapRemoveBody);
	iGoliathMaimDamage = GetConVarInt(hGoliathMaimDamage);
	iGoliathCrushDamage = GetConVarInt(hGoliathCrushDamage);
	bGoliathRemoveBody = GetConVarBool(hGoliathRemoveBody);
	iWarpTeleportDelay = GetConVarInt(hWarpTeleportDelay);
	iPsychoticTeleportDelay = GetConVarInt(hPsychoticTeleportDelay);
	iFeedbackTeleportDelay = GetConVarInt(hFeedbackTeleportDelay);
	iDistractionTeleportDelay = GetConVarInt(hDistractionTeleportDelay);
	iFlashTeleportDelay = GetConVarInt(hFlashTeleportDelay);
	iReverseFlashTeleportDelay = GetConVarInt(hReverseFlashTeleportDelay);
	iHallucinationTeleportDelay = GetConVarInt(hHallucinationTeleportDelay);
	iPsykotikTeleportDelay = GetConVarInt(hPsykotikTeleportDelay);
	iSpykotikTeleportDelay = GetConVarInt(hSpykotikTeleportDelay);
	iSpypsyTeleportDelay = GetConVarInt(hSpypsyTeleportDelay);
	iPoltergeistTeleportDelay = GetConVarInt(hPoltergeistTeleportDelay);
	iMirageTeleportDelay = GetConVarInt(hMirageTeleportDelay);
	iMeteorStormDelay = GetConVarInt(hMeteorStormDelay);
	flMeteorStormDamage = GetConVarFloat(hMeteorStormDamage);
	iPsychoticStormDelay = GetConVarInt(hPsychoticStormDelay);
	flPsychoticStormDamage = GetConVarFloat(hPsychoticStormDamage);
	iArmageddonStormDelay = GetConVarInt(hArmageddonStormDelay);
	flArmageddonStormDamage = GetConVarFloat(hArmageddonStormDamage);
	iSipowStormDelay = GetConVarInt(hSipowStormDelay);
	flSipowStormDamage = GetConVarFloat(hSipowStormDamage);
	iHealthHealthCommons = GetConVarInt(hHealthHealthCommons);
	iHealthHealthSpecials = GetConVarInt(hHealthHealthSpecials);
	iHealthHealthTanks = GetConVarInt(hHealthHealthTanks);
	iPsychoticHealthCommons = GetConVarInt(hPsychoticHealthCommons);
	iPsychoticHealthSpecials = GetConVarInt(hPsychoticHealthSpecials);
	iPsychoticHealthTanks = GetConVarInt(hPsychoticHealthTanks);
	iGoliathHealthCommons = GetConVarInt(hGoliathHealthCommons);
	iGoliathHealthSpecials = GetConVarInt(hGoliathHealthSpecials);
	iGoliathHealthTanks = GetConVarInt(hGoliathHealthTanks);
	iPsykotikHealthCommons = GetConVarInt(hPsykotikHealthCommons);
	iPsykotikHealthSpecials = GetConVarInt(hPsykotikHealthSpecials);
	iPsykotikHealthTanks = GetConVarInt(hPsykotikHealthTanks);
	bGhostDisarm = GetConVarBool(hGhostDisarm);
	bHallucinationDisarm = GetConVarBool(hHallucinationDisarm);
	bPoltergeistDisarm = GetConVarBool(hPoltergeistDisarm);
	iShockStunDamage = GetConVarInt(hShockStunDamage);
	flShockStunMovement = GetConVarFloat(hShockStunMovement);
	iFeedbackStunDamage = GetConVarInt(hFeedbackStunDamage);
	flFeedbackStunMovement = GetConVarFloat(hFeedbackStunMovement);
	iWitchMaxWitches = GetConVarInt(hWitchMaxWitches);
	flShieldShieldsDownInterval = GetConVarFloat(hShieldShieldsDownInterval);
	flCobaltSpecialSpeed = GetConVarFloat(hCobaltSpecialSpeed);
	flFlashSpecialSpeed = GetConVarFloat(hFlashSpecialSpeed);
	flReverseFlashSpecialSpeed = GetConVarFloat(hReverseFlashSpecialSpeed);
	flPsykotikSpecialSpeed = GetConVarFloat(hPsykotikSpecialSpeed);
	flSpykotikSpecialSpeed = GetConVarFloat(hSpykotikSpecialSpeed);
	flSpypsySpecialSpeed = GetConVarFloat(hSpypsySpecialSpeed);
	flPoltergeistSpecialSpeed = GetConVarFloat(hPoltergeistSpecialSpeed);
	flMirageSpecialSpeed = GetConVarFloat(hMirageSpecialSpeed);
	iJumperJumpDelay = GetConVarInt(hJumperJumpDelay);
	iPsychoticJumpDelay = GetConVarInt(hPsychoticJumpDelay);
	iDistractionJumpDelay = GetConVarInt(hDistractionJumpDelay);
	flGravityPullForce = GetConVarFloat(hGravityPullForce);
	flArmageddonPullForce = GetConVarFloat(hArmageddonPullForce);
	flFeedbackPushForce = GetConVarFloat(hFeedbackPushForce);
	iMemeCommonAmount = GetConVarInt(hMemeCommonAmount);
	iMemeCommonInterval = GetConVarInt(hMemeCommonInterval);
	iMemeMaimDamage = GetConVarInt(hMemeMaimDamage);
	iMemeCrushDamage = GetConVarInt(hMemeCrushDamage);
	bMemeRemoveBody = GetConVarBool(hMemeRemoveBody);
	iMemeTeleportDelay = GetConVarInt(hMemeTeleportDelay);
	iMemeStormDelay = GetConVarInt(hMemeStormDelay);
	flMemeStormDamage = GetConVarFloat(hMemeStormDamage);
	bMemeDisarm = GetConVarBool(hMemeDisarm);
	iMemeMaxWitches = GetConVarInt(hMemeMaxWitches);
	flMemeSpecialSpeed = GetConVarFloat(hMemeSpecialSpeed);
	iMemeJumpDelay = GetConVarInt(hMemeJumpDelay);
	flMemePullForce = GetConVarFloat(hMemePullForce);
	iBossMaimDamage = GetConVarInt(hBossMaimDamage);
	iBossCrushDamage = GetConVarInt(hBossCrushDamage);
	bBossRemoveBody = GetConVarBool(hBossRemoveBody);
	iBossTeleportDelay = GetConVarInt(hBossTeleportDelay);
	iBossStormDelay = GetConVarInt(hBossStormDelay);
	flBossStormDamage = GetConVarFloat(hBossStormDamage);
	iBossHealthCommons = GetConVarInt(hBossHealthCommons);
	iBossHealthSpecials = GetConVarInt(hBossHealthSpecials);
	iBossHealthTanks = GetConVarInt(hBossHealthTanks);
	bBossDisarm = GetConVarBool(hBossDisarm);
	iBossMaxWitches = GetConVarInt(hBossMaxWitches);
	flBossSpecialSpeed = GetConVarFloat(hBossSpecialSpeed);
	iBossJumpDelay = GetConVarInt(hBossJumpDelay);
	flBossPullForce = GetConVarFloat(hBossPullForce);
	return 0;
}

public void OnMapStart()
{
	PrecacheParticle("smoker_smokecloud");
	PrecacheParticle("aircraft_destroy_fastFireTrail");
	PrecacheParticle("electrical_arc_01_system");
	PrecacheParticle("steam_manhole");
	PrecacheParticle("spitter_areaofdenial_glow2");
	PrecacheParticle("spitter_projectile");
	PrecacheParticle("electrical_arc_01_parent");
	PrecacheParticle("boomer_explode_D");
	PrecacheParticle("boomer_explode");
	PrecacheParticle("smoke_medium_01");
	CheckModelPreCache("models/props_junk/gascan001a.mdl");
	CheckModelPreCache("models/props_junk/propanecanister001a.mdl");
	CheckModelPreCache("models/infected/witch.mdl");
	CheckModelPreCache("models/infected/witch_bride.mdl");
	CheckModelPreCache("models/props_vehicles/tire001c_car.mdl");
	CheckModelPreCache("models/props_unique/airport/atlas_break_ball.mdl");
	CheckSoundPreCache("ambient/fire/gascan_ignite1.wav");
	CheckSoundPreCache("player/charger/hit/charger_smash_02.wav");
	CheckSoundPreCache("npc/infected/action/die/male/death_42.wav");
	CheckSoundPreCache("npc/infected/action/die/male/death_43.wav");
	CheckSoundPreCache("ambient/energy/zap1.wav");
	CheckSoundPreCache("ambient/energy/zap5.wav");
	CheckSoundPreCache("ambient/energy/zap7.wav");
	CheckSoundPreCache("player/spitter/voice/warn/spitter_spit_02.wav");
	CheckSoundPreCache("player/tank/voice/growl/tank_climb_01.wav");
	CheckSoundPreCache("player/tank/voice/growl/tank_climb_02.wav");
	CheckSoundPreCache("player/tank/voice/growl/tank_climb_03.wav");
	CheckSoundPreCache("player/tank/voice/growl/tank_climb_04.wav");
	//return void:0;
}

CheckModelPreCache(String:Modelfile[])
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile, true);
		PrintToServer("[Super Tanks]Precaching Model:%s", Modelfile);
	}
	return 0;
}

CheckSoundPreCache(String:Soundfile[])
{
	PrecacheSound(Soundfile, true);
	PrintToServer("[Super Tanks]Precaching Sound:%s", Soundfile);
	return 0;
}

public void OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHookType:2, OnPlayerTakeDamage);
	TankAbility[client] = 0;
	Rock[client] = 0;
	ShieldsUp[client] = 0;
	PlayerSpeed[client] = 0;
	//return void:0;
}

public Action:Ability_Use(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (bSuperTanksEnabled)
	{
		if (0 < client)
		{
			if (IsClientInGame(client))
			{
				if (IsTank(client))
				{
					new index = GetSuperTankByRenderColor(GetEntityRenderColor(client));
					
					if (index >= 0 && index <= 40)
					{
						//
						if (index || (index && bDefaultOverride))
						{
							ResetInfectedAbility(client, flTankThrow[index]);
						}
					}
				}
			}
		}
	}
	return Action:0;
}

public Action:Finale_Escape_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iTankWave = 3;
	return Action:0;
}

public Action:Finale_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iTankWave = 1;
	return Action:0;
}

public Action:Finale_Vehicle_Leaving(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iTankWave = 4;
	return Action:0;
}

public Action:Finale_Vehicle_Ready(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iTankWave = 3;
	return Action:0;
}

public Action:Player_Death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (bSuperTanksEnabled)
	{
		//
		if (client > 0 && IsClientInGame(client))
		{
			SetEntityGravity(client, 1.0);
			if (IsTank(client))
			{
				ExecTankDeath(client);
			}
			if (GetClientTeam(client) == 2)
			{
				new entity = -1;
				while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != -1)
				{
					new Float:Origin[3] = 0.0;
					new Float:EOrigin[3] = 0.0;
					GetClientAbsOrigin(client, Origin);
					GetEntPropVector(entity, PropType:0, "m_vecOrigin", EOrigin, 0);
					//
					if (Origin[0] == EOrigin[0] && Origin[1] == EOrigin[1] && Origin[2] == EOrigin[2])
					{
						SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
					}
				}
			}
		}
	}
	return Action:0;
}

public Action:Round_End(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (bSuperTanksEnabled)
	{
		new i = 1;
		while (i <= MaxClients)
		{
			//
			if (IsClientInGame(i) && IsPlayerAlive(i) && IsFakeClient(i) && GetClientTeam(i) == 3 && !IsTank(i))
			{
				if (CountInfectedAll() > 40)
				{
					KickClient(i, "");
				}
			}
			i++;
		}
	}
	return Action:0;
}

public Action:Round_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (bSuperTanksEnabled)
	{
		iTick = 0;
		iTankWave = 0;
		iNumTanks = 0;
		new flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
		SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBounds:0, false, 0.0);
		SetConVarFlags(FindConVar("z_max_player_zombies"), flags & -257);
		new client = 1;
		while (client <= MaxClients)
		{
			TankAbility[client] = 0;
			Rock[client] = 0;
			ShieldsUp[client] = 0;
			PlayerSpeed[client] = 0;
			client++;
		}
	}
	return Action:0;
}

public Action:Tank_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	CountTanks();
	if (bSuperTanksEnabled)
	{
		//
		if (client > 0 && IsClientInGame(client))
		{
			TankAlive[client] = 1;
			TankAbility[client] = 0;
			CreateTimer(0.1, TankSpawnTimer, client, 2);
			//
			if (!bFinaleOnly || (bFinaleOnly && iTankWave > 0))
			{
				RandomizeTank(client);
				switch (iTankWave)
				{
					case 1:
					{
						if (iNumTanks < iWave1Cvar)
						{
							CreateTimer(5.0, SpawnTankTimer, any:0, 2);
						}
						else
						{
							if (iNumTanks > iWave1Cvar)
							{
								if (IsFakeClient(client))
								{
									KickClient(client, "");
								}
							}
						}
					}
					case 2:
					{
						if (iNumTanks < iWave2Cvar)
						{
							CreateTimer(5.0, SpawnTankTimer, any:0, 2);
						}
						else
						{
							if (iNumTanks > iWave2Cvar)
							{
								if (IsFakeClient(client))
								{
									KickClient(client, "");
								}
							}
						}
					}
					case 3:
					{
						if (iNumTanks < iWave3Cvar)
						{
							CreateTimer(5.0, SpawnTankTimer, any:0, 2);
						}
						else
						{
							if (iNumTanks > iWave3Cvar)
							{
								if (IsFakeClient(client))
								{
									KickClient(client, "");
								}
							}
						}
					}
					default:
					{
					}
				}
			}
		}
	}
	return Action:0;
}

public TankController()
{
	CountTanks();
	if (0 < iNumTanks)
	{
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsTank(i))
			{
				new index = GetSuperTankByRenderColor(GetEntityRenderColor(i));
				//
				if (index >= 0 && index <= 40)
				{
					//
					if (index || (index && bDefaultOverride))
					{
						SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", flTankSpeed[index], 0);
						switch (index)
						{
							case 1:
							{
								iTick = iTick + 1;
								if (iTick >= iSpawnCommonInterval)
								{
									new count = 1;
									while (count <= iSpawnCommonAmount)
									{
										CheatCommand(i, "z_spawn", "zombie area");
										count++;
									}
									iTick = 0;
								}
							}
							case 3:
							{
								TeleportTank(i);
							}
							case 4:
							{
								if (TankAbility[i])
								{
								}
								else
								{
									new random = GetRandomInt(1, iMeteorStormDelay);
									if (random == 1)
									{
										StartMeteorFall(i);
									}
								}
							}
							case 6:
							{
								HealthTank(i);
							}
							case 7:
							{
								IgniteEntity(i, 1.0, false, 0.0, false);
							}
							case 14:
							{
								InfectedCloak(i);
								if (CountSurvivorsAliveAll() == CountSurvRange(i))
								{
									SetEntityRenderMode(i, RenderMode:3);
									SetEntityRenderColor(i, 100, 100, 100, 50);
									EmitSoundToAll("npc/infected/action/die/male/death_43.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
								else
								{
									SetEntityRenderMode(i, RenderMode:3);
									SetEntityRenderColor(i, 100, 100, 100, 150);
									EmitSoundToAll("npc/infected/action/die/male/death_42.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
							}
							case 16:
							{
								SpawnWitch(i);
							}
							case 17:
							{
								if (0 < ShieldsUp[i])
								{
								}
							}
							case 18:
							{
								if (TankAbility[i])
								{
									if (TankAbility[i] == 1)
									{
										SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", flCobaltSpecialSpeed, 0);
									}
								}
								else
								{
									SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", 1.0, 0);
									new random = GetRandomInt(1, 9);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect, i, 3);
									}
								}
							}
							case 20:
							{
								SetEntityGravity(i, 0.5);
							}
							case 21:
							{
								TeleportTank2(i);
								if (TankAbility[i])
								{
									if (TankAbility[i] == 1)
									{
										SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", flFlashSpecialSpeed, 0);
									}
								}
								else
								{
									SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", 1.0, 0);
									new random = GetRandomInt(1, 9);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect2, i, 3);
									}
								}
							}
							case 22:
							{
								TeleportTank3(i);
								if (TankAbility[i])
								{
									if (TankAbility[i] == 1)
									{
										SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", flReverseFlashSpecialSpeed, 0);
									}
								}
								else
								{
									SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", 1.0, 0);
									new random = GetRandomInt(1, 9);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect3, i, 3);
									}
								}
							}
							case 23:
							{
								SetEntityGravity(i, 0.5);
								if (TankAbility[i])
								{
								}
								else
								{
									new random = GetRandomInt(1, iArmageddonStormDelay);
									if (random == 1)
									{
										StartArmageddonFall(i);
									}
								}
							}
							case 24:
							{
								TeleportTank4(i);
								InfectedCloak2(i);
								if (CountSurvivorsAliveAll() == CountSurvRange(i))
								{
									SetEntityRenderMode(i, RenderMode:3);
									SetEntityRenderColor(i, 50, 50, 50, 50);
									EmitSoundToAll("npc/infected/action/die/male/death_43.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
								else
								{
									SetEntityRenderMode(i, RenderMode:3);
									SetEntityRenderColor(i, 50, 50, 50, 150);
									EmitSoundToAll("npc/infected/action/die/male/death_42.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
							}
							case 26:
							{
								SetEntityGravity(i, 0.5);
							}
							case 28:
							{
								TeleportTank5(i);
							}
							case 29:
							{
								TeleportTank6(i);
								SetEntityGravity(i, 0.5);
							}
							case 30:
							{
								TeleportTank7(i);
								PsychoticTank(i);
								if (TankAbility[i])
								{
								}
								else
								{
									new random = GetRandomInt(1, iPsychoticStormDelay);
									if (random == 1)
									{
										StartPsychoticFall(i);
									}
								}
							}
							case 32:
							{
								GoliathTank(i);
							}
							case 33:
							{
								PsykotikTank(i);
								TeleportTank8(i);
								if (TankAbility[i])
								{
									if (TankAbility[i] == 1)
									{
										SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", flPsykotikSpecialSpeed, 0);
									}
								}
								else
								{
									SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", 1.0, 0);
									new random = GetRandomInt(1, 9);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect4, i, 3);
									}
								}
							}
							case 34:
							{
								TeleportTank9(i);
								if (TankAbility[i])
								{
									if (TankAbility[i] == 1)
									{
										SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", flSpykotikSpecialSpeed, 0);
									}
								}
								else
								{
									SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", 1.0, 0);
									new random = GetRandomInt(1, 9);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect5, i, 3);
									}
								}
							}
							case 35:
							{
								TeleportTank10(i);
								SpawnWitch2(i);
								IgniteEntity(i, 1.0, false, 0.0, false);
								SetEntityGravity(i, 0.5);
								iTick = iTick + 1;
								if (iTick >= iMemeCommonInterval)
								{
									new count = 1;
									while (count <= iMemeCommonAmount)
									{
										CheatCommand(i, "z_spawn", "zombie area");
										count++;
									}
									iTick = 0;
								}
								if (TankAbility[i])
								{
									if (TankAbility[i] == 1)
									{
										SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", flMemeSpecialSpeed, 0);
									}
								}
								else
								{
									SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", 1.0, 0);
									new random = GetRandomInt(1, 9);
									new random2 = GetRandomInt(1, iMemeStormDelay);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect6, i, 3);
									}
									if (random2 == 1)
									{
										StartMemeFall(i);
									}
								}
								InfectedCloak3(i);
								if (CountSurvivorsAliveAll() == CountSurvRange(i))
								{
									SetEntityRenderMode(i, RenderMode:3);
									SetEntityRenderColor(i, 0, 255, 0, 50);
									EmitSoundToAll("npc/infected/action/die/male/death_43.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
								else
								{
									SetEntityRenderMode(i, RenderMode:3);
									SetEntityRenderColor(i, 0, 255, 0, 150);
									EmitSoundToAll("npc/infected/action/die/male/death_42.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
							}
							case 36:
							{
								TeleportTank11(i);
								BossTank(i);
								SpawnWitch3(i);
								IgniteEntity(i, 1.0, false, 0.0, false);
								SetEntityGravity(i, 0.5);
								if (TankAbility[i])
								{
									if (TankAbility[i] == 1)
									{
										SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", flBossSpecialSpeed, 0);
									}
								}
								else
								{
									SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", 1.0, 0);
									new random = GetRandomInt(1, 9);
									new random2 = GetRandomInt(1, iBossStormDelay);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect7, i, 3);
									}
									if (random2 == 1)
									{
										StartBossFall(i);
									}
								}
								InfectedCloak4(i);
								if (CountSurvivorsAliveAll() == CountSurvRange(i))
								{
									SetEntityRenderMode(i, RenderMode:3);
									SetEntityRenderColor(i, 0, 0, 50, 50);
									EmitSoundToAll("npc/infected/action/die/male/death_43.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
								else
								{
									SetEntityRenderMode(i, RenderMode:3);
									SetEntityRenderColor(i, 0, 0, 50, 150);
									EmitSoundToAll("npc/infected/action/die/male/death_42.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
							}
							case 37:
							{
								TeleportTank12(i);
								if (TankAbility[i])
								{
									if (TankAbility[i] == 1)
									{
										SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", flSpypsySpecialSpeed, 0);
									}
								}
								else
								{
									SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", 1.0, 0);
									new random = GetRandomInt(1, 9);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect8, i, 3);
									}
								}
							}
							case 38:
							{
								if (TankAbility[i])
								{
								}
								else
								{
									new random = GetRandomInt(1, iSipowStormDelay);
									if (random == 1)
									{
										StartSipowFall(i);
									}
								}
							}
							case 39:
							{
								TeleportTank13(i);
								InfectedCloak5(i);
								if (CountSurvivorsAliveAll() == CountSurvRange(i))
								{
									SetEntityRenderMode(i, RenderMode:3);
									SetEntityRenderColor(i, 100, 50, 50, 50);
									EmitSoundToAll("npc/infected/action/die/male/death_43.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
								else
								{
									SetEntityRenderMode(i, RenderMode:3);
									SetEntityRenderColor(i, 100, 50, 50, 150);
									EmitSoundToAll("npc/infected/action/die/male/death_42.wav", i, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
								if (TankAbility[i])
								{
									if (TankAbility[i] == 1)
									{
										SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", flPoltergeistSpecialSpeed, 0);
									}
								}
								else
								{
									SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", 1.0, 0);
									new random = GetRandomInt(1, 9);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect9, i, 3);
									}
								}
							}
							case 40:
							{
								TeleportTank14(i);
								if (TankAbility[i])
								{
									if (TankAbility[i] == 1)
									{
										SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", flMirageSpecialSpeed, 0);
									}
								}
								else
								{
									SetEntPropFloat(i, PropType:1, "m_flLaggedMovementValue", 1.0, 0);
									new random = GetRandomInt(1, 9);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect10, i, 3);
									}
								}
							}
							default:
							{
							}
						}
						if (bTankFireImmunity[index])
						{
							if (IsPlayerBurning(i))
							{
								ExtinguishEntity(i);
								SetEntPropFloat(i, PropType:0, "m_burnPercent", 1.0, 0);
							}
						}
					}
				}
			}
			i++;
		}
	}
	return 0;
}

public Action:TankSpawnTimer(Handle:timer, any:client)
{
	if (any:0 < client)
	{
		if (IsTank(client))
		{
			new index = GetSuperTankByRenderColor(GetEntityRenderColor(client));
			//
			if (index >= 0 && index <= 40)
			{
				//
				if (index || (index && bDefaultOverride))
				{
					switch (index)
					{
						case 1:
						{
							CreateTimer(1.2, Timer_AttachSPAWN, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03ZOMBIE TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "ZOMBIE TANK");
							}
						}
						case 2:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03KILLER TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "KILLER TANK");
							}
						}
						case 3:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03TELEPORT TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "TELEPORT TANK");
							}
						}
						case 4:
						{
							CreateTimer(0.1, MeteorTankTimer, client, 2);
							CreateTimer(6.0, Timer_AttachMETEOR, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03METEOR TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "METEOR TANK");
							}
						}
						case 5:
						{
							CreateTimer(2.0, Timer_AttachSPIT, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03ACID TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "ACID TANK");
							}
						}
						case 6:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03HULK TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "HULK TANK");
							}
						}
						case 7:
						{
							CreateTimer(0.8, Timer_AttachFIRE, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03FIRE TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "FIRE TANK");
							}
						}
						case 8:
						{
							CreateTimer(2.0, Timer_AttachICE, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03ICE TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "ICE TANK");
							}
						}
						case 9:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03JOCKEY TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "JOCKEY TANK");
							}
						}
						case 10:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03HUNTER TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "HUNTER TANK");
							}
						}
						case 11:
						{
							CreateTimer(1.2, Timer_AttachSMOKE, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03SMOKER TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "SMOKER TANK");
							}
						}
						case 12:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03BOOMER TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "BOOMER TANK");
							}
						}
						case 13:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03CHARGER TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "CHARGER TANK");
							}
						}
						case 14:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03FANTASMA TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "FANTASMA TANK");
							}
						}
						case 15:
						{
							CreateTimer(0.8, Timer_AttachELEC, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03SHOCK TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "SHOCK TANK");
							}
						}
						case 16:
						{
							CreateTimer(2.0, Timer_AttachBLOOD, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03WITCH TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "WITCH TANK");
							}
						}
						case 17:
						{
							if (!ShieldsUp[client])
							{
								ActivateShield(client);
							}
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03ESCUDO TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "SHIELD TANK");
							}
						}
						case 18:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03SONIC TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "SONIC TANK");
							}
						}
						case 19:
						{
							CreateTimer(0.1, JumperTankTimer, client, 2);
							CreateTimer(1.0, JumpTimer, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03JUMPER TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "JUMPER TANK");
							}
						}
						case 20:
						{
							CreateTimer(0.1, GravityTankTimer, client, 2);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03MAGNET TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "MAGNET TANK");
							}
						}
						case 21:
						{
							CreateTimer(0.1, FlashTankTimer, client, 2);
							CreateTimer(0.1, FlashTankTimer2, client, 2);
							CreateTimer(0.8, Timer_AttachELEC2, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03FLASH TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "FLASH TANK");
							}
						}
						case 22:
						{
							CreateTimer(0.1, ReverseFlashTankTimer, client, 2);
							CreateTimer(0.1, ReverseFlashTankTimer2, client, 2);
							CreateTimer(0.8, Timer_AttachELEC3, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03REVERSE FLASH TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "REVERSE FLASH TANK");
							}
						}
						case 23:
						{
							CreateTimer(0.1, ArmageddonTankTimer, client, 2);
							CreateTimer(6.0, Timer_AttachARMAGEDDON, client, 3);
							CreateTimer(0.1, ArmageddonTankTimer2, client, 2);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03ARMAGEDDON TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "ARMAGEDDON TANK");
							}
						}
						case 24:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03HALLUCINATION TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "HALLUCINATION TANK");
							}
						}
						case 25:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03MINION TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "MINION TANK");
							}
						}
						case 26:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03BITCH TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "BITCH TANK");
							}
						}
						case 27:
						{
							CreateTimer(0.1, TrapTankTimer, client, 2);
							CreateTimer(0.1, TrapTankTimer2, client, 2);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03TRAP TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "TRAP TANK");
							}
						}
						case 28:
						{
							CreateTimer(1.0, DistractionTimer, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03DISTRACTION TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "DISTRACTION TANK");
							}
						}
						case 29:
						{
							CreateTimer(0.1, FeedbackTankTimer, client, 2);
							CreateTimer(0.8, Timer_AttachELEC4, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03FEEDBACK TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "FEEDBACK TANK");
							}
						}
						case 30:
						{
							CreateTimer(0.1, PsychoticTankTimer, client, 2);
							CreateTimer(0.1, PsychoticTankTimer2, client, 2);
							CreateTimer(0.1, PsychoticTankTimer3, client, 2);
							CreateTimer(1.0, PsychoticTimer, client, 3);
							CreateTimer(6.0, Timer_AttachPSYCHOTIC, client, 3);
							CreateTimer(0.8, Timer_AttachELEC5, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03PSYCHOTIC TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "PSYCHOTIC TANK");
							}
						}
						case 31:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03SPITTER TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "SPITTER TANK");
							}
						}
						case 32:
						{
							CreateTimer(0.1, GoliathTankTimer, client, 2);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03GOLIATH TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "GOLIATH TANK");
							}
						}
						case 33:
						{
							CreateTimer(0.1, PsykotikTankTimer, client, 2);
							CreateTimer(0.1, PsykotikTankTimer2, client, 2);
							CreateTimer(0.8, Timer_AttachELEC6, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03PSYKOTIK TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "PSYKOTIK TANK");
							}
						}
						case 34:
						{
							CreateTimer(0.1, SpykotikTankTimer, client, 2);
							CreateTimer(0.1, SpykotikTankTimer2, client, 2);
							CreateTimer(0.8, Timer_AttachELEC7, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03SPYKOTIK TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "SPYKOTIK TANK");
							}
						}
						case 35:
						{
							CreateTimer(0.1, MemeTankTimer, client, 2);
							CreateTimer(0.1, MemeTankTimer2, client, 2);
							CreateTimer(0.1, MemeTankTimer3, client, 2);
							CreateTimer(1.0, MemeTimer, client, 3);
							CreateTimer(1.2, Timer_AttachMEME, client, 3);
							CreateTimer(6.0, Timer_AttachMEME2, client, 3);
							CreateTimer(2.0, Timer_AttachICE2, client, 3);
							CreateTimer(0.8, Timer_AttachFIRE2, client, 3);
							CreateTimer(2.0, Timer_AttachBLOOD2, client, 3);
							CreateTimer(0.8, Timer_AttachELEC8, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03MEME TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "MEME TANK");
							}
						}
						case 36:
						{
							CreateTimer(0.1, BossTankTimer, client, 2);
							CreateTimer(0.1, BossTankTimer2, client, 2);
							CreateTimer(0.1, BossTankTimer3, client, 2);
							CreateTimer(1.0, BossTimer, client, 3);
							CreateTimer(1.2, Timer_AttachBOSS, client, 3);
							CreateTimer(6.0, Timer_AttachBOSS2, client, 3);
							CreateTimer(2.0, Timer_AttachICE3, client, 3);
							CreateTimer(0.8, Timer_AttachFIRE3, client, 3);
							CreateTimer(2.0, Timer_AttachBLOOD3, client, 3);
							CreateTimer(0.8, Timer_AttachELEC9, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03BOSS TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "BOSS TANK");
							}
						}
						case 37:
						{
							CreateTimer(0.1, SpypsyTankTimer, client, 2);
							CreateTimer(0.1, SpypsyTankTimer2, client, 2);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03SPYPSY TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "SPYPSY TANK");
							}
						}
						case 38:
						{
							CreateTimer(0.1, SipowTankTimer, client, 2);
							CreateTimer(0.1, SipowTankTimer2, client, 2);
							CreateTimer(6.0, Timer_AttachSIPOW, client, 3);
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03SIPOW TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "SIPOW TANK");
							}
						}
						case 39:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03POLTERGEIST TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "POLTERGEIST TANK");
							}
						}
						case 40:
						{
							if (GetConVarInt(henable_announce))
							{
								PrintToChatAll("\x04[\x03☣[R.T.H]☣\x04]\x01 \x01[\x03MIRAGE TANK\x01]");
							}
							if (IsFakeClient(client))
							{
								SetClientInfo(client, "name", "MIRAGE TANK");
							}
						}
						default:
						{
						}
					}
					if (0 < iTankExtraHealth[index])
					{
						new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
						new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
						//SetEntProp(client, PropType, "m_iMaxHealth", iTankExtraHealth[index][maxhealth]);
						//SetEntProp(client, PropType, "m_iHealth", iTankExtraHealth[index][health]);

						SetEntProp(client, Prop_Send, "m_iMaxHealth", maxhealth + iTankExtraHealth[index]);
						SetEntProp(client, Prop_Send, "m_iHealth", health + iTankExtraHealth[index]);	
					}
					ResetInfectedAbility(client, flTankThrow[index]);
				}
			}
		}
	}
	return Action:0;
}

SpeedRebuild(client)
{
	new Float:value = 0.0;
	new speed = PlayerSpeed[client];
	if (0 < speed)
	{
		value = flShockStunMovement;
		SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", value, 0);
	}
	else
	{
		if (!speed)
		{
			value = 1.0;
			SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", value, 0);
			PlayerSpeed[client] += -1;
		}
	}
	return 0;
}

SpeedRebuild2(client)
{
	new Float:value = 0.0;
	new speed = PlayerSpeed[client];
	if (0 < speed)
	{
		value = flFeedbackStunMovement;
		SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", value, 0);
	}
	else
	{
		if (!speed)
		{
			value = 1.0;
			SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", value, 0);
			PlayerSpeed[client] += -1;
		}
	}
	return 0;
}

public void OnEntityCreated(entity, const String:classname[])
{
	if(bSuperTanksEnabled)
	{
		if(StrEqual(classname, "tank_rock", true))
		{
			CreateTimer(0.1, RockThrowTimer, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void OnEntityDestroyed(entity)
{
	//if(!IsServerProcessing()) return;
	
	if (!IsServerProcessing())

	if (bSuperTanksEnabled)
	{
		//
		if (entity > 32 && IsValidEntity(entity))
		{
			new String:classname[32];
			GetEdictClassname(entity, classname, 32);
			if (StrEqual(classname, "tank_rock", true))
			{
				new color = GetEntityRenderColor(entity);
				switch (color)
				{
					case 12800:
					{
						new prop = CreateEntityByName("prop_physics", -1);
						//
						if (prop > 32 && IsValidEntity(prop))
						{
							new Float:Pos[3] = 0.0;
							GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
							Pos[2] += 10.0;
							DispatchKeyValue(prop, "model", "models/props_junk/gascan001a.mdl");
							DispatchSpawn(prop);
							SetEntData(prop, GetEntSendPropOffs(prop, "m_CollisionGroup", false), any:1, 1, true);
							TeleportEntity(prop, Pos, NULL_VECTOR, NULL_VECTOR);
							AcceptEntityInput(prop, "break", -1, -1, 0);
						}
					}
					case 255125:
					{
						new x = CreateFakeClient("Spitter");
						if (0 < x)
						{
							new Float:Pos[3] = 0.0;
							GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
							TeleportEntity(x, Pos, NULL_VECTOR, NULL_VECTOR);
							SDKCallSpitBurst(x);
							KickClient(x, "");
						}
					}
					case 12115128:
					{
						new x = CreateFakeClient("Spitter");
						if (0 < x)
						{
							new Float:Pos[3] = 0.0;
							GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
							TeleportEntity(x, Pos, NULL_VECTOR, NULL_VECTOR);
							SDKCallSpitBurst(x);
							KickClient(x, "");
						}
					}
					default:
					{
					}
				}
			}
		}
	}
	//return void:0;
}

//Pick()
stock Pick()
{
	new count;
	new clients[MaxClients];
	new i = 1;
	while (i <= MaxClients)
	{
		//
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			count++;
			clients[count] = i;
		}
		i++;
	}
	return clients[GetRandomInt(0, count + -1)];
}

bool:IsSpecialInfected(client)
{
	//
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[32];
		GetEntityNetClass(client, classname, 32);
		//
		if (StrEqual(classname, "Smoker", false) || StrEqual(classname, "Boomer", false) || StrEqual(classname, "Hunter", false) || StrEqual(classname, "Spitter", false) || StrEqual(classname, "Jockey", false) || StrEqual(classname, "Charger", false))
		{
			return true;
		}
	}
	return false;
}

bool:IsTank(client)
{
	//
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && !IsPlayerIncap(client) && TankAlive[client] == 1)
	{
		decl String:classname[32];
		GetEntityNetClass(client, classname, 32);
		if (StrEqual(classname, "Tank", false))
		{
			return true;
		}
	}
	return false;
}

bool:IsValidClient(client)
{
	//
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

bool:IsSurvivor(client)
{
	//
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

bool:IsWitch(i)
{
	if (IsValidEntity(i))
	{
		decl String:classname[32];
		GetEdictClassname(i, classname, 32);
		if (StrEqual(classname, "witch", true))
		{
			return true;
		}
		return false;
	}
	return false;
}

CountTanks()
{
	iNumTanks = 0;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsTank(i))
		{
			iNumTanks += 1;
		}
		i++;
	}
	return 0;
}

public Action:TankLifeCheck(Handle:timer, any:client)
{
	//
	if (IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		new lifestate = GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"));
		if(lifestate == 0)
		{
		//
		}
		else
		{
			new bot = CreateFakeClient("Tank");
			if (0 < bot)
			{
				new Float:Origin[3] = 0.0;
				new Float:Angles[3] = 0.0;
				GetClientAbsOrigin(client, Origin);
				GetClientAbsAngles(client, Angles);
				KickClient(client, "");
				TeleportEntity(bot, Origin, Angles, NULL_VECTOR);
				SpawnInfected(bot, 8, true);
			}
		}
	}
	return Action:0;
}

RandomizeTank(client)
{
	if (!bDefaultTanks)
	{
		new count;
		new TempArray[41];
		new index = 1;
		while (index <= 40)
		{
			if (bTankEnabled[index])
			{
				TempArray[count + 1] = index;
				count++;
			}
			index++;
		}
		if (0 < count)
		{
			new random = GetRandomInt(1, count);
			new tankpick = TempArray[random];
			switch (tankpick)
			{
				case 1:
				{
					SetEntityRenderColor(client, 75, 95, 105, 255);
				}
				case 2:
				{
					SetEntityRenderColor(client, 70, 80, 100, 255);
				}
				case 3:
				{
					SetEntityRenderColor(client, 130, 130, 255, 255);
				}
				case 4:
				{
					SetEntityRenderColor(client, 100, 25, 25, 255);
				}
				case 5:
				{
					SetEntityRenderColor(client, 12, 115, 128, 255);
				}
				case 6:
				{
					SetEntityRenderColor(client, 100, 255, 200, 255);
				}
				case 7:
				{
					SetEntityRenderColor(client, 128, 0, 0, 255);
				}
				case 8:
				{
					SetEntityRenderMode(client, RenderMode:3);
					SetEntityRenderColor(client, 0, 100, 170, 200);
				}
				case 9:
				{
					SetEntityRenderColor(client, 255, 165, 75, 255);
				}
				case 10:
				{
					SetEntityRenderColor(client, 25, 90, 185, 255);
				}
				case 11:
				{
					SetEntityRenderColor(client, 120, 85, 120, 255);
				}
				case 12:
				{
					SetEntityRenderColor(client, 65, 105, 0, 255);
				}
				case 13:
				{
					SetEntityRenderColor(client, 40, 125, 40, 255);
				}
				case 14:
				{
					SetEntityRenderMode(client, RenderMode:3);
					SetEntityRenderColor(client, 100, 100, 100, 0);
				}
				case 15:
				{
					SetEntityRenderColor(client, 100, 165, 255, 255);
				}
				case 16:
				{
					SetEntityRenderColor(client, 255, 200, 255, 255);
				}
				case 17:
				{
					SetEntityRenderColor(client, 135, 205, 255, 255);
				}
				case 18:
				{
					SetEntityRenderColor(client, 0, 105, 255, 255);
				}
				case 19:
				{
					SetEntityRenderColor(client, 200, 255, 0, 255);
				}
				case 20:
				{
					SetEntityRenderColor(client, 33, 34, 35, 255);
				}
				case 21:
				{
					SetEntityRenderColor(client, 255, 0, 0, 255);
				}
				case 22:
				{
					SetEntityRenderColor(client, 255, 255, 0, 255);
				}
				case 23:
				{
					SetEntityRenderColor(client, 75, 0, 0, 255);
				}
				case 24:
				{
					SetEntityRenderMode(client, RenderMode:3);
					SetEntityRenderColor(client, 50, 50, 50, 0);
				}
				case 25:
				{
					SetEntityRenderColor(client, 225, 225, 225, 255);
				}
				case 26:
				{
					SetEntityRenderColor(client, 255, 155, 255, 255);
				}
				case 27:
				{
					SetEntityRenderColor(client, 55, 125, 70, 255);
				}
				case 28:
				{
					SetEntityRenderColor(client, 225, 225, 0, 255);
				}
				case 29:
				{
					SetEntityRenderColor(client, 90, 60, 90, 255);
				}
				case 30:
				{
					SetEntityRenderColor(client, 0, 0, 0, 255);
				}
				case 31:
				{
					SetEntityRenderColor(client, 75, 255, 75, 255);
				}
				case 32:
				{
					SetEntityRenderColor(client, 0, 0, 100, 255);
				}
				case 33:
				{
					SetEntityRenderColor(client, 1, 1, 1, 255);
				}
				case 34:
				{
					SetEntityRenderColor(client, 255, 100, 255, 255);
				}
				case 35:
				{
					SetEntityRenderColor(client, 0, 255, 0, 255);
				}
				case 36:
				{
					SetEntityRenderColor(client, 0, 0, 50, 255);
				}
				case 37:
				{
					SetEntityRenderColor(client, 0, 0, 255, 255);
				}
				case 38:
				{
					SetEntityRenderColor(client, 0, 255, 125, 255);
				}
				case 39:
				{
					SetEntityRenderColor(client, 100, 50, 50, 0);
				}
				case 40:
				{
					SetEntityRenderColor(client, 25, 40, 25, 255);
				}
				default:
				{
				}
			}
		}
	}
	return 0;
}

//SpawnInfected(client, Class, bool:bAuto)
stock SpawnInfected(client, Class, bool:bAuto=true)
{
	new resetGhostState[MaxClients + 1];
	new resetHallucinationState[MaxClients + 1];
	new resetMemeState[MaxClients + 1];
	new resetBossState[MaxClients + 1];
	new resetPoltergeistState[MaxClients + 1];
	new resetIsAlive[MaxClients + 1];
	new resetLifeState[MaxClients + 1];
	ChangeClientTeam(client, 3);
	//new String:g_sBossNames[10][12] = "(";
	new String:g_sBossNames[9+1][10]={"","smoker","boomer","hunter","spitter","jockey","charger","witch","tank","survivor"};
	decl String:options[32];
	//
	if (Class < 1 || Class > 8)
	{
		return 0;
	}
	if (GetClientTeam(client) != 3)
	{
		return 0;
	}
	if (!IsClientInGame(client))
	{
		return 0;
	}
	if (IsPlayerAlive(client))
	{
		return 0;
	}
	new i = 1;
	while (i <= MaxClients)
	{
		if (!(client == i))
		{
			if (IsClientInGame(i))
			{
				if (!(GetClientTeam(i) != 3))
				{
					if (!(IsFakeClient(i)))
					{
						if (IsPlayerGhost(i))
						{
							resetGhostState[i] = true;
							SetPlayerGhostStatus(i, false);
							resetIsAlive[i] = true;
							SetPlayerIsAlive(i, true);
						}
						if (IsPlayerHallucination(i))
						{
							resetHallucinationState[i] = true;
							SetPlayerHallucinationStatus(i, false);
							resetIsAlive[i] = true;
							SetPlayerIsAlive(i, true);
						}
						if (IsPlayerMeme(i))
						{
							resetMemeState[i] = true;
							SetPlayerMemeStatus(i, false);
							resetIsAlive[i] = true;
							SetPlayerIsAlive(i, true);
						}
						if (IsPlayerBoss(i))
						{
							resetBossState[i] = true;
							SetPlayerBossStatus(i, false);
							resetIsAlive[i] = true;
							SetPlayerIsAlive(i, true);
						}
						if (IsPlayerPoltergeist(i))
						{
							resetPoltergeistState[i] = true;
							SetPlayerPoltergeistStatus(i, false);
							resetIsAlive[i] = true;
							SetPlayerIsAlive(i, true);
						}
						else
						{
							if (!IsPlayerAlive(i))
							{
								resetLifeState[i] = true;
								SetPlayerLifeState(i, false);
							}
						}
					}
				}
			}
		}
		i++;
	}
	/*
	if (bAuto)
	{
		var2[0] = 36620;
	}
	else
	{
		var2[0] = 36628;
	}
	Format(options, 30, "%s%s", g_sBossNames[Class], var2);*/
	Format(options,sizeof(options),"%s%s",g_sBossNames[Class],(bAuto?" auto":""));
	CheatCommand(client, "z_spawn", options);
	
	if(IsFakeClient(client)) KickClient(client);
	// We restore the player's status
	for(new d=1; d<=MaxClients; d++)
	{
		if(resetGhostState[i]) SetPlayerGhostStatus(i, true);
		if(resetHallucinationState[i]) SetPlayerHallucinationStatus(i, true);

		//Meme Tank
		if(resetMemeState[i]) SetPlayerMemeStatus(i, true);

		//Boss Tank
		if(resetBossState[i]) SetPlayerBossStatus(i, true);
		if(resetPoltergeistState[i]) SetPlayerPoltergeistStatus(i, true);
		if(resetIsAlive[i]) SetPlayerIsAlive(i, false);
		if(resetLifeState[i]) SetPlayerLifeState(i, true);
	}

	return true;
}

SetPlayerGhostStatus(client, bool:ghost)
{
	if (ghost)
	{
		SetEntProp(client, PropType:0, "m_isGhost", any:1, 1, 0);
	}
	else
	{
		SetEntProp(client, PropType:0, "m_isGhost", any:0, 1, 0);
	}
	return 0;
}

SetPlayerHallucinationStatus(client, bool:hallucination)
{
	if (hallucination)
	{
		SetEntProp(client, PropType:0, "m_isGhost", any:1, 1, 0);
	}
	else
	{
		SetEntProp(client, PropType:0, "m_isGhost", any:0, 1, 0);
	}
	return 0;
}

SetPlayerMemeStatus(client, bool:meme)
{
	if (meme)
	{
		SetEntProp(client, PropType:0, "m_isGhost", any:1, 1, 0);
	}
	else
	{
		SetEntProp(client, PropType:0, "m_isGhost", any:0, 1, 0);
	}
	return 0;
}

SetPlayerBossStatus(client, bool:boss)
{
	if (boss)
	{
		SetEntProp(client, PropType:0, "m_isGhost", any:1, 1, 0);
	}
	else
	{
		SetEntProp(client, PropType:0, "m_isGhost", any:0, 1, 0);
	}
	return 0;
}

SetPlayerPoltergeistStatus(client, bool:poltergeist)
{
	if (poltergeist)
	{
		SetEntProp(client, PropType:0, "m_isGhost", any:1, 1, 0);
	}
	else
	{
		SetEntProp(client, PropType:0, "m_isGhost", any:0, 1, 0);
	}
	return 0;
}

SetPlayerIsAlive(client, bool:alive)
{
	new offset = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	if (alive)
	{
		SetEntData(client, offset, any:1, 1, true);
	}
	else
	{
		SetEntData(client, offset, any:0, 1, true);
	}
	return 0;
}

SetPlayerLifeState(client, bool:ready)
{
	if (ready)
	{
		SetEntProp(client, PropType:1, "m_lifeState", any:1, 1, 0);
	}
	else
	{
		SetEntProp(client, PropType:1, "m_lifeState", any:0, 1, 0);
	}
	return 0;
}

bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, PropType:0, "m_isGhost", 1, 0))
	{
		return true;
	}
	return false;
}

bool:IsPlayerHallucination(client)
{
	if (GetEntProp(client, PropType:0, "m_isGhost", 1, 0))
	{
		return true;
	}
	return false;
}

bool:IsPlayerMeme(client)
{
	if (GetEntProp(client, PropType:0, "m_isGhost", 1, 0))
	{
		return true;
	}
	return false;
}

bool:IsPlayerBoss(client)
{
	if (GetEntProp(client, PropType:0, "m_isGhost", 1, 0))
	{
		return true;
	}
	return false;
}

bool:IsPlayerPoltergeist(client)
{
	if (GetEntProp(client, PropType:0, "m_isGhost", 1, 0))
	{
		return true;
	}
	return false;
}

bool:IsPlayerIncap(client)
{
	if (GetEntProp(client, PropType:0, "m_isIncapacitated", 1, 0))
	{
		return true;
	}
	return false;
}

CountSurvivorsAliveAll()
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		//
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			count++;
		}
		i++;
	}
	return count;
}

CountInfectedAll()
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		//
		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			count++;
		}
		i++;
	}
	return count;
}

bool:IsPlayerBurning(i)
{
	new Float:IsBurning = GetEntPropFloat(i, PropType:0, "m_burnPercent", 0);
	if (IsBurning > 0.0)
	{
		return true;
	}
	return false;
}

public Action:CreateParticle(target, String:particlename[], Float:time, Float:origin)
{
	if (0 < target)
	{
		new particle = CreateEntityByName("info_particle_system", -1);
		if (IsValidEntity(particle))
		{
			new Float:pos[3] = 0.0;
			GetEntPropVector(target, PropType:0, "m_vecOrigin", pos, 0);
			pos[2] += origin;
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(particle, "effect_name", particlename);
			DispatchKeyValue(particle, "targetname", "particle");
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start", -1, -1, 0);
			CreateTimer(time, DeleteParticles, particle, 2);
		}
	}
	return Action:0;
}

public Action:AttachParticle(target, String:particlename[], Float:time, Float:origin)
{
	//
	if (target > 0 && IsValidEntity(target))
	{
		new particle = CreateEntityByName("info_particle_system", -1);
		if (IsValidEntity(particle))
		{
			new Float:pos[3] = 0.0;
			GetEntPropVector(target, PropType:0, "m_vecOrigin", pos, 0);
			pos[2] += origin;
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			decl String:tName[64];
			Format(tName, 64, "Attach%d", target);
			DispatchKeyValue(target, "targetname", tName);
			GetEntPropString(target, PropType:1, "m_iName", tName, 64, 0);
			DispatchKeyValue(particle, "scale", "");
			DispatchKeyValue(particle, "effect_name", particlename);
			DispatchKeyValue(particle, "parentname", tName);
			DispatchKeyValue(particle, "targetname", "particle");
			DispatchSpawn(particle);
			ActivateEntity(particle);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
			AcceptEntityInput(particle, "Enable", -1, -1, 0);
			AcceptEntityInput(particle, "start", -1, -1, 0);
			CreateTimer(time, DeleteParticles, particle, 2);
		}
	}
	return Action:0;
}

public Action:PrecacheParticle(String:particlename[])
{
	new particle = CreateEntityByName("info_particle_system", -1);
	if (IsValidEntity(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		CreateTimer(0.1, DeleteParticles, particle, 2);
	}
	return Action:0;
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, 64);
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "Kill", -1, -1, 0);
		}
	}
	return Action:0;
}

public ScreenShake(target, Float:intensity)
{
	new Handle:msg = StartMessageOne("Shake", target, 0);
	BfWriteByte(msg, 0);
	BfWriteFloat(msg, intensity);
	BfWriteFloat(msg, 10.0);
	BfWriteFloat(msg, 3.0);
	EndMessage();
	return 0;
}

public Action:RockThrowTimer(Handle:timer)
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
	{
		new thrower = GetEntPropEnt(entity, PropType:1, "m_hThrower", 0);
		//
		if (thrower > 0 && thrower < 40 && IsTank(thrower))
		{
			new color = GetEntityRenderColor(thrower);
			switch (color)
			{
				case 12800:
				{
					SetEntityRenderColor(entity, 128, 0, 0, 255);
					CreateTimer(0.8, Timer_AttachFIRE_Rock, entity, 3);
				}
				case 100170:
				{
					SetEntityRenderMode(entity, RenderMode:3);
					SetEntityRenderColor(entity, 0, 100, 170, 180);
				}
				case 254025:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, MirageThrow, thrower, 3);
				}
				case 651050:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, BoomerThrow, thrower, 3);
				}
				case 906090:
				{
					CreateTimer(0.8, Timer_AttachELEC_Rock2, entity, 3);
				}
				case 2590185:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, HunterThrow, thrower, 3);
				}
				case 4012540:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, ChargerThrow, thrower, 3);
				}
				case 7525575:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, SpitterThrow, thrower, 3);
				}
				case 12085120:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, SmokerThrow, thrower, 3);
				}
				case 12115128:
				{
					SetEntityRenderMode(entity, RenderMode:3);
					SetEntityRenderColor(entity, 121, 151, 28, 30);
					CreateTimer(0.8, Timer_SpitSound, thrower, 2);
					CreateTimer(0.8, Timer_AttachSPIT_Rock, entity, 3);
				}
				case 25516575:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, JockeyThrow, thrower, 3);
				}
				case 100165255:
				{
					CreateTimer(0.8, Timer_AttachELEC_Rock, entity, 3);
				}
				case 135205255:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, PropaneThrow, thrower, 3);
				}
				case 225225225:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, MinionThrow, thrower, 3);
				}
				case 255155255:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, BitchThrow, thrower, 3);
				}
				default:
				{
				}
			}
		}
	}
	return Action:0;
}

public Action:PropaneThrow(Handle:timer, any:client)
{
	new Float:velocity[3] = 0.0;
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity, false);
		if (v > 500.0)
		{
			new propane = CreateEntityByName("prop_physics", -1);
			if (IsValidEntity(propane))
			{
				DispatchKeyValue(propane, "model", "models/props_junk/propanecanister001a.mdl");
				DispatchSpawn(propane);
				new Float:Pos[3] = 0.0;
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 1.4);
				TeleportEntity(propane, Pos, NULL_VECTOR, velocity);
			}
			return Action:4;
		}
		return Action:0;
	}
	return Action:4;
}

public Action:JockeyThrow(Handle:timer, any:client)
{
	new Float:velocity[3] = 0.0;
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity, false);
		if (v > 500.0)
		{
			new bot = CreateFakeClient("Jockey");
			if (0 < bot)
			{
				SpawnInfected(bot, 5, true);
				new Float:Pos[3] = 0.0;
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 1.4);
				TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
			}
			return Action:4;
		}
		return Action:0;
	}
	return Action:4;
}

public Action:HunterThrow(Handle:timer, any:client)
{
	new Float:velocity[3] = 0.0;
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity, false);
		if (v > 500.0)
		{
			new bot = CreateFakeClient("Hunter");
			if (0 < bot)
			{
				SpawnInfected(bot, 3, true);
				new Float:Pos[3] = 0.0;
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 1.4);
				TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
			}
			return Action:4;
		}
		return Action:0;
	}
	return Action:4;
}

public Action:SmokerThrow(Handle:timer, any:client)
{
	new Float:velocity[3] = 0.0;
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity, false);
		if (v > 500.0)
		{
			new bot = CreateFakeClient("Smoker");
			if (0 < bot)
			{
				SpawnInfected(bot, 1, true);
				new Float:Pos[3] = 0.0;
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 1.4);
				TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
			}
			return Action:4;
		}
		return Action:0;
	}
	return Action:4;
}

public Action:BoomerThrow(Handle:timer, any:client)
{
	new Float:velocity[3] = 0.0;
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity, false);
		if (v > 500.0)
		{
			new bot = CreateFakeClient("Boomer");
			if (0 < bot)
			{
				SpawnInfected(bot, 2, true);
				new Float:Pos[3] = 0.0;
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 1.4);
				TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
			}
			return Action:4;
		}
		return Action:0;
	}
	return Action:4;
}

public Action:ChargerThrow(Handle:timer, any:client)
{
	new Float:velocity[3] = 0.0;
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity, false);
		if (v > 500.0)
		{
			new bot = CreateFakeClient("Charger");
			if (0 < bot)
			{
				SpawnInfected(bot, 6, true);
				new Float:Pos[3] = 0.0;
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 1.4);
				TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
			}
			return Action:4;
		}
		return Action:0;
	}
	return Action:4;
}

public Action:MinionThrow(Handle:timer, any:client)
{
	new Float:velocity[3] = 0.0;
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity, false);
		if (v > 500.0)
		{
			new bot = CreateFakeClient("Tank");
			if (0 < bot)
			{
				SpawnInfected(bot, 8, true);
				new Float:Pos[3] = 0.0;
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 1.4);
				TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
			}
			return Action:4;
		}
		return Action:0;
	}
	return Action:4;
}

public Action:BitchThrow(Handle:timer, any:client)
{
	new Float:velocity[3] = 0.0;
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity, false);
		if (v > 500.0)
		{
			new bot = CreateFakeClient("Witch");
			if (0 < bot)
			{
				SpawnInfected(bot, 7, true);
				new Float:Pos[3] = 0.0;
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 1.4);
				TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
			}
			return Action:4;
		}
		return Action:0;
	}
	return Action:4;
}

public Action:SpitterThrow(Handle:timer, any:client)
{
	new Float:velocity[3] = 0.0;
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity, false);
		if (v > 500.0)
		{
			new bot = CreateFakeClient("Spitter");
			if (0 < bot)
			{
				SpawnInfected(bot, 4, true);
				new Float:Pos[3] = 0.0;
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 1.4);
				TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
			}
			return Action:4;
		}
		return Action:0;
	}
	return Action:4;
}

public Action:MirageThrow(Handle:timer, any:client)
{
	new Float:velocity[3] = 0.0;
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity, false);
		if (v > 500.0)
		{
			new bot = CreateFakeClient("Tank");
			if (0 < bot)
			{
				SpawnInfected(bot, 8, true);
				new Float:Pos[3] = 0.0;
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", Pos, 0);
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 1.4);
				TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
			}
			return Action:4;
		}
		return Action:0;
	}
	return Action:4;
}

public Action:JumpTimer(Handle:timer, any:client)
{
	//
	if (client > any:0 && IsTank(client))
	{
		new flags = GetEntityFlags(client);
		if (flags & 1)
		{
			new random = GetRandomInt(1, iJumperJumpDelay);
			if (random == 1)
			{
				//
				if (GetNearestSurvivorDist(client) > 200 && GetNearestSurvivorDist(client) < 2000)
				{
					FakeJump(client);
				}
			}
		}
		return Action:0;
	}
	return Action:4;
}

public Action:PsychoticTimer(Handle:timer, any:client)
{
	//
	if (client > any:0 && IsTank(client))
	{
		new flags = GetEntityFlags(client);
		if (flags & 1)
		{
			new random = GetRandomInt(1, iPsychoticJumpDelay);
			if (random == 1)
			{
				//
				if (GetNearestSurvivorDist(client) > 200 && GetNearestSurvivorDist(client) < 2000)
				{
					FakeJump(client);
				}
			}
		}
		return Action:0;
	}
	return Action:4;
}

public Action:DistractionTimer(Handle:timer, any:client)
{
	//
	if (client > any:0 && IsTank(client))
	{
		new flags = GetEntityFlags(client);
		if (flags & 1)
		{
			new random = GetRandomInt(1, iDistractionJumpDelay);
			if (random == 1)
			{
				//
				if (GetNearestSurvivorDist(client) > 200 && GetNearestSurvivorDist(client) < 2000)
				{
					FakeJump(client);
				}
			}
		}
		return Action:0;
	}
	return Action:4;
}

public Action:MemeTimer(Handle:timer, any:client)
{
	//
	if (client > any:0 && IsTank(client))
	{
		new flags = GetEntityFlags(client);
		if (flags & 1)
		{
			new random = GetRandomInt(1, iMemeJumpDelay);
			if (random == 1)
			{
				//
				if (GetNearestSurvivorDist(client) > 200 && GetNearestSurvivorDist(client) < 2000)
				{
					FakeJump(client);
				}
			}
		}
		return Action:0;
	}
	return Action:4;
}

public Action:BossTimer(Handle:timer, any:client)
{
	//
	if (client > any:0 && IsTank(client))
	{
		new flags = GetEntityFlags(client);
		if (flags & 1)
		{
			new random = GetRandomInt(1, iBossJumpDelay);
			if (random == 1)
			{
				//
				if (GetNearestSurvivorDist(client) > 200 && GetNearestSurvivorDist(client) < 2000)
				{
					FakeJump(client);
				}
			}
		}
		return Action:0;
	}
	return Action:4;
}

public FakeJump(client)
{
	//
	if (client > 0 && IsTank(client))
	{
		new Float:vecVelocity[3] = 0.0;
		GetEntPropVector(client, PropType:1, "m_vecVelocity", vecVelocity, 0);
		//
		if (vecVelocity[0] > 0.0 && vecVelocity[0] < 500.0)
		{
			vecVelocity[0] = vecVelocity[0] + 500.0;
		}
		else
		{
			//
			if (vecVelocity[0] < 0.0 && vecVelocity[0] > -500.0)
			{
				vecVelocity[0] = vecVelocity[0] + -500.0;
			}
		}
		//
		if (vecVelocity[1] > 0.0 && vecVelocity[1] < 500.0)
		{
			vecVelocity[1] += 500.0;
		}
		else
		{
			//
			if (vecVelocity[1] < 0.0 && vecVelocity[1] > -500.0)
			{
				vecVelocity[1] += -500.0;
			}
		}
		vecVelocity[2] += 750.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
	}
	return 0;
}

public SkillFlameClaw(target)
{
	if (0 < target)
	{
		//
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			IgniteEntity(target, 3.0, false, 0.0, false);
			EmitSoundToAll("ambient/fire/gascan_ignite1.wav", target, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	return 0;
}

public SkillIceClaw(target)
{
	if (0 < target)
	{
		//
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			SetEntityRenderMode(target, RenderMode:3);
			SetEntityRenderColor(target, 0, 100, 170, 180);
			SetEntityMoveType(target, MoveType:6);
			CreateTimer(5.0, Timer_UnFreeze, target, 2);
		}
	}
	return 0;
}

public SkillFlameGush(target)
{
	if (0 < target)
	{
		//
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 3)
		{
			decl Float:pos[3];
			GetClientAbsOrigin(target, pos);
			new entity = CreateEntityByName("prop_physics", -1);
			if (IsValidEntity(entity))
			{
				pos[2] += 10.0;
				DispatchKeyValue(entity, "model", "models/props_junk/gascan001a.mdl");
				DispatchSpawn(entity);
				SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup", false), any:1, 1, true);
				TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(entity, "break", -1, -1, 0);
			}
		}
	}
	return 0;
}

public SkillGravityClaw(target)
{
	if (0 < target)
	{
		//
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			SetEntityGravity(target, 0.3);
			CreateTimer(2.0, Timer_ResetGravity, target, 2);
			ScreenShake(target, 5.0);
		}
	}
	return 0;
}

public Action:MeteorTankTimer(Handle:timer, any:client)
{
	//
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 1002525)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:FlashTankTimer(Handle:timer, any:client)
{
	//
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 25500)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new entity = CreateEntityByName("beam_spotlight", -1);
			if (IsValidEntity(entity))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(entity, "targetname", "LightEntity");
				DispatchKeyValue(entity, "parentname", tName);
				DispatchKeyValueVector(entity, "origin", Origin);
				DispatchKeyValueVector(entity, "angles", Angles);
				DispatchKeyValue(entity, "spotlightwidth", "10");
				DispatchKeyValue(entity, "spotlightlength", "60");
				DispatchKeyValue(entity, "spawnflags", "3");
				DispatchKeyValue(entity, "rendercolor", "255 255 0");
				DispatchKeyValue(entity, "renderamt", "125");
				DispatchKeyValue(entity, "maxspeed", "100");
				DispatchKeyValue(entity, "HDRColorScale", "0.7");
				DispatchKeyValue(entity, "fadescale", "1");
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);
				SetVariantString(tName);
				AcceptEntityInput(entity, "SetParent", entity, entity, 0);
				SetVariantString("mouth");
				AcceptEntityInput(entity, "SetParentAttachment", -1, -1, 0);
				AcceptEntityInput(entity, "Enable", -1, -1, 0);
				AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
				SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
				TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	return Action:0;
}

public Action:FlashTankTimer2(Handle:timer, any:client)
{
	//
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 25500)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					SetEntityRenderColor(ent[count], 225, 225, 0, 255);
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:ReverseFlashTankTimer(Handle:timer, any:client)
{
	//
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 2552550)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new entity = CreateEntityByName("beam_spotlight", -1);
			if (IsValidEntity(entity))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(entity, "targetname", "LightEntity");
				DispatchKeyValue(entity, "parentname", tName);
				DispatchKeyValueVector(entity, "origin", Origin);
				DispatchKeyValueVector(entity, "angles", Angles);
				DispatchKeyValue(entity, "spotlightwidth", "10");
				DispatchKeyValue(entity, "spotlightlength", "60");
				DispatchKeyValue(entity, "spawnflags", "3");
				DispatchKeyValue(entity, "rendercolor", "255 0 0");
				DispatchKeyValue(entity, "renderamt", "125");
				DispatchKeyValue(entity, "maxspeed", "100");
				DispatchKeyValue(entity, "HDRColorScale", "0.7");
				DispatchKeyValue(entity, "fadescale", "1");
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);
				SetVariantString(tName);
				AcceptEntityInput(entity, "SetParent", entity, entity, 0);
				SetVariantString("mouth");
				AcceptEntityInput(entity, "SetParentAttachment", -1, -1, 0);
				AcceptEntityInput(entity, "Enable", -1, -1, 0);
				AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
				SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
				TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	return Action:0;
}

public Action:ReverseFlashTankTimer2(Handle:timer, any:client)
{
	//
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 2552550)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					SetEntityRenderColor(ent[count], 225, 0, 0, 255);
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:PsykotikTankTimer(Handle:timer, any:client)
{
	//
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 111)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new entity = CreateEntityByName("beam_spotlight", -1);
			if (IsValidEntity(entity))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(entity, "targetname", "LightEntity");
				DispatchKeyValue(entity, "parentname", tName);
				DispatchKeyValueVector(entity, "origin", Origin);
				DispatchKeyValueVector(entity, "angles", Angles);
				DispatchKeyValue(entity, "spotlightwidth", "10");
				DispatchKeyValue(entity, "spotlightlength", "60");
				DispatchKeyValue(entity, "spawnflags", "3");
				DispatchKeyValue(entity, "rendercolor", "100 200 255");
				DispatchKeyValue(entity, "renderamt", "125");
				DispatchKeyValue(entity, "maxspeed", "100");
				DispatchKeyValue(entity, "HDRColorScale", "0.7");
				DispatchKeyValue(entity, "fadescale", "1");
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);
				SetVariantString(tName);
				AcceptEntityInput(entity, "SetParent", entity, entity, 0);
				SetVariantString("mouth");
				AcceptEntityInput(entity, "SetParentAttachment", -1, -1, 0);
				AcceptEntityInput(entity, "Enable", -1, -1, 0);
				AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
				SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
				TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	return Action:0;
}

public Action:PsykotikTankTimer2(Handle:timer, any:client)
{
	//
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 111)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					SetEntityRenderColor(ent[count], 225, 0, 0, 255);
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:SpykotikTankTimer(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 255100255)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new entity = CreateEntityByName("beam_spotlight", -1);
			if (IsValidEntity(entity))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(entity, "targetname", "LightEntity");
				DispatchKeyValue(entity, "parentname", tName);
				DispatchKeyValueVector(entity, "origin", Origin);
				DispatchKeyValueVector(entity, "angles", Angles);
				DispatchKeyValue(entity, "spotlightwidth", "10");
				DispatchKeyValue(entity, "spotlightlength", "60");
				DispatchKeyValue(entity, "spawnflags", "3");
				DispatchKeyValue(entity, "rendercolor", "150 0 255");
				DispatchKeyValue(entity, "renderamt", "125");
				DispatchKeyValue(entity, "maxspeed", "100");
				DispatchKeyValue(entity, "HDRColorScale", "0.7");
				DispatchKeyValue(entity, "fadescale", "1");
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);
				SetVariantString(tName);
				AcceptEntityInput(entity, "SetParent", entity, entity, 0);
				SetVariantString("mouth");
				AcceptEntityInput(entity, "SetParentAttachment", -1, -1, 0);
				AcceptEntityInput(entity, "Enable", -1, -1, 0);
				AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
				SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
				TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	return Action:0;
}

public Action:SpykotikTankTimer2(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 255100255)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					SetEntityRenderColor(ent[count], 150, 0, 255, 255);
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:MemeTankTimer(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 2550)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new entity = CreateEntityByName("beam_spotlight", -1);
			if (IsValidEntity(entity))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(entity, "targetname", "LightEntity");
				DispatchKeyValue(entity, "parentname", tName);
				DispatchKeyValueVector(entity, "origin", Origin);
				DispatchKeyValueVector(entity, "angles", Angles);
				DispatchKeyValue(entity, "spotlightwidth", "10");
				DispatchKeyValue(entity, "spotlightlength", "60");
				DispatchKeyValue(entity, "spawnflags", "3");
				DispatchKeyValue(entity, "rendercolor", "255 0 255");
				DispatchKeyValue(entity, "renderamt", "125");
				DispatchKeyValue(entity, "maxspeed", "100");
				DispatchKeyValue(entity, "HDRColorScale", "0.7");
				DispatchKeyValue(entity, "fadescale", "1");
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);
				SetVariantString(tName);
				AcceptEntityInput(entity, "SetParent", entity, entity, 0);
				SetVariantString("mouth");
				AcceptEntityInput(entity, "SetParentAttachment", -1, -1, 0);
				AcceptEntityInput(entity, "Enable", -1, -1, 0);
				AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
				SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
				TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	return Action:0;
}

public Action:MemeTankTimer2(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 2550)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					SetEntityRenderColor(ent[count], 225, 0, 255, 255);
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:BossTankTimer(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 50)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new entity = CreateEntityByName("beam_spotlight", -1);
			if (IsValidEntity(entity))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(entity, "targetname", "LightEntity");
				DispatchKeyValue(entity, "parentname", tName);
				DispatchKeyValueVector(entity, "origin", Origin);
				DispatchKeyValueVector(entity, "angles", Angles);
				DispatchKeyValue(entity, "spotlightwidth", "10");
				DispatchKeyValue(entity, "spotlightlength", "60");
				DispatchKeyValue(entity, "spawnflags", "3");
				DispatchKeyValue(entity, "rendercolor", "0 175 255");
				DispatchKeyValue(entity, "renderamt", "125");
				DispatchKeyValue(entity, "maxspeed", "100");
				DispatchKeyValue(entity, "HDRColorScale", "0.7");
				DispatchKeyValue(entity, "fadescale", "1");
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);
				SetVariantString(tName);
				AcceptEntityInput(entity, "SetParent", entity, entity, 0);
				SetVariantString("mouth");
				AcceptEntityInput(entity, "SetParentAttachment", -1, -1, 0);
				AcceptEntityInput(entity, "Enable", -1, -1, 0);
				AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
				SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
				TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	return Action:0;
}

public Action:BossTankTimer2(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 50)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					SetEntityRenderColor(ent[count], 25, 25, 25, 255);
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:SpypsyTankTimer(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 255)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new entity = CreateEntityByName("beam_spotlight", -1);
			if (IsValidEntity(entity))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(entity, "targetname", "LightEntity");
				DispatchKeyValue(entity, "parentname", tName);
				DispatchKeyValueVector(entity, "origin", Origin);
				DispatchKeyValueVector(entity, "angles", Angles);
				DispatchKeyValue(entity, "spotlightwidth", "10");
				DispatchKeyValue(entity, "spotlightlength", "60");
				DispatchKeyValue(entity, "spawnflags", "3");
				DispatchKeyValue(entity, "rendercolor", "255 255 0");
				DispatchKeyValue(entity, "renderamt", "125");
				DispatchKeyValue(entity, "maxspeed", "100");
				DispatchKeyValue(entity, "HDRColorScale", "0.7");
				DispatchKeyValue(entity, "fadescale", "1");
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);
				SetVariantString(tName);
				AcceptEntityInput(entity, "SetParent", entity, entity, 0);
				SetVariantString("mouth");
				AcceptEntityInput(entity, "SetParentAttachment", -1, -1, 0);
				AcceptEntityInput(entity, "Enable", -1, -1, 0);
				AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
				SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
				TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	return Action:0;
}

public Action:SpypsyTankTimer2(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 255)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					SetEntityRenderColor(ent[count], 255, 100, 0, 255);
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:SipowTankTimer(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 255125)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new entity = CreateEntityByName("beam_spotlight", -1);
			if (IsValidEntity(entity))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(entity, "targetname", "LightEntity");
				DispatchKeyValue(entity, "parentname", tName);
				DispatchKeyValueVector(entity, "origin", Origin);
				DispatchKeyValueVector(entity, "angles", Angles);
				DispatchKeyValue(entity, "spotlightwidth", "10");
				DispatchKeyValue(entity, "spotlightlength", "60");
				DispatchKeyValue(entity, "spawnflags", "3");
				DispatchKeyValue(entity, "rendercolor", "255 0 0");
				DispatchKeyValue(entity, "renderamt", "125");
				DispatchKeyValue(entity, "maxspeed", "100");
				DispatchKeyValue(entity, "HDRColorScale", "0.7");
				DispatchKeyValue(entity, "fadescale", "1");
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);
				SetVariantString(tName);
				AcceptEntityInput(entity, "SetParent", entity, entity, 0);
				SetVariantString("mouth");
				AcceptEntityInput(entity, "SetParentAttachment", -1, -1, 0);
				AcceptEntityInput(entity, "Enable", -1, -1, 0);
				AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
				SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
				TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	return Action:0;
}

public Action:SipowTankTimer2(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 255125)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					SetEntityRenderColor(ent[count], 225, 0, 0, 255);
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:PsychoticTankTimer(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color)
		{
		}
		else
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					SetEntityRenderColor(ent[count], 200, 0, 0, 255);
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:PsychoticTankTimer2(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color)
		{
		}
		else
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new entity = CreateEntityByName("beam_spotlight", -1);
			if (IsValidEntity(entity))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(entity, "targetname", "LightEntity");
				DispatchKeyValue(entity, "parentname", tName);
				DispatchKeyValueVector(entity, "origin", Origin);
				DispatchKeyValueVector(entity, "angles", Angles);
				DispatchKeyValue(entity, "spotlightwidth", "10");
				DispatchKeyValue(entity, "spotlightlength", "60");
				DispatchKeyValue(entity, "spawnflags", "3");
				DispatchKeyValue(entity, "rendercolor", "255 0 0");
				DispatchKeyValue(entity, "renderamt", "125");
				DispatchKeyValue(entity, "maxspeed", "100");
				DispatchKeyValue(entity, "HDRColorScale", "0.7");
				DispatchKeyValue(entity, "fadescale", "1");
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);
				SetVariantString(tName);
				AcceptEntityInput(entity, "SetParent", entity, entity, 0);
				SetVariantString("mouth");
				AcceptEntityInput(entity, "SetParentAttachment", -1, -1, 0);
				AcceptEntityInput(entity, "Enable", -1, -1, 0);
				AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
				SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
				TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	return Action:0;
}

public Action:ArmageddonTankTimer(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 7500)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					SetEntityRenderColor(ent[count], 25, 25, 25, 255);
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:GoliathTankTimer(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 100)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					SetEntityRenderColor(ent[count], 25, 25, 25, 255);
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:TrapTankTimer(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 5512570)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			new ent[5];
			new count = 1;
			while (count <= 4)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					SetEntityRenderColor(ent[count], 25, 25, 25, 255);
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("relbow");
						}
						case 2:
						{
							SetVariantString("lelbow");
						}
						case 3:
						{
							SetVariantString("rshoulder");
						}
						case 4:
						{
							SetVariantString("lshoulder");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					switch (count)
					{
						case 1, 2:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.4, 0);
						}
						case 3, 4:
						{
							SetEntPropFloat(ent[count], PropType:1, "m_flModelWidthScale", 0.5, 0);
						}
						default:
						{
						}
					}
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:TrapTankTimer2(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 5512570)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new entity = CreateEntityByName("beam_spotlight", -1);
			if (IsValidEntity(entity))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(entity, "targetname", "LightEntity");
				DispatchKeyValue(entity, "parentname", tName);
				DispatchKeyValueVector(entity, "origin", Origin);
				DispatchKeyValueVector(entity, "angles", Angles);
				DispatchKeyValue(entity, "spotlightwidth", "10");
				DispatchKeyValue(entity, "spotlightlength", "60");
				DispatchKeyValue(entity, "spawnflags", "3");
				DispatchKeyValue(entity, "rendercolor", "255 255 255");
				DispatchKeyValue(entity, "renderamt", "125");
				DispatchKeyValue(entity, "maxspeed", "100");
				DispatchKeyValue(entity, "HDRColorScale", "0.7");
				DispatchKeyValue(entity, "fadescale", "1");
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);
				SetVariantString(tName);
				AcceptEntityInput(entity, "SetParent", entity, entity, 0);
				SetVariantString("mouth");
				AcceptEntityInput(entity, "SetParentAttachment", -1, -1, 0);
				AcceptEntityInput(entity, "Enable", -1, -1, 0);
				AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
				SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
				TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	return Action:0;
}

public Action:JumperTankTimer(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 2002550)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + 90.0;
			new ent[3];
			new count = 1;
			while (count <= 2)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_vehicles/tire001c_car.mdl");
					DispatchKeyValue(ent[count], "targetname", "TireEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("rfoot");
						}
						case 2:
						{
							SetVariantString("lfoot");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:PsychoticTankTimer3(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color)
		{
		}
		else
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + 90.0;
			new ent[3];
			new count = 1;
			while (count <= 2)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_vehicles/tire001c_car.mdl");
					SetEntityRenderColor(ent[count], 200, 0, 0, 255);
					DispatchKeyValue(ent[count], "targetname", "TireEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("rfoot");
						}
						case 2:
						{
							SetVariantString("lfoot");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
		}
	}
	return Action:0;
}

public Action:MemeTankTimer3(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 2550)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + 90.0;
			new ent[3];
			new count = 1;
			while (count <= 2)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_vehicles/tire001c_car.mdl");
					SetEntityRenderColor(ent[count], 255, 0, 255, 255);
					DispatchKeyValue(ent[count], "targetname", "TireEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("rfoot");
						}
						case 2:
						{
							SetVariantString("lfoot");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
			new blackhole = CreateEntityByName("point_push", -1);
			if (IsValidEntity(blackhole))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(blackhole, "targetname", "BlackholeEntity");
				DispatchKeyValue(blackhole, "parentname", tName);
				DispatchKeyValueVector(blackhole, "origin", Origin);
				DispatchKeyValueVector(blackhole, "angles", Angles);
				DispatchKeyValue(blackhole, "radius", "750");
				DispatchKeyValueFloat(blackhole, "magnitude", flMemePullForce);
				DispatchKeyValue(blackhole, "spawnflags", "8");
				SetVariantString(tName);
				AcceptEntityInput(blackhole, "SetParent", blackhole, blackhole, 0);
				AcceptEntityInput(blackhole, "Enable", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:BossTankTimer3(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 50)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + 90.0;
			new ent[3];
			new count = 1;
			while (count <= 2)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override", -1);
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, 64, "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
					DispatchKeyValue(ent[count], "model", "models/props_vehicles/tire001c_car.mdl");
					SetEntityRenderColor(ent[count], 25, 25, 25, 255);
					DispatchKeyValue(ent[count], "targetname", "TireEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count], 0);
					switch (count)
					{
						case 1:
						{
							SetVariantString("rfoot");
						}
						case 2:
						{
							SetVariantString("lfoot");
						}
						default:
						{
						}
					}
					AcceptEntityInput(ent[count], "SetParentAttachment", -1, -1, 0);
					AcceptEntityInput(ent[count], "Enable", -1, -1, 0);
					AcceptEntityInput(ent[count], "DisableCollision", -1, -1, 0);
					SetEntProp(ent[count], PropType:0, "m_hOwnerEntity", client, 4, 0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
				count++;
			}
			new blackhole = CreateEntityByName("point_push", -1);
			if (IsValidEntity(blackhole))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(blackhole, "targetname", "BlackholeEntity");
				DispatchKeyValue(blackhole, "parentname", tName);
				DispatchKeyValueVector(blackhole, "origin", Origin);
				DispatchKeyValueVector(blackhole, "angles", Angles);
				DispatchKeyValue(blackhole, "radius", "1000");
				DispatchKeyValueFloat(blackhole, "magnitude", flBossPullForce);
				DispatchKeyValue(blackhole, "spawnflags", "8");
				SetVariantString(tName);
				AcceptEntityInput(blackhole, "SetParent", blackhole, blackhole, 0);
				AcceptEntityInput(blackhole, "Enable", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:GravityTankTimer(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 333435)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new entity = CreateEntityByName("beam_spotlight", -1);
			if (IsValidEntity(entity))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(entity, "targetname", "LightEntity");
				DispatchKeyValue(entity, "parentname", tName);
				DispatchKeyValueVector(entity, "origin", Origin);
				DispatchKeyValueVector(entity, "angles", Angles);
				DispatchKeyValue(entity, "spotlightwidth", "10");
				DispatchKeyValue(entity, "spotlightlength", "60");
				DispatchKeyValue(entity, "spawnflags", "3");
				DispatchKeyValue(entity, "rendercolor", "100 100 100");
				DispatchKeyValue(entity, "renderamt", "125");
				DispatchKeyValue(entity, "maxspeed", "100");
				DispatchKeyValue(entity, "HDRColorScale", "0.7");
				DispatchKeyValue(entity, "fadescale", "1");
				DispatchKeyValue(entity, "fademindist", "-1");
				DispatchSpawn(entity);
				SetVariantString(tName);
				AcceptEntityInput(entity, "SetParent", entity, entity, 0);
				SetVariantString("mouth");
				AcceptEntityInput(entity, "SetParentAttachment", -1, -1, 0);
				AcceptEntityInput(entity, "Enable", -1, -1, 0);
				AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
				SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
				TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
			}
			new blackhole = CreateEntityByName("point_push", -1);
			if (IsValidEntity(blackhole))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(blackhole, "targetname", "BlackholeEntity");
				DispatchKeyValue(blackhole, "parentname", tName);
				DispatchKeyValueVector(blackhole, "origin", Origin);
				DispatchKeyValueVector(blackhole, "angles", Angles);
				DispatchKeyValue(blackhole, "radius", "750");
				DispatchKeyValueFloat(blackhole, "magnitude", flGravityPullForce);
				DispatchKeyValue(blackhole, "spawnflags", "8");
				SetVariantString(tName);
				AcceptEntityInput(blackhole, "SetParent", blackhole, blackhole, 0);
				AcceptEntityInput(blackhole, "Enable", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:ArmageddonTankTimer2(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 7500)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new blackhole = CreateEntityByName("point_push", -1);
			if (IsValidEntity(blackhole))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(blackhole, "targetname", "BlackholeEntity");
				DispatchKeyValue(blackhole, "parentname", tName);
				DispatchKeyValueVector(blackhole, "origin", Origin);
				DispatchKeyValueVector(blackhole, "angles", Angles);
				DispatchKeyValue(blackhole, "radius", "1000");
				DispatchKeyValueFloat(blackhole, "magnitude", flArmageddonPullForce);
				DispatchKeyValue(blackhole, "spawnflags", "8");
				SetVariantString(tName);
				AcceptEntityInput(blackhole, "SetParent", blackhole, blackhole, 0);
				AcceptEntityInput(blackhole, "Enable", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:FeedbackTankTimer(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 906090)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetEntPropVector(client, PropType:0, "m_vecOrigin", Origin, 0);
			GetEntPropVector(client, PropType:0, "m_angRotation", Angles, 0);
			Angles[0] = Angles[0] + -90.0;
			new blackhole = CreateEntityByName("point_push", -1);
			if (IsValidEntity(blackhole))
			{
				decl String:tName[64];
				Format(tName, 64, "Tank%d", client);
				DispatchKeyValue(client, "targetname", tName);
				GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
				DispatchKeyValue(blackhole, "targetname", "BlackholeEntity");
				DispatchKeyValue(blackhole, "parentname", tName);
				DispatchKeyValueVector(blackhole, "origin", Origin);
				DispatchKeyValueVector(blackhole, "angles", Angles);
				DispatchKeyValue(blackhole, "radius", "1000");
				DispatchKeyValueFloat(blackhole, "magnitude", flFeedbackPushForce);
				DispatchKeyValue(blackhole, "spawnflags", "8");
				SetVariantString(tName);
				AcceptEntityInput(blackhole, "SetParent", blackhole, blackhole, 0);
				AcceptEntityInput(blackhole, "Enable", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:BlurEffect(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client) && TankAbility[client] == 1)
	{
		new Float:TankPos[3] = 0.0;
		new Float:TankAng[3] = 0.0;
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, PropType:0, "m_nSequence", 4, 0);
		new entity = CreateEntityByName("prop_dynamic", -1);
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "6");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
			SetEntityRenderColor(entity, 0, 105, 255, 50);
			SetEntProp(entity, PropType:0, "m_nSequence", Anim, 4, 0);
			SetEntPropFloat(entity, PropType:0, "m_flPlaybackRate", 5.0, 0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect, entity, 2);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:RemoveBlurEffect(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "prop_dynamic", true))
		{
			decl String:model[128];
			GetEntPropString(entity, PropType:1, "m_ModelName", model, 128, 0);
			if (StrEqual(model, "models/infected/hulk.mdl", true))
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:BlurEffect2(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client) && TankAbility[client] == 1)
	{
		new Float:TankPos[3] = 0.0;
		new Float:TankAng[3] = 0.0;
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, PropType:0, "m_nSequence", 4, 0);
		new entity = CreateEntityByName("prop_dynamic", -1);
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "25");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
			SetEntityRenderColor(entity, 255, 0, 0, 50);
			SetEntProp(entity, PropType:0, "m_nSequence", Anim, 4, 0);
			SetEntPropFloat(entity, PropType:0, "m_flPlaybackRate", 5.0, 0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect2, entity, 2);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:RemoveBlurEffect2(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "prop_dynamic", true))
		{
			decl String:model[128];
			GetEntPropString(entity, PropType:1, "m_ModelName", model, 128, 0);
			if (StrEqual(model, "models/infected/hulk.mdl", true))
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:BlurEffect3(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client) && TankAbility[client] == 1)
	{
		new Float:TankPos[3] = 0.0;
		new Float:TankAng[3] = 0.0;
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, PropType:0, "m_nSequence", 4, 0);
		new entity = CreateEntityByName("prop_dynamic", -1);
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "25");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
			SetEntityRenderColor(entity, 255, 255, 0, 50);
			SetEntProp(entity, PropType:0, "m_nSequence", Anim, 4, 0);
			SetEntPropFloat(entity, PropType:0, "m_flPlaybackRate", 5.0, 0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect3, entity, 2);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:RemoveBlurEffect3(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "prop_dynamic", true))
		{
			decl String:model[128];
			GetEntPropString(entity, PropType:1, "m_ModelName", model, 128, 0);
			if (StrEqual(model, "models/infected/hulk.mdl", true))
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:BlurEffect4(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client) && TankAbility[client] == 1)
	{
		new Float:TankPos[3] = 0.0;
		new Float:TankAng[3] = 0.0;
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, PropType:0, "m_nSequence", 4, 0);
		new entity = CreateEntityByName("prop_dynamic", -1);
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "25");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
			SetEntityRenderColor(entity, 1, 1, 1, 50);
			SetEntProp(entity, PropType:0, "m_nSequence", Anim, 4, 0);
			SetEntPropFloat(entity, PropType:0, "m_flPlaybackRate", 5.0, 0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect4, entity, 2);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:RemoveBlurEffect4(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "prop_dynamic", true))
		{
			decl String:model[128];
			GetEntPropString(entity, PropType:1, "m_ModelName", model, 128, 0);
			if (StrEqual(model, "models/infected/hulk.mdl", true))
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:BlurEffect5(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client) && TankAbility[client] == 1)
	{
		new Float:TankPos[3] = 0.0;
		new Float:TankAng[3] = 0.0;
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, PropType:0, "m_nSequence", 4, 0);
		new entity = CreateEntityByName("prop_dynamic", -1);
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "25");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
			SetEntityRenderColor(entity, 255, 100, 255, 50);
			SetEntProp(entity, PropType:0, "m_nSequence", Anim, 4, 0);
			SetEntPropFloat(entity, PropType:0, "m_flPlaybackRate", 5.0, 0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect5, entity, 2);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:RemoveBlurEffect5(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "prop_dynamic", true))
		{
			decl String:model[128];
			GetEntPropString(entity, PropType:1, "m_ModelName", model, 128, 0);
			if (StrEqual(model, "models/infected/hulk.mdl", true))
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:BlurEffect6(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client) && TankAbility[client] == 1)
	{
		new Float:TankPos[3] = 0.0;
		new Float:TankAng[3] = 0.0;
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, PropType:0, "m_nSequence", 4, 0);
		new entity = CreateEntityByName("prop_dynamic", -1);
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "25");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
			SetEntityRenderColor(entity, 0, 255, 0, 50);
			SetEntProp(entity, PropType:0, "m_nSequence", Anim, 4, 0);
			SetEntPropFloat(entity, PropType:0, "m_flPlaybackRate", 5.0, 0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect6, entity, 2);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:RemoveBlurEffect6(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "prop_dynamic", true))
		{
			decl String:model[128];
			GetEntPropString(entity, PropType:1, "m_ModelName", model, 128, 0);
			if (StrEqual(model, "models/infected/hulk.mdl", true))
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:BlurEffect7(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client) && TankAbility[client] == 1)
	{
		new Float:TankPos[3] = 0.0;
		new Float:TankAng[3] = 0.0;
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, PropType:0, "m_nSequence", 4, 0);
		new entity = CreateEntityByName("prop_dynamic", -1);
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "25");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
			SetEntityRenderColor(entity, 0, 0, 50, 50);
			SetEntProp(entity, PropType:0, "m_nSequence", Anim, 4, 0);
			SetEntPropFloat(entity, PropType:0, "m_flPlaybackRate", 5.0, 0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect7, entity, 2);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:RemoveBlurEffect7(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "prop_dynamic", true))
		{
			decl String:model[128];
			GetEntPropString(entity, PropType:1, "m_ModelName", model, 128, 0);
			if (StrEqual(model, "models/infected/hulk.mdl", true))
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:BlurEffect8(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client) && TankAbility[client] == 1)
	{
		new Float:TankPos[3] = 0.0;
		new Float:TankAng[3] = 0.0;
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, PropType:0, "m_nSequence", 4, 0);
		new entity = CreateEntityByName("prop_dynamic", -1);
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "25");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
			SetEntityRenderColor(entity, 0, 0, 255, 50);
			SetEntProp(entity, PropType:0, "m_nSequence", Anim, 4, 0);
			SetEntPropFloat(entity, PropType:0, "m_flPlaybackRate", 5.0, 0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect8, entity, 2);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:RemoveBlurEffect8(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "prop_dynamic", true))
		{
			decl String:model[128];
			GetEntPropString(entity, PropType:1, "m_ModelName", model, 128, 0);
			if (StrEqual(model, "models/infected/hulk.mdl", true))
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:BlurEffect9(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client) && TankAbility[client] == 1)
	{
		new Float:TankPos[3] = 0.0;
		new Float:TankAng[3] = 0.0;
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, PropType:0, "m_nSequence", 4, 0);
		new entity = CreateEntityByName("prop_dynamic", -1);
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "25");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
			SetEntityRenderColor(entity, 100, 50, 50, 50);
			SetEntProp(entity, PropType:0, "m_nSequence", Anim, 4, 0);
			SetEntPropFloat(entity, PropType:0, "m_flPlaybackRate", 5.0, 0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect9, entity, 2);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:RemoveBlurEffect9(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "prop_dynamic", true))
		{
			decl String:model[128];
			GetEntPropString(entity, PropType:1, "m_ModelName", model, 128, 0);
			if (StrEqual(model, "models/infected/hulk.mdl", true))
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public Action:BlurEffect10(Handle:timer, any:client)
{
	
	if (client > any:0 && IsTank(client) && TankAbility[client] == 1)
	{
		new Float:TankPos[3] = 0.0;
		new Float:TankAng[3] = 0.0;
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, PropType:0, "m_nSequence", 4, 0);
		new entity = CreateEntityByName("prop_dynamic", -1);
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "25");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision", -1, -1, 0);
			SetEntityRenderColor(entity, 25, 40, 25, 50);
			SetEntProp(entity, PropType:0, "m_nSequence", Anim, 4, 0);
			SetEntPropFloat(entity, PropType:0, "m_flPlaybackRate", 5.0, 0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect10, entity, 2);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:RemoveBlurEffect10(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "prop_dynamic", true))
		{
			decl String:model[128];
			GetEntPropString(entity, PropType:1, "m_ModelName", model, 128, 0);
			if (StrEqual(model, "models/infected/hulk.mdl", true))
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
			}
		}
	}
	return Action:0;
}

public SkillSmashClaw(target)
{
	new health = GetEntProp(target, PropType:1, "m_iHealth", 4, 0);
	
	if (health > 1 && !IsPlayerIncap(target))
	{
		SetEntProp(target, PropType:1, "m_iHealth", iSmasherMaimDamage, 4, 0);
		new Float:hbuffer = float(health) - float(iSmasherMaimDamage);
		if (hbuffer > 0.0)
		{
			SetEntPropFloat(target, PropType:0, "m_healthBuffer", hbuffer, 0);
		}
	}
	EmitSoundToAll("player/charger/hit/charger_smash_02.wav", target, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	ScreenShake(target, 30.0);
	return 0;
}

public SkillSmashClawKill(client, attacker)
{
	EmitSoundToAll("player/tank/voice/growl/tank_climb_01.wav", attacker, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	AttachParticle(client, "boomer_explode", 0.1, 0.0);
	DealDamagePlayer(client, attacker, 2, iSmasherCrushDamage);
	DealDamagePlayer(client, attacker, 2, iSmasherCrushDamage);
	CreateTimer(0.1, RemoveDeathBody, client, 2);
	return 0;
}

public Action:RemoveDeathBody(Handle:timer, any:client)
{
	if (bSmasherRemoveBody)
	{
		if (any:0 < client)
		{
			
			if (IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				new entity = -1;
				while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != -1)
				{
					new owner = GetEntPropEnt(entity, PropType:0, "m_hOwnerEntity", 0);
					if (owner == client)
					{
						AcceptEntityInput(entity, "Kill", -1, -1, 0);
					}
				}
			}
		}
	}
	return Action:0;
}

public SkillArmageddonClaw(target)
{
	new health = GetEntProp(target, PropType:1, "m_iHealth", 4, 0);
	
	if (health > 1 && !IsPlayerIncap(target))
	{
		SetEntProp(target, PropType:1, "m_iHealth", iArmageddonMaimDamage, 4, 0);
		new Float:hbuffer = float(health) - float(iArmageddonMaimDamage);
		if (hbuffer > 0.0)
		{
			SetEntPropFloat(target, PropType:0, "m_healthBuffer", hbuffer, 0);
		}
	}
	EmitSoundToAll("player/charger/hit/charger_smash_02.wav", target, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	ScreenShake(target, 30.0);
	return 0;
}

public SkillArmageddonClawKill(client, attacker)
{
	EmitSoundToAll("player/tank/voice/growl/tank_climb_01.wav", attacker, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	AttachParticle(client, "boomer_explode", 0.1, 0.0);
	DealDamagePlayer(client, attacker, 2, iArmageddonCrushDamage);
	DealDamagePlayer(client, attacker, 2, iArmageddonCrushDamage);
	CreateTimer(0.1, RemoveDeathBody2, client, 2);
	return 0;
}

public Action:RemoveDeathBody2(Handle:timer, any:client)
{
	if (bArmageddonRemoveBody)
	{
		if (any:0 < client)
		{
			
			if (IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				new entity = -1;
				while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != -1)
				{
					new owner = GetEntPropEnt(entity, PropType:0, "m_hOwnerEntity", 0);
					if (owner == client)
					{
						AcceptEntityInput(entity, "Kill", -1, -1, 0);
					}
				}
			}
		}
	}
	return Action:0;
}

public SkillTrapClaw(target)
{
	new health = GetEntProp(target, PropType:1, "m_iHealth", 4, 0);
	
	if (health > 1 && !IsPlayerIncap(target))
	{
		SetEntProp(target, PropType:1, "m_iHealth", iTrapMaimDamage, 4, 0);
		new Float:hbuffer = float(health) - float(iTrapMaimDamage);
		if (hbuffer > 0.0)
		{
			SetEntPropFloat(target, PropType:0, "m_healthBuffer", hbuffer, 0);
		}
	}
	EmitSoundToAll("player/charger/hit/charger_smash_02.wav", target, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	ScreenShake(target, 30.0);
	return 0;
}

public SkillTrapClawKill(client, attacker)
{
	EmitSoundToAll("player/tank/voice/growl/tank_climb_01.wav", attacker, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	AttachParticle(client, "boomer_explode", 0.1, 0.0);
	DealDamagePlayer(client, attacker, 2, iTrapCrushDamage);
	DealDamagePlayer(client, attacker, 2, iTrapCrushDamage);
	CreateTimer(0.1, RemoveDeathBody3, client, 2);
	return 0;
}

public Action:RemoveDeathBody3(Handle:timer, any:client)
{
	if (bTrapRemoveBody)
	{
		if (any:0 < client)
		{
			
			if (IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				new entity = -1;
				while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != -1)
				{
					new owner = GetEntPropEnt(entity, PropType:0, "m_hOwnerEntity", 0);
					if (owner == client)
					{
						AcceptEntityInput(entity, "Kill", -1, -1, 0);
					}
				}
			}
		}
	}
	return Action:0;
}

public SkillGoliathClaw(target)
{
	new health = GetEntProp(target, PropType:1, "m_iHealth", 4, 0);
	
	if (health > 1 && !IsPlayerIncap(target))
	{
		SetEntProp(target, PropType:1, "m_iHealth", iGoliathMaimDamage, 4, 0);
		new Float:hbuffer = float(health) - float(iGoliathMaimDamage);
		if (hbuffer > 0.0)
		{
			SetEntPropFloat(target, PropType:0, "m_healthBuffer", hbuffer, 0);
		}
	}
	EmitSoundToAll("player/charger/hit/charger_smash_02.wav", target, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	ScreenShake(target, 30.0);
	return 0;
}

public SkillGoliathClawKill(client, attacker)
{
	EmitSoundToAll("player/tank/voice/growl/tank_climb_01.wav", attacker, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	AttachParticle(client, "boomer_explode", 0.1, 0.0);
	DealDamagePlayer(client, attacker, 2, iGoliathCrushDamage);
	DealDamagePlayer(client, attacker, 2, iGoliathCrushDamage);
	CreateTimer(0.1, RemoveDeathBody4, client, 2);
	return 0;
}

public Action:RemoveDeathBody4(Handle:timer, any:client)
{
	if (bGoliathRemoveBody)
	{
		if (any:0 < client)
		{
			
			if (IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				new entity = -1;
				while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != -1)
				{
					new owner = GetEntPropEnt(entity, PropType:0, "m_hOwnerEntity", 0);
					if (owner == client)
					{
						AcceptEntityInput(entity, "Kill", -1, -1, 0);
					}
				}
			}
		}
	}
	return Action:0;
}

public SkillMemeClaw(target)
{
	new health = GetEntProp(target, PropType:1, "m_iHealth", 4, 0);
	
	if (health > 1 && !IsPlayerIncap(target))
	{
		SetEntProp(target, PropType:1, "m_iHealth", iMemeMaimDamage, 4, 0);
		new Float:hbuffer = float(health) - float(iMemeMaimDamage);
		if (hbuffer > 0.0)
		{
			SetEntPropFloat(target, PropType:0, "m_healthBuffer", hbuffer, 0);
		}
	}
	EmitSoundToAll("player/charger/hit/charger_smash_02.wav", target, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	ScreenShake(target, 30.0);
	return 0;
}

public SkillMemeClawKill(client, attacker)
{
	EmitSoundToAll("player/tank/voice/growl/tank_climb_01.wav", attacker, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	AttachParticle(client, "boomer_explode", 0.1, 0.0);
	DealDamagePlayer(client, attacker, 2, iMemeCrushDamage);
	DealDamagePlayer(client, attacker, 2, iMemeCrushDamage);
	CreateTimer(0.1, RemoveDeathBody5, client, 2);
	return 0;
}

public Action:RemoveDeathBody5(Handle:timer, any:client)
{
	if (bMemeRemoveBody)
	{
		if (any:0 < client)
		{
			
			if (IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				new entity = -1;
				while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != -1)
				{
					new owner = GetEntPropEnt(entity, PropType:0, "m_hOwnerEntity", 0);
					if (owner == client)
					{
						AcceptEntityInput(entity, "Kill", -1, -1, 0);
					}
				}
			}
		}
	}
	return Action:0;
}

public SkillBossClaw(target)
{
	new health = GetEntProp(target, PropType:1, "m_iHealth", 4, 0);
	
	if (health > 1 && !IsPlayerIncap(target))
	{
		SetEntProp(target, PropType:1, "m_iHealth", iBossMaimDamage, 4, 0);
		new Float:hbuffer = float(health) - float(iBossMaimDamage);
		if (hbuffer > 0.0)
		{
			SetEntPropFloat(target, PropType:0, "m_healthBuffer", hbuffer, 0);
		}
	}
	EmitSoundToAll("player/charger/hit/charger_smash_02.wav", target, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	ScreenShake(target, 30.0);
	return 0;
}

public SkillBossClawKill(client, attacker)
{
	EmitSoundToAll("player/tank/voice/growl/tank_climb_01.wav", attacker, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	AttachParticle(client, "boomer_explode", 0.1, 0.0);
	DealDamagePlayer(client, attacker, 2, iBossCrushDamage);
	DealDamagePlayer(client, attacker, 2, iBossCrushDamage);
	CreateTimer(0.1, RemoveDeathBody6, client, 2);
	return 0;
}

public Action:RemoveDeathBody6(Handle:timer, any:client)
{
	if (bBossRemoveBody)
	{
		if (any:0 < client)
		{
			
			if (IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				new entity = -1;
				while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != -1)
				{
					new owner = GetEntPropEnt(entity, PropType:0, "m_hOwnerEntity", 0);
					if (owner == client)
					{
						AcceptEntityInput(entity, "Kill", -1, -1, 0);
					}
				}
			}
		}
	}
	return Action:0;
}

public SkillElecClaw(target, tank)
{
	if (0 < target)
	{
		
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			PlayerSpeed[target] += 3;
			new Handle:Pack = CreateDataPack();
			WritePackCell(Pack, target);
			WritePackCell(Pack, tank);
			WritePackCell(Pack, any:4);
			CreateTimer(5.0, Timer_Volt, Pack, 3);
			ScreenShake(target, 15.0);
			AttachParticle(target, "electrical_arc_01_parent", 2.0, 30.0);
			EmitSoundToAll("ambient/energy/zap1.wav", target, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	return 0;
}

public SkillFeedbackClaw(target, tank)
{
	if (0 < target)
	{
		
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			PlayerSpeed[target] += 3;
			new Handle:Pack = CreateDataPack();
			WritePackCell(Pack, target);
			WritePackCell(Pack, tank);
			WritePackCell(Pack, any:4);
			CreateTimer(5.0, Timer_Volt2, Pack, 3);
			ScreenShake(target, 15.0);
			AttachParticle(target, "electrical_arc_01_parent", 2.0, 30.0);
			EmitSoundToAll("ambient/energy/zap1.wav", target, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	return 0;
}

public Action:Timer_Volt(Handle:timer, any:Pack)
{
	ResetPack(Pack, false);
	new client = ReadPackCell(Pack);
	new tank = ReadPackCell(Pack);
	new amount = ReadPackCell(Pack);
	
	if (client > 0 && tank > 0)
	{
		
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && PlayerSpeed[client] && IsTank(tank))
		{
			if (0 < amount)
			{
				PlayerSpeed[client] += 2;
				ScreenShake(client, 2.0);
				DealDamagePlayer(client, tank, 2, iShockStunDamage);
				AttachParticle(client, "electrical_arc_01_parent", 2.0, 30.0);
				new random = GetRandomInt(1, 2);
				if (random == 1)
				{
					EmitSoundToAll("ambient/energy/zap5.wav", client, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				}
				else
				{
					EmitSoundToAll("ambient/energy/zap7.wav", client, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				}
				ResetPack(Pack, true);
				WritePackCell(Pack, client);
				WritePackCell(Pack, tank);
				WritePackCell(Pack, amount + -1);
				return Action:0;
			}
		}
	}
	CloseHandle(Pack);
	return Action:4;
}

public Action:Timer_Volt2(Handle:timer, any:Pack)
{
	ResetPack(Pack, false);
	new client = ReadPackCell(Pack);
	new tank = ReadPackCell(Pack);
	new amount = ReadPackCell(Pack);
	
	if (client > 0 && tank > 0)
	{
		
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && PlayerSpeed[client] && IsTank(tank))
		{
			if (0 < amount)
			{
				PlayerSpeed[client] += 2;
				ScreenShake(client, 2.0);
				DealDamagePlayer(client, tank, 2, iFeedbackStunDamage);
				AttachParticle(client, "electrical_arc_01_parent", 2.0, 30.0);
				new random = GetRandomInt(1, 2);
				if (random == 1)
				{
					EmitSoundToAll("ambient/energy/zap5.wav", client, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				}
				else
				{
					EmitSoundToAll("ambient/energy/zap7.wav", client, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				}
				ResetPack(Pack, true);
				WritePackCell(Pack, client);
				WritePackCell(Pack, tank);
				WritePackCell(Pack, amount + -1);
				return Action:0;
			}
		}
	}
	CloseHandle(Pack);
	return Action:4;
}

StartMeteorFall(client)
{
	TankAbility[client] = 1;
	decl Float:pos[3];
	GetClientEyePosition(client, pos);
	new Handle:h = CreateDataPack();
	WritePackCell(h, client);
	WritePackFloat(h, pos[0]);
	WritePackFloat(h, pos[1]);
	WritePackFloat(h, pos[2]);
	WritePackFloat(h, GetEngineTime());
	CreateTimer(0.6, UpdateMeteorFall, h, 3);
	return 0;
}

StartArmageddonFall(client)
{
	TankAbility[client] = 1;
	decl Float:pos[3];
	GetClientEyePosition(client, pos);
	new Handle:h = CreateDataPack();
	WritePackCell(h, client);
	WritePackFloat(h, pos[0]);
	WritePackFloat(h, pos[1]);
	WritePackFloat(h, pos[2]);
	WritePackFloat(h, GetEngineTime());
	CreateTimer(0.6, UpdateArmageddonFall, h, 3);
	return 0;
}

StartPsychoticFall(client)
{
	TankAbility[client] = 1;
	decl Float:pos[3];
	GetClientEyePosition(client, pos);
	new Handle:h = CreateDataPack();
	WritePackCell(h, client);
	WritePackFloat(h, pos[0]);
	WritePackFloat(h, pos[1]);
	WritePackFloat(h, pos[2]);
	WritePackFloat(h, GetEngineTime());
	CreateTimer(0.6, UpdatePsychoticFall, h, 3);
	return 0;
}

StartMemeFall(client)
{
	TankAbility[client] = 1;
	decl Float:pos[3];
	GetClientEyePosition(client, pos);
	new Handle:h = CreateDataPack();
	WritePackCell(h, client);
	WritePackFloat(h, pos[0]);
	WritePackFloat(h, pos[1]);
	WritePackFloat(h, pos[2]);
	WritePackFloat(h, GetEngineTime());
	CreateTimer(0.6, UpdateMemeFall, h, 3);
	return 0;
}

StartBossFall(client)
{
	TankAbility[client] = 1;
	decl Float:pos[3];
	GetClientEyePosition(client, pos);
	new Handle:h = CreateDataPack();
	WritePackCell(h, client);
	WritePackFloat(h, pos[0]);
	WritePackFloat(h, pos[1]);
	WritePackFloat(h, pos[2]);
	WritePackFloat(h, GetEngineTime());
	CreateTimer(0.6, UpdateBossFall, h, 3);
	return 0;
}

StartSipowFall(client)
{
	TankAbility[client] = 1;
	decl Float:pos[3];
	GetClientEyePosition(client, pos);
	new Handle:h = CreateDataPack();
	WritePackCell(h, client);
	WritePackFloat(h, pos[0]);
	WritePackFloat(h, pos[1]);
	WritePackFloat(h, pos[2]);
	WritePackFloat(h, GetEngineTime());
	CreateTimer(0.6, UpdateSipowFall, h, 3);
	return 0;
}

public Action:UpdateMeteorFall(Handle:timer, any:h)
{
	ResetPack(h, false);
	decl Float:pos[3];
	new client = ReadPackCell(h);
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);
	new Float:time = ReadPackFloat(h);
	if (GetEngineTime() - time > 5.0)
	{
		TankAbility[client] = 0;
	}
	new entity = -1;
	
	if (IsTank(client) && TankAbility[client] == 1)
	{
		decl Float:angle[3];
		decl Float:velocity[3];
		decl Float:hitpos[3];
		angle[0] = GetRandomFloat(-20.0, 20.0) + 0.0;
		angle[1] = GetRandomFloat(-20.0, 20.0) + 0.0;
		angle[2] = 60.0;
		GetVectorAngles(angle, angle);
		GetRayHitPos(pos, angle, hitpos, client, true);
		new Float:dis = GetVectorDistance(pos, hitpos, false);
		if (GetVectorDistance(pos, hitpos, false) > 2000.0)
		{
			dis = 1600.0;
		}
		decl Float:t[3];
		MakeVectorFromPoints(pos, hitpos, t);
		NormalizeVector(t, t);
		ScaleVector(t, dis - 40.0);
		AddVectors(pos, t, hitpos);
		if (dis > 100.0)
		{
			new ent = CreateEntityByName("tank_rock", -1);
			if (0 < ent)
			{
				DispatchKeyValue(ent, "model", "models/props_debris/concrete_chunk01a.mdl");
				DispatchSpawn(ent);
				decl Float:angle2[3];
				angle2[0] = GetRandomFloat(-180.0, 180.0);
				angle2[1] = GetRandomFloat(-180.0, 180.0);
				angle2[2] = GetRandomFloat(-180.0, 180.0);
				velocity[0] = GetRandomFloat(0.0, 350.0);
				velocity[1] = GetRandomFloat(0.0, 350.0);
				velocity[2] = GetRandomFloat(0.0, 30.0);
				TeleportEntity(ent, hitpos, angle2, velocity);
				ActivateEntity(ent);
				AcceptEntityInput(ent, "Ignite", -1, -1, 0);
				SetEntProp(ent, PropType:0, "m_hOwnerEntity", client, 4, 0);
			}
		}
	}
	else
	{
		if (!TankAbility[client])
		{
			while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
			{
				new ownerent = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
				if (ownerent == client)
				{
					ExplodeMeteor(entity, ownerent);
				}
			}
			CloseHandle(h);
			return Action:4;
		}
	}
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
	{
		new ownerent = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
		if (ownerent == client)
		{
			if (OnGroundUnits(entity) < 200.0)
			{
				ExplodeMeteor(entity, ownerent);
			}
		}
	}
	return Action:0;
}

public Action:UpdateArmageddonFall(Handle:timer, any:h)
{
	ResetPack(h, false);
	decl Float:pos[3];
	new client = ReadPackCell(h);
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);
	new Float:time = ReadPackFloat(h);
	if (GetEngineTime() - time > 5.0)
	{
		TankAbility[client] = 0;
	}
	new entity = -1;
	
	if (IsTank(client) && TankAbility[client] == 1)
	{
		decl Float:angle[3];
		decl Float:velocity[3];
		decl Float:hitpos[3];
		angle[0] = GetRandomFloat(-20.0, 20.0) + 0.0;
		angle[1] = GetRandomFloat(-20.0, 20.0) + 0.0;
		angle[2] = 60.0;
		GetVectorAngles(angle, angle);
		GetRayHitPos(pos, angle, hitpos, client, true);
		new Float:dis = GetVectorDistance(pos, hitpos, false);
		if (GetVectorDistance(pos, hitpos, false) > 2000.0)
		{
			dis = 1600.0;
		}
		decl Float:t[3];
		MakeVectorFromPoints(pos, hitpos, t);
		NormalizeVector(t, t);
		ScaleVector(t, dis - 40.0);
		AddVectors(pos, t, hitpos);
		if (dis > 100.0)
		{
			new ent = CreateEntityByName("tank_rock", -1);
			if (0 < ent)
			{
				DispatchKeyValue(ent, "model", "models/props_debris/concrete_chunk01a.mdl");
				DispatchSpawn(ent);
				decl Float:angle2[3];
				angle2[0] = GetRandomFloat(-180.0, 180.0);
				angle2[1] = GetRandomFloat(-180.0, 180.0);
				angle2[2] = GetRandomFloat(-180.0, 180.0);
				velocity[0] = GetRandomFloat(0.0, 350.0);
				velocity[1] = GetRandomFloat(0.0, 350.0);
				velocity[2] = GetRandomFloat(0.0, 30.0);
				TeleportEntity(ent, hitpos, angle2, velocity);
				ActivateEntity(ent);
				AcceptEntityInput(ent, "Ignite", -1, -1, 0);
				SetEntProp(ent, PropType:0, "m_hOwnerEntity", client, 4, 0);
			}
		}
	}
	else
	{
		if (!TankAbility[client])
		{
			while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
			{
				new ownerent = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
				if (ownerent == client)
				{
					ExplodeArmageddon(entity, ownerent);
				}
			}
			CloseHandle(h);
			return Action:4;
		}
	}
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
	{
		new ownerent = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
		if (ownerent == client)
		{
			if (OnGroundUnits(entity) < 200.0)
			{
				ExplodeArmageddon(entity, ownerent);
			}
		}
	}
	return Action:0;
}

public Action:UpdatePsychoticFall(Handle:timer, any:h)
{
	ResetPack(h, false);
	decl Float:pos[3];
	new client = ReadPackCell(h);
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);
	new Float:time = ReadPackFloat(h);
	if (GetEngineTime() - time > 5.0)
	{
		TankAbility[client] = 0;
	}
	new entity = -1;
	
	if (IsTank(client) && TankAbility[client] == 1)
	{
		decl Float:angle[3];
		decl Float:velocity[3];
		decl Float:hitpos[3];
		angle[0] = GetRandomFloat(-20.0, 20.0) + 0.0;
		angle[1] = GetRandomFloat(-20.0, 20.0) + 0.0;
		angle[2] = 60.0;
		GetVectorAngles(angle, angle);
		GetRayHitPos(pos, angle, hitpos, client, true);
		new Float:dis = GetVectorDistance(pos, hitpos, false);
		if (GetVectorDistance(pos, hitpos, false) > 2000.0)
		{
			dis = 1600.0;
		}
		decl Float:t[3];
		MakeVectorFromPoints(pos, hitpos, t);
		NormalizeVector(t, t);
		ScaleVector(t, dis - 40.0);
		AddVectors(pos, t, hitpos);
		if (dis > 100.0)
		{
			new ent = CreateEntityByName("tank_rock", -1);
			if (0 < ent)
			{
				DispatchKeyValue(ent, "model", "models/props_debris/concrete_chunk01a.mdl");
				DispatchSpawn(ent);
				decl Float:angle2[3];
				angle2[0] = GetRandomFloat(-180.0, 180.0);
				angle2[1] = GetRandomFloat(-180.0, 180.0);
				angle2[2] = GetRandomFloat(-180.0, 180.0);
				velocity[0] = GetRandomFloat(0.0, 350.0);
				velocity[1] = GetRandomFloat(0.0, 350.0);
				velocity[2] = GetRandomFloat(0.0, 30.0);
				TeleportEntity(ent, hitpos, angle2, velocity);
				ActivateEntity(ent);
				AcceptEntityInput(ent, "Ignite", -1, -1, 0);
				SetEntProp(ent, PropType:0, "m_hOwnerEntity", client, 4, 0);
			}
		}
	}
	else
	{
		if (!TankAbility[client])
		{
			while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
			{
				new ownerent = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
				if (ownerent == client)
				{
					ExplodePsychotic(entity, ownerent);
				}
			}
			CloseHandle(h);
			return Action:4;
		}
	}
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
	{
		new ownerent = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
		if (ownerent == client)
		{
			if (OnGroundUnits(entity) < 200.0)
			{
				ExplodePsychotic(entity, ownerent);
			}
		}
	}
	return Action:0;
}

public Action:UpdateMemeFall(Handle:timer, any:h)
{
	ResetPack(h, false);
	decl Float:pos[3];
	new client = ReadPackCell(h);
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);
	new Float:time = ReadPackFloat(h);
	if (GetEngineTime() - time > 5.0)
	{
		TankAbility[client] = 0;
	}
	new entity = -1;
	
	if (IsTank(client) && TankAbility[client] == 1)
	{
		decl Float:angle[3];
		decl Float:velocity[3];
		decl Float:hitpos[3];
		angle[0] = GetRandomFloat(-20.0, 20.0) + 0.0;
		angle[1] = GetRandomFloat(-20.0, 20.0) + 0.0;
		angle[2] = 60.0;
		GetVectorAngles(angle, angle);
		GetRayHitPos(pos, angle, hitpos, client, true);
		new Float:dis = GetVectorDistance(pos, hitpos, false);
		if (GetVectorDistance(pos, hitpos, false) > 2000.0)
		{
			dis = 1600.0;
		}
		decl Float:t[3];
		MakeVectorFromPoints(pos, hitpos, t);
		NormalizeVector(t, t);
		ScaleVector(t, dis - 40.0);
		AddVectors(pos, t, hitpos);
		if (dis > 100.0)
		{
			new ent = CreateEntityByName("tank_rock", -1);
			if (0 < ent)
			{
				DispatchKeyValue(ent, "model", "models/props_debris/concrete_chunk01a.mdl");
				DispatchSpawn(ent);
				decl Float:angle2[3];
				angle2[0] = GetRandomFloat(-180.0, 180.0);
				angle2[1] = GetRandomFloat(-180.0, 180.0);
				angle2[2] = GetRandomFloat(-180.0, 180.0);
				velocity[0] = GetRandomFloat(0.0, 350.0);
				velocity[1] = GetRandomFloat(0.0, 350.0);
				velocity[2] = GetRandomFloat(0.0, 30.0);
				TeleportEntity(ent, hitpos, angle2, velocity);
				ActivateEntity(ent);
				AcceptEntityInput(ent, "Ignite", -1, -1, 0);
				SetEntProp(ent, PropType:0, "m_hOwnerEntity", client, 4, 0);
			}
		}
	}
	else
	{
		if (!TankAbility[client])
		{
			while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
			{
				new ownerent = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
				if (ownerent == client)
				{
					ExplodeMeme(entity, ownerent);
				}
			}
			CloseHandle(h);
			return Action:4;
		}
	}
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
	{
		new ownerent = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
		if (ownerent == client)
		{
			if (OnGroundUnits(entity) < 200.0)
			{
				ExplodeMeme(entity, ownerent);
			}
		}
	}
	return Action:0;
}

public Action:UpdateBossFall(Handle:timer, any:h)
{
	ResetPack(h, false);
	decl Float:pos[3];
	new client = ReadPackCell(h);
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);
	new Float:time = ReadPackFloat(h);
	if (GetEngineTime() - time > 5.0)
	{
		TankAbility[client] = 0;
	}
	new entity = -1;
	
	if (IsTank(client) && TankAbility[client] == 1)
	{
		decl Float:angle[3];
		decl Float:velocity[3];
		decl Float:hitpos[3];
		angle[0] = GetRandomFloat(-20.0, 20.0) + 0.0;
		angle[1] = GetRandomFloat(-20.0, 20.0) + 0.0;
		angle[2] = 60.0;
		GetVectorAngles(angle, angle);
		GetRayHitPos(pos, angle, hitpos, client, true);
		new Float:dis = GetVectorDistance(pos, hitpos, false);
		if (GetVectorDistance(pos, hitpos, false) > 2000.0)
		{
			dis = 1600.0;
		}
		decl Float:t[3];
		MakeVectorFromPoints(pos, hitpos, t);
		NormalizeVector(t, t);
		ScaleVector(t, dis - 40.0);
		AddVectors(pos, t, hitpos);
		if (dis > 100.0)
		{
			new ent = CreateEntityByName("tank_rock", -1);
			if (0 < ent)
			{
				DispatchKeyValue(ent, "model", "models/props_debris/concrete_chunk01a.mdl");
				DispatchSpawn(ent);
				decl Float:angle2[3];
				angle2[0] = GetRandomFloat(-180.0, 180.0);
				angle2[1] = GetRandomFloat(-180.0, 180.0);
				angle2[2] = GetRandomFloat(-180.0, 180.0);
				velocity[0] = GetRandomFloat(0.0, 350.0);
				velocity[1] = GetRandomFloat(0.0, 350.0);
				velocity[2] = GetRandomFloat(0.0, 30.0);
				TeleportEntity(ent, hitpos, angle2, velocity);
				ActivateEntity(ent);
				AcceptEntityInput(ent, "Ignite", -1, -1, 0);
				SetEntProp(ent, PropType:0, "m_hOwnerEntity", client, 4, 0);
			}
		}
	}
	else
	{
		if (!TankAbility[client])
		{
			while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
			{
				new ownerent = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
				if (ownerent == client)
				{
					ExplodeBoss(entity, ownerent);
				}
			}
			CloseHandle(h);
			return Action:4;
		}
	}
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
	{
		new ownerent = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
		if (ownerent == client)
		{
			if (OnGroundUnits(entity) < 200.0)
			{
				ExplodeBoss(entity, ownerent);
			}
		}
	}
	return Action:0;
}

public Action:UpdateSipowFall(Handle:timer, any:h)
{
	ResetPack(h, false);
	decl Float:pos[3];
	new client = ReadPackCell(h);
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);
	new Float:time = ReadPackFloat(h);
	if (GetEngineTime() - time > 5.0)
	{
		TankAbility[client] = 0;
	}
	new entity = -1;
	
	if (IsTank(client) && TankAbility[client] == 1)
	{
		decl Float:angle[3];
		decl Float:velocity[3];
		decl Float:hitpos[3];
		angle[0] = GetRandomFloat(-20.0, 20.0) + 0.0;
		angle[1] = GetRandomFloat(-20.0, 20.0) + 0.0;
		angle[2] = 60.0;
		GetVectorAngles(angle, angle);
		GetRayHitPos(pos, angle, hitpos, client, true);
		new Float:dis = GetVectorDistance(pos, hitpos, false);
		if (GetVectorDistance(pos, hitpos, false) > 2000.0)
		{
			dis = 1600.0;
		}
		decl Float:t[3];
		MakeVectorFromPoints(pos, hitpos, t);
		NormalizeVector(t, t);
		ScaleVector(t, dis - 40.0);
		AddVectors(pos, t, hitpos);
		if (dis > 100.0)
		{
			new ent = CreateEntityByName("tank_rock", -1);
			if (0 < ent)
			{
				DispatchKeyValue(ent, "model", "models/props_debris/concrete_chunk01a.mdl");
				DispatchSpawn(ent);
				decl Float:angle2[3];
				angle2[0] = GetRandomFloat(-180.0, 180.0);
				angle2[1] = GetRandomFloat(-180.0, 180.0);
				angle2[2] = GetRandomFloat(-180.0, 180.0);
				velocity[0] = GetRandomFloat(0.0, 350.0);
				velocity[1] = GetRandomFloat(0.0, 350.0);
				velocity[2] = GetRandomFloat(0.0, 30.0);
				TeleportEntity(ent, hitpos, angle2, velocity);
				ActivateEntity(ent);
				AcceptEntityInput(ent, "Ignite", -1, -1, 0);
				SetEntProp(ent, PropType:0, "m_hOwnerEntity", client, 4, 0);
			}
		}
	}
	else
	{
		if (!TankAbility[client])
		{
			while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
			{
				new ownerent = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
				if (ownerent == client)
				{
					ExplodeSipow(entity, ownerent);
				}
			}
			CloseHandle(h);
			return Action:4;
		}
	}
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
	{
		new ownerent = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
		if (ownerent == client)
		{
			if (OnGroundUnits(entity) < 200.0)
			{
				ExplodeMeteor(entity, ownerent);
			}
		}
	}
	return Action:0;
}

public Float:OnGroundUnits(i_Ent)
{
	if(!(GetEntityFlags(i_Ent) & (FL_ONGROUND)))
	{
		decl Handle:h_Trace;
		decl Float:f_Origin[3];
		decl Float:f_Position[3];
		//new Float:f_Down[3] = {6.4664E-41,0.0,0.0};
		new Float:f_Down[3] = { 90.0, 0.0, 0.0 };
		GetEntPropVector(i_Ent, PropType:0, "m_vecOrigin", f_Origin, 0);
		h_Trace = TR_TraceRayFilterEx(f_Origin, f_Down, 16385, RayType:1, TraceRayDontHitSelfAndLive, i_Ent);
		if (TR_DidHit(h_Trace))
		{
			decl Float:f_Units;
			TR_GetEndPosition(f_Position, h_Trace);
			f_Units = f_Origin[2] - f_Position[2];
			CloseHandle(h_Trace);
			return f_Units;
		}
		CloseHandle(h_Trace);
	}
	return 0.0;
}

GetRayHitPos(Float:pos[3], Float:angle[3], Float:hitpos[3], ent, bool:useoffset)
{
	new Handle:trace;
	new hit;
	trace = TR_TraceRayFilterEx(pos, angle, 33570827, RayType:1, TraceRayDontHitSelfAndLive, ent);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		hit = TR_GetEntityIndex(trace);
	}
	CloseHandle(trace);
	if (useoffset)
	{
		decl Float:v[3];
		MakeVectorFromPoints(hitpos, pos, v);
		NormalizeVector(v, v);
		ScaleVector(v, 15.0);
		AddVectors(hitpos, v, hitpos);
	}
	return hit;
}

ExplodeMeteor(entity, client)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, 16);
		if (!StrEqual(classname, "tank_rock", true))
		{
			return 0;
		}
		new Float:pos[3] = 0.0;
		GetEntPropVector(entity, PropType:0, "m_vecOrigin", pos, 0);
		pos[2] += 50.0;
		AcceptEntityInput(entity, "Kill", -1, -1, 0);
		new ent = CreateEntityByName("prop_physics", -1);
		DispatchKeyValue(ent, "model", "models/props_junk/propanecanister001a.mdl");
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Break", -1, -1, 0);
		new pointHurt = CreateEntityByName("point_hurt", -1);
		DispatchKeyValueFloat(pointHurt, "Damage", flMeteorStormDamage);
		DispatchKeyValue(pointHurt, "DamageType", "2");
		DispatchKeyValue(pointHurt, "DamageDelay", "0.0");
		DispatchKeyValueFloat(pointHurt, "DamageRadius", 200.0);
		DispatchSpawn(pointHurt);
		TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
		
		if (IsValidEntity(client) && IsTank(client))
		{
			AcceptEntityInput(pointHurt, "Hurt", client, -1, 0);
		}
		CreateTimer(0.1, DeletePointHurt, pointHurt, 2);
		new push = CreateEntityByName("point_push", -1);
		DispatchKeyValueFloat(push, "magnitude", 600.0);
		DispatchKeyValueFloat(push, "radius", 1.0 * 200.0);
		SetVariantString("spawnflags 24");
		AcceptEntityInput(push, "AddOutput", -1, -1, 0);
		DispatchSpawn(push);
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(push, "Enable", -1, -1, 0);
		CreateTimer(0.5, DeletePushForce, push, 2);
	}
	return 0;
}

ExplodeArmageddon(entity, client)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, 16);
		if (!StrEqual(classname, "tank_rock", true))
		{
			return 0;
		}
		new Float:pos[3] = 0.0;
		GetEntPropVector(entity, PropType:0, "m_vecOrigin", pos, 0);
		pos[2] += 50.0;
		AcceptEntityInput(entity, "Kill", -1, -1, 0);
		new ent = CreateEntityByName("prop_physics", -1);
		DispatchKeyValue(ent, "model", "models/props_junk/propanecanister001a.mdl");
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Break", -1, -1, 0);
		new pointHurt = CreateEntityByName("point_hurt", -1);
		DispatchKeyValueFloat(pointHurt, "Damage", flArmageddonStormDamage);
		DispatchKeyValue(pointHurt, "DamageType", "2");
		DispatchKeyValue(pointHurt, "DamageDelay", "0.0");
		DispatchKeyValueFloat(pointHurt, "DamageRadius", 200.0);
		DispatchSpawn(pointHurt);
		TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
		
		if (IsValidEntity(client) && IsTank(client))
		{
			AcceptEntityInput(pointHurt, "Hurt", client, -1, 0);
		}
		CreateTimer(0.1, DeletePointHurt, pointHurt, 2);
		new push = CreateEntityByName("point_push", -1);
		DispatchKeyValueFloat(push, "magnitude", 600.0);
		DispatchKeyValueFloat(push, "radius", 1.0 * 200.0);
		SetVariantString("spawnflags 24");
		AcceptEntityInput(push, "AddOutput", -1, -1, 0);
		DispatchSpawn(push);
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(push, "Enable", -1, -1, 0);
		CreateTimer(0.5, DeletePushForce, push, 2);
	}
	return 0;
}

ExplodePsychotic(entity, client)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, 16);
		if (!StrEqual(classname, "tank_rock", true))
		{
			return 0;
		}
		new Float:pos[3] = 0.0;
		GetEntPropVector(entity, PropType:0, "m_vecOrigin", pos, 0);
		pos[2] += 50.0;
		AcceptEntityInput(entity, "Kill", -1, -1, 0);
		new ent = CreateEntityByName("prop_physics", -1);
		DispatchKeyValue(ent, "model", "models/props_junk/propanecanister001a.mdl");
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Break", -1, -1, 0);
		new pointHurt = CreateEntityByName("point_hurt", -1);
		DispatchKeyValueFloat(pointHurt, "Damage", flPsychoticStormDamage);
		DispatchKeyValue(pointHurt, "DamageType", "2");
		DispatchKeyValue(pointHurt, "DamageDelay", "0.0");
		DispatchKeyValueFloat(pointHurt, "DamageRadius", 200.0);
		DispatchSpawn(pointHurt);
		TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
		
		if (IsValidEntity(client) && IsTank(client))
		{
			AcceptEntityInput(pointHurt, "Hurt", client, -1, 0);
		}
		CreateTimer(0.1, DeletePointHurt, pointHurt, 2);
		new push = CreateEntityByName("point_push", -1);
		DispatchKeyValueFloat(push, "magnitude", 600.0);
		DispatchKeyValueFloat(push, "radius", 1.0 * 200.0);
		SetVariantString("spawnflags 24");
		AcceptEntityInput(push, "AddOutput", -1, -1, 0);
		DispatchSpawn(push);
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(push, "Enable", -1, -1, 0);
		CreateTimer(0.5, DeletePushForce, push, 2);
	}
	return 0;
}

ExplodeMeme(entity, client)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, 16);
		if (!StrEqual(classname, "tank_rock", true))
		{
			return 0;
		}
		new Float:pos[3] = 0.0;
		GetEntPropVector(entity, PropType:0, "m_vecOrigin", pos, 0);
		pos[2] += 50.0;
		AcceptEntityInput(entity, "Kill", -1, -1, 0);
		new ent = CreateEntityByName("prop_physics", -1);
		DispatchKeyValue(ent, "model", "models/props_junk/propanecanister001a.mdl");
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Break", -1, -1, 0);
		new pointHurt = CreateEntityByName("point_hurt", -1);
		DispatchKeyValueFloat(pointHurt, "Damage", flMemeStormDamage);
		DispatchKeyValue(pointHurt, "DamageType", "2");
		DispatchKeyValue(pointHurt, "DamageDelay", "0.0");
		DispatchKeyValueFloat(pointHurt, "DamageRadius", 200.0);
		DispatchSpawn(pointHurt);
		TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
		
		if (IsValidEntity(client) && IsTank(client))
		{
			AcceptEntityInput(pointHurt, "Hurt", client, -1, 0);
		}
		CreateTimer(0.1, DeletePointHurt, pointHurt, 2);
		new push = CreateEntityByName("point_push", -1);
		DispatchKeyValueFloat(push, "magnitude", 600.0);
		DispatchKeyValueFloat(push, "radius", 1.0 * 200.0);
		SetVariantString("spawnflags 24");
		AcceptEntityInput(push, "AddOutput", -1, -1, 0);
		DispatchSpawn(push);
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(push, "Enable", -1, -1, 0);
		CreateTimer(0.5, DeletePushForce, push, 2);
	}
	return 0;
}

ExplodeBoss(entity, client)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, 16);
		if (!StrEqual(classname, "tank_rock", true))
		{
			return 0;
		}
		new Float:pos[3] = 0.0;
		GetEntPropVector(entity, PropType:0, "m_vecOrigin", pos, 0);
		pos[2] += 50.0;
		AcceptEntityInput(entity, "Kill", -1, -1, 0);
		new ent = CreateEntityByName("prop_physics", -1);
		DispatchKeyValue(ent, "model", "models/props_junk/propanecanister001a.mdl");
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Break", -1, -1, 0);
		new pointHurt = CreateEntityByName("point_hurt", -1);
		DispatchKeyValueFloat(pointHurt, "Damage", flBossStormDamage);
		DispatchKeyValue(pointHurt, "DamageType", "2");
		DispatchKeyValue(pointHurt, "DamageDelay", "0.0");
		DispatchKeyValueFloat(pointHurt, "DamageRadius", 200.0);
		DispatchSpawn(pointHurt);
		TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
		
		if (IsValidEntity(client) && IsTank(client))
		{
			AcceptEntityInput(pointHurt, "Hurt", client, -1, 0);
		}
		CreateTimer(0.1, DeletePointHurt, pointHurt, 2);
		new push = CreateEntityByName("point_push", -1);
		DispatchKeyValueFloat(push, "magnitude", 600.0);
		DispatchKeyValueFloat(push, "radius", 1.0 * 200.0);
		SetVariantString("spawnflags 24");
		AcceptEntityInput(push, "AddOutput", -1, -1, 0);
		DispatchSpawn(push);
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(push, "Enable", -1, -1, 0);
		CreateTimer(0.5, DeletePushForce, push, 2);
	}
	return 0;
}

ExplodeSipow(entity, client)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, 16);
		if (!StrEqual(classname, "tank_rock", true))
		{
			return 0;
		}
		new Float:pos[3] = 0.0;
		GetEntPropVector(entity, PropType:0, "m_vecOrigin", pos, 0);
		pos[2] += 50.0;
		AcceptEntityInput(entity, "Kill", -1, -1, 0);
		new ent = CreateEntityByName("prop_physics", -1);
		DispatchKeyValue(ent, "model", "models/props_junk/propanecanister001a.mdl");
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Break", -1, -1, 0);
		new pointHurt = CreateEntityByName("point_hurt", -1);
		DispatchKeyValueFloat(pointHurt, "Damage", flSipowStormDamage);
		DispatchKeyValue(pointHurt, "DamageType", "2");
		DispatchKeyValue(pointHurt, "DamageDelay", "0.0");
		DispatchKeyValueFloat(pointHurt, "DamageRadius", 200.0);
		DispatchSpawn(pointHurt);
		TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
		
		if (IsValidEntity(client) && IsTank(client))
		{
			AcceptEntityInput(pointHurt, "Hurt", client, -1, 0);
		}
		CreateTimer(0.1, DeletePointHurt, pointHurt, 2);
		new push = CreateEntityByName("point_push", -1);
		DispatchKeyValueFloat(push, "magnitude", 600.0);
		DispatchKeyValueFloat(push, "radius", 1.0 * 200.0);
		SetVariantString("spawnflags 24");
		AcceptEntityInput(push, "AddOutput", -1, -1, 0);
		DispatchSpawn(push);
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(push, "Enable", -1, -1, 0);
		CreateTimer(0.5, DeletePushForce, push, 2);
	}
	return 0;
}

public Action:DeletePushForce(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		decl String:classname[64];
		GetEdictClassname(ent, classname, 64);
		if (StrEqual(classname, "point_push", false))
		{
			AcceptEntityInput(ent, "Kill", -1, -1, 0);
		}
	}
	return Action:0;
}

public Action:DeletePointHurt(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		decl String:classname[64];
		GetEdictClassname(ent, classname, 64);
		if (StrEqual(classname, "point_hurt", false))
		{
			AcceptEntityInput(ent, "Kill", -1, -1, 0);
		}
	}
	return Action:0;
}

public bool:TraceRayDontHitSelfAndLive(entity, mask, any:data)
{
	if (data == entity)
	{
		return false;
	}
	
	if (entity > 0 && entity <= MaxClients)
	{
		if (IsClientInGame(entity))
		{
			return false;
		}
	}
	return true;
}

ExecTankDeath(client)
{
	TankAlive[client] = 0;
	TankAbility[client] = 0;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		decl String:model[128];
		GetEntPropString(entity, PropType:1, "m_ModelName", model, 128, 0);
		if (StrEqual(model, "models/props_debris/concrete_chunk01a.mdl", true))
		{
			new owner = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
			if (client == owner)
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
			}
		}
		else
		{
			if (StrEqual(model, "models/props_vehicles/tire001c_car.mdl", true))
			{
				new owner = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
				if (client == owner)
				{
					AcceptEntityInput(entity, "Kill", -1, -1, 0);
				}
			}
			if (StrEqual(model, "models/props_unique/airport/atlas_break_ball.mdl", true))
			{
				new owner = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
				if (client == owner)
				{
					AcceptEntityInput(entity, "Kill", -1, -1, 0);
				}
			}
		}
	}
	while ((entity = FindEntityByClassname(entity, "beam_spotlight")) != -1)
	{
		new owner = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
		if (client == owner)
		{
			AcceptEntityInput(entity, "Kill", -1, -1, 0);
		}
	}
	switch (iTankWave)
	{
		case 1:
		{
			CreateTimer(5.0, TimerTankWave2, any:0, 2);
		}
		case 2:
		{
			CreateTimer(5.0, TimerTankWave3, any:0, 2);
		}
		default:
		{
		}
	}
	return 0;
}

public Action:TimerTankWave2(Handle:timer)
{
	CountTanks();
	if (!iNumTanks)
	{
		iTankWave = 2;
	}
	return Action:0;
}

public Action:TimerTankWave3(Handle:timer)
{
	CountTanks();
	if (!iNumTanks)
	{
		iTankWave = 3;
	}
	return Action:0;
}

public Action:SpawnTankTimer(Handle:timer)
{
	CountTanks();
	if (iTankWave == 1)
	{
		if (iNumTanks < iWave1Cvar)
		{
			new bot = CreateFakeClient("Tank");
			if (0 < bot)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
	else
	{
		if (iTankWave == 2)
		{
			if (iNumTanks < iWave2Cvar)
			{
				new bot = CreateFakeClient("Tank");
				if (0 < bot)
				{
					SpawnInfected(bot, 8, true);
				}
			}
		}
		if (iTankWave == 3)
		{
			if (iNumTanks < iWave3Cvar)
			{
				new bot = CreateFakeClient("Tank");
				if (0 < bot)
				{
					SpawnInfected(bot, 8, true);
				}
			}
		}
	}
	return Action:0;
}

public Action:Timer_UnFreeze(Handle:timer, any:client)
{
	if (any:0 < client)
	{
		
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			SetEntityRenderMode(client, RenderMode:3);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			SetEntityMoveType(client, MoveType:2);
		}
	}
	return Action:0;
}

public Action:Timer_ResetGravity(Handle:timer, any:client)
{
	if (any:0 < client)
	{
		if (IsClientInGame(client))
		{
			SetEntityGravity(client, 1.0);
		}
	}
	return Action:0;
}

public Action:Timer_AttachSPAWN(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 7595105)
	{
		AttachParticle(client, "smoker_smokecloud", 1.2, 0.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachSMOKE(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 12085120)
	{
		AttachParticle(client, "smoker_smokecloud", 1.2, 0.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachMEME(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 2550)
	{
		AttachParticle(client, "smoker_smokecloud", 1.2, 0.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachBOSS(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 50)
	{
		AttachParticle(client, "smoker_smokecloud", 1.2, 0.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachFIRE(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 12800)
	{
		AttachParticle(client, "aircraft_destroy_fastFireTrail", 0.8, 0.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachFIRE2(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 2550)
	{
		AttachParticle(client, "aircraft_destroy_fastFireTrail", 0.8, 0.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachFIRE3(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 50)
	{
		AttachParticle(client, "aircraft_destroy_fastFireTrail", 0.8, 0.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachFIRE_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "tank_rock", true))
		{
			IgniteEntity(entity, 100.0, false, 0.0, false);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:Timer_AttachICE(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 100170)
	{
		AttachParticle(client, "steam_manhole", 2.0, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachICE2(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 2550)
	{
		AttachParticle(client, "steam_manhole", 2.0, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachICE3(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 50)
	{
		AttachParticle(client, "steam_manhole", 2.0, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_SpitSound(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 12115128)
	{
		EmitSoundToAll("player/spitter/voice/warn/spitter_spit_02.wav", client, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	return Action:0;
}

public Action:Timer_SpitSound2(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 255125)
	{
		EmitSoundToAll("player/spitter/voice/warn/spitter_spit_02.wav", client, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	return Action:0;
}

public Action:Timer_AttachSPIT(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 12115128)
	{
		AttachParticle(client, "spitter_areaofdenial_glow2", 2.0, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachSPIT2(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 255125)
	{
		AttachParticle(client, "spitter_areaofdenial_glow2", 2.0, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachSPIT_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "tank_rock", true))
		{
			AttachParticle(entity, "spitter_projectile", 0.8, 0.0);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:Timer_AttachELEC(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 100165255)
	{
		AttachParticle(client, "electrical_arc_01_parent", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachELEC2(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 25500)
	{
		AttachParticle(client, "electrical_arc_01_parent", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachELEC3(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 2552550)
	{
		AttachParticle(client, "electrical_arc_01_parent", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachELEC4(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 906090)
	{
		AttachParticle(client, "electrical_arc_01_parent", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachELEC5(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client))
	{
		AttachParticle(client, "electrical_arc_01_parent", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachELEC6(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 111)
	{
		AttachParticle(client, "electrical_arc_01_parent", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachELEC7(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 255100255)
	{
		AttachParticle(client, "electrical_arc_01_parent", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachELEC8(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 2550)
	{
		AttachParticle(client, "electrical_arc_01_parent", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachELEC9(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 50)
	{
		AttachParticle(client, "electrical_arc_01_parent", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachELEC10(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 255)
	{
		AttachParticle(client, "electrical_arc_01_parent", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachELEC11(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 1005050)
	{
		AttachParticle(client, "electrical_arc_01_parent", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachELEC12(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 254025)
	{
		AttachParticle(client, "electrical_arc_01_parent", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachELEC_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "tank_rock", true))
		{
			AttachParticle(entity, "electrical_arc_01_parent", 0.8, 0.0);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:Timer_AttachELEC_Rock2(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, 32);
		if (StrEqual(classname, "tank_rock", true))
		{
			AttachParticle(entity, "electrical_arc_01_parent", 0.8, 0.0);
			return Action:0;
		}
	}
	return Action:4;
}

public Action:Timer_AttachBLOOD(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 255200255)
	{
		AttachParticle(client, "boomer_explode_D", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachBLOOD2(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 2550)
	{
		AttachParticle(client, "boomer_explode_D", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachBLOOD3(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 50)
	{
		AttachParticle(client, "boomer_explode_D", 0.8, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachMETEOR(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 1002525)
	{
		AttachParticle(client, "smoke_medium_01", 6.0, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachARMAGEDDON(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 7500)
	{
		AttachParticle(client, "smoke_medium_01", 6.0, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachPSYCHOTIC(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client))
	{
		AttachParticle(client, "smoke_medium_01", 6.0, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachMEME2(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 2550)
	{
		AttachParticle(client, "smoke_medium_01", 6.0, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachBOSS2(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 50)
	{
		AttachParticle(client, "smoke_medium_01", 6.0, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:Timer_AttachSIPOW(Handle:timer, any:client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 255125)
	{
		AttachParticle(client, "smoke_medium_01", 6.0, 30.0);
		return Action:0;
	}
	return Action:4;
}

public Action:ActivateShieldTimer(Handle:timer, any:client)
{
	ActivateShield(client);
	return Action:0;
}

ActivateShield(client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 135205255 && ShieldsUp[client])
	{
		decl Float:Origin[3];
		GetClientAbsOrigin(client, Origin);
		Origin[2] -= 120.0;
		new entity = CreateEntityByName("prop_dynamic", -1);
		if (IsValidEntity(entity))
		{
			decl String:tName[64];
			Format(tName, 64, "Tank%d", client);
			DispatchKeyValue(client, "targetname", tName);
			GetEntPropString(client, PropType:1, "m_iName", tName, 64, 0);
			DispatchKeyValue(entity, "targetname", "Player");
			DispatchKeyValue(entity, "parentname", tName);
			DispatchKeyValue(entity, "model", "models/props_unique/airport/atlas_break_ball.mdl");
			DispatchKeyValueVector(entity, "origin", Origin);
			DispatchSpawn(entity);
			SetVariantString(tName);
			AcceptEntityInput(entity, "SetParent", entity, entity, 0);
			SetEntityRenderMode(entity, RenderMode:3);
			SetEntityRenderColor(entity, 25, 125, 125, 50);
			SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup", false), any:1, 1, true);
			SetEntProp(entity, PropType:0, "m_hOwnerEntity", client, 4, 0);
		}
		ShieldsUp[client] = 1;
	}
	return 0;
}

DeactivateShield(client)
{
	
	if (IsTank(client) && GetEntityRenderColor(client) == 135205255 && ShieldsUp[client] == 1)
	{
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
		{
			decl String:model[128];
			GetEntPropString(entity, PropType:1, "m_ModelName", model, 128, 0);
			if (StrEqual(model, "models/props_unique/airport/atlas_break_ball.mdl", true))
			{
				new owner = GetEntProp(entity, PropType:0, "m_hOwnerEntity", 4, 0);
				if (client == owner)
				{
					AcceptEntityInput(entity, "Kill", -1, -1, 0);
				}
			}
		}
		CreateTimer(flShieldShieldsDownInterval, ActivateShieldTimer, client, 2);
		ShieldsUp[client] = 0;
	}
	return 0;
}

TeleportTank(client)
{
	new random = GetRandomInt(1, iWarpTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			CreateParticle(client, "electrical_arc_01_system", 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank2(client)
{
	new random = GetRandomInt(1, iFlashTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			CreateParticle(client, "electrical_arc_01_system", 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank3(client)
{
	new random = GetRandomInt(1, iReverseFlashTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			CreateParticle(client, "electrical_arc_01_system", 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank4(client)
{
	new random = GetRandomInt(1, iHallucinationTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank5(client)
{
	new random = GetRandomInt(1, iDistractionTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			CreateParticle(client, "electrical_arc_01_system", 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank6(client)
{
	new random = GetRandomInt(1, iFeedbackTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			CreateParticle(client, "electrical_arc_01_system", 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank7(client)
{
	new random = GetRandomInt(1, iPsychoticTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			CreateParticle(client, "electrical_arc_01_system", 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank8(client)
{
	new random = GetRandomInt(1, iPsykotikTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			CreateParticle(client, "electrical_arc_01_system", 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank9(client)
{
	new random = GetRandomInt(1, iSpykotikTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			CreateParticle(client, "electrical_arc_01_system", 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank10(client)
{
	new random = GetRandomInt(1, iMemeTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			CreateParticle(client, "electrical_arc_01_system", 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank11(client)
{
	new random = GetRandomInt(1, iBossTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			CreateParticle(client, "electrical_arc_01_system", 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank12(client)
{
	new random = GetRandomInt(1, iSpypsyTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			CreateParticle(client, "electrical_arc_01_system", 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank13(client)
{
	new random = GetRandomInt(1, iPoltergeistTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

TeleportTank14(client)
{
	new random = GetRandomInt(1, iMirageTeleportDelay);
	if (random == 1)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3] = 0.0;
			new Float:Angles[3] = 0.0;
			GetClientAbsOrigin(target, Origin);
			GetClientAbsAngles(target, Angles);
			CreateParticle(client, "electrical_arc_01_system", 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
	return 0;
}

CountWitches()
{
	new count;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != -1)
	{
		count++;
	}
	return count;
}

SpawnWitch(client)
{
	new count;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != -1)
	{
		
		if (count < 4 && CountWitches() < iWitchMaxWitches)
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			decl Float:InfectedAng[3];
			GetClientAbsOrigin(client, TankPos);
			GetEntPropVector(entity, PropType:0, "m_vecOrigin", InfectedPos, 0);
			GetEntPropVector(entity, PropType:0, "m_angRotation", InfectedAng, 0);
			new Float:distance = GetVectorDistance(InfectedPos, TankPos, false);
			if (distance < 100.0)
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				new witch = CreateEntityByName("witch", -1);
				DispatchSpawn(witch);
				ActivateEntity(witch);
				TeleportEntity(witch, InfectedPos, InfectedAng, NULL_VECTOR);
				SetEntProp(witch, PropType:0, "m_hOwnerEntity", any:255200255, 4, 0);
				count++;
			}
		}
	}
	return 0;
}

SpawnWitch2(client)
{
	new count;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != -1)
	{
		
		if (count < 4 && CountWitches() < iMemeMaxWitches)
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			decl Float:InfectedAng[3];
			GetClientAbsOrigin(client, TankPos);
			GetEntPropVector(entity, PropType:0, "m_vecOrigin", InfectedPos, 0);
			GetEntPropVector(entity, PropType:0, "m_angRotation", InfectedAng, 0);
			new Float:distance = GetVectorDistance(InfectedPos, TankPos, false);
			if (distance < 100.0)
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				new witch = CreateEntityByName("witch", -1);
				DispatchSpawn(witch);
				ActivateEntity(witch);
				TeleportEntity(witch, InfectedPos, InfectedAng, NULL_VECTOR);
				SetEntProp(witch, PropType:0, "m_hOwnerEntity", any:255200255, 4, 0);
				count++;
			}
		}
	}
	return 0;
}

SpawnWitch3(client)
{
	new count;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != -1)
	{
		
		if (count < 4 && CountWitches() < iBossMaxWitches)
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			decl Float:InfectedAng[3];
			GetClientAbsOrigin(client, TankPos);
			GetEntPropVector(entity, PropType:0, "m_vecOrigin", InfectedPos, 0);
			GetEntPropVector(entity, PropType:0, "m_angRotation", InfectedAng, 0);
			new Float:distance = GetVectorDistance(InfectedPos, TankPos, false);
			if (distance < 100.0)
			{
				AcceptEntityInput(entity, "Kill", -1, -1, 0);
				new witch = CreateEntityByName("witch", -1);
				DispatchSpawn(witch);
				ActivateEntity(witch);
				TeleportEntity(witch, InfectedPos, InfectedAng, NULL_VECTOR);
				SetEntProp(witch, PropType:0, "m_hOwnerEntity", any:255200255, 4, 0);
				count++;
			}
		}
	}
	return 0;
}

stock HealthTank(client)
{
	new infectedfound;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != -1)
	{
		decl Float:TankPos[3];
		decl Float:InfectedPos[3];
		GetClientAbsOrigin(client, TankPos);
		GetEntPropVector(entity, PropType:0, "m_vecOrigin", InfectedPos, 0);
		new Float:distance = GetVectorDistance(InfectedPos, TankPos, false);
		//if (distance < 7.0E-43)
		if(distance < 500)
		{
			new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
			new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
			
			if (health <= maxhealth - iHealthHealthCommons && health > 500)
			{
				SetEntProp(client, PropType:1, "m_iHealth", iHealthHealthCommons + health, 4, 0);
			}
			else
			{
				if (health > 500)
				{
					SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
				}
			}
			if (health > 500)
			{
				infectedfound = 1;
			}
		}
	}
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			GetClientAbsOrigin(client, TankPos);
			GetClientAbsOrigin(i, InfectedPos);
			new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
			//if (distance < 7.0E-43)
			if(distance < 500)
			{
				new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
				new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
				
				if (health <= maxhealth - iHealthHealthSpecials && health > 500)
				{
					SetEntProp(client, PropType:1, "m_iHealth", iHealthHealthSpecials + health, 4, 0);
				}
				else
				{
					if (health > 500)
					{
						SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
					}
				}
				
				if (health > 500 && infectedfound < 2)
				{
					infectedfound = 1;
				}
			}
		}
		else
		{
			
			if (IsTank(i) && client != i)
			{
				decl Float:TankPos[3];
				decl Float:InfectedPos[3];
				GetClientAbsOrigin(client, TankPos);
				GetClientAbsOrigin(i, InfectedPos);
				new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
				//if (distance < 7.0E-43)
				if(distance < 500)
				{
					new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
					new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
					
					if (health <= maxhealth - iHealthHealthTanks && health > 500)
					{
						SetEntProp(client, PropType:1, "m_iHealth", iHealthHealthTanks + health, 4, 0);
					}
					else
					{
						if (health > 500)
						{
							SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
						}
					}
					if (health > 500)
					{
						infectedfound = 2;
					}
				}
			}
		}
		i++;
	}
	return 0;
}

PsychoticTank(client)
{
	new infectedfound;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != -1)
	{
		decl Float:TankPos[3];
		decl Float:InfectedPos[3];
		GetClientAbsOrigin(client, TankPos);
		GetEntPropVector(entity, PropType:0, "m_vecOrigin", InfectedPos, 0);
		new Float:distance = GetVectorDistance(InfectedPos, TankPos, false);
		//if (distance < 7.0E-43)
		if(distance < 500)
		{
			new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
			new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
			
			if (health <= maxhealth - iPsychoticHealthCommons && health > 500)
			{
				SetEntProp(client, PropType:1, "m_iHealth", iPsychoticHealthCommons + health, 4, 0);
			}
			else
			{
				if (health > 500)
				{
					SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
				}
			}
			if (health > 500)
			{
				infectedfound = 1;
			}
		}
	}
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			GetClientAbsOrigin(client, TankPos);
			GetClientAbsOrigin(i, InfectedPos);
			new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
			//if (distance < 7.0E-43)
			if(distance < 500)
			{
				new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
				new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
				
				if (health <= maxhealth - iPsychoticHealthSpecials && health > 500)
				{
					SetEntProp(client, PropType:1, "m_iHealth", iPsychoticHealthSpecials + health, 4, 0);
				}
				else
				{
					if (health > 500)
					{
						SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
					}
				}
				
				if (health > 500 && infectedfound < 2)
				{
					infectedfound = 1;
				}
			}
		}
		else
		{
			
			if (IsTank(i) && client != i)
			{
				decl Float:TankPos[3];
				decl Float:InfectedPos[3];
				GetClientAbsOrigin(client, TankPos);
				GetClientAbsOrigin(i, InfectedPos);
				new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
				//if (distance < 7.0E-43)
				if(distance < 500)
				{
					new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
					new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
					
					if (health <= maxhealth - iPsychoticHealthTanks && health > 500)
					{
						SetEntProp(client, PropType:1, "m_iHealth", iPsychoticHealthTanks + health, 4, 0);
					}
					else
					{
						if (health > 500)
						{
							SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
						}
					}
					if (health > 500)
					{
						infectedfound = 2;
					}
				}
			}
		}
		i++;
	}
	return 0;
}

GoliathTank(client)
{
	new infectedfound;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != -1)
	{
		decl Float:TankPos[3];
		decl Float:InfectedPos[3];
		GetClientAbsOrigin(client, TankPos);
		GetEntPropVector(entity, PropType:0, "m_vecOrigin", InfectedPos, 0);
		new Float:distance = GetVectorDistance(InfectedPos, TankPos, false);
		//if (distance < 7.0E-43)ç
		if(distance < 500)
		{
			new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
			new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
			
			if (health <= maxhealth - iGoliathHealthCommons && health > 500)
			{
				SetEntProp(client, PropType:1, "m_iHealth", iGoliathHealthCommons + health, 4, 0);
			}
			else
			{
				if (health > 500)
				{
					SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
				}
			}
			if (health > 500)
			{
				infectedfound = 1;
			}
		}
	}
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			GetClientAbsOrigin(client, TankPos);
			GetClientAbsOrigin(i, InfectedPos);
			new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
			//if (distance < 7.0E-43)
			if(distance < 500)
			{
				new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
				new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
				
				if (health <= maxhealth - iGoliathHealthSpecials && health > 500)
				{
					SetEntProp(client, PropType:1, "m_iHealth", iGoliathHealthSpecials + health, 4, 0);
				}
				else
				{
					if (health > 500)
					{
						SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
					}
				}
				
				if (health > 500 && infectedfound < 2)
				{
					infectedfound = 1;
				}
			}
		}
		else
		{
			
			if (IsTank(i) && client != i)
			{
				decl Float:TankPos[3];
				decl Float:InfectedPos[3];
				GetClientAbsOrigin(client, TankPos);
				GetClientAbsOrigin(i, InfectedPos);
				new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
				//if (distance < 7.0E-43)
				if(distance < 500)
				{
					new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
					new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
					
					if (health <= maxhealth - iGoliathHealthTanks && health > 500)
					{
						SetEntProp(client, PropType:1, "m_iHealth", iGoliathHealthTanks + health, 4, 0);
					}
					else
					{
						if (health > 500)
						{
							SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
						}
					}
					if (health > 500)
					{
						infectedfound = 2;
					}
				}
			}
		}
		i++;
	}
	return 0;
}

PsykotikTank(client)
{
	new infectedfound;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != -1)
	{
		decl Float:TankPos[3];
		decl Float:InfectedPos[3];
		GetClientAbsOrigin(client, TankPos);
		GetEntPropVector(entity, PropType:0, "m_vecOrigin", InfectedPos, 0);
		new Float:distance = GetVectorDistance(InfectedPos, TankPos, false);
		//if (distance < 7.0E-43)
		if(distance < 500)
		{
			new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
			new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
			
			if (health <= maxhealth - iPsykotikHealthCommons && health > 500)
			{
				SetEntProp(client, PropType:1, "m_iHealth", iPsykotikHealthCommons + health, 4, 0);
			}
			else
			{
				if (health > 500)
				{
					SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
				}
			}
			if (health > 500)
			{
				infectedfound = 1;
			}
		}
	}
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			GetClientAbsOrigin(client, TankPos);
			GetClientAbsOrigin(i, InfectedPos);
			new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
			//if (distance < 7.0E-43)
			if(distance < 500)
			{
				new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
				new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
				
				if (health <= maxhealth - iPsykotikHealthSpecials && health > 500)
				{
					SetEntProp(client, PropType:1, "m_iHealth", iPsykotikHealthSpecials + health, 4, 0);
				}
				else
				{
					if (health > 500)
					{
						SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
					}
				}
				
				if (health > 500 && infectedfound < 2)
				{
					infectedfound = 1;
				}
			}
		}
		else
		{
			
			if (IsTank(i) && client != i)
			{
				decl Float:TankPos[3];
				decl Float:InfectedPos[3];
				GetClientAbsOrigin(client, TankPos);
				GetClientAbsOrigin(i, InfectedPos);
				new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
				//if (distance < 7.0E-43)
				if(distance < 500)
				{
					new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
					new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
					
					if (health <= maxhealth - iPsykotikHealthTanks && health > 500)
					{
						SetEntProp(client, PropType:1, "m_iHealth", iPsykotikHealthTanks + health, 4, 0);
					}
					else
					{
						if (health > 500)
						{
							SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
						}
					}
					if (health > 500)
					{
						infectedfound = 2;
					}
				}
			}
		}
		i++;
	}
	return 0;
}

BossTank(client)
{
	new infectedfound;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != -1)
	{
		decl Float:TankPos[3];
		decl Float:InfectedPos[3];
		GetClientAbsOrigin(client, TankPos);
		GetEntPropVector(entity, PropType:0, "m_vecOrigin", InfectedPos, 0);
		new Float:distance = GetVectorDistance(InfectedPos, TankPos, false);
		//if (distance < 7.0E-43)
		if(distance < 500)
		{
			new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
			new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
			
			if (health <= maxhealth - iBossHealthCommons && health > 500)
			{
				SetEntProp(client, PropType:1, "m_iHealth", iBossHealthCommons + health, 4, 0);
			}
			else
			{
				if (health > 500)
				{
					SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
				}
			}
			if (health > 500)
			{
				infectedfound = 1;
			}
		}
	}
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			GetClientAbsOrigin(client, TankPos);
			GetClientAbsOrigin(i, InfectedPos);
			new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
			//if (distance < 7.0E-43)
			if(distance < 500)
			{
				new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
				new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
				
				if (health <= maxhealth - iBossHealthSpecials && health > 500)
				{
					SetEntProp(client, PropType:1, "m_iHealth", iBossHealthSpecials + health, 4, 0);
				}
				else
				{
					if (health > 500)
					{
						SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
					}
				}
				
				if (health > 500 && infectedfound < 2)
				{
					infectedfound = 1;
				}
			}
		}
		else
		{
			
			if (IsTank(i) && client != i)
			{
				decl Float:TankPos[3];
				decl Float:InfectedPos[3];
				GetClientAbsOrigin(client, TankPos);
				GetClientAbsOrigin(i, InfectedPos);
				new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
				//if (distance < 7.0E-43)
				if(distance < 500)
				{
					new health = GetEntProp(client, PropType:0, "m_iHealth", 4, 0);
					new maxhealth = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0);
					
					if (health <= maxhealth - iBossHealthTanks && health > 500)
					{
						SetEntProp(client, PropType:1, "m_iHealth", iBossHealthTanks + health, 4, 0);
					}
					else
					{
						if (health > 500)
						{
							SetEntProp(client, PropType:1, "m_iHealth", maxhealth, 4, 0);
						}
					}
					if (health > 500)
					{
						infectedfound = 2;
					}
				}
			}
		}
		i++;
	}
	return 0;
}

InfectedCloak(client)
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			GetClientAbsOrigin(client, TankPos);
			GetClientAbsOrigin(i, InfectedPos);
			new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
			//if (distance < 7.0E-43)
			if(distance < 500)
			{
				SetEntityRenderMode(i, RenderMode:3);
				SetEntityRenderColor(i, 255, 255, 255, 50);
			}
			else
			{
				SetEntityRenderMode(i, RenderMode:3);
				SetEntityRenderColor(i, 255, 255, 255, 255);
			}
		}
		i++;
	}
	return 0;
}

InfectedCloak2(client)
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			GetClientAbsOrigin(client, TankPos);
			GetClientAbsOrigin(i, InfectedPos);
			new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
			//if (distance < 7.0E-43)
			if(distance < 500)
			{
				SetEntityRenderMode(i, RenderMode:3);
				SetEntityRenderColor(i, 255, 255, 255, 50);
			}
			else
			{
				SetEntityRenderMode(i, RenderMode:3);
				SetEntityRenderColor(i, 255, 255, 255, 255);
			}
		}
		i++;
	}
	return 0;
}

InfectedCloak3(client)
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			GetClientAbsOrigin(client, TankPos);
			GetClientAbsOrigin(i, InfectedPos);
			new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
			//if (distance < 7.0E-43)
			if(distance < 500)
			{
				SetEntityRenderMode(i, RenderMode:3);
				SetEntityRenderColor(i, 0, 255, 0, 50);
			}
			else
			{
				SetEntityRenderMode(i, RenderMode:3);
				SetEntityRenderColor(i, 0, 255, 0, 255);
			}
		}
		i++;
	}
	return 0;
}

InfectedCloak4(client)
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			GetClientAbsOrigin(client, TankPos);
			GetClientAbsOrigin(i, InfectedPos);
			new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
			//if (distance < 7.0E-43)
			if(distance < 500)
			{
				SetEntityRenderMode(i, RenderMode:3);
				SetEntityRenderColor(i, 0, 0, 50, 50);
			}
			else
			{
				SetEntityRenderMode(i, RenderMode:3);
				SetEntityRenderColor(i, 0, 0, 50, 255);
			}
		}
		i++;
	}
	return 0;
}

InfectedCloak5(client)
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3];
			decl Float:InfectedPos[3];
			GetClientAbsOrigin(client, TankPos);
			GetClientAbsOrigin(i, InfectedPos);
			new Float:distance = GetVectorDistance(TankPos, InfectedPos, false);
			//if (distance < 7.0E-43)
			if(distance < 500)
			{
				SetEntityRenderMode(i, RenderMode:3);
				SetEntityRenderColor(i, 100, 50, 50, 50);
			}
			else
			{
				SetEntityRenderMode(i, RenderMode:3);
				SetEntityRenderColor(i, 100, 50, 50, 255);
			}
		}
		i++;
	}
	return 0;
}

CountSurvRange(client)
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			decl Float:TankPos[3];
			decl Float:PlayerPos[3];
			GetClientAbsOrigin(client, TankPos);
			GetClientAbsOrigin(i, PlayerPos);
			new Float:distance = GetVectorDistance(TankPos, PlayerPos, false);
			//if (distance > 1.68E-43)
			if(distance < 500)
			{
				count++;
			}
		}
		i++;
	}
	return count;
}

GetEntityRenderColor(entity)
{
	if (0 < entity)
	{
		new offset = GetEntSendPropOffs(entity, "m_clrRender", false);
		new r = GetEntData(entity, offset, 1);
		new g = GetEntData(entity, offset + 1, 1);
		new b = GetEntData(entity, offset + 2, 1);
		decl String:rgb[12];
		Format(rgb, 10, "%d%d%d", r, g, b);
		new color = StringToInt(rgb, 10);
		return color;
	}
	return 0;
}

public Action:OnPlayerTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (bSuperTanksEnabled)
	{
		
		if (damage > 0.0 && IsValidClient(victim))
		{
			decl String:classname[32];
			if (GetClientTeam(victim) == 2)
			{
				if (IsWitch(attacker))
				{
					if (GetEntProp(attacker, PropType:0, "m_hOwnerEntity", 4, 0) == 255200255)
					{
						damage = 16.0;
					}
				}
				else
				{
					
					if (IsTank(attacker) && damagetype != 2)
					{
						new color = GetEntityRenderColor(attacker);
						switch (color)
						{
							case 50:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									new random = GetRandomInt(1, 2);
									if (random == 1)
									{
										SkillBossClawKill(victim, attacker);
									}
									else
									{
										SkillBossClaw(victim);
									}
								}
							}
							case 100:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									new random = GetRandomInt(1, 2);
									if (random == 1)
									{
										SkillGoliathClawKill(victim, attacker);
									}
									else
									{
										SkillGoliathClaw(victim);
									}
								}
							}
							case 111:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									TankAbility[attacker] = 0;
								}
							}
							case 255:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									TankAbility[attacker] = 0;
								}
							}
							case 2550:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									new random = GetRandomInt(1, 2);
									if (random == 1)
									{
										SkillMemeClawKill(victim, attacker);
									}
									else
									{
										SkillMemeClaw(victim);
									}
								}
							}
							case 7500:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									new random = GetRandomInt(1, 2);
									if (random == 1)
									{
										SkillArmageddonClawKill(victim, attacker);
									}
									else
									{
										SkillArmageddonClaw(victim);
									}
								}
							}
							case 12800:
							{
								GetEdictClassname(inflictor, classname, 32);
								
								if (StrEqual(classname, "weapon_tank_claw", true) || StrEqual(classname, "weapon_tank_rock", true))
								{
									SkillFlameClaw(victim);
								}
							}
							case 25500:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									TankAbility[attacker] = 0;
								}
							}
							case 100170:
							{
								new flags = GetEntityFlags(victim);
								if (flags & 1)
								{
									new random = GetRandomInt(1, 3);
									if (random == 1)
									{
										SkillIceClaw(victim);
									}
								}
							}
							case 105255:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									TankAbility[attacker] = 0;
								}
							}
							case 254025:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									TankAbility[attacker] = 0;
								}
							}
							case 333435:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									SkillGravityClaw(victim);
								}
							}
							case 906090:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									SkillFeedbackClaw(victim, attacker);
								}
							}
							case 1005050:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									TankAbility[attacker] = 0;
								}
							}
							case 2252250:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									new dmg = RoundFloat(damage / 2);
									DealDamagePlayer(victim, attacker, 2, dmg);
								}
							}
							case 2552550:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									TankAbility[attacker] = 0;
								}
							}
							case 5512570:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									new random = GetRandomInt(1, 2);
									if (random == 1)
									{
										SkillTrapClawKill(victim, attacker);
									}
									else
									{
										SkillTrapClaw(victim);
									}
								}
							}
							case 7080100:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									new random = GetRandomInt(1, 2);
									if (random == 1)
									{
										SkillSmashClawKill(victim, attacker);
									}
									else
									{
										SkillSmashClaw(victim);
									}
								}
							}
							case 7595105:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									new random = GetRandomInt(1, 4);
									if (random == 1)
									{
										SDKCallVomitOnPlayer(victim, attacker);
									}
								}
							}
							case 100165255:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									SkillElecClaw(victim, attacker);
								}
							}
							case 130130255:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									new dmg = RoundFloat(damage / 2);
									DealDamagePlayer(victim, attacker, 2, dmg);
								}
							}
							case 255100255:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_tank_claw", true))
								{
									TankAbility[attacker] = 0;
								}
							}
							default:
							{
							}
						}
					}
				}
			}
			else
			{
				if (IsTank(victim))
				{
					
					if (damagetype == 8 || damagetype == 2056 || damagetype == 268435464)
					{
						new index = GetSuperTankByRenderColor(GetEntityRenderColor(victim));
						
						if (index >= 0 && index <= 40)
						{
							if (bTankFireImmunity[index])
							{
								
								if (index || (index && bDefaultOverride))
								{
									return Action:3;
								}
							}
						}
					}
					if (IsSurvivor(attacker))
					{
						new color = GetEntityRenderColor(victim);
						switch (color)
						{
							case 0:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_melee", true))
								{
									new random = GetRandomInt(1, 2);
									if (random == 1)
									{
										if (!TankAbility[victim])
										{
											StartPsychoticFall(victim);
										}
									}
								}
							}
							case 50:
							{
								if (bBossDisarm)
								{
									GetEdictClassname(inflictor, classname, 32);
									if (StrEqual(classname, "weapon_melee", true))
									{
										new random = GetRandomInt(1, 4);
										if (random == 1)
										{
											ForceWeaponDrop(attacker);
											EmitSoundToClient(attacker, "npc/infected/action/die/male/death_42.wav", victim, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
										}
									}
								}
							}
							case 2550:
							{
								if (bMemeDisarm)
								{
									GetEdictClassname(inflictor, classname, 32);
									if (StrEqual(classname, "weapon_melee", true))
									{
										new random = GetRandomInt(1, 4);
										if (random == 1)
										{
											ForceWeaponDrop(attacker);
											EmitSoundToClient(attacker, "npc/infected/action/die/male/death_42.wav", victim, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
										}
									}
								}
							}
							case 7500:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_melee", true))
								{
									new random = GetRandomInt(1, 2);
									if (random == 1)
									{
										if (!TankAbility[victim])
										{
											StartArmageddonFall(victim);
										}
									}
								}
							}
							case 12800:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_melee", true))
								{
									new random = GetRandomInt(1, 4);
									if (random == 1)
									{
										SkillFlameGush(victim);
									}
								}
							}
							case 255125:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_melee", true))
								{
									new random = GetRandomInt(1, 2);
									new random2 = GetRandomInt(1, 4);
									if (random == 1)
									{
										if (!TankAbility[victim])
										{
											StartSipowFall(victim);
										}
									}
									if (random2 == 1)
									{
										new x = CreateFakeClient("Spitter");
										if (0 < x)
										{
											new Float:Pos[3] = 0.0;
											GetClientAbsOrigin(victim, Pos);
											TeleportEntity(x, Pos, NULL_VECTOR, NULL_VECTOR);
											SDKCallSpitBurst(x);
											KickClient(x, "");
										}
									}
								}
							}
							case 505050:
							{
								if (bHallucinationDisarm)
								{
									GetEdictClassname(inflictor, classname, 32);
									if (StrEqual(classname, "weapon_melee", true))
									{
										new random = GetRandomInt(1, 4);
										if (random == 1)
										{
											ForceWeaponDrop(attacker);
											EmitSoundToClient(attacker, "npc/infected/action/die/male/death_42.wav", victim, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
										}
									}
								}
							}
							case 1002525:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_melee", true))
								{
									new random = GetRandomInt(1, 2);
									if (random == 1)
									{
										if (!TankAbility[victim])
										{
											StartMeteorFall(victim);
										}
									}
								}
							}
							case 1005050:
							{
								if (bPoltergeistDisarm)
								{
									GetEdictClassname(inflictor, classname, 32);
									if (StrEqual(classname, "weapon_melee", true))
									{
										new random = GetRandomInt(1, 4);
										if (random == 1)
										{
											ForceWeaponDrop(attacker);
											EmitSoundToClient(attacker, "npc/infected/action/die/male/death_42.wav", victim, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
										}
									}
								}
							}
							case 12115128:
							{
								GetEdictClassname(inflictor, classname, 32);
								if (StrEqual(classname, "weapon_melee", true))
								{
									new random = GetRandomInt(1, 4);
									if (random == 1)
									{
										new x = CreateFakeClient("Spitter");
										if (0 < x)
										{
											new Float:Pos[3] = 0.0;
											GetClientAbsOrigin(victim, Pos);
											TeleportEntity(x, Pos, NULL_VECTOR, NULL_VECTOR);
											SDKCallSpitBurst(x);
											KickClient(x, "");
										}
									}
								}
							}
							case 100100100:
							{
								if (bGhostDisarm)
								{
									GetEdictClassname(inflictor, classname, 32);
									if (StrEqual(classname, "weapon_melee", true))
									{
										new random = GetRandomInt(1, 4);
										if (random == 1)
										{
											ForceWeaponDrop(attacker);
											EmitSoundToClient(attacker, "npc/infected/action/die/male/death_42.wav", victim, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
										}
									}
								}
							}
							case 135205255:
							{
								
								if (damagetype == 134217792 || damagetype == 33554432 || damagetype == 16777280)
								{
									if (ShieldsUp[victim] == 1)
									{
										DeactivateShield(victim);
									}
								}
								else
								{
									if (ShieldsUp[victim] == 1)
									{
										return Action:3;
									}
								}
							}
							default:
							{
							}
						}
					}
				}
			}
		}
	}
	return Action:1;
}

DealDamagePlayer(target, attacker, dmgtype, dmg)
{
	
	if (target > 0 && target <= MaxClients)
	{
		
		if (IsClientInGame(target) && IsPlayerAlive(target))
		{
			decl String:damage[16];
			IntToString(dmg, damage, 16);
			decl String:type[16];
			IntToString(dmgtype, type, 16);
			new pointHurt = CreateEntityByName("point_hurt", -1);
			if (pointHurt)
			{
				DispatchKeyValue(target, "targetname", "hurtme");
				DispatchKeyValue(pointHurt, "Damage", damage);
				DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
				DispatchKeyValue(pointHurt, "DamageType", type);
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt, "Hurt", attacker, -1, 0);
				AcceptEntityInput(pointHurt, "Kill", -1, -1, 0);
				DispatchKeyValue(target, "targetname", "donthurtme");
			}
		}
	}
	return 0;
}

ForceWeaponDrop(client)
{
	if (0 < GetPlayerWeaponSlot(client, 1))
	{
		new weapon = GetPlayerWeaponSlot(client, 1);
		SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
	}
	return 0;
}

ResetInfectedAbility(client, Float:time)
{
	if (0 < client)
	{
		
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{
			new ability = GetEntPropEnt(client, PropType:0, "m_customAbility", 0);
			if (0 < ability)
			{
				SetEntPropFloat(ability, PropType:0, "m_duration", time, 0);
				SetEntPropFloat(ability, PropType:0, "m_timestamp", GetGameTime() + time, 0);
			}
		}
	}
	return 0;
}

GetNearestSurvivorDist(client)
{
	new Float:PlayerPos[3] = 0.0;
	new Float:TargetPos[3] = 0.0;
	new Float:nearest = 0.0;
	new Float:distance = 0.0;
	if (0 < client)
	{
		
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetClientAbsOrigin(client, PlayerPos);
			new i = 1;
			while (i <= MaxClients)
			{
				
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					GetClientAbsOrigin(i, TargetPos);
					distance = GetVectorDistance(PlayerPos, TargetPos, false);
					if (0.0 == nearest)
					{
						nearest = distance;
					}
					if (nearest > distance)
					{
						nearest = distance;
					}
				}
				i++;
			}
		}
	}
	return RoundFloat(distance);
}

GetSuperTankByRenderColor(color)
{
	switch (color)
	{
		case 0:
		{
			return 30;
		}
		case 50:
		{
			return 36;
		}
		case 100:
		{
			return 32;
		}
		case 111:
		{
			return 33;
		}
		case 255:
		{
			return 37;
		}
		case 2550:
		{
			return 35;
		}
		case 7500:
		{
			return 23;
		}
		case 12800:
		{
			return 7;
		}
		case 25500:
		{
			return 21;
		}
		case 100170:
		{
			return 8;
		}
		case 105255:
		{
			return 18;
		}
		case 254025:
		{
			return 40;
		}
		case 255125:
		{
			return 38;
		}
		case 333435:
		{
			return 20;
		}
		case 505050:
		{
			return 24;
		}
		case 651050:
		{
			return 12;
		}
		case 906090:
		{
			return 29;
		}
		case 1002525:
		{
			return 4;
		}
		case 1005050:
		{
			return 39;
		}
		case 2002550:
		{
			return 19;
		}
		case 2252250:
		{
			return 28;
		}
		case 2552550:
		{
			return 22;
		}
		case 2590185:
		{
			return 10;
		}
		case 4012540:
		{
			return 13;
		}
		case 5512570:
		{
			return 27;
		}
		case 7080100:
		{
			return 2;
		}
		case 7525575:
		{
			return 31;
		}
		case 7595105:
		{
			return 1;
		}
		case 12085120:
		{
			return 11;
		}
		case 12115128:
		{
			return 5;
		}
		case 25516575:
		{
			return 9;
		}
		case 100100100:
		{
			return 14;
		}
		case 100165255:
		{
			return 15;
		}
		case 100255200:
		{
			return 6;
		}
		case 130130255:
		{
			return 3;
		}
		case 135205255:
		{
			return 17;
		}
		case 225225225:
		{
			return 25;
		}
		case 255100255:
		{
			return 34;
		}
		case 255155255:
		{
			return 26;
		}
		case 255200255:
		{
			return 16;
		}
		case 255255255:
		{
			return 0;
		}
	}
	return -1;
}

//CheatCommand(client, String:command[], String:arguments[])
stock CheatCommand(client, const String:command[], const String:arguments[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & -16385);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags | 16384);
	return 0;
}

public void OnGameFrame()
{
	//if(!IsServerProcessing()) return;
	if (!IsServerProcessing())

	if (bSuperTanksEnabled)
	{
		iFrame += 1;
		if (iFrame >= 3)
		{
			new i = 1;
			while (i <= MaxClients)
			{
				
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					SpeedRebuild(i);
					SpeedRebuild2(i);
				}
				i++;
			}
			iFrame = 0;
		}
	}
	//return void:0;
}

public Action:TimerUpdate01(Handle:timer)
{
	if (!IsServerProcessing())
	{
		return Action:0;
	}
	
	if (bSuperTanksEnabled && bDisplayHealthCvar)
	{
		new i = 1;
		while (i <= MaxClients)
		{
			
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				if (!IsFakeClient(i))
				{
					new entity = GetClientAimTarget(i, false);
					if (IsValidEntity(entity))
					{
						new String:classname[32];
						GetEdictClassname(entity, classname, 32);
						if (StrEqual(classname, "player", false))
						{
							if (0 < entity)
							{
								IsTank(entity);
							}
						}
					}
				}
			}
			i++;
		}
	}
	return Action:0;
}

public Action:TimerUpdate1(Handle:timer)
{
	if (!IsServerProcessing())
	{
		return Action:0;
	}
	if (bSuperTanksEnabled)
	{
		TankController();
		SetConVarInt(FindConVar("z_max_player_zombies"), 32, false, false);
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == 2)
				{
					if (0 < PlayerSpeed[i])
					{
						PlayerSpeed[i] += -1;
					}
				}
				if (GetClientTeam(i) == 3)
				{
					if (IsFakeClient(i))
					{
						//new zombie = GetEntData(i, FindSendPropInfo("CTerrorPlayer", "m_zombieClass", 0, 0, 0), 4);
						new zombie = GetEntData(i, FindSendPropInfo("CTerrorPlayer", "m_zombieClass"));
						if (zombie == 5)
						{
							CreateTimer(3.0, TankLifeCheck, i, 2);
						}
					}
				}
			}
			i++;
		}
	}
	return Action:0;
}

GetConfig()
{
	decl String:bufA[8];
	decl String:bufB[8];
	GetConVarString(hCharHealth, bufA, 8);
	GetConVarString(hCharDamage, bufB, 8);
	nCharLength = strlen(bufA);
	
	if (!nCharLength || strlen(bufB) == nCharLength)
	{
		nCharLength = 1;
		sCharHealth[0] = 124;
		sCharHealth[0] = 0;
		sCharDamage[0] = 45;
		sCharDamage[0] = 0;
	}
	else
	{
		strcopy(sCharHealth, 8, bufA);
		strcopy(sCharDamage, 8, bufB);
	}
	nShowType = GetConVarBool(hShowType);
	nShowNum = GetConVarBool(hShowNum);
	nShowTank = GetConVarBool(hTank);
	return 0;
}

ShowHealthGauge(client, maxBAR, maxHP, nowHP, String:clName[])
{
	new percent = RoundToCeil(float(nowHP) / float(maxHP) * float(maxBAR));
	new i, length = maxBAR * nCharLength + 2;

	decl String:showBAR[length];
	showBAR[0] = '\0';
	for(i=0; i<percent&&i<maxBAR; i++){
		StrCat(showBAR, length, sCharHealth);
	}
	for(; i<maxBAR; i++){
		StrCat(showBAR, length, sCharDamage);
	}
	//BY STRIKER
	if(nShowType){
		if(!nShowNum){
			PrintHintText(client, "HP: |-%s-|  %s", showBAR, clName);
		}
		else{
			PrintHintText(client, "HP: |-%s-|  [%d / %d]  %s", showBAR, nowHP, maxHP, clName);
		}
	}
	else{
		if(!nShowNum){
			PrintCenterText(client, "HP: |-%s-|  %s", showBAR, clName);
		}
		else{
			PrintCenterText(client, "HP: |-%s-|  [%d / %d]  %s", showBAR, nowHP, maxHP, clName);
		}
	}
}

public Action:OnRoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	nShowTank = 0;
	new i;
	while (i < 66)
	{
		prevMAX[i] = -1;
		prevHP[i] = -1;
		i++;
	}
	return Action:0;
}

public Action:TimerSpawn(Handle:timer, any:client)
{
	if(IsValidEntity(client)){
		new val = GetEntProp(client, Prop_Send, "m_iMaxHealth") & 0xffff;
		prevMAX[client] = (val <= 0) ? val : 1;
		prevHP[client] = 999999;
	}
	return Plugin_Stop;
}

public Action:OnInfectedSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	GetConfig();

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( client > 0
		&& IsClientConnected(client)
		&& IsClientInGame(client)
		&& GetClientTeam(client) == 3
	){
		TimerSpawn(INVALID_HANDLE, client);
		CreateTimer(0.5, TimerSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:OnInfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hPluginEnable)) return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( client > 0
		&& IsClientConnected(client)
		&& IsClientInGame(client)
		&& GetClientTeam(client) == 3
	){
		decl String:clName[MAX_NAME_LENGTH];
		GetClientName(client, clName, sizeof(clName));
		prevMAX[client] = -1;
		prevHP[client] = -1;
		if(nShowTank && StrContains(clName, "Tank", false) != -1){
			new max = GetMaxClients();
			for(new i=1; i<=max; i++){
				if(IsClientConnected(i)
				  && IsClientInGame(i)
				  && !IsFakeClient(i)
				  && GetClientTeam(i) == 2){
					PrintHintText(i, "++ %s is DEAD ++", clName);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(hPluginEnable))
	{
		return Action:0;
	}
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker", 0));
	
	if (!attacker || !IsClientConnected(attacker) || !IsClientInGame(attacker) || GetClientTeam(attacker) == 2)
	{
		return Action:0;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	
	if (!client || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) == 3)
	{
		return Action:0;
	}
	decl String:class[128];
	GetClientModel(client, class, 128);
	
	if (!nShowTank || (nShowTank && StrContains(class, "tank", false) == -1 && StrContains(class, "hulk", false) == -1))
	{
		return Action:0;
	}
	new maxBAR = GetConVarInt(hBarLEN);
	new nowHP = GetEventInt(event, "health", 0) & 65535;
	new maxHP = GetEntProp(client, PropType:0, "m_iMaxHealth", 4, 0) & 65535;
	
	if (nowHP <= 0 || prevMAX[client] < 0)
	{
		nowHP = 0;
	}
	
	if (nowHP && nowHP > prevHP[client])
	{
		nowHP = prevHP[client];
	}
	else
	{
		prevHP[client] = nowHP;
	}
	if (prevMAX[client] > maxHP)
	{
		maxHP = prevMAX[client];
	}
	if (maxHP < nowHP)
	{
		maxHP = nowHP;
		prevMAX[client] = nowHP;
	}
	if (maxHP < 1)
	{
		maxHP = 1;
	}
	decl String:clName[32];
	GetClientName(client, clName, 32);
	ShowHealthGauge(attacker, maxBAR, maxHP, nowHP, clName);
	return Action:0;
}

