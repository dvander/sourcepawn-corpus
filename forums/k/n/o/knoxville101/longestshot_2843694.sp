#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define MIN_DISTANCE    75.0
#define MAX_RECORDS     10

public Plugin myinfo =
{
    name        = "Longest Shot Tracker",
    author      = "Knoxville",
    description = "Tracks top 10 longest kill shots per map. Type !shots to view.",
    version     = PLUGIN_VERSION,
    url         = ""
};

// Per-record data
char  g_sName[MAX_RECORDS][64];
float g_fDist[MAX_RECORDS];
char  g_sWeapon[MAX_RECORDS][64];
int   g_iRecordCount;

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
    RegConsoleCmd("sm_shots", Command_Shots, "Show longest shots this map");
}

bool g_bPanelShown;

public void OnMapStart()
{
    ResetRecords();
    g_bPanelShown = false;
    CreateTimer(5.0, Timer_CheckTimeLeft, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CheckTimeLeft(Handle timer)
{
    if (g_bPanelShown)
        return Plugin_Continue;

    int timeLeft;
    if (!GetMapTimeLeft(timeLeft))
        return Plugin_Continue;

    if (timeLeft > 0 && timeLeft <= 10 && g_iRecordCount > 0)
    {
        g_bPanelShown = true;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || IsFakeClient(i))
                continue;

            ShowShotsPanel(i, 9);
        }
    }

    return Plugin_Continue;
}


void ResetRecords()
{
    g_iRecordCount = 0;
    for (int i = 0; i < MAX_RECORDS; i++)
    {
        g_sName[i][0]   = '\0';
        g_fDist[i]      = 0.0;
        g_sWeapon[i][0] = '\0';
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim   = GetClientOfUserId(event.GetInt("userid"));

    if (attacker <= 0 || victim <= 0 || attacker == victim)
        return Plugin_Continue;

    if (!IsClientInGame(attacker) || !IsClientInGame(victim))
        return Plugin_Continue;

    float vAttacker[3], vVictim[3];
    GetClientAbsOrigin(attacker, vAttacker);
    GetClientAbsOrigin(victim, vVictim);

    float distance = GetVectorDistance(vAttacker, vVictim) / 39.37;

    if (distance < MIN_DISTANCE)
        return Plugin_Continue;

    char rawWeapon[64], displayWeapon[64];
    event.GetString("weapon", rawWeapon, sizeof(rawWeapon));
    FormatWeaponName(rawWeapon, displayWeapon, sizeof(displayWeapon));

    char shooterName[64];
    GetClientName(attacker, shooterName, sizeof(shooterName));

    InsertRecord(shooterName, distance, displayWeapon);

    return Plugin_Continue;
}

// Insert into sorted top-10 list
void InsertRecord(const char[] playerName, float distance, const char[] weapon)
{
    int insertPos = -1;
    for (int i = 0; i < MAX_RECORDS; i++)
    {
        if (i >= g_iRecordCount || distance > g_fDist[i])
        {
            insertPos = i;
            break;
        }
    }

    if (insertPos == -1)
        return;

    int shiftTo = (g_iRecordCount < MAX_RECORDS) ? g_iRecordCount : MAX_RECORDS - 1;
    for (int i = shiftTo; i > insertPos; i--)
    {
        strcopy(g_sName[i],   sizeof(g_sName[]),   g_sName[i-1]);
        g_fDist[i] = g_fDist[i-1];
        strcopy(g_sWeapon[i], sizeof(g_sWeapon[]), g_sWeapon[i-1]);
    }

    strcopy(g_sName[insertPos],   sizeof(g_sName[]),   playerName);
    g_fDist[insertPos] = distance;
    strcopy(g_sWeapon[insertPos], sizeof(g_sWeapon[]), weapon);

    if (g_iRecordCount < MAX_RECORDS)
        g_iRecordCount++;
}

public Action Command_Shots(int client, int args)
{
    if (client == 0)
    {
        PrintToServer("Command available in-game only.");
        return Plugin_Handled;
    }

    ShowShotsPanel(client, 15);
    return Plugin_Handled;
}

void ShowShotsPanel(int client, int duration)
{
    Menu menu = new Menu(Menu_Shots, MENU_ACTIONS_DEFAULT);
    menu.SetTitle("= LONGEST SHOTS THIS MAP =");

    if (g_iRecordCount == 0)
    {
        menu.AddItem("", "No qualifying shots yet. (min 75m)");
    }
    else
    {
        char line[128];
        for (int i = 0; i < g_iRecordCount; i++)
        {
            Format(line, sizeof(line), "%s | %.0fm | %s",
                g_sName[i],
                g_fDist[i],
                g_sWeapon[i]
            );
            menu.AddItem("", line);
        }
    }

    menu.ExitButton = true;
    menu.Display(client, duration);
}

public int Menu_Shots(Menu menu, MenuAction action, int client, int param)
{
    return 0;
}

void FormatWeaponName(const char[] raw, char[] display, int maxlen)
{
    char stripped[64];

    if (StrContains(raw, "weapon_") == 0)
        strcopy(stripped, sizeof(stripped), raw[7]);
    else
        strcopy(stripped, sizeof(stripped), raw);

    if      (StrEqual(stripped, "k98_scoped",    false)) strcopy(display, maxlen, "Kar98k Scoped");
    else if (StrEqual(stripped, "k98",           false)) strcopy(display, maxlen, "Kar98k");
    else if (StrEqual(stripped, "spring",        false)) strcopy(display, maxlen, "Springfield");
    else if (StrEqual(stripped, "garand",        false)) strcopy(display, maxlen, "M1 Garand");
    else if (StrEqual(stripped, "mp40",          false)) strcopy(display, maxlen, "MP40");
    else if (StrEqual(stripped, "mp44",          false)) strcopy(display, maxlen, "MP44");
    else if (StrEqual(stripped, "bar",           false)) strcopy(display, maxlen, "BAR");
    else if (StrEqual(stripped, "30cal",         false)) strcopy(display, maxlen, "30 Cal MG");
    else if (StrEqual(stripped, "mg42",          false)) strcopy(display, maxlen, "MG42");
    else if (StrEqual(stripped, "thompson",      false)) strcopy(display, maxlen, "Thompson");
    else if (StrEqual(stripped, "greasegun",     false)) strcopy(display, maxlen, "Grease Gun");
    else if (StrEqual(stripped, "colt",          false)) strcopy(display, maxlen, "Colt .45");
    else if (StrEqual(stripped, "p38",           false)) strcopy(display, maxlen, "P38");
    else if (StrEqual(stripped, "c96",           false)) strcopy(display, maxlen, "C96");
    else if (StrEqual(stripped, "bazooka",       false)) strcopy(display, maxlen, "Bazooka");
    else if (StrEqual(stripped, "pschreck",      false)) strcopy(display, maxlen, "Panzerschreck");
    else if (StrEqual(stripped, "riflegren_us",  false) ||
             StrEqual(stripped, "riflegren_ger", false)) strcopy(display, maxlen, "Rifle Grenade");
    else if (StrEqual(stripped, "frag_us",       false) ||
             StrEqual(stripped, "frag_ger",      false)) strcopy(display, maxlen, "Grenade");
    else if (StrEqual(stripped, "smoke_us",      false) ||
             StrEqual(stripped, "smoke_ger",     false)) strcopy(display, maxlen, "Smoke Grenade");
    else
    {
        strcopy(display, maxlen, stripped);
        if (display[0] >= 'a' && display[0] <= 'z')
            display[0] -= 32;
    }
}
