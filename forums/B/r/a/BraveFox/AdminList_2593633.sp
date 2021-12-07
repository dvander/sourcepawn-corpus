#include <sourcemod>
#include <clientprefs>
#include <csgovip>
#define MAX_MESSAGE_LENGTH 256
Handle cookies = INVALID_HANDLE;
bool invis[MAXPLAYERS + 1];
public Plugin myinfo = 
{
	name = "Advanced Tags&AdminList", 
	author = "S4muRaY'", 
	description = "", 
	version = "1.0", 
	url = "http://steamcommunity.com/id/s4muray"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_admins", OpenMenu);
	cookies = RegClientCookie("AdminList", "admins 0 or 1", CookieAccess_Protected);
}
public Action OpenMenu(int client, int args)
{
	if (args > 0)
	{
		char yesorno[32];
		GetCmdArg(1, yesorno, sizeof(yesorno));
		if (StrEqual(yesorno, "1"))
		{
			ShowNoneInvis(client)
			invis[client] = false;
			SetClientCookie(client, cookies, "0");
		}
		else {
			ShowInvis(client);
			invis[client] = true;
			SetClientCookie(client, cookies, "1");
		}
		return Plugin_Handled;
	}
	if (!CheckCommandAccess(client, "", ADMFLAG_GENERIC))
	{
		showmenun(client);
	}
	else {
		showmenua(client);
	}
	return Plugin_Handled;
}
stock ShowInvis(int client)
{
	Handle menu = CreateMenu(ShowInvisM)
	SetMenuTitle(menu, "Admins List");
	AddMenuItem(menu, "Invis", "You are now invisible.");
	DisplayMenu(menu, client, 30);
}
stock ShowNoneInvis(int client)
{
	Handle menu = CreateMenu(ShowvisM)
	SetMenuTitle(menu, "Admins List");
	AddMenuItem(menu, "Vis", "You are now visible.");
	DisplayMenu(menu, client, 30);
}
stock showmenua(int client)
{
	int items = 1;
	Handle menu = CreateMenu(AdminListN);
	SetMenuTitle(menu, "Online Admins");
	AddMenuItem(menu, "vips", "VIP List");
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !CheckCommandAccess(i, "", ADMFLAG_ROOT) && CheckCommandAccess(i, "", ADMFLAG_GENERIC) && !invis[i])
		{
			char name[64];
			Format(name, MAX_NAME_LENGTH, "%N", i);
			AddMenuItem(menu, "", name);
			items++;
		}
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && CheckCommandAccess(i, "", ADMFLAG_ROOT) && !invis[i])
		{
			char name[64];
			Format(name, MAX_NAME_LENGTH, "%N -Root-", i);
			AddMenuItem(menu, "", name);
			items++;
		}
	}
	//Invis
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !CheckCommandAccess(i, "", ADMFLAG_ROOT) && CheckCommandAccess(i, "", ADMFLAG_GENERIC) && invis[i])
		{
			char name[64];
			Format(name, MAX_NAME_LENGTH, "[INVISIBLE]%N", i);
			AddMenuItem(menu, "", name);
			items++;
		}
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && CheckCommandAccess(i, "", ADMFLAG_ROOT) && invis[i] && CheckCommandAccess(client, "", ADMFLAG_ROOT))
		{
			char name[64];
			Format(name, MAX_NAME_LENGTH, "[INVISIBLE]%N -Root-", i);
			AddMenuItem(menu, "", name);
			items++;
		}
	}
	if (items == 1)
	{
		AddMenuItem(menu, "none", "No Admins Are Online Right Now");
	}
	DisplayMenu(menu, client, 30);
}
stock showmenun(int client)
{
	int items = 1;
	Menu menu = CreateMenu(AdminListN);
	SetMenuTitle(menu, "Online Admins");
	AddMenuItem(menu, "vips", "Online VIPs");
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !CheckCommandAccess(i, "", ADMFLAG_ROOT) && CheckCommandAccess(i, "", ADMFLAG_BAN) && !CheckCommandAccess(i, "", ADMFLAG_CHEATS) && !invis[i])
		{
			char name[64];
			Format(name, MAX_NAME_LENGTH, "%N", i);
			AddMenuItem(menu, "", name);
			items++;
		}
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !CheckCommandAccess(i, "", ADMFLAG_ROOT) && !CheckCommandAccess(i, "", ADMFLAG_BAN) && CheckCommandAccess(i, "", ADMFLAG_CHEATS) && !invis[i])
		{
			char name[64];
			Format(name, MAX_NAME_LENGTH, "%N -High-", i);
			AddMenuItem(menu, "", name);
			items++;
		}
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && CheckCommandAccess(i, "", ADMFLAG_ROOT) && !invis[i])
		{
			char name[64];
			Format(name, MAX_NAME_LENGTH, "%N -Root-", i);
			AddMenuItem(menu, "", name);
			items++;
		}
	}
	if (items == 1)
	{
		AddMenuItem(menu, "none", "No Admins Are Online Right Now");
	}
	DisplayMenu(menu, client, 30);
}
public int AdminListN(Handle menu, MenuAction:action, int client, int itemNum)
{
	if(action == MenuAction_Select)
	{
		char sInfo[32];
		GetMenuItem(menu, itemNum, sInfo, sizeof(sInfo));
		if(StrEqual(sInfo, "vips"))
			ShowVIPMenu(client);
	}
}
public int ShowInvisM(Handle menu, MenuAction action, int client, int param2) {}
public int ShowvisM(Handle menu, MenuAction action, int client, int param2) {}
stock void ShowVIPMenu(int client)
{
	Menu menu = CreateMenu(VIPsList);
	menu.SetTitle("Online VIPs");
	int iCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && CSGOVIP_IsClientVIP(i) == true)
		{
			char name[64];
			Format(name, MAX_NAME_LENGTH, "%N", i);
			menu.AddItem("", name);
			iCount++;
		}
	}
	if(iCount == 0)
		menu.AddItem("", "No VIPs are currently online.");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}
public int VIPsList(Handle menu, MenuAction action, int client, int param2) 
{
	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		FakeClientCommand(client, "say /admins");
	}
}
stock bool IsValidClient(int client)
{
	if (client <= 0)
		return false;
	if (client > MaxClients)
		return false;
	if (!IsClientConnected(client))
		return false;
	return IsClientInGame(client);
}