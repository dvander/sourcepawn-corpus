#include <sourcemod>
#include <smmem>
#include <dhooks>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <sourcescramble>

#define PLUGIN_VERSION 	"1.0.0"

public Plugin myinfo ={
	name = "[TF2] Building Overhaul",
	author = "Scag",
	description = "Gotta move that gear up!",
	version = PLUGIN_VERSION,
	url = "https://github.com/Scags"
};

ConVar
	cvMax[3]
;

// Need to handle bad objects...
const TFObjectType TFObject_Invalid = view_as< TFObjectType >(-1);
const TFObjectMode TFObjectMode_Invalid = view_as< TFObjectMode >(-1);

enum //gamerules_roundstate_t
{
	// initialize the game, create teams
	GR_STATE_INIT = 0,

	//Before players have joined the game. Periodically checks to see if enough players are ready
	//to start a game. Also reverts to this when there are no active players
	GR_STATE_PREGAME,

	//The game is about to start, wait a bit and spawn everyone
	GR_STATE_STARTGAME,

	//All players are respawned, frozen in place
	GR_STATE_PREROUND,

	//Round is on, playing normally
	GR_STATE_RND_RUNNING,

	//Someone has won the round
	GR_STATE_TEAM_WIN,

	//Noone has won, manually restart the game, reset scores
	GR_STATE_RESTART,

	//Noone has won, restart the game
	GR_STATE_STALEMATE,

	//Game is over, showing the scoreboard etc
	GR_STATE_GAME_OVER,

	//Game is in a bonus state, transitioned to after a round ends
	GR_STATE_BONUS,

	//Game is awaiting the next wave/round of a multi round experience
	GR_STATE_BETWEEN_RNDS,

	GR_NUM_ROUND_STATES
};

enum //ETFGameType
{
	TF_GAMETYPE_UNDEFINED = 0,
	TF_GAMETYPE_CTF,
	TF_GAMETYPE_CP,
	TF_GAMETYPE_ESCORT,
	TF_GAMETYPE_ARENA,
	TF_GAMETYPE_MVM,
	TF_GAMETYPE_RD,
	TF_GAMETYPE_PASSTIME,
	TF_GAMETYPE_PD,

	//
	// ADD NEW ITEMS HERE TO AVOID BREAKING DEMOS
	//
	TF_GAMETYPE_COUNT
};

enum struct ObjectInfo
{
	int ref;			// Ref
	int buildnumber;	// What number this is in our list of this object
	float buildtime;	// How old this object is
	TFObjectType originaltype;	// Actual object type, in-game type will be overridden

	Address GetBaseAddr()
	{
		if (!IsValidEntity(this.ref))
			return Address_Null;
		return GetEntityAddress(this.ref);
	}
	TFObjectType GetType()
	{
		if (!IsValidEntity(this.ref))
			return TFObject_Invalid;
		return TF2_GetObjectType(this.ref);
	}
	TFObjectMode GetMode()
	{
		if (!IsValidEntity(this.ref))
			return TFObjectMode_Invalid;
		return TF2_GetObjectMode(this.ref);
	}
}

ArrayList
// Since m_aObjects is capped at 6 (supposedly), we can't abuse it with a multitude of shitty objects
// So we need to have a list of actual objects and swap them out when necessary
	g_ActualObjects[MAXPLAYERS+1]
;

Handle
	hCTFLaserPointer_CanAttack,
	hCTFWeaponBase_SendWeaponAnim,
	hCSniperDot_Update,
	hCalcAbsolutePosition,
	hCCollisionProperty_SetSolid,
	hCTFGameStats_Event_PlayerCreatedBuilding
;

DynamicHook
	hCTFLaserPointer_PrimaryAttack,
	hCTFLaserPointer_SecondaryAttack
;

MemoryPatch
	g_PlayerThinkPatch
;

Address
	g_GameStats
;

