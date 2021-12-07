/************************************************************************
*************************************************************************
Simple Chat Colors
Description:
 		Changes the colors of players chat based on config file
*************************************************************************
*************************************************************************
This file is part of Simple Plugins project.

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id: simple-chatcolors.sp 66 2009-12-22 23:40:30Z antithasys $
$Author: antithasys $
$Revision: 66 $
$Date: 2009-12-22 17:40:30 -0600 (Tue, 22 Dec 2009) $
$LastChangedBy: antithasys $
$LastChangedDate: 2009-12-22 17:40:30 -0600 (Tue, 22 Dec 2009) $
$URL: https://svn.simple-plugins.com/svn/simpleplugins/trunk/Simple%20Chat%20Colors/addons/sourcemod/scripting/simple-chatcolors.sp $
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <loghelper>
#include <simple-plugins>
#include <clientprefs>

#define PLUGIN_VERSION "1.1.0-nw"

#define CHAT_SYMBOL '@'
#define TRIGGER_SYMBOL1 '!'
#define TRIGGER_SYMBOL2 '/'
#define CHAR_PERCENT "%"
#define CHAR_NULL "\0"

enum e_Settings
{
	Handle:hGroupName,
	Handle:hGroupFlag,
	Handle:hNameColor,
	Handle:hTextColor,
	Handle:hTagText,
	Handle:hTagColor,
	Handle:hOverrides
};

new Handle:g_Cvar_hDebug = INVALID_HANDLE;
new Handle:g_Cvar_hTriggerBackup = INVALID_HANDLE;

new bool:g_bDebug = false;
new bool:g_bTriggerBackup = false;
new bool:g_bOverrideSection = false;

new g_iArraySize;

new Handle:g_aSettings[e_Settings];
new g_aPlayerIndex[MAXPLAYERS + 1] = { -1, ... };

new Handle:c_PlayerEnabled;

public Plugin:myinfo =
{
	name = "Simple Chat Colors",
	author = "Simple Plugins",
	description = "Changes the colors of players chat based on config file.",
	version = PLUGIN_VERSION,
	url = "http://www.simple-plugins.com"
};

/**
Sourcemod callbacks
*/
public OnPluginStart()
{
	
	/**
	Get game type and load the team numbers
	*/
	g_CurrentMod = GetCurrentMod();
	LoadCurrentTeams();
	LogAction(0, -1, "[SCC] Detected [%s].", g_sGameName[g_CurrentMod]);
	
	/**
	Need to create all of our console variables.
	*/
	CreateConVar("sm_chatcolors_version", PLUGIN_VERSION, "Simple Chat Colors", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_hDebug = CreateConVar("sm_chatcolors_debug", "0", "Enable/Disable debugging information");
	g_Cvar_hTriggerBackup = CreateConVar("sm_chatcolors_triggerbackup", "0", "Enable/Disable the trigger backup");
	
	/**
	Hook console variables
	*/
	HookConVarChange(g_Cvar_hDebug, ConVarSettingsChanged);
	HookConVarChange(g_Cvar_hTriggerBackup, ConVarSettingsChanged);
	
	/**
	Need to register the commands we are going to use
	*/
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
	RegAdminCmd("sm_reloadchatcolors", Command_Reload, ADMFLAG_GENERIC,  "Reloads settings from config file");
	RegAdminCmd("sm_printchatcolors", Command_PrintChatColors, ADMFLAG_GENERIC,  "Prints out the color names in their color");
	RegConsoleCmd("sm_colortoggle", Command_ToggleEnable);
	RegConsoleCmd("sm_colorstatus", Command_ShowStatus);
	
	/**
	Create the arrays
	*/
	for (new e_Settings:i; i < e_Settings:sizeof(g_aSettings); i++)
	{
		g_aSettings[i] = CreateArray(128, 1);
	}
	
	/**
	Load the admins and colors from the config
	*/
	ProcessConfigFile();
	g_iArraySize = GetArraySize(g_aSettings[hGroupName]) - 1;
	
	/**
	Make a Cookie
	*/
	c_PlayerEnabled = RegClientCookie("sm_color_enabled", "", CookieAccess_Public);
	
	/**
	Hook event
	*/
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnConfigsExecuted()
{
	g_bDebug = GetConVarBool(g_Cvar_hDebug);
	ReloadConfigFile();	
}

public OnClientPostAdminCheck(client)
{
	
	/**
	Check the client to see if they have a color
	*/
	CheckPlayer(client);
}

public OnClientDisconnect(client)
{
	g_aPlayerIndex[client] = -1;
}

public OnMapStart()
{
	GetTeams();
}

/**
Adjust the settings if a convar was changed
*/
public ConVarSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_Cvar_hDebug)
	{
		if (StringToInt(newValue) == 1)
		{
			g_bDebug = true;
		}
		else
		{
			g_bDebug = false;
		}
	}
	else if (convar == g_Cvar_hTriggerBackup)
	{
		if (StringToInt(newValue) == 1)
		{
			g_bTriggerBackup = true;
		}
		else
		{
			g_bTriggerBackup = false;
		}
	}
}

