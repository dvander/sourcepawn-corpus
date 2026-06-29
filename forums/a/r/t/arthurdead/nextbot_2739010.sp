#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <datamaps>
#include <nextbot>
#include <dhooks>
#include <animhelpers>

ConVar pause_path = null;

public void OnPluginStart()
{
	Handle factory = register_entity_factory_ex("hl2_zombie", datamaps_allocatenextbot);

	CustomDatamap datamap = CustomDatamap.from_factory(factory);
	datamap.add_prop("m_pNextBot", custom_prop_int);
	datamap.add_prop("m_pLocomotion", custom_prop_int);
	datamap.add_prop("m_pVision", custom_prop_int);
	datamap.add_prop("m_pPathFollower", custom_prop_int);
	datamap.add_prop("m_flRepathTime", custom_prop_float);
	datamap.add_prop("m_nMoveYaw", custom_prop_int);
	datamap.add_prop("m_nActIdle", custom_prop_int);
	datamap.add_prop("m_nActWalk", custom_prop_int);

	RegConsoleCmd("testzm", cmd);

	pause_path = CreateConVar("pause_path", "0");
}

public void OnMapStart()
{
	PrecacheModel("models/zombie/classic.mdl");
	PrecacheModel("models/headcrabclassic.mdl");
	PrecacheModel("models/dog.mdl");
}

Action cmd(int client, int args)
{
	int ent = CreateEntityByName("hl2_zombie");
	DispatchSpawn(ent);
	float pos[3];
	GetClientAbsOrigin(client, pos);
	TeleportEntity(ent, pos);
	return Plugin_Handled;
}

stock float ClampFloat(float value, float min, float max) {
	if (value > max) {
		return max;
	} else if (value < min) {
		return min;
	}
	return value;
}

void OnZombieThink(int entity)
{
	INextBot bot = GetEntCustomProp(entity, "m_pNextBot");
	PathFollower path = GetEntCustomProp(entity, "m_pPathFollower");
	NextBotGoundLocomotionCustom locomotion = GetEntCustomProp(entity, "m_pLocomotion");

	if(!pause_path.BoolValue) {
		if(GetEntCustomPropFloat(entity, "m_flRepathTime") <= GetGameTime()) {
			path.ComputeEntity(bot, 1, baseline_path_cost);
			SetEntCustomPropFloat(entity, "m_flRepathTime", GetGameTime() + 0.5);
		}
	}

	float m_flGroundSpeed = GetEntPropFloat(entity, Prop_Data, "m_flGroundSpeed");

	float speed = locomotion.GroundSpeed;

	if(m_flGroundSpeed > 0.0) {
		float playbackRate = ClampFloat( speed / m_flGroundSpeed, -4.0, 12.0 );
		SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", playbackRate);
	} else {
		SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 1.0);
	}

	BaseAnimating anim = BaseAnimating(entity);

	float vel[3];
	locomotion.GetVelocity(vel);

	float eye[3];
	GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", eye);

	float xaxis[3];
	float zaxis[3];
	GetAngleVectors(eye, xaxis, zaxis, NULL_VECTOR);

	float x = GetVectorDotProduct(xaxis, vel);
	float z = GetVectorDotProduct(zaxis, vel);

	float yaw = (ArcTangent2(-z, x) * 180.0 / FLOAT_PI);

	int move_yaw = GetEntCustomProp(entity, "m_nMoveYaw");
	anim.SetPoseParameter(move_yaw, yaw);

	int seq = GetEntCustomProp(entity, "m_nActIdle");
	if(speed > 2.0) {
		seq = GetEntCustomProp(entity, "m_nActWalk")
	}

	anim.ResetSequence(seq);

	anim.StudioFrameAdvance();

	if(m_flGroundSpeed < 1.0) {
		m_flGroundSpeed = 999.0;
	} else {
		//m_flGroundSpeed *= 5.0;
	}

	locomotion.RunSpeed = m_flGroundSpeed;
	locomotion.WalkSpeed = m_flGroundSpeed;

	path.Update(bot);
}

void OnZombieSpawn(int entity)
{
	INextBot bot = INextBot(entity);
	IBodyCustom body = bot.AllocateCustomBody();
	NextBotGoundLocomotionCustom locomotion = bot.AllocateCustomLocomotion();

	#define COLLISION_GROUP_PLAYER 5

	float HullWidth = 26.0;
	float HullHeight = 26.0;

	float hullMins[3];
	hullMins[0] = -HullWidth;
	hullMins[1] = hullMins[0];
	hullMins[2] = 0.0;

	float hullMaxs[3];
	hullMaxs[0] = HullWidth;
	hullMaxs[1] = hullMaxs[0];
	hullMaxs[2] = HullHeight;

	//body.SetHullMins(hullMins);
	//body.SetHullMaxs(hullMaxs);
	//body.HullWidth = HullWidth;
	//body.HullHeight = HullHeight;

	//SetEntPropVector(entity, Prop_Send, "m_vecMins", hullMins);
	//SetEntPropVector(entity, Prop_Send, "m_vecMaxs", hullMaxs);

	//body.SolidMask = MASK_PLAYERSOLID;
	//body.CollisionGroup = COLLISION_GROUP_PLAYER;

	SetEntityModel(entity, "models/headcrabclassic.mdl");
	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 1.5);

	locomotion.MaxJumpHeight = 18.0;
	//locomotion.DeathDropHeight = 1.0;
	locomotion.StepHeight = 18.0;
	locomotion.MaxYawRate = 200.0;

	PathFollower path = new PathFollower();
	//path.GoalTolerance = 100.0;
	//path.MinLookAheadDistance = 100.0;

	BaseAnimating anim = BaseAnimating(entity);

	SetEntCustomProp(entity, "m_nMoveYaw", anim.LookupPoseParameter("move_yaw"));
	SetEntCustomProp(entity, "m_nActIdle", anim.LookupSequence("Idle01"));
	SetEntCustomProp(entity, "m_nActWalk", anim.LookupSequence("Run1"));
	SetEntCustomProp(entity, "m_pPathFollower", path);
	SetEntCustomProp(entity, "m_pLocomotion", locomotion);
	SetEntCustomProp(entity, "m_pNextBot", bot);
	SetEntCustomProp(entity, "m_pVision", bot.VisionInterface);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "hl2_zombie")) {
		SDKHook(entity, SDKHook_Think, OnZombieThink);
		SDKHook(entity, SDKHook_SpawnPost, OnZombieSpawn);
	}
}

public void OnEntityDestroyed(int entity)
{
	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	if(StrEqual(classname, "hl2_zombie")) {
		PathFollower path = GetEntCustomProp(entity, "m_pPathFollower");
		if(path != null) {
			delete path;
		}
	}
}

public void OnPluginEnd()
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "hl2_zombie")) != -1) {
		PathFollower path = GetEntCustomProp(entity, "m_pPathFollower");
		if(path != null) {
			delete path;
		}
		SetEntCustomProp(entity, "m_pPathFollower", 0);
	}
}