#include <sourcemod>
#define PLUGIN_VERSION "1.2"
#define MAX_FILE_LEN 60
new Handle:vote_command = INVALID_HANDLE
new Handle:vote_rank = INVALID_HANDLE
new wcounter = 0
 
public Plugin:myinfo = {
        name        = "CS:GO AR MAPVOTE",
        author      = "Darkranger",
        description = "starting a mapvote when a player is on an specific Level",
        version     = PLUGIN_VERSION,
        url         = "http://dark.asmodis.at"
}
 
public OnPluginStart()
{
	CreateConVar("csgo_ar_mapvote_version", PLUGIN_VERSION, "CS:GO AR Mapvote Version", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	vote_rank = CreateConVar("csgo_ar_mapvote_level",    "16", "CS:GO AR Mapvote! On which Level should start the vote?", FCVAR_PLUGIN)
	vote_command = CreateConVar("csgo_ar_mapvote_command",    "sm_mapvote", "CS:GO AR Mapvote! Command to execute when vote starts!", FCVAR_PLUGIN)
	HookEvent("ggtr_player_levelup", ggtr_levelup)
	HookEvent("ggprogressive_player_levelup", ggpro_levelup)
}

public Action:ggtr_levelup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new rank = GetEventInt(event, "weaponrank")
	if (rank == (GetConVarInt(vote_rank)) && (wcounter == 0))
	{
		decl String:Command[64];
		GetConVarString(vote_command, Command, MAX_FILE_LEN)
		ServerCommand("%s", Command)
		wcounter = 1
	}
}

public Action:ggpro_levelup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new rank = GetEventInt(event, "weaponrank")
	if (rank == (GetConVarInt(vote_rank)) && (wcounter == 0))
	{
		decl String:Command[64];
		GetConVarString(vote_command, Command, MAX_FILE_LEN)
		ServerCommand("%s", Command)
		wcounter = 1
	}
}

public OnMapStart()
{
	wcounter = 0
}

public OnMapEnd()
{
	wcounter = 0
}