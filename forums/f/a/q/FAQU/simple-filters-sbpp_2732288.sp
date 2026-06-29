#include <sourcemod>
#include <sdktools>
#include <regex>

#pragma semicolon 1
#pragma newdecls required

// globals
Regex regex;
Regex regexip;

ConVar gc_bNameFilters;
ConVar gc_bNameIpFilters;
ConVar gc_bNameSymbols;
ConVar gc_bChatFilters;
ConVar gc_bChatIpFilters;
ConVar gc_bChatSymbols;
ConVar gc_bChatCommands;
ConVar gc_iChatPunishment;
ConVar gc_iBanDuration;
ConVar gc_sReplacement;
ConVar gc_bWhitelist;

char chatfilters[100][50];
char namefilters[100][50];
char allowedips[20][20];
char chatfile[PLATFORM_MAX_PATH];
char namefile[PLATFORM_MAX_PATH];
char whitelistfile[PLATFORM_MAX_PATH];
char logfile[PLATFORM_MAX_PATH];

char plugin_version[] = "1.0.2";

public Plugin myinfo = 
{
	name = "Simple Filters",
	author = "FAQU",
	version = plugin_version,
	description = "Name and chat filtering"
};

public void OnPluginStart()
{
	regex = CompileRegex("[^\\w \\-\\/!@#$%^&*()+=,.<>\":;?[\\]]+", PCRE_UTF8);
	regexip = CompileRegex("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}");
	
	if (!regex)
	{
		SetFailState("Invalid regex pattern - Handle: regex");
	}
	else if (!regexip)
	{
		SetFailState("Invalid regex pattern - Handle: regexip");
	}
	
	BuildPath(Path_SM, chatfile, sizeof(chatfile), "configs/simple-chatfilters.txt");
	BuildPath(Path_SM, namefile, sizeof(namefile), "configs/simple-namefilters.txt");
	BuildPath(Path_SM, whitelistfile, sizeof(whitelistfile), "configs/simple-ipwhitelist.txt");
	BuildPath(Path_SM, logfile, sizeof(logfile), "logs/simple-filters.log");
	
	gc_bChatFilters = CreateConVar("simple_chatfilters", "1", "Enable the usage of chat filters (0 = Disabled / 1 = Enabled)");
	gc_bNameFilters = CreateConVar("simple_namefilters", "1", "Enable the usage of name filters (0 = Disabled / 1 = Enabled)");
	gc_bChatIpFilters = CreateConVar("simple_chatipfilters", "1", "Enable the usage of chat IP filters (0 = Disabled / 1 = Enabled)");
	gc_bNameIpFilters = CreateConVar("simple_nameipfilters", "1", "Enable the usage of name IP filters (0 = Disabled / 1 = Enabled)");
	gc_bWhitelist = CreateConVar("simple_ipwhitelist", "0", "Enable the usage of IP whitelist (0 = Disabled / 1 = Enabled)");
	gc_bChatSymbols = CreateConVar("simple_blockchatsymbols", "0", "Block chat messages if they contain symbols/custom fonts (0 = Disabled / 1 = Enabled)");
	gc_bNameSymbols = CreateConVar("simple_removenamesymbols", "1", "Remove symbols/custom fonts from player's name (0 = Allow symbols / 1 = Remove symbols)");
	gc_iChatPunishment = CreateConVar("simple_chatpunishment", "0", "How to punish the player if message contains bad word / IP address (0 = Block message / 1 = Kick player / 2 = Ban Player)");
	gc_iBanDuration = CreateConVar("simple_chatbanduration", "1440", "Ban duration in minutes - requires simple_chatpunishment 2");
	gc_bChatCommands = CreateConVar("simple_hidechatcommands", "1", "Hide chat commands - ex. !admin (0 = Don't hide / 1 = Hide)");
	gc_sReplacement = CreateConVar("simple_replacementword", "", "Replacement word for name filters (Empty = just remove bad words/IPs)");

	AutoExecConfig(true, "Simple-Filters");
	
	HookEvent("player_changename", Event_Changename);
	
	RegAdminCmd("sm_chatfilters", Command_Chatfilters, ADMFLAG_ROOT, "Prints a list of currently loaded chat filters");
	RegAdminCmd("sm_namefilters", Command_Namefilters, ADMFLAG_ROOT, "Prints a list of currently loaded name filters");
	RegAdminCmd("sm_ipwhitelist", Command_IpWhitelist, ADMFLAG_ROOT, "Prints a list of currently whitelisted IPs");
	RegAdminCmd("sm_reloadfilters", Command_Reloadfilters, ADMFLAG_ROOT, "Reloads chat and name filters");
}

