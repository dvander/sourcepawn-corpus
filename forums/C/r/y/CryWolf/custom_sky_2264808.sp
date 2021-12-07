/*
	
	-------------------------------------------------------------
		Cusom SKY Changer
		v1.5.1 by CryWolf
	
	- Provides realtime sky change features
	- Auto precache the needed sky texture (bouth .VMT and .VTF files)
	- Simple code
	- Extra config features (cfg/sourcemod/skychanger.cfg)
	- removed FCAVR_PLUGIN deprechaced
	- removed details
	- new precache method
	- removed INDEX
	- public to void
	
	-------------------------------------------------------------
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// ConVar's
ConVar cvarEnabled;
ConVar cvarSkybox;

public Plugin myinfo =
{
	name = "Sky Changer",
	author = "CryWolf",
	description = "Provides Sky changer feature",
	version = "1.5.1",
	url = "https://forums.alliedmods.net/showthread.php?t=258603"
};

public OnPluginStart ( )
{
	cvarEnabled = CreateConVar ( "sm_custom_sky", "1.0", 		"Skybox plugin on / off" );
	cvarSkybox  = CreateConVar ( "sm_skybox_name", "blood1_", 	"Skybox texture name" );
	
	// Load configuration file
	AutoExecConfig ( true, "skychanger" );
}

public OnMapStart ( )
{
	if ( GetConVarBool ( cvarEnabled ) )
	{
		PrecacheSkyBoxTexture ( );
	
		if ( GetConVarBool ( cvarEnabled ) )
		{
			decl String: newskybox[32];
			GetConVarString ( cvarSkybox, newskybox, sizeof ( newskybox ) );
			
			if ( strcmp ( newskybox, "", false ) !=0 )
			{
				DispatchKeyValue ( 0, "skyname", newskybox );
			}
		}
	}
}

void PrecacheSkyBoxTexture ( ) 
{
	static char suffix [ ] [ ] =
	{
		"bk",
		"Bk",
		"dn",
		"Dn",
		"ft",
		"Ft",
		"lf",
		"Lf",
		"rt",
		"Rt",
		"up",
		"Up",
	};
	
	decl String:newskybox [ 32 ];
	GetConVarString ( cvarSkybox, newskybox, sizeof ( newskybox ) );
	char buffer[ 64];
	
	for ( int i = 0; i < sizeof ( suffix ); i++ )
	{
		FormatEx ( buffer, sizeof ( buffer ), "materials/skybox/%s%s.vtf", newskybox, suffix [ i ] );
		if ( FileExists ( buffer, false ) )
			AddFileToDownloadsTable ( buffer );
		        
		FormatEx ( buffer, sizeof ( buffer ), "materials/skybox/%s%s.vmt", newskybox, suffix [ i ] );
		if ( FileExists ( buffer, false ) )
			AddFileToDownloadsTable ( buffer );
	}
}
