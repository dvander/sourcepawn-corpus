public PlVers:__version =
{
	version = 5,
	filevers = "1.3.6",
	date = "02/21/2011",
	time = "17:28:04"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Plugin:myinfo =
{
	name = "Basic Chat",
	description = "Basic Communication Commands",
	author = "AlliedModders LLC",
	version = "1.3.6",
	url = "http://www.sourcemod.net/"
};
new String:g_ColorNames[13][12];
new g_Colors[13][3] =
{
	{
		255, ...
	},
	{
		255, 0, 0
	},
	{
		0, 255, 0
	},
	{
		0, 0, 255
	},
	{
		255, 255, 0
	},
	{
		255, 0, 255
	},
	{
		0, 255, 255
	},
	{
		255, 128, 0
	},
	{
		255, 0, 128
	},
	{
		128, 255, 0
	},
	{
		0, 255, 128
	},
	{
		128, 0, 255
	},
	{
		0, 128, 255
	}
};
new Handle:g_Cvar_Chatmode;
new bool:g_DoColor = 1;
new g_GameEngine;
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	VerifyCoreVersion();
	return 0;
}

ReplyToTargetError(client, reason)
{
	switch (reason)
	{
		case -7:
		{
			ReplyToCommand(client, "[SM] %t", "More than one client matched");
		}
		case -6:
		{
			ReplyToCommand(client, "[SM] %t", "Cannot target bot");
		}
		case -5:
		{
			ReplyToCommand(client, "[SM] %t", "No matching clients");
		}
		case -4:
		{
			ReplyToCommand(client, "[SM] %t", "Unable to target");
		}
		case -3:
		{
			ReplyToCommand(client, "[SM] %t", "Target is not in game");
		}
		case -2:
		{
			ReplyToCommand(client, "[SM] %t", "Target must be dead");
		}
		case -1:
		{
			ReplyToCommand(client, "[SM] %t", "Target must be alive");
		}
		case 0:
		{
			ReplyToCommand(client, "[SM] %t", "No matching client");
		}
		default:
		{
		}
	}
	return 0;
}

FindTarget(client, String:target[], bool:nobots, bool:immunity)
{
	decl String:target_name[64];
	decl target_list[1];
	decl target_count;
	decl bool:tn_is_ml;
	new flags = 16;
	if (nobots)
	{
		flags |= 32;
	}
	if (!immunity)
	{
		flags |= 8;
	}
	target_count = var1;
	if (0 < var1)
	{
		return target_list[0];
	}
	ReplyToTargetError(client, target_count);
	return -1;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	g_GameEngine = GuessSDKVersion();
	g_Cvar_Chatmode = CreateConVar("sm_chat_mode", "1", "Allows player's to send messages to admin chat.", 0, true, 0, true, 1);
	RegConsoleCmd("say", Command_SayChat, "", 0);
	RegConsoleCmd("say_team", Command_SayAdmin, "", 0);
	RegAdminCmd("sm_say", Command_SmSay, 512, "sm_say <message> - sends message to all players", "", 0);
	RegAdminCmd("sm_csay", Command_SmCsay, 512, "sm_csay <message> - sends centered message to all players", "", 0);
	if (g_GameEngine != 15)
	{
		RegAdminCmd("sm_hsay", Command_SmHsay, 512, "sm_hsay <message> - sends hint message to all players", "", 0);
	}
	RegAdminCmd("sm_tsay", Command_SmTsay, 512, "sm_tsay [color] <message> - sends top-left message to all players", "", 0);
	RegAdminCmd("sm_chat", Command_SmChat, 512, "sm_chat <message> - sends message to admins", "", 0);
	RegAdminCmd("sm_psay", Command_SmPsay, 512, "sm_psay <name or #userid> <message> - sends private message", "", 0);
	RegAdminCmd("sm_msay", Command_SmMsay, 512, "sm_msay <message> - sends message as a menu panel", "", 0);
	decl String:modname[64];
	GetGameFolderName(modname, 64);
	if (!(strcmp(modname, "hl2mp", true)))
	{
		g_DoColor = 0;
	}
	return 0;
}

