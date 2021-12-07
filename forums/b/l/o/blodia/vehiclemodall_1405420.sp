#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "0.75a"

#define DAMAGE_NO 0
#define DAMAGE_YES 2

#define VEHICLE_TYPE_AIRBOAT_RAYCAST 8

#define SOLID_VPHYSICS 6

#define COLLISION_GROUP_PLAYER 5
#define COLLISION_GROUP_IN_VEHICLE 10

#define EF_NODRAW 32

#define HIDEHUD_WEAPONSELECTION 1
#define HIDEHUD_CROSSHAIR 256
#define HIDEHUD_INVEHICLE 1024

new Handle:hBreakable;
new Handle:hHealth;
new Handle:hBlockExit;

new Handle:VehicleKV;

new IsBreakable;
new VehicleHealth;
new BlockExit;

new Float:null[3] = {0.0, 0.0, 0.0};

new InVehicle[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Vehicle Mod",
	author = "Blodia",
	description = "Allows you to drive vehicles",
	version = "0.75a",
	url = ""
}

public OnPluginStart()
{
	CreateConVar("vehiclemod_version", PLUGIN_VERSION, "Vehicle Mod version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	RegServerCmd("vehiclemod_spawnatuserid", SpawnVehicleUserId, "Spawns a vehicle at a players coordinates by userid and force them in. Usage vehiclemod_spawnatuserid <userid> <vehicle name> <skin>[optional])");
	RegServerCmd("vehiclemod_spawnatcoords", SpawnVehicleCoords, "Spawns a vehicle at a set of coordinates. Usage vehiclemod_spawnatcoords <x coord> <y coord> <z coord> <yaw angle> <vehicle name> <skin>[optional])");
	
	hBreakable = CreateConVar("vehiclemod_breakable", "0", "0 make vehicles unbreakable and 1 makes them breakable", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	hHealth = CreateConVar("vehiclemod_health", "200", "how much health breakable vehicles have", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 1.0, true, 10000.0);
	hBlockExit = CreateConVar("vehiclemod_blockexit", "0", "0 lets players exit vehicles at will and 1 locks them in once they enter", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	
	IsBreakable = GetConVarInt(hBreakable);
	VehicleHealth = GetConVarInt(hHealth);
	BlockExit = GetConVarInt(hBlockExit);
	
	HookConVarChange(hBreakable, ConVarChange);
	HookConVarChange(hHealth, ConVarChange);
	HookConVarChange(hBlockExit, ConVarChange);
	
	HookEvent("round_end", Event_RoundEndPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	
	VehicleKV = CreateKeyValues("VehicleDatabase");
	FileToKeyValues(VehicleKV, "cfg/vehiclelist.cfg");
	
	for (new client = 1; client <= MaxClients; client++) 
	{ 
        if (IsClientInGame(client)) 
        {
			SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
			SDKHook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
			SDKHook(client, SDKHook_WeaponSwitch, OnWeaponStuff);
			SDKHook(client, SDKHook_WeaponDrop, OnWeaponStuff);
        } 
    }
}

public OnPluginEnd()
{
	CloseHandle(VehicleKV);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	SDKHook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponStuff);
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponStuff);
}

public ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == hBreakable)
	{
		IsBreakable = StringToInt(newVal);
	}
	
	else if (cvar == hHealth)
	{
		VehicleHealth = StringToInt(newVal);
	}
	
	else if (cvar == hBlockExit)
	{
		BlockExit = StringToInt(newVal);
	}
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		if (InVehicle[client])
		{
			ExitVehicle(client, InVehicle[client], 1);
		}
	}
}

