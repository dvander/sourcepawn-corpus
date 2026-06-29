#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define DEBUG 0

#define PLUGIN_VERSION                  "1.0.5"

#define	SHAKE_START                     0     // Starts the screen shake for all players within the radius.
#define	SHAKE_STOP                      1     // Stops the screen shake for all players within the radius.
#define	SHAKE_AMPLITUDE                 2     // Modifies the amplitude of an active screen shake for all players within the radius.
#define	SHAKE_FREQUENCY                 3     // Modifies the frequency of an active screen shake for all players within the radius.
#define	SHAKE_START_RUMBLEONLY          4     // Starts a shake effect that only rumbles the controller, no screen effect.
#define	SHAKE_START_NORUMBLE            5     // Starts a shake that does NOT rumble the controller.

#define SOUND_QUAKE   g_bLeft4Dead2 ? "player/charger/hit/charger_smash_02.wav" : "player/t/hit/hulk_punch_1"
#define SOUND_ROAR    "player/tank/voice/yell/tank_yell_12.wav"

bool   g_bLateLoad,
       g_bLeft4Dead2,
       g_bPluginEnable,
       g_brecentlyHurtSurvivors[MAXPLAYERS + 1],
       g_bisTankActive[MAXPLAYERS + 1],
       g_binRockThrow[MAXPLAYERS + 1];

int    g_iTankLocationInterval,
       g_istuckTicks[MAXPLAYERS + 1];

Handle g_hFlingPlayerSig,
       g_hRecentlyHurtSurvivors_Timer[MAXPLAYERS + 1],
       g_hInRockThrow_Timer[MAXPLAYERS + 1];

ConVar g_cvPluginEnable,
       g_cvCheckTankLocationInterval,
       g_cvSlapDistanceInitial,
       g_cvSlapDistanceIntervalIncrease,
       g_cvSlapMaxDistance,
       g_cvSlapPower,
       g_cvSlapVerticalMultiplier;

float  g_fDistanceInitial,
       g_fDistanceIntervalIncrease,
       g_fMaxDistance,
       g_fSlapPower,
       g_fVerticalMultiplier,
       g_fLastOrigin[MAXPLAYERS + 1][3],
       g_fSlapDistance[MAXPLAYERS + 1];

bool   g_bHookedEvents = false,
       g_bisFlingPlayerSigLoaded = false;

