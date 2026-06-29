#define PLUGIN_VERSION "1.0.7"

#define MAX_FEATURES	400
#define	MAX_CATEGORIES	50

// Comment out to stop debugging messages!
//#define	DEBUG			1

#include <sourcemod>
#include <hub>
#undef REQUIRE_PLUGIN

/*********************************************************************************************/
// Efficient Cvar Handling from Zephyrus

#define CVAR_LENGTH 128
#define MAX_CVARS 32

enum CVAR_TYPE
{
		TYPE_INT = 0,
		TYPE_FLOAT,
		TYPE_STRING,
		TYPE_FLAG
}
 
enum CVAR_CACHE
{
		Handle:hCvar,
		CVAR_TYPE:eType,
		any:aCache,
		String:sCache[CVAR_LENGTH]
}new g_eCvars[MAX_CVARS][CVAR_CACHE];
 
new g_iCvars = 0;
 
public RegisterConVar(String:name[], String:value[], String:description[], CVAR_TYPE:type)
{
		new Handle:cvar = CreateConVar(name, value, description);
		HookConVarChange(cvar, GlobalConVarChanged);
		g_eCvars[g_iCvars][hCvar] = cvar;
		g_eCvars[g_iCvars][eType] = type;
		if(g_eCvars[g_iCvars][eType]==TYPE_INT)
				g_eCvars[g_iCvars][aCache] = GetConVarInt(cvar);
		else if(g_eCvars[g_iCvars][eType]==TYPE_FLOAT)
				g_eCvars[g_iCvars][aCache] = GetConVarFloat(cvar);
		else if(g_eCvars[g_iCvars][eType]==TYPE_STRING)
				GetConVarString(cvar, g_eCvars[g_iCvars][sCache], CVAR_LENGTH);
		else if(g_eCvars[g_iCvars][eType]==TYPE_FLAG)
		{
				GetConVarString(cvar, g_eCvars[g_iCvars][sCache], CVAR_LENGTH);
				g_eCvars[g_iCvars][aCache] = ReadFlagString(g_eCvars[g_iCvars][sCache]);
		}
		g_iCvars++;
		return g_iCvars-1;
}
 
public GlobalConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
		new i;
		for(i=0;i<g_iCvars;++i)
				if(g_eCvars[i][hCvar]==convar)
						break;
		if(g_eCvars[i][eType]==TYPE_INT)
		{
				g_eCvars[i][aCache] = StringToInt(newValue);
		} else if(g_eCvars[i][eType]==TYPE_FLOAT)
		{
				g_eCvars[i][aCache] = StringToFloat(newValue);
		} else if(g_eCvars[i][eType]==TYPE_STRING)
		{
				strcopy(g_eCvars[i][sCache], CVAR_LENGTH, newValue);
		} else if(g_eCvars[i][eType]==TYPE_FLAG)
		{
				strcopy(g_eCvars[i][sCache], CVAR_LENGTH, newValue);
				g_eCvars[i][aCache] = ReadFlagString(newValue);
		}
}

/*********************************************************************************************/

enum HubCategories
{
	Hub_Admin = -5,
	Hub_Purchase,
	Hub_Gift,
	Hub_Refund
};

new Handle:gH_Database = INVALID_HANDLE;
new bool:g_bIsMySQL = false;
new Handle:gH_Trie_Features = INVALID_HANDLE;
new Handle:gH_Array_Types = INVALID_HANDLE;
new Handle:gH_Array_Menus = INVALID_HANDLE;
new String:g_sAuthId[MAXPLAYERS+1][32];
new bool:g_bClientHasFeature[MAXPLAYERS+1][MAX_FEATURES];
new g_iFeatureCost[MAX_FEATURES];
new g_iFeatureType[MAX_FEATURES] = {-2, ...};
new String:g_sFeatureName[MAX_FEATURES][64];
new String:g_sCategoryCommand[MAX_CATEGORIES][32];
new g_iCreditSnapshot[MAXPLAYERS+1];
new g_iCredits[MAXPLAYERS+1] = {NO_CASH, ...};
new g_iMenuType[MAXPLAYERS+1];
new g_iFeatures = 0;

new Handle:gH_Frwd_AddFeature = INVALID_HANDLE;
new Handle:gH_Frwd_RemoveFeature = INVALID_HANDLE;
new Handle:gH_Frwd_OnHubClientConfigured = INVALID_HANDLE;

new String:g_sMenuTitle[32];

new g_Cvar_vBulletin;
new g_Cvar_Database;
new g_Cvar_SteamLinkURL;
new g_Cvar_SellbackRate;
new g_Cvar_ChatPrefix;
new g_Cvar_Logging;

public Plugin:myinfo = 
{
	name = "Hub",
	author = "databomb",
	description = "Provides a donator system for integration with other plugins.",
	version = PLUGIN_VERSION,
	url = "vintagejailbreak.org"
};

