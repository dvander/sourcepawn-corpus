#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.3"

new bool:Delay[MAXPLAYERS+1];
new propinfoghost = -1;
new Handle:enabled;
new bool:enabledhook;

public Plugin:myinfo = 

{
    name = "Distance Meter",
    author = "Olj | Mods & Consolidation by Dragonshadow",
    description = "Displays distance between hunter and any object while crouching",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=102612"
}

public OnPluginStart()
{
    CreateConVar("l4d_dmeter_version", PLUGIN_VERSION, "Version of Distance Meter", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    enabled = CreateConVar("l4d_dmeter_enabled", "1", "Enabled or Disabled | 1/0", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	HookConVarChange(enabled, Cvar_enabled);
}

public OnConfigsExecuted() {
    enabledhook = GetConVarBool(enabled);
} 

public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
    enabledhook = GetConVarBool(enabled);
}     
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3 
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(enabledhook) 
    {
        if (buttons & IN_DUCK && Delay[client] == false)
        {
            //           if (!IsValidClient(client)) return Plugin_Continue;
            //           if (GetClientTeam(client)!=3) return Plugin_Continue;
            //           if (IsPlayerGhost(client)) return Plugin_Continue;
            if(IsValidClient(client) && GetClientTeam(client)==3 && !IsPlayerGhost(client))
            {
                decl String:model[128];
                GetClientModel(client, model, sizeof(model));
                if (StrContains(model, "hunter", false)!=-1)
                {
                    Delay[client] = true;
                    CreateTimer(0.3, ResetDelay, client);
                    
                    decl Float:vAngles[3], Float:vOrigin[3], Float:vStart[3], Distance;
                    
                    GetClientEyePosition(client,vOrigin);
                    GetClientEyeAngles(client, vAngles);
                    
                    new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, client);
                    if(TR_DidHit(trace))
                    {        
                        TR_GetEndPosition(vStart, trace);
                        Distance = RoundToNearest(GetVectorDistance(vOrigin, vStart, false));
                        PrintCenterText(client, "%i", Distance);
						//PrintToChatAll("1.3 DM RUNNING");
                        CloseHandle(trace);
                    }
                    else CloseHandle(trace);
                }	
            }
        }
    }
    return 	Plugin_Continue;
}
#else
public OnGameFrame() 
{
    // running GetConVarBool every frame is not good... hook instead!
    if(enabledhook) 
    {
        for(new i=1;i<=MaxClients;i++) 
        {
            new buttons;
            if (buttons & IN_DUCK && Delay[i] == false)
            {
                if(IsValidClient(i) && GetClientTeam(i)==3 && !IsPlayerGhost(i))
                {
                    decl String:model[128];
                    GetClientModel(i, model, sizeof(model));
                    if (StrContains(model, "hunter", false)!=-1)
                    {

                        Delay[i] = true;
                        CreateTimer(0.3, ResetDelay, i);
                        
                        decl Float:vAngles[3], Float:vOrigin[3], Float:vStart[3], Distance;
                        
                        GetClientEyePosition(i,vOrigin);
                        GetClientEyeAngles(i, vAngles);
                        
                        new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, i);
                        if(TR_DidHit(trace))
                        {        
                            TR_GetEndPosition(vStart, trace);
                            Distance = RoundToNearest(GetVectorDistance(vOrigin, vStart, false));
                            PrintCenterText(i, "%i", Distance);
							//PrintToChatAll("1.2 DM RUNNING");
                            CloseHandle(trace);
                        }
                        else CloseHandle(trace);
                    }
                }
            }
        }
    }
}
#endif

public Action:ResetDelay(Handle:timer, Handle:client)
{
    Delay[client] = false;
}

public IsValidClient(client)
{
    if (client == 0)
    return false;
    
    if (!IsClientConnected(client))
    return false;
    
    if (IsFakeClient(client))
    return false;
    
    if (!IsClientInGame(client))
    return false;
    
    if (!IsPlayerAlive(client))
    return false;
    return true;
}				

bool:IsPlayerGhost(client)
{
    new isghost = GetEntData(client, propinfoghost, 1);
    
    if (isghost == 1) return true;
    else return false;
}			

/*public GetEntityAbsOrigin(entity,Float:origin[3]) {
    decl Float:mins[3], Float:maxs[3];

    GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
    GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
    GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);

    origin[0] += (mins[0] + maxs[0]) * 0.5;
    origin[1] += (mins[1] + maxs[1]) * 0.5;
    origin[2] += (mins[2] + maxs[2]) * 0.5;
}  */

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
    if(entity == data) // Check if the TraceRay hit the itself.
    {
        return false; // Don't let the entity be hit
    }
    return true; // It didn't hit itself
}