/**
Commands
*/
public Action:Command_Say(client, args)
{
	
	/**
	Make sure its not the server or a chat trigger
	*/
	if (client == 0 || IsChatTrigger() || ColorDisabled(client))
	{
		return Plugin_Continue;
	}
	
	/**
	Get the message
	*/
	decl	String:sMessage[1024];
	GetCmdArgString(sMessage, sizeof(sMessage));
	
	/**
	Process the message
	*/
	return ProcessMessage(client, false, sMessage, sizeof(sMessage));
}

public Action:Command_SayTeam(client, args)
{
	
	/**
	Make sure we are enabled.
	*/
	if (client == 0 || IsChatTrigger() || ColorDisabled(client))
	{
		return Plugin_Continue;
	}
	
	/**
	Get the message
	*/
	decl	String:sMessage[1024];
	GetCmdArgString(sMessage, sizeof(sMessage));
	
	/**
	Process the message
	*/
	return ProcessMessage(client, true, sMessage, sizeof(sMessage));
}

public Action:Command_Reload(client, args)
{
	ReloadConfigFile();	
	return Plugin_Handled;
}

public Action:Command_PrintChatColors(client, args)
{
	CPrintToChat(client, "{default}default");
	CPrintToChat(client, "{green}green");
	CPrintToChat(client, "{lightgreen}lightgreen");
	CPrintToChat(client, "{red}red");
	CPrintToChat(client, "{blue}blue");
	CPrintToChatEx(client, client, "{teamcolor}teamcolor");
	CPrintToChat(client, "{olive}olive");
	return Plugin_Handled;
}

public Action:Command_ToggleEnable(client, args)
{
	decl String:strCookie[16];
	GetClientCookie(client, c_PlayerEnabled, strCookie, sizeof(strCookie));
	
	if(StrEqual(strCookie, "true"))
	{
		SetClientCookie(client, c_PlayerEnabled, "false");
		ReplyToCommand(client, "Custom chat color is disabled.");
	}
	else if(StrEqual(strCookie, "false"))
	{
		SetClientCookie(client, c_PlayerEnabled, "true");
		ReplyToCommand(client, "Custom chat color is enabled.");
	}
	else
	{
		SetClientCookie(client, c_PlayerEnabled, "true");
		ReplyToCommand(client, "Custom chat color was not properly set, but is now enabled.");
	}
	return Plugin_Handled;
}

public Action:Command_ShowStatus(client, args)
{
	decl String:strCookie[16];
	GetClientCookie(client, c_PlayerEnabled, strCookie, sizeof(strCookie));
	
	if(StrEqual(strCookie, "true"))
	{
		ReplyToCommand(client, "Custom chat color is enabled.");
	}
	else if(StrEqual(strCookie, "false"))
	{
		ReplyToCommand(client, "Custom chat color is disabled.");
	}
	else
	{
		SetClientCookie(client, c_PlayerEnabled, "true");
		ReplyToCommand(client, "Custom chat color was not properly set, but is now enabled.");
	}
	return Plugin_Handled;
}

