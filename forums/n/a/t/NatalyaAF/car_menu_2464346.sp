#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <halflife>
#include <roleplay_classes>
#include <emitsoundany>

#define	MAX_CARS						128
#define	MAX_ENTITIES					2048
#define	MAX_LIGHTS						12
#define CAR_VERSION						"0.90 GO"
#define VEHICLE_TYPE_AIRBOAT_RAYCAST	8
#define COLLISION_GROUP_PLAYER			5

#define HIDEHUD_WEAPONSELECTION			1
#define HIDEHUD_CROSSHAIR				256
#define HIDEHUD_INVEHICLE				1024
#define EF_NODRAW						32


new Handle:g_Cvar_Enable = INVALID_HANDLE;
new Handle:g_Cvar_Gas = INVALID_HANDLE;
new Handle:g_Cvar_GasUse = INVALID_HANDLE;
new Handle:g_Cvar_DelayH = INVALID_HANDLE;
new Handle:g_Cvar_Interval = INVALID_HANDLE;
new Handle:g_Cvar_Database = INVALID_HANDLE;
new Handle:g_Cvar_Debug = INVALID_HANDLE;
new Handle:g_Cvar_Override = INVALID_HANDLE;

new Handle:g_CarTimer = INVALID_HANDLE;
new Handle:g_GasTimer = INVALID_HANDLE;
new Handle:g_GasMenu = INVALID_HANDLE
new Handle:g_BuyMenu = INVALID_HANDLE;
new Handle:g_VIPBuyMenu = INVALID_HANDLE;
new Handle:g_InfoMenu = INVALID_HANDLE;
new Handle:g_VIPInfoMenu = INVALID_HANDLE;
new Handle:db_cars = INVALID_HANDLE;

new Handle:carbuykv;

new fuel_display[MAX_ENTITIES];
new mpg[MAX_ENTITIES];
new armour[MAXPLAYERS+1];

public bool:AtGas[MAXPLAYERS+1];
public bool:Driving[MAXPLAYERS+1];
public bool:Needs_Reset[MAXPLAYERS+1];

new Cars[MAXPLAYERS+1];
new String:authid[MAXPLAYERS+1][35];
new Float:CurrentEyeAngle[MAXPLAYERS+1][3];

new g_CarIndex[4096];
new g_CarLightQuantity[MAX_ENTITIES];
new g_CarLights[MAX_ENTITIES][MAX_LIGHTS];
new g_CarQty = -1;
new g_SpawnedCars[MAXPLAYERS+1];

new gas_remaining[MAX_ENTITIES];
new gas_into_this_car[MAXPLAYERS+1];

// View Entity
new buttons2;
new ViewEnt[2048];

// Siren and Horn
public bool:CarSiren[MAX_ENTITIES+1];
public bool:CarView[MAXPLAYERS+1];
public bool:CarOn[MAX_ENTITIES+1];
new Float:car_fuel[MAX_ENTITIES+1];
public bool:CarHorn[MAXPLAYERS+1];
new Handle:h_siren_a = INVALID_HANDLE;
new Handle:h_siren_b = INVALID_HANDLE;
new Handle:h_siren_c = INVALID_HANDLE;
new Handle:h_horn = INVALID_HANDLE;

// Car Buy Menu Load Arrays
new car_quantity = 0;
new car_quantity_vip = 0;
new car_quantity_disabled = 0;
new car_vip[MAX_CARS];
new String:car_name[MAX_CARS][32];
new String:car_model[MAX_CARS][256];
new String:car_script[MAX_CARS][256];
new car_skins[MAX_CARS];
new car_price[MAX_CARS];
new car_mpg[MAX_CARS];
new car_lights[MAX_CARS];
new car_police_lights[MAX_CARS];
new car_view_enabled[MAX_CARS];
new car_siren_enabled[MAX_CARS];
new car_driver_view[MAX_CARS];
new Float:car_gas[MAX_CARS];
new car_passengers[MAX_CARS];
new String:car_passenger_seat[MAX_CARS][11][128];
new String:car_passenger_attachment[MAX_CARS][11][32];
new car_passenger_mode[MAX_CARS][11];
new Float:car_passenger_position[MAX_CARS][11][3];

// Temporary Car Menu Arrays
new selected_car[MAXPLAYERS+1];
new selected_car_stowed[MAXPLAYERS+1];
new selected_car_skin[MAXPLAYERS+1];
new selected_car_type[MAXPLAYERS+1];
new selected_car_index[MAXPLAYERS+1];
new Float:selected_car_fuel[MAXPLAYERS+1];
new String:selected_car_name[MAXPLAYERS+1][32];

new m_ArmorValue;
new MoneyOffset;

// Individual Car Arrays
new cars_type[MAX_ENTITIES];
new cars_index[MAX_ENTITIES];
new drivers_car[MAXPLAYERS+1];
new Car_Entity[MAXPLAYERS+1][10];
new Car_Type[MAXPLAYERS+1][10];
new Car_Skin[MAXPLAYERS+1][10];
new Float:Car_Gas[MAXPLAYERS+1][10];
new Cars_Driver_Prop[MAX_ENTITIES];
new cars_seats[MAX_ENTITIES];
new cars_seat_entities[MAX_ENTITIES][11];
new is_chair[MAX_ENTITIES];
new chairs_car[MAX_ENTITIES];
new car_owner[MAX_ENTITIES];
new bool:can_stow[MAXPLAYERS+1];
new cars_spawned[MAXPLAYERS+1];

// Player Loading to Database
public bool:InQuery;
public bool:IsDisconnect[33];
public bool:Loaded[33];

// IP Security
new String:player_ip[MAXPLAYERS+1][32];
new started = 0;


public Plugin:myinfo =
{
	name = "Car Menu",
	author = "Natalya",
	description = "CS:S Car Menu",
	version = CAR_VERSION,
	url = "http://www.lady-natalya.info/"
}

public OnPluginStart()
{
	// Load Plugin Requirements
	LoadTranslations("plugin.car_menu");
	
	m_ArmorValue = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
	MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

	// Commands
	RegConsoleCmd("sm_car_menu", Car_Menu, " -- Open the Car Menu.");
	RegConsoleCmd("sm_menu_voiture", Car_Menu, " -- Ouvrir le menu voiture.");
	RegConsoleCmd("sm_car_stow", Car_Stow_R, "Stow Your Car");
	RegConsoleCmd("sm_ranger_voiture", Car_Stow_R, " -- Ranger la voiture.");
	RegConsoleCmd("sm_car_on", Car_On, " -- Turn your car on.");
	RegConsoleCmd("sm_car_exit", Car_Exit, "-- Exit a Car.");
	RegConsoleCmd("sm_car_off", Car_Off, " -- Turn your car off.");
	RegConsoleCmd("sm_siren", Car_Siren, " -- Toggle a police cruiser's siren.");
	RegConsoleCmd("sm_car_view", Car_View, " -- Toggle between first and 3rd.");
	RegConsoleCmd("sm_car_info", Car_Info, " -- View information about the car you are driving.");
	RegConsoleCmd("sm_seat", Car_Seat, " -- Switch seats in a car if applicable.");
	
	RegAdminCmd("sm_car_register", Car_Register, ADMFLAG_CUSTOM3, "Admin register a car to be drivable after plugin reload.");
	RegAdminCmd("sm_car_kill", Car_Kill, ADMFLAG_CUSTOM3, "Admin Hard Delete a Car.");
	RegAdminCmd("sm_car_stow_a", Car_Stow, ADMFLAG_CUSTOM3, "Admin Only");
	RegAdminCmd("car_db_save", Command_DBSave, ADMFLAG_CUSTOM3, "Force Server DB Save");

	RegConsoleCmd("sm_car_menu_super", Car_Menu_Super, "Super Car Menu, MotherFucker!!");
	RegServerCmd("sm_verifyip", IP_Check, "RCON Only");
	RegServerCmd("sm_give_steam", Steam_Check, "RCON Only");
	RegServerCmd("sm_car_spawned", Car_Check, "RCON Only");
	RegServerCmd("sm_car_name", Cars_Name, "RCON Only");
	RegServerCmd("sm_car_skin", Cars_Skin, "RCON Only");
	RegServerCmd("sm_car_skin_num", Cars_Skin2, "RCON Only");
	RegServerCmd("sm_car_max_skins", Cars_Skin3, "RCON Only");
	RegServerCmd("sm_car_set_skin", Cars_Skin4, "RCON Only");
	RegServerCmd("sm_car_spawn", Car_Spawn, "RCON Only");


	// Server Variables
	CreateConVar("car_menu_version", CAR_VERSION, "Version of Car Menu on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_Enable = CreateConVar("car_menu_enabled", "1", " Enable/Disable the Car Menu plugin", FCVAR_PLUGIN);
	g_Cvar_Database = CreateConVar("car_db_mode", "0", "DB Location 1 = remote or 2 = local -- 0 = failure", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_Gas = CreateConVar("car_menu_gas_price", "3.00", "Set the price of gas.", FCVAR_PLUGIN);
	g_Cvar_GasUse = CreateConVar("car_menu_gas_enabled", "1", "Use gas in cars?", FCVAR_PLUGIN);
//	g_Cvar_DelayS = CreateConVar("car_stow_delay", "60.0", " Delay for car_stow command.", FCVAR_PLUGIN, true, 0.0);
	g_Cvar_DelayH = CreateConVar("car_horn_delay", "1.0", " Delay between horn honks.", FCVAR_PLUGIN, true, 0.1);
	g_Cvar_Interval = CreateConVar("car_save_interval", "3600.0", "Interval between Car DB saves in seconds.  Set higher if server doesn't crash frequently.", FCVAR_PLUGIN);
	g_Cvar_Debug 	= CreateConVar("car_debug_mode", "0", "Use 1 to turn Debug messages on or 0 to turn them off.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_Override = CreateConVar("car_vip_override", "0", "0 means no restrictions on spawning VIP cars, 1 means only VIPs can spawn VIP cars", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);


	// Hook Events
	HookEvent("player_spawn", Event_PlayerSpawnPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEntityOutput("trigger_multiple","OnStartTouch",OnStartTouch);
	HookEntityOutput("trigger_multiple","OnEndTouch",OnEndTouch);
	
	// Load the car buy menu
	ReadCarFile();
	
	
	// Load Players Already In Game
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			GetClientAuthId(client, AuthId_Engine, authid[client], sizeof(authid[]));
			Reset_Car_Selection(client);
			SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
			SDKHook(client, SDKHook_PreThink, OnPreThink);
			
			AtGas[client] = false;
			Driving[client] = false;			
			Loaded[client] = false;
			cars_spawned[client] = 0;
			can_stow[client] = true;
	
			CreateTimer(1.0, CreateSQLAccount, client);
		}
	}

	// Thanks to Mitchell for +lookatweapon listener
	AddCommandListener(Cmd_LookAtWeapon, "+lookatweapon");
}



// #######
// NATIVES
// #######



public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[],  err_max)
{
	CreateNative("IsClientDriving", NativeIsClientDriving);
	CreateNative("SpawnChair", NativeSpawnChair);
	CreateNative("IsEntityChair", NativeIsEntityChair);
	CreateNative("GetCarOwner", NativeGetCarOwner);
	RegPluginLibrary("car_menu");
	return APLRes_Success;
}
// native functions
public NativeIsClientDriving(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return Driving[client];
}
public NativeIsEntityChair(Handle:plugin, numParams)
{
	new entity = GetNativeCell(1);
	return is_chair[entity];
}
public NativeGetCarOwner(Handle:plugin, numParams)
{
	new car = GetNativeCell(1);
	return car_owner[car];
}
public NativeSpawnChair(Handle:plugin, numParams)
{
	// Create Variables
	new String:model[255];
	new skin = 0;
	new client = 0;
	new fail = -1;
	
	// Get the variables from the command
	GetNativeString(1, model, sizeof(model));
	skin = GetNativeCell(2);
	client = GetNativeCell(3);
	
	// Do it do it do it!!
	if (IsClientInGame(client))
	{	
		new seat = SpawnSeat2(model, skin, client);
		return seat;
	}
	else return fail;
}

public OnMapStart()
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		g_BuyMenu = BuildBuyMenu();
		g_VIPBuyMenu = BuildVIPBuyMenu();
		g_InfoMenu = BuildInfoMenu();
		g_VIPInfoMenu = BuildVIPInfoMenu();
		g_CarQty = -1;
		g_GasMenu = BuildGasMenu();
		
		CreateTimer(300.0, LOLCar_Time, INVALID_HANDLE);
	}

	if (started == 0)
	{
		new db_mode = GetConVarInt(g_Cvar_Database);
		if (db_mode == 0)
		{
			CreateTimer(1.0, FUCKING_CAR_MODE_NOT_0);
		}
		else InitializeCarDB();
	}
}
public Action:FUCKING_CAR_MODE_NOT_0(Handle:Timer, any:client)
{
	new db_mode = GetConVarInt(g_Cvar_Database);
	if (db_mode == 0)
	{
		PrintToChatAll("\x03[Car] car_db_mode is 0 -- set it to 1 or 2");
		CreateTimer(1.0, FUCKING_CAR_MODE_NOT_0);
	}
	else InitializeCarDB();
}
public Action:LOLCar_Time(Handle:timer)
{
	new Float:interval_time = GetConVarFloat(g_Cvar_Interval);
	g_CarTimer = CreateTimer(interval_time, Car_Time, INVALID_HANDLE, TIMER_REPEAT);
}
public Action:Car_Time(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{	
			DBSave(client);
		}
	}
	PrintToServer("[Car] Auto Save -- updated clients in SQL Database.");
	LogMessage("[Car] Auto Save -- updated clients in SQL Database.");
}
public OnPluginEnd()
{
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{	
			GetClientAuthId(client, AuthId_Engine, authid[client], sizeof(authid[]));
			PrintToServer("[Car] Plugin Ending -- updating client in SQL Database.", authid[client]);
			LogMessage("[Car] Plugin Ending -- updating client in SQL Database.", authid[client]);
			DBSave(client);
		}
	}	
	UnhookEntityOutput("trigger_multiple","OnStartTouch",OnStartTouch);
	UnhookEntityOutput("trigger_multiple","OnEndTouch",OnEndTouch);
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
	for (new client = 1; client <= MaxClients; client++)
	{
    	if (IsClientInGame(client))
    	{
			if (Cars[client] > 0)
			{
				for (new index = 0; index < 10; index++)
				{
					if (IsValidEntity(Car_Entity[client][index]))
					{
						new car = Car_Entity[client][index];
						new driver = GetEntPropEnt(car, Prop_Send, "m_hPlayer");
						if (driver != -1)
						{
							LeaveVehicle(driver);
							drivers_car[driver] = -1;
						}
						
						Car_Gas[client][index] = car_fuel[car];
						Car_Entity[client][index] = -1;
						
						CarOn[car] = false;
						AcceptEntityInput(car,"Kill");
						cars_index[car] = -1;
					}
				}
			}
		}
	}
	if (g_CarTimer != INVALID_HANDLE)
	{
		CloseHandle(g_CarTimer);
		g_CarTimer = INVALID_HANDLE;
	}
	if (g_GasTimer != INVALID_HANDLE)
	{
		CloseHandle(g_GasTimer);
		g_GasTimer = INVALID_HANDLE;
	}
	if (h_siren_a != INVALID_HANDLE)
	{
		CloseHandle(h_siren_a);
		h_siren_a = INVALID_HANDLE;
	}
	if (h_siren_b != INVALID_HANDLE)
	{
		CloseHandle(h_siren_b);
		h_siren_b = INVALID_HANDLE;
	}
	if (h_siren_c != INVALID_HANDLE)
	{
		CloseHandle(h_siren_c);
		h_siren_c = INVALID_HANDLE;
	}
	if (h_horn != INVALID_HANDLE)
	{
		CloseHandle(h_horn);
		h_horn = INVALID_HANDLE;
	}
}



