#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <tf2idb>
#include <unusual>
#undef REQUIRE_PLUGIN
#include <freak_fortress_2>



#define PLUGIN_NAME         "Unusual"
#define PLUGIN_AUTHOR       "Erreur 500"
#define PLUGIN_DESCRIPTION	"Add Unusual effects on your weapons"
#define PLUGIN_VERSION      "2.19"
#define PLUGIN_CONTACT      "erreur500@hotmail.fr"
#define EFFECTSFILE			"unusual_list.cfg"
#define PERMISSIONFILE		"unusual_permissions.cfg"
#define WEBSITE 			"http://bit.ly/l77777"

#define IDIL_IDLE 		0
#define IDIL_START 		1
#define IDIL_WAIT 		2
#define IDIL_REQUEST 	3

enum ItemData
{
    e_ItemID,
	e_EffectID,
	e_QualityID,
}
new ClientItemData[MAXPLAYERS+1][10][ItemData];

new String:SteamUsed[MAXPLAYERS+1][64];
new String:ClientSteamID[MAXPLAYERS+1][64];
new String:EffectsList[PLATFORM_MAX_PATH];
new String:PermissionsFile[PLATFORM_MAX_PATH];

new Effect[MAXPLAYERS+1];
new Quality[MAXPLAYERS+1];
new ClientItems[MAXPLAYERS+1];
new NbOfEffect[MAXPLAYERS+1];
new ItemDataInLoad[MAXPLAYERS+1] 	= {0, ...};

new bool:SQLite 						= false;
new bool:IsFF2Enabled 					= false;
new bool:StopItemLoading[MAXPLAYERS+1] 	= {false, ...};
new bool:AT_Choice_add[MAXPLAYERS+1]	= {false, ...};

new Permission[22] 					= {0, ...};
new FlagsList[21] 					= {ADMFLAG_RESERVATION, ADMFLAG_GENERIC, ADMFLAG_KICK, ADMFLAG_BAN, ADMFLAG_UNBAN, ADMFLAG_SLAY, ADMFLAG_CHANGEMAP, ADMFLAG_CONVARS, ADMFLAG_CONFIG, ADMFLAG_CHAT, ADMFLAG_VOTE, ADMFLAG_PASSWORD, ADMFLAG_RCON, ADMFLAG_CHEATS, ADMFLAG_CUSTOM1, ADMFLAG_CUSTOM2, ADMFLAG_CUSTOM3, ADMFLAG_CUSTOM4, ADMFLAG_CUSTOM5, ADMFLAG_CUSTOM6, ADMFLAG_ROOT};

new Handle:db 						= INVALID_HANDLE;
new Handle:c_tag					= INVALID_HANDLE;
new Handle:c_TeamRest				= INVALID_HANDLE;
new Handle:c_PanelFlag				= INVALID_HANDLE;
new Handle:c_FF2					= INVALID_HANDLE;
new Handle:g_hItem 					= INVALID_HANDLE;



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
	CreateConVar("unusual_version", PLUGIN_VERSION, "Unusual version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	c_tag			= CreateConVar("unusual_tag", 	"1", "Enable 'unusual' tag", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_TeamRest		= CreateConVar("unusual_team_restriction", 	"0", "0 = no restriction, 1 = red, 2 = blue can't have unusual effects", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	c_PanelFlag		= CreateConVar("unusual_panel_flag", 	"0", "0 = ADMFLAG_ROOT, 1 = ADMFLAG_GENERIC", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	c_FF2			= CreateConVar("unusual_fix_ff2boss", 	"1", "0 = boss can have unusual effects, 1 = boss can't", FCVAR_PLUGIN, true, 0.0, true, 1.0);	

	RegConsoleCmd("unusual", OpenMenu, "Get unusual effect on your weapons");
	RegAdminCmd("unusual_control", ControlPlayer, ADMFLAG_GENERIC);
	RegAdminCmd("unusual_permissions", reloadPermissions, ADMFLAG_GENERIC);
	
	LoadTranslations("unusual.phrases"); 

	Connect();
	BuildPath(Path_SM, EffectsList, sizeof(EffectsList), "configs/%s", EFFECTSFILE);
	BuildPath(Path_SM, PermissionsFile,sizeof(PermissionsFile),"configs/%s", PERMISSIONFILE);
	
	decl String:PlayerInfo[64];
	for(new i=1; i<MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			GetClientAuthId(i, AuthId_Steam2, PlayerInfo, sizeof(PlayerInfo));
			strcopy(ClientSteamID[i], 64, PlayerInfo);
		}
		
		for(new j=0; j<10; j++)
			ClientItemData[i][j][e_ItemID] = -1;
	}

	g_hItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);
	TF2Items_SetNumAttributes(g_hItem, 1);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("UE_RemoveEffect", Native_RemoveEffect);
	CreateNative("UE_RemovePlayerEffects", Native_RemovePlayerEffects);
	CreateNative("UE_GetUnusualEffectPermission", Native_GetUnusualEffectPermission);
	CreateNative("UE_SetUnusualEffectPermission", Native_SetUnusualEffectPermission);
	
	return APLRes_Success;
}

public OnMapStart() 
{
	if(LoadPermissions())
	{
		LogMessage("Unusual effects permissions loaded !");
		if(LibraryExists("freak_fortress_2"))
			IsFF2Enabled = FF2_IsFF2Enabled();
	}
	else
	{
		LogMessage("Error while charging permissions !");
		IsFF2Enabled = false;
	}
}

public OnConfigsExecuted()
{
	if(GetConVarBool(c_tag))
		TagsCheck("unusual");
}

stock TagsCheck(const String:tag[])
{
	new Handle:hTags = FindConVar("sv_tags");
	decl String:tags[255];
	GetConVarString(hTags, tags, sizeof(tags));

	if (!(StrContains(tags, tag, false)>-1))
	{
		decl String:newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		SetConVarString(hTags, newTags);
	}
	CloseHandle(hTags);
}

