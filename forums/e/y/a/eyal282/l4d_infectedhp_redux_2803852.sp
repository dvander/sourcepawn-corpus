/* put the line below after all of the includes!
#pragma newdecls required
*/

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.2"
#define INFECTED_NAMES 6
#define WITCH_LEN 32
#define CVAR_FLAGS FCVAR_SPONLY|FCVAR_NOTIFY

public Plugin myinfo =
{
    name = "L4D Infected HP Redux",
    author = "NiCo-op, redux by Eyal282",
    description = "L4D Infected HP",
    version = PLUGIN_VERSION,
    url = "http://nico-op.forjp.net/"
};

Handle hPluginEnable = INVALID_HANDLE;
Handle hBarLEN = INVALID_HANDLE;
int witchCUR = 0;
int witchMAX[WITCH_LEN];
int witchHP[WITCH_LEN];
int witchID[WITCH_LEN];
int prevMAX[MAXPLAYERS+1];
int prevHP[MAXPLAYERS+1];
int nCharLength;
char sCharHealth[8] = "#";
char sCharDamage[8] = "=";
Handle hCharHealth;
Handle hCharDamage;
Handle hShowType;
Handle hShowNum;
Handle hTank;
Handle hWitch;
Handle hWitchHealth;
Handle hInfected[INFECTED_NAMES];
int nShowType;
int nShowNum;
int nShowTank;
int nShowWitch;
int nShowFlag[INFECTED_NAMES];
char sClassName[][] = {
    "boomer",
    "hunter",
    "smoker",
    "jockey",
    "spitter",
    "charger"
};


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("ShowHealthGauge", Native_ShowHealthGauge);

    return APLRes_Success;
}

public any Native_ShowHealthGauge(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int maxBAR = GetNativeCell(2);
    int maxHP = GetNativeCell(3);
    int nowHP = GetNativeCell(4);

    if(maxBAR == 0)
    {
        maxBAR = GetConVarInt(hBarLEN);
    }

    GetConfig();

    char clName[64];
    GetNativeString(5, clName, sizeof(clName));

    ShowHealthGauge(client, maxBAR, maxHP, nowHP, clName);

    return 0;
}
public void OnPluginStart()
{
    hWitchHealth = FindConVar("z_witch_health");

    CreateConVar("l4d_infectedhp_version",
        PLUGIN_VERSION,
        "L4D Infected HP version",
        FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD
    );

    hPluginEnable = CreateConVar("l4d_infectedhp", "1", "plugin on/off (on:1 / off:0)", CVAR_FLAGS, true, 0.0, true, 1.0);

    hBarLEN = CreateConVar("l4d_infectedhp_bar", "100", "length of health bar (def:100 / min:10 / max:200)", CVAR_FLAGS, true, 10.0, true, 200.0);

    hCharHealth = CreateConVar("l4d_infectedhp_health", "#", "show health character", CVAR_FLAGS);

    hCharDamage = CreateConVar("l4d_infectedhp_damage", "=", "show damage character", CVAR_FLAGS);

    hShowType = CreateConVar("l4d_infectedhp_type", "0", "health bar type (def:0 / center text:0 / hint text:1)", CVAR_FLAGS, true, 0.0, true, 1.0);

    hShowNum = CreateConVar("l4d_infectedhp_num", "0", "health value display (def:0 / hidden:0 / visible:1)", CVAR_FLAGS, true, 0.0, true, 1.0);

    hTank = CreateConVar("l4d_infectedhp_tank", "1", "show health bar (def:1 / on:1 / off:0)", CVAR_FLAGS, true, 0.0, true, 1.0);

    hWitch = CreateConVar("l4d_infectedhp_witch", "1", "show health bar (def:1 / on:1 / off:0)", CVAR_FLAGS, true, 0.0, true, 1.0);

    char buffers[64];
    for(int i=0; i<INFECTED_NAMES; i++)
    {
        Format(buffers, sizeof(buffers), "l4d_infectedhp_%s", sClassName[i]);
        hInfected[i] = CreateConVar(buffers, "1", "show health bar (def:1 / on:1 / off:0)", CVAR_FLAGS, true, 0.0, true, 1.0);
    }

    HookEvent("round_start", OnRoundStart);
    HookEvent("player_hurt", OnPlayerHurt);
    HookEvent("witch_spawn", OnWitchSpawn);
    HookEvent("witch_killed", OnWitchKilled);
    HookEvent("infected_hurt", OnWitchHurt);
    HookEvent("player_spawn", OnInfectedSpawn);
    HookEvent("player_death", OnInfectedDeath, EventHookMode_Pre);
    // HookEvent("tank_spawn", OnInfectedSpawn);
    // HookEvent("tank_killed", OnInfectedDeath, EventHookMode_Pre);

    AutoExecConfig(true, "l4d_infectedhp");
}

