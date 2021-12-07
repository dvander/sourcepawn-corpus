
#define PLUGIN_NAME           "Server Information Panel(SIP)"
#define PLUGIN_AUTHOR         "spike1234"
#define PLUGIN_DESCRIPTION    "Provides a menu panel for display server information to players"
#define PLUGIN_VERSION        "1.1"
#define PLUGIN_URL            "https://forums.alliedmods.net/showthread.php?t=321134"

#include <sourcemod>
#include <sdktools>
#include <colors>

#pragma semicolon 1

#define MAXCATEGORIES 7

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

ConVar g_hEnable;
ConVar g_hNoteTiming;
ConVar g_hNoteType;
ConVar g_hNoteMax;
ConVar g_hReset;
ConVar g_hInsColor;
ConVar g_hForceOpen;
ConVar g_hPartition;
ConVar g_hTop;

Menu g_hMainMenu;
Menu g_hMenuCtg[MAXCATEGORIES];
int g_iItemNum[MAXCATEGORIES];
int g_iShowedTime[MAXPLAYERS];

public OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "translations/server_info_panel.phrases.txt");
	
	if(FileExists(sPath))
	LoadTranslations("server_info_panel.phrases");
	else
	ThrowError("could not find file: translations/server_info_panel.phrases.txt");
	
	g_hEnable = 	CreateConVar( "sm_sip_enable",				"1",		"[1:Enable], [0:Disable]");
	g_hNoteType = 	CreateConVar( "sm_sip_noteType",			"123",		"Way of showing note message.Input numbers you want to use. [(Empty):Disable], [1:Chat], [2:Hint Message], [3:Instructor Hint]");
	g_hNoteTiming = CreateConVar( "sm_sip_noteTiming",			"1234",		"When show note message to player. [(Empty):Disable], [1:On Joined], [2:On Opened Menu], [3:on closed menu], [4:on map start]");
	g_hNoteMax = 	CreateConVar( "sm_sip_noteMax",				"3",		"How many times show note message.");
	g_hReset = 		CreateConVar( "sm_sip_note_resetPerRound",	"1",		"Whether to reset note count on map chenged [0:Don't Reset] [1:Reset]");
	g_hInsColor = 	CreateConVar( "sm_sip_note_instructorColor","255 255 0","Color of instructor hint that shown by note message.");
	g_hForceOpen =	CreateConVar( "sm_sip_forceOpen",			"1",		"Whether to force player to open menu when player joined. [0:Don't Open] [1:Open]");
	g_hPartition = 	CreateConVar( "sm_sip_partition",			"12",		"Whether to draw partition line of message. [(Empty:Disable)] [1:Draw Before] [2:Draw After]");
	g_hTop = 		CreateConVar( "sm_sip_top",					"1",		"Whether to show top message(Tag + Item Name). [0:Disable] [1:Enable]");
	
	RegConsoleCmd("sm_helpmenu", sm_helpmenu, "Show sip help menu.");
	RegConsoleCmd("sm_sip_note_resetCount", ResetCount, "Reset note count for all players.", ADMFLAG_KICK);
	
	AutoExecConfig( true, "server_info_panel");
}

