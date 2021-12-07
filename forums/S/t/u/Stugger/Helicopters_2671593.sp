#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Stugger"
#define PLUGIN_VERSION "2.0"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Helicopters",
	author = PLUGIN_AUTHOR,
	description = "Spawn pilotable helicopters capabale of firing homing missiles",
	version = PLUGIN_VERSION,
	url = ""
};

char GAME[16];

#define SPRITE_HALO "materials/sprites/halo01.vmt"
#define SPRITE_BEAM "materials/sprites/laserbeam.vmt"
 
#define SOUND_HELI_LOCKED "player/suit_denydevice.wav" // All 3 games

char MODEL_CSGO_PHYSICS[72] = "models/props/de_boathouse/stealthboat.mdl";
char MODEL_HELICOPTER[72] = "models/combine_helicopter.mdl";
char MODEL_THRUSTER[72] = "models/props_junk/popcan01a.mdl";
char MODEL_MISSILE[72] = "models/weapons/w_missile_closed.mdl";

char SOUND_HELI_ROTOR[72] = "#/npc/attack_helicopter/aheli_rotor_loop1.wav";
char SOUND_ROCKET_FIRED[72] = "weapons/rpg/rocketfire1.wav"; 
char SOUND_ROCKET_FIRED_HOMING[72] = "weapons/stinger_fire1.wav";
char SOUND_ROCKET_FLY[72] = "weapons/rpg/rocket1.wav";
char SOUND_ROCKET_EXPLODE[72] = "weapons/mortar/mortar_explode1.wav";

float TEAMCOLOR_RED[3] = { 0.75, 0.3, 0.3 };
float TEAMCOLOR_BLUE[3] = { 0.35, 0.35, 0.75 };
float TEAMCOLOR_GREY[3] = { 0.4, 0.4, 0.4 };

int g_BeamSprite;
int g_HaloSprite;

/************************************/

#define MAX_HELIS 8
#define TOTAL_THRUSTERS 7 // dont change

ConVar g_cvReloadInterval;
ConVar g_cvMissileDamage;
ConVar g_cvMissileSpeed;
ConVar g_cvMissileDistance;
ConVar g_cvHomingEnabled;
ConVar g_cvHomingDistance;

/************************************/

int g_Helicopter[MAX_HELIS] = {-1, ...};
int g_HelicopterShell[MAX_HELIS] = {-1, ...};
int g_HelicopterThrusts[MAX_HELIS][TOTAL_THRUSTERS];
int g_HelicopterView[MAX_HELIS] = { -1, ... };
int g_HelicopterUI[MAX_HELIS] = {-1, ...};
int g_HelicopterSound[MAX_HELIS] = {-1, ...};

/************************************/

int g_pInHelicopter[MAXPLAYERS + 1] = {-1, ...};

float g_pMissileTimer[MAXPLAYERS + 1];
float g_pExitTimer[MAXPLAYERS + 1];

bool g_pAlternateFire[MAXPLAYERS + 1];

/************************************/

//--------------------------------------------------------
// ******************* ON PLUGIN START *******************
//--------------------------------------------------------
public void OnPluginStart()
{
	/***** COMMANDS ******/
	RegAdminCmd("sm_helicopter", Cmd_SpawnHeli, ADMFLAG_CHEATS, "Spawn a pilotable helicopter capabale of firing homing missiles");
	//RegAdminCmd("sm_helicopter_delete", Cmd_DeleteHeli, ADMFLAG_CHEATS, "<1-8|all>|raypoint - Delete the specified or targeted helicopter");
	
	
	/***** CONVARS ******/
	g_cvReloadInterval = CreateConVar("sm_helicopter_missile_interval", "1.2", "The reload interval for all helicopter missiles");
	
	g_cvMissileDamage = CreateConVar("sm_helicopter_missile_damage", "55", "Controls the damage of all helicopter missiles");
	g_cvMissileSpeed = CreateConVar("sm_helicopter_missile_speed", "1100", "Controls the travel speed of all helicopter missiles");
	g_cvMissileDistance = CreateConVar("sm_helicopter_missile_distance", "8000.0", "Controls the max distance for regular missiles before self detonation");
	
	g_cvHomingEnabled = CreateConVar("sm_helicopter_homing_enabled", "1", "Enable or disable the use of homing missiles");
	g_cvHomingDistance = CreateConVar("sm_helicopter_homing_distance", "4000.0", "Controls the max distance and enemy can be to be targeted by homing missiles");
	
	
	/***** GAME SPECIFIC ******/
	char GameFolder[32];
	GetGameFolderName(GameFolder, sizeof(GameFolder));
	
	// CSGO
	if (StrContains(GameFolder, "csgo", false) != -1) {
		GAME = "csgo";
	
		MODEL_HELICOPTER = "models/props_vehicles/helicopter_rescue.mdl";
		MODEL_THRUSTER = "models/props/cs_office/trash_can_p8.mdl";
		MODEL_MISSILE = "models/props/de_inferno/hr_i/missile/missile_02.mdl";
		
		SOUND_HELI_ROTOR = "#/vehicles/loud_helicopter_lp_01.wav";
		SOUND_ROCKET_FIRED = "survival/missile_land_01.wav";
		SOUND_ROCKET_FIRED_HOMING = "survival/missile_land_04.wav";
		SOUND_ROCKET_FLY = "ambient/nuke/vent_02.wav";
		SOUND_ROCKET_EXPLODE = "weapons/c4/c4_explode1.wav";
		
		HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
		HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
		HookEvent("cs_win_panel_round", OnRoundEnd, EventHookMode_PostNoCopy);
		HookEvent("round_freeze_end", OnRoundEnd, EventHookMode_PostNoCopy);
	}
	//  CSS
	else if (StrContains(GameFolder, "cstrike", false) != -1) {
		GAME = "cstrike";

		HookEvent("cs_win_panel_round", OnRoundEnd, EventHookMode_PostNoCopy);
		HookEvent("round_freeze_end", OnRoundEnd, EventHookMode_PostNoCopy);
	}
	// HL2DM
	else {
		GAME = "hl2mp";
	}
	
	// ALL
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

//--------------------------------------------------------
// ******************** ON MAP START *********************
//--------------------------------------------------------
public void OnMapStart()
{
	if (StrEqual(GAME, "csgo")) 
		PrecacheModel(MODEL_CSGO_PHYSICS, true);
	PrecacheModel(MODEL_HELICOPTER, true);
	PrecacheModel(MODEL_THRUSTER, true);
	PrecacheModel(MODEL_MISSILE, true);
	
	g_HaloSprite = PrecacheModel(SPRITE_HALO, true);
	g_BeamSprite = PrecacheModel(SPRITE_BEAM, true);
	
	PrecacheSound(SOUND_HELI_ROTOR, true);
	PrecacheSound(SOUND_HELI_LOCKED, true);
	PrecacheSound(SOUND_ROCKET_FIRED, true);
	PrecacheSound(SOUND_ROCKET_FIRED_HOMING, true);
	PrecacheSound(SOUND_ROCKET_FLY, true);
	PrecacheSound(SOUND_ROCKET_EXPLODE, true);
	
	for (int i = 0; i < MAX_HELIS; i++) {
		g_Helicopter[i] = -1;
		g_HelicopterShell[i] = -1;
		g_HelicopterView[i] = -1;
		g_HelicopterUI[i] = -1;
		g_HelicopterSound[i] = -1;
		
		for (int j = 0; j < TOTAL_THRUSTERS; j++) {
	 		g_HelicopterThrusts[i][j] = -1;
		}
	}	
	for (int i = 1; i <= MAXPLAYERS; i++) {
		g_pInHelicopter[i] = -1;
	}
}

//--------------------------------------------------------
// ******************* ON ROUND START ********************
//--------------------------------------------------------
public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	ExitAllHelicopters();
	
	for (int i = 0; i < MAX_HELIS; i++) {
		if (g_Helicopter[i] != -1 && IsValidEntity(g_Helicopter[i]))
	 			AcceptEntityInput(g_Helicopter[i], "Kill");
		g_Helicopter[i] = -1;
		
		if (g_HelicopterShell[i] != -1 && IsValidEntity(g_HelicopterShell[i]))
	 			AcceptEntityInput(g_HelicopterShell[i], "Kill");
		g_HelicopterShell[i] = -1;
		
		if (g_HelicopterView[i] != -1 && IsValidEntity(g_HelicopterView[i]))
	 			AcceptEntityInput(g_HelicopterView[i], "Kill");
		g_HelicopterView[i] = -1;		

		if (g_HelicopterUI[i] != -1 && IsValidEntity(g_HelicopterUI[i]))
	 			AcceptEntityInput(g_HelicopterUI[i], "Kill");
		g_HelicopterUI[i] = -1;
		
		if (g_HelicopterSound[i] != -1 && IsValidEntity(g_HelicopterSound[i]))
	 			AcceptEntityInput(g_HelicopterSound[i], "Kill");
		g_HelicopterSound[i] = -1;
		
		for (int j = 0; j < TOTAL_THRUSTERS; j++) {
			if (g_HelicopterThrusts[i][j] != -1 && IsValidEntity(g_HelicopterThrusts[i][j]))
	 			AcceptEntityInput(g_HelicopterThrusts[i][j], "Kill");
	 			
	 		g_HelicopterThrusts[i][j] = -1;
		}
	}	
}
//--------------------------------------------------------
// ********************* ON MAP END **********************
//--------------------------------------------------------
public void OnMapEnd()
{
	ExitAllHelicopters();
	
	for (int i = 0; i < MAX_HELIS; i++) {
		SDKUnhook(g_Helicopter[i], SDKHook_Use, OnHeliUse);
	}
} 

