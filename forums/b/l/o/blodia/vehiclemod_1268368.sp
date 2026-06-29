#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "0.6"

#define DAMAGE_NO 0
#define DAMAGE_YES 2

#define VEHICLE_TYPE_AIRBOAT_RAYCAST 8

#define SOLID_VPHYSICS 6
#define SOLID_NONE 0

#define COLLISION_GROUP_PLAYER 5

#define EF_NODRAW 32

#define HIDEHUD_WEAPONSELECTION 1
#define HIDEHUD_CROSSHAIR 256
#define HIDEHUD_INVEHICLE 1024

enum VehicleData
{
	WeaponEntity,
	DamageEntity,
	Float:NextAttack
};

new Handle:VehicleTrie;

new Handle:hBreakable;
new Handle:hHealth;
new Handle:hLock;
new Handle:hdamage;
new Handle:henablegun;
new Handle:hgunmindamage;
new Handle:hgunmaxdamage;
new Handle:hgunrof;

new Handle:VehicleKV;

new IsBreakable;
new VehicleHealth;
new ForceLocked;
new DamageDriver;
new AllowGun;
new GunMinDamage;
new GunMaxDamage;
new Float:GunROF;
new LaserIndex;

new Float:CurrentEyeAngle[MAXPLAYERS+1][3];
new ForceSwitch[MAXPLAYERS+1];

new Float:null[3];

public Plugin:myinfo =
{
	name = "Vehicle Mod",
	author = "Blodia",
	description = "Allows you to drive vehicles",
	version = "0.6",
	url = ""
}

public OnPluginStart()
{
	CreateConVar("vehiclemod_version", PLUGIN_VERSION, "Vehicle Mod version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	RegServerCmd("vehiclemod_spawnatuserid", SpawnVehicleUserId, "Spawns a vehicle in front of a player by userid. Usage vehiclemod_spawnatuserid <userid> <vehicle name> <skin>[optional])");
	RegServerCmd("vehiclemod_spawnatcoords", SpawnVehicleCoords, "Spawns a vehicle at a set of coordinates. Usage vehiclemod_spawnatcoords <x coord> <y coord> <z coord> <yaw angle> <vehicle name> <skin>[optional])");
	
	hBreakable = CreateConVar("vehiclemod_breakable", "0", "0 make vehicles unbreakable and 1 makes them breakable", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	hHealth = CreateConVar("vehiclemod_health", "200", "how much health breakable vehicles have", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 1.0, true, 1000000.0);
	hLock = CreateConVar("vehiclemod_autolock", "0", "0 lets players exit vehicles at will and 1 locks them in once they enter", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	hdamage = CreateConVar("vehiclemod_damagedriver", "1", "0 stops players taking damage while in vehicle 1 allows them to be damaged", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	henablegun = CreateConVar("vehiclemod_gun_enable", "0", "0 disables vehicle guns 1 enables vehicle guns", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	hgunmindamage = CreateConVar("vehiclemod_gun_mindamage", "5", "minimum damage the gun does", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 1.0, true, 1000000.0);
	hgunmaxdamage = CreateConVar("vehiclemod_gun_maxdamage", "10", "maximum damage the gun does", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 1.0, true, 1000000.0);
	hgunrof = CreateConVar("vehiclemod_gun_rof", "0.2", "the guns rate of fire, delays between shots in seconds", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.01, true, 100.0);
	
	IsBreakable = GetConVarInt(hBreakable);
	VehicleHealth = GetConVarInt(hHealth);
	ForceLocked = GetConVarInt(hLock);
	DamageDriver = GetConVarInt(hdamage);
	AllowGun = GetConVarInt(henablegun);
	GunMinDamage = GetConVarInt(hgunmindamage);
	GunMaxDamage = GetConVarInt(hgunmaxdamage);
	GunROF = GetConVarFloat(hgunrof);
	
	HookConVarChange(hBreakable, ConVarChange);
	HookConVarChange(hHealth, ConVarChange);
	HookConVarChange(hLock, ConVarChange);
	HookConVarChange(hdamage, ConVarChange);
	HookConVarChange(henablegun, ConVarChange);
	HookConVarChange(hgunmindamage, ConVarChange);
	HookConVarChange(hgunmaxdamage, ConVarChange);
	HookConVarChange(hgunrof, ConVarChange);
	
	HookEvent("round_end", Event_RoundEndPre, EventHookMode_Pre);
	
	for (new client = 1; client <= MaxClients; client++) 
	{ 
		if (IsClientInGame(client)) 
		{
			SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost);
			SDKHook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
		}
	}
	
	VehicleKV = CreateKeyValues("VehicleDatabase");
	FileToKeyValues(VehicleKV, "cfg/vehiclelist.cfg");
	
	VehicleTrie = CreateTrie();
}

public OnPluginEnd()
{
	CloseHandle(VehicleKV);
	CloseHandle(VehicleTrie);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost);
	SDKHook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
}

// remove players from vehicles when they disconnect or the engine still thinks theres a driver.
// plus any new players who connect with the same index as old driver are forced to be the driver.
public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		new InVehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		
		if (InVehicle != -1)
		{
			ExitVehicle(client, InVehicle, 1);
		}
	}
}

public ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == hBreakable)
	{
		IsBreakable = StringToInt(newVal);
		
		new Vehicle = -1;
		while ((Vehicle = FindEntityByClassname(Vehicle, "prop_vehicle_driveable")) != -1)
		{
			if (IsBreakable)
			{
				SetEntProp(Vehicle, Prop_Data, "m_takedamage", DAMAGE_YES);
				SetEntProp(Vehicle, Prop_Data, "m_iHealth", VehicleHealth);
			}
			else
			{
				SetEntProp(Vehicle, Prop_Data, "m_takedamage", DAMAGE_NO);
			}
		}
	}
	
	else if (cvar == hHealth)
	{
		VehicleHealth = StringToInt(newVal);
	}
	
	else if (cvar == hLock)
	{
		ForceLocked = StringToInt(newVal);
	}
	
	else if (cvar == hdamage)
	{
		DamageDriver = StringToInt(newVal);
		
		for (new client = 1; client <= MaxClients; client++) 
		{ 
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				if (GetEntPropEnt(client, Prop_Send, "m_hVehicle") != -1)
				{
					if (DamageDriver)
					{
						SetEntityMoveType(client, MOVETYPE_NONE);
					}
					else
					{
						SetEntityMoveType(client, MOVETYPE_NOCLIP);
					}
				}
			}
		}
	}
	
	else if (cvar == henablegun)
	{
		AllowGun = StringToInt(newVal);
		
		
	
		new Vehicle = -1;
		while ((Vehicle = FindEntityByClassname(Vehicle, "prop_vehicle_driveable")) != -1)
		{
			new String:IndexString[10];
			Format(IndexString, sizeof(IndexString), "%i", Vehicle);
			
			new VehicleInfo[VehicleData];
			GetTrieArray(VehicleTrie, IndexString, VehicleInfo[0], 3);
			
			new EntEffects = GetEntProp(VehicleInfo[WeaponEntity], Prop_Send, "m_fEffects");
			
			if (AllowGun)
			{
				EntEffects &= ~EF_NODRAW;
			}
			else
			{
				EntEffects |= EF_NODRAW;
			}
			SetEntProp(VehicleInfo[WeaponEntity], Prop_Send, "m_fEffects", EntEffects);
			SetEntProp(Vehicle, Prop_Data, "m_bHasGun", AllowGun);
		}
	}
	
	else if (cvar == hgunmindamage)
	{
		GunMinDamage = StringToInt(newVal);
		
		if (GunMinDamage > GunMaxDamage)
		{
			SetConVarInt(hgunmindamage, GunMaxDamage);
		}
	}
	
	else if (cvar == hgunmaxdamage)
	{
		GunMaxDamage = StringToInt(newVal);
		
		if (GunMaxDamage < GunMinDamage)
		{
			SetConVarInt(hgunmaxdamage, GunMinDamage);
		}
	}
	
	else if (cvar == hgunrof)
	{
		GunROF = StringToFloat(newVal);
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
	
	AddFileToDownloadsTable("models/blodia/vehicle_gun.dx80.vtx");
	AddFileToDownloadsTable("models/blodia/vehicle_gun.dx90.vtx");
	AddFileToDownloadsTable("models/blodia/vehicle_gun.mdl");
	AddFileToDownloadsTable("models/blodia/vehicle_gun.sw.vtx");
	AddFileToDownloadsTable("models/blodia/vehicle_gun.vvd");
	
	PrecacheModel("models/blodia/vehicle_gun.mdl");
	
	AddFileToDownloadsTable("materials/sprites/laser.vmt");
	AddFileToDownloadsTable("materials/sprites/laser.vtf");
	LaserIndex = PrecacheModel("materials/sprites/laser.vmt");
	
	AddFileToDownloadsTable("materials/sprites/hud/320v_crosshair1.vmt");
	AddFileToDownloadsTable("materials/sprites/hud/320v_crosshair1.vtf");
	AddFileToDownloadsTable("materials/sprites/hud/v_crosshair1.vmt");
	AddFileToDownloadsTable("materials/sprites/hud/v_crosshair1.vtf");
	
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
	
	AddFileToDownloadsTable("sound/weapons/gauss/fire1.wav");
	
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
	
	PrecacheSound("weapons/gauss/fire1.wav");
	
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
	
	new String:Arg2[50];
	GetCmdArg(2, Arg2, sizeof(Arg2));
	
	new Skin = -1;
	if (GetCmdArgs() == 3)
	{
		new String:Arg3[10];
		GetCmdArg(3, Arg3, sizeof(Arg3));
		
		Skin = StringToInt(Arg3);
		
		new Skins = KvGetNum(VehicleKV, "skins");
		
		if ((Skin < 0) || (Skin > Skins))
		{
			PrintToServer("********** vehiclemod: skin value must be an integer between 0 and %i", Skins);
			return Plugin_Handled;
		}
	}
	
	new userid = StringToInt(Arg1);
	new client = GetClientOfUserId(userid);
	
	if ((client == 0) || (client > MaxClients))
	{
		PrintToServer("********** vehiclemod: no valid userindex found from userid");
		return Plugin_Handled;
	}
	
	if (GetEntPropEnt(client, Prop_Send, "m_hVehicle") != -1)
	{
		PrintToServer("********** vehiclemod: client is already in a vehicle");
		return Plugin_Handled;
	}
	
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:EyeAng[3];
		GetClientEyeAngles(client, EyeAng);
		
		new Float:SpawnAngles[3];
		SpawnAngles[1] = EyeAng[1] - 90.0;
		new Float:SpawnOrigin[3];
		GetClientEyePosition(client, SpawnOrigin);
		
		SpawnVehicle(SpawnOrigin, SpawnAngles, Arg2, Skin, client);
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
	
	new String:Arg5[50];
	GetCmdArg(5, Arg5, sizeof(Arg5));
	
	new Skin = -1;
	if (GetCmdArgs() == 6)
	{
		new String:Arg6[10];
		GetCmdArg(6, Arg6, sizeof(Arg6));
		
		Skin = StringToInt(Arg6);
		
		new Skins = KvGetNum(VehicleKV, "skins");
		
		if ((Skin < 0) || (Skin > Skins))
		{
			PrintToServer("********** vehiclemod: skin value must be an integer between 0 and %i", Skins);
			return Plugin_Handled;
		}
	}
	
	new Float:SpawnOrigin[3];
	SpawnOrigin[0] = StringToFloat(Arg1);
	SpawnOrigin[1] = StringToFloat(Arg2);
	SpawnOrigin[2] = StringToFloat(Arg3);
	
	new Float:SpawnAngles[3];
	SpawnAngles[1] = StringToFloat(Arg4) - 90.0;
	
	SpawnVehicle(SpawnOrigin, SpawnAngles, Arg5, Skin);
	
	return Plugin_Handled;
}

