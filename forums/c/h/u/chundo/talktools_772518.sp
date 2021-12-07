/*
 * Talk Tools
 * Written by chundo (chundo@mefightclub.com)
 *
 * Licensed under the GPLv3
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define TALKTOOLS_PLUGIN_VERSION "0.1"

public Plugin:myinfo = 
{
	name = "Talk Tools",
	author = "chundo",
	description = "Add keybindings for team- and all-talk regardless of sv_alltalk setting",
	version = "0.1",
	url = "http://www.mefightclub.com/"
};

new Handle:g_cvarEnable = INVALID_HANDLE;
new Handle:g_cvarTeamTalk = INVALID_HANDLE;
new Handle:g_cvarAllTalk = INVALID_HANDLE;
new Handle:g_cvarAllTalkAdmin = INVALID_HANDLE;
new Handle:g_cvarWelcome = INVALID_HANDLE;
new Handle:g_cvarSvAllTalk = INVALID_HANDLE;

public OnPluginStart() {
	CreateConVar("sm_talktools_version", TALKTOOLS_PLUGIN_VERSION, "Talk Tools version.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvarEnable = CreateConVar("sm_talktools_enable", "1", "Enable Talk Tools.", FCVAR_PLUGIN);
	g_cvarTeamTalk = CreateConVar("sm_talktools_teamtalk", "1", "Enable team talk with +voiceteam.", FCVAR_PLUGIN);
	g_cvarAllTalk = CreateConVar("sm_talktools_alltalk", "1", "Enable all talk with +voiceall.", FCVAR_PLUGIN);
	g_cvarAllTalkAdmin = CreateConVar("sm_talktools_alltalk_admin", "", "Admin command privilege required to use alltalk when sv_alltalk = 0.", FCVAR_PLUGIN);
	g_cvarWelcome = CreateConVar("sm_talktools_welcome", "1", "Display a welcome message to new users explaining how to use this plugin.", FCVAR_PLUGIN);
	g_cvarSvAllTalk = FindConVar("sv_alltalk");

	// Speak to all if sv_alltalk is off
	RegConsoleCmd("+voiceall", Command_AllTalkStart);
	RegConsoleCmd("-voiceall", Command_TalkStop);

	// Speak to team only if sv_alltalk is on
	RegConsoleCmd("+voiceteam", Command_TeamTalkStart);
	RegConsoleCmd("-voiceteam", Command_TalkStop);

	// Speak to team or all, depending on current sv_alltalk setting
	RegConsoleCmd("+voiceother", Command_OtherTalkStart);
	RegConsoleCmd("-voiceother", Command_TalkStop);

	RegConsoleCmd("talkhelp", Command_TalkHelp);

	HookConVarChange(g_cvarSvAllTalk, Change_Enable);
	HookConVarChange(g_cvarEnable, Change_Enable);
	HookConVarChange(g_cvarAllTalk, Change_Enable);
	HookConVarChange(g_cvarTeamTalk, Change_Enable);

	AutoExecConfig(false);
}

public Change_Enable(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (strcmp(oldval, newval) != 0) {
		if (cvar == g_cvarAllTalk) {
			if (strcmp(newval, "1") == 0)
				PrintToChatAll("\x01[SM] UberTalk has been enabled. Type \x04!talkhelp\x01 for details.");
			else
				PrintToChatAll("\x01[SM] UberTalk has been disabled.");
		} else if (cvar == g_cvarTeamTalk) {
			if (strcmp(newval, "1") == 0)
				PrintToChatAll("\x01[SM] TeamTalk has been enabled. Type \x04!talkhelp\x01 for details.");
			else
				PrintToChatAll("\x01[SM] TeamTalk has been disabled.");
		}
		ResetListening();
	}
}

public OnMapStart() {
	ResetListening();
}

public OnMapEnd() {
	new maxc = GetMaxClients();
	for (new i = 1; i <= maxc; ++i)
		if (IsClientConnected(i))
			SetClientListeningFlags(i, VOICE_NORMAL);
}

ResetListening() {
	new maxc = GetMaxClients();
	for (new i = 1; i <= maxc; ++i)
		if (IsClientConnected(i))
			ResetClientListening(i);
}

ResetClientListening(client) {
	if (GetConVarBool(g_cvarEnable) && GetConVarBool(g_cvarTeamTalk) && !GetConVarBool(g_cvarSvAllTalk))
		SetClientListeningFlags(client, VOICE_LISTENTEAM|VOICE_TEAM);
	else
		SetClientListeningFlags(client, VOICE_NORMAL);
}

public OnClientPutInServer(client) {
	if (GetConVarBool(g_cvarEnable) && GetConVarBool(g_cvarWelcome))
		CreateTimer(30.0, Timer_WelcomeMessage, client);
	ResetClientListening(client);
}

public OnClientDisconnect(client) {
	SetClientListeningFlags(client, VOICE_NORMAL);
}

public Action:Timer_WelcomeMessage(Handle:timer, any:client) {
	if (GetConVarBool(g_cvarWelcome) && GetConVarBool(g_cvarTeamTalk) && IsClientConnected(client) && IsClientInGame(client))
		PrintToChat(client, "\x01[SM] This server uses UberTalk. Type \x04!talkhelp\x01 for details.");
}

public Action:Command_AllTalkStart(client, args) {
	if (client > 0 && GetConVarBool(g_cvarEnable)) {
		decl String:atcmd[32];
		GetConVarString(g_cvarAllTalkAdmin, atcmd, sizeof(atcmd));
		if (!GetConVarBool(g_cvarSvAllTalk)) {
			if (GetConVarBool(g_cvarAllTalk) && (strlen(atcmd) == 0 || CheckCommandAccess(client, atcmd, ADMFLAG_ROOT))) {
				SetClientListeningFlags(client, VOICE_LISTENTEAM|VOICE_SPEAKALL);
			} else {
				PrintToChat(client, "[SM] All talk is not enabled.");
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_TeamTalkStart(client, args) {
	if (client > 0 && GetConVarBool(g_cvarEnable)) {
		if (GetConVarBool(g_cvarSvAllTalk)) {
			if (GetConVarBool(g_cvarTeamTalk)) {
				SetClientListeningFlags(client, VOICE_LISTENALL|VOICE_TEAM);
			} else {
				PrintToChat(client, "[SM] Team talk is not enabled.");
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_TalkStop(client, args) {
	ResetClientListening(client);
	return Plugin_Handled;
}

public Action:Command_OtherTalkStart(client, args) {
	if (client > 0 && GetConVarBool(g_cvarEnable)) {
		if (GetConVarBool(g_cvarSvAllTalk))
			return Command_TeamTalkStart(client, args);
		else
			return Command_AllTalkStart(client, args);
	}
	return Plugin_Handled;
}

public Action:Command_TalkHelp(client, args) {
	new Handle:helppanel = CreatePanel(INVALID_HANDLE);
	//SetPanelKeys(helppanel, 1<<9);
	SetPanelTitle(helppanel, "UberTalk/TeamTalk");
	DrawPanelText(helppanel, " ");
	DrawPanelText(helppanel, "UBERTALK allows you to speak to everyone even when");
	DrawPanelText(helppanel, "server alltalk is off, so that you can still talk to");
	DrawPanelText(helppanel, "just your team when needed.  To use it, enter these");
	DrawPanelText(helppanel, "lines in your autoexec.cfg:");
	DrawPanelText(helppanel, " ");
	DrawPanelText(helppanel, "alias +alltalk \"+voiceall; +voicerecord\"");
	DrawPanelText(helppanel, "alias -alltalk \"-voicerecord; -voiceall\"");
	DrawPanelText(helppanel, "bind f +alltalk");
	DrawPanelText(helppanel, " ");
	DrawPanelText(helppanel, "This will allow you to speak to everyone by");
	DrawPanelText(helppanel, "pressing \"f\".");
	DrawPanelText(helppanel, " ");
	DrawPanelText(helppanel, "TEAMTALK allows you to always speak to your own");
	DrawPanelText(helppanel, "team, even when dead, similar to a Ventrilo server.");
	DrawPanelText(helppanel, " ");
	DrawPanelText(helppanel, "0. Close Help");
	SendPanelToClient(helppanel, client, NullMenuHandler, 30);
	CloseHandle(helppanel);
	return Plugin_Handled;
}

public NullMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
}
