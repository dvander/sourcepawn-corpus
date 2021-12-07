#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.7"

#define STRINGLENGTH_CLASSES				  64

static const Float:TRACE_TOLERANCE 			= 25.0;
static const Float:BILE_POS_HEIGHT_FIX		= 70.0;
static const ZOMBIECLASS_BOOMER				= 2;
static const L4D2Team_Survivors				= 2;
static const L4D2Team_Infected				= 3;
static const String:ENTPROP_ZOMBIE_CLASS[] 	= "m_zombieClass";
static const String:GAMEDATA_FILE[]			= "l4d2addresses";
static const String:ENTPROP_IS_GHOST[]		= "m_isGhost";
static const String:CLASS_BILEJAR[]			= "vomitjar_projectile";
static const String:CLASS_ZOMBIE[]			= "infected";
static const String:CLASS_WITCH[]			= "witch";

static const String:VELOCITY_ENTPROP[]		= "m_vecVelocity";
static const Float:SLAP_VERTICAL_MULTIPLIER	= 1.5;

static Handle:isEnabled = 				INVALID_HANDLE;
static Handle:splashRadius = 			INVALID_HANDLE;
static Handle:sdkCallVomitOnPlayer = 	INVALID_HANDLE;
static Handle:sdkCallBileJarPlayer = 	INVALID_HANDLE;
static Handle:sdkCallBileJarInfected = 	INVALID_HANDLE;
static Handle:sdkCallFling			 = 	INVALID_HANDLE;

static Handle:cvar_slapPower		 = INVALID_HANDLE;
static Handle:cvar_bFling			 = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "L4D2 Bile the World",
	author = " AtomicStryker",
	description = "Vomit Jars hit Survivors, Boomer Explosions slime Infected",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1237748"
}

public OnPluginStart()
{
	PrepSDKCalls();

	HookEvent("player_death", event_PlayerDeath);
	
	CreateConVar("l4d2_bile_the_world_version", PLUGIN_VERSION, " L4D2 Bile the World Plugin Version ", 					FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	splashRadius = 	CreateConVar("l4d2_bile_the_world_radius", 	"200", 			" Radius of Bile Splash on Boomer Death and Vomit Jar ", 	FCVAR_PLUGIN|FCVAR_REPLICATED);
	isEnabled = 	CreateConVar("l4d2_bile_the_world_enabled", "1", 			" Turn Bile the World on and off ", 						FCVAR_PLUGIN|FCVAR_REPLICATED);
	
	cvar_slapPower = CreateConVar("l4d2_bile_the_world_expl_pwr", "150.0", " How much Force is applied to the victims ", FCVAR_PLUGIN|FCVAR_REPLICATED);
	cvar_bFling  = 	CreateConVar("l4d2_bile_the_world_flingenabled", "0", " Turn Flinging by Boomer Explosion on and off ", FCVAR_PLUGIN|FCVAR_REPLICATED);
}

public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client
	|| !IsClientInGame(client)
	|| GetClientTeam(client) != L4D2Team_Infected
	|| GetEntProp(client, Prop_Send, ENTPROP_ZOMBIE_CLASS) != ZOMBIECLASS_BOOMER)
	{
		return;
	}
	
	decl Float:pos[3];
	GetClientEyePosition(client, pos);

	VomitSplash(true, pos, client);
}

public OnEntityDestroyed(entity)
{
	if (!IsValidEdict(entity)) return;

	decl String:class[STRINGLENGTH_CLASSES];
	GetEdictClassname(entity, class, sizeof(class));
	
	if (!StrEqual(class, CLASS_BILEJAR)) return;
	
	decl Float:pos[3];
	GetEntityAbsOrigin(entity, pos);
	pos[2] += BILE_POS_HEIGHT_FIX;
	
	VomitSplash(false, pos, 0);
}

