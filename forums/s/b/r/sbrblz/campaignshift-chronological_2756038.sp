//# vim: set filetype=cpp :

/*
 * license = "https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html#SEC1",
 */

//#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_NAME "CampaignShift"
#define PLUGIN_VERSION "0.0.15"

#define i_mapStart(%1)      g_cMappings[%1 + g_skip]
#define i_mapEnd(%1)        g_cMappings[%1 + g_skip + 1]
#define i_campaignName(%1)  g_cMappings[%1 + g_skip + 2]
#define i_mapName(%1)       g_cMappings[%1 + g_skip + 3]

static int g_skipVotes[MAXPLAYERS + 1];
static int g_replayVotes[MAXPLAYERS + 1];
int g_voted;                // see OnMapStart & SkipOutroIntercept
char g_campaignName[64];    // Campaign name
char g_mapStart[64];        // changelevel name
int g_defaultMode = 0;      // 0: coop 1: versus 2: scavenge 3: survival
int g_skip;                 // See SetModeSkip()
int g_mode;                 // See SetModeSkip()
int g_columns = 8;          // Columns per row in cMappings
bool g_matchEnded;          // Flag is set when a competitive match ends
bool g_newGame = true;
char g_currentCampaignName[64];
char g_currentMapStart[64];
bool g_transitioning;
Handle g_cvCmdDelay; float g_cmdDelay;
bool g_restartMap; bool g_warpToStartArea;
float g_notice;

char g_cMappings[][64] = {
    // coop, versus, scavenge, survival mapStart, mapEnd, campaignName, mapName
    "1", "1", "1", "1", "c8m1_apartment", "c8m5_rooftop", "No Mercy", "Apartments",
    "0", "0", "0", "1", "c8m2_subway", "c8m2_subway", "No Mercy", "Generator Room",
    "0", "0", "1", "1", "c8m5_rooftop", "c8m5_rooftop", "No Mercy", "Rooftop",
    "1", "1", "0", "0", "c9m1_alleys", "c9m2_lots", "Crash Course", "Alleys",
    "1", "1", "0", "0", "c10m1_caves", "c10m5_houseboat", "Death Toll", "Caves",
	"1", "0", "0", "0", "c14m1_junkyard", "c14m2_lighthouse", "The Last Stand", "The Junkyard",
	"1", "1", "0", "0", "c11m1_greenhouse", "c11m5_runway", "Dead Air", "Greenhouse",
    "1", "1", "0", "0", "c12m1_hilltop", "c12m5_cornfield", "Blood Harvest", "Hilltop",
	"1", "1", "1", "1", "c7m1_docks", "c7m3_port", "The Sacrifice", "Docks",
    "0", "0", "1", "1", "c7m2_barge", "c7m2_barge", "The Sacrifice", "Barge",
    "0", "0", "0", "1", "c7m3_port", "c7m3_port", "The Sacrifice", "Port",
    "1", "1", "0", "0", "c1m1_hotel", "c1m4_atrium", "Dead Center", "Hotel",
    "0", "0", "1", "1", "c1m4_atrium", "c1m4_atrium", "Dead Center", "Mall Atrium",
	"1", "1", "0", "1", "c6m1_riverbank", "c6m3_port", "The Passing", "Riverbank",
	"0", "0", "1", "1", "c6m2_bedlam", "c6m2_bedlam", "The Passing", "Underground",
	"0", "0", "1", "1", "c6m3_port", "c6m3_port", "The Passing", "Port",
    "1", "1", "1", "1", "c2m1_highway", "c2m5_concert", "Dark Carnival", "Highway",
    "0", "0", "0", "1", "c2m4_barns", "c2m4_barns", "Dark Carnival", "Stadium Gate",
    "0", "0", "0", "1", "c2m5_concert", "c2m5_concert", "Dark Carnival", "Concert",
    "1", "1", "1", "1", "c3m1_plankcountry", "c3m4_plantation", "Swamp Fever", "Plank Country",
    "0", "0", "0", "1", "c3m4_plantation", "c3m4_plantation", "Swamp Fever", "Plantation",
    "1", "1", "1", "1", "c4m1_milltown_a", "c4m5_milltown_escape","Hard Rain", "Mill Town",
    "0", "0", "1", "1", "c4m2_sugarmill_a", "c4m2_sugarmill_a", "Hard Rain", "Sugar Mill",
    "1", "1", "0", "0", "c5m1_waterfront", "c5m5_bridge","The Parish", "Waterfront",
    "0", "0", "1", "1", "c5m2_park", "c5m2_park", "The Parish", "Bus Depot",
    "0", "0", "0", "1", "c5m5_bridge", "c5m5_bridge", "The Parish", "Bridge",
    "1", "1", "0", "0", "c13m1_alpinecreek", "c13m4_cutthroatcreek", "Cold Stream", "Alpine Creek"
};

