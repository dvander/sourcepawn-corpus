#include <sourcemod>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.85"

int g_bMapNeedsFix = 0;
bool g_bIsThisDeGroot = false;
ConVar g_hCVRemoveFirstSlot;
ConVar g_hCVEnabled;
ConVar g_hCVForceClass;

public Plugin myinfo =
{
	name        = "Map Bot Fix",
	author      = "luki1412",
	description = "Limits TF2 bots to snipers, spies and engineers on incompatible maps.",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/member.php?u=43109"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	char Game[32];
	GetGameFolderName(Game, sizeof(Game));
	
	if (!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta")) 
	{
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar g_hCVVer = CreateConVar("sm_mbf_version", PLUGIN_VERSION, "Restrict classes for bots on incompatible maps", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	g_hCVEnabled                              = CreateConVar("sm_mbf_enabled", "1", "Enables/disables Map Bot Fix", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVRemoveFirstSlot					  = CreateConVar("sm_mbf_removefirstslot", "0", "If enabled, removes weapon from the first slot of each player on DeGrootKeep", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVForceClass							  = FindConVar("tf_bot_force_class");
	
	HookConVarChange(g_hCVEnabled, EnabledChanged);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("post_inventory_application", OnInventoryApplication);
	MapCheck();
	SetConVarString(g_hCVVer, PLUGIN_VERSION);
}

public void EnabledChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(g_hCVEnabled))
	{
		HookEvent("player_spawn", Event_PlayerSpawn);
		HookEvent("post_inventory_application", OnInventoryApplication);
	}
	else
	{
		UnhookEvent("player_spawn", Event_PlayerSpawn);
		UnhookEvent("post_inventory_application", OnInventoryApplication);
		SetConVarString(g_hCVForceClass, "");
	}
}

public void OnMapStart()
{
	MapCheck();
}

void MapCheck()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if ( StrContains( currentMap, "cp_" , false) != -1 || StrContains( currentMap, "pl_" , false) != -1 || StrContains( currentMap, "koth_" , false) != -1 || StrContains( currentMap, "ctf_" , false) != -1 )
	{
		g_bMapNeedsFix = 0;
		
		if (GetConVarBool(g_hCVEnabled))
		{
			SetConVarString(g_hCVForceClass, "");
		}
	}
	else if( StrContains( currentMap, "sd_" , false) != -1 || StrContains( currentMap, "pd_" , false) != -1)
	{		
		g_bMapNeedsFix = 2;
		
		if (GetConVarBool(g_hCVEnabled))
		{
			RandomizeClass2();
		}
	}
	else
	{		
		g_bMapNeedsFix = 1;
		
		if (GetConVarBool(g_hCVEnabled))
		{
			RandomizeClass();
		}
	}
	
	if (StrContains(currentMap, "cp_degrootkeep" , false) != -1 && GetConVarInt(g_hCVEnabled) == 1)
	{
		g_bIsThisDeGroot = true;
	}
	else
	{
		g_bIsThisDeGroot = false;
	}
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(g_hCVEnabled))
	{
		switch (g_bMapNeedsFix)
		{
			case 1:
			{
				RandomizeClass();
			}
			case 2:
			{
				RandomizeClass2();
			}
		}
	}
}

public void OnInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(g_hCVEnabled))
	{
		if (GetConVarBool(g_hCVRemoveFirstSlot) && g_bIsThisDeGroot == true)
		{
			int client = GetClientOfUserId(GetEventInt(event, "userid"));
			
			if (IsValidClient(client))
			{
				TF2_RemoveWeaponSlot(client, 0);
				EquipPlayerWeapon(client, GetPlayerWeaponSlot(client, 2));
			}
		}
	}
}

void RandomizeClass()
{
	float RndCls = GetURandomFloat();
	
	if (RndCls <= 0.45)
	{
		SetConVarString(g_hCVForceClass, "sniper");
	}
	else if (RndCls > 0.45 && RndCls <= 0.90)
	{
		SetConVarString(g_hCVForceClass, "spy");
	}
	else
	{
		SetConVarString(g_hCVForceClass, "engineer");
	}
}

void RandomizeClass2()
{
	float RndCls = GetURandomFloat();
	
	if (RndCls <= 0.5)
	{
		SetConVarString(g_hCVForceClass, "sniper");
	}
	else
	{
		SetConVarString(g_hCVForceClass, "spy");
	}
}

bool IsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client));
}