/**
Stock Functions
*/
stock CheckPlayer(client)
{
	new String:sFlags[15];
	new String:sClientSteamID[64];
	new bool:bDebug_FoundBySteamID = false;
	new iGroupFlags;
	new iFlags;
	new iIndex = -1;
	
	/**
	Look for a steamid first
	*/
	GetClientAuthString(client, sClientSteamID, sizeof(sClientSteamID));
	iIndex = FindStringInArray(g_aSettings[hGroupName], sClientSteamID);	
	if (iIndex != -1)
	{
		g_aPlayerIndex[client] = iIndex;
		bDebug_FoundBySteamID = true;
	}
	
	/**
	Didn't find one, check for flags
	*/
	else
	{
		
		/**
		Search for flag in groups
		*/
		iFlags = GetUserFlagBits(client);
		for (new i = 0; i < g_iArraySize; i++)
		{
			GetArrayString(g_aSettings[hGroupFlag], i, sFlags, sizeof(sFlags));
			iGroupFlags = ReadFlagString(sFlags);
			if (iFlags & iGroupFlags)
			{
				g_aPlayerIndex[client] = i;
				iIndex = i;
				break;
			}
		}
		
		/**
		Check to see if flag was found
		*/
		if (iIndex == -1)
		{
			
			/**
			No flag, look for an "everyone" group
			*/
			iIndex = FindStringInArray(g_aSettings[hGroupName], "everyone");
			if (iIndex != -1)
			{
				g_aPlayerIndex[client] = iIndex;
			}
		}
	}
	
	if (g_bDebug)
	{
		if (g_aPlayerIndex[client] == -1)
		{
			PrintToConsole(client, "[SCC] Client %N was NOT found in colors config", client);
		}
		else
		{
			new String:sGroupName[256];
			GetArrayString(g_aSettings[hGroupName], g_aPlayerIndex[client], sGroupName, sizeof(sGroupName));
			PrintToConsole(client, "[SCC] Client %N was found in colors config", client);
			if (bDebug_FoundBySteamID)
			{
				PrintToConsole(client, "[SCC] Found steamid: %s in config file", sGroupName);
			}
			else
			{
				PrintToConsole(client, "[SCC] Found in group: %s in config file", sGroupName);
			}
		}
	}
}

stock bool:IsStringBlank(const String:input[])
{
	new len = strlen(input);
	for (new i=0; i<len; i++)
	{
		if (!IsCharSpace(input[i]))
		{
			return false;
		}
	}
	return true;
}

stock Action:ProcessMessage(client, bool:teamchat, String:message[], maxlength)
{
	
	/**
	Make sure the client has a color assigned
	*/
	if (g_aPlayerIndex[client] != -1)
	{
	
		/**
		The client is, so get the chat message and strip it down.
		*/
		decl String:sChatMsg[1280];
		StripQuotes(message);
		TrimString(message);
		
		/**
		Because we are dealing with a chat message, lets take out all the %'s
		*/
		ReplaceString(message, maxlength, CHAR_PERCENT, CHAR_NULL);
		
		/**
		Make sure it's not blank
		*/
		if (IsStringBlank(message))
		{
			return Plugin_Stop;
		}
		
		/**
		Bug out if they are using the admin chat symbol (admin chat).
		*/
		if (message[0] == CHAT_SYMBOL)
		{
			return Plugin_Continue;
		}
		/**
		If we are using the trigger backup, then bug out on the triggers
		*/
		else if (g_bTriggerBackup && (message[0] == TRIGGER_SYMBOL1 || message[0] == TRIGGER_SYMBOL2))
		{
			return Plugin_Continue;
		}
		/**
		Make sure it's not a override string
		*/
		else if (FindStringInArray(g_aSettings[hOverrides], message) != -1)
		{
			return Plugin_Continue;
		}
		
		/**
		Log the message for hlstatsx and other things.
		*/
		if (teamchat)
		{
			LogPlayerEvent(client, "say_team", message);
		}
		else
		{
			LogPlayerEvent(client, "say", message);
		}
		
		/**
		Format the message.
		*/
		FormatMessage(	client, GetClientTeam(client), IsPlayerAlive(client), teamchat, g_aPlayerIndex[client], message, sChatMsg, sizeof(sChatMsg));
		
		/**
		Send the message.
		*/
		new bool:bTeamColorUsed = StrContains(sChatMsg, "{teamcolor}") != -1 ? true : false;
		new iCurrentTeam = GetClientTeam(client);
		if (teamchat)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == iCurrentTeam)
				{
					if (bTeamColorUsed)
					{
						CPrintToChatEx(i, client, "%s", sChatMsg);
					}
					else
					{
						CPrintToChat(i, "%s", sChatMsg);
					}
				}
			}
		}
		else
		{
			if (bTeamColorUsed)
			{
				CPrintToChatAllEx(client, "%s", sChatMsg);
			}
			else
			{
				CPrintToChatAll("%s", sChatMsg);
			}
		}
		
		/**
		We are done, bug out, and stop the original chat message.
		*/
		return Plugin_Stop;
	}

	/**
	Doesn't have a color assigned, bug out.
	*/
	return Plugin_Continue;
}

