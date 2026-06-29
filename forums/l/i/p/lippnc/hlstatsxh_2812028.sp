/**
 * HLstatsX Community Edition - SourceMod plugin to display ingame messages
 * http://www.hlxcommunity.com/
 * Copyright (C) 2008-2009 Nicholas Hastings
 * Copyright (C) 2007-2009 TTS Oetzel & Goerz GmbH
 * Modified by Nicholas Hastings (psychonic) for use with HLstatsX Community Edition
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <loghelper>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <clientprefs>
#define VERSION "1.6.22h"
#define HLXTAG "HLstatsX:CE"

enum GameType {
	Game_Unknown = -1,
	Game_CSS,
	Game_DODS,
	Game_L4D,
	Game_TF,
	Game_HL2MP,
	Game_INSMOD,
	Game_FF,
	Game_ZPS,
	Game_AOC,
	Game_FOF,
	Game_GES,
	Game_PVKII,
	Game_CSP,
	Game_ND,
	Game_DDD,
	Game_CSGO,
};

GameType gamemod = Game_Unknown;

Handle hlx_block_chat_commands;
Handle hlx_message_prefix;
Handle hlx_protect_address;
Handle hlx_server_tag;
Handle sv_tags;
Handle message_recipients;
char blocked_commands[][] = { "rank", "skill", "points", "place", "session", "session_data", 
                                     "kpd", "kdratio", "kdeath", "next", "load", "status", "servers", 
                                     "top20", "top10", "top5", "clans", "bans", "cheaters", "statsme", "weapons", 
                                     "weapon", "action", "actions", "accuracy", "targets", "target", "kills", 
                                     "kill", "player_kills", "cmd", "cmds", "command", "hlx_display 0", 
                                     "hlx_display 1", "hlx_teams 0", "hlx_teams 1", "hlx_hideranking", 
                                     "hlx_chat 0", "hlx_chat 1", "hlx_menu", "servers 1", "servers 2", 
                                     "servers 3", "hlx", "hlstatsx", "help" };

Menu HLstatsXMenuMain;
Menu HLstatsXMenuAuto;
Menu HLstatsXMenuEvents;

Handle PlayerColorArray;
int ColorSlotArray[] = { -1, -1, -1, -1, -1, -1 };

char ct_models[][] = {
	"models/player/ct_urban.mdl", 
	"models/player/ct_gsg9.mdl", 
	"models/player/ct_sas.mdl", 
	"models/player/ct_gign.mdl"
};

char ts_models[][] = {
	"models/player/t_phoenix.mdl", 
	"models/player/t_leet.mdl", 
	"models/player/t_arctic.mdl", 
	"models/player/t_guerilla.mdl"
};

char modnamelist[][] = {
	"Counter-Strike: Source",
	"Day of Defeat: Source",
	"Left 4 Dead (1 or 2)",
	"Team Fortress 2",
	"Half-Life 2 Deathmatch",
	"Insurgency",
	"Fortress Forever",
	"Zombie Panic: Source",
	"Age of Chivalry",
	"Fistful of Frags",
	"GoldenEye: Source",
	"Pirates, Vikings, and Knights",
	"CSPromod",
	"Nuclear Dawn",
	"Dino D-Day",
	"Counter-Strike: Global Offensive"
};

char message_prefix[32];
bool g_bPlyrCanDoMotd[MAXPLAYERS+1];
bool g_bGameCanDoMotd = true;
bool g_bTrackColors4Chat;
EngineVersion g_evEngineVersion = Engine_Unknown;
Handle g_cvarTeamPlay = INVALID_HANDLE;
bool g_bTeamPlay;
bool g_bLateLoad = false;
bool g_bIgnoreNextTagChange = false;
Handle g_hCustomTags;

#define SVTAGSIZE 128

public Plugin myinfo = {
	name = "HLstatsX:CE Ingame Plugin",
	author = "psychonic modded by Huck",
	description = "Provides ingame functionality for interaction from an HLstatsX CE installation",
	version = VERSION,
	url = "https://bitbucket.org/Maverick_of_UC/hlstatsx-community-edition/wiki/Home"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	MarkNativeAsOptional("CS_SwitchTeam");
	MarkNativeAsOptional("CS_RespawnPlayer");
	MarkNativeAsOptional("SetCookieMenuItem");
	
	return APLRes_Success;
}

public void OnPluginStart() 
{
	get_server_mod();

	CreateHLstatsXMenuMain(HLstatsXMenuMain);
	CreateHLstatsXMenuAuto(HLstatsXMenuAuto);
	CreateHLstatsXMenuEvents(HLstatsXMenuEvents);

	RegServerCmd("hlx_sm_psay",          hlx_sm_psay);
	RegServerCmd("hlx_sm_psay2",         hlx_sm_psay2);
	RegServerCmd("hlx_sm_bulkpsay",      hlx_sm_psay);
	RegServerCmd("hlx_sm_csay",          hlx_sm_csay);
	RegServerCmd("hlx_sm_msay",          hlx_sm_msay);
	RegServerCmd("hlx_sm_tsay",          hlx_sm_tsay);
	RegServerCmd("hlx_sm_hint",          hlx_sm_hint);
	RegServerCmd("hlx_sm_browse",        hlx_sm_browse);
	RegServerCmd("hlx_sm_swap",          hlx_sm_swap);
	RegServerCmd("hlx_sm_redirect",      hlx_sm_redirect);
	RegServerCmd("hlx_sm_player_action", hlx_sm_player_action);
	RegServerCmd("hlx_sm_team_action",   hlx_sm_team_action);
	RegServerCmd("hlx_sm_world_action",  hlx_sm_world_action);

	if (gamemod == Game_INSMOD)
	{
		AddCommandListener(hlx_block_commands, "say2");
	}
	else if (gamemod == Game_ND)
	{
		AddCommandListener(hlx_block_commands, "say_squad");
	}
	
	AddCommandListener(hlx_block_commands, "say");
	AddCommandListener(hlx_block_commands, "say_team");
	
	switch (gamemod)
	{
		case Game_CSS, Game_L4D, Game_TF, Game_HL2MP, Game_AOC, Game_FOF, Game_PVKII, Game_ND, Game_DDD, Game_CSGO:
		{
			g_bTrackColors4Chat = true;
			HookEvent("player_team",  HLstatsX_Event_PlyTeamChange, EventHookMode_Pre);
		}
	}
	
	switch (gamemod)
	{
		case Game_L4D, Game_INSMOD, Game_GES, Game_CSGO:
		{
			g_bGameCanDoMotd = false;
		}
	}
	
	if (gamemod == Game_HL2MP)
	{
		g_cvarTeamPlay = FindConVar("mp_teamplay");
		if (g_cvarTeamPlay != INVALID_HANDLE)
		{
			g_bTeamPlay = GetConVarBool(g_cvarTeamPlay);
			HookConVarChange(g_cvarTeamPlay, OnTeamPlayChange);
		}
	}
	
	CreateConVar("hlxce_plugin_version", VERSION, "HLstatsX:CE Ingame Plugin", FCVAR_NOTIFY);
	CreateConVar("hlxce_version", "1.6.19h", "HLstatsX:CE Web Version", FCVAR_NOTIFY);
	CreateConVar("hlxce_webpage", "https://bitbucket.org/Maverick_of_UC/hlstatsx-community-edition/wiki/Home", "HLstatsX:CE Web Depository", FCVAR_NOTIFY);
	
	hlx_block_chat_commands = CreateConVar("hlx_block_commands", "0", "If activated HLstatsX commands are blocked from the chat area");
	hlx_message_prefix = CreateConVar("hlx_message_prefix", "HLstatsX", "Define the prefix displayed on every HLstatsX ingame message");
	hlx_protect_address = CreateConVar("hlx_protect_address", "", "Address to be protected for logging/forwarding");
	hlx_server_tag = CreateConVar("hlx_server_tag", "0", "If enabled, adds \"HLstatsX\" to server tags on supported games. 1 = Enabled (default), 0 = Disabled", _, true, 0.0, true, 1.0);
	
	g_hCustomTags = CreateArray(SVTAGSIZE);
	sv_tags = FindConVar("sv_tags");
	AutoExecConfig(true, "hlstatsxh");
	
	if (g_bLateLoad)
	{
		GetConVarString(hlx_message_prefix, message_prefix, sizeof(message_prefix));
		char protaddr[24];
		GetConVarString(hlx_protect_address, protaddr, sizeof(protaddr));
		OnProtectAddressChange(hlx_protect_address, "", protaddr);
	}
	
	MyAddServerTag(HLXTAG);
	
	HookConVarChange(hlx_message_prefix, OnMessagePrefixChange);
	HookConVarChange(hlx_protect_address, OnProtectAddressChange);
	HookConVarChange(hlx_server_tag, OnServerTagChange);
	if (sv_tags != INVALID_HANDLE)
	{
		HookConVarChange(sv_tags, OnSVTagsChange);
	}
	
	RegServerCmd("log", ProtectLoggingChange);
	RegServerCmd("logaddress_del", ProtectForwardingChange);
	RegServerCmd("logaddress_delall", ProtectForwardingDelallChange);
	RegServerCmd("hlx_message_prefix_clear", MessagePrefixClear);

	PlayerColorArray = CreateArray();
	message_recipients = CreateStack();
	
	GetTeams(gamemod == Game_INSMOD);
}


public void OnAllPluginsLoaded()
{
	if (LibraryExists("clientprefs"))
	{
		SetCookieMenuItem(HLXSettingsMenu, 0, "HLstatsX:CE Settings");
	}
}

public void HLXSettingsMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		DisplayMenu(HLstatsXMenuMain, client, MENU_TIME_FOREVER);
	}
}


public void OnMapStart()
{
	GetTeams(gamemod == Game_INSMOD);

	if (g_bTrackColors4Chat)
	{
		find_player_team_slot(2);
		find_player_team_slot(3);
		if (gamemod == Game_PVKII)
		{
			find_player_team_slot(4);
		}
	}
}

bool BTagsSupported()
{
	return (sv_tags != INVALID_HANDLE && (g_evEngineVersion == Engine_SourceSDK2007 || g_evEngineVersion == Engine_DODS || g_evEngineVersion == Engine_HL2DM || g_evEngineVersion == Engine_TF2 || gamemod == Game_ND));
}

stock void MyAddServerTag(const char[] tag)
{
	if (!BTagsSupported())
	{
		// game doesn't support sv_tags
		return;
	}
	
	if (!GetConVarBool(hlx_server_tag))
	{
		return;
	}
	
	if (FindStringInArray(g_hCustomTags, tag) == -1)
	{
		PushArrayString(g_hCustomTags, tag);
	}
	
	char current_tags[SVTAGSIZE];
	GetConVarString(sv_tags, current_tags, sizeof(current_tags));
	if (StrContains(current_tags, tag) > -1)
	{
		// already have tag
		return;
	}
	
	char new_tags[SVTAGSIZE];
	Format(new_tags, sizeof(new_tags), "%s%s%s", current_tags, (current_tags[0]!=0)?",":"", tag);
	
	int flags = GetConVarFlags(sv_tags);
	SetConVarFlags(sv_tags, flags & ~FCVAR_NOTIFY);
	g_bIgnoreNextTagChange = true;
	SetConVarString(sv_tags, new_tags);
	g_bIgnoreNextTagChange = false;
	SetConVarFlags(sv_tags, flags);
}

stock void MyRemoveServerTag(const char[] tag)
{
	if (!BTagsSupported())
	{
		// game doesn't support sv_tags
		return;
	}
	
	int idx = FindStringInArray(g_hCustomTags, tag);
	if (idx > -1)
	{
		RemoveFromArray(g_hCustomTags, idx);
	}
	
	char current_tags[SVTAGSIZE];
	GetConVarString(sv_tags, current_tags, sizeof(current_tags));
	if (StrContains(current_tags, tag) == -1)
	{
		// tag isn't on here, just bug out
		return;
	}
	
	ReplaceString(current_tags, sizeof(current_tags), tag, "");
	ReplaceString(current_tags, sizeof(current_tags), ",,", "");
	
	int flags = GetConVarFlags(sv_tags);
	SetConVarFlags(sv_tags, flags & ~FCVAR_NOTIFY);
	g_bIgnoreNextTagChange = true;
	SetConVarString(sv_tags, current_tags);
	g_bIgnoreNextTagChange = false;
	SetConVarFlags(sv_tags, flags);
}

void get_server_mod()
{
	char game_description[64];
	GetGameDescription(game_description, sizeof(game_description), true);
	
	if (StrContains(game_description, "Counter-Strike: Source", false) != -1)
	{
		gamemod = Game_CSS;
	}
	if (StrContains(game_description, "Counter-Strike: Global Offensive", false) != -1)
	{
		gamemod = Game_CSGO;
	}
	else if (StrContains(game_description, "Day of Defeat", false) != -1)
	{
		gamemod = Game_DODS;
	}
	else if (StrContains(game_description, "Half-Life 2 Deathmatch", false) != -1)
	{
		gamemod = Game_HL2MP;
	}
	else if (StrContains(game_description, "Team Fortress", false) != -1)
	{
		gamemod = Game_TF;
	}
	else if (StrContains(game_description, "L4D", false) != -1 || StrContains(game_description, "Left 4 D", false) != -1)
	{
		gamemod = Game_L4D;
	}
	else if (StrContains(game_description, "Insurgency", false) != -1)
	{
		gamemod = Game_INSMOD;
		//psychonic - added detection for more supported games
	}
	else if (StrContains(game_description, "Fortress Forever", false) != -1)
	{
		gamemod = Game_FF;
	}
	else if (StrContains(game_description, "ZPS", false) != -1)
	{
		gamemod = Game_ZPS;
	}
	else if (StrContains(game_description, "Age of Chivalry", false) != -1)
	{
		gamemod = Game_AOC;
	}
	else if (StrContains(game_description, "PVKII", false) != -1)
	{
		gamemod = Game_PVKII;
	}
	else if (StrContains(game_description, "CSPromod", false) != -1)
	{
		gamemod = Game_CSP;
	}
	else if (StrContains(game_description, "Nuclear Dawn", false) != -1)
	{
		gamemod = Game_ND;
	}
	
	// game mod could not detected, try further
	if (gamemod == Game_Unknown)
	{
		char game_folder[64];
		GetGameFolderName(game_folder, sizeof(game_folder));
		if (StrContains(game_folder, "cstrike", false) != -1)
		{
			gamemod = Game_CSS;
		}
		else if (strncmp(game_folder, "dod", 3, false) == 0)
		{
			gamemod = Game_DODS;
		}
		else if (StrContains(game_folder, "hl2mp", false) != -1 || StrContains(game_folder, "hl2ctf", false) != -1)
		{
			gamemod = Game_HL2MP;
		}
		else if (StrContains(game_folder, "fistful_of_frags", false) != -1)
		{
			gamemod = Game_FOF;
		}
		else if (strncmp(game_folder, "tf", 2, false) == 0)
		{
			gamemod = Game_TF;
		}
		else if (StrContains(game_folder, "left4dead", false) != -1)
		{
			gamemod = Game_L4D;
		}
		else if (StrContains(game_folder, "insurgency", false) != -1)
		{
			gamemod = Game_INSMOD;
			//psychonic - added detection for more supported games
		}
		else if (StrContains(game_folder, "FortressForever", false) != -1)
		{
			gamemod = Game_FF;
		}
		else if (StrContains(game_folder, "zps", false) != -1)
		{
			gamemod = Game_ZPS;
		}
		else if (StrContains(game_folder, "ageofchivalry", false) != -1)
		{
			gamemod = Game_AOC;
		}
		else if (StrContains(game_folder, "gesource", false) != -1)
		{
			gamemod = Game_GES;
		}
		else if (StrContains(game_folder, "pvkii", false) != -1)
		{
			gamemod = Game_PVKII;
		}
		else if (StrContains(game_folder, "cspromod", false) != -1)
		{
			gamemod = Game_CSP;
		}
		else if (StrContains(game_folder, "nucleardawn", false) != -1)
		{
			gamemod = Game_ND;
		}
		else if (StrContains(game_folder, "dinodday", false) != -1)
		{
			gamemod = Game_DDD;
		}
		else if (StrContains(game_folder, "csgo", false) != -1)
		{
			gamemod = Game_CSGO;
		}
		else
		{
			LogToGame("HLX:CE Mod Not In Detected List, Using Defaults (%s, %s)", game_description, game_folder);
			LogToGame("HLX:CE If this is incorrect, please file a bug at hlxcommunity.com");
		}
	}
	if (gamemod > Game_Unknown)
	{
		LogToGame("HLX:CE Mod Detection: %s", modnamelist[view_as<int>(gamemod)]);
		LogToGame("HLX:CE If this is incorrect, please file a bug at hlxcommunity.com");
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (g_bGameCanDoMotd && !IsFakeClient(client))
	{
		QueryClientConVar(client, "cl_disablehtmlmotd", motdQuery);
	}
}


public void motdQuery(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if (result == ConVarQuery_Okay && StringToInt(cvarValue) == 0 || result != ConVarQuery_Okay)
	{
		g_bPlyrCanDoMotd[client] = true;
	}
}


public void OnServerTagChange(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if (GetConVarBool(hlx_server_tag))
	{
		MyAddServerTag(HLXTAG);
	}
	else
	{
		MyRemoveServerTag(HLXTAG);
	}
}

public void OnSVTagsChange(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if (g_bIgnoreNextTagChange)
	{
		// we fired this callback, no need to reapply tags
		return;
	}
	
	// reapply each custom tag
	int cnt = GetArraySize(g_hCustomTags);
	for (int i = 0; i < cnt; i++)
	{
		char tag[SVTAGSIZE];
		GetArrayString(g_hCustomTags, i, tag, sizeof(tag));
		MyAddServerTag(tag);
	}
}


public void OnProtectAddressChange(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if (newVal[0] > 0)
	{
		char log_command[192];
		Format(log_command, sizeof(log_command), "logaddress_add %s", newVal);
		LogToGame("Command: %s", log_command);
		ServerCommand(log_command);
	}
}

public void OnTeamPlayChange(Handle cvar, const char[] oldVal, const char[] newVal)
{
	g_bTeamPlay = GetConVarBool(g_cvarTeamPlay);
}

public Action ProtectLoggingChange(int args)
{
	if (hlx_protect_address != INVALID_HANDLE)
	{
		char protect_address[192];
		GetConVarString(hlx_protect_address, protect_address, sizeof(protect_address));
		if (strcmp(protect_address, "") != 0)
		{
			if (args >= 1)
			{
				char log_action[192];
				GetCmdArg(1, log_action, sizeof(log_action));
				if ((strcmp(log_action, "off") == 0) || (strcmp(log_action, "0") == 0))
				{
					LogToGame("HLstatsX address protection active, logging reenabled!");
					ServerCommand("log 1");
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action ProtectForwardingChange(int args)
{
	if (hlx_protect_address != INVALID_HANDLE)
	{
		char protect_address[192];
		GetConVarString(hlx_protect_address, protect_address, sizeof(protect_address));
		if (strcmp(protect_address, "") != 0)
		{
			if (args == 1)
			{
				char log_action[192];
				GetCmdArg(1, log_action, sizeof(log_action));
				if (strcmp(log_action, protect_address) == 0)
				{
					char log_command[192];
					Format(log_command, sizeof(log_command), "logaddress_add %s", protect_address);
					LogToGame("HLstatsX address protection active, logaddress readded!");
					ServerCommand(log_command);
				}
			}
			else if (args > 1)
			{
				char log_action[192];
				for(int i = 1; i <= args; i++)
				{
					char temp_argument[192];
					GetCmdArg(i, temp_argument, sizeof(temp_argument));
					strcopy(log_action[strlen(log_action)], sizeof(log_action), temp_argument);
				}
				if (strcmp(log_action, protect_address) == 0)
				{
					char log_command[192];
					Format(log_command, sizeof(log_command), "logaddress_add %s", protect_address);
					LogToGame("HLstatsX address protection active, logaddress readded!");
					ServerCommand(log_command);
				}			
			}
		}
	}
	return Plugin_Continue;
}



public Action ProtectForwardingDelallChange(int args)
{
	if (hlx_protect_address != INVALID_HANDLE)
	{
		char protect_address[192];
		GetConVarString(hlx_protect_address, protect_address, sizeof(protect_address));
		if (strcmp(protect_address, "") != 0)
		{
			char log_command[192];
			Format(log_command, sizeof(log_command), "logaddress_add %s", protect_address);
			LogToGame("HLstatsX address protection active, logaddress readded!");
			ServerCommand(log_command);
		}
	}
	return Plugin_Continue;
}


public void OnMessagePrefixChange(Handle cvar, const char[] oldVal, const char[] newVal)
{
	strcopy(message_prefix, sizeof(message_prefix), newVal);
}


public Action MessagePrefixClear(int args)
{
	message_prefix = "";
	return Plugin_Continue;
}


void find_player_team_slot(int team_index) 
{
	if (team_index > -1)
	{
		ColorSlotArray[team_index] = -1;
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == team_index)
			{
				ColorSlotArray[team_index] = i;
				break;
			}
		}
	}
}

stock void validate_team_colors() 
{
	for (int i = 0; i < sizeof(ColorSlotArray); i++)
	{
		int color_client = ColorSlotArray[i];
		if (color_client > 0)
		{
			if (IsClientInGame(color_client) && GetClientTeam(color_client) != color_client)
			{
				find_player_team_slot(i);
			}
		}
		else
		{
			if (i == 2 || i == 3 || (i == 4 && gamemod == Game_PVKII))
			{
				find_player_team_slot(i);
			}
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (g_bTrackColors4Chat && client > 0 && IsClientInGame(client))
	{
		int team_index = GetClientTeam(client);
		if (client == ColorSlotArray[team_index])
		{
			ColorSlotArray[team_index] = -1;
		}
	}
	
	g_bPlyrCanDoMotd[client] = false;
}

int color_player(int color_type, int player_index, char client_message[192]) 
{
	int color_player_index = -1;
	if (g_bTrackColors4Chat || (gamemod == Game_DODS) || (gamemod == Game_ZPS) || (gamemod == Game_GES) || (gamemod == Game_CSP))
	{
		char client_name[192];
		GetClientName(player_index, client_name, sizeof(client_name));
		if ((strcmp(client_message, "") != 0) && (strcmp(client_name, "") != 0))
		{
			if (color_type == 1)
			{
				char search_client_name[192];
				Format(search_client_name, sizeof(search_client_name), "%s ", client_name);
				char colored_player_name[192];
				switch (gamemod)
				{
					case Game_DODS, Game_GES, Game_CSP:
						Format(colored_player_name, sizeof(colored_player_name), "\x04%s\x01 ", client_name);
					case Game_HL2MP:
						Format(colored_player_name, sizeof(colored_player_name), "%c%s\x01 ", g_bTeamPlay?3:4, client_name);
					case Game_ZPS:
						Format(colored_player_name, sizeof(colored_player_name), "\x05%s\x01 ", client_name);
					default:
						Format(colored_player_name, sizeof(colored_player_name), "\x03%s\x01 ", client_name);
				}
				if (ReplaceString(client_message, sizeof(client_message), search_client_name, colored_player_name) > 0)
				{
					return player_index;
				}
			}
			else
			{
				char search_client_name[192];
				Format(search_client_name, sizeof(search_client_name), " %s ", client_name);
				char colored_player_name[192];
				switch (gamemod)
				{
					case Game_ZPS:
						Format(colored_player_name, sizeof(colored_player_name), " \x05%s\x01 ", client_name);
					case Game_GES:
						Format(colored_player_name, sizeof(colored_player_name), " \x05%s\x01 ", client_name);
					default:
						Format(colored_player_name, sizeof(colored_player_name), " \x04%s\x01 ", client_name);
				}
				ReplaceString(client_message, sizeof(client_message), search_client_name, colored_player_name);
			}
		}
	}
	else if (gamemod == Game_FF)
	{
		char client_name[192];
		GetClientName(player_index, client_name, sizeof(client_name));
		
		int team = GetClientTeam(player_index);
		if (team > 1 && team < 6)
		{
			char colored_player_name[192];
			Format(colored_player_name, sizeof(colored_player_name), "^%d%s^0", (team-1), client_name);
			if (ReplaceString(client_message, sizeof(client_message), client_name, colored_player_name) > 0)
			{
				return player_index;
			}
		}
	}
	return color_player_index;
}

int color_all_players(char message[192]) 
{
	int color_index = -1;
	if ((g_bTrackColors4Chat || (gamemod == Game_DODS) || (gamemod == Game_ZPS) || (gamemod == Game_FF) || (gamemod == Game_GES) || (gamemod == Game_CSP)) && (PlayerColorArray != INVALID_HANDLE))
	{
		if (strcmp(message, "") != 0)
		{
			ClearArray(PlayerColorArray);

			int lowest_matching_pos = 192;
			int lowest_matching_pos_client = -1;

			for(int i = 1; i <= MaxClients; i++)
			{
				int client = i;
				if (IsClientInGame(client))
				{
					char client_name[32];
					GetClientName(client, client_name, sizeof(client_name));

					if (strcmp(client_name, "") != 0)
					{
						int message_pos = StrContains(message, client_name);
						if (message_pos > -1)
						{
							if (lowest_matching_pos > message_pos)
							{
								lowest_matching_pos = message_pos;
								lowest_matching_pos_client = client;
							}
							int TempPlayerColorArray[1];
							TempPlayerColorArray[0] = client;
							PushArrayArray(PlayerColorArray, TempPlayerColorArray);
						}
					}
				}
			}
			int size = GetArraySize(PlayerColorArray);
			for (int i = 0; i < size; i++)
			{
				int temp_player_array[1];
				GetArrayArray(PlayerColorArray, i, temp_player_array);
				int temp_client = temp_player_array[0];
				if (temp_client == lowest_matching_pos_client)
				{
					int temp_color_index = color_player(1, temp_client, message);
					color_index = temp_color_index;
				}
				else
				{
					color_player(0, temp_client, message);
				}
			}
			ClearArray(PlayerColorArray);
		}
	}
	
	return color_index;
}

int[] color_team_entities(char message[192])
{
	switch(gamemod)
	{
		case Game_CSS, Game_CSGO:
		{
			if (strcmp(message, "") != 0)
			{
				if (ColorSlotArray[2] > -1)
				{
					if (ReplaceString(message, sizeof(message), "TERRORIST ", "\x03TERRORIST\x01 ") > 0)
					{
						return ColorSlotArray[2];
					}
				}
				if (ColorSlotArray[3] > -1)
				{
					if (ReplaceString(message, sizeof(message), "CT ", "\x03CT\x01 ") > 0)
					{
						return ColorSlotArray[3];
					}
				}
			}
		}
		case Game_L4D:
		{
			if (strcmp(message, "") != 0)
			{
				if (ColorSlotArray[2] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Survivors ", "\x03Survivors\x01 ") > 0)
					{
						return ColorSlotArray[2];
					}
				}
				if (ColorSlotArray[3] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Infected ", "\x03Infected\x01 ") > 0)
					{
						return ColorSlotArray[3];
					}
				}
			}
		}
		case Game_TF:
		{
			if (strcmp(message, "") != 0)
			{
				if (ColorSlotArray[2] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Red ", "\x03Red\x01 ") > 0)
					{
						return ColorSlotArray[2];
					}
				}
				if (ColorSlotArray[3] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Blue ", "\x03Blue\x01 ") > 0)
					{
						return ColorSlotArray[3];
					}
				}
			}
		}
		case Game_FF:
		{
			if (strcmp(message, "") != 0)
			{
				if (ReplaceString(message, sizeof(message), "Red Team", "^2Red Team^0") > 0)
				{
					return 0;
				}
				if (ReplaceString(message, sizeof(message), "Blue Team", "^1Blue Team^0") > 0)
				{
					return 0;
				}
				if (ReplaceString(message, sizeof(message), "Yellow Team", "^3Yellow Team^0") > 0)
				{
					return 0;
				}
				if (ReplaceString(message, sizeof(message), "Green Team", "^4Green Team^0") > 0)
				{
					return 0;
				}
			}
		}
		case Game_AOC:
		{
			if (strcmp(message, "") != 0)
			{
				if (ColorSlotArray[2] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Agathia Knights ", "\x03Agathia Knights\x01 ") > 0)
					{
						return ColorSlotArray[2];
					}
				}
				if (ColorSlotArray[3] > -1)
				{
					if (ReplaceString(message, sizeof(message), "The Mason Order ", "\x03The Mason Order\x01 ") > 0)
					{
						return ColorSlotArray[3];
					}
				}
			}
		}
		case Game_FOF:
		{
			if (strcmp(message, "") != 0)
			{
				if (ColorSlotArray[2] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Desperados ", "\x03Desperados\x01 ") > 0
						|| ReplaceString(message, sizeof(message), "Desparados ", "\x03Desperados\x01 ") > 0)
					{
						return ColorSlotArray[2];
					}
				}
				if (ColorSlotArray[3] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Vigilantes ", "\x03Vigilantes\x01 ") > 0)
					{
						return ColorSlotArray[3];
					}
				}
			}
		}
		case Game_HL2MP:
		{
			if (g_bTeamPlay && strcmp(message, "") != 0)
			{
				if (ColorSlotArray[2] > -1)
				{
					if (ReplaceString(message, sizeof(message), "The Combine ", "\x03The Combine\x01 ") > 0)
					{
						return ColorSlotArray[2];
					}
				}
				if (ColorSlotArray[3] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Rebel Forces ", "\x03Rebel Forces\x01 ") > 0)
					{
						return ColorSlotArray[3];
					}
				}
			}
		}
		case Game_PVKII:
		{
			if (strcmp(message, "") != 0)
			{
				if (ColorSlotArray[2] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Pirates ", "\x03Pirates\x01 ") > 0)
					{
						return ColorSlotArray[2];
					}
				}
				if (ColorSlotArray[3] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Vikings ", "\x03Vikings\x01 ") > 0)
					{
						return ColorSlotArray[3];
					}
				}
				if (ColorSlotArray[4] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Knights ", "\x03Knights\x01 ") > 0)
					{
						return ColorSlotArray[4];
					}
				}
			}
		}
		case Game_ND:
		{
			if (strcmp(message, "") != 0)
			{
				if (ColorSlotArray[2] > -1)
				{
					if (ReplaceString(message, sizeof(message), "EMPIRE ", "\x03Empire\x01 ") > 0)
					{
						return ColorSlotArray[2];
					}
				}
				if (ColorSlotArray[3] > -1)
				{
					if (ReplaceString(message, sizeof(message), "CONSORTIUM ", "\x03Consortium\x01 ") > 0)
					{
						return ColorSlotArray[3];
					}
				}
			}
		}
		case Game_DDD:
		{
			if (g_bTeamPlay && strcmp(message, "") != 0)
			{
				if (ColorSlotArray[2] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Allies ", "\x03Allies\x01 ") > 0)
					{
						return ColorSlotArray[2];
					}
				}
				if (ColorSlotArray[3] > -1)
				{
					if (ReplaceString(message, sizeof(message), "Axis ", "\x03Axis\x01 ") > 0)
					{
						return ColorSlotArray[3];
					}
				}
			}
		}
	}

	return -1;
}

void display_menu(int player_index, int timex, char full_message[1024], int need_handler = 0)
{
	ReplaceString(full_message, sizeof(full_message), "\\n", "\10");
	if (need_handler == 0)
	{
		InternalShowMenu(player_index, full_message, timex);
	}
	else
	{
		InternalShowMenu(player_index, full_message, timex, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9), InternalMenuHandler);
	}
}

public int InternalMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	int client = param1;
	if (IsClientInGame(client))
	{
		if (action == MenuAction_Select)
		{
			char player_event[192];
			IntToString(param2, player_event, sizeof(player_event));
			LogPlayerEvent(client, "selected", player_event);
		}
		else if (action == MenuAction_Cancel)
		{
			LogPlayerEvent(client, "selected", "cancel");
		}
	}
	return 0;
}

public Action hlx_sm_psay(int args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_psay <userid><colored><message> - sends private message");
		return Plugin_Handled;
	}

	char client_list[192];
	GetCmdArg(1, client_list, sizeof(client_list));
	BuildClientList(client_list);

	char colored_param[32];
	GetCmdArg(2, colored_param, sizeof(colored_param));
	int is_colored = 0;
	int ignore_param = 0;
	
	if (strcmp(colored_param, "1") == 0)
	{
		is_colored = 1;
		ignore_param = 1;
	}
	else if (strcmp(colored_param, "2") == 0)
	{
		is_colored = 2;
		ignore_param = 1;
	}
	else if (strcmp(colored_param, "0") == 0)
	{
		ignore_param = 1;
	}

	char client_message[192];
	GetCmdArg((ignore_param + 2), client_message, sizeof(client_message));
	
	if (IsStackEmpty(message_recipients))
	{
		return Plugin_Handled;
	}
	
	int color_index = -1;
	char display_message[192];

	switch (gamemod)
	{
		case Game_CSS, Game_DODS, Game_L4D, Game_TF, Game_HL2MP, Game_ZPS, Game_AOC, Game_FOF, Game_GES, Game_PVKII, Game_CSP, Game_ND, Game_DDD, Game_CSGO:
		{
			if (is_colored > 0)
			{
				if (is_colored == 1)
				{
					int player_color_index = color_all_players(client_message);
					if (player_color_index > -1)
					{
						color_index = player_color_index;
					}
					else
					{
						if (g_bTrackColors4Chat)
						{
							validate_team_colors();
						}
						color_index = color_team_entities(client_message);
					}
				}
			}
			if (strcmp(message_prefix, "") == 0)
			{
				Format(display_message, sizeof(display_message), "\x01\x0B\x01%s", client_message);
			}
			else
			{
				Format(display_message, sizeof(display_message), "\x01\x0B%c%s\x01 %s", ((gamemod == Game_ZPS || gamemod == Game_GES)?5:4), message_prefix, client_message);
			}
			
			bool setupColorForRecipients = false;
			if (color_index == -1)
			{
				setupColorForRecipients = true;
			}
			
			if (g_bTrackColors4Chat && is_colored != 2)
			{
				while (IsStackEmpty(message_recipients) == false)
				{
					int recipient_client = -1;
					PopStackCell(message_recipients, recipient_client);

					int player_index = GetClientOfUserId(recipient_client);
					if (player_index > 0 && !IsFakeClient(player_index) && IsClientInGame(player_index))
					{
						if (setupColorForRecipients == true)
						{
							color_index = player_index;
						}
						Handle hBf;
						hBf = StartMessageOne("SayText2", player_index, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
						
						if (hBf != INVALID_HANDLE)
						{
							if(GetUserMessageType() == UM_Protobuf) 
							{
								PbSetInt(hBf, "ent_idx", 0);
								PbSetBool(hBf, "chat", false);
								PbSetString(hBf, "msg_name", display_message);
								PbAddString(hBf, "params", "");
								PbAddString(hBf, "params", "");
								PbAddString(hBf, "params", "");
								PbAddString(hBf, "params", "");
							}
							else
							{
								BfWriteByte(hBf, color_index); 
								BfWriteByte(hBf, 0);
								
								BfWriteString(hBf, display_message);
							}
							
							EndMessage();
						}
					}
				}
			}
			else
			{
				PrintToChatRecipients(display_message);
			}
		}
		case Game_FF:
		{
			// thanks to hlstriker for help with this
			
			char client_message_backup[192];
			strcopy(client_message_backup, sizeof(client_message_backup), client_message);
		
			if (is_colored == 1)
			{
				color_index = color_all_players(client_message);
				if (color_index ==  -1)
				{
					color_team_entities(client_message);
				}
			}
			
			if (strcmp(message_prefix, "") == 0)
			{
				Format(display_message, sizeof(display_message), "Console: %s%s\n", ((is_colored == 2)?"^4":""), client_message);
			}
			else
			{
				Format(display_message, sizeof(display_message), "Console: ^4%s:%s %s\n", message_prefix, ((is_colored == 2)?"":"^"), client_message);
			}
			
			PrintToChatRecipientsFF(display_message);
		}
		default:
		{
			if (strcmp(message_prefix, "") != 0)
			{
				Format(display_message, sizeof(display_message), "%s %s", message_prefix, client_message);
				PrintToChatRecipients(display_message);
				return Plugin_Handled;
			}
			PrintToChatRecipients(client_message);
		}
	}
	return Plugin_Handled;
}

public Action hlx_sm_psay2(int args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_psay2 <userid><colored><message> - sends green colored private message");
		return Plugin_Handled;
	}
	
	char client_list[192];
	GetCmdArg(1, client_list, sizeof(client_list));
	BuildClientList(client_list);

	char colored_param[32];
	GetCmdArg(2, colored_param, sizeof(colored_param));
	
	int ignore_param = 0;
	if (strcmp(colored_param, "2") == 0 || strcmp(colored_param, "1") == 0 || strcmp(colored_param, "0") == 0)
	{
		ignore_param = 1;
	}

	char client_message[192];
	GetCmdArg((ignore_param + 2), client_message, sizeof(client_message));

	if (IsStackEmpty(message_recipients)) {
		return Plugin_Handled;
	}
	
	// Strip color control codes
	char buffer_message[192];
	int j = 0;
	for (int i = 0; i < sizeof(client_message); i++)
	{
		int c = client_message[i];
		if (c < 5 && c > 0)
		{
			continue;
		}
		buffer_message[j] = client_message[i];
		if (c == 0)
		{
			break;
		}
		j++;
	}
	
	switch(gamemod)
	{
		case Game_INSMOD:
		{
			int prefix = 0;
			if (strcmp(message_prefix, "") != 0)
			{
				prefix = 1;
				Format(client_message, sizeof(client_message), "%s: %s", message_prefix, buffer_message);
			}
			
			while (IsStackEmpty(message_recipients) == false)
			{
				int recipient_client = -1;
				PopStackCell(message_recipients, recipient_client);

				int player_index = GetClientOfUserId(recipient_client);
				if (player_index > 0 && !IsFakeClient(player_index) && IsClientInGame(player_index))
				{
					// thanks to Fyren and IceMatrix for help with this
					Handle hBf;
					hBf = StartMessageOne("SayText", player_index, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
					if (hBf != INVALID_HANDLE)
					{
						if(GetUserMessageType() == UM_Protobuf) 
						{
							PbSetInt(hBf, "ent_idx", player_index);
							PbSetBool(hBf, "chat", true);
							
							if (prefix == 0)
							{
								PbSetString(hBf, "text", buffer_message);
							}
							else
							{
								PbSetString(hBf, "text", client_message);
							}
						}
						else
						{
							BfWriteByte(hBf, 1);
							BfWriteBool(hBf, true);
							BfWriteByte(hBf, player_index); 
							
							if (prefix == 0)
							{
								BfWriteString(hBf, buffer_message);
							}
							else
							{
								BfWriteString(hBf, client_message);
							}
						}
						
						EndMessage();
					}
				}
			}
		}
		case Game_FF:
		{
			if (strcmp(message_prefix, "") == 0)
			{
				Format(client_message, sizeof(client_message), "Console: \x02^4%s\n", buffer_message);
			}
			else
			{
				Format(client_message, sizeof(client_message), "Console: \x02^4%s: %s\n", message_prefix, buffer_message);
			}
			
			PrintToChatRecipientsFF(client_message);
		}
		case Game_ZPS, Game_GES:
		{
			if (strcmp(message_prefix, "") == 0)
			{
				Format(client_message, sizeof(client_message), "\x05%s", buffer_message);
			}
			else
			{
				Format(client_message, sizeof(client_message), "\x05%s %s", message_prefix, buffer_message);
			}
			PrintToChatRecipients(client_message);
		}
		default:
		{
			if (strcmp(message_prefix, "") == 0)
			{
				Format(client_message, sizeof(client_message), "\x04%s", buffer_message);
			}
			else
			{
				Format(client_message, sizeof(client_message), "\x04%s %s", message_prefix, buffer_message);
			}
			PrintToChatRecipients(client_message);
		}
	}
	return Plugin_Handled;
}

public Action hlx_sm_csay(int args)
{
	if (args < 1)
	{
		PrintToServer("Usage: hlx_sm_csay <message> - display center message");
		return Plugin_Handled;
	}

	char display_message[192];
	GetCmdArg(1, display_message, sizeof(display_message));

	if (strcmp(display_message, "") != 0)
	{
		if (gamemod == Game_L4D)
		{
			PrintToChatAll("\x03%s", display_message);
		}
		else
		{
			PrintCenterTextAll("%s", display_message);
		}
	}
		
	return Plugin_Handled;
}

public Action hlx_sm_msay(int args)
{
	if (args < 3)
	{
		PrintToServer("Usage: hlx_sm_msay <time><userid><message> - sends hud message");
		return Plugin_Handled;
	}

	if (gamemod == Game_HL2MP)
	{
		return Plugin_Handled;
	}
	
	char display_time[16];
	GetCmdArg(1, display_time, sizeof(display_time));
	
	char client_id[32];
	GetCmdArg(2, client_id, sizeof(client_id));
	
	char handler_param[32];
	GetCmdArg(3, handler_param, sizeof(handler_param));
	
	int ignore_param = 0;
	int need_handler = 0;
	if (handler_param[1] == 0 && (handler_param[0] == '1' || handler_param[0] == '0'))
	{
		need_handler = 1;
		ignore_param = 1;
	}

	char client_message[1024];
	GetCmdArg((ignore_param + 3), client_message, 1024);

	int time = StringToInt(display_time);
	if (time <= 0)
	{
		time = 10;
	}

	int client = StringToInt(client_id);
	if (client > 0)
	{
		int player_index = GetClientOfUserId(client);
		if (player_index > 0 && !IsFakeClient(player_index) && IsClientInGame(player_index) && strcmp(client_message, "") != 0)
		{
			display_menu(player_index, time, client_message, need_handler);
		}	
	}
	
	return Plugin_Handled;
}

public Action hlx_sm_tsay(int args)
{
	if (args < 3)
	{
		PrintToServer("Usage: hlx_sm_tsay <time><userid><message> - sends hud message");
		return Plugin_Handled;
	}

	char display_time[16];
	GetCmdArg(1, display_time, sizeof(display_time));
	
	char client_id[32];
	GetCmdArg(2, client_id, sizeof(client_id));

	char client_message[192];
	GetCmdArg(3, client_message, sizeof(client_message));
	
	int client = StringToInt(client_id);
	if ((client > 0) && (strcmp(client_message, "") != 0))
	{
		int player_index = GetClientOfUserId(client);
		if (player_index > 0 && !IsFakeClient(player_index) && IsClientInGame(player_index))
		{
			Handle values = CreateKeyValues("msg");
			KvSetString(values, "title", client_message);
			KvSetNum(values, "level", 1); 
			KvSetString(values, "time", display_time); 
			CreateDialog(player_index, values, DialogType_Msg);
			CloseHandle(values);
		}	
	}
		
	return Plugin_Handled;
}

public Action hlx_sm_hint(int args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_hint <userid><message> - send hint message");
		return Plugin_Handled;
	}

	char client_list[192];
	GetCmdArg(1, client_list, sizeof(client_list));
	BuildClientList(client_list);

	char client_message[192];
	GetCmdArg(2, client_message, sizeof(client_message));

	if (IsStackEmpty(message_recipients) == false && strcmp(client_message, "") != 0)
	{
		while (IsStackEmpty(message_recipients) == false)
		{
			int recipient_client = -1;
			PopStackCell(message_recipients, recipient_client);
		
			int player_index = GetClientOfUserId(recipient_client);
			if (player_index > 0 && !IsFakeClient(player_index) && IsClientInGame(player_index) && IsClientInGame(player_index))
			{
				PrintHintText(player_index, "%s", client_message);
			}
		}
	}
	return Plugin_Handled;
}

public Action hlx_sm_browse(int args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_browse <userid><url> - open client ingame browser");
		return Plugin_Handled;
	}

	char client_list[192];
	GetCmdArg(1, client_list, sizeof(client_list));
	BuildClientList(client_list);

	char client_url[192];
	GetCmdArg(2, client_url, sizeof(client_url));

	if (IsStackEmpty(message_recipients) == false && strcmp(client_url, "") != 0)
	{
		while (IsStackEmpty(message_recipients) == false)
		{
			int recipient_client = -1;
			PopStackCell(message_recipients, recipient_client);

			int player_index = GetClientOfUserId(recipient_client);
			if (player_index > 0 && !IsFakeClient(player_index) && IsClientInGame(player_index))
			{
				if (g_bGameCanDoMotd)
				{
					if (g_bPlyrCanDoMotd[player_index])
					{
						if (GetUserMessageType() == UM_Protobuf)
						{
							char typeStr[5];
							IntToString(MOTDPANEL_TYPE_URL, typeStr, 4);
							
							Handle pb = StartMessageOne("VGUIMenu", player_index);
							
							PbSetString(pb, "name", "info");
							PbSetBool(pb, "show", true);

							Handle modkey = PbAddMessage(pb, "subkeys");
							
							PbSetString(modkey, "name", "type");
							PbSetString(modkey, "str", typeStr); 

							modkey = PbAddMessage(pb, "subkeys");
							PbSetString(modkey, "name", "title");
							PbSetString(modkey, "str", "HLstatsX:CE");

							modkey = PbAddMessage(pb, "subkeys");
							PbSetString(modkey, "name", "msg");
							PbSetString(modkey, "str", client_url);

							EndMessage();
						}
						else
						{
							ShowMOTDPanel(player_index, "HLstatsX:CE", client_url, MOTDPANEL_TYPE_URL);
						}
						
						ShowMOTDPanel(player_index, "HLstatsX:CE", client_url, MOTDPANEL_TYPE_URL);
					}
					else
					{
						PrintToChat(player_index, "HTML MOTD needs to be enabled in your game options to use this command");
					}
				}
				else
				{
					PrintToChat(player_index, "This game does not support the HTML MOTD window required for this command");
				}
			}
		}
	}
			
	return Plugin_Handled;
}

public Action hlx_sm_swap(int args)
{
	if (args < 1)
	{
		PrintToServer("Usage: hlx_sm_swap <userid> - swaps players to the opposite team (css only)");
		return Plugin_Handled;
	}

	if (gamemod != Game_CSS || gamemod != Game_CSGO)
	{
		PrintToServer("hlx_sm_swap is not supported by this game.");
		return Plugin_Handled;
	}
	
	char client_id[32];
	GetCmdArg(1, client_id, sizeof(client_id));

	int client = StringToInt(client_id);
	if (client > 0)
	{
		int player_index = GetClientOfUserId(client);
		if (player_index > 0 && IsClientInGame(player_index))
		{
			swap_player(player_index);
		}
	}
	return Plugin_Handled;
}

public Action hlx_sm_redirect(int args)
{
	if (args < 3)
	{
		PrintToServer("Usage: hlx_sm_redirect <time><userid><address><reason> - asks player to be redirected to specified gameserver");
		return Plugin_Handled;
	}

	char display_time[16];
	GetCmdArg(1, display_time, sizeof(display_time));

	char client_list[192];
	GetCmdArg(2, client_list, sizeof(client_list));
	BuildClientList(client_list);
	
	char server_address[192];
	GetCmdArg(3, server_address, sizeof(server_address));

	char redirect_reason[192];
	GetCmdArg(4, redirect_reason, sizeof(redirect_reason));

	if (IsStackEmpty(message_recipients) == false && strcmp(server_address, "") != 0)
	{
		while (IsStackEmpty(message_recipients) == false)
		{
			int recipient_client = -1;
			PopStackCell(message_recipients, recipient_client);

			int player_index = GetClientOfUserId(recipient_client);
			if (player_index > 0 && !IsFakeClient(player_index) && IsClientInGame(player_index))
			{
				Handle top_values = CreateKeyValues("msg");
				KvSetString(top_values, "title", redirect_reason);
				KvSetNum(top_values, "level", 1); 
				KvSetString(top_values, "time", display_time); 
				CreateDialog(player_index, top_values, DialogType_Msg);
				CloseHandle(top_values);
		
				float display_time_float;
				display_time_float = StringToFloat(display_time);
				DisplayAskConnectBox(player_index, display_time_float, server_address);
			}
		}
	}
		
	return Plugin_Handled;
}


public Action hlx_sm_player_action(int args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_player_action <clientid><action> - trigger player action to be handled from HLstatsX");
		return Plugin_Handled;
	}

	char client_id[32];
	GetCmdArg(1, client_id, sizeof(client_id));

	char player_action[64];
	GetCmdArg(2, player_action, sizeof(player_action));

	int client = StringToInt(client_id);

	LogPlayerEvent(client, "triggered", player_action);

	return Plugin_Handled;
}


public Action hlx_sm_team_action(int args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_team_action <team_name><action> - trigger team action to be handled from HLstatsX");
		return Plugin_Handled;
	}

	char team_name[64];
	GetCmdArg(1, team_name, sizeof(team_name));

	char team_action[64];
	GetCmdArg(2, team_action, sizeof(team_action));

	LogToGame("Team \"%s\" triggered \"%s\"", team_name, team_action); 

	return Plugin_Handled;
}

public Action hlx_sm_world_action(int args)
{
	if (args < 1)
	{
		PrintToServer("Usage: hlx_sm_world_action <action> - trigger world action to be handled from HLstatsX");
		return Plugin_Handled;
	}

	char world_action[64];
	GetCmdArg(1, world_action, sizeof(world_action));

	LogToGame("World triggered \"%s\"", world_action); 

	return Plugin_Handled;
}

int is_command_blocked(char[] command)
{
	int command_blocked = 0;
	int command_index = 0;
	while ((command_blocked == 0) && (command_index < sizeof(blocked_commands)))
	{
		if (strcmp(command, blocked_commands[command_index]) == 0)
		{
			command_blocked++;
		}
		command_index++;
	}
	if (command_blocked > 0)
	{
		return 1;
	}
	return 0;
}

public Action hlx_block_commands(int client, const char[] command, int args)
{
	if (client)
	{
		if (client == 0)
		{
			return Plugin_Continue;
		}
		int block_chat_commands = GetConVarInt(hlx_block_chat_commands);

		char user_command[192];
		GetCmdArgString(user_command, sizeof(user_command));

		char origin_command[192];
		int start_index = 0;
		int command_length = strlen(user_command);
		if (command_length > 0)
		{
			if (user_command[0] == 34)
			{
				start_index = 1;
				if (user_command[command_length - 1] == 34)
				{
					user_command[command_length - 1] = 0;
				}
			}
			strcopy(origin_command, sizeof(origin_command), user_command[start_index]);
			
			if (user_command[start_index] == 47)
			{
				start_index++;
			}
		}

		char command_type[32] = "say";

		if (gamemod == Game_INSMOD)
		{
			char say_type[1];
			strcopy(say_type, 2, user_command[start_index]);
			if (strcmp(say_type, "1") == 0)
			{
				command_type = "say";
			}
			else if (strcmp(say_type, "2") == 0)
			{
				command_type = "say_team";
			}
			start_index += 4;
		}

		if (command_length > 0)
		{
			if (block_chat_commands > 0)
			{
				int command_blocked = is_command_blocked(user_command[start_index]);
				if (command_blocked > 0)
				{
					if (IsClientInGame(client))
					{
						if ((strcmp("hlx_menu", user_command[start_index]) == 0) ||
							(strcmp("hlx", user_command[start_index]) == 0) ||
							(strcmp("hlstatsx", user_command[start_index]) == 0))
						{
							DisplayMenu(HLstatsXMenuMain, client, MENU_TIME_FOREVER);
						}

						if (gamemod == Game_INSMOD)
						{
							LogPlayerEvent(client, command_type, user_command[start_index]);
						}
						else
						{
							LogPlayerEvent(client, command_type, origin_command);
						}
					}
					return Plugin_Stop;
				}
			}
			else
			{
				if (IsClientInGame(client) &&
					(strcmp("hlx_menu", user_command[start_index]) == 0
					|| strcmp("hlx", user_command[start_index]) == 0
					|| strcmp("hlstatsx", user_command[start_index]) == 0))
				{
					DisplayMenu(HLstatsXMenuMain, client, MENU_TIME_FOREVER);
				}
				
				return Plugin_Continue;
			}
		}
		
	}
	return Plugin_Continue;
}

public Action HLstatsX_Event_PlyTeamChange(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0)
	{
		for (int i = 0; (i < sizeof(ColorSlotArray)); i++)
		{
			int color_client = ColorSlotArray[i];
			if (color_client > -1)
			{
				if (color_client == client)
				{
					ColorSlotArray[i] = -1;
				}
			}
		}
	}
	return Plugin_Continue;
}

int swap_player(int player_index)
{
	if (IsClientInGame(player_index))
	{
		switch (GetClientTeam(player_index))
		{
			case CS_TEAM_CT:
			{
				if (IsPlayerAlive(player_index))
				{
					CS_SwitchTeam(player_index, CS_TEAM_T);
					CS_RespawnPlayer(player_index);
					int new_model = GetRandomInt(0, 3);
					SetEntityModel(player_index, ts_models[new_model]);
				}
				else
				{
					CS_SwitchTeam(player_index, CS_TEAM_T);
				}
			}
			case CS_TEAM_T:
			{
				if (IsPlayerAlive(player_index))
				{
					CS_SwitchTeam(player_index, CS_TEAM_CT);
					CS_RespawnPlayer(player_index);
					int new_model = GetRandomInt(0, 3);
					SetEntityModel(player_index, ct_models[new_model]);
					int weapon_entity = GetPlayerWeaponSlot(player_index, 4);
					if (weapon_entity > 0)
					{
						char class_name[32];
						GetEdictClassname(weapon_entity, class_name, sizeof(class_name));
						if (strcmp(class_name, "weapon_c4") == 0)
						{
							RemovePlayerItem(player_index, weapon_entity);
						}
					}
				}
				else
				{
					CS_SwitchTeam(player_index, CS_TEAM_CT);
				}
			}
		}
	}
	return 0;
}

public void CreateHLstatsXMenuMain(Menu MenuHandle)
{
	MenuHandle = CreateMenu(HLstatsXMainCommandHandler, MenuAction_Select|MenuAction_Cancel);

	if (!g_bGameCanDoMotd)
	{
		SetMenuTitle(MenuHandle, "HLstatsX - Main Menu");
		AddMenuItem(MenuHandle, "", "Display Rank");
		AddMenuItem(MenuHandle, "", "Next Players");
		AddMenuItem(MenuHandle, "", "Top10 Players");
		AddMenuItem(MenuHandle, "", "Auto Ranking");
		AddMenuItem(MenuHandle, "", "Toggle Point Msgs");
		AddMenuItem(MenuHandle, "", "Toggle Ranking Display");
	}
	else
	{
		SetMenuTitle(MenuHandle, "HLstatsX - Main Menu");
		AddMenuItem(MenuHandle, "", "Display Rank");
		AddMenuItem(MenuHandle, "", "Next Players");
		AddMenuItem(MenuHandle, "", "Top10 Players");
		AddMenuItem(MenuHandle, "", "Clans Ranking");
		AddMenuItem(MenuHandle, "", "Server Status");
		AddMenuItem(MenuHandle, "", "Statsme");
		AddMenuItem(MenuHandle, "", "Auto Ranking");
		AddMenuItem(MenuHandle, "", "Toggle Point Msgs");
		AddMenuItem(MenuHandle, "", "Weapon Usage");
		AddMenuItem(MenuHandle, "", "Weapons Accuracy");
		AddMenuItem(MenuHandle, "", "Weapons Targets");
		AddMenuItem(MenuHandle, "", "Player Kills");
		AddMenuItem(MenuHandle, "", "Toggle Ranking Display");
		AddMenuItem(MenuHandle, "", "Ban and Cheater List");
		AddMenuItem(MenuHandle, "", "Display Help");
	}

	SetMenuPagination(MenuHandle, 8);
}

public void CreateHLstatsXMenuAuto(Menu MenuHandle)
{
	MenuHandle = CreateMenu(HLstatsXAutoCommandHandler, MenuAction_Select|MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "HLstatsX - Auto-Ranking");
	AddMenuItem(MenuHandle, "", "Enable on round-start");
	AddMenuItem(MenuHandle, "", "Enable on round-end");
	AddMenuItem(MenuHandle, "", "Enable on player death");
	AddMenuItem(MenuHandle, "", "Disable");

	SetMenuPagination(MenuHandle, 8);
}

public void CreateHLstatsXMenuEvents(Menu MenuHandle)
{
	MenuHandle = CreateMenu(HLstatsXEventsCommandHandler, MenuAction_Select|MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "HLstatsX - Console Events");
	AddMenuItem(MenuHandle, "", "Enable Events");
	AddMenuItem(MenuHandle, "", "Disable Events");
	AddMenuItem(MenuHandle, "", "Enable Global Chat");
	AddMenuItem(MenuHandle, "", "Disable Global Chat");

	SetMenuPagination(MenuHandle, 8);
}

void make_player_command(int client, const char[] player_command) 
{
	LogPlayerEvent(client, "say", player_command);
}

public int HLstatsXMainCommandHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (IsClientInGame(param1))
		{
			if (!g_bGameCanDoMotd)
			{
				switch (param2)
				{
					case 0 : 
						make_player_command(param1, "/rank");
					case 1 : 
						make_player_command(param1, "/next");
					case 2 : 
						make_player_command(param1, "/top10");
					case 3 : 
						DisplayMenu(HLstatsXMenuAuto, param1, MENU_TIME_FOREVER);
					case 4 : 
						DisplayMenu(HLstatsXMenuEvents, param1, MENU_TIME_FOREVER);
					case 5 : 
						make_player_command(param1, "/hlx_hideranking");
				}
			}
			else
			{
				switch (param2)
				{
					case 0 : 
						make_player_command(param1, "/rank");
					case 1 : 
						make_player_command(param1, "/next");
					case 2 : 
						make_player_command(param1, "/top10");
					case 3 : 
						make_player_command(param1, "/clans");
					case 4 : 
						make_player_command(param1, "/status");
					case 5 : 
						make_player_command(param1, "/statsme");
					case 6 : 
						DisplayMenu(HLstatsXMenuAuto, param1, MENU_TIME_FOREVER);
					case 7 : 
						DisplayMenu(HLstatsXMenuEvents, param1, MENU_TIME_FOREVER);
					case 8 : 
						make_player_command(param1, "/weapons");
					case 9 : 
						make_player_command(param1, "/accuracy");
					case 10 : 
						make_player_command(param1, "/targets");
					case 11 : 
						make_player_command(param1, "/kills");
					case 12 : 
						make_player_command(param1, "/hlx_hideranking");
					case 13 : 
						make_player_command(param1, "/bans");
					case 14 : 
						make_player_command(param1, "/help");
				}
			}
		}
	}
	return 0;
}

public int HLstatsXAutoCommandHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (IsClientInGame(param1))
		{
			switch (param2)
			{
				case 0 : 
					make_player_command(param1, "/hlx_auto start rank");
				case 1 : 
					make_player_command(param1, "/hlx_auto end rank");
				case 2 : 
					make_player_command(param1, "/hlx_auto kill rank");
				case 3 : 
					make_player_command(param1, "/hlx_auto clear");
			}
		}
	}
	return 0;
}

public int HLstatsXEventsCommandHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (IsClientInGame(param1))
		{
			switch (param2)
			{
				case 0 : 
					make_player_command(param1, "/hlx_display 1");
				case 1 : 
					make_player_command(param1, "/hlx_display 0");
				case 2 : 
					make_player_command(param1, "/hlx_chat 1");
				case 3 : 
					make_player_command(param1, "/hlx_chat 0");
			}
		}
	}
	return 0;
}

stock void BuildClientList(const char[] client_list)
{
	if (StrContains(client_list, ",") > -1)
	{
		char[][] MessageRecipients= new char[MaxClients][8];
		int recipient_count = ExplodeString(client_list, ",", MessageRecipients, MaxClients, 8);
		for (int i = 0; (i < recipient_count); i++)
		{
			PushStackCell(message_recipients, StringToInt(MessageRecipients[i]));
		}
	}
	else
	{
		PushStackCell(message_recipients, StringToInt(client_list));
	}
}

stock void PrintToChatRecipients(const char[] message)
{
	while (IsStackEmpty(message_recipients) == false)
	{
		int recipient_client = -1;
		PopStackCell(message_recipients, recipient_client);

		int client = GetClientOfUserId(recipient_client);
		if (client > 0 && !IsFakeClient(client) && IsClientInGame(client))
		{
			PrintToChat(client, "%s", message);
		}
	}
}

stock void PrintToChatRecipientsFF(const char[] message)
{
	while (IsStackEmpty(message_recipients) == false)
	{
		int recipient_client = -1;
		PopStackCell(message_recipients, recipient_client);

		int client = GetClientOfUserId(recipient_client);
		if (client > 0 && !IsFakeClient(client) && IsClientInGame(client))
		{	
			Handle hBf;
			hBf = StartMessageOne("SayText", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
			if (hBf != INVALID_HANDLE)
			{
				if(GetUserMessageType() == UM_Protobuf) 
				{
					PbSetInt(hBf, "ent_idx", 0);
					PbSetBool(hBf, "chat", true);
					PbSetString(hBf, "text", message);
				}
				else
				{
					BfWriteByte(hBf, 0); // send as console
					BfWriteString(hBf, message);
					BfWriteByte(hBf, 1); // 1 to enable color parsing, 0 to not
				}
				EndMessage();
			}
		}
	}
}