// This is Natalya's edit with a custom car menu, support for
// brake lights and sirens, and fixes for the September update.

// Thanks to rcarm and MAT4DOR for their contributions to the
// stability of the plugin.

// Thanks also to psychonic for help with the use button glitch.

#pragma semicolon 1
#include <sourcemod>
#include <mapchooser>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <rallyrace>
#include <emitsoundany>

#define  RALLYRACE_VERSION			"N-GO 0.51"

public Plugin:myinfo =
{
	name = "CS:GO Rally Race",
	author = "ben -- CS:GO by Natalya",
	description = "CS:GO Rally Race",
	version = RALLYRACE_VERSION,
	url = "http://www.sourcemod.net/"
};

//////////////////////////////////////////////
//					CONFIG					//
//////////////////////////////////////////////
#define 	DEBUG			1					// print debug message for getting entitys

new String:place_name[][3] = {"","st","nd","rd","th"};

//////////////////////////////////////////////
//				END CONFIG					//
//////////////////////////////////////////////

#define 	MAX_CAR							100		// will you make more than 100 cars?
#define		MAXENTITYS						2048
#define  	MODEL_BUGGY	"models/buggy.mdl"
#define		ENTITYS_ARRAY_SIZE				3
#define		ENTITYS_ZONE_TYPE				0
#define		ENTITYS_CHECK_POINT_INDEX		1
#define		ENTITYS_CHECK_POINT_PASSED		2
#define  	CMD_RANDOM		0
#define		NONE			0
#define		READY			1
#define		RACING			2
#define		UNKNOWN			"UNKNOWN"
#define 	CHECKPOINT		0
#define 	POSITION		1

#define 	CHECKPOINT_ENTITY			"trigger_multiple"
#define 	CAR_SPAWN_ENTITY			"info_target"
#define		CHECKPOINT_NAME				"checkpoint_#"
#define		READYZONE_NAME				"ready_zone"
#define		SPECTATE_ZONE_NAME			"spectate_zone"
#define		CAR_SPAWN_NAME				"car_spawn"

#define		VEHICLE_TYPE_AIRBOAT_RAYCAST 8
#define 	EF_NODRAW 32
#define		COLLISION_GROUP_PLAYER 5
#define 	HIDEHUD_WEAPONSELECTION 1
#define 	HIDEHUD_CROSSHAIR 256
#define 	HIDEHUD_INVEHICLE 1024

#define		MAX_CARS	2048
#define		MAX_LIGHTS	12
#define		MAX_SPAWNS	64

// Thanks to Psychonic for this:
#define MAX_BUTTONS 25
new g_LastButtons[MAXPLAYERS+1];

enum TriggerType {
	TT_CHECKPOINT,
	TT_READYPOINT,
	TT_SPECPOINT
};

new racing = 0;
new race_started = 0;

new g_Car_skin_min[MAX_CAR];
new g_Car_skin_max[MAX_CAR];
new car_quantity = 0;
new car_quantity_vip = 0;

new m_vecOrigin;
new m_angRotation;
new m_ArmorValue;
new m_hRagdoll;
new m_hOwnerEntity;

new g_Entitys[ENTITYS_ARRAY_SIZE][MAXENTITYS+1];

new Float:g_Player_JoinReadyTime[MAXPLAYERS+1];
new Float:g_Player_LastCheckPointTime[MAXPLAYERS+1];
new Float:g_Player_RaceTime[MAXPLAYERS+1];

new g_Player_CheckPoint[MAXPLAYERS+1][2];

new g_Max_CheckPoint;
new g_Player_Race_Finish;
new g_Player_Race_Count;
new Handle:g_ACarMenu = INVALID_HANDLE;
new Handle:g_CarMenu = INVALID_HANDLE;
new Handle:kv;
new Handle:g_RaceTimer = INVALID_HANDLE;
new Handle:g_CarSpawnArray = INVALID_HANDLE;
new g_Game_Stats;
new g_Game_CountDown;
new g_Game_Race_Round_Count;

new Handle:spawnkv;
public bool:g_useSpawns2 = true;
new g_SpawnQty = 0;
new Float:g_SpawnLoc[MAX_SPAWNS][3];

new Handle:spawnmodekv;
public bool:InSpawnMode;
new SpawnModeAdmin;
new SMSpawns;
new Float:g_SpawnModeLoc[MAX_SPAWNS][3];

new Handle:g_PlayerTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:h_rallyrace_readytime = INVALID_HANDLE;
new Handle:h_rallyrace_racetime = INVALID_HANDLE;
new Handle:h_rallyrace_raceround = INVALID_HANDLE;
new Handle:h_rallyrace_use = INVALID_HANDLE;

new Handle:F_OnPlayerFinishRace = INVALID_HANDLE;


// CVARs
new Handle:g_Cvar_DelayH = INVALID_HANDLE;

// Player Stuff
// new Float:CurrentEyeAngle[MAXPLAYERS+1][3];
new armour[MAXPLAYERS+1];
public bool:Driving[MAXPLAYERS+1];
new selected_car_type[MAXPLAYERS+1];
new selected_car_skin[MAXPLAYERS+1];
new String:authid[MAXPLAYERS+1][35];
new spawned_car[MAXPLAYERS+1];
new cars_spawned[MAXPLAYERS+1];
new player_ready[MAXPLAYERS+1];
new players_racing = 0;

// Car Customization Stuff
new car_vip[MAX_CARS];
new String:car_name[MAX_CARS][32];
new String:car_model[MAX_CARS][256];
new String:car_script[MAX_CARS][256];
new car_lights[MAX_CARS];
new car_police_lights[MAX_CARS];
new car_view_enabled[MAX_CARS];
new car_siren_enabled[MAX_CARS];
new car_driver_view[MAX_CARS];

// A Particular Car's Stuff
new cars_type[MAX_CARS];
new g_CarIndex[4096];
new g_CarLightQuantity[MAX_CARS];
new g_CarLights[MAX_CARS][MAX_LIGHTS];
new g_CarQty = -1;
new g_SpawnedCars[MAXPLAYERS+1];
new buttons2;
new ViewEnt[2048];
new car_owner[MAX_CARS];
new String:cars_t_name[MAX_CARS][64];
new g_VehicleFlippedTickCount[MAX_CARS] = 0;
new Cars_Driver_Prop[MAX_CARS];

// Siren and Horn and View
public bool:CarSiren[MAX_CARS+1];
public bool:CarView[MAX_CARS+1];
public bool:CarOn[MAX_CARS+1];
public bool:CarHorn[MAXPLAYERS+1];
new Handle:h_siren_a = INVALID_HANDLE;
new Handle:h_siren_b = INVALID_HANDLE;
new Handle:h_siren_c = INVALID_HANDLE;
new Handle:h_horn = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.car_menu");

	m_vecOrigin = FindSendPropInfo("CBaseEntity", "m_vecOrigin");
	m_angRotation = FindSendPropInfo("CBaseEntity", "m_angRotation");
	m_ArmorValue = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
	m_hRagdoll = FindSendPropInfo("CCSPlayer", "m_hRagdoll");
	m_hOwnerEntity = FindSendPropOffs("CBaseEntity","m_hOwnerEntity");
	
	RegConsoleCmd("sm_siren", Car_Siren, " -- Toggle a police cruiser's siren.");
	RegConsoleCmd("sm_car", Car_Command, " -- Open the Car Menu");
	RegConsoleCmd("sm_car_menu", Car_Command, " -- Open the Car Menu");
	
	RegAdminCmd("sm_car_exit", Car_Exit, ADMFLAG_CUSTOM3, "Admin Only");	
	RegConsoleCmd("sm_car_on", Car_On, "Start a Car");
	RegAdminCmd("sm_car_off", Car_Off, ADMFLAG_CUSTOM3, "Admin Only");
	RegAdminCmd("sm_car_lock", Car_Lock, ADMFLAG_CUSTOM3, "Admin Only");
	RegAdminCmd("race_spawn_mode", CommandSpawnMode, ADMFLAG_CUSTOM3, "Set up custom spawn points.");
	RegAdminCmd("race_spawn_reload", CommandSpawnReload, ADMFLAG_CUSTOM3, "Reload custom spawns.");
	
	CreateConVar("rallyrace_version_csgo",RALLYRACE_VERSION,"Rally Race Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_DelayH = CreateConVar("car_horn_delay", "1.0", "Delay between horn honks.", FCVAR_PLUGIN, true, 0.1);
	h_rallyrace_readytime = CreateConVar("rallyrace_readytime","20","Ready Time",0,true,5.0,true,120.0);
	h_rallyrace_racetime= CreateConVar("rallyrace_racetime","320","Racers will force suicide to end current race round after this value (0 = disable)",0,true,0.0);
	h_rallyrace_raceround = CreateConVar("rallyrace_raceround","6","How many race round start a map vote? (0 = Disable)",0,true,0.0);
	h_rallyrace_use = CreateConVar("rallyrace_use","1","Allow players to press 'e' to exit the car? (0 = Disable)",0,true,0.0);

	HookEntityOutput("trigger_multiple","OnStartTouch",OnStartTouch);
	HookEntityOutput("trigger_multiple","OnEndTouch",OnEndTouch);
	HookEvent("player_death",Ev_player_death);
	HookEvent("player_spawn",Ev_player_spawn);
	HookEvent("player_team",Ev_player_team,EventHookMode_Pre);

	// Hook Events
	HookEvent("player_spawn", Event_PlayerSpawnPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);

	g_CarSpawnArray = CreateArray();
	
	F_OnPlayerFinishRace = CreateGlobalForward("OnPlayerFinishRace",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Float);

	AutoExecConfig(true, "rallyrace");
	
	// Load Players Already In Game
	for (new client = 1; client <= MaxClients; client++) 
	{ 
      	if (IsClientInGame(client)) 
      	{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			GetClientAuthString(client, authid[client], sizeof(authid[]));
			Driving[client] = false;
			if ((IsPlayerAlive(client)) && (GetClientTeam(client) == 3))
			{
				FakeClientCommand(client, "kill");
				CS_SwitchTeam(client, 2);
			}
		}
	}

	new Handle:cvar = FindConVar("sv_cheats");
	new flags = GetConVarFlags(cvar) ;
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(cvar, flags);

	// Car File
	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath),"configs/rallyrace/carconfig.txt");
	if(!FileExists(sPath))
	{
		PrintToServer("[RR DEBUG] Error -- There is no carconfig.txt!!");
	}
	kv = CreateKeyValues("RallyRaceCar");
	FileToKeyValues(kv, sPath);
	KvRewind(kv);
	
	// Spawn File
	ReadSpawnFile(0);
	
	// Spawn Mode
	SpawnModeAdmin = -1;
	InSpawnMode = false;

	// Thanks to Mitchell for +lookatweapon listener
	AddCommandListener(Cmd_LookAtWeapon, "+lookatweapon");

	HookConVarChange(h_rallyrace_use, convarchangecallback);
}
public convarchangecallback(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new value = (StringToInt(newValue));
	SetConVarInt(h_rallyrace_use, value, false, true);
	return;
}

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	RegPluginLibrary("rallyrace");
	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
    return APLRes_Success;
	#else
	    return true;
	#endif
}

public OnPluginEnd()
{
	UnhookEntityOutput("trigger_multiple","OnStartTouch",OnStartTouch);
	UnhookEntityOutput("trigger_multiple","OnEndTouch",OnEndTouch);

	ClearArray(g_CarSpawnArray);
	CloseHandle(F_OnPlayerFinishRace);
}

