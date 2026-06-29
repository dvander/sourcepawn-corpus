#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.9.23"

// Model path
#define MORTAR_MODEL "models/surgeon/mortar34.mdl"
#define MORTAR_MODEL_AXIS "models/props_lg40/lg40.mdl"
#define MORTAR_MODEL_AXIS_DESTROYED "models/props_lg40/lg40_destroyed.mdl"
#define HELPER_MODEL "models/props_c17/oildrum001.mdl"

// Sound files
#define SOUND_FIRING "weapons/mortar_shoot.wav"
#define SOUND_RELOAD "weapons/rocket_worldreload.wav"
#define SOUND_INCOMING "weapons/mortar_incoming.wav"

// Distance in front of player to spawn mortar
#define SPAWN_DISTANCE 80.0

// Maximum mortars that can exist
#define MAX_MORTARS 64

// Cooldown between fires (seconds)
#define FIRE_COOLDOWN 5.0

// Range settings
#define RANGE_MIN 1050       // 20m
#define RANGE_MAX 10500      // 200m
#define RANGE_STEP 525       // 10m
#define RANGE_DEFAULT 1050   // 20m
#define HU_PER_METRE 52.49

// Mortar health
#define MORTAR_HEALTH 60

// Team definitions
#define TEAM_ALLIES 2
#define TEAM_AXIS   3

// Menu state constants
#define MENU_STATE_NORMAL 0
#define MENU_STATE_UNDER_ROOF 1

// Track all spawned mortars
int g_SpawnedMortars[MAX_MORTARS];
int g_SpawnedHelpers[MAX_MORTARS];
int g_MortarCount = 0;

// Track last fire time, owners, ranges, and target sprites
float g_LastFireTime[MAX_MORTARS];
int g_MortarOwner[MAX_MORTARS];
int g_MortarRange[MAX_MORTARS];
int g_MortarTargetSprite[MAX_MORTARS];

// Track mortar rotation
float g_MortarSpawnYaw[MAX_MORTARS];  // Original yaw at spawn
float g_MortarRotation[MAX_MORTARS];  // Rotation offset (-45 to +45)

// Track mortar health
int g_MortarHealth[MAX_MORTARS];

// Track last explosion position per mortar (for kill logging)
float g_LastExplosionPos[MAX_MORTARS][3];

// Track firing timers so they can be cancelled on removal
Handle g_SteamTimer[MAX_MORTARS];
Handle g_ReloadTimer[MAX_MORTARS];
Handle g_ExplosionTimer[MAX_MORTARS];

// Track if mortar target is in a restricted zone
bool g_MortarBlocked[MAX_MORTARS];
char g_MortarBlockReason[MAX_MORTARS][32];
bool g_MortarOffMap[MAX_MORTARS];
float g_MortarSkyZ[MAX_MORTARS];
int g_MortarGroundMarker[MAX_MORTARS];

ConVar g_CvarWelcome;
ConVar g_CvarMaxShots;
ConVar g_CvarDebugBeam;
int g_SteamEntity[MAX_MORTARS];
int g_BeamSprite = -1;

// Track shots fired per mortar
int g_MortarShotsFired[MAX_MORTARS];

// Track which clients currently have the mortar menu open
bool g_MortarMenuOpen[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "DoD Deployable Mortar",
    author = "Claude.ai guided by DNA.styx",
    description = "Allows players to deploy and use mortars. Allied model by The Surgeon, Axis model by Cpt Ukulele",
    version = PLUGIN_VERSION,
    url = "https://github.com/DNA-styx/dod_deployable_mortar"
};