public OnMapStart()
{
	AddFileToDownloadsTable("models/blodia/buggy.dx80.vtx");
	AddFileToDownloadsTable("models/blodia/buggy.dx90.vtx");
	AddFileToDownloadsTable("models/blodia/buggy.mdl");
	AddFileToDownloadsTable("models/blodia/buggy.phy");
	AddFileToDownloadsTable("models/blodia/buggy.sw.vtx");
	AddFileToDownloadsTable("models/blodia/buggy.vvd");
	
	AddFileToDownloadsTable("models/blodia/airboat.dx80.vtx");
	AddFileToDownloadsTable("models/blodia/airboat.dx90.vtx");
	AddFileToDownloadsTable("models/blodia/airboat.mdl");
	AddFileToDownloadsTable("models/blodia/airboat.phy");
	AddFileToDownloadsTable("models/blodia/airboat.sw.vtx");
	AddFileToDownloadsTable("models/blodia/airboat.vvd");
	
	AddFileToDownloadsTable("materials/models/buggy/ammo_box.vmt");
	AddFileToDownloadsTable("materials/models/buggy/ammo_box.vtf");
	AddFileToDownloadsTable("materials/models/buggy/buggy001.vmt");
	AddFileToDownloadsTable("materials/models/buggy/buggy001.vtf");
	
	AddFileToDownloadsTable("materials/models/airboat/Airboat001.vmt");
	AddFileToDownloadsTable("materials/models/airboat/Airboat001.vtf");
	AddFileToDownloadsTable("materials/models/airboat/airboat_blur02.vmt");
	AddFileToDownloadsTable("materials/models/airboat/airboat_blur02.vtf");
	
	AddFileToDownloadsTable("sound/vehicles/v8/first.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/fourth_cruise_loop2.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/second.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/skid_highfriction.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/skid_lowfriction.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/skid_normalfriction.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/third.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/v8_firstgear_rev_loop1.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/v8_idle_loop1.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/v8_rev_short_loop1.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/v8_start_loop1.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/v8_stop1.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/v8_throttle_off_fast_loop1.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/v8_throttle_off_slow_loop2.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/v8_turbo_on_loop1.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/vehicle_impact_heavy1.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/vehicle_impact_heavy2.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/vehicle_impact_heavy3.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/vehicle_impact_heavy4.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/vehicle_impact_medium1.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/vehicle_impact_medium2.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/vehicle_impact_medium3.wav");
	AddFileToDownloadsTable("sound/vehicles/v8/vehicle_impact_medium4.wav");
	AddFileToDownloadsTable("sound/vehicles/jetski/jetski_no_gas_start.wav");
	AddFileToDownloadsTable("sound/vehicles/jetski/jetski_off.wav");
	
	AddFileToDownloadsTable("sound/vehicles/airboat/fan_motor_fullthrottle_loop1.wav");
	AddFileToDownloadsTable("sound/vehicles/airboat/fan_motor_idle_loop1.wav");
	AddFileToDownloadsTable("sound/vehicles/airboat/fan_motor_shut_off1.wav");
	AddFileToDownloadsTable("sound/vehicles/airboat/fan_motor_start1.wav");
	AddFileToDownloadsTable("sound/vehicles/airboat/pontoon_scrape_rough1.wav");
	AddFileToDownloadsTable("sound/vehicles/airboat/pontoon_scrape_rough2.wav");
	AddFileToDownloadsTable("sound/vehicles/airboat/pontoon_scrape_rough3.wav");
	AddFileToDownloadsTable("sound/vehicles/airboat/pontoon_scrape_smooth1.wav");
	AddFileToDownloadsTable("sound/vehicles/airboat/pontoon_scrape_smooth2.wav");
	AddFileToDownloadsTable("sound/vehicles/airboat/pontoon_scrape_smooth3.wav");
	
	PrecacheSound("vehicles/v8/first.wav");
	PrecacheSound("vehicles/v8/fourth_cruise_loop2.wav");
	PrecacheSound("vehicles/v8/second.wav");
	PrecacheSound("vehicles/v8/skid_highfriction.wav");
	PrecacheSound("vehicles/v8/skid_lowfriction.wav");
	PrecacheSound("vehicles/v8/skid_normalfriction.wav");
	PrecacheSound("vehicles/v8/third.wav");
	PrecacheSound("vehicles/v8/v8_firstgear_rev_loop1.wav");
	PrecacheSound("vehicles/v8/v8_idle_loop1.wav");
	PrecacheSound("vehicles/v8/v8_rev_short_loop1.wav");
	PrecacheSound("vehicles/v8/v8_start_loop1.wav");
	PrecacheSound("vehicles/v8/v8_stop1.wav");
	PrecacheSound("vehicles/v8/v8_throttle_off_fast_loop1.wav");
	PrecacheSound("vehicles/v8/v8_throttle_off_slow_loop2.wav");
	PrecacheSound("vehicles/v8/v8_turbo_on_loop1.wav");
	PrecacheSound("vehicles/v8/vehicle_impact_heavy1.wav");
	PrecacheSound("vehicles/v8/vehicle_impact_heavy2.wav");
	PrecacheSound("vehicles/v8/vehicle_impact_heavy3.wav");
	PrecacheSound("vehicles/v8/vehicle_impact_heavy4.wav");
	PrecacheSound("vehicles/v8/vehicle_impact_medium1.wav");
	PrecacheSound("vehicles/v8/vehicle_impact_medium2.wav");
	PrecacheSound("vehicles/v8/vehicle_impact_medium3.wav");
	PrecacheSound("vehicles/v8/vehicle_impact_medium4.wav");
	PrecacheSound("vehicles/v8/vehicle_rollover1.wav");
	PrecacheSound("vehicles/v8/vehicle_rollover2.wav");
	PrecacheSound("vehicles/jetski/jetski_no_gas_start.wav");
	PrecacheSound("vehicles/jetski/jetski_off.wav");
	
	PrecacheSound("vehicles/airboat/fan_motor_fullthrottle_loop1.wav");
	PrecacheSound("vehicles/airboat/fan_motor_idle_loop1.wav");
	PrecacheSound("vehicles/airboat/fan_motor_shut_off1.wav");
	PrecacheSound("vehicles/airboat/fan_motor_start1.wav");
	PrecacheSound("vehicles/airboat/pontoon_scrape_rough1.wav");
	PrecacheSound("vehicles/airboat/pontoon_scrape_rough2.wav");
	PrecacheSound("vehicles/airboat/pontoon_scrape_rough3.wav");
	PrecacheSound("vehicles/airboat/pontoon_scrape_smooth1.wav");
	PrecacheSound("vehicles/airboat/pontoon_scrape_smooth2.wav");
	PrecacheSound("vehicles/airboat/pontoon_scrape_smooth3.wav");
	
	KvRewind(VehicleKV);
	
	KvGotoFirstSubKey(VehicleKV);
	
	new String:ModelPath[255];
	
	do
	{
		KvGetString(VehicleKV, "model", ModelPath, sizeof(ModelPath));
		PrecacheModel(ModelPath);
	}
	while (KvGotoNextKey(VehicleKV));
}

