/*
Databases.cfg:
"naminator"
{
	"driver"			"sqlite"
	"database"			"sm_naminator"
}

More Colors:
https://bitbucket.org/Doctor_McKay/public-plugins/src/morecolors-dev/scripting/include/morecolors.inc
*/

#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define PLUGIN_VERSION "1.0.0"

// SQL Updating System
//{
//Total number of updates the plugin is considering.
//Increase by one for each entry added to g_sUpdatePaths.
#define UPDATE_TOTAL 0

//Add updates to g_iUpdateFlags in factors of 2^x. 1, 2, 4, 8, 16, etc
//Increase by one factor each entry added to g_sUpdatePaths.
new g_iUpdateFlags[] = { 1 };
new String:g_sUpdatePaths[][] = { "configs/naminator/setup.txt" };
//}

// Table
//{
//Handle that saves the active connection to database.
new Handle:g_hActiveDatabase = INVALID_HANDLE;

//Declaration of the entry within databases.cfg to connect.
new const String:g_sTable[] = "naminator";
//}

// Assorted Defines
//{
#define MODE_TEMP -1
#define MODE_DISABLED 0
#define MODE_ENABLED 1

#define ACTION_TEMP 0
#define ACTION_PERM 1
#define ACTION_RESET 2
//}

// Assorted Declarations
//{
new Handle:g_hConsoleName = INVALID_HANDLE;
new Handle:g_hHideName = INVALID_HANDLE;
new Handle:g_hTemporary = INVALID_HANDLE;
new Handle:g_hPermanent = INVALID_HANDLE;
new Handle:g_hReset = INVALID_HANDLE;

new bool:g_bLateLoad, bool:g_bLateQuery, bool:g_bHideName;
new g_iUpdate, g_ModVersion;
new UserMsg:g_umSayText2;
new String:g_sConsoleName[32], String:g_sPermanent[16], String:g_sTemporary[16], String:g_sReset[16];
//}

// Player Declarations
//{
new g_iPrefix[MAXPLAYERS + 1];
new g_iSuffix[MAXPLAYERS + 1];
new g_iPermName[MAXPLAYERS + 1];

new bool:g_bPrefix[MAXPLAYERS + 1];
new bool:g_bSuffix[MAXPLAYERS + 1];
new bool:g_bPermName[MAXPLAYERS + 1];

new String:g_sPrefix[MAXPLAYERS + 1][20];
new String:g_sSuffix[MAXPLAYERS + 1][20];
new String:g_sPermName[MAXPLAYERS + 1][32];

new bool:g_bLoaded[MAXPLAYERS + 1];
new String:g_sSteam[MAXPLAYERS + 1][24];
new String:g_sOriginal[MAXPLAYERS + 1][32];
//}