stock FormatMessage(client, team, bool:alive, bool:teamchat, index, const String:message[], String:chatmsg[], maxlength)
{
	decl	String:sDead[10],
			String:sTeam[15],
			String:sClientName[64];
	
	GetClientName(client, sClientName, sizeof(sClientName));
	
	if (teamchat)
	{
		if ((g_CurrentMod == GameType_L4D || g_CurrentMod == GameType_L4D2) && team == g_aCurrentTeams[Team1])
		{
			Format(sTeam, sizeof(sTeam), "(Survivor) ");
		}
		else if ((g_CurrentMod == GameType_L4D || g_CurrentMod == GameType_L4D2) && team == g_aCurrentTeams[Team2])
		{
			Format(sTeam, sizeof(sTeam), "(Infected) ");
		}
		else if (team != g_aCurrentTeams[Spectator])
		{
			Format(sTeam, sizeof(sTeam), "(TEAM) ");
		}
		else
		{
			Format(sTeam, sizeof(sTeam), "(Spectator) ");
		}
	}
	else
	{
		if (team != g_aCurrentTeams[Spectator])
		{
			Format(sTeam, sizeof(sTeam), "");
		}
		else
		{
			Format(sTeam, sizeof(sTeam), "*SPEC* ");
		}
	}
	if (team != g_aCurrentTeams[Spectator])
	{
		if (alive)
		{
			Format(sDead, sizeof(sDead), "");
		}
		else if (g_CurrentMod != GameType_L4D || g_CurrentMod != GameType_L4D2)
		{
			Format(sDead, sizeof(sDead), "*DEAD* ");
		}
	}
	else
	{
		Format(sDead, sizeof(sDead), "");
	}
	
	new String:sNameColor[15];
	new String:sTextColor[15];
	GetArrayString(g_aSettings[hNameColor], index, sNameColor, sizeof(sNameColor));
	GetArrayString(g_aSettings[hTextColor], index, sTextColor, sizeof(sTextColor));
	
	new String:sTagText[24];
	new String:sTagColor[15];
	GetArrayString(g_aSettings[hTagText], index, sTagText, sizeof(sTagText));
	GetArrayString(g_aSettings[hTagColor], index, sTagColor, sizeof(sTagColor));
	
	Format(chatmsg, maxlength, "{default}%s%s%s%s%s%s {default}:  %s%s", sDead, sTeam, sTagColor, sTagText, sNameColor, sClientName, sTextColor, message);
}

stock ColorDisabled(client)
{
	decl String:strCookie[16];
	GetClientCookie(client, c_PlayerEnabled, strCookie, sizeof(strCookie));
	
	if(!StrEqual(strCookie, "true"))
	{
		return true;
	}
	return false;
}