public OnClientAuthorized(iClient, const String:auth[])
{
	strcopy(ClientSteamID[iClient], 64, auth);
	for(new j=0; j<10;j++)
			ClientItemData[iClient][j][e_ItemID] = -1;
}

Connect()
{
	if (SQL_CheckConfig("unusual"))
	{
		SQL_TConnect(Connected, "unusual");
	}
	else
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
			LogMessage("Loading : Connected to SQLite Database");
			CreateDbSQLite();
		}
	}
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

	LogMessage("Loading : Connected to MySQL Database");
	SQL_TQuery(hndl, SQLErrorCheckCallback, "SET NAMES 'utf8'");
	db = hndl;
	SQL_CreateTables();
}

SQL_CreateTables()
{
	new len = 0;
	decl String:query[512];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `unusual_data` (");
	len += Format(query[len], sizeof(query)-len, "`ue_ID` int(10) unsigned NOT NULL AUTO_INCREMENT, ");
	len += Format(query[len], sizeof(query)-len, "`user_steamID` VARCHAR(64) NOT NULL, ");
	len += Format(query[len], sizeof(query)-len, "`item_ID` int(11) NOT NULL DEFAULT '-1', ");
	len += Format(query[len], sizeof(query)-len, "`effect_ID` int(11) NOT NULL DEFAULT '-1', ");
	len += Format(query[len], sizeof(query)-len, "`quality_ID` int(11) NOT NULL DEFAULT '-1', ");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY (`ue_ID`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;");
	if (SQL_FastQuery(db, query)) 
		LogMessage("Loading : Table Created");
}

CreateDbSQLite()
{
	new len = 0;
	decl String:query[512];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `unusual_data` (");
	len += Format(query[len], sizeof(query)-len, " `ID` INTEGER PRIMARY KEY AUTOINCREMENT,");
	len += Format(query[len], sizeof(query)-len, " `user_steamID` VARCHAR(64),");
	len += Format(query[len], sizeof(query)-len, " `item_ID` INTEGER DEFAULT -1,");
	len += Format(query[len], sizeof(query)-len, " `effect_ID` INTEGER DEFAULT -1,");
	len += Format(query[len], sizeof(query)-len, " `quality_ID` INTEGER DEFAULT -1");	
	len += Format(query[len], sizeof(query)-len, ");");
	if(SQL_FastQuery(db, query))
		LogMessage("Loading : Table Created");
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
	}
}


//--------------------------------------------------------------------------------------
//							Control
//--------------------------------------------------------------------------------------


stock GetClientID(String:PlayerSteamID[64])
{
	if(StrEqual(PlayerSteamID, ""))
		return -1;

	new iClient = -1;
	for(new i=1; i<MaxClients; i++)
		if(IsValidClient(i))
			if(StrEqual(ClientSteamID[i], PlayerSteamID))
			{
				iClient = i;
				continue;
			}
			
	return iClient;
}

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
	if(LoadPermissions())
	{
		if(IsValidClient(iClient))
			PrintToChat(iClient,"Unusual effects permissions reloaded !");
		else
			LogMessage("Unusual effects permissions reloaded !");
	}
	else
	{
		if(IsValidClient(iClient))
			PrintToChat(iClient,"Error while recharging permissions !");
		else
			LogMessage("Error while recharging permissions !");
	}
}

bool:LoadPermissions()
{
	new Handle: kv;
	kv = CreateKeyValues("Unusual_permissions");
	if(!FileToKeyValues(kv, PermissionsFile))
	{
		LogError("Can't open %s file",PERMISSIONFILE);
		CloseHandle(kv);
		return false;
	}

	KvGotoFirstSubKey(kv, true);
	Permission[0]  = KvGetNum(kv, "0", 0);
	Permission[1]  = KvGetNum(kv, "a", 0);
	Permission[2]  = KvGetNum(kv, "b", 0);
	Permission[3]  = KvGetNum(kv, "c", 0);
	Permission[4]  = KvGetNum(kv, "d", 0);
	Permission[5]  = KvGetNum(kv, "e", 0);
	Permission[6]  = KvGetNum(kv, "f", 0);
	Permission[7]  = KvGetNum(kv, "g", 0);
	Permission[8]  = KvGetNum(kv, "h", 0);
	Permission[9]  = KvGetNum(kv, "i", 0);
	Permission[10] = KvGetNum(kv, "j", 0);
	Permission[11] = KvGetNum(kv, "k", 0);
	Permission[12] = KvGetNum(kv, "l", 0);
	Permission[13] = KvGetNum(kv, "m", 0);
	Permission[14] = KvGetNum(kv, "n", 0);
	Permission[15] = KvGetNum(kv, "o", 0);
	Permission[16] = KvGetNum(kv, "p", 0);
	Permission[17] = KvGetNum(kv, "q", 0);
	Permission[18] = KvGetNum(kv, "r", 0);
	Permission[19] = KvGetNum(kv, "s", 0);
	Permission[20] = KvGetNum(kv, "t", 0);
	Permission[21] = KvGetNum(kv, "z", 0);
	CloseHandle(kv);
	return true;
}

bool:isAuthorized(iClient, bool:Strict)
{
	new Limit = GetLimit(GetUserFlagBits(iClient));

	if(Limit == -1)
		return true;
	
	if(Strict && NbOfEffect[iClient] < Limit)			return true;
	else if(!Strict && NbOfEffect[iClient] <= Limit)  return true;
	else											return false;
}

GetLimit(flags)
{
	new Limit 	= 0;
	new i 		= 0;
	
	if(flags == 0)				// Without flag 
		return Permission[0];
		
	do // With flag, detect best limit.
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

public OnClientDisconnect(iClient)
{
	if(!IsValidClient(iClient)) return;
	
	ClientSteamID[iClient] = "-1";

	for(new i=0; i<10; i++)
		ClientItemData[iClient][i][e_ItemID] = -1;
}

Updating(iClient)
{
	new String:buffer[128];
	Format(buffer, sizeof(buffer), "SELECT COUNT(`user_steamID`) AS NB FROM unusual_data WHERE `user_steamID` = '%s'", ClientSteamID[iClient]);
	SQL_TQuery(db, T_ClientControl, buffer, iClient);
}

public T_ClientControl(Handle:owner, Handle:hndl, const String:error[], any:iClient) // Control nbr of client effect (quota)
{
	if(!SQL_GetRowCount(hndl))
	{
		NbOfEffect[iClient] = 0;
		return;
	}
	
	while(SQL_FetchRow(hndl))
		NbOfEffect[iClient] = SQL_FetchInt(hndl,0);
		
	if(!isAuthorized(iClient, false))
	{
		CPrintToChat(iClient, "%t", "Sent6");
		RemoveEffect(iClient, ClientSteamID[iClient], "-1");
	}
	else // Control if player can still have scpefic UE
	{
		new String:buffer[128];
		Format(buffer, sizeof(buffer), "SELECT DISTINCT `effect_ID` FROM unusual_data WHERE `user_steamID` = '%s'", ClientSteamID[iClient]);
		SQL_TQuery(db, T_ClientControl2, buffer, iClient);
	}
}

public T_ClientControl2(Handle:owner, Handle:hndl, const String:error[], any:iClient) // Control each UE used by client
{
	if(!SQL_GetRowCount(hndl)) 
		return;
	
	new Handle:kv;
	kv = CreateKeyValues("Unusual_effects");
	if(!FileToKeyValues(kv, EffectsList))
	{
		LogError("[UNUSUAL] Could not open file %s", EFFECTSFILE);
		CloseHandle(kv);
		return;
	}
	
	new EffectID;
	new String:EffectFlag[2];
	new String:str_EffectID[8];
	
	while(SQL_FetchRow(hndl))
	{
		EffectID = SQL_FetchInt(hndl,0); 	// return an effect ID that client use
		
		Format(str_EffectID, sizeof(str_EffectID), "%i", EffectID);
		if(!KvJumpToKey(kv, str_EffectID, false))
		{
			LogMessage("DB contain effectID that do not exist: %i", EffectID);
			KvRewind(kv);
			continue;
		}
		
		KvGetString(kv, "flag", EffectFlag, sizeof(EffectFlag));
		KvRewind(kv);
		
		if(!IsClientUEAllowed(iClient, EffectFlag)) // If client can't use this effect => remove it
		{
			new String:buffer[128];
			Format(buffer, sizeof(buffer), "SELECT `item_ID` FROM unusual_data WHERE `user_steamID` = '%s' AND `effect_ID` = %i", ClientSteamID[iClient], EffectID);
			SQL_TQuery(db, T_ClientRemoveEffect, buffer, iClient);
		}
	}
	
	CloseHandle(kv);
}

public T_ClientRemoveEffect(Handle:owner, Handle:hndl, const String:error[], any:iClient) // Remove each item with the no allowed UE
{
	if(!SQL_GetRowCount(hndl)) 
		return;
	
	while(SQL_FetchRow(hndl))
	{
		new String:str_ItemID[10];
		Format(str_ItemID, sizeof(str_ItemID), "%i", SQL_FetchInt(hndl,0));
	
		RemoveEffect(iClient, ClientSteamID[iClient], str_ItemID);
	}
}

stock FixItemSlot(iItemDefinitionIndex, TFClassType:Class)
{
	/* Fix ShotGun Festive and Gun Mettle Skin for engineer*/
	if(Class == TFClass_Engineer)
	{
		if(iItemDefinitionIndex == 1141) return 0;
		if(iItemDefinitionIndex == 15003) return 0;
		if(iItemDefinitionIndex == 15016) return 0;
		if(iItemDefinitionIndex == 15044) return 0;
		if(iItemDefinitionIndex == 15047) return 0;
	}
	
	/* Fix ShotGun Festive and Gun Mettle Skin for other class*/
	if(iItemDefinitionIndex == 1141) return 1;
	if(iItemDefinitionIndex == 15003) return 1;
	if(iItemDefinitionIndex == 15016) return 1;
	if(iItemDefinitionIndex == 15044) return 1;
	if(iItemDefinitionIndex == 15047) return 1;
	
	return -1;
}

public Action:TF2Items_OnGiveNamedItem(iClient, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if(!IsValidClient(iClient)) return Plugin_Continue;
	if(IsFakeClient(iClient))	return Plugin_Continue;
	
	new TeamRestriction = GetConVarInt(c_TeamRest);	// Team restriction
	if(GetClientTeam(iClient) == TeamRestriction+1)
		return Plugin_Continue;
	
	if(GetConVarInt(c_FF2) && IsFF2Enabled)	// Freak Fortress 2 boss security
		if(FF2_GetBossUserId() == iClient)
			return Plugin_Continue;
	
	if(iItemDefinitionIndex == 739 || iItemDefinitionIndex == 142) // Blacklisted weapon due to crash.
		return Plugin_Continue;
	
	if(StrEqual(classname, "tf_wearable"))
		return Plugin_Continue;
	
	new String:strItemDefSlot[3];
	Format(strItemDefSlot, sizeof(strItemDefSlot), "%i", TF2IDB_GetItemSlot(iItemDefinitionIndex));
	
	new ItemDefSlot = FixItemSlot(iItemDefinitionIndex, TF2_GetPlayerClass(iClient)); // TF2IDB_GetItemSlot() return a wrong slot for some items
	if(ItemDefSlot < 0)
		ItemDefSlot = StringToInt(strItemDefSlot); 
	
	if(ItemDefSlot >= 10 || ItemDefSlot < 0)
		return Plugin_Continue;
	
	if(ClientItemData[iClient][ItemDefSlot][e_ItemID] != iItemDefinitionIndex)
	{
		//LogMessage("[%i] Loading item %i on slot %i state %i (old: %i)", iClient, iItemDefinitionIndex, ItemDefSlot, ItemDataInLoad[iClient], ClientItemData[iClient][ItemDefSlot][e_ItemID]);
	
		if(ItemDataInLoad[iClient] == IDIL_IDLE)
			ItemDataInLoad[iClient] = IDIL_START;
		else if(ItemDataInLoad[iClient] >= IDIL_REQUEST)
		{
			StopItemLoading[iClient] = true;
			ItemDataInLoad[iClient] = IDIL_START;
		}
		
		ClientItemData[iClient][ItemDefSlot][e_ItemID] 		= iItemDefinitionIndex;
		ClientItemData[iClient][ItemDefSlot][e_EffectID] 	= -1;
		ClientItemData[iClient][ItemDefSlot][e_QualityID] 	= -1;
		
		if(ItemDataInLoad[iClient] != IDIL_WAIT)
		{	
			CreateTimer(0.2, TimerUpdateWeapon, iClient);
			ItemDataInLoad[iClient] = IDIL_WAIT;
		}
		
		return Plugin_Continue;
	}
	else if(ItemDataInLoad[iClient] == IDIL_IDLE && ClientItemData[iClient][ItemDefSlot][e_EffectID] > -1)
	{
		
		//LogMessage("[%i] Set item %i on slot %i effect %i quality %i", iClient, iItemDefinitionIndex, ItemDefSlot, ClientItemData[iClient][ItemDefSlot][e_EffectID], ClientItemData[iClient][ItemDefSlot][e_QualityID]);
	
		TF2Items_SetAttribute(g_hItem, 0, 134, ClientItemData[iClient][ItemDefSlot][e_EffectID] * 1.0);
		
		if(ClientItemData[iClient][ItemDefSlot][e_QualityID] > -1)
		{
			TF2Items_SetQuality(g_hItem, ClientItemData[iClient][ItemDefSlot][e_QualityID]);
		
			hItem = g_hItem;
			//LogMessage("WEAPON %i, with %i for %i",iItemDefinitionIndex,ClientItemData[iClient][ItemDefSlot][e_EffectID],iClient);
			return Plugin_Changed;
		}
	}

	//LogMessage("[%i] No item %i on slot %i effect %i state %i", iClient, iItemDefinitionIndex, ItemDefSlot, ClientItemData[iClient][ItemDefSlot][e_EffectID], ItemDataInLoad[iClient]);
	return Plugin_Continue;
	
}

public Action:TimerUpdateWeapon(Handle:timer, any:iClient)
{	
	ItemDataInLoad[iClient] = IDIL_REQUEST;

	new String:itembuffer[1024] = "";
	for(new i=0; i<=GetMaximumNumberSlot(iClient); i++)
	{
		if(StrEqual(itembuffer, ""))
			Format(itembuffer, sizeof(itembuffer), "`item_ID` = '%i'", ClientItemData[iClient][i][e_ItemID]);
		else
			Format(itembuffer, sizeof(itembuffer), "%s OR `item_ID` = '%i'", itembuffer, ClientItemData[iClient][i][e_ItemID]);
	}
	
	if(StopItemLoading[iClient] == true) // Other items are currently loading
	{
		StopItemLoading[iClient] = false;
		ItemDataInLoad[iClient] = IDIL_IDLE;
		return;
	}
	
	new String:PlayerInfo[64];	
	GetClientAuthId(iClient, AuthId_Steam2, PlayerInfo, sizeof(PlayerInfo));
		
	new String:buffer[1024];
	Format(buffer, sizeof(buffer), "SELECT  `item_ID`, `effect_ID`, `quality_ID` FROM unusual_data WHERE `user_steamID` = '%s' AND ( %s )", PlayerInfo, itembuffer);
	//LogMessage("%s", buffer);
	SQL_TQuery(db, T_UpdateClientItemDataSlot, buffer, iClient);
}

public T_UpdateClientItemDataSlot(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	if(!SQL_GetRowCount(hndl))
	{
		ItemDataInLoad[iClient] = IDIL_IDLE;
		//LogMessage("Nothing in the DB!");
		return;
	}
		
	new String:strItemDefSlot[3];
	new ItemDefSlot;
	
	while(SQL_FetchRow(hndl))
	{
		Format(strItemDefSlot, sizeof(strItemDefSlot), "%i", TF2IDB_GetItemSlot(SQL_FetchInt(hndl, 0)));
		ItemDefSlot = FixItemSlot(SQL_FetchInt(hndl, 0), TF2_GetPlayerClass(iClient)); // TF2IDB_GetItemSlot() return a wrong slot for some items
		if(ItemDefSlot < 0)
			ItemDefSlot = StringToInt(strItemDefSlot);
	
		if(ItemDefSlot >= 10 || ItemDefSlot < 0)
		{
			ItemDataInLoad[iClient] = IDIL_IDLE;
			return;
		}
			
		if(StopItemLoading[iClient] == true) // Other items are currently loading
		{
			StopItemLoading[iClient] = false;
			ItemDataInLoad[iClient] = IDIL_IDLE;
			return;
		}
		
		if(ClientItemData[iClient][ItemDefSlot][e_ItemID] != SQL_FetchInt(hndl, 0))
		{
			ItemDataInLoad[iClient] = IDIL_IDLE;
			return;
		}
		
		ClientItemData[iClient][ItemDefSlot][e_EffectID]  = SQL_FetchInt(hndl, 1);
		ClientItemData[iClient][ItemDefSlot][e_QualityID] = SQL_FetchInt(hndl, 2);
		//LogMessage("item: %i, effect: %i, quality: %i", SQL_FetchInt(hndl,0), SQL_FetchInt(hndl,1), SQL_FetchInt(hndl,2));
	}
	
	UpdateWeapon(iClient);
}

UpdateWeapon(iClient)
{
	if(!IsValidClient(iClient))
	{	
		ItemDataInLoad[iClient] = IDIL_IDLE;
		
		for(new i=0; i<10; i++)
		{
			ClientItemData[iClient][i][e_ItemID]    = -1;
			ClientItemData[iClient][i][e_EffectID]  = -1;
			ClientItemData[iClient][i][e_QualityID] = -1;
		}
		return;
	}
	
	new Clip[6] = {0, ...};
	new Ammo[6] = {0, ...};
	new SlotMax = GetMaximumNumberSlot(iClient);
		
	for(new i = 0; i<=SlotMax; i++)
	{
		Clip[i] = GetClip(iClient, i);
		Ammo[i] = GetAmmo(iClient, i);
		TF2_RemoveWeaponSlot(iClient, i);
	}
	
	//LogMessage("Regenerate player!")
	ItemDataInLoad[iClient] = IDIL_IDLE;
	TF2_RegeneratePlayer(iClient);
	
	new iHealth = GetClientHealth(iClient);
	if (iHealth < GetClientHealth(iClient)) 
		SetEntityHealth(iClient, iHealth);
	
	for(new i=0; i<=SlotMax; i++)
	{
		if(Clip[i] != -1 && Clip[i] < GetClip(iClient, i))
			SetClip(iClient, i, Clip[i]);
		if(Ammo[i] != -1 && Ammo[i] < GetAmmo(iClient, i))
			SetAmmo(iClient, i, Ammo[i]);
	}
	
	Updating(iClient);
}

GetMaximumNumberSlot(iClient)
{
	new TFClassType:Class = TF2_GetPlayerClass(iClient);
	if(Class <= TFClass_Unknown)
		return 0;
		
	new SlotMax = 2;
	if(Class == TFClass_Spy)
		SlotMax = 4;
	else if(Class == TFClass_Engineer)
		SlotMax = 5;
		
	return SlotMax;
}

stock GetClip(iClient, WeapSlot)
{
	new weapon = GetPlayerWeaponSlot(iClient, WeapSlot);
	if(IsValidEntity(weapon))
	{
		new iAmmo = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		return GetEntData(weapon, iAmmo);
	}
	return -1;
}

stock GetAmmo(iClient, WeapSlot)
{
	new weapon = GetPlayerWeaponSlot(iClient, WeapSlot);
	if(IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmo = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		return GetEntData(iClient, iAmmo+iOffset);
	}
	return -1;
}

stock SetClip(iClient, WeapSlot, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(iClient, WeapSlot);
	if (IsValidEntity(weapon))
	{
		new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		SetEntData(weapon, iAmmoTable, newAmmo, 4, true);
	}
}

stock SetAmmo(iClient, WeapSlot, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(iClient, WeapSlot);
	if(IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(iClient, iAmmoTable+iOffset, newAmmo, 4, true);
	}
}

//--------------------------------------------------------------------------------------
//							Menu selection
//--------------------------------------------------------------------------------------
	
FirstMenu(iClient)
{	
	if(IsValidClient(iClient))
	{
		new TeamRestriction = GetConVarInt(c_TeamRest);
		if(GetClientTeam(iClient) == TeamRestriction+1)
		{
			if(TeamRestriction == 1)
			{
				CPrintToChat(iClient, "%t", "Sent1", "Red");
				return;
			}
			else if(TeamRestriction == 2)
			{
				CPrintToChat(iClient, "%t", "Sent1", "Blue");
				return;
			}
		}
		
		if(GetConVarInt(c_FF2) && IsFF2Enabled)	// Freak Fortress 2 boss security
			if(FF2_GetBossUserId() == iClient)
			{
				CPrintToChat(iClient, "%t", "Sent1", "Boss");
				return;
			}
			
		new String:PlayerInfo[64];	
		GetClientAuthId(iClient, AuthId_Steam2, PlayerInfo, sizeof(PlayerInfo));
		strcopy(SteamUsed[iClient], 64, PlayerInfo);
		
		new Handle:Menu1 = CreateMenu(Menu1_1);
		SetMenuTitle(Menu1, "What do you want ?");
		AddMenuItem(Menu1, "0", "Add/modify weapons");
		AddMenuItem(Menu1, "1", "Delete effects");
		AddMenuItem(Menu1, "2", "Show effects");
		
		if((GetConVarInt(c_PanelFlag) == 0 && (GetUserFlagBits(iClient) & ADMFLAG_ROOT)) || (GetConVarInt(c_PanelFlag) == 1 && ((GetUserFlagBits(iClient) & ADMFLAG_GENERIC) || (GetUserFlagBits(iClient) & ADMFLAG_ROOT)) ))
		{
			AddMenuItem(Menu1, "3", "Admin tools: Add/modify");
			AddMenuItem(Menu1, "4", "Admin tools: Delete");
		}
			
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
			QualityMenu(iClient);
		else if(args == 1)
			DeleteWeapPanel(iClient);
		else if(args == 2)
		{
			FirstMenu(iClient);
			ShowMOTDPanel(iClient, "Unusual effects", WEBSITE, MOTDPANEL_TYPE_URL );
		}
		else if(args == 3) // AT add/modify item
		{
			AT_Choice_add[iClient] = true;
			AT_OnlinePlayers_Menu(iClient);
		}
		else if(args == 4)	// AT delete item
		{
			AT_Choice_add[iClient] = false;
			AT_First_Menu(iClient);
		}
	}
}


//--------------------------------------------------------------------------------------
//							Remove Effect
//--------------------------------------------------------------------------------------


DeleteWeapPanel(iClient)
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT `item_ID` FROM unusual_data WHERE `user_steamID` = '%s'", SteamUsed[iClient]);
	SQL_TQuery(db, T_DeleteWeapPanel, buffer, iClient);
}

public T_DeleteWeapPanel(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	new Handle:YourItemsMenu = CreateMenu(YourItemsMenuAnswer);
		
	SetMenuTitle(YourItemsMenu, "What items ?");
		
	if(!SQL_GetRowCount(hndl)) // nothing in db
	{
		CPrintToChat(iClient, "%t","Sent3");
		return;
	}
	
	new WeapID;
	new String:ItemsName[64];
	new String:strWeapID[10];
	
	AddMenuItem(YourItemsMenu, "-1", "All");
	
	while(SQL_FetchRow(hndl))
	{
		WeapID 	= SQL_FetchInt(hndl,0);
		Format(strWeapID, sizeof(strWeapID), "%i", WeapID);
		TF2IDB_GetItemName(WeapID, ItemsName, sizeof(ItemsName));
		AddMenuItem(YourItemsMenu, strWeapID, ItemsName);
	}

	SetMenuExitButton(YourItemsMenu, true);
	DisplayMenu(YourItemsMenu, iClient, MENU_TIME_FOREVER);
}

public YourItemsMenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		new String:WeapID[10];
		GetMenuItem(menu, args, WeapID, sizeof(WeapID));
		
		if(IsValidClient(iClient))
			RemoveEffect(iClient, SteamUsed[iClient], WeapID);
	}	
}

