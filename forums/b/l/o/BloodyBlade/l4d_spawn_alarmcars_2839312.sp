#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CONFIG_LOCATIONS	"./cfg/sourcemod/alarmcars_location.cfg"
#define CONFIG_MODELS		"./cfg/sourcemod/alarmcars_models.cfg"
#define CVAR_FLAGS 			FCVAR_NOTIFY
#define DEBUG_ENABLED		0
#define DEBUG_LOGFILE		"./alarmcar_debug_file.txt"
#define PLUGIN_VERSION 		"1.0.4d"

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
 *   + updated plugin for support of custom alarm car models divided in two categories (cars / trucks)
 *   + updated config file to support custom models
 *   + added new commands for spawning --> sm_alarmcar_spawn_custom, sm_alarmcar_spawn_custom_at, sm_alarmcar_spawn_truck and sm_alarmcar_spawn_truck_at
 *   + added new command to list alle possible models to spawn --> sm_alarmcar_list_customs
 *   + updated old commands --> sm_alarmcar_move, sm_alarmcar_remove and sm_alarmcar_remove_at
 *   + updated save command and mapstart function for new config files
 * v1.0.4a:
 *  - Fixed CreateEntityByName runing before OnMapStart -- Mr. Zero
 * v1.0.4b:
 *  - Fixed round start spawn car -- KillJoy
 * v1.0.4c:
 *  - Fixed some warnings -- Mart
 *  - Merged Zero and KillJoy versions -- Mart
 *  - Added glass blinking fix on tank hit -- Mart
 * v1.0.4d:
 *  - Fixed custom cars/trucks not spawning when there is no normal alarm car in the config -- Mart
 *  - Added command sm_alarmcar_reload_config to reload the map based config file -- Mart
 */

public Plugin myinfo =
{
	name = "[L4D1&2] Spawn Alarmcars",
	author = "Die Teetasse, Quick fixed by Mr. Zero",
	description = "Spawns fully function alarm cars.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1313372"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

// ###################################
// GLOBAL THINGS
// ###################################

bool g_IsBeforeMapStart = true, globalIsMapInit = false;
ConVar globalCVarEnable;
ArrayList globalDataCarsStrings = null, globalDataCarsValues = null, globalDataTrucksStrings = null, globalDataTrucksValues = null;
int globalCarNumber = 0, globalDataCarsCount = 0, globalDataTrucksCount = 0;

public void OnPluginStart()
{
	// check game
	char game[12];
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
	RegAdminCmd("sm_alarmcar_reload_config", Command_ReloadConfig, ADMFLAG_KICK, "sm_alarmcar_reload| Reload config from file /cfg/sourcemod/alarmcars_location.cfg.");
	RegAdminCmd("sm_alarmcar_spawn", Command_SpawnCarInFront, ADMFLAG_KICK, "sm_alarmcar_spawn | Spawns a fully functional alarm car in front of you.");
	RegAdminCmd("sm_alarmcar_spawn_at", Command_SpawnCarAt, ADMFLAG_KICK, "sm_alarmcar_spawn_at <x> <y> <z> <pitch> <yaw> <roll> [r] [g] [b] | Spawns a fully functional alarm car at the given position, angles and optional color.");
	RegAdminCmd("sm_alarmcar_spawn_custom", Command_SpawnCostumInFront, ADMFLAG_KICK, "sm_alarmcar_spawn_custom <type> | Spawns a fully functional alarm custom car in front of you.");
	RegAdminCmd("sm_alarmcar_spawn_custom_at", Command_SpawnCostumAt, ADMFLAG_KICK, "sm_alarmcar_spawn_custom_at <type> <x> <y> <z> <pitch> <yaw> <roll> [r] [g] [b] | Spawns a fully functional alarm custom car at the given position, angles and optional color.");
	RegAdminCmd("sm_alarmcar_spawn_truck", Command_SpawnTruckInFront, ADMFLAG_KICK, "sm_alarmcar_spawn_truck <type> | Spawns a fully functional alarm truck in front of you.");
	RegAdminCmd("sm_alarmcar_spawn_truck_at", Command_SpawnTruckAt, ADMFLAG_KICK, "sm_alarmcar_spawn_truck_at <type> <x> <y> <z> <pitch> <yaw> <roll> | Spawns a fully functional alarm truck at the given position and optional angles.");

	// hook events
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_freeze_end", Event_RoundStart); // by KillJoy
	HookEvent("mission_lost", Event_RoundEnd); // by KillJoy
	HookEvent("round_end", Event_RoundEnd);

	// init arrays
	globalDataCarsStrings = new ArrayList(128);
	globalDataTrucksStrings = new ArrayList(128);

	globalDataCarsValues = new ArrayList(3);
	globalDataTrucksValues = new ArrayList(3);

	// init data
	InitData();
}

public void OnMapStart()
{
	#if DEBUG_ENABLED
	DebugOutput("Forward: map start");
	#endif
	g_IsBeforeMapStart = false;
	InitData();
	InitMap();
}

public void OnMapEnd()
{
	#if DEBUG_ENABLED
	DebugOutput("Forward: map end");
	#endif
	g_IsBeforeMapStart = true;
	globalIsMapInit = false;
}

// ###################################
// PUBLIC HOOKED EVENTS
// ###################################

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUG_ENABLED
	DebugOutput("Event: round start");
	#endif
	if (g_IsBeforeMapStart) return;
	InitMap();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUG_ENABLED
	DebugOutput("Event: round end");
	#endif
	globalIsMapInit = false;
}

// ###################################
// PUBLIC ADMIN COMMANDS
// ###################################

// LIST
// ##################

