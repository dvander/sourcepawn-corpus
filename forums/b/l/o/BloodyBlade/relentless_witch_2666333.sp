#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2.0"

#define ANIM_WITCH_PRE_RETREAT		5
#define ANIM_WITCH_RUN_INTENSE		6
#define ANIM_WITCH_RUN_ONFIRE_INT	7
#define ANIM_WITCH_RUN_RETREAT		8
#define ANIM_WITCH_WANDER_WALK		11
#define ANIM_WITCH_WANDER_ACQUIRE	30
#define ANIM_WITCH_KILLING_BLOW		31
#define ANIM_WITCH_RUN_ONFIRE		39

/*Handles*/
static ConVar relentlesswitchoncvar;
static ConVar relentlesswitchincap;
static ConVar relentlesswitchrange;

static int bRelentlessWitchOn;
static int bRelentlessWitchIncap;
static int iRelentlessWitchRange;

static Handle SDKOnHitByVomitJar 	= INVALID_HANDLE;

static const char CONFIG_CHECKPOINTS[]	= "data/relentlesswitch_checkpoints.cfg";
static bool bCPStartHasExtraData;
static bool bCPEndHasExtraData;
static float CPStartLocA[3];
static float CPStartLocB[3];
static float CPStartLocC[3];
static float CPStartLocD[3];
static float CPEndLocA[3];
static float CPEndLocB[3];
static float CPEndLocC[3];
static float CPEndLocD[3];
static float CPStartRotate;
static float CPEndRotate;
static int iCheckpoint;

public Plugin myinfo =
{
	name = "[L4D2] Relentless Witch",
	author = "Machine",
	description = "Startled Witches will relentlessly attack survivors until all are dead.",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
};