public Plugin:myinfo =
{
	name = "Naminator",
	author = "Twisted|Panda",
	description = "Provides custom name, prefix, and suffix functionality.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmodders.com"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = g_bLateQuery = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	if(!SQL_CheckConfig(g_sTable))
		SetFailState("You have not added the naminator entry to your databases.cfg!");
	
	LoadTranslations("common.phrases");
	LoadTranslations("sm_naminator.phrases");
	CreateConVar("sm_naminator_version", PLUGIN_VERSION, "Naminator: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD); 

	g_hConsoleName = CreateConVar("sm_naminator_console_name", "{white}Naminator: {olive}", "The prefix (name) that is applied to say2 actions.");
	HookConVarChange(g_hConsoleName, OnSettingsChange);
	GetConVarString(g_hConsoleName, g_sConsoleName, sizeof(g_sConsoleName));
	
	g_hHideName = CreateConVar("sm_naminator_hide_name", "1", "If enabled, name changes pertaining to sm_name will be hidden.");
	HookConVarChange(g_hHideName, OnSettingsChange);
	g_bHideName = GetConVarBool(g_hHideName);
	
	g_hTemporary = CreateConVar("sm_naminator_temporary_action", "temp", "The action phrase for sm_suffix,sm_prefix,sm_name that defines a temporary change, clearing on disconnect.");
	HookConVarChange(g_hTemporary, OnSettingsChange);
	GetConVarString(g_hTemporary, g_sTemporary, sizeof(g_sTemporary));
	
	g_hPermanent = CreateConVar("sm_naminator_permanent_action", "perm", "The action phrase for sm_suffix,sm_prefix,sm_name that defines a permanent change, saving the information on disconnect.");
	HookConVarChange(g_hPermanent, OnSettingsChange);
	GetConVarString(g_hPermanent, g_sPermanent, sizeof(g_sPermanent));
	
	g_hReset = CreateConVar("sm_naminator_reset_action", "reset", "The action phrase for sm_suffix,sm_prefix,sm_name that defines a reset action, clearing the saved settings.");
	HookConVarChange(g_hReset, OnSettingsChange);
	GetConVarString(g_hReset, g_sReset, sizeof(g_sReset));

	AutoExecConfig(true, "sm_naminator");
	
	RegServerCmd("say2", Command_Say2, "");
	RegAdminCmd("sm_suffix", Command_Suffix, ADMFLAG_GENERIC, "Naminator: Sets the suffix of a player - Usage: sm_suffix <target> \"action\" \"suffix\"");
	RegAdminCmd("sm_prefix", Command_Prefix, ADMFLAG_GENERIC, "Naminator: Sets the prefix of a player - Usage: sm_prefix <target> \"action\" \"prefix\"");
	RegAdminCmd("sm_name", Command_Name, ADMFLAG_GENERIC, "Naminator: Sets the name of a player - Usage: sm_name <target> \"action\" \"newname\"");

	g_umSayText2 = GetUserMessageId("SayText2");
	HookUserMessage(g_umSayText2, UserMessageHook, true);
	g_ModVersion = GuessSDKVersion();
	
	HookEvent("player_changename", Event_OnNameChange);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hConsoleName)
		strcopy(g_sConsoleName, sizeof(g_sConsoleName), newvalue);
	else if(cvar == g_hTemporary)
		strcopy(g_sTemporary, sizeof(g_sTemporary), newvalue);
	else if(cvar == g_hPermanent)
		strcopy(g_sPermanent, sizeof(g_sPermanent), newvalue);
	else if(cvar == g_hReset)
		strcopy(g_sReset, sizeof(g_sReset), newvalue);
	else if(cvar == g_hHideName)
		g_bHideName = bool:StringToInt(newvalue);
}

public Action:Event_OnNameChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client <= 0 || !IsClientInGame(client))
		return Plugin_Continue;

	new String:sName[64], String:sOther[64];
	GetEventString(event, "newname", sName, sizeof(sName));
	if(GetNaminatorName(client, sOther, sizeof(sOther)))
	{
		if(!StrEqual(sName, sOther))
		{
			if (g_ModVersion > SOURCE_SDK_EPISODE1)
				SetClientInfo(client, "name", sOther);
			else
				ClientCommand(client, "name %s", sOther);
				
			dontBroadcast = true;
			SetEventBroadcast(event, true);
		}
	}

	return Plugin_Continue;
}

bool:GetNaminatorName(client, String:sBuffer[], iSize)
{
	if(g_iPermName[client])
	{
		Format(sBuffer, iSize, "%s", g_sPermName[client]);
		if(g_iPrefix[client])
			Format(sBuffer, iSize, "%s%s",  g_sPrefix[client], sBuffer);
		if(g_iSuffix[client])
			Format(sBuffer, iSize, "%s%s",  sBuffer, g_sSuffix[client]);
			
		return true;
	}
	else if(g_iPrefix[client])
	{
		Format(sBuffer, iSize, "%s%s", g_sPrefix[client], g_sOriginal[client]);
		if(g_iSuffix[client])
			Format(sBuffer, iSize, "%s%s",  sBuffer, g_sSuffix[client]);
			
		return true;
	}
	else if(g_iSuffix[client])
	{
		Format(sBuffer, iSize, "%s%s", g_sOriginal[client], g_sSuffix[client]);
			
		return true;
	}
	
	return false;
}

