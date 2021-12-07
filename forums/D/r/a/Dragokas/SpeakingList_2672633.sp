#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

forward void OnClientSpeaking(int client);

public Extension __ext_voice = 
{
	name = "VoiceHook",
	file = "VoiceHook.ext",
	autoload = 1,
	required = 1,
}

bool ClientSpeaking[MAXPLAYERS+1];
int iCount;
char SpeakingPlayers[128];

public void OnPluginStart()
{
	CreateTimer(0.7, UpdateSpeaking, _, TIMER_REPEAT);
}

public void OnClientSpeaking(int client)
{
	ClientSpeaking[client] = true;
}

public Action UpdateSpeaking(Handle timer)
{
	iCount = 0;
	SpeakingPlayers[0] = '\0';
	for (int i = 1; i <= MaxClients; i++)
	{
		if (ClientSpeaking[i])
		{
			if (!IsClientInGame(i)) continue;
			
			Format(SpeakingPlayers, sizeof(SpeakingPlayers), "%s\n%N", SpeakingPlayers, i);
			iCount++;
		}
		ClientSpeaking[i] = false;
	}
	if (iCount > 0)
	{
		PrintCenterTextAll(SpeakingPlayers);
	}
}

/*
public void OnClientSpeakingEnd(int client)
{
	if (IsClientInGame(client))
	{
		PrintToChatAll("OnClientSpeakingEnd - %N", client);
	}
}

public void OnClientSpeakingStart(int client)
{
	if (IsClientInGame(client))
	{
		PrintToChatAll("OnClientSpeakingStart - %N", client);
	}
}
*/