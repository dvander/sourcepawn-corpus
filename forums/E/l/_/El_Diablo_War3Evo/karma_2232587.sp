/*  This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

	Antihack written by El Diablo of www.War3Evo.info
	All rights reserved.
*/

#define DATABASENAME "servers"
#define DATABASENAME_TABLE "karma"

// switchgamemode is only used in our servers,
// and I was too lazy to remove for upload
#tryinclude <switchgamemode>

#if !defined _switchgamemode_included
#define GGAMETYPE 1
// If your running CSGO, then change below to 1
#define GGAME_CSGO 0
#endif

// NOTE TO CSGO SERVER OWNERS:
// If your a CSGO server, I've included my personal copy
// of my CSGO colors.  It's my "lazy version" where it removes
// colors not compatible with CSGO from morecolors colors used
// in many scripts.


////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
////////////////////////////// DO NOT EDIT BELOW THIS LINE
#pragma semicolon 1

#include <karma>

#define PLUGIN_VERSION "1.0"


#if GGAMETYPE != GGAME_CSGO
#include <morecolors>
#else
#include <colors>
#endif


new dummy;

new Handle:hDB = INVALID_HANDLE;
new Handle:m_AutosaveTime;

new pos_karma[MAXPLAYERS + 1];
new pos_karma_expiry[MAXPLAYERS + 1];

new neg_karma[MAXPLAYERS + 1];
new neg_karma_expiry[MAXPLAYERS + 1];

new Handle:g_OnKarmaUpdate;
new Handle:g_OnKarmaTimeUpdate;

new bool:b_LateLoad = false;

public Plugin:myinfo =
{
	name = "KARMA",
	author = "El Diablo",
	description = "A database system to give players karma.",
	version = PLUGIN_VERSION,
	url = "http://www.war3evo.info"
};

public OnPluginStart()
{
	CreateConVar("karma_version","1.0 by El Diablo","Karma version.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	m_AutosaveTime=CreateConVar("karma_autosavetime","300.0");
	CreateTimer(GetConVarFloat(m_AutosaveTime),Database_DoAutosave);
}

public OnAllPluginsLoaded()
{
	ConnectDB();
}

public OnClientPostAdminCheck(client)
{
	if (hDB == INVALID_HANDLE)
	{
		return;
	}

	LoadPlayerData(client);
}

public OnClientDisconnect(client)
{
	SavePlayerData(client);
}

public OnPluginEnd()
{
	if(hDB != INVALID_HANDLE)
	{
		CloseHandle(hDB);
	}
}

///////////////// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
///////////////// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
///////////////// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
///////////////// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
///////////////// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
///////////////// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
///////////////// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
stock bool:ValidPlayer(client,bool:check_alive=false,bool:alivecheckbyhealth=false) {
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(check_alive && !IsPlayerAlive(client))
		{
			return false;
		}
		if(alivecheckbyhealth&&GetClientHealth(client)<1) {
			return false;
		}
		return true;
	}
	return false;
}
stock totalkarma(client)
{
	return (pos_karma[client]-neg_karma[client]);
}
stock SQL_VIP_CheckForErrors(Handle:hndl,const String:originalerror[],const String:prependstr[]="",Handle:originalqueryTrie=Handle:0) {
	new String:orignalquerystr[512];
	if(originalqueryTrie) {
		if(!GetTrieString(originalqueryTrie,"query",orignalquerystr,sizeof(orignalquerystr))) {
			LogError("SQLCheckForErrors: originalqueryTrie is not null but key 'query' not set from trie");
		}
		CloseHandle(originalqueryTrie);
	}

	if(!StrEqual("", originalerror))
	LogError("SQL error: [%s] %s QUERY:%s", prependstr, originalerror,orignalquerystr);
	else if(hndl == INVALID_HANDLE)
	{
		decl String:err[512];
		SQL_GetError(hndl, err, sizeof(err));
		LogError("SQLCheckForErrors: [%s] %s QUERY:%s", prependstr, err,orignalquerystr);
	}
}
public bool:SQL_FastQueryLogOnError(Handle:DB,const String:query[]) {
	if(!SQL_FastQuery(DB,query)) {
		new String:error[256];
		SQL_GetError(DB, error, sizeof(error));
		LogError("SQLFastQuery %s failed, Error: %s",query,error);
		return false;
	}
	return true;
}
stock KarmaLog(const String:reason[]="", any:...)
{
	new String:szFile[1024];

	new String:LogThis[2048];
	VFormat(LogThis, sizeof(LogThis), reason, 2);

	BuildPath(Path_SM, szFile, sizeof(szFile), "logs/karma.log");
	LogToFile(szFile, LogThis);
}

