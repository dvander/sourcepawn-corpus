#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static const String:t2strings[][] = {
                                    "weapon_autoshotgun",
                                    "weapon_shotgun_spas",
                                    "weapon_hunting_rifle",
                                    "weapon_rifle",
                                    "weapon_pistol_magnum",
                                    "weapon_rifle_ak47",
                                    "weapon_rifle_desert",
                                    "weapon_rifle_sg552",
                                    "weapon_sniper_awp",
                                    "weapon_sniper_military",
                                    "weapon_sniper_scout"
                                    };

public OnPluginStart()
{
    HookEvent("player_use", Event_PlayerUse);
}

public Action:Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
    new item = GetEventInt(event, "targetid");
    
    if (IsValidEdict(item)
    && IsT2Gun(item))
    {
        RemoveEdict(item);
    }
}

static bool:IsT2Gun(item)
{
    decl String:itemname[64];
    GetEdictClassname(item, itemname, sizeof(itemname));
    
    for (new i = 0; i < sizeof(t2strings); i++)
    {
        if (StrContains(itemname, t2strings[i], false) != -1)
        {
            return true;
        }
    }
    
    return false;
}