Action Command_ListCustomCars(int client, int args)
{
	char desc[256], model[128];
	PrintMessage(client, "[SM] %d custom car(s):", globalDataCarsCount);

	for (int i = 0; i < globalDataCarsCount; i++)
	{
		globalDataCarsStrings.GetString((i*3), model, 128);
		globalDataCarsStrings.GetString((i*3)+2, desc, 256);
		PrintMessage(client, "[SM] - %d: %s [%s]", i, desc, model);
	}

	PrintMessage(client, "[SM] %d custom truck(s):", globalDataTrucksCount);

	for (int i = 0; i < globalDataTrucksCount; i++)
	{
		globalDataTrucksStrings.GetString((i * 3), model, 128);
		globalDataTrucksStrings.GetString((i * 3) + 2, desc, 256);
		PrintMessage(client, "[SM] - %d: %s [%s]", i, desc, model);
	}

	return Plugin_Handled;
}

// MOVE
// ##################

Action Command_MoveCarInFront(int client, int args)
{
	if (client == 0) client = 1; // DEBUG
	if (client == 0)
	{
		PrintToServer("[SM] This command can only be used by a client!");
		return Plugin_Handled;
	}

	if (args != 3 && args != 6)
	{
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_move <PosX> <PosY> <PosZ> [NewPitch] [NewYaw] [NewRoll]");
		return Plugin_Handled;
	}

	float entityPosition[3], entityAngles[3];
	GetClientInFrontLocation(client, entityPosition, entityAngles);

	float newPosition[3];
	char tempFloat[16];

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(1+i, tempFloat, 16);
		newPosition[i] = StringToFloat(tempFloat);
	}

	if (args == 3) MoveAlarmCar(entityPosition, newPosition, NULL_VECTOR, client);
	else
	{
		float newAngle[3];
		for (int i = 0; i < 3; i++)
		{
			GetCmdArg(4+i, tempFloat, 16);
			newAngle[i] = StringToFloat(tempFloat);
		}

		MoveAlarmCar(entityPosition, newPosition, newAngle, client);
	}

	return Plugin_Handled;
}

Action Command_MoveCarAt(int client, int args)
{
	if (args != 6 && args != 9)
	{
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_move_at <PosX> <PosY> <PosZ> <NewPosX> <NewPosY> <NewPosZ> [NewPitch] [NewYaw] [NewRoll]");
		return Plugin_Handled;
	}

	float entityPosition[3], newPosition[3];
	char tempFloat[16];

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(1+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(4+i, tempFloat, 16);
		newPosition[i] = StringToFloat(tempFloat);
	}

	if (args == 6) MoveAlarmCar(entityPosition, newPosition, NULL_VECTOR, client);
	else
	{
		float newAngle[3];
		for (int i = 0; i < 3; i++)
		{
			GetCmdArg(7+i, tempFloat, 16);
			newAngle[i] = StringToFloat(tempFloat);
		}

		MoveAlarmCar(entityPosition, newPosition, newAngle, client);
	}

	return Plugin_Handled;
}

// REMOVE
// ##################

Action Command_RemoveCarInFront(int client, int args)
{
	if (client == 0) client = 1; // DEBUG
	if (client == 0)
	{
		PrintToServer("[SM] This command can only be used by a client!");
		return Plugin_Handled;
	}

	float entityPosition[3], entityAngles[3];
	GetClientInFrontLocation(client, entityPosition, entityAngles);
	RemoveAlarmCar(entityPosition, client);

	return Plugin_Handled;
}

Action Command_RemoveCarAt(int client, int args)
{
	if (args != 3)
	{
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_remove_at <PosX> <PosY> <PosZ>");
		return Plugin_Handled;
	}

	float entityPosition[3];
	char tempFloat[16];

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(1+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}

	RemoveAlarmCar(entityPosition, client);

	return Plugin_Handled;
}

// ROTATE
// ##################

Action Command_RotateCarInFront(int client, int args)
{
	if (client == 0) client = 1; // DEBUG
	if (client == 0)
	{
		PrintToServer("[SM] This command can only be used by a client!");
		return Plugin_Handled;
	}

	if (args != 3)
	{
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_rotate <Pitch> <Yaw> <Roll>");
		return Plugin_Handled;
	}

	float newAngle[3];
	char tempFloat[16];

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(1+i, tempFloat, 16);
		newAngle[i] = StringToFloat(tempFloat);
	}

	float entityPosition[3];
	GetClientInFrontLocation(client, entityPosition);
	RotateAlarmCar(entityPosition, newAngle, client);

	return Plugin_Handled;
}

Action Command_RotateCarAt(int client, int args)
{
	if (args != 6)
	{
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_rotate_at <PosX> <PosY> <PosZ> <Pitch> <Yaw> <Roll>");
		return Plugin_Handled;
	}

	float entityPosition[3], newAngle[3];
	char tempFloat[16];

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(1+i, tempFloat, 16);
		newAngle[i] = StringToFloat(tempFloat);
	}

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(4+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}

	RotateAlarmCar(entityPosition, newAngle, client);

	return Plugin_Handled;
}

// SAVE
// ##################

Action Command_SaveCarsToConfig(int client, int args)
{
	SaveAlarmCars(client);
	return Plugin_Handled;
}

// RELOAD
// ##################

Action Command_ReloadConfig(int client, int args)
{
	PlaceAlarmCars();
	return Plugin_Handled;
}

// SPAWN (NORMAL)
// ##################

Action Command_SpawnCarInFront(int client, int args)
{
	if (client == 0) client = 1; // DEBUG
	if (client == 0)
	{
		PrintToServer("[SM] This command can only be used by a client!");
		return Plugin_Handled;
	}

	float entityPosition[3], entityAngles[3];
	GetClientInFrontLocation(client, entityPosition, entityAngles);

	SpawnAlarmCar(entityPosition, entityAngles, client);

	return Plugin_Handled;
}

