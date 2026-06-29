public PlVers:__version =
{
	version = 5,
	filevers = "1.4.4",
	date = "09/18/2013",
	time = "21:47:57"
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
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_cstrike =
{
	name = "cstrike",
	file = "games/game.cstrike.ext",
	autoload = 0,
	required = 1,
};
public Extension:__ext_cprefs =
{
	name = "Client Preferences",
	file = "clientprefs.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_topmenus =
{
	name = "TopMenus",
	file = "topmenus.ext",
	autoload = 1,
	required = 1,
};
public SharedPlugin:__pl_adminmenu =
{
	name = "adminmenu",
	file = "adminmenu.smx",
	required = 1,
};
public Extension:__ext_regex =
{
	name = "Regex Extension",
	file = "regex.ext",
	autoload = 1,
	required = 1,
};
new bool:CSkipList[66];
new Handle:CTrie;
new CTeamColors[1][3] =
{
	{
		13421772, 5077314, 16728128
	}
};
public Extension:__ext_curl =
{
	name = "curl",
	file = "curl.ext",
	autoload = 1,
	required = 0,
};
public Extension:__ext_smsock =
{
	name = "Socket",
	file = "socket.ext",
	autoload = 1,
	required = 0,
};
public Extension:__ext_SteamTools =
{
	name = "SteamTools",
	file = "steamtools.ext",
	autoload = 1,
	required = 0,
};
new Handle:URLcurl;
new Handle:SURLcurl;
new Handle:mmws_ads_Advertisements;
new Handle:mmws_ads_Enabled;
new Handle:mmws_ads_Interval;
new Handle:mmws_ads_prefix;
new String:ads_prefix[128];
new bool:astop;
new bool:astop_team;
new bool:astop_all;
new bool:afstart;
new bool:afknife;
new bool:afknifego;
new bool:knifeenable;
new bool:knifeselect;
new bool:knife;
new bool:g_bPlyrCanDoMotd[66];
new TimeAFK[66];
new Float:g_Position[66][3];
new bool:steamstatus[66];
new t_cap;
new ct_cap;
new menuopen;
new players_ready;
new bool:cwstatus;
new Handle:statushostname;
new bool:half_t_readymenu;
new bool:half_ct_readymenu;
new String:hoststats[64];
new String:databasestats[64];
new String:user[64];
new String:pass[64];
new String:port[64];
new String:lic[256];
new half_t_ready;
new half_ct_ready;
new half_t_unready;
new half_ct_unready;
new admin;
new SubPlayer;
new SubSpectator;
new bool:SubStatus;
new bool:SubStatusWait;
new g_player_list[66];
new bool:g_cancel_list[66];
new String:user_damage[66][8192];
new String:hostnameupdate[128];
new String:hostnamenew[256];
new Handle:hTopMenu;
new BanTarget[66];
new radio[66];
new g_scores[2][2];
new g_scores_overtime[2][256][2];
new g_overtime_count;
new astopdelay;
new knifeselectdelay;
new knifeselectdelay2;
new g_i_ragdolls = -1;
new g_i_account = -1;
new g_i_frags = -1;
new votedelay;
new bool:disconnected_by_user;
new String:g_map[64];
new String:g_log_filename[128];
new Handle:g_log_file;
new String:weapon_list[28][0];
new weapon_stats[66][28][15];
new clutch_stats[66][4];
new String:last_weapon[66][64];
new Handle:mmws_on_lo3;
new Handle:mmws_on_half_time;
new Handle:mmws_on_reset_half;
new Handle:mmws_on_reset_match;
new Handle:mmws_on_end_match;
new Handle:mmws_force_camera;
new Handle:mmws_fade_to_black;
new Handle:mmws_stats_enabled;
new Handle:mmws_rcon_only;
new Handle:mmws_global_chat;
new Handle:mmws_locked;
new Handle:mmws_min_ready;
new Handle:mmws_max_players;
new Handle:mmws_match_config;
new Handle:mmws_live_config;
new Handle:mmws_end_config;
new Handle:mmws_round_money;
new Handle:mmws_night_vision;
new Handle:mmws_bomb_frags;
new Handle:mmws_defuse_frags;
new Handle:mmws_ingame_scores;
new Handle:mmws_max_rounds;
new Handle:mmws_knife_hegrenade;
new Handle:mmws_knife_flashbang;
new Handle:mmws_knife_smokegrenade;
new Handle:mmws_auto_ready;
new Handle:mmws_auto_swap;
new Handle:mmws_auto_swap_delay;
new Handle:mmws_auto_knife;
new Handle:mmws_score_mode;
new Handle:mmws_auto_record;
new Handle:mmws_play_out;
new Handle:mmws_remove_hint_text;
new Handle:mmws_remove_gren_sound;
new Handle:mmws_body_delay;
new Handle:mmws_body_remove;
new Handle:mmws_deathcam_remove;
new Handle:mmws_deathcam_delay;
new Handle:mmws_warmup_respawn;
new Handle:mmws_modifiers;
new Handle:mmws_status;
new Handle:mmws_t;
new Handle:mmws_ct;
new Handle:mmws_mp_startmoney;
new Handle:mmws_Db;
new Handle:mmws_DbStats;
new Handle:KeyValues;
new Handle:KeyValuesStats;
new String:sql_createTables[148] = "CREATE TABLE IF NOT EXISTS `temp` (`pid` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `id` INTEGER NOT NULL, `name` TEXT, `ip` TEXT, `authid` TEXT)";
new String:sql_DeleteTables[20] = "DROP TABLE `temp`";
new String:sql_ClearTables[20] = "DELETE FROM `temp`";
new String:sql_createTablesBans[168] = "CREATE TABLE IF NOT EXISTS `bans` (`bid` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `authid` TEXT, `created` INTEGER, `ends` INTEGER, `length` INTEGER, `reason` TEXT)";
new Handle:BanTimer[66];
new Handle:menuready[66];
new Handle:menuhalftready[66];
new Handle:menuhalfctready[66];
new Handle:AFKTimer;
new Handle:AFKCheckTimer;
new Handle:AFKUpdateTimer;
new bool:g_ready_enabled;
new Handle:mmws_menu;
new bool:g_match;
new bool:g_live;
new bool:g_playing_out;
new bool:g_first_half = 1;
new bool:mmws_money;
new bool:mmws_score;
new bool:mmws_knife = 1;
new bool:mmws_had_knife;
new bool:g_round_end;
new bool:mmws_RestartPlugin;
new String:mmws_t_name[64];
new String:mmws_ct_name[64];
new String:prefix[32];
new String:infotitle[64];
new Handle:h_CvarHostIp;
new Handle:h_CvarPort;
new String:s_ServerIP[32];
new String:s_ServerPort[8];
new Handle:h_Database;
new String:logFile[256];
new Handle:mmws_CvarAStop_Delay;
new Handle:mmws_CvarBanTime;
new Handle:mmws_CvarBanCountExtend;
new Handle:mmws_CvarBanCountExtend2;
new Handle:mmws_CvarBanCountExtend3;
new Handle:mmws_CvarBanCountExtend4;
new Handle:mmws_CvarBanTimeExtend;
new Handle:mmws_CvarBanTimeExtend2;
new Handle:mmws_CvarBanTimeExtend3;
new Handle:mmws_CvarBanTimeExtend4;
new Handle:mmws_CvarBanAllReason;
new Handle:mmws_CvarBanAutoForceStart;
new Handle:mmws_CvarBanAutoFSdelay;
new Handle:mmws_CvarBanAddDelay;
new Handle:mmws_CvarBanVoteStart;
new Handle:mmws_CvarBanVoteMessage;
new Handle:mmws_CvarBanImmunity;
new Handle:mmws_CvarAcceptReplace;
new Handle:mmws_CvarBanServerID;
new Handle:mmws_CvarBanEnable;
new Handle:mmws_CvarLicense;
new Handle:mmws_CvarBanTextOption;
new Handle:mmws_CvarBanText;
new Handle:mmws_CvarSBPrefix;
new Handle:mmws_CvarAutoForceStart;
new Handle:mmws_CvarAutoStartDelay;
new Handle:mmws_CvarAutoForceKnife;
new Handle:mmws_CvarWaitSelectTeam;
new Handle:Timers;
new Handle:TimersKnife;
new Handle:mmws_CvarInfoTitle;
new Handle:mmws_CvarMenuSelectPlayers;
new Handle:mmws_CvarHostnameStatus;
new Handle:mmws_CvarHostnameStatus_Wait;
new Handle:mmws_CvarHostnameStatus_HalfWait;
new Handle:mmws_CvarHostnameStatus_Knife;
new Handle:mmws_CvarHostnameStatus_Select;
new Handle:mmws_CvarHostnameStatus_Check;
new Handle:mmws_CvarHostnameStatus_Live;
new Handle:mmws_CvarHostnameStatus_LiveType;
new Handle:mmws_CvarHostnameStatus_Live_First;
new Handle:mmws_CvarHostnameStatus_Vote;
new Handle:mmws_CvarDemoFolder;
new String:Status_Wait[128];
new String:Status_HalfWait[128];
new String:Status_Knife[128];
new String:Status_Select[128];
new String:Status_Check[128];
new String:Status_Live[128];
new String:Status_Live_First[128];
new String:Status_Vote[128];
new String:DefaultMap[128];
new Handle:mmws_CvarModeDefault;
new Handle:mmws_CvarMixOnly;
new Handle:mmws_CvarDefaultMap;
new Handle:mmws_CvarSteamGroupAccess;
new Handle:mmws_CvarSteamGroupAdminAccess;
new Handle:mmws_CvarSteamGroup;
new Handle:mmws_CvarSteamGroupAdmin;
new Handle:mmws_CvarStatsUrl;
new Handle:mmws_CvarStatsHost;
new Handle:mmws_CvarStatsDatabase;
new Handle:mmws_CvarStatsUser;
new Handle:mmws_CvarStatsPassword;
new Handle:mmws_CvarStatsPort;
new Handle:mmws_CvarHelpUrl;
new Handle:mmws_CvarRestrictak47;
new Handle:mmws_CvarRestrictaug;
new Handle:mmws_CvarRestrictawp;
new Handle:mmws_CvarRestrictdeagle;
new Handle:mmws_CvarRestrictelite;
new Handle:mmws_CvarRestrictfamas;
new Handle:mmws_CvarRestrictfiveseven;
new Handle:mmws_CvarRestrictg3sg1;
new Handle:mmws_CvarRestrictgalil;
new Handle:mmws_CvarRestrictglock;
new Handle:mmws_CvarRestrictm249;
new Handle:mmws_CvarRestrictm3;
new Handle:mmws_CvarRestrictm4a1;
new Handle:mmws_CvarRestrictmac10;
new Handle:mmws_CvarRestrictmp5navy;
new Handle:mmws_CvarRestrictp228;
new Handle:mmws_CvarRestrictp90;
new Handle:mmws_CvarRestrictscout;
new Handle:mmws_CvarRestrictsg550;
new Handle:mmws_CvarRestrictsg552;
new Handle:mmws_CvarRestricttmp;
new Handle:mmws_CvarRestrictump45;
new Handle:mmws_CvarRestrictusp;
new Handle:mmws_CvarRestrictxm1014;
new String:s_PluginName[32];
new autofsdelay;
new g_Count[66];
new bool:mmws_Joined[66];
new bool:mmws_Team[66];
new Handle:g_deathcam_delays[66];
new bool:g_bGetDownload = 1;
new bool:g_bGetSource;
new Handle:g_hPluginPacks;
new Handle:g_hDownloadQueue;
new Handle:g_hRemoveQueue;
new bool:g_bDownloading;
new bool:license;
new String:g_sDataPath[256];
new Handle:mmws_OnPluginChecking;
new Handle:mmws_OnPluginDownloading;
new Handle:mmws_OnPluginUpdating;
new Handle:mmws_OnPluginUpdated;
public Plugin:myinfo =
{
	name = "Match&Mix Wars System",
	description = "An automative Match&Mix Wars System created by MixWars (mixwars.eu)",
	author = "apkon",
	version = "5.26",
	url = "http://mixwars.eu"
};
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	VerifyCoreVersion();
	return 0;
}

Float:operator/(Float:,_:)(Float:oper1, oper2)
{
	return oper1 / float(oper2);
}

bool:operator==(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) == 0;
}

bool:operator>(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) > 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

CharToLower(chr)
{
	if (IsCharUpper(chr))
	{
		return chr | 32;
	}
	return chr;
}

FindCharInString(String:str[], c, bool:reverse)
{
	new i;
	new len = strlen(str);
	if (!reverse)
	{
		i = 0;
		while (i < len)
		{
			if (c == str[i])
			{
				return i;
			}
			i++;
		}
	}
	else
	{
		i = len + -1;
		while (0 <= i)
		{
			if (c == str[i])
			{
				return i;
			}
			i--;
		}
	}
	return -1;
}

ExplodeString(String:text[], String:split[], String:buffers[][], maxStrings, maxStringLength, bool:copyRemainder)
{
	new reloc_idx;
	new idx;
	new total;
	if (maxStrings < 1)
	{
		return 0;
	}
	idx = var2;
	while (var2 != -1)
	{
		reloc_idx = idx + reloc_idx;
		total++;
		if (maxStrings == total)
		{
			if (copyRemainder)
			{
				strcopy(buffers[total + -1], maxStringLength, text[reloc_idx - idx]);
			}
			return total;
		}
	}
	total++;
	strcopy(buffers[total], maxStringLength, text[reloc_idx]);
	return total;
}

bool:WriteFileCell(Handle:hndl, data, size)
{
	new array[1];
	array[0] = data;
	return WriteFile(hndl, array, 1, size);
}

Handle:CreateDataTimer(Float:interval, Timer:func, &Handle:datapack, flags)
{
	datapack = CreateDataPack();
	flags |= 512;
	return CreateTimer(interval, func, datapack, flags);
}

Handle:StartMessageOne(String:msgname[], client, flags)
{
	new players[1];
	players[0] = client;
	return StartMessage(msgname, players, 1, flags);
}

PrintHintTextToAll(String:format[])
{
	decl String:buffer[192];
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 192, format, 2);
			PrintHintText(i, "%s", buffer);
			i++;
		}
		i++;
	}
	return 0;
}

ShowMOTDPanel(client, String:title[], String:msg[], type)
{
	decl String:num[4];
	new Handle:Kv = CreateKeyValues("data", "", "");
	IntToString(type, num, 3);
	KvSetString(Kv, "title", title);
	KvSetString(Kv, "type", num);
	KvSetString(Kv, "msg", msg);
	ShowVGUIPanel(client, "info", Kv, true);
	CloseHandle(Kv);
	return 0;
}

CS_GetLogString(client, String:LogString[], size)
{
	if (client)
	{
		return -1;
	}
	new String:player_name[32];
	new userid;
	new String:authid[32];
	new String:team[32];
	GetClientName(client, player_name, 32);
	GetClientAuthString(client, authid, 32);
	userid = GetClientUserId(client);
	if (!(GetClientTeam(client) == 2))
	{
		if (GetClientTeam(client) == 3)
		{
		}
		else
		{
			if (GetClientTeam(client) == 1)
			{
			}
		}
	}
	Format(LogString, size, "%s [ID: %d][%s][%s]", player_name, userid, authid, team);
	return client;
}

/* ERROR! Index was outside the bounds of the array. */
 function "CS_GetAdvLogString" (number 14)

IntToMoney(OldMoney, String:NewMoney[], size)
{
	new String:Temp[32];
	new String:OldMoneyStr[32];
	new tempChar;
	new RealLen;
	IntToString(OldMoney, OldMoneyStr, 32);
	new i = strlen(OldMoneyStr) + -1;
	while (0 <= i)
	{
		if (RealLen)
		{
			tempChar = OldMoneyStr[i];
			Format(Temp, 32, "%s,%s", tempChar, Temp);
		}
		else
		{
			tempChar = OldMoneyStr[i];
			Format(Temp, 32, "%s%s", tempChar, Temp);
		}
		RealLen++;
		i--;
	}
	Format(NewMoney, size, "%s", Temp);
	return 0;
}

GetOtherTeam(team)
{
	if (team == 2)
	{
		return 3;
	}
	if (team == 3)
	{
		return 2;
	}
	return 0;
}

CS_SwapTeams()
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			ChangeClientTeam(i, GetOtherTeam(GetClientTeam(i)));
			i++;
		}
		i++;
	}
	return 0;
}

CS_GetAdminPlayingCount()
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			count++;
			i++;
		}
		i++;
	}
	return count;
}

CS_GetPlayingCount()
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			count++;
			i++;
		}
		i++;
	}
	return count;
}

CS_GetPlayersCount()
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			count++;
			i++;
		}
		i++;
	}
	return count;
}

CS_GetSpecCount()
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			count++;
			i++;
		}
		i++;
	}
	return count;
}

CS_GetSubCount()
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			count++;
			i++;
		}
		i++;
	}
	return count;
}

CS_GetPlayingTCount()
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			count++;
			i++;
		}
		i++;
	}
	return count;
}

CS_GetPlayingCTCount()
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			count++;
			i++;
		}
		i++;
	}
	return count;
}

CS_SpawnSpectator()
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			ChangeClientTeam(i, 1);
			i++;
		}
		i++;
	}
	return 0;
}

CS_ReadyPlayersKnifeWait()
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			count++;
			i++;
		}
		i++;
	}
	return count;
}

CS_ReadyPlayersKnife()
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			count++;
			i++;
		}
		i++;
	}
	return count;
}

CS_StripButKnife(client, bool:equip)
{
	if (!IsClientInGame(client))
	{
		return 0;
	}
	new item_index;
	new i;
	while (i < 5)
	{
		if (!(i == 2))
		{
			item_index = var2;
			if (var2 != -1)
			{
				RemovePlayerItem(client, item_index);
				RemoveEdict(item_index);
			}
			if (equip)
			{
				CS_EquipKnife(client);
			}
		}
		i++;
	}
	return 1;
}

GetNumAlive(team)
{
	new count;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			count++;
			i++;
		}
		i++;
	}
	return count;
}

CS_EquipKnife(client)
{
	ClientCommand(client, "slot3");
	return 0;
}

