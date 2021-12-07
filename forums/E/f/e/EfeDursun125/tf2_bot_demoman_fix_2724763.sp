#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION  "1.0"

public Plugin myinfo = 
{
	name = "[TF2] Demoman Bot Sticky Fix",
	author = "EfeDursun125",
	description = "Demoman Bots now automatically detonate sticky bombs.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

enum TFClassType
{
	TFClass_Unknown = 0,
	TFClass_Scout,
	TFClass_Sniper,
	TFClass_Soldier,
	TFClass_DemoMan,
	TFClass_Medic,
	TFClass_Heavy,
	TFClass_Pyro,
	TFClass_Spy,
	TFClass_Engineer
};

float CheckTimer[MAXPLAYERS + 1];

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse)
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(CheckTimer[client] < GetGameTime())
			{
				if(IsPlayerAlive(client))
				{
					if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
					{
						int iSticky = -1; 
						
						while((iSticky = FindEntityByClassname(iSticky, "tf_projectile_pipe_remote")) != INVALID_ENT_REFERENCE)
						{
							if(IsValidEntity(iSticky))
							{
								for(int search = 1; search <= MaxClients; search++)
								{
									if(IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
									{
										float stickyOrigin[3];
										float searchOrigin[3];
										GetClientAbsOrigin(search, searchOrigin);
										GetEntPropVector(iSticky, Prop_Send, "m_vecOrigin", stickyOrigin);
										
										if(GetVectorDistance(stickyOrigin, searchOrigin) < 80.0)
										{
											if(GetEntPropEnt(iSticky, Prop_Send, "m_hThrower") == client)
											{
												buttons |= IN_ATTACK2;
											}
										}
									}
								}
							}
						}
					}
				}
				
				CheckTimer[client] = GetGameTime() + 1.0;
			}
		}
	}
	
	return Plugin_Continue;
}

stock TFClassType TF2_GetPlayerClass(int client) // for tf2classic support (from tf2_stocks.inc)
{
	return view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_iClass"));
}

bool IsValidClient(int client) 
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
        return false;
     
    return true;
}
