#include <sourcemod>

public OnPluginStart()
{
    CreateTimer(1.0, Timer_OneHealth, _, TIMER_REPEAT);  
}

public Action:Timer_OneHealth(Handle:timer)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i)&&IsPlayerAlive(i))
        {
            SetEntProp(i, Prop_Data, "m_iMaxHealth", 1);
            SetEntProp(i, Prop_Data, "m_iHealth", 1);
        }
    }
}  