public Action:SpawnVehicleUserId(args)
{
	if ((GetCmdArgs() != 3) && (GetCmdArgs() != 2))
	{
		PrintToServer("********** vehiclemod: must be 2 or 3 arguments - <userid> <vehicle name> <skin>[optional]");
		return Plugin_Handled;
	}
	
	new String:Arg1[10];
	GetCmdArg(1, Arg1, sizeof(Arg1));
	
	new String:Arg2[20];
	GetCmdArg(2, Arg2, sizeof(Arg2));
	
	new Skin;
	if (GetCmdArgs() == 3)
	{
		new String:Arg3[10];
		GetCmdArg(3, Arg3, sizeof(Arg3));
		
		Skin = StringToInt(Arg3);
	}
	
	new userid = StringToInt(Arg1);
	new client = GetClientOfUserId(userid);
	
	if ((client == 0) || (client > MaxClients))
	{
		PrintToServer("********** vehiclemod: no valid userindex found from userid");
		return Plugin_Handled;
	}
	
	if (InVehicle[client])
	{
		PrintToServer("********** vehiclemod: client is already in a vehicle");
		return Plugin_Handled;
	}
	
	new String:ModelPath[255];
	new String:ScriptPath[255];
	
	KvRewind(VehicleKV);
	
	if (!KvJumpToKey(VehicleKV, Arg2))
	{
		PrintToServer("********** vehiclemod: vehicle not found");
		return Plugin_Handled;
	}
	
	KvGetString(VehicleKV, "model", ModelPath, sizeof(ModelPath));
	KvGetString(VehicleKV, "vehiclescript", ScriptPath, sizeof(ScriptPath));
	
	if ((Skin < 0) || (Skin > 20))
	{
		PrintToServer("********** vehiclemod: skin value must be an integer between 0 and 20");
		return Plugin_Handled;
	}
	
	new VehicleType = KvGetNum(VehicleKV, "vehicletype");
	
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:EyeAng[3];
		GetClientEyeAngles(client, EyeAng);
		
		new Float:SpawnAngles[3];
		SpawnAngles[1] = EyeAng[1] - 90.0;
		new Float:SpawnOrigin[3];
		GetClientEyePosition(client, SpawnOrigin);
		
		SpawnVehicle(SpawnOrigin, SpawnAngles, ModelPath, ScriptPath, Skin, VehicleType, client);
	}
	else
	{
		PrintToServer("********** vehiclemod: client is not in game or is dead");
	}
	
	return Plugin_Handled;
}

public Action:SpawnVehicleCoords(args)
{
	if ((GetCmdArgs() != 6) && (GetCmdArgs() != 5))
	{
		PrintToServer("********** vehiclemod: must be 5 or 6 arguments - <x coord> <y coord> <z coord> <yaw angle> <vehicle name> <skin>[optional]");
		return Plugin_Handled;
	}
	
	new String:Arg1[10];
	GetCmdArg(1, Arg1, sizeof(Arg1));
	
	new String:Arg2[10];
	GetCmdArg(2, Arg2, sizeof(Arg2));
	
	new String:Arg3[10];
	GetCmdArg(3, Arg3, sizeof(Arg3));
	
	new String:Arg4[10];
	GetCmdArg(4, Arg4, sizeof(Arg4));
	
	new String:Arg5[20];
	GetCmdArg(5, Arg5, sizeof(Arg5));
	
	new Skin;
	if (GetCmdArgs() == 6)
	{
		new String:Arg6[10];
		GetCmdArg(6, Arg6, sizeof(Arg6));
		
		Skin = StringToInt(Arg6);
	}
	
	new Float:SpawnOrigin[3];
	SpawnOrigin[0] = StringToFloat(Arg1);
	SpawnOrigin[1] = StringToFloat(Arg2);
	SpawnOrigin[2] = StringToFloat(Arg3);
	
	new Float:SpawnAngles[3];
	SpawnAngles[1] = StringToFloat(Arg4) -90.0;
	
	new String:ModelPath[255];
	new String:ScriptPath[255];
	
	KvRewind(VehicleKV);
	
	if (!KvJumpToKey(VehicleKV, Arg5))
	{
		PrintToServer("********** vehiclemod: vehicle not found");
		return Plugin_Handled;
	}
	
	KvGetString(VehicleKV, "model", ModelPath, sizeof(ModelPath));
	KvGetString(VehicleKV, "vehiclescript", ScriptPath, sizeof(ScriptPath));
	
	if ((Skin < 0) || (Skin > 20))
	{
		PrintToServer("********** vehiclemod: skin value must be an integer between 0 and 20");
		return Plugin_Handled;
	}
	
	new VehicleType = KvGetNum(VehicleKV, "vehicletype");
	
	SpawnVehicle(SpawnOrigin, SpawnAngles, ModelPath, ScriptPath, Skin, VehicleType);
	
	return Plugin_Handled;
}

