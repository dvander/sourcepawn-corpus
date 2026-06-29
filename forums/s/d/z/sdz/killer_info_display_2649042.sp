#include <sourcemod>
#include <clientprefs>
#include <morecolors>

#pragma semicolon 1

#define PLUGINVERSION		"2.0r"
char CHATTAG[32] = {"{green}[Killer Info]"};

public Plugin myinfo =
{
	name		= "Killer Info Display Redux",
	author		= "sdz, berni & co.",
	description	= "Displays the health, the armor and the weapon of the player who has killed you",
	version		= "2.0",
	url			= "http://forums.alliedmods.net/showthread.php?p=670361"
};

//Global variable jazz:

//Convars:
ConVar g_hCV_Version; //kid_version

ConVar g_hCV_HeaderTag; //kid_header

bool g_PrintToChat;
ConVar g_hCV_PrintToChat; //kid_printtochat

bool g_PrintToPanel;
ConVar g_hCV_PrintToPanel; //kid_printtopanel

bool g_ShowWeapon;
ConVar g_hCV_ShowWeapon; //kid_showweapon

bool g_ShowArmorLeft;
ConVar g_hCV_ShowArmorLeft; //kid_showarmorleft

bool g_ShowDistance;
ConVar g_hCV_ShowDistance; //kid_showdistance

char g_DistanceType[16];
ConVar g_hCV_DistanceType; //kid_distancetype

float g_AnnounceTime;
ConVar g_hCV_AnnounceTime; //kid_announcetime

int g_DefaultPref;
ConVar g_hCV_DefaultPref; //kid_defaultpref

//Player stuff:
bool g_Enabled[MAXPLAYERS + 1] = {true, ...};

Handle g_Cookie = null;
bool g_CookieEnabled;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{ 
    MarkNativeAsOptional("GetUserMessageType"); 
    return APLRes_Success;
}

public void CheckConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_hCV_PrintToChat) g_PrintToChat = view_as<bool>(StringToInt(newValue));
	else if(convar == g_hCV_HeaderTag) strcopy(CHATTAG, sizeof(CHATTAG), newValue);
	else if(convar == g_hCV_PrintToPanel) g_PrintToPanel = view_as<bool>(StringToInt(newValue));
	else if(convar == g_hCV_ShowWeapon) g_ShowWeapon = view_as<bool>(StringToInt(newValue));
	else if(convar == g_hCV_ShowArmorLeft) g_ShowArmorLeft = view_as<bool>(StringToInt(newValue));
	else if(convar == g_hCV_ShowDistance) g_ShowDistance = view_as<bool>(StringToInt(newValue));
	else if(convar == g_hCV_DistanceType) strcopy(g_DistanceType, sizeof(g_DistanceType), newValue);
	else if(convar == g_hCV_AnnounceTime) g_AnnounceTime = StringToFloat(newValue);
	else if(convar == g_hCV_DefaultPref) g_DefaultPref = StringToInt(newValue);
}

public void OnPluginStart()
{
	g_hCV_Version = CreateConVar("kid_version", PLUGINVERSION, "Killer info display plugin version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	SetConVarString(g_hCV_Version, PLUGINVERSION);

	g_hCV_HeaderTag = CreateConVar("kid_header", CHATTAG, "The header that the plugin should print");
	g_hCV_HeaderTag.AddChangeHook(CheckConVarChanged);

	g_hCV_PrintToChat = CreateConVar("kid_printtochat", "1", "Prints the killer info to the victims chat");
	g_hCV_PrintToChat.AddChangeHook(CheckConVarChanged);

	g_hCV_PrintToPanel = CreateConVar("kid_printtopanel", "1", "Displays the killer info to the victim as a panel");
	g_hCV_PrintToPanel.AddChangeHook(CheckConVarChanged);

	g_hCV_ShowWeapon = CreateConVar("kid_showweapon", "1", "Set to 1 to show the weapon the player got killed with, 0 to disable.");
	g_hCV_ShowWeapon.AddChangeHook(CheckConVarChanged);

	g_hCV_ShowArmorLeft = CreateConVar("kid_showarmorleft", "1", "Set to 0 to disable, 1 to show the armor, 2 to show the suitpower the killer has left.");
	g_hCV_ShowArmorLeft.AddChangeHook(CheckConVarChanged);

	g_hCV_ShowDistance = CreateConVar("kid_showdistance", "1", "Set to 1 to show the distance to the killer, 0 to disable.");
	g_hCV_ShowDistance.AddChangeHook(CheckConVarChanged);

	g_hCV_DistanceType = CreateConVar("kid_distancetype", "meters", "Set to \"meters\" to show the distance in \"meters\" or \"feet\" for feet.");
	g_hCV_DistanceType.AddChangeHook(CheckConVarChanged);

	g_hCV_AnnounceTime = CreateConVar("kid_announcetime", "5", "Time in seconds after an announce about turning killer infos on/off is printed to chat, set to -1 to disable.");
	g_hCV_AnnounceTime.AddChangeHook(CheckConVarChanged);

	g_hCV_DefaultPref = CreateConVar("kid_defaultpref", "1", "Default client preference (0 - killer info display off, 1 - killer info display on)");
	g_hCV_DefaultPref.AddChangeHook(CheckConVarChanged);

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	//Create/Load Config:
	AutoExecConfig(true);

	//Translations stuff:
	LoadTranslations("killer_info_display.phrases");
	
	g_CookieEnabled = (GetExtensionFileStatus("clientprefs.ext") == 1);

	if(g_CookieEnabled) 
	{
		// prepare title for clientPref menu
		char title[64];
		Format(title, sizeof(title), "%T", "name", LANG_SERVER);
		SetCookieMenuItem(DrawPrefMenu, 0, title);
		g_Cookie = RegClientCookie("killerinfo", "Enable (\"on\") / Disable (\"off\") Display of Killer Info", CookieAccess_Public);

		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				if(!AreClientCookiesCached(i)) continue;
				MarkClientReady(i);
			}
		}
	}

	RegConsoleCmd("sm_killerinfo", Command_KillerInfo, "On/Off Killer info display");
}

