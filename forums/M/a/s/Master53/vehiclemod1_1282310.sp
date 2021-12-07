#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1"

new Handle:hGameCfg;
new Handle:hLeaveVehicle;

public Plugin:myinfo =
{
	name = "Vehicle Mod",
	author = "Blodia",
	description = "Allows you to drive vehicles",
	version = "0.1",
	url = ""
}

public OnPluginStart()
{
	CreateConVar("vehiclemod_version", PLUGIN_VERSION, "Vehicle Mod version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	RegServerCmd("vehiclemod_spawnatuserid1", SpawnVehicleUserId, "Spawns a vehicle in front of a player by userid. Usage vehiclemod_spawnatuserid <userid>)");

	hGameCfg = LoadGameConfigFile("vehiclemod.games");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameCfg, SDKConf_Virtual, "LeaveVehicle");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	hLeaveVehicle = EndPrepSDKCall();
	
	HookEvent("player_spawn", Event_PlayerSpawnPre, EventHookMode_Pre);
	
	for (new client = 1; client <= MaxClients; client++) 
	{ 
        if (IsClientInGame(client)) 
        {
			SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
		}
	}
}

public OnMapStart()
{
	AddFileToDownloadsTable("models/contron/combapc.phy");
	AddFileToDownloadsTable("models/contron/combapc.mdl");
	AddFileToDownloadsTable("models/contron/combapc.sw.vtx");
	AddFileToDownloadsTable("models/contron/combapc.dx80.vtx");
	AddFileToDownloadsTable("models/contron/combapc.dx90.vtx");
	AddFileToDownloadsTable("models/contron/combapc.vvd");
	
	
	PrecacheModel("models/contron/combapc.mdl");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public Action:SpawnVehicleUserId(args)
{
	if (GetCmdArgs() != 1)
	{
		PrintToServer("********** vehiclemod: must be 1 argument - <userid>");
		return Plugin_Handled;
	}
	
	new String:Arg[10];
	GetCmdArg(1, Arg, sizeof(Arg));
	
	new userid = StringToInt(Arg);
	new client = GetClientOfUserId(userid);
	
	if ((client == 0) || (client > MaxClients))
	{
		PrintToServer("********** vehiclemod: no valid userindex found from userid");
		return Plugin_Handled;
	}
	
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:EyeAng[3];
		GetClientEyeAngles(client, EyeAng);
		new Float:ForwardVec[3];
		GetAngleVectors(EyeAng, ForwardVec, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(ForwardVec, 100.0);
		ForwardVec[2] = 0.0;
		new Float:EyePos[3];
		GetClientEyePosition(client, EyePos);
		new Float:AbsAngle[3];
		GetClientAbsAngles(client, AbsAngle);
		
		new Float:SpawnAngles[3];
		SpawnAngles[1] = EyeAng[1];
		new Float:SpawnOrigin[3];
		AddVectors(EyePos, ForwardVec, SpawnOrigin);
		
		SpawnVehicle(SpawnOrigin, SpawnAngles);
	}
	else
	{
		PrintToServer("********** vehiclemod: client is not in game or is dead");
	}
	
	return Plugin_Handled;
}

SpawnVehicle(Float:SpawnOrigin[3], Float:SpawnAngles[3])
{
	new VehicleIndex = CreateEntityByName("prop_vehicle_driveable");
	if (VehicleIndex != -1)
	{
		DispatchKeyValue(VehicleIndex, "model", "models/contron/combapc.mdl");
		DispatchKeyValue(VehicleIndex, "vehiclescript", "scripts/vehicles/fixed_apc.txt");
		DispatchKeyValue(VehicleIndex, "solid", "6");
		
		DispatchSpawn(VehicleIndex);
		ActivateEntity(VehicleIndex);
		
		//SetEntityModel(VehicleIndex, "models/contron/combapc.mdl");
		
		TeleportEntity(VehicleIndex, SpawnOrigin, SpawnAngles, NULL_VECTOR);
		
		SetEntProp(VehicleIndex, Prop_Data, "m_nNextThinkTick", -1);
		
		SDKHook(VehicleIndex, SDKHook_ThinkPost, OnThinkPost); 
	}
}

public OnThinkPost(entity)
{
	if (GetEntProp(entity, Prop_Send, "m_bEnterAnimOn") == 1)
	{
		SetEntProp(entity, Prop_Send, "m_bEnterAnimOn", 0);
		SetEntProp(entity, Prop_Send, "m_nSequence", 0);
		AcceptEntityInput(entity, "TurnOn");
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static bool:PressingUse[MAXPLAYERS + 1];
	
	if (buttons & IN_USE)
	{
		if (!PressingUse[client])
		{
			if (GetEntPropEnt(client, Prop_Send, "m_hVehicle") != -1)
			{
				LeaveVehicle(client);
				return Plugin_Handled;
			}
		}
		PressingUse[client] = true;
	}
	else
	{
		PressingUse[client] = false;
	}
	
	return Plugin_Continue;
}

public OnEntityDestroyed(entity)
{
	new String:ClassName[30];
	GetEdictClassname(entity, ClassName, sizeof(ClassName));
	if (StrEqual("prop_vehicle_driveable", ClassName, false))
	{
		new Driver = GetEntPropEnt(entity, Prop_Send, "m_hPlayer");
		if (Driver != -1)
		{
			LeaveVehicle(Driver);
		}
	}
}

public Action:Event_PlayerSpawnPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);
	
	if (GetEntPropEnt(client, Prop_Send, "m_hVehicle") != -1)
	{
		LeaveVehicle(client);
	}
	
	return Plugin_Continue;
}

LeaveVehicle(client)
{
	new Float:Null[3] = {0.0, 0.0, 0.0};
	new Float:ExitAng[3];
	
	new vehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	GetEntPropVector(vehicle, Prop_Data, "m_angRotation", ExitAng);
	ExitAng[0] = 0.0;
	ExitAng[1] += 90.0;
	ExitAng[2] = 0.0;
	
	SDKCall(hLeaveVehicle, client, Null, Null);
	
	TeleportEntity(client, NULL_VECTOR, ExitAng, NULL_VECTOR);
}

public Action:OnWeaponDrop(client, weapon)
{
	if (GetEntPropEnt(client, Prop_Send, "m_hVehicle") != -1)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}