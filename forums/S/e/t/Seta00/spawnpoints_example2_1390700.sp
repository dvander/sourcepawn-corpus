#include <sourcemod>
#include "spawnpoints"

public OnPluginStart() {
	SC_Initialize("sc_test2",
				  "", 0,
				  "", 0,
				  "", 0,
				  "sc_test2_show", ADMFLAG_GENERIC,
				  "sc_test2");
}

public OnMapStart()
	SC_LoadMapConfig();

public OnMapEnd()
	SC_SaveMapConfig();