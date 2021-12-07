#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#define MSG_LENGTH		256
#define PLUGIN_VERSION	"1.1.3"
#define STEAMID_SIZE 	64
new Handle:g_hCvarEnabled;
new Handle:g_hCookieCodName;
new Handle:g_hCookieCodNameOnOff;

public Plugin:myinfo = 
{
	name = "Colored Names",
	author = "Thraka (Original by Afronanny)",
	description = "Adds COD-style color-coding to names in chat",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1269003"
}



public OnPluginStart()
{
	g_hCvarEnabled = CreateConVar("sm_codnamecolor_enabled", "1", "Enable the plugin", FCVAR_PLUGIN);
	CreateConVar("sm_coloredname_version", PLUGIN_VERSION, "Version of COD-Style color-codes", FCVAR_NOTIFY|FCVAR_PLUGIN);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
	RegConsoleCmd("sm_coloredname_on", Command_SetColoredNameOn, "Turns on the colored name for the player");
	RegConsoleCmd("sm_coloredname_off", Command_SetColoredNameOff, "Turns off the colored name for the player");
	RegConsoleCmd("sm_coloredname", Command_SetColoredName, "Sets the current players colored name");
	RegConsoleCmd("sm_coloredname_help", Command_PrintHelp, "Lists helpful information to the client");
	RegConsoleCmd("sm_coloredname_list", Command_ListUsers, "Lists all users with their real and colored names", ADMFLAG_KICK);
	g_hCookieCodName = RegClientCookie("cookie_coloredname", "The name to use in chat. Supports the ^1^2 etc Call of Duty styles.", CookieAccess_Public);
	g_hCookieCodNameOnOff = RegClientCookie("cookie_coloredname_on", "1 = on, 0 = off for the colored names in chat", CookieAccess_Public);
}

public Action:Command_ListUsers(client, args)
{
	new clientCount = 0;
	if (client != 0)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && !IsFakeClient(i))
			{
				decl String:name[MAX_NAME_LENGTH];
				decl String:coloredName[MAX_NAME_LENGTH];
				GetClientName(i, name, MAX_NAME_LENGTH);
				GetClientCookie(i, g_hCookieCodName, coloredName, MAX_NAME_LENGTH);
				ReplyToCommand(client, "%s === %s", name, coloredName);
				clientCount++;
			}
		}
		
		ReplyToCommand(client, "%d Clients Listed", clientCount);
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && !IsFakeClient(i))
			{
				decl String:name[MAX_NAME_LENGTH];
				decl String:coloredName[MAX_NAME_LENGTH];
				GetClientName(i, name, MAX_NAME_LENGTH);
				GetClientCookie(i, g_hCookieCodName, coloredName, MAX_NAME_LENGTH);
				PrintToServer("%s === %s", name, coloredName);
				clientCount++;
			}
		}
		
		PrintToServer("%d Clients Listed", clientCount);
	}
}


public Action:Command_PrintHelp(client, args)
{
	if (client != 0)
	{
		ReplyToCommand(client, "sm_coloredname_on - Turns on the colored name");
		ReplyToCommand(client, "sm_coloredname_off - Turns off the colored name");
		ReplyToCommand(client, "sm_coloredname \"colored name here\" - Sets your colored name");
		ReplyToCommand(client, "-----------------");
		ReplyToCommand(client, "Colors");
		ReplyToCommand(client, "-----------------");
		ReplyToCommand(client, "^0 - Default");
		ReplyToCommand(client, "^1 - Default");
		ReplyToCommand(client, "^2 - White");
		ReplyToCommand(client, "^3 - Team color");
		ReplyToCommand(client, "^4 - Green");
		ReplyToCommand(client, "^5 - Olive green");
		ReplyToCommand(client, "^6 - Item color (usually yellow, black if the client hasn't seen an item found or crafted yet)");
		ReplyToCommand(client, "^7 - Default");
		ReplyToCommand(client, "^8 - Team");
		ReplyToCommand(client, "^9 - Green");
	}
}

