#include <sourcemod>
#include <sdktools>

#define MAX_PLAYERS 33
#define COLOR_DEFAULT "\x01"
#define COLOR_GREEN "\x04"
#define COLOR_ORANGE "\x03"

public Plugin myinfo = 
{
    name = "Dual Primaries",
    author = "easy",
    description = "Allows players to carry two primary weapons",
    version = "1.0"
};

char g_sSlot1[MAX_PLAYERS][64];
int g_iSlot1Clip[MAX_PLAYERS];
int g_iSlot1Ammo[MAX_PLAYERS];

char g_sSlot2[MAX_PLAYERS][64];
int g_iSlot2Clip[MAX_PLAYERS];
int g_iSlot2Ammo[MAX_PLAYERS];

bool g_bSwitching[MAX_PLAYERS];
float g_fLastSwitch[MAX_PLAYERS];

ConVar g_cvCooldown;

public void OnPluginStart()
{
    g_cvCooldown = CreateConVar("sm_dualprimary_cooldown", "1.0", "Кулдаун между переключениями");
    
    RegConsoleCmd("sm_switch", Cmd_SwitchPrimary);
    RegConsoleCmd("sm_save", Cmd_StorePrimary);
    RegConsoleCmd("sm_status", Cmd_ShowStatus);
    
    HookEvent("weapon_drop", Event_WeaponDrop);
    HookEvent("item_pickup", Event_ItemPickup);
    HookEvent("player_death", Event_PlayerDeath);
}

public void OnClientPutInServer(int client)
{
    g_sSlot1[client][0] = '\0';
    g_iSlot1Clip[client] = 0;
    g_iSlot1Ammo[client] = 0;
    
    g_sSlot2[client][0] = '\0';
    g_iSlot2Clip[client] = 0;
    g_iSlot2Ammo[client] = 0;
    
    g_bSwitching[client] = false;
    g_fLastSwitch[client] = 0.0;
}

void NormalizeWeaponName(const char[] input, char[] output, int maxlen)
{
    strcopy(output, maxlen, input);
    ReplaceString(output, maxlen, "weapon_", "", false);
}

bool IsPrimaryWeapon(const char[] classname)
{
    return (StrContains(classname, "rifle", false) != -1 ||
            StrContains(classname, "smg", false) != -1 ||
            StrContains(classname, "shotgun", false) != -1 ||
            StrContains(classname, "sniper", false) != -1);
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

public Action Cmd_SwitchPrimary(int client, int args)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return Plugin_Handled;
    
    float cooldown = g_cvCooldown.FloatValue;
    float currentTime = GetGameTime();
    
    if (currentTime - g_fLastSwitch[client] < cooldown)
        return Plugin_Handled;
    
    if (g_sSlot2[client][0] == '\0')
        return Plugin_Handled;
    
    g_bSwitching[client] = true;
    g_fLastSwitch[client] = currentTime;
    
    int currentWeapon = GetPlayerWeaponSlot(client, 0);
    char currentClass[64] = "";
    int currentClip = 0;
    int currentAmmo = 0;
    
    if (currentWeapon > 0)
    {
        GetEntityClassname(currentWeapon, currentClass, sizeof(currentClass));
        currentClip = GetEntProp(currentWeapon, Prop_Send, "m_iClip1");
        
        int ammoType = GetEntProp(currentWeapon, Prop_Send, "m_iPrimaryAmmoType");
        if (ammoType >= 0)
            currentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
    }
    
    char tempClass[64];
    strcopy(tempClass, sizeof(tempClass), g_sSlot2[client]);
    int tempClip = g_iSlot2Clip[client];
    int tempAmmo = g_iSlot2Ammo[client];
    
    if (currentWeapon > 0)
    {
        RemovePlayerItem(client, currentWeapon);
        AcceptEntityInput(currentWeapon, "Kill");
    }
    
    int newWeapon = GivePlayerItem(client, tempClass);
    if (newWeapon > 0)
    {
        SetEntProp(newWeapon, Prop_Send, "m_iClip1", tempClip);
        
        int ammoType = GetEntProp(newWeapon, Prop_Send, "m_iPrimaryAmmoType");
        if (ammoType >= 0)
            SetEntProp(client, Prop_Send, "m_iAmmo", tempAmmo, _, ammoType);
        
        strcopy(g_sSlot1[client], sizeof(g_sSlot1[]), tempClass);
        g_iSlot1Clip[client] = tempClip;
        g_iSlot1Ammo[client] = tempAmmo;
        
        if (currentClass[0] != '\0' && IsPrimaryWeapon(currentClass))
        {
            strcopy(g_sSlot2[client], sizeof(g_sSlot2[]), currentClass);
            g_iSlot2Clip[client] = currentClip;
            g_iSlot2Ammo[client] = currentAmmo;
        }
        
        // Сообщение при !switch
        char displayName[64];
        NormalizeWeaponName(g_sSlot2[client], displayName, sizeof(displayName));
        PrintToChat(client, "%sЗапасное оружие%s: %s%s", 
            COLOR_GREEN, COLOR_DEFAULT, COLOR_ORANGE, displayName);
    }
    
    CreateTimer(0.5, Timer_ClearSwitch, GetClientUserId(client));
    return Plugin_Handled;
}

