#pragma semicolon 1

#include <sourcemod>
#include <multicolors>

#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION	"0.4.0"
#define UPDATE_URL		"https://github.com/RueLee/TF2-Timescale-Fun/blob/main/updater.txt"

ConVar g_hTimeScale;
ConVar g_hRandomMin;
ConVar g_hRandomMax;
ConVar g_hAddition;
ConVar g_hAdditionMax;
ConVar g_hSineAddition;
ConVar g_hTeamCapturedValue;
// ConVar g_hLinearTimescale;
// ConVar g_hSinusodialSineTimescale;

enum TimescaleMode {
	RANDOM,
	LINEAR,
	WAVELENGTH,
}

TimescaleMode g_hActiveTimescaleMode;
char g_sTimescaleModeArray[][] = {"Random", "Linear", "Wavelength"};

bool g_bWaitingForPlayers;
bool g_bIsModeRandom;

int g_iSelectedModeIdx;

float g_fSineAmplitude;
float g_fSineNumDenom;
float g_fSineNumPIAddition;
const float PI = 3.14159;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	char Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf")) {
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public Plugin:myinfo = {
	name = "[TF2] Timescale Fun",
	author = "RueLee",
	description = "It's TF2 but the game gets faster/slower everytime when a player dies.",
	version = PLUGIN_VERSION,
	url = "https://github.com/RueLee/TF2-Timescale-Fun"
}

