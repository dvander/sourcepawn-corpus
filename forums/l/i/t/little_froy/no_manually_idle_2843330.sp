#define PLUGIN_VERSION	"1.1"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <little_froy_utils_colors>

public Plugin myinfo =
{
	name = "No Manually Idle",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=352420"
};

Action on_cmd_idle(int client, const char[] command, int argc)
{
    if(client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
    {
        colors_print_to_chat(client, "%T", "no_manually_idle", client);
    }
    return Plugin_Handled;
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
    LoadTranslations("no_manually_idle.phrases");

    AddCommandListener(on_cmd_idle, "go_away_from_keyboard");
    
    CreateConVar("no_manually_idle_version", PLUGIN_VERSION, "version of No Manually Idle", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}