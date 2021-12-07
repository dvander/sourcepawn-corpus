#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define CONFIG_LOCATIONS	"./cfg/sourcemod/alarmcars_location.cfg"
#define CONFIG_MODELS		"./cfg/sourcemod/alarmcars_models.cfg"
#define CVAR_FLAGS 			FCVAR_PLUGIN|FCVAR_NOTIFY
#define DEBUG_ENABLED		0
#define DEBUG_LOGFILE		"./alarmcar_debug_file.txt"
#define PLUGIN_VERSION 		"1.0.4b"

#define ALARMCAR_MODEL 		"models/props_vehicles/cara_95sedan.mdl"
#define ALARMCAR_GLASS		"models/props_vehicles/cara_95sedan_glass_alarm.mdl"
#define ALARMCAR_GLASS_OFF	"models/props_vehicles/cara_95sedan_glass.mdl"
#define COLOR_REDCAR		"222 92 86"
#define COLOR_REDLIGHT		"255 13 19"
#define COLOR_WHITELIGHT	"252 243 226"
#define COLOR_YELLOWLIGHT	"224 162 44"
#define DISTANCE_BACK		103.0
#define DISTANCE_FRONT		101.0
#define DISTANCE_SIDE		27.0
#define DISTANCE_SIDETURN	34.0
#define DISTANCE_UPBACK		31.0
#define DISTANCE_UPFRONT	29.0

/**
 *
 * Known Bugs:
 *  none 
 *
 * History:
 * v1.0.1:
 *  - fixed chirp/alarm for every car and not for the one shot at
 *  - fixed no spawning in 2nd round of versus mode
 * v1.0.2:
 *  - fixed pitch and roll for cars
 *  - renamed old commands and cvars
 *  - added new commands for removing
 * v1.0.3:
 *  - fixed car not moving and glass/lights are parented to the car
 *  - fixed no spawning cars at 1st round of versus and on mapchange
 *  - added new commands for moving and rotating cars
 *  - added new command to save current cars into the config (overriding previous cars of the map)
 * v1.0.4:
 *  - fixed errors in log, when two map loadings appeared very fast after each other 
 *  - added #pragma semicolon 1 (copy paste of file header mistake xD)
 *  - major update:
 *     + updated plugin for support of custom alarm car models divided in two categories (cars / trucks)
 *     + updated config file to support custom models
 *     + added new commands for spawning --> sm_alarmcar_spawn_custom, sm_alarmcar_spawn_custom_at, sm_alarmcar_spawn_truck and sm_alarmcar_spawn_truck_at
 *     + added new command to list alle possible models to spawn --> sm_alarmcar_list_customs
 *     + updated old commands --> sm_alarmcar_move, sm_alarmcar_remove and sm_alarmcar_remove_at
 *     + updated save command and mapstart function for new config files
 * v1.0.4b:
 *  - fix round start spawn car
 */

public Plugin:myinfo = {
	name = "[L4D1&2] Spawn Alarmcars",
	author = "Die Teetasse",
	description = "Spawns fully function alarm cars.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1313372"
};

// ###################################
// GLOBAL THINGS
// ###################################

new bool:globalIsMapInit = false;
new Handle:globalCVarEnable;
new Handle:globalDataCarsStrings;
new Handle:globalDataCarsValues;
new Handle:globalDataTrucksStrings;
new Handle:globalDataTrucksValues;
new globalCarNumber;
new globalDataCarsCount;
new globalDataTrucksCount;

public OnPluginStart() {
	// check game
	decl String:game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead") == -1) SetFailState("Spawn Alarmcars will only work with Left 4 Dead 1 or 2!");

	// create cvars
	CreateConVar("sm_alarmcar_version", PLUGIN_VERSION, "Spawn alarmcar version", CVAR_FLAGS|FCVAR_DONTRECORD);
	globalCVarEnable = CreateConVar("sm_alarmcar_mapstart", "1", "Spawn fully functional alarm cars at mapstart from config file /cfg/sourcemod/alarmcars_location.cfg", CVAR_FLAGS);

	// reg commands
	RegAdminCmd("sm_alarmcar_list_customs", Command_ListCustomCars, ADMFLAG_KICK, "sm_alarmcar_list_customs | Lists all custom cars from config.");
	RegAdminCmd("sm_alarmcar_move", Command_MoveCarInFront, ADMFLAG_KICK, "sm_alarmcar_move <x> <y> <z> [pitch] [yaw] [roll] | Moves alarm car in front of you. Optional rotates the car too.");
	RegAdminCmd("sm_alarmcar_move_at", Command_MoveCarAt, ADMFLAG_KICK, "sm_alarmcar_move_at <x> <y> <z> <newX> <newY> <newZ> [pitch] [yaw] [roll] | Moves alarm car at the given position. Optional rotates the car too.");	
	RegAdminCmd("sm_alarmcar_remove", Command_RemoveCarInFront, ADMFLAG_KICK, "sm_alarmcar_remove | Removes alarm car in front of you.");
	RegAdminCmd("sm_alarmcar_remove_at", Command_RemoveCarAt, ADMFLAG_KICK, "sm_alarmcar_remove_at <x> <y> <z> | Removes alarm car at the given position.");
	RegAdminCmd("sm_alarmcar_rotate", Command_RotateCarInFront, ADMFLAG_KICK, "sm_alarmcar_rotate <pitch> <yaw> <roll> | Rotates alarm car in front of you.");
	RegAdminCmd("sm_alarmcar_rotate_at", Command_RotateCarAt, ADMFLAG_KICK, "sm_alarmcar_rotate_at <x> <y> <z> <pitch> <yaw> <roll> | Rotates alarm car at the given position.");
	RegAdminCmd("sm_alarmcar_save_to_config", Command_SaveCarsToConfig, ADMFLAG_KICK, "sm_alarmcar_save_to_config | Saves current created cars into the config and overrides old ones.");
	RegAdminCmd("sm_alarmcar_spawn", Command_SpawnCarInFront, ADMFLAG_KICK, "sm_alarmcar_spawn | Spawns a fully functional alarm car in front of you.");
	RegAdminCmd("sm_alarmcar_spawn_at", Command_SpawnCarAt, ADMFLAG_KICK, "sm_alarmcar_spawn_at <x> <y> <z> <pitch> <yaw> <roll> [r] [g] [b] | Spawns a fully functional alarm car at the given position, angles and optional color.");
	RegAdminCmd("sm_alarmcar_spawn_custom", Command_SpawnCostumInFront, ADMFLAG_KICK, "sm_alarmcar_spawn_custom <type> | Spawns a fully functional alarm custom car in front of you.");
	RegAdminCmd("sm_alarmcar_spawn_custom_at", Command_SpawnCostumAt, ADMFLAG_KICK, "sm_alarmcar_spawn_custom_at <type> <x> <y> <z> <pitch> <yaw> <roll> [r] [g] [b] | Spawns a fully functional alarm custom car at the given position, angles and optional color.");
	RegAdminCmd("sm_alarmcar_spawn_truck", Command_SpawnTruckInFront, ADMFLAG_KICK, "sm_alarmcar_spawn_truck <type> | Spawns a fully functional alarm truck in front of you.");
	RegAdminCmd("sm_alarmcar_spawn_truck_at", Command_SpawnTruckAt, ADMFLAG_KICK, "sm_alarmcar_spawn_truck_at <type> <x> <y> <z> <pitch> <yaw> <roll> | Spawns a fully functional alarm truck at the given position and optional angles.");
	
	// hook events
	HookEvent("round_freeze_end", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("mission_lost", Event_RoundStart);
	
	// init arrays
	globalDataCarsStrings = CreateArray(128);
	globalDataTrucksStrings = CreateArray(128);
	
	globalDataCarsValues = CreateArray(3);
	globalDataTrucksValues = CreateArray(3);
	
	// init data
	InitData();
}

public OnMapStart() {
	DebugOutput("Forward: map start");
	InitData();
	InitMap();
}

public OnMapEnd() {
	DebugOutput("Forward: map end");
	globalIsMapInit = false;
}

// ###################################
// PUBLIC HOOKED EVENTS
// ###################################

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugOutput("Event: round start");	
	InitMap();
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugOutput("Event: round end");	
	globalIsMapInit = false;
}

// ###################################
// PUBLIC ADMIN COMMANDS
// ###################################

// LIST
// ##################

public Action:Command_ListCustomCars(client, args) {
	decl String:desc[256], String:model[128];
	PrintMessage(client, "[SM] %d custom car(s):", globalDataCarsCount);
	
	for (new i = 0; i < globalDataCarsCount; i++) {
		GetArrayString(globalDataCarsStrings, (i*3), model, 128);
		GetArrayString(globalDataCarsStrings, (i*3)+2, desc, 256);
		PrintMessage(client, "[SM] - %d: %s [%s]", i, desc, model);
	}
	
	PrintMessage(client, "[SM] %d custom truck(s):", globalDataTrucksCount);
	
	for (new i = 0; i < globalDataTrucksCount; i++) {
		GetArrayString(globalDataTrucksStrings, (i*3), model, 128);
		GetArrayString(globalDataTrucksStrings, (i*3)+2, desc, 256);
		PrintMessage(client, "[SM] - %d: %s [%s]", i, desc, model);
	}	
}

// MOVE
// ##################

public Action:Command_MoveCarInFront(client, args) {
	if (client == 0) client = 1; // DEBUG
	if (client == 0) {
		PrintToServer("[SM] This command can only be used by a client!");
		return;
	}
	
	if (args != 3 && args != 6) {
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_move <PosX> <PosY> <PosZ> [NewPitch] [NewYaw] [NewRoll]");
		return;
	}
	
	decl Float:entityPosition[3], Float:entityAngles[3];
	GetClientInFrontLocation(client, entityPosition, entityAngles);
	
	decl Float:newPosition[3];
	decl String:tempFloat[16];
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(1+i, tempFloat, 16);
		newPosition[i] = StringToFloat(tempFloat);
	}
	
	if (args == 3) MoveAlarmCar(entityPosition, newPosition, NULL_VECTOR, client); 
	else {
		decl Float:newAngle[3];
		for (new i = 0; i < 3; i++) {
			GetCmdArg(4+i, tempFloat, 16);
			newAngle[i] = StringToFloat(tempFloat);
		}		
		
		MoveAlarmCar(entityPosition, newPosition, newAngle, client);
	}
}

