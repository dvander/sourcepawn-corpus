// Knowledgebase plugin by MistaGee

#pragma semicolon 1

#include <sourcemod>

#define KNOWLEDGEBASE_VERSION "1.6"
#define KNOWLEDGEBASE_ADMINFLAG ADMFLAG_CHAT

public Plugin:myinfo = {
	name = "Knowledge base",
	author = "MistaGee",
	description = "Builds knowledgebase",
	version = KNOWLEDGEBASE_VERSION,
	url = "http://www.sourcemod.net/"
	}

new Handle:db		= INVALID_HANDLE,
    Handle:cvar_public	= INVALID_HANDLE;

public OnPluginStart(){
	CreateConVar( "kbase_version", KNOWLEDGEBASE_VERSION, "Knowledgebase version", FCVAR_NOTIFY );
	cvar_public = CreateConVar( "kbase_public", "1", "Show ansers to everyone?", FCVAR_NOTIFY );
	
	RegAdminCmd( "?",		Command_Question,	0 );
	RegAdminCmd( "!",		Command_Answer,		KNOWLEDGEBASE_ADMINFLAG );
	RegAdminCmd( "kbase_list",	Command_List,		KNOWLEDGEBASE_ADMINFLAG );
	RegAdminCmd( "kbase_delete",	Command_Delete,		KNOWLEDGEBASE_ADMINFLAG );
	
	// Shamelessly stolen from sql-admin-manager.sp
	new String:error[255];
	
	if( SQL_CheckConfig("knowledgebase") ){
		db = SQL_Connect( "knowledgebase", true, error, sizeof(error) );
		}
	else if( SQL_CheckConfig("default") ){
		db = SQL_Connect( "default", true, error, sizeof(error) );
		}
	
	if( db == INVALID_HANDLE ){
		LogError( "[KB] Could not connect to database: %s", error );
		}
	else{
		// Make sure table exists
		SQL_FastQuery( db,
			"CREATE TABLE IF NOT EXISTS knowledgebase ( keyword varchar(40) NOT NULL PRIMARY KEY, description varchar(255) NOT NULL );"
			);
		}
	}

public Action:Command_Question( client, args ){
	if( args == 0 ){
		ReplyToCommand( client, "[KB] Usage: ? <keyword> [<user>]" );
		return Plugin_Handled;
		}
	if( db == INVALID_HANDLE ){
		ReplyToCommand( client, "[KB] Database is not connected." );
		return Plugin_Handled;
		}
	
	decl String:keyword[40],
	     String:error[255];
	GetCmdArg( 1, keyword, sizeof(keyword) );
	
	new Handle:database_select = SQL_PrepareQuery( db,
		"SELECT description FROM knowledgebase WHERE keyword=?",
		error, sizeof(error)
		);
	if( database_select == INVALID_HANDLE ){
		LogError( "[KB] Preparing statement failed: %s", error );
		}
	
	if( StrEqual( keyword, "me" ) ){
		// Bind with SteamID to allow private things - idea by Extreme_One
		decl String:SteamID[40];
		GetClientAuthString( client, SteamID, sizeof(SteamID) );
		SQL_BindParamString( database_select, 0, SteamID, false );
		}
	else
		SQL_BindParamString( database_select, 0, keyword, false );
	
	if( !SQL_Execute( database_select ) ){
		ReplyToCommand( client, "[KB] Database query failed." );
		CloseHandle( database_select );
		return Plugin_Handled;
		}
	
	if( !SQL_MoreRows( database_select ) ){
		ReplyToCommand( client, "[KB] Keyword not found." );
		CloseHandle( database_select );
		return Plugin_Handled;
		}
	
	SQL_FetchRow( database_select );
	
	decl String:descrip[255];
	SQL_FetchString( database_select, 0, descrip, sizeof(descrip) );
	
	if( StrEqual( keyword, "me" ) ){
		GetClientName( client, keyword, sizeof(keyword) );
		}
	
	ReplaceTFColorCodes( descrip, sizeof(descrip) );
	
	if( GetConVarBool( cvar_public ) ){
		PrintToChatAll( "[KB] %s: %s", keyword, descrip );
		}
	else{
		ReplyToCommand( client, "[KB] %s: %s", keyword, descrip );
		}
	
	CloseHandle( database_select );
	return Plugin_Handled;
	}

