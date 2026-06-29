/*
bottools.sp

Description:
	A variety of tools for dealing with bots

Versions:
	0.5
		* Initial Release
		
	1.0
		* Added menu system
		* Added weapon commands
		* Added weapon restrictions
		* Added general bot controls
		* Added general bot commands
		* Added other bot options
		* Added support for localization
		* switched to bot_kill
		* sm_bot_tools_autoslay now effects plugin behavior after startup
		
	1.1
		* Added options for bot chatter control
		
	1.2
		* Changed menu selection behavior
		* Fixed other menu
*/

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "SM Bot Tools",
	author = "AMP",
	description = "Bot Tools Plugin for CS:S bot management",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new iLifeState = -1;
new Handle:cvarEnabled = INVALID_HANDLE;
new Handle:cvarAutoSlay = INVALID_HANDLE;
new	Handle:cvarBotCount = INVALID_HANDLE;
new	Handle:cvarDefer = INVALID_HANDLE;
new	Handle:cvarDifficulty = INVALID_HANDLE;
new	Handle:cvarQuota = INVALID_HANDLE;
new	Handle:cvarQuotaMode = INVALID_HANDLE;
new	Handle:cvarAutoFollow = INVALID_HANDLE;
new	Handle:cvarAllowRogues = INVALID_HANDLE;
new	Handle:cvarAllowMGS = INVALID_HANDLE;
new	Handle:cvarAllowPistols = INVALID_HANDLE;
new	Handle:cvarAllowRifles = INVALID_HANDLE;
new	Handle:cvarAllowShotguns = INVALID_HANDLE;
new	Handle:cvarAllowSMGS = INVALID_HANDLE;
new	Handle:cvarAllowSnipers = INVALID_HANDLE;
new	Handle:cvarChatter = INVALID_HANDLE;

public OnPluginStart()
{
	// Before we do anything else lets make sure that the plugin is not disabled
	cvarEnabled = CreateConVar("sm_bot_tools_enable", "1", "Enables the Bot Tools plugin");
	if(!GetConVarBool(cvarEnabled))
		SetFailState("Plugin Disabled");

	// create other cvars
	CreateConVar("sm_bot_tools_version", PLUGIN_VERSION, "Bot Tools Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarBotCount = CreateConVar("sm_bot_tools_bot_count", "4", "The default number of bots.  Only used when bots are re-enabled");
	cvarAutoSlay = CreateConVar("sm_bot_tools_autoslay", "1", "Turns autoslay on and off");

	// Get handles to all the bot cvar's
	cvarChatter = FindConVar("bot_chatter");
	cvarDefer = FindConVar("bot_defer_to_human");
	cvarDifficulty = FindConVar("bot_difficulty");
	cvarQuota = FindConVar("bot_quota");
	cvarQuotaMode = FindConVar("bot_quota_mode");
	cvarAutoFollow = FindConVar("bot_auto_follow");
	cvarAllowRogues = FindConVar("bot_allow_rogues");
	cvarAllowMGS = FindConVar("bot_allow_machine_guns");
	cvarAllowPistols = FindConVar("bot_allow_pistols");
	cvarAllowRifles = FindConVar("bot_allow_rifles");
	cvarAllowShotguns = FindConVar("bot_allow_shotguns");
	cvarAllowSMGS = FindConVar("bot_allow_sub_machine_guns");
	cvarAllowSnipers = FindConVar("bot_allow_snipers");

	// Load translations from the translations file
	LoadTranslations("plugin.bottools");

	// Set iLifeState, hook events and register commands
	iLifeState = FindSendPropOffs("CBasePlayer", "m_lifeState");
	HookEvent("player_death", EventPlayerDeath, EventHookMode_PostNoCopy);
	RegAdminCmd("botslay", CommandBotSlay, ADMFLAG_SLAY);
	RegAdminCmd("bottools", PanelMainMenu, ADMFLAG_CONVARS);
}

// The death event
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If autoslay is not on there is no reason to process EventPlayerDeath
	if(!GetConVarBool(cvarAutoSlay))
		return;
	
	new aliveHuman = false;
	new playersConnected = GetMaxClients();
	for (new i = 1; i < playersConnected; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && IsAlive(i)) {
			aliveHuman = true;
			break;
		}
	}
	if(!aliveHuman)
		CommandBotSlay(0, 0);
}

