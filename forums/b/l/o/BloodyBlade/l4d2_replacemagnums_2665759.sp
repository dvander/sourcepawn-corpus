#pragma semicolon 1
#pragma newdecls required
#include <sourcemod> 
#include <sdktools> 
#define PLUGIN_VERSION "1.0.1" 

public Plugin myinfo =
{ 
    name = "[L4D2] Replace Magnums", 
    author = "chinagreenelvis, McFlurry", 
    description = "Replaces magnums with normal pistol.", 
    version = PLUGIN_VERSION, 
    url = "http://forums.alliedmods.net"     
}

public void OnPluginStart()
{
    HookEvent("round_start", Event_Round_Start);
}

public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
    CreateTimer(10.0, ReplaceMagnumDelay);
}

public Action ReplaceMagnumDelay(Handle timer)
{
    ReplaceMagnum();
}

void ReplaceMagnum()
{
    int ent = -1;
    int prev = 0;
    int replacement;
    float origin[3];
    float angles[3];
    while ((ent = FindEntityByClassname(ent, "weapon_pistol")) != -1)
    {
        if (prev)
        {
            GetEntPropVector(prev, Prop_Send, "m_vecOrigin", origin);
            GetEntPropVector(prev, Prop_Send, "m_angRotation", angles);
            
            replacement = CreateEntityByName("weapon_pistol_magnum_spawn");
            DispatchSpawn(replacement);
            //PrintToChatAll("Replacing weapon_pistol %i with weapon_pistol_magnum_spawn %i", prev, replacement);
            if (!IsValidEdict(replacement)) return;
            
            TeleportEntity(replacement, origin, angles, NULL_VECTOR);
            //PrintToChatAll("Teleported weapon_pistol_magnum_spawn %i into position, removing weapon_pistol now", replacement);
            
            if (IsValidEdict(prev)) RemoveEdict(prev);
        }
        prev = ent;
    }
    if (prev)
    {
        GetEntPropVector(prev, Prop_Send, "m_vecOrigin", origin);
        GetEntPropVector(prev, Prop_Send, "m_angRotation", angles);
            
        replacement = CreateEntityByName("weapon_pistol_magnum_spawn");
        DispatchSpawn(replacement);
        //PrintToChatAll("Replacing weapon_pistol %i with weapon_pistol_magnum_spawn %i", prev, replacement);
        if (!IsValidEdict(replacement)) return;
            
        TeleportEntity(replacement, origin, angles, NULL_VECTOR);
        //PrintToChatAll("Teleported weapon_pistol_magnum_spawn %i into position, removing weapon_pistol now", replacement);
            
        if (IsValidEdict(prev)) RemoveEdict(prev);
    }
    while ((ent = FindEntityByClassname(ent, "weapon_spawn")) != -1)
    {
        if (prev)
        {
            GetEntPropVector(prev, Prop_Send, "m_vecOrigin", origin);
            GetEntPropVector(prev, Prop_Send, "m_angRotation", angles);
            
            replacement = CreateEntityByName("weapon_pistol_magnum_spawn");
            DispatchSpawn(replacement);
            //PrintToChatAll("Replacing weapon_pistol %i with weapon_pistol_magnum_spawn %i", prev, replacement);
            if (!IsValidEdict(replacement)) return;
            
            TeleportEntity(replacement, origin, angles, NULL_VECTOR);
            //PrintToChatAll("Teleported weapon_pistol_magnum_spawn %i into position, removing weapon_pistol now", replacement);
            
            if (IsValidEdict(prev)) RemoveEdict(prev);
        }
        char weptospawn[32];
        GetEntPropString(ent, Prop_Data, "m_iszWeaponToSpawn", weptospawn, sizeof(weptospawn));
        if(StrContains(weptospawn, "any_pistol", false) != -1 || StrContains(weptospawn, "weapon_pistol_magnum_spawn_magnum", false) != -1)
        {
            prev = ent;
        }
    }
    if (prev)
    {
        GetEntPropVector(prev, Prop_Send, "m_vecOrigin", origin);
        GetEntPropVector(prev, Prop_Send, "m_angRotation", angles);
            
        replacement = CreateEntityByName("weapon_pistol_magnum_spawn");
        DispatchSpawn(replacement);
        //PrintToChatAll("Replacing weapon_pistol %i with weapon_pistol_magnum_spawn %i", prev, replacement);
        if (!IsValidEdict(replacement)) return;
            
        TeleportEntity(replacement, origin, angles, NULL_VECTOR);
        //PrintToChatAll("Teleported weapon_pistol_magnum_spawn %i into position, removing weapon_pistol now", replacement);
            
        if (IsValidEdict(prev)) RemoveEdict(prev);
    }
}