void GetConfig()
{
    char bufA[8];
    char bufB[8];
    GetConVarString(hCharHealth, bufA, sizeof(bufA));
    GetConVarString(hCharDamage, bufB, sizeof(bufB));
    nCharLength = strlen(bufA);
    if(!nCharLength || nCharLength != strlen(bufB)){
        nCharLength = 1;
        sCharHealth[0] = '#';
        sCharHealth[1] = '\0';
        sCharDamage[0] = '=';
        sCharDamage[1] = '\0';
    }
    else{
        strcopy(sCharHealth, sizeof(sCharHealth), bufA);
        strcopy(sCharDamage, sizeof(sCharDamage), bufB);
    }

    nShowType = GetConVarBool(hShowType);
    nShowNum = GetConVarBool(hShowNum);
    nShowTank = GetConVarBool(hTank);
    nShowWitch = GetConVarBool(hWitch);
    for(int i=0; i<INFECTED_NAMES; i++){
        nShowFlag[i] = GetConVarBool(hInfected[i]);
    }
}

void ShowHealthGauge(int client, int maxBAR, int maxHP, int nowHP, char[] clName){
    int percent = RoundToCeil((float(nowHP) / float(maxHP)) * float(maxBAR));
    int i, length = maxBAR * nCharLength + 2;

    char[] showBAR = new char[length+1];
    showBAR[0] = '\0';
    for(i=0; i<percent&&i<maxBAR; i++){
        StrCat(showBAR, length, sCharHealth);
    }
    for(i=0; i<maxBAR; i++){
        StrCat(showBAR, length, sCharDamage);
    }

    if(nShowType){
        if(!nShowNum){
            PrintHintText(client, "HP: |-%s-|  %s", showBAR, clName);
        }
        else{
            PrintHintText(client, "HP: |-%s-|  [%d / %d]  %s", showBAR, nowHP, maxHP, clName);
        }
    }
    else{
        if(!nShowNum){
            PrintCenterText(client, "HP: |-%s-|  %s", showBAR, clName);
        }
        else{
            PrintCenterText(client, "HP: |-%s-|  [%d / %d]  %s", showBAR, nowHP, maxHP, clName);
        }
    }
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    nShowTank = 0;
    nShowWitch = 0;
    witchCUR = 0;
    for(int i=0; i<WITCH_LEN; i++){
        witchMAX[i] = -1;
        witchHP[i] = -1;
        witchID[i] = -1;

    }
    for(int i=0; i<MAXPLAYERS+1; i++){
        prevMAX[i] = -1;
        prevHP[i] = -1;
    }
    return Plugin_Continue;
}

public Action TimerSpawn(Handle timer, any client)
{
    if(IsValidEntity(client)){
        int val = GetEntProp(client, Prop_Send, "m_iMaxHealth") & 0xffff;
        prevMAX[client] = (val <= 0) ? val : 1;
        prevHP[client] = 999999;
    }
    return Plugin_Stop;
}

public Action OnInfectedSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    GetConfig();

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if( client > 0
        && IsClientConnected(client)
        && IsClientInGame(client)
        && GetClientTeam(client) == 3
    ){
        TimerSpawn(INVALID_HANDLE, client);
        CreateTimer(0.5, TimerSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
    }

    return Plugin_Continue;
}

