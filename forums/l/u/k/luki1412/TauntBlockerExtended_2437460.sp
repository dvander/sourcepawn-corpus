#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.08"

ConVar g_hCV_tbe_enabled;
ConVar g_hCV_tbe_taunts;
ConVar g_hCV_tbe_tauntdamagetoplayers;
ConVar g_hCV_tbe_tauntdamagetobuildings;
ConVar g_hCV_tbe_tauntflag;
ConVar g_hCV_tbe_tauntitems;
ConVar g_hCV_tbe_tauntitemstimer;
Handle g_hTauntItems;

public Plugin myinfo = 
{
	name = "Taunt Blocker Extended",
	author = "luki1412",
	description = "Provides multiple options for blocking taunts in TF2",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=43109"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	if (GetEngineVersion() != Engine_TF2) 
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar g_hCV_tbe_version = CreateConVar("sm_tbe_version", PLUGIN_VERSION, "Taunt Blocker Extended version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
	g_hCV_tbe_enabled = CreateConVar("sm_tbe_enabled", "1", "Enables/disables Taunt Blocker Extended", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_tbe_taunts = CreateConVar("sm_tbe_allowtaunts", "1", "Enables/disables taunts", FCVAR_NONE, true, 0.0, true, 4.0);
	g_hCV_tbe_tauntdamagetoplayers = CreateConVar("sm_tbe_allowtauntdamagetoplayers", "0", "Allows/disallows players to do taunt damage to other players", FCVAR_NONE, true, 0.0, true, 4.0);
	g_hCV_tbe_tauntdamagetobuildings = CreateConVar("sm_tbe_allowtauntdamagetobuildings", "0", "Allows/disallows players to do taunt damage to buildings", FCVAR_NONE, true, 0.0, true, 4.0);
	g_hCV_tbe_tauntflag = CreateConVar("sm_tbe_adminflag", "b", "Admin flag needed to do taunt damage if its set as admin only", FCVAR_NONE);
	g_hCV_tbe_tauntitems = CreateConVar("sm_tbe_allowtauntitems", "1", "Enables/disables specified taunt items", FCVAR_NONE, true, 0.0, true, 4.0);
	g_hCV_tbe_tauntitemstimer = CreateConVar("sm_tbe_allowtauntitemstimer", "0", "Timer for taunt items. Players will be forced to stop taunting when this timer runs out", FCVAR_NONE, true, 0.0, true, 300.0);	
	RegAdminCmd("sm_tbe_reloadtauntitems", ReloadItemList, ADMFLAG_GENERIC, "Reloads the config file with taunt item indexes");
	g_hTauntItems = CreateArray(10, 0);
	HookConVarChange(g_hCV_tbe_enabled, EnabledChanged);
	AddCommandListener(Cmd_taunt, "taunt");
	AddCommandListener(Cmd_taunt, "+taunt");
	ReadItemList();	
	AutoExecConfig(true, "Taunt_Blocker_Extended");
	SetConVarString(g_hCV_tbe_version, PLUGIN_VERSION);
}

public Action ReloadItemList(int client, int args)
{
	ReadItemList();
}

public void EnabledChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(g_hCV_tbe_enabled))
	{
		AddCommandListener(Cmd_taunt, "taunt");
		AddCommandListener(Cmd_taunt, "+taunt");
	}
	else
	{
		RemoveCommandListener(Cmd_taunt, "taunt");
		RemoveCommandListener(Cmd_taunt, "+taunt");
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
}

public void OnEntityCreated(int building, const char[] classname)
{
    SDKHook(building, SDKHook_Spawn, OnEntitySpawned);
}

public void OnEntitySpawned(int building)
{
    SDKHook(building, SDKHook_OnTakeDamage, OnBuildingTakeDamage);
}

public Action Cmd_taunt(int client, char[] cmd, int args)
{
	if (!GetConVarBool(g_hCV_tbe_enabled)) 
	{
		return Plugin_Continue;
	}

	switch (GetConVarInt(g_hCV_tbe_taunts))
	{
		case 0:
		{
			return Plugin_Handled;
		}
		case 1:
		{
			return Plugin_Continue;
		}
		case 2:
		{
			if (IsPlayerHere(client) && GetClientTeam(client) == 3)
			{
				return Plugin_Handled;
			}
		}		
		case 3:
		{
			if (IsPlayerHere(client) && GetClientTeam(client) == 2)
			{
				return Plugin_Handled;
			}
		}		
		case 4:
		{
			if (IsPlayerHere(client))
			{
				char CharAdminFlag[10];
				GetConVarString(g_hCV_tbe_tauntflag, CharAdminFlag, sizeof(CharAdminFlag));
				
				if (!IsValidAdmin(client, CharAdminFlag))
				{
					return Plugin_Handled;
				}
			}
		}	
	}
	
	return Plugin_Continue;
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!GetConVarBool(g_hCV_tbe_enabled)) 
	{
		return Plugin_Continue;
	}

	switch (GetConVarInt(g_hCV_tbe_tauntdamagetoplayers))
	{
		case 0:
		{
			switch (damagecustom)
			{
				case TF_CUSTOM_TAUNT_HADOUKEN,TF_CUSTOM_TAUNT_HIGH_NOON,TF_CUSTOM_TAUNT_GRAND_SLAM,TF_CUSTOM_TAUNT_FENCING,TF_CUSTOM_TAUNT_ARROW_STAB,TF_CUSTOM_TAUNT_GRENADE,TF_CUSTOM_TAUNT_BARBARIAN_SWING,TF_CUSTOM_TAUNT_UBERSLICE,TF_CUSTOM_TAUNT_ENGINEER_SMASH,TF_CUSTOM_TAUNT_ENGINEER_ARM,TF_CUSTOM_TAUNT_ARMAGEDDON,TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF,TF_CUSTOM_FLARE_PELLET,TF_CUSTOM_TAUNTATK_GASBLAST:
				{
					return Plugin_Handled;
				}
			}
		}
		case 1:
		{
			return Plugin_Continue;
		}
		case 2:
		{
			if (IsPlayerHere(attacker) && GetClientTeam(attacker) == 3)
			{
				switch (damagecustom)
				{
					case TF_CUSTOM_TAUNT_HADOUKEN,TF_CUSTOM_TAUNT_HIGH_NOON,TF_CUSTOM_TAUNT_GRAND_SLAM,TF_CUSTOM_TAUNT_FENCING,TF_CUSTOM_TAUNT_ARROW_STAB,TF_CUSTOM_TAUNT_GRENADE,TF_CUSTOM_TAUNT_BARBARIAN_SWING,TF_CUSTOM_TAUNT_UBERSLICE,TF_CUSTOM_TAUNT_ENGINEER_SMASH,TF_CUSTOM_TAUNT_ENGINEER_ARM,TF_CUSTOM_TAUNT_ARMAGEDDON,TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF,TF_CUSTOM_FLARE_PELLET,TF_CUSTOM_TAUNTATK_GASBLAST:
					{
						return Plugin_Handled;
					}
				}
			}
		}		
		case 3:
		{
			if (IsPlayerHere(attacker) && GetClientTeam(attacker) == 2)
			{
				switch (damagecustom)
				{
					case TF_CUSTOM_TAUNT_HADOUKEN,TF_CUSTOM_TAUNT_HIGH_NOON,TF_CUSTOM_TAUNT_GRAND_SLAM,TF_CUSTOM_TAUNT_FENCING,TF_CUSTOM_TAUNT_ARROW_STAB,TF_CUSTOM_TAUNT_GRENADE,TF_CUSTOM_TAUNT_BARBARIAN_SWING,TF_CUSTOM_TAUNT_UBERSLICE,TF_CUSTOM_TAUNT_ENGINEER_SMASH,TF_CUSTOM_TAUNT_ENGINEER_ARM,TF_CUSTOM_TAUNT_ARMAGEDDON,TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF,TF_CUSTOM_FLARE_PELLET,TF_CUSTOM_TAUNTATK_GASBLAST:
					{
						return Plugin_Handled;
					}
				}
			}
		}		
		case 4:
		{
			if (IsPlayerHere(attacker))
			{
				char CharAdminFlag[10];
				GetConVarString(g_hCV_tbe_tauntflag, CharAdminFlag, sizeof(CharAdminFlag));
				
				if (!IsValidAdmin(attacker, CharAdminFlag))
				{
					switch (damagecustom)
					{
						case TF_CUSTOM_TAUNT_HADOUKEN,TF_CUSTOM_TAUNT_HIGH_NOON,TF_CUSTOM_TAUNT_GRAND_SLAM,TF_CUSTOM_TAUNT_FENCING,TF_CUSTOM_TAUNT_ARROW_STAB,TF_CUSTOM_TAUNT_GRENADE,TF_CUSTOM_TAUNT_BARBARIAN_SWING,TF_CUSTOM_TAUNT_UBERSLICE,TF_CUSTOM_TAUNT_ENGINEER_SMASH,TF_CUSTOM_TAUNT_ENGINEER_ARM,TF_CUSTOM_TAUNT_ARMAGEDDON,TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF,TF_CUSTOM_FLARE_PELLET,TF_CUSTOM_TAUNTATK_GASBLAST:
						{
							return Plugin_Handled;
						}
					}
				}
			}
		}	
	}
	
	return Plugin_Continue;
}

