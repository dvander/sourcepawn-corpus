#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
 
#define DEBUG
 
static const String:MODEL_NICK[] = "models/survivors/survivor_gambler.mdl";
static const String:MODEL_ROCHELLE[] = "models/survivors/survivor_producer.mdl";
static const String:MODEL_COACH[] = "models/survivors/survivor_coach.mdl";
static const String:MODEL_ELLIS[] = "models/survivors/survivor_mechanic.mdl";
static const String:MODEL_BILL[] = "models/survivors/survivor_namvet.mdl";
static const String:MODEL_ZOEY[] = "models/survivors/survivor_teenangst.mdl";
static const String:MODEL_FRANCIS[] = "models/survivors/survivor_biker.mdl";
static const String:MODEL_LOUIS[] = "models/survivors/survivor_manager.mdl";
 
static PreviousAnimation[MAXPLAYERS + 1] = -1;
static CloneModel[MAXPLAYERS + 1] = -1;
static bool:ThirdPerson[MAXPLAYERS + 1] = false;
new PropOff_nSequence;
 
public Plugin myinfo =
{
        name = "[L4D2] View Legs",
        author = "[†×Ą]AYA SUPAY[Ļ×Ø]/DeathChaos",
        description = "Show legs in first person",
        version = "1.0",
        url = "http://steamcommunity.com/id/AyaSupay/"
};
 
public void OnPluginStart()
{
        PropOff_nSequence = FindSendPropInfo("CTerrorPlayer", "m_nSequence");
        CreateTimer(GetRandomFloat(0.1, 0.3), CheckClients, _, TIMER_REPEAT);
        RegConsoleCmd("sm_view", ViewAngles);
        RegConsoleCmd("sm_ang", ChangeAngles);
        RegConsoleCmd("sm_pos", ChangePosition);
}
public OnMapStart()
{
        CheckModelPreCache(MODEL_NICK);
        CheckModelPreCache(MODEL_ROCHELLE);
        CheckModelPreCache(MODEL_COACH);
        CheckModelPreCache(MODEL_ELLIS);
        CheckModelPreCache(MODEL_BILL);
        CheckModelPreCache(MODEL_ZOEY);
        CheckModelPreCache(MODEL_FRANCIS);
        CheckModelPreCache(MODEL_LOUIS);
}
stock CheckModelPreCache(const String:Modelfile[])
{
        if (!IsModelPrecached(Modelfile))
        {
                PrecacheModel(Modelfile, true);
                PrintToServer("Precaching Model:%s", Modelfile);
        }
}
public void OnGameFrame()
{
        for (new client = 1; client <= MaxClients; client++)
        {
                if (IsSurvivor(client) && !IsFakeClient(client) && IsPlayerAlive(client))
                {
                        new sequence = GetEntData(client, PropOff_nSequence);
                        if (CloneModel[client] <= 0 || !IsValidEntity(CloneModel[client]))
                        {
                                new clone = CreateEntityByName("prop_dynamic_override");
                                decl String:model[64];
                                GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
                                if (StrContains(model, "gambler", false) != -1)
                                {
                                        SetEntityModel(clone, MODEL_NICK);
                                }
                                else if (StrContains(model, "coach", false) != -1)
                                {
                                        SetEntityModel(clone, MODEL_COACH);
                                }
                                else if (StrContains(model, "producer", false) != -1)
                                {
                                        SetEntityModel(clone, MODEL_ROCHELLE);
                                }
                                else if (StrContains(model, "mechanic", false) != -1)
                                {
                                        SetEntityModel(clone, MODEL_ELLIS);
                                }
                                else if (StrContains(model, "namvet", false) != -1)
                                {
                                        SetEntityModel(clone, MODEL_BILL);
                                }
                                else if (StrContains(model, "teenangst", false) != -1)
                                {
                                        SetEntityModel(clone, MODEL_ZOEY);
                                }
                                else if (StrContains(model, "biker", false) != -1)
                                {
                                        SetEntityModel(clone, MODEL_FRANCIS);
                                }
                                else if (StrContains(model, "manager", false) != -1)
                                {
                                        SetEntityModel(clone, MODEL_LOUIS);
                                }
                                else
                                {
                                        AcceptEntityInput(clone, "Kill");
                                        LogError("Player Model %s is not supported!", model);
                                }
                                decl Float:vAngles[3];
                                decl Float:vOrigin[3];
                                GetClientAbsOrigin(client, vOrigin);
                                GetClientAbsAngles(client, vAngles);
                               
                                SetEntProp(clone, Prop_Data, "m_CollisionGroup", 2);
                                decl String:sTemp[16];
                                Format(sTemp, sizeof(sTemp), "target%d", client);
                                DispatchKeyValue(client, "targetname", sTemp);
                                SetVariantString(sTemp);
                                AcceptEntityInput(clone, "SetParent", clone, clone, 0);
                               
                                SetVariantString("bleedout");
                                AcceptEntityInput(clone, "SetParentAttachment");
                               
                                SetEntPropFloat(clone, Prop_Send, "m_flPlaybackRate", GetEntPropFloat(client, Prop_Send, "m_flPlaybackRate"));
                                SetEntData(clone, PropOff_nSequence, sequence);
                               
                                CloneModel[client] = clone;
                                //ang -80 0 -90
                                //pos -10 -40 -20
                                new Float:pos[3], Float:ang[3];
                                ang[0] = -80.0;
                                ang[1] = 0.0;
                                ang[2] = -90.0;
                               
                                pos[0] = -10.0;
                                pos[1] = -40.0;
                                pos[2] = -20.0;
                                TeleportEntity(CloneModel[client], pos, ang, NULL_VECTOR);
                                SDKHook(clone, SDKHook_SetTransmit, Hook_SetTransmit);
                        }
                       
                        if (!PreviousAnimation[client])
                        {
                                PreviousAnimation[client] = sequence;
                        }
                        else if (PreviousAnimation[client] != sequence && PreviousAnimation[client] > 0)
                        {
                                new Float:angs[3];
                                GetEntPropVector(client, Prop_Send, "m_angRotation", angs);
                                SetEntPropFloat(CloneModel[client], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(client, Prop_Send, "m_flPlaybackRate"));
                                SetEntData(CloneModel[client], PropOff_nSequence, sequence);
                                for (new i = 0; i < 92; i += 4)
                                {
                                        new prop = FindSendPropInfo("CTerrorPlayer", "m_flPoseParameter");
                                        new prop2 = FindSendPropInfo("CDynamicProp", "m_flPoseParameter");
                                        new value = GetEntData(client, prop + (i));
                                       
                                        SetEntData(CloneModel[client], prop2 + (i), value);
                                }
                                SetEntPropFloat(CloneModel[client], Prop_Send, "m_flCycle", GetEntPropFloat(client, Prop_Send, "m_flCycle"));
                        }
                }
        }
}
 
