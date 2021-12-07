#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <tf2itemsinfo>


#define PLUGIN_NAME         "Unusual"
#define PLUGIN_AUTHOR       "Erreur 500"
#define PLUGIN_DESCRIPTION	"Add Unusual effects on your weapons"	
#define PLUGIN_VERSION      "2.14.90B"
#define PLUGIN_CONTACT      "erreur500@hotmail.fr"
#define EFFECTSFILE			"unusual_list.cfg"
#define WEBSITE 			"http://bit.ly/1aYK7zo"

new bool:DEBUGMOD	= false;


new String:ClientSteamID[MAXPLAYERS+1][24];
new String:EffectsList[PLATFORM_MAX_PATH];

new Quality[MAXPLAYERS+1];
new ClientItems[MAXPLAYERS+1];
new Effect[MAXPLAYERS+1];
new EffectCount[MAXPLAYERS+1];
new TF2ItemSlot:CurrentSlot[MAXPLAYERS+1];
new TFClassType:CurrentClass[MAXPLAYERS+1]	= {TFClass_Unknown, ...};
new ItemSlot[MAXPLAYERS+1][6];

new bool:FirstControl[MAXPLAYERS+1] 	= {false, ...};
new bool:SQLite 						= false;

new bool:IsItemExist[MAXPLAYERS+1][6];
new bool:ItemReady[MAXPLAYERS+1][6];
new bool:ItemInLoading[MAXPLAYERS+1][6];

new Permission[22] 						= {0, ...};
new FlagsList[21] 						= {ADMFLAG_RESERVATION, ADMFLAG_GENERIC, ADMFLAG_KICK, ADMFLAG_BAN, ADMFLAG_UNBAN, ADMFLAG_SLAY, ADMFLAG_CHANGEMAP, ADMFLAG_CONVARS, ADMFLAG_CONFIG, ADMFLAG_CHAT, ADMFLAG_VOTE, ADMFLAG_PASSWORD, ADMFLAG_RCON, ADMFLAG_CHEATS, ADMFLAG_CUSTOM1, ADMFLAG_CUSTOM2, ADMFLAG_CUSTOM3, ADMFLAG_CUSTOM4, ADMFLAG_CUSTOM5, ADMFLAG_CUSTOM6, ADMFLAG_ROOT};

new Handle:c_Control					= INVALID_HANDLE;
new Handle:g_hItem[MAXPLAYERS+1][6];
new Handle:db 							= INVALID_HANDLE;


public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

public OnPluginStart()
{	
	CreateConVar("unusual_version", PLUGIN_VERSION, "Unusual version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_Control	= CreateConVar("unusual_controlmod", 	"0", "0 = no control, 1 = event spawn, 2 = event inventory");	
		
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Pre);
	HookEvent("post_inventory_application", EventPlayerInventory, EventHookMode_Post);
	HookEvent("player_changeclass", EventPlayerchangeclass, EventHookMode_Pre);
	
	RegConsoleCmd("unusual", OpenMenu, "Get unusual effect on your weapons");

	RegAdminCmd("unusual_control", ControlPlayer, ADMFLAG_GENERIC);
	RegAdminCmd("unusual_permissions", reloadPermissions, ADMFLAG_GENERIC);
	
	Connect();
	LoadTranslations("unusual.phrases"); 
	AutoExecConfig(true, "unusual_configs");
	
	BuildPath(Path_SM, EffectsList, sizeof(EffectsList), "configs/%s", EFFECTSFILE);
}

public OnMapStart() 
{
	for(new i=0; i<MaxClients; i++)
		InitializePlayerData(i);
}


//--------------------------------------------------------------------------------------
//							DATA BASE INITIALIZATION
//--------------------------------------------------------------------------------------


Connect()
{
	if (SQL_CheckConfig("unusual"))
	{
		SQL_TConnect(Connected, "unusual");
	}
	/*else
	{
		new String:error[255];
		SQLite = true;
		
		new Handle:kv;
		kv = CreateKeyValues("");
		KvSetString(kv, "driver", "sqlite");
		KvSetString(kv, "database", "unusual");
		db = SQL_ConnectCustom(kv, error, sizeof(error), false);
		CloseHandle(kv);		
		
		if (db == INVALID_HANDLE)
			LogMessage("Loading : Failed to connect: %s", error);
		else
		{
			LogMessage("Loading : Connected to SQLite Database !");
			CreateDbSQLite();
		}
	}*/
}

public Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Failed to connect! Error: %s", error);
		LogMessage("Loading : Failed to connect! Error: %s", error);
		SetFailState("SQL Error.  See error logs for details.");
		return;
	}
	
	LogMessage("Loading : Connected to MySQLite Database !");
	SQL_TQuery(hndl, SQLErrorCheckCallback, "SET NAMES 'utf8'");
	db = hndl;
	
	SQL_CreateEffect_dataTables();
	SQL_CreateEffect_permissionsTables();
	
	LoadPermissions();
}