public OnClientPutInServer(client)
{
	g_Player_JoinReadyTime[client] = 0.0;
	g_Player_LastCheckPointTime[client] = 0.0;
	g_Player_CheckPoint[client][CHECKPOINT] = 0;
	g_Player_CheckPoint[client][POSITION] = 0;
	g_Player_RaceTime[client] = 0.0;
	KillPlayerTimer(client);
	spawned_car[client] = -1;
	cars_spawned[client] = 0;
	player_ready[client] = 0;
}
public OnClientPostAdminCheck(client)
{
	CreateTimer(10.0,MenuTime,client);
	selected_car_type[client] = 0;
	selected_car_skin[client] = 0;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	PrintToChat(client, "\x03[RR] ******** Welcome to Rally Race ********");
	PrintToChat(client, "\x03[RR] Plugin converted to CS:GO by Natalya");
	PrintToChat(client, "\x03[RR] Type snd_updateaudiocache in console to hear the cars");
}
public OnClientDisconnect(client)
{
	RemovePlayerCar(client);
	g_Player_JoinReadyTime[client] = 0.0;
	g_Player_LastCheckPointTime[client] = 0.0;
	g_Player_CheckPoint[client][CHECKPOINT] = 0;
	g_Player_CheckPoint[client][POSITION] = 0;
	g_Player_RaceTime[client] = 0.0;
	KillPlayerTimer(client);

	new car = spawned_car[client];
	if ((car > 0) && IsValidEntity(car))
	{
		new driver = GetEntPropEnt(car, Prop_Send, "m_hPlayer");
		if (driver != -1)
		{
			LeaveVehicle(driver);
		}
		
		CarOn[car] = false;
		cars_t_name[car] = "FUCKYOU";
		AcceptEntityInput(car,"KillHierarchy");
		SDKUnhook(car, SDKHook_Think, OnThink);
		RemoveEdict(car);
	}
	spawned_car[client] = -1;
	cars_spawned[client] = 0;
	player_ready[client] = 0;
	g_LastButtons[client] = 0;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	
	if (SpawnModeAdmin == client)
	{
		InSpawnMode = false;
		SpawnModeAdmin = -1;
		CloseHandle(spawnmodekv);
		// May need to reset Spawn Mode stuff here?
	}
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (victim != 0)
    {
		new car = GetEntPropEnt(victim, Prop_Send, "m_hVehicle");
		if (car != -1)
		{
			new plyr_hp = GetClientHealth(victim);
			new damage2 = RoundToCeil(damage);
			plyr_hp -= damage2;
			
			if (plyr_hp <= 0)
			{
				SetEntityHealth(victim, 1);
				damage = 0.0;
				
				if(CarView[victim] == true)
				{
					new String:car_ent_name[128];
					GetTargetName(car, car_ent_name, sizeof(car_ent_name));
					
					SetVariantString(car_ent_name);
					AcceptEntityInput(victim, "SetParent");
					CarView[victim] = false;
					SetVariantString("vehicle_driver_eyes");
					AcceptEntityInput(victim, "SetParentAttachment");
				}
				LeaveVehicle(victim);
				FakeClientCommand(victim, "kill");
				if (damagetype & DMG_VEHICLE)
				{
					new String:ClassName[30];
					GetEdictClassname(inflictor, ClassName, sizeof(ClassName));
					if (StrEqual("prop_vehicle_driveable", ClassName, false))
					{
						new Driver = GetEntPropEnt(inflictor, Prop_Send, "m_hPlayer");
						if (Driver != -1)
						{	
							if (victim != Driver)
							{	
								attacker = Driver;
								return Plugin_Changed;
							}
							return Plugin_Changed;
						}
					}
				}
			}
			else
			{
				SetEntityHealth(victim, plyr_hp);
			}			
			return Plugin_Changed;			
		}
	}
	return Plugin_Changed;
}
public OnMapStart()
{
	g_Game_Race_Round_Count = 0;
	

	ReadDownloadFile();

	ClearArray(g_CarSpawnArray);

	car_quantity = 0;
	if(!ReadCarConfig())
	{
		PrintToServer("[*] Unable To Load Car Config!");
		return;
	}

	g_CarQty = -1;
	g_ACarMenu = BuildVIPCarMenu();
	g_CarMenu = BuildCarMenu();	
	
	InitEntityArray();
	LoadPointEntitys();
	CheckEnoughPlayer();
	players_racing = 0;
	
	// Spawn File
	ReadSpawnFile(0);
}
public OnConfigsExecuted()
{
	PrecacheSoundAny("vehicles/mustang_horn.mp3", true);
	AddFileToDownloadsTable("sound/vehicles/mustang_horn.mp3");
	PrecacheSoundAny("vehicles/police_siren_single.mp3", true);
	AddFileToDownloadsTable("sound/vehicles/police_siren_single.mp3");
	PrecacheSoundAny("natalya/doors/latchunlocked1.mp3", true);
	AddFileToDownloadsTable("sound/natalya/doors/latchunlocked1.mp3");
	PrecacheSoundAny("natalya/doors/default_locked.mp3", true);
	AddFileToDownloadsTable("sound/natalya/doors/default_locked.mp3");
	PrecacheSoundAny("natalya/buttons/lightswitch2.mp3", true);
	AddFileToDownloadsTable("sound/natalya/buttons/lightswitch2.mp3");
}
public OnMapEnd()
{
	if (h_siren_a != INVALID_HANDLE)
	{
		h_siren_a = INVALID_HANDLE;
	}
	if (h_siren_b != INVALID_HANDLE)
	{
		h_siren_b = INVALID_HANDLE;
	}
	if (h_siren_c != INVALID_HANDLE)
	{
		h_siren_c = INVALID_HANDLE;
	}
	if (h_horn != INVALID_HANDLE)
	{
		h_horn = INVALID_HANDLE;
	}
}


// ########
// CAR MENU
// ########


Handle:BuildCarMenu()
{
	if (car_quantity == 0)
	{
		PrintToServer("[Rally] No Cars were detected.");
		return g_CarMenu;
	}
	
	/* Create the menu Handle */
	new Handle:car = CreateMenu(Menu_Car);

	new String:LOLFUCK[4];
	Format(LOLFUCK, sizeof(LOLFUCK), "0");
	AddMenuItem(car,LOLFUCK,"Random");
	
	decl String:cat_str[30];
	for (new i = 1; i < car_quantity; i++)
	{
		if (car_vip[i] == 0)
		{
			Format(cat_str, sizeof(cat_str), "%i", i);
			AddMenuItem(car,cat_str,car_name[i]);
		}
		else if (car_vip[i] == 1)
		{
			Format(cat_str, sizeof(cat_str), "%i", i);
			AddMenuItem(car,cat_str,car_name[i], ITEMDRAW_DISABLED);
		}		
	}
	SetMenuTitle(car, "Choose a Car");
	return car;
}
Handle:BuildVIPCarMenu()
{
	if (car_quantity_vip == 0)
	{
		PrintToServer("[Rally] No VIP Cars were detected.");
	}
	
	/* Create the menu Handle */
	new Handle:car = CreateMenu(Menu_Car);

	new String:LOLFUCK[4];
	Format(LOLFUCK, sizeof(LOLFUCK), "0");
	AddMenuItem(car,LOLFUCK,"Random");	
	
	decl String:cat_str[30];
	for (new i = 1; i < car_quantity; i++)
	{
		Format(cat_str, sizeof(cat_str), "%i", i);
		AddMenuItem(car,cat_str,car_name[i]);
	}
	SetMenuTitle(car, "Choose a Car");
	return car;
}
public Menu_Car(Handle:car, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(car, param2, info, sizeof(info));

		new t = StringToInt(info);
		selected_car_type[param1] = param2;

		if (StrEqual("Random", car_name[param2], false))
		{
			PrintToChat(param1, "\x03[RR] You chose a random car.  You can use !car to change your car again.");
		}
		else
		{
			PrintToChat(param1, "\x03[RR] You chose the %s.  You can use !car to change your car again.", car_name[param2]);
		}
		KvRewind(kv);
		if (t > 0)  // Random car means random skin
		{
			KvJumpToKey(kv, info, false);
	
			new skins = g_Car_skin_max[t];
			skins += 1;
			decl String:skin_str[32], String:skin_num[4], String:colour[32];

			new Handle:skin_menu = CreateMenu(Menu_CarSkin);

			for ( new i = 0;  i < skins; i++ )
			{
				Format(skin_num, sizeof(skin_num), "%i", i);
				KvGetString(kv, skin_num, colour, sizeof(colour), UNKNOWN);
				Format(skin_str, sizeof(skin_str), "%s", colour);
				AddMenuItem(skin_menu, skin_num, skin_str);
			}

			SetMenuTitle(skin_menu, "Choose a Colour:");
			KvRewind(kv);
			DisplayMenu(skin_menu, param1, 0);
		}
		return;
	}
	return;
}
public Menu_CarSkin(Handle:skin_menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{		
		selected_car_skin[param1] = param2;
		new t = selected_car_type[param1];
			
		decl String:skin_num[4], String:car_num[4], String:colour[32];
		Format(car_num, sizeof(car_num), "%i", t);
		Format(skin_num, sizeof(skin_num), "%i", selected_car_skin[param1]);
		
		KvJumpToKey(kv, car_num, false);
		KvGetString(kv, skin_num, colour, sizeof(colour), "UNKNOWN");
		KvRewind(kv);

		PrintToChat(param1, "\x04[RR] Your %s will be %s.", car_name[t], colour);
	}
}





public Action:Ev_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new team = GetEventInt(event,"team");
	if(!client || !IsClientInGame(client) || team <  2)
		return Plugin_Continue;
	if(!IsPlayerAlive(client))
	{
		RespawnClient(1.0,client);
	}
	return Plugin_Handled;
}

public Ev_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(!IsClientInGame(client) || GetClientTeam(client) < 2)
		return;

	new weaponIndex;
	for(new i=0;i<=1;i++)
	{
		weaponIndex = GetPlayerWeaponSlot(client,i);
		if(weaponIndex != -1)
		{
			RemovePlayerItem(client, weaponIndex);
			RemoveEdict(weaponIndex);
		}
	}
	weaponIndex = GetPlayerWeaponSlot(client,2);
	if(weaponIndex != -1)
	{
		EquipPlayerWeapon(client,weaponIndex);
	}
	g_Player_JoinReadyTime[client] = 0.0;
	SetEntData(client,m_ArmorValue,0,4,true);
	player_ready[client] = 0;

	RemoveIdleWeapon();
	
	// If there is a custom spawn config, teleport them to a spawn.
	if (g_useSpawns2 == true)
	{
		new spawn_here = GetRandomInt(0, g_SpawnQty);
		TeleportEntity(client, g_SpawnLoc[spawn_here], NULL_VECTOR, NULL_VECTOR);
	}
	CreateTimer(4.0,MenuTime,client);
}

public Ev_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	Disintegrate(client);
	RemovePlayerCar(client);
	LeaveVehicle(client);
	SetClientViewEntity(client, client);
	CarHorn[client] = false;
	
	if(g_Player_RaceTime[client] != 0.0 && GetClientTeam(client) == 3)
	{
		CS_SwitchTeam(client,2);
		g_Player_JoinReadyTime[client] = 0.0;
	}
	RespawnClient(0.5,client);
	return;
}
	
public Action:RaceTimerFunc(Handle:timer)
{
	switch(g_Game_Stats)
	{
		case NONE: // check enough player to start run reday time
		{
			new maxClients = GetMaxClients();
			new total = 0;
			for (new i=1; i<=maxClients; i++)
				if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2)
					total++;

			if(total >= 1) // enough player! go to ready time count down
			{
				g_Game_CountDown = GetConVarInt(h_rallyrace_readytime);
				g_Game_Stats = READY;
			} else {
				// PrintCenterTextAll("Not enough player to start, at least 1 players!");
				// EndMessage();
			}
		}
		case READY:
		{
			// PrintCenterTextAll("%ds Race Start\n      \"GO!\"",g_Game_CountDown);
			if ((g_Game_CountDown == 30) || (g_Game_CountDown == 25) || (g_Game_CountDown == 20) || (g_Game_CountDown == 15) || (g_Game_CountDown == 10) || (g_Game_CountDown == 5))
			{
				PrintToChatAll(" \x04[RR] Next Race in: %d", g_Game_CountDown);
			}
			g_Game_CountDown -= 1;
			if(g_Game_CountDown >= 0) // counting down...
				return Plugin_Continue;
			if (g_Game_CountDown == -1)
			{
				new maxClients = GetMaxClients();
				new total = 0;
				new clients[maxClients];
				for (new i=1; i<=maxClients; i++)
				{
					if (IsClientConnected(i) && IsClientInGame(i))
					{
						g_Player_CheckPoint[i][CHECKPOINT] = 0;
						g_Player_CheckPoint[i][POSITION] = 0;
						g_Player_RaceTime[i] = 0.0;
						SetEntProp(i, Prop_Data, "m_iDeaths", 0);
						if(GetClientTeam(i) == 2 && g_Player_JoinReadyTime[i] != 0.0)
						clients[total++] = i;
					}
				}
				if(total == 0) // no one in ready zone, check enough player again
				{
					PrintToChatAll("\x04 [RR] Nobody Ready -- Waiting Again");
					g_Game_Stats = NONE;
					return Plugin_Continue;
				}
				g_Player_Race_Finish = 0;
				g_Player_Race_Count = 0;
				// PrintCenterTextAll("");
				g_Game_Stats = RACING;
				g_Game_CountDown = GetConVarInt(h_rallyrace_racetime) + 4;
				ResetCheckPointsPass();
				SpawnCarsToRace(clients,total);
				new use2 = 0;
				use2 = GetConVarInt(h_rallyrace_use);
				if (use2 != 1)
				{
					PrintToChatAll("\x04 [Rally] Pressing 'e' or use to exit a car has been disabled for this race.");
				}
			}
		}
		case RACING:
		{
			g_Game_CountDown--;
			new racetime = GetConVarInt(h_rallyrace_racetime);
			if(g_Game_CountDown >= racetime)
			{
				if(g_Game_CountDown == (racetime + 3))
					ShowOverlays("r_screenoverlay zx2_car/3");
				else if(g_Game_CountDown == (racetime + 2))
					ShowOverlays("r_screenoverlay zx2_car/2");
				else if(g_Game_CountDown == (racetime + 1))
					ShowOverlays("r_screenoverlay zx2_car/1");
				else if(g_Game_CountDown == racetime) {
					ShowOverlays("r_screenoverlay zx2_car/go");
					StartAllPLayerVehicleEngine();
					racing = 1;
					CreateTimer(0.5,KillOverlays);
				}
			} else {
				new maxClients = GetMaxClients();
				new total = 0;
				for (new i=1; i<=maxClients; i++)
					if (IsClientConnected(i) && IsClientInGame(i) && g_Player_JoinReadyTime[i] == 0.0 &&  g_Player_RaceTime[i] != 0.0 && GetClientTeam(i) == 3) // player join race
						total++;

				if( (g_Game_CountDown <= 0 && GetConVarInt(h_rallyrace_racetime) > 0)|| total == 0) // all racers finish or no racers or timeout
				{
					racing = 0;
					race_started = 0;
					if(g_Game_CountDown <= 0 && GetConVarInt(h_rallyrace_racetime) > 0)
					{
						PrintToChatAll("\x04[-]\x03 Timeout!");
						KillAllRacePlayer();
					}
					g_Game_Race_Round_Count++;
					new raceround = GetConVarInt(h_rallyrace_raceround);
					if(raceround > 0 && g_Game_Race_Round_Count >= raceround) // played x rounds, time to change map, if use CleanUp() call, no need??
					{
						InitiateMapChooserVote(MapChange_Instant);
						g_RaceTimer = INVALID_HANDLE;
						return Plugin_Stop;
					}
					CleanUpRound();
					g_Game_CountDown = GetConVarInt(h_rallyrace_readytime);
					g_Game_Stats = READY;
				}
			}
		}
	}
	return Plugin_Continue;
}

