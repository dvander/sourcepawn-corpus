/*
 * Custom Votes
 * Written by chundo (chundo@mefightclub.com)
 *
 * Allows new votes to be created from configuration files.  Other plugins
 * can drop config files in configs/customvotes/ to automatically have their
 * votes created.
 *
 * Licensed under the GPL version 2 or above
 */

#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "0.5.6"
#define INVALID_VOTE -1
#define MAX_VOTES 64

enum CVoteType {
	CVoteType_Confirm,
	CVoteType_List,
	CVoteType_OnOff,
	CVoteType_Chat
}

enum CVoteApprove {
	CVoteApprove_None,
	CVoteApprove_Sender,
	CVoteApprove_Admin
}

enum CVoteParamType {
	CVoteParamType_MapCycle,
	CVoteParamType_Player,
	CVoteParamType_GroupPlayer,
	CVoteParamType_Group,
	CVoteParamType_OnOff,
	CVoteParamType_YesNo,
	CVoteParamType_List
}

enum CVote {
	String:name[32],
	String:title[128],
	String:admin[32],
	String:trigger[32],
	String:triggernotice[128],
	triggercount,
	triggerpercent,
	CVoteApprove:approve,
	triggerexpires,
	percent,
	abspercent,
	votes,
	delay,
	triggerdelay,
	mapdelay,
	String:target[32],
	String:execute[128],
	CVoteType:type,
	options,
	Handle:optiondata,
	numparams,
	CVoteParamType:paramtypes[10],
	Handle:paramdata[10],
	paramoptions[10]
}

enum CVoteStatus {
	voteindex,
	Handle:params,
	Handle:paramdata, // Store player names in case of disconnect
	paramct,
	clientvotes[MAXPLAYERS+1],
	clienttriggers[MAXPLAYERS+1],
	clientnostatus[MAXPLAYERS+1],
	clienttimestamps[MAXPLAYERS+1],
	targets[MAXPLAYERS+1],
	targetct,
	sender
}

enum CVoteTempParams {
	String:name[32],
	bool:triggered,
	Handle:params,
	paramct
}

// Hopefully this stock menu stuff will be in core soon
enum StockMenuType {
	StockMenuType_MapCycle,
	StockMenuType_Player,
	StockMenuType_GroupPlayer,
	StockMenuType_Group,
	StockMenuType_OnOff,
	StockMenuType_YesNo
}

// CVars
new Handle:sm_cvote_showstatus = INVALID_HANDLE;
new Handle:sm_cvote_resetonmapchange = INVALID_HANDLE;
new Handle:sm_cvote_triggers = INVALID_HANDLE;
new Handle:sm_cvote_mapdelay = INVALID_HANDLE;
new Handle:sm_cvote_triggerdelay = INVALID_HANDLE;
new Handle:sm_cvote_executedelay = INVALID_HANDLE;
new Handle:sm_cvote_minpercent = INVALID_HANDLE;
new Handle:sm_cvote_minvotes = INVALID_HANDLE;
new Handle:sm_cvote_adminonly = INVALID_HANDLE;
new Handle:sm_vote_delay = INVALID_HANDLE;

// Vote lookup tables
new Handle:g_voteArray = INVALID_HANDLE;
new String:g_voteNames[MAX_VOTES][32];
new String:g_voteTriggers[MAX_VOTES][32];

// Vote status tables
new Handle:g_voteStatus = INVALID_HANDLE;
new g_activeVoteStatus[CVoteStatus];
new g_activeVoteStatusIdx = -1;
new g_confirmMenus = 0;

// Votes currently being built via menus
new g_clientTempParams[MAXPLAYERS+1][CVoteTempParams];

// Menu pointers
new Handle:g_topMenu = INVALID_HANDLE;
new Handle:g_adminMenuHandle = INVALID_HANDLE;

// Timestamps for delay calculations
new g_voteLastInitiated[MAX_VOTES];
new g_lastVoteTime = 0;
new g_mapStartTime = 0;

// Config parsing state
new g_configLevel = 0;
new String:g_configSection[32];
new g_configParam = -1;
new g_configParamsUsed = 0;
new g_configVote[CVote];

public Plugin:myinfo = {
	name = "Custom Votes",
	author = "chundo",
	description = "Allow addition of custom votes with configuration files",
	version = PLUGIN_VERSION,
	url = "http://www.mefightclub.com"
};

public OnPluginStart() {
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("customvotes.phrases");

	CreateConVar("sm_cvote_version", PLUGIN_VERSION, "Custom votes version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_cvote_showstatus = CreateConVar("sm_cvote_showstatus", "1", "Show vote status. 0 = none, 1 = in side panel anonymously, 2 = in chat anonymously, 3 = in chat with player names.", FCVAR_PLUGIN);
	sm_cvote_resetonmapchange = CreateConVar("sm_cvote_resetonmapchange", "0", "Reset all votes on map change.", FCVAR_PLUGIN);
	sm_cvote_triggers = CreateConVar("sm_cvote_triggers", "1", "Allow in-chat vote triggers.", FCVAR_PLUGIN);
	sm_cvote_triggerdelay = CreateConVar("sm_cvote_triggerdelay", "60", "Default delay between non-admin initiated votes.", FCVAR_PLUGIN);
	sm_cvote_executedelay = CreateConVar("sm_cvote_executedelay", "3.0", "Default delay before executing a command after a successful vote.", FCVAR_PLUGIN);
	sm_cvote_mapdelay = CreateConVar("sm_cvote_mapdelay", "0", "Default delay after maps starts before players can initiate votes.", FCVAR_PLUGIN);
	sm_cvote_minpercent = CreateConVar("sm_cvote_minpercent", "60", "Minimum percentage of votes the winner must receive to be considered the winner.", FCVAR_PLUGIN);
	sm_cvote_minvotes = CreateConVar("sm_cvote_minvotes", "0", "Minimum number of votes the winner must receive to be considered the winner.", FCVAR_PLUGIN);
	sm_cvote_adminonly = CreateConVar("sm_cvote_adminonly", "0", "Only admins can initiate votes (except chat votes.)", FCVAR_PLUGIN);
	sm_vote_delay = FindConVar("sm_vote_delay");

	RegAdminCmd("sm_cvote", Command_CustomVote, ADMFLAG_GENERIC, "Initiate a vote, or list available votes", "customvotes", FCVAR_PLUGIN);
	RegAdminCmd("sm_cvote_reload", Command_ReloadConfig, ADMFLAG_GENERIC, "Reload vote configuration", "customvotes", FCVAR_PLUGIN);
	RegConsoleCmd("sm_votemenu", Command_VoteMenu, "List available votes", FCVAR_PLUGIN);

	RegAdminCmd("sm_ban_auto", Command_BanAuto, ADMFLAG_GENERIC, "Ban a user by Steam ID or IP (auto-detected)", "customvotes", FCVAR_PLUGIN);

	// Loaded late, OnAdminMenuReady already fired
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		g_topMenu = topmenu;
	
	for (new i = 0; i < sizeof(g_voteLastInitiated); ++i)
		g_voteLastInitiated[i] = 0;
	g_voteStatus = CreateArray(sizeof(g_activeVoteStatus));

	HookEvent("player_say", Event_PlayerChat, EventHookMode_Post);
	HookConVarChange(sm_cvote_triggers, Change_Triggers);

	AutoExecConfig(false);
}

public OnAdminMenuReady(Handle:topmenu) {
	// Called twice
	if (topmenu == g_topMenu)
		return;

	// Save handle to prevent duplicate calls
	g_topMenu = topmenu;

	// Add votes to admin menu
	if (g_voteArray != INVALID_HANDLE) {
		new cvote[CVote];
		for (new i = 0; i < GetArraySize(g_voteArray); ++i) {
			GetArrayArray(g_voteArray, i, cvote[0]);
			AddVoteToMenu(topmenu, cvote);
		}
	}
}

AddVoteToMenu(Handle:topmenu, cvote[CVote]) {
	if (cvote[type] == CVoteType_Chat)
		return;

	// Add votes to admin menu
	new TopMenuObject:voting_commands = FindTopMenuCategory(topmenu, ADMINMENU_VOTINGCOMMANDS);
	if (voting_commands != INVALID_TOPMENUOBJECT) {
		new String:menu_id[38];
		Format(menu_id, sizeof(menu_id), "cvote_%s", cvote[name]);
		AddToTopMenu(topmenu,
			menu_id,
			TopMenuObject_Item,
			CVote_AdminMenuHandler,
			voting_commands,
			"sm_cvote",
			ADMFLAG_VOTE,
			cvote[name]);
	}
}

public Change_Triggers(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (strcmp(oldval, newval) != 0) {
		if (strcmp(newval, "0") == 0)
			UnhookEvent("player_say", Event_PlayerChat, EventHookMode_Post);
		else
			HookEvent("player_say", Event_PlayerChat, EventHookMode_Post);
	}
}

public OnClientDisconnect(client) {
	new tstatus[CVoteStatus];
	new cvote[CVote];
	for (new i = 0; i < GetArraySize(g_voteStatus); ++i) {
		GetArrayArray(g_voteStatus, i, tstatus[0]);
		GetArrayArray(g_voteArray, tstatus[voteindex], cvote[0]);
		if (tstatus[clienttriggers][client] > -1) {
			tstatus[clienttriggers][client] = -1;
			SetArrayArray(g_voteStatus, i, tstatus[0]);
		}
	}
	RemoveExpiredStatuses();
}

public OnMapStart() {
	g_mapStartTime = GetTime();
	// Clean up memory
	ClearCurrentVote();
	for (new i = 1; i <= MAXPLAYERS; ++i)
		ClearTempParams(i);
	if (GetConVarBool(sm_cvote_resetonmapchange))
		ClearArray(g_voteStatus);
	else
		RemoveExpiredStatuses();
	if (!LoadConfigFiles())
		LogError("%T", "Plugin configuration error", LANG_SERVER);
}

public CVote_AdminMenuHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	new String:votename[32];
	GetTopMenuInfoString(topmenu, object_id, votename, sizeof(votename));
	new idx = InArray(votename, g_voteNames, sizeof(g_voteNames));
	if (idx > -1) {
		new selvote[CVote];
		GetArrayArray(g_voteArray, idx, selvote[0]);
		if (action == TopMenuAction_DisplayOption) {
			new String:votetitle[128];
			new String:voteparams[10][32];
			new CVoteParamType:voteparamtypes[10];
			new voteparamct = 0;
			voteparamct = selvote[numparams];
			for (new k = 0; k < selvote[numparams]; ++k) {
				voteparamtypes[k] = CVoteParamType_List;
				switch (selvote[paramtypes][k]) {
					case CVoteParamType_MapCycle: {
						strcopy(voteparams[k], 32, "<map>");
					}
					case CVoteParamType_Player: {
						strcopy(voteparams[k], 32, "<player>");
					}
					case CVoteParamType_GroupPlayer: {
						strcopy(voteparams[k], 32, "<group/player>");
					}
					case CVoteParamType_Group: {
						strcopy(voteparams[k], 32, "<group>");
					}
					case CVoteParamType_OnOff: {
						strcopy(voteparams[k], 32, "<on/off>");
					}
					case CVoteParamType_YesNo: {
						strcopy(voteparams[k], 32, "<yes/no>");
					}
					case CVoteParamType_List: {
						strcopy(voteparams[k], 32, "<value>");
					}
				}
			}
			ProcessTemplateString(votetitle, sizeof(votetitle), selvote[title]);
			ReplaceParams(votetitle, sizeof(votetitle), voteparams, voteparamct, voteparamtypes, true);
			strcopy(buffer, maxlength, votetitle);
		} else if (action == TopMenuAction_SelectOption) {
			new String:vparams[1][1];
			g_adminMenuHandle = topmenu;
			CVote_DoVote(param, votename, vparams, 0);
		} else if (action == TopMenuAction_DrawOption) {
			new String:errormsg[128];
			if (CanInitiateVote(param, selvote[admin]))
				buffer[0] = !IsVoteAllowed(param, idx, false, errormsg, sizeof(errormsg)) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
			else
				buffer[0] = ITEMDRAW_IGNORE;
		}
	}
}

