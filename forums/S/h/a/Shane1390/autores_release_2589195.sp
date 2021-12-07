#include <colors_csgo>
#include <cstrike>
#include <dhooks>
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

bool g_bCourse, g_bAutores, g_bOverride, g_bStartDisabled[2048];
float g_PlayerTimers[MAXPLAYERS + 1];
Handle g_SpawnPoints, g_Triggers, hAcceptInput;
Handle g_ConVar;
int g_iCTSpawns, g_iTSpawns;

public Plugin myinfo = 
{
    name = "Auto-Respawn",
    author = "Shane",
    description = "Course Map Auto-Respawn",
    version = "2.3.8",
    url = "http://steamcommunity.com/id/shane1390/"
}

public void OnPluginStart()
{
    //coursemap cvars/commands
    RegAdminCmd("sm_disableautores", Command_DisableAutoRes, ADMFLAG_GENERIC, "Disable Auto Respawn.");
    RegAdminCmd("sm_enableautores", Command_EnableAutoRes, ADMFLAG_GENERIC, "Enable Auto Respawn.");

    g_ConVar = CreateConVar("sm_auto_respawn", "1", "Enable Auto-Respawn.");
    g_bAutores = GetConVarBool(g_ConVar);
    HookConVarChange(g_ConVar, ConvarChanged);

    //respawn + detection handling
    HookEntityOutput("trigger_hurt", "OnHurtPlayer", OnTriggerHurt);
    HookEvent("player_death", PlayerDeath);
    HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
    HookEvent("round_start", RoundStart);

    //dhooks AcceptInput
    Handle temp = LoadGameConfigFile("dhooks-acceptinput.games");
    if(temp == null)
        SetFailState("Autores missing gamedata!");

    int offset = GameConfGetOffset(temp, "AcceptInput");
    hAcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, AcceptInput);
    DHookAddParam(hAcceptInput, HookParamType_CharPtr);
    DHookAddParam(hAcceptInput, HookParamType_CBaseEntity);
    DHookAddParam(hAcceptInput, HookParamType_CBaseEntity);
    DHookAddParam(hAcceptInput, HookParamType_Object, 20); //varaint_t is a union of 12 (float[3]) plus two int type params 12 + 8 = 20
    DHookAddParam(hAcceptInput, HookParamType_Int);

    delete temp;
}

public void ConvarChanged(Handle convar, const char[] oldVal, const char[] newVal)
{
    g_bAutores = GetConVarBool(convar);
}

public void OnMapStart()
{
    g_iCTSpawns = EntityCountByClassname("info_player_counterterrorist");
    g_iTSpawns = EntityCountByClassname("info_player_terrorist");
    g_bCourse = (g_iCTSpawns == 0 || g_iTSpawns == 0);
    if(!g_bCourse)return;

    g_SpawnPoints = CreateArray();
    g_Triggers = CreateArray();

    //handling for maps that spawn players in the map
    int counter = -1;
    char class[32];
    class = (g_iCTSpawns > g_iTSpawns) ? "info_player_counterterrorist" : "info_player_terrorist";
    while((counter = FindEntityByClassname(counter, class)) != -1)
    {
        PushArrayCell(g_SpawnPoints, counter);
    }

    //handling for maps that teleport players into the map
    char targetName[32];
    counter = -1;
    while((counter = FindEntityByClassname(counter, "trigger_teleport")) != -1)
    {
        if(BoxOverSpawns(counter)) {
            GetEntPropString(counter, Prop_Data, "m_target", targetName, sizeof(targetName));
            int iTarget = FindEntityByTargetname(targetName, "info_teleport_destination");
            if(iTarget != -1)
                PushArrayCell(g_SpawnPoints, iTarget);
        }
    }

    counter = -1;
    while((counter = FindEntityByClassname(counter, "trigger_hurt")) != -1)
    {
        /*
            manual m_bStartDisabled, as it's not included in
            ent flags, m_spawnflags or m_fFlags. janky but i
            wasn't able to find a solution anywhere.
        */
        g_bStartDisabled[counter] = (GetEntProp(counter, Prop_Data, "m_bDisabled") == 1);
        if(g_bStartDisabled[counter] && BoxOverSpawns(counter) != 0)
            PushArrayCell(g_Triggers, counter);
    }
}

stock int FindEntityByTargetname(char[] name, char[] class)
{
    int counter = -1;
    char sTarget[32];

    while((counter = FindEntityByClassname(counter, class)) != -1)
    {
        GetEntPropString(counter, Prop_Data, "m_iName", sTarget, sizeof(sTarget));
        if(StrEqual(name, sTarget))return counter;
    }
    return -1;
}

stock int EntityCountByClassname(char[] class)
{
    int counter = -1;
    int ents = 0;
    while((counter = FindEntityByClassname(counter, class)) != -1)
    {
        ents++;
    }
    return ents;
}

