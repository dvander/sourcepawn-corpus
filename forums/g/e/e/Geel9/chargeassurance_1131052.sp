#include <sourcemod>
#include <sdktools>
public Plugin:myinfo =
{
    
    
    name = "Charge Protection",
    author = "Joshua Coffey",
    description = "Let chargers have a higher chance of survival during charges.",
    version = "1.1.0.0",
    url = "http://www.sourcemod.net/"
    
    
}


new bool:done[MAXPLAYERS] = {
    false, ...
}
;

public OnClientPutInServer(client) {
    
    
    done[client] = false;
    
}

new charger
new health
new healthtoadd
new Handle:convarhealth = INVALID_HANDLE;
public OnPluginStart()
{
    
    
    convarhealth = CreateConVar("sm_charger_health", "300", "The amount of health to give to a charger during a charge", FCVAR_NOTIFY|FCVAR_PLUGIN)
    HookEvent("charger_charge_start",startcharge);
    HookEvent("charger_charge_end",endcharge);
    
    
}



public startcharge(Handle:event, const String:name[], bool:dontBroadcast)

{
    
    
    healthtoadd = GetConVarInt(convarhealth)
    new user_id = GetEventInt(event, "userid")
    charger = GetClientOfUserId(user_id)
    health = GetClientHealth(charger)
    if(!done[charger])
    
    {
        
        
        SetEntityHealth(charger, healthtoadd + health)
        done[charger] = true
        
    }
    
    
    
    
}



public endcharge(Handle:event, const String:name[], bool:dontBroadcast)

{
    
    
    healthtoadd = GetConVarInt(convarhealth)
    new user_id = GetEventInt(event, "userid")
    new endcharger = GetClientOfUserId(user_id)
    new clienthealth = GetClientHealth(endcharger)
    done[endcharger] = false
    new dmgdeal = clienthealth - healthtoadd
    if(clienthealth > healthtoadd)
    {
        
        
        SetEntityHealth(endcharger, dmgdeal)
        
        
    }
    
    
    
    
}