StripFilename(String:filename[], size)
{
	ReplaceString(filename, size, "\", "", true);
	ReplaceString(filename, size, "/", "", true);
	ReplaceString(filename, size, ":", "", true);
	ReplaceString(filename, size, "*", "", true);
	ReplaceString(filename, size, "?", "", true);
	ReplaceString(filename, size, "<", "", true);
	ReplaceString(filename, size, ">", "", true);
	ReplaceString(filename, size, "|", "", true);
	ReplaceString(filename, size, ";", "", true);
	ReplaceString(filename, size, "-", "+", true);
	ReplaceString(filename, size, " ", "_", true);
	return 0;
}

StringToLower(String:input[], size)
{
	new i;
	while (i < size)
	{
		input[i] = CharToLower(input[i]);
		i++;
	}
	return 0;
}

SetConVarIntHidden(Handle:cvar, value)
{
	new String:cvar_name[64];
	new String:value_string[512];
	new flags = GetConVarFlags(cvar);
	SetConVarFlags(cvar, flags & -257);
	SetConVarInt(cvar, value, false, false);
	GetConVarName(cvar, cvar_name, 64);
	IntToString(value, value_string, 512);
	SetConVarFlags(cvar, flags);
	return 0;
}

SetConVarStringHidden(Handle:cvar, String:value[])
{
	new String:cvar_name[64];
	new flags = GetConVarFlags(cvar);
	SetConVarFlags(cvar, flags & -257);
	SetConVarString(cvar, value, false, false);
	GetConVarName(cvar, cvar_name, 64);
	SetConVarFlags(cvar, flags);
	return 0;
}

SimpleRegexMatch(String:str[], String:pattern[], flags, String:error[], maxLen)
{
	new Handle:regex = CompileRegex(pattern, flags, error, maxLen, 0);
	if (regex)
	{
		new substrings = MatchRegex(regex, str, 0);
		CloseHandle(regex);
		return substrings;
	}
	return -1;
}

CPrintToChat(client, String:message[])
{
	CCheckTrie();
	if (client <= 0)
	{
		ThrowError("Invalid client index %i", client);
	}
	if (!IsClientInGame(client))
	{
		ThrowError("Client %i is not in game", client);
	}
	decl String:buffer[256];
	decl String:buffer2[256];
	SetGlobalTransTarget(client);
	Format(buffer, 256, "", message);
	VFormat(buffer2, 256, buffer, 3);
	CReplaceColorCodes(buffer2, 0, false, 256);
	CSendMessage(client, buffer2, 0);
	return 0;
}

CPrintToChatAll(String:message[])
{
	CCheckTrie();
	decl String:buffer[256];
	decl String:buffer2[256];
	new i = 1;
	while (i <= MaxClients)
	{
		if (!IsClientInGame(i))
		{
			CSkipList[i] = 0;
		}
		else
		{
			SetGlobalTransTarget(i);
			Format(buffer, 256, "", message);
			VFormat(buffer2, 256, buffer, 2);
			CReplaceColorCodes(buffer2, 0, false, 256);
			CSendMessage(i, buffer2, 0);
		}
		i++;
	}
	return 0;
}

CPrintToChatEx(client, author, String:message[])
{
	CCheckTrie();
	if (client <= 0)
	{
		ThrowError("Invalid client index %i", client);
	}
	if (!IsClientInGame(client))
	{
		ThrowError("Client %i is not in game", client);
	}
	if (author <= 0)
	{
		ThrowError("Invalid client index %i", author);
	}
	if (!IsClientInGame(author))
	{
		ThrowError("Client %i is not in game", author);
	}
	decl String:buffer[256];
	decl String:buffer2[256];
	SetGlobalTransTarget(client);
	Format(buffer, 256, "", message);
	VFormat(buffer2, 256, buffer, 4);
	CReplaceColorCodes(buffer2, author, false, 256);
	CSendMessage(client, buffer2, author);
	return 0;
}

CPrintToChatAllEx(author, String:message[])
{
	CCheckTrie();
	if (author <= 0)
	{
		ThrowError("Invalid client index %i", author);
	}
	if (!IsClientInGame(author))
	{
		ThrowError("Client %i is not in game", author);
	}
	decl String:buffer[256];
	decl String:buffer2[256];
	new i = 1;
	while (i <= MaxClients)
	{
		if (!IsClientInGame(i))
		{
			CSkipList[i] = 0;
		}
		else
		{
			SetGlobalTransTarget(i);
			Format(buffer, 256, "", message);
			VFormat(buffer2, 256, buffer, 3);
			CReplaceColorCodes(buffer2, author, false, 256);
			CSendMessage(i, buffer2, author);
		}
		i++;
	}
	return 0;
}

CSendMessage(client, String:message[], author)
{
	if (!author)
	{
		author = client;
	}
	decl String:buffer[256];
	decl String:game[16];
	GetGameFolderName(game, 16);
	strcopy(buffer, 256, message);
	new UserMsg:index = GetUserMessageId("SayText2");
	if (index == UserMsg:-1)
	{
		if (StrEqual(game, "dod", true))
		{
			new team = GetClientTeam(author);
			if (team)
			{
				decl String:temp[16];
				Format(temp, 16, "\x07%06X", var1[0][0][var1][team + -1]);
				ReplaceString(buffer, 256, "\x03", temp, false);
			}
			else
			{
				ReplaceString(buffer, 256, "\x03", "\x04", false);
			}
		}
		PrintToChat(client, "%s", buffer);
		return 0;
	}
	new Handle:buf = StartMessageOne("SayText2", client, 132);
	BfWriteByte(buf, author);
	BfWriteByte(buf, 1);
	BfWriteString(buf, buffer);
	EndMessage();
	return 0;
}

CCheckTrie()
{
	if (!CTrie)
	{
		CTrie = InitColorTrie();
	}
	return 0;
}

CReplaceColorCodes(String:buffer[], author, bool:removeTags, maxlen)
{
	CCheckTrie();
	if (!removeTags)
	{
		ReplaceString(buffer, maxlen, "{default}", "", false);
	}
	else
	{
		ReplaceString(buffer, maxlen, "{default}", "", false);
		ReplaceString(buffer, maxlen, "{teamcolor}", "", false);
	}
	if (author)
	{
		if (author < 0)
		{
			ThrowError("Invalid client index %i", author);
		}
		if (!IsClientInGame(author))
		{
			ThrowError("Client %i is not in game", author);
		}
		ReplaceString(buffer, maxlen, "{teamcolor}", "\x03", false);
	}
	new cursor;
	new value;
	decl String:tag[32];
	decl String:buff[32];
	decl output[maxlen];
	strcopy(output, maxlen, buffer);
	new Handle:regex = CompileRegex("{[a-zA-Z0-9]+}", 0, "", 0, 0);
	new i;
	while (i < 1000)
	{
		if (MatchRegex(regex, buffer[cursor], 0) < 1)
		{
			CloseHandle(regex);
			strcopy(buffer, maxlen, output);
			return 0;
		}
		GetRegexSubString(regex, 0, tag, 32);
		CStrToLower(tag);
		cursor = StrContains(buffer[cursor], tag, false) + cursor + 1;
		strcopy(buff, 32, tag);
		ReplaceString(buff, 32, "{", "", true);
		ReplaceString(buff, 32, "}", "", true);
		if (GetTrieValue(CTrie, buff, value))
		{
			if (removeTags)
			{
				ReplaceString(output, maxlen, tag, "", false);
			}
			else
			{
				Format(buff, 32, "\x07%06X", value);
				ReplaceString(output, maxlen, tag, buff, false);
			}
		}
		i++;
	}
	LogError("[MORE COLORS] Infinite loop broken.");
	return 0;
}

CStrToLower(String:buffer[])
{
	new len = strlen(buffer);
	new i;
	while (i < len)
	{
		buffer[i] = CharToLower(buffer[i]);
		i++;
	}
	return 0;
}

Handle:InitColorTrie()
{
	new Handle:hTrie = CreateTrie();
	SetTrieValue(hTrie, "aliceblue", any:15792383, true);
	SetTrieValue(hTrie, "allies", any:5077314, true);
	SetTrieValue(hTrie, "antiquewhite", any:16444375, true);
	SetTrieValue(hTrie, "aqua", any:65535, true);
	SetTrieValue(hTrie, "aquamarine", any:8388564, true);
	SetTrieValue(hTrie, "axis", any:16728128, true);
	SetTrieValue(hTrie, "azure", any:32767, true);
	SetTrieValue(hTrie, "beige", any:16119260, true);
	SetTrieValue(hTrie, "bisque", any:16770244, true);
	SetTrieValue(hTrie, "black", any:0, true);
	SetTrieValue(hTrie, "blanchedalmond", any:16772045, true);
	SetTrieValue(hTrie, "blue", any:10079487, true);
	SetTrieValue(hTrie, "blueviolet", any:9055202, true);
	SetTrieValue(hTrie, "brown", any:10824234, true);
	SetTrieValue(hTrie, "burlywood", any:14596231, true);
	SetTrieValue(hTrie, "cadetblue", any:6266528, true);
	SetTrieValue(hTrie, "chartreuse", any:8388352, true);
	SetTrieValue(hTrie, "chocolate", any:13789470, true);
	SetTrieValue(hTrie, "community", any:7385162, true);
	SetTrieValue(hTrie, "coral", any:16744272, true);
	SetTrieValue(hTrie, "cornflowerblue", any:6591981, true);
	SetTrieValue(hTrie, "cornsilk", any:16775388, true);
	SetTrieValue(hTrie, "crimson", any:14423100, true);
	SetTrieValue(hTrie, "cyan", any:65535, true);
	SetTrieValue(hTrie, "darkblue", any:139, true);
	SetTrieValue(hTrie, "darkcyan", any:35723, true);
	SetTrieValue(hTrie, "darkgoldenrod", any:12092939, true);
	SetTrieValue(hTrie, "darkgray", any:11119017, true);
	SetTrieValue(hTrie, "darkgrey", any:11119017, true);
	SetTrieValue(hTrie, "darkgreen", any:25600, true);
	SetTrieValue(hTrie, "darkkhaki", any:12433259, true);
	SetTrieValue(hTrie, "darkmagenta", any:9109643, true);
	SetTrieValue(hTrie, "darkolivegreen", any:5597999, true);
	SetTrieValue(hTrie, "darkorange", any:16747520, true);
	SetTrieValue(hTrie, "darkorchid", any:10040012, true);
	SetTrieValue(hTrie, "darkred", any:9109504, true);
	SetTrieValue(hTrie, "darksalmon", any:15308410, true);
	SetTrieValue(hTrie, "darkseagreen", any:9419919, true);
	SetTrieValue(hTrie, "darkslateblue", any:4734347, true);
	SetTrieValue(hTrie, "darkslategray", any:3100495, true);
	SetTrieValue(hTrie, "darkslategrey", any:3100495, true);
	SetTrieValue(hTrie, "darkturquoise", any:52945, true);
	SetTrieValue(hTrie, "darkviolet", any:9699539, true);
	SetTrieValue(hTrie, "deeppink", any:16716947, true);
	SetTrieValue(hTrie, "deepskyblue", any:49151, true);
	SetTrieValue(hTrie, "dimgray", any:6908265, true);
	SetTrieValue(hTrie, "dimgrey", any:6908265, true);
	SetTrieValue(hTrie, "dodgerblue", any:2003199, true);
	SetTrieValue(hTrie, "firebrick", any:11674146, true);
	SetTrieValue(hTrie, "floralwhite", any:16775920, true);
	SetTrieValue(hTrie, "forestgreen", any:2263842, true);
	SetTrieValue(hTrie, "fuchsia", any:16711935, true);
	SetTrieValue(hTrie, "fullblue", any:255, true);
	SetTrieValue(hTrie, "fullred", any:16711680, true);
	SetTrieValue(hTrie, "gainsboro", any:14474460, true);
	SetTrieValue(hTrie, "genuine", any:5076053, true);
	SetTrieValue(hTrie, "ghostwhite", any:16316671, true);
	SetTrieValue(hTrie, "gold", any:16766720, true);
	SetTrieValue(hTrie, "goldenrod", any:14329120, true);
	SetTrieValue(hTrie, "gray", any:13421772, true);
	SetTrieValue(hTrie, "grey", any:13421772, true);
	SetTrieValue(hTrie, "green", any:4128574, true);
	SetTrieValue(hTrie, "greenyellow", any:11403055, true);
	SetTrieValue(hTrie, "haunted", any:3732395, true);
	SetTrieValue(hTrie, "honeydew", any:15794160, true);
	SetTrieValue(hTrie, "hotpink", any:16738740, true);
	SetTrieValue(hTrie, "indianred", any:13458524, true);
	SetTrieValue(hTrie, "indigo", any:4915330, true);
	SetTrieValue(hTrie, "ivory", any:16777200, true);
	SetTrieValue(hTrie, "khaki", any:15787660, true);
	SetTrieValue(hTrie, "lavender", any:15132410, true);
	SetTrieValue(hTrie, "lavenderblush", any:16773365, true);
	SetTrieValue(hTrie, "lawngreen", any:8190976, true);
	SetTrieValue(hTrie, "lemonchiffon", any:16775885, true);
	SetTrieValue(hTrie, "lightblue", any:11393254, true);
	SetTrieValue(hTrie, "lightcoral", any:15761536, true);
	SetTrieValue(hTrie, "lightcyan", any:14745599, true);
	SetTrieValue(hTrie, "lightgoldenrodyellow", any:16448210, true);
	SetTrieValue(hTrie, "lightgray", any:13882323, true);
	SetTrieValue(hTrie, "lightgrey", any:13882323, true);
	SetTrieValue(hTrie, "lightgreen", any:10092441, true);
	SetTrieValue(hTrie, "lightpink", any:16758465, true);
	SetTrieValue(hTrie, "lightsalmon", any:16752762, true);
	SetTrieValue(hTrie, "lightseagreen", any:2142890, true);
	SetTrieValue(hTrie, "lightskyblue", any:8900346, true);
	SetTrieValue(hTrie, "lightslategray", any:7833753, true);
	SetTrieValue(hTrie, "lightslategrey", any:7833753, true);
	SetTrieValue(hTrie, "lightsteelblue", any:11584734, true);
	SetTrieValue(hTrie, "lightyellow", any:16777184, true);
	SetTrieValue(hTrie, "lime", any:65280, true);
	SetTrieValue(hTrie, "limegreen", any:3329330, true);
	SetTrieValue(hTrie, "linen", any:16445670, true);
	SetTrieValue(hTrie, "magenta", any:16711935, true);
	SetTrieValue(hTrie, "maroon", any:8388608, true);
	SetTrieValue(hTrie, "mediumaquamarine", any:6737322, true);
	SetTrieValue(hTrie, "mediumblue", any:205, true);
	SetTrieValue(hTrie, "mediumorchid", any:12211667, true);
	SetTrieValue(hTrie, "mediumpurple", any:9662680, true);
	SetTrieValue(hTrie, "mediumseagreen", any:3978097, true);
	SetTrieValue(hTrie, "mediumslateblue", any:8087790, true);
	SetTrieValue(hTrie, "mediumspringgreen", any:64154, true);
	SetTrieValue(hTrie, "mediumturquoise", any:4772300, true);
	SetTrieValue(hTrie, "mediumvioletred", any:13047173, true);
	SetTrieValue(hTrie, "midnightblue", any:1644912, true);
	SetTrieValue(hTrie, "mintcream", any:16121850, true);
	SetTrieValue(hTrie, "mistyrose", any:16770273, true);
	SetTrieValue(hTrie, "moccasin", any:16770229, true);
	SetTrieValue(hTrie, "navajowhite", any:16768685, true);
	SetTrieValue(hTrie, "navy", any:128, true);
	SetTrieValue(hTrie, "normal", any:11711154, true);
	SetTrieValue(hTrie, "oldlace", any:16643558, true);
	SetTrieValue(hTrie, "olive", any:10404687, true);
	SetTrieValue(hTrie, "olivedrab", any:7048739, true);
	SetTrieValue(hTrie, "orange", any:16753920, true);
	SetTrieValue(hTrie, "orangered", any:16729344, true);
	SetTrieValue(hTrie, "orchid", any:14315734, true);
	SetTrieValue(hTrie, "palegoldenrod", any:15657130, true);
	SetTrieValue(hTrie, "palegreen", any:10025880, true);
	SetTrieValue(hTrie, "paleturquoise", any:11529966, true);
	SetTrieValue(hTrie, "palevioletred", any:14184595, true);
	SetTrieValue(hTrie, "papayawhip", any:16773077, true);
	SetTrieValue(hTrie, "peachpuff", any:16767673, true);
	SetTrieValue(hTrie, "peru", any:13468991, true);
	SetTrieValue(hTrie, "pink", any:16761035, true);
	SetTrieValue(hTrie, "plum", any:14524637, true);
	SetTrieValue(hTrie, "powderblue", any:11591910, true);
	SetTrieValue(hTrie, "purple", any:8388736, true);
	SetTrieValue(hTrie, "red", any:16728128, true);
	SetTrieValue(hTrie, "rosybrown", any:12357519, true);
	SetTrieValue(hTrie, "royalblue", any:4286945, true);
	SetTrieValue(hTrie, "saddlebrown", any:9127187, true);
	SetTrieValue(hTrie, "salmon", any:16416882, true);
	SetTrieValue(hTrie, "sandybrown", any:16032864, true);
	SetTrieValue(hTrie, "seagreen", any:3050327, true);
	SetTrieValue(hTrie, "seashell", any:16774638, true);
	SetTrieValue(hTrie, "selfmade", any:7385162, true);
	SetTrieValue(hTrie, "sienna", any:10506797, true);
	SetTrieValue(hTrie, "silver", any:12632256, true);
	SetTrieValue(hTrie, "skyblue", any:8900331, true);
	SetTrieValue(hTrie, "slateblue", any:6970061, true);
	SetTrieValue(hTrie, "slategray", any:7372944, true);
	SetTrieValue(hTrie, "slategrey", any:7372944, true);
	SetTrieValue(hTrie, "snow", any:16775930, true);
	SetTrieValue(hTrie, "springgreen", any:65407, true);
	SetTrieValue(hTrie, "steelblue", any:4620980, true);
	SetTrieValue(hTrie, "strange", any:13593138, true);
	SetTrieValue(hTrie, "tan", any:13808780, true);
	SetTrieValue(hTrie, "teal", any:32896, true);
	SetTrieValue(hTrie, "thistle", any:14204888, true);
	SetTrieValue(hTrie, "tomato", any:16737095, true);
	SetTrieValue(hTrie, "turquoise", any:4251856, true);
	SetTrieValue(hTrie, "unique", any:16766720, true);
	SetTrieValue(hTrie, "unusual", any:8802476, true);
	SetTrieValue(hTrie, "valve", any:10817401, true);
	SetTrieValue(hTrie, "vintage", any:4678289, true);
	SetTrieValue(hTrie, "violet", any:15631086, true);
	SetTrieValue(hTrie, "wheat", any:16113331, true);
	SetTrieValue(hTrie, "white", any:16777215, true);
	SetTrieValue(hTrie, "whitesmoke", any:16119285, true);
	SetTrieValue(hTrie, "yellow", any:16776960, true);
	SetTrieValue(hTrie, "yellowgreen", any:10145074, true);
	return hTrie;
}

GetMaxPlugins()
{
	return GetArraySize(g_hPluginPacks);
}

bool:IsValidPlugin(Handle:plugin)
{
	new Handle:hIterator = GetPluginIterator();
	new bool:bIsValid;
	while (MorePlugins(hIterator))
	{
		if (ReadPlugin(hIterator) == plugin)
		{
			bIsValid = 1;
			CloseHandle(hIterator);
			return bIsValid;
		}
	}
	CloseHandle(hIterator);
	return bIsValid;
}

PluginToIndex(Handle:plugin)
{
	new Handle:hPluginPack;
	new maxPlugins = GetMaxPlugins();
	new i;
	while (i < maxPlugins)
	{
		hPluginPack = GetArrayCell(g_hPluginPacks, i, 0, false);
		ResetPack(hPluginPack, false);
		if (ReadPackCell(hPluginPack) == plugin)
		{
			return i;
		}
		i++;
	}
	return -1;
}

Handle:IndexToPlugin(index)
{
	new Handle:hPluginPack = GetArrayCell(g_hPluginPacks, index, 0, false);
	ResetPack(hPluginPack, false);
	return ReadPackCell(hPluginPack);
}

MMWS_Updater_AddPlugin(Handle:plugin, String:url[])
{
	new index = PluginToIndex(plugin);
	if (index != -1)
	{
		new maxPlugins = GetArraySize(g_hRemoveQueue);
		new i;
		while (i < maxPlugins)
		{
			if (GetArrayCell(g_hRemoveQueue, i, 0, false) == plugin)
			{
				RemoveFromArray(g_hRemoveQueue, i);
				MMWS_Updater_SetURL(index, url);
			}
			i++;
		}
		MMWS_Updater_SetURL(index, url);
	}
	else
	{
		new Handle:hPluginPack = CreateDataPack();
		new Handle:hFiles = CreateArray(256, 0);
		WritePackCell(hPluginPack, plugin);
		WritePackCell(hPluginPack, hFiles);
		WritePackCell(hPluginPack, 0);
		WritePackString(hPluginPack, url);
		PushArrayCell(g_hPluginPacks, hPluginPack);
	}
	return 0;
}

MMWS_Updater_QueueRemovePlugin(Handle:plugin)
{
	new maxPlugins = GetArraySize(g_hRemoveQueue);
	new i;
	while (i < maxPlugins)
	{
		if (GetArrayCell(g_hRemoveQueue, i, 0, false) == plugin)
		{
			return 0;
		}
		i++;
	}
	PushArrayCell(g_hRemoveQueue, plugin);
	MMWS_Updater_FreeMemory();
	return 0;
}

MMWS_Updater_RemovePlugin(index)
{
	CloseHandle(MMWS_Updater_GetFiles(index));
	CloseHandle(GetArrayCell(g_hPluginPacks, index, 0, false));
	RemoveFromArray(g_hPluginPacks, index);
	return 0;
}

Handle:MMWS_Updater_GetFiles(index)
{
	new Handle:hPluginPack = GetArrayCell(g_hPluginPacks, index, 0, false);
	SetPackPosition(hPluginPack, 8);
	return ReadPackCell(hPluginPack);
}

MMWS_UpdateStatus:MMWS_Updater_GetStatus(index)
{
	new Handle:hPluginPack = GetArrayCell(g_hPluginPacks, index, 0, false);
	SetPackPosition(hPluginPack, 16);
	return ReadPackCell(hPluginPack);
}

MMWS_Updater_SetStatus(index, MMWS_UpdateStatus:status)
{
	new Handle:hPluginPack = GetArrayCell(g_hPluginPacks, index, 0, false);
	SetPackPosition(hPluginPack, 16);
	WritePackCell(hPluginPack, status);
	return 0;
}

MMWS_Updater_GetURL(index, String:buffer[], size)
{
	new Handle:hPluginPack = GetArrayCell(g_hPluginPacks, index, 0, false);
	SetPackPosition(hPluginPack, 24);
	ReadPackString(hPluginPack, buffer, size);
	return 0;
}

MMWS_Updater_SetURL(index, String:url[])
{
	new Handle:hPluginPack = GetArrayCell(g_hPluginPacks, index, 0, false);
	SetPackPosition(hPluginPack, 24);
	WritePackString(hPluginPack, url);
	return 0;
}

StripPathFilename(String:path[])
{
	strcopy(path, FindCharInString(path, 47, true) + 1, path);
	return 0;
}

GetPathBasename(String:path[], String:buffer[], maxlength)
{
	new check = -1;
	check = var2;
	if (var2 == -1)
	{
		strcopy(buffer, maxlength, path[check + 1]);
	}
	else
	{
		strcopy(buffer, maxlength, path);
	}
	return 0;
}

PrefixURL(String:buffer[], maxlength, String:url[])
{
	if (strncmp(url, "http://", 7, true))
	{
		FormatEx(buffer, maxlength, "http://%s", url);
	}
	else
	{
		strcopy(buffer, maxlength, url);
	}
	return 0;
}

ParseURL(String:url[], String:host[], maxHost, String:location[], maxLoc, String:filename[], maxName)
{
	new idx = StrContains(url, "://", true);
	if (idx != -1)
	{
		var1 = idx + 3;
	}
	else
	{
		var1 = 0;
	}
	idx = var1;
	new String:dirs[64][64] = "@";
	new total = ExplodeString(url[idx], "/", dirs, 16, 64, false);
	Format(host, maxHost, "%s", dirs[0][dirs]);
	location[0] = 0;
	new i = 1;
	while (total + -1 > i)
	{
		Format(location, maxLoc, "%s/%s", location, dirs[i]);
		i++;
	}
	Format(filename, maxName, "%s", dirs[total + -1]);
	return 0;
}

ParseKVPathForLocal(String:path[], String:buffer[], maxlength)
{
	new String:dirs[64][64] = "@";
	new total = ExplodeString(path, "/", dirs, 16, 64, false);
	if (StrEqual(dirs[0][dirs], "Path_SM", true))
	{
		BuildPath(PathType:0, buffer, maxlength, "");
	}
	else
	{
		buffer[0] = 0;
	}
	new i = 1;
	while (total + -1 > i)
	{
		Format(buffer, maxlength, "%s%s/", buffer, dirs[i]);
		if (!DirExists(buffer))
		{
			CreateDirectory(buffer, 511);
			i++;
		}
		i++;
	}
	Format(buffer, maxlength, "%s%s", buffer, dirs[total + -1]);
	return 0;
}

ParseKVPathForDownload(String:path[], String:buffer[], maxlength)
{
	new String:dirs[64][64] = "@";
	new total = ExplodeString(path, "/", dirs, 16, 64, false);
	buffer[0] = 0;
	new i = 1;
	while (i < total)
	{
		Format(buffer, maxlength, "%s/%s", buffer, dirs[i]);
		i++;
	}
	return 0;
}

bool:ParseUpdateFile(index, String:path[])
{
	new Handle:kv = CreateKeyValues("Updater", "", "");
	if (!FileToKeyValues(kv, path))
	{
		CloseHandle(kv);
		return false;
	}
	decl String:kvLatestVersion[8];
	decl String:kvPrevVersion[8];
	decl String:sBuffer[256];
	new bool:bUpdate;
	new Handle:hNotes = CreateArray(192, 0);
	new Handle:hPlugin = IndexToPlugin(index);
	new Handle:hFiles = MMWS_Updater_GetFiles(index);
	ClearArray(hFiles);
	if (KvJumpToKey(kv, "Information", false))
	{
		if (KvJumpToKey(kv, "Version", false))
		{
			KvGetString(kv, "Latest", kvLatestVersion, 5, "");
			KvGetString(kv, "Previous", kvPrevVersion, 5, "");
			KvGoBack(kv);
		}
		if (KvGotoFirstSubKey(kv, false))
		{
			do
			{
				KvGetSectionName(kv, sBuffer, 256);
				if (StrEqual(sBuffer, "Notes", true))
				{
					KvGetString(kv, NULL_STRING, sBuffer, 256, "");
					PushArrayString(hNotes, sBuffer);
				}
			} while (KvGotoNextKey(kv, false));
			KvGoBack(kv);
		}
		KvGoBack(kv);
		decl String:sCurrentVersion[8];
		decl String:sFilename[64];
		GetPluginInfo(hPlugin, PluginInfo:3, sCurrentVersion, 5);
		if (!StrEqual(sCurrentVersion, kvLatestVersion, true))
		{
			decl String:sName[64];
			GetPluginFilename(hPlugin, sFilename, 64);
			GetPluginInfo(hPlugin, PluginInfo:0, sName, 64);
			new maxNotes = GetArraySize(hNotes);
			new i;
			while (i < maxNotes)
			{
				GetArrayString(hNotes, i, sBuffer, 256);
				i++;
			}
			bUpdate = 1;
		}
		if (bUpdate)
		{
			decl String:urlprefix[256];
			decl String:url[256];
			decl String:dest[256];
			MMWS_Updater_GetURL(index, urlprefix, 256);
			StripPathFilename(urlprefix);
			KvJumpToKey(kv, "Files", false);
			if (StrEqual(sCurrentVersion, kvPrevVersion, true))
			{
				KvJumpToKey(kv, "Patch", false);
			}
			if (KvGotoFirstSubKey(kv, false))
			{
				do
				{
					KvGetSectionName(kv, sBuffer, 256);
					if (StrEqual(sBuffer, "Plugin", true))
					{
						KvGetString(kv, NULL_STRING, sBuffer, 256, "");
						ParseKVPathForDownload(sBuffer, url, 256);
						Format(url, 256, "%s%s", urlprefix, url);
						ParseKVPathForLocal(sBuffer, dest, 256);
						decl String:sLocalBase[64];
						decl String:sPluginBase[64];
						GetPathBasename(dest, sLocalBase, 64);
						GetPathBasename(sFilename, sPluginBase, 64);
						if (StrEqual(sLocalBase, sPluginBase, true))
						{
							StripPathFilename(dest);
							Format(dest, 256, "%s/%s", dest, sFilename);
						}
						PushArrayString(hFiles, dest);
						Format(dest, 256, "%s.%s", dest, "temp");
						AddToDownloadQueue(index, url, dest);
					}
					if (KvGotoNextKey(kv, false))
					{
					}
				} while (StrEqual(sBuffer, "Plugin", true) || (g_bGetSource && StrEqual(sBuffer, "Source", true)));
			}
			MMWS_Updater_SetStatus(index, MMWS_UpdateStatus:2);
		}
		else
		{
			if (bUpdate)
			{
				MMWS_Updater_SetStatus(index, MMWS_UpdateStatus:3);
			}
		}
		CloseHandle(hNotes);
		CloseHandle(kv);
		return bUpdate;
	}
	CloseHandle(hNotes);
	CloseHandle(kv);
	return false;
}

Download_cURL(String:url[], String:dest[])
{
	decl String:sURL[256];
	PrefixURL(sURL, 256, url);
	new Handle:hFile = curl_OpenFile(dest, "wb");
	if (!hFile)
	{
		decl String:sError[256];
		FormatEx(sError, 256, "Error writing to file: %s", dest);
		DownloadEnded("1.4.4", sError);
	}
	new CURL_Default_opt[5][2];
	new Handle:headers = curl_slist();
	curl_slist_append(headers, "Pragma: no-cache");
	curl_slist_append(headers, "Cache-Control: no-cache");
	new Handle:hDLPack = CreateDataPack();
	WritePackCell(hDLPack, hFile);
	WritePackCell(hDLPack, headers);
	new Handle:curl = curl_easy_init();
	curl_easy_setopt_int_array(curl, CURL_Default_opt, 5);
	curl_easy_setopt_handle(curl, CURLoption:10001, hFile);
	curl_easy_setopt_string(curl, CURLoption:10002, url);
	curl_easy_setopt_handle(curl, CURLoption:10023, headers);
	curl_easy_perform_thread(curl, OnCurlComplete, hDLPack);
	return 0;
}

public OnCurlComplete(Handle:curl, CURLcode:code, hDLPack)
{
	ResetPack(hDLPack, false);
	CloseHandle(ReadPackCell(hDLPack));
	CloseHandle(ReadPackCell(hDLPack));
	CloseHandle(hDLPack);
	CloseHandle(curl);
	if (code)
	{
		decl String:sError[256];
		curl_easy_strerror(code, sError, 256);
		Format(sError, 256, "cURL error: %s", sError);
		DownloadEnded("1.4.4", sError);
	}
	else
	{
		DownloadEnded(".4.4", "");
	}
	return 0;
}

Download_Socket(String:url[], String:dest[])
{
	new Handle:hFile = OpenFile(dest, "wb");
	if (!hFile)
	{
		decl String:sError[256];
		FormatEx(sError, 256, "Error writing to file: %s", dest);
		DownloadEnded("1.4.4", sError);
	}
	decl String:hostname[64];
	decl String:location[128];
	decl String:filename[64];
	decl String:sRequest[384];
	ParseURL(url, hostname, 64, location, 128, filename, 64);
	FormatEx(sRequest, 384, "GET %s/%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\nPragma: no-cache\r\nCache-Control: no-cache\r\n\r\n", location, filename, hostname);
	new Handle:hDLPack = CreateDataPack();
	WritePackCell(hDLPack, 0);
	WritePackCell(hDLPack, hFile);
	WritePackString(hDLPack, sRequest);
	new Handle:socket = SocketCreate(SocketType:1, OnSocketError);
	SocketSetArg(socket, hDLPack);
	SocketSetOption(socket, SocketOption:1, 4096);
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, hostname, 80);
	return 0;
}

public OnSocketConnected(Handle:socket, hDLPack)
{
	decl String:sRequest[384];
	SetPackPosition(hDLPack, 16);
	ReadPackString(hDLPack, sRequest, 384);
	SocketSend(socket, sRequest, -1);
	return 0;
}

public OnSocketReceive(Handle:socket, String:data[], size, hDLPack)
{
	new idx;
	SetPackPosition(hDLPack, 0);
	new bool:bParsedHeader = ReadPackCell(hDLPack);
	if (!bParsedHeader)
	{
		idx = var1;
		if (var1 == -1)
		{
			idx = 0;
		}
		else
		{
			idx += 4;
		}
		SetPackPosition(hDLPack, 0);
		WritePackCell(hDLPack, 1);
	}
	SetPackPosition(hDLPack, 8);
	new Handle:hFile = ReadPackCell(hDLPack);
	while (idx < size)
	{
		idx++;
		WriteFileCell(hFile, data[idx], 1);
	}
	return 0;
}

public OnSocketDisconnected(Handle:socket, hDLPack)
{
	SetPackPosition(hDLPack, 8);
	CloseHandle(ReadPackCell(hDLPack));
	CloseHandle(hDLPack);
	CloseHandle(socket);
	DownloadEnded(".4.4", "");
	return 0;
}

public OnSocketError(Handle:socket, errorType, errorNum, hDLPack)
{
	SetPackPosition(hDLPack, 8);
	CloseHandle(ReadPackCell(hDLPack));
	CloseHandle(hDLPack);
	CloseHandle(socket);
	decl String:sError[256];
	FormatEx(sError, 256, "Socket error: %d (Error code %d)", errorType, errorNum);
	DownloadEnded("1.4.4", sError);
	return 0;
}

FinalizeDownload(index)
{
	decl String:newpath[256];
	decl String:oldpath[256];
	new Handle:hFiles = MMWS_Updater_GetFiles(index);
	new maxFiles = GetArraySize(hFiles);
	new i;
	while (i < maxFiles)
	{
		GetArrayString(hFiles, i, newpath, 256);
		Format(oldpath, 256, "%s.%s", newpath, "temp");
		if (FileExists(newpath, false))
		{
			DeleteFile(newpath);
		}
		RenameFile(newpath, oldpath);
		i++;
	}
	ClearArray(hFiles);
	return 0;
}

AbortDownload(index)
{
	decl String:path[256];
	new Handle:hFiles = MMWS_Updater_GetFiles(index);
	new maxFiles = GetArraySize(hFiles);
	new i;
	while (i < maxFiles)
	{
		GetArrayString(hFiles, 0, path, 256);
		Format(path, 256, "%s.%s", path, "temp");
		if (FileExists(path, false))
		{
			DeleteFile(path);
			i++;
		}
		i++;
	}
	ClearArray(hFiles);
	return 0;
}

ProcessDownloadQueue(bool:force)
{
	if (!force)
	{
		return 0;
	}
	new Handle:hQueuePack = GetArrayCell(g_hDownloadQueue, 0, 0, false);
	SetPackPosition(hQueuePack, 8);
	decl String:url[256];
	decl String:dest[256];
	ReadPackString(hQueuePack, url, 256);
	ReadPackString(hQueuePack, dest, 256);
	if (GetFeatureStatus(FeatureType:0, "curl_easy_init"))
	{
		if (GetFeatureStatus(FeatureType:0, "SocketCreate"))
		{
			SetFailState("This plugin requires either the cURL, Socket, or SteamTools extension to function.");
		}
		Download_Socket(url, dest);
	}
	else
	{
		Download_cURL(url, dest);
	}
	g_bDownloading = 1;
	return 0;
}

public Action:Timer_RetryQueue(Handle:timer)
{
	ProcessDownloadQueue(true);
	return Action:4;
}

AddToDownloadQueue(index, String:url[], String:dest[])
{
	new Handle:hQueuePack = CreateDataPack();
	WritePackCell(hQueuePack, index);
	WritePackString(hQueuePack, url);
	WritePackString(hQueuePack, dest);
	PushArrayCell(g_hDownloadQueue, hQueuePack);
	ProcessDownloadQueue(false);
	return 0;
}

DownloadEnded(bool:successful)
{
	new Handle:hQueuePack = GetArrayCell(g_hDownloadQueue, 0, 0, false);
	ResetPack(hQueuePack, false);
	decl String:url[256];
	decl String:dest[256];
	new index = ReadPackCell(hQueuePack);
	ReadPackString(hQueuePack, url, 256);
	ReadPackString(hQueuePack, dest, 256);
	CloseHandle(hQueuePack);
	RemoveFromArray(g_hDownloadQueue, 0);
	switch (MMWS_Updater_GetStatus(index))
	{
		case 1:
		{
			if (!successful)
			{
				MMWS_Updater_SetStatus(index, MMWS_UpdateStatus:0);
			}
		}
		case 2:
		{
			if (successful)
			{
				decl String:lastfile[256];
				new Handle:hFiles = MMWS_Updater_GetFiles(index);
				GetArrayString(hFiles, GetArraySize(hFiles) + -1, lastfile, 256);
				Format(lastfile, 256, "%s.%s", lastfile, "temp");
				if (StrEqual(dest, lastfile, true))
				{
					new Handle:hPlugin = IndexToPlugin(index);
					MMWS_OnPluginUpdating(hPlugin);
					FinalizeDownload(index);
					decl String:sName[64];
					GetPluginInfo(hPlugin, PluginInfo:0, sName, 64);
					MMWS_Updater_SetStatus(index, MMWS_UpdateStatus:3);
					MMWS_OnPluginUpdated(hPlugin);
				}
			}
			else
			{
				AbortDownload(index);
				MMWS_Updater_SetStatus(index, MMWS_UpdateStatus:4);
				decl String:filename[64];
				GetPluginFilename(IndexToPlugin(index), filename, 64);
			}
		}
		case 4:
		{
			if (successful)
			{
				DeleteFile(dest);
			}
		}
		default:
		{
		}
	}
	g_bDownloading = 0;
	ProcessDownloadQueue(false);
	return 0;
}

MMWS_API_Init()
{
	CreateNative("MMWS_Updater_AddPlugin", MMWS_Native_AddPlugin);
	CreateNative("MMWS_Updater_RemovePlugin", MMWS_Native_RemovePlugin);
	CreateNative("MMWS_Updater_ForceUpdate", MMWS_Native_ForceUpdate);
	mmws_OnPluginChecking = CreateForward(ExecType:2);
	mmws_OnPluginDownloading = CreateForward(ExecType:2);
	mmws_OnPluginUpdating = CreateForward(ExecType:0);
	mmws_OnPluginUpdated = CreateForward(ExecType:0);
	return 0;
}

public MMWS_Native_AddPlugin(Handle:plugin, numParams)
{
	decl String:url[256];
	GetNativeString(1, url, 256, 0);
	MMWS_Updater_AddPlugin(plugin, url);
	return 0;
}

public MMWS_Native_RemovePlugin(Handle:plugin, numParams)
{
	new index = PluginToIndex(plugin);
	if (index != -1)
	{
		MMWS_Updater_QueueRemovePlugin(plugin);
	}
	return 0;
}

public MMWS_Native_ForceUpdate(Handle:plugin, numParams)
{
	new index = PluginToIndex(plugin);
	if (index == -1)
	{
		ThrowNativeError(6, "Plugin not found in updater.");
	}
	else
	{
		if (MMWS_Updater_GetStatus(index))
		{
		}
		else
		{
			MMWS_Updater_Check(index);
			return 1;
		}
	}
	return 0;
}

Action:MMWS_OnPluginChecking(Handle:plugin)
{
	new Action:result;
	new Function:func = GetFunctionByName(plugin, "MMWS_Updater_OnPluginChecking");
	if (func != -1)
	{
		Call_StartForward(mmws_OnPluginChecking);
		Call_Finish(result);
		RemoveAllFromForward(mmws_OnPluginChecking, plugin);
	}
	return result;
}

Action:MMWS_OnPluginDownloading(Handle:plugin)
{
	new Action:result;
	new Function:func = GetFunctionByName(plugin, "MMWS_Updater_OnPluginDownloading");
	if (func != -1)
	{
		Call_StartForward(mmws_OnPluginDownloading);
		Call_Finish(result);
		RemoveAllFromForward(mmws_OnPluginDownloading, plugin);
	}
	return result;
}

MMWS_OnPluginUpdating(Handle:plugin)
{
	new Function:func = GetFunctionByName(plugin, "MMWS_Updater_OnPluginUpdating");
	if (func != -1)
	{
		Call_StartForward(mmws_OnPluginUpdating);
		Call_Finish(0);
		RemoveAllFromForward(mmws_OnPluginUpdating, plugin);
	}
	return 0;
}

