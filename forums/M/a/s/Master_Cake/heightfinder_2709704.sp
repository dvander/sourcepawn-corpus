#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION	"1.0.1"
#define SPRITE_BEAM	"materials/sprites/laser.vmt"

bool PL_Enabled;
bool BM_ENABLED[MAXPLAYERS + 1];
bool CJ_ENABLED[MAXPLAYERS + 1];

int Offset_for_entity_effect = -1;
int BrushEntityIndex[MAXPLAYERS + 1][1]; //Array of brush entities (trigger_teleport, func_nogrenades)
int sprite;
int halo;

float FL_VelClient[MAXPLAYERS + 1][3];

ConVar g_pluginEnabled;

Handle HudDisplay;

public Plugin:myinfo =
{
	name = "Height Finder",
	author = "Master Cake",
	description = "This plugin finds height",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("hfind_version", PLUGIN_VERSION, "Height Finder Version", FCVAR_REPLICATED | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_pluginEnabled = CreateConVar("hfind_enabled", "1", "Enable Height Finder\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	PL_Enabled = GetConVarBool(g_pluginEnabled);

	HookConVarChange(g_pluginEnabled, ConsoleVarChange);

	Offset_for_entity_effect = FindSendPropInfo("CBaseEntity", "m_fEffects"); //Find offset to "m_fEffects" property
	if (Offset_for_entity_effect == -1)
		SetFailState("m_fEffects property not found!");

	RegConsoleCmd("sm_findh", HC_Command, "Command to enable Height Finder");
	RegConsoleCmd("sm_checkjump", CJ_Command, "Command to enable jump checker");

	RegAdminCmd("sm_brushmode", BM_Command, ADMFLAG_GENERIC, "Command to enable/disable brush mode");
	RegAdminCmd("sm_nogrenades", NG_Command, ADMFLAG_GENERIC, "Command to show func_nogrenades brush entities");
	RegAdminCmd("sm_stopnogrenades", SNG_Command, ADMFLAG_GENERIC, "Command to stop showing func_nogrenades brush entities");
	RegAdminCmd("sm_teletriggers", TT_Command, ADMFLAG_GENERIC, "Command to show trigger_teleport brush entities");
	RegAdminCmd("sm_stopteletriggers", STT_Command, ADMFLAG_GENERIC, "Command to stop showing trigger_teleport brush entities");
	RegAdminCmd("sm_removent", RENT_Command, ADMFLAG_GENERIC, "Command to remove trigger_teleport and func_nogrenades brush entities");
	RegAdminCmd("sm_getentindex", GEI_Command, ADMFLAG_GENERIC, "Command to get trigger_teleport and func_nogrenades index");
	RegAdminCmd("sm_moventup", MEU_Command, ADMFLAG_GENERIC, "Command to move trigger_teleport and func_nogrenades brush entities up");
	RegAdminCmd("sm_moventdown", MED_Command, ADMFLAG_GENERIC, "Command to move trigger_teleport and func_nogrenades brush entities down");

	AutoExecConfig(true, "hfind");

	HudDisplay = CreateHudSynchronizer();
}

public OnMapStart()
{
	sprite = PrecacheModel(SPRITE_BEAM);
	halo = PrecacheModel(SPRITE_BEAM);
}

public ConsoleVarChange(Handle:CVar, const String:oldValue[], const String:newValue[])
{
	if(CVar == g_pluginEnabled)
	{
		PL_Enabled = GetConVarBool(g_pluginEnabled);
	}
}

public OnClientPutInServer(myClient)
{
	BM_ENABLED[myClient] = false;
	CJ_ENABLED[myClient] = false;
	BrushEntityIndex[myClient][0] = -1;
}

public int MenuHandler_func(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
    {
        delete menu;
    }
}

public Action:CJ_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (!CJ_ENABLED[myClient])
	{
    	CJ_ENABLED[myClient] = true;
    	ReplyToCommand(myClient, "[SM] Jump Check Enabled!");
    	return Plugin_Continue;
    }
	if (CJ_ENABLED[myClient])
    {
    	CJ_ENABLED[myClient] = false;
    	ReplyToCommand(myClient, "[SM] Jump Check Disabled!");
    }

	return Plugin_Handled;
}

public Action:BM_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (!BM_ENABLED[myClient])
	{
    	BM_ENABLED[myClient] = true;
    	ReplyToCommand(myClient, "[SM] Brush Mode Enabled!");
    	return Plugin_Continue;
    }
	if (BM_ENABLED[myClient])
    {
    	BM_ENABLED[myClient] = false;
    	ReplyToCommand(myClient, "[SM] Brush Mode Disabled!");
    }

	return Plugin_Handled;
}

