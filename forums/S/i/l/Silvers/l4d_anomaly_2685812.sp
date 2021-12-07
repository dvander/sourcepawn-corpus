/*
*	Anomaly
*	Copyright (C) 2021 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"1.6"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Anomaly
*	Author	:	SilverShot
*	Descrp	:	Randomly spawns an anomaly somewhere on the map that moves around and electrocutes people.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321872
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.6 (20-Jun-2021)
	- Fixed not deleting the Anomaly when the plugin was toggled off.

1.5 (10-Apr-2021)
	- Fixed affecting players who have not spawned and are Special Infected ghosts.
	- Fixed damage cvars not applying correctly to Special Infected.

1.4 (15-May-2020)
	- Replaced "point_hurt" entity with "SDKHooks_TakeDamage" function.

1.3 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.2 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.1 (05-Mar-2020)
	- Now spawns in the same place for both Versus teams.

1.0 (04-Mar-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// #include <left4dhooks>
// Instead of using the include above. Adding these here so it compiles on the forum. Plugin will fail without left4dhooks being present anyway.
native bool L4D_GetRandomPZSpawnPosition(int client, int zombieClass, int attempts, float vecPos[3]);
native float L4D2Direct_GetFlowDistance(int client);
native float L4D2Direct_GetMapMaxFlowDistance();
native int L4D_GetHighestFlowSurvivor();


#define CVAR_FLAGS				FCVAR_NOTIFY
#define DEBUG					0		// 0=Off. 1=Flow + location. 2=With glow outline.

#define GROUND_HEIGHT			40.0	// Height to spawn above ground
#define TICK_THINK				0.1 	// How often the think tick fires
#define TICK_MOVE				2.0		// How often the move tick fires
#define TICK_HEIGHT				1.0		// How often the height tick fires

#define MODEL_SPRITE			"models/sprites/glow01.spr"
#define PARTICLE_ELMOS			"st_elmos_fire_cp0"
#define PARTICLE_TES1			"electrical_arc_01"
#define PARTICLE_TES2			"electrical_arc_01_system"
#define PARTICLE_TES3			"st_elmos_fire"
#define SOUND_VENDOR1			"ambient/spacial_loops/vendingmachinehum_loop.wav"
#define SOUND_VENDOR2			"ambient/ambience/generator_amb01_loop.wav"
#define SOUND_VENDOR3			"ambient/spacial_loops/fluorescent_lights_loop.wav"

static const char g_sSoundsZap[][]	=
{
	"ambient/energy/zap1.wav",
	"ambient/energy/zap2.wav",
	"ambient/energy/zap3.wav",
	"ambient/energy/zap5.wav",
	"ambient/energy/zap6.wav",
	"ambient/energy/zap7.wav",
	"ambient/energy/zap8.wav",
	"ambient/energy/zap9.wav"
};


ConVar g_hCvarAllow, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarDamageDist, g_hCvarDamageInfe, g_hCvarDamageSpec, g_hCvarDamageSurv, g_hCvarDamageWitch, g_hCvarDamageTime,
		g_hCvarRandDist, g_hCvarRandMax, g_hCvarRandMin, g_hCvarSpawnMax, g_hCvarSpawnMin, g_hCvarMPGameMode;

Handle g_hTimer;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;
float g_fCvarDamageDist, g_fCvarDamageTime, g_fCvarRandDist, g_fCvarRandMax, g_fCvarRandMin, g_fCvarSpawnMax, g_fCvarSpawnMin, g_fFlowMax, g_fFlowMin, g_fRandNext;
float g_fTickDmgs, g_fTickMove, g_fTickHeight, g_vLastPos[3], g_vSpawnPos[3];
int g_iCvarDamageInfe, g_iCvarDamageSpec, g_iCvarDamageSurv, g_iCvarDamageWitch;
int g_iAnomaly;
int g_iLighting;
int g_iPlayerSpawn, g_iRoundStart;



// ====================================================================================================
//					PLUGIN
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Anomaly",
	author = "SilverShot",
	description = "Randomly spawns an anomaly somewhere on the map that moves around and electrocutes people.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=321872"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow =			CreateConVar(	"l4d_anomaly_allow",				"1",					"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_anomaly_modes",				"",						"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_anomaly_modes_off",			"",						"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_anomaly_modes_tog",			"0",					"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarDamageDist =		CreateConVar(	"l4d_anomaly_damage_distance",		"250.0",				"How close entities must be to the anomaly before being struck.", CVAR_FLAGS );
	g_hCvarDamageInfe =		CreateConVar(	"l4d_anomaly_damage_infected",		"20",					"0.0=Off, also disables effects. The amount of damage to deal to Common Infected when being struck.", CVAR_FLAGS );
	g_hCvarDamageSpec =		CreateConVar(	"l4d_anomaly_damage_special",		"20",					"0.0=Off, also disables effects. The amount of damage to deal to Special Infected when being struck.", CVAR_FLAGS );
	g_hCvarDamageSurv =		CreateConVar(	"l4d_anomaly_damage_survivor",		"10",					"0.0=Off, also disables effects. The amount of damage to deal to Survivors when being struck.", CVAR_FLAGS );
	g_hCvarDamageWitch =	CreateConVar(	"l4d_anomaly_damage_witch",			"50",					"0.0=Off, also disables effects. The amount of damage to deal to Witches when being struck.", CVAR_FLAGS );
	g_hCvarDamageTime =		CreateConVar(	"l4d_anomaly_damage_time",			"1.5",					"How often to damage entities within range.", CVAR_FLAGS );
	g_hCvarRandDist =		CreateConVar(	"l4d_anomaly_random_dist",			"200.0",				"How far can random sparks shoot out. These do not affect players and only visual effect.", CVAR_FLAGS );
	g_hCvarRandMax =		CreateConVar(	"l4d_anomaly_random_max",			"5.0",					"0.0=Off. Display random sparks and sound after this many seconds maximum.", CVAR_FLAGS );
	g_hCvarRandMin =		CreateConVar(	"l4d_anomaly_random_min",			"2.0",					"0.0=Off. Display random sparks and sound after this many seconds minimum.", CVAR_FLAGS );
	g_hCvarSpawnMax =		CreateConVar(	"l4d_anomaly_spawn_max",			"70.0",					"0.0=Off. Automatically spawns anomaly when Survivors pass between this minimum and maximum map flow distance percent.", CVAR_FLAGS, true, 0.0, true, 100.0 );
	g_hCvarSpawnMin =		CreateConVar(	"l4d_anomaly_spawn_min",			"20.0",					"0.0=Off. Automatically spawns anomaly when Survivors pass between this minimum and maximum map flow distance percent.", CVAR_FLAGS, true, 0.0, true, 100.0 );
	CreateConVar(							"l4d_anomaly_version",				PLUGIN_VERSION,			"Anomaly plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_anomaly");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);

	g_hCvarDamageDist.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDamageInfe.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDamageSpec.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDamageSurv.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDamageWitch.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDamageTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRandMax.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRandMin.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpawnMax.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpawnMin.AddChangeHook(ConVarChanged_Cvars);



	// ====================================================================================================
	// COMMANDS
	// ====================================================================================================
	RegAdminCmd("sm_anomaly",	CmdAnomaly,	ADMFLAG_ROOT, "Create an Anomaly where your crosshair is pointing.");
	RegAdminCmd("sm_anom",		CmdAnom,	ADMFLAG_ROOT, "Create an Anomaly near you using the random spawn placement system.");
}

public void OnPluginEnd()
{
	DeleteAnomaly(g_iAnomaly);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	g_vSpawnPos = view_as<float>({ 0.0, 0.0, 0.0 });

	DeleteAnomaly(g_iAnomaly);
	delete g_hTimer;
}

public void OnMapStart()
{
	g_bMapStarted = true;

	PrecacheModel(MODEL_SPRITE);

	PrecacheParticle(PARTICLE_ELMOS);
	PrecacheParticle(PARTICLE_TES1);
	PrecacheParticle(PARTICLE_TES2);
	PrecacheParticle(PARTICLE_TES3);

	PrecacheSound(SOUND_VENDOR1);
	PrecacheSound(SOUND_VENDOR2);
	PrecacheSound(SOUND_VENDOR3);

	for( int i = 0; i < sizeof(g_sSoundsZap); i++ ) PrecacheSound(g_sSoundsZap[i], true);
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
public Action CmdAnom(int client, int args)
{
	float vPos[3];
	L4D_GetRandomPZSpawnPosition(client, g_bLeft4Dead2 ? 5 : 0, 10, vPos);

	CreateAnomaly(vPos);
	return Plugin_Handled;
}

public Action CmdAnomaly(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	float vPos[3], vAng[3];
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	if( SetTeleportEndPoint(client, vPos, vAng) == false )
	{
		ReplyToCommand(client, "Invalid position, try again.");
		return Plugin_Handled;
	}

	vPos[2] += GROUND_HEIGHT;
	CreateAnomaly(vPos);

	return Plugin_Handled;
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();

	// Select the same flow distance for both Versus teams, this is called once per map.
	g_fFlowMin = GetRandomFloat(g_fCvarSpawnMin, g_fCvarSpawnMax);

	#if DEBUG
	PrintToServer("Anomaly selected to spawn after flow: %f", g_fFlowMin);
	#endif
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fCvarDamageDist = g_hCvarDamageDist.FloatValue;
	g_iCvarDamageInfe = g_hCvarDamageInfe.IntValue;
	g_iCvarDamageSpec = g_hCvarDamageSpec.IntValue;
	g_iCvarDamageSurv = g_hCvarDamageSurv.IntValue;
	g_iCvarDamageWitch = g_hCvarDamageWitch.IntValue;
	g_fCvarDamageTime = g_hCvarDamageTime.FloatValue;
	g_fCvarRandDist = g_hCvarRandDist.FloatValue;
	g_fCvarRandMax = g_hCvarRandMax.FloatValue;
	g_fCvarRandMin = g_hCvarRandMin.FloatValue;
	g_fCvarSpawnMax = g_hCvarSpawnMax.FloatValue;
	g_fCvarSpawnMin = g_hCvarSpawnMin.FloatValue;

	if( g_fCvarSpawnMin && g_fCvarSpawnMax )
		g_fFlowMin = GetRandomFloat(g_fCvarSpawnMin, g_fCvarSpawnMax);
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);

		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		DeleteAnomaly(g_iAnomaly);
		delete g_hTimer;

		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_bMapStarted == false )
		return false;

	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;

	// Commented out due to being used to determine Versus mode for spawning Anomaly in the same place for both teams:
	// if( iCvarModesTog != 0 )
	// {
	g_iCurrentMode = 0;

	int entity = CreateEntityByName("info_gamemode");
	if( IsValidEntity(entity) )
	{
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
			RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
	}

	if( iCvarModesTog && g_iCurrentMode == 0 )
		return false;

	if( iCvarModesTog && !(iCvarModesTog & g_iCurrentMode) )
		return false;
	// }

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					ANOMALY SPAWN
// ====================================================================================================
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	DeleteAnomaly(g_iAnomaly);
	delete g_hTimer;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action TimerStart(Handle timer)
{
	g_fFlowMax = L4D2Direct_GetMapMaxFlowDistance();

	if( g_fFlowMin && g_hTimer == null ) g_hTimer = CreateTimer(1.0, TimerSpawn, _, TIMER_REPEAT);
}

public Action TimerSpawn(Handle timer)
{
	float flow;
	int client = L4D_GetHighestFlowSurvivor();

	if( client > 0 )
	{
		flow = L4D2Direct_GetFlowDistance(client);

		if( flow )
		{
			flow = flow / g_fFlowMax * 100;
		}
	}

	if( flow > g_fFlowMin )
	{
		float vPos[3];

		// Versus same spawn pos for both teams
		if( g_iCurrentMode == 4 && g_vSpawnPos[0] != 0.0 && g_vSpawnPos[1] != 0.0 )
		{
			vPos = g_vSpawnPos;
		}
		else
		{
			// GetClientAbsOrigin(client, vPos);
			// int area = L4D_GetNearestNavArea(vPos);
			// L4D_FindRandomSpot(area, vPos);
			// Above spawns next to player.

			// Hopefully within bounds and rarely out-of-bounds.
			// g_bLeft4Dead2 ? 7 : 4 == Witch.
			// g_bLeft4Dead2 ? 8 : 5 == Tank.
			// g_bLeft4Dead2 ? 9 : 6 == Unknown.
			// 0 = Common Infected, seems good for L4D1. 5 = Jockey, seems good for L4D2.

			L4D_GetRandomPZSpawnPosition(client, g_bLeft4Dead2 ? 5 : 0, 10, vPos);

			if( g_iCurrentMode == 4 )
				g_vSpawnPos = vPos;
		}

		CreateAnomaly(vPos);

		#if DEBUG
		PrintToServer("Anomaly auto spawning at: %f %f %f", vPos[0], vPos[1], vPos[2]);
		#endif

		g_hTimer = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}



// ====================================================================================================
//					ANOMALY CREATE
// ====================================================================================================
void DeleteAnomaly(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
	{
		StopSound(entity, SNDCHAN_AUTO, SOUND_VENDOR1);
		StopSound(entity, SNDCHAN_AUTO, SOUND_VENDOR2);
		StopSound(entity, SNDCHAN_AUTO, SOUND_VENDOR3);

		// Prevent plugin conflicts for any plugins detecting "tank_rock" in "OnEntityDestroyed":
		DispatchKeyValue(entity, "classname", "weapon_pistol");

		RemoveEntity(entity);
	}
}

void CreateAnomaly(float vPos[3])
{
	// Only supports 1 anomaly at a time. No plans to change.
	DeleteAnomaly(g_iAnomaly);

	// Create
	int entity = CreateEntityByName("tank_rock"); // DO NOT USE "pipe_bomb_projectile" or bots won't shoot any common. Using "tank_rock" to prevent "molotov_projectile" showing flames, and support L4D1.
	if( entity == -1 ) return;

	g_iAnomaly = EntIndexToEntRef(entity);

	SetEntProp(entity, Prop_Data, "m_iHammerID", 92950); // Other plugins using "tank_rock" entity can use this ident to exclude affecting Anomaly plugin.
	DispatchSpawn(entity);

	// Set origin and velocity
	float vVel[3];
	vVel[0] = GetRandomFloat(-50.0, 50.0);
	vVel[1] = GetRandomFloat(-50.0, 50.0);
	vVel[2] = 0.0;
	TeleportEntity(entity, vPos, NULL_VECTOR, vVel);

	// Set gravity and elasticity
	SetEntPropFloat(entity, Prop_Data, "m_flGravity", -0.000001);
	SetEntPropFloat(entity, Prop_Data, "m_flElasticity", 1.0);

	// Invisible
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);

	// Glow debug
	#if DEBUG == 2
	if( g_bLeft4Dead2 )
	{
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 16737280); // 0 100 255
		SetEntProp(entity, Prop_Send, "m_nGlowRange", 0);
		AcceptEntityInput(entity, "StartGlowing");
	}
	#endif

	// Effects
	MakeLightDynamic(view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR, entity);
	MakeEnvSprite(view_as<float>({ 0.0, 0.0, 0.0 }), view_as<float>({ 180.0, 0.0, 90.0 }), entity);

	// Particles
	DisplayParticle(PARTICLE_ELMOS,	view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR, entity); // Pulsating
	DisplayParticle(PARTICLE_TES2,	view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR, entity); // Random electricity

	// Sounds
	EmitSoundToAll(SOUND_VENDOR1, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
	EmitSoundToAll(SOUND_VENDOR2, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
	if( GetRandomInt(0, 3) == 0 )
		EmitSoundToAll(SOUND_VENDOR3, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER); // Alarm sort of sound

	// Think function
	g_fRandNext = 0.0;
	g_fTickMove = 0.0;
	g_fTickHeight = 0.0;
	g_fTickDmgs = 0.0;

	CreateTimer(TICK_THINK, TimerThink, g_iAnomaly, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}



// ====================================================================================================
//					ANOMALY THINK
// ====================================================================================================
public Action TimerThink(Handle timer, any entity)
{
	float fTickTime = GetGameTime();


	// Validate alive
	if( EntRefToEntIndex(entity) == INVALID_ENT_REFERENCE )
	{
		return Plugin_Stop;
	}


	// Stuck check
	bool stuck;
	float vPos[3], vEnd[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vEnd);
	if( GetVectorDistance(vEnd, g_vLastPos) < 1.0 )
	{
		stuck = true;
	} else {
		g_vLastPos = vEnd;
	}


	// Random elect shots
	if( g_fCvarRandMax && g_fCvarRandMin )
	{
		if( g_fRandNext < fTickTime )
		{
			g_fRandNext = fTickTime + GetRandomFloat(g_fCvarRandMin, g_fCvarRandMax);

			// Random angle
			float vAng[3];
			vAng[0] = GetRandomFloat(-90.0, 90.0);
			vAng[1] = GetRandomFloat(-180.0, 180.0);

			vPos = vEnd;

			// Trace to nearest wall, if any
			if( SetTeleportEndPoint(EntRefToEntIndex(entity), vPos, vAng) )
			{
				float dist = GetVectorDistance(vPos, vEnd);
				if( dist > g_fCvarRandDist ) dist = g_fCvarRandDist;
				else dist -= 10.0; // Slightly away from surfaces

				NormalizeVector(vAng, vAng);
				vPos[0] = vEnd[0] + (vAng[0] * dist);
				vPos[1] = vEnd[1] + (vAng[1] * dist);
				vPos[2] = vEnd[2] + (vAng[2] * dist);

				TeslaShock(entity, 0, vPos);

				PlaySound(entity, g_sSoundsZap[GetRandomInt(0, sizeof(g_sSoundsZap) - 1)]);
			}
		}
	}


	// Change velocity direction
	if( g_fTickMove < fTickTime )
	{
		g_fTickMove = fTickTime + TICK_MOVE;

		// 1 in 4 chance to change direction
		if( stuck || GetRandomInt(0, 3) == 0 )
		{
			vPos[0] = GetRandomFloat(-50.0, 50.0);
			vPos[1] = GetRandomFloat(-50.0, 50.0);
			vPos[2] = 0.0;
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vPos);
		}
	}
	else
	{
		// Keep average height above ground
		if( g_fTickHeight < fTickTime )
		{
			g_fTickHeight = fTickTime + TICK_HEIGHT;
			vPos = vEnd;

			if( SetTeleportEndPoint(EntRefToEntIndex(entity), vPos, view_as<float>({ 89.0, 0.0, 0.0 })) ) // Trace down
			{
				float height = vEnd[2] - vPos[2];

				if( height > 65 )
				{
					GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vPos);
					vPos[2] = -5.0;
					TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vPos);
				}
				else if( height < 40 )
				{
					GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vPos);
					vPos[2] = 5.0;
					TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vPos);
				}
				else
				{
					GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vPos);
					vPos[2] = 0.0;
					TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vPos);
				}
			}
		}
	}


	// Damage check
	if( g_fTickDmgs < fTickTime )
	{
		g_fTickDmgs = fTickTime + g_fCvarDamageTime;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsPlayerAlive(i) )
			{
				GetClientAbsOrigin(i, vPos);
				if( GetVectorDistance(vPos, vEnd) < g_fCvarDamageDist )
				{
					DoDamage(entity, i, vPos);
				}
			}
		}

		int infected = -1;
		if( g_iCvarDamageInfe )
		{
			while( (infected = FindEntityByClassname(infected, "infected")) != INVALID_ENT_REFERENCE )
			{
				GetEntPropVector(infected, Prop_Data, "m_vecOrigin", vPos);
				if( GetVectorDistance(vPos, vEnd) < g_fCvarDamageDist )
				{
					DoDamage(entity, infected, vPos, 4);
				}
			}
		}

		infected = -1;
		if( g_iCvarDamageWitch )
		{
			while( (infected = FindEntityByClassname(infected, "witch")) != INVALID_ENT_REFERENCE )
			{
				GetEntPropVector(infected, Prop_Data, "m_vecOrigin", vPos);
				if( GetVectorDistance(vPos, vEnd) < g_fCvarDamageDist )
				{
					DoDamage(entity, infected, vPos, 5);
				}
			}
		}
	}

	return Plugin_Continue;
}



// ====================================================================================================
//					TESLA SHOCK
// ====================================================================================================
int g_iLastLight;

void DoDamage(int entity, int client, float vPos[3], int type = 0)
{
	// Type
	if( client <= MaxClients )
	{
		int team = GetClientTeam(client);

		if( g_iCvarDamageSurv && team == 2 )
			type = 2;
		else if( g_iCvarDamageSpec && team == 3 && GetEntProp(client, Prop_Send, "m_isGhost") == 0 )
			type = 3;
	}

	if( type == 0 ) return;


	// Visible
	float vEnd[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vEnd);

	if( IsVisibleTo(EntRefToEntIndex(entity), vEnd, vPos) == false ) return;


	// Damage
	switch( type )
	{
		case 2:		SDKHooks_TakeDamage(client, entity, entity, float(g_iCvarDamageSurv), DMG_PLASMA, -1, NULL_VECTOR, vEnd); // Survivor
		case 3:		SDKHooks_TakeDamage(client, entity, entity, float(g_iCvarDamageSpec), DMG_PLASMA, -1, NULL_VECTOR, vEnd); // Special Infected
		case 4:		SDKHooks_TakeDamage(client, entity, entity, float(g_iCvarDamageInfe), g_bLeft4Dead2 ? DMG_AIRBOAT : DMG_BUCKSHOT, -1, NULL_VECTOR, vEnd);	// Common L4D2 / L4D1
		case 5:		SDKHooks_TakeDamage(client, entity, entity, float(g_iCvarDamageWitch), DMG_BLAST, -1, NULL_VECTOR, vEnd);	// Witch
	}


	// Teleport
	if( type == 2 || type == 3 )
	{
		MakeVectorFromPoints(vEnd, vPos, vEnd);
		NormalizeVector(vEnd, vEnd);
		ScaleVector(vEnd, 400.0);

		vEnd[2] = 300.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vEnd);
	}


	// Effects
	TeslaShock(entity, client);


	// Light color
	if( !g_iLastLight && g_iLighting && EntRefToEntIndex(g_iLighting) != INVALID_ENT_REFERENCE )
	{
		g_iLastLight = 250;
		DispatchKeyValue(g_iLighting, "_light", "250 50 150 255");
		CreateTimer(0.1, TimerColor, _, TIMER_REPEAT);
	}
}

public Action TimerColor(Handle timer)
{
	if( !g_iLighting || EntRefToEntIndex(g_iLighting) == INVALID_ENT_REFERENCE ) return Plugin_Stop;

	g_iLastLight -= 10;
	if( g_iLastLight <= 0 )
	{
		g_iLastLight = 0;
		return Plugin_Stop;
	}

	static char temp[16];
	Format(temp, sizeof(temp), "%d 50 150 255", g_iLastLight);
	DispatchKeyValue(g_iLighting, "_light", temp);
	return Plugin_Continue;
}

void TeslaShock(int grenade, int target, float vEnd[3] = NULL_VECTOR)
{
	static char sTemp[32];
	float vPos[3];
	int entity;
	int iType = GetRandomInt(0, 1);



	// PARTICLE TARGET
	entity = CreateEntityByName(g_bLeft4Dead2 ? "info_particle_target" : "info_particle_system");

	if( iType == 0 )
		DispatchKeyValue(entity, "effect_name", PARTICLE_TES1);
	else if( iType == 1 )
		DispatchKeyValue(entity, "effect_name", PARTICLE_TES3);

	Format(sTemp, sizeof(sTemp), "tesla%d%d%d", entity, grenade, target);
	DispatchKeyValue(entity, "targetname", sTemp);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", grenade);
	vPos[2] = 1.0;
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start");

	InputKill(entity, 1.5);



	// PARTICLE
	entity = CreateEntityByName("info_particle_system");
	DispatchKeyValue(entity, "cpoint1", sTemp);
	if( iType == 0 )
		DispatchKeyValue(entity, "effect_name", PARTICLE_TES1);
	else if( iType == 1 )
		DispatchKeyValue(entity, "effect_name", PARTICLE_TES3);

	AcceptEntityInput(entity, "Start");

	if( target )
	{
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);
		vPos[2] = GetRandomFloat(20.0, 50.0);
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	} else {
		TeleportEntity(entity, vEnd, NULL_VECTOR, NULL_VECTOR);
	}

	DispatchSpawn(entity);
	ActivateEntity(entity);

	InputKill(entity, 1.5);



	// SOUND
	PlaySound(entity, g_sSoundsZap[GetRandomInt(0, sizeof(g_sSoundsZap) - 1)]);
}

void PlaySound(int entity, const char[] sound, int level = SNDLEVEL_NORMAL)
{
	EmitSoundToAll(sound, entity, level == SNDLEVEL_RAIDSIREN ? SNDCHAN_ITEM : SNDCHAN_AUTO, level);
}

void InputKill(int entity, float time)
{
	static char temp[40];
	Format(temp, sizeof(temp), "OnUser4 !self:Kill::%f:-1", time);
	SetVariantString(temp);
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser4");
}



// ====================================================================================================
//					PARTICLES
// ====================================================================================================
int DisplayParticle(const char[] sParticle, const float vPos[3], const float vAng[3], int client = 0)
{
	int entity = CreateEntityByName("info_particle_system");

	if( entity != -1 )
	{
		DispatchKeyValue(entity, "effect_name", sParticle);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");

		if( client )
		{
			// Attach to survivor
			SetVariantString("!activator"); 
			AcceptEntityInput(entity, "SetParent", client);
		}

		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		// Refire
		float refire = 0.2;
		static char sTemp[64];
		Format(sTemp, sizeof(sTemp), "OnUser1 !self:Stop::%f:-1", refire - 0.05);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnUser1 !self:FireUser2::%f:-1", refire);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");

		SetVariantString("OnUser2 !self:Start::0:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser2 !self:FireUser1::0:-1");
		AcceptEntityInput(entity, "AddOutput");

		return entity;
	}

	return 0;
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}



// ====================================================================================================
//					MAKE LIGHT AND SPRITE
// ====================================================================================================
int MakeLightDynamic(const float vOrigin[3], const float vAngles[3], int client)
{
	int entity = CreateEntityByName("light_dynamic");
	if( entity == -1)
	{
		LogError("Failed to create 'light_dynamic'");
		return 0;
	}

	DispatchKeyValue(entity, "_light", "0 50 150 255");
	DispatchKeyValue(entity, "brightness", "1");
	DispatchKeyValueFloat(entity, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(entity, "distance", 300.0);
	DispatchKeyValue(entity, "style", "6");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");

	// Attach
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);

	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);

	g_iLighting = EntIndexToEntRef(entity);
	return entity;
}

int MakeEnvSprite(const float vOrigin[3], const float vAngles[3], int client)
{
	int entity = CreateEntityByName("env_sprite");
	if( entity == -1)
	{
		LogError("Failed to create 'env_sprite'");
		return 0;
	}

	DispatchKeyValue(entity, "rendercolor", "0 50 150");
	DispatchKeyValue(entity, "model", MODEL_SPRITE);
	DispatchKeyValue(entity, "spawnflags", "3");
	DispatchKeyValue(entity, "rendermode", "9");
	DispatchKeyValue(entity, "GlowProxySize", "256.0");
	DispatchKeyValue(entity, "renderamt", "120");
	DispatchKeyValue(entity, "scale", "512.0");
	DispatchSpawn(entity);

	// Attach
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);

	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
	return entity;
}



// ====================================================================================================
//					STOCKS - TRACERAY
// ====================================================================================================
stock bool IsVisibleTo(int entity, float vPos[3], float vEnd[3])
{
	float vAngles[3];
	vPos[2] += 50.0;

	MakeVectorFromPoints(vPos, vEnd, vAngles); // compute vector from start to target
	GetVectorAngles(vAngles, vAngles); // get angles from vector for trace

	// execute Trace
	Handle trace = TR_TraceRayFilterEx(vPos, vAngles, MASK_ALL, RayType_Infinite, TraceFilter, entity);
	bool isVisible;

	if( TR_DidHit(trace) )
	{
		float vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint

		if( GetVectorDistance(vPos, vStart) + 25.0 >= GetVectorDistance(vPos, vEnd) )
			isVisible = true; // if trace ray length plus tolerance equal or bigger absolute distance, you hit the target
	}
	else
		isVisible = false;

	vPos[2] -= 50.0;
	delete trace;
	return isVisible;
}

bool SetTeleportEndPoint(int entity, float vPos[3], float vAng[3])
{
	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, entity);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);

		// For returning the ground angle, we don't need in this plugin.
		// float vNorm[3];
		// TR_GetPlaneNormal(trace, vNorm);
		// GetVectorAngles(vNorm, vAng);

		delete trace;
		return true;
	}

	delete trace;
	return false;
}

bool TraceFilter(int entity, int contentsMask, any ignore)
{
	if( !entity || entity == ignore || !IsValidEntity(entity) ) // Don't hit WORLD, SELF, or INVALID entities
		return false;

	// Don't hit triggers
	static char classname[10];
	GetEdictClassname(entity, classname, sizeof(classname));
	if( strncmp(classname, "trigger_", 8) == 0 )
		return false;

	return true;
}