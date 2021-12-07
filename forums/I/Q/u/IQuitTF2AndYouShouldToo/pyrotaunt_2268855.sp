#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.2"

public Plugin:myinfo =
{
    name = "Pyro Taunt Hadouken Redux",
    author = "Tec Dicas (original by TonyBaretta)",
    description = "Hudda Hudda Huh",
    version = PLUGIN_VERSION,
    url = "http://www.tecdicas.com/"
}

public OnPluginStart()
{
	CreateConVar("sm_pyrotaunt_version", PLUGIN_VERSION, "Show Pyro Taunt Hadouken Redux version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnEntityCreated(entity, const String:classname[])
{
    if (!StrEqual(classname, "instanced_scripted_scene", false)) return;
    SDKHook(entity, SDKHook_Spawn, OnSceneSpawned);
}

public Action:OnSceneSpawned(entity)
{
    new client = GetEntPropEnt(entity, Prop_Data, "m_hOwner"), String:scenefile[128];
    GetEntPropString(entity, Prop_Data, "m_iszSceneFile", scenefile, sizeof(scenefile));
    if ((GetEntityFlags(client) & FL_ONGROUND) ) 
    {
        if (StrEqual(scenefile, "scenes/player/pyro/low/taunt02.vcd"))
        {
            if (isValidClient(client)) 
            {
                TF2_AddCondition(client, TFCond_MarkedForDeath, 1.9);
                TF2_AddCondition(client, TFCond_Teleporting, 1.9);
                TF2_AddCondition(client, TFCond_TeleportedGlow, 1.9);
                
                CreateTimer(1.9, FireBall, client);
            }
        }
    }
    return Plugin_Continue;
}

public Action:FireBall(Handle:timer, any:client){
    if (isValidClient(client))
    {
        new Float:vPosition[3];
        new Float:vAngles[3];
        vAngles[2] += 25.0;
        new iTeam = GetClientTeam(client);
        GetClientEyePosition(client, vPosition);
        GetClientEyeAngles(client, vAngles);
        RocketsGameFired(client, vPosition, vAngles, 1300.0, 800.0, iTeam, false);
    }
    return Plugin_Handled;
}

public RocketsGameFired(client, Float:vPosition[3], Float:vAngles[3], Float:flSpeed, Float:flDamage, iTeam, bool:bCritical){
    new iRocket = CreateEntityByName("tf_projectile_energy_ball");
    if(!IsValidEntity(iRocket)) return -0;
    decl Float:vVelocity[3];
    decl Float:vBuffer[3];
    GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
    vVelocity[0] = vBuffer[0]*flSpeed;
    vVelocity[1] = vBuffer[1]*flSpeed;
    vVelocity[2] = vBuffer[2]*flSpeed;
    TeleportEntity(iRocket, vPosition, vAngles, vVelocity);
    SetEntData(iRocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iTeamNum"), GetClientTeam(client), true);
    SetEntData(iRocket, FindSendPropOffs("CTFProjectile_Rocket", "m_bCritical"), bCritical, true);
    SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", client);
    SetEntDataFloat(iRocket, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, flDamage, true);
    SetVariantInt(iTeam);
    AcceptEntityInput(iRocket, "TeamNum", -1, -1, 0);
    SetVariantInt(iTeam);
    AcceptEntityInput(iRocket, "SetTeam", -1, -1, 0); 
    DispatchSpawn(iRocket);
    return iRocket;
}


stock bool:isValidClient(client)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
    if (!IsPlayerAlive(client)) return false;
    if (TF2_GetPlayerClass(client) != TFClass_Pyro) return false;
    return true;
}
