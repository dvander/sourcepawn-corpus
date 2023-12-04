/*
	"rage_hinttext"		//Ability name can use suffixes
	{
		"slot"			"0"								// Ability Slot
		"message"		"Go Get Them Maggot!"			// Hinttext Message
		"plugin_name"	"ff2r_subplugin_template"		// this subplugin name
	}
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cfgmap>
#include <ff2r>
#include <tf2_stocks>
#include <tf2items>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2 Rewrite: My Stock Subplugin"
#define PLUGIN_AUTHOR 	"J0BL3SS"
#define PLUGIN_DESC 	"It's a template ff2r subplugin"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"0"
#define STABLE_REVISION "1"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL ""

#define MAXTF2PLAYERS	36

public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESC,
	version 	= PLUGIN_VERSION,
	url			= PLUGIN_URL,
};

public void OnPluginStart()
{
	for(int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		if(IsClientInGame(clientIdx))
		{
			OnClientPutInServer(clientIdx);
			
			BossData cfg = FF2R_GetBossData(clientIdx);	// Get boss config (known as boss index) from player
			if(cfg)
			{
				FF2R_OnBossCreated(clientIdx, cfg, false);	// If boss is valid, Hook the abilities because this subplugin is most likely late-loaded
			}
		}
	}
}

public void OnClientPutInServer(int clientIdx)
{
	// Check and apply stuff if boss abilities that can effect players is active
}

public void OnPluginEnd()
{
	for(int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		// Clear everything from players, because FF2:R either disabled/unloaded or this subplugin unloaded
	}
}

public void FF2R_OnBossCreated(int clientIdx, BossData cfg, bool setup)
{
	/*
	 * When boss created, hook the abilities etc.
	 *
	 * We no longer use RoundStart Event to hook abilities because bosses can be created trough 
	 * manually by command in other gamemodes other than Arena or create bosses mid-round.
	 *
	 */
}

public void FF2R_OnBossRemoved(int clientIdx)
{
	 /*
	  * When boss removed (Died/Left the Game/New Round Started)
	  * 
	  * Unhook and clear ability effects from the player/players
	  *
	  */
}

public void FF2R_OnAbility(int clientIdx, const char[] ability, AbilityData cfg)
{
	//Just your classic stuff, when boss raged:
	if(!cfg.IsMyPlugin())	// Incase of duplicated ability names with different plugins in boss config
		return;
	
	if(!StrContains(ability, "rage_hinttext", false))	// We want to use subffixes
	{
		static char buffer[128];
		cfg.GetString("message", buffer, sizeof(buffer));	// We use ConfigMap to Get string from "message" argument from ability
		
		if(buffer[0] != '\0') {
			PrintHintText(clientIdx, buffer);
		}
		else {
			PrintHintText(clientIdx, "fill up your \"message\" argument lol");
		}			
	}
}

stock bool IsValidClient(int clientIdx, bool replaycheck=true)
{
	if(clientIdx <= 0 || clientIdx > MaxClients)
		return false;

	if(!IsClientInGame(clientIdx) || !IsClientConnected(clientIdx))
		return false;

	if(GetEntProp(clientIdx, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(clientIdx) || IsClientReplay(clientIdx)))
		return false;

	return true;
}