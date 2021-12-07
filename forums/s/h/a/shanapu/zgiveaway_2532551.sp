#include <sourcemod>
#include <colorvariables>
#include <sdktools>
#include <store>

#pragma newdecls required

ConVar gc_iCredits;
ConVar gc_iMinPlayer;

ConVar gc_sTag;
char g_sTag[32];

public Plugin myinfo = {
	name = "zGiveaway",
	author = "Black Flash, fix by shanapu",
	description = "Giveaway plugin compatible with zephyrus store.",
	version = "2.1",
	url = "www.terra2.forumeiros.com"
}

public void OnPluginStart()
{
	gc_iCredits = CreateConVar("sm_giveaway_credits", "5000", "Number of credits given.");
	gc_iMinPlayer = CreateConVar("sm_giveaway_minplayers", "5", "Minimum players required in the server for the giveaway.");

	RegConsoleCmd("sm_giveaway", CommandGiveaway, "Start giveaway");

	AutoExecConfig(true, "plugin.zGiveaway");

	LoadTranslations("zgiveaway.phrases");
}

public void OnConfigsExecuted()
{
	gc_sTag = FindConVar("sm_store_chat_tag");
	gc_sTag.GetString(g_sTag, sizeof(g_sTag));
}

public Action CommandGiveaway(int client, int args)
{
	if (!CheckCommandAccess(client, "sm_giveaway_flag_overwrite", ADMFLAG_ROOT))
		return Plugin_Handled;

	if(GetClientCount() > gc_iMinPlayer.IntValue)
	{
		int random = GetRandomPlayer();
		if (IsClientInGame(random))
		{
			Store_SetClientCredits(random, Store_GetClientCredits(random) + gc_iCredits.IntValue);

			CPrintToChatAll("%t","GiveAway Result", g_sTag, random, gc_iCredits.IntValue);
			CPrintToChat(random, "%t","Client GiveAway Result", g_sTag, gc_iCredits.IntValue);

			LogToFile("addons/sourcemod/logs/zgiveaway/zgiveawayfile.log", "The admin %L did a giveaway and %L won", client, random);
		}
		return Plugin_Handled;
	}
	else
	{
		CPrintToChat(client, "%t", "Minimum Players", g_sTag, gc_iMinPlayer.IntValue);
	}
	return Plugin_Handled;
}

stock int GetRandomPlayer()
{
	int[] clients = new int[MaxClients];
	int clientCount;

	for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
	{
		if (IsPlayerAlive(i))
		{
			clients[clientCount++] = i;
		}
	}

	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}