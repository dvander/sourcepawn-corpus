#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_NAME			    "l4d_common_lagfix"
#define PLUGIN_VERSION 			"1.04"
#define CONFIG_FILENAME         PLUGIN_NAME
#define DEBUG 0

public Plugin myinfo =
{
	name = "[L4D1/L4D2] Common Lagfix",
	author = "gvazdas, SilverShot",
	description = "Reduce lag due to dynamic load of materials for Common Infected on Linux servers.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2843590, https://knockout.chat/user/3022"
}

ArrayList g_AllModels; // all infected models
bool g_bClientsCached[MAXPLAYERS+1] = {true,...}; // check if already cached for client
int g_iModel[MAXPLAYERS+1]; // track model in cycle for client
int g_iCycle[MAXPLAYERS+1] = {-1,...}; // track cycle for client. -1 indicates they are not in cycle
int g_iInfectedRef[MAXPLAYERS+1]; // track infected entity assigned to client
ConVar g_hCvarCycles, g_hCvarGibs, g_hCvarNotify;

bool PVS_available; // PVS natives in l4dhooks

public void OnPluginStart()
{
	AutoExecConfig(true, CONFIG_FILENAME);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_PostNoCopy);
	g_hCvarCycles = CreateConVar("l4d_common_lagfix","5","How many times to repeat cycle. 0 to disable plugin.",FCVAR_NOTIFY,true,0.0,true,100.0);
	g_hCvarGibs = CreateConVar("l4d_common_lagfix_gibs","0","Include gib models in cycle. Probably not needed.",FCVAR_NOTIFY,true,0.0,true,1.0);
	g_hCvarNotify = CreateConVar("l4d_common_lagfix_notify","1","Print info to clients.",FCVAR_NOTIFY,true,0.0,true,1.0);
    RegAdminCmd("l4d_common_lagfix_reload", CmdReload, ADMFLAG_ROOT,"Reload modelprecache and force cycle on all clients. For debugging.");
}

public void OnAllPluginsLoaded()
{
    PVS_available = GetFeatureStatus(FeatureType_Native,"L4D_GetClusterForOrigin")==FeatureStatus_Available;
    if (!PVS_available) LogMessage("Please update l4dhooks to improve performance.");
}

Action CmdReload(int client, int args)
{
    OnMapStart();
    return Plugin_Continue;
}

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bClientsCached[i] = false;
	}
}

public void OnMapStart()
{
	RequestFrame(LoadModels);
}

void LoadModels()
{
	int table = FindStringTable("modelprecache");
	int total = GetStringTableNumStrings(table);
	static char sTemp[PLATFORM_MAX_PATH];
	delete g_AllModels;
	g_AllModels = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	for( int i = 0; i < total; i++ )
	{
		ReadStringTable(table, i, sTemp, sizeof(sTemp)); // "_w_ models appear to be gib related, i dont think they have this lag issue."
		if( strncmp(sTemp,"models/infected/common",22) == 0 && (g_hCvarGibs.BoolValue || StrContains(sTemp,"_w_",false)<0) )
		{
        	g_AllModels.PushString(sTemp);
        }
	}
	#if DEBUG
	LogMessage("modelprecache: %d models", g_AllModels.Length);
	#endif
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || IsFakeClient(i)) g_bClientsCached[i] = true;
		else
        {
            g_bClientsCached[i] = false;
            CreateTimer(0.1,Timer_CycleModels,GetClientUserId(i),TIMER_FLAG_NO_MAPCHANGE); // in game - start cycle immediately
        }
	}
}

