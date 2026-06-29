#include <sdkhooks>

#define PLUGIN_VERSION                  "1.0.0"
#define PLUGIN_NAME                     "Health Reset"
#define PLUGIN_DESCRIPTION              "Resets the clients health to the maximum."

public Plugin myinfo =
{
    name            = PLUGIN_NAME,
    author          = "Maxximou5",
    description     = PLUGIN_DESCRIPTION,
    version         = PLUGIN_VERSION,
    url             = "http://maxximou5.com/"
}

ConVar cvar_sm_hp_enabled;
ConVar cvar_sm_hp_max;

bool enabled;
int maxHP;

public void OnPluginStart()
{
    CreateConVar( "sm_healthreset_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD );

    cvar_sm_hp_enabled = CreateConVar("sm_hp_enabled", "1", "Enable HP Reset.");
    cvar_sm_hp_max = CreateConVar("sm_hp_max", "100", "Maximum HP.");

    AutoExecConfig(true, "healthreset");

    HookEvent("player_death", Event_PlayerDeath);

    HookConVarChange(cvar_sm_hp_enabled, Event_CvarChange);
    HookConVarChange(cvar_sm_hp_max, Event_CvarChange);
}

public void OnConfigsExecuted()
{
    enabled = GetConVarBool(cvar_sm_hp_enabled);
    maxHP = GetConVarInt(cvar_sm_hp_max);
}

public Action Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (enabled)
    {
        new attackerIndex = GetClientOfUserId(GetEventInt(event, "attacker"));
        new bool:validAttacker = (attackerIndex != 0) && IsPlayerAlive(attackerIndex);
        // Reward attacker with HP.
        if (validAttacker)
        {
            maxHP = GetConVarInt(cvar_sm_hp_max);
            new attackerHP = GetClientHealth(attackerIndex);

            if (attackerHP < maxHP)
            {
                SetEntProp(attackerIndex, Prop_Send, "m_iHealth", maxHP, 1);
                PrintToChat(attackerIndex, "[\x04HP\x01] \x04+%iHP\x01 %t", maxHP);
            }
        }
    }
}

public Event_CvarChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
        // Ignore changes which result in the same value being set
    if (StrEqual(oldValue, newValue, true))
    {
        return;
    }

    enabled = GetConVarBool(cvar_sm_hp_enabled);
    maxHP = GetConVarBool(cvar_sm_hp_max);
}