SQL_CreateEffect_dataTables()
{
	new len = 0;
	decl String:query[300];
	
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Effect_data` (");
	len += Format(query[len], sizeof(query)-len, "`Players` VARCHAR(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`SteamID` VARCHAR(25) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`Number` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`Item_list` TEXT NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY  (`SteamID`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM DEFAULT CHARSET=utf8;");
	if (SQL_FastQuery(db, query)) 
		LogMessage("Loading : Tables 'Effect_data' Created 				[3/5]");
}

SQL_CreateEffect_permissionsTables()
{
	new len = 0;
	new String:FlagLetterList[22][] = {"0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "z"};
	new String:buffer[70];
	decl String:query[200];
	
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Effect_permissions` (");
	len += Format(query[len], sizeof(query)-len, "`Flags` VARCHAR(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`Limits` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY  (`Flags`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM DEFAULT CHARSET=utf8;");
	
	if (SQL_FastQuery(db, query)) 
		LogMessage("Loading : Tables 'Effect_permissions' Created 				[3/5]");
	
	for(new i = 0; i < 22; i++)
	{
		Format(buffer, sizeof(buffer), "SELECT `Limits` FROM Effect_permissions WHERE Flags = '%s'", FlagLetterList[i]);
		SQL_TQuery(db, T_InitializePermission, buffer, i);
	}
}


public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		LogError("Loading : SQL Error: %s", error);
		LogMessage("Loading : SQL Error: %s", error);
	}
}



//--------------------------------------------------------------------------------------
//							Control
//--------------------------------------------------------------------------------------



stock bool:IsValidClient(iClient)
{
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	return IsClientInGame(iClient);
}

public Action:OpenMenu(iClient, Args)
{	
	FirstMenu(iClient);
}

public Action:ControlPlayer(iClient, Args)
{	
	for(new i=1; i<MaxClients; i++)
		if(IsClientInGame(i))
			Updating(i);
	
	if(IsValidClient(iClient))
		PrintToChat(iClient,"All Players have been controlled !");
	else
		LogMessage("All Players have been controlled !");
}

public Action:reloadPermissions(iClient, Args)
{
	LoadPermissions();

	if(IsValidClient(iClient))
		PrintToChat(iClient,"Unusual effects permissions reloaded !");
	else
		LogMessage("Unusual effects permissions reloaded !");
}

LoadPermissions()
{
	new String:buffer[100]
	new String:FlagLetterList[22][] = {"0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "z"};
	
	for( new i = 0; i<22; i++)
	{
		Format(buffer, sizeof(buffer), "SELECT `Limits` FROM Effect_permissions WHERE Flags = '%s'", FlagLetterList[i]);
		SQL_TQuery(db, T_LoadPermission, buffer, i);
	}
}

bool:isAuthorized(iClient, bool:Strict)
{
	new Limit = GetLimit(GetUserFlagBits(iClient));
	
	if(Limit == -1)
		return true;
			
	if(Strict && EffectCount[iClient] < Limit)
		return true;
	else if(!Strict && EffectCount[iClient] <= Limit)
		return true;
	else
		return false;
}

GetLimit(flags)
{
	new Limit 	= 0;
	new i 		= 0;
	
	if(flags == 0)
		return Limit;
		
	do
	{
		if( (flags & FlagsList[i]) && ((Limit < Permission[i+1]) || (Permission[i+1] == -1)) )
			Limit = Permission[i+1];
		i++;
	}while(Limit != -1 && i<21)
	return Limit;
}

//--------------------------------------------------------------------------------------
//							Update Effects
//--------------------------------------------------------------------------------------


public OnClientAuthorized(iClient, const String:auth[])
{
	new String:buffer[255];
	
	strcopy(ClientSteamID[iClient], 60, auth);
	
	InitializePlayerData(iClient);
	
	Format(buffer, sizeof(buffer), "SELECT `Number` FROM effect_data WHERE SteamID = '%s'", ClientSteamID[iClient]);
	SQL_TQuery(db, T_EffectCount, buffer, iClient);
}

InitializePlayerData(iClient)
{
	for(new j = 0; j<6; j++) 
	{
		g_hItem[iClient][j]		  = INVALID_HANDLE;
		ItemReady[iClient][j]	  = false;
		ItemInLoading[iClient][j] = false;
	}
	CurrentSlot[iClient] = TF2ItemSlot_Primary;
}

public Action:EventPlayerSpawn(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(GetConVarInt(c_Control) == 1 || !FirstControl[iClient])
	{
		if (IsValidClient(iClient))
			Updating(iClient);
	}
	return Plugin_Continue;
}

public Action:EventPlayerInventory(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));	
	if(GetConVarInt(c_Control) == 2)
	{
		if (!IsValidClient(iClient)) return Plugin_Continue;
		if (!IsPlayerAlive(iClient)) return Plugin_Continue;
		Updating(iClient);
	}
	return Plugin_Continue;
}