public void OnClientPutInServer(int client) // player_spawn doesn't always happen. spectators, for example.
{
    if (!IsValidClient(client)) return;
    if(IsFakeClient(client))
    {
        g_bClientsCached[client] = true;
        return;
    }
    #if DEBUG
    LogMessage("OnClientPutInServer %d %f", client, GetEngineTime());
    #endif
    g_bClientsCached[client] = false;
    g_iCycle[client] = -1; // not cycling
    g_iModel[client] = 0;
    if (g_hCvarCycles.IntValue<=0) return;
    CreateTimer(6.0,Timer_CycleModels,GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE); // takes about 6 seconds to actually be put in game
    // actually this is non-sense, gives inconsistent results. sometimes servers hang for 30-40 seconds between campaigns. somebody with more brain cells should fix this
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hCvarCycles.IntValue<=0) return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client)) return;
	if (IsFakeClient(client)) g_bClientsCached[client] = true;
	if(g_bClientsCached[client] || g_iCycle[client]>=0) return; // skip if already cached or busy cycling
    #if DEBUG
	LogMessage("Event_PlayerSpawn %d %f", client, GetEngineTime());
	#endif
	CreateTimer(0.1,Timer_CycleModels,GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE); // in game - start cycle immediately
}

Action Timer_CycleModels(Handle timer, int userid)
{
    if (g_AllModels.Length <= 0) return Plugin_Stop;
    if (g_hCvarCycles.IntValue<=0) return Plugin_Stop;
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client)) return Plugin_Stop;
    if (IsFakeClient(client)) g_bClientsCached[client] = true;
    if(g_bClientsCached[client] || g_iCycle[client]>=0) return Plugin_Stop;
    g_iModel[client] = 0;
    g_iCycle[client] = 0;
    RequestFrame(CycleModels,userid);
    return Plugin_Stop;
}

#define TRY_RANDOM 20 // how many L4D_GetRandomPZSpawnPosition_PVS attempts

void CycleModels(int userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client) || IsFakeClient(client))
    {
        //g_bClientsCached[client] = true;
        cleanup_infected(); // client disappeared suddenly, find and delete loose infected entities.
        return;
    }
    int entref_infected = g_iInfectedRef[client];
    if (g_iModel[client]==0) // new zombie for new cycle
    {
        int cycle = g_iCycle[client];
        if (g_hCvarNotify.BoolValue && cycle<g_hCvarCycles.IntValue)
            PrintToChat(client, "[l4d_common_lagfix] Common Infected textures loading: %d/%d ...",
                        g_iCycle[client], g_hCvarCycles.IntValue);
        
        if (IsValidEntRef(entref_infected))
        {
            RemoveEntity(entref_infected);
            g_iInfectedRef[client] = INVALID_ENT_REFERENCE;
            entref_infected = INVALID_ENT_REFERENCE;
        }
    }
    if (g_iCycle[client]>=g_hCvarCycles.IntValue) // end of cycle
    {
        g_iCycle[client] = -1;
        g_bClientsCached[client] = true;
        if (g_hCvarNotify.BoolValue)
        {
            PrintHintText(client, "Common Infected textures loaded.");
            PrintToChat(client,"[l4d_common_lagfix] Common Infected textures loaded.");
        }
        return;
    }
    if (!IsValidEntRef(entref_infected))
    {
        static float vPos[3]; // zombie pos
        if (!L4D_GetRandomPZSpawnPosition_PVS(client,0,TRY_RANDOM,vPos))
        {
            #if DEBUG
            LogMessage("CycleModels %d failed random PVS location", client);
            #endif
            GetClientAbsOrigin(client,vPos);
            vPos[2] += 120.0;
        }
        if (vPos[0]==0.0 && vPos[1]==0.0 && vPos[2]==0.0) // avoid server crashing exploit
        {
            #if DEBUG
            LogMessage("pos 0.0 0.0 0.0, skipping cycle to avoid server crash.");
            #endif
            g_iCycle[client] = -1;
            return;
        }
        int infected = CreateEntityByName("infected");
        if (!IsValidEntity_Safe(infected))
        {
            g_iCycle[client] = -1;
            return;
        }
        SDKHook(infected, SDKHook_SetTransmit, OnTransmit);
        TeleportEntity(infected, vPos, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(infected);
        SetEntityRenderMode(infected,RENDER_NONE);
        SetEntPropFloat(infected,Prop_Send,"m_flModelScale",0.001); 
        SetEntProp(infected,Prop_Data,"m_takedamage",0);
        SetEntityMoveType(infected, MOVETYPE_NONE);
        SetEntProp(infected,Prop_Data,"m_iHealth",99999);
        SetEntProp(infected,Prop_Data,"m_iMaxHealth",99999);
        SetEntProp(infected,Prop_Data,"m_nNextThinkTick",-1);
        SetEntProp(infected, Prop_Data, "m_nSolidType", 0);
        //SetEntProp(infected, Prop_Data, "m_CollisionGroup", 1);
        entref_infected = EntIndexToEntRef(infected);
        g_iInfectedRef[client] = entref_infected; 
        #if DEBUG
        LogMessage("%d new infected %d %d (%.1f %.1f %.1f)", client, infected, entref_infected, vPos[0], vPos[1], vPos[2]);
        #endif
    }
    static char model[128];
    g_AllModels.GetString(g_iModel[client],model,sizeof(model));
    SetEntityModel(entref_infected, model);
    #if DEBUG
    LogMessage("%d %d %d %s", client, g_iCycle[client], g_iModel[client], model);
    #endif
    g_iModel[client] += 1;
    if (g_iModel[client]>=g_AllModels.Length) // if last model - begin new cycle.
    {
        g_iModel[client] = 0;
        g_iCycle[client] += 1;
    }
    RequestFrame(CycleModels,userid);
}

