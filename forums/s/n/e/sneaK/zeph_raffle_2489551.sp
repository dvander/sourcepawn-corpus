#pragma semicolon 1

#define PLUGIN_VERSION "Private"

#include <sourcemod>
#include <sdktools>
#include <store>
#include <multicolors>

#define MIN_CREDITS 100
#define MAX_CREDITS 50000

#define CHAT_PREFIX "[Raffle]"

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)

bool g_bUsed[MAXPLAYERS + 1] = {false, ...};
int g_iSpend[MAXPLAYERS + 1] = {0, ...};

int g_iAccountID[MAXPLAYERS + 1] = {-1, ...};

Handle g_hJackpot = null;

ConVar hConVar_JackpotTimer;
Handle hJackpotTimer;

public Plugin myinfo = 
{
	name = "Zephyrus-Store: Raffle",
	author = ".#Zipcore & Simon DREXEVIL",
	description = "Round based raffle system for Zephyrus Store credits",
	version = PLUGIN_VERSION,
	url = "G"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_raffle", Cmd_Raffle);
	
	g_hJackpot = CreateArray(1);
	
	HookEvent("round_end", Event_OnRoundEnd);
	
	hConVar_JackpotTimer = CreateConVar("sm_zeph_raffle_timer", "180.0", "Time in seconds.", FCVAR_NOTIFY, true, 1.0);
	HookConVarChange(hConVar_JackpotTimer, OnTimerChange);
}

public void OnTimerChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(oldValue, newValue))
	{
		return;
	}
	
	delete hJackpotTimer;
	hJackpotTimer = CreateTimer(StringToFloat(newValue), Timer_Jackpot, _, TIMER_REPEAT);
}

public void OnConfigsExecuted()
{
	delete hJackpotTimer;
	hJackpotTimer = CreateTimer(GetConVarFloat(hConVar_JackpotTimer), Timer_Jackpot, _, TIMER_REPEAT);
}

public void OnClientDisconnect(int client)
{
	g_iAccountID[client] = -1;
}

int GetClientOfAccountId(int accountID)
{
	char buffer1[32];
	Format(buffer1, 32, "%d", accountID);
	LoopClients(i)
	{
		char buffer2[32];
		Format(buffer2, 32, "%d", g_iAccountID[i]);
		if(StrEqual(buffer1, buffer2))
		{
			return i;
		}
	}
	
	return -1;
}

public Action Event_OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int jackpot = GetArraySize(g_hJackpot);
	
	if (jackpot <= 0)
		return Plugin_Continue;
		
	int winner_account = GetArrayCell(g_hJackpot, GetRandomInt(0, jackpot-1));
	int winner = GetClientOfAccountId(winner_account);
	
	// Winner is not in game, try to find another winner
	if (winner <= 0 || !IsClientInGame(winner))
	{
		CPrintToChatAll("%s Winner is not in game anymore, trying to find a new winner.", CHAT_PREFIX);
		
		for (int i = 0; i < jackpot - 1; i++)
		{
			winner_account = GetArrayCell(g_hJackpot, GetRandomInt(0, jackpot-1));
			winner = GetClientOfAccountId(winner_account);
			
			if(winner > 0 && IsClientInGame(winner))
				break;
		}
	}
	
	// All players disconnect, nobody get his credits back, lol
	if (winner <= 0 || !IsClientInGame(winner))
	{
		CPrintToChatAll("%s All players disconnect, nobody get his credits back, lol. Jackpot was %d credits!", CHAT_PREFIX, jackpot);
		return Plugin_Continue;
	}
	
	//Store_GiveCredits(winner_account, jackpot, EmptyStoreCreditsCallback, winner_account);
	Store_SetClientCredits(winner_account, Store_GetClientCredits(winner_account) + jackpot);
	
	//if(winner == -1 || !IsClientInGame(winner))
		//CPrintToChatAll("%s Winner has left the game but won %d credits.", CHAT_PREFIX, jackpot);
	//else CPrintToChatAll("%s %N has won %d credits.", CHAT_PREFIX, winner, jackpot);
	
	char sBuffer[512];
	if(winner == -1 || !IsClientInGame(winner))
		FormatEx(sBuffer, sizeof(sBuffer), "Winner has left the game but won %d credits.", jackpot);
	else FormatEx(sBuffer, sizeof(sBuffer), "%N has won %d credits.", winner, jackpot);
	
	Panel panel = new Panel();
	panel.DrawItem(sBuffer);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			panel.Send(i, PanelHandle_Void, 5);
		}
	}
	
	delete panel;
	
	// Reset
	LoopClients(i)
	{
		g_bUsed[i] = false;
		g_iSpend[i] = 0;
	}
		
	ClearArray(g_hJackpot);
	
	return Plugin_Continue;
}