public OnPluginStart() {
	CreateConVar("sm_timescale_fun_version", PLUGIN_VERSION, "Plugin Version -- DO NOT MODIFY!", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hTimeScale = FindConVar("host_timescale");
	g_hRandomMin = CreateConVar("sm_timescale_fun_random_min", "0.5", "Lowest random timescale range. | Default: 0.5");
	g_hRandomMax = CreateConVar("sm_timescale_fun_random_max", "2", "Highest random timescale range. | Default: 2");
	g_hAddition = CreateConVar("sm_timescale_fun_linear_addition", "0.05", "Change timescale by adding. | Default: 0.05");
	g_hAdditionMax = CreateConVar("sm_timescale_fun_linear_addition_max", "2.5", "Maximum number timescale can reach for linear mode. | Default: 2.5");
	g_hSineAddition = CreateConVar("sm_timescale_fun_sine_addition", "0.0", "Initial number. Value changes a lot overtime. | Default: 0");
	g_hTeamCapturedValue = CreateConVar("sm_timescale_fun_linear_captured_value", "1.5", "Divides the current timescale value. Only accepts linear. | Default: 1.5");
	// g_hSinusodialSineTimescale = CreateConVar("sm_timescale_sinusodial_sine_enabled", "0", "");
	// g_hLinearTimescale = CreateConVar("sm_timescale_linear_enabled", "1", "");
	
	// Declaring default variables inside OnPluginStart.
	g_fSineAmplitude = 0.5;
	g_fSineNumDenom = 14.0;
	g_fSineNumPIAddition = PI / g_fSineNumDenom;

	g_bIsModeRandom = true;

	g_iSelectedModeIdx = 0;
	
	RegAdminCmd("sm_timescalereset", CmdResetTimeScale, ADMFLAG_GENERIC, "Resets host_timescale to the default value.");
	RegAdminCmd("sm_settimescale", CmdSetScale, ADMFLAG_GENERIC, "Sets host_timescale to a desired value.");
	// RegAdminCmd("sm_enable_sine_timescale", CmdSinTimeScale, ADMFLAG_GENERIC, "Enables timescale to a sinousodial rate.");
	RegAdminCmd("sm_sineamplitude", CmdSinAmplitude, ADMFLAG_GENERIC, "Determines the amplitude for sine. Acceptable range: 0.25-2");
	RegAdminCmd("sm_setsineaddition", CmdSetSinAddition, ADMFLAG_GENERIC, "Sets a specific number to the denominator and then adds to that value. Ex: 20 will turn to PI/20.");
	
	// RegAdminCmd("sm_enable_linear_timescale", CmdLinearTimeScale, ADMFLAG_GENERIC, "Enables timescale to a constant rate.");
	RegAdminCmd("sm_timescalemenu", CmdTimescaleMenu, ADMFLAG_GENERIC, "Displays available timescale menu modes!");
	RegAdminCmd("sm_tsmenu", CmdTimescaleMenu, ADMFLAG_GENERIC, "");
	
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("teamplay_point_captured", Event_TeamCaptured);
	HookEvent("ctf_flag_captured", Event_TeamCaptured);
	
	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryAdded(const char[] sName) {
	if (StrEqual(sName, "updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnMapEnd() {
	g_hTimeScale.FloatValue = 1.0;
	//g_fSineAmplitude = 2;
}

public void TF2_OnWaitingForPlayersStart() {
	g_bWaitingForPlayers = true;
	
	// This does cause exceptions when it doesn't exist, but this is the only method I found for now.
	UnhookEvent("player_death", Event_PlayerDeath);
}

public void TF2_OnWaitingForPlayersEnd() {
	g_bWaitingForPlayers = false;
}

public Action Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast) {
	if (g_bWaitingForPlayers) {
		return Plugin_Handled;
	}
	g_hTimeScale.FloatValue = 1.0;	// In case something goes wrong with host_timescale.

	if (g_bIsModeRandom) {
		int iModeSize = sizeof(g_sTimescaleModeArray);
		int iRandomMode = GetRandomInt(0, iModeSize - 1);
		g_hActiveTimescaleMode = view_as<TimescaleMode>(iRandomMode);
	}
	else {
		g_hActiveTimescaleMode = view_as<TimescaleMode>(g_iSelectedModeIdx);
	}
	HookEvent("player_death", Event_PlayerDeath);
	CPrintToChatAll("{green}[SM] {default}Using active timescale mode: {lightblue}%s", g_sTimescaleModeArray[g_hActiveTimescaleMode]);
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast) {
	if (g_hActiveTimescaleMode == RANDOM) {
		g_hTimeScale.FloatValue = GetRandomFloat(g_hRandomMin.FloatValue, g_hRandomMax.FloatValue);
	}
	else if (g_hActiveTimescaleMode == LINEAR) {
		float fAddedResult = g_hTimeScale.FloatValue + g_hAddition.FloatValue;
		g_hTimeScale.FloatValue = (fAddedResult >= g_hAdditionMax.FloatValue) ? g_hAdditionMax.FloatValue : fAddedResult;
	}
	else if (g_hActiveTimescaleMode == WAVELENGTH) {
		g_hTimeScale.FloatValue = ((g_fSineAmplitude * Sine(g_hSineAddition.FloatValue)) + (g_fSineAmplitude + 0.5));
		g_hSineAddition.FloatValue += g_fSineNumPIAddition;
	}
	CPrintToChatAll("{green}[SM] {default}TimeScale is now %.3f", g_hTimeScale.FloatValue);
	return Plugin_Continue;
}

public Action Event_RoundWin(Event hEvent, const char[] sName, bool bDontBroadcast) {
	g_hTimeScale.FloatValue = 1.0;
	g_hSineAddition.FloatValue = 0.0;
	CPrintToChatAll("{green}[SM] {default}TimeScale has been reset.");
	UnhookEvent("player_death", Event_PlayerDeath);
	return Plugin_Continue;
}

// This only has a constant rate. Other implementations may be out soon.
public Action Event_TeamCaptured(Event hEvent, const char[] sName, bool bDontBroadcast) {
	if (g_hActiveTimescaleMode == LINEAR) {
		g_hTimeScale.FloatValue /= g_hTeamCapturedValue.FloatValue;
		CPrintToChatAll("{green}[SM] {default}TimeScale decreased to %.3f", g_hTimeScale.FloatValue);
	}
	return Plugin_Continue;
}

public Action CmdResetTimeScale(int client, int args) {
	g_hTimeScale.FloatValue = 1.0;
	CPrintToChatAll("{green}[SM] {dodgerblue}%N {default}has reset the timescale to the default value!", client);
	return Plugin_Handled;
}

// Will not work properly if sinusodial is active. More updates soon...
public Action CmdSetScale(int client, int args) {
	if (args != 1) {
		ReplyToCommand(client, "[SM] Usage: sm_settimescale <float>");
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	float scaleValue = StringToFloat(arg1);
	
	g_hTimeScale.FloatValue = scaleValue;
	CPrintToChatAll("{green}[SM] {mediumvioletred}%N {default}has set the timescale value to %.3f", client, scaleValue);
	return Plugin_Handled;
}

// Sine Cmds
// public Action CmdSinTimeScale(int client, int args) {
// 	if (g_hSinusodialSineTimescale) {
// 		CPrintToChat(client, "{green}[SM] {default}Cannot call this command while this is active!");
// 		return Plugin_Handled;
// 	}
// 	g_hLinearTimescale.IntValue = 0;
// 	g_hSinusodialSineTimescale.IntValue = 1;
// 	CPrintToChat(client, "{green}[SM] {default}Timescale rate has been set to sine sinousodial!");
// 	return Plugin_Handled;
// }

public Action CmdSinAmplitude(int client, int args) {
	// if (g_hActiveTimescaleMode != WAVELENGTH) {
	// 	CReplyToCommand(client, "{green}[SM] {default}Cannot change value when sine rate is not enabled!");
	// 	return Plugin_Handled;
	// }
	
	if (args != 1) {
		CReplyToCommand(client, "{green}[SM] {default}Usage: sm_sineamplitude <value (0.25-2)> | Current Value: %.3f", g_fSineAmplitude);
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	float fAmplitude = StringToFloat(arg1);
	
	if (fAmplitude < 0.25 || fAmplitude > 2) {
		CReplyToCommand(client, "{green}[SM] {default}Amplitude needs to be around 0.25-2!");
		return Plugin_Handled;
	}
	
	g_fSineAmplitude = fAmplitude;
	return Plugin_Handled;
}

public Action CmdSetSinAddition(int client, int args) {
	if (args != 1) {
		ReplyToCommand(client, "[SM] Usage: sm_setsineaddition <float> | Current Value: PI/%.3f", g_fSineNumDenom);
		return Plugin_Handled;
	}
	
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	float f_SineAddition = StringToFloat(arg);
	g_fSineNumPIAddition = PI / f_SineAddition;
	g_hSineAddition.FloatValue = PI / f_SineAddition;
	g_fSineNumDenom = f_SineAddition;
	CPrintToChat(client, "[SM] Set Sine Addition to PI/%.3f!", g_fSineNumDenom);
	return Plugin_Handled;
}

//Linear Cmds
// public Action CmdLinearTimeScale(int client, int args) {
// 	if (g_hLinearTimescale) {
// 		CPrintToChat(client, "{green}[SM] {default}Cannot call this command while this is active!");
// 		return Plugin_Handled;
// 	}
// 	g_hLinearTimescale.IntValue = 1;
// 	g_hSinusodialSineTimescale.IntValue = 0;
// 	CPrintToChat(client, "{green}[SM] {default}Timescale rate has been set to linear!");
// 	return Plugin_Handled;
// }

public int TimescaleMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		char sInfo[32];

		menu.GetItem(param2, sInfo, sizeof(sInfo));
		g_bIsModeRandom = (param2 == 0) ? true : false;
		g_iSelectedModeIdx = param2 - 1;
		CPrintToChat(param1, "{green}[SM] {default}You have selected %s! Mode will take effect next round!", sInfo);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
	
	// Eliminate warning compile message
	return 0;
}

public Action CmdTimescaleMenu(int client, int args) {
	Menu hMenu = new Menu(TimescaleMenuHandler);

	hMenu.SetTitle("Select Timescale Mode. Current: %s", g_sTimescaleModeArray[g_hActiveTimescaleMode]);
	hMenu.AddItem("to pick random from the list", "Pick Random");
	for (int i = 0; i < sizeof(g_sTimescaleModeArray); i++) {
		hMenu.AddItem(g_sTimescaleModeArray[i], g_sTimescaleModeArray[i]);
	}

	int iSecondTimeDisplay = 15;
	hMenu.Display(client, iSecondTimeDisplay);

	CPrintToChat(client, "{green}[SM] {default}Random Mode Status: %s", g_bIsModeRandom ? "True" : "False");

	return Plugin_Handled;
}