// Transmit only to clients who are known to need precaching.
Action OnTransmit(int entity, int client)
{
	if(g_bClientsCached[client]) return Plugin_Handled;
	return Plugin_Continue;
}

// A client disappeared in the middle of a cycle - find loose infected and remove them.
void cleanup_infected()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidEntRef(g_iInfectedRef[i])) continue;
        if ( g_iCycle[i]<0 || !IsValidClient(i) || IsFakeClient(i) )
        {
            #if DEBUG
            LogMessage("cleanup_infected %d %d", i, g_iInfectedRef[i]);
            #endif
            RemoveEntity(g_iInfectedRef[i]);
            g_iInfectedRef[i] = INVALID_ENT_REFERENCE;
            g_iCycle[i] = -1;
        }
    }
}

// wrapper for L4D_GetRandomPZSpawnPosition, with Potentially Visible Set (PVS) checks.
// on success, fills vecPos and returns true
stock bool L4D_GetRandomPZSpawnPosition_PVS(int client, int zombieClass, int attempts = TRY_RANDOM, float vecPos[3] = {0.0,0.0,0.0})
{
    if (!PVS_available) return false;
    static float pos[3];
    GetClientEyePosition(client,pos);
    int cluster = L4D_GetClusterForOrigin(pos);
    if (cluster<0) return false;
    static int PVS[PVS_BUFFER_SIZE];
    L4D_GetPVSForCluster(cluster,PVS);
    if (!L4D_CheckOriginInPVS(pos,PVS)) // Self-consistency check.
    {
        #if DEBUG
        LogMessage("client %d failed its own PVS check, cluster %d!!! CONSULT FIFTH PLANE OF REALITY ELDRITCH BEING JOHN CARMACK FOR FURTHER INSTRUCTIONS", client, cluster);
        #endif
        return false;
    }
    int i = 0; // number of tries
    while (i<attempts)
    {
        i += 1;
        if (!L4D_GetRandomPZSpawnPosition(client,zombieClass,1,vecPos)) continue;
        if (!L4D_CheckOriginInPVS(vecPos,PVS)) continue;
        return true;
    }
    return false;
}

stock bool IsValidEntRef(int entity)
{
	if( entity && entity != -1 && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;	
}

stock bool IsValidEntity_Safe(int entity)
{
	return ( entity && entity != INVALID_ENT_REFERENCE && IsValidEntity(entity) );
}

stock bool IsValidClient(int client, bool replaycheck = true)
{
	if (client<1 || client>MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}