// ######
// CAR DB
// ######



public InitializeCarDB()
{
	ServerCommand("mp_startmoney 0");
	new String:error[255];
	new db_mode = GetConVarInt(g_Cvar_Database);
	
	if (db_mode == 1)
	{
		db_cars = SQL_Connect("ln-roleplay", true, error, sizeof(error));
		if(db_cars == INVALID_HANDLE)
		{
			SetFailState("[car_menu.smx] %s", error);
		}
	
		// Stuff
		new len = 0;
		decl String:query[20000];
	
		// Format the DB Car Table
		len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Cars`");
		len += Format(query[len], sizeof(query)-len, " (`STEAMID` varchar(25) NOT NULL, `LASTONTIME` int(25) NOT NULL DEFAULT 0, ");
		for(new i= 0; i < 10; i++)	// 10 cars max per user is hardcoded into the plugin here.  Who IRL has 10 cars?
		{
			len += Format(query[len], sizeof(query)-len, "`%iTYPE` int(25) NOT NULL DEFAULT 0, `%iSKIN` int(25) NOT NULL DEFAULT 0, `%iFUEL` float(7,4) NOT NULL DEFAULT 0, ", i, i, i, i);
		}
		len += Format(query[len], sizeof(query)-len, "PRIMARY KEY (`STEAMID`));");
	
	
		// Lock and Load!!
		SQL_LockDatabase(db_cars);
		SQL_FastQuery(db_cars, query);
		SQL_UnlockDatabase(db_cars);
		started = 1;
		
	}
	else if (db_mode == 2) //sqlite
	{
		db_cars = SQLite_UseDatabase("rp_cars", error, sizeof(error));
		if(db_cars == INVALID_HANDLE)
		{
			SetFailState("[car_menu.smx] %s", error);
		}
	
		// Stuff
		new len = 0;
		decl String:query[20000];
	
		// Format the DB Car Table
		len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Cars`");
		len += Format(query[len], sizeof(query)-len, " (`STEAMID` varchar(25) NOT NULL, `LASTONTIME` int(25) NOT NULL DEFAULT 0, ");
		for(new i= 0; i < 10; i++)	// 10 cars max per user is hardcoded into the plugin here.  Who IRL has 10 cars?
		{
			len += Format(query[len], sizeof(query)-len, "`%iTYPE` int(25) NOT NULL DEFAULT 0, `%iSKIN` int(25) NOT NULL DEFAULT 0, `%iFUEL` float(7,4) NOT NULL DEFAULT 0, ", i, i, i, i);
		}
		len += Format(query[len], sizeof(query)-len, "PRIMARY KEY (`STEAMID`));");
	
	
		// Lock and Load!!
		SQL_LockDatabase(db_cars);
		SQL_FastQuery(db_cars, query);
		SQL_UnlockDatabase(db_cars);
		started = 1;
	}
	else
	{
		Format(error, sizeof(error), "[Car] car_db_mode is %i when it needs to be 1 or 2.", db_mode);
		SetFailState("[car_menu.smx] %s", error);
	}
}
public InitializeClientonDB(client)
{
	if(IsFakeClient(client)) return true;
	
	new String:SteamId[255];
	new String:query[255];
	
	new conuserid;
	conuserid = GetClientUserId(client);
	
	GetClientAuthId(client, AuthId_Engine, SteamId, sizeof(SteamId));
	Format(query, sizeof(query), "SELECT LASTONTIME FROM Cars WHERE STEAMID = '%s';", SteamId);
	SQL_TQuery(db_cars, T_CheckConnectingItems, query, conuserid);
	return true;
}
public T_CheckConnectingItems(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	
	/* Make sure the client didn't disconnect while the thread was running */
	
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return true;
	}
	
	new String:SteamId[255];
	GetClientAuthId(client, AuthId_Engine, SteamId, sizeof(SteamId));
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		InitializeCarDB();
	}
	else 
	{
		new String:buffer[512];
		if (!SQL_GetRowCount(hndl))
		{
			// insert user
			GetClientAuthId(client, AuthId_Engine, SteamId, sizeof(SteamId));
			Format(buffer, sizeof(buffer), "INSERT INTO Cars (`STEAMID`,`LASTONTIME`, `0TYPE`, `0Skin`,`0FUEL`, `1TYPE`, `1Skin`,`1FUEL`, `2TYPE`, `2Skin`,`2FUEL`, `3TYPE`, `3Skin`,`3FUEL`, `4TYPE`, `4Skin`,`4FUEL`, `5TYPE`, `5Skin`,`5FUEL`, `6TYPE`, `6Skin`,`6FUEL`, `7TYPE`, `7Skin`,`7FUEL`, `8TYPE`, `8Skin`,`8FUEL`, `9TYPE`, `9Skin`,`9FUEL`) VALUES ('%s',%i, -1, 0, 0.0, -1, 0, 0.0, -1, 0, 0.0, -1, 0, 0.0, -1, 0, 0.0, -1, 0, 0.0, -1, 0, 0.0, -1, 0, 0.0, -1, 0, 0.0, -1, 0, 0.0);", SteamId, GetTime());
			SQL_FastQuery(db_cars, buffer);
			
			for(new X = 0;X < 10;X++)
			{
				Car_Type[client][X] = 0;
				Car_Skin[client][X] = 0;
				Car_Gas[client][X] = 0.0;
				Car_Entity[client][X] = -1;
			}
			Cars[client] = 0;
		}
		else
		{
			Format(buffer, sizeof(buffer), "SELECT * FROM `Cars` WHERE STEAMID = '%s';", SteamId);
			SQL_TQuery(db_cars, DBCarLoad_Callback, buffer, data);
		}
		FinallyLoaded(client);
	}
	return true;
}
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogMessage("SQL Error: %s", error);
	}
}
public FinallyLoaded(client)
{
	if(!IsClientConnected(client))return true;
	InQuery = false;		
	Loaded[client] = true;
	IsDisconnect[client] = false;
	
	return true;
}

// New Client Loading Done.  Now for Client Data Updating

public Action:DBSave_Restart(Handle:Timer, any:client){
	DBSave(client);
	return Plugin_Handled;
}
public DBSave(client)
{
	if(!IsClientConnected(client))return true;
	if(InQuery)
	{
		CreateTimer(1.0, DBSave_Restart, client);
		return true;
	}
	
	if(Loaded[client]){
		InQuery = true;
		new userid = GetClientUserId(client);
		
		//Declare:
		new String:SteamId[32], String:query[255];
		new UnixTime = GetTime();
		
		//Initialize:
		GetClientAuthId(client, AuthId_Engine, SteamId, 32);
		
		Format(query, sizeof(query), "UPDATE Cars SET LASTONTIME = %d WHERE STEAMID = '%s';",UnixTime, SteamId);
		SQL_TQuery(db_cars, T_SaveCallback, query, userid);		

		new t;
		new s;
		new Float:f;
		for(new X = 0;X < 10;X++)
		{
			t = Car_Type[client][X];
			s = Car_Skin[client][X];
			f = Car_Gas[client][X];
			Format(query, sizeof(query), "UPDATE Cars SET `%iTYPE` = %i, `%iSKIN` = %i, `%iFUEL` = %f WHERE STEAMID = '%s';", X, t, X, s, X, f, SteamId);
			SQL_TQuery(db_cars, T_SaveCallback, query, userid);
		}
			
		if(IsDisconnect[client])
		{
			Loaded[client] = false;
			IsDisconnect[client] = false;
		}
		InQuery = false;
	}
	return true;
}
// Now we go to loading existing clients.
public T_SaveCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	/* Make sure the client didn't disconnect while the thread was running */
	if (error[0])
	{
		LogError("[CAR DB ERROR] %s", error);
	}
	if (GetClientOfUserId(data) == 0)
	{
		return;
	}
	return;
}
public DBCarLoad_Callback(Handle:owner, Handle:hndl, const String:error[], any:data)
{  
	new client = GetClientOfUserId(data);
	Cars[client] = 0;
	
	//Make sure the client didn't disconnect while the thread was running
	
	if(client == 0)
	{
		return true;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		InitializeCarDB();
	}
	else
	{
		if(!SQL_GetRowCount(hndl))
		{
			LogError("Database error! SteamID not found!");
		}
		else
		{
			Cars[client] = 0;
			while (SQL_FetchRow(hndl))
			{
				new count = 2;
				new countb = 3;
				new countc = 4;
				for(new X = 0; X < 10; X++)
				{
					Car_Type[client][X] = SQL_FetchInt(hndl,(X+count));
					if (Car_Type[client][X] > 0)
					{
						Cars[client] += 1;
						Car_Skin[client][X] = SQL_FetchInt(hndl,(X+countb));
						Car_Gas[client][X] = SQL_FetchFloat(hndl,(X+countc));
						Car_Entity[client][X] = -1;
					}
					else (Car_Type[client][X] = 0);
					count += 2;
					countb += 2;
					countc += 2;
				}  
			}
		} 
	}
	return true;
}



// #######
// CLIENTS
// #######



public bool:OnClientConnect(client, String:Reject[], Len)
{
	if (GetConVarInt(g_Cvar_Debug))
	{
		PrintToServer("[Car DEBUG] Player %N (#%i) has Connected.", client, client);
	}
	//Disable:
	Loaded[client] = false;
	Cars[client] = 0;
	cars_spawned[client] = 0;
	can_stow[client] = true;
	for (new index = 0; index < 10; index++)
	{
		Car_Entity[client][index] = -1;
	}
	return true;
}
public OnClientPutInServer(client)
{
	if (GetConVarInt(g_Cvar_Debug))
	{
		PrintToServer("[Car DEBUG] Player %N (#%i) is being put in the server.", client, client);
	}
	//Default Values:
	CarHorn[client] = false;
	Driving[client] = false;
	Needs_Reset[client] = false;
	Reset_Car_Selection(client);
	drivers_car[client] = -1;
	AtGas[client] = false;
	
	if (GetConVarInt(g_Cvar_Debug))
	{
		PrintToServer("[Car DEBUG] Player %N (#%i) has had their defaults set.", client, client);
	}
	
	if (GetConVarInt(g_Cvar_Enable))
	{
		SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
		SDKHook(client, SDKHook_PreThink, OnPreThink);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		
		if (GetConVarInt(g_Cvar_Debug))
		{
			PrintToServer("[Car DEBUG] Player %N (#%i) has had their SDK Hooks set up.", client, client);
		}

		if(!Loaded[client])
		{
			CreateTimer(1.0, CreateSQLAccount, client);
		}
	}
	for (new index = 0; index < 10; index++)
	{
		Car_Entity[client][index] = -1;
	}

}
public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(g_Cvar_Debug))
	{
		PrintToServer("[Car DEBUG] Player %N (#%i) is past the Admin Check.", client, client);
	}
	for (new index = 0; index < 10; index++)
	{
		Car_Entity[client][index] = -1;
	}	
}
public Action:CreateSQLAccount(Handle:Timer, any:client)
{   
	if (!IsClientConnected(client))
	{
		CreateTimer(1.0, CreateSQLAccount, client);
	}
	else
	{
		new String:SteamId[64];
		GetClientAuthId(client, AuthId_Engine, SteamId, 64);
	
		if(StrEqual(SteamId, "") || InQuery)
		{
			CreateTimer(1.0, CreateSQLAccount, client);
		}
		else
		{	
			//PrintToChatAll("Connection Successful");
		
			// InQuery stops it from loading more than one player at a time.
			InQuery = true;
			InitializeClientonDB(client); 	
		}
	}
}
public OnClientDisconnect(client)
{
	CarHorn[client] = false;
	Driving[client] = false;
	AtGas[client] = false;
	Reset_Car_Selection(client);
	
	if (drivers_car[client] != -1)
	{
		if (client > 0)
		{
			if (IsClientInGame(client))
			{
				drivers_car[client] = -1
				LeaveVehicle(client);
			}
		}
	}
	for (new index = 0; index < 10; index++)
	{
		new car;
		car = Car_Entity[client][index];
		if ((car > 0) && (IsValidEdict(car)) && (IsValidEntity(car)))
		{
			new String:ClassName[64];
			GetEdictClassname(car, ClassName, 255);
			if (StrEqual(ClassName, "prop_vehicle_driveable", false))
			{
				new driver = GetEntPropEnt(car, Prop_Send, "m_hPlayer");
				if (driver != -1)
				{
					LeaveVehicle(driver);
				}
			}
			AcceptEntityInput(car,"Kill");
			SetCarOwnership(client, car, 0);
			CarOn[car] = false;
			cars_index[car] = -1;
		}
		Car_Entity[client][index] = -1;
	}
	IsDisconnect[client] = true;
	DBSave(client);
	can_stow[client] = true;
	cars_spawned[client] = 0;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}


//  ########
//  CAR MENU
//  ########



public Menu_Car(Handle:car, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		Reset_Car_Selection(param1);
		new String:info[32];
		GetMenuItem(car, param2, info, sizeof(info));
		if (StrEqual(info,"g_InvMenu"))
		{
			/* Create the menu Handle */
			new Handle:inv = CreateMenu(Menu_Inventory);

			decl String:title_str[32];
			if (Cars[param1] <= 0)
			{
				Format(title_str, sizeof(title_str), "%T:", "Garage", param1);
				
				decl String:cars_str[64];
				Format(cars_str, sizeof(cars_str), "%T", "Car_Zero", param1);
				AddMenuItem(inv,"-1",cars_str, ITEMDRAW_DISABLED);
			}
			if (Cars[param1] == 1)
			{
				Format(title_str, sizeof(title_str), "%T", "Car_One", param1);
			}
			if (Cars[param1] >> 1)
			{
				Format(title_str, sizeof(title_str), "%T", "Car_Qty", param1, Cars[param1]);
			}


			if (Cars[param1] > 0)
			{
				// Figure out what cars they have.

				decl String:car_string[64];
				decl t;

				for (new index = 0; index < 10; index++)
				{
					t = Car_Type[param1][index];
					if (t > 0)
					{
						Format(car_string, sizeof(car_string), "%i", index);
						AddMenuItem(inv,car_string,car_name[t]);
					}
				}
			}
			SetMenuTitle(inv, title_str);
			DisplayMenu(inv, param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info,"g_BuyMenu"))
		{
			DisplayMenu(g_BuyMenu, param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info,"g_InfoMenu"))
		{
			DisplayMenu(g_InfoMenu, param1, MENU_TIME_FOREVER);\
		}
		if (StrEqual(info,"g_VIPBuyMenu"))
		{
			DisplayMenu(g_VIPBuyMenu, param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info,"g_VIPInfoMenu"))
		{
			DisplayMenu(g_VIPInfoMenu, param1, MENU_TIME_FOREVER);\
		}
	}
}



// #############
// CAR INVENTORY
// #############



