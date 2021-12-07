#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION	"1.0.6"

bool WP_ENABLED[MAXPLAYERS + 1];
bool FOL_ENABLED[MAXPLAYERS + 1];
bool PL_Enabled;

int BrushEntityIndex[MAXPLAYERS + 1][1]; //Array of brush entities (trigger_teleport)
int Offset_for_entity_effect = -1;

Handle HudDisplay;

ConVar g_pluginEnabled;

public Plugin myinfo =
{
	name = "Wall Pogo Assistant",
	author = "Master Cake",
	description = "This plugin helps jumpers to learn Wall Pogo",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("wp_version", PLUGIN_VERSION, "Wall Pogo Assistant Version", FCVAR_REPLICATED | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_pluginEnabled = CreateConVar("wp_enabled", "1", "Enable Wall Pogo Assistant\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	PL_Enabled = GetConVarBool(g_pluginEnabled);

	HookConVarChange(g_pluginEnabled, ConsoleVarChange);

	Offset_for_entity_effect = FindSendPropInfo("CBaseEntity", "m_fEffects"); //Find offset to "m_fEffects" property
	if (Offset_for_entity_effect == -1)
		SetFailState("m_fEffects property not found!");

	RegConsoleCmd("sm_wp", WP_Command, "Command to enable/disable Wall Pogo Assistant");
	RegConsoleCmd("sm_trigger", TR_Command, "Command to display trigger_teleport brush entity");
	RegConsoleCmd("sm_distrigger", DITR_Command, "Command to disable trigger_teleport brush entity");

	RegAdminCmd("sm_followrockets", FOL_Command, ADMFLAG_GENERIC, "Command to enable/disable Follow Rockets Mode");
	RegAdminCmd("sm_setfollowrockets", SETFOL_Command, ADMFLAG_GENERIC, "Enable/disable Follow Rockets Mode for the specified player");

	AutoExecConfig(true, "wp");
	HudDisplay = CreateHudSynchronizer();
}

public void ConsoleVarChange(Handle CVar, const char[] oldValue, const char[] newValue)
{
	if(CVar == g_pluginEnabled)
	{
		PL_Enabled = GetConVarBool(g_pluginEnabled);
	}
}

public void OnClientPutInServer(int myClient)
{
	WP_ENABLED[myClient] = false;
	FOL_ENABLED[myClient] = false;
	BrushEntityIndex[myClient][0] = -1;
}

public Action WP_Command(int myClient, int args)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (!WP_ENABLED[myClient])
	{
    	WP_ENABLED[myClient] = true;
    	ReplyToCommand(myClient, "[SM] Wall Pogo Assistant Enabled!");
    	if (TF2_GetPlayerClass(myClient) != TFClass_Soldier)
    	{
    		ClearSyncHud(myClient, HudDisplay);
    		SetHudTextParams(-1.0, -1.0, 3.0, 255, 255, 255, 255, 0, 0.1, 0.1, 0.1);
    		ShowSyncHudText(myClient, HudDisplay, "GO SOLLY");
    		WP_ENABLED[myClient] = false;
    	}
    	return Plugin_Continue;
    }
	if (WP_ENABLED[myClient])
    {
    	WP_ENABLED[myClient] = false;
    	BrushEntityIndex[myClient][0] = -1;
    	ReplyToCommand(myClient, "[SM] Wall Pogo Assistant Disabled!");
    }

	return Plugin_Handled;
}

public Action TR_Command(int myClient, int args)
{
	if(!PL_Enabled || !IsValidClient(myClient) || !WP_ENABLED[myClient])
		return Plugin_Continue;

	float FL_TargetPos[3];
	float FL_PlayerPos[3];
	float FL_PlayerAng[3];
	GetClientEyePosition(myClient, FL_PlayerPos);
	GetClientEyeAngles(myClient, FL_PlayerAng);
	Handle myTrace = TR_TraceRayFilterEx(FL_PlayerPos, FL_PlayerAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilterEntity);

 	if(TR_DidHit(myTrace))
	{
		TR_GetEndPosition(FL_TargetPos, myTrace);
		TR_EnumerateEntities(FL_PlayerPos, FL_TargetPos, PARTITION_TRIGGER_EDICTS, RayType_EndPoint, DetectTrigger, myClient);
		if (BrushEntityIndex[myClient][0] != -1)
			ShowTrigger(BrushEntityIndex[myClient][0]);
	}
	delete myTrace;

	return Plugin_Handled;
}

public Action DITR_Command(int myClient, int args)
{
	if(!PL_Enabled || !IsValidClient(myClient) || !WP_ENABLED[myClient])
		return Plugin_Continue;

	float FL_TargetPos[3];
	float FL_PlayerPos[3];
	float FL_PlayerAng[3];
	GetClientEyePosition(myClient, FL_PlayerPos);
	GetClientEyeAngles(myClient, FL_PlayerAng);
	Handle myTrace = TR_TraceRayFilterEx(FL_PlayerPos, FL_PlayerAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilterEntity);

 	if(TR_DidHit(myTrace))
	{
		TR_GetEndPosition(FL_TargetPos, myTrace);
		TR_EnumerateEntities(FL_PlayerPos, FL_TargetPos, PARTITION_TRIGGER_EDICTS, RayType_EndPoint, DetectTrigger, myClient);
		if (BrushEntityIndex[myClient][0] != -1)
			DisableTrigger(BrushEntityIndex[myClient][0]);
	}
	delete myTrace;

	return Plugin_Handled;
}

public Action FOL_Command(int myClient, int args)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (!FOL_ENABLED[myClient])
	{
    	FOL_ENABLED[myClient] = true;
    	ReplyToCommand(myClient, "[SM] Follow Rockets Mode Enabled!");
    	return Plugin_Continue;
    }

	if (FOL_ENABLED[myClient])
    {
    	FOL_ENABLED[myClient] = false;
    	ReplyToCommand(myClient, "[SM] Follow Rockets Mode Disabled!");
    }

	return Plugin_Handled;
}

