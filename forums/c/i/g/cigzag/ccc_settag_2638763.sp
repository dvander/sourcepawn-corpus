#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "blood"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <ccc>
#include <morecolors>
#include <clientprefs>

#pragma newdecls required

Handle TagCookie = null;
Handle TagBoolCookie = null;

bool CustomTag[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[TF2] Set Custom Tags", 
	author = PLUGIN_AUTHOR, 
	description = "Set Custom Tags for Custom Chat Colors", 
	version = PLUGIN_VERSION, 
	url = "https://savita-gaming.com"
};

public void OnPluginStart()
{
	TagCookie = RegClientCookie("TagString", "Cookie for saved tag string.", CookieAccess_Private);
	TagBoolCookie = RegClientCookie("TagBool", "Cookie for saved tag bool.", CookieAccess_Private);
	RegAdminCmd("sm_tag", Cmd_ChangeTag, ADMFLAG_GENERIC, "Allows players to change their tag in-game");
	RegAdminCmd("sm_resettag", Cmd_ResetTag, ADMFLAG_GENERIC, "Allows players to reset their custom tag in-game");
	
	LoadTranslations("common.phrases");
}

public void OnClientPostAdminCheck(int client)
{
	if (AreClientCookiesCached(client))
	{
		char sTagValue[64];
		
		GetClientCookie(client, TagCookie, sTagValue, sizeof(sTagValue));
		
		char sTagBool[64];
		GetClientCookie(client, TagBoolCookie, sTagBool, sizeof(sTagBool));
		
		float fTag = StringToFloat(sTagBool);
		
		if (fTag == 1.0)
			CCC_SetTag(client, sTagValue);
	}
}

public Action Cmd_ResetTag(int client, int args)
{
	if (args >= 1)
	{
		return Plugin_Handled;
	}
	
	CPrintToChat(client, "Your tag has been reset.");
	CCC_ResetTag(client);
	CustomTag[client] = false;
	
	if (AreClientCookiesCached(client))
	{
		char sTagValue[64];
		GetClientCookie(client, TagCookie, sTagValue, sizeof(sTagValue));
		
		sTagValue = "";
		
		SetClientCookie(client, TagCookie, sTagValue);
		
		char sTagBool[64];
		GetClientCookie(client, TagBoolCookie, sTagBool, sizeof(sTagBool));
		
		float fTag = StringToFloat(sTagBool);
		
		if (CustomTag[client])
			fTag = 1.0;
		else
			fTag = 0.0;
		
		FloatToString(fTag, sTagBool, sizeof(sTagBool));
		
		SetClientCookie(client, TagBoolCookie, sTagBool);
	}
	
	return Plugin_Handled;
}

public Action Cmd_ChangeTag(int client, int args)
{
	char arg1[64];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (args <= 0)
	{
		CPrintToChat(client, "sm_tag <tag>");
		return Plugin_Handled;
	}
	
	if (args >= 2)
	{
		CPrintToChat(client, "Error occured, tag must only contain one tag argument.");
		return Plugin_Handled;
	}
	
	char result[64];
	Format(result, sizeof(result), "[%s] ", arg1);
	
	if (!CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		if (StrEqual(arg1, "Owner", true) || StrEqual(arg1, "Admin", true) || StrEqual(arg1, "Mod", true) || StrEqual(arg1, "Moderator", true) || StrEqual(arg1, "Administrator", true) || StrEqual(arg1, "moderator", true) || StrEqual(arg1, "owner", true) || StrEqual(arg1, "admin", true) || StrEqual(arg1, "administrator", true) || StrEqual(arg1, "mod", true) || StrEqual(arg1, "0wner", true))
		{
			CPrintToChat(client, "Impersonation of staff is not allowed!");
			return Plugin_Handled;
		}
	}
	
	CPrintToChat(client, "Your tag has been set to %s", result);
	CCC_SetTag(client, result);
	CustomTag[client] = true;
	
	if (AreClientCookiesCached(client))
	{
		char sTagValue[64];
		GetClientCookie(client, TagCookie, sTagValue, sizeof(sTagValue));
		
		sTagValue = result;
		
		SetClientCookie(client, TagCookie, sTagValue);
		
		char sTagBool[64];
		GetClientCookie(client, TagBoolCookie, sTagBool, sizeof(sTagBool));
		
		float fTag = StringToFloat(sTagBool);
		
		if (CustomTag[client])
			fTag = 1.0;
		else
			fTag = 0.0;
		
		FloatToString(fTag, sTagBool, sizeof(sTagBool));
		
		SetClientCookie(client, TagBoolCookie, sTagBool);
	}
	
	return Plugin_Handled;
}
