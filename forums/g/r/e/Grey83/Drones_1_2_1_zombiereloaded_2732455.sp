/**** v1.2 ChangeLog ------------------------------------------------------------
 * Added Self destruct convar
 * Added Set render RENDER_NORMAL to clients not in drone, ongameframe, in attempt to remedy invisible enemy glitch
 * Added second thruster for forward movement(added one to keep travel straight)
 * Adjusted all thrusters for more accurate movement
*/

#pragma semicolon 1

#undef REQUIRE_PLUGIN
#tryinclude <zombiereloaded>

#pragma newdecls required

#define DEBUG

#define MAX_DRONES		12
#define TOTAL_THRUSTERS	8 // dont change

#define REQUIRE_PLUGIN
#include <sdktools>

public Plugin myinfo =
{
	name		= "Drones",
	version		= "1.2.1_zombiereloaded",
	description	= "Pilot drones armed with miniature missiles capable of homing in on enemies",
	author		= "Stugger (rewritten by Grey83)",
	url			= "https://forums.alliedmods.net/showthread.php?t=319847"
}

static const char
	DRONE_GIBS[][] =
	{
		"models/props_survival/drone/drone_gib1.mdl",
		"models/props_survival/drone/drone_gib2.mdl",
		"models/props_survival/drone/drone_gib3.mdl",
		"models/props_survival/drone/drone_gib6.mdl",
	},

	MODEL_DRONE[]				= "models/props_survival/drone/br_drone.mdl",
	MODEL_THRUSTER[]			= "models/props/cs_office/trash_can_p8.mdl",
	MODEL_MISSILE[]				= "models/shells/shell_338mag.mdl",

	SND_DRONE[]					= "#/vehicles/drone_loop_03.wav",
	SND_DRONE_BREAK[]			= "weapons/taser/taser_shoot.wav",

	SND_ROCKET_FIRED[]			= "survival/missile_land_01.wav",
	SND_ROCKET_FIRED_HOMING[]	= "survival/missile_land_04.wav",
	SND_ROCKET_FLY[]			= "ambient/nuke/vent_02.wav",
	SND_ROCKET_EXPLODE[]		= "weapons/c4/c4_explode1.wav",

	SPRITE_HALO[]				= "materials/sprites/halo01.vmt",
	SPRITE_BEAM[]				= "materials/sprites/laserbeam.vmt";

/************************************/

ConVar
	g_cvSelfDestruct,
	g_cvTurnForce,

	g_cvReloadInterval,
	g_cvMissileDamage,
	g_cvMissileRadius,
	g_cvMissileSpeed,
	g_cvMissileDistance,
	g_cvHomingEnabled,
	g_cvHomingDistance;
int
	g_BeamSprite,
	g_HaloSprite,

	g_Drone[MAX_DRONES]			= {-1, ...},
	g_DroneView[MAX_DRONES]		= {-1, ...},
	g_DroneUI[MAX_DRONES]		= {-1, ...},
	g_DroneSound[MAX_DRONES]	= {-1, ...},
	g_DroneThrusts[MAX_DRONES][TOTAL_THRUSTERS],
	g_DroneSelectedView[MAX_DRONES],

	g_pInDrone[MAXPLAYERS+1]	= {-1, ...};
float
	g_pActivateLocation[MAXPLAYERS+1][2][3],

	g_pFireMissileTimer[MAXPLAYERS+1],
	g_pGeneralTimer[MAXPLAYERS+1];
bool
	g_pAlternateFire[MAXPLAYERS+1];

//--------------------------------------------------------
// ******************* ON PLUGIN START *******************
//--------------------------------------------------------
public void OnPluginStart()
{
	RegAdminCmd("sm_drone", Cmd_SpawnDrone, ADMFLAG_CHEATS, "Spawn and enter or force a player into a pilotable drone capabale of firing homing missiles");

	g_cvSelfDestruct	= CreateConVar("sm_drone_self_destruct", "1", "Enable or disable drone self-destruction on exit");
	g_cvTurnForce		= CreateConVar("sm_drone_turn_force", "200", "Controls the thrust force for turning left and right of all drones");

	g_cvReloadInterval	= CreateConVar("sm_drone_missile_interval", "0.7", "Controls the reload interval for all drone missiles");

	g_cvMissileSpeed	= CreateConVar("sm_drone_missile_speed", "900", "Controls the travel speed of all drone missiles", FCVAR_NONE, true, 1.0, true, 2500.0);
	g_cvMissileDistance = CreateConVar("sm_drone_missile_distance", "5000.0", "Controls the max distance for regular missiles before self detonation");
	g_cvMissileDamage	= CreateConVar("sm_drone_missile_damage", "47", "Controls the damage of all drone missiles");
	g_cvMissileRadius	= CreateConVar("sm_drone_missile_radius", "275", "Controls the damage radius of all drone missiles");

	g_cvHomingEnabled	= CreateConVar("sm_drone_homing_enabled", "1", "Enable or disable the use of homing missiles(missiles will only shoot straight)");
	g_cvHomingDistance	= CreateConVar("sm_drone_homing_distance", "2500.0", "Controls the max distance an enemy can be to be targeted by homing missiles");

	// Hook Round Start
	HookEvent("round_prestart", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);

	// Hook Round End
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("cs_win_panel_round", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("cs_intermission", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("announce_phase_end", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_freeze_end", OnRoundEnd, EventHookMode_PostNoCopy);

	// Hook Player Spawn
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_PostNoCopy);

	// Translations
	LoadTranslations("common.phrases");
}

//--------------------------------------------------------
// ******************** ON MAP START *********************
//--------------------------------------------------------
public void OnMapStart()
{
	PrecacheModel(MODEL_DRONE, true);
	PrecacheModel(MODEL_THRUSTER, true);
	PrecacheModel(MODEL_MISSILE, true);

	for(int i; i < sizeof(DRONE_GIBS); i++) PrecacheModel(DRONE_GIBS[i], true);

	g_HaloSprite = PrecacheModel(SPRITE_HALO, true);
	g_BeamSprite = PrecacheModel(SPRITE_BEAM, true);

	PrecacheSound(SND_DRONE, true);
	PrecacheSound(SND_DRONE_BREAK, true);

	PrecacheSound(SND_ROCKET_FIRED, true);
	PrecacheSound(SND_ROCKET_FIRED_HOMING, true);
	PrecacheSound(SND_ROCKET_FLY, true);
	PrecacheSound(SND_ROCKET_EXPLODE, true);

	for(int i, j; i < MAX_DRONES; i++)
	{
		g_Drone[i]		= -1;
		g_DroneView[i]	= -1;
		g_DroneUI[i]	= -1;
		g_DroneSound[i]	= -1;

		for(j = 0; j < TOTAL_THRUSTERS; j++) g_DroneThrusts[i][j] = -1;
	}

	for(int i = 1; i <= MaxClients; i++) g_pInDrone[i] = -1;
}

//--------------------------------------------------------
// ******************* ON ROUND START ********************
//--------------------------------------------------------
public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	ExitAllDrones();

	for(int i, j; i < MAX_DRONES; i++)
	{
		if(g_Drone[i] != -1 && IsValidEntity(g_Drone[i]))
				AcceptEntityInput(g_Drone[i], "Kill");
		g_Drone[i] = -1;

		if(g_DroneView[i] != -1 && IsValidEntity(g_DroneView[i]))
				AcceptEntityInput(g_DroneView[i], "Kill");
		g_DroneView[i] = -1;

		if(g_DroneUI[i] != -1 && IsValidEntity(g_DroneUI[i]))
				AcceptEntityInput(g_DroneUI[i], "Kill");
		g_DroneUI[i] = -1;

		if(g_DroneSound[i] != -1 && IsValidEntity(g_DroneSound[i]))
				AcceptEntityInput(g_DroneSound[i], "Kill");
		g_DroneSound[i] = -1;

		for(j = 0; j < TOTAL_THRUSTERS; j++)
		{
			if(g_DroneThrusts[i][j] != -1 && IsValidEntity(g_DroneThrusts[i][j]))
				AcceptEntityInput(g_DroneThrusts[i][j], "Kill");
			g_DroneThrusts[i][j] = -1;
		}
	}
}

//--------------------------------------------------------
// ********************* ON MAP END **********************
//--------------------------------------------------------
public void OnMapEnd()
{
	ExitAllDrones();
}

//--------------------------------------------------------
// ******************** ON ROUND END *********************
//--------------------------------------------------------
public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	ExitAllDrones();
}

