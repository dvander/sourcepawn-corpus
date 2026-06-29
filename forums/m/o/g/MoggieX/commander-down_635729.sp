/**
* Sound & Hint Say for whena ROOT admin dies [7 Jun 08]
*
* Description:
*	When a ROOT admin dies, a sound and hint message is played
*
* Usage:
*	Install & Go!
*	If you are NOT using CSS, chnage this to a valid sound sm_commander_sound in your /cfg/sourcemod.cfg
*	Oh and sm_commander_enable enables and disables it too :-P	
*
* Thanks to:
* 	Every other plugin on SM
*	
* Based upon:
*	Nothign really, it was an idea I had while playing
*  
* Version History
* 	1.0 - After quite a few attempts it works :-P
* 	
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#define CD_VERSION "1.0"
#define MAX_FILE_LEN 80
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];
new Handle:cvarEnable;
new bool:g_isHooked;

// Define author information
public Plugin:myinfo = 
{
	name = "Commander Down",
	author = "MoggieX",
	description = "When a root admin dies, play sound",
	version = CD_VERSION,
	url = "http://www.UKManDown.co.uk"
};

public OnPluginStart()
{
	CreateConVar("sm_commander_version", CD_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	cvarEnable = CreateConVar("sm_commander_enable","1","Plays sound play root admin is killed",FCVAR_PLUGIN,true,0.0,true,1.0);
	g_CvarSoundName = CreateConVar("sm_commander_sound", "bot/the_commander_is_down_repeat.wav", "The sound to play when a root player is killed");
	CreateTimer(3.0, OnPluginStart_Delayed);
}

// For sounds and its caching
public OnConfigsExecuted()
{
	GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(g_soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	AddFileToDownloadsTable(buffer);
}


public Action:OnPluginStart_Delayed(Handle:timer){
	if(GetConVarInt(cvarEnable) > 0)
	{
		g_isHooked = true;
		HookEvent("player_death",ev_PlayerDeath);
		
		HookConVarChange(cvarEnable,CommanderCvarChange);
		
		LogMessage("[Commander Down] - Loaded");
	}
}

public CommanderCvarChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(GetConVarInt(cvarEnable) <= 0){
		if(g_isHooked){
		g_isHooked = false;
		UnhookEvent("player_death",ev_PlayerDeath);
		}
	}else if(!g_isHooked){
		g_isHooked = true;
		HookEvent("player_death",ev_PlayerDeath);
	}
}

public ev_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if enabled, if not bail out
	if (GetConVarInt(cvarEnable) == 0)
	{
		return;
	}

	// Get as little info as possible here
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if(CheckCommandAccess(victim, "sm_rcon", ADMFLAG_ROOT) == true)
	{
		// OK its a nub with ROOT admin that has died
		
		// get thier team
		new victimTeam = GetClientTeam(victim);
		
		// play only for alive, non bot and in game players on the same team
		new MaxClients = GetMaxClients();
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == victimTeam)
			{
				// do stuff
				EmitSoundToClient(i, g_soundName);
				PrintHintText(i, "The Commander is Down!!!");

			}
		}
		
		//now message the killer of the commander

		decl String:killerName[100];
		decl String:victimName[100];

		new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
		GetClientName(killer,killerName,100);
		GetClientName(victim,victimName,100);
		
		PrintToChat(killer, "\x04 [Commander Down]\x03 Well done %s you killed the Commander %s!", killerName, victim);

	}
}