stock bool:IsSurvivor(client)
{
        return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}
 
SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
        target[0] = x;
        target[1] = y;
        target[2] = z;
}
 
public Action:ViewAngles(client, args)
{
        new Float:angles[3];
        GetEntPropVector(CloneModel[client], Prop_Send, "m_vecAngles", angles);
        PrintToChatAll("%f %f %f", angles[0], angles[1], angles[2]);
}
 
public Action:ChangeAngles(client, args)
{
        new String:buffer[32];
        new Float:x, Float:y, Float:z, Float:ang[3];
       
        GetCmdArg(1, buffer, sizeof(buffer));
        x = StringToFloat(buffer);
       
        GetCmdArg(2, buffer, sizeof(buffer));
        y = StringToFloat(buffer);
       
        GetCmdArg(3, buffer, sizeof(buffer));
        z = StringToFloat(buffer);
       
        SetVector(ang, x, y, z);
       
        if (CloneModel[client] > 0 && IsValidEntS(CloneModel[client], "prop_dynamic_override"))
        {
                TeleportEntity(CloneModel[client], NULL_VECTOR, ang, NULL_VECTOR);
        }
}
 
public Action:ChangePosition(client, args)
{
        new String:buffer[32];
        new Float:x, Float:y, Float:z, Float:ang[3];
       
        GetCmdArg(1, buffer, sizeof(buffer));
        x = StringToFloat(buffer);
       
        GetCmdArg(2, buffer, sizeof(buffer));
        y = StringToFloat(buffer);
       
        GetCmdArg(3, buffer, sizeof(buffer));
        z = StringToFloat(buffer);
       
        SetVector(ang, x, y, z);
       
        if (CloneModel[client] > 0 && IsValidEntS(CloneModel[client], "prop_dynamic_override"))
        {
                TeleportEntity(CloneModel[client], ang, NULL_VECTOR, NULL_VECTOR);
        }
}
 
IsValidEntS(ent, String:classname[64])
{
        if (IsValidEnt(ent))
        {
                decl String:name[64];
                GetEdictClassname(ent, name, 64);
                if (StrEqual(classname, name))
                {
                        return true;
                }
        }
        return false;
}
 
IsValidEnt(ent)
{
        if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
        {
                return true;
        }
        return false;
}
 
public Action:Hook_SetTransmit(entity, client)
{
        if(!IsSurvivor(client))
        {
                return Plugin_Handled;
        }
        if (entity != CloneModel[client] || GetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView") > 0.0
        || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 1 || IsPlayerHeld(client) || IsIncapacitated(client) || ThirdPerson[client])
        {
                return Plugin_Handled;
        }
        return Plugin_Continue;
}
 
stock bool:IsPlayerHeld(client)
{
        new jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
        new charger = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
        new hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
        new smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
        if (jockey > 0 || charger > 0 || hunter > 0 || smoker > 0)
        {
                return true;
        }
        return false;
}
stock bool:IsIncapacitated(client)
{
        if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0)
                return true;
        return false;
}
 
public Action:CheckClients(Handle:timer)
{
        for (new iClientIndex = 1; iClientIndex <= MaxClients; iClientIndex++)
        {
                if (IsClientInGame(iClientIndex) && !IsFakeClient(iClientIndex))
                {
                        if (GetClientTeam(iClientIndex) == 2 || GetClientTeam(iClientIndex) == 3) // Only query clients on survivor or infected team, ignore spectators.
                        {
                                QueryClientConVar(iClientIndex, "c_thirdpersonshoulder", QueryClientConVarCallback);
                        }
                }
        }
}
 
public QueryClientConVarCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
        if (IsClientInGame(client) && !IsClientInKickQueue(client))
        {
                if (result != ConVarQuery_Okay)
                {
                        ThirdPerson[client] = true;
                }
                else if (!StrEqual(cvarValue, "false") && !StrEqual(cvarValue, "0"))
                {
                        ThirdPerson[client] = true;
                }
                else ThirdPerson[client] = false;
        }
}