//--------------------------------------------------------
// **************** ON CLIENT DISCONNECT *****************
//--------------------------------------------------------
public void OnClientDisconnect(int client)
{
	if(g_pInDrone[client] > -1) ExitDrone(client, true);
}

//--------------------------------------------------------
// ****************** ON PLAYER SPAWN ********************
//--------------------------------------------------------
public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_pInDrone[client] > -1) ExitDrone(client, true);
}

//============================================================================================
//																							//
//									COMMAND: SPAWN DRONE									//
//																							//
//============================================================================================
public Action Cmd_SpawnDrone(int client, int args)
{
	if(args < 1)
	{
		CreateDrone(client, client);
		return Plugin_Handled;
	}

	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
		for(int i; i < target_count; i++) CreateDrone(client, target_list[i]);
	else ReplyToTargetError(client, target_count);

	return Plugin_Handled;
}

//============================================================================================
//																							//
//								CREATE DRONE(DRONE ASSEMBLY)								//
//																							//
//============================================================================================
stock Action CreateDrone(int client, int target)
{
#if defined _zr_included
	if(!ZR_IsClientHuman(client)) return Plugin_Handled;
#endif

	int dIndex = -1;

	char nameTarget[32];
	GetClientName(target, nameTarget, sizeof(nameTarget));

	float targetposition[3], targetangle[3];
	GetClientAbsOrigin(target, targetposition); targetposition[2] += 1.5;
	GetClientAbsAngles(target, targetangle);

	// If player is already in a drone, then just teleport that drone back to their activation location
	if(g_pInDrone[target] > -1 && IsValidEntity(g_Drone[g_pInDrone[target]]))
	{
		dIndex = g_pInDrone[target];

		float newpos[3]; newpos = g_pActivateLocation[target][0];
		newpos[2] += 40.0;

		ExitDrone(target, true);
		TeleportEntity(g_Drone[dIndex], newpos, g_pActivateLocation[target][1], NULL_VECTOR);

		EnterDrone(target, dIndex);
		if(target != client)
		{
			PrintToChat(client, "[SM] Put \"%s\" in a replacement drone", nameTarget);
			PrintToChat(target, "[SM] An admin put you in a new drone!");
		}

		return Plugin_Handled;
	}
	// If player is not in a drone, find a drone that is already assembled, if found, use that drone
	else for(int i, j; i < MAX_DRONES; i++) if(g_Drone[i] != -1 && IsValidEntity(g_Drone[i]))
	{
		for(j = 1; j <= MaxClients; j++)
		{
			if(g_pInDrone[j] == i)
				break;
			else if(j == MaxClients)
			{
				g_pActivateLocation[target][0] = targetposition;
				g_pActivateLocation[target][1] = targetangle;

				targetposition[2] += 40.0;
				TeleportEntity(g_Drone[i], targetposition, targetangle, NULL_VECTOR);

				EnterDrone(target, i);
				if(target != client)
				{
					PrintToChat(client, "[SM] Put \"%s\" in a drone", nameTarget);
					PrintToChat(target, "[SM] An admin put you in a drone!");
				}

				return Plugin_Handled;
			}
		}
	}

	// If there are no available already-assembled drones, then find out if we can make another one
	for(int i; i < MAX_DRONES; i++) if(g_Drone[i] == -1 || !IsValidEntity(g_Drone[i]))
	{
		dIndex = i;
		break;
	}
	// If max drones are assembled, and all drones are being used, then SORRY!!
	if(dIndex == -1)
	{
		PrintToChat(client, "[SM] All \x04[\x01%d\x04/\x01%d\x04]\x01 drones are currently being used!", MAX_DRONES, MAX_DRONES);
		return Plugin_Handled;
	}

	// Otherwise let's assemble a new drone

	//--------------------------------------------------------
	// **************** CREATE PHYSICS DRONE *****************
	//--------------------------------------------------------
	int drone = CreateEntityByName("prop_physics");

	char nameDrone[32];
	Format(nameDrone, sizeof(nameDrone), "%d_dronephysics_%d", drone, dIndex);
	DispatchKeyValue(drone, "targetname", nameDrone);

	DispatchKeyValue(drone, "model", MODEL_DRONE);

	char spawnflagsDrone[32];
	Format(spawnflagsDrone, sizeof(spawnflagsDrone), "%i", 256 | 512 | 1024); // +Use | Prevent pickup | Prevent motion on player bump
	DispatchKeyValue(drone, "spawnflags", spawnflagsDrone);

	if(DispatchSpawn(drone)) g_Drone[dIndex] = drone;

	//--------------------------------------------------------
	// ************** CREATE CONSTRAINT SYSTEM ***************
	//--------------------------------------------------------
	int constraintsystem = CreateEntityByName("phys_constraintsystem");

	char nameConstraintsys[32];
	Format(nameConstraintsys, sizeof(nameConstraintsys), "%d_csystem_%d", drone, dIndex);
	DispatchKeyValue(constraintsystem, "targetname", nameConstraintsys);

	if(DispatchSpawn(constraintsystem))
	{
		ActivateEntity(constraintsystem);
		ParentToEntity(constraintsystem, drone);
	}

	//--------------------------------------------------------
	// ************ CREATE KEEP UP RIGHT ENTITY **************
	//--------------------------------------------------------
	int keepupright = CreateEntityByName("phys_keepupright");

	DispatchKeyValue(keepupright, "angularlimit", "90.0");
	DispatchKeyValue(keepupright, "attach1", nameDrone);
	DispatchKeyValue(keepupright, "target", nameDrone);

	if(DispatchSpawn(keepupright))
	{
		ActivateEntity(keepupright);
		ParentToEntity(keepupright, drone);
		AcceptEntityInput(keepupright, "TurnOn");
	}

	//--------------------------------------------------------
	// ********** CREATE AND PLACE THRUST ENTITIES ***********
	//--------------------------------------------------------
	CreateThrustEntities(dIndex, drone);

	//--------------------------------------------------------
	// ********** CONSTRAIN THRUST PROPS TO DRONE ************
	//--------------------------------------------------------
	// *Constrained instead of parented to allow thruster push
	for(int i = 1; i < TOTAL_THRUSTERS-2; i++)
	{
		int thrustprop = GetEntPropEnt(g_DroneThrusts[dIndex][i], Prop_Data, "m_hMoveParent");
		if(IsValidEntity(thrustprop))
		{
			char nameThrustProp[32];
			GetEntPropString(thrustprop, Prop_Data, "m_iName", nameThrustProp, sizeof(nameThrustProp));

			ConstrainEntities(nameConstraintsys, nameThrustProp, nameDrone);
		}
	}

	//--------------------------------------------------------
	// ************* CREATE CAMERA VIEW CONROL ***************
	//--------------------------------------------------------
	int viewcontrol = CreateEntityByName("point_viewcontrol");

	char nameViewcontrol[32];
	Format(nameViewcontrol, sizeof(nameViewcontrol), "%d_droneview_%d", drone, dIndex);
	DispatchKeyValue(viewcontrol, "targetname", nameViewcontrol);
	DispatchKeyValue(viewcontrol, "m_hTarget", nameDrone);
	DispatchKeyValue(viewcontrol, "fov", "92.5");

	char spawnflagsViewcontrol[32];
	FormatEx(spawnflagsViewcontrol, sizeof(spawnflagsViewcontrol), "%i", 8 | 32 | 128); // Stay active | Nonsolid player | Set FOV
	DispatchKeyValue(viewcontrol, "spawnflags", spawnflagsViewcontrol);

	if(DispatchSpawn(viewcontrol))
	{
		g_DroneView[dIndex] = viewcontrol;
		ActivateEntity(viewcontrol);

		float viewpos[3], viewang[3];
		viewpos[0] -= 10.0;
		viewpos[2] -= 13.5;
		viewang[0] += 10.0;

		TeleportEntity(viewcontrol, viewpos, viewang, NULL_VECTOR);

		ParentToEntity(viewcontrol, drone);
	}

	//--------------------------------------------------------
	// ****************** CREATE GAME UI *********************
	//--------------------------------------------------------
	int gameui = CreateEntityByName("game_ui");

	char nameGameUI[32];
	Format(nameGameUI, sizeof(nameGameUI), "%d_droneui_%d", drone, dIndex);
	DispatchKeyValue(gameui, "targetname", nameGameUI);

	DispatchKeyValue(gameui, "FieldOfView", "-1.0");
	DispatchKeyValue(gameui, "spawnflags", "32"); // Freeze Player

	if(DispatchSpawn(gameui))
	{
		g_DroneUI[dIndex] = gameui;
		ActivateEntity(gameui);

		ParentToEntity(gameui, drone);

		// Hook all controls
		HookSingleEntityOutput(gameui, "PressedForward",	OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "UnpressedForward",	OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "PressedBack",		OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "UnpressedBack",		OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "PressedMoveLeft",	OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "UnpressedMoveLeft",	OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "PressedMoveRight",	OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "UnpressedMoveRight",OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "PressedAttack",		OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "UnpressedAttack",	OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "PressedAttack2",	OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "UnpressedAttack2",	OnGameUiButtonPress, false);
	}

	//--------------------------------------------------------
	// ************* CREATE ROTORS SOUND SOURCE **************
	//--------------------------------------------------------
	int sound = CreateEntityByName("ambient_generic");

	char nameSound[32];
	Format(nameSound, sizeof(nameSound), "%d_dronesound_%d", drone, dIndex);
	DispatchKeyValue(sound, "targetname", nameSound);

	DispatchKeyValue(sound, "message", SND_DRONE);
	DispatchKeyValue(sound, "SourceEntityName", nameDrone);
	DispatchKeyValue(sound, "radius", "1100.0");
	DispatchKeyValue(sound, "spawnflags", "16"); // Start silent

	if(DispatchSpawn(sound))
	{
		g_DroneSound[dIndex] = sound;
		ActivateEntity(sound);

		ParentToEntity(sound, drone);

		AcceptEntityInput(sound, "PlaySound");
		SetEntityInputFloat(sound, "Volume", 0.0);
		SetEntityInputInt(sound, "Pitch", 45);
	}

	//--------------------------------------------------------
	// ********* TELEPORT ASSEMBLED DRONE AT PLAYER **********
	//--------------------------------------------------------
	g_pActivateLocation[target][0] = targetposition;
	g_pActivateLocation[target][1] = targetangle;

	targetposition[2] += 40.0;
	TeleportEntity(drone, targetposition, targetangle, NULL_VECTOR);

	EnterDrone(target, dIndex);
	if(target != client)
	{
		PrintToChat(client, "[SM] Put \"%s\" in a drone", nameTarget);
		PrintToChat(target, "[SM] An admin put you in a drone!");
	}

	return Plugin_Handled;
}

