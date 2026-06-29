#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1"

public Plugin:myinfo =
{
	name = "Beach Ball",
	author = "Burgerkern/Tylerst(Code)",
	description = "Changes Baseballs To Beach Balls",
	version = PLUGIN_VERSION,
	url = "None"
};

public OnPluginStart()
{
	TF2only();
	CreateConVar("sm_crushedcan_version", PLUGIN_VERSION, "TF2 Balls to Balls", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart()
{
	PrecacheModel("models/props_gameplay/ball001.mdl", true);	
}

public OnGameFrame()
{
	new entity = -1; 
	while ((entity=FindEntityByClassname(entity, "tf_projectile_stun_ball"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			SetEntityModel(entity, "models/props_gameplay/ball001.mdl"); 
		}
	}
}

TF2only()
{
	new String:Game[10];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		SetFailState("This plugin only works for TF2");
	}
}