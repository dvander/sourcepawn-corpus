#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"

public Plugin myinfo = 
{
	name = "[TF2] Midas - Turn to Gold on Melee Hit",
	author = "PC Gamer, using code from Nanochip",
	description = "Creates a gold statue of victim when hit by melee weapon",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

bool g_bIsMidas[MAXPLAYERS + 1];


public void OnPluginStart()
{
	RegAdminCmd("sm_midas", Command_Midas, ADMFLAG_SLAY, "Enjoy being King Midas");
	RegAdminCmd("sm_nomidas", Command_NoMidas, ADMFLAG_SLAY, "No longer King Midas");	

	for( int client = 1; client <= MaxClients; client++ )
	{
		if( IsValidClient(client) )
		{
			SDKHook( client, SDKHook_OnTakeDamage, OnTakeDamage );
			g_bIsMidas[client] = false;
		}
	}
}

public void OnClientPutInServer(int client)
{
	OnClientDisconnect_Post(client);
}

public void OnClientDisconnect_Post(int client)
{
	if(g_bIsMidas[client])
	{
		g_bIsMidas[client] = false;
	}
}

public void OnEntityCreated(int iEntity, const char[] strClassname)
{
	if (StrEqual(strClassname,"tf_ragdoll"))
	{
		SetEntPropFloat(iEntity, Prop_Send, "m_flHeadScale", 1.0);
		SetEntPropFloat(iEntity, Prop_Send, "m_flTorsoScale", 1.0);
		SetEntPropFloat(iEntity, Prop_Send, "m_flHandScale", 1.0);
	}
}

public Action Command_Midas(int client, int args)
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
		MakeMidas(target_list[i]);
		PrintToChat(target_list[i], "You have the Midas effect. Melee hits turn victims to gold");
		LogAction(client, target_list[i], "\"%L\" gave \"%L\" the Midas Effect!", client, target_list[i]);
		ReplyToCommand(client, "Midas effect enabled on %N", target_list[i]);
	}

	return Plugin_Handled;
}

public Action Command_NoMidas(int client, int args)
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
		RemoveMidas(target_list[i]);
		PrintToChat(target_list[i], "You no longer have the Midas effect.");
		LogAction(client, target_list[i], "\"%L\" removed the Midas Effect from \"%L\"!", client, target_list[i]);
		ReplyToCommand(client, "Midas effect disabled on %N", target_list[i]);		
	}

	return Plugin_Handled;
}

public Action RemoveBody(Handle timer, any client)
{
	int BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(IsValidEdict(BodyRagdoll))
	{
		AcceptEntityInput(BodyRagdoll, "kill");
	}
}

public Action MakeMidas(int client)
{
	g_bIsMidas[client] = true;
	
	return Plugin_Handled;
}

public Action RemoveMidas(int client)
{
	g_bIsMidas[client] = false;

	return Plugin_Handled;	
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

public Action OnPlayerActivate(Handle hEvent, const char[] strEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(client) )
	return;

	g_bIsMidas[client] = false;
	
	SDKHook( client, SDKHook_OnTakeDamage, OnTakeDamage );
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(g_bIsMidas[attacker] && IsWeaponSlotActive(attacker, 2)) //melee weapon
	{
		CreateTimer(0.0, RemoveBody, victim);
		
		int ragdoll = CreateEntityByName("tf_ragdoll");
		int team = GetClientTeam(victim);
		int class = view_as<int>(TF2_GetPlayerClass(victim));
		
		float clientOrigin[3];
		SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", clientOrigin); 
		SetEntProp(ragdoll, Prop_Send, "m_iPlayerIndex", victim);
		
		SetEntProp(ragdoll, Prop_Send, "m_bGoldRagdoll", 1);
		
		SetEntProp(ragdoll, Prop_Send, "m_iTeam", team);
		SetEntProp(ragdoll, Prop_Send, "m_iClass", class);
		SetEntProp(ragdoll, Prop_Send, "m_nForceBone", 1);
		
		DispatchSpawn(ragdoll);
	}

	return Plugin_Changed;
} 

stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
	return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}