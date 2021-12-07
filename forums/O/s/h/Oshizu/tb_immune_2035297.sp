#include <sourcemod>
#include <tf2autobalance>

#define PLUGIN_VERSION "1.0"

new Handle:g_hCvarFlags;
new g_Flags = ADMFLAG_RESERVATION;

public Plugin:myinfo =
{
    name = "Team Balance Immunity",
    author = "Afronanny",
    description = "Protect your admins or donors from the autobalancer!",
    version = PLUGIN_VERSION,
    url = "http://www.afronanny.org/"
}

public OnPluginStart()
{
    HookConVarChange(CreateConVar("teambalance_version", PLUGIN_VERSION, "", FCVAR_NOTIFY), ConVarChanged);
    g_hCvarFlags = CreateConVar("sm_teambalance_flags", "a");
    HookConVarChange(g_hCvarFlags, ConVarChanged);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (convar == g_hCvarFlags)
    {
        g_Flags = ReadFlagString(newValue);
        return;
    }
    
    if (!StrEqual(newValue, PLUGIN_VERSION))
    {
        SetConVarString(convar, PLUGIN_VERSION);
    }
    
}

public Action:OnCanBeAutobalanced(client, &bool:result)
{
    if (GetUserFlagBits(client) & g_Flags)
    {
        result = false;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}