public CheckEnoughPlayer()
{
	g_Game_Stats = NONE;
	if(g_RaceTimer != INVALID_HANDLE)
	{
		KillTimer(g_RaceTimer);
		g_RaceTimer = INVALID_HANDLE;
	}
	g_RaceTimer = CreateTimer(1.0,RaceTimerFunc,INVALID_HANDLE,TIMER_REPEAT);
}

public OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	if(g_Entitys[ENTITYS_ZONE_TYPE][caller] == -1)
		return;
	if(!IsPlayer(activator))
		return;
	if(!IsClientInGame(activator))
		return;

	switch(g_Entitys[ENTITYS_ZONE_TYPE][caller])
	{
		case TT_CHECKPOINT: // touching checkpoint
		{
			if(g_Entitys[ENTITYS_CHECK_POINT_INDEX][caller] ==  -1)
				return;

			new car = GetEntPropEnt(activator, Prop_Send, "m_hVehicle");
			if(car == -1) // player not in car, on foot?
				return;

			if((g_Entitys[ENTITYS_CHECK_POINT_INDEX][caller] - g_Player_CheckPoint[activator][CHECKPOINT]) != 1)
				return;
			if(g_Player_CheckPoint[activator][CHECKPOINT] >= g_Max_CheckPoint) { // finish last checkpoint
				PlayerFinishRace(car,activator);
			}else {
				g_Entitys[ENTITYS_CHECK_POINT_PASSED][caller]++;
				g_Player_LastCheckPointTime[activator] = GetGameTime();
				g_Player_CheckPoint[activator][CHECKPOINT]++;
				g_Player_CheckPoint[activator][POSITION] = g_Entitys[ENTITYS_CHECK_POINT_PASSED][caller];
				UpdatAllPLayersPosition(); // update all player place
			}
		}/*
		case TT_SPECPOINT: // player touching gman
		{
			ChangeClientTeam(activator,1);
		} */
		case TT_READYPOINT: // player ready to race
		{
			g_Player_JoinReadyTime[activator] = GetGameTime();
			player_ready[activator] = 1;
		}
	}
}

public OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	if(g_Entitys[ENTITYS_ZONE_TYPE][caller] == -1)
		return;
	if(!IsPlayer(activator))
		return;
	if(!IsClientInGame(activator))
		return;

	if(g_Entitys[ENTITYS_ZONE_TYPE][caller] == _:TT_READYPOINT) // player leave ready zone (may be going to find gman)
	{
		g_Player_JoinReadyTime[activator] = 0.0;
		player_ready[activator] = 0;
	}
}

public PlayerFinishRace(car,client)
{
	new String:playername[32];
	GetClientName(client, playername, sizeof(playername));
	new Float:finish_time = GetGameTime() - g_Player_RaceTime[client] - 0.005;
	new minutes = RoundToZero(finish_time/60);
	new Float:seconds = finish_time  - (minutes * 60);
	g_Player_Race_Finish++;
	
	RemovePlayerCar(client);
	LeaveVehicle(client);
	CS_SwitchTeam(client,2);
	CS_RespawnPlayer(client);
	cars_t_name[car] = "FUCKYOU";
	new index = (g_Player_Race_Finish >= 4) ? 4 : g_Player_Race_Finish;
	if(seconds < 10.0) // time = 3:02
	{
		PrintToChatAll("\x04[RR]\x03 %d%s: %s\x01 %d:0%.2f",g_Player_Race_Finish,place_name[index],playername,minutes,seconds);
		PrintToServer("[RR] %d%s: %s %d:0%.2f",g_Player_Race_Finish,place_name[index],playername,minutes,seconds);
	}
	else
	{
		// time = 3:12
		PrintToChatAll("\x04[RR]\x03 %d%s: %s\x01 %d:%.2f",g_Player_Race_Finish,place_name[index],playername,minutes,seconds);
		PrintToServer("[RR] %d%s: %s %d:%.2f",g_Player_Race_Finish,place_name[index],playername,minutes,seconds);
	}
	players_racing -= 1;

	CallOnPlayerFinishRace(client, true, minutes, seconds);
	SetEntityHealth(client, 100);
}
stock ShowPlayerText(client)
{
	if(IsPlayerAlive(client))
	{
		PrintHintText(client,"CheckPoints\n %d/%d\nPosition\n %d/%d",g_Player_CheckPoint[client][CHECKPOINT],g_Max_CheckPoint+1,g_Player_CheckPoint[client][POSITION],g_Player_Race_Count);
	}
}
public Action:MenuTime(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		new AdminId:admin = GetUserAdmin(client);
		if (admin != INVALID_ADMIN_ID)
		{
			DisplayMenu(g_ACarMenu, client, 0);
		}
		else
		{
			DisplayMenu(g_CarMenu, client, 0);
		}
	}
}

public SortPosition(array1[], array2[], const array[][], Handle:hndl)
{
	if(array1[CHECKPOINT] == array2[CHECKPOINT]) return array1[POSITION] - array2[POSITION];
	return array2[CHECKPOINT] - array1[CHECKPOINT];
}

public UpdatAllPLayersPosition()
{
	new SortArray[MAXPLAYERS+1][3];
	new maxClients = GetMaxClients();
	new total = 0;
	for (new i=1; i<=maxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && g_Player_RaceTime[i] != 0.0)
		{
			SortArray[total][CHECKPOINT] = g_Player_CheckPoint[i][CHECKPOINT];
			SortArray[total][POSITION] = g_Player_CheckPoint[i][POSITION];
			SortArray[total][2] = i;
			total++;
		}
	}
	if(total > 0)
	{
		SortCustom2D(SortArray,total,SortPosition);
		for(new i=0;i< total;i++)
		{
			new client = SortArray[i][2];
			g_Player_CheckPoint[client][POSITION] = i+1;
			if(GetClientTeam(client) == 3)
			{
				ShowPlayerText(client);
			}
		}
	}
}

public KillAllRacePlayer()
{
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			RemovePlayerCar(i);
			LeaveVehicle(i);
			ForcePlayerSuicide(i);
		}
	}
}

public StartAllPLayerVehicleEngine()
{
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && g_Player_RaceTime[i] != 0.0 && GetClientTeam(i) == 3)
		{
			new car = GetEntPropEnt(i, Prop_Send, "m_hVehicle");
			if(car != -1)
			{
				AcceptEntityInput(car, "TurnOn");
				ActivateEntity(car);
				AcceptEntityInput(car, "TurnOn");
				CarOn[car] = true;
			}
		}
	}
	racing = 1;
	race_started = 1;
}

public RemovePlayerCar(client)
{
	if(IsClientInGame(client))
	{
		new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		if(car != -1)
		{
			new owner = car_owner[car];
			cars_spawned[owner] = 0;
			spawned_car[owner] = -1;
			car_owner[car] = -1;
			LeaveVehicle(client);
			AcceptEntityInput(car,"KillHierarchy");
			cars_t_name[car] = "FUCKYOU";
			SDKUnhook(car, SDKHook_Think, OnThink);
			RemoveEdict(car);
		}
	}
}

public SortJoinReadyTime(array1[], array2[], const array[][], Handle:hndl)
{
	return array2[0] - array1[0];
}

public SpawnCarsToRace(clients[], total)
{
	new size = GetArraySize(g_CarSpawnArray);
	if(size == 0)
		return;
		
	decl maxplayers,i;
	maxplayers = GetMaxClients();
	for(i = 1; i <= maxplayers; i++)
	{
		if (player_ready[i] == 1)
		{
			new ent = GetArrayCell(g_CarSpawnArray,i);
			new Float:vec[3],Float:ang[3];
			GetEntDataVector(ent,m_vecOrigin,vec);
			GetEntDataVector(ent,m_angRotation,ang);
			players_racing += 1;
			GetClientAuthString(i, authid[i], sizeof(authid[]));
			new car = CreateJeep(i, vec, ang);
			if(IsValidEntity(car))
			{
//				TeleportEntity(i, vec, NULL_VECTOR, NULL_VECTOR);
				TeleportEntity(car, vec, ang, NULL_VECTOR);
				AcceptEntityInput(car, "use", i);
				SetPlayerToVehicle(i, car);
				FakeClientCommandEx(i, "+use");
				CS_SwitchTeam(i,3);
				g_Player_RaceTime[i] = GetGameTime();
				g_Player_Race_Count++;
				CarOn[car] = false;
			}
		}
	}
}

stock bool:IsPlayer(client)
{
	return (client > 0 && client <= MAXPLAYERS);
}

public ResetCheckPointsPass()
{
	for(new i=0;i<=MAXENTITYS;i++)
	{
		g_Entitys[ENTITYS_CHECK_POINT_PASSED][i] = 0;
	}
}

public InitEntityArray()
{
	for(new j=0;j<ENTITYS_ARRAY_SIZE;j++)
	{
		for(new i=0;i<=MAXENTITYS;i++)
		{
			g_Entitys[j][i] = -1;
		}
	}
}

public LoadPointEntitys()
{
	g_Max_CheckPoint = 0;
	new String:classname[64];
	new String:targetname[64];
	new maxents = GetMaxEntities();
	for(new i=1;i<=maxents;i++)
	{
		if(!IsValidEntity(i))
			continue;

		GetEdictClassname(i,classname,sizeof(classname));
		if(StrEqual(classname,CHECKPOINT_ENTITY))
		{
			GetTargetName(i,targetname,sizeof(targetname));
			if(StrEqual(targetname,READYZONE_NAME,false)) // ready zone
			{
				g_Entitys[ENTITYS_ZONE_TYPE][i] = _:TT_READYPOINT;

				#if DEBUG == 1
				PrintToServer("Found Ready Zone");
				#endif
			} else if(StrEqual(targetname,SPECTATE_ZONE_NAME,false)) { // spectate zone
				g_Entitys[ENTITYS_ZONE_TYPE][i] = _:TT_SPECPOINT;

				#if DEBUG == 1
				PrintToServer("Found Spectate Zone");
				#endif
			} else if(strcmp(targetname,CHECKPOINT_NAME,false) > 1) { // check points
				new index = StringToInt(targetname[12]);
				g_Entitys[ENTITYS_ZONE_TYPE][i] = _:TT_CHECKPOINT;
				g_Entitys[ENTITYS_CHECK_POINT_INDEX][i] = index;
				g_Entitys[ENTITYS_CHECK_POINT_PASSED][i] = 0;
				g_Max_CheckPoint++;
				#if DEBUG == 1
				PrintToServer("Found CheckPoint: %d",index);
				#endif
			}
		} else if(StrEqual(classname,CAR_SPAWN_ENTITY)) {
			GetTargetName(i,targetname,sizeof(targetname));
			if(StrEqual(targetname,CAR_SPAWN_NAME,false)) // car spawn points
			{
				PushArrayCell(g_CarSpawnArray,i);
				#if DEBUG == 1
				new Float:vec[3],Float:ang[3];
				GetEntDataVector(i,m_vecOrigin,vec);
				GetEntDataVector(i,m_angRotation,ang);
				PrintToServer("Found Car Spawn Point: %.1f %.1f %.1f (%.1f %.1f %.1f)",vec[0],vec[1],vec[2],ang[0],ang[1],ang[2]);
				#endif
			}
		}
	}
	g_Max_CheckPoint--;
}

