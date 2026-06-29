#include <sourcemod>
#include <sdktools>
#include <dukehacks>

#define PLUGIN_VERSION "0.0.1.0"

public Plugin:myinfo =
{
	name = "rocket model",
	author = "L. Duke",
	description = "rocket model",
	version = PLUGIN_VERSION,
	url = "http://www.lduke.com/"
};


#define MDL_PIPE "models/props/cake/cake.mdl"

new Handle:cvModel = INVALID_HANDLE;
new String:model[512];


public OnPluginStart()

{
	CreateConVar("sm_prk_version", PLUGIN_VERSION, "Rocket Model version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvModel = CreateConVar("sm_prk_model", MDL_PIPE, "model for rockets");

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

	if (StrEqual(classname, "tf_projectile_rocket"))

	{

		SetEntityModel(edict, model);

	}

	return;

}