MMWS_OnPluginUpdated(Handle:plugin)
{
	new Function:func = GetFunctionByName(plugin, "MMWS_Updater_OnPluginUpdated");
	if (func != -1)
	{
		Call_StartForward(mmws_OnPluginUpdated);
		Call_Finish(0);
		RemoveAllFromForward(mmws_OnPluginUpdated, plugin);
	}
	return 0;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("mmws");
	MarkNativeAsOptional("curl_OpenFile");
	MarkNativeAsOptional("curl_slist");
	MarkNativeAsOptional("curl_slist_append");
	MarkNativeAsOptional("curl_easy_init");
	MarkNativeAsOptional("curl_easy_setopt_int_array");
	MarkNativeAsOptional("curl_easy_setopt_handle");
	MarkNativeAsOptional("curl_easy_setopt_string");
	MarkNativeAsOptional("curl_easy_perform_thread");
	MarkNativeAsOptional("curl_easy_strerror");
	MarkNativeAsOptional("SocketCreate");
	MarkNativeAsOptional("SocketSetArg");
	MarkNativeAsOptional("SocketSetOption");
	MarkNativeAsOptional("SocketConnect");
	MarkNativeAsOptional("SocketSend");
	MarkNativeAsOptional("Steam_CreateHTTPRequest");
	MarkNativeAsOptional("Steam_SetHTTPRequestHeaderValue");
	MarkNativeAsOptional("Steam_SendHTTPRequest");
	MarkNativeAsOptional("Steam_WriteHTTPResponseBody");
	MarkNativeAsOptional("Steam_ReleaseHTTPRequest");
	MarkNativeAsOptional("Steam_RequestGroupStatus");
	MMWS_API_Init();
	RegPluginLibrary("mmws_updater");
	return APLRes:0;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("mmws.phrases");
	if (!GetFeatureStatus(FeatureType:0, "curl_easy_init") == 0)
	{
		SetFailState("This plugin requires either the cURL, Socket, or SteamTools extension to function.");
	}
	g_hPluginPacks = CreateArray(1, 0);
	g_hDownloadQueue = CreateArray(1, 0);
	g_hRemoveQueue = CreateArray(1, 0);
	BuildPath(PathType:0, g_sDataPath, 256, "data/mmws.txt");
	MMWS_Updater_AddPlugin(GetMyHandle(), "http://buy.mixwars.eu/pl_update/mmws/update.txt");
	CreateTimer(600, Timer_CheckUpdates, any:0, 1);
	mmws_on_lo3 = CreateGlobalForward("OnLiveOn3", ExecType:0);
	mmws_on_half_time = CreateGlobalForward("OnHalfTime", ExecType:0);
	mmws_on_reset_half = CreateGlobalForward("OnResetHalf", ExecType:0);
	mmws_on_reset_match = CreateGlobalForward("OnResetMatch", ExecType:0);
	mmws_on_end_match = CreateGlobalForward("OnEndMatch", ExecType:0);
	RegConsoleCmd("score", ConsoleScore, "", 0);
	RegConsoleCmd("say", SayChat, "", 0);
	RegConsoleCmd("say_team", SayTeamChat, "", 0);
	RegConsoleCmd("buy", RestrictBuy, "", 0);
	RegConsoleCmd("jointeam", ChooseTeam, "", 0);
	RegConsoleCmd("spectate", ChooseTeam, "", 0);
	RegConsoleCmd("wm_cash", AskTeamMoney, "", 0);
	RegConsoleCmd("admins", AdminsList, "", 0);
	RegConsoleCmd("sub", ReplacePlayer, "", 0);
	RegConsoleCmd("replace", ReplacePlayer, "", 0);
	RegAdminCmd("spec", SpecAll, 32768, "Swap all players to the spectator", "", 0);
	RegAdminCmd("changelevel", ChangeLevel, 32768, "Swap all players to the spectator", "", 0);
	RegAdminCmd("viewprofile", SteamID, 32768, "View Steam Profile", "", 0);
	RegAdminCmd("vp", SteamID, 32768, "View Steam Profile", "", 0);
	RegAdminCmd("searchprofile", SteamIDGoogle, 32768, "View Steam Profile", "", 0);
	RegAdminCmd("sp", SteamIDGoogle, 32768, "View Steam Profile", "", 0);
	RegConsoleCmd("top", Stats, "", 0);
	RegConsoleCmd("rank", Rank, "", 0);
	RegConsoleCmd("help", Help, "", 0);
	RegConsoleCmd("info", Info, "", 0);
	RegAdminCmd("knife", KnifeOn3, 32768, "Remove all weapons except knife and lo3", "", 0);
	RegAdminCmd("ko3", KnifeOn3, 32768, "Remove all weapons except knife and lo3", "", 0);
	RegAdminCmd("cancelknife", CancelKnife, 32768, "Declares knife not live and restarts round", "", 0);
	RegAdminCmd("ck", CancelKnife, 32768, "Declares knife not live and restarts round", "", 0);
	RegAdminCmd("reboot", RestartMW, 32768, "Restarting MW System", "", 0);
	RegAdminCmd("resetmix", ResetMix, 32768, "Reseting Live", "", 0);
	RegAdminCmd("changemode", Status, 32768, "Server Mode", "", 0);
	RegAdminCmd("cm", Status, 32768, "Server Mode", "", 0);
	RegAdminCmd("pw", ChangePassword, 32768, "Change Password", "", 0);
	RegAdminCmd("password", ChangePassword, 32768, "Change Password", "", 0);
	RegAdminCmd("unban", UnBan, 16384, "Unban Players", "", 0);
	RegAdminCmd("recordstart", RS, 32768, "SourceTV record", "", 0);
	RegAdminCmd("rs", RS, 32768, "SourceTV record", "", 0);
	RegAdminCmd("recordend", RE, 32768, "SourceTV stoping record", "", 0);
	RegAdminCmd("re", RE, 32768, "SourceTV stoping record", "", 0);
	RegAdminCmd("lo3", ForceStart, 32768, "Starts the match regardless of player and ready count", "", 0);
	RegAdminCmd("forcestart", ForceStart, 32768, "Starts the match regardless of player and ready count", "", 0);
	RegAdminCmd("fs", ForceStart, 32768, "Starts the match regardless of player and ready count", "", 0);
	RegAdminCmd("forceend", ForceEnd, 32768, "Ends the match regardless of status", "", 0);
	RegAdminCmd("fe", ForceEnd, 32768, "Ends the match regardless of status", "", 0);
	mmws_stats_enabled = CreateConVar("mmws_stats_enabled", "1", "[BASE] Enable or disable statistical logging", 256, false, 0, false, 0);
	mmws_rcon_only = CreateConVar("mmws_rcon_only", "0", "[BASE] Enable or disable admin commands to be only executed via RCON or console", 0, false, 0, false, 0);
	mmws_global_chat = CreateConVar("mmws_global_chat", "1", "[BASE] Enable or disable the global chat command (@ prefix in messagemode)", 0, false, 0, false, 0);
	mmws_locked = CreateConVar("mmws_lock_teams", "1", "[BASE] Enable or disable locked teams when a match is running", 256, false, 0, false, 0);
	mmws_min_ready = CreateConVar("mmws_min_ready", "10", "[BASE] Sets the minimum required ready players to Live on 3", 256, false, 0, false, 0);
	mmws_max_players = CreateConVar("mmws_max_players", "10", "[BASE] Sets the maximum players allowed on both teams combined, others will be forced to spectator (0 = unlimited)", 256, true, 0, false, 0);
	mmws_match_config = CreateConVar("mmws_match_config", "mmw_system/mr15.cfg", "[BASE] Sets the match config to load on Live on 3", 0, false, 0, false, 0);
	mmws_live_config = CreateConVar("mmws_live_config", "mmw_system/lo3.cfg", "[BASE] Sets the Live on 3 config", 0, false, 0, false, 0);
	mmws_end_config = CreateConVar("mmws_reset_config", "mmw_system/end.cfg", "[BASE] Sets the config to load at the end/reset of a match", 0, false, 0, false, 0);
	mmws_round_money = CreateConVar("mmws_round_money", "1", "[BASE] Enable or disable a client's team mates money to be displayed at the start of a round (to him only)", 256, false, 0, false, 0);
	mmws_night_vision = CreateConVar("mmws_block_nightvision", "1", "[BASE] Enable or disable blocking nightvision", 256, false, 0, false, 0);
	mmws_bomb_frags = CreateConVar("mmws_bomb_frags", "0", "[BASE] Enable or disable a player getting 3 points for their bomb explosion", 256, false, 0, false, 0);
	mmws_defuse_frags = CreateConVar("mmws_defuse_frags", "0", "[BASE] Enable or disable a player getting 3 points for defusing the bomb", 256, false, 0, false, 0);
	mmws_ingame_scores = CreateConVar("mmws_ingame_scores", "1", "[BASE] Enable or disable ingame scores to be showed at the end of each round", 256, false, 0, false, 0);
	mmws_max_rounds = CreateConVar("mmws_max_rounds", "15", "[BASE] Sets maxrounds before auto team switch", 256, false, 0, false, 0);
	mmws_knife_hegrenade = CreateConVar("mmws_knife_hegrenade", "0", "[BASE] Enable or disable giving a player a hegrenade on Knife on 3", 256, false, 0, false, 0);
	mmws_knife_flashbang = CreateConVar("mmws_knife_flashbang", "0", "[BASE] Sets how many flashbangs to give a player on Knife on 3", 256, true, 0, true, 2);
	mmws_knife_smokegrenade = CreateConVar("mmws_knife_smokegrenade", "0", "[BASE] Enable or disable giving a player a smokegrenade on Knife on 3", 256, false, 0, false, 0);
	mmws_auto_ready = CreateConVar("mmws_auto_ready", "1", "[BASE] Enable or disable the ready system being automatically enabled on map change", 256, false, 0, false, 0);
	mmws_auto_swap = CreateConVar("mmws_auto_swap", "1", "[BASE] Enable or disable the automatic swapping of teams at half time", 256, false, 0, false, 0);
	mmws_auto_swap_delay = CreateConVar("mmws_auto_swap_delay", "3", "[BASE] Time to wait before swapping teams at half time", 0, true, 0, false, 0);
	mmws_auto_knife = CreateConVar("mmws_auto_knife", "0", "[BASE] Enable or disable the knife round before going live", 256, false, 0, false, 0);
	mmws_score_mode = CreateConVar("mmws_score_mode", "1", "[BASE] Sets score mode: 1 = Best Of, 2 = First To (based on wm_max_rounds)", 256, false, 0, false, 0);
	mmws_auto_record = CreateConVar("mmws_auto_record", "1", "[BASE] Enable or disable auto SourceTV demo record on Live on 3", 256, false, 0, false, 0);
	mmws_play_out = CreateConVar("mmws_play_out", "0", "[BASE] Enable or disable teams required to play out the match even after a winner has been decided", 256, false, 0, false, 0);
	mmws_remove_hint_text = CreateConVar("mmws_remove_help_hints", "1", "[BASE] Enable or disable the removal of the help hints", 256, false, 0, false, 0);
	mmws_remove_gren_sound = CreateConVar("mmws_remove_grenade_sound", "0", "[BASE] Enable or disable the \"Fire in the Hole\" sound when throwing grenades", 256, false, 0, false, 0);
	mmws_body_remove = CreateConVar("mmws_remove_ragdoll", "1", "[BASE] Enable or disable the removal of ragdolls after wm_remove_ragdoll_delay seconds of time after death", 256, false, 0, false, 0);
	mmws_body_delay = CreateConVar("mmws_remove_ragdoll_delay", "2", "[BASE] The ammount of time to wait before removing corpses", 256, true, 0, false, 0);
	mmws_deathcam_remove = CreateConVar("mmws_remove_deathcam", "1", "[BASE] Enable or disable the switching of views after wm_remove_deathcam_delay seconds of time after death", 256, false, 0, false, 0);
	mmws_deathcam_delay = CreateConVar("mmws_remove_deathcam_delay", "1.4", "[BASE] The ammount of time to wait before switching a players view after death", 256, true, 1.4, false, 0);
	mmws_warmup_respawn = CreateConVar("mmws_warmup_respawn", "0", "[BASE] Enable or disable the respawning of players in warmup", 256, false, 0, false, 0);
	mmws_modifiers = CreateConVar("mmws_modifiers", "1", "[BASE] Enable or disable slight game modifiers (green RCON + short team_say)", 256, false, 0, false, 0);
	mmws_status = CreateConVar("mmws_status", "0", "[BASE] WarMod Extended automatically updates this value to the corresponding match status code", 256, false, 0, false, 0);
	mmws_t = CreateConVar("mmws_t", "Террористы", "[BASE] Team starting terrorists, designed for score and demo naming purposes", 256, false, 0, false, 0);
	mmws_ct = CreateConVar("mmws_ct", "Спецназ", "[BASE] Team starting counter-terrorists, designed for score and demo naming purposes", 256, false, 0, false, 0);
	mmws_mp_startmoney = FindConVar("mp_startmoney");
	g_i_account = FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_i_ragdolls = FindSendPropOffs("CCSPlayer", "m_hRagdoll");
	HookUserMessage(GetUserMessageId("HintText"), MessageHandler, true, MsgPostHook:-1);
	HookUserMessage(GetUserMessageId("SendAudio"), MessageHandler, true, MsgPostHook:-1);
	HookUserMessage(GetUserMessageId("TextMsg"), MessageHandler, true, MsgPostHook:-1);
	HookEvent("round_start", Event_Round_Start, EventHookMode:1);
	HookEvent("round_end", Event_Round_End, EventHookMode:1);
	HookConVarChange(FindConVar("mp_restartgame"), Event_Round_Restart);
	HookEvent("player_death", Event_Player_Death, EventHookMode:1);
	HookEvent("player_connect", Event_Player_Connect, EventHookMode:1);
	HookEvent("player_disconnect", Event_Player_Disc, EventHookMode:1);
	HookEvent("player_team", Event_Player_Team, EventHookMode:1);
	HookEvent("bomb_planted", Event_Bomb_Planted, EventHookMode:1);
	HookEvent("bomb_defused", Event_Bomb_Defused, EventHookMode:1);
	HookEvent("bomb_exploded", Event_Bomb_Exploded, EventHookMode:1);
	BuildPath(PathType:0, logFile, 256, "logs/mmws.log");
	RegisterCvars();
	AutoExecConfig(true, "mmw_system", "sourcemod");
	new i_Pieces[4];
	new i_LongIP;
	h_CvarHostIp = FindConVar("hostip");
	h_CvarPort = FindConVar("hostport");
	i_LongIP = GetConVarInt(h_CvarHostIp);
	i_Pieces[0] = i_LongIP >>> 24 & 255;
	i_Pieces[1] = i_LongIP >>> 16 & 255;
	i_Pieces[2] = i_LongIP >>> 8 & 255;
	i_Pieces[3] = i_LongIP & 255;
	FormatEx(s_ServerIP, 32, "%d.%d.%d.%d", i_Pieces, i_Pieces[1], i_Pieces[2], i_Pieces[3]);
	GetConVarString(h_CvarPort, s_ServerPort, 8);
	GetPluginFilename(GetMyHandle(), s_PluginName, 32);
	decl String:errorbuffer[256];
	KeyValues = CreateKeyValues("Kv", "", "");
	KvSetString(KeyValues, "driver", "sqlite");
	KvSetString(KeyValues, "host", "localhost");
	KvSetString(KeyValues, "database", "mmws");
	KvSetString(KeyValues, "user", "root");
	KvSetString(KeyValues, "pass", "");
	KvSetString(KeyValues, "port", "0");
	mmws_Db = SQL_ConnectCustom(KeyValues, errorbuffer, 255, true);
	CloseHandle(KeyValues);
	if (mmws_Db)
	{
		MMWS_Updater_Log("SQLite DB connected");
		SQL_FastQuery(mmws_Db, sql_DeleteTables, -1);
		SQL_FastQuery(mmws_Db, sql_createTables, -1);
		SQL_UnlockDatabase(mmws_Db);
	}
	else
	{
		MMWS_Updater_Log("SQLite DB not connected");
	}
	statushostname = FindConVar("hostname");
	GetConVarString(statushostname, hostnameupdate, 128);
	return 0;
}

public CheckonComplete(Handle:hndl, CURLcode:code, data)
{
	CloseHandle(SURLcurl);
	SURLcurl = 0;
	return 0;
}

public URLonComplete(Handle:hndl, CURLcode:code, data)
{
	if (code)
	{
		new String:error_buffer[256];
		curl_easy_strerror(code, error_buffer, 256);
		MMWS_Updater_Log("Update FAIL - %s", error_buffer);
	}
	else
	{
		MMWS_Updater_Log("License Updated. Check License...");
		CreateTimer(10, CLicense, any:0, 0);
	}
	CloseHandle(URLcurl);
	URLcurl = 0;
	return 0;
}

public Action:CLicense(Handle:timer, client)
{
	CheckLicense();
	return Action:0;
}

CheckLicense()
{
	if (StrEqual(s_ServerIP, "46.174.49.4", true))
	{
		MMWS_Updater_Log("License accepted. Plugin MMWSystem Full %s activated...", "5.26");
		license = 1;
	}
	else
	{
		decl String:err[256];
		decl String:licquery[256];
		decl String:liccheck[256];
		decl String:licstatus[256];
		decl String:licservers[256];
		decl String:lservers[256];
		new licid;
		new liccol;
		decl String:licip[256];
		decl String:licport[256];
		new Handle:LValues;
		new Handle:mmws_LDb;
		LValues = CreateKeyValues("Kv", "", "");
		KvSetString(LValues, "driver", "mysql");
		KvSetString(LValues, "host", "db2.myarena.ru");
		KvSetString(LValues, "database", "hardrock_gg");
		KvSetString(LValues, "user", "hardrock_gg");
		KvSetString(LValues, "pass", "gg");
		KvSetString(LValues, "port", "3306");
		mmws_LDb = SQL_ConnectCustom(LValues, err, 255, true);
		CloseHandle(LValues);
		if (mmws_LDb)
		{
			FormatEx(licquery, 255, "SELECT `serviceid`, `validdomain`, `validip`, `status`, `validdirectory`, `quantity` FROM mod_licensing WHERE `licensekey` = '%s'", lic);
			new Handle:licresult = SQL_Query(mmws_LDb, licquery, -1);
			if (licresult)
			{
				if (SQL_GetRowCount(licresult) == 1)
				{
					while (SQL_FetchRow(licresult))
					{
						licid = SQL_FetchInt(licresult, 0, 0);
						SQL_FetchString(licresult, 1, licip, 255, 0);
						SQL_FetchString(licresult, 2, licport, 255, 0);
						SQL_FetchString(licresult, 3, licstatus, 255, 0);
						SQL_FetchString(licresult, 4, licservers, 255, 0);
						liccol = SQL_FetchInt(licresult, 5, 0);
					}
				}
				else
				{
					MMWS_Updater_Log("License not valid. Plugin MMWSystem Lite %s activated...", "5.26");
				}
				if (StrContains(lic, "Leased-", true) != -1)
				{
					if (StrEqual(licstatus, "Active", true))
					{
						MMWS_Updater_Log("License accepted. Plugin MMWSystem Full %s activated...", "5.26");
						license = 1;
					}
					else
					{
						if (StrEqual(licstatus, "Reissued", true))
						{
							URLcurl = curl_easy_init();
							Format(liccheck, 255, "http://buy.mixwars.eu/check_license.php?id=%d&lic=%s&ip=%s&port=%s", licid, lic, s_ServerIP, s_ServerPort);
							curl_easy_setopt_string(URLcurl, CURLoption:10002, liccheck);
							curl_easy_perform_thread(URLcurl, URLonComplete, any:0);
						}
						MMWS_Updater_Log("License not valid. Plugin MMWSystem Lite %s activated...", "5.26");
					}
				}
				if (StrContains(lic, "LeaseD-", true) != -1)
				{
					if (StrEqual(licstatus, "Active", true))
					{
						Format(lservers, 255, "%s:%s", s_ServerIP, s_ServerPort);
						if (StrContains(licservers, lservers, true) != -1)
						{
							MMWS_Updater_Log("License accepted. Plugin MMWSystem Full %s activated...", "5.26");
							license = 1;
						}
						else
						{
							if (liccol < 5)
							{
								URLcurl = curl_easy_init();
								Format(liccheck, 255, "http://buy.mixwars.eu/check_license.php?id=%d&lic=%s&ip=%s&port=%s", licid, lic, s_ServerIP, s_ServerPort);
								curl_easy_setopt_string(URLcurl, CURLoption:10002, liccheck);
								curl_easy_perform_thread(URLcurl, URLonComplete, any:0);
							}
						}
					}
					else
					{
						if (StrEqual(licstatus, "Reissued", true))
						{
							URLcurl = curl_easy_init();
							Format(liccheck, 255, "http://buy.mixwars.eu/check_license.php?id=%d&lic=%s&ip=%s&port=%s", licid, lic, s_ServerIP, s_ServerPort);
							curl_easy_setopt_string(URLcurl, CURLoption:10002, liccheck);
							curl_easy_perform_thread(URLcurl, URLonComplete, any:0);
						}
						MMWS_Updater_Log("License not valid. Plugin MMWSystem Lite %s activated...", "5.26");
					}
				}
				if (StrContains(lic, "LeaSeD-", true) != -1)
				{
					if (StrEqual(licstatus, "Active", true))
					{
						Format(lservers, 255, "%s:%s", s_ServerIP, s_ServerPort);
						if (StrContains(licservers, lservers, true) != -1)
						{
							MMWS_Updater_Log("License accepted. Plugin MMWSystem Full %s activated...", "5.26");
							license = 1;
						}
						else
						{
							URLcurl = curl_easy_init();
							Format(liccheck, 255, "http://buy.mixwars.eu/check_license.php?id=%d&lic=%s&ip=%s&port=%s", licid, lic, s_ServerIP, s_ServerPort);
							curl_easy_setopt_string(URLcurl, CURLoption:10002, liccheck);
							curl_easy_perform_thread(URLcurl, URLonComplete, any:0);
						}
					}
					if (StrEqual(licstatus, "Reissued", true))
					{
						URLcurl = curl_easy_init();
						Format(liccheck, 255, "http://buy.mixwars.eu/check_license.php?id=%d&lic=%s&ip=%s&port=%s", licid, lic, s_ServerIP, s_ServerPort);
						curl_easy_setopt_string(URLcurl, CURLoption:10002, liccheck);
						curl_easy_perform_thread(URLcurl, URLonComplete, any:0);
					}
					MMWS_Updater_Log("License not valid. Plugin MMWSystem Lite %s activated...", "5.26");
				}
			}
		}
		MMWS_Updater_Log("License DB not answered. New connect attempt...");
		CreateTimer(15, DBReconnect, any:0, 0);
		return 0;
	}
	decl String:mode[32];
	GetConVarString(mmws_CvarModeDefault, mode, 32);
	if (StrEqual(mode, "match", false))
	{
		cwstatus = 1;
	}
	if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
	{
		MMWS_Updater_Log("Status Template Loaded...");
		ServerCommand("hostname \"%s\"", hostnameupdate);
		Format(hostnamenew, 256, "%s [%s]", hostnameupdate, Status_Wait);
		ServerCommand("hostname \"%s\"", hostnamenew);
		MMWS_Updater_Log("Status Enabled...");
	}
	else
	{
		MMWS_Updater_Log("Status Disabled...");
	}
	if (license)
	{
		ParseAds();
		CreateTimer(GetConVarFloat(mmws_ads_Interval), Timer_DisplayAds, any:0, 3);
	}
	new Handle:topmenu;
	if (LibraryExists("adminmenu"))
	{
		OnAdminMenuReady(topmenu);
	}
	return 0;
}

public OnConfigsExecuted()
{
	GetConVarString(mmws_CvarSBPrefix, prefix, 32);
	GetConVarString(mmws_CvarInfoTitle, infotitle, 64);
	decl String:filename[200];
	BuildPath(PathType:0, filename, 200, "plugins/mmws.smx");
	if (FileExists(filename, false))
	{
		ServerCommand("sm plugins unload mmws");
		DeleteFile(filename);
		MMWS_Updater_Log("mmws.smx was unloaded and deleted");
	}
	BuildPath(PathType:0, filename, 200, "plugins/warmod.smx");
	if (FileExists(filename, false))
	{
		decl String:newfilename[200];
		BuildPath(PathType:0, newfilename, 200, "plugins/disabled/warmod.smx");
		ServerCommand("sm plugins unload warmod");
		if (FileExists(newfilename, false))
		{
			DeleteFile(newfilename);
		}
		RenameFile(newfilename, filename);
		MMWS_Updater_Log("plugins/warmod.smx was unloaded and moved to plugins/disabled/warmod.smx");
	}
	if (GetConVarInt(mmws_CvarBanEnable) == 2)
	{
		SQL_TConnect(GotDatabase, "sourcebans", any:0);
	}
	else
	{
		decl String:errorbuf[256];
		KeyValues = CreateKeyValues("Kv", "", "");
		KvSetString(KeyValues, "driver", "sqlite");
		KvSetString(KeyValues, "host", "localhost");
		KvSetString(KeyValues, "database", "mmws");
		KvSetString(KeyValues, "user", "root");
		KvSetString(KeyValues, "pass", "");
		KvSetString(KeyValues, "port", "0");
		h_Database = SQL_ConnectCustom(KeyValues, errorbuf, 255, true);
		CloseHandle(KeyValues);
		if (h_Database)
		{
			SQL_LockDatabase(h_Database);
			SQL_TQuery(h_Database, ErrorCheckCallback, sql_createTablesBans, any:0, DBPriority:1);
			SQL_UnlockDatabase(h_Database);
		}
		else
		{
			LogError("SQL Connection Failed: %s", errorbuf);
		}
	}
	if (GetConVarInt(mmws_CvarBanEnable) == 1)
	{
		decl String:filenamesb[200];
		BuildPath(PathType:0, filenamesb, 200, "plugins/sourcebans.smx");
		if (FileExists(filenamesb, false))
		{
			decl String:newfilenamesb[200];
			BuildPath(PathType:0, newfilenamesb, 200, "plugins/disabled/sourcebans.smx");
			ServerCommand("sm plugins unload sourcebans");
			if (FileExists(newfilenamesb, false))
			{
				DeleteFile(newfilenamesb);
			}
			RenameFile(newfilenamesb, filenamesb);
			MMWS_Updater_Log("plugins/sourcebans.smx was unloaded and moved to plugins/disabled/sourcebans.smx");
		}
		decl String:filenameb[200];
		BuildPath(PathType:0, filenameb, 200, "plugins/disabled/basebans.smx");
		if (FileExists(filenameb, false))
		{
			decl String:newfilenameb[200];
			BuildPath(PathType:0, newfilenameb, 200, "plugins/basebans.smx");
			if (FileExists(newfilenameb, false))
			{
				DeleteFile(newfilenameb);
			}
			RenameFile(newfilenameb, filenameb);
			ServerCommand("sm plugins load basebans");
			MMWS_Updater_Log("plugins/disabled/basebans.smx was moved to plugins/basebans.smx and loaded");
		}
	}
	if (GetConVarInt(mmws_CvarBanEnable) == 2)
	{
		decl String:filenamesb[200];
		BuildPath(PathType:0, filenamesb, 200, "plugins/disabled/sourcebans.smx");
		if (FileExists(filenamesb, false))
		{
			decl String:newfilenamesb[200];
			BuildPath(PathType:0, newfilenamesb, 200, "plugins/sourcebans.smx");
			ServerCommand("sm plugins unload sourcebans");
			if (FileExists(newfilenamesb, false))
			{
				DeleteFile(newfilenamesb);
			}
			RenameFile(newfilenamesb, filenamesb);
			MMWS_Updater_Log("plugins/disabled/sourcebans.smx was moved to plugins/sourcebans.smx and loaded");
		}
		decl String:filenameb[200];
		BuildPath(PathType:0, filenameb, 200, "plugins/basebans.smx");
		if (FileExists(filenameb, false))
		{
			decl String:newfilenameb[200];
			BuildPath(PathType:0, newfilenameb, 200, "plugins/disabled/basebans.smx");
			if (FileExists(newfilenameb, false))
			{
				DeleteFile(newfilenameb);
			}
			RenameFile(newfilenameb, filenameb);
			ServerCommand("sm plugins load basebans");
			MMWS_Updater_Log("plugins/basebans.smx was unloaded and moved to plugins/disabled/basebans.smx");
		}
	}
	GetConVarString(mmws_CvarSBPrefix, prefix, 32);
	GetConVarString(mmws_CvarStatsHost, hoststats, 64);
	GetConVarString(mmws_CvarStatsDatabase, databasestats, 64);
	GetConVarString(mmws_CvarStatsUser, user, 64);
	GetConVarString(mmws_CvarStatsPassword, pass, 64);
	GetConVarString(mmws_CvarStatsPort, port, 64);
	decl String:errorbuffer[256];
	if (!StrEqual(hoststats, "", true))
	{
		KeyValuesStats = CreateKeyValues("Kv", "", "");
		KvSetString(KeyValuesStats, "driver", "mysql");
		KvSetString(KeyValuesStats, "host", hoststats);
		KvSetString(KeyValuesStats, "database", databasestats);
		KvSetString(KeyValuesStats, "user", user);
		KvSetString(KeyValuesStats, "pass", pass);
		KvSetString(KeyValuesStats, "port", port);
		mmws_DbStats = SQL_ConnectCustom(KeyValuesStats, errorbuffer, 255, true);
		CloseHandle(KeyValuesStats);
		if (mmws_DbStats)
		{
			MMWS_Updater_Log("Stats DB connected");
			decl String:s_Query[1024];
			FormatEx(s_Query, 1024, "SET NAMES \"UTF8\"");
			SQL_TQuery(mmws_DbStats, ErrorCheckCallback, s_Query, any:0, DBPriority:1);
		}
		MMWS_Updater_Log("Stats DB not connected");
	}
	GetConVarString(mmws_ads_prefix, ads_prefix, 128);
	MMWS_Updater_Log("Status Check Begin...");
	GetConVarString(mmws_CvarHostnameStatus_Wait, Status_Wait, 128);
	GetConVarString(mmws_CvarHostnameStatus_HalfWait, Status_HalfWait, 128);
	GetConVarString(mmws_CvarHostnameStatus_Knife, Status_Knife, 128);
	GetConVarString(mmws_CvarHostnameStatus_Select, Status_Select, 128);
	GetConVarString(mmws_CvarHostnameStatus_Check, Status_Check, 128);
	GetConVarString(mmws_CvarHostnameStatus_Live, Status_Live, 128);
	GetConVarString(mmws_CvarHostnameStatus_Live_First, Status_Live_First, 128);
	GetConVarString(mmws_CvarHostnameStatus_Vote, Status_Vote, 128);
	GetConVarString(mmws_CvarDefaultMap, DefaultMap, 128);
	if (!StrEqual(DefaultMap, "", false))
	{
		Format(DefaultMap, 128, "changelevel %s", DefaultMap);
		CreateTimer(300, ChangeMap, any:0, 0);
	}
	if (mmws_Db)
	{
		SQL_LockDatabase(mmws_Db);
		SQL_TQuery(mmws_Db, ErrorCheckCallback, sql_ClearTables, any:0, DBPriority:1);
		SQL_UnlockDatabase(mmws_Db);
	}
	GetConVarString(mmws_CvarLicense, lic, 255);
	if (GetFeatureStatus(FeatureType:0, "curl_easy_init"))
	{
		MMWS_Updater_Log("Curl Extention not found. Plugin MMWSystem %s disabled...", "5.26");
		ServerCommand("sm plugins unload %s", s_PluginName);
	}
	else
	{
		if (StrEqual(s_ServerIP, "62.152.34.94", true))
		{
			CheckLicense();
		}
		else
		{
			MMWS_Updater_Log("License not valid. Plugin MMWSystem Lite %s activated...", "5.26");
		}
	}
	CreateTimer(60, Scheck, any:0, 0);
	return 0;
}

public Action:Scheck(Handle:timer, client)
{
	decl String:scheck[256];
	SURLcurl = curl_easy_init();
	if (license)
	{
		Format(scheck, 255, "http://buy.mixwars.eu/check_server.php?ip=%s&port=%s&zone=2&version=%s", s_ServerIP, s_ServerPort, "5.26");
	}
	else
	{
		if (license)
		{
			Format(scheck, 255, "http://buy.mixwars.eu/check_server.php?ip=%s&port=%s&zone=1&version=%s", s_ServerIP, s_ServerPort, "5.26");
		}
		Format(scheck, 255, "http://buy.mixwars.eu/check_server.php?ip=%s&port=%s&zone=0&version=%s", s_ServerIP, s_ServerPort, "5.26");
	}
	curl_easy_setopt_string(SURLcurl, CURLoption:10002, scheck);
	curl_easy_perform_thread(SURLcurl, CheckonComplete, any:0);
	return Action:0;
}

public Action:DBReconnect(Handle:timer, client)
{
	ServerCommand("sm plugins reload %s", s_PluginName);
	return Action:0;
}

