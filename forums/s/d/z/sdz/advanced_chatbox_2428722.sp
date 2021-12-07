#include <sourcemod>
#include <sdktools>
#include <morecolorsX>
#include <clientprefs>

#define COLOR_NAME		0
#define COLOR_TEXT		1

new Handle:g_hColors[2] = INVALID_HANDLE;

new String:g_nameColor[MAXPLAYERS + 1][32];
new String:g_textColor[MAXPLAYERS + 1][32];

new EngineVersion:gameEngine;

public Plugin:myinfo =
{
	name = "Advanced Chatbox",
	author = "Sidezz",
	description = "Lets dudes pick their colors of text/name and stuff. Doesn't work for CS:GO.",
	version = "1.0",
	url = "www.coldcommunity.com"
}

public OnPluginStart()
{
	if(gameEngine == Engine_CSGO)
	{
		SetFailState("[SM] Advanced Chatbox does not support Counter-Strike Global Offensive.");
	}

	else if(gameEngine == Engine_Left4Dead2 || gameEngine == Engine_Left4Dead)
	{
		SetFailState("[SM] Advanced Chatbox does not support Left4Dead.");
	}

	//Hook Chat:
	AddCommandListener(listen_Say, "say");
	//RegAdminCmd("sm_namecolor", command_nameColor, ADMFLAG_ROOT, "");
	//RegAdminCmd("sm_textcolor", command_textColor, ADMFLAG_ROOT, "");
	RegConsoleCmd("sm_namecolor", command_nameColor, "[ACBX] - Set the color of your name");
	RegConsoleCmd("sm_textcolor", command_textColor, "[ACBX] - Set the color of your chat messages");


	//Preference Cookies
	g_hColors[COLOR_NAME] = RegClientCookie("advchat_name", "Name color hex", CookieAccess_Private);
	g_hColors[COLOR_TEXT] = RegClientCookie("advchat_text", "Text color hex", CookieAccess_Private);

	SetCookiePrefabMenu(g_hColors[COLOR_NAME], CookieMenu_OnOff, "Name Color", handleC);
	SetCookiePrefabMenu(g_hColors[COLOR_TEXT], CookieMenu_OnOff, "Text Color", handleC);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!AreClientCookiesCached(i))
		{
			continue;
		}

		OnClientCookiesCached(i);
	}
}

public handleC(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	switch (action)
    {
        case CookieMenuAction_DisplayOption:
        {

        }
        
        case CookieMenuAction_SelectOption:
        {
            OnClientCookiesCached(client);
        }
    }
}

public OnClientCookiesCached(client)
{
	if(IsClientInGame(client))
	{
		GetClientCookie(client, g_hColors[COLOR_NAME], g_nameColor[client], sizeof(g_nameColor[]));
		GetClientCookie(client, g_hColors[COLOR_TEXT], g_textColor[client], sizeof(g_textColor[]));
	}
}

public Action:listen_Say(client, const String:command[], argc)
{
	if(client == 0) return Plugin_Continue;

	decl String:finalMessage[1024];
	decl String:textMessage[512];
	GetCmdArgString(textMessage, sizeof(textMessage));
	StripQuotes(textMessage);

	if(strlen(g_nameColor[client]) >= 3 || strlen(g_textColor[client]) >= 3)
	{
		//Has different name color:
		if(strlen(g_nameColor[client]) >= 3)
		{
			Format(finalMessage, sizeof(finalMessage), "\x07%s%N\x01", g_nameColor[client], client);
		}

		else
		{
			Format(finalMessage, sizeof(finalMessage), "%N", client);
		}

		//Has different text color:
		if(strlen(g_textColor[client]) >= 3)
		{
			Format(finalMessage, sizeof(finalMessage), "%s :  \x07%s%s", finalMessage, g_textColor[client], textMessage);
		}

		else
		{
			Format(finalMessage, sizeof(finalMessage), "%s :  %s", finalMessage, textMessage);
		}

		TrimString(finalMessage);
		StripQuotes(finalMessage);

		if(StrContains(textMessage, "/", false) == 0) return Plugin_Handled;
		CPrintToChatAll(finalMessage);
		return Plugin_Handled;
	}

	else if(StrContains(textMessage, "/", false) == 0)
	{
		return Plugin_Handled;
	}
	
	else return Plugin_Continue;
}

public Action:command_nameColor(client, args)
{
	if(client == 0) return Plugin_Handled;

	decl String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));

	if(SimpleRegexMatch(arg, "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$") == -1)
	{
		PrintToChat(client, "[SM] Invalid Usage: sm_namecolor <#RRGGBB hexadecimal color code>");
		return Plugin_Handled;
	}

	if(strlen(arg) > 6) 
	{
		PrintToChat(client, "[SM] Invalid Usage: sm_namecolor <#RRGGBB hexadecimal color code>");
		return Plugin_Handled;
	}

	if(StrContains(arg, "#", false) != -1) ReplaceString(arg, sizeof(arg), "#", "", false);
	StripQuotes(arg);
	TrimString(arg);
	SetClientCookie(client, g_hColors[COLOR_NAME], arg);

	strcopy(g_nameColor[client], sizeof(g_nameColor[]), arg);
	CPrintToChat(client, "[SM] Name color set to: \x07%s #%s", g_nameColor[client], arg);
	return Plugin_Handled;
}

public Action:command_textColor(client, args)
{
	if(client == 0) return Plugin_Handled;

	decl String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));

	if(SimpleRegexMatch(arg, "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$") == -1)
	{
		PrintToChat(client, "[SM] Invalid Usage: sm_textcolor <#RRGGBB hexadecimal color code>");
		return Plugin_Handled;
	}

	if(strlen(arg) > 6) 
	{
		PrintToChat(client, "[SM] Invalid Usage: sm_textcolor <#RRGGBB hexadecimal color code>");
		return Plugin_Handled;
	}

	if(StrContains(arg, "#", false) != -1) ReplaceString(arg, sizeof(arg), "#", "", false);
	StripQuotes(arg);
	TrimString(arg);
	SetClientCookie(client, g_hColors[COLOR_TEXT], arg);

	strcopy(g_textColor[client], sizeof(g_nameColor[]), arg);
	CPrintToChat(client, "[SM] Text color set to: \x07%s #%s", g_textColor[client], arg);
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	g_nameColor[client] = "\x01";
	g_textColor[client] = "\x01";
	if(AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}
}