public Action:RENT_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient) || !BM_ENABLED[myClient])
		return Plugin_Continue;

	int EntityCount = GetEntityCount();
	char myClassName[50];
	for (int myEntity = MaxClients + 1; myEntity <= EntityCount; ++myEntity)
	{
		if (IsValidEntity(myEntity))
		{
			GetEntityClassname(myEntity, myClassName, sizeof(myClassName));
			if (StrEqual(myClassName, "trigger_teleport") || StrEqual(myClassName, "func_nogrenades"))
			{
				RemoveEntity(myEntity);
			}
		}
	}

	return Plugin_Handled;
}

public Action:STT_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient) || !BM_ENABLED[myClient])
		return Plugin_Continue;

	int EntityCouunt = GetEntityCount();
	char myClassName[50];
	for (int myEntity = MaxClients + 1; myEntity <= EntityCouunt; ++myEntity)
	{
		if (IsValidEntity(myEntity))
		{
			GetEntityClassname(myEntity, myClassName, sizeof(myClassName));
			if (StrEqual(myClassName, "trigger_teleport"))
			{
				StopShowBrushEntity(myEntity);
			}
		}
	}

	return Plugin_Handled;
}

public Action:TT_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient) || !BM_ENABLED[myClient])
		return Plugin_Continue;

	int EntityCouunt = GetEntityCount();
	char myClassName[50];
	for (int myEntity = MaxClients + 1; myEntity <= EntityCouunt; ++myEntity)
	{
		if (IsValidEntity(myEntity))
		{
			GetEntityClassname(myEntity, myClassName, sizeof(myClassName));
			if (StrEqual(myClassName, "trigger_teleport"))
			{
				ShowBrushEntity(myEntity);
			}
		}
	}

	return Plugin_Handled;
}

public Action:NG_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient) || !BM_ENABLED[myClient])
		return Plugin_Continue;

	int EntityCouunt = GetEntityCount();
	char myClassName[50];
	for (int myEntity = MaxClients + 1; myEntity <= EntityCouunt; ++myEntity)
	{
		if (IsValidEntity(myEntity))
		{
			GetEntityClassname(myEntity, myClassName, sizeof(myClassName));
			if (StrEqual(myClassName, "func_nogrenades"))
			{
				ShowBrushEntity(myEntity);
			}
		}
	}

	return Plugin_Handled;
}

public Action:SNG_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient) || !BM_ENABLED[myClient])
		return Plugin_Continue;

	int EntityCouunt = GetEntityCount();
	char myClassName[50];
	for (int myEntity = MaxClients + 1; myEntity <= EntityCouunt; ++myEntity)
	{
		if (IsValidEntity(myEntity))
		{
			GetEntityClassname(myEntity, myClassName, sizeof(myClassName));
			if (StrEqual(myClassName, "func_nogrenades"))
			{
				StopShowBrushEntity(myEntity);
			}
		}
	}

	return Plugin_Handled;
}

public Action:MED_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient) || !BM_ENABLED[myClient])
		return Plugin_Continue;

	if (args != 2)
	{
    	ReplyToCommand(myClient, "Usage: sm_moventdown <index> <num of units>");
    	return Plugin_Handled;
	}

	char myArgs1[32];
	GetCmdArg(1, myArgs1, sizeof(myArgs1));
	int EntIndex = StringToInt(myArgs1);
	if (!IsValidEntity(EntIndex))
		return Plugin_Handled;
	char myArgs2[32];
	GetCmdArg(2, myArgs2, sizeof(myArgs2));
	int num = StringToInt(myArgs2);
	if (num > 999)
	{
		ReplyToCommand(myClient, "Invalid value");
		return Plugin_Handled;
	}
	else
	{
		float EntPos[3];
		char typent[32];
		GetEntityClassname(EntIndex, typent, sizeof(typent));
		if (StrEqual(typent, "func_nogrenades") || StrEqual(typent, "trigger_teleport"))
		{
			GetEntPropVector(EntIndex, Prop_Send, "m_vecOrigin", EntPos);
			if (num == 0)
			{
				EntPos[2] += num;
			}
			else
			{
				EntPos[2] -= num;
			}
			TeleportEntity(EntIndex, EntPos, NULL_VECTOR, NULL_VECTOR);
		}
	}

	return Plugin_Handled;
}