Action Command_SpawnCarAt(int client, int args)
{
	if (args != 6 && args != 9)
	{
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_spawn_at <PosX> <PosY> <PosZ> <Pitch> <Yaw> <Roll> [ColorR] [ColorG] [ColorB]");
		return Plugin_Handled;
	}

	float entityPosition[3], entityAngles[3];
	char tempFloat[16];

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(1+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(4+i, tempFloat, 16);
		entityAngles[i] = StringToFloat(tempFloat);
	}

	if (args == 6) SpawnAlarmCar(entityPosition, entityAngles, client);
	else
	{
		int entityColor[3];
		char entityColorString[16];
		for (int i = 0; i < 3; i++)
		{
			GetCmdArg(7+i, tempFloat, 16);
			entityColor[i] = StringToInt(tempFloat);
		}

		Format(entityColorString, 16, "%d %d %d", entityColor[0], entityColor[1], entityColor[2]);
		SpawnAlarmCar(entityPosition, entityAngles, client, entityColorString);
	}

	return Plugin_Handled;
}

// SPAWN (CUSTOM)
// ##################

Action Command_SpawnCostumInFront(int client, int args)
{
	if (client == 0) client = 1; // DEBUG
	if (client == 0)
	{
		PrintToServer("[SM] This command can only be used by a client!");
		return Plugin_Handled;
	}

	if (args != 1)
	{
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_spawn_custom <Type>");
		return Plugin_Handled;
	}

	float entityPosition[3], entityAngles[3];
	GetClientInFrontLocation(client, entityPosition, entityAngles);

	char temp[8];
	GetCmdArg(1, temp, 8);
	int type = StringToInt(temp);
	SpawnCustomAlarmCar(entityPosition, entityAngles, type, client);

	return Plugin_Handled;
}

Action Command_SpawnCostumAt(int client, int args)
{
	if (args != 7 && args != 10)
	{
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_spawn_at <Type> <PosX> <PosY> <PosZ> <Pitch> <Yaw> <Roll> [ColorR] [ColorG] [ColorB]");
		return Plugin_Handled;
	}

	float entityPosition[3], entityAngles[3];
	char tempFloat[16];

	GetCmdArg(1, tempFloat, 16);
	int type = StringToInt(tempFloat);

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(2+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(5+i, tempFloat, 16);
		entityAngles[i] = StringToFloat(tempFloat);
	}

	if (args == 6) SpawnCustomAlarmCar(entityPosition, entityAngles, type, client);
	else
	{
		int entityColor[3];
		char entityColorString[16];
		for (int i = 0; i < 3; i++)
		{
			GetCmdArg(8+i, tempFloat, 16);
			entityColor[i] = StringToInt(tempFloat);
		}

		Format(entityColorString, 16, "%d %d %d", entityColor[0], entityColor[1], entityColor[2]);
		SpawnCustomAlarmCar(entityPosition, entityAngles, type, client, entityColorString);
	}

	return Plugin_Handled;
}

// SPAWN (TRUCK)
// ##################

Action Command_SpawnTruckInFront(int client, int args)
{
	if (client == 0) client = 1; // DEBUG
	if (client == 0)
	{
		PrintToServer("[SM] This command can only be used by a client!");
		return Plugin_Handled;
	}

	if (args != 1)
	{
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_spawn_truck <Type>");
		return Plugin_Handled;
	}

	float entityPosition[3], entityAngles[3];
	GetClientInFrontLocation(client, entityPosition, entityAngles, 300.0);

	char temp[8];
	GetCmdArg(1, temp, 8);
	int type = StringToInt(temp);

	SpawnCustomAlarmTruck(entityPosition, entityAngles, type, client);

	return Plugin_Handled;
}

Action Command_SpawnTruckAt(int client, int args)
{
	if (args != 7)
	{
		PrintMessage(client, "[SM] Correct use: sm_alarmcar_spawn_truck_at <Type> <PosX> <PosY> <PosZ> <Pitch> <Yaw> <Roll>");
		return Plugin_Handled;
	}

	float entityPosition[3], entityAngles[3];
	char tempFloat[16];

	GetCmdArg(1, tempFloat, 16);
	int type = StringToInt(tempFloat);

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(2+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(5 + i, tempFloat, 16);
		entityAngles[i] = StringToFloat(tempFloat);
	}

	SpawnCustomAlarmTruck(entityPosition, entityAngles, type, client);

	return Plugin_Handled;
}

// ###################################
// PRIVATE MOVE/ROTATE CAR FUNCTIONS
// ###################################

stock void MoveAlarmCar(const float entityPosition[3], const float newPosition[3], const float newAngle[3] = NULL_VECTOR, const int client = 0)
{
	int carEntity, carTimer[2], gameEventInfo;
	if (!FindCarEntitiesAt(entityPosition, client, carEntity, carTimer, gameEventInfo))
	{
		return;
	}

	// teleport
	TeleportEntity(carEntity, newPosition, newAngle, NULL_VECTOR);
	TeleportEntity(carTimer[0], newPosition, newAngle, NULL_VECTOR);
	TeleportEntity(carTimer[1], newPosition, newAngle, NULL_VECTOR);
	TeleportEntity(gameEventInfo, newPosition, newAngle, NULL_VECTOR);
}

