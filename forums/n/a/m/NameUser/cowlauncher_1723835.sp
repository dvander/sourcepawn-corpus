#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
	name = "Cow Launcher",
	author = "Pierce 'NameUser' Strine",
	description = "You are stoopid, said the cows.",
	version = PLUGIN_VERSION,
	url = "None"
};

public OnPluginStart()
{
	TF2only();
	CreateConVar("sm_cowlauncher_version", PLUGIN_VERSION, "Cow Launcher for TF2", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart()
{
	PrecacheModel("models/props_2fort/cow001_reference.mdl");	
}

public OnGameFrame()
{
	new entity = -1; 
	while ((entity=FindEntityByClassname(entity, "tf_projectile_rocket"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			SetEntityModel(entity, "models/props_2fort/cow001_reference.mdl"); 
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