SpawnVehicle(Float:spawnorigin[3], Float:spawnangles[3], const String:model[], const String:script[], skin, vehicletype, client=0)
{
	new VehicleIndex = CreateEntityByName("prop_vehicle");
	if (VehicleIndex == -1)
	{
		PrintToServer("********** vehiclemod: could not create vehicle entity");
		return;
	}
	
	new String:TargetName[10];
	Format(TargetName, sizeof(TargetName), "%i",VehicleIndex);
	DispatchKeyValue(VehicleIndex, "targetname", TargetName);
	
	DispatchKeyValue(VehicleIndex, "model", model);
	DispatchKeyValue(VehicleIndex, "vehiclescript", script);
	DispatchKeyValue(VehicleIndex, "spawnflags", "1");
	
	SetEntProp(VehicleIndex, Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
	SetEntProp(VehicleIndex, Prop_Send, "m_nSkin", skin);
	
	if (vehicletype)
	{
		SetEntProp(VehicleIndex, Prop_Data, "m_nVehicleType", VEHICLE_TYPE_AIRBOAT_RAYCAST);
	}
	
	if (StrEqual("models/blodia/airboat.mdl", model, false))
	{
		SetEntProp(VehicleIndex, Prop_Send, "m_nBody", 6);
	}
	
	DispatchSpawn(VehicleIndex);
	ActivateEntity(VehicleIndex);
	
	SDKHook(VehicleIndex, SDKHook_OnTakeDamage, OnVehicleTakeDamage);
	
	new PhysIndex = CreateEntityByName("phys_ragdollconstraint");
	
	if (PhysIndex == -1)
	{
		AcceptEntityInput(VehicleIndex, "Kill");
		
		PrintToServer("********** vehiclemod: could not create anti flip entity");
		return;
	}
	
	DispatchKeyValue(PhysIndex, "spawnflags", "2");
	DispatchKeyValue(PhysIndex, "xmin", "-100.0");
	DispatchKeyValue(PhysIndex, "xmax", "100.0");
	DispatchKeyValue(PhysIndex, "ymin", "-100.0");
	DispatchKeyValue(PhysIndex, "ymax", "100.0");
	DispatchKeyValue(PhysIndex, "zmin", "-180.0");
	DispatchKeyValue(PhysIndex, "zmax", "180.0");
	
	DispatchKeyValue(PhysIndex, "attach1", TargetName);
	
	DispatchSpawn(PhysIndex);
	ActivateEntity(PhysIndex);
	
	SetVariantString(TargetName);
	AcceptEntityInput(PhysIndex, "SetParent");
	
	TeleportEntity(PhysIndex, null, NULL_VECTOR, NULL_VECTOR);
	
	new Float:MinHull[3];
	new Float:MaxHull[3];
	GetEntPropVector(VehicleIndex, Prop_Send, "m_vecMins", MinHull);
	GetEntPropVector(VehicleIndex, Prop_Send, "m_vecMaxs", MaxHull);
	
	new Float:temp;
	
	temp = MinHull[0];
	MinHull[0] = MinHull[1];
	MinHull[1] = temp;
	
	temp = MaxHull[0];
	MaxHull[0] = MaxHull[1];
	MaxHull[1] = temp;
	
	if (client == 0)
	{
		TR_TraceHull(spawnorigin, spawnorigin, MinHull, MaxHull, MASK_SOLID);
	}
	else
	{
		TR_TraceHullFilter(spawnorigin, spawnorigin, MinHull, MaxHull, MASK_SOLID, RayDontHitClient, client);
	}
	
	if (TR_DidHit())
	{
		AcceptEntityInput(VehicleIndex, "Kill");
		
		PrintToServer("********** vehiclemod: spawn coordinates not clear");
		return;
	}
	
	TeleportEntity(VehicleIndex, spawnorigin, spawnangles, NULL_VECTOR);
	
	if (IsBreakable)
	{
		SetEntProp(VehicleIndex, Prop_Data, "m_takedamage", DAMAGE_YES);
		SetEntProp(VehicleIndex, Prop_Data, "m_iHealth", VehicleHealth);
	}
	else
	{
		SetEntProp(VehicleIndex, Prop_Data, "m_takedamage", DAMAGE_NO);
	}
	
	if (client != 0)
	{
		EnterVehicle(client, VehicleIndex);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static OldButtons[MAXPLAYERS + 1];
	
	if (!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	if (!InVehicle[client])
	{
		if (!(OldButtons[client] & IN_USE) && (buttons & IN_USE))
		{
			decl Float:clientAng[3];
			GetClientEyeAngles(client, clientAng);
			decl Float:clientPos[3];
			GetClientEyePosition(client, clientPos);
			TR_TraceRayFilter(clientPos, clientAng, MASK_SOLID, RayType_Infinite, RayDontHitClient, client);
			
			new vehicle = TR_GetEntityIndex ();
			
			if (vehicle != -1)
			{
				new String:ClassName[30];
				GetEdictClassname(vehicle, ClassName, sizeof(ClassName));
				if (StrEqual("prop_vehicle", ClassName, false))
				{
					new Driver = GetEntProp(vehicle, Prop_Data, "m_iMaxHealth");
					
					if (!Driver)
					{
						decl Float:tracehit[3];
						TR_GetEndPosition(tracehit);
						if (GetVectorDistance(clientPos, tracehit) <= 100.0)
						{
							if (!(buttons & IN_DUCK))
							{
								EnterVehicle(client, vehicle);
							}
							else
							{
								PrintToChat(client, "\x04[VehicleMod]\x05 You can't enter vehicles while crouching");
							}
						}
					}
				}
			}
		}
	}
	
	else
	{
		new String:Model[255];
		
		GetEntPropString(InVehicle[client], Prop_Data, "m_ModelName", Model, sizeof(Model));
		
		if (StrEqual("models/blodia/airboat.mdl", Model, false))
		{
			new PoseOffset = FindSendPropOffs("CBaseAnimating", "m_flPoseParameter");
			
			new Float:Pose = GetEntDataFloat(InVehicle[client], PoseOffset + 24);
			
			Pose -= 0.1;
			if (Pose <= 0.0)
			{
				Pose += 1.0;
			}
			
			SetEntDataFloat(InVehicle[client], PoseOffset + 24, Pose);
			SetEntDataFloat(InVehicle[client], PoseOffset + 28, Pose / 10.0);
		}
		
		if (buttons & IN_MOVELEFT)
		{
			SetVariantFloat(-1.0);
			AcceptEntityInput(InVehicle[client], "Steer");
		}
		
		else if (buttons & IN_MOVERIGHT)
		{
			SetVariantFloat(1.0);
			AcceptEntityInput(InVehicle[client], "Steer");
		}
		
		else
		{
			SetVariantInt(0);
			AcceptEntityInput(InVehicle[client], "Steer");
			SetVariantInt(0);
			AcceptEntityInput(InVehicle[client], "Steer");
			SetVariantInt(0);
			AcceptEntityInput(InVehicle[client], "Steer");
			SetVariantInt(0);
			AcceptEntityInput(InVehicle[client], "Steer");
			SetVariantInt(0);
			AcceptEntityInput(InVehicle[client], "Steer");
			SetVariantInt(0);
			AcceptEntityInput(InVehicle[client], "Steer");
		}
		
		if (buttons & IN_BACK)
		{
			SetVariantFloat(-1.0);
			AcceptEntityInput(InVehicle[client], "Throttle");
		}
		
		else if (buttons & IN_FORWARD)
		{
			SetVariantFloat(1.5);
			AcceptEntityInput(InVehicle[client], "Throttle");
		}
		
		else
		{
			SetVariantInt(0);
			AcceptEntityInput(InVehicle[client], "Throttle");
		}
		
		if (!(OldButtons[client] & IN_BACK) && (buttons & IN_BACK))
		{
			if (StrEqual("models/blodia/airboat.mdl", Model, false))
			{
				EmitSoundToAll("vehicles/airboat/fan_motor_fullthrottle_loop1.wav", InVehicle[client], SNDCHAN_STATIC, SNDLEVEL_MINIBIKE);
			}
			else
			{
				EmitSoundToAll("vehicles/v8/first.wav", InVehicle[client], SNDCHAN_STATIC, SNDLEVEL_MINIBIKE);
			}
		}
		
		else if ((OldButtons[client] & IN_BACK) && !(buttons & IN_BACK))
		{
			if (StrEqual("models/blodia/airboat.mdl", Model, false))
			{
				StopSound(InVehicle[client], SNDCHAN_STATIC, "vehicles/airboat/fan_motor_fullthrottle_loop1.wav");
			}
			else
			{
				StopSound(InVehicle[client], SNDCHAN_STATIC, "vehicles/v8/first.wav");
			}
		}
		
		else if (!(OldButtons[client] & IN_FORWARD) && (buttons & IN_FORWARD))
		{
			if (StrEqual("models/blodia/airboat.mdl", Model, false))
			{
				EmitSoundToAll("vehicles/airboat/fan_motor_fullthrottle_loop1.wav", InVehicle[client], SNDCHAN_STATIC, SNDLEVEL_MINIBIKE);
			}
			else
			{
				EmitSoundToAll("vehicles/v8/first.wav", InVehicle[client], SNDCHAN_STATIC, SNDLEVEL_MINIBIKE);
			}
		}
		
		else if ((OldButtons[client] & IN_FORWARD) && !(buttons & IN_FORWARD))
		{
			if (StrEqual("models/blodia/airboat.mdl", Model, false))
			{
				StopSound(InVehicle[client], SNDCHAN_STATIC, "vehicles/airboat/fan_motor_fullthrottle_loop1.wav");
			}
			else
			{
				StopSound(InVehicle[client], SNDCHAN_STATIC, "vehicles/v8/first.wav");
			}
		}
		
		if (!(OldButtons[client] & IN_JUMP) && (buttons & IN_JUMP))
		{
			AcceptEntityInput(InVehicle[client], "HandBrakeOn");
		}
		
		if ((OldButtons[client] & IN_JUMP) && !(buttons & IN_JUMP))
		{
			AcceptEntityInput(InVehicle[client], "HandBrakeOff");
		}
		
		if (!(OldButtons[client] & IN_USE) && (buttons & IN_USE))
		{
			if (!BlockExit)
			{
				ExitVehicle(client, InVehicle[client]);
			}
			else
			{
				PrintToChat(client, "\x04[VehicleMod]\x05 Exiting vehicles is disabled");
			}
		}
		
		OldButtons[client] = buttons;
		
		SetEntPropVector(client, Prop_Data, "m_vecViewOffset", null);
		
		return Plugin_Handled;
	}
	
	OldButtons[client] = buttons;
	
	return Plugin_Continue;
}

public bool:RayDontHitClient(entity, contentsMask, any:data)
{
	return (entity != data);
}

public OnEntityDestroyed(entity)
{
	new String:ClassName[30];
	GetEdictClassname(entity, ClassName, sizeof(ClassName));
	if (StrEqual("prop_vehicle", ClassName, false))
	{
		new Driver = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		if (Driver)
		{
			ExitVehicle(Driver, entity, 1);
		}
	}
}

public Action:Event_RoundEndPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Vehicle = -1;
	new PrevVehicle = 0;
	while ((Vehicle = FindEntityByClassname(Vehicle, "prop_vehicle")) != -1)
	{
		if (PrevVehicle)
		{
			new Driver = GetEntProp(PrevVehicle, Prop_Data, "m_iMaxHealth");
			if (Driver)
			{
				ExitVehicle(Driver, PrevVehicle, 1);
			}
			AcceptEntityInput(PrevVehicle, "Kill");
		}
		PrevVehicle = Vehicle;
	}
	
	if (PrevVehicle)
	{
		new Driver = GetEntProp(PrevVehicle, Prop_Data, "m_iMaxHealth");
		if (Driver)
		{
			ExitVehicle(Driver, PrevVehicle, 1);
		}
		AcceptEntityInput(PrevVehicle, "Kill");
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);
	
	if (InVehicle[client])
	{
		ExitVehicle(client, InVehicle[client], 1);
	}
	
	return Plugin_Continue;
}

EnterVehicle(client, vehicle)
{
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, null);
	
	new String:TargetName[10];
	Format(TargetName, sizeof(TargetName), "%i",vehicle);
	
	SetVariantString(TargetName);
	AcceptEntityInput(client, "SetParent");
	
	new EntEffects = GetEntProp(client, Prop_Send, "m_fEffects");
	EntEffects |= EF_NODRAW;
	SetEntProp(client, Prop_Send, "m_fEffects", EntEffects);
	
	new ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (ActiveWeapon != -1)
	{
		EntEffects = GetEntProp(ActiveWeapon, Prop_Send, "m_fEffects");
		EntEffects |= EF_NODRAW;
		SetEntProp(ActiveWeapon, Prop_Send, "m_fEffects", EntEffects);
		
		SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", (GetGameTime() + 999999.0));
		SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", (GetGameTime() + 999999.0));
		
		AcceptEntityInput(ActiveWeapon, "hideweapon");
	}
	
	new hud = GetEntProp(client, Prop_Send, "m_iHideHUD");
	hud |= HIDEHUD_WEAPONSELECTION;
	hud |= HIDEHUD_CROSSHAIR;
	hud |= HIDEHUD_INVEHICLE;
	SetEntProp(client, Prop_Send, "m_iHideHUD", hud);
	
	new DriverTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
	SetEntProp(vehicle, Prop_Send, "m_iTeamNum", DriverTeam);

	SetEntProp(vehicle, Prop_Data, "m_iMaxHealth", client);
	
	InVehicle[client] = vehicle;
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_IN_VEHICLE);
	
	HookSingleEntityOutput(client, "OnUser2", FixView, true);
	
	decl String:OutputString[50] = "OnUser1 !self:FireUser2::0.0:1";
	SetVariantString(OutputString);
	AcceptEntityInput(client, "AddOutput");
	
	AcceptEntityInput(client, "FireUser1");
	
	new String:Model[255];
	
	GetEntPropString(vehicle, Prop_Data, "m_ModelName", Model, sizeof(Model));
	
	if (StrEqual("models/blodia/airboat.mdl", Model, false))
	{
		EmitSoundToAll("vehicles/airboat/fan_motor_idle_loop1.wav", vehicle, SNDCHAN_STATIC, SNDLEVEL_MINIBIKE, SND_NOFLAGS, 0.5);
	}
	else
	{
		EmitSoundToAll("vehicles/v8/v8_idle_loop1.wav", vehicle, SNDCHAN_STATIC, SNDLEVEL_MINIBIKE);
	}
}

