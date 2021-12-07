#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

Handle g_hTempAdminsData;


public Plugin myinfo = 
{
	name        = "Temp Access",
	author      = "taski",
	description = "Add temporary admin flags",
	version     = "0.0.1",
	url         = "https://steamcommunity.com/id/taski_amagad/"
};


public void OnPluginStart() 
{
	RegAdminCmd("sm_refresh_ta", 	fwRefreshTempAdminsCmd, ADMFLAG_RCON, "Refreshes temp admins");
	RegAdminCmd("sm_remove_ta", 	fwRemoveAccess, 		ADMFLAG_RCON, "Removes temp access. Usage: sm_remove_ta <steamid>");
	RegAdminCmd("sm_give_ta", 		fwGiveAccess, 			ADMFLAG_RCON, "Gives temp access. Usage: sm_give_ta <steamid> <flag(s)> <days>");
}


public void OnMapStart()
{
	fwRefreshTempAdmins();
}


public void OnClientPutInServer(int iClient)
{
	CreateTimer(7.5, fwCheckUserAccess, iClient);
}


public Action fwRefreshTempAdminsCmd(int iClient, int iArgs)
{
	fwRefreshTempAdmins();
	PrintToConsole(iClient, "[SM] Temporary admins have been reloaded!");
}


public Action fwGiveAccess(int iClient, int iArgs)
{
	if(iArgs != 3)
    {
    	PrintToConsole(iClient, "[SM] Invalid arguments.");
        PrintToConsole(iClient, "[SM] Usage: sm_give_ta <steamid> <flag(s)> <days>");
        return Plugin_Handled;
    }
    
	char sArgs[32][256];
	
	for(int i = 0; i <= GetCmdArgs(); i++)
		GetCmdArg( i, sArgs[i], sizeof(sArgs) );
	
	if( ~StrContains( sArgs[1], "STEAM_", true ) != -1 )
	{
		PrintToConsole( iClient, "[SM] %s is not a valid SteamID!", sArgs[1] );
		PrintToConsole(iClient, "[SM] Usage: sm_give_ta <steamid> <flag(s)> <days>");
		return Plugin_Handled;
	}
	
	char sTrieData[128];
	
	if( GetTrieString( g_hTempAdminsData, sArgs[1], sTrieData, sizeof sTrieData ) )
	{
		PrintToConsole( iClient, "[SM] %s already has temporary access!", sArgs[1] );
		return Plugin_Handled;
	}
		
	int iAccessDays = StringToInt( sArgs[3] );
		
	Handle 	hFile;
	char 	sDirPath[PLATFORM_MAX_PATH];
				
	BuildPath(Path_SM, sDirPath, PLATFORM_MAX_PATH, "configs/admins_expire.cfg");
	
	hFile = OpenFile(sDirPath, "a+");
		
	WriteFileLine( hFile, "%s;|;%s;|;%i;|;%i", sArgs[1], sArgs[2], iAccessDays, GetTime() );
	
	CloseHandle(hFile);
	
	BuildPath(Path_SM, sDirPath, PLATFORM_MAX_PATH, "configs/admins_simple.ini");

	hFile = OpenFile(sDirPath, "a+");
	
	WriteFileLine( hFile, "\n\"%s\" \"0:%s\" //Temp access (%i days).\n", sArgs[1], sArgs[2], iAccessDays );
	
	char sTrieBuffer[128];
	Format( sTrieBuffer, sizeof(sTrieBuffer), "%s;|;%i;|;%s", sArgs[2], iAccessDays, GetTime() );
	
	SetTrieString( g_hTempAdminsData, sArgs[1], sTrieBuffer, false );

	CloseHandle(hFile);
	
	PrintToConsole( iClient, "[SM] Registered flags '%s' to user '%s' for %i days.", sArgs[2], sArgs[1], iAccessDays );
	LogMessage( "[TA] %N gave %s %s flags for %i days.", iClient, sArgs[1], sArgs[2], iAccessDays );
	
	ServerCommand("sm_reloadadmins");
	return Plugin_Handled;
}


public Action fwRemoveAccess(int iClient, int iArgs)
{
	if(iArgs != 1)
	{
		PrintToConsole(iClient, "[SM] Invalid arguments.");
		PrintToConsole(iClient, "[SM] Usage: sm_remove_ta <steamid>");
		return Plugin_Handled;
	}
	
	char sArgs[32];
	GetCmdArg( 1, sArgs, sizeof(sArgs) );
    
	if( ~StrContains(sArgs, "STEAM_", true) != -1 )
	{
		PrintToConsole(iClient, "[SM] %s is not a valid SteamID!", sArgs);
		PrintToConsole(iClient, "[SM] Usage: sm_remove_ta <steamid>");
		return Plugin_Handled;
	}
	
	char sTrieData[128];
	
	if( !GetTrieString(g_hTempAdminsData, sArgs, sTrieData, sizeof sTrieData) )
	{
		PrintToConsole(iClient, "[SM] Couldn't find user '%s'.", sArgs);
		return Plugin_Handled;
	}
	
	char sDirPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, sDirPath, PLATFORM_MAX_PATH, "configs/admins_expire.cfg");
	fwSearchAndRemove(sDirPath, sArgs);
			
	BuildPath(Path_SM, sDirPath, PLATFORM_MAX_PATH, "configs/admins_simple.ini");
	fwSearchAndRemove(sDirPath, sArgs);
			
	RemoveFromTrie(g_hTempAdminsData, sArgs);
	
	PrintToConsole(iClient, "[SM] Successfully removed '%s' access.", sArgs);
	LogMessage( "[TA] %N removed %s's temp access.", iClient, sArgs[1] );
	
	ServerCommand("sm_reloadadmins");
	return Plugin_Handled;
}