public Action:Command_SayChat(client, args)
{
	decl String:text[192];
	if (IsChatTrigger())
	{
		return Action:0;
	}
	new startidx;
	if (text[strlen(text) + -1] == '"')
	{
		text[strlen(text) + -1] = 0;
		startidx = 1;
	}
	if (text[startidx] != '@')
	{
		return Action:0;
	}
	new msgStart = 1;
	if (text[startidx + 1] == '@')
	{
		msgStart = 2;
		if (text[startidx + 2] == '@')
		{
			msgStart = 3;
		}
	}
	decl String:message[192];
	strcopy(message, 192, text[msgStart + startidx]);
	decl String:name[64];
	GetClientName(client, name, 64);
	if (msgStart == 1)
	{
		SendChatToAll(client, message);
		LogAction(client, -1, "%L triggered sm_say (text %s)", client, message);
	}
	else
	{
		if (msgStart == 3)
		{
			DisplayCenterTextToAll(client, message);
			LogAction(client, -1, "%L triggered sm_csay (text %s)", client, text);
		}
		if (msgStart == 2)
		{
			decl String:arg[64];
			new len = BreakString(message, arg, 64);
			new target = FindTarget(client, arg, true, false);
			if (target == -1)
			{
				return Action:3;
			}
			decl String:name2[64];
			GetClientName(target, name2, 64);
			if (g_DoColor)
			{
				PrintToChat(client, "\x04(Private to %s) %s: ", name2, name, message[len]);
				PrintToChat(target, "\x04(Private to %s) %s: ", name2, name, message[len]);
			}
			else
			{
				PrintToChat(client, "(Private to %s) %s: %s", name2, name, message[len]);
				PrintToChat(target, "(Private to %s) %s: %s", name2, name, message[len]);
			}
			LogAction(client, -1, "%L triggered sm_psay to %L (text %s)", client, target, message);
		}
		return Action:0;
	}
	return Action:3;
}

public Action:Command_SayAdmin(client, args)
{
	if (!CheckCommandAccess(client, "sm_chat", 512, false))
	{
		return Action:0;
	}
	decl String:text[192];
	if (IsChatTrigger())
	{
		return Action:0;
	}
	new startidx;
	if (text[strlen(text) + -1] == '"')
	{
		text[strlen(text) + -1] = 0;
		startidx = 1;
	}
	if (text[startidx] != '@')
	{
		return Action:0;
	}
	decl String:message[192];
	strcopy(message, 192, text[startidx + 1]);
	SendChatToAdmins(client, message);
	LogAction(client, -1, "%L triggered sm_chat (text %s)", client, message);
	return Action:3;
}

public Action:Command_SmSay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_say <message>");
		return Action:3;
	}
	decl String:text[192];
	GetCmdArgString(text, 192);
	SendChatToAll(client, text);
	LogAction(client, -1, "%L triggered sm_say (text %s)", client, text);
	return Action:3;
}

public Action:Command_SmCsay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_csay <message>");
		return Action:3;
	}
	decl String:text[192];
	GetCmdArgString(text, 192);
	DisplayCenterTextToAll(client, text);
	LogAction(client, -1, "%L triggered sm_csay (text %s)", client, text);
	return Action:3;
}

public Action:Command_SmHsay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hsay <message>");
		return Action:3;
	}
	decl String:text[192];
	GetCmdArgString(text, 192);
	decl String:nameBuf[32];
	new i = 1;
	while (i <= MaxClients)
	{
		if (!IsClientInGame(i))
		{
		}
		else
		{
			FormatActivitySource(client, i, nameBuf, 32);
			PrintHintText(i, "%s: %s", nameBuf, text);
		}
		i++;
	}
	LogAction(client, -1, "%L triggered sm_hsay (text %s)", client, text);
	return Action:3;
}

public Action:Command_SmTsay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_tsay <message>");
		return Action:3;
	}
	decl String:text[192];
	decl String:colorStr[16];
	GetCmdArgString(text, 192);
	new len = BreakString(text, colorStr, 16);
	decl String:name[64];
	GetClientName(client, name, 64);
	new color = FindColor(colorStr);
	new String:nameBuf[32];
	if (color == -1)
	{
		color = 0;
		len = 0;
	}
	new i = 1;
	while (i <= MaxClients)
	{
		if (!IsClientInGame(i))
		{
		}
		else
		{
			FormatActivitySource(client, i, nameBuf, 32);
			SendDialogToOne(i, color, "%s: %s", nameBuf, text[len]);
		}
		i++;
	}
	LogAction(client, -1, "%L triggered sm_tsay (text %s)", client, text);
	return Action:3;
}

public Action:Command_SmChat(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_chat <message>");
		return Action:3;
	}
	decl String:text[192];
	GetCmdArgString(text, 192);
	SendChatToAdmins(client, text);
	LogAction(client, -1, "%L triggered sm_chat (text %s)", client, text);
	return Action:3;
}