bool:RemoveEffect(iClient, String:PlayerSteamID[64], String:WeapID[])
{
	new clientControled = -1;
	
	clientControled = GetClientID(PlayerSteamID);
	
	
	if(StrEqual(WeapID, "-1"))	// remove player from the DB
	{
		new String:buffer[255];
		Format(buffer, sizeof(buffer), "DELETE FROM unusual_data WHERE `user_steamID` = '%s'", PlayerSteamID);
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		
		if(clientControled != iClient && IsValidClient(iClient))
		{
			if(IsValidClient(clientControled))
				CPrintToChat(iClient, "%t","Sent11", clientControled);
			else
				CPrintToChat(iClient, "%t","Sent4", PlayerSteamID);
		}
		
		if(clientControled != -1)
		{
			for(new i=0; i<10; i++)
			{
				ClientItemData[clientControled][i][e_EffectID] = -1;
				ClientItemData[clientControled][i][e_QualityID] = -1;
			}
			
			if(IsValidClient(clientControled))
				CPrintToChat(clientControled, "%t","Sent10");
		}
	}
	else  // Remove this player item from BD
	{
		new String:buffer[255];
		Format(buffer, sizeof(buffer), "DELETE FROM unusual_data WHERE `user_steamID` = '%s' AND `item_ID` = %i", PlayerSteamID, StringToInt(WeapID));
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		
		if(clientControled != iClient && IsValidClient(iClient))
			CPrintToChat(iClient, "%t", "Sent12", StringToInt(WeapID));
		
		if(clientControled != -1)
		{
			if(GetClientTeam(clientControled) == 2  || GetClientTeam(clientControled) == 3)
			{
				new String:strItemDefSlot[2];
				Format(strItemDefSlot, sizeof(strItemDefSlot), "%i", TF2IDB_GetItemSlot(StringToInt(WeapID)));
				new ItemDefSlot = FixItemSlot(StringToInt(WeapID), TF2_GetPlayerClass(clientControled)); // TF2IDB_GetItemSlot() return a wrong slot for some items
				if(ItemDefSlot < 0)
					ItemDefSlot = StringToInt(strItemDefSlot);
				
				ClientItemData[clientControled][ItemDefSlot][e_EffectID] = -1;
				ClientItemData[clientControled][ItemDefSlot][e_QualityID] = -1;
			}
			
			if(IsValidClient(clientControled))
				CPrintToChat(clientControled, "%t", "Sent12", StringToInt(WeapID));
		}
	}

	if(clientControled != -1)
	{
		if(GetClientTeam(clientControled) == 2 || GetClientTeam(clientControled) == 3)
			UpdateWeapon(clientControled);
			
		if(IsValidClient(iClient) && IsValidClient(clientControled))
			if(iClient == clientControled)
				DeleteWeapPanel(iClient);
			else
				FirstMenu(iClient);
		
	}
	return true;
}