public Action:MEU_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient) || !BM_ENABLED[myClient])
		return Plugin_Continue;

	if (args != 2)
	{
    	ReplyToCommand(myClient, "Usage: sm_moventup <index> <num of units>");
    	return Plugin_Handled;
	}

	char myArgs1[32];
	GetCmdArg(1, myArgs1, sizeof(myArgs1));
	int EntIndex = StringToInt(myArgs1);
	if (!IsValidEntity(EntIndex))
		return Plugin_Handled;
	char myArgs2[32];
	GetCmdArg(2, myArgs2, sizeof(myArgs2));
	int num = StringToInt(myArgs2);
	if (num > 999)
	{
		ReplyToCommand(myClient, "Invalid value");
		return Plugin_Handled;
	}
	else
	{
		float EntPos[3];
		char typent[32];
		GetEntityClassname(EntIndex, typent, sizeof(typent));
		if (StrEqual(typent, "func_nogrenades") || StrEqual(typent, "trigger_teleport"))
		{
			GetEntPropVector(EntIndex, Prop_Send, "m_vecOrigin", EntPos);
			if (num == 0)
			{
				EntPos[2] += num;
			}
			else
			{
				EntPos[2] += num; //Anyway LOL
			}
			TeleportEntity(EntIndex, EntPos, NULL_VECTOR, NULL_VECTOR);
		}
	}

	return Plugin_Handled;
}

public Action:GEI_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient) || !BM_ENABLED[myClient])
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
			ReplyToCommand(myClient, "Entity Index: %i", BrushEntityIndex[myClient][0]);
	}
	delete myTrace;

	return Plugin_Handled;
}

