#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION "1.0"
new Handle:cvarTaskTime;
new String:g_szMap[32];


public Plugin:myinfo = 
{
	name = "Alone Server, Map Change",
	author = "graczu",
	description = "After mapchange, plugin start 120 sec. task that checking there are any players, if no plugin change map",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{

	CreateConVar("sm_alonemap_version", PLUGIN_VERSION, "Alone Map Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	CreateConVar(
		"sm_alone_map",
		"3mc_training",
		"Name of map that serwer will change if there is no clients.",
		FCVAR_PLUGIN
	);

	cvarTaskTime = CreateConVar(
		"sm_alone_time",
		"120",
		"Time after mapchange to check the server number of clients.",
		FCVAR_PLUGIN,
		true,
		30.0,
		true,
		300.0
	);

}

public OnMapStart(){

	new Float:DelayTime = GetConVarFloat(cvarTaskTime);
	CreateTimer(DelayTime, checkMap);

}

public Action:checkMap(Handle:timer){
	if(GetClientCount(true) <= 2){

		GetConVarString(FindConVar("sm_alone_map"), g_szMap, sizeof(g_szMap));

		decl String:mapformat[64];
		Format(mapformat, sizeof(mapformat), "/changelevel %s", g_szMap);

		LogMessage("TIME: %s : There is no players on server, changing map.", GetTime());
		InsertServerCommand(mapformat);
		ServerExecute();

	}
}