/***************************
 ** CONFIGURATION PARSING **
 ***************************/

LoadConfigFiles() {
	if (g_voteArray == INVALID_HANDLE)
		g_voteArray = CreateArray(sizeof(g_configVote));

	decl String:vd[PLATFORM_MAX_PATH];
	new bool:success = true;

	BuildPath(Path_SM, vd, sizeof(vd), "configs/customvotes");
	new Handle:vdh = OpenDirectory(vd);

	// Search Path_SM/configs/customvotes for CFG files
	if (vdh != INVALID_HANDLE) {
		decl String:vf[PLATFORM_MAX_PATH];
		decl FileType:vft;
		while (ReadDirEntry(vdh, vf, sizeof(vf), vft)) {
			if (vft == FileType_File && strlen(vf) > 4 && strcmp(".cfg", vf[strlen(vf)-4]) == 0) {
				decl String:vfp[PLATFORM_MAX_PATH];
				strcopy(vfp, sizeof(vfp), vd);
				StrCat(vfp, sizeof(vfp), "/");
				StrCat(vfp, sizeof(vfp), vf);
				success = success && ParseConfigFile(vfp);
			}
		}
		CloseHandle(vdh);
	} else {
		LogError("%T (%s).", "Directory does not exist", LANG_SERVER, vd);
	}
	return success;
}

bool:ParseConfigFile(const String:file[]) {
	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	new line = 0;
	new col = 0;
	new String:error[128];
	new SMCError:result = SMC_ParseFile(parser, file, line, col);
	CloseHandle(parser);

	if (result != SMCError_Okay) {
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}

	return (result == SMCError_Okay);
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) {
	g_configLevel++;
	switch (g_configLevel) {
		case 2: {
			g_configParamsUsed = 0;
			ResetVoteCache(g_configVote);
			strcopy(g_configVote[name], 32, section);
		}
		case 3: {
			strcopy(g_configSection, sizeof(g_configSection), section);
			if (strcmp(g_configSection, "options", false) == 0)
				g_configVote[optiondata] = CreateDataPack();
		}
		case 4: {
			new pidx = StringToInt(section) - 1;
			if (pidx < 10) {
				g_configParam = pidx;
				g_configVote[paramtypes][pidx] = CVoteParamType_List;
				g_configVote[paramdata][pidx] = CreateDataPack();
				g_configVote[numparams] = Max(g_configVote[numparams], pidx + 1);
			}
		}
	}
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes) {
	switch (g_configLevel) {
		case 2: {
			if(strcmp(key, "title", false) == 0) {
				strcopy(g_configVote[title], sizeof(g_configVote[title]), value);
				g_configParamsUsed = Max(g_configParamsUsed, GetParamCount(g_configVote[title]));
			} else if(strcmp(key, "admin", false) == 0)
				strcopy(g_configVote[admin], sizeof(g_configVote[admin]), value);
			else if(strcmp(key, "trigger", false) == 0)
				// Backwards compatibility with 0.4
				strcopy(g_configVote[trigger], sizeof(g_configVote[trigger]), value);
			else if(strcmp(key, "target", false) == 0)
				strcopy(g_configVote[target], sizeof(g_configVote[target]), value);
			else if(strcmp(key, "execute", false) == 0)
				strcopy(g_configVote[execute], sizeof(g_configVote[execute]), value);
			else if(strcmp(key, "command", false) == 0)
				strcopy(g_configVote[execute], sizeof(g_configVote[execute]), value);
			else if(strcmp(key, "cmd", false) == 0)
				strcopy(g_configVote[execute], sizeof(g_configVote[execute]), value);
			else if(strcmp(key, "delay", false) == 0)
				g_configVote[delay] = StringToInt(value);
			else if(strcmp(key, "playerdelay", false) == 0)
				// Backwards compatibility with 0.4
				g_configVote[triggerdelay] = StringToInt(value);
			else if(strcmp(key, "mapdelay", false) == 0)
				g_configVote[mapdelay] = StringToInt(value);
			else if(strcmp(key, "percent", false) == 0)
				g_configVote[percent] = StringToInt(value);
			else if(strcmp(key, "abspercent", false) == 0)
				g_configVote[abspercent] = StringToInt(value);
			else if(strcmp(key, "votes", false) == 0)
				g_configVote[votes] = StringToInt(value);
			else if(strcmp(key, "approve", false) == 0) {
				if (strcmp(value, "sender") == 0) {
					g_configVote[approve] = CVoteApprove_Sender;
				} else if (strcmp(value, "admins") == 0) {
					g_configVote[approve] = CVoteApprove_Admin;
				} else {
					g_configVote[approve] = CVoteApprove_None;
				}
			} else if(strcmp(key, "type", false) == 0) {
				if (strcmp(value, "confirm") == 0) {
					g_configVote[type] = CVoteType_Confirm;
				} else if (strcmp(value, "chat") == 0) {
					g_configVote[type] = CVoteType_Chat;
				} else if (strcmp(value, "onoff") == 0) {
					g_configVote[type] = CVoteType_OnOff;
				} else {
					// Default to list
					g_configVote[type] = CVoteType_List;
				}
			}
		}
		case 3: {
			if (strcmp(g_configSection, "options", false) == 0) {
				WritePackString(g_configVote[optiondata], key);
				g_configParamsUsed = Max(g_configParamsUsed, GetParamCount(key));
				WritePackString(g_configVote[optiondata], value);
				g_configParamsUsed = Max(g_configParamsUsed, GetParamCount(value));
				g_configVote[options]++;
			} else if (strcmp(g_configSection, "params", false) == 0) {
				new pidx = StringToInt(key) - 1;
				if (pidx < 10) {
					if (strcmp(value, "mapcycle", false) == 0) {
						g_configVote[paramtypes][pidx] = CVoteParamType_MapCycle;
					} else if (strcmp(value, "player", false) == 0) {
						g_configVote[paramtypes][pidx] = CVoteParamType_Player;
					} else if (strcmp(value, "groupplayer", false) == 0) {
						g_configVote[paramtypes][pidx] = CVoteParamType_GroupPlayer;
					} else if (strcmp(value, "group", false) == 0) {
						g_configVote[paramtypes][pidx] = CVoteParamType_Group;
					} else if (strcmp(value, "onoff", false) == 0) {
						g_configVote[paramtypes][pidx] = CVoteParamType_OnOff;
					} else if (strcmp(value, "yesno", false) == 0) {
						g_configVote[paramtypes][pidx] = CVoteParamType_YesNo;
					}
					g_configVote[numparams] = Max(g_configVote[numparams], pidx + 1);
				}
			} else if (strcmp(g_configSection, "trigger", false) == 0) {
				if(strcmp(key, "command", false) == 0)
					strcopy(g_configVote[trigger], sizeof(g_configVote[trigger]), value);
				else if(strcmp(key, "notice", false) == 0)
					strcopy(g_configVote[triggernotice], sizeof(g_configVote[triggernotice]), value);
				else if(strcmp(key, "percent", false) == 0)
					g_configVote[triggerpercent] = StringToInt(value);
				else if(strcmp(key, "count", false) == 0)
					g_configVote[triggercount] = StringToInt(value);
				else if(strcmp(key, "delay", false) == 0)
					g_configVote[triggerdelay] = StringToInt(value);
				else if(strcmp(key, "expires", false) == 0)
					g_configVote[triggerexpires] = StringToInt(value);
			}
		}
		case 4: {
			if (g_configParam > -1 && g_configVote[paramdata][g_configParam] != INVALID_HANDLE) {
				WritePackString(g_configVote[paramdata][g_configParam], key);
				WritePackString(g_configVote[paramdata][g_configParam], value);
				g_configVote[paramoptions][g_configParam]++;
			}
		}
	}
	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser) {
	switch (g_configLevel) {
		case 2: {
			if (g_configParamsUsed != g_configVote[numparams])
				LogMessage("Warning: vote definition for \"%s\" defines %d parameters but only uses %d.", g_configVote[name], g_configVote[numparams], g_configParamsUsed);
				
			new tidx = InArray(g_configVote[name], g_voteNames, sizeof(g_voteNames));
			if (tidx == -1) {
				new idx = PushArrayArray(g_voteArray, g_configVote[0]);
				if (idx < MAX_VOTES) {
					strcopy(g_voteNames[idx], 32, g_configVote[name]);
					strcopy(g_voteTriggers[idx], 32, g_configVote[trigger]);
					if (g_topMenu != INVALID_HANDLE)
						AddVoteToMenu(g_topMenu, g_configVote);
				} else {
					LogError("Reached maximum vote limit. Please increase MAX_VOTES and recompile.");
				}
			}
		}
		case 3: {
			if (strcmp(g_configSection, "options", false) == 0)
				ResetPack(g_configVote[optiondata]);
		}
		case 4: {
			if (g_configParam > -1) {
				ResetPack(g_configVote[paramdata][g_configParam]);
				g_configParam = -1;
			}
		}
	}
	g_configLevel--;
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) {
	if (failed)
		SetFailState("%T", "Plugin configuration error", LANG_SERVER);
}

