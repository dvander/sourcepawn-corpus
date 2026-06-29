#pragma semicolon 1

#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <sourcemod>

// SPECTATOR MODES

#define SPECMODE_NONE           0
#define SPECMODE_FIRSTPERSON    4
#define SPECMODE_THIRDPERSON    5
#define SPECMODE_FREELOOK       6

// PLUGIN INFORMATION

#define PLUGIN_NAME "CS:S Bot Control"
#define PLUGIN_AUTHOR "Adam Short"
#define PLUGIN_DESCRIPTION "Hacky way to 'control' bots, similar to CS:GO"
#define PLUGIN_VERSION "1.1.0"
#define PLUGIN_URL "https://gamepunch.net"

bool gB_deathnoticeHide;
bool gB_restrictPickup[MAXPLAYERS + 1];
bool gB_cleanup[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnPluginEnd()
{
	UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, SDKWeaponCanUse);
	SDKHook(client, SDKHook_WeaponDrop, SDKWeaponDrop);
	gB_restrictPickup[client] = false;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	int playerTeam = GetClientTeam(client);
	int playerTeamBots = 0;
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientInGame(p) && IsFakeClient(p) && IsPlayerAlive(p) && GetClientTeam(p) == playerTeam)
		{
			playerTeamBots++;
		}
	}
	if (playerTeamBots > 0)
	{
		PrintToChat(client, "\x04You can take over a bot by pressing your use key while spectating a bot!");
	}

	if(gB_deathnoticeHide)
	{
		gB_deathnoticeHide = false;
		SetEventBroadcast(event, true);
	}
	gB_restrictPickup[client] = false;
}

Action timer_canuse(Handle timer, int client)
{
	if(IsClientInGame(client))
	{
		gB_restrictPickup[client] = false;
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	// If the player is using the use key
	if(buttons & IN_USE)
	{
		// Make sure the player is dead
		if(!IsPlayerAlive(client))
		{
			int iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
			// If the client is not spectating anyone, ignore
			if(iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_THIRDPERSON)
			{
				return Plugin_Continue;
			}
			// Get the target
			int iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			// Make sure the player is a bot
			if(!IsFakeClient(iTarget))
			{
				return Plugin_Continue;
			}
			// Make sure the target is alive
			if(!IsPlayerAlive(iTarget))
			{
				return Plugin_Continue;
			}
			// Make sure they are on the same team
			if(GetClientTeam(iTarget) != GetClientTeam(client))
			{
				return Plugin_Continue;
			}
			CS_RespawnPlayer(client);
			gB_cleanup[client] = true;
			for(int i = 0; i <= 3; i++)
			{
				if(i == 3)
				{
					for(int j = 0; j <= 3; j++)
					{
						if(IsValidEntity(GetPlayerWeaponSlot(client, i)))
						{
							CS_DropWeapon(client, GetPlayerWeaponSlot(client, i), true);
						}
					}
				}
				if(i != 2 && IsValidEntity(GetPlayerWeaponSlot(client, i)))
				{
					CS_DropWeapon(client, GetPlayerWeaponSlot(client, i), true);
				}
			}
			gB_cleanup[client] = false;
			float teleportDestination[3];
			float anglesDestination[3];
			float velocityDestination[3];
			GetClientAbsOrigin(iTarget, teleportDestination);
			GetClientAbsAngles(iTarget, anglesDestination);
			GetEntPropVector(iTarget, Prop_Data, "m_vecVelocity", velocityDestination);
			gB_restrictPickup[client] = true;
			TeleportEntity(client, teleportDestination, anglesDestination, velocityDestination);
			SetEntityHealth(client, GetClientHealth(iTarget));
			SetEntProp(client, Prop_Send, "m_ArmorValue", GetEntProp(iTarget, Prop_Send, "m_ArmorValue"));
			SetEntProp(client, Prop_Send, "m_bHasHelmet", GetEntProp(iTarget, Prop_Send, "m_bHasHelmet"));
			FakeClientCommand(iTarget, "use weapon_knife");
			PrintToChatAll("\x04Player '%N' took control of '%N'.", client, iTarget);
			gB_deathnoticeHide = true;
			// Kill the bot, clean it up
			int iFrags = GetClientFrags(iTarget);
			int iDeaths = GetClientDeaths(iTarget);
			for(int i = 0; i <= 3; i++)
			{
				if(i == 3)
				{
					for(int j = 0; j <= 3; j++)
					{
						if(IsValidEntity(GetPlayerWeaponSlot(iTarget, i)))
						{
							CS_DropWeapon(iTarget, GetPlayerWeaponSlot(iTarget, i), false);
						}
					}
				}
				if(i != 2 && IsValidEntity(GetPlayerWeaponSlot(iTarget, i)))
				{
					CS_DropWeapon(iTarget, GetPlayerWeaponSlot(iTarget, i), false);
				}
			}
			ForcePlayerSuicide(iTarget);
			RemoveBody(iTarget);
			SetEntProp(iTarget, Prop_Data, "m_iFrags", iFrags);
			SetEntProp(iTarget, Prop_Data, "m_iDeaths", iDeaths);
			CreateTimer(0.1, timer_canuse, client, TIMER_FLAG_NO_MAPCHANGE); //visual bug fix way.
		}
	}
	return Plugin_Continue;
}

//Body:
stock RemoveBody(int client)
{
	//Declare:
	int BodyRagdoll;
	char Classname[64];
	//Initialize:
	BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(IsValidEdict(BodyRagdoll))
	{
		//Find:
		GetEdictClassname(BodyRagdoll, Classname, sizeof(Classname));
		//Remove:
		if(StrEqual(Classname, "cs_ragdoll", false))
		{
			RemoveEdict(BodyRagdoll);
		}
	}
}

Action SDKWeaponCanUse(int client, int weapon)
{
	if(gB_restrictPickup[client])
	{
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}

Action SDKWeaponDrop(int client, int weapon)
{
	if(gB_cleanup[client])
	{
		RemoveEntity(weapon);
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}