//--------------------------------------------------------------------------------------
//							Quality + Effect
//--------------------------------------------------------------------------------------


QualityMenu(iClient)
{
	new clientControled = GetClientID(SteamUsed[iClient]);
	if(clientControled == -1)
	{
		CPrintToChat(iClient, "%t", "Sent9");
		return;
	}
	
	if(!isAuthorized(clientControled, true)) // Can have more unusual effects ?
	{
		CPrintToChat(iClient, "%t", "Sent7");
		FirstMenu(iClient);
		return;
	}
	
	new EntitiesID = GetEntPropEnt(clientControled, Prop_Data, "m_hActiveWeapon");
	if(EntitiesID < 0)
	{
		CPrintToChat(iClient, "%t", "Sent14");
		return;
	}
		
	ClientItems[iClient] = GetEntProp(EntitiesID, Prop_Send, "m_iItemDefinitionIndex");
	if(ClientItems[iClient] == 739 || ClientItems[iClient] == 142) // Blacklisted weapon due to crash.
	{
		CPrintToChat(iClient, "%t", "Sent13");
		FirstMenu(iClient);
		return;
	}
	
	decl String:Title[64];
	decl String:WeapName[64];
	new Handle:Qltymenu = CreateMenu(QltymenuAnswer);
	
	TF2IDB_GetItemName(ClientItems[iClient], WeapName, sizeof(WeapName)); 
	Format(Title, sizeof(Title), "Select a quality: %s",WeapName);
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
		Quality[iClient] = args;
		PanelEffect(iClient);
	}
}