//============================================================================================
//																							//
//																							//
//							CREATE ALL THRUST ENTITIES										//
//																							//
//============================================================================================
stock void CreateThrustEntities(int dIndex, int drone)
{
	float thrustang[3], thrustpos[3];
	char buffer[32];
	for(int i, thrustprop, thrust; i < TOTAL_THRUSTERS; i++)
	{	//--------------------------------------------------------
		// ************ CREATE THRUSTER PHYSICS PROPS ************
		//--------------------------------------------------------
		thrustprop = -1;
		if(i > 0 && i < TOTAL_THRUSTERS - 2)
		{
			thrustprop = CreateEntityByName("prop_physics");

			FormatEx(buffer, sizeof(buffer), "%d_thrustprop_%d", dIndex, i);
			DispatchKeyValue(thrustprop, "targetname", buffer);

			FormatEx(buffer, sizeof(buffer), "%i", 2 | 4 | 128 | 512 | 1024); // No Damage | No Collide | No Rotorwash | No Pickup | No Motion on Bump	1670
			DispatchKeyValue(thrustprop, "spawnflags", buffer);

			DispatchKeyValue(thrustprop, "model", MODEL_THRUSTER);
			DispatchKeyValue(thrustprop, "solid", "0");

			if(DispatchSpawn(thrustprop))
			{
				SetEntProp(thrustprop, Prop_Data, "m_CollisionGroup", 1);

				SetEntityRenderMode(thrustprop, RENDER_TRANSALPHA);
				SetEntityRenderColor(thrustprop, 255, 255, 255, 0);
			}
		}

		//--------------------------------------------------------
		// *************** CREATE THRUST ENTITIES ****************
		//--------------------------------------------------------
		if(i >= TOTAL_THRUSTERS - 2)
			thrust = CreateEntityByName("phys_torque"); // For rotation force
		else thrust = CreateEntityByName("phys_thruster"); // For linear force

		FormatEx(buffer, sizeof(buffer), "%d_thruster_%d", dIndex, i);
		DispatchKeyValue(thrust, "targetname", buffer);

		if(i == 6 || i == 7) FormatEx(buffer, sizeof(buffer), "%i", 4 | 8 | 16); // Torque(Rotation) | Local | Ignore Mass
		else FormatEx(buffer, sizeof(buffer), "%i", 2 | 8 | 16); // Linear | Local | Ignore Mass

		DispatchKeyValue(thrust, "spawnflags", buffer);
		DispatchKeyValue(thrust, "angles", "90 0 0");

		if(!i) { // 0: UPWARD
			DispatchKeyValue(thrust, "angles", "-90 0 0");
			DispatchKeyValue(thrust, "force", "1520");
		}
		else if(i == 1 || i == 2) { // 1: FORWARD - 2: FORWARD #2(Two to prevent turn)
			DispatchKeyValue(thrust, "force", "700");
			thrustpos[1] = (i == 1) ? -7.6 : 7.0;
			thrustpos[2] = 5.0;
			thrustang[0] = (i == 1) ? 4.0 : -4.0; //4.0 and -4.0 best so far
			thrustang[1] = -90.0;
			thrustang[2] = 90.0;
		}
		else if(i == 3) { // 3: BACKWARD
			DispatchKeyValue(thrust, "force", "1550");
			thrustpos[2] = 5.0;
			thrustang[1] = 90.0;
			thrustang[2] = 90.0;
		}
		else if(i == 4 || i == 5) { // 4: LEFT - 5: RIGHT
			DispatchKeyValue(thrust, "force", "2000");
			thrustpos[0] =(i == 4) ? -1.0 : -1.0; // RIGHT IS GOOD
			thrustpos[2] = 5.0;
			thrustang[2] =(i == 4) ? 95.0 : -95.0;
		}
		else if(i == 6 || i == 7) { // 6: TURN LEFT - 7: TURN RIGHT
			DispatchKeyValue(thrust, "axis",(i == 6) ? "0 0 90" : "0 0 -90");

			g_cvTurnForce.GetString(buffer, sizeof(buffer));
			DispatchKeyValue(thrust, "force", buffer);
		}

		if(DispatchSpawn(thrust))
		{
			g_DroneThrusts[dIndex][i] = thrust;

			if(i == 0 || i == 6 || i == 7)	// These 3 don't need a physics prop to push the drone
			{
				SetEntPropEnt(thrust, Prop_Data, "m_attachedObject", drone);
				ParentToEntity(thrust, drone);
			}
			else	// The rest do
			{
				SetEntPropEnt(thrust, Prop_Data, "m_attachedObject", thrustprop);
				ParentToEntity(thrust, thrustprop);

				TeleportEntity(thrustprop, thrustpos, thrustang, NULL_VECTOR);
			}
		}
	}
}

