#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>

#define SECONDS_IN_A_DAY 86400

public Plugin:myinfo = 
{
	name = "SQLite VIP API",
	author = "Eyal282",
	description = "A fully API integrated VIP system that works on SQLite",
	version = PLUGIN_VERSION,
	url = ""
}

#define SL_VIPLevel	0
#define SL_Name			1

#define FL_Name			0
#define FL_Cookie		1
#define FL_Max_Settings_Length 2

#define FL_MAX_LENGTH 3
#define SL_MAX_LENGTH 2

new Handle:dbLocal;

new Handle:fw_Auth;
new Handle:fw_dbConnected;
new Handle:fw_FeatureChanged;

new Handle:Array_Features[FL_MAX_LENGTH];
new Handle:Array_Settings[128][SL_MAX_LENGTH];

new LastFeatureSerial = -1; // Starts from 0, instantly incremented before being used ever.

new const String:PLUGIN_VERSION[] = "1.0";

new VIPLevel[MAXPLAYERS+1];

/**

*	@note			This forward is called when SQLite VIP API has connected to it's database.

*/
forward SQLiteVIPAPI_OnDatabaseConnected();

/**

* @param client		Client index that was authenticated.
* @param VIPLevel	VIP Level of the client, or 0 if the player is not VIP.
 
* @note				This forward is called for non-vip players as well as VIPs.
* @note				With the proper cvars, this isn't guaranteed to be called once, given the VIP Level of the VIP has decreased due to expiration of a better level / all of the levels.
* @noreturn		
*/

forward SQLiteVIPAPI_OnClientAuthorized(client, &VIPLevel);

/**

* @param client			Client index that changed his preference.
* @param FeatureSerial	Feature serial whose setting was changed.
* @param SettingValue	The new setting of the feature the client has set.
 
* @note					This forward is called whenever a client changes his feature preference.
* @note					This can be easily spammed by a client, and therefore should be noted.
* @noreturn		
*/

forward SQLiteVIPAPI_OnClientFeatureChanged(client, FeatureSerial, SettingValue);
/**

* @return			true if SQLite VIP API has connected to the database already, false otherwise.

*/

native SQLiteVIPAPI_IsDatabaseConnected();
/**

* @param client		Client index to check.
 
* @note				This forward is called for non-vip players as well as VIPs.
* @note				With the proper cvars, this isn't guaranteed to be called once, given the VIP Level of the VIP has decreased due to expiration of a better level / all of the levels.

* @return			VIP Level of the client, or 0 if the client is not a VIP. returns -1 if client was yet to be authenticated. If an error is thrown, returns -2 instead.

* @error			Client index is not in-game.
*/

native SQLiteVIPAPI_GetClientVIPLevel(client);

/**
* @param FeatureName	The name of the feature to be displayed in !settings.
* @param VIPLevelList	An arrayList containing each setting's VIP Level requirement
* @param NameList		An arrayList containing each setting's Name
* @param AlreadyExisted	Optional param to determine if the feature's name has already existed and therefore no feature was added. 

* @note					Only higher settings should be allowed to have higher VIP Levels than their lower ones.
* @note					You can execute this on "OnAllPluginsLoaded" even if the database is broken it'll still cache it.

* @return				Feature serial ID on success, 
* @error				List of setting variations exceed 25 ( it's too much anyways  )
*/

native bool:SQLiteVIPAPI_AddFeature(const String:FeatureName[64], Handle:VIPLevelList, Handle:NameList, &bool:AlreadyExisted=false);

/**

* @param client			Client index to check.
* @param FeatureSerial	Feature serial whose setting to find.

* @note 				Reduces to highest allowed value for the client if he lost a VIP status.
* @note					Returns -1 if the feature is entirely out of the client's league VIP wise. If an error is thrown, returns -2 instead.

* @return				Client's VIP setting for the feature given by the serial.

* @error				Client index is not in-game.

*/

native SQLiteVIPAPI_GetClientVIPFeature(client, FeatureSerial);