public Action:Command_SetColoredNameOn(client, args)
{
	//PrintToChatAll("SetColoredNameOn called");
	if (client != 0)
	{
		//PrintToChatAll("Setting g_hCookieCodNameOnOff 1");
		SetClientCookie(client, g_hCookieCodNameOnOff, "1");
		ReplyToCommand(client, "Colored name is now off");
	}
}

public Action:Command_SetColoredNameOff(client, args)
{
	//PrintToChatAll("SetColoredNameOff called");
	if (client != 0)
	{
		//PrintToChatAll("Setting g_hCookieCodNameOnOff 0");
		SetClientCookie(client, g_hCookieCodNameOnOff, "0");
		ReplyToCommand(client, "Colored name is now on");
	}
}

public Action:Command_SetColoredName(client, args)
{
	//PrintToChatAll("SetColoredName called");
	if (client != 0)
	{
		decl String:name[MAX_NAME_LENGTH];
		
		if (GetCmdArgs() == 1)
		{
			//PrintToChatAll("Getting name arg");			
			GetCmdArg(1, name, MAX_NAME_LENGTH);
			//PrintToChatAll("Setting g_hCookieCodName to %s", name);
			SetClientCookie(client, g_hCookieCodName, name);
			ReplyToCommand(client, "Colored name set.");
		}
		else
		{
			GetClientCookie(client, g_hCookieCodName, name, MAX_NAME_LENGTH);
			ReplyToCommand(client, "Current colored chat name: %s", name);
		}
	}
}

public Action:Command_Say(client, args)
{
	if (GetConVarBool(g_hCvarEnabled) && IsChatTrigger() == false)
	{
		if (client != 0)
		{
			//PrintToChatAll("Checking for cookies cached");
			if (AreClientCookiesCached(client))
			{
				decl String:name[MAX_NAME_LENGTH];
				decl String:temp[3];
				new bool:isOn = false;
				new bool:isDead = !IsPlayerAlive(client);
				
				
				GetClientCookie(client, g_hCookieCodName, name, MAX_NAME_LENGTH);
				GetClientCookie(client, g_hCookieCodNameOnOff, temp, sizeof(temp));
				
				//PrintToChatAll("g_hCookieCodName gotten %s", name);
				//PrintToChatAll("g_hCookieCodNameOnOff gotten %s", temp);
				
				if (!StrEqual(temp, ""))
				{
					if (StringToInt(temp) == 1)
						isOn = true;
				}
				
				//PrintToChatAll("isOn is %i", isOn);
				
				if (!StrEqual(name, "") && isOn)
				{
					//PrintToChatAll("in");
					decl String:msg[MSG_LENGTH];
					decl String:buffer[MSG_LENGTH + MAX_NAME_LENGTH];
					
					GetCmdArgString(msg, sizeof(msg));
					StripQuotes(msg);
					
					if (FindCharInString(msg, '@') != 0)
					{
						ReplaceString(name, sizeof(name), "^0", "\x01");
						ReplaceString(name, sizeof(name), "^1", "\x01");
						ReplaceString(name, sizeof(name), "^2", "\x02");
						ReplaceString(name, sizeof(name), "^3", "\x03");
						ReplaceString(name, sizeof(name), "^4", "\x04");
						ReplaceString(name, sizeof(name), "^5", "\x05");
						ReplaceString(name, sizeof(name), "^6", "\x06");
						ReplaceString(name, sizeof(name), "^7", "\x01");
						ReplaceString(name, sizeof(name), "^8", "\x03");
						ReplaceString(name, sizeof(name), "^9", "\x04");
						
						new AdminId:id = GetUserAdmin(client);
						if (id == INVALID_ADMIN_ID)
							ReplaceString(name, sizeof(name), "[admin]", "", false);
						
						if (!isDead)
							Format(buffer, sizeof(buffer), "\x03%s \x01:  %s", name, msg);
						else
							Format(buffer, sizeof(buffer), "\x01*DEAD* \x03%s \x01:  %s", name, msg);
						
						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsClientConnected(i) && IsClientInGame(i))
							{
								if (!isDead)
								{
									SayText2(i, client, buffer);
								}
								else if (isDead && !IsPlayerAlive(i))
								{
									SayText2(i, client, buffer);
								}
							}
						}
						
						WriteChatLog(client, "say", msg);
						
						return Plugin_Stop;
					}
				}
				//PrintToChatAll("out");
			}
		}
	}
	return Plugin_Continue;
}

