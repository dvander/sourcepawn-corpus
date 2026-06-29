#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <multicolors>

#define VALUE 32
#define KVNAME "MenuItem"

int gI_Setting[MAXPLAYERS+1] = 0;
int menuDisplay;
int button_Dontshow;
int roundEnd_Menu;
int item;
int playerEvent;

ConVar delayToshow;
ConVar menuTime;
ConVar dontShow;
ConVar roundEnd;
ConVar eventMenu;
ConVar chatPrefix;

char gC_Path[PLATFORM_MAX_PATH];
char prefix[64];

bool gB_RoundEnd;
bool gB_MenuOpen[MAXPLAYERS+1] = false;

Handle gH_Cookie;
float menuDelay;

Menu gH_Menu = null;
KeyValues kv;

enum kvFile
{
	String:Id[8],
	String:itemName[64],
	String:itemCommand[64]
};

menuItem[VALUE][kvFile];

public Plugin myinfo = 
{
	name = "CSGO: MenuItem Commands",
	author = "Mish0UUU",
	description	= "Open a menu on player event",
	version = "1.1",
	url = "wwww.balkanstar.fr"
};

public void OnPluginStart()
{
	loadMenu();
	
	gH_Cookie = RegClientCookie("savemenu", "savemenu", CookieAccess_Protected);

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd);
	
	RegConsoleCmd("sm_menu", Cmd_MenuEvent);
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(AreClientCookiesCached(client)) 
				OnClientCookiesCached(client);
		}
	}
	
	delayToshow = CreateConVar("sm_menu_delay", "0.5", "Delay to send menu", FCVAR_NOTIFY, true, 0.0);
	menuTime = CreateConVar("sm_menu_display_time", "10", "Display menu time", FCVAR_NOTIFY, true, 0.0);	
	dontShow = CreateConVar("sm_menu_dontshow_button", "1", "Enable button 'Dont show again menu", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	roundEnd = CreateConVar("sm_menu_roundend_menu", "0", "Send menu when round is ending", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	eventMenu = CreateConVar("sm_menu_event", "1", "Event to send a menu 1 = PLAYER DEATH | 2 = PLAYER SPAWN", FCVAR_NOTIFY, true, 1.0, true, 2.0);
	chatPrefix =  CreateConVar("sm_menu_prefix", "[{green}MenuItem{default}] ", "Chat prefix");
	
	HookConVarChange(delayToshow, OnConVarChanged);
	HookConVarChange(menuTime, OnConVarChanged);
	HookConVarChange(dontShow, OnConVarChanged);
	HookConVarChange(roundEnd, OnConVarChanged);
	HookConVarChange(eventMenu, OnConVarChanged);
	HookConVarChange(chatPrefix, OnConVarChanged);
	
	menuDelay = GetConVarFloat(delayToshow);
	menuDisplay = GetConVarInt(menuTime);
	button_Dontshow = GetConVarInt(dontShow);
	roundEnd_Menu = GetConVarInt(roundEnd);
	playerEvent = GetConVarInt(eventMenu);
	GetConVarString(chatPrefix, prefix, sizeof(prefix));
	
	AutoExecConfig(true, "plugins.menu_itemcmd");	
	LoadTranslations("menu_itemcmd.phrases");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == delayToshow) 
		menuDelay = GetConVarFloat(delayToshow);
	else if(convar == menuTime) 
		menuDisplay = GetConVarInt(menuTime);
	else if(convar == dontShow) 
		button_Dontshow = GetConVarInt(dontShow);
	else if(convar == roundEnd) 
		roundEnd_Menu = GetConVarInt(roundEnd);
	else if(convar == eventMenu) 
		playerEvent = GetConVarInt(eventMenu);
	else if(convar == chatPrefix)
		GetConVarString(chatPrefix, prefix, sizeof(prefix));	
}

public void OnClientCookiesCached(int client)
{
	char sCookieValue[12];
	GetClientCookie(client, gH_Cookie, sCookieValue, sizeof(sCookieValue));
	gI_Setting[client] = StringToInt(sCookieValue);
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dB)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
		
	if(gB_MenuOpen[client])
		closeClientmenu(client);
		
	if(playerEvent != 1)
		return;
		
	CreateMenu_(client);
}