public void OnPluginStart()
{
	CreateConVar("relentless_witch_version", PLUGIN_VERSION, "[L4D2] Relentless Witch Version", FCVAR_NONE|FCVAR_DONTRECORD|FCVAR_NOTIFY);

	relentlesswitchoncvar = CreateConVar("relentless_witch_on", "1", "Is Relentless Witch enabled?", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	relentlesswitchincap = CreateConVar("relentless_witch_incap", "0", "Allow witch to kill Incapacitated survivor before moving on?", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	relentlesswitchrange = CreateConVar("relentless_witch_range", "1200", "This controls the range for witch to reacquire another target.", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 9999.0);

	//Hook Events
	HookEvent("round_start", Round_Start);
	HookEvent("player_incapacitated", Player_Incapacitated);
	HookEvent("player_death", Player_Death);

	bRelentlessWitchOn 	= GetConVarBool(relentlesswitchoncvar);
	bRelentlessWitchIncap 	= GetConVarBool(relentlesswitchincap);
	iRelentlessWitchRange  	= GetConVarInt(relentlesswitchrange);

	HookConVarChange(relentlesswitchoncvar, CvarsChanged);
	HookConVarChange(relentlesswitchincap, CvarsChanged);
	HookConVarChange(relentlesswitchrange, CvarsChanged);

	InitSDKCalls();

	CreateTimer(0.1, TimerUpdate, _, TIMER_REPEAT);

	//AutoExecConfig(true,"Relentless_Witch");
}
//=============================
// SDKCalls
//=============================
void InitSDKCalls()
{
	Handle ConfigFile = LoadGameConfigFile("relentless_witch");
	Handle MySDKCall = INVALID_HANDLE;

	///////////////////
	//OnHitByVomitJar//
	///////////////////
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "Infected_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	MySDKCall = EndPrepSDKCall();
	if (MySDKCall == INVALID_HANDLE)
	{
		SetFailState("Cant initialize Infected_OnHitByVomitJar SDKCall");
	}
	SDKOnHitByVomitJar = CloneHandle(MySDKCall, SDKOnHitByVomitJar);

	CloseHandle(ConfigFile);
	CloseHandle(MySDKCall);
}

stock void SDKCallOnHitByVomitJar(int target, int client)
{
	SDKCall(SDKOnHitByVomitJar, target, client);
}

public void CvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bRelentlessWitchOn 	= GetConVarBool(relentlesswitchoncvar);
	bRelentlessWitchIncap 	= GetConVarBool(relentlesswitchincap);
	iRelentlessWitchRange  	= GetConVarInt(relentlesswitchrange);
}

public Action Player_Incapacitated(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int entity = GetEventInt(event,"attackerentid");
	if (IsWitch(entity) && IsSurvivor(victim))
	{
		if (!bRelentlessWitchIncap)
		{
			int target = GetNearestSurvivorDist(entity);
			if (target > 0)
			{
				int onfire = GetEntProp(entity, Prop_Send, "m_bIsBurning");
				if (onfire > 0)
				{
					entity = ReplaceWitch(entity);
				}
				SetEntProp(entity, Prop_Send, "m_nSequence", ANIM_WITCH_RUN_INTENSE);
				WitchAttackFunc(entity, target);
			}
		}
	}
}

public Action Player_Death(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int entity = GetEventInt(event,"attackerentid");
	if (IsWitch(entity) && IsSurvivor(victim))
	{
		int target = GetNearestSurvivorDist(entity);
		if (target <= 0)
		{
			target = GetNearestIncapSurvivorDist(entity);
		}
		if (target > 0)
		{
			SetEntProp(entity, Prop_Send, "m_nSequence", ANIM_WITCH_RUN_INTENSE);
			WitchAttackFunc(entity, target);
		}
	}
}

public Action Round_Start(Event event, const char[] event_name, bool dontBroadcast)
{
	ResetVariables();
}

stock void ResetVariables()
{
	iCheckpoint = 0;
	for (int i = 0; i <= 2; i++)
	{
		CPStartLocA[i] = 0.0;
		CPStartLocB[i] = 0.0;
		CPStartLocC[i] = 0.0;
		CPStartLocD[i] = 0.0;
		CPEndLocA[i] = 0.0;
		CPEndLocB[i] = 0.0;
		CPEndLocC[i] = 0.0;
		CPEndLocD[i] = 0.0;
	}
	CPStartRotate = 0.0;
	CPEndRotate = 0.0;
	bCPStartHasExtraData = false;
	bCPEndHasExtraData = false;
}

public Action TimerUpdate(Handle timer)
{
	if (!IsServerProcessing())
	{
		return Plugin_Continue;
	}

	LoadCheckpoints();

	return Plugin_Continue;
}

stock void WitchAttackFunc(int entity, int target)
{
	if (IsWitch(entity))
	{
		//PrintToChatAll("attacking target %N", target);
		SDKCallOnHitByVomitJar(entity, target);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
	}
}

stock void DealDamageWitch(int entity, int attacker, int dmgtype, int dmg, char[] inflictor)
{
	if (IsWitch(entity))
	{
   	 	char damage[16];
   	 	IntToString(dmg, damage, 16);
   	 	char type[16];
   	 	IntToString(dmgtype, type, 16);
   	 	int pointHurt = CreateEntityByName("point_hurt");
		if (pointHurt)
		{
			DispatchKeyValue(entity, "targetname", "hurtme");
			DispatchKeyValue(pointHurt, "Damage", damage);
			DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
			DispatchKeyValue(pointHurt, "DamageType", type);
			DispatchKeyValue(pointHurt, "classname", inflictor);
			DispatchSpawn(pointHurt);
			if (attacker > 0 && IsValidEntity(attacker))
			{
				AcceptEntityInput(pointHurt, "Hurt", attacker);
			}
			AcceptEntityInput(pointHurt, "Kill");
			DispatchKeyValue(entity, "targetname", "donthurtme");
		}
	}
}

public void WitchAttackHook(int entity)
{
	if (bRelentlessWitchOn)
	{
		if (IsWitch(entity))
		{
			int target = GetNearestSurvivorDist(entity);
			int targetincap = GetNearestIncapSurvivorDist(entity);
			int clone = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			float rage = GetEntPropFloat(entity, Prop_Send, "m_rage");
			float wanderrage = GetEntPropFloat(entity, Prop_Send, "m_wanderrage");
			int sequence = GetEntProp(entity, Prop_Send, "m_nSequence");
			if (target == 0 && targetincap == 0)
			{
				if (IsWitchBurning(entity))
				{
					SetEntProp(entity, Prop_Send, "m_nSequence", ANIM_WITCH_RUN_ONFIRE_INT);
				}
			}
			else if (sequence == ANIM_WITCH_RUN_ONFIRE || sequence == ANIM_WITCH_RUN_RETREAT)
			{
				if (target <= 0)
				{
					target = targetincap;
				}
				if (target > 0)
				{
					ReplaceWitch(entity);
				}
			}
			else if (clone > 0 && (rage < 0.4 || wanderrage < 0.4))
			{
				if (target <= 0)
				{
					target = targetincap;
				}
				if (target > 0)
				{
					SetEntPropFloat(entity, Prop_Send, "m_wanderrage", 1.0);
					SetEntPropFloat(entity, Prop_Send, "m_rage", 1.0);
					SetEntProp(entity, Prop_Send, "m_nSequence", ANIM_WITCH_RUN_INTENSE);
					WitchAttackFunc(entity, target);
				}
			}
		}
	}
}

stock int ReplaceWitch(int entity)
{
	int witch = 0;
	if (IsWitch(entity))
	{
		float Origin[3], Angles[3];
		int health, maxhealth;
		float rage, wanderrage;
		int onfire;
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", Angles);
		maxhealth = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		health = GetEntProp(entity, Prop_Data, "m_iHealth");
		rage = GetEntPropFloat(entity, Prop_Send, "m_rage");
		wanderrage = GetEntPropFloat(entity, Prop_Send, "m_wanderrage");
		int owner = entity;
		onfire = GetEntProp(entity, Prop_Send, "m_bIsBurning");
		AcceptEntityInput(entity, "Kill");
		witch = CreateEntityByName("witch");
		DispatchSpawn(witch);
		ActivateEntity(witch);
		SetEntProp(witch, Prop_Data, "m_iMaxHealth", maxhealth);
		SetEntProp(witch, Prop_Data, "m_iHealth", health);
		SetEntPropFloat(witch, Prop_Send, "m_rage", rage);
		SetEntPropFloat(witch, Prop_Send, "m_wanderrage", wanderrage);
		SetEntProp(witch, Prop_Send, "m_hOwnerEntity", owner);
		if (onfire > 0)
		{
			DealDamageWitch(witch, witch, 8, 1, "point_hurt");
		}
		TeleportEntity(witch, Origin, Angles, NULL_VECTOR);
	}
	return witch;
}

stock int GetNearestSurvivorDist(int entity)
{
	int target = 0;
	if (IsWitch(entity))
	{
		int range = iRelentlessWitchRange;
		float Origin[3], TOrigin[3], distance = 0.0, savedDistance = 0.0;
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
   		for (int i = 1; i <= MaxClients; i++)
    	{
        	if (IsSurvivor(i) && IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerInSaferoom(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", TOrigin);
				distance = GetVectorDistance(Origin, TOrigin);
				if (range >= distance)
				{
                    if (savedDistance == 0.0 || savedDistance > distance)
					{
						savedDistance = distance;
						target = i;
					}
				}
			}
		}
    }
	return target;
}

stock int GetNearestIncapSurvivorDist(int entity)
{
	int target = 0;
	if (IsWitch(entity))
	{
		int range = iRelentlessWitchRange;
		float Origin[3], TOrigin[3], distance = 0.0, savedDistance = 0.0;
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
   		for (int i = 1; i <= MaxClients; i++)
    	{
        	if (IsSurvivor(i) && IsPlayerAlive(i) && IsPlayerIncap(i) && !IsPlayerInSaferoom(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", TOrigin);
				distance = GetVectorDistance(Origin, TOrigin);
				if (range >= distance)
				{
                    if (savedDistance == 0.0 || savedDistance > distance)
					{
						savedDistance = distance;
						target = i;
					}
				}
			}
		}
    }
	return target;
}

stock bool IsSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

stock bool IsPlayerIncap(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

stock bool IsWitch(int entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "witch", false))
			return true;
	}
	return false;
}

stock bool IsWitchBurning(int entity)
{
	if (IsWitch(entity))
	{
		int isBurning = GetEntProp(entity, Prop_Send, "m_bIsBurning");
		if (isBurning > 0)
			return true;
	}
	return false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "witch", false))
	{
		SDKHook(entity, SDKHook_ThinkPost, WitchAttackHook);
	}
}

