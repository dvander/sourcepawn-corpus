#pragma semicolon 1
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.1"
public Plugin myinfo = {
    name = "Projectile Explosions",
    author = "MitchDizzle",
    description = "Decoy and other projectiles expload on hit.",
    version = PLUGIN_VERSION,
    url = "mtch.tech"
}

ConVar cEnable;
ConVar cRemove;
ConVar cDamageHit;
ConVar cRadius;
ConVar cMag;
ConVar cNoDamage;

public void OnPluginStart() {
    cEnable = CreateConVar("sm_de_enable", "1", "Enable Decoy Explosions?");
    cRemove = CreateConVar("sm_de_remove", "1", "Remove the decoy after explosion?");
    cDamageHit = CreateConVar("sm_de_damage_on_hit", "200", "Damage when the decoy hits the player.");
    cRadius = CreateConVar("sm_de_radius", "600", "Explosion Radius");
    cMag = CreateConVar("sm_de_damage", "0", "Explosion Magnitude");
    cNoDamage = CreateConVar("sm_de_nodamage", "1", "Explosion damage will not hurt other players.");
    
    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i)) {
            OnClientPutInServer(i);
        }
    }
}

public void OnMapStart() {
    char exp_sample[64];
    for(int s = 3; s <= 5; s++) {
        Format(exp_sample, 64, ")weapons/hegrenade/explode%d.wav", s);
        PrecacheSound(exp_sample);
    }
}

public void OnClientPutInServer(int client) {
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType) {
    if (!cEnable.BoolValue) {
        return Plugin_Continue;
    }
    
    char sWeapon[32];
    GetEdictClassname(inflictor, sWeapon, sizeof(sWeapon));

    if(StrContains(sWeapon, "_projectile") >= 0) {
        CreateExplosion(inflictor, victim);
        damage = cDamageHit.FloatValue;
        return Plugin_Changed;
    }
    
    if(StrEqual(sWeapon, "env_explosion") && cNoDamage.BoolValue) {
        int owner = GetEntPropEnt(inflictor, Prop_Data, "m_hOwnerEntity");
        int target = GetEntPropEnt(inflictor, Prop_Data, "m_hEffectEntity");
        if(owner < 1 || owner > MaxClients || !IsClientInGame(owner))
            return Plugin_Continue;
        if(victim != target)
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public CreateExplosion(int entity, int victim) {
    int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
    if(owner < 1 || owner > MaxClients)
        return;
    if(!IsClientInGame(owner))
        return;
    
    float nadeOrigin[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", nadeOrigin);

    if(cRemove.BoolValue) {
        AcceptEntityInput(entity, "Kill");
    }
    
    int ent = CreateEntityByName("env_explosion");
    SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", owner); //Set the owner of the explosion
    SetEntPropEnt(ent, Prop_Data, "m_hEffectEntity", victim); //Set the victim of the explosion

    int mag = cMag.IntValue;
    int rad = cRadius.IntValue;
    SetEntProp(ent, Prop_Data, "m_iMagnitude", mag); 
    if(rad != 0) {
        SetEntProp(ent, Prop_Data, "m_iRadiusOverride",rad); 
    }

    DispatchSpawn(ent);
    ActivateEntity(ent);

    char exp_sample[64];
    Format(exp_sample, 64, ")weapons/hegrenade/explode%d.wav", GetRandomInt(3, 5));
    EmitAmbientSound(exp_sample, nadeOrigin, _, SNDLEVEL_GUNFIRE);
    //if(explosion_sound_enable) {
        //explosion_sound_enable = false;
        
        //CreateTimer(0.1, EnableExplosionSound);
    //} 

    TeleportEntity(ent, nadeOrigin, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(ent, "explode");
    AcceptEntityInput(ent, "kill");
}
