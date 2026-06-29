new Handle:pointscharge                = INVALID_HANDLE;
new Handle:pointscharge_collateral    = INVALID_HANDLE;
new Handle:pointsjockey_ride        = INVALID_HANDLE;

	pointscharge			= CreateConVar("points_amount_infected_charge","1","How many points you get [as a charger] after impact on survivor, for 1 pummel damage.",CVAR_FLAGS,true,0.0,true,50.0);
    pointscharge_collateral	= CreateConVar("points_amount_infected_charge_coll","1","How many points you get [as a charger] when hitting nearby survivors.",CVAR_FLAGS,true,0.0,true,50.0);
    pointsjockey_ride		= CreateConVar("points_amount_infected_jockeyride","1","How many points you get when jumping on a survivor.",CVAR_FLAGS,true,0.0,true,50.0);

    HookEvent("charger_pummel_start",Charge_Pummel_Points); //charger does the hammer like pumping action to the victim.
    HookEvent("charger_impact",Charge_Collateral_Damage_Points); //charger hits survivor(s) who he did NOT carry, thus, collateral damage :).
    HookEvent("jockey_ride",Jockey_Ride_Points); //charger hits survivor(s) who he did NOT carry, thus, collateral damage :).

public Action:Charge_Pummel_Points(Handle:event, String:event_name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid")); // charger
    if (client > 0 && client <= MaxClients)
    {
        if (pointsteam[client] != SURVIVORTEAM)
        {
            if(pointson)
            {
                PrintToChat(client, "[SM] You charged a survivor! + %d %s",GetConVarInt(pointscharge),"points.");
                points[client] += GetConVarInt(pointscharge);
            }
        }
    }
}

public Action:Charge_Collateral_Damage_Points(Handle:event, String:event_name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid")); // charger
    if (client > 0 && client <= MaxClients)
    {
        if (pointsteam[client] != SURVIVORTEAM)
        {
            if(pointson)
            {
                PrintToChat(client, "[SM] Collateral damage!!! + %d %s",GetConVarInt(pointscharge_collateral),"points.");
                points[client] += GetConVarInt(pointscharge_collateral);
            }
        }
    }
}


public Action:Jockey_Ride_Points(Handle:event, String:event_name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid")); // charger
    if (client > 0 && client <= MaxClients)
    {
        if (pointsteam[client] != SURVIVORTEAM)
        {
            if(pointson)
            {
                PrintToChat(client, "[SM] Successful jump! + %d %s",GetConVarInt(pointsjockey_ride),"points.");
                points[client] += GetConVarInt(pointsjockey_ride);
            }
        }
    }
}