//=============================================================================
// AskPluginLoad2
//=============================================================================
public APLRes:AskPluginLoad2(Handle:plugin,bool:late,String:error[],err_max)
{
	g_OnKarmaUpdate=CreateGlobalForward("OnKarmaUpdate",ET_Ignore,Param_Cell);
	g_OnKarmaTimeUpdate=CreateGlobalForward("OnKarmaTimeUpdate",ET_Ignore,Param_Cell);

	CreateNative("GetPosKarma",Native_GetPosKarma);
	CreateNative("SetPosKarma",Native_SetPosKarma);
	CreateNative("AddPosKarma",Native_AddPosKarma);

	CreateNative("GetNegKarma",Native_GetNegKarma);
	CreateNative("SetNegKarma",Native_SetNegKarma);
	CreateNative("AddNegKarma",Native_AddNegKarma);

	CreateNative("GetPosKarmaTime",Native_GetPosKarmaTime);
	CreateNative("SetPosKarmaTime",Native_SetPosKarmaTime);

	CreateNative("GetNegKarmaTime",Native_GetNegKarmaTime);
	CreateNative("SetNegKarmaTime",Native_SetNegKarmaTime);

	RegPluginLibrary("karma");

	if(late)
	{
		b_LateLoad = true;

		PrintToServer("KARMA LATE LOAD");
	}
	return APLRes_Success;
}

///////////////// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES
///////////////// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES
///////////////// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES
///////////////// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES
///////////////// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES
//pos_karma[MAXPLAYERS + 1];
//pos_karma_expiry[MAXPLAYERS + 1];
//neg_karma[MAXPLAYERS + 1];
//neg_karma_expiry[MAXPLAYERS + 1];

public Native_GetPosKarma(Handle:plugin,numParams) {
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		return pos_karma[client];
	}
	return 0;
}
public Native_GetNegKarma(Handle:plugin,numParams) {
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		return neg_karma[client];
	}
	return 0;
}

public Native_SetPosKarma(Handle:plugin,numParams) {
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		pos_karma[client]=GetNativeCell(2);

		Call_StartForward(g_OnKarmaUpdate);
		Call_PushCell(client);
		Call_Finish(dummy);
	}
}
public Native_SetNegKarma(Handle:plugin,numParams) {
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		neg_karma[client]=GetNativeCell(2);

		Call_StartForward(g_OnKarmaUpdate);
		Call_PushCell(client);
		Call_Finish(dummy);
	}
}

public Native_AddPosKarma(Handle:plugin,numParams) {
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		pos_karma[client]+=GetNativeCell(2);

		Call_StartForward(g_OnKarmaUpdate);
		Call_PushCell(client);
		Call_Finish(dummy);
	}
}
public Native_AddNegKarma(Handle:plugin,numParams) {
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		neg_karma[client]+=GetNativeCell(2);

		Call_StartForward(g_OnKarmaUpdate);
		Call_PushCell(client);
		Call_Finish(dummy);
	}
}

public Native_GetPosKarmaTime(Handle:plugin,numParams) {
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		return pos_karma_expiry[client];
	}
	return 0;
}
public Native_GetNegKarmaTime(Handle:plugin,numParams) {
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		return neg_karma_expiry[client];
	}
	return 0;
}

public Native_SetPosKarmaTime(Handle:plugin,numParams) {
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		pos_karma_expiry[client]=GetNativeCell(2);

		Call_StartForward(g_OnKarmaTimeUpdate);
		Call_PushCell(client);
		Call_Finish(dummy);
	}
}
public Native_SetNegKarmaTime(Handle:plugin,numParams) {
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		neg_karma_expiry[client]=GetNativeCell(2);

		Call_StartForward(g_OnKarmaTimeUpdate);
		Call_PushCell(client);
		Call_Finish(dummy);
	}
}

