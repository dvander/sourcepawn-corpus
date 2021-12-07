#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION 	"1.0.0"

public Plugin myinfo = 
{
	name        = "[L4D1 AND L4D2] Dynamic Info In Hostname",
	author      = "Ernecio (Satanael)",
	description = "The plugin shows in Hostname the difficulty and the number of players in real time.",
	version     = PLUGIN_VERSION,
	url         = "https://steamcommunity.com/groups/American-Infernal"
};

/**
 * Called on pre plugin start.
 *
 * @param myself        Handle to the plugin.
 * @param late          Whether or not the plugin was loaded "late" (after map load).
 * @param error         Error message buffer in case load failed.
 * @param err_max       Maximum number of characters for error message buffer.
 * @return              APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!IsDedicatedServer())
	{
		strcopy( error, err_max, "This plugin is only supported on \"Dedicated Server\"" );
		return APLRes_Failure;
	}
	
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy( error, err_max, "This plugin can only be run in the \"Left 4 Dead 1/2\" Games!" );
		return APLRes_SilentFailure;
	}	
	return APLRes_Success;
}

static ConVar hCvar_HostNameEnabled;
static ConVar hCvar_HostNameModes;
static ConVar hCvar_HostNameData;
static ConVar hCvar_HostNameFormatFirst;
static ConVar hCvar_HostNameFormatSecond;
static ConVar hCvar_HostNameFormatThird;
static ConVar hCvar_HostNameDifficulty; 
static ConVar hCvar_HostNameCommand;
static ConVar hCvar_HostNameMaxPlayers;

static bool bCvar_HostNameEnabled;
static int  iCvar_HostNameModes;
static int  NumPlayers = 0;
static char sCvar_HostNameData[256];
static char sCvar_HostNameFormatFirst[256];
static char sCvar_HostNameFormatSecond[256];
static char sCvar_HostNameFormatThird[256];

/**
 * Called on plugin start.
 *
 * @noreturn
 */