PanelEffect(iClient)
{
	new String:EffectID[8];
	new String:EffectName[128];
	new String:EffectFlag[2];

	new Handle:UnusualMenu = CreateMenu(UnusualMenuAnswer);
	SetMenuTitle(UnusualMenu, "Select an unusual effect:");
	AddMenuItem(UnusualMenu, "0", "Show effects");
	
	new Handle:kv;
	kv = CreateKeyValues("Unusual_effects");
	if(!FileToKeyValues(kv, EffectsList))
	{
		LogError("[UNUSUAL] Could not open file %s", EFFECTSFILE);
		CloseHandle(kv);
		return;
	}
	
	if(!KvGotoFirstSubKey(kv, true)) // First UE
	{
		LogMessage("ERROR: Can't find unusual effects in %s", EFFECTSFILE);
		CloseHandle(kv);
		return;
	}
	
	do
	{
		KvGetSectionName(kv, EffectID, sizeof(EffectID));
		KvGetString(kv, "name", EffectName, sizeof(EffectName));
		KvGetString(kv, "flag", EffectFlag, sizeof(EffectFlag));
		
		if(IsClientUEAllowed(iClient, EffectFlag))
			AddMenuItem(UnusualMenu, EffectID, EffectName);
	}
	while(KvGotoNextKey(kv, true)) // while there are UE
	
	CloseHandle(kv);

	SetMenuExitButton(UnusualMenu, true);
	DisplayMenu(UnusualMenu, iClient, MENU_TIME_FOREVER);
}

public UnusualMenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Select)
	{
		if(args == 0)
		{
			PanelEffect(iClient);
			ShowMOTDPanel(iClient, "Unusual effects", WEBSITE, MOTDPANEL_TYPE_URL );
			return;
		}
		
		new String:strEffect[8];
		GetMenuItem(menu, args, strEffect, sizeof(strEffect));
		Effect[iClient] = StringToInt(strEffect);
		if(IsValidClient(iClient)) AddUnusualEffect(iClient);
	}	
}

bool:IsClientUEAllowed(iClient, const String:EffectFlag[])
{
	if(StrEqual(EffectFlag, "0") || StrEqual(EffectFlag, "") || StrEqual(EffectFlag, "-1"))
		return true;
	
	new flag = GetUserFlagBits(iClient);
	if(flag & ADMFLAG_GENERIC || flag & ADMFLAG_ROOT)
		return true;
	
	if(flag & GetUEFlag(EffectFlag))
		return true;

	return false;	
}

GetUEFlag(const String:Value[])
{
	new String:FlagsLetter[21][2] = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "z"};
	
	for(new i=0; i<21; i++)
		if(StrEqual(Value, FlagsLetter[i]))
			return FlagsList[i];
	
	return -1;
}

bool:AddUnusualEffect(iClient)
{
	if(ClientItems[iClient] < 0)	// Is Valid item ID
		return;
		
	if(ClientItems[iClient] == 739 || ClientItems[iClient] == 142) // Blacklisted weapon due to crash.
	{
		CPrintToChat(iClient, "%t", "Sent13");
		return;
	}

	if(TF2IDB_GetItemSlot(ClientItems[iClient]) >= TF2ItemSlot:5)
		return;
	
	if(StrEqual(SteamUsed[iClient], ""))
		CPrintToChat(iClient, "%t", "Sent5");
		
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT * FROM unusual_data WHERE `user_steamID` = '%s' AND `item_ID` = '%i'", SteamUsed[iClient], ClientItems[iClient]);
	SQL_TQuery(db, T_UpdateClient, buffer, iClient);
}