//--------------------------------------------------------
// ******************** ON ROUND END *********************
//--------------------------------------------------------
public void OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	ExitAllHelicopters();
	
	for (int i = 0; i < MAX_HELIS; i++) {
		SDKUnhook(g_Helicopter[i], SDKHook_Use, OnHeliUse);
	}
}  

//--------------------------------------------------------
// **************** ON CLIENT DISCONNECT *****************
//--------------------------------------------------------
public void OnClientDisconnect(int client)
{
	if (g_pInHelicopter[client] > -1)
		ExitHelicopter(client, g_pInHelicopter[client]);
}

//============================================================================================
//																							//
//					COMMAND: SPAWN HELICOPTER - HELICOPTER ASSEMBLY							//
//																							//
//============================================================================================
public Action Cmd_SpawnHeli(int client, int args)
{	
	int hIndex = -1;
	
	for (int i = 0; i < MAX_HELIS; i++) {
		if (g_Helicopter[i] < 0 || !IsValidEntity(g_Helicopter[i])) {
			hIndex = i;
			break;
		}
	}
	if (hIndex == -1) {
		PrintToChat(client, "[SM] The helicopter spawn limit \x04[\x01%d\x04/\x01%d\x04]\x01 has been reached.", MAX_HELIS, MAX_HELIS);
		return Plugin_Handled;
	}

	//--------------------------------------------------------
	// *********** CREATE PHYSICS (CORE) HELICOPTER **********
	//--------------------------------------------------------
	int heli = CreateEntityByName("prop_physics_override");
	
	char nameHeli[32];
	Format(nameHeli, sizeof(nameHeli), "%d_helicopter_%d", heli, hIndex);
	DispatchKeyValue(heli, "targetname", nameHeli);

	char spawnflagsHeli[32];
	Format(spawnflagsHeli, sizeof(spawnflagsHeli), "%i", 256 | 512 | 1024); // +Use | Prevent pickup | Prevent motion on bump
	DispatchKeyValue(heli, "spawnflags", spawnflagsHeli);
	
	DispatchKeyValue(heli, "model", (!StrEqual(GAME, "csgo")) ? MODEL_HELICOPTER : MODEL_CSGO_PHYSICS);
	DispatchKeyValue(heli, "massscale", "0.85");
	DispatchKeyValue(heli, "inertiascale", "0.85");
	
	if (DispatchSpawn(heli)) {
		g_Helicopter[hIndex] = heli;
		
		// Invisible as this is only the physical core
		SetEntityRenderMode(heli, RENDER_TRANSALPHA);
		SetEntityRenderColor(heli, 255, 255, 255, 0);	
	
		SDKHook(heli, SDKHook_Use, OnHeliUse);
	}
	
	//--------------------------------------------------------
	// ********** CREATE DYNAMIC (VISUAL) HELICOPTER *********
	//--------------------------------------------------------
	int shell = CreateEntityByName("prop_dynamic");
	
	char nameShell[32];
	Format(nameShell, sizeof(nameShell), "%d_hshell_%d", heli, hIndex);
	DispatchKeyValue(shell, "targetname", nameShell);
	
	DispatchKeyValue(shell, "model", MODEL_HELICOPTER);
	if (StrEqual(GAME, "csgo"))
		DispatchKeyValue(shell, "modelscale", "0.72");
	
	if (DispatchSpawn(shell)) {
		g_HelicopterShell[hIndex] = shell;
		
		float shellpos[3], shellang[3];
		shellpos[0] = (!StrEqual(GAME, "csgo")) ? 0.0 : 42.0;
		shellpos[2] = (!StrEqual(GAME, "csgo")) ? -27.0 : -48.0;
		shellang[0] = (!StrEqual(GAME, "csgo")) ? -10.0 : 0.0;
		
		TeleportEntity(shell, shellpos, shellang, NULL_VECTOR);
		
		SetEntityInputString(shell, "SetAnimation", (StrEqual(GAME, "csgo")) ? "fly_generic" : "idle");
		SetEntityInputFloat(shell, "SetPlaybackRate", 0.0);
		
		ParentToEntity(shell, heli);
	}
	
	//--------------------------------------------------------
	// ************** CREATE CONSTRAINT SYSTEM ***************
	//--------------------------------------------------------
	int constraintsystem = CreateEntityByName("phys_constraintsystem");
	
	char nameConstraintsys[32];
	Format(nameConstraintsys, sizeof(nameConstraintsys), "%d_csystem_%d", heli, hIndex);
	DispatchKeyValue(constraintsystem, "targetname", nameConstraintsys);
	
	if (DispatchSpawn(constraintsystem)) {
		ActivateEntity(constraintsystem);
		
		ParentToEntity(constraintsystem, heli);
	}
	
	//--------------------------------------------------------
	// ************ CREATE KEEP UP RIGHT ENTITY **************
	//--------------------------------------------------------
	int keepupright = CreateEntityByName("phys_keepupright");

	DispatchKeyValue(keepupright, "angularlimit", "30.0");
	DispatchKeyValue(keepupright, "attach1", nameHeli);
	DispatchKeyValue(keepupright, "target", nameHeli);
	
	if (DispatchSpawn(keepupright)) {
		ActivateEntity(keepupright);
		
		ParentToEntity(keepupright, heli);
	
		AcceptEntityInput(keepupright, "TurnOn");
	}
	
	//--------------------------------------------------------
	// ********** CREATE AND PLACE THRUST ENTITIES ***********
	//--------------------------------------------------------
	CreateThrustEntities(hIndex, heli);
	
	//--------------------------------------------------------
	// ******** CONSTRAIN THRUST PROPS TO HELICOPTER *********
	//--------------------------------------------------------
	// *Constrained instead of parented to allow thruster push
	for (int i = 1; i < TOTAL_THRUSTERS-2; i++) {
		int thrustprop = GetEntPropEnt(g_HelicopterThrusts[hIndex][i], Prop_Data, "m_hMoveParent");

		char nameThrustProp[32];
		GetEntPropString(thrustprop, Prop_Data, "m_iName", nameThrustProp, sizeof(nameThrustProp));
		
		ConstrainEntities(nameConstraintsys, nameThrustProp, nameHeli);
	}
	
	//--------------------------------------------------------
	// ************** MAKE CAMERA VIEW CONROL ****************
	//--------------------------------------------------------
	int viewcontrol = CreateEntityByName("point_viewcontrol");
	
	char nameViewcontrol[32];
	Format(nameViewcontrol, sizeof(nameViewcontrol), "%d_heliview_%d", heli, hIndex);
	DispatchKeyValue(viewcontrol, "nameview", nameViewcontrol);
	DispatchKeyValue(viewcontrol, "m_hTarget", nameHeli);
	
	char spawnflagsViewcontrol[32];
	FormatEx(spawnflagsViewcontrol, sizeof(spawnflagsViewcontrol), "%i", 8 | 32); // Stay active | Nonsolid player
	DispatchKeyValue(viewcontrol, "spawnflags", spawnflagsViewcontrol);
	
	if (DispatchSpawn(viewcontrol)) {
		g_HelicopterView[hIndex] = viewcontrol;
		ActivateEntity(viewcontrol);
		
		float viewpos[3], viewang[3];
		viewpos[0] -= 125.0;
		viewpos[2] += 270.0;
		viewang[0] += 32.0;
		TeleportEntity(viewcontrol, viewpos, viewang, NULL_VECTOR);
		
		ParentToEntity(viewcontrol, shell);
	}

	//--------------------------------------------------------
	// ****************** CREATE GAME UI *********************
	//--------------------------------------------------------
	int gameui = CreateEntityByName("game_ui");

	char nameGameUI[32];
	Format(nameGameUI, sizeof(nameGameUI), "%d_heliui_%d", heli, hIndex);
	DispatchKeyValue(gameui, "targetname", nameGameUI);
	
	DispatchKeyValue(gameui, "FieldOfView", "-1.0");
	
	char spawnflagsGameUI[32];
	FormatEx(spawnflagsGameUI, sizeof(spawnflagsGameUI), "%i", 32 | 64 ); // Freeze player | Hide weapon
	DispatchKeyValue(gameui, "spawnflags", spawnflagsGameUI);
	
	if (DispatchSpawn(gameui)) {
		g_HelicopterUI[hIndex] = gameui;
		ActivateEntity(gameui);
		
		ParentToEntity(gameui, shell);
		
		// Hook all controls
		HookSingleEntityOutput(gameui, "PressedForward", OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "UnpressedForward", OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "PressedBack", OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "UnpressedBack", OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "PressedMoveLeft", OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "UnpressedMoveLeft", OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "PressedMoveRight", OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "UnpressedMoveRight", OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "PressedAttack", OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "UnpressedAttack", OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "PressedAttack2", OnGameUiButtonPress, false);
		HookSingleEntityOutput(gameui, "UnpressedAttack2", OnGameUiButtonPress, false);
	}
	
	//--------------------------------------------------------
	// ************** CREATE ROTOR SOUND SOURCE **************
	//--------------------------------------------------------
	int sound = CreateEntityByName("ambient_generic");

	char nameSound[32];
	Format(nameSound, sizeof(nameSound), "%d_helisound_%d", heli, hIndex);
	DispatchKeyValue(sound, "targetname", nameSound);
	
	DispatchKeyValue(sound, "message", SOUND_HELI_ROTOR);
	DispatchKeyValue(sound, "SourceEntityName", nameShell);
	DispatchKeyValue(sound, "radius", "1750.0");
	DispatchKeyValue(sound, "spawnflags", "16");
	
	if(DispatchSpawn(sound)) {
		g_HelicopterSound[hIndex] = sound;
		ActivateEntity(sound);
		
		ParentToEntity(sound, heli);
		
		AcceptEntityInput(sound, "PlaySound");
		SetEntityInputFloat(sound, "Volume", 0.0);
		SetEntityInputInt(sound, "Pitch", 45);
	}
	
	//--------------------------------------------------------
	// ************ TELEPORT ASSEMBLED HELICOPTER ************
	//--------------------------------------------------------
	// FIXME: Replace with TraceHull to make sure it wont get stuck when spawned
	float raypos[3], clientEyepos[3], clientEyeangle[3];
	GetClientEyePosition(client, clientEyepos);
	GetClientEyeAngles(client, clientEyeangle);

	TR_TraceRayFilter(clientEyepos, clientEyeangle, MASK_SOLID, RayType_Infinite, TraceRayFilterActivator, client);
	if (TR_DidHit(INVALID_HANDLE))
		TR_GetEndPosition(raypos);
	
	raypos[2] += 100.0;
	
	TeleportEntity(heli, raypos, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
} 

//============================================================================================
//																							//
//																							//
//							CREATE ALL THRUST ENTITIES										//
//																							//
//============================================================================================
stock void CreateThrustEntities(int hIndex, int heli)
{
	for (int i = 0; i < TOTAL_THRUSTERS; i++) {
		//--------------------------------------------------------
		// ************ CREATE THRUSTER PHYSICS PROPS ************
		//--------------------------------------------------------
		int thrustprop = -1;
		
		if (i > 0 && i < TOTAL_THRUSTERS - 2) {
			thrustprop = CreateEntityByName("prop_physics");

			char nameThrustProp[32];
			Format(nameThrustProp, sizeof(nameThrustProp), "%d_thrustprop_%d", heli, i);
			DispatchKeyValue(thrustprop, "targetname", nameThrustProp);
			
			char spawnflagsThrustProp[32];
			Format(spawnflagsThrustProp, sizeof(spawnflagsThrustProp), "%i", 2 | 4 | 128 | 512); // No Damage | No Collide | No Rotorwash | No Pickup
			DispatchKeyValue(thrustprop, "spawnflags", spawnflagsThrustProp);
			
			DispatchKeyValue(thrustprop, "model", MODEL_THRUSTER);
			DispatchKeyValue(thrustprop, "massscale", "25.0");
			DispatchKeyValue(thrustprop, "solid", "0");
			
			if (DispatchSpawn(thrustprop)) {
				SetEntityRenderMode(thrustprop, RENDER_TRANSALPHA);
				SetEntityRenderColor(thrustprop, 255, 255, 255, 0);
			}
		}
		
		//--------------------------------------------------------
		// *************** CREATE THRUST ENTITIES ****************
		//--------------------------------------------------------
		float thrustang[3], thrustpos[3];
		int thrust;
		
		if (i >= TOTAL_THRUSTERS - 2)
			thrust = CreateEntityByName("phys_torque"); // For rotation force
		else
			thrust = CreateEntityByName("phys_thruster"); // For linear force

		char nameThrust[32];
		Format(nameThrust, sizeof(nameThrust), "%d_thruster_%d", heli, i);
		DispatchKeyValue(thrust, "targetname", nameThrust);
		
		char spawnflagsThrust[32];
		if (i == 5 || i == 6) Format(spawnflagsThrust, sizeof(spawnflagsThrust), "%i", 4 | 8 | 16); // Torque(Rotation) | Local | Ignore Mass
		else Format(spawnflagsThrust, sizeof(spawnflagsThrust), "%i", 2 | 8 | 16); // Linear | Local | Ignore Mass
		
		DispatchKeyValue(thrust, "spawnflags", spawnflagsThrust);
		
		DispatchKeyValue(thrust, "angles", "90 0 0");
		
		if (i == 0) { // UPWARD
			char upforce[16];
			if (StrEqual(GAME, "csgo"))
				upforce = "1200";
			else if (StrEqual(GAME, "hl2mp"))
				upforce = "800";
			else if (StrEqual(GAME, "cstrike"))
				upforce = "1100";
				
			DispatchKeyValue(thrust, "angles", "-90 0 0");
			DispatchKeyValue(thrust, "force", upforce);
		}
		else if (i == 1 || i == 2) { // 1: FORWARD - 2: BACKWARD
			DispatchKeyValue(thrust, "force", (StrEqual(GAME, "csgo")) ? "2300" : "9300");
			thrustpos[0] = -135.0;
			thrustpos[2] = 25.0;
			thrustang[1] = (i == 1) ? -90.0 : 90.0;
			thrustang[2] = 90.0;
		}
		else if (i == 3 || i == 4) { // 3: LEFT - 4: RIGHT
			DispatchKeyValue(thrust, "force", (StrEqual(GAME, "csgo")) ? "2300" : "9300");
			thrustpos[0] = (!StrEqual(GAME, "csgo")) ? 10.0 : -40.0;
			thrustpos[1] = (i == 3) ? -17.0 : 17.0;
			thrustpos[2] = 75.0;
			thrustang[2] = (i == 3) ? 95.0 : -95.0;
		}
		else if (i == 5 || i == 6) { // 5: TURN LEFT - 6: TURN RIGHT
			DispatchKeyValue(thrust, "axis", (i == 5) ? "0 0 90" : "0 0 -90");
			DispatchKeyValue(thrust, "force", "60");
		}			
		
		if(DispatchSpawn(thrust)) {
			g_HelicopterThrusts[hIndex][i] = thrust;
			
			if (i == 0 || i == 5 || i == 6) { // These 3 don't need a physics prop to push the heli
				SetEntPropEnt(thrust, Prop_Data, "m_attachedObject", heli);	
				ParentToEntity(thrust, heli);
			}
			else { // The rest do
				SetEntPropEnt(thrust, Prop_Data, "m_attachedObject", thrustprop);
				ParentToEntity(thrust, thrustprop);
				
				TeleportEntity(thrustprop, thrustpos, thrustang, NULL_VECTOR);
			}
		}
	}
}

//============================================================================================
//																							//
//								HELICOPTER HANDLING											//
//																							//
//============================================================================================
//--------------------------------------------------------
// ************** HOOK ON PLAYER PRESS USE ***************
//--------------------------------------------------------
public Action OnHeliUse(int heli, int client, int caller, UseType type, float value) 
{
	char targetname[64];
	GetEntPropString(heli, Prop_Data, "m_iName", targetname, sizeof(targetname)); TrimString(targetname);
	
	// Get the index of the helicopter from its name
	char shIndex[16];
	if(IsCharNumeric(targetname[strlen(targetname)-2]))
		StrCat(shIndex, sizeof(shIndex), targetname[strlen(targetname) - 2]);
	StrCat(shIndex, sizeof(shIndex), targetname[strlen(targetname) - 1]); TrimString(shIndex);
	
	int hIndex = StringToInt(shIndex);
	
	// No more than one player per helicopter (Incorporate a gunner position allowing two players per?)
	for(int i = 1; i <= MaxClients; i++) {
		if (i != client && g_pInHelicopter[i] == hIndex) {
			EmitSoundToClient(client, SOUND_HELI_LOCKED);
			PrintToChat(client, "[SM] That helicopter is taken!");
			return Plugin_Handled;
		}
	}
	
	// If no one is in the helicopter and player is not already in a helicopter, then enter the selected helicopter
	if(g_Helicopter[hIndex] > 0 && IsValidEntity(g_Helicopter[hIndex]) && IsClientInGame(client) && IsPlayerAlive(client) && g_pInHelicopter[client] < 0)
		EnterHelicopter(client, hIndex);

	return Plugin_Handled;
}

//--------------------------------------------------------
// *************** PLAYER ENTER HELICOPTER ***************
//--------------------------------------------------------
stock Action EnterHelicopter(int client, int hIndex)
{
	if (IsValidEntity(client) && hIndex > -1 && g_Helicopter[hIndex] > 0 && IsValidEntity(g_Helicopter[hIndex])) {
		float helipos[3], heliang[3], direction[3], ridepos[3];
		GetEntPropVector(g_Helicopter[hIndex], Prop_Send, "m_vecOrigin", helipos); 
		GetEntPropVector(g_Helicopter[hIndex], Prop_Send, "m_angRotation", heliang);
		
		// Reset heli timers
		g_pMissileTimer[client] = GetGameTime() - 1.0;
		g_pExitTimer[client] = GetGameTime();
		
		// Get the player parent position
		if (!StrEqual(GAME, "csgo")) heliang[0] += 25.0;
		// Upwards
		GetAngleVectors(heliang, NULL_VECTOR, NULL_VECTOR, direction);
		ScaleVector(direction, (StrEqual(GAME, "csgo")) ? 75.0 : 60.0);
		AddVectors(helipos, direction, ridepos);
		// Forwards
		GetAngleVectors(heliang, direction, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(direction, (StrEqual(GAME, "csgo")) ? 125.0 : 30.0);
		AddVectors(ridepos, direction, ridepos);
		
		// Parent player to helicopter
		TeleportEntity(client, ridepos, NULL_VECTOR, NULL_VECTOR);
		ParentToEntity(client, g_Helicopter[hIndex]);
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
		SetEntityRenderMode(client, RENDER_TRANSALPHA);
		SetEntityRenderColor(client, 255, 255, 255, 0);
		
		// Activate Viewcontrol
		AcceptEntityInput(g_HelicopterView[hIndex], "Enable", client, -1);
		
		// Activate the UI
		AcceptEntityInput(g_HelicopterUI[hIndex], "Activate", client, -1);
		
		// Record player in helicopter
		g_pInHelicopter[client] = hIndex;
		
		// Helicopter Wind Up "Animation"
		DataPack pack;
		CreateDataTimer(0.1, Timer_HeliAnimate, pack);
		pack.WriteString("u");
		pack.WriteCell(hIndex);
		pack.WriteFloat(0.85/35.0);
		pack.WriteFloat(10.0/35.0);
		pack.WriteCell(47);
		
	}
	return Plugin_Handled;
}
//--------------------------------------------------------
// **************** PLAYER EXIT HELICOPTER ***************
//--------------------------------------------------------
stock Action ExitHelicopter(int client, int hIndex)
{
	if (IsValidEntity(client) && hIndex > -1 && g_HelicopterShell[hIndex] > 0 && IsValidEntity(g_HelicopterShell[hIndex])) {
		float shellpos[3], shellang[3];
		GetEntPropVector(g_HelicopterShell[hIndex], Prop_Send, "m_vecOrigin", shellpos);
		GetEntPropVector(g_HelicopterShell[hIndex], Prop_Send, "m_angRotation", shellang);
		
		// Deactivate the Viewcontrol
		AcceptEntityInput(g_HelicopterView[hIndex], "Disable");
		
		// Deactivate the UI
		AcceptEntityInput(g_HelicopterUI[hIndex], "Deactivate");
		
		// Unparent the player from the helicopter
		AcceptEntityInput(client, "ClearParent");
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		// Deactivate the thrusters
		for (int i = 0; i < TOTAL_THRUSTERS; i++) {
			AcceptEntityInput(g_HelicopterThrusts[hIndex][i], "Deactivate");
		}
		
		g_pInHelicopter[client] = -1;
		
		// Helicopter Wind Down "Animation"
		DataPack pack;
		CreateDataTimer(0.1, Timer_HeliAnimate, pack);
		pack.WriteString("d");
		pack.WriteCell(hIndex);
		pack.WriteFloat(0.85);
		pack.WriteFloat(10.0); 
		pack.WriteCell(115);

	}
	return Plugin_Handled;
}
//--------------------------------------------------------
// ************* ALL PLAYERS EXIT HELICOPTERS ************
//--------------------------------------------------------
stock void ExitAllHelicopters()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (g_pInHelicopter[i] > -1)
			ExitHelicopter(i, g_pInHelicopter[i]);
	}
}

