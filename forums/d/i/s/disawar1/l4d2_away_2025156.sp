#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Away for versus",
	author = "V10, raziEiL [disawar1]",
	description = "Left 4 Dead 2: Away for versus",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.v10.name"
}

new Handle:g_hGoAwayFromKeyboard = INVALID_HANDLE;
new Handle:g_hCVAnnounce = INVALID_HANDLE;


public OnPluginStart()
{
	new Handle:gConf = LoadGameConfigFile("l4d2_away");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "CTerrorPlayer::GoAwayFromKeyboard");
	//PrepSDKCall_SetReturnInfo(SDKType_Bool,SDKPass_Plain);
	g_hGoAwayFromKeyboard = EndPrepSDKCall();

	if (g_hGoAwayFromKeyboard == INVALID_HANDLE){
		CloseHandle(gConf);
		SetFailState("Can't get CTerrorPlayer::GoAwayFromKeyboard SDKCall!");
		return;
	}
	CloseHandle(gConf);

	CreateConVar("l4d2_away_version", PLUGIN_VERSION, "L4D2 Away for versus version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCVAnnounce = CreateConVar("l4d2_away_announce","1");

	RegConsoleCmd("sm_away", Away);

	AutoExecConfig(true, "l4d2_away");
}

public OnClientPutInServer(client)
{
	if(IsClient(client) && !IsFakeClient(client)) {
		if (GetConVarBool(g_hCVAnnounce))
			CreateTimer(30.0, TimerAnnounce, client);
	}
}

public Action:Away(client, args)
{
	if(IsClient(client)) {
		if(GetClientTeam(client) == 2) {
			GoAwayFromKeyboard(client);
		} else {
			PrintToChat(client, "\x04[SM]\x03 Only survivors can use !away command.");
		}
	}
	return Plugin_Handled;
}


public Action:TimerAnnounce(Handle:timer, any:client)
{
	if (IsClientInGame(client))	{
		PrintToChat(client, "\x04[SM]\x03 Type !away if you need to go AFK.");
	}
}

bool:IsClient(client) { return client > 0 && client <= 64; }

GoAwayFromKeyboard(client) { return SDKCall(g_hGoAwayFromKeyboard, client); }
