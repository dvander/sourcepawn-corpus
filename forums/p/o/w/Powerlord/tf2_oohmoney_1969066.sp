#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "[TF2] Ooh, money!",
	author = "Powerlord",
	description = "Replaces the Medic's Battle Cry with the \"Ooh, money!\" sound",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	AddCommandListener(Cmd_BattleCry, "voicemenu");
	
}

public Action:Cmd_BattleCry(client, const String:command[], argc)
{
	if (client < 1 || client > MaxClients || TF2_GetPlayerClass(client) != TFClass_Medic)
	{
		return Plugin_Continue;
	}
	
	new String:args[5];
	GetCmdArgString(args, sizeof(args));
	if (!StrEqual(args, "2 1"))
	{
		return Plugin_Continue;
	}
	
	SetVariantString("randomnum:100");
	AcceptEntityInput(client, "AddContext");
	
	SetVariantString("IsMvMDefender:1");
	AcceptEntityInput(client, "AddContext");
	
	SetVariantString("TLK_MVM_MONEY_PICKUP");
	AcceptEntityInput(client, "SpeakResponseConcept");
	
	AcceptEntityInput(client, "ClearContext");
	
	return Plugin_Handled;
}