stock int BoxOverSpawns(int trigger)
{
    float trigOrigin[3], trigMins[3], trigMaxs[3];

    GetEntPropVector(trigger, Prop_Send, "m_vecOrigin", trigOrigin);
    GetEntPropVector(trigger, Prop_Send, "m_vecMins", trigMins);
    GetEntPropVector(trigger, Prop_Send, "m_vecMaxs", trigMaxs);

    for(int i = 0; i <= 2; i++)
    {
        trigMins[i] = trigMins[i] + trigOrigin[i];
        trigMaxs[i] = trigMaxs[i] + trigOrigin[i];
    }

    int spawns = 0;
    int iterate = GetArraySize(g_SpawnPoints);
    
    bool InTrigger;
    int spawnPoint;
    float spawnPos[3];
    for(int point = 0; point < iterate; point++)
    {
        InTrigger = true;
        spawnPoint = GetArrayCell(g_SpawnPoints, point);
        GetEntPropVector(spawnPoint, Prop_Send, "m_vecOrigin", spawnPos);

        for(int i = 0; i <= 2; i++)
        {
            if(trigMins[i] > spawnPos[i] || trigMaxs[i] < spawnPos[i])
                InTrigger = false;
        }

        if(InTrigger)spawns++;
    }

    return spawns;
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if(!g_bCourse)return Plugin_Handled;

    EnableAutoRes();
    g_bOverride = false;
    
    //hooks expire at the end of each round
    int iterate = GetArraySize(g_Triggers);
    int triggerCell;
    for(int trigger = 0; trigger < iterate; trigger++)
    {
        triggerCell = GetArrayCell(g_Triggers, trigger);
        DHookEntity(hAcceptInput, false, triggerCell);
    }

    return Plugin_Handled;
}

void EnableAutoRes(bool override = false)
{
    if(!g_bCourse)return;

    if(override) {
        CPrintToChatAll("{orange}> {default}Auto-Respawn {orange}***OVERRIDE***");
        g_bOverride = true;
    } else
        CPrintToChatAll("{green}> {default}Auto-Respawn {green}Enabled{default}.");

    g_bAutores = true;
}

public MRESReturn AcceptInput(int entity, Handle hReturn, Handle hParams)
{
    char sAction[128];
    DHookGetParamString(hParams, 1, sAction, sizeof(sAction));
    
    if(StrEqual(sAction, "Enable")) {
        if(g_bOverride) {
            DHookSetReturn(hReturn, false);
            return MRES_Supercede;
        }
        DisableAutoRes();
    }

    return MRES_Ignored;
}

void DisableAutoRes()
{
    if(!g_bCourse || !g_bAutores)return;
    CPrintToChatAll("{darkred}> {default}Auto-Respawn {darkred}Disabled{default}.");
    g_bAutores = false;
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    CreateTimer(0.1, RespawnPlayer, client);

    //disgusting, emergency backup (mostly for trigger_multiple's)
    char weapon[32];
    event.GetString("weapon", weapon, sizeof(weapon));
    float fTickedTime = GetTickedTime();
    if(g_bCourse && (StrContains(weapon, "trigger_") != -1 || StrEqual(weapon, "point_hurt")) && fTickedTime <= g_PlayerTimers[client])
        DisableAutoRes();

    return Plugin_Handled;
}

public Action OnTriggerHurt(const char[] output, int trigger, int client, float delay)
{
    float fTickedTime = GetTickedTime();
    if(g_bCourse && client >= 1 && client <= MaxClients && IsClientInGame(client) && fTickedTime <= g_PlayerTimers[client]) {
        /*
            this won't always work, as some maps are retarded
            and drop the floor out from under the player,
            dropping them into a trigger, hence the StartDisabled check.
            (too unpredictable, not supportable)
        */
        if(g_bStartDisabled[trigger] && FindValueInArray(g_Triggers, trigger) == -1) 
            PushArrayCell(g_Triggers, trigger);

        if(g_bOverride)
            AcceptEntityInput(trigger, "Disable");
        else {
            float fTriggerDamage = GetEntPropFloat(trigger, Prop_Data, "m_flDamage");
            if(fTriggerDamage > 0.0)
                DisableAutoRes();
        }
    }
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    float fTickedTime = GetTickedTime();
    g_PlayerTimers[client] = fTickedTime + 1.0;
}

public Action RespawnPlayer(Handle timer, int client)
{
    //just in case server has really short end of round or smth funky happens
    if(g_bCourse && g_bAutores && IsClientInGame(client) && !IsPlayerAlive(client))
        CS_RespawnPlayer(client);
}

public Action Command_DisableAutoRes(int client, int args)
{
    if(g_bOverride) {
        int iterate = GetArraySize(g_Triggers);
        int triggerCell;
        for(int trigger = 0; trigger < iterate; trigger++)
        {
            triggerCell = GetArrayCell(g_Triggers, trigger);
            if(IsValidEntity(triggerCell) && triggerCell != 0)
                AcceptEntityInput(triggerCell, "Enable");
        }
        g_bOverride = false;
    }
    DisableAutoRes();
}

public Action Command_EnableAutoRes(int client, int args)
{
    int iTriggers = GetArraySize(g_Triggers);
    if(iTriggers < 1) {
        ReplyToCommand(client, "Not Available!");
        return Plugin_Handled;
    }

    int iTemp;
    for(int trigger = 0; trigger < iTriggers; trigger++)
    {
        iTemp = GetArrayCell(g_Triggers, trigger);
        if(IsValidEntity(iTemp) && iTemp != 0)
            AcceptEntityInput(iTemp, "Disable");
    }

    EnableAutoRes(true);

    for(int _client = 1; _client <= MaxClients; _client++)
    {
        if(IsClientInGame(_client) && !IsPlayerAlive(_client) && (GetClientTeam(_client) == CS_TEAM_CT || GetClientTeam(_client) == CS_TEAM_T))
            CreateTimer(0.1, RespawnPlayer, _client );
    }

    return Plugin_Continue;
}