RegisterCvars()
{
	mmws_CvarLicense = CreateConVar("mmws_license", "", "[EXT] Вводится действительный ключ лицензии для активации полной версии системы", 256, false, 0, false, 0);
	mmws_CvarBanEnable = CreateConVar("mmws_ban_enable", "0", "[EXT] Система банов (0 - Отключена, 1 - Использование локальной базы SQLite, 2 - Использование SourceBans)", 256, false, 0, false, 0);
	mmws_CvarBanServerID = CreateConVar("mmws_serverid", "1", "[EXT] Номер сервера в системе SourceBans (при использовании локальной базы SQLite устанавить значение 1, при использовании SourceBans установить номер сервера в системе или -1 для автоматического определения)", 256, false, 0, false, 0);
	mmws_CvarBanTime = CreateConVar("mmws_ban_time", "180", "[EXT] Время банов I уровня", 256, false, 0, false, 0);
	mmws_CvarBanCountExtend = CreateConVar("mmws_ban_count", "3", "[EXT] Количество банов до уровня II", 256, false, 0, false, 0);
	mmws_CvarBanCountExtend2 = CreateConVar("mmws_ban_count2", "5", "[EXT] Количество банов до уровня III", 256, false, 0, false, 0);
	mmws_CvarBanCountExtend3 = CreateConVar("mmws_ban_count3", "10", "[EXT] Количество банов до уровня IV", 256, false, 0, false, 0);
	mmws_CvarBanCountExtend4 = CreateConVar("mmws_ban_count4", "20", "[EXT] Количество банов до уровня V", 256, false, 0, false, 0);
	mmws_CvarBanTimeExtend = CreateConVar("mmws_ban_time_extend", "720", "[EXT] Время банов II уровня", 256, false, 0, false, 0);
	mmws_CvarBanTimeExtend2 = CreateConVar("mmws_ban_time_extend2", "1440", "[EXT] Время банов III уровня", 256, false, 0, false, 0);
	mmws_CvarBanTimeExtend3 = CreateConVar("mmws_ban_time_extend3", "4320", "[EXT] Время банов IV уровня", 256, false, 0, false, 0);
	mmws_CvarBanTimeExtend4 = CreateConVar("mmws_ban_time_extend4", "10080", "[EXT] Время банов V уровня", 256, false, 0, false, 0);
	mmws_CvarBanAddDelay = CreateConVar("mmws_ban_delay", "120.0", "[EXT] Время до добавления бана в базу (секунды)", 256, true, 0.1, false, 0);
	mmws_CvarBanAllReason = CreateConVar("mmws_ban_reason", "0", "[EXT] Причины, по коротым будет банить вышедших (0 - только за самовольное отключение, 1 - отключение по любой причине)", 256, false, 0, false, 0);
	mmws_CvarBanImmunity = CreateConVar("mmws_ban_immuno", "3", "[EXT] Иммунитет (0 - Отключен, 1 - Только админы, 2 - Только наблюдатели, 3 - Админы и наблюдатели)", 256, false, 0, false, 0);
	mmws_CvarBanAutoForceStart = CreateConVar("mmws_halftime_autostart", "2", "[EXT] Автопродолжение миска после смены сторон (0 - Отключено, 1 - Включено, 2 - Включено, но ждет полных составов)", 256, false, 0, false, 0);
	mmws_CvarBanAutoFSdelay = CreateConVar("mmws_halftime_autostart_delay", "2.0", "[EXT] Время до автозапуска микса после смены сторон (секунды)", 256, true, 0.1, false, 0);
	mmws_CvarBanVoteStart = CreateConVar("mmws_vote_endmap", "1", "[EXT] Голосование за следующую карту после окончания микса (0 - Отключено, 1 - Включено)", 256, false, 0, false, 0);
	mmws_CvarBanVoteMessage = CreateConVar("mmws_vote_message", "1", "[EXT] Сообщение о начале голосования за следующую карту (0 - Отключено, 1 - Включено)", 256, false, 0, false, 0);
	mmws_CvarBanTextOption = CreateConVar("mmws_ban_text_format", "1", "[EXT] Сообщение о выданном бане (1 - Показать Никнейм, 2 - Показать SteamID, 3 - Показать Никнейм и SteamID)", 256, false, 0, false, 0);
	mmws_CvarBanText = CreateConVar("mmws_ban_text", "1", "[EXT] Сообщение о выданном бане (0 - Отключено, 1 - Включено)", 256, false, 0, false, 0);
	mmws_CvarAStop_Delay = CreateConVar("mmws_live_astop_delay", "180.0", "[EXT] Время до остановки микса при недостаточном количестве игроков (секунды)", 256, true, 0.1, false, 0);
	mmws_CvarAcceptReplace = CreateConVar("mmws_accept_replace", "1", "[EXT] Замены во время микса (позволяет игрокам менять друг друга и не получать бан за выход, если на сервере достаточно игроков)", 256, false, 0, false, 0);
	mmws_CvarSBPrefix = CreateConVar("mmws_sb_prefix", "sb_", "[EXT] Префикс базы банов SourceBans", 256, false, 0, false, 0);
	mmws_CvarAutoForceStart = CreateConVar("mmws_match_autostart", "1", "[EXT] Автостарт микса после укопмлектования сторон (0 - Отключено, 1 - Включено)", 256, false, 0, false, 0);
	mmws_CvarAutoStartDelay = CreateConVar("mmws_match_autostart_delay", "36", "[EXT] Время до автоматического запуска микса (секунды)", 256, false, 0, false, 0);
	mmws_CvarAutoForceKnife = CreateConVar("mmws_match_autoknife", "1", "[EXT] Ожидание игроков для ножевого раунда (0 - Отключено, 1 - Включено)", 256, false, 0, false, 0);
	mmws_CvarWaitSelectTeam = CreateConVar("mmws_wait_select_team", "1", "[EXT] Ожидание подключения игроков (0 - Отключено, 1 - Включено)", 256, false, 0, false, 0);
	mmws_CvarInfoTitle = CreateConVar("mmws_info", "MMWSystem", "[EXT] Префикс информационных сообщений в чате", 256, false, 0, false, 0);
	mmws_CvarMenuSelectPlayers = CreateConVar("mmws_enable_menu_player", "0", "[EXT] Меню выбора игроков после ножевого раунда (0 - Отключено, 1 - Включено)", 256, false, 0, false, 0);
	mmws_CvarHostnameStatus = CreateConVar("mmws_hostname_status", "1", "[EXT] Отображение статуса в названии сервера (0 - Отключено, 1 - Включено)", 256, false, 0, false, 0);
	mmws_CvarHostnameStatus_Wait = CreateConVar("mmws_hostname_message_wait", "Waiting players...", "[EXT] Сообщение 'Ожидание подключения игроков' в названии сервера", 256, false, 0, false, 0);
	mmws_CvarHostnameStatus_HalfWait = CreateConVar("mmws_hostname_message_half_wait", "HalfTime. Waiting players...", "[EXT] Сообщение 'Ожидание игроков для начала второй половины' в названии сервера", 256, false, 0, false, 0);
	mmws_CvarHostnameStatus_Knife = CreateConVar("mmws_hostname_message_knife", "Knife Round...", "[EXT] Сообщение 'Проведение ножевого раунда' в названии сервера", 256, false, 0, false, 0);
	mmws_CvarHostnameStatus_Select = CreateConVar("mmws_hostname_message_select", "Select players...", "[EXT] Сообщение 'Выбор игроков' в названии сервера", 256, false, 0, false, 0);
	mmws_CvarHostnameStatus_Check = CreateConVar("mmws_hostname_message_check", "Check players...", "[EXT] Сообщение 'Проверка AFK игроков' в названии сервера", 256, false, 0, false, 0);
	mmws_CvarHostnameStatus_Live = CreateConVar("mmws_hostname_message_live", "LIVE", "[EXT] Сообщение 'Микс идет' в названии сервера (если mmws_hostname_message_live_type равно 0 или 1)", 256, false, 0, false, 0);
	mmws_CvarHostnameStatus_LiveType = CreateConVar("mmws_hostname_message_live_type", "0", "[EXT] Вид сообщения в названии сервера (0 - [LIVE] CT[5]-[5]T, 1 - [LIVE] [5-5], 2 - [5-5])", 256, false, 0, false, 0);
	mmws_CvarHostnameStatus_Live_First = CreateConVar("mmws_hostname_message_first_round", "First round...", "[EXT] Сообщение 'Микс начался' в названии сервера (если mmws_hostname_message_live_type равно 0 или 1)", 256, false, 0, false, 0);
	mmws_CvarHostnameStatus_Vote = CreateConVar("mmws_hostname_message_vote", "GG. Map Voting...", "[EXT] Сообщение 'Микс завершен. Голосование за карту' в названии сервера", 256, false, 0, false, 0);
	mmws_CvarModeDefault = CreateConVar("mmws_mode_default", "mix", "[EXT] Установка режима работы сервера по умолчанию(mix - режим MixWars, match - режим ClanWars)", 256, false, 0, false, 0);
	mmws_CvarMixOnly = CreateConVar("mmws_mix_only", "0", "[EXT] Изменение режима работы сервера (0 - Разрешено, 1 - Запрещено)", 256, false, 0, false, 0);
	mmws_CvarDefaultMap = CreateConVar("mmws_default_map_timer", "", "[EXT] Установка карты по умолчанию (Смена карты происходит через 5 минут при пустом сервере)", 256, false, 0, false, 0);
	mmws_CvarSteamGroupAccess = CreateConVar("mmws_steamgroup_only", "0", "[EXT] Доступ на сервер только игроков, состоящих в Steam-группе (0 - Разрешен всем, 1 - Только участники группы)", 256, false, 0, false, 0);
	mmws_CvarSteamGroupAdminAccess = CreateConVar("mmws_steamgroup_admin_only", "0", "[EXT] Limit Connect Admin SteamGroup (0 - Anyone)", 256, false, 0, false, 0);
	mmws_CvarSteamGroup = CreateConVar("mmws_steamgroup", "0", "[EXT] ID-номер Steam-группы сервера (номер указан на странице администрирования группы)", 256, false, 0, false, 0);
	mmws_CvarSteamGroupAdmin = CreateConVar("mmws_steamgroup_admin", "0", "[EXT] ID-номер Steam-группы администраторов сервера (номер указан на странице администрирования группы)", 256, false, 0, false, 0);
	mmws_CvarStatsUrl = CreateConVar("mmws_help_url", "", "[EXT] Адрес страницы помощи (вводится без http://)", 256, false, 0, false, 0);
	mmws_CvarStatsUrl = CreateConVar("mmws_stats_url", "", "[EXT] Адрес сайта статистики HLStatsX (вводится без http://)", 256, false, 0, false, 0);
	mmws_CvarStatsHost = CreateConVar("mmws_stats_host", "", "[EXT] Хост БД статистики (Пусто - Отключено)", 256, false, 0, false, 0);
	mmws_CvarStatsDatabase = CreateConVar("mmws_stats_database", "hlstatsx", "[EXT] Название БД статистики", 256, false, 0, false, 0);
	mmws_CvarStatsUser = CreateConVar("mmws_stats_user", "user", "[EXT] Пользователь БД статистики", 256, false, 0, false, 0);
	mmws_CvarStatsPassword = CreateConVar("mmws_stats_password", "password", "[EXT] Пароль БД статистики", 256, false, 0, false, 0);
	mmws_CvarStatsPort = CreateConVar("mmws_stats_port", "3306", "[EXT] Порт БД статистики", 256, false, 0, false, 0);
	mmws_CvarRestrictak47 = CreateConVar("mmws_restrict_ak47", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictaug = CreateConVar("mmws_restrict_aug", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictawp = CreateConVar("mmws_restrict_awp", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictdeagle = CreateConVar("mmws_restrict_deagle", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictelite = CreateConVar("mmws_restrict_elite", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictfamas = CreateConVar("mmws_restrict_famas", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictfiveseven = CreateConVar("mmws_restrict_fiveseven", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictg3sg1 = CreateConVar("mmws_restrict_g3sg1", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictgalil = CreateConVar("mmws_restrict_galil", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictglock = CreateConVar("mmws_restrict_glock", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictm249 = CreateConVar("mmws_restrict_m249", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictm3 = CreateConVar("mmws_restrict_m3", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictm4a1 = CreateConVar("mmws_restrict_m4a1", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictmac10 = CreateConVar("mmws_restrict_mac10", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictmp5navy = CreateConVar("mmws_restrict_mp5navy", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictp228 = CreateConVar("mmws_restrict_p228", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictp90 = CreateConVar("mmws_restrict_p90", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictscout = CreateConVar("mmws_restrict_scout", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictsg550 = CreateConVar("mmws_restrict_sg550", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictsg552 = CreateConVar("mmws_restrict_sg552", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestricttmp = CreateConVar("mmws_restrict_tmp", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictump45 = CreateConVar("mmws_restrict_ump45", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictusp = CreateConVar("mmws_restrict_usp", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_CvarRestrictxm1014 = CreateConVar("mmws_restrict_xm1014", "-1", "[EXT] Запрет оружия (-1 - Разрешено, 0 - Запрещено на вармапе, 1 -Запрещено всегда)", 256, false, 0, false, 0);
	mmws_ads_prefix = CreateConVar("mmws_ads_prefix", "Adverts", "[EXT] Префикс рекламных сообщений (Если значение пустое, то префикс не показывается)", 256, false, 0, false, 0);
	mmws_ads_Enabled = CreateConVar("mmws_ads_enabled", "0", "[EXT] Показ рекламных сообщений (1 - Включено, 0 - Отключено)", 256, false, 0, false, 0);
	mmws_ads_Interval = CreateConVar("mmws_ads_interval", "30", "[EXT] Интервал показа рекламных сообщений", 256, false, 0, false, 0);
	mmws_CvarDemoFolder = CreateConVar("mmws_demo_folder", "", "[EXT] Установка названия пользовательской директории для сохранения демок и логов (директория должна быть создана заранее)", 256, false, 0, false, 0);
	return 0;
}

public GotDatabase(Handle:owner, Handle:hndl, String:error[], data)
{
	if (hndl)
	{
		h_Database = hndl;
		decl String:s_Query[1024];
		FormatEx(s_Query, 1024, "SET NAMES \"UTF8\"");
		SQL_TQuery(h_Database, ErrorCheckCallback, s_Query, any:0, DBPriority:1);
		return 0;
	}
	MMWS_Updater_Log("Database failure: %s", error);
	return 0;
}

public ErrorCheckCallback(Handle:owner, Handle:hndle, String:error[], data)
{
	if (error[0])
	{
		MMWS_Updater_Log("Query Failed: %s", error);
	}
	return 0;
}

public Action:RestartMW(client, args)
{
	if (!g_match)
	{
		if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
		{
			ServerCommand("hostname \"%s\"", hostnameupdate);
		}
		GetPluginFilename(GetMyHandle(), s_PluginName, 32);
		ServerCommand("sm plugins reload %s", s_PluginName);
		if (Timers)
		{
			KillTimer(Timers, false);
			Timers = 0;
		}
		if (TimersKnife)
		{
			KillTimer(TimersKnife, false);
			TimersKnife = 0;
		}
		afknife = 0;
		knifeenable = 0;
		knife = 0;
		afknifego = 0;
		afstart = 0;
		astop = 0;
		if (GetConVarInt(mmws_CvarAutoForceKnife) == 1)
		{
			afknife = 1;
			knifeenable = 1;
			afstart = 0;
			knife = 1;
			TimersKnife = CreateTimer(0.2, AutoForceKnife, any:0, 1);
		}
		if (GetConVarInt(mmws_CvarAutoForceStart) == 1)
		{
			Timers = CreateTimer(1, AutoForceStart, any:0, 1);
			if (!(GetConVarInt(mmws_CvarAutoForceKnife)))
			{
				afstart = 1;
			}
			autofsdelay = GetConVarInt(mmws_CvarAutoStartDelay);
		}
		CPrintToChatAll("{lightgreen}*%s* Info: {aliceblue}%t", infotitle, "System Reset");
	}
	return Action:0;
}

public Action:ResetMix(client, args)
{
	if (g_match)
	{
		if (var4[0][0][var4][g_scores[1][0]] < 3)
		{
			ServerCommand("forceend");
			afstart = 1;
			afknife = 0;
			autofsdelay = GetConVarInt(mmws_CvarAutoStartDelay);
			CPrintToChatAll("{lightgreen}*%s* Info: {aliceblue}%t {lightgreen}%s.", infotitle, "Mix Stopped", client);
			CPrintToChatAll("{lightgreen}*%s* Info: {aliceblue}%t", infotitle, "Set Teams");
		}
		else
		{
			CPrintToChat(client, "{lightgreen}*%s* Info: {aliceblue}%t {lightgreen}%t.", infotitle, "Set Teams Denied", "Set Teams Denied 1");
		}
		if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
		{
			ServerCommand("hostname \"%s\"", hostnameupdate);
			Format(hostnamenew, 256, "%s [%s]", hostnameupdate, Status_Select);
			ServerCommand("hostname \"%s\"", hostnamenew);
		}
	}
	return Action:0;
}

public Action:Timer_CheckUpdates(Handle:timer)
{
	MMWS_Updater_FreeMemory();
	new maxPlugins = GetMaxPlugins();
	new i;
	while (i < maxPlugins)
	{
		if (MMWS_Updater_GetStatus(i))
		{
			i++;
		}
		else
		{
			MMWS_Updater_Check(i);
			i++;
		}
		i++;
	}
	return Action:0;
}

public MMWS_Updater_OnPluginUpdated()
{
	MMWS_Updater_Log("Reloading Updater plugin on End Map... updates will resume automatically.");
	return 0;
}

MMWS_Updater_Check(index)
{
	if (!(MMWS_OnPluginChecking(IndexToPlugin(index))))
	{
		decl String:url[256];
		MMWS_Updater_GetURL(index, url, 256);
		MMWS_Updater_SetStatus(index, MMWS_UpdateStatus:1);
		AddToDownloadQueue(index, url, g_sDataPath);
	}
	return 0;
}

MMWS_Updater_FreeMemory()
{
	if (g_bDownloading)
	{
		return 0;
	}
	new index;
	new maxPlugins = GetArraySize(g_hRemoveQueue);
	new i;
	while (i < maxPlugins)
	{
		index = PluginToIndex(GetArrayCell(g_hRemoveQueue, i, 0, false));
		if (index != -1)
		{
			MMWS_Updater_RemovePlugin(index);
			i++;
		}
		i++;
	}
	ClearArray(g_hRemoveQueue);
	new i;
	while (GetMaxPlugins() > i)
	{
		if (!IsValidPlugin(IndexToPlugin(i)))
		{
			MMWS_Updater_RemovePlugin(i);
			i--;
			i++;
		}
		i++;
	}
	return 0;
}

MMWS_Updater_Log(String:format[])
{
	decl String:buffer[256];
	decl String:path[256];
	VFormat(buffer, 256, format, 2);
	BuildPath(PathType:0, path, 256, "logs/mmws.log");
	LogToFileEx(path, "%s", buffer);
	return 0;
}

public OnMapStart()
{
	if (mmws_RestartPlugin)
	{
		GetPluginFilename(GetMyHandle(), s_PluginName, 32);
		ServerCommand("sm plugins reload %s", s_PluginName);
	}
	if (Timers)
	{
		KillTimer(Timers, false);
		Timers = 0;
	}
	if (TimersKnife)
	{
		KillTimer(TimersKnife, false);
		TimersKnife = 0;
	}
	CreateTimer(10, Timer_CheckUpdates, any:0, 0);
	afknife = 0;
	knifeenable = 0;
	knife = 0;
	afknifego = 0;
	afstart = 0;
	astop = 0;
	if (!cwstatus)
	{
		if (GetConVarInt(mmws_CvarAutoForceKnife) == 1)
		{
			afknife = 1;
			knifeenable = 1;
			knife = 1;
			TimersKnife = CreateTimer(0.2, AutoForceKnife, any:0, 1);
		}
		if (GetConVarInt(mmws_CvarAutoForceStart) == 1)
		{
			if (!(GetConVarInt(mmws_CvarAutoForceKnife)))
			{
				afstart = 1;
			}
			Timers = CreateTimer(1, AutoForceStart, any:0, 1);
			autofsdelay = GetConVarInt(mmws_CvarAutoStartDelay);
		}
	}
	GetCurrentMap(g_map, 64);
	StringToLower(g_map, 64);
	if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
	{
		ServerCommand("hostname \"%s\"", hostnameupdate);
		Format(hostnamenew, 256, "%s [%s]", hostnameupdate, Status_Wait);
		ServerCommand("hostname \"%s\"", hostnamenew);
	}
	ResetMatch(true);
	ResetSwitchCameraTimers(false);
	return 0;
}

public motdQuery(QueryCookie:cookie, client, ConVarQueryResult:result, String:cvarName[], String:cvarValue[])
{
	if (result)
	{
		g_bPlyrCanDoMotd[client] = 1;
	}
	return 0;
}

public OnMapEnd()
{
	ResetSwitchCameraTimers(false);
	if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
	{
		ServerCommand("hostname \"%s\"", hostnameupdate);
	}
	return 0;
}

public OnLibraryRemoved(String:name[])
{
	if (StrEqual(name, "adminmenu", true))
	{
		mmws_menu = 0;
	}
	return 0;
}

public MMWSHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	new String:menu_name[256];
	GetTopMenuObjName(topmenu, object_id, menu_name, 256);
	SetGlobalTransTarget(param);
	if (StrEqual(menu_name, "MMWSCommands", true))
	{
		if (action == TopMenuAction:1)
		{
			Format(buffer, maxlength, "Управление системой MMWS");
		}
		else
		{
			if (action)
			{
			}
			else
			{
				Format(buffer, maxlength, "Управление системой MMWS");
			}
		}
	}
	else
	{
		if (StrEqual(menu_name, "forcestart", true))
		{
			if (action)
			{
				Format(buffer, maxlength, "Запустить матч");
			}
			else
			{
				if (action)
				{
					Format(buffer, maxlength, "Запустить микс");
				}
				if (action == TopMenuAction:2)
				{
					ForceStart(param, 0);
				}
			}
		}
		if (StrEqual(menu_name, "knife", true))
		{
			if (action)
			{
				if (action == TopMenuAction:2)
				{
					KnifeOn3(param, 0);
				}
			}
			else
			{
				Format(buffer, maxlength, "Ножевой раунд");
			}
		}
		if (StrEqual(menu_name, "forceend", true))
		{
			if (action)
			{
				Format(buffer, maxlength, "Остановить матч");
			}
			else
			{
				if (action)
				{
					Format(buffer, maxlength, "Остановить микс");
				}
				if (action == TopMenuAction:2)
				{
					ForceEnd(param, 0);
				}
			}
		}
		if (StrEqual(menu_name, "changemode", true))
		{
			if (action)
			{
				if (action == TopMenuAction:2)
				{
					Status(param, 0);
				}
			}
			else
			{
				Format(buffer, maxlength, "Переключить в MixWars режим");
			}
		}
		if (StrEqual(menu_name, "changemode", true))
		{
			if (action)
			{
				if (action == TopMenuAction:2)
				{
					Status(param, 0);
				}
			}
			Format(buffer, maxlength, "Переключить в ClanWars режим");
		}
	}
	return 0;
}

public Steam_GroupStatusResult(client, groupAccountID, bool:groupMember, bool:groupOfficer)
{
	new String:Name[1024];
	new String:query[1024];
	new String:AuthID[36];
	new SteamGroupAdmin = GetConVarInt(mmws_CvarSteamGroupAdmin);
	new SteamGroup = GetConVarInt(mmws_CvarSteamGroup);
	GetClientAuthString(client, AuthID, 34);
	GetClientName(client, Name, 1024);
	if (GetConVarInt(mmws_CvarBanEnable) == 2)
	{
		FormatEx(query, 1024, "SELECT * FROM %sbans WHERE `authid` = '%s'", prefix, AuthID);
	}
	else
	{
		if (GetConVarInt(mmws_CvarBanEnable) == 1)
		{
			FormatEx(query, 1024, "SELECT * FROM bans WHERE `authid` = '%s'", AuthID);
		}
	}
	if (groupAccountID > 0)
	{
		if (groupOfficer)
		{
			new i = 1;
			while (i <= MaxClients)
			{
				if (IsClientInGame(i))
				{
					CPrintToChat(i, "{dimgray}*%s* Info: {lime}%s {aliceblue}%t.", infotitle, Name, "MixMaster");
					i++;
				}
				i++;
			}
		}
		if (groupMember)
		{
			if (admin > 0)
			{
				ServerCommand("sm_kick #%d На сервере есть админ.", GetClientUserId(client));
			}
			if (0 < GetConVarInt(mmws_CvarSteamGroupAdminAccess))
			{
				admin = client;
			}
			new i = 1;
			while (i <= MaxClients)
			{
				if (IsClientInGame(i))
				{
					CPrintToChat(i, "{dimgray}*%s* Info: {lime}%s {aliceblue}%t.", infotitle, Name, "MixAmateur");
					i++;
				}
				i++;
			}
		}
	}
	if (groupAccountID > 0)
	{
		if (groupOfficer)
		{
			steamstatus[client] = 1;
			LogToFile(logFile, "*%s* Info: %s [%s] %t.", infotitle, Name, AuthID, "MixMaster");
			new i = 1;
			while (i <= MaxClients)
			{
				if (IsClientInGame(i))
				{
					CPrintToChat(i, "{dimgray}*%s* Info: {lime}%s {aliceblue}%t.", infotitle, Name, "MixMaster");
					i++;
				}
				i++;
			}
		}
		if (groupMember)
		{
			steamstatus[client] = 1;
			LogToFile(logFile, "*%s* Info: %s [%s] %t.", infotitle, Name, AuthID, "SteamMember");
			new i = 1;
			while (i <= MaxClients)
			{
				if (IsClientInGame(i))
				{
					CPrintToChat(i, "{dimgray}*%s* Info: {lime}%s {aliceblue}%t.", infotitle, Name, "SteamMember");
					i++;
				}
				i++;
			}
		}
		steamstatus[client] = 0;
		LogToFile(logFile, "*%s* Info: %s [%s] %t.", infotitle, Name, AuthID, "NotSteamMember");
		if (GetConVarInt(mmws_CvarSteamGroupAccess) == 1)
		{
			ServerCommand("sm_kick #%d %t", GetClientUserId(client), "KickNotSteamMember");
		}
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				CPrintToChat(i, "{dimgray}*%s* Info: {lime}%s {aliceblue}%t.", infotitle, Name, "NotSteamMember");
				i++;
			}
			i++;
		}
	}
	return 0;
}

/* ERROR! Index was outside the bounds of the array. */
 function "OnClientPutInServer" (number 110)

/* ERROR! Index was outside the bounds of the array. */
 function "OnClientDisconnect" (number 111)

public Action:selecttcap(Handle:timer)
{
	new String:client_name[256];
	new String:client_name_t[256];
	new String:client_auth[32];
	if (0 < CS_GetPlayingTCount())
	{
		t_cap = GetRandomPlayer(2);
		GetClientName(t_cap, client_name_t, 255);
		CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {dimgray}%s", infotitle, "CaptainT", client_name_t);
	}
	else
	{
		t_cap = GetRandomPlayer(1);
		ChangeClientTeam(t_cap, 2);
		GetClientName(t_cap, client_name_t, 255);
		CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {dimgray}%s", infotitle, "CaptainT", client_name_t);
	}
	if (menuopen == 2)
	{
		new Handle:menuT = CreateMenu(SelectPlayer, MenuAction:28);
		SetMenuTitle(menuT, "%t:", "Menu Select Player");
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, client_name, 255);
				IntToString(i, client_auth, 32);
				AddMenuItem(menuT, client_auth, client_name, 0);
				i++;
			}
			i++;
		}
		SetMenuExitButton(menuT, false);
		DisplayMenu(menuT, t_cap, 0);
	}
	return Action:0;
}

public Action:selectctcap(Handle:timer)
{
	new String:client_name[256];
	new String:client_name_ct[256];
	new String:client_auth[32];
	if (0 < CS_GetPlayingCTCount())
	{
		ct_cap = GetRandomPlayer(3);
		GetClientName(ct_cap, client_name_ct, 255);
		CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {lime}%s", infotitle, "CaptainCT", client_name_ct);
	}
	else
	{
		ct_cap = GetRandomPlayer(1);
		ChangeClientTeam(ct_cap, 3);
		GetClientName(ct_cap, client_name_ct, 255);
		CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {lime}%s", infotitle, "CaptainCT", client_name_ct);
	}
	if (menuopen == 3)
	{
		new Handle:menuCT = CreateMenu(SelectPlayer, MenuAction:28);
		SetMenuTitle(menuCT, "%t:", "Menu Select Player");
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, client_name, 255);
				IntToString(i, client_auth, 32);
				AddMenuItem(menuCT, client_auth, client_name, 0);
				i++;
			}
			i++;
		}
		SetMenuExitButton(menuCT, false);
		DisplayMenu(menuCT, ct_cap, 0);
	}
	return Action:0;
}

public Action:CheckResults(Handle:h_Timer, Handle:h_Pack)
{
	new String:s_Query[1024];
	new String:s_Reason[64];
	new i_Time;
	new i_Client;
	new String:s_AuthID[36];
	new String:s_Name[64];
	new String:s_IP[32];
	new time = GetTime({0,0});
	ResetPack(h_Pack, false);
	i_Client = ReadPackCell(h_Pack);
	ReadPackString(h_Pack, s_Name, 64);
	ReadPackString(h_Pack, s_IP, 32);
	ReadPackString(h_Pack, s_AuthID, 34);
	CloseHandle(h_Pack);
	if (!mmws_Joined[i_Client][0][0])
	{
		FormatEx(s_Reason, 64, "Выход с микса");
		if (GetConVarInt(mmws_CvarBanCountExtend4) <= g_Count[i_Client][0][0])
		{
			i_Time = GetConVarInt(mmws_CvarBanTimeExtend4);
		}
		else
		{
			if (GetConVarInt(mmws_CvarBanCountExtend3) <= g_Count[i_Client][0][0])
			{
				i_Time = GetConVarInt(mmws_CvarBanTimeExtend3);
			}
			if (GetConVarInt(mmws_CvarBanCountExtend2) <= g_Count[i_Client][0][0])
			{
				i_Time = GetConVarInt(mmws_CvarBanTimeExtend2);
			}
			if (GetConVarInt(mmws_CvarBanCountExtend) <= g_Count[i_Client][0][0])
			{
				i_Time = GetConVarInt(mmws_CvarBanTimeExtend);
			}
			i_Time = GetConVarInt(mmws_CvarBanTime);
		}
		if (g_first_half)
		{
			i_Time *= 2;
		}
		if (GetConVarInt(mmws_CvarBanEnable) == 2)
		{
			if (GetConVarInt(mmws_CvarBanServerID) < 1)
			{
				FormatEx(s_Query, 1024, "INSERT INTO %sbans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES ('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', '1000', '%s', (SELECT `sid` FROM %sservers WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1), ' ')", prefix, s_IP, s_AuthID, s_Name, i_Time * 60, i_Time * 60, s_Reason, s_ServerIP, prefix, s_ServerIP, s_ServerPort);
			}
			else
			{
				FormatEx(s_Query, 1024, "INSERT INTO %sbans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES ('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', '1000', '%s', %d, ' ')", prefix, s_IP, s_AuthID, s_Name, i_Time * 60, i_Time * 60, s_Reason, s_ServerIP, GetConVarInt(mmws_CvarBanServerID));
			}
		}
		else
		{
			if (GetConVarInt(mmws_CvarBanEnable) == 1)
			{
				FormatEx(s_Query, 1024, "INSERT INTO bans (authid, created, ends, length, reason) VALUES ('%s', %d, %d, %d, '%s')", s_AuthID, time, i_Time * 60 + time, i_Time * 60, s_Reason);
			}
		}
		if (0 < GetConVarInt(mmws_CvarBanEnable))
		{
			SQL_TQuery(h_Database, VerifyInsert, s_Query, any:0, DBPriority:0);
			if (GetConVarInt(mmws_CvarBanText) == 1)
			{
				if (GetConVarInt(mmws_CvarBanTextOption) == 1)
				{
					CPrintToChatAll("{dimgray}*%s* Info: {lime}%s {aliceblue}%t", infotitle, s_Name, "Ban Player");
				}
				if (GetConVarInt(mmws_CvarBanTextOption) == 2)
				{
					CPrintToChatAll("{dimgray}*%s* Info: {lime}%s {aliceblue}%t", infotitle, s_AuthID, "Ban Player");
				}
				if (GetConVarInt(mmws_CvarBanTextOption) == 3)
				{
					CPrintToChatAll("{dimgray}*%s* Info: {lime}%s {aliceblue}[%s] %t", infotitle, s_Name, s_AuthID, "Ban Player");
				}
			}
			decl String:query[256];
			Format(query, 255, "DELETE FROM temp WHERE `authid` = '%s'", s_AuthID);
			SQL_TQuery(mmws_Db, ErrorCheckCallback, query, any:0, DBPriority:1);
		}
	}
	return Action:0;
}

public CheckPlayerBan(Handle:owner, Handle:hndl, String:error[], h_Pack)
{
	if (hndl)
	{
		new client;
		new String:s_AuthID[36];
		new String:s_Name[64];
		new String:s_IP[32];
		ResetPack(h_Pack, false);
		client = ReadPackCell(h_Pack);
		ReadPackString(h_Pack, s_Name, 64);
		ReadPackString(h_Pack, s_IP, 32);
		ReadPackString(h_Pack, s_AuthID, 34);
		CloseHandle(h_Pack);
		g_Count[client] = SQL_GetRowCount(hndl);
		h_Pack = CreateDataPack();
		WritePackCell(h_Pack, client);
		WritePackString(h_Pack, s_Name);
		WritePackString(h_Pack, s_IP);
		WritePackString(h_Pack, s_AuthID);
		if (GetConVarInt(mmws_CvarBanAddDelay) < 1)
		{
			CreateTimer(0.1, CheckResults, h_Pack, 0);
		}
		else
		{
			new String:s_Query[1024];
			FormatEx(s_Query, 1024, "INSERT INTO temp (id, name, ip, authid) VALUES (%d, '%s', '%s', '%s')", client, s_Name, s_IP, s_AuthID);
			SQL_TQuery(mmws_Db, ErrorCheckCallback, s_Query, any:0, DBPriority:1);
			BanTimer[client] = CreateTimer(GetConVarFloat(mmws_CvarBanAddDelay), CheckResults, h_Pack, 0);
		}
		return 0;
	}
	MMWS_Updater_Log("Check Ban Query Failed: %s", error);
	return 0;
}

public VerifyInsert(Handle:owner, Handle:hndl, String:error[], data)
{
	if (hndl)
	{
		MMWS_Updater_Log("Verify Insert Query Failed: %s", error);
		return 0;
	}
	return 0;
}

public Action:OnClientCommand(client, args)
{
	if (!mmws_force_camera)
	{
		mmws_force_camera = FindConVar("mp_forcecamera");
	}
	if (client > 0)
	{
		new String:arg[256];
		GetCmdArg(0, arg, 256);
		if (StrEqual(arg, "spec_prev", true))
		{
			if (GetNumAlive(GetClientTeam(client)) > 1)
			{
				SpecPrev(client, 0.1);
			}
			return Action:3;
		}
		if (StrEqual(arg, "spec_next", true))
		{
			if (GetNumAlive(GetClientTeam(client)) > 1)
			{
				SpecNext(client, 0.1);
			}
			return Action:3;
		}
	}
	return Action:0;
}

/* ERROR! Index was outside the bounds of the array. */
 function "ResetMatch" (number 118)

ResetHalf(bool:silent)
{
	if (g_match)
	{
		Call_StartForward(mmws_on_reset_half);
		Call_Finish(0);
		if (!cwstatus)
		{
			Log2Game("\"MIX HALF RESET\"");
		}
		Log2Game("\"MATCH HALF RESET\"");
	}
	g_live = 0;
	mmws_money = 0;
	mmws_score = 0;
	mmws_knife = 0;
	g_playing_out = 0;
	SetAllCancelled(false);
	ResetHalfScores();
	UpdateStatusMMWS();
	if (GetConVarBool(mmws_auto_ready))
	{
		UpdateStatusMMWS();
	}
	if (!silent)
	{
		new x = 1;
		while (x <= 3)
		{
			if (cwstatus)
			{
				CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Half Match Cancel");
				x++;
			}
			else
			{
				CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Half Mix Cancel");
				x++;
			}
			x++;
		}
		ServerCommand("mp_restartgame 1");
	}
	ServerCommand("log off");
	return 0;
}

ResetTeams()
{
	SetConVarStringHidden(mmws_t, "Террористы");
	SetConVarStringHidden(mmws_ct, "Спецназ");
	return 0;
}

ResetMatchScores()
{
	g_scores[1][0] = 0;
	g_scores[1][0][1] = 0;
	var1[0][0][var1] = 0;
	var2[0][0][var2][1] = 0;
	new i;
	while (i <= g_overtime_count)
	{
		g_scores_overtime[1][0][i] = 0;
		g_scores_overtime[1][0][i][1] = 0;
		var3[0][0][var3][i] = 0;
		var4[0][0][var4][i][1] = 0;
		i++;
	}
	return 0;
}

ResetHalfScores()
{
	if (g_first_half)
	{
		g_scores[1][0] = 0;
		var1[0][0][var1] = 0;
	}
	else
	{
		g_scores[1][0][1] = 0;
		var2[0][0][var2][1] = 0;
	}
	return 0;
}

public Action:ForceStart(client, args)
{
	if (!IsAdminCmd(client, false))
	{
		return Action:3;
	}
	if (!g_match)
	{
		CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Team Uncompleted");
		if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
		{
			ServerCommand("hostname \"%s\"", hostnameupdate);
			Format(hostnamenew, 256, "%s [%s]", hostnameupdate, Status_Wait);
			ServerCommand("hostname \"%s\"", hostnamenew);
		}
		return Action:4;
	}
	if (g_match)
	{
		CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Halftime Team Uncompleted");
		if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
		{
			ServerCommand("hostname \"%s\"", hostnameupdate);
			Format(hostnamenew, 256, "%s [%s]", hostnameupdate, Status_HalfWait);
			ServerCommand("hostname \"%s\"", hostnamenew);
		}
		return Action:4;
	}
	ResetHalf(true);
	SetAllCancelled(false);
	LiveOn3(true);
	LogAction(client, -1, "\"force_start\" (player \"%L\")", client);
	return Action:3;
}

public Action:ForceEnd(client, args)
{
	if (!IsAdminCmd(client, false))
	{
		return Action:3;
	}
	Log2Game("\"FORCE END\"");
	ResetMatch(true);
	LogAction(client, -1, "\"force_end\" (player \"%L\")", client);
	return Action:3;
}

public Action:ConsoleScore(client, args)
{
	if (g_match)
	{
		if (g_live)
		{
			if (client)
			{
				if (cwstatus)
				{
					PrintToConsole(client, "*%s* Info: %t", infotitle, "Match Started");
				}
				else
				{
					PrintToConsole(client, "*%s* Info: %t", infotitle, "Mix Started");
				}
			}
			if (cwstatus)
			{
				PrintToServer("*%s* Info: %t", infotitle, "Match Started");
			}
			PrintToServer("*%s* Info: %t", infotitle, "Mix Started");
		}
		PrintToConsole(client, "*%s* Info: %s: [%d] %s: [%d] MR%d", infotitle, mmws_t_name, GetTScore(), mmws_ct_name, GetCTScore(), GetConVarInt(mmws_max_rounds));
	}
	else
	{
		if (client)
		{
			if (cwstatus)
			{
				PrintToConsole(client, "*%s* Info: %t", infotitle, "Match Not Started");
			}
			else
			{
				PrintToConsole(client, "*%s* Info: %t", infotitle, "Mix Not Started");
			}
		}
		if (cwstatus)
		{
			PrintToServer("*%s* Info: %t", infotitle, "Match Not Started");
		}
		PrintToServer("*%s* Info: %t", infotitle, "Mix Not Started");
	}
	return Action:3;
}

DisplayScore(client, msgindex, bool:priv)
{
	if (!GetConVarBool(mmws_ingame_scores))
	{
		return 0;
	}
	if (msgindex)
	{
		if (msgindex == 2)
		{
			new String:score_msg[192];
			GetScoreMsg(client, score_msg, 192, GetTTotalScore(), GetCTTotalScore());
			if (priv)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t: %s", infotitle, "Total Score", score_msg);
			}
			else
			{
				CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t: %s", infotitle, "Total Score", score_msg);
			}
		}
	}
	else
	{
		new String:score_msg[192];
		GetScoreMsg(client, score_msg, 192, GetTScore(), GetCTScore());
		if (priv)
		{
			CPrintToChat(client, "{dimgray}*%s* Info: %s", infotitle, score_msg);
		}
		else
		{
			CPrintToChatAll("{dimgray}*%s* Info: %s", infotitle, score_msg);
		}
	}
	return 0;
}

public GetScoreMsg(client, String:result[], maxlen, t_score, ct_score)
{
	SetGlobalTransTarget(client);
	if (t_score > ct_score)
	{
		Format(result, maxlen, "%t {aliceblue}%d-%d", "Win T", t_score, ct_score);
	}
	else
	{
		if (ct_score == t_score)
		{
			Format(result, maxlen, "{lime}%t {aliceblue}%d-%d", "Draw", t_score, ct_score);
		}
		Format(result, maxlen, "{blue}%t {aliceblue}%d-%d", "Win CT", ct_score, t_score);
	}
	if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
	{
		ServerCommand("hostname \"%s\"", hostnameupdate);
		if (GetConVarInt(mmws_CvarHostnameStatus_LiveType))
		{
			if (GetConVarInt(mmws_CvarHostnameStatus_LiveType) == 1)
			{
				Format(hostnamenew, 256, "%s [%s] [%d-%d]", hostnameupdate, Status_Live, ct_score, t_score);
			}
			Format(hostnamenew, 256, "%s [%d-%d]", hostnameupdate, ct_score, t_score);
		}
		else
		{
			Format(hostnamenew, 256, "%s [%s] CT[%d]-[%d]T", hostnameupdate, Status_Live, ct_score, t_score);
		}
		ServerCommand("hostname \"%s\"", hostnamenew);
	}
	return 0;
}

SwitchCameraTimer(client, Float:delay)
{
	ResetSwitchCameraTimer(client, true);
	g_deathcam_delays[client] = CreateTimer(delay, SpecNextFake, client, 0);
	return 0;
}

ResetSwitchCameraTimer(client, bool:killTimer)
{
	if (killTimer)
	{
		KillTimer(g_deathcam_delays[client][0][0], false);
	}
	g_deathcam_delays[client] = 0;
	return 0;
}

ResetSwitchCameraTimers(bool:killTimer)
{
	new client = 1;
	while (client <= MaxClients)
	{
		ResetSwitchCameraTimer(client, killTimer);
		client++;
	}
	return 0;
}

public Event_Round_Start(Handle:event, String:name[], bool:dontBroadcast)
{
	g_round_end = 0;
	ResetSwitchCameraTimers(true);
	CreateTimer(0.1, ShowDamage, any:0, 0);
	if (!mmws_score)
	{
		mmws_score = 1;
	}
	if (AFKTimer)
	{
		KillTimer(AFKTimer, false);
		AFKTimer = 0;
	}
	if (AFKUpdateTimer)
	{
		KillTimer(AFKUpdateTimer, false);
		AFKUpdateTimer = 0;
	}
	if (AFKCheckTimer)
	{
		KillTimer(AFKCheckTimer, false);
		AFKCheckTimer = 0;
	}
	if (mmws_knife)
	{
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				SetEntData(i, g_i_account, any:650, 4, false);
				CS_StripButKnife(i, true);
				if (GetConVarBool(mmws_knife_hegrenade))
				{
					GivePlayerItem(i, "weapon_hegrenade", 0);
				}
				if (GetConVarInt(mmws_knife_flashbang) >= 1)
				{
					GivePlayerItem(i, "weapon_flashbang", 0);
					if (GetConVarInt(mmws_knife_flashbang) >= 2)
					{
						GivePlayerItem(i, "weapon_flashbang", 0);
					}
				}
				if (GetConVarBool(mmws_knife_smokegrenade))
				{
					GivePlayerItem(i, "weapon_smokegrenade", 0);
					i++;
				}
				i++;
			}
			i++;
		}
	}
	if (!g_match)
	{
		return 0;
	}
	new the_money[66];
	new num_players;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			the_money[num_players] = i;
			num_players++;
			i++;
		}
		i++;
	}
	SortCustom1D(the_money, num_players, SortMoney, Handle:0);
	new String:player_name[32];
	new String:player_money[12];
	new String:has_weapon[4];
	new pri_weapon;
	new i = 1;
	while (i <= MaxClients)
	{
		new x;
		while (x < num_players)
		{
			GetClientName(the_money[x], player_name, 32);
			if (IsClientInGame(i))
			{
				pri_weapon = GetPlayerWeaponSlot(the_money[x], 0);
				if (!(pri_weapon == -1))
				{
				}
				IntToMoney(GetEntData(the_money[x], g_i_account, 4), player_money, 10);
				CPrintToChat(i, "{aliceblue}$%s {dimgray}%s> \x03%s", player_money, has_weapon, player_name);
				x++;
			}
			x++;
		}
		i++;
	}
	return 0;
}

public Action:ASTOP(Handle:timer)
{
	if (g_match)
	{
		astopdelay -= 1;
		if (0 < astopdelay)
		{
			if (GetConVarInt(mmws_min_ready) + -2 > CS_GetPlayingCount())
			{
				astop = 0;
				astop_team = 0;
				astop_all = 0;
				ServerCommand("forceend");
				PrintHintTextToAll("%t\n%t", "Mix Stop", "Halftime Team Uncompleted");
				CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {fullred}%t", infotitle, "Halftime Team Uncompleted", "Mix Stop");
			}
			else
			{
				if (CS_GetPlayingTCount() < 4)
				{
					PrintHintTextToAll("%t\n %t", "Mix Stop Delay", astopdelay, "T Min");
					CreateTimer(1, ASTOP, any:0, 0);
				}
				if (CS_GetPlayingCTCount() < 4)
				{
					PrintHintTextToAll("%t\n %t", "Mix Stop Delay", astopdelay, "CT Min");
					CreateTimer(1, ASTOP, any:0, 0);
				}
				if (CS_GetPlayingTCount() == 4)
				{
					PrintHintTextToAll("%t\n %t", "Mix Stop Delay", astopdelay, "Team Min");
					CreateTimer(1, ASTOP, any:0, 0);
				}
				astop = 0;
				astop_team = 0;
				astop_all = 0;
				PrintHintTextToAll("%t\n%t", "Mix Continued", "Min Players");
				CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {lime}%t", infotitle, "Min Players", "Mix Continued");
			}
		}
		else
		{
			astop = 0;
			astop_team = 0;
			astop_all = 0;
			ServerCommand("forceend");
			PrintHintTextToAll("%t\n%t", "Mix Stop", "Halftime Team Uncompleted");
			CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {fullred}%t", infotitle, "Halftime Team Uncompleted", "Mix Stop");
		}
	}
	else
	{
		astop = 0;
		astop_team = 0;
		astop_all = 0;
	}
	return Action:0;
}

public Action:AskTeamMoney(client, args)
{
	ShowTeamMoney(client);
	return Action:3;
}

ShowTeamMoney(client)
{
	new the_money[66];
	new num_players;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			the_money[num_players] = i;
			num_players++;
			i++;
		}
		i++;
	}
	SortCustom1D(the_money, num_players, SortMoney, Handle:0);
	new String:player_name[32];
	new String:player_money[12];
	new String:has_weapon[4];
	new pri_weapon;
	CPrintToChat(client, "{aliceblue}--------");
	new x;
	while (x < num_players)
	{
		GetClientName(the_money[x], player_name, 32);
		if (IsClientInGame(client))
		{
			pri_weapon = GetPlayerWeaponSlot(the_money[x], 0);
			if (!(pri_weapon == -1))
			{
			}
			IntToMoney(GetEntData(the_money[x], g_i_account, 4), player_money, 10);
			CPrintToChat(client, "{aliceblue}$%s {dimgray}%s> \x03%s", player_money, has_weapon, player_name);
			x++;
		}
		x++;
	}
	return 0;
}

public Event_Round_End(Handle:event, String:name[], bool:dontBroadcast)
{
	g_round_end = 1;
	ResetSwitchCameraTimers(true);
	CreateTimer(0.1, ShowDamage, any:1, 0);
	new winner = GetEventInt(event, "winner");
	new String:winner_name[256];
	new String:reason[256];
	if (winner == 2)
	{
		Format(winner_name, 256, "Террористы");
	}
	else
	{
		if (winner == 3)
		{
			Format(winner_name, 256, "Спецназ");
		}
		Format(winner_name, 256, "Неизвестно");
	}
	if (GetEventInt(event, "reason") == 6)
	{
		Format(reason, 255, "Бомба обезврежена");
	}
	if (GetEventInt(event, "reason") == 7)
	{
		Format(reason, 255, "Террористы уничтожены");
	}
	if (GetEventInt(event, "reason") == 8)
	{
		Format(reason, 255, "Спецназ уничтожен");
	}
	if (GetEventInt(event, "reason") == 11)
	{
		Format(reason, 255, "Бомба не заложена");
	}
	if (!(GetEventInt(event, "reason")))
	{
		Format(reason, 255, "Бомба взорвана");
	}
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			clutch_stats[i][0][0][3] = 1;
			i++;
		}
		i++;
	}
	Log2Game("\"ROUND END\" (winner \"%s\") (reason \"%s\")", winner_name, reason);
	if (winner > 1)
	{
		if (mmws_knife)
		{
			if (GetConVarBool(mmws_auto_knife))
			{
				SetAllCancelled(false);
			}
			if (GetConVarBool(mmws_stats_enabled))
			{
				if (winner == 2)
				{
					Log2Game("\"knife_win\" (team \"%s\")", mmws_t_name);
				}
				if (winner == 3)
				{
					Log2Game("\"knife_win\" (team \"%s\")", mmws_ct_name);
				}
			}
			if (!afknifego)
			{
				mmws_knife = 0;
			}
			mmws_had_knife = 1;
			UpdateStatusMMWS();
		}
		if (!g_live)
		{
			return 0;
		}
		if (!mmws_money)
		{
			mmws_money = 1;
		}
		AddScore(winner);
		CheckScores();
		UpdateStatusMMWS();
	}
	if (SubStatusWait)
	{
		if (g_match)
		{
			if (!IsClientInGame(SubSpectator))
			{
				CPrintToChat(SubPlayer, "{dimgray}*%s* Info: {aliceblue}Игрок для замены недоступен. {fullred}%t", infotitle, "Replace Cancel");
			}
			else
			{
				if (!IsClientInGame(SubPlayer))
				{
					CPrintToChat(SubSpectator, "{dimgray}*%s* Info: {aliceblue}Игрок для замены недоступен. {dimgray}%t.", infotitle, "Replace Cancel");
				}
				decl String:SubName[256];
				decl String:PlayerName[256];
				decl String:SubAuth[256];
				decl String:PlayerAuth[256];
				GetClientName(SubSpectator, SubName, 255);
				GetClientName(SubPlayer, PlayerName, 255);
				GetClientAuthString(SubPlayer, PlayerAuth, 255);
				GetClientAuthString(SubSpectator, SubAuth, 255);
				new PlayerTeam = GetClientTeam(SubPlayer);
				ServerCommand("sm_kick #%d %t %s", GetClientUserId(SubPlayer), "Your Replace", SubName);
				ChangeClientTeam(SubSpectator, PlayerTeam);
				CPrintToChat(SubSpectator, "{dimgray}*%s* Info: {aliceblue}%t {lime}%s {aliceblue}%t", infotitle, "Replace", SubName, "Replace 1");
				Log2Game("\"SUBSTITUTION\" (OUT: \"%s\" [%s]) (IN: \"%s\" [%s]) (TEAM: %d)", PlayerName, PlayerAuth, SubName, SubAuth, PlayerTeam);
			}
		}
		else
		{
			CPrintToChat(SubSpectator, "{dimgray}*%s* Info: {aliceblue}%t {dimgray}%t.", infotitle, "Mix Ended", "Replace Cancel");
			CPrintToChat(SubPlayer, "{dimgray}*%s* Info: {aliceblue}%t {fullred}%t", infotitle, "Mix Ended", "Exit Allow");
		}
		SubStatus = 0;
		SubPlayer = 0;
		SubSpectator = 0;
		SubStatusWait = 0;
	}
	return 0;
}

public Event_Round_Restart(Handle:cvar, String:oldVal[], String:newVal[])
{
	if (GetConVarBool(mmws_stats_enabled))
	{
		new i = 1;
		while (i <= MaxClients)
		{
			ResetPlayerStats(i);
			clutch_stats[i][0][0][0] = 0;
			clutch_stats[i][0][0][1] = 0;
			clutch_stats[i][0][0][2] = 0;
			clutch_stats[i][0][0][3] = 0;
			i++;
		}
		Log2Game("\"ROUND RESTART\" (delay \"%s\")", newVal);
	}
	return 0;
}

public Event_Player_Death(Handle:event, String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:headshot = GetEventBool(event, "headshot");
	new String:weapon[64];
	GetEventString(event, "weapon", weapon, 64);
	if (!knife)
	{
		if (attacker > 0)
		{
			if (GetConVarInt(mmws_CvarMenuSelectPlayers))
			{
				if (GetClientTeam(attacker) == 2)
				{
					t_cap = attacker;
					menuopen = 2;
				}
				else
				{
					ct_cap = attacker;
					menuopen = 3;
				}
				if (GetClientTeam(victim) == 2)
				{
					t_cap = victim;
				}
				else
				{
					ct_cap = victim;
				}
				new Handle:menu = CreateMenu(SelectPlayer, MenuAction:28);
				new String:client_name[256];
				new String:client_auth[32];
				SetMenuTitle(menu, "Выберите игрока:");
				new i = 1;
				while (i <= MaxClients)
				{
					if (IsClientInGame(i))
					{
						GetClientName(i, client_name, 255);
						IntToString(i, client_auth, 32);
						AddMenuItem(menu, client_auth, client_name, 0);
						i++;
					}
					i++;
				}
				SetMenuExitButton(menu, false);
				DisplayMenu(menu, attacker, 15);
			}
			if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
			{
				ServerCommand("hostname \"%s\"", hostnameupdate);
				Format(hostnamenew, 256, "%s [%s]", hostnameupdate, Status_Select);
				ServerCommand("hostname \"%s\"", hostnamenew);
			}
			afknifego = 0;
			afstart = 1;
			afknife = 0;
			mmws_knife = 0;
		}
	}
	if (attacker > 0)
	{
		new String:attacker_log_string[256];
		new String:victim_log_string[256];
		CS_GetAdvLogString(attacker, attacker_log_string, 256);
		CS_GetAdvLogString(victim, victim_log_string, 256);
		Log2Game("\"PLAYER DEATH\" (attacker \"%s\") (victim \"%s\") (weapon \"%s\") (headshot \"%d\")", attacker_log_string, victim_log_string, weapon, headshot);
	}
	else
	{
		if (victim > 0)
		{
			new String:log_string[256];
			CS_GetAdvLogString(victim, log_string, 256);
			ReplaceString(weapon, 64, "worldspawn", "world", true);
			Log2Game("\"PLAYER SUICIDE\" (player \"%s\") (weapon \"%s\")", log_string, weapon);
		}
	}
	if (0 < victim)
	{
		new weapon_index = GetWeaponIndex(weapon);
		if (0 < attacker)
		{
			new victim_team = GetClientTeam(victim);
			new attacker_team = GetClientTeam(attacker);
			if (weapon_index > -1)
			{
				weapon_stats[attacker][0][0][weapon_index][2]++;
				if (headshot == true)
				{
					weapon_stats[attacker][0][0][weapon_index][3]++;
				}
				if (victim_team == attacker_team)
				{
					weapon_stats[attacker][0][0][weapon_index][4]++;
				}
			}
			new victim_num_alive = GetNumAlive(victim_team);
			new attacker_num_alive = GetNumAlive(attacker_team);
			if (!victim_num_alive)
			{
				clutch_stats[victim][0][0][0] = 1;
				if (clutch_stats[victim][0][0][1])
				{
				}
				else
				{
					clutch_stats[victim][0][0][1] = attacker_num_alive;
				}
			}
			if (attacker_num_alive == 1)
			{
				if (victim_team != attacker_team)
				{
					clutch_stats[attacker][0][0][2]++;
					if (!clutch_stats[attacker][0][0][0])
					{
						clutch_stats[attacker][0][0][1] = victim_num_alive + 1;
					}
					clutch_stats[attacker][0][0][0] = 1;
				}
			}
		}
		new victim_weapon_index = GetWeaponIndex(last_weapon[victim][0][0]);
		if (victim_weapon_index > -1)
		{
			weapon_stats[victim][0][0][victim_weapon_index][6]++;
		}
	}
	if (!g_live)
	{
		CreateTimer(0.1, RespawnPlayer, victim, 0);
	}
	else
	{
		if (!g_round_end)
		{
			if (!mmws_force_camera)
			{
				mmws_force_camera = FindConVar("mp_forcecamera");
			}
			if (mmws_force_camera)
			{
				if (0 < GetNumAlive(GetClientTeam(victim)))
				{
					SwitchCameraTimer(victim, GetConVarFloat(mmws_deathcam_delay));
					new target;
					new i = 1;
					while (i <= MaxClients)
					{
						if (victim != i)
						{
							target = GetEntPropEnt(i, PropType:0, "m_hObserverTarget", 0);
							if (IsValidEntity(target))
							{
								SwitchCameraTimer(i, GetConVarFloat(mmws_deathcam_delay));
								i++;
							}
							i++;
						}
						i++;
					}
				}
			}
		}
		if (!mmws_fade_to_black)
		{
			mmws_fade_to_black = FindConVar("mp_fadetoblack");
		}
		if (GetConVarBool(mmws_fade_to_black))
		{
			CreateTimer(6, SetSpecTimer, victim, 2);
		}
	}
	if (GetConVarBool(mmws_body_remove))
	{
		CreateTimer(GetConVarFloat(mmws_body_delay), RemoveRagdoll, victim, 2);
	}
	return 0;
}

public Action:Event_Player_Connect(Handle:event, String:name[], bool:dontBroadcast)
{
	return Action:0;
}

public Action:CheckStatus(Handle:timer)
{
	if (g_match)
	{
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				if (CS_GetPlayingTCount() < CS_GetPlayingCTCount())
				{
					ChangeClientTeam(i, 2);
				}
				if (CS_GetPlayingTCount() > CS_GetPlayingCTCount())
				{
					ChangeClientTeam(i, 3);
				}
				if (CS_GetPlayingCTCount() == CS_GetPlayingTCount())
				{
					if (GetCTTotalScore() > GetTTotalScore())
					{
						ChangeClientTeam(i, 2);
					}
					if (GetCTTotalScore() < GetTTotalScore())
					{
						ChangeClientTeam(i, 3);
					}
					if (GetCTTotalScore() == GetTTotalScore())
					{
						ChangeClientTeam(i, 3);
						i++;
					}
					i++;
				}
				i++;
			}
			i++;
		}
		if (CS_GetPlayingTCount() < 4)
		{
			astop_all = 0;
			astop_team = 1;
			if (astopdelay > 60)
			{
				astopdelay = 60;
			}
		}
		else
		{
			if (CS_GetPlayingCTCount() < 4)
			{
				astop_all = 0;
				astop_team = 1;
				if (astopdelay > 60)
				{
					astopdelay = 60;
				}
			}
			if (CS_GetPlayingCTCount() < 5)
			{
				astop_all = 1;
				astop_team = 0;
				astopdelay = GetConVarInt(mmws_CvarAStop_Delay) + -60 + astopdelay;
			}
		}
		if (CS_GetPlayingTCount() < 4)
		{
			astop = 1;
			astop_team = 1;
			astop_all = 0;
			astopdelay = 60;
			CreateTimer(1, ASTOP, any:0, 0);
			PrintHintTextToAll("%t %d %t\n %t %d %t.", "Mix Stop Delay", astopdelay, "Seconds", "Team T Min", GetConVarInt(mmws_min_ready) / 2 + -1, "Players");
			CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {fullred}%d {aliceblue}%t. %t {fullred}%d {aliceblue}%t", infotitle, "Mix Stopped Delay", astopdelay, "Seconds", "Team T Min", GetConVarInt(mmws_min_ready) / 2 + -1, "Players");
		}
		if (CS_GetPlayingCTCount() < 4)
		{
			astop = 1;
			astop_team = 1;
			astop_all = 0;
			astopdelay = 60;
			CreateTimer(1, ASTOP, any:0, 0);
			PrintHintTextToAll("%t %d %t\n %t %d %t.", "Mix Stop Delay", astopdelay, "Seconds", "Team CT Min", GetConVarInt(mmws_min_ready) / 2 + -1, "Players");
			CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {fullred}%d {aliceblue}%t. %t {fullred}%d {aliceblue}%t", infotitle, "Mix Stopped Delay", astopdelay, "Seconds", "Team CT Min", GetConVarInt(mmws_min_ready) / 2 + -1, "Players");
		}
		if (CS_GetPlayingTCount() < 5)
		{
			astop = 1;
			astop_all = 1;
			astop_team = 0;
			astopdelay = 180;
			CreateTimer(1, ASTOP, any:0, 0);
			PrintHintTextToAll("%t %d %t\n %t", "Mix Stop Delay", GetConVarInt(mmws_CvarAStop_Delay), "Seconds", "Teams Min");
			CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {fullred}%d {aliceblue}%t. %t {fullred}%d %t.", infotitle, "Mix Stopped Delay", GetConVarInt(mmws_CvarAStop_Delay), "Seconds", "Teams Min", GetConVarInt(mmws_min_ready) / 2 + -1, "Player");
		}
	}
	return Action:0;
}

/* ERROR! Unable to cast object of type 'Lysis.LDebugBreak' to type 'Lysis.LConstant'. */
 function "Event_Player_Disc" (number 140)

public Event_Player_Team(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new old_team = GetEventInt(event, "oldteam");
	new new_team = GetEventInt(event, "team");
	if (!old_team)
	{
		CreateTimer(5, ShowPluginInfo, client, 0);
		if (!license)
		{
			CreateTimer(8, ShowAdverts, client, 0);
		}
	}
	if (new_team > 1)
	{
		CreateTimer(0.1, RespawnPlayer, client, 0);
	}
	if (new_team > 1)
	{
		mmws_Team[client] = 1;
	}
	else
	{
		mmws_Team[client] = 0;
	}
	return 0;
}

public Event_Bomb_Exploded(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!GetConVarBool(mmws_bomb_frags))
	{
		SetFrags(client, GetFrags(client) + -3);
	}
	new String:log_string[256];
	CS_GetAdvLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, 256);
	Log2Game("\"BOMB EXPLODED\" (player \"%s\")", log_string);
	return 0;
}

public Event_Bomb_Planted(Handle:event, String:name[], bool:dontBroadcast)
{
	new String:log_string[256];
	CS_GetAdvLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, 256);
	Log2Game("\"BOMB PLANTED\" (player \"%s\")", log_string);
	return 0;
}

