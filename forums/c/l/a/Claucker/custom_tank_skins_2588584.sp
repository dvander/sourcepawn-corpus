#pragma semicolon 1

#include <sourcemod>  
#include <sdktools>

public Plugin myinfo = 
{
	name = "Custom Tank Skins",
	author = "Claucker",
	description = "Adds new tank skins",
	version = "0.1",
	url = ""
}

/*

												VARIABLES

*/

// INFECTED
#define MODEL_SPONGEBOBTANK		"models/custom_survivors/spongebobtank/hulk.mdl"
#define MODEL_ROSHANTANK		"models/custom_survivors/roshan/hulk.mdl"
#define MODEL_NIGHTTANK			"models/custom_survivors/nighttank/hulk_dlc3.mdl"
#define MODEL_HALOTANK			"models/custom_survivors/halotank/hulk.mdl"
#define MODEL_SIAMTANK			"models/custom_survivors/siamtank/hulk.mdl"
#define MODEL_BRUTILDA			"models/custom_survivors/brutilda/hulk.mdl"
#define MODEL_TEDDYTANK			"models/custom_survivors/teddytank/hulk.mdl"

int g_index = 0;

char g_tankModels[][] = { 
	
	MODEL_TEDDYTANK,
	MODEL_BRUTILDA,
	MODEL_SIAMTANK,
	MODEL_HALOTANK,
	MODEL_ROSHANTANK,
	MODEL_NIGHTTANK,
	MODEL_SPONGEBOBTANK
};

const int g_ammount = sizeof( g_tankModels );

/*

												FILES

*/

