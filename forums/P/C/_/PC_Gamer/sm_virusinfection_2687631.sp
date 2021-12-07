/*  SM Virus Infection
 *
 *  Copyright (C) 2020 Francisco 'Franc1sco' García and Totenfluch
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */
 
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <autoexecconfig>
#include <colorlib>
#include <rtd2> //For TF2 players check for 'Roll The Dice Revamped' plugin by Phil25
#undef REQUIRE_PLUGIN
#include <devzones>

#pragma semicolon 1
#pragma newdecls required

#define DATA "1.31"


#define ENGLISH // multi language pending to do


public Plugin myinfo = 
{
	name = "SM Virus Infection",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

enum struct Virus{
	Handle tStartVirus;
	Handle tShareVirus;
	Handle tProgressVirus;
	Handle tQuarantine;
	Handle tBlind;
	bool bSafeZone;
	bool bVirus;
	bool bNoticed;
}

Virus virus[MAXPLAYERS + 1];
UserMsg g_FadeUserMsgId;

ConVar cv_TIME_START, cv_TIME_EFFECTS, cv_TIME_SHARE, cv_TIME_BLIND, cv_SHARE_CHANCE, cv_SHARE_CHANCE_COUGH, cv_VIRUS_DAMAGE, cv_VIRUS_DISTANCE, cv_TIME_QUARANTINE;

public void OnPluginStart()
{
	CreateConVar("sm_virus_version", DATA, "virus plugin version.");
	
	AutoExecConfig_SetFile("sm_virus");
	cv_TIME_START = AutoExecConfig_CreateConVar("sm_virus_time_start", "60.0", "Seconds for start to know that you have virus.");
	cv_TIME_EFFECTS = AutoExecConfig_CreateConVar("sm_virus_time_effects", "30.0", "Each X seconds for have the virus effects.");
	cv_TIME_SHARE = AutoExecConfig_CreateConVar("sm_virus_time_share", "5.0", "Each X seconds for share the virus.");
	cv_TIME_BLIND = AutoExecConfig_CreateConVar("sm_virus_time_blind", "5.0", "Seconds for have the blind effect.");
	cv_SHARE_CHANCE = AutoExecConfig_CreateConVar("sm_virus_share_chance", "10", "Chance of share virus.");
	cv_SHARE_CHANCE_COUGH = AutoExecConfig_CreateConVar("sm_virus_share_chancecough", "60", "Chance of share virus when you cough.");
	cv_VIRUS_DAMAGE = AutoExecConfig_CreateConVar("sm_virus_virus_damage", "5", "Damage that produce virus when you have the effects.");
	cv_VIRUS_DISTANCE = AutoExecConfig_CreateConVar("sm_virus_virus_distance", "100.0", "Distance min for share virus to someone.");
	cv_TIME_QUARANTINE = AutoExecConfig_CreateConVar("sm_virus_quarantine_time", "60.0", "Seconds that you need to stay in a quarantine zone for be healed.");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	RegAdminCmd("sm_givevirus", Command_GiveVirus, ADMFLAG_BAN);
	RegAdminCmd("sm_removevirus", Command_RemoveVirus, ADMFLAG_BAN);
	
	HookEventEx("player_spawn", Event_Restart);
	HookEventEx("player_death", Event_Restart);
	
	g_FadeUserMsgId = GetUserMessageId("Fade");
	
	
	//If we load after the map has started, the OnEntityCreated check wont be called
	int iSpawn = -1;
	while ((iSpawn = FindEntityByClassname(iSpawn, "func_respawnroom")) != -1)
	{
		// If plugin is loaded early, these won't be called because the func_respawnroom wont exist yet
		SDKHook(iSpawn, SDKHook_StartTouch, SpawnStartTouch);
		SDKHook(iSpawn, SDKHook_EndTouch, SpawnEndTouch);
	}
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/sm_virus/cough1.mp3");
	PrecacheSound("sm_virus/cough1.mp3");
}

public Action Command_GiveVirus(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Use: sm_givevirus <name>");
		return Plugin_Handled;
	}
	char strTarget[32]; 
	GetCmdArg(1, strTarget, sizeof(strTarget)); 

	// Progress the targets 
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS];
	int TargetCount; 
	bool TargetTranslate; 

	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
					strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{ 
		ReplyToCommand(client, "client not found");
		return Plugin_Handled; 
	} 

	// Apply to all targets 
	int count;
	for (int i = 0; i < TargetCount; i++) 
	{ 
		int iClient = TargetList[i]; 
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient)) 
		{
			count++;
			Infection(iClient);
			#if defined ENGLISH
			CReplyToCommand(client, "{green}[SM-Virus]{lightgreen} Player %N has been infected with virus", iClient);
			#else
			CReplyToCommand(client, "{green}[SM-Virus]{lightgreen} Jugador %N ha sido infectado con el virus", iClient);
			#endif
		} 
	}

	if(count == 0)
		ReplyToCommand(client, "No valid clients");
	
	return Plugin_Handled;
}

