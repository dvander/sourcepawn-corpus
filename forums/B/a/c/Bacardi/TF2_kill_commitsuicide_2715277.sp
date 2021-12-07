
#include <sdktools>

Handle hCall;

public void OnPluginStart()
{
	PrepareSDKCall();
	AddCommandListener(kill, "kill");
}

public Action kill(int client, char[] command, int args)
{
	// 445	445	CTFPlayer::CommitSuicide(bool, bool)
	CommitSuicide(client, true, true);

	return Plugin_Handled;
}

CommitSuicide(int client, bool bExplode, bool bForce)
{
	if( client != 0 )
	{
		SDKCall(hCall, client, bExplode, bForce);
	}

	return;
}

PrepareSDKCall()
{
	Handle gameconf; // gamedata config

	if( (gameconf = LoadGameConfigFile("commitsuicide.games")) == null )
	{
		SetFailState("LoadGameConfigFile \"commitsuicide.games\" INVALID_HANDLE");
	}

	if(GameConfGetOffset(gameconf, "CommitSuicide") == -1)
	{
		delete gameconf;
		SetFailState("GameConfGetOffset \"CommitSuicide\" -1");
	}

	// CTFPlayer::
	// First SDKCall parameter, player index.
	StartPrepSDKCall(SDKCall_Player);

	// virtual function index (offset)
	//PrepSDKCall_SetVirtual(310); // Use gamedata file instead, OS Win/Linux/Mac
	if(!PrepSDKCall_SetFromConf(gameconf, SDKConf_Virtual, "CommitSuicide"))
	{
		SetFailState("PrepSDKCall_SetFromConf false, nothing found");
	}
	delete gameconf;

	// void CTFPlayer::CommitSuicide( bool bExplode /* = false */, bool bForce /*= false*/ )
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);

	hCall = EndPrepSDKCall();
	
	if(hCall == null) SetFailState("Failed prepare CommitSuicide, EndPrepSDKCall()");
}