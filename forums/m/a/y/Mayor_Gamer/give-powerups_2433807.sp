#include <sourcemod>
#include <adminmenu>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.0.0"

public Plugin myinfo = 
{
	name = "[TF2] Give Powerups",
	author = "puntero",
	description = "Gives Mannpower Powerups to a player.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=284848"
};

/* Globals */
TFCond pList[12] = { TFCond_RuneAgility, TFCond_RuneHaste, TFCond_RuneKnockout, TFCond_RunePrecision, TFCond_RuneRegen, TFCond_RuneResist, TFCond_RuneStrength,
					 TFCond_RuneVampire, TFCond_RuneWarlock, TFCond_KingRune, TFCond_SupernovaRune, TFCond_PlagueRune };
char pSelect[32];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// No need for the old GetGameFolderName setup.
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_TF2)
	{
		SetFailState("This plugin was made for use with Team Fortress 2 only.");
	}
} 

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	
	CreateConVar("sm_powermenu_version", PLUGIN_VERSION, "Don't touch this!", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegAdminCmd("sm_givepower", CMD_GivePower, ADMFLAG_GENERIC, "Gives a powerup to a player. Usage: sm_givepower <powername> <player>");
	RegAdminCmd("sm_removepower", CMD_RemovePower, ADMFLAG_GENERIC, "Strips all powerups from a player. Usage: sm_removepower <player>");
	
	RegAdminCmd("sm_powerups", CMD_PowerList, ADMFLAG_GENERIC, "Shows a list of powerup names for use with the sm_givepower command.");
	
	RegAdminCmd("sm_powermenu", CMD_PowerMenu, ADMFLAG_GENERIC, "Opens a simplified powerup menu.");
}

public Action CMD_GivePower(int client, int args)
{
	if (args < 2 || args > 2)
	{
		ReplyToCommand(client, "[SM] Wrong command usage. Usage: sm_givepower <power name> <player>");
		ReplyToCommand(client, "[SM] For a list of powerup names, use sm_powerups");
		return Plugin_Handled;
	}
	
	char pName[32], player[32];
	GetCmdArg(1, pName, sizeof(pName));
	GetCmdArg(2, player, sizeof(player));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	TFCond power = PowerNameToCond(pName);
	if (power != TFCond_Unknown1)
	{
		char pTrans[32];
		GetPowerName(power, pTrans, sizeof(pTrans));
		
		for (int i = 0; i < target_count; i++)
		{
			TF2_AddCondition(target_list[i], TFCond_HasRune, TFCondDuration_Infinite);
			TF2_AddCondition(target_list[i], power, TFCondDuration_Infinite);
		}
		
		ReplyToCommand(client, "[SM] Applied power %s to %s.", pTrans, target_name);
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "[SM] Wrong power name. For a list of powerup names, use sm_powerups");
	return Plugin_Handled;
}

public Action CMD_RemovePower(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Wrong command usage. Usage: sm_removepower <player>");
		return Plugin_Handled;
	}
	
	char player[32];
	GetCmdArg(1, player, sizeof(player));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		TF2_RemoveCondition(target_list[i], TFCond_HasRune);
		for (int x = 0; x < sizeof(pList); x++)
			TF2_RemoveCondition(target_list[i], pList[x]);
	}
	
	ReplyToCommand(client, "[SM] Removed powerups from %s", target_name);
	return Plugin_Handled;
}

public Action CMD_PowerList(int client, int args)
{
	ReplyToCommand(client, "[SM] Available powerup names: strength - haste - regen - resist - vampire - warlock - precision - agility - knockout - king - plague - supernova");
	return Plugin_Handled;
}

public Action CMD_PowerMenu(int client, int args)
{
	PowerMenu(client);
	return Plugin_Handled;
}

public int PowerMenuHdlr(Menu menu, MenuAction action, int a1, int a2)
{
	if (action == MenuAction_Select) {
		GetMenuItem(menu, a2, pSelect, sizeof(pSelect));
		PlayerListMenu(a1);
	}
	return 0;
}

