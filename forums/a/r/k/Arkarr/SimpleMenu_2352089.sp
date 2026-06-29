#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR "Arkarr"
#define PLUGIN_VERSION "1.00"

Handle CVAR_CommandName;
Handle ARRAY_Items;
Handle mainMenu;

char commandStr[45];

public Plugin myinfo = 
{
	name = "[ANY] Simple Menus", 
	author = PLUGIN_AUTHOR, 
	description = "Create a very simples customs menus", 
	version = PLUGIN_VERSION, 
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	CVAR_CommandName = CreateConVar("sm_simplemenu_command", "sm_helpmenu", "Set the command to display the menu");
}

public void OnConfigsExecuted()
{
	ARRAY_Items = CreateArray();
	
	if(!ReadConfigFile())
	{
		PrintToServer(">>>> SimpleMenu.smx <<<<");
		PrintToServer(">>>> ERROR WHILE CREATINGS THE MENU, CONFIG FILE CORRUPTED OR MISSING ! <<<<");
	}
	else
	{
		CreateCustomMenu();
	}
	
	GetConVarString(CVAR_CommandName, commandStr, sizeof(commandStr));
	RegConsoleCmd(commandStr, CMD_DisplayMainMenu, "Display the main menu.");
}

public Action CMD_DisplayMainMenu(client, args)
{
	if(GetArraySize(ARRAY_Items) <= 0)
	{
		PrintToChat(client, "No menu founds.");
		return Plugin_Continue;
	}
	
	DisplayMenu(mainMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Continue;
}

public int Panel_Handler(Menu menu, MenuAction action, int client, int itemSelectionIndex)
{
	if (action == MenuAction_Select)
		DisplayMenu(mainMenu, client, MENU_TIME_FOREVER);
}

public MainMenu_Handler(Handle menu, MenuAction action, int client, int itemSelectionIndex)  
{  
    char index[32];  
    GetMenuItem(menu, itemSelectionIndex, index, sizeof(index));  
    
    if (action == MenuAction_Select)  
    {
    	Handle tmpTrie = GetArrayCell(ARRAY_Items, StringToInt(index));
        Handle panel = CreatePanel();
        char panelTitle[45];
        char itemInfo[125];
        GetTrieString(tmpTrie, "itemName", panelTitle, sizeof(panelTitle));
        SetPanelTitle(panel, panelTitle);
        
        GetTrieString(tmpTrie, "InfoLine1", itemInfo, sizeof(itemInfo));
        DrawPanelText(panel, itemInfo);
        
        GetTrieString(tmpTrie, "InfoLine2", itemInfo, sizeof(itemInfo));
        DrawPanelText(panel, itemInfo);
        
        GetTrieString(tmpTrie, "InfoLine3", itemInfo, sizeof(itemInfo));
        DrawPanelText(panel, itemInfo);
        
        GetTrieString(tmpTrie, "InfoLine4", itemInfo, sizeof(itemInfo));
        DrawPanelText(panel, itemInfo);
        
        DrawPanelItem(panel, "Okay, bring me back.", ITEMDRAW_CONTROL);
        
        SendPanelToClient(panel, client, Panel_Handler, 60);
    }
}

stock void CreateCustomMenu()
{
	mainMenu = CreateMenu(MainMenu_Handler); 
	SetMenuTitle(mainMenu, "Please, select a choice :"); 
	
	char index[10];
	char itemName[10];
	for(int i = 0; i < GetArraySize(ARRAY_Items); i++)
	{
		IntToString(i, index, sizeof(index));
		Handle tmpTrie = GetArrayCell(ARRAY_Items, i);
		GetTrieString(tmpTrie, "itemName", itemName, sizeof(itemName));
		AddMenuItem(mainMenu, index, itemName);
	}
	
	SetMenuExitButton(mainMenu, true); 
}

stock bool ReadConfigFile()
{
	char path[100];
	Handle kv = CreateKeyValues("SimpleMenuItems");
	BuildPath(Path_SM, path, sizeof(path), "/configs/SimpleMenu.cfg");
	FileToKeyValues(kv, path);
	
	if (!KvGotoFirstSubKey(kv))
	return false;
	
	char itemName[45];
	char infoLine[125];
	do
	{
		Handle itemInfo = CreateTrie();
		KvGetSectionName(kv, itemName, sizeof(itemName));
		SetTrieString(itemInfo, "itemName", itemName);
		
		KvGetString(kv, "InfoLine1", infoLine, sizeof(infoLine));
		SetTrieString(itemInfo, "InfoLine1", infoLine);
		
		KvGetString(kv, "InfoLine2", infoLine, sizeof(infoLine));
		SetTrieString(itemInfo, "InfoLine2", infoLine);
		
		KvGetString(kv, "InfoLine3", infoLine, sizeof(infoLine));
		SetTrieString(itemInfo, "InfoLine3", infoLine);
		
		KvGetString(kv, "InfoLine4", infoLine, sizeof(infoLine));
		SetTrieString(itemInfo, "InfoLine4", infoLine);
		
		PushArrayCell(ARRAY_Items, itemInfo);
		
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);
	
	return true;
}