SetClientName(client)
{
	decl String:sName[64];
	if(GetNaminatorName(client, sName, sizeof(sName)))
	{
		if (g_ModVersion > SOURCE_SDK_EPISODE1)
			SetClientInfo(client, "name", sName);
		else
			ClientCommand(client, "name %s", sName);
	}
}

public Action:UserMessageHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:sUserMess[96], String:sName[64];
	BfReadString(bf, sUserMess, sizeof(sUserMess));
	BfReadString(bf, sUserMess, sizeof(sUserMess));
	if (g_bHideName && StrContains(sUserMess, "Name_Change", false) != -1)
	{
		BfReadString(bf, sUserMess, sizeof(sUserMess));
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				GetClientName(i, sName, sizeof(sName));
				if(StrEqual(sUserMess, sName) && (g_iPrefix[i] || g_iSuffix[i] || g_iPermName[i]))
					return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Command_Say2(args)
{
	decl String:sBuffer[192];
	GetCmdArgString(sBuffer, 192);
	StripQuotes(sBuffer);
	TrimString(sBuffer);

	if(!StrEqual(sBuffer, ""))
		CPrintToChatAll("%s%s", g_sConsoleName, sBuffer);

	return Plugin_Handled;
}

public OnConfigsExecuted()
{
	if(g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				GetClientName(i, g_sOriginal[i], sizeof(g_sOriginal[]));
				GetClientAuthString(i, g_sSteam[i], sizeof(g_sSteam[]));
			}
		}
				

		g_bLateLoad = false;
	}

	if(g_hActiveDatabase == INVALID_HANDLE)
		SQL_TConnect(SQL_Connect_Database, g_sTable); 
}

public SQL_Connect_Database(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ErrorCheck(owner, error); 
	ErrorCheck(hndl, error); 

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/naminator");
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);

	g_iUpdate = 0;
	for(new i = 0; i < UPDATE_TOTAL; i++)
	{
		BuildPath(Path_SM, sPath, sizeof(sPath), g_sUpdatePaths[i]);
		if(!FileExists(sPath))
		{
			new Handle:hTemp = OpenFile(sPath, "w");
			CloseHandle(hTemp);
			
			g_iUpdate += g_iUpdateFlags[i];
		}
	}

	g_hActiveDatabase = hndl;

	decl String:sQuery[192]; 
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS %s (steamid VARCHAR(22) PRIMARY KEY, prefix_state INT, prefix VARCHAR(64), suffix_state INT, suffix VARCHAR(64), pname_state INT, pname VARCHAR(64))", g_sTable);	
	SQL_TQuery(g_hActiveDatabase, CallBack_Creation, sQuery, _);
}

public CallBack_Creation(Handle:owner, Handle:hndl, const String:error[], any:ref)
{
	ErrorCheck(owner, error, "Creation"); 

	if(g_iUpdate)
	{
		if(g_iUpdate & 1)
		{
			//Not Needed ATM
		}
	}
	
	if(g_bLateQuery)
	{
		decl String:sQuery[128];
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !g_bLoaded[i])
			{
				Format(sQuery, sizeof(sQuery), "SELECT * FROM %s WHERE steamid = '%s'", g_sTable, g_sSteam[i]); 
				SQL_TQuery(g_hActiveDatabase, CallBack_ClientConnect, sQuery, GetClientUserId(i)); 
			}
		}

		g_bLateQuery = false;
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_hActiveDatabase != INVALID_HANDLE)
	{
		GetClientAuthString(client, g_sSteam[client], sizeof(g_sSteam[]));
		if(!g_bLoaded[client])
		{
			decl String:sQuery[128]; 
			Format(sQuery, sizeof(sQuery), "SELECT * FROM %s WHERE steamid = '%s'", g_sTable, g_sSteam[client]); 
			SQL_TQuery(g_hActiveDatabase, CallBack_ClientConnect, sQuery, GetClientUserId(client));
		}
	}
}

