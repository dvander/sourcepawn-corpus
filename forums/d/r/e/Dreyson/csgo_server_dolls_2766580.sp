#define PLUGIN_NAME "[CSGO] Server Ragdolls"
#define PLUGIN_AUTHOR "Dreyson"
#define PLUGIN_DESC "Replaces the usual client-sided ragdolls with server-sided ones."
#define PLUGIN_VERSION "1.1.0"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESC,
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    ConVar hTempCvar = CreateConVar("sm_server_dolls_version", PLUGIN_VERSION, "plugin's version.", FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
    if (hTempCvar != null)
    {
        hTempCvar.SetString(PLUGIN_VERSION);
    }
    
    HookEvent("player_death", player_death, EventHookMode_Pre);
    
    delete hTempCvar;
}

void CreateRagdoll(int client)
{
    int Ragdoll = CreateEntityByName("physics_prop_ragdoll");
    int prev_ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
    
    float m_vecPos[3], m_vecAng[3], m_vecDamageForce[3], m_vecRagdollVelocity[3];
    GetClientAbsOrigin(client, m_vecPos);
    GetClientAbsAngles(client, m_vecAng);
    
    DispatchKeyValue(Ragdoll, "spawnflags", "4");
    
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", m_vecRagdollVelocity);
    m_vecRagdollVelocity[0] *= 20;
    m_vecRagdollVelocity[1] *= 20;
    m_vecRagdollVelocity[2] *= 20;
    
    if (prev_ragdoll)
    {
        GetEntPropVector(prev_ragdoll, Prop_Send, "m_vecForce", m_vecDamageForce);
        m_vecDamageForce[0] *= 20;
        m_vecDamageForce[1] *= 20;
        m_vecDamageForce[2] *= 20;
        AcceptEntityInput(prev_ragdoll, "Kill");
        
        AddVectors(m_vecRagdollVelocity, m_vecDamageForce, m_vecRagdollVelocity);
    }
    
    char sModel[128];
    GetClientModel(client, sModel, sizeof(sModel));
    DispatchKeyValue(Ragdoll, "model", sModel);
    
    SetEntProp(Ragdoll, Prop_Send, "m_nForceBone", GetEntProp(client, Prop_Send, "m_nForceBone"));
    SetEntProp(Ragdoll, Prop_Send, "m_nModelIndex", GetEntProp(client, Prop_Send, "m_nModelIndex"));
    SetEntProp(Ragdoll, Prop_Send, "m_iTeamNum", GetClientTeam(client));
    SetEntPropEnt(client, Prop_Send, "m_hRagdoll", Ragdoll);
    
    DispatchSpawn(Ragdoll);
    ActivateEntity(Ragdoll);
    
    m_vecPos[2] -= 20; // Ragdolls tend to spawn mid air for some reason, we circumvent this by moving the origin down a lil.
    TeleportEntity(Ragdoll, m_vecPos, m_vecAng, m_vecRagdollVelocity);
}

void player_death(Event event, const char[] name, bool dontbroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client == 0 || IsPlayerAlive(client))
    {
        return;
    }
    
    CreateRagdoll(client);
}