public Action:EventPlayerchangeclass(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (!IsValidClient(iClient)) return Plugin_Continue;
	
	InitializePlayerData(iClient);
	
	if(DEBUGMOD) LogMessage("0 - Player item data initialized");
	return Plugin_Continue;
}

Updating(iClient)
{
	new String:buffer[255];
	
	Format(buffer, sizeof(buffer), "SELECT `Number` FROM effect_data WHERE SteamID = '%s'", ClientSteamID[iClient]);
	SQL_TQuery(db, T_EffectCount, buffer, iClient);
		
	if(isAuthorized(iClient, false))	return;
	
	CPrintToChat(iClient, "%t","Sent6");	// Delete player effects 
	
	Format(buffer, sizeof(buffer), "DELETE FROM effect_data WHERE SteamID = '%s'", ClientSteamID[iClient]);
	SQL_TQuery(db,SQLErrorCheckCallback, buffer);
	
	if(GetClientTeam(iClient) == 2 || GetClientTeam(iClient) == 3)
			UpdateWeapon(iClient);		// GIVE PLAYER NEW EFFECT IN GAME
}


public Action:TF2Items_OnGiveNamedItem(iClient, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if(!IsValidClient(iClient)) return Plugin_Continue;
	if(StrEqual(classname, "tf_wearable")) return Plugin_Continue;		// Can't use it with hat and misc
	if(iItemDefinitionIndex == 28) return Plugin_Continue;				// Engineer item without unusual effect
	
	CurrentSlot[iClient] = TF2ItemSlot_Primary;
	
	while(CurrentSlot[iClient] != TF2II_GetItemSlot(iItemDefinitionIndex, TF2_GetPlayerClass(iClient)) && CurrentSlot[iClient] < GetPlayerMaxSlot(iClient))
	{
		CurrentSlot[iClient]++;
	}
		
	if(CurrentSlot[iClient] <= GetPlayerMaxSlot(iClient) && ItemReady[iClient][CurrentSlot[iClient]])	// Is item loaded ?
	{				
		if(DEBUGMOD) LogMessage("6 - GIVE ITEM %i slot number %i",iItemDefinitionIndex, CurrentSlot[iClient]);
		
		ItemInLoading[iClient][CurrentSlot[iClient]] = false;
		ItemReady[iClient][CurrentSlot[iClient]] 	 = false;
		
		if(g_hItem[iClient][CurrentSlot[iClient]] != INVALID_HANDLE)
		{
			hItem = g_hItem[iClient][CurrentSlot[iClient]];					// Give player unusual item
			g_hItem[iClient][CurrentSlot[iClient]] 	= INVALID_HANDLE;
		
			return Plugin_Changed;
		}
		else
		{
			g_hItem[iClient][CurrentSlot[iClient]] 	= INVALID_HANDLE;
				
			return Plugin_Continue;
		}		
	}	
	else
	{
		decl String:buffer[255];
		
		CurrentSlot[iClient] = TF2ItemSlot_Primary;

		while(CurrentSlot[iClient] != TF2II_GetItemSlot(iItemDefinitionIndex, TF2_GetPlayerClass(iClient)) && CurrentSlot[iClient] < GetPlayerMaxSlot(iClient))
		{
			ItemReady[iClient][CurrentSlot[iClient]] 	= false;
			CurrentSlot[iClient]++;
		}
		
		if(CurrentSlot[iClient] <= GetPlayerMaxSlot(iClient) && CurrentSlot[iClient] == TF2II_GetItemSlot(iItemDefinitionIndex, TF2_GetPlayerClass(iClient)))
		{
			ItemSlot[iClient][CurrentSlot[iClient]] 	 = iItemDefinitionIndex;	// What is the weapon ID of this player item slot
			ItemInLoading[iClient][CurrentSlot[iClient]] = true;
			
			if(DEBUGMOD) LogMessage("1 - LOAD ITEM %i for slot %i", ItemSlot[iClient][CurrentSlot[iClient]], CurrentSlot[iClient]);	
			Format(buffer, sizeof(buffer), "SELECT `Number` FROM effect_data WHERE SteamID = '%s'", ClientSteamID[iClient]);
			SQL_TQuery(db, T_ClientItemsExistance, buffer, iClient);
		}
		else
		{
			CurrentSlot[iClient] = TF2ItemSlot_Primary;
			while(CurrentSlot[iClient] != TF2II_GetItemSlot(iItemDefinitionIndex, TF2_GetPlayerClass(iClient)) && CurrentSlot[iClient] < GetPlayerMaxSlot(iClient))
			{	
				if(!ItemInLoading[iClient][CurrentSlot[iClient]])
				{
					ItemSlot[iClient][CurrentSlot[iClient]] 		= -1;
					ItemInLoading[iClient][CurrentSlot[iClient]] 	= true;
					
					if(DEBUGMOD) LogMessage("1 - LOAD ITEM %i for slot %i", ItemSlot[iClient][CurrentSlot[iClient]], CurrentSlot[iClient]);	
					Format(buffer, sizeof(buffer), "SELECT `Number` FROM effect_data WHERE SteamID = '%s'", ClientSteamID[iClient]);
					SQL_TQuery(db, T_ClientItemsExistance, buffer, iClient);
				}
				CurrentSlot[iClient]++;
			}
		}
		
		CurrentSlot[iClient] = TF2ItemSlot_Primary;
			
		return Plugin_Continue;
	}	
}

