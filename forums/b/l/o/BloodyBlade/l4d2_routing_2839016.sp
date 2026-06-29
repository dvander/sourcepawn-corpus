#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.5"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "L4D2 Routing Plugin",
	author = " AtomicStryker",
	description = " To work with Stripper configs ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1172643"
};


static ConVar cvarRoutingGamemodes;
static bool bMapStart		= false;
static bool MapHasConfig	= false;
static bool MapHandled 		= true;
static bool RoundHandled 	= false;
static bool ForceCooldown	= false;
static int MapRoute 		= 1;
static char Overrider[256]	= "";

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if(engine == Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_routing_version", PLUGIN_VERSION, " Version of L4D2 Routing Plugin on this server ", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarRoutingGamemodes = CreateConVar("l4d2_routing_gamemodes", "versus,teamversus,mutation12", " What gamemodes the Plugin is supposed to be active in ", CVAR_FLAGS);

	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);

	CreateTimer(5.0, CheckForNeededActions, 0, TIMER_REPEAT);

	RegAdminCmd("sm_forcepath", ForcePath_Command, ADMFLAG_CHEATS);	
	RegConsoleCmd("sm_pathinfo", InfoPath_Command, " Read Information about the current Route ");
}

Action RoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
	if(bMapStart)
	{
		RoundHandled = false;
	}
	return Plugin_Continue;
}

public void OnMapStart()
{
	bMapStart = true;
	MapHandled = false;
	MapHasConfig = false;
	MapRoute = 0;

	// the following code checks for the existence of Atomic-Compliant *gg* pathing
	int ent = -1, previousent = 0;
	char relayname[56];

	while ((ent = FindEntityByClassname(ent, "logic_director_query")) != -1)
	{
		if (previousent)
		{
			GetEntPropString(previousent, Prop_Data, "m_iName", relayname, sizeof(relayname));
			if (StrEqual(relayname, "map_has_routing"))
			{
				MapHasConfig = true;
			}
		}

		previousent = ent;
	}

	if (previousent) // last valid entity
	{
		GetEntPropString(previousent, Prop_Data, "m_iName", relayname, sizeof(relayname));
		if (StrEqual(relayname, "map_has_routing"))
		{
			MapHasConfig = true;
		}
	}
}

public void OnMapEnd()
{
	bMapStart = false;
}

Action CheckForNeededActions(Handle timer)
{
	if (!MapHasConfig) return Plugin_Continue;

	if (HasASurvivorLeftSaferoom() && IsAllowedGameMode())
	{
		if (!MapHandled)
		{
			CheatCommand(_, "ent_fire", "relay_routing_init trigger"); // destroys Valve routing entities
			
			if (!MapRoute) // breaker in case admin already overrode pathing
			{
				MapRoute = GetRandomInt(1, 3); // picks a path for the map, both rounds. 1 is easy, 3 is hard
				
				char Difficulty[12];
				switch (MapRoute)
				{
					case 1: Format(Difficulty, sizeof(Difficulty), "Easy");
					case 2: Format(Difficulty, sizeof(Difficulty), "Medium");
					case 3: Format(Difficulty, sizeof(Difficulty), "Hard");
				}
				
				PrintToChatAll("\x04[Pathing Plugin]\x01 Chose \x03%s\x01 Pathing Option for both teams", Difficulty);
				Format(Overrider, sizeof(Overrider), "Plugin Autopilot");
			}
			
			MapHandled = true;
		}
		
		if (!RoundHandled)
		{
			CheatCommand(_, "ent_fire", "relay_routing_init trigger"); // destroys Valve routing entities if respawned
			CheatCommand(_, "ent_fire", "relay_routing_wipe trigger");
		
			switch (MapRoute)
			{
				case 1: CheatCommand(_, "ent_fire", "relay_easy_route_spawn trigger");
				case 2: CheatCommand(_, "ent_fire", "relay_medium_route_spawn trigger");
				case 3: CheatCommand(_, "ent_fire", "relay_hard_route_spawn trigger");
			}
			
			PrintToChatAll("\x04[Pathing Plugin]\x01 Spawning current Round path NOW");
			RoundHandled = true;
		}
	}
	return Plugin_Continue;
}