public OnClientConnected(client)
{
	g_iPrefix[client] = g_iSuffix[client] = g_iPermName[client] = MODE_DISABLED;
}

public OnClientDisconnect(client)
{
	if(g_bLoaded[client])
	{
		decl String:sQuery[128];
		if(g_bPrefix[client])
		{
			decl String:sBuffer[65];
			SQL_EscapeString(g_hActiveDatabase, g_sPrefix[client], sBuffer, sizeof(sBuffer));
			
			Format(sQuery, sizeof(sQuery), "UPDATE %s SET prefix_state = %d, prefix = '%s' WHERE steamid = '%s'", g_sTable, g_iPrefix[client], sBuffer, g_sSteam[client]); 
			SQL_TQuery(g_hActiveDatabase, CallBack_General, sQuery);
		
		}
		
		if(g_bSuffix[client])
		{
			decl String:sBuffer[65];
			SQL_EscapeString(g_hActiveDatabase, g_sSuffix[client], sBuffer, sizeof(sBuffer));
			
			Format(sQuery, sizeof(sQuery), "UPDATE %s SET suffix_state = %d, suffix = '%s' WHERE steamid = '%s'", g_sTable, g_iSuffix[client], sBuffer, g_sSteam[client]); 
			SQL_TQuery(g_hActiveDatabase, CallBack_General, sQuery);
		
		}
	
		if(g_bPermName[client])
		{
			decl String:sBuffer[65];
			SQL_EscapeString(g_hActiveDatabase, g_sPermName[client], sBuffer, sizeof(sBuffer));
			
			Format(sQuery, sizeof(sQuery), "UPDATE %s SET pname_state = %d, pname = '%s' WHERE steamid = '%s'", g_sTable, g_iPermName[client], sBuffer, g_sSteam[client]); 
			SQL_TQuery(g_hActiveDatabase, CallBack_General, sQuery);
		
		}	
		
		g_bPrefix[client] = g_bSuffix[client] = g_bPermName[client] = g_bLoaded[client] = false;
	}
}

public CallBack_ClientConnect(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	ErrorCheck(owner, error, "ClientConnect"); 
	
	new client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;
	
	if(!SQL_GetRowCount(hndl))
	{
		strcopy(g_sPrefix[client], sizeof(g_sPrefix[]), "");
		strcopy(g_sSuffix[client], sizeof(g_sSuffix[]), "");
		strcopy(g_sPermName[client], sizeof(g_sPermName[]), "");
		
		decl String:sQuery[256];
		Format(sQuery, sizeof(sQuery), "INSERT INTO %s (steamid, prefix_state, prefix, suffix_state, suffix, pname_state, pname) VALUES ('%s', %d, '%s', %d, '%s', %d, '%s')", g_sTable, g_sSteam[client], MODE_DISABLED, "", MODE_DISABLED, "", MODE_DISABLED, "");
		SQL_TQuery(g_hActiveDatabase, CallBack_General, sQuery); 
	}
	else if(SQL_FetchRow(hndl))
	{
		g_iPrefix[client] = SQL_FetchInt(hndl, 1);
		if(g_iPrefix[client] == MODE_ENABLED)
			SQL_FetchString(hndl, 2, g_sPrefix[client], sizeof(g_sPrefix[]));
			
		g_iSuffix[client] = SQL_FetchInt(hndl, 3);
		if(g_iSuffix[client] == MODE_ENABLED)
			SQL_FetchString(hndl, 4, g_sSuffix[client], sizeof(g_sSuffix[]));
			
		g_iPermName[client] = SQL_FetchInt(hndl, 5);
		if(g_iPermName[client] == MODE_ENABLED)
			SQL_FetchString(hndl, 6, g_sPermName[client], sizeof(g_sPermName[]));
	}

	GetClientName(client, g_sOriginal[client], sizeof(g_sOriginal[]));
	SetClientName(client);
	g_bLoaded[client] = true;	
}

