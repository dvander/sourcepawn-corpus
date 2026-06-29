/* 	
*	Hardpoint.sp
*   Made by Sidezz of Realization Entertainment
*   March 8th, 2017
*
*   TODO: Random Cycle hardpoints
*   TODO: Create OPTIONAL player stats module
*   TODO: Release on Alliedmods
*   TODO: Incorporate Sounds to it and stuff
*	TODO: Test on CS:S, CS:GO, Maybe TF2 and Maybe SForts and Maybe DOD:S
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#define MAX_HARDPOINTS 			10;

//Actual Hardpoint Data:
int g_Counter = 10;
int g_CurrentCycle = 0;
int g_Hardpoints = 0;
float g_Hardpoint[10][2][3];
int g_HardpointID[10];
int g_HardpointTimer = 60;
Handle g_tMoveHardpoint = INVALID_HANDLE;

bool g_Live = false;

//Precache, Material Jazz:
new laserSprite;
new laserHalo;

//Admin Stuff:
int cmdPhase[MAXPLAYERS + 1] = {0, ...};
float hardPointCreate[2][3];

//Player Stuff:
bool g_onHardpoint[MAXPLAYERS + 1] = {false, ...};
int g_HudLocationPrefs[MAXPLAYERS + 1] = {1, ...};

//Console Variables:
ConVar g_Hardpoint_Lifetime;
//ConVar g_Hardpoint_Cycle;
ConVar g_Hardpoint_BlastResist;
ConVar g_Hardpoint_DBType;

//Engine Stuff:
EngineVersion g_Engine;

//Prefs Stuff:
Handle hudCookie = INVALID_HANDLE;

//Logging Stuff:
char logFile[PLATFORM_MAX_PATH];

//Database Stuff:
Database g_Database;

//Late load:
bool g_lateLoad = false;

public Plugin myinfo = 
{
	name = "Hardpoint", 
	author = "Sidezz", 
	description = "A remake of the popular Call of Duty Gamemode - Hardpoint AKA King of the Hill", 
	version = "1.0",
	url = "www.coldcommunity.com"
};

char Hardpoint_Create_Query[] = { "CREATE TABLE IF NOT EXISTS hardpoint_table (hardpoint_id INT NOT NULL AUTO_INCREMENT, hardpoint_x1 FLOAT NOT NULL, hardpoint_y1 FLOAT NOT NULL, hardpoint_z1 FLOAT NOT NULL, hardpoint_x2 FLOAT NOT NULL, hardpoint_y2 FLOAT NOT NULL, hardpoint_z2 FLOAT NOT NULL, map_name VARCHAR(64) NOT NULL, PRIMARY KEY(hardpoint_id, map_name));" };

public APLRes AskPluginLoad2(Handle myself, bool late, char[] sError, int err_max)
{
	g_lateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	for(int i = 0; i < 10; i++)
	{
		g_Hardpoint[i][0][0] = 0.0;
	}

	g_Engine = GetEngineVersion();

	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/hardpoint.log");

	g_Hardpoint_Lifetime = CreateConVar("hardpoint_lifetime", "60.0", "The amount of time a hardpoint should last", FCVAR_NOTIFY);
	HookConVarChange(g_Hardpoint_Lifetime, OnLifetimeChanged);
	//g_Hardpoint_Cycle = CreateConVar("hardpoint_cycle", "1", "The cycle type of the hardpoints (1 = linear, 2 = random)", FCVAR_NOTIFY);
	g_Hardpoint_BlastResist = CreateConVar("hardpoint_blast_damage", "75", "The damage multipler for explosions while in the hardpoint (default is 75% of normal damage)", FCVAR_NOTIFY);
	g_Hardpoint_DBType = CreateConVar("hardpoint_dbtype", "mysql", "The default database driver to use (mysql = 1 or sqlite = 2)", FCVAR_NOTIFY | FCVAR_PROTECTED);

	AutoExecConfig();

	RegAdminCmd("sm_createhardpoint", command_createHardpoint, ADMFLAG_ROOT, "Create a hardpoint");
	RegAdminCmd("sm_inserthardpoint", command_createHardpoint, ADMFLAG_ROOT, "Create a hardpoint");
	RegAdminCmd("sm_deletehardpoint", command_removeHardpoint, ADMFLAG_ROOT, "Remove a hardpoint");
	RegAdminCmd("sm_removehardpoint", command_removeHardpoint, ADMFLAG_ROOT, "Remove a hardpoint");

	RegConsoleCmd("sm_hardpointhud", command_hardpointHud, "Show a menu to select HUD options");
	RegConsoleCmd("sm_hudmenu", command_hardpointHud, "Show a menu to select HUD options");

	hudCookie = RegClientCookie("hardpoint_hud", "Location of the Hardpoint Timer Hud", CookieAccess_Public);

	if(g_lateLoad) 
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientConnected(i) && IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
				OnClientCookiesCached(i);
			}
		}
	}

	StartDatabaseConnection();
}

public void OnMapStart()
{
	laserSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	laserHalo = PrecacheModel("materials/sprites/halo01.vmt", true);

	switch(g_Engine)
	{
		case Engine_HL2DM:
		{
			HookEvent("player_death", event_Death, EventHookMode_Post);
		}

		case Engine_TF2:
		{
			//Teamplay_Round_Start:
			//HookEvent("teamplay_round_start", event_roundStart, EventHookMode_Post);
		}

		default: //Likely a Counter-Strike Title.
		{
			//Round_Start:
			//HookEvent("round_start", event_roundStart, EventHookMode_Post);
		}
	}
	CreateTimer(1.0, timer_Counter, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(10.0, timer_StartMatch, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
	if(g_tMoveHardpoint != INVALID_HANDLE) KillTimer(g_tMoveHardpoint);
}

public void OnPluginEnd()
{
	if(g_tMoveHardpoint != INVALID_HANDLE) KillTimer(g_tMoveHardpoint);
}

public void OnClientCookiesCached(int client)
{
	char cVal[32];
	GetClientCookie(client, hudCookie, cVal, sizeof(cVal));
	g_HudLocationPrefs[client] = StringToInt(cVal);
}

public void OnLifetimeChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	KillTimer(g_tMoveHardpoint);
	g_tMoveHardpoint = CreateTimer(g_Hardpoint_Lifetime.FloatValue + 1.0, moveHardpoint, _, TIMER_REPEAT);
}

public void event_Death(Event event, const char[] name, bool noBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int aTeam = GetClientTeam(attacker);

	if(victim != attacker)
	{	
		SetTeamScore(aTeam, GetTeamScore(aTeam) - 1);
	}
	else if(victim == attacker)
	{
		SetTeamScore(aTeam, GetTeamScore(aTeam) + 1);
	}
	return;
}

public Action timer_Counter(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			PrintCenterText(i, "Match Begins in: %i", g_Counter);
		}
	}
	g_Counter--;
	if(g_Counter > 1) CreateTimer(1.0, timer_Counter);

	else if(g_Counter == 1) 
	{
		g_Live = true;
		KillTimer(timer);
		return Plugin_Stop;
	}
	return Plugin_Handled;
}

public Action timer_StartMatch(Handle timer)
{
	if(g_Live)
	{
		g_tMoveHardpoint = CreateTimer(g_Hardpoint_Lifetime.FloatValue + 1.0, moveHardpoint, _, TIMER_REPEAT);
		DrawHardpoint(0);
	}
}

void DrawHardpoint(int point)
{
	if(point == g_Hardpoints) 
	{
		g_CurrentCycle = 0;
		point = 0;
	}

	CreateTimer(1.0, redrawHardpoint, g_CurrentCycle, TIMER_REPEAT);
	g_HardpointTimer = g_Hardpoint_Lifetime.IntValue + 1;
}

public Action redrawHardpoint(Handle timer, any Data)
{	
	float corners[8][3];

	for (int i = 0; i < 4; i++) 
	{
		Array_Copy(g_Hardpoint[g_CurrentCycle][0], corners[i], 3);
	}

	//Get Area:
	corners[1][0] = g_Hardpoint[g_CurrentCycle][1][0];
	corners[2][0] = g_Hardpoint[g_CurrentCycle][1][0]; corners[2][1] = g_Hardpoint[g_CurrentCycle][1][1];
	corners[3][1] = g_Hardpoint[g_CurrentCycle][1][1];

	float Width = GetVectorDistance(corners[1], corners[2]);
	float Length = GetVectorDistance(corners[1], corners[3]);

	if(Width <= -1.0) FloatMul(Width, -1.0);
	if(Length <= -1.0) FloatMul(Length, -1.0);

	float Area = FloatMul(Length, Width);
	float pi = 3.14159265358;

	float Radius = SquareRoot(FloatDiv(Area, pi));

	float midPoint[3];
	GetMiddleOfABox(g_Hardpoint[g_CurrentCycle][0], g_Hardpoint[g_CurrentCycle][1], midPoint);

	int Team2Count = 0;
	int Team3Count = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			float ClientOrigin[3];
			GetClientAbsOrigin(i, ClientOrigin);
			/*
			if(IsbetweenRect(ClientOrigin, g_Hardpoint[g_CurrentCycle][0], g_Hardpoint[g_CurrentCycle][1], i))
			{
				g_onHardpoint[i] = true;
				switch(GetClientTeam(i))
				{
					case 2:
					{
						Team2Count++;
					}

					case 3:
					{
						Team3Count++;
					}
				}
			}
			else g_onHardpoint[i] = false;
			*/
			if((GetVectorDistance(ClientOrigin, midPoint) <= Radius) && (ClientOrigin[2] < midPoint[2] + 45.0) && (ClientOrigin[2] > midPoint[2] - 45.0))
			{
				g_onHardpoint[i] = true;
				switch(GetClientTeam(i))
				{
					case 2:
					{
						Team2Count++;
					}

					case 3:
					{
						Team3Count++;
					}
				}
			}
			else g_onHardpoint[i] = false;
		}
	}

	int controlColor[4] = {255, 255, 255, 255};
	int controlTeam = 0;

	if(g_Engine == Engine_HL2DM)
	{
		if(Team2Count == 0 && Team3Count != 0)
		{
			controlColor = {255, 0, 0, 255};
			controlTeam = 3;
		}
		else if(Team2Count != 0 && Team3Count == 0)
		{
			controlColor = {0, 255, 255, 255};
			controlTeam = 2;
		}
		else if(Team2Count == 0 && Team3Count == 0)
		{
			controlColor = {255, 255, 255, 255};
			controlTeam = 0;
		}
	}
	else if(g_Engine == Engine_CSGO || g_Engine == Engine_CSS)
	{
		if(Team2Count == 0 && Team3Count != 0)
		{
			controlColor = {0, 255, 255, 255};
			controlTeam = 3;
		}
		else if(Team2Count != 0 && Team3Count == 0)
		{
			controlColor = {255, 0, 0, 255};
			controlTeam = 2;
		}
		else if(Team2Count == 0 && Team3Count == 0)
		{
			controlColor = {255, 255, 255, 255};
			controlTeam = 0;
		}
	}
	else if(g_Engine == Engine_TF2)
	{
		if(Team2Count == 0 && Team3Count != 0)
		{
			controlColor = {0, 255, 255, 255};
			controlTeam = 3;
		}
		else if(Team2Count != 0 && Team3Count == 0)
		{
			controlColor = {255, 0, 0, 255};
			controlTeam = 2;
		}
		else if(Team2Count == 0 && Team3Count == 0)
		{
			controlColor = {255, 255, 255, 255};
			controlTeam = 0;
		}
	}

	SetTeamScore(controlTeam, GetTeamScore(controlTeam) + 1);
	TE_SetupBeamRingPoint(midPoint, (Radius * 2), (Radius * 2)  + 0.1, laserSprite, laserHalo, 0, 0, 1.0, 5.0, 0.0, controlColor, 1, FBEAM_NOTILE);
	TE_SendToAll();

	for(int a = 1; a <= MaxClients; a++)
	{
		if(IsClientConnected(a) && IsClientInGame(a))
		{	
			switch(g_HudLocationPrefs[a])
			{
				case 1: //Top Middle:
				{
					SetHudTextParams(-1.0, 0.01, 1.00, 255, 255, 255, 255, 0, 0.0, 0.1, 0.0);
				}

				case 2: //Top Left:
				{
					SetHudTextParams(0.0125, 0.01, 1.00, 255, 255, 255, 255, 0, 0.0, 0.1, 0.0);
				}

				case 3: //Top Right:
				{
					SetHudTextParams(0.9, 0.01, 1.00, 255, 255, 255, 255, 0, 0.0, 0.1, 0.0);
				}

				case 4: //Bottom Middle:
				{
					SetHudTextParams(-1.0, 0.98, 1.00, 255, 255, 255, 255, 0, 0.0, 0.1, 0.0);
				}

				case 5: //Bottom Left:
				{
					SetHudTextParams(0.0125, 0.098, 1.00, 255, 255, 255, 255, 0, 0.0, 0.1, 0.0);
				}

				case 6: //Bottom Right:
				{
					SetHudTextParams(0.9, 0.098, 1.00, 255, 255, 255, 255, 0, 0.0, 0.1, 0.0);
				}

				case 7: //Off:
				{

				}

				default:
				{
					SetHudTextParams(-1.0, 0.01, 1.00, 255, 255, 255, 255, 0, 0.0, 0.1, 0.0);
				}
			}

			ShowHudText(a, -1, "Hardpoint: %is remaining", g_HardpointTimer - 1);
		}
	}

	g_HardpointTimer--;
	if(g_HardpointTimer < 2) KillTimer(timer);
	return Plugin_Handled;
}