public Event_Bomb_Defused(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarBool(mmws_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(client, log_string, 256);
		Log2Game("\"BOMB DEFUSED\" (player \"%s\")", log_string);
	}
	if (!GetConVarBool(mmws_defuse_frags))
	{
		SetFrags(client, GetFrags(client) + -3);
	}
	return 0;
}

AddScore(team)
{
	if (team == 2)
	{
		if (g_first_half)
		{
			g_scores[1][0]++;
		}
		g_scores[1][0][1]++;
	}
	if (team == 3)
	{
		if (g_first_half)
		{
			var1[0][0][var1]++;
		}
		var2[0][0][var2][1]++;
	}
	if (GetConVarBool(mmws_stats_enabled))
	{
		Log2Game("\"SCORE UPDATE\" \"%s (%d) - (%d) %s\"", mmws_t_name, GetTTotalScore(), GetCTTotalScore(), mmws_ct_name);
	}
	return 0;
}

/* ERROR! Unable to cast object of type 'Lysis.LDebugBreak' to type 'Lysis.LConstant'. */
 function "CheckScores" (number 146)

GetScore()
{
	return GetCTScore() + GetTScore();
}

GetTScore()
{
	return g_scores[1][0][1][g_scores[1][0]];
}

GetCTScore()
{
	return var1[0][0][var1][var2[0][0][var2][1]];
}

GetTTotalScore()
{
	new result = GetTScore();
	new i;
	while (i <= g_overtime_count)
	{
		result = g_scores_overtime[1][0][i][1][g_scores_overtime[1][0][i]][result];
		i++;
	}
	return result;
}

GetCTTotalScore()
{
	new result = GetCTScore();
	new i;
	while (i <= g_overtime_count)
	{
		result = var2[0][0][var2][i][1][var1[0][0][var1][i]][result];
		i++;
	}
	return result;
}

public SortMoney(elem1, elem2, array[], Handle:hndl)
{
	new money1 = GetEntData(elem1, g_i_account, 4);
	new money2 = GetEntData(elem2, g_i_account, 4);
	if (money1 > money2)
	{
		return -1;
	}
	if (money2 == money1)
	{
		return 0;
	}
	return 1;
}

LiveOn3(bool:e_war)
{
	Call_StartForward(mmws_on_lo3);
	Call_Finish(0);
	mmws_score = 0;
	new String:match_config[64];
	GetConVarString(mmws_match_config, match_config, 64);
	new String:live_config[64];
	GetConVarString(mmws_live_config, live_config, 64);
	if (e_war)
	{
		ServerCommand("exec %s", match_config);
	}
	if (!g_match)
	{
		new String:date[32];
		FormatTime(date, 32, "%Y%m%d_%H%M", -1);
		new String:t_name[64];
		new String:ct_name[64];
		StripFilename(t_name, 64);
		StripFilename(ct_name, 64);
		StringToLower(t_name, 64);
		StringToLower(ct_name, 64);
		new String:demofolder[256];
		GetConVarString(mmws_CvarDemoFolder, demofolder, 255);
		if (StrEqual(demofolder, "", true))
		{
			Format(g_log_filename, 128, "%s_%s", date, g_map);
		}
		else
		{
			Format(g_log_filename, 128, "%s/%s_%s", demofolder, date, g_map);
		}
		if (GetConVarBool(mmws_auto_record))
		{
			ServerCommand("tv_stoprecord");
			ServerCommand("tv_record %s.dem", g_log_filename);
		}
		new String:filepath[128];
		Format(filepath, 128, "%s.log", g_log_filename);
		g_log_file = OpenFile(filepath, "w");
		LogPlayers();
	}
	LiveOn3Override();
	if (!g_match)
	{
		if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
		{
			ServerCommand("hostname \"%s\"", hostnameupdate);
			if (GetConVarInt(mmws_CvarHostnameStatus_LiveType))
			{
				if (GetConVarInt(mmws_CvarHostnameStatus_LiveType) == 1)
				{
					Format(hostnamenew, 256, "%s [%s] [0-0]", hostnameupdate, Status_Live);
				}
				Format(hostnamenew, 256, "%s [0-0]", hostnameupdate);
			}
			else
			{
				Format(hostnamenew, 256, "%s [%s] %s", hostnameupdate, Status_Live, Status_Live_First);
			}
			ServerCommand("hostname \"%s\"", hostnamenew);
		}
	}
	g_match = 1;
	g_live = 1;
	ServerCommand("log on");
	if (GetConVarBool(mmws_stats_enabled))
	{
		Log2Game("\"LIVEon3\" (map \"%s\") (t \"%s\") (ct \"%s\") (status \"%d\") (version \"%s\")", g_map, mmws_t_name, mmws_ct_name, UpdateStatusMMWS(), "5.26");
	}
	return 0;
}

LiveOn3Override()
{
	new String:text[128];
	new lastdelay;
	new delay = 1;
	Format(text, 128, "***** 3 *****");
	CreateTimer(0.1, RestartRound, delay, 0);
	new Handle:datapack;
	CreateDataTimer(0.9, CPrintToChatDelayed, datapack, 0);
	WritePackString(datapack, text);
	lastdelay = delay;
	delay = 1;
	Format(text, 128, "***** 2 *****");
	CreateTimer(float(lastdelay) + 1.3, RestartRound, delay, 0);
	new Handle:datapack1;
	CreateDataTimer(float(lastdelay) + 2, CPrintToChatDelayed, datapack1, 0);
	WritePackString(datapack1, text);
	lastdelay = delay + lastdelay;
	delay = 3;
	Format(text, 128, "***** 1 *****");
	CreateTimer(float(lastdelay) + 2.5, RestartRound, delay, 0);
	new Handle:datapack2;
	CreateDataTimer(float(lastdelay) + 3.5, CPrintToChatDelayed, datapack2, 0);
	WritePackString(datapack2, text);
	lastdelay = delay + lastdelay;
	Format(text, 128, "********* GL HF *********");
	new Handle:datapack4;
	CreateDataTimer(float(lastdelay) + 3.5, CPrintToChatDelayed, datapack4, 0);
	WritePackString(datapack4, text);
	if (cwstatus)
	{
		Format(text, 128, "***** %t *****", "Match Live");
	}
	else
	{
		Format(text, 128, "***** %t *****", "Mix Live");
	}
	new Handle:datapack3;
	CreateDataTimer(float(lastdelay) + 3.5, CPrintToChatDelayed, datapack3, 0);
	WritePackString(datapack3, text);
	return 1;
}

public Action:KnifeOn3(client, args)
{
	if (cwstatus)
	{
		if (!IsAdminCmd(client, false))
		{
			return Action:3;
		}
		mmws_knife = 1;
		mmws_score = 0;
		if (GetConVarBool(mmws_stats_enabled))
		{
			Log2Game("\"knife_on_3\" (map \"%s\") (t \"%s\") (ct \"%s\")", g_map, mmws_t_name, mmws_ct_name);
		}
		new String:match_config[64];
		GetConVarString(mmws_match_config, match_config, 64);
		if (!StrEqual(match_config, "", true))
		{
			ServerCommand("exec %s", match_config);
		}
		KnifeOn3Override();
		UpdateStatusMMWS();
	}
	return Action:3;
}

KnifeOn3Override()
{
	new String:text[128];
	new lastdelay;
	new delay = 1;
	Format(text, 128, "***** 3 *****");
	CreateTimer(0.1, RestartRound, delay, 0);
	new Handle:datapack;
	CreateDataTimer(0.9, CPrintToChatDelayed, datapack, 0);
	WritePackString(datapack, text);
	lastdelay = delay;
	delay = 1;
	Format(text, 128, "***** 2 *****");
	CreateTimer(float(lastdelay) + 1.3, RestartRound, delay, 0);
	new Handle:datapack1;
	CreateDataTimer(float(lastdelay) + 2, CPrintToChatDelayed, datapack1, 0);
	WritePackString(datapack1, text);
	lastdelay = delay + lastdelay;
	delay = 3;
	Format(text, 128, "***** 1 *****");
	CreateTimer(float(lastdelay) + 2.5, RestartRound, delay, 0);
	new Handle:datapack2;
	CreateDataTimer(float(lastdelay) + 3.5, CPrintToChatDelayed, datapack2, 0);
	WritePackString(datapack2, text);
	lastdelay = delay + lastdelay;
	Format(text, 128, "********* GL HF *********");
	new Handle:datapack4;
	CreateDataTimer(float(lastdelay) + 3.5, CPrintToChatDelayed, datapack4, 0);
	WritePackString(datapack4, text);
	Format(text, 128, "***** %t *****", "Knife Live");
	new Handle:datapack3;
	CreateDataTimer(float(lastdelay) + 3.5, CPrintToChatDelayed, datapack3, 0);
	WritePackString(datapack3, text);
	return 1;
}

