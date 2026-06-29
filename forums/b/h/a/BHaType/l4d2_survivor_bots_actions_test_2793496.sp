#include <sourcemod>
#include <sdktools>
#include <actions>

#define APPROACH_ENTITY_DISTANCE_MIN 50.0
#define APPROACH_VECTOR_DISTANCE_MIN 150.0

Handle g_hApproachVector, g_hApproachEntity;
Handle g_hSurvivorLegsRegroup;

typedef functor = function bool(int cl); 

int g_commandInititor;

public OnPluginStart()
{
	if (!PrepSDKCalls())
	{
		SetFailState("Failed to PrepSDKCalls: g_hApproachVector = 0x%X, g_hApproachEntity = 0x%X, g_hSurvivorLegsRegroup = 0x%X", g_hApproachVector, g_hApproachEntity, g_hSurvivorLegsRegroup)
	}

	RegAdminCmd("sm_approach_crosshair", sm_approach_crosshair, ADMFLAG_ROOT);
	RegAdminCmd("sm_approach_me", sm_approach_me, ADMFLAG_ROOT);
	RegAdminCmd("sm_regroup_to_target", sm_regroup_to_target, ADMFLAG_ROOT);
}

public Action sm_approach_crosshair(int client, int args)
{
	g_commandInititor = client;
	ForEveryAliveSurvivorBot(ApproachCrosshair);
	return Plugin_Handled;
}

public Action sm_approach_me(int client, int args)
{
	g_commandInititor = client;
	ForEveryAliveSurvivorBot(ApproachMe);
	return Plugin_Handled;
}

public Action sm_regroup_to_target(int client, int args)
{
	g_commandInititor = client;
	ForEveryAliveSurvivorBot(RegroupToCrosshairTarget);
	return Plugin_Handled;
}

bool RegroupToCrosshairTarget(int cl)
{
	BehaviorAction action = ActionsManager.GetAction(cl, "SurvivorBehavior");

	if (action == INVALID_ACTION)
		return true;

	int target = GetClientAimTarget(g_commandInititor, false);

	if (cl == target)
		return true;

	if (!IsValidEntity(target) || !target)
		return false;

	BehaviorAction regroup = CreateSurvivorLegsRegroup(target);
	action.StorePendingEventResult(SUSPEND_FOR, regroup, RESULT_TRY, "It's time to regroup");
	return true;
}

bool ApproachMe(int cl)
{
	BehaviorAction action = ActionsManager.GetAction(cl, "SurvivorBehavior");

	if (action == INVALID_ACTION)
		return true;

	BehaviorAction approach = CreateSurvivorLegsApproachEntity(g_commandInititor);
	action.StorePendingEventResult(SUSPEND_FOR, approach, RESULT_TRY, "Approach me!");

	approach.OnUpdate = OnApproachEntityUpdate;
	return true;
}

bool ApproachCrosshair(int cl)
{
	BehaviorAction action = ActionsManager.GetAction(cl, "SurvivorBehavior");

	if (action == INVALID_ACTION)
		return true;

	float angles[3], origin[3];
	
	GetClientEyePosition(g_commandInititor, origin);
	GetClientEyeAngles(g_commandInititor, angles);

	TR_TraceRayFilter(origin, angles, MASK_SHOT, RayType_Infinite, TraceFilter, g_commandInititor);
	
	if (TR_DidHit())
	{
		float end[3];
		TR_GetEndPosition(end);

		BehaviorAction approach = CreateSurvivorLegsApproachVector(end);
		action.StorePendingEventResult(SUSPEND_FOR, approach, RESULT_TRY, "Go where by crosshair points");

		approach.OnUpdate = OnApproachVectorUpdate;
		return true;
	}

	return false;
}

public Action OnApproachEntityUpdate(BehaviorAction action, int actor, float interval, ActionResult result)
{
	float origin[3], goal[3];
	int subject = GetApproacherSubject(action);

	GetClientAbsOrigin(actor, origin);
	GetClientAbsOrigin(subject, goal);

	if (GetVectorDistance(origin, goal) <= APPROACH_ENTITY_DISTANCE_MIN)
		return action.Done("Approached given entity");

	return action.Continue();
}

public Action OnApproachVectorUpdate(BehaviorAction action, int actor, float interval, ActionResult result)
{
	float origin[3], goal[3];

	GetClientAbsOrigin(actor, origin);

	for(int i; i < 3; i++)
		goal[i] = action.Get(0x38 + 4 * i);

	if (GetVectorDistance(origin, goal) <= APPROACH_VECTOR_DISTANCE_MIN)
		return action.Done("Approached given goal");

	return action.Continue();
}

int GetApproacherSubject(BehaviorAction action)
{
	if (action.Get(0x34) == -1)
		return 0;
	
	return action.Get(0x34) & 0xFFF;
}

public bool TraceFilter(int entity, int mask, int data)
{
	return entity != data;
}

stock BehaviorAction CreateSurvivorLegsApproachVector(const float vec[3])
{
	BehaviorAction action = ActionsManager.Allocate(0x9050);
	SDKCall(g_hApproachVector, action, vec);
	return action;
}

stock BehaviorAction CreateSurvivorLegsApproachEntity(int entity)
{
	BehaviorAction action = ActionsManager.Allocate(0x9050);
	SDKCall(g_hApproachEntity, action, entity);
	return action;
}

stock BehaviorAction CreateSurvivorLegsRegroup(int entity)
{
	BehaviorAction action = ActionsManager.Allocate(0x484C);
	SDKCall(g_hSurvivorLegsRegroup, action, entity);
	return action;
}

void ForEveryAliveSurvivorBot(functor f)
{
	bool r;

	for(int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i) || !IsFakeClient(i))
			continue;

		Call_StartFunction(null, f);
		Call_PushCell(i);
		Call_Finish(r);

		if (!r)
			return;
	}
}

bool PrepSDKCalls()
{
	GameData data = new GameData("l4d2_t");

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "SurvivorLegsApproachVector");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	g_hApproachVector = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "SurvivorLegsApproachEntity");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hApproachEntity = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "SurvivorLegsRegroup");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSurvivorLegsRegroup = EndPrepSDKCall();

	delete data;

	return g_hApproachVector && 
			g_hApproachEntity && 
			g_hSurvivorLegsRegroup;
}