public Action:Command_Answer( client, args ){
	if( args <= 1 ){
		ReplyToCommand( client, "[KB] Usage: ! <keyword> \"<description>\"" );
		return Plugin_Handled;
		}
	if( db == INVALID_HANDLE ){
		ReplyToCommand( client, "[KB] Database is not connected." );
		return Plugin_Handled;
		}
	
	decl String:keyword[40],
	     String:descrip[255],
	     String:error[255];
	
	GetCmdArg( 1, keyword, sizeof(keyword) );
	GetCmdArg( 2, descrip, sizeof(descrip) );
	
	new Handle:database_insert = SQL_PrepareQuery( db,
		"INSERT INTO knowledgebase VALUES( ?, ? )",
		error, sizeof(error)
		);
	
	decl String:SteamID[40];
	if( StrEqual( keyword, "me" ) ){
		// Bind with SteamID to allow private things - idea by Extreme_One
		GetClientAuthString( client, SteamID, sizeof(SteamID) );
		SQL_BindParamString( database_insert, 0, SteamID, false );
		}
	else
		SQL_BindParamString( database_insert, 0, keyword, false );
	
	SQL_BindParamString( database_insert, 1, descrip, false );
	
	if( !SQL_Execute( database_insert ) ){
		// seems like keyword exists
		// This method is sort of shitty, I should check that first... omg hax
		new Handle:database_update = SQL_PrepareQuery( db,
			"UPDATE knowledgebase SET description=? WHERE keyword=?",
			error, sizeof(error)
			);
		SQL_BindParamString( database_update, 0, descrip, false );
		
		if( StrEqual( keyword, "me" ) ){
			// Bind with SteamID to allow private things - idea by Extreme_One
			SQL_BindParamString( database_update, 1, SteamID, false );
			}
		else
			SQL_BindParamString( database_update, 1, keyword, false );
		
		if( !SQL_Execute( database_update ) ){
			ReplyToCommand( client, "[KB] Database update failed." );
			CloseHandle( database_insert );
			CloseHandle( database_update );
			return Plugin_Handled;
			}
		CloseHandle( database_update );
		}
	
	CloseHandle( database_insert );
	
	ReplyToCommand( client, "[KB] Defined %s as \"%s\".", keyword, descrip );
	return Plugin_Handled;
	}

public OnClientPutInServer( client ){
	if( client == 0 )
		return;
	if( db == INVALID_HANDLE ){
		ReplyToCommand( client, "[KB] Database is not connected." );
		return;
		}
	
	decl String:error[255];
	
	new Handle:database_select = SQL_PrepareQuery( db,
		"SELECT description FROM knowledgebase WHERE keyword=?",
		error, sizeof(error)
		);
	if( database_select == INVALID_HANDLE ){
		LogError( "[KB] Preparing statement failed: %s", error );
		}
	
	// Bind with SteamID to allow private things - idea by Extreme_One
	decl String:SteamID[40];
	GetClientAuthString( client, SteamID, sizeof(SteamID) );
	SQL_BindParamString( database_select, 0, SteamID, false );
	
	if( !SQL_Execute( database_select ) ){
		PrintToServer( "[KB] Database query failed." );
		CloseHandle( database_select );
		return;
		}
	
	if( SQL_MoreRows( database_select ) ){
		SQL_FetchRow( database_select );
		
		decl	String:descrip[255],
			String:plName[40];
		
		SQL_FetchString( database_select, 0, descrip, sizeof(descrip) );
		GetClientName( client, plName, sizeof(plName) );
		
		ReplaceTFColorCodes( descrip, sizeof(descrip) );
		PrintToChatAll( "[KB] %s: %s", plName, descrip );
		}
	
	CloseHandle( database_select );
	}

public Action:Command_List( client, args ){
	if( db == INVALID_HANDLE ){
		ReplyToCommand( client, "[KB] Database is not connected." );
		return Plugin_Handled;
		}
	
	new Handle:result = SQL_Query( db,
		"SELECT keyword FROM knowledgebase WHERE keyword NOT LIKE 'STEAM_%'"
		);
	
	if( result == INVALID_HANDLE ){
		ReplyToCommand( client, "[KB] Database query failed." );
		return Plugin_Handled;
		}
	
	if( !SQL_MoreRows( result ) ){
		ReplyToCommand( client, "[KB] No keywords were defined." );
		}
	else{
		decl String:keyword[40];
		ReplyToCommand( client, "[KB] Listing defined keywords..." );
		while( SQL_MoreRows( result ) ){
			SQL_FetchRow( result );
			SQL_FetchString( result, 0, keyword, sizeof(keyword) );
			ReplyToCommand( client, "[KB] %s", keyword );
			}
		ReplyToCommand( client, "[KB] End of defined keywords." );
		}
	
	return Plugin_Handled;
	}


public Action:Command_Delete( client, args ){
	if( args < 1 ){
		ReplyToCommand( client, "[KB] Usage: kbase_delete <keyword>" );
		return Plugin_Handled;
		}
	if( db == INVALID_HANDLE ){
		ReplyToCommand( client, "[KB] Database is not connected." );
		return Plugin_Handled;
		}
	
	decl String:keyword[40],
	     String:error[255];
	
	GetCmdArg( 1, keyword, sizeof(keyword) );
	
	new Handle:qry = SQL_PrepareQuery( db,
		"DELETE FROM knowledgebase WHERE keyword=?",
		error, sizeof(error)
		);
	
	if( StrEqual( keyword, "me" ) ){
		decl String:SteamID[40];
		GetClientAuthString( client, SteamID, sizeof(SteamID) );
		SQL_BindParamString( qry, 0, SteamID, false );
		}
	else
		SQL_BindParamString( qry, 0, keyword, false );
	
	if( !SQL_Execute( qry ) ){
		ReplyToCommand( client, "[KB] Database query failed." );
		}
	else{
		ReplyToCommand( client, "[KB] Entry deleted." );
		}
	
	CloseHandle( qry );
	return Plugin_Handled;
	}


void:ReplaceTFColorCodes( String:theString[], theStringLen ){
	ReplaceString( theString, theStringLen, "%1", "\x01" );
	ReplaceString( theString, theStringLen, "%2", "\x02" );
	ReplaceString( theString, theStringLen, "%3", "\x03" );
	ReplaceString( theString, theStringLen, "%4", "\x04" );
	}
