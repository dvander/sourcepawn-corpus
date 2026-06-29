#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <math>

#define WHISKERS_COUNT 4
#define RING_RADIUS_START 1.0
#define RING_RADIUS_END 25.0
#define RING_LIFETIME 1.0

// Config-controlled variables
float WHISKER_LENGTH;
float WHISKER_ANGLE;
int MAX_BOUNCES;
bool SHOW_WHISKERS;

// Global variables
ArrayList g_ActiveProjectiles;
StringMap g_hProjectileBounces;
bool g_PluginEnabled = true;
char g_ConfigPath[PLATFORM_MAX_PATH];

public Plugin myinfo = {
    name = "Ricochet",
    author = "vexx-sm",
    description = "Projectile guidance system using whisker simulation",
    version = "1.0.0",
    url = ""
};

public void OnPluginStart()
{
    g_ActiveProjectiles = new ArrayList();
    g_hProjectileBounces = new StringMap();
    RegAdminCmd("sm_rico", Command_RicoMenu, ADMFLAG_ROOT, "Opens Ricochet control menu");
    BuildPath(Path_SM, g_ConfigPath, sizeof(g_ConfigPath), "configs/ricochet.cfg");
    LoadConfig();
}

public void OnMapStart()
{
    if (g_ActiveProjectiles != null)
        g_ActiveProjectiles.Clear();
    if (g_hProjectileBounces != null)
        g_hProjectileBounces.Clear();
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity <= 0 || !IsValidEntity(entity))
        return;
        
    if (!IsValidProjectile(classname))
        return;
        
    RequestFrame(OnEntitySpawned, EntIndexToEntRef(entity));
}

public void OnEntitySpawned(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);
    
    if (entity == INVALID_ENT_REFERENCE)
        return;
        
    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));
    
    if (IsValidProjectile(classname))
    {
        g_ActiveProjectiles.Push(entityRef);
        
        float velocity[3];
        GetEntPropVector(entity, Prop_Data, "m_vecVelocity", velocity);
        float speed = GetVectorLength(velocity);
        float updateRate = 0.1 * (1000.0 / speed);
        updateRate = ClampFloat(updateRate, 0.01, 0.1);
        
        CreateTimer(updateRate, Timer_UpdateWhiskers, entityRef, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        
        char entKey[16];
        IntToString(entityRef, entKey, sizeof(entKey));
        g_hProjectileBounces.SetValue(entKey, 0);
    }
}

public void OnEntityDestroyed(int entity)
{
    if (entity > 0)
    {
        char entKey[16];
        IntToString(EntIndexToEntRef(entity), entKey, sizeof(entKey));
        g_hProjectileBounces.Remove(entKey);
    }
}

bool IsValidProjectile(const char[] classname)
{
    return (
        StrEqual(classname, "tf_projectile_rocket") ||
        StrEqual(classname, "tf_projectile_pipe") ||
        StrEqual(classname, "tf_projectile_pipe_remote") ||
        StrEqual(classname, "tf_projectile_arrow") ||
        StrEqual(classname, "tf_projectile_healing_bolt") ||
        StrEqual(classname, "tf_projectile_energy_ball") ||
        StrEqual(classname, "tf_projectile_flare") ||
        StrEqual(classname, "tf_projectile_sentryrocket") ||
        StrEqual(classname, "tf_projectile_cleaver") ||
        StrEqual(classname, "tf_projectile_ball_ornament") ||
        StrEqual(classname, "tf_projectile_jar") ||
        StrEqual(classname, "tf_projectile_jar_milk") ||
        StrEqual(classname, "tf_projectile_jar_gas") ||
        StrEqual(classname, "tf_projectile_stun_ball") ||
        StrEqual(classname, "tf_projectile_grapplinghook") ||
        StrEqual(classname, "tf_projectile_balloffire") ||
        StrEqual(classname, "tf_projectile_rocket_festive") ||
        StrEqual(classname, "tf_projectile_arrow_festive") ||
        StrEqual(classname, "tf_projectile_flare_festive") ||
        StrEqual(classname, "tf_projectile_energy_ring")
    );
}

