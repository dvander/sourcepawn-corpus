#include <sourcemod>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <sdktools>
#include <updater>
#include <smlib>

#define UPDATE_URL			"http://tf2serverofarkarr.net63.net/TF2RPG/TF2RPGupdate.txt"

new Handle:Array_Upgrade;
new Handle:Array_rows;
new Handle:Array_values;
new Handle:Array_SQLreturn;
new Handle:Array_UpgradeInUse[MAXPLAYERS+1];
new Handle:DatabaseConnection;

new bool:HelpMessageDisplayed[MAXPLAYERS+1];

new String:plugin_tag[40] = "{green}[TF2RPG]{default}";

new p_level[MAXPLAYERS+1];
new p_exp[MAXPLAYERS+1];
new p_exp_level_up[MAXPLAYERS+1];
new p_cash[MAXPLAYERS+1];

public Plugin:myinfo =  
{  
	name = "TF2 RPG",  
	author = "Arkarr",  
	description = "A simple RPG plugin for TF2 !",  
	version = "0.2",  
	url = "http://www.sourcemod.net/"  
};

//Check if server is a TF2 server
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "[ERROR] This plugin only works in TF2 ! (TF2_RPG.smx)");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	//Commandes
	RegConsoleCmd("sm_rpgmenu", CMD_RPG_MENU, "Display the upgrades menu.");	
	
	//Event
	HookEvent("player_changeclass", Event_Changeclass);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	//Connect to DB :
	SQL_TConnect(GotDatabase, "TF2RPG");
	
	//Updater things :
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	//Create arrays
	Array_Upgrade = CreateArray(100, 0);
	Array_rows = CreateArray(100, 0);
	Array_values = CreateArray(100, 0);
	Array_SQLreturn = CreateArray(100, 0);
	
	//Display timer and restore cookies	
	for (new i = MaxClients; i > 0; --i)
	{
		if(IsValidClient(i))
		{
			SetHudTextParams(-1.0, 0.85, 0.5, 0, 255, 0, 200, 0, 0.00001, 0.000001, 0.000001);
			ShowHudText(i, -1, "[ Level : %i | Exp : %i/%i ]", p_level[i] , p_exp[i] , p_exp_level_up[i] );
			CreateTimer(0.48, RefreshStat, GetClientSerial(i), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			Array_UpgradeInUse[i] = CreateArray(100, 0);
		}
	}
	
	CreateTimer(30.0, SaveDataOfPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnClientPostAdminCheck(client)
{	
	ResetStatsPlayer(client);
	Array_UpgradeInUse[client] = CreateArray(100, 0);
	HelpMessageDisplayed[client] = false;
}

public OnClientDisconnect(client)
{
	ClearArray(Array_rows);
	PushArrayString(Array_rows, "level_player");
	PushArrayString(Array_rows, "exp_player");
	PushArrayString(Array_rows, "explevelup_player");
	PushArrayString(Array_rows, "cash_player");
	
	ClearArray(Array_values);
	decl String:tmp[100];
	IntToString(p_level[client], tmp, sizeof(tmp));
	PushArrayString(Array_values, tmp);
	IntToString(p_exp[client], tmp, sizeof(tmp));
	PushArrayString(Array_values, tmp);
	IntToString(p_exp_level_up[client], tmp, sizeof(tmp));
	PushArrayString(Array_values, tmp);
	IntToString(p_cash[client], tmp, sizeof(tmp));
	PushArrayString(Array_values, tmp);
	
	decl String:Condition[50], String:auth[30];
	GetClientAuthString(client, auth, sizeof(auth));
	Format(Condition, sizeof(Condition), "steam_id='%s'", auth);
	
	if(!SQL_UPDATE(client, DatabaseConnection,  Array_rows, Array_values, "t_player", Condition))
	{
		PrintToServer("[TF2RPG] ERROR: Can't save data of player %N into database !", client);
	}
}

public Updater_OnPluginUpdated()
{
	ReloadPlugin();
	PrintToServer("------------------------PLUGIN UPDATE----------------------");
	PrintToServer("TF2_mini_RPG.smx as been updated ! Please, don't forget to read the new config file to see if there is any changes.");
	PrintToServer("-----------------------------------------------------------");
}

public Action:CMD_RPG_MENU(client, args)
{
	DisplayRPGMenu(client);
	return Plugin_Handled;
}

public Menu_ApplyUpgrade(Handle:menu, MenuAction:action, client, menu_index)  
{ 
	if (action == MenuAction_Select)  
	{
		decl String:db_id[200];
		GetMenuItem(menu, menu_index, db_id, sizeof(db_id));
		UpdatePlayerUpgradeDB(client, db_id);
	}
	else if (action == MenuAction_End)  
	{
		CloseHandle(menu); 
	}
} 

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:Condition[50], String:auth[30], String:id_player[10], String:id_upg[40], String:class[10], String:class_db[10];
		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	TF2Attrib_RemoveAll(client);
	GetClientAuthString(client, auth, sizeof(auth));
	
	ClearArray(Array_rows);
	PushArrayString(Array_rows, "id_player");
	Format(Condition, sizeof(Condition), "steam_id='%s'", auth);
	Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_player", Condition);
	GetArrayString(Array_SQLreturn, 0, id_player, sizeof(id_player));
	
	ClearArray(Array_rows);
	PushArrayString(Array_rows, "class_upgrade");
	PushArrayString(Array_rows, "id_upgrade");
	Format(Condition, sizeof(Condition), "FK_id_player='%s'", id_player);
	new Handle:tmp;
	tmp =  SQL_GET(client, DatabaseConnection, Array_rows, "t_upgrades", Condition);
	for(new i = 0; i < GetArraySize(tmp)/2; i++)
	{
		new TFClassType:p_class = TF2_GetPlayerClass(client);
		switch(p_class)
		{
			case TFClass_Scout : Format(class, sizeof(class), "Scout");
			case TFClass_Sniper : Format(class, sizeof(class), "Sniper");
			case TFClass_Soldier : Format(class, sizeof(class), "Soldier");
			case TFClass_DemoMan : Format(class, sizeof(class), "Demoman");
			case TFClass_Medic : Format(class, sizeof(class), "Medic");
			case TFClass_Heavy : Format(class, sizeof(class), "Heavy");
			case TFClass_Pyro : Format(class, sizeof(class), "Pyro");
			case TFClass_Spy : Format(class, sizeof(class), "Spy");
			case TFClass_Engineer : Format(class, sizeof(class), "Engineer");
		}
		GetArrayString(tmp, (i*2)+0, class_db, sizeof(class_db));
		if(!StrContains(class, class_db, false) || StrEqual(class_db, "ALL", false))
		{
			GetArrayString(tmp, (i*2)+1, id_upg, sizeof(id_upg));
			AddUpgradeToPlayer(client, id_upg, true);
		}
	}
}

public Action:Event_Changeclass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(HelpMessageDisplayed[client] == false)
	{
		CPrintToChat(client, "%s This server is running TF2RPG ! Type {green}!rpgmenu{default} to display the upgrade menu !", plugin_tag);
		HelpMessageDisplayed[client] = true;
		SetHudTextParams(-1.0, 0.85, 0.5, 0, 255, 0, 200, 0, 0.00001, 0.000001, 0.000001);
		ShowHudText(client, -1, "[ Level : %i | Exp : %i/%i ]", p_level[client] , p_exp[client] , p_exp_level_up[client] );
		CreateTimer(0.48, RefreshStat, GetClientSerial(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(killer != client)
	{
		p_exp[killer]+= 5;
		if(p_exp[killer] >= p_exp_level_up[killer])
		{
			p_exp[killer] -= p_exp_level_up[killer];
			p_exp_level_up[killer] += 7;
			p_level[killer]++;
			CPrintToChatAll("%s %N has leveled up to {green}%i{default} !", plugin_tag, killer, p_level[killer]);
		}
	}
	
	new deathflags = GetEventInt(event, "death_flags");
	
	if(IsValidClient(client) && IsValidClient(killer))
	{
		if (deathflags != TF_DEATHFLAG_DEADRINGER && client != killer)
		{
			new Float:pos[3];
			GetClientAbsOrigin(client, pos);
			pos[2] += 10.0;
			createMoni(client, pos);
		}
	}
	return Plugin_Continue;
}

public Action:RefreshStat(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if(client == 0)
	{
		return Plugin_Continue;
	}
	SetHudTextParams(-1.0, 0.85, 0.5, 0, 255, 0, 255, 0, 0.00001, 0.000001, 0.000001);
	ShowHudText(client, -1, "[ Level : %i | Exp : %i/%i ]", p_level[client] , p_exp[client] , p_exp_level_up[client] );
	SetHudTextParams(0.14, 0.9, 0.5, 0, 255, 0, 255, 0, 0.00001, 0.000001, 0.000001);
	ShowHudText(client, -1, "Cash : %i $", p_cash[client]);
	
	return Plugin_Handled;
}

public Action:SaveDataOfPlayers(Handle:timer, any:serial)
{
	for (new i = MaxClients; i > 0; --i)
	{
		if(IsValidClient(i))
		{
			ClearArray(Array_rows);
			PushArrayString(Array_rows, "level_player");
			PushArrayString(Array_rows, "exp_player");
			PushArrayString(Array_rows, "explevelup_player");
			PushArrayString(Array_rows, "cash_player");
			
			ClearArray(Array_values);
			decl String:tmp[100];
			IntToString(p_level[i], tmp, sizeof(tmp));
			PushArrayString(Array_values, tmp);
			IntToString(p_exp[i], tmp, sizeof(tmp));
			PushArrayString(Array_values, tmp);
			IntToString(p_exp_level_up[i], tmp, sizeof(tmp));
			PushArrayString(Array_values, tmp);
			IntToString(p_cash[i], tmp, sizeof(tmp));
			PushArrayString(Array_values, tmp);
			
			decl String:Condition[50], String:auth[30];
			GetClientAuthString(i, auth, sizeof(auth));
			Format(Condition, sizeof(Condition), "steam_id='%s'", auth);
			
			if(!SQL_UPDATE(i, DatabaseConnection,  Array_rows, Array_values, "t_player", Condition))
			{
				PrintToServer("[TF2RPG] ERROR: Can't save data of player %N into database !", i);
			}
		}
	}
}

public Action:RestoreTmpUpgrade(Handle:timer, Handle:pack)
{
	new client;
	new target;
	decl String:attribut[100];
	new Float:value;
	decl String:upgrade_id[10];
 
	ResetPack(pack);
	client = ReadPackCell(pack);
	target = ReadPackCell(pack);
	ReadPackString(pack, attribut, sizeof(attribut));
	value = ReadPackFloat(pack);
	ReadPackString(pack, upgrade_id, sizeof(upgrade_id));
	
	TF2Attrib_SetByName(target, attribut, value);
	
	RemoveFromArray(Array_UpgradeInUse[client], FindStringInArray(Array_UpgradeInUse[client], upgrade_id));
}


stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if(hndl == INVALID_HANDLE)
    {
        SetFailState("[TF2RPG] Database failure: %s", error);
        return;
    }
	else
	{
		PrintToServer("[TF2RPG] Successfully connected to database !");
	}
	
    DatabaseConnection = hndl;
	
	UpdateUpgradesDatabase(DatabaseConnection);
	
	for (new i = MaxClients; i > 0; --i)
		if(IsValidClient(i))
			ResetStatsPlayer(i);
}

stock ResetStatsPlayer(client)
{
	ClearArray(Array_rows);
	
	PushArrayString(Array_rows, "level_player");
	PushArrayString(Array_rows, "exp_player");
	PushArrayString(Array_rows, "explevelup_player");
	PushArrayString(Array_rows, "cash_player");
	
	decl String:Condition[50], String:auth[30];
	GetClientAuthString(client, auth, sizeof(auth));
	Format(Condition, sizeof(Condition), "steam_id='%s'", auth);
	
	Array_SQLreturn = SQL_GET(client, DatabaseConnection, Array_rows, "t_player", Condition);
	if(GetArraySize(Array_SQLreturn) != 0)
	{
		decl String:lavel[300],String:exp[300],String:expn[300],String:cashp[300]; 
	
		GetArrayString(Array_SQLreturn, 0, lavel, sizeof(lavel));
		GetArrayString(Array_SQLreturn, 1, exp, sizeof(exp));
		GetArrayString(Array_SQLreturn, 2, expn, sizeof(expn));
		GetArrayString(Array_SQLreturn, 3, cashp, sizeof(cashp));
		
		p_level[client] = StringToInt(lavel);
		p_exp[client] = StringToInt(exp);
		p_exp_level_up[client] = StringToInt(expn);
		p_cash[client] = StringToInt(cashp);
	}
	else
	{
		GetClientAuthString(client, auth, sizeof(auth));
		
		ClearArray(Array_rows);
	
		PushArrayString(Array_rows, "level_player");
		PushArrayString(Array_rows, "exp_player");
		PushArrayString(Array_rows, "explevelup_player");
		PushArrayString(Array_rows, "cash_player");
		PushArrayString(Array_rows, "steam_id");
		
		ClearArray(Array_values);
		PushArrayString(Array_values, "1");
		PushArrayString(Array_values, "0");
		PushArrayString(Array_values, "100");
		PushArrayString(Array_values, "100");
		PushArrayString(Array_values, auth);
	
		SQL_INSERT(client, DatabaseConnection, Array_rows, Array_values, "t_player");
		
		p_level[client] = 1;
		p_exp[client] = 0;
		p_exp_level_up[client] = 100;
		p_cash[client] = 100;
	}
}

stock DisplayRPGMenu(client)
{
	decl String:menu_title[100], String:class[30];
	new TFClassType:p_class = TF2_GetPlayerClass(client);
	switch(p_class)
	{
		case TFClass_Unknown : CPrintToChat(client, "%s ERREUR! Can't find your TF2 class !", plugin_tag);
		case TFClass_Scout : Format(class, sizeof(class), "Scout");
		case TFClass_Sniper : Format(class, sizeof(class), "Sniper");
		case TFClass_Soldier : Format(class, sizeof(class), "Soldier");
		case TFClass_DemoMan : Format(class, sizeof(class), "Demoman");
		case TFClass_Medic : Format(class, sizeof(class), "Medic");
		case TFClass_Heavy : Format(class, sizeof(class), "Heavy");
		case TFClass_Pyro : Format(class, sizeof(class), "Pyro");
		case TFClass_Spy : Format(class, sizeof(class), "Spy");
		case TFClass_Engineer : Format(class, sizeof(class), "Engineer");
	}
	Format(menu_title, sizeof(menu_title), "TF2 RPG shop - %s", class);
	
	new Handle:MenuRPG = CreateMenu(Menu_ApplyUpgrade);
	SetMenuTitle(MenuRPG, menu_title);
	
	ClearArray(Array_rows);
	PushArrayString(Array_rows, "name_upgrade");
	PushArrayString(Array_rows, "cost_upgrade");
	PushArrayString(Array_rows, "level_upgrade");
	PushArrayString(Array_rows, "time_upgrade");
	PushArrayString(Array_rows, "id_upgrade");
	PushArrayString(Array_rows, "value_upgrade");
	
	decl String:condi[100];
	String_ToUpper(class, class, sizeof(class));
	Format(condi, sizeof(condi), "class_upgrade LIKE '%%%s%%' OR class_upgrade LIKE 'ALL'", class[3]);
	Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_store_upgrades", condi);
	if(GetArraySize(Array_SQLreturn) != 0)
	{
		for(new i = 0; i < (GetArraySize(Array_SQLreturn)/6); i++)
		{
			decl String:item_name[200], String:price[800], String:level[10], String:effect_time[200], String:id_upgrade[200], String:value[100];
		
			GetArrayString(Array_SQLreturn, ((i*6)+0), item_name, sizeof(item_name));
			GetArrayString(Array_SQLreturn, ((i*6)+1), price, sizeof(price));
			GetArrayString(Array_SQLreturn, ((i*6)+2), level, sizeof(level));
			GetArrayString(Array_SQLreturn, ((i*6)+3), effect_time, sizeof(effect_time));
			GetArrayString(Array_SQLreturn, ((i*6)+4), id_upgrade, sizeof(id_upgrade));
			GetArrayString(Array_SQLreturn, ((i*6)+5), value, sizeof(value));
			
			decl String:bit[10][64];
			new max_upg_lvl = ExplodeString(value, "/", bit, sizeof bit, sizeof bit[]);
			
			
			new Handle:tmp_arry;
			//Grab the player id in db
			decl String:auth[50], String:id_player[50];
			GetClientAuthString(client, auth, sizeof(auth));
			ClearArray(Array_rows);
			PushArrayString(Array_rows, "id_player");
			Format(condi, sizeof(condi), "steam_id='%s'", auth);
			tmp_arry =  SQL_GET(client, DatabaseConnection, Array_rows, "t_player", condi);
			GetArrayString(tmp_arry, 0, id_player, sizeof(id_player));
			
			decl String:upg_level[50];
			ClearArray(Array_rows);
			PushArrayString(Array_rows, "actlvl_upgrade");
			Format(condi, sizeof(condi), "id_upgrade=%s AND FK_id_player='%s'",id_upgrade, id_player);
			tmp_arry =  SQL_GET(client, DatabaseConnection, Array_rows, "t_upgrades", condi);
			if(GetArraySize(tmp_arry) != 0)
				GetArrayString(tmp_arry, 0, upg_level, sizeof(upg_level));
			else
				Format(upg_level, sizeof(upg_level), "0");
				
			decl String:list_price[20][64];
			ExplodeString(price, "/", list_price, sizeof list_price, sizeof list_price[]);
			
			decl String:item[100];
			if(StringToInt(effect_time) == -1)
				Format(item, sizeof(item), "%s - [%s $] [LVL %s] [%s/%i]", item_name, list_price[StringToInt(upg_level)], level, upg_level, max_upg_lvl);
			else
				Format(item, sizeof(item), "%s - [%s $] [LVL %s] [%s sec]", item_name, list_price[StringToInt(upg_level)], level, effect_time);
			
			if(FindStringInArray(Array_UpgradeInUse[client], id_upgrade) != -1 && StringToInt(effect_time) == -1 && max_upg_lvl == StringToInt(upg_level))
			{
				StrCat(item, sizeof(item), " [SOLD]");
				AddMenuItem(MenuRPG, id_upgrade, item, ITEMDRAW_DISABLED);
			}
			else if(FindStringInArray(Array_UpgradeInUse[client], id_upgrade) != -1 && StringToInt(effect_time) != -1)
			{
				StrCat(item, sizeof(item), " [IN USE]");
				AddMenuItem(MenuRPG, id_upgrade, item, ITEMDRAW_DISABLED);
			}
			else
			{
				AddMenuItem(MenuRPG, id_upgrade, item);
			}
		}
	}
	DisplayMenu(MenuRPG, client, MENU_TIME_FOREVER);
}

stock bool:UpdatePlayerUpgradeDB(client, const String:id_upgrade[])
{
	decl String:condi[50];
	decl String:auth[50];
	decl String:id_player[50];
	decl String:time_upgrade[50];
	decl String:value[200];
	
	GetClientAuthString(client, auth, sizeof(auth));
	
	ClearArray(Array_rows);
	PushArrayString(Array_rows, "time_upgrade");	
	Format(condi, sizeof(condi), "id_upgrade=%s",id_upgrade);
	Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_store_upgrades", condi);
	GetArrayString(Array_SQLreturn, 0, time_upgrade, sizeof(time_upgrade));
	
	if(StringToInt(time_upgrade) != -1)
	{
		ClearArray(Array_rows);
		PushArrayString(Array_rows, "attribute_upgrade");
		PushArrayString(Array_rows, "value_upgrade");
		PushArrayString(Array_rows, "level_upgrade");
		PushArrayString(Array_rows, "cost_upgrade");
		PushArrayString(Array_rows, "class_upgrade");
		PushArrayString(Array_rows, "override_upgrade");
		PushArrayString(Array_rows, "equip_upgrade");
		PushArrayString(Array_rows, "type_upgrade");
		PushArrayString(Array_rows, "actlvl_upgrade");
		
		Format(condi, sizeof(condi), "id_upgrade=%s",id_upgrade);
		Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_store_upgrades", condi);
		
		AddUpgradeToPlayer(client, id_upgrade, _, Array_SQLreturn);
		DisplayRPGMenu(client);
		return false;
	}
	
	//Grab the player id in db
	ClearArray(Array_rows);
	PushArrayString(Array_rows, "id_player");
	Format(condi, sizeof(condi), "steam_id='%s'", auth);
	Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_player", condi);
	GetArrayString(Array_SQLreturn, 0, id_player, sizeof(id_player));
	
	
	ClearArray(Array_rows);
	PushArrayString(Array_rows, "value_upgrade");
	Format(condi, sizeof(condi), "id_upgrade=%s",id_upgrade);
	Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_store_upgrades", condi);
	GetArrayString(Array_SQLreturn, 0, value, sizeof(value));
	
	decl String:bit[10][64], String:upg_level[50];
	new max_upg_lvl = ExplodeString(value, "/", bit, sizeof bit, sizeof bit[]);
	
	ClearArray(Array_rows);
	PushArrayString(Array_rows, "actlvl_upgrade");
	Format(condi, sizeof(condi), "id_upgrade='%s'", id_upgrade);
	Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_upgrades");
	
	if(GetArraySize(Array_SQLreturn) != 0)
		GetArrayString(Array_SQLreturn, 0, upg_level, sizeof(upg_level));
	else
		Format(upg_level, sizeof(upg_level), "0");
	
	//Grab the upgrade id in db of the id_player
	ClearArray(Array_rows);
	PushArrayString(Array_rows, "id_upgrade");	
	Format(condi, sizeof(condi), "id_upgrade=%s AND FK_id_player='%s'",id_upgrade, id_player);
	Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_upgrades", condi);
	
	if(GetArraySize(Array_SQLreturn) == 0) //Player don't have the upgrade with id 'id_upgrade'
	{
		if(AddUpgradeToPlayer(client, id_upgrade))
		{
			ClearArray(Array_rows);
			PushArrayString(Array_rows, "attribute_upgrade");
			PushArrayString(Array_rows, "value_upgrade");
			PushArrayString(Array_rows, "level_upgrade");
			PushArrayString(Array_rows, "class_upgrade");
			PushArrayString(Array_rows, "override_upgrade");
			PushArrayString(Array_rows, "equip_upgrade");
			PushArrayString(Array_rows, "type_upgrade");

			Format(condi, sizeof(condi), "id_upgrade=%s",id_upgrade);
			Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_store_upgrades", condi);
			
			ClearArray(Array_rows);
			PushArrayString(Array_rows, "id_player");
			
			GetClientAuthString(client, condi, sizeof(condi))
			Format(condi, sizeof(condi), "steam_id='%s'", condi);
			Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_player", condi);
			
			decl String:tmp[100], String:player_id[10];
			GetArrayString(Array_SQLreturn, 0, player_id, sizeof(player_id));
			
			ClearArray(Array_rows);
			PushArrayString(Array_rows, "attribute_upgrade");
			PushArrayString(Array_rows, "value_upgrade");
			PushArrayString(Array_rows, "level_upgrade");
			PushArrayString(Array_rows, "class_upgrade");
			PushArrayString(Array_rows, "override_upgrade");
			PushArrayString(Array_rows, "equip_upgrade");
			PushArrayString(Array_rows, "type_upgrade");
			PushArrayString(Array_rows, "cost_upgrade");
			
			Format(condi, sizeof(condi), "id_upgrade=%s",id_upgrade);
			Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_store_upgrades", condi);
			
			ClearArray(Array_rows);
			PushArrayString(Array_rows, "FK_id_player");
			PushArrayString(Array_rows, "attribute_upgrade");
			PushArrayString(Array_rows, "value_upgrade");
			PushArrayString(Array_rows, "level_upgrade");
			PushArrayString(Array_rows, "class_upgrade");
			PushArrayString(Array_rows, "override_upgrade");
			PushArrayString(Array_rows, "equip_upgrade");
			PushArrayString(Array_rows, "type_upgrade");
			PushArrayString(Array_rows, "cost_upgrade");
			PushArrayString(Array_rows, "id_upgrade");
			
			ClearArray(Array_values);		
			PushArrayString(Array_values, player_id);
			GetArrayString(Array_SQLreturn, 0, tmp, sizeof(tmp));
			PushArrayString(Array_values, tmp);
			GetArrayString(Array_SQLreturn, 1, tmp, sizeof(tmp));
			PushArrayString(Array_values, tmp);
			GetArrayString(Array_SQLreturn, 2, tmp, sizeof(tmp));
			PushArrayString(Array_values, tmp);
			GetArrayString(Array_SQLreturn, 3, tmp, sizeof(tmp));
			PushArrayString(Array_values, tmp);
			GetArrayString(Array_SQLreturn, 4, tmp, sizeof(tmp));
			PushArrayString(Array_values, tmp);
			GetArrayString(Array_SQLreturn, 5, tmp, sizeof(tmp));
			PushArrayString(Array_values, tmp);
			GetArrayString(Array_SQLreturn, 6, tmp, sizeof(tmp));
			PushArrayString(Array_values, tmp);
			GetArrayString(Array_SQLreturn, 7, tmp, sizeof(tmp));
			PushArrayString(Array_values, tmp);
			PushArrayString(Array_values, id_upgrade);
			
			SQL_INSERT(client, DatabaseConnection, Array_rows, Array_values, "t_upgrades");
		}		
	}
	else if(GetArraySize(Array_SQLreturn) > 0 && (max_upg_lvl > StringToInt(upg_level)))
	{
		if(AddUpgradeToPlayer(client, id_upgrade))
		{
			decl String:upglvl[10];
			ClearArray(Array_rows);
			PushArrayString(Array_rows, "actlvl_upgrade");
			Format(condi, sizeof(condi), "id_upgrade=%s AND FK_id_player='%s'",id_upgrade, id_player);
			Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_upgrades", condi);
			GetArrayString(Array_SQLreturn, 0, upglvl, sizeof(upglvl));
			new fdwgfew = StringToInt(upglvl);
			IntToString(fdwgfew+1, upglvl, sizeof(upglvl));
			
			ClearArray(Array_rows);
			PushArrayString(Array_rows, "actlvl_upgrade");
			
			ClearArray(Array_values);		
			PushArrayString(Array_values, upglvl);
			
			Format(condi, sizeof(condi), "id_upgrade=%s AND FK_id_player='%s'",id_upgrade, id_player);
			
			SQL_UPDATE(client, DatabaseConnection, Array_rows, Array_values, "t_upgrades", condi);
		}
	}
	
	DisplayRPGMenu(client);
	
	return true;
}

stock bool:AddUpgradeToPlayer(client, const String:id_upgrade[], bool:bypass_check = false, Handle:UpgradeArray = INVALID_HANDLE)
{
	decl String:condi[50], String:auth[50], String:id_player[50], String:actlvl[10];
	decl String:attribut[100], String:value[100], String:level[100], String:cost[100];
	decl String:class[100], String:override[100], String:equip[100], String:type[100];
	
	new target = -1;
	
	new Address:attr;
	
	new Float:new_value;
	new Float:new_value_SAVE;
	
	GetClientAuthString(client, auth, sizeof(auth));
	
	if(UpgradeArray == INVALID_HANDLE)
	{
		//Grab the player id in db
		ClearArray(Array_rows);
		PushArrayString(Array_rows, "id_player");
		Format(condi, sizeof(condi), "steam_id='%s'", auth);
		Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_player", condi);
		GetArrayString(Array_SQLreturn, 0, id_player, sizeof(id_player));
		
		//Grab the upgrade id in db of the id_player
		ClearArray(Array_rows);
		PushArrayString(Array_rows, "attribute_upgrade");
		PushArrayString(Array_rows, "value_upgrade");
		PushArrayString(Array_rows, "level_upgrade");
		PushArrayString(Array_rows, "class_upgrade");
		PushArrayString(Array_rows, "override_upgrade");
		PushArrayString(Array_rows, "equip_upgrade");
		PushArrayString(Array_rows, "type_upgrade");
		PushArrayString(Array_rows, "cost_upgrade");
		PushArrayString(Array_rows, "actlvl_upgrade");
		Format(condi, sizeof(condi), "id_upgrade=%s",id_upgrade, id_player);
		Array_SQLreturn = SQL_GET(client, DatabaseConnection, Array_rows, "t_upgrades", condi);
		if(GetArraySize(Array_SQLreturn) == 0)
		{
			Array_SQLreturn = SQL_GET(client, DatabaseConnection, Array_rows, "t_store_upgrades", condi);
		}
		
		GetArrayString(Array_SQLreturn, 0, attribut, sizeof(attribut));
		GetArrayString(Array_SQLreturn, 1, value, sizeof(value));
		GetArrayString(Array_SQLreturn, 2, level, sizeof(level));
		GetArrayString(Array_SQLreturn, 3, class, sizeof(class));
		GetArrayString(Array_SQLreturn, 4, override, sizeof(override));
		GetArrayString(Array_SQLreturn, 5, equip, sizeof(equip));
		GetArrayString(Array_SQLreturn, 6, type, sizeof(type));
		GetArrayString(Array_SQLreturn, 7, cost, sizeof(cost));
		GetArrayString(Array_SQLreturn, 8, actlvl, sizeof(actlvl));
	}
	else
	{
		GetArrayString(UpgradeArray, 0, attribut, sizeof(attribut));
		GetArrayString(UpgradeArray, 1, value, sizeof(value));
		GetArrayString(UpgradeArray, 2, level, sizeof(level));
		GetArrayString(UpgradeArray, 3, cost, sizeof(cost));
		GetArrayString(UpgradeArray, 4, class, sizeof(class)); //not for now
		GetArrayString(UpgradeArray, 5, override, sizeof(override));
		GetArrayString(UpgradeArray, 6, equip, sizeof(equip));
		GetArrayString(UpgradeArray, 7, type, sizeof(type));
		GetArrayString(UpgradeArray, 8, actlvl, sizeof(actlvl));
	}
	
	decl String:list_value[20][64];
	ExplodeString(value, "/", list_value, sizeof list_value, sizeof list_value[]);
	
	decl String:list_price[20][64];
	ExplodeString(cost, "/", list_price, sizeof list_price, sizeof list_price[]);
	
	new tab_index = StringToInt(actlvl)-1;
	if(tab_index < 0) tab_index = 0;
	
	if(p_level[client] < StringToInt(level) && bypass_check == false)
	{
		CPrintToChat(client, "%s You don't have the level to buy this !", plugin_tag);
		return false;
	}
	
	if(p_cash[client] < StringToInt(list_price[tab_index]) && bypass_check == false)
	{
		CPrintToChat(client, "%s You don't have enough cash to buy this !", plugin_tag);
		return false;
	}
	else if(bypass_check == false)
	{
		p_cash[client] -= StringToInt(list_price[tab_index]);
	}
	
	if(StrEqual(equip, "PLAYER", true))
		target = client;
	else if(StrEqual(equip, "PRIMARY", true))
		target = GetPlayerWeaponSlot(client, 0);
	else if(StrEqual(equip, "SECONDARY", true))
		target = GetPlayerWeaponSlot(client, 1);
	else if(StrEqual(equip, "MELEE", true))
		target = GetPlayerWeaponSlot(client, 2);
	else
		PrintToServer("[TF2RPG] ERROR: Can't found where the attribute should be added !");
	
	if(TF2Attrib_GetByName(target, attribut) != Address_Null) 
	{ 
		attr = TF2Attrib_GetByName(target, attribut);
		new_value = TF2Attrib_GetValue(attr);
		new_value_SAVE = new_value;
	}
	
	if(new_value_SAVE == 0.0)
	{
		if(StrEqual(type, "additive", true))
			new_value_SAVE = 0.0;
		else
			new_value_SAVE = 1.0;
	}
	
	if(StringToInt(override) == 0)
		new_value += StringToFloat(list_value[tab_index]);
	else
		new_value = StringToFloat(list_value[tab_index]);
		
	TF2Attrib_SetByName(target, attribut, new_value);
	
	decl String:time_upgrade[10];
	ClearArray(Array_rows);
	PushArrayString(Array_rows, "time_upgrade");
	Format(condi, sizeof(condi), "id_upgrade='%s'", id_upgrade);
	Array_SQLreturn =  SQL_GET(client, DatabaseConnection, Array_rows, "t_store_upgrades", condi);
	GetArrayString(Array_SQLreturn, 0, time_upgrade, sizeof(time_upgrade));
	
	if(StringToInt(time_upgrade) != -1)
	{
		new Handle:RestoreData;
		CreateDataTimer(StringToFloat(time_upgrade), RestoreTmpUpgrade, RestoreData);
		WritePackCell(RestoreData, client);
		WritePackCell(RestoreData, target);
		WritePackString(RestoreData, attribut);
		WritePackFloat(RestoreData, new_value_SAVE);
		WritePackString(RestoreData, id_upgrade);
	}
	
	PushArrayString(Array_UpgradeInUse[client], id_upgrade);

	return true;
}

stock UpdateUpgradesDatabase(Handle:DBConnection)
{
	SQL_FastQuery(DBConnection, "TRUNCATE TABLE t_store_upgrades");
	
	decl String:item_name[200], String:class_item[200], String:value[10], String:price[800], String:equip[100];
	decl String:level[10], String:att_type[100], String:override[10], String:attribut_name[200], String:effect_time[200];
	
	ClearArray(Array_rows);
	PushArrayString(Array_rows, "attribute_upgrade");
	PushArrayString(Array_rows, "value_upgrade");
	PushArrayString(Array_rows, "level_upgrade");
	PushArrayString(Array_rows, "cost_upgrade");
	PushArrayString(Array_rows, "name_upgrade");
	PushArrayString(Array_rows, "class_upgrade");
	PushArrayString(Array_rows, "time_upgrade");
	PushArrayString(Array_rows, "override_upgrade");
	PushArrayString(Array_rows, "equip_upgrade");
	PushArrayString(Array_rows, "type_upgrade");

	new Handle:kv = CreateKeyValues("TF2_RPG");
	FileToKeyValues(kv, "addons/sourcemod/configs/TF2_RPG.cfg");
	if (!KvGotoFirstSubKey(kv)) {
		return -1;
	}
	do
	{
		ClearArray(Array_values);
		KvGetString(kv, "class", class_item, sizeof(class_item));
		KvGetString(kv, "item_name", item_name, 200);
		KvGetString(kv, "attribut_name", attribut_name, sizeof(attribut_name));
		KvGetString(kv, "time", effect_time, sizeof(effect_time));
		KvGetString(kv, "value", value, sizeof(value));
		KvGetString(kv, "price", price, sizeof(price));
		KvGetString(kv, "override", override, sizeof(override));
		KvGetString(kv, "equip", equip, sizeof(equip));
		KvGetString(kv, "level", level, sizeof(level));
		KvGetString(kv, "att_type", att_type, sizeof(att_type));
		
		PushArrayString(Array_values, attribut_name);
		PushArrayString(Array_values, value);
		PushArrayString(Array_values, level);
		PushArrayString(Array_values, price);
		PushArrayString(Array_values, item_name);
		PushArrayString(Array_values, class_item);
		PushArrayString(Array_values, effect_time);
		PushArrayString(Array_values, override);
		PushArrayString(Array_values, equip);
		PushArrayString(Array_values, att_type);
		
		SQL_INSERT(0, DBConnection, Array_rows, Array_values, "t_store_upgrades");
		
	}while (KvGotoNextKey(kv));
	
	return 0;
}

stock createMoni(client, Float:pos[3]) 
{
	if(IsValidClient(client))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			{
				new moni = CreateEntityByName("item_currencypack_small");
				
				if(IsValidEntity(moni))
				{
					DispatchSpawn(moni);
					SetEntPropEnt(moni, Prop_Send, "m_hOwnerEntity", client);
					
					//		HookSingleEntityOutput(moni, "OnPlayerTouch", PickedSmall, true);
					SDKHook(moni, SDKHook_Touch, PickedSmall);
					SDKHook(moni, SDKHook_StartTouch, PickedSmall);
					CreateTimer(30.0, DeleteMoney, EntRefToEntIndex(moni));	
					
					TeleportEntity(moni, pos, NULL_VECTOR, NULL_VECTOR); 
				}
			}
			case 2:
			{
				new moni = CreateEntityByName("item_currencypack_medium");
				
				if(IsValidEntity(moni))
				{
					DispatchSpawn(moni);
					SetEntPropEnt(moni, Prop_Send, "m_hOwnerEntity", client);
					
					//		HookSingleEntityOutput(moni, "OnPlayerTouch", PickedMedium, true);
					SDKHook(moni, SDKHook_Touch, PickedMedium);
					SDKHook(moni, SDKHook_StartTouch, PickedMedium);
					CreateTimer(30.0, DeleteMoney, EntRefToEntIndex(moni));
					
					TeleportEntity(moni, pos, NULL_VECTOR, NULL_VECTOR); 
				}
			}
			case 3:
			{
				new moni = CreateEntityByName("item_currencypack_large");
				
				if(IsValidEntity(moni))
				{
					DispatchSpawn(moni);
					SetEntPropEnt(moni, Prop_Send, "m_hOwnerEntity", client);
					
					//		HookSingleEntityOutput(moni, "OnPlayerTouch", PickedLarge, true);
					SDKHook(moni, SDKHook_Touch, PickedLarge);
					SDKHook(moni, SDKHook_StartTouch, PickedLarge);
					CreateTimer(30.0, DeleteMoney, EntRefToEntIndex(moni));	
					
					TeleportEntity(moni, pos, NULL_VECTOR, NULL_VECTOR); 
				}
			}
		}
	}
}