public Action Timer_Jackpot(Handle timer)
{
	int jackpot = GetArraySize(g_hJackpot);
	
	if (jackpot <= 0)
		return Plugin_Continue;
		
	int winner_account = GetArrayCell(g_hJackpot, GetRandomInt(0, jackpot-1));
	int winner = GetClientOfAccountId(winner_account);
	
	// Winner is not in game, try to find another winner
	if (winner <= 0 || !IsClientInGame(winner))
	{
		CPrintToChatAll("%s Winner is not in game anymore, trying to find a new winner.", CHAT_PREFIX);
		
		for (int i = 0; i < jackpot - 1; i++)
		{
			winner_account = GetArrayCell(g_hJackpot, GetRandomInt(0, jackpot-1));
			winner = GetClientOfAccountId(winner_account);
			
			if(winner > 0 && IsClientInGame(winner))
				break;
		}
	}
	
	// All players disconnect, nobody get his credits back, lol
	if (winner <= 0 || !IsClientInGame(winner))
	{
		CPrintToChatAll("%s All players disconnect, nobody get his credits back, lol. Jackpot was %d credits!", CHAT_PREFIX, jackpot);
		return Plugin_Continue;
	}
	
	//Store_GiveCredits(winner_account, jackpot, EmptyStoreCreditsCallback, winner_account);
	Store_SetClientCredits(winner_account, Store_GetClientCredits(winner_account) + jackpot);
	
	//if(winner == -1 || !IsClientInGame(winner))
		//CPrintToChatAll("%s Winner has left the game but won %d credits.", CHAT_PREFIX, jackpot);
	//else CPrintToChatAll("%s %N has won %d credits.", CHAT_PREFIX, winner, jackpot);
	
	char sBuffer[512];
	if(winner == -1 || !IsClientInGame(winner))
		FormatEx(sBuffer, sizeof(sBuffer), "Winner has left the game but won %d credits.", jackpot);
	else FormatEx(sBuffer, sizeof(sBuffer), "%N has won %d credits.", winner, jackpot);
	
	Panel panel = new Panel();
	panel.DrawItem(sBuffer);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			panel.Send(i, PanelHandle_Void, 5);
		}
	}
	
	delete panel;
	
	// Reset
	LoopClients(i)
	{
		g_bUsed[i] = false;
		g_iSpend[i] = 0;
	}
		
	ClearArray(g_hJackpot);
	return Plugin_Continue;
}

public Action Cmd_Raffle(int client, int args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "%s This command is only for players", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	if(g_bUsed[client])
	{
		CPrintToChat(client, "%s You already spend %d credits this game. Current win chance: %.2f% Jackpot: %d credits", CHAT_PREFIX, g_iSpend[client], float(g_iSpend[client])/float(GetArraySize(g_hJackpot))*100.0, GetArraySize(g_hJackpot));
		return Plugin_Handled;
	}
	
	if(args == 0)
	{
		CPrintToChat(client, "%s Jackpot: %d credits", CHAT_PREFIX, GetArraySize(g_hJackpot));
		return Plugin_Handled;
	}
	
	if(args != 1)
	{
		CPrintToChat(client, "%s Usage: sm_raffle <credits>", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	char buffer[32];
	GetCmdArg(1, buffer, 32);
	
	int credits = StringToInt(buffer);
	
	if(credits < MIN_CREDITS)
	{
		CPrintToChat(client, "%s You have to spend at least %d credits.", CHAT_PREFIX, MIN_CREDITS);
		return Plugin_Handled;
	}
	else if(credits > MAX_CREDITS)
	{
		CPrintToChat(client, "%s You can't spend that much credits (Max: %d).", CHAT_PREFIX, MAX_CREDITS);
		return Plugin_Handled;
	}
	
	//int storeAccountID = Store_GetClientTarget(client);
	g_iAccountID[client] = client;
	
	//Store_GetCredits(storeAccountID, GetCreditsCallback, pack);
	int test = Store_GetClientCredits(client);
	if(credits > test)
	{
		CPrintToChat(client, "%s You don't have enough credits. (Spend: %d Current: %d)", CHAT_PREFIX, credits, test);
		return Plugin_Handled;
	}
	
	g_bUsed[client] = true;
	g_iSpend[client] = credits;
	
	// Remove credits
	//Store_GiveCredits(storeAccountID, -credits_spend, EmptyStoreCreditsCallback, client);
	Store_SetClientCredits(client, test - credits);
	
	// Add his credits too the jackpot "pool"
	for (int i = 0; i < credits; i++)
		PushArrayCell(g_hJackpot, client); //Use store account id in case player left game or rejoined
	
	//CPrintToChatAll("%s %N has spend %d credits, his current winning chance is: %.2f% (Jackpot: %d credits)", CHAT_PREFIX, client, credits, float(credits)/float(GetArraySize(g_hJackpot))*100.0, GetArraySize(g_hJackpot));
	
	char sBuffer[512];
	FormatEx(sBuffer, sizeof(sBuffer), "%N\nhas spent %i credits\nhis current winning chance is: %.2f%\nJackpot: %i credits\nType !raffle to get your chance to win", client, credits, float(credits)/float(GetArraySize(g_hJackpot))*100.0, GetArraySize(g_hJackpot));
	
	Panel panel = new Panel();
	panel.DrawItem(sBuffer);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			panel.Send(i, PanelHandle_Void, 5);
		}
	}
	
	delete panel;
	
	return Plugin_Handled;
}

public int PanelHandle_Void(Menu menu, MenuAction action, int param1, int param2)
{

}

//Empty callback
//public int EmptyStoreCreditsCallback(int accountId, any pack){}