public OnPluginStart()
{
	// Register console variables
	CreateConVar("sm_hub_version", PLUGIN_VERSION, "Hub Version Number",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	gH_Trie_Features = CreateTrie();
	gH_Array_Types = CreateArray(66);
	gH_Array_Menus = CreateArray(66);
	
	RegConsoleCmd("sm_perks", Command_Store, "Use in-game credits to purchase items.");
	RegConsoleCmd("sm_store", Command_Store, "Use in-game credits to purchase items.");
	RegConsoleCmd("sm_hub", Command_Store, "Use in-game credits to purchase items.");
	RegConsoleCmd("sm_features", Command_Store, "Use in-game credits to purchase items.");
	
	RegAdminCmd("sm_credit", Command_Credit, ADMFLAG_RCON, "Adds credits or reports current credits.");
	RegAdminCmd("sm_reload_hub", Command_Reload_Hub, ADMFLAG_RCON, "Manually updates the config files.");
	
	// RegisterConVar(String:name[], String:value[], String:description[], CVAR_TYPE:type)
	g_Cvar_vBulletin = RegisterConVar("sm_hub_vbulletin", "1", "Determines vBulletin integration.", TYPE_INT);
	g_Cvar_Database = RegisterConVar("sm_hub_database", "store", "Determines the database.cfg driver to use.", TYPE_STRING);
	g_Cvar_SteamLinkURL = RegisterConVar("sm_hub_link_url", "http://xenogamers.org/profile.php?do=steamlink", "Determines pop-up for users who join without a Steam Link.", TYPE_STRING);
	g_Cvar_SellbackRate = RegisterConVar("sm_hub_sell_rate", "0.50", "The rate at which items are refunded when sold back to the store.", TYPE_FLOAT);
	g_Cvar_ChatPrefix = RegisterConVar("sm_hub_chat_prefix", "\x03[xG] \x01", "The prefix before each chat message.", TYPE_STRING);
	g_Cvar_Logging = RegisterConVar("sm_hub_logging", "0", "Whether a separate transaction logging database is kept and updated for each transaction.", TYPE_INT);
	
	AutoExecConfig(true, "hub-1");

	LoadTranslations("common.phrases");
	LoadTranslations("hub.phrases");
	
	gH_Frwd_AddFeature = CreateGlobalForward("HubFeatureAdded", ET_Ignore, Param_Cell, Param_String);
	gH_Frwd_RemoveFeature = CreateGlobalForward("HubFeatureRemoved", ET_Ignore, Param_Cell, Param_String);
	gH_Frwd_OnHubClientConfigured = CreateGlobalForward("OnHubClientConfigured", ET_Ignore, Param_Cell);
}

public Action:Command_Credit(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "Cmd Credit Usage");
		return Plugin_Handled;
	}

	decl String:sTarget[32];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	new target = FindTarget(client, sTarget);
	
	if (target <= 0)
	{
		ReplyToCommand(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "No matching client");
		return Plugin_Handled;
	}
	
	if (args > 1)
	{
		decl String:sNameTarget[64];
		GetClientName(target, sNameTarget, sizeof(sNameTarget));
		
		if (g_iCredits[target] == NO_CASH)
		{
			ReplyToCommand(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "Cmd Credit Check", sNameTarget, g_iCredits[target]);
			return Plugin_Handled;
		}
		
		decl String:sCredits[255];
		GetCmdArg(2, sCredits, sizeof(sCredits));
		new iCredits = StringToInt(sCredits);
		
		Credit(target, iCredits);
		
		decl String:sNameClient[64];
		GetClientName(client, sNameClient, sizeof(sNameClient));
		
		LogMessage("%t", "Cmd Credit Log", sNameClient, sNameTarget, iCredits);
		ShowActivity2(client, g_eCvars[g_Cvar_ChatPrefix][sCache], "%t", "Cmd Credit Log", sNameClient, sNameTarget, iCredits);
	}
	else
	{
		decl String:sNameTarget[64];
		GetClientName(target, sNameTarget, sizeof(sNameTarget));
		ReplyToCommand(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "Cmd Credit Check", sNameTarget, g_iCredits[target]);
	}
	
	return Plugin_Handled;
}

public SQL_CB_Connect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("FATAL ERROR CONNECTING TO DATABASE: %s", error);
	}
	else
	{
		CheckDatabaseType(hndl);
		gH_Database = hndl;
		
		// non vbulletin users will need their own table
		if (!g_eCvars[g_Cvar_vBulletin][aCache])
		{
			decl String:sQuery[255];
			if (g_bIsMySQL)
			{
				Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `hub` (`credits` int(32) NOT NULL,`steam_code` varchar(32) NOT NULL, `credits_features` varchar(4000), PRIMARY KEY (`steam_code`))");
			}
			else
			{
				Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS hub(credits INTEGER, steam_code TEXT PRIMARY KEY, credits_features TEXT );");
			}
			SQL_TQuery(gH_Database, SQL_CB_LogErrorOnly, sQuery);
		}
		// vbulletin users need some new fields
		else
		{
			if (!g_bIsMySQL)
			{
				SetFailState("MySQL required for vBulletin integration!");
			}
			
			decl String:sQuery[255];
			Format(sQuery, sizeof(sQuery), "ALTER TABLE vb_user ADD COLUMN credits int(32) DEFAULT 0, ADD COLUMN credits_features varchar(4000)");
			SQL_TQuery(gH_Database, SQL_CB_DontCare, sQuery);
		}
		
		// transactional logging
		if (g_eCvars[g_Cvar_Logging][aCache])
		{
			decl String:sQuery[255];
			if (g_bIsMySQL)
			{
				Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `hub_log` (`steam_code` varchar(32) NOT NULL, `timestamp` int(32) NOT NULL, `change` int(32) NOT NULL, `description` varchar(256))");
			}
			else
			{
				Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS hub_log(steam_code TEXT, timestamp INTEGER, change INTEGER, description TEXT );");
			}
			SQL_TQuery(gH_Database, SQL_CB_LogErrorOnly, sQuery);
		}
	}
}

CheckDatabaseType(Handle:database)
{
	decl String:buffer[255];
	SQL_GetDriverIdent(SQL_ReadDriver(database), buffer, sizeof(buffer));
	g_bIsMySQL = StrEqual(buffer,"mysql", false);
}

public SQL_CB_DontCare(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		#if defined DEBUG
		LogError("Query error (check SYNTAX): %s", error);
		#endif
	}
}

public SQL_CB_LogErrorOnly(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query Error: %s", error);
	}
}


public SQL_CB_ClientConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query Error: %s", error);
	}
	else
	{
		new client;
		
		// Is the client still connected?
		if ((client = GetClientOfUserId(data)) == 0)
		{
			return;
		}
		
		if (!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl))
		{
			#if defined DEBUG
			LogMessage("No rows returned for connect query for %N", client);
			#endif
			
			if (g_eCvars[g_Cvar_vBulletin][aCache])
			{
				PrintToConsole(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "vB No Steam Link", g_eCvars[g_Cvar_SteamLinkURL][sCache]);
			}
			else
			{
				// make default entry
				decl String:sQuery[255];
				Format(sQuery, sizeof(sQuery), "INSERT INTO hub (credits, steam_code) VALUES (0, '%s')", g_sAuthId[client]);
				g_iCredits[client] = 0;
				g_iCreditSnapshot[client] = 0;
				
				#if defined DEBUG
				LogMessage("Created row for %s", g_sAuthId[client]);
				#endif
				
				SQL_TQuery(gH_Database, SQL_CB_LogErrorOnly, sQuery);
			}
			
			return;
		}
		
		g_iCredits[client] = SQL_FetchInt(hndl, 0);
		g_iCreditSnapshot[client] = g_iCredits[client];
		
		decl String:sFeatures[4000];
		SQL_FetchString(hndl, 1, sFeatures, sizeof(sFeatures));
		
		#if defined DEBUG
		LogMessage("Credits %d Features %s", g_iCredits[client], sFeatures);
		#endif
		
		ParseFeatureSet(client, sFeatures);
	}
}