public void OnPluginStart()
{
    CreateConVar("dod_deployable_mortar_version", PLUGIN_VERSION, "DoD Deployable Mortar Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    g_CvarWelcome = CreateConVar("dod_deployable_mortar_welcome", "1", "Show welcome message to players on connect (0=off, 1=on)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_CvarMaxShots = CreateConVar("dod_deployable_mortar_shots", "5", "Number of shots before mortar is destroyed (0=unlimited)", FCVAR_NOTIFY, true, 0.0);
    g_CvarDebugBeam = CreateConVar("dod_deployable_mortar_debug", "0", "Draw targeting beam visible to admins (0=off, 1=on)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    AutoExecConfig(true, "dod_deployable_mortar");
    RegConsoleCmd("sm_mortar", Command_SpawnMortar, "Deploy a mortar");
    AddCommandListener(Listener_Say, "say");
    AddCommandListener(Listener_Say, "say_team");
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
    HookEvent("dod_round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("dod_round_win", OnRoundWin, EventHookMode_PostNoCopy);
    HookEvent("player_team", OnPlayerTeam, EventHookMode_Post);
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public void OnPluginEnd()
{
    RemoveAllMortars();
}

public Action Listener_Say(int client, const char[] command, int argc)
{
    char text[16];
    GetCmdArg(1, text, sizeof(text));
    
    if (StrEqual(text, "!mortar", false) || StrEqual(text, "/mortar", false))
        return Plugin_Handled;
    
    return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
    g_MortarMenuOpen[client] = false;
    
    // Clean up mortars owned by disconnecting player
    for (int i = 0; i < g_MortarCount; i++)
    {
        if (g_MortarOwner[i] == client)
        {
            RemoveMortar(i);
            break;
        }
    }
}

public void OnClientPutInServer(int client)
{
    if (!IsFakeClient(client))
        CreateTimer(20.0, Timer_WelcomeMsg, client);
}

public Action Timer_WelcomeMsg(Handle timer, int client)
{
    if (g_CvarWelcome.IntValue == 0)
        return Plugin_Stop;
    
    if (!IsValidClient(client, false, false))
        return Plugin_Stop;
    
    PrintToChat(client, "\x01\x04[Mortar]\x01 Say \x04!mortar\x01 to place a deployable mortar");
    return Plugin_Stop;
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    if (!IsValidClient(victim, false, true))
        return Plugin_Continue;
    
    // If victim owns a mortar, refresh menu to disable items
    if (!IsFakeClient(victim))
    {
        for (int i = 0; i < g_MortarCount; i++)
        {
            if (g_MortarOwner[i] == victim)
            {
                int mortar = EntRefToEntIndex(g_SpawnedMortars[i]);
                if (mortar != INVALID_ENT_REFERENCE && IsValidEntity(mortar))
                    ShowMortarMenu(victim, i, MENU_STATE_NORMAL);
                break;
            }
        }
    }
    
    // Only check world kills for kill credit (env_explosion has no attacker)
    if (attacker != 0)
        return Plugin_Continue;
    
    float victimPos[3];
    GetClientAbsOrigin(victim, victimPos);
    
    float deathTime = GetGameTime();
    
    // Check each active mortar - window is fire time + 2s delay + 1s tolerance
    for (int i = 0; i < g_MortarCount; i++)
    {
        if (g_MortarOwner[i] == 0)
            continue;
        
        if (deathTime < g_LastFireTime[i] + 1.5 || deathTime > g_LastFireTime[i] + 4.0)
            continue;
        
        float dist = GetVectorDistance(victimPos, g_LastExplosionPos[i]);
        if (dist > 500.0)
            continue;
        
        // Victim was killed by this mortar
        int owner = g_MortarOwner[i];
        char ownerName[MAX_NAME_LENGTH], victimName[MAX_NAME_LENGTH];
        GetClientName(owner, ownerName, sizeof(ownerName));
        GetClientName(victim, victimName, sizeof(victimName));
        
        // Colour names by team - matching dod_mortarkill_v2
        char ownerColored[MAX_NAME_LENGTH + 16];
        char victimColored[MAX_NAME_LENGTH + 16];
        
        switch (GetClientTeam(owner))
        {
            case TEAM_ALLIES: Format(ownerColored, sizeof(ownerColored), "\x074d7942%s\x01", ownerName);
            case TEAM_AXIS:   Format(ownerColored, sizeof(ownerColored), "\x07ff4040%s\x01", ownerName);
            default:          Format(ownerColored, sizeof(ownerColored), "\x01%s", ownerName);
        }
        
        switch (GetClientTeam(victim))
        {
            case TEAM_ALLIES: Format(victimColored, sizeof(victimColored), "\x074d7942%s\x01", victimName);
            case TEAM_AXIS:   Format(victimColored, sizeof(victimColored), "\x07ff4040%s\x01", victimName);
            default:          Format(victimColored, sizeof(victimColored), "\x01%s", victimName);
        }
        
        PrintToChatAll("\x01\x04[Mortar]\x01 %s killed %s", ownerColored, victimColored);
        
        char ownerSteamId[32], victimSteamId[32];
        if (IsFakeClient(owner))
            strcopy(ownerSteamId, sizeof(ownerSteamId), "BOT");
        else
            GetClientAuthId(owner, AuthId_Steam2, ownerSteamId, sizeof(ownerSteamId));
        
        if (IsFakeClient(victim))
            strcopy(victimSteamId, sizeof(victimSteamId), "BOT");
        else
            GetClientAuthId(victim, AuthId_Steam2, victimSteamId, sizeof(victimSteamId));
        
        LogToGame("\"%s<%d><%s><%s>\" killed \"%s<%d><%s><%s>\" with \"mortar_deployable\"",
            ownerName, GetClientUserId(owner), ownerSteamId, GetClientTeam(owner) == TEAM_ALLIES ? "Allies" : "Axis",
            victimName, GetClientUserId(victim), victimSteamId, GetClientTeam(victim) == TEAM_ALLIES ? "Allies" : "Axis");
        
        break;
    }
    
    return Plugin_Continue;
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    CancelMortarMenus();
    RemoveAllMortars();
    return Plugin_Continue;
}

public Action OnRoundWin(Handle event, const char[] name, bool dontBroadcast)
{
    CancelMortarMenus();
    return Plugin_Continue;
}

public Action OnPlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (!IsValidClient(client))
        return Plugin_Continue;
    
    for (int i = 0; i < g_MortarCount; i++)
    {
        if (g_MortarOwner[i] == client)
        {
            int mortar = EntRefToEntIndex(g_SpawnedMortars[i]);
            if (mortar != INVALID_ENT_REFERENCE && IsValidEntity(mortar))
            {
                CancelClientMenu(client);
                RemoveMortar(i);
            }
            break;
        }
    }
    
    return Plugin_Continue;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (!IsValidClient(client))
        return Plugin_Continue;
    
    // Refresh menu if player owns a mortar so Fire becomes active again
    for (int i = 0; i < g_MortarCount; i++)
    {
        if (g_MortarOwner[i] == client)
        {
            int mortar = EntRefToEntIndex(g_SpawnedMortars[i]);
            if (mortar != INVALID_ENT_REFERENCE && IsValidEntity(mortar))
                ShowMortarMenu(client, i, MENU_STATE_NORMAL);
            break;
        }
    }
    
    return Plugin_Continue;
}

void CancelMortarMenus()
{
    for (int i = 0; i < g_MortarCount; i++)
    {
        int owner = g_MortarOwner[i];
        if (IsValidClient(owner, false, false) && g_MortarMenuOpen[owner])
            CancelClientMenu(owner);
    }
}

public void OnMapEnd()
{
    CancelMortarMenus();
    RemoveAllMortars();
}

public void OnMapStart()
{
    g_MortarCount = 0;
    
    for (int i = 1; i <= MaxClients; i++)
        g_MortarMenuOpen[i] = false;
    
    PrecacheModel(MORTAR_MODEL, true);
    PrecacheModel(MORTAR_MODEL_AXIS, true);
    PrecacheModel(MORTAR_MODEL_AXIS_DESTROYED, true);
    PrecacheModel(HELPER_MODEL, true);
    PrecacheModel("models/surgeon/mortar34_gib1.mdl", true);
    PrecacheModel("models/surgeon/mortar34_gib2.mdl", true);
    PrecacheModel("models/surgeon/mortar34_gib3.mdl", true);
    PrecacheModel("models/weapons/w_smoke_us.mdl", true);
    PrecacheModel("models/weapons/w_smoke_ger.mdl", true);
    
    PrecacheSound(SOUND_FIRING, true);
    PrecacheSound(SOUND_RELOAD, true);
    PrecacheSound(SOUND_INCOMING, true);
    
    g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
    
    // Custom mortar models - register all companion files for client download
    AddFileToDownloadsTable("models/surgeon/mortar34.mdl");
    AddFileToDownloadsTable("models/surgeon/mortar34.vvd");
    AddFileToDownloadsTable("models/surgeon/mortar34.dx90.vtx");
    AddFileToDownloadsTable("models/surgeon/mortar34.phy");
    AddFileToDownloadsTable("models/surgeon/mortar34_gib1.mdl");
    AddFileToDownloadsTable("models/surgeon/mortar34_gib1.vvd");
    AddFileToDownloadsTable("models/surgeon/mortar34_gib1.dx90.vtx");
    AddFileToDownloadsTable("models/surgeon/mortar34_gib1.phy");
    AddFileToDownloadsTable("models/surgeon/mortar34_gib2.mdl");
    AddFileToDownloadsTable("models/surgeon/mortar34_gib2.vvd");
    AddFileToDownloadsTable("models/surgeon/mortar34_gib2.dx90.vtx");
    AddFileToDownloadsTable("models/surgeon/mortar34_gib2.phy");
    AddFileToDownloadsTable("models/surgeon/mortar34_gib3.mdl");
    AddFileToDownloadsTable("models/surgeon/mortar34_gib3.vvd");
    AddFileToDownloadsTable("models/surgeon/mortar34_gib3.dx90.vtx");
    AddFileToDownloadsTable("models/surgeon/mortar34_gib3.phy");
    AddFileToDownloadsTable("materials/models/surgeon/mortar34.vmt");
    AddFileToDownloadsTable("materials/models/surgeon/mortar34.vtf");
    AddFileToDownloadsTable("materials/models/surgeon/mortarcase.vmt");
    AddFileToDownloadsTable("materials/models/surgeon/mortarcase.vtf");
    AddFileToDownloadsTable("materials/models/surgeon/mortarshell.vmt");
    AddFileToDownloadsTable("materials/models/surgeon/mortarshell.vtf");
    
    // Axis mortar model (lg40 by Cpt Ukulele)
    AddFileToDownloadsTable("models/props_lg40/lg40.mdl");
    AddFileToDownloadsTable("models/props_lg40/lg40.vvd");
    AddFileToDownloadsTable("models/props_lg40/lg40.dx90.vtx");
    AddFileToDownloadsTable("models/props_lg40/lg40.phy");
    AddFileToDownloadsTable("models/props_lg40/lg40_destroyed.mdl");
    AddFileToDownloadsTable("models/props_lg40/lg40_destroyed.vvd");
    AddFileToDownloadsTable("models/props_lg40/lg40_destroyed.dx90.vtx");
    AddFileToDownloadsTable("models/props_lg40/lg40_destroyed.phy");
    AddFileToDownloadsTable("materials/models/props_lg40/lg40_diffuse.vmt");
    AddFileToDownloadsTable("materials/models/props_lg40/lg40_diffuse.vtf");
    AddFileToDownloadsTable("materials/models/props_lg40/lg40_destroyed_diffuse.vmt");
    AddFileToDownloadsTable("materials/models/props_lg40/lg40_destroyed_diffuse.vtf");
}

public Action Command_SpawnMortar(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;
    
    if (!IsPlayerAlive(client))
        return Plugin_Handled;
    
    // Check if player already has a mortar
    for (int i = 0; i < g_MortarCount; i++)
    {
        if (g_MortarOwner[i] == client)
        {
            int mortar = EntRefToEntIndex(g_SpawnedMortars[i]);
            if (mortar != INVALID_ENT_REFERENCE && IsValidEntity(mortar))
            {
                ShowMortarMenu(client, i, MENU_STATE_NORMAL);
                return Plugin_Handled;
            }
        }
    }
    
    ShowMortarMenu(client, -1, MENU_STATE_NORMAL);
    return Plugin_Handled;
}

void ShowMortarMenu(int client, int mortarIndex, int state)
{
    Menu menu = new Menu(MenuHandler_Mortar);
    
    char title[512];
    
    if (state == MENU_STATE_UNDER_ROOF)
    {
        Format(title, sizeof(title), "Deployable Mortar Restricted (Indoors)\n \n• Place in the open, not under cover\n• Move outside - roof detected\n ");
    }
    else if (mortarIndex < 0)
    {
        Format(title, sizeof(title), "Deployable Mortar\n \n• Place in the open, not under cover\n• Smoke shows where shell will land\n• Shoot or hit mortar to fire\n ");
    }
    else if (g_MortarOffMap[mortarIndex])
    {
        Format(title, sizeof(title), "Deployable Mortar - Restricted (Off Map)");
    }
    else if (g_MortarBlocked[mortarIndex])
    {
        Format(title, sizeof(title), "Deployable Mortar - Restricted (%s)", g_MortarBlockReason[mortarIndex]);
    }
    else
    {
        Format(title, sizeof(title), "Deployable Mortar (Range: %dm)", RoundToNearest(float(g_MortarRange[mortarIndex]) / HU_PER_METRE));
    }
    
    menu.SetTitle(title);
    
    char indexStr[8];
    if (mortarIndex >= 0)
    {
        IntToString(mortarIndex, indexStr, sizeof(indexStr));
    }
    else
    {
        strcopy(indexStr, sizeof(indexStr), "-1");
    }
    
    // No mortar placed
    if (mortarIndex < 0)
    {
        char placermItem[16];
        Format(placermItem, sizeof(placermItem), "placerm_%s", indexStr);
        menu.AddItem(placermItem, "Place Mortar");
    }
    else
    {
        bool alive = IsPlayerAlive(client);
        bool reloading = (g_ReloadTimer[mortarIndex] != INVALID_HANDLE);
        bool blocked = g_MortarBlocked[mortarIndex] || g_MortarOffMap[mortarIndex];
        
        char placermItem[16];
        Format(placermItem, sizeof(placermItem), "placerm_%s", indexStr);
        menu.AddItem(placermItem, "Remove Mortar", alive ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        
        char fireItem[16];
        Format(fireItem, sizeof(fireItem), "fire_%s", indexStr);
        
        char fireLabel[32];
        int maxShots = g_CvarMaxShots.IntValue;
        if (maxShots > 0)
        {
            int shotsLeft = maxShots - g_MortarShotsFired[mortarIndex];
            Format(fireLabel, sizeof(fireLabel), "Fire Mortar (%d rounds)", shotsLeft);
        }
        else
        {
            strcopy(fireLabel, sizeof(fireLabel), "Fire Mortar");
        }
        
        menu.AddItem(fireItem, fireLabel, (alive && !reloading && !blocked) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        
        menu.AddItem("", "", ITEMDRAW_IGNORE);
        
        char incItem[16];
        Format(incItem, sizeof(incItem), "inc_%s", indexStr);
        if (!alive || g_MortarRange[mortarIndex] >= RANGE_MAX)
            menu.AddItem(incItem, "Increase Range (+10m)", ITEMDRAW_DISABLED);
        else
            menu.AddItem(incItem, "Increase Range (+10m)");
        
        char decItem[16];
        Format(decItem, sizeof(decItem), "dec_%s", indexStr);
        if (!alive || g_MortarRange[mortarIndex] <= RANGE_MIN)
            menu.AddItem(decItem, "Decrease Range (-10m)", ITEMDRAW_DISABLED);
        else
            menu.AddItem(decItem, "Decrease Range (-10m)");
        
        menu.AddItem("", "", ITEMDRAW_IGNORE);
        
        char rotLeftItem[16];
        Format(rotLeftItem, sizeof(rotLeftItem), "rotleft_%s", indexStr);
        if (!alive || g_MortarRotation[mortarIndex] >= 45.0)
            menu.AddItem(rotLeftItem, "Rotate Left", ITEMDRAW_DISABLED);
        else
            menu.AddItem(rotLeftItem, "Rotate Left");
        
        char rotRightItem[16];
        Format(rotRightItem, sizeof(rotRightItem), "rotright_%s", indexStr);
        if (!alive || g_MortarRotation[mortarIndex] <= -45.0)
            menu.AddItem(rotRightItem, "Rotate Right", ITEMDRAW_DISABLED);
        else
            menu.AddItem(rotRightItem, "Rotate Right");
    }
    
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
    g_MortarMenuOpen[client] = true;
}

public int MenuHandler_Mortar(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        int client = param1;
        char info[16];
        menu.GetItem(param2, info, sizeof(info));
        
        char parts[2][16];
        ExplodeString(info, "_", parts, 2, 16);
        int mortarIndex = StringToInt(parts[1]);
        
        // Handle Place/Remove action - recheck location validity
        if (StrEqual(parts[0], "placerm"))
        {
            if (mortarIndex >= 0)
            {
                // mortarIndex >= 0 means remove
                RemoveMortar(mortarIndex);
                ShowMortarMenu(client, -1, MENU_STATE_NORMAL);
                return 0;
            }
            
            // mortarIndex < 0 means place
            if (!IsPlayerAlive(client))
                return 0;
            
            float playerPos[3], playerAngles[3];
            GetClientAbsOrigin(client, playerPos);
            GetClientEyeAngles(client, playerAngles);
            
            float spawnPos[3];
            spawnPos[0] = playerPos[0] + (SPAWN_DISTANCE * Cosine(DegToRad(playerAngles[1])));
            spawnPos[1] = playerPos[1] + (SPAWN_DISTANCE * Sine(DegToRad(playerAngles[1])));
            spawnPos[2] = playerPos[2] + 100.0;
            
            float groundPos[3];
            if (!TraceToGround(spawnPos, groundPos))
            {
                ShowMortarMenu(client, -1, MENU_STATE_UNDER_ROOF);
                return 0;
            }
            
            // Check if location is under roof
            if (IsUnderRoof(groundPos))
            {
                ShowMortarMenu(client, -1, MENU_STATE_UNDER_ROOF);
                return 0;
            }
            
            // Valid location - try to place mortar
            if (g_MortarCount >= MAX_MORTARS)
                return 0;
            
            int mortar = CreateMortarEntity(groundPos, playerAngles[1], client);
            
            if (mortar != -1)
            {
                int newMortarIndex = g_MortarCount;
                int helper = CreateHelperEntity(groundPos, mortar, newMortarIndex);
                
                g_SpawnedMortars[newMortarIndex] = EntIndexToEntRef(mortar);
                g_SpawnedHelpers[newMortarIndex] = EntIndexToEntRef(helper);
                g_LastFireTime[newMortarIndex] = 0.0;
                g_MortarOwner[newMortarIndex] = client;
                g_MortarRange[newMortarIndex] = RANGE_DEFAULT;
                g_MortarTargetSprite[newMortarIndex] = INVALID_ENT_REFERENCE;
                g_MortarSpawnYaw[newMortarIndex] = playerAngles[1];
                g_MortarRotation[newMortarIndex] = 0.0;
                g_MortarHealth[newMortarIndex] = MORTAR_HEALTH;
                g_SteamTimer[newMortarIndex] = INVALID_HANDLE;
                g_ReloadTimer[newMortarIndex] = INVALID_HANDLE;
                g_ExplosionTimer[newMortarIndex] = INVALID_HANDLE;
                g_SteamEntity[newMortarIndex] = INVALID_ENT_REFERENCE;
                g_MortarBlocked[newMortarIndex] = false;
                g_MortarOffMap[newMortarIndex] = false;
                g_MortarShotsFired[newMortarIndex] = 0;
                g_MortarSkyZ[newMortarIndex] = StoreSkyZ(groundPos);
                g_MortarGroundMarker[newMortarIndex] = INVALID_ENT_REFERENCE;
                g_MortarCount++;
                
                UpdateTargetSprite(newMortarIndex);
                
                ShowMortarMenu(client, newMortarIndex, MENU_STATE_NORMAL);
            }
            
            return 0;
        }
        
        int mortar = EntRefToEntIndex(g_SpawnedMortars[mortarIndex]);
        if (mortar == INVALID_ENT_REFERENCE)
            return 0;
        
        if (StrEqual(parts[0], "fire"))
        {
            if (!g_MortarBlocked[mortarIndex])
            {
                float currentTime = GetGameTime();
                if (currentTime - g_LastFireTime[mortarIndex] >= FIRE_COOLDOWN)
                {
                    g_LastFireTime[mortarIndex] = currentTime;
                    float mortarPos[3], mortarAngles[3];
                    GetEntPropVector(mortar, Prop_Send, "m_vecOrigin", mortarPos);
                    GetEntPropVector(mortar, Prop_Send, "m_angRotation", mortarAngles);
                    FireMortarEffects(mortarPos, mortarAngles, mortarIndex);
                }
            }
        }
        else if (StrEqual(parts[0], "inc"))
        {
            g_MortarRange[mortarIndex] += RANGE_STEP;
            if (g_MortarRange[mortarIndex] > RANGE_MAX)
                g_MortarRange[mortarIndex] = RANGE_MAX;
            
            UpdateTargetSprite(mortarIndex);
        }
        else if (StrEqual(parts[0], "dec"))
        {
            g_MortarRange[mortarIndex] -= RANGE_STEP;
            if (g_MortarRange[mortarIndex] < RANGE_MIN)
                g_MortarRange[mortarIndex] = RANGE_MIN;
            
            UpdateTargetSprite(mortarIndex);
        }
        else if (StrEqual(parts[0], "rotleft"))
        {
            RotateMortar(mortarIndex, 5.0);
        }
        else if (StrEqual(parts[0], "rotright"))
        {
            RotateMortar(mortarIndex, -5.0);
        }
        
        ShowMortarMenu(client, mortarIndex, MENU_STATE_NORMAL);
    }
    else if (action == MenuAction_Cancel)
    {
        g_MortarMenuOpen[param1] = false;
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    
    return 0;
}

void RemoveMortar(int mortarIndex)
{
    int mortar = EntRefToEntIndex(g_SpawnedMortars[mortarIndex]);
    if (mortar != INVALID_ENT_REFERENCE && IsValidEntity(mortar))
        AcceptEntityInput(mortar, "Kill");
    
    int helper = EntRefToEntIndex(g_SpawnedHelpers[mortarIndex]);
    if (helper != INVALID_ENT_REFERENCE && IsValidEntity(helper))
        AcceptEntityInput(helper, "Kill");
    
    int sprite = EntRefToEntIndex(g_MortarTargetSprite[mortarIndex]);
    if (sprite != INVALID_ENT_REFERENCE && IsValidEntity(sprite))
        AcceptEntityInput(sprite, "Kill");
    
    // Cancel reload sound timer
    if (g_ReloadTimer[mortarIndex] != INVALID_HANDLE)
    {
        KillTimer(g_ReloadTimer[mortarIndex], true);
        g_ReloadTimer[mortarIndex] = INVALID_HANDLE;
    }
    
    // Cancel explosion timer
    if (g_ExplosionTimer[mortarIndex] != INVALID_HANDLE)
    {
        KillTimer(g_ExplosionTimer[mortarIndex], true);
        g_ExplosionTimer[mortarIndex] = INVALID_HANDLE;
    }
    
    // Cancel steam timer and kill steam entity
    if (g_SteamTimer[mortarIndex] != INVALID_HANDLE)
    {
        KillTimer(g_SteamTimer[mortarIndex], true);
        g_SteamTimer[mortarIndex] = INVALID_HANDLE;
    }
    int steam = EntRefToEntIndex(g_SteamEntity[mortarIndex]);
    if (steam != INVALID_ENT_REFERENCE && IsValidEntity(steam))
        AcceptEntityInput(steam, "Kill");
    g_SteamEntity[mortarIndex] = INVALID_ENT_REFERENCE;
    
    g_SpawnedMortars[mortarIndex] = INVALID_ENT_REFERENCE;
    g_SpawnedHelpers[mortarIndex] = INVALID_ENT_REFERENCE;
    g_MortarTargetSprite[mortarIndex] = INVALID_ENT_REFERENCE;
    g_MortarOwner[mortarIndex] = 0;
    g_MortarRange[mortarIndex] = RANGE_DEFAULT;
    g_MortarSpawnYaw[mortarIndex] = 0.0;
    g_MortarRotation[mortarIndex] = 0.0;
    g_MortarHealth[mortarIndex] = MORTAR_HEALTH;
    g_SteamTimer[mortarIndex] = INVALID_HANDLE;
    g_ReloadTimer[mortarIndex] = INVALID_HANDLE;
    g_ExplosionTimer[mortarIndex] = INVALID_HANDLE;
    g_MortarBlocked[mortarIndex] = false;
    g_MortarBlockReason[mortarIndex][0] = '\0';
    g_MortarOffMap[mortarIndex] = false;
    g_MortarSkyZ[mortarIndex] = 0.0;
    
    int marker = EntRefToEntIndex(g_MortarGroundMarker[mortarIndex]);
    if (marker != INVALID_ENT_REFERENCE && IsValidEntity(marker))
        AcceptEntityInput(marker, "Kill");
    g_MortarGroundMarker[mortarIndex] = INVALID_ENT_REFERENCE;
    g_MortarShotsFired[mortarIndex] = 0;
}

void RotateMortar(int mortarIndex, float rotationDelta)
{
    int mortar = EntRefToEntIndex(g_SpawnedMortars[mortarIndex]);
    if (mortar == INVALID_ENT_REFERENCE)
        return;
    
    // Update rotation offset, clamped to -45 to +45
    g_MortarRotation[mortarIndex] += rotationDelta;
    if (g_MortarRotation[mortarIndex] < -45.0)
        g_MortarRotation[mortarIndex] = -45.0;
    if (g_MortarRotation[mortarIndex] > 45.0)
        g_MortarRotation[mortarIndex] = 45.0;
    
    // Calculate actual yaw: spawn yaw + rotation offset
    float actualYaw = g_MortarSpawnYaw[mortarIndex] + g_MortarRotation[mortarIndex];
    
    // Get current position and apply new rotation
    float mortarPos[3];
    GetEntPropVector(mortar, Prop_Send, "m_vecOrigin", mortarPos);
    
    float newAngles[3];
    newAngles[0] = 0.0;
    newAngles[1] = actualYaw;
    newAngles[2] = 0.0;
    
    TeleportEntity(mortar, mortarPos, newAngles, NULL_VECTOR);
    
    // Update target sprite to match new rotation
    UpdateTargetSprite(mortarIndex);
}

// --- Entity Creation (from working version) ---

int CreateMortarEntity(const float pos[3], float yaw, int owner)
{
    int entity = CreateEntityByName("prop_dynamic");
    
    if (entity == -1)
    {
        LogError("[DeployableMortar] Failed to create entity");
        return -1;
    }
    
    char model[64];
    if (GetClientTeam(owner) == TEAM_AXIS)
        strcopy(model, sizeof(model), MORTAR_MODEL_AXIS);
    else
        strcopy(model, sizeof(model), MORTAR_MODEL);
    
    DispatchKeyValue(entity, "model", model);
    DispatchKeyValue(entity, "solid", "6");
    DispatchKeyValue(entity, "spawnflags", "0");
    
    float angles[3];
    angles[0] = 0.0;
    angles[1] = yaw;
    angles[2] = 0.0;
    
    TeleportEntity(entity, pos, angles, NULL_VECTOR);
    
    if (!DispatchSpawn(entity))
    {
        LogError("[DeployableMortar] Failed to spawn entity");
        return -1;
    }
    
    ActivateEntity(entity);
    
    SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
    SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
    SetEntProp(entity, Prop_Send, "m_usSolidFlags", 8);
    AcceptEntityInput(entity, "EnableCollision");
    
    SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", owner);
    
    return entity;
}

int CreateHelperEntity(const float pos[3], int mortarEntity, int mortarIndex)
{
    int entity = CreateEntityByName("prop_physics_override");
    
    if (entity == -1)
    {
        LogError("[DeployableMortar] Failed to create helper entity");
        return -1;
    }
    
    DispatchKeyValue(entity, "model", HELPER_MODEL);
    DispatchKeyValue(entity, "rendermode", "10");
    DispatchKeyValue(entity, "renderamt", "0");
    DispatchKeyValue(entity, "disableshadows", "1");
    DispatchKeyValue(entity, "spawnflags", "256");
    
    float helperPos[3];
    helperPos[0] = pos[0];
    helperPos[1] = pos[1];
    helperPos[2] = pos[2];
    
    TeleportEntity(entity, helperPos, NULL_VECTOR, NULL_VECTOR);
    
    if (!DispatchSpawn(entity))
    {
        LogError("[DeployableMortar] Failed to spawn helper entity");
        return -1;
    }
    
    ActivateEntity(entity);
    AcceptEntityInput(entity, "DisableMotion");
    
    SetEntProp(entity, Prop_Data, "m_takedamage", 2);
    SetEntProp(entity, Prop_Data, "m_iHealth", 999999);
    
    // Store mortar entity ref and index
    SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", mortarEntity);
    SetEntProp(entity, Prop_Data, "m_iMaxHealth", mortarIndex);
    
    SDKHook(entity, SDKHook_OnTakeDamage, OnHelperDamage);
    
    return entity;
}

// --- Damage Handler (from working version, adapted for range) ---

public Action OnHelperDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!IsValidClient(attacker, false, true))
        return Plugin_Continue;
    
    // Get mortar entity from helper owner
    int mortarEntity = GetEntPropEnt(victim, Prop_Data, "m_hOwnerEntity");
    if (!IsValidEntity(mortarEntity))
        return Plugin_Continue;
    
    // Get mortar owner from mortar
    int mortarOwner = GetEntPropEnt(mortarEntity, Prop_Data, "m_hOwnerEntity");
    int mortarIndex = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
    
    if (attacker == mortarOwner)
    {
        // Owner shooting = fire mortar
        if (g_MortarBlocked[mortarIndex] || g_MortarOffMap[mortarIndex])
            return Plugin_Handled;
        
        float currentTime = GetGameTime();
        if (currentTime - g_LastFireTime[mortarIndex] < FIRE_COOLDOWN)
            return Plugin_Handled;
        
        g_LastFireTime[mortarIndex] = currentTime;
        
        float mortarPos[3], mortarAngles[3];
        GetEntPropVector(mortarEntity, Prop_Send, "m_vecOrigin", mortarPos);
        GetEntPropVector(mortarEntity, Prop_Send, "m_angRotation", mortarAngles);
        
        FireMortarEffects(mortarPos, mortarAngles, mortarIndex);
        
        // Refresh menu to disable Fire Mortar during reload
        if (IsValidClient(mortarOwner) && IsPlayerAlive(mortarOwner))
            ShowMortarMenu(mortarOwner, mortarIndex, MENU_STATE_NORMAL);
        
        return Plugin_Handled;
    }
    
    // Check if attacker is an enemy (different team)
    if (!IsValidClient(mortarOwner) || GetClientTeam(attacker) == GetClientTeam(mortarOwner))
        return Plugin_Handled;
    
    // Enemy damage - apply to mortar health
    g_MortarHealth[mortarIndex] -= RoundToNearest(damage);
    
    if (g_MortarHealth[mortarIndex] <= 0)
    {
        float mortarPos[3];
        GetEntPropVector(mortarEntity, Prop_Send, "m_vecOrigin", mortarPos);
        DestroyMortar(mortarIndex, mortarOwner, attacker, mortarPos);
    }
    
    return Plugin_Handled;
}

void DestroyMortar(int mortarIndex, int owner, int destroyer, const float pos[3])
{
    // Log destruction for HLStatsX
    if (destroyer != -1 && IsValidClient(destroyer) && IsValidClient(owner))
    {
        char destroyerName[MAX_NAME_LENGTH], ownerName[MAX_NAME_LENGTH];
        GetClientName(destroyer, destroyerName, sizeof(destroyerName));
        GetClientName(owner, ownerName, sizeof(ownerName));
        
        char destroyerSteamId[32], ownerSteamId[32];
        if (IsFakeClient(destroyer))
            strcopy(destroyerSteamId, sizeof(destroyerSteamId), "BOT");
        else
            GetClientAuthId(destroyer, AuthId_Steam2, destroyerSteamId, sizeof(destroyerSteamId));
        
        if (IsFakeClient(owner))
            strcopy(ownerSteamId, sizeof(ownerSteamId), "BOT");
        else
            GetClientAuthId(owner, AuthId_Steam2, ownerSteamId, sizeof(ownerSteamId));
        
        LogToGame("\"%s<%d><%s><%s>\" triggered \"mortar_deployable_destroyed\" against \"%s<%d><%s><%s>\"",
            destroyerName, GetClientUserId(destroyer), destroyerSteamId, GetClientTeam(destroyer) == TEAM_ALLIES ? "Allies" : "Axis",
            ownerName, GetClientUserId(owner), ownerSteamId, GetClientTeam(owner) == TEAM_ALLIES ? "Allies" : "Axis");
    }
    // Spawn destruction effect based on team
    if (IsValidClient(owner) && GetClientTeam(owner) == TEAM_AXIS)
    {
        // Axis: spawn destroyed model prop_dynamic, remove after 15 seconds
        int destroyed = CreateEntityByName("prop_dynamic");
        if (destroyed != -1)
        {
            DispatchKeyValue(destroyed, "model", MORTAR_MODEL_AXIS_DESTROYED);
            DispatchKeyValue(destroyed, "solid", "0");
            TeleportEntity(destroyed, pos, NULL_VECTOR, NULL_VECTOR);
            DispatchSpawn(destroyed);
            ActivateEntity(destroyed);
            CreateTimer(15.0, Timer_RemoveEntity, EntIndexToEntRef(destroyed));
        }
    }
    else
    {
        // Allies: spawn gibs
        SpawnGib("models/surgeon/mortar34_gib1.mdl", pos, "-65 250 0");
        SpawnGib("models/surgeon/mortar34_gib2.mdl", pos, "0 250 0");
        SpawnGib("models/surgeon/mortar34_gib3.mdl", pos, "-30 300 0");
        SpawnGib("models/surgeon/mortar34_gib3.mdl", pos, "-30 200 0");
    }
    
    // Spawn dust
    int dust = CreateEntityByName("env_dustpuff");
    if (dust != -1)
    {
        DispatchKeyValue(dust, "color", "128 128 128");
        DispatchKeyValue(dust, "speed", "16");
        DispatchKeyValue(dust, "scale", "32");
        DispatchKeyValue(dust, "angles", "270 180 0");
        TeleportEntity(dust, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(dust);
        ActivateEntity(dust);
        AcceptEntityInput(dust, "SpawnDust");
        CreateTimer(1.0, Timer_RemoveEntity, EntIndexToEntRef(dust));
    }
    
    RemoveMortar(mortarIndex);
    
    // Refresh owner menu to show Place Mortar
    if (IsValidClient(owner) && IsPlayerAlive(owner))
        ShowMortarMenu(owner, -1, MENU_STATE_NORMAL);
    else
        CancelClientMenu(owner);
}

void SpawnGib(const char[] model, const float pos[3], const char[] angles)
{
    int gib = CreateEntityByName("prop_physics_multiplayer");
    if (gib == -1)
        return;
    
    DispatchKeyValue(gib, "model", model);
    DispatchKeyValue(gib, "spawnflags", "9220");
    DispatchKeyValue(gib, "fademindist", "800");
    DispatchKeyValue(gib, "fademaxdist", "900");
    DispatchKeyValue(gib, "fadescale", "1");
    DispatchKeyValue(gib, "physdamagescale", "0.1");
    DispatchKeyValue(gib, "angles", angles);
    
    TeleportEntity(gib, pos, NULL_VECTOR, NULL_VECTOR);
    DispatchSpawn(gib);
    ActivateEntity(gib);
    CreateTimer(15.0, Timer_RemoveEntity, EntIndexToEntRef(gib));
}

void DrawTargetBeam(int mortarIndex, const float fromPos[3], const float toPos[3])
{
    int owner = g_MortarOwner[mortarIndex];
    
    // Build list of clients to send beam to - admins only, fall back to owner
    int[] targets = new int[MaxClients];
    int count = 0;
    bool adminFound = false;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;
        if (GetUserFlagBits(i) != 0)
        {
            targets[count++] = i;
            adminFound = true;
        }
    }
    
    // No admins online - send to owner only
    if (!adminFound && IsValidClient(owner))
    {
        targets[count++] = owner;
    }
    
    if (count == 0)
        return;
    
    int color[4] = {0, 255, 0, 200};
    
    TE_SetupBeamPoints(
        fromPos,
        toPos,
        g_BeamSprite,
        g_BeamSprite,
        0,      // startframe
        0,      // framerate
        25.0,   // life (max allowed by engine)
        4.0,    // width
        4.0,    // endwidth
        0,      // fade length
        0.0,    // amplitude
        color,
        0       // flags
    );
    
    TE_Send(targets, count);
}

// --- Firing Effects ---

void UpdateTargetSprite(int mortarIndex)
{
    int mortar = EntRefToEntIndex(g_SpawnedMortars[mortarIndex]);
    if (mortar == INVALID_ENT_REFERENCE)
        return;
    
    float mortarPos[3], mortarAngles[3];
    GetEntPropVector(mortar, Prop_Send, "m_vecOrigin", mortarPos);
    GetEntPropVector(mortar, Prop_Send, "m_angRotation", mortarAngles);
    
    float targetPos[3];
    targetPos[0] = mortarPos[0] + (float(g_MortarRange[mortarIndex]) * Cosine(DegToRad(mortarAngles[1])));
    targetPos[1] = mortarPos[1] + (float(g_MortarRange[mortarIndex]) * Sine(DegToRad(mortarAngles[1])));
    targetPos[2] = mortarPos[2];
    
    float groundPos[3];
    if (!FindGroundAt(targetPos, mortarPos, g_MortarSkyZ[mortarIndex], groundPos))
    {
        bool wasOffMap = g_MortarOffMap[mortarIndex];
        g_MortarOffMap[mortarIndex] = true;
        if (!wasOffMap)
        {
            int owner = g_MortarOwner[mortarIndex];
            if (IsValidClient(owner) && IsPlayerAlive(owner))
                ShowMortarMenu(owner, mortarIndex, MENU_STATE_NORMAL);
        }
        return;
    }
    
    // Ground found - clear off-map state
    bool wasOffMap = g_MortarOffMap[mortarIndex];
    g_MortarOffMap[mortarIndex] = false;
    
    // Check restricted zones and update blocked state
    bool wasBlocked = g_MortarBlocked[mortarIndex];
    g_MortarBlocked[mortarIndex] = IsTargetInRestrictedZone(groundPos, g_MortarBlockReason[mortarIndex], sizeof(g_MortarBlockReason[]));
    
    // Refresh menu if blocked or off-map state changed
    if (wasBlocked != g_MortarBlocked[mortarIndex] || wasOffMap != g_MortarOffMap[mortarIndex])
    {
        int owner = g_MortarOwner[mortarIndex];
        if (IsValidClient(owner) && IsPlayerAlive(owner))
            ShowMortarMenu(owner, mortarIndex, MENU_STATE_NORMAL);
    }
    
    int oldSprite = EntRefToEntIndex(g_MortarTargetSprite[mortarIndex]);
    if (oldSprite != INVALID_ENT_REFERENCE && IsValidEntity(oldSprite))
        AcceptEntityInput(oldSprite, "Kill");
    
    int oldMarker = EntRefToEntIndex(g_MortarGroundMarker[mortarIndex]);
    if (oldMarker != INVALID_ENT_REFERENCE && IsValidEntity(oldMarker))
        AcceptEntityInput(oldMarker, "Kill");
    
    // Spawn smoke grenade model at ground level
    int owner = g_MortarOwner[mortarIndex];
    char smokeModel[64];
    if (IsValidClient(owner) && GetClientTeam(owner) == TEAM_AXIS)
        strcopy(smokeModel, sizeof(smokeModel), "models/weapons/w_smoke_ger.mdl");
    else
        strcopy(smokeModel, sizeof(smokeModel), "models/weapons/w_smoke_us.mdl");
    
    int marker = CreateEntityByName("prop_dynamic");
    if (marker != -1)
    {
        float flatAngles[3] = {90.0, 0.0, 0.0};
        DispatchKeyValue(marker, "model", smokeModel);
        DispatchKeyValue(marker, "solid", "0");
        TeleportEntity(marker, groundPos, flatAngles, NULL_VECTOR);
        DispatchSpawn(marker);
        ActivateEntity(marker);
        g_MortarGroundMarker[mortarIndex] = EntIndexToEntRef(marker);
    }
    
    // Spawn persistent smokestack 20 units above ground
    int smokestack = CreateEntityByName("env_smokestack");
    if (smokestack != -1)
    {
        float smokePos[3];
        smokePos[0] = groundPos[0];
        smokePos[1] = groundPos[1];
        smokePos[2] = groundPos[2] + 20.0;
        
        DispatchKeyValue(smokestack, "InitialState", "1");
        DispatchKeyValue(smokestack, "BaseSpread", "20");
        DispatchKeyValue(smokestack, "SpreadSpeed", "15");
        DispatchKeyValue(smokestack, "Speed", "30");
        DispatchKeyValue(smokestack, "StartSize", "8");
        DispatchKeyValue(smokestack, "EndSize", "40");
        DispatchKeyValue(smokestack, "Rate", "20");
        DispatchKeyValue(smokestack, "JetLength", "80");
        DispatchKeyValue(smokestack, "Twist", "2");
        DispatchKeyValue(smokestack, "RenderColor", "0 255 0");
        DispatchKeyValue(smokestack, "RenderAmt", "200");
        
        TeleportEntity(smokestack, smokePos, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(smokestack);
        ActivateEntity(smokestack);
        AcceptEntityInput(smokestack, "TurnOn");
        
        g_MortarTargetSprite[mortarIndex] = EntIndexToEntRef(smokestack);
    }
    
    // Draw debug targeting beam if enabled
    if (g_CvarDebugBeam.BoolValue && g_BeamSprite != -1)
        DrawTargetBeam(mortarIndex, mortarPos, groundPos);
}

void FireMortarEffects(const float pos[3], const float mortarAngles[3], int mortarIndex)
{
    float explosionPos[3];
    explosionPos[0] = pos[0] + (float(g_MortarRange[mortarIndex]) * Cosine(DegToRad(mortarAngles[1])));
    explosionPos[1] = pos[1] + (float(g_MortarRange[mortarIndex]) * Sine(DegToRad(mortarAngles[1])));
    explosionPos[2] = pos[2];
    
    float groundExplosionPos[3];
    if (!FindGroundAt(explosionPos, pos, g_MortarSkyZ[mortarIndex], groundExplosionPos))
        return;
    
    // Increment shot counter only after confirmed valid target
    g_MortarShotsFired[mortarIndex]++;
    
    int maxShots = g_CvarMaxShots.IntValue;
    bool lastShot = (maxShots > 0 && g_MortarShotsFired[mortarIndex] >= maxShots);
    
    // Store for kill detection
    g_LastExplosionPos[mortarIndex][0] = groundExplosionPos[0];
    g_LastExplosionPos[mortarIndex][1] = groundExplosionPos[1];
    g_LastExplosionPos[mortarIndex][2] = groundExplosionPos[2];
    
    EmitSoundToAll(SOUND_INCOMING, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, groundExplosionPos);
    
    DataPack explosionPack = new DataPack();
    explosionPack.WriteFloat(groundExplosionPos[0]);
    explosionPack.WriteFloat(groundExplosionPos[1]);
    explosionPack.WriteFloat(groundExplosionPos[2]);
    explosionPack.WriteCell(mortarIndex);
    g_ExplosionTimer[mortarIndex] = CreateTimer(2.0, Timer_CreateExplosion, explosionPack);
    
    DataPack soundPack = new DataPack();
    soundPack.WriteFloat(pos[0]);
    soundPack.WriteFloat(pos[1]);
    soundPack.WriteFloat(pos[2]);
    CreateTimer(0.1, Timer_PlayFiringSound, soundPack);
    
    CreateMortarSteam(pos, mortarAngles, mortarIndex);
    
    DataPack reloadPack = new DataPack();
    reloadPack.WriteFloat(pos[0]);
    reloadPack.WriteFloat(pos[1]);
    reloadPack.WriteFloat(pos[2]);
    reloadPack.WriteCell(mortarIndex);
    g_ReloadTimer[mortarIndex] = CreateTimer(5.0, Timer_PlayReloadSound, reloadPack);
    
    // Destroy mortar after last shot (after reload completes)
    if (lastShot)
    {
        DataPack destroyPack = new DataPack();
        destroyPack.WriteCell(mortarIndex);
        destroyPack.WriteFloat(pos[0]);
        destroyPack.WriteFloat(pos[1]);
        destroyPack.WriteFloat(pos[2]);
        CreateTimer(2.1, Timer_DestroyAfterLastShot, destroyPack);
    }
}

void CreateMortarSteam(const float pos[3], const float mortarAngles[3], int mortarIndex)
{
    int steam = CreateEntityByName("env_steam");
    if (steam == -1)
        return;
    
    float steamPos[3];
    steamPos[0] = pos[0];
    steamPos[1] = pos[1];
    steamPos[2] = pos[2] + 48.0;
    
    float steamAngles[3];
    steamAngles[0] = mortarAngles[0] - 45.0;
    steamAngles[1] = mortarAngles[1];
    steamAngles[2] = mortarAngles[2];
    
    DispatchKeyValue(steam, "SpawnFlags", "1");
    DispatchKeyValue(steam, "Type", "1");
    DispatchKeyValue(steam, "InitialState", "1");
    DispatchKeyValue(steam, "Spreadspeed", "10");
    DispatchKeyValue(steam, "Speed", "800");
    DispatchKeyValue(steam, "Startsize", "12");
    DispatchKeyValue(steam, "EndSize", "100");
    DispatchKeyValue(steam, "Rate", "100");
    DispatchKeyValue(steam, "JetLength", "500");
    DispatchKeyValue(steam, "RenderColor", "0 255 0");
    DispatchKeyValue(steam, "RenderAmt", "255");
    
    DispatchSpawn(steam);
    TeleportEntity(steam, steamPos, steamAngles, NULL_VECTOR);
    ActivateEntity(steam);
    AcceptEntityInput(steam, "TurnOn");
    
    g_SteamEntity[mortarIndex] = EntIndexToEntRef(steam);
    
    DataPack steamPack = new DataPack();
    steamPack.WriteCell(EntIndexToEntRef(steam));
    steamPack.WriteCell(mortarIndex);
    g_SteamTimer[mortarIndex] = CreateTimer(2.0, Timer_TurnOffSteam, steamPack);
}

// --- Timers ---

public Action Timer_PlayFiringSound(Handle timer, DataPack pack)
{
    pack.Reset();
    float pos[3];
    pos[0] = pack.ReadFloat();
    pos[1] = pack.ReadFloat();
    pos[2] = pack.ReadFloat();
    delete pack;
    
    EmitSoundToAll(SOUND_FIRING, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos);
    return Plugin_Stop;
}

public Action Timer_PlayReloadSound(Handle timer, DataPack pack)
{
    pack.Reset();
    float pos[3];
    pos[0] = pack.ReadFloat();
    pos[1] = pack.ReadFloat();
    pos[2] = pack.ReadFloat();
    int mortarIndex = pack.ReadCell();
    delete pack;
    
    g_ReloadTimer[mortarIndex] = INVALID_HANDLE;
    
    EmitSoundToAll(SOUND_RELOAD, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos);
    
    // Refresh menu to re-enable Fire Mortar
    int owner = g_MortarOwner[mortarIndex];
    if (IsValidClient(owner) && IsPlayerAlive(owner))
        ShowMortarMenu(owner, mortarIndex, MENU_STATE_NORMAL);
    
    return Plugin_Stop;
}

void CreateShakeEntity(const float pos[3])
{
    int shake = CreateEntityByName("env_shake");
    if (shake != -1)
    {
        DispatchKeyValue(shake, "amplitude", "14");
        DispatchKeyValue(shake, "duration", "1");
        DispatchKeyValue(shake, "frequency", "1.5");
        DispatchKeyValue(shake, "radius", "1500");
        TeleportEntity(shake, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(shake);
        ActivateEntity(shake);
        AcceptEntityInput(shake, "StartShake");
        CreateTimer(2.0, Timer_RemoveEntity, EntIndexToEntRef(shake));
    }
}

public Action Timer_CreateExplosion(Handle timer, DataPack pack)
{
    pack.Reset();
    float pos[3];
    pos[0] = pack.ReadFloat();
    pos[1] = pack.ReadFloat();
    pos[2] = pack.ReadFloat();
    int mortarIndex = pack.ReadCell();
    delete pack;
    
    g_ExplosionTimer[mortarIndex] = INVALID_HANDLE;
    
    int explosion = CreateEntityByName("env_explosion");
    if (explosion != -1)
    {
        DispatchKeyValue(explosion, "iMagnitude", "200");
        DispatchKeyValue(explosion, "rendermode", "5");
        TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(explosion);
        ActivateEntity(explosion);
        AcceptEntityInput(explosion, "Explode");
        CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(explosion));
    }
    
    CreateShakeEntity(pos);
    
    return Plugin_Stop;
}

public Action Timer_TurnOffSteam(Handle timer, DataPack pack)
{
    pack.Reset();
    int entRef = pack.ReadCell();
    int mortarIndex = pack.ReadCell();
    delete pack;
    
    g_SteamTimer[mortarIndex] = INVALID_HANDLE;
    
    int entity = EntRefToEntIndex(entRef);
    if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
    {
        AcceptEntityInput(entity, "TurnOff");
        char classname[64];
        GetEdictClassname(entity, classname, sizeof(classname));
        if (StrEqual(classname, "env_steam", false))
            RemoveEdict(entity);
    }
    return Plugin_Stop;
}

public Action Timer_DestroyAfterLastShot(Handle timer, DataPack pack)
{
    pack.Reset();
    int mortarIndex = pack.ReadCell();
    float pos[3];
    pos[0] = pack.ReadFloat();
    pos[1] = pack.ReadFloat();
    pos[2] = pack.ReadFloat();
    delete pack;
    
    // Verify mortar still exists and shot count hasn't been reset (e.g. manually removed)
    if (g_MortarOwner[mortarIndex] == 0)
        return Plugin_Stop;
    
    int owner = g_MortarOwner[mortarIndex];
    DestroyMortar(mortarIndex, owner, -1, pos);
    
    return Plugin_Stop;
}

public Action Timer_RemoveEntity(Handle timer, int entRef)
{
    int entity = EntRefToEntIndex(entRef);
    if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
        AcceptEntityInput(entity, "Kill");
    return Plugin_Stop;
}

public Action Timer_TurnOffSmokestack(Handle timer, int entRef)
{
    int smokestack = EntRefToEntIndex(entRef);
    if (smokestack != INVALID_ENT_REFERENCE && IsValidEntity(smokestack))
    {
        AcceptEntityInput(smokestack, "TurnOff");
        // Remove after a delay to let smoke dissipate
        CreateTimer(5.0, Timer_RemoveEntity, entRef);
    }
    return Plugin_Stop;
}

// --- Utilities ---

void RemoveAllMortars()
{
    for (int i = 0; i < g_MortarCount; i++)
    {
        RemoveMortar(i);
    }
    g_MortarCount = 0;
}

bool IsTargetInRestrictedZone(const float targetPos[3], char[] reason, int maxlen)
{
    static const char restrictedEntities[][] = {
        "dod_control_point",
        "dod_bomb_target",
        "dod_bomb_dispenser",
        "info_teleport_destination",
        "info_player_allies",
        "info_player_axis"
    };
    
    static const char restrictedReasons[][] = {
        "Flag",
        "Bomb Plant",
        "Bomb Disp.",
        "Spawn",
        "Spawn",
        "Spawn"
    };
    
    float checkRadius = 300.0;
    
    for (int t = 0; t < 6; t++)
    {
        int ent = -1;
        while ((ent = FindEntityByClassname(ent, restrictedEntities[t])) != -1)
        {
            // Skip dod_bomb_target entities that have already been destroyed (EF_NODRAW set)
            if (StrEqual(restrictedEntities[t], "dod_bomb_target"))
            {
                int effects = GetEntProp(ent, Prop_Send, "m_fEffects");
                if (effects & 32)
                    continue;
            }
            
            float entPos[3];
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entPos);
            
            if (GetVectorDistance(targetPos, entPos) <= checkRadius)
            {
                strcopy(reason, maxlen, restrictedReasons[t]);
                return true;
            }
        }
    }
    
    reason[0] = '\0';
    return false;
}

bool TraceToGround(const float start[3], float result[3])
{
    float end[3];
    end[0] = start[0];
    end[1] = start[1];
    end[2] = start[2] - 10000.0;
    
    TR_TraceRayFilter(start, end, MASK_SOLID, RayType_EndPoint, TraceFilter_IgnorePlayers);
    
    if (TR_DidHit())
    {
        TR_GetEndPosition(result);
        return true;
    }
    
    return false;
}

float StoreSkyZ(const float mortarPos[3])
{
    float upStart[3];
    upStart[0] = mortarPos[0];
    upStart[1] = mortarPos[1];
    upStart[2] = mortarPos[2] + 50.0;
    
    float upEnd[3];
    upEnd[0] = mortarPos[0];
    upEnd[1] = mortarPos[1];
    upEnd[2] = mortarPos[2] + 10000.0;
    
    TR_TraceRayFilter(upStart, upEnd, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_IgnorePlayers);
    
    if (TR_DidHit())
    {
        float ceilingPos[3];
        TR_GetEndPosition(ceilingPos);
        return ceilingPos[2] - 16.0;
    }
    
    return mortarPos[2] + 10000.0;
}

// Two-stage trace: use stored sky Z, then trace straight down at the target XY.
bool FindGroundAt(const float targetXY[3], const float mortarPos[3], float skyZ, float result[3])
{
    // Stage 2: trace DOWN at the target XY from stored sky Z to well below the mortar.
    float downStart[3];
    downStart[0] = targetXY[0];
    downStart[1] = targetXY[1];
    downStart[2] = skyZ;
    
    float downEnd[3];
    downEnd[0] = targetXY[0];
    downEnd[1] = targetXY[1];
    downEnd[2] = mortarPos[2] - 10000.0;
    
    TR_TraceRayFilter(downStart, downEnd, MASK_SOLID, RayType_EndPoint, TraceFilter_IgnorePlayers);
    
    if (TR_DidHit() && !TR_StartSolid())
    {
        TR_GetEndPosition(result);
        return true;
    }
    
    return false;
}

bool IsUnderRoof(const float mortarPos[3])
{
    float upPos[3];
    upPos[0] = mortarPos[0];
    upPos[1] = mortarPos[1];
    upPos[2] = mortarPos[2] + 200.0;
    
    TR_TraceRayFilter(mortarPos, upPos, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_IgnorePlayers);
    
    return TR_DidHit();
}

public bool TraceFilter_IgnorePlayers(int entity, int contentsMask, any data)
{
    if (entity > 0 && entity <= MaxClients)
        return false;
    return true;
}

bool IsValidClient(int client, bool checkAlive = false, bool allowBots = false)
{
    if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
    {
        if (!allowBots && IsFakeClient(client))
            return false;
        if (checkAlive && !IsPlayerAlive(client))
            return false;
        return true;
    }
    return false;
}
