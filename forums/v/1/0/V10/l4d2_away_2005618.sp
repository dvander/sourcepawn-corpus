#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "[L4D2] Away for versus",
	author = "V10",
	description = "Left 4 Dead 2: Away for versus",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.v10.name"
}

new Handle:g_hGoAwayFromKeyboard = INVALID_HANDLE;
new Handle:g_hCVAnnounce = INVALID_HANDLE;


public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if (!StrEqual(ModName, "left4dead2", false)) {
		SetFailState("Use this Left 4 Dead 2 only.");
		return;
	}
	
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
	if(client > 0 && client <= 64) {
		if (GetConVarBool(g_hCVAnnounce))
			CreateTimer(30.0, TimerAnnounce, client);
	}
}

public Action:Away(client, args)
{
	if(client > 0 && client <= 64) {
		if(GetClientTeam(client) == 2) {
			GoAwayFromKeyboard(client);
		} else {
			PrintToChat(client, "\x04[SM]\x03 Only survivors can use !away command.");
		}
	}
}


public Action:TimerAnnounce(Handle:timer, any:client)
{
	if (IsClientInGame(client))	{
		PrintToChat(client, "\x04[SM]\x03 Type !away if you need to go AFK.");
	}
}				

GoAwayFromKeyboard(client) { return SDKCall(g_hGoAwayFromKeyboard, client); }
