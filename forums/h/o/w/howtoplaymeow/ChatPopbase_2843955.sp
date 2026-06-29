#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define MAX_MSG_LENGTH 192

ConVar g_cvarDisplayTime;
ConVar g_cvarMaxLength;
ConVar g_cvarProximity;
ConVar g_cvarCooldown;
ConVar g_cvarOffset;
ConVar g_cvarScale;
ConVar g_cvarRainbow;
ConVar g_cvarFont;
ConVar g_cvarRemove;
ConVar g_cvarMaxEntRefs;

float g_flNextAllowed[MAXPLAYERS+1];
Handle g_hLastEntRefs[MAXPLAYERS+1];

public Plugin myinfo =
{
    name        = "Overhead Chat",
    author      = "Lanthan fix HowToPlayMeow",
    description = "Meow Meow",
    version     = "7.1"
};

public void OnPluginStart()
{
    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");

    g_cvarFont        = CreateConVar("sm_overheadchat_font", "0", "Set world text font (integer index)", FCVAR_PROTECTED, true, 0.0, true, 12.0);
    g_cvarRainbow     = CreateConVar("sm_overheadchat_rainbow", "0", "Enable rainbow world text (0 = off, 1 = on)", FCVAR_PROTECTED, true, 0.0, true, 1.0);
    g_cvarDisplayTime = CreateConVar("sm_overheadchat_time", "10.0", "How long the text stays", FCVAR_PROTECTED, true, 1.0, true, 30.0);
    g_cvarMaxLength   = CreateConVar("sm_overheadchat_maxlen", "96", "Max chars shown", FCVAR_PROTECTED, true, 10.0, true, 192.0);
    g_cvarProximity   = CreateConVar("sm_overheadchat_radius", "0", "Distance players see text (0 = all)", FCVAR_PROTECTED, true, 0.0, true, 5000.0);
    g_cvarCooldown    = CreateConVar("sm_overheadchat_cooldown", "1.0", "Cooldown in seconds", FCVAR_PROTECTED, true, 0.0, true, 30.0);
    g_cvarOffset      = CreateConVar("sm_overheadchat_offset", "90.0", "Vertical offset above player head", FCVAR_PROTECTED, true, 0.0, true, 200.0);
    g_cvarScale       = CreateConVar("sm_overheadchat_scale", "6.0", "Scale multiplier for text size", FCVAR_PROTECTED, true, 0.1, true, 10.0);
    g_cvarRemove      = CreateConVar("sm_overheadchat_remove", "1", "Remove previous text when sending new one (0 = off, 1 = on)", FCVAR_PROTECTED, true, 0.0, true, 1.0);
    g_cvarMaxEntRefs  = CreateConVar("sm_overheadchat_maxentrefs", "32", "Max stored worldtext entrefs per sender", FCVAR_PROTECTED, true, 1.0, true, 256.0);

    for (int i = 0; i <= MAXPLAYERS; i++)
    {
        g_flNextAllowed[i] = 0.0;
        g_hLastEntRefs[i] = INVALID_HANDLE;
    }

    AutoExecConfig(true, "tf2_overheadchat");
}

public void OnClientDisconnect(int client)
{
    if (client <= 0 || client > MAXPLAYERS) 
        return;

    if (g_hLastEntRefs[client] != INVALID_HANDLE)
    {
        int size = GetArraySize(g_hLastEntRefs[client]);
        for (int i = 0; i < size; i++)
        {
            int entRef = GetArrayCell(g_hLastEntRefs[client], i);
            if (entRef != 0)
                CreateTimer(0.0, Timer_KillEntity, entRef);
        }
        ClearArray(g_hLastEntRefs[client]);
        CloseHandle(g_hLastEntRefs[client]);
        g_hLastEntRefs[client] = INVALID_HANDLE;
    }
}

public Action Command_Say(int client, const char[] command, int argc)
{
    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
        return Plugin_Continue;

    if (TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Disguised) || TF2_IsPlayerInCondition(client, TFCond_Disguising))
        return Plugin_Continue;

    float now = GetEngineTime();
    if (now < g_flNextAllowed[client])
        return Plugin_Continue;

    char message[MAX_MSG_LENGTH];
    GetCmdArgString(message, sizeof(message));
    StripQuotes(message);
    TrimString(message);

    if (message[0] == '\0' || message[0] == '/')
        return Plugin_Continue;

    int maxlen = g_cvarMaxLength.IntValue;
    if (strlen(message) > maxlen)
        message[maxlen] = '\0';

    ShowOverheadText(client, message);
    g_flNextAllowed[client] = now + g_cvarCooldown.FloatValue;

    return Plugin_Continue;
}

