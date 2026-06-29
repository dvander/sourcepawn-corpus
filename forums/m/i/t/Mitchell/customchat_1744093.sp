#include <sourcemod>
#include <sdktools>
#include <regex>
#pragma semicolon 1
/*
		"tag"				""
		"tagcolor"			"#957B29"
		"namecolor"			"#DBA901"
		"textcolor"			"#F3E2A9"
*/

#define OFF 0
#define ON 1
#define TAG 5
#define TAGCOLOR 2
#define NAMECOLOR 3
#define TEXTCOLOR 4

enum ChatEnum
{
	String:Tag[20],
	String:TagColor[8],
	String:NameColor[8],
	String:TextColor[8],
	IsTyping,
};
new Players[MAXPLAYERS+1][ChatEnum];

new Handle:hRegex;

public Plugin:myinfo =
{
	name = "Color Chat Menu!",
	author = "MitchDizzle_",
	description = "Mitch.'s color chat menu, base on Dr.McKay's color chat plugin.",
	version = "0.1",
	url = "http://snbx.info/"
}
public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegAdminCmd("sm_colorchat", Command_ShowChatMenu, ADMFLAG_GENERIC);
	hRegex = CompileRegex("((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))");
	/*This regex took me 5 hours to find out how regexs work and how to make one that would find "255 0 0" etc. 
	I hope this goes to good use.
	Also, if there are any issues, blame the internet for not giving me enough resources on this subject.
	Aparrently it hates to find a number using: ([0-255]) (i guess no one likes simplicity... :(
	
	*/
}

public Action:Command_ShowChatMenu(client, args)
{
	Void_MenuChat_main(client);
	return Plugin_Handled;
}