public void OnConfigsExecuted()
{
	g_PrintToChat = g_hCV_PrintToChat.BoolValue;
	g_PrintToPanel = g_hCV_PrintToPanel.BoolValue;
	g_ShowWeapon = g_hCV_ShowWeapon.BoolValue;
	g_ShowArmorLeft = g_hCV_ShowArmorLeft.BoolValue;
	g_ShowDistance = g_hCV_ShowDistance.BoolValue;
	g_hCV_DistanceType.GetString(g_DistanceType, sizeof(g_DistanceType));
	g_AnnounceTime = g_hCV_AnnounceTime.FloatValue;
	g_DefaultPref = g_hCV_DefaultPref.IntValue;
}

public void OnClientCookiesCached(int client)
{
	if(IsClientInGame(client)) MarkClientReady(client);
}

public void OnClientConnected(int client)
{
	g_Enabled[client] = true;
}

public void OnClientPutInServer(int client)
{
	if(g_CookieEnabled && AreClientCookiesCached(client)) MarkClientReady(client);
}


public void DrawPrefMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_SelectOption) DisplaySettingsMenu(client);
}

public int Handler_PrefMenu(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char pref[8];
			menu.GetItem(selection, pref, sizeof(pref));

			g_Enabled[client] = view_as<bool>(StringToInt(pref));

			if(g_Enabled[client]) SetClientCookie(client, g_Cookie, "on");
			else SetClientCookie(client, g_Cookie, "off");
			DisplaySettingsMenu(client);
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Command_KillerInfo(int client, int args)
{
	//Server Console:
	if (client == 0) 
	{
		ReplyToCommand(client, "[Killer Info] This command can only be run by players.");
		return Plugin_Handled;
	}

	if(g_Enabled[client]) 
	{
		g_Enabled[client] = false;

		CReplyToCommand(client, "%s {default}%t", CHATTAG, "kid_disabled");
		if(g_CookieEnabled) SetClientCookie(client, g_Cookie, "off");
	}
	else 
	{
		g_Enabled[client] = true;
		CReplyToCommand(client, "%s {N}%t", CHATTAG, "kid_enabled");
		if(g_CookieEnabled) SetClientCookie(client, g_Cookie, "on");
	}

	return Plugin_Handled;
}

public Action Timer_Announce(Handle timer, any data)
{
	int client = GetClientFromSerial(data);

	//Check for invalid client serial
	if(client == 0) return Plugin_Stop;
	CPrintToChatEx(client, client, "%s {default}%t", CHATTAG, "announcement");
	return Plugin_Stop;
}

public Action Event_PlayerDeath(Event e, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(e.GetInt("userid"));
	int attacker = GetClientOfUserId(e.GetInt("attacker"));
	bool dominated = e.GetBool("dominated", false);
	bool revenge = e.GetBool("revenge", false);

	if(client == 0 || attacker == 0 || client == attacker) return Plugin_Continue;
	if(!g_Enabled[client]) return Plugin_Continue;

	char weapon[32], unitType[8], distanceType[5];
	int armor;
	float distance;
	int healthLeft = GetClientHealth(attacker);

	e.GetString("weapon", weapon, sizeof(weapon));		
	if(g_ShowArmorLeft) armor = GetClientArmor(client);

	if(g_ShowDistance)
	{
		float cOrigin[3], aOrigin[3];
		GetClientAbsOrigin(client, cOrigin);
		GetClientAbsOrigin(attacker, aOrigin);
		distance = GetVectorDistance(cOrigin, aOrigin);
		
		//0.01905m = 1 source game unit
		//3.2808399m = 1 imperial foot
		//from math.inc in smlib
		if (StrEqual(distanceType, "feet", false)) 
		{
			distance = (distance * 0.01905) * 3.2808399;
			Format(unitType, sizeof(unitType), "%t", "feet");
		}
		else 
		{
			distance = distance * 0.01905;
			Format(unitType, sizeof(unitType), "%t", "meters");
		}
	}

	//Print To Chat?
	if(g_PrintToChat) 
	{
		char weaponFmt[64];
		char distanceFmt[64];
		char armorFmt[64];
			
		if(g_ShowWeapon) Format(weaponFmt, sizeof(weaponFmt), " %t", "chat_weapon", weapon);	
		if(g_ShowDistance) Format(distanceFmt, sizeof(distanceFmt), " %t", "chat_distance", distance, unitType);
		if(g_ShowArmorLeft && armor > 0) Format(armorFmt, sizeof(armorFmt), " %t", "chat_armor", armor, g_ShowArmorLeft ? "armor" : "suitpower");

		CPrintToChatEx(client, attacker, "%s {default}%t", CHATTAG, "chat_basic", attacker, weaponFmt, distanceFmt, healthLeft, armorFmt);

		if(dominated) CPrintToChatEx(client, attacker, "%s {default}%t", CHATTAG, "dominated", attacker);
		if(revenge) CPrintToChatEx(client, attacker, "%s {default}%t", CHATTAG, "revenge", attacker);
	}

	// Print To Panel ?
	if(g_PrintToPanel)
	{
		Panel panel = new Panel();
		char buffer[128];

		Format(buffer, sizeof(buffer), "%t", "panel_killer", attacker);
		panel.SetTitle(buffer, false);
		panel.DrawItem("", ITEMDRAW_SPACER);
		
		if(g_ShowWeapon)
		{
			Format(buffer, sizeof(buffer), "%t", "panel_weapon", weapon);
			panel.DrawItem(buffer, ITEMDRAW_DEFAULT);
		}

		Format(buffer, sizeof(buffer), "%t", "panel_health", healthLeft);
		panel.DrawItem(buffer, ITEMDRAW_DEFAULT);

		if(g_ShowArmorLeft && armor > 0)
		{
			Format(buffer, sizeof(buffer), "%t", "panel_armor", g_ShowArmorLeft ? "armor" : "suitpower", armor);
			panel.DrawItem(buffer, ITEMDRAW_DEFAULT);
		}

		if(g_ShowDistance)
		{
			Format(buffer, sizeof(buffer), "%t", "panel_distance", distance, unitType);
			panel.DrawItem(buffer, ITEMDRAW_DEFAULT);
		}
		
		panel.DrawItem("", ITEMDRAW_SPACER);

		if(dominated)
		{
			char strippedText[64];
			Format(buffer, sizeof(buffer), "%t", "dominated", attacker);

			//Add to panel by removing color codes:
			CReplaceColorCodes(strippedText, _, true, sizeof(strippedText));
			panel.DrawItem(strippedText, ITEMDRAW_DEFAULT);
		}

		if(revenge)
		{
			char strippedText[64];
			Format(buffer, sizeof(buffer), "%t", "revenge", attacker);

			//Add to panel by removing color codes:
			CReplaceColorCodes(strippedText, _, true, sizeof(strippedText));
			panel.DrawItem(strippedText, ITEMDRAW_DEFAULT);
		}

		panel.CurrentKey = 10;
		panel.Send(client, Handler_DoNothing, 20);
		delete panel;
	}

	return Plugin_Continue;
}

public int Handler_DoNothing(Handle menu, MenuAction action, int param1, int param2) {}

void MarkClientReady(int client)
{
	char preference[8];
	GetClientCookie(client, g_Cookie, preference, sizeof(preference));

	//Sets default to default:
	if (StrEqual(preference, "")) g_Enabled[client] = view_as<bool>(g_DefaultPref);
	else g_Enabled[client] = !StrEqual(preference, "off", false);

	//Less than 0 timer = don't create timer:
	if(g_AnnounceTime > 0.0) CreateTimer(g_AnnounceTime, Timer_Announce, GetClientSerial(client));
}

void DisplaySettingsMenu(int client)
{
	char MenuItem[128];
	Menu menu = new Menu(Handler_PrefMenu);

	Format(MenuItem, sizeof(MenuItem), "%t", "name");
	menu.SetTitle(MenuItem);

	char checked[] = view_as<char>(0x9A88E2);
	
	Format(MenuItem, sizeof(MenuItem), "%t [%s]", "enabled", g_Enabled[client] ? checked : "   ");
	menu.AddItem("1", MenuItem);

	Format(MenuItem, sizeof(MenuItem), "%t [%s]", "disabled", g_Enabled[client] ? "   " : checked);
	menu.AddItem("0", MenuItem);

	menu.Display(client, MENU_TIME_FOREVER);
}