UpdateWeapon(iClient)
{		
	for(new i=GetPlayerMaxSlot; i>=0; i--)
		TF2_RemoveWeaponSlot(iClient, i);
		
	TF2_RegeneratePlayer(iClient);
}

TF2ItemSlot:GetPlayerMaxSlot(iClient)
{
	new TFClassType:Class = TF2_GetPlayerClass(iClient);
	new TF2ItemSlot:SlotMax;
	
	if(Class == TFClassType:8)		// SPY
		SlotMax = TF2ItemSlot_PDA;
	else if(Class == TFClassType:9)	// ENGINEER
		SlotMax = TF2ItemSlot_PDA2;
	else	// OTHER
		SlotMax = TF2ItemSlot_Melee;
	
	return SlotMax;
}
	
	
	




//--------------------------------------------------------------------------------------
//							Menu selection
//--------------------------------------------------------------------------------------
	
FirstMenu(iClient)
{	
	if(IsValidClient(iClient))
	{
		new Handle:Menu1 = CreateMenu(Menu1_1);
		SetMenuTitle(Menu1, "What do you want ?");
		AddMenuItem(Menu1, "0", "Add/modify weapons");
		AddMenuItem(Menu1, "1", "Delete effects");
		AddMenuItem(Menu1, "2", "Show effects");
				
		SetMenuExitButton(Menu1, true);
		DisplayMenu(Menu1, iClient, MENU_TIME_FOREVER);
	}
}

public Menu1_1(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		if(args == 0)
			if(GetClientTeam(iClient) == 2 || GetClientTeam(iClient) == 3)
			{
				CurrentClass[iClient] = TF2_GetPlayerClass(iClient);
				QualityMenu(iClient);
			}
			else
				CPrintToChat(iClient, "%t","Sent2");
		else if(args == 1)
			DeleteWeapPanel(iClient);
		else if(args == 2)
		{
			FirstMenu(iClient);
			ShowMOTDPanel(iClient, "Unusual effects", WEBSITE, MOTDPANEL_TYPE_URL );
		}
	}
}

//--------------------------------------------------------------------------------------
//							Remove Effect
//--------------------------------------------------------------------------------------

DeleteWeapPanel(iClient)
{
	new String:buffer[256];
	Format(buffer, sizeof(buffer), "SELECT `Item_list` FROM effect_data WHERE SteamID = '%s'", ClientSteamID[iClient]);
	SQL_TQuery(db, T_InitilizeDeleteMenu, buffer, iClient);
}


public DeleteItemsMenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		new String:WeapID[7];
		GetMenuItem(menu, args, WeapID, sizeof(WeapID));
		ClientItems[iClient] = StringToInt(WeapID);
		
		new String:buffer[256];
		Format(buffer, sizeof(buffer), "SELECT `Item_list`, `Number` FROM effect_data WHERE SteamID = '%s'",ClientSteamID[iClient]);
		SQL_TQuery(db, T_DeleteItem, buffer, iClient);
	}
}


//--------------------------------------------------------------------------------------
//							Quality + Effect
//--------------------------------------------------------------------------------------


QualityMenu(iClient)
{
	new String:buffer[255];
	
	Format(buffer, sizeof(buffer), "SELECT `Number` FROM effect_data WHERE SteamID = '%s'", ClientSteamID[iClient]);
	SQL_TQuery(db, T_EffectCount, buffer, iClient);

	if(!isAuthorized(iClient, true))	// Is player allowed ?
	{
		CPrintToChat(iClient, "%t", "Sent7");
		return;
	}

	new EntitiesID		= GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
	if(EntitiesID < 0)
		return;
	ClientItems[iClient]	= GetEntProp(EntitiesID, Prop_Send, "m_iItemDefinitionIndex");
	
	decl String:Title[64];
	decl String:WeapName[64];
	new Handle:Qltymenu = CreateMenu(QltymenuAnswer);
	
	TF2II_GetItemName(ClientItems[iClient], WeapName, sizeof(WeapName)); 
	Format(Title, sizeof(Title), "Select effect: %s",WeapName);
	SetMenuTitle(Qltymenu, Title);
	
	AddMenuItem(Qltymenu, "0", "normal");
	AddMenuItem(Qltymenu, "1", "rarity1");
	AddMenuItem(Qltymenu, "2", "rarity2");
	AddMenuItem(Qltymenu, "3", "vintage");
	AddMenuItem(Qltymenu, "4", "rarity3");
	AddMenuItem(Qltymenu, "5", "rarity4");
	AddMenuItem(Qltymenu, "6", "unique");
	AddMenuItem(Qltymenu, "7", "community");
	AddMenuItem(Qltymenu, "8", "developer");
	AddMenuItem(Qltymenu, "9", "selfmade");
	AddMenuItem(Qltymenu, "10", "customized");
	AddMenuItem(Qltymenu, "11", "strange");
	AddMenuItem(Qltymenu, "12", "completed");
	AddMenuItem(Qltymenu, "13", "haunted");
	AddMenuItem(Qltymenu, "14", "Collector's"); 
	
	SetMenuExitButton(Qltymenu, true);
	DisplayMenu(Qltymenu, iClient, MENU_TIME_FOREVER);
}

public QltymenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		if(CurrentClass[iClient] != TF2_GetPlayerClass(iClient))
		{
			CPrintToChat(iClient, "%t", "Sent1");
			CloseHandle(menu);
		}
		else
		{
			Quality[iClient] = args;
			PanelEffect(iClient);
		}
	}
}

PanelEffect(iClient)
{
	new String:EffectID[8];
	new String:EffectName[128];
	new String:Line[255];
	new Len = 0, NameLen = 0, IDLen = 0;
	new i,j,data,count = 0;

	new Handle:UnusualMenu = CreateMenu(UnusualMenuAnswer);
	SetMenuTitle(UnusualMenu, "Select Unusual effect :");
	AddMenuItem(UnusualMenu, "0", "Show effects");
	
	new Handle:file = OpenFile(EffectsList, "rt");
	if (file == INVALID_HANDLE)
	{
		LogError("[UNUSUAL] Could not open file %s", EFFECTSFILE);
		CloseHandle(file);
		return;
	}
	
	while (!IsEndOfFile(file))
	{
		count++;
		ReadFileLine(file, Line, sizeof(Line));
		Len = strlen(Line);
		data = 0;
		TrimString(Line);
		if(Line[0] == '"')
		{
			for (i=0; i<Len; i++)
			{
				if (Line[i] == '"')
				{
					i++;
					data++;
					j = i;
					while(Line[j] != '"' && j < Len)
					{
						if(data == 1)
						{
							EffectName[j-i] = Line[j];
							NameLen = j-i;
						}
						else
						{
							EffectID[j-i] = Line[j];
							IDLen = j-i;
						}
						j++;
					}
					i = j;
				}	
			} 
		}
		if(data != 0 && j <= Len)
			AddMenuItem(UnusualMenu, EffectID, EffectName);
		else if(Line[0] != '*' && Line[0] != '/')
			LogError("[UNUSUAL] %s can't read line : %i ",EFFECTSFILE, count);
			
		for(i = 0; i <= NameLen; i++)
			EffectName[i] = '\0';
		for(i = 0; i <= IDLen; i++)
			EffectID[i] = '\0';
	}
	CloseHandle(file);

	SetMenuExitButton(UnusualMenu, true);
	DisplayMenu(UnusualMenu, iClient, MENU_TIME_FOREVER);
}

public UnusualMenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		if(CurrentClass[iClient] != TF2_GetPlayerClass(iClient))
		{
			CPrintToChat(iClient, "%t", "Sent1");
			CloseHandle(menu);
		}
		else
		{
			if(args == 0)
			{
				PanelEffect(iClient);
				ShowMOTDPanel(iClient, "Unusual effects", WEBSITE, MOTDPANEL_TYPE_URL );
			}
			
			
			new String:srtEffect[3];
			new String:buffer[255];
			
			GetMenuItem(menu, args, srtEffect, sizeof(srtEffect));
			Effect[iClient] = StringToInt(srtEffect);
			
			InitializePlayerData(iClient);
					
			Format(buffer, sizeof(buffer), "SELECT `Number` FROM effect_data WHERE SteamID = '%s'", ClientSteamID[iClient]);
			SQL_TQuery(db, T_UpdateDB, buffer, iClient);
		
			CPrintToChat(iClient, "%t", "Sent5");
			FirstMenu(iClient); 
		}
	}	
}



//--------------------------------------------------------------------------------------
//							DATABASE ACCESS
//--------------------------------------------------------------------------------------



// ---  WEAPON UPDATE ------------------------------------------------------------------