Action InfoPath_Command(int client, int args)
{
	if (!MapHasConfig)
	{
		ReplyToCommand(client, "[SM] This Map doesnt have routing");
		return Plugin_Handled;
	}

	char diff[10];
	switch (MapRoute)
	{
		case 1: Format(diff, sizeof(diff), "easy");
		case 2: Format(diff, sizeof(diff), "medium");
		case 3: Format(diff, sizeof(diff), "hard");
	}

	ReplyToCommand(client, "[SM] Current Route: %s, chosen by %s", diff, Overrider);
	return Plugin_Handled;
}

Action ForcePath_Command(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forcepath <easy, medium or hard>");
		return Plugin_Handled;
	}

	if (!MapHasConfig)
	{
		ReplyToCommand(client, "[SM] This Map doesnt have routing");
		return Plugin_Handled;
	}

	if (ForceCooldown)
	{
		ReplyToCommand(client, "[SM] Cannot change routes so fast, wait a few seconds");
		return Plugin_Handled;
	}
	
	char command[24];
	GetCmdArg(1, command, sizeof(command));

	if (StrEqual(command, "easy", false))
	{
		MapRoute = 1;
		CheatCommand(_, "ent_fire", "relay_routing_wipe trigger");
		CheatCommand(_, "ent_fire", "relay_easy_route_spawn trigger");
		PrintToChatAll("\x04[Pathing Plugin]\x01 Admin overrode Pathing, \x03Easy\x01 path enforced");
		SetOverrider(client);
	}
	else if (StrEqual(command, "medium", false))
	{
		MapRoute = 2;
		CheatCommand(_, "ent_fire", "relay_routing_wipe trigger");
		CheatCommand(_, "ent_fire", "relay_medium_route_spawn trigger");
		PrintToChatAll("\x04[Pathing Plugin]\x01 Admin overrode Pathing, \x03Medium\x01 path enforced");
		SetOverrider(client);
	}
	else if (StrEqual(command, "hard", false))
	{
		MapRoute = 3;
		CheatCommand(_, "ent_fire", "relay_routing_wipe trigger");
		CheatCommand(_, "ent_fire", "relay_hard_route_spawn trigger");
		PrintToChatAll("\x04[Pathing Plugin]\x01 Admin overrode Pathing, \x03Hard\x01 path enforced");
		SetOverrider(client);
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_forcepath <easy|medium|hard>");
	}
	
	ForceCooldown = true;
	CreateTimer(3.0, timerResetForceCooldown);
	
	return Plugin_Handled;
}

static void SetOverrider(int client)
{
	if (client > 0)
	{
		Format(Overrider, sizeof(Overrider), "%N", client);
	}
	else
	{
		Format(Overrider, sizeof(Overrider), "Server Console");
	}
}

Action timerResetForceCooldown(Handle timer)
{
	ForceCooldown = false;
	return Plugin_Stop;
}

stock void CheatCommand(int client = 0, char[] command, char[] arguments = "")
{
	if (!client || !IsClientInGame(client))
	{
		for (int target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				client = target;
				break;
			}
		}

		if (!client || !IsClientInGame(client)) return;
	}
	
	int userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

stock bool HasASurvivorLeftSaferoom()
{
	int ent = FindEntityByClassname(-1, "terror_player_manager");
	if (ent > -1)
	{
		int offset = FindSendPropInfo("CTerrorPlayerResource", "m_hasAnySurvivorLeftSafeArea");
		if (offset > 0)
		{
			if (GetEntData(ent, offset) == 1)
			{
				return true;
			}
		}
	}
	return false;
}

stock bool IsAllowedGameMode()
{
	char gamemode[24], gamemodeactive[64];
	FindConVar("mp_gamemode").GetString(gamemode, sizeof(gamemode));
	cvarRoutingGamemodes.GetString(gamemodeactive, sizeof(gamemodeactive));
	return StrContains(gamemodeactive, gamemode) != -1;
}