/************************
 ** COMMANDS AND HOOKS **
 ************************/

public Action:Command_VoteMenu(client, args) {
	if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
		PrintVotesToConsole(client);
	else
		PrintVotesToMenu(client);
	return Plugin_Handled;
}

public Action:Command_ReloadConfig(client, args) {
	new exct = GetArraySize(g_voteArray);
	if (!LoadConfigFiles())
		LogError("%T", "Plugin configuration error", LANG_SERVER);
	else {
		new newvotect = GetArraySize(g_voteArray) - exct;
		if (newvotect > 0)
			ReplyToCommand(client, "[SM] Loaded %d new votes", GetArraySize(g_voteArray) - exct);
		else
			ReplyToCommand(client, "[SM] No new votes found", GetArraySize(g_voteArray) - exct);
	}
		
	return Plugin_Handled;
}

public Action:Command_CustomVote(client, args) {
	if (args == 0)
		return Command_VoteMenu(client, args);

	new String:votename[32];
	GetCmdArg(1, votename, sizeof(votename));

	new String:vparams[10][64];
	for (new i = 2; i <= args; ++i)
		GetCmdArg(i, vparams[i-2], 64);

	CVote_DoVote(client, votename, vparams, args-1);

	return Plugin_Handled;
}

public Action:Command_BanAuto(client, args) {
	if (args == 0)
		ReplyToCommand(client, "[SM] Usage: sm_ban_auto <steamid|ip> <time> [reason]");

	new String:banid[32];
	new String:bantime[8] = "30";
	new String:reason[8];

	GetCmdArg(1, banid, sizeof(banid));
	if (args > 1)
		GetCmdArg(2, bantime, sizeof(bantime));
	if (args > 2)
		GetCmdArg(3, reason, sizeof(reason));

	new bantimeint = StringToInt(bantime);

	new ididx = 0;
	new btarget = 0;
	new bool:bansuccess = false;
	new btargets[MAXPLAYERS];
	new String:btargetdesc[64];
	new bool:tn_is_ml;

	if (ProcessTargetString(banid, client, btargets, GetMaxClients(), COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI, btargetdesc, sizeof(btargetdesc), tn_is_ml) > 0) {
		btarget = btargets[0];
		bansuccess = BanClient(btarget, bantimeint, BANFLAG_AUTO, reason, "sm_ban_auto");
	} else {
		if (banid[0] == '#')
			ididx++;
		if (strncmp(banid[ididx], "STEAM_0:", 8) == 0) {
			bansuccess = BanIdentity(banid[ididx], bantimeint, BANFLAG_AUTHID, reason, "sm_ban_auto");
		} else {
			// TODO: Check for correct IP format - skipped for now because I don't
			// want to worry about IPv6 compatibility, BanIdentity should just return
			// false if it is an invalid IP.
			bansuccess = BanIdentity(banid[ididx], bantimeint, BANFLAG_IP, reason, "sm_ban_auto");
		}
	}

	if (bansuccess) {
		LogAction(client, btarget, "\"%L\" added ban (minutes \"%d\") (ip \"%s\") (reason \"%s\")",
			client, bantimeint, banid[ididx], reason);
		ReplyToCommand(client, "[SM] %s", "Ban added");
	}
	
	return Plugin_Handled;
}

public Action:Event_PlayerChat(Handle:event, const String:eventname[], bool:dontBroadcast) {
	new String:saytext[191];
	new String:votetrigger[32];
	new String:vparams[10][64];
	new pidx = 0;
	new vidx = 0;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "text", saytext, sizeof(saytext));
	new idx = BreakString(saytext, votetrigger, sizeof(votetrigger));

	if (strlen(votetrigger) > 0) {
		if ((vidx = InArray(votetrigger, g_voteTriggers, GetArraySize(g_voteArray))) > -1) {
			if (idx > -1)
				while((idx = BreakString(saytext[idx], vparams[pidx++], 64)) > -1 && pidx <= 10) { }
			SetCmdReplySource(SM_REPLY_TO_CHAT);
			CVote_DoVote(client, g_voteNames[vidx], vparams, pidx, true);
		}
	}
}

/**********************
 ** VOTING FUNCTIONS **
 **********************/

