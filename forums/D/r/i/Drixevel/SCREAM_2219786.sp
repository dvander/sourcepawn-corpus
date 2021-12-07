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
	RegConsoleCmd("sm_scream", Scream);
}

public Action:Scream(client, args)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	SetVariantString("HalloweenLongFall");
	AcceptEntityInput(client, "SpeakResponseConcept");
	
	return Plugin_Handled;
}