// This function was originally from ferret's teambet plugin
public bool:IsAlive(client)
{
    if(iLifeState != -1 && GetEntData(client, iLifeState, 1) == 0)
        return true;
 
    return false;
}

//  This command slays all the bots
public Action:CommandBotSlay(client, args)
{
	ServerCommand("bot_kill");
			
	return Plugin_Handled;
}

//  Main menu handler
public PanelHandlerMainMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		switch(param2)
		{
			case 1:
				BotPower();
			case 2:
				PanelGeneralManagement(param1);
			case 3:
				PanelControlCommands(param1);
			case 4:
				PanelWeaponCommands(param1);
			case 5:
				PanelWeaponRestrictions(param1);
			case 6:
				PanelChatter(param1);
			case 7:
				PanelOther(param1);
		}
	}
}
 
//  The main menu
public Action:PanelMainMenu(client, args)
{
	new Handle:panel = CreatePanel();
	decl String:buffer[100];
	Format(buffer, sizeof(buffer), "Bot Tools:%T", "main menu", client);
	SetPanelTitle(panel, buffer);
	if(GetConVarInt(cvarQuota))
		Format(buffer, sizeof(buffer), "%T", "disable bots", client);
	else
		Format(buffer, sizeof(buffer), "%T", "enable bots", client);
	DrawPanelItem(panel, buffer);
	Format(buffer, sizeof(buffer), "%T", "general management menu", client);
	DrawPanelItem(panel, buffer);
	Format(buffer, sizeof(buffer), "%T", "control commands menu", client);
	DrawPanelItem(panel, buffer);
	Format(buffer, sizeof(buffer), "%T", "weapon commands menu", client);
	DrawPanelItem(panel, buffer);
	Format(buffer, sizeof(buffer), "%T", "weapon restrictions menu", client);
	DrawPanelItem(panel, buffer);
	Format(buffer, sizeof(buffer), "%T", "bot chatter menu", client);
	DrawPanelItem(panel, buffer);
	Format(buffer, sizeof(buffer), "%T", "other options menu", client);
	DrawPanelItem(panel, buffer);
	Format(buffer, sizeof(buffer), "%T", "exit", client);
	DrawPanelItem(panel, buffer);

	SendPanelToClient(panel, client, PanelHandlerMainMenu, 20);
 
	CloseHandle(panel);
 
	return Plugin_Handled;
}

//  The general management menu
public PanelGeneralManagement(client)
{
	new Handle:subPanel = CreatePanel();
	decl String:buffer[100];
	
	Format(buffer, sizeof(buffer), "Bot Tools:%T", "general management menu", client);
	SetPanelTitle(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "increase skill level", client, GetConVarInt(cvarDifficulty));
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "decrease skill level", client, GetConVarInt(cvarDifficulty));
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "add bot", client, GetConVarInt(cvarQuota));
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "remove bot", client, GetConVarInt(cvarQuota));
	DrawPanelItem(subPanel, buffer);
	GetConVarString(cvarQuotaMode, buffer, sizeof(buffer));
	if(StrEqual(buffer, "fill"))
		Format(buffer, sizeof(buffer), "%T", "bot normal", client);
	else
		Format(buffer, sizeof(buffer), "%T", "bot fill", client);
	DrawPanelItem(subPanel, buffer);
	if(GetConVarBool(cvarAutoSlay))
		Format(buffer, sizeof(buffer), "%T", "disable autoslay", client);
	else
		Format(buffer, sizeof(buffer), "%T", "enable autoslay", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "back", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "exit", client);
	DrawPanelItem(subPanel, buffer);

	SendPanelToClient(subPanel, client, PanelHandlerGeneralManagement, 20);
 
	CloseHandle(subPanel);
}

