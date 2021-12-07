#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

#define NUM_WEAPONS_PER_ROUND 1

public Plugin:myinfo = 
{
	name = "basic jail supporter",
	author = "Skruf",
	description = "gives supporter/premium members weapons for ct in jailbreak",
	version = PLUGIN_VERSION,
	url = "http://www.sensationmg.com/"
};

enum WeaponType
{
    AK47,
    M4A1,
    AWP
}

new NumWeaponsLeft[MAXPLAYERS + 1];

public OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart);
    RegAdminCmd("sm_ak47", Command_Ak47, ADMFLAG_CUSTOM1);
    RegAdminCmd("sm_m4a1", Command_M4a1, ADMFLAG_CUSTOM1);
    RegAdminCmd("sm_awp", Command_Awp, ADMFLAG_CUSTOM1);
}



public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i = 1; i <= MAXPLAYERS; i++)
    {
        NumWeaponsLeft[i] = NUM_WEAPONS_PER_ROUND;
    }
}

public Action:Command_Ak47(client, args)  
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }
    return GiveWeapon(client, AK47);
}

public Action:Command_M4a1(client, args)  
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }
    return GiveWeapon(client, M4A1);
}

public Action:Command_Awp(client, args)  
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }
    return GiveWeapon(client, AWP);
}

stock bool:IsValidClient(const client)
{
    if ((client <= 0) || (client > MaxClients))
    {
        return false;
    }
    if (!IsClientInGame(client))
    {
        return false;
    }
    return true;
}

Action:GiveWeapon(const client, const WeaponType:type)
{
    new team = GetClientTeam(client);
    if (team == CS_TEAM_CT) 
    {
        if (NumWeaponsLeft[client] == 0)
        {
            ReplyToCommand(client, "[Premium] You have exceeded your weapons limit.");
            return Plugin_Handled;
        }
        switch (type)
        {
            case AK47: {ReplyToCommand(client, "[Premium] Got an AK47.");GivePlayerItem(client, "weapon_ak47");}
            case M4A1: {ReplyToCommand(client, "[Premium] Got an M4A1.");GivePlayerItem(client, "weapon_m4a1");}
            case AWP: {ReplyToCommand(client, "[Premium] Got an AWP.");GivePlayerItem(client, "weapon_awp");}
        }
        NumWeaponsLeft[client]--;
        return Plugin_Handled;
    }
    if (team == CS_TEAM_T && !(GetUserFlagBits(client) & ADMFLAG_ROOT))
    {
        ReplyToCommand(client, "[Premium] Denied: Only root admins can spawn for T's.");
    }
    return Plugin_Handled;
}