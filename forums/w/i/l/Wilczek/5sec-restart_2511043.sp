#define PLUGIN_AUTHOR "Wilk"
#define PLUGIN_VERSION "0.10"
#include <sourcemod>

EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "5 sec restart",
	author = PLUGIN_AUTHOR,
	description = "Restart the game after 5 seconds from map start",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
}

public OnMapStart()
{  
    CreateTimer(1.0, Timer_RestartGame);
} 

public Action Timer_RestartGame(Handle Timer)
{
    ServerCommand("mp_restartgame 5");
}