//--------------------------------------------------------
// ********* "ANIMATE" HELICOPTER POWER UP/DOWN **********
//--------------------------------------------------------
stock Action Timer_HeliAnimate(Handle timer, DataPack pack) 
{
	/* NOTE: Maybe just remove this feature as it is pretty much just extra processing with no real benefit other than visual */
	
	char mode[2];
	int hIndex, pitchScale;
	float animScale, volScale;
	
	pack.Reset();
	pack.ReadString(mode, sizeof(mode));
	hIndex = pack.ReadCell();
	animScale = pack.ReadFloat();
	volScale = pack.ReadFloat();
	pitchScale = pack.ReadCell();
		
	if (hIndex < 0 || g_HelicopterShell[hIndex] == -1 || !IsValidEntity(g_HelicopterShell[hIndex]))
		return Plugin_Handled;
		
	float shellpos[3], shellang[3];
	GetEntPropVector(g_HelicopterShell[hIndex], Prop_Send, "m_vecOrigin", shellpos);
	GetEntPropVector(g_HelicopterShell[hIndex], Prop_Send, "m_angRotation", shellang);
	
	// Position/Angle the shell to stance
	shellpos[2] = (mode[0] == 'u') ? shellpos[2] + (27.0 / 35.0) : shellpos[2] - (27.0 / 35.0);
	shellang[0] = (mode[0] == 'u') ? shellang[0] + (10.0 / 35.0) : shellang[0] - (10.0 / 35.0);
	
	TeleportEntity(g_HelicopterShell[hIndex], shellpos, shellang, NULL_VECTOR);
	
	// Scale rotor spin speed
	SetEntityInputFloat(g_HelicopterShell[hIndex], "SetPlaybackRate", animScale);
		
	// Scale rotor sound 
	SetEntityInputFloat(g_HelicopterSound[hIndex], "Volume", volScale);
	SetEntityInputInt(g_HelicopterSound[hIndex], "Pitch", pitchScale);
	
	// Ending condition
	if (mode[0] == 'u' && pitchScale == 115)
		return Plugin_Handled;
	else if (mode[0] == 'd' && pitchScale == 47)
		return Plugin_Handled;
		
	// Recurse
	DataPack newData;
	CreateDataTimer(0.1, Timer_HeliAnimate, newData);
	newData.WriteString(mode);
	newData.WriteCell(hIndex);
	newData.WriteFloat((mode[0] == 'u') ? animScale + (0.85 / 35.0) : animScale - (0.85 / 35.0));
	newData.WriteFloat((mode[0] == 'u') ? volScale + (10.0 / 35.0) : volScale - (10.0 / 35.0));
	newData.WriteCell((mode[0] == 'u') ? pitchScale + 2 : pitchScale - 2);
	
	return Plugin_Handled;
}