public void OnMapStart()
{
	GetFilters();
}

public Action Command_Reloadfilters(int client, int args)
{
	GetFilters();
	ReplyToCommand(client, "Filters successfully reloaded !");
	return Plugin_Handled;
}

// debug chat filters read from file
public Action Command_Chatfilters(int client, int args)
{
	if (!gc_bChatFilters.BoolValue)
	{
		PrintToChat(client, "Chat filters are disabled");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "See console for output");
	if (client == 0)
	{
		PrintToServer("Chat Filters:");
	}
	else PrintToConsole(client, "Chat Filters:");
	
	int filters = sizeof(chatfilters);
	for (int i = 0; i < filters; i++)
	{
		if (StrEqual(chatfilters[i], ""))
		{
			break;
		}
		
		if (client == 0)
		{
			PrintToServer("%d. %s", i + 1, chatfilters[i]);
		}
		else PrintToConsole(client, "%d. %s", i + 1, chatfilters[i]);
	}
	return Plugin_Handled;
}

// debug name filters read from file
public Action Command_Namefilters(int client, int args)
{
	if (!gc_bNameFilters.BoolValue)
	{
		PrintToChat(client, "Name filters are disabled");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "See console for output");
	if (client == 0)
	{
		PrintToServer("Name Filters:");
	}
	else PrintToConsole(client, "Name Filters:");
	
	int filters = sizeof(namefilters);
	for (int i = 0; i < filters; i++)
	{
		if (StrEqual(namefilters[i], ""))
		{
			break;
		}
		
		if (client == 0)
		{
			PrintToServer("%d. %s", i + 1, namefilters[i]);
		}
		else PrintToConsole(client, "%d. %s", i + 1, namefilters[i]);
	}
	return Plugin_Handled;
}

// debug whitelisted IPs read from file
public Action Command_IpWhitelist(int client, int args)
{
	if (!gc_bWhitelist.BoolValue)
	{
		ReplyToCommand(client, "IP Whitelisting is disabled.");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "See console for output");
	if (client == 0)
	{
		PrintToServer("Whitelisted IPs:");
	}
	else PrintToConsole(client, "Whitelisted IPs:");
	
	int filters = sizeof(allowedips);
	for (int i = 0; i < filters; i++)
	{
		if (StrEqual(allowedips[i], ""))
		{
			break;
		}
		
		if (client == 0)
		{
			PrintToServer("%d. %s", i + 1, allowedips[i]);
		}
		else PrintToConsole(client, "%d. %s", i + 1, allowedips[i]);
	}
	return Plugin_Handled;
}