///////////////////// DATABASE ///////////////////////////////////////
///////////////////// DATABASE ///////////////////////////////////////
///////////////////// DATABASE ///////////////////////////////////////
///////////////////// DATABASE ///////////////////////////////////////
///////////////////// DATABASE ///////////////////////////////////////
///////////////////// DATABASE ///////////////////////////////////////

public bool:Initialize_SQLTable()
{
	PrintToServer("[Karma] Initialize_SQLTable");
	if(hDB!=INVALID_HANDLE)
	{
		PrintToServer("Karma DATABASE Locked");

		//non threading operations here, done once on plugin load only, not map change
		SQL_LockDatabase(hDB);

		//main table
		decl String:shortquery[512];
		Format(shortquery,sizeof(shortquery),"SELECT * from %s LIMIT 1",DATABASENAME_TABLE);
		new Handle:query=SQL_Query(hDB,shortquery);

		if(query==INVALID_HANDLE)
		{
			PrintToServer("Karma CREATE DATABASE");
			new String:createtable[3000];
			Format(createtable,sizeof(createtable),
			"CREATE TABLE `%s` ( \
			`id` int(11) NOT NULL AUTO_INCREMENT, \
			`accountid` int(11) NOT NULL, \
			`recent_name` varchar(64) COLLATE utf8_unicode_ci NOT NULL DEFAULT '', \
			`positive_karma` int(11) NOT NULL DEFAULT '0', \
			`negative_karma` int(11) NOT NULL DEFAULT '0', \
			`positive_karma_expiry` bigint(20) NOT NULL DEFAULT '0', \
			`negative_karma_expiry` bigint(20) NOT NULL DEFAULT '0', \
			`last_seen` bigint(20) NOT NULL DEFAULT '0', \
			PRIMARY KEY (`id`,`accountid`) \
			) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci$$ \
			",DATABASENAME_TABLE,
			"DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci");

			if(!SQL_FastQueryLogOnError(hDB,createtable))
			{
				SetFailState("[Karma] ERROR in the creation of the SQL table %s.",DATABASENAME);
			}
			else
			{
				PrintToServer("Karma CREATE TABLE %s SUCCESSFUL",DATABASENAME_TABLE);
				KarmaLog("Karma CREATE TABLE %s SUCCESSFUL",DATABASENAME_TABLE);
			}
		}
		else
		{
			PrintToServer("Karma DATABASE Creation Check passed");
		}

		CloseHandle(query);

		SQL_UnlockDatabase(hDB);

		PrintToServer("Karma DATABASE UnLocked");

		return true;
	}
	else
	{
		PrintToServer("hDB invalid");
		KarmaLog("hDB invalid");
		return false;
	}
}

public ConnectDB()
{
	SQL_TConnect(DB_Callback_Connect, DATABASENAME);
}

public DB_Callback_Connect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		hDB=hndl;
		if(Initialize_SQLTable())
		{
			if(b_LateLoad)
			{
				for(new x=1;x<=MaxClients;x++)
				{
					if(ValidPlayer(x))
					{
						LoadPlayerData(x);
					}
				}
			}
		}
	}
	else
	{
		KarmaLog("Can not connect to database %s error: %s",DATABASENAME,error);
	}
}

///////////////////// DATABASE LOAD ///////////////////////////////////////
///////////////////// DATABASE LOAD ///////////////////////////////////////
///////////////////// DATABASE LOAD ///////////////////////////////////////
///////////////////// DATABASE LOAD ///////////////////////////////////////
///////////////////// DATABASE LOAD ///////////////////////////////////////

public LoadPlayerData(client)
{
	if(hDB != INVALID_HANDLE)
	{
		new steamaccountid = GetSteamAccountID(client);

		if(steamaccountid>0)
		{
			PrintToServer("KARMA --> LoadPlayerData steamaccountid = %d",steamaccountid);

			new String:query[2000];
			Format(query, sizeof(query), "SELECT positive_karma,negative_karma,positive_karma_expiry,negative_karma_expiry FROM %s WHERE `accountid` = '%d';", DATABASENAME_TABLE, steamaccountid);

			new Handle:pk;
			pk = CreateDataPack();
			WritePackCell(pk, GetClientUserId(client));
			WritePackCell(pk, steamaccountid);
			WritePackString(pk, query);

			SQL_TQuery(hDB, SQLCallback_LookupPlayer, query, pk, DBPrio_High);
		}
	}
	else
	{
		KarmaLog("Karma LoadPlayerData() Database Invalid!");
	}
}