public Plugin myinfo= {
    name = PLUGIN_NAME,
    author = "Victor \"NgBUCKWANGS\" Gonzalez",
    description = "Shift to the Next Campaign Automatically on Credits End.",
    version = PLUGIN_VERSION,
    url = "https://gitlab.com/vbgunz/CampaignShift"
}

public void OnPluginStart() {
    AddCommandListener(UnpauseIntercept, "unpause");
    AddCommandListener(ChangeIntercept, "sm_map");
    AddCommandListener(ChangeIntercept, "changelevel");
    AddCommandListener(SkipOutroIntercept, "skipouttro");
    AddCommandListener(OutroDoneIntercept, "outtro_stats_done");
    HookEvent("player_disconnect", DisconnectHook, EventHookMode_Pre);
    HookEvent("versus_match_finished", VsMatchEndedHook);
    HookEvent("scavenge_match_finished", VsMatchEndedHook);
    HookEvent("finale_win", NextMapHook);
    HookEvent("round_end", NextMapHook);
    HookEvent("map_transition", TransHook);
    HookEvent("server_spawn", SpawnHook);
    HookEvent("round_freeze_end", SetupScavenge);

    g_cvCmdDelay = FindConVar("sv_vote_command_delay");
    g_cmdDelay = GetConVarFloat(g_cvCmdDelay);
}

public void TransHook(Handle event, const char[] name, bool dontBroadcast) {
    g_transitioning = true;
}

public void SpawnHook(Handle event, const char[] name, bool dontBroadcast) {
    g_newGame = !g_transitioning ? true : false;
}

public void DisconnectHook(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int clients = CountClients() - 1;

    if (g_newGame && IsClientConnected(client) && !IsFakeClient(client)) {
        if (g_replayVotes[client] > 0) {
            g_replayVotes[client] = 0;

            PrintToChatAll(
                "\x03[ REPLAY \x01%d / %d\x03 ]: \x01Vote Tally Changed",
                GetReplayVotes(), clients
            );
        }

        if (g_skipVotes[client] > 0) {
            g_skipVotes[client] = 0;
            g_voted--;
        }

        if (g_voted >= clients) {
            OutroDoneIntercept(0, "", 0);
        }
    }
}

public void VsMatchEndedHook(Handle event, const char[] name, bool dontBroadcast) {
    g_matchEnded = true;
}

public void NextMapHook(Handle event, const char[] name, bool dontBroadcast) {
    if (StrEqual(name, "finale_win")) {
        g_newGame = true;
    }

    SetupShift(false);

    if (g_matchEnded) {
        g_matchEnded = false;

        if (g_mode == 2) {
            g_restartMap = true;

            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientConnected(i) && IsClientInGame(i)) {
                    if (GetClientTeam(i) >= 2 && !IsFakeClient(i)) {
                        FakeClientCommand(i, "pzendgameyes");
                    }
                }
            }
        }

        else {
            CreateTimer(3.0, VsMatchNextMapTimer, _);
        }
    }
}

