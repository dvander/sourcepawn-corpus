#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1.1"

public Plugin:myinfo =
{
	name = "TF2 Bird Launcher",
	author = "Tylerst",
	description = "Changes rockets into birds",
	version = PLUGIN_VERSION,
	url = "None"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

new Handle:g_hRocketModel = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_birdlauncher_version", PLUGIN_VERSION, "Bird Launcher for TF2", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hRocketModel = CreateConVar("sm_birdlauncher_model", "models/props_forest/bird.mdl", "Model for the rockets");
	HookConVarChange(g_hRocketModel, CvarChange_RocketModel);	
}

public OnMapStart()
{
	new String:strRocketModel[128];
	GetConVarString(g_hRocketModel, strRocketModel, sizeof(strRocketModel));
	if(!IsModelPrecached(strRocketModel)) PrecacheModel(strRocketModel);	
}


public CvarChange_RocketModel(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
{
	if(!IsModelPrecached(strNewValue)) PrecacheModel(strNewValue);
}


public OnEntityCreated(entity, const String:classname[])
{
	if(IsValidEntity(entity) && entity > MaxClients && StrEqual(classname, "tf_projectile_rocket", false))
	{
		SDKHook(entity, SDKHook_SpawnPost, SDKHook_OnSpawnPost);
	}
}

public SDKHook_OnSpawnPost(entity)
{
	new String:strRocketModel[128];
	GetConVarString(g_hRocketModel, strRocketModel, sizeof(strRocketModel));
	if(IsModelPrecached(strRocketModel)) SetEntityModel(entity, strRocketModel);
}