public Action Command_RemoveVirus(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Use: sm_removevirus <name>");
		return Plugin_Handled;
	}
	char strTarget[32]; 
	GetCmdArg(1, strTarget, sizeof(strTarget)); 

	// Progress the targets 
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS];
	int TargetCount; 
	bool TargetTranslate; 

	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
					strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{ 
		ReplyToCommand(client, "client not found");
		return Plugin_Handled; 
	} 

	// Apply to all targets 
	int count;
	for (int i = 0; i < TargetCount; i++) 
	{ 
		int iClient = TargetList[i]; 
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient) && virus[iClient].bVirus) 
		{
			count++;
			resetClient(iClient);
			#if defined ENGLISH
			CReplyToCommand(client, "{green}[SM-Virus]{lightgreen} Player %N has been cured of virus", iClient);
			#else
			CReplyToCommand(client, "{green}[SM-Virus]{lightgreen} Jugador %N ha sido curado del virus", iClient);
			#endif
		} 
	}

	if(count == 0)
		ReplyToCommand(client, "No valid clients");
	
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	resetClient(client);
}

public Action Event_Restart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	resetClient(client);
}

void Infection(int client)
{
	resetClient(client);
	
	virus[client].bVirus = true;
	
	virus[client].tStartVirus = CreateTimer(cv_TIME_START.FloatValue, Timer_StartVirus, client);
	
	
	virus[client].tShareVirus = CreateTimer(cv_TIME_SHARE.FloatValue, Timer_ShareVirus, client);
}

public Action Timer_StartVirus(Handle timer, int client)
{
	virus[client].tStartVirus = null;
	
	if (!IsClientInGame(client) || !virus[client].bVirus)return;
	
	// todo do firsts effects with chat notification, damage, etc
	//PrintToConsoleAll("%N Virus effects starting..", client); // debug
	
	#if defined ENGLISH
	CPrintToChat(client, "{green}[SM-Virus]{lightgreen} Something start to be wrong...");
	#else
	CPrintToChat(client, "{green}[SM-Virus]{lightgreen} Algo empieza a ir mal...");
	#endif
	
	virus[client].bNoticed = true;

	int health = GetClientHealth(client) - cv_VIRUS_DAMAGE.IntValue;
	if(health <= 0)
	{
		ForcePlayerSuicide(client);
		return;
	}
		
	SetEntityHealth(client, health);
	
	float cal = (GetClientHealth(client) * 1.0) / (GetEntProp(client, Prop_Data, "m_iMaxHealth") * 1.0);
	cal = cal * 255.0;
	cal = cal - 255.0;
	if(cal != 0.0)
		cal *= -1.0;
	
	if(cal > 255.0)
		cal = 255.0;
	else if(cal < 0.0)
		cal = 0.0;
	
	PerformBlind(client, RoundToNearest(cal), cv_TIME_BLIND.FloatValue);
	
	virus[client].tProgressVirus = CreateTimer(cv_TIME_EFFECTS.FloatValue, Timer_ProgressVirus, client);
}