public CallBack_General(Handle:owner, Handle:hndl, const String:error[], any:ref)
{
	ErrorCheck(owner, error, "General"); 
}

ErrorCheck(Handle:owner, const String:error[], const String:callback[] = "")
{
	if(owner == INVALID_HANDLE)
		SetFailState("[SM] FATAL SQL ERROR - %s, %s", callback, error);
	else if(!StrEqual(error, ""))
		LogError("[SM] SQL ERROR - %s, %s", callback, error);
}

public Action:Command_Suffix(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "%t", "Phrase_Suffix_Command_Arguments");
		return Plugin_Handled;
	}
	
	decl String:sAction[64], String:sSuffix[64], String:sStuff[65], String:sBuffer[256];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	StripQuotes(sBuffer);
	new iAction = -1, iLength = BreakString(sBuffer, sStuff, sizeof(sStuff));
	if(iLength == -1)
	{
		ReplyToCommand(client, "%t", "Phrase_Suffix_Command_Arguments");
		return Plugin_Handled;
	}
	iLength += BreakString(sBuffer[iLength], sAction, sizeof(sAction));
	if(StrEqual(sAction, g_sTemporary, false))
		iAction = ACTION_TEMP;
	else if(StrEqual(sAction, g_sPermanent, false))
		iAction = ACTION_PERM;
	else if(StrEqual(sAction, g_sReset, false))
		iAction = ACTION_RESET;

	if(iAction != -1)
	{
		decl String:sTargets[MAX_TARGET_LENGTH];
		decl iTargets[MAXPLAYERS], iCount, bool:bWtf;
		if ((iCount = ProcessTargetString(sStuff, client, iTargets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, sTargets, sizeof(sTargets), bWtf)) > 0)
		{
			for(new i = 0; i < iCount; i++)
			{
				if(!IsClientInGame(iTargets[i]))
					continue;

				switch(iAction)
				{
					case ACTION_TEMP:
					{
						Format(sSuffix, sizeof(sSuffix), sBuffer[iLength]);
						StripQuotes(sSuffix);
						
						g_iSuffix[iTargets[i]] = MODE_TEMP;
						g_bSuffix[iTargets[i]] = false;
						strcopy(g_sSuffix[iTargets[i]], sizeof(g_sSuffix[]), sSuffix);
						
						ShowActivity2(client, "[SM] ", "%t", "Command_Suffix_Temporary", iTargets[i], sSuffix);
						LogAction(client, iTargets[i], "%L set a temporary suffix of %s on %N", client, sSuffix, iTargets[i]);
						
						SetClientName(iTargets[i]);
					}
					case ACTION_PERM:
					{
						Format(sSuffix, sizeof(sSuffix), sBuffer[iLength]);
						StripQuotes(sSuffix);
						
						g_iSuffix[iTargets[i]] = MODE_ENABLED;
						g_bSuffix[iTargets[i]] = true;
						strcopy(g_sSuffix[iTargets[i]], sizeof(g_sSuffix[]), sSuffix);
						
						ShowActivity2(client, "[SM] ", "%t", "Command_Suffix_Permanent", iTargets[i], sSuffix);
						LogAction(client, iTargets[i], "%L set a permanent suffix of %s on %N", client, sSuffix, iTargets[i]);
						
						SetClientName(iTargets[i]);
					}
					case ACTION_RESET:
					{
						g_iSuffix[iTargets[i]] = MODE_DISABLED;
						g_bSuffix[iTargets[i]] = true;
						strcopy(g_sSuffix[iTargets[i]], sizeof(g_sSuffix[]), "");
						
						ShowActivity2(client, "[SM] ", "%t", "Command_Suffix_Reset", iTargets[i]);
						LogAction(client, iTargets[i], "%L reset the suffix of %s on %N", client, sSuffix, iTargets[i]);
						
						SetClientName(iTargets[i]);
					}
				}
			}
		}
		else
			ReplyToTargetError(client, iCount);
	}
	else
		ReplyToCommand(client, "%t", "Phrase_Command_Invalid_Action", g_sTemporary, g_sPermanent, g_sReset);
	
	return Plugin_Handled;
}