public T_UpdateDB(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	new String:str_Value[16];
	decl String:query[1000];
	
	Format(str_Value, sizeof(str_Value), "%i_%i",Quality[iClient], Effect[iClient]);	// ADD new item column
	Format(query, sizeof(query), "ALTER TABLE effect_data ADD COLUMN Item_%i VARCHAR(25) NOT NULL;", ClientItems[iClient]);
	if (SQL_FastQuery(db, query)) 
		LogMessage("Loading : Column Item_%i Created", ClientItems[iClient]);
		
	if (!SQL_GetRowCount(hndl))		// If player doesn't exist in DB
	{
		new String:PlayerName[64];
		new String:buffer[1024];
		
		GetClientName(iClient, PlayerName, sizeof(PlayerName) );	// REMOVE special character
		ReplaceString(PlayerName, sizeof(PlayerName), "'", "");
		ReplaceString(PlayerName, sizeof(PlayerName), "<?PHP", "");
		ReplaceString(PlayerName, sizeof(PlayerName), "<?php", "");
		ReplaceString(PlayerName, sizeof(PlayerName), "<?", "");
		ReplaceString(PlayerName, sizeof(PlayerName), "?>", "");
		ReplaceString(PlayerName, sizeof(PlayerName), "<", "[");
		ReplaceString(PlayerName, sizeof(PlayerName), ">", "]");
		ReplaceString(PlayerName, sizeof(PlayerName), ",", ".");
		
		if(!SQLite)
		{		
			Format(buffer, sizeof(buffer), "INSERT INTO effect_data (`Players`,`SteamID`,`Number`,`Item_list`,`Item_%i`) VALUES ('%s','%s','1','_%i_','%s')",ClientItems[iClient], PlayerName, ClientSteamID[iClient], ClientItems[iClient], str_Value);
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
			LogMessage("%N unusual effect item ADD in DB", iClient);
		}
	}
	else	// Player already in DB
	{
		new String:buffer[128];
		
		Format(buffer, sizeof(buffer), "SELECT `Item_list` FROM effect_data WHERE SteamID = '%s'", ClientSteamID[iClient]);
		SQL_TQuery(db, T_UpdateClient, buffer, iClient);
	}
}

public T_UpdateClient(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	new String:PlayerName[64];
	new String:buffer[4056];
	new String:Item_list[3000];
	new String:str_Value[16];
	new String:StrItem[10];
		
	GetClientName(iClient, PlayerName, sizeof(PlayerName)); 	// REMOVE special character
	ReplaceString(PlayerName, sizeof(PlayerName), "'", "");
	ReplaceString(PlayerName, sizeof(PlayerName), "<?PHP", "");
	ReplaceString(PlayerName, sizeof(PlayerName), "<?php", "");
	ReplaceString(PlayerName, sizeof(PlayerName), "<?", "");
	ReplaceString(PlayerName, sizeof(PlayerName), "?>", "");
	ReplaceString(PlayerName, sizeof(PlayerName), "<", "[");
	ReplaceString(PlayerName, sizeof(PlayerName), ">", "]");
	ReplaceString(PlayerName, sizeof(PlayerName), ",", ".");

	Format(str_Value, sizeof(str_Value), "%i_%i",Quality[iClient], Effect[iClient]);

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Item_list, sizeof(Item_list));
		IntToString(ClientItems[iClient], StrItem, sizeof(StrItem));
		Format(StrItem, sizeof(StrItem), "%s_", StrItem);		
		
		if(StrContains(Item_list, StrItem) == -1)
		{
			if(StrEqual(Item_list, ""))
				Format(Item_list, sizeof(Item_list), "_%i_", ClientItems[iClient]);		// ADD NEW ITEM EFFECT
			else
				Format(Item_list, sizeof(Item_list), "%s%i_", Item_list, ClientItems[iClient]);		// ADD NEW ITEM EFFECT
			
			EffectCount[iClient]++;
		}
		
		Format(buffer, sizeof(buffer), "UPDATE effect_data SET Players = '%s', Number = %i, Item_list = '%s', Item_%i = '%s' WHERE SteamID = '%s'", PlayerName, EffectCount[iClient], Item_list, ClientItems[iClient], str_Value, ClientSteamID[iClient]);
		SQL_TQuery(db,SQLErrorCheckCallback, buffer);
		
		LogMessage("%s ITEM %i UPDATE", PlayerName, ClientItems[iClient]);
		
		if(GetClientTeam(iClient) == 2 || GetClientTeam(iClient) == 3)
			UpdateWeapon(iClient);		// GIVE PLAYER NEW EFFECT IN GAME
	}
}


// ---  GIVE WEAPON ATTRIBUT ------------------------------------------------------------


public T_ClientItemsExistance(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	if (SQL_GetRowCount(hndl))	// Is player on the database ?
	{
		new String:buffer[100];
		
		Format(buffer, sizeof(buffer), "SHOW columns FROM effect_data LIKE 'Item_%i'", ItemSlot[iClient][CurrentSlot[iClient]]);
		SQL_TQuery(db, T_ClientItems, buffer, iClient);
		
		if(DEBUGMOD) LogMessage("2 - Client EXIST for ITEM %i Slot %i", ItemSlot[iClient][CurrentSlot[iClient]], CurrentSlot[iClient]);
	}
	
	/** Upgrade current slot, for te next function call **/
	CurrentSlot[iClient]++;
	if(CurrentSlot[iClient] > GetPlayerMaxSlot(iClient))
		CurrentSlot[iClient] = TF2ItemSlot_Primary;
}

