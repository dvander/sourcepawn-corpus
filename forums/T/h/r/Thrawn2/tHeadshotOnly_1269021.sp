#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define VERSION 		"1.0.0.6"

new Handle:g_hCvarSniperRestrictedNoScope = INVALID_HANDLE;
new Handle:g_hCvarSniperRestricted = INVALID_HANDLE;
new Handle:g_hCvarHuntsmanRestricted = INVALID_HANDLE;
new Handle:g_hCvarAmbassadorRestricted = INVALID_HANDLE;
new Handle:g_hCvarSniperHeadshot = INVALID_HANDLE;
new Handle:g_hCvarHuntsmanHeadshot = INVALID_HANDLE;
new Handle:g_hCvarAmbassadorHeadshot = INVALID_HANDLE;

new Handle:g_hCvarShowMissedParticle = INVALID_HANDLE;


new Float:g_fSniperModifierNoScope;
new Float:g_fSniperModifier;
new Float:g_fHuntsmanModifier;
new Float:g_fAmbassadorModifier;
new Float:g_fSniperHeadModifier;
new Float:g_fHuntsmanHeadModifier;
new Float:g_fAmbassadorHeadModifier;

new bool:g_bShowMissedParticle;

public Plugin:myinfo =
{
	name = "tHeadshotOnly",
	author = "Thrawn",
	description = "Restricts certain weapons to headshots only. Uses SDKHooks.",
	version = VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_theadshotonly_version", VERSION, "[TF2] tHeadshotOnly", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	//Turn these down to limit body damage
	g_hCvarSniperRestricted = CreateConVar("sm_theadshotonly_sniper", "0.0", "Modifier for body-shot damage dealt by the sniper rifle", FCVAR_PLUGIN, true, 0.0);
	g_hCvarSniperRestrictedNoScope = CreateConVar("sm_theadshotonly_sniper_noscope", "1.0", "Modifier for body-shot damage dealt by the sniper rifle without zooming", FCVAR_PLUGIN, true, 0.0);
	g_hCvarHuntsmanRestricted = CreateConVar("sm_theadshotonly_huntsman", "0.0", "Modifier for body-shot damage dealt by the huntsman", FCVAR_PLUGIN, true, 0.0);
	g_hCvarAmbassadorRestricted = CreateConVar("sm_theadshotonly_ambassador", "1.0", "Modifier for body-shot damage dealt by the ambassador", FCVAR_PLUGIN, true, 0.0);

	//Turn these _up_ for instant headshot kills
	g_hCvarSniperHeadshot = CreateConVar("sm_theadshotonly_sniper_head", "1.0", "Modifier for head-shot damage dealt by the sniper rifle", FCVAR_PLUGIN, true, 0.0);
	g_hCvarHuntsmanHeadshot = CreateConVar("sm_theadshotonly_huntsman_head", "1.0", "Modifier for head-shot damage dealt by the huntsman", FCVAR_PLUGIN, true, 0.0);
	g_hCvarAmbassadorHeadshot = CreateConVar("sm_theadshotonly_ambassador_head", "1.0", "Modifier for head-shot damage dealt by the ambassador", FCVAR_PLUGIN, true, 0.0);

	g_hCvarShowMissedParticle = CreateConVar("sm_theadshotonly_particle", "1", "If enabled bodyshots with a 0.0 dmg modifier pop up 'miss' particles", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookConVarChange(g_hCvarSniperRestrictedNoScope, Cvar_Changed);
	HookConVarChange(g_hCvarSniperRestricted, Cvar_Changed);
	HookConVarChange(g_hCvarHuntsmanRestricted, Cvar_Changed);
	HookConVarChange(g_hCvarAmbassadorRestricted, Cvar_Changed);
	HookConVarChange(g_hCvarSniperHeadshot, Cvar_Changed);
	HookConVarChange(g_hCvarHuntsmanHeadshot, Cvar_Changed);
	HookConVarChange(g_hCvarAmbassadorHeadshot, Cvar_Changed);

	HookConVarChange(g_hCvarShowMissedParticle, Cvar_Changed);

	AutoExecConfig(true, "plugin.tHeadshotOnly");
}

public OnConfigsExecuted() {
	g_fSniperModifierNoScope = GetConVarFloat(g_hCvarSniperRestrictedNoScope);
	g_fSniperModifier = GetConVarFloat(g_hCvarSniperRestricted);
	g_fHuntsmanModifier = GetConVarFloat(g_hCvarHuntsmanRestricted);
	g_fAmbassadorModifier = GetConVarFloat(g_hCvarAmbassadorRestricted);

	g_fSniperHeadModifier = GetConVarFloat(g_hCvarSniperHeadshot);
	g_fHuntsmanHeadModifier = GetConVarFloat(g_hCvarHuntsmanHeadshot);
	g_fAmbassadorHeadModifier = GetConVarFloat(g_hCvarAmbassadorHeadshot);

	g_bShowMissedParticle = GetConVarBool(g_hCvarShowMissedParticle);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnClientPutInServer(client) {
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(attacker > 0 && attacker <= MaxClients) {
		if ((damagetype & DMG_SLASH))
			return Plugin_Continue;

		//Maybe add some class checks here
		//or better: only hook snipers and spies

		decl String:sWeapon[32]; decl String:sInflictor[32];
		GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
		GetEdictClassname(inflictor, sInflictor, sizeof(sInflictor));

		new bool:bNeedMissedParticle = false;
		new bool:bChanged = false;

		if (!(damagetype & DMG_ACID)) {
			//Bodyshots
			if(StrEqual(sWeapon, "tf_weapon_sniperrifle")) {
				if(TF2_GetPlayerConditionFlags(attacker) & TF_CONDFLAG_ZOOMED) {
					if(g_fSniperModifier != 1.0) {
						damage *= g_fSniperModifier;
						bChanged = true;
						if(g_fSniperModifier == 0.0)
							bNeedMissedParticle = true;
					}
				} else {
					if(g_fSniperModifierNoScope != 1.0) {
						damage *= g_fSniperModifierNoScope;
						bChanged = true;
						if(g_fSniperModifierNoScope == 0.0)
							bNeedMissedParticle = true;
					}
				}
			} else if(g_fHuntsmanModifier != 1.0 && StrEqual(sInflictor, "tf_projectile_arrow")) {
				damage *= g_fHuntsmanModifier;
				bChanged = true;
				if(g_fHuntsmanModifier == 0.0)
					bNeedMissedParticle = true;
			} else if(g_fAmbassadorModifier != 1.0 && StrEqual(sWeapon, "tf_weapon_revolver")) {
				if (inflictor > 0 && inflictor <= MaxClients && GetEntProp(GetPlayerWeaponSlot(inflictor, 0), Prop_Send, "m_iEntityQuality") == 3) {
					damage *= g_fAmbassadorModifier;
					bChanged = true;
					if(g_fAmbassadorModifier == 0.0)
						bNeedMissedParticle = true;
				}
			}
		} else {
			//Headshots
			if(g_fSniperHeadModifier != 1.0 && StrEqual(sWeapon, "tf_weapon_sniperrifle")) {
				damage *= g_fSniperHeadModifier;
				bChanged = true;
				if(g_fSniperHeadModifier == 0.0)
					bNeedMissedParticle = true;

			} else if(g_fHuntsmanHeadModifier != 1.0 && StrEqual(sInflictor, "tf_projectile_arrow")) {
				damage *= g_fHuntsmanHeadModifier;
				bChanged = true;
				if(g_fHuntsmanHeadModifier == 0.0)
					bNeedMissedParticle = true;
			} else if(g_fAmbassadorHeadModifier != 1.0 && StrEqual(sWeapon, "tf_weapon_revolver")) {
				if (inflictor > 0 && inflictor <= MaxClients && GetEntProp(GetPlayerWeaponSlot(inflictor, 0), Prop_Send, "m_iEntityQuality") == 3) {
					damage *= g_fAmbassadorHeadModifier;
					bChanged = true;
					if(g_fAmbassadorHeadModifier == 0.0)
						bNeedMissedParticle = true;
				}
			}
		}

		if(bChanged) {
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