public Action:Command_Prefix(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "%t", "Phrase_Prefix_Command_Arguments");
		return Plugin_Handled;
	}
	
	decl String:sAction[64], String:sPrefix[64], String:sStuff[65], String:sBuffer[256];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	BreakString(sBuffer, sStuff, sizeof(sStuff));
	new iAction = -1, iLength = BreakString(sBuffer, sStuff, sizeof(sStuff));
	if(iLength == -1)
	{
		ReplyToCommand(client, "%t", "Phrase_Prefix_Command_Arguments");
		return Plugin_Handled;
	}
	iLength += BreakString(sBuffer[iLength], sAction, sizeof(sAction));
	if(StrEqual(sAction, g_sTemporary, false))
		iAction = ACTION_TEMP;
	else if(StrEqual(sAction, g_sPermanent, false))
		iAction = ACTION_PERM;
	else if(StrEqual(sAction, g_sReset, false))
		iAction = ACTION_RESET;

	if(iAction != -1)
	{
		decl String:sTargets[MAX_TARGET_LENGTH];
		decl iTargets[MAXPLAYERS], iCount, bool:bWtf;
		if ((iCount = ProcessTargetString(sStuff, client, iTargets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, sTargets, sizeof(sTargets), bWtf)) > 0)
		{
			for(new i = 0; i < iCount; i++)
			{
				if(!IsClientInGame(iTargets[i]))
					continue;

				switch(iAction)
				{
					case ACTION_TEMP:
					{
						Format(sPrefix, sizeof(sPrefix), sBuffer[iLength]);
						
						g_iPrefix[iTargets[i]] = MODE_TEMP;
						g_bPrefix[iTargets[i]] = false;
						strcopy(g_sPrefix[iTargets[i]], sizeof(g_sPrefix[]), sPrefix);
						
						ShowActivity2(client, "[SM] ", "%t", "Command_Prefix_Temporary", iTargets[i], sPrefix);
						LogAction(client, iTargets[i], "%L set a temporary prefix of %s on %N", client, sPrefix, iTargets[i]);
						
						SetClientName(iTargets[i]);
					}
					case ACTION_PERM:
					{
						Format(sPrefix, sizeof(sPrefix), sBuffer[iLength]);
						
						g_iPrefix[iTargets[i]] = MODE_ENABLED;
						g_bPrefix[iTargets[i]] = true;
						strcopy(g_sPrefix[iTargets[i]], sizeof(g_sPrefix[]), sPrefix);
						
						ShowActivity2(client, "[SM] ", "%t", "Command_Prefix_Permanent", iTargets[i], sPrefix);
						LogAction(client, iTargets[i], "%L set a permanent prefix of %s on %N", client, sPrefix, iTargets[i]);
						
						SetClientName(iTargets[i]);
					}
					case ACTION_RESET:
					{
						g_iPrefix[iTargets[i]] = MODE_DISABLED;
						g_bPrefix[iTargets[i]] = true;
						strcopy(g_sPrefix[iTargets[i]], sizeof(g_sPrefix[]), "");
						
						ShowActivity2(client, "[SM] ", "%t", "Command_Prefix_Reset", iTargets[i]);
						LogAction(client, iTargets[i], "%L reset the prefix of %s on %N", client, sPrefix, iTargets[i]);
						
						SetClientName(iTargets[i]);
					}
				}	
			}
		}
		else
			ReplyToTargetError(client, iCount);
	}
	else
		ReplyToCommand(client, "%t", "Phrase_Command_Invalid_Action", g_sTemporary, g_sPermanent, g_sReset);

	return Plugin_Handled;
}

