#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME				"Weestwood rm door remover"
#define PLUGIN_VERSION			"v1.1"
#define PLUGIN_DESCRIPTION		"Remove doors on de_westwood_rm map"

char mapname[64];

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = "Nerus, fixed by root",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/"
}

public void OnMapStart()
{
	GetCurrentMap(mapname, sizeof(mapname));
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strncmp(mapname, "de_westwood", 8) == 0)
		if(StrEqual(classname, "func_physbox", false))
			CreateTimer(0.1, RemoveDelay, entity);
}

public Action RemoveDelay(Handle timer, any data)
{
	if(IsValidEntity(data))
		RemoveEdict(data);

	return Plugin_Stop;
}
