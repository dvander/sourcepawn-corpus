#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "boomix"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
//#include <sdkhooks>

EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "Web motd test",
	author = PLUGIN_AUTHOR,
	description = "Web scrollbar test",
	version = PLUGIN_VERSION,
	url = "http://burst.lv"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	RegConsoleCmd("sm_webtest", CMD_WebTest);
	RegConsoleCmd("sm_webtest2", CMD_WebTest2);
	
}

public Action CMD_WebTest(int client, int args)
{
	ShowMOTDPanel(client, "Motdtest", "http://37.203.36.42/mapvote/redirect.php?url=http://37.203.36.42/test/", MOTDPANEL_TYPE_URL);	
	return Plugin_Handled;
}

public Action CMD_WebTest2(int client, int args)
{
	ShowMOTDPanel(client, "Motdtest2", "http://37.203.36.42/mapvote/redirect.php?url=http://37.203.36.42/test/index2.html", MOTDPANEL_TYPE_URL);	
	return Plugin_Handled;		
}