#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "[L4D2] Type Suvivors Select",
    author = "Ginseng",
    description = "Allows players to switch survivors depending on campaign support.",
    version = "1.0"
};

enum SurvivorType
{
    SURV_COACH = 0,
    SURV_NICK,
    SURV_ROCHELLE,
    SURV_ELLIS,
    SURV_BILL,
    SURV_ZOEY,
    SURV_LOUIS,
    SURV_FRANCIS
};

int g_GameIndexMap[8] = {2, 0, 1, 3, 4, 5, 6, 7};

bool g_bIsL4D1Map = false;

static const char g_SurvivorNames[8][16] =
{
    "Coach",
    "Nick",
    "Rochelle",
    "Ellis",
    "Bill",
    "Zoey",
    "Louis",
    "Francis"
};
char g_SurvivorModels[][64] =
{
    "models/survivors/survivor_coach.mdl",
    "models/survivors/survivor_gambler.mdl",
    "models/survivors/survivor_producer.mdl",
    "models/survivors/survivor_mechanic.mdl",
    "models/survivors/survivor_namvet.mdl",
    "models/survivors/survivor_teenangst.mdl",
    "models/survivors/survivor_manager.mdl",
    "models/survivors/survivor_biker.mdl"
};


// Simple CheckPrecacheModel replacement: calls PrecacheModel and returns true.
// This avoids undefined-symbol issues on servers without IsModelPrecached.
bool CheckPrecacheModel(const char[] mdl)
{
    if (mdl[0] == '\0')
        return false;
    PrecacheModel(mdl, true);
    return true;
}

public void OnMapStart()
{
    char map[64];
    GetCurrentMap(map, sizeof(map));

    g_bIsL4D1Map = StrContains(map, "l4d_") == 0;

    CheckPrecacheModel("models/survivors/survivor_coach.mdl");
    CheckPrecacheModel("models/survivors/survivor_nick.mdl");
    CheckPrecacheModel("models/survivors/survivor_rochelle.mdl");
    CheckPrecacheModel("models/survivors/survivor_mechanic.mdl");

    CheckPrecacheModel("models/survivors/survivor_namvet.mdl");
    CheckPrecacheModel("models/survivors/survivor_teenangst.mdl");
    CheckPrecacheModel("models/survivors/survivor_manager.mdl");
    CheckPrecacheModel("models/survivors/survivor_biker.mdl");
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_c", Cmd_Coach);
    RegConsoleCmd("sm_coach", Cmd_Coach);

    RegConsoleCmd("sm_n", Cmd_Nick);
    RegConsoleCmd("sm_nick", Cmd_Nick);

    RegConsoleCmd("sm_r", Cmd_Rochelle);
    RegConsoleCmd("sm_rochelle", Cmd_Rochelle);

    RegConsoleCmd("sm_e", Cmd_Ellis);
    RegConsoleCmd("sm_ellis", Cmd_Ellis);

    RegConsoleCmd("sm_b", Cmd_Bill);
    RegConsoleCmd("sm_bill", Cmd_Bill);

    RegConsoleCmd("sm_z", Cmd_Zoey);
    RegConsoleCmd("sm_zoey", Cmd_Zoey);

    RegConsoleCmd("sm_l", Cmd_Louis);
    RegConsoleCmd("sm_louis", Cmd_Louis);

    RegConsoleCmd("sm_f", Cmd_Francis);
    RegConsoleCmd("sm_francis", Cmd_Francis);
}

public Action Cmd_Coach(int client, int args)     { return ChangeToSurvivor(client, SURV_COACH); }
public Action Cmd_Nick(int client, int args)      { return ChangeToSurvivor(client, SURV_NICK); }
public Action Cmd_Rochelle(int client, int args)  { return ChangeToSurvivor(client, SURV_ROCHELLE); }
public Action Cmd_Ellis(int client, int args)     { return ChangeToSurvivor(client, SURV_ELLIS); }
public Action Cmd_Bill(int client, int args)      { return ChangeToSurvivor(client, SURV_BILL); }
public Action Cmd_Zoey(int client, int args)      { return ChangeToSurvivor(client, SURV_ZOEY); }
public Action Cmd_Louis(int client, int args)     { return ChangeToSurvivor(client, SURV_LOUIS); }
public Action Cmd_Francis(int client, int args)   { return ChangeToSurvivor(client, SURV_FRANCIS); }

public Action ChangeToSurvivor(int client, SurvivorType st)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Handled;

    bool isL4D2Surv = (st <= SURV_ELLIS);
    bool isL4D1Surv = (st >= SURV_BILL);

    if (g_bIsL4D1Map && isL4D2Surv)
    {
        PrintToChat(client, "\x01This campaign does not support \x04%s", g_SurvivorNames[st]);
        return Plugin_Handled;
    }

    if (!g_bIsL4D1Map && isL4D1Surv)
    {
        PrintToChat(client, "\x01This campaign does not support \x04%s", g_SurvivorNames[st]);
        return Plugin_Handled;
    }

    int gameIndex = g_GameIndexMap[st];

    SetEntProp(client, Prop_Send, "m_survivorCharacter", gameIndex);
    SetEntityModel(client, g_SurvivorModels[st]);
    SetEntPropString(client, Prop_Data, "m_ModelName", g_SurvivorModels[st]);
    int idx = PrecacheModel(g_SurvivorModels[st], true);
    SetEntProp(client, Prop_Send, "m_nModelIndex", idx);

    PrintToChat(client, "\x01You are now playing as \x04%s", g_SurvivorNames[st]);

    return Plugin_Handled;
}