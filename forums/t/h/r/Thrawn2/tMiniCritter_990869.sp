#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0.0"

public Plugin:myinfo = {
	name = "tMiniCritter",
	author = "Thrawn",
	description = "Turns crit to minicrits.",
	version = PLUGIN_VERSION,
	url = "http://aaa.einfachonline.net/"
}

new Handle:g_hCvarEnable;
new bool:g_bEnable;

new g_m_nPlayerCond;
new g_iParticleIndex;

public OnPluginStart() {
	CreateConVar("sm_tminicritter_version", PLUGIN_VERSION, "Version of tMiniCritter plugin.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);
	g_hCvarEnable = CreateConVar("sm_tminicritter_enable", "1", "Convert all crits to minicrits", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	
	HookConVarChange(g_hCvarEnable, Cvar_regenenable);
	
	g_m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond");
}

public OnConfigsExecuted() {
	g_bEnable = GetConVarBool(g_hCvarEnable);
}

public Cvar_regenenable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnable = GetConVarBool(g_hCvarEnable);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnMapStart()
{
	new particles = FindStringTable("ParticleEffectNames");

	decl String:tmp[13]; new i;
	for (i = 0; i < GetStringTableNumStrings(particles); i++)
	{
		ReadStringTable(particles, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, "minicrit_text", false))
			break;
	}
	
	g_iParticleIndex = i;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{	
	if (g_bEnable && attacker > 0)
	{
		if (damagetype & DMG_ACID)
		{		
			//Hit is critical
			new cond = GetEntData(attacker, g_m_nPlayerCond);
		
			if (!(cond & 2048))
			{
				//Not ubered with Kritzkrieg
				new particle = CreateEntityByName("info_particle_system");

				if (IsValidEdict(particle))
				{
					/*
					//moved to OnMapStart, possible?
					new particles = FindStringTable("ParticleEffectNames");

					decl String:tmp[13];
					for (new i = 0; i < GetStringTableNumStrings(particles); i++)
					{
						ReadStringTable(particles, i, tmp, sizeof(tmp));
						if (StrEqual(tmp, "minicrit_text", false))
							break;
					}
					*/
					
					if(IsClientInGame(attacker))
					{
						decl Float:pos[3];
						GetClientEyePosition(victim, pos);
						pos[2] += 4.0;

						TE_Start("TFParticleEffect");
						TE_WriteFloat("m_vecOrigin[0]", pos[0]);
						TE_WriteFloat("m_vecOrigin[1]", pos[1]);
						TE_WriteFloat("m_vecOrigin[2]", pos[2]);
						TE_WriteNum("m_iParticleSystemIndex", g_iParticleIndex);
						TE_WriteNum("m_bResetParticles", true);

						TE_SendToClient(attacker);
					}
					
					damage *= 0.5;

					return Plugin_Changed;
				}	
			}
		}
	}
	
	return Plugin_Continue;
}