public Action:Command_SayTeam(client, args)
{
	if (GetConVarBool(g_hCvarEnabled) && IsChatTrigger() == false)
	{
		if (client != 0)
		{
			if (AreClientCookiesCached(client))
			{
				decl String:name[MAX_NAME_LENGTH];
				decl String:temp[3];
				new bool:isOn = false;
				new bool:isDead = !IsPlayerAlive(client);
				
				GetClientCookie(client, g_hCookieCodName, name, MAX_NAME_LENGTH);
				GetClientCookie(client, g_hCookieCodNameOnOff, temp, sizeof(temp));
				
				if (!StrEqual(temp, ""))
				{
					if (StringToInt(temp) == 1)
						isOn = true;
				}
				
				if (!StrEqual(name, "") && isOn)
				{
					decl String:msg[MSG_LENGTH];
					decl String:buffer[MSG_LENGTH + MAX_NAME_LENGTH];
					
					GetCmdArgString(msg, sizeof(msg));
					StripQuotes(msg);
					
					if (FindCharInString(msg, '@') != 0)
					{
						
						ReplaceString(name, sizeof(name), "^0", "\x01");
						ReplaceString(name, sizeof(name), "^1", "\x01");
						ReplaceString(name, sizeof(name), "^2", "\x02");
						ReplaceString(name, sizeof(name), "^3", "\x03");
						ReplaceString(name, sizeof(name), "^4", "\x04");
						ReplaceString(name, sizeof(name), "^5", "\x05");
						ReplaceString(name, sizeof(name), "^6", "\x06");
						ReplaceString(name, sizeof(name), "^7", "\x01");
						ReplaceString(name, sizeof(name), "^8", "\x03");
						ReplaceString(name, sizeof(name), "^9", "\x04");
						
						new AdminId:id = GetUserAdmin(client);
						if (id == INVALID_ADMIN_ID)
							ReplaceString(name, sizeof(name), "[admin]", "", false);
						
						if (IsPlayerAlive(client))
							Format(buffer, sizeof(buffer), "\x01(TEAM) \x03%s \x01:  %s", name, msg);
						else
							Format(buffer, sizeof(buffer), "\x01*DEAD*(TEAM) \x03%s \x01:  %s", name, msg);

						new team = GetClientTeam(client);
						
						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team)
							{
								if (!isDead)
								{
									SayText2(i, client, buffer);
								}
								else if (isDead && !IsPlayerAlive(i))
								{
									SayText2(i, client, buffer);
								}
							}
						}
						
						WriteChatLog(client, "say_team", msg);
						
						return Plugin_Stop;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}


stock SayText2(client, author, const String:message[])
{
	new Handle:hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, message);
	EndMessage();
}

stock WriteChatLog(client, const String:sayOrSayTeam[], const String:msg[MSG_LENGTH])
{
	decl String:name[MAX_NAME_LENGTH];
	decl String:steamid[STEAMID_SIZE];
	decl String:teamName[10];
	
	GetClientName(client, name, MAX_NAME_LENGTH);
	GetTeamName(GetClientTeam(client), teamName, sizeof(teamName));
	GetClientAuthString(client, steamid, sizeof(steamid));
	LogToGame("\"%s<%i><%s><%s>\" %s \"%s\"", name, GetClientUserId(client), steamid, teamName, sayOrSayTeam, msg);
}

