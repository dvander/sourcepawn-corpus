#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

public Plugin:myinfo =
{
    name    = "GoreX",
    author  = "iGENIUS",
    version = "1.1.1"
};

new Handle:gorex_blood_amount;
new Handle:gorex_gib_effects;
new Handle:gorex_count_head;
new Handle:gorex_count_rib;
new Handle:gorex_count_scapula;
new Handle:gorex_count_spine;
new Handle:gorex_bleed_effects;
new Handle:gorex_health_to_bleed;
new Handle:gorex_time_between_bleeding;
new Handle:gorex_bleed_effects_amount;
new Handle:gorex_remove_ragdoll;
new Handle:gorex_gib_weapons;
new Handle:gorex_bleed_loop;
new Handle:gorex_blood_loop;
new Handle:gorex_headshot_amount;
new Handle:gorex_headshot_loop;
new Handle:gorex_spray_effects;

new const String:gibs[4][128] =
{
    "models/gibs/hgibs.mdl",
    "models/gibs/hgibs_rib.mdl",
    "models/gibs/hgibs_scapula.mdl",
    "models/gibs/hgibs_spine.mdl"
};

public OnMapStart()
    for(new i = 0; i < sizeof(gibs); i++)
        PrecacheModel(gibs[i], true);
        
public OnPluginStart()
{
    CreateConVar("gorex", "1.1.1", "GoreX version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PLUGIN);
    
    gorex_blood_amount          = CreateConVar("gorex_blood_amount", "10", "Amount of blood per squirt for spray effects.");
    gorex_gib_effects           = CreateConVar("gorex_gib_effects", "1", "Enable exploding gib effects.");
    gorex_count_head            = CreateConVar("gorex_count_head", "1", "Amount of head gibs.");
    gorex_count_rib             = CreateConVar("gorex_count_rib", "4", "Amount of rib gibs.");
    gorex_count_scapula         = CreateConVar("gorex_count_scapula", "3", "Amount of scapula gibs.");
    gorex_count_spine           = CreateConVar("gorex_count_spine", "2", "Amount of spine gibs.");
    gorex_bleed_effects         = CreateConVar("gorex_bleed_effects", "1", "Enable bleeding effects.");
    gorex_health_to_bleed       = CreateConVar("gorex_health_to_bleed", "20", "Amount of health remaining to start bleeding at.");
    gorex_time_between_bleeding = CreateConVar("gorex_time_between_bleeding", "5", "Seconds between bleeding.");
    gorex_bleed_effects_amount  = CreateConVar("gorex_bleed_effects_amount", "10", "Amount of blood per squirt used for bleeding effects.");
    gorex_remove_ragdoll        = CreateConVar("gorex_remove_ragdoll", "1", "Enable removing of ragdoll for exploding gib effects.");
    gorex_gib_weapons           = CreateConVar("gorex_gib_weapons", "hegrenade;frag_;riflegren_;bazooka;pschreck", "List of comma seperated weapons with which to gib for. It checks for the existence of each of these strings in the weapon name. Ex: weapon_hegrenade.");
    gorex_bleed_loop            = CreateConVar("gorex_bleed_loop", "3", "Amount of squirts per bleed effect. (Reduce this if lag occurs.)");
    gorex_blood_loop            = CreateConVar("gorex_blood_loop", "5", "Amount of squirts per spray effect. (Reduce this if lag occurs.)");
    gorex_headshot_amount       = CreateConVar("gorex_headshot_amount", "10", "Amount of blood per squirt per head shot.");
    gorex_headshot_loop         = CreateConVar("gorex_headshot_loop", "5", "Amount of blood squirts per head shot. (Reduce this if lag occurs.)");
    gorex_spray_effects         = CreateConVar("gorex_spray_effects", "1", "Enable blood spray effects.");
    
    AutoExecConfig(true, "gorex");
    
    HookEvent("player_hurt", player_hurt);
    HookEvent("player_death", player_death);
}
    
public Action:player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    new id = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if(GetConVarBool(gorex_bleed_effects) && GetEventInt(event, "health") <= GetConVarInt(gorex_health_to_bleed))
        CreateTimer(float(GetConVarInt(gorex_time_between_bleeding)), bleed, id, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        
    if(!GetConVarBool(gorex_spray_effects))
        return;
        
    new loop = GetConVarInt(gorex_blood_loop);
    
    new String:amount[32];
    GetConVarString(gorex_blood_amount, amount, sizeof(amount));
    
    if(GetEventInt(event, "hitgroup") == 1)
    {
        loop = GetConVarInt(gorex_headshot_loop);
        GetConVarString(gorex_headshot_amount, amount, sizeof(amount));
    }
    
    for(new i = 0; i < loop; i++)
        env_blood(amount, 1|4|20|40, id);
}

public Action:bleed(Handle:timer, any:id)
{
    if(!IsClientInGame(id) || !IsPlayerAlive(id) || GetClientHealth(id) > GetConVarInt(gorex_health_to_bleed))
        return Plugin_Stop;
        
    new String:amount[32];
    GetConVarString(gorex_bleed_effects_amount, amount, sizeof(amount));
    
    for(new i = 0; i < GetConVarInt(gorex_bleed_loop); i++)
        env_blood(amount, 1|4|40, id);
        
    return Plugin_Continue;
}

env_blood(const String:amount[], spawnflags, id)
{
    new blood = CreateEntityByName("env_blood");
    
    if(blood == -1)
        return;
        
    DispatchKeyValue(blood, "amount", amount);
    SetEntProp(blood, Prop_Data, "m_spawnflags", spawnflags);
    
    new Float:origin[3];
    GetClientAbsOrigin(id, origin);
    
    origin[2] += 35.0;
    DispatchKeyValueVector(blood, "origin", origin);
    
    AcceptEntityInput(blood, "emitblood");
    AcceptEntityInput(blood, "kill");
}

public Action:player_death(Handle:event, const String:name[], bool:dontBroadcast)
{       
    new id      = GetClientOfUserId(GetEventInt(event, "userid"));
    new ragdoll = GetEntPropEnt(id, Prop_Send, "m_hRagdoll");
    
    if(IsPlayerAlive(id) || !GetConVarBool(gorex_gib_effects))
        return;
        
    new String:text[32];
    GetConVarString(gorex_gib_weapons, text, sizeof(text));
    
    new String:buffer[32][128];
    ExplodeString(text, ";", buffer, sizeof(buffer), sizeof(buffer[]));
    
    new String:weapon[32];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    
    new bool:shouldgib;
    
    for(new i = 0; i < sizeof(buffer); i++)
        if(StrEqual(weapon, buffer[i]))
        {
            // PrintToChatAll("weapon: %s", buffer[i]);
            shouldgib = true;
            
            break;
        }
            
    if(GetEventBool(event, "headshot") || shouldgib)
    {
        // PrintToChatAll("shouldgib: %i", shouldgib);
        
        if(!GetConVarBool(gorex_spray_effects))
        {
            new String:amount[32];
            GetConVarString(gorex_blood_amount, amount, sizeof(amount));
            
            for(new i = 0; i < GetConVarInt(gorex_blood_loop); i++)
                env_blood(amount, 1|4|20|40, id);
        }
        
        new gib = -1;
        
        new String:ent[64];
        Format(ent, sizeof(ent), "%i_gib", id);
        
        if(ragdoll != -1 && GetConVarBool(gorex_remove_ragdoll))
            AcceptEntityInput(ragdoll, "kill");
            
        while((gib = FindEntityByClassname(gib, "prop_physics")) != -1)
        {
            new String:tmp[64];
            GetEntPropString(gib, Prop_Data, "m_iName", tmp, sizeof(tmp));
        
            if(StrEqual(tmp, ent))
                AcceptEntityInput(gib, "kill");
        }
        
        new amount;
        
        for(new i = 0; i < sizeof(gibs); i++)
        {
            switch(i)
            {
                case 0: amount = GetConVarInt(gorex_count_head);
                case 1: amount = GetConVarInt(gorex_count_rib);
                case 2: amount = GetConVarInt(gorex_count_scapula);
                case 3: amount = GetConVarInt(gorex_count_spine);
            }
            
            if(!amount)
                return;
                
            for(i = 0; i < amount; i++)
            {
                gib = CreateEntityByName("prop_physics");
                
                if(gib == -1)
                    return;
                    
                DispatchKeyValue(gib, "targetname", ent);
                DispatchKeyValue(gib, "model", gibs[i]);
                SetEntProp(gib, Prop_Data, "m_spawnflags", 4|8192|1048576);
                
                new Float:origin[3];
                GetClientAbsOrigin(id, origin);
                
                new Float:vel[3];
                
                vel[0] = GetRandomFloat(-200.0, 300.0);
                vel[1] = GetRandomFloat(-200.0, 300.0);
                vel[2] = GetRandomFloat(-200.0, 300.0);
                
                DispatchSpawn(gib);
                
                TeleportEntity(gib, origin, NULL_VECTOR, vel);
            }
        }
    }
}