public FixView(const String:output[], caller, activator, Float:delay)
{
	SetVariantString("vehicle_driver_eyes");
	AcceptEntityInput(caller, "SetParentAttachment");
	
	new Float:FaceFront[3] = {0.0, 90.0, 0.0};
	
	TeleportEntity(caller, NULL_VECTOR, FaceFront, NULL_VECTOR);
}

ExitVehicle(client, vehicle, force=0)
{
	new Float:ExitPoint[3];
	
	if (!force)
	{
		if (!IsExitClear(client, vehicle, 90.0, ExitPoint))
		{
			if (!IsExitClear(client, vehicle, -90.0, ExitPoint))
			{
				if (!IsExitClear(client, vehicle, 0.0, ExitPoint))
				{
					if (!IsExitClear(client, vehicle, 180.0, ExitPoint))
					{
						new Float:ClientEye[3];
						GetClientEyePosition(client, ClientEye);
						
						new Float:ClientMinHull[3];
						new Float:ClientMaxHull[3];
						GetEntPropVector(client, Prop_Send, "m_vecMins", ClientMinHull);
						GetEntPropVector(client, Prop_Send, "m_vecMaxs", ClientMaxHull);
						
						new Float:TraceEnd[3];
						TraceEnd[0] = ClientEye[0];
						TraceEnd[1] = ClientEye[1];
						TraceEnd[2] = ClientEye[2] + 500.0;
						
						TR_TraceHullFilter(ClientEye, TraceEnd, ClientMinHull, ClientMaxHull, MASK_PLAYERSOLID, DontHitClientOrVehicle, client);
						
						new Float:CollisionPoint[3];
						
						if (TR_DidHit())
						{
							TR_GetEndPosition(CollisionPoint);
						}
						else
						{
							CollisionPoint[0] = TraceEnd[0];
							CollisionPoint[1] = TraceEnd[1];
							CollisionPoint[2] = TraceEnd[2];
						}
						
						TR_TraceHull(CollisionPoint, ClientEye, ClientMinHull, ClientMaxHull, MASK_PLAYERSOLID);
						
						new Float:VehicleEdge[3];
						TR_GetEndPosition(VehicleEdge);
						
						new Float:ClearDistance = GetVectorDistance(VehicleEdge, CollisionPoint);
						
						if (ClearDistance >= 50.0)
						{
							ExitPoint[0] = VehicleEdge[0];
							ExitPoint[1] = VehicleEdge[1];
							ExitPoint[2] = VehicleEdge[2] + 50.0;
							
							if (TR_PointOutsideWorld(ExitPoint))
							{
								PrintToChat(client, "\x04[Vehicle Mod]\x05 No safe exit point found!!!!!");
								return;
							}
						}
						else
						{
							PrintToChat(client, "\x04[Vehicle Mod]\x05 No safe exit point found!!!!!");
							return;
						}
					}
				}
			}
		}
	}
	
	AcceptEntityInput(client, "ClearParent");
	
	if (IsPlayerAlive(client))
	{
		new EntEffects = GetEntProp(client, Prop_Send, "m_fEffects");
		EntEffects &= ~EF_NODRAW;
		SetEntProp(client, Prop_Send, "m_fEffects", EntEffects);
		
		new ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (ActiveWeapon != -1)
		{
			EntEffects = GetEntProp(ActiveWeapon, Prop_Send, "m_fEffects");
			EntEffects |= EF_NODRAW;
			SetEntProp(ActiveWeapon, Prop_Send, "m_fEffects", EntEffects);
			
			SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
			SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime());
		}
	}
	
	new hud = GetEntProp(client, Prop_Send, "m_iHideHUD");
	hud &= ~HIDEHUD_WEAPONSELECTION;
	hud &= ~HIDEHUD_CROSSHAIR;
	hud &= ~HIDEHUD_INVEHICLE;
	SetEntProp(client, Prop_Send, "m_iHideHUD", hud);
	
	SetEntProp(vehicle, Prop_Send, "m_iTeamNum", 0);
	
	SetEntProp(vehicle, Prop_Data, "m_iMaxHealth", 0);
	
	InVehicle[client] = 0;
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
	
	new Float:ExitAng[3];
	
	GetEntPropVector(vehicle, Prop_Data, "m_angRotation", ExitAng);
	ExitAng[0] = 0.0;
	ExitAng[1] += 90.0;
	ExitAng[2] = 0.0;
	
	if (!force)
	{
		TeleportEntity(client, ExitPoint, ExitAng, null);
	}
	
	new String:Model[255];
	
	GetEntPropString(vehicle, Prop_Data, "m_ModelName", Model, sizeof(Model));
	
	if (StrEqual("models/blodia/airboat.mdl", Model, false))
	{
		StopSound(vehicle, SNDCHAN_STATIC, "vehicles/airboat/fan_motor_fullthrottle_loop1.wav");
		StopSound(vehicle, SNDCHAN_STATIC, "vehicles/airboat/fan_motor_fullthrottle_loop1.wav");
		StopSound(vehicle, SNDCHAN_STATIC, "vehicles/airboat/fan_motor_idle_loop1.wav");
	}
	else
	{
		StopSound(vehicle, SNDCHAN_STATIC, "vehicles/v8/first.wav");
		StopSound(vehicle, SNDCHAN_STATIC, "vehicles/v8/first.wav");
		StopSound(vehicle, SNDCHAN_STATIC, "vehicles/v8/v8_idle_loop1.wav");
	}
	
	SetVariantInt(0);
	AcceptEntityInput(vehicle, "Steer");
	
	SetVariantInt(0);
	AcceptEntityInput(vehicle, "Throttle");
	
	AcceptEntityInput(vehicle, "HandBrakeOff");
}