public Plugin myinfo = 
{
	name           = "[L4D/2] Tank Stuck Fix",
	author         = "Buster \"Mr. Zero\" Nielsen",
	description    = "Flings Survivors away from Tank upon getting stuck",
	version        = PLUGIN_VERSION,
	url            = "https://forums.alliedmods.net/showthread.php?t=349021"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead) g_bLeft4Dead2 = false;
	else if (test == Engine_Left4Dead2) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("tankstuck_fix_version", PLUGIN_VERSION, "[L4D/2] Tank Stuck Fix plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_cvPluginEnable = CreateConVar("tankstuck_fix_enable", "1", "Enables or disables the Tank Stuck Fix plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvCheckTankLocationInterval = CreateConVar("tankstuck_check_interval", "5", "Sets the interval (in seconds) to check if the Tank is stuck.", FCVAR_NOTIFY, true, 1.0, true, 10.0);
	g_cvSlapDistanceInitial = CreateConVar("tankstuck_slap_distance_initial", "150.0", "Initial distance used to push Survivors away from the Tank if stuck.", FCVAR_NOTIFY, true, 0.0, true, 1000.0);
	g_cvSlapDistanceIntervalIncrease = CreateConVar("tankstuck_slap_distance_increase", "10.0", "Amount by which the slap distance increases with each check interval while the Tank remains stuck.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_cvSlapMaxDistance = CreateConVar("tankstuck_slap_max_distance", "300.0", "Maximum distance Survivors are pushed away when the Tank is stuck.", FCVAR_NOTIFY, true, 0.0, true, 1000.0);
	g_cvSlapPower = CreateConVar("tankstuck_slap_power", "200.0", "Force applied to Survivors when they are pushed away from a stuck Tank.", FCVAR_NOTIFY, true, 0.0, true, 1000.0);
	g_cvSlapVerticalMultiplier = CreateConVar("tankstuck_slap_vertical_multiplier", "1.2", "Multiplier for the upward force applied to Survivors when pushed by the Tank.", FCVAR_NOTIFY, true, 0.0, true, 10.0);

	AutoExecConfig(true, "tankstuck_fix");

	g_cvPluginEnable.AddChangeHook(ConVarChanged_Cvars);
	g_cvCheckTankLocationInterval.AddChangeHook(ConVarChanged_Cvars);
	g_cvSlapDistanceInitial.AddChangeHook(ConVarChanged_Cvars);
	g_cvSlapDistanceIntervalIncrease.AddChangeHook(ConVarChanged_Cvars);
	g_cvSlapMaxDistance.AddChangeHook(ConVarChanged_Cvars);
	g_cvSlapPower.AddChangeHook(ConVarChanged_Cvars);
	g_cvSlapVerticalMultiplier.AddChangeHook(ConVarChanged_Cvars);

	if (g_bPluginEnable && g_bLeft4Dead2)
		g_bisFlingPlayerSigLoaded = LoadFlingPlayerSignature();
		
	if (g_bLateLoad) 
	{
		for (int i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i))
				OnClientPutInServer(i);
		}
	}
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bPluginEnable = g_cvPluginEnable.BoolValue;
	g_iTankLocationInterval = g_cvCheckTankLocationInterval.IntValue;
	g_fDistanceInitial = g_cvSlapDistanceInitial.FloatValue;
	g_fDistanceIntervalIncrease = g_cvSlapDistanceIntervalIncrease.FloatValue;
	g_fMaxDistance = g_cvSlapMaxDistance.FloatValue;
	g_fSlapPower = g_cvSlapPower.FloatValue;
	g_fVerticalMultiplier = g_cvSlapVerticalMultiplier.FloatValue;
}

void IsAllowed()
{	
	GetCvars();
	if (g_bPluginEnable && !g_bHookedEvents)
	{
		HookEvent("tank_spawn", EvtOnTankSpawn);
		HookEvent("player_death", EvtOnTankDeath);
		HookEvent("ability_use", EvtOnAbilityUse);
		g_bHookedEvents = true;
	}
	else if (!g_bPluginEnable && g_bHookedEvents)
	{
		UnhookEvent("tank_spawn", EvtOnTankSpawn);
		UnhookEvent("player_death", EvtOnTankDeath);
		UnhookEvent("ability_use", EvtOnAbilityUse);
		g_bHookedEvents = false;
	}
}

public void OnMapStart()
{
	PrecacheSound(SOUND_QUAKE, true);
	PrecacheSound(SOUND_ROAR, true);
}

void EvtOnAbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsInfected(client) && IsValidTank(client))
	{
		g_hInRockThrow_Timer[client] = CreateTimer(3.0, OnAbilityUse, client);
		g_binRockThrow[client] = true;
	}
}

Action OnAbilityUse(Handle timer, any tank)
{
	g_binRockThrow[tank] = false;
	g_hInRockThrow_Timer[tank] = null;
	return Plugin_Stop;
}

