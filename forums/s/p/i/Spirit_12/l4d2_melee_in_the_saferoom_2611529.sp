#define VERSION "3.0.0"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Melee In The Saferoom
*	Author	:	$atanic $pirit, N3wton
*	Descrp	:	Spawns a selection of melee weapons in the saferoom, at the start of each round.
*	Plugins	:	https://forums.alliedmods.net/showpost.php?p=2611529&postcount=484

========================================================================================
	Change Log:

3.0.0 (22-Aug-2018 - Major rewrite)
	- Switched ConVar to support 3 options. (Custom limits, Random or Map Based)
	- Switched to transitional syntax.
	- Moved repetitive fucntions into loops and arrays for future expansion.
	- Fixed Melee spawning for second team in versus.
	- Added debugging support for the plugin.
	
2.0.7
	- Made my own vpk with only standard melee weapons unlocked (no knife or riot shield).
	- Precached all standard melee weapons.(it looks like without having something client side, knife and riot just won't work)

2.0.6
	- MasterMind420 posted a release which use MITSR 2.0.5 but with some new .vpk's to unlock weapons.
	- Repackaged .zip file and updated code to correct version

2.0.5
	- Add support for the sacrifice an no mercy.
	- Fixed a bug where hunter arms could be spawned.

2.0.4
	- Fixed a potential error where on campaign mode, melee weapons wouldn't spawn on any but the first map.

2.0.3
	- Added riot_shield to make sure people can get riot shields to spawn properly.
	- Added !melee (admin command) to list all spawnable melee weapons on current campaign.

2.0.2
	- Now spawns the default weapons, except for knives. Where it  spawns a huntingknife.

2.0.1
	- Quick (failing) test

2.0.0
	- Complete rewrite, from a blank document.
	-  Fixed all errors (hopefully, tested for on all campaigns with two people with no errors)
	-  Made all Melee weapons work with out any glitches (read how to setup for more information)
	- Now supports custom melee lists, e.g. spawn 4 knives, 1 golf club and 3 katans.
	- Cleaner faster code.

1.2.6
	- added tonfa to the cfg list of files.
	- more sure sv_allowdownload is on.

1.2.5
	- After many internal versions, trying to fix the glitches with unlocked melee weapons, I finally have one, which I believe works in all game modes. Basically, put the unlock_melee_weapons.vpk in your servers addon folder and this then downloads the individual files from the server to you clients on map start, because there all .txt files there all around 1 - 2kb each so they download instantly, enabling all melee weapons with no glitches and with audio.

1.2.0
	- Been a while since an update, and this isn't anything big, basically I've added an extra cvar for versus mode, if enabled both teams get the same melee weapons when set to random, to make it fair.

1.1.1
	- Right hopefully, hunter claws are 100% gone, now it finds out what weapons are aloud on that map, then picks from them.

1.1.0
	- Changed how the weapons spawn, hopfully fixing the hunter claws once and for all (Thanks DJ_WEST)
	- Fixed some typos
	- Removed !mitserror
	- NOTE: Please delete the old [L4D2]MeleeSafeRoom.cfg before using this plugin.
	- NOTE: This version is broken, reuploaded 1.0.5

1.0.5
	- Changed hunter claws check to check all cases (lower and higher caps)
	- Added !mitserror command to output all weapon models spawned to help with debugging.

1.0.4 
	- Added extra checking for spawn amounts.
	- Made sure knifes worked for edited servers.

1.0.3
	- A Quick Beta version used to check a hunter claws bug had been fixed.

1.0.2
	- Fixed Bug with weapons spawning in wrong place
	- Wrote better code for positioning and rotating melee weapons

1.0.1
	- Small bug fix (increased timer from round start)

1.0.0
	- Initial Release

========================================================================================
	Credit To:
	
	- SilverShot for his coding format style.
	- Fyren for his help with nested loops.

======================================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

// Setting up ConVar handles
ConVar Cvar_Enabled;
ConVar Cvar_WeaponSpawnType;
ConVar Cvar_WeaponRandomAmount;
ConVar Cvar_MapBaseAmount;
ConVar Cvar_Debug;
ConVar Cvar_Items[11];

// Global variables
int g_iMeleeClassCount;
int g_iMeleeRandomSpawn[20];
bool g_bMeleeSpawned;
char g_sMeleeClass[16][32];

// Setting up model array
char g_sMeleeModels [] [] =
{
	"models/weapons/melee/v_bat.mdl",
	"models/weapons/melee/v_cricket_bat.mdl",
	"models/weapons/melee/v_crowbar.mdl",
	"models/weapons/melee/v_electric_guitar.mdl",
	"models/weapons/melee/v_fireaxe.mdl",
	"models/weapons/melee/v_frying_pan.mdl",
	"models/weapons/melee/v_golfclub.mdl",
	"models/weapons/melee/v_katana.mdl",
	"models/weapons/melee/v_machete.mdl",
	"models/weapons/melee/v_tonfa.mdl",
	"models/weapons/melee/w_bat.mdl",
	"models/weapons/melee/w_cricket_bat.mdl",
	"models/weapons/melee/w_crowbar.mdl",
	"models/weapons/melee/w_electric_guitar.mdl",
	"models/weapons/melee/w_fireaxe.mdl",
	"models/weapons/melee/w_frying_pan.mdl",
	"models/weapons/melee/w_golfclub.mdl",
	"models/weapons/melee/w_katana.mdl",
	"models/weapons/melee/w_machete.mdl",
	"models/weapons/melee/w_tonfa.mdl"
};

// Setting up weapon names array
char g_sMeleeName [] [] =
{
	"baseball_bat",
	"cricket_bat",
	"crowbar",
	"electric_guitar",
	"fireaxe",
	"frying_pan",
	"golfclub",
	"knife",
	"katana",
	"machete",
	"tonfa"
};

// ====================================================================================================
// myinfo - Basic plugin information
// ====================================================================================================

public Plugin myinfo =
{
	name = "Melee In The Saferoom",
	author = "$atanic $pirit, N3wton",
	description = "Spawns a selection of melee weapons in the saferoom, at the start of each round.",
	version = VERSION
};

// ====================================================================================================
// AskPluginLoad2 - Checking if Left4Dead 2?
// ====================================================================================================

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "Melee in the Saferoom only supports Left 4 Dead 2.");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