public Action:Command_Name(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "%t", "Phrase_Name_Command_Arguments");
		return Plugin_Handled;
	}
	
	decl String:sAction[64], String:sName[64], String:sStuff[65], String:sBuffer[256];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	BreakString(sBuffer, sStuff, sizeof(sStuff));
	new iAction = -1, iLength = BreakString(sBuffer, sStuff, sizeof(sStuff));
	if(iLength == -1)
	{
		ReplyToCommand(client, "%t", "Phrase_Name_Command_Arguments");
		return Plugin_Handled;
	}
	iLength += BreakString(sBuffer[iLength], sAction, sizeof(sAction));
	if(StrEqual(sAction, g_sTemporary, false))
		iAction = ACTION_TEMP;
	else if(StrEqual(sAction, g_sPermanent, false))
		iAction = ACTION_PERM;
	else if(StrEqual(sAction, g_sReset, false))
		iAction = ACTION_RESET;

	if(iAction != -1)
	{
		decl String:sTargets[MAX_TARGET_LENGTH];
		decl iTargets[MAXPLAYERS], iCount, bool:bWtf;
		if ((iCount = ProcessTargetString(sStuff, client, iTargets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, sTargets, sizeof(sTargets), bWtf)) > 0)
		{
			for(new i = 0; i < iCount; i++)
			{
				if(!IsClientInGame(iTargets[i]))
					continue;

				switch(iAction)
				{
					case ACTION_TEMP:
					{
						Format(sName, sizeof(sName), sBuffer[iLength]);
						StripQuotes(sName);
						
						g_iPermName[iTargets[i]] = MODE_TEMP;
						g_bPermName[iTargets[i]] = false;
						strcopy(g_sPermName[iTargets[i]], sizeof(g_sPermName[]), sName);
						
						ShowActivity2(client, "[SM] ", "%t", "Command_Name_Temporary", iTargets[i], sName);
						LogAction(client, iTargets[i], "%L set a temporary name of %s on %N", client, sName, iTargets[i]);

						SetClientName(iTargets[i]);
					}
					case ACTION_PERM:
					{
						Format(sName, sizeof(sName), sBuffer[iLength]);
						StripQuotes(sName);
						
						g_iPermName[iTargets[i]] = MODE_ENABLED;
						g_bPermName[iTargets[i]] = true;
						strcopy(g_sPermName[iTargets[i]], sizeof(g_sPermName[]), sName);
						
						ShowActivity2(client, "[SM] ", "%t", "Command_Name_Permanent", iTargets[i], sName);
						LogAction(client, iTargets[i], "%L set a permanent name of %s on %N", client, sName, iTargets[i]);
						
						SetClientName(iTargets[i]);
					}
					case ACTION_RESET:
					{
						g_iPermName[iTargets[i]] = MODE_DISABLED;
						g_bPermName[iTargets[i]] = true;
						strcopy(g_sPermName[iTargets[i]], sizeof(g_sPermName[]), "");
						
						ShowActivity2(client, "[SM] ", "%t", "Command_Name_Reset", iTargets[i]);
						LogAction(client, iTargets[i], "%L reset the name of %s on %N", client, sName, iTargets[i]);
						
						SetClientName(iTargets[i]);
					}
				}
			}
		}
		else
			ReplyToTargetError(client, iCount);
	}
	else
		ReplyToCommand(client, "%t", "Phrase_Command_Invalid_Action", g_sTemporary, g_sPermanent, g_sReset);

	return Plugin_Handled;
}