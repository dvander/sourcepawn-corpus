#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools_tempents>

public Plugin:myinfo = {
    name = "Feign sniper kills",
    author = "Seta00",
    description = "Feign sniper kills with a configurable minimum distance",
    version = "1.0",
    url = "http://www.sourcemod.net/"
};

new bool:b_lateLoad;
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
    b_lateLoad = late;
    return APLRes_Success;
}

new Handle:cv_distance;
new Float:f_distance;
public OnPluginStart() {
    cv_distance = CreateConVar("sm_feignsniperkills_distance", "750", "Maximum distance between Sniper and victim for kills to register", _, true, 0.0);
    f_distance = GetConVarFloat(cv_distance);
    HookConVarChange(cv_distance, OnConVarChange);

    if (b_lateLoad) {
        for (new i = 1; i < MaxClients; ++i) {
            if (IsClientInGame(i)) {
                SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }
    }
}

public OnConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[]) {
    f_distance = GetConVarFloat(cv_distance);
}

public OnEntityCreated(entity, const String:classname[]) {
    if (!strcmp(classname, "player") || !strcmp(classname, "tf_bot")) {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
    if (victim < 1 || victim > MaxClients)
        return Plugin_Continue;

    new String:inflictingWeapon[32];
    GetClientWeapon(attacker, inflictingWeapon, sizeof inflictingWeapon);

    new Float:attackerOrigin[3], Float:victimOrigin[3];
    GetClientAbsOrigin(attacker, attackerOrigin);
    GetClientAbsOrigin(victim, victimOrigin);
    new Float:distance = GetVectorDistance(attackerOrigin, victimOrigin);

    if ((!strncmp(inflictingWeapon, "tf_weapon_sniperrifle", 21) || !strcmp(inflictingWeapon, "tf_weapon_compound_bow")) && distance > f_distance) {
        new Handle:newEvent = CreateEvent("player_death");
        if (newEvent != INVALID_HANDLE) {
            SetEventInt(newEvent, "userid", GetClientUserId(victim));
            SetEventInt(newEvent, "attacker", GetClientUserId(attacker));
            SetEventString(newEvent, "weapon", "sniperrifle");

            decl Float:victimPos[3];
            GetClientEyePosition(victim, victimPos);
            victimPos[2] += 4.0;

            if (damagetype & DMG_CRIT) {
                SetEventInt(newEvent, "customkill", TF_CUSTOM_HEADSHOT);
                TE_ParticleToClient(attacker, "crit_text", victimPos);
            } else {
                TE_ParticleToClient(attacker, "hit_text", damagePosition);
            }
            FireEvent(newEvent);
        }

        damage = 0.0;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

// stolen from Thrawn's tHeadshotOnly. yarrpen-source!
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