public Action:CancelKnife(client, args)
{
	if (!IsAdminCmd(client, false))
	{
		return Action:3;
	}
	if (mmws_knife)
	{
		if (GetConVarBool(mmws_stats_enabled))
		{
			Log2Game("\"knife_reset\"");
		}
		mmws_knife = 0;
		mmws_had_knife = 0;
		ServerCommand("mp_restartgame 1");
		new x = 1;
		while (x <= 3)
		{
			CPrintToChatAll("{dimgray}*%s* Info: {fullred}%t", infotitle, "Knife Cancel");
			x++;
		}
		if (client)
		{
		}
		else
		{
			PrintToServer("{dimgray}*%s* Info: {fullred}%t", infotitle, "Knife Cancel");
		}
	}
	UpdateStatusMMWS();
	return Action:3;
}

public Action:ChooseTeam(client, args)
{
	if (client)
	{
		if (g_match)
		{
			if (cwstatus)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {fullred}%t", infotitle, "Change Team Match Deny");
			}
			else
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {fullred}%t", infotitle, "Change Team Mix Deny");
			}
			return Action:4;
		}
		new max_players = GetConVarInt(mmws_max_players);
		new max_team_players = max_players / 2;
		if (!g_match)
		{
			if (GetClientTeam(client))
			{
				if (GetClientTeam(client) > 1)
				{
					return Action:4;
				}
				if (CS_GetPlayingTCount() > 0)
				{
					ChangeClientTeam(client, 3);
					return Action:4;
				}
				if (CS_GetPlayingTCount())
				{
					ChangeClientTeam(client, 2);
					return Action:4;
				}
				if (CS_GetPlayingTCount() > 0)
				{
					CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Team Knife Completed");
					ChangeClientTeam(client, 1);
					return Action:4;
				}
			}
			ChangeClientTeam(client, 1);
			return Action:4;
		}
		if (!g_match)
		{
			if (menuopen > 0)
			{
				if (GetClientTeam(client))
				{
					CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Waiting Select");
					return Action:4;
				}
				ChangeClientTeam(client, 1);
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Waiting Select");
				return Action:4;
			}
			if (GetClientTeam(client) > 1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {fullred}%t", infotitle, "Change Denied");
				return Action:4;
			}
			if (CS_GetPlayingTCount() > 4)
			{
				ChangeClientTeam(client, 3);
				return Action:4;
			}
			if (CS_GetPlayingCTCount() > 4)
			{
				ChangeClientTeam(client, 2);
				return Action:4;
			}
			if (CS_GetPlayingTCount() > 4)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {lime}%t", infotitle, "Team Completed");
				ChangeClientTeam(client, 1);
				return Action:4;
			}
		}
		if (g_match)
		{
			ChangeClientTeam(client, 3);
			return Action:4;
		}
		if (g_match)
		{
			ChangeClientTeam(client, 2);
			return Action:4;
		}
		if (g_match)
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {lime}%t", infotitle, "Team Completed");
			ChangeClientTeam(client, 1);
			return Action:4;
		}
		if (g_match)
		{
			new ClientID;
			decl String:query[256];
			Format(query, 255, "SELECT `id` FROM temp");
			new Handle:result = SQL_Query(mmws_Db, query, -1);
			if (result)
			{
				while (SQL_FetchRow(result))
				{
					ClientID = SQL_FetchInt(result, 0, 0);
					if (BanTimer[ClientID][0][0])
					{
						KillTimer(BanTimer[ClientID][0][0], false);
						BanTimer[ClientID] = 0;
					}
				}
				SQL_LockDatabase(mmws_Db);
				SQL_FastQuery(mmws_Db, sql_ClearTables, -1);
				SQL_UnlockDatabase(mmws_Db);
			}
		}
		return Action:0;
	}
	return Action:0;
}

public Action:RestrictBuy(client, args)
{
	if (client)
	{
		new String:arg[128];
		GetCmdArgString(arg, 128);
		new String:the_weapon[32];
		Format(the_weapon, 32, "%s", arg);
		ReplaceString(the_weapon, 32, "weapon_", "", true);
		ReplaceString(the_weapon, 32, "item_", "", true);
		if (mmws_knife)
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {fullred}%t", infotitle, "Knife Weapon Denied");
			if (!cwstatus)
			{
				SetEntData(client, g_i_account, any:0, 4, false);
			}
			ClientCommand(client, "playgamesound resource/warning.wav");
			return Action:3;
		}
		if (!cwstatus)
		{
			if (StrEqual(arg, "nvgs", false))
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "NightVision Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "ak47", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "aug", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "awp", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "deagle", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "elite", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "famas", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "fiveseven", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "g3sg1", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "galil", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "glock", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "m249", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "m3", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "m4a1", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "mac10", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "mp5navy", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "p228", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "p90", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "scout", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "sg550", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "sg552", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "tmp", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "ump45", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "usp", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (StrContains(the_weapon, "xm1014", false) != -1)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Weapon Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
			if (!g_match)
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Grenade Denied");
				ClientCommand(client, "playgamesound resource/warning.wav");
				return Action:3;
			}
		}
		return Action:0;
	}
	return Action:0;
}

public Action:NotLive(client, args)
{
	if (!IsAdminCmd(client, false))
	{
		return Action:3;
	}
	ResetHalf(false);
	if (!client)
	{
		if (cwstatus)
		{
			PrintToServer("*%s* Info: %t", infotitle, "Half Match Cancel");
		}
		PrintToServer("*%s* Info: %t", infotitle, "Half Mix Cancel");
	}
	LogAction(client, -1, "\"half_reset\" (player \"%L\")", client);
	return Action:3;
}

public Action:CancelMatch(client, args)
{
	if (!IsAdminCmd(client, false))
	{
		return Action:3;
	}
	ResetMatch(false);
	if (!client)
	{
		if (cwstatus)
		{
			PrintToServer("*%s* Info: %t", infotitle, "Match Stop");
		}
		PrintToServer("*%s* Info: %t", infotitle, "Mix Stop");
	}
	LogAction(client, -1, "\"match_reset\" (player \"%L\")", client);
	return Action:3;
}

IsAdminCmd(client, bool:silent)
{
	if (client)
	{
		return 1;
	}
	if (!silent)
	{
		CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "RCON");
	}
	return 0;
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	return 0;
}

public SetAllCancelled(bool:cancelled)
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			g_cancel_list[i] = cancelled;
			i++;
		}
		i++;
	}
	return 0;
}

public Action:SayChat(client, args)
{
	if (client)
	{
		if (GetConVarBool(mmws_modifiers))
		{
			new String:text[192];
			GetCmdArgString(text, 192);
			CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%s", infotitle, text);
			return Action:3;
		}
		return Action:0;
	}
	new String:text[192];
	new start_index;
	GetCmdArgString(text, 192);
	if (text[strlen(text) + -1] == '"')
	{
		text[strlen(text) + -1] = 0;
		start_index = 1;
	}
	if (text[start_index] == '@')
	{
		if (CheckAdminForChat(client))
		{
			new String:message[192];
			strcopy(message, 192, text[start_index + 1]);
			new i = 1;
			while (i <= MaxClients)
			{
				if (IsClientInGame(i))
				{
					CPrintToChat(i, "{dimgray}*%s* Info: {aliceblue}%s", infotitle, message);
					i++;
				}
				i++;
			}
		}
		else
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {fullred}%t", infotitle, "Command Denied");
		}
		return Action:3;
	}
	if (!g_live)
	{
		new msg_start;
		if (text[start_index] == '!')
		{
			msg_start = 1;
		}
		new String:message[192];
		strcopy(message, 192, text[msg_start + start_index]);
		new String:name[64];
		GetClientName(client, name, 64);
		if (msg_start)
		{
			new String:command[192];
			new String:split_str[32][32];
			ExplodeString(text[msg_start + start_index], " ", split_str, 8, 32, false);
			strcopy(command, 192, split_str[0][split_str]);
		}
		return Action:0;
	}
	else
	{
		new msg_start = 721740;
		CPrintToChat(client, "{dimgray}*%s* Info: {fullred}%t", infotitle, "Chat Disabled");
	}
	return Action:3;
}

public Action:SayTeamChat(client, args)
{
	if (client)
	{
		new String:text[256];
		GetCmdArgString(text, 255);
		new start_index;
		if (text[strlen(text) + -1] == '"')
		{
			text[strlen(text) + -1] = 0;
			start_index = 1;
		}
		new msg_start;
		if (text[start_index] == '!')
		{
			return Action:3;
		}
		new String:message[256];
		strcopy(message, 255, text[msg_start + start_index]);
		new client_team = GetClientTeam(client);
		new String:client_name[32];
		GetClientName(client, client_name, 32);
		if (client_team < 2)
		{
			CPrintToChatAllEx(client, "{aliceblue}(%t) {teamcolor}%s {aliceblue}: %s", "Spectator", client_name, message);
		}
		else
		{
			new i = 1;
			while (i <= MaxClients)
			{
				if (!IsPlayerAlive(client))
				{
					CPrintToChatEx(i, client, "{aliceblue}*%t* (%t) {teamcolor}%s {aliceblue}: %s", "Dead", "Team", client_name, message);
				}
				if (IsPlayerAlive(client))
				{
					CPrintToChatEx(i, client, "{aliceblue}(%t) {teamcolor}%s {aliceblue}: %s", "Team", client_name, message);
					i++;
				}
				i++;
			}
		}
		return Action:3;
	}
	return Action:0;
}

GetWeaponIndex(String:weapon[])
{
	new i;
	while (i < 28)
	{
		if (StrEqual(weapon, weapon_list[i][0][0], false))
		{
			return i;
		}
		i++;
	}
	return -1;
}

SwitchScores()
{
	new temp = g_scores[1][0];
	g_scores[1][0] = var1[0][0][var1];
	var2[0][0][var2] = temp;
	temp = g_scores[1][0][1];
	g_scores[1][0][1] = var3[0][0][var3][1];
	var4[0][0][var4][1] = temp;
	new i;
	while (i <= g_overtime_count)
	{
		temp = g_scores_overtime[1][0][i];
		g_scores_overtime[1][0][i] = var5[0][0][var5][i];
		var6[0][0][var6][i] = temp;
		temp = g_scores_overtime[1][0][i][1];
		g_scores_overtime[1][0][i][1] = var7[0][0][var7][i][1];
		var8[0][0][var8][i][1] = temp;
		i++;
	}
	return 0;
}

SwitchTeams()
{
	new String:temp[64];
	SetConVarStringHidden(mmws_t, mmws_ct_name);
	SetConVarStringHidden(mmws_ct, temp);
	return 0;
}

public Action:SwapAll(client, args)
{
	if (!IsAdminCmd(client, false))
	{
		return Action:3;
	}
	CS_SwapTeams();
	SwitchScores();
	return Action:3;
}

public Action:Swap(Handle:timer)
{
	if (!g_live)
	{
		CS_SwapTeams();
		if (GetConVarInt(mmws_CvarBanAutoForceStart) == 1)
		{
			ServerCommand("forcestart");
		}
		if (GetConVarInt(mmws_CvarBanAutoForceStart) == 2)
		{
			CreateTimer(GetConVarFloat(mmws_CvarBanAutoFSdelay), FS, any:0, 0);
			CreateTimer(300, FE, any:0, 0);
		}
	}
	return Action:0;
}

public Action:FE(Handle:timer)
{
	if (g_match)
	{
		if (CS_GetPlayingCount() < GetConVarInt(mmws_min_ready))
		{
			PrintHintTextToAll("%t\n%t", "Mix Stop", "Uncount Player 5 Minutes");
			ServerCommand("forceend");
		}
	}
	return Action:0;
}

public Action:FS(Handle:timer)
{
	if (g_match)
	{
		if (GetConVarInt(mmws_min_ready) + -2 > CS_GetPlayingCount())
		{
			ServerCommand("forceend");
			PrintHintTextToAll("%t\n%t", "Mix Stop", "Halftime Team Uncompleted");
			CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {fullred}%t", infotitle, "Halftime Team Uncompleted", "Mix Stop");
		}
		if (CS_GetPlayingTCount() < 5)
		{
			if (!half_t_readymenu)
			{
				half_t_readymenu = 1;
				half_t_ready = 0;
				half_t_unready = 0;
				half_ct_readymenu = 1;
				half_ct_ready = 0;
				half_ct_unready = 0;
				CreateTimer(5, HalfTReadyMenu, any:0, 0);
				CreateTimer(5, HalfCTReadyMenu, any:0, 0);
			}
			CreateTimer(1, FS, any:0, 0);
			PrintHintTextToAll("%t \n%t", "Uncomplete Teams", "Autoresume Teams");
		}
		if (CS_GetPlayingCTCount() < 5)
		{
			if (!half_ct_readymenu)
			{
				half_ct_readymenu = 1;
				half_ct_ready = 0;
				half_ct_unready = 0;
				CreateTimer(5, HalfCTReadyMenu, any:0, 0);
			}
			CreateTimer(1, FS, any:0, 0);
			PrintHintTextToAll("%t \n%t", "Uncomplete CT", "Autoresume Team");
		}
		if (CS_GetPlayingTCount() < 5)
		{
			if (!half_t_readymenu)
			{
				half_t_readymenu = 1;
				half_t_ready = 0;
				half_t_unready = 0;
				CreateTimer(5, HalfTReadyMenu, any:0, 0);
			}
			CreateTimer(1, FS, any:0, 0);
			PrintHintTextToAll("%t \n%t", "Uncomplete T", "Autoresume Team");
		}
		half_t_readymenu = 0;
		half_t_ready = 0;
		half_t_unready = 0;
		half_ct_readymenu = 0;
		half_ct_ready = 0;
		half_ct_unready = 0;
		ServerCommand("forcestart");
		PrintHintTextToAll("%t", "Resume Mix");
	}
	return Action:0;
}

public Action:HalfTReadyMenu(Handle:timer)
{
	if (g_match)
	{
		decl String:item[256];
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				menuhalftready[i] = CreateMenu(HalfTReady, MenuAction:28);
				Format(item, 255, "%t", "Question Continued");
				SetMenuTitle(menuhalftready[i][0][0], item);
				Format(item, 255, "%t", "Yes");
				AddMenuItem(menuhalftready[i][0][0], "Yes", item, 0);
				Format(item, 255, "%t", "No");
				AddMenuItem(menuhalftready[i][0][0], "No", item, 0);
				SetMenuExitButton(menuhalftready[i][0][0], false);
				DisplayMenu(menuhalftready[i][0][0], i, 0);
				i++;
			}
			i++;
		}
	}
	return Action:0;
}

public HalfTReady(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		new String:info[256];
		GetMenuItem(menu, param2, info, 255, 0, "", 0);
		if (StrEqual(info, "Yes", true))
		{
			HalfTReadyPlayers();
		}
		if (StrEqual(info, "No", true))
		{
			HalfTUnreadyPlayers();
		}
	}
	else
	{
		if (action == MenuAction:8)
		{
		}
		else
		{
			if (action == MenuAction:16)
			{
				CloseHandle(menu);
			}
		}
	}
	return 0;
}

/* ERROR! Index was outside the bounds of the array. */
 function "HalfTReadyPlayers" (number 176)

/* ERROR! Index was outside the bounds of the array. */
 function "HalfTUnreadyPlayers" (number 177)

public Action:HalfCTReadyMenu(Handle:timer)
{
	if (g_match)
	{
		decl String:item[256];
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				menuhalfctready[i] = CreateMenu(HalfCTReady, MenuAction:28);
				Format(item, 255, "%t", "Question Continued");
				SetMenuTitle(menuhalfctready[i][0][0], item);
				Format(item, 255, "%t", "Yes");
				AddMenuItem(menuhalfctready[i][0][0], "Yes", item, 0);
				Format(item, 255, "%t", "No");
				AddMenuItem(menuhalfctready[i][0][0], "No", item, 0);
				SetMenuExitButton(menuhalfctready[i][0][0], false);
				DisplayMenu(menuhalfctready[i][0][0], i, 0);
				i++;
			}
			i++;
		}
	}
	return Action:0;
}

public HalfCTReady(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		new String:info[256];
		GetMenuItem(menu, param2, info, 255, 0, "", 0);
		if (StrEqual(info, "Yes", true))
		{
			HalfCTReadyPlayers();
		}
		if (StrEqual(info, "No", true))
		{
			HalfCTUnreadyPlayers();
		}
	}
	else
	{
		if (action == MenuAction:8)
		{
		}
		else
		{
			if (action == MenuAction:16)
			{
				CloseHandle(menu);
			}
		}
	}
	return 0;
}

/* ERROR! Index was outside the bounds of the array. */
 function "HalfCTReadyPlayers" (number 180)

/* ERROR! Index was outside the bounds of the array. */
 function "HalfCTUnreadyPlayers" (number 181)

public Action:StopRecord(Handle:timer)
{
	if (!g_match)
	{
		ServerCommand("tv_stoprecord");
	}
	return Action:0;
}

public Action:ShowDamage(Handle:timer, dead_only)
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (user_damage[i][0][0][0])
		{
			PrintToConsole(i, user_damage[i][0][0]);
			user_damage[i][0][0][0] = 0;
			i++;
		}
		i++;
	}
	return Action:0;
}

public Action:SpecNextFake(Handle:timer, client)
{
	ResetSwitchCameraTimer(client, false);
	if (IsClientInGame(client))
	{
		SpecNext(client, 0.4);
	}
	return Action:0;
}

public Action:SetSpecTimer(Handle:timer, client)
{
	if (IsClientInGame(client))
	{
		FakeClientCommandEx(client, "spec_next");
		FakeClientCommandEx(client, "spec_mode 1");
		if (!mmws_fade_to_black)
		{
			mmws_fade_to_black = FindConVar("mp_fadetoblack");
		}
		if (mmws_fade_to_black)
		{
			new targets[2];
			targets[0] = client;
			new Handle:message = StartMessage("Fade", targets, 1, 1);
			BfWriteShort(message, 1536);
			BfWriteShort(message, 1536);
			BfWriteShort(message, 17);
			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
			EndMessage();
		}
	}
	return Action:0;
}

ResetPlayerStats(client)
{
	new i;
	while (i < 28)
	{
		new x;
		while (x < 15)
		{
			weapon_stats[client][0][0][i][x] = 0;
			x++;
		}
		i++;
	}
	return 0;
}

LogPlayers()
{
	new String:player_name[32];
	new String:authid[32];
	new String:team[32];
	new String:authip[32];
	new i = 1;
	while (i < MaxClients)
	{
		if (IsClientInGame(i))
		{
			GetClientName(i, player_name, 32);
			GetClientAuthString(i, authid, 32);
			GetClientIP(i, authip, 32, true);
			if (!(GetClientTeam(i) == 2))
			{
				if (GetClientTeam(i) == 3)
				{
				}
				else
				{
					if (GetClientTeam(i) == 1)
					{
					}
				}
			}
			Log2Game("\"PLAYER STATUS\" \"%s [%s][IP: %s][%s]\"", player_name, authid, authip, team);
			i++;
		}
		i++;
	}
	return 0;
}

Log2Game(String:Format[])
{
	decl String:buffer[1024];
	VFormat(buffer, 1024, Format, 2);
	if (g_log_file)
	{
		LogToOpenFileEx(g_log_file, buffer);
	}
	return 0;
}

public Action:RemoveRagdoll(Handle:timer, victim)
{
	if (IsValidEntity(victim))
	{
		new player_ragdoll = GetEntDataEnt2(victim, g_i_ragdolls);
		if (player_ragdoll != -1)
		{
			RemoveEdict(player_ragdoll);
		}
	}
	return Action:0;
}

public Action:MessageHandler(UserMsg:msg_id, Handle:bf, players[], playersNum, bool:reliable, bool:init)
{
	new String:msg_name[128];
	GetUserMessageName(msg_id, msg_name, 128);
	new String:message[256];
	BfReadString(bf, message, 256, false);
	new String:msg[256];
	Format(msg, 256, "%s", message[0]);
	TrimString(msg);
	if (GetConVarBool(mmws_remove_gren_sound))
	{
		PrintToServer("Incoming: %s", message);
		if (StrEqual(message, "Radio.FireInTheHole", false))
		{
			return Action:3;
		}
	}
	else
	{
		if (GetConVarBool(mmws_remove_hint_text))
		{
			if (message[0] == '#')
			{
				return Action:3;
			}
		}
	}
	return Action:0;
}

public Action:RestartRound(Handle:timer, delay)
{
	ServerCommand("mp_restartgame %d", delay);
	return Action:0;
}

public Action:CPrintToChatDelayed(Handle:timer, Handle:datapack)
{
	decl String:text[128];
	ResetPack(datapack, false);
	ReadPackString(datapack, text, 128);
	ServerCommand("say %s", text);
	return Action:0;
}

public Action:RespawnPlayer(Handle:timer, client)
{
	CS_RespawnPlayer(client);
	SetEntData(client, g_i_account, GetConVarInt(mmws_mp_startmoney), 4, false);
	return Action:0;
}

public Action:AutoFSTimer(Handle:timer)
{
	if (GetConVarInt(mmws_CvarAutoForceKnife) == 1)
	{
		afknife = 1;
		afstart = 0;
		knife = 1;
		knifeenable = 1;
	}
	if (GetConVarInt(mmws_CvarAutoForceStart) == 1)
	{
		if (!(GetConVarInt(mmws_CvarAutoForceKnife)))
		{
			afstart = 1;
			afknife = 0;
		}
		autofsdelay = GetConVarInt(mmws_CvarAutoStartDelay);
	}
	return Action:0;
}

public Action:SpecAll(client, args)
{
	if (!g_match)
	{
		knife = 0;
		knifeenable = 0;
		CS_SpawnSpectator();
	}
	else
	{
		if (!g_match)
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t {fullred}%d {aliceblue}%t. {fullred}%t", infotitle, "Players Min", GetConVarInt(mmws_min_ready) + -2, "Players", "Spec Move Denied");
		}
	}
	return Action:0;
}

GetRandomPlayer(team)
{
	new clients[MaxClients + 1];
	new clientCount;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			clientCount++;
			clients[clientCount] = i;
			i++;
		}
		i++;
	}
	if (clientCount)
	{
		var2 = clients[GetRandomInt(0, clientCount + -1)];
	}
	else
	{
		var2 = -1;
	}
	return var2;
}

public Action:AutoForceKnife(Handle:timer, client)
{
	new String:namet[32];
	GetConVarString(mmws_t, namet, 32);
	new String:namect[32];
	GetConVarString(mmws_ct, namect, 32);
	if (!g_match)
	{
		if (GetConVarInt(mmws_CvarWaitSelectTeam))
		{
			PrintHintTextToAll("%t", "Waiting Players Connect", CS_ReadyPlayersKnife(), GetConVarInt(mmws_min_ready));
		}
		else
		{
			if (GetConVarInt(mmws_CvarWaitSelectTeam) == 1)
			{
				PrintHintTextToAll("%t", "Waiting Players Connect", CS_ReadyPlayersKnifeWait(), GetConVarInt(mmws_min_ready));
			}
			if (GetConVarInt(mmws_CvarWaitSelectTeam))
			{
				knife = 0;
				knifeenable = 0;
				CS_SpawnSpectator();
			}
			if (GetConVarInt(mmws_CvarWaitSelectTeam) == 1)
			{
				knife = 0;
				knifeenable = 0;
				CS_SpawnSpectator();
			}
			if (!knife)
			{
				if (!knifeselectdelay2)
				{
					knifeselectdelay2 = 5;
				}
				knifeselectdelay2 -= 1;
				if (knifeselectdelay)
				{
					knifeselectdelay = 30;
				}
				if (knifeselectdelay > 0)
				{
					knifeselectdelay -= 1;
				}
				new String:counter_t_name[64];
				new String:counter_ct_name[64];
				if (CS_GetPlayingCTCount() < 1)
				{
					PrintHintTextToAll("%t", "Waiting Knife Connect", knifeselectdelay);
					if (knifeselectdelay)
					{
						new counter_t = GetRandomPlayer(1);
						GetClientName(counter_t, counter_t_name, 64);
						if (counter_t != -1)
						{
							ChangeClientTeam(counter_t, 2);
							CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {lime}%s {aliceblue}%t", infotitle, "1 Player", counter_t_name, "T Knife Select");
						}
						new counter_ct = GetRandomPlayer(1);
						GetClientName(counter_ct, counter_ct_name, 64);
						if (counter_ct != -1)
						{
							ChangeClientTeam(counter_ct, 3);
							CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {lime}%s {aliceblue}%t", infotitle, "1 Player", counter_ct_name, "CT Knife Select");
						}
					}
					knifeselect = 0;
					mmws_knife = 0;
					afknifego = 0;
				}
				else
				{
					if (CS_GetPlayingCTCount() > 0)
					{
						PrintHintTextToAll("%t", "Waiting T Knife", knifeselectdelay);
						if (knifeselectdelay)
						{
							new counter_t = GetRandomPlayer(1);
							GetClientName(counter_t, counter_t_name, 64);
							if (counter_t != -1)
							{
								ChangeClientTeam(counter_t, 2);
								CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {lime}%s {aliceblue}%t", infotitle, "1 Player", counter_t_name, "T Knife Select");
							}
						}
						knifeselect = 0;
						mmws_knife = 0;
						afknifego = 0;
					}
					if (CS_GetPlayingCTCount() < 1)
					{
						if (knifeselectdelay)
						{
							new counter_ct = GetRandomPlayer(1);
							GetClientName(counter_ct, counter_ct_name, 64);
							if (counter_ct != -1)
							{
								ChangeClientTeam(counter_ct, 3);
								CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {lime}%s {aliceblue}%t", infotitle, "1 Player", counter_ct_name, "CT Knife Select");
							}
						}
						PrintHintTextToAll("%t", "Waiting CT Knife", knifeselectdelay);
						knifeselect = 0;
						mmws_knife = 0;
						afknifego = 0;
					}
					if (CS_GetPlayingCTCount() > 0)
					{
						if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
						{
							ServerCommand("hostname \"%s\"", hostnameupdate);
							Format(hostnamenew, 256, "%s [%s]", hostnameupdate, Status_Knife);
							ServerCommand("hostname \"%s\"", hostnamenew);
						}
						PrintHintTextToAll("%t", "Knife Round");
						if (!afknifego)
						{
							CreateTimer(18, TimersAFKStatus, any:0, 2);
							ServerCommand("mp_restartgame 5");
							knifeselect = 1;
							mmws_knife = 1;
							afknifego = 1;
						}
					}
				}
			}
		}
	}
	else
	{
		mmws_knife = 0;
		afknife = 0;
	}
	return Action:3;
}

public Action:TimersAFKStatus(Handle:Timer)
{
	new i = 1;
	while (i <= MaxClients)
	{
		TimeAFK[i] = 0;
		i++;
	}
	CreateTimer(0.5, Timer_UpdateView, any:0, 2);
	CreateTimer(1, Timer_CheckPlayers, any:0, 2);
	return Action:0;
}

public Action:Timer_UpdateView(Handle:Timer)
{
	if (afknifego)
	{
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				GetPlayerEye(i, g_Position[i][0][0]);
				i++;
			}
			i++;
		}
		CreateTimer(0.5, Timer_UpdateView, any:0, 2);
	}
	return Action:0;
}

public Action:Timer_CheckPlayers(Handle:Timer)
{
	if (afknifego)
	{
		new i = 1;
		while (i < MaxClients)
		{
			if (IsClientInGame(i))
			{
				CheckForAFK(i);
				HandleAFKClient(i);
				i++;
			}
			i++;
		}
		CreateTimer(1, Timer_CheckPlayers, any:0, 2);
	}
	return Action:0;
}

CheckForAFK(client)
{
	new Float:f_Loc[3] = 0;
	new bool:f_SamePlace[3];
	GetPlayerEye(client, f_Loc);
	new i;
	while (i < 3)
	{
		if (g_Position[client][0][0][i] == f_Loc[i])
		{
			f_SamePlace[i] = 1;
			i++;
		}
		else
		{
			f_SamePlace[i] = 0;
			i++;
		}
		i++;
	}
	if (f_SamePlace[0])
	{
		TimeAFK[client]++;
	}
	else
	{
		TimeAFK[client] = 0;
	}
	return 0;
}

HandleAFKClient(client)
{
	decl String:f_Name[32];
	GetClientName(client, f_Name, 32);
	CheckForAFK(client);
	if (afknifego)
	{
		CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Knife AFK", f_Name);
		KickClient(client, "*%s* Info: ", infotitle, "Kick AFK");
	}
	return 0;
}

bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3] = 0;
	new Float:vOrigin[3] = 0;
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, 1174421507, RayType:1, TraceEntityFilterPlayer, any:0);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients();
}

public Action:AutoForceStart(Handle:timer, client)
{
	new String:namet[32];
	GetConVarString(mmws_t, namet, 32);
	new String:namect[32];
	GetConVarString(mmws_ct, namect, 32);
	if (!g_match)
	{
		if (GetConVarInt(mmws_min_ready) <= CS_GetPlayingTCount() + CS_GetPlayingCTCount())
		{
			if (GetConVarInt(mmws_CvarAutoStartDelay) == autofsdelay)
			{
				CheckPlayers();
			}
			autofsdelay -= 1;
			if (GetConVarInt(mmws_CvarAutoStartDelay) + -6 < autofsdelay)
			{
				PrintHintTextToAll("Провека статусов игроков...");
			}
			if (GetConVarInt(mmws_CvarAutoStartDelay) + -6 == autofsdelay)
			{
				players_ready = 0;
				new i = 1;
				while (i <= MaxClients)
				{
					if (IsClientInGame(i))
					{
						menuready[i] = CreateMenu(PlayersReady, MenuAction:28);
						SetMenuTitle(menuready[i][0][0], "Готовы к миксу?");
						AddMenuItem(menuready[i][0][0], "Yes", "Да", 0);
						AddMenuItem(menuready[i][0][0], "No", "Нет", 0);
						SetMenuExitButton(menuready[i][0][0], false);
						DisplayMenu(menuready[i][0][0], i, GetConVarInt(mmws_CvarAutoStartDelay) + -6);
						i++;
					}
					i++;
				}
			}
			if (autofsdelay > 0)
			{
				PrintHintTextToAll("%t", "Waiting Live", players_ready, autofsdelay);
			}
			if (autofsdelay)
			{
			}
			else
			{
				afstart = 0;
				autofsdelay = GetConVarInt(mmws_CvarAutoStartDelay);
				ServerCommand("forcestart");
				PrintHintTextToAll("%t", "Mix Begin");
			}
		}
		else
		{
			if (CS_GetPlayersCount() < 7)
			{
				if (Timers)
				{
					KillTimer(Timers, false);
					Timers = 0;
				}
				if (TimersKnife)
				{
					KillTimer(TimersKnife, false);
					TimersKnife = 0;
				}
				afknife = 0;
				knifeenable = 0;
				knife = 0;
				afknifego = 0;
				afstart = 0;
				astop = 0;
				if (GetConVarInt(mmws_CvarAutoForceKnife) == 1)
				{
					afknife = 1;
					knifeenable = 1;
					afstart = 0;
					knife = 1;
					TimersKnife = CreateTimer(0.2, AutoForceKnife, any:0, 1);
				}
				if (GetConVarInt(mmws_CvarAutoForceStart) == 1)
				{
					Timers = CreateTimer(1, AutoForceStart, any:0, 1);
					if (!(GetConVarInt(mmws_CvarAutoForceKnife)))
					{
						afstart = 1;
					}
					autofsdelay = GetConVarInt(mmws_CvarAutoStartDelay);
				}
				CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Change To Waiting");
			}
			PrintHintTextToAll("%t", "Waiting Ready Mix", namet, CS_GetPlayingTCount(), namect, CS_GetPlayingCTCount());
			autofsdelay = GetConVarInt(mmws_CvarAutoStartDelay);
			afstart = 1;
		}
	}
	else
	{
		autofsdelay = GetConVarInt(mmws_CvarAutoStartDelay);
		afstart = 0;
	}
	return Action:3;
}

