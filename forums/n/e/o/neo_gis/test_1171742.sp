#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new g_iFlashDuration = -1;
//new g_iAccount = -1;

public OnPluginStart()
{
    g_iFlashDuration = FindSendPropOffs("CCSPlayer", "m_flFlashDuration");
    //g_iAccount = FindSendPropOffs("CSSPlayer", "m_iAccount");

    HookEvent("item_pickup", Event_Item_Pickup);
    HookEvent("player_spawn", Event_Player_Spawn);
    HookEvent("player_blind", Event_Player_Blind);
    HookEvent("flashbang_detonate", Event_Flashbang_Detonate);
}

public Action:Event_Item_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid");
    new client = GetClientOfUserId(userid);
    
    new ent1 = GetPlayerWeaponSlot(client, 1);
    if (ent1 != -1) 
    {
        RemovePlayerItem(client, ent1);
    }
    
    new ent2 = GetPlayerWeaponSlot(client, 2);
    if (ent2 != -1) 
    {
        RemovePlayerItem(client, ent2);
    }
    
    new ent0 = GetPlayerWeaponSlot(client, 0);
    if (ent0 != -1) 
    {
        RemovePlayerItem(client, ent0);
    }    
}

public Action:Event_Player_Blind(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid");
    new client = GetClientOfUserId(userid);
    
    SetEntData(client, g_iFlashDuration, 0);        
}

public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid");
    new client = GetClientOfUserId(userid);
    
    //SetEntData(client, g_iAccount, 0);
    SetEntProp(client, Prop_Send, "m_iAccount", 0);
    GivePlayerItem(client, "weapon_flashbang"); 
}

public Action:Event_Flashbang_Detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid");
    new client = GetClientOfUserId(userid);
    
    GivePlayerItem(client, "weapon_flashbang"); 
}