public Menu_Inventory(Handle:inv, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(inv, param2, info, sizeof(info));

		new index = StringToInt(info);

		if (index < 0)
		{
			PrintToChat(param1, "\x04[Car] %T (00)", "Selection_Error", param1);
			return;
		}
		if (Car_Type[param1][index] < 1)
		{
			PrintToChat(param1, "\x04[Car] %T (01)", "Selection_Error", param1);
			return;
		}
		selected_car[param1] = index;
		if (Car_Entity[param1][index] > 0)
		{
			selected_car_stowed[param1] = 0;
		}
		else selected_car_stowed[param1] = 1;

		selected_car_skin[param1] = Car_Skin[param1][index];
		selected_car_fuel[param1] = Car_Gas[param1][index];
		selected_car_index[param1] = index;
		selected_car_type[param1] = Car_Type[param1][index];

		new t = selected_car_type[param1];

		new String:skin_str[48];		
		
		KvJumpToKey(carbuykv, car_name[t], false);
		decl String:skin_num[4], String:colour[32];

		Format(skin_num, sizeof(skin_num), "%i", selected_car_skin[param1]);				
		KvGetString(carbuykv, skin_num, colour, sizeof(colour), "UNKNOWN");
  		Format(skin_str, sizeof(skin_str), "Colour: %s", colour);
				
		KvRewind(carbuykv);		
		
		new String:title_str[32];
		new String:spawn_str[32];
		new String:info_str[32];
		new String:give_away_str[32];
		Format(title_str, sizeof(title_str), "%s (#%i)", car_name[t], index);
		Format(spawn_str, sizeof(spawn_str), "%T", "Spawn_Car", param1);
		Format(info_str, sizeof(info_str), "%T", "Car_Info", param1);
		Format(give_away_str, sizeof(give_away_str), "%T", "Give_Away_Car", param1);
		
		if (selected_car_stowed[param1] == 0)
		{
			new Handle:tempmenu_a = CreateMenu(Menu_NotStowed);

			SetMenuTitle(tempmenu_a, title_str);
			
			AddMenuItem(tempmenu_a, "1", spawn_str, ITEMDRAW_DISABLED);
			AddMenuItem(tempmenu_a, "2", skin_str, ITEMDRAW_DISABLED);
			AddMenuItem(tempmenu_a, "4", info_str);
			AddMenuItem(tempmenu_a, "5", give_away_str, ITEMDRAW_DISABLED);

			DisplayMenu(tempmenu_a, param1, MENU_TIME_FOREVER);
			return;
		}
		else if (selected_car_stowed[param1] == 1)
		{
			new Handle:tempmenu_a = CreateMenu(Menu_Stowed);

			SetMenuTitle(tempmenu_a, title_str);
			
			if (GetConVarInt(g_Cvar_Override))
			{
				if (car_vip[t])
				{
					new AdminId:admin = GetUserAdmin(param1);
					if (admin != INVALID_ADMIN_ID)
					{
						AddMenuItem(tempmenu_a, "1", spawn_str);
					}
					else
					{
						Format(spawn_str, sizeof(spawn_str), "[VIP Required to Spawn]");
						AddMenuItem(tempmenu_a, "1", spawn_str, ITEMDRAW_DISABLED);
					}
				}
				else
				{
					AddMenuItem(tempmenu_a, "1", spawn_str);
				}
			}
			else
			{
				AddMenuItem(tempmenu_a, "1", spawn_str);
			}
			
			AddMenuItem(tempmenu_a, "2", skin_str);
			AddMenuItem(tempmenu_a, "4", info_str);
			AddMenuItem(tempmenu_a, "5", give_away_str);

			DisplayMenu(tempmenu_a, param1, MENU_TIME_FOREVER);
			return;
     	}
	}
}
public Menu_NotStowed(Handle:tempmenu_a, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(tempmenu_a, param2, info, sizeof(info));

		if (StrEqual(info,"1"))
		{
			PrintToChat(param1, "\x04[Car] %T", "Already_Spawned", param1);
			return;
		}
		if (StrEqual(info,"2"))
		{
			PrintToChat(param1, "\x04[Car] %T", "Colour_In_Garage", param1);
			return;
		}
		if (StrEqual(info,"4"))
		{
			new Handle:help_menu = CreateMenu(Menu_CarHelp);

			// This is now an info menu.  It tells about the car's features.
			new t = selected_car_type[param1];
			new String:title_str[32];
			new String:mpg_str[32];
			new String:fuel_str[32];
			new tank = RoundToNearest(car_gas[t]);
			Format(title_str, sizeof(title_str), "%s", car_name[t]);
			Format(mpg_str, sizeof(mpg_str), "%T", "Average_MPG", param1, car_mpg[t]);
			Format(fuel_str, sizeof(fuel_str), "%T", "Maximum_Gas", param1, tank);
		
			SetMenuTitle(help_menu, title_str);
			AddMenuItem(help_menu, "1", mpg_str, ITEMDRAW_DISABLED);
			AddMenuItem(help_menu, "2", fuel_str, ITEMDRAW_DISABLED);

			DisplayMenu(help_menu, param1, MENU_TIME_FOREVER);
			return;
		}
		if (StrEqual(info,"5"))
		{
			PrintToChat(param1, "\x04[Car] %T", "Already_Spawned", param1);
			return;
		}
	}
	return;
}
public Menu_Stowed(Handle:tempmenu_a, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(tempmenu_a, param2, info, sizeof(info));

		if (StrEqual(info,"1"))
		{
			Spawn_a_Car(param1, selected_car[param1]);
		}
		if (StrEqual(info,"2"))
		{
			new t = selected_car_type[param1];
			KvJumpToKey(carbuykv, car_name[t], false);


			decl String:skin_str[48], String:skin_num[4], String:colour[32];

			new i = selected_car_type[param1];

			new Handle:skin_menu = CreateMenu(Menu_CarSkin);

			for ( new ic = 0;  ic < car_skins[i]; ic++ )
			{
				Format(skin_num, sizeof(skin_num), "%i", ic);				
				KvGetString(carbuykv, skin_num, colour, sizeof(colour), "UNKNOWN");
  				Format(skin_str, sizeof(skin_str), "%s", colour);
				AddMenuItem(skin_menu, skin_num, skin_str);
            }
			
			SetMenuTitle(skin_menu, "Colour Menu:");
			KvRewind(carbuykv);
			DisplayMenu(skin_menu, param1, 0);
			return;
		}
		if (StrEqual(info,"4"))
		{
			new Handle:help_menu = CreateMenu(Menu_CarHelp);

			// This is now an info menu.  It tells about the car's features.
			new t = selected_car_type[param1];
			new String:title_str[32];
			new String:mpg_str[32];
			new String:fuel_str[32];
			new tank = RoundToNearest(car_gas[t]);
			Format(title_str, sizeof(title_str), "%s", car_name[t]);
			Format(mpg_str, sizeof(mpg_str), "%T", "Average_MPG", param1, car_mpg[t]);
			Format(fuel_str, sizeof(fuel_str), "%T", "Maximum_Gas", param1, tank);
		
			SetMenuTitle(help_menu, title_str);
			AddMenuItem(help_menu, "1", mpg_str, ITEMDRAW_DISABLED);
			AddMenuItem(help_menu, "2", fuel_str, ITEMDRAW_DISABLED);

			DisplayMenu(help_menu, param1, MENU_TIME_FOREVER);
			return;
		}
		if (StrEqual(info,"5"))
		{
			new t = selected_car_type[param1];
			
			decl String:name[32];
			decl String:title[32];
			decl String:identifier[32];
			new Handle:givemenu = CreateMenu(Menu_Give);
			for (new i = 1; i < GetMaxClients(); i++)
			{
				if (IsClientInGame(i))
				{
					if (Cars[i] < 10)
					{
						GetClientName(i, name, sizeof(name));
						Format(identifier, sizeof(identifier), "%i", i);
						AddMenuItem(givemenu, identifier, name);
					}
				}
			}
			AddMenuItem(givemenu, "DELETE", "Delete this Car");
			Format(title, sizeof(title), "Give your %s to:", car_name[t]);
			SetMenuTitle(givemenu, title);
			DisplayMenu(givemenu, param1, MENU_TIME_FOREVER);
			return;
		}
	}
}
public Action:Stow_Timer(Handle:Timer, any:client)
{
	can_stow[client] = true;
}				
SpawnSeat2(String:model[], skin, client)
{
	new fail = -1;
	if (!IsClientInGame(client))
	{
		return fail;
	}
	// Get the location for the car.
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
			
	new seat = CreateEntityByName("prop_vehicle_driveable");
	if(IsValidEntity(seat))
	{
		Cars_Driver_Prop[seat] = -1;

		new String:Seat_Name[64];
		Format(Seat_Name, sizeof(Seat_Name), "%i_chair", seat);
		new String:skin_str[4];
		Format(skin_str, sizeof(skin_str), "%i", skin);
				
		DispatchKeyValue(seat, "vehiclescript", "scripts/vehicles/chair.txt");
		DispatchKeyValue(seat, "model", model);
		DispatchKeyValue(seat, "targetname", Seat_Name);
		DispatchKeyValue(seat, "EnableGun","0");
		TeleportEntity(seat, SpawnOrigin, SpawnAngles, NULL_VECTOR);
		
		DispatchSpawn(seat);
		ActivateEntity(seat);

		SetEntProp(seat, Prop_Data, "m_nNextThinkTick", -1);	
		SDKHook(seat, SDKHook_Think, OnThink);
//		AcceptEntityInput(seat, "TurnOff");		
		
		ViewEnt[seat] = -1;
		
		car_fuel[seat] = 10.0;
		mpg[seat] = 10;
		cars_type[seat] = 100;

		is_chair[seat] = 2;
		return seat;
	}
	else return fail;
}						
						
						
public Menu_Give(Handle:givemenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		// Make sure selection is valid first.
		if (selected_car[param1] == -1)
		{
			Reset_Car_Selection(param1);
			return;
		}
		if (selected_car_stowed[param1] == 0)
		{
			Reset_Car_Selection(param1);
			return;
		}
		if (selected_car_type[param1] == -1)
		{
			Reset_Car_Selection(param1);
			return;
		}
		
		// Validly selected car.  Let's do the rest.
		new String:info[32];
		GetMenuItem(givemenu, param2, info, sizeof(info));		
		if (StrEqual(info,"DELETE"))
		{
			new Handle:verifymenu = CreateMenu(Menu_Verify);
			AddMenuItem(verifymenu, "NO", "No.");
			AddMenuItem(verifymenu, "DELETE", "Yes.");
			SetMenuTitle(verifymenu, "Are you sure?");
			DisplayMenu(verifymenu, param1, MENU_TIME_FOREVER);
			return;
		}
		else
		{
			new player = StringToInt(info);
			if (player > 0)
			{
				if (IsClientInGame(player))
				{
					if (Cars[player] < 10)
					{
						new String:name[32];
						GetClientName(player, name, sizeof(name));
						new t = selected_car_type[param1];
						new c = Cars[player];
						new index = selected_car[param1];

						Car_Skin[player][c] = 0;
						Car_Type[player][c] = t;
						Car_Gas[player][c] = Car_Gas[param1][index];
								
						Cars[player] += 1;
						DBSave(player);
					
					
						// Now we delete the car we just gave.
						
						Car_Type[param1][index] = 0;
						Car_Skin[param1][index] = 0;
						Car_Gas[param1][index] = 0.0;
			
						Cars[param1] -= 1;
						DBSave(param1);
						
						LogMessage("[Car] %N (%s) gave their %s (#%i) to %N (%s).", param1, authid[param1], car_name[t], index, player, authid[player]);
					
						PrintToChat(player, "\x04[Car] %T", "Given_Car", player, car_name[t]);
						PrintToChat(param1, "\x04[Car] %T", "Gave_Car", param1, name);
					
						return;
					}
				}
			}
		}
	}
}
public Menu_Verify(Handle:verifymenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(verifymenu, param2, info, sizeof(info));
		if (StrEqual(info,"DELETE"))
		{
			if (selected_car[param1] == -1)
			{
				Reset_Car_Selection(param1);
				return;
			}
			if (selected_car_stowed[param1] == 0)
			{
				Reset_Car_Selection(param1);
				return;
			}
			new i = selected_car_type[param1];
			if (i == -1)
			{
				Reset_Car_Selection(param1);
				return;
			}

			new index = selected_car[param1];
			
			Car_Type[param1][index] = 0;
			Car_Skin[param1][index] = 0;
			Car_Gas[param1][index] = 0.0;	
	
			Cars[param1] -= 1;
			
			LogMessage("[Car] %N (%s) deleted their %s (#%i) from their garage.", param1, authid[param1], car_name[i], index);
			PrintToChat(param1, "\x04[Car] %T", "Deleted", param1, car_name[i]);
			DBSave(param1);
			return;
		}
	}
}
public Menu_CarInfo(Handle:info_menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		Reset_Car_Selection(param1);
		return;
	}
}
public Menu_CarSkin(Handle:skin_menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(skin_menu, param2, info, sizeof(info));

		new index = selected_car[param1];
		new i = StringToInt(info);

		Car_Skin[param1][index] = i;
		
		Reset_Car_Selection(param1);
		return;
	}
}
public Menu_CarHelp(Handle:help_menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		Reset_Car_Selection(param1);
		return;
	}
}



//  ########
//  BUY MENU
//  ########



