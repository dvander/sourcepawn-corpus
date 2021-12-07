#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "codingcow"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Spec Block",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(!IsFakeClient(client) && !IsPlayerAlive(client))
	{
		int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		
		if(GetClientTeam(client) != GetClientTeam(target))
		{
			for (int i = 0; i <= MAXPLAYERS + 1; i++)
			{
				if(i != client)
				{
					if(GetClientTeam(client) == GetClientTeam(i))
					{
						SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", i);
						break;
					}
				}
			}
		}
	}
}