public PickedSmall(entity, client)
{
	if(IsValidClient(client))
	{
		p_cash[client] += GetRandomInt(5,7);
		AcceptEntityInput(entity, "Kill");
	}
}

public PickedMedium(entity, client)
{
	if(IsValidClient(client))
	{
		p_cash[client] += GetRandomInt(15,30);
		AcceptEntityInput(entity, "Kill");
	}
}

public PickedLarge(entity, client)
{
	if(IsValidClient(client))
	{
		p_cash[client] += GetRandomInt(25,40);
		AcceptEntityInput(entity, "Kill");
	}
}

public Action:DeleteMoney(Handle:timer, any:entity) 
{
	new ent = EntRefToEntIndex(entity);
	if (ent > 0 && IsValidEntity(ent))
	{
		decl String:sClass[32];
		GetEntityClassname(ent, sClass, sizeof(sClass));
		
		if(StrEqual(sClass, "item_currencypack_small") || StrEqual(sClass, "item_currencypack_medium") || StrEqual(sClass, "item_currencypack_large"))
		{
			new Float:zPos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", zPos);
			AcceptEntityInput(ent, "Kill");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

stock Handle:SQL_GET(client, Handle:DBConnection, Handle:ArrayRows, const String:table[], const String:condition[] = "")
{
	new String:query[900];
	new Handle:HandleQuery = INVALID_HANDLE;
	new Handle:ArrayResult = INVALID_HANDLE;
	
	StrCat(query, sizeof(query), "SELECT ");
	for(new i = 0; i < GetArraySize(ArrayRows); i++)
	{
		decl String:row[100];
		GetArrayString(ArrayRows, i, row, sizeof(row));
		StrCat(query, sizeof(query), row);
		if(i != (GetArraySize(ArrayRows)-1))
			StrCat(query, sizeof(query), ", ");
	}
	StrCat(query, sizeof(query), " FROM ");
	StrCat(query, sizeof(query), table);
	
	if(!StrEqual(condition, ""))
	{
		StrCat(query, sizeof(query), " WHERE ");
		StrCat(query, sizeof(query), condition);
	}
	
	//PrintToServer(query);
	
	HandleQuery = SQL_Query(DBConnection, query);
	
	if (HandleQuery == INVALID_HANDLE)
	{
		new String:error[255];
		SQL_GetError(DBConnection, error, sizeof(error));
		PrintToServer("[TF2RPG] Failed to get infos of %N (error: %s)", client, error);
	}
	else
	{
		ArrayResult = CreateArray(300, 0);
		new String:data[300]
		while (SQL_FetchRow(HandleQuery))
		{
			for(new i = 0; i < GetArraySize(ArrayRows); i++)
			{
				SQL_FetchString(HandleQuery, i, data, sizeof(data));
				PushArrayString(ArrayResult, data);
			}
		}
		CloseHandle(HandleQuery)
	}
	return ArrayResult;
}

stock bool:SQL_UPDATE(client, Handle:DBConnection, Handle:ArrayRows, Handle:ArrayValues, const String:table[], const String:condition[] = "")
{
	new String:query[900];

	StrCat(query, sizeof(query), "UPDATE ");
	StrCat(query, sizeof(query), table);
	StrCat(query, sizeof(query), " SET ");
	for(new i = 0; i < GetArraySize(ArrayRows); i++)
	{
		decl String:row[100], String:value[100];
		GetArrayString(ArrayRows, i, row, sizeof(row));
		GetArrayString(ArrayValues, i, value, sizeof(value));
		StrCat(query, sizeof(query), row);
		StrCat(query, sizeof(query), "=");
		StrCat(query, sizeof(query), "'");
		StrCat(query, sizeof(query), value);
		StrCat(query, sizeof(query), "'");
		if(i != (GetArraySize(ArrayRows)-1))
			StrCat(query, sizeof(query), ", ");
	}
	
	if(!StrEqual(condition, ""))
	{
		StrCat(query, sizeof(query), " WHERE ");
		StrCat(query, sizeof(query), condition);
	}
	
	//PrintToServer(query);
	
	if(!SQL_FastQuery(DBConnection, query))
    {
        new String:error[255];
		SQL_GetError(DBConnection, error, sizeof(error));
		PrintToServer("[TF2RPG] Failed to update infos of %N (error: %s)", client, error); //Double error message ?!?
		return false;
    }
	
	return true;
}

stock bool:SQL_INSERT(client, Handle:DBConnection, Handle:ArrayRows, Handle:ArrayValues, const String:table[])
{
	new String:query[900];

	StrCat(query, sizeof(query), "INSERT INTO ");
	StrCat(query, sizeof(query), table);
	StrCat(query, sizeof(query), " (");
	
	decl String:row[100];
	
	for(new i = 0; i < GetArraySize(ArrayRows); i++)
	{
		
		GetArrayString(ArrayRows, i, row, sizeof(row));
		StrCat(query, sizeof(query), row);
		if(i != (GetArraySize(ArrayRows)-1))
			StrCat(query, sizeof(query), ", ");
	}
	StrCat(query, sizeof(query), ") VALUES (");
	
	decl String:value[100];
	for(new i = 0; i < GetArraySize(ArrayValues); i++)
	{
		GetArrayString(ArrayValues, i, value, sizeof(value));
		StrCat(query, sizeof(query), "'");
		StrCat(query, sizeof(query), value);
		StrCat(query, sizeof(query), "'");
		if(i != (GetArraySize(ArrayValues)-1))
			StrCat(query, sizeof(query), ", ");
	}
	
	StrCat(query, sizeof(query), ")");
	
	//PrintToServer(query);
	
	if(!SQL_FastQuery(DBConnection, query))
    {
        new String:error[255];
		SQL_GetError(DBConnection, error, sizeof(error));
		PrintToServer("[TF2RPG] Failed to add infos of %N (error: %s)", client, error);
		return false;
    }
	return true;
}