Action ResetRecentlyHurtSurvivors(Handle timer, any tank)
{
	g_brecentlyHurtSurvivors[tank] = false;
	g_hRecentlyHurtSurvivors_Timer[tank] = null;
	return Plugin_Stop;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_bPluginEnable || !IsValidEntity(victim) || !IsValidEntity(attacker))
		return Plugin_Continue;
	// If the victim is a survivor and the attacker is an infected Tank
	if (IsSurvivor(victim) && IsInfected(attacker) && IsValidTank(attacker))
	{
		g_hRecentlyHurtSurvivors_Timer[attacker] = CreateTimer(8.0, ResetRecentlyHurtSurvivors, attacker);
		ActivateTank(attacker);
		g_brecentlyHurtSurvivors[attacker] = true;
		g_istuckTicks[attacker] = 0;
		g_fSlapDistance[attacker] = g_fDistanceInitial;
	}
	// If the attacker is a survivor and the victim is an inactive infected Tank
	else if (!g_bisTankActive[victim] && IsSurvivor(attacker) && IsInfected(victim) && IsValidTank(victim))
	{
		ActivateTank(victim);
	}
	return Plugin_Continue;
}

void ActivateTank(int tank)
{
	if (!IsTankIdle(tank))
	{
		g_bisTankActive[tank] = true;
		#if DEBUG
		PrintToChatAll("[DEBUG] Tank %d activated", tank);
		#endif
	}
}

void EvtOnTankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (IsInfected(tank) && IsValidTank(tank))
	{
		g_bisTankActive[tank] = false;
		g_istuckTicks[tank] = 0;
		GetClientEyePosition(tank, g_fLastOrigin[tank]);
		g_fSlapDistance[tank] = g_fDistanceInitial;
		CreateTimer(1.0, CheckTankLocation, GetClientUserId(tank), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

void EvtOnTankDeath(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (IsInfected(tank) && IsValidTank(tank))
	{
		if (g_hInRockThrow_Timer[tank] != null)
			delete g_hInRockThrow_Timer[tank];
		if (g_hRecentlyHurtSurvivors_Timer[tank] != null)
			delete g_hRecentlyHurtSurvivors_Timer[tank];
		g_bisTankActive[tank] = false;
		g_brecentlyHurtSurvivors[tank] = false;
		g_binRockThrow[tank] = false;
	}
}

Action CheckTankLocation(Handle timer, any userid)
{
	int tank = GetClientOfUserId(userid);
	if (!g_bPluginEnable || !IsInfected(tank) || !IsValidTank(tank) || IsIncapped(tank))
		return Plugin_Stop;
	#if DEBUG
	PrintToChatAll("[DEBUG] Tank %d is active: %s", tank, g_bisTankActive[tank] ? "true" : "false");
	#endif
	if (!g_bisTankActive[tank] || g_brecentlyHurtSurvivors[tank] || g_binRockThrow[tank])
		return Plugin_Continue;
	float origin[3];
	GetClientEyePosition(tank, origin);
	if (GetVectorDistance(g_fLastOrigin[tank], origin) < 100.0)
	{
		g_istuckTicks[tank]++;
		#if DEBUG
		PrintToChatAll("[DEBUG] Tank %d is stuck (stuck ticks: %d)", tank, g_istuckTicks[tank]);
		#endif
	}
	else
	{
		g_istuckTicks[tank] = 0;
		g_fSlapDistance[tank] = g_fDistanceInitial;
		#if DEBUG
		PrintToChatAll("[DEBUG] Tank %d has moved. Resetting stuck ticks and slap distance.", tank);
		#endif
	}
	g_fLastOrigin[tank][0] = origin[0];
	g_fLastOrigin[tank][1] = origin[1];
	g_fLastOrigin[tank][2] = origin[2];
	if (g_istuckTicks[tank] > g_iTankLocationInterval)
	{
		g_fSlapDistance[tank] += g_fDistanceIntervalIncrease;
		if (g_fSlapDistance[tank] > g_fMaxDistance)
			g_fSlapDistance[tank] = g_fMaxDistance;
		SlapNearbySurvivors(tank, origin);
	}
	return Plugin_Continue;
}

void SlapNearbySurvivors(int tank, float origin[3])
{
	float slapDistance = g_fSlapDistance[tank];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) 
			|| !IsPlayerAlive(i) 
				|| IsIncapped(i) 
					|| GetClientTeam(i) != 2)
			continue;
		if (GetInfectedAttacker(i) != -1)
			continue;
		// Get the Survivor's position
		float surOrigin[3];
		GetClientEyePosition(i, surOrigin);
		// Calculate the distance from the tank
		float distance = GetVectorDistance(origin, surOrigin);
		if (distance <= slapDistance)
			ApplySlapEffect(i, tank);
	}
}