public Action OnBuildingTakeDamage(int building, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!GetConVarBool(g_hCV_tbe_enabled)) 
	{
		return Plugin_Continue;
	}

	char classname[32];
	GetEntityClassname(building, classname, sizeof(classname));

	if (!StrEqual(classname, "obj_sentrygun", false) && !StrEqual(classname, "obj_dispenser", false) && !StrEqual(classname, "obj_teleporter", false))
	{
		return Plugin_Continue;
	}

	switch (GetConVarInt(g_hCV_tbe_tauntdamagetobuildings))
	{
		case 0:
		{
			switch (damagecustom)
			{
				case TF_CUSTOM_TAUNT_HADOUKEN,TF_CUSTOM_TAUNT_HIGH_NOON,TF_CUSTOM_TAUNT_GRAND_SLAM,TF_CUSTOM_TAUNT_FENCING,TF_CUSTOM_TAUNT_ARROW_STAB,TF_CUSTOM_TAUNT_GRENADE,TF_CUSTOM_TAUNT_BARBARIAN_SWING,TF_CUSTOM_TAUNT_UBERSLICE,TF_CUSTOM_TAUNT_ENGINEER_SMASH,TF_CUSTOM_TAUNT_ENGINEER_ARM,TF_CUSTOM_TAUNT_ARMAGEDDON,TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF,TF_CUSTOM_FLARE_PELLET,TF_CUSTOM_TAUNTATK_GASBLAST:
				{
					return Plugin_Handled;
				}
			}
		}
		case 1:
		{
			return Plugin_Continue;
		}
		case 2:
		{
			if (IsPlayerHere(attacker) && GetClientTeam(attacker) == 3)
			{
				switch (damagecustom)
				{
					case TF_CUSTOM_TAUNT_HADOUKEN,TF_CUSTOM_TAUNT_HIGH_NOON,TF_CUSTOM_TAUNT_GRAND_SLAM,TF_CUSTOM_TAUNT_FENCING,TF_CUSTOM_TAUNT_ARROW_STAB,TF_CUSTOM_TAUNT_GRENADE,TF_CUSTOM_TAUNT_BARBARIAN_SWING,TF_CUSTOM_TAUNT_UBERSLICE,TF_CUSTOM_TAUNT_ENGINEER_SMASH,TF_CUSTOM_TAUNT_ENGINEER_ARM,TF_CUSTOM_TAUNT_ARMAGEDDON,TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF,TF_CUSTOM_FLARE_PELLET,TF_CUSTOM_TAUNTATK_GASBLAST:
					{
						return Plugin_Handled;
					}
				}
			}
		}		
		case 3:
		{
			if (IsPlayerHere(attacker) && GetClientTeam(attacker) == 2)
			{
				switch (damagecustom)
				{
					case TF_CUSTOM_TAUNT_HADOUKEN,TF_CUSTOM_TAUNT_HIGH_NOON,TF_CUSTOM_TAUNT_GRAND_SLAM,TF_CUSTOM_TAUNT_FENCING,TF_CUSTOM_TAUNT_ARROW_STAB,TF_CUSTOM_TAUNT_GRENADE,TF_CUSTOM_TAUNT_BARBARIAN_SWING,TF_CUSTOM_TAUNT_UBERSLICE,TF_CUSTOM_TAUNT_ENGINEER_SMASH,TF_CUSTOM_TAUNT_ENGINEER_ARM,TF_CUSTOM_TAUNT_ARMAGEDDON,TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF,TF_CUSTOM_FLARE_PELLET,TF_CUSTOM_TAUNTATK_GASBLAST:
					{
						return Plugin_Handled;
					}
				}
			}
		}		
		case 4:
		{
			if (IsPlayerHere(attacker))
			{
				char CharAdminFlag[10];
				GetConVarString(g_hCV_tbe_tauntflag, CharAdminFlag, sizeof(CharAdminFlag));
				
				if (!IsValidAdmin(attacker, CharAdminFlag))
				{
					switch (damagecustom)
					{
						case TF_CUSTOM_TAUNT_HADOUKEN,TF_CUSTOM_TAUNT_HIGH_NOON,TF_CUSTOM_TAUNT_GRAND_SLAM,TF_CUSTOM_TAUNT_FENCING,TF_CUSTOM_TAUNT_ARROW_STAB,TF_CUSTOM_TAUNT_GRENADE,TF_CUSTOM_TAUNT_BARBARIAN_SWING,TF_CUSTOM_TAUNT_UBERSLICE,TF_CUSTOM_TAUNT_ENGINEER_SMASH,TF_CUSTOM_TAUNT_ENGINEER_ARM,TF_CUSTOM_TAUNT_ARMAGEDDON,TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF,TF_CUSTOM_FLARE_PELLET,TF_CUSTOM_TAUNTATK_GASBLAST:
						{
							return Plugin_Handled;
						}
					}
				}
			}
		}	
	}
	
	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (!GetConVarBool(g_hCV_tbe_enabled)) 
	{
		return;
	}

	if (condition != TFCond_Taunting)
	{
		return;
	}	

	float titimer = GetConVarFloat(g_hCV_tbe_tauntitemstimer);
	int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
	
	switch (GetConVarInt(g_hCV_tbe_tauntitems))
	{
		case 0:
		{
			if (IsPlayerHere(client) && FindValueInArray(g_hTauntItems, tauntid) != -1)
			{
				if (titimer == 0.0)
				{
					TF2_RemoveCondition(client, TFCond_Taunting);
				}
				else
				{
					CreateTimer(titimer, RemoveTaunt, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		case 1:
		{
			return;
		}
		case 2:
		{
			if (IsPlayerHere(client) && GetClientTeam(client) == 3)
			{
				if (FindValueInArray(g_hTauntItems, tauntid) != -1)
				{
					if (titimer == 0.0)
					{
						TF2_RemoveCondition(client, TFCond_Taunting);
					}
					else
					{
						CreateTimer(titimer, RemoveTaunt, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}		
		case 3:
		{
			if (IsPlayerHere(client) && GetClientTeam(client) == 2)
			{
				if (FindValueInArray(g_hTauntItems, tauntid) != -1)
				{
					if (titimer == 0.0)
					{
						TF2_RemoveCondition(client, TFCond_Taunting);
					}
					else
					{
						CreateTimer(titimer, RemoveTaunt, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}		
		case 4:
		{
			if (IsPlayerHere(client))
			{
				char CharAdminFlag[10];
				GetConVarString(g_hCV_tbe_tauntflag, CharAdminFlag, sizeof(CharAdminFlag));
				
				if (!IsValidAdmin(client, CharAdminFlag))
				{
					if (FindValueInArray(g_hTauntItems, tauntid) != -1)
					{
						if (titimer == 0.0)
						{
							TF2_RemoveCondition(client, TFCond_Taunting);
						}
						else
						{
							CreateTimer(titimer, RemoveTaunt, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}	
	}
}

public Action RemoveTaunt(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (IsPlayerHere(client))
	{
		if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
		{
			int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
			
			if (FindValueInArray(g_hTauntItems, tauntid) != -1)
			{
				TF2_RemoveCondition(client, TFCond_Taunting);
			}
		}
	}
}

public void ReadItemList()
{
	char Filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Filename, sizeof(Filename), "configs/tbe_tauntitems.ini");
	File file = OpenFile(Filename, "rt");

	if (!file)
	{
		LogError("Could not open the config file - tbe_tauntitems.ini! Setting taunt item blocker to disabled.");
		SetConVarInt(g_hCV_tbe_tauntitems, 1);
		return;
	}

	ClearArray(g_hTauntItems);
	
	while (!IsEndOfFile(file))
	{
		char line[255];

		if (!ReadFileLine(file, line, sizeof(line)))
		{
			break;
		}
		
		if (line[0] == ';')
		{
			continue;
		}
		
		TrimString(line);
		int number = StringToInt(line);

		if (number != 0)
		{
			PushArrayCell(g_hTauntItems, number);
		}
	}
	
	CloseHandle(file);
}

bool IsPlayerHere(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

bool IsValidAdmin(int client, const char[] flags)
{
    if (!IsClientConnected(client)) 
	{
        return false;
    }
	
    int IntFlags = ReadFlagString(flags);
	
    if ((GetUserFlagBits(client) & IntFlags) == IntFlags) 
	{
        return true;
    }
	
    if (GetUserFlagBits(client) & ADMFLAG_ROOT) 
	{
        return true;
    }
	
    return false;
} 