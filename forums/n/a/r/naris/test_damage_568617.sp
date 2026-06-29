/**
 * vim: set ai et ts=4 sw=4 :
 * File: test_damage.sp
 * Description: Display damage for every hit.
 * Author(s): Naris (Murray Wilson)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "util"
#include "health"
#include "damage"

public Plugin:myinfo = 
{
    name = "test_damage",
    author = "Naris",
    description = "Test damage.",
    version = "1.0.0.0",
    url = "http://jigglysfunhouse.net/"
};

// War3Source Functions
public OnPluginStart()
{
    GetGameType();

    HookEvent("player_hurt",PlayerHurtEvent);
    HookEvent("player_spawn",PlayerSpawnEvent);
}

public OnClientPutInServer(client)
{
    SetupHealth(client);
}

public OnGameFrame()
{
    SaveAllHealth();
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid = GetEventInt(event,"userid");
    new index = GetClientOfUserId(userid);
    if (index && IsClientConnected(index) && IsPlayerAlive(index))
        SaveHealth(index);
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victimUserid = GetEventInt(event,"userid");
    new victimIndex = GetClientOfUserId(victimUserid);

    new attackerUserid = GetEventInt(event,"attacker");
    new attackerIndex = GetClientOfUserId(attackerUserid);

    new health = GetEventInt(event,"health");
    new oldHealth = GetSavedHealth(victimIndex);

    new damage = GetDamage(event, victimIndex, attackerIndex, -1, -1);

    decl String:victimName[64] = "";
    decl String:attackerName[64] = "";
    decl String:weapon[64] = "";

    if (victimIndex)
        GetClientName(victimIndex,victimName,sizeof(victimName));

    if (attackerIndex)
    {
        GetClientName(attackerIndex,attackerName,sizeof(attackerName));
        GetClientWeapon(attackerIndex, weapon, sizeof(weapon));
    }

    LogMessage("%s has attacked %s with %s for %d damage with %d of %d health remaining.\n",
               attackerName, victimName, weapon, damage, health, oldHealth);

    if (victimIndex)
        PrintToChat(victimIndex,"%s has attacked %s with %s for %d damage with %d of %d health remaining.",
                    attackerName, victimName, weapon, damage, health, oldHealth);

    if (attackerIndex)
        PrintToChat(attackerIndex,"%s has attacked %s with %s for %d damage with %d of %d health remaining.",
                    attackerName, victimName, weapon, damage, health, oldHealth);

    if (victimIndex)
        SaveHealth(victimIndex);
}
