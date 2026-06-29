/******************************************************************************
	ABSBotMoney
	Austinbots!

	Sets the starting money for bots.
	
	Requires Metamod:Source, Sourcemod
	
******************************************************************************/
#include <sourcemod>
#define VERSION "1.1"

new g_iAccount = -1;
new bool:g_firstround = true;
new Handle:botmoney;

public Plugin:myinfo = 
{
	name = "[CSS+CSGO] ABSBotMoney",
	author = "Austinbots",
	description = "Sets starting money for bots.",
	version = VERSION,
	url = ""
}

public OnPluginStart()
{
	PrintToServer("ABSBotMoney Loaded - Version: %s", VERSION);
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	botmoney = CreateConVar("sm_botmoney","1000","Amount of Money To Give Bots at the start of a map.", _, true, 0.0, true, 1000.0);
	HookEvent("player_spawn", PlayerSpawnEvent);
	HookEvent("round_end", RoundEndEvent);
}

public OnMapStart()
{
	g_firstround = true;
}

public Action:RoundEndEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new reason = GetEventInt(event, "reason");	
    if( reason == 15) //#Game_Commencing, game begin
        g_firstround = true;
	else
	    g_firstround = false; 
}

public Action:PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	CreateTimer(0.1, timer_PlayerSpawn, client);
}  

public Action:timer_PlayerSpawn(Handle:timer, any:client)
{
	if(g_firstround) 
		if(IsClientInGame(client) && IsFakeClient(client))
			if (g_iAccount != -1)
				SetEntData(client, g_iAccount, GetConVarInt(botmoney));
}