public APLRes:AskPluginLoad2(Handle:myself, bool:bLate, String:error[], err_max)
{
	CreateNative("SQLiteVIPAPI_IsDatabaseConnected", Native_IsDatabaseConnected);
	CreateNative("SQLiteVIPAPI_GetClientVIPLevel", Native_GetClientVIPLevel);
	CreateNative("SQLiteVIPAPI_AddFeature", Native_AddFeature);
	CreateNative("SQLiteVIPAPI_GetClientVIPFeature", Native_GetClientVIPFeature);
	
	RegPluginLibrary("SQLiteVIP");
}

public Native_IsDatabaseConnected(Handle:plugin, numParams)
{
	return dbLocal != INVALID_HANDLE;
}

public Native_GetClientVIPLevel(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if(!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %i is not in-game!", client);
		
		return -2;
	}
	
	return VIPLevel[client];
}

public Native_AddFeature(Handle:plugin, numParams)
{
	new String:FeatureName[64];
	GetNativeString(1, FeatureName, sizeof(FeatureName));
	
	new Handle:VIPLevelList = GetNativeCell(2);
	new Handle:NameList = GetNativeCell(3);
	
	new cell;
	if((cell = FindStringInArray(Array_Features[FL_Name], FeatureName)) != -1)
	{
		SetNativeCellRef(4, true);
		return cell;
	}
	
	if(GetArraySize(VIPLevelList) != GetArraySize(NameList))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Array sizes of VIPLevelList and NameList are not equal.");
		
		return -2;
	}
	
	LastFeatureSerial++;
	
	new String:CookieName[32];
	
	Format(CookieName, sizeof(CookieName), "SQLiteVIP_Feat_%s", FeatureName);
	
	new Handle:Cookie = RegClientCookie(CookieName, CookieName, CookieAccess_Protected);
	
	new SL_Size = GetArraySize(VIPLevelList);
	
	PushArrayString(Array_Features[FL_Name], FeatureName);	
	PushArrayCell(Array_Features[FL_Cookie], Cookie);	
	PushArrayCell(Array_Features[FL_Max_Settings_Length], SL_Size);
	
	Array_Settings[LastFeatureSerial][SL_VIPLevel] = CreateArray(1);
	Array_Settings[LastFeatureSerial][SL_Name] = CreateArray(64);
	
	new String:Name[64];
	for(new i=0;i < SL_Size;i++)
	{
		PushArrayCell(Array_Settings[LastFeatureSerial][SL_VIPLevel], GetArrayCell(VIPLevelList, i));
		GetArrayString(NameList, i, Name, sizeof(Name));
		
		PushArrayString(Array_Settings[LastFeatureSerial][SL_Name], Name);
	}
	
	SetNativeCellRef(4, false);
	
	return LastFeatureSerial;
}

public Native_GetClientVIPFeature(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if(!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %i is not in-game!", client);
		
		return -2;
	}
	
	new FeatureSerial = GetNativeCell(2);
	
	return GetClientVIPFeature(client, FeatureSerial);
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_setvip", Command_SetVIP, ADMFLAG_ROOT, "sm_setvip <#userid|name> <vip level> <days|0=permanent>");
	RegAdminCmd("sm_unsetvip", Command_UnsetVIP, ADMFLAG_ROOT, "sm_unsetvip <#userid|name>");
	RegConsoleCmd("sm_vip", Command_Test); 
	
	SetCookieMenuItem(VIPSystemCookieMenu_Handler, 0, "VIP System");
}

public OnAllPluginsLoaded()
{
	fw_Auth = CreateGlobalForward("SQLiteVIPAPI_OnClientAuthorized", ET_Ignore, Param_Cell, Param_CellByRef);
	fw_dbConnected = CreateGlobalForward("SQLiteVIPAPI_OnDatabaseConnected", ET_Ignore);
	fw_FeatureChanged = CreateGlobalForward("SQLiteVIPAPI_OnClientFeatureChanged", ET_Ignore, Param_Cell, Param_Cell);
	
	ConnectToDatabase();
}


