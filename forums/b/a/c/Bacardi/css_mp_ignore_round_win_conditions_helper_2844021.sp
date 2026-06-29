
public Plugin myinfo =
{
	name = "[cs:s] mp_ignore_round_win_conditions helper",
	author = "Bacardi",
	description = "Will run extra ingame check after cvar is disabled",
	version = "26.04.2026",
	url = "http://www.sourcemod.net/"
};

#include <sdktools>

Handle CheckWinConditions;
public void OnPluginStart()
{
	GameData gameconf = new GameData("cstrike.checkwinconditions");
	if(gameconf == null) SetFailState("Failed load gamedata file cstrike.checkwinconditions.txt");

	//char signature[] = "\x55\x8B\xEC\x83\xEC\x1C\xA1\x2A\x2A\x2A\x2A\x53\x56\x8B\xF1";
	// bool CCSGameRules::CheckWinConditions( void )

	StartPrepSDKCall(SDKCall_GameRules);
	//PrepSDKCall_SetSignature(SDKLibrary_Server, signature, strlen(signature));
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Signature, "CCSGameRules::CheckWinConditions(void)");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	CheckWinConditions = EndPrepSDKCall();

	if(CheckWinConditions == null) SetFailState("StartPrepSDKCall CheckWinConditions failed");


	ConVar mp_ignore_round_win_conditions = FindConVar("mp_ignore_round_win_conditions");

	if(mp_ignore_round_win_conditions == null) SetFailState("Game missing cvar mp_ignore_round_win_conditions");

	mp_ignore_round_win_conditions.AddChangeHook(convar_changed);

	delete gameconf;
}

public void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bool newv = StringToInt(newValue) == 0;

	if(newv)
		SDKCall(CheckWinConditions);
}