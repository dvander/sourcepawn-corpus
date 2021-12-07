#pragma semicolon 1
#include < sourcemod >
#include < sdktools >
#include < sdktools_sound >
#include < sdktools_tempents_stocks >

#define PLUGIN_VERSION "1.1"
#define MAX_FILE_LEN 80
new g_Lightning;
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

public Plugin:myinfo = 
{
	name = "Admin Thunder",
	author = "aNNakin, edit by R3M",
	description = "Slays a player with a lightning bolt and thunder sound",
	version = "1.1",
	url = "http://forums.alliedmods.net/"
}

public OnPluginStart ( )
{
	CreateConVar("sm_thunder_version", PLUGIN_VERSION, "Admin Thunder Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd ( "sm_thunder", thunder_cmd, ADMFLAG_SLAY );
	g_CvarSoundName = CreateConVar("sm_thunder_sound", "ambient/weather/thunderstorm/lightning_strike_2.wav", "Thunder Sound");
}

public OnConfigsExecuted()
{
	GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(g_soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	AddFileToDownloadsTable(buffer);
}

public OnMapStart ( )
{

	g_Lightning = PrecacheModel ( "sprites/lgtning.vmt" );
}

public Action:thunder_cmd (client, args)
{
	new String:s_Arg[ 32 ];
	GetCmdArg ( 1, s_Arg, sizeof s_Arg );
	
	new e_Target = FindTarget ( client, s_Arg );
	
	if ( e_Target == -1 )
		return Plugin_Handled;
	if ( ! IsPlayerAlive ( e_Target ) )
		return Plugin_Handled;
	
	// - - -
	new
	String:s_PlayerName[ 32 ], String:s_AdminName[ 32 ],
	Float:f_Origin[ 3 ], Float:f_StartOrigin[ 3 ],
	i_Color[ 4 ] = { 255, 255, 255, 255 };
	// - - -
	
	GetClientName ( client, s_AdminName, 31 );
	GetClientName ( e_Target, s_PlayerName, 31 );
	GetClientAbsOrigin ( e_Target, f_Origin );
	
	f_Origin[ 2 ] -= 26;
	f_StartOrigin[ 0 ] = f_Origin[ 0 ] + 150;
	f_StartOrigin[ 1 ] = f_Origin[ 1 ] + 150;
	f_StartOrigin[ 2 ] = f_Origin[ 2 ] + 800;
	
	TE_SetupBeamPoints( f_StartOrigin, f_Origin, g_Lightning, 0, 0, 0, 2.0, 10.0, 10.0, 0, 1.0, i_Color, 3 );
	TE_SendToAll ( );
	

	
	ForcePlayerSuicide ( e_Target );
	EmitSoundToAll (g_soundName);
	PrintToChatAll ( "Admin %s: Trucked-down player %s", s_AdminName, s_PlayerName );
	
	return Plugin_Handled;
}