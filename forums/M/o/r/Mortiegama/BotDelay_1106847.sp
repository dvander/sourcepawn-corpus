#include <sourcemod>
#pragma semicolon 1

#define DELAY_ROUND
#define PLUGIN_VERSION "1.21"

new bool:isBotDelay = false;
new bool:isBotAutoStart = false;
new bool:isDelay = false;
new bool:isBotDelayed = false;
new bool:isAutoStarted = false;

new Handle:cvarBotDelay;
new Handle:cvarBotDelayTime;
new Handle:cvarBotAutoStart;
new Handle:cvarBotAutoStartTime;
new Handle:BotDelayTimeout;
new Handle:AutoStartTimeout;

public Plugin:myinfo = 
{
	name = "[L4D2] Delay Round",
	author = "Mortiegama, Thraka, mi123645",
	description = "Delays the start of the match so everyone can load properly before the game starts.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	cvarBotDelay = CreateConVar("l4d_bd_botdelay", "1", "Delays the Survivor Bots from starting before the players load. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBotDelayTime = CreateConVar("l4d_bd_botdelaytime", "30", "How long after a player is in the game will the Bots start. (Def 30)", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarBotAutoStart = CreateConVar("l4d_bd_botautostart", "1", "Should the Bots automatically start if no player is present. (Def 1)", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarBotAutoStartTime = CreateConVar("l4d_bd_botautostarttime", "120", "How long after a match begins should the Bots start if no player is present. (Def 120)", FCVAR_PLUGIN, true, 1.0, false, _);

	HookEvent("item_pickup", Event_ItemPickup);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);

	if (GetConVarInt(cvarBotDelay))
	{
		isBotDelay = true;
		isDelay = true;
		SetConVarInt(FindConVar("sb_stop"), 1);
	}

	if (GetConVarInt(cvarBotAutoStart))
	{
		isBotAutoStart = true;
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarInt(FindConVar("sb_stop"), 1);
	isBotDelayed = false;
	isAutoStarted = false;
	isDelay = true;
}

public Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (isBotDelay && IsFakeClient(client) && isBotAutoStart)
	{
		BotAutoStart();
	}

	if (isBotDelay && !IsFakeClient(client))
	{
		BotDelay();
	}
}

public BotAutoStart()
{
	if (!isAutoStarted)
	{
	new time = GetConVarInt(cvarBotAutoStartTime);
	AutoStartTimeout = CreateTimer(GetConVarFloat(cvarBotAutoStartTime), BotAutoStartTimer);
	isAutoStarted = true;
	}
}

public Action:BotAutoStartTimer(Handle:timer)
{
	if (isDelay)
	{
		SetConVarInt(FindConVar("sb_stop"), 0);
		isDelay = false;
	}
} 

public BotDelay()
{
	if (!isBotDelayed)
	{
	new time = GetConVarInt(cvarBotDelayTime);
	PrintToChatAll("The Bots are frozen for %i seconds.", time);
	BotDelayTimeout = CreateTimer(GetConVarFloat(cvarBotDelayTime), BotDelayTimer);
	isBotDelayed = true;
	}
}

public Action:BotDelayTimer(Handle:timer)
{
	if (isDelay)
	{
		SetConVarInt(FindConVar("sb_stop"), 0);
		isDelay = false;
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarInt(FindConVar("sb_stop"), 1);
	
	if (AutoStartTimeout != INVALID_HANDLE)
	{
 		CloseHandle(AutoStartTimeout);
		AutoStartTimeout = INVALID_HANDLE;
	}

	if (BotDelayTimeout != INVALID_HANDLE)
	{
 		CloseHandle(BotDelayTimeout);
		BotDelayTimeout = INVALID_HANDLE;
	}
}