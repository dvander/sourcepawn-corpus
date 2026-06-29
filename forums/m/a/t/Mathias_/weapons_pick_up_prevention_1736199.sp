#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
    name = "Weapon pick up prevention",
    author = "Nigty's (credits: blodia, PowerLord)",
    description = "Prevent players to picking up weapon throug objects, entities or any kind of collision between the player and the weapon.",
    version = "1.0",
    url = "www.alliedmods.net"
}

public OnPluginStart()
{
    for (new client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client))
        {
            OnClientPutInServer(client);
        }
    }
}

public OnPluginEnd()
{
    for (new client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client))
        {
            OnClientDisconnect_Post(client);
        }
    }
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public OnClientDisconnect_Post(client)
{
    SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action:OnWeaponCanUse(client, weapon)
{
    decl Float:clientOrigin[3];
    decl Float:entityOrigin[3];

    GetClientAbsOrigin(client, clientOrigin);
    GetEntPropVector(weapon, Prop_Send, "m_vecOrigin", entityOrigin);

    
    new Handle:data = CreateDataPack();

    WritePackCell(data, client);
    WritePackCell(data, weapon);
    
    
    new Handle:trace = TR_TraceRayFilterEx(clientOrigin, entityOrigin, MASK_SOLID, RayType_EndPoint, Filter_ClientSelf, data);

    if (TR_DidHit(trace))
    {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public bool:Filter_ClientSelf(entity, contentsMask, any:data)
{
    ResetPack(data);

    new client = ReadPackCell(data);
    new weapon = ReadPackCell(data);
    
    if (entity != client && entity != weapon)
    {
        return true;
    }
    return false;
}  