public T_ClientItems(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	new String:buffer[128];
	new String:Column[16];	
	
	IsItemExist[iClient][CurrentSlot[iClient]] = false;
	
	while(SQL_FetchRow(hndl)) 	// Is this weapon on the DB ?
	{
		g_hItem[iClient][CurrentSlot[iClient]] = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);
		IsItemExist[iClient][CurrentSlot[iClient]] = true;
		
		SQL_FetchString(hndl, 0, Column, sizeof(Column));
		Format(buffer, sizeof(buffer), "SELECT `%s` FROM effect_data WHERE SteamID = '%s'", Column, ClientSteamID[iClient]);
		SQL_TQuery(db, T_ItemDatas, buffer, iClient);
		if(DEBUGMOD) LogMessage("3 - ITEM %i, Column Exist %s, Slot %i", ItemSlot[iClient][CurrentSlot[iClient]], Column, CurrentSlot[iClient]);
	}
	
	if(!IsItemExist[iClient][CurrentSlot[iClient]])
	{
		Format(buffer, sizeof(buffer), "SELECT `SteamID` FROM effect_data WHERE SteamID = '%s'", ClientSteamID[iClient]);
		SQL_TQuery(db, T_ItemDatas, buffer, iClient);
		if(DEBUGMOD) LogMessage("3 - ITEM %i, No Column , Slot %i", ItemSlot[iClient][CurrentSlot[iClient]], CurrentSlot[iClient]);
	}
	
	/** Upgrade current slot, for te next function call **/
	CurrentSlot[iClient]++;
	if(CurrentSlot[iClient] > GetPlayerMaxSlot(iClient))
		CurrentSlot[iClient] = TF2ItemSlot_Primary;
}

public T_ItemDatas(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	new String:Column[16];
	new TF2ItemSlot:ItemLoaded = TF2ItemSlot_Primary;
		
	while (SQL_FetchRow(hndl)) 
		SQL_FetchString(hndl, 0, Column, sizeof(Column));
		
	ItemReady[iClient][CurrentSlot[iClient]] 	= true;	
	
	if(!StrEqual(Column, "") && !StrEqual(Column, ClientSteamID[iClient]) && IsItemExist[iClient][CurrentSlot[iClient]] && g_hItem[iClient][CurrentSlot[iClient]] != INVALID_HANDLE)
	{
		new String:buffers[2][5];
		
		/** ADD UNUSUAL EFFECT DATA **/
		ExplodeString(Column, "_", buffers, 2, 5, false);			
		if(DEBUGMOD) PrintToChat(iClient, "Will give %s: %s + %s",Column, buffers[0], buffers[1]);
		
		TF2Items_SetQuality(g_hItem[iClient][CurrentSlot[iClient]], StringToInt(buffers[0]));
		TF2Items_SetNumAttributes(g_hItem[iClient][CurrentSlot[iClient]], 1);
		TF2Items_SetAttribute(g_hItem[iClient][CurrentSlot[iClient]], 0, 134, StringToInt(buffers[1])*1.0);
		
		if(DEBUGMOD) LogMessage("4 - ITEM %i unusual, Slot %i", ItemSlot[iClient][CurrentSlot[iClient]], CurrentSlot[iClient]);
	}
	else
	{
		if(DEBUGMOD) LogMessage("4 - ITEM %i ISN'T unusual, Slot: %i !", ItemSlot[iClient][CurrentSlot[iClient]], CurrentSlot[iClient]);
		g_hItem[iClient][CurrentSlot[iClient]] = INVALID_HANDLE;
	}
	
	
	for( new TF2ItemSlot:i = GetPlayerMaxSlot(iClient); i >= TF2ItemSlot_Primary; i--)	// IS ALL CLIENT ITEMS LOADED ?
		if(ItemReady[iClient][i])
			ItemLoaded++;
		
	if(ItemLoaded == GetPlayerMaxSlot(iClient) + TF2ItemSlot_Secondary) 	// ALL CLIENT ITEMS LOADED ! 
	{
		for( new TF2ItemSlot:i = GetPlayerMaxSlot(iClient); i >= TF2ItemSlot_Primary; i--)	// REMOVE ALL WEAP
		{
			if(DEBUGMOD) LogMessage("5 - ITEM LOADED : %i  SLOT : %i", ItemSlot[iClient][i], i);
			ItemSlot[iClient][i] = -1;
			TF2_RemoveWeaponSlot(iClient, i);
		}
		
		CurrentSlot[iClient] 		= TF2ItemSlot_Primary;		
		TF2_RegeneratePlayer(iClient);			// GIVE CLIENT UNUSUAL ITEMS
		return;
	}
	
	/** Upgrade current slot, for the next function call **/
	CurrentSlot[iClient]++;
	if(CurrentSlot[iClient] > GetPlayerMaxSlot(iClient))
		CurrentSlot[iClient] = TF2ItemSlot_Primary;
}


// ---  GET EFFECT COUNT ------------------------------------------------------------------


public T_EffectCount(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	if (!SQL_GetRowCount(hndl))
		EffectCount[iClient] = 0;
	else
		while(SQL_FetchRow(hndl)) EffectCount[iClient] = SQL_FetchInt(hndl,0);
}



