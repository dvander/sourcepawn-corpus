/**
* Bomb Defuser Gets a Slappin!
*
* Description:
*	Slaps the living daylights out of the CT trying to defuse the bomb
*
* Usage:
*	sm_psay <name or #userid> <message> - sends private message as a menu panel
*	sm_masay <message> - sends message to admins as a menu panel
*	sm_namsay <message> - sends message to non-admins as a menu panel
*	
* Thanks to:
* 	Tsunami for my n00b questions
*	
* Based upon:
*	n00bs
*  
* Version History
* 	1.0 - First Release
* 	
*/
//////////////////////////////////////////////////////////////////
// Defines, Includes, Handles & Plugin Info
//////////////////////////////////////////////////////////////////
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#define SD_VERSION "1.0"
#define MAX_FILE_LEN 80
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

new Handle:cvarEnable;
new bool:g_isHooked;

// Define author information
public Plugin:myinfo = 
{
	name = "Slap Defuser",
	author = "MoggieX",
	description = "Slap the CT who is Defusing",
	version = SD_VERSION,
	url = "http://www.UKManDown.co.uk"
};

//////////////////////////////////////////////////////////////////
// Plugin Start
//////////////////////////////////////////////////////////////////
public OnPluginStart()
{
	CreateConVar("sm_slapdefuser_version", SD_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	cvarEnable = CreateConVar("sm_slapdefuser_enable","1","Plays sound and gives chat ntoification when a player is knifed",FCVAR_PLUGIN,true,0.0,true,1.0);
	g_CvarSoundName = CreateConVar("sm_slapdefuser_sound", "bot/this_is_my_house.wav", "The sound to play when a player is trying to defuse");

	CreateTimer(3.0, OnPluginStart_Delayed);

}

//////////////////////////////////////////////////////////////////
// Caching Sound File
//////////////////////////////////////////////////////////////////
public OnConfigsExecuted()
{
	GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(g_soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	AddFileToDownloadsTable(buffer);
}

//////////////////////////////////////////////////////////////////
// Hook Event
//////////////////////////////////////////////////////////////////
public Action:OnPluginStart_Delayed(Handle:timer){
	if(GetConVarInt(cvarEnable) > 0)
	{
		g_isHooked = true;
		HookEvent("bomb_begindefuse",ev_BombDefusing);
		
		HookConVarChange(cvarEnable,SlapDefuserCvarChange);
		
		LogMessage("[Slap Defuser] - Loaded");
	}
}
//////////////////////////////////////////////////////////////////
// Check for changes
//////////////////////////////////////////////////////////////////
public SlapDefuserCvarChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(GetConVarInt(cvarEnable) <= 0){
		if(g_isHooked){
		g_isHooked = false;
		UnhookEvent("bomb_begindefuse",ev_BombDefusing);
		}
	}else if(!g_isHooked){
		g_isHooked = true;
		HookEvent("bomb_begindefuse",ev_BombDefusing);
	}
}
//////////////////////////////////////////////////////////////////
// The Funny Bit
//////////////////////////////////////////////////////////////////
public ev_BombDefusing(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if enabled, if not bail out

	if (GetConVarInt(cvarEnable) == 0)
	{
		return;
	}

	decl String:victimName[100];
	
	new userid = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(userid);
	
	GetClientName(victim,victimName,100);
	//GetClientName(killer,killerName,100);

	//Slap the nub cake		
	SlapPlayer(victim, 0);
	
	//hell lets slap em again for good measure :P
	SlapPlayer(victim, 0);
	SlapPlayer(victim, 0);
	SlapPlayer(victim, 0);

	PrintToChat(victim, "\x03Oh no you don't \x0%s\x04, thats MY bomb!",victimName);
	PrintToChatAll("\x04 [Slap Defuser]\x03 %s was slapped to buggery for trying to defuse the bomb",victimName);

	// play Sound to all
	EmitSoundToAll(g_soundName);

}