//  General management menu handler
public PanelHandlerGeneralManagement(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:buffer[100];
	if (action == MenuAction_Select) {
		switch(param2)
		{
			// Increase skill level
			case 1: {
				if(GetConVarInt(cvarDifficulty) < 3)
					SetConVarInt(cvarDifficulty, GetConVarInt(cvarDifficulty) + 1, true, true);
			}
			// Decrease skill level
			case 2: {
				if(GetConVarInt(cvarDifficulty) > 0)
					SetConVarInt(cvarDifficulty, GetConVarInt(cvarDifficulty) - 1, true, true);
			}
			// Increase the number of bots
			case 3: {
				SetConVarInt(cvarQuota, GetConVarInt(cvarQuota) + 1, true, true);
			}
			// Decrease the number of bots
			case 4: {
				if(GetConVarInt(cvarQuota) > 0)
					SetConVarInt(cvarQuota, GetConVarInt(cvarQuota) - 1, true, true);
			}
			// Bot fill/normal mode
			case 5: {
				GetConVarString(cvarQuotaMode, buffer, sizeof(buffer));
				if(StrEqual(buffer, "fill"))
					SetConVarString(cvarQuotaMode, "normal", true, true);
				else
					SetConVarString(cvarQuotaMode, "fill", true, true);
			}
			// Enable/disable autoslay
			case 6: {
				SetConVarBool(cvarAutoSlay, FlipBool(GetConVarBool(cvarAutoSlay)), true, true);
			}
			// Back
			case 7: {
				PanelMainMenu(param1, 0);
				return;
			}
			// Exit
			case 8: {
				return;
			}
		}
		PanelGeneralManagement(param1);
	}
}
 
public BotPower()
{
	if(GetConVarInt(cvarQuota))
		SetConVarInt(cvarQuota, 0, true, true);
	else
		SetConVarInt(cvarQuota, GetConVarInt(cvarBotCount), true, true);
}

public PanelControlCommands(client)
{
	new Handle:subPanel = CreatePanel();
	decl String:buffer[100];
	
	Format(buffer, sizeof(buffer), "Bot Tools:%T", "control commands menu", client);
	SetPanelTitle(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "slay all", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "rebalance all", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "back", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "exit", client);
	DrawPanelItem(subPanel, buffer);

	SendPanelToClient(subPanel, client, PanelHandlerControlCommands, 20);
 
	CloseHandle(subPanel);
}

//  Control Commands menu handler
public PanelHandlerControlCommands(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		switch(param2)
		{
			// slay bots
			case 1: {
				CommandBotSlay(0, 0);
			}
			// rebalance bots
			case 2: {
				ServerCommand("bot_kick");
				ServerCommand("bot_quota %i", GetConVarInt(cvarQuota));
			}
			// back
			case 3: {
				PanelMainMenu(param1, 0);
				return;
			}
			// exit
			case 4: {
				return;
			}
		}
		PanelControlCommands(param1);
	}
}
 
public PanelWeaponCommands(client)
{
	decl String:buffer[100];
	new Handle:subPanel = CreatePanel();
	
	Format(buffer, sizeof(buffer), "Bot Tools:%T", "weapon commands menu", client);
	SetPanelTitle(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "use all weapons", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "knives only", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "pistols only", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "snipers only", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "back", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "exit", client);
	DrawPanelItem(subPanel, buffer);

	SendPanelToClient(subPanel, client, PanelHandlerWeaponCommands, 20);
 
	CloseHandle(subPanel);
}

//  Weapon Commands menu handler
public PanelHandlerWeaponCommands(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		switch(param2)
		{
			case 1:
				ServerCommand("bot_all_weapons");
			case 2:
				ServerCommand("bot_knives_only");
			case 3:
				ServerCommand("bot_pistols_only");
			case 4:
				ServerCommand("bot_snipers_only");
			case 5: {
				PanelMainMenu(param1, 0);
				return;
			}
			case 6:
				return;
		}
		PanelWeaponCommands(param1);
	}
}

