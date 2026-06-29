#pragma semicolon 1
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define VERSION "1.0"

public Plugin myinfo = 
{
    name = "Scout No Scope", 
    author = "XARiUS, Holder", 
    description = "Plugin which will force scout no scoping!", 
    version = "1.0", 
    url = "http://www.the-otc.com/"
};

char language[4];
char languagecode[4];
bool g_enabled;
bool g_bulletpath;
int g_laser;
Handle g_Cvarenabled = INVALID_HANDLE;
Handle g_Cvarbulletpath = INVALID_HANDLE;

public void OnPluginStart()
{
    LoadTranslations("noscope.phrases");
    CreateConVar("sm_noscope_version", VERSION, "Scout No Scope Version", FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_SPONLY | FCVAR_DONTRECORD);
    g_Cvarenabled = CreateConVar("sm_noscope_enabled", "1", "Enable this plugin. 0 = Disabled");
    g_Cvarbulletpath = CreateConVar("sm_noscope_bulletpath", "0", "Show the bullet path using a small laser beam. 0 = Disabled");
    
    GetLanguageInfo(GetServerLanguage(), languagecode, sizeof(languagecode), language, sizeof(language));
    
    HookEvent("weapon_zoom", EventWeaponZoom, EventHookMode_Post);
    HookEvent("weapon_fire", EventWeaponFire, EventHookMode_Post);
    
    HookConVarChange(g_Cvarenabled, OnSettingChanged);
    HookConVarChange(g_Cvarbulletpath, OnSettingChanged);
    
    g_enabled = GetConVarBool(g_Cvarenabled);
    g_bulletpath = GetConVarBool(g_Cvarbulletpath);
    
    g_laser = PrecacheModel("materials/sprites/laser.vmt");
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
    if (convar == g_Cvarenabled)
    {
        if (newValue[0] == 1)
        {
            PrintHintTextToAll("%t", "Noscope enabled");
            EmitSoundToAll("weapons/zoom.wav");
            g_enabled = true;
            g_bulletpath = true;
        }
        else
        {
            PrintHintTextToAll("%t", "Noscope disabled");
            EmitSoundToAll("weapons/zoom.wav");
            g_enabled = false;
            g_bulletpath = false;
        }
    }
}

public Action EventWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    if (g_enabled && g_bulletpath)
    {
        int clientid = GetClientOfUserId(event.GetInt("userid"));
        char weaponname[32];
        int weapon;
        GetEdictClassname(weapon, weaponname, sizeof(weaponname));
        if (StrEqual(weaponname, "weapon_ssg08"))
        {
            DrawLaser(clientid);
        }
    }
}

public Action EventWeaponZoom(Event event, const char[] name, bool dontBroadcast)
{
    if (g_enabled)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        char weaponname[32];
        GetClientWeapon(client, weaponname, sizeof(weaponname));
        if (StrEqual(weaponname, "weapon_ssg08"))
        {
            int weapon = GetPlayerWeaponSlot(client, 0);
            if (IsValidEdict(weapon))
            {
                RemovePlayerItem(client, weapon);
                RemoveEdict(weapon);
                CreateTimer(0.1, GiveScout, client);
                PrintHintText(client, "%t", "Not Allowed");
            }
            return Plugin_Continue;
        }
        return Plugin_Continue;
    }
    return Plugin_Continue;
}

public Action GiveScout(Handle timer, any client)
{
    GivePlayerItem(client, "weapon_ssg08");
}

public int DrawLaser(int client)
{
    float clientOrigin[3], impactOrigin[3];
    float vAngles[3], vOrigin[3];
    GetClientEyePosition(client, vOrigin);
    GetClientEyeAngles(client, vAngles);
    int color[4];
    
    Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer, client);
    
    if (TR_DidHit(trace))
    {
        TR_GetEndPosition(impactOrigin, trace);
        GetClientEyePosition(client, clientOrigin);
        clientOrigin[2] -= 1;
        if (GetClientTeam(client) == 3)
        {
            color =  { 75, 75, 255, 255 };
        }
        else
        {
            color =  { 255, 75, 75, 255 };
        }
        TE_SetupBeamPoints(clientOrigin, impactOrigin, g_laser, 0, 0, 0, 0.5, 1.0, 1.0, 10, 0.0, color, 0);
        TE_SendToAll();
    }
    CloseHandle(trace);
}

public bool TraceEntityFilterPlayer(int entity, int mask, any data)
{
    return data != entity;
} 