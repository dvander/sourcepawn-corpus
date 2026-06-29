/*   
*    L4D2 Last Boss Reworked   
*    Copyright (C) 2025 ztar, JustMe   
*   
*    This program is free software: you can redistribute it and/or modify   
*    it under the terms of the GNU General Public License as published by   
*    the Free Software Foundation, either version 3 of the License, or   
*    (at your option) any later version.   
*   
*    This program is distributed in the hope that it will be useful,   
*    but WITHOUT ANY WARRANTY; without even the implied warranty of   
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the   
*    GNU General Public License for more details.   
*   
*    You should have received a copy of the GNU General Public License   
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.   
*/

#define PLUGIN_VERSION "2.0.5"

/*======================================================================================   
    Plugin Info:   
  
*     Name    :    [L4D2] Last Boss Reworked   
*     Author  :    ztar (original), JustMe (reworked)   
*     Descrp  :    Enhanced special Tank spawns.   
*     Link	  :    http://ztar.blog7.fc2.com/   
*     Plugins :    https://forums.alliedmods.net/showthread.php?t=351157   
*     Original:    https://forums.alliedmods.net/showthread.php?t=129013      
  
========================================================================================   
    Change Log:   

2.0.5 (17-May-2026)
	- Replaced crash-prone info_gamemode entity with L4D_GetGameModeType native.

2.0.4 (03-11-2025)
	- Improved code organization

2.0.3 (28-Oct-2025)
	- Add Cvar sm_lastboss_reworked_explode_on_death.

2.0.2.2 (20-Oct-2025)   
    - Fix codes. 
     
2.0.2 (16-Aug-2025)   
    - Fix codes.   
       
2.0.1 (09-Jun-2025)   
    - Reworked by JustMe.   
   
1.0.0 (Original Release)   
    - Initial release by ztar.   
   
======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <multicolors>

// ==================================================================================================== 
// Defines and Enums   
// ==================================================================================================== 
#define PLUGIN_NAME "[L4D2] Last Boss Reworked"
#define PLUGIN_PREFIX "l4d2_lastboss_reworked"

#define ZC_TANK 8
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define MODEL_GASCAN "models/props_junk/gascan001a.mdl"
#define MODEL_PROPANE "models/props_junk/propanecanister001a.mdl"
#define SOUND_EXPLODE "animation/bombing_run_01.wav"
#define SOUND_SPAWN "music/pzattack/contusion.wav"
#define SOUND_BCLAW "weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SOUND_GCLAW "plats/churchbell_end.wav"
#define SOUND_DCLAW "ambient/random_amb_sounds/randbridgegroan_03.wav"
#define SOUND_QUAKE "player/charger/hit/charger_smash_02.wav"
#define SOUND_STEEL "physics/metal/metal_solid_impact_hard5.wav"
#define SOUND_CHANGE "items/suitchargeok1.wav"
#define SOUND_HOWL "player/tank/voice/pain/tank_fire_08.wav"
#define SOUND_WARP "ambient/energy/zap9.wav"

#define PARTICLE_SPAWN "electrical_arc_01_system"
#define PARTICLE_DEATH "gas_explosion_main"
#define PARTICLE_THIRD "smoker_smokecloud"
#define PARTICLE_FORTH "aircraft_destroy_fastFireTrail"
#define PARTICLE_WARP "water_splash"

#define MSG_SPAWN "{olive}Prepare for the final battle! {lightgreen}Type-UNKNOWN{default}[FINAL BOSS]"
#define MSG_SECOND "{olive}Form changed -> {default}[STEEL OVERLOAD]"
#define MSG_THIRD "{olive}Form changed -> {default}[NIGHT HUNTER]"
#define MSG_FORTH "{olive}Form changed -> {default}[FIRE SPIRIT]"

enum Form {
	FORM_ONE = 1,
	FORM_TWO,
	FORM_THREE,
	FORM_FOUR,
	FORM_DEAD = -1
}

enum struct TankData {
	Form formPrev;
	bool bossActive;
	bool lastWave;
	int waveCount;
	int alphaRate;
	int visibility;
	float lastPos[3];
	int velocityOffset;
}

// ==================================================================================================== 
// Globals   
// ====================================================================================================
TankData
	g_TankData[MAXPLAYERS + 1];
	
ConVar
	g_hCvarEnable, g_hCvarAnnounce, g_hCvarSteel, g_hCvarStealth, g_hCvarGravity,
	g_hCvarBurn, g_hCvarQuake, g_hCvarJump, g_hCvarComet, g_hCvarDread,
	g_hCvarGush, g_hCvarAbyss, g_hCvarWarp, g_hCvarHealthMax, g_hCvarHealthSecond,
	g_hCvarHealthThird, g_hCvarHealthForth, g_hCvarColorFirst, g_hCvarColorSecond,
	g_hCvarColorThird, g_hCvarColorForth, g_hCvarForceFirst, g_hCvarForceSecond,
	g_hCvarForceThird, g_hCvarForceForth, g_hCvarSpeedFirst, g_hCvarSpeedSecond,
	g_hCvarSpeedThird, g_hCvarSpeedForth, g_hCvarWeightSecond, g_hCvarStealthThird,
	g_hCvarJumpIntervalForth, g_hCvarJumpHeightForth, g_hCvarGravityInterval,
	g_hCvarQuakeRadius, g_hCvarQuakeForce, g_hCvarDreadInterval, g_hCvarDreadRate,
	g_hCvarForthC5M5Bridge, g_hCvarWarpInterval, g_hCvarModes, g_hCvarModesOff,
	g_hCvarModesTog, g_hCvarMPGameMode, g_hCvarPlayBackRate, g_hCvarSetHealth,
	g_hCvarExplodeOnDeath;
	
Handle
	g_hTimerUpdate[MAXPLAYERS + 1];

bool
	g_bCvarAllow, g_bSetHealth, g_bCvarExplodeOnDeath, g_isFinale;

int
	g_iDefaultForce, g_iCurrentMode, g_iHealthMax, g_iHealthSecond, g_iHealthThird,
	g_iHealthForth, g_iForceFirst, g_iForceSecond, g_iForceThird, g_iForceForth,
	g_iDreadRate, g_waveCount;

float
	g_fSpeedFirst, g_fSpeedSecond, g_fSpeedThird, g_fSpeedForth, g_fWeightSecond,
	g_fStealthThird, g_fJumpIntervalForth, g_fJumpHeightForth, g_fGravityInterval,
	g_fQuakeRadius, g_fQuakeForce, g_fDreadInterval, g_fWarpInterval, g_fCvarPlayBackRate;

char
	g_sColorFirst[32], g_sColorSecond[32],
	g_sColorThird[32], g_sColorForth[32];



// ==================================================================================================== 
// Plugin Info / Start   
// ====================================================================================================
public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "ztar (original), JustMe (reworked)",
	description = "Enhanced special Tank spawns",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_iDefaultForce = GetConVarInt(FindConVar("z_tank_throw_force"));

	CreateConVar("sm_lastboss_reworked_version", PLUGIN_VERSION, "Plugin version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	g_hCvarEnable = CreateConVar(PLUGIN_PREFIX ... "_enable", "3", "Enable plugin (0:OFF 1:Finale Only 2:Always 3:Second Tank)", FCVAR_NOTIFY);
	g_hCvarAnnounce = CreateConVar(PLUGIN_PREFIX ... "_announce", "1", "Enable announcements (0:OFF 1:ON)", FCVAR_NOTIFY);
	
	g_hCvarSteel = CreateConVar(PLUGIN_PREFIX ... "_steel", "1", "Enable SteelSkin (0:OFF 1:ON)", FCVAR_NOTIFY);
	g_hCvarStealth = CreateConVar(PLUGIN_PREFIX ... "_stealth", "1", "Enable StealthSkin (0:OFF 1:ON)", FCVAR_NOTIFY);
	g_hCvarGravity = CreateConVar(PLUGIN_PREFIX ... "_gravity", "1", "Enable GravityClaw (0:OFF 1:ON)", FCVAR_NOTIFY);
	g_hCvarBurn = CreateConVar(PLUGIN_PREFIX ... "_burn", "1", "Enable BurnClaw (0:OFF 1:ON)", FCVAR_NOTIFY);
	g_hCvarQuake = CreateConVar(PLUGIN_PREFIX ... "_quake", "1", "Enable EarthQuake (0:OFF 1:ON)", FCVAR_NOTIFY);
	g_hCvarJump = CreateConVar(PLUGIN_PREFIX ... "_jump", "1", "Enable MadSpring (0:OFF 1:ON)", FCVAR_NOTIFY);
	g_hCvarComet = CreateConVar(PLUGIN_PREFIX ... "_comet", "1", "Enable BlastRock/CometStrike (0:OFF 1:ON)", FCVAR_NOTIFY);
	g_hCvarDread = CreateConVar(PLUGIN_PREFIX ... "_dread", "1", "Enable DreadClaw (0:OFF 1:ON)", FCVAR_NOTIFY);
	g_hCvarGush = CreateConVar(PLUGIN_PREFIX ... "_gush", "1", "Enable FlameGush (0:OFF 1:ON)", FCVAR_NOTIFY);
	g_hCvarAbyss = CreateConVar(PLUGIN_PREFIX ... "_abyss", "2", "Enable CallOfAbyss (0:OFF 1:Forth Form 2:All Forms)", FCVAR_NOTIFY);
	g_hCvarWarp = CreateConVar(PLUGIN_PREFIX ... "_warp", "1", "Enable FatalMirror (0:OFF 1:ON)", FCVAR_NOTIFY);
	g_hCvarExplodeOnDeath = CreateConVar(PLUGIN_PREFIX ... "_explode_on_death", "1", "Enable tank explosion on death (0:OFF 1:ON)", FCVAR_NOTIFY);
	
	//Health
	g_hCvarSetHealth = CreateConVar(PLUGIN_PREFIX ... "_set_health", "1", "Enable setting tank health (0:Use from other plugin, 1:Use this plugin's health)", FCVAR_NOTIFY);
	g_hCvarHealthMax = CreateConVar(PLUGIN_PREFIX ... "_health_max", "80000", "Max Health", FCVAR_NOTIFY);
	g_hCvarHealthSecond = CreateConVar(PLUGIN_PREFIX ... "_health_second", "60000", "Health (second form)", FCVAR_NOTIFY);
	g_hCvarHealthThird = CreateConVar(PLUGIN_PREFIX ... "_health_third", "40000", "Health (third form)", FCVAR_NOTIFY);
	g_hCvarHealthForth = CreateConVar(PLUGIN_PREFIX ... "_health_forth", "20000", "Health (fourth form)", FCVAR_NOTIFY);
	
	//Color
	g_hCvarColorFirst = CreateConVar(PLUGIN_PREFIX ... "_color_first", "255 255 80", "RGB for First form", FCVAR_NOTIFY);
	g_hCvarColorSecond = CreateConVar(PLUGIN_PREFIX ... "_color_second", "80 255 80", "RGB for Second form", FCVAR_NOTIFY);
	g_hCvarColorThird = CreateConVar(PLUGIN_PREFIX ... "_color_third", "80 80 255", "RGB for Third form", FCVAR_NOTIFY);
	g_hCvarColorForth = CreateConVar(PLUGIN_PREFIX ... "_color_forth", "255 80 80", "RGB for Fourth form", FCVAR_NOTIFY);
	
	//Force
	g_hCvarForceFirst = CreateConVar(PLUGIN_PREFIX ... "_force_first", "800", "Force (first form)", FCVAR_NOTIFY);
	g_hCvarForceSecond = CreateConVar(PLUGIN_PREFIX ... "_force_second", "825", "Force (second form)", FCVAR_NOTIFY);
	g_hCvarForceThird = CreateConVar(PLUGIN_PREFIX ... "_force_third", "835", "Force (third form)", FCVAR_NOTIFY);
	g_hCvarForceForth = CreateConVar(PLUGIN_PREFIX ... "_force_forth", "850", "Force (fourth form)", FCVAR_NOTIFY);
	
	//Speed
	g_hCvarSpeedFirst = CreateConVar(PLUGIN_PREFIX ... "_speed_first", "1.0", "Speed (first form)", FCVAR_NOTIFY);
	g_hCvarSpeedSecond = CreateConVar(PLUGIN_PREFIX ... "_speed_second", "1.1", "Speed (second form)", FCVAR_NOTIFY);
	g_hCvarSpeedThird = CreateConVar(PLUGIN_PREFIX ... "_speed_third", "1.15", "Speed (third form)", FCVAR_NOTIFY);
	g_hCvarSpeedForth = CreateConVar(PLUGIN_PREFIX ... "_speed_forth", "1.2", "Speed (fourth form)", FCVAR_NOTIFY);
	
	g_hCvarWeightSecond = CreateConVar(PLUGIN_PREFIX ... "_weight_second", "8.0", "Weight (second form)", FCVAR_NOTIFY);
	g_hCvarStealthThird = CreateConVar(PLUGIN_PREFIX ... "_stealth_third", "10.0", "Stealth interval (third form)", FCVAR_NOTIFY);
	g_hCvarJumpIntervalForth = CreateConVar(PLUGIN_PREFIX ... "_jumpinterval_forth", "1.0", "Jump interval (fourth form)", FCVAR_NOTIFY);
	g_hCvarJumpHeightForth = CreateConVar(PLUGIN_PREFIX ... "_jumpheight_forth", "300.0", "Jump height (fourth form)", FCVAR_NOTIFY);
	g_hCvarGravityInterval = CreateConVar(PLUGIN_PREFIX ... "_gravityinterval", "6.0", "Gravity claw interval", FCVAR_NOTIFY);
	g_hCvarQuakeRadius = CreateConVar(PLUGIN_PREFIX ... "_quake_radius", "600.0", "Earth Quake radius", FCVAR_NOTIFY);
	g_hCvarQuakeForce = CreateConVar(PLUGIN_PREFIX ... "_quake_force", "350.0", "Earth Quake force", FCVAR_NOTIFY);
	g_hCvarDreadInterval = CreateConVar(PLUGIN_PREFIX ... "_dreadinterval", "8.0", "Dread Claw interval", FCVAR_NOTIFY);
	g_hCvarDreadRate = CreateConVar(PLUGIN_PREFIX ... "_dreadrate", "235", "Dread Claw blind rate", FCVAR_NOTIFY);
	g_hCvarForthC5M5Bridge = CreateConVar(PLUGIN_PREFIX ... "_forth_c5m5_bridge", "0", "Start at fourth form in c5m5_bridge", FCVAR_NOTIFY);
	g_hCvarWarpInterval = CreateConVar(PLUGIN_PREFIX ... "_warp_interval", "35.0", "Fatal Mirror interval", FCVAR_NOTIFY);
	g_hCvarPlayBackRate = CreateConVar("ai_TankSequencePlayBackRate", "5.0", "play back rate", FCVAR_NOTIFY, true, 0.0);
	
	g_hCvarModes = CreateConVar(PLUGIN_PREFIX ... "_modes", "", "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all)", FCVAR_NOTIFY);
	g_hCvarModesOff = CreateConVar(PLUGIN_PREFIX ... "_modes_off", "", "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none)", FCVAR_NOTIFY);
	g_hCvarModesTog = CreateConVar(PLUGIN_PREFIX ... "_modes_tog", "0", "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", FCVAR_NOTIFY);

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarEnable.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarHealthMax.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthSecond.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthThird.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthForth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarColorFirst.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarColorSecond.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarColorThird.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarColorForth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarForceFirst.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarForceSecond.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarForceThird.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarForceForth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpeedFirst.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpeedSecond.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpeedThird.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpeedForth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWeightSecond.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStealthThird.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarJumpIntervalForth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarJumpHeightForth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGravityInterval.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarQuakeRadius.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarQuakeForce.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDreadInterval.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDreadRate.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarForthC5M5Bridge.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWarpInterval.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPlayBackRate.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSetHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarExplodeOnDeath.AddChangeHook(ConVarChanged_Cvars);
	
	IsAllowed();

	AutoExecConfig(true, PLUGIN_PREFIX);
}



// ==================================================================================================== 
// Config and Map Events   
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void OnMapStart()
{
	PrecacheAssets();
	ResetTankData();
}

public void OnMapEnd()
{
	ResetTankData();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iHealthMax = g_hCvarHealthMax.IntValue;
	g_iHealthSecond = g_hCvarHealthSecond.IntValue;
	g_iHealthThird = g_hCvarHealthThird.IntValue;
	g_iHealthForth = g_hCvarHealthForth.IntValue;

	g_hCvarColorFirst.GetString(g_sColorFirst, sizeof(g_sColorFirst));
	g_hCvarColorSecond.GetString(g_sColorSecond, sizeof(g_sColorSecond));
	g_hCvarColorThird.GetString(g_sColorThird, sizeof(g_sColorThird));
	g_hCvarColorForth.GetString(g_sColorForth, sizeof(g_sColorForth));

	g_iForceFirst = g_hCvarForceFirst.IntValue;
	g_iForceSecond = g_hCvarForceSecond.IntValue;
	g_iForceThird = g_hCvarForceThird.IntValue;
	g_iForceForth = g_hCvarForceForth.IntValue;

	g_fSpeedFirst = g_hCvarSpeedFirst.FloatValue;
	g_fSpeedSecond = g_hCvarSpeedSecond.FloatValue;
	g_fSpeedThird = g_hCvarSpeedThird.FloatValue;
	g_fSpeedForth = g_hCvarSpeedForth.FloatValue;

	g_fWeightSecond = g_hCvarWeightSecond.FloatValue;
	g_fStealthThird = g_hCvarStealthThird.FloatValue;
	g_fJumpIntervalForth = g_hCvarJumpIntervalForth.FloatValue;
	g_fJumpHeightForth = g_hCvarJumpHeightForth.FloatValue;
	g_fGravityInterval = g_hCvarGravityInterval.FloatValue;
	g_fQuakeRadius = g_hCvarQuakeRadius.FloatValue;
	g_fQuakeForce = g_hCvarQuakeForce.FloatValue;
	g_fDreadInterval = g_hCvarDreadInterval.FloatValue;
	g_iDreadRate = g_hCvarDreadRate.IntValue;
	g_fWarpInterval = g_hCvarWarpInterval.FloatValue;
	g_fCvarPlayBackRate = g_hCvarPlayBackRate.FloatValue;

	g_bSetHealth = g_hCvarSetHealth.BoolValue;
	g_bCvarExplodeOnDeath = g_hCvarExplodeOnDeath.BoolValue;
}

void IsAllowed()
{
	int cvarEnable = g_hCvarEnable.IntValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if (!g_bCvarAllow && cvarEnable > 0 && bAllowMode)
	{
		g_bCvarAllow = true;
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("finale_start", Event_FinaleStart, EventHookMode_PostNoCopy);
		HookEvent("finale_vehicle_incoming", Event_FinaleLast, EventHookMode_PostNoCopy);
		HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
		HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
		HookEvent("player_incapacitated", Event_PlayerHurt, EventHookMode_Post);
		HookEvent("finale_bridge_lowering", Event_FinaleStart, EventHookMode_PostNoCopy);
		HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	}
	else if (g_bCvarAllow && (cvarEnable == 0 || !bAllowMode))
	{
		g_bCvarAllow = false;
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("finale_start", Event_FinaleStart, EventHookMode_PostNoCopy);
		UnhookEvent("finale_vehicle_incoming", Event_FinaleLast, EventHookMode_PostNoCopy);
		UnhookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
		UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
		UnhookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
		UnhookEvent("player_incapacitated", Event_PlayerHurt, EventHookMode_Post);
		UnhookEvent("finale_bridge_lowering", Event_FinaleStart, EventHookMode_PostNoCopy);
		UnhookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
		ResetTankData();
	}
}

bool IsAllowedGameMode()
{
    if (g_hCvarMPGameMode == null)
        return false;

    int iCvarModesTog = g_hCvarModesTog.IntValue;
    if (iCvarModesTog != 0)
    {
        if (g_iCurrentMode == 0)
        {
            if (!L4D_HasMapStarted())
                return false;
            g_iCurrentMode = L4D_GetGameModeType();
        }

        if (g_iCurrentMode == 0)
            return false;

        if (!(iCvarModesTog & g_iCurrentMode))
            return false;
    }

    char sGameModes[64], sGameMode[64];
    g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
    Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

    g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
    if (sGameModes[0])
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) == -1)
            return false;
    }

    g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
    if (sGameModes[0])
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) != -1)
            return false;
    }

    return true;
}



// ==================================================================================================== 
// Precache and Reset
// ==================================================================================================== 
void ResetTankData()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		ResetSingleTankData(i);
	}
	g_isFinale = false;
	g_waveCount = 0;
	SetConVarInt(FindConVar("z_tank_throw_force"), g_iDefaultForce, true, true);
}

void ResetSingleTankData(int client)
{
	g_TankData[client].formPrev = FORM_DEAD;
	g_TankData[client].bossActive = false;
	g_TankData[client].lastWave = false;
	g_TankData[client].waveCount = 0;
	g_TankData[client].alphaRate = 255;
	g_TankData[client].visibility = 0;
	g_TankData[client].lastPos = { 0.0, 0.0, 0.0 };
	delete g_hTimerUpdate[client];
}

void PrecacheAssets()
{
	PrecacheModel(MODEL_PROPANE, true);
	PrecacheModel(MODEL_GASCAN, true);

	PrecacheSound(SOUND_EXPLODE, true);
	PrecacheSound(SOUND_SPAWN, true);
	PrecacheSound(SOUND_BCLAW, true);
	PrecacheSound(SOUND_GCLAW, true);
	PrecacheSound(SOUND_DCLAW, true);
	PrecacheSound(SOUND_QUAKE, true);
	PrecacheSound(SOUND_STEEL, true);
	PrecacheSound(SOUND_CHANGE, true);
	PrecacheSound(SOUND_HOWL, true);
	PrecacheSound(SOUND_WARP, true);

	Precache_Particle_System(PARTICLE_SPAWN);
	Precache_Particle_System(PARTICLE_DEATH);
	Precache_Particle_System(PARTICLE_THIRD);
	Precache_Particle_System(PARTICLE_FORTH);
	Precache_Particle_System(PARTICLE_WARP);

	int shake = CreateEntityByName("env_shake");
	if (shake != -1)
	{
		DispatchKeyValue(shake, "spawnflags", "8");
		DispatchKeyValue(shake, "amplitude", "16.0");
		DispatchKeyValue(shake, "frequency", "1.5");
		DispatchKeyValue(shake, "duration", "0.9");
		DispatchKeyValue(shake, "radius", "50");
		TeleportEntity(shake, view_as<float>( { 0.0, 0.0, -1000.0 } ), NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(shake);
		ActivateEntity(shake);
		AcceptEntityInput(shake, "Enable");
		AcceptEntityInput(shake, "StartShake");
		RemoveEntity(shake);
	}
}



// ==================================================================================================== 
// Events   
// ====================================================================================================
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_isFinale = false;
	g_waveCount = 0;
	ResetTankData();
}

public void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	g_isFinale = true;
	char currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));
	g_waveCount = (StrEqual(currentMap, "c1m4_atrium") || StrEqual(currentMap, "c5m5_bridge")) ? 2 : 1;
}

public void Event_FinaleLast(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			g_TankData[i].lastWave = true;
		}
	}
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK)
	{
		ResetSingleTankData(client);
	}
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarAllow) return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client)) return;

	g_TankData[client].bossActive = g_isFinale;
	g_TankData[client].waveCount = g_waveCount;

	if (g_TankData[client].waveCount < 2 && g_hCvarEnable.IntValue == 3) return;

	if ((g_TankData[client].bossActive && g_hCvarEnable.IntValue == 1) ||
		g_hCvarEnable.IntValue == 2 ||
		(g_TankData[client].bossActive && g_hCvarEnable.IntValue == 3))
	{
		g_TankData[client].bossActive = true;

		Form startForm = FORM_ONE;
		char currentMap[64];
		GetCurrentMap(currentMap, sizeof(currentMap));
		if (g_TankData[client].lastWave || (StrEqual(currentMap, "c5m5_bridge") && g_hCvarForthC5M5Bridge.BoolValue))
		{
			startForm = FORM_FOUR;
		}

		g_TankData[client].formPrev = startForm;
		SetParameters(client, startForm);

		if (g_bSetHealth)
		{
			CreateTimer(0.3, Timer_SetTankHealth, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.4, Timer_AnnounceTank, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			CreateTimer(0.5, Timer_AnnounceTank, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}

		delete g_hTimerUpdate[client];
		g_hTimerUpdate[client] = CreateTimer(1.0, Timer_TankUpdate, client, TIMER_REPEAT);

		SDKHook(client, SDKHook_PostThinkPost, UpdateThink);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarAllow) return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_TANK) return;

	if (g_waveCount < 2 && g_hCvarEnable.IntValue == 3)
	{
		g_waveCount++;
		return;
	}

	if (g_TankData[client].bossActive)
	{
		if (g_bCvarExplodeOnDeath)
		{
			float pos[3];
			GetClientAbsOrigin(client, pos);
			EmitSoundToAll(SOUND_EXPLODE, client);
			ShowParticle(pos, PARTICLE_DEATH, 10.0);
			LittleFlower(pos, 0); // MOLOTOV
			LittleFlower(pos, 1); // EXPLODE
		}
		ResetSingleTankData(client);
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarAllow) return;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int target = GetClientOfUserId(event.GetInt("userid"));
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));

	if (g_TankData[attacker].bossActive && StrEqual(weapon, "tank_claw") && GetEntProp(attacker, Prop_Send, "m_zombieClass") == ZC_TANK)
	{
		if (g_hCvarQuake.BoolValue && IsClientIncapped(target))
		{
			SkillEarthQuake(attacker, target);
		}
		if (g_hCvarGravity.BoolValue && g_TankData[attacker].formPrev == FORM_TWO)
		{
			SkillGravityClaw(target);
		}
		if (g_hCvarDread.BoolValue && g_TankData[attacker].formPrev == FORM_THREE)
		{
			SkillDreadClaw(target);
		}
		if (g_hCvarBurn.BoolValue && g_TankData[attacker].formPrev == FORM_FOUR)
		{
			SkillBurnClaw(target);
		}
	}

	if (g_TankData[attacker].bossActive && StrEqual(weapon, "tank_rock") && g_hCvarComet.BoolValue)
	{
		SkillCometStrike(target, g_TankData[attacker].formPrev == FORM_FOUR ? 0 : 1);
	}

	if (StrEqual(weapon, "melee") && g_TankData[target].bossActive)
	{
		if (g_hCvarSteel.BoolValue && g_TankData[target].formPrev == FORM_TWO)
		{
			EmitSoundToClient(attacker, SOUND_STEEL);
			SetEntityHealth(target, GetEventInt(event, "dmg_health") + GetEventInt(event, "health"));
		}
		if (g_hCvarGush.BoolValue && g_TankData[target].formPrev == FORM_FOUR)
		{
			SkillFlameGush(target, attacker);
		}
	}
}



// ==================================================================================================== 
// Timers   
// ==================================================================================================== 
Action Timer_SetTankHealth(Handle timer, int client)
{
	char currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if (IsValidClient(client))
	{
		int finalHealth = (g_TankData[client].lastWave || (StrEqual(currentMap, "c5m5_bridge") && g_hCvarForthC5M5Bridge.BoolValue)) ? g_iHealthForth : g_iHealthMax;
		SetEntProp(client, Prop_Data, "m_iHealth", finalHealth);
		SetEntProp(client, Prop_Data, "m_iMaxHealth", finalHealth);
	}
	return Plugin_Stop;
}

Action Timer_AnnounceTank(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client))
	{
		Form form = g_TankData[client].formPrev;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				EmitSoundToClient(i, SOUND_SPAWN);
				CPrintToChat(i, MSG_SPAWN);
			}
		}
		int actualHealth = GetEntProp(client, Prop_Data, "m_iHealth");
		float actualSpeed = (form == FORM_FOUR) ? g_fSpeedForth : g_fSpeedFirst;
		CPrintToChatAll("{olive}Health: {lightgreen}%d {olive}Speed: {lightgreen}%.1f", actualHealth, actualSpeed);
	}
	return Plugin_Stop;
}

Action Timer_TankUpdate(Handle timer, int client)
{
	if (!IsValidClient(client) || !g_TankData[client].bossActive)
	{
		g_hTimerUpdate[client] = null;
		return Plugin_Stop;
	}

	if (g_TankData[client].waveCount < 2 && g_hCvarEnable.IntValue == 3)
	{
		return Plugin_Continue;
	}

	int health = GetClientHealth(client);
	int maxhealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");

	if (g_bSetHealth)
	{
		if (health > g_iHealthSecond)
		{
			if (g_TankData[client].formPrev != FORM_ONE)
				SetParameters(client, FORM_ONE);
		}
		else if (health > g_iHealthThird)
		{
			if (g_TankData[client].formPrev != FORM_TWO)
				SetParameters(client, FORM_TWO);
		}
		else if (health > g_iHealthForth)
		{
			ExtinguishEntity(client);
			if (g_TankData[client].formPrev != FORM_THREE)
				SetParameters(client, FORM_THREE);
		}
		else if (health > 0)
		{
			if (g_TankData[client].formPrev != FORM_FOUR)
				SetParameters(client, FORM_FOUR);
		}
	}
	else
	{
		float propSecond = float(g_iHealthSecond) / float(g_iHealthMax);
		float propThird = float(g_iHealthThird) / float(g_iHealthMax);
		float propForth = float(g_iHealthForth) / float(g_iHealthMax);

		int threshSecond = RoundToFloor(float(maxhealth) * propSecond);
		int threshThird = RoundToFloor(float(maxhealth) * propThird);
		int threshForth = RoundToFloor(float(maxhealth) * propForth);

		if (health > threshSecond)
		{
			if (g_TankData[client].formPrev != FORM_ONE)
				SetParameters(client, FORM_ONE);
		}
		else if (health > threshThird)
		{
			if (g_TankData[client].formPrev != FORM_TWO)
				SetParameters(client, FORM_TWO);
		}
		else if (health > threshForth)
		{
			ExtinguishEntity(client);
			if (g_TankData[client].formPrev != FORM_THREE)
				SetParameters(client, FORM_THREE);
		}
		else if (health > 0)
		{
			if (g_TankData[client].formPrev != FORM_FOUR)
				SetParameters(client, FORM_FOUR);
		}
	}
	return Plugin_Continue;
}

Action Timer_Particle(Handle timer, int client)
{
	if (!IsValidClient(client)) return Plugin_Stop;

	if (g_TankData[client].formPrev == FORM_THREE)
	{
		TE_SetupParticleFollowEntity_Name(PARTICLE_THIRD, client);
		TE_SendToAll();
	}
	else if (g_TankData[client].formPrev == FORM_FOUR)
	{
		TE_SetupParticleFollowEntity_Name(PARTICLE_FORTH, client);
		TE_SendToAll();
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

Action Timer_Gravity(Handle timer, int target)
{
	if (IsValidClient(target))
		SetEntityGravity(target, 1.0);
	return Plugin_Stop;
}

Action Timer_Jumping(Handle timer, int client)
{
	if (g_TankData[client].formPrev == FORM_FOUR && IsValidClient(client))
	{
		AddVelocity(client, g_fJumpHeightForth);
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

Action Timer_Stealth(Handle timer, int client)
{
	if (g_TankData[client].formPrev == FORM_THREE && IsValidClient(client))
	{
		g_TankData[client].alphaRate = 255;
		Remove(client);
	}
	return Plugin_Stop;
}

Action Timer_Dread(Handle timer, int target)
{
	g_TankData[target].visibility -= 8;
	if (g_TankData[target].visibility < 0)
		g_TankData[target].visibility = 0;

	if (IsValidClient(target))
	{
		ScreenFade(target, 0, 0, 0, g_TankData[target].visibility, 0, 1);
	}

	if (g_TankData[target].visibility <= 0)
		return Plugin_Stop;

	return Plugin_Continue;
}

Action Timer_Howl(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	return Plugin_Stop;
}

Action Timer_Warp(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		if (!g_TankData[client].lastWave)
		{
			return Plugin_Stop;
		}

		float pos[3];
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
			EmitSoundToClient(i, SOUND_WARP);
		}
		GetClientAbsOrigin(client, pos);
		TE_SetupParticle_Name(PARTICLE_WARP, pos);
		TE_SendToAll();
		TeleportEntity(client, g_TankData[client].lastPos, NULL_VECTOR, NULL_VECTOR);
		TE_SetupParticle_Name(PARTICLE_WARP, g_TankData[client].lastPos);
		TE_SendToAll();
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	return Plugin_Stop;
}

Action Timer_GetSurvivorPosition(Handle timer, int client)
{
	if (!IsValidClient(client)) return Plugin_Stop;

	int count = 0;
	int idAlive[MAXPLAYERS + 1];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		idAlive[count] = i;
		count++;
	}
	if (count == 0) return Plugin_Stop;

	int clientNum = GetRandomInt(0, count - 1);
	GetClientAbsOrigin(idAlive[clientNum], g_TankData[client].lastPos);
	return Plugin_Continue;
}

Action Timer_FatalMirror(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		if (!g_TankData[client].lastWave)
		{
			return Plugin_Stop;
		}

		SetEntityMoveType(client, MOVETYPE_NONE);
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		CreateTimer(1.5, Timer_Warp, client);
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

Action Timer_FadeOut(Handle timer, int ent)
{
	if (!IsValidEntity(ent) || g_TankData[ent].formPrev != FORM_THREE) return Plugin_Stop;

	g_TankData[ent].alphaRate -= 2;
	if (g_TankData[ent].alphaRate < 0)
		g_TankData[ent].alphaRate = 0;

	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 80, 80, 255, g_TankData[ent].alphaRate);

	if (g_TankData[ent].alphaRate <= 0)
		return Plugin_Stop;

	return Plugin_Continue;
}



// ==================================================================================================== 
// Skills   
// ====================================================================================================
void SkillEarthQuake(int tank, int target)
{
	if (!IsValidClient(target) || !IsClientIncapped(target)) return;

	float pos[3], tPos[3];
	GetClientAbsOrigin(tank, pos);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == tank || !IsValidClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		GetClientAbsOrigin(i, tPos);
		if (GetVectorDistance(tPos, pos) < g_fQuakeRadius)
		{
			EmitSoundToClient(i, SOUND_QUAKE);
			Smash(tank, i, g_fQuakeForce, 1.0, 1.5);
		}
	}
	CreateShake(60.0, g_fQuakeRadius, pos);
}

void SkillDreadClaw(int target)
{
	g_TankData[target].visibility = g_iDreadRate;
	CreateTimer(g_fDreadInterval, Timer_Dread, target);
	EmitSoundToAll(SOUND_DCLAW, target);
	ScreenFade(target, 0, 0, 0, g_TankData[target].visibility, 0, 0);
}

void SkillGravityClaw(int target)
{
	SetEntityGravity(target, 0.3);
	CreateTimer(g_fGravityInterval, Timer_Gravity, target);
	EmitSoundToAll(SOUND_GCLAW, target);
	ScreenFade(target, 0, 0, 100, 80, 4000, 1);
	ScreenShake(target, 30.0);
}

void SkillBurnClaw(int target)
{
	int health = GetClientHealth(target);
	if (health > 0 && !IsClientIncapped(target))
	{
		SetEntityHealth(target, 1);
		SetEntPropFloat(target, Prop_Send, "m_healthBuffer", float(health));
	}
	EmitSoundToAll(SOUND_BCLAW, target);
	ScreenFade(target, 200, 0, 0, 150, 80, 1);
	ScreenShake(target, 50.0);
}

void SkillCometStrike(int target, int type)
{
	float pos[3];
	GetClientAbsOrigin(target, pos);
	if (type == 0) // MOLOTOV
	{
		LittleFlower(pos, 1); // EXPLODE
		LittleFlower(pos, 0); // MOLOTOV
	}
	else
	{
		LittleFlower(pos, 1); // EXPLODE
	}
}

void SkillFlameGush(int tank, int target)
{
	SkillBurnClaw(target);
	float pos[3];
	GetClientAbsOrigin(tank, pos);
	LittleFlower(pos, 0); // MOLOTOV
}

void SkillCallOfAbyss(int tank)
{
	SetEntityMoveType(tank, MOVETYPE_NONE);
	SetEntProp(tank, Prop_Data, "m_takedamage", 0, 1);
	float pos[3];
	GetClientAbsOrigin(tank, pos);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		EmitSoundToClient(i, SOUND_HOWL);
	}
	CreateShake(20.0, 0.0, pos);
	if ((g_TankData[tank].formPrev == FORM_FOUR && g_hCvarAbyss.IntValue == 1) || g_hCvarAbyss.IntValue == 2)
	{
		TriggerPanicEvent();
	}
	CreateTimer(5.0, Timer_Howl, tank);
}

void SetParameters(int client, Form formNext)
{
	g_TankData[client].formPrev = formNext;
	int force;
	float speed;
	char color[32];

	if (formNext != FORM_ONE)
	{
		if (g_hCvarAbyss.BoolValue)
			SkillCallOfAbyss(client);
		ExtinguishEntity(client);
		TE_SetupParticleFollowEntity_Name(PARTICLE_SPAWN, client);
		TE_SendToAll();
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
			EmitSoundToClient(i, SOUND_CHANGE);
			ScreenFade(i, 200, 200, 255, 255, 100, 1);
		}
	}

	switch (formNext)
	{
		case FORM_ONE:
		{
			force = g_iForceFirst;
			speed = g_fSpeedFirst;
			strcopy(color, sizeof(color), g_sColorFirst);
			if (g_hCvarWarp.BoolValue)
			{
				CreateTimer(3.0, Timer_GetSurvivorPosition, client, TIMER_REPEAT);
				if (g_TankData[client].lastWave)
				{
					CreateTimer(g_fWarpInterval, Timer_FatalMirror, client, TIMER_REPEAT);
				}
			}
		}
		case FORM_TWO:
		{
			if (g_hCvarAnnounce.BoolValue)
				CPrintToChatAll(MSG_SECOND);
			force = g_iForceSecond;
			speed = g_fSpeedSecond;
			strcopy(color, sizeof(color), g_sColorSecond);
			SetEntityGravity(client, g_fWeightSecond);
		}
		case FORM_THREE:
		{
			if (g_hCvarAnnounce.BoolValue)
				CPrintToChatAll(MSG_THIRD);
			force = g_iForceThird;
			speed = g_fSpeedThird;
			strcopy(color, sizeof(color), g_sColorThird);
			SetEntityGravity(client, 1.0);
			CreateTimer(0.8, Timer_Particle, client, TIMER_REPEAT);
			if (g_hCvarStealth.BoolValue)
				CreateTimer(g_fStealthThird, Timer_Stealth, client);
		}
		case FORM_FOUR:
		{
			if (g_hCvarAnnounce.BoolValue)
				CPrintToChatAll(MSG_FORTH);
			force = g_iForceForth;
			speed = g_fSpeedForth;
			strcopy(color, sizeof(color), g_sColorForth);
			SetEntityGravity(client, 1.0);
			IgniteEntity(client, 9999.9);
			if (g_hCvarJump.BoolValue)
				CreateTimer(g_fJumpIntervalForth, Timer_Jumping, client, TIMER_REPEAT);
		}
	}

	SetConVarInt(FindConVar("z_tank_throw_force"), force, true, true);
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
	SetEntityRenderMode(client, RENDER_NORMAL);
	DispatchKeyValue(client, "rendercolor", color);
}



// ==================================================================================================== 
// Utility Functions   
// ==================================================================================================== 
void Remove(int ent)
{
	if (IsValidEntity(ent))
	{
		CreateTimer(0.1, Timer_FadeOut, ent, TIMER_REPEAT);
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	}
}

void AddVelocity(int client, float zSpeed)
{
	int velocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	if (velocityOffset == -1) return;

	float vecVelocity[3];
	GetEntDataVector(client, velocityOffset, vecVelocity);
	vecVelocity[2] += zSpeed;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

void LittleFlower(float pos[3], int type)
{
	int entity = CreateEntityByName("prop_physics");
	if (IsValidEntity(entity))
	{
		pos[2] += 10.0;
		DispatchKeyValue(entity, "model", type == 0 ? MODEL_GASCAN : MODEL_PROPANE);
		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}
}

void Smash(int client, int target, float power, float powHor, float powVec)
{
	float headingVector[3], aimVector[3];
	GetClientEyeAngles(client, headingVector);
	aimVector[0] = Cosine(DegToRad(headingVector[1])) * power * powHor;
	aimVector[1] = Sine(DegToRad(headingVector[1])) * power * powHor;

	float current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);

	float resulting[3];
	resulting[0] = current[0] + aimVector[0];
	resulting[1] = current[1] + aimVector[1];
	resulting[2] = power * powVec;
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

void ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	BfWriteShort(msg, type == 0 ? (0x0002 | 0x0008) : (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

void ScreenShake(int target, float intensity)
{
	float pos[3];
	GetClientAbsOrigin(target, pos);
	CreateShake(intensity, 50.0, pos);
}

void CreateShake(float intensity, float range, float vPos[3])
{
	int entity = CreateEntityByName("env_shake");
	if (entity == -1)
	{
		LogError("Failed to create 'env_shake'");
		return;
	}
	char sTemp[8];
	FloatToString(intensity, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "amplitude", sTemp);
	DispatchKeyValue(entity, "frequency", "10.0");
	DispatchKeyValue(entity, "duration", "3.0");
	FloatToString(range, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "radius", sTemp);
	DispatchKeyValue(entity, "spawnflags", "8");
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Enable");
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "StartShake");
	RemoveEntity(entity);
}

void TriggerPanicEvent()
{
	int flager = GetAnyClient();
	if (flager == -1) return;
	int flag = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flag & ~FCVAR_CHEAT);
	FakeClientCommand(flager, "director_force_panic_event");
}

void ShowParticle(float pos[3], char[] particleName, float time)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particleName);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, Timer_DeleteParticles, particle);
	}
}

Action Timer_DeleteParticles(Handle timer, int particle)
{
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			RemoveEntity(particle);
		}
	}
	return Plugin_Stop;
}

void UpdateThink(int client)
{
	switch (GetEntProp(client, Prop_Send, "m_nSequence"))
	{
		case 15, 16, 17, 18, 19, 20, 21, 22, 23:
		{
			SetEntPropFloat(client, Prop_Send, "m_flPlaybackRate", g_fCvarPlayBackRate);
		}
		case 54, 55, 56, 57, 58, 59, 60:
		{
			SetEntPropFloat(client, Prop_Send, "m_flPlaybackRate", 999.0);
		}
	}
}

int GetAnyClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i)) return i;
	}
	return -1;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool IsClientIncapped(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)) { return false; }
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}