/**
Parse the config file
*/
stock ProcessConfigFile()
{
	new String:sConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/simple-chatcolors.cfg");
	if (!FileExists(sConfigFile)) 
	{
		/**
		Config file doesn't exists, stop the plugin
		*/
		LogError("[SCC] Simple Chat Colors is not running! Could not find file %s", sConfigFile);
		SetFailState("Could not find file %s", sConfigFile);
	}
	else if (!ParseConfigFile(sConfigFile))
	{
		/**
		Config file doesn't exists, stop the plugin
		*/
		LogError("[SCC] Simple Chat Colors is not running! Failed to parse %s", sConfigFile);
		SetFailState("Could not find file %s", sConfigFile);
	}
}

stock ReloadConfigFile()
{
	
	/**
	Clear the arrays
	*/
	for (new e_Settings:i; i < e_Settings:sizeof(g_aSettings); i++)
	{
		ClearArray(g_aSettings[i]);
	}
	
	/**
	Load the admins, groups, and colors from the config
	*/
	ProcessConfigFile();
	g_iArraySize = GetArraySize(g_aSettings[hGroupName]) - 1;
	
	/**
	Recheck all the online players for assigned colors
	*/
	for (new index = 1; index <= MaxClients; index++)
	{
		if (IsClientConnected(index) && IsClientInGame(index))
		{
			CheckPlayer(index);
		}
	}
}

bool:ParseConfigFile(const String:file[]) 
{
	
	/**
	Clear the arrays
	*/
	for (new i = 0; i < sizeof(g_aSettings); i++)
	{
		ClearArray(g_aSettings[e_Settings:i]);
	}

	new Handle:hParser = SMC_CreateParser();
	SMC_SetReaders(hParser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(hParser, Config_End);

	new line = 0;
	new col = 0;
	new String:error[128];
	new SMCError:result = SMC_ParseFile(hParser, file, line, col);
	CloseHandle(hParser);

	if (result != SMCError_Okay) 
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}
	return (result == SMCError_Okay);
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) 
{
	if (StrEqual(section, "admin_colors"))
	{
		return SMCParse_Continue;
	}
	else if (StrEqual(section, "Overrides"))
	{
		g_bOverrideSection = true;
		if (g_bDebug)
		{
			PrintToChatAll("In override");
		}
	}
	else
	{
		g_bOverrideSection = false;
		if (g_bDebug)
		{
			PrintToChatAll("In section: %s", section);
		}
	}
	PushArrayString(g_aSettings[hGroupName], section);
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if (g_bOverrideSection)
	{
		PushArrayString(g_aSettings[hOverrides], key);
		if (g_bDebug)
		{
			PrintToChatAll("Storing override: %s", key);
		}
	}
	else
	{
		if(StrEqual(key, "flag", false))
		{
			PushArrayString(g_aSettings[hGroupFlag], value);
		}
		else if(StrEqual(key, "tag", false))
		{
			PushArrayString(g_aSettings[hTagText], value);
		}
		else if(StrEqual(key, "tagcolor", false))
		{
			PushArrayString(g_aSettings[hTagColor], value);
		}
		else if(StrEqual(key, "namecolor", false))
		{
			PushArrayString(g_aSettings[hNameColor], value);
		}
		else if(StrEqual(key, "textcolor", false))
		{
			PushArrayString(g_aSettings[hTextColor], value);
		}
		if (g_bDebug)
		{
			PrintToChatAll("Storing %s: %s", key,value);
		}
	}
	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser) 
{
	if (g_bOverrideSection)
	{
		g_bOverrideSection = false;
	}
	if (g_bDebug)
	{
		PrintToChatAll("Leaving section");
	}
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) 
{
	if (failed)
	{
		SetFailState("Plugin configuration error");
	}
}

/**
Hooks
*/
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:strCookie[16];
	GetClientCookie(client, c_PlayerEnabled, strCookie, sizeof(strCookie));
	
	if(StrEqual(strCookie, ""))
	{
		SetClientCookie(client, c_PlayerEnabled, "true");
	}
}