public void OnPluginStart()
{
	GameData conf = new GameData("tf2.buildingoverhaul");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "CTFLaserPointer::CanAttack");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if (!(hCTFLaserPointer_CanAttack = EndPrepSDKCall()))
		SetFailState("Could not load CTFLaserPointer::CanAttack from gamedata.");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "CTFWeaponBase::SendWeaponAnim");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	if (!(hCTFWeaponBase_SendWeaponAnim = EndPrepSDKCall()))
		SetFailState("Could not load CTFWeaponBase::SendWeaponAnim from gamedata.");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CSniperDot::Update");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	if (!(hCSniperDot_Update = EndPrepSDKCall()))
		SetFailState("Could not load CSniperDot::Update from gamedata.");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CBaseEntity::CalcAbsolutePosition");
	if (!(hCalcAbsolutePosition = EndPrepSDKCall()))
		SetFailState("Could not load CBaseEntity::CalcAbsolutePosition from gamedata.");

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CCollisionProperty::SetSolid");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	if (!(hCCollisionProperty_SetSolid = EndPrepSDKCall()))
		SetFailState("Could not load CCollisionProperty::SetSolid from gamedata.");

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CTFGameStats::Event_PlayerCreatedBuilding");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	if (!(hCTFGameStats_Event_PlayerCreatedBuilding = EndPrepSDKCall()))
		SetFailState("Could not load CTFGameStats::Event_PlayerCreatedBuilding from gamedata.");

	hCTFLaserPointer_PrimaryAttack = new DynamicHook(conf.GetOffset("CTFLaserPointer::PrimaryAttack"), HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	hCTFLaserPointer_SecondaryAttack = new DynamicHook(conf.GetOffset("CTFLaserPointer::SecondaryAttack"), HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	
	DynamicDetour.FromConf(conf, "CTFLaserPointer::DestroyLaserDot").Enable(Hook_Pre, CTFLaserPointer_DestroyLaserDot);
	DynamicDetour.FromConf(conf, "CTFLaserPointer::UpdateLaserDot").Enable(Hook_Pre, CTFLaserPointer_UpdateLaserDot);
	DynamicDetour.FromConf(conf, "CTFPlayer::TFPlayerThink").Enable(Hook_Post, CTFPlayer_TFPlayerThink);
	DynamicDetour.FromConf(conf, "CTFPlayer::RemoveAllObjects").Enable(Hook_Post, CTFPlayer_RemoveAllObjects);
	DynamicDetour.FromConf(conf, "CObjectTeleporter::FindMatch").Enable(Hook_Pre, CObjectTeleporter_FindMatch);
	DynamicDetour.FromConf(conf, "CTFPlayer::FinishedObject").Enable(Hook_Pre, CTFPlayer_FinishedObject);
	DynamicDetour.FromConf(conf, "CTFPlayer::RemoveObject").Enable(Hook_Post, CTFPlayer_RemoveObject);
	DynamicDetour.FromConf(conf, "CTFPlayer::BuildObservableEntityList").Enable(Hook_Post, CTFPlayer_BuildObservableEntityList);
	DynamicDetour.FromConf(conf, "CTFPlayer::TryToPickupBuilding").Enable(Hook_Pre, CTFPlayer_TryToPickupBuilding);
	DynamicDetour.FromConf(conf, "CTFPlayer::TryToPickupBuilding").Enable(Hook_Post, CTFPlayer_TryToPickupBuilding_Post);
	DynamicDetour.FromConf(conf, "CTFPlayer::GetObjectCount").Enable(Hook_Pre, CTFPlayer_GetObjectCount);
	DynamicDetour.FromConf(conf, "CTFPlayer::GetObject").Enable(Hook_Pre, CTFPlayer_GetObject);

	g_PlayerThinkPatch = MemoryPatch.CreateFromConf(conf, "CTFPlayer::TFPlayerThink_Patch");
	g_PlayerThinkPatch.Enable();

	g_GameStats = conf.GetAddress("CTFGameStats");

	delete conf;

	cvMax[0] = CreateConVar("sm_buildingov_max_dispenser", "999", "Max amount of dispensers", FCVAR_NOTIFY, true, 1.0);
	cvMax[1] = CreateConVar("sm_buildingov_max_teleporter", "999", "Max amount of teleporters. Counts for each set i.e. setting to 3 means 3 sets of teleporters.", FCVAR_NOTIFY, true, 1.0);
	cvMax[2] = CreateConVar("sm_buildingov_max_sentry", "999", "Max amount of sentries", FCVAR_NOTIFY, true, 1.0);

	AutoExecConfig(true, "TF2BuildingOverhaul");

	HookEvent("player_death", OnPlayerDied);

	for (int i = MaxClients; i; --i)
		if (IsClientInGame(i))
			OnClientPutInServer(i);
}

public void OnPluginEnd()
{
	g_PlayerThinkPatch.Disable();
}

public void OnClientPutInServer(int client)
{
	delete g_ActualObjects[client];
	g_ActualObjects[client] = new ArrayList(sizeof(ObjectInfo));
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public void OnClientDisconnect_Post(int client)
{
	delete g_ActualObjects[client];
}

public Action OnWeaponSwitch(int client, int weapon)
{
	if (!IsClientInGame(client))
		return Plugin_Continue;

	if (!IsValidEntity(weapon))
		return Plugin_Continue;

	// If a player pulls out a pda, flush m_aObjects
	if (GetPlayerWeaponSlot(client, 3) == weapon && IsPDA(weapon))
	{
		AllowBuilding(client);
		return Plugin_Continue;
	}
	// And re-add the oldest objects to them afterwards
	else if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") != 28)
	{
		AllowDestroying(client);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public void OnEntityCreated(int ent, const char[] classname)
{
	if (!strcmp(classname, "tf_weapon_laser_pointer", false))
	{
		hCTFLaserPointer_PrimaryAttack.HookEntity(Hook_Pre, ent, CTFLaserPointer_PrimaryAttack);
		hCTFLaserPointer_SecondaryAttack.HookEntity(Hook_Pre, ent, CTFLaserPointer_SecondaryAttack);
	}
}

// So essentially we need to recreate a lot of functions so that the game understands we can have multiple objects at a time
// This is the fun way :D
#define ACT_ITEM1_VM_RELOAD 1635

public MRESReturn CTFLaserPointer_PrimaryAttack(int pThis)
{
	int owner = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	if (owner == -1)
		return MRES_Supercede;

	if (!CTFLaserPointer_CanAttack(pThis))
		return MRES_Supercede;

	int numobjs = GetNumObjects(owner);
	if (numobjs > 0)
	{
		int[] objs = new int[numobjs]
		int num = GetObjectsOfType(owner, TFObject_Sentry, objs);
		int offs = FindSendPropInfo("CObjectSentrygun", "m_hEnemy");
		for (int i = 0; i < num; ++i)
			SetEntData(objs[i], offs + 4, 1, 1, true);
	}

	if (GetIdealActivity(pThis) != ACT_ITEM1_VM_RELOAD)
		SetEntDataFloat(pThis, FindSendPropInfo("CTFLaserPointer", "m_nInspectStage") + 16, GetGameTime());

	CTFWeaponBase_SendWeaponAnim(pThis, ACT_ITEM1_VM_RELOAD);
	return MRES_Supercede;
}

public MRESReturn CTFLaserPointer_SecondaryAttack(int pThis)
{
	int owner = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	if (owner == -1)
		return MRES_Supercede;

	if (!CTFLaserPointer_CanAttack(pThis))
		return MRES_Supercede;

	int numobjs = GetNumObjects(owner);
	if (numobjs > 0)
	{
		int[] objs = new int[numobjs]
		int num = GetObjectsOfType(owner, TFObject_Sentry, objs);
		int offs = FindSendPropInfo("CObjectSentrygun", "m_hEnemy");
		for (int i = 0; i < num; ++i)
			if (GetEntProp(objs[i], Prop_Send, "m_iUpgradeLevel") == 3)
				SetEntData(objs[i], offs + 5, 1, 1, true);
	}
	return MRES_Supercede;
}

public MRESReturn CTFLaserPointer_DestroyLaserDot(int pThis)
{
	int owner = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	if (owner != -1)
	{
		int numobjs = GetNumObjects(owner);
		if (numobjs > 0)
		{
			int[] objs = new int[numobjs]
			int num = GetObjectsOfType(owner, TFObject_Sentry, objs);
			for (int i = 0; i < num; ++i)
				SetEntProp(objs[i], Prop_Send, "m_hEnemy", 0);
		}
	}

	int dot = GetEntDataEnt2(pThis, FindSendPropInfo("CTFLaserPointer", "m_nInspectStage") + 8);
	if (dot != -1)
	{
		RemoveEntity(dot);
		SetEntDataEnt2(pThis, FindSendPropInfo("CTFLaserPointer", "m_nInspectStage") + 8, -1);
	}
	return MRES_Supercede;
}

public MRESReturn CTFLaserPointer_UpdateLaserDot(int pThis)
{
	int owner = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	if (owner == -1)
		return MRES_Supercede;

	float vecMuzzlePos[3]; GetClientEyePosition(owner, vecMuzzlePos);
	float fwd[3]; GetClientEyeAngles(owner, fwd);

	TR_TraceRayFilter(vecMuzzlePos, fwd, MASK_SOLID, RayType_Infinite, CTraceFilterIgnoreTeammatesAndTeamObjects, owner);

	int dot = GetEntDataEnt2(pThis, FindSendPropInfo("CTFLaserPointer", "m_nInspectStage") + 8);
	if (dot != -1)
	{
		int entindex = TR_GetEntityIndex();
		if (0 < entindex <= MaxClients && GetEntProp(entindex, Prop_Data, "m_takedamage") != 0)
		{
			// We lased a player target. We want to auto-aim on this guy for a short period of time.
			int numobjs = GetNumObjects(owner);
			if (numobjs > 0)
			{
				int[] objs = new int[numobjs]
				int num = GetObjectsOfType(owner, TFObject_Sentry, objs);
				for (int i = 0; i < num; ++i)
					SetAutoAimTarget(objs[i], entindex);
			}
		}

		float endpos[3]; TR_GetEndPosition(endpos);
		float normal[3]; TR_GetPlaneNormal(null, normal);
		CSniperDot_Update(dot, entindex, endpos, normal);
	}
	return MRES_Supercede;
}

stock void SetAutoAimTarget(int obj, int enemy)
{
	// No auto aim target if a dummy is found
	int old = GetEntPropEnt(obj, Prop_Send, "m_hEnemy");
	if (old != -1)
	{
		char cls[32]; GetEntityClassname(old, cls, sizeof(cls));
		if (!strcmp(cls, "tf_target_dummy", false))
		{
			SetEntProp(obj, Prop_Send, "m_hAutoAimTarget", 0);
			return;
		}
	}

	SetEntPropEnt(obj, Prop_Send, "m_hAutoAimTarget", enemy);
	SetEntDataFloat(obj, FindSendPropInfo("CObjectSentrygun", "m_hAutoAimTarget") + 4, GetGameTime());
}

public bool CTraceFilterIgnoreTeammatesAndTeamObjects(int ent, int mask, any data)
{
	if (GetEntProp(ent, Prop_Send, "m_iTeamNum") == GetEntProp(data, Prop_Send, "m_iTeamNum"))
	{
		return false;
	}

	if (0 < ent <= MaxClients)
	{
		if (TF2_IsPlayerInCondition(ent, TFCond_Disguised) && GetDisguiseTeam(ent) == GetEntProp(data, Prop_Send, "m_iTeamNum"))
			return false;

		if (IsStealthed(ent))
			return false;
	}
	return true;
}

public MRESReturn CTFPlayer_TFPlayerThink(int pThis)
{
	int offs = FindSendPropInfo("CTFPlayer", "m_bMatchSafeToLeave") + 69;	// Nice
	if (!GetEntData(pThis, offs, 1))
	{
		if (TF2_GetPlayerClass(pThis))
		{
			int numobjs = GetNumObjects(pThis);
			if (numobjs > 0)
			{
				int[] objs = new int[numobjs]
				int num = GetObjectsOfType(pThis, TFObject_Sentry, objs);
				if (num <= 0)
					SetEntData(pThis, offs, 1, 1);
				else
				{
					float mypos[3]; GetAbsOrigin(pThis, mypos);
					float otherpos[3];
					bool success = true;
					for (int i = 0; i < num; ++i)
					{
						GetAbsOrigin(objs[i], otherpos);
						if (GetVectorDistance(mypos, otherpos, true) <= 2500)
						{
							success = false;
							break;
						}
					}
					if (success)
						SetEntData(pThis, offs, 1, 1);
				}
			}
		}
		else SetEntData(pThis, offs, 1, 1);
	}
}

public MRESReturn CTFPlayer_RemoveAllObjects(int pThis, DHookParam hParams)
{
	if (!g_ActualObjects[pThis])
		return;

	ObjectInfo info;
	for (int i = g_ActualObjects[pThis].Length-1; i >= 0; --i)
	{
		g_ActualObjects[pThis].GetArray(i, info, sizeof(info));
		if (IsValidEntity(info.ref))
		{
			Event event = CreateEvent("object_removed");
			if (event)
			{
				event.SetInt("userid", GetClientUserId(pThis));
				event.SetInt("objecttype", view_as< int >(info.GetType()));
				event.SetInt("index", info.ref & 0xFFF);
				event.Fire();
			}
			if (hParams.Get(1))
			{
				SetVariantInt(9999);
				AcceptEntityInput(info.ref, "RemoveHealth");
			}
			else
			{
				CCollisionProperty_SetSolid(GetEntityAddress(info.ref) + view_as< Address >(FindSendPropInfo("CBaseEntity", "m_Collision")), 0);	// SOLID_NONE
				RemoveEntity(info.ref);
			}
		}
	}
	g_ActualObjects[pThis].Clear();
}

// Overriding this completely
// Match newly built teleporters with a teleporter with the smallest build number
public MRESReturn CObjectTeleporter_FindMatch(int pThis, DHookReturn hReturn)
{
	int builder = GetBuilder(pThis);
	if (!(0 < builder <= MaxClients))
	{
		hReturn.Value = -1;
		return MRES_Supercede;
	}

	ObjectInfo info;
	TFObjectType iObjType = TF2_GetObjectType(pThis);
	int match = -1;
	int idx = g_ActualObjects[builder].FindValue(EntIndexToEntRef(pThis));
	// Fricking impossible
	if (idx == -1)
		return MRES_Ignored;

	g_ActualObjects[builder].GetArray(idx, info);
	int mybuildnumber = info.buildnumber;
	float mybuildtime = info.buildtime;

	for (int i = 0; i < g_ActualObjects[builder].Length; i++)
	{
		g_ActualObjects[builder].GetArray(i, info);
		if (!IsValidEntity(info.ref))
			continue;

		if ((info.ref & 0xFFF != pThis) && (iObjType == info.GetType()) && mybuildnumber == info.buildnumber)
		{
			if (HasEntProp(info.ref, Prop_Send, "m_bMatchBuilding") && 
				((IsEntrance(pThis) && IsExit(info.ref)) || (IsExit(pThis) && IsEntrance(info.ref))))
			{
				int other = GetEntDataEnt2(info.ref, FindSendPropInfo("CObjectTeleporter", "m_bMatchBuilding") + 4);
				if (other != -1 && other != pThis)
				{
					match = -1;
					continue;
				}
				// This is to align teleporter destruction
				// E.g. if a teleporter is broken, and u replace that teleporter, 
				// its match should not be destroyed at a different position than
				// the one that you just built
				info.buildtime = mybuildtime;
				match = info.ref;
				break;
			}
		}
	}

	if (match != -1)
	{
		bool bFrom = (GetUpgradeLevel(match) > GetUpgradeLevel(pThis) || GetUpgradeMetal(match) > GetUpgradeMetal(pThis));
		CopyUpgradeStateToMatch(pThis, match, bFrom);
	}

	hReturn.Value = match;
	return MRES_Supercede;
}
// AddObject is inlined on windows ;-;
// We need to skip over the actual vector if this is a multiple
// AKA, if we build 2 sentries, we don't want both under m_aObjects
public MRESReturn CTFPlayer_FinishedObject(int pThis, DHookParam hParams)
{
	int obj = hParams.Get(1);
	TFObjectType type = TF2_GetObjectType(obj);
	TFObjectMode mode = TF2_GetObjectMode(obj);

	CUtlVector m_aObjects = GetObjectVector(pThis);
//	bool addtovec = true;
	// I don't even think this loop runs because the PDA is still out
	// and the vector is flushed when that happens
//	for (int i = m_aObjects.Count()-1; i >= 0; --i)
//	{
//		int foundobj = m_aObjects.GetEx(i);
//		if (foundobj == -1)
//		{
//			m_aObjects.FastRemove(i);			
//			continue;
//		}
//		foundobj &= 0xFFF;
//		if (!IsValidEntity(foundobj) || foundobj <= MaxClients)
//		{
//			m_aObjects.FastRemove(i);
//			continue;
//		}
//
//		if (TF2_GetObjectType(foundobj) == type)
//		{
//			if (type == TFObject_Teleporter && TF2_GetObjectMode(foundobj) != mode)
//				continue;
//
//			addtovec = false;
//			break;
//		}
//	}
//
//	if (addtovec)
//	{
//		m_aObjects.AddToTail(GetEntityHandle(obj));
//	}

	int oldest = GetOldestObject(pThis, type, mode);
	if (oldest != -1)
		m_aObjects.AddToTail(GetEntityHandle(oldest));
	else m_aObjects.AddToTail(GetEntityHandle(obj));

	CTFGameStats_Event_PlayerCreatedBuilding(pThis, obj);

	if (g_ActualObjects[pThis].FindValue(EntIndexToEntRef(obj)) != -1)
		return MRES_Supercede;

	ObjectInfo info;
	info.ref = EntIndexToEntRef(obj);
	info.buildtime = GetGameTime();

	// Now there is a possibility that an object could be destroyed, poking a hole
	// in the build number list
	// Best option seems to be filling up a buffer at each index if there's a matching
	// build number
	// Then start running up the buffer and if there's a missing index, use it instead
	int buildnumber;
	int numobjs = GetNumObjects(pThis);
	if (numobjs > 0)
	{
		ObjectInfo info2;
		int highestbuildnumber = numobjs;
		for (int i = numobjs-1; i >= 0; --i)
		{
			g_ActualObjects[pThis].GetArray(i, info2);
			if (!IsValidEntity(info2.ref))
			{
				g_ActualObjects[pThis].Erase(i);
				continue;
			}

			if (info2.GetType() != type)
				continue;

			if (type == TFObject_Teleporter && info2.GetMode() != mode)
				continue;

			if (highestbuildnumber < info2.buildnumber)
				highestbuildnumber = info2.buildnumber;
		}

		bool[] objchecker = new bool[highestbuildnumber+1];
		for (int i = numobjs-1; i >= 0; --i)
		{
			g_ActualObjects[pThis].GetArray(i, info2);

			if (info2.GetType() != type)
				continue;

			if (type == TFObject_Teleporter && info2.GetMode() != mode)
				continue;

			objchecker[info2.buildnumber] = true;
		}

		// Pick the soonest possible index
		// Kinda sucks for teleporters, but oh well
		int i;
		for (i = 0; i < numobjs; ++i)
			if (!objchecker[i])
				break;
		buildnumber = i;
	}

	info.buildnumber = buildnumber;
	g_ActualObjects[pThis].PushArray(info);
	return MRES_Supercede;
}

public Action OnPlayerRunCsmd(int client)
{
	//	ObjectInfo info;
	//	for (int i = g_ActualObjects[client].Length-1; i >= 0; --i)
	//	{
	//		g_ActualObjects[client].GetArray(i, info, sizeof(info));
	//		if (!IsValidEntity(info.ref))
	//		{
	//			g_ActualObjects[client].Erase(i);
	//			continue;
	//		}
	//		PrintToChat(client, "%d %d", info.ref, info.GetType());
	//	}
	CUtlVector vec = GetObjectVector(client);
//	if (!GetRandomInt(0, 10))
	{
		for (int i = vec.Count()-1; i >= 0; --i)
		{
			PrintToChat(client, "%d %d %d %d", i, vec.GetEx(i), vec.GetEx(i) & 0xFFF, TF2_GetObjectType(vec.GetEx(i) & 0xFFF));
		}
	}
}

public MRESReturn CTFPlayer_RemoveObject(int pThis, DHookParam hParams)
{
	if (!g_ActualObjects[pThis])
		return MRES_Ignored;

	int obj = hParams.Get(1);
	int idx = g_ActualObjects[pThis].FindValue(EntIndexToEntRef(obj));
	TFObjectType type = TF2_GetObjectType(obj);
	TFObjectMode mode = TF2_GetObjectMode(obj);
	if (idx != -1)
		g_ActualObjects[pThis].Erase(idx);

	int oldestobj = GetOldestObject(pThis, type, mode);
	if (oldestobj != -1)
	{
		CUtlVector m_aObjects = GetObjectVector(pThis);
		any handle = GetEntityHandle(oldestobj);
		if (m_aObjects.FindEx(handle) == -1)
			m_aObjects.AddToTail(handle);
	}
	return MRES_Ignored;
}

public MRESReturn CTFPlayer_BuildObservableEntityList(int pThis, DHookReturn hReturn)
{
	if (!g_ActualObjects[pThis])
		return MRES_Ignored;

	int iNumObjects = GetNumObjects(pThis);
	CUtlVector m_hObservableEntities = GetObservableEntities(pThis);
	int currentidx = -1;
	for (int i = 0; i < iNumObjects; i++)
	{
		int obj = GetObject(pThis, i) & 0xFFF;
		if (IsValidEntity(obj))
		{
			int handle = GetEntityHandle(obj);
			if (m_hObservableEntities.FindEx(handle) == -1)
			{
				// Sadly this will put bosses and trains/carts before one's own buildings to spectate
				// Not a big deal, but someone might notice. Whatever...
				m_hObservableEntities.AddToTail(handle);

				if (GetEntPropEnt(pThis, Prop_Send, "m_hObserverTarget") == obj)
					currentidx = m_hObservableEntities.Count() - 1;
			}
		}
	}
	if (currentidx != -1)
	{
		hReturn.Value = currentidx;
		return MRES_Override;
	}
	return MRES_Ignored;
}

// Should also do CTFPlayer::FindNearestObservableTarget. Right now it'll auto spec to the first sentry you build,
// Once again, not a big deal. Who even cares about this stuff?

// This is a pretty big function and won't be easy to reimplement.
// So the best course of action is to cheese it
// by slapping our number into the loop and overriding
// more functions
// Woohoo!
bool
	g_InPickupCall
;
public MRESReturn CTFPlayer_TryToPickupBuilding(int pThis)
{
	g_InPickupCall = true;
}
public MRESReturn CTFPlayer_TryToPickupBuilding_Post(int pThis)
{
	g_InPickupCall = false;
}

public MRESReturn CTFPlayer_GetObjectCount(int pThis, DHookReturn hReturn)
{
	if (g_InPickupCall)
	{
		hReturn.Value = GetNumObjects(pThis);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public MRESReturn CTFPlayer_GetObject(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	if (g_InPickupCall)
	{
		ObjectInfo info;
		g_ActualObjects[pThis].GetArray(hParams.Get(1), info, sizeof(info));
		hReturn.Value = info.ref;
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public void OnPlayerDied(Event event, const char[] name, bool db)
{
	if (event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	int rstate = GameRules_GetProp("m_iRoundState");
	int gtype = GameRules_GetProp("m_nGameType");
	if (TF2_GetPlayerClass(client) == TFClass_Engineer && rstate == GR_STATE_STALEMATE && gtype == TF_GAMETYPE_ARENA)
		DestroyAllObjects(client);
}

stock int GetNumObjects(int client)
{
	return g_ActualObjects[client].Length;
}

stock int GetIdealActivity(int ent)
{
	return GetEntData(ent, FindSendPropInfo("CBaseCombatWeapon", "m_iWorldModelIndex") + 16);
}

stock int GetDisguiseTeam(int client)
{
	return TF2_IsPlayerInCondition(client, TFCond_DisguisedAsDispenser) ? ((GetClientTeam(client) == 2) ? 3 : 2) : GetEntProp(client, Prop_Send, "m_nDisguiseTeam");
}

stock bool IsStealthed(int client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Stealthed) || TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade));
}

stock int GetObjectsOfType(int client, TFObjectType type, int[] objs)
{
	int count;
	ObjectInfo info;
	for (int i = g_ActualObjects[client].Length-1; i >= 0; --i)
	{
		g_ActualObjects[client].GetArray(i, info, sizeof(info));
		if (!IsValidEntity(info.ref))
		{
			g_ActualObjects[client].Erase(i);
			continue;
		}

		if (info.GetType() == type)
			objs[count++] = info.ref;
	}
	return count;
}

stock void DestroyAllObjects(int client)
{
	ObjectInfo info;
	for (int i = g_ActualObjects[client].Length-1; i >= 0; --i)
	{
		g_ActualObjects[client].GetArray(i, info, sizeof(info));
		if (IsValidEntity(info.ref))
		{
			SetVariantInt(9999);
			AcceptEntityInput(info.ref, "RemoveHealth");
		}
	}
	g_ActualObjects[client].Clear();
}

stock any GetObjectVector(int client)
{
	return GetEntityAddress(client) + view_as< Address >(FindSendPropInfo("CTFPlayer", "m_flMvMLastDamageTime") + 48);
}

stock any GetObservableEntities(int client)
{
	return GetEntityAddress(client) + view_as< Address >(FindSendPropInfo("CTFPlayer", "m_flMvMLastDamageTime") + 96);
}

stock void CopyUpgradeStateToMatch(int ent, int match, bool from)
{
	if (from)
		CopyUpgradeStateToMatch(match, ent, false); 
	else
	{
		SetEntProp(match, Prop_Send, "m_iHighestUpgradeLevel", GetEntProp(ent, Prop_Send, "m_iHighestUpgradeLevel"));
		SetEntProp(match, Prop_Send, "m_iUpgradeLevel", GetEntProp(ent, Prop_Send, "m_iUpgradeLevel"));
		SetEntProp(match, Prop_Send, "m_iUpgradeMetal", GetEntProp(ent, Prop_Send, "m_iUpgradeMetal"));
		SetEntProp(match, Prop_Send, "m_iUpgradeMetalRequired", GetEntProp(ent, Prop_Send, "m_iUpgradeMetalRequired"));
		SetEntData(match, FindSendPropInfo("CObjectTeleporter", "m_iHighestUpgradeLevel") + 4, GetEntData(ent, FindSendPropInfo("CObjectTeleporter", "m_iHighestUpgradeLevel") + 4));
		SetEntDataFloat(match, FindSendPropInfo("CObjectTeleporter", "m_iHighestUpgradeLevel") + 8, GetEntDataFloat(ent, FindSendPropInfo("CObjectTeleporter", "m_iHighestUpgradeLevel") + 8));
	}
}

stock int GetBuilder(int obj)
{
	return GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
}

stock int GetTeleType(int tele)
{
	return GetEntData(tele, FindSendPropInfo("CObjectTeleporter", "m_bMatchBuilding") + 44);
}

stock bool IsEntrance(int tele)
{
	return GetTeleType(tele) == 1;
}

stock bool IsExit(int tele)
{
	return GetTeleType(tele) == 2;
}

stock int GetUpgradeLevel(int obj)
{
	return GetEntProp(obj, Prop_Send, "m_iUpgradeLevel");
}

stock int GetUpgradeMetal(int obj)
{
	return GetEntProp(obj, Prop_Send, "m_iUpgradeMetal");
}

stock int GetObject(int client, int idx)
{
	ObjectInfo info;
	g_ActualObjects[client].GetArray(idx, info);
	return info.ref;
}

stock bool CTFLaserPointer_CanAttack(int ent)
{
	return SDKCall(hCTFLaserPointer_CanAttack, ent);
}

stock void CTFWeaponBase_SendWeaponAnim(int ent, int anim)
{
	SDKCall(hCTFWeaponBase_SendWeaponAnim, ent, anim);
}

stock void CSniperDot_Update(int ent, int enemy, float endpos[3], float normal[3])
{
	SDKCall(hCSniperDot_Update, ent, enemy, endpos, normal);
}

stock void GetAbsOrigin(int ent, float buffer[3])
{
	SDKCall(hCalcAbsolutePosition, ent);
	GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", buffer);
}

stock void CCollisionProperty_SetSolid(any col, int solid)
{
	SDKCall(hCCollisionProperty_SetSolid, col, solid);
}

stock void CTFGameStats_Event_PlayerCreatedBuilding(int player, int obj)
{
	SDKCall(hCTFGameStats_Event_PlayerCreatedBuilding, g_GameStats, player, obj);
}

stock bool IsPDA(int wep)
{
	char cls[32]; GetEntityClassname(wep, cls, sizeof(cls));
	return !strncmp(cls, "tf_weapon_pda_engineer", 22, false);
}

stock void AllowBuilding(int client)
{
	int count[3];
	int teleportercount[2];

	ObjectInfo info;
	for (int i = GetNumObjects(client)-1; i >= 0; --i)
	{
		g_ActualObjects[client].GetArray(i, info);
		if (!IsValidEntity(info.ref))
			g_ActualObjects[client].Erase(i);

		++count[view_as< int >(info.GetType())];
		if (info.GetType() == TFObject_Teleporter)
			++teleportercount[view_as< int >(info.GetMode())];
	}

	CUtlVector m_aObjects = GetObjectVector(client);
	for (int i = m_aObjects.Count()-1; i >= 0; --i)
	{
		int foundobj = m_aObjects.GetEx(i);
		if (foundobj == -1)
		{
			m_aObjects.FastRemove(i);			
			continue;
		}
		foundobj &= 0xFFF;
		if (!IsValidEntity(foundobj) || foundobj <= MaxClients)
		{
			m_aObjects.FastRemove(i);
			continue;
		}

		bool remove = false;

		TFObjectType currtype = TF2_GetObjectType(foundobj);
		if (currtype == TFObject_Teleporter)
			remove |= teleportercount[view_as< int >(TF2_GetObjectMode(foundobj))] < cvMax[1].IntValue;

		remove |= count[view_as< int >(currtype)] < cvMax[view_as< int >(currtype)].IntValue;

		if (remove)
			m_aObjects.FastRemove(i);
	}
}

stock void AllowDestroying(int client)
{
	CUtlVector m_aObjects = GetObjectVector(client);
	bool hasobj[4];
	for (int i = m_aObjects.Count()-1; i >= 0; --i)
	{
		int foundobj = m_aObjects.GetEx(i);
		if (foundobj == -1)
		{
			m_aObjects.FastRemove(i);			
			continue;
		}
		foundobj &= 0xFFF;
		if (!IsValidEntity(foundobj) || foundobj <= MaxClients)
		{
			m_aObjects.FastRemove(i);
			continue;
		}

		// Ugly teleporter crap
		switch (TF2_GetObjectType(foundobj))
		{
			case TFObject_Sentry, TFObject_Dispenser:hasobj[view_as< int >(TF2_GetObjectType(foundobj))] = true;
			case TFObject_Teleporter:
			{
				switch (TF2_GetObjectMode(foundobj))
				{
					case TFObjectMode_Entrance:hasobj[1] = true;
					case TFObjectMode_Exit:hasobj[3] = true;
				}
			}
		}
	}

	int obj;
	for (int i = 0; i < 4; ++i)
	{
		if (hasobj[i])
			continue;

		switch (i)
		{
			case 0:
			{
				obj = GetOldestObject(client, TFObject_Dispenser);
				if (obj != -1)
				{
					any handle = GetEntityHandle(obj);
					if (m_aObjects.FindEx(handle) == -1)
						m_aObjects.AddToTail(handle);
				}
			}
			case 1:
			{
				obj = GetOldestObject(client, TFObject_Teleporter, TFObjectMode_Entrance);
				if (obj != -1)
				{
					any handle = GetEntityHandle(obj);
					if (m_aObjects.FindEx(handle) == -1)
						m_aObjects.AddToTail(handle);
				}
			}
			case 2:
			{
				obj = GetOldestObject(client, TFObject_Sentry);
				if (obj != -1)
				{
					any handle = GetEntityHandle(obj);
					if (m_aObjects.FindEx(handle) == -1)
						m_aObjects.AddToTail(handle);
				}
			}
			case 3:
			{
				obj = GetOldestObject(client, TFObject_Teleporter, TFObjectMode_Exit);
				if (obj != -1)
				{
					any handle = GetEntityHandle(obj);
					if (m_aObjects.FindEx(handle) == -1)
						m_aObjects.AddToTail(handle);
				}
			}
		}
	}
}

stock int GetOldestObject(int client, TFObjectType type, TFObjectMode mode = TFObjectMode_Invalid)
{
	int obj = -1;
	ObjectInfo info;
	float oldest = GetGameTime();	// 0x7f7fffff
	for (int i = GetNumObjects(client)-1; i >= 0; --i)
	{
		g_ActualObjects[client].GetArray(i, info);
		if (!IsValidEntity(info.ref))
		{
			g_ActualObjects[client].Erase(i);
			continue;
		}

		if (info.GetType() == type && (mode == TFObjectMode_Invalid || info.GetMode() == mode))
		{
			if (info.buildtime < oldest)
			{
				obj = info.ref;
				oldest = info.buildtime;
			}
		}
	}
	return obj;
}