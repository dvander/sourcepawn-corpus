#pragma semicolon 1

//////////////////////////////
//		DEFINITIONS			//
//////////////////////////////

#define PLUGIN_NAME "Show Nickname on HUD"
#define PLUGIN_AUTHOR "Zephyrus"
#define PLUGIN_DESCRIPTION "Show Nickname on HUD"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL ""

//////////////////////////////
//			INCLUDES		//
//////////////////////////////

#include <sourcemod>
#include <sdktools>

//////////////////////////////
//			ENUMS			//
//////////////////////////////

//////////////////////////////////
//		GLOBAL VARIABLES		//
//////////////////////////////////

new bool:g_bShown[MAXPLAYERS+1] = {false, ...};

//////////////////////////////
//			MODULES			//
//////////////////////////////

//////////////////////////////////
//		PLUGIN DEFINITION		//
//////////////////////////////////

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

//////////////////////////////
//		PLUGIN FORWARDS		//
//////////////////////////////

public OnPluginStart()
{
}

//////////////////////////////
//		CLIENT FORWARDS		//
//////////////////////////////

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(!client || !IsClientInGame(client))
        return Plugin_Continue;

    new target = GetClientAimTarget(client);
    if(target == -1)
    {
        if(g_bShown[client])
        {
            PrintHintText(client, "");
            g_bShown[client] = false;
        }
        return Plugin_Continue;
    }

    PrintHintText(client, "%N", target);
    g_bShown[client] = true;

    return Plugin_Continue;
}

//////////////////////////////
//			EVENTS			//
//////////////////////////////

//////////////////////////////
//		    COMMANDS	 	//
//////////////////////////////

//////////////////////////////
//			MENUS	 		//
//////////////////////////////

//////////////////////////////
//			CONVARS	 		//
//////////////////////////////

//////////////////////////////
//		SQL CALLBACKS		//
//////////////////////////////

//////////////////////////////
//			HOOKS			//
//////////////////////////////