// ====================================================================================================
// OnPluginStart - Creating Convars, Hooking RoundStart and Registering Command
// ====================================================================================================

public void OnPluginStart()
{
	// Create Convars
	CreateConVar( "l4d2_MITSR_Version",		VERSION, "The version of Melee In The Saferoom"); 
	Cvar_Enabled			= CreateConVar( "l4d2_MITSR_Enabled",		"1", "Should the plugin be enabled", _, true, 0.0, true, 1.0);
	Cvar_WeaponSpawnType	= CreateConVar( "l4d2_MITSR_Spawn_Type",		"2", "0 = Custom list, 1 = Random Weapon and 2 = Map based weapons.", _, true, 0.0, true, 2.0);
	Cvar_WeaponRandomAmount	= CreateConVar( "l4d2_MITSR_Random_Amount",	"10","Number of weapons to spawn if l4d2_MITSR_Spawn_Type is set to 1.", _, true, 0.0, true, 10.0);
	Cvar_MapBaseAmount		= CreateConVar( "l4d2_MITSR_MapBase_Amount",	"1", "Number multiple if l4d2_MITSR_Spawn_Type is set to 2.", _, true, 0.0, true, 4.0);
	Cvar_Debug				= CreateConVar( "l4d2_MITSR_Debug",			"0", "0 = off, 1 = Chat message, 2 = Log to file. Check logs/meleeinthesaferoom.txt", _, true, 0.0, true, 2.0);
		
	Cvar_Items[0] 			= CreateConVar( "l4d2_MITSR_BaseballBat",	"1", "Number of baseball bats to spawn (l4d2_MITSR_Spawn_Type must be 0)", _, true, 0.0, true, 10.0);
	Cvar_Items[1] 			= CreateConVar( "l4d2_MITSR_CricketBat", 	"1", "Number of cricket bats to spawn (l4d2_MITSR_Spawn_Type must be 0)", _, true, 0.0, true, 10.0);
	Cvar_Items[2] 			= CreateConVar( "l4d2_MITSR_Crowbar", 		"1", "Number of crowbars to spawn (l4d2_MITSR_Spawn_Type must be 0)", _, true, 0.0, true, 10.0);
	Cvar_Items[3]			= CreateConVar( "l4d2_MITSR_ElecGuitar",		"1", "Number of electric guitars to spawn (l4d2_MITSR_Spawn_Type must be 0)", _, true, 0.0, true, 10.0);
	Cvar_Items[4]			= CreateConVar( "l4d2_MITSR_FireAxe",		"1", "Number of fireaxes to spawn (l4d2_MITSR_Spawn_Type must be 0)", _, true, 0.0, true, 10.0);
	Cvar_Items[5]			= CreateConVar( "l4d2_MITSR_FryingPan",		"1", "Number of frying pans to spawn (l4d2_MITSR_Spawn_Type must be 0)", _, true, 0.0, true, 10.0);
	Cvar_Items[6]			= CreateConVar( "l4d2_MITSR_GolfClub",		"1", "Number of golf clubs to spawn (l4d2_MITSR_Spawn_Type must be 0)", _, true, 0.0, true, 10.0);
	Cvar_Items[7]			= CreateConVar( "l4d2_MITSR_Knife",			"1", "Number of knifes to spawn (l4d2_MITSR_Spawn_Type must be 0)", _, true, 0.0, true, 10.0);
	Cvar_Items[8]			= CreateConVar( "l4d2_MITSR_Katana",			"1", "Number of katanas to spawn (l4d2_MITSR_Spawn_Type must be 0)", _, true, 0.0, true, 10.0);
	Cvar_Items[9]			= CreateConVar( "l4d2_MITSR_Machete",		"1", "Number of machetes to spawn (l4d2_MITSR_Spawn_Type must be 0)", _, true, 0.0, true, 10.0);
	Cvar_Items[10]			= CreateConVar( "l4d2_MITSR_Tonfa",			"1", "Number of tonfas to spawn (l4d2_MITSR_Spawn_Type must be 0)", _, true, 0.0, true, 10.0);
	
	// Autocreate the config file
	AutoExecConfig( true, "l4d2_melee_in_the_saferoom" );
	
	// Hooking round start
	HookEvent( "round_start", Event_RoundStart );
	
	// Register client command
	RegAdminCmd( "sm_melee",	Command_SMMelee,	ADMFLAG_KICK, "Lists all melee weapons spawnable in current campaign" ); 
}