// Chat-Filtering
public Action OnClientSayCommand(int client, const char[] command, const char[] message)
{
	if (client == 0)
	{
		return Plugin_Continue;
	}
	else if (gc_bChatCommands.BoolValue && IsChatTrigger())
	{
		return Plugin_Handled;
	}
	else if (gc_bChatSymbols.BoolValue && regex.Match(message) > 0)
	{
		PrintToChat(client, "Your message has been blocked because it contains symbols.");
		return Plugin_Handled;
	}
	
	if (gc_bChatFilters.BoolValue)
	{
		int filters = sizeof(chatfilters);
		
		for (int i = 0; i < filters; i++)
		{
			if (StrEqual(chatfilters[i], ""))
			{
				break;
			}
			else if (StrContains(message, chatfilters[i], false) != -1)
			{
				switch (gc_iChatPunishment.IntValue)
				{
					case 0:
					{
						BlockMessage(client);
					}
					case 1:
					{
						KickPlayer(client, message, chatfilters[i]);
					}
					case 2:
					{
						BanPlayer(client, message, chatfilters[i]);
					}
					default:
					{
						BlockMessage(client);
					}
				}
				return Plugin_Handled;
			}
		}
	}
	
	if (gc_bChatIpFilters.BoolValue && regexip.Match(message) > 0)
	{
		
		if (gc_bWhitelist.BoolValue)
		{
			int filters = sizeof(allowedips);
			for (int i = 0; i < filters; i++)
			{
				if (StrEqual(allowedips[i], ""))
				{
					break;
				}
				else if (StrContains(message, allowedips[i], false) != -1)
				{
					return Plugin_Continue;
				}
			}
		}
		
		char ipad[32];
		GetRegexSubString(regexip, 0, ipad, sizeof(ipad));
		
		switch (gc_iChatPunishment.IntValue)
		{
			case 0:
			{
				BlockMessage(client);
			}
			case 1:
			{
				KickPlayer(client, message, ipad);
			}
			case 2:
			{
				BanPlayer(client, message, ipad);
			}
			default:
			{
				BlockMessage(client);
			}
		}
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// Name-Filtering
public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	char name[MAX_NAME_LENGTH];
	char oldname[MAX_NAME_LENGTH];
	
	GetClientName(client, name, sizeof(name));
	strcopy(oldname, sizeof(oldname), name);
	
	if (gc_bNameSymbols.BoolValue && regex.Match(name) > 0)
	{
		char substr[MAX_NAME_LENGTH];

		while (regex.Match(name) > 0)
		{
			GetRegexSubString(regex, 0, substr, sizeof(substr));
			ReplaceString(name, sizeof(name), substr, "", false);
		}
		RegexRename(client, name, oldname);
	}
	
	if (gc_bNameFilters.BoolValue)
	{
		int filters = sizeof(namefilters);
		for (int i = 0; i < filters; i++)
		{
			if (StrEqual(namefilters[i], ""))
			{
				break;
			}
			else if (StrContains(name, namefilters[i], false) != -1)
			{
				Rename(client, name, namefilters[i], oldname);
				return;
			}
		}
	}
	
	if (gc_bNameIpFilters.BoolValue && regexip.Match(name) > 0)
	{
		if (gc_bWhitelist.BoolValue)
		{
			int filters = sizeof(allowedips);
			for (int i = 0; i < filters; i++)
			{
				if (StrEqual(allowedips[i], ""))
				{
					break;
				}
				else if (StrContains(name, allowedips[i], false) != -1)
				{
					return;
				}
			}
		}
		
		char ipad[32];
		GetRegexSubString(regexip, 0, ipad, sizeof(ipad));
		Rename(client, name, ipad, oldname);
	}
}

public void Event_Changename(Handle event, const char[] namex, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsFakeClient(client))
	{
		return;
	}
	
	char name[MAX_NAME_LENGTH];
	char oldname[MAX_NAME_LENGTH];
	
	GetEventString(event, "newname", name, sizeof(name));
	strcopy(oldname, sizeof(oldname), name);

	if (gc_bNameSymbols.BoolValue && regex.Match(name) > 0)
	{
		char substr[MAX_NAME_LENGTH];
		
		while (regex.Match(name) > 0)
		{
			GetRegexSubString(regex, 0, substr, sizeof(substr));
			ReplaceString(name, sizeof(name), substr, "", false);
		}
		RegexRename(client, name, oldname);
	}
	
	if (gc_bNameFilters.BoolValue)
	{
		int filters = sizeof(namefilters);
		for (int i = 0; i < filters; i++)
		{
			if (StrEqual(namefilters[i], ""))
			{
				break;
			}
			else if (StrContains(name, namefilters[i], false) != -1)
			{
				Rename(client, name, namefilters[i], oldname);
				return;
			}
		}
	}
	
	if (gc_bNameIpFilters.BoolValue && regexip.Match(name) > 0)
	{
		if (gc_bWhitelist.BoolValue)
		{
			int filters = sizeof(allowedips);
			for (int i = 0; i < filters; i++)
			{
				if (StrEqual(allowedips[i], ""))
				{
					break;
				}
				else if (StrContains(name, allowedips[i], false) != -1)
				{
					return;
				}
			}
		}
		
		char ipad[32];
		GetRegexSubString(regexip, 0, ipad, sizeof(ipad));
		Rename(client, name, ipad, oldname);
	}
}