SpawnVehicle(Float:spawnorigin[3], Float:spawnangles[3], const String:vehicle[], skin, client=0)
{	
	new String:ModelPath[255];
	new String:ScriptPath[255];
	
	KvRewind(VehicleKV);
	
	if (!KvJumpToKey(VehicleKV, vehicle))
	{
		PrintToServer("********** vehiclemod: vehicle not found");
		return;
	}
	
	KvGetString(VehicleKV, "model", ModelPath, sizeof(ModelPath));
	KvGetString(VehicleKV, "vehiclescript", ScriptPath, sizeof(ScriptPath));
	
	new VehicleType = KvGetNum(VehicleKV, "vehicletype");
	
	new VehicleIndex = CreateEntityByName("prop_vehicle_driveable");
	if (VehicleIndex == -1)
	{
		PrintToServer("********** vehiclemod: could not create vehicle entity");
		return;
	}
	
	new String:TargetName[10];
	Format(TargetName, sizeof(TargetName), "%i",VehicleIndex);
	DispatchKeyValue(VehicleIndex, "targetname", TargetName);
	
	DispatchKeyValue(VehicleIndex, "model", ModelPath);
	DispatchKeyValue(VehicleIndex, "vehiclescript", ScriptPath);
	
	SetEntProp(VehicleIndex, Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
	
	if (skin == -1)
	{
		new Skins = KvGetNum(VehicleKV, "skins");
		
		skin = GetRandomInt(0, Skins-1);
	}
	
	SetEntProp(VehicleIndex, Prop_Send, "m_nSkin", skin);
	
	if (VehicleType)
	{
		SetEntProp(VehicleIndex, Prop_Data, "m_nVehicleType", VEHICLE_TYPE_AIRBOAT_RAYCAST);
	}
	
	DispatchSpawn(VehicleIndex);
	ActivateEntity(VehicleIndex);
	
	// stops the vehicle rolling back when it is spawned.
	SetEntProp(VehicleIndex, Prop_Data, "m_nNextThinkTick", -1);
	SetEntProp(VehicleIndex, Prop_Data, "m_bHasGun", AllowGun);
	
	SDKHook(VehicleIndex, SDKHook_OnTakeDamage, OnVehicleTakeDamage);
	
	// anti flip, not 100% effective.
	new PhysIndex = CreateEntityByName("phys_ragdollconstraint");
	
	if (PhysIndex == -1)
	{
		AcceptEntityInput(VehicleIndex, "Kill");
		
		PrintToServer("********** vehiclemod: could not create anti flip entity");
		return;
	}
	
	DispatchKeyValue(PhysIndex, "spawnflags", "2");
	DispatchKeyValue(PhysIndex, "ymin", "-50.0");
	DispatchKeyValue(PhysIndex, "ymax", "50.0");
	DispatchKeyValue(PhysIndex, "zmin", "-180.0");
	DispatchKeyValue(PhysIndex, "zmax", "180.0");
	DispatchKeyValue(PhysIndex, "xmin", "-50.0");
	DispatchKeyValue(PhysIndex, "xmax", "50.0");
	
	DispatchKeyValue(PhysIndex, "attach1", TargetName);
	
	DispatchSpawn(PhysIndex);
	ActivateEntity(PhysIndex);
	
	SetVariantString(TargetName);
	AcceptEntityInput(PhysIndex, "SetParent");
	
	TeleportEntity(PhysIndex, null, NULL_VECTOR, NULL_VECTOR);
	
	// gun entity
	new GunIndex = CreateEntityByName("prop_dynamic");
	
	if (GunIndex == -1)
	{
		AcceptEntityInput(VehicleIndex, "Kill");
		
		PrintToServer("********** vehiclemod: could not create gun");
		return;
	}
	
	DispatchKeyValue(GunIndex, "model", "models/blodia/vehicle_gun.mdl");
	
	SetEntProp(GunIndex, Prop_Send, "m_nSolidType", SOLID_NONE);
	
	DispatchSpawn(GunIndex);
	ActivateEntity(GunIndex);
	
	SetVariantString(TargetName);
	AcceptEntityInput(GunIndex, "SetParent");
	
	new Float:gunvec[3];
	new Float:gunang[3] = {0.0, 90.0, 0.0};
	
	gunvec[0] = KvGetFloat(VehicleKV, "gunx");
	gunvec[1] = KvGetFloat(VehicleKV, "guny");
	gunvec[2] = KvGetFloat(VehicleKV, "gunz");
	
	TeleportEntity(GunIndex, gunvec, gunang, NULL_VECTOR);
	
	// damage entity
	new DamageIndex = CreateEntityByName("point_hurt");
	
	if (DamageIndex == -1)
	{
		AcceptEntityInput(VehicleIndex, "Kill");
		
		PrintToServer("********** vehiclemod: could not create damage entity");
		return;
	}
	
	SetEntPropFloat(DamageIndex, Prop_Data, "m_flRadius", 1.0);
	SetEntProp(DamageIndex, Prop_Data, "m_nDamage", 1);
	SetEntProp(DamageIndex, Prop_Data, "m_bitsDamageType", DMG_BLAST);
	
	new String:GunTarget[20];
	Format(GunTarget, sizeof(GunTarget), "%itarget",VehicleIndex);
	DispatchKeyValue(DamageIndex,"DamageTarget",GunTarget);
	
	DispatchSpawn(DamageIndex);
	ActivateEntity(DamageIndex);
	
	
	// check if theres space to spawn the vehicle.
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
	
	if (!AllowGun)
	{
		new EntEffects = GetEntProp(GunIndex, Prop_Send, "m_fEffects");
		EntEffects |= EF_NODRAW;
		SetEntProp(GunIndex, Prop_Send, "m_fEffects", EntEffects);
	}
	
	// force players in.
	if (client != 0)
	{
		AcceptEntityInput(VehicleIndex, "use", client);
	}
	
	new VehicleInfo[VehicleData];
	VehicleInfo[WeaponEntity] = GunIndex;
	VehicleInfo[NextAttack] = GetGameTime();
	VehicleInfo[DamageEntity] = DamageIndex;
	SetTrieArray(VehicleTrie, TargetName, VehicleInfo[0], 3);
}

public bool:RayDontHitClient(entity, contentsMask, any:data)
{
	return (entity != data);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static OldButtons[MAXPLAYERS + 1];
	
	if (!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	// grab players view angles for when vehicles take control.
	CurrentEyeAngle[client] = angles;
	
	// only check the first keypress to stop spam.
	if (!(OldButtons[client] & IN_USE) && (buttons & IN_USE))
	{
		new InVehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		
		if (InVehicle != -1)
		{
			// make sure the vehicle isn't locked or moving.
			if ((!GetEntProp(InVehicle, Prop_Data, "m_bLocked")) && (GetEntProp(InVehicle, Prop_Data, "m_nSpeed") == 0))
			{
				ExitVehicle(client, InVehicle);
			}
			
			OldButtons[client] = buttons;
			return Plugin_Handled;
		}
	}
	
	if (ForceSwitch[client])
	{
		ForceSwitch[client]--;
		weapon = GetEntPropEnt(client, Prop_Send, "m_hLastWeapon");
		if (weapon == -1)
		{
			weapon = 0;
		}
	}

	OldButtons[client] = buttons;
	
	return Plugin_Continue;
}

ExitVehicle(client, vehicle, force=0)
{
	new Float:ExitPoint[3];
	
	if (!force)
	{
		// check left.
		if (!IsExitClear(client, vehicle, 90.0, ExitPoint))
		{
			// check right.
			if (!IsExitClear(client, vehicle, -90.0, ExitPoint))
			{
				// check front.
				if (!IsExitClear(client, vehicle, 0.0, ExitPoint))
				{
					// check back.
					if (!IsExitClear(client, vehicle, 180.0, ExitPoint))
					{
						// check above the vehicle.
						new Float:ClientEye[3];
						GetClientEyePosition(client, ClientEye);
						
						new Float:ClientMinHull[3];
						new Float:ClientMaxHull[3];
						GetEntPropVector(client, Prop_Send, "m_vecMins", ClientMinHull);
						GetEntPropVector(client, Prop_Send, "m_vecMaxs", ClientMaxHull);
						
						new Float:TraceEnd[3];
						TraceEnd = ClientEye;
						TraceEnd[2] += 500.0;
						
						TR_TraceHullFilter(ClientEye, TraceEnd, ClientMinHull, ClientMaxHull, MASK_PLAYERSOLID, DontHitClientOrVehicle, client);
						
						new Float:CollisionPoint[3];
						
						if (TR_DidHit())
						{
							TR_GetEndPosition(CollisionPoint);
						}
						else
						{
							CollisionPoint = TraceEnd;
						}
						
						TR_TraceHull(CollisionPoint, ClientEye, ClientMinHull, ClientMaxHull, MASK_PLAYERSOLID);
						
						new Float:VehicleEdge[3];
						TR_GetEndPosition(VehicleEdge);
						
						new Float:ClearDistance = GetVectorDistance(VehicleEdge, CollisionPoint);
						
						if (ClearDistance >= 100.0)
						{
							ExitPoint = VehicleEdge;
							ExitPoint[2] += 100.0;
							
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
	else
	{
		GetClientAbsOrigin(client, ExitPoint);
	}
	
	AcceptEntityInput(client, "ClearParent");
	
	SetEntPropEnt(client, Prop_Send, "m_hVehicle", -1);
	
	SetEntPropEnt(vehicle, Prop_Send, "m_hPlayer", -1);
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
	
	new hud = GetEntProp(client, Prop_Send, "m_iHideHUD");
	hud &= ~HIDEHUD_WEAPONSELECTION;
	hud &= ~HIDEHUD_CROSSHAIR;
	hud &= ~HIDEHUD_INVEHICLE;
	SetEntProp(client, Prop_Send, "m_iHideHUD", hud);
	
	new EntEffects = GetEntProp(client, Prop_Send, "m_fEffects");
	EntEffects &= ~EF_NODRAW;
	SetEntProp(client, Prop_Send, "m_fEffects", EntEffects);
	
	SetEntProp(vehicle, Prop_Send, "m_nSpeed", 0);
	SetEntPropFloat(vehicle, Prop_Send, "m_flThrottle", 0.0);
	AcceptEntityInput(vehicle, "TurnOff");
	
	new Float:ExitAng[3];
	
	GetEntPropVector(vehicle, Prop_Data, "m_angRotation", ExitAng);
	ExitAng[0] = 0.0;
	ExitAng[1] += 90.0;
	ExitAng[2] = 0.0;

	TeleportEntity(client, ExitPoint, ExitAng, null);
	
	ForceSwitch[client] = 2;
}

// checks if 100 units away from the edge of the vehicle in the given direction is clear.
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
		CollisionPoint = TraceEnd;
	}
	
	TR_TraceHull(CollisionPoint, ClientEye, ClientMinHull, ClientMaxHull, MASK_PLAYERSOLID);
	
	new Float:VehicleEdge[3];
	TR_GetEndPosition(VehicleEdge);
	
	new Float:ClearDistance = GetVectorDistance(VehicleEdge, CollisionPoint);
	
	if (ClearDistance >= 100.0)
	{
		MakeVectorFromPoints(VehicleEdge, CollisionPoint, DirectionVec);
		NormalizeVector(DirectionVec, DirectionVec);
		ScaleVector(DirectionVec, 100.0);
		
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
	new InVehicle = GetEntPropEnt(data, Prop_Send, "m_hVehicle");
	return ((entity != data) && (entity != InVehicle));
}

// remove players from vehicles before they are destroyed or the server will crash!
public OnEntityDestroyed(entity)
{
	if (IsValidEdict(entity))
	{
		new String:ClassName[30];
		GetEdictClassname(entity, ClassName, sizeof(ClassName));
		if (StrEqual("prop_vehicle_driveable", ClassName, false))
		{		
			new Driver = GetEntPropEnt(entity, Prop_Send, "m_hPlayer");
			if (Driver != -1)
			{
				ExitVehicle(Driver, entity, 1);
			}
			
			new String:IndexString[10];
			Format(IndexString, sizeof(IndexString), "%i", entity);
			
			new VehicleInfo[VehicleData];
			GetTrieArray(VehicleTrie, IndexString, VehicleInfo[0], 3);
			
			AcceptEntityInput(VehicleInfo[WeaponEntity], "Kill");
			AcceptEntityInput(VehicleInfo[DamageEntity], "Kill");
			
			RemoveFromTrie(VehicleTrie, IndexString);
		}
	}
}

// kill all vehicles at round end or players won't spawn in the right place next round.
public Action:Event_RoundEndPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Vehicle = -1;
	while ((Vehicle = FindEntityByClassname(Vehicle, "prop_vehicle_driveable")) != -1)
	{
		AcceptEntityInput(Vehicle, "Kill");
	}
}

public OnPreThinkPost(client)
{
	static WasInVehicle[MAXPLAYERS + 1];
	
	new InVehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	
	if (InVehicle == -1)
	{
		if (WasInVehicle[client] != 0)
		{
			if (IsValidEdict(WasInVehicle[client]))
			{
				SendConVarValue(client, FindConVar("sv_client_predict"), "1");
				SetEntProp(WasInVehicle[client], Prop_Send, "m_iTeamNum", 0);
			}
			WasInVehicle[client] = 0;
		}
		return;
	}
	
	new String:IndexString[10];
	Format(IndexString, sizeof(IndexString), "%i", InVehicle);
	
	new VehicleInfo[VehicleData];
	GetTrieArray(VehicleTrie, IndexString, VehicleInfo[0], 3);
	
	// "m_bEnterAnimOn" is the culprit for vehicles controlling all players views.
	// this is the earliest it can be changed, also stops vehicle starting..
	if (GetEntProp(InVehicle, Prop_Send, "m_bEnterAnimOn") == 1)
	{
		WasInVehicle[client] = InVehicle;
		
		new Float:FaceFront[3] = {0.0, 90.0, 0.0};
		
		TeleportEntity(client, NULL_VECTOR, FaceFront, NULL_VECTOR);
		
		SetEntProp(InVehicle, Prop_Send, "m_bEnterAnimOn", 0);
		
		// stick the player in the correct view position if they're stuck in and enter animation.
		SetEntProp(InVehicle, Prop_Send, "m_nSequence", 0);
		
		// set the vehicles team so team mates can't destroy it.
		new DriverTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
		SetEntProp(InVehicle, Prop_Send, "m_iTeamNum", DriverTeam);
		
		// this will make the player take damage while in the car.
		if (DamageDriver)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}
		
		if (ForceLocked)
		{
			AcceptEntityInput(InVehicle, "Lock");
		}
		
		// set players views back to where they were before the vehicle took control.
		for (new players = 1; players <= MaxClients; players++) 
		{ 
			if (IsClientInGame(players) && IsPlayerAlive(players))
			{
				if (players != client)
				{
					TeleportEntity(players, NULL_VECTOR, CurrentEyeAngle[players], NULL_VECTOR);
				}
			}
		}
		
		SendConVarValue(client, FindConVar("sv_client_predict"), "0");
		
		VehicleInfo[NextAttack] = GetGameTime() + GunROF;
		SetTrieArray(VehicleTrie, IndexString, VehicleInfo[0], 3);
	}
	else
	{
		AcceptEntityInput(InVehicle, "TurnOn");
		
		if (AllowGun)
		{
			//Calculate clients aim coords.
			new Float:EyePos[3];
			GetClientEyePosition(client, EyePos);
			new Float:EyeAng[3];
			GetClientEyeAngles(client, EyeAng);
			TR_TraceRayFilter(EyePos, EyeAng, MASK_SOLID, RayType_Infinite, DontHitClientOrVehicle, client);
			new Float:EndPos[3];
			TR_GetEndPosition(EndPos);
			new GunTarget = TR_GetEntityIndex();
			
			SetEntPropVector(InVehicle, Prop_Send, "m_vecGunCrosshair", EndPos);
			
			//Aim gun at same coords.
			new Float:GunPos[3];
			new Float:GunVec[3];
			new Float:GunAng[3];
			
			AcceptEntityInput(VehicleInfo[WeaponEntity], "ClearParent");
			GetEntPropVector(VehicleInfo[WeaponEntity], Prop_Send, "m_vecOrigin", GunPos);
			MakeVectorFromPoints(GunPos, EndPos, GunVec);
			GetVectorAngles(GunVec, GunAng);
			TeleportEntity(VehicleInfo[WeaponEntity], NULL_VECTOR, GunAng, NULL_VECTOR);
			SetVariantString(IndexString);
			AcceptEntityInput(VehicleInfo[WeaponEntity], "SetParent");
			
			new Float:GunAng2[3];
			GetEntPropVector(VehicleInfo[WeaponEntity], Prop_Data, "m_angRotation", GunAng2);
			GunAng2[2] = 0.0;
			TeleportEntity(VehicleInfo[WeaponEntity], NULL_VECTOR, GunAng2, NULL_VECTOR);
			
			//fire gun if possible
			if (GetGameTime() < VehicleInfo[NextAttack])
			{
				return;
			}
			
			if (GetClientButtons(client) & IN_ATTACK)
			{
				new Color[4] = {255, 0, 255, 255};
				
				new ClientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
				
				switch (ClientTeam)
				{
					case 2:
					{
						Color[2] = 0;
					}
					case 3:
					{
						Color[0] = 0;
					}
				}
					
				TE_SetupBeamPoints(GunPos, EndPos, LaserIndex, LaserIndex, 0, 0, 0.1, 3.0, 3.0, 0, 0.0, Color, 0);
				TE_SendToAll();
				
				EmitSoundToAll("weapons/gauss/fire1.wav", VehicleInfo[WeaponEntity], 1, 90);
				
				VehicleInfo[NextAttack] = GetGameTime() + GunROF;
				SetTrieArray(VehicleTrie, IndexString, VehicleInfo[0], 3);
				
				if (GunTarget > 0)
				{
					TeleportEntity(VehicleInfo[DamageEntity], EndPos, GunAng, NULL_VECTOR);
					
					new GunDamage = GetRandomInt(GunMinDamage, GunMaxDamage);
					SetEntProp(VehicleInfo[DamageEntity], Prop_Data, "m_nDamage", GunDamage);
					
					new String:OldTargetname[50];
					new String:NewTargetname[20];
					GetEntPropString(GunTarget, Prop_Data, "m_iName", OldTargetname, sizeof(OldTargetname));
					Format(NewTargetname, sizeof(NewTargetname), "%itarget",InVehicle);
					DispatchKeyValue(GunTarget,"targetname",NewTargetname);
					DispatchKeyValue(VehicleInfo[DamageEntity],"classname","weapon_vehiclegun");
					AcceptEntityInput(VehicleInfo[DamageEntity],"Hurt", client);
					DispatchKeyValue(VehicleInfo[DamageEntity],"classname","point_hurt");
					DispatchKeyValue(GunTarget,"targetname",OldTargetname);
				}
			}
		}
	}
}

// rewards drivers with kills when they ram players instead of it counting as a suicide.
// players don't get rewarded if they crush them against another entity as it counts as world damage.
public Action: OnClientTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (damagetype & DMG_VEHICLE)
	{
		new String:ClassName[30];
		GetEdictClassname(inflictor, ClassName, sizeof(ClassName));
		if (StrEqual("prop_vehicle_driveable", ClassName, false))
		{
			new Driver = GetEntPropEnt(inflictor, Prop_Send, "m_hPlayer");
			if (Driver != -1)
			{
				damage *= 2.0;
				
				if (victim != Driver)
				{
					new DriverTeam = GetEntProp(Driver, Prop_Send, "m_iTeamNum");
					new VictimTeam = GetEntProp(victim, Prop_Send, "m_iTeamNum");
					
					// don't hurt team mates when you ram them.
					// they will still die if crushed against an entity.
					if (VictimTeam == DriverTeam)
					{
						return Plugin_Handled;
					}
					
					attacker = Driver;
					return Plugin_Changed;
				}
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

// moved this here from OnEntityDestroyed as it would fire when vehicles were destroyed by none damage means.
public Action: OnVehicleTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((damage > float(GetEntProp(victim, Prop_Data, "m_iHealth"))) && IsBreakable)
	{
		new Float:Pos[3];
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", Pos);
		TE_SetupExplosion(Pos, -1, 1.0, 1, 0, 200, 200);
		TE_SendToAll();
		EmitSoundToAll("vehicles/v8/vehicle_impact_heavy1.wav", victim, 0, 90);
	}
	
	return Plugin_Continue;
}