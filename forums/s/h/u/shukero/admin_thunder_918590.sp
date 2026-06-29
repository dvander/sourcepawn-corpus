#pragma semicolon 1
#include < sourcemod >
#include < sdktools >

#define PLUGIN_VERSION "1.2"
#define MAX_FILE_LEN 80
new g_Lightning, g_Smoke;
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

public Plugin:myinfo = 
{
	name = "Admin Thunder",
	author = "aNNakin, edit by R3M and Wazz",
	description = "Slays a player with a lightning bolt and thunder sound",
	version = "1.1",
	url = "http://forums.alliedmods.net/"
}

public OnPluginStart ( )
{
	CreateConVar("sm_thunder_version", PLUGIN_VERSION, "Admin Thunder Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd ( "sm_thunder", thunder_cmd, ADMFLAG_SLAY );
	g_CvarSoundName = CreateConVar("sm_thunder_sound", "ambient/explosions/explode_9.wav", "Thunder Sound");
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
	g_Smoke = PrecacheModel ( "sprites/steam1.vmt" );
	g_Lightning = PrecacheModel ( "sprites/lgtning.vmt" );
}

public Action:thunder_cmd (client, args)
{
	new String:s_Arg[ 32 ];
	GetCmdArg ( 1, s_Arg, sizeof s_Arg );
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			s_Arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		DoThunder(client, target_list[i]);
	}
	
	return Plugin_Handled;
}

DoThunder(admin, victim)
{
	if ( !IsPlayerAlive( victim ) )
		return;
	
	// - - -
	new Float:f_Origin[ 3 ], Float:f_StartOrigin[ 3 ],
	i_Color[ 4 ] = { 255, 255, 255, 255 };
	// - - -
	
	GetClientAbsOrigin ( victim, f_Origin );
	
	f_Origin[ 2 ] -= 26;
	f_StartOrigin[ 0 ] = f_Origin[ 0 ] + 150;
	f_StartOrigin[ 1 ] = f_Origin[ 1 ] + 150;
	f_StartOrigin[ 2 ] = f_Origin[ 2 ] + 800;
	
	TE_SetupBeamPoints( f_StartOrigin, f_Origin, g_Lightning, 0, 0, 0, 2.0, 10.0, 10.0, 0, 1.0, i_Color, 3 );
	TE_SendToAll ( );
	
	TE_SetupSmoke ( f_Origin, g_Smoke, 10.0, 10 );
	TE_SendToAll ( );
	
	ForcePlayerSuicide ( victim );
	EmitAmbientSound (g_soundName, f_Origin );
	ShowActivity2( admin, "[SM] ", "Struck down %N", victim );
}