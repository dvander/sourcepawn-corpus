#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION  "1.5.1"


float g_flHelpTimer[MAXPLAYERS + 1];
float g_flGoodJobTimer[MAXPLAYERS + 1];
float g_flCheersJeersTimer[MAXPLAYERS + 1];
float g_flPositiveNegativeTimer[MAXPLAYERS + 1];
float g_flBattleCryTimer[MAXPLAYERS + 1];

ConVar g_cvBVCEnable;

public Plugin myinfo = 
{
	name = "[TF2] Bot Voice Commands 2",
	author = "Marqueritte",
	description = "Bots use the cheers and jeers voice commands as well as others.",
	version = PLUGIN_VERSION,
};

public void OnPluginStart()
{
 	g_cvBVCEnable = CreateConVar("tf_bot_voice_commands", "1", "1 = Enable Voice Commands, 0 = Disable Voice Commands", _, true, 0.0, true, 1.0);
}

public Action OnPlayerRunCmd(int client)
{
	if(IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client))
	{	
		
		if (g_cvBVCEnable.IntValue > 0)
		{
			if(g_flHelpTimer[client] < GetGameTime()) // Bot use the "Help!" voice command
			{
			 	FakeClientCommandThrottled(client, "voicemenu 2 0");
				g_flHelpTimer[client] = GetGameTime() + GetRandomFloat(20.0, 40.0);
		 	}
		
			if(g_flGoodJobTimer[client] < GetGameTime()) // Bots use the "Good Job" voice command
			{
				FakeClientCommandThrottled(client, "voicemenu 2 7");
				g_flGoodJobTimer[client] = GetGameTime() + GetRandomFloat(15.0, 30.0);
			}
		
			if(g_flCheersJeersTimer[client] < GetGameTime()) // Bots use the "Cheers" & "Jeers" voice command
			{
				int randomvoice = GetRandomInt(1,100);
				if(randomvoice <= 50)
				{
					FakeClientCommandThrottled(client, "voicemenu 2 2");
				}
				else
				{
					FakeClientCommandThrottled(client, "voicemenu 2 3");
				}
				g_flCheersJeersTimer[client] = GetGameTime() + GetRandomFloat(20.0, 60.0);
			}
		
			if(g_flPositiveNegativeTimer[client] < GetGameTime()) // Bot use the "Positive" voice command
			{
				int randomvoice = GetRandomInt(1,100);
				if(randomvoice <= 50)
				{
					FakeClientCommandThrottled(client, "voicemenu 2 4");
				}
				else
				{
					FakeClientCommandThrottled(client, "voicemenu 2 5");
				}
				g_flPositiveNegativeTimer[client] = GetGameTime() + GetRandomFloat(40.0, 80.0);
			}
		
			if(g_flBattleCryTimer[client] < GetGameTime()) // Bot use the "Battle Cry" voice command 
			{
				FakeClientCommandThrottled(client, "voicemenu 2 1");
				g_flBattleCryTimer[client] = GetGameTime() + GetRandomFloat(22.0, 44.0);
			}
			
		}
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client) 
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

float g_flNextCommand[MAXPLAYERS + 1];
stock bool FakeClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	
	g_flNextCommand[client] = GetGameTime() + 0.4;
	
	return true;
}