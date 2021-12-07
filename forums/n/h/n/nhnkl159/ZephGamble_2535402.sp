#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <store> //just add the include.

#define PREFIX "\x05[Gamble]\x01" // PREFIX

// === ConVars === //
ConVar gB_ShowGamble;
ConVar gB_MinimumBet;
ConVar gB_MaximumBet;
ConVar gB_WinPrecent;

public Plugin myinfo = 
{
	name = "[Zeph Store] Gamble Module",
	author = "nhnkl159",
	description = "Simple gamble module for zeph store.",
	version = "1.0",
	url = "http://keepomod.com/"
};

public void OnPluginStart()
{
	// === Player Commands === //
	RegConsoleCmd("sm_gamble", Cmd_Gamble, "Command for player to gamble his credits.");
	
	// === ConVars === //
	gB_ShowGamble = CreateConVar("sm_gamble_showgamble", "1", "Sets whether or not to show everyone gambles");
	gB_MinimumBet = CreateConVar("sm_gamble_minbet", "25", "Sets the minimum amount of credits to gamble");
	gB_MaximumBet = CreateConVar("sm_gamble_maxbet", "7000", "Sets the maximum amount of credits to gamble");
	gB_WinPrecent = CreateConVar("sm_gamble_winprecent", "40", "Sets the precent of winning in the gamble system");
	
	AutoExecConfig(true, "sm_storegamble");
}

public Action Cmd_Gamble(int client, int args)
{
	if(!IsValidClient(client)) //Let's check if client is valid first.
	{
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, 32);
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : sm_gamble <credits>", PREFIX);
		return Plugin_Handled; //returning cause there are no arg.
	}
	
	if(!isNumeric(arg1)) //Let's check if the arg entered is numberic.
	{
		CPrintToChat(client, "%s Please enter only numbers if you wish to gamble.", PREFIX);
		return Plugin_Handled; //returning cause this shit is not a number.
	}
	
	int gB_OurNumber = StringToInt(arg1); //Why you are always doing it on the function if you can do it once.
	int gB_PlayerCredits = Store_GetClientCredits(client); //Let's get client credits ! :D
	
	if(!IsNumberValid(gB_OurNumber)) //Let's check if client's number meets our criteria.
	{
		CPrintToChat(client, "%s Please enter a number between [\x07%d - %d\x01] if you wish to gamble.", PREFIX, gB_MinimumBet.IntValue, gB_MaximumBet.IntValue);
		return Plugin_Handled;
	}
	
	if(gB_OurNumber > gB_PlayerCredits) //Let's check if client had enough credits for this.
	{
		CPrintToChat(client, "%s You don't have this amount of credits.", PREFIX);
		return Plugin_Handled;
	}
	
	int gB_RandomNum = GetRandomInt(1, 100); //When we done with the check lets create new randomnum.
	
	if(gB_RandomNum <= gB_WinPrecent.IntValue)
	{
		//When player win , sets client credits and print to client / everyone chat about the happy winning.
		Store_SetClientCredits(client, gB_PlayerCredits + gB_OurNumber);
		Gamble_PrintToChat(client, gB_OurNumber, true);
	}
	else
	{
		//When player lose , sets client credits and print to client / everyone chat about the sad losing.
		Store_SetClientCredits(client, gB_PlayerCredits - gB_OurNumber);
		Gamble_PrintToChat(client, gB_OurNumber, false);
	}
	
	return Plugin_Handled;
}

stock void Gamble_PrintToChat(int client, int gB_Number, bool winner)
{
	if(gB_ShowGamble.BoolValue)
	{
		CPrintToChatAll("%s \x07%N\x01 just gambled \x07%d\x01 amount of credits and \x07%s", PREFIX, client, gB_Number, winner ? "won" : "lost");
	}
	else
	{
		CPrintToChat(client, "%s You just gambled \x07%d\x01 amount of credits and \x07%s", PREFIX, gB_Number, winner ? "won" : "lost");
	}
}

stock bool IsNumberValid(int number)
{
	if(number < gB_MinimumBet.IntValue)
	{
		return false;
	}
	else if (number > gB_MaximumBet.IntValue)
	{
	   return false;
	}
	else if (number == 0)
	{
	   return false;
	}
	return true;
}

stock bool IsValidClient(int client, bool alive = false, bool bots = false)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)) && (bots == false && !IsFakeClient(client)))
	{
		return true;
	}
	return false;
}

stock bool isNumeric(char[] arg)
{
	int argl = strlen(arg);
	for (int i = 0; i < argl; i++)
	{
		if (!IsCharNumeric(arg[i]))
		{
			return false;
		}
	}
	return true;
}