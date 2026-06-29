#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

ConVar g_cvSprint;
ConVar g_cvBreathing;

bool g_bInfiniteSprint;
bool g_bInfiniteBreathing;

public Plugin myinfo = {
    name = "Infinite Aux Power",
    author = "Various",
    description = "Gives infinite aux/suit power and breathing in HL2DM",
    version = "1.1",
    url = ""
};

public void OnPluginStart()
{
    // Create ConVars
    CreateConVar("sm_infinite_aux_version", "1.1", "Infinite Aux Power Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    g_cvSprint = CreateConVar("sm_infinite_aux_sprint", "1", "Enable infinite sprinting (1=On, 0=Off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvBreathing = CreateConVar("sm_infinite_aux_breath", "1", "Enable infinite underwater breathing (1=On, 0=Off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    // Hook ConVar changes
    g_cvSprint.AddChangeHook(OnConVarChanged);
    g_cvBreathing.AddChangeHook(OnConVarChanged);
    
    // Set initial values
    UpdateConVars();
    
    // Hook player movement
    HookEvent("player_spawn", Event_PlayerSpawn);
    
    // Auto-generate config
    AutoExecConfig(true, "infinite_aux_power");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    UpdateConVars();
}

void UpdateConVars()
{
    g_bInfiniteSprint = g_cvSprint.BoolValue;
    g_bInfiniteBreathing = g_cvBreathing.BoolValue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (!IsValidClient(client))
        return Plugin_Continue;
    
    // Set initial values
    if (g_bInfiniteSprint || g_bInfiniteBreathing)
    {
        int suitPowerOffset = FindSendPropInfo("CHL2MP_Player", "m_flSuitPower");
        if (suitPowerOffset > 0)
        {
            SetEntDataFloat(client, suitPowerOffset, 100.0);
        }
    }
    
    if (g_bInfiniteBreathing)
    {
        int airOffset = FindSendPropInfo("CBasePlayer", "m_AirFinished");
        if (airOffset > 0)
        {
            SetEntDataFloat(client, airOffset, GetGameTime() + 20.0);
        }
    }
    
    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    
    // Handle sprint power
    if (g_bInfiniteSprint)
    {
        int suitPowerOffset = FindSendPropInfo("CHL2MP_Player", "m_flSuitPower");
        if (suitPowerOffset > 0)
        {
            float currentPower = GetEntDataFloat(client, suitPowerOffset);
            if (currentPower < 100.0)
            {
                SetEntDataFloat(client, suitPowerOffset, 100.0);
            }
        }
    }
    
    // Handle underwater breathing
    if (g_bInfiniteBreathing)
    {
        int airOffset = FindSendPropInfo("CBasePlayer", "m_AirFinished");
        if (airOffset > 0)
        {
            int waterLevel = GetEntProp(client, Prop_Data, "m_nWaterLevel");
            if (waterLevel > 2)  // Head is underwater
            {
                // Keep setting air time to the future
                SetEntDataFloat(client, airOffset, GetGameTime() + 20.0);
            }
        }
    }
    
    return Plugin_Continue;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client));
}