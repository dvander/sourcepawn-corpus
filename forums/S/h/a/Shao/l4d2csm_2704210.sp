/********************************************************************************************
* Plugin	: [L4D2] Character Select Menu
* Version	: 1.4
* Game		: Left 4 Dead 2
* Author	: Patje
* Testers	: Myself
* Website	: N/A
* 
* 
* Purpose	: Allows players to change their in game character or model!
* 
* Version 1.4	
*		- added Equal, that allow all players to change ther model
*
* Version 1.3
* 		- Added a timer to the Gamemode ConVarHook to ensure compatitbilty with other gamemode changing plugins
* 		- Survivors can now become Infected and vice versa (Character or model) (L4D2 only)
* 		- Added Boomette (L4D2 only)
* 		- Added Uncommon infected (model only) (L4D2 only)
* 	    	- Fixed bug where the survivor menu would appear even if its turned off
* 
* Version 1.2
* 		- Redone tank health fix
* 		- Few optimizations here and there
* 
* Version 1.1
* 		- Added cvars: l4d_csm_infected_menu, l4d_csm_survivor_menu and l4d_csm_change_limit
* 		- Fixed bug where clients can access restricted parts of the menu
* 
* Version 1.0
* 		- Initial release.
* 
* 
**********************************************************************************************/

// define
#define PLUGIN_VERSION "1.3"
#define PLUGIN_NAME "[L4D2] Character Select Menu"
#define DEBUG 0
#pragma semicolon 1
#define TEAM_SPECTATOR		1
#define TEAM_SURVIVORS 		2

// includes
#include <sourcemod>
#include <sdktools>

// Cvar Handles
new Handle:g_hActivate;
new Handle:h_Equal;
new Handle:h_GameMode;
new Handle:g_hSurvivorMenu;
new Handle:g_hChangeLimit;

// Variables
new g_GameMode; // Used to determine the gamemode

// Arrays
new g_ChangeLimitPlayer[MAXPLAYERS+1];

// Bools
new bool:DoNotUseConVarHook;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "MI 5",
	description = "Allows survivors to change their in game character",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	
	// Register the version cvar
	CreateConVar("l4d2_csm_version", PLUGIN_VERSION, "Version of L4D2 Character Select Menu", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// convars
	
	// Equal Cvar
	h_Equal = CreateConVar("l4d2_csm_equal_mode", "1", "If 1, players will be able to change their character on the csm", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Activate Cvar
	g_hActivate = CreateConVar("l4d2_csm_enable", "1", "If 1, character select menu is activated", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Survivor Menu cvar
	g_hSurvivorMenu = CreateConVar("l4d2_csm_survivor_menu", "1", "If 1, Survivor Menu will be shown to players", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Change Limit cvar
	g_hChangeLimit = CreateConVar("l4d2_csm_change_limit", "9999", "Sets the amount of times a client can change their character", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
	HookConVarChange(g_hChangeLimit, ConVarChangeLimit);
	
	// Grab Gamemode value
	h_GameMode = FindConVar("mp_gamemode");
	HookConVarChange(h_GameMode, ConVarGameMode);
	
	// Hook Events
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	// config file
	AutoExecConfig(true, "l4d2csm");
	
	// sourcemod command
	RegConsoleCmd("sm_csm", PlayerMenuActivator);
}

public ConVarGameMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// If the plugin is changing the gamemode manually, don't execute this convar hook
	
	if (DoNotUseConVarHook)
		return;
	
	CreateTimer(2.0, GameModeCheck);
}

public ConVarChangeLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		g_ChangeLimitPlayer[i] = GetConVarInt(g_hChangeLimit);
	}
	
}

//public OnClientPutInServer(client)
//{
//	if (client)
//	{
//		if (GetConVarBool(g_hActivate))
//			CreateTimer(30.0, AnnounceCharSelect, client);
//	}
//}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, GameModeCheck);
	
	for (new i = 1; i <= MaxClients; i++) 
	{
		g_ChangeLimitPlayer[i] = GetConVarInt(g_hChangeLimit);
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// We get the client id
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// If client is valid
	if (client == 0) return Plugin_Continue;
	if (!IsClientConnected(client)) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Continue;
	
	g_ChangeLimitPlayer[client] = GetConVarInt(g_hChangeLimit);
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;
	
	g_ChangeLimitPlayer[client] = GetConVarInt(g_hChangeLimit);
}

public Action:GameModeCheck(Handle:timer)
{
	#if DEBUG
	LogMessage("Checking Gamemode");
	#endif
	//MI 5, We determine what the gamemode is
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		g_GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		g_GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		g_GameMode = 1;
}

public CharMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:item[256], String:display[256];
		
		GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));
		
		if (StrEqual(item, "nick"))
		{
			// get prop
			new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
			new charr = GetEntData(param1, offset, 1);
			
			// set char
			charr = 0;
			SetEntData(param1, offset, charr, 1, true);
			
			// update client model info
			decl String:model[] = "models/survivors/survivor_gambler.mdl";
			SetEntityModel(param1, model);
			
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Nick \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "rochelle"))
		{
			// get prop
			new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
			new charr = GetEntData(param1, offset, 1);
			
			// set char
			charr = 1;
			SetEntData(param1, offset, charr, 1, true);
			
			// update client model info
			decl String:model[] = "models/survivors/survivor_producer.mdl";
			SetEntityModel(param1, model);
			
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Rochelle \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "coach"))
		{
			// get prop
			new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
			new charr = GetEntData(param1, offset, 1);
			
			// set char
			charr = 2;
			SetEntData(param1, offset, charr, 1, true);
			
			// update client model info
			decl String:model[] = "models/survivors/survivor_coach.mdl";
			SetEntityModel(param1, model);
			
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Coach \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "ellis"))
		{
			// get prop
			new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
			new charr = GetEntData(param1, offset, 1);
			
			// set char
			charr = 3;
			SetEntData(param1, offset, charr, 1, true);
			
			// update client model info
			decl String:model[] = "models/survivors/survivor_mechanic.mdl";
			SetEntityModel(param1, model);
			
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Ellis \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "bill"))
		{
			// get prop
			new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
			new charr = GetEntData(param1, offset, 1);
			
			// set char
			charr = 4;
			SetEntData(param1, offset, charr, 1, true);
			
			// update client model info
			decl String:model[] = "models/survivors/survivor_namvet.mdl";
			SetEntityModel(param1, model);
			
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Bill \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "zoey"))
		{
			// get prop
			new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
			new charr = GetEntData(param1, offset, 1);
			
			// set char
			charr = 5;
			SetEntData(param1, offset, charr, 1, true);
			
			// update client model info
			decl String:model[] = "models/survivors/survivor_teenangst.mdl";
			SetEntityModel(param1, model);
			
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Zoey \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "francis"))
		{
			// get prop
			new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
			new charr = GetEntData(param1, offset, 1);
			
			// set char
			charr = 6;
			SetEntData(param1, offset, charr, 1, true);
			
			// update client model info
			decl String:model[] = "models/survivors/survivor_biker.mdl";
			SetEntityModel(param1, model);
			
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Francis \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "louis"))
		{	
			// get prop
			new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
			new charr = GetEntData(param1, offset, 1);
			
			// set char
			charr = 7;
			SetEntData(param1, offset, charr, 1, true);
			
			// update client model info
			decl String:model[] = "models/survivors/survivor_manager.mdl";
			SetEntityModel(param1, model);
			
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Louis \x05]");
			g_ChangeLimitPlayer[param1]--;
		}

	} 
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:PlayerMenuActivator(client, args)
{
	if ((client) && (GetConVarBool(g_hActivate)))
	{
		CreateTimer(0.1, PlayerMenu, client);
	}
}

