#include <sourcemod>

#pragma semicolon 1  
#pragma newdecls required

Handle 	g_hMenuStringsArray;


public void OnPluginStart()
{
	RegConsoleCmd	("sm_menu", fwMenuCmd);
	RegAdminCmd		("sm_refresh_menudata", fwRefreshMenuData, ADMFLAG_RCON, "Refreshes menu data");
	
	g_hMenuStringsArray = CreateArray(128);
}


public void OnMapEnd()
{
	ClearArray(g_hMenuStringsArray);
}


public void OnMapStart()
{
	 fwRefreshMenuData(0, 0);
}


public Action fwRefreshMenuData(int iClient, int iArgs)
{
	ClearArray(g_hMenuStringsArray);
	
	char 	sFilePath[PLATFORM_MAX_PATH];
	Handle 	hKeyValues = CreateKeyValues("Menu"); 
    
	BuildPath( Path_SM, sFilePath, sizeof(sFilePath), "configs/menudata.ini" );	
	FileToKeyValues(hKeyValues, sFilePath);
    
	char sSection[128];
	char sGetString[128];
	
	if( !KvGotoFirstSubKey(hKeyValues) ) 
	{
		LogMessage("There was no entries found in menudata.ini !");
		if(iClient != 0) PrintToChat(iClient, "[SM] There was no entries found in menudata.ini !");
		return Plugin_Handled;
	}
	
	do 
	{
		KvGetSectionName( hKeyValues, sSection, sizeof(sSection) );
		KvGetString( hKeyValues, "value", sGetString, sizeof(sGetString), "NULL" );
		
		PushArrayString(g_hMenuStringsArray, sSection);
		PushArrayString(g_hMenuStringsArray, sGetString);
		
	} while( KvGotoNextKey(hKeyValues) );

	CloseHandle(hKeyValues); 
	
	if(iClient != 0) PrintToChat(iClient, "[SM] Menu data refreshed successfully");
	return Plugin_Handled;
}


public Action fwMenuCmd(int iClient, int iArgs)
{
	if(iClient != 0) fwMenuFormat(iClient);
	return Plugin_Handled;
}


public Action fwMenuFormat(int iClient)
{
	Menu mMenu = new Menu(fwMenuHandle);

	mMenu.SetTitle("[Config menu] \n \n");
	
	int 	i;
	char 	sLineBuffer[128];
	char 	sMenuString[128];
	
	for( i = 0 ; i < GetArraySize(g_hMenuStringsArray) - 1; i++ )
    {
		GetArrayString( g_hMenuStringsArray, i, sMenuString, sizeof(sMenuString) );
    	
		i++;
		GetArrayString( g_hMenuStringsArray, i, sLineBuffer, sizeof(sLineBuffer) );
		
		mMenu.AddItem( sLineBuffer, sMenuString );
	}
	
	if(i == 0)
	{
		PrintToChat(iClient, "[SM] Nothing was found!");
		return Plugin_Handled;
	}
	
	mMenu.ExitButton = true;
	mMenu.Display(iClient, 0);
	return Plugin_Handled;
}


public int fwMenuHandle(Menu mMenu, MenuAction maAction, int iClient, int iParam)
{
	if( IsValidClient(iClient) )
	{
		if(maAction == MenuAction_Select)
		{
			char sInfoPressed[264];
			mMenu.GetItem( iParam, sInfoPressed, sizeof(sInfoPressed) );
			PrintToChat(iClient, "You chose #%i ( %s ).", iParam + 1, sInfoPressed);
		}
		
		if(maAction == MenuAction_Cancel) 
			PrintToChat(iClient, "Exit");
		
		delete mMenu;
		return -1;
	}
	return -1;
}


bool IsValidClient(int iClient) 
{ 
	if(iClient <= 0) 
		return false; 
	
	if(iClient > MaxClients) 
		return false; 
	
	if( !IsClientConnected(iClient) ) 
		return false; 
	
	return IsClientInGame(iClient); 
}

