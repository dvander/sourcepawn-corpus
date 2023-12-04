#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.4"
#define SPAWN	"/player/taunt_yeti_roar_first.wav"

Handle g_hEquipWearable;
bool g_bZombie[MAXPLAYERS+1] = {false, ... };

public Plugin myinfo = 
{
	name = "Zombie",
	author = "PC Gamer",
	description = "Makes Target Player a Zombie",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/"
}

public void OnPluginStart() 
{
	RegConsoleCmd("sm_zombie", Zombie_Mode);
	RegConsoleCmd("sm_zombies", Zombie_Mode);
	RegAdminCmd("sm_makezombie", Command_zombie, ADMFLAG_SLAY, "Make Player a Zombie");
	RegAdminCmd("sm_makezombies", Command_zombie, ADMFLAG_SLAY, "Make Player a Zombie");
	RegAdminCmd("sm_nozombie", Command_nozombie, ADMFLAG_SLAY, "Remove Zombie from Player");
	RegAdminCmd("sm_nozombies", Command_nozombie, ADMFLAG_SLAY, "Remove Zombie from Player");	

	HookEvent("post_inventory_application", player_inv);
	
	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamedata

	if (!hTF2)
	SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);    // EquipWearable offset is always behind RemoveWearable, subtract its value by 1
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hEquipWearable = EndPrepSDKCall();

	if (!g_hEquipWearable)
	SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2;
}

public void OnMapStart()
{
	PrecacheSound(SPAWN);
}

public Action Command_zombie(int client, int args)
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
		Makezombie(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" a Zombie!", client, target_list[i]);
	}
	EmitSoundToAll(SPAWN);
	return Plugin_Handled;
}

public Action Zombie_Mode(int client, int args)
{	
	if(g_bZombie[client])
	{
		PrintToChat(client, "Zombie mode disabled");
		Makenozombie(client);
	}
	else
	{
		PrintToChat(client, "Zombie mode enabled");
		Makezombie(client);		
	}
	
	return Plugin_Handled;
}

public Action Makezombie(int client)
{
	switch(TF2_GetPlayerClass(client))
	{
	case TFClass_Scout: GiveVoodooItem(client, 5617);
	case TFClass_Soldier: GiveVoodooItem(client, 5618);
	case TFClass_Pyro: GiveVoodooItem(client, 5624);
	case TFClass_DemoMan: GiveVoodooItem(client, 5620);
	case TFClass_Heavy: GiveVoodooItem(client, 5619);
	case TFClass_Engineer: GiveVoodooItem(client, 5621);
	case TFClass_Medic: GiveVoodooItem(client, 5622);
	case TFClass_Sniper: GiveVoodooItem(client, 5625);
	case TFClass_Spy: GiveVoodooItem(client, 5623);
	}

	g_bZombie[client] = true;	
	
	CreateTimer(0.1, Timer_Makezombie2, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;	
}

public Action Timer_Makezombie2(Handle timer, int client)	
{
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 && TF2_GetPlayerClass(client) !=TFClass_Spy)
	{
		TF2Attrib_SetByName(client, "player skin override", 1.0);
		TF2Attrib_SetByName(client, "zombiezombiezombiezombie", 1.0);
		TF2Attrib_SetByName(client, "SPELL: Halloween voice modulation", 1.0);		
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 1);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 4);
	}
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)==3 && TF2_GetPlayerClass(client) !=TFClass_Spy)
	{
		TF2Attrib_SetByName(client, "player skin override", 1.0);
		TF2Attrib_SetByName(client, "zombiezombiezombiezombie", 1.0);
		TF2Attrib_SetByName(client, "SPELL: Halloween voice modulation", 1.0);	
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 1);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 5);
	}	
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 && TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		TF2Attrib_SetByName(client, "player skin override", 1.0);
		TF2Attrib_SetByName(client, "zombiezombiezombiezombie", 1.0);
		TF2Attrib_SetByName(client, "SPELL: Halloween voice modulation", 1.0);		
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 1);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 22);
	}
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)==3 && TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		TF2Attrib_SetByName(client, "player skin override", 1.0);
		TF2Attrib_SetByName(client, "zombiezombiezombiezombie", 1.0);
		TF2Attrib_SetByName(client, "SPELL: Halloween voice modulation", 1.0);		
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 1);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 23);
	}
	PrintToChat(client, "You are now a zombie.");

	return Plugin_Handled;	
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast) 
{
	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	
	if(g_bZombie[client])
	{
		if(!TF2_IsPlayerInCondition(client, TFCond_Disguised))
		{	
			Makezombie(client);
		}
	}
}

public void TF2_OnConditionAdded(int client, TFCond cond)
{
	if(g_bZombie[client] && cond == TFCond_Disguised)
	{
		TF2Attrib_SetByName(client, "player skin override", 0.0);
		TF2Attrib_SetByName(client, "zombiezombiezombiezombie", 0.0);
		TF2Attrib_SetByName(client, "SPELL: Halloween voice modulation", 0.0);			
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 0);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);		
	}
	
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	if(g_bZombie[client] && cond == TFCond_Disguised)
	{
		Makezombie(client);	
	}
}

public Action Command_nozombie(int client, int args)
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
		Makenozombie(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" removed Zombie from \"%L\"!", client, target_list[i]);
	}
	return Plugin_Handled;
}

public Action Makenozombie(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2Attrib_SetByName(client, "player skin override", 0.0);
		TF2Attrib_SetByName(client, "zombiezombiezombiezombie", 0.0);
		TF2Attrib_SetByName(client, "SPELL: Halloween voice modulation", 0.0);			
		SetEntProp(client, Prop_Send, "m_bForcedSkin", 0);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);			

		g_bZombie[client] = false;
		PrintToChat(client, "You are no longer a zombie.");
		ForcePlayerSuicide(client);		
	}
	
	return Plugin_Handled;	
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

bool GiveVoodooItem(int client, int itemindex)
{
	int soul = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(soul))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(soul, entclass, sizeof(entclass));
	SetEntData(soul, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(soul, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(soul, FindSendPropInfo(entclass, "m_iEntityLevel"), 6);
	SetEntData(soul, FindSendPropInfo(entclass, "m_iEntityQuality"), 13);
	SetEntProp(soul, Prop_Send, "m_bValidatedAttachedEntity", 1);		
	
	DispatchSpawn(soul);
	SDKCall(g_hEquipWearable, client, soul);
	return true;
} 
