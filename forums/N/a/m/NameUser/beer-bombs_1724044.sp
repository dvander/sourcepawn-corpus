#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
	name = "Beer Pipebombs",
	author = "Pierce 'NameUser' Strine",
	description = "mrh",
	version = PLUGIN_VERSION,
	url = "None"
};

public OnPluginStart()
{
	TF2only();
	CreateConVar("sm_beerbombs_version", PLUGIN_VERSION, "Beer Bombs", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart()
{
	PrecacheModel("models/props_gameplay/bottle001.mdl");	
}

public OnGameFrame()
{
	new entity = -1; 
	while ((entity=FindEntityByClassname(entity, "tf_projectile_pipe"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			SetEntityModel(entity, "models/props_gameplay/bottle001.mdl"); 
		}
	}
}