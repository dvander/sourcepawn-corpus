#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>

public Plugin:myinfo =
{
	name = "SM PlayOpt",
	author = "./Moriss",
	description = "Sound commands with option to disable it by players",
	version = "1.0",
	url = "http://moriss.adjustmentbeaver.com/"
};

new Handle:g_hCookie = INVALID_HANDLE;
new bool:g_bCookies[MAXPLAYERS + 1] = {true,...};

public OnPluginStart( )
{
	RegAdminCmd("sm_playopt", Command_PlayOpt, ADMFLAG_GENERIC, "sm_playopt <#userid|name> <filename>");

	RegConsoleCmd("sm_soundon", Command_SoundOn, "Turn sound playing on");
	RegConsoleCmd("sm_soundoff", Command_SoundOff, "Turn sound playing off");

	LoadTranslations("common.phrases");
	LoadTranslations("sounds.phrases");
	LoadTranslations("playopt.phrases");

	g_hCookie = RegClientCookie("PlayOpt", "", CookieAccess_Private);
	SetCookieMenuItem(Handler_Cookie, g_hCookie, "Custom Sounds");

	for (new client=1; client<=MaxClients; client++)
	{
		if (IsClientConnected(client) && IsClientInGame(client))
			if (AreClientCookiesCached(client))
				OnClientCookiesCached(client);
	}
}

public Action:Command_PlayOpt(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_playopt <#userid|name> <filename>");
		return Plugin_Handled;
	}

	new String:szArgs[PLATFORM_MAX_PATH + 65];
	GetCmdArgString(szArgs, sizeof(szArgs));

	decl String:szTarget[65];
	new iLength = BreakString(szArgs, szTarget, sizeof(szTarget));

	if (iLength == -1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_playopt <#userid|name> <filename>");
		return Plugin_Handled;
	}

	if (szArgs[iLength] == '"')
	{
		iLength++;
		new iPathLen = TrimString(szArgs[iLength]) + iLength;

		if (szArgs[iPathLen - 1] == '"')
			szArgs[iPathLen - 1] = '\0';
	}
	
	decl String:szTargetName[MAX_TARGET_LENGTH];
	decl rgiTargets[MAXPLAYERS], iTargets, bool:bTnMl;
	
	if ((iTargets = ProcessTargetString(szTarget, client, rgiTargets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, szTargetName, MAX_NAME_LENGTH, bTnMl)) <= 0)
	{
		ReplyToTargetError(client, iTargets);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < iTargets; i++)
	{
		if (g_bCookies[rgiTargets[i]])
		{
			ClientCommand(rgiTargets[i], "playgamesound \"%s\"", szArgs[iLength]);
			LogAction(client, rgiTargets[i], "\"%L\" played sound on \"%L\" (file \"%s\")", client, rgiTargets[i], szArgs[iLength]);
		}
	}
	
	if (bTnMl)
		ShowActivity2(client, "[SM] ", "%t", "Played sound to target", szTargetName);
	else
		ShowActivity2(client, "[SM] ", "%t", "Played sound to target", "_s", szTargetName);

	return Plugin_Handled;
}


public Action:Command_SoundOn(client, args)
{
	SetClientCookie(client, g_hCookie, "on");
	g_bCookies[client] = true;

	ReplyToCommand(client, "[SM] %t", "Sounds Enabled");

	return Plugin_Handled;
}

public Action:Command_SoundOff(client, args)
{
	SetClientCookie(client, g_hCookie, "off");
	g_bCookies[client] = false;

	ReplyToCommand(client, "[SM] %t", "Sounds Disabled");

	return Plugin_Handled;
}

public Handler_Cookie(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		if (GetCookieValue(client))
			Format(buffer, maxlen, "%T", "Custom Sounds On", client);
		else
			Format(buffer, maxlen, "%T", "Custom Sounds Off", client);
	}
	else
	{
		g_bCookies[client] = !g_bCookies[client];
		
		if (g_bCookies[client])
		{
			SetClientCookie(client, g_hCookie, "on");
			PrintToChat(client, "[SM] %T", "Sounds Enabled", client);
		}
		else
		{
			SetClientCookie(client, g_hCookie, "off");
			PrintToChat(client, "[SM] %T", "Sounds Disabled", client);
		}
		
		ShowCookieMenu(client);
	}
}

public OnClientCookiesCached(client)
{
	decl String:buffer[10];
	GetClientCookie(client, g_hCookie, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "on") && !StrEqual(buffer, "off"))
		SetClientCookie(client, g_hCookie, "on");

	g_bCookies[client] = StrEqual(buffer, "on");
}

public bool:GetCookieValue(client)
{
	decl String:buffer[10];
	GetClientCookie(client, g_hCookie, buffer, sizeof(buffer));
	return StrEqual(buffer, "on");
}