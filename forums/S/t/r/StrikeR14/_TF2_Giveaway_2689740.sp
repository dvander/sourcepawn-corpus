#include <sourcemod>
#include <sdktools>
#include <morecolors>

#pragma newdecls required
#pragma semicolon 1

bool g_bGARunning;
int g_iNumber[MAXPLAYERS + 1] =  { -1, ... };
int g_Time;
char g_sGARedeemCode[64], g_sGAMessage[64];

ConVar gcv_Time;

public Plugin myinfo =  
{
	name = "[TF2] Giveaway", 
	author = "StrikeR", 
	description = "A system that allows admins to host giveaways and randomize winners.", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/kenmaskimmeod/"
};

//-----[ Events ]-----//

public void OnPluginStart()
{
	gcv_Time = CreateConVar("sm_giveaway_time", "20", "Duartion of the giveaway event.", _, true, 10.0);
	g_Time = gcv_Time.IntValue;
	
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_startgiveaway", Command_StartGiveAway, ADMFLAG_RCON);
	RegAdminCmd("sm_sga", Command_StartGiveAway, ADMFLAG_RCON);
	RegAdminCmd("sm_abortgiveaway", Command_AbortGiveAway, ADMFLAG_RCON);
	RegAdminCmd("sm_aga", Command_AbortGiveAway, ADMFLAG_RCON);
	RegConsoleCmd("sm_giveaway", Command_GiveAway);
	RegConsoleCmd("sm_ga", Command_GiveAway);
}

public void OnMapStart()
{
	PrecacheSound("vo/announcer_begins_1sec.mp3");
	PrecacheSound("vo/announcer_begins_2sec.mp3");
	PrecacheSound("vo/announcer_begins_3sec.mp3");
	PrecacheSound("vo/announcer_begins_4sec.mp3");
	PrecacheSound("vo/announcer_begins_5sec.mp3");
	PrecacheSound("vo/announcer_dec_missionbegins10s01.mp3");
	PrecacheSound("items/cart_explode_trigger.wav");
	PrecacheSound("items/pumpkin_drop.wav");
	PrecacheSound("misc/happy_birthday.wav");
}

public void OnClientDisconnect(int client)
{
	g_iNumber[client] = -1;
}

//-----[ Commands ]-----//

public Action Command_StartGiveAway(int client, int args)
{
	if (args < 2)
	{
		CReplyToCommand(client, "{red}[{default}SM{red}]{default} Usage: sm_startgiveaway <REEDEM CODE> <prize>");
		return Plugin_Handled;
	}
	if (g_bGARunning)
	{
		CReplyToCommand(client, "{red}[{default}SM{red}]{default} Giveaway is already running, type /aga to abort it.");
		return Plugin_Handled;
	}
	
	char text[128], arg2[10];
	GetCmdArgString(text, sizeof(text));
	int len = BreakString(text, arg2, 10);
	
	for (int i = 1; i <= MaxClients; i++)
		g_iNumber[i] = -1;
	
	g_bGARunning = true;
	strcopy(g_sGARedeemCode, sizeof(g_sGARedeemCode), arg2);
	strcopy(g_sGAMessage, sizeof(g_sGAMessage), text[len]);
	CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CPrintToChatAll("{red}[{default}SM{red}] {red}%N {unusual}Started Giveaway event! {red}%s{unusual}.", client, g_sGAMessage);
	return Plugin_Handled;
}

public Action Command_AbortGiveAway(int client, int args)
{
	if (!g_bGARunning)
	{
		CReplyToCommand(client, "{red}[{default}SM{red}]{default} Giveaway is not running.");
		return Plugin_Handled;
	}
	
	g_bGARunning = false;
	CShowActivity2(client, "{red}[{default}SM{red}]{default} ", "Stopped the {unusual}Giveaway{default} event.");
	return Plugin_Handled;
}

public Action Command_GiveAway(int client, int args)
{
	if (!g_bGARunning)
	{
		CReplyToCommand(client, "{red}[{default}SM{red}] {unusual}Giveaway{default} is not running... yet.");
		return Plugin_Handled;
	}
	
	if (g_iNumber[client] > -1)
	{
		CReplyToCommand(client, "{red}[{default}SM{red}]{default} You already have a number, %d.", g_iNumber[client]);
		return Plugin_Handled;
	}
	
	if (!args)
	{
		CReplyToCommand(client, "{red}[{default}SM{red}]{default} Usage: sm_ga <1-100>");
		return Plugin_Handled;
	}
	
	char arg[5];
	GetCmdArg(1, arg, sizeof(arg));
	int iarg = StringToInt(arg);
	
	if (!(1 <= iarg <= 100))
	{
		CReplyToCommand(client, "{red}[{default}SM{red}]{default} Number must be in the range 1-100.");
		return Plugin_Handled;
	}
	
	if (GetMatched(iarg) != -1)
	{
		CReplyToCommand(client, "{red}[{default}SM{red}]{default} %N has already chosen the number %d.", GetMatched(iarg), iarg);
		return Plugin_Handled;
	}
	
	g_iNumber[client] = iarg;
	
	if (IsPlayerAlive(client))
	{
		float fPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		ClientParticle(client, "teleportedin_red", fPos, 3.0);
	}
	
	CPrintToChatAll("{red}[{default}SM{red}]{default} %N has received the number %d, Good luck!", client, g_iNumber[client]);
	return Plugin_Handled;
}

