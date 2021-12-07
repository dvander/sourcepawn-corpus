#pragma semicolon 1
#include <sourcemod>
#include <basestock>
/**
 * =============================================================================
 * ImDawe plugin
 * www.neogames.eu Plugin / Mod request section for plugin request
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * CONTACT:
 * MSN/MAIL: imdawe@hotmail.com
 * STEAM: csokikola
 * Add me if you have any question
 * =============================================================================
 */
 
/***************
	DEFINES
***************/
#define VERSION 		"1.0"
#define NAME 			"[ANY] Remaing HP"
#define AUTHOR	 		"ImDawe"
#define DESCRIPTION 	"This plugin displays the victims remaing health points"


/***************
	REGISTER PLUGIN
***************/

public Plugin:myinfo =
{
	name = NAME,
	author = AUTHOR,
	description = DESCRIPTION,
	version = VERSION,
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("rhp.phrases.txt");
	RegisterConVar("sm_rhp_version", VERSION, "Version of rhp plugin", TYPE_STRING);
	HookEvent("player_hurt", Event_OnPlayerHurt);
}

/***************
	FUNCTIONS
***************/

public Action:Event_OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!client)
		return Plugin_Continue;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new hp = GetClientHealth(victim);
	new String:pName[128];
	GetClientName(victim, pName, sizeof(pName));
	if(hp > 0)
	{
		PrintCenterText(client, "%t", "HpDisplay", pName, hp);
	}else{
		PrintCenterText(client, "%t", "KillDisplay", pName);
	}
	return Plugin_Continue;
}
