#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "boomix"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>

public Plugin myinfo = 
{
	name = "Multiple player boost ",
	author = PLUGIN_AUTHOR,
	description = "Multiple player boost",
	version = PLUGIN_VERSION,
	url = "http://burst.lv"
};

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	
	int ent = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	
	if(ent > 0)
		SetEntPropEnt(client, Prop_Send, "m_hGroundEntity", 0);
	
}
