float Multiplier[2][4]= {{1.0 , 0.70 , 0.50 , 0.36}    ,    {1.0 , 0.35 , 0.23 , 0.20}}; 

// First group is the survivors' multiplier of speed based on their level in water , And the 2nd one is for Infected .
// As you can see above , when a survivor went deep in water the multiplier of speed would be 0.36 .while it would be 0.20 for tanks.

Handle h_timer[32];

public OnPluginStart()
{
    HookEvent("player_spawn",E_P_X);
    HookEvent("player_death",E_P_X);
}

public E_P_X(Handle:event, const String:name[], bool:Broadcast) 
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client)    return ;
    
    if (name[7] == 's')
    {
        if (h_timer[client] == null)
        {
            h_timer[client] = CreateTimer(0.5 ,Timer_Refresh_Speed , client ,TIMER_REPEAT);
        }
    }
    else    OnClientDisconnect(client);
}

public Action Timer_Refresh_Speed(Handle Timer ,any client)
{
    SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", Multiplier[ GetClientTeam(client) %2 ][ GetEntProp(client, Prop_Send, "m_nWaterLevel") ] );
    return Plugin_Continue;
}

public OnClientDisconnect(client)
{
    if (h_timer[client]!=null)    delete h_timer[client];  
}