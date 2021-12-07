#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <sdkhooks>

new bool:ClientIsBuddah[MAXPLAYERS+1] = {false, ...};
new Handle:hBlockWeps = INVALID_HANDLE;
new Handle:hRemember = INVALID_HANDLE;

public OnPluginStart()
{
    for(new i=1; i<MAXPLAYERS+1; i++)
        ClientIsBuddah[i] = false;
    hBlockWeps = CreateConVar("sm_friendly_blockweps", "0", "Enable/Disable(1/0) Blocked Weapons", FCVAR_PLUGIN|FCVAR_NOTIFY);
    hRemember = CreateConVar("sm_friendly_remember", "0", "Enable/Disable(1/0) Remember Friendly", FCVAR_PLUGIN|FCVAR_NOTIFY);
    RegAdminCmd("sm_friendly", OnToggleFriendly, ADMFLAG_BAN, "Toggles friendly on/off");
    HookEvent("player_death", OnPlayerDeath);
    HookEvent("player_spawn", OnPlayerSpawned);
}

public Action:OnToggleFriendly(client, args)
{
    if(IsPlayerAlive(client))
    {
        if (ClientIsBuddah[client] == true) {
            ClientIsBuddah[client] = false;
            new flags = GetEntityFlags(client)&~FL_NOTARGET;
        SetEntityFlags(client, flags);
        SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
        ReplyToCommand(client, "Freindly mode disabled.");
        }
        else {
            ClientIsBuddah[client] = true;
            new flags = GetEntityFlags(client)|FL_NOTARGET;
        SetEntityFlags(client, flags);
        SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
        ReplyToCommand(client, "Friendly mode enabled.");
        }
     }
     else
         ReplyToCommand(client, "You cannot apply !friendly when dead.");

    return Plugin_Handled;
}  

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(ClientIsBuddah[client] && !GetConVarBool(hRemember))
    {
        ClientIsBuddah[client] = false;
        SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
        new flags = GetEntityFlags(client)&~FL_NOTARGET;
        SetEntityFlags(client, flags);
        ReplyToCommand(client, "Freindly mode disabled on death.");
    }
}

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(ClientIsBuddah[client] && GetConVarBool(hRemember))
    {
        ClientIsBuddah[client] = true;
        new flags = GetEntityFlags(client)|FL_NOTARGET;
    SetEntityFlags(client, flags);
    SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
    ReplyToCommand(client, "Friendly mode re-enabled on spawn.");
    }
}

public OnEntityCreated(building, const String:classname[])
{
    SDKHook(building, SDKHook_Spawn, OnEntitySpawned);
}

public OnEntitySpawned(building)
{
    SDKHook(building, SDKHook_OnTakeDamage, BuildingTakeDamage);
}

public OnClientPutInServer(client)
{
    ClientIsBuddah[client] = false;
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public Action:OnWeaponSwitch(client, weapon)
{
    decl String:sWeapon[32];
    GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));

    if(ClientIsBuddah[client] && GetConVarBool(hBlockWeps))
    {
        if(StrEqual(sWeapon, "tf_weapon_flamethrower") || StrEqual(sWeapon, "tf_weapon_medigun") || StrEqual(sWeapon, "tf_weapon_builder") || StrEqual(sWeapon, "tf_weapon_bonesaw") || StrEqual(sWeapon, "tf_weapon_compound_bow") || StrEqual(sWeapon, "tf_weapon_bat_wood") || StrEqual(sWeapon, "tf_weapon_jar") || StrEqual(sWeapon, "tf_weapon_jar_milk") || StrEqual(sWeapon, "tf_weapon_fireaxe") || StrEqual(sWeapon, "tf_weapon_lunchbox") || StrEqual(sWeapon, "tf_weapon_crossbow"))
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action:BuildingTakeDamage(building, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if (attacker < 1 || attacker > MaxClients)
    {
        return Plugin_Continue;
    }
    new String:classname[64];
    GetEntityClassname(building, classname, sizeof(classname));
    if (StrEqual(classname, "obj_sentrygun", false) || StrEqual(classname, "obj_dispenser", false) || StrEqual(classname, "obj_teleporter", false))    // make sure it is a building
    {
        if(ClientIsBuddah[attacker])
        {
        damage = 0;
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
    decl String:weapon[32];
    GetClientWeapon(attacker, weapon, sizeof(weapon));

    if (attacker < 1 || attacker > MaxClients || client == attacker)
    {
        return Plugin_Continue;
    }

    if (ClientIsBuddah[attacker] || ClientIsBuddah[client])
    {
        damage = 0;
        return Plugin_Handled;
    }

    return Plugin_Continue;
}  