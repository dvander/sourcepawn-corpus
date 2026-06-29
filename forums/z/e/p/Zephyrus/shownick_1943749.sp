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

    decl String:m_szOutput[96];
    decl String:m_szName[64];
    GetClientName(target, m_szName, sizeof(m_szName));
    new m_iLen = strlen(m_szName)/2;
    if(m_iLen < 18)
    {
        for(new i=0;i<18-m_iLen;++i)
            m_szOutput[i] = '\n';
        strcopy(m_szOutput[18-m_iLen], sizeof(m_szOutput)-m_iLen, m_szName);
    }
    else
        strcopy(m_szOutput, sizeof(m_szOutput), m_szName);
    PrintHintText(client, "\n%s", m_szOutput);
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