public ConnectToDatabase()
{		
	if(dbLocal != INVALID_HANDLE)
		return;
		
	new String:Error[256];
	if((dbLocal = SQLite_UseDatabase("sqlite-vip", Error, sizeof(Error))) == INVALID_HANDLE)
		SetFailState("Could not connect to the database \"sqlite-vip\" at the following error:\n%s", Error);
	
	else
	{ 
		SQL_TQuery(dbLocal, SQLCB_Error, "CREATE TABLE IF NOT EXISTS SQLiteVIP_players (AuthId VARCHAR(35), PlayerName VARCHAR(64) NOT NULL, VIPLevel INT(11) NOT NULL, TimestampGiven INT(11) NOT NULL, TimestampExpire INT(11) NOT NULL, UNIQUE(AuthId, VIPLevel))", _, DBPrio_High); 

		new String:sQuery[256];
		
		Format(sQuery, sizeof(sQuery), "DELETE FROM SQLiteVIP_players WHERE TimestampExpire > TimestampGiven AND TimestampExpire < %i", GetTime());
		SQL_TQuery(dbLocal, SQLCB_Error, sQuery, _, DBPrio_High);
		
		Array_Features[FL_Name] = CreateArray(64);
		Array_Features[FL_Cookie] = CreateArray(1);
		Array_Features[FL_Max_Settings_Length] = CreateArray(1);
		
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
			
			else if(!IsClientAuthorized(i))
				continue;
			
			OnClientPostAdminCheck(i);
		}
		
		Call_StartForward(fw_dbConnected);
		
		Call_Finish();
	}
}

public SQLCB_Error(Handle:db, Handle:hndl, const String:sError[], data)
{
	if(hndl == null)
		ThrowError(sError);
}

public OnClientConnected(client)
{
	VIPLevel[client] = -1;
}
public OnClientPostAdminCheck(client)
{		
	if(IsFakeClient(client))
		return;

	new String:AuthId[35];
	
	if(!GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId)))
		CreateTimer(5.0, Timer_Auth, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
	else
		FindClientVIPStatus(client);
}

public OnClientDisconnect(client)
{
	new String:AuthId[35];
	if(!GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId)))
		return;
	
	new String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "UPDATE SQLiteVIP_players SET PlayerName = '%N' WHERE AuthId = '%s'", client, AuthId);
	
	SQL_TQuery(dbLocal, SQLCB_Error, sQuery, _, DBPrio_Normal);
}

public Action:Timer_Auth(Handle:timer, UserId)
{
	new client = GetClientOfUserId(UserId);
	
	new String:AuthId[35]
	
	if(!GetClientAuthId(client, AuthId_Engine, AuthId, sizeof AuthId))
		return Plugin_Continue;
		
	else
	{
		FindClientVIPStatus(client);
		
		return Plugin_Stop;
	} 
}

FindClientVIPStatus(client)
{		
	new String:AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	new String:sQuery[256];
	
	Format(sQuery, sizeof(sQuery), "SELECT * FROM SQLiteVIP_players WHERE AuthId = '%s' ORDER BY VIPLevel DESC", AuthId);
	
	SQL_TQuery(dbLocal, SQLCB_FindClientVIPStatus, sQuery, GetClientUserId(client));
}


public SQLCB_FindClientVIPStatus(Handle:db, Handle:hndl, const String:sError[], data)
{
	if(hndl == null)
		ThrowError(sError);
	
	new client = GetClientOfUserId(data);

	new bool:ShouldAnnounce = false;
	
	if(client == 0)
		return;
	
	else if(SQL_GetRowCount(hndl) == 0)
	{
		ShouldAnnounce = VIPLevel[client] != 0; // If VIPLevel[client] != newVIPLevel of client.
		
		VIPLevel[client] = 0;
		
		if(ShouldAnnounce)
		{
			Call_StartForward(fw_Auth);
			
			Call_PushCell(client);
			Call_PushCellRef(VIPLevel[client]);
		
			Call_Finish();
		}
		
		return;
	}
	
	new bool:Purge = false;
	new UnixTime = GetTime();
	
	SQL_FetchRow(hndl);
	
	new Level = SQL_FetchInt(hndl, 2);
	new TimestampGiven = SQL_FetchInt(hndl, 3);
	new TimestampExpire = SQL_FetchInt(hndl, 4);
	
	if(TimestampExpire > TimestampGiven && TimestampExpire < UnixTime)
		Purge = true;
		
	if(Purge)
	{
		new String:sQuery[256];
			
		Format(sQuery, sizeof(sQuery), "DELETE FROM SQLiteVIP_players WHERE TimestampExpire > TimestampGiven AND TimestampExpire < %i", UnixTime);
		SQL_TQuery(dbLocal, SQLCB_Error, sQuery, _, DBPrio_High);
		
		FindClientVIPStatus(client);
		
		return;
	}
	
	ShouldAnnounce = VIPLevel[client] != Level;
	
	VIPLevel[client] = Level;
	
	if(ShouldAnnounce)
	{
		Call_StartForward(fw_Auth);
		
		Call_PushCell(client);
		Call_PushCell(VIPLevel[client]);
		Call_Finish();
	}
}

