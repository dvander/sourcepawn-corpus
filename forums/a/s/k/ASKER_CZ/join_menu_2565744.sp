#include <sourcemod>
#include <clientprefs>

Handle g_hMySelection;
int MenuShow[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Join Menu - Info Panel",
    author = "IMMENSE-GAMING.COM",
    description = "Info panel",
    version = "6.9",
	url = "IMMENSE-GAMING.COM"
};

public void OnPluginStart()
{
	LoadTranslations("join_menu.phrases");
	
	RegConsoleCmd("sm_menu", ShowMenu);
	RegConsoleCmd("sm_help", ShowMenu);
	
	g_hMySelection = RegClientCookie("info_menu", "Info Panel", CookieAccess_Private);
	
	HookEvent("player_spawn", Event_Spawn);
	AutoExecConfig(true, "join_menu");
	
	GetClientsCookies();
}

public void GetClientsCookies() {

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientValid(i) && AreClientCookiesCached(i)) {
			GetCookieValue(i);
		}
	}
}

public Action ShowMenu(int client, int args)
{
	if (IsClientValid(client))
		InfoMenu(client);
}


public Action Event_Spawn(Event gEventHook, const char[] gEventName, bool iDontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(gEventHook, "userid"));
	
	if (MenuShow[client])
		CreateTimer(3.0, Timer_ShowMenu, client);
}

public Action Timer_ShowMenu(Handle timer, int client) {

	if (IsClientValid(client))
		InfoMenu(client);
}

public Action InfoMenu(int client)
{
	char playerNick[64];
	char translationString[256];
	
	GetClientName(client, playerNick, sizeof(playerNick));

	Menu menu = new Menu(InfoMenuHandler);
	
	Format(translationString, sizeof(translationString), "%t \n¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯", "Menu Title", playerNick)
	menu.SetTitle(translationString);
	
	Format(translationString, sizeof(translationString), "%t", "Line 1")
	menu.AddItem("$line1", translationString, ITEMDRAW_DISABLED);
	Format(translationString, sizeof(translationString), "%t", "Line 2")
	menu.AddItem("$line2", translationString, ITEMDRAW_DISABLED);
	Format(translationString, sizeof(translationString), "%t", "Line 3")
	menu.AddItem("$line3", translationString, ITEMDRAW_DISABLED);
	Format(translationString, sizeof(translationString), "%t \n \n", "Line 4")
	menu.AddItem("$line4", translationString, ITEMDRAW_DISABLED);
	Format(translationString, sizeof(translationString), "%t  \n", "Info Line")
	menu.AddItem("$line6", translationString, ITEMDRAW_DISABLED);
	
	Format(translationString, sizeof(translationString), "%t",  MenuShow[client] ? "Do Not Show" : "Show Again");
	menu.AddItem("$doNotShow", translationString);
	
	menu.ExitButton = true;
	menu.Display(client, 30);
 
	return Plugin_Handled;
}

public int InfoMenuHandler(Menu menu, MenuAction action, int client, int position)
{
	if (IsClientValid(client)) {
		
		if (action == MenuAction_Select) {

			char item[64];
			menu.GetItem(position, item, sizeof(item));
			
			if(StrEqual(item, "$doNotShow", true)) {
				
				char sCookieValue[3];
				MenuShow[client] = !MenuShow[client];
				
				IntToString(MenuShow[client], sCookieValue, sizeof(sCookieValue));
				SetClientCookie(client, g_hMySelection, sCookieValue);
				
				delete menu;
			} 
		} else if (action == MenuAction_End) {
			delete menu;
		}
	}
}

public void OnClientPostAdminCheck(int client)
{	
	GetCookieValue(client);
}

public void GetCookieValue(int client)
{
	char sCookieValue[3];
	
	GetClientCookie(client, g_hMySelection, sCookieValue, sizeof(sCookieValue));
	
	if(strlen(sCookieValue) > 0) 
		MenuShow[client] = StringToInt(sCookieValue);
	else 
		MenuShow[client] = true;
}

public bool IsClientValid(int client) {
	
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client)) 
		return true;
		
	return false;
}