stock GetTargetName(entity, String:buf[], len)
{
	GetEntPropString(entity, Prop_Data, "m_iName", buf, len);
}

stock ShowOverlays(const String:overlay[])
{
	SetConVarBool(FindConVar("sv_cheats"),true,false);
	decl maxplayers,i;
	maxplayers = GetMaxClients();
	for(i=1;i<=maxplayers;i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			ClientCommand(i,overlay);
		}
	}
	SetConVarBool(FindConVar("sv_cheats"),false,false);
}

public Action:KillOverlays(Handle:timer)
{
	SetConVarBool(FindConVar("sv_cheats"),true,false);
	decl maxplayers,i;
	maxplayers = GetMaxClients();
	for(i=1;i<=maxplayers;i++)
		if(IsClientInGame(i))
			ClientCommand(i,"r_screenoverlay \"\"");
	SetConVarBool(FindConVar("sv_cheats"),false,false);
	return Plugin_Stop;
}

public Action:_RespawnClient(Handle:timer, any:client)
{
	if(IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) >= 2 && !IsPlayerAlive(client))
	{
		CS_RespawnPlayer(client);
	}
	return Plugin_Stop;
}

public RespawnClient(Float:seconds, client)
{
	CreateTimer(seconds,_RespawnClient,client,TIMER_FLAG_NO_MAPCHANGE);
}