public Action:Command_SetVIP(client, args)
{
	if(args < 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setvip <#userid|name> <vip level> <days|0=permanent>");
		return Plugin_Handled;
	}	
	
	new String:TargetArg[64], String:sVIPLevel[11], String:VIPDuration[11], UnixTime = GetTime();
	
	new target_list[1], String:target_name[MAX_TARGET_LENGTH];
	new TargetClient, ReplyReason, bool:tn_is_ml;
	
	GetCmdArg(1, TargetArg, sizeof(TargetArg));
	GetCmdArg(2, sVIPLevel, sizeof(sVIPLevel));
	GetCmdArg(3, VIPDuration, sizeof(VIPDuration));
	
	if ((ReplyReason = ProcessTargetString(
		TargetArg,
		client, 
		target_list, 
		1, 
		COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, ReplyReason);
		return Plugin_Handled;
	}
	
	new String:AuthId[35];
	
	TargetClient = target_list[0];
	
	new Level = StringToInt(sVIPLevel);
	
	if(!GetClientAuthId(TargetClient, AuthId_Engine, AuthId, sizeof(AuthId)))
	{
		ReplyToCommand(client, "[SM] Error: Couldn't authenticate %N's Steam ID.", TargetClient);
		return Plugin_Handled;
	}
	
	else if(VIPLevel[client] >= Level)
	{
		ReplyToCommand(client, "[SM] Error: %N is already at a higher or equal VIP level.", TargetClient);
		return Plugin_Handled
	}
	
	new bool:AnnounceStack = VIPLevel[client] > 0;
	new Duration = StringToInt(VIPDuration);
	
	new String:sQuery[1024];
	Format(sQuery, sizeof(sQuery), "INSERT OR REPLACE INTO SQLiteVIP_players (AuthId, PlayerName, VIPLevel, TimestampGiven, TimestampExpire) VALUES ('%s', '%N', '%i', '%i', '%i')", AuthId, TargetClient, Level, UnixTime, UnixTime + (Duration * SECONDS_IN_A_DAY));
	
	SQL_TQuery(dbLocal, SQLCB_Error, sQuery);
	
	FindClientVIPStatus(TargetClient);
	
	ReplyToCommand(client, "Successfully set VIP level %i on %N for %i days.", Level, TargetClient, Duration);
	
	if(AnnounceStack)
		ReplyToCommand(client, "Note: Adding a higher VIP level doesn't delete the previous VIP level to be given after this level expires.");
	
	return Plugin_Handled;
	
}

public Action:Command_UnsetVIP(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unsetvip <#userid|name>");
		return Plugin_Handled;
	}	
	
	new String:TargetArg[64];
	
	new target_list[1], String:target_name[MAX_TARGET_LENGTH];
	new TargetClient, ReplyReason, bool:tn_is_ml;
	
	GetCmdArg(1, TargetArg, sizeof(TargetArg));

	if ((ReplyReason = ProcessTargetString(
		TargetArg,
		client, 
		target_list, 
		1, 
		COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, ReplyReason);
		return Plugin_Handled;
	}
	
	new String:AuthId[35];
	
	TargetClient = target_list[0];
	
	if(!GetClientAuthId(TargetClient, AuthId_Engine, AuthId, sizeof(AuthId)))
	{
		ReplyToCommand(client, "[SM] Error: Couldn't authenticate %N's Steam ID.", TargetClient);
		return Plugin_Handled;
	}
	
	else if(VIPLevel[client] == 0)
	{
		ReplyToCommand(client, "[SM] Error: %N is not a VIP.", TargetClient);
		
		return Plugin_Handled;
	}
	
	new String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "DELETE FROM SQLiteVIP_players WHERE AuthId = '%s'", AuthId);
	
	SQL_TQuery(dbLocal, SQLCB_Error, sQuery);
	
	FindClientVIPStatus(TargetClient);
	
	ReplyToCommand(client, "Successfully unset VIP from %N", TargetClient);
	
	return Plugin_Handled;
	
}