public int PlayerMenuHdlr(Menu menu, MenuAction action, int a1, int a2)
{
	if (action == MenuAction_Select)
	{
		char pBuff[32];
		GetMenuItem(menu, a2, pBuff, sizeof(pBuff));
		
		int client = GetClientOfUserId(StringToInt(pBuff));
		
		TF2_AddCondition(client, TFCond_HasRune, TFCondDuration_Infinite);
		TF2_AddCondition(client, PowerNameToCond(pSelect), TFCondDuration_Infinite);
		
		PrintToChat(a1, "[SM] Gave powerup %s to %N", pSelect, client);
	}
	return 0;
}

// Custom functions for reliability and beautifulness (don't look, they're horrible to the eye!)
void GetPowerName(TFCond id, char[] buffer, int size) {
	switch (id) {
		case TFCond_RuneStrength:
			strcopy(buffer, size, "Strength");
		case TFCond_RuneHaste:
			strcopy(buffer, size, "Haste");
		case TFCond_RuneRegen:
			strcopy(buffer, size, "Regeneration");
		case TFCond_RuneResist:
			strcopy(buffer, size, "Resistance");
		case TFCond_RuneVampire:
			strcopy(buffer, size, "Vampire");
		case TFCond_RuneWarlock:
			strcopy(buffer, size, "Warlock");
		case TFCond_RunePrecision:
			strcopy(buffer, size, "Precision");
		case TFCond_RuneAgility:
			strcopy(buffer, size, "Agility");
		case TFCond_RuneKnockout:
			strcopy(buffer, size, "Knockout");
		case TFCond_KingRune:
			strcopy(buffer, size, "King");
		case TFCond_PlagueRune:
			strcopy(buffer, size, "Plague");
		case TFCond_SupernovaRune:
			strcopy(buffer, size, "Supernova");
	}
}

TFCond PowerNameToCond(char[] name)
{
	if (StrContains(name, "strength", false) != -1)
		return TFCond_RuneStrength;
	if (StrContains(name, "haste", false) != -1)
		return TFCond_RuneHaste;
	if (StrContains(name, "regen", false) != -1)
		return TFCond_RuneRegen;
	if (StrContains(name, "resist", false) != -1)
		return TFCond_RuneResist;
	if (StrContains(name, "vampire", false) != -1)
		return TFCond_RuneVampire;
	if (StrContains(name, "warlock", false) != -1)
		return TFCond_RuneWarlock;
	if (StrContains(name, "precision", false) != -1)
		return TFCond_RunePrecision;
	if (StrContains(name, "agility", false) != -1)
		return TFCond_RuneAgility;
	if (StrContains(name, "knockout", false) != -1)
		return TFCond_RuneKnockout;
	if (StrContains(name, "king", false) != -1)
		return TFCond_KingRune;
	if (StrContains(name, "plague", false) != -1)
		return TFCond_PlagueRune;
	if (StrContains(name, "supernova", false) != -1)
		return TFCond_SupernovaRune;
	return TFCond_Unknown1;
}

void PowerMenu(int client)
{
	Menu pMenu = CreateMenu(PowerMenuHdlr);
	
	SetMenuTitle(pMenu, "Powerup Menu");
	
	for (int i = 0; i < sizeof(pList); i++)
	{
		char pStr[32];
		GetPowerName(pList[i], pStr, sizeof(pStr));
		
		AddMenuItem(pMenu, pStr, pStr);
	}
	
	SetMenuExitButton(pMenu, true);
	DisplayMenu(pMenu, client, MENU_TIME_FOREVER);
}

void PlayerListMenu(int client)
{
	Menu pPlayer = CreateMenu(PlayerMenuHdlr);
	
	SetMenuTitle(pPlayer, "Select a player...");
	
	AddTargetsToMenu(pPlayer, client, true, true);
	
	SetMenuExitButton(pPlayer, true);
	DisplayMenu(pPlayer, client, MENU_TIME_FOREVER);
}