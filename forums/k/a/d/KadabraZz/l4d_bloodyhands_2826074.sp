#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>

ConVar g_hCvarEnable, g_hBloodyHands;
bool g_bCvarEnable;
int g_iBloodyHands;

#define PLUGIN_VERSION 		"1.0-2024/8/11" //By HarryPotter aka fbef0102

public Plugin myinfo =
{
	name = "[L4D1 & L4D2] BloodyHands",
	author = "KadabraZz",
	description = "You can control whether the hunter spawns with bloody hands.",
	version = "PLUGIN_VERSION",
	url = "https://forums.alliedmods.net/showthread.php?p=2826074"
}

bool g_bL4D2Version;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion test = GetEngineVersion();

    if( test == Engine_Left4Dead )
    {
        g_bL4D2Version = false;
    }
    else if( test == Engine_Left4Dead2 )
    {
        g_bL4D2Version = true;
    }
    else
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

bool 
	g_bSetHand[MAXPLAYERS+1];

public void OnPluginStart() 
{
	g_hCvarEnable 		= CreateConVar( "l4d_bloodyhands_enable",        "1",   "0=Plugin off, 1=Plugin on.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hBloodyHands 		= CreateConVar( "l4d_bloodyhands_skin",			 "1",	"0 = Disable \n1 = 100% of chance \n2 = 50% of chance", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	CreateConVar("l4d_bloodyhands_version",	PLUGIN_VERSION,	"BloodyHands plugin version.",	FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY); 

	AutoExecConfig(true,	"l4d_bloodyhands");

	GetCvars();
	g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hBloodyHands.AddChangeHook(ConVarChanged_Cvars);

	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("ghost_spawn_time", Event_GhostSpawnTime); // when player enter "count down", how long until they become a ghost
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("tank_frustrated", Event_TankFrustrated); // when tank frustrated and pass
}

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarEnable = g_hCvarEnable.BoolValue;
	g_iBloodyHands = g_hBloodyHands.IntValue;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!g_bCvarEnable || !client || !IsClientInGame(client) || GetClientTeam(client) != L4D_TEAM_INFECTED)
		return;

	if(IsPlayerAlive(client) && g_bSetHand[client] == false)
	{
		BloodyHands(client);
		g_bSetHand[client] = true;
	}
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!g_bCvarEnable || !client || !IsClientInGame(client))
		return;

	g_bSetHand[client] = false;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!g_bCvarEnable || !client || !IsClientInGame(client))
		return;

	g_bSetHand[client] = false;
}

void Event_GhostSpawnTime(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!g_bCvarEnable || !client || !IsClientInGame(client))
		return;

	g_bSetHand[client] = false;
}

void Event_TankFrustrated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!g_bCvarEnable || !client || !IsClientInGame(client))
		return;

	g_bSetHand[client] = false;
}

public void L4D_OnEnterGhostState(int client)
{
	if(!g_bCvarEnable) return;

	if (GetClientTeam(client) == L4D_TEAM_INFECTED && g_bSetHand[client] == false)
	{
		if (GetEntProp(client, Prop_Send, "m_zombieClass") == 3)
		{
			BloodyHands(client);
			g_bSetHand[client] = true;
		}
	}
}

void BloodyHands(int client)
{
	//PrintToChatAll("%N", client);
	if (IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		if (GetEntProp(client, Prop_Send, "m_zombieClass") == 3)
		{
			switch (g_iBloodyHands)
			{
				case 0:
				{
					if(!g_bL4D2Version) SetEntPropFloat(client, Prop_Send, "m_bloodyHandsPercent", 0.0);
					else SetEntProp(client, Prop_Send, "m_iBloodyHandsLevel", 0);
				}
				case 1:
				{
					if(!g_bL4D2Version) SetEntPropFloat(client, Prop_Send, "m_bloodyHandsPercent", 1.0);
					else SetEntProp(client, Prop_Send, "m_iBloodyHandsLevel", 10);
				}
				case 2:
				{
					switch(GetRandomInt(1, 2))
					{
						case 1:
						{
							if(!g_bL4D2Version) SetEntPropFloat(client, Prop_Send, "m_bloodyHandsPercent", 0.0);
							else SetEntProp(client, Prop_Send, "m_iBloodyHandsLevel", 0);
						}
						case 2:
						{
							if(!g_bL4D2Version) SetEntPropFloat(client, Prop_Send, "m_bloodyHandsPercent", 1.0);
							else SetEntProp(client, Prop_Send, "m_iBloodyHandsLevel", 10);
						}
					}
				}
				default:
				{
						if(!g_bL4D2Version) SetEntPropFloat(client, Prop_Send, "m_bloodyHandsPercent", 0.0);
						else SetEntProp(client, Prop_Send, "m_iBloodyHandsLevel", 0);
				}
			}
		}
	}
}
