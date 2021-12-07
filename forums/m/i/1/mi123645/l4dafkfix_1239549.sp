#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"
#define DEBUG 0
#define TEAM_SURVIVORS 2

// Bools
new bool:PlayerWentAFK[MAXPLAYERS+1];
new bool:g_bL4DVersion;

// Variables
new SurvivorCharacter[MAXPLAYERS+1];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Checks to see if the game is a L4D game. If it is, check if its the sequel. L4DVersion is L4D if false, L4D2 if true.
	decl String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if(StrContains(GameName, "left4dead", false) == -1)
		return APLRes_Failure;
	else if(StrEqual(GameName, "left4dead2", false))
		g_bL4DVersion = true;
	
	return APLRes_Success;
}

public Plugin:myinfo = 
{
	name = "[L4D(2)] 4+ Survivor Afk Fix",
	author = "MI 5, SwiftReal",
	description = "Fixes issue where player does not go IDLE on a bot in 4+ survivors games",
	version = PLUGIN_VERSION,
	url = "N/A"
}


public OnPluginStart()
{
	// Register a version cvar
	CreateConVar("l4dafkfix_version", PLUGIN_VERSION, "Version of L4D 4+ Survivor AFK Fix", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(FindConVar("l4dafkfix_version"), PLUGIN_VERSION);
	
	RegConsoleCmd("sm_idle", GoAwayFromKeyboard, "Take a break and spectate own survivor bot");
	RegConsoleCmd("sm_afk", GoAwayFromKeyboard, "Take a break and spectate own survivor bot");
	
	// Hook the player_bot_replace event and player_afk event
	HookEvent("player_afk", Event_PlayerWentAFK, EventHookMode_Pre);
	HookEvent("player_bot_replace", Event_BotReplacedPlayer);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnded, EventHookMode_Pre);
	HookEvent("bot_player_replace", Event_PlayerReplacedBot);
}

public Action:GoAwayFromKeyboard(client, args)
{
	FakeClientCommand(client, "go_away_from_keyboard");
	return Plugin_Handled;
}

public Action:Event_PlayerWentAFK(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Event is triggered when a player goes AFK
	
	#if DEBUG
	PrintToChatAll("Player went AFK");
	#endif
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	PlayerWentAFK[client] = true;
	SurvivorCharacter[client] = GetEntProp(client, Prop_Send, "m_survivorCharacter");
}

public Action:Event_BotReplacedPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Event is triggered when a bot takes over a player    
	#if DEBUG
	PrintToChatAll("Bot Replaced Player");
	#endif
	
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	
	// Create a datapack as we are moving 2+ pieces of data through a timer
	if(GetClientTeam(bot)==TEAM_SURVIVORS)
	{
		if(client)
		{
			if(IsClientConnected(client) && IsClientInGame(client))
			{
				SurvivorCharacter[bot] = SurvivorCharacter[client];
				
				if(g_bL4DVersion)
					SetSurvivorCharacter(bot);
				else
				SetSurvivorCharacterL4D1(bot);
				
				new Handle:datapack = CreateDataPack();
				WritePackCell(datapack, client);
				WritePackCell(datapack, bot);   
				CreateTimer(0.5, Timer_ActivateFix, datapack, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:Event_PlayerReplacedBot(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Event is triggered when a player takes over a bot
	#if DEBUG
	PrintToChatAll("Player replaced bot");
	#endif
	
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	
	if(client)
	{
		if(IsClientConnected(client))
		{
			if(IsClientInGame(client))
			{
				if(GetClientTeam(client) == TEAM_SURVIVORS)
				{
					if(g_bL4DVersion)
						SetSurvivorCharacter(client);
					else
					SetSurvivorCharacterL4D1(client);
				}
			}
		}
	}
	
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Event is triggered when a player dies
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client) return;
	if(!IsClientInGame(client)) return;
	
	// If the client is a bot and has a player idle on it, force the player to take over the bot
	if(IsFakeClient(client) && GetClientTeam(client)==TEAM_SURVIVORS && HasIdlePlayer(client))
	{
		new idleplayer = FindidOfIdlePlayer(client);
		if(idleplayer != 0)
			TakeOverBot(idleplayer, client);
	}
}

public Action:Timer_ActivateFix(Handle:Timer, any:datapack)
{
	// Reset the data pack
	ResetPack(datapack);
	
	// Retrieve values from datapack
	new client = ReadPackCell(datapack);
	new bot = ReadPackCell(datapack);
	
	// Check to see if the player successfully went AFK, and if the player did, forget this plugin
	if(IsClientIdle(client, bot))
	{
		PlayerWentAFK[client] = false;
		return;
	}
	
	// If the player went AFK and failed, continue on
	if(PlayerWentAFK[client])
	{
		PlayerWentAFK[client] = false;
		SetHumanIdle(client, bot);
	}
}

stock SetHumanIdle(client, bot)
{
	#if DEBUG
	PrintToChatAll("Player went idle");
	#endif
	
	static Handle:hSpec;
	if(hSpec == INVALID_HANDLE)
	{
		new Handle:hGameConf;
		
		hGameConf = LoadGameConfigFile("l4dafkfix");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSpec = EndPrepSDKCall();
	}
	SDKCall(hSpec, bot, client);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 5);
	if(g_bL4DVersion)
		SetSurvivorCharacter(bot);
	else
	SetSurvivorCharacterL4D1(bot);
	return;
}

stock TakeOverBot(client, bot)
{
	#if DEBUG
	PrintToChatAll("Taking over bot because it died");
	#endif
	
	static Handle:hSpec;
	if(hSpec == INVALID_HANDLE)
	{
		new Handle:hGameConf;
		
		hGameConf = LoadGameConfigFile("l4dafkfix");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSpec = EndPrepSDKCall();
	}
	
	static Handle:hSwitch;
	if(hSwitch == INVALID_HANDLE)
	{
		new Handle:hGameConf;
		
		hGameConf = LoadGameConfigFile("l4dafkfix");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hSwitch = EndPrepSDKCall();
	}
	
	SDKCall(hSpec, bot, client);
	SDKCall(hSwitch, client, true);
	if(g_bL4DVersion)
		SetSurvivorCharacter(client);
	else
	SetSurvivorCharacterL4D1(client);
	return;
}

public OnClientPutInServer(client)
{
	SurvivorCharacter[client] = -1;
}

public Action:Event_RoundEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i >= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i) && IsAlive(i) && HasIdlePlayer(i))
			TakeOverBot(FindidOfIdlePlayer(i), i);
	}
}