public Action VsMatchNextMapTimer(Handle timer) {
    OutroDoneIntercept(0, "", 0);
}

public void OnMapStart() {
    SetConVarFloat(g_cvCmdDelay, g_cmdDelay);
    SetupShift(g_newGame);
    g_newGame = false;
    g_transitioning = false;
    g_voted = 0;

    for (int i = 1; i <= MaxClients; i++) {
        g_skipVotes[i] = g_replayVotes[i] = 0;
    }
}

void SetModeSkip() {
    static char mode[64];  // mutation12 = realism versus
    GetConVarString(FindConVar("mp_gamemode"), mode, sizeof(mode));

    switch (mode[0]) {
        case 'c': {
            if (StrEqual(mode, "coop")) g_mode = 0;
            else if (StrEqual(mode, "community1")) g_mode = 0;  // Special Delivery
            else if (StrEqual(mode, "community2")) g_mode = 0;  // Flu Season
            else if (StrEqual(mode, "community3")) g_mode = 1;  // Riding My Survivor
            else if (StrEqual(mode, "community4")) g_mode = 3;  // Nightmare
            else if (StrEqual(mode, "community5")) g_mode = 0;  // Death's Door
        }

        case 'm': {
            if (StrEqual(mode, "mutation1")) g_mode = 0;        // Last Man on Earth
            else if (StrEqual(mode, "mutation2")) g_mode = 0;   // Headshot!
            else if (StrEqual(mode, "mutation3")) g_mode = 0;   // Bleed Out
            else if (StrEqual(mode, "mutation4")) g_mode = 0;   // Hard Eight
            else if (StrEqual(mode, "mutation5")) g_mode = 0;   // Four Swordsmen
            else if (StrEqual(mode, "mutation7")) g_mode = 0;   // Chainsaw Massacre
            else if (StrEqual(mode, "mutation8")) g_mode = 0;   // Ironman
            else if (StrEqual(mode, "mutation9")) g_mode = 0;   // Last Gnome on Earth
            else if (StrEqual(mode, "mutation10")) g_mode = 0;  // Room for One
            else if (StrEqual(mode, "mutation11")) g_mode = 1;  // Healthpackalypse
            else if (StrEqual(mode, "mutation12")) g_mode = 1;  // Realism Versus
            else if (StrEqual(mode, "mutation13")) g_mode = 2;  // Follow the Liter
            else if (StrEqual(mode, "mutation14")) g_mode = 0;  // Gib Fest
            else if (StrEqual(mode, "mutation15")) g_mode = 3;  // Versus Survival
            else if (StrEqual(mode, "mutation16")) g_mode = 0;  // Hunting Party
            else if (StrEqual(mode, "mutation17")) g_mode = 0;  // Lone Gunman
            else if (StrEqual(mode, "mutation18")) g_mode = 1;  // Bleed Out Versus
            else if (StrEqual(mode, "mutation19")) g_mode = 1;  // Taaannnkk!
            else if (StrEqual(mode, "mutation20")) g_mode = 0;  // Healing Gnome
        }

        case 'r': {
            if (StrEqual(mode, "realism")) g_mode = 0;
        }

        case 's': {
            if (StrEqual(mode, "scavenge")) g_mode = 2;
            else if (StrEqual(mode, "survival")) g_mode = 3;
        }

        case 't': {
            if (StrEqual(mode, "teamscavenge")) g_mode = 2;
            else if (StrEqual(mode, "teamversus")) g_mode = 1;
        }

        case 'v': {
            if (StrEqual(mode, "versus")) g_mode = 1;
        }

        default: {
            g_mode = g_defaultMode;
        }
    }

    for (int i = g_mode; i < sizeof(g_cMappings); i += g_columns) {
        if (g_cMappings[i][0] == '1') {
            for (int j = 1; j <= 5; j++) {
                if (!IsCharNumeric(g_cMappings[i + j][0])) {
                    g_skip = j;
                    return;
                }
            }
        }
    }
}

