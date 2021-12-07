#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

#define PLUGIN_VERSION			"1.0"

public Plugin:myinfo =
{
	name = "[TF2] Rename bots",
	author = "Pelipoika",
	description = "Rename bots based by class",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	HookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, true);
}

public OnPlayerSpawn(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (IsClientInGame(iClient) && IsFakeClient(iClient))
	{
		new TFClassType:class = TF2_GetPlayerClass(iClient);
		switch(class)
		{
			case TFClass_Scout:		SetClientInfo(iClient, "name", "Scout");
			case TFClass_Soldier:	SetClientInfo(iClient, "name", "Soldier");
			case TFClass_DemoMan:	SetClientInfo(iClient, "name", "DemoMan");
			case TFClass_Medic:		SetClientInfo(iClient, "name", "Medic");
			case TFClass_Pyro:		SetClientInfo(iClient, "name", "Pyro");
			case TFClass_Spy:		SetClientInfo(iClient, "name", "Spy");
			case TFClass_Engineer:	SetClientInfo(iClient, "name", "Engineer");
			case TFClass_Sniper:	SetClientInfo(iClient, "name", "Sniper");
			case TFClass_Heavy:		SetClientInfo(iClient, "name", "HeavyWeapons");
		}
	}
}

public Action:UserMessage_SayText2(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:message[256];

	BfReadShort(bf);
	BfReadString(bf, message, sizeof(message));
	if (StrContains(message, "Name_Change") != -1)
	{
		BfReadString(bf, message, sizeof(message));

		new maxplayers, client = -1;
		maxplayers = GetMaxClients();
		for (new i = 1; i <= maxplayers; i++)
		{
			if (!IsClientConnected(i) || !IsFakeClient(i))
			{
				continue;
			}

			decl String:testname[MAX_NAME_LENGTH];
			GetClientName(i, testname, sizeof(testname));
			if (StrEqual(message, testname))
			{
				client = i;
			}
		}

		if (client == -1)
			return Plugin_Continue;

		return Plugin_Handled;
	}

	return Plugin_Continue;
}