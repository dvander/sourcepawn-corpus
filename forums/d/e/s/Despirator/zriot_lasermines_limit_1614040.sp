#include <sourcemod> 
#include <zriot_lasermines> 

new Handle:h_limit; 
new limit[MAXPLAYERS+1]; 

public OnPluginStart() 
{ 
    h_limit = CreateConVar("zriot_client_limit", "5", "The max limit", FCVAR_PLUGIN, true, 0.0); 
    HookEvent("round_start", OnRoundStart); 
} 
public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
    for (new i = 1; i <= MaxClients; i++)
    { 
        limit[i] = 0; 
    } 
} 
public ZRiot_OnLaserMinePlanted(client, Float:act_delay, exp_damage, exp_radius, health, color[3]) 
{ 
    limit[client]++; 
} 
public Action:ZRiot_OnPlantLaserMine(client, &Float:act_delay, &exp_damage, &exp_radius, &health, color[3]) 
{ 
    if (limit[client] > GetConVarInt(h_limit)) 
    {
        PrintHintText(client, "You have reached your limit of laser mines!");
        return Plugin_Handled;
    }
    return Plugin_Continue; 
}
public Action:ZRiot_OnPreBuyLaserMine(client, &amount, &price)
{
	decl max_limit;
	max_limit = GetConVarInt(h_limit);
	if (amount > max_limit)
	{
		amount = max_limit;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}