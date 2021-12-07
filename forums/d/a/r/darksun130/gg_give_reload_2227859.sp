#include <sourcemod>
#include <sdktools_functions>
#include <gungame>

#define GG_SLOTINDEX_KNIFE 2

public Plugin:myinfo =
{
    name = "SM GunGame Give",
    author = "Rogue",
    description = "Gives the player the current weapon they are on.",
    version = "2.0",
    url = "http://www.sourcemod.net/"
};

new bool:playerIsHoldingKey[MAXPLAYERS+1];

public OnPluginStart()
{
    CreateConVar("sm_gggive_version", "2.0", "SM GunGame Give Weapon Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

//Reload with IN_RELOAD by darksun130 ;) special thanks to bobbobagan for the awesome plugin :)
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (buttons & IN_RELOAD)
    {
            if (!playerIsHoldingKey[client])
            {
                    playerIsHoldingKey[client] = true;
                    new bool:WarmupInProgress = GG_IsWarmupInProgress();
                    new ClientLevel = GG_GetClientLevel(client);
                    new maxlevel = GG_GetMaxLevel();
                    if (WarmupInProgress == false && (ClientLevel <= (maxlevel - 2)) && IsPlayerAlive(client))
                    {
                        StripWeaponsButKnife(client);
                        GiveWeaponToClient(client);
                        ClientCommand(client, "slot1");
                        ClientCommand(client, "slot2");
            
                        return Plugin_Handled;
                    }
                    else
                    {
                        PrintToChat(client, "[SM] Fast reload can not be used now.");
                        return Plugin_Handled;
                    }
             }
    }
    else
    {
    playerIsHoldingKey[client] = false;
    }
    
    return Plugin_Continue;
}

// Thanks to MistaGee's JailMod for this part
StripWeaponsButKnife(client)
{
    new wepIdx;
    // Iterate through weapon slots
    for( new i = 0; i < 5; i++ )
    {
        if( i == GG_SLOTINDEX_KNIFE ) continue; // You can leeeeave your knife on...
        // Strip all weapons from current slot
        while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 )
        {
            RemovePlayerItem( client, wepIdx );
        }
    }
}

GiveWeaponToClient(client)
{
    new String:Weaponname[64];
    new String:FullWeaponName[64];
    new ClientLevel = GG_GetClientLevel(client);
    GG_GetLevelWeaponName(ClientLevel, Weaponname, sizeof(Weaponname));
    Format(FullWeaponName, sizeof(FullWeaponName), "weapon_%s", Weaponname);
    
    GivePlayerItem(client, FullWeaponName);
    return;
}