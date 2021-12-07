#pragma semicolon 1
#include <sourcemod>
#include <ccc>
#include <clientprefs>

public Plugin:myinfo =
{
	name = "[THB] Custom Colors",
	author = "The.Hardstyle.Bro^_^",
	description = "Set's a special tag/name/chat color for VIP's",
	version = "1.0",
	url = "http://www.extreme-network.net/"
};

new Handle:g_CvarFlag = INVALID_HANDLE;
new bool:HasAccess[MAXPLAYERS+1];

new Handle:cookieTag;
new Handle:cookieName;
new Handle:cookieChat;

public OnPluginStart()
{
	AutoExecConfig(true, "CustomChatColor-Prefs");
	g_CvarFlag = CreateConVar("vip_flag", "p", "Flag for the VIP's. Default: Custom 4", FCVAR_PLUGIN);
	RegConsoleCmd("vip_namecolor", Command_NameColor);
	RegConsoleCmd("vip_chatcolor", Command_ChatColor);
	RegConsoleCmd("vip_tagcolor", Command_TagColor);
}

public OnAllPluginsLoaded()
{
	if(FindPluginByFile("simple-chatprocessor.smx") == INVALID_HANDLE) {
		LogError("!!! WARNING !!! simple-chatprocessor.smx is not loaded. Is Simple Chat Processor not installed?");
	}
	else if(FindPluginByFile("clientprefs.smx") == INVALID_HANDLE) {
		LogError("!!! WARNING !!! clientprefs.smx is not loaded. Is Client Preferences not installed?");
	}
	else if(FindPluginByFile("custom-chatcolors.smx") == INVALID_HANDLE) {
		LogError("!!! WARNING !!! simple-chatprocessor.smx is not loaded. Is Custom Chat Colors not installed?");
	}
	else
	{
		cookieName = RegClientCookie("namecolor", "Name Color", CookieAccess_Protected);
		cookieTag = RegClientCookie("tagcolor", "Tag Color", CookieAccess_Private);
		cookieChat = RegClientCookie("chatcolor", "Chat Color", CookieAccess_Private);
	}
}

public OnClientPostAdminCheck(client)
{
	if (AreClientCookiesCached(client))
	{
		decl String:cookie1[8], cookie2[8], cookie3[8];
		GetClientCookie(client, cookieName, cookie1, sizeof(cookie1));
		GetClientCookie(client, cookieTag, cookie2, sizeof(cookie2));
		GetClientCookie(client, cookieChat, cookie3, sizeof(cookie3));
		if(StrEqual(cookie2, ""))
		{
			SetClientCookie(client, cookieTag, "T");
		}
		if(StrEqual(cookie1, "")) 
		{
			SetClientCookie(client, cookieName, "T");
			
		}
		if(CheckImmunity(client, g_CvarFlag))
		{
			HasAccess[client] = true;
			CCC_SetNameColor(client, cookie1);
			CCC_SetTagColor(client, cookie2);
			CCC_SetChatColor(client, cookie3);
		}
		else
		{
			HasAccess[client] = false;
		}
	}

}
public Action:Command_ChatColor(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Useage: vip_chatcolor <color>.");
		return Plugin_Handled;
	}
	new String:color[6];
	GetClientCookie(client, cookieChat, color, sizeof(color));
	new String:Arg1[32];
	GetCmdArg(1, Arg1, sizeof(Arg1));

	if (HasAccess[client])
	{
		SetClientCookie(client, cookieChat, Arg1);
		PrintToChat(client, "[SM] Chat Color has been changed.");
		CCC_SetChatColor(client, Arg1);
	}
	
	return Plugin_Handled;
}
public Action:Command_TagColor(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Useage: vip_tagcolor <color>.");
		return Plugin_Handled;
	}
	new String:color[6];
	GetClientCookie(client, cookieTag, color, sizeof(color));
	new String:Arg1[32];
	GetCmdArg(1, Arg1, sizeof(Arg1));

	if (HasAccess[client])
	{
		SetClientCookie(client, cookieTag, Arg1);
		PrintToChat(client, "[SM] Tag Color has been changed.");
		CCC_SetTagColor(client, Arg1);
	}
	
	return Plugin_Handled;
}
public Action:Command_NameColor(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Useage: vip_namecolor <color>.");
		return Plugin_Handled;
	}
	new String:color[6];
	GetClientCookie(client, cookieName, color, sizeof(color));
	new String:Arg1[32];
	GetCmdArg(1, Arg1, sizeof(Arg1));

	if (HasAccess[client])
	{
		SetClientCookie(client, cookieName, Arg1);
		PrintToChat(client, "[SM] Name Color has been changed.");
		CCC_SetNameColor(client, Arg1);
	}
	
	return Plugin_Handled;
}
stock bool:CheckImmunity(client, Handle:cvar_immunity)
{
	if (!client)
		return false;

	new AdminId:adminid = GetUserAdmin(client);
	if (adminid == INVALID_ADMIN_ID)
		return false;

	new AdminFlag:flag;
	decl String:immunity[3];
	GetConVarString(cvar_immunity, immunity, sizeof(immunity));
	if (!FindFlagByChar(immunity[0], flag))
		return false;

	return GetAdminFlag(adminid , flag);
}