public Action sm_helpmenu(int client, int args)
{
	if(!g_hEnable.BoolValue) return Plugin_Continue;
	
	char sTiming[8];
	g_hNoteTiming.GetString(sTiming, sizeof(sTiming));
	if(StrContains(sTiming, "2") != -1) ShowNoteMsg(client);
	
	SetupMenus(client);
	g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

public Action ResetCount(int client, int args)
{
	for(int i=0; i < MAXPLAYERS; i++)
	{
		g_iShowedTime[i] = 0;
	}
}

void SetupMenus(int client)
{
	if(!IsClientInGame(client) || IsFakeClient(client)) return;
	
	//Get index number of each category
	for(int ctg = 1; ctg <= MAXCATEGORIES; ctg++)
	{
		g_iItemNum[ctg-1] = 0;
		for(int i = 1; ; i++)
		{
			char sCallSign[16];
			Format(sCallSign, sizeof(sCallSign), "C%d_%d", ctg, i);
			if(!TranslationPhraseExists(sCallSign)) break;
			g_iItemNum[ctg-1] = i;
		}
	}
	
	//Main Menu
	{
		g_hMainMenu = new Menu(MainMenuHandler);
		g_hMainMenu.SetTitle("%T", "MAIN TITLE", client);
		g_hMainMenu.ExitButton = true;
		g_hMainMenu.ExitBackButton = false;
		
		for(int ctg=1; ctg <= MAXCATEGORIES; ctg++)
		{
			char sCategoryName[16];
			char sBuffer[128];
			Format(sCategoryName, sizeof(sCategoryName), "CATEGORY%d", ctg);
			if(TranslationPhraseExists(sCategoryName))
			{
				Format(sBuffer, sizeof(sBuffer), "%T", sCategoryName, client);
				if(g_iItemNum[ctg-1] > 0)
				g_hMainMenu.AddItem("", sBuffer);
				else
				g_hMainMenu.AddItem("", sBuffer, ITEMDRAW_DISABLED);
			}
		}
	}
	
	//1-7Category Menu
	if(g_iItemNum[0] > 0) g_hMenuCtg[0] = new Menu(MenuCtg1Handler);
	if(g_iItemNum[1] > 0) g_hMenuCtg[1] = new Menu(MenuCtg2Handler);
	if(g_iItemNum[2] > 0) g_hMenuCtg[2] = new Menu(MenuCtg3Handler);
	if(g_iItemNum[3] > 0) g_hMenuCtg[3] = new Menu(MenuCtg4Handler);
	if(g_iItemNum[4] > 0) g_hMenuCtg[4] = new Menu(MenuCtg5Handler);
	if(g_iItemNum[5] > 0) g_hMenuCtg[5] = new Menu(MenuCtg6Handler);
	if(g_iItemNum[6] > 0) g_hMenuCtg[6] = new Menu(MenuCtg7Handler);
	for(int ctg=1; ctg <= MAXCATEGORIES; ctg++)
	{
		if(g_iItemNum[ctg-1] == 0) continue;
		
		char sCategoryName[16];
		Format(sCategoryName, sizeof(sCategoryName), "CATEGORY%d", ctg);
		g_hMenuCtg[ctg-1].SetTitle("%T", sCategoryName, client);
		g_hMenuCtg[ctg-1].ExitButton = true;
		g_hMenuCtg[ctg-1].ExitBackButton = true;
		
		for(int i = 1; i <= g_iItemNum[ctg-1]; i++)
		{
			char sBuffer[128];
			char sCallSign[16];
			Format(sCallSign, sizeof(sCallSign), "C%d_%d", ctg, i);
			if(TranslationPhraseExists(sCallSign))
			{
				Format(sBuffer, sizeof(sBuffer), "%T",  sCallSign, client);
				
				char sMsgIndex[16];
				Format(sMsgIndex, sizeof(sMsgIndex), "C%d_%d_1", ctg, i);
				if(TranslationPhraseExists(sMsgIndex))
				g_hMenuCtg[ctg-1].AddItem("", sBuffer);
				else
				g_hMenuCtg[ctg-1].AddItem("", sBuffer, ITEMDRAW_DISABLED);
			}
		}
	}
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	char sTiming[8];
	g_hNoteTiming.GetString(sTiming, sizeof(sTiming));
	
	switch(action)
	{
		case MenuAction_Select:
		{
			g_hMenuCtg[index].Display(client, MENU_TIME_FOREVER);
		}
		
		case MenuAction_Cancel:
		{
			if(StrContains(sTiming, "3") != -1 && index != MenuCancel_Interrupted) ShowNoteMsg(client);
		}
	}
}

public int MenuCtg1Handler(Menu menu, MenuAction action, int client, int index)
{
	CategoryMenuProcess(menu, action, client, index, 1);
}

public int MenuCtg2Handler(Menu menu, MenuAction action, int client, int index)
{
	CategoryMenuProcess(menu, action, client, index, 2);
}

public int MenuCtg3Handler(Menu menu, MenuAction action, int client, int index)
{
	CategoryMenuProcess(menu, action, client, index, 3);
}

public int MenuCtg4Handler(Menu menu, MenuAction action, int client, int index)
{
	CategoryMenuProcess(menu, action, client, index, 4);
}

public int MenuCtg5Handler(Menu menu, MenuAction action, int client, int index)
{
	CategoryMenuProcess(menu, action, client, index, 5);
}

public int MenuCtg6Handler(Menu menu, MenuAction action, int client, int index)
{
	CategoryMenuProcess(menu, action, client, index, 6);
}

public int MenuCtg7Handler(Menu menu, MenuAction action, int client, int index)
{
	CategoryMenuProcess(menu, action, client, index, 7);
}

public void CategoryMenuProcess(Menu menu, MenuAction action, int client, int index, int category)
{
	char sTiming[8];
	g_hNoteTiming.GetString(sTiming, sizeof(sTiming));
	
	switch(action)
	{
		case MenuAction_Select:
		{
			PrintHelpMessage(client, category, index);
			
			int iDisplayPos = (index/7)*7;
			g_hMenuCtg[category-1].DisplayAt(client, iDisplayPos, MENU_TIME_FOREVER);
		}
		
		case MenuAction_Cancel:
		{
			if(index == MenuCancel_ExitBack) 
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
			else
			if(index != MenuCancel_Interrupted && StrContains(sTiming, "2") != -1)
			ShowNoteMsg(client);
		}
	}
}

public void PrintHelpMessage(int client, int category, int index)
{
	char sTag[128];
	char sItemIndex[16];
	char sItemName[128];
	char sTop[256];
	char sMsgIndex[16];
	char sMsg[1024];
	
	if(g_hTop.BoolValue) //prepare top message
	{
		Format(sTag, sizeof(sTag), "%T\x01", "TAG", client);								//get tag
		
		Format(sItemIndex, sizeof(sItemIndex), "C%d_%d", category, index + 1);				//prepare item index
		Format(sItemName, sizeof(sItemName), "%T\x01", sItemIndex, client);					//get item name
		
		Format(sTop, sizeof(sTop), "%s\x01", sTag, client);									//get top message
		ReplaceString(sTop, sizeof(sTop), "{itemname}", sItemName);							//convert {itemname} to real
	}
	
	char sFlag[8]; //for check partition flag
	g_hPartition.GetString(sFlag, sizeof(sFlag));
	
	if(StrContains(sFlag, "1") != -1) PrintToChat(client, "%T\x01", "PARTITION", client);	//up partition
	
	if(g_hTop.BoolValue)CPrintToChat(client, sTop);											//display top message (TAG + ITEMNAME)
	for(int i=1; ;i++)																		//display all messages of item
	{
		Format(sMsgIndex, sizeof(sMsgIndex), "C%d_%d_%d", category, index + 1, i);			//prepare message index
		if(TranslationPhraseExists(sMsgIndex))
		{
			Format(sMsg, sizeof(sMsg), "%T\x01", sMsgIndex, client);						//get message
			CPrintToChat(client, sMsg);
		}
		else break;
	}
	if(StrContains(sFlag, "2") != -1) PrintToChat(client, "%T\x01", "PARTITION", client);	//down partition
}

public void ShowNoteMsg(int client)
{
	if(!g_hEnable.BoolValue) return;
	if(!IsClientInGame(client) || IsFakeClient(client)) return;
	
	if(g_iShowedTime[client] >= g_hNoteMax.IntValue) return;
	g_iShowedTime[client] ++;
	
	char sMsg[100];
	Format(sMsg, sizeof(sMsg), "%T", "NOTE", client);
	
	char sType[8];
	g_hNoteType.GetString(sType, sizeof(sType));
	
	if(StrContains(sType, "1") != -1)		//chat
	PrintToChat(client, "\x04%s", sMsg);
	
	if(StrContains(sType, "2") != -1)		//hint
	PrintHintText(client, "\x04%s", sMsg);
	
	if(StrContains(sType, "3") != -1)		//instructor
	{
		new entity = CreateEntityByName("env_instructor_hint");
		char sTemp[32];
		char sColor[12];
		FormatEx(sTemp, sizeof(sTemp), "hint%d", client);
		g_hInsColor.GetString(sColor, sizeof(sColor));
		DispatchKeyValue(client, "targetname", sTemp);
		DispatchKeyValue(entity, "hint_target", sTemp);
		DispatchKeyValue(entity, "hint_timeout", "10");
		DispatchKeyValue(entity, "hint_range", "0.01");
		DispatchKeyValue(entity, "hint_icon_onscreen", "icon_tip");
		DispatchKeyValue(entity, "hint_caption", sMsg);
		DispatchKeyValue(entity, "hint_color", sColor);
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "ShowHint");
		
		SetVariantString("OnUser1 !self:Kill::10:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

public void OnClientDisconnect(int client)
{
	g_iShowedTime[client] = 0;
}


public void OnClientPutInServer(int client)
{
	if(!g_hEnable.BoolValue) return;
	
	if(g_hForceOpen.BoolValue)
	{
		SetupMenus(client);
		g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	}
	else
	if(IsClientInGame(client) && !IsFakeClient(client))
	ShowNoteMsg(client);
}

public void OnMapStart()
{
	if(!g_hEnable.BoolValue) return;
	
	if(g_hReset.BoolValue) ServerCommand("sm_sip_note_resetCount");
	CreateTimer(60.0, ShowMsg);
}

public Action ShowMsg(Handle timer)
{
	if(!g_hEnable.BoolValue) return;
	
	for(int i=1; i<=MaxClients; i++)
	{
		g_iShowedTime[i] = 0;
		if(IsClientInGame(i) && !IsFakeClient(i))
		ShowNoteMsg(i);
	}
}