// Weapon restrictions menu
public PanelWeaponRestrictions(client)
{
	decl String:buffer[100];
	new Handle:subPanel = CreatePanel();
	Format(buffer, sizeof(buffer), "Bot Tools:%T", "weapon restrictions menu", client);
	SetPanelTitle(subPanel, buffer);
	if(GetConVarBool(cvarAllowPistols))
		Format(buffer, sizeof(buffer), "%T*", "allow pistols", client);
	else
		Format(buffer, sizeof(buffer), "%T", "allow pistols", client);
	DrawPanelItem(subPanel, buffer);
	if(GetConVarBool(cvarAllowSMGS))
		Format(buffer, sizeof(buffer), "%T*", "allow smgs", client);
	else
		Format(buffer, sizeof(buffer), "%T", "allow smgs", client);
	DrawPanelItem(subPanel, buffer);
	if(GetConVarBool(cvarAllowShotguns))
		Format(buffer, sizeof(buffer), "%T*", "allow shotguns", client);
	else
		Format(buffer, sizeof(buffer), "%T", "allow shotguns", client);
	DrawPanelItem(subPanel, buffer);
	if(GetConVarBool(cvarAllowRifles))
		Format(buffer, sizeof(buffer), "%T*", "allow rifles", client);
	else
		Format(buffer, sizeof(buffer), "%T", "allow rifles", client);
	DrawPanelItem(subPanel, buffer);
	if(GetConVarBool(cvarAllowMGS))
		Format(buffer, sizeof(buffer), "%T*", "allow mgs", client);
	else
		Format(buffer, sizeof(buffer), "%T", "allow mgs", client);
	DrawPanelItem(subPanel, buffer);
	if(GetConVarBool(cvarAllowSnipers))
		Format(buffer, sizeof(buffer), "%T*", "allow snipers", client);
	else
		Format(buffer, sizeof(buffer), "%T", "allow snipers", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "back", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "exit", client);
	DrawPanelItem(subPanel, buffer);

	SendPanelToClient(subPanel, client, PanelHandlerWeaponRestrictions, 20);
 
	CloseHandle(subPanel);
}

//  Weapon Restrictions menu handler
public PanelHandlerWeaponRestrictions(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		switch(param2)
		{
			// pistols
			case 1:
				SetConVarBool(cvarAllowPistols, FlipBool(GetConVarBool(cvarAllowPistols)), true, true);
			// sub machine guns
			case 2:
				SetConVarBool(cvarAllowSMGS, FlipBool(GetConVarBool(cvarAllowSMGS)), true, true);
			// shotguns
			case 3:
				SetConVarBool(cvarAllowShotguns, FlipBool(GetConVarBool(cvarAllowShotguns)), true, true);
			// rifles
			case 4:
				SetConVarBool(cvarAllowRifles, FlipBool(GetConVarBool(cvarAllowRifles)), true, true);
			// machine guns
			case 5:
				SetConVarBool(cvarAllowMGS, FlipBool(GetConVarBool(cvarAllowMGS)), true, true);
			// snipers
			case 6:
				SetConVarBool(cvarAllowSnipers, FlipBool(GetConVarBool(cvarAllowSnipers)), true, true);
			// back
			case 7: {
				PanelMainMenu(param1, 0);
				return;
			}
			// exit
			case 8:
				return;
		}
		PanelWeaponRestrictions(param1);
	}
}