void:ParseFeatureSet(client, const String:sFeatures[])
{
	decl String:sNames[MAX_FEATURES][64];
	new iFeatures = ExplodeString(sFeatures, ",", sNames, MAX_FEATURES, 64);
	
	if (!strlen(sFeatures))
	{
		#if defined DEBUG
		PrintToConsole(client, "No features detected.");
		#endif
		
		return;
	}
	
	new key;
	for (new idx = 0; idx < iFeatures; idx++)
	{
		if (GetTrieValue(gH_Trie_Features, sNames[idx], key))
		{
			g_bClientHasFeature[client][key] = true;
			
			#if defined DEBUG
			PrintToConsole(client, "Adding feature: %s", sNames[idx]);
			#endif
		}
		else
		{
			#if defined DEBUG
			PrintToConsole(client, "Could not find key for feature: %s", sNames[idx]);
			#endif
		}
	}
	
	#if defined DEBUG
	PrintToConsole(client, "Scanned %d features on your account.", iFeatures);
	#endif
	
	new ignore;
	Call_StartForward(gH_Frwd_OnHubClientConfigured);
	Call_PushCell(client);
	Call_Finish(ignore);
}

public OnClientPostAdminCheck(client)
{
	if (IsClientInGame(client))
	{
		if (!GetClientAuthString(client, g_sAuthId[client], sizeof(g_sAuthId[])))
		{
			#if defined DEBUG
			LogMessage("Error finding steamid for %N", client);
			#endif
			return;
		}
		
		decl String:sQuery[512];
		if (g_eCvars[g_Cvar_vBulletin][aCache])
		{
			Format(sQuery, sizeof(sQuery), "SELECT credits, credits_features FROM vb_user WHERE steam_code = '%s'", g_sAuthId[client]);
		}
		else
		{
			Format(sQuery, sizeof(sQuery), "SELECT credits, credits_features FROM hub WHERE steam_code = '%s'", g_sAuthId[client]);
		}
		
		#if defined DEBUG
		LogMessage(sQuery);
		#endif
		
		SQL_TQuery(gH_Database, SQL_CB_ClientConnect , sQuery, GetClientUserId(client));
	}
}

public OnMapEnd()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client))
		{
			if (g_iCredits[client] >= 0)
			{
				// Save credits to database
				decl String:sQuery[512];
				if (g_eCvars[g_Cvar_vBulletin][aCache])
				{
					Format(sQuery, sizeof(sQuery), "SELECT credits FROM vb_user WHERE steam_code = '%s'", g_sAuthId[client]);
				}
				else
				{
					Format(sQuery, sizeof(sQuery), "SELECT credits FROM hub WHERE steam_code = '%s'", g_sAuthId[client]);
				}
				
				#if defined DEBUG
				LogMessage(sQuery);
				#endif
				
				new iSessionCredits = g_iCredits[client] - g_iCreditSnapshot[client];
				new Handle:pack = CreateDataPack();
				WritePackCell(pack, iSessionCredits);
				WritePackString(pack, g_sAuthId[client]);
				
				SQL_TQuery(gH_Database, SQL_CB_AdjudicateCredits, sQuery, pack);
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if (g_iCredits[client] >= 0)
	{
		// Save credits to database
		decl String:sQuery[512];
		if (g_eCvars[g_Cvar_vBulletin][aCache])
		{
			Format(sQuery, sizeof(sQuery), "SELECT credits FROM vb_user WHERE steam_code = '%s'", g_sAuthId[client]);
		}
		else
		{
			Format(sQuery, sizeof(sQuery), "SELECT credits FROM hub WHERE steam_code = '%s'", g_sAuthId[client]);
		}
		
		#if defined DEBUG
		LogMessage(sQuery);
		#endif
		
		new iSessionCredits = g_iCredits[client] - g_iCreditSnapshot[client];
		new Handle:pack = CreateDataPack();
		WritePackCell(pack, iSessionCredits);
		WritePackString(pack, g_sAuthId[client]);
		
		SQL_TQuery(gH_Database, SQL_CB_AdjudicateCredits, sQuery, pack);
	}

	for (new idx = 0; idx < MAX_FEATURES; idx++)
	{
		g_bClientHasFeature[client][idx] = false;
	}
	
	Format(g_sAuthId[client], sizeof(g_sAuthId[]), "");
	
	g_iCreditSnapshot[client] = 0;
	g_iCredits[client] = NO_CASH;
}

public SQL_CB_AdjudicateCredits(Handle:owner, Handle:hndl, const String:error[], any:pack)
{
	ResetPack(pack);
	new iCreditsDifference = ReadPackCell(pack);
	new String:sAuthId[32];
	ReadPackString(pack, sAuthId, sizeof(sAuthId));
	CloseHandle(pack);
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query Error: %s", error);
	}
	else
	{	
		if (!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl))
		{
			#if defined DEBUG
			LogMessage("No rows returned for connect query for %s", sAuthId);
			#endif
			
			return;
		}
		
		new iCredits = SQL_FetchInt(hndl, 0);
		new iNewCredits = iCredits + iCreditsDifference;
		
		if (iNewCredits < 0)
		{
			LogMessage("%s was caught kiting credits! Their balance of %d was kept.", sAuthId, iNewCredits);
		}
		
		#if defined DEBUG
		LogMessage("Credit Difference %d Existing Credits %d New Credits %d", iCreditsDifference, iCredits, iNewCredits);
		#endif
		
		decl String:sQuery[255];
		
		if (g_eCvars[g_Cvar_vBulletin][aCache])
		{
			Format(sQuery, sizeof(sQuery), "UPDATE vb_user SET credits = '%d' WHERE steam_code = '%s'", iNewCredits, sAuthId);
		}
		else
		{
			Format(sQuery, sizeof(sQuery), "UPDATE hub SET credits = '%d' WHERE steam_code = '%s'", iNewCredits, sAuthId);
		}
		
		#if defined DEBUG
		LogMessage(sQuery);
		#endif
		
		SQL_TQuery(gH_Database, SQL_CB_LogErrorOnly, sQuery);
	}
}