//============================================================================================
//																							//
//									DRONE HANDLING											//
//																							//
//============================================================================================
//--------------------------------------------------------
// ***************** PLAYER ENTER DRONE ******************
//--------------------------------------------------------
stock Action EnterDrone(int client, int dIndex)
{
	if(IsValidEntity(client) && IsPlayerAlive(client) && dIndex > -1 && g_Drone[dIndex] > 0
	&& IsValidEntity(g_Drone[dIndex]))
	{	// Reset timers
		g_pFireMissileTimer[client] = GetGameTime() - 1.0;
		g_pGeneralTimer[client] = GetGameTime();

		// Delay weapon use and render player invisible
		SetWeaponDelay(client, 960.0);
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
		SetEntityRenderMode(client, RENDER_NONE);

		// Activate Viewcontrol
		AcceptEntityInput(g_DroneView[dIndex], "Enable", client);

		// Activate the UI
		AcceptEntityInput(g_DroneUI[dIndex], "Activate", client);

		// Scale rotor sound
		SetEntityInputFloat(g_DroneSound[dIndex], "Volume", 10.0);
		SetEntityInputInt(g_DroneSound[dIndex], "Pitch", 110);

		// Ensure color and collision
		SetEntityRenderColor(g_Drone[dIndex], 255, 255, 255, 255);
		SetEntProp(g_Drone[dIndex], Prop_Data, "m_CollisionGroup", 0);

		// Record player in drone and reset view
		g_pInDrone[client] = dIndex;

	}
	return Plugin_Handled;
}

//--------------------------------------------------------
// ***************** PLAYER EXIT DRONE *******************
//--------------------------------------------------------
stock Action ExitDrone(int client, bool explode)
{
	int dIndex = g_pInDrone[client];
	if(IsValidEntity(client) && dIndex > -1 && IsValidEntity(g_Drone[dIndex]))
	{	// Deactivate the Viewcontrol
		AcceptEntityInput(g_DroneView[dIndex], "Disable");

		// Deactivate the UI
		AcceptEntityInput(g_DroneUI[dIndex], "Deactivate");

		// Make sure player is properly removed from above two ents
		SetClientViewEntity(client, client);
		int flags = GetEntityFlags(client);
		flags &= ~FL_ONTRAIN;
		flags &= ~FL_FROZEN;
		flags &= ~FL_ATCONTROLS;
		SetEntityFlags(client, flags);

		// Reset player weapon delay and return to activation location
		TeleportEntity(client, g_pActivateLocation[client][0], g_pActivateLocation[client][1], NULL_VECTOR);
		SetWeaponDelay(client, 0.5);
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
		SetEntityRenderMode(client, RENDER_NORMAL);

		// Deactivate the thrusters
		for(int i; i < TOTAL_THRUSTERS; i++) AcceptEntityInput(g_DroneThrusts[dIndex][i], "Deactivate");

		// Scale rotor sound
		SetEntityInputFloat(g_DroneSound[dIndex], "Volume", 0.0);
		SetEntityInputInt(g_DroneSound[dIndex], "Pitch", 0);

		// Invisible and nonsolid the drone
		SetEntityRenderMode(g_Drone[dIndex], RENDER_TRANSALPHA);
		SetEntityRenderColor(g_Drone[dIndex], 255, 255, 255, 0);
		SetEntProp(g_Drone[dIndex], Prop_Data, "m_CollisionGroup", 1);

		// Create gib explosion where the drone was unless disabled
		if(explode && g_cvSelfDestruct.BoolValue)
		{
			float pos[3], ang[3];
			GetEntPropVector(g_Drone[dIndex], Prop_Send, "m_vecOrigin", pos);
			GetEntPropVector(g_Drone[dIndex], Prop_Send, "m_angRotation", ang);

			CreateDroneExplosion(client, pos, ang);
		}

		// Record player no longer in drone
		g_pInDrone[client] = -1;

	}
	return Plugin_Handled;
}