int CreateWorldText(int sender, const char[] text)
{
    if (!IsClientInGame(sender) || !IsPlayerAlive(sender))
        return -1;

    int ent = CreateEntityByName("point_worldtext");
    if (ent == -1)
        return -1;

    DispatchKeyValue(ent, "message", text);
    DispatchKeyValueFloat(ent, "textsize", g_cvarScale.FloatValue);

    int team = GetClientTeam(sender);
    char sColor[32];

    switch (team)
    {
        case 2: strcopy(sColor, sizeof(sColor), "255 80 80 255");
        case 3: strcopy(sColor, sizeof(sColor), "80 150 255 255");
        default:strcopy(sColor, sizeof(sColor), "255 255 255 255");
    }

    DispatchKeyValue(ent, "color", sColor);

    char sFont[8];
    Format(sFont, sizeof(sFont), "%d", g_cvarFont.IntValue);
    DispatchKeyValue(ent, "font", sFont);
    DispatchKeyValue(ent, "orientation", "1");
    DispatchKeyValue(ent, "rainbow", g_cvarRainbow.IntValue ? "1" : "0");
    DispatchSpawn(ent);

    float origin[3];
    GetClientAbsOrigin(sender, origin);
    origin[2] += g_cvarOffset.FloatValue;
    TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);

    SetVariantString("!activator");
    AcceptEntityInput(ent, "SetParent", sender, ent);

    if (g_cvarProximity.IntValue > 0)
        CreateTimer(0.0, Timer_HookTransmit, ent);

    StoreEntRefForSender(sender, EntIndexToEntRef(ent));
    CreateTimer(g_cvarDisplayTime.FloatValue, Timer_KillEntity, EntIndexToEntRef(ent));
    return ent;
}

public Action Timer_HookTransmit(Handle timer, any entAny)
{
    int ent = entAny;
    if (ent > 0 && IsValidEntity(ent))
        SDKHook(ent, SDKHook_SetTransmit, EntTransmitFilter);

    return Plugin_Stop;
}

public Action EntTransmitFilter(int ent, int client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Handled;

    if (!IsValidEntity(ent))
        return Plugin_Handled;

    int radius = g_cvarProximity.IntValue;
    if (radius <= 0)
        return Plugin_Continue;

    float entOrigin[3];
    float clientOrigin[3];

    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entOrigin);
    GetClientAbsOrigin(client, clientOrigin);

    if (GetVectorDistance(entOrigin, clientOrigin) <= float(radius))
        return Plugin_Continue;

    return Plugin_Handled;
}

void ShowOverheadText(int sender, const char[] text)
{
    if (g_cvarRemove.BoolValue && g_hLastEntRefs[sender] != INVALID_HANDLE)
    {
        int size = GetArraySize(g_hLastEntRefs[sender]);
        for (int i = 0; i < size; i++)
        {
            int entRef = GetArrayCell(g_hLastEntRefs[sender], i);
            if (entRef != 0)
                CreateTimer(0.0, Timer_KillEntity, entRef);
        }

        ClearArray(g_hLastEntRefs[sender]);
        CloseHandle(g_hLastEntRefs[sender]);
        g_hLastEntRefs[sender] = INVALID_HANDLE;
    }

    CreateWorldText(sender, text);
}

void StoreEntRefForSender(int sender, int entRef)
{
    if (entRef == 0)
        return;

    if (g_hLastEntRefs[sender] == INVALID_HANDLE)
        g_hLastEntRefs[sender] = CreateArray();

    int size = GetArraySize(g_hLastEntRefs[sender]);
    if (size >= g_cvarMaxEntRefs.FloatValue)
        RemoveFromArray(g_hLastEntRefs[sender], 0);

    PushArrayCell(g_hLastEntRefs[sender], entRef);
}

public Action Timer_KillEntity(Handle timer, any ref)
{
    int entRef = ref;
    int ent = EntRefToEntIndex(entRef);

    if (ent > 0 && IsValidEntity(ent))
        AcceptEntityInput(ent, "Kill");

    return Plugin_Stop;
}