// ====================================================================================================
// Command_SMMelee - Command function to list all available melee weapoms.
// ====================================================================================================

public Action Command_SMMelee( int client, int args )
{	
	for( int i; i < g_iMeleeClassCount; i++ )
	{
		PrintToChat( client, "%d : %s", i, g_sMeleeClass[i] );
	}
	return Plugin_Handled;
}

// ====================================================================================================
// OnMapStart - Precache melee weapon models and scripts
// ====================================================================================================

public void OnMapStart()
{
	int len;

	// Get size of models array
	len = sizeof(g_sMeleeModels);
	
	// Precache Melee Models
	for(int i; i < len; i++)
	{
		PrecacheModel( g_sMeleeModels[i], true );
	}
	
	// Get size of scripts array
	len = sizeof(g_sMeleeName);
	
	// Precache Melee Scripts
	char buffer[32];
	
	for( int i; i < len; i++ )
	{
		Format(buffer, sizeof(buffer), "scripts/melee/%s.txt", g_sMeleeName[i]);
		PrecacheModel( buffer, true );
	}
}

// ====================================================================================================
// Event_RoundStart - Creating timer to spawn melee weapons
// ====================================================================================================

public Action Event_RoundStart( Event event, const char[] name, bool dontBroadcast )
{
	if( !Cvar_Enabled.BoolValue ) 
		return Plugin_Continue;
	
	g_bMeleeSpawned = false;
	
	CreateTimer( 1.0, Timer_SpawnMelee );
	LogAcitivity( "Function::Event_RoundStart - Melee spawn timer created.");
	
	return Plugin_Continue;
}

