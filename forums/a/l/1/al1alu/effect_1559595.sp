#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <zombiereloaded>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Explosion Effect - ZR",
	author = "SoZika",
	description = "Creates an explosion effect to be infected",
	version = "1.0",
	url = "http://insanitybrasil.info"
};

// Cvars
new Handle:gCvarEnabled;
new bool:gEnabled;

public OnPluginStart() {
	gCvarEnabled = CreateConVar("sm_effect_enabled", "1");
	gEnabled = GetConVarBool(gCvarEnabled);
	HookConVarChange(gCvarEnabled, CvarChanged);

	if(gEnabled == 1)
	{
		HookEvent("player_hurt", Event_PlayerFire);
	}
}

public CvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[]) {
    if ( cvar == gCvarEnabled ) {
        gEnabled = GetConVarBool(gCvarEnabled);
        if ( gEnabled ) {
	HookEvent("player_hurt", Event_PlayerFire);
        } else {
	UnhookEvent("player_hurt", Event_PlayerFire);
        }
        return;
    }
}

CreateExplosion(client, Float:pos[3], attacked) {
    if(client != attacked) {
	new ent = CreateEntityByName("env_explosion");
	DispatchKeyValue(ent, "spawnflags", "1");
	DispatchSpawn(ent);

	GetClientAbsOrigin(attacked, pos);
	SetVariantString("!activator");
	SetVariantString("rfoot");

	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(ent);
	AcceptEntityInput(ent, "explode");
    }
}

public Event_PlayerFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:weapon[128];

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if  ( StrEqual(weapon, "knife") && ZR_IsClientZombie(attacker)) {
		new Float:vec[3];
		GetClientAbsOrigin(victim, vec);
		if(attacker != victim) {
			CreateExplosion(attacker, vec,victim);
		}
	}
}
