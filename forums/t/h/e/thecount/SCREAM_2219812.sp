#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "[TF2] SCREAM",
	author = "Keith Warren (Jack of Designs)",
	description = "Allows anybody to scream at anytime!",
	version = "1.0.0",
	url = "http://www.jackofdesigns.com/"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_screamme", Scream);
	RegAdminCmd("sm_scream", Cmd_Scream, ADMFLAG_SLAY, "");
}

public Action:Cmd_Scream(client, args){
	if(args > 1){
		PrintToChat(client, "[SM] Usage: !scream [CLIENT]");
		return Plugin_Handled;
	}
	new targ = -1;
	if(args == 0){
		targ = client;
	}else{
		new String:arg1[MAX_NAME_LENGTH];
		GetCmdArg(1, arg1, sizeof(arg1));
		targ = FindTarget(client, arg1, false, false);
	}
	if(targ == -1){
		return Plugin_Handled;
	}
	if(!IsPlayerAlive(targ)){
		PrintToChat(client, "[SM] Target is not alive.");
		return Plugin_Handled;
	}
	SetVariantString("HalloweenLongFall");
	AcceptEntityInput(targ, "SpeakResponseConcept");
	return Plugin_Handled;
}

public Action:Scream(client, args)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		PrintToChat(client, "[SM] Must be alive to scream");
		return Plugin_Handled;
	}
	
	SetVariantString("HalloweenLongFall");
	AcceptEntityInput(client, "SpeakResponseConcept");
	
	return Plugin_Handled;
}