// ====================================================================================================
// Timer_SpawnMelee - Main function to decide if Random, Map Based or Preset spawns
// ====================================================================================================

public Action Timer_SpawnMelee( Handle timer )
{
	int client = GetInGameClient();

	LogAcitivity( "Function::Timer_SpawnMelee - Checking for valid Client ID: %d.", client);
	
	if( client != 0 && !g_bMeleeSpawned )
	{
		// Get Melee weapons allowed on the map
		GetMeleeClasses();
	
		LogAcitivity( "Function::Timer_SpawnMelee - Valid client found: %d, %N.", client, client);
		int Limit;
		float SpawnPosition[3]; 
		float SpawnAngle[3];
		GetClientAbsOrigin( client, SpawnPosition );
		SpawnPosition[2] += 20; SpawnAngle[0] = 90.0;
		
		if( Cvar_WeaponSpawnType.IntValue == 1 )
		{
			int RandomMelee;
			int FirstHalf = IsGameInFirstHalf();
			LogAcitivity( "Function::Timer_SpawnMelee - This %s First Half.", FirstHalf? "is" : "is not");
			Limit = Cvar_WeaponRandomAmount.IntValue;
			
			for( int i; i < Limit; i++ )
			{	
				// First Half
				if(FirstHalf)
				{
					RandomMelee = GetRandomInt( 0, g_iMeleeClassCount );
					g_iMeleeRandomSpawn[i] = RandomMelee;
					LogAcitivity( "Function::Timer_SpawnMelee - First Half Random Melee: %N.", g_iMeleeRandomSpawn[i] );
				}
				// Second Half
				else
				{
					RandomMelee = g_iMeleeRandomSpawn[i];
					LogAcitivity( "Function::Timer_SpawnMelee - Second Half Random Melee: %N.", g_iMeleeRandomSpawn[i] );
				}
				
				// Spawn the Melee weapon
				SpawnMelee( g_sMeleeClass[RandomMelee], SpawnPosition, SpawnAngle );
			}
		}
		else if( Cvar_WeaponSpawnType.IntValue == 2 )
		{
			int iCount;
			Limit = Cvar_MapBaseAmount.IntValue;
			for( int i; i < g_iMeleeClassCount; i++)
			{
				if( i == (g_iMeleeClassCount-1) )
				{
					i = 0;
					iCount++;
					LogAcitivity( "Function::Timer_SpawnMelee - Reset loop, iCount: %d", i, iCount );
				}
				
				if( iCount == Limit )
				{
					LogAcitivity( "Function::Timer_SpawnMelee - iCount: %d reached limit of %d. Breaking the loop.", iCount, Limit );
					break;
				}
				// Spawn the Melee weapon
				SpawnMelee( g_sMeleeClass[i], SpawnPosition, SpawnAngle );
			}
		}
		else
		{
			SpawnCustomList( SpawnPosition, SpawnAngle );
		}
		
		g_bMeleeSpawned = true;
		return Plugin_Stop;
	}
	
	else if( !g_bMeleeSpawned ) 
	{
		CreateTimer( 1.0, Timer_SpawnMelee );
	}
	
	return Plugin_Handled;
}

