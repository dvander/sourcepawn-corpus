#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <actions>
#include <left4dhooks_stocks>

#define HITGROUP_LEFTLEG     6
#define HITGROUP_RIGHTLEG    7

enum INextBot {}
enum IBody {}
enum ILocomotion {}

enum PostureType
{
	STAND,
	CROUCH,
	SIT,
	CRAWL,
	LIE
};

enum ActivityType 
{ 
	MOTION_CONTROLLED_XY	= 0x0001,	// XY position and orientation of the bot is driven by the animation.
	MOTION_CONTROLLED_Z		= 0x0002,	// Z position of the bot is driven by the animation.
	ACTIVITY_UNINTERRUPTIBLE= 0x0004,	// activity can't be changed until animation finishes
	ACTIVITY_TRANSITORY		= 0x0008,	// a short animation that takes over from the underlying animation momentarily, resuming it upon completion
	ENTINDEX_PLAYBACK_RATE	= 0x0010,	// played back at different rates based on entindex
};

methodmap CTakeDamageInfo
{
    public CTakeDamageInfo(Address info)
    {
        return view_as<CTakeDamageInfo>(info);
    }

	property int m_hInflictor
	{
		public get() 
        {
            return EntityFromHandle(this, 48); 
        }
	}

	property int m_hAttacker
	{
		public get() 
        {
            return EntityFromHandle(this, 52); 
        }
	}

	property int m_hWeapon
	{
		public get() 
        {
            return EntityFromHandle(this, 56); 
        }
	}
}

Handle g_hMyNextBotPointer, g_hGetBodyInterface, g_hGetLocomotionInterface, 
		g_hStartActivity, g_hSetDesiredPosture, g_hIsActivity, 
		g_hGetGroundSpeed, g_hLookupActivity;

ConVar sm_common_stumble_chance, sm_common_stumble_speed_min,
		sm_common_stumble_weapons;

ArrayList g_hWeaponIDs;

public void OnPluginStart()
{
	g_hWeaponIDs = new ArrayList();

	sm_common_stumble_chance = CreateConVar("sm_common_stumble_chance", "100.0");
	sm_common_stumble_speed_min = CreateConVar("sm_common_stumble_speed_min", "200.0");
	sm_common_stumble_weapons = CreateConVar("sm_common_stumble_weapons", "6;10");

	sm_common_stumble_weapons.AddChangeHook(OnConVarChanged);

	AutoExecConfig(true, "l4d_common_stumble");
	GetCvars();
	SetupSDKCalls();
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	char buffer[128], ids[L4D2WeaponId_MAX][8];
	int num;

	sm_common_stumble_weapons.GetString(buffer, sizeof buffer);
	num = ExplodeString(buffer, ";", ids, sizeof ids, sizeof ids[]);

	g_hWeaponIDs.Clear();
	for(int i; i < num; i++)
	{
		int id = StringToInt(ids[i]);
		g_hWeaponIDs.Push(id);
	}
}

public void OnActionCreated(BehaviorAction action, int actor, const char[] name)
{
	if (strcmp(name, "ChaseVictim") == 0)
	{
		action.OnStart = ChaseVictim_OnStart;
		action.OnEnd = ChaseVictim_OnEnd;
		action.OnInjured = ChaseVictim_OnInjured;
	}	
}

public Action ChaseVictim_OnStart(BehaviorAction action, int actor, BehaviorAction priorAction, ActionDesiredResult result)
{
	SDKHook(actor, SDKHook_TraceAttackPost, TraceAttackPost);
	return Plugin_Continue;
}

public void ChaseVictim_OnEnd(BehaviorAction action, int actor, BehaviorAction nextAction, ActionResult result)
{
	SDKUnhook(actor, SDKHook_TraceAttackPost, TraceAttackPost);
}

public void TraceAttackPost(int victim, int attacker, int inflictor, float damage, int damagetype, int ammotype, int hitbox, int hitgroup)
{
	BehaviorAction action = ActionsManager.GetAction(victim, "ChaseVictim");

	if (action)
	{
		action.SetUserData("m_chaseVictimHitGroup", hitgroup);
	}
}