public Action:ShowPluginInfo(Handle:timer, client)
{
	if (client)
	{
		new Handle:wiki = CreateKeyValues("data", "", "");
		KvSetString(wiki, "title", "WIKI MixWars");
		KvSetNum(wiki, "type", 2);
		KvSetString(wiki, "msg", "http://wiki.mixwars.eu/index.php");
		ShowVGUIPanel(client, "info", wiki, false);
		CloseHandle(wiki);
	}
	if (client)
	{
		if (CheckAdminForChat(client))
		{
			CPrintToChat(client, "{aliceblue}*** Информация {lime}Match&Mix Wars System");
			CPrintToChat(client, "{aliceblue}*** Автоматизированная система управления миксами MMWS {lime}v.%s", "5.26");
			CPrintToChat(client, "{aliceblue}*** Список доступных команд указан в консоле");
			if (!license)
			{
				CPrintToChat(client, "{aliceblue}*** Для получения информации о системе введите {lime}/info");
			}
			PrintToConsole(client, "******************** MMWS Information ********************");
			PrintToConsole(client, "На сервере работает Автоматизированная система управления миксами MMWS v.%s", "5.26");
			PrintToConsole(client, "");
			PrintToConsole(client, "Created by MixWars (mixwars.eu)");
			PrintToConsole(client, "");
			PrintToConsole(client, "Команды:");
			PrintToConsole(client, "  /forcestart или /fs - Запуск микса без ожидания");
			PrintToConsole(client, "  /forceend или /fe - Остановка микса");
			PrintToConsole(client, "  /resetmix - Остановка микса и возврат в состояние набора команд");
			PrintToConsole(client, "  /spec - Перемещение всех игроков в наблюдатели (работает когда на сервере 8 и более игроков)");
			PrintToConsole(client, "  /recordstart или /rs - запись SourceTV демки во время набора микса (во время микса команда отключена)");
			PrintToConsole(client, "  /recordend или /re - остановка записи SourceTV демки во время набора микса (во время микса команда отключена)");
			PrintToConsole(client, "");
			PrintToConsole(client, "  /sub или /replace - Запрос замены (если на сервере есть наблюдатель и в командах по 5 игроков)");
			PrintToConsole(client, "  /top - Статистика игроков");
			PrintToConsole(client, "  /rank - Личная Статистика игрока");
			PrintToConsole(client, "  /help - Страница помощи игрокам (если подключена владельцем сервера)");
			PrintToConsole(client, "  /info - Информация об установленной Системе миксов MMWS");
			PrintToConsole(client, "  /handsup - Включение WaveWars HandsUp&DanceMix iNet Radio (работает только во время набора микса)");
			PrintToConsole(client, "  /pop - Включение WaveWars Pop iNet Radio (работает только во время набора микса)");
			PrintToConsole(client, "  /radiomenu или /rm - Настройка WaveWars iNet Radio (работает только во время набора микса)");
			PrintToConsole(client, "  /radiooff или /off - Отключение WaveWars iNet Radio");
			PrintToConsole(client, "  /admins - Список админов на сервере");
			PrintToConsole(client, "**************************************************************");
		}
		CPrintToChat(client, "{aliceblue}*** Информация {lime}Match&Mix Wars System");
		CPrintToChat(client, "{aliceblue}*** Автоматизированная система управления миксами MMWS {lime}v.%s", "5.26");
		CPrintToChat(client, "{aliceblue}*** Список доступных команд указан в консоле");
		if (!license)
		{
			CPrintToChat(client, "{aliceblue}*** Для получения информации о системе введите {lime}/info");
		}
		PrintToConsole(client, "******************** MMWS Information ********************");
		PrintToConsole(client, "На сервере работает Автоматизированная система управления миксами MMWS v.%s", "5.26");
		PrintToConsole(client, "");
		PrintToConsole(client, "Created by MixWars (mixwars.eu)");
		PrintToConsole(client, "");
		PrintToConsole(client, "Команды:");
		PrintToConsole(client, "  /sub или /replace - Запрос замены (если на сервере есть наблюдатель и в командах по 5 игроков)");
		PrintToConsole(client, "  /top - Статистика игроков");
		PrintToConsole(client, "  /rank - Личная Статистика игрока");
		PrintToConsole(client, "  /help - Страница помощи игрокам (если подключена владельцем сервера)");
		PrintToConsole(client, "  /info - Информация об установленной Системе миксов MMWS");
		PrintToConsole(client, "  /handsup - Включение WaveWars HandsUp&DanceMix iNet Radio (работает только во время набора микса)");
		PrintToConsole(client, "  /pop - Включение WaveWars Pop iNet Radio (работает только во время набора микса)");
		PrintToConsole(client, "  /radiomenu или /rm - Настройка WaveWars iNet Radio (работает только во время набора микса)");
		PrintToConsole(client, "  /radiooff или /off - Отключение WaveWars iNet Radio");
		PrintToConsole(client, "  /admins - Список админов на сервере");
		PrintToConsole(client, "**************************************************************");
	}
	return Action:0;
}

public Action:ShowAdverts(Handle:timer, client)
{
	if (client)
	{
		CPrintToChat(client, "{aliceblue}*** Информация {lime}Match&Mix Wars System");
		CPrintToChat(client, "{aliceblue}*** До {lime}1 сентября {aliceblue}администраторы серверов могут получить");
		CPrintToChat(client, "{aliceblue}*** ключ для активации {lime}ПОЛНОЙ {aliceblue}версии {lime}АБСОЛЮТНО БЕСПЛАТНО!!!");
		CPrintToChat(client, "{aliceblue}*** Для получения информации о системе введите {lime}/info");
	}
	return Action:0;
}

bool:CheckAdminForChat(client)
{
	new AdminId:aid = GetUserAdmin(client);
	if (aid == AdminId:-1)
	{
		return false;
	}
	return GetAdminFlag(aid, AdminFlag:9, AdmAccessMode:1);
}

UpdateStatusMMWS()
{
	new value;
	if (!g_match)
	{
		if (!mmws_knife)
		{
			if (!g_ready_enabled)
			{
				if (!mmws_had_knife)
				{
					value = 0;
				}
				else
				{
					value = 3;
				}
			}
			else
			{
				if (!mmws_had_knife)
				{
					value = 1;
				}
				value = 4;
			}
		}
		else
		{
			value = 2;
		}
	}
	else
	{
		if (!g_live)
		{
			if (!g_ready_enabled)
			{
				if (g_first_half)
				{
					value = 3;
				}
				else
				{
					value = 6;
				}
			}
			else
			{
				if (g_first_half)
				{
					value = 4;
				}
				value = 7;
			}
		}
		if (g_first_half)
		{
			value = 5;
		}
		value = 8;
	}
	SetConVarIntHidden(mmws_status, value);
	return value;
}

GetFrags(client)
{
	if (g_i_frags == -1)
	{
		return GetEntData(client, g_i_frags, 4);
	}
	return 0;
}

SetFrags(client, frags)
{
	if (g_i_frags == -1)
	{
		SetEntData(client, g_i_frags, frags, 4, false);
	}
	return 0;
}

SpecNext(client, Float:time)
{
	new client_team = GetClientTeam(client);
	new target = GetEntPropEnt(client, PropType:0, "m_hObserverTarget", 0);
	new last_target = GetLastTarget(client_team);
	new new_target = -1;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			new_target = i;
			if (new_target > target)
			{
				if (new_target != -1)
				{
					if (time > 0.1)
					{
						SpecTarget_Delayed(client, new_target, time);
					}
					SpecTarget(client, new_target);
				}
				return 0;
			}
			i++;
		}
		i++;
	}
	if (new_target != -1)
	{
		if (time > 0.1)
		{
			SpecTarget_Delayed(client, new_target, time);
		}
		SpecTarget(client, new_target);
	}
	return 0;
}

SpecPrev(client, Float:time)
{
	new client_team = GetClientTeam(client);
	new target = GetEntPropEnt(client, PropType:0, "m_hObserverTarget", 0);
	new first_target = GetFirstTarget(client_team);
	new last_target = GetLastTarget(client_team);
	new new_target = -1;
	if (first_target == target)
	{
		new_target = last_target;
	}
	else
	{
		new i = MaxClients + -1;
		while (i >= 1)
		{
			if (IsClientInGame(i))
			{
				new_target = i;
				if (new_target < target)
				{
				}
				i--;
			}
			i--;
		}
	}
	if (new_target != -1)
	{
		if (time > 0.1)
		{
			SpecTarget_Delayed(client, new_target, time);
		}
		SpecTarget(client, new_target);
	}
	return 0;
}

SpecTarget_Delayed(client, target, Float:time)
{
	new Handle:dp;
	CreateDataTimer(time, Timer_SpecTarget, dp, 2);
	WritePackCell(dp, client);
	WritePackCell(dp, target);
	return 0;
}

public Action:Timer_SpecTarget(Handle:timer, Handle:dp)
{
	ResetPack(dp, false);
	new client = ReadPackCell(dp);
	new target = ReadPackCell(dp);
	SpecTarget(client, target);
	return Action:0;
}

SpecTarget(client, target)
{
	SetEntProp(client, PropType:0, "m_iObserverMode", any:4, 4, 0);
	SetEntPropEnt(client, PropType:0, "m_hObserverTarget", target, 0);
	CreateTimer(0.2, Timer_SpecTarget2, client, 2);
	return 0;
}

public Action:Timer_SpecTarget2(Handle:timer, client)
{
	FakeClientCommand(client, "spec_mode 1");
	return Action:0;
}

GetLastTarget(team)
{
	new last;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			last = i;
			i++;
		}
		i++;
	}
	return last;
}

GetFirstTarget(team)
{
	new first;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			first = i;
			return first;
		}
		i++;
	}
	return first;
}

public OnResetMatch()
{
	mmws_RestartPlugin = 1;
	if (!cwstatus)
	{
		if (GetConVarInt(mmws_CvarBanVoteStart) == 1)
		{
			votedelay = 15;
			if (GetConVarInt(mmws_CvarBanVoteMessage) == 1)
			{
				PrintHintTextToAll("%t", "Voting Hint", votedelay);
				CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {lime}%d {aliceblue}%t...", infotitle, "Voting", votedelay, "Seconds");
				CreateTimer(1, VoteMap, any:0, 0);
			}
			CreateTimer(15, MapVote, any:0, 0);
		}
		CreateTimer(90, AutoFSTimer, any:0, 0);
	}
	return 0;
}

public Action:VoteMap(Handle:timer)
{
	votedelay = votedelay + -1;
	PrintHintTextToAll("%t", "Voting Hint", votedelay);
	if (votedelay > 1)
	{
		CreateTimer(1, VoteMap, any:0, 0);
	}
	else
	{
		CreateTimer(1, MapVote, any:0, 0);
	}
	return Action:0;
}

public Action:MapVote(Handle:timer)
{
	PrintHintTextToAll("%t", "Vote Starting");
	InitiateMapChooserVote(MapChange:0, Handle:0);
	return Action:0;
}

public Action:Rank(client, args)
{
	if (license)
	{
		if (mmws_DbStats)
		{
			if (!g_live)
			{
				if (g_bPlyrCanDoMotd[client][0][0])
				{
					new String:client_url[256];
					new String:client_info[256];
					new String:AuthID[256];
					new String:Name[256];
					new ClientID;
					decl String:query[256];
					GetClientAuthString(client, AuthID, 255);
					GetClientName(client, Name, 255);
					ReplaceString(AuthID, 255, "STEAM_0:", "", true);
					Format(query, 255, "SELECT `playerId` FROM `hlstats_PlayerUniqueIds` WHERE `uniqueId` = '%s'", AuthID);
					new Handle:result = SQL_Query(mmws_DbStats, query, -1);
					if (result)
					{
						while (SQL_FetchRow(result))
						{
							ClientID = SQL_FetchInt(result, 0, 0);
						}
						new Handle:mstats = CreateKeyValues("data", "", "");
						new String:url[64];
						GetConVarString(mmws_CvarStatsUrl, url, 64);
						Format(client_url, 255, "http://%s/ingame.php?mode=statsme&game=css&player=%d", url, ClientID);
						Format(client_info, 255, "Статистика игрока %s", Name);
						KvSetString(mstats, "title", client_info);
						KvSetNum(mstats, "type", 2);
						KvSetString(mstats, "msg", client_url);
						ShowVGUIPanel(client, "info", mstats, true);
						CloseHandle(mstats);
					}
					else
					{
						CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Вы еще не внесены в статистику из-за малого онлайна.", infotitle);
						PrintToConsole(client, "Ваш SteamID [%s] не найден в статистике.", AuthID);
					}
				}
				else
				{
					CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Для использования команд {lime}/rank {aliceblue}необходимо включение HTML сообщений в настройках.", infotitle);
					CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Перейдите в НАСТРОЙКИ > СЕТЕВОЙ РЕЖИМ > ДОПОЛНИТЕЛЬНО > Снимите флажок с 'Отключить HTML сообщения дня'.", infotitle);
					CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}После изменения настроек ПЕРЕЗАЙДИТЕ на сервер.", infotitle);
				}
			}
			else
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Команда {lime}/rank {aliceblue}во время микса отключена.", infotitle);
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Используйте команду по окончании микса.", infotitle);
			}
		}
		CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Статистика не подключена.", infotitle);
	}
	return Action:3;
}

public Action:Stats(client, args)
{
	if (license)
	{
		if (mmws_DbStats)
		{
			if (!g_live)
			{
				if (g_bPlyrCanDoMotd[client][0][0])
				{
					new Handle:mstats = CreateKeyValues("data", "", "");
					new String:url[64];
					GetConVarString(mmws_CvarStatsUrl, url, 64);
					Format(url, 64, "http://%s/ingame.php?mode=players&game=css", url);
					KvSetString(mstats, "title", "Статистика игроков");
					KvSetNum(mstats, "type", 2);
					KvSetString(mstats, "msg", url);
					ShowVGUIPanel(client, "info", mstats, true);
					CloseHandle(mstats);
				}
				else
				{
					CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Для использования команд {lime}/top {aliceblue}необходимо включение HTML сообщений в настройках.", infotitle);
					CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Перейдите в НАСТРОЙКИ > СЕТЕВОЙ РЕЖИМ > ДОПОЛНИТЕЛЬНО > Снимите флажок с 'Отключить HTML сообщения дня'.", infotitle);
					CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}После изменения настроек ПЕРЕЗАЙДИТЕ на сервер.", infotitle);
				}
			}
			else
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Команда {lime}/top {aliceblue}во время микса отключена.", infotitle);
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Используйте команду по окончании микса.", infotitle);
			}
		}
		CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Статистика не подключена.", infotitle);
	}
	return Action:3;
}

public Action:Help(client, args)
{
	if (license)
	{
		new String:url[128];
		GetConVarString(mmws_CvarHelpUrl, url, 128);
		if (!StrEqual(url, "", true))
		{
			if (!g_live)
			{
				if (g_bPlyrCanDoMotd[client][0][0])
				{
					new Handle:mhelp = CreateKeyValues("data", "", "");
					Format(url, 128, "http://%s", url);
					KvSetString(mhelp, "title", "Помощь игрокам");
					KvSetNum(mhelp, "type", 2);
					KvSetString(mhelp, "msg", url);
					ShowVGUIPanel(client, "help", mhelp, true);
					CloseHandle(mhelp);
				}
				else
				{
					CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Для использования команды {lime}/help {aliceblue}необходимо включение HTML сообщений в настройках.", infotitle);
					CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Перейдите в НАСТРОЙКИ > СЕТЕВОЙ РЕЖИМ > ДОПОЛНИТЕЛЬНО > Снимите флажок с 'Отключить HTML сообщения дня'.", infotitle);
					CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}После изменения настроек ПЕРЕЗАЙДИТЕ на сервер.", infotitle);
				}
			}
			else
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Команда {lime}/help {aliceblue}во время микса отключена.", infotitle);
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Используйте команду по окончании микса.", infotitle);
			}
		}
		else
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Страница помощи не подключена. Обратитесь к адинистраторам.", infotitle);
		}
	}
	return Action:3;
}

public Action:Info(client, args)
{
	if (!g_live)
	{
		if (g_bPlyrCanDoMotd[client][0][0])
		{
			new Handle:mhelp = CreateKeyValues("data", "", "");
			KvSetString(mhelp, "title", "Информация о системе");
			KvSetNum(mhelp, "type", 2);
			if (CheckAdminForChat(client))
			{
				KvSetString(mhelp, "msg", "http://wiki.mixwars.eu/admins");
			}
			else
			{
				KvSetString(mhelp, "msg", "http://wiki.mixwars.eu/players");
			}
			ShowVGUIPanel(client, "info", mhelp, true);
			CloseHandle(mhelp);
		}
		else
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Для использования команды {lime}/info {aliceblue}необходимо включение HTML сообщений в настройках.", infotitle);
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Перейдите в НАСТРОЙКИ > СЕТЕВОЙ РЕЖИМ > ДОПОЛНИТЕЛЬНО > Снимите флажок с 'Отключить HTML сообщения дня'.", infotitle);
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}После изменения настроек ПЕРЕЗАЙДИТЕ на сервер.", infotitle);
		}
	}
	else
	{
		CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Команда {lime}/info {aliceblue}во время микса отключена.", infotitle);
		CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Используйте команду по окончании микса.", infotitle);
	}
	return Action:3;
}

public Action:RS(client, args)
{
	if (license)
	{
		if (!g_match)
		{
			new String:date[32];
			new String:stv_name[256];
			FormatTime(date, 32, "%Y%m%d_%H%M", -1);
			new String:demofolder[256];
			GetConVarString(mmws_CvarDemoFolder, demofolder, 255);
			if (StrEqual(demofolder, "", true))
			{
				Format(stv_name, 255, "%s_%s_admin", date, g_map);
			}
			else
			{
				Format(stv_name, 255, "%s/%s_%s_admin", demofolder, date, g_map);
			}
			ServerCommand("tv_record %s.dem", stv_name);
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Запись демо {lime}%s {aliceblue}начата.", infotitle, stv_name);
		}
		if (!cwstatus)
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Команда {lime}/rs {aliceblue}во время микса отключена.", infotitle);
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Используйте команду по окончании микса.", infotitle);
		}
	}
	return Action:3;
}

public Action:RE(client, args)
{
	if (license)
	{
		if (!g_match)
		{
			ServerCommand("tv_stoprecord");
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Запись демо остановлена.", infotitle);
		}
		if (!cwstatus)
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Команда {lime}/re {aliceblue}во время микса отключена.", infotitle);
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Используйте команду по окончании микса.", infotitle);
		}
	}
	return Action:3;
}

public Action:Status(client, args)
{
	if (license)
	{
		if (GetConVarInt(mmws_CvarMixOnly))
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Сервер работает только в {lime}MiX {aliceblue}режиме.", infotitle);
		}
		if (!cwstatus)
		{
			cwstatus = 1;
			if (Timers)
			{
				KillTimer(Timers, false);
				Timers = 0;
			}
			if (TimersKnife)
			{
				KillTimer(TimersKnife, false);
				TimersKnife = 0;
			}
			afknife = 0;
			knifeenable = 0;
			knife = 0;
			afknifego = 0;
			afstart = 0;
			astop = 0;
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Сервер переведен в {lime}ClanWars {aliceblue}режим.", infotitle);
			ServerCommand("hostname \"%s\"", hostnameupdate);
		}
		else
		{
			if (cwstatus)
			{
				cwstatus = 0;
				if (GetConVarInt(mmws_CvarAutoForceKnife) == 1)
				{
					afknife = 1;
					knifeenable = 1;
					afstart = 0;
					knife = 1;
					TimersKnife = CreateTimer(0.2, AutoForceKnife, any:0, 1);
				}
				if (GetConVarInt(mmws_CvarAutoForceStart) == 1)
				{
					Timers = CreateTimer(1, AutoForceStart, any:0, 1);
					if (!(GetConVarInt(mmws_CvarAutoForceKnife)))
					{
						afstart = 1;
					}
					autofsdelay = GetConVarInt(mmws_CvarAutoStartDelay);
				}
				ServerCommand("sv_password \"\"");
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Сервер переведен в {lime}MixWars {aliceblue}режим.", infotitle);
				if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
				{
					ServerCommand("hostname \"%s\"", hostnameupdate);
					Format(hostnamenew, 256, "%s [%s]", hostnameupdate, Status_Wait);
					ServerCommand("hostname \"%s\"", hostnamenew);
				}
			}
		}
	}
	return Action:3;
}

public Action:ChangePassword(client, args)
{
	if (cwstatus)
	{
		new String:password[32];
		GetCmdArg(1, password, 32);
		if (0 < strlen(password))
		{
			ServerCommand("sv_password %s", password);
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Установлен пароль: {lime}%s", password);
		}
		else
		{
			ServerCommand("sv_password \"\"");
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Пароль снят.");
		}
	}
	else
	{
		CPrintToChat(client, "{dimgray}*%s* Info: {fullred}Пароль не может быть установлен в режиме MIX.");
	}
	return Action:3;
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (mmws_menu == topmenu)
	{
		return 0;
	}
	mmws_menu = topmenu;
	new TopMenuObject:mmwsmenu = FindTopMenuCategory(mmws_menu, "SystemCommands");
	if (mmwsmenu)
	{
		AddToTopMenu(mmws_menu, "forcestart", TopMenuObjectType:1, MMWSHandler, mmwsmenu, "forcestart", 32768, "");
		AddToTopMenu(mmws_menu, "knife", TopMenuObjectType:1, MMWSHandler, mmwsmenu, "knife", 32768, "");
		AddToTopMenu(mmws_menu, "forceend", TopMenuObjectType:1, MMWSHandler, mmwsmenu, "forceend", 32768, "");
		AddToTopMenu(mmws_menu, "changemode", TopMenuObjectType:1, MMWSHandler, mmwsmenu, "changemode", 32768, "");
	}
	new TopMenuObject:player_commands = FindTopMenuCategory(mmws_menu, "PlayerCommands");
	if (player_commands)
	{
		if (0 < GetConVarInt(mmws_CvarBanEnable))
		{
			AddToTopMenu(mmws_menu, "bans", TopMenuObjectType:1, AdminMenu_Bans, player_commands, "bans", 512, "");
		}
	}
	return 0;
}

DisplayBansMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Bans, MenuAction:28);
	decl String:title[100];
	Format(title, 100, "Причина бана:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	AddMenuItem(menu, "0", "Убийство тиммейтов (3 ч.)", 0);
	AddMenuItem(menu, "1", "Атака тиммейтов (2 ч.)", 0);
	AddMenuItem(menu, "2", "Оскорбление игроков (24 ч.)", 0);
	AddMenuItem(menu, "3", "Неадекватное поведение (6 ч.)", 0);
	AddMenuItem(menu, "4", "Некорректный никнейм (6 ч.)", 0);
	AddMenuItem(menu, "5", "Высокий пинг (30 мин.)", 0);
	AddMenuItem(menu, "6", "AFK (3 ч.)", 0);
	AddMenuItem(menu, "7", "Оскорбление родных(1 месяц)", 0);
	AddMenuItem(menu, "8", "Подозрение на читы(3 дня)", 0);
	DisplayMenu(menu, client, 0);
	return 0;
}

DisplayBansPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_BansPlayer, MenuAction:28);
	decl String:title[100];
	Format(title, 100, "Выбор игрока:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	AddTargetsToMenu(menu, client, true, false);
	DisplayMenu(menu, client, 0);
	return 0;
}

public AdminMenu_Bans(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action)
	{
		if (action == TopMenuAction:2)
		{
			DisplayBansPlayerMenu(param);
		}
	}
	else
	{
		Format(buffer, maxlength, "Выдать БАН", param);
	}
	return 0;
}

public MenuHandler_BansPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction:16)
	{
		CloseHandle(menu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param2 == -6)
			{
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition:3);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:info[32];
			new userid;
			new target;
			GetMenuItem(menu, param2, info, 32, 0, "", 0);
			userid = StringToInt(info, 10);
			target = var2;
			if (var2)
			{
				if (!CanUserTarget(param1, target))
				{
					CPrintToChat(param1, "[SM] Игрок неизвестен");
				}
				BanTarget[param1] = GetClientOfUserId(userid);
				DisplayBansMenu(param1);
			}
			else
			{
				CPrintToChat(param1, "[SM] Игрок больше недоступен");
			}
		}
	}
	return 0;
}

public MenuHandler_Bans(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction:16)
	{
		CloseHandle(menu);
	}
	else
	{
		if (action == MenuAction:8)
		{
			if (param2 == -6)
			{
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition:3);
			}
		}
		if (action == MenuAction:4)
		{
			decl String:info[32];
			new type;
			GetMenuItem(menu, param2, info, 32, 0, "", 0);
			type = StringToInt(info, 10);
			decl String:name[32];
			GetClientName(BanTarget[param1][0][0], name, 32);
			switch (type)
			{
				case 0:
				{
					PerformTK(param1, BanTarget[param1][0][0]);
				}
				case 1:
				{
					PerformTA(param1, BanTarget[param1][0][0]);
				}
				case 2:
				{
					PerformLang(param1, BanTarget[param1][0][0]);
				}
				case 3:
				{
					PerformNeadeq(param1, BanTarget[param1][0][0]);
				}
				case 4:
				{
					PerformNickname(param1, BanTarget[param1][0][0]);
				}
				case 5:
				{
					PerformHP(param1, BanTarget[param1][0][0]);
				}
				case 6:
				{
					PerformAFK(param1, BanTarget[param1][0][0]);
				}
				case 7:
				{
					PerformLangFamily(param1, BanTarget[param1][0][0]);
				}
				case 8:
				{
					PerformCheat(param1, BanTarget[param1][0][0]);
				}
				default:
				{
				}
			}
		}
	}
	return 0;
}

PerformTK(client, target)
{
	new String:query[1024];
	new String:AuthAID[36];
	new String:AuthPID[36];
	new String:AIP[32];
	new String:PIP[32];
	new time = GetTime({0,0});
	decl String:name_admin[32];
	decl String:name_player[32];
	GetClientName(client, name_admin, 32);
	GetClientName(target, name_player, 32);
	GetClientAuthString(client, AuthAID, 34);
	GetClientAuthString(target, AuthPID, 34);
	GetClientIP(target, PIP, 32, true);
	GetClientIP(client, AIP, 32, true);
	if (GetConVarInt(mmws_CvarBanEnable) == 2)
	{
		FormatEx(query, 1024, "INSERT INTO sb_bans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES ('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', (SELECT `aid` FROM sb_admins WHERE `authid` = '%s' LIMIT 0,1), '%s', (SELECT `sid` FROM sb_servers WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1), ' ')", PIP, AuthPID, name_player, 10800, 10800, "Убийство тиммейтов", AuthAID, AIP, s_ServerIP, s_ServerPort);
	}
	else
	{
		if (GetConVarInt(mmws_CvarBanEnable) == 1)
		{
			FormatEx(query, 1024, "INSERT INTO bans (authid, created, ends, length, reason) VALUES ('%s', %d, %d, %d, '%s')", AuthAID, time, time + 10800, 10800, "Убийство тиммейтов");
		}
	}
	SQL_TQuery(h_Database, VerifyInsert, query, any:0, DBPriority:0);
	ServerCommand("sm_kick #%d Вы забанены за убийство тиммейтов", GetClientUserId(target));
	CPrintToChatAll("{dimgray}*%s* Info: {lime}%s {fullred}забанен. {lightslategray}Причина: убийство тиммейтов. Админ: %s.", infotitle, name_player, name_admin);
	return 0;
}

PerformTA(client, target)
{
	new String:query[1024];
	new String:AuthAID[36];
	new String:AuthPID[36];
	new String:AIP[32];
	new String:PIP[32];
	new time = GetTime({0,0});
	decl String:name_admin[32];
	decl String:name_player[32];
	GetClientName(client, name_admin, 32);
	GetClientName(target, name_player, 32);
	GetClientAuthString(client, AuthAID, 34);
	GetClientAuthString(target, AuthPID, 34);
	GetClientIP(target, PIP, 32, true);
	GetClientIP(client, AIP, 32, true);
	if (GetConVarInt(mmws_CvarBanEnable) == 2)
	{
		FormatEx(query, 1024, "INSERT INTO sb_bans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES ('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', (SELECT `aid` FROM sb_admins WHERE `authid` = '%s' LIMIT 0,1), '%s', (SELECT `sid` FROM sb_servers WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1), ' ')", PIP, AuthPID, name_player, 7200, 7200, "Стрельба по тиммейтам", AuthAID, AIP, s_ServerIP, s_ServerPort);
	}
	else
	{
		if (GetConVarInt(mmws_CvarBanEnable) == 1)
		{
			FormatEx(query, 1024, "INSERT INTO bans (authid, created, ends, length, reason) VALUES ('%s', %d, %d, %d, '%s')", AuthAID, time, time + 7200, 7200, "Стрельба по тиммейтам");
		}
	}
	SQL_TQuery(h_Database, VerifyInsert, query, any:0, DBPriority:0);
	ServerCommand("sm_kick #%d Вы забанены за стрельбу по тиммейтам", GetClientUserId(target));
	CPrintToChatAll("{dimgray}*%s* Info: {lime}%s {fullred}забанен. {lightslategray}Причина: стрельба по тиммейтам. Админ: %s.", infotitle, name_player, name_admin);
	return 0;
}

PerformLang(client, target)
{
	new String:query[1024];
	new String:AuthAID[36];
	new String:AuthPID[36];
	new String:AIP[32];
	new String:PIP[32];
	new time = GetTime({0,0});
	decl String:name_admin[32];
	decl String:name_player[32];
	GetClientName(client, name_admin, 32);
	GetClientName(target, name_player, 32);
	GetClientAuthString(client, AuthAID, 34);
	GetClientAuthString(target, AuthPID, 34);
	GetClientIP(target, PIP, 32, true);
	GetClientIP(client, AIP, 32, true);
	if (GetConVarInt(mmws_CvarBanEnable) == 2)
	{
		FormatEx(query, 1024, "INSERT INTO sb_bans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES ('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', (SELECT `aid` FROM sb_admins WHERE `authid` = '%s' LIMIT 0,1), '%s', (SELECT `sid` FROM sb_servers WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1), ' ')", PIP, AuthPID, name_player, 86400, 86400, "Оскорбление игроков", AuthAID, AIP, s_ServerIP, s_ServerPort);
	}
	else
	{
		if (GetConVarInt(mmws_CvarBanEnable) == 1)
		{
			FormatEx(query, 1024, "INSERT INTO bans (authid, created, ends, length, reason) VALUES ('%s', %d, %d, %d, '%s')", AuthAID, time, time + 86400, 86400, "Оскорбление игроков");
		}
	}
	SQL_TQuery(h_Database, VerifyInsert, query, any:0, DBPriority:0);
	ServerCommand("sm_kick #%d Вы забанены за оскорбление игроков", GetClientUserId(target));
	CPrintToChatAll("{dimgray}*%s* Info: {lime}%s {fullred}забанен. {lightslategray}Причина: оскорбление игроков. Админ: %s.", infotitle, name_player, name_admin);
	return 0;
}

PerformNeadeq(client, target)
{
	new String:query[1024];
	new String:AuthAID[36];
	new String:AuthPID[36];
	new String:AIP[32];
	new String:PIP[32];
	new time = GetTime({0,0});
	decl String:name_admin[32];
	decl String:name_player[32];
	GetClientName(client, name_admin, 32);
	GetClientName(target, name_player, 32);
	GetClientAuthString(client, AuthAID, 34);
	GetClientAuthString(target, AuthPID, 34);
	GetClientIP(target, PIP, 32, true);
	GetClientIP(client, AIP, 32, true);
	if (GetConVarInt(mmws_CvarBanEnable) == 2)
	{
		FormatEx(query, 1024, "INSERT INTO sb_bans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES ('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', (SELECT `aid` FROM sb_admins WHERE `authid` = '%s' LIMIT 0,1), '%s', (SELECT `sid` FROM sb_servers WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1), ' ')", PIP, AuthPID, name_player, 21600, 21600, "Неадекватное поведение", AuthAID, AIP, s_ServerIP, s_ServerPort);
	}
	else
	{
		if (GetConVarInt(mmws_CvarBanEnable) == 1)
		{
			FormatEx(query, 1024, "INSERT INTO bans (authid, created, ends, length, reason) VALUES ('%s', %d, %d, %d, '%s')", AuthAID, time, time + 21600, 21600, "Неадекватное поведение");
		}
	}
	SQL_TQuery(h_Database, VerifyInsert, query, any:0, DBPriority:0);
	ServerCommand("sm_kick #%d Вы забанены за неадекватное поведение", GetClientUserId(target));
	CPrintToChatAll("{dimgray}*%s* Info: {lime}%s {fullred}забанен. {lightslategray}Причина: неадекватное поведение. Админ: %s.", infotitle, name_player, name_admin);
	return 0;
}

PerformNickname(client, target)
{
	new String:query[1024];
	new String:AuthAID[36];
	new String:AuthPID[36];
	new String:AIP[32];
	new String:PIP[32];
	new time = GetTime({0,0});
	decl String:name_admin[32];
	decl String:name_player[32];
	GetClientName(client, name_admin, 32);
	GetClientName(target, name_player, 32);
	GetClientAuthString(client, AuthAID, 34);
	GetClientAuthString(target, AuthPID, 34);
	GetClientIP(target, PIP, 32, true);
	GetClientIP(client, AIP, 32, true);
	if (GetConVarInt(mmws_CvarBanEnable) == 2)
	{
		FormatEx(query, 1024, "INSERT INTO sb_bans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES ('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', (SELECT `aid` FROM sb_admins WHERE `authid` = '%s' LIMIT 0,1), '%s', (SELECT `sid` FROM sb_servers WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1), ' ')", PIP, AuthPID, name_player, 21600, 21600, "Некорректный никнейм", AuthAID, AIP, s_ServerIP, s_ServerPort);
	}
	else
	{
		if (GetConVarInt(mmws_CvarBanEnable) == 1)
		{
			FormatEx(query, 1024, "INSERT INTO bans (authid, created, ends, length, reason) VALUES ('%s', %d, %d, %d, '%s')", AuthAID, time, time + 21600, 21600, "Некорректный никнейм");
		}
	}
	SQL_TQuery(h_Database, VerifyInsert, query, any:0, DBPriority:0);
	ServerCommand("sm_kick #%d Вы забанены за некорректный никнейм", GetClientUserId(target));
	CPrintToChatAll("{dimgray}*%s* Info: {lime}%s {fullred}забанен. {lightslategray}Причина: некорректный никнейм. Админ: %s.", infotitle, name_player, name_admin);
	return 0;
}

