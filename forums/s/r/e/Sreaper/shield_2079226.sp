#include <sdktools>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#pragma semicolon 1

new g_delay[MAXPLAYERS+1];
new bool:g_bPlayerPressedReload[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[TF2] Medic Shield",
	author = "Pelipoika",
	description = "The shield from MVM in normal gameplay!",
	version = "1.0",
	url = "google.com"
}

public OnPluginStart()
{
	RegAdminCmd("sm_shield", Command_Shield, 0);
}

public Action:Command_Shield(client, args)
{
	if (g_delay[client] > 0)
	{
		CPrintToChat(client, "{green}Please wait {cyan}%i {green}seconds before putting up a new shield", g_delay[client]);
		return Plugin_Handled;
	}

	if (IsValidClient(client) && IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		new shield = CreateEntityByName("entity_medigun_shield");
		if(shield != -1)
		{
			DispatchSpawn(shield);
			SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", client);  
			SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(client));  
			Delay(client);
			PrintCenterText(client, "Shield up!");
			return Plugin_Handled;
		}
	}
		
	return Plugin_Handled;
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
			FakeClientCommandEx(client, "sm_shield");
		}
	}
	return Plugin_Continue;
}

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
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}