// FUNCTIONS
void GetFilters()
{
	int filters = sizeof(chatfilters);
	int allowed = sizeof(allowedips);
	
	for (int i = 0; i < filters; i++)
	{
		chatfilters[i] = "";
		namefilters[i] = "";
		if (i < allowed)
		{
			allowedips[i] = "";
		}
	}
	
	File chat = OpenFile(chatfile, "rt");
	File name = OpenFile(namefile, "rt");
	File whitelist = OpenFile(whitelistfile, "rt");
	
	if (!chat)
	{
		SetFailState("Couldn't read from file configs/simple-chatfilters.txt");
	}
	else if (!name)
	{
		SetFailState("Couldn't read from file configs/simple-namefilters.txt");
	}
	else if (!whitelist)
	{
		SetFailState("Couldn't read from file configs/simple-ipwhitelist.txt");
	}
	
	char line[50];
	
	for (int i = 0; !chat.EndOfFile() && chat.ReadLine(line, sizeof(line)); i++)
	{
		ReplaceString(line, sizeof(line), "\n", "", false);
		SplitString(line, "//", line, sizeof(line));
		TrimString(line);
		
		if (StrEqual(line, ""))
		{
			i--;
		}
		else BreakString(line, chatfilters[i], sizeof(chatfilters[]));
	}
	
	for (int i = 0; !name.EndOfFile() && name.ReadLine(line, sizeof(line)); i++)
	{
		ReplaceString(line, sizeof(line), "\n", "", false);
		SplitString(line, "//", line, sizeof(line));
		TrimString(line);
		
		if (StrEqual(line, ""))
		{
			i--;
		}
		else BreakString(line, namefilters[i], sizeof(namefilters[]));
	}
	
	for (int i = 0; !whitelist.EndOfFile() && whitelist.ReadLine(line, sizeof(line)); i++)
	{
		ReplaceString(line, sizeof(line), "\n", "", false);
		SplitString(line, "//", line, sizeof(line));
		TrimString(line);
		
		if (StrEqual(line, ""))
		{
			i--;
		}
		else BreakString(line, allowedips[i], sizeof(allowedips[]));
	}
	
	delete chat;
	delete name;
	delete whitelist;
}

void Rename(int client, char[] name, const char[] forbiddenword, const char[] oldname)
{
	char replacement[50];
	GetConVarString(gc_sReplacement, replacement, sizeof(replacement));
	
	ReplaceString(name, MAX_NAME_LENGTH, forbiddenword, replacement, false);
	TrimString(name);
	
	if (strlen(name) < 3)
	{
		Format(name, MAX_NAME_LENGTH, "Player #%d", GetClientUserId(client));
	}
	
	SetClientInfo(client, "name", name);
	LogToFile(logfile, "Renamed %s because his name contained a bad word. New name: \"%s\"", oldname, name);
}

void RegexRename(int client, char[] name, const char[] oldname)
{
	TrimString(name);
	
	if (strlen(name) < 3)
	{
		Format(name, MAX_NAME_LENGTH, "Player #%d", GetClientUserId(client));
	}
	
	SetClientInfo(client, "name", name);
	LogToFile(logfile, "Renamed %s because his name contained symbols. New name: \"%s\"", oldname, name);
}

void KickPlayer(int client, const char[] message, const char[] forbiddenword)
{
	KickClient(client, "Simple Filters %s by FAQU\n\n\
						You have been kicked for using a bad word in chat.\n\
						Bad word: %s", plugin_version, forbiddenword);
	LogToFile(logfile, "Kicked %N for using a bad word in chat. Message: \"%s\"", client, message);
}

void BanPlayer(int client, const char[] message, const char[] forbiddenword)
{
	char steamid[32], sBantime[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	int iBantime = gc_iBanDuration.IntValue;
	
	if (iBantime != 0)
	{
		Format(sBantime, sizeof(sBantime), "%d minutes", iBantime);
	}
	else if (iBantime == 0)
	{
		Format(sBantime, sizeof(sBantime), "permanent");
	}
	
	ServerCommand("sm_addban %d \"%s\" \"Simple Filters (%s)\"", iBantime, steamid, plugin_version);
	KickClient(client, "Simple Filters %s by FAQU\n\n\
						You have been banned for using a bad word in chat.\n\
						Ban duration: %s\n\
						Bad word: %s", plugin_version, sBantime, forbiddenword);	
	LogToFile(logfile, "Banned %N [%s] for using a bad word in chat. Message: \"%s\"", client, steamid, message);
}

void BlockMessage(int client)
{
	PrintToChat(client, "Your message has been blocked because it contains a bad word.");
	LogToFile(logfile, "Blocked %N's message because it contains a bad word.", client);
}