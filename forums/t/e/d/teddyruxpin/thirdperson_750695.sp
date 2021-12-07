//Includes:
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"


public Plugin:myinfo = 

{
	name = "L4D 3rd Person View enabler",
	author = "Teddy Ruxpin",
	description = "L4D 3rd Person Enabler",
	version = PLUGIN_VERSION,
	url = "http://blacktusklabs.com"
};

public OnPluginStart()

{

	CreateConVar("sm_l4d_3rdperson_enable_version", PLUGIN_VERSION, "L4D 3rd Person Enabler", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetCommandFlags("thirdpersonshoulder",GetCommandFlags("thirdpersonshoulder")^FCVAR_CHEAT)
	SetCommandFlags("thirdperson_mayamode",GetCommandFlags("thirdperson_mayamode")^FCVAR_CHEAT)
	SetCommandFlags("thirdperson",GetCommandFlags("thirdperson")^FCVAR_CHEAT)
	SetCommandFlags("firstperson",GetCommandFlags("firstperson")^FCVAR_CHEAT)
}