public void OnPluginStart()
{
	CreateConVar("l4d_dynamic_info_in_hostname_version", PLUGIN_VERSION, "Dynamic Info In HostName Version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	
	hCvar_HostNameEnabled 		= CreateConVar("l4d_hostname_enable", 			"1", 				"Enables/Disables The Plugin. 0 = Plugin OFF, 1 = Plugin ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_HostNameModes 		= CreateConVar("l4d_hostname_modes", 			"1", 				"Select HostName Format Modes.\n1 = Show: Difficulty, HostName And Player Counter.\n2 = Show: Difficulty And HostName.\n3 = Show: HostName And Player Counter.", FCVAR_NOTIFY, true, 1.0, true, 3.0);
	hCvar_HostNameData 			= CreateConVar("l4d_hostname_data", 			"HostName", 		"Name of the server to be used", FCVAR_NOTIFY);
	hCvar_HostNameFormatFirst 	= CreateConVar("l4d_hostname_format_first", 	"[%s] %s [%d/%d]", 	"Firts HostName Format.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hCvar_HostNameFormatSecond 	= CreateConVar("l4d_hostname_format_second", 	"[%s] %s", 			"Second HostName Format.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hCvar_HostNameFormatThird 	= CreateConVar("l4d_hostname_format_third", 	"%s [%d/%d]", 		"Third HostName Format.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hCvar_HostNameDifficulty 	= FindConVar("z_difficulty");
	hCvar_HostNameCommand 		= FindConVar("hostname");
	hCvar_HostNameMaxPlayers 	= FindConVar("sv_maxplayers");
	
	hCvar_HostNameEnabled.AddChangeHook( Event_ConVarChanged );
	hCvar_HostNameModes.AddChangeHook( Event_ConVarChanged );
	hCvar_HostNameData.AddChangeHook( Event_ConVarChanged );
	hCvar_HostNameFormatFirst.AddChangeHook( Event_ConVarChanged );
	hCvar_HostNameFormatSecond.AddChangeHook( Event_ConVarChanged );
	hCvar_HostNameFormatThird.AddChangeHook( Event_ConVarChanged );
	hCvar_HostNameDifficulty.AddChangeHook( Event_ConVarChange_Difficulty );
	
//	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);
	AutoExecConfig( true, "l4d_dynamic_info_in_hostname" );
}

/**
 * Called on configs executed.
 *
 * @noreturn
 */
public void OnConfigsExecuted()
{
	GetCvars();
}

void Event_ConVarChanged( Handle hCvar, const char[] sOldValue, const char[] sNewValue )
{
    GetCvars();
}

void GetCvars()
{
	bCvar_HostNameEnabled = hCvar_HostNameEnabled.BoolValue;
	iCvar_HostNameModes = hCvar_HostNameModes.IntValue;
	hCvar_HostNameData.GetString( sCvar_HostNameData, sizeof( sCvar_HostNameData ) );
	TrimString( sCvar_HostNameData );
	hCvar_HostNameFormatFirst.GetString( sCvar_HostNameFormatFirst, sizeof( sCvar_HostNameFormatFirst ) );
	TrimString( sCvar_HostNameFormatFirst );
	hCvar_HostNameFormatSecond.GetString( sCvar_HostNameFormatSecond, sizeof( sCvar_HostNameFormatSecond ) );
	TrimString( sCvar_HostNameFormatSecond );
	hCvar_HostNameFormatThird.GetString( sCvar_HostNameFormatThird, sizeof( sCvar_HostNameFormatThird ) );
	TrimString( sCvar_HostNameFormatThird );
	
	DynamicHostname();
}

public void OnMapStart()
{	
	NumPlayers = 0;
}
 
public void OnClientConnected( int client )
{
	if ( IsFakeClient( client ) ) return;
	
	NumPlayers ++;
	DynamicHostname();
}

public void OnClientDisconnect( int client )
{
	if ( IsFakeClient( client ) ) return;
	
	NumPlayers --;
	DynamicHostname();
}

void Event_ConVarChange_Difficulty( Handle hCvar, const char[] sOldValue, const char[] sNewValue )
{
	if ( iCvar_HostNameModes == 3 ) return;
	
	DynamicHostname();
}

/****************************************************************************************************/
void DynamicHostname()
{
	if ( !bCvar_HostNameEnabled ) return;
	
	char sDifficulty[64];
	char sTempHostname[256];
	int  MaxPlayers;
	
	hCvar_HostNameDifficulty.GetString( sDifficulty, sizeof( sDifficulty ) );
	MaxPlayers = hCvar_HostNameMaxPlayers.IntValue;
	
	if ( strncmp( sDifficulty, "Easy", sizeof( sDifficulty ), false ) == 0 ) strcopy( sDifficulty, sizeof( sDifficulty ), "Easy" );   // Replace the default name of the current difficulty to new custom name.
	else if ( strncmp( sDifficulty, "Hard", sizeof( sDifficulty ), false ) == 0 ) strcopy( sDifficulty, sizeof( sDifficulty ), "Advanced" );
	else if ( strncmp( sDifficulty, "Impossible", sizeof( sDifficulty ), false ) == 0 ) strcopy( sDifficulty, sizeof( sDifficulty ), "Expert" );
	else strcopy ( sDifficulty, sizeof( sDifficulty ), "Normal" );
	
	if ( iCvar_HostNameModes == 1 ) 		Format( sTempHostname, sizeof( sTempHostname ), sCvar_HostNameFormatFirst, sDifficulty, sCvar_HostNameData, NumPlayers, MaxPlayers );
	else if ( iCvar_HostNameModes == 2 ) 	Format( sTempHostname, sizeof( sTempHostname ), sCvar_HostNameFormatSecond, sDifficulty, sCvar_HostNameData );
	else if ( iCvar_HostNameModes == 3 ) 	Format( sTempHostname, sizeof( sTempHostname ), sCvar_HostNameFormatThird, sCvar_HostNameData, NumPlayers, MaxPlayers );
	
	SetConVarString( hCvar_HostNameCommand, sTempHostname );
	
//	PrintToServer("[Hostname] Hostname loaded successfully!");
	ServerCommand("heartbeat");
}
/****************************************************************************************************/
	