CVote_DoVote(client, const String:votename[], const String:vparams[][], vparamct, bool:fromtrigger=false) {
	new voteidx = InArray(votename, g_voteNames, GetArraySize(g_voteArray));
	new cvote[CVote];
	if (voteidx > -1) {
		GetArrayArray(g_voteArray, voteidx, cvote[0]);
	} else {
		if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			ReplyToCommand(client, "[SM] %t", "See console for output");
		PrintVotesToConsole(client);
		return;
	}

	if (!CanInitiateVote(client, cvote[admin]) && !fromtrigger) {
		ReplyToCommand(client, "[SM] %t", "No Access");
		return;
	}

	new String:errormsg[128];
	if (!IsVoteAllowed(client, voteidx, fromtrigger, errormsg, sizeof(errormsg))) {
		ReplyToCommand(client, "[SM] %s", errormsg);
		return;
	}

	if (vparamct < cvote[numparams]) {
		if (client == 0) {
			PrintToServer("[SM] %T", "Vote Requires Parameters", LANG_SERVER, cvote[numparams]);
			ClearCurrentVote();
		} else {
			// Reset client temp params
			g_clientTempParams[client][triggered] = fromtrigger;
			strcopy(g_clientTempParams[client][name], 128, votename);
			g_clientTempParams[client][paramct] = vparamct;
			g_clientTempParams[client][params] = CreateDataPack();
			for (new i = 0; i < vparamct; ++i)
				WritePackString(g_clientTempParams[client][params], vparams[i]);
			ResetPack(g_clientTempParams[client][params]);

			new Handle:parammenu = INVALID_HANDLE;
			switch (cvote[paramtypes][vparamct]) {
				case CVoteParamType_MapCycle: {
					new String:mapcycle[32];
					Format(mapcycle, sizeof(mapcycle), "sm_cvote %s", votename);
					parammenu = CreateStockMenu(StockMenuType_MapCycle, CVote_AddParamMenuHandler, client, mapcycle);
					if (GetMenuItemCount(parammenu) == 0)
						ReplyToCommand(client, "[SM] %s", "No maps were found.");
				}
				case CVoteParamType_Player: {
					parammenu = CreateStockMenu(StockMenuType_Player, CVote_AddParamMenuHandler, client);
					AddDisconnectedPlayers(parammenu, votename, vparamct);
					if (GetMenuItemCount(parammenu) == 0)
						ReplyToCommand(client, "[SM] %s", "No players can be targeted.");
				}
				case CVoteParamType_GroupPlayer: {
					parammenu = CreateStockMenu(StockMenuType_GroupPlayer, CVote_AddParamMenuHandler, client);
					AddDisconnectedPlayers(parammenu, votename, vparamct);
					if (GetMenuItemCount(parammenu) == 0)
						ReplyToCommand(client, "[SM] %s", "No players can be targeted.");
				}
				case CVoteParamType_Group: {
					parammenu = CreateStockMenu(StockMenuType_Group, CVote_AddParamMenuHandler, client);
					if (GetMenuItemCount(parammenu) == 0)
						ReplyToCommand(client, "[SM] %s", "No players can be targeted.");
				}
				case CVoteParamType_OnOff: {
					parammenu = CreateStockMenu(StockMenuType_OnOff, CVote_AddParamMenuHandler, client);
				}
				case CVoteParamType_YesNo: {
					parammenu = CreateStockMenu(StockMenuType_YesNo, CVote_AddParamMenuHandler, client);
				}
				case CVoteParamType_List: {
					decl String:value[64];
					decl String:desc[128];
					parammenu = CreateMenu(CVote_AddParamMenuHandler);
					for (new i = 0; i < cvote[paramoptions][vparamct]; ++i) {
						ReadPackString(cvote[paramdata][vparamct], value, sizeof(value));
						ReadPackString(cvote[paramdata][vparamct], desc, sizeof(desc));
						AddMenuItem(parammenu, value, desc, ITEMDRAW_DEFAULT);
					}
					ResetPack(cvote[paramdata][vparamct]);
				}
			}
			if (GetMenuItemCount(parammenu) > 0 && parammenu != INVALID_HANDLE) {
				if (g_adminMenuHandle != INVALID_HANDLE)
					SetMenuExitBackButton(parammenu, true);
				DisplayMenu(parammenu, client, 30);
			} else {
				ClearCurrentVote();
			}
		}
		return;
	}

	for (new i = 0; i < vparamct; ++i) {
		switch(cvote[paramtypes][i]) {
			case CVoteParamType_Player: {
				if (!CheckClientTarget(vparams[i], client, true)) {
					ReplyToCommand(client, "[SM] %t", "No matching client");
					CVote_DoVote(client, votename, vparams, i, fromtrigger);
					return;
				}
			}
			case CVoteParamType_GroupPlayer: {
				if (!CheckClientTarget(vparams[i], client, false)) {
					ReplyToCommand(client, "[SM] %t", "No matching client");
					CVote_DoVote(client, votename, vparams, i, fromtrigger);
					return;
				}
			}
			case CVoteParamType_Group: {
				if (!CheckClientTarget(vparams[i], client, false)) {
					ReplyToCommand(client, "[SM] %t", "No matching client");
					CVote_DoVote(client, votename, vparams, i, fromtrigger);
					return;
				}
			}
			case CVoteParamType_MapCycle: {
				if (!IsMapValid(vparams[i])) {
					ReplyToCommand(client, "[SM] %t", "Map was not found", vparams[i]);
					CVote_DoVote(client, votename, vparams, i, fromtrigger);
					return;
				}
			}
		}
	}

	decl String:votetitle[128];
	ProcessTemplateString(votetitle, sizeof(votetitle), cvote[title]);
	ReplaceParams(votetitle, sizeof(votetitle), vparams, vparamct, cvote[paramtypes], true);

	new statusidx = GetStatusIndex(voteidx, client, vparams, vparamct);
	if (statusidx == INVALID_VOTE)
		statusidx = CreateStatus(voteidx, client, vparams, vparamct);
	if (statusidx == INVALID_VOTE)
		return;
	new tstatus[CVoteStatus];
	GetArrayArray(g_voteStatus, statusidx, tstatus[0]);

	new tcount = cvote[triggercount];
	new tpercent = cvote[triggerpercent];
	if (cvote[type] == CVoteType_Chat) {
		tcount = Max(cvote[votes], tcount);
		tpercent = Max(51, Max(cvote[percent], tpercent));

		// Abort vote if vote target string does not include this client
		if (InArrayInt(client, tstatus[targets], tstatus[targetct]) == -1) {
			ReplyToCommand(client, "[SM] You are not allowed to vote.");
			return;
		}
	}
	new votect = 0;
	new players = 0;
	tstatus[clienttriggers][client] = 1;
	tstatus[clienttimestamps][client] = GetTime();
	SetArrayArray(g_voteStatus, statusidx, tstatus[0]);
	new maxc = GetMaxClients();
	for (new i = 1; i <= maxc; ++i) {
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			players++;
		if (tstatus[clienttriggers][i] > -1)
			votect++;
	}
	tcount = Max(RoundToCeil(FloatMul(FloatDiv(float(tpercent), float(100)), float(players))), tcount);
	if (fromtrigger) {
		new String:playername[64];
		new String:tnotice[128];
		GetClientName(client, playername, sizeof(playername));
		if (strlen(cvote[triggernotice]) == 0) {
			strcopy(tnotice, sizeof(tnotice), votetitle);
		} else {
			ProcessTemplateString(tnotice, sizeof(tnotice), cvote[triggernotice]);
			ReplaceParams(tnotice, sizeof(tnotice), vparams, vparamct, cvote[paramtypes], true);
		}
		ReplaceString(tnotice, sizeof(tnotice), "%u", playername);
		PrintToChatAll("[SM] %s [%d/%d votes]", tnotice, votect, tcount);
		if (votect < tcount)
			return;
	}

	ClearTempParams(client);
	g_lastVoteTime = GetTime();
	g_voteLastInitiated[voteidx] = g_lastVoteTime;

	// Chat votes are a special case
	if (cvote[type] == CVoteType_Chat) {
		new votepct = RoundToCeil(FloatMul(FloatDiv(float(votect), float(players)), float(100)));
		PrintToChatAll("[SM] %T", "Won The Vote", LANG_SERVER, votepct, votect);
		LogAction(0, -1, "Vote succeeded with %d%% of the vote (%d votes)", votepct, votect);

		new String:execcommand[128] = "";
		ProcessTemplateString(execcommand, sizeof(execcommand), cvote[execute]);
		ReplaceParams(execcommand, sizeof(execcommand), vparams, vparamct, cvote[paramtypes]);
		if (strlen(execcommand) > 0) {
			new Handle:strpack = CreateDataPack();
			WritePackString(strpack, execcommand);
			CreateTimer(GetConVarFloat(sm_cvote_executedelay), Timer_ExecuteCommand, strpack);
		}
	} else {
		g_activeVoteStatusIdx = statusidx;
		GetArrayArray(g_voteStatus, g_activeVoteStatusIdx, g_activeVoteStatus[0]);

		decl String:key[64];
		decl String:value[128];

		new String:label[128];
		new Handle:vm = CreateMenu(CVote_MenuHandler);

		SetMenuTitle(vm, votetitle);
		SetMenuExitButton(vm, false);

		switch(cvote[type]) {
			case CVoteType_List: {
				if (cvote[options] > 0) {
					for (new i = 0; i < cvote[options]; ++i) {
						ReadPackString(cvote[optiondata], key, sizeof(key));
						ReplaceParams(key, sizeof(key), vparams, vparamct, cvote[paramtypes]);
						ReadPackString(cvote[optiondata], value, sizeof(value));
						ReplaceParams(value, sizeof(value), vparams, vparamct, cvote[paramtypes], true);
						AddMenuItem(vm, key, value, ITEMDRAW_DEFAULT);
					}
					ResetPack(cvote[optiondata]);
				}
			}
			case CVoteType_Confirm: {
				Format(label, sizeof(label), "%T", "Yes", LANG_SERVER);
				AddMenuItem(vm, "1", label, ITEMDRAW_DEFAULT);
				Format(label, sizeof(label), "%T", "No", LANG_SERVER);
				AddMenuItem(vm, "0", label, ITEMDRAW_DEFAULT);
			}
			case CVoteType_OnOff: {
				Format(label, sizeof(label), "%T", "On", LANG_SERVER);
				AddMenuItem(vm, "1", label, ITEMDRAW_DEFAULT);
				Format(label, sizeof(label), "%T", "Off", LANG_SERVER);
				AddMenuItem(vm, "0", label, ITEMDRAW_DEFAULT);
			}
		}

		LogAction(client, -1, "%L initiated a %s vote", client, cvote[name]);
		ShowActivity(client, "%t", "Initiated a vote");
		SetVoteResultCallback(vm, CVote_VoteHandler);
		VoteMenu(vm, g_activeVoteStatus[targets], g_activeVoteStatus[targetct], 30);
	}
}

