#include <sourcemod>

public Plugin:myinfo =
{
	name = "RoundWinText",
	author = "Cereal, |HS|Jesus",
	description = "Announces a definable string in chat after a round has been won.",
	version = "1.11",
	url = "http://www.sourcemod.net/"
};

// Global Variables
new Handle:RoundwinText = INVALID_HANDLE;
new Handle:Enabled = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("teamplay_round_win", RoundWin)
	RoundwinText = CreateConVar("sm_roundwin_text", "BUUUUUURRR!!!", "Text to be announced after a round has been won.");
	Enabled = CreateConVar("sm_roundwin_enabled", "1", "Toggle Round Win plugin on/off.");

	AutoExecConfig(true, "plugin_roundwin");
}

public RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(Enabled)) {
		decl String:roundwin[128]
		GetConVarString(RoundwinText, roundwin, 128);
		PrintToChatAll(" ~*~ %s", roundwin);
	}
	return Plugin_Handled;
}