static VomitSplash(bool:BoomerDeath, Float:pos[3], boomer)
{		
	if (!GetConVarBool(isEnabled)) return;
	
	decl Float:targetpos[3];
	new Float:distancesetting = GetConVarFloat(splashRadius);
	
	if (BoomerDeath) // unfortunately we're forced to loop all entities here
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)
			|| GetClientTeam(i) != L4D2Team_Infected
			|| !IsPlayerAlive(i)
			|| GetEntProp(i, Prop_Send, ENTPROP_IS_GHOST) != 0)
			{
				continue;
			}
			
			GetClientEyePosition(i, targetpos);
			if (GetVectorDistance(pos, targetpos) > distancesetting
			|| !IsVisibleTo(pos, targetpos))
			{
				continue;
			}
			
			if (GetConVarBool(cvar_bFling))
			{
				decl Float:HeadingVector[3], Float:AimVector[3];
				new Float:power = GetConVarFloat(cvar_slapPower);
				
				// compute target vector
				HeadingVector[0] = targetpos[0] - pos[0];
				HeadingVector[1] = targetpos[1] - pos[1];
				HeadingVector[2] = targetpos[2] - pos[2];
			
				AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , power);
				AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , power);
				
				decl Float:current[3];
				GetEntPropVector(i, Prop_Data, VELOCITY_ENTPROP, current);
				
				decl Float:resulting[3];
				resulting[0] = FloatAdd(current[0], AimVector[0]);	
				resulting[1] = FloatAdd(current[1], AimVector[1]);
				resulting[2] = power * SLAP_VERTICAL_MULTIPLIER;
				
				L4D2_Fling(i, resulting, boomer);
			}
			else
			{
				SDKCall(sdkCallBileJarPlayer, i, GetAnyValidSurvivor());
			}
		}
	
		decl String:class[STRINGLENGTH_CLASSES];
	
		new maxents = GetMaxEntities();
		for (new i = MaxClients+1; i <= maxents; i++)
		{
			if (!IsValidEdict(i)) continue;
			GetEdictClassname(i, class, sizeof(class));
			
			if (!StrEqual(class, CLASS_ZOMBIE)
			&& !StrEqual(class, CLASS_WITCH)) continue;
			
			GetEntityAbsOrigin(i, targetpos);
			if (GetVectorDistance(pos, targetpos) > distancesetting
			|| !IsVisibleTo(pos, targetpos))
			{
				continue;
			}
			
			SDKCall(sdkCallBileJarInfected, i, GetAnyValidSurvivor());
		}
	}
	
	else // case Vomit Jar Explosion, since it already hits Infected we only need to check Survivors
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)
			|| GetClientTeam(i) != L4D2Team_Survivors
			|| !IsPlayerAlive(i))
			{
				continue;
			}
			
			GetClientEyePosition(i, targetpos);
			if (GetVectorDistance(pos, targetpos) > distancesetting
			|| !IsVisibleTo(pos, targetpos))
			{
				continue;
			}
			
			SDKCall(sdkCallVomitOnPlayer, i, GetAnyValidSurvivor(), true);
		}
	}
}

static PrepSDKCalls()
{
	new Handle:ConfigFile = LoadGameConfigFile(GAMEDATA_FILE);
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkCallVomitOnPlayer = EndPrepSDKCall();
	
	if (sdkCallVomitOnPlayer == INVALID_HANDLE)
	{
		SetFailState("Cant initialize OnVomitedUpon SDKCall");
		return;
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	sdkCallBileJarPlayer = EndPrepSDKCall();
	
	if (sdkCallBileJarPlayer == INVALID_HANDLE)
	{
		SetFailState("Cant initialize CTerrorPlayer_OnHitByVomitJar SDKCall");
		return;
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "Infected_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	sdkCallBileJarInfected = EndPrepSDKCall();
	
	if (sdkCallBileJarInfected == INVALID_HANDLE)
	{
		SetFailState("Cant initialize Infected_OnHitByVomitJar SDKCall");
		return;
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCallFling = EndPrepSDKCall();
	
	if (sdkCallFling == INVALID_HANDLE)
	{
		SetFailState("Cant initialize Fling SDKCall");
		return;
	}
	
	CloseHandle(ConfigFile);
}

static bool:IsVisibleTo(Float:position[3], Float:targetposition[3])
{
	decl Float:vAngles[3], Float:vLookAt[3];
	
	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	// execute Trace
	new Handle:trace = TR_TraceRayFilterEx(position, vAngles, MASK_SHOT, RayType_Infinite, _TraceFilter);
	
	new bool:isVisible = false;
	if (TR_DidHit(trace))
	{
		decl Float:vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		
		if ((GetVectorDistance(position, vStart, false) + TRACE_TOLERANCE) >= GetVectorDistance(position, targetposition))
		{
			isVisible = true; // if trace ray lenght plus tolerance equal or bigger absolute distance, you hit the target
		}
	}
	else
	{
		LogError("Tracer Bug: Player-Zombie Trace did not hit anything, WTF");
		isVisible = true;
	}
	CloseHandle(trace);
	
	return isVisible;
}

public bool:_TraceFilter(entity, contentsMask)
{
	if (!entity || !IsValidEntity(entity)) // dont let WORLD, or invalid entities be hit
	{
		return false;
	}
	
	return true;
}

//entity abs origin code from here
//http://forums.alliedmods.net/showpost.php?s=e5dce96f11b8e938274902a8ad8e75e9&p=885168&postcount=3
stock GetEntityAbsOrigin(entity, Float:origin[3])
{
	if (entity && IsValidEntity(entity)
	&& (GetEntSendPropOffs(entity, "m_vecOrigin") != -1)
	&& (GetEntSendPropOffs(entity, "m_vecMins") != -1)
	&& (GetEntSendPropOffs(entity, "m_vecMaxs") != -1))
	{
		decl Float:mins[3], Float:maxs[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
		GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);
		
		origin[0] += (mins[0] + maxs[0]) * 0.5;
		origin[1] += (mins[1] + maxs[1]) * 0.5;
		origin[2] += (mins[2] + maxs[2]) * 0.5;
	}
}

stock GetAnyValidSurvivor()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)
		&& GetClientTeam(i) == L4D2Team_Survivors)
		{
			return i;
		}
	}
	return 1;
}

// CTerrorPlayer::Fling(Vector  const&, PlayerAnimEvent_t, CBaseCombatCharacter *, float)
stock L4D2_Fling(target, Float:vector[3], attacker, Float:incaptime = 3.0)
{	
	SDKCall(sdkCallFling, target, vector, 76, attacker, incaptime); //76 is the 'got bounced' animation in L4D2
}