public CVote_AddParamMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Select) {
		new String:vparams[10][64];
		new Handle:parampack = g_clientTempParams[param1][params];
		new i = 0;
		for (i = 0; i < g_clientTempParams[param1][paramct]; ++i)
			ReadPackString(parampack, vparams[i], 64);
		CloseHandle(parampack);
		GetMenuItem(menu, param2, vparams[i++], 64);
		CVote_DoVote(param1, g_clientTempParams[param1][name], vparams, i, g_clientTempParams[param1][triggered]);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && g_adminMenuHandle != INVALID_HANDLE)
			RedisplayAdminMenu(g_adminMenuHandle, param1);
		ClearCurrentVote();
	}
}

public CVote_MenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_VoteCancel) {
		new cvote[CVote];
		GetArrayArray(g_voteArray, g_activeVoteStatus[voteindex], cvote[0]);
		new client = (param1 > -1 ? param1 : 0);
		LogAction(client, -1, "%L cancelled the %s vote", client, cvote[name]);
		ShowActivity(client, "%t", "Cancelled Vote");
		ClearCurrentVote();
	} else if (action == MenuAction_Select) {
		new String:itemval[64];
		new String:itemname[128];
		new style = 0;
		GetMenuItem(menu, param2, itemval, sizeof(itemval), style, itemname, sizeof(itemname));
		switch(GetConVarInt(sm_cvote_showstatus)) {
			case 1: {
				g_activeVoteStatus[clientvotes][param1] = param2;
				CVote_UpdateStatusPanel(menu);
			}
			case 2: {
				for (new i = 0; i < g_activeVoteStatus[targetct]; ++i)
					PrintToChat(g_activeVoteStatus[targets][i], "[SM] %t", "Vote Select Anonymous", itemname);
			}
			case 3: {
				new String:playername[64] = "";
				GetClientName(param1, playername, sizeof(playername));
				for (new i = 0; i < g_activeVoteStatus[targetct]; ++i)
					PrintToChat(g_activeVoteStatus[targets][i], "[SM] %t", "Vote Select", playername, itemname);
			}
		}
	}
}

CVote_UpdateStatusPanel(Handle:menu) {
	new cvote[CVote];
	GetArrayArray(g_voteArray, g_activeVoteStatus[voteindex], cvote[0]);

	new String:vparams[10][64];
	for (new i = 0; i < g_activeVoteStatus[paramct]; ++i)
		ReadPackString(g_activeVoteStatus[params], vparams[i], 64);
	ResetPack(g_activeVoteStatus[params]);

	new Handle:statuspanel = CreatePanel(INVALID_HANDLE);

	new String:votetitle[128];
	new String:label[128];
	ProcessTemplateString(votetitle, sizeof(votetitle), cvote[title]);
	ReplaceParams(votetitle, sizeof(votetitle), vparams, g_activeVoteStatus[paramct], cvote[paramtypes], true);
	SetPanelTitle(statuspanel, votetitle);
	DrawPanelText(statuspanel, " ");
	Format(label, sizeof(label), "%T:", "Results", LANG_SERVER);
	DrawPanelText(statuspanel, label);

	new String:paneltext[128];
	new String:itemval[64];
	new String:itemname[128];
	new itemct = GetMenuItemCount(menu);
	new style = 0;
	
	new maxc = GetMaxClients();
	new votesumm[10];
	for (new i = 1; i <= maxc; ++i)
		if (g_activeVoteStatus[clientvotes][i] > -1)
			votesumm[g_activeVoteStatus[clientvotes][i]]++;

	for (new j = 0; j < itemct; ++j) {
		GetMenuItem(menu, j, itemval, sizeof(itemval), style, itemname, sizeof(itemname));
		ProcessTemplateString(label, sizeof(label), itemname);
		ReplaceParams(label, sizeof(label), vparams, g_activeVoteStatus[paramct], cvote[paramtypes], true);
		Format(paneltext, sizeof(paneltext), "%s: %d", label, votesumm[j]);
		DrawPanelItem(statuspanel, paneltext, ITEMDRAW_DEFAULT);
	}

	DrawPanelText(statuspanel, " ");
	for (new j = itemct; j < 9; ++j)
		DrawPanelItem(statuspanel, " ", ITEMDRAW_NOTEXT);
	DrawPanelItem(statuspanel, "Close window", ITEMDRAW_CONTROL);

	for (new i = 1; i <= maxc; ++i)
		if (g_activeVoteStatus[clientvotes][i] > -1 && g_activeVoteStatus[clientnostatus][i] == -1)
			SendPanelToClient(statuspanel, i, CVote_PanelHandler, 5);

	CloseHandle(statuspanel);
}

public CVote_PanelHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		if (param2 == 10)
			g_activeVoteStatus[clientnostatus][param1] = 1;
		// Workaround breaking weapon selection
		if (param2 <= 5)
			ClientCommand(param1, "slot%d", param2);
	}
}

public CVote_VoteHandler(Handle:menu, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2]) {
	new cvote[CVote];
	GetArrayArray(g_voteArray, g_activeVoteStatus[voteindex], cvote[0]);

	new String:vparams[10][64];
	for (new i = 0; i < g_activeVoteStatus[paramct]; ++i)
		ReadPackString(g_activeVoteStatus[params], vparams[i], 64);
	ResetPack(g_activeVoteStatus[params]);

	new String:execcommand[128] = "";
	decl String:value[64];
	decl String:description[128];
	new style;
	GetMenuItem(menu, item_info[0][VOTEINFO_ITEM_INDEX], value, sizeof(value), style, description, sizeof(description));

	// See if top vote meets winning criteria
	new winvotes = item_info[0][VOTEINFO_ITEM_VOTES];
	new winpercent = RoundToFloor(FloatMul(FloatDiv(float(winvotes), float(num_votes)), float(100)));
	new playerpercent = RoundToFloor(FloatMul(FloatDiv(float(winvotes), float(GetClientCount(true))), float(100)));
	if (winpercent < cvote[percent]) {
		PrintToChatAll("[SM] %T", "Not Enough Vote Percentage", LANG_SERVER, cvote[percent], winpercent);
	} else if (playerpercent < cvote[abspercent]) {
		PrintToChatAll("[SM] %T", "Not Enough Vote Percentage", LANG_SERVER, cvote[abspercent], playerpercent);
	} else if (winvotes < cvote[votes]) {
		PrintToChatAll("[SM] %T", "Not Enough Votes", LANG_SERVER, cvote[votes], winvotes);
	} else {
		PrintToChatAll("[SM] %T", "Option Won The Vote", LANG_SERVER, description, winpercent, winvotes);
		LogAction(0, -1, "\"%s\" (%s) won with %d%% of the vote (%d votes)", description, value, winpercent, winvotes);
		// Don't need to take action if a confirmation vote was shot down
		if (cvote[type] != CVoteType_Confirm || strcmp(value, "1") == 0) {
			strcopy(vparams[g_activeVoteStatus[paramct]++], 64, value);
			ProcessTemplateString(execcommand, sizeof(execcommand), cvote[execute]);
			ReplaceParams(execcommand, sizeof(execcommand), vparams, g_activeVoteStatus[paramct], cvote[paramtypes]);
			switch (cvote[approve]) {
				case CVoteApprove_None: {
					if (strlen(execcommand) > 0) {
						ClearCurrentVote();
						new Handle:strpack = CreateDataPack();
						WritePackString(strpack, execcommand);
						CreateTimer(GetConVarFloat(sm_cvote_executedelay), Timer_ExecuteCommand, strpack);
					}
				}
				case CVoteApprove_Admin: {
					decl String:targetdesc[128];
					new vtargets[MAXPLAYERS+1];
					new vtargetct = 0;

					if ((vtargetct = ProcessVoteTargetString(
							"@admins",
							vtargets,
							targetdesc,
							sizeof(targetdesc))) <= 0) {
						PrintToChatAll("[SM] %T %T", "No Admins Found To Approve Vote", LANG_SERVER, "Cancelled Vote", LANG_SERVER);
					} else {
						CVote_ConfirmVote(vtargets, vtargetct, execcommand, description);
					}
				}
				case CVoteApprove_Sender: {	
					new vtargets[1];
					vtargets[0] = g_activeVoteStatus[sender];
					new vtargetct = 1;
					CVote_ConfirmVote(vtargets, vtargetct, execcommand, description);
				}
			}
		}
	}
	ClearCurrentVote();
}

CVote_ConfirmVote(vtargets[], vtargetct, const String:execcommand[], const String:description[]) {
	new Handle:cm = CreateMenu(CVote_ConfirmMenuHandler);

	SetMenuTitle(cm, "%T", "Accept Vote Result", LANG_SERVER, description);
	SetMenuExitButton(cm, false);
	AddMenuItem(cm, execcommand, "Yes", ITEMDRAW_DEFAULT);
	AddMenuItem(cm, "0", "No", ITEMDRAW_DEFAULT);

	g_confirmMenus = vtargetct;
	for (new i = 0; i < vtargetct; ++i)
		DisplayMenu(cm, vtargets[i], 30);
}

