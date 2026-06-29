//
// SourceMod Script
//
// Developed by dbozan99
// June 2008
// http://www.gauntletcss.com
//

// USE:
// Install To Your Server.

// CONSOLE VARIABLES
// flashwars_enable - Set to 1 To turn on. 0 = Turn off. [Def 0]
// flashwars_flash  - Set To 1 For Flash Or 0 For No Flash [Def 1] (Only if flashwars_enable = 1)

// DESCRIPTION:
// This Plugin Strips all weapons (and money) from people and gives them 1 hp and flashbangs to kill the other team with.

// CHANGELOG:
// - Version 1.1
//   If flashwars_enable is toggled midgame, the server will be isssued a "mp_restartgame 1"
//
// - Version 1.0
//   Initial Release

#include <sourcemod>
#include <sdktools>


#define ZERO_MONEY 0
#define ONE_HEALTH 1
#define ALPHA_ZERO 0.5
#define FLASHWARS_VERSION 1.1


// offsets
new g_iAccount = -1;
new g_iFlashAlpha = -1;
new FindHP = -1;

// cvars
new Handle:cvar_flash = INVALID_HANDLE;
new Handle:cvar_enable = INVALID_HANDLE;
new Handle:cvar_version = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Flash Wars",
	author = "dbozan99",
	description = "Kill The Other Team With FlashBangs!",
	version = "1.1",
	url = "http://www.gauntletcss.com/"
}

public OnPluginStart()
{

	// find offsets
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_iFlashAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	FindHP = FindSendPropOffs("CCSPlayer", "m_iHealth");
	
	// hook events
	HookEvent("player_blind",Event_Flashed);
	HookEvent("player_spawn",Event_spawn);
	HookEvent("player_death",Event_death);
	HookEvent("flashbang_detonate",Event_detonate);
	
	//reg cvar
	cvar_enable = CreateConVar("flashwars_enable","0","Set to 1 To turn on. 0 = Turn off. [Def 0]");
	cvar_flash = CreateConVar("flashwars_flash","0","1=Flash Like a normal Flashbang, 0=No Flash [Def 0]");
	cvar_version = CreateConVar("flashwars_version","1.1","Flashwars Version 1.0 By dbozan99. http://www.gauntletcss.com/");

	HookConVarChange(cvar_enable, Event_changed);
}


public Action:Event_Flashed(Handle:event, const String:name[], bool:dontBroadcast)
{
if (GetConVarBool(cvar_enable) == 1)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
    if (g_iFlashAlpha != -1)
    {
		if (GetConVarBool(cvar_flash) == 0)
		{
		SetEntDataFloat(client, g_iFlashAlpha, ALPHA_ZERO);
		}
    }
}
}


public Action:Event_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
if (GetConVarBool(cvar_enable) == 1)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	StripAndGive( client );
}
}


public Action:Event_detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
if (GetConVarBool(cvar_enable) == 1)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	StripAndGive( client );
}
}


public Action:Event_death(Handle:event, const String:name[], bool:dontBroadcast)
{
if (GetConVarBool(cvar_enable) == 1)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker" ));
	if (attacker != 0)
	{
	SetEntData(attacker, g_iAccount, ZERO_MONEY);
	StripAndGive( attacker );
	}
}
}

public Event_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ServerCommand("mp_restartgame 1");
	if (GetConVarBool(cvar_enable) == 1)
	{
	PrintToChatAll ("FlashWars Has Been Enabled. Kill The Other Team With Your FlashBangs!");
	PrintCenterTextAll ("FlashWars Enabled.");
	PrintHintTextToAll ("FlashWars Enabled.");
	}
	else
	{
	PrintToChatAll ("FlashWars Disabled.")
	PrintCenterTextAll ("FlashWars Disabled.")
	PrintHintTextToAll ("FlashWars Disabled.")
	}
}

StripAndGive( client )
	{
	SetEntData(client, g_iAccount, ZERO_MONEY);
	SetEntData(client, FindHP, ONE_HEALTH);
	new wepIdx;
	for( new i = 0; i < 6; i++ ){
		while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 )
			{
			RemovePlayerItem( client, wepIdx );
			}
		}
	GivePlayerItem(client, "weapon_flashbang");
	}