public Action:Command_SmPsay(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_psay <name or #userid> <message>");
		return Action:3;
	}
	decl String:text[192];
	decl String:arg[64];
	decl String:message[192];
	GetCmdArgString(text, 192);
	new len = BreakString(text, arg, 64);
	BreakString(text[len], message, 192);
	new target = FindTarget(client, arg, true, false);
	if (target == -1)
	{
		return Action:3;
	}
	new String:name[64] = "Console";
	decl String:name2[64];
	if (client)
	{
		GetClientName(client, name, 64);
	}
	GetClientName(target, name2, 64);
	if (client)
	{
		if (g_DoColor)
		{
			PrintToChat(client, "\x04(Private: %s) %s: ", name2, name, message);
		}
		PrintToChat(client, "(Private: %s) %s: %s", name2, name, message);
	}
	else
	{
		PrintToServer("(Private: %s) %s: %s", name2, name, message);
	}
	if (g_DoColor)
	{
		PrintToChat(target, "\x04(Private: %s) %s: ", name2, name, message);
	}
	else
	{
		PrintToChat(target, "(Private: %s) %s: %s", name2, name, message);
	}
	LogAction(client, -1, "%L triggered sm_psay to %L (text %s)", client, target, message);
	return Action:3;
}

public Action:Command_SmMsay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_msay <message>");
		return Action:3;
	}
	decl String:text[192];
	GetCmdArgString(text, 192);
	decl String:name[64];
	GetClientName(client, name, 64);
	SendPanelToAll(name, text);
	LogAction(client, -1, "%L triggered sm_msay (text %s)", client, text);
	return Action:3;
}

FindColor(String:color[])
{
	new i;
	while (i < 13)
	{
		if (strcmp(color, g_ColorNames[i][0][0], false))
		{
			i++;
		}
		else
		{
			return i;
		}
		i++;
	}
	return -1;
}

SendChatToAll(client, String:message[])
{
	new String:nameBuf[32];
	new i = 1;
	while (i <= MaxClients)
	{
		if (!IsClientInGame(i))
		{
		}
		else
		{
			FormatActivitySource(client, i, nameBuf, 32);
			if (g_DoColor)
			{
				PrintToChat(i, "\x03(ADMIN) %s: \x03%s", nameBuf, message);
			}
			else
			{
				PrintToChat(i, "%s: %s", nameBuf, message);
			}
		}
		i++;
	}
	return 0;
}

DisplayCenterTextToAll(client, String:message[])
{
	new String:nameBuf[32];
	new i = 1;
	while (i <= MaxClients)
	{
		if (!IsClientInGame(i))
		{
		}
		else
		{
			FormatActivitySource(client, i, nameBuf, 32);
			PrintCenterText(i, "%s: %s", nameBuf, message);
		}
		i++;
	}
	return 0;
}

SendChatToAdmins(from, String:message[])
{
	new fromAdmin = CheckCommandAccess(from, "sm_chat", 512, false);
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (g_DoColor)
			{
				if (fromAdmin)
				{
					var3[0] = 2500;
				}
				else
				{
					var3[0] = 2504;
				}
				PrintToChat(i, "\x04(%sADMINS ONLY) %N: \x04%s", var3, from, message);
				i++;
			}
			if (fromAdmin)
			{
				var4[0] = 2528;
			}
			else
			{
				var4[0] = 2532;
			}
			PrintToChat(i, "(%sADMINs) %N: %s", var4, from, message);
			i++;
		}
		i++;
	}
	return 0;
}

SendDialogToOne(client, color, String:text[])
{
	new String:message[100];
	VFormat(message, 100, text, 4);
	new Handle:kv = CreateKeyValues("Stuff", "title", message);
	KvSetColor(kv, "color", g_Colors[color][0][0][0], g_Colors[color][0][0][1], g_Colors[color][0][0][2], 255);
	KvSetNum(kv, "level", 1);
	KvSetNum(kv, "time", 10);
	CreateDialog(client, kv, DialogType:0);
	CloseHandle(kv);
	return 0;
}

SendPanelToAll(String:name[], String:message[])
{
	decl String:title[100];
	Format(title, 64, "%s:", name);
	ReplaceString(message, 192, "\n", "\n", true);
	new Handle:mSayPanel = CreatePanel(Handle:0);
	SetPanelTitle(mSayPanel, title, false);
	DrawPanelItem(mSayPanel, "", 8);
	DrawPanelText(mSayPanel, message);
	DrawPanelItem(mSayPanel, "", 8);
	SetPanelCurrentKey(mSayPanel, 10);
	DrawPanelItem(mSayPanel, "Exit", 16);
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SendPanelToClient(mSayPanel, i, Handler_DoNothing, 10);
			i++;
		}
		i++;
	}
	CloseHandle(mSayPanel);
	return 0;
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	return 0;
}

