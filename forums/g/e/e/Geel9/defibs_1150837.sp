#include <sourcemod>
#include <sdktools>
public Plugin:myinfo = {
    
    name = "Defib Healing",
    author = "Joshua Coffey",
    description = "Allows players to heal alive players with defibs.",
    version = "1.0.0.0",
    url = "http://www.sourcemod.net/"
    
}


new Handle:chat = INVALID_HANDLE;
new Handle:health = INVALID_HANDLE;

public OnPluginStart() {
    
    HookEvent("defibrillator_used_fail",defail);
    chat = CreateConVar("sm_defib_chat", "1", "Tell players when a user heals another user with a defib.", FCVAR_NOTIFY|FCVAR_PLUGIN)
    health = CreateConVar("sm_defib_health", "30", "The amount of health to give to player when using defibs on them", FCVAR_NOTIFY)
    
}


public defail(Handle:event, const String:name[], bool:dontBroadcast)
{
    
    new healthdone = 0
    new chatdo = GetConVarInt(chat)
    new healthremainder = 100 - GetConVarInt(health)
    new user_id = GetEventInt(event, "userid")
    new healthtoadd = GetConVarInt(health)
    new subject_id = GetEventInt(event, "subject")
    new subject = GetClientOfUserId(subject_id)
    new user = GetClientOfUserId(user_id)
    new subjecthealth = GetClientHealth(subject)
    new defibrillator = GetPlayerWeaponSlot(user, 3);
    
    if(subjecthealth < 100){
        
        
        if(subjecthealth > healthremainder){
            
            for(new i = subjecthealth; i < 100; i++){
                
                healthdone++
                
            }
            
            SetEntityHealth(subject,100)
            
        }
        else{
            
            SetEntityHealth(subject, subjecthealth + healthtoadd)
            
        }
        
        if(chatdo){
            
            if(healthdone != 0){
                
                PrintToChatAll("%N gave %i health via defib to %N", user, healthdone, subject)
                
            }
            else{
                
                PrintToChatAll("%N gave %i health via defib to %N", user, healthtoadd, subject)
                
            }
            
            
        }
        
        RemovePlayerItem(user, defibrillator);
        
    }
    
    
}