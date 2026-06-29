#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "Vote Block",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351515"
};

ConVar C_block_kick;
bool O_block_kick;
ConVar C_block_return_to_lobby;
bool O_block_return_to_lobby;
ConVar C_block_change_all_talk;
bool O_block_change_all_talk;
ConVar C_block_restart_game;
bool O_block_restart_game;
ConVar C_block_change_mission;
bool O_block_change_mission;
ConVar C_block_change_chapter;
bool O_block_change_chapter;
ConVar C_block_change_difficulty;
bool O_block_change_difficulty;

Action on_cmd_callvote(int client, const char[] command, int argc)
{
    if(argc < 1)
    {
        return Plugin_Continue;
    }
    char arg1[64];
    GetCmdArg(1, arg1, sizeof(arg1));
    if(O_block_kick && strcmp(arg1, "kick", false) == 0)
    {
        return Plugin_Handled;
    }
    if(O_block_return_to_lobby && strcmp(arg1, "returntolobby", false) == 0)
    {
        return Plugin_Handled;
    }
    if(O_block_change_all_talk && strcmp(arg1, "changealltalk", false) == 0)
    {
        return Plugin_Handled;
    }
    if(O_block_restart_game && strcmp(arg1, "restartgame", false) == 0)
    {
        return Plugin_Handled;
    }
    if(O_block_change_mission && strcmp(arg1, "changemission", false) == 0)
    {
        return Plugin_Handled;
    }
    if(O_block_change_chapter && strcmp(arg1, "changechapter", false) == 0)
    {
        return Plugin_Handled;
    }
    if(O_block_change_difficulty && strcmp(arg1, "changedifficulty", false) == 0)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

void get_all_cvars()
{
    O_block_kick = C_block_kick.BoolValue;
    O_block_return_to_lobby = C_block_return_to_lobby.BoolValue;
    O_block_change_all_talk = C_block_change_all_talk.BoolValue;
    O_block_restart_game = C_block_restart_game.BoolValue;
    O_block_change_mission = C_block_change_mission.BoolValue;
    O_block_change_chapter = C_block_change_chapter.BoolValue;
    O_block_change_difficulty = C_block_change_difficulty.BoolValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_block_kick)
    {
        O_block_kick = C_block_kick.BoolValue;
    }
    else if(convar == C_block_return_to_lobby)
    {
        O_block_return_to_lobby = C_block_return_to_lobby.BoolValue;
    }
    else if(convar == C_block_change_all_talk)
    {
        O_block_change_all_talk = C_block_change_all_talk.BoolValue;
    }
    else if(convar == C_block_restart_game)
    {
        O_block_restart_game = C_block_restart_game.BoolValue;
    }
    else if(convar == C_block_change_mission)
    {
        O_block_change_mission = C_block_change_mission.BoolValue;
    }
    else if(convar == C_block_change_chapter)
    {
        O_block_change_chapter = C_block_change_chapter.BoolValue;
    }
    else if(convar == C_block_change_difficulty)
    {
        O_block_change_difficulty = C_block_change_difficulty.BoolValue;
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    AddCommandListener(on_cmd_callvote, "callvote");

    C_block_kick = CreateConVar("vote_block_kick", "0", "1 = enable, 0 = disable. block vote to kick?");
    C_block_kick.AddChangeHook(convar_changed);
    C_block_return_to_lobby = CreateConVar("vote_block_return_to_lobby", "0", "1 = enable, 0 = disable. block vote to return to lobby?");
    C_block_return_to_lobby.AddChangeHook(convar_changed);
    C_block_change_all_talk = CreateConVar("vote_block_change_all_talk", "0", "1 = enable, 0 = disable. block vote to change all talk?");
    C_block_change_all_talk.AddChangeHook(convar_changed);
    C_block_restart_game = CreateConVar("vote_block_restart_game", "0", "1 = enable, 0 = disable. block vote to restart game?");
    C_block_restart_game.AddChangeHook(convar_changed);
    C_block_change_mission = CreateConVar("vote_block_change_mission", "0", "1 = enable, 0 = disable. block vote to change mission?");
    C_block_change_mission.AddChangeHook(convar_changed);
    C_block_change_chapter = CreateConVar("vote_block_change_chapter", "0", "1 = enable, 0 = disable. block vote to change chapter?");
    C_block_change_chapter.AddChangeHook(convar_changed);
    C_block_change_difficulty = CreateConVar("vote_block_change_difficulty", "0", "1 = enable, 0 = disable. block vote to change difficulty?");
    C_block_change_difficulty.AddChangeHook(convar_changed);
    CreateConVar("vote_block_version", PLUGIN_VERSION, "version of Vote Block", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "vote_block");
    get_all_cvars();
}
