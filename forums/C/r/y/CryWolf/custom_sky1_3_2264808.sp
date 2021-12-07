/*
	
	-------------------------------------------------------------
		Cusom SKY Changer
		v1.3 by CryWolf
	
	- Provides realtime sky change features
	- Auto precache the needed sky texture (bouth .VMT and .VTF files)
	- Simple code
	- Extra config features (cfg/sourcemod/skychanger.cfg)
	
	-------------------------------------------------------------
*/
	
	
#include < sourcemod >
#include < sdktools >

#pragma semicolon 1


// Plugin Information
#define PLUGIN_VERSION	"1.3"
#define INDEX 0

// pCvarS:
new Handle:cvarEnabled;
new Handle:cvarSkybox;


public Plugin:myinfo =
{
	name = "Sky Changer",
	author = "CryWolf",
	description = "Provides Sky changer feature",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=258603"
};

public OnPluginStart ( )
{
	cvarEnabled = CreateConVar ( "sm_custom_sky", "1.0", "Skybox plugin on / off", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	cvarSkybox  = CreateConVar ( "sm_skybox_name", "blood1_", "Skybox texture name", FCVAR_PLUGIN );
	
	// Load configuration file
	AutoExecConfig ( true, "skychanger" );
	
}

public OnMapStart ( )
{
	if ( GetConVarBool ( cvarEnabled ) ) {
		PrecacheSkyBoxTexture ( );
		ChangeSkyboxTexture ( );
	}
}

public PrecacheSkyBoxTexture ( ) 
{
	/****************************************************************************************************************/
	
	decl String:newskybox [ 32 ];
	GetConVarString ( cvarSkybox, newskybox, sizeof ( newskybox ) );
		
	decl String:skyname_download1 [ 128 ];
	Format ( skyname_download1, sizeof ( skyname_download1 ), "materials/skybox/%sup.vtf", newskybox );
	AddFileToDownloadsTable ( skyname_download1 );
	
	decl String:skyname_dld20 [ 128 ];
	Format ( skyname_dld20, sizeof ( skyname_dld20 ), "materials/skybox/%sdn.vtf", newskybox );
	AddFileToDownloadsTable ( skyname_dld20 );
	
	decl String:skyname_dld21 [ 128 ];
	Format ( skyname_dld21, sizeof ( skyname_dld21 ), "materials/skybox/%sft.vtf", newskybox );
	AddFileToDownloadsTable ( skyname_dld21 );
	
	decl String:skyname_dld22 [ 128 ];
	Format ( skyname_dld22, sizeof ( skyname_dld22 ), "materials/skybox/%slf.vtf", newskybox );
	AddFileToDownloadsTable ( skyname_dld22 );
	
	decl String:skyname_dld23 [ 128 ];
	Format ( skyname_dld23, sizeof ( skyname_dld23 ), "materials/skybox/%srt.vtf", newskybox );
	AddFileToDownloadsTable ( skyname_dld23 );
	
	decl String:skyname_dld24 [ 128 ];
	Format ( skyname_dld24, sizeof ( skyname_dld24 ), "materials/skybox/%sbk.vtf", newskybox );
	AddFileToDownloadsTable ( skyname_dld24 );
	
	/******************************End of VTF Texture*****************************************************************/
	
	decl String:skyname_download3 [ 128 ];
	Format ( skyname_download3, sizeof ( skyname_download3 ), "materials/skybox/%sup.vmt", newskybox );
	AddFileToDownloadsTable ( skyname_download3 );
	
	decl String:skyname_dld30 [ 128 ];
	Format ( skyname_dld30, sizeof ( skyname_dld30 ), "materials/skybox/%sdn.vmt", newskybox );
	AddFileToDownloadsTable ( skyname_dld30 );
	
	decl String:skyname_dld31 [ 128 ];
	Format ( skyname_dld31, sizeof ( skyname_dld31 ), "materials/skybox/%sft.vmt", newskybox );
	AddFileToDownloadsTable ( skyname_dld31 );
	
	decl String:skyname_dld32 [ 128 ];
	Format ( skyname_dld32, sizeof ( skyname_dld32 ), "materials/skybox/%slf.vmt", newskybox );
	AddFileToDownloadsTable ( skyname_dld32 );
	
	decl String:skyname_dld33 [ 128 ];
	Format ( skyname_dld33, sizeof ( skyname_dld33 ), "materials/skybox/%srt.vmt", newskybox );
	AddFileToDownloadsTable ( skyname_dld33 );
	
	decl String:skyname_dld34 [ 128 ];
	Format ( skyname_dld34, sizeof ( skyname_dld34 ), "materials/skybox/%sbk.vmt", newskybox );
	AddFileToDownloadsTable ( skyname_dld34 );
		
	/****************************End of VMT Textures******************************************************************/
}

public ChangeSkyboxTexture ( )
{
	if ( GetConVarBool ( cvarEnabled ) )
	{
		decl String:newskybox  [ 32 ];
		GetConVarString ( cvarSkybox, newskybox, sizeof ( newskybox ) );
		
		// If there is a convar set, change the skybox to it
		if ( strcmp ( newskybox, "", false ) !=0 )
		{
			// PrintToServer ( "[CSC] Changing the Skybox to %s", newskybox );
			DispatchKeyValue ( INDEX, "skyname", newskybox );
		}
	}
}