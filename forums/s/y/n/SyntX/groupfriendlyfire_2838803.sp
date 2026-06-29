#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

ConVar 
    g_cvFFCT, 
    g_cvFFT, 
    g_cvFFBots, 
    g_cvMPFF;
bool 
    g_bFFCT, 
    g_bFFT, 
    g_bFFBots;

public Plugin myinfo = 
{
    name = "Team-Specific Friendly Fire",
    author = "+SyntX",
    description = "Dynamically controls friendly fire per team using mp_friendlyfire",
    version = PLUGIN_VERSION,
    url = "https://steamcommunity.com/id/SyntX34 && https://github.com/SyntX34"
};

public void OnPluginStart()
{
    g_cvFFCT = CreateConVar("sm_ff_ct", "0", "Enable or Disable friendly fire for CT's (0 = off, 1 = on)", _, true, 0.0, true, 1.0);
    g_cvFFT = CreateConVar("sm_ff_t", "0", "Enable or Disable friendly fire for T's (0 = off, 1 = on)", _, true, 0.0, true, 1.0);
    g_cvFFBots = CreateConVar("sm_ff_bots", "1", "Enable or Disable friendly fire for bots (0 = off, 1 = on)", _, true, 0.0, true, 1.0);
    
    g_cvMPFF = FindConVar("mp_friendlyfire");
    g_cvMPFF.AddChangeHook(OnFriendlyFireChanged);
    
    g_cvFFCT.AddChangeHook(OnConVarChanged);
    g_cvFFT.AddChangeHook(OnConVarChanged);
    g_cvFFBots.AddChangeHook(OnConVarChanged);
    
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
    
    g_bFFCT = g_cvFFCT.BoolValue;
    g_bFFT = g_cvFFT.BoolValue;
    g_bFFBots = g_cvFFBots.BoolValue;
    
    AutoExecConfig(true, "team_friendlyfire");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == g_cvFFCT)
    {
        g_bFFCT = convar.BoolValue;
    }
    else if (convar == g_cvFFT)
    {
        g_bFFT = convar.BoolValue;
    }
    else if (convar == g_cvFFBots)
    {
        g_bFFBots = convar.BoolValue;
    }
}

public void OnFriendlyFireChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (StringToInt(newValue) != 1)
    {
        g_cvMPFF.IntValue = 1;
    }
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    if (victim <= 0 || victim > MaxClients || attacker <= 0 || attacker > MaxClients)
        return Plugin_Continue;
    
    if (attacker == victim)
        return Plugin_Continue;
    
    if (GetClientTeam(attacker) != GetClientTeam(victim))
        return Plugin_Continue;
    
    bool attackerIsBot = IsFakeClient(attacker);
    bool victimIsBot = IsFakeClient(victim);
    
    if ((attackerIsBot || victimIsBot) && !g_bFFBots)
    {
        return Plugin_Handled;
    }
    
    if (GetClientTeam(attacker) == CS_TEAM_CT && !g_bFFCT)
    {
        return Plugin_Handled;
    }
    
    if (GetClientTeam(attacker) == CS_TEAM_T && !g_bFFT)
    {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}