void CalculateWhiskerPositions(int entity, float whiskerStarts[4][3], float whiskerEnds[4][3])
{
    float entityPos[3];
    float entityVel[3];
    float forwardVec[3];
    float rightVec[3];
    float upVec[3];
    float whiskerDir[3];
    float angles[4];
    float rad;
    
    angles[0] = 0.0;
    angles[1] = 90.0;
    angles[2] = 180.0;
    angles[3] = 270.0;
    
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityPos);
    GetEntPropVector(entity, Prop_Data, "m_vecVelocity", entityVel);
    
    NormalizeVector(entityVel, forwardVec);
    
    upVec[0] = 0.0;
    upVec[1] = 0.0;
    upVec[2] = 1.0;
    
    GetVectorCrossProduct(forwardVec, upVec, rightVec);
    NormalizeVector(rightVec, rightVec);
    GetVectorCrossProduct(rightVec, forwardVec, upVec);
    NormalizeVector(upVec, upVec);
    
    float radAngle = DegToRad(WHISKER_ANGLE);
    
    for (int i = 0; i < WHISKERS_COUNT; i++)
    {
        rad = DegToRad(angles[i]);
        
        for (int axis = 0; axis < 3; axis++)
        {
            whiskerDir[axis] = forwardVec[axis] * Cosine(radAngle) +
                              (rightVec[axis] * Cosine(rad) + upVec[axis] * Sine(rad)) * Sine(radAngle);
        }
        
        whiskerStarts[i] = entityPos;
        for (int axis = 0; axis < 3; axis++)
        {
            whiskerEnds[i][axis] = entityPos[axis] + (whiskerDir[axis] * WHISKER_LENGTH);
        }
    }
}

void ProcessWhiskerCollisions(int entity, float whiskerStarts[4][3], float whiskerEnds[4][3])
{
    if (!g_PluginEnabled)
        return;
        
    float hitPos[3];
    float hitNormal[3];
    float currentVel[3];
    bool needsAlignment = false;
    float alignmentNormal[3] = {0.0, 0.0, 0.0};
    
    char entKey[16];
    IntToString(EntIndexToEntRef(entity), entKey, sizeof(entKey));
    
    int bounces = 0;
    g_hProjectileBounces.GetValue(entKey, bounces);
    
    if (bounces >= MAX_BOUNCES)
        return;
    
    GetEntPropVector(entity, Prop_Data, "m_vecVelocity", currentVel);
    float speed = GetVectorLength(currentVel);
    
    for (int i = 0; i < WHISKERS_COUNT; i++)
    {
        Handle trace = TR_TraceRayFilterEx(whiskerStarts[i], whiskerEnds[i], MASK_SOLID, RayType_EndPoint, TraceFilter_NoPlayers, entity);
        
        if (TR_DidHit(trace))
        {
            TR_GetEndPosition(hitPos, trace);
            TR_GetPlaneNormal(trace, hitNormal);
            
            AddVectors(alignmentNormal, hitNormal, alignmentNormal);
            needsAlignment = true;
        }
        
        delete trace;
    }
    
    if (needsAlignment)
    {
        NormalizeVector(alignmentNormal, alignmentNormal);
        float newVel[3];
        
        float dot = GetVectorDotProduct(currentVel, alignmentNormal);
        for (int i = 0; i < 3; i++)
        {
            newVel[i] = currentVel[i] - (dot * alignmentNormal[i]);
        }
        
        NormalizeVector(newVel, newVel);
        ScaleVector(newVel, speed);
        
        // Get current position for the ring effect
        float currentPos[3];
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", currentPos);
        CreateAlignmentRing(currentPos);
        
        TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, newVel);
        
        bounces++;
        g_hProjectileBounces.SetValue(entKey, bounces);
    }
}