public APLRes:AskPluginLoad2(Handle:h_Myself, bool:bLateLoaded, String:sError[], error_max)
{
	CreateNative("Credit", Native_Credit);
	CreateNative("Debit", Native_Debit);
	CreateNative("ClientHasFeature", Native_ClientHasFeature);
	CreateNative("Inquire", Native_Inquire);
	return APLRes_Success;
}

public Native_Inquire(Handle:h_Plugin, iParameters)
{
	new client = GetNativeCell(1);
	if (!client || client > MAXPLAYERS+1)
	{
		ThrowNativeError(1, "Invalid client index %d", client);
		return -1;
	}
	
	return g_iCredits[client];
}

public Native_ClientHasFeature(Handle:h_Plugin, iParameters)
{
	new client = GetNativeCell(1);
	decl String:sFeature[256];
	GetNativeString(2, sFeature, sizeof(sFeature));
	
	new key;
	if (!GetTrieValue(gH_Trie_Features, sFeature, key))
	{
		ThrowNativeError(1, "Invalid trie lookup for feature: %s", sFeature);
		return false;
	}
	
	return g_bClientHasFeature[client][key];
}

public Native_Credit(Handle:h_Plugin, iParameters)
{
	new client = GetNativeCell(1);
	
	if (!client || client > MAXPLAYERS+1)
	{
		ThrowNativeError(1, "Invalid client index %d", client);
		return;
	}
	
	if (g_iCredits[client] == NO_CASH)
	{
		// silently return (client is not linked, etc.)
		return;
	}
	
	new amount =  GetNativeCell(2);
	
	g_iCredits[client] += amount;
}

public Native_Debit(Handle:h_Plugin, iParameters)
{
	new client = GetNativeCell(1);
	
	if (!client || client > MAXPLAYERS+1)
	{
		ThrowNativeError(1, "Invalid client index %d", client);
		return -1;
	}
	
	new amount =  GetNativeCell(2);
	
	// check for people trying to steal money
	if (amount < 0)
	{
		return false;
	}
	
	// check if they have enough money
	if (g_iCredits[client] - amount < 0)
	{
		return false;
	}
	
	g_iCredits[client] -= amount;
	return true;
}

public Action:Command_Store(client, arguments)
{
	if (g_iCredits[client] == NO_CASH)
	{
		if (!g_eCvars[g_Cvar_vBulletin][aCache])
		{
			ReplyToCommand(client, "%sError Rcvd: No Cash For Your User.", g_eCvars[g_Cvar_ChatPrefix][sCache]);
			return Plugin_Handled;
		}
		
		ReplyToCommand(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "vB No Steam Link", g_eCvars[g_Cvar_SteamLinkURL][sCache]);
		
		new iLength = strlen(g_eCvars[g_Cvar_SteamLinkURL][sCache]);
		if (iLength > 0)
		{
			#if defined DEBUG
			PrintToConsole(client, "Trying URL: %s", g_eCvars[g_Cvar_SteamLinkURL][sCache]);
			#endif
			
			if (iLength > 192)
			{
				LogError("Your sm_hub_link_url cvar is too long!");
			}
			else
			{
				decl String:sTitle[64];
				Format(sTitle, sizeof(sTitle), "%t", "Steam Link URL Title");
				ShowMOTDPanel(client, sTitle, g_eCvars[g_Cvar_SteamLinkURL][sCache], MOTDPANEL_TYPE_URL);
			}
		}
		return Plugin_Handled;
	}
	
	Menu_Hub(client);
	
	return Plugin_Handled;
}

