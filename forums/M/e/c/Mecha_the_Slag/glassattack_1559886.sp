#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "0.5"
public Plugin:myinfo = 
{
    name = "Glass Attack",
    author = "Fenderic (modified by Mecha the Slag)",
    description = "Sniper-only deathmatch with tons of breakable glass!",
    version = PLUGIN_VERSION,
    url = "http://www.moddb.com/mods/glass-attack"
};
//CVars
new Handle:g_Cvar_GlassEnabled;

public OnPluginStart()
{
    CreateConVar("sm_glass_version", PLUGIN_VERSION, "Glass Attack version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_Cvar_GlassEnabled = CreateConVar("sm_glass_enabled", "1", "Enables the Glass Attack plugin");
    if(GetConVarBool(g_Cvar_GlassEnabled))
    {
        HookEvent("player_changeclass", Event_PlayerClass);
        HookEvent("player_spawn", Event_PlayerSpawn);
    }
    
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i)) OnClientPutInServer(i);
    }
}

stock IsValidClient(client)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    decl String:adminname[32];
//    decl String:auth[32];
    decl String:name[32];
    new AdminId:admin;
    GetClientName(client, name, sizeof(name));
//    GetClientAuthString(client, auth, sizeof(auth));
    if (strcmp(name, "replay", false) == 0 && IsFakeClient(client)) return false;
    if ((admin = GetUserAdmin(client)) != INVALID_ADMIN_ID)
    {
        GetAdminUsername(admin, adminname, sizeof(adminname));
        if (strcmp(adminname, "Replay", false) == 0) return false;
    }
    return true;
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponSwitch);
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType, &iWeapon, Float:vDamageForce[3], Float:vDamagePos[3])
{
    if (IsValidClient(iVictim) && IsValidClient(iAttacker) && iVictim != iAttacker)
    {
        fDamage *= 0.3;
        return Plugin_Changed;
    }
    return Plugin_Changed;
}

public Action:OnWeaponSwitch(client, weapon)
{
    decl String:classname[32];
    GetEdictClassname(weapon, classname, sizeof(classname));
    if (StrEqual(classname, "tf_weapon_smg"))
        return Plugin_Handled;
    
    return Plugin_Continue;
}

public Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!GetConVarBool(g_Cvar_GlassEnabled))
    {
        return;
    }
    new glass_user = GetClientOfUserId(GetEventInt(event, "userid"));
    new glass_user_class  = GetEventInt(event, "class");
    if(glass_user_class != 2)
    {
        TF2_SetPlayerClass(glass_user, TFClassType:2);
    }
    
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!GetConVarBool(g_Cvar_GlassEnabled))
    {
        return;
    }
    new glass_user = GetClientOfUserId(GetEventInt(event, "userid"));
    if(TF2_GetPlayerClass(glass_user) != TFClassType:2)
    {
        TF2_SetPlayerClass(glass_user, TFClassType:2);
        if(IsPlayerAlive(glass_user))
        {
            TF2_RespawnPlayer(glass_user);
        }
    }
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
    DestroyGlass(client);
}

DestroyGlass(iClient)
{
    decl String:strWeapon[128];
    GetClientWeapon(iClient, strWeapon, sizeof(strWeapon));
    if (!StrEqual(strWeapon, "tf_weapon_sniperrifle")) return;

    new iTarget = GetClientAimTarget(iClient, false);
    if (!IsClassname(iTarget, "func_breakable")) return;
    
    if (GetRandomInt(1,2) != 1) return;
    
    AcceptEntityInput(iTarget, "Break");
}

stock bool:IsClassname(iEntity, String:strClassname[]) {
    if (iEntity <= 0) return false;
    
    if (!IsValidEdict(iEntity)) return false;
        
    decl String:strClassname2[32];
    GetEdictClassname(iEntity, strClassname2, sizeof(strClassname2));
    if (!StrEqual(strClassname, strClassname2, false)) return false;
    
    return true;
}