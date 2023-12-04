#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

bool g_bSpawnHealth[MAXPLAYERS+1];
int g_iSpawnHealth[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Set Health",
	author = "joac1144 / Zyanthius [DK]",
	description = "Set players' health.",
	version = "2.1",
	url = "https://forums.alliedmods.net/showthread.php?t=233971"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_hp", Command_HP, ADMFLAG_SLAY, "Set players' health.");
	RegAdminCmd("sm_spawnhp", Command_SpawnHP, ADMFLAG_SLAY, "Set health on spawn.");
	HookEvent("player_spawn", vPlayerSpawn);
}

public Action Command_HP(int client, int args)
{
	char target[32], sHP[32];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, sHP, sizeof(sHP));
	int iHealth = StringToInt(sHP);
	char target_name[MAX_NAME_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hp <#userid|name> <HP value>");
		return Plugin_Handled;	
	}
	else if (iHealth <= 0)
	{
		PrintToChat(client, "[SM] Please choose a higher value! (Minimum: 1)");
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		SetEntityHealth(target_list[i], iHealth);
		LogAction(client, target_list[i], "Admin %L set %L's health to %d.", client, target_list[i], iHealth);
	}
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Set %t health to %d.", target_name, iHealth);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Set %s's health to %d.", target_name, iHealth);
	}
	return Plugin_Handled;
}

public Action Command_SpawnHP(int client, int args)
{
	char target[32], sHP[32];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, sHP, sizeof(sHP));
	char target_name[MAX_NAME_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spawnhp <#userid|name> <HP value>");
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		g_iSpawnHealth[target_list[i]] = StringToInt(sHP);
		if (g_iSpawnHealth[target_list[i]] <= 0)
		{
			ReplyToCommand(client, "[SM] Please choose a higher value! (Minimum: 1)");
			return Plugin_Handled;
		}
		else	
		{
			g_bSpawnHealth[target_list[i]] = true;
			LogAction(client, target_list[i], "Admin %L set %L to spawn with %d HP", client, target_list[i], g_iSpawnHealth[target_list[i]]);
		}
	}
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Set spawnhealth on %t", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Set spawnhealth on %s", target_name);
	}

	return Plugin_Handled;
}

public void vPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iPlayer = GetClientOfUserId(event.GetInt("userid"));
	if (g_bSpawnHealth[iPlayer])
	{
		SetEntityHealth(iPlayer, g_iSpawnHealth[iPlayer]);
	}
}