// ---  DELETE UNUSUAL EFFECTS MENU ------------------------------------------------------------------


public T_InitilizeDeleteMenu(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	if (!SQL_GetRowCount(hndl))
		CPrintToChat(iClient, "%t", "Sent3");
	else
	{
		while(SQL_FetchRow(hndl))
		{
			new String:Item_list[3000];
			new String:StrItem[8];
			new String:ItemsName[64];
			new ItemNumber 	= 0;
			new ItemID		= 0;
			new Handle:ItemsMenu = CreateMenu(DeleteItemsMenuAnswer);
			
			SetMenuTitle(ItemsMenu, "What items ?");
			SQL_FetchString(hndl, 0, Item_list, sizeof(Item_list));

			while(ItemNumber < EffectCount[iClient] && ItemID < 10000)
			{
				Format(StrItem, sizeof(StrItem), "_%i_", ItemID);
				if(StrContains(Item_list, StrItem, true) != -1)
				{
					ItemNumber++;
					
					IntToString(ItemID, StrItem, sizeof(StrItem));
					TF2II_GetItemName(ItemID, ItemsName, sizeof(ItemsName));
					AddMenuItem(ItemsMenu, StrItem, ItemsName);
				}
				ItemID++;
			}
			
			if(ItemNumber > 0)
			{
				SetMenuExitButton(ItemsMenu, true);
				DisplayMenu(ItemsMenu, iClient, MENU_TIME_FOREVER);
			}
			else CloseHandle(ItemsMenu);
		}
	}
}

public T_DeleteItem(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	if (!SQL_GetRowCount(hndl))
		CPrintToChat(iClient, "%t", "Sent3");
	else
	{
		while(SQL_FetchRow(hndl))
		{
			new String:PlayerName[64];
			new String:Item_list[3000];
			
			GetClientName(iClient, PlayerName, sizeof(PlayerName));
			ReplaceString(PlayerName, sizeof(PlayerName), "'", "");
			ReplaceString(PlayerName, sizeof(PlayerName), "<?PHP", "");
			ReplaceString(PlayerName, sizeof(PlayerName), "<?php", "");
			ReplaceString(PlayerName, sizeof(PlayerName), "<?", "");
			ReplaceString(PlayerName, sizeof(PlayerName), "?>", "");
			ReplaceString(PlayerName, sizeof(PlayerName), "<", "[");
			ReplaceString(PlayerName, sizeof(PlayerName), ">", "]");
			ReplaceString(PlayerName, sizeof(PlayerName), ",", ".");
			
			if(SQL_FetchString(hndl, 0, Item_list, sizeof(Item_list)))
			{
				new String:ExplodeItem_list[2][3000];
				new String:strItem[10];
				
				Format(strItem, sizeof(strItem), "_%i_", ClientItems[iClient]);
				ExplodeString(Item_list, strItem, ExplodeItem_list, 2, 3000, false);	
				Format(Item_list, sizeof(Item_list), "%s_%s", ExplodeItem_list[0], ExplodeItem_list[1]);
			}
			
			if( SQL_FetchInt(hndl, 1) <= 1)
			{
				new String:buffer[255];
				Format(buffer, sizeof(buffer), "DELETE FROM effect_data WHERE SteamID = '%s'", ClientSteamID[iClient]);	// REMOVE PLAYER FROM DB
				SQL_TQuery(db,SQLErrorCheckCallback, buffer);
			}
			else
			{
				new String:buffer[4096];
				Format(buffer, sizeof(buffer), "UPDATE effect_data SET Players = '%s', Number = Number-1, Item_list = '%s', Item_%i = '' WHERE SteamID = '%s'", PlayerName, Item_list, ClientItems[iClient], ClientSteamID[iClient]);
				SQL_TQuery(db,SQLErrorCheckCallback, buffer);
			}
			
			
				
			CPrintToChat(iClient, "%t", "Sent4");
			
			if(GetClientTeam(iClient) == 2 || GetClientTeam(iClient) == 3)
				UpdateWeapon(iClient);
			
			DeleteWeapPanel(iClient);
		}
	}
}



// ---  PERMISSION ------------------------------------------------------------------



public T_InitializePermission(Handle:owner, Handle:hndl, const String:error[], any:Data)
{
	if (!SQL_GetRowCount(hndl))
	{
		new String:buffer[512];
		new String:FlagLetterList[22][] = {"0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "z"};
		
		Format(buffer, sizeof(buffer), "INSERT INTO Effect_permissions (`Flags`,`Limits`) VALUES ('%s', '-1')", FlagLetterList[Data]);
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	}
}

public T_LoadPermission(Handle:owner, Handle:hndl, const String:error[], any:Data)
{
	if (SQL_GetRowCount(hndl))
	{		
		while (SQL_FetchRow(hndl))
		{
			Permission[Data] = SQL_FetchInt(hndl, 0);
		}
	}
	else
		Permission[Data] = -1;	// DEFAULT VALUE, else player will lost their effects
}