public CreateJeep(client, Float:vec[3], Float:ang[3])
{
	new t = selected_car_type[client];
	new String:skin[4];
	Format(skin, sizeof(skin), "%i", selected_car_skin[client]);
	new ent  = CreateEntityByName("prop_vehicle_driveable");
	if(IsValidEntity(ent))
	{
		Cars_Driver_Prop[ent] = -1;
		g_VehicleFlippedTickCount[ent] = 0;
		new String:ent_name[16], String:light_index[16];
		Format(ent_name, 16, "%i", ent);
		Format(light_index, 16, "%iLgt", ent);
		new String:Car_Name[64];
		Format(Car_Name, sizeof(Car_Name), "%s_%i", authid[client], g_SpawnedCars[client]);
		AcceptEntityInput(ent, "Unlock", 0);
		if (t == 0)
		{
			t = GetRandomCar();
			
			IntToString(GetRandomInt(g_Car_skin_min[t], g_Car_skin_max[t]), skin,sizeof(skin));
			DispatchKeyValue(ent, "vehiclescript", car_script[t]);
			DispatchKeyValue(ent, "model", car_model[t]);
			DispatchKeyValueFloat (ent, "MaxPitch", 360.00);
			DispatchKeyValueFloat (ent, "MinPitch", -360.00);
			DispatchKeyValueFloat (ent, "MaxYaw", 90.00);
			DispatchKeyValue(ent, "targetname", Car_Name);
			DispatchKeyValue(ent, "solid","6");
			DispatchKeyValue(ent, "skin",skin);
			DispatchKeyValue(ent, "actionScale","1");
			DispatchKeyValue(ent, "EnableGun","0");
			DispatchKeyValue(ent, "ignorenormals","0");
			DispatchKeyValue(ent, "fadescale","1");
			DispatchKeyValue(ent, "fademindist","-1");
			DispatchKeyValue(ent, "VehicleLocked","0");
			DispatchKeyValue(ent, "screenspacefade","0");
			DispatchKeyValue(ent, "spawnflags", "256" );
			DispatchKeyValue(ent, "setbodygroup", "511" );
			SetEntProp(ent, Prop_Send, "m_nSolidType", 2);
			DispatchSpawn(ent);
			ActivateEntity(ent);
		}
		if (t > 0)
		{
			DispatchKeyValue(ent, "vehiclescript", car_script[t]);
			DispatchKeyValue(ent, "model", car_model[t]);
			DispatchKeyValueFloat (ent, "MaxPitch", 360.00);
			DispatchKeyValueFloat (ent, "MinPitch", -360.00);
			DispatchKeyValueFloat (ent, "MaxYaw", 90.00);
			DispatchKeyValue(ent, "targetname", Car_Name);
			DispatchKeyValue(ent, "solid","6");
			DispatchKeyValue(ent, "skin", skin);
			DispatchKeyValue(ent, "actionScale","1");
			DispatchKeyValue(ent, "EnableGun","0");
			DispatchKeyValue(ent, "ignorenormals","0");
			DispatchKeyValue(ent, "fadescale","1");
			DispatchKeyValue(ent, "fademindist","-1");
			DispatchKeyValue(ent, "VehicleLocked","0");
			DispatchKeyValue(ent, "screenspacefade","0");
			DispatchKeyValue(ent, "spawnflags", "256" );
			DispatchKeyValue(ent, "setbodygroup", "511" );
			SetEntProp(ent, Prop_Send, "m_nSolidType", 2);
			DispatchSpawn(ent);
			ActivateEntity(ent);
		}
		Format(cars_t_name[ent], sizeof(cars_t_name[]), "%s", Car_Name);
		spawned_car[client] = ent;
		cars_spawned[client] = 1;
		car_owner[ent] = client;
		TeleportEntity(ent,vec,ang,NULL_VECTOR);
		SetEntProp(ent, Prop_Data, "m_nNextThinkTick", -1);	
		SDKHook(ent, SDKHook_Think, OnThink);		
		ViewEnt[ent] = -1;	
				
		g_CarQty += 1;
		g_CarIndex[ent] = g_CarQty;
		new car_index2 = g_CarIndex[ent];
		g_CarLightQuantity[car_index2] = 0;
				
		cars_type[ent] = t;
		CarOn[ent] = false;


		if ((car_lights[t] == 1) || (car_lights[t] == 2))
		{
			// First declare some angles and colours.
			decl Float:brake_rgb[3], Float:blue_rgb[3], Float:white_rgb[3];
			brake_rgb[0] = 255.0;
			brake_rgb[1] = 0.0;
			brake_rgb[2] = 0.0;

			blue_rgb[0] = 20.0;
			blue_rgb[1] = 20.0;
			blue_rgb[2] = 255.0;
			
			white_rgb[0] = 255.0;
			white_rgb[1] = 255.0;
			white_rgb[2] = 255.0;

			// Then we create the brake lights.  Siren lights will come later if applicable.
	
			new brake_l = CreateEntityByName("env_sprite");


			DispatchKeyValue(brake_l, "parentname", ent_name);
			DispatchKeyValue(brake_l, "targetname", light_index);
			DispatchKeyValueFloat(brake_l, "HDRColorScale", 1.0);
			DispatchKeyValue(brake_l, "renderamt", "155");
			DispatchKeyValueVector(brake_l, "rendercolor", brake_rgb);
			DispatchKeyValue(brake_l, "spawnflags", "0");
			DispatchKeyValue(brake_l, "rendermode", "3");
			DispatchKeyValue(brake_l, "model", "sprites/light_glow02.spr");
			DispatchKeyValueFloat(brake_l, "scale", 0.2);
			DispatchSpawn(brake_l);
			TeleportEntity(brake_l, vec, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(Car_Name);
			AcceptEntityInput(brake_l, "SetParent", brake_l, brake_l, 0);
			SetVariantString("light_rl");
			AcceptEntityInput(brake_l, "SetParentAttachment", brake_l, brake_l, 0);

			g_CarLightQuantity[car_index2] += 1;
			g_CarLights[car_index2][0] = brake_l;


			new brake_r = CreateEntityByName("env_sprite");

			DispatchKeyValue(brake_r, "parentname", ent_name);
			DispatchKeyValue(brake_r, "targetname", light_index);
			DispatchKeyValueFloat(brake_r, "HDRColorScale", 1.0);
			DispatchKeyValue(brake_r, "renderamt", "155");
			DispatchKeyValueVector(brake_r, "rendercolor", brake_rgb);
			DispatchKeyValue(brake_r, "spawnflags", "0");
			DispatchKeyValue(brake_r, "rendermode", "3");
			DispatchKeyValue(brake_r, "model", "sprites/light_glow02.spr");
			DispatchKeyValueFloat(brake_r, "scale", 0.2);
			DispatchSpawn(brake_r);
			TeleportEntity(brake_r, vec, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(Car_Name);
			AcceptEntityInput(brake_r, "SetParent", brake_r, brake_r, 0);
			SetVariantString("light_rr");
			AcceptEntityInput(brake_r, "SetParentAttachment", brake_r, brake_r, 0);

			g_CarLightQuantity[car_index2] += 1;
			g_CarLights[car_index2][1] = brake_r;


			new brake_l2 = CreateEntityByName("env_sprite");

			DispatchKeyValue(brake_l2, "parentname", ent_name);
			DispatchKeyValue(brake_l2, "targetname", light_index);
			DispatchKeyValueFloat(brake_l2, "HDRColorScale", 1.0);
			DispatchKeyValue(brake_l2, "renderamt", "100");
			DispatchKeyValueVector(brake_l2, "rendercolor", brake_rgb);
			DispatchKeyValue(brake_l2, "spawnflags", "0");
			DispatchKeyValue(brake_l2, "rendermode", "3");
			DispatchKeyValue(brake_l2, "model", "sprites/light_glow02.spr");
			DispatchKeyValueFloat(brake_l2, "scale", 0.2);
			DispatchSpawn(brake_l2);
			TeleportEntity(brake_l2, vec, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(Car_Name);
			AcceptEntityInput(brake_l2, "SetParent", brake_l2, brake_l2, 0);
			SetVariantString("light_rl");
			AcceptEntityInput(brake_l2, "SetParentAttachment", brake_l2, brake_l2, 0);

			g_CarLightQuantity[car_index2] += 1;
			g_CarLights[car_index2][2] = brake_l2;


			new brake_r2 = CreateEntityByName("env_sprite");

			DispatchKeyValue(brake_r2, "parentname", ent_name);
			DispatchKeyValue(brake_r2, "targetname", light_index);
			DispatchKeyValueFloat(brake_r2, "HDRColorScale", 1.0);
			DispatchKeyValue(brake_r2, "renderamt", "100");
			DispatchKeyValueVector(brake_r2, "rendercolor", brake_rgb);
			DispatchKeyValue(brake_r2, "spawnflags", "0");
			DispatchKeyValue(brake_r2, "rendermode", "3");
			DispatchKeyValue(brake_r2, "model", "sprites/light_glow02.spr");
			DispatchKeyValueFloat(brake_r2, "scale", 0.2);
			DispatchSpawn(brake_r2);
			TeleportEntity(brake_r2, vec, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(Car_Name);
			AcceptEntityInput(brake_r2, "SetParent", brake_r2, brake_r2, 0);
			SetVariantString("light_rr");
			AcceptEntityInput(brake_r2, "SetParentAttachment", brake_r2, brake_r2, 0);

			g_CarLightQuantity[car_index2] += 1;
			g_CarLights[car_index2][3] = brake_r2;
					
			if (car_police_lights[t] == 1)
			{
				new blue_1 = CreateEntityByName("env_sprite");

				DispatchKeyValue(blue_1, "parentname", ent_name);
				DispatchKeyValue(blue_1, "targetname", light_index);
				DispatchKeyValueFloat(blue_1, "HDRColorScale", 1.0);
				DispatchKeyValue(blue_1, "renderamt", "255");
				DispatchKeyValueVector(blue_1, "rendercolor", blue_rgb);
				DispatchKeyValue(blue_1, "spawnflags", "0");
				DispatchKeyValue(blue_1, "rendermode", "3");
				DispatchKeyValue(blue_1, "model", "sprites/light_glow02.spr");
				DispatchSpawn(blue_1);
				TeleportEntity(blue_1, vec, NULL_VECTOR, NULL_VECTOR);
				SetVariantString(Car_Name);
				AcceptEntityInput(blue_1, "SetParent", blue_1, blue_1, 0);
				SetVariantString("light_bar1");
				AcceptEntityInput(blue_1, "SetParentAttachment", blue_1, blue_1, 0);
				AcceptEntityInput(blue_1, "HideSprite");
						
				g_CarLightQuantity[car_index2] += 1;
				g_CarLights[car_index2][4] = blue_1;

				new blue_2 = CreateEntityByName("env_sprite");

				DispatchKeyValue(blue_2, "parentname", ent_name);
				DispatchKeyValue(blue_2, "targetname", light_index);
				DispatchKeyValueFloat(blue_2, "HDRColorScale", 1.0);
				DispatchKeyValue(blue_2, "renderamt", "255");
				DispatchKeyValueVector(blue_2, "rendercolor", blue_rgb);
				DispatchKeyValue(blue_2, "spawnflags", "0");
				DispatchKeyValue(blue_2, "rendermode", "3");
				DispatchKeyValue(blue_2, "model", "sprites/light_glow02.spr");
				DispatchSpawn(blue_2);
				TeleportEntity(blue_2, vec, NULL_VECTOR, NULL_VECTOR);
				SetVariantString(Car_Name);
				AcceptEntityInput(blue_2, "SetParent", blue_2, blue_2, 0);
				SetVariantString("light_bar2");
				AcceptEntityInput(blue_2, "SetParentAttachment", blue_2, blue_2, 0);
				AcceptEntityInput(blue_2, "HideSprite");
						
				g_CarLightQuantity[car_index2] += 1;
				g_CarLights[car_index2][5] = blue_2;
			}
			if (car_lights[t] == 2)
			{
				new headlight_l = CreateEntityByName("light_dynamic");
				DispatchKeyValue(headlight_l, "parentname", ent_name);
				DispatchKeyValue(headlight_l, "targetname", light_index);
				DispatchKeyValueVector(headlight_l, "rendercolor", white_rgb);
				DispatchKeyValue(headlight_l, "_inner_cone", "60");
				DispatchKeyValue(headlight_l, "_cone", "70");
				DispatchKeyValueFloat(headlight_l, "spotlight_radius", 220.0);
				DispatchKeyValueFloat(headlight_l, "distance", 768.0);
				DispatchKeyValue(headlight_l, "brightness", "2");
				DispatchKeyValue(headlight_l, "_light", "255 255 255 511");
				DispatchKeyValue(headlight_l, "style", "0");
				DispatchKeyValue(headlight_l, "pitch", "-20");
				DispatchKeyValue(headlight_l, "renderamt", "200");
				DispatchSpawn(headlight_l);
				TeleportEntity(headlight_l, vec, ang, NULL_VECTOR);
				SetVariantString(Car_Name);
				AcceptEntityInput(headlight_l, "SetParent", headlight_l, headlight_l, 0);
				SetVariantString("light_fl");
				AcceptEntityInput(headlight_l, "SetParentAttachment", headlight_l, headlight_l, 0);
				AcceptEntityInput(headlight_l, "TurnOff");

				g_CarLights[car_index2][6] = headlight_l;	
					
					
				new headlight_r = CreateEntityByName("light_dynamic");
				DispatchKeyValue(headlight_r, "parentname", ent_name);
				DispatchKeyValue(headlight_r, "targetname", light_index);
				DispatchKeyValueVector(headlight_r, "rendercolor", white_rgb);
				DispatchKeyValue(headlight_r, "_inner_cone", "60");
				DispatchKeyValue(headlight_r, "_cone", "70");
				DispatchKeyValueFloat(headlight_r, "spotlight_radius", 220.0);
				DispatchKeyValueFloat(headlight_r, "distance", 768.0);
				DispatchKeyValue(headlight_r, "brightness", "2");
				DispatchKeyValue(headlight_r, "_light", "255 255 255 511");
				DispatchKeyValue(headlight_r, "style", "0");
				DispatchKeyValue(headlight_r, "pitch", "-20");					
				DispatchKeyValue(headlight_r, "renderamt", "200");
				DispatchSpawn(headlight_r);
				TeleportEntity(headlight_r, vec, ang, NULL_VECTOR);
				SetVariantString(Car_Name);
				AcceptEntityInput(headlight_r, "SetParent", headlight_r, headlight_r, 0);
				SetVariantString("light_fr");
				AcceptEntityInput(headlight_r, "SetParentAttachment", headlight_r, headlight_r, 0);
				AcceptEntityInput(headlight_r, "TurnOff");
					
				g_CarLights[car_index2][7] = headlight_r;



				new headlight_l2 = CreateEntityByName("env_sprite");

				DispatchKeyValue(headlight_l2, "parentname", ent_name);
				DispatchKeyValue(headlight_l2, "targetname", light_index);
				DispatchKeyValueFloat(headlight_l2, "HDRColorScale", 1.0);
				DispatchKeyValue(headlight_l2, "renderamt", "200");
				DispatchKeyValueVector(headlight_l2, "rendercolor", white_rgb);
				DispatchKeyValue(headlight_l2, "spawnflags", "0");
				DispatchKeyValue(headlight_l2, "rendermode", "3");
				DispatchKeyValue(headlight_l2, "model", "sprites/light_glow03.spr");
				DispatchKeyValueFloat(headlight_l2, "scale", 0.35);
				DispatchSpawn(headlight_l2);
				TeleportEntity(headlight_l2, vec, NULL_VECTOR, NULL_VECTOR);
				SetVariantString(Car_Name);
				AcceptEntityInput(headlight_l2, "SetParent", headlight_l2, headlight_l2, 0);
				SetVariantString("light_fl");
				AcceptEntityInput(headlight_l2, "SetParentAttachment", headlight_l2, headlight_l2, 0);
				AcceptEntityInput(headlight_l2, "HideSprite");

				g_CarLightQuantity[car_index2] += 1;
				g_CarLights[car_index2][8] = headlight_l2;


				new headlight_r2 = CreateEntityByName("env_sprite");


				DispatchKeyValue(headlight_r2, "parentname", ent_name);
				DispatchKeyValue(headlight_r2, "targetname", light_index);
				DispatchKeyValueFloat(headlight_r2, "HDRColorScale", 1.0);
				DispatchKeyValue(headlight_r2, "renderamt", "200");
				DispatchKeyValueVector(headlight_r2, "rendercolor", white_rgb);
				DispatchKeyValue(headlight_r2, "spawnflags", "0");
				DispatchKeyValue(headlight_r2, "rendermode", "3");
				DispatchKeyValue(headlight_r2, "model", "sprites/light_glow03.spr");
				DispatchKeyValueFloat(headlight_r2, "scale", 0.35);
				DispatchSpawn(headlight_r2);
				TeleportEntity(headlight_r2, vec, NULL_VECTOR, NULL_VECTOR);
				SetVariantString(Car_Name);
				AcceptEntityInput(headlight_r2, "SetParent", headlight_r2, headlight_r2, 0);
				SetVariantString("light_fr");
				AcceptEntityInput(headlight_r2, "SetParentAttachment", headlight_r2, headlight_r2, 0);
				AcceptEntityInput(headlight_r2, "HideSprite");

				g_CarLightQuantity[car_index2] += 1;
				g_CarLights[car_index2][9] = headlight_r2;						
			}
		}
		CarSiren[ent] = false;
		CarView[ent] = false;		
	}
	return ent;
}
stock GetRandomCar()
{
	new t = 0;
	do {
		t = GetRandomInt(1,car_quantity-1);
		if(car_vip[t] == 1)
			t = 0;
	} while(t==0);
	return t;
}
public bool:ReadCarConfig()
{
	if(KvGotoFirstSubKey(kv))
	{
		new String:sec_name[8];
		do
		{
			KvGetSectionName(kv, sec_name, sizeof(sec_name));
			PrintToServer("[Rally] Loading Car #%s", sec_name);
			KvGetString(kv, "name", car_name[car_quantity], sizeof(car_name[]));
			KvGetString(kv,"model",car_model[car_quantity],sizeof(car_model[]), "FUCK_YOU");
			KvGetString(kv,"script",car_script[car_quantity],sizeof(car_script[]), "FUCK_YOU");
			g_Car_skin_min[car_quantity] = KvGetNum(kv, "skin_min", 0);
			g_Car_skin_max[car_quantity] = KvGetNum(kv, "skin_max", 0);
			PrintToServer("[Rally] #%s name = %s and skins: %i", sec_name, car_name[car_quantity], g_Car_skin_max[car_quantity] + 1);
			PrecacheModel(car_model[car_quantity],true);
			
			car_vip[car_quantity] = KvGetNum(kv, "VIP", 0);
			car_lights[car_quantity] = KvGetNum(kv, "lights", 0);
			car_police_lights[car_quantity] = KvGetNum(kv, "police_lights", 0);
			car_view_enabled[car_quantity] = KvGetNum(kv, "view", 0);
			car_siren_enabled[car_quantity] = KvGetNum(kv, "siren", 0);
			car_driver_view[car_quantity] = KvGetNum(kv, "driver", 0);
			
			PrintToServer("[Rally] #%s siren = %i view = %i, vip = %i", sec_name, car_siren_enabled[car_quantity], car_view_enabled[car_quantity], car_vip[car_quantity]);

			if (car_vip[car_quantity] == 1)
			{
				car_quantity_vip += 1;
			}
			car_quantity += 1;

		} while(KvGotoNextKey(kv));
	}
	KvRewind(kv);

	#if DEBUG == 1
	PrintToServer("Found %d Cars",car_quantity);
	#endif
	if(car_quantity == 0)
		return false;
		
	PrintToServer("[Rally] Cars Loaded");
	PrintToServer("[Rally] %i Cars were detected.", car_quantity - car_quantity_vip - 1);
	PrintToServer("[Rally] %i VIP Cars were detected.", car_quantity_vip);
	
	return true;
}
public ReadDownloadFile()
{
	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath),"configs/rallyrace/download.txt");

	new Handle:file = OpenFile(sPath, "rb");
	if(file == INVALID_HANDLE)
		return;

	new String:readData[256];
	new length;
	while(!IsEndOfFile(file) && ReadFileLine(file, readData, sizeof(readData)))
	{
		TrimString(readData);
		if(!FileExists(readData))
			continue;

		length = strlen(readData);
		if(length >= 4)
		{
			if(StrEqual(readData[length-4],".mdl") && !IsModelPrecached(readData))
			{
				PrecacheModel(readData,true);
			}
		}
		AddFileToDownloadsTable(readData);
	}

	CloseHandle(file);
}


LeaveVehicle(client)
{
	new vehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	if (IsValidEntity(vehicle))
	{
		// Put client in Exit attachment.
		new String:car_ent_name[128];
		GetTargetName(vehicle, car_ent_name, sizeof(car_ent_name));		
		SetVariantString(car_ent_name);
		AcceptEntityInput(client, "SetParent");
		CarView[client] = false;
		SetVariantString("vehicle_driver_exit");
		AcceptEntityInput(client, "SetParentAttachment");		

		new Float:ExitAng[3];
		GetEntPropVector(vehicle, Prop_Data, "m_angRotation", ExitAng);
		ExitAng[0] = 0.0;
		ExitAng[1] += 90.0;
		ExitAng[2] = 0.0;
		
	
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

		SetEntPropFloat(vehicle, Prop_Data, "m_flTurnOffKeepUpright", 0.0);
	
		SetEntProp(vehicle, Prop_Send, "m_iTeamNum", 0);
		
		SetClientViewEntity(client, client);
		
		TeleportEntity(client, NULL_VECTOR, ExitAng, NULL_VECTOR);
		
	
		SetClientViewEntity(client, client);

		new car_index = g_CarIndex[vehicle];	
		new max = g_CarLightQuantity[car_index];
		if (max > 0)
		{
			decl light;
			light = g_CarLights[car_index][0];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "HideSprite");
			}
			light = g_CarLights[car_index][1];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "HideSprite");
			}
			if (max > 2)
			{
				light = g_CarLights[car_index][2];
				if (IsValidEntity(light))
				{
					AcceptEntityInput(light, "HideSprite");
				}
				light = g_CarLights[car_index][3];
				if (IsValidEntity(light))
				{
					AcceptEntityInput(light, "HideSprite");
				}

	/*			AcceptEntityInput(g_CarLights[car_index][6], "LightOff");
				AcceptEntityInput(g_CarLights[car_index][7], "LightOff"); */
			}
		}
	}
	if (vehicle > 0)
	{
		if (IsValidEntity(Cars_Driver_Prop[vehicle]))
		{
			AcceptEntityInput(Cars_Driver_Prop[vehicle],"Kill");
			RemoveEdict(Cars_Driver_Prop[vehicle]);
			Cars_Driver_Prop[vehicle] = -1;
		}
	}
	SetEntProp(client, Prop_Send, "m_ArmorValue", armour[client], 1 );
	Driving[client] = false;
	
	// Fix no weapon
	new plyr_gun2 = GetPlayerWeaponSlot(client, 2);
	if (IsValidEntity(plyr_gun2))
	{
		RemovePlayerItem(client, plyr_gun2);
		RemoveEdict(plyr_gun2);
		GivePlayerItem(client, "weapon_knife", 0);
	}		
}
public ViewToggle(client)
{
	new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	new t = cars_type[car];
	if (!car_view_enabled[t])
	{
		return;
	}
	new String:car_ent_name[128];
	GetTargetName(car,car_ent_name,sizeof(car_ent_name));
	if(CarView[client] == true)
	{
		SetVariantString(car_ent_name);
		AcceptEntityInput(client, "SetParent");
		CarView[client] = false;
		SetVariantString("vehicle_driver_eyes");
		AcceptEntityInput(client, "SetParentAttachment");	
		return;
	}
	if(CarView[client] == false)
	{
		SetVariantString(car_ent_name);
		AcceptEntityInput(client, "SetParent");
		CarView[client] = true;
		SetVariantString("vehicle_3rd");
		AcceptEntityInput(client, "SetParentAttachment");	
		return;
	}
}
public Action:Car_Siren(client, args)
{
	if (IsPlayerAlive(client))
	{
		new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		if(car != -1)
		{
			new t = cars_type[car];
			if (car_siren_enabled[t] == 1)
			{
				SirenToggle(car, client);
			}
			else PrintToChat(client, "\x04[RR] %T", "No_Siren", LANG_SERVER);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x04[RR] %T", "Get_Inside", LANG_SERVER);
		return Plugin_Handled;
	}
	else PrintToChat(client, "\x04[RR] %T", "Youre_Dead", LANG_SERVER);
	return Plugin_Handled;		
}
public SirenToggle(car, client)
{
	if(CarSiren[car] == true)
	{
		CarSiren[car] = false;
		PrintToChat(client, "\x04[RR] %T", "Siren_Off", client);
		return;
	}
	if(CarSiren[car] == false)
	{
		CarSiren[car] = true;
		PrintToChat(client, "\x04[RR] %T", "Siren_On", client);
		EmitSoundToAllAny("vehicles/police_siren_single.mp3", client, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT);
		h_siren_a = CreateTimer(0.15, A_Time, car);
		h_siren_c = CreateTimer(4.50, C_Time, car);
		
		return;
	}
}
public Action:A_Time(Handle:timer, any:car)
{
	new car_index = g_CarIndex[car];
	if (IsValidEntity(car))
	{
		decl light;
		if(CarSiren[car] == true)
		{
			light = g_CarLights[car_index][4];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "ShowSprite");
			}
			light = g_CarLights[car_index][5];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "HideSprite");
			}
			h_siren_b = CreateTimer(0.15, B_Time, car);		
		}
		if(CarSiren[car] == false)
		{
			light = g_CarLights[car_index][4];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "HideSprite");
			}
			light = g_CarLights[car_index][5];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "HideSprite");
			}
		}
	}
}
public Action:B_Time(Handle:timer, any:car)
{
	new car_index = g_CarIndex[car];
	if (IsValidEntity(car))
	{
		decl light;
		if(CarSiren[car] == true)
		{
			light = g_CarLights[car_index][4];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "HideSprite");	
			}
			light = g_CarLights[car_index][5];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "ShowSprite");
			}
			h_siren_a = CreateTimer(0.15, A_Time, car);		
		}
		if(CarSiren[car] == false)
		{
			light = g_CarLights[car_index][4];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "HideSprite");
			}
			light = g_CarLights[car_index][5];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "HideSprite");
			}
		}
	}
}
public Action:C_Time(Handle:timer, any:car)
{
	if((CarSiren[car] == true) && (IsValidEntity(car)))
	{
		new Driver = GetEntPropEnt(car, Prop_Send, "m_hPlayer");
		if (Driver != -1)
		{
			EmitSoundToAllAny("vehicles/police_siren_single.mp3", Driver, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT);
			h_siren_c = CreateTimer(4.50, C_Time, car);
		}
	}
}
public Action:Horn_Time(Handle:timer, any:Driver)
{
	CarHorn[Driver] = false;
}
// These are functions unrelated to the cars.
public bool:TraceEntityFilterPlayers( entity, contentsMask, any:data )
{
    return entity > MaxClients && entity != data;
}