public Action SETFOL_Command(int myClient, int args)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (args != 2)
	{
    	ReplyToCommand(myClient, "Usage: sm_setfollowrockets <player> [0/1]");
    	return Plugin_Handled;
	}

	char myArgs[32];
	GetCmdArg(1, myArgs, sizeof(myArgs));
	int myTarget = FindTarget(myClient, myArgs);

	if (myTarget == -1)
	{
		return Plugin_Handled;
	}

	char myArgs2[32];
	GetCmdArg(2, myArgs2, sizeof(myArgs2));
	bool flag = view_as<bool>(StringToInt(myArgs2));

	char myClientName[32];
	GetClientName(myTarget, myClientName, sizeof(myClientName));
	FOL_ENABLED[myTarget] = flag;
	if (flag)
	{
    	ReplyToCommand(myClient, "Follow Rockets Mode enabled for %s", myClientName);
    	PrintToChat(myTarget, "Follow Rockets Mode enabled");
	}
	else
	{
    	ReplyToCommand(myClient, "Follow Rockets Mode disabled for %s", myClientName);
    	PrintToChat(myTarget, "Follow Rockets Mode disabled");
    	FOL_ENABLED[myTarget] = false;
	}

	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int myClient, int &myButtons, int &myImpulse, float myVel[3], float myAng[3], int &myWeapon)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (TF2_GetPlayerClass(myClient) != TFClass_Soldier)
		WP_ENABLED[myClient] = false;

	if(IsPlayerAlive(myClient) && IsValidClient(myClient) && WP_ENABLED[myClient] && myButtons & IN_DUCK)
	{
		static float FL_Angles[3];

		/*Indicator begins here*/
		static float FL_TargetPos[3];
		static float FL_PlayerPos[3];
		static float FL_PlayerAng[3]; FL_PlayerAng[0] = 90.0; FL_PlayerAng[1] = 0.0; FL_PlayerAng[2] = 0.0;
		static float FL_TargetVec[3];
		GetClientAbsOrigin(myClient, FL_PlayerPos);
		Handle myTrace = TR_TraceRayFilterEx(FL_PlayerPos, FL_PlayerAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilterEntity);

 		if(TR_DidHit(myTrace))
		{
			TR_GetEndPosition(FL_TargetPos, myTrace);
			TR_EnumerateEntities(FL_PlayerPos, FL_TargetPos, PARTITION_TRIGGER_EDICTS, RayType_EndPoint, DetectTrigger, myClient);
		}
		delete myTrace;

		SubtractVectors(FL_PlayerPos, FL_TargetPos, FL_TargetVec); //Distance to the ground
		//float FL_Dist = GetVectorLength(FL_TargetVec);
		char msg[32];

		ClearSyncHud(myClient, HudDisplay);
		SetHudTextParams(0.65, 0.55, 0.0001, 255, 255, 255, 255, 0, 0.1, 0.1, 0.1);
		if (BrushEntityIndex[myClient][0] != -1)
			msg = "YES";
		else
			msg = "NO";
		ShowSyncHudText(myClient, HudDisplay, "Distance to the ground: %1.3f \n\nTrigger detected: %s \n\nIndex (trigger_teleport): %i", FL_TargetVec[2], msg, BrushEntityIndex[myClient][0]);
		/*Indicator ends here*/

		GetClientEyeAngles(myClient, FL_Angles);

		if (FL_Angles[0] >= 75.0 && FL_Angles[0] <= 79.9)
		{
			SetHudTextParams(0.475, 0.4, 0.5, 0, 0, 255, 0, 0, 0.1, 0.1, 0.1);
			ShowHudText(myClient, -1, "▲▲▲");
			return Plugin_Continue;
		}
		if (FL_Angles[0] >= 80.55 && FL_Angles[0] <= 81.0)
		{
			SetHudTextParams(0.475, 0.55, 0.5, 0, 255, 0, 0, 0, 0.1, 0.1, 0.1);
			ShowHudText(myClient, -1, "▼▼▼");
			return Plugin_Continue;
		}

		if (FL_Angles[0] >= 80.0 && FL_Angles[0] <= 80.54)
		{
			SetHudTextParams(0.44, 0.483, 0.5, 255, 255, 0, 0, 0, 0.1, 0.1, 0.1);
			ShowHudText(myClient, -1, "►►►    ◄◄◄");
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public void OnEntityCreated(int myEntity, const char[] MyName)
{
	if (StrContains(MyName, "tf_projectile_") == 0)
	{
		if (StrEqual(MyName[14], "rocket"))
		{
			SDKHook(myEntity, SDKHook_SpawnPost, RockSpawn);
		}
	}
}

public Action RockSpawn(int myEntity)
{
	int myRef = EntIndexToEntRef(myEntity); //Converts an entity index into a serial encoded entity reference.
	static int PrevRef = -1;

	if (PL_Enabled && PrevRef != myRef)
	{
		PrevRef = myRef; //To execute the code 1 time in this scope

		int myOwner = GetEntPropEnt(myEntity, Prop_Data, "m_hOwnerEntity");

		if (IsValidClient(myOwner) && FOL_ENABLED[myOwner])
		{
			CreateTimer(0.0005, rocketCheck, myEntity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action rocketCheck(Handle timer, int myEntity)
{
	if(!IsValidEntity(myEntity))
	{
		return Plugin_Stop;
	}

	int myOwner = GetEntPropEnt(myEntity, Prop_Data, "m_hOwnerEntity");
	float FL_PosEntity[3];
	float FL_AngEntity[3];
	float FL_VelEntity[3];

	float FL_TargetPos[3];
	float FL_TargetVec[3];

	float FL_MidVector[3];

	if (FOL_ENABLED[myOwner])
	{
		GetTargetOfPlayerEye(myOwner, FL_TargetPos);

		GetEntPropVector(myEntity, Prop_Data, "m_vecAbsOrigin", FL_PosEntity);
		GetEntPropVector(myEntity, Prop_Data, "m_angRotation", FL_AngEntity);
		GetEntPropVector(myEntity, Prop_Data, "m_vecAbsVelocity", FL_VelEntity);

		float FL_VelRock = GetVectorLength(FL_VelEntity);

		SubtractVectors(FL_TargetPos, FL_PosEntity, FL_TargetVec); //Distance to target

		AddVectors(FL_VelEntity, FL_TargetVec, FL_MidVector);
		AddVectors(FL_VelEntity, FL_MidVector, FL_VelEntity);
		NormalizeVector(FL_VelEntity, FL_VelEntity);

		GetVectorAngles(FL_VelEntity, FL_AngEntity);
		SetEntPropVector(myEntity, Prop_Data, "m_angRotation", FL_AngEntity);

		ScaleVector(FL_VelEntity, FL_VelRock); //Scales vector to initial value size
		SetEntPropVector(myEntity, Prop_Data, "m_vecAbsVelocity", FL_VelEntity);

		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public bool DetectTrigger(int myEntity, int myClient)
{
	char myClassName[50];
	GetEntityClassname(myEntity, myClassName, sizeof(myClassName));
	if (StrEqual(myClassName, "trigger_teleport"))
	{
		BrushEntityIndex[myClient][0] = myEntity;
		return false;
	}
	else
	{
		BrushEntityIndex[myClient][0] = -1;
		return true;
	}
}

public bool TraceFilterEntity(int myEntity, int myMask)
{
	return (myEntity == 0 || myEntity > MaxClients); //0 - server console
}

public bool TraceFilter(int myEntity, int myMask, any myData)
{
	if (myEntity <= 0)
		return true;
	if (myEntity == myData)
		return false;

	char myClassName[128];
	GetEdictClassname(myEntity, myClassName, sizeof(myClassName));
	if(StrEqual(myClassName,"func_respawnroomvisualizer", false))
	{
		return false;
	}
	else
	{
		return true;
	}
}

public Action Func_SetTransmit(int entity, int myClient)
{
	if (!WP_ENABLED[myClient])
	{
		return Plugin_Handled; //Disable trigger_teleport transmit to the client (if plugin is disabled for current player in array)
	}
	return Plugin_Continue;
}

/////////////////////////////// <-- STOCKS --> ////////////////////////////////////////////////

/**
 * Checks client validity
 * @param myEntity        Entity index.
 * @param Replay          Logical bool parameter.
 */
stock bool IsValidClient(int myClient, bool Replay = true)
{
  if(myClient <= 0 || myClient > MaxClients || !IsClientInGame(myClient))
    return false;
  if(Replay && (IsClientSourceTV(myClient) || IsClientReplay(myClient) || IsClientObserver(myClient)))
    return false;
  return true;
}

/**
 * Gets vector where player looks
 * @param myEntity        Entity index.
 * @param FL_TargetPos    Output buffer.
 */
stock void GetTargetOfPlayerEye(int myEntity, float FL_TargetPos[3])
{
 	float FL_Pos[3];
 	float FL_Ang[3];

 	GetClientEyePosition(myEntity, FL_Pos);
 	GetClientEyeAngles(myEntity, FL_Ang);

 	Handle Trace = TR_TraceRayFilterEx(FL_Pos, FL_Ang, MASK_SHOT_HULL, RayType_Infinite, TraceFilter, myEntity);

 	if(TR_DidHit(Trace))
	{
		TR_GetEndPosition(FL_TargetPos, Trace);
	}
	delete Trace;
}

/**
 * Sets transmit state to the edict and flag
 * @param myEntity        Edict index.
 */
stock void ShowTrigger(int myEntity)
{
	if (IsValidEdict(myEntity))
	{
		int EffectFlags = GetEntData(myEntity, Offset_for_entity_effect);
		int EdictFlags = GetEdictFlags(myEntity);
		if (myEntity != -1)
		{
			EffectFlags &= ~32; //EF_NODRAW flag (0x020)
			EdictFlags &= ~FL_EDICT_DONTSEND; //Transmit State - Don't ever transmit.

			SetEntData(myEntity, Offset_for_entity_effect, EffectFlags);
			ChangeEdictState(myEntity, Offset_for_entity_effect);
			SetEdictFlags(myEntity, EdictFlags);
		}
	}
	SDKHook(myEntity, SDKHook_SetTransmit, Func_SetTransmit);
}

/**
 * Sets transmit state to the edict and flag
 * @param myEntity        Edict index.
 */
stock void DisableTrigger(int myEntity)
{
	if (IsValidEdict(myEntity))
	{
		int EffectFlags = GetEntData(myEntity, Offset_for_entity_effect);
		int EdictFlags = GetEdictFlags(myEntity);
		if (myEntity != -1)
		{
			EffectFlags |= 32; //EF_NODRAW flag (0x020)
			EdictFlags |= FL_EDICT_DONTSEND; //Transmit State - Don't ever transmit.

			SetEntData(myEntity, Offset_for_entity_effect, EffectFlags);
			ChangeEdictState(myEntity, Offset_for_entity_effect);
			SetEdictFlags(myEntity, EdictFlags);
		}
	}
	SDKUnhook(myEntity, SDKHook_SetTransmit, Func_SetTransmit);
}