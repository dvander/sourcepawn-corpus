#include <sourcemod>
#include <morecolors>
#include <clientprefs>
#include <tf2itemsinfo>

new kill[MAXPLAYERS+1] = 0;
new death[MAXPLAYERS+1] = 0;
new shot_prima[MAXPLAYERS+1] = 0;
new shot_secon[MAXPLAYERS+1] = 0;
new shot_melee[MAXPLAYERS+1] = 0;
new houres[MAXPLAYERS+1] = 0;
new mins[MAXPLAYERS+1] = 0;
new secs[MAXPLAYERS+1] = 0;

new Handle:menu_ratio;
new Handle:RefreshPanel[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TimeOnServer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:Cvar_reset_ration_flag;

new Handle:Cookie_kill;
new Handle:Cookie_death;
new Handle:Cookie_shot_prima;
new Handle:Cookie_shot_secon;
new Handle:Cookie_shot_melee;
new Handle:Cookie_time_on_server;

public OnPluginStart()
{
	RegConsoleCmd("sm_showratio", DisplayRatioPanel);
	RegConsoleCmd("sm_myratio", DisplayRatio);
	RegConsoleCmd("sm_resetratio", DisplayResetRatio);
	
	Cvar_reset_ration_flag = CreateConVar("sm_ration_reset_flag", "z", "What should be the flag to allow the reset of a player ratio.");
	
	Cookie_kill = RegClientCookie("Ratio_kill", "Store the number of kills", CookieAccess_Protected);
	Cookie_death = RegClientCookie("Ratio_death", "Store the number of death", CookieAccess_Protected);
	Cookie_shot_prima = RegClientCookie("Ratio_shot_prima", "Store the number of time player used is primary", CookieAccess_Protected);
	Cookie_shot_secon = RegClientCookie("Ratio_shot_secon", "Store the number of time player used is secondary", CookieAccess_Protected);
	Cookie_shot_melee = RegClientCookie("Ratio_shot_melee", "Store the number of time player used is melee", CookieAccess_Protected);
	Cookie_time_on_server = RegClientCookie("Ratio_time_on_server", "Store the ammount of time of a player in the server", CookieAccess_Protected);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	LoadTranslations("common.phrases");
	
	for (new i = MaxClients; i > 0; --i)
	{
		if (!AreClientCookiesCached(i))
		{
			continue;
		}
		OnClientCookiesCached(i);
		
		if (TimeOnServer[i] != INVALID_HANDLE)
		{
			KillTimer(TimeOnServer[i]);
			TimeOnServer[i] = INVALID_HANDLE;
		}
		TimeOnServer[i] = CreateTimer(1.0, ManageTime, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientCookiesCached(client)
{
	decl String:sCookie_kill[11];
	decl String:sCookie_death[11];
	decl String:sCookie_shot_prima[11];
	decl String:sCookie_shot_secon[11];
	decl String:sCookie_shot_melee[11];
	decl String:sCookie_time_on_server[100];
	decl String:time_part[3][10];
	
	GetClientCookie(client, Cookie_kill, sCookie_kill, sizeof(sCookie_kill));
	GetClientCookie(client, Cookie_death, sCookie_death, sizeof(sCookie_death));
	GetClientCookie(client, Cookie_shot_prima, sCookie_shot_prima, sizeof(sCookie_shot_prima));
	GetClientCookie(client, Cookie_shot_secon, sCookie_shot_secon, sizeof(sCookie_shot_secon));
	GetClientCookie(client, Cookie_shot_melee, sCookie_shot_melee, sizeof(sCookie_shot_melee));
	GetClientCookie(client, Cookie_time_on_server, sCookie_time_on_server, sizeof(sCookie_time_on_server));

	kill[client] = StringToInt(sCookie_kill);
	death[client] = StringToInt(sCookie_death);
	shot_prima[client] = StringToInt(sCookie_shot_prima);
	shot_secon[client] = StringToInt(sCookie_shot_secon);
	shot_melee[client] = StringToInt(sCookie_shot_melee);
	ExplodeString(sCookie_time_on_server, ":", time_part, sizeof(time_part), sizeof(time_part[]));
	houres[client] = StringToInt(time_part[0]);
	mins[client] = StringToInt(time_part[1]);
	secs[client] = StringToInt(time_part[2]);
}

public OnPluginEnd()
{
	for (new i = MaxClients; i > 0; --i)
	{
		SaveCookie(i);
	}
}

public OnClientConnected(client)
{
	TimeOnServer[client] = CreateTimer(1.0, ManageTime, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:ManageTime(Handle:timer, any:client)
{
	if(secs[client] != 59)
	{
		secs[client]++;
	}
	else
	{
		secs[client] = 0;
		if(mins[client] != 59)
		{
			mins[client]++;
		}
		else
		{
			mins[client] = 0;
			houres[client]++;
		}
	}
}

public OnClientDisconnect(client)
{
	SaveCookie(client);
	if (RefreshPanel[client] != INVALID_HANDLE)
	{
		KillTimer(RefreshPanel[client]);
		RefreshPanel[client] = INVALID_HANDLE;
	}
	if (TimeOnServer[client] != INVALID_HANDLE)
	{
		KillTimer(TimeOnServer[client]);
		TimeOnServer[client] = INVALID_HANDLE;
	}
	kill[client] = 0;
	death[client] = 0;
	shot_prima[client] = 0;
	shot_secon[client] = 0;
	shot_melee[client] = 0;
	houres[client] = 0;
	mins[client] = 0;
	secs[client] = 0;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	new actual_wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new wep_index = GetEntProp(actual_wep, Prop_Send, "m_iItemDefinitionIndex");
	new iItemSlot = _:TF2II_GetItemSlot(wep_index);
	
	new slot; 
	for (new i = 0; i <= 5; i++)
	{
		if (weapon == GetPlayerWeaponSlot(client, i))
		{
			slot = i;
			break;
		}
	}
	
	switch(slot)
	{
		case 0 :
		{
			shot_prima[client]++;
		}
		case 1 :
		{
			shot_secon[client]++;
		}
		case 2 :
		{
			shot_melee[client]++;
		}
		default :
		{
			PrintToServer("-------- Ration.smx --------");
			PrintToServer("Warning : user use a unrecognized slot : %i", iItemSlot);
			PrintToServer("----------------------------");
		}
	}
}

public Action:DisplayRatioPanel(client, args)
{
	if(args == 0)
	{
		DisplayPlayerMenu(client, false);
		
		return Plugin_Handled;
	}
	else
	{
		CPrintToChat(client, "{green}[Ratio]{default} Usage : !showratio");
		
		return Plugin_Continue;
	}
}

public Action:DisplayRatio(client, args)
{
	DisplayPlayerScoreMenu(client, client);
	
	new Handle:pack;
	
	if(IsValidClient(client) && RefreshPanel[client] != INVALID_HANDLE)
	{
		KillTimer(RefreshPanel[client]);
		RefreshPanel[client] = INVALID_HANDLE;
	}
	RefreshPanel[client] = CreateDataTimer(0.1, RefreshRatioPanel, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	WritePackCell(pack, client);
	WritePackCell(pack, client);
	
	return Plugin_Handled;
}

public Action:RefreshRatioPanel(Handle:timer, any:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new target = ReadPackCell(pack);
	DisplayPlayerScoreMenu(client, target);
}

public Action:DisplayResetRatio(client, args)
{
	if(args == 0)
	{
		kill[client] = 0;
		death[client] = 0;
		shot_prima[client] = 0;
		shot_secon[client] = 0;
		shot_melee[client] = 0;
		houres[client] = 0;
		mins[client] = 0;
		secs[client] = 0;
	}
	else
	{
		decl String:adm_flag[10];
		GetConVarString(Cvar_reset_ration_flag, adm_flag, sizeof(adm_flag));
		new custom_flag = ReadFlagString(adm_flag);
		
		if(CheckCommandAccess(client, "sm_reset_ratio_acces", custom_flag,true) == false)
		{
			CPrintToChat(client, "{green}[Ratio]{default} You can only reset your own ratio !");
			return Plugin_Handled;
		}
		
		if(args != 1)
		{
			CPrintToChat(client, "{green}[Ratio]{default} Usage : sm_resetratio -> reset your own ratio");
			CPrintToChat(client, "{green}[Ratio]{default} Usage : sm_resetratio [PLAYER] -> reset a player ratio");
			return Plugin_Handled;
		}
		
		decl String:arg1[100];
		decl String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS];
		new target_count;
		new bool:tn_is_ml;
		
		GetCmdArg(1, arg1, sizeof(arg1));
		
		if ((target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (new i = 0; i < target_count; i++)
		{
			kill[target_list[i]] = 0;
			death[target_list[i]] = 0;
			shot_prima[target_list[i]] = 0;
			shot_secon[target_list[i]] = 0;
			shot_melee[target_list[i]] = 0;
		}
		
		if (tn_is_ml)
		{
			CPrintToChat(client, "{green}[Ratio]{default} Ration successful reset on %t !", target_name);
		}
		else
		{
			CPrintToChat(client, "{green}[Ratio]{default} Ration successful reset on %s !", target_name);
		}
	}
	
	return Plugin_Handled;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(killer) && IsValidClient(victim))
	{
		if(killer == victim)
		{
			death[killer]++;
		}
		else
		{
			kill[killer]++;
			death[victim]++;
		}
	}
	
	return Plugin_Continue;
}


stock DisplayPlayerScoreMenu(client, target)
{
	decl String:item1[200];
	decl String:item2[200];
	decl String:item3[200];
	decl String:item4[200];
	decl String:item5[200];
	decl String:item6[200];
	decl String:item7[200];
	decl String:item8[200];
	decl String:time[200];
	decl String:p_name[200];
	
	new Float:ratio = 0.0;
	if(death[target] != 0)
		ratio = float(kill[target])/float(death[target]);
	else
		ratio = float(kill[target]);
	
	Format(item1, sizeof(item1), "Kill : %i", kill[target]);
	Format(item2, sizeof(item2), "Death : %i", death[target]);
	Format(item3, sizeof(item3), "K:D ratio : %.2f", ratio);
	Format(item4, sizeof(item4), "Primary shots : %i", shot_prima[target]);
	Format(item5, sizeof(item5), "Secondary shots : %i", shot_secon[target]);
	Format(item6, sizeof(item6), "Melee Swings : %i", shot_melee[target]);
	Format(time, sizeof(time), "%2i:%2i:%2i", houres[target], mins[target], secs[target]);
	ReplaceString(time, sizeof(time), " ", "0");
	Format(item8, sizeof(item8), "Total time in server : %s", time);
	
	GetClientName(target, p_name, sizeof(p_name))
	Format(item7, sizeof(item7), "Stat of %s", p_name);
	
	menu_ratio = CreateMenu(MenuHandler1); 
	SetMenuTitle(menu_ratio, item7);
	AddMenuItem(menu_ratio, "Kill", item1); 
	AddMenuItem(menu_ratio, "Death", item2); 
	AddMenuItem(menu_ratio, "Ratio", item3); 
	AddMenuItem(menu_ratio, "Pshot", item4); 
	AddMenuItem(menu_ratio, "Sshot", item5); 
	AddMenuItem(menu_ratio, "Mshot", item6); 
	AddMenuItem(menu_ratio, "Time", item8); 
	SetMenuExitButton(menu_ratio, false); 
	DisplayMenu(menu_ratio, client, MENU_TIME_FOREVER);
}

public MenuHandler1(Handle:menu, MenuAction:action, client, param2)  
{
	if (action == MenuAction_Select)
	{
		if(IsValidClient(client) && RefreshPanel[client] != INVALID_HANDLE)
		{
			KillTimer(RefreshPanel[client]);
			RefreshPanel[client] = INVALID_HANDLE;
		}
		DisplayPlayerMenu(client, true);
	}
	else if (action == MenuAction_End)  
	{  
		if(IsValidClient(client) && RefreshPanel[client] != INVALID_HANDLE)
		{
			KillTimer(RefreshPanel[client]);
			RefreshPanel[client] = INVALID_HANDLE;
		}
		if(menu != INVALID_HANDLE)
		{
			CloseHandle(menu);
		}
	} 
} 

public Action:DisplayPlayerMenu(client, bool:send_from_panel)
{	

	new player;
	for(new i = 0; i < MaxClients; i++) 
	{
		if(IsValidClient(i)) player++;
	}
	
	if(player == 1 && send_from_panel == false)
	{
		CPrintToChat(client, "{green}[Ratio]{default} No one connected for the moment ! use !myratio instead.");
		return Plugin_Handled;
	}
	
	decl String:name[200];
	decl String:random_g[80];
	new Handle:menuPlayer = CreateMenu(MenuHandler2); 
	SetMenuTitle(menuPlayer, "Select a player :");
	
	for(new i = 0; i < MaxClients; i++) 
	{ 
		if(i > 0 && i <= MaxClients && IsClientInGame(i) && i != client) 
		{
			GetClientName(i, name, sizeof(name)); 
			IntToString(i, random_g, sizeof(random_g));
			AddMenuItem(menuPlayer, random_g, name);
		}
	}  
	SetMenuExitButton(menuPlayer, true); 
	DisplayMenu(menuPlayer, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public MenuHandler2(Handle:menu, MenuAction:action, client, param2)  
{    
	if (action == MenuAction_Select && IsClientInGame(client))  
	{
		decl String:szInfo[8];
		GetMenuItem(menu, param2, szInfo, sizeof(szInfo));
		new target = StringToInt(szInfo)
		if(IsValidClient(client) && RefreshPanel[client] != INVALID_HANDLE)
		{
			KillTimer(RefreshPanel[client]);
			RefreshPanel[client] = INVALID_HANDLE;
		}
		new Handle:pack;
		
		if(IsValidClient(client) && RefreshPanel[client] != INVALID_HANDLE)
		{
			KillTimer(RefreshPanel[client]);
			RefreshPanel[client] = INVALID_HANDLE;
		}
		RefreshPanel[client] = CreateDataTimer(0.1, RefreshRatioPanel, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		WritePackCell(pack, client);
		WritePackCell(pack, target);
		
		DisplayPlayerScoreMenu(client, target);
	} 
	
	else if (action == MenuAction_End)  
	{  
		if(menu != INVALID_HANDLE)
		{
			CloseHandle(menu);
		} 
	} 
}

stock SaveCookie(client)
{
	decl String:sCookie_kill[11];
	decl String:sCookie_death[11];
	decl String:sCookie_shot_prima[11];
	decl String:sCookie_shot_secon[11];
	decl String:sCookie_shot_melee[11];		
	decl String:sCookie_time_in_server[100];		
		
	IntToString(kill[client], sCookie_kill, sizeof(sCookie_kill));
	IntToString(death[client], sCookie_death, sizeof(sCookie_death));
	IntToString(shot_prima[client], sCookie_shot_prima, sizeof(sCookie_shot_prima));
	IntToString(shot_secon[client], sCookie_shot_secon, sizeof(sCookie_shot_secon));
	IntToString(shot_melee[client], sCookie_shot_melee, sizeof(sCookie_shot_melee));
	Format(sCookie_time_in_server, sizeof(sCookie_time_in_server), "%i:%i:%i", houres[client], mins[client], secs[client]);

	SetClientCookie(client, Cookie_kill, sCookie_kill);
	SetClientCookie(client, Cookie_death, sCookie_death);
	SetClientCookie(client, Cookie_shot_prima, sCookie_shot_prima);
	SetClientCookie(client, Cookie_shot_secon, sCookie_shot_secon);
	SetClientCookie(client, Cookie_shot_melee, sCookie_shot_melee);
	SetClientCookie(client, Cookie_time_on_server, sCookie_time_in_server);
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
