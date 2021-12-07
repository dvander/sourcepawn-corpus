#define PLUGIN_VERSION		"1.0.0"

#define TEST_DEBUG								1
#define TEST_DEBUG_LOG						 	2

#define CVAR_FLAGS          FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "Infinite Panic",
	author = "AtomicStryker",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

static Handle:cvarDebugMode			= INVALID_HANDLE;
static Handle:cvarGameModeActive	= INVALID_HANDLE;
static bool:isAllowedGameMode		= false;
static bool:timerStarted			= false;

public OnPluginStart()
{
	cvarGameModeActive =	CreateConVar("l4d2_infinitepanic_gamemodesactive",
							"coop,versus,teamversus,realism,mutation19",
							" Set the gamemodes for which the plugin should be activated (same usage as sv_gametypes, i.e. add all game modes where you want it active separated by comma) ",
							CVAR_FLAGS);
							
	cvarDebugMode = CreateConVar("l4d2_infinitepanic_debugmode", "3", " 0 = off, 1 = Chat, 2 = Logfile, 3 = special ", CVAR_FLAGS);
	
	HookConVarChange(FindConVar("mp_gamemode"), GameModeChanged);
	CheckGamemode();
	
	HookEvent("round_end", RoundEnd);
	HookEvent("player_left_start_area", EventPlayerLeftStartArea);
}

public GameModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CheckGamemode();
}

static CheckGamemode()
{
	decl String:gamemode[PLATFORM_MAX_PATH];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	decl String:convarsetting[PLATFORM_MAX_PATH];
	GetConVarString(cvarGameModeActive, convarsetting, sizeof(convarsetting));
	
	isAllowedGameMode = ListContainsString(convarsetting, ",", gamemode);
	
	DebugPrintToAll("Gamemode Check ran, enabled = %s", (isAllowedGameMode ? "yes" : "no"));
}

stock bool:ListContainsString(const String:list[], const String:separator[], const String:string[])
{
	decl String:buffer[64][15];
	
	new count = ExplodeString(list, separator, buffer, 14, sizeof(buffer));
	for (new i = 0; i < count; i++)
	{
		if (StrEqual(string, buffer[i], false))
		{
			return true;
		}
	}
	
	return false;
}

public EventPlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
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

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	DebugPrintToAll("Round End");
	timerStarted = false;
	isAllowedGameMode = false;
}

stock bool:AreHumansIngame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			return true;
	}
	
	return false;
}

stock CheatCommand(client = 0, String:command[], String:arguments[]="")
{
	if (!client || !IsClientInGame(client))
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				client = target;
				break;
			}
		}
		
		if (!client || !IsClientInGame(client)) return;
	}
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

DebugPrintToAll(const String:format[], any:...)
{
	if (GetConVarBool(cvarDebugMode))
	{
		decl String:buffer[192];
		
		VFormat(buffer, sizeof(buffer), format, 2);
		
		if (GetConVarInt(cvarDebugMode) == TEST_DEBUG)
		{
			PrintToChatAll("[TANKENFORCE] %s", buffer);
			PrintToConsole(0, "[TANKENFORCE] %s", buffer);
		}
		
		else if (GetConVarInt(cvarDebugMode) == TEST_DEBUG_LOG)
			LogMessage("%s", buffer);
			
		else
		{
			decl String:authid[64];
			for (new target = 1; target <= MaxClients; target++)
			{
				if (IsClientInGame(target)
				&& !IsFakeClient(target))
				{
					GetClientAuthString(target, authid, sizeof(authid));
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