#pragma semicolon 1
#pragma newdecls required

#include <modelch>


public Plugin myinfo =  {
	name = "CS:GO Disable agent models (mmcs.pro)",
	author = "SAZONISCHE",
	description = "",
	version = "1.0",
	url = "mmcs.pro"
};

public Action MdlCh_PlayerSpawn(int client, bool custom, char[] model, int model_maxlen, char[] vo_prefix, int prefix_maxlen) {
	if (custom && GetClientTeam(client) >= 2){
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

