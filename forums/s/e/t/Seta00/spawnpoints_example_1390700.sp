#include <sourcemod>
#include "spawnpoints"


public OnPluginStart() {
	SC_Initialize("sc_test",
				  "sc_test_menu", ADMFLAG_GENERIC, 
				  "sc_test_add", ADMFLAG_GENERIC, 
				  "sc_test_del", ADMFLAG_GENERIC, 
				  "sc_test_show", ADMFLAG_GENERIC, 
				  "configs/sc_test",
				  10);
				  
	RegAdminCmd("sc_test_dump", DumpSpawnsInfo, ADMFLAG_GENERIC);
}

public Action:DumpSpawnsInfo(client, args) {
	new Handle:spawns = SC_GetSpawnsArray();
	new count = GetArraySize(spawns);
	new Float:spawn[3];
	
	ReplyToCommand(client, "Dumping %d spawn point%s", count, count == 1 ? "" : "s");
	for (new i = 0; i < count; ++i) {
		GetArrayArray(spawns, i, spawn);
		ReplyToCommand(client, "%2d - (.2f, .2f, .2f)", i, spawn[0], spawn[1], spawn[2]);
	}
	ReplyToCommand(client, "End of spawn points dump", count);
	
	return Plugin_Handled;
}

public OnMapStart() {
	SC_LoadMapConfig();
} 

public OnMapEnd() {
	SC_SaveMapConfig();
} 
