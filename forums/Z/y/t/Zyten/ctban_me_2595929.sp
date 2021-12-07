#include <sourcemod>
#include <colors>

#tryinclude <ctban>

#pragma semicolon 1
#pragma newdecls required

float g_fSpamCheck[33];


public Plugin myinfo = 
{
	name        = "CTban me (for databomb vers)",
	author      = "taski",
	description = "CT bans yourself (for databomb version)",
	version     = "0.0.2",
	url         = "https://steamcommunity.com/id/taski_amagad/"
};


public void OnPluginStart()
{
	RegConsoleCmd("sm_ctbanme", fwExecuteCTBan);
}


public void OnClientPostAdminCheck(int iClient) 
{
	if( IsValidClient(iClient) ) 
		g_fSpamCheck[iClient] = 0.0;
}


public Action fwExecuteCTBan(int iClient,  int iArgs)
{
	if ( g_fSpamCheck[iClient] && GetGameTime() - g_fSpamCheck[iClient] <= 5.0 )
	{
		CPrintToChat(iClient, "[{olive}CTBan Me{default}] Do not spam this.");
		return Plugin_Handled;
	}
		
	g_fSpamCheck[iClient] = GetGameTime();
	
	//Usage: sm_ctban <player> <time> <optional:reason>
	
	int iClientCTBan = CTBan_IsClientBanned(iClient);
	
	if(iClientCTBan <= 0)
	{
		ServerCommand( "sm_ctban #%d 30 ctbanme", GetClientUserId(iClient) );
		CPrintToChatAll("[{olive}CTBan Me{default}] %N CT banned himself for 30 minutes.", iClient);
	} else {
		CPrintToChat(iClient, "[{olive}CTBan Me{default}] You are already CT banned.");
		return Plugin_Handled;
	}
	return Plugin_Continue;
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