//-----[ Timers ]-----//

public Action Timer_CountDown(Handle timer)
{
	if (g_Time <= 0)
	{
		g_bGARunning = false;
		
		int winner = GetWinner();
		if (winner == -1)
		{
			CPrintToChatAll("{red}[{default}SM{red}] Nobody has entered the giveaway!");
			SetHudTextParams(-1.0, 0.15, 15.0, 255, 0, 0, 255);
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					ShowHudText(i, 0, "--------------- Giveaway ---------------\n------ No one has entered the giveaway! ------");
				}
			}
			
			g_Time = gcv_Time.IntValue;
			return Plugin_Stop;
		}
		
		CPrintToChatAll("{red}[{default}SM{red}]{default} The winning number was {red}%d{default}, and the winner is {unusual}%N{default}. {red}Congrats!", g_iNumber[winner], winner);
		
		float fPos[3];
		GetEntPropVector(winner, Prop_Send, "m_vecOrigin", fPos);
		for (int i = 1; i < 10; i++)
			ClientParticle(winner, "bday_confetti", fPos, 3.0);
		ClientParticle(winner, "green_wof_sparks", fPos, 3.0);
		
		SetHudTextParams(-1.0, 0.15, 15.0, 0, 255, 50, 255);
		
		for (int d = 1; d <= MaxClients; d++)
		{
			if (IsValidClient(d))
			{
				ShowHudText(d, 0, "--------------- Giveaway ---------------\n------------ %s ------------\n------ The winning number was %d ------\n------ The winner is %N ------", g_sGAMessage, g_iNumber[winner], winner);
			}
		}
		
		EmitSoundToAll("misc/happy_birthday.wav", winner);
		CPrintToChat(winner, "{red}[{default}SM{red}]{default} You won the event!! Here's your code: {red}%s", g_sGARedeemCode);
		PrintToConsole(winner, "You won the event!! Here's your code: %s\nYou won the event!! Here's your code: %s\nYou won the event!! Here's your code: %s\nYou won the event!! Here's your code: %s", 
		g_sGARedeemCode, g_sGARedeemCode, g_sGARedeemCode, g_sGARedeemCode);
		g_Time = gcv_Time.IntValue;
		return Plugin_Stop;
	}
	
	SetHudTextParams(-1.0, 0.15, 0.8, 50, 70, 255, 255);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			ShowHudText(i, 0, "--------------- Giveaway ---------------\n------------ %s ------------\nJoin the giveaway by typing !ga in the chat!\nYou have %02d:%02d seconds to enter", g_sGAMessage, g_Time / 60, g_Time % 60);
		}
	}
	
	if (g_Time == gcv_Time.IntValue)
	{
		EmitSoundToAll("items/cart_explode_trigger.wav");
	}
	else if (g_Time == 10)
	{
		EmitSoundToAll("vo/announcer_dec_missionbegins10s01.mp3");
	}
	else if (g_Time <= 5)
	{
		char buffer[32];
		FormatEx(buffer, sizeof(buffer), "vo/announcer_begins_%dsec.mp3", g_Time);
		EmitSoundToAll(buffer);
	}
	
	g_Time--;
	return Plugin_Continue;
}

//-----[ Functions ]-----//

int GetMatched(const int iNumber)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && g_iNumber[i] == iNumber)
		{
			return i;
		}
	}
	return -1;
}

int GetWinner()
{
	bool noOne = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && g_iNumber[i] > -1)
		{
			noOne = false;
			break;
		}
	}
	
	if (noOne)
		return -1;
	
	int winner;
	do 
		winner = GetRandomInt(1, MaxClients);
	while (!IsValidClient(winner) || g_iNumber[winner] == -1);
	return winner;
}

void ClientParticle(int client, const char[] effect, float fPos[3], float time)
{
	int iParticle = CreateEntityByName("info_particle_system");
	char sName[16];
	if (iParticle != -1)
	{
		TeleportEntity(iParticle, fPos, NULL_VECTOR, NULL_VECTOR);
		FormatEx(sName, 16, "target%d", client);
		DispatchKeyValue(client, "targetname", sName);
		DispatchKeyValue(iParticle, "targetname", "tf2particle");
		DispatchKeyValue(iParticle, "parentname", sName);
		DispatchKeyValue(iParticle, "effect_name", effect);
		DispatchSpawn(iParticle);
		SetVariantString(sName);
		AcceptEntityInput(iParticle, "SetParent", iParticle, iParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "start");
		CreateTimer(time, Timer_KillEntity, iParticle);
	}
}

public Action Timer_KillEntity(Handle timer, any prop)
{
	if (IsValidEntity(prop))
		AcceptEntityInput(prop, "Kill");
	return Plugin_Continue;
}

bool IsValidClient(const int client)
{
	return IsClientInGame(client) && IsClientConnected(client);
} 