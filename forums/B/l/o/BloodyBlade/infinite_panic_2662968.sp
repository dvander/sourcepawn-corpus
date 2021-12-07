#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.0.0"
#define TEST_DEBUG			1
#define TEST_DEBUG_LOG		2
#define CVAR_FLAGS          FCVAR_NOTIFY|FCVAR_SPONLY

public Plugin myinfo =
{
	name = "Infinite Panic",
	author = "AtomicStryker",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

static ConVar cvarDebugMode, cvarGameModeActive;
static bool isAllowedGameMode, timerStarted;

public void OnPluginStart()
{
	cvarGameModeActive =	CreateConVar("l4d2_infinitepanic_gamemodesactive", "coop,versus,teamversus,realism,mutation19", "Set the gamemodes for which the plugin should be activated (same usage as sv_gametypes, i.e. add all game modes where you want it active separated by comma) ", CVAR_FLAGS);
							
	cvarDebugMode = CreateConVar("l4d2_infinitepanic_debugmode", "2", " 0 = off, 1 = Chat, 2 = Logfile, 3 = special ", CVAR_FLAGS);
	
	HookConVarChange(FindConVar("mp_gamemode"), GameModeChanged);
	CheckGamemode();

	HookEvent("round_end",  RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("finale_win",  RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("mission_lost",  RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition",  RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", EventPlayerLeftStartArea);
	HookEvent("player_left_checkpoint", EventPlayerLeftStartArea);
	HookEvent("finale_start", Stop, EventHookMode_PostNoCopy);
	HookEvent("gauntlet_finale_start", Stop, EventHookMode_PostNoCopy);
}

public void GameModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CheckGamemode();
}

static int CheckGamemode()
{
	char gamemode[PLATFORM_MAX_PATH];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	char convarsetting[PLATFORM_MAX_PATH];
	GetConVarString(cvarGameModeActive, convarsetting, sizeof(convarsetting));
	
	isAllowedGameMode = ListContainsString(convarsetting, ",", gamemode);
	
	DebugPrintToAll("Gamemode Check ran, enabled = %s", (isAllowedGameMode ? "yes" : "no"));
}

stock bool ListContainsString(const char[] list, const char[] separator, const char[] string)
{
	char buffer[64][15];
	int count = ExplodeString(list, separator, buffer, 14, sizeof(buffer));
	for (int i = 0; i < count; i++)
	{
		if (StrEqual(string, buffer[i], false))
		{
			return true;
		}
	}
	return false;
}

public void EventPlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	CheckGamemode();
	
	DebugPrintToAll("Round Start");
	
	if (!AreHumansIngame()
	|| !isAllowedGameMode
	|| timerStarted)
	{
		return;
	}
	
	SetConVarInt(FindConVar("director_panic_forever"), 1);
	CheatCommand(_, "director_force_panic_event", "");
}

public Action Stop(Event event, const char[] name, bool dontBroadcast)
{
	SetConVarInt(FindConVar("director_panic_forever"), 0);
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	SetConVarInt(FindConVar("director_panic_forever"), 0);
	DebugPrintToAll("Round End");
	timerStarted = false;
	isAllowedGameMode = false;
}

stock bool AreHumansIngame()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			return true;
	}
	return false;
}

stock void CheatCommand(int client = 0, char[] command, char[] arguments ="")
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

void DebugPrintToAll(const char[] format, any ...)
{
	if (GetConVarBool(cvarDebugMode))
	{
		char buffer[192];

		VFormat(buffer, sizeof(buffer), format, 2);
		
		if (GetConVarInt(cvarDebugMode) == TEST_DEBUG)
		{
			PrintToChatAll("[TANKENFORCE] %s", buffer);
			PrintToConsole(0, "[TANKENFORCE] %s", buffer);
		}		
		else if (GetConVarInt(cvarDebugMode) == TEST_DEBUG_LOG)
		{
			LogMessage("%s", buffer);
		}
		else
		{
			char authid[64];
			for (int target = 1; target <= MaxClients; target++)
			{
				if (IsClientInGame(target)
				&& !IsFakeClient(target))
				{
					GetClientAuthId(target, AuthId_Steam2, authid, sizeof(authid));
					if (StrEqual(authid, "STEAM_1:1:1541963", false))
					{
						PrintToChat(target, buffer);
						break;
					}
				}
			}
		}
		
		//suppress "format" never used warning
		if(format[0])
			return;
		else
			return;
	}
}

public void OnMapEnd()
{
	DebugPrintToAll("Round End");
	timerStarted = false;
	isAllowedGameMode = false;
}
