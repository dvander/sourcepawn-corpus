#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
	name = "Gman Jarate",
	author = "Pierce 'NameUser' Strine",
	description = "Wake up and smell the ashes",
	version = PLUGIN_VERSION,
	url = "None"
};

public OnPluginStart()
{
	TF2only();
	CreateConVar("sm_gmanjarate_version", PLUGIN_VERSION, "Gman Jarate for TF2", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart()
{
	PrecacheModel("models/gman.mdl");	
}

public OnGameFrame()
{
	new entity = -1; 
	while ((entity=FindEntityByClassname(entity, "tf_projectile_jar"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			SetEntityModel(entity, "models/gman.mdl"); 
		}
	}
}

TF2only()
{
	new String:Game[10];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		SetFailState("This plugin only works for Team Fortress 2");
	}
}