public T_UpdateClient(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	new clientControled = GetClientID(SteamUsed[iClient]);
	if(clientControled == -1 || !IsValidClient(clientControled))
	{
		CPrintToChat(iClient, "%t", "Sent9");
		return;
	}
	
	if(!isAuthorized(clientControled, true))
	{
		CPrintToChat(iClient, "%t", "Sent7");
		return;
	}
	
	if(!SQL_GetRowCount(hndl))
	{
		new String:buffer[256];
		if(!SQLite)
		{
			Format(buffer, sizeof(buffer), "INSERT INTO unusual_data (`user_steamID`,`item_ID`,`effect_ID`,`quality_ID`) VALUES ('%s','%i','%i','%i')", SteamUsed[iClient], ClientItems[iClient], Effect[iClient], Quality[iClient]);
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		}
		else
		{
			Format(buffer, sizeof(buffer), "INSERT INTO unusual_data VALUES ('%s','%i','%i','%i')", SteamUsed[iClient], ClientItems[iClient], Effect[iClient], Quality[iClient]);
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		}
		
		if(IsValidClient(clientControled)) 	NbOfEffect[clientControled]++;
	}
	else
	{
		new String:buffer[256];
		while (SQL_FetchRow(hndl))
		{
			Format(buffer, sizeof(buffer), "UPDATE unusual_data SET `effect_ID` = %i, `quality_ID` = %i WHERE `user_steamID` = '%s' AND `item_ID` = %i", Effect[iClient], Quality[iClient], SteamUsed[iClient], ClientItems[iClient]);
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		}
	}
	
	if(GetClientTeam(clientControled) == 2  || GetClientTeam(clientControled) == 3)
	{
		new String:strItemDefSlot[2];
		Format(strItemDefSlot, sizeof(strItemDefSlot), "%i", TF2IDB_GetItemSlot(ClientItems[iClient]));
		new ItemDefSlot = FixItemSlot(ClientItems[iClient], TF2_GetPlayerClass(clientControled)); // TF2IDB_GetItemSlot() return a wrong slot for some items
		if(ItemDefSlot < 0)
			ItemDefSlot = StringToInt(strItemDefSlot);
		
		ClientItemData[clientControled][ItemDefSlot][e_EffectID] = Effect[iClient];
		ClientItemData[clientControled][ItemDefSlot][e_QualityID] = Quality[iClient];
	}
	
	if(IsValidClient(clientControled)) 
		UpdateWeapon(clientControled);
	
	
	if(IsValidClient(iClient)) 			CPrintToChat(iClient, "%t", "Sent8");
	if(iClient != clientControled && IsValidClient(clientControled)) 	CPrintToChat(clientControled, "%t", "Sent8");
	
	if(IsValidClient(iClient) && IsValidClient(clientControled))
	{
		FirstMenu(iClient);
	}
}


//--------------------------------------------------------------------------------------
//							Admin tool menu
//--------------------------------------------------------------------------------------


AT_First_Menu(iClient)
{
	new Handle:AdMenu = CreateMenu(AT_First_Menu_Ans);
	SetMenuTitle(AdMenu, "Admin Tools: Which kind of player ?");
	
	AddMenuItem(AdMenu, "0", "Players on the server");
	AddMenuItem(AdMenu, "1", "Players from the BD");
	
	SetMenuExitButton(AdMenu, true);
	DisplayMenu(AdMenu, iClient, MENU_TIME_FOREVER);
}