void:Menu_Hub(client)
{
	new Handle:menu = CreateMenu(Handler_Hub);
	SetMenuTitle(menu, "%s\nCredits: %d\n ", g_sMenuTitle, g_iCredits[client]);
	
	decl String:sInfo[10], String:sTitle[64];
	IntToString(_:Hub_Purchase, sInfo, sizeof(sInfo));
	Format(sTitle, sizeof(sTitle), "%t", "Hub Menu Purchase");
	AddMenuItem(menu, sInfo, sTitle);
	IntToString(_:Hub_Gift, sInfo, sizeof(sInfo));
	Format(sTitle, sizeof(sTitle), "%t", "Hub Menu Gift");
	AddMenuItem(menu, sInfo, sTitle);
	IntToString(_:Hub_Refund, sInfo, sizeof(sInfo));
	Format(sTitle, sizeof(sTitle), "%t\n ", "Hub Menu Refund");
	AddMenuItem(menu, sInfo, sTitle);
	
	// *** check for admin
	/*if (0)
	{
		IntToString(_:Hub_Admin, sInfo, sizeof(sInfo));
		Format(sTitle, sizeof(sTitle), "%t\n ", "Hub Menu Admin");
		AddMenuItem(menu, sInfo, sTitle);
	}*/
	
	new iSize = GetArraySize(gH_Array_Menus);
	for (new idx = 0; idx < iSize; idx++)
	{
		new iType = GetArrayCell(gH_Array_Menus, idx, sizeof(sTitle)+1);
		if (iType == -1)
		{
			GetArrayString(gH_Array_Menus, idx, sTitle, sizeof(sTitle));
			IntToString(idx, sInfo, sizeof(sInfo));
			AddMenuItem(menu, sInfo, sTitle);
			
			#if defined DEBUG
			PrintToConsole(client, "Added %s to main menu with index %s", sTitle, sInfo);
			#endif
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Handler_Custom(Handle:menu, MenuAction:action, client, choice)
{
	if (action == MenuAction_Select)
	{
		decl String:sInfo[32];
		GetMenuItem(menu, choice, sInfo, sizeof(sInfo));
		
		FakeClientCommand(client, sInfo);
		
		#if defined DEBUG
		PrintToConsole(client, "Sent command %s", sInfo);
		#endif
	}
	else if (action == MenuAction_Cancel)
	{
		Menu_Hub(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Handler_Hub(Handle:menu, MenuAction:action, client, choice)
{
	if (action == MenuAction_Select)
	{
		// create sub-menu
		decl String:sInfo[10];
		GetMenuItem(menu, choice, sInfo, sizeof(sInfo));
		new iSelection = StringToInt(sInfo);
		
		#if defined DEBUG
		PrintToConsole(client, "You selected %d", iSelection);
		#endif
		
		switch (iSelection)
		{
			case Hub_Purchase:
			{
				Menu_Store(client);
			}
			case Hub_Gift:
			{
				Menu_Gift(client);
			}
			case Hub_Refund:
			{
				Menu_FeatureList(client);
			}
			// custom menus
			default:
			{
				
				// check for command being present or if it's a submenu
				if (strlen(g_sCategoryCommand[iSelection]) > 0)
				{
					PrintToConsole(client, "Custom cmd: %s", g_sCategoryCommand[iSelection]);
					FakeClientCommand(client, g_sCategoryCommand[iSelection]);
				}
				// it's a sub-menu
				else
				{
					#if defined DEBUG
					PrintToChat(client, "Going to custom menu.");
					#endif
					Menu_Custom(client, iSelection);
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Handler_Gift(Handle:menu, MenuAction:action, client, choice)
{
	if (action == MenuAction_Select)
	{
		// create sub-menu
		decl String:sInfo[10];
		GetMenuItem(menu, choice, sInfo, sizeof(sInfo));
		new target = StringToInt(sInfo);
		
		Menu_FeatureList(client, target);
	}
	else if (action == MenuAction_Cancel)
	{
		Menu_Hub(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Handler_Sell(Handle:menu, MenuAction:action, client, choice)
{
	if (action == MenuAction_Select)
	{
		// create sub-menu
		decl String:sInfo[10];
		GetMenuItem(menu, choice, sInfo, sizeof(sInfo));
		new iFeature = StringToInt(sInfo);
		// Sell item
		RemoveFeature(client, iFeature);
		new Float:fCost = 0.0;
		fCost = FloatMul(float(g_iFeatureCost[iFeature]),g_eCvars[g_Cvar_SellbackRate][aCache]);
		new iCost = RoundToNearest(fCost);
		Credit(client, iCost);
		PrintToChat(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "Processed Refund", g_sFeatureName[iFeature], iCost);
	}
	else if (action == MenuAction_Cancel)
	{
		Menu_Hub(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Handler_GiveGift(Handle:menu, MenuAction:action, client, choice)
{
	if (action == MenuAction_Select)
	{
		// create sub-menu
		decl String:sInfo[10];
		// get target
		GetMenuItem(menu, 0, sInfo, sizeof(sInfo));
		new target = GetClientOfUserId(StringToInt(sInfo));
		if (!target)
		{
			PrintToChat(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "Player no longer available");
		}
		else
		{
			GetMenuItem(menu, choice, sInfo, sizeof(sInfo));
			new iFeature = StringToInt(sInfo);
			
			// check if client already has that feature
			if (g_bClientHasFeature[target][iFeature])
			{
				decl String:sNameTarget[64];
				GetClientName(target, sNameTarget, sizeof(sNameTarget));
				PrintToChat(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "Target Already Owns Gift", sNameTarget, g_sFeatureName[iFeature]);
			}
			else
			{			
				// transfer
				RemoveFeature(client, iFeature);
				AddFeature(target, iFeature);
				decl String:sNameTarget[64], String:sNameClient[64];
				GetClientName(target, sNameTarget, sizeof(sNameTarget));
				GetClientName(client, sNameClient, sizeof(sNameClient));
				PrintToChat(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "Gave Gift", g_sFeatureName[iFeature], sNameTarget);
				PrintToChat(target, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "Received Gift", sNameClient, g_sFeatureName[iFeature]);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		Menu_Hub(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void:Menu_FeatureList(client, target = 0)
{
	new Handle:menu;
	decl String:sTitle[64];
	decl String:sInfo[10];
	if (!target)
	{
		menu = CreateMenu(Handler_Sell);
	}
	else
	{
		menu = CreateMenu(Handler_GiveGift);
	}
	
	if (target)
	{
		SetMenuTitle(menu, "%s\n%t\n ", g_sMenuTitle, "SubMenu Title Gift Feature");
		
		// Use a disabled menu item to transmit information instead of using a pack
		Format(sInfo, sizeof(sInfo), "%d", target);
		decl String:sNameTarget[64];
		GetClientName(GetClientOfUserId(target), sNameTarget, sizeof(sNameTarget));
		Format(sTitle, sizeof(sTitle), "%t\n ", "Gift To Menu Line", sNameTarget);
		AddMenuItem(menu, sInfo, sTitle, ITEMDRAW_DISABLED);
	}
	else
	{
		SetMenuTitle(menu, "%s\n%t\n ", g_sMenuTitle, "SubMenu Title Sell Feature");
	}
	
	new items;
	for (new idx = 0; idx < MAX_FEATURES; idx++)
	{
		if (g_bClientHasFeature[client][idx])
		{
			items++;
			IntToString(idx, sInfo, sizeof(sInfo));
			AddMenuItem(menu, sInfo, g_sFeatureName[idx]);
		}
	}
	
	if (!items)
	{
		PrintToChat(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "No Items Owned");
		CloseHandle(menu);
		Menu_Hub(client);
		return;
	}
	
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void:Menu_Gift(client)
{
	new Handle:menu = CreateMenu(Handler_Gift);
	SetMenuTitle(menu, "%s\n%t\n ", g_sMenuTitle, "SubMenu Title Gift Player");
	
	decl String:sInfo[10];
	decl String:sTitle[64];
	new players;
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		if (IsClientInGame(idx) && idx != client && g_iCredits[idx] != NO_CASH)
		{
			players++;
			IntToString(GetClientUserId(idx), sInfo, sizeof(sInfo));
			Format(sTitle, sizeof(sTitle), "%N", idx);
			AddMenuItem(menu, sInfo, sTitle);
		}
	}
	
	if (!players)
	{
		PrintToChat(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "No matching clients");
		CloseHandle(menu);
		Menu_Hub(client);
		return;
	}
	
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void:Menu_Custom(client, index)
{
	new Handle:menu = CreateMenu(Handler_Custom);
	decl String:sTitle[64];
	GetArrayString(gH_Array_Menus, index, sTitle, sizeof(sTitle));
	SetMenuTitle(menu, "%s\n%s\nCredits: %d\n ", g_sMenuTitle, sTitle, g_iCredits[client]);
	
	new iSize = GetArraySize(gH_Array_Menus);
	for (new idx = 0; idx < iSize; idx++)
	{
		new subtype = GetArrayCell(gH_Array_Menus, idx, sizeof(sTitle)+1);
		#if defined DEBUG
		PrintToConsole(client, "Type %d SubType %d Index %d", index, subtype, idx);
		#endif
		if (subtype == index)
		{
			if (strlen(g_sCategoryCommand[idx]) > 0)
			{
				GetArrayString(gH_Array_Menus, idx, sTitle, sizeof(sTitle));
				AddMenuItem(menu, g_sCategoryCommand[idx], sTitle);
				#if defined DEBUG
				PrintToConsole(client, "Added %s to use menu with cmd %s", sTitle, g_sCategoryCommand[idx]);
				#endif
			}
			else
			{
				LogError("Malformed menus.cfg");
			}
		}

	}
	
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void:Menu_Store(client)
{
	new Handle:menu = CreateMenu(Handler_Store);
	SetMenuTitle(menu, "%s\nCredits: %d\n ", g_sMenuTitle, g_iCredits[client]);
	decl String:sChoice[5];
	new String:sTitle[64];
	
	new iSize = GetArraySize(gH_Array_Types);
	new subtype = -1;
	for (new idx = 0; idx < iSize; idx++)
	{	
		subtype = GetArrayCell(gH_Array_Types, idx, sizeof(sTitle)+1);
		if (subtype == -1)
		{
			GetArrayString(gH_Array_Types, idx, sTitle, sizeof(sTitle));
			IntToString(idx, sChoice, sizeof(sChoice));
			AddMenuItem(menu, sChoice, sTitle);
			
			#if defined DEBUG
			PrintToConsole(client, "Added %s to main menu with index %s", sTitle, sChoice);
			#endif
		}
	}
	
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void:Menu_FirstSub(client, iTypeIndex)
{
	decl String:sTitle[64];
	decl String:sInfo[10];
	GetArrayString(gH_Array_Types, iTypeIndex, sTitle, sizeof(sTitle));
	
	new Handle:submenu = CreateMenu(Handler_SubMenu);
	SetMenuTitle(submenu, "%s\n%t\nCredits: %d\n ", g_sMenuTitle, "SubMenu Title Buy Subset", sTitle, g_iCredits[client]);
	
	// add sub menu categories, if any
	decl String:sChoice[5];
	new iSize = GetArraySize(gH_Array_Types);
	for (new idx = 0; idx < iSize; idx++)
	{
		new subtype = GetArrayCell(gH_Array_Types, idx, sizeof(sTitle)+1);
		if (subtype == iTypeIndex)
		{
			g_iMenuType[client] = iTypeIndex;
			GetArrayString(gH_Array_Types, idx, sTitle, sizeof(sTitle));
			IntToString(-idx, sChoice, sizeof(sChoice));
			AddMenuItem(submenu, sChoice, sTitle);
			
			#if defined DEBUG
			PrintToConsole(client, "Added %s as submenu with %s", sTitle, sChoice);
			#endif
		}
	}
	
	// add all features for this top category
	new type = -1;
	for (new idx = 0; idx < MAX_FEATURES; idx++)
	{
		type = g_iFeatureType[idx];
		
		if (type == iTypeIndex)
		{
			IntToString(idx, sInfo, sizeof(sInfo));
		
			if (g_bClientHasFeature[client][idx])
			{
				Format(sTitle, sizeof(sTitle), "%s %t", g_sFeatureName[idx], "Owned Menu Item Suffix");
				AddMenuItem(submenu, sInfo, sTitle, ITEMDRAW_DISABLED);
			}
			else
			{
				Format(sTitle, sizeof(sTitle), "%s (%d)", g_sFeatureName[idx], g_iFeatureCost[idx]);
				AddMenuItem(submenu, sInfo, sTitle);
			}
		}
	}
	
	SetMenuExitButton(submenu, true);
	SetMenuExitBackButton(submenu, true);
	DisplayMenu(submenu, client, MENU_TIME_FOREVER);
}

public Handler_Store(Handle:menu, MenuAction:action, client, choice)
{
	if (action == MenuAction_Select)
	{
		// create sub-menu
		decl String:sInfo[10];
		GetMenuItem(menu, choice, sInfo, sizeof(sInfo));
		new iTypeIndex = StringToInt(sInfo);
		Menu_FirstSub(client, iTypeIndex);
	}
	else if (action == MenuAction_Cancel)
	{
		Menu_Hub(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Handler_SubSubMenu(Handle:menu, MenuAction:action, client, choice)
{
	if (action == MenuAction_Select)
	{
		// check to see if they have the money
		decl String:sInfo[10];
		GetMenuItem(menu, choice, sInfo, sizeof(sInfo));
		new iFeature = StringToInt(sInfo);
		
		// debit
		new cost = g_iFeatureCost[iFeature];
		
		if (Debit(client, cost))
		{
			AddFeature(client, iFeature);
			PrintToChat(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "Purchased Feature", g_sFeatureName[iFeature]);
		}
		else
		{
			PrintToChat(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "Insufficient Credits");
			return;
		}
	}
	else if (action == MenuAction_Cancel)
	{
		#if defined DEBUG
		PrintToConsole(client, "Trying to go back a submenu with index %d", g_iMenuType[client]);
		#endif
		Menu_FirstSub(client, g_iMenuType[client]);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Handler_SubMenu(Handle:menu, MenuAction:action, client, choice)
{
	if (action == MenuAction_Select)
	{
		// check to see if they have the money
		decl String:sInfo[10];
		GetMenuItem(menu, choice, sInfo, sizeof(sInfo));
		new iFeature = StringToInt(sInfo);
		
		// debit
		if (iFeature >= 0)
		{
			new cost = g_iFeatureCost[iFeature];
			
			if (Debit(client, cost))
			{
				AddFeature(client, iFeature);
				PrintToChat(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "Purchased Feature", g_sFeatureName[iFeature]);
			}
			else
			{
				PrintToChat(client, "%s%t", g_eCvars[g_Cvar_ChatPrefix][sCache], "Insufficient Credits");
				return;
			}
		}
		// more menus
		else
		{
			new iTypeIndex = -iFeature;
			
			#if defined DEBUG
			PrintToConsole(client, "submenu %d", iTypeIndex);
			#endif
			Menu_SubMenu(client, iTypeIndex);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		Menu_Store(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void:Menu_SubMenu(client, iTypeIndex)
{
	decl String:sTitle[64];
	GetArrayString(gH_Array_Types, iTypeIndex, sTitle, sizeof(sTitle));
	
	new Handle:submenu = CreateMenu(Handler_SubSubMenu);
	SetMenuTitle(submenu, "%s\n%t\nCredits: %d\n ", g_sMenuTitle, "SubMenu Title Buy Subset", sTitle, g_iCredits[client]);
	
	new type = -1;
	decl String:sInfo[10];
	for (new idx = 0; idx < MAX_FEATURES; idx++)
	{
		type = g_iFeatureType[idx];
		
		if (type == iTypeIndex)
		{
			IntToString(idx, sInfo, sizeof(sInfo));
		
			if (g_bClientHasFeature[client][idx])
			{
				Format(sTitle, sizeof(sTitle), "%s %t", g_sFeatureName[idx], "Owned Menu Item Suffix");
				AddMenuItem(submenu, sInfo, sTitle, ITEMDRAW_DISABLED);
			}
			else
			{
				Format(sTitle, sizeof(sTitle), "%s (%d)", g_sFeatureName[idx], g_iFeatureCost[idx]);
				AddMenuItem(submenu, sInfo, sTitle);
			}
		}
	}
	
	SetMenuExitButton(submenu, true);
	SetMenuExitBackButton(submenu, true);
	DisplayMenu(submenu, client, MENU_TIME_FOREVER);
}

void:RemoveFeature(client, iFeature)
{
	g_bClientHasFeature[client][iFeature] = false;
	new String:sFeatures[4000];
	for (new idx = 0; idx < MAX_FEATURES; idx++)
	{
		if (g_bClientHasFeature[client][idx])
		{
			StrCat(sFeatures, sizeof(sFeatures), g_sFeatureName[idx]);
			StrCat(sFeatures, sizeof(sFeatures), ",");
		}
	}

	// update sql
	decl String:sQuery[4100];
	if (g_eCvars[g_Cvar_vBulletin][aCache])
	{
		Format(sQuery, sizeof(sQuery), "UPDATE vb_user SET credits_features = '%s' WHERE steam_code = '%s'", sFeatures, g_sAuthId[client]);
	}
	else
	{
		Format(sQuery, sizeof(sQuery), "UPDATE hub SET credits_features = '%s' WHERE steam_code = '%s'", sFeatures, g_sAuthId[client]);
	}
	
	#if defined DEBUG
	LogMessage(sQuery);
	#endif
	
	SQL_TQuery(gH_Database, SQL_CB_LogErrorOnly, sQuery);
	
	new ignore;
	Call_StartForward(gH_Frwd_RemoveFeature);
	Call_PushCell(client);
	Call_PushString(g_sFeatureName[iFeature]);
	Call_Finish(ignore);
}

void:AddFeature(client, iFeature)
{
	new String:sFeatures[4000];
	g_bClientHasFeature[client][iFeature] = true;
	for (new idx = 0; idx < MAX_FEATURES; idx++)
	{
		if (g_bClientHasFeature[client][idx])
		{
			StrCat(sFeatures, sizeof(sFeatures), g_sFeatureName[idx]);
			StrCat(sFeatures, sizeof(sFeatures), ",");
		}
	}
	
	#if defined DEBUG
	PrintToConsole(client, "Features: %s", sFeatures);
	#endif
	
	// update sql
	decl String:sQuery[4100];
	if (g_eCvars[g_Cvar_vBulletin][aCache])
	{
		Format(sQuery, sizeof(sQuery), "UPDATE vb_user SET credits_features = '%s' WHERE steam_code = '%s'", sFeatures, g_sAuthId[client]);
	}
	else
	{
		Format(sQuery, sizeof(sQuery), "UPDATE hub SET credits_features = '%s' WHERE steam_code = '%s'", sFeatures, g_sAuthId[client]);
	}
	
	#if defined DEBUG
	LogMessage(sQuery);
	#endif
	
	SQL_TQuery(gH_Database, SQL_CB_LogErrorOnly, sQuery);
	
	new ignore;
	Call_StartForward(gH_Frwd_AddFeature);
	Call_PushCell(client);
	Call_PushString(g_sFeatureName[iFeature]);
	Call_Finish(ignore);
}

public OnMapStart()
{
	LoadFeatures();
}

public OnConfigsExecuted()
{
	Format(g_sMenuTitle, 32, "%T", "Hub Title", LANG_SERVER);
	
	if (gH_Database == INVALID_HANDLE)
	{
		SQL_TConnect(SQL_CB_Connect, g_eCvars[g_Cvar_Database][sCache]);
	}
}

public Action:Command_Reload_Hub(client, args)
{
	LoadFeatures(true);
	ReplyToCommand(client, "Reloaded menus.cfg and features.cfg");
	return Plugin_Handled;
}

void:LoadFeatures(bool:force = false)
{
	ClearArray(gH_Array_Types);
	ClearArray(gH_Array_Menus);
	ClearTrie(gH_Trie_Features);
	
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/hub/menus.cfg");
	static iLastKvLoadMenus = 0;
	new bool:bSkipMenus = false;
	new iCurrentKvLoad;
	decl String:sBuffer[64];
	
	if (!force)
	{
		iCurrentKvLoad = GetFileTime(sPath, FileTime_LastChange);
		if(iCurrentKvLoad < iLastKvLoadMenus)
		{
			bSkipMenus = true;
		}
		else
		{
			iLastKvLoadMenus = iCurrentKvLoad;
		}
	}
	
	if (!bSkipMenus)
	{
		new Handle:hMenus = CreateKeyValues("Menus");
		if(FileToKeyValues(hMenus, sPath))
		{
			if (!KvGotoFirstSubKey(hMenus))
			{
				LogError("Error reading donator features config file.");
				return;
			}
			
			do
			{
				KvGetSectionName(hMenus, sBuffer, sizeof(sBuffer));
				
				new iTypeIndex = FindStringInArray(gH_Array_Menus, sBuffer);
				if (iTypeIndex == -1)
				{
					iTypeIndex = PushArrayString(gH_Array_Menus, sBuffer);
					#if defined DEBUG
					LogMessage("Added %s to menu list", sBuffer);
					#endif
					
					SetArrayCell(gH_Array_Menus, iTypeIndex, -1, sizeof(sBuffer)+1);
					
					KvGetString(hMenus, "command", g_sCategoryCommand[iTypeIndex], sizeof(g_sCategoryCommand[]));
					#if defined DEBUG
					LogMessage("Detected command link: %s", g_sCategoryCommand[iTypeIndex]);
					#endif
					
				}
				else
				{
					LogError("Duplicate entry found in config. Ignoring duplicate: %s", sBuffer);
				}
				
				if (!strlen(g_sCategoryCommand[iTypeIndex]))
				{
					if (KvGotoFirstSubKey(hMenus))
					{
						do
						{
							KvGetSectionName(hMenus, sBuffer, sizeof(sBuffer));
							
							new iSubTypeIndex = FindStringInArray(gH_Array_Menus, sBuffer);
							if (iSubTypeIndex == -1)
							{
								iSubTypeIndex = PushArrayString(gH_Array_Menus, sBuffer);
								#if defined DEBUG
								LogMessage("Added %s to sub menu list", sBuffer);
								#endif
								
								SetArrayCell(gH_Array_Menus, iSubTypeIndex, iTypeIndex, sizeof(sBuffer)+1);
								
								KvGetString(hMenus, "command", g_sCategoryCommand[iSubTypeIndex], sizeof(g_sCategoryCommand[]));
								#if defined DEBUG
								LogMessage("Detected command link: %s", g_sCategoryCommand[iSubTypeIndex]);
								#endif
							}
							else
							{
								LogError("Duplicate entry found in config. Ignoring duplicate: %s", sBuffer);
							}
							
						} while (KvGotoNextKey(hMenus));
					
						KvGoBack(hMenus);
					}
					
				}
				
			} while (KvGotoNextKey(hMenus));
		}
		else
		{
			SetFailState("Bad command or file name: %s", sPath);
		}
		CloseHandle(hMenus);
	}
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/hub/features.cfg");
	static iLastKvLoadFeatures = 0;
	new bool:bSkipFeatures = false;
	
	if (!force)
	{
		iCurrentKvLoad = GetFileTime(sPath, FileTime_LastChange);
		if(iCurrentKvLoad < iLastKvLoadFeatures)
		{
			bSkipFeatures = true;
		}
		else
		{
			iLastKvLoadFeatures = iCurrentKvLoad;
		}
	}
	
	if (!bSkipFeatures)
	{
		g_iFeatures = 0;
		new Handle:hFeatures = CreateKeyValues("Features");
		if(FileToKeyValues(hFeatures, sPath))
		{
			if (!KvGotoFirstSubKey(hFeatures))
			{
				LogError("Error reading donator features config file.");
				return;
			}
				
			do
			{
				KvGetSectionName(hFeatures, sBuffer, sizeof(sBuffer));
				
				new iTypeIndex = FindStringInArray(gH_Array_Types, sBuffer);
				if (iTypeIndex == -1)
				{
					new bHide = KvGetNum(hFeatures, "hide");
					
					iTypeIndex = PushArrayString(gH_Array_Types, sBuffer);
					#if defined DEBUG
					LogMessage("Added %s to menu array", sBuffer);
					#endif
					if (bHide)
					{
						SetArrayCell(gH_Array_Types, iTypeIndex, -2, sizeof(sBuffer)+1);
					}
					else
					{
						SetArrayCell(gH_Array_Types, iTypeIndex, -1, sizeof(sBuffer)+1);
					}
				}
				else
				{
					LogError("Duplicate entry found in config. Ignoring duplicate: %s", sBuffer);
				}
				
				if (KvGotoFirstSubKey(hFeatures))
				{
					do
					{				
						KvGetString(hFeatures, "Cost", sBuffer, sizeof(sBuffer));
						
						// If cost is empty here then it's a new sub-menu category
						if (!strlen(sBuffer))
						{
							KvGetSectionName(hFeatures, sBuffer, sizeof(sBuffer));
							
							new iSubTypeIndex = FindStringInArray(gH_Array_Types, sBuffer);
							if (iSubTypeIndex == -1)
							{
								iSubTypeIndex = PushArrayString(gH_Array_Types, sBuffer);
								SetArrayCell(gH_Array_Types, iSubTypeIndex, iTypeIndex, sizeof(sBuffer)+1);
							}
							
							#if defined DEBUG
							LogMessage("Added %s as sub-menu category with %d index", sBuffer, iSubTypeIndex);
							#endif
							
							if (KvGotoFirstSubKey(hFeatures))
							{
								do
								{
									KvGetSectionName(hFeatures, g_sFeatureName[g_iFeatures], sizeof(g_sFeatureName[]));
									SetTrieValue(gH_Trie_Features, g_sFeatureName[g_iFeatures], g_iFeatures);
									
									g_iFeatureCost[g_iFeatures] = KvGetNum(hFeatures, "Cost", 1000);
									
									g_iFeatureType[g_iFeatures] = iSubTypeIndex;
									
									g_iFeatures++;
									
									if (g_iFeatures >= MAX_FEATURES)
									{
										SetFailState("Too many features listed in configs/donator_features.cfg");
									}
									
								} while (KvGotoNextKey(hFeatures));	

								KvGoBack(hFeatures);
							}

						}
						else
						{
							KvGetSectionName(hFeatures, g_sFeatureName[g_iFeatures], sizeof(g_sFeatureName[]));
							SetTrieValue(gH_Trie_Features, g_sFeatureName[g_iFeatures], g_iFeatures);
							
							g_iFeatureCost[g_iFeatures] = KvGetNum(hFeatures, "Cost", 1000);
							
							g_iFeatureType[g_iFeatures] = iTypeIndex;
							
							g_iFeatures++;
							
							if (g_iFeatures >= MAX_FEATURES)
							{
								SetFailState("Too many features listed in configs/donator_features.cfg");
							}
						}
					
					} while (KvGotoNextKey(hFeatures));
					
					KvGoBack(hFeatures);
				}
				
			} while (KvGotoNextKey(hFeatures));
		}
		else
		{
			SetFailState("Bad command or file name: %s", sPath);
		}
		
	#if defined DEBUG
	LogMessage("Loaded %d features", g_iFeatures);
	#endif
	
	CloseHandle(hFeatures);
	
	}
}