//--------------------------------------------------------
// *************** ALL PLAYERS EXIT DRONES ***************
//--------------------------------------------------------
stock void ExitAllDrones()
{
	for(int i = 1; i <= MaxClients; i++) if(g_pInDrone[i] > -1) ExitDrone(i, false);
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	OnClientDisconnect(client);
}

//--------------------------------------------------------
// ************ CREATE A DRONE GIB EXPLOSION *************
//--------------------------------------------------------
stock void CreateDroneExplosion(int owner, float pos[3], float ang[3])
{
	for(int i, gib; i < 4; i++) if((gib = CreateEntityByName("prop_physics")) != -1)
	{
		DispatchKeyValue(gib, "model", DRONE_GIBS[i]);

		if(DispatchSpawn(gib))
		{
			TeleportEntity(gib, pos, ang, NULL_VECTOR);
			CreateTimer(6.0, TimerDeleteEntity, EntIndexToEntRef(gib));
		}
	}

	CreateExplosion(owner, pos, "15.0", SND_DRONE_BREAK);
}

//============================================================================================
//																							//
//								HOOK DRONE CONTROLS											//
//																							//
//============================================================================================
//--------------------------------------------------------
// ********* FW/BW/RIGHT/LEFT/MISSILES WITH OUTPUT ***********
//--------------------------------------------------------
public void OnGameUiButtonPress(const char[] output, int caller, int activator, float delay)
{
	int dIndex = g_pInDrone[activator];

	if(StrEqual(output, "PressedForward", false))
	{
		AcceptEntityInput(g_DroneThrusts[dIndex][1], "Activate");
		AcceptEntityInput(g_DroneThrusts[dIndex][2], "Activate");
	}
	else if(StrEqual(output, "UnpressedForward", false))
	{
		AcceptEntityInput(g_DroneThrusts[dIndex][1], "Deactivate");
		AcceptEntityInput(g_DroneThrusts[dIndex][2], "Deactivate");
	}
	else if(StrEqual(output, "PressedBack", false))
		AcceptEntityInput(g_DroneThrusts[dIndex][3], "Activate");
	else if(StrEqual(output, "UnpressedBack", false))
		AcceptEntityInput(g_DroneThrusts[dIndex][3], "Deactivate");
	else if(StrEqual(output, "PressedMoveLeft", false))
		AcceptEntityInput(g_DroneThrusts[dIndex][4], "Activate");
	else if(StrEqual(output, "UnpressedMoveLeft", false))
		AcceptEntityInput(g_DroneThrusts[dIndex][4], "Deactivate");
	else if(StrEqual(output, "PressedMoveRight", false))
		AcceptEntityInput(g_DroneThrusts[dIndex][5], "Activate");
	else if(StrEqual(output, "UnpressedMoveRight", false))
		AcceptEntityInput(g_DroneThrusts[dIndex][5], "Deactivate");
	else if(StrEqual(output, "PressedAttack", false))
		AcceptEntityInput(g_DroneThrusts[dIndex][6], "Activate");
	else if(StrEqual(output, "UnpressedAttack", false))
		AcceptEntityInput(g_DroneThrusts[dIndex][6], "Deactivate");
	else if(StrEqual(output, "PressedAttack2", false))
		AcceptEntityInput(g_DroneThrusts[dIndex][7], "Activate");
	else if(StrEqual(output, "UnpressedAttack2", false))
		AcceptEntityInput(g_DroneThrusts[dIndex][7], "Deactivate");
}

