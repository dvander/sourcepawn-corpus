#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

char spawnTarget[32];
char hp[32];
int spawnHealth[MAXPLAYERS+1];
bool spawnHealthOn[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Set Health",
	author = "joac1144 / Zyanthius [DK]",
	description = "Set players' health",
	version = "2.0",
	url = "https://forums.alliedmods.net/showthread.php?t=233971"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_hp", Command_HP, ADMFLAG_SLAY, "Set players health");
	RegAdminCmd("sm_spawnhp", Command_SpawnHP, ADMFLAG_SLAY, "Set health on spawn");
	HookEvent("player_spawn", PlayerSpawn);
}

public Action Command_HP(int client, int args)
{	
	int health;

	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hp <name or #userid> <hp>");
		return Plugin_Handled;	
	}	
	
	char Target[64];
	char cHP[32];
	GetCmdArg(1, Target, sizeof(Target))
	
	if (args >= 2 && GetCmdArg(2, cHP, sizeof(cHP)))
	{
		health = StringToInt(cHP);
	}

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					Target,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	
	for (int i = 0; i < target_count; i++)
	{
		if (health <= 0)
		{
			PrintToChat(client, "[SM] Please choose a higher value!");
			return Plugin_Handled;
		}
		else
		{
			SetEntityHealth(target_list[i], health);
			LogAction(client, target_list[i], "Admin %L set %L's health to %d.", client, target_list[i], health);
		}
	}

	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Set %t health to %d.", target_name, health);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Set %s's health to %d.", target_name, health);
	}

	return Plugin_Handled;
}

public Action Command_SpawnHP(int client, int args)
{
	/*
	char spawnTarget[MAX_NAME_LENGTH];
	int spawnHealth[MAXPLAYERS+1];
	char hp[32];
	bool spawnHealthOn[MAXPLAYERS+1];
	*/
	
	GetCmdArg(1, spawnTarget, sizeof(spawnTarget));
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spawnhp <name or #userid> <HP>");
		return Plugin_Handled;
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
					spawnTarget,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if (args >= 2 && GetCmdArg(2, hp, sizeof(hp)))
		{
			spawnHealth[target_list[i]] = StringToInt(hp);
		}
	
		if (spawnHealth[target_list[i]] <= 0)
		{
			ReplyToCommand(client, "[SM] Please choose a higher value!");
			return Plugin_Handled;
		}
		else	
		{
			spawnHealthOn[target_list[i]] = true;
			LogAction(client, target_list[i], "Admin %L set %L to spawn with %d HP", client, target_list[i], spawnHealth[target_list[i]]);
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

public void PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (spawnHealthOn[client])
	{
		SetEntityHealth(client, spawnHealth[client]);
	}
}