void ApplySlapEffect(int client, int tank)
{
	if (g_bLeft4Dead2 && g_bisFlingPlayerSigLoaded)
		FlingPlayerAwayFromTank(client, tank);
	else
		SlapPlayer(client, 0, true);
	ShakeClient(client, SHAKE_START, 30.0, 10.0, 2.0);
	EmitSoundToClient(client, SOUND_QUAKE, tank);
	EmitSoundToClient(client, SOUND_ROAR, tank);
}

void FlingPlayerAwayFromTank(int client, int tank)
{
	float HeadingVector[3], AimVector[3], power = g_fSlapPower, currentVelocity[3], flingVelocity[3];
	GetClientEyeAngles(tank, HeadingVector);
	float radAngle = DegToRad(HeadingVector[1]);
	AimVector[0] = Cosine(radAngle) * power;
	AimVector[1] = Sine(radAngle) * power;
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", currentVelocity);
	flingVelocity[0] = currentVelocity[0] + AimVector[0];
	flingVelocity[1] = currentVelocity[1] + AimVector[1];
	flingVelocity[2] = power * g_fVerticalMultiplier;
	L4D2_FlingPlayer(client, flingVelocity, 76, tank);
}

stock bool IsSurvivor(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2;
}

stock bool IsInfected(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3;
}

stock bool IsIncapped(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool IsValidTank(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == (g_bLeft4Dead2 ? 8 : 5);
}

stock bool IsTankIdle(int client)
{
	if (!IsValidClient(client))
		return false;
	static const int validSequences[] = {1, 2, 3, 4};
	int sequence = GetEntProp(client, Prop_Send, "m_nSequence");
	for (int i = 0; i < sizeof(validSequences); i++)
	{	
		if (sequence == validSequences[i])
			return true;
	}
	return false;
}

stock bool ShakeClient(int client, int command = SHAKE_START, float amplitude = 50.0, float frequency = 150.0, float duration = 3.0)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("Shake", client));
	if (bf == null)
		return false;
	if (command == SHAKE_STOP)
		amplitude = 0.0;
	else if (amplitude <= 0.0)
		return false;
	bf.WriteByte(command);        // shake command
	bf.WriteFloat(amplitude);     // shake magnitude/amplitude
	bf.WriteFloat(frequency);     // shake noise frequency
	bf.WriteFloat(duration);      // shake lasts this long
	EndMessage();
	return true;
}

stock int GetInfectedAttacker(int client)
{
	int attacker;
	if (g_bLeft4Dead2)
	{
		/* Charger */
		attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
		if (attacker > 0)
			return attacker;
		attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
		if (attacker > 0)
			return attacker;
		/* Jockey */
		attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
		if (attacker > 0)
			return attacker;
	}
	/* Hunter */
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if (attacker > 0)
		return attacker;
	/* Smoker */
	attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (attacker > 0)
		return attacker;
	return -1;
}

stock void L4D2_FlingPlayer(int target, float vector[3], int animation, int attacker, float incaptime = 3.0)
{
	SDKCall(g_hFlingPlayerSig, target, vector, animation, attacker, incaptime); //76 is the 'got bounced' animation in L4D2
}

stock bool LoadFlingPlayerSignature()
{
	GameData gameConf = new GameData("tankstuck_fix");
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "CTerrorPlayer_Fling"))
	{
		LogError("Unable to load fling player signature");
		return false;
	}
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	g_hFlingPlayerSig = EndPrepSDKCall();
	if (g_hFlingPlayerSig == null)
	{
		LogError("Unable to prep fling player signature");
		return false;
	}
	return true;
}