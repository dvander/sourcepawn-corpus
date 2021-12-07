/*
* No Witch Hunting
* 
* Set up:
* ===========================
* The witch. 
* What more is she than a common road block?
* 
* It is really a sob story. She need some fear put back into her.
* Even through in L4D2 she now can wander, it doesnt really help her. So.
*  I set out to find somehow to make her feared again or at least make the
*  survivor regret missing crown / strafe bullet hitting her.
* 
* This will make the survivors go black and white if they got incaped her
*  or instant kill!
* 
* "Fear me! /cries" - The Witch
* 
* Plugin Description:
* ===========================
* An attempt to put some fear back into the witch, survivors can go black
*  and white upon incap or be instant killed by the witch
* 
* Known Problems / Things to Notice:
* =====================================
* This is active on all gamemodes. As I'm really lazy and don't add a
*  gamemode check, may I recommend "Game Mode Config Loader"
*  (http://forums.alliedmods.net/showthread.php?t=93212) to disable
*  this plugin in coop/survival or what not.
* 
* Simply change l4d_nwh_incapaction to 0 upon coop and 
*  l4d_nwh_incapaction to 1/2 upon versus.
* 
* Changelog:
* ===========================
* Legend: 
*  + Added 
*  - Removed 
*  ~ Fixed or changed
* 
* Version 0.9
* -----------------
* Initial release
* 
* - Mr. Zero
*/

// ***********************************************************************
// PREPROCESSOR
// ***********************************************************************
#pragma semicolon 1
#pragma newdecls required
// ========================================================
// Includes
// ========================================================
#include <sourcemod>
#include <sdktools>

// ***********************************************************************
// CONSTANTS
// ***********************************************************************
#define PLUGIN_VERSION 		"0.90"

// ========================================================
// Plugin Info
// ========================================================
public Plugin myinfo = 
{
	name = "No Witch Hunting",
	author = "Mr. Zero",
	description = "An attempt to put some fear back into the witch, survivors can go black and white upon incap or be instant killed by the witch",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}
// ***********************************************************************
// VARIABLES
// ***********************************************************************
Handle g_hWitchIncapAction;
Handle g_hSurvivorMaxIncapCount;
int g_iSurvivorMaxIncapCount = 2;

// ***********************************************************************
// FUNCTIONS
// ***********************************************************************
public void OnPluginStart()
{
	g_hWitchIncapAction = CreateConVar("l4d_nwh_incapaction","1","What action to take upon witch incapping a survivor. 0 - Disable plugin, 1 - Survivor becomes black and white, 2 - Instant kill the survivor",FCVAR_NONE);
	CreateConVar("l4d_nwh_version", PLUGIN_VERSION, "No Witch Hunting Version", FCVAR_NONE|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	AutoExecConfig(true,"NoWitchHunting");
	
	g_hSurvivorMaxIncapCount = FindConVar("survivor_max_incapacitated_count");
	HookConVarChange(g_hSurvivorMaxIncapCount, CvarChanged_IncapCount);
	
	HookEvent("player_incapacitated_start", Event_WitchIncap);
}

public void CvarChanged_IncapCount(ConVar convar, const char[] oldValue, const char[] newValue) {g_iSurvivorMaxIncapCount = StringToInt(newValue);}

public void Event_WitchIncap(Event event, const char[] n, bool dB)
{
	int IncapAction;
	IncapAction = GetConVarInt(g_hWitchIncapAction);
	if(IncapAction == 0){return;}
	
	int type = GetEventInt(event, "type");
	
	// Witch damage type: 4
	if(type != 4){return;}
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IncapAction == 1)
	{
		int count = GetEntProp(client,Prop_Send,"m_currentReviveCount");
		if(count > g_iSurvivorMaxIncapCount - 1){return;}
		
		SetEntProp(client,Prop_Send,"m_currentReviveCount",g_iSurvivorMaxIncapCount - 1);
	}
	else
	{
		ForcePlayerSuicide(client);
	}
}