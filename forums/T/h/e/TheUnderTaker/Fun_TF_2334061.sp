#include <sourcemod>
#include <tf2_stocks>
#include <tf2>

#pragma semicolon 1
#pragma tabsize 0

public Plugin myinfo = {
	name        = "[TF2] Fun TF",
	author      = "TheUnderTaker",
	description = "Fun tf2 commands for team fortress 2, players got commands for themself and admins got commands for themself & another players.!",
	version     = "1.0",
	url         = "http://steamcommunity.com/id/theundertaker007/"
};

public OnPluginStart()
{
	// Player Commands
	
	RegConsoleCmd("sm_civilian", P_Civilian);
	RegConsoleCmd("sm_fireme", P_Fire);
	RegConsoleCmd("sm_blood", P_Blood);
	RegConsoleCmd("sm_regen", P_Regen);
	RegConsoleCmd("sm_stripme", P_Strip);
	RegConsoleCmd("sm_respawnme", P_Respawn);
	RegConsoleCmd("sm_class", P_Class);
	RegConsoleCmd("sm_fcmds", P_Cmds);
	
	// Admin Commands
	
	RegAdminCmd("sm_stun", A_Stun, ADMFLAG_GENERIC);
	/* No need fire by target, SM already got /burn */
	RegAdminCmd("sm_cut", A_Blood, ADMFLAG_GENERIC);
	RegAdminCmd("sm_regenp", A_Regen, ADMFLAG_GENERIC);
	RegAdminCmd("sm_strip", A_Strip, ADMFLAG_GENERIC);
	RegAdminCmd("sm_respawn", A_Respawn, ADMFLAG_GENERIC);
	RegAdminCmd("sm_setclass", A_Class, ADMFLAG_GENERIC);
}