public Action:Command_MoveCarAt(client, args) {
	if (args != 6 && args != 9) {
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_move_at <PosX> <PosY> <PosZ> <NewPosX> <NewPosY> <NewPosZ> [NewPitch] [NewYaw] [NewRoll]");
		return;
	}
	
	decl Float:entityPosition[3], Float:newPosition[3];
	decl String:tempFloat[16];
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(1+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(4+i, tempFloat, 16);
		newPosition[i] = StringToFloat(tempFloat);
	}

	if (args == 6) MoveAlarmCar(entityPosition, newPosition, NULL_VECTOR, client); 
	else {
		decl Float:newAngle[3];
		for (new i = 0; i < 3; i++) {
			GetCmdArg(7+i, tempFloat, 16);
			newAngle[i] = StringToFloat(tempFloat);
		}		
		
		MoveAlarmCar(entityPosition, newPosition, newAngle, client);
	}
}

// REMOVE
// ##################

public Action:Command_RemoveCarInFront(client, args) {
	if (client == 0) client = 1; // DEBUG
	if (client == 0) {
		PrintToServer("[SM] This command can only be used by a client!");
		return;
	}
	
	decl Float:entityPosition[3], Float:entityAngles[3];
	GetClientInFrontLocation(client, entityPosition, entityAngles);
	
	RemoveAlarmCar(entityPosition, client);
}

public Action:Command_RemoveCarAt(client, args) {
	if (args != 3) {
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_remove_at <PosX> <PosY> <PosZ>");
		return;
	}
	
	decl Float:entityPosition[3];
	decl String:tempFloat[16];
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(1+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}
	
	RemoveAlarmCar(entityPosition, client);
}

// ROTATE
// ##################

public Action:Command_RotateCarInFront(client, args) {
	if (client == 0) client = 1; // DEBUG
	if (client == 0) {
		PrintToServer("[SM] This command can only be used by a client!");
		return;
	}
	
	if (args != 3) {
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_rotate <Pitch> <Yaw> <Roll>");
		return;
	}
	
	decl Float:newAngle[3];
	decl String:tempFloat[16];
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(1+i, tempFloat, 16);
		newAngle[i] = StringToFloat(tempFloat);
	}	
	
	decl Float:entityPosition[3];
	GetClientInFrontLocation(client, entityPosition);
	
	RotateAlarmCar(entityPosition, newAngle, client);
}

public Action:Command_RotateCarAt(client, args) {
	if (args != 6) {
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_rotate_at <PosX> <PosY> <PosZ> <Pitch> <Yaw> <Roll>");
		return;
	}
	
	decl Float:entityPosition[3], Float:newAngle[3];
	decl String:tempFloat[16];
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(1+i, tempFloat, 16);
		newAngle[i] = StringToFloat(tempFloat);
	}	
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(4+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}
	
	RotateAlarmCar(entityPosition, newAngle, client);
}

// SAVE
// ##################

public Action:Command_SaveCarsToConfig(client, args) {
	SaveAlarmCars(client);
}

// SPAWN (NORMAL)
// ##################

public Action:Command_SpawnCarInFront(client, args) {
	if (client == 0) client = 1; // DEBUG
	if (client == 0) {
		PrintToServer("[SM] This command can only be used by a client!");
		return;
	}
	
	decl Float:entityPosition[3], Float:entityAngles[3];
	GetClientInFrontLocation(client, entityPosition, entityAngles);
	
	SpawnAlarmCar(entityPosition, entityAngles, client);
}

public Action:Command_SpawnCarAt(client, args) {
	if (args != 6 && args != 9) {
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_spawn_at <PosX> <PosY> <PosZ> <Pitch> <Yaw> <Roll> [ColorR] [ColorG] [ColorB]");
		return;
	}
	
	decl Float:entityPosition[3], Float:entityAngles[3];
	decl String:tempFloat[16];
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(1+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(4+i, tempFloat, 16);
		entityAngles[i] = StringToFloat(tempFloat);
	}
	
	if (args == 6) SpawnAlarmCar(entityPosition, entityAngles, client);
	else {
		decl entityColor[3], String:entityColorString[16];
		for (new i = 0; i < 3; i++) {
			GetCmdArg(7+i, tempFloat, 16);
			entityColor[i] = StringToInt(tempFloat);
		}		
		
		Format(entityColorString, 16, "%d %d %d", entityColor[0], entityColor[1], entityColor[2]);
		SpawnAlarmCar(entityPosition, entityAngles, client, entityColorString);
	}
}

// SPAWN (CUSTOM)
// ##################

public Action:Command_SpawnCostumInFront(client, args) {
	if (client == 0) client = 1; // DEBUG
	if (client == 0) {
		PrintToServer("[SM] This command can only be used by a client!");
		return;
	}
	
	if (args != 1) {
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_spawn_custom <Type>");
		return;
	}
	
	decl Float:entityPosition[3], Float:entityAngles[3];
	GetClientInFrontLocation(client, entityPosition, entityAngles);
	
	decl String:temp[8];
	GetCmdArg(1, temp, 8);
	new type = StringToInt(temp);
	
	SpawnCustomAlarmCar(entityPosition, entityAngles, type, client);
}

public Action:Command_SpawnCostumAt(client, args) {
	if (args != 7 && args != 10) {
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_spawn_at <Type> <PosX> <PosY> <PosZ> <Pitch> <Yaw> <Roll> [ColorR] [ColorG] [ColorB]");
		return;
	}
	
	decl Float:entityPosition[3], Float:entityAngles[3];
	decl String:tempFloat[16];

	GetCmdArg(1, tempFloat, 16);
	new type = StringToInt(tempFloat);
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(2+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(5+i, tempFloat, 16);
		entityAngles[i] = StringToFloat(tempFloat);
	}
	
	if (args == 6) SpawnCustomAlarmCar(entityPosition, entityAngles, type, client);
	else {
		decl entityColor[3], String:entityColorString[16];
		for (new i = 0; i < 3; i++) {
			GetCmdArg(8+i, tempFloat, 16);
			entityColor[i] = StringToInt(tempFloat);
		}		
		
		Format(entityColorString, 16, "%d %d %d", entityColor[0], entityColor[1], entityColor[2]);
		SpawnCustomAlarmCar(entityPosition, entityAngles, type, client, entityColorString);
	}
}

// SPAWN (TRUCK)
// ##################

public Action:Command_SpawnTruckInFront(client, args) {
	if (client == 0) client = 1; // DEBUG
	if (client == 0) {
		PrintToServer("[SM] This command can only be used by a client!");
		return;
	}
	
	if (args != 1) {
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_spawn_truck <Type>");
		return;
	}
	
	decl Float:entityPosition[3], Float:entityAngles[3];
	GetClientInFrontLocation(client, entityPosition, entityAngles, 300.0);
	
	decl String:temp[8];
	GetCmdArg(1, temp, 8);
	new type = StringToInt(temp);
	
	SpawnCustomAlarmTruck(entityPosition, entityAngles, type, client);
}

public Action:Command_SpawnTruckAt(client, args) {
	if (args != 7) {
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_spawn_truck_at <Type> <PosX> <PosY> <PosZ> <Pitch> <Yaw> <Roll>");
		return;
	}
	
	decl Float:entityPosition[3], Float:entityAngles[3];
	decl String:tempFloat[16];

	GetCmdArg(1, tempFloat, 16);
	new type = StringToInt(tempFloat);
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(2+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}
	
	for (new i = 0; i < 3; i++) {
		GetCmdArg(5+i, tempFloat, 16);
		entityAngles[i] = StringToFloat(tempFloat);
	}
	
	SpawnCustomAlarmTruck(entityPosition, entityAngles, type, client);
}

// ###################################
// PRIVATE MOVE/ROTATE CAR FUNCTIONS
// ###################################

MoveAlarmCar(const Float:entityPosition[3], const Float:newPosition[3], const Float:newAngle[3] = NULL_VECTOR, const client = 0) {
	new carEntity, carTimer[2], gameEventInfo;
	
	if (!FindCarEntitiesAt(entityPosition, client, carEntity, carTimer, gameEventInfo)) {
		return;
	}
	
	// teleport
	TeleportEntity(carEntity, newPosition, newAngle, NULL_VECTOR);
	TeleportEntity(carTimer[0], newPosition, newAngle, NULL_VECTOR);
	TeleportEntity(carTimer[1], newPosition, newAngle, NULL_VECTOR);
	TeleportEntity(gameEventInfo, newPosition, newAngle, NULL_VECTOR);
}

RotateAlarmCar(const Float:entityPosition[3], const Float:newAngle[3], const client = 0) {
	new carEntity, carTimer[2], gameEventInfo;
	
	if (!FindCarEntitiesAt(entityPosition, client, carEntity, carTimer, gameEventInfo)) {
		return;
	}
	
	// rotate
	TeleportEntity(carEntity, NULL_VECTOR, newAngle, NULL_VECTOR);
	//TeleportEntity(alarmTimer, NULL_VECTOR, newAngle, NULL_VECTOR);
	//TeleportEntity(gameEventInfo, NULL_VECTOR, newAngle, NULL_VECTOR);
}

// ###################################
// PRIVATE REMOVE CAR FUNCTIONS
// ###################################

RemoveAlarmCar(const Float:entityPosition[3], const client = 0) {
	new carEntity, carTimer[2], gameEventInfo;
	
	if (!FindCarEntitiesAt(entityPosition, client, carEntity, carTimer, gameEventInfo)) {
		return;
	}
	
	// kill
	KillEntity(carEntity);
	KillEntity(carTimer[0]);
	KillEntity(carTimer[1]);
	KillEntity(gameEventInfo);
	
	PrintMessage(client, "[SM] removed alarm car!");
}

// ###################################
// PRIVATE SPAWN ALARM CAR FUNCTIONS
// ###################################