//--------------------------------------------------------
// ******* EXIT/UP/DOWN/MISSILES WITH ONGAMEFRAME ********
//--------------------------------------------------------
public void OnGameFrame()
{
	for(int i = 1, pilot, dIndex, keypress; i <= MaxClients; i++) if(IsClientInGame(i) && IsPlayerAlive(i))
	{	// Not in drone
		if(g_pInDrone[i] < 0)
			SetEntityRenderMode(i, RENDER_NORMAL); //sad attempt to restore enemy visibility glitch
		// In drone
		else
		{
			pilot = i;
			dIndex = g_pInDrone[pilot];
			keypress = GetClientButtons(pilot);

			// Delay weapon always
			SetWeaponDelay(pilot, 1.0);

			if(g_Drone[dIndex] > 0 && IsValidEntity(g_Drone[dIndex]))
			{	// DUCK, Half scale the upwards thruster and rotor spin
				if(keypress & IN_DUCK)
				{
					SetEntityInputFloat(g_DroneThrusts[dIndex][0], "Scale", 0.5);
					AcceptEntityInput(g_DroneThrusts[dIndex][0], "Activate");

					SetEntityInputInt(g_DroneSound[dIndex], "Pitch", 85);
				}
				// JUMP, Full scale the upwards thruster and rotor spin
				if(keypress & IN_JUMP)
				{
					SetEntityInputFloat(g_DroneThrusts[dIndex][0], "Scale", 1.0);
					AcceptEntityInput(g_DroneThrusts[dIndex][0], "Activate");

					SetEntityInputInt(g_DroneSound[dIndex], "Pitch", 110);
				}
				// IF NEITHER, Set cruising scale upwards thruster and rotor spin
				if(!(keypress & IN_DUCK) && !(keypress & IN_JUMP))
				{
					SetEntityInputFloat(g_DroneThrusts[dIndex][0], "Scale", 0.75);
					AcceptEntityInput(g_DroneThrusts[dIndex][0], "Activate");

					SetEntityInputInt(g_DroneSound[dIndex], "Pitch", 95);
				}

				/************************************/

				// USE, Exit Drone
				if((keypress & IN_USE) && GetGameTime() - g_pGeneralTimer[pilot] >= 0.75)
				{
					ExitDrone(pilot, true);
					continue;
				}

				// SHIFT, Switch camera position between above/below
				if(keypress & IN_SPEED &&(GetGameTime() - g_pGeneralTimer[pilot] >= 0.75))
				{
					ExitDrone(pilot, false);
					AcceptEntityInput(g_DroneView[dIndex], "ClearParent");

					float viewpos[3], viewang[3], direction[3];
					GetEntPropVector(g_DroneView[dIndex], Prop_Send, "m_vecOrigin", viewpos);
					GetEntPropVector(g_DroneView[dIndex], Prop_Send, "m_angRotation", viewang);

					// Ensure drone has the correct view setting, and alternate accordingly
					g_DroneSelectedView[dIndex] =(viewang[0] > 12.0) ? 0 : 1;

					// This stays up here
					if(g_DroneSelectedView[dIndex] == 1) viewang[0] += 12.5;

					GetAngleVectors(viewang, direction, NULL_VECTOR, NULL_VECTOR);
					if(g_DroneSelectedView[dIndex] == 1) NegateVector(direction);
					ScaleVector(direction, 60.0);
					AddVectors(viewpos, direction, viewpos);

					GetAngleVectors(viewang, NULL_VECTOR, NULL_VECTOR, direction);
					if(g_DroneSelectedView[dIndex] == 0) NegateVector(direction);
					ScaleVector(direction, 55.0);
					AddVectors(viewpos, direction, viewpos);

					// This stays down here
					if(!g_DroneSelectedView[dIndex]) viewang[0] -= 12.5;

					TeleportEntity(g_DroneView[dIndex], viewpos, viewang, NULL_VECTOR);
					ParentToEntity(g_DroneView[dIndex], g_Drone[dIndex]);

					EnterDrone(pilot, dIndex);
					continue;
				}

				/************************************/

				// MOUSE1 + MOUSE2 -or- RELOAD, Fire missiles
				if((keypress & IN_ATTACK && keypress & IN_ATTACK2 || keypress & IN_RELOAD)
				&& GetGameTime() - g_pFireMissileTimer[pilot] >= g_cvReloadInterval.FloatValue)
				{
					// Reset the reload timer
					g_pFireMissileTimer[pilot] = GetGameTime();
			
					float dronepos[3], droneang[3];
					GetEntPropVector(g_Drone[dIndex], Prop_Send, "m_vecOrigin", dronepos);
					GetEntPropVector(g_Drone[dIndex], Prop_Send, "m_angRotation", droneang); droneang[0] += 12.0;

					int trackcount = 3, tracks[3];
					float missileTracks[3][3], spawnpos[3], movepos[3], direction[3];

					// Alternate left/right wing missile launch
					GetAngleVectors(droneang, NULL_VECTOR, direction, NULL_VECTOR);
					if(g_pAlternateFire[pilot]) NegateVector(direction);
					g_pAlternateFire[pilot] =(g_pAlternateFire[pilot]) ? false : true;

					// FIRST TRACK - Placed at the spawn position of the firing side based on the condition above
					ScaleVector(direction, 13.0);
					AddVectors(dronepos, direction, spawnpos);
					spawnpos[2] = spawnpos[2] - 10.0;
					missileTracks[0] = spawnpos;

					// Is there a target in sight?(if homing enabled)
					char nameTarget[32];
					int target = -1;

					if(g_cvHomingEnabled.BoolValue) target = FindMissileTarget(pilot, spawnpos);

					if(target > 0 && target <= MaxClients && IsValidEntity(target) && IsPlayerAlive(target))
					{
						// Give target unambigous name
						FormatEx(nameTarget, sizeof(nameTarget), "%d_missiletarget", target);
						DispatchKeyValue(target, "targetname", nameTarget);

						float targetpos[3];
						GetClientEyePosition(target, targetpos);

						// Draw target marker
						TE_SetupBeamRingPoint(targetpos, 50.0, 125.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.4, 10.0, 0.5, {255, 0, 0, 255}, 15, 0);
						TE_SendToClient(pilot, 0.0);

						// SECOND TRACK(TARGET) - Placed on target. This track will move with the target
						missileTracks[1] = targetpos;

						// THIRD TRACK(TARGET) - Placement should be irrelevant for homing. Ensures "OnPass" callback on previous track
						targetpos[2] -= 75.0;
						missileTracks[2] = targetpos;

						// Play fired sound, homing missile
						EmitSoundToAll(SND_ROCKET_FIRED_HOMING, g_Drone[dIndex]);
					}
					else
					{
						// SECOND TRACK(NO TARGET) - Placed at MAX DISTANCE, to ensure explosion/deletion of missile
						droneang[0] =(g_DroneSelectedView[dIndex] == 0) ? 10.0 : 17.5; // firing angle based on view position
						GetAngleVectors(droneang, direction, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(direction, g_cvMissileDistance.FloatValue);
						AddVectors(dronepos, direction, movepos);
						missileTracks[1] = movepos;

						// THIRD TRACK(NO TARGET) - Placed past track to avoid train rotation. This ensures a callback on "OnPass" output
						GetAngleVectors(droneang, direction, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(direction, g_cvMissileDistance.FloatValue+100.0);
						AddVectors(dronepos, direction, movepos);
						missileTracks[2] = movepos;

						// Player fired sound, non-homing missile
						EmitSoundToAll(SND_ROCKET_FIRED, g_Drone[dIndex]);
					}

					// Give unambiguous names to prevent parenting error
					char nameTrack[32], nameFirstTrack[32], namePrevTrack[32], nameTrain[32], nameMissile[32];
					FormatEx(nameFirstTrack, sizeof(nameFirstTrack), "%d_%f_dmtrack_0", target, GetGameTime()/2);
					FormatEx(nameTrain, sizeof(nameTrain), "%d_%f_dmtrain", target, GetGameTime()/2);
					FormatEx(nameMissile, sizeof(nameMissile), "%d_%f_dmissile", target, GetGameTime()/2);

					// Create the missiles tracktrain
					int tracktrain = CreateMissileTrain(pilot, nameTrain, nameFirstTrack);

					// Create the missiles path tracks
					for(int j = trackcount-1; j >= 0; j--)
					{
						FormatEx(nameTrack, sizeof(nameTrack), "%d_%f_dmtrack_%d", target, GetGameTime()/2, j);
						tracks[j] = CreateMissilePath(pilot, nameTrack, missileTracks[j], namePrevTrack);

						// Homing missile
						if(j !=(trackcount - 1) && target > 0 && target <= MaxClients) {
							int measuremove = CreateEntityByName("logic_measure_movement");

							DispatchKeyValue(measuremove, "MeasureType", "1"); // Aim for head
							DispatchKeyValue(measuremove, "MeasureTarget",(j == 1) ? nameTarget : nameTrain);
							DispatchKeyValue(measuremove, "MeasureReference", nameTarget);
							DispatchKeyValue(measuremove, "TargetReference", nameTarget);
							DispatchKeyValue(measuremove, "Target", nameTrack);

							if(DispatchSpawn(measuremove)) {
								ActivateEntity(measuremove);
								AcceptEntityInput(measuremove, "Enable");

								// Keep parenting heirarchy for removal on missile explode
								ParentToEntity(tracks[j], measuremove);
								ParentToEntity(measuremove, tracktrain);
							}
						}
						else ParentToEntity(tracks[j], tracktrain);

						strcopy(namePrevTrack, sizeof(namePrevTrack), nameTrack);
					}

					// Create the missile
					int missileprop = CreateMissileProp(nameMissile);
					ParentToEntity(missileprop, tracktrain);

					// Create the missiles smoke trail
					int smoketrail = CreateMissileTrail(GetClientTeam(pilot));
					ParentToEntity(smoketrail, missileprop);

					// Hook train OnNextPoint output and Hook collision path "OnPass" output
					HookSingleEntityOutput(tracktrain, "OnNextPoint", OnMissileFrame, false);
					HookSingleEntityOutput(tracks[1], "OnPass", OnPassCollisionTrack, false);

				}
			}
		}
	}
}

//============================================================================================
//																							//
//								MISSILE HANDLING											//
//																							//
//============================================================================================
//--------------------------------------------------------
// *********** FIND A TARGET FOR HOMING MISSILE **********
//--------------------------------------------------------
stock int FindMissileTarget(int client, float startpos[3])
{

	int target = -1;
	float lastDistance = g_cvHomingDistance.FloatValue + 5.0, // A little passed max, just in case
		targetpos[3], distance, rayend[3], rayang[3], direction[3], newvec[3];

	for(int i = 1, t = GetClientTeam(client); i <= MaxClients; i++)
		if(i != client && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != t)
		{	// Do not target clients in the same team
			GetClientEyePosition(i, targetpos);
			distance = GetVectorDistance(startpos, targetpos);
			// If the distance is less than any previous targets while looping, then consider this player as possible target and run traceray
			if(distance >= 50.0 && distance < lastDistance)
			{	// Get the angle from the missile spawn position to the possible targets face
				SubtractVectors(targetpos, startpos, newvec);
				NormalizeVector(newvec, newvec);
				GetVectorAngles(newvec, rayang);

				GetAngleVectors(rayang, direction, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(direction, g_cvHomingDistance.FloatValue);
				AddVectors(startpos, direction, rayend);

				// Send a traceray, if there is nothing directly blocking the path, select player as target, and record distance for next player check
				TR_TraceRayFilter(startpos, rayend, MASK_SOLID, RayType_EndPoint, TraceRayFilterFindTarget, client);
				if(TR_DidHit(INVALID_HANDLE) && TR_GetEntityIndex() > 0 && TR_GetEntityIndex() <= MaxClients)
				{
					target = TR_GetEntityIndex();
					lastDistance = distance;
				}
			}
		}

	return target > 0 && target <= MaxClients ? target : -1;
}

//--------------------------------------------------------
// ****************** CREATE THE MISSILE *****************
//--------------------------------------------------------
stock int CreateMissileProp(const char[] name)
{
	int missile = CreateEntityByName("prop_dynamic");

	DispatchKeyValue(missile, "targetname", name);
	DispatchKeyValue(missile, "solid", "0");

	DispatchKeyValue(missile, "model", MODEL_MISSILE);
	DispatchKeyValue(missile, "modelscale", "4.0");

	if(DispatchSpawn(missile)) SetEntityRenderColor(missile, 220, 120, 0, 255);

	return missile;
}

//--------------------------------------------------------
// *********** CREATE THE MISSILES SMOKE TRAIL ***********
//--------------------------------------------------------
stock int CreateMissileTrail(int team)
{
	int smoketrail = CreateEntityByName("env_rockettrail");

	SetEntPropFloat(smoketrail, Prop_Send, "m_StartSize", 1.0);
	SetEntPropFloat(smoketrail, Prop_Send, "m_EndSize", 3.5);
	SetEntPropFloat(smoketrail, Prop_Send, "m_MinSpeed", 3.0);
	SetEntPropFloat(smoketrail, Prop_Send, "m_MaxSpeed", 9.0);
	SetEntPropVector(smoketrail,Prop_Send, "m_StartColor",(team == 3) ? view_as<float>({0.35, 0.35, 0.75}) : view_as<float>({0.75, 0.3, 0.3}));
	SetEntPropFloat(smoketrail, Prop_Send, "m_Opacity", 0.4);
	SetEntPropFloat(smoketrail, Prop_Send, "m_SpawnRate", 25.0);
	SetEntPropFloat(smoketrail, Prop_Send, "m_SpawnRadius", 1.0);
	SetEntPropFloat(smoketrail, Prop_Send, "m_ParticleLifetime", 0.4);
	SetEntPropFloat(smoketrail, Prop_Send, "m_flFlareScale", 0.5);

	if(DispatchSpawn(smoketrail)) ActivateEntity(smoketrail);

	return smoketrail;
}

//--------------------------------------------------------
// ********* CREATE THE PATHWAY FOR THE MISSILE **********
//--------------------------------------------------------
stock int CreateMissilePath(int client, const char[] name, const float pos[3], const char[] nexttarget)
{
	int path = CreateEntityByName("path_track");

	DispatchKeyValue(path, "targetname", name);
	DispatchKeyValue(path, "target", nexttarget);

	DispatchKeyValue(path, "spawnflags", "2"); // Fire once

	if(DispatchSpawn(path))
	{
		ActivateEntity(path);
		TeleportEntity(path, pos, NULL_VECTOR, NULL_VECTOR);
	}

	return path;
}

//--------------------------------------------------------
// ***** CREATE THE TRAIN THE MISSILE WILL MOVE WITH *****
//--------------------------------------------------------
stock int CreateMissileTrain(int client, const char[] name, const char[] firstpath)
{
	int tracktrain = CreateEntityByName("func_tracktrain");

	DispatchKeyValue(tracktrain, "targetname", name);
	DispatchKeyValue(tracktrain, "target", firstpath);

	SetEntPropEnt(tracktrain, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(tracktrain, Prop_Send, "m_fEffects", 32);

	char buffer[16];
	FormatEx(buffer, sizeof(buffer), "%i", 2 | 8 | 512); // No control | No collision | Not blockable
	DispatchKeyValue(tracktrain, "spawnflags", buffer);

	char speed[32];
	g_cvMissileSpeed.GetString(speed, sizeof(speed));

	int fStartspeed = RoundFloat((StringToFloat(speed)/2));
	IntToString(fStartspeed, buffer, sizeof(buffer));

	DispatchKeyValue(tracktrain, "startspeed", buffer);
	DispatchKeyValue(tracktrain, "speed", speed);

	DispatchKeyValue(tracktrain, "orientationtype", "3");
	DispatchKeyValue(tracktrain, "MoveSound", SND_ROCKET_FLY);
	DispatchKeyValue(tracktrain, "volume", "10");
	DispatchKeyValue(tracktrain, "wheels", "300");

	DispatchSpawn(tracktrain);

	return tracktrain;
}

//--------------------------------------------------------
// ********** HOOK ON PASS PATH TO EXPLODE AT ************
//--------------------------------------------------------
public void OnPassCollisionTrack(const char[] output, int track, int train, float delay)
{	/* NOTE: "OnPass" does not get called on the last path_track, so we add an additional "dummy" path_track to ensure targets track gets fired*/
	if(IsValidEntity(train) && IsValidEntity(track))
	{
		float explodepos[3];
		GetEntPropVector(train, Prop_Send, "m_vecOrigin", explodepos);

		// Explode on pass
		int pilot = GetEntPropEnt(train, Prop_Send, "m_hOwnerEntity");
		CreateExplosion(pilot, explodepos, "500.0", SND_ROCKET_EXPLODE);

		// Kill the entire track train system for this missile
		AcceptEntityInput(train, "Stop");
		AcceptEntityInput(train, "KillHierarchy");
	}
}

//--------------------------------------------------------
// ********* HOOK EVERY FRAME THE MISSILE MOVES **********
//--------------------------------------------------------
public void OnMissileFrame(const char[] output, int train, int track, float delay)
{
	if(IsValidEntity(train) && IsValidEntity(track))
	{
		int pilot = GetEntPropEnt(train, Prop_Send, "m_hOwnerEntity");
		if(!IsValidEntity(pilot)) return;

		int missile = GetEntPropEnt(train, Prop_Data, "m_hMoveChild");
		if(!IsValidEntity(missile)) return;

		float missilepos[3];
		GetEntPropVector(train, Prop_Send, "m_vecOrigin", missilepos);

		static const float mins[] = {-2.0, -2.0, -1.5}, maxs[] = {2.0, 2.0, 1.5};

		DataPack dp = CreateDataPack();
		WritePackCell(dp, pilot);
		WritePackCell(dp, missile);
		WritePackCell(dp, train);

		TR_TraceHullFilter(missilepos, missilepos, mins, maxs, MASK_SHOT, TraceHullFilterMissile, dp);
		if(TR_DidHit(INVALID_HANDLE))
		{
			float hitpos[3];
			TR_GetEndPosition(hitpos);

			// Explode on collision
			CreateExplosion(pilot, hitpos, "500.0", SND_ROCKET_EXPLODE);

			// Kill the entire track train system for this missile
			AcceptEntityInput(train, "Stop");
			AcceptEntityInput(train, "KillHierarchy");
		}
		delete dp;
	}
}

//--------------------------------------------------------
// ****************** EXPLOSION CREATION *****************
//--------------------------------------------------------
stock int CreateExplosion(int owner, const float pos[3], const char[] damageforce, const char[] sound)
{
	int explosion = CreateEntityByName("env_explosion");

	char damage[32], radius[32];
	g_cvMissileDamage.GetString(damage, sizeof(damage));
	g_cvMissileRadius.GetString(radius, sizeof(radius));

	DispatchKeyValue(explosion, "iMagnitude", damage);
	DispatchKeyValue(explosion, "iRadiusOverride", radius);
	DispatchKeyValue(explosion, "DamageForce", damageforce);
	DispatchKeyValue(explosion, "rendermode", "5");

	char spawnflags[16];
	FormatEx(spawnflags, sizeof(spawnflags), "%i", 64 | 128 | 256 | 2048); // No Sound | Random Orient | No Smoke | Dont Clamp Min
	DispatchKeyValue(explosion, "spawnflags", spawnflags);

	if(DispatchSpawn(explosion))
	{
		if(IsValidEntity(owner))
		{
			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", owner);
			if(owner > 0 && owner <= MaxClients)
				SetEntProp(explosion, Prop_Send, "m_iTeamNum", GetClientTeam(owner));
		}

		TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);

		ActivateEntity(explosion);

		AcceptEntityInput(explosion, "Explode");
		EmitSoundToAll(sound, explosion);

		// Delete explosion to prevent rapid re-fire
		CreateTimer(0.7, TimerDeleteEntity, EntIndexToEntRef(explosion));
	}

	return explosion;
}

//--------------------------------------------------------
// *************** TIMED ENTITY DELETEIONS ***************
//--------------------------------------------------------
stock Action TimerDeleteEntity(Handle timer, int entref)
{
	if(IsValidEntRef(entref)) AcceptEntityInput(EntRefToEntIndex(entref), "Kill");
}

//============================================================================================
//																							//
//								TRACE FILTERS												//
//																							//
//============================================================================================
//--------------------------------------------------------
// ************* TRACERAY FILTER ACTIVATOR ***************
//--------------------------------------------------------
public bool TraceRayFilterActivator(int entityAtPoint, int mask, any client)
{
	return entityAtPoint != client;
}

//--------------------------------------------------------
//****** TRACERAY FILTER TARGET FINDING OBSTACLES ********
//--------------------------------------------------------
public bool TraceRayFilterFindTarget(int entityAtPoint, int mask, any client)
{
	if(entityAtPoint > 0 && entityAtPoint <= MaxClients && entityAtPoint != client)
		return true;

	int dIndex = g_pInDrone[client];
	if(dIndex > -1 && entityAtPoint == g_Drone[dIndex])
		return false;

	if(entityAtPoint == client)
		return false;

	return false;
}

//--------------------------------------------------------
// ********* TRACERAY FILTER MISSILE OBSTACLES ***********
//--------------------------------------------------------
public bool TraceHullFilterMissile(int touched, int mask, DataPack data)
{
	data.Reset();
	int client	= data.ReadCell();
	int missile	= data.ReadCell();
	int train	= data.ReadCell();
	int dIndex	= g_pInDrone[client];

	if(dIndex < 0)
		return false;

	if(touched == client || touched == missile || touched == train || touched == g_Drone[dIndex])
		return false;

	return true;
}

//============================================================================================
//																							//
//								ENTITY UTILITIES											//
//																							//
//============================================================================================
stock bool IsValidEntRef(int entref)
{
	return entref != -1 && IsValidEntity(EntRefToEntIndex(entref)) && EntRefToEntIndex(entref) != INVALID_ENT_REFERENCE;
}

/************************************/

stock void SetWeaponDelay(int client, float delay)
{
	if(client > 0 && client <= MaxClients && IsValidEntity(client) && IsClientInGame(client))
	{
		int pWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(pWeapon != -1 && IsValidEntity(pWeapon))
		{
			SetEntPropFloat(pWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + delay);
			SetEntPropFloat(pWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + delay);
		}
	}
}

/************************************/

stock bool ParentToEntity(int child, int parent)
{
	SetVariantEntity(parent);
	return AcceptEntityInput(child, "SetParent");
}

/************************************/

stock int ConstrainEntities(const char[] nameconstraintsys, const char[] nameentity1, const char[] nameentity2)
{
	/* An Alternative to parenting to allow physics interaction */
	int constraint = CreateEntityByName("phys_constraint");

	DispatchKeyValue(constraint, "constraintsystem", nameconstraintsys);

	DispatchKeyValue(constraint, "attach1", nameentity1);
	DispatchKeyValue(constraint, "attach2", nameentity2);

	DispatchKeyValue(constraint, "teleportfollowdistance", "0.0");
	DispatchKeyValue(constraint, "forcelimit", "0");
	DispatchKeyValue(constraint, "torquelimit", "0");

	if(DispatchSpawn(constraint))
	{
		ActivateEntity(constraint);
		AcceptEntityInput(constraint, "TurnOn");
	}

	return constraint;
}

/************************************/

stock bool SetEntityInputInt(int entity, char[] input, int value)
{
	SetVariantInt(value);
	return AcceptEntityInput(entity, input);
}

stock bool SetEntityInputFloat(int entity, char[] input, float value)
{
	SetVariantFloat(value);
	return AcceptEntityInput(entity, input);
}

stock bool SetEntityInputString(int entity, char[] input, char[] value)
{
	SetVariantString(value);
	return AcceptEntityInput(entity, input);
}