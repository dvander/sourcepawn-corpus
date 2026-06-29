#pragma semicolon 1

#include <sourcemod>
#include <multicolors>

#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION	"0.3.1"
#define UPDATE_URL		"https://github.com/RueLee/TF2-Increase-Host-TimeScale-on-Player-Death/blob/main/updater.txt"

ConVar g_hTimeScale;
ConVar g_hAddition;
ConVar g_hSineAddition;
ConVar g_hTeamCapturedValue;
ConVar g_hLinearTimescale;
ConVar g_hSinusodialSineTimescale;

bool g_bWaitingForPlayers;

float g_fSineAmplitude;
float g_fSineNumPIAddition;
float g_fSineNumDenom;
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
	name = "[TF2] Increase Host TimeScale on Player Death",
	author = "RueLee",
	description = "It's TF2 but the game gets faster everytime when a player dies.",
	version = PLUGIN_VERSION,
	url = "https://github.com/RueLee/TF2-Increase-Host-TimeScale-on-Player-Death"
}

public OnPluginStart() {
	CreateConVar("sm_timescale_version", PLUGIN_VERSION, "Plugin Version -- DO NOT MODIFY!", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hTimeScale = FindConVar("host_timescale");
	g_hAddition = CreateConVar("sm_timescale_addition", "0.04", "Change timescale by adding. | Default: 0.04");
	g_hSineAddition = CreateConVar("sm_timescale_sine_addition", "0.0", "Initial number. Value changes a lot overtime. | Default: 0");
	g_hTeamCapturedValue = CreateConVar("sm_timescale_captured_value", "0.1", "Decreases timescale when a team has captured the point. | Default: 0.1");
	g_hSinusodialSineTimescale = CreateConVar("sm_timescale_sinusodial_sine_enabled", "0", "");
	g_hLinearTimescale = CreateConVar("sm_timescale_linear_enabled", "1", "");
	
	g_fSineAmplitude = 1.0;
	g_fSineNumPIAddition = PI / 16;
	g_fSineNumDenom = 16.0;
	
	RegAdminCmd("sm_timescalereset", CmdResetTimeScale, ADMFLAG_GENERIC, "Resets host_timescale to the default value.");
	RegAdminCmd("sm_settimescale", CmdSetScale, ADMFLAG_GENERIC, "Sets host_timescale to a desired value.");
	RegAdminCmd("sm_enable_sine_timescale", CmdSinTimeScale, ADMFLAG_GENERIC, "Enables timescale to a sinousodial rate.");
	RegAdminCmd("sm_sineamplitude", CmdSinAmplitude, ADMFLAG_GENERIC, "Determines the amplitude for sine. Acceptable range: 0.25-2");
	RegAdminCmd("sm_setsineaddition", CmdSetSinAddition, ADMFLAG_GENERIC, "Sets a specific number to the denominator and then adds to that value. Ex: 20 will turn to PI/20.");
	
	RegAdminCmd("sm_enable_linear_timescale", CmdLinearTimeScale, ADMFLAG_GENERIC, "Enables timescale to a constant rate.");
	
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
	UnhookEvent("player_death", Event_PlayerDeath);
}

public void TF2_OnWaitingForPlayersEnd() {
	g_bWaitingForPlayers = false;
}

public Action Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast) {
	if (!g_bWaitingForPlayers) {
		g_hTimeScale.FloatValue = 1.0;
		HookEvent("player_death", Event_PlayerDeath);
	}
}

public Action Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast) {
	if (g_hSinusodialSineTimescale.IntValue >= 1) {
		//y = Asin(B) + D | Formula for sinusodial included in this code.
		g_hTimeScale.FloatValue = ((g_fSineAmplitude * Sine(g_hSineAddition.FloatValue)) + (g_fSineAmplitude + 0.5));
		g_hSineAddition.FloatValue += g_fSineNumPIAddition;
	}
	if (g_hLinearTimescale.IntValue >= 1) {
		g_hTimeScale.FloatValue += g_hAddition.FloatValue;
	}
	CPrintToChatAll("{green}[SM] {default}TimeScale is now %.5f", g_hTimeScale.FloatValue);
}

public Action Event_RoundWin(Event hEvent, const char[] sName, bool bDontBroadcast) {
	g_hTimeScale.FloatValue = 1.0;
	g_hSineAddition.FloatValue = 0.0;
	CPrintToChatAll("{green}[SM] {default}TimeScale resetted.");
	UnhookEvent("player_death", Event_PlayerDeath);
}

public Action Event_TeamCaptured(Event hEvent, const char[] sName, bool bDontBroadcast) {
	if (g_hLinearTimescale.IntValue >= 1) {
		g_hTimeScale.FloatValue -= g_hTeamCapturedValue.FloatValue;
		CPrintToChatAll("{green}[SM] {default}TimeScale decreased to %.5f", g_hTimeScale.FloatValue);
	}
}

public Action CmdResetTimeScale(int client, int args) {
	g_hTimeScale.FloatValue = 1.0;
	CPrintToChatAll("{green}[SM] {mediumvioletred}%N {default}has reset the timescale to the default value!", client);
	return Plugin_Handled;
}

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

public Action CmdSinTimeScale(int client, int args) {
	if (g_hSinusodialSineTimescale.IntValue == 0) {
		g_hLinearTimescale.IntValue = 0;
		g_hSinusodialSineTimescale.IntValue = 1;
		CPrintToChat(client, "{green}[SM] {default}Timescale rate has been set to sine sinousodial!");
	}
	else {
		CPrintToChat(client, "{green}[SM] {default}Cannot call this command while this is active!");
	}
	return Plugin_Handled;
}

public Action CmdSinAmplitude(int client, int args) {
	if (g_hSinusodialSineTimescale.IntValue == 0) {
		CReplyToCommand(client, "{green}[SM] {default}Cannot change value when sine rate is not enabled!");
	}
	else {
		if (args != 1) {
			CReplyToCommand(client, "{green}[SM] {default}Usage: sm_sineamplitude <value (0.25-2)> | Current Value: %.5f", g_fSineAmplitude);
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
	}
	return Plugin_Handled;
}

public Action CmdSetSinAddition(int client, int args) {
	if (args != 1) {
		ReplyToCommand(client, "[SM] Usage: sm_setsineaddition <float> | Current Value: PI/%.5f", g_fSineNumDenom);
		return Plugin_Handled;
	}
	
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	float f_SineAddition = StringToFloat(arg);
	g_fSineNumPIAddition = PI / f_SineAddition;
	g_hSineAddition.FloatValue = PI / f_SineAddition;
	g_fSineNumDenom = f_SineAddition;
	CPrintToChat(client, "[SM] Set Sine Addition to PI/%.5f!", g_fSineNumDenom);
	return Plugin_Handled;
}

public Action CmdLinearTimeScale(int client, int args) {
	if (g_hLinearTimescale.IntValue == 0) {
		g_hLinearTimescale.IntValue = 1;
		g_hSinusodialSineTimescale.IntValue = 0;
		CPrintToChat(client, "{green}[SM] {default}Timescale rate has been set to linear!");
	}
	else {
		CPrintToChat(client, "{green}[SM] {default}Cannot call this command while this is active!");
	}
}