// ######
// EVENTS
// ######



public Action:Event_PlayerSpawnPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);
	
	if (GetEntPropEnt(client, Prop_Send, "m_hVehicle") != -1)
	{
		LeaveVehicle(client);
	}
	CarHorn[client] = false;
	//CreateTimer(0.1, HudRallyRace, client);
	return Plugin_Continue;
}
public Action:Event_PlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);

	LeaveVehicle(client);	
	SetClientViewEntity(client, client);
	CarHorn[client] = false;
	
	return Plugin_Continue;
}
public OnEntityDestroyed(entity)
{
	new String:ClassName[30];
	if (IsValidEdict(entity))
	{
		GetEdictClassname(entity, ClassName, sizeof(ClassName));
		if (StrEqual("prop_vehicle_driveable", ClassName, false))
		{
			new Driver = GetEntPropEnt(entity, Prop_Send, "m_hPlayer");
			if (Driver != -1)
			{
				LeaveVehicle(Driver);
				CarOn[entity] = false;
			}
		}
	}
	SDKUnhook(entity, SDKHook_Think, OnThink);
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static bool:PressingUse[MAXPLAYERS + 1];
	static bool:DuckBuffer[MAXPLAYERS + 1];
	static OldButtons[MAXPLAYERS + 1];
	new use = 0;
	use = GetConVarInt(h_rallyrace_use);

	if (use == 1)
	{
		if (!(OldButtons[client] & IN_USE) && (buttons & IN_USE))
		{
			if (!PressingUse[client])
			{
				if (GetEntPropEnt(client, Prop_Send, "m_hVehicle") != -1)
				{
					LeaveVehicle(client);
					buttons &= ~IN_USE;
					PressingUse[client] = true;
					OldButtons[client] = buttons;
					return Plugin_Handled;
				}
				else
				{
					decl Ent;
					Ent = GetClientAimTarget(client, false);
					if (IsValidEdict(Ent))
					{
						decl String:ClassName[255];
						GetEdictClassname(Ent, ClassName, 255);

						//Valid:
						if (StrEqual(ClassName, "prop_vehicle_driveable", false))
						{
							new Float:origin[3];
							new Float:car_origin[3];
							new Float:distance;

							GetClientAbsOrigin(client, origin);	
							GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", car_origin);
							distance = GetVectorDistance(origin, car_origin, false);
					
							// It is a car.  See if it is locked or not, and if it is in range.
							if ((!GetEntProp(Ent, Prop_Data, "m_bLocked")) && (distance <= 128.00))
							{
								// Car in range, unlocked.
								new Driver = GetEntPropEnt(Ent, Prop_Send, "m_hPlayer");
								if (Driver == -1)
								{
									AcceptEntityInput(Ent, "use", client);
									PressingUse[client] = true;
									OldButtons[client] = buttons;
									return Plugin_Handled;
								}						
							}
							else
							{
								EmitSoundToAllAny("natalya/doors/default_locked.mp3", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}							
				}
			}
			PressingUse[client] = true;
		}
		else
		{
			PressingUse[client] = false;
		}
	}
	else
	{
		buttons &= ~IN_USE;
	}
	if (buttons & IN_RELOAD)
	{
		new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		if ((car != -1) && (race_started == 1))
		{	
			AcceptEntityInput(car, "TurnOn");
			CarOn[car] = true;
		}
	}
	// impulse 100 detection is a candidate for depreciation
	if (impulse == 100)
	{
		new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		if (car != -1)
		{
			LightToggle(client);
		}
	}
	if (buttons & IN_DUCK)
	{
		if (!DuckBuffer[client])
		{
			new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if (car != -1)
			{
				ViewToggle(client);
			}			
		}
		DuckBuffer[client] = true;
	}
	else
	{
		DuckBuffer[client] = false;
	}
	OldButtons[client] = buttons;
	return Plugin_Continue;
}
public Action:Cmd_LookAtWeapon(client, const String:command[], argc)
{
	if ((client > 0) && (IsClientInGame(client)))
	{
		if(IsPlayerAlive(client))
		{
			new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if (car != -1)
			{
				LightToggle(client);
			}
		}
	}
}
public LightToggle(client)
{
	new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	new t = cars_type[car];
	if (car_lights[t] != 2)
	{
		return;
	}
	
	new car_index = g_CarIndex[car];

	AcceptEntityInput(g_CarLights[car_index][6], "Toggle");
	AcceptEntityInput(g_CarLights[car_index][7], "Toggle");
	AcceptEntityInput(g_CarLights[car_index][8], "ToggleSprite");
	AcceptEntityInput(g_CarLights[car_index][9], "ToggleSprite");

	// Lightswitch Noise
	new Driver = GetEntPropEnt(car, Prop_Send, "m_hPlayer");
	EmitSoundToAllAny("natalya/buttons/lightswitch2.mp3", Driver, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
}
public OnThink(entity)
{
	new Driver = GetEntPropEnt(entity, Prop_Send, "m_hPlayer");
	if (IsValidEntity(ViewEnt[entity]))
	{
		if (Driver > 0)
		{
			if(IsClientInGame(Driver) && IsPlayerAlive(Driver))
			{
				SetEntProp(entity, Prop_Data, "m_nNextThinkTick", 1);
				SetEntPropFloat(entity, Prop_Data, "m_flTurnOffKeepUpright", 1.0);
		
				SetClientViewEntity(Driver, ViewEnt[entity]);
				Driving[Driver] = true;
	
	
				new t = cars_type[entity];
				if (car_driver_view[t] == 1)
				{
					if (Cars_Driver_Prop[entity] == -1)
					{
						new prop = CreateEntityByName("prop_physics_override");
						if(IsValidEntity(prop))
						{
							new String:model[128];
							GetClientModel(Driver, model, sizeof(model));
							DispatchKeyValue(prop, "model", model);
							DispatchKeyValue(prop, "skin","0");
							
							ActivateEntity(prop);
							DispatchSpawn(prop);
                                        
							new enteffects = GetEntProp(prop, Prop_Send, "m_fEffects");  
							
							enteffects |= 1;	/* This is EF_BONEMERGE */
							enteffects |= 16;	/* This is EF_NOSHADOW */
							enteffects |= 64;	/* This is EF_NORECEIVESHADOW */
							enteffects |= 128;	/* This is EF_BONEMERGE_FASTCULL */
							enteffects |= 512;	/* This is EF_PARENT_ANIMATES */

							SetEntProp(prop, Prop_Send, "m_fEffects", enteffects);

							new String:car_ent_name[128];
							GetTargetName(entity,car_ent_name,sizeof(car_ent_name));
                    
							SetVariantString(car_ent_name);
							AcceptEntityInput(prop, "SetParent", prop, prop, 0);
							SetVariantString("vehicle_driver_eyes");
							AcceptEntityInput(prop, "SetParentAttachment", prop, prop, 0);	
							Cars_Driver_Prop[entity] = prop;
						}
					}
				}
				else Cars_Driver_Prop[entity] = -1;
			}
		}
	}
	if (GetEntProp(entity, Prop_Send, "m_bEnterAnimOn") == 1)
	{
		SetEntProp(entity, Prop_Send, "m_nSequence", 0);
		
		GetClientAuthString(Driver, authid[Driver], sizeof(authid[]));
		SetVariantString(authid[Driver]);
		DispatchKeyValue(Driver, "targetname", authid[Driver]);
	
		decl String:targetName[100];
		
		decl Float:sprite_rgb[3];
		sprite_rgb[0] = 0.0;
		sprite_rgb[1] = 0.0;
		sprite_rgb[2] = 0.0;
		
		GetTargetName(entity, targetName, sizeof(targetName));
	
		new sprite = CreateEntityByName("env_sprite");
		
		DispatchKeyValue(sprite, "model", "materials/sprites/dot.vmt");
		DispatchKeyValue(sprite, "renderamt", "0");
		DispatchKeyValue(sprite, "renderamt", "0");
		DispatchKeyValueVector(sprite, "rendercolor", sprite_rgb);
		
		DispatchSpawn(sprite);
		
		new Float:vec[3], Float:ang[3];
		
		GetClientAbsOrigin(Driver, vec);
		GetClientAbsAngles(Driver, ang);
		
		TeleportEntity(sprite, vec, ang, NULL_VECTOR);
		
		SetClientViewEntity(Driver, sprite);
		
		SetVariantString("!activator");
		AcceptEntityInput(sprite, "SetParent", Driver);
		
		SetVariantString(targetName);
		AcceptEntityInput(Driver, "SetParent");
		
		SetVariantString("vehicle_driver_eyes");
		AcceptEntityInput(Driver, "SetParentAttachment");
		
//		SetEntProp(entity, Prop_Send, "m_nSolidType", 2);
				
		ViewEnt[entity] = sprite;
	
		CarHorn[Driver] = false;
		armour[Driver] = GetEntProp(Driver, Prop_Send, "m_ArmorValue");
		SetEntProp(entity, Prop_Send, "m_bEnterAnimOn", 0);
		SetEntProp(entity, Prop_Send, "m_nSequence", 0);
		
		if (racing == 1)
		{
			AcceptEntityInput(entity, "TurnOn");
			CarOn[entity] = true;
		}
	}
	if (Driver > 0)
	{
		Driving[Driver] = true;
		buttons2 = GetClientButtons(Driver);
		// Brake Lights on or Off

		if (buttons2 & IN_ATTACK)
		{
			if (!CarHorn[Driver])
			{
				EmitSoundToAllAny("vehicles/mustang_horn.mp3", Driver, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT);
				CarHorn[Driver] = true;
				new Float:delay = GetConVarFloat(g_Cvar_DelayH);
				h_horn = CreateTimer(delay, Horn_Time, Driver);
			}
		}
		new car_index = g_CarIndex[entity];
		new max = g_CarLightQuantity[car_index];
		if (max > 0)
		{
			decl light;
			if (CarOn[entity])
			{
				light = g_CarLights[car_index][2];
				if (IsValidEntity(light))
				{
					AcceptEntityInput(light, "ShowSprite");
					if ((buttons2 & IN_BACK) && !(buttons2 & IN_JUMP))
					{
						SetVariantInt(255);
						AcceptEntityInput(light, "ColorGreenValue");
						SetVariantInt(255);
						AcceptEntityInput(light, "ColorBlueValue");
					}
					else
					{
						SetVariantInt(0);
						AcceptEntityInput(light, "ColorGreenValue");
						SetVariantInt(0);
						AcceptEntityInput(light, "ColorBlueValue");					
					}
				}
				light = g_CarLights[car_index][3];
				if (IsValidEntity(light))
				{
					AcceptEntityInput(light, "ShowSprite");
					if ((buttons2 & IN_BACK) && !(buttons2 & IN_JUMP))
					{
						SetVariantInt(255);
						AcceptEntityInput(light, "ColorGreenValue");
						SetVariantInt(255);
						AcceptEntityInput(light, "ColorBlueValue");
					}
					else
					{
						SetVariantInt(0);
						AcceptEntityInput(light, "ColorGreenValue");
						SetVariantInt(0);
						AcceptEntityInput(light, "ColorBlueValue");					
					}
				}
				
			/*	AcceptEntityInput(g_CarLights[car_index][6], "LightOn");
				AcceptEntityInput(g_CarLights[car_index][7], "LightOn"); */
			}
			if (buttons2 & IN_JUMP)
			{	
				light = g_CarLights[car_index][0];
				if (IsValidEntity(light))
				{
					AcceptEntityInput(light, "ShowSprite");
				}
				light = g_CarLights[car_index][1];
				if (IsValidEntity(light))
				{
					AcceptEntityInput(light, "ShowSprite");
				}
			}
			else
			{	
				light = g_CarLights[car_index][0];
				if (IsValidEntity(light))
				{
					AcceptEntityInput(light, "HideSprite");
				}
				light = g_CarLights[car_index][1];
				if (IsValidEntity(light))
				{
					AcceptEntityInput(light, "HideSprite");
				}
			}
		}
		new speed = GetEntProp(entity, Prop_Data, "m_nSpeed");
		SetEntData(Driver, m_ArmorValue,speed,4,true);
	}
	decl Float:ang[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", ang);
		 
	new Float:roll = ang[2];
	
	if(roll > 100.0 || roll < -100.0)
	{
		g_VehicleFlippedTickCount[entity]++;
		
		if(g_VehicleFlippedTickCount[entity] >= 198) // 66 ticks per second * 3 seconds = 198 ticks
		{
			if (Driver != -1)
			{
				new buttons = GetClientButtons(Driver);

				if(buttons & (IN_USE|IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT|IN_SPEED|IN_JUMP|IN_ATTACK|IN_ATTACK2))
				{
					LeaveVehicle(Driver);
					FakeClientCommand(Driver, "kill");
					PrintToChatAll("%N is out of the race", Driver);
				}
			}
		}
	}
}
stock KillPlayerTimer(client)
{
	if(g_PlayerTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_PlayerTimer[client]);
		g_PlayerTimer[client] = INVALID_HANDLE;
	}
}

stock Disintegrate(client)
{
	new ragdoll = GetEntDataEnt2(client,m_hRagdoll);
	if(ragdoll != -1)
	{
		RemoveEdict(ragdoll);
	}
}

stock RemoveIdleWeapon()
{
	new maxents = GetMaxEntities();
	for(new i=0;i<=maxents;i++)
	{
		new String:Class[65];
		if(IsValidEdict(i) && IsValidEntity(i) && IsEntNetworkable(i))
		{
			GetEdictClassname(i, Class, sizeof(Class));
			if(StrContains(Class,"weapon_") != -1 || StrContains(Class,"defuser") != -1)
			{
				decl owner;
				owner = GetEntData(i,m_hOwnerEntity);
				if (owner == -1)
				{
					RemoveEdict(i);
				}
			}
		}
	}
}
stock CallOnPlayerFinishRace(client, bool:isfinish, minutes, Float:seconds)
{
	Call_StartForward(F_OnPlayerFinishRace);
	Call_PushCell(client);
	Call_PushCell(isfinish);
	Call_PushCell(minutes);
	Call_PushFloat(seconds);
	Call_Finish();
}
stock CleanUpRound()
{
	// No more clean up round stock...  But let's at least delete any spawned cars.
	decl maxplayers;
	maxplayers = GetMaxClients();
	for (new client = 1; client <= maxplayers; client++) 
	{
		if (cars_spawned[client] > 0)
		{
			if (spawned_car[client] != -1)
			{
				new car = spawned_car[client];
				if (IsValidEntity(car))
				{	
					new driver = GetEntPropEnt(car, Prop_Send, "m_hPlayer");
					if (driver != -1)
					{
						LeaveVehicle(driver);
					}
		
					CarOn[car] = false;
					AcceptEntityInput(car,"KillHierarchy");
					cars_t_name[car] = "FUCKYOU";
					SDKUnhook(car, SDKHook_Think, OnThink);
					RemoveEdict(car);
				}			
			}
			spawned_car[client] = -1;
		}
		cars_spawned[client] = 0;
	}
}
stock SetPlayerToVehicle(client, vehicle)
{
	AcceptEntityInput(vehicle, "use", client);
}  	
public Action:Car_Command(client, args)
{
	new AdminId:admin = GetUserAdmin(client);
	if (admin != INVALID_ADMIN_ID)
	{
		DisplayMenu(g_ACarMenu, client, 0);
	}
	else
	{
		DisplayMenu(g_CarMenu, client, 0);
	}
	return Plugin_Handled;
}
public Action:Car_Exit(client, args)
{
	new AdminId:admin = GetUserAdmin(client);
	if (admin != INVALID_ADMIN_ID)
	{
		if (IsPlayerAlive(client))
		{
			new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if(car != -1)
			{
				LeaveVehicle(client);
				
				if (car > 0)
				{		
					if (IsValidEntity(Cars_Driver_Prop[car]))
					{
						AcceptEntityInput(Cars_Driver_Prop[car],"Kill");
						RemoveEdict(Cars_Driver_Prop[car]);
						Cars_Driver_Prop[car] = -1;
					}
				}			
				SetEntProp(client, Prop_Send, "m_ArmorValue", armour[client], 1 );
				Driving[client] = false;
			}
			else PrintToChat(client, "\x04[RR] %T", "Get_Inside", LANG_SERVER);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x04[RR] %T", "Youre_Dead", LANG_SERVER);
		return Plugin_Handled;			
	}	
	return Plugin_Handled;
}
public Action:Car_On(client, args)
{
	if (IsPlayerAlive(client))
	{
		new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		if((car != -1) && (race_started == 1))
		{
			AcceptEntityInput(car, "TurnOn");
			ActivateEntity(car);
			AcceptEntityInput(car, "TurnOn");
			CarOn[car] = true;
			PrintToChat(client, "\x04[RR] %T", "Car_On", client);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x04[RR] %T", "Get_Inside", client);
		return Plugin_Handled;
	}
	else PrintToChat(client, "\x04[RR] %T", "Youre_Dead", client);
	return Plugin_Handled;
}
public Action:Car_Off(client, args)
{
	if (IsPlayerAlive(client))
	{
		new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		if(car != -1)
		{
			AcceptEntityInput(car, "TurnOff");
			CarOn[car] = false;
			PrintToChat(client, "\x04[RR] %T", "Car_Off", client);

			new car_index = g_CarIndex[car];	
			new max = g_CarLightQuantity[car_index];
			if (max > 0)
			{
				decl light;
				light = g_CarLights[car_index][0];
				AcceptEntityInput(light, "HideSprite");
				light = g_CarLights[car_index][1];
				AcceptEntityInput(light, "HideSprite");
				if (max > 2)
				{
					light = g_CarLights[car_index][2];
					AcceptEntityInput(light, "HideSprite");
					light = g_CarLights[car_index][3];
					AcceptEntityInput(light, "HideSprite");
				}
			}
		}
		else PrintToChat(client, "\x04[RR] %T", "Get_Inside", client);
		return Plugin_Handled;			
	}
	else PrintToChat(client, "\x04[RR] %T", "Youre_Dead", client);
	return Plugin_Handled;		
}
public Action:Car_Lock(client, args)
{
	if (client == 0)
	{
		PrintToServer("[RR] Lock Command Disabled for RCON");
		return Plugin_Handled;
	}
	if (IsPlayerAlive(client))
	{
		new car = GetClientAimTarget(client, false);
		if(car != -1)
		{
			if (!GetEntProp(car, Prop_Data, "m_bLocked"))
			{
				AcceptEntityInput(car, "Lock", client);
				EmitSoundToAllAny("natalya/doors/default_locked.mp3", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
			}
			else
			{
				AcceptEntityInput(car, "Unlock", client);
				EmitSoundToAllAny("natalya/doors/latchunlocked1.mp3", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
			}
		}
		else PrintToChat(client, "\x04[RR] %T", "Look_At_Car", client);
		return Plugin_Handled;
	}
	else PrintToChat(client, "\x04[RR] %T", "Youre_Dead", LANG_SERVER);
	return Plugin_Handled;			
}

// ##########
// File Stuff
// ##########

public ReadSpawnFile(client)
{
	new String:sPath[PLATFORM_MAX_PATH];
	new String:mapname[64];
	new String:path_str[96];
	
	GetCurrentMap(mapname, sizeof(mapname));
	Format(path_str, sizeof(path_str), "configs/rallyrace/%s_spawns.txt", mapname);

	
	BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
	spawnkv = CreateKeyValues("Spawns");
	FileToKeyValues(spawnkv, sPath);

	KvRewind(spawnkv);

	if (!KvGotoFirstSubKey(spawnkv))
	{
		if (client == 0)
		{
			PrintToServer("[RR DEBUG] There are no spawns listed in %s, or there is an error with the file.", path_str);
		}
		else PrintToChat(client, "\x04[RR DEBUG] There are no spawns listed in %s, or there is an error with the file.", path_str);
		g_useSpawns2 = false;
		return;
	}
	
	new Float:spawn[3];
	g_SpawnQty = -1;
	new String:spawn_templol[8];

	for (new i = 0; i < MAX_SPAWNS; i++)
	{
		KvRewind(spawnkv);
		
		Format(spawn_templol, sizeof(spawn_templol), "%i", i);
		
		if (KvJumpToKey(spawnkv, spawn_templol, false))
		{
			spawn[0] = KvGetFloat(spawnkv, "x", 0.0);
			spawn[1] = KvGetFloat(spawnkv, "y", 0.0);
			spawn[2] = KvGetFloat(spawnkv, "z", 0.0);
			g_SpawnQty += 1;
	
			g_SpawnLoc[g_SpawnQty][0] = spawn[0];
			g_SpawnLoc[g_SpawnQty][1] = spawn[1];
			g_SpawnLoc[g_SpawnQty][2] = spawn[2];
			KvRewind(spawnkv);
			
			PrintToServer("[RR] Spawn #%i: x = %f  y = %f  z = %f", i, spawn[0], spawn[1], spawn[2]);
		}
		else
		{
			KvRewind(spawnkv);
			break;		
		}
	}
	
	if (client == 0)
	{
		PrintToServer("[RR] Spawns Loaded");
		PrintToServer("[RR] %i spawns were detected.", g_SpawnQty+1);
	}
	else
	{
		PrintToChat(client, "\x04[RR] Spawns Loaded");
		PrintToChat(client, "\x04[RR] %i spawns were detected.", g_SpawnQty+1);
	}
	return;
}
stock CreateSpawnModeMenu(Handle:spawn_mode_menu, String:title_str[])
{
	SetMenuTitle(spawn_mode_menu, title_str);
		
	AddMenuItem(spawn_mode_menu, "1", "Set Location as a Spawn");
	AddMenuItem(spawn_mode_menu, "2", "Save");
	AddMenuItem(spawn_mode_menu, "3", "List Spawns");
	AddMenuItem(spawn_mode_menu, "4", "Reset Spawn Mode");
	AddMenuItem(spawn_mode_menu, "5", "Exit Spawn Mode");
}
public Action:CommandSpawnMode(client, Arguments)
{
	if (client < 1)
	{
		PrintToServer("[RR] You must be in-game to use this command.");
		return Plugin_Handled;
	}
	if (SpawnModeAdmin == -1)
	{
		SpawnModeAdmin = client;
		InSpawnMode = true;
		new case_thingy = -1;
		
		
		// First we check to see if we can load an existing spawn list.
		new String:sPath[PLATFORM_MAX_PATH];
		new String:mapname[64];
		new String:path_str[96];
	
		GetCurrentMap(mapname, sizeof(mapname));
		Format(path_str, sizeof(path_str), "configs/rallyrace/%s_spawns.txt", mapname);
	
		BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
		spawnmodekv = CreateKeyValues("Doors");

		if (spawnmodekv == INVALID_HANDLE)
		{
			CreateTimer(0.1, SpawnMode_Restart, client);
		}		
		
		if (!FileToKeyValues(spawnmodekv, sPath))
		{
			PrintToChat(client, "\x04[RR DEBUG] Spawns from file %s could not be loaded, or there is an error with the file, or the file does not exist.", path_str);
			PrintToChat(client, "\x04[RR DEBUG] A new file will be created.");
			case_thingy = 0;
		}
		else
		{
			PrintToChat(client, "\x04[RR DEBUG] Attempting to load spawns from file: %s", path_str);
			case_thingy = 1;
		}
		
		SMSpawns = 0;
		KvRewind(spawnmodekv);
		
		if (case_thingy == 1)
		{
			// This is where we load the existing spawn file.
			if (!KvGotoFirstSubKey(spawnmodekv))
			{
				PrintToChat(client, "\x04[RR DEBUG] There are no spawns listed in %s, or there is an error with the file.", path_str);
				case_thingy = 0;
			}
			else
			{
				new String:spawn_templol2[8];
				new Float:spawn_lol[3];
				
				for (new i = 0; i < MAX_SPAWNS; i++)
				{
					KvRewind(spawnmodekv);
					
					Format(spawn_templol2, sizeof(spawn_templol2), "%i", i);
					if (KvJumpToKey(spawnmodekv, spawn_templol2, false))
					{
						spawn_lol[0] = KvGetFloat(spawnmodekv, "x", 0.0);
						spawn_lol[1] = KvGetFloat(spawnmodekv, "y", 0.0);
						spawn_lol[2] = KvGetFloat(spawnmodekv, "z", 0.0);
						g_SpawnQty += 1;
				
						g_SpawnLoc[g_SpawnQty][0] = spawn_lol[0];
						g_SpawnLoc[g_SpawnQty][1] = spawn_lol[1];
						g_SpawnLoc[g_SpawnQty][2] = spawn_lol[2];
						KvRewind(spawnmodekv);
					}
				}
				PrintToChat(client, "\x04[RR] %i custom spawns were detected.", SMSpawns);
			}
		}		
		// Make spawn menu, do stuff, etc...
		
		new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
		new String:title_str[32];
		Format(title_str, sizeof(title_str), "Spawn Mode");
		CreateSpawnModeMenu(spawn_mode_menu, title_str);		
		DisplayMenu(spawn_mode_menu, client, MENU_TIME_FOREVER);
	}
	else if (SpawnModeAdmin == client)
	{
		// Same shit, different day.  Make spawn menu, etc...
		
		InSpawnMode = true;
		new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
		new String:title_str[32];
		Format(title_str, sizeof(title_str), "Spawn Mode");
		CreateSpawnModeMenu(spawn_mode_menu, title_str);		
		DisplayMenu(spawn_mode_menu, client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintToChat(client, "\x03[RR ADMIN] Admin %N is currently using Spawn Mode.", SpawnModeAdmin);
	}
	return Plugin_Handled;
}
public Action:SpawnMode_Restart(Handle:Timer, any:client)
{
	spawnmodekv = CreateKeyValues("Spawns");
	SMSpawns = 0;
	KvRewind(spawnmodekv);
	if (spawnmodekv == INVALID_HANDLE)
	{
		CreateTimer(0.1, SpawnMode_Restart, client);
	}
}
public Menu_SpawnMode(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info,"1"))
		{
			decl Ent;
			//Ent:
			Ent = GetClientAimTarget(param1, false);
			if (Ent == -1)
			{
				decl Float:_origin[3], Float:_angles[3];
				GetClientEyePosition( param1, _origin );
				GetClientEyeAngles( param1, _angles );

				new Handle:trace = TR_TraceRayFilterEx( _origin, _angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers );
				if( !TR_DidHit( trace ) )
				{
					PrintToChat(param1, "\x03[RR]Unable to pick the current location.");
					return;
				}
				decl Float:position[3];
				TR_GetEndPosition(position, trace);

				PrintToChat(param1, "\x03[RR] New Spawn #%i -- Location: %f, %f, %f.", SMSpawns, position[0], position[1], position[2]);

				g_SpawnModeLoc[SMSpawns][0] = position[0];
				g_SpawnModeLoc[SMSpawns][1] = position[1];
				g_SpawnModeLoc[SMSpawns][2] = position[2];
				
				
				new String:spawn_temp[8];
				Format(spawn_temp, sizeof(spawn_temp), "%i", SMSpawns);
				
				KvRewind(spawnmodekv);
				if (KvJumpToKey(spawnmodekv, spawn_temp, true))
				{
					KvSetFloat(spawnmodekv, "x", position[0]);
					KvSetFloat(spawnmodekv, "y", position[1]);
					KvSetFloat(spawnmodekv, "z", position[2]+4);
					SMSpawns += 1;
					
				} else PrintToChat(param1, "\x03[RR ERROR] Spawn %i could not be created.  :(", SMSpawns);
				KvRewind(spawnmodekv);
				
			}
			else PrintToChat(param1, "\x03[RR ADMIN] You must look at the ground.");
			
			InSpawnMode = true;
			new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "Spawn Mode");
			CreateSpawnModeMenu(spawn_mode_menu, title_str);		
			DisplayMenu(spawn_mode_menu, param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info,"2"))
		{
			// Save Spawns
			new String:sPath[PLATFORM_MAX_PATH];
			new String:mapname[64];
			new String:path_str[96];
	
			GetCurrentMap(mapname, sizeof(mapname));
			Format(path_str, sizeof(path_str), "configs/rallyrace/%s_spawns.txt", mapname);
			
			BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
			KvRewind(spawnmodekv);
			KeyValuesToFile(spawnmodekv, sPath);			
			
			new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "All Spawns Saved");
			CreateSpawnModeMenu(spawn_mode_menu, title_str);		
			DisplayMenu(spawn_mode_menu, param1, MENU_TIME_FOREVER);
			
			PrintToChat(param1, "\x03[RR ADMIN] Spawns Saved, changes not loaded yet.");
		}
		if (StrEqual(info,"3"))
		{
			// List Spawns
			new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "See Console for Output.");
			CreateSpawnModeMenu(spawn_mode_menu, title_str);		
			DisplayMenu(spawn_mode_menu, param1, MENU_TIME_FOREVER);
			
			if (SMSpawns <= 0)
			{
				PrintToChat(param1, "\x03[RR ADMIN] No Spawns Yet.");
			}
			else
			{
				KvRewind(spawnmodekv);
				
				PrintToChat(param1, "\x03[RP ADMIN] See Console for Output.");
				PrintToConsole(param1, "[RR] Spawn Mode Spawns");
				PrintToConsole(param1, "Total Spawns:  %i", SMSpawns);
				
				new Float:temp_x;
				new Float:temp_y;
				new Float:temp_z;
				
				new String:spawn_temp2[4];
								
				for (new i = 0; i <= SMSpawns; i++)
				{
					Format(spawn_temp2, sizeof(spawn_temp2), "%i", i);
					if (KvJumpToKey(spawnmodekv, spawn_temp2, false))
					{
						temp_x = KvGetFloat(spawnmodekv, "x", -6.6);
						temp_y = KvGetFloat(spawnmodekv, "y", -6.6);
						temp_z = KvGetFloat(spawnmodekv, "z", -6.6);
						
						PrintToConsole(param1, "Spawn #%i:  x = %f  y = %f  z = %f", i, temp_x, temp_y, temp_z);
						KvRewind(spawnmodekv);
					}
					else
					{
						KvRewind(spawnmodekv);
						break;
					}
				}
			}
		}
		if (StrEqual(info,"4"))
		{
			// Reset all changes.
			new Handle:spawn_mode_reset_menu = CreateMenu(Menu_SpawnModeReset);
			SetMenuTitle(spawn_mode_reset_menu, "Delete All Changes?");
		
			AddMenuItem(spawn_mode_reset_menu, "1", "Yes");
			AddMenuItem(spawn_mode_reset_menu, "2", "No");
		
			DisplayMenu(spawn_mode_reset_menu, param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info,"5"))
		{
			new Handle:spawn_mode_exit_menu = CreateMenu(Menu_SpawnModeExit);
			SetMenuTitle(spawn_mode_exit_menu, "Save Changes Before Exit?");
		
			AddMenuItem(spawn_mode_exit_menu, "1", "Yes");
			AddMenuItem(spawn_mode_exit_menu, "2", "No");
		
			DisplayMenu(spawn_mode_exit_menu, param1, MENU_TIME_FOREVER);
		}
	}
	return;
}
public Menu_SpawnModeReset(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info,"1"))
		{
			// Reset Spawns
			if (spawnmodekv != INVALID_HANDLE)
			{
				CloseHandle(spawnmodekv);
				spawnmodekv = INVALID_HANDLE;
			}
			spawnmodekv = CreateKeyValues("Spawns");
			SMSpawns = 0;
			KvRewind(spawnmodekv);
			
			new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "All Changes Reset");
			CreateSpawnModeMenu(spawn_mode_menu, title_str);		
			DisplayMenu(spawn_mode_menu, param1, MENU_TIME_FOREVER);
		}
		else
		{
			new Handle:spawn_mode_menu = CreateMenu(Menu_SpawnMode);		
			new String:title_str[32];
			Format(title_str, sizeof(title_str), "Spawn Mode");
			CreateSpawnModeMenu(spawn_mode_menu, title_str);		
			DisplayMenu(spawn_mode_menu, param1, MENU_TIME_FOREVER);
		}
	}
	return;
}
public Menu_SpawnModeExit(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info,"1"))
		{
			// Save and exit
			new String:sPath[PLATFORM_MAX_PATH];
			new String:mapname[64];
			new String:path_str[96];
	
			GetCurrentMap(mapname, sizeof(mapname));
			Format(path_str, sizeof(path_str), "configs/rallyrace/%s_spawns.txt", mapname);
			
			BuildPath(Path_SM, sPath, sizeof(sPath), path_str);
			KvRewind(spawnmodekv);
			KeyValuesToFile(spawnmodekv, sPath);
			if (spawnmodekv != INVALID_HANDLE)
			{
				KvRewind(spawnmodekv);
				CloseHandle(spawnmodekv);
				spawnmodekv = INVALID_HANDLE;
			}
			InSpawnMode = false;
			SpawnModeAdmin = -1;
			ReadSpawnFile(param1);
		}
		else
		{
			// Just exit
			InSpawnMode = false;
			SpawnModeAdmin = -1;
			if (spawnmodekv != INVALID_HANDLE)
			{
				KvRewind(spawnmodekv);
				CloseHandle(spawnmodekv);
				spawnmodekv = INVALID_HANDLE;
			}
			
			ReadSpawnFile(param1);
		}
	}
	return;
}
public Action:CommandSpawnReload(client, Arguments)
{
	ReadSpawnFile(client);
	return Plugin_Handled;
}