// ====================================================================================================
// SpawnCustomList - Spawn custom list respecting ConVar values 
// ====================================================================================================

stock void SpawnCustomList( float Position[3], float Angle[3] )
{
	char ScriptName[32];
	
	int len = sizeof(Cvar_Items);
	
	for(int x; x < len; x++)
	{
		for(int i; i < Cvar_Items[x].IntValue; i++ )
		{
			GetScriptName( g_sMeleeName[x], ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
			LogAcitivity( "Function::SpawnCustomList - %s spawned", g_sMeleeName[x] );
		}
	}
}

// ====================================================================================================
// SpawnMelee - Main stock to spawn weapons
// ====================================================================================================

stock void SpawnMelee( char Class[32], float Position[3], float Angle[3] )
{
	float SpawnPosition[3];
	float SpawnAngle[3];
	SpawnPosition = Position;
	SpawnAngle = Angle;
	
	SpawnPosition[0] += ( -10 + GetRandomInt( 0, 20 ) );
	SpawnPosition[1] += ( -10 + GetRandomInt( 0, 20 ) );
	SpawnPosition[2] += GetRandomInt( 0, 10 );
	SpawnAngle[1] = GetRandomFloat( 0.0, 360.0 );

	int MeleeSpawn = CreateEntityByName( "weapon_melee" );
	DispatchKeyValue( MeleeSpawn, "melee_script_name", Class );
	DispatchSpawn( MeleeSpawn );
	TeleportEntity(MeleeSpawn, SpawnPosition, SpawnAngle, NULL_VECTOR );
}

// ====================================================================================================
// GetMeleeClasses - Store melee class names from map to our global variable
// ====================================================================================================

stock void GetMeleeClasses()
{
	int MeleeStringTable = FindStringTable( "MeleeWeapons" );
	g_iMeleeClassCount = GetStringTableNumStrings( MeleeStringTable );
	
	int len = sizeof(g_sMeleeClass);
	
	for( int i = 0; i < g_iMeleeClassCount; i++ )
	{
		ReadStringTable( MeleeStringTable, i, g_sMeleeClass[i], len );
		LogAcitivity( "Function::GetMeleeClasses - Getting melee classes: %s", g_sMeleeClass[i]);
	}	
}

// ====================================================================================================
// GetScriptName - Get the script name matching our weapon class
// ====================================================================================================

stock void GetScriptName( char[] Class, char[] ScriptName )
{
	for( int i = 0; i < g_iMeleeClassCount; i++ )
	{
		if( StrContains( g_sMeleeClass[i], Class, false ) == 0 )
		{
			Format( ScriptName, 31, "%s", g_sMeleeClass[i] );
			return;
		}
	}
	Format( ScriptName, 31, "%s", g_sMeleeClass[0] );	
}

// ====================================================================================================
// GetScriptName - Get the script name based on weapon class
// ====================================================================================================

stock int GetInGameClient()
{
	for( int i = 1; i <= GetClientCount( true ); i++ )
	{
		if( IsClientInGame( i ) && GetClientTeam( i ) == 2 )
		{
			return i;
		}
	}
	return 0;
}

// ====================================================================================================
// IsGameInFirstHalf - Check if the game is in first half for our Ramdom weapon spawns
// ====================================================================================================

stock bool IsGameInFirstHalf()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound") ? false : true;
}

// ====================================================================================================
// LogAcitivity - Debug information
// ====================================================================================================

stock void LogAcitivity(const char[] format, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	if(Cvar_Debug.IntValue == 1)
	{
		char Tag[] = "\x04[\x05MITS\x04] \x01";
		PrintToChatAll("%s %s", Tag, buffer);
	}
	
	if(Cvar_Debug.IntValue == 2)
	{
		// Build LogFile path
		char LogFilePath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, LogFilePath, sizeof(LogFilePath), "logs/meleeinthesaferoom.txt");
		
		LogToFile(LogFilePath, "%s", buffer);
	}
}