bool:IsExitClear(client, vehicle, Float:direction, Float:exitpoint[3])
{
	new Float:ClientEye[3];
	new Float:VehicleAngle[3];
	GetClientEyePosition(client, ClientEye);
	GetEntPropVector(vehicle, Prop_Data, "m_angRotation", VehicleAngle);
	
	new Float:ClientMinHull[3];
	new Float:ClientMaxHull[3];
	GetEntPropVector(client, Prop_Send, "m_vecMins", ClientMinHull);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", ClientMaxHull);
	
	VehicleAngle[0] = 0.0;
	VehicleAngle[2] = 0.0;
	VehicleAngle[1] += direction;
	
	new Float:DirectionVec[3];
	GetAngleVectors(VehicleAngle, NULL_VECTOR, DirectionVec, NULL_VECTOR);
	ScaleVector(DirectionVec, -500.0);
	
	new Float:VehicleMinHull[3] ;
	new Float:VehicleMaxHull[3] ;
	GetEntPropVector(vehicle, Prop_Send, "m_vecMins", VehicleMinHull);
	GetEntPropVector(vehicle, Prop_Send, "m_vecMaxs", VehicleMaxHull);
	
	new Float:TraceEnd[3];
	AddVectors(ClientEye, DirectionVec, TraceEnd);
	
	TR_TraceHullFilter(ClientEye, TraceEnd, ClientMinHull, ClientMaxHull, MASK_PLAYERSOLID, DontHitClientOrVehicle, client);
	
	new Float:CollisionPoint[3];
	
	if (TR_DidHit())
	{
		TR_GetEndPosition(CollisionPoint);
	}
	else
	{
		CollisionPoint[0] = TraceEnd[0];
		CollisionPoint[1] = TraceEnd[1];
		CollisionPoint[2] = TraceEnd[2];
	}
	
	TR_TraceHull(CollisionPoint, ClientEye, ClientMinHull, ClientMaxHull, MASK_PLAYERSOLID);
	
	new Float:VehicleEdge[3];
	TR_GetEndPosition(VehicleEdge);
	
	new Float:ClearDistance = GetVectorDistance(VehicleEdge, CollisionPoint);
	
	if (ClearDistance >= 50.0)
	{
		MakeVectorFromPoints(VehicleEdge, CollisionPoint, DirectionVec);
		NormalizeVector(DirectionVec, DirectionVec);
		ScaleVector(DirectionVec, 50.0);
		
		AddVectors(VehicleEdge, DirectionVec, exitpoint);
		
		if (TR_PointOutsideWorld(exitpoint))
		{
			return false;
		}
		else
		{
			return true;
		}
	}
	else
	{
		return false;
	}
}