public Action Cmd_StorePrimary(int client, int args)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return Plugin_Handled;
    
    int weapon = GetPlayerWeaponSlot(client, 0);
    if (weapon <= 0)
        return Plugin_Handled;
    
    char classname[64];
    GetEntityClassname(weapon, classname, sizeof(classname));
    
    if (!IsPrimaryWeapon(classname))
        return Plugin_Handled;
    
    int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
    int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    int ammo = (ammoType >= 0) ? GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType) : 0;
    
    // Сохраняем в слот 2 (запасное)
    strcopy(g_sSlot2[client], sizeof(g_sSlot2[]), classname);
    g_iSlot2Clip[client] = clip;
    g_iSlot2Ammo[client] = ammo;
    
    // Сообщение при !save
    char displayName[64];
    NormalizeWeaponName(classname, displayName, sizeof(displayName));
    PrintToChat(client, "%sОружие сохранено%s: %s%s", 
        COLOR_GREEN, COLOR_DEFAULT, COLOR_ORANGE, displayName);
    
    return Plugin_Handled;
}

public Action Cmd_ShowStatus(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Handled;
    
    char displayName1[64], displayName2[64];
    
    if (g_sSlot1[client][0] != '\0')
        NormalizeWeaponName(g_sSlot1[client], displayName1, sizeof(displayName1));
    else
        strcopy(displayName1, sizeof(displayName1), "пусто");
        
    if (g_sSlot2[client][0] != '\0')
        NormalizeWeaponName(g_sSlot2[client], displayName2, sizeof(displayName2));
    else
        strcopy(displayName2, sizeof(displayName2), "пусто");
    
    PrintToChat(client, "%sВ руках%s: %s%s %s(%d/%d)", 
        COLOR_GREEN, COLOR_DEFAULT, COLOR_ORANGE, displayName1, COLOR_DEFAULT,
        g_iSlot1Clip[client], g_iSlot1Ammo[client]);
    PrintToChat(client, "%sЗапасное%s: %s%s %s(%d/%d)", 
        COLOR_GREEN, COLOR_DEFAULT, COLOR_ORANGE, displayName2, COLOR_DEFAULT,
        g_iSlot2Clip[client], g_iSlot2Ammo[client]);
    
    return Plugin_Handled;
}

public void Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client)) return;
    
    int weapon = event.GetInt("propid");
    if (weapon <= 0) return;
    
    char classname[64];
    GetEntityClassname(weapon, classname, sizeof(classname));
    
    if (!IsPrimaryWeapon(classname)) return;
    
    if (StrEqual(classname, g_sSlot1[client]))
    {
        g_sSlot1[client][0] = '\0';
        g_iSlot1Clip[client] = 0;
        g_iSlot1Ammo[client] = 0;
    }
    else if (StrEqual(classname, g_sSlot2[client]))
    {
        g_sSlot2[client][0] = '\0';
        g_iSlot2Clip[client] = 0;
        g_iSlot2Ammo[client] = 0;
    }
}

public void Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client) || !IsPlayerAlive(client) || g_bSwitching[client]) return;
    
    CreateTimer(0.1, Timer_ProcessPickup, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ProcessPickup(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client) || !IsPlayerAlive(client) || g_bSwitching[client]) 
        return Plugin_Stop;
    
    int weapon = GetPlayerWeaponSlot(client, 0);
    if (weapon <= 0) return Plugin_Stop;
    
    char classname[64];
    GetEntityClassname(weapon, classname, sizeof(classname));
    
    if (!IsPrimaryWeapon(classname)) return Plugin_Stop;
    
    int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
    int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    int ammo = (ammoType >= 0) ? GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType) : 0;
    
    strcopy(g_sSlot1[client], sizeof(g_sSlot1[]), classname);
    g_iSlot1Clip[client] = clip;
    g_iSlot1Ammo[client] = ammo;
    
    return Plugin_Stop;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidClient(client))
    {
        g_sSlot1[client][0] = '\0';
        g_iSlot1Clip[client] = 0;
        g_iSlot1Ammo[client] = 0;
        
        g_sSlot2[client][0] = '\0';
        g_iSlot2Clip[client] = 0;
        g_iSlot2Ammo[client] = 0;
    }
}

public Action Timer_ClearSwitch(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client))
        g_bSwitching[client] = false;
    
    return Plugin_Stop;
}