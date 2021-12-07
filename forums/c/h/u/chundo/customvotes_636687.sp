/*
 * Custom Votes
 * Written by chundo (chundo@mefightclub.com)
 *
 * Licensed under the GPL version 2 or above
 */

#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "0.4"

enum CVoteType {
	CVoteType_Confirm,
	CVoteType_List,
	CVoteType_OnOff
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
	CVoteParamType_List
}

enum CVote {
	String:name[32],
	String:title[128],
	String:admin[32],
	String:trigger[32],
	CVoteApprove:approve,
	percent,
	votes,
	delay,
	playerdelay,
	mapdelay,
	String:target[32],
	String:command[128],
	CVoteType:type,
	numparams,
	CVoteParamType:paramtypes[10],
	options,
	Handle:optiondata
}

enum TemplateVar_Type {
	TemplateVar_BoolType,
	TemplateVar_IntType,
	TemplateVar_FloatType,
	TemplateVar_StringType
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
new Handle:g_cvarStatus = INVALID_HANDLE;
new Handle:g_cvarTriggers = INVALID_HANDLE;
new Handle:g_cvarDelay = INVALID_HANDLE;
new Handle:g_cvarMapDelay = INVALID_HANDLE;
new Handle:g_cvarPlayerDelay = INVALID_HANDLE;
new Handle:g_cvarPercent = INVALID_HANDLE;
new Handle:g_cvarVotes = INVALID_HANDLE;

// Vote lookup tables
new Handle:g_voteArray = INVALID_HANDLE;
new String:g_voteNames[64][128];
new String:g_voteTriggers[64][128];

// Topmenu pointer
new Handle:g_topMenu;

// Timestamps for delay calculations
new g_voteLastInitiated[64];
new g_lastVoteTime = 0;
new g_mapStartTime;

// Config parsing state
new g_configLevel = 0;
new String:g_configSection[32];
new g_configParamsUsed = 0;
new g_configVote[CVote];

// Current vote details
new Handle:g_adminMenuHandle = INVALID_HANDLE;
new g_currentVote[CVote];
new g_currentVoteParamCt = 0;
new String:g_currentVoteParams[10][128];
new g_currentClientVotes[MAXPLAYERS];
new g_currentVoteSender = -1;
new g_currentVoteTargets[MAXPLAYERS];
new g_currentVoteTargetCt = 0;
new g_currentConfirmMenus = 0;

public Plugin:myinfo = {
	name = "Custom Votes",
	author = "chundo",
	description = "Allow easy addition of custom votes with configuration files",
	version = PLUGIN_VERSION,
	url = "http://www.mefightclub.com"
};

public OnPluginStart() {
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("customvotes.phrases");

	CreateConVar("sm_cvote_version", PLUGIN_VERSION, "Custom votes version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarStatus = CreateConVar("sm_cvote_showstatus", "1", "Show vote status. 0 = none, 1 = in side panel anonymously, 2 = in chat anonymously, 3 = in chat with player names.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvarTriggers = CreateConVar("sm_cvote_triggers", "1", "Allow in-chat vote triggers.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvarPlayerDelay = CreateConVar("sm_cvote_playerdelay", "60", "Default delay between non-admin initiated votes.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvarMapDelay = CreateConVar("sm_cvote_mapdelay", "0", "Default delay after maps starts before players can initiate votes.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvarPercent = CreateConVar("sm_cvote_minpercent", "60", "Minimum percentage of votes the winner must receive to be considered the winner.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvarVotes = CreateConVar("sm_cvote_minvotes", "0", "Minimum number of votes the winner must receive to be considered the winner.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvarDelay = FindConVar("sm_vote_delay");

	RegConsoleCmd("sm_cvote", Command_CustomVote, "Initiate a vote, or list available votes", FCVAR_PLUGIN);
	RegConsoleCmd("sm_votemenu", Command_VoteMenu, "List available votes", FCVAR_PLUGIN);

	if (!LoadConfigFiles()) {
		LogError("%T", "Plugin configuration error", LANG_SERVER);
	} else {
		// Loaded late, OnAdminMenuReady already fired
		new Handle:topmenu;
		if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
			OnAdminMenuReady(topmenu);
	}
	
	for (new i = 0; i < sizeof(g_voteLastInitiated); ++i)
		g_voteLastInitiated[i] = 0;
	ClearCurrentVote();

	AutoExecConfig(false);
}

public OnAdminMenuReady(Handle:topmenu) {
	// Called twice
	if (topmenu == g_topMenu)
		return;

	// Save handle to prevent duplicate calls
	g_topMenu = topmenu;

	// Add votes to admin menu
	new TopMenuObject:voting_commands = FindTopMenuCategory(topmenu, ADMINMENU_VOTINGCOMMANDS);
	if (voting_commands != INVALID_TOPMENUOBJECT) {
		new String:menu_id[38];
		for (new i = 0; i < GetArraySize(g_voteArray); ++i) {
			Format(menu_id, sizeof(menu_id), "cvote_%s", g_voteNames[i]);
			AddToTopMenu(topmenu,
				menu_id,
				TopMenuObject_Item,
				CVote_AdminMenuHandler,
				voting_commands,
				"sm_cvote",
				ADMFLAG_VOTE,
				g_voteNames[i]);
		}
	}
}

public OnConfigsExecuted() {
	if (GetConVarBool(g_cvarTriggers)) {
		//HookEvent("player_chat", Event_PlayerChat, EventHookMode_Post);
		HookEvent("player_say", Event_PlayerChat, EventHookMode_Post);
	}
	HookConVarChange(g_cvarTriggers, Change_Triggers);
}

public Change_Triggers(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (strcmp(oldval, newval) != 0) {
		if (strcmp(newval, "0") == 0) {
			//UnhookEvent("player_chat", Event_PlayerChat, EventHookMode_Post);
			UnhookEvent("player_say", Event_PlayerChat, EventHookMode_Post);
		} else {
			//HookEvent("player_chat", Event_PlayerChat, EventHookMode_Post);
			HookEvent("player_say", Event_PlayerChat, EventHookMode_Post);
		}
	}
}

public OnMapStart() {
	g_mapStartTime = GetTime();
}

public CVote_AdminMenuHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	new String:votename[32];
	GetTopMenuInfoString(topmenu, object_id, votename, sizeof(votename));
	new idx = InArray(votename, g_voteNames, sizeof(g_voteNames));
	if (idx > -1) {
		new vote[CVote];
		GetArrayArray(g_voteArray, idx, vote[0]);
		if (action == TopMenuAction_DisplayOption) {
			new String:votetitle[128];
			new String:voteparams[10][32];
			new CVoteParamType:voteparamtypes[10];
			new voteparamct = 0;
			voteparamct = vote[numparams];
			for (new k = 0; k < vote[numparams]; ++k) {
				voteparamtypes[k] = CVoteParamType_List;
				switch (vote[paramtypes][k]) {
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
					case CVoteParamType_List: {
						strcopy(voteparams[k], 32, "<value>");
					}
				}
			}
			ProcessTemplateString(votetitle, sizeof(votetitle), vote[title]);
			ReplaceParams(votetitle, sizeof(votetitle), voteparams, voteparamct, voteparamtypes, true);
			strcopy(buffer, maxlength, votetitle);
		} else if (action == TopMenuAction_SelectOption) {
			new String:params[1][1];
			g_adminMenuHandle = topmenu;
			CVote_DoVote(param, votename, params, 0);
		} else if (action == TopMenuAction_DrawOption) {
			new String:errormsg[128];
			if (strlen(vote[admin]) == 0 || CheckCommandAccess(param, vote[admin], ADMFLAG_ROOT))
				buffer[0] = !IsVoteAllowed(param, idx, errormsg, sizeof(errormsg)) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
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
	else
		ClearArray(g_voteArray);

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
				strcopy(g_configVote[trigger], sizeof(g_configVote[trigger]), value);
			else if(strcmp(key, "target", false) == 0)
				strcopy(g_configVote[target], sizeof(g_configVote[target]), value);
			else if(strcmp(key, "cmd", false) == 0)
				strcopy(g_configVote[command], sizeof(g_configVote[command]), value);
			else if(strcmp(key, "delay", false) == 0)
				g_configVote[delay] = StringToInt(value);
			else if(strcmp(key, "playerdelay", false) == 0)
				g_configVote[playerdelay] = StringToInt(value);
			else if(strcmp(key, "mapdelay", false) == 0)
				g_configVote[mapdelay] = StringToInt(value);
			else if(strcmp(key, "percent", false) == 0)
				g_configVote[percent] = StringToInt(value);
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
					} else if (strcmp(value, "list", false) == 0) {
						g_configVote[paramtypes][pidx] = CVoteParamType_List;
					}
					g_configVote[numparams] = Max(g_configVote[numparams], pidx + 1);
				}
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
				
			new idx = PushArrayArray(g_voteArray, g_configVote[0]);
			if (idx < 64) {
				strcopy(g_voteNames[idx], 128, g_configVote[name]);
				strcopy(g_voteTriggers[idx], 128, g_configVote[trigger]);
			}
		}
		case 3: {
			if (strcmp(g_configSection, "options", false) == 0)
				ResetPack(g_configVote[optiondata]);
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

public Action:Command_CustomVote(client, args) {
	if (args == 0)
		return Command_VoteMenu(client, args);

	new String:votename[32];
	GetCmdArg(1, votename, sizeof(votename));

	new String:params[10][128];
	for (new i = 2; i <= args; ++i)
		GetCmdArg(i, params[i-2], 128);

	CVote_DoVote(client, votename, params, args-1);

	return Plugin_Handled;
}

public Action:Event_PlayerChat(Handle:event, const String:eventname[], bool:dontBroadcast) {
	new String:saytext[191];
	new String:votetrigger[32];
	new String:params[10][128];
	new pidx = 0;
	new vidx = 0;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "text", saytext, sizeof(saytext));
	new idx = BreakString(saytext, votetrigger, sizeof(votetrigger));

	if ((vidx = InArray(votetrigger, g_voteTriggers, GetArraySize(g_voteArray))) > -1) {
		if (idx > -1)
			while((idx = BreakString(saytext[idx], params[pidx++], 128)) > -1 && pidx <= 10) { }
		SetCmdReplySource(SM_REPLY_TO_CHAT);
		CVote_DoVote(client, g_voteNames[vidx], params, pidx);
	}
}

/**********************
 ** VOTING FUNCTIONS **
 **********************/

CVote_DoVote(client, const String:votename[], const String:params[][], paramct) {
	new voteidx = InArray(votename, g_voteNames, GetArraySize(g_voteArray));
	if (voteidx > -1) {
		GetArrayArray(g_voteArray, voteidx, g_currentVote[0]);
	} else {
		if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			ReplyToCommand(client, "[SM] %t", "See console for output");
		PrintVotesToConsole(client);
		return;
	}

	if (strlen(g_currentVote[admin]) > 0 && !CheckCommandAccess(client, g_currentVote[admin], ADMFLAG_ROOT)) {
		// Chat keyword triggers seem to send replies to console
		ReplyToCommand(client, "[SM] %t", "No Access");
		return;
	}

	new String:errormsg[128];
	if (!IsVoteAllowed(client, voteidx, errormsg, sizeof(errormsg))) {
		ReplyToCommand(client, "[SM] %s", errormsg);
		return;
	}

	// Reset current pointers
	g_currentVoteParamCt = paramct;
	g_currentConfirmMenus = 0;
	g_currentVoteSender = client;

	if (paramct < g_currentVote[numparams]) {
		if (client == 0) {
			PrintToServer("[SM] %T", "Vote Requires Parameters", LANG_SERVER, g_currentVote[numparams]);
			ClearCurrentVote();
		} else {
			new Handle:parammenu = INVALID_HANDLE;
			switch (g_currentVote[paramtypes][paramct]) {
				case CVoteParamType_MapCycle: {
					parammenu = CreateStockMenu(StockMenuType_MapCycle, CVote_AddParamMenuHandler, client);
				}
				case CVoteParamType_Player: {
					parammenu = CreateStockMenu(StockMenuType_Player, CVote_AddParamMenuHandler, client);
				}
				case CVoteParamType_GroupPlayer: {
					parammenu = CreateStockMenu(StockMenuType_GroupPlayer, CVote_AddParamMenuHandler, client);
				}
				case CVoteParamType_Group: {
					parammenu = CreateStockMenu(StockMenuType_Group, CVote_AddParamMenuHandler, client);
				}
				case CVoteParamType_List: {
					// Not supported yet
				}
			}
			if (parammenu != INVALID_HANDLE) {
				if (g_adminMenuHandle != INVALID_HANDLE)
					SetMenuExitBackButton(parammenu, true);
				DisplayMenu(parammenu, client, 30);
			}
		}
		return;
	}
		
	decl String:targetdesc[128];

	new String:targetstr[32] = "@all";
	if (strlen(g_currentVote[target]) > 0)
		strcopy(targetstr, sizeof(targetstr), g_currentVote[target]);

	if ((g_currentVoteTargetCt = ProcessVoteTargetString(
			targetstr,
			g_currentVoteTargets,
			targetdesc,
			sizeof(targetdesc))) <= 0) {
		ReplyToTargetError(client, g_currentVoteTargetCt);
		return;
	}

	decl String:votetitle[128];
	decl String:key[128];
	decl String:value[128];

	for (new i = 0; i < paramct; ++i) {
		switch(g_currentVote[paramtypes][i]) {
			case CVoteParamType_Player: {
				if (!CheckClientTarget(params[i], client, true)) {
					CVote_DoVote(client, votename, params, i);
					return;
				}
			}
			case CVoteParamType_GroupPlayer: {
				if (!CheckClientTarget(params[i], client, false)) {
					CVote_DoVote(client, votename, params, i);
					return;
				}
			}
			case CVoteParamType_Group: {
				if (!CheckClientTarget(params[i], client, false)) {
					CVote_DoVote(client, votename, params, i);
					return;
				}
			}
			case CVoteParamType_MapCycle: {
				if (!IsMapValid(params[i])) {
					ReplyToCommand(client, "[SM] %t", "Map was not found", params[i]);
					CVote_DoVote(client, votename, params, i);
					return;
				}
			}
		}
		strcopy(g_currentVoteParams[i], 128, params[i]);
	}

	g_lastVoteTime = GetTime();
	g_voteLastInitiated[voteidx] = g_lastVoteTime;

	new String:label[128];
	new Handle:vm = CreateMenu(CVote_MenuHandler);

	ProcessTemplateString(votetitle, sizeof(votetitle), g_currentVote[title]);
	ReplaceParams(votetitle, sizeof(votetitle), g_currentVoteParams, g_currentVoteParamCt, g_currentVote[paramtypes], true);
	SetMenuTitle(vm, votetitle);
	SetMenuExitButton(vm, false);

	switch(g_currentVote[type]) {
		case CVoteType_List: {
			if (g_currentVote[options] > 0) {
				for (new i = 0; i < g_currentVote[options]; ++i) {
					ReadPackString(g_currentVote[optiondata], key, sizeof(key));
					ReplaceParams(key, sizeof(key), g_currentVoteParams, g_currentVoteParamCt, g_currentVote[paramtypes]);
					ReadPackString(g_currentVote[optiondata], value, sizeof(value));
					ReplaceParams(value, sizeof(value), g_currentVoteParams, g_currentVoteParamCt, g_currentVote[paramtypes], true);
					AddMenuItem(vm, key, value, ITEMDRAW_DEFAULT);
				}
				ResetPack(g_currentVote[optiondata]);
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

	LogAction(client, -1, "%L initiated a %s vote", client, g_currentVote[name]);
	ShowActivity(client, "%t", "Initiated a vote");
	SetVoteResultCallback(vm, CVote_VoteHandler);
	VoteMenu(vm, g_currentVoteTargets, g_currentVoteTargetCt, 30);
}

public CVote_AddParamMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Select) {
		GetMenuItem(menu, param2, g_currentVoteParams[g_currentVoteParamCt++], 128);
		CVote_DoVote(param1, g_currentVote[name], g_currentVoteParams, g_currentVoteParamCt);
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
		new client = (param1 > -1 ? param1 : 0);
		LogAction(client, -1, "%L cancelled the %s vote", client, g_currentVote[name]);
		ShowActivity(client, "%t", "Cancelled Vote");
		ClearCurrentVote();
	} else if (action == MenuAction_Select) {
		new String:itemval[128];
		new String:itemname[128];
		new style = 0;
		GetMenuItem(menu, param2, itemval, sizeof(itemval), style, itemname, sizeof(itemname));
		switch(GetConVarInt(g_cvarStatus)) {
			case 1: {
				g_currentClientVotes[param1] = param2;
				CVote_UpdateStatusPanel(menu);
			}
			case 2: {
				for (new i = 0; i < g_currentVoteTargetCt; ++i)
					PrintToChat(g_currentVoteTargets[i], "[SM] %t", "Vote Select Anonymous", itemname);
			}
			case 3: {
				new String:playername[64] = "";
				GetClientName(param1, playername, sizeof(playername));
				for (new i = 0; i < g_currentVoteTargetCt; ++i)
					PrintToChat(g_currentVoteTargets[i], "[SM] %t", "Vote Select", playername, itemname);
			}
		}
	}
}

CVote_UpdateStatusPanel(Handle:menu) {
	new Handle:statuspanel = CreatePanel(INVALID_HANDLE);

	new String:votetitle[128];
	new String:label[128];
	ProcessTemplateString(votetitle, sizeof(votetitle), g_currentVote[title]);
	ReplaceParams(votetitle, sizeof(votetitle), g_currentVoteParams, g_currentVoteParamCt, g_currentVote[paramtypes], true);
	SetPanelTitle(statuspanel, votetitle);
	DrawPanelText(statuspanel, " ");
	Format(label, sizeof(label), "%T:", "Results", LANG_SERVER);
	DrawPanelText(statuspanel, label);

	new String:paneltext[128];
	new String:itemval[128];
	new String:itemname[128];
	new itemct = GetMenuItemCount(menu);
	new style = 0;
	
	new votesumm[10];
	for (new i = 0; i < sizeof(g_currentClientVotes); ++i)
		if (g_currentClientVotes[i] > -1)
			votesumm[g_currentClientVotes[i]]++;

	for (new i = 0; i < itemct; ++i) {
		GetMenuItem(menu, i, itemval, sizeof(itemval), style, itemname, sizeof(itemname));
		ProcessTemplateString(label, sizeof(label), itemname);
		ReplaceParams(label, sizeof(label), g_currentVoteParams, g_currentVoteParamCt, g_currentVote[paramtypes], true);
		Format(paneltext, sizeof(paneltext), "%s: %d", label, votesumm[i]);
		DrawPanelItem(statuspanel, paneltext, ITEMDRAW_DISABLED);
	}

	for (new i = 0; i < g_currentVoteTargetCt; ++i)
		SendPanelToClient(statuspanel, g_currentVoteTargets[i], CVote_PanelHandler, 5);

	CloseHandle(statuspanel);
}

public CVote_PanelHandler(Handle:menu, MenuAction:action, param1, param2) {
	// No events for the status panel
}

public CVote_VoteHandler(Handle:menu, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2]) {
	new String:execcommand[128] = "";
	decl String:value[128];
	decl String:description[128];
	new style;
	GetMenuItem(menu, item_info[0][VOTEINFO_ITEM_INDEX], value, sizeof(value), style, description, sizeof(description));

	// See if top vote meets winning criteria
	new winvotes = item_info[0][VOTEINFO_ITEM_VOTES];
	new winpercent = RoundToFloor(FloatMul(FloatDiv(float(winvotes), float(num_votes)), float(100)));
	if (winpercent < g_currentVote[percent]) {
		PrintToChatAll("[SM] %T", "Not Enough Vote Percentage", LANG_SERVER, g_currentVote[percent], winpercent);
	} else if (winvotes < g_currentVote[votes]) {
		PrintToChatAll("[SM] %T", "Not Enough Votes", LANG_SERVER, g_currentVote[votes], winvotes);
	} else {
		PrintToChatAll("[SM] %T", "Won The Vote", LANG_SERVER, description, winpercent, winvotes);
		LogAction(0, -1, "\"%s\" (%s) won with %d%% of the vote (%d votes)", description, value, winpercent, winvotes);
		// Don't need to take action if a confirmation vote was shot down
		if (g_currentVote[type] != CVoteType_Confirm || strcmp(value, "1") == 0) {
			strcopy(g_currentVoteParams[g_currentVoteParamCt++], 128, value);
			ProcessTemplateString(execcommand, sizeof(execcommand), g_currentVote[command]);
			ReplaceParams(execcommand, sizeof(execcommand), g_currentVoteParams, g_currentVoteParamCt, g_currentVote[paramtypes]);
			switch (g_currentVote[approve]) {
				case CVoteApprove_None: {
					if (strlen(execcommand) > 0) {
						LogAction(0, -1, "Executing \"%s\"", execcommand);
						ServerCommand(execcommand);
					}
				}
				case CVoteApprove_Admin: {
					decl String:targetdesc[128];
					new targets[MAXPLAYERS];
					new targetct = 0;

					if ((targetct = ProcessVoteTargetString(
							"@admins",
							targets,
							targetdesc,
							sizeof(targetdesc))) <= 0) {
						PrintToChatAll("[SM] %T %T", "No Admins Found To Approve Vote", LANG_SERVER, "Cancelled Vote", LANG_SERVER);
					} else {
						CVote_ConfirmVote(targets, targetct, execcommand, description);
					}
				}
				case CVoteApprove_Sender: {	
					new targets[1];
					targets[0] = g_currentVoteSender;
					new targetct = 1;
					CVote_ConfirmVote(targets, targetct, execcommand, description);
				}
			}
		}
	}
	ClearCurrentVote();
}

CVote_ConfirmVote(targets[], targetct, const String:execcommand[], const String:description[]) {
	new Handle:cm = CreateMenu(CVote_ConfirmMenuHandler);

	SetMenuTitle(cm, "%T", "Accept Vote Result", LANG_SERVER, description);
	SetMenuExitButton(cm, false);
	AddMenuItem(cm, execcommand, "Yes", ITEMDRAW_DEFAULT);
	AddMenuItem(cm, "0", "No", ITEMDRAW_DEFAULT);

	g_currentConfirmMenus = targetct;
	for (new i = 0; i < targetct; ++i)
		DisplayMenu(cm, targets[i], 30);
}

public CVote_ConfirmMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
		if (g_currentConfirmMenus > 0) {
			if (--g_currentConfirmMenus == 0)
				PrintToChatAll("[SM] %T %T", "No Admins Approved Vote", LANG_SERVER, "Cancelled Vote", LANG_SERVER);
		}
	} else if (action == MenuAction_Select) {
		if (g_currentConfirmMenus > 0) {
			g_currentConfirmMenus = 0;
			new String:execcommand[128];
			GetMenuItem(menu, param2, execcommand, sizeof(execcommand));
			if (param2 == 1) {
				ShowActivity(param1, "%T", "Vote Rejected", LANG_SERVER);
				LogAction(param1, -1, "Vote rejected by %L", param1);
			} else {
				ShowActivity(param1, "%T", "Vote Accepted", LANG_SERVER);
				if (strlen(execcommand) > 0) {
					LogAction(param1, -1, "Vote approved by %L, executing \"%s\"", param1, execcommand);
					ServerCommand(execcommand);
				}
			}
		}
	}
}

/***********************
 ** UTILITY FUNCTIONS **
 ***********************/

stock IsVoteAllowed(client, voteidx, String:errormsg[], msglen) {
	new lang = LANG_SERVER;
	if (client > 0)
		lang = GetClientLanguage(client);

	if (IsVoteInProgress() || (g_currentVoteSender > -1 && g_currentVoteSender != client)) {
		Format(errormsg, msglen, "%T", "Vote in Progress", lang);
		return false;
	}

	new currtime = GetTime();
	new vd = CheckVoteDelay();
	vd = Max(vd, (g_mapStartTime + GetConVarInt(g_cvarMapDelay)) - currtime);
	vd = Max(vd, (g_voteLastInitiated[voteidx] + g_currentVote[mapdelay]) - currtime);
	vd = Max(vd, (g_lastVoteTime + GetConVarInt(g_cvarDelay)) - currtime);
	vd = Max(vd, (g_voteLastInitiated[voteidx] + g_currentVote[delay]) - currtime);
	if (client != 0) {
		new AdminId:aid = GetUserAdmin(client);
		if (aid == INVALID_ADMIN_ID || !GetAdminFlag(aid, Admin_Generic, Access_Effective)) {
			vd = Max(vd, (g_lastVoteTime + GetConVarInt(g_cvarPlayerDelay)) - currtime);
			vd = Max(vd, (g_voteLastInitiated[voteidx] + g_currentVote[playerdelay]) - currtime);
		}
	}

	if (vd > 0) {
		Format(errormsg, msglen, "%T", "Vote Delay Seconds", lang, vd);
		return false;
	}

	return true;
}

stock ProcessVoteTargetString(const String:targetstr[], targets[], String:targetdesc[], targetdesclen, client=0, nomulti=false) {
	new maxc = GetMaxClients();
	new targetct = 0;

	if (strcmp(targetstr, "@admins") == 0 && !nomulti) {
		for (new i = 1; i <= maxc; ++i) {
			if (IsClientInGame(i)) {
				new AdminId:aid = GetUserAdmin(i);
				if (aid != INVALID_ADMIN_ID && GetAdminFlag(aid, Admin_Generic, Access_Effective))
					targets[targetct++] = i;
			}
		}
		strcopy(targetdesc, targetdesclen, "admins");
	} else {
		new filter = COMMAND_FILTER_NO_BOTS;
		if (nomulti) 
			filter = filter|COMMAND_FILTER_NO_MULTI;
		new bool:tn_is_ml = false;
		targetct = ProcessTargetString(
			targetstr,
			client,
			targets,
			maxc,
			filter,
			targetdesc,
			targetdesclen,
			tn_is_ml);
	}

	return targetct;
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
	new vote[CVote];
	new String:votetitle[128];
	new String:voteparams[10][32];
	new CVoteParamType:voteparamtypes[10];
	new voteparamct = 0;

	new Handle:menu = CreateMenu(CVote_VoteListMenuHandler);
	SetMenuTitle(menu, "%T:", "Available Votes", LANG_SERVER);

	for (new i = 0; i < s; ++i) {
		GetArrayArray(g_voteArray, i, vote[0]);
		voteparamct = vote[numparams];
		for (new k = 0; k < vote[numparams]; ++k) {
			voteparamtypes[k] = CVoteParamType_List;
			switch (vote[paramtypes][k]) {
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
				case CVoteParamType_List: {
					strcopy(voteparams[k], 32, "<value>");
				}
			}
		}
		if (strlen(vote[admin]) == 0 || CheckCommandAccess(client, vote[admin], ADMFLAG_ROOT)) {
			ProcessTemplateString(votetitle, sizeof(votetitle), vote[title]);
			ReplaceParams(votetitle, sizeof(votetitle), voteparams, voteparamct, voteparamtypes, true);
			AddMenuItem(menu, vote[name], votetitle, ITEMDRAW_DEFAULT);
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
		CVote_DoVote(param1, votename, p, 0);
	}
}

stock PrintVotesToConsole(client) {
	new s = GetArraySize(g_voteArray);
	new vote[CVote];
	new String:votetitle[128];
	PrintToConsole(client, "Available votes:");
	for (new i = 0; i < s; ++i) {
		GetArrayArray(g_voteArray, i, vote[0]);
		if (client == 0) {
			ProcessTemplateString(votetitle, sizeof(votetitle), vote[title]);
			PrintToConsole(client, "  %20s %s", vote[name], votetitle);
		} else {
			new targetct = 0;
			new targets[MAXPLAYERS];
			new String:targetdesc[128];
			targetct = ProcessVoteTargetString(vote[target], targets, targetdesc, sizeof(targetdesc));
			if (targetct > 0) {
				for (new j = 0; j < targetct; ++j) {
					if (targets[j] == client && (strlen(vote[admin]) == 0 || CheckCommandAccess(client, vote[admin], ADMFLAG_ROOT))) {
						ProcessTemplateString(votetitle, sizeof(votetitle), vote[title]);
						PrintToConsole(client, "  %20s %s", vote[name], votetitle);
						break;
					}
				}
			}
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

stock ReplaceParams(String:source[], sourcelen, const String:params[][], paramct, CVoteParamType:ptypes[], bool:pretty=false, client=0) {
	new String:token[3];
	new String:replace[128];
	new String:quoted[128];
	new targets[MAXPLAYERS];
	new String:targetdesc[128];
	new targetct;
	for (new i = 0; i < paramct; ++i) {
		if (pretty) {
			switch(ptypes[i]) {
				case CVoteParamType_Player: {
					targetct = ProcessVoteTargetString(params[i], targets, targetdesc, sizeof(targetdesc), client, true);
					if (targetct > 0)
						strcopy(replace, sizeof(replace), targetdesc);
				}
				case CVoteParamType_GroupPlayer: {
					targetct = ProcessVoteTargetString(params[i], targets, targetdesc, sizeof(targetdesc), client);
					if (targetct > 0)
						strcopy(replace, sizeof(replace), targetdesc);
				}
				case CVoteParamType_Group: {
					targetct = ProcessVoteTargetString(params[i], targets, targetdesc, sizeof(targetdesc), client);
					if (targetct > 0)
						strcopy(replace, sizeof(replace), targetdesc);
				}
				default: {
					strcopy(replace, sizeof(replace), params[i]);
				}
			}
			strcopy(quoted, sizeof(quoted), replace);
		} else {
			strcopy(replace, sizeof(replace), params[i]);
			Format(quoted, sizeof(quoted), "\"%s\"", replace);
		}
		Format(token, sizeof(token), "@%d", i + 1);
		ReplaceString(source, sourcelen, token, replace);
		Format(token, sizeof(token), "#%d", i + 1);
		ReplaceString(source, sourcelen, token, quoted);
	}
}

ResetVoteCache(vote[CVote]) {
	strcopy(g_configVote[name], 32, "");
	strcopy(vote[admin], 32, "");
	strcopy(vote[trigger], 32, "");
	strcopy(vote[target], 32, "@all");
	strcopy(vote[command], 128, "");
	vote[delay] = 0;
	vote[playerdelay] = 0;
	vote[mapdelay] = 0;
	vote[percent] = GetConVarInt(g_cvarPercent);
	vote[votes] = GetConVarInt(g_cvarVotes);
	vote[approve] = CVoteApprove_None;
	vote[type] = CVoteType_List;
	vote[options] = 0;
	vote[numparams] = 0;
}

ClearCurrentVote() {
	ResetVoteCache(g_currentVote);
	for (new i = 0; i < MAXPLAYERS; ++i)
		g_currentClientVotes[i] = -1;
	g_currentVoteSender = -1;
	g_currentVoteParamCt = 0;
	g_currentVoteTargetCt = 0;
	g_adminMenuHandle = INVALID_HANDLE;
}

CheckClientTarget(const String:targetstr[], client, bool:nomulti) {
	new targets[MAXPLAYERS];
	new String:targetdesc[128];
	new targetct = ProcessVoteTargetString(targetstr, targets, targetdesc, sizeof(targetdesc), client, nomulti);
	if (targetct <= 0) {
		// Oops!  Targeting non-existent player or someone outside their immunity
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return false;
	}
	return true;
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

Handle:CreateStockMenu(StockMenuType:menutype, MenuHandler:menuhandler, client) {
	new Handle:menu = CreateMenu(menuhandler);
	switch(menutype) {
		case StockMenuType_MapCycle: {
			if (g_mapList == INVALID_HANDLE)
				g_mapList = CreateArray(32);
			ReadMapList(g_mapList, g_mapSerial, "sm_cvote", MAPLIST_FLAG_CLEARARRAY);
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
	new targets[MAXPLAYERS];
	new String:targetdesc[128];
	new targetct;
	
	targetct = ProcessVoteTargetString("@humans", targets, targetdesc, sizeof(targetdesc), client);

	for (new i = 0; i <= targetct; ++i) {
		if (targets[i] > 0 && IsClientInGame(targets[i])) {
			GetClientAuthString(targets[i], steamid, sizeof(steamid));
			Format(playerid, sizeof(playerid), "#%s", steamid);
			GetClientName(targets[i], playername, sizeof(playername));
			AddMenuItem(menu, playerid, playername, ITEMDRAW_DEFAULT);
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
