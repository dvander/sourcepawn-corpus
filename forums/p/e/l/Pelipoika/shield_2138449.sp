#include <sdktools>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#pragma semicolon 1

//new g_delay[MAXPLAYERS+1];
new bool:g_bPlayerPressedReload[MAXPLAYERS+1];
new g_entCurrentShield[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ... };

public Plugin:myinfo = 
{
	name = "[TF2] Medic Shield",
	author = "Pelipoika",
	description = "The shield from MVM in normal gameplay!",
	version = "1.0",
	url = "Null"
}

public OnPluginStart()
{
	RegAdminCmd("sm_shield", Command_Shield, 0);
	
	HookEvent("player_death", Event_PlayerDeath);
}

public Action:Command_Shield(client, args)
{
//	if (g_delay[client] > 0)
//	{
//		CPrintToChat(client, "{green}Please wait {cyan}%i {green}seconds before putting up a new shield", g_delay[client]);
//		return Plugin_Handled;
//	}

	if (IsValidClient(client) && IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Medic && GetClientTeam(client) < 2)
	{
		new medgun = GetPlayerWeaponSlot(client, 1);
		
		if(TF2_GetUberLevel(client) >= 0.75 && GetWeaponItemDef(medgun) != 998)
		{
			new shield = CreateEntityByName("entity_medigun_shield");
			if(shield != -1)
			{
				DispatchSpawn(shield);
				
				SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", client);  
				SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(client));  
				SetEntProp(shield, Prop_Data, "m_iInitialTeamNum", GetClientTeam(client));  
				
				TF2_SetUberLevel(client, TF2_GetUberLevel(client) - 0.75);
				g_entCurrentShield[client] = EntIndexToEntRef(shield);
				
				return Plugin_Handled;
			}
		}
		else
			CPrintToChat(client, "{green}You must have atleast {cyan}75%% Uber {green}to use this!");
			
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontbroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client != 0)
    {
        if (IsValidEntity(g_entCurrentShield[client]))
        {
            AcceptEntityInput(g_entCurrentShield[client], "Kill");
            g_entCurrentShield[client] = INVALID_ENT_REFERENCE;
        }
    }
}

public Action:OnPlayerRunCmd(client, &buttons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon) 
{
	if (IsValidClient(client) && IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		if(buttons & IN_RELOAD)
		{
			g_bPlayerPressedReload[client] = true;
		}
		else if (!(buttons & IN_RELOAD) && g_bPlayerPressedReload[client])
		{
			g_bPlayerPressedReload[client] = false;
			Command_Shield(client, client);
		}
	}
	return Plugin_Continue;
}

stock GetWeaponItemDef(weapon)
{
	if (!IsValidWeapon(weapon))
		return 0;
	
	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}

stock Float:TF2_GetUberLevel(client)
{
    new index = GetPlayerWeaponSlot(client, 1);
    if (index > 0)
        return GetEntPropFloat(index, Prop_Send, "m_flChargeLevel");
    else
        return 0.0;
}

stock TF2_SetUberLevel(client, Float:uberlevel)
{
    new index = GetPlayerWeaponSlot(client, 1);
    if (index > 0)
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel);
}

stock bool:IsValidWeapon(weapon)
{
	if (!IsValidEntity(weapon))
		return false;
	
	decl String:class[64];
	GetEdictClassname(weapon, class, sizeof(class));
	
	if (strncmp(class, "tf_weapon_", 10) == 0 || strncmp(class, "tf_wearable_demoshield", 22) == 0)
		return true;
	return false;
}
/*
public Delay(client)
{
	g_delay[client] = 60;
	CreateTimer(1.0, Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Delay(Handle:timer, any:client)
{
	g_delay[client]--;
	if (g_delay[client])
		CreateTimer(1.0, Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}*/

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}