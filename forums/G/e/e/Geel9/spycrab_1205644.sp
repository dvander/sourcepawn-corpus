#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.1"
new bool:done[MAXPLAYERS + 1];
new Handle:enabled;
public Plugin:myinfo =


{
    name = "SpyCrab",
    author = "Geel9",
    description = "SpyCrab mode.",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/id/geel9/"
}
;

public OnPluginStart()
{
    HookEvent("player_changeclass", RemovePlayer);
    HookEvent("player_disconnect", RemovePlayer);
    HookEvent("player_shoot", Shoot);
    RegConsoleCmd("spycrab", Spycrab);
    RegConsoleCmd("slot0", Check);
    RegConsoleCmd("slot1", Check);
    RegConsoleCmd("slot2", Check);
    enabled = CreateConVar("sm_spycrab_enabled", "1", "Spycrab Mode Enabled.", FCVAR_PLUGIN|FCVAR_NOTIFY);
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(weapon != 0){
        if(done[client] == true){
            if(GetPlayerWeaponSlot(client, 0) != -1){
                new w1 = GetPlayerWeaponSlot(client, 0);
                new w2 = GetPlayerWeaponSlot(client, 1);
                new w3 = GetPlayerWeaponSlot(client, 2);
                RemovePlayerItem(client, w1);
                RemovePlayerItem(client, w2);
                RemovePlayerItem(client, w3);
                TF2_AddCondition(client, 14, 100000.0);
                ClientCommand(client, "slot3");
            }
        }
    }
}


public Strip(client){
    new bool:pluginEnabled = GetConVarBool(enabled)
    new w1 = GetPlayerWeaponSlot(client, 0);
    new w2 = GetPlayerWeaponSlot(client, 1);
    new w3 = GetPlayerWeaponSlot(client, 2);
    if(pluginEnabled)
    {
        if (TF2_GetPlayerClass(client) == TFClass_Spy)        
        {
            if(done[client] == true)
            {
                RemovePlayerItem(client, w1);
                RemovePlayerItem(client, w2);
                RemovePlayerItem(client, w3);
                TF2_AddCondition(client, 14, 100000.0);
                ClientCommand(client, "slot3");
            }  
        }		
    }
}


public Action:Check(client, args)
{
    Strip(client);
}


public Action:Spycrab(client, args)
{
    doSpycrab(client, false);
}



public doSpycrab(client, bool:requirement)
{
    new pluginEnabled = GetConVarBool(enabled)
    new w1 = GetPlayerWeaponSlot(client, 0);
    new w2 = GetPlayerWeaponSlot(client, 1);
    new w3 = GetPlayerWeaponSlot(client, 2);
    if(pluginEnabled)
    {
        if (TF2_GetPlayerClass(client) == TFClass_Spy) 
        {
            if(done[client] == requirement)
            {
                RemovePlayerItem(client, w1);
                RemovePlayerItem(client, w2);
                RemovePlayerItem(client, w3);
                ClientCommand(client, "slot3");
                if(requirement == false)
                {
                    done[client] = true;
                }
                TF2_AddCondition(client, 14, 100000.0);
            }
        }
    }
}


public Action:Shoot(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    Strip(client);
}


public Action:RemovePlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    done[client] = false;
}