public bool:DontHitClientOrVehicle(entity, contentsMask, any:data)
{
	return ((entity != data) && (entity != InVehicle[data]));
}

public OnPostThinkPost(client)
{
	if (InVehicle[client])
	{
		SetEntPropVector(client, Prop_Data, "m_vecViewOffset", null);
	}
}

public Action: OnVehicleTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (damage > GetEntProp(victim, Prop_Data, "m_iHealth"))
	{
		SetVariantString("Explosion");
		AcceptEntityInput(victim, "DispatchEffect");
		EmitSoundToAll("vehicles/v8/vehicle_impact_heavy1.wav", victim, 0, 90);
	}
	
	return Plugin_Continue;
}

public Action: OnClientTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new String:ClassName[30];
	GetEdictClassname(inflictor, ClassName, sizeof(ClassName));
	if (StrEqual("prop_vehicle", ClassName, false))
	{
		new Driver = GetEntProp(inflictor, Prop_Data, "m_iMaxHealth");
		if (Driver)
		{
			if (victim != Driver)
			{
				new DriverTeam = GetEntProp(Driver, Prop_Send, "m_iTeamNum");
				new VictimTeam = GetEntProp(victim, Prop_Send, "m_iTeamNum");
				
				if (VictimTeam == DriverTeam)
				{
					return Plugin_Handled;
				}
				
				attacker = Driver;
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:OnWeaponStuff(client, weapon)
{
	if (InVehicle[client])
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}