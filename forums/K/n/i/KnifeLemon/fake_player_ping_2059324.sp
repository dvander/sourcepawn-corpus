#include<sourcemod>
#include<sdktools>
#include<sdkhooks>

#define PLUGIN_VERSION "1.0"

new g_Player_Manager = 0;

new Handle:g_CvarEnable;
new Handle:g_CvarFPPing = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Fake Player Ping",
	author = "KnifeLemon",
	description = "Player have fake ping",
	version = PLUGIN_VERSION,
	url = "http://knifelemon.wordpress.com/"
};

public OnPluginStart()
{
	CreateConVar("sm_fpp_version", PLUGIN_VERSION, "fake player ping plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CvarEnable = CreateConVar("sm_fpp_enable", "1", "FPP plugin on = 1 , off = 0");
	g_CvarFPPing = CreateConVar("sm_fpp_ping", "999", "get fake ping to all player Enable = -1 ~ 999 , Disabled = None");
	
	AutoExecConfig(true, "FakePlayerPing");
}

public OnMapStart()
{
	g_Player_Manager = FindEntityByClassname(-1, "cs_player_manager");
}

public OnClientPutInServer(Client)
{
	SDKHook(Client, SDKHook_PreThinkPost, OnPreThinkPost);
}

public OnPreThinkPost(client)
{
	new on = GetConVarInt(g_CvarEnable);
	if(on == 1)
	{
		if(JoinCheck(client))
		{
			if(IsValidEdict(g_Player_Manager))
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					SetEntProp(g_Player_Manager, Prop_Send, "m_iPing", 0, _, i);
					if(JoinCheck(i))
					{
						SetEntProp(g_Player_Manager, Prop_Send, "m_iPing", GetConVarInt(g_CvarFPPing), _, i);
					}
				}
			}
		}
	}
}

stock bool:JoinCheck(Client)
{
	if(Client > 0 && Client <= MaxClients)
	{
		if(IsClientConnected(Client) == true)
		{
			if(IsClientInGame(Client) == true)
			{
				return true;
			}
			else return false;
		}
		else return false;
	}
	else return false;
}