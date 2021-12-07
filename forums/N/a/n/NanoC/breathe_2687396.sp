#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <multicolors>
#include <clientprefs>

#define SOUND_BREATHE	"breathing.mp3"
#define SOUND_BREATHE_TABLE	"sound/breathing.mp3"

#pragma semicolon 1
#pragma newdecls required

bool g_bBreathEnabled[MAXPLAYERS + 1];

ConVar g_cvAreBotsBreathing;
ConVar g_cvWhoShouldBreathe;

Handle g_hBreatheCookie;

public Plugin myinfo = 
{
	name = "[CS:GO] Breathe",
	author = "Original plugin from thecount, Rewritten by Natanel 'LuqS', Edited by Nano",
	description = "",
	version = "1.0",
	url = "https://steamcommunity.com/id/LuqSGood/"
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");
	}

	g_hBreatheCookie = RegClientCookie("Breathe", "Breathe Cookie", CookieAccess_Protected);

	RegConsoleCmd("sm_breathe", Command_Breathe);
	RegConsoleCmd("sm_breathing", Command_Breathe);

	g_cvAreBotsBreathing 	= CreateConVar("breathe_are_bots_breathing"	, "1.0"	, "Whether to make bots breathe or not.");
	g_cvWhoShouldBreathe	= CreateConVar("breathe_who_should_breathe"	, "0"	, "0 - Both teams, 1 - Only Terrorists, 2 - Only Counter-Terrorists");
	
	for(int iCurrentClient = 1; iCurrentClient <= MaxClients; iCurrentClient++)
	{
		if(IsValidClient(iCurrentClient, g_cvAreBotsBreathing.BoolValue))
		{
			OnClientPutInServer(iCurrentClient);
		}
	}
}

public void OnMapStart()
{
	AddFileToDownloadsTable(SOUND_BREATHE_TABLE);
	PrecacheSound(SOUND_BREATHE, true);
}

public void OnClientPutInServer(int client)
{
	g_bBreathEnabled[client] = true;
	char buffer[64];
	GetClientCookie(client, g_hBreatheCookie, buffer, sizeof(buffer));
	if(StrEqual(buffer,"0"))
	{
		g_bBreathEnabled[client] = false;
	}

	CreateTimer(10.2, Timer_Breathe, GetClientUserId(client), TIMER_REPEAT);
}

public Action Command_Breathe(int client, int args)
{
	ToggleBreath(client);
	return Plugin_Handled;
}

public void ToggleBreath(int client)
{
	if(!client)
	{
		return;
	}

	g_bBreathEnabled[client] = !g_bBreathEnabled[client];
	SetClientCookie(client, g_hBreatheCookie, g_bBreathEnabled[client] ? "1" : "");

	CPrintToChat(client, "{green}[BREATHING]{default} You have %s {default}breathing sounds. This option will be saved {darkred}until you write the command again.", g_bBreathEnabled[client] ? "{blue}enabled" : "{darkred}disabled");
}

public Action Timer_Breathe(Handle timer, any userId)
{
	int client = GetClientOfUserId(userId);
	int cvarBreathing = g_cvWhoShouldBreathe.IntValue;
	
	if(!IsValidClient(client, g_cvAreBotsBreathing.BoolValue, false) || !(cvarBreathing == 0 ? true : (cvarBreathing == 1 ? GetClientTeam(client) == CS_TEAM_T : GetClientTeam(client) == CS_TEAM_CT)))
	{
		return Plugin_Stop;
	}
	
	if(IsValidClient(client) && g_bBreathEnabled[client])
	{
		EmitSoundToClient(client, SOUND_BREATHE, client, SNDCHAN_AUTO, SNDLEVEL_CONVO);
	}

	return Plugin_Continue;
}

// Checking if the sent client is valid based of the parmeters sent and other other functions.
stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client) || (IsFakeClient(client) && !bAllowBots) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}