void CreateAlignmentRing(const float pos[3])
{
    float startRadius = 1.0;
    float endRadius = 25.0;
    int modelIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
    int haloIndex = PrecacheModel("materials/sprites/halo01.vmt");
    int startFrame = 0;
    int frameRate = 15;
    float life = 0.2;
    float width = 3.0;
    float amplitude = 0.0;
    int speed = 10;
    int flags = 0;
    
    int color[4];
    color[0] = 255;
    color[1] = 200;
    color[2] = 0;
    color[3] = 255;
    
    TE_SetupBeamRingPoint(pos, startRadius, endRadius, modelIndex, haloIndex, 
        startFrame, frameRate, life, width, amplitude, color, speed, flags);
    TE_SendToAll();
}

public Action Timer_UpdateWhiskers(Handle timer, any entityRef)
{
    int entity = EntRefToEntIndex(entityRef);
    
    if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity))
        return Plugin_Stop;
        
    float whiskerStarts[4][3];
    float whiskerEnds[4][3];
    
    CalculateWhiskerPositions(entity, whiskerStarts, whiskerEnds);
    ProcessWhiskerCollisions(entity, whiskerStarts, whiskerEnds);
    
    if (SHOW_WHISKERS)
    {
        for (int i = 0; i < WHISKERS_COUNT; i++)
        {
            TE_SetupBeamPoints(
                whiskerStarts[i], 
                whiskerEnds[i],
                PrecacheModel("materials/sprites/laserbeam.vmt"),
                PrecacheModel("materials/sprites/halo01.vmt"),
                0, 0, 0.1, 3.0, 3.0, 0, 0.0,
                {255, 0, 0, 255}, 0
            );
            TE_SendToAll(0.0);
        }
    }
    
    return Plugin_Continue;
}

public Action Command_RicoMenu(int client, int args)
{
    Menu menu = new Menu(RicoMenuHandler);
    menu.SetTitle("Ricochet Controls");
    menu.AddItem("toggle", g_PluginEnabled ? "Toggle Ricochet: [ON]" : "Toggle Ricochet: [OFF]");
    menu.AddItem("reload", "Reload Configuration");
    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public int RicoMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            
            if (StrEqual(info, "toggle"))
            {
                g_PluginEnabled = !g_PluginEnabled;
                PrintToChat(param1, "[Ricochet] Plugin %s", g_PluginEnabled ? "enabled" : "disabled");
            }
            else if (StrEqual(info, "reload"))
            {
                LoadConfig();
                PrintToChat(param1, "[Ricochet] Configuration reloaded");
            }
            
            Command_RicoMenu(param1, 0);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

void LoadConfig()
{
    KeyValues kv = new KeyValues("Ricochet");
    
    if (!kv.ImportFromFile(g_ConfigPath))
    {
        delete kv;
        CreateDefaultConfig();
        return;
    }
    
    WHISKER_LENGTH = kv.GetFloat("whisker_length", 200.0);
    WHISKER_ANGLE = kv.GetFloat("whisker_angle", 2.0);
    MAX_BOUNCES = kv.GetNum("max_bounces", 2);
    SHOW_WHISKERS = view_as<bool>(kv.GetNum("show_whiskers", 1));
    
    delete kv;
}

void CreateDefaultConfig()
{
    KeyValues kv = new KeyValues("Ricochet");
    kv.SetFloat("whisker_length", 200.0);
    kv.SetFloat("whisker_angle", 2.0);
    kv.SetNum("max_bounces", 2);
    kv.SetNum("show_whiskers", 1);
    kv.ExportToFile(g_ConfigPath);
    delete kv;
}

public bool TraceFilter_NoPlayers(int entity, int contentsMask, any data)
{
    return (entity == data || !IsValidEntity(entity) || !IsClientIndex(entity)) ? false : true;
}

bool IsClientIndex(int entity)
{
    return (entity > 0 && entity <= MaxClients);
}
