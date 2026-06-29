
// https://forums.alliedmods.net/showpost.php?p=2738474&postcount=11


public Plugin myinfo = 
{
	name = "VoiceCommand spam",
	author = "Bacardi",
	description = "Spam more VoiceCommands",
	version = "26.3.2025",
	url = "https://forums.alliedmods.net/showpost.php?p=2738474&postcount=11"
};

#include <sdktools>

Handle SDKCallVoiceCommand;

public void OnPluginStart()
{

	ConVar cvar = FindConVar("tf_max_voice_speak_delay"); // Hidden developer cvar from TF2 game

	if(cvar != null)
	{
		cvar.SetBounds(ConVarBound_Lower, false);
		delete cvar; // <- maybe can't done :P
		LogMessage("Plugin removed convar lower bound, to allow voice spam you can now change: sm_cvar tf_max_voice_speak_delay -999");
	}


	GameData temp = new GameData("VoiceCommand.games");

	if(temp == INVALID_HANDLE) SetFailState("Why you no has VoiceCommand gamedata?");

	AddCommandListener(listen, "voicemenu");

	StartPrepSDKCall(SDKCall_GameRules);
	if(!PrepSDKCall_SetFromConf(temp, SDKConf_Virtual, "VoiceCommand")) SetFailState("SDKCall fail virtual offset VoiceCommand");

	delete temp;

	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

	SDKCallVoiceCommand = EndPrepSDKCall();
	

}

public Action listen(int client, const char[] command, int args)
{
	if(args < 2) return Plugin_Continue;

	if(!client || !IsClientInGame(client) || GetClientTeam(client) < 2 || !IsPlayerAlive(client) || IsFakeClient(client)) return Plugin_Continue;

	char arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	int menu = StringToInt(arg)

	GetCmdArg(2, arg, sizeof(arg));

	int item = StringToInt(arg)
	SDKCall(SDKCallVoiceCommand, client, menu, item);
	
	return Plugin_Continue;
}