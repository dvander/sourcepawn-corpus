#include <sourcemod>
#include <sdktools>

#pragma tabsize 0
#define PREFIX "\x01[\x04Gamble\x01]\x04"

ConVar cvShowGamble, cvMinBet, cvMaxBet, cvWiningPrecent;
native Store_SetClientCredits(client, credits);
native Store_GetClientCredits(client);

public Plugin myinfo =
{
    name = "[Store] Gamble",
    author = "BaroNN",
    description = "CSGO Store Module of Gambling Credits",
    version = "1.0",
    url = "http://steamcommunity.com/id/BaRoNN-Main"
}
 
public void OnPluginStart()
{
    RegConsoleCmd("sm_gamble", Command_Gamble);
    
    cvShowGamble = CreateConVar("sm_gamble_showgamble", "0", "Show Gamble Message to All?");
    cvMinBet = CreateConVar("sm_gamble_minbet", "25", "Minimum BetAmount");
    cvMaxBet = CreateConVar("sm_gamble_maxbet", "7000", "Maximum BetAmount");
    cvWiningPrecent = CreateConVar("sm_gamble_winingchance", "40", "Sets the Wining precent?");
    AutoExecConfig(true, "store_gamble");
}
 
public Action Command_Gamble(int client, int args)
{
    char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	int BetAmount = StringToInt(arg);
	int RandomNum = GetRandomInt(1,100);
	
    if(args < 0 || !BetAmount || IsValidClient(client)) 
    {
        PrintToChat(client, "%s Usage: /gamble <credits>", PREFIX);
        return Plugin_Handled;
    }
    if(BetAmount >= Store_GetClientCredits(client) || BetAmount <= 0)
    {
       PrintToChat(client, "%s \x02You dont have enough credits.", PREFIX);
       return Plugin_Handled;
    }
    if(BetAmount < cvMinBet.IntValue)
	{
		PrintToChat(client, "%s \x02You have to spend at least \x10(Min Credits: \x02%d\x04)", PREFIX, cvMinBet.IntValue);
		return Plugin_Handled;
	}
	else if(BetAmount > cvMaxBet.IntValue)
	{
		PrintToChat(client, "%s \x02You can't spend that much credits \x10(Max Credits: \x02%d\x04).", PREFIX, cvMaxBet.IntValue);
		return Plugin_Handled;
	}       
	
    if(RandomNum <= cvWiningPrecent.IntValue)
    {
    	if(cvShowGamble.BoolValue)PrintToChatAll("%s \x0E%N \x01Just \x3Gambled \x01%d \x10and he \x04WON!", PREFIX, client, BetAmount);
    	else PrintToChat(client, "%s You Just \x3Gambled \x01%d \x10and you \x04WON!", PREFIX, BetAmount);
    	Store_SetClientCredits(client, Store_GetClientCredits(client) + BetAmount);
    } 
    else 
    {
    	if(cvShowGamble.BoolValue)PrintToChatAll("%s \x0E%N \x01Just \x3Gambled \x01%d \x10and he \x02LOST!", PREFIX, client, BetAmount);
    	else PrintToChat(client, "%s You Just \x3Gambled \x01%d \x10and you \x02LOST!", PREFIX, BetAmount);
    	Store_SetClientCredits(client, Store_GetClientCredits(client) - BetAmount);
    }
    return Plugin_Handled;
}

stock bool IsValidClient(client)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsFakeClient(client) && IsClientSourceTV(client))return true;
	return false;
}