public Action Timer_ProgressVirus(Handle timer, int client)
{
	virus[client].tProgressVirus = null;
	
	if (!IsClientInGame(client) || !virus[client].bVirus)resetClient(client);
	
	// todo do progress effects, do damage and view effects
	//PrintToConsoleAll("%N Virus effects progress..", client); // debug
	
	#if defined ENGLISH
	CPrintToChat(client, "{green}[SM-Virus]{lightgreen} dry cough");
	#else
	CPrintToChat(client, "{green}[SM-Virus]{lightgreen} Tos seca");
	#endif
	
	EmitSoundToAll("sm_virus/cough1.mp3", client);

	//If TF2 Roll The Dice Revamped is running, do this:
	int rnd = GetRandomInt(1,13);

	switch (rnd)
	{
	case 1:
		{
			RTD2_Force(client, "sickness", 10); 
		}
	case 2:
		{
			RTD2_Force(client, "sickness", 10);
		}
	case 3:
		{
			RTD2_Force(client, "sickness", 10);
		}
	case 4:
		{
			RTD2_Force(client, "snail", 10);
		}
	case 5:
		{
			RTD2_Force(client, "drugged", 10);
		}
	case 6:
		{
			RTD2_Force(client, "blind", 10);
		}
	case 7:
		{
			RTD2_Force(client, "monochromia", 10);
		}
	case 8:
		{
			RTD2_Force(client, "badsauce", 10);
		}
	case 9:
		{
			RTD2_Force(client, "suffocation", 10);
		}
	case 10:
		{
			RTD2_Force(client, "drunkwalk", 10);
		}
	case 11, 12, 13:
		{
			//This space intentionally left blank
		}
	}
	// End of TF2 Roll The Dice specific part
	
	int health = GetClientHealth(client) - cv_VIRUS_DAMAGE.IntValue;
	if(health <= 0)
	{
		ForcePlayerSuicide(client);
		return;
	}
		
	SetEntityHealth(client, health);
	
	float cal = (GetClientHealth(client) * 1.0) / (GetEntProp(client, Prop_Data, "m_iMaxHealth") * 1.0);
	cal = cal * 255.0;
	cal = cal - 255.0;
	if(cal != 0.0)
		cal *= -1.0;
	
	if(cal > 255.0)
		cal = 255.0;
	else if(cal < 0.0)
		cal = 0.0;
	
	PerformBlind(client, RoundToNearest(cal), cv_TIME_BLIND.FloatValue);
	
	ShareVirus(client, true);
	
	virus[client].tProgressVirus = CreateTimer(cv_TIME_EFFECTS.FloatValue, Timer_ProgressVirus, client);
}

public Action Timer_ShareVirus(Handle timer, int client)
{
	virus[client].tShareVirus = null;
	
	if (!IsClientInGame(client) || !virus[client].bVirus)resetClient(client);
	
	// todo do share virus, with nearby people
	//PrintToConsoleAll("%N Virus effects share..", client); // debug
	
	ShareVirus(client, false);
	
	virus[client].tShareVirus = CreateTimer(cv_TIME_SHARE.FloatValue, Timer_ShareVirus, client);
}

void ShareVirus(int client, bool cough)
{
	if (virus[client].bSafeZone)return;
	
	float Origin[3], TargetOrigin[3], Distance;
	
	GetClientEyePosition(client, Origin);
	
	for (int X = 1; X <= MaxClients; X++)
	{
		if(IsClientInGame(X) && IsPlayerAlive(X) && !virus[X].bVirus && !virus[X].bSafeZone) 
		{
			GetClientEyePosition(X, TargetOrigin);
			Distance = GetVectorDistance(TargetOrigin,Origin);
			if(Distance <= cv_VIRUS_DISTANCE.FloatValue)
			{ 
				if(!cough)
				{
					if(GetRandomInt(1, 100) <= cv_SHARE_CHANCE.FloatValue)
						Infection(X);
				}
				else
				{
					if(GetRandomInt(1, 100) <= cv_SHARE_CHANCE_COUGH.FloatValue)
						Infection(X);
				}
			}
		}
	}
}