public Action fwCheckUserAccess( Handle hTimer, int iClient)
{
	if( !IsValidClient(iClient) )
		return Plugin_Handled;
		
	char sUserData[4][64];
	char sAuth[32], sTrieData[128];
	
	GetClientAuthId( iClient, AuthId_Steam2, sAuth, sizeof(sAuth) );

	if( GetTrieString(g_hTempAdminsData, sAuth, sTrieData, sizeof sTrieData) )
	{
		ExplodeString( sTrieData, ";|;", sUserData, 4, sizeof( sUserData[] ) );
		
		int iCurrentTime = GetTime();
		int iUserTime = StringToInt( sUserData[2] );
		int iAccessDays = StringToInt( sUserData[1] );
		
		if( (iCurrentTime - iUserTime) > (iAccessDays * 86400) )
		{
			char sDirPath[PLATFORM_MAX_PATH];
			
			BuildPath(Path_SM, sDirPath, PLATFORM_MAX_PATH, "configs/admins_expire.cfg");
			fwSearchAndRemove(sDirPath, sAuth);
			
			BuildPath(Path_SM, sDirPath, PLATFORM_MAX_PATH, "configs/admins_simple.ini");
			fwSearchAndRemove(sDirPath, sAuth);
			
			PrintToChat(iClient, " ");
			PrintToChat(iClient, " ");
			PrintToChat(iClient, "[SM] Your temporary access has expired.");
			LogMessage("[TA] %N's access has expired.", iClient);
			
			RemoveFromTrie(g_hTempAdminsData, sAuth);
			ServerCommand("sm_reloadadmins");
			
		} else {
			
			PrintToChat(iClient, " ");
			
			char sExpiry[64], sCurrentTime[64];
			FormatTime( sCurrentTime, sizeof(sCurrentTime), "%F (%I:%M:%S %p)", GetTime() ); 
			FormatTime( sExpiry, sizeof(sExpiry), "%F (%I:%M:%S %p)", ( iUserTime + (iAccessDays * 86400) ) ); 
			
			PrintToChat(iClient, "[SM] You got temporary flags '%s'.", sUserData[0] );
			PrintToChat(iClient, "[SM] You've got access till %s.", sExpiry);
			PrintToChat(iClient, "[SM] Current time is %s.", sCurrentTime);
		}
	}
	return Plugin_Handled;
}


stock void fwRefreshTempAdmins()
{
	Handle 	hFile;
	char 	sLine[128];
	char 	sDirPath[PLATFORM_MAX_PATH];
				
	BuildPath(Path_SM, sDirPath, PLATFORM_MAX_PATH, "configs/admins_expire.cfg");
	
	if( !FileExists(sDirPath) )
		hFile = OpenFile(sDirPath, "w+");
	else
		hFile = OpenFile(sDirPath, "r+");
		
	char sTrieData[128];
	char sLineFormatData[5][64];
	
	g_hTempAdminsData = CreateTrie();
		
	while( !IsEndOfFile(hFile) && ReadFileLine( hFile, sLine, sizeof(sLine) ) )
	{
		if( ( !StrEqual(sLine, "") ) )
		{
			ExplodeString( sLine, ";|;", sLineFormatData, 5, sizeof( sLineFormatData[] ) );
			Format( sTrieData, sizeof(sTrieData), "%s;|;%s;|;%s", sLineFormatData[1], sLineFormatData[2], sLineFormatData[3] );
			SetTrieString( g_hTempAdminsData, sLineFormatData[0], sTrieData, false );
		}
	}
	
	if(hFile != INVALID_HANDLE)
		CloseHandle(hFile);
}


stock void fwSearchAndRemove( char[] sDirPath, char[] sTargetString )
{
	char sTempFile[PLATFORM_MAX_PATH];
	char sLineBuffer[PLATFORM_MAX_PATH];
    
	Format(sTempFile, sizeof(sTempFile), "%s.temp", sDirPath);
    
	Handle hFile = OpenFile(sDirPath, "r+");
	Handle hFileTemp = OpenFile(sTempFile, "w");
    
	if(hFile != INVALID_HANDLE)
	{
		while( ReadFileLine( hFile, sLineBuffer, sizeof(sLineBuffer) ) )
		{
			TrimString(sLineBuffer);
			
			if( (! StrEqual(sLineBuffer, "") ) )
			{
				if(StrContains(sLineBuffer, sTargetString, false) == -1)
				{
					WriteFileLine(hFileTemp, sLineBuffer);
				}
			}
			else
				WriteFileLine(hFileTemp, sLineBuffer);
		}
	}
	
	if(hFile != INVALID_HANDLE)
		CloseHandle(hFile);

	if(hFileTemp != INVALID_HANDLE)
		CloseHandle(hFileTemp);

	DeleteFile(sDirPath);
	RenameFile(sDirPath, sTempFile);
}


stock bool IsValidClient(int iClient) 
{ 
	if (iClient <= 0) 
		return false; 
	
	if (iClient > MaxClients) 
		return false; 
	
	if ( !IsClientConnected(iClient) ) 
		return false; 
	
	return IsClientInGame(iClient); 
}

