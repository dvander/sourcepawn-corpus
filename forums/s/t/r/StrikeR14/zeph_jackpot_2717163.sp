#include <sourcemod>
#include <store>

#define TAG "\x03[\x01SM\x03]\x01"
#define newdecls required
#define semicolon 1

int Pot=0, gamblersCount=0;
int gambleAmount[MAXPLAYERS + 1];
int Min[MAXPLAYERS+1], Max[MAXPLAYERS+1];
int maxTicket;

ConVar cvar_min, cvar_max;

public Plugin myinfo = 
{
	name = "[TF2/CSGO] JackPot for Zephyrus Store",
	author = "Striker14", 
	description = "Jackpot gambling system for zeph store", 
	version = "1.1", 
	url = "https://steamcommunity.com/profiles/76561198164353433"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_pot", Cmd_Pot);
	
	EngineVersion game = GetEngineVersion();
	
	if(game == Engine_CSGO)
	{
		HookEvent("round_end", OnRoundEnd, EventHookMode_Post);
	}
	else if(game == Engine_TF2)
	{
		HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);
		HookEvent("teamplay_round_stalemate", OnRoundEnd, EventHookMode_Post);
	}
	else
	{
		SetFailState("This plugin is made for TF2/CSGO Only.");
	}
	
	cvar_min = CreateConVar("sm_zephgamble_min", "50", "The minimum amount of credits to gamble on.", _, true);
	cvar_max = CreateConVar("sm_zephgamble_max", "10000", "The maxmium amount of credits to gamble on.", _, true, 1.0);
}

public void OnClientDisconnect(int client)
{
	if (gambleAmount[client]) 
		gamblersCount--;
	
	Pot -= gambleAmount[client];
	gambleAmount[client] = 0;
	Min[client] = 0;
	Max[client] = 0;

	int temp = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && gambleAmount[i] > 0)
		{
			Min[i] = temp;
			Max[i] = Min[i] + gambleAmount[i] - 1;
			temp = Max[i] + 1;
		}
	}

	maxTicket = temp;
}

public Action Cmd_Pot(int client, int args)
{
	if(!args)
	{
		if(Pot)
		{
			PrintToChat(client, "%s There are \x03%d\x01 credits in the pot.", TAG, Pot);
			
			if(gamblersCount)
			{
				Menu hMenu = CreateMenu(Gamblers);
				hMenu.SetTitle("[SM] %d credits in the pot:", Pot);
				
				for(int i = 1; i <= MaxClients; i++)
				{
					if (!IsValidClient(i) || !gambleAmount[i]) continue;
					char bfr[100];
					float b = gambleAmount[i] * 100.0 / Pot;
					if(i != client)
					{
						Format(bfr, sizeof(bfr), "%N - Gambled on %d credits (%.2f%% chance)", i, gambleAmount[i], b);
						hMenu.AddItem("Sup", bfr);
					}
					else
					{
						Format(bfr, sizeof(bfr), "You - Gambled on %d credits (%.2f%% chance)", gambleAmount[client], b);
						hMenu.AddItem("Sup", bfr, ITEMDRAW_DISABLED);
					}
				}
				
				hMenu.ExitBackButton = true;
				hMenu.Display(client, 30);
			}
		}
		else
		{
			PrintToChat(client, "%s There are no points in the pot.", TAG);
		}
	}
	else
	{
		char arg[8];
		GetCmdArg(1, arg, 8);
		int credits;
		if(!strcmp(arg, "all", false))
			credits = Store_GetClientCredits(client);
		else if(!strcmp(arg, "half", false))
			credits = Store_GetClientCredits(client) / 2;
		else 
			credits = StringToInt(arg);
			
		if (credits < cvar_min.IntValue)
		{
			PrintToChat(client, "%s The minimum amount to gamble on is %i credits.", TAG, cvar_min.IntValue);
			return Plugin_Handled;
		}
		if (Store_GetClientCredits(client) < credits)
		{
			PrintToChat(client, "%s You don't have %d credits to gamble on.", TAG, credits);
			return Plugin_Handled;
		}
		if(gambleAmount[client] + credits > cvar_max.IntValue)
		{
			PrintToChat(client, "%s The maximum amount to gamble on is %i credits.", TAG, cvar_max.IntValue);
			return Plugin_Handled;
		}

		if(gambleAmount[client])
		{
			PrintToChat(client, "%s You have already gambled on %i credits.", TAG, gambleAmount[client]);
			return Plugin_Handled;
		}
		
		Min[client] = maxTicket;
		Max[client] = Min[client] + credits - 1;
		maxTicket = Max[client] + 1;
			
		gambleAmount[client] = credits;
		Pot += credits;
		Store_SetClientCredits(client, Store_GetClientCredits(client) - credits);

		PrintToChatAll("%s %N has gambled on %d credits at \x03THE POT\x01, good luck!", TAG, client, credits);
	}
	
	return Plugin_Handled;
}

public int Gamblers(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_End) 
		delete menu;
	
	return 0;
}

public Action OnRoundEnd(Handle hEvent, char[] sName, bool bBroadcast)
{
	if(Pot > 0)
	{
		int random = GetRandomInt(0, 1073741824) % maxTicket;
		int winner = -1;
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && gambleAmount[i] && Min[i] <= random <= Max[i])
			{
				winner = i;
				break;
			}
		}
		
		PrintCenterTextAll("%N has won the pot! (%d credits in total, %.2f%% chance)", winner, Pot, gambleAmount[winner] * 100.0 / Pot);
		PrintToChatAll("%s \x03%N\x01 has won the pot! (\x03%d\x01 credits, \x03%d%%\x01 chance).", TAG, winner, Pot, gambleAmount[winner] * 100.0 / Pot);
		Store_SetClientCredits(winner, Store_GetClientCredits(winner) + Pot);
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		gambleAmount[i] = 0;
		Min[i] = 0;
		Max[i] = 0;
	}
	
	Pot = 0;
	gamblersCount = 0;
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}