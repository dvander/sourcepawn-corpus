/**
 * SpecialAttack Zones
 * 2009-06-16 (VictorOfSweden)
 *
 * Regularly checks player locations.
 * If found to be in one of the user configurable zones, players are then filtered by team and class.
 * If a player passes the filters, a given command is executed (from the server console).
 *
 * Some code/ideas borrowed from:
 * - "Anti Barrier Jumping" <http://forums.alliedmods.net/showthread.php?t=63980>
 * - "Advertisements 0.5.5" <http://forums.alliedmods.net/showthread.php?p=592536>
 *
 */

/*
Sample Config
-------------

//Teams: ..., Red = 4, Blu = 8
//       Sum up the numbers corresponding to the teams you want to be affected (Red+Blu=12).
//Classes: Scout = 1, Soldier = 2, Pyro = 4, ...
//         Sum up the numbers corresponding to the classes you want to be affected (Scout+Pyro=5).
//Command: Available tolkens are: {CLIENT_NAME}, {CLIENT_STEAMID}, {CLIENT_USERID}, {CLIENT_LONG_ID}
//         To get regular "double" quotation marks ("), enter two single ones (''). They are converted automatically.
"Zones"
{
	"ctf_2fort"
	{
		"red_spawn"
		{
			"minx"		"175"
			"miny"		"1310"
			"minz"		"250"
			
			"maxx"		"800"
			"maxy"		"1630"
			"maxz"		"275"
			
			"teams"		"4"
			"classes"	"1"
			
			"command"	"say Hi ''{CLIENT_NAME}''! You are a red scout in front of red spawn on ''ctf_2fort''!"
		}
	}
}

*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

//NOTE: When compiling and uploading, please remove -dev suffix and increase version number
#define PLUGIN_VERSION "1.0.0"

#define AUTOEXEC_FILE "plugin.spa-zones"

#define LOG_FILE_DEBUG "addons/sourcemod/logs/spazones_debug.log"

public Plugin:myinfo =
{
	name = "SpecialAttack Zones",
	author = "SpecialAttack",
	description = "Executes commands when clients are located in predifined zones.",
	version = PLUGIN_VERSION,
	url = "http://www.specialattack.net/"
};

//CVAR handles
new Handle:g_cvar_enabled = INVALID_HANDLE;
new Handle:g_cvar_file = INVALID_HANDLE;
new Handle:g_cvar_interval = INVALID_HANDLE;
new Handle:g_cvar_debug = INVALID_HANDLE;

//KV handles
new Handle:g_kv_zones = INVALID_HANDLE;

//Timer handles
new Handle:g_timer_playercheck = INVALID_HANDLE;

//Called when the plugin is fully initialized and all known external references are resolved.
public OnPluginStart()
{
	//Create CVARs
	CreateConVar(
		"sm_spa_zones_version",
		PLUGIN_VERSION,
		_,
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_cvar_enabled = CreateConVar(
		"sm_spa_zones_enabled",
		"1",
		"Enable/disable player location checking.",
		0,
		true,
		0.0,
		true,
		1.0);
	g_cvar_file = CreateConVar(
		"sm_spa_zones_file",
		"configs/zones.txt",
		"The configuration file to load.");
	g_cvar_interval = CreateConVar(
		"sm_spa_zones_interval",
		"10",
		"Time (in seconds) between checking player locations.",
		0,
		true,
		1.0,
		true,
		3600.0);
	g_cvar_debug = CreateConVar(
		"sm_spa_zones_debug",
		"0",
		"Enable/disable debug output (to file & server console).",
		0,
		true,
		0.0,
		true,
		1.0);
	
	//Exec config
	AutoExecConfig(true, AUTOEXEC_FILE);
	
	//Hook changes of the check timer interval
	HookConVarChange(g_cvar_interval, CVAR_OnCheckIntervalChange);
	
	//Create timer
	g_timer_playercheck = CreateTimer(GetConVarFloat(g_cvar_interval), Timer_CheckClientLocations, _, TIMER_REPEAT);
	
	//Reload zones
	ReloadZones();
}

public OnMapStart()
{
	//Reload zones
	ReloadZones();
}

public CVAR_OnCheckIntervalChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	LogDebugMessage("Timer interval changed (new \"%s\") (old \"%s\")", newVal, oldVal);

	if( g_cvar_interval != INVALID_HANDLE )
	{
		KillTimer(g_timer_playercheck);
		g_timer_playercheck = CreateTimer(GetConVarFloat(g_cvar_interval), Timer_CheckClientLocations, _, TIMER_REPEAT);
	}
}

public OnConfigsExecuted()
{
	AutoExecConfig(true, AUTOEXEC_FILE);
}

ReloadZones()
{
	//Reset the kv handle
	if (g_kv_zones != INVALID_HANDLE)
	{
		CloseHandle(g_kv_zones);
	}
	g_kv_zones = CreateKeyValues("Zones");
	
	//Get partial path off cvar
	decl String:filepartialpath[256];
	GetConVarString(g_cvar_file, filepartialpath, sizeof(filepartialpath));
	
	//Build full path
	decl String:filepath[256];
	BuildPath(Path_SM, filepath, sizeof(filepath), filepartialpath);
	
	//Check for existance
	if ( !FileExists(filepath) )
	{
		LogError("Cannot find file \"%s\"!", filepath);
		return;
	}
	
	//Load the file
	FileToKeyValues(g_kv_zones, filepath);
}

//Called regularly to check player locations
public Action:Timer_CheckClientLocations(Handle:timer)
{
	if ( g_cvar_enabled != INVALID_HANDLE && GetConVarBool(g_cvar_enabled) )
	{
		LogDebugMessage("Starting checking...");
		
		//Rewind the kv handle
		KvRewind(g_kv_zones);
		
		//Get map name
		decl String:mapname[32];
		GetCurrentMap(mapname, sizeof(mapname));
		
		//Jump to map key
		if ( !KvJumpToKey(g_kv_zones, mapname) )
		{
			LogDebugMessage("No key for map \"%s\"!", mapname);
			return Plugin_Continue;
		}
		
		//Jump to first subkey of current map
		if ( !KvGotoFirstSubKey(g_kv_zones) )
		{
			LogDebugMessage("No subkeys for map \"%s\"!", mapname);
			return Plugin_Continue;
		}
		
		//Declare variables
		decl String:minx_string[16];
		decl String:miny_string[16];
		decl String:minz_string[16];
		new Float:mincoords[3];
		
		decl String:maxx_string[16];
		decl String:maxy_string[16];
		decl String:maxz_string[16];
		new Float:maxcoords[3];
		
		decl String:teams_string[4]; new teams;
		decl String:classes_string[4]; new classes;
		
		decl String:command_string[512];
		
		//Iterate over the map subkeys
		do
		{
			//Get key name
			decl String:key_name[128];
			KvGetSectionName(g_kv_zones, key_name, sizeof(key_name));
			
			LogDebugMessage("Parsing key \"%s\"...", key_name);
			
			//Get min coords
			KvGetString(g_kv_zones, "minx", minx_string, sizeof(minx_string)); mincoords[0] = StringToFloat(minx_string);
			KvGetString(g_kv_zones, "miny", miny_string, sizeof(miny_string)); mincoords[1] = StringToFloat(miny_string);
			KvGetString(g_kv_zones, "minz", minz_string, sizeof(minz_string)); mincoords[2] = StringToFloat(minz_string);
			
			//Get max coords
			KvGetString(g_kv_zones, "maxx", maxx_string, sizeof(maxx_string)); maxcoords[0] = StringToFloat(maxx_string);
			KvGetString(g_kv_zones, "maxy", maxy_string, sizeof(maxy_string)); maxcoords[1] = StringToFloat(maxy_string);
			KvGetString(g_kv_zones, "maxz", maxz_string, sizeof(maxz_string)); maxcoords[2] = StringToFloat(maxz_string);
			
			//Get teams, classes and command
			KvGetString(g_kv_zones, "teams", teams_string, sizeof(teams_string), "15"); teams = StringToInt(teams_string);
			KvGetString(g_kv_zones, "classes", classes_string, sizeof(classes_string), "511"); classes = StringToInt(classes_string);
			KvGetString(g_kv_zones, "command", command_string, sizeof(command_string));
			
			//Iterate over clients
			for ( new client = 1; client <= MaxClients; client++ )
			{
				//Make sure we have a proper client
				if ( !IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) )
				{
					continue;
				}
				
				LogDebugMessage("Checking client \"%L\"...", client);
				
				//Check client location
				if ( !IsClientInCube(client, mincoords, maxcoords) )
				{
					LogDebugMessage("Client is not in cube.");
					continue;
				}
				else
				{
					LogDebugMessage("Client is in cube.");
				}
				
				//Check client location
				if ( !FilterClient(client, teams, classes) )
				{
					LogDebugMessage("Client didn't pass team/class filter.");
					continue;
				}
				else
				{
					LogDebugMessage("Client passed team/class filter.");
				}
				
				//Log the event (to game and sm logs)
				LogToGame("\"%L\" found in hotzone (map \"%s\") (key \"%s\")", client, mapname, key_name);
				LogMessage("\"%L\" found in hotzone (map \"%s\") (key \"%s\")", client, mapname, key_name);
				
				//Format command string
				FormatCommandString(command_string, sizeof(command_string), client);
				
				//Execute command
				ServerCommand(command_string);
			}
		}
		while ( KvGotoNextKey(g_kv_zones) );
		
		LogDebugMessage("Done checking.");
	}
	
	return Plugin_Continue;
}

//Filters the client by team and class. Returns true if the client matches both filters, otherwise false.
bool:FilterClient(client, teams, classes)
{
	//Get client team
	new client_team = 1 << GetClientTeam(client);
	
	//Get player class
	new TFClassType:player_class = TF2_GetPlayerClass(client);
	new player_class_int;
	
	switch(player_class)
	{
		case 1:
			player_class_int = 1 << 0;
		case 3:
			player_class_int = 1 << 1;
		case 7:
			player_class_int = 1 << 2;
		case 4:
			player_class_int = 1 << 3;
		case 6:
			player_class_int = 1 << 4;
		case 9:
			player_class_int = 1 << 5;
		case 5:
			player_class_int = 1 << 6;
		case 2:
			player_class_int = 1 << 7;
		case 8:
			player_class_int = 1 << 8;
		default:
			player_class_int = 511;
	}
	
	//Log debug info (c=client info, f=filter, p=c&f)
	LogDebugMessage("Team: c=%d f=%d p=%d", client_team, teams, (client_team & teams));
	LogDebugMessage("Class: c=%d f=%d p=%d", player_class_int, classes, (player_class_int & classes));
	
	//Store filter results as booleans
	new bool:filterTeams = ( (client_team & teams) > 0 );
	new bool:filterClasses = ( (player_class_int & classes) > 0 );
	
	//Return the combined result
	return ( filterTeams && filterClasses );
}

//Tests to see if a client is in the cube defined by max/min coords
bool:IsClientInCube(client, Float:minCoords[3], Float:maxCoords[3])
{
	//Get player coords
	new Float:playerCoords[3];
	GetClientAbsOrigin(client, playerCoords);
	
	//Log debug info
	LogDebugMessage("Client is at: %f %f %f", playerCoords[0], playerCoords[1], playerCoords[2]);
	//LogDebugMessage("Min at: %f %f %f", minCoords[0], minCoords[1], minCoords[2]);
	//LogDebugMessage("Max at: %f %f %f", maxCoords[0], maxCoords[1], maxCoords[2]);
	
	//Store check results as booleans
	new bool:inX = ( playerCoords[0] >= minCoords[0] && playerCoords[0] <= maxCoords[0] );
	new bool:inY = ( playerCoords[1] >= minCoords[1] && playerCoords[1] <= maxCoords[1] );
	new bool:inZ = ( playerCoords[2] >= minCoords[2] && playerCoords[2] <= maxCoords[2] );
	
	//Return the combined result
	return ( inX && inY && inZ );
}

//Formats the command string by parsing tolkens
FormatCommandString(String:commandbuffer[], maxlength, client)
{
	//Declare buffer
	decl String:infobuffer[128];
	
	//Convert quotes
	if ( StrContains(commandbuffer, "''") != -1 )
	{
		ReplaceString(commandbuffer, maxlength, "''", "\"");
	}
	
	//Client name
	if ( StrContains(commandbuffer, "{CLIENT_NAME}") != -1 )
	{
		GetClientName(client, infobuffer, sizeof(infobuffer));
		ReplaceString(commandbuffer, maxlength, "{CLIENT_NAME}", infobuffer);
	}
	
	//Client number
	if ( StrContains(commandbuffer, "{CLIENT_USERID}") != -1 )
	{
		new userid = GetClientUserId(client);
		Format(infobuffer, sizeof(infobuffer), "%i", userid);
		ReplaceString(commandbuffer, maxlength, "{CLIENT_USERID}", infobuffer);
	}
	
	//Client SteamID
	if ( StrContains(commandbuffer, "{CLIENT_STEAMID}") != -1 )
	{
		GetClientAuthString(client, infobuffer, sizeof(infobuffer));
		ReplaceString(commandbuffer, maxlength, "{CLIENT_STEAMID}", infobuffer);
	}
	
	//Client long ID
	if ( StrContains(commandbuffer, "{CLIENT_LONG_ID}") != -1 )
	{
		Format(infobuffer, sizeof(infobuffer), "%L", client);
		ReplaceString(commandbuffer, maxlength, "{CLIENT_LONG_ID}", infobuffer);
	}
}

public OnPluginEnd()
{
	KillTimer(g_timer_playercheck);
	CloseHandle(g_kv_zones);
}

//Function to log debug messages
LogDebugMessage(const String:message[], any:...)
{
	if( g_cvar_debug != INVALID_HANDLE && GetConVarBool(g_cvar_debug) )
	{
		decl String:buffer[256];
		VFormat(buffer, sizeof(buffer), message, 2);
		LogToFile(LOG_FILE_DEBUG, buffer);
	}
}