//Using Tabbernauts saferoom detection since its the best way for accurate detection
stock void LoadCheckpoints()
{
	if (iCheckpoint == 0)
	{
		char sPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_CHECKPOINTS);
		if (!FileExists(sPath))
		{
			PrintToServer("Error: Cannot read the config %s", sPath);
			iCheckpoint = 1;
			return;
		}
		// Load config
		Handle hFile = CreateKeyValues("bounds");
		if (!FileToKeyValues(hFile, sPath))
		{
			PrintToServer("Error: Cannot read the config %s", sPath);
			CloseHandle(hFile);
			iCheckpoint = 1;
			return;
		}
		// Check for current map in the config
		char sMap[64];
		GetCurrentMap(sMap, 64);
		if (!KvJumpToKey(hFile, sMap))
		{
			PrintToServer("Error: Failed to add map to config");
			CloseHandle(hFile);
			iCheckpoint = 1;
			return;
		}
		// Get the information
		KvGetVector(hFile, "start_loc_a", CPStartLocA);
		KvGetVector(hFile, "start_loc_b", CPStartLocB);
		KvGetVector(hFile, "start_loc_c", CPStartLocC);
		KvGetVector(hFile, "start_loc_d", CPStartLocD);
		KvGetVector(hFile, "end_loc_a", CPEndLocA);
		KvGetVector(hFile, "end_loc_b", CPEndLocB);
		KvGetVector(hFile, "end_loc_c", CPEndLocC);
		KvGetVector(hFile, "end_loc_d", CPEndLocD);
		CPStartRotate = KvGetFloat(hFile, "start_rotate", CPStartRotate);
		CPEndRotate = KvGetFloat(hFile, "end_rotate", CPEndRotate);
		if (CPStartLocA[0] == 0.0 && CPStartLocA[1] == 0.0 && CPStartLocA[2] == 0.0)
		{
			PrintToServer("Error: Positions at 0.0");
		}
		else
		{
			if (CPStartLocC[0] != 0.0 && CPStartLocC[1] != 0.0 && CPStartLocC[2] != 0.0 && CPStartLocD[0] != 0.0 && CPStartLocD[1] != 0.0 && CPStartLocD[2] != 0.0) 
			{ 
				bCPStartHasExtraData = true; 
			}
			if (CPEndLocC[0] != 0.0 && CPEndLocC[1] != 0.0 && CPEndLocC[2] != 0.0 && CPEndLocD[0] != 0.0 && CPEndLocD[1] != 0.0 && CPEndLocD[2] != 0.0) 
			{ 
				bCPEndHasExtraData = true; 
			}
			if (CPStartRotate != 0.0) 
			{
            	RotatePoint(CPStartLocA, CPStartLocB[0], CPStartLocB[1], CPStartRotate);
            	if (bCPStartHasExtraData) 
				{
                	RotatePoint(CPStartLocA, CPStartLocC[0], CPStartLocC[1], CPStartRotate);
                	RotatePoint(CPStartLocA, CPStartLocD[0], CPStartLocD[1], CPStartRotate);
            	}
       	 	}
			if (CPEndRotate != 0.0) 
			{
            	RotatePoint(CPEndLocA, CPEndLocB[0], CPEndLocB[1], CPEndRotate);
            	if (bCPEndHasExtraData) 
				{
                	RotatePoint(CPEndLocA, CPEndLocC[0], CPEndLocC[1], CPEndRotate);
                	RotatePoint(CPEndLocA, CPEndLocD[0], CPEndLocD[1], CPEndRotate);
            	}
       	 	}
			PrintToServer("Checkpoint Coordinates loaded!");
		}
		CloseHandle(hFile);
		iCheckpoint = 1;
	}
}

