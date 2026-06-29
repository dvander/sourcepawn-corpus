
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vip_core>
#include <clientprefs>

#define VIP_NCROSSHAIR	"NCrosshair"
#define VIP_NCROSSHAIR_Menu	"NCrosshair_Menu"

#define PLUGIN_VERSION "1.5"
#pragma semicolon 1

Handle g_Cookie;
Handle killTimer;
bool g_Crosshair[MAXPLAYERS+1];
int g_clientItem[MAXPLAYERS+1];
char colors[20];
public Plugin myinfo = 
{
	name = "[VIP] Noscope Crosshair",
	author = "SLAYER",
	description = "Show Crosshair for Noscope for VIP players",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=293943"
};
public void OnPluginStart()
{
	g_Cookie = RegClientCookie("VIP_Crosshair", "VIP_Crosshair", CookieAccess_Private);
	RegConsoleCmd("sm_crosshair", DisplayColorsMenu, "Dispaly Crosshair Color Menu");
	LoadTranslations("vip_modules.phrases");
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	} 
}
public void VIP_OnVIPClientRemoved(int client, const char[] sReason, int admin)
{
	ClientCommand(client, "r_screenoverlay off");
	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}
public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_NCROSSHAIR, BOOL);
	VIP_RegisterFeature(VIP_NCROSSHAIR_Menu, _, SELECTABLE, OnSelectItem, _, OnDrawItem);
}
public void OnClientCookiesCached(int client)
{
    char sColor[64];
    GetClientCookie(client, g_Cookie, sColor, sizeof(sColor));

    if(sColor[0] == 0)
    {
        g_clientItem[client] = StringToInt(sColor);
    }
}
public VIP_OnVIPClientLoaded(client)
{
	if(VIP_GetClientFeatureStatus(client, VIP_NCROSSHAIR) != NO_ACCESS)
	{
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
		g_Crosshair[client] = VIP_IsClientFeatureUse(client, VIP_NCROSSHAIR);
		decl String:sColor[64];
		GetClientCookie(client, g_Cookie, sColor, 64);
		if(sColor[0] == 0)
		{
			g_clientItem[client] = StringToInt(sColor);
		}
	}
}
public Action OnWeaponSwitch(client, weapon)
{
	char weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (
	StrEqual(weaponname, "weapon_awp", false) || StrEqual(weaponname, "weapon_g3sg1", false)||
	StrEqual(weaponname, "weapon_sg550", false) || StrEqual(weaponname, "weapon_scout", false)||
	StrEqual(weaponname, "weapon_scar20", false) || StrEqual(weaponname, "weapon_ssg08", false)&& IsPlayerAlive(client))
	{
		ClientCommand(client, "r_screenoverlay slayer/%s", colors);
	}
	else{ClientCommand(client, "r_screenoverlay off");}
}
public void OnMapStart()
{
	AddFileToDownloadsTable("materials/slayer/red.vmt");
	AddFileToDownloadsTable("materials/slayer/red.vtf");
	AddFileToDownloadsTable("materials/slayer/blue.vmt");
	AddFileToDownloadsTable("materials/slayer/blue.vtf");
	AddFileToDownloadsTable("materials/slayer/green.vmt");
	AddFileToDownloadsTable("materials/slayer/green.vtf");
	PrecacheModel("materials/slayer/red.vmt", true);
	PrecacheModel("materials/slayer/green.vmt", true);
	PrecacheModel("materials/slayer/blue.vmt", true);
}
public Action CrosshairMenu(int client)
{
	if(!VIP_IsClientVIP(client) || !VIP_IsClientFeatureUse(client, VIP_NCROSSHAIR))
	{
		PrintToChat(client,"\x04[Noscope-Crosshair] \x01You don't have permission to this \x04Menu");
		return Plugin_Stop;
	}
	if(IsClientInGame(client) && VIP_IsClientVIP(client) && VIP_IsClientFeatureUse(client, VIP_NCROSSHAIR))
	{
		Menu g_ColorsMenu = new Menu(ColorsMenu, MenuAction_DisplayItem);
		g_ColorsMenu.SetTitle("Noscope Crosshair Colors");
		g_ColorsMenu.AddItem("Team","Team");
		g_ColorsMenu.AddItem("Red","Red");
		g_ColorsMenu.AddItem("Blue","Blue");
		g_ColorsMenu.AddItem("Green","Green");
		g_ColorsMenu.ExitBackButton = true;
		g_ColorsMenu.ExitButton = true;
		g_ColorsMenu.Display(client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public ColorsMenu(Menu g_ColorsMenu, MenuAction:action, client, Item)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) VIP_SendClientVIPMenu(client);
		}
		case MenuAction_Display:
		{
	 		char sBuffer[255];
			FormatEx(sBuffer, sizeof(sBuffer), "%T", "NCrosshair_Menu", client);
			SetPanelTitle(Handle:Item, sBuffer);
		}
		case MenuAction_Select:
		{
			char sColor[64];
			GetMenuItem(g_ColorsMenu, Item, sColor, sizeof(sColor));
			char item1[32];
			g_ColorsMenu.GetItem(Item, item1, sizeof(item1));
			g_clientItem[client] = Item;
			if(StrEqual(item1, "Team"))
			{
				SetClientCookie(client, g_Cookie, sColor);
				killTimer = null;
				ClientCommand(client, "r_screenoverlay off");
				PrintToChatAll("\x04[Noscope-Crosshair] \x01Your Crosshair Color is Changed to \x04Team");
				killTimer = CreateTimer(0.1, CrosshairTeam, _, TIMER_REPEAT);
			}
			if(StrEqual(item1, "Red"))
			{
				SetClientCookie(client, g_Cookie, sColor);
				killTimer = null;
				ClientCommand(client, "r_screenoverlay off");
				PrintToChatAll("\x04[Noscope-Crosshair] \x01Your Crosshair Color is Changed to \x04Red");
				killTimer = CreateTimer(0.1, CrosshairRed, _, TIMER_REPEAT);
			}
			if(StrEqual(item1, "Blue"))
			{
				SetClientCookie(client, g_Cookie, sColor);
				killTimer = null;
				ClientCommand(client, "r_screenoverlay off");
				PrintToChatAll("\x04[Noscope-Crosshair] \x01Your Crosshair Color is Changed to \x04Blue");
				killTimer = CreateTimer(0.1, CrosshairBlue, _, TIMER_REPEAT);
			}
			if(StrEqual(item1, "Green"))
			{
				SetClientCookie(client, g_Cookie, sColor);
				killTimer = null;
				ClientCommand(client, "r_screenoverlay off");
				PrintToChatAll("\x04[Noscope-Crosshair] \x01Your Crosshair Color is Changed to \x04Green");
				killTimer = CreateTimer(0.1, CrosshairGreen, _, TIMER_REPEAT);
			}
			CrosshairMenu(client);
		}
		case MenuAction_End:
		{
			delete g_ColorsMenu;
		}
		case MenuAction_DisplayItem:
		{
			if(g_clientItem[client] == Item)
			{
				char sColorName[64];
				GetMenuItem(g_ColorsMenu, Item, sColorName, sizeof(sColorName));
				Format(sColorName, sizeof(sColorName), "%s [✔]", sColorName);
				return RedrawMenuItem(sColorName);
			}
		}
	}
	return 0;
}
public OnDrawItem(Client, const String:sFeatureName[], menu)
{
	if(VIP_GetClientFeatureStatus(Client, VIP_NCROSSHAIR) != ENABLED)
	{
		return ITEMDRAW_DISABLED;
	}
	return menu;
}
public bool OnSelectItem(client, const String:sFeatureName[])
{
	CrosshairMenu(client);
	return false;
}
public Action DisplayColorsMenu(int client, int args)
{
    CrosshairMenu(client);
    return Plugin_Handled;
}
public Action CrosshairTeam(Handle timer, any data)
{
	if(killTimer == null)
    {
        return Plugin_Stop; // stop repeating timer
    }
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, VIP_NCROSSHAIR))
		{
			char weaponname[32];
			GetClientWeapon(i, weaponname, sizeof(weaponname));
			if (
			StrEqual(weaponname, "weapon_awp", false) || StrEqual(weaponname, "weapon_g3sg1", false)||
			StrEqual(weaponname, "weapon_sg550", false) || StrEqual(weaponname, "weapon_scout", false)||
			StrEqual(weaponname, "weapon_scar20", false) || StrEqual(weaponname, "weapon_ssg08", false)&& IsPlayerAlive(i))
			{
				ClientCommand(i, "r_screenoverlay off");// Remove previous crosshair
				int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
				SetCommandFlags("r_screenoverlay", iFlags);
				int clientTeam = GetClientTeam(i);
				if(clientTeam == 2){ClientCommand(i, "r_screenoverlay slayer/red.vmt");colors = "red.vmt";} // Team  T
				if(clientTeam == 3){ClientCommand(i, "r_screenoverlay slayer/blue.vmt");colors = "blue.vmt";} // Team CT
			}
			else{ClientCommand(i, "r_screenoverlay off");}
		}
	}
	return Plugin_Continue;
}
public Action CrosshairRed(Handle timer, any data)
{
	if(killTimer == null)
    {
        return Plugin_Stop; // stop repeating timer
    }
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, VIP_NCROSSHAIR))
		{
			char weaponname[32];
			GetClientWeapon(i, weaponname, sizeof(weaponname));
			if (
			StrEqual(weaponname, "weapon_awp", false) || StrEqual(weaponname, "weapon_g3sg1", false)||
			StrEqual(weaponname, "weapon_sg550", false) || StrEqual(weaponname, "weapon_scout", false)||
			StrEqual(weaponname, "weapon_scar20", false) || StrEqual(weaponname, "weapon_ssg08", false)&& IsPlayerAlive(i))
			{
				int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
				SetCommandFlags("r_screenoverlay", iFlags);
				ClientCommand(i, "r_screenoverlay slayer/red.vmt");
				colors = "red.vmt";
			}
			else{ClientCommand(i, "r_screenoverlay off");}
		}
	}
	return Plugin_Continue;
}
public Action CrosshairBlue(Handle timer, any data)
{
	if(killTimer == null)
    {
        return Plugin_Stop; // stop repeating timer
    }
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, VIP_NCROSSHAIR))
		{
			char weaponname[32];
			GetClientWeapon(i, weaponname, sizeof(weaponname));
			if (
			StrEqual(weaponname, "weapon_awp", false) || StrEqual(weaponname, "weapon_g3sg1", false)||
			StrEqual(weaponname, "weapon_sg550", false) || StrEqual(weaponname, "weapon_scout", false)||
			StrEqual(weaponname, "weapon_scar20", false) || StrEqual(weaponname, "weapon_ssg08", false)&& IsPlayerAlive(i))
			{
				int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
				SetCommandFlags("r_screenoverlay", iFlags);
				ClientCommand(i, "r_screenoverlay slayer/blue.vmt");
				colors = "blue.vmt";
			}
			else{ClientCommand(i, "r_screenoverlay off");}
		}
	}
	return Plugin_Continue;
}
public Action CrosshairGreen(Handle timer, any data)
{
	if(killTimer == null)
    {
        return Plugin_Stop; // stop repeating timer
    }
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, VIP_NCROSSHAIR))
		{
			char weaponname[32];
			GetClientWeapon(i, weaponname, sizeof(weaponname));
			if (
			StrEqual(weaponname, "weapon_awp", false) || StrEqual(weaponname, "weapon_g3sg1", false)||
			StrEqual(weaponname, "weapon_sg550", false) || StrEqual(weaponname, "weapon_scout", false)||
			StrEqual(weaponname, "weapon_scar20", false) || StrEqual(weaponname, "weapon_ssg08", false)&& IsPlayerAlive(i))
			{
				int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
				SetCommandFlags("r_screenoverlay", iFlags);
				ClientCommand(i, "r_screenoverlay slayer/green.vmt");
				colors = "green.vmt";
			}
			else{ClientCommand(i, "r_screenoverlay off");}
		}
	}
	return Plugin_Continue;
}