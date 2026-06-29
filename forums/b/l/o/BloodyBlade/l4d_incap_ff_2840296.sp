#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define CVAR_FLAGS FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
    name        = "[L4D] Incap FF",
    author      = "BloodyBlade",
    description = "Allow friendly fire by incappacitated players",
    version     = PLUGIN_VERSION,
    url         = "https://bloodsiworld.ru"
};

ConVar hPluginOn, z_difficulty;
bool bL4D2 = false, bPluginOn = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
    EngineVersion engine = GetEngineVersion();
    if(engine == Engine_Left4Dead)
    {
        bL4D2 = false;
    }
    else if(engine == Engine_Left4Dead2)
    {
        bL4D2 = true;
    }
    else
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead game series.");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("l4d_incap_ff_version", PLUGIN_VERSION, "[L4D] Incap FF plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
    hPluginOn = CreateConVar("l4d_incap_ff_enable", "1", "Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
    AutoExecConfig(true, "l4d_incap_ff");
    hPluginOn.AddChangeHook(OnConVarEnableChanged);
    z_difficulty = FindConVar("z_difficulty");
}

public void OnConfigsExecuted()
{
    OnConVarEnableChanged(null, "", "");
}

void OnConVarEnableChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    bPluginOn = hPluginOn.BoolValue;
}

public void OnClientPutInServer(int client)
{
	if(bPluginOn && client > 0)
	{
	    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
    if(bPluginOn && IsValidSurvivor(victim) && view_as<bool>(GetEntProp(victim, Prop_Send, "m_isIncapacitated")) && IsValidSurvivor(attacker))
    {
        static char sBuffer[64];
        z_difficulty.GetString(sBuffer, sizeof(sBuffer));
        if (strncmp(sBuffer, "Easy", sizeof(sBuffer), false) == 0) damage = 0.0;
        else if ((!bL4D2 && strncmp(sBuffer, "Medium", sizeof(sBuffer), false) == 0) || (bL4D2 && strncmp(sBuffer, "Normal", sizeof(sBuffer), false) == 0)) damage = 5.0;
        else if (strncmp(sBuffer, "Hard", sizeof(sBuffer), false) == 0) damage = 10.0;
        else if ((!bL4D2 && strncmp(sBuffer, "Expert", sizeof(sBuffer), false) == 0) || (bL4D2 && strncmp(sBuffer, "Impossible", sizeof(sBuffer), false) == 0)) damage = 20.0;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

bool IsValidSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}