void resetClient(int client)
{
	if(virus[client].tBlind != null)
		PerformBlind(client, 0, 0.0);
		
	delete virus[client].tStartVirus;
	delete virus[client].tShareVirus;
	delete virus[client].tProgressVirus;
	delete virus[client].tBlind;
	delete virus[client].tQuarantine;
	virus[client].bVirus = false;
	virus[client].bNoticed = false;
	virus[client].bSafeZone = false;
}

void PerformBlind(int target, int amount, float time)
{
	int targets[2];
	targets[0] = target;
	
	int duration = 1536;
	int holdtime = 1536;
	int flags;
	if (amount == 0)
	{
		flags = (0x0001 | 0x0010);
	}
	else
	{
		flags = (0x0002 | 0x0008);
	}
	
	int color[4] = { 0, 0, 0, 0 };
	color[3] = amount;
	
	Handle message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWrite bf = UserMessageToBfWrite(message);
		bf.WriteShort(duration);
		bf.WriteShort(holdtime);
		bf.WriteShort(flags);		
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);
	}
	
	EndMessage();
	
	if(time > 0.0)
	{
		delete virus[target].tBlind;
		virus[target].tBlind = CreateTimer(time, Timer_NoBlind, target);
	}
}

public Action Timer_NoBlind(Handle timer, int client)
{
	virus[client].tBlind = null;
	
	PerformBlind(client, 0, 0.0);
}

public void Zone_OnClientEntry(int client, const char[] zone)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client) ||!IsPlayerAlive(client)) 
		return;
		
	if(StrContains(zone, "safezone", false) != 0) return;
	
	joinSafeZone(client);
}

void joinSafeZone(int client)
{
	virus[client].bSafeZone = true;
	#if defined ENGLISH
	CPrintToChat(client, "{green}[SM-Virus]{lightgreen} You joined a quarantine zone. Stay here during %i seconds if you think that you have virus.", RoundToNearest(cv_TIME_QUARANTINE.FloatValue));
	#else
	CPrintToChat(client, "{green}[SM-Virus]{lightgreen} Has entrado a una zona de cuarentena. Permanece aquí %i segundos si crees que tienes el virus.", RoundToNearest(cv_TIME_QUARANTINE.FloatValue));
	#endif
	
	
	if (!virus[client].bVirus)return;
	
	delete virus[client].tQuarantine;
	virus[client].tQuarantine = CreateTimer(cv_TIME_QUARANTINE.FloatValue, Timer_Quarantine, client);
}

void leaveSafeZone(int client)
{
	virus[client].bSafeZone = false;
	#if defined ENGLISH
	CPrintToChat(client, "{green}[SM-Virus]{lightgreen} You left a quarantine zone.");
	#else
	CPrintToChat(client, "{green}[SM-Virus]{lightgreen} Has salido de una zona de cuarentena.");
	#endif
	
	if (!virus[client].bVirus)return;
	
	delete virus[client].tQuarantine;
}

public void Zone_OnClientLeave(int client, const char[] zone)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) 
		return;
		
	if(StrContains(zone, "safezone", false) != 0) return;
	
	leaveSafeZone(client);

}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "func_respawnroom", false))	// This is the earliest we can catch this
	{
		SDKHook(entity, SDKHook_StartTouch, SpawnStartTouch);
		SDKHook(entity, SDKHook_EndTouch, SpawnEndTouch);
	}
}

public void SpawnStartTouch(int spawn, int client)
{
	// Make sure it is a client and not something random
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) 
		return;

	joinSafeZone(client);
}

public void SpawnEndTouch(int spawn, int client)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) 
		return;

	leaveSafeZone(client);
}

public Action Timer_Quarantine(Handle timer, int client)
{
	virus[client].tQuarantine = null;
	
	#if defined ENGLISH
	CPrintToChat(client, "{green}[SM-Virus]{lightgreen} You have been quarantined long enough so you are healed!");
	#else
	CPrintToChat(client, "{green}[SM-Virus]{lightgreen} Has permanecido en cuarentena el tiempo suficiente así que estas curado!");
	#endif
	
	resetClient(client);
}