public Action:HudRallyRace(Handle:Timer, any:client)
{
	if(IsClientInGame(client))
	{
		new c = selected_car_type[client];
		new String:car_type_str[128];
		new Handle:pb = StartMessageOne("HintText", client);
		
		if (c == -1)
		{
			car_type_str = "Random";
		}
		else
		{
			car_type_str = car_name[c];
		}
		if (pb == INVALID_HANDLE)
		{
			PrintToChat(client, "INVALID_HANDLE");
		}
		else
		{
			new String:tmptext[1024];
			if (!IsPlayerAlive(client))
			{
				// Player is dead.  Show respawn countdown.

				Format(tmptext, sizeof(tmptext), "Car: %s\nYou are dead.", car_type_str);
				
				//PbSetString(pb, "hints", tmptext); 
				//EndMessage();
				// CreateTimer(0.1, HudRallyRace, client);
			}
			else
			{
				if (race_started == 0)
				{
					 
					
					Format(tmptext, sizeof(tmptext), "Car: %s", car_type_str);
					//PbSetString(pb, "hints", tmptext);
					//EndMessage();
					// CreateTimer(0.1, HudRallyRace, client);
				}
				else if (race_started == 1)
				{
					if (GetClientTeam(client) == 2)
					{
						Format(tmptext, sizeof(tmptext), "** Race In Progress **\nCar: %s", car_type_str);
						//PbSetString(pb, "hints", tmptext); 
						//EndMessage();
						//CreateTimer(0.1, HudRallyRace, client);
					}
					if (GetClientTeam(client) == 3)
					{
						Format(tmptext, sizeof(tmptext), "** GO GO GO **\nCar: %s\nCheckpoints: %d/%d\nPosition %d/%d", car_type_str, g_Player_CheckPoint[client][CHECKPOINT],g_Max_CheckPoint+1,g_Player_CheckPoint[client][POSITION],g_Player_Race_Count);
						//PbSetString(pb, "hints", tmptext);
						//EndMessage();
						//CreateTimer(0.1, HudRallyRace, client);
					}
				}
			}
		}
	}
}
// PrintHintText(client,"CheckPoints\n %d/%d\nPosition\n %d/%d",g_Player_CheckPoint[client][CHECKPOINT],g_Max_CheckPoint+1,g_Player_CheckPoint[client][POSITION],g_Player_Race_Count);