char TanksList[][] = {
	
	"materials/custom_model/siamtank/02.vmt",
	"materials/custom_model/siamtank/03.vmt",
	"materials/custom_model/siamtank/decap.vmt",
	"materials/custom_model/siamtank/meat.vmt",
	"materials/custom_model/siamtank/teeth.vmt",
	"materials/custom_model/siamtank/01.vmt",
	"materials/custom_model/siamtank/decap.vtf",
	"materials/custom_model/siamtank/meat.vtf",
	"materials/custom_model/siamtank/teeth.vtf",
	"materials/custom_model/siamtank/01.vtf",
	"materials/custom_model/siamtank/02.vtf",
	"materials/custom_model/siamtank/03.vtf",
	"models/custom_survivors/siamtank/hulk.mdl",
	"models/custom_survivors/siamtank/hulk.phy",
	"models/custom_survivors/siamtank/hulk.dx80.vtx",
	"models/custom_survivors/siamtank/hulk.dx90.vtx",
	"models/custom_survivors/siamtank/hulk.vtx",
	"models/custom_survivors/siamtank/hulk.vvd",
	"materials/custom_model/halotank/flood_tank_d.vmt",
	"materials/custom_model/halotank/flood_fronds_d.vmt",
	"materials/custom_model/halotank/flood_fronds_n.vtf",
	"materials/custom_model/halotank/flood_tank_d.vtf",
	"materials/custom_model/halotank/flood_tank_n.vtf",
	"materials/custom_model/halotank/flood_fronds_d.vtf",
	"models/custom_survivors/halotank/hulk.mdl",
	"models/custom_survivors/halotank/hulk.phy",
	"models/custom_survivors/halotank/hulk.vvd",
	"models/custom_survivors/halotank/hulk.dx90.vtx",
	"materials/custom_model/roshan/roshan_color.vmt",
	"materials/custom_model/nighttank/nightstalker_color.vmt",
	"materials/custom_model/spongebobtank/spongebob_m.vmt",
	"materials/custom_model/roshan/roshan_color.vtf",
	"materials/custom_model/roshan/roshan_normal.vtf",
	"materials/custom_model/roshan/coach_head_wrp.vtf",
	"materials/custom_model/nighttank/nightstalker_color.vtf",
	"materials/custom_model/nighttank/nightstalker_normal.vtf",
	"materials/custom_model/nighttank/coach_head_wrp.vtf",
	"materials/custom_model/spongebobtank/spongebob_n.vtf",
	"materials/custom_model/spongebobtank/spongebob_t.vtf",
	"models/custom_survivors/roshan/hulk.mdl",
	"models/custom_survivors/roshan/hulk.phy",
	"models/custom_survivors/roshan/hulk.vtx",
	"models/custom_survivors/roshan/hulk.vvd",
	"models/custom_survivors/roshan/hulk.dx90.vtx",
	"models/custom_survivors/nighttank/hulk_dlc3.mdl",
	"models/custom_survivors/nighttank/hulk_dlc3.phy",
	"models/custom_survivors/nighttank/hulk_dlc3.vtx",
	"models/custom_survivors/nighttank/hulk_dlc3.vvd",
	"models/custom_survivors/nighttank/hulk_dlc3.dx90.vtx",
	"models/custom_survivors/spongebobtank/hulk.mdl",
	"models/custom_survivors/spongebobtank/hulk.phy",
	"models/custom_survivors/spongebobtank/hulk.vvd",
	"models/custom_survivors/spongebobtank/hulk.dx90.vtx",	
	"materials/custom_model/teddytank/tank_color.vtf",
	"materials/custom_model/teddytank/hulk_01.vmt",
	"models/custom_survivors/teddytank/hulk.mdl",
	"models/custom_survivors/teddytank/hulk.phy",
	"models/custom_survivors/teddytank/hulk.vvd",
	"models/custom_survivors/teddytank/hulk.dx90.vtx",	
	"materials/custom_model/brutilda/image_0002.vmt",
	"materials/custom_model/brutilda/something.vmt",
	"materials/custom_model/brutilda/thingy.vmt",
	"materials/custom_model/brutilda/untitled.vmt",
	"materials/custom_model/brutilda/image_0000.vtf",
	"materials/custom_model/brutilda/image_0001.vtf",
	"materials/custom_model/brutilda/image_0002.vtf",
	"materials/custom_model/brutilda/something.vtf",
	"materials/custom_model/brutilda/thingy.vtf",
	"materials/custom_model/brutilda/untitled.vtf",
	"materials/custom_model/brutilda/image_0000.vmt",
	"materials/custom_model/brutilda/image_0001.vmt",
	"models/custom_survivors/brutilda/hulk.mdl",
	"models/custom_survivors/brutilda/hulk.phy",
	"models/custom_survivors/brutilda/hulk.vvd",
	"models/custom_survivors/brutilda/hulk.dx90.vtx"
};

/*

												FUNCTIONS

*/

public void PrecacheTankModelList()
{
	//Precache TANKS
	for (int i = 0; i < g_ammount; i++ )
	{
		PrecacheCustomModels( g_tankModels[ i ] );
	}
}

public void DownloadFilesFromArray ( char[][] file, int size )
{
	for ( int i = 0; i < size; i++ )
	{
		AddFileToDownloadsTable( file[i] );
	}
}

public void PrecacheCustomModels( const char[] MODEL )
{
	if (!IsModelPrecached(MODEL))
		PrecacheModel(MODEL, false);
}

/*

												GAME EVENTS

*/

public Action TankSpawn( Event event, const char[] name, bool dontBroadcast ) 
{
	int client =  GetClientOfUserId(GetEventInt(event, "userid")); 
	
	SetEntityModel( client, g_tankModels[ g_index ] );
	g_index++;
	
	g_index = ( g_index % ( g_ammount ) );
}

/*

												SOURCEPAWN EVENTS

*/

public OnPluginStart()  
{
	HookEvent("tank_spawn", TankSpawn);
}

public OnMapStart()
{
	//Download Model Files
	DownloadFilesFromArray( TanksList, sizeof( TanksList ) );
	
	//MODELS
	PrecacheTankModelList();
}