PerformHP(client, target)
{
	new String:query[1024];
	new String:AuthAID[36];
	new String:AuthPID[36];
	new String:AIP[32];
	new String:PIP[32];
	new time = GetTime({0,0});
	decl String:name_admin[32];
	decl String:name_player[32];
	GetClientName(client, name_admin, 32);
	GetClientName(target, name_player, 32);
	GetClientAuthString(client, AuthAID, 34);
	GetClientAuthString(target, AuthPID, 34);
	GetClientIP(target, PIP, 32, true);
	GetClientIP(client, AIP, 32, true);
	if (GetConVarInt(mmws_CvarBanEnable) == 2)
	{
		FormatEx(query, 1024, "INSERT INTO sb_bans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES ('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', (SELECT `aid` FROM sb_admins WHERE `authid` = '%s' LIMIT 0,1), '%s', (SELECT `sid` FROM sb_servers WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1), ' ')", PIP, AuthPID, name_player, 1800, 1800, "Высокий пинг", AuthAID, AIP, s_ServerIP, s_ServerPort);
	}
	else
	{
		if (GetConVarInt(mmws_CvarBanEnable) == 1)
		{
			FormatEx(query, 1024, "INSERT INTO bans (authid, created, ends, length, reason) VALUES ('%s', %d, %d, %d, '%s')", AuthAID, time, time + 1800, 1800, "Высокий пинг");
		}
	}
	SQL_TQuery(h_Database, VerifyInsert, query, any:0, DBPriority:0);
	ServerCommand("sm_kick #%d Вы забанены за высокий пинг", GetClientUserId(target));
	CPrintToChatAll("{dimgray}*%s* Info: {lime}%s {fullred}забанен. {lightslategray}Причина: высокий пинг. Админ: %s.", infotitle, name_player, name_admin);
	return 0;
}

PerformAFK(client, target)
{
	new String:query[1024];
	new String:AuthAID[36];
	new String:AuthPID[36];
	new String:AIP[32];
	new String:PIP[32];
	new time = GetTime({0,0});
	decl String:name_admin[32];
	decl String:name_player[32];
	GetClientName(client, name_admin, 32);
	GetClientName(target, name_player, 32);
	GetClientAuthString(client, AuthAID, 34);
	GetClientAuthString(target, AuthPID, 34);
	GetClientIP(target, PIP, 32, true);
	GetClientIP(client, AIP, 32, true);
	if (GetConVarInt(mmws_CvarBanEnable) == 2)
	{
		FormatEx(query, 1024, "INSERT INTO sb_bans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES ('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', (SELECT `aid` FROM sb_admins WHERE `authid` = '%s' LIMIT 0,1), '%s', (SELECT `sid` FROM sb_servers WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1), ' ')", PIP, AuthPID, name_player, 10800, 10800, "AFK", AuthAID, AIP, s_ServerIP, s_ServerPort);
	}
	else
	{
		if (GetConVarInt(mmws_CvarBanEnable) == 1)
		{
			FormatEx(query, 1024, "INSERT INTO bans (authid, created, ends, length, reason) VALUES ('%s', %d, %d, %d, '%s')", AuthAID, time, time + 10800, 10800, "AFK");
		}
	}
	SQL_TQuery(h_Database, VerifyInsert, query, any:0, DBPriority:0);
	ServerCommand("sm_kick #%d Вы забанены за AFK", GetClientUserId(target));
	CPrintToChatAll("{dimgray}*%s* Info: {lime}%s {fullred}забанен. {lightslategray}Причина: AFK. Админ: %s.", infotitle, name_player, name_admin);
	return 0;
}

PerformLangFamily(client, target)
{
	new String:query[1024];
	new String:AuthAID[36];
	new String:AuthPID[36];
	new String:AIP[32];
	new String:PIP[32];
	new time = GetTime({0,0});
	decl String:name_admin[32];
	decl String:name_player[32];
	GetClientName(client, name_admin, 32);
	GetClientName(target, name_player, 32);
	GetClientAuthString(client, AuthAID, 34);
	GetClientAuthString(target, AuthPID, 34);
	GetClientIP(target, PIP, 32, true);
	GetClientIP(client, AIP, 32, true);
	if (GetConVarInt(mmws_CvarBanEnable) == 2)
	{
		FormatEx(query, 1024, "INSERT INTO sb_bans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES ('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', (SELECT `aid` FROM sb_admins WHERE `authid` = '%s' LIMIT 0,1), '%s', (SELECT `sid` FROM sb_servers WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1), ' ')", PIP, AuthPID, name_player, 2592000, 2592000, "Оскорбление родных", AuthAID, AIP, s_ServerIP, s_ServerPort);
	}
	else
	{
		if (GetConVarInt(mmws_CvarBanEnable) == 1)
		{
			FormatEx(query, 1024, "INSERT INTO bans (authid, created, ends, length, reason) VALUES ('%s', %d, %d, %d, '%s')", AuthAID, time, time + 2592000, 2592000, "Оскорбление родных");
		}
	}
	SQL_TQuery(h_Database, VerifyInsert, query, any:0, DBPriority:0);
	ServerCommand("sm_kick #%d Вы забанены за оскорбление родных", GetClientUserId(target));
	CPrintToChatAll("{dimgray}*%s* Info: {lime}%s {fullred}забанен. {lightslategray}Причина: оскорбление родных. Админ: %s.", infotitle, name_player, name_admin);
	return 0;
}

PerformCheat(client, target)
{
	new String:query[1024];
	new String:AuthAID[36];
	new String:AuthPID[36];
	new String:AIP[32];
	new String:PIP[32];
	new time = GetTime({0,0});
	decl String:name_admin[32];
	decl String:name_player[32];
	GetClientName(client, name_admin, 32);
	GetClientName(target, name_player, 32);
	GetClientAuthString(client, AuthAID, 34);
	GetClientAuthString(target, AuthPID, 34);
	GetClientIP(target, PIP, 32, true);
	GetClientIP(client, AIP, 32, true);
	if (GetConVarInt(mmws_CvarBanEnable) == 2)
	{
		FormatEx(query, 1024, "INSERT INTO sb_bans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, country) VALUES ('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', (SELECT `aid` FROM sb_admins WHERE `authid` = '%s' LIMIT 0,1), '%s', (SELECT `sid` FROM sb_servers WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1), ' ')", PIP, AuthPID, name_player, 259200, 259200, "Подозрение на читы", AuthAID, AIP, s_ServerIP, s_ServerPort);
	}
	else
	{
		if (GetConVarInt(mmws_CvarBanEnable) == 1)
		{
			FormatEx(query, 1024, "INSERT INTO bans (authid, created, ends, length, reason) VALUES ('%s', %d, %d, %d, '%s')", AuthAID, time, time + 259200, 259200, "Подозрение на читы");
		}
	}
	SQL_TQuery(h_Database, VerifyInsert, query, any:0, DBPriority:0);
	ServerCommand("sm_kick #%d Вы забанены за подозрение на читы", GetClientUserId(target));
	CPrintToChatAll("{dimgray}*%s* Info: {lime}%s {fullred}забанен. {lightslategray}Причина: подозрение на читы. Админ: %s.", infotitle, name_player, name_admin);
	return 0;
}

public SelectPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	new String:info[256];
	GetMenuItem(menu, param2, info, 255, 0, "", 0);
	new id = StringToInt(info, 10);
	new String:client_name[256];
	new String:client_name_t[256];
	new String:client_name_ct[256];
	new String:client_name_select[256];
	new String:client_auth[32];
	GetClientName(t_cap, client_name_t, 255);
	GetClientName(ct_cap, client_name_ct, 255);
	GetClientName(id, client_name_select, 255);
	if (action == MenuAction:4)
	{
		CPrintToChat(param1, "{aliceblue}%t {lime}%s", "Your Select", client_name_select);
		if (t_cap == param1)
		{
			ChangeClientTeam(id, 2);
			if (CS_GetSpecCount())
			{
				menuopen = 0;
			}
			if (CS_GetPlayingCTCount() < 5)
			{
				menuopen = 3;
				new Handle:menuT = CreateMenu(SelectPlayer, MenuAction:28);
				SetMenuTitle(menuT, "%t:", "Menu Select Player");
				new i = 1;
				while (i <= MaxClients)
				{
					if (IsClientInGame(i))
					{
						GetClientName(i, client_name, 255);
						IntToString(i, client_auth, 32);
						AddMenuItem(menuT, client_auth, client_name, 0);
						i++;
					}
					i++;
				}
				SetMenuExitButton(menuT, false);
				if (CS_GetPlayingTCount() >= CS_GetPlayingCTCount())
				{
					CPrintToChat(param1, "{aliceblue}%t {fullred}%s", "Waiting Player Select", client_name_ct);
					DisplayMenu(menuT, ct_cap, 15);
				}
				else
				{
					menuopen = 2;
					DisplayMenu(menuT, t_cap, 15);
				}
			}
		}
		if (ct_cap == param1)
		{
			ChangeClientTeam(id, 3);
			if (CS_GetSpecCount())
			{
				menuopen = 0;
			}
			if (CS_GetPlayingTCount() < 5)
			{
				menuopen = 2;
				new Handle:menuCT = CreateMenu(SelectPlayer, MenuAction:28);
				SetMenuTitle(menuCT, "%t:", "Menu Select Player");
				new i = 1;
				while (i <= MaxClients)
				{
					if (IsClientInGame(i))
					{
						GetClientName(i, client_name, 255);
						IntToString(i, client_auth, 32);
						AddMenuItem(menuCT, client_auth, client_name, 0);
						i++;
					}
					i++;
				}
				SetMenuExitButton(menuCT, false);
				if (CS_GetPlayingCTCount() >= CS_GetPlayingTCount())
				{
					CPrintToChat(param1, "{aliceblue}%t {fullred}%s", "Waiting Player Select", client_name_t);
					DisplayMenu(menuCT, t_cap, 15);
				}
				else
				{
					menuopen = 3;
					DisplayMenu(menuCT, ct_cap, 15);
				}
			}
		}
	}
	else
	{
		if (action == MenuAction:8)
		{
			id = GetRandomPlayer(1);
			GetClientName(id, client_name_select, 255);
			CPrintToChat(param1, "{fullred}Вы не сделали свой выбор за 15 секунд.");
			CPrintToChat(param1, "{fullred}Система выбрала за Вас.");
			CPrintToChat(param1, "{aliceblue}Игрок {lime}%s {aliceblue}перемещен за Вашу команду.", client_name_select);
			if (t_cap == param1)
			{
				ChangeClientTeam(id, 2);
				if (CS_GetSpecCount())
				{
					menuopen = 0;
				}
				if (CS_GetPlayingCTCount() < 5)
				{
					menuopen = 3;
					CPrintToChat(param1, "{fullred}%t {aliceblue}%s", "Waiting Player Select", client_name_ct);
					new Handle:menuT = CreateMenu(SelectPlayer, MenuAction:28);
					SetMenuTitle(menuT, "%t:", "Menu Select Player");
					new i = 1;
					while (i <= MaxClients)
					{
						if (IsClientInGame(i))
						{
							GetClientName(i, client_name, 255);
							IntToString(i, client_auth, 32);
							AddMenuItem(menuT, client_auth, client_name, 0);
							i++;
						}
						i++;
					}
					SetMenuExitButton(menuT, false);
					DisplayMenu(menuT, ct_cap, 15);
				}
			}
			if (ct_cap == param1)
			{
				ChangeClientTeam(id, 3);
				if (CS_GetSpecCount())
				{
					menuopen = 0;
				}
				if (CS_GetPlayingTCount() < 5)
				{
					menuopen = 2;
					CPrintToChat(param1, "{fullred}%t {aliceblue}%s", "Waiting Player Select", client_name_t);
					new Handle:menuCT = CreateMenu(SelectPlayer, MenuAction:28);
					SetMenuTitle(menuCT, "%t:", "Menu Select Player");
					new i = 1;
					while (i <= MaxClients)
					{
						if (IsClientInGame(i))
						{
							GetClientName(i, client_name, 255);
							IntToString(i, client_auth, 32);
							AddMenuItem(menuCT, client_auth, client_name, 0);
							i++;
						}
						i++;
					}
					SetMenuExitButton(menuCT, false);
					DisplayMenu(menuCT, t_cap, 15);
				}
			}
		}
		if (action == MenuAction:16)
		{
			CloseHandle(menu);
		}
	}
	return 0;
}

public Action:openmenu(client, args)
{
	new Handle:menu = CreateMenu(SelectMenu, MenuAction:28);
	SetMenuTitle(menu, "Select Number");
	AddMenuItem(menu, "1", "1", 0);
	AddMenuItem(menu, "2", "2", 0);
	AddMenuItem(menu, "3", "3", 0);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
	return Action:0;
}

public SelectMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		new String:info[256];
		GetMenuItem(menu, param2, info, 255, 0, "", 0);
		CPrintToChat(param1, "Вы выбрали %s", info);
	}
	else
	{
		if (action == MenuAction:8)
		{
			CPrintToChat(param1, "Вы ничего не выбрали. Причина: %d", param2);
		}
		if (action == MenuAction:16)
		{
			CPrintToChat(param1, "Меню закрылось по истечение 15 секунд");
			CloseHandle(menu);
		}
	}
	return 0;
}

public Action:ChangeMap(Handle:timer)
{
	if (CS_GetPlayersCount() < 1)
	{
		ServerCommand("%s", DefaultMap);
	}
	return Action:0;
}

public Action:AdminsList(client, args)
{
	new String:admin_name[256];
	new String:admin_list[1024];
	new String:client_name[256];
	GetClientName(client, client_name, 255);
	Format(admin_list, 1024, "");
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			CPrintToChat(i, "{dimgray}*%s* Info: {aliceblue}Игрок {lime}%s {aliceblue}просматривает список админов", infotitle, client_name);
			GetClientName(i, admin_name, 255);
			if (StrEqual(admin_list, "", true))
			{
				Format(admin_list, 1024, "{lime}%s", admin_name);
				i++;
			}
			Format(admin_list, 1024, "%s{aliceblue}, {lime}%s", admin_list, admin_name);
			i++;
		}
		i++;
	}
	if (StrEqual(admin_list, "", true))
	{
		CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t", infotitle, "Not Admins");
	}
	else
	{
		CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}%t: %s", infotitle, "Admins On Server", admin_list);
	}
	return Action:3;
}

CheckPlayers()
{
	if (GetConVarInt(mmws_CvarHostnameStatus) == 1)
	{
		ServerCommand("hostname \"%s\"", hostnameupdate);
		Format(hostnamenew, 256, "%s [%s]", hostnameupdate, Status_Check);
		ServerCommand("hostname \"%s\"", hostnamenew);
	}
	ServerCommand("mp_restartgame 2");
	CreateTimer(4, CheckAlive, any:0, 0);
	return 0;
}

public Action:CheckAlive(Handle:timer)
{
	new String:client_name[256];
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			GetClientName(i, client_name, 255);
			ChangeClientTeam(i, 1);
			CPrintToChatAll("{dimgray}*%s* Info: {aliceblue}%t {lime}%s {fullred}%t", infotitle, "1 Player", client_name, "Move AFK");
			i++;
		}
		i++;
	}
	return Action:0;
}

public PlayersReady(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction:4)
	{
		new String:info[256];
		GetMenuItem(menu, param2, info, 255, 0, "", 0);
		if (StrEqual(info, "Yes", true))
		{
			ReadyPlayers();
		}
	}
	else
	{
		if (action == MenuAction:8)
		{
		}
		else
		{
			if (action == MenuAction:16)
			{
				CloseHandle(menu);
			}
		}
	}
	return 0;
}

ReadyPlayers()
{
	players_ready += 1;
	if (players_ready == 10)
	{
		ServerCommand("forcestart");
	}
	return 0;
}

public Action:UnBan(client, args)
{
	if (GetConVarInt(mmws_CvarBanEnable) == 1)
	{
		decl String:s_CheckQuery[1024];
		decl String:Arguments[256];
		new time = GetTime({0,0});
		GetCmdArgString(Arguments, 256);
		if (SimpleRegexMatch(Arguments, "STEAM_0:.:([0-9]){3,8}", 0, "", 0) < 1)
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}команда для разбана {fullred}\"unban <steamid>\"", infotitle);
			return Action:3;
		}
		FormatEx(s_CheckQuery, 1024, "SELECT * FROM bans WHERE `ends` > %d AND `authid` = '%s'", time, Arguments);
		new Handle:resultrow = SQL_Query(h_Database, s_CheckQuery, -1);
		if (resultrow)
		{
			Format(s_CheckQuery, 1024, "DELETE FROM bans WHERE `authid` = '%s'", Arguments);
			SQL_TQuery(h_Database, ErrorCheckCallback, s_CheckQuery, any:0, DBPriority:1);
			CPrintToChat(client, "{dimgray}*%s* Info: %s разбанен.", infotitle, Arguments);
		}
		else
		{
			CPrintToChat(client, "{dimgray}*%s* Info: %s не найден.", infotitle, Arguments);
		}
	}
	else
	{
		if (GetConVarInt(mmws_CvarBanEnable) == 2)
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {fullred}Команда недоступна. {aliceblue}Используйте систему SourceBans.", infotitle);
		}
		if (GetConVarInt(mmws_CvarBanEnable))
		{
		}
		else
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {fullred}Команда недоступна. {aliceblue}Сервер не подключен ни к одной системе банов.", infotitle);
		}
	}
	return Action:3;
}

public Action:ChangeLevel(client, args)
{
	if (license)
	{
		ServerCommand("hostname \"%s\"", hostnameupdate);
	}
	return Action:0;
}

public Action:ReplacePlayer(client, args)
{
	if (!cwstatus)
	{
		if (g_match)
		{
			if (GetClientTeam(client) > 1)
			{
				if (GetConVarInt(mmws_CvarAcceptReplace) == 1)
				{
					if (!SubStatus)
					{
						if (CS_GetPlayingCount() == 10)
						{
							if (CS_GetSubCount() == 1)
							{
								decl String:SubName[256];
								SubStatus = 1;
								SubPlayer = client;
								SubSpectator = GetRandomPlayer(1);
								GetClientName(SubSpectator, SubName, 255);
								CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Игрок {lime}%s {aliceblue}получил запрос на Вашу замену", infotitle, SubName);
								CreateTimer(0.5, SubstitionMenu, any:0, 0);
							}
							else
							{
								CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Игроков для замены {fullred}нет", infotitle);
							}
						}
						else
						{
							CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}В командах должно быть по {lime}5 {aliceblue}человек", infotitle);
						}
					}
					else
					{
						CPrintToChat(client, "{dimgray}*%s* Info: {fullred}Отказано. {aliceblue}Замену запросил другой игрок", infotitle);
					}
				}
				else
				{
					CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Настройки сервера не позволяют производить замены.", infotitle);
				}
			}
			else
			{
				CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Команда недоступна.", infotitle);
			}
		}
		else
		{
			CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Замены разрешены только во время микса.", infotitle);
		}
	}
	else
	{
		CPrintToChat(client, "{dimgray}*%s* Info: {aliceblue}Замены разрешены только в режиме 'MxWars'.", infotitle);
	}
	return Action:0;
}

public Action:SubstitionMenu(Handle:timer)
{
	decl String:question[256];
	decl String:SubName[256];
	GetClientName(SubPlayer, SubName, 255);
	Format(question, 255, "%s запросил замену", SubName);
	new Handle:submenu = CreateMenu(Substition, MenuAction:28);
	SetMenuTitle(submenu, question);
	AddMenuItem(submenu, "Yes", "Заменить", 0);
	AddMenuItem(submenu, "No", "Отказаться", 0);
	SetMenuExitButton(submenu, false);
	DisplayMenu(submenu, SubSpectator, 30);
	return Action:0;
}

public Substition(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:SubName[256];
	decl String:PlayerName[256];
	decl String:SubAuth[256];
	decl String:PlayerAuth[256];
	GetClientName(SubSpectator, SubName, 255);
	GetClientName(SubPlayer, PlayerName, 255);
	GetClientAuthString(SubPlayer, PlayerAuth, 255);
	GetClientAuthString(SubSpectator, SubAuth, 255);
	new PlayerTeam = GetClientTeam(SubPlayer);
	if (action == MenuAction:4)
	{
		new String:info[256];
		GetMenuItem(menu, param2, info, 255, 0, "", 0);
		if (StrEqual(info, "Yes", true))
		{
			if (!IsPlayerAlive(SubPlayer))
			{
				ServerCommand("sm_kick #%d Вас заменил %s", GetClientUserId(SubPlayer), SubName);
				ChangeClientTeam(SubSpectator, PlayerTeam);
				CPrintToChat(SubSpectator, "{dimgray}*%s* Info: {aliceblue}Вы заменили {lime}%s {aliceblue}и перемещены за команду", infotitle, PlayerName);
				Log2Game("\"SUBSTITUTION\" (OUT: \"%s\" [%s]) (IN: \"%s\" [%s]) (TEAM: %d)", PlayerName, PlayerAuth, SubName, SubAuth, PlayerTeam);
				SubStatus = 0;
				SubPlayer = 0;
				SubSpectator = 0;
			}
			SubStatusWait = 1;
			CPrintToChat(SubPlayer, "{dimgray}*%s* Info: {aliceblue}Вы будете заменены по окончании раунда или после смерти", infotitle);
		}
		if (StrEqual(info, "No", true))
		{
			CPrintToChat(SubPlayer, "{dimgray}*%s* Info: {aliceblue}Игрок {lime}%s {fullred}отказался заменить Вас", infotitle, SubName);
			ServerCommand("sm_kick #%d Вы отклонили замену", GetClientUserId(SubSpectator));
			SubStatus = 0;
			SubPlayer = 0;
			SubSpectator = 0;
		}
	}
	else
	{
		if (action == MenuAction:8)
		{
			CPrintToChat(SubPlayer, "{dimgray}*%s* Info: {aliceblue}Игрок {lime}%s {fullred}отказался заменить Вас", infotitle, SubName);
			ServerCommand("sm_kick #%d Вы отклонили замену", GetClientUserId(SubSpectator));
			SubStatus = 0;
			SubPlayer = 0;
			SubSpectator = 0;
		}
		if (action == MenuAction:16)
		{
			CloseHandle(menu);
		}
	}
	return 0;
}

public Action:Timer_DisplayAds(Handle:timer)
{
	if (GetConVarBool(mmws_ads_Enabled))
	{
		if (!KvGotoNextKey(mmws_ads_Advertisements, true))
		{
			KvRewind(mmws_ads_Advertisements);
			KvGotoFirstSubKey(mmws_ads_Advertisements, true);
		}
		decl String:sText[256];
		decl String:sTextTmp[256];
		decl String:sType[8];
		decl String:sMode[8];
		KvGetString(mmws_ads_Advertisements, "type", sType, 6, "");
		KvGetString(mmws_ads_Advertisements, "text", sText, 256, "");
		KvGetString(mmws_ads_Advertisements, "mode", sMode, 6, "");
		if (StrContains(sType, "L", true) != -1)
		{
			if (StrEqual(sMode, "mix", true))
			{
				if (StrEqual(ads_prefix, "", true))
				{
					Format(sTextTmp, 256, "{aliceblue}%s", sTextTmp);
				}
				else
				{
					Format(sTextTmp, 256, "{dimgray}*%s*: {aliceblue}%s", ads_prefix, sTextTmp);
				}
				CPrintToChatAll(sTextTmp);
			}
			if (StrEqual(sMode, "match", true))
			{
				if (StrEqual(ads_prefix, "", true))
				{
					Format(sTextTmp, 256, "{aliceblue}%s", sTextTmp);
				}
				else
				{
					Format(sTextTmp, 256, "{dimgray}*%s*: {aliceblue}%s", ads_prefix, sTextTmp);
				}
				CPrintToChatAll(sTextTmp);
			}
			if (StrEqual(ads_prefix, "", true))
			{
				Format(sTextTmp, 256, "{aliceblue}%s", sTextTmp);
			}
			else
			{
				Format(sTextTmp, 256, "{dimgray}*%s*: {aliceblue}%s", ads_prefix, sTextTmp);
			}
			CPrintToChatAll(sTextTmp);
		}
		if (StrContains(sType, "W", true) != -1)
		{
			if (StrEqual(sMode, "mix", true))
			{
				if (StrEqual(ads_prefix, "", true))
				{
					Format(sTextTmp, 256, "{aliceblue}%s", sTextTmp);
				}
				else
				{
					Format(sTextTmp, 256, "{dimgray}*%s*: {aliceblue}%s", ads_prefix, sTextTmp);
				}
				CPrintToChatAll(sTextTmp);
			}
			if (StrEqual(sMode, "match", true))
			{
				if (StrEqual(ads_prefix, "", true))
				{
					Format(sTextTmp, 256, "{aliceblue}%s", sTextTmp);
				}
				else
				{
					Format(sTextTmp, 256, "{dimgray}*%s*: {aliceblue}%s", ads_prefix, sTextTmp);
				}
				CPrintToChatAll(sTextTmp);
			}
			if (StrEqual(ads_prefix, "", true))
			{
				Format(sTextTmp, 256, "{aliceblue}%s", sTextTmp);
			}
			else
			{
				Format(sTextTmp, 256, "{dimgray}*%s*: {aliceblue}%s", ads_prefix, sTextTmp);
			}
			CPrintToChatAll(sTextTmp);
		}
	}
	return Action:0;
}

ParseAds()
{
	if (mmws_ads_Advertisements)
	{
		CloseHandle(mmws_ads_Advertisements);
	}
	mmws_ads_Advertisements = CreateKeyValues("Advertisements", "", "");
	decl String:sPath[256];
	BuildPath(PathType:0, sPath, 256, "configs/mmws_adverts.txt");
	if (FileExists(sPath, false))
	{
		FileToKeyValues(mmws_ads_Advertisements, sPath);
		KvGotoFirstSubKey(mmws_ads_Advertisements, true);
	}
	else
	{
		SetFailState("File Not Found: %s", sPath);
	}
	return 0;
}

public Action:SteamID(client, args)
{
	new Handle:steam_menu = CreateMenu(SteamProfile, MenuAction:28);
	new String:client_name[256];
	new String:client_auth[32];
	SetMenuTitle(steam_menu, "%t:", "Menu Select Player");
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			GetClientName(i, client_name, 255);
			IntToString(i, client_auth, 32);
			AddMenuItem(steam_menu, client_auth, client_name, 0);
			i++;
		}
		i++;
	}
	SetMenuExitButton(steam_menu, true);
	DisplayMenu(steam_menu, client, 60);
	return Action:0;
}

public SteamProfile(Handle:menu, MenuAction:action, param1, param2)
{
	new String:info[256];
	GetMenuItem(menu, param2, info, 255, 0, "", 0);
	new id = StringToInt(info, 10);
	new String:client_name[256];
	new String:client_auth[32];
	GetClientName(id, client_name, 255);
	GetClientAuthString(id, client_auth, 32);
	if (action == MenuAction:4)
	{
		decl String:link[256];
		AuthIDToFriendID(client_auth, link, 256);
		CPrintToChat(param1, "{dimgray}Player Info: {aliceblue}Информация об {lime}%s", client_name);
		CPrintToChat(param1, "{dimgray}Player Info: {aliceblue}SteamID: {lime}%s", client_auth);
		CPrintToChat(param1, "{dimgray}Player Info: {aliceblue}CommunityID: {lime}%s", link);
		if (g_bPlyrCanDoMotd[param1][0][0])
		{
			ShowMOTDPanel(param1, "Player Community Profile", link, 2);
		}
		else
		{
			CPrintToChat(param1, "{dimgray}*%s* Info: {aliceblue}Для просмотра {lime}Steam-профиля игрока {aliceblue}необходимо включение HTML сообщений в настройках.", infotitle);
			CPrintToChat(param1, "{dimgray}*%s* Info: {aliceblue}Перейдите в НАСТРОЙКИ > СЕТЕВОЙ РЕЖИМ > ДОПОЛНИТЕЛЬНО > Снимите флажок с 'Отключить HTML сообщения дня'.", infotitle);
			CPrintToChat(param1, "{dimgray}*%s* Info: {aliceblue}После изменения настроек ПЕРЕЗАЙДИТЕ на сервер.", infotitle);
		}
	}
	else
	{
		if (action == MenuAction:8)
		{
		}
		else
		{
			if (action == MenuAction:16)
			{
				CloseHandle(menu);
			}
		}
	}
	return 0;
}

AuthIDToFriendID(String:AuthID[], String:FriendID[], size)
{
	ReplaceString(AuthID, strlen(AuthID), "STEAM_", "", true);
	if (StrEqual(AuthID, "ID_LAN", true))
	{
		FriendID[0] = 0;
		return 0;
	}
	new String:toks[12][16] = "";
	new upper = 765611979;
	new String:temp[12];
	new String:carry[12];
	ExplodeString(AuthID, ":", toks, 3, 16, false);
	new iServer = StringToInt(toks[1], 10);
	new iAuthID = StringToInt(toks[2], 10);
	new iFriendID = iAuthID * 2 + 60265728 + iServer;
	if (iFriendID >= 100000000)
	{
		Format(temp, 12, "%d", iFriendID);
		Format(carry, 2, "%s", temp);
		new icarry = StringToInt(carry, 10);
		upper = icarry + upper;
		Format(temp, 12, "%d", iFriendID);
		Format(FriendID, size, "http://steamcommunity.com/profiles/%d%s", upper, temp[0]);
	}
	else
	{
		Format(FriendID, size, "http://steamcommunity.com/profiles/765611979%d", iFriendID);
	}
	return 0;
}

public Action:SteamIDGoogle(client, args)
{
	new Handle:steam_menu = CreateMenu(SteamProfileGoogle, MenuAction:28);
	new String:client_name[256];
	new String:client_auth[32];
	SetMenuTitle(steam_menu, "%t:", "Menu Select Player");
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			GetClientName(i, client_name, 255);
			IntToString(i, client_auth, 32);
			AddMenuItem(steam_menu, client_auth, client_name, 0);
			i++;
		}
		i++;
	}
	SetMenuExitButton(steam_menu, true);
	DisplayMenu(steam_menu, client, 60);
	return Action:0;
}

public SteamProfileGoogle(Handle:menu, MenuAction:action, param1, param2)
{
	new String:info[256];
	GetMenuItem(menu, param2, info, 255, 0, "", 0);
	new id = StringToInt(info, 10);
	new String:client_name[256];
	new String:client_auth[32];
	GetClientName(id, client_name, 255);
	GetClientAuthString(id, client_auth, 32);
	if (action == MenuAction:4)
	{
		decl String:link[512];
		decl String:url[512];
		Format(url, 512, "http://www.google.ru/search?q=%s", client_auth);
		AuthIDToFriendID(client_auth, link, 512);
		CPrintToChat(param1, "{dimgray}Player Info: {aliceblue}Информация об {lime}%s", client_name);
		CPrintToChat(param1, "{dimgray}Player Info: {aliceblue}SteamID: {lime}%s", client_auth);
		CPrintToChat(param1, "{dimgray}Player Info: {aliceblue}CommunityID: {lime}%s", link);
		if (g_bPlyrCanDoMotd[param1][0][0])
		{
			ShowMOTDPanel(param1, "Search Player Information", url, 2);
		}
		else
		{
			CPrintToChat(param1, "{dimgray}*%s* Info: {aliceblue}Для просмотра {lime}информации об игроке {aliceblue}необходимо включение HTML сообщений в настройках.", infotitle);
			CPrintToChat(param1, "{dimgray}*%s* Info: {aliceblue}Перейдите в НАСТРОЙКИ > СЕТЕВОЙ РЕЖИМ > ДОПОЛНИТЕЛЬНО > Снимите флажок с 'Отключить HTML сообщения дня'.", infotitle);
			CPrintToChat(param1, "{dimgray}*%s* Info: {aliceblue}После изменения настроек ПЕРЕЗАЙДИТЕ на сервер.", infotitle);
		}
	}
	else
	{
		if (action == MenuAction:8)
		{
		}
		else
		{
			if (action == MenuAction:16)
			{
				CloseHandle(menu);
			}
		}
	}
	return 0;
}