public Action:HC_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	Menu menu = new Menu(MenuHandler_func);
	menu.SetTitle("Height Finder");

	static float FL_TargetPos[3];
	static float FL_PlayerPos[3];
	static float FL_PlayerAbsPos[3];
	static float FL_PlayerTempPos[3];
	static float FL_PlayerAng[3];
	static float FL_TargetVec[3];
	GetClientEyePosition(myClient, FL_PlayerPos);
	GetClientAbsOrigin(myClient, FL_PlayerAbsPos); //Abs Origin
	GetClientEyeAngles(myClient, FL_PlayerAng);
	Handle myTrace = TR_TraceRayFilterEx(FL_PlayerPos, FL_PlayerAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilterEntity);

 	if(TR_DidHit(myTrace))
	{
		TR_GetEndPosition(FL_TargetPos, myTrace);
		TR_EnumerateEntities(FL_PlayerPos, FL_TargetPos, PARTITION_TRIGGER_EDICTS, RayType_EndPoint, DetectTrigger, myClient);
	}
	delete myTrace;

	char distance[32];
	char detent[32];
	char typent[32];
	SubtractVectors(FL_TargetPos, FL_PlayerAbsPos, FL_TargetVec); //Distance to the ground
	Format(distance, sizeof(distance), "Target height:       %1.3f", FL_TargetVec[2]);
	if (BrushEntityIndex[myClient][0] != -1)
		Format(detent, sizeof(detent), "Brush entity:       YES");
	else
		Format(detent, sizeof(detent), "Brush entity:       NO");

	menu.AddItem("th", distance, ITEMDRAW_DISABLED);
	menu.AddItem("be", detent, ITEMDRAW_DISABLED);

	if (BrushEntityIndex[myClient][0] != -1)
	{
		GetEntityClassname(BrushEntityIndex[myClient][0], typent, sizeof(typent));
		if (StrEqual(typent, "func_nogrenades"))
			Format(typent, sizeof(typent), "First detected:       Nogrenade");
		if (StrEqual(typent, "trigger_teleport"))
			Format(typent, sizeof(typent), "First detected:       Teleport");
	}
	else
	{
		Format(typent, sizeof(typent), "First detected:       ---");
	}
	menu.AddItem("fd", typent, ITEMDRAW_DISABLED);
	menu.Display(myClient, 30);

	int color[4]; color[0] = 255; color[1] = 255; color[2] = 255; color[3] = 255;
	TE_SetupBeamPoints(FL_PlayerAbsPos, FL_TargetPos, sprite, halo, 0, 0, 7.0, 5.0, 5.0, 1, 0.0, color, 0);
	TE_SendToClient(myClient, 0.1);
	FL_PlayerTempPos = FL_PlayerAbsPos;
	FL_PlayerTempPos[2] = FL_TargetPos[2];
	TE_SetupBeamPoints(FL_TargetPos, FL_PlayerTempPos, sprite, halo, 0, 0, 7.0, 5.0, 5.0, 1, 0.0, color, 0);
	TE_SendToClient(myClient, 0.1);
	TE_SetupBeamPoints(FL_PlayerTempPos, FL_PlayerAbsPos, sprite, halo, 0, 0, 7.0, 5.0, 5.0, 1, 0.0, color, 0);
	TE_SendToClient(myClient, 0.1);

	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(myClient, &myButtons, &myImpulse, Float:myVel[3], Float:myAng[3], &myWeapon)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (CJ_ENABLED[myClient])
	{
		GetEntPropVector(myClient, Prop_Data, "m_vecAbsVelocity", FL_VelClient[myClient]);
		if (FL_VelClient[myClient][2] > 0.0)
		{
			static float FL_TargetPos[3];
			static float FL_PlayerPos[3];
			static float FL_PlayerAng[3]; FL_PlayerAng[0] = 90.0; FL_PlayerAng[1] = 0.0; FL_PlayerAng[2] = 0.0;
			static float FL_TargetVec[3];
			GetClientAbsOrigin(myClient, FL_PlayerPos);
			Handle myTrace = TR_TraceRayFilterEx(FL_PlayerPos, FL_PlayerAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilterEntity);

 			if(TR_DidHit(myTrace))
			{
				TR_GetEndPosition(FL_TargetPos, myTrace);
			}
			delete myTrace;

			SubtractVectors(FL_PlayerPos, FL_TargetPos, FL_TargetVec); //Distance to the ground
			ClearSyncHud(myClient, HudDisplay);
			SetHudTextParams(0.65, 0.55, 5.0, 255, 255, 255, 255, 0, 0.1, 0.1, 0.1);
			ShowSyncHudText(myClient, HudDisplay, "Your max height: %1.3f", FL_TargetVec[2]);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public bool TraceFilterEntity(int myEntity, int myMask)
{
	return (myEntity == 0 || myEntity > MaxClients); //0 - server console
}

public bool DetectTrigger(int myEntity, int myClient)
{
	char myClassName[50];
	GetEntityClassname(myEntity, myClassName, sizeof(myClassName));
	if (StrEqual(myClassName, "trigger_teleport") || StrEqual(myClassName, "func_nogrenades"))
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

public Action Func_SetTransmit(int entity, int myClient)
{
	if (!BM_ENABLED[myClient])
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
stock bool:IsValidClient(myClient, bool:Replay = true)
{
  if(myClient <= 0 || myClient > MaxClients || !IsClientInGame(myClient))
    return false;
  if(Replay && (IsClientSourceTV(myClient) || IsClientReplay(myClient) || IsClientObserver(myClient)))
    return false;
  return true;
}

/**
 * Sets transmit state to the edict and flag (shows brush entity - func_nogrenades, trigger_teleport)
 * @param myEntity        Entity index.
 */
stock void ShowBrushEntity(int myEntity)
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
 * Sets transmit state to the edict and flag (stops showing brush entities - func_nogrenades, trigger_teleport)
 * @param myEntity        Entity index.
 */
stock void StopShowBrushEntity(int myEntity)
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