public AT_First_Menu_Ans(Handle:menu, MenuAction:action, iClient, args)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Select)
	{
		if(args == 0)
			AT_OnlinePlayers_Menu(iClient);
		else
			AT_BDPlayers_Menu(iClient);
	}
}

AT_OnlinePlayers_Menu(iClient)
{
	new Handle:AdMenu = CreateMenu(AT_OnlinePlayers_Menu_Ans);
	new String:str_PlayerID[5];
	new String:str_PlayerName[128];
	new count = 0;
	SetMenuTitle(AdMenu, "Admin Tools: Player selection");
	
	for(new i=0; i<MaxClients; i++)
	{
		if(IsValidClient(i) && i != iClient && IsClientInGame(i) && !IsFakeClient(i))
		{
			Format(str_PlayerID, sizeof(str_PlayerID), "%d",i);
			GetClientName(i, str_PlayerName, sizeof(str_PlayerName));
			AddMenuItem(AdMenu, str_PlayerID, str_PlayerName);
			count++;
		}
	}
	
	if(count == 0)
	{
		CPrintToChat(iClient, "%t", "Sent2");
		CloseHandle(AdMenu);
		FirstMenu(iClient);
		return;
	}
	
	SetMenuExitButton(AdMenu, true);
	DisplayMenu(AdMenu, iClient, MENU_TIME_FOREVER);
}

public AT_OnlinePlayers_Menu_Ans(Handle:menu, MenuAction:action, iClient, args)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Select)
	{
		new String:str_PlayerID[5];
		new String:PlayerInfo[64];
		GetMenuItem(menu, args, str_PlayerID, sizeof(str_PlayerID));
		GetClientAuthId(StringToInt(str_PlayerID), AuthId_Steam2, PlayerInfo, sizeof(PlayerInfo));
		strcopy(SteamUsed[iClient], 64, PlayerInfo);
		
		if(!IsValidClient(StringToInt(str_PlayerID)))
		{
			CPrintToChat(iClient, "%t", "Sent9");
			AT_OnlinePlayers_Menu(iClient);
		}
		else
		{
			if(AT_Choice_add[iClient])
				QualityMenu(iClient);
			else
				DeleteWeapPanel(iClient);
		}
	}
}

AT_BDPlayers_Menu(iClient)
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT DISTINCT `user_steamID` FROM unusual_data ORDER BY `user_steamID`");
	SQL_TQuery(db, AT_BDPlayers_Menu_2, buffer, iClient);
}

public AT_BDPlayers_Menu_2(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	if(!SQL_GetRowCount(hndl))
	{
		CPrintToChat(iClient, "%t", "Sent2");
		FirstMenu(iClient);
		return;
	}
	
	new Handle:AdMenu = CreateMenu(AT_BDPlayers_Menu_Ans);
	SetMenuTitle(AdMenu, "Admin Tools: Player selection");
	
	new String:PlayerInfo[64];
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, PlayerInfo, sizeof(PlayerInfo));
		AddMenuItem(AdMenu, PlayerInfo, PlayerInfo);
	}
	
	SetMenuExitButton(AdMenu, true);
	DisplayMenu(AdMenu, iClient, MENU_TIME_FOREVER);
}

public AT_BDPlayers_Menu_Ans(Handle:menu, MenuAction:action, iClient, args)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Select)
	{
		new String:PlayerInfo[64];
		GetMenuItem(menu, args, PlayerInfo, sizeof(PlayerInfo));
		strcopy(SteamUsed[iClient], 64, PlayerInfo);
		
		DeleteWeapPanel(iClient);
	}
}


//--------------------------------------------------------------------------------------
//							Native Functions
//--------------------------------------------------------------------------------------


public Native_RemoveEffect(Handle:plugin, numParams)
{
	new String:PlayerSteamID[64];
	new String:WeapID[10];
	GetNativeString(1, PlayerSteamID, 64);
	
	if(GetNativeCell(2) < 0)
		return false;
	Format(WeapID, sizeof(WeapID), "%d", GetNativeCell(2));
	
	return RemoveEffect(-1, PlayerSteamID, WeapID);
}

public Native_RemovePlayerEffects(Handle:plugin, numParams)
{
	new String:PlayerSteamID[64];
	GetNativeString(1, PlayerSteamID, 64);
	
	return RemoveEffect(-1, PlayerSteamID, "-1");
}

public Native_GetUnusualEffectPermission(Handle:plugin, numParams)
{
	new Bit = GetNativeCell(1);
	
	if(Bit == -1)
		return Permission[0];

	new i=0;
	while(FlagsList[i] != Bit && i<21)
		i++;	
	
	if(i < 21)
		return Permission[i+1];
	
	LogError("INVALID FLAGBIT !");
	return -2;
}

public Native_SetUnusualEffectPermission(Handle:plugin, numParams)
{
	new Bit  = GetNativeCell(1);
	new Limit = GetNativeCell(2);

	if(Limit < -1)
	{
		LogError("INVALID LIMIT !");
		return false;
	}

	new String:FlagBitToLetter[22][2] = {"0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "z"};
	new Handle:kv;
	kv = CreateKeyValues("Unusual_permissions");
	if(!FileToKeyValues(kv, PermissionsFile))
	{
		LogError("Can't open %s file", PERMISSIONFILE);
		CloseHandle(kv);
		return false;
	}

	KvGotoFirstSubKey(kv, true);
	if(Bit == -1)
		KvSetNum(kv, "0", Limit);
	else
	{
		new i=0;
		while(FlagsList[i] != Bit && i<21)
			i++;	
			
		if(i<21)
			KvSetNum(kv, FlagBitToLetter[i+1], Limit);
		else
		{
			CloseHandle(kv);
			LogError("INVALID FLAGBIT !");
			return false;
		}
	}
		
	KvRewind(kv);
	if(!KeyValuesToFile(kv, PermissionsFile))
	{
		CloseHandle(kv);
		LogError("Plugin ERROR : Can't save %s modifications !", PERMISSIONFILE);
		return false;
	}
	
	CloseHandle(kv);
	return LoadPermissions();
}


