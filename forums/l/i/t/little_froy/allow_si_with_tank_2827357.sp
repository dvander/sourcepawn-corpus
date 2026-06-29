#define PLUGIN_VERSION	"1.0"
#define PLUGIN_NAME		"Allow Special Infected With Tank"
#define PLUGIN_PREFIX   "allow_si_with_tank"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=349087"
};

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
    if(strcmp(key, "ShouldAllowSpecialsWithTank") == 0)
    {
        retVal = 1;
        return Plugin_Handled;        
    }
    return Plugin_Continue;
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
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
}