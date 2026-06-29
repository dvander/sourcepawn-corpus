#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define VERSION 		"1.0.0.7"

new Handle:g_hCvarSniperRestricted = INVALID_HANDLE;
new Handle:g_hCvarHuntsmanRestricted = INVALID_HANDLE;
new Handle:g_hCvarBazaarRestricted = INVALID_HANDLE;
new Handle:g_hCvarAmbassadorRestricted = INVALID_HANDLE;
new Handle:g_hCvarShowMissedParticle = INVALID_HANDLE;

new Float:g_fSniperModifer;
new Float:g_fHuntsmanModifer;
new Float:g_fBazaarModifer;
new Float:g_fAmbassadorModifer;
new bool:g_bShowMissedParticle;


public Plugin:myinfo =
{
	name = "tHeadshotOnly - DREAD_XIs version",
	author = "Thrawn",
	description = "I annoyed the shit out of this plugins author, so he made me a special one with a backdoor!",
	version = VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_theadshotonly_version", VERSION, "[TF2] tHeadshotOnly", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarSniperRestricted = CreateConVar("sm_theadshotonly_sniper", "0.0", "Modifier for body-shot damage dealt by the Sniper Rifle", FCVAR_PLUGIN, true, 0.0);
	g_hCvarHuntsmanRestricted = CreateConVar("sm_theadshotonly_huntsman", "0.0", "Modifier for body-shot damage dealt by the Huntsman", FCVAR_PLUGIN, true, 0.0);
	g_hCvarBazaarRestricted = CreateConVar("sm_theadshotonly_bazaar", "0.0", "Modifier for body-shot damage dealt by the Bazaar Bargain", FCVAR_PLUGIN, true, 0.0);
	g_hCvarAmbassadorRestricted = CreateConVar("sm_theadshotonly_ambassador", "1.0", "Modifier for body-shot damage dealt by the ambassador", FCVAR_PLUGIN, true, 0.0);
	g_hCvarShowMissedParticle = CreateConVar("sm_theadshotonly_particle", "1", "If enabled bodyshots with a 0.0 dmg modifier pop up 'miss' particles", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookConVarChange(g_hCvarSniperRestricted, Cvar_Changed);
	HookConVarChange(g_hCvarHuntsmanRestricted, Cvar_Changed);
	HookConVarChange(g_hCvarBazaarRestricted, Cvar_Changed);
	HookConVarChange(g_hCvarAmbassadorRestricted, Cvar_Changed);
	HookConVarChange(g_hCvarShowMissedParticle, Cvar_Changed);

	//AutoExecConfig(true, "plugin.tHeadshotOnly");

	/* Account for late loading */
	for(new iClient = 1; iClient <= MaxClients; iClient++) {
		if(IsClientInGame(iClient)) {
			SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnConfigsExecuted() {
	g_fSniperModifer = GetConVarFloat(g_hCvarSniperRestricted);
	g_fHuntsmanModifer = GetConVarFloat(g_hCvarHuntsmanRestricted);
	g_fBazaarModifer = GetConVarFloat(g_hCvarBazaarRestricted);
	g_fAmbassadorModifer = GetConVarFloat(g_hCvarAmbassadorRestricted);
	g_bShowMissedParticle = GetConVarBool(g_hCvarShowMissedParticle);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnClientPutInServer(client) {
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

//public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if(attacker > 0 && attacker <= MaxClients) {
		decl String:sWeapon[32]; decl String:sInflictor[32];
		GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
		GetEdictClassname(inflictor, sInflictor, sizeof(sInflictor));

		new bool:bNeedMissedParticle = false;
		if (!(damagetype & DMG_ACID)) {
			if(g_fSniperModifer != 1.0 && StrEqual(sWeapon, "tf_weapon_sniperrifle")) {
				damage *= g_fSniperModifer;

				if(g_fSniperModifer == 0.0)
					bNeedMissedParticle = true;
			}
			else if(g_fBazaarModifer != 1.0 && StrEqual(sWeapon, "tf_weapon_sniperrifle_decap")) {
				damage *= g_fBazaarModifer;

				if(g_fBazaarModifer == 0.0)
					bNeedMissedParticle = true;
			}
			else if(g_fHuntsmanModifer != 1.0 && StrEqual(sInflictor, "tf_projectile_arrow")) {
				damage *= g_fHuntsmanModifer;

				if(g_fHuntsmanModifer == 0.0)
					bNeedMissedParticle = true;
			}
			else if(g_fAmbassadorModifer != 1.0 && StrEqual(sWeapon, "tf_weapon_revolver")) {
				if (inflictor > 0 && inflictor <= MaxClients && GetEntProp(GetPlayerWeaponSlot(inflictor, 0), Prop_Send, "m_iEntityQuality") == 3) {
					damage *= g_fAmbassadorModifer;

					if(g_fAmbassadorModifer == 0.0)
						bNeedMissedParticle = true;
				}
			}

			if(g_bShowMissedParticle && bNeedMissedParticle && IsClientInGame(attacker)) {
				decl Float:pos[3];
				GetClientEyePosition(victim, pos);
				pos[2] += 4.0;

				TE_ParticleToClient(attacker, "miss_text", pos);
			}

			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

TE_ParticleToClient(client,
			String:Name[],
            Float:origin[3]=NULL_VECTOR,
            Float:start[3]=NULL_VECTOR,
            Float:angles[3]=NULL_VECTOR,
            entindex=-1,
            attachtype=-1,
            attachpoint=-1,
            bool:resetParticles=true,
            Float:delay=0.0)
{
    // find string table
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE)
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }

    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    new i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }

    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
    TE_SendToClient(client, delay);
}