public CVote_ConfirmMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
		if (g_confirmMenus > 0) {
			if (--g_confirmMenus == 0)
				PrintToChatAll("[SM] %T %T", "No Admins Approved Vote", LANG_SERVER, "Cancelled Vote", LANG_SERVER);
		}
	} else if (action == MenuAction_Select) {
		if (g_confirmMenus > 0) {
			g_confirmMenus = 0;
			new String:execcommand[128];
			GetMenuItem(menu, param2, execcommand, sizeof(execcommand));
			if (param2 == 1) {
				ShowActivity(param1, "%T", "Vote Rejected", LANG_SERVER);
				LogAction(param1, -1, "Vote rejected by %L", param1);
			} else {
				ShowActivity(param1, "%T", "Vote Accepted", LANG_SERVER);
				if (strlen(execcommand) > 0) {
					LogAction(param1, -1, "Vote approved by %L", param1);
					new Handle:strpack = CreateDataPack();
					WritePackString(strpack, execcommand);
					CreateTimer(GetConVarFloat(sm_cvote_executedelay), Timer_ExecuteCommand, strpack);
				}
			}
		}
	}
}

/***********************
 ** UTILITY FUNCTIONS **
 ***********************/

public Action:Timer_ExecuteCommand(Handle:timer, any:strpack) {
	decl String:command[128];
	ResetPack(strpack);
	ReadPackString(strpack, command, sizeof(command));
	CloseHandle(strpack);
	LogAction(0, -1, "Executing \"%s\"", command);
	ServerCommand(command);
}

// Get the index for an existing vote status, or create a new one and return the index
stock GetStatusIndex(voteidx, vsender, const String:vparams[][], vparamct) {
	new ssize = GetArraySize(g_voteStatus);
	new String:tparam[64];
	new tstatus[CVoteStatus];
	new bool:match = false;

	for (new i = 0; i < ssize; ++i) {
		GetArrayArray(g_voteStatus, i, tstatus[0]);
		if (tstatus[voteindex] == voteidx) {
			match = true;
			for (new j = 0; j < vparamct; ++j) {
				ReadPackString(tstatus[params], tparam, sizeof(tparam));
				if (strcmp(vparams[j], tparam) != 0)
					match = false;
			}
			ResetPack(tstatus[params]);
			if (match) {
				new currtime = GetTime();
				new cvote[CVote];
				GetArrayArray(g_voteArray, voteidx, cvote[0]);
				for (new j = 1; j <= MAXPLAYERS; ++j)
					if (tstatus[clienttriggers][j] > -1 && currtime - tstatus[clienttimestamps][j] > cvote[triggerexpires])
						tstatus[clienttriggers][j] = -1;
				SetArrayArray(g_voteStatus, i, tstatus[0]);
				return i;
			}
		}
	}

	return INVALID_VOTE;
}

stock CreateStatus(voteidx, vsender, const String:vparams[][], vparamct) {
	// No match, create a new status
	new cvote[CVote];
	GetArrayArray(g_voteArray, voteidx, cvote[0]);

	new vstatus[CVoteStatus];
	vstatus[voteindex] = voteidx;
	vstatus[paramct] = vparamct;
	for (new i = 1; i <= MAXPLAYERS; ++i) {
		vstatus[clientvotes][i] = -1;
		vstatus[clientnostatus][i] = -1;
		vstatus[clienttriggers][i] = -1;
		vstatus[clienttimestamps][i] = 0;
	}

	new String:targetstr[32] = "@all";
	decl String:targetdesc[128];
	decl targetlist[MAXPLAYERS+1];

	if (strlen(cvote[target]) > 0)
		strcopy(targetstr, sizeof(targetstr), cvote[target]);

	vstatus[targetct] = ProcessVoteTargetString(
				targetstr,
				vstatus[targets],
				targetdesc,
				sizeof(targetdesc));

	vstatus[params] = CreateDataPack();
	vstatus[paramdata] = CreateDataPack();
	for (new i = 0; i < vparamct; ++i) {
		WritePackString(vstatus[params], vparams[i]);
		if (cvote[paramtypes][i] == CVoteParamType_Player
				|| cvote[paramtypes][i] == CVoteParamType_GroupPlayer
				|| cvote[paramtypes][i] == CVoteParamType_Group) {
			ProcessVoteTargetString(vparams[i], targetlist, targetdesc, sizeof(targetdesc));
			WritePackString(vstatus[paramdata], targetdesc);
		} else {
			WritePackString(vstatus[paramdata], "");
		}
	}
	ResetPack(vstatus[params]);
	ResetPack(vstatus[paramdata]);

	vstatus[sender] = vsender;

	return PushArrayArray(g_voteStatus, vstatus[0]);
}

stock RemoveExpiredStatuses() {
	new tstatus[CVoteStatus];
	new cvote[CVote];
	new currtime = GetTime();
	for (new i = 0; i < GetArraySize(g_voteStatus); ++i) {
		if (g_activeVoteStatusIdx != i) {
			GetArrayArray(g_voteStatus, i, tstatus[0]);
			GetArrayArray(g_voteArray, tstatus[voteindex], cvote[0]);
			new trigct = 0;
			for (new j = 1; j <= MAXPLAYERS; ++j) {
				if (tstatus[clienttriggers][j] > -1) {
					if (currtime - tstatus[clienttimestamps][j] <= cvote[triggerexpires])
						trigct++;
				}
			}
			// Not active and no unexpired triggers found, clean from memory
			if (trigct == 0)
				RemoveFromArray(g_voteStatus, i--);
		}
	}
}

stock IsVoteAllowed(client, voteidx, bool:fromtrigger, String:errormsg[], msglen) {
	new cvote[CVote];
	GetArrayArray(g_voteArray, voteidx, cvote[0]);

	new lang = LANG_SERVER;
	if (client > 0)
		lang = GetClientLanguage(client);

	if (IsVoteInProgress() || (g_activeVoteStatusIdx > -1 && (g_activeVoteStatusIdx != voteidx || g_activeVoteStatus[sender] != client))) {
		Format(errormsg, msglen, "%T", "Vote in Progress", lang);
		return false;
	}

	new currtime = GetTime();
	new vd = CheckVoteDelay();
	vd = Max(vd, (g_mapStartTime + GetConVarInt(sm_cvote_mapdelay)) - currtime);
	vd = Max(vd, (g_mapStartTime + cvote[mapdelay]) - currtime);
	vd = Max(vd, (g_lastVoteTime + GetConVarInt(sm_vote_delay)) - currtime);
	vd = Max(vd, (g_voteLastInitiated[voteidx] + cvote[delay]) - currtime);
	if (fromtrigger) {
		vd = Max(vd, (g_lastVoteTime + GetConVarInt(sm_cvote_triggerdelay)) - currtime);
		vd = Max(vd, (g_voteLastInitiated[voteidx] + cvote[triggerdelay]) - currtime);
	}

	if (vd > 0) {
		Format(errormsg, msglen, "%T", "Vote Delay Seconds", lang, vd);
		return false;
	}

	return true;
}