//public Action:AnnounceCharSelect(Handle:timer, any:client)
//{
//	if (IsClientInGame(client))
//	{
//		PrintHintText(client, "[SM] Character Select Menu: Type !csm in chat to select your character!");
//	}
//}

public Action:PlayerMenu(Handle:timer, any:client)
{
	
	new Handle:menu = CreateMenu(CharMenu);
	SetMenuTitle(menu, "Choose a character:");
	
	if (GetClientHealth(client) > 1)
	{
		if (GetConVarBool(h_Equal) && GetConVarBool(g_hSurvivorMenu) && g_ChangeLimitPlayer[client] >= 1 || GetUserFlagBits(client) != 0 && GetConVarBool(g_hSurvivorMenu) && g_ChangeLimitPlayer[client] >= 1)
		{
			AddMenuItem(menu, "nick", "Nick");
			AddMenuItem(menu, "rochelle", "Rochelle");
			AddMenuItem(menu, "coach", "Coach");
			AddMenuItem(menu, "ellis", "Ellis");
		}
		
		if (GetConVarBool(h_Equal) && GetConVarBool(g_hSurvivorMenu) && g_ChangeLimitPlayer[client] >= 1 || GetUserFlagBits(client) != 0 && GetConVarBool(g_hSurvivorMenu) && g_ChangeLimitPlayer[client] >= 1)
		{
			AddMenuItem(menu, "bill", "Bill");
			AddMenuItem(menu, "zoey", "Zoey");
			AddMenuItem(menu, "louis", "Louis");
			AddMenuItem(menu, "francis", "Francis");
		}
		
		if (g_ChangeLimitPlayer[client] < 1)
		{
			PrintHintText(client, "Sorry, you cannot change your character until you respawn.");
			return;
		}
		if (GetMenuItemCount(menu) == 0)
		{
			PrintHintText(client, "Sorry, there are no selections you can make at this time.");
			return;
		}
	}
	else
	{
		PrintHintText(client, "Sorry, you must be alive to use the Character Select Menu!");
		return;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 9999);
}

public GetAnyClient ()
{
	#if DEBUG
	LogMessage("[Character Select] Looking for any real client to fake command");
	#endif
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && (!IsFakeClient(i)))
		{
			return i;
		}
	}
	return 0;
}

public Action:kickbot(Handle:timer, any:value)
{
	KickThis(value);
}

KickThis (client)
{
	
	if (IsClientConnected(client) && (!IsClientInKickQueue(client)))
	{
		if (IsFakeClient(client)) KickClient(client,"Kick");
	}
}

////////////////