SpawnAlarmCar(const Float:entityPosition[3], const Float:entityAngles[3], const client = 0, const String:carColor[] = COLOR_REDCAR) {
	// init
	new carEntity, glassEntity, glassOffEntity, alarmTimer, chirpSound, alarmSound;
	new carLights[6], gameEventInfo;

	decl String:carName[64], String:glassName[64], String:glassOffName[64], String:alarmTimerName[64];
	decl String:chirpSoundName[64], String:alarmSoundName[64], String:carLightsName[64];
	decl String:carHeadLightsName[64], String:tempString[256];
	
	Format(carName, 64, "sm_alarmcar_car%d", globalCarNumber);
	Format(glassName, 64, "sm_alarmcar_glass%d", globalCarNumber);
	Format(glassOffName, 64, "sm_alarmcar_glassoff%d", globalCarNumber);
	Format(alarmTimerName, 64, "sm_alarmcar_alarmtimer%d", globalCarNumber);
	Format(chirpSoundName, 64, "sm_alarmcar_chirpsound%d", globalCarNumber);
	Format(alarmSoundName, 64, "sm_alarmcar_alarmsound%d", globalCarNumber);
	Format(carLightsName, 64, "sm_alarmcar_carlights%d", globalCarNumber);
	Format(carHeadLightsName, 64, "sm_alarmcar_carheadlights%d", globalCarNumber);
	
	// create car model
	// ################################
	carEntity = CreateAlarmCar();
	if (carEntity == -1) {
		PrintMessage(client, "[SM] Could not create car entity!");
		return;
	}
	
	DispatchKeyValue(carEntity, "targetname", carName);
	DispatchKeyValue(carEntity, "rendercolor", carColor);
	DispatchKeyValue(carEntity, "model", ALARMCAR_MODEL);
	DispatchKeyValue(carEntity, "renderamt", "255");	
	
	Format(tempString, 256, "%s,Enable,,0,-1", alarmTimerName);
	DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
	Format(tempString, 256, "%s,Disable,,0,-1", alarmTimerName);
	DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
	Format(tempString, 256, "%s,PlaySound,,0,-1", alarmSoundName);
	DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
	Format(tempString, 256, "%s,StopSound,,0,-1", alarmSoundName);
	DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
	Format(tempString, 256, "%s,PlaySound,,0.2,-1", chirpSoundName);
	DispatchKeyValue(carEntity, "OnCarAlarmChirpStart", tempString);
	Format(tempString, 256, "%s,HideSprite,,0.7,-1", carLightsName);
	DispatchKeyValue(carEntity, "OnCarAlarmChirpEnd", tempString);
	Format(tempString, 256, "%s,ShowSprite,,0.2,-1", carLightsName);
	DispatchKeyValue(carEntity, "OnCarAlarmChirpStart", tempString);
	Format(tempString, 256, "%s,Disable,,0,-1", glassName);
	DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
	Format(tempString, 256, "%s,Enable,,0,-1", glassOffName);
	DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
	
	TeleportEntity(carEntity, entityPosition, entityAngles, NULL_VECTOR);
	DispatchSpawn(carEntity);	
	ActivateEntity(carEntity);
	SetEntityMoveType(carEntity, MOVETYPE_NONE);
	
	// create glass model
	// ################################
	glassEntity = CreateCarGlass(ALARMCAR_GLASS, glassName, entityPosition, entityAngles, carName);
	if (glassEntity == -1) {
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create car glass entity!");
		return;
	}

	// create off glass model 
	// ################################
	glassOffEntity = CreateCarGlass(ALARMCAR_GLASS_OFF, glassOffName, entityPosition, entityAngles, carName);
	if (glassOffEntity == -1) {
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create car glass off entity!");
		return;
	}
	
	// create alarm timer
	// ################################
	alarmTimer = CreateEntityByName("logic_timer");	
	if (alarmTimer == -1) {
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create logic timer entity!");
		return;
	}	
	
	DispatchKeyValue(alarmTimer, "UseRandomTime", "0");
	DispatchKeyValue(alarmTimer, "targetname", alarmTimerName);
	DispatchKeyValue(alarmTimer, "StartDisabled", "1");
	DispatchKeyValue(alarmTimer, "spawnflags", "0");
	DispatchKeyValue(alarmTimer, "RefireTime", ".75");
	
	Format(tempString, 256, "%s,ShowSprite,,0,-1", carLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,HideSprite,,0.5,-1", carLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,HideSprite,,0.5,-1", carLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,ShowSprite,,0,-1", carLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	
	Format(tempString, 256, "%s,LightOff,,0.5,-1", carHeadLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,LightOn,,0,-1", carHeadLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);	

	TeleportEntity(alarmTimer, entityPosition, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(alarmTimer);

	// create game event info
	// ################################
	gameEventInfo = CreateGameEvent(entityPosition);
	if (gameEventInfo == -1) {
		KillEntity(carEntity);
		KillEntity(alarmTimer);
		
		PrintMessage(client, "[SM] Could not create game event info entity!");
		return;
	}	
	
	// create sounds
	// ################################
	new Float:soundsPosition[3];
	CopyVector(entityPosition, soundsPosition);
	soundsPosition[2] += 80.0;
	
	chirpSound = CreateCarSound(soundsPosition, chirpSoundName, carName, "Car.Alarm.Chirp2", "48");
	alarmSound = CreateCarSound(soundsPosition, alarmSoundName, carName, "Car.Alarm", "16");
	
	// create lights
	// ################################
	// (Yellow (X,Y,Z), Red, White)
	new Float:distances[9] = {DISTANCE_FRONT, DISTANCE_SIDETURN, DISTANCE_UPFRONT, DISTANCE_BACK, DISTANCE_SIDE, DISTANCE_UPBACK, DISTANCE_FRONT, DISTANCE_SIDE, DISTANCE_UPFRONT};
	CreateLights(carLights, entityPosition, entityAngles, distances, carLightsName, carHeadLightsName, carName);

	// check entities
	// ################################
	decl String:entityName[16];
	new bool:somethingWrong;
	
	if (chirpSound == -1 || alarmSound == -1) {
		entityName = "sound";
		somethingWrong = true;	
	}
	else {
		for (new i = 0; i < 6; i++) {
			if (carLights[i] == -1) {
				entityName = "lights";
				somethingWrong = true;
				break;
			}
		}
	}		
	
	if (somethingWrong) {
		// delete everything
		KillEntity(carEntity);
		KillEntity(alarmTimer);	
		KillEntity(gameEventInfo);	
		
		PrintMessage(client, "[SM] Could not create %s entity!", entityName);
		return;
	}
	
	PrintMessage(client, "[SM] Spawned alarm car at %.2f %.2f %.2f (%.2f %.2f %.2f)", entityPosition[0], entityPosition[1], entityPosition[2], entityAngles[0], entityAngles[1], entityAngles[2]);
	globalCarNumber++;
	
	// allow car moving
	CreateTimer(0.2, Timer_CarMove, carEntity, TIMER_FLAG_NO_MAPCHANGE);
}

// ###################################
// PRIVATE SPAWN ALARM TRUCK FUNCTIONS
// ###################################

SpawnCustomAlarmTruck(const Float:entityPosition[3], const Float:entityAngles[3], const carType, const client = 0) {
	// init
	new carEntity, glassEntity, alarmTimer, chirpSound, alarmSound;
	new carLights[6], gameEventInfo;

	decl Float:modelAngles[3], Float:modelRotation;
	decl Float:distanceYellow[3], Float:distanceRed[3], Float:distanceWhite[3]; 
	
	decl String:carName[64], String:glassName[64], String:alarmTimerName[64];
	decl String:chirpSoundName[64], String:alarmSoundName[64], String:carLightsName[64];
	decl String:carHeadLightsName[64];
	decl String:modelCarName[128], String:modelGlassName[128], String:tempString[256];
	
	Format(carName, 64, "sm_alarmcar_car%d", globalCarNumber);
	Format(glassName, 64, "sm_alarmcar_glass%d", globalCarNumber);
	Format(alarmTimerName, 64, "sm_alarmcar_alarmtimer%d", globalCarNumber);
	Format(chirpSoundName, 64, "sm_alarmcar_chirpsound%d", globalCarNumber);
	Format(alarmSoundName, 64, "sm_alarmcar_alarmsound%d", globalCarNumber);
	Format(carLightsName, 64, "sm_alarmcar_carlights%d", globalCarNumber);
	Format(carHeadLightsName, 64, "sm_alarmcar_carheadlights%d", globalCarNumber);
	
	// check car type
	if (carType < 0 || carType > globalDataTrucksCount-1) {
		PrintMessage(client, "[SM] Car type number is invalid!");
		return;	
	}
	
	// load car type data
	new indexStrings = carType*3;
	new indexValues = carType*4;
	
	GetArrayString(globalDataTrucksStrings, indexStrings, modelCarName, 128);
	GetArrayString(globalDataTrucksStrings, indexStrings+1, modelGlassName, 128);
	
	modelRotation = GetArrayCell(globalDataTrucksValues, indexValues);
	GetArrayArray(globalDataTrucksValues, indexValues+1, distanceYellow);
	GetArrayArray(globalDataTrucksValues, indexValues+2, distanceRed);
	GetArrayArray(globalDataTrucksValues, indexValues+3, distanceWhite);
	
	// model angles
	CopyVector(entityAngles, modelAngles);
	modelAngles[1] += modelRotation;
	
	// create car model
	// ################################
	carEntity = CreateAlarmCar();
	if (carEntity == -1) {
		PrintMessage(client, "[SM] Could not create car entity!");
		return;
	}
	
	DispatchKeyValue(carEntity, "targetname", carName);
	DispatchKeyValue(carEntity, "model", modelCarName);
	
	Format(tempString, 256, "%s,Enable,,0,-1", alarmTimerName);
	DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
	Format(tempString, 256, "%s,Disable,,0,-1", alarmTimerName);
	DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
	Format(tempString, 256, "%s,PlaySound,,0,-1", alarmSoundName);
	DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
	Format(tempString, 256, "%s,StopSound,,0,-1", alarmSoundName);
	DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
	Format(tempString, 256, "%s,PlaySound,,0.2,-1", chirpSoundName);
	DispatchKeyValue(carEntity, "OnCarAlarmChirpStart", tempString);
	Format(tempString, 256, "%s,HideSprite,,0.7,-1", carLightsName);
	DispatchKeyValue(carEntity, "OnCarAlarmChirpEnd", tempString);
	Format(tempString, 256, "%s,ShowSprite,,0.2,-1", carLightsName);
	DispatchKeyValue(carEntity, "OnCarAlarmChirpStart", tempString);
	
	TeleportEntity(carEntity, entityPosition, modelAngles, NULL_VECTOR);
	DispatchSpawn(carEntity);	
	ActivateEntity(carEntity);
	SetEntityMoveType(carEntity, MOVETYPE_NONE);
	
	// create glass model
	// ################################
	glassEntity = CreateCarGlass(modelGlassName, glassName, entityPosition, modelAngles, carName);
	if (glassEntity == -1) {
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create car glass entity!");
		return;
	}
	
	// create alarm timer
	// ################################
	alarmTimer = CreateEntityByName("logic_timer");	
	if (alarmTimer == -1) {
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create logic timer entity!");
		return;
	}	
	
	DispatchKeyValue(alarmTimer, "UseRandomTime", "0");
	DispatchKeyValue(alarmTimer, "targetname", alarmTimerName);
	DispatchKeyValue(alarmTimer, "StartDisabled", "1");
	DispatchKeyValue(alarmTimer, "spawnflags", "0");
	DispatchKeyValue(alarmTimer, "RefireTime", ".75");
	
	Format(tempString, 256, "%s,ShowSprite,,0,-1", carLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,HideSprite,,0.5,-1", carLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,HideSprite,,0.5,-1", carLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,ShowSprite,,0,-1", carLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	
	Format(tempString, 256, "%s,LightOff,,0.5,-1", carHeadLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,LightOn,,0,-1", carHeadLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);	
	
	Format(tempString, 256, "%s,PlaySound,,0,-1", alarmSoundName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,StopSound,,0.5,-1", alarmSoundName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	
	TeleportEntity(alarmTimer, entityPosition, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(alarmTimer);
	
	// create game event info
	// ################################
	gameEventInfo = CreateGameEvent(entityPosition);
	if (gameEventInfo == -1) {
		KillEntity(carEntity);
		KillEntity(alarmTimer);
		
		PrintMessage(client, "[SM] Could not create game event info entity!");
		return;
	}	
	
	// create sounds
	// ################################
	new Float:soundsPosition[3];
	CopyVector(entityPosition, soundsPosition);
	soundsPosition[2] += 80.0;
	
	chirpSound = CreateCarSound(soundsPosition, chirpSoundName, carName, "Car.Alarm.Chirp2", "48");
	alarmSound = CreateCarSound(soundsPosition, alarmSoundName, carName, "apc.horn", "16");
	
	// create lights
	// ################################
	// (Yellow (X,Y,Z), Red, White)
	decl Float:distances[9];
	distances[0] = distanceYellow[0];
	distances[1] = distanceYellow[1];
	distances[2] = distanceYellow[2];
	distances[3] = distanceRed[0];
	distances[4] = distanceRed[1];
	distances[5] = distanceRed[2];
	distances[6] = distanceWhite[0];
	distances[7] = distanceWhite[1];
	distances[8] = distanceWhite[2];
	CreateLights(carLights, entityPosition, entityAngles, distances, carLightsName, carHeadLightsName, carName);

	// check entities
	// ################################
	decl String:entityName[16];
	new bool:somethingWrong;
	
	if (chirpSound == -1 || alarmSound == -1) {
		entityName = "sound";
		somethingWrong = true;	
	}
	else {
		for (new i = 0; i < 6; i++) {
			if (carLights[i] == -1) {
				entityName = "lights";
				somethingWrong = true;
				break;
			}
		}
	}		
	
	if (somethingWrong) {
		// delete everything
		KillEntity(carEntity);
		KillEntity(alarmTimer);	
		KillEntity(gameEventInfo);	
		
		PrintMessage(client, "[SM] Could not create %s entity!", entityName);
		return;
	}
	
	PrintMessage(client, "[SM] Spawned custom alarm truck at %.2f %.2f %.2f (%.2f %.2f %.2f)", entityPosition[0], entityPosition[1], entityPosition[2], entityAngles[0], entityAngles[1], entityAngles[2]);
	globalCarNumber++;
	
	// allow car moving
	CreateTimer(0.2, Timer_CarMove, carEntity, TIMER_FLAG_NO_MAPCHANGE);
}

// ###################################
// PRIVATE SPAWN CUSTOM CAR FUNCTIONS
// ###################################

SpawnCustomAlarmCar(const Float:entityPosition[3], const Float:entityAngles[3], const carType, const client = 0, const String:carColor[] = COLOR_REDCAR) {
	// init
	new carEntity, glassEntity, alarmTimer, chirpSound, alarmSound;
	new carLights[6], glassBlinkLight, glassBlinkTimer, gameEventInfo;

	decl Float:modelAngles[3], Float:modelRotation;
	decl Float:distanceYellow[3], Float:distanceRed[3], Float:distanceWhite[3], Float:distanceLamp[3]; 
	
	decl String:carName[64], String:glassName[64], String:alarmTimerName[64];
	decl String:chirpSoundName[64], String:alarmSoundName[64], String:carLightsName[64];
	decl String:carHeadLightsName[64], String:glassBlinkLightName[64], String:glassBlinkTimerName[64];
	decl String:modelCarName[128], String:modelGlassName[128], String:tempString[256];
	
	Format(carName, 64, "sm_alarmcar_car%d", globalCarNumber);
	Format(glassName, 64, "sm_alarmcar_glass%d", globalCarNumber);
	Format(glassBlinkLightName, 64, "sm_alarmcar_glasslight%d", globalCarNumber);
	Format(glassBlinkTimerName, 64, "sm_alarmcar_glasstimer%d", globalCarNumber);
	Format(alarmTimerName, 64, "sm_alarmcar_alarmtimer%d", globalCarNumber);
	Format(chirpSoundName, 64, "sm_alarmcar_chirpsound%d", globalCarNumber);
	Format(alarmSoundName, 64, "sm_alarmcar_alarmsound%d", globalCarNumber);
	Format(carLightsName, 64, "sm_alarmcar_carlights%d", globalCarNumber);
	Format(carHeadLightsName, 64, "sm_alarmcar_carheadlights%d", globalCarNumber);
	
	// check car type
	if (carType < 0 || carType > globalDataCarsCount-1) {
		PrintMessage(client, "[SM] Car type number is invalid!");
		return;	
	}
	
	// load car type data
	new indexStrings = carType*3;
	new indexValues = carType*5;
	
	GetArrayString(globalDataCarsStrings, indexStrings, modelCarName, 128);
	GetArrayString(globalDataCarsStrings, indexStrings+1, modelGlassName, 128);
	
	modelRotation = GetArrayCell(globalDataCarsValues, indexValues);
	GetArrayArray(globalDataCarsValues, indexValues+1, distanceYellow);
	GetArrayArray(globalDataCarsValues, indexValues+2, distanceRed);
	GetArrayArray(globalDataCarsValues, indexValues+3, distanceWhite);
	GetArrayArray(globalDataCarsValues, indexValues+4, distanceLamp);
	
	// model angles
	CopyVector(entityAngles, modelAngles);
	modelAngles[1] += modelRotation;
	
	// create car model
	// ################################
	carEntity = CreateAlarmCar();
	if (carEntity == -1) {
		PrintMessage(client, "[SM] Could not create car entity!");
		return;
	}
	
	DispatchKeyValue(carEntity, "targetname", carName);
	DispatchKeyValue(carEntity, "rendercolor", carColor);
	DispatchKeyValue(carEntity, "model", modelCarName);
	DispatchKeyValue(carEntity, "renderamt", "255");	
	
	Format(tempString, 256, "%s,Enable,,0,-1", alarmTimerName);
	DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
	Format(tempString, 256, "%s,Disable,,0,-1", alarmTimerName);
	DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
	Format(tempString, 256, "%s,PlaySound,,0,-1", alarmSoundName);
	DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
	Format(tempString, 256, "%s,StopSound,,0,-1", alarmSoundName);
	DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
	Format(tempString, 256, "%s,PlaySound,,0.2,-1", chirpSoundName);
	DispatchKeyValue(carEntity, "OnCarAlarmChirpStart", tempString);
	Format(tempString, 256, "%s,HideSprite,,0.7,-1", carLightsName);
	DispatchKeyValue(carEntity, "OnCarAlarmChirpEnd", tempString);
	Format(tempString, 256, "%s,ShowSprite,,0.2,-1", carLightsName);
	DispatchKeyValue(carEntity, "OnCarAlarmChirpStart", tempString);
	Format(tempString, 256, "%s,Disable,,0.5,-1", glassBlinkLightName);
	DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
	Format(tempString, 256, "%s,Kill,,0,-1", glassBlinkTimerName);
	DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
	
	TeleportEntity(carEntity, entityPosition, modelAngles, NULL_VECTOR);
	DispatchSpawn(carEntity);	
	ActivateEntity(carEntity);
	SetEntityMoveType(carEntity, MOVETYPE_NONE);
	
	// create glass model
	// ################################
	glassEntity = CreateCarGlass(modelGlassName, glassName, entityPosition, modelAngles, carName);
	if (glassEntity == -1) {
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create car glass entity!");
		return;
	}
	
	// create alarm timer
	// ################################
	alarmTimer = CreateEntityByName("logic_timer");	
	if (alarmTimer == -1) {
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create logic timer entity!");
		return;
	}	
	
	DispatchKeyValue(alarmTimer, "UseRandomTime", "0");
	DispatchKeyValue(alarmTimer, "targetname", alarmTimerName);
	DispatchKeyValue(alarmTimer, "StartDisabled", "1");
	DispatchKeyValue(alarmTimer, "spawnflags", "0");
	DispatchKeyValue(alarmTimer, "RefireTime", ".75");
	
	Format(tempString, 256, "%s,ShowSprite,,0,-1", carLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,HideSprite,,0.5,-1", carLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,HideSprite,,0.5,-1", carLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,ShowSprite,,0,-1", carLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	
	Format(tempString, 256, "%s,LightOff,,0.5,-1", carHeadLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,LightOn,,0,-1", carHeadLightsName);
	DispatchKeyValue(alarmTimer, "OnTimer", tempString);	

	TeleportEntity(alarmTimer, entityPosition, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(alarmTimer);

	// create glass blink light
	// ################################
	decl Float:blinkLightPosition[3];
	CopyVector(entityPosition, blinkLightPosition);
	MoveVectorPosition3D(blinkLightPosition, entityAngles, distanceLamp);
	
	glassBlinkLight = CreateCarBlinkLight(blinkLightPosition, glassBlinkLightName, carName);
	if (glassBlinkLight == -1) {
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create BLINK LIGHT entity!");
		return;
	}	

	// create glass blink light timer
	// ################################
	glassBlinkTimer = CreateEntityByName("logic_timer");	
	if (glassBlinkTimer == -1) {
		KillEntity(carEntity);
		KillEntity(alarmTimer);
		PrintMessage(client, "[SM] Could not create blink timer entity!");
		return;
	}
	
	DispatchKeyValue(glassBlinkTimer, "UseRandomTime", "0");
	DispatchKeyValue(glassBlinkTimer, "targetname", glassBlinkTimerName);
	DispatchKeyValue(glassBlinkTimer, "StartDisabled", "0");
	DispatchKeyValue(glassBlinkTimer, "spawnflags", "0");
	DispatchKeyValue(glassBlinkTimer, "RefireTime", "0.6");	
	
	Format(tempString, 256, "%s,ShowSprite,,0,-1", glassBlinkLightName);
	DispatchKeyValue(glassBlinkTimer, "OnTimer", tempString);
	Format(tempString, 256, "%s,HideSprite,,0.3,-1", glassBlinkLightName);
	DispatchKeyValue(glassBlinkTimer, "OnTimer", tempString);	
	
	TeleportEntity(glassBlinkTimer, entityPosition, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(glassBlinkTimer);
	ActivateEntity(glassBlinkTimer);
	
	// create game event info
	// ################################
	gameEventInfo = CreateGameEvent(entityPosition);
	if (gameEventInfo == -1) {
		KillEntity(carEntity);
		KillEntity(alarmTimer);
		KillEntity(glassBlinkTimer);
		
		PrintMessage(client, "[SM] Could not create game event info entity!");
		return;
	}	
	
	// create sounds
	// ################################
	new Float:soundsPosition[3];
	CopyVector(entityPosition, soundsPosition);
	soundsPosition[2] += 80.0;
	
	chirpSound = CreateCarSound(soundsPosition, chirpSoundName, carName, "Car.Alarm.Chirp2", "48");
	alarmSound = CreateCarSound(soundsPosition, alarmSoundName, carName, "Car.Alarm", "16");
	
	// create lights
	// ################################
	// (Yellow (X,Y,Z), Red, White)
	decl Float:distances[9];
	distances[0] = distanceYellow[0];
	distances[1] = distanceYellow[1];
	distances[2] = distanceYellow[2];
	distances[3] = distanceRed[0];
	distances[4] = distanceRed[1];
	distances[5] = distanceRed[2];
	distances[6] = distanceWhite[0];
	distances[7] = distanceWhite[1];
	distances[8] = distanceWhite[2];
	CreateLights(carLights, entityPosition, entityAngles, distances, carLightsName, carHeadLightsName, carName);

	// check entities
	// ################################
	decl String:entityName[16];
	new bool:somethingWrong;
	
	if (chirpSound == -1 || alarmSound == -1) {
		entityName = "sound";
		somethingWrong = true;	
	}
	else {
		for (new i = 0; i < 6; i++) {
			if (carLights[i] == -1) {
				entityName = "lights";
				somethingWrong = true;
				break;
			}
		}
	}		
	
	if (somethingWrong) {
		// delete everything
		KillEntity(carEntity);
		KillEntity(alarmTimer);	
		KillEntity(glassBlinkTimer);
		KillEntity(gameEventInfo);	
		
		PrintMessage(client, "[SM] Could not create %s entity!", entityName);
		return;
	}
	
	PrintMessage(client, "[SM] Spawned custom alarm car at %.2f %.2f %.2f (%.2f %.2f %.2f)", entityPosition[0], entityPosition[1], entityPosition[2], entityAngles[0], entityAngles[1], entityAngles[2]);
	globalCarNumber++;
	
	// allow car moving
	CreateTimer(0.2, Timer_CarMove, carEntity, TIMER_FLAG_NO_MAPCHANGE);
}

// ###################################
// PRIVATE SPAWN CAR GENERIC FUNCTIONS
// ###################################

public Action:Timer_CarMove(Handle:timer, any:carEntity) {
	if (IsValidEntity(carEntity)) SetEntityMoveType(carEntity, MOVETYPE_VPHYSICS);
}

CreateAlarmCar() {
	new carEntity = CreateEntityByName("prop_car_alarm");
	if (carEntity == -1) return -1;
	
	DispatchKeyValue(carEntity, "spawnflags", "256");
	DispatchKeyValue(carEntity, "fadescale", "1");
	DispatchKeyValue(carEntity, "fademindist", "-1"); 
	DispatchKeyValue(carEntity, "inertiaScale", "1.0"); 
	DispatchKeyValue(carEntity, "physdamagescale", "0.1"); 
	DispatchKeyValue(carEntity, "BreakableType", "0");
	DispatchKeyValue(carEntity, "forcetoenablemotion", "0");
	DispatchKeyValue(carEntity, "massScale", "0");
	DispatchKeyValue(carEntity, "PerformanceMode", "0");
	DispatchKeyValue(carEntity, "nodamageforces", "0");
	
	DispatchKeyValue(carEntity, "skin", "0");
	DispatchKeyValue(carEntity, "shadowcastdist", "0");
	DispatchKeyValue(carEntity, "rendermode", "0");
	DispatchKeyValue(carEntity, "renderfx", "0");
	DispatchKeyValue(carEntity, "pressuredelay", "0");
	DispatchKeyValue(carEntity, "minhealthdmg", "0");
	DispatchKeyValue(carEntity, "mindxlevel", "0");
	DispatchKeyValue(carEntity, "maxdxlevel", "0");
	DispatchKeyValue(carEntity, "fademaxdist", "0");
	DispatchKeyValue(carEntity, "ExplodeRadius", "0");
	DispatchKeyValue(carEntity, "ExplodeDamage", "0");
	DispatchKeyValue(carEntity, "disableshadows", "0");
	DispatchKeyValue(carEntity, "disablereceiveshadows", "0");
	DispatchKeyValue(carEntity, "Damagetype", "0");
	DispatchKeyValue(carEntity, "damagetoenablemotion", "0");
	DispatchKeyValue(carEntity, "body", "0");
	
	return carEntity;
}

CreateCarGlass(const String:modelName[], const String:targetName[], const Float:position[3], const Float:angle[3], const String:carName[]) {
	new glassEntity = CreateEntityByName("prop_car_glass");
	if (glassEntity == -1) return -1;
	
	DispatchKeyValue(glassEntity, "model", modelName);
	DispatchKeyValue(glassEntity, "targetname", targetName);
	
	DispatchKeyValue(glassEntity, "spawnflags", "0");	
	DispatchKeyValue(glassEntity, "solid", "6");
	DispatchKeyValue(glassEntity, "MinAnimTime", "5");
	DispatchKeyValue(glassEntity, "MaxAnimTime", "10");
	DispatchKeyValue(glassEntity, "fadescale", "1");
	DispatchKeyValue(glassEntity, "fademindist", "-1");
	
	// teleport and spawn
	TeleportEntity(glassEntity, position, angle, NULL_VECTOR);
	DispatchSpawn(glassEntity);
	ActivateEntity(glassEntity);
	
	// parent to car
	SetVariantString(carName);
	AcceptEntityInput(glassEntity, "SetParent", glassEntity, glassEntity, 0);	
	
	return glassEntity;
}

CreateGameEvent(const Float:position[3]) {
	new gameEventInfo = CreateEntityByName("info_game_event_proxy");
	if (gameEventInfo == -1) return -1;
	
	DispatchKeyValue(gameEventInfo, "targetname", "caralarm_game_event");
	DispatchKeyValue(gameEventInfo, "spawnflags", "1");
	DispatchKeyValue(gameEventInfo, "range", "100");
	DispatchKeyValue(gameEventInfo, "event_name", "explain_disturbance");
	
	TeleportEntity(gameEventInfo, position, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(gameEventInfo);	
	ActivateEntity(gameEventInfo);
	
	return gameEventInfo;
}

CreateCarSound(const Float:entityPosition[3], const String:targetName[], const String:sourceName[], const String:messageName[], const String:spawnFlags[]) {
	new soundEntity = CreateEntityByName("ambient_generic");
	if (soundEntity == -1) {
		return -1;
	}	
	
	DispatchKeyValue(soundEntity, "targetname", targetName);
	DispatchKeyValue(soundEntity, "SourceEntityName", sourceName);
	DispatchKeyValue(soundEntity, "message", messageName);
	DispatchKeyValue(soundEntity, "radius", "4000");
	DispatchKeyValue(soundEntity, "pitchstart", "100");
	DispatchKeyValue(soundEntity, "pitch", "100");
	DispatchKeyValue(soundEntity, "health", "10");
	DispatchKeyValue(soundEntity, "spawnflags", spawnFlags);	
	DispatchKeyValue(soundEntity, "volstart", "0");
	DispatchKeyValue(soundEntity, "spinup", "0");
	DispatchKeyValue(soundEntity, "spindown", "0");
	DispatchKeyValue(soundEntity, "preset", "0");
	DispatchKeyValue(soundEntity, "lfotype", "0");
	DispatchKeyValue(soundEntity, "lforate", "0");
	DispatchKeyValue(soundEntity, "lfomodvol", "0");
	DispatchKeyValue(soundEntity, "lfomodpitch", "0");
	DispatchKeyValue(soundEntity, "fadeoutsecs", "0");
	DispatchKeyValue(soundEntity, "fadeinsecs", "0");
	DispatchKeyValue(soundEntity, "cspinup", "0");
	
	TeleportEntity(soundEntity, entityPosition, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(soundEntity);
	ActivateEntity(soundEntity);
	
	SetVariantString(sourceName);
	AcceptEntityInput(soundEntity, "SetParent", soundEntity, soundEntity, 0);
	
	return soundEntity;
}

CreateLights(carLights[6], const Float:position[3], const Float:angle[3], const Float:distance[9], const String:lightName[], const String:headLightName[], const String:carName[]) {
	decl Float:lightPosition[3], Float:lightDistance[3];
	
	CopyVector(position, lightPosition);
	lightDistance[0] = distance[0];
	lightDistance[1] = distance[1]*-1.0;
	lightDistance[2] = distance[2];
	MoveVectorPosition3D(lightPosition, angle, lightDistance); // front left
	carLights[0] = CreateCarLight(lightPosition, lightName, carName, COLOR_YELLOWLIGHT);
	
	CopyVector(position, lightPosition);
	lightDistance[1] = distance[1];
	MoveVectorPosition3D(lightPosition, angle, lightDistance); // front right
	carLights[1] = CreateCarLight(lightPosition, lightName, carName, COLOR_YELLOWLIGHT);
	
	CopyVector(position, lightPosition);
	lightDistance[0] = distance[3]*-1.0;
	lightDistance[1] = distance[4]*-1.0;
	lightDistance[2] = distance[5];
	MoveVectorPosition3D(lightPosition, angle, lightDistance); // back left
	carLights[2] = CreateCarLight(lightPosition, lightName, carName, COLOR_REDLIGHT);
	
	CopyVector(position, lightPosition);
	lightDistance[1] = distance[4];
	MoveVectorPosition3D(lightPosition, angle, lightDistance); // back right
	carLights[3] = CreateCarLight(lightPosition, lightName, carName, COLOR_REDLIGHT);
	
	// create head lights
	CopyVector(position, lightPosition);
	lightDistance[0] = distance[6];
	lightDistance[1] = distance[7]*-1.0;
	lightDistance[2] = distance[8];
	MoveVectorPosition3D(lightPosition, angle, lightDistance); // front left
	carLights[4] = CreateCarHeadLight(lightPosition, angle, headLightName, carName);	

	CopyVector(position, lightPosition);
	lightDistance[1] = distance[7];
	MoveVectorPosition3D(lightPosition, angle, lightDistance); // front right
	carLights[5] = CreateCarHeadLight(lightPosition, angle, headLightName, carName);	
}

CreateCarBlinkLight(const Float:entityPosition[3], const String:targetName[], const String:parentName[]) {
	new lightEntity = CreateEntityByName("env_sprite");
	if (lightEntity == -1) {
		return -1;
	}	
	
	DispatchKeyValue(lightEntity, "targetname", targetName);
	DispatchKeyValue(lightEntity, "spawnflags", "0");
	DispatchKeyValue(lightEntity, "scale", "0.4");
	DispatchKeyValue(lightEntity, "rendermode", "9");
	DispatchKeyValue(lightEntity, "renderfx", "0");
	DispatchKeyValue(lightEntity, "rendercolor", COLOR_REDLIGHT);
	DispatchKeyValue(lightEntity, "renderamt", "255");
	DispatchKeyValue(lightEntity, "model", "sprites/glow.vmt");
	DispatchKeyValue(lightEntity, "HDRColorScale", "0.4");
	DispatchKeyValue(lightEntity, "GlowProxySize", "35");
	DispatchKeyValue(lightEntity, "framerate", "10.0");
	DispatchKeyValue(lightEntity, "fadescale", "1");
	DispatchKeyValue(lightEntity, "fademindist", "-1");
	DispatchKeyValue(lightEntity, "disablereceiveshadows", "0");
	
	TeleportEntity(lightEntity, entityPosition, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(lightEntity);
	ActivateEntity(lightEntity);
	
	SetVariantString(parentName);
	AcceptEntityInput(lightEntity, "SetParent", lightEntity, lightEntity, 0);
	
	return lightEntity;
}

CreateCarLight(const Float:entityPosition[3], const String:targetName[], const String:parentName[], const String:renderColor[]) {
	new lightEntity = CreateEntityByName("env_sprite");
	if (lightEntity == -1) {
		return -1;
	}	
	
	DispatchKeyValue(lightEntity, "targetname", targetName);
	DispatchKeyValue(lightEntity, "spawnflags", "0");
	DispatchKeyValue(lightEntity, "scale", ".5");
	DispatchKeyValue(lightEntity, "rendermode", "9");
	DispatchKeyValue(lightEntity, "renderfx", "0");
	DispatchKeyValue(lightEntity, "rendercolor", renderColor);
	DispatchKeyValue(lightEntity, "renderamt", "255");
	DispatchKeyValue(lightEntity, "model", "sprites/glow.vmt");
	DispatchKeyValue(lightEntity, "HDRColorScale", "0.7");
	DispatchKeyValue(lightEntity, "GlowProxySize", "5");
	DispatchKeyValue(lightEntity, "framerate", "10.0");
	DispatchKeyValue(lightEntity, "fadescale", "1");
	DispatchKeyValue(lightEntity, "fademindist", "-1");
	DispatchKeyValue(lightEntity, "disablereceiveshadows", "0");
	
	TeleportEntity(lightEntity, entityPosition, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(lightEntity);
	ActivateEntity(lightEntity);
	
	SetVariantString(parentName);
	AcceptEntityInput(lightEntity, "SetParent", lightEntity, lightEntity, 0);
	
	return lightEntity;
}

CreateCarHeadLight(const Float:entityPosition[3], const Float:entityAngles[3], const String:targetName[], const String:parentName[]) {
	new lightEntity = CreateEntityByName("beam_spotlight");
	if (lightEntity == -1) {
		return -1;
	}	
	
	DispatchKeyValue(lightEntity, "targetname", targetName);
	DispatchKeyValue(lightEntity, "spawnflags", "2");
	DispatchKeyValue(lightEntity, "spotlightwidth", "32");
	DispatchKeyValue(lightEntity, "spotlightlength", "256");
	DispatchKeyValue(lightEntity, "rendermode", "5");
	DispatchKeyValue(lightEntity, "rendercolor", COLOR_WHITELIGHT);
	DispatchKeyValue(lightEntity, "renderamt", "150");
	DispatchKeyValue(lightEntity, "maxspeed", "100");
	DispatchKeyValue(lightEntity, "HDRColorScale", ".5");
	DispatchKeyValue(lightEntity, "fadescale", "1");
	DispatchKeyValue(lightEntity, "fademindist", "-1");
	
	TeleportEntity(lightEntity, entityPosition, entityAngles, NULL_VECTOR);
	DispatchSpawn(lightEntity);
	ActivateEntity(lightEntity);
	
	SetVariantString(parentName);
	AcceptEntityInput(lightEntity, "SetParent", lightEntity, lightEntity, 0);
	
	return lightEntity;
}

// ###################################
// PRIVATE VECTOR FUNCTIONS
// ###################################

MoveVectorPosition3D(Float:position[3], const Float:constAngles[3], const Float:constDistance[3]) {
	decl Float:angle[3], Float:dirFw[3], Float:dirRi[3], Float:dirUp[3], Float:distance[3];
	CopyVector(constDistance, distance);
	
	angle[0] = DegToRad(constAngles[0]);
	angle[1] = DegToRad(constAngles[1]);
	angle[2] = DegToRad(constAngles[2]);	
	
	// roll (rotation over x)
	dirFw[0] = 1.0;
	dirFw[1] = 0.0;
	dirFw[2] = 0.0;
	dirRi[0] = 0.0;
	dirRi[1] = Cosine(angle[2]);
	dirRi[2] = Sine(angle[2])*-1;
	dirUp[0] = 0.0;
	dirUp[1] = Sine(angle[2]);
	dirUp[2] = Cosine(angle[2]);
	MatrixMulti(dirFw, dirRi, dirUp, distance);
	
	// pitch (rotation over y)
	dirFw[0] = Cosine(angle[0]);
	dirFw[1] = 0.0;
	dirFw[2] = Sine(angle[0]);
	dirRi[0] = 0.0;
	dirRi[1] = 1.0;
	dirRi[2] = 0.0;
	dirUp[0] = Sine(angle[0])*-1;
	dirUp[1] = 0.0;
	dirUp[2] = Cosine(angle[0]);
	MatrixMulti(dirFw, dirRi, dirUp, distance);

	// yaw (rotation over z)
	dirFw[0] = Cosine(angle[1]);
	dirFw[1] = Sine(angle[1])*-1;
	dirFw[2] = 0.0;
	dirRi[0] = Sine(angle[1]);
	dirRi[1] = Cosine(angle[1]);
	dirRi[2] = 0.0;
	dirUp[0] = 0.0;
	dirUp[1] = 0.0;
	dirUp[2] = 1.0;
	MatrixMulti(dirFw, dirRi, dirUp, distance);
	
	// addition
	for (new i = 0; i < 3; i++) position[i] += distance[i];
}

MatrixMulti(const Float:matA[3], const Float:matB[3], const Float:matC[3], Float:vec[3]) {
	new Float:res[3];
	for (new i = 0; i < 3; i++) res[0] += matA[i]*vec[i];
	for (new i = 0; i < 3; i++) res[1] += matB[i]*vec[i];
	for (new i = 0; i < 3; i++) res[2] += matC[i]*vec[i];	
	CopyVector(res, vec);
}

CopyVector(const Float:original[3], Float:copy[3]) {
	for (new i = 0; i < 3; i++) copy[i] = original[i];
}

// ###################################
// PRIVATE MISC FUNCTIONS
// ###################################

InitData() { 
	// reset arrays
	ClearArray(globalDataCarsStrings);
	ClearArray(globalDataTrucksStrings);
	ClearArray(globalDataCarsValues);
	ClearArray(globalDataTrucksValues);
	
	// load data into
	new Handle:dataHandle = CreateKeyValues("alarmcars_models");
	if (!FileToKeyValues(dataHandle, CONFIG_MODELS)) {
		PrintToServer("[SM] models config file not found!");
		return;
	}
	
	// load cars
	if (KvJumpToKey(dataHandle, "cars")) {
		if (KvJumpToKey(dataHandle, "info")) {
			globalDataCarsCount = KvGetNum(dataHandle, "count", 0);
			
			if (globalDataCarsCount > 0) {
				KvGoBack(dataHandle);
				if (KvJumpToKey(dataHandle, "data")) {
					KvGotoFirstSubKey(dataHandle);
					
					decl Float:rot, Float:dis_y[3], Float:dis_r[3], Float:dis_w[3], Float:dis_l[3];
					decl String:modc[128], String:modg[128], String:desc[256];
					
					for (new i = 0; i < globalDataCarsCount; i++) {
						// get data
						KvGetString(dataHandle, "model_car", modc, 128);
						KvGetString(dataHandle, "model_glass", modg, 128);
						rot = KvGetFloat(dataHandle, "rotation");
						KvGetVector(dataHandle, "distance_yellow", dis_y);
						KvGetVector(dataHandle, "distance_red", dis_r);
						KvGetVector(dataHandle, "distance_white", dis_w);
						KvGetVector(dataHandle, "distance_lamp", dis_l);
						KvGetString(dataHandle, "description", desc, 256);
						
						// precache models if neccessary
						if (!IsModelPrecached(modc)) PrecacheModel(modc, true);
						if (!IsModelPrecached(modg)) PrecacheModel(modg, true);
		
						// save data
						PushArrayString(globalDataCarsStrings, modc);
						PushArrayString(globalDataCarsStrings, modg);
						PushArrayString(globalDataCarsStrings, desc);
						
						PushArrayCell(globalDataCarsValues, rot);
						PushArrayArray(globalDataCarsValues, dis_y);
						PushArrayArray(globalDataCarsValues, dis_r);
						PushArrayArray(globalDataCarsValues, dis_w);
						PushArrayArray(globalDataCarsValues, dis_l);
		
						KvGotoNextKey(dataHandle);
					}					
				}
			}
		}
	}	
	else {
		PrintToServer("[SM] cars not found!");
	}
	
	// back to root
	KvRewind(dataHandle);

	// load trucks
	if (KvJumpToKey(dataHandle, "trucks")) {
		if (KvJumpToKey(dataHandle, "info")) {
			globalDataTrucksCount = KvGetNum(dataHandle, "count", 0);
			
			if (globalDataTrucksCount > 0) {
				KvGoBack(dataHandle);
				if (KvJumpToKey(dataHandle, "data")) {
					KvGotoFirstSubKey(dataHandle);
					
					decl Float:rot, Float:dis_y[3], Float:dis_r[3], Float:dis_w[3];
					decl String:modc[128], String:modg[128], String:desc[256];
					
					for (new i = 0; i < globalDataTrucksCount; i++) {
						// get data
						KvGetString(dataHandle, "model_car", modc, 128);
						KvGetString(dataHandle, "model_glass", modg, 128);
						rot = KvGetFloat(dataHandle, "rotation");
						KvGetVector(dataHandle, "distance_yellow", dis_y);
						KvGetVector(dataHandle, "distance_red", dis_r);
						KvGetVector(dataHandle, "distance_white", dis_w);
						KvGetString(dataHandle, "description", desc, 256);

						// precache models if neccessary
						if (!IsModelPrecached(modc)) PrecacheModel(modc, true);
						if (!IsModelPrecached(modg)) PrecacheModel(modg, true);
						
						// save data
						PushArrayString(globalDataTrucksStrings, modc);
						PushArrayString(globalDataTrucksStrings, modg);
						PushArrayString(globalDataTrucksStrings, desc);
						
						PushArrayCell(globalDataTrucksValues, rot);
						PushArrayArray(globalDataTrucksValues, dis_y);
						PushArrayArray(globalDataTrucksValues, dis_r);
						PushArrayArray(globalDataTrucksValues, dis_w);
		
						KvGotoNextKey(dataHandle);
					}					
				}
			}
		}
	}	
	else {
		PrintToServer("[SM] trucks not found!");
	}
	
	// close keyvalues
	CloseHandle(dataHandle);
	
	// precache normal car models
	if (!IsModelPrecached(ALARMCAR_MODEL)) PrecacheModel(ALARMCAR_MODEL, true);
	if (!IsModelPrecached(ALARMCAR_GLASS)) PrecacheModel(ALARMCAR_GLASS, true);
	if (!IsModelPrecached(ALARMCAR_GLASS_OFF)) PrecacheModel(ALARMCAR_GLASS_OFF, true);
	// and light model
	if (!IsModelPrecached("sprites/glow.vmt")) PrecacheModel("sprites/glow.vmt", true);
	if (!IsModelPrecached("sprites/light_glow03.vmt")) PrecacheModel("sprites/light_glow03.vmt", true);
	if (!IsModelPrecached("sprites/glow_test02.vmt")) PrecacheModel("sprites/glow_test02.vmt", true);
	
	// now it is allowed to spawn cars
	//globalIsDataInit = true;
}

InitMap() {
	DebugOutput("Function: init map");

	//if (!globalIsDataInit) return;
	if (globalIsMapInit) return;
	globalIsMapInit = true;

	globalCarNumber = 1;
	
	if (GetConVarBool(globalCVarEnable)) {
		PlaceAlarmCars();
	}
}

PlaceAlarmCars() {
	DebugOutput("Function: place alarm cars");

	new Handle:dataHandle = CreateKeyValues("alarmcars"); 
	
	if (!FileToKeyValues(dataHandle, CONFIG_LOCATIONS)) {
		PrintToServer("[SM] config file not found!");
		return;
	}
	
	decl String:mapName[64];
	GetCurrentMap(mapName, 64);
	
	if (!KvJumpToKey(dataHandle, mapName)) {
		PrintToServer("[SM] Map not found!");
		CloseHandle(dataHandle);
		return;
	}
	
	if (!KvJumpToKey(dataHandle, "info")) {
		PrintToServer("[SM] info not found!");
		CloseHandle(dataHandle);
		return;
	}	
	
	new carCount = KvGetNum(dataHandle, "count", 0);
	new customCount = KvGetNum(dataHandle, "count_custom", 0);
	new truckCount = KvGetNum(dataHandle, "count_truck", 0);
	
	if ((carCount + customCount + truckCount) < 1) {
		PrintToServer("[SM] no cars for this map!");
		CloseHandle(dataHandle);
		return;
	}	
	
	KvGoBack(dataHandle);
	
	decl Float:position[3], Float:angle[3], String:color[32];	
	decl String:model[128];
	new type;
	
	if (carCount > 0 && KvJumpToKey(dataHandle, "data")) {
		PrintToServer("[SM] %d cars found!", carCount);
		KvGotoFirstSubKey(dataHandle);
	
		for (new i = 0; i < carCount; i++) {
			KvGetVector(dataHandle, "position", position);
			KvGetVector(dataHandle, "angle", angle);
			KvGetString(dataHandle, "color", color, 32, COLOR_REDCAR);
			PrintToServer("[SM] spawning %d car at %f %f %f (%f,%f,%f - %s)", i, position[0], position[1], position[2], angle[0], angle[1], angle[2], color);
			SpawnAlarmCar(position, angle, 0, color);
		
			KvGotoNextKey(dataHandle);
		}
	}		
	
	KvGoBack(dataHandle);
	KvGoBack(dataHandle);
	
	if (customCount > 0 && KvJumpToKey(dataHandle, "data_custom")) {
		PrintToServer("[SM] %d custom cars found!", customCount);
		KvGotoFirstSubKey(dataHandle);
	
		for (new i = 0; i < customCount; i++) {
			KvGetString(dataHandle, "modelname", model, 128, "");
			KvGetVector(dataHandle, "position", position);
			KvGetVector(dataHandle, "angle", angle);
			KvGetString(dataHandle, "color", color, 32, COLOR_REDCAR);
			
			type = FindTypeByModelname(model, 0);
			if (type == -1) {
				PrintToServer("[SM] could not find type of model %s", model);
				continue;
			}
			
			PrintToServer("[SM] spawning %d custom car at %f %f %f (%f %f %f - %s [%d] - %s)", i, position[0], position[1], position[2], angle[0], angle[1], angle[2], model, type, color);
			SpawnCustomAlarmCar(position, angle, type, 0, color);
		
			KvGotoNextKey(dataHandle);
		}
	}		

	KvGoBack(dataHandle);
	KvGoBack(dataHandle);
	
	if (truckCount > 0 && KvJumpToKey(dataHandle, "data_truck")) {
		PrintToServer("[SM] %d custom trucks found!", customCount);
		KvGotoFirstSubKey(dataHandle);
	
		for (new i = 0; i < truckCount; i++) {
			KvGetString(dataHandle, "modelname", model, 128, "");
			KvGetVector(dataHandle, "position", position);
			KvGetVector(dataHandle, "angle", angle);
			
			type = FindTypeByModelname(model, 1);
			if (type == -1) {
				PrintToServer("[SM] could not find type of model %s", model);
				continue;
			}
			
			PrintToServer("[SM] spawning %d custom truck at %f %f %f (%f %f %f - %s [%d])", i, position[0], position[1], position[2], angle[0], angle[1], angle[2], model, type);
			SpawnCustomAlarmTruck(position, angle, type, 0);
		
			KvGotoNextKey(dataHandle);
		}
	}	
	
	CloseHandle(dataHandle);
}

FindGroupAndTypeByModelname(const String:modelName[], &group, &type) {
	if (StrEqual(ALARMCAR_MODEL, modelName, false)) {
		group = 2;
		return;
	}
	
	type = FindTypeByModelname(modelName, 0);
	if (type > -1) {
		group = 0;
		return;
	}
	
	type = FindTypeByModelname(modelName, 1);
	if (type > -1) {
		group = 1;
		return;
	}
	
	group = -1;
	return;
}

FindTypeByModelname(const String:modelName[], const group) {
	new index;
	
	// custom
	if (group == 0) {
		index = FindStringInArray(globalDataCarsStrings, modelName);
	}
	// truck
	else {
		index = FindStringInArray(globalDataTrucksStrings, modelName);
	}
	
	if (index == -1) return -1;
	return (index / 3);
}

SaveAlarmCars(const client = 0) {
	new carCount = 0, customCount = 0, truckCount = 0;
	new entity = -1, group, offset, tempColor[3], type;
	
	decl Float:carPositions[16][3], Float:carAngles[16][3]; 
	decl Float:customPositions[16][3], Float:customAngles[16][3]; 
	decl Float:truckPositions[16][3], Float:truckAngles[16][3];
	
	decl String:carColors[16][16], String:customColors[16][16];
	decl String:customModel[16][128], String:truckModel[16][128];
	decl String:targetName[64], String:tempModel[128];
	
	// find all alarm cars
	while ((entity = FindEntityByClassname(entity, "prop_car_alarm")) != -1) {
		// check if it is a plugin one
		GetTargetname(entity, targetName);
		if (StrContains(targetName, "sm_alarmcar_", false) == -1) continue;
		
		// get model
		GetEntPropString(entity, Prop_Data, "m_ModelName", tempModel, 128);		

		// get group and type
		FindGroupAndTypeByModelname(tempModel, group, type);
		
		// model known?
		if (group == -1) continue;
		
		// normal alarmcar
		if (group == 2) {
			// get position and angle
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", carPositions[carCount]);
			GetEntPropVector(entity, Prop_Send, "m_angRotation", carAngles[carCount]);
		
			// get color
			offset = GetEntSendPropOffs(entity, "m_clrRender");
			tempColor[0] = GetEntData(entity, offset, 1);
			tempColor[1] = GetEntData(entity, offset + 1, 1);
			tempColor[2] = GetEntData(entity, offset + 2, 1);		
		
			// convert to string
			Format(carColors[carCount], 16, "%d %d %d", tempColor[0], tempColor[1], tempColor[2]);
		
			// increment count
			carCount++;
		}
		// truck
		else if (group == 1) {
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", truckPositions[truckCount]);
			GetEntPropVector(entity, Prop_Send, "m_angRotation", truckAngles[truckCount]);		
			
			// get rotation to adjust angle vector
			new Float:rot = GetArrayCell(globalDataTrucksValues, (type*4));
			truckAngles[truckCount][1] -= rot;
			
			// copy model
			strcopy(truckModel[truckCount], 128, tempModel);
			
			truckCount++;
		}
		// custom car
		else {
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", customPositions[customCount]);
			GetEntPropVector(entity, Prop_Send, "m_angRotation", customAngles[customCount]);		
			
			// get rotation to adjust angle vector
			new Float:rot = GetArrayCell(globalDataCarsValues, (type*5));
			customAngles[customCount][1] -= rot;
			
			// copy model
			strcopy(customModel[customCount], 128, tempModel);
			
			offset = GetEntSendPropOffs(entity, "m_clrRender");
			tempColor[0] = GetEntData(entity, offset, 1);
			tempColor[1] = GetEntData(entity, offset + 1, 1);
			tempColor[2] = GetEntData(entity, offset + 2, 1);		
			Format(customColors[customCount], 16, "%d %d %d", tempColor[0], tempColor[1], tempColor[2]);
			
			customCount++;		
		}
	}
	
	if ((carCount + customCount + truckCount) < 1) {
		PrintMessage(client, "[SM] No cars found on the map!");
		return;
	}
	
	PrintMessage(client, "[SM] Found %d cars on the map.", carCount);
	PrintMessage(client, "[SM] Found %d custom cars on the map.", customCount);
	PrintMessage(client, "[SM] Found %d custom trucks on the map.", truckCount);	
	
	// create keyvalues and load old data
	new Handle:dataHandle = CreateKeyValues("alarmcars"); 
	FileToKeyValues(dataHandle, CONFIG_LOCATIONS);
	
	// get map
	decl String:mapName[64];
	GetCurrentMap(mapName, 64);	

	// create general structure
	KvJumpToKey(dataHandle, mapName, true);
	KvJumpToKey(dataHandle, "info", true);
	KvSetNum(dataHandle, "count", carCount);
	KvSetNum(dataHandle, "count_custom", customCount);
	KvSetNum(dataHandle, "count_truck", truckCount);
	KvGoBack(dataHandle);
	KvDeleteKey(dataHandle, "data");
	KvDeleteKey(dataHandle, "data_custom");
	KvDeleteKey(dataHandle, "data_truck");
		
	decl String:tempString[8];
	
	// save cars
	KvJumpToKey(dataHandle, "data", true);
	for (new i = 0; i < carCount; i++) {
		Format(tempString, 8, "%d", (i+1));
		KvJumpToKey(dataHandle, tempString, true);
		KvSetVector(dataHandle, "position", carPositions[i]);
		KvSetVector(dataHandle, "angle", carAngles[i]);
		KvSetString(dataHandle, "color", carColors[i]);
		KvGoBack(dataHandle);
	}
	
	KvGoBack(dataHandle);

	// save custom cars
	KvJumpToKey(dataHandle, "data_custom", true);
	for (new i = 0; i < customCount; i++) {
		Format(tempString, 8, "%d", (i+1));
		KvJumpToKey(dataHandle, tempString, true);
		KvSetString(dataHandle, "modelname", customModel[i]);
		KvSetVector(dataHandle, "position", customPositions[i]);
		KvSetVector(dataHandle, "angle", customAngles[i]);
		KvSetString(dataHandle, "color", customColors[i]);
		KvGoBack(dataHandle);
	}
	
	KvGoBack(dataHandle);	
	
	// save custom trucks
	KvJumpToKey(dataHandle, "data_truck", true);
	for (new i = 0; i < truckCount; i++) {
		Format(tempString, 8, "%d", (i+1));
		KvJumpToKey(dataHandle, tempString, true);
		KvSetString(dataHandle, "modelname", truckModel[i]);
		KvSetVector(dataHandle, "position", truckPositions[i]);
		KvSetVector(dataHandle, "angle", truckAngles[i]);
		KvGoBack(dataHandle);
	}

	// rewind and save
	KvRewind(dataHandle);
	KeyValuesToFile(dataHandle, CONFIG_LOCATIONS);
	CloseHandle(dataHandle);
	PrintMessage(client, "[SM] Alarmcars successfully saved!");
}

GetClientInFrontLocation(client, Float:entityPosition[3], Float:entityAngles[3] = NULL_VECTOR, Float:clientDistance = 200.0){
    decl Float:clientOrigin[3], Float:clientAngles[3], Float:clientDirection[3];
	
    GetClientAbsOrigin(client, clientOrigin);
    GetClientEyeAngles(client, clientAngles);
    GetAngleVectors(clientAngles, clientDirection, NULL_VECTOR, NULL_VECTOR);
    
    entityPosition[0] = clientOrigin[0] + clientDirection[0] * clientDistance;
    entityPosition[1] = clientOrigin[1] + clientDirection[1] * clientDistance;
    entityPosition[2] = clientOrigin[2];
    
    entityAngles[0] = 0.0;
    entityAngles[1] = clientAngles[1];
    entityAngles[2] = 0.0;
}

PrintMessage(const client, const String:text[], any:...) {
	new size = strlen(text) + 255;
	new String:tempText[size];
	VFormat(tempText, size, text, 3);

	if (client == 0) PrintToServer("%s", tempText);
	else PrintToChat(client, "%s", tempText);
}

FindEntityAt(const String:entityClassname[], const Float:entityPosition[3], const bool:checkTargetname = false, const String:searchString[] = "", entity = -1, const Float:positionRange = 100.0) {
	decl Float:tempPosition[3], String:targetName[64];
	
	while ((entity = FindEntityByClassname(entity, entityClassname)) != -1) {
		if (entity < 0) entity = EntRefToEntIndex(entity);
		
		// get position and compare		 
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", tempPosition);			
		if (FloatCompare(GetVectorDistance(tempPosition, entityPosition), positionRange) < 1) {
			// extra targetname check on?
			if (checkTargetname) {
				GetTargetname(entity, targetName);
				// contains not our string? skip!
				if (StrContains(targetName, searchString, false) == -1) continue;
			}
			
			return entity;
		}	
	}
	return -1;
}

GetTargetname(const entity, String:entityName[64]) {
	if (!IsValidEntity(entity)) return;
	if (FindDataMapOffs(entity, "m_iName") == -1) return;
    
	GetEntPropString(entity, Prop_Data, "m_iName", entityName, 64);
}  

KillEntity(const entity) {
	if (entity < 1) return;
	if (!IsValidEntity(entity)) return;
	if (AcceptEntityInput(entity, "Kill")) return;
	
	RemoveEdict(entity);
}

bool:FindCarEntitiesAt(const Float:entityPosition[3], const client, &carEntity, carTimer[2], &gameEventInfo) {
	carEntity = FindEntityAt("prop_car_alarm", entityPosition);
	if (carEntity == -1) {
		PrintMessage(client, "[SM] no car at %f %f %f found!", entityPosition[0], entityPosition[1], entityPosition[2]);
		return false;
	}
	
	// get target name, check it and extract carnumber
	decl String:carTargetname[64]/*, String:tempTargetname[64]*/;
	GetTargetname(carEntity, carTargetname);
	
	if (StrContains(carTargetname, "sm_alarmcar_", false) == -1) {
		PrintMessage(client, "[SM] the car found was not created by plugin!");
		return false;
	}
	
	new carNumber = StringToInt(carTargetname[15]);
	PrintMessage(client, "[SM] found plugin car number %d!", carNumber);
	
	// get real position
	decl Float:realPosition[3];
	GetEntPropVector(carEntity, Prop_Send, "m_vecOrigin", realPosition);	

	// timer
	carTimer[0] = FindEntityAt("logic_timer", realPosition);
	carTimer[1] = FindEntityAt("logic_timer", realPosition, false, "", carTimer[0]);
	
	// game event info
	gameEventInfo = FindEntityAt("info_game_event_proxy", realPosition);
	
	return true;
}

stock DebugOutput(const String:text[], any:...) {
#if DEBUG_ENABLED == 1
	new size = strlen(text) + 255;
	new String:tempText[size];
	VFormat(tempText, size, text, 2);

	LogToFile(DEBUG_LOGFILE, "%s", tempText);
#endif
}