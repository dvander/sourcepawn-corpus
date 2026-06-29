/*
	Zoom Plugin for Half life 2 Death Match(and Other Half life Mod Games...)!!!
	
	Tested Games:
	* Half Life 2 Death Match

Changelog:

Date: 04.26.2009
Version: 1.0

	* Plugin release


					Author : Nargis 
					Steam ID : nalsis_v

					Thx for using my plugin ^^
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static bool:KeyBuffer[33] = false;
static bool:ZoomOn[33] = false;

public OnPluginStart()
{
	HookEvent("player_spawn", Event_Spawn);
}

public Event_Spawn(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new Client = GetClientOfUserId(GetEventInt(Spawn_Event, "userid"));
	SetEntProp(Client,    Prop_Send, "m_bDrawViewmodel",  1);
	SetEntProp(Client,    Prop_Send, "m_iFOV", 90);
	ZoomOn[Client] = false;
}

public OnGameFrame()
{
	decl MaxPlayer;
	MaxPlayer = GetMaxClients();

	for(new Client = 1; Client <= MaxPlayer; Client++)
	{
		if(IsClientConnected(Client) && IsClientInGame(Client))
		{
			if(GetClientButtons(Client) & IN_ATTACK2)
			{
				if(!KeyBuffer[Client])
				{
					new String:WeaponNamed[64];
					GetClientWeapon(Client, WeaponNamed, sizeof(WeaponNamed)); 
					if(StrEqual(WeaponNamed, "weapon_crossbow"))
					{
						KeyBuffer[Client] = true;
					}else{
						if(ZoomOn[Client])
						{
							ZoomOn[Client] = false;
							KeyBuffer[Client] = true;
							SetEntProp(Client,    Prop_Send, "m_bDrawViewmodel",  1);
							SetEntProp(Client,    Prop_Send, "m_iFOV", 90);
						}else{
							ZoomOn[Client] = true;
							KeyBuffer[Client] = true;
							SetEntProp(Client,    Prop_Send, "m_bDrawViewmodel",  0);
							SetEntProp(Client,    Prop_Send, "m_iFOV", 20);
						}
					}
				}
			}else{
				KeyBuffer[Client] = false;
			}
		}
	}
}