void SetupShift(bool getCurrentMap=true) {
    SetModeSkip();

    // http://cplusplus.com/reference/clibrary/ctime/strftime.html
    static char sHour[4], sMinute[4], currentMap[64];
    FormatTime(sMinute, sizeof(sMinute), "%M", GetTime());
    FormatTime(sHour, sizeof(sHour), "%H", GetTime());
    GetCurrentMap(currentMap, sizeof(currentMap));

    if (getCurrentMap) {
        g_currentCampaignName = currentMap;
        g_currentMapStart = currentMap;
    }

    bool found;
    static int j;
    j = 0;

    for (int i = g_mode; i < sizeof(g_cMappings); i += g_columns) {
        if (g_cMappings[i][0] == '1') {
            j++;
        }
    }

    static float perCampaign, next;
    perCampaign = 480.0 / float(j);
    next = StringToFloat(sHour) * 60.0 + StringToFloat(sMinute);
    PrintToServer("-- %f Minutes per Campaign", perCampaign);
    j = -1;

    while (j == -1) {
        for (int i = g_mode; i < sizeof(g_cMappings); i += g_columns) {
            if (g_cMappings[i][0] == '1') {
                next -= perCampaign;

                if (found) {
                    j = i;
                    break;
                }

                else if (next <= 0 && j == -1) {
                    j = i;
                }

                switch (g_mode) {
                    case 0, 1: found = StrEqual(currentMap, i_mapEnd(i));
                    case 2, 3: found = StrEqual(currentMap, i_mapStart(i));
                }

                if (found && getCurrentMap) {
                    g_currentCampaignName = i_campaignName(i);
                    g_currentMapStart = i_mapStart(i);
                }
            }
        }
    }

    PrintToServer("\
        -- currentMap: %s \n\
        -- nextMap: %s",
        currentMap, i_mapStart(j)
    );

    g_campaignName = i_campaignName(j);
    g_mapStart = i_mapStart(j);
}

int CountClients() {
    static int clients;
    clients = 0;

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
            clients++;
        }
    }

    return clients;
}

public Action ChangeIntercept(int client, const char[] cmd, int argc) {
    static char map[64];
    if (CheckCommandAccess(client, cmd, ADMFLAG_CHANGEMAP)) {
        if (GetCmdArg(1, map, sizeof(map)) && IsMapValid(map)) {
            g_newGame = !g_transitioning ? true : false;
            g_notice = GetEngineTime() + 4.0;
        }
    }
}

public Action SkipOutroIntercept(int client, const char[] cmd, int argc) {
    g_newGame = true;
    if (++g_skipVotes[client] <= 1 && ++g_voted >= CountClients()) {
        OutroDoneIntercept(0, "", 0);
    }
}

int GetReplayVotes() {
    static int votes;
    votes = 0;

    for (int i = 1; i <= MaxClients; i++) {
        if (g_replayVotes[i] >= 1) {
            votes++;
        }
    }

    return votes;
}

public void SetupScavenge(Handle event, const char[] name, bool dontBroadcast) {
    if (g_mode == 2 && g_restartMap) {
        g_cmdDelay = GetConVarFloat(g_cvCmdDelay);
        SetConVarFloat(g_cvCmdDelay, 0.0);
        ForceVoteMapChange(g_mapStart);
        g_restartMap = false;
    }
}

