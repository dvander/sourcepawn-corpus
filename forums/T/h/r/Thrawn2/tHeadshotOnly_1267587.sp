#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define VERSION 		"1.0.0.5"

new Handle:g_hCvarSniperRestricted = INVALID_HANDLE;
new Handle:g_hCvarHuntsmanRestricted = INVALID_HANDLE;
new Handle:g_hCvarAmbassadorRestricted = INVALID_HANDLE;
new Handle:g_hCvarSniperHeadshot = INVALID_HANDLE;
new Handle:g_hCvarHuntsmanHeadshot = INVALID_HANDLE;
new Handle:g_hCvarAmbassadorHeadshot = INVALID_HANDLE;

new Handle:g_hCvarShowMissedParticle = INVALID_HANDLE;
new Handle:g_hCvarHeadModifierOnlyZoomed = INVALID_HANDLE;

new Float:g_fSniperModifer;
new Float:g_fHuntsmanModifer;
new Float:g_fAmbassadorModifer;
new Float:g_fSniperHeadModifer;
new Float:g_fHuntsmanHeadModifer;
new Float:g_fAmbassadorHeadModifer;

new bool:g_bShowMissedParticle;
new bool:g_bHeadModifierOnlyZoomed;

public Plugin:myinfo =
{
	name = "tHeadshotOnly",
	author = "Thrawn",
	description = "Restricts certain weapons to headshots only. Uses SDKHooks.",
	version = VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_theadshotonly_version", VERSION, "[TF2] tHeadshotOnly", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarSniperRestricted = CreateConVar("sm_theadshotonly_sniper", "0.0", "Modifier for body-shot damage dealt by the sniper rifle", FCVAR_PLUGIN, true, 0.0);
	g_hCvarHuntsmanRestricted = CreateConVar("sm_theadshotonly_huntsman", "0.0", "Modifier for body-shot damage dealt by the huntsman", FCVAR_PLUGIN, true, 0.0);
	g_hCvarAmbassadorRestricted = CreateConVar("sm_theadshotonly_ambassador", "1.0", "Modifier for body-shot damage dealt by the ambassador", FCVAR_PLUGIN, true, 0.0);
	g_hCvarSniperHeadshot = CreateConVar("sm_theadshotonly_sniper_head", "1.0", "Modifier for head-shot damage dealt by the sniper rifle", FCVAR_PLUGIN, true, 0.0);
	g_hCvarHuntsmanHeadshot = CreateConVar("sm_theadshotonly_huntsman_head", "1.0", "Modifier for head-shot damage dealt by the huntsman", FCVAR_PLUGIN, true, 0.0);
	g_hCvarAmbassadorHeadshot = CreateConVar("sm_theadshotonly_ambassador_head", "1.0", "Modifier for head-shot damage dealt by the ambassador", FCVAR_PLUGIN, true, 0.0);

	g_hCvarHeadModifierOnlyZoomed = CreateConVar("sm_theadshotonly_sniper_head_onlyzoomed", "1", "If enabled extra head damage only applies when zoomed (rifle only)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarShowMissedParticle = CreateConVar("sm_theadshotonly_particle", "1", "If enabled bodyshots with a 0.0 dmg modifier pop up 'miss' particles", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookConVarChange(g_hCvarSniperRestricted, Cvar_Changed);
	HookConVarChange(g_hCvarHuntsmanRestricted, Cvar_Changed);
	HookConVarChange(g_hCvarAmbassadorRestricted, Cvar_Changed);
	HookConVarChange(g_hCvarSniperHeadshot, Cvar_Changed);
	HookConVarChange(g_hCvarHuntsmanHeadshot, Cvar_Changed);
	HookConVarChange(g_hCvarAmbassadorHeadshot, Cvar_Changed);

	HookConVarChange(g_hCvarHeadModifierOnlyZoomed, Cvar_Changed);
	HookConVarChange(g_hCvarShowMissedParticle, Cvar_Changed);

	AutoExecConfig(true, "plugin.tHeadshotOnly");
}

public OnConfigsExecuted() {
	g_fSniperModifer = GetConVarFloat(g_hCvarSniperRestricted);
	g_fHuntsmanModifer = GetConVarFloat(g_hCvarHuntsmanRestricted);
	g_fAmbassadorModifer = GetConVarFloat(g_hCvarAmbassadorRestricted);

	g_fSniperHeadModifer = GetConVarFloat(g_hCvarSniperHeadshot);
	g_fHuntsmanHeadModifer = GetConVarFloat(g_hCvarHuntsmanHeadshot);
	g_fAmbassadorHeadModifer = GetConVarFloat(g_hCvarAmbassadorHeadshot);

	g_bShowMissedParticle = GetConVarBool(g_hCvarShowMissedParticle);
	g_bHeadModifierOnlyZoomed = GetConVarBool(g_hCvarHeadModifierOnlyZoomed);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnClientPutInServer(client) {
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(attacker > 0 && attacker <= MaxClients) {
		decl String:sWeapon[32]; decl String:sInflictor[32];
		GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
		GetEdictClassname(inflictor, sInflictor, sizeof(sInflictor));

		new bool:bNeedMissedParticle = false;
		new bool:bChanged = false;

		if ((damagetype & DMG_SLASH))
			return Plugin_Continue;


		if (!(damagetype & DMG_ACID)) {
			if(g_fSniperModifer != 1.0 && StrEqual(sWeapon, "tf_weapon_sniperrifle")) {
				damage *= g_fSniperModifer;
				bChanged = true;
				if(g_fSniperModifer == 0.0)
					bNeedMissedParticle = true;
			} else if(g_fHuntsmanModifer != 1.0 && StrEqual(sInflictor, "tf_projectile_arrow")) {
				damage *= g_fHuntsmanModifer;
				bChanged = true;
				if(g_fHuntsmanModifer == 0.0)
					bNeedMissedParticle = true;
			} else if(g_fAmbassadorModifer != 1.0 && StrEqual(sWeapon, "tf_weapon_revolver")) {
				if (inflictor > 0 && inflictor <= MaxClients && GetEntProp(GetPlayerWeaponSlot(inflictor, 0), Prop_Send, "m_iEntityQuality") == 3) {
					damage *= g_fAmbassadorModifer;
					bChanged = true;
					if(g_fAmbassadorModifer == 0.0)
						bNeedMissedParticle = true;
				}
			}
		} else {
			if(g_fSniperHeadModifer != 1.0 && StrEqual(sWeapon, "tf_weapon_sniperrifle")) {
				if(g_bHeadModifierOnlyZoomed && !(TF2_GetPlayerConditionFlags(attacker) & TF_CONDFLAG_ZOOMED))
					return Plugin_Continue;

				damage *= g_fSniperHeadModifer;
				bChanged = true;
				if(g_fSniperHeadModifer == 0.0)
					bNeedMissedParticle = true;

			} else if(g_fHuntsmanHeadModifer != 1.0 && StrEqual(sInflictor, "tf_projectile_arrow")) {
				damage *= g_fHuntsmanHeadModifer;
				bChanged = true;
				if(g_fHuntsmanHeadModifer == 0.0)
					bNeedMissedParticle = true;
			} else if(g_fAmbassadorHeadModifer != 1.0 && StrEqual(sWeapon, "tf_weapon_revolver")) {
				if (inflictor > 0 && inflictor <= MaxClients && GetEntProp(GetPlayerWeaponSlot(inflictor, 0), Prop_Send, "m_iEntityQuality") == 3) {
					damage *= g_fAmbassadorHeadModifer;
					bChanged = true;
					if(g_fAmbassadorHeadModifer == 0.0)
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