Handle:BuildBuyMenu()
{
	if (car_quantity == 0)
	{
		PrintToServer("[Car] No Cars were detected.");
		return g_BuyMenu;
	}
	
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Buy)

	decl String:cat_str[30], String:title[30];
	for (new i = 1; i <= car_quantity; i++)
	{
		if (car_vip[i] == 0)
		{
			Format(title, sizeof(title), "%s ($%i)", car_name[i], car_price[i]);
			Format(cat_str, sizeof(cat_str), "%i", i);
			AddMenuItem(menu,cat_str,title);
		}	
	}
	SetMenuTitle(menu, "Choose a Car");
	return menu;
}
Handle:BuildVIPBuyMenu()
{
	if (car_quantity_vip == 0)
	{
		PrintToServer("[Car] No VIP Cars were detected.");
		return g_VIPBuyMenu;
	}
	
	/* Create the menu Handle */
	new Handle:vipmenu = CreateMenu(Menu_Buy)

	decl String:cat_str[30], String:title[30];
	for (new i = 1; i <= car_quantity; i++)
	{
		if (car_vip[i] == 1)
		{
			Format(title, sizeof(title), "%s ($%i)", car_name[i], car_price[i]);
			Format(cat_str, sizeof(cat_str), "%i", i);
			AddMenuItem(vipmenu,cat_str,title);
		}	
	}
	SetMenuTitle(vipmenu, "Choose a VIP Car");
	return vipmenu;
}
public Menu_Buy(Handle:menu, MenuAction:action, param1, param2)
{
	// user has selected to buy something

	if (action == MenuAction_Select)
	{
		new String:info[30];

		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info))

		if (!found)
			return;
			
		new t = StringToInt(info);
		
		new cost2 = car_price[t] - 1;


		// Why is it like this?  I have no idea.
		new money = GetEntData(param1, MoneyOffset);
		new bank = GetClientBank(param1);
		
		Cars[param1] = 0;
		if (Car_Type[param1][0] > 0)
		{
			Cars[param1] += 1;
		}
		if (Car_Type[param1][1] > 0)
		{
			Cars[param1] += 1;
		}
		if (Car_Type[param1][2] > 0)
		{
			Cars[param1] += 1;
		}
		if (Car_Type[param1][3] > 0)
		{
			Cars[param1] += 1;
		}
		if (Car_Type[param1][4] > 0)
		{
			Cars[param1] += 1;
		}
		if (Car_Type[param1][5] > 0)
		{
			Cars[param1] += 1;
		}
		if (Car_Type[param1][6] > 0)
		{
			Cars[param1] += 1;
		}
		if (Car_Type[param1][7] > 0)
		{
			Cars[param1] += 1;
		}
		if (Car_Type[param1][8] > 0)
		{
			Cars[param1] += 1;
		}
		if (Car_Type[param1][9] > 0)
		{
			Cars[param1] += 1;
		}


		if(money > cost2)
		{			
			if(Cars[param1] < 10)
			{
				SetEntData(param1, MoneyOffset, money - car_price[t], 4, true);
				SetClientMoney(param1, money - car_price[t]);
				PrintToChat(param1, "\x04[Car] %T", "Bought_C", param1, car_name[t]);
				new index = 0;
				for (new i = 0; i < 10; i++)
				{
					if (Car_Type[param1][i] < 1)
					{
						index = i;
						break;
					}
				}
				Car_Type[param1][index] = t;
				Car_Skin[param1][index] = 0;
				Car_Gas[param1][index] = car_gas[t];
				Car_Entity[param1][index] = -1;

				LogMessage("[Car] %N (%s) bought a %s (#%i) with cash.", param1, authid[param1], car_name[t], index); 
				Cars[param1] += 1;
				DBSave(param1);
				return;
			}
			else PrintToChat(param1, "\x04[Car] %T", "Own_10", param1);
			return;
		}
		else if(bank > cost2)
		{
			if(Cars[param1] < 10)
			{
				bank -= car_price[t];
				SetClientBank(param1, bank);
				PrintToChat(param1, "\x04[Car] %T", "Bought_B", param1, car_name[t]);
				PrintToChat(param1, "\x04[Car] %T", "Bank", param1, bank);

				new index = 0;
				for (new i = 0; i < 10; i++)
				{
					if (Car_Type[param1][i] < 1)
					{
						index = i;
						break;
					}
				}
				Car_Type[param1][index] = t;
				Car_Skin[param1][index] = 0;
				Car_Gas[param1][index] = car_gas[t];
				Car_Entity[param1][index] = -1;
				
				LogMessage("[Car] %N (%s) bought a %s (#%i) with money from their bank account.", param1, authid[param1], car_name[t], index); 
				Cars[param1] += 1;
				DBSave(param1);
				return;
			}
			else PrintToChat(param1, "\x04[Car] %T", "Own_10", param1);
			return;
		}
		else PrintToChat(param1, "\x04[Car] %T", "Expensive", param1, car_price[t]);
	}
}
Handle:BuildGasMenu()
{
	/* Create the menu Handle */
	new Handle:gasmenu = CreateMenu(Menu_Gas);
	new Float:price;
	price = GetConVarFloat(g_Cvar_Gas);
	
	new String:gas_str[32];
	Format(gas_str, sizeof(gas_str), "Gas Costs $%f", price);

	AddMenuItem(gasmenu, "-1", gas_str, ITEMDRAW_DISABLED);
	AddMenuItem(gasmenu, "1", "Buy 1 Gallon");
	AddMenuItem(gasmenu, "5", "Buy 5 Gallons");
	AddMenuItem(gasmenu, "10", "Buy 10 Gallons");
	SetMenuTitle(gasmenu, "Gas Pump:");
	return gasmenu;
}
public Menu_Gas(Handle:menu, MenuAction:action, param1, param2)
{
	// user has selected to buy some gas
	if (action == MenuAction_Select)
	{
		if (IsPlayerAlive(param1))
		{
			if (AtGas[param1] == false)
			{
				return;
			}
			new car = GetClientAimTarget(param1, false);
			if(car != -1)
			{
				new String:ClassName[64];
				GetEdictClassname(car, ClassName, 255);
				if (StrEqual(ClassName, "prop_vehicle_driveable", false))
				{				
					new String:info[32];
					GetMenuItem(menu, param2, info, sizeof(info));
					if(StrEqual(info,"1"))
					{
						new money = GetEntData(param1, MoneyOffset);
						new price = GetConVarInt(g_Cvar_Gas);
					
						if (money >= price)
						{
							SetEntData(param1, MoneyOffset, money - price, 4, true);
							SetClientMoney(param1, money - price);
							AcceptEntityInput(car, "TurnOff");
							CarOn[car] = false;
							g_GasTimer = CreateTimer(4.0, Gas_Time, param1);
							EmitSoundToAll("ambient/gas/steam_loop1.wav", car, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
							gas_into_this_car[param1] = car;
							gas_remaining[car] = 1;
						}
						else PrintToChat(param1, "\x04[Car] %T", "Not_Enough_Minerals", param1, price);
					}
					if(StrEqual(info,"5"))
					{
						new money = GetEntData(param1, MoneyOffset);
						new price = GetConVarInt(g_Cvar_Gas);
						price *= 5;
					
						if (money >= price)
						{
							price /= 5;
							SetEntData(param1, MoneyOffset, money - price, 4, true);
							SetClientMoney(param1, money - price);
							AcceptEntityInput(car, "TurnOff");
							CarOn[car] = false;
							g_GasTimer = CreateTimer(4.0, Gas_Time, param1);
							EmitSoundToAll("ambient/gas/steam_loop1.wav", car, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
							gas_into_this_car[param1] = car;
							gas_remaining[car] = 5;
						}
						else PrintToChat(param1, "\x04[Car] %T", "Not_Enough_Minerals", param1, price);
					}
					if(StrEqual(info,"10"))
					{
						new money = GetEntData(param1, MoneyOffset);
						new price = GetConVarInt(g_Cvar_Gas);
						price *= 10;
					
						if (money >= price)
						{
							price /= 10;
							SetEntData(param1, MoneyOffset, money - price, 4, true);
							SetClientMoney(param1, money - price);
							AcceptEntityInput(car, "TurnOff");
							CarOn[car] = false;
							g_GasTimer = CreateTimer(4.0, Gas_Time, param1);
							EmitSoundToAll("ambient/gas/steam_loop1.wav", car, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
							gas_into_this_car[param1] = car;
							gas_remaining[car] = 10;
						}
						else PrintToChat(param1, "\x04[Car] %T", "Not_Enough_Minerals", param1, price);
					}
				}
				else PrintToChat(param1, "\x04[Car] %T", "Look_At_Car", param1);
				return;
			}	
		}
		else PrintToChat(param1, "\x04[Car] %T", "Youre_Dead", param1);
		return;		
	}
}
public Action:Gas_Time(Handle:timer, any:client)
{
	if (IsPlayerAlive(client))
	{
		new car = gas_into_this_car[client];
		if (AtGas[client] == true)
		{
			if(car != -1)
			{
				car_fuel[car] += 1.0;
				gas_remaining[car] -= 1;
				new t = cars_type[car];
				if (car_fuel[car] >= car_gas[t])
				{
					gas_remaining[car] = 0;
					car_fuel[car] = car_gas[t];
				}
				if (gas_remaining[car] > 0)
				{
					new price = GetConVarInt(g_Cvar_Gas);
					new money = GetEntData(client, MoneyOffset);
					SetEntData(client, MoneyOffset, money - price, 4, true);
					SetClientMoney(client, money - price);
					AcceptEntityInput(car, "TurnOff");
					CarOn[car] = false;
					g_GasTimer = CreateTimer(4.0, Gas_Time, client);
				}
				else
				{
					PrintToChat(client, "\x04[Car] %T", "Fueling_Completed", client);
					StopSound(car, SNDCHAN_AUTO, "ambient/gas/steam_loop1.wav");
				}
			}
		}
		else
		{
			StopSound(car, SNDCHAN_AUTO, "ambient/gas/steam_loop1.wav");
		}
	}
}

//  #########
//  INFO MENU
//  #########



Handle:BuildInfoMenu()
{
	new Handle:info = CreateMenu(Menu_Info);
	AddMenuItem(info, "1", "  Type !car_menu to open the menu.", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  Select Your Cars to see your cars.", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  Select Buy Cars to buy new cars.", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  Type !car_stow to put away your car.", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  Buy VIP to get access to VIP cars.", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  www.lady-natalya.info", ITEMDRAW_DISABLED);
	SetMenuTitle(info, "<==>  Plugin by Natalya[AF]  <==>");
	return info;
}
Handle:BuildVIPInfoMenu()
{
	new Handle:info = CreateMenu(Menu_Info);
	AddMenuItem(info, "1", "  Type !car_menu to open the menu.", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  Select Your Cars to see your cars.", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  Select Buy Cars to buy new cars.", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  Type !car_stow to put away your car.", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  Thanks for your VIP donation!!", ITEMDRAW_DISABLED);
	AddMenuItem(info, "1", "  www.lady-natalya.info", ITEMDRAW_DISABLED);
	SetMenuTitle(info, "<==>  Plugin by Natalya[AF]  <==>");
	return info;
}
public Menu_Info(Handle:info, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		return;
	}
}



// #################
// COMMAND FUNCTIONS
// #################



public Action:Command_DBSave(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		for (new player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				DBSave(player);
			}
		}
	}
	if (client == 0)
	{
		PrintToServer("[Car] Server Forced DB Save");
	}
	else
	{
		PrintToChat(client, "[Car] %N Forced DB Save", client);
	}
	return Plugin_Handled;
}
public Action:Car_Menu(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			if (!IsClientHandcuffed(client))
			{
				new bank = GetClientBank(client);
				new AdminId:admin = GetUserAdmin(client);
				if (admin != INVALID_ADMIN_ID)
				{
					new Handle:car = CreateMenu(Menu_Car);
					new String:garage_str[32];
					Format(garage_str, sizeof(garage_str), "%T", "Garage", client);
					new String:buy_str[64];
					Format(buy_str, sizeof(buy_str), "%T", "Buy_Cars", client);
					new String:vip_str[64];
					Format(vip_str, sizeof(vip_str), "%T", "VIP_Cars", client);
					new String:help_str[32];
					Format(help_str, sizeof(help_str), "%T", "Help", client);
					new String:title_str[32];
					Format(title_str, sizeof(title_str), "%T", "Car_Menu", client);
					
					AddMenuItem(car, "g_InvMenu", garage_str);
					AddMenuItem(car, "g_BuyMenu", buy_str);
					if (car_quantity_vip > 0)
					{
						AddMenuItem(car, "g_VIPBuyMenu", vip_str);
					}
					else AddMenuItem(car, "g_VIPBuyMenu", vip_str, ITEMDRAW_DISABLED);
					AddMenuItem(car, "g_VIPInfoMenu", help_str);

					SetMenuTitle(car, title_str);

					DisplayMenu(car, client, MENU_TIME_FOREVER);
					PrintToChat(client, "\x04[Car] %T", "Bank", client, bank);
				}
				else
				{
					new Handle:car = CreateMenu(Menu_Car);
					new String:garage_str[32];
					Format(garage_str, sizeof(garage_str), "%T", "Garage", client);
					new String:buy_str[64];
					Format(buy_str, sizeof(buy_str), "%T", "Buy_Cars", client);
					new String:vip_str[64];
					Format(vip_str, sizeof(vip_str), "%T", "VIP_Cars", client);
					new String:help_str[32];
					Format(help_str, sizeof(help_str), "%T", "Help", client);
					new String:title_str[32];
					Format(title_str, sizeof(title_str), "%T", "Car_Menu", client);
					
					AddMenuItem(car, "g_InvMenu", garage_str);
					AddMenuItem(car, "g_BuyMenu", buy_str);
					if (car_quantity_vip > 0)
					{
						AddMenuItem(car, "g_VIPBuyMenu", vip_str, ITEMDRAW_DISABLED);
					}
					AddMenuItem(car, "g_VIPInfoMenu", help_str);

					SetMenuTitle(car, title_str);				

					DisplayMenu(car, client, MENU_TIME_FOREVER);
					PrintToChat(client, "\x04[Car] %T", "Bank", client, bank);
				}
			}
			else PrintToChat(client, "\x04[Car] %T", "Handcuffed", client);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x04[Car] %T", "Youre_Dead", client);
		return Plugin_Handled;
	}
	else PrintToChat(client, "\x04[Car] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Car_Menu_Super(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			if (!IsClientHandcuffed(client))
			{
				// Declare Stuff
				new String:url[255];
				new String:ip[32];
				
				// Put User ID into URL
				new userid = GetClientUserId(client);			
				Format(url, sizeof(url), "http://www.lady-natalya.info/rp/car_garage.php?id=%i", userid);
				
				// Display URL
				ShowMOTDPanel(client, "Car Menu", url, MOTDPANEL_TYPE_URL);
				
				// Save Client IP so that it can be used later to verify client authenticity.
				GetClientIP(client, ip, sizeof(ip), true);
				Format(player_ip[client], sizeof(player_ip[]), "%s", ip);
			}
		}
	}
	return Plugin_Handled;
}
public Action:IP_Check(args)
{
	// If we got here now we check that the proper arguments were supplied.
	if (args <= 1)
	{
		ReplyToCommand(0, "-3");
		return Plugin_Handled;
	}
	
	// Okay, so far, so good...
	new String:arg1[32], String:arg2[32];
	new userid = 0;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	userid = StringToInt(arg1);
	new player = GetClientOfUserId(userid);
	if (player == 0)
	{
		ReplyToCommand(0, "-2");
		return Plugin_Handled;
	}	
	
	// arg2 is the IP Address
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new compare = strcmp(arg2, player_ip[player], false); 
	if (compare == 0)
	{
		// Success!! The IPs and the UserIDs matched!!
		ReplyToCommand(0, "1");
		return Plugin_Handled;
	}
	else ReplyToCommand(0, "0");
	return Plugin_Handled;
}
public Action:Steam_Check(args)
{
	if (args <= 0)
	{
		ReplyToCommand(0, "-1");
		return Plugin_Handled;
	}
	new String:arg1[32], String:steamid[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	new userid = StringToInt(arg1);
	
	new player = GetClientOfUserId(userid);
	GetClientAuthId(player, AuthId_Engine, steamid, sizeof(steamid));
	
	ReplyToCommand(0, steamid);
	return Plugin_Handled;
}
public Action:Car_Check(args)
{
	if (args <= 0)
	{
		ReplyToCommand(0, "-1");
		return Plugin_Handled;
	}
	new String:arg1[32], String:arg2[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	new userid = StringToInt(arg1);	
	new player = GetClientOfUserId(userid);

	GetCmdArg(2, arg2, sizeof(arg2));
	new car = StringToInt(arg2);
	
	new stowed = -1;

	if (Car_Entity[player][car] > 0)
	{
		stowed = 0;
	}
	else stowed = 1;

	new String:stowed_str[4];
	Format(stowed_str, sizeof(stowed_str), "%i", stowed);
	
	ReplyToCommand(0, stowed_str);
	return Plugin_Handled;
}
public Action:Cars_Name(args)
{
	if (args <= 0)
	{
		ReplyToCommand(0, "-1");
		return Plugin_Handled;
	}
	new String:arg1[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	new t = StringToInt(arg1);	
	if (t <= 128)
	{
		ReplyToCommand(0, car_name[t]);
	}
	else ReplyToCommand(0, "ERROR");
	return Plugin_Handled;
}
public Action:Cars_Skin(args)
{
	if (args <= 0)
	{
		ReplyToCommand(0, "-1");
		return Plugin_Handled;
	}
	new String:arg1[32], String:arg2[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	new t = StringToInt(arg1);
	GetCmdArg(2, arg2, sizeof(arg2));
	new s = StringToInt(arg2);		
		
	KvJumpToKey(carbuykv, car_name[t], false);
	decl String:skin_num[4], String:colour[32];
	Format(skin_num, sizeof(skin_num), "%i", s);				
	KvGetString(carbuykv, skin_num, colour, sizeof(colour), "UNKNOWN");		
	KvRewind(carbuykv);	
	
	ReplyToCommand(0, colour);
	return Plugin_Handled;
}
public Action:Cars_Skin2(args)
{
	if (args <= 1)
	{
		ReplyToCommand(0, "-1");
		return Plugin_Handled;
	}
	new String:arg1[32], String:arg2[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	new car = StringToInt(arg1);
	GetCmdArg(2, arg2, sizeof(arg2));
	new userid = StringToInt(arg2);	
	new player = GetClientOfUserId(userid);	
	
	new s = Car_Skin[player][car];
	new String:skin_str[4];
	Format(skin_str, sizeof(skin_str), "%i", s);
	
	ReplyToCommand(0, skin_str);
	return Plugin_Handled;
}
public Action:Cars_Skin3(args)
{
	if (args <= 0)
	{
		ReplyToCommand(0, "0");
		return Plugin_Handled;
	}
	new String:arg1[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	new t = StringToInt(arg1);
	
	ReplyToCommand(0, "%i", car_skins[t]);
	return Plugin_Handled;
}
public Action:Cars_Skin4(args)
{
	if (args <= 2)
	{
		ReplyToCommand(0, "-1");
		return Plugin_Handled;
	}
	new String:arg1[32], String:arg2[32], String:arg3[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	new car = StringToInt(arg1);
	GetCmdArg(2, arg2, sizeof(arg2));
	new userid = StringToInt(arg2);	
	new player = GetClientOfUserId(userid);
	GetCmdArg(3, arg3, sizeof(arg3));
	new s = StringToInt(arg3);

	Car_Skin[player][car] = s;
	
	return Plugin_Handled;
}
public Action:Car_Spawn(args)
{
	if (args <= 1)
	{
		ReplyToCommand(0, "-1");
		return Plugin_Handled;
	}
	new String:arg1[32], String:arg2[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	new car = StringToInt(arg1);
	GetCmdArg(2, arg2, sizeof(arg2));
	new userid = StringToInt(arg2);	
	new player = GetClientOfUserId(userid);
	
	Spawn_a_Car(player, car);
	
	return Plugin_Handled;
}
public Action:Car_On(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if(car != -1)
			{
				if (GetConVarInt(g_Cvar_GasUse))
				{
					if (car_fuel[car] > 0.0)
					{
						AcceptEntityInput(car, "TurnOn");
						ActivateEntity(car);
						AcceptEntityInput(car, "TurnOn");
						CarOn[car] = true;
						PrintToChat(client, "\x04[Car] %T", "Car_On", client);
						return Plugin_Handled;
					}
					else PrintToChat(client, "\x04[Car] %T", "No_Gas", client);
					return Plugin_Handled;
				}
				else
				{
					AcceptEntityInput(car, "TurnOn");
					ActivateEntity(car);
					AcceptEntityInput(car, "TurnOn");
					CarOn[car] = true;
					PrintToChat(client, "\x04[Car] %T", "Car_On", client);
					return Plugin_Handled;
				}
			}
			else PrintToChat(client, "\x04[Car] %T", "Get_Inside", client);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x04[Car] %T", "Youre_Dead", client);
		return Plugin_Handled;		
	}
	else PrintToChat(client, "\x04[Car] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Car_Off(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if(car != -1)
			{
				AcceptEntityInput(car, "TurnOff");
				CarOn[car] = false;
				PrintToChat(client, "\x04[Car] %T", "Car_Off", client);

				new car_index = g_CarIndex[car];
				new max = g_CarLightQuantity[car_index];
				
				if (max > 0)
				{
					decl light;
					light = g_CarLights[car_index][2];
					AcceptEntityInput(light, "HideSprite");
					light = g_CarLights[car_index][3];
					AcceptEntityInput(light, "HideSprite");
					
	/*				AcceptEntityInput(g_CarLights[car_index][6], "LightOff");
					AcceptEntityInput(g_CarLights[car_index][7], "LightOff");	*/
				}
			}
			else PrintToChat(client, "\x04[Car] %T", "Get_Inside", client);
			return Plugin_Handled;			
		}
		else PrintToChat(client, "\x04[Car] %T", "Youre_Dead", client);
		return Plugin_Handled;		
	}
	else PrintToChat(client, "\x04[Car] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Car_Register(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if(car != -1)
			{
				SetEntProp(car, Prop_Data, "m_nNextThinkTick", -1);	
				SDKHook(car, SDKHook_Think, OnThink);
				car_fuel[car] = 10.00;
				mpg[car] = 20;

				new ViewEntIndex = CreateEntityByName("env_fire");
				if (ViewEntIndex == -1)
				{
					PrintToServer("[Car DEBUG] Could not create vehicle view entity");
					return;
				}
				new String:The_Name[54];
				GetTargetName(car, The_Name, sizeof(The_Name));
		
				DispatchSpawn(ViewEntIndex);
				ActivateEntity(ViewEntIndex);
		
				SetVariantString(The_Name);
				AcceptEntityInput(ViewEntIndex, "SetParent");
		
				SetVariantString("vehicle_driver_eyes");
				AcceptEntityInput(ViewEntIndex, "SetParentAttachment");
				
				ViewEnt[car] = ViewEntIndex;
				SetEntityHealth(client, 100);
			}
		}
	}
}
public Action:Car_Siren(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
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
				else PrintToChat(client, "\x04[Car] %T", "No_Siren", client);
				return Plugin_Handled;
			}
			else PrintToChat(client, "\x04[Car] %T", "Get_Inside", client);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x04[Car] %T", "Youre_Dead", client);
		return Plugin_Handled;		
	}
	else PrintToChat(client, "\x04[Car] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Car_Info(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if(car != -1)
			{
				new String:owner[32];
				// Check if owner is ingame 
				if(car_owner[car] != -1 )
				{
					GetClientName(car_owner[car], owner, sizeof(owner));
				}
				PrintHintText(client, "Fuel: %f Gallons\nOwner: %s", car_fuel[car], owner);
				return Plugin_Handled;
			}
			else PrintToChat(client, "\x04[Car] %T", "Get_Inside", client);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x04[Car] %T", "Youre_Dead", client);
		return Plugin_Handled;		
	}
	else PrintToChat(client, "\x04[Car] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Car_Seat(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if(car != -1)
			{
				if (is_chair[car] == 1)
				{
					new seat = car;
					car = chairs_car[seat];
					
					new done = 0;
					new Passenger = -1;
					for ( new ic = 1;  ic < cars_seats[car] + 1; ic++ )
					{
						Passenger = GetEntPropEnt(cars_seat_entities[car][ic], Prop_Send, "m_hPlayer");
						if (Passenger == -1)
						{
							new chair = cars_seat_entities[car][ic];
							if (IsValidEntity(chair))
							{
								LeaveVehicle(client);
								new t = cars_type[car];
								SetVariantString("");
								AcceptEntityInput(chair, "SetParent", chair, chair, 0);									
								AcceptEntityInput(chair, "use", client);
										
								new String:car_name2[128];
								GetTargetName(car,car_name2,sizeof(car_name2));
                    
								SetVariantString(car_name2);
								AcceptEntityInput(chair, "SetParent", chair, chair, 0);
								SetVariantString(car_passenger_attachment[t][ic]);
								AcceptEntityInput(chair, "SetParentAttachment", chair, chair, 0);								
								done = 1;
								break;
							}
						}
					}
					new driver = GetEntPropEnt(car, Prop_Send, "m_hPlayer");
					if ((done == 0) && (driver == -1))
					{
						LeaveVehicle(client);
						AcceptEntityInput(car, "use", client);
						done = 1;
					}					
				}
				else if (cars_seats[car] > 0)
				{
					new done = 0;
					new Passenger = -1;
					for ( new ic = 1;  ic < cars_seats[car] + 1; ic++ )
					{
						if (IsValidEntity(cars_seat_entities[car][ic]))
						{
							Passenger = GetEntPropEnt(cars_seat_entities[car][ic], Prop_Send, "m_hPlayer");
							if (Passenger == -1)
							{
								new chair = cars_seat_entities[car][ic];
								if (IsValidEntity(chair))
								{
									LeaveVehicle(client);
									new t = cars_type[car];
									SetVariantString("");
									AcceptEntityInput(chair, "SetParent", chair, chair, 0);									
									AcceptEntityInput(chair, "use", client);
										
									new String:car_name2[128];
									GetTargetName(car,car_name2,sizeof(car_name2));
						
									SetVariantString(car_name2);
									AcceptEntityInput(chair, "SetParent", chair, chair, 0);
									SetVariantString(car_passenger_attachment[t][ic]);
									AcceptEntityInput(chair, "SetParentAttachment", chair, chair, 0);								
									done = 1;
									break;
								}
							}
						}
					}
					new driver = GetEntPropEnt(car, Prop_Send, "m_hPlayer");
					if ((done == 0) && (driver == -1))
					{
						AcceptEntityInput(car, "use", client);
						done = 1;
					}
				}
			}
			else PrintToChat(client, "\x04[Car] %T", "Get_Inside", client);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x04[Car] %T", "Youre_Dead", client);
		return Plugin_Handled;		
	}
	else PrintToChat(client, "\x04[Car] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Car_View(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if(car != -1)
			{
				ViewToggle(client);
			}
			else PrintToChat(client, "\x04[Car] %T", "Get_Inside", client);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x04[Car] %T", "Youre_Dead", client);
		return Plugin_Handled;		
	}
	else PrintToChat(client, "\x04[Car] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Car_Kill(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if(car != -1)
			{
/*				new hat = GetClientHatEntity(client);
				new IsThereAHat = 0;
				if (IsValidEntity(hat))
				{
					AcceptEntityInput(hat, "ClearParent", hat, hat, 0);
					IsThereAHat = 1;
				} */
				LeaveVehicle(client);
/*				if (IsThereAHat == 1)
				{
					new type = GetClientHat(client);
					SetHatEntityToParent(hat, client, type);
				} */
				SetCarOwnership(client, car, 0);
				AcceptEntityInput(car,"Kill");
				cars_index[car] = -1;
				CarSiren[car] = false;
			}
		}
	}
	return Plugin_Handled;
}
public Action:Car_Stow(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if(car != -1)
			{
				if (is_chair[car] >= 1)
				{
					return Plugin_Handled;
				}
				new String:car_ent_name[128];
				GetTargetName(car,car_ent_name,sizeof(car_ent_name));

				GetClientAuthId(client, AuthId_Engine, authid[client], sizeof(authid[]));

				if (((StrContains(car_ent_name, authid[client], false)) != -1) || (car_owner[car] == client))
				{
					// Client spawned this car.
/*					new driverhat = GetClientHatEntity(client);
					new IsThereAHat = 0;
					if (IsValidEntity(driverhat))
					{
						AcceptEntityInput(driverhat, "ClearParent", driverhat, driverhat, 0);
						IsThereAHat = 1;
					} */
					LeaveVehicle(client);
/*					if (IsThereAHat == 1)
					{
						new type = GetClientHat(client);
						SetHatEntityToParent(driverhat, client, type);
					} */
					
					if (cars_seats[car] > 0)
					{
						new Passenger = -1;
						for ( new ic = 1;  ic < cars_seats[car] + 1; ic++ )
						{
							Passenger = GetEntPropEnt(cars_seat_entities[car][ic], Prop_Send, "m_hPlayer");
							if (Passenger > 0)
							{
/*								new hat = GetClientHatEntity(Passenger);
								new IsThereAHatB = 0;
								if (IsValidEntity(hat))
								{
									AcceptEntityInput(hat, "ClearParent", hat, hat, 0);
									IsThereAHatB = 1;
								} */
								LeaveVehicle(Passenger);
/*								if (IsThereAHatB == 1)
								{
									new type = GetClientHat(Passenger);
									SetHatEntityToParent(hat, Passenger, type);
								} */
							}
						}			
					}											
					new index = -1;
					for (new c = 0; c < 10; c++)
					{
						if (car == Car_Entity[client][c])
						{
							index = c;
							break;
						}
					}
					if (index > -1)
					{
						Car_Entity[client][index] = -1;
					}
					else LogError("[Car Error] Car_Stow -- Car index not found. Index: %i Car_Entity: %i Player: %N", index, Car_Entity[client][index], client);
					Car_Gas[client][index] = car_fuel[car];
					new t = Car_Type[client][index];
					CarSiren[car] = false;
					SetCarOwnership(client, car, 0);
					CarOn[car] = false;
					AcceptEntityInput(car,"Kill");
					cars_index[car] = -1;
					if (cars_spawned[client] > 0)
					{
						cars_spawned[client] -= 1;
					}

					PrintToChat(client, "\x04[Car] %T", "Stowed", client, car_name[t]);
					PrintToServer("[Car] %s #%i was stowed by %N (%s).", car_name[t], car, client, authid[client]);
					return Plugin_Handled;
				}
				else PrintToChat(client, "\x04[Car] %T", "Not_Yours", client);
				return Plugin_Handled;
			}
			else PrintToChat(client, "\x04[Car] %T", "Get_Inside", client);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x04[Car] %T", "Youre_Dead", client);
		return Plugin_Handled;
	}
	else PrintToChat(client, "\x04[Car] %T", "Disabled", client);
	return Plugin_Handled;
}
public Action:Car_Stow_R(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (IsPlayerAlive(client))
		{
			if (!can_stow[client])
			{
				PrintToChat(client, "\x04[Car] You must wait before you can stow your car.  Try again later.");
				return Plugin_Handled;
			}
			new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if(car != -1)
			{
				if (is_chair[car] >= 1)
				{
					return Plugin_Handled;
				}
				new String:car_ent_name[128];
				GetTargetName(car,car_ent_name,sizeof(car_ent_name));

				GetClientAuthId(client, AuthId_Engine, authid[client], sizeof(authid[]));

				if (((StrContains(car_ent_name, authid[client], false)) != -1) || (car_owner[car] == client))
				{
					// Client spawned this car.
/*					new driverhat = GetClientHatEntity(client);
					new IsThereAHat = 0;
					if (IsValidEntity(driverhat))
					{
						AcceptEntityInput(driverhat, "ClearParent", driverhat, driverhat, 0);
						IsThereAHat = 1;
					} */
					LeaveVehicle(client);
/*					if (IsThereAHat == 1)
					{
						new type = GetClientHat(client);
						SetHatEntityToParent(driverhat, client, type);
					} */
				
					if (cars_seats[car] > 0)
					{
						new Passenger = -1;
						for ( new ic = 1;  ic < cars_seats[car] + 1; ic++ )
						{
							Passenger = GetEntPropEnt(cars_seat_entities[car][ic], Prop_Send, "m_hPlayer");
							if (Passenger > 0)
							{
/*								new hat = GetClientHatEntity(Passenger);
								new IsThereAHatB = 0;
								if (IsValidEntity(hat))
								{
									AcceptEntityInput(hat, "ClearParent", hat, hat, 0);
									IsThereAHatB = 1;
								} */
								LeaveVehicle(Passenger);
/*								if (IsThereAHatB == 1)
								{
									new type = GetClientHat(Passenger);
									SetHatEntityToParent(hat, Passenger, type);
								} */
							}
						}			
					}											
					new index = cars_index[car];
					if (index > -1)
					{
						Car_Entity[client][index] = -1;
					}
					else LogError("[Car Error] Car_Stow_R -- Car index not found. Index: %i Car_Entity: %i Player: %N", index, Car_Entity[client][index], client);
					Car_Gas[client][index] = car_fuel[car];
					new t = Car_Type[client][index];
					
					SetCarOwnership(client, car, 0);
					CarOn[car] = false;
					AcceptEntityInput(car,"Kill");
					cars_index[car] = -1;
					CarSiren[car] = false;
					PrintToChat(client, "\x04[Car] %T", "Stowed", client, car_name[t]);
					PrintToServer("[Car] %s #%i was stowed by %N (%s).", car_name[t], car, client, authid[client]);
					cars_spawned[client] -= 1;
					can_stow[client] = false;
					CreateTimer(300.0, Stow_Timer, client);
					return Plugin_Handled;
				}
				else PrintToChat(client, "\x04[Car] %T", "Not_Yours", client);
				return Plugin_Handled;
			}
			else PrintToChat(client, "\x04[Car] %T", "Get_Inside", client);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x04[Car] %T", "Youre_Dead", client);
		return Plugin_Handled;
	}
	else PrintToChat(client, "\x04[Car] %T", "Disabled", client);
	return Plugin_Handled;
}
public OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	if (GetConVarInt(g_Cvar_GasUse))
	{
		if (0 < activator <= MaxClients)
		{
			if(caller == -1)
				return;
			if(!IsPlayerAlive(activator))
				return;
			if(!IsClientInGame(activator))
				return;
			
			new String:classname[64];
			new String:targetname[64];
		
			GetEdictClassname(caller,classname,sizeof(classname));
			if(StrEqual(classname,"trigger_multiple"))
			{
				GetTargetName(caller,targetname,sizeof(targetname));
				if(StrEqual(targetname,"gas"))
				{
					AtGas[activator] = true;
					DisplayMenu(g_GasMenu, activator, MENU_TIME_FOREVER);
				}
			}
		}
	}
	return;
}
public OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	if (GetConVarInt(g_Cvar_GasUse))
	{
		if (0 < activator <= MaxClients)
		{
			if(caller == -1)
				return;
			if(!IsClientInGame(activator))
				return;
			if(!IsPlayerAlive(activator))
				return;

			new String:classname[64];
			new String:targetname[64];
			
			GetEdictClassname(caller,classname,sizeof(classname));
			if(StrEqual(classname,"trigger_multiple"))
			{
				GetTargetName(caller,targetname,sizeof(targetname));
				if(StrEqual(targetname,"gas"))
				{
					AtGas[activator] = false;
				}
			}
		}
	}
	return;
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
	else drivers_car[client] = -1;
	CarHorn[client] = false;
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
				LeaveVehicle(victim);
				FakeClientCommand(victim, "kill");
			}
			else
			{
				SetEntityHealth(victim, plyr_hp);
			}
			if ((cars_seats[car] > 0) && (is_chair[car] == 0))
			{
				new Passenger = -1;
				for ( new ic = 1;  ic < cars_seats[car] + 1; ic++ )
				{
					if (IsValidEdict(cars_seat_entities[car][ic]))
					{
						decl String:ClassName[255];
						GetEdictClassname(cars_seat_entities[car][ic], ClassName, 255);					
						if (StrEqual(ClassName, "prop_vehicle_driveable", false))
						{
							Passenger = GetEntPropEnt(cars_seat_entities[car][ic], Prop_Send, "m_hPlayer");
							if (Passenger > 0)
							{
								plyr_hp = GetClientHealth(Passenger);
								plyr_hp -= damage2;
						
								if (plyr_hp <= 0)
								{
									SetEntityHealth(Passenger, 1);
									LeaveVehicle(Passenger);
									FakeClientCommand(Passenger, "kill");
									damage = 0.0;
									return Plugin_Changed;
								}
								else
								{
									SetEntityHealth(Passenger, plyr_hp);
								}
							}
						}
					}
				}
			}			
			return Plugin_Changed;			
		}
	}
	return Plugin_Changed;
}
public OnEntityDestroyed(entity)
{
	if (entity >= MAXPLAYERS)
	{
		new String:ClassName[30];
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
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static bool:PressingUse[MAXPLAYERS + 1];
	static bool:DuckBuffer[MAXPLAYERS + 1];
	static OldButtons[MAXPLAYERS + 1];
	
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
//						if ((distance <= 80.00) && (!GetEntProp(Ent, Prop_Data, "m_bLocked")))
					
						// It is a car.  See if it is locked or not, and if it is in range.
						if ((!GetEntProp(Ent, Prop_Data, "m_bLocked")) && (distance <= 88.00))
						{
							// Car in range, unlocked.
							new Driver = GetEntPropEnt(Ent, Prop_Send, "m_hPlayer");
							if (Driver == -1)
							{
								AcceptEntityInput(Ent, "use", client);
//								buttons &= ~IN_USE;
								PressingUse[client] = true;
								OldButtons[client] = buttons;

/*
								FakeClientCommand(client, "use weapon_knife; use weapon_knifegg");
								int enteffects = GetEntProp(client, Prop_Send, "m_fEffects");
								enteffects |= 1;	// This is EF_BONEMERGE
								enteffects |= 16;	// This is EF_NOSHADOW 
								enteffects &= ~32;	// This is EF_NODRAW 
								enteffects |= 64;	// This is EF_NORECEIVESHADOW 
								enteffects |= 128;	// This is EF_BONEMERGE_FASTCULL 
								enteffects |= 512;	// This is EF_PARENT_ANIMATES
								SetEntProp(client, Prop_Send, "m_fEffects", enteffects); 
								SetClientViewEntity(client, client);*/

								return Plugin_Handled;
							}
							else if (cars_seats[Ent] > 0)
							{
								// Car has multiple seats, someone already driving
								new Passenger = -1;
								decl String:ClassName2[255];
								for ( new ic = 1;  ic < cars_seats[Ent] + 1; ic++ )
								{
									GetEdictClassname(cars_seat_entities[Ent][ic], ClassName2, 255);
									if (StrEqual(ClassName2, "prop_vehicle_driveable", false))
									{
										// Is there a passenger in one of the seats?
										Passenger = GetEntPropEnt(cars_seat_entities[Ent][ic], Prop_Send, "m_hPlayer");
										if (Passenger == -1)
										{
											new chair = cars_seat_entities[Ent][ic];
											if (IsValidEntity(chair))
											{
												new t = cars_type[Ent];
												SetVariantString("");
												AcceptEntityInput(chair, "SetParent", chair, chair, 0);									
												AcceptEntityInput(chair, "use", client);
										
												new String:car_name2[128];
												GetTargetName(Ent,car_name2,sizeof(car_name2));
                    
												SetVariantString(car_name2);
												AcceptEntityInput(chair, "SetParent", chair, chair, 0);
												SetVariantString(car_passenger_attachment[t][ic]);
												AcceptEntityInput(chair, "SetParentAttachment", chair, chair, 0);								

												break;
											}
										}
									}
								}
							}						
						}
						else
						{
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
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
	if (buttons & IN_RELOAD)
	{
		new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		if (car != -1)
		{	
			if (GetConVarInt(g_Cvar_GasUse))
			{
				if (car_fuel[car] > 0.0)
				{
					AcceptEntityInput(car, "TurnOn");
					CarOn[car] = true;
				}
				else PrintToChat(client, "\x04[Car] %T", "No_Gas", client);
			}
			else
			{
				AcceptEntityInput(car, "TurnOn");
				CarOn[car] = true;
			}
		}
	}
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
public OnThink(entity)
{
	new Driver = GetEntPropEnt(entity, Prop_Send, "m_hPlayer");
	if ((IsValidEntity(ViewEnt[entity])) && (Driver > 0))
	{
		if(IsClientInGame(Driver) && IsPlayerAlive(Driver))
		{
			SetEntProp(entity, Prop_Data, "m_nNextThinkTick", 1);
			SetEntPropFloat(entity, Prop_Data, "m_flTurnOffKeepUpright", 1.0);
			Driving[Driver] = true;
			SetClientViewEntity(Driver, Driver);
/*			SetEntProp(Driver, Prop_Send, "m_pParent", entity);
			SetEntProp(Driver, Prop_Send, "m_iParentAttachment", 1);
			PrintToChatAll("LOL 2"); */
			new t = cars_type[entity];
			if (car_driver_view[t] == 1)
			{/*
				new enteffects = GetEntProp(Driver, Prop_Send, "m_fEffects"); 
				enteffects &= ~32; // make player visible
				enteffects |= 1; // for bonemerge
				enteffects |= 128; // for bonemerge
				SetEntProp(Driver, Prop_Send, "m_fEffects", enteffects);
				
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

						new String:car_ent_name[128];
						GetTargetName(entity,car_ent_name,sizeof(car_ent_name));
				
						SetVariantString(car_ent_name);
						AcceptEntityInput(prop, "SetParent", prop, prop, 0);
						SetVariantString("vehicle_driver_eyes");
						AcceptEntityInput(prop, "SetParentAttachment", prop, prop, 0);
						Cars_Driver_Prop[entity] = prop;
						
						new hat = GetClientHatEntity(Driver);
						if (IsValidEntity(hat))
						{
							AcceptEntityInput(hat, "ClearParent", hat, hat, 0);
							new type = GetClientHat(Driver);
							SetHatEntityToParent(hat, entity, type);
	
							SetVariantString(car_ent_name);
							AcceptEntityInput(hat, "SetParent", hat, hat, 0);
							SetVariantString("n_head");
							AcceptEntityInput(hat, "SetParentAttachmentMaintainOffset", hat, hat, 0);
						}
					}
				}
			*/
			}
			else Cars_Driver_Prop[entity] = -1;
		}
	}
	if ((!IsValidEntity(ViewEnt[entity])) && Driver > 0)
	{
		// This runs ONCE when client enters the car.
		SetEntProp(entity, Prop_Send, "m_nSequence", 0);
		CarView[Driver] = false;
		CarHorn[Driver] = false;
		armour[Driver] = GetEntProp(Driver, Prop_Send, "m_ArmorValue"); 
		SetEntProp(entity, Prop_Send, "m_bEnterAnimOn", 0);
		SetEntProp(entity, Prop_Send, "m_nSequence", 0);
		if (is_chair[entity] <= 1)
		{
			if (GetConVarInt(g_Cvar_GasUse))
			{
				if (car_fuel[entity] > 0.0)
				{
					AcceptEntityInput(entity, "TurnOn");
					CarOn[entity] = true;
				}
				else PrintToChat(Driver, "\x04[Car] %T", "No_Gas", Driver);
			}
			else
			{
				AcceptEntityInput(entity, "TurnOn");
				CarOn[entity] = true;
			}
		}
		else if (is_chair[entity] == 2)
		{
			AcceptEntityInput(entity, "TurnOff");
			CarOn[entity] = false;
		}
/*
		float origin[3], angles[3];
		angles[0] *=2;
		angles[1] *=2;
		angles[2] *=2;
		GetEntPropVector(entity, Prop_Data, "m_angRotation", angles);
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		angles[1] += 90.0;
		
		float x = 0.0, y = -200.0, z = 120.0 , radian = DegToRad(angles[1]);
		origin[0] += (x*Sine(radian)) + (y*Cosine(radian));
		origin[1] += (x*Cosine(radian)) + (y*Sine(radian));
		origin[2] += z;
		angles[0] -= 10.0;

		int fire = CreateEntityByName("env_fire");
		DispatchSpawn(fire);
		ActivateEntity(fire);

		TeleportEntity(fire, origin, angles, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(fire, "SetParent", entity);
		ViewEnt[entity] = fire;
*/
		SetClientViewEntity(Driver, Driver);

		new String:car_ent_name[128];
		GetTargetName(entity,car_ent_name,sizeof(car_ent_name));
		SetVariantString(car_ent_name);
		AcceptEntityInput(Driver, "SetParent", Driver, Driver, 0);
		SetVariantString("vehicle_3rd");
		AcceptEntityInput(Driver, "SetParentAttachment", Driver, Driver, 0);

		new enteffects = GetEntProp(Driver, Prop_Send, "m_fEffects"); 
		enteffects &= ~32; // make player visible
		enteffects |= 1; // for bonemerge
		enteffects |= 128; // for bonemerge
		SetEntProp(Driver, Prop_Send, "m_fEffects", enteffects);


		/* Old Stuff for client view
		decl Float:ang[3];
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

		new Float:vec[3];
		GetClientAbsOrigin(Driver, vec);
		GetClientAbsAngles(Driver, ang);
		TeleportEntity(sprite, vec, ang, NULL_VECTOR);

		SetClientViewEntity(Driver, sprite);

		//SetVariantString(targetName);
		SetVariantString("!activator");
		AcceptEntityInput(sprite, "SetParent", Driver);
		SetVariantString(targetName);
		AcceptEntityInput(Driver, "SetParent");

		SetVariantString("vehicle_driver_eyes");
		AcceptEntityInput(Driver, "SetParentAttachment");
//		SetVariantString("vehicle_driver_eyes");
//		AcceptEntityInput(sprite, "SetParentAttachment");
		
//		SetEntProp(entity, Prop_Send, "m_nSolidType", 2);

		
		ViewEnt[entity] = sprite; */
	}
	if (Driver > 0)
	{
		// This is checking for a weird error.
		new car = GetEntPropEnt(Driver, Prop_Send, "m_hVehicle");
		if (car != entity)
		{
			PrintToChatAll("\x04[Car] ERROR");
			LeaveVehicle(Driver);
			SDKUnhook(car, SDKHook_Think, OnThink);
			SDKHook(car, SDKHook_Think, OnThink); 
			AcceptEntityInput(car, "Use", Driver);
		}
		
		
		drivers_car[Driver] = entity;
		Driving[Driver] = true;
		buttons2 = GetClientButtons(Driver);
		// Brake Lights on or Off

		if (buttons2 & IN_ATTACK)
		{
			if (!CarHorn[Driver] && (is_chair[entity] <= 1))
			{
				EmitSoundToAll("vehicles/mustang_horn.mp3", entity, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT);
				CarHorn[Driver] = true;
				new Float:delay = GetConVarFloat(g_Cvar_DelayH);
				h_horn = CreateTimer(delay, Horn_Time, Driver);
			}
		}
		new car_index = g_CarIndex[entity];	
		new max = g_CarLightQuantity[car_index];
		if ((max > 0) && (is_chair[entity] == 0))
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
		if (GetConVarInt(g_Cvar_GasUse))
		{
			// Car is on so they're burning gas
			// How fast they burn it depends on forewards or reverse or idle
			if (buttons2 & IN_FORWARD)
			{
				car_fuel[entity] -= (0.001 / mpg[entity]); // accelerate
			}
			else if (buttons2 & IN_BACK)
			{
				car_fuel[entity] -= (0.0005 / mpg[entity]); // reverse
			}
			else car_fuel[entity] -= (0.0001 / mpg[entity]); //idle
			
			if (car_fuel[entity] <= 0.0)
			{
				car_fuel[entity] = 0.0;
				AcceptEntityInput(entity, "TurnOff");
			}
			fuel_display[entity] = RoundToCeil(car_fuel[entity]);
			SetEntData(Driver, m_ArmorValue,fuel_display[entity],4,true);
		}
		if (is_chair[entity] == 0)
		{
			new speed = GetEntProp(entity, Prop_Data, "m_nSpeed");
			if (GetConVarInt(g_Cvar_GasUse))
			{
				PrintHintText(Driver, "%T", "Speed+Gas", Driver, speed, fuel_display[entity]);
			}
			else PrintHintText(Driver, "%T", "Speed", Driver, speed);
		}
/*		new hat = GetClientHatEntity(Driver);
		if (IsValidEntity(hat))
		{
			AcceptEntityInput(hat, "ClearParent", hat, hat, 0);
			new String:car_ent_name[128];
			GetTargetName(entity,car_ent_name,sizeof(car_ent_name));				
			SetVariantString(car_ent_name);
			AcceptEntityInput(hat, "SetParent", hat, hat, 0);
		} */
	}
}
public Action:OnWeaponDrop(client, weapon)
{
	if (IsClientInGame(client))
	{
		if (GetEntPropEnt(client, Prop_Send, "m_hVehicle") != -1)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public OnPreThink(client)
{
	GetClientEyeAngles(client, CurrentEyeAngle[client]);
}



// ####################
// SUPPORTING FUNCTIONS
// ####################



public ReadCarFile()
{
	carbuykv = CreateKeyValues("Commands")
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/cars.ini")
	FileToKeyValues(carbuykv, file)

	KvRewind(carbuykv);

	if (!KvGotoFirstSubKey(carbuykv))
	{
		PrintToServer("[Car DEBUG] There are no cars listed in cars.ini, or there is an error with the file.");
		return;
	}
	new t = 1;
	do
	{
		KvGetSectionName(carbuykv, car_name[t], sizeof(car_name[]));
		car_price[t] = KvGetNum(carbuykv, "Price", 2000);
		car_vip[t] = KvGetNum(carbuykv, "VIP", 0);
		car_skins[t] = KvGetNum(carbuykv, "val_1", 0);
		KvGetString(carbuykv, "model", car_model[t], 255, "FUCK_YOU");
		PrecacheModel(car_model[t]);
		KvGetString(carbuykv, "script", car_script[t], 255, "FUCK_YOU");
		car_mpg[t] = KvGetNum(carbuykv, "mpg", 20);
		car_gas[t] = KvGetFloat(carbuykv, "gas_tank", 16.00);
		car_lights[t] = KvGetNum(carbuykv, "lights", 0);
		car_police_lights[t] = KvGetNum(carbuykv, "police_lights", 0);
		car_view_enabled[t] = KvGetNum(carbuykv, "view", 0);
		car_siren_enabled[t] = KvGetNum(carbuykv, "siren", 0);
		car_driver_view[t] = KvGetNum(carbuykv, "driver", 0);
		car_passengers[t] = KvGetNum(carbuykv, "passengers", 0);

		if (car_passengers[t] > 0)
		{
			new String:buffer_m[32];
			new String:buffer_a[32];
			for ( new ic = 1;  ic < car_passengers[t] + 1; ic++ )
			{
				Format(buffer_m, sizeof(buffer_m), "p%i_model", ic);
				KvGetString(carbuykv, buffer_m, car_passenger_seat[t][ic], sizeof(car_passenger_seat), "UNKNOWN");
				if (StrEqual(car_passenger_seat[t][ic], "UNKNOWN", false))
				{
					car_passengers[t] = 0;
					PrintToServer("[Car] Car %s has an error for passenger seat model %i.", car_name[t], ic);
					break;
				}
				Format(buffer_a, sizeof(buffer_a), "p%i_attachment", ic);
				KvGetString(carbuykv, buffer_a, car_passenger_attachment[t][ic], sizeof(car_passenger_attachment), "UNKNOWN");
				if (StrEqual(car_passenger_attachment[t][ic], "UNKNOWN", false))
				{
					car_passengers[t] = 0;
					PrintToServer("[Car] Car %s has an error for passenger seat attachment %i.", car_name[t], ic);
					break;
				}
				Format(buffer_m, sizeof(buffer_m), "p%i_mode", ic);
				car_passenger_mode[t][ic] = KvGetNum(carbuykv, buffer_m, 0);
				if (car_passenger_mode[t][ic] == 1)
				{
					//Mode was set to 1 for this seat, get its position float.
					new Float:temp[3];
					Format(buffer_m, sizeof(buffer_m), "p%i_position", ic);
					KvGetVector(carbuykv, buffer_m, temp);
					car_passenger_position[t][ic] = temp;
				}
            }
			PrintToServer("[Car] Car %s has %i seat(s).", car_name[t], car_passengers[t]);
		}
		

		if (car_vip[t] == 1)
		{
			car_quantity_vip += 1;
		}
		else if (car_vip[t] == -1)
		{
			car_quantity_disabled += 1;
		}
		car_quantity += 1;
		t += 1;

	} while (KvGotoNextKey(carbuykv));

	KvRewind(carbuykv);
	
	car_view_enabled[100] = 1;
	car_driver_view[100] = 1;
	
	PrintToServer("[Car] Cars Loaded (%s)", CAR_VERSION);
	PrintToServer("[Car] %i Cars were detected.", car_quantity - car_quantity_vip - car_quantity_disabled);
	PrintToServer("[Car] %i VIP Cars were detected.", car_quantity_vip);
}

LeaveVehicle(client)
{
	new vehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	if (IsValidEntity(vehicle))
	{
		if (IsValidEntity(ViewEnt[vehicle]))
		{
			AcceptEntityInput(ViewEnt[vehicle], "Kill");
		}
		if (IsValidEntity(Cars_Driver_Prop[vehicle]))
		{
			AcceptEntityInput(Cars_Driver_Prop[vehicle], "Kill");
			Cars_Driver_Prop[vehicle] = -1;
		}
		
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
/*
		new EntEffects = GetEntProp(client, Prop_Send, "m_fEffects");
		EntEffects &= ~EF_NODRAW;
		SetEntProp(client, Prop_Send, "m_fEffects", EntEffects);

		new Float:ViewOffset[3];
		GetEntPropVector(vehicle, Prop_Data, "m_savedViewOffset", ViewOffset);
		SetEntPropVector(client, Prop_Data, "m_vecViewOffset", ViewOffset);
*/

		SetEntProp(vehicle, Prop_Send, "m_nSpeed", 0);
		SetEntPropFloat(vehicle, Prop_Send, "m_flThrottle", 0.0);
		AcceptEntityInput(vehicle, "TurnOff");

		SetEntPropFloat(vehicle, Prop_Data, "m_flTurnOffKeepUpright", 0.0);
		SetEntProp(vehicle, Prop_Send, "m_iTeamNum", 0);
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
			}
		}
	}
	Driving[client] = false;
	drivers_car[client] = -1;
	
	// Fix no weapon
	new plyr_gun2 = GetPlayerWeaponSlot(client, 2);
	if (IsValidEntity(plyr_gun2))
	{
		RemovePlayerItem(client, plyr_gun2);
		RemoveEdict(plyr_gun2);
		GivePlayerItem(client, "weapon_knife", 0);
	}
/*	new hat = GetClientHatEntity(client);
	if (IsValidEntity(hat))
	{
		AcceptEntityInput(hat, "ClearParent", hat, hat, 0);
		new type = GetClientHat(client);
		SetHatEntityToParent(hat, client, type);
	} */
	ClientCommand(client, "firstperson");
}
public ViewToggle(client)
{
	new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	new t = cars_type[car];
	if (!car_view_enabled[t])
	{
		return;
	}
	if(CarView[client] == true)
	{
		CarView[client] = false;
		ClientCommand(client, "firstperson");
		return;
	}
	if(CarView[client] == false)
	{
		CarView[client] = true;
		ClientCommand(client, "thirdperson");
		return; 
	}
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
	EmitSoundToAll("buttons/lightswitch2.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
}
public SirenToggle(car, client)
{
	if(IsValidEntity(car))
	{
		decl String:ClassName[255];
		GetEdictClassname(car, ClassName, 255);
							
		if(StrEqual(ClassName, "prop_vehicle_driveable"))
		{
			if(CarSiren[car] == true)
			{
				CarSiren[car] = false;
				PrintToChat(client, "\x04[Car] %T", "Siren_Off", client);
				return;
			}
			if(CarSiren[car] == false)
			{
				CarSiren[car] = true;
				PrintToChat(client, "\x04[Car] %T", "Siren_On", client);
				EmitSoundToAll("vehicles/police_siren_single.mp3", client, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT);
				h_siren_a = CreateTimer(0.15, A_Time, car);
				h_siren_c = CreateTimer(4.50, C_Time, car);
			
				return;
			}
		}
	}
	return;
}
public Action:A_Time(Handle:timer, any:car)
{
	new car_index = g_CarIndex[car];
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
public Action:B_Time(Handle:timer, any:car)
{
	new car_index = g_CarIndex[car];
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
public Action:C_Time(Handle:timer, any:car)
{
	if(CarSiren[car] == true)
	{
		if ((car > 0) && (IsValidEntity(car)))
		{
			decl String:ClassName[255];
			GetEdictClassname(car, ClassName, 255);
							
			if(StrEqual(ClassName, "prop_vehicle_driveable"))
			{
				new Driver = GetEntPropEnt(car, Prop_Send, "m_hPlayer");
				if (Driver > 0)
				{
					EmitSoundToAll("vehicles/police_siren_single.mp3", Driver, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT);
					h_siren_c = CreateTimer(4.50, C_Time, car);
				}
			}
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
// STOCKS
// ######



// Thanks to raydan for this one.
stock GetTargetName(entity, String:buf[], len)
{
	GetEntPropString(entity, Prop_Data, "m_iName", buf, len);
}
stock Reset_Car_Selection(client)
{
	selected_car[client] = -1;
	selected_car_stowed[client] = -1;
	selected_car_skin[client] = -1;
	selected_car_type[client] = -1;
	selected_car_fuel[client] = -1.0;
	selected_car_name[client] = "FUCK_YOU";
	selected_car_index[client] = -1;
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
stock FindEntityByTargetname(const String:targetname[], const String:classname[])
{
  decl String:namebuf[32];
  new index = -1;
  namebuf[0] = '\0';

  while(strcmp(namebuf, targetname) != 0
    && (index = FindEntityByClassname(index, classname)) != -1)
    GetEntPropString(index, Prop_Data, "m_iName", namebuf, sizeof(namebuf));

  return(index);
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
			}
			else PrintToChat(client, "\x04[RR] %T", "Get_Inside", LANG_SERVER);
			return Plugin_Handled;
		}
		else PrintToChat(client, "\x04[RR] %T", "Youre_Dead", LANG_SERVER);
		return Plugin_Handled;			
	}	
	return Plugin_Handled;
}
stock Spawn_a_Car(param1, index)
{
	if (!IsPlayerAlive(param1))
	{
		PrintToChat(param1, "\x04[Car] %T", "Youre_Dead", param1);
		Reset_Car_Selection(param1);
		return;
	}
	if (index == -1)
	{
		return;
	}
	if (Car_Entity[param1][index] > 0)
	{
		return;
	}
	new i = Car_Type[param1][index];
	if (i == 0)
	{
		return;
	}
	new AdminId:admin = GetUserAdmin(param1);
	if (admin == INVALID_ADMIN_ID)
	{
		if (cars_spawned[param1] >= 2)
		{
			PrintToChat(param1, "You must stow one of your cars before you can spawn another one.");
			Reset_Car_Selection(param1);
			return;
		}
	}
	if (StrEqual(car_model[i],"FUCK_YOU"))
	{
		PrintToServer("[Car DEBUG] Error in cars.ini for vehicle: %s (Model not found.)", car_name[i]);
		PrintToChat(param1, "\x04[Car DEBUG] %T", "Error_V", param1, car_name[i]);
		PrintToChat(param1, "\x04[Car DEBUG] %T", "Error_No_Spawn", param1);
		Reset_Car_Selection(param1);
		return;
	}
	if (StrEqual(car_script[i],"FUCK_YOU"))
	{
		PrintToServer("[Car DEBUG] Error in cars.ini for vehicle: %s (Script not found.)", car_name[i]);
		PrintToChat(param1, "\x04[Car DEBUG] %T", "Error_V", param1, car_name[i]);
		PrintToChat(param1, "\x04[Car DEBUG] %T", "Error_No_Spawn", param1);
		Reset_Car_Selection(param1);
		return;
	}									
	selected_car_stowed[param1] = 0;
			
	// Get the location for the car.
	new Float:EyeAng[3];
	GetClientEyeAngles(param1, EyeAng);
	new Float:ForwardVec[3];
	GetAngleVectors(EyeAng, ForwardVec, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(ForwardVec, 100.0);
	ForwardVec[2] = 0.0;
	new Float:EyePos[3];
	GetClientEyePosition(param1, EyePos);
	new Float:AbsAngle[3];
	GetClientAbsAngles(param1, AbsAngle);
		
	new Float:SpawnAngles[3];
	SpawnAngles[1] = EyeAng[1];
	new Float:SpawnOrigin[3];
	AddVectors(EyePos, ForwardVec, SpawnOrigin);			
			
	new ent = CreateEntityByName("prop_vehicle_driveable");
	if(IsValidEntity(ent))
	{
		Cars_Driver_Prop[ent] = -1;
		ActivateEntity(ent);
		decl String:skin[4];
		Format(skin, sizeof(skin), "%i", Car_Skin[param1][index]);
				
		new String:ent_name[16], String:light_index[16];
		Format(ent_name, 16, "%i", ent);
		Format(light_index, 16, "%iLgt", ent);

		g_SpawnedCars[param1] += 1;
		new String:Car_Name[64];
		GetClientAuthId(param1, AuthId_Engine, authid[param1], sizeof(authid[]));
		Format(Car_Name, sizeof(Car_Name), "%s_%i_%i", authid[param1], g_SpawnedCars[param1], ent);
				
		DispatchKeyValue(ent, "vehiclescript", car_script[i]);
		DispatchKeyValue(ent, "model", car_model[i]);
		DispatchKeyValueFloat (ent, "MaxPitch", 360.00);
		DispatchKeyValueFloat (ent, "MinPitch", -360.00);
		DispatchKeyValueFloat (ent, "MaxYaw", 90.00);
		DispatchKeyValue(ent, "targetname", Car_Name);
		DispatchKeyValue(ent, "solid","6");
		DispatchKeyValue(ent, "actionScale","1");
		DispatchKeyValue(ent, "EnableGun","0");
		DispatchKeyValue(ent, "ignorenormals","0");
		DispatchKeyValue(ent, "fadescale","1");
		DispatchKeyValue(ent, "fademindist","-1");
		DispatchKeyValue(ent, "VehicleLocked","0");
		DispatchKeyValue(ent, "screenspacefade","0");
		DispatchKeyValue(ent, "spawnflags", "256" );
		DispatchKeyValue(ent, "skin", skin);
		DispatchKeyValue(ent, "setbodygroup", "511" );
		TeleportEntity(ent, SpawnOrigin, SpawnAngles, NULL_VECTOR);
				
				
		PrintToServer("[Car] %s spawned a %s.", authid[param1], car_name[i]);
		PrintToChat(param1, "\x04[Car] %T", "Spawn", param1, car_name[i]);
				
		DispatchSpawn(ent);

		// Thanks to blodia for this
					
		SetEntProp(ent, Prop_Data, "m_nNextThinkTick", -1);	
		SDKHook(ent, SDKHook_Think, OnThink); 				

		ViewEnt[ent] = -1;
				
		SetCarOwnership(param1, ent, 1);
		car_owner[ent] = param1;
			
		Car_Entity[param1][index] = ent;

		g_CarQty += 1;
		g_CarIndex[ent] = g_CarQty;
		new car_index2 = g_CarIndex[ent];
		g_CarLightQuantity[car_index2] = 0;
				
		// Set the gas in the tank.
		car_fuel[ent] = Car_Gas[param1][index];
		mpg[ent] = car_mpg[i];
		cars_type[ent] = i;
		CarOn[ent] = true;
		cars_index[ent] = index;
		is_chair[ent] = 0;
		chairs_car[ent] = -1;
				
		can_stow[param1] = false;
		cars_spawned[param1] +=1;	
		CreateTimer(300.0, Stow_Timer, param1);

				
		// Car is spawned and all neccessary arrays are taken care of.
		// Now we move on to lights.
				
		if ((car_lights[i] == 1) || (car_lights[i] == 2))
		{
			// First declare some angles and colours.
			decl Float:brake_rgb[3], Float:brake_angles[3], Float:white_rgb[3], Float:blue_rgb[3];
			brake_rgb[0] = 255.0;
			brake_rgb[1] = 0.0;
			brake_rgb[2] = 0.0;

			blue_rgb[0] = 0.0;
			blue_rgb[1] = 0.0;
			blue_rgb[2] = 255.0;

			white_rgb[0] = 255.0;
			white_rgb[1] = 255.0;
			white_rgb[2] = 255.0;

			brake_angles[0] = 0.0;
			brake_angles[1] = 0.0;
			brake_angles[2] = 0.0;

			// Then we create the brake lights.  Siren lights will come later if applicable.
	
			new brake_l = CreateEntityByName("env_sprite");


			DispatchKeyValue(brake_l, "parentname", ent_name);
			DispatchKeyValue(brake_l, "targetname", light_index);
			DispatchKeyValueFloat(brake_l, "HDRColorScale", 1.0);
			DispatchKeyValue(brake_l, "renderamt", "155");
			DispatchKeyValueVector(brake_l, "rendercolor", brake_rgb);
			DispatchKeyValueVector(brake_l, "angles", brake_angles);
			DispatchKeyValue(brake_l, "spawnflags", "3");
			DispatchKeyValue(brake_l, "rendermode", "5");
			DispatchKeyValue(brake_l, "model", "sprites/light_glow02.spr");
			DispatchKeyValueFloat(brake_l, "scale", 0.2);
			DispatchSpawn(brake_l);
			TeleportEntity(brake_l, SpawnOrigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(Car_Name);
			AcceptEntityInput(brake_l, "SetParent", brake_l, brake_l, 0);
			SetVariantString("light_rl")
			AcceptEntityInput(brake_l, "SetParentAttachment", brake_l, brake_l, 0);

			g_CarLightQuantity[car_index2] += 1;
			g_CarLights[car_index2][0] = brake_l;


			new brake_r = CreateEntityByName("env_sprite");


			DispatchKeyValue(brake_l, "parentname", ent_name);
			DispatchKeyValue(brake_l, "targetname", light_index);
			DispatchKeyValueFloat(brake_r, "HDRColorScale", 1.0);
			DispatchKeyValue(brake_r, "renderamt", "155");
			DispatchKeyValueVector(brake_r, "rendercolor", brake_rgb);
			DispatchKeyValueVector(brake_r, "angles", brake_angles);
			DispatchKeyValue(brake_r, "spawnflags", "3");
			DispatchKeyValue(brake_r, "rendermode", "5");
			DispatchKeyValue(brake_r, "model", "sprites/light_glow02.spr");
			DispatchKeyValueFloat(brake_r, "scale", 0.2);
			DispatchSpawn(brake_r);
			TeleportEntity(brake_r, SpawnOrigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(Car_Name);
			AcceptEntityInput(brake_r, "SetParent", brake_r, brake_r, 0);
			SetVariantString("light_rr")
			AcceptEntityInput(brake_r, "SetParentAttachment", brake_r, brake_r, 0);

			g_CarLightQuantity[car_index2] += 1;
			g_CarLights[car_index2][1] = brake_r;


			new brake_l2 = CreateEntityByName("env_sprite");

			DispatchKeyValue(brake_l2, "parentname", ent_name);
			DispatchKeyValue(brake_l2, "targetname", light_index);
			DispatchKeyValueFloat(brake_l2, "HDRColorScale", 1.0);
			DispatchKeyValue(brake_l2, "renderamt", "100");
			DispatchKeyValueVector(brake_l2, "rendercolor", brake_rgb);
			DispatchKeyValueVector(brake_l2, "angles", brake_angles);
			DispatchKeyValue(brake_l2, "spawnflags", "3");
			DispatchKeyValue(brake_l2, "rendermode", "5");
			DispatchKeyValue(brake_l2, "model", "sprites/light_glow02.spr");
			DispatchKeyValueFloat(brake_l2, "scale", 0.2);
			DispatchSpawn(brake_l2);
			TeleportEntity(brake_l2, SpawnOrigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(Car_Name);
			AcceptEntityInput(brake_l2, "SetParent", brake_l, brake_l, 0);
			SetVariantString("light_rl")
			AcceptEntityInput(brake_l2, "SetParentAttachment", brake_l, brake_l, 0);

			g_CarLightQuantity[car_index2] += 1;
			g_CarLights[car_index2][2] = brake_l2;


			new brake_r2 = CreateEntityByName("env_sprite");


			DispatchKeyValue(brake_r2, "parentname", ent_name);
			DispatchKeyValue(brake_r2, "targetname", light_index);
			DispatchKeyValueFloat(brake_r2, "HDRColorScale", 1.0);
			DispatchKeyValue(brake_r2, "renderamt", "100");
			DispatchKeyValueVector(brake_r2, "rendercolor", brake_rgb);
			DispatchKeyValueVector(brake_r2, "angles", brake_angles);
			DispatchKeyValue(brake_r2, "spawnflags", "3");
			DispatchKeyValue(brake_r2, "rendermode", "5");
			DispatchKeyValue(brake_r2, "model", "sprites/light_glow02.spr");
			DispatchKeyValueFloat(brake_r2, "scale", 0.2);
			DispatchSpawn(brake_r2);
			TeleportEntity(brake_r2, SpawnOrigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(Car_Name);
			AcceptEntityInput(brake_r2, "SetParent", brake_r, brake_r, 0);
			SetVariantString("light_rr")
			AcceptEntityInput(brake_r2, "SetParentAttachment", brake_r, brake_r, 0);

			g_CarLightQuantity[car_index2] += 1;
			g_CarLights[car_index2][3] = brake_r2;			
					
			if (car_police_lights[i] == 1)
			{
				new blue_1 = CreateEntityByName("env_sprite");

				DispatchKeyValue(blue_1, "parentname", ent_name);
				DispatchKeyValue(blue_1, "targetname", light_index);
				DispatchKeyValueFloat(blue_1, "HDRColorScale", 1.0);
				DispatchKeyValue(blue_1, "renderamt", "255");
				DispatchKeyValueVector(blue_1, "rendercolor", blue_rgb);
				DispatchKeyValueVector(blue_1, "angles", brake_angles);
				DispatchKeyValue(blue_1, "spawnflags", "3");
				DispatchKeyValue(blue_1, "rendermode", "5");
				DispatchKeyValue(blue_1, "model", "sprites/light_glow02.spr");
				DispatchSpawn(blue_1);
				TeleportEntity(blue_1, SpawnOrigin, NULL_VECTOR, NULL_VECTOR);
				SetVariantString(Car_Name)
				AcceptEntityInput(blue_1, "SetParent", blue_1, blue_1, 0);
				SetVariantString("light_bar1")
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
				DispatchKeyValueVector(blue_2, "angles", brake_angles);
				DispatchKeyValue(blue_2, "spawnflags", "3");
				DispatchKeyValue(blue_2, "rendermode", "5");
				DispatchKeyValue(blue_2, "model", "sprites/light_glow02.spr");
				DispatchSpawn(blue_2);
				TeleportEntity(blue_2, SpawnOrigin, NULL_VECTOR, NULL_VECTOR);
				SetVariantString(Car_Name)
				AcceptEntityInput(blue_2, "SetParent", blue_2, blue_2, 0);
				SetVariantString("light_bar2")
				AcceptEntityInput(blue_2, "SetParentAttachment", blue_2, blue_2, 0);
				AcceptEntityInput(blue_2, "HideSprite");
						
				g_CarLightQuantity[car_index2] += 1;
				g_CarLights[car_index2][5] = blue_2;
						
				CarSiren[ent] = false;
			}
			if (car_lights[i] == 2)
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
					TeleportEntity(headlight_l, SpawnOrigin, SpawnAngles, NULL_VECTOR);
					SetVariantString(Car_Name);
					AcceptEntityInput(headlight_l, "SetParent", headlight_l, headlight_l, 0);
					SetVariantString("light_fl")
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
					TeleportEntity(headlight_r, SpawnOrigin, SpawnAngles, NULL_VECTOR);
					SetVariantString(Car_Name);
					AcceptEntityInput(headlight_r, "SetParent", headlight_r, headlight_r, 0);
					SetVariantString("light_fr")
					AcceptEntityInput(headlight_r, "SetParentAttachment", headlight_r, headlight_r, 0);
					AcceptEntityInput(headlight_r, "TurnOff");
					
					g_CarLights[car_index2][7] = headlight_r;



					new headlight_l2 = CreateEntityByName("env_sprite");

					DispatchKeyValue(headlight_l2, "parentname", ent_name);
					DispatchKeyValue(headlight_l2, "targetname", light_index);
					DispatchKeyValueFloat(headlight_l2, "HDRColorScale", 1.0);
					DispatchKeyValue(headlight_l2, "renderamt", "200");
					DispatchKeyValueVector(headlight_l2, "rendercolor", white_rgb);
					DispatchKeyValueVector(headlight_l2, "angles", brake_angles);
					DispatchKeyValue(headlight_l2, "spawnflags", "3");
					DispatchKeyValue(headlight_l2, "rendermode", "5");
					DispatchKeyValue(headlight_l2, "model", "sprites/light_glow03.spr");
					DispatchKeyValueFloat(headlight_l2, "scale", 0.35);
					DispatchSpawn(headlight_l2);
					TeleportEntity(headlight_l2, SpawnOrigin, NULL_VECTOR, NULL_VECTOR);
					SetVariantString(Car_Name);
					AcceptEntityInput(headlight_l2, "SetParent", headlight_l2, headlight_l2, 0);
					SetVariantString("light_fl")
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
					DispatchKeyValueVector(headlight_r2, "angles", brake_angles);
					DispatchKeyValue(headlight_r2, "spawnflags", "3");
					DispatchKeyValue(headlight_r2, "rendermode", "5");
					DispatchKeyValue(headlight_r2, "model", "sprites/light_glow03.spr");
					DispatchKeyValueFloat(headlight_r2, "scale", 0.35);
					DispatchSpawn(headlight_r2);
					TeleportEntity(headlight_r2, SpawnOrigin, NULL_VECTOR, NULL_VECTOR);
					SetVariantString(Car_Name);
					AcceptEntityInput(headlight_r2, "SetParent", headlight_r2, headlight_r2, 0);
					SetVariantString("light_fr")
					AcceptEntityInput(headlight_r2, "SetParentAttachment", headlight_r2, headlight_r2, 0);
					AcceptEntityInput(headlight_r2, "HideSprite");

					g_CarLightQuantity[car_index2] += 1;
					g_CarLights[car_index2][9] = headlight_r2;						
			}
		}		
		// That was the bit for car lights.  Now for seats.  :)
		cars_seats[ent] = 0;
		if (car_passengers[i] > 0)
		{
			for ( new ic = 1;  ic < car_passengers[i] + 1; ic++ )
			{
				new seat = CreateEntityByName("prop_vehicle_driveable");
				if(IsValidEntity(seat))
				{
					cars_seat_entities[ent][ic] = seat;
					Cars_Driver_Prop[seat] = -1;

					new String:Seat_Name[64];
					Format(Seat_Name, sizeof(Seat_Name), "%i_chair", seat);
				
					DispatchKeyValue(seat, "vehiclescript", "scripts/vehicles/chair.txt");
					DispatchKeyValue(seat, "model", car_passenger_seat[i][ic]);	
					DispatchKeyValueFloat (seat, "MaxPitch", 360.00);
					DispatchKeyValueFloat (seat, "MinPitch", -360.00);
					DispatchKeyValueFloat (seat, "MaxYaw", 90.00);
					DispatchKeyValue(seat, "targetname", Seat_Name);
//					DispatchKeyValue(seat, "solid","6");
					DispatchKeyValue(seat, "actionScale","1");
					DispatchKeyValue(seat, "EnableGun","0");
					DispatchKeyValue(seat, "ignorenormals","0");
					DispatchKeyValue(seat, "fadescale","1");
					DispatchKeyValue(seat, "fademindist","-1");
					DispatchKeyValue(seat, "VehicleLocked","0");
					DispatchKeyValue(seat, "screenspacefade","0");
					DispatchKeyValue(seat, "spawnflags", "4" );
					DispatchKeyValue(seat, "skin", "0");
					DispatchKeyValue(seat, "setbodygroup", "511" );
					SetEntProp(seat, Prop_Data, "m_CollisionGroup", 2);
					
					
					if(car_passenger_mode[i][ic] == 1)
					{
						new Float:origin[3];
						new Float:fForward[3];
						new Float:fRight[3];
						new Float:fUp[3];
						ChairMath(ent, i, ic, origin, fForward, fRight, fUp, SpawnOrigin, SpawnAngles);
						
						PrintToChatAll("\x03[DEBUG] Car Type: %i Chair Number: %i", i, ic);
						
						DispatchSpawn(seat);
						ActivateEntity(seat);
						TeleportEntity(seat, origin, SpawnAngles, NULL_VECTOR);
						
						PrintToChatAll("\x03[DEBUG] origin: %f %f %f", origin[0], origin[1], origin[2]);
						PrintToChatAll("\x03[DEBUG] SpawnOrigin: %f %f %f", SpawnOrigin[0], SpawnOrigin[1], SpawnOrigin[2]);
						
						SetVariantString(Car_Name)
						AcceptEntityInput(seat, "SetParent", seat, seat, 0);
						
						// SetVariantString(car_passenger_attachment[i][ic]);
						// AcceptEntityInput(seat, "SetParentAttachmentMaintainOffset", seat, seat, 0);
					}
					else
					{
						TeleportEntity(seat, SpawnOrigin, SpawnAngles, NULL_VECTOR);
						DispatchSpawn(seat);
						ActivateEntity(seat);
						SetVariantString(Car_Name)
						AcceptEntityInput(seat, "SetParent", seat, seat, 0);
						SetVariantString(car_passenger_attachment[i][ic]);
						AcceptEntityInput(seat, "SetParentAttachment", seat, seat, 0);
					}
					
					SetEntProp(seat, Prop_Data, "m_nNextThinkTick", -1);	
					SDKHook(seat, SDKHook_Think, OnThink);
					AcceptEntityInput(seat, "TurnOff");		
							
					ViewEnt[seat] = -1;
							
					car_fuel[seat] = 10.0;
					mpg[seat] = 10;
					cars_type[seat] = 100;					
					
					cars_seats[ent] += 1;
					is_chair[seat] = 1;
					chairs_car[seat] = ent;
				}
			}
		}
	}
}
stock ChairMath(ent, i, ic, Float:origin[3], Float:fForward[3], Float:fRight[3], Float:fUp[3], Float:SpawnOrigin[3], Float:SpawnAngles[3])
{
	// Hat Location Math -- Thanks to Zephyrus

	origin = SpawnOrigin;
	
	new Float:fOffset[3];
	fOffset[0] = car_passenger_position[i][ic][0];
	fOffset[1] = car_passenger_position[i][ic][1];
	fOffset[2] = car_passenger_position[i][ic][2];
	
	GetAngleVectors(SpawnAngles, fForward, fRight, fUp);
	
	origin[0] += fRight[0]*fOffset[0]+fForward[0]*fOffset[1]+fUp[0]*fOffset[2];
	origin[1] += fRight[1]*fOffset[0]+fForward[1]*fOffset[1]+fUp[1]*fOffset[2];
	origin[2] += fRight[2]*fOffset[0]+fForward[2]*fOffset[1]+fUp[2]*fOffset[2];
}/*
stock EyeFix(client)
{
	for (new players = 1; players <= MaxClients; players++) 
	{ 
		if (IsClientInGame(players) && IsPlayerAlive(players))
		{
			if (players != client)
			{
				new vehicle = GetEntPropEnt(players, Prop_Send, "m_hVehicle");
				if (vehicle != -1)
				{
					new Float: VehicleAng[3];
					VehicleAng[0] *=2;
					VehicleAng[1] *=2;
					VehicleAng[2] *=2;
					GetEntPropVector(vehicle, Prop_Data, "m_angRotation", VehicleAng);
					SubtractVectors(CurrentEyeAngle[players], VehicleAng, CurrentEyeAngle[players]);
				}
				TeleportEntity(players, NULL_VECTOR, CurrentEyeAngle[players], NULL_VECTOR);
			}
		}
	}
}*/