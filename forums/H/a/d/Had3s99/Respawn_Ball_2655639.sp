#include <sourcemod>
#include <smlib>
#include <sdktools>
#include <morecolors>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_NAME "Respawn Ball", 
#define PLUGIN_AUTHOR "Had3s99",
#define PLUGIN_DESC "Respawn Balle Foot",
#define PLUGIN_VERSION "1.0",
#define PLUGIN_URL "lastfate.fr"

Handle g_hTimerEnter;

public Plugin myinfo = {
	name = PLUGIN_NAME
	author = PLUGIN_AUTHOR
	description = PLUGIN_DESC
	version = PLUGIN_VERSION
	url = PLUGIN_URL
};

public void OnMapStart() {
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	
	if(StrContains(mapname, "ba_jail_electric_razor_v6", false) == 0 || StrContains(mapname, "ba_jail_electric_razor_go", false) == 0)
		g_hTimerEnter = CreateTimer(0.1, EnterOrNot, _, TIMER_REPEAT);
	else
		PrintToServer("Please set the map ba_jail_electric_razor_v6 or ba_jail_electric_razor_go ! :)");
}

public void OnMapEnd() {
	if(g_hTimerEnter != null) {
		KillTimer(g_hTimerEnter);
		g_hTimerEnter = null;
	}
}

public Action EnterOrNot(Handle timer) {
	char entName[64];
	float Middle_Stadium[3] =  {-2764.00, -1024.00, 80.00};
	
	for(int i = 1; i <= 2048; i++) {
		if(IsValidEntity(i)) {
			Entity_GetName(i, entName, sizeof(entName));
			if(StrContains(entName, "ballon") != -1 && (CageFoot1(i) || CageFoot2(i))) {
				TeleportEntity(i, Middle_Stadium, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

bool CageFoot1(int ent) {
	float v[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", v);
	
	if(v[0] >= -2865.986816 && v[0] <= -2660.006348 && v[1] >= -228.250336 && v[1] <= -173.291168 && v[2] >= 60.00 && v[2] <= 120.00)
		return true;
	else
		return false;
}

bool CageFoot2(int ent) {
	float v[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -2867.968750 && v[0] <= -2662.000244 && v[1] >= -1874.708740 && v[1] <= -1819.318726 && v[2] >= 60.0 && v[2] <= 120.0)
		return true;
	else
		return false;
}