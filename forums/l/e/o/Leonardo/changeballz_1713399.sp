#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

new Handle:sm_tf2cb_version = INVALID_HANDLE;

new String:strModells[][] =
{
	"models/props_gameplay/ball001.mdl",
	"models/player/items/scout/soccer_ball.mdl",
	"models/weapons/w_models/w_baseball.mdl"
};

public Plugin:myinfo =
{
	name = "TF2 Change Ballz",
	author = "Leonardo",
	description = "Changes Baseballs To Another Balls",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net/"
};

public OnPluginStart()
{
	sm_tf2cb_version = CreateConVar( "sm_tf2cb_version", PLUGIN_VERSION, "TF2 Change Ballz", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED );
	SetConVarString( sm_tf2cb_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_tf2cb_version, OnConVarChanged_PluginVersion );
	
	decl String:sGameDir[8];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	if( !StrEqual(sGameDir, "tf", false) && !StrEqual(sGameDir, "tf_beta", false) )
		SetFailState("THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!");
}

public OnMapStart()
{
	for( new i = 0; i < sizeof(strModells); i++ )
		PrecacheModel( strModells[i], true );	
}

public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( strcmp( strNewValue, PLUGIN_VERSION, true ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );

public OnEntityCreated( iEntity, const String:strClassname[] )
{
	if( strcmp( strClassname, "tf_projectile_stun_ball", false ) == 0 )
		SDKHook( iEntity, SDKHook_SpawnPost, OnBallSpawned );
}

public OnBallSpawned( iEntity )
{
	SetEntityModel( iEntity, strModells[ GetRandInt( 0, sizeof(strModells)-1 ) ] );
}

stock _:GetRandInt( _:min, _:max, _:seed = 0 )
{
	SetRandomSeed( seed != 0 ? seed : RoundFloat(GetEngineTime()) );
	return GetRandomInt( min, max );
}