void ForceVoteMapChange(const char[] map) {
    g_warpToStartArea = true;

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i) && GetClientTeam(i) == 3 && IsFakeClient(i)) {
            KickClient(i);
        }
    }

    int j = CreateFakeClient(PLUGIN_NAME);
    if (DispatchKeyValue(j, "classname", "SurvivorBot")) {
        ChangeClientTeam(j, 3);

        if (DispatchSpawn(j)) {
            FakeClientCommand(j, "callvote ChangeChapter %s", map);
            AcceptEntityInput(j, "Kill");

            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientConnected(i) && IsClientInGame(i)) {
                    if (GetClientTeam(i) >= 2 && !IsFakeClient(i)) {
                        FakeClientCommand(i, "Vote Yes");
                    }
                }
            }
        }
    }
}

public Action UnpauseIntercept(int client, const char[] cmd, int argc) {
    if (g_warpToStartArea) {
        g_warpToStartArea = false;

        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientConnected(i) && IsClientInGame(i)) {
                if (GetClientTeam(i) == 2) {
                    QuickCheat(i, "warp_to_start_area");
                }
            }
        }
    }
}

void QuickCheat(int client, char [] cmd) {
    int flags = GetCommandFlags(cmd);
    SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s", cmd);
    SetCommandFlags(cmd, flags);
}

public Action OutroDoneIntercept(int client, const char[] cmd, int argc) {
    if (CountClients() > 0 && GetReplayVotes() > (CountClients() / 2)) {
        g_campaignName = g_currentCampaignName;
        g_mapStart = g_currentMapStart;
    }

    if (GetGameTime() > 30.0) {
        PrintToServer(" -Shifting: %s", g_campaignName);
        ServerCommand("changelevel %s", g_mapStart);
    }
}

//void OnKeyPress(int client, int key) {}

void OnKeyHold(int client, int key) {
    if (key == 4) {
        g_replayVotes[client] = 1;
    }
}

void OnKeyRelease(int client, int key, int held) {
    static char msg[64];

    if (key == 4) {  // CROUCH KEY
        if (held < 5) {
            g_replayVotes[client] = !(g_replayVotes[client]);
        }

        if (g_newGame) {
            switch (g_replayVotes[client]) {
                case 1: msg = "You've Voted to Replay";
                case 0: msg = "You've Voted NOT to Replay";
            }

            PrintToChat(client,\
                "\x03[ REPLAY \x01%d / %d\x03 ]: \x01%s",
                GetReplayVotes(), CountClients(), msg
            );
        }
    }
}

void OnNoKey(int client) {
    if (!g_newGame) {
        g_replayVotes[client] = 0;
    }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
    static float notice;
    static int noKey[MAXPLAYERS + 1];

    if (GetEngineTime() < g_notice) {
        return;
    }

    g_notice = GetEngineTime();
    if (g_newGame && g_notice > notice + 24.0) {
        notice = g_notice;

        PrintToChatAll(
            "\x03[ REPLAY \x01%d / %d\x03 ]: \x01Tap \x03'CROUCH' \x01to Vote",
            GetReplayVotes(), CountClients()
        );
    }

    // Thanks @ https://forums.alliedmods.net/showthread.php?t=151142
    if (IsClientConnected(client) && !IsFakeClient(client)) {
        static int button;
        static int longHolds[MAXPLAYERS + 1];
        static int lastKey[MAXPLAYERS + 1];

        for (int i = 0; i < 25; i++) {  // MAX_BUTTONS 25
            button = (1 << i);

            if ((buttons & button)) {
                longHolds[client]++;

                if (!(lastKey[client] & button)) {
                    //OnKeyPress(client, buttons);
                    longHolds[client] = 1;
                }
            }

            else if ((lastKey[client] & button)) {
                OnKeyRelease(client, lastKey[client], longHolds[client]);
                longHolds[client] = 0;
            }
        }

        if (longHolds[client] == 5) {
            OnKeyHold(client, buttons);
            longHolds[client]++;
        }

        lastKey[client] = buttons;
    }

    switch (buttons) {
        case  0: noKey[client]++;
        default: noKey[client]=0;
    }

    if (noKey[client] == 2) {
        OnNoKey(client);
    }
}