stock bool:CanInitiateVote(client, String:command[]) {
	if (strlen(command) == 0) {
		if (GetConVarBool(sm_cvote_adminonly))
			return ((GetUserFlagBits(client) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC || (GetUserFlagBits(client) & ADMFLAG_ROOT) == ADMFLAG_ROOT);
		else
			return true;
	} else if (CheckCommandAccess(client, command, ADMFLAG_ROOT)) {
		return true;
	}
	return false;
}

stock ProcessVoteTargetString(const String:targetstr[], vtargets[], String:targetdesc[], targetdesclen, client=0, nomulti=false) {
	new maxc = GetMaxClients();
	new vtargetct = 0;

	if (!nomulti && strcmp(targetstr, "@admins") == 0) {
		for (new i = 1; i <= maxc; ++i)
			if (IsClientInGame(i) && (GetUserFlagBits(i) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC)
				vtargets[vtargetct++] = i;
		PrintToServer("%d admins", vtargetct);
		strcopy(targetdesc, targetdesclen, "admins");
	} else {
		new filter = 0;
		new skipped = 0;
		if (nomulti) 
			filter = filter|COMMAND_FILTER_NO_MULTI;
		new bool:tn_is_ml = false;
		vtargetct = ProcessTargetString(targetstr, 0, vtargets, maxc, filter, targetdesc, targetdesclen, tn_is_ml);
		if (client > 0) {
			new AdminId:aid = GetUserAdmin(client);
			decl AdminId:tid;
			for (new i = 0; i < vtargetct; ++i) {
				tid = GetUserAdmin(vtargets[i]);
				if (tid == INVALID_ADMIN_ID
						//|| (aid == INVALID_ADMIN_ID && !GetAdminFlag(tid, Admin_Generic, Access_Effective))
						|| (aid != INVALID_ADMIN_ID && CanAdminTarget(aid, tid)))
					vtargets[i - skipped] = vtargets[i];
				else
					skipped++;
			}
			vtargetct -= skipped;
		}
	}

	return vtargetct;
}

stock GetParamCount(const String:expr[]) {
	new idx = -1;
	new max = 0;
	new pnum = 0;
	while ((idx = IndexOf(expr, '#', idx)) > -1) {
		if (IsCharNumeric(expr[idx+1])) {
			pnum = expr[idx+1] - 48;
			if (pnum > max) max = pnum;
		}
	}
	while ((idx = IndexOf(expr, '@', idx)) > -1) {
		if (IsCharNumeric(expr[idx+1])) {
			pnum = expr[idx+1] - 48;
			if (pnum > max) max = pnum;
		}
	}
	return max;
}

stock IndexOf(const String:str[], char, offset=-1) {
	for (new i = offset + 1; i < strlen(str); ++i)
		if (str[i] == char)
			return i;
	return -1;
}

stock InArrayInt(needle, haystack[], hsize) {
	for (new i = 0; i < hsize; ++i)
		if (needle == haystack[i])
			return i;
	return -1;
}

stock InArray(const String:needle[], const String:haystack[][], hsize) {
	for (new i = 0; i < hsize; ++i)
		if (strcmp(needle, haystack[i]) == 0)
			return i;
	return -1;
}

stock Max(first, second) {
	if (first > second)
		return first;
	return second;
}

stock PrintVotesToMenu(client) {
	if (client == 0)
		return;

	new s = GetArraySize(g_voteArray);
	new tvote[CVote];
	new String:votetitle[128];
	new String:voteparams[10][64];
	new String:errormsg[128];
	new CVoteParamType:voteparamtypes[10];
	new voteparamct = 0;

	new Handle:menu = CreateMenu(CVote_VoteListMenuHandler);
	SetMenuTitle(menu, "%T:", "Available Votes", LANG_SERVER);

	for (new i = 0; i < s; ++i) {
		GetArrayArray(g_voteArray, i, tvote[0]);
		voteparamct = tvote[numparams];
		for (new k = 0; k < tvote[numparams]; ++k) {
			voteparamtypes[k] = CVoteParamType_List;
			switch (tvote[paramtypes][k]) {
				case CVoteParamType_MapCycle: {
					strcopy(voteparams[k], 32, "<map>");
				}
				case CVoteParamType_Player: {
					strcopy(voteparams[k], 32, "<player>");
				}
				case CVoteParamType_GroupPlayer: {
					strcopy(voteparams[k], 32, "<group/player>");
				}
				case CVoteParamType_Group: {
					strcopy(voteparams[k], 32, "<group>");
				}
				case CVoteParamType_OnOff: {
					strcopy(voteparams[k], 32, "<on/off>");
				}
				case CVoteParamType_YesNo: {
					strcopy(voteparams[k], 32, "<yes/no>");
				}
				case CVoteParamType_List: {
					strcopy(voteparams[k], 32, "<value>");
				}
			}
		}

		ProcessTemplateString(votetitle, sizeof(votetitle), tvote[title]);
		ReplaceParams(votetitle, sizeof(votetitle), voteparams, voteparamct, voteparamtypes, true);

		if (CanInitiateVote(client, tvote[admin])) {
			if (IsVoteAllowed(client, i, false, errormsg, sizeof(errormsg)))
				AddMenuItem(menu, tvote[name], votetitle, ITEMDRAW_DEFAULT);
			else
				AddMenuItem(menu, tvote[name], votetitle, ITEMDRAW_DISABLED);
		} else if (strlen(tvote[trigger]) > 0) {
			if (IsVoteAllowed(client, i, true, errormsg, sizeof(errormsg)))
				AddMenuItem(menu, tvote[name], votetitle, ITEMDRAW_DEFAULT);
			else
				AddMenuItem(menu, tvote[name], votetitle, ITEMDRAW_DISABLED);
		}
	}

	if (GetMenuItemCount(menu) > 0)
		DisplayMenu(menu, client, 30);
}

public CVote_VoteListMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Select) {
		new String:p[1][1];
		new String:votename[32];
		GetMenuItem(menu, param2, votename, sizeof(votename));

		// Fetch the vote definition
		new voteidx = InArray(votename, g_voteNames, GetArraySize(g_voteArray));
		new tvote[CVote];
		if (voteidx > -1) {
			GetArrayArray(g_voteArray, voteidx, tvote[0]);
			// Check user access
			if (CanInitiateVote(param1, tvote[admin]))
				CVote_DoVote(param1, votename, p, 0);
			else if (strlen(tvote[trigger]) > 0)
				CVote_DoVote(param1, votename, p, 0, true);
			else
				PrintToChat(param1, "This vote can only be initiated by an admin.");
		}
	}
}

stock PrintVotesToConsole(client) {
	new s = GetArraySize(g_voteArray);
	new tvote[CVote];
	new String:votetitle[128];
	PrintToConsole(client, "Available votes:");
	for (new i = 0; i < s; ++i) {
		GetArrayArray(g_voteArray, i, tvote[0]);
		if (client == 0 || CanInitiateVote(client, tvote[admin])) {
			ProcessTemplateString(votetitle, sizeof(votetitle), tvote[title]);
			PrintToConsole(client, "  %20s %s", tvote[name], votetitle);
		}
	}
}

stock ProcessTemplateString(String:dest[], destlen, const String:source[]) {
	decl String:cvar[32];
	decl String:expr[destlen];
	decl String:modifiers[10][32];
	new destidx = 0;

	new modcount = 0;
	new negate = 0;
	new start = -1;
	new end = -1;
	new firstmod = -1;

	for (new i = 0; i < strlen(source); ++i) {
		if (start == -1 && source[i] == '{') {
			strcopy(dest[destidx], i - end, source[end + 1]);
			destidx += i - end - 1;
			start = i;
			end = 0;
		}
		if (start ==  i-1 && source[i] == '!') negate = 1;
		if (start > -1 && source[i] == '|' && firstmod == -1) firstmod = i - start - 1 - negate;
		if (start > -1 && source[i] == '}') end = i;
		if (start > -1 && end > 0) {
			// Parse expression
			new exprsize = (end-start) - negate;
			strcopy(expr, exprsize, source[start+1+negate]);
			if (firstmod > -1) {
				strcopy(cvar, firstmod + 1, expr);
				modcount = ExplodeString(expr[firstmod + 1], "|", modifiers, 10, 32);
			} else {
				strcopy(cvar, exprsize, expr);
				modcount = 0;
			}

			// Replace
			new Handle:cvh = FindConVar(cvar);
			if (cvh != INVALID_HANDLE) {
				decl String:val[128];
				GetConVarString(cvh, val, sizeof(val));
				if (negate) {
					if (strcmp(val, "0") == 0) strcopy(val, 2, "1");
					else strcopy(val, 2, "0");
				}
				for (new j = 0; j < modcount; ++j) {
					if (strcmp(modifiers[j], "onoff") == 0) {
						if (strcmp(val, "0") == 0) strcopy(val, 4, "off");
						else strcopy(val, 3, "on");
					} else if (strcmp(modifiers[j], "yesno") == 0) {
						if (strcmp(val, "0") == 0) strcopy(val, 4, "no");
						else strcopy(val, 3, "yes");
					} else if (strcmp(modifiers[j], "capitalize") == 0
							|| strcmp(modifiers[j], "cap") == 0) {
						val[0] = CharToUpper(val[0]);
					} else if (strcmp(modifiers[j], "upper") == 0) {
						for(new k = 0; k < strlen(val); ++k)
							val[k] = CharToUpper(val[k]);
					} else if (strcmp(modifiers[j], "lower") == 0) {
						for(new k = 0; k < strlen(val); ++k)
							val[k] = CharToLower(val[k]);
					}
				}
				strcopy(dest[destidx], destlen, val);
				destidx += strlen(val);
			}

			// Reset flags
			start = -1;
			firstmod = -1;
			negate = 0;
		}
	}
	strcopy(dest[destidx], strlen(source) - end, source[end + 1]);
}

stock ReplaceParams(String:source[], sourcelen, const String:vparams[][], vparamct, CVoteParamType:ptypes[], bool:pretty=false, client=0) {
	new String:token[3];
	new String:replace[128];
	new String:quoted[128];
	new vtargets[MAXPLAYERS+1];
	new String:targetdesc[128];
	new vtargetct;
	for (new i = 0; i < vparamct; ++i) {
		if (pretty) {
			switch(ptypes[i]) {
				case CVoteParamType_Player: {
					vtargetct = ProcessVoteTargetString(vparams[i], vtargets, targetdesc, sizeof(targetdesc), client, true);
					if (vtargetct > 0)
						strcopy(replace, sizeof(replace), targetdesc);
				}
				case CVoteParamType_GroupPlayer: {
					vtargetct = ProcessVoteTargetString(vparams[i], vtargets, targetdesc, sizeof(targetdesc), client);
					if (vtargetct > 0)
						strcopy(replace, sizeof(replace), targetdesc);
				}
				case CVoteParamType_Group: {
					vtargetct = ProcessVoteTargetString(vparams[i], vtargets, targetdesc, sizeof(targetdesc), client);
					if (vtargetct > 0)
						strcopy(replace, sizeof(replace), targetdesc);
				}
				case CVoteParamType_OnOff: {
					if (strcmp(vparams[i], "1") == 0)
						strcopy(replace, sizeof(replace), "on");
					else
						strcopy(replace, sizeof(replace), "off");
				}
				case CVoteParamType_YesNo: {
					if (strcmp(vparams[i], "1") == 0)
						strcopy(replace, sizeof(replace), "yes");
					else
						strcopy(replace, sizeof(replace), "no");
				}
				default: {
					strcopy(replace, sizeof(replace), vparams[i]);
				}
			}
			strcopy(quoted, sizeof(quoted), replace);
		} else {
			strcopy(replace, sizeof(replace), vparams[i]);
			Format(quoted, sizeof(quoted), "\"%s\"", replace);
		}
		Format(token, sizeof(token), "@%d", i + 1);
		ReplaceString(source, sourcelen, token, replace);
		Format(token, sizeof(token), "#%d", i + 1);
		ReplaceString(source, sourcelen, token, quoted);
	}
}

