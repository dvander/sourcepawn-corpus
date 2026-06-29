public Plugin:myinfo = 
{
	name = "No Force",
	author = "Bottiger",
	description = "Prevents other players from being knock backed by explosion damage and stops airblasts",
	version = "1.0",
	url = "http://skial.com"
};

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Handle:nf_airblast;

new g_weapon[MAXPLAYERS+1];
new bool:g_airblast = true;

public OnPluginStart() {
    nf_airblast = CreateConVar("nf_airblast", "1", "Enable airblasts. 0 to disable.");
    HookConVarChange(nf_airblast, AirblastChanged);
    
    for(new i=1;i<=MaxClients;i++) {
        if(IsClientInGame(i))
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
    }
    HookEvent("player_spawn", OnSpawn);
}

public AirblastChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
    if(newValue[0] == '0') {
        g_airblast = false;
    } else {
        g_airblast = true;
    }
}

public OnClientPutInServer(client) {
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
    if(victim != attacker) {
        damagetype |= DMG_PREVENT_PHYSICS_FORCE;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
    // detect weapon switches
    if(weapon != 0)
        g_weapon[client] = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
    
    if(g_airblast)
        return Plugin_Continue;
    
    // check if holding flamethrower and block airblast
    // alternative GetClientWeapon with tf_weapon_flamethrower
    switch(g_weapon[client]) {
        case 21, 40, 208, 215:
            if(buttons & IN_ATTACK2) {
                buttons &= ~IN_ATTACK2;
                return Plugin_Changed;
            }
    }
    
    return Plugin_Continue;
}

public Action:OnSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
    // Check the weapon the person is holding when they spawn
    // It doesn't register onplayerruncmd when they spawn
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    decl String:weapon[32];
    GetClientWeapon(client, weapon, sizeof(weapon));
    if(StrEqual(weapon, "tf_weapon_flamethrower"))
        g_weapon[client] = 21; // index for regular flamethower.
    else
        g_weapon[client] = 0;
}