public Action moveHardpoint(Handle timer, any Data)
{
	//TODO: Random Move
	if(g_CurrentCycle == g_Hardpoints) g_CurrentCycle = 0;
	else g_CurrentCycle++;

	DrawHardpoint(g_CurrentCycle);
}

public Action command_hardpointHud(int client, int args)
{
	Menu hudMenu = new Menu(hudHandler);

	hudMenu.AddItem("1", "[Top-Middle]");
	hudMenu.AddItem("2", "[Top-Left]");
	hudMenu.AddItem("3", "[Top-Right]");
	hudMenu.AddItem("4", "[Bottom-Middle]");
	hudMenu.AddItem("5", "[Bottom-Left]");
	hudMenu.AddItem("6", "[Bottom-Right]");
	hudMenu.AddItem("7", "[Off]");

	hudMenu.SetTitle("Hardpoint HUD Location");
	hudMenu.Pagination = 7;
	hudMenu.Display(client, 30);
	ReplyToCommand(client, "[Hardpoint] Press <ESC> to open menu.");
	LogToFile(logFile, "%N used command: sm_hudmenu", client);
	return Plugin_Handled;
}

int hudHandler(Menu hudMenu, MenuAction action, int client, int selection)
{
	char buffer[64];
	GetMenuItem(hudMenu, selection, buffer, sizeof(buffer));

	int hud = StringToInt(buffer);

	if (action == MenuAction_Select)
	{
		switch(hud)
		{
			case 1:
			{
				ReplyToCommand(client, "[Hardpoint] Your hud location is now: Top-Middle.");
				g_HudLocationPrefs[client] = 1;
				SetClientCookie(client, hudCookie, buffer);
			}

			case 2:
			{
				ReplyToCommand(client, "[Hardpoint] Your hud location is now: Top-Left.");
				g_HudLocationPrefs[client] = 2;
				SetClientCookie(client, hudCookie, buffer);
			}

			case 3:
			{
				ReplyToCommand(client, "[Hardpoint] Your hud location is now: Top-Right.");
				g_HudLocationPrefs[client] = 3;
				SetClientCookie(client, hudCookie, buffer);
			}

			case 4:
			{
				ReplyToCommand(client, "[Hardpoint] Your hud location is now: Bottom-Middle.");
				g_HudLocationPrefs[client] = 4;
				SetClientCookie(client, hudCookie, buffer);
			}

			case 5:
			{
				ReplyToCommand(client, "[Hardpoint] Your hud location is now: Bottom-Left.");
				g_HudLocationPrefs[client] = 5;
				SetClientCookie(client, hudCookie, buffer);
			}

			case 6:
			{
				ReplyToCommand(client, "[Hardpoint] Your hud location is now: Bottom-Right.");
				g_HudLocationPrefs[client] = 6;
				SetClientCookie(client, hudCookie, buffer);
			}

			case 7:
			{
				ReplyToCommand(client, "[Hardpoint] Your hud location is now: Off.");
				g_HudLocationPrefs[client] = 7;
				SetClientCookie(client, hudCookie, buffer);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete hudMenu;
		return 0;
	}
	return 1;
}

public Action command_createHardpoint(int client, int args)
{
	if(args != 0)
	{
		ReplyToCommand(client, "[Hardpoint] Invalid Syntax: sm_createhardpoint <NO ARGS>");
		return Plugin_Handled;	
	}

	switch(cmdPhase[client])
	{
		case 0:
		{
			GetClientAbsOrigin(client, hardPointCreate[0]);
			ReplyToCommand(client, "[Hardpoint] Point Created.");
			ReplyToCommand(client, "[Hardpoint] Run Command again to mark final point.");
			cmdPhase[client] = 1;
			return Plugin_Handled;	
		}

		case 1:
		{
			GetClientAbsOrigin(client, hardPointCreate[1]);
			if(hardPointCreate[0][2] > hardPointCreate[1][2])
			{
				hardPointCreate[0][2] += 15.0;
				hardPointCreate[1][2] -= 15.0;
			}
			else
			{
				hardPointCreate[0][2] -= 15.0;
				hardPointCreate[1][2] += 15.0;
			}
			InsertHardpoint(hardPointCreate);
			ReplyToCommand(client, "[Hardpoint] Final Point Created.");
			ReplyToCommand(client, "[Hardpoint] Inserted Hardpoint @ %.2f, %.2f, %.2f, %.2f, %.2f, %.2f", hardPointCreate[0][0], hardPointCreate[0][1], hardPointCreate[0][2], hardPointCreate[1][0], hardPointCreate[1][1], hardPointCreate[1][2]);
			LogToFile(logFile, "Admin %N Created a Hardpoint: <%.2f, %.2f, %.2f, -  %.2f, %.2f, %.2f>", client, hardPointCreate[0][0], hardPointCreate[0][1], hardPointCreate[0][2], hardPointCreate[1][0], hardPointCreate[1][1], hardPointCreate[1][2])
			cmdPhase[client] = 0;
			g_Hardpoints++;
			return Plugin_Handled;
		}

		default:
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
}

public Action command_removeHardpoint(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "[Hardpoint] Invalid Syntax: sm_removehardpoint <id>");
		return Plugin_Handled;	
	}

	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	int id = StringToInt(arg);

	char mapName[PLATFORM_MAX_PATH];
	switch(g_Engine)
	{
		case Engine_CSGO:
		{
			GetCurrentMap(mapName, sizeof(mapName));
			RemoveMapPath(mapName, mapName, sizeof(mapName));
		}

		default:
		{
			GetCurrentMap(mapName, sizeof(mapName));
		}
	}

	ReplyToCommand(client, "[Hardpoint] Attempting to delete Hardpoint with ID: %i..", id);
	LogToFile(logFile, "Admin %N Attempted to delete Hardpoint ID: %i on Map %s.", client, id, mapName);

	for(int i = 0; i < 10; i++)
	{
		if(g_HardpointID[i] == id)
		{
			DeleteHardpoint(id);
			ReplyToCommand(client, "[Hardpoint] Hardpoint ID: %i has been deleted", id);
			LogToFile(logFile, "Admin %N Deleted Hardpoint ID: %i on Map %s.", client, id, mapName);
			break;
		}
	}

	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(client > 0 && client <= MaxClients)
	{
		if(!g_Live) return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType)
{
	if(victim > 0)
	{
		//Blast Damage inside Hardpoint is 75%
		if(damageType == DMG_BLAST && g_onHardpoint[victim])
		{
			float dmgMultiplier = FloatMul(g_Hardpoint_BlastResist.FloatValue, 0.01); //Move decimal 2 places for percentage
			damage *= dmgMultiplier;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public void sql_ConnectCB(Handle driver, Handle db, const char[] error, any data)
{
	//Failed Connection:
	if(db == INVALID_HANDLE)
	{
		PrintToServer("[Hardpoint] MySQL Error: %s", error);
		SetFailState("[Hardpoint] MySQL Error: %s", error);
		delete db;
	}

	//Some weird shit with newdecls not even sure what this is all about lol..
	g_Database = view_as <Database>(db);
	PrintToServer("[Hardpoint] MySQL Connection Successful.");
	CreateHardpointTables();
	return;
}

public void sql_GenericQuery(Handle hOwner, Handle hHndl, const char[] sError, any data)
{
	if (hHndl == INVALID_HANDLE) LogError("[Hardpoint] sql_GenericQuery: Query failed! %s", sError);
}

public void sql_LoadMap(Handle owner, Handle results, const char[] error, any data)
{
	//Failed Connection:
	if(results == INVALID_HANDLE)
	{
		PrintToServer("[Hardpoint] SQL LoadMap Query Error: %s", error);
		SetFailState("[Hardpoint] SQL LoadMap Query Error: %s", error);
		delete results;
	}

	int currentPoint = 0;

	while(SQL_FetchRow(results))
	{		
		if(currentPoint >= 10) break;

		int x1, x2, y1, y2, z1, z2, id;

		SQL_FieldNameToNum(results, "hardpoint_id", id);
		SQL_FieldNameToNum(results, "hardpoint_x1", x1);
		SQL_FieldNameToNum(results, "hardpoint_x2", x2);
		SQL_FieldNameToNum(results, "hardpoint_y1", y1);
		SQL_FieldNameToNum(results, "hardpoint_y2", y2);
		SQL_FieldNameToNum(results, "hardpoint_z1", z1);
		SQL_FieldNameToNum(results, "hardpoint_z2", z2);

		g_HardpointID[currentPoint] = SQL_FetchInt(results, id);

		g_Hardpoint[currentPoint][0][0] = SQL_FetchFloat(results, x1);
		g_Hardpoint[currentPoint][0][1] = SQL_FetchFloat(results, y1);
		g_Hardpoint[currentPoint][0][2] = SQL_FetchFloat(results, z1);
		g_Hardpoint[currentPoint][1][0] = SQL_FetchFloat(results, x2);
		g_Hardpoint[currentPoint][1][1] = SQL_FetchFloat(results, y2);
		g_Hardpoint[currentPoint][1][2] = SQL_FetchFloat(results, z2);

		currentPoint++;
		g_Hardpoints++;
	}
}

void CreateHardpointTables()
{
	SQL_TQuery(g_Database, sql_GenericQuery, Hardpoint_Create_Query);
	LoadCurrentMap()
	return;
}

void LoadCurrentMap()
{
	char loadQuery[1024];
	char mapName[PLATFORM_MAX_PATH];

	switch(g_Engine)
	{
		case Engine_CSGO:
		{
			GetCurrentMap(mapName, sizeof(mapName));
			RemoveMapPath(mapName, mapName, sizeof(mapName));
		}

		default:
		{
			GetCurrentMap(mapName, sizeof(mapName));
		}
	}

	Format(loadQuery, sizeof(loadQuery), "SELECT * FROM hardpoint_table WHERE map_name = '%s';", mapName);
	SQL_TQuery(g_Database, sql_LoadMap, loadQuery);
	return;
}

void StartDatabaseConnection()
{
	if(!SQL_CheckConfig("hardpoint_database"))
	{
		PrintToServer("[Hardpoint] hardpoint_database config not found in sourcemod/config/databases.cfg! Aborting.");
		LogError("[Hardpoint] hardpoint_database config not found in sourcemod/config/databases.cfg! Aborting.");
		SetFailState("[Hardpoint] hardpoint_database config not found in sourcemod/config/databases.cfg! Aborting.");
		return;
	}

	char dbType[16];
	int dbInt;
	g_Hardpoint_DBType.GetString(dbType, sizeof(dbType));

	if(StrEqual(dbType, "mysql", false) || StrEqual(dbType, "1", false)) dbInt = 1; //MySQL
	else dbInt = 2; //SQLite

	switch(dbInt)
	{
		//MySQL:
		case 1:
		{
			SQL_TConnect(sql_ConnectCB, "hardpoint_database");
			return;
		}

		//SQLite:
		case 2:
		{
			char sqlError[256];
			g_Database = SQLite_UseDatabase("hardpoint_database", sqlError, sizeof(sqlError));
			if(g_Database == INVALID_HANDLE)
			{
				PrintToServer("[Hardpoint] SQLite Error: %s", sqlError);
				LogError("[Hardpoint] SQLite Error: %s", sqlError);
				SetFailState("[Hardpoint] SQLite Initialization Error. View Error Logs for more information.");
				return;
			}
		}
	}

	return;
}

void InsertHardpoint(float hardPoint[2][3])
{
	char insertQuery[1024];
	char mapName[PLATFORM_MAX_PATH];

	switch(g_Engine)
	{
		case Engine_CSGO:
		{
			GetCurrentMap(mapName, sizeof(mapName));
			RemoveMapPath(mapName, mapName, sizeof(mapName));
		}

		default:
		{
			GetCurrentMap(mapName, sizeof(mapName));
		}
	}

	Format(insertQuery, sizeof(insertQuery), "INSERT INTO hardpoint_table (hardpoint_x1, hardpoint_y1, hardpoint_z1, hardpoint_x2, hardpoint_y2, hardpoint_z2, map_name) VALUES (%.2f, %.2f, %.2f, %.2f, %.2f, %.2f, '%s');", hardPoint[0][0], hardPoint[0][1], hardPoint[0][2], hardPoint[1][0], hardPoint[1][1], hardPoint[1][2], mapName);
	SQL_TQuery(g_Database, sql_GenericQuery, insertQuery);
	return;
}

void DeleteHardpoint(int hardpoint_id)
{
	char deleteQuery[1024];
	char mapName[PLATFORM_MAX_PATH];

	switch(g_Engine)
	{
		case Engine_CSGO:
		{
			GetCurrentMap(mapName, sizeof(mapName));
			RemoveMapPath(mapName, mapName, sizeof(mapName));
		}

		default:
		{
			GetCurrentMap(mapName, sizeof(mapName));
		}
	}

	for(int i = 0; i < 10; i++)
	{
		if(g_HardpointID[i] == hardpoint_id)
		{
			g_HardpointID[i] = 0;
			for(int a = 0; a < 3; a++)
			{
				g_Hardpoint[i][0][a] = 0.0;
				g_Hardpoint[i][1][a] = 0.0;
			}
		}
	}

	Format(deleteQuery, sizeof(deleteQuery), "DELETE FROM hardpoint_table WHERE hardpoint_id = %i AND map_name = '%s';", hardpoint_id, mapName);
	SQL_TQuery(g_Database, sql_GenericQuery, deleteQuery);
	return;
}

//thx to powerdude for this functions:
bool SubString(const char[] source, int start, int len, char[] destination, int maxlen)
{
	if (maxlen < 1)
	{
		ThrowError("Destination size must be 1 or greater, but was %d", maxlen);
	}
	
	// optimization
	if (len == 0)
	{
		strcopy(destination, maxlen, "");
		return true;
	}
	
	if (start < 0)
	{
		// strlen doesn't count the null terminator, so don't -1 on it.
		start = strlen(source) + start;
		if (start < 0)
			start = 0;
	}
	
	if (len < 0)
	{
		len = strlen(source) + len - start;
		// If length is still less than 0, that'd be an error.
		if (len < 0)
			return false;
	}
	
	// Check to make sure destination is large enough to hold the len, or truncate it.
	// len + 1 because second arg to strcopy counts 1 for the null terminator
	int realLength = len + 1 < maxlen ? len + 1 : maxlen;
	
	strcopy(destination, realLength, source[start]);
	return true;
}

bool RemoveMapPath(const char[] map, char[] dest, int maxlen)
{
	if (strlen(map) < 1)
	{
		ThrowError("Bad map name: %s", map);
	}
	
	// UNIX paths
	int pos = FindCharInString(map, '/', true);
	if (pos == -1)
	{
		// Windows paths
		pos = FindCharInString(map, '\\', true);
		if (pos == -1)
		{
			//destination[0] = '\0';
			strcopy(dest, maxlen, map);
			return false;
		}
	}

	// strlen is last + 1
	int len = strlen(map) - 1 - pos;
	
	SubString(map, pos + 1, len, dest, maxlen);
	return true;
}

void GetMiddleOfABox(const float vec1[3], const float vec2[3], float buffer[3])
{
	float mid[3];
	MakeVectorFromPoints(vec1, vec2, mid);
	mid[0] = mid[0] / 2.0;
	mid[1] = mid[1] / 2.0;
	mid[2] = mid[2] / 2.0;
	AddVectors(vec1, mid, buffer);
}

stock bool IsbetweenRect(float Pos[3], float Corner1[3], float Corner2[3], int client = 0) 
{ 
    float Entity[3]; 
    float field1[2]; 
    float field2[2]; 
    float field3[2]; 
    
    if (!client)
    {
        Entity = Pos;
    }
    else GetClientAbsOrigin(client, Entity); 
     
    // Sort Floats... 
     
    if (FloatCompare(Corner1[0], Corner2[0]) == -1)  
    { 
        field1[0] = Corner1[0]; 
        field1[1] = Corner2[0]; 
    } 
    else 
    { 
        field1[0] = Corner2[0]; 
        field1[1] = Corner1[0]; 
    } 
    if (FloatCompare(Corner1[1], Corner2[1]) == -1)  
    { 
        field2[0] = Corner1[1]; 
        field2[1] = Corner2[1]; 
    } 
    else 
    { 
        field2[0] = Corner2[1]; 
        field2[1] = Corner1[1]; 
    } 
    if (FloatCompare(Corner1[2], Corner2[2]) == -1)  
    { 
        field3[0] = Corner1[2]; 
        field3[1] = Corner2[2]; 
    } 
    else 
    { 
        field3[0] = Corner2[2]; 
        field3[1] = Corner1[2]; 
    } 
     
    // Check the Vectors ... 
     
    if (Entity[0] < field1[0] || Entity[0] > field1[1]) return false; 
    if (Entity[1] < field2[0] || Entity[1] > field2[1]) return false; 
    if (Entity[2] < field3[0] || Entity[2] > field3[1]) return false; 
     
    return true; 
}  

void Array_Copy(const any[] array, any[] newArray, size)
{
	for (int i=0; i < size; i++) 
	{
		newArray[i] = array[i];
	}
}

public SharedPlugin __pl_ircrelay = 
{
	name = "hardpoint",
	file = "hardpoint.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
 
#if !defined REQUIRE_PLUGIN
public void __pl_hardpoint_SetNTVOptional()
{

}
#endif