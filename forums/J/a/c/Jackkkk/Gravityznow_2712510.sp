#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	
	name = "Gravity",
	
	author = "Jack",

	description = "Toggle gravity as vip",

	version = "1.0",
	
	url = "None"

};



bool lowGrav[MAXPLAYERS+1];

public OnPluginStart()
{
    RegAdminCmd("sm_grav", Command_Grav, ADMFLAG_CUSTOM4, "Toggle gravity for vip");
}

public Action Command_Grav(int client, int args)
{
    lowGrav[client] = !lowGrav[client];
    SetEntityGravity(client, lowGrav[client] ? 0.5 : 1.0);
    return Plugin_Handled;
}