ResetVoteCache(cvote[CVote]) {
	strcopy(cvote[name], 32, "");
	strcopy(cvote[admin], 32, "");
	strcopy(cvote[trigger], 32, "");
	strcopy(cvote[triggernotice], 128, "");
	strcopy(cvote[target], 32, "@all");
	strcopy(cvote[execute], 128, "");
	cvote[triggerpercent] = 0;
	cvote[triggercount] = 0;
	cvote[triggerexpires] = 300;
	cvote[delay] = 0;
	cvote[triggerdelay] = 0;
	cvote[mapdelay] = 0;
	cvote[percent] = GetConVarInt(sm_cvote_minpercent);
	cvote[abspercent] = 0;
	cvote[votes] = GetConVarInt(sm_cvote_minvotes);
	cvote[approve] = CVoteApprove_None;
	cvote[type] = CVoteType_List;
	cvote[options] = 0;
	cvote[numparams] = 0;
	for (new i = 0; i < 10; ++i) {
		cvote[paramoptions][i] = 0;
		cvote[paramdata][i] = INVALID_HANDLE;
	}
}

ClearTempParams(client) {
	g_clientTempParams[client][voteindex] = -1;
	g_clientTempParams[client][paramct] = 0;
}

ClearCurrentVote() {
	if (g_activeVoteStatusIdx > -1) {
		RemoveFromArray(g_voteStatus, g_activeVoteStatusIdx);
		g_activeVoteStatusIdx = -1;
	}
	g_adminMenuHandle = INVALID_HANDLE;
}

CheckClientTarget(const String:targetstr[], client, bool:nomulti) {
	new vtargets[MAXPLAYERS+1];
	new String:targetdesc[128];
	new vtargetct = ProcessVoteTargetString(targetstr, vtargets, targetdesc, sizeof(targetdesc), client, nomulti);
	return vtargetct > 0;
}

/*****************************************************************
 ** STOCK MENU FUNCTIONS (will hopefully be added to adminmenu) **
 *****************************************************************/

enum TargetGroup {
	String:groupName[32],
	String:groupTarget[32]
}

new g_targetGroups[32][TargetGroup];
new g_targetGroupCt = -1;
new g_mapSerial = -1;
new Handle:g_mapList = INVALID_HANDLE;

Handle:CreateStockMenu(StockMenuType:menutype, MenuHandler:menuhandler, client, const String:mapcycle[] = "sm_cvote") {
	new Handle:menu = CreateMenu(menuhandler);
	switch(menutype) {
		case StockMenuType_MapCycle: {
			if (g_mapList == INVALID_HANDLE)
				g_mapList = CreateArray(32);
			ReadMapList(g_mapList, g_mapSerial, mapcycle, MAPLIST_FLAG_CLEARARRAY);
			new mapct = GetArraySize(g_mapList);
			new String:mapname[32];
			for (new i = 0; i < mapct; ++i) {
				GetArrayString(g_mapList, i, mapname, sizeof(mapname));
				AddMenuItem(menu, mapname, mapname, ITEMDRAW_DEFAULT);
			}
		}
		case StockMenuType_Player: {
			AddPlayerItems(menu, client);
		}
		case StockMenuType_GroupPlayer: {
			AddGroupItems(menu);
			AddPlayerItems(menu, client);
		}
		case StockMenuType_Group: {
			AddGroupItems(menu);
		}
		case StockMenuType_OnOff: {
			AddMenuItem(menu, "1", "On", ITEMDRAW_DEFAULT);
			AddMenuItem(menu, "0", "Off", ITEMDRAW_DEFAULT);
		}
		case StockMenuType_YesNo: {
			AddMenuItem(menu, "1", "Yes", ITEMDRAW_DEFAULT);
			AddMenuItem(menu, "0", "No", ITEMDRAW_DEFAULT);
		}
	}
	return menu;
}

AddPlayerItems(Handle:menu, client) {
	new String:playername[64];
	new String:steamid[32];
	new String:playerid[32];
	new vtargets[MAXPLAYERS+1];
	new String:targetdesc[128];
	new vtargetct;
	
	vtargetct = ProcessVoteTargetString("@all", vtargets, targetdesc, sizeof(targetdesc), client);

	for (new i = 0; i < vtargetct; ++i) {
		if (vtargets[i] > 0 && IsClientInGame(vtargets[i])) {
			if (IsFakeClient(vtargets[i])) {
				Format(playerid, sizeof(playerid), "#%d", GetClientUserId(vtargets[i]));
			} else if (!IsClientAuthorized(vtargets[i])) {
				// Use IP address if not authorized - won't work with most commands!
				GetClientIP(vtargets[i], steamid, sizeof(steamid));
				Format(playerid, sizeof(playerid), "#%s", steamid);
			} else {
				GetClientAuthString(vtargets[i], steamid, sizeof(steamid));
				Format(playerid, sizeof(playerid), "#%s", steamid);
			}
			GetClientName(vtargets[i], playername, sizeof(playername));
			AddMenuItem(menu, playerid, playername, ITEMDRAW_DEFAULT);
		}
	}
}

AddDisconnectedPlayers(Handle:menu, const String:votename[], pidx) {
	new String:steamids[MAXPLAYERS*2][32];
	new sidx = 0;
	new maxc = GetMaxClients();
	new String:steamid[32];
	for (new i = 1; i <= maxc; ++i) {
		if (IsClientConnected(i) && !IsFakeClient(i)) {
			GetClientAuthString(i, steamid, sizeof(steamid));
			Format(steamids[sidx++], 32, "#%s", steamid);
		}
	}
	for (new i = 0; i < GetArraySize(g_voteStatus); ++i) {
		if (strcmp(g_activeVoteStatus[name], votename) == 0) {
			new String:sid[32];
			new String:sname[64];
			new String:label[64];
			for (new j = 0; j <= pidx; ++j) {
				ReadPackString(g_activeVoteStatus[params], sid, sizeof(sid));
				ReadPackString(g_activeVoteStatus[paramdata], sname, sizeof(sname));
			}
			ResetPack(g_activeVoteStatus[params]);
			ResetPack(g_activeVoteStatus[paramdata]);
			if (InArray(sid, steamids, sizeof(steamids)) == -1) {
				Format(label, sizeof(label), "* %s", sname);
				AddMenuItem(menu, sid, sname, ITEMDRAW_DEFAULT);
				strcopy(steamids[sidx++], 32, sid);
			}
		}
	}
}

AddGroupItems(Handle:menu) {
	if (g_targetGroupCt == -1) {
		g_targetGroupCt = 0;
		new String:groupconfig[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, groupconfig, sizeof(groupconfig), "configs/adminmenu_grouping.txt");
		new Handle:parser = SMC_CreateParser();
		SMC_SetReaders(parser, gtNewSection, gtKeyValue, gtEndSection);
		new line = 0;
		SMC_ParseFile(parser, groupconfig, line);
		CloseHandle(parser);
	}
	for (new i = 0; i < g_targetGroupCt; ++i)
		AddMenuItem(menu, g_targetGroups[i][groupTarget], g_targetGroups[i][groupName], ITEMDRAW_DEFAULT);
}

public SMCResult:gtKeyValue(Handle:parser, const String:key[], const String:value[], bool:keyquotes, bool:valuequotes) {
	if (g_targetGroupCt < 32) {
		strcopy(g_targetGroups[g_targetGroupCt][groupName], 32, key);
		strcopy(g_targetGroups[g_targetGroupCt++][groupTarget], 32, value);
	}
}
public SMCResult:gtNewSection(Handle:parser, const String:section[], bool:quotes) {}
public SMCResult:gtEndSection(Handle:parser) {}

// DEBUG - DELETE ME
stock Action:Command_AddAdmin(client, args) {
	new tct = 0;
	new bool:ml = false;
	new maxc = GetMaxClients();
	new t[maxc];
	new String:td[32];
	new String:ts[32];
	GetCmdArg(1, ts, sizeof(ts));
	tct = ProcessTargetString(ts, 0, t, maxc, 0, td, sizeof(td), ml);
	for (new i = 0; i < tct; ++i)
		SetUserFlagBits(t[i], ADMFLAG_GENERIC);
}