///////////////////// DATABASE: LOAD SAVED DATA //////////////////////
///////////////////// DATABASE: LOAD SAVED DATA //////////////////////
///////////////////// DATABASE: LOAD SAVED DATA //////////////////////
///////////////////// DATABASE: LOAD SAVED DATA //////////////////////
///////////////////// DATABASE: LOAD SAVED DATA //////////////////////

public SQLCallback_LookupPlayer(Handle:owner,Handle:hndl,const String:error[],any:data)
{
	new Handle:pk = Handle:data;
	ResetPack(pk);

	new client = GetClientOfUserId(ReadPackCell(pk));

	new steamaccountid = ReadPackCell(pk);

	SQL_VIP_CheckForErrors(hndl,error,"SQLCallback_LookupPlayer");

	if(client<=0 || client>MaxClients)
	{
		decl String:query[255];
		ReadPackString(pk, query, sizeof(query));

		KarmaLog("INVALID CLIENT Query dump: %s",query);

		/* Discard everything*/
		CloseHandle(pk);
		return;
	}

	if(hndl == INVALID_HANDLE)
	{
		KarmaLog("SQLCallback_LookupPlayer: Error looking up player. %s.", error);
		PrintToServer("SQLCallback_LookupPlayer: Error looking up player. %s.", error);

		decl String:query[255];
		ReadPackString(pk, query, sizeof(query));

		KarmaLog("Query dump: %s",query);

		/* Discard everything*/
		CloseHandle(pk);
		return;
	}
	else
	{
		/**
		 * We're done with you, now.
		 */
		CloseHandle(pk);

		if(SQL_GetRowCount(hndl) == 1)
		{
			PrintToServer("SQL_GetRowCount(hndl) == 1");
			SQL_Rewind(hndl);

			if(!SQL_FetchRow(hndl))
			{
				//This would be pretty fucked to occur here
				LogError("[Karma] Unexpected error loading player data, could not FETCH row. Check DATABASE settings!");
				PrintToServer("");
				PrintToServer("[Karma] Unexpected error loading player data, could not FETCH row. Check DATABASE settings!");
				return;
			}
			else
			{
					PrintToServer("Karma SQLCallback_LookupPlayer SQL_FetchRow(hndl)");
					pos_karma[client]=SQL_FetchInt(hndl, 0);
					neg_karma[client]=SQL_FetchInt(hndl, 1);
					new total = pos_karma[client] - neg_karma[client];
					pos_karma_expiry[client]=SQL_FetchInt(hndl, 2);
					neg_karma_expiry[client]=SQL_FetchInt(hndl, 3);
					CPrintToChat(client,"{yellow}[KARMA] You have {orange}%d {yellow}Positive | {orange}%d {yellow}Negative | {orange}%d {yellow}Total Karma",pos_karma[client],neg_karma[client],total);
			}
		}
		else if(SQL_GetRowCount(hndl) == 0) //he or she doesnt exist
		{
			///////////////////////////////////////////
			/////////IN THIS AREA IS///////////////////
			/////////WHERE THE NEW PLAYER DATA/////////
			/////////IS CREATED!///////////////////////
			///////////////////////////////////////////
			decl String:name[64];
			if(GetClientName(client,name,sizeof(name)))
			{
				ReplaceString(name,sizeof(name), "'","", true);//REMOVE IT//double escape because \\ turns into -> \  after the %s insert into sql statement

				new String:szSafeName[(sizeof(name)*2)-1];
				SQL_EscapeString( hDB, name, szSafeName, sizeof(szSafeName));

				new today = GetTime();

				pos_karma[client]=0;
				neg_karma[client]=0;
				pos_karma_expiry[client]=today;
				neg_karma_expiry[client]=today;

				new String:longquery[4000];

				Format(longquery,sizeof(longquery),"INSERT INTO %s \
				(accountid,recent_name,positive_karma,negative_karma,positive_karma_expiry,negative_karma_expiry) \
				VALUES ('%d','%s','0','0','%d','%d')",
				DATABASENAME_TABLE,steamaccountid,szSafeName,today,today);
				SQL_TQuery(hDB, SQLCallback_NewPlayer, longquery, sizeof(longquery), DBPrio_High);
			}
		}
		else if(SQL_GetRowCount(hndl) >1)
		{
			// this is a WTF moment here
			//should probably purge these records and get the player to rejoin but I'm lazy
			//and don't want to write that
			LogError("[Karma] Returned more than 1 record, primary or UNIQUE keys are screwed (main, rows: %d)",SQL_GetRowCount(hndl));
			PrintToServer("[Karma] Returned more than 1 record, primary or UNIQUE keys are screwed (main, rows: %d)",SQL_GetRowCount(hndl));
		}
	}
}

