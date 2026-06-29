#include <sourcemod>
#include <multicolors>

#define PLUGIN_NEV	"skipstats"
#define PLUGIN_LERIAS	"https://forums.alliedmods.net/showthread.php?t=314123"
#define PLUGIN_AUTHOR	"Nexd"
#define PLUGIN_VERSION	"1.0"

ConVar restartgame;

public Plugin myinfo = 
{
	name = PLUGIN_NEV,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_LERIAS,
	version = PLUGIN_VERSION
};

public void OnPluginStart()
{
	HookEvent("cs_match_end_restart", Event_RestartMatch, EventHookMode_Pre);
	restartgame = FindConVar("mp_restartgame");
}

public Action Event_RestartMatch(Event event, const char[] name, bool dontBroadcast)
{
	SetConVarInt(restartgame, 1);
	PrintToChatAll("\x01[\x0BSystem\x01] The game has been reseted.");
}