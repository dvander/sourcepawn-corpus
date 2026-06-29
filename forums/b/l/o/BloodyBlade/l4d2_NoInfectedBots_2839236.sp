#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION     "0.92"
#define CVAR_FLAGS FCVAR_NOTIFY

bool bEnabled = true;
ConVar noSI_allowSmoker, noSI_allowBoomer, noSI_allowHunter, noSI_allowSpitter, noSI_allowJockey, noSI_allowCharger, hEnableCvar;
int noSI_SmokerSpawn = 0, noSI_BoomerSpawn = 0, noSI_HunterSpawn = 0, noSI_SpitterSpawn = 0, noSI_JockeySpawn = 0, noSI_ChargerSpawn = 0;

public Plugin myinfo = 
{
    name = "No Infected Bots",
    author = "Mr. Zero",
    description = "Kick special infected bots.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=118798"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin supports Left 4 Dead 2 only.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("l4d2_noinfectedbots_version", PLUGIN_VERSION, "NoInfectedBots Version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
    hEnableCvar = CreateConVar("noSI_enabled", "1", "Blocks infected bots from joining the game", CVAR_FLAGS, true, 0.0, true, 1.0);

    noSI_allowSmoker = CreateConVar("noSI_allowSmoker", "0", "Allow Smokers to spawn?", CVAR_FLAGS, true, 0.0, true, 1.0);
    noSI_allowBoomer = CreateConVar("noSI_allowBoomer", "0", "Allow Boomers to spawn?", CVAR_FLAGS, true, 0.0, true, 1.0);
    noSI_allowHunter = CreateConVar("noSI_allowHunter", "0", "Allow Hunters to spawn?", CVAR_FLAGS, true, 0.0, true, 1.0);
    noSI_allowSpitter = CreateConVar("noSI_allowSpitter", "0", "Allow Spitters to spawn?", CVAR_FLAGS, true, 0.0, true, 1.0);
    noSI_allowJockey = CreateConVar("noSI_allowJockey", "0", "Allow Jockeys to spawn?", CVAR_FLAGS, true, 0.0, true, 1.0);
    noSI_allowCharger = CreateConVar("noSI_allowCharger", "0", "Allow Chargers to spawn?", CVAR_FLAGS, true, 0.0, true, 1.0);

    AutoExecConfig(true, "NoInfectedBots");

    hEnableCvar.AddChangeHook(ConVarChange);
    noSI_allowSmoker.AddChangeHook(ConVarChange);
    noSI_allowBoomer.AddChangeHook(ConVarChange);
    noSI_allowHunter.AddChangeHook(ConVarChange);
    noSI_allowSpitter.AddChangeHook(ConVarChange);
    noSI_allowJockey.AddChangeHook(ConVarChange);
    noSI_allowCharger.AddChangeHook(ConVarChange);

    RegAdminCmd("sm_infbots", ToogleInfectedBots_Command, ADMFLAG_BAN, "Toggles infected bots", _, CVAR_FLAGS);
}

Action ToogleInfectedBots_Command(int client, int args)
{
    if (bEnabled)
    {
        hEnableCvar.SetInt(0, false, false);
        ReplyToCommand(client,"[SM] Infected bots are now managed");
    }
    else
    {
        hEnableCvar.SetInt(1, false, false);
        ReplyToCommand(client,"[SM] Infected bots are now managed");
    }
    return Plugin_Handled;
}

void ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    bEnabled = hEnableCvar.BoolValue;
    if (bEnabled)
    {
        UnsetCheatVar(FindConVar("z_smoker_limit"));
        UnsetCheatVar(FindConVar("z_boomer_limit"));
        UnsetCheatVar(FindConVar("z_hunter_limit"));
        UnsetCheatVar(FindConVar("z_spitter_limit"));
        UnsetCheatVar(FindConVar("z_jockey_limit"));
        UnsetCheatVar(FindConVar("z_charger_limit"));

        noSI_SmokerSpawn = noSI_allowSmoker.IntValue;
        noSI_BoomerSpawn = noSI_allowBoomer.IntValue;
        noSI_HunterSpawn = noSI_allowHunter.IntValue;
        noSI_SpitterSpawn = noSI_allowSpitter.IntValue;
        noSI_JockeySpawn = noSI_allowJockey.IntValue;
        noSI_ChargerSpawn = noSI_allowCharger.IntValue;

        FindConVar("z_smoker_limit").SetInt(noSI_SmokerSpawn);
        FindConVar("z_boomer_limit").SetInt(noSI_BoomerSpawn);
        FindConVar("z_hunter_limit").SetInt(noSI_HunterSpawn);
        FindConVar("z_spitter_limit").SetInt(noSI_SpitterSpawn);
        FindConVar("z_jockey_limit").SetInt(noSI_JockeySpawn);
        FindConVar("z_charger_limit").SetInt(noSI_ChargerSpawn);
    }
    else
    {
        ResetConVar(FindConVar("z_smoker_limit"));
        ResetConVar(FindConVar("z_boomer_limit"));
        ResetConVar(FindConVar("z_hunter_limit"));
        ResetConVar(FindConVar("z_spitter_limit"));
        ResetConVar(FindConVar("z_jockey_limit"));
        ResetConVar(FindConVar("z_charger_limit"));

        noSI_SmokerSpawn = 1;
        noSI_BoomerSpawn = 1;
        noSI_HunterSpawn = 1;
        noSI_SpitterSpawn = 1;
        noSI_JockeySpawn = 1;
        noSI_ChargerSpawn = 1;

        SetCheatVar(FindConVar("z_smoker_limit"));
        SetCheatVar(FindConVar("z_boomer_limit"));
        SetCheatVar(FindConVar("z_hunter_limit"));
        SetCheatVar(FindConVar("z_spitter_limit"));
        SetCheatVar(FindConVar("z_jockey_limit"));
        SetCheatVar(FindConVar("z_charger_limit"));
    }
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    // If it's a human avatar stop right here.
    if (!IsFakeClient(client) || !bEnabled)
    {
        return true;
    }

    char name[10];
    GetClientName(client, name, sizeof(name));

    // If it isn't one of these AI stop right here.
    if(StrContains(name, "smoker", false) == -1 && 
        StrContains(name, "boomer", false) == -1 && 
        StrContains(name, "hunter", false) == -1 && 
        StrContains(name, "spitter", false) == -1 && 
        StrContains(name, "jockey", false) == -1 && 
        StrContains(name, "charger", false) == -1)
    {
        return true;
    }

    if (StrContains(name, "smoker", false) != -1 && noSI_SmokerSpawn > 0)
    {
        return true;
    }
    else if (StrContains(name, "boomer", false) != -1 && noSI_BoomerSpawn > 0)
    {
        return true;
    }
    else if (StrContains(name, "hunter", false) != -1 && noSI_HunterSpawn > 0)
    {
        return true;
    }
    else if (StrContains(name, "spitter", false) != -1 && noSI_SpitterSpawn > 0)
    {
        return true;
    }
    else if (StrContains(name, "jockey", false) != -1 && noSI_JockeySpawn > 0)
    {
        return true;
    }
    else if (StrContains(name, "charger", false) != -1 && noSI_ChargerSpawn > 0)
    {
        return true;
    }

    KickClient(client,"[NoInfectedBots] Kicking infected bot...");
    
    return false;
}

stock void UnsetCheatVar(ConVar hndl)
{
    int flags = GetConVarFlags(hndl);
    flags &= ~FCVAR_CHEAT;
    SetConVarFlags(hndl, flags);
}
 
stock void SetCheatVar(ConVar hndl)
{
    int flags = GetConVarFlags(hndl);
    flags |= FCVAR_CHEAT;
    SetConVarFlags(hndl, flags);
}