public OnMapEnd()
{
	for(new i = 1; i >= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i) && IsAlive(i) && HasIdlePlayer(i))
			TakeOverBot(FindidOfIdlePlayer(i), i);
	}
}

public OnClientDisconnect(client)
{
	// Reset the arrays on the client when the client disconnects
	PlayerWentAFK[client] = false;
	SurvivorCharacter[client] = -1;
}

stock bool:IsClientIdle(client, bot)
{
	// Taken from cigs code
	
	if(IsValidEntity(bot))
	{
		new spectator_userid = GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID");
		new spectator_client = GetClientOfUserId(spectator_userid);
		
		if(spectator_client == client)
			return true;
	}
	return false;
} 

stock bool:HasIdlePlayer(bot)
{
	// Taken from cigs code
	
	new userid = GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID");
	new client = GetClientOfUserId(userid);
	
	if(client)
	{
		// Do not count bots
		// Do not count 3rd person view players
		if(IsClientInGame(client) && !IsFakeClient(client) && (GetClientTeam(client) != TEAM_SURVIVORS))
			return true;
	}       
	return false;
}

stock bool:IsAlive(client)
{
	if(!GetEntProp(client, Prop_Send, "m_lifeState"))
		return true;
	
	return false;
}

stock FindidOfIdlePlayer(bot)
{
	// Taken from cigs code
	
	new userid = GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID");
	new client = GetClientOfUserId(userid);
	
	if(client)
	{
		// Do not count bots
		// Do not count 3rd person view players
		if(IsClientInGame(client) && !IsFakeClient(client) && (GetClientTeam(client) != TEAM_SURVIVORS))
			return client;
	}       
	
	#if DEBUG
	PrintToChatAll("Unable to find an idle player");
	#endif
	return 0;
}

stock SetSurvivorCharacter(client)
{
	switch(SurvivorCharacter[client])
	{
		case 0: // Nick
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 0);
			SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
		}
		case 1: // Rochelle
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 1);
			SetEntityModel(client, "models/survivors/survivor_producer.mdl");
		}
		case 2: // Coach
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 2);
			SetEntityModel(client, "models/survivors/survivor_coach.mdl");
		}
		case 3: // Ellis
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 3);
			SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
		}
		case 4: // Bill
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 4);
			SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
		}
		case 5: // Zoey
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 5);
			SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
		}
		case 6: // Francis
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 6);
			SetEntityModel(client, "models/survivors/survivor_biker.mdl");
		}
		case 7: // Louis
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 7);
			SetEntityModel(client, "models/survivors/survivor_manager.mdl");
		}
	}
}

stock SetSurvivorCharacterL4D1(client)
{
	switch(SurvivorCharacter[client])
	{
		case 0: // Bill
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 0);
			SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
		}
		case 1: // Zoey
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 1);
			SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
		}
		case 2: // Francis
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 2);
			SetEntityModel(client, "models/survivors/survivor_biker.mdl");
		}
		case 3: // Louis
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 3);
			SetEntityModel(client, "models/survivors/survivor_manager.mdl");
		}
	}
}

///////////////////////////////////////////////////////////