public SQLCallback_NewPlayer(Handle:owner,Handle:hndl,const String:error[],any:data)
{
	SQL_VIP_CheckForErrors(hndl,error,"SQLCallback_NewPlayer");
}

///////////////////// DATABASE: SAVE DATA //////////////////////
///////////////////// DATABASE: SAVE DATA //////////////////////
///////////////////// DATABASE: SAVE DATA //////////////////////
///////////////////// DATABASE: SAVE DATA //////////////////////
///////////////////// DATABASE: SAVE DATA //////////////////////
public Action:Database_DoAutosave(Handle:timer,any:data)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(client>0 && client<=MaxClients && IsClientInGame(client))
		{
			SavePlayerData(client);
		}
	}
	CreateTimer(GetConVarFloat(m_AutosaveTime),Database_DoAutosave);
}

public SavePlayerData(client)
{
	if(hDB != INVALID_HANDLE)
	{
		new steamaccountid = GetSteamAccountID(client);

		if(steamaccountid>0)
		{
			PrintToServer("KARMA --> SavePlayerData steamaccountid = %d",steamaccountid);

			decl String:name[64];
			GetClientName(client,name,sizeof(name));
			ReplaceString(name,sizeof(name), "'","", true);//REMOVE IT//double escape because \\ turns into -> \  after the %s insert into sql statement

			new String:szSafeName[(sizeof(name)*2)-1];
			SQL_EscapeString( hDB, name, szSafeName, sizeof(szSafeName));

			new last_seen=GetTime();

			new String:query[2000];
			Format(query, sizeof(query), "UPDATE %s \
			SET recent_name='%s',positive_karma='%d',negative_karma='%d',positive_karma_expiry='%d',negative_karma_expiry='%d',last_seen='%d' WHERE `accountid` = '%d';",
			DATABASENAME_TABLE, szSafeName, pos_karma[client], neg_karma[client], pos_karma_expiry[client], neg_karma_expiry[client], last_seen, steamaccountid);

			new Handle:pk;
			pk = CreateDataPack();
			WritePackCell(pk, GetClientUserId(client));
			WritePackString(pk, query);

			SQL_TQuery(hDB, SQLCallback_SavePlayerData, query, pk, DBPrio_High);
		}
	}
	else
	{
		KarmaLog("Karma LoadPlayerData() Database Invalid!");
	}
}

public SQLCallback_SavePlayerData(Handle:owner,Handle:hndl,const String:error[],any:data)
{
	new Handle:pk = Handle:data;
	ResetPack(pk);

	new client = GetClientOfUserId(ReadPackCell(pk));

	SQL_VIP_CheckForErrors(hndl,error,"SQLCallback_SavePlayerData");

	if(client<=0 || client>MaxClients)
	{
		decl String:query[255];
		ReadPackString(pk, query, sizeof(query));

		KarmaLog("SQLCallback_SavePlayerData INVALID CLIENT Query dump: %s",query);

		/* Discard everything*/
		CloseHandle(pk);
		return;
	}

	if(hndl == INVALID_HANDLE)
	{
		KarmaLog("SQLCallback_SavePlayerData: Error looking up player. %s.", error);
		PrintToServer("SQLCallback_SavePlayerData: Error looking up player. %s.", error);

		decl String:query[255];
		ReadPackString(pk, query, sizeof(query));

		KarmaLog("Query dump: %s",query);

		/* Discard everything*/
		CloseHandle(pk);
		return;
	}
	else
	{
		/**
		 * We're done with you, now.
		 */
		CloseHandle(pk);
	}
}
