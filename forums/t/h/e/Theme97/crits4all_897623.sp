#pragma semicolon 1

#include <sourcemod>
#include <dukehacks>
#include <sdktools>

public Plugin:myinfo = {
	name = "crits4all",
	author = "EnigmatiK",
	description = "Shows crits from other players.",
	version = "1.0",
	url = "http://http.www.com/"
}

new Handle:cvar_onlytoteam;

public OnPluginStart() {
	CreateConVar("crits_version", "1.0", "Version of crits4all plugin.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);
	cvar_onlytoteam = CreateConVar("crits_onlytoteam", "1", "Only shows Critical Hits to teammates.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	dhAddClientHook(CHK_TakeDamage, dh_takedamage);
}

public Action:dh_takedamage(client, attacker, inflicter, Float:dmg, &Float:multiplier, damagetype) {
	if ((damagetype & DMG_ACID) && 0 < attacker <= MaxClients && client != attacker) {
		new particle = CreateEntityByName("info_particle_system");
		if (IsValidEdict(particle)) {
			new particles = FindStringTable("ParticleEffectNames");
			new i, count = GetStringTableNumStrings(particles);
			decl String:tmp[11];
			for (i = 0; i < count; i++) {
				ReadStringTable(particles, i, tmp, sizeof(tmp));
				if (StrEqual(tmp, "crit_text", false)) break;
			}
			TE_Start("TFParticleEffect");
			decl Float:pos[3];
			GetClientEyePosition(client, pos);
			pos[2] += 4.0;
			TE_WriteFloat("m_vecOrigin[0]", pos[0]);
			TE_WriteFloat("m_vecOrigin[1]", pos[1]);
			TE_WriteFloat("m_vecOrigin[2]", pos[2]);
			TE_WriteNum("m_iParticleSystemIndex", i);
			TE_WriteNum("m_bResetParticles", true);
			decl clients[MaxClients];
			new num;
			for (new j = 1; j <= MaxClients; j++) {
				if (IsClientConnected(j) && IsClientInGame(j)) {
					if (!GetConVarBool(cvar_onlytoteam) || GetClientTeam(j) == GetClientTeam(attacker)) {
						if (j != attacker) clients[num++] = j;
					}
				}
			}
			TE_Send(clients, num);
		}
	}
	return Plugin_Continue;
}
