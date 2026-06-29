#include <sourcemod>

#define MAX_AWARDS 151 
#define BAN_THRESHOLD -1000 // Can be changed later 
#define AWARD_COOLDOWN 1.0
#define AWARD_BAN_TIME 20 //(0 = permanent)

int awardPoints[MAX_AWARDS];            // Points for each award (0-150)
int lastAward[MAXPLAYERS+1][MAX_AWARDS];
int score[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    // Register your native here
    CreateNative("Give_Award", Native_GiveAward);
    return APLRes_Success;
}

// This is the native callback
public any Native_GiveAward(Handle plugin, int numParams)
{
    // Read parameters from the native call
    int client = GetNativeCell(1);
    int awardId = GetNativeCell(2);

    PlayerAward(client, awardId);

    return 0; // natives usually return a value, but you can keep void by returning 0
}

public void OnPluginStart()
{
    HookEvent("award_earned", Event_PlayerAward);
    RegAdminCmd("sm_reload_awards", Command_ReloadAwards, ADMFLAG_ROOT, "Reloads the award configuration");
    LoadAwardConfig();
}

public void OnClientPutInServer(int client)
{
    score[client] = 0;
}

void LoadAwardConfig()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/award_config.txt");
    File file = OpenFile(path, "r");

    if (file == null)
    {
        LogError("[AwardBan] Missing config: %s", path);
        return;
    }

    char line[128], parts[2][16];
    // Reset all awards to unassigned
    for (int i = 0; i < MAX_AWARDS; i++) 
    {
        awardPoints[i] = 0;
    }

    while (!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
    {
        TrimString(line);
        // Skip comments and empty lines
        if (line[0] == '/' || line[0] == '\0' || !IsCharNumeric(line[0])) 
            continue;

        // Split by colon
        int partCount = ExplodeString(line, ":", parts, sizeof(parts), sizeof(parts[]));
        if (partCount >= 2)
        {
            int id = StringToInt(parts[0]);
            // Validate ID range (1-150, stored in 1-150 indexes)
            if (id >= 1 && id < MAX_AWARDS)
            {
                awardPoints[id] = StringToInt(parts[1]);
                PrintToServer("[AwardConfig] Loaded ID:%d Points:%d", id, awardPoints[id]);
            }
            else
            {
                LogError("[AwardConfig] Invalid award ID: %d (must be 1-%d)", id, MAX_AWARDS-1);
            }
        }
        else
        {
            LogError("[AwardConfig] Invalid line format: %s", line);
        }
    }
    delete file;
}

public Action Command_ReloadAwards(int client, int args)
{
    LoadAwardConfig();
    ReplyToCommand(client, "[AwardBan] Award config reloaded");
    return Plugin_Handled;
}

public void Event_PlayerAward(Event event, const char[] name, bool db)
{
    PlayerAward(GetClientOfUserId(event.GetInt("userid")) , event.GetInt("award"));
}

stock void PlayerAward(int client, int id)
{
    if (!client || id >= MAX_AWARDS) 
        return;

    int currentTime = GetTime();

    if (currentTime - lastAward[client][id] < AWARD_COOLDOWN) 
        return;

    lastAward[client][id] = currentTime;

    if (awardPoints[id] == 0)
    {
        PrintToChat(client, "[AwardBan] AwardID: %d [not assigned]", id);
        return;
    }

    score[client] += awardPoints[id];

    PrintToChat(client, "[AwardBan] AwardID: %d (assigned) cost:%d | TotalScore: %d",
        id, awardPoints[id], score[client]);
        
    
    if (score[client] <= BAN_THRESHOLD)
    {
        BanClient(client, AWARD_BAN_TIME , BANFLAG_AUTO, "Trolling detected (too many negative awards)", "Trolling detected");
    }
}