public void CreateMenu_(int id)
{
	if(GameRules_GetProp("m_bWarmupPeriod") != 1) 
	{		
		if(gI_Setting[id] > 0)
			return;			
		if(GetClientTeam(id) < 2)
			return;
			
		CreateTimer(menuDelay, Timer_ShowMenu, id);
	}
}

public Action Timer_ShowMenu(Handle timer, any userid)
{
	if(!IsClientInGame(userid))
		return Plugin_Handled;	
	if(gB_RoundEnd)
		return Plugin_Handled;
	if(playerEvent == 1 && IsPlayerAlive(userid))
		return Plugin_Handled;
		
	gB_MenuOpen[userid] = true;
		
	gH_Menu = new Menu(MenuHandler);
	
	char sTitle[32];
	Format(sTitle, sizeof(sTitle), "%t\n ", "MENU_TITLE");
	
	gH_Menu.SetTitle(sTitle);	
	
	char Item[32];
	for(int i = 0; i < item; ++i) 
	{
		if(menuItem[i][Id] > 0)
		{
			Format(Item, 16, "%i", i);
			gH_Menu.AddItem(Item, menuItem[i][itemName]);
			//PrintToChatAll("%i %s", i, menuItem[i][itemName]);
		}
	}
		
	if(button_Dontshow)
	{
		char sButton[64];
		Format(sButton, sizeof(sButton), "%t", "MENU_DONT_SHOW_AGAIN");
		gH_Menu.AddItem("-1", sButton); 
	}

	gH_Menu.ExitButton = true;	
	gH_Menu.Display(userid, menuDisplay);
		
	return Plugin_Handled;
}

public int MenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
    {             
		char sInfo[64];
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo));   
		int param = StringToInt(sInfo);
		if(param == -1)
		{
			gI_Setting[client] = 1;
			SetClientCookie(client, gH_Cookie, "1");
			CPrintToChat(client, "%s%t", prefix, "MENU_DISABLED");
		}
		else
		{							
			FakeClientCommand(client, menuItem[param][itemCommand]);
			//PrintToChatAll("itemName: %s | command: %s", menuItem[param][itemName], menuItem[param][itemCommand]);			
		}
	}
	else if(action == MenuAction_End)
		delete menu;
	else if(action == MenuAction_Cancel)
		gB_MenuOpen[client] = false;
	return 0;
}	

public Action Cmd_MenuEvent(int client, int args)
{
	if(gI_Setting[client] == 0)
	{
		gI_Setting[client] = 1;
		SetClientCookie(client, gH_Cookie, "1");
		CPrintToChat(client, "%s%t", prefix, "MENU_DISABLED");
	}
	else
	{
		gI_Setting[client] = 0;
		SetClientCookie(client, gH_Cookie, "0");	
		CPrintToChat(client, "%s%t", prefix, "MENU_ENABLED");
	}
}

public void Event_RoundStart(Handle event, const char[] name, bool dB) 
{
	gB_RoundEnd = false;
}

public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(!roundEnd_Menu) 
		gB_RoundEnd = true;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(gB_MenuOpen[client])
		closeClientmenu(client);
		
	if(playerEvent != 2)
		return;

	CreateMenu_(client);
}

stock void closeClientmenu(int client)
{
	Menu menu = new Menu(MenuHandler_CloseMenu);
	menu.SetTitle("none");
	DisplayMenu(menu, client, 1);
}

public int MenuHandler_CloseMenu(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
		delete menu;
}

public void loadMenu() 
{
	BuildPath(Path_SM, gC_Path, sizeof(gC_Path), "configs/menu_itemcmd.cfg");
	kv = new KeyValues(KVNAME);
	
	kv.ImportFromFile(gC_Path);	
	
	item = 1;
	if(!kv.GotoFirstSubKey())
	{
		SetFailState("File config not installed in addons/sourcemod/%d", gC_Path);
		delete kv;
	}
	do
	{		
		kv.GetSectionName(menuItem[item][Id], 8);    
		kv.GetString("item", menuItem[item][itemName], 64);
		kv.GetString("command", menuItem[item][itemCommand], 64);
		item++;
		
	}while(kv.GotoNextKey());	

	delete kv;
}

