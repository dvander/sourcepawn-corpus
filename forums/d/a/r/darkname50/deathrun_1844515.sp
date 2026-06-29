#include <tf2_stocks>
#include <tf2lib>
#include <morecolors> 

#define PLAYERCOND_SPYCLOAK (1<<4)

new changeteamallowed = false

public Plugin:myinfo =
{
	name = "[TF2] Deathrun",
	author = "Your Manager Urahara Kisuke",
	description = "Deathrun Gamemode for Team Fortress 2",
	version = "1.1.1",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("teamplay_round_start", event_RoundStart);
	HookEvent("arena_round_start", event_ArenaStart); 
	HookEvent("teamplay_round_win", event_RoundWin);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre); 
	HookEvent("player_spawn", player_spawn); 
	AddCommandListener(hook_JoinTeam, "jointeam");
	AddCommandListener(BlockCommand, "kill");
	AddCommandListener(BlockCommand, "explode"); 
	AddServerTag("deathrun");
}

public OnConfigsExecuted()
{
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0); 
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("mp_autoteambalance"), 0); 
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_scrambleteams_auto"), 0);
}

public OnMapStart()
{

	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("mp_autoteambalance"), 0); 
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_scrambleteams_auto"), 0);
}

public OnMapEnd()
{
	changeteamallowed = false
}

public OnGameFrame()
{
  handle_gameFrameLogic();
}

public player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	TF2_RemoveWeaponSlot(client, 3)
	TF2_RemoveWeaponSlot(client, 4)
	TF2_RemoveWeaponSlot(client, 5)
	new class = GetEventInt(event, "class");
	if (class == 1)
	{
		TF2_SetPlayerClass(client, TFClass_Sniper, true, true);
		TF2_RespawnPlayer(client);
	}
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
    {
        new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
        if (cond & PLAYERCOND_SPYCLOAK)
        {
           SetEntProp(client, Prop_Send, "m_nPlayerCond", cond | ~PLAYERCOND_SPYCLOAK);
        }
    }  
}

public Action:Event_PlayerTeam(Handle:event, const String:szEventName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEventBroadcast(event, true);
	CreateTimer(0.5, TeamMsg, client);
	return Plugin_Continue;
}  

public Action:TeamMsg(Handle:timer, any:client) 
{
	decl String:name[32];
	GetClientName(client, name, sizeof(name));
	if (client > 0 && client <= MaxClients)
	{
		if(GetClientTeam(client) == 1)
		{
		CPrintToChatAll("Player {olive}%s{DEFAULT} joined team {gray}Spectator", name);
		}
		else if(GetClientTeam(client) == 3)
		{
		CPrintToChatAll("Player {olive}%s{DEFAULT} has become {blue}Death", name);
		}
		else if(GetClientTeam(client) == 2)
		{
		CPrintToChatAll("Player {olive}%s{DEFAULT} joined team {red}Runners", name);
		}
	}
}

public Action:hook_JoinTeam(client, const String:command[], argc)
{
	if (!changeteamallowed)
	{
		if (GetClientTeam(client) == 1)
		{
		PrintToChat(client, "You change team to Spectator!"); // shows up message
		}
		else if (GetClientTeam(client) == 3)
		{
		PrintToChat(client, "You can't change team!"); // shows up message
		return Plugin_Handled
		}
		else if (GetClientTeam(client) == 2)
		{
		PrintToChat(client, "You can't change team!"); // shows up message
		return Plugin_Handled
		}
	}
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
  Format(gameDesc, sizeof(gameDesc), "Deathrun 1.1");
  return Plugin_Changed;
}

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) // When round starts random player gets moved into death team and player who was before death gets moved to runners team
{
	SecurityLevel1()
	changeteamallowed = false
	CreateTimer(1.0, moveplayers);
}

public Action:event_ArenaStart(Handle:event, const String:name[], bool:dontBroadcast) // When round starts random player gets moved into death team and player who was before death gets moved to runners team
{
	changeteamallowed = true
}

public Action:event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
changeteamallowed = true
}

public Action:SecurityLevel1()
{
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("mp_autoteambalance"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_scrambleteams_auto"), 0);
}

public Action:moveplayers(Handle:timer)
{
	CreateTimer(1.0, moveplayers2);
	for(new i = 1, iCount = 0; i <= MaxClients; i++)
	{
	ChangeClientTeam(i, 2);
	}
	new player = GetRandomPlayer(2);
	ChangeClientTeam(player, 3);
}

public Action:moveplayers2(Handle:timer)
{
	new player = GetRandomPlayer(2);
	ChangeClientTeam(player, 3);
}

//STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS 

/// Small userful thingy from cs:s deathrun manager made by Rogue plugin
public Action:BlockCommand(client, const String:command[], args) // Blocks use of commands USED FOR kill & explode things
{
	return Plugin_Handled; // blocks command 
}

/// Small userful thingy from cs:s deathrun manager made by Rogue plugin
stock GetRandomPlayer(team) 
{
    new clients[MaxClients+1], clientCount;
    for (new i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && (GetClientTeam(i) == team))
            clients[clientCount++] = i;
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

/// Stock Made by FlaminSarge from [TF2] Be the Horsemann
stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

handle_gameFrameLogic()
{
  // 1. Limit spy cloak to 1% of max.
  for(new i = 1; i <= MaxClients; i++)
  {
    if(IsClientInGame(i) && IsPlayerAlive(i))
    {
      if(GetCloak(i) > 1.0) 
        SetCloak(i, 1.0);
    }
  }
}