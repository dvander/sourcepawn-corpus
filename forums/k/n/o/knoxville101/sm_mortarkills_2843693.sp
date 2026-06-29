// sm_mortarkills.sp
// DoD:S Mortar Kill Credit - Zero config, automatic, works on any map
//
// Tracks func_button presses. When a world kill happens within the time
// window after a button press, credits the kill to the button presser
// and notifies both players via chat and hint text.

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION   "3.4.0"
#define MAX_BUTTONS      64
#define KILL_TIME_MIN    1    // ignore deaths within 1 second of press
#define KILL_TIME_MAX    30   // credit window in seconds after button press

int   g_ButtonCount;
int   g_ButtonEnt[MAX_BUTTONS];
float g_ButtonPos[MAX_BUTTONS][3];
int   g_ButtonPresser[MAX_BUTTONS];
int   g_ButtonPressTime[MAX_BUTTONS];

public Plugin myinfo =
{
    name        = "DoD:S Mortar Kill Credit",
    author      = "Knoxville",
    description = "Zero-config mortar kill credit for any DoD:S map",
    version     = PLUGIN_VERSION,
    url         = ""
};

public void OnPluginStart()
{
    CreateConVar("sm_mortarkills_version", PLUGIN_VERSION, "Mortar Kill Credit version", FCVAR_NOTIFY);

    HookEntityOutput("func_button", "OnPressed", OnButtonPressed);

    HookEvent("player_death",            OnPlayerDeath, EventHookMode_Pre);
    HookEvent("dod_stats_player_killed", OnPlayerDeath, EventHookMode_Pre);
}

public void OnMapStart()
{
    RequestFrame(Frame_ScanButtons, 0);
}

public void Frame_ScanButtons(any unused)
{
    g_ButtonCount = 0;

    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "func_button")) != -1)
    {
        if (g_ButtonCount >= MAX_BUTTONS)
            break;

        float pos[3];
        GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", pos);

        g_ButtonEnt[g_ButtonCount]       = ent;
        g_ButtonPos[g_ButtonCount][0]    = pos[0];
        g_ButtonPos[g_ButtonCount][1]    = pos[1];
        g_ButtonPos[g_ButtonCount][2]    = pos[2];
        g_ButtonPresser[g_ButtonCount]   = 0;
        g_ButtonPressTime[g_ButtonCount] = 0;
        g_ButtonCount++;
    }
}

public void OnButtonPressed(const char[] output, int caller, int activator, float delay)
{
    if (activator < 1 || activator > MaxClients || !IsClientInGame(activator))
        return;

    for (int i = 0; i < g_ButtonCount; i++)
    {
        if (g_ButtonEnt[i] == caller)
        {
            g_ButtonPresser[i]   = activator;
            g_ButtonPressTime[i] = GetTime();
            return;
        }
    }

    // Button not in scan list -- add it
    if (g_ButtonCount < MAX_BUTTONS)
    {
        float pos[3];
        GetEntPropVector(caller, Prop_Data, "m_vecAbsOrigin", pos);
        int i = g_ButtonCount;
        g_ButtonEnt[i]       = caller;
        g_ButtonPos[i][0]    = pos[0];
        g_ButtonPos[i][1]    = pos[1];
        g_ButtonPos[i][2]    = pos[2];
        g_ButtonPresser[i]   = activator;
        g_ButtonPressTime[i] = GetTime();
        g_ButtonCount++;
    }
}

public Action OnPlayerDeath(Event event, const char[] evname, bool dontBroadcast)
{
    // Only world kills
    if (event.GetInt("attacker") != 0)
        return Plugin_Continue;

    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim < 1 || victim > MaxClients || !IsClientInGame(victim))
        return Plugin_Continue;

    if (g_ButtonCount == 0)
        return Plugin_Continue;

    int deathTime     = GetTime();
    int bestButton    = -1;
    int bestPressTime = 0;

    for (int i = 0; i < g_ButtonCount; i++)
    {
        int presser   = g_ButtonPresser[i];
        int pressTime = g_ButtonPressTime[i];

        if (presser < 1 || presser > MaxClients || !IsClientInGame(presser))
            continue;
        if (pressTime == 0)
            continue;
        if (presser == victim)
            continue;

        int elapsed = deathTime - pressTime;
        if (elapsed < KILL_TIME_MIN || elapsed > KILL_TIME_MAX)
            continue;

        if (pressTime > bestPressTime)
        {
            bestPressTime = pressTime;
            bestButton    = i;
        }
    }

    if (bestButton == -1)
        return Plugin_Continue;

    int attacker = g_ButtonPresser[bestButton];
    AwardKill(attacker, victim);
    return Plugin_Handled;
}

void AwardKill(int attacker, int victim)
{
    Event killEvent = CreateEvent("player_death");
    if (killEvent == null)
        return;

    killEvent.SetInt("userid",    GetClientUserId(victim));
    killEvent.SetInt("attacker",  GetClientUserId(attacker));
    killEvent.SetString("weapon", "mortar");
    killEvent.SetInt("dominated", 0);
    killEvent.SetInt("revenge",   0);
    FireEvent(killEvent);

    bool teamkill = (GetClientTeam(victim) == GetClientTeam(attacker));
    int frags = GetEntProp(attacker, Prop_Data, "m_iFrags");
    SetEntProp(attacker, Prop_Data, "m_iFrags", frags + (teamkill ? -1 : 1));

    char attackerName[MAX_NAME_LENGTH];
    char victimName[MAX_NAME_LENGTH];
    GetClientName(attacker, attackerName, sizeof(attackerName));
    GetClientName(victim,   victimName,   sizeof(victimName));

    PrintHintText(victim,   "You were killed by a MORTAR\nfired by %s!", attackerName);
    PrintToChat(victim,     "\x01[\x04MORTAR\x01] You were blasted by \x03%s\x01's mortar!", attackerName);
    PrintToChat(attacker,   "\x01[\x04MORTAR\x01] Your mortar killed \x03%s\x01!", victimName);
}
