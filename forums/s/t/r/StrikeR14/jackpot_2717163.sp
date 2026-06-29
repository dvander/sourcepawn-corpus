#include <sourcemod>
#include <store>

#define TAG "\x03[\x01SM\x03]\x01"
#define newdecls required
#define semicolon 1

int Pot=0, GmbCount=0;
int Gambled[MAXPLAYERS + 1], chance[MAXPLAYERS+1], g_iLastGamble[MAXPLAYERS+1]; 
bool wonHisChances[MAXPLAYERS + 1];

ConVar cvar_min, cvar_max;

public Plugin myinfo = 
{
	name = "[TF2/CSGO] JackPot for Zephyrus Store",
	author = "Striker14", 
	description = "Jackpot gambling system for zeph store", 
	version = "1.0", 
	url = ""
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
	if (Gambled[client]) 
		GmbCount--;
	Pot -= Gambled[client];
	Store_SetClientCredits(client, Store_GetClientCredits(client) + Gambled[client]);
	Gambled[client] = 0;
	chance[client] = 0;
	wonHisChances[client] = false;
}

public Action Cmd_Pot(int client, int args)
{
	if(!args)
	{
		if(Pot)
		{
			PrintToChat(client, "%s There are \x03%d\x01 credits in the pot.", TAG, Pot);
			
			if(GmbCount)
			{
				Menu hMenu = CreateMenu(Gamblers);
				hMenu.SetTitle("[SM] %d credits in the pot:", Pot);
				
				for(int i = 1; i <= MaxClients; i++)
				{
					if (!IsValidClient(i) || !Gambled[i]) continue;
					char bfr[100];
					int b = RoundToNearest((Gambled[i] * 100.0) / Pot);
					if(i != client)
					{
						Format(bfr, sizeof(bfr), "%N - Gambled on %d credits (%d%% chance)", i, Gambled[i], b);
						hMenu.AddItem("Sup", bfr);
					}
					else
					{
						Format(bfr, sizeof(bfr), "You - Gambled on %d credits (%d%% chance)", Gambled[client], b);
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
			PrintToChat(client, "%s The minimum amount to gamble on is 50 credits.", TAG);
			return Plugin_Handled;
		}
		if (Store_GetClientCredits(client) < credits)
		{
			PrintToChat(client, "%s You don't have %d credits to gamble on.", TAG, credits);
			return Plugin_Handled;
		}
		if(Gambled[client] + credits > cvar_max.IntValue)
		{
			PrintToChat(client, "%s The maximum amount to gamble on is 10000 credits.", TAG);
			return Plugin_Handled;
		}
		
		int time = GetTime();
		if (!(time - g_iLastGamble[client] < 10)) 
		{
			if(!Gambled[client]) GmbCount++;
			Gambled[client] += credits;
			Pot += credits;
			Store_SetClientCredits(client, Store_GetClientCredits(client) - credits);
			PrintToChatAll("%s %N has gambled on %d credits at \x03THE POT\x01, good luck!", TAG, client, credits);
			PrintToChat(client, "%s NOTE: You can gamble again.", TAG);
			g_iLastGamble[client] = GetTime();
		}
		else
		{
			PrintToChat(client, "%s Please wait %d seconds before using this command again.", TAG, 10 - (time - g_iLastGamble[client]));
		}
	}
	
	return Plugin_Handled;
}

public int Gamblers(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_End) 
		delete menu;
}

public Action OnRoundEnd(Handle hEvent, char[] sName, bool bBroadcast)
{
	if(Pot > 0)
	{
		int random;
		bool atLeastOne = false;
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && Gambled[i])
			{
				chance[i] = RoundToNearest((Gambled[i] * 100.0) / Pot);
				wonHisChances[i] = (GetRandomInt(1, 100) <= chance[i]);
				if(wonHisChances[i]) 
					atLeastOne = true;
			}
		}
		
		if(atLeastOne)
		{
			do
				random = GetRandomInt(1, MaxClients);
			while (!IsValidClient(random) || !wonHisChances[random]);
		}
		else
		{
			do
				random = GetRandomInt(1, MaxClients);
			while (!IsValidClient(random) || !Gambled[random]);
		}
		
		PrintCenterTextAll("%N has won the pot! (%d credits in total, %d%% chance)", random, Pot, chance[random]);
		PrintToChatAll("%s \x03%N\x01 has won the pot! (\x03%d\x01 credits, \x03%d%%\x01 chance).", TAG, random, Pot, chance[random]);
		Store_SetClientCredits(random, Store_GetClientCredits(random) + Pot);
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		Gambled[i] = 0;
		chance[i] = 0;
		wonHisChances[i] = false;
	}
	
	Pot = 0;
	GmbCount = 0;
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}