// The other bot options menu
public PanelOther(client)
{
	decl String:buffer[100];
	new Handle:subPanel = CreatePanel();
	Format(buffer, sizeof(buffer), "Bot Tools:%T", "other options menu", client);
	SetPanelTitle(subPanel, buffer);
	if(GetConVarBool(cvarDefer))
		Format(buffer, sizeof(buffer), "%T", "defer off", client);
	else
		Format(buffer, sizeof(buffer), "%T", "defer on", client);
	DrawPanelItem(subPanel, buffer);
	if(GetConVarBool(cvarAllowRogues))
		Format(buffer, sizeof(buffer), "%T", "rogue off", client);
	else
		Format(buffer, sizeof(buffer), "%T", "rogue on", client);
	DrawPanelItem(subPanel, buffer);
	if(GetConVarBool(cvarAutoFollow))
		Format(buffer, sizeof(buffer), "%T", "follow off", client);
	else
		Format(buffer, sizeof(buffer), "%T", "follow on", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "back", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "exit", client);
	DrawPanelItem(subPanel, buffer);

	SendPanelToClient(subPanel, client, PanelHandlerOther, 20);
 
	CloseHandle(subPanel);
}

//  Other menu handler
public PanelHandlerOther(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		switch(param2)
		{
			// defer
			case 1:
				SetConVarBool(cvarDefer, FlipBool(GetConVarBool(cvarDefer)), true, true);
			// allow rogue
			case 2:
				SetConVarBool(cvarAllowRogues, FlipBool(GetConVarBool(cvarAllowRogues)), true, true);
			// auto follow
			case 3:
				SetConVarBool(cvarAutoFollow, FlipBool(GetConVarBool(cvarAutoFollow)), true, true);
			// back
			case 4: {
				PanelMainMenu(param1, 0);
				return;
			}
			// exit
			case 5:
				return;
		}
		PanelOther(param1);
	}
}


// Flips a bool
public bool:FlipBool(bool:current)
{
	if(current)
		return false;
	else
		return true;
}

// Bot chatter menu
public PanelChatter(client)
{
	decl String:buffer[100];
	decl String:chatter[10];
	
	GetConVarString(cvarChatter, chatter, sizeof(chatter));
	new Handle:subPanel = CreatePanel();
	Format(buffer, sizeof(buffer), "Bot Tools:%T", "bot chatter menu", client);
	SetPanelTitle(subPanel, buffer);
	if(StrEqual(chatter, "off"))
		Format(buffer, sizeof(buffer), "%T*", "chatter off", client);
	else
		Format(buffer, sizeof(buffer), "%T", "chatter off", client);
	DrawPanelItem(subPanel, buffer);
	if(StrEqual(chatter, "radio"))
		Format(buffer, sizeof(buffer), "%T*", "chatter radio", client);
	else
		Format(buffer, sizeof(buffer), "%T", "chatter radio", client);
	DrawPanelItem(subPanel, buffer);
	if(StrEqual(chatter, "minimal"))
		Format(buffer, sizeof(buffer), "%T*", "chatter minimal", client);
	else
		Format(buffer, sizeof(buffer), "%T", "chatter minimal", client);
	DrawPanelItem(subPanel, buffer);
	if(StrEqual(chatter, "normal"))
		Format(buffer, sizeof(buffer), "%T*", "chatter normal", client);
	else
		Format(buffer, sizeof(buffer), "%T", "chatter normal", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "back", client);
	DrawPanelItem(subPanel, buffer);
	Format(buffer, sizeof(buffer), "%T", "exit", client);
	DrawPanelItem(subPanel, buffer);

	SendPanelToClient(subPanel, client, PanelHandlerChatter, 20);
 
	CloseHandle(subPanel);
}

//  Bot chatter menu handler
public PanelHandlerChatter(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		switch(param2)
		{
			// off
			case 1:
				SetConVarString(cvarChatter, "off", true, true);
			// radio
			case 2:
				SetConVarString(cvarChatter, "radio", true, true);
			// minimal
			case 3:
				SetConVarString(cvarChatter, "minimal", true, true);
			// normal
			case 4:
				SetConVarString(cvarChatter, "normal", true, true);
			// back
			case 5: {
				PanelMainMenu(param1, 0);
				return;
			}
			// exit
			case 6:
				return;
		}
		PanelChatter(param1);
	}
}
