#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"
#define GAME_INFO "witch_attack"

Handle g_SDKCall_WitchHitByVomit;

ConVar
    cvar_witch_killincap;

bool
    g_witch_killincap;

ArrayList g_harasser;


public Plugin myinfo =
{
	name = "[L4D2] Smart Witch",
	author = "Miuwiki",
	description = "Witch change target who is the closed when kill/incapte one survivor.",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnPluginStart()
{
    HookEvent("round_start", Evetnt_RoundStart);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("witch_killed", Event_WitchKilled);
    HookEvent("player_incapacitated", Event_PlayerIncapacitated);
    HookEvent("witch_harasser_set", Event_WitchHarasserSet);
    LoadGameData();

    g_harasser = new ArrayList(2);
    cvar_witch_killincap = CreateConVar("l4d2_witch_killincap", "0", "witch kill the incap target before changing the other one.[0=close, 1=open]");
    cvar_witch_killincap.AddChangeHook(OnCvarChange);
}

public void OnConfigsExecuted()
{
    g_witch_killincap = cvar_witch_killincap.BoolValue;
}
void OnCvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_witch_killincap = cvar_witch_killincap.BoolValue;
}
void Evetnt_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_harasser.Clear();
}
void Event_WitchHarasserSet(Event event, const char[] name, bool dontBroadcast)
{
    int witchid = event.GetInt("witchid");
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId( userid );

    PrintToChatAll("\x03★ \x04%N \x05start the Witch!", client);
    int info[2];
    info[0] = EntIndexToEntRef(witchid);
    info[1] = userid;
    g_harasser.PushArray(info, sizeof(info));
    // SDKHook(witchid, SDKHook_ThinkPost, SDKCallback_TP);
}
void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
    if( g_harasser.Length <= 0 )
        return;

    int witchid = event.GetInt("witchid");

    for(int i = 0; i < g_harasser.Length; i++)
    {
        if( witchid == EntRefToEntIndex(g_harasser.Get(i,0)))
        {
            g_harasser.Erase(i);
            return;
        }
    }
}
void Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId( event.GetInt("userid") );
    if( client < 1 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 )
        return;

    if( g_witch_killincap )
        return;

    if( g_harasser.Length <= 0 )
        return;
    
    SetWitchTarget(client);
}
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId( event.GetInt("userid") );
    if( client < 1 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 )
        return;

    if( g_harasser.Length <= 0 )
        return;
    
    SetWitchTarget(client);
}

void SetWitchTarget(int client)
{
    int userid = GetClientUserId(client);
    for(int i = 0; i < g_harasser.Length; i++)
    {
        int harasser = g_harasser.Get(i, 1);
        if( userid != harasser )
            continue;

        int witch = EntRefToEntIndex(g_harasser.Get(i,0));
        int new_harasser = GetRandomSurvivor(witch);
        if( new_harasser != 0 )
        {
            int prop = GetEntProp(witch, Prop_Send, "m_iGlowType");
            SDKCall(g_SDKCall_WitchHitByVomit, witch, new_harasser);
            SetEntProp(witch, Prop_Send, "m_iGlowType", prop);
            
            g_harasser.Set(i, GetClientUserId(new_harasser), 1);
            PrintToChatAll("\x03★ \x04Witch \x05is chasing \x04%N", new_harasser);
        }
    }
}
int GetRandomSurvivor(int witch)
{
    int index;
    float pos1[3], pos2[3];
    int survivor[MAXPLAYERS + 1][2];
    // int [][] survivor = new int[MaxClients][2];

    GetEntPropVector(witch, Prop_Send, "m_vecOrigin", pos1);

    for(int i = 1; i <= MaxClients; i++)
    {
        if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated") <= 0 )
        {
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
            MakeVectorFromPoints(pos1, pos2, pos2);
            survivor[index][0] = i;
            survivor[index][1] = RoundToFloor(GetVectorLength(pos2));
            
            index++;
        }
    }

    if( index == 0 )
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
            {
                GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
                MakeVectorFromPoints(pos1, pos2, pos2);
                survivor[index][0] = i;
                survivor[index][1] = RoundToFloor(GetVectorLength(pos2));
                
                index++;
            }
        }
    }
    SortCustom2D(survivor, sizeof(survivor), SortDistance);

    // the distance in first index is the max, so we get the last one of the array( last one means the index has num, not include the empty index. )
    return index == 0 ? 0 : survivor[index - 1][0]; 
}
int SortDistance(int[] elem1, int[] elem2, const int[][] array, Handle hndl)
{
    if( elem1[1] > elem2[1] )
        return -1;
    else if( elem1[1] < elem2[1] )
        return 1;

    return 0;
}
// void SDKCallback_TP(int witch)
// {
//     PrintToChatAll("test 111");
//     int index = g_harasser.FindValue(EntIndexToEntRef(witch), 0);
//     if( index == -1 )
//         return;
    
//     PrintToChatAll("test 222");
//     int client = GetClientOfUserId(g_harasser.Get(index, 1));
//     if( client == 0 || !IsPlayerAlive(client) 
//         || (!g_witch_killincap && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0 ) 
//         )
//     {
//         int new_harasser = GetRandomSurvivor();
//         if( new_harasser != 0 )
//         {
//             int prop = GetEntProp(witch, Prop_Send, "m_iGlowType");
//             SDKCall(g_SDKCall_WitchHitByVomit, witch, new_harasser);
//             SetEntProp(witch, Prop_Send, "m_iGlowType", prop);
            
//             g_harasser.Set(index, GetClientUserId(new_harasser), 1);
//             PrintToChatAll("\x03★ \x04妹子 \x05正在追杀 \x04%N", new_harasser);
//         }
//     }
// }

void LoadGameData()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAME_INFO);

    if(FileExists(sPath) == false) 
        SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

    GameData hGameData = new GameData(GAME_INFO);
    if(hGameData == null) 
        SetFailState("Failed to load \"%s.txt\" gamedata.", GAME_INFO);

    StartPrepSDKCall(SDKCall_Entity);
    if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "Infected::OnHitByVomitJar"))
        SetFailState("Failed to find signature: \"Infected::OnHitByVomitJar\" (%s)", PLUGIN_VERSION);
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    if(!(g_SDKCall_WitchHitByVomit = EndPrepSDKCall()))
        SetFailState("Failed to create SDKCall: \"Infected::OnHitByVomitJar\" (%s)", PLUGIN_VERSION);
}


