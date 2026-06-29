#include <sourcemod>

#pragma semicolon 1  
#pragma newdecls required

ConVar g_cvTitle;
char g_sMenuTitle[64];
Handle 	g_hMenuStringsArray;


public Plugin myinfo = 
{
	name        = "Youtubers",
	author      = "rohanlogs",
	version     = "0.0.1"
};


public void OnPluginStart()
{
	RegConsoleCmd	("sm_youtubers", fwMenuCmd);
	RegAdminCmd		("sm_refresh_menu", fwRefreshMenuData, ADMFLAG_RCON, "Refreshes menu data");
	
	g_cvTitle = CreateConVar("sm_menu_title", "[Youtubers]", "Set your title for the menu.");
	HookConVarChange(g_cvTitle, OnSettingChanged);
	
	g_hMenuStringsArray = CreateArray(128);
}


public void OnSettingChanged( Handle hCvar, const char[] sOld, const char[] sNew )
{
	if(hCvar == g_cvTitle)
	{
		strcopy( g_sMenuTitle, sizeof(g_sMenuTitle), sNew );
		FormatEx( g_sMenuTitle, sizeof(g_sMenuTitle), "%s \n \n", g_sMenuTitle );
	}
}


public void OnConfigsExecuted()
{
	g_cvTitle.GetString( g_sMenuTitle, sizeof(g_sMenuTitle) );
	FormatEx( g_sMenuTitle, sizeof(g_sMenuTitle), "%s \n \n", g_sMenuTitle );
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
    
	BuildPath( Path_SM, sFilePath, sizeof(sFilePath), "configs/streamers.ini" );	
	FileToKeyValues(hKeyValues, sFilePath);
    
	char sSection[128];
	char sGetString[128];
	
	if( !KvGotoFirstSubKey(hKeyValues) ) 
	{
		LogMessage("There was no entries found in streamers.ini !");
		if(iClient != 0) PrintToChat(iClient, "[SM] There was no entries found in streamers.ini !");
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
	
	if(iClient != 0) PrintToChat(iClient, "[SM] Menu refreshed successfully");
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

	mMenu.SetTitle(g_sMenuTitle);
	
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
	if( fwIsValidClient(iClient) )
	{
		if(maAction == MenuAction_Select)
		{
			char sInfoPressed[264];
			mMenu.GetItem( iParam, sInfoPressed, sizeof(sInfoPressed) );
			PrintToChat(iClient, "%s", sInfoPressed);
		}
		
		delete mMenu;
		return -1;
	}
	return -1;
}


bool fwIsValidClient(int iClient) 
{ 
	if(iClient <= 0) 
		return false; 
	
	if(iClient > MaxClients) 
		return false; 
	
	if( !IsClientConnected(iClient) ) 
		return false; 
	
	return IsClientInGame(iClient); 
}