stock int RotatePoint(float origin[3], float &pointX, float &pointY, float angle)
{
    float newPoint[2];
    angle = angle / 57.2957795130823;
    
    newPoint[0] = (Cosine(angle) * (pointX - origin[0])) - (Sine(angle) * (pointY - origin[1]))   + origin[0];
    newPoint[1] = (Sine(angle) * (pointX - origin[0]))   + (Cosine(angle) * (pointY - origin[1])) + origin[1];
    
    pointX = newPoint[0];
    pointY = newPoint[1];
    
    return;
}

stock bool IsPlayerInSaferoom(int client)
{
    float Origin[3];
    if (client > 0 && IsClientInGame(client))
	{
    	GetClientAbsOrigin(client, Origin);
	}
    return IsPointInSaferoom(Origin);
}

stock bool IsPointInSaferoom(float Origin[3])
{
    float xMin, xMax;
    float yMin, yMax;
    float zMin, zMax;

    if (CPStartRotate != 0.0){RotatePoint(CPStartLocA, Origin[0], Origin[1], CPStartRotate);}
    if (CPStartLocA[0] < CPStartLocB[0]){xMin = CPStartLocA[0];xMax = CPStartLocB[0];}else{xMin = CPStartLocB[0];xMax = CPStartLocA[0];}
    if (CPStartLocA[1] < CPStartLocB[1]){yMin = CPStartLocA[1];yMax = CPStartLocB[1];}else{yMin = CPStartLocB[1];yMax = CPStartLocA[1];}
    if (CPStartLocA[2] < CPStartLocB[2]){zMin = CPStartLocA[2];zMax = CPStartLocB[2];}else{zMin = CPStartLocB[2];zMax = CPStartLocA[2];}
        
    if (Origin[0] >= xMin && Origin[0] <= xMax &&  Origin[1] >= yMin && Origin[1] <= yMax && Origin[2] >= zMin && Origin[2] <= zMax)
	{
		return true;
	}
    if (bCPStartHasExtraData)
    {
        if (CPStartLocC[0] < CPStartLocD[0]){xMin = CPStartLocC[0];xMax = CPStartLocD[0];}else{xMin = CPStartLocD[0];xMax = CPStartLocC[0];}
        if (CPStartLocC[1] < CPStartLocD[1]){yMin = CPStartLocC[1];yMax = CPStartLocD[1];}else{yMin = CPStartLocD[1];yMax = CPStartLocC[1];}
        if (CPStartLocC[2] < CPStartLocD[2]){zMin = CPStartLocC[2];zMax = CPStartLocD[2];}else{zMin = CPStartLocD[2];zMax = CPStartLocC[2];}
        if (Origin[0] >= xMin && Origin[0] <= xMax &&  Origin[1] >= yMin && Origin[1] <= yMax && Origin[2] >= zMin && Origin[2] <= zMax)
		{
			return true;
		}
    }
	
    if (CPEndRotate != 0.0){RotatePoint(CPEndLocA, Origin[0], Origin[1], CPEndRotate);}
    if (CPEndLocA[0] < CPEndLocB[0]){xMin = CPEndLocA[0];xMax = CPEndLocB[0];}else{xMin = CPEndLocB[0];xMax = CPEndLocA[0];}
    if (CPEndLocA[1] < CPEndLocB[1]){yMin = CPEndLocA[1];yMax = CPEndLocB[1];}else{yMin = CPEndLocB[1];yMax = CPEndLocA[1];}
    if (CPEndLocA[2] < CPEndLocB[2]){zMin = CPEndLocA[2];zMax = CPEndLocB[2];}else{zMin = CPEndLocB[2];zMax = CPEndLocA[2];}
    if (Origin[0] >= xMin && Origin[0] <= xMax &&  Origin[1] >= yMin && Origin[1] <= yMax && Origin[2] >= zMin && Origin[2] <= zMax)
	{
		return true;
	}
    if (bCPEndHasExtraData)
    {
        if (CPEndLocC[0] < CPEndLocD[0]){xMin = CPEndLocC[0];xMax = CPEndLocD[0];}else{xMin = CPEndLocD[0];xMax = CPEndLocC[0];}
        if (CPEndLocC[1] < CPEndLocD[1]){yMin = CPEndLocC[1];yMax = CPEndLocD[1];}else{yMin = CPEndLocD[1];yMax = CPEndLocC[1];}
        if (CPEndLocC[2] < CPEndLocD[2]){zMin = CPEndLocC[2];zMax = CPEndLocD[2];}else{zMin = CPEndLocD[2];zMax = CPEndLocC[2];}
        if (Origin[0] >= xMin && Origin[0] <= xMax &&  Origin[1] >= yMin && Origin[1] <= yMax && Origin[2] >= zMin && Origin[2] <= zMax)
		{
			return true;
		}
    }

    return false;
}