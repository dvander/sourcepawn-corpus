#pragma semicolon 1

#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[TF2] Give Diamondback Rockets",
	author = "PC Gamer",
	description = "Replace Diamondback bullets with rockets",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

ConVar g_hDiamondbackForAllPlayers;
bool g_bHasDBRockets[MAXPLAYERS+1] = {false, ...};
	
public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	g_hDiamondbackForAllPlayers = CreateConVar("sm_diamondback_allplayers_enabled", "0", "Enables/disables giving rockets to all players who equip diamondback", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	RegAdminCmd("sm_dbrocketson", Command_GiveDBR, ADMFLAG_SLAY, "Give Player Diamondback Rockets");
	RegAdminCmd("sm_dbrocketsoff", Command_TakeDBR, ADMFLAG_SLAY, "Remove Player Diamondback Rockets");

	HookEvent("post_inventory_application", EventInventoryApplication);
	HookConVarChange(g_hDiamondbackForAllPlayers, convarchange);
	
}

public void EventInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_hDiamondbackForAllPlayers.BoolValue|| g_bHasDBRockets[client] == true)
	{
		if (TF2_GetPlayerClass(client) == TFClass_Spy && !IsFakeClient(client))
		{
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 525)//Diamondback
			{
				CreateTimer(1.0, FixDiamondback, client);			
			}
		}
	}
}

public void convarchange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_hDiamondbackForAllPlayers.BoolValue == false)
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if (IsValidEntity(i))
			{
				g_bHasDBRockets[i] = false;

				if (TF2_GetPlayerClass(i) == TFClass_Spy && !IsFakeClient(i))
				{
					int myslot0 = GetIndexOfWeaponSlot(i, 0);
					if(myslot0 == 525)//Diamondback
					{
						int health = GetClientHealth(i);
						TF2_RegeneratePlayer(i);
						SetEntProp(i, Prop_Send, "m_iHealth", health, 1);
						SetEntProp(i, Prop_Send, "m_iHealth", health, 1);

						int weapon = GetPlayerWeaponSlot(i, 0); 
						TF2Attrib_RemoveByName(weapon, "override projectile type");	
						TF2Attrib_RemoveByName(weapon, "damage bonus");			
					}
				}
			}
		}
		PrintToServer("Diamondback Rockets Disabled for all players");
	}
	else if (g_hDiamondbackForAllPlayers.BoolValue == true)
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if (IsValidEntity(i))
			{
				g_bHasDBRockets[i] = true;

				if (TF2_GetPlayerClass(i) == TFClass_Spy && !IsFakeClient(i))
				{
					int myslot0 = GetIndexOfWeaponSlot(i, 0);
					if(myslot0 == 525)//Diamondback
					{
						int health = GetClientHealth(i);
						TF2_RegeneratePlayer(i);
						SetEntProp(i, Prop_Send, "m_iHealth", health, 1);
						SetEntProp(i, Prop_Send, "m_iHealth", health, 1);

						int weapon = GetPlayerWeaponSlot(i, 0); 
						TF2Attrib_SetByName(weapon, "override projectile type", 2.0);	
						TF2Attrib_SetByName(weapon, "damage bonus", 3.0);			
					}
				}
			}
		}
		PrintToServer("Diamondback Rockets Enabled for all players");
	}
}

public Action Command_GiveDBR(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		GiveDBR(target_list[i]);
		ReplyToCommand(client, "[SM] Gave Diamondback Rockets to player %N", target_list[i]);			
		LogAction(client, target_list[i], "\"%L\" gave \"%L\" Diamondback Rockets", client, target_list[i]);
	}
	return Plugin_Handled;
}

Action GiveDBR(int client)
{
	g_bHasDBRockets[client] = true;

	if (TF2_GetPlayerClass(client) == TFClass_Spy && !IsFakeClient(client))
	{
		int myslot0 = GetIndexOfWeaponSlot(client, 0);
		if(myslot0 == 525)//Diamondback
		{
			int weapon = GetPlayerWeaponSlot(client, 0); 
			TF2Attrib_SetByName(weapon, "override projectile type", 2.0);	
			TF2Attrib_SetByName(weapon, "damage bonus", 3.0);
			
			PrintToChat(client, "You were given Diamondback Rockets");
		}
	}
	return Plugin_Handled;
}

public Action Command_TakeDBR(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		TakeDBR(target_list[i]);
		ReplyToCommand(client, "[SM] Removed Diamondback Rockets on player %N", target_list[i]);			
		LogAction(client, target_list[i], "\"%L\" removed Diamondback Rockets from \"%L\"", client, target_list[i]);
	}
	return Plugin_Handled;
}

Action TakeDBR(int client)
{
	g_bHasDBRockets[client] = false;

	if (TF2_GetPlayerClass(client) == TFClass_Spy && !IsFakeClient(client))
	{
		int myslot0 = GetIndexOfWeaponSlot(client, 0);
		if(myslot0 == 525)//Diamondback
		{
			int health = GetClientHealth(client);
			TF2_RegeneratePlayer(client);
			SetEntProp(client, Prop_Send, "m_iHealth", health, 1);
			SetEntProp(client, Prop_Send, "m_iHealth", health, 1);

			int weapon = GetPlayerWeaponSlot(client, 0); 
			TF2Attrib_RemoveByName(weapon, "override projectile type");	
			TF2Attrib_RemoveByName(weapon, "damage bonus");
			
			PrintToChat(client, "Your Diamondback Rockets were removed");
		}
	}	
	return Plugin_Handled;	
}

Action FixDiamondback(Handle timer, int client) 
{
	int weapon = GetPlayerWeaponSlot(client, 0); 
	TF2Attrib_SetByName(weapon, "override projectile type", 2.0);	
	TF2Attrib_SetByName(weapon, "damage bonus", 3.0);
		
	return Plugin_Handled;
}

int GetIndexOfWeaponSlot(int iClient, int iSlot)
{
	return GetWeaponIndex(GetPlayerWeaponSlot(iClient, iSlot));
}


int GetWeaponIndex(int iWeapon)
{
	return IsValidEnt(iWeapon) ? GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"):-1;
}

stock bool IsValidEnt(int iEnt)
{
	return iEnt > MaxClients && IsValidEntity(iEnt);
}