stock void RotateAlarmCar(const float entityPosition[3], const float newAngle[3], const int client = 0)
{
	int carEntity, carTimer[2], gameEventInfo;
	if (!FindCarEntitiesAt(entityPosition, client, carEntity, carTimer, gameEventInfo))
	{
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

stock void RemoveAlarmCar(const float entityPosition[3], const int client = 0)
{
	int carEntity, carTimer[2], gameEventInfo;
	if (!FindCarEntitiesAt(entityPosition, client, carEntity, carTimer, gameEventInfo))
	{
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

stock void SpawnAlarmCar(const float entityPosition[3], const float entityAngles[3], const int client = 0, const char[] carColor = COLOR_REDCAR)
{
	// init
	int carEntity, glassEntity, glassOffEntity, alarmTimer, chirpSound, alarmSound, carLights[6], gameEventInfo;
	char carName[64], glassName[64], glassOffName[64], alarmTimerName[64], chirpSoundName[64], alarmSoundName[64], carLightsName[64], carHeadLightsName[64], tempString[256];

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
	if (carEntity == -1)
	{
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
	Format(tempString, 256, "%s,Kill,,0,-1", glassName);
	DispatchKeyValue(carEntity, "OnHitByTank", tempString);

	TeleportEntity(carEntity, entityPosition, entityAngles, NULL_VECTOR);
	DispatchSpawn(carEntity);
	ActivateEntity(carEntity);
	SetEntityMoveType(carEntity, MOVETYPE_NONE);

	// create glass model
	// ################################
	glassEntity = CreateCarGlass(ALARMCAR_GLASS, glassName, entityPosition, entityAngles, carName);
	if (glassEntity == -1)
	{
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create car glass entity!");
		return;
	}

	// create off glass model
	// ################################
	glassOffEntity = CreateCarGlass(ALARMCAR_GLASS_OFF, glassOffName, entityPosition, entityAngles, carName);
	if (glassOffEntity == -1)
	{
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create car glass off entity!");
		return;
	}

	// create alarm timer
	// ################################
	alarmTimer = CreateEntityByName("logic_timer");
	if (alarmTimer == -1)
	{
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
	if (gameEventInfo == -1)
	{
		KillEntity(carEntity);
		KillEntity(alarmTimer);
		PrintMessage(client, "[SM] Could not create game event info entity!");
		return;
	}

	// create sounds
	// ################################
	float soundsPosition[3];
	CopyVector(entityPosition, soundsPosition);
	soundsPosition[2] += 80.0;

	chirpSound = CreateCarSound(soundsPosition, chirpSoundName, carName, "Car.Alarm.Chirp2", "48");
	alarmSound = CreateCarSound(soundsPosition, alarmSoundName, carName, "Car.Alarm", "16");

	// create lights
	// ################################
	// (Yellow (X,Y,Z), Red, White)
	float distances[9] = {DISTANCE_FRONT, DISTANCE_SIDETURN, DISTANCE_UPFRONT, DISTANCE_BACK, DISTANCE_SIDE, DISTANCE_UPBACK, DISTANCE_FRONT, DISTANCE_SIDE, DISTANCE_UPFRONT};
	CreateLights(carLights, entityPosition, entityAngles, distances, carLightsName, carHeadLightsName, carName);

	// check entities
	// ################################
	char entityName[16];
	bool somethingWrong;

	if (chirpSound == -1 || alarmSound == -1)
	{
		entityName = "sound";
		somethingWrong = true;
	}
	else
	{
		for (int i = 0; i < 6; i++)
		{
			if (carLights[i] == -1)
			{
				entityName = "lights";
				somethingWrong = true;
				break;
			}
		}
	}

	if (somethingWrong)
	{
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

stock void SpawnCustomAlarmTruck(const float entityPosition[3], const float entityAngles[3], const int carType, const int client = 0)
{
	// init
	int carEntity, glassEntity, alarmTimer, chirpSound, alarmSound, carLights[6], gameEventInfo;
	float modelAngles[3], modelRotation, distanceYellow[3], distanceRed[3], distanceWhite[3];
	char carName[64], glassName[64], alarmTimerName[64], chirpSoundName[64], alarmSoundName[64], carLightsName[64], carHeadLightsName[64], modelCarName[128], modelGlassName[128], tempString[256];

	Format(carName, 64, "sm_alarmcar_car%d", globalCarNumber);
	Format(glassName, 64, "sm_alarmcar_glass%d", globalCarNumber);
	Format(alarmTimerName, 64, "sm_alarmcar_alarmtimer%d", globalCarNumber);
	Format(chirpSoundName, 64, "sm_alarmcar_chirpsound%d", globalCarNumber);
	Format(alarmSoundName, 64, "sm_alarmcar_alarmsound%d", globalCarNumber);
	Format(carLightsName, 64, "sm_alarmcar_carlights%d", globalCarNumber);
	Format(carHeadLightsName, 64, "sm_alarmcar_carheadlights%d", globalCarNumber);

	// check car type
	if (carType < 0 || carType > globalDataTrucksCount-1)
	{
		PrintMessage(client, "[SM] Car type number is invalid!");
		return;
	}

	// load car type data
	int indexStrings = carType * 3;
	int indexValues = carType * 4;

	globalDataTrucksStrings.GetString(indexStrings, modelCarName, 128);
	globalDataTrucksStrings.GetString(indexStrings+1, modelGlassName, 128);

	modelRotation = globalDataTrucksValues.Get(indexValues);
	globalDataTrucksValues.GetArray(indexValues + 1, distanceYellow);
	globalDataTrucksValues.GetArray(indexValues + 2, distanceRed);
	globalDataTrucksValues.GetArray(indexValues + 3, distanceWhite);

	// model angles
	CopyVector(entityAngles, modelAngles);
	modelAngles[1] += modelRotation;

	// create car model
	// ################################
	carEntity = CreateAlarmCar();
	if (carEntity == -1)
	{
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
	if (glassEntity == -1)
	{
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create car glass entity!");
		return;
	}

	// create alarm timer
	// ################################
	alarmTimer = CreateEntityByName("logic_timer");
	if (alarmTimer == -1)
	{
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
	if (gameEventInfo == -1)
	{
		KillEntity(carEntity);
		KillEntity(alarmTimer);

		PrintMessage(client, "[SM] Could not create game event info entity!");
		return;
	}

	// create sounds
	// ################################
	float soundsPosition[3];
	CopyVector(entityPosition, soundsPosition);
	soundsPosition[2] += 80.0;

	chirpSound = CreateCarSound(soundsPosition, chirpSoundName, carName, "Car.Alarm.Chirp2", "48");
	alarmSound = CreateCarSound(soundsPosition, alarmSoundName, carName, "apc.horn", "16");

	// create lights
	// ################################
	// (Yellow (X,Y,Z), Red, White)
	float distances[9];
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
	char entityName[16];
	bool somethingWrong;

	if (chirpSound == -1 || alarmSound == -1)
	{
		entityName = "sound";
		somethingWrong = true;
	}
	else
	{
		for (int i = 0; i < 6; i++)
		{
			if (carLights[i] == -1)
			{
				entityName = "lights";
				somethingWrong = true;
				break;
			}
		}
	}

	if (somethingWrong)
	{
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

stock void SpawnCustomAlarmCar(const float entityPosition[3], const float entityAngles[3], const int carType, const int client = 0, const char[] carColor = COLOR_REDCAR)
{
	// init
	int carEntity, glassEntity, alarmTimer, chirpSound, alarmSound;
	int carLights[6], glassBlinkLight, glassBlinkTimer, gameEventInfo;
	float modelAngles[3], modelRotation, distanceYellow[3], distanceRed[3], distanceWhite[3], distanceLamp[3];
	char carName[64], glassName[64], alarmTimerName[64];
	char chirpSoundName[64], alarmSoundName[64], carLightsName[64];
	char carHeadLightsName[64], glassBlinkLightName[64], glassBlinkTimerName[64];
	char modelCarName[128], modelGlassName[128], tempString[256];

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
	if (carType < 0 || carType > globalDataCarsCount - 1)
	{
		PrintMessage(client, "[SM] Car type number is invalid!");
		return;
	}

	// load car type data
	int indexStrings = carType * 3;
	int indexValues = carType * 5;

	globalDataCarsStrings.GetString(indexStrings, modelCarName, 128);
	globalDataCarsStrings.GetString(indexStrings + 1, modelGlassName, 128);

	modelRotation = globalDataCarsValues.Get(indexValues);
	globalDataCarsValues.GetArray(indexValues + 1, distanceYellow);
	globalDataCarsValues.GetArray(indexValues + 2, distanceRed);
	globalDataCarsValues.GetArray(indexValues + 3, distanceWhite);
	globalDataCarsValues.GetArray(indexValues + 4, distanceLamp);

	// model angles
	CopyVector(entityAngles, modelAngles);
	modelAngles[1] += modelRotation;

	// create car model
	// ################################
	carEntity = CreateAlarmCar();
	if (carEntity == -1)
	{
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
	if (glassEntity == -1)
	{
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create car glass entity!");
		return;
	}

	// create alarm timer
	// ################################
	alarmTimer = CreateEntityByName("logic_timer");
	if (alarmTimer == -1)
	{
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
	float blinkLightPosition[3];
	CopyVector(entityPosition, blinkLightPosition);
	MoveVectorPosition3D(blinkLightPosition, entityAngles, distanceLamp);

	glassBlinkLight = CreateCarBlinkLight(blinkLightPosition, glassBlinkLightName, carName);
	if (glassBlinkLight == -1)
	{
		KillEntity(carEntity);
		PrintMessage(client, "[SM] Could not create BLINK LIGHT entity!");
		return;
	}

	// create glass blink light timer
	// ################################
	glassBlinkTimer = CreateEntityByName("logic_timer");
	if (glassBlinkTimer == -1)
	{
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
	if (gameEventInfo == -1)
	{
		KillEntity(carEntity);
		KillEntity(alarmTimer);
		KillEntity(glassBlinkTimer);
		PrintMessage(client, "[SM] Could not create game event info entity!");
		return;
	}

	// create sounds
	// ################################
	float soundsPosition[3];
	CopyVector(entityPosition, soundsPosition);
	soundsPosition[2] += 80.0;

	chirpSound = CreateCarSound(soundsPosition, chirpSoundName, carName, "Car.Alarm.Chirp2", "48");
	alarmSound = CreateCarSound(soundsPosition, alarmSoundName, carName, "Car.Alarm", "16");

	// create lights
	// ################################
	// (Yellow (X,Y,Z), Red, White)
	float distances[9];
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
	char entityName[16];
	bool somethingWrong;

	if (chirpSound == -1 || alarmSound == -1)
	{
		entityName = "sound";
		somethingWrong = true;
	}
	else
	{
		for (int i = 0; i < 6; i++)
		{
			if (carLights[i] == -1)
			{
				entityName = "lights";
				somethingWrong = true;
				break;
			}
		}
	}

	if (somethingWrong)
	{
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

Action Timer_CarMove(Handle timer, any carEntity)
{
	if (IsValidEntity(carEntity))
	{
		SetEntityMoveType(carEntity, MOVETYPE_VPHYSICS);
	}
	return Plugin_Stop;
}

stock int CreateAlarmCar()
{
	int carEntity = CreateEntityByName("prop_car_alarm");
	if (carEntity == -1)
	{
		return -1;
	}

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

stock int CreateCarGlass(const char[] modelName, const char[] targetName, const float position[3], const float angle[3], const char[] carName)
{
	int glassEntity = CreateEntityByName("prop_car_glass");
	if (glassEntity == -1)
	{
		return -1;
	}

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

stock int CreateGameEvent(const float position[3])
{
	int gameEventInfo = CreateEntityByName("info_game_event_proxy");
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

stock int CreateCarSound(const float entityPosition[3], const char[] targetName, const char[] sourceName, const char[] messageName, const char[] spawnFlags)
{
	int soundEntity = CreateEntityByName("ambient_generic");
	if (soundEntity == -1)
	{
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

stock void CreateLights(int carLights[6], const float position[3], const float angle[3], const float distance[9], const char[] lightName, const char[] headLightName, const char[] carName)
{
	float lightPosition[3], lightDistance[3];

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

stock int CreateCarBlinkLight(const float entityPosition[3], const char[] targetName, const char[] parentName)
{
	int lightEntity = CreateEntityByName("env_sprite");
	if (lightEntity == -1)
	{
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

stock int CreateCarLight(const float entityPosition[3], const char[] targetName, const char[] parentName, const char[] renderColor)
{
	int lightEntity = CreateEntityByName("env_sprite");
	if (lightEntity == -1)
	{
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

stock int CreateCarHeadLight(const float entityPosition[3], const float entityAngles[3], const char[] targetName, const char[] parentName)
{
	int lightEntity = CreateEntityByName("beam_spotlight");
	if (lightEntity == -1)
	{
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

stock void MoveVectorPosition3D(float position[3], const float constAngles[3], const float constDistance[3])
{
	float angle[3], dirFw[3], dirRi[3], dirUp[3], distance[3];
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
	for (int i = 0; i < 3; i++)
	{
		position[i] += distance[i];
	}
}

stock void MatrixMulti(const float matA[3], const float matB[3], const float matC[3], float vec[3])
{
	float res[3];
	for (int i = 0; i < 3; i++)
	{
		res[0] += matA[i] * vec[i];
		res[1] += matB[i] * vec[i];
		res[2] += matC[i] * vec[i];
	}
	CopyVector(res, vec);
}

stock void CopyVector(const float original[3], float copy[3])
{
	for (int i = 0; i < 3; i++)
	{
		copy[i] = original[i];
	}
}

// ###################################
// PRIVATE MISC FUNCTIONS
// ###################################

stock void InitData()
{
	// reset arrays
	globalDataCarsStrings.Clear();
	globalDataTrucksStrings.Clear();
	globalDataCarsValues.Clear();
	globalDataTrucksValues.Clear();

	// load data into
	KeyValues dataHandle = new KeyValues("alarmcars_models");
	if (!dataHandle.ImportFromFile(CONFIG_MODELS))
	{
		PrintToServer("[SM] models config file not found!");
		return;
	}

	// load cars
	if (dataHandle.JumpToKey("cars"))
	{
		if (dataHandle.JumpToKey("info"))
		{
			globalDataCarsCount = dataHandle.GetNum("count", 0);

			if (globalDataCarsCount > 0)
			{
				dataHandle.GoBack();
				if (dataHandle.JumpToKey("data"))
				{
					dataHandle.GotoFirstSubKey();

					float rot, dis_y[3], dis_r[3], dis_w[3], dis_l[3];
					char modc[128], modg[128], desc[256];

					for (int i = 0; i < globalDataCarsCount; i++)
					{
						// get data
						dataHandle.GetString("model_car", modc, 128);
						dataHandle.GetString("model_glass", modg, 128);
						rot = dataHandle.GetFloat("rotation");
						dataHandle.GetVector("distance_yellow", dis_y);
						dataHandle.GetVector("distance_red", dis_r);
						dataHandle.GetVector("distance_white", dis_w);
						dataHandle.GetVector("distance_lamp", dis_l);
						dataHandle.GetString("description", desc, 256);

						// precache models if neccessary
						if (!IsModelPrecached(modc)) PrecacheModel(modc, true);
						if (!IsModelPrecached(modg)) PrecacheModel(modg, true);

						// save data
						globalDataCarsStrings.PushString(modc);
						globalDataCarsStrings.PushString(modg);
						globalDataCarsStrings.PushString(desc);

						globalDataCarsValues.Push(rot);
						globalDataCarsValues.PushArray(dis_y);
						globalDataCarsValues.PushArray(dis_r);
						globalDataCarsValues.PushArray(dis_w);
						globalDataCarsValues.PushArray(dis_l);

						dataHandle.GotoNextKey();
					}
				}
			}
		}
	}
	else
	{
		PrintToServer("[SM] cars not found!");
	}

	// back to root
	dataHandle.Rewind();

	// load trucks
	if (dataHandle.JumpToKey("trucks"))
	{
		if (dataHandle.JumpToKey("info"))
		{
			globalDataTrucksCount = dataHandle.GetNum("count", 0);

			if (globalDataTrucksCount > 0) {
				dataHandle.GoBack();
				if (dataHandle.JumpToKey("data"))
				{
					dataHandle.GotoFirstSubKey();

					float rot, dis_y[3], dis_r[3], dis_w[3];
					char modc[128], modg[128], desc[256];

					for (int i = 0; i < globalDataTrucksCount; i++)
					{
						// get data
						dataHandle.GetString("model_car", modc, 128);
						dataHandle.GetString("model_glass", modg, 128);
						rot = dataHandle.GetFloat("rotation");
						dataHandle.GetVector("distance_yellow", dis_y);
						dataHandle.GetVector("distance_red", dis_r);
						dataHandle.GetVector("distance_white", dis_w);
						dataHandle.GetString("description", desc, 256);

						// precache models if neccessary
						if (!IsModelPrecached(modc)) PrecacheModel(modc, true);
						if (!IsModelPrecached(modg)) PrecacheModel(modg, true);

						// save data
						globalDataTrucksStrings.PushString(modc);
						globalDataTrucksStrings.PushString(modg);
						globalDataTrucksStrings.PushString(desc);

						globalDataTrucksValues.Push(rot);
						globalDataTrucksValues.PushArray(dis_y);
						globalDataTrucksValues.PushArray(dis_r);
						globalDataTrucksValues.PushArray(dis_w);

						dataHandle.GotoNextKey();
					}
				}
			}
		}
	}
	else
	{
		PrintToServer("[SM] trucks not found!");
	}

	// close keyvalues
	delete dataHandle;

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

stock void InitMap()
{
	#if DEBUG_ENABLED
	DebugOutput("Function: init map");
	#endif

	//if (!globalIsDataInit) return;
	if (globalIsMapInit) return;
	globalIsMapInit = true;

	globalCarNumber = 1;

	if (globalCVarEnable.BoolValue)
	{
		PlaceAlarmCars();
	}
}

stock void PlaceAlarmCars()
{
	#if DEBUG_ENABLED
	DebugOutput("Function: place alarm cars");
	#endif

	KeyValues dataHandle = new KeyValues("alarmcars");

	if (!dataHandle.ImportFromFile(CONFIG_LOCATIONS))
	{
		PrintToServer("[SM] config file not found!");
		return;
	}

	char mapName[64];
	GetCurrentMap(mapName, 64);

	if (!dataHandle.JumpToKey(mapName))
	{
		PrintToServer("[SM] Map not found!");
		delete dataHandle;
		return;
	}

	if (!dataHandle.JumpToKey("info"))
	{
		PrintToServer("[SM] info not found!");
		delete dataHandle;
		return;
	}

	int carCount = dataHandle.GetNum("count", 0);
	int customCount = dataHandle.GetNum("count_custom", 0);
	int truckCount = dataHandle.GetNum("count_truck", 0);

	if ((carCount + customCount + truckCount) < 1)
	{
		PrintToServer("[SM] no cars for this map!");
		delete dataHandle;
		return;
	}

	dataHandle.GoBack();

	float position[3], angle[3];
	char color[32], model[128];
	int type = 0;

	if (carCount > 0 && dataHandle.JumpToKey("data"))
	{
		PrintToServer("[SM] %d cars found!", carCount);
		dataHandle.GotoFirstSubKey();

		for (int i = 0; i < carCount; i++)
		{
			dataHandle.GetVector("position", position);
			dataHandle.GetVector("angle", angle);
			dataHandle.GetString("color", color, 32, COLOR_REDCAR);
			PrintToServer("[SM] spawning %d car at %f %f %f (%f,%f,%f - %s)", i, position[0], position[1], position[2], angle[0], angle[1], angle[2], color);
			SpawnAlarmCar(position, angle, 0, color);
			dataHandle.GotoNextKey();
		}

		dataHandle.GoBack();
		dataHandle.GoBack();
	}

	if (customCount > 0 && dataHandle.JumpToKey("data_custom"))
	{
		PrintToServer("[SM] %d custom cars found!", customCount);
		dataHandle.GotoFirstSubKey();

		for (int i = 0; i < customCount; i++)
		{
			dataHandle.GetString("modelname", model, 128, "");
			dataHandle.GetVector("position", position);
			dataHandle.GetVector("angle", angle);
			dataHandle.GetString("color", color, 32, COLOR_REDCAR);

			type = FindTypeByModelname(model, 0);
			if (type == -1)
			{
				PrintToServer("[SM] could not find type of model %s", model);
				continue;
			}

			PrintToServer("[SM] spawning %d custom car at %f %f %f (%f %f %f - %s [%d] - %s)", i, position[0], position[1], position[2], angle[0], angle[1], angle[2], model, type, color);
			SpawnCustomAlarmCar(position, angle, type, 0, color);
			dataHandle.GotoNextKey();
		}

		dataHandle.GoBack();
		dataHandle.GoBack();
	}

	if (truckCount > 0 && dataHandle.JumpToKey("data_truck"))
	{
		PrintToServer("[SM] %d custom trucks found!", customCount);
		dataHandle.GotoFirstSubKey();

		for (int i = 0; i < truckCount; i++)
		{
			dataHandle.GetString("modelname", model, 128, "");
			dataHandle.GetVector("position", position);
			dataHandle.GetVector("angle", angle);

			type = FindTypeByModelname(model, 1);
			if (type == -1)
			{
				PrintToServer("[SM] could not find type of model %s", model);
				continue;
			}

			PrintToServer("[SM] spawning %d custom truck at %f %f %f (%f %f %f - %s [%d])", i, position[0], position[1], position[2], angle[0], angle[1], angle[2], model, type);
			SpawnCustomAlarmTruck(position, angle, type, 0);
			dataHandle.GotoNextKey();
		}
	}

	delete dataHandle;
}

stock void FindGroupAndTypeByModelname(const char[] modelName, int &group, int &type)
{
	if (StrEqual(ALARMCAR_MODEL, modelName, false))
	{
		group = 2;
		return;
	}

	type = FindTypeByModelname(modelName, 0);
	if (type > -1)
	{
		group = 0;
		return;
	}

	type = FindTypeByModelname(modelName, 1);
	if (type > -1)
	{
		group = 1;
		return;
	}

	group = -1;
	return;
}

stock int FindTypeByModelname(const char[] modelName, const int group)
{
	int index = 0;
	// custom
	if (group == 0)
	{
		index = globalDataCarsStrings.FindString(modelName);
	}
	// truck
	else
	{
		index = globalDataTrucksStrings.FindString(modelName);
	}

	if (index == -1) return -1;
	return (index / 3);
}

stock void SaveAlarmCars(const int client = 0)
{
	int carCount = 0, customCount = 0, truckCount = 0, entity = -1, group, offset, tempColor[3], type;
	float carPositions[16][3], carAngles[16][3], customPositions[16][3], customAngles[16][3], truckPositions[16][3], truckAngles[16][3];
	char carColors[16][16], customColors[16][16], customModel[16][128], truckModel[16][128], targetName[64], tempModel[128];

	// find all alarm cars
	while ((entity = FindEntityByClassname(entity, "prop_car_alarm")) != -1)
	{
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
		if (group == 2)
		{
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
		else if (group == 1)
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", truckPositions[truckCount]);
			GetEntPropVector(entity, Prop_Send, "m_angRotation", truckAngles[truckCount]);

			// get rotation to adjust angle vector
			float rot = globalDataTrucksValues.Get((type * 4));
			truckAngles[truckCount][1] -= rot;

			// copy model
			strcopy(truckModel[truckCount], 128, tempModel);

			truckCount++;
		}
		// custom car
		else
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", customPositions[customCount]);
			GetEntPropVector(entity, Prop_Send, "m_angRotation", customAngles[customCount]);

			// get rotation to adjust angle vector
			float rot = globalDataCarsValues.Get((type*5));
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

	if ((carCount + customCount + truckCount) < 1)
	{
		PrintMessage(client, "[SM] No cars found on the map!");
		return;
	}

	PrintMessage(client, "[SM] Found %d cars on the map.", carCount);
	PrintMessage(client, "[SM] Found %d custom cars on the map.", customCount);
	PrintMessage(client, "[SM] Found %d custom trucks on the map.", truckCount);

	// create keyvalues and load old data
	KeyValues dataHandle = new KeyValues("alarmcars");
	dataHandle.ImportFromFile(CONFIG_LOCATIONS);

	// get map
	char mapName[64];
	GetCurrentMap(mapName, 64);

	// create general structure
	dataHandle.JumpToKey(mapName, true);
	dataHandle.JumpToKey("info", true);
	dataHandle.SetNum("count", carCount);
	dataHandle.SetNum("count_custom", customCount);
	dataHandle.SetNum("count_truck", truckCount);
	dataHandle.GoBack();
	dataHandle.DeleteKey("data");
	dataHandle.DeleteKey("data_custom");
	dataHandle.DeleteKey("data_truck");

	char tempString[8];

	// save cars
	dataHandle.JumpToKey("data", true);
	for (int i = 0; i < carCount; i++)
	{
		Format(tempString, 8, "%d", (i+1));
		dataHandle.JumpToKey(tempString, true);
		dataHandle.SetVector("position", carPositions[i]);
		dataHandle.SetVector("angle", carAngles[i]);
		dataHandle.SetString("color", carColors[i]);
		dataHandle.GoBack();
	}

	dataHandle.GoBack();

	// save custom cars
	dataHandle.JumpToKey("data_custom", true);
	for (int i = 0; i < customCount; i++)
	{
		Format(tempString, 8, "%d", (i+1));
		dataHandle.JumpToKey(tempString, true);
		dataHandle.SetString("modelname", customModel[i]);
		dataHandle.SetVector("position", customPositions[i]);
		dataHandle.SetVector("angle", customAngles[i]);
		dataHandle.SetString("color", customColors[i]);
		dataHandle.GoBack();
	}

	dataHandle.GoBack();

	// save custom trucks
	dataHandle.JumpToKey("data_truck", true);
	for (int i = 0; i < truckCount; i++)
	{
		Format(tempString, 8, "%d", (i+1));
		dataHandle.JumpToKey(tempString, true);
		dataHandle.SetString("modelname", truckModel[i]);
		dataHandle.SetVector("position", truckPositions[i]);
		dataHandle.SetVector("angle", truckAngles[i]);
		dataHandle.GoBack();
	}

	// rewind and save
	dataHandle.Rewind();
	dataHandle.ExportToFile(CONFIG_LOCATIONS);
	delete dataHandle;
	PrintMessage(client, "[SM] Alarmcars successfully saved!");
}

stock void GetClientInFrontLocation(int client, float entityPosition[3], float entityAngles[3] = NULL_VECTOR, float clientDistance = 200.0)
{
	float clientOrigin[3], clientAngles[3], clientDirection[3];
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

stock void PrintMessage(const int client, const char[] text, any ...)
{
	int size = strlen(text) + 255;
	char[] tempText = new char[size];
	VFormat(tempText, size, text, 3);
	if (client == 0) PrintToServer("%s", tempText);
	else PrintToChat(client, "%s", tempText);
}

stock int FindEntityAt(const char[] entityClassname, const float entityPosition[3], const bool checkTargetname = false, const char[] searchString = "", int entity = -1, const float positionRange = 100.0)
{
	float tempPosition[3];
	char targetName[64];
	while ((entity = FindEntityByClassname(entity, entityClassname)) != -1)
	{
		if (entity < 0) entity = EntRefToEntIndex(entity);

		// get position and compare
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", tempPosition);
		if (FloatCompare(GetVectorDistance(tempPosition, entityPosition), positionRange) < 1)
		{
			// extra targetname check on?
			if (checkTargetname)
			{
				GetTargetname(entity, targetName);
				// contains not our string? skip!
				if (StrContains(targetName, searchString, false) == -1) continue;
			}

			return entity;
		}
	}
	return -1;
}

stock void GetTargetname(const int entity, char entityName[64])
{
	if (!IsValidEntity(entity)) return;
	if (!HasEntProp(entity, Prop_Data, "m_iName")) return;
	GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
}

stock void KillEntity(const int entity)
{
	if (entity < 1) return;
	if (!IsValidEntity(entity)) return;
	if (AcceptEntityInput(entity, "Kill")) return;
	RemoveEdict(entity);
}

stock bool FindCarEntitiesAt(const float entityPosition[3], const int client, int &carEntity, int carTimer[2], int &gameEventInfo)
{
	carEntity = FindEntityAt("prop_car_alarm", entityPosition);
	if (carEntity == -1)
	{
		PrintMessage(client, "[SM] no car at %f %f %f found!", entityPosition[0], entityPosition[1], entityPosition[2]);
		return false;
	}

	// get target name, check it and extract carnumber
	char carTargetname[64]/*, tempTargetname[64]*/;
	GetTargetname(carEntity, carTargetname);

	if (StrContains(carTargetname, "sm_alarmcar_", false) == -1) {
		PrintMessage(client, "[SM] the car found was not created by plugin!");
		return false;
	}

	int carNumber = StringToInt(carTargetname[15]);
	PrintMessage(client, "[SM] found plugin car number %d!", carNumber);

	// get real position
	float realPosition[3];
	GetEntPropVector(carEntity, Prop_Send, "m_vecOrigin", realPosition);

	// timer
	carTimer[0] = FindEntityAt("logic_timer", realPosition);
	carTimer[1] = FindEntityAt("logic_timer", realPosition, false, "", carTimer[0]);

	// game event info
	gameEventInfo = FindEntityAt("info_game_event_proxy", realPosition);

	return true;
}

#if DEBUG_ENABLED
stock void DebugOutput(const char[] text, any ...)
{
	int size = strlen(text) + 255;
	char tempText[size];
	VFormat(tempText, size, text, 2);
	LogToFile(DEBUG_LOGFILE, "%s", tempText);
}
#endif