/*
//--------------------------------------------------------
// ***************** DELETE HELICOPTER *******************
//--------------------------------------------------------
//FIXME : THIS "WORKS" BUT SPAWNING A HELICOPTER AFTER DELETING ONE CRASHES SERVER? SOMETIMES IT'S THE SECOND HELICOPTER SPAWNED THAT CRASHES?

stock void KillHelicopter(int hIndex) 
{
	if (g_Helicopter[hIndex] != -1 && IsValidEntity(g_Helicopter[hIndex])) {
		for (int i = 1; i <= MaxClients; i++) {
			if (g_pInHelicopter[i] == hIndex) {
				ExitHelicopter(i, hIndex);
				break;
			}
		}
		
		// Just in case
		SDKUnhook(g_Helicopter[hIndex], SDKHook_Use, OnHeliUse);
		
		for (int i = 0; i < TOTAL_THRUSTERS; i++) {
			if (g_HelicopterThrusts[hIndex][i] > 0 && IsValidEntity(g_HelicopterThrusts[hIndex][i])) {
				int can = GetEntPropEnt(g_HelicopterThrusts[hIndex][i], Prop_Data, "m_hMoveParent");
				
				if (can > -1 && IsValidEntity(can))
					AcceptEntityInput(can, "Kill");
				
				g_HelicopterThrusts[hIndex][i] = -1;
			}
		}
		
		// Everything but thrust entities are parented to helicopter, so this will kill most everything
		AcceptEntityInput(g_Helicopter[hIndex], "KillHierarchy");
		
		g_Helicopter[hIndex] = -1;
		g_HelicopterShell[hIndex] = -1;
		g_HelicopterUI[hIndex] = -1;
		g_HelicopterView[hIndex] = -1;
		g_HelicopterSound[hIndex] = -1;
	}	
}
*/
//============================================================================================
//																							//
//						HOOK HELICOPTER CONTROLS											//
//																							//
//============================================================================================
//--------------------------------------------------------
// ********* FW/BW/RIGHT/LEFT/TURN WITH OUTPUT ***********
//--------------------------------------------------------
public void OnGameUiButtonPress(const char[] output, int caller, int activator, float delay)
{
	int hIndex = g_pInHelicopter[activator];
		
	if (StrEqual(output, "PressedForward", false))
		AcceptEntityInput(g_HelicopterThrusts[hIndex][1], "Activate");
	else if (StrEqual(output, "UnpressedForward", false))
		AcceptEntityInput(g_HelicopterThrusts[hIndex][1], "Deactivate");
	else if (StrEqual(output, "PressedBack", false))
		AcceptEntityInput(g_HelicopterThrusts[hIndex][2], "Activate");
	else if (StrEqual(output, "UnpressedBack", false))
		AcceptEntityInput(g_HelicopterThrusts[hIndex][2], "Deactivate");
	else if (StrEqual(output, "PressedMoveLeft", false))
		AcceptEntityInput(g_HelicopterThrusts[hIndex][3], "Activate");
	else if (StrEqual(output, "UnpressedMoveLeft", false))
		AcceptEntityInput(g_HelicopterThrusts[hIndex][3], "Deactivate");
	else if (StrEqual(output, "PressedMoveRight", false))
		AcceptEntityInput(g_HelicopterThrusts[hIndex][4], "Activate");
	else if (StrEqual(output, "UnpressedMoveRight", false))
		AcceptEntityInput(g_HelicopterThrusts[hIndex][4], "Deactivate");
	else if (StrEqual(output, "PressedAttack", false))
		AcceptEntityInput(g_HelicopterThrusts[hIndex][5], "Activate");
	else if (StrEqual(output, "UnpressedAttack", false))
		AcceptEntityInput(g_HelicopterThrusts[hIndex][5], "Deactivate");
	else if (StrEqual(output, "PressedAttack2", false))
		AcceptEntityInput(g_HelicopterThrusts[hIndex][6], "Activate");
	else if (StrEqual(output, "UnpressedAttack2", false))
		AcceptEntityInput(g_HelicopterThrusts[hIndex][6], "Deactivate");

}
//--------------------------------------------------------
// ******* EXIT/UP/DOWN/MISSILES WITH ONGAMEFRAME ********
//--------------------------------------------------------
public void OnGameFrame() 
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidEntity(i) && !IsPlayerAlive(i) && g_pInHelicopter[i] > -1)
			ExitHelicopter(i, g_pInHelicopter[i]);
			
		else if (IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && g_pInHelicopter[i] > -1) {
			int pilot = i;
			int keypress = GetClientButtons(pilot);
			int hIndex = g_pInHelicopter[pilot];
			
			if (g_Helicopter[hIndex] > 0 && IsValidEntity(g_Helicopter[hIndex])) {
				// USE, EXIT HELICOPTER
				if ((keypress & IN_USE) && (GetGameTime() - g_pExitTimer[pilot] >= 0.75)) {
					ExitHelicopter(pilot, hIndex);
					continue;
				}
				// DUCK, Half scale the upwards thruster and rotor spin
				if (keypress & IN_DUCK) {
					//AcceptEntityInput(g_HelicopterThrusts[hIndex][0], "Deactivate");
					SetEntityInputFloat(g_HelicopterThrusts[hIndex][0], "Scale", 0.5);
					AcceptEntityInput(g_HelicopterThrusts[hIndex][0], "Activate");
					
					SetEntityInputFloat(g_HelicopterShell[hIndex], "SetPlaybackRate", 0.50);
					SetEntityInputInt(g_HelicopterSound[hIndex], "Pitch", 85);
				}
				// JUMP, Full scale the upwards thruster and rotor spin
				if (keypress & IN_JUMP) {
					SetEntityInputFloat(g_HelicopterThrusts[hIndex][0], "Scale", 1.0);
					AcceptEntityInput(g_HelicopterThrusts[hIndex][0], "Activate");
					
					SetEntityInputFloat(g_HelicopterShell[hIndex], "SetPlaybackRate", 0.95);
					SetEntityInputInt(g_HelicopterSound[hIndex], "Pitch", 110);
				}
				// IF NEITHER, Set cruising scale upwards thruster and rotor spin
				if (!(keypress & IN_DUCK) && !(keypress & IN_JUMP)) {
					SetEntityInputFloat(g_HelicopterThrusts[hIndex][0], "Scale", 0.75);
					AcceptEntityInput(g_HelicopterThrusts[hIndex][0], "Activate");
					
					SetEntityInputFloat(g_HelicopterShell[hIndex], "SetPlaybackRate", 0.75);
					SetEntityInputInt(g_HelicopterSound[hIndex], "Pitch", 95);
				}
				
				// MOUSE1 + MOUSE2 -or- RELOAD, Fire missiles
				if (((keypress & IN_ATTACK) && (keypress & IN_ATTACK2) || (keypress & IN_RELOAD)) && (GetGameTime() - g_pMissileTimer[pilot] >= g_cvReloadInterval.FloatValue)) {
					// Reset the reload timer
					g_pMissileTimer[pilot] = GetGameTime(); 
			
					float helipos[3], heliang[3];
					GetEntPropVector(g_Helicopter[hIndex], Prop_Send, "m_vecOrigin", helipos);
					GetEntPropVector(g_Helicopter[hIndex], Prop_Send, "m_angRotation", heliang);

					int trackcount = 3, tracks[3];
					float vecTracks[3][3], spawnpos[3], movepos[3], direction[3];
					
					// Alternate left/right wing missile launch
					GetAngleVectors(heliang, NULL_VECTOR, direction, NULL_VECTOR);	
					if (g_pAlternateFire[pilot]) NegateVector(direction);
					g_pAlternateFire[pilot] = (g_pAlternateFire[pilot]) ? false : true;
						
					// FIRST TRACK - Placed at the spawn position of the firing wing based on the condition above
					ScaleVector(direction, (StrEqual(GAME, "csgo")) ? 70.0 : 93.0); 
					AddVectors(helipos, direction, spawnpos);
					spawnpos[2] = (StrEqual(GAME, "csgo")) ? spawnpos[2] : spawnpos[2] - 65.0;
					vecTracks[0] = spawnpos;
					
					// Is there a target in sight?
					char nameTarget[32];
					int target = -1; 
					
					if (g_cvHomingEnabled.BoolValue == true)
						target = FindMissileTarget(pilot, spawnpos);
					
					if (target > 0 && target <= MaxClients && IsValidEntity(target) && IsPlayerAlive(target)) {
						// Give target unambigous name
						FormatEx(nameTarget, sizeof(nameTarget), "%d_missiletarget", target);
						DispatchKeyValue(target, "targetname", nameTarget); 
							
						float targetpos[3];
						GetClientEyePosition(target, targetpos);
						
						// Draw target marker
						TE_SetupBeamRingPoint(targetpos, 50.0, 150.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.5, 10.0, 0.5, {255, 0, 0, 255}, 15, 0);
						TE_SendToClient(pilot, 0.0);
											
						// SECOND TRACK (TARGET) - Placed on target. This track will move with the target
						vecTracks[1] = targetpos;

						// THIRD TRACK (TARGET) - Placement mostly irrelevant. Ensures "OnPass" callback on previous track for explosion at target
						targetpos[2] -= 100.0;
						vecTracks[2] = targetpos;
						
						// Play fired sound, homing missile
						EmitSoundToAll(SOUND_ROCKET_FIRED_HOMING, g_Helicopter[hIndex]);		
					}
					else {
						// SECOND TRACK (NO TARGET) - Placed at MAX DISTANCE, to ensure explosion/deletion of missile
						GetAngleVectors(heliang, direction, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(direction, g_cvMissileDistance.FloatValue); 
						AddVectors(helipos, direction, movepos);
						movepos[2] -= 100.0; // TODO: A consistent downward and centered angle would be good for strafe-fire when no target
						vecTracks[1] = movepos;
						
						// THIRD TRACK (NO TARGET) - Placement mostly irrelevant. This ensures a callback on "OnPass" output
						movepos[2] += 50.0;
						vecTracks[2] = movepos;
						
						// Player fired sound, non-homing missile
						EmitSoundToAll(SOUND_ROCKET_FIRED, g_Helicopter[hIndex]);
					}
					
					// Give unambiguous names to prevent parenting error
					char nameTrack[32], nameFirstTrack[32], namePrevTrack[32], nameTrain[32], nameMissile[32];
					FormatEx(nameFirstTrack, sizeof(nameFirstTrack), "%d_%f_mtrack_0", target, GetGameTime()/2);
					FormatEx(nameTrain, sizeof(nameTrain), "%d_%f_mtrain", target, GetGameTime()/2);
					FormatEx(nameMissile, sizeof(nameMissile), "%d_%f_missile", target, GetGameTime()/2);
					
					// Create the missiles tracktrain
					int tracktrain = CreateMissileTrain(pilot, nameTrain, nameFirstTrack);
					
					// Create the missiles path tracks
					for(int j = trackcount-1; j >= 0; j--) {
						FormatEx(nameTrack, sizeof(nameTrack), "%d_%f_mtrack_%d", target, GetGameTime()/2, j);
						tracks[j] = CreateMissilePath(pilot, nameTrack, vecTracks[j], namePrevTrack);
						
						// Homing missile
						if (j != (trackcount - 1) && target > 0 && target <= MaxClients) {
							int measuremove = CreateEntityByName("logic_measure_movement");
							
							DispatchKeyValue(measuremove, "MeasureType", "1"); // Aim for head
							DispatchKeyValue(measuremove, "MeasureTarget", (j == 1) ? nameTarget : nameTrain);
							DispatchKeyValue(measuremove, "MeasureReference", nameTarget);
							DispatchKeyValue(measuremove, "TargetReference", nameTarget);
							DispatchKeyValue(measuremove, "Target", nameTrack);
							
							if (DispatchSpawn(measuremove)) {
								ActivateEntity(measuremove);
								AcceptEntityInput(measuremove, "Enable");
								
								// Keep parenting heirarchy for removal on missile explode
								ParentToEntity(tracks[j], measuremove);
								ParentToEntity(measuremove, tracktrain);
							}
						}
						else
							ParentToEntity(tracks[j], tracktrain);
					
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
	int clientTeam = GetClientTeam(client);
	
	int target = -1;
	float lastDistance = g_cvHomingDistance.FloatValue + 5.0; // A little passed max, just in case
	
	for (int i = 1; i <= MaxClients; i++) {
		if (i != client && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i)) {
			int targetTeam = GetClientTeam(i);
			
			// Do not target clients in the same team, unless it's hl2 free-for-all deathmatch
			if (targetTeam != clientTeam || (StrEqual(GAME, "hl2mp") && clientTeam == 0)) {
				float targetpos[3];
				GetClientEyePosition(i, targetpos);
				
				float distance = GetVectorDistance(startpos, targetpos);
				
				// If the distance is less than any previous targets while looping, then consider this player as possible target and run traceray
				if (distance >= 50.0 && distance < lastDistance) {
					float rayend[3], rayang[3], direction[3], newvec[3];
					
					// Get the angle from the missile spawn position to the possible targets face
					SubtractVectors(targetpos, startpos, newvec);
					NormalizeVector(newvec, newvec);
					GetVectorAngles(newvec, rayang);
	
					GetAngleVectors(rayang, direction, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(direction, g_cvHomingDistance.FloatValue);
					AddVectors(startpos, direction, rayend);
		
					// Send a traceray, if there is nothing blocking the path, select player as target, and record distance for next player check
					TR_TraceRayFilter(startpos, rayend, MASK_SOLID, RayType_EndPoint, TraceRayFilterFindTarget, client);
					if (TR_DidHit(INVALID_HANDLE) && TR_GetEntityIndex() > 0 && TR_GetEntityIndex() <= MaxClients) {
						target = TR_GetEntityIndex();
						lastDistance = distance;
					}
				}
			}
		}
	}
	
	return (target > 0 && target <= MaxClients) ? target : -1;
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
	
	float ang[3];
	if (StrEqual(GAME, "csgo")) {
		DispatchKeyValue(missile, "modelscale", "0.4");
		ang[1] = 90.0;
	}
	
	if (DispatchSpawn(missile))
		TeleportEntity(missile, NULL_VECTOR, ang, NULL_VECTOR);
	
	return missile;
}
//--------------------------------------------------------
// *********** CREATE THE MISSILES SMOKE TRAIL ***********
//--------------------------------------------------------
stock int CreateMissileTrail(int team) 
{
	int smoketrail = CreateEntityByName("env_rockettrail");
	
	SetEntPropFloat(smoketrail, Prop_Send, "m_StartSize", 3.0);
	SetEntPropFloat(smoketrail, Prop_Send, "m_EndSize", 11.0);
	SetEntPropFloat(smoketrail, Prop_Send, "m_MinSpeed", 3.0);
	SetEntPropFloat(smoketrail, Prop_Send, "m_MaxSpeed", 6.0);
	SetEntPropFloat(smoketrail, Prop_Send, "m_Opacity", 0.25);
	SetEntPropFloat(smoketrail, Prop_Send, "m_SpawnRate", 20.0);
	SetEntPropFloat(smoketrail, Prop_Send, "m_SpawnRadius", 0.8);
	SetEntPropFloat(smoketrail, Prop_Send, "m_ParticleLifetime", 0.4);
	SetEntPropFloat(smoketrail, Prop_Send, "m_flFlareScale", 1.5);
	
	float smokeColor[3];
	
	if ((!StrEqual(GAME, "hl2mp") && team == 3) || (StrEqual(GAME, "hl2mp") && team == 2))
		smokeColor = TEAMCOLOR_BLUE;
	else if ((!StrEqual(GAME, "hl2mp") && team == 2) || (StrEqual(GAME, "hl2mp") && team == 3))
		smokeColor = TEAMCOLOR_RED;
	else
		smokeColor = TEAMCOLOR_GREY;
		
	SetEntPropVector(smoketrail, Prop_Send, "m_StartColor", smokeColor); 
	SetEntPropVector(smoketrail, Prop_Send, "m_EndColor", TEAMCOLOR_GREY); 
	
	if (DispatchSpawn(smoketrail))
		ActivateEntity(smoketrail);

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
		
	if (DispatchSpawn(path)) {
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

	char spawnflags[16];
	FormatEx(spawnflags, sizeof(spawnflags), "%i", 2 | 8 | 512); // No control | No collision | Not blockable
	DispatchKeyValue(tracktrain, "spawnflags", spawnflags);
	
	char startspeed[16], speed[32];
	g_cvMissileSpeed.GetString(speed, sizeof(speed));
	
	int fStartspeed = RoundFloat((StringToFloat(speed)/2));
	IntToString(fStartspeed, startspeed, sizeof(startspeed));

	DispatchKeyValue(tracktrain, "startspeed", startspeed);
	DispatchKeyValue(tracktrain, "speed", speed);
	
	DispatchKeyValue(tracktrain, "orientationtype", "3");
	DispatchKeyValue(tracktrain, "MoveSound", SOUND_ROCKET_FLY);
	DispatchKeyValue(tracktrain, "volume", "10");
	DispatchKeyValue(tracktrain, "wheels", "300");
	
	DispatchSpawn(tracktrain);
	
	return tracktrain;
}
//--------------------------------------------------------
// ********** HOOK ON PASS PATH TO EXPLODE AT ************
//--------------------------------------------------------
public void OnPassCollisionTrack(const char[] output, int track, int train, float delay)
{
	/* NOTE: "OnPass" does not get called on the last path_track, so we add an additional "dummy" path_track to ensure targets track gets fired*/
		
	int pilot = GetEntPropEnt(train, Prop_Send, "m_hOwnerEntity");
	
	if (IsValidEntity(train) && IsValidEntity(track)) {	
		float explodepos[3];
		GetEntPropVector(train, Prop_Send, "m_vecOrigin", explodepos);

		// Explode on pass
		CreateExplosion(pilot, explodepos);
		
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
	if (IsValidEntity(train) && IsValidEntity(track)) {
		int pilot = GetEntPropEnt(train, Prop_Send, "m_hOwnerEntity");
		int missile = GetEntPropEnt(train, Prop_Data, "m_hMoveChild"); 
		
		if (IsValidEntity(pilot) && IsValidEntity(missile)) {
			float missilepos[3];
			GetEntPropVector(train, Prop_Send, "m_vecOrigin", missilepos);
			
			float mins[3] = { -5.0, -5.0, -3.0 };
			float maxs[3] = { 5.0, 5.0, 3.0 };
		
			DataPack pack = CreateDataPack();
			WritePackCell(pack, pilot);
			WritePackCell(pack, missile);
			WritePackCell(pack, train);
			
			TR_TraceHullFilter(missilepos, missilepos, mins, maxs, MASK_SHOT, TraceHullFilterMissile, pack);
			if(TR_DidHit(INVALID_HANDLE)) {
				float hitpos[3];
				TR_GetEndPosition(hitpos);
				
				// Explode on collision
				CreateExplosion(pilot, hitpos);
				
				// Kill the entire track train system for this missile
				AcceptEntityInput(train, "Stop");
				AcceptEntityInput(train, "KillHierarchy");
			}
			delete pack;
		}
	}
}
//--------------------------------------------------------
// ****************** EXPLOSION CREATION *****************
//--------------------------------------------------------
stock int CreateExplosion(int owner, float pos[3])
{
	int explosion = CreateEntityByName("env_explosion");
	
	char damage[32];
	g_cvMissileDamage.GetString(damage, sizeof(damage));
	
	DispatchKeyValue(explosion, "iMagnitude", damage);
	DispatchKeyValue(explosion, "iRadiusOverride", "400");
	DispatchKeyValue(explosion, "DamageForce", "500.0");
	DispatchKeyValue(explosion, "rendermode", "5");
	DispatchKeyValue(explosion, "spawnflags", "128"); // Random Orientation
	
	if (DispatchSpawn(explosion) && IsValidEntity(owner)) {
		if (IsValidEntity(owner)) {
			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", owner);
			if (owner > 0 && owner <= MaxClients)
				SetEntProp(explosion, Prop_Send, "m_iTeamNum", GetClientTeam(owner));
		}
			
		TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);
		
		ActivateEntity(explosion);
		
		AcceptEntityInput(explosion, "Explode");
		EmitSoundToAll(SOUND_ROCKET_EXPLODE, explosion);
				
		// Delete explosion to prevent rapid re-fire
		CreateTimer(1.0, TimerDeleteExplosion, explosion);
	}
	
	return explosion;
}
//--------------------------------------------------------
// ****** EXPLOSION DELETION, PREVENT RAPID RE-FIRE ******
//--------------------------------------------------------
stock Action TimerDeleteExplosion(Handle timer, int explosion)
{
	// Use this for other timed deletions of different entities?
	if (IsValidEntity(explosion))
		AcceptEntityInput(explosion, "Kill");
		
	KillTimer(timer);
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
	return !(entityAtPoint == client);
}
//--------------------------------------------------------
//****** TRACERAY FILTER TARGET FINDING OBSTACLES ********
//--------------------------------------------------------
public bool TraceRayFilterFindTarget(int entityAtPoint, int mask, any client) 
{
	if (entityAtPoint > 0 && entityAtPoint <= MaxClients && entityAtPoint != client)
		return true;
		
	int hIndex = g_pInHelicopter[client];
	
	if (hIndex > -1 && (entityAtPoint == g_Helicopter[hIndex] || entityAtPoint == g_HelicopterShell[hIndex]))
		return false;
		
	if (entityAtPoint == client)
		return false;
		
	return false;
}
//--------------------------------------------------------
// ********* TRACERAY FILTER MISSILE OBSTACLES ***********
//--------------------------------------------------------
public bool TraceHullFilterMissile(int touched, int mask, DataPack data)
{
	data.Reset();
	int client = data.ReadCell();
	int missile = data.ReadCell();
	int train = data.ReadCell();
	int hIndex = g_pInHelicopter[client];
    
	if (hIndex < 0)
		return false;
 
	if (touched == client || touched == missile || touched == train || touched == g_Helicopter[hIndex] || touched == g_HelicopterShell[hIndex])
 		return false;
		
	return true;
}
//============================================================================================
//																							//
//								ENTITY UTILITIES											//
//																							//
//============================================================================================
stock bool ParentToEntity(int child, int parent)
{
	SetVariantEntity(parent);
	return AcceptEntityInput(child, "SetParent");
}
///
stock int ConstrainEntities(const char[] nameconstraintsys, const char[] nameentity1, const char[] nameentity2)
{
	/* An Alternative to parenting to allow physics interaction */
	int constraint = CreateEntityByName("phys_constraint");
	
	DispatchKeyValue(constraint, "constraintsystem", nameconstraintsys);
	DispatchKeyValue(constraint, "attach1", nameentity1);
	DispatchKeyValue(constraint, "attach2", nameentity2);
	
	DispatchKeyValue(constraint, "teleportfollowdistance", "0.1");
	DispatchKeyValue(constraint, "forcelimit", "0");
	DispatchKeyValue(constraint, "torquelimit", "0");
	
	if (DispatchSpawn(constraint)) {
		ActivateEntity(constraint);
		AcceptEntityInput(constraint, "TurnOn");
	}
		
	return constraint;
}
///
stock bool SetEntityInputInt(int entity, char[] input, int value)
{
	SetVariantInt(value);
	return AcceptEntityInput(entity, input);
}
///
stock bool SetEntityInputFloat(int entity, char[] input, float value)
{
	SetVariantFloat(value);
	return AcceptEntityInput(entity, input);
}
///
stock bool SetEntityInputString(int entity, char[] input, char[] value)
{
	SetVariantString(value);
	return AcceptEntityInput(entity, input);
}