public Action ChaseVictim_OnInjured(BehaviorAction action, int actor, CTakeDamageInfo info, ActionDesiredResult result)
{
	int hitgroup = action.GetUserData("m_chaseVictimHitGroup");
	if (hitgroup != HITGROUP_LEFTLEG && hitgroup != HITGROUP_RIGHTLEG)
		return Plugin_Continue;

	int attacker = info.m_hAttacker;
	int weapon = info.m_hWeapon;

	if (weapon == -1 || attacker == -1 || attacker > MaxClients || GetClientTeam(attacker) != 2)
		return Plugin_Continue;

	char name[32];
	if (!GetEntityClassname(weapon, name, sizeof name))
		return Plugin_Continue;

	L4D2WeaponId id = L4D2_GetWeaponIdByWeaponName(name);

	if (id == L4D2WeaponId_None || g_hWeaponIDs.FindValue(id) == -1)
		return Plugin_Continue;

	INextBot bot = MyNextBotPointer(actor);
	IBody body = GetBodyInterface(bot);
	ILocomotion locomotion = GetLocomotionInterface(bot);
	
	if (GetGroundSpeed(locomotion) <= sm_common_stumble_speed_min.FloatValue)
		return Plugin_Continue;

	int activity = LookupActivity(actor, "ACT_TERROR_RUN_STUMBLE");
	if (activity == -1 || IsActivity(body, activity))
		return Plugin_Continue;

	float chance = sm_common_stumble_chance.FloatValue;
	if ( GetRandomFloat(1.0, 100.0) > chance )
		return Plugin_Continue;

	return action.TrySuspendFor(CreateStumbleAction(), RESULT_TRY, "Injured while running");
}

BehaviorAction CreateStumbleAction()
{
    BehaviorAction stumble = ActionsManager.Create("InfectedStumble");

    stumble.OnStart = InfectedStumble_OnStart;
    stumble.OnEnd = InfectedStumble_OnEnd;
    stumble.OnAnimationActivityComplete = InfectedStumble_OnAnimationActivityComplete;
    stumble.OnAnimationActivityInterrupted = InfectedStumble_OnAnimationActivityInterrupted;

    return stumble;
}

public Action InfectedStumble_OnStart(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{	
	int activity = LookupActivity(actor, "ACT_TERROR_RUN_STUMBLE");

	if (activity == -1)
		return action.Done("No specified activity");

	INextBot bot = MyNextBotPointer(actor);
	IBody body = GetBodyInterface(bot);

	SetDesiredPosture(body, LIE);
	StartActivity(body, activity, MOTION_CONTROLLED_XY);
	SetEntPropFloat(actor, Prop_Send, "m_flCycle", 0.13);

	return Plugin_Continue;
}

public void InfectedStumble_OnEnd(BehaviorAction action, int actor, BehaviorAction nextAction, ActionResult result)
{
	IBody body = GetBodyInterface(MyNextBotPointer(actor));
	SetDesiredPosture(body, STAND);
}

public Action InfectedStumble_OnAnimationActivityComplete(BehaviorAction action, int actor, int activity, ActionDesiredResult result)
{
	return action.Done("We backed up");
}

public Action InfectedStumble_OnAnimationActivityInterrupted(BehaviorAction action, int actor, int activity, ActionDesiredResult result)
{
	return action.Done("Something interrupted us");
}

// ====================================================================================================
// STOCKS
// ====================================================================================================

stock INextBot MyNextBotPointer(int entity)
{
	return SDKCall(g_hMyNextBotPointer, entity);
} 

stock IBody GetBodyInterface(INextBot nextbot)
{
	return SDKCall(g_hGetBodyInterface, nextbot);
} 

stock ILocomotion GetLocomotionInterface(INextBot nextbot)
{
	return SDKCall(g_hGetLocomotionInterface, nextbot);
} 

stock bool StartActivity(IBody body, int activity, ActivityType flags = MOTION_CONTROLLED_XY)
{
	return SDKCall(g_hStartActivity, body, activity, flags);
} 

stock bool SetDesiredPosture(IBody body, PostureType posture)
{
	return SDKCall(g_hSetDesiredPosture, body, posture);
} 

stock bool IsActivity(IBody body, int activity)
{
	return SDKCall(g_hIsActivity, body, activity);
} 

stock int LookupActivity(int entity, const char[] activity)
{
	return SDKCall(g_hLookupActivity, entity, activity);
} 

stock float GetGroundSpeed(ILocomotion locomotion)
{
	return SDKCall(g_hGetGroundSpeed, locomotion);
} 

stock any Dereference(any data, any offset, NumberType type = NumberType_Int32)
{
	return LoadFromAddress(data + offset, type);
}

stock any EntityFromHandle(any data, any offset)
{
	any handle = LoadFromAddress(data + offset, NumberType_Int32);
	
	if (handle == -1)
		return -1;

	return handle & 0xFFF;
}

// ====================================================================================================
// SDK SETUP
// ====================================================================================================

void SetupSDKCalls()
{
	GameData data = new GameData("l4d2_infected_stumble");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "CBaseEntity::MyNextBotPointer");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hMyNextBotPointer = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "INextBot::GetBodyInterface");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hGetBodyInterface = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "INextBot::GetLocomotionInterface");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hGetLocomotionInterface = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "IBody::StartActivity");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hStartActivity = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "IBody::SetDesiredPosture");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSetDesiredPosture = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "IBody::IsActivity");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hIsActivity = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "ILocomotion::GetGroundSpeed");
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
	g_hGetGroundSpeed = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "CBaseAnimating::LookupActivity");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hLookupActivity = EndPrepSDKCall();

	delete data;

	if (g_hLookupActivity == null)
		SetFailState("CBaseAnimating::LookupActivity signature broken");
}