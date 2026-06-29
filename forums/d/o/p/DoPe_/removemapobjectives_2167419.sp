#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

//Handles
new Handle:g_hVipEnabled = INVALID_HANDLE;
new Handle:cfg_mode = INVALID_HANDLE;
new Handle:cfg_enabled = INVALID_HANDLE;

//Strings
new String:s_MapType[128] = "";
new String:s_cfg_mode[20];
new String:s_cfg_enabled[20];

//Bool
new bool:AllowMode = false;


public Plugin:myinfo =
{
	name = "Remove Map Objectives",
	author = "DoPe^",
	description = "Removes bomb from the map.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2165975#post2165975"
};

public OnPluginStart()
{
	//Create Public Var for Server Tracking
	CreateConVar("rmo_version", PLUGIN_VERSION, "Version of Remove Map Objectives", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cfg_enabled = CreateConVar("sm_rmo_enable", "1", "Enable/Disable the plugin", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	cfg_mode = CreateConVar("sm_rmo_mode", "1", "1 = Enabled all the time // 2 = Checking for vip_forceload ConVar", FCVAR_PLUGIN, true, 1.00, true, 2.00);

	//Hook Events
	HookEvent("round_start", OnRoundStart);

	//Hook ConVar Changes
	HookConVarChange(cfg_mode, cfg_modeChanged);
	HookConVarChange(cfg_enabled, cfg_enabledChanged);

	AutoExecConfig(true, "remove_map_objectives");
}

public OnConfigsExecuted()
{
	GetConVarString(cfg_mode, s_cfg_mode, sizeof(s_cfg_mode));
	GetConVarString(cfg_enabled, s_cfg_enabled, sizeof(s_cfg_enabled));


	g_hVipEnabled = FindConVar("vip_forceload");

	if (g_hVipEnabled != INVALID_HANDLE && GetConVarBool(g_hVipEnabled)) 
	{
		AllowMode = true;
	}
	else
	{
		AllowMode = false;
	}
}


public cfg_modeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(s_cfg_mode, sizeof(s_cfg_mode), newValue);

	if (GetConVarInt(cfg_mode) == 1)
	{
		PrintToServer("[RMO] Plugin Is Enabled at all times");
	}
	else if (GetConVarInt(cfg_mode) == 2)
	{
		PrintToServer("[RMO] Plugin is Checking for the vip_forceload ConVar");
	}
}

public cfg_enabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(s_cfg_enabled, sizeof(s_cfg_enabled), newValue);

	if (GetConVarInt(cfg_enabled) == 1)
	{
		PrintToServer("[RMO] Plugin Enabled");
	}
	else if (GetConVarInt(cfg_enabled) == 0)
	{
		PrintToServer("[RMO] Plugin Disabled");
	}
}


public OnMapStart() 
{ 
	CheckMap();
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("vip_forceload = %d", GetConVarInt(g_hVipEnabled));
	ObjectiveRemover();
}

ObjectiveRemover()
{
	if (GetConVarBool(cfg_enabled))
	{
		switch (GetConVarInt(cfg_mode))
		{
			case 1:
			{
				if (StrContains(s_MapType, "bomb", false) == 0)
				{
					RemoveC4();
					//PrintToChatAll("s_MapType = bomb");
				}
				if (StrContains(s_MapType, "hostage", false) == 0)
				{
					RemoveHosties();
					//PrintToChatAll("s_MapType = hostage");
				}
			}
			case 2:
			{
				if (AllowMode)
				{
					if (GetConVarInt(g_hVipEnabled) == 1)
					{
						if (StrContains(s_MapType, "bomb", false) == 0)
						{
							RemoveC4();
							//PrintToChatAll("s_MapType = bomb");
						}
						if (StrContains(s_MapType, "hostage", false) == 0)
						{
							RemoveHosties();
							//PrintToChatAll("s_MapType = hostage");
						}
					}
				}
			}
		} 
	}
}

RemoveC4()
{
	new ent;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
		{
			ent = GetC4Ent(i);
			
			if (ent != INVALID_ENT_REFERENCE)
			{
				RemovePlayerItem(i, ent);
			}
		}
	}
}

RemoveHosties()
{
	new FindHostages = -1;
	while((FindHostages = FindEntityByClassname(FindHostages, "hostage_entity")) != -1)
	{
		AcceptEntityInput(FindHostages, "kill");
	}
}

GetC4Ent(client)
{
	return GetPlayerWeaponSlot(client, CS_SLOT_C4);
}

CheckMap()
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));

	if (StrContains( mapname, "de_", false) == 0)
	{
		s_MapType = "bomb";
	}

	if (StrContains( mapname, "cs_", false) == 0)
	{
		s_MapType = "hostage";
	}
}
