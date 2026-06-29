#pragma semicolon 1

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

public Plugin:myinfo =
{
	name = "Wall Pogo Assistant",
	author = "Master Cake",
	description = "This plugin helps jumpers to learn Wall Pogo",
	version = PLUGIN_VERSION,
	url = ""
};

/**
 * Called when the plugin is fully initialized and all known external references are resolved
 */
public OnPluginStart()
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

/**
 * Called when a console variable's value is changed
 */
public ConsoleVarChange(Handle:CVar, const String:oldValue[], const String:newValue[])
{
	if(CVar == g_pluginEnabled)
	{
		PL_Enabled = GetConVarBool(g_pluginEnabled);
	}
}

/**
 * Called when the plugin is fully initialized and all known external references are resolved
 * @param myClient - Client index
 */
public OnClientPutInServer(myClient)
{
	WP_ENABLED[myClient] = false;
	FOL_ENABLED[myClient] = false;
	BrushEntityIndex[myClient][0] = -1;
}

/**
 * Enables Wall Pogo Assistant for client
 * @param myClient - Client index
 * @param args - Number of arguments that were in the argument string
 * @return - Action
 */
public Action:WP_Command(myClient, args)
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

/**
 * Enables trigger teleport displaying
 * @param myClient - Client index
 * @param args - Number of arguments that were in the argument string
 * @return - Action
 */
public Action:TR_Command(myClient, args)
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

/**
 * Disables trigger teleport displaying
 * @param myClient - Client index
 * @param args - Number of arguments that were in the argument string
 * @return - Action
 */
public Action:DITR_Command(myClient, args)
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

/**
 * Enables Follow Rockets Mode for client
 * @param myClient - Client index
 * @param args - Number of arguments that were in the argument string
 * @return - Action
 */
public Action:FOL_Command(myClient, args)
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

/**
 * Enables Follow Rockets Mode for specified client
 * @param myClient - Client index
 * @param args - Number of arguments that were in the argument string
 * @return - Action
 */
public Action:SETFOL_Command(myClient, args)
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
	new bool:flag = bool:StringToInt(myArgs2);

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

/**
 * Called when a clients movement buttons are being processed
 * @param myClient - Client index
 * @param myButtons - Copyback buffer containing the current commands
 * @param myImpulse - Copyback buffer containing the current impulse command
 * @param myVel - Players desired velocity
 * @param myAng - Players desired view angles
 * @param myWeapon - Entity index of the new weapon if player switches weapon, 0 otherwise
 * @return - Action
 */
public Action:OnPlayerRunCmd(myClient, &myButtons, &myImpulse, Float:myVel[3], Float:myAng[3], &myWeapon)
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

/**
 * Creates the hook when entity is created
 * @param myEntity - Entity index for which function creates the hook
 * @param MyName - Class name
 */
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

/**
 * Creates the timer when entity (rocket) is released
 * @param myEntity - Entity index for which function creates the beam
 * @return - Action
 */
public Action:RockSpawn(int myEntity)
{
	new myRef = EntIndexToEntRef(myEntity); //Converts an entity index into a serial encoded entity reference.
	static PrevRef = -1;

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

/**
 * Changes velocity, rotation and abs vectors for the given entity
 * @param myEntity - Entity index for which function changes vectors
 * @return - Action
 */
public Action:rocketCheck(Handle timer, int myEntity)
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

/**
 * Returns false if trigger teleport is detected, true otherwise
 * @param myEntity - Entity index to check if this is teleport trigger
 * @param myClient - Client index
 * @return - False if trigger teleport is detected, true otherwise
 */
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

/**
 * Filters the entity
 * @param myEntity - Entity index for filtering
 * @param MyName - Mask for filtering
 * @param myData - Data for filtering
 * @return - True to allow the current entity to be hit, otherwise false
 */
public bool TraceFilterEntity(int myEntity, int myMask)
{
	return (myEntity == 0 || myEntity > MaxClients); //0 - server console
}

/**
 * Filters the entity
 * @param myEntity - Entity index for filtering
 * @param MyName - Mask for filtering
 * @param myData - Data for filtering
 * @return - True to allow the current entity to be hit, otherwise false
 */
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

/**
 * Disables trigger_teleport transmit to the client
 * @param entity - Entity index
 * @param myClient - Client index
 * @return - Action
 */
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
 * Returns false if client is invalid, true otherwie
 * @param myClient - Client index
 * @param Replay - Logical bool parameter
 * @return - False if client is invalid, true otherwie
 */
stock bool:IsValidClient(myClient, bool:Replay = true)
{
  if(myClient <= 0 || myClient > MaxClients || !IsClientInGame(myClient))
    return false;
  if(Replay && (IsClientSourceTV(myClient) || IsClientReplay(myClient) || IsClientObserver(myClient)))
    return false;
  return true;
}

/**
 * Gets position vector where client looks
 * @param myClient - Client index
 * @param FL_TargetPos - Output buffer that stores received vector
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
 * Enables brush entity displaying (sets edict flags and changes edict state)
 * @param myEntity - Entity index to display
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
 * Disables brush entity displaying by its index (sets edict flags and changes edict state)
 * @param myEntity - Entity index
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