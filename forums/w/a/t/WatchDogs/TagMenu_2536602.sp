#pragma semicolon 1 

#define	PLUGIN_AUTHOR	"[W]atch [D]ogs"
#define PLUGIN_VERSION	"1.1.1"

#include <sourcemod> 
#include <cstrike> 
#include <clientprefs>

#pragma newdecls required 

Handle h_bEnable;
Handle g_hClientCookies;

char sTags[100][256];
char sFlags[100][8];
int iTags = 0;

public Plugin myinfo = 
{
	name = "[CSGO/CSS] Scoreboard Tag Menu", 
	author = PLUGIN_AUTHOR, 
	description = "Creates a score board tag menu for players to choose", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=299351"
};

public void OnPluginStart()
{
	h_bEnable = CreateConVar("sm_tagmenu_enable", "1", "Enable / Disable tag menu", _, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_tag", Command_TagMenu);
	
	LoadTags();
	
	g_hClientCookies = RegClientCookie("TagMenu", "A cookie for saving clients's tags", CookieAccess_Private);
}

public void OnClientCookiesCached(int client)
{
	if(!IsFakeClient(client))
	{
		char sCookie[256];
		GetClientCookie(client, g_hClientCookies, sCookie, sizeof(sCookie));
		CS_SetClientClanTag(client, sCookie);
	}
}

public Action Command_TagMenu(int client, int args)
{
	if (GetConVarBool(h_bEnable))
		TagMenu(client);
	else
		ReplyToCommand(client, "[SM] Tag menu is disabled !");
	
	return Plugin_Handled;
}

public void TagMenu(int client)
{
	Handle menu = CreateMenu(MenuCallBack);
	SetMenuTitle(menu, "★ TAG MENU ★");
	AddMenuItem(menu, "0", "Disable Tag");
	
	for (int i = 0; i < iTags; i++)
	{
		if (sFlags[i][0] == '\0')
		{
			AddMenuItem(menu, sTags[i], sTags[i]);
		}
		else
		{
			if (CheckCommandAccess(client, "", ReadFlagString(sFlags[i])))
				AddMenuItem(menu, sTags[i], sTags[i]);
			else
				AddMenuItem(menu, sTags[i], sTags[i], ITEMDRAW_DISABLED);
		}
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuCallBack(Handle menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		char sItem[256], sSteamID[64];
		GetMenuItem(menu, itemNum, sItem, sizeof(sItem));
		GetClientAuthId(client, AuthId_Engine, sSteamID, sizeof(sSteamID));
		
		if (itemNum == 0)
		{
			CS_SetClientClanTag(client, "");
			SetAuthIdCookie(sSteamID, g_hClientCookies, "");
		}
		else
		{
			CS_SetClientClanTag(client, sItem);
			SetAuthIdCookie(sSteamID, g_hClientCookies, sItem);
		}
	}
	else if (action == MenuAction_End)CloseHandle(menu);
}

public void LoadTags()
{
	Handle kv = CreateKeyValues("TagMenu");
	if (FileToKeyValues(kv, "addons/sourcemod/configs/tagmenu.cfg") && KvGotoFirstSubKey(kv))
	{
		iTags = 0;
		do
		{
			KvGetString(kv, "tag", sTags[iTags], 256);
			KvGetString(kv, "flag", sFlags[iTags], 8);
			iTags++;
		} while (KvGotoNextKey(kv));
	}
	else
	{
		SetFailState("[Tag Menu] Error in parsing file tagmenu.cfg.");
	}
} 