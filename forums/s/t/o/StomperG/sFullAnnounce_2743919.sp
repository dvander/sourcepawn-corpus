#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <emperor>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ConVar g_scm_cvar_holdtime;

ConVar g_scm_cvar_red;
ConVar g_scm_cvar_green;
ConVar g_scm_cvar_blue;
ConVar g_scm_cvar_transparency;

ConVar g_scm_cvar_x;
ConVar g_scm_cvar_y;

ConVar g_scm_cvar_effecttype;

ConVar g_scm_cvar_effectduration;
ConVar g_scm_cvar_fadeinduration;
ConVar g_scm_cvar_fadeoutduration;

ConVar g_cvar_verify;

float scm_holdtime;

Handle HUD;

public Plugin myinfo = 
{
	name = "sFullAnnounce", 
	author = "StomperG", 
	description = "Announce when server is full and someone's on spectator.", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/StomperG"
};


public void OnPluginStart()
{
	g_scm_cvar_x = CreateConVar("sm_scm_x", "-1.0", "Horizontal Position to show the displayed message (To be centered, set as -1.0).", _, true, -1.0, true, 1.0);
	g_scm_cvar_y = CreateConVar("sm_scm_y", "0.1", "Vertical Position to show the displayed message (To be centered, set as -1.0).", _, true, -1.0, true, 1.0);
	g_scm_cvar_holdtime = CreateConVar("sm_scm_holdtime", "5.0", "Time that the message is shown.", _, true, 0.0, true, 5.0);
	g_scm_cvar_red = CreateConVar("sm_scm_r", "255", "RGB Red Color to the displayed message.", _, true, 0.0, true, 255.0);
	g_scm_cvar_green = CreateConVar("sm_scm_g", "0", "RGB Green Color to the displayed message.", _, true, 0.0, true, 255.0);
	g_scm_cvar_blue = CreateConVar("sm_scm_b", "0", "RGB Blue Color to the displayed message.", _, true, 0.0, true, 255.0);
	g_scm_cvar_transparency = CreateConVar("sm_scm_transparency", "100", "Message Transparency Value.");
	g_scm_cvar_effecttype = CreateConVar("sm_scm_effect", "1.0", "0 - Fade In; 1 - Fade out; 2 - Flash", _, true, 0.0, true, 2.0);
	g_scm_cvar_effectduration = CreateConVar("sm_scm_effectduration", "0.5", "Duration of the selected effect. Not always aplicable");
	g_scm_cvar_fadeinduration = CreateConVar("sm_scm_fadeinduration", "0.5", "Duration of the selected effect.");
	g_scm_cvar_fadeoutduration = CreateConVar("sm_scm_fadeoutduration", "0.5", "Duration of the selected effect.");
	g_cvar_verify = CreateConVar("verificar", "7.0", "Time to verify");
	
	HUD = CreateHudSynchronizer();
	
	CreateConVar("sm_stmp_plugin_ver", PLUGIN_VERSION, "Plugin version // Do not touch!", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
}


public void OnConfigsExecuted()
{
	// HUD Stuff
	scm_holdtime = GetConVarFloat(g_scm_cvar_holdtime);
	int scm_red = GetConVarInt(g_scm_cvar_red);
	int scm_green = GetConVarInt(g_scm_cvar_green);
	int scm_blue = GetConVarInt(g_scm_cvar_blue);
	int scm_transparency = GetConVarInt(g_scm_cvar_transparency);
	int scm_effect = GetConVarInt(g_scm_cvar_effecttype);
	float scm_x = GetConVarFloat(g_scm_cvar_x);
	float scm_y = GetConVarFloat(g_scm_cvar_y);
	float scm_effectduration = GetConVarFloat(g_scm_cvar_effectduration);
	float scm_fadein = GetConVarFloat(g_scm_cvar_fadeinduration);
	float scm_fadeout = GetConVarFloat(g_scm_cvar_fadeoutduration);
	
	SetHudTextParams(scm_x, scm_y, scm_holdtime, scm_red, scm_green, scm_blue, scm_transparency, scm_effect, scm_effectduration, scm_fadein, scm_fadeout);
	
}

public void OnMapStart()
{
	float time_verify = GetConVarFloat(g_cvar_verify);
	
	CreateTimer(time_verify, CountPlayers, _, TIMER_REPEAT);
}

public Action CountPlayers(Handle timer, int client)
{
	if (GetMaxHumanPlayers() <= GetClientCount(true))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (EMP_IsValidClient(i) && IsClientInGame(i))
			{
				if (GetClientTeam(i) == CS_TEAM_SPECTATOR) {
					ShowSyncHudText(i, HUD, "O servidor encontra-se cheio, caso queiras trocar, utiliza !servers"); // Portuguese Message
					//ShowSyncHudText(i, HUD, "The server is currently full, if you want to change type !servers"); // English Message
				}
			}
		}
	}
} 