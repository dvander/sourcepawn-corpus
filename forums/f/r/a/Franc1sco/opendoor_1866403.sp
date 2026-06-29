#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new iEnt;
new const String:EntityList[][] = { "func_door", "func_movinglinear" };


public Plugin:myinfo =
{
	name = "SM Door opener",
	author = "Franc1sco Steam: franug",
	description = "open the door pls :p",
	version = "1.0",
	url = "www.servers-cfg.foroactivo.com"
};


public OnPluginStart()
{
	RegAdminCmd("sm_cell", OpenDoor, ADMFLAG_GENERIC);
}

public Action:OpenDoor(client,args)
{
    	for(new i = 0; i < sizeof(EntityList); i++)
        while((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
            	AcceptEntityInput(iEnt, "Open");
}