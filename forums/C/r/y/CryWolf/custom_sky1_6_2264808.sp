/*

	-------------------------------------------------------------
		Cusom SKY Changer
		v1.3 by CryWolf

	- Provides realtime sky change features
	- Auto precache the needed sky texture (bouth .VMT and .VTF files)
	- Simple code
	- Extra config features (cfg/sourcemod/skychanger.cfg)

	-------------------------------------------------------------
	
	Custom Sky Changer
	    v1.6.2
	- Removed compile errors
	- updated new syntax
	- Set the sky to server and clients
	- Simplyfied download method.
	- Removed unnecessary code and checks
	
	to do:
	* Fix a way of disabling CS:GO 3D sky without affecting the sky cvar and enable 2d skybox
	* Add external .INI file
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// Plugin Information
#define PLUGIN_VERSION	"1.6.2"

// pCvarS:
new Handle:cvarEnabled;
new Handle:cvarSkybox;
ConVar SkyName;

public Plugin:myinfo =
{
	name = "Sky Changer",
	author = "CryWolf",
	description = "Provides Sky changer feature",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=258603"
};

public OnPluginStart()
{
	// CVARS
	cvarEnabled = CreateConVar ("sm_custom_sky", "1.0", "Skybox plugin on / off");
	cvarSkybox  = CreateConVar ("sm_skybox_name", "blood1_", "Skybox texture name");
	
	// Fiind sv_skyname cvar
	SkyName = FindConVar("sv_skyname");
	
	// Load and create configuration file
	AutoExecConfig(true, "skychanger");
}

public OnMapStart()
{
	if (!GetConVarBool (cvarEnabled))
		return;
	
	PrecacheSkyBoxTexture();
	ChangeSkyboxTexture();
}

public PrecacheSkyBoxTexture()
{
	static char suffix[][] =
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
	
	decl String:newskybox [32];
	GetConVarString (cvarSkybox, newskybox, sizeof(newskybox));
	char buffer[64];
	
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

public ChangeSkyboxTexture()
{
	decl String:newskybox [32];
	GetConVarString(cvarSkybox, newskybox, sizeof (newskybox));
	
	// If there is a convar set, change the skybox to it
	if( strcmp ( newskybox, "", false ) !=0)
	{
		// PrintToServer("[CSC] Changing the Skybox to %s", newskybox);
		DispatchKeyValue(0, "skyname", newskybox);
	}
}

public void OnClientConnected(int client)
{
	if (!GetConVarBool(cvarEnabled))
		return;
	
	decl String:newskybox[32];
	
	// Get server sm_customy_sky cvar and send it to client	
	GetConVarString(cvarSkybox, newskybox, sizeof(newskybox));
	SendConVarValue(client, SkyName, newskybox);
}