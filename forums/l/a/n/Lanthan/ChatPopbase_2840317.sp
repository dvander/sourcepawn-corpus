#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#tryinclude <metachatprocessor>

#define MAX_MSG_LENGTH 192

ConVar g_cvarDisplayTime;
ConVar g_cvarMaxLength;
ConVar g_cvarProximity;
ConVar g_cvarCooldown;
ConVar g_cvarOffset;
ConVar g_cvarScale;
ConVar g_cvarRainbow;
ConVar g_cvarFont;

float g_flNextAllowed[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name        = "Overhead chat",
    author      = "Lanthan",
    description = "Shows the Chat above player heads with point_worldtext",
    version     = "6.9"
};

public void OnPluginStart()
{
#if !defined _metachatprocessor_included
    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");
#endif

    g_cvarFont = CreateConVar("sm_overheadchat_font", "0",
        "Set world text font (integer index)", FCVAR_PROTECTED, true, 0.0, true, 12.0);

    g_cvarRainbow = CreateConVar("sm_overheadchat_rainbow", "0",
        "Enable rainbow world text (0 = off, 1 = on)", FCVAR_PROTECTED, true, 0.0, true, 1.0);

    g_cvarDisplayTime = CreateConVar("sm_overheadchat_time", "5.0",
        "How long the text stays", FCVAR_PROTECTED, true, 1.0, true, 30.0);

    g_cvarMaxLength = CreateConVar("sm_overheadchat_maxlen", "96",
        "Max chars shown", FCVAR_PROTECTED, true, 10.0, true, 192.0);

    g_cvarProximity = CreateConVar("sm_overheadchat_radius", "0",
        "Distance players see text (0 = all)", FCVAR_PROTECTED, true, 0.0, true, 5000.0);

    g_cvarCooldown = CreateConVar("sm_overheadchat_cooldown", "2.0",
        "Cooldown in seconds", FCVAR_PROTECTED, true, 0.0, true, 30.0);

    g_cvarOffset = CreateConVar("sm_overheadchat_offset", "75.0",
        "Vertical offset above player head", FCVAR_PROTECTED, true, 0.0, true, 200.0);

    g_cvarScale = CreateConVar("sm_overheadchat_scale", "1.0",
        "Scale multiplier for text size", FCVAR_PROTECTED, true, 0.1, true, 10.0);

    AutoExecConfig(true, "plugin.tf2_overheadchat");
}

#if !defined _metachatprocessor_included
public Action Command_Say(int client, const char[] command, int argc)
{
    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Continue;

    float now = GetEngineTime();
    if (now < g_flNextAllowed[client])
        return Plugin_Continue;

    char message[MAX_MSG_LENGTH];
    GetCmdArgString(message, sizeof(message));
    TrimString(message);

    int len = strlen(message);
    if (len > 1 && message[0] == '"' && message[len - 1] == '"')
    {
        message[len - 1] = '\0';
        strcopy(message, sizeof(message), message[1]);
    }

    if (message[0] == '\0')
        return Plugin_Continue;

    int maxlen = g_cvarMaxLength.IntValue;
    if (strlen(message) > maxlen)
        message[maxlen] = '\0';

    ShowOverheadText(client, message);

    g_flNextAllowed[client] = now + g_cvarCooldown.FloatValue;
    return Plugin_Continue;
}
#endif

#if defined _metachatprocessor_included
public Action mcpHookFormatted(int sender, int recipient, any senderflags, any targetgroup, any options, const char[] formatted)
{
    if (sender <= 0 || !IsClientInGame(sender) || IsFakeClient(sender))
        return Plugin_Continue;
    if (recipient <= 0 || !IsClientInGame(recipient) || IsFakeClient(recipient))
        return Plugin_Continue;

    float now = GetEngineTime();
    if (now < g_flNextAllowed[sender])
        return Plugin_Continue;

    char buf[MAX_MSG_LENGTH];
    strcopy(buf, sizeof(buf), formatted);

    int maxlen = g_cvarMaxLength.IntValue;
    if (strlen(buf) > maxlen)
        buf[maxlen] = '\0';

    ShowOverheadText(sender, buf);

    g_flNextAllowed[sender] = now + g_cvarCooldown.FloatValue;

    return Plugin_Continue;
}
#endif

int CreateWorldText(int sender, const char[] text, int recipient)
{
    int ent = CreateEntityByName("point_worldtext");
    if (ent == -1)
        return -1;

    DispatchKeyValue(ent, "message", text);
    DispatchKeyValueFloat(ent, "textsize", g_cvarScale.FloatValue);
    DispatchKeyValue(ent, "color", "255 255 255 255");
    char sFont[4];
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
    if (recipient > 0)
    {
        SDKHook(ent, SDKHook_SetTransmit, EntTransmitFilter);
    }
    CreateTimer(g_cvarDisplayTime.FloatValue, Timer_KillEntity, EntIndexToEntRef(ent));

    return ent;
}

public Action EntTransmitFilter(int ent, int client)
{
    return Plugin_Continue;
}

void ShowOverheadText(int sender, const char[] text)
{
    int radius = g_cvarProximity.IntValue;
    if (radius > 0)
    {
        float sOrigin[3];
        GetClientAbsOrigin(sender, sOrigin);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || IsFakeClient(i))
                continue;
            float pOrigin[3];
            GetClientAbsOrigin(i, pOrigin);
            if (GetVectorDistance(sOrigin, pOrigin) <= float(radius))
                CreateWorldText(sender, text, i);
        }
    }
    else
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
                CreateWorldText(sender, text, i);
        }
    }
}
public Action Timer_KillEntity(Handle timer, any ref)
{
    int ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEntity(ent))
        AcceptEntityInput(ent, "Kill");
    return Plugin_Stop;
}
