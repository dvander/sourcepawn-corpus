#include <sourcemod>
#include "mvm_menu.maphelper.sp"
#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "Randomize mission on map start",
	author = "bovril",
	description = "Randomize mission on map start",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("mapchangerestartround_version", VERSION, "Randomize mission on map start", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	generateMapData();
}

public OnMapStart()
{
	new Handle:popfileArray=getPopfilesForMap();
	if(popfileArray != INVALID_HANDLE){
		new arraySize = GetArraySize(popfileArray);
		new i = GetRandomInt(0, arraySize);
		decl String:difficulty[255];
		GetArrayString(popfileArray,i,difficulty,sizeof(difficulty));
		LogMessage("Changinging to %s",difficulty);
		ServerCommand("tf_mvm_popfile %s",difficulty);
	}
	else{
		LogMessage("PopfileArray invalid");
	}

}
