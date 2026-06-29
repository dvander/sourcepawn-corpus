/* 
 * Based on Simple Welcome Message Plugin by Zuko
 */

#include <sourcemod>

#define PLUGIN_NAME "L4D Difficulty Announce"
#define PLUGIN_VERSION "1.0"

new const String:g_szActualDifficulty[4][] = {
	"Easy",
	"Normal",
	"Hard",
	"Impossible"
};

new const String:g_szFunDifficulty[4][] = {
	"Sweet",
	"Salty",
	"Tasty",
	"Spicy"
};

new Handle:g_Cvar_PluginEnable = INVALID_HANDLE;
new Handle:g_Cvar_PluginTimer = INVALID_HANDLE;
new Handle:g_Cvar_Difficulty = INVALID_HANDLE;

new String:g_szDifficulty[16];

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "psychonic, Zuko",
	description = "Announces difficulty to players after connect",
	version = PLUGIN_VERSION,
	url = "http://www.nicholashastings.com"
}

public OnPluginStart()
{
	CreateConVar("diffannounce_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_PluginEnable = 		CreateConVar("diffannounce_enable", "1", "Enable/Disable Plugin", _, true, 0.0, true, 1.0);
	g_Cvar_PluginTimer = 		CreateConVar("diffannounce_timer", "25.0", "When the message should be displayed after the player join on the server (in seconds)");
	g_Cvar_Difficulty = FindConVar("z_difficulty");
	
	decl String:newValue[16];
	GetConVarString(g_Cvar_Difficulty, newValue, sizeof(newValue));
	for (new i = 0; i < 4; i++)
	{
		if (StrEqual(newValue, g_szActualDifficulty[i]))
		{
			strcopy(g_szDifficulty, sizeof(g_szDifficulty), g_szFunDifficulty[i]);
			break;
		}
	}
	
	HookConVarChange(g_Cvar_Difficulty, DifficultyChanged);
}

public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(g_Cvar_PluginEnable) == 1)
	{
		CreateTimer (GetConVarFloat(g_Cvar_PluginTimer), Timer_Welcome, client);
	}
}

public DifficultyChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	for (new i = 0; i < 4; i++)
	{
		if (StrEqual(newValue, g_szActualDifficulty[i]))
		{
			strcopy(g_szDifficulty, sizeof(g_szDifficulty), g_szFunDifficulty[i]);
			break;
		}
	}
}
	
public Action:Timer_Welcome(Handle:timer, any:client)
{
	ChatMessagesDisplay(client);

	return Plugin_Handled;
}

ChatMessagesDisplay(client)
{
	if (IsClientInGame(client))
	{
		PrintToChat(client, "\x04[SM] Difficulty is: \x03%s\x04.", g_szDifficulty);
	}
}