public Action:Command_Say(client, args)
{
	if(!IsClientInGame(client)) return Plugin_Continue;
	if(Players[client][IsTyping] == OFF) return Plugin_Continue;
	
	
	decl String:strMessage[128];
	GetCmdArgString(strMessage, sizeof(strMessage));
	
	/* ((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)) */
	if(Players[client][IsTyping] == TAG)
	{
		new String:TextBuffer[8];
		StripQuotes(strMessage);
		Format(Players[client][Tag], 20, "%s", strMessage);
		Format(TextBuffer, 8, "%s", Players[client][TagColor]);
		SaveChatConfig(client);
		Players[client][IsTyping] = OFF;
		ReplaceString(TextBuffer, 8, "#", "");
		PrintToChat(client, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF New Tag: \x07%s %s", TextBuffer, Players[client][Tag]);
		Void_MenuChat_main(client);
		return Plugin_Handled;
	}
	else
	{
		decl String:matchedTag[64];
		
		if (MatchRegex(hRegex, strMessage))
		{
			GetRegexSubString(hRegex, 0, matchedTag, sizeof(matchedTag));
			new location = StrContains(strMessage, matchedTag);
			if (location != -1)
			{
				new Color;
				new String:ColorString[3][4];
				ExplodeString(matchedTag, " ", ColorString, 3, 4, true);
				Color |=    ( (StringToInt(ColorString[0]) & 0xFF) << 16);
				Color |=    ( (StringToInt(ColorString[1]) & 0xFF) << 8);
				Color |=    ( (StringToInt(ColorString[2]) & 0xFF) << 0 );
				new String:TextBuffer[8];
				if(Players[client][IsTyping] == TAGCOLOR)
				{
					Format(Players[client][TagColor], 8, "#%06X", Color);
					Format(TextBuffer, 8, "%s", Players[client][TagColor]);
					ReplaceString(TextBuffer, 8, "#", "");
					PrintToChat(client, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF New Tag Color: \x07%s %s", TextBuffer, Players[client][Tag]);
				}
				if(Players[client][IsTyping] == NAMECOLOR)
				{
					Format(Players[client][NameColor], 8, "#%06X", Color);
					Format(TextBuffer, 8, "%s", Players[client][NameColor]);
					ReplaceString(TextBuffer, 8, "#", "");
					PrintToChat(client, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF New Name Color: \x07%s %N", TextBuffer, client);
				}
				if(Players[client][IsTyping] == TEXTCOLOR)
				{
					Format(Players[client][TextColor], 8, "#%06X", Color);
					Format(TextBuffer, 8, "%s", Players[client][TextColor]);
					ReplaceString(TextBuffer, 8, "#", "");
					PrintToChat(client, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF New Text Color: \x07%s Example Text", TextBuffer);
				}
				SaveChatConfig(client);
				Players[client][IsTyping] = OFF;
				Void_MenuChat_main(client);
				return Plugin_Handled;
			}
		}
	}
	Players[client][IsTyping] = OFF;
	return Plugin_Continue;
}


public SaveChatConfig(client)
{
	new String:steam[32];
	GetClientAuthString(client, steam, sizeof(steam));
	new String:sPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, sPath, sizeof(sPath),"configs/custom-chatcolors.cfg");
	new Handle:kv = CreateKeyValues("admin_colors");
	FileToKeyValues(kv, sPath);
	KvRewind(kv);
	if(KvJumpToKey(kv, steam, true))
	{
		KvSetString(kv, "tag", Players[client][Tag]);
		KvSetString(kv, "tagcolor", Players[client][TagColor]);
		KvSetString(kv, "namecolor", Players[client][NameColor]);
		KvSetString(kv, "textcolor", Players[client][TextColor]);
		KvRewind(kv);
	}
	KeyValuesToFile(kv, sPath);
	CloseHandle(kv);
	ServerCommand("sm_reloadccc");
}
public LoadChatConfig(client)
{
	new String:steam[32];
	GetClientAuthString(client, steam, sizeof(steam));
	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath),"configs/custom-chatcolors.cfg");
	new Handle:kv = CreateKeyValues("admin_colors");
	FileToKeyValues(kv, sPath);
	KvRewind(kv);
	if(KvJumpToKey(kv, steam, true))
	{
		KvGetString(kv, "tag", Players[client][Tag], 20, "");
		KvGetString(kv, "tagcolor", Players[client][TagColor], 8, "");
		KvGetString(kv, "namecolor", Players[client][NameColor], 8, "");
		KvGetString(kv, "textcolor", Players[client][TextColor], 8, "");
		KvRewind(kv);
	}
	CloseHandle(kv);
}
Void_MenuChat_main(client, index=0)
{
	LoadChatConfig(client);
	decl String:g_sDisplay[128];
	new Handle:main = CreateMenu(Menu_Chat_Main, MENU_ACTIONS_DEFAULT);
	Format(g_sDisplay, sizeof(g_sDisplay), "Chat Colors Menu!\n Tag: %s\n Tag Color: %s\n Name Color: %s\n Text Color: %s", Players[client][Tag], Players[client][TagColor], Players[client][NameColor], Players[client][TextColor]);
	SetMenuTitle(main, g_sDisplay);
	AddMenuItem(main, "menu_tag", "Change Tag", ITEMDRAW_DEFAULT);
	AddMenuItem(main, "menu_tagc", "Change Tag Color", ITEMDRAW_DEFAULT);
	AddMenuItem(main, "menu_namec", "Change Name Color", ITEMDRAW_DEFAULT);
	AddMenuItem(main, "menu_textc", "Change Text Color", ITEMDRAW_DEFAULT);
	DisplayMenuAtItem(main, client, index, MENU_TIME_FOREVER);
}
public Menu_Chat_Main(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			new String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			if(StrEqual(info, "menu_tag", false))
			{
				if(Players[param1][IsTyping] == OFF)
				{
					Players[param1][IsTyping] = TAG;
					PrintToChat(param1, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF Changing Tag");
					PrintToChat(param1, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF Type a 20 character tag.");
				}
				else
				{
					PrintToChat(param1, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF You are already in a typing state, please type in a color code to continue.");
				}
			}
			else if(StrEqual(info, "menu_tagc", false))
			{
				if(Players[param1][IsTyping] == OFF)
				{
					Players[param1][IsTyping] = TAGCOLOR;
					PrintToChat(param1, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF Changing Tag Color");
					PrintToChat(param1, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF Type a RGB color scale. \x0700FFFFExample: 255 128 0");
				}
				else
				{
					PrintToChat(param1, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF You are already in a typing state, please type in a color code to continue.");
				}
				
			}
			else if(StrEqual(info, "menu_namec", false))
			{
				if(Players[param1][IsTyping] == OFF)
				{
					Players[param1][IsTyping] = NAMECOLOR;
					PrintToChat(param1, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF Changing Name Color");
					PrintToChat(param1, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF Type a RGB color scale. \x0700FFFFExample: 255 128 0");
				}
				else
				{
					PrintToChat(param1, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF You are already in a typing state, please type in a color code to continue.");
				}
				
			}
			else if(StrEqual(info, "menu_textc", false))
			{
				if(Players[param1][IsTyping] == OFF)
				{
					Players[param1][IsTyping] = TEXTCOLOR;
					PrintToChat(param1, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF Changing Text Color");
					PrintToChat(param1, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF Type a RGB color scale. \x0700FFFFExample: 255 128 0");
				}
				else
				{
					PrintToChat(param1, "\x01\x07FF0000[\x07FF00FFChatColors\x07FF0000]\x07FFFFFF You are already in a typing state, please type in a color code to continue.");
				}
				
			}
			Void_MenuChat_main(param1);
		}
	}
	return;
}