public Action:Command_Test(client, args)
{
	PrintToChat(client, "You are %s VIP. VIP Level: %i", VIPLevel[client] > 0 ? "" : "not", VIPLevel[client]);
	
	return Plugin_Handled
}

public VIPSystemCookieMenu_Handler(client, CookieMenuAction:action, info, String:buffer[], maxlen)
{
	if(VIPLevel[client] <= 0)
	{
		ShowCookieMenu(client);
		PrintToChat(client, "[SM] Error: You are not VIP!");
		return;
	}
	
	ShowVIPMenu(client);
} 
public ShowVIPMenu(client)
{
	new Handle:hMenu = CreateMenu(VIPMenu_Handler);

	new String:TempFormat[256], String:FeatureName[64], String:SettingName[64];
	
	if(LastFeatureSerial == -1)
		return;
		
	for(new i=0;i < LastFeatureSerial+1;i++)
	{
		new Feature = GetClientVIPFeature(client, i);
		
		if(Feature == -1)
			continue;
			
		GetArrayString(Array_Features[FL_Name], i, FeatureName, sizeof(FeatureName));
		GetArrayString(Array_Settings[i][SL_Name], Feature, SettingName, sizeof(SettingName));
		Format(TempFormat, sizeof(TempFormat), "%s - [%s]", FeatureName, SettingName);
		AddMenuItem(hMenu, "", TempFormat);
	}
	
	SetMenuExitBackButton(hMenu, true);
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 30);
}


public VIPMenu_Handler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	else if(item == MenuCancel_ExitBack)
	{
		ShowCookieMenu(client);
	}
	else if(action == MenuAction_Select)
	{
		IncrementVIPFeature(client, item);
		
		Call_StartForward(fw_FeatureChanged);
		
		Call_PushCell(client);
		Call_PushCell(item);
		Call_PushCell(GetClientVIPFeature(client, item));
		
		Call_Finish();
		
		ShowVIPMenu(client);
	}
	return 0;
}
// reduces to highest allowed value for the client if he lost a VIP status.

// returns -1 if the feature is entirely out of the client's league VIP wise

stock GetClientVIPFeature(client, FeatureSerial)
{
	if(VIPLevel[client] < 0)
		return -1;
		
	new Handle:Cookie = GetArrayCell(Array_Features[FL_Cookie], FeatureSerial);
	new String:CookieValue[11];
	GetClientCookie(client, Cookie, CookieValue, sizeof(CookieValue));
	
	new SettingSerial = StringToInt(CookieValue);
	
	if(CookieValue[0] == EOS)
		SettingSerial = GetArrayCell(Array_Features[FL_Max_Settings_Length], FeatureSerial)-1;
	
	while(SettingSerial >= 0 && VIPLevel[client] < GetArrayCell(Array_Settings[FeatureSerial][SL_VIPLevel], SettingSerial))
		SettingSerial--;
	
	return SettingSerial;
}

stock IncrementVIPFeature(client, FeatureSerial)
{
	new Handle:Cookie = GetArrayCell(Array_Features[FL_Cookie], FeatureSerial);
	new String:CookieValue[11];
	
	new SettingSerial = GetClientVIPFeature(client, FeatureSerial);
	
	SettingSerial++;
	
	if(SettingSerial >= GetArrayCell(Array_Features[FL_Max_Settings_Length], FeatureSerial) || VIPLevel[client] < GetArrayCell(Array_Settings[FeatureSerial][SL_VIPLevel], SettingSerial))
		SettingSerial = 0;
		
	IntToString(SettingSerial, CookieValue, sizeof(CookieValue));
	
	SetClientCookie(client, Cookie, CookieValue);
}