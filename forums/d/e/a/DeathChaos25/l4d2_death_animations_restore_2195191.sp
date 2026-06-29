/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* [L4D2] Special Infected Warnings Vocalize Fix
* 
* About : This plugin restores the Survivor Death Animations while
* also fixing the bug where the animations would endlessly loop and
* the survivors would never actually die
* 
* =============================
* ===      Change Log       ===
* =============================
* Version 1.0    2014-09-02
* - Initial Release
* =============================
* Version 1.1    2014-09-05
* - Semi Major code re-write, moved from using a "player_hurt" event hook
* to SDK_Tools OnTakeDamagePost (Huge thanks to Mr.Zero for that)
* =============================
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


#include <sourcemod> 
#include <sdkhooks> 
#include <l4d_stocks> 

#define PLUGIN_VERSION "1.0" 
#define PLUGIN_NAME "[L4D2] Restore Survivor Death Animations" 

/*Credits to Mr.Zero as the bit of code were the plugin checks for MaxIncaps CVAR 
* was shamelessly taken from his restore ragdolls plugin,  
* which can be found here; 
* https://forums.alliedmods.net/showthread.php?t=198806 */ 

#define CVAR_SURVIVOR_MAX_INCAP_COUNT "survivor_max_incapacitated_count" 
new Handle:g_Cvar_MaxIncaps 

static bool:g_bIsRagdollDeathEnabled 

public Plugin:myinfo =  
{ 
    name        = PLUGIN_NAME, 
    author        = "DeathChaos25", 
    description    = "Restores the Death Animations for survivors while fixing the bug where the animation would loop endlessly and the survivors would never die.", 
    version        = PLUGIN_VERSION, 
    url        = "https://forums.alliedmods.net/showthread.php?t=247488", 
} 

public OnPluginStart() 
{ 
    SetConVarInt(FindConVar("survivor_death_anims"), 1) 
     
    g_Cvar_MaxIncaps = FindConVar(CVAR_SURVIVOR_MAX_INCAP_COUNT) 
    if (g_Cvar_MaxIncaps == INVALID_HANDLE) 
    { 
        SetFailState("Unable to find \"%s\" cvar", CVAR_SURVIVOR_MAX_INCAP_COUNT) 
    } 
     
    new Handle:RagdollDeathEnabled = CreateConVar("enable_ragdoll_death", "1", "Enable Ragdolls upon Death? 0 = Disable Ragdoll Death, 1 = Enable Ragdoll Death", FCVAR_PLUGIN, true, 0.0, true, 1.0)  
    HookConVarChange(RagdollDeathEnabled, ConVarRagdollDeathEnabled)  
    g_bIsRagdollDeathEnabled = GetConVarBool(RagdollDeathEnabled)  
     
    AutoExecConfig(true, "l4d2_death_animations_restore")  
} 

public OnClientPutInServer(client)  
{ 
    SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost) 
} 

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)  
{ 
    if (!IsClientInGame(victim) || L4DTeam:GetClientTeam(victim) != L4DTeam_Survivor || !IsPlayerAlive(victim)) 
        return 
     
    new health = GetClientHealth(victim) + L4D_GetPlayerTempHealth(victim) 
    if (damage < health || L4D_GetPlayerReviveCount(victim) < GetConVarInt(g_Cvar_MaxIncaps)) 
        return 
     
    new Handle:pack = CreateDataPack() 
    WritePackCell(pack, GetClientUserId(victim)) 
    WritePackFloat(pack, damage) 
    CreateTimer(1.0, CheckIsSurvivorDyingTimer, pack, TIMER_FLAG_NO_MAPCHANGE  | TIMER_DATA_HNDL_CLOSE) 
} 

public Action:CheckIsSurvivorDyingTimer(Handle:timer, Handle:pack, TIMER_FLAG_NO_MAPCHANGE  | TIMER_DATA_HNDL_CLOSE) 
{ 
    ResetPack(pack) 
    new client = GetClientOfUserId(ReadPackCell(pack)) 
    new Float:damage = ReadPackFloat(pack) 
     
    if (client <= 0 || client > MaxClients || !IsClientInGame(client)) 
        return Plugin_Stop /* Client disconnected before timer ended */ 
     
    new health = GetClientHealth(client) + L4D_GetPlayerTempHealth(client) 
    if (damage < health || L4D_GetPlayerReviveCount(client) < GetConVarInt(g_Cvar_MaxIncaps)) 
        return Plugin_Stop 
     
    CreateTimer(2.14, ForcePlayerSuicideTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE) 
    return Plugin_Stop 
} 

public Action:ForcePlayerSuicideTimer(Handle:timer, any:userid) 
{ 
    new client = GetClientOfUserId(userid) 
    if (client <= 0 || client > MaxClients || !IsClientInGame(client)) 
        return Plugin_Stop 
     
    if (g_bIsRagdollDeathEnabled == true) { 
         
        /*Also taken from Restore Ragdolls :) */ 
         
        SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1) 
         
        new weapon = GetPlayerWeaponSlot(client, _:L4DWeaponSlot_Secondary) 
        if (weapon > 0 && IsValidEntity(weapon)) { 
            SDKHooks_DropWeapon(client, weapon) // Drop their secondary weapon since they cannot be defibed 
        } 
    } 
     
    ForcePlayerSuicide(client) 
} 

public ConVarRagdollDeathEnabled(Handle:convar, const String:oldValue[], const String:newValue[]) 
{ 
    g_bIsRagdollDeathEnabled = GetConVarBool(convar)  
}  