public Action OnInfectedDeath(Handle event, const char[] name, bool dontBroadcast)
{
    if(!GetConVarBool(hPluginEnable)) return Plugin_Continue;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if( client > 0
        && IsClientConnected(client)
        && IsClientInGame(client)
        && GetClientTeam(client) == 3
    ){
        char clName[MAX_NAME_LENGTH];
        GetClientName(client, clName, sizeof(clName));
        prevMAX[client] = -1;
        prevHP[client] = -1;
        if(nShowTank && StrContains(clName, "Tank", false) != -1)
        {
            for(int i=1; i<= MaxClients; i++){
                if(IsClientConnected(i)
                && IsClientInGame(i)
                && !IsFakeClient(i)
                && GetClientTeam(i) == 2){
                    PrintHintText(i, "++ %s is DEAD ++", clName);
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action OnPlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
    if(!GetConVarBool(hPluginEnable)) return Plugin_Continue;

    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    if(!attacker
    || !IsClientConnected(attacker)
    || !IsClientInGame(attacker)
    || GetClientTeam(attacker) != 2){
        return Plugin_Continue;
    }
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!client
    || !IsClientConnected(client)
    || !IsClientInGame(client)
    || !IsPlayerAlive(client)
    || GetClientTeam(client) != 3){
        return Plugin_Continue;
    }

    char class[128];
    GetClientModel(client, class, sizeof(class));
    int match = 0;
    for(int i=0; i<INFECTED_NAMES; i++){
        if(nShowFlag[i] && StrContains(class, sClassName[i], false) != -1){
            match = 1;
            break;
        }
    }
    if(!match && (!nShowTank || (nShowTank
    && StrContains(class, "tank", false) == -1
    && StrContains(class, "hulk", false) == -1))){
        return Plugin_Continue;
    }

    int maxBAR = GetConVarInt(hBarLEN);
    int nowHP = GetEventInt(event, "health") & 0xffff;
    int maxHP = GetEntProp(client, Prop_Send, "m_iMaxHealth") & 0xffff;

    if(nowHP <= 0 || prevMAX[client] < 0){
        nowHP = 0;
    }
    if(nowHP && nowHP > prevHP[client]){
        nowHP = prevHP[client];
    }
    else{
        prevHP[client] = nowHP;
    }
    if(maxHP < prevMAX[client]){
        maxHP = prevMAX[client];
    }
    if(maxHP < nowHP){
        maxHP = nowHP;
        prevMAX[client] = nowHP;
    }
    if(maxHP < 1){
        maxHP = 1;
    }
    char clName[MAX_NAME_LENGTH];
    GetClientName(client, clName, sizeof(clName));
    ShowHealthGauge(attacker, maxBAR, maxHP, nowHP, clName);

    return Plugin_Continue;
}

public Action OnWitchSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    GetConfig();

    int entity = GetEventInt(event, "witchid");
    witchID[witchCUR] = entity;

    int health = (hWitchHealth == INVALID_HANDLE) ? 0 : GetConVarInt(hWitchHealth);
    witchMAX[witchCUR] = health;
    witchHP[witchCUR] = health;
    witchCUR = (witchCUR + 1) % WITCH_LEN;

    return Plugin_Continue;
}

public Action OnWitchKilled(Handle event, const char[] name, bool dontBroadcast)
{
    int entity = GetEventInt(event, "witchid");
    for(int i=0; i<WITCH_LEN; i++){
        if(witchID[i] == entity){
            witchMAX[i] = -1;
            witchHP[i] = -1;
            witchID[i] = -1;
            break;
        }
    }
    return Plugin_Continue;
}

public Action OnWitchHurt(Handle event, const char[] name, bool dontBroadcast)
{
    if(!nShowWitch || !GetConVarBool(hPluginEnable)) return Plugin_Continue;

    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    if(!attacker
    || !IsClientConnected(attacker)
    || !IsClientInGame(attacker)
    || GetClientTeam(attacker) != 2){
        return Plugin_Continue;
    }

    int entity = GetEventInt(event, "entityid");
    for(int i=0; i<WITCH_LEN; i++){
        if(witchID[i] == entity){
            int damage = GetEventInt(event, "amount");
            int maxBAR = GetConVarInt(hBarLEN);
            int nowHP = witchHP[i] - damage;
            int maxHP = witchMAX[i];

            if(nowHP <= 0 || witchMAX[i] < 0){
                nowHP = 0;
            }
            if(nowHP && nowHP > witchHP[i]){
                nowHP = witchHP[i];
            }
            else{
                witchHP[i] = nowHP;
            }
            if(maxHP < 1){
                maxHP = 1;
            }
            char clName[64];
            if(i == 0){
                strcopy(clName, sizeof(clName), "Witch");
            }
            else{
                Format(clName, sizeof(clName), "(%d)Witch", i);
            }
            ShowHealthGauge(attacker, maxBAR, maxHP, nowHP, clName);
            return Plugin_Continue;
        }
    }

    return Plugin_Continue;
}