public Action:P_Cmds(client, args)
{
	new Handle:menu = CreateMenu(CMDMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	SetMenuTitle(menu, "Fun TF - Command + Description");
	AddMenuItem(menu, "X", "Player Commands:", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "----------------", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!civilian <seconds> - Stun yourself, You can't do anything.", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!fireme <seconds> - Turn you into fire, Stop = 0", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!blood <seconds> - Make you bleed for seconds by you can choose, Stop = 0.", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!regen - Regenerate yourself; Supply + Health.", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!stripme - Removes all your weapons.", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!respawnme - Respawn you.", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!class [class] - Set you to class.", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!giveadmin - Not give you admin.", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "Admin Commands:", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "---------------", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!stun <target> <time> - Stuns player for specific time, Make him civilian(Stop = 0).", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!cut <target> <seconds> - Force bleed on player.", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!regenp <target> - Regenerate player.", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!strip <target> - Removes all weapon of target.", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!respawn <target> - Respawn player", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!setclass <target> <class> - Set player class.", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "---------------", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "Fun TF Version 1.0", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "By TheUnderTaker", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "Okay", "Okay");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public CMDMenu_Callback(Handle:menu, MenuAction:action, client, item)
{
        switch (action)
        {
				case MenuAction_Select:
                {
                        decl String:item_name[64];
                        GetMenuItem(menu, item, item_name, sizeof(item_name));
                        if(StrEqual(item_name, "Okay"))
                        {
                        		/* EMPTY */
                        }
                }
                case MenuAction_End:
                {
                        CloseHandle(menu);
                }
        }
}

public Action:P_Civilian(client, args)
{
	if(!IsPlayerAlive(client))
	{
	ReplyToCommand(client, "[SM] You must be alive to use this command.");
	return Plugin_Handled;
	}

	char store_duration[32];
	new Float:duration;
	GetCmdArg(1, store_duration, sizeof(store_duration));
	duration = StringToFloat(store_duration);
	TF2_StunPlayer(client, duration, _, 96, 0);
	ReplyToCommand(client, "[SM] Civilian mode enabled for %f seconds", duration);
	
	return Plugin_Handled;
}

public Action:P_Fire(client, args)
{
	if(args != 1)
	{
	ReplyToCommand(client, "[SM] Usage: sm_fireme <duration>");
	}
	if(!IsPlayerAlive(client))
	{
	ReplyToCommand(client, "[SM] You must be alive to use this command.");
	return Plugin_Handled;
	}
	
	char store_duration[32];
	new Float:duration;
	GetCmdArg(1, store_duration, sizeof(store_duration));
	duration = StringToFloat(store_duration);
	IgniteEntity(client, duration);
	PrintToChat(client, "You're now burning for the next %f seconds!", duration);
	
	return Plugin_Handled;
}

public Action:P_Blood(client, args)
{
	if(args != 1)
	{
	ReplyToCommand(client, "[SM] Usage: sm_blood <duration>");
	return Plugin_Handled;
	}
	if(!IsPlayerAlive(client))
	{
	ReplyToCommand(client, "[SM] You must be alive to use this command.");
	return Plugin_Handled;
	}
	
	char store_duration[32];
	new Float:duration;
	GetCmdArg(1, store_duration, sizeof(store_duration));
	duration = StringToFloat(store_duration);
	TF2_MakeBleed(client, client, duration);
	PrintToChat(client, "You're now Bleed for %f seconds!", duration);
	return Plugin_Handled;
}

public Action:P_Regen(client, args)
{
	if(!IsPlayerAlive(client))
	{
	ReplyToCommand(client, "[SM] You must be alive to use this command.");
	return Plugin_Handled;
	}
	else {
	TF2_RegeneratePlayer(client);
	PrintToChat(client, "You've regenerated! Your Ammo + Health are now full!");
	}
	return Plugin_Handled;
}

public Action:P_Strip(client, args)
{
	if(!IsPlayerAlive(client))
	{
	ReplyToCommand(client, "[SM] You must be alive to use this command.");
	return Plugin_Handled;
	}
	else {
	TF2_RemoveAllWeapons(client);
	PrintToChat(client, "You stripped all your weapons!");
	}
	return Plugin_Handled;
}

public Action:P_Respawn(client, args)
{
	if(IsPlayerAlive(client))
	{
	ReplyToCommand(client, "[SM] You must be dead to use this command");
	return Plugin_Handled;
	}
	else {
	TF2_RespawnPlayer(client);
	}
	return Plugin_Handled;
}

public Action:P_Class(client, args)
{
	if(args != 1)
	{
	ReplyToCommand(client, "[SM] Usage: sm_class <class>");
	return Plugin_Handled;
	}
	char who[10];
	
	GetCmdArg(1, who, sizeof(who));
	
	if(StrEqual(who, "scout"))
	{
	TF2_SetPlayerClass(client, TFClass_Scout);
	TF2_RegeneratePlayer(client);
	}
	else if(StrEqual(who, "soldier"))
	{
	TF2_SetPlayerClass(client, TFClass_Soldier);
	TF2_RegeneratePlayer(client);
	}
	else if(StrEqual(who, "pyro"))
	{
	TF2_SetPlayerClass(client, TFClass_Pyro);
	TF2_RegeneratePlayer(client);
	}
	else if(StrEqual(who, "demoman"))
	{
	TF2_SetPlayerClass(client, TFClass_DemoMan);
	TF2_RegeneratePlayer(client);
	}
	else if(StrEqual(who, "heavy"))
	{
	TF2_SetPlayerClass(client, TFClass_Heavy);
	TF2_RegeneratePlayer(client);
	}
	else if(StrEqual(who, "engineer"))
	{
	TF2_SetPlayerClass(client, TFClass_Engineer);
	TF2_RegeneratePlayer(client);
	}
	else if(StrEqual(who, "medic"))
	{
	TF2_SetPlayerClass(client, TFClass_Medic);
	TF2_RegeneratePlayer(client);
	}
	else if(StrEqual(who, "sniper"))
	{
	TF2_SetPlayerClass(client, TFClass_Sniper);
	TF2_RegeneratePlayer(client);
	}
	else if(StrEqual(who, "spy"))
	{
	TF2_SetPlayerClass(client, TFClass_Spy);
	TF2_RegeneratePlayer(client);
	}
	
	return Plugin_Handled;
}

public Action:A_Stun(client, args)
{
	if(args < 2 || args > 2)
	{
	ReplyToCommand(client, "[SM] Usage:sm_stun <target> <duration>");
	return Plugin_Handled;
	}
	char arg1[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
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
	
	char store_duration[32];
	new Float:duration;
	GetCmdArg(2, store_duration, sizeof(store_duration));
	duration = StringToFloat(store_duration);
 
	for (int i = 0; i < target_count; i++)
	{
		if(IsPlayerAlive(target_list[i]))
		{
		TF2_StunPlayer(target_list[i], duration, _, TF_STUNFLAGS_LOSERSTATE, 0);
		PrintToChatAll("%N: Forced Civilian Mode on %N for %d seconds", client, target_list[i], duration);
		}
		else
		{
		ReplyToCommand(client, "Target isn't alive.");
		}
	}
	return Plugin_Handled;
}

public Action:A_Blood(client, args)
{
	if(args != 2)
	{
	ReplyToCommand(client, "[SM] Usage: sm_cut <target> <duration>");
	return Plugin_Handled;
	}
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
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
	if(!IsPlayerAlive(target_list[i]))
	{
	ReplyToCommand(client, "[SM] Target isn't alive.");
	}
	else {
	char store_duration[32];
	new Float:duration;
	GetCmdArg(2, store_duration, sizeof(store_duration));
	duration = StringToFloat(store_duration);
	TF2_MakeBleed(target_list[i], client, duration);
	PrintToChatAll("%N: Cutted %N for %d seconds.", client, target_name, duration);
	}
	}
	
	return Plugin_Handled;
}

public Action:A_Regen(client, args)
{
	if(args != 1)
	{
	ReplyToCommand(client, "[SM] Usage: sm_regenp <target>");
	return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
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
	if(!IsPlayerAlive(target_list[i]))
	{
	ReplyToCommand(client, "[SM] Target isn't alive.");
	}
	else {
	TF2_RegeneratePlayer(target_list[i]);
	PrintToChatAll("%N: Regenerated %N.", client, target_name);
	}
	}
	
	return Plugin_Handled;
}

public Action:A_Strip(client, args)
{
	if(args != 1)
	{
	ReplyToCommand(client, "[SM] Usage: sm_strip <target>");
	return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
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
	if(!IsPlayerAlive(target_list[i]))
	{
	ReplyToCommand(client, "[SM] Target isn't alive.");
	}
	else {
	TF2_RemoveAllWeapons(target_list[i]);
	PrintToChatAll("%N: Stripped %N.", client, target_name);
	}
	}
	return Plugin_Handled;
}

public Action:A_Respawn(client, args)
{
	if(args != 1)
	{
	ReplyToCommand(client, "[SM] Usage: sm_respawn <target>");
	return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
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
	if(!IsPlayerAlive(target_list[i]))
	{
	ReplyToCommand(client, "[SM] Target isn't alive.");
	}
	else {
	TF2_RespawnPlayer(target_list[i]);
	PrintToChatAll("%N: Respawned %N.", client, target_name);
	}
	}
	
	return Plugin_Handled;
}

public Action:A_Class(client, args)
{
	if(args != 2)
	{
	ReplyToCommand(client, "[SM] Usage: sm_setclass <target> <class>");
	return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
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
	if(!IsPlayerAlive(target_list[i]))
	{
	ReplyToCommand(client, "[SM] Target isn't alive.");
	}
	
	char who[10];
	
	GetCmdArg(1, who, sizeof(who));
	
	if(StrEqual(who, "scout"))
	{
	TF2_SetPlayerClass(target_list[i], TFClass_Scout);
	PrintToChatAll("%N: Set class of %N to Scout", client, target_name);
	TF2_RegeneratePlayer(target_list[i]);
	}
	else if(StrEqual(who, "soldier"))
	{
	TF2_SetPlayerClass(target_list[i], TFClass_Soldier);
	PrintToChatAll("%N: Set class of %N to Soldier", client, target_name);
	TF2_RegeneratePlayer(target_list[i]);
	}
	else if(StrEqual(who, "pyro"))
	{
	TF2_SetPlayerClass(target_list[i], TFClass_Pyro);
	PrintToChatAll("%N: Set class of %N to Pyro", client, target_name);
	TF2_RegeneratePlayer(target_list[i]);
	}
	else if(StrEqual(who, "demoman"))
	{
	TF2_SetPlayerClass(target_list[i], TFClass_DemoMan);
	PrintToChatAll("%N: Set class of %N to Demoman", client, target_name);
	TF2_RegeneratePlayer(target_list[i]);
	}
	else if(StrEqual(who, "heavy"))
	{
	TF2_SetPlayerClass(target_list[i], TFClass_Heavy);
	PrintToChatAll("%N: Set class of %N to Heavy", client, target_name);
	TF2_RegeneratePlayer(target_list[i]);
	}
	else if(StrEqual(who, "engineer"))
	{
	TF2_SetPlayerClass(target_list[i], TFClass_Engineer);
	PrintToChatAll("%N: Set class of %N to Engineer", client, target_name);
	TF2_RegeneratePlayer(target_list[i]);
	}
	else if(StrEqual(who, "medic"))
	{
	TF2_SetPlayerClass(target_list[i], TFClass_Medic);
	PrintToChatAll("%N: Set class of %N to Medic", client, target_name);
	TF2_RegeneratePlayer(target_list[i]);
	}
	else if(StrEqual(who, "sniper"))
	{
	TF2_SetPlayerClass(target_list[i], TFClass_Sniper);
	PrintToChatAll("%N: Set class of %N to Sniper", client, target_name);
	TF2_RegeneratePlayer(target_list[i]);
	}
	else if(StrEqual(who, "spy"))
	{
	TF2_SetPlayerClass(target_list[i], TFClass_Spy);
	PrintToChatAll("%N: Set class of %N to Spy", client, target_name);
	TF2_RegeneratePlayer(target_list[i]);
	}
	}
	
	return Plugin_Handled;
}