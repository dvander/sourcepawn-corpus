#include <sourcemod>
#include <sdktools>
#include <dukehacks>

#define PLUGIN_VERSION "0.0.1.0"

public Plugin:myinfo =
{
	name = "pipe bomb model",
	author = "L. Duke",
	description = "pipe bomb model",
	version = PLUGIN_VERSION,
	url = "http://www.lduke.com/"
};

#define MDL_PIPE "models/props_junk/watermelon01.mdl"

new Handle:cvModel = INVALID_HANDLE;
new String:model[512];

public OnPluginStart()
{
	CreateConVar("sm_pbm_version", PLUGIN_VERSION, "Mushroom Health version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvModel = CreateConVar("sm_pbm_model", MDL_PIPE, "model for pipe bomb");
}


public OnConfigsExecuted()
{
	GetConVarString(cvModel, model, sizeof(model));
	PrecacheModel(model, true);
}


// entity listener
public ResultType:dhOnEntitySpawned(edict)
{
	// get class name
	new String:classname[64];
	GetEdictClassname(edict, classname, sizeof(classname)); 
	
	// is entity a rocket?
	if (StrEqual(classname, "tf_projectile_pipe"))
	{
		SetEntityModel(edict, model);
	}
	return;
}

