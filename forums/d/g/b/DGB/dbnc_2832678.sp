/*****************************************************************************
                  Dynamic Bot Name Changer (4FuN Plugin)
******************************************************************************/
#include <sourcemod>
#include <sdktools>
#pragma tabsize 0 // Remove annoying table and space warning messages

/////////////////////////////////////////////// Default settings
ConVar sm_rdescription;
ConVar sm_rdescriptiontime;
ConVar sm_rdescription_random;
ConVar sm_rname;
ConVar sm_rtime;
ConVar sm_rday;
ConVar sm_rmonth;
ConVar sm_rweek;

/////////////////////////////////////////////// Outro
ConVar sm_rblockbroadcast;
ConVar sm_drn_enabled;

/////////////////////////////////////////////// Source TV Settings
ConVar sm_stvday
ConVar sm_stvdescription
ConVar sm_stvmonth
ConVar sm_stvtime
ConVar sm_stvweek
ConVar sm_stvchanges
ConVar sm_stvname

#define MAX_DESCRIPTIONS 30
#define MAX_DESCRIPTION_LENGTH 128
char g_Descriptions[MAX_DESCRIPTIONS][MAX_DESCRIPTION_LENGTH];
int g_DescriptionCount;
int g_CurrentDescription = 0;
Handle g_DescriptionTimer = null;

/////////////////////////////////////////////// Plugin Info

public Plugin:myinfo =
{
    name = "Dynamic Replay Name",
    author = "DGB",
    description = "Dynamically changes the name of the replay bot in TF2",
    version = "1.1.0",
    url = ""
};

/////////////////////////////////////////////// Plugin Start

public void OnPluginStart()
{
/////////////////////////////////////////////////// Replay (R) Commands

    sm_rdescription = CreateConVar("sm_rdescription", "1", "Activate dynamic descriptions (1 for yes, 0 for no)", FCVAR_NONE);
    sm_rdescriptiontime = CreateConVar("sm_rdescriptiontime", "10", "Time in minutes to change the description", FCVAR_NONE, true, 1.0);
    sm_rdescription_random = CreateConVar("sm_rdescription_random", "0", "Activate random rotation of descriptions (1 for yes, 0 for no)", FCVAR_NONE);
    HookConVarChange(sm_rdescription_random, OnDescriptionRandomChanged);
    HookConVarChange(sm_rdescriptiontime, OnDescriptionTimeChanged);
    sm_rname = CreateConVar("sm_rname", "Example Replay", "A name for replay bot", FCVAR_NONE);
    sm_rtime = CreateConVar("sm_rtime", "1", "Add time to replay bot name (1 for yes, 0 for no)", FCVAR_NONE);
    sm_rday = CreateConVar("sm_rday", "1", "Add day to replay bot name (1 for yes, 0 for no)", FCVAR_NONE);
    sm_rmonth = CreateConVar("sm_rmonth", "1", "Add month to replay bot name (1 for yes, 0 for no)", FCVAR_NONE);
    sm_rweek = CreateConVar("sm_rweek", "0", "Add day of the week to replay bot name (1 for yes, 0 for no)", FCVAR_NONE);
	sm_rblockbroadcast = CreateConVar("sm_rblockbroadcast", "1", "Block the broadcast name change for the bot in the chat", FCVAR_NONE);
    sm_drn_enabled = CreateConVar("sm_drn_enabled", "1", "Enable Dynamic Replay Name (1 for yes, 0 for no)", FCVAR_NONE);
	
	
	/////////////////////////////////////////////// Source TV (STV) Commands
	
    sm_stvchanges = CreateConVar("sm_stvchanges", "1", "Enable SourceTV name change (1 for yes, 0 for no)", FCVAR_NONE);
    sm_stvname = CreateConVar("sm_stvname", "Example Source TV", "A name for SourceTV bot", FCVAR_NONE);
    sm_stvday = CreateConVar("sm_stvday", "1", "Add date to SourceTV bot name (1 for yes, 0 for no)", FCVAR_NONE);
	sm_stvweek = CreateConVar("sm_stvweek", "0", "Add a week to SourceTV bot name (1 for yes, 0 for no)", FCVAR_NONE);
    sm_stvdescription = CreateConVar("sm_stvdescription", "1", "Add description to SourceTV bot name (1 for yes, 0 for no)", FCVAR_NONE);
    sm_stvtime = CreateConVar("sm_stvtime", "0", "Add time to SourceTV bot name (1 for yes, 0 for no)", FCVAR_NONE);
	sm_stvmonth = CreateConVar("sm_stvmonth", "0", "Add month to SourceTV bot name (1 for yes, 0 for no)", FCVAR_NONE);
	
	/////////////////////////////////////////////// Another Bonus Things

    LoadDescriptions();
    CreateTimer(5.0, UpdateReplayBotName, _, TIMER_REPEAT);
	CreateTimer(5.0, UpdateSourceTVBotName, _, TIMER_REPEAT);
    StartDescriptionTimer();
    HookUserMessage(GetUserMessageId("SayText2"), SayText2, true);
	AutoExecConfig(true, "dnyamic_replay_name"); // Check your Source Mod CFG File -7-
}

void StartDescriptionTimer()
{
    if (g_DescriptionTimer != null)
    {
        CloseHandle(g_DescriptionTimer);
    }
    g_DescriptionTimer = CreateTimer(sm_rdescriptiontime.FloatValue * 60.0, RotateDescription, _, TIMER_REPEAT);
}

public void OnDescriptionTimeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    StartDescriptionTimer();
}

public void OnDescriptionRandomChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!sm_rdescription_random.BoolValue)
    {
        g_CurrentDescription = 0;
    }
    RotateDescription(null);
    StartDescriptionTimer();
}

/////////////////////////////////////////////// Descriptions Config Reader

void LoadDescriptions()
{
    Handle file = OpenFile("addons/sourcemod/configs/rdescription.cfg", "r");
    if (file == null)
    {
        PrintToServer("[Dynamic Replay Bot] Falha ao abrir rdescription.cfg");
        return;
    }

    g_DescriptionCount = 0;
    char line[128];
    while (!IsEndOfFile(file) && g_DescriptionCount < MAX_DESCRIPTIONS)
    {
        if (ReadFileLine(file, line, sizeof(line)))
        {
            TrimString(line);

            if (line[0] != '\0' && line[0] != '/' && !(line[0] == '/' && line[1] == '/')) // Literally ignores lines or examples with // like this.
            {
                strcopy(g_Descriptions[g_DescriptionCount], sizeof(g_Descriptions[]), line);
                g_DescriptionCount++;
            }
        }
    }
	
    CloseHandle(file);

    if (g_DescriptionCount > 0)
    {
        PrintToServer("[Dynamic Replay Bot] %d descriptions uploaded successfully.", g_DescriptionCount);
    }
    else
    {
        PrintToServer("[Dynamic Replay Bot] No valid description found in the file.");
    }
}

public Action RotateDescription(Handle timer)
{
    if (g_DescriptionCount == 0 || !sm_rdescription.BoolValue)
    {
        return Plugin_Continue;
    }

    if (sm_rdescription_random.BoolValue)
    {
        g_CurrentDescription = GetRandomInt(0, g_DescriptionCount - 1);
    }
    else
    {
        g_CurrentDescription = (g_CurrentDescription + 1) % g_DescriptionCount;
    }
	
    return Plugin_Continue;
}

////////////////////////////////////////////// Bot replay updating name.

public Action UpdateReplayBotName(Handle timer)
{
    if (!sm_drn_enabled.BoolValue)
    {
        return Plugin_Continue;
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
        {
            continue;
        }

        if (IsClientReplay(client))
        {
            char baseName[32];
            GetConVarString(sm_rname, baseName, sizeof(baseName));

            char newName[256];
            strcopy(newName, sizeof(newName), baseName);
			
            // Add details to Replay Bot name
            if (sm_rtime.BoolValue)
            {
                char timeStr[32];
                FormatTime(timeStr, sizeof(timeStr), "%H:%M", GetTime());
                AddToName(newName, timeStr, sizeof(newName));
            }
            if (sm_rday.BoolValue)
            {
                char dayStr[16];
                FormatTime(dayStr, sizeof(dayStr), "%d/%m/%Y", GetTime());
                AddToName(newName, dayStr, sizeof(newName));
            }
            if (sm_rmonth.BoolValue)
            {
                char monthStr[16];
                FormatTime(monthStr, sizeof(monthStr), "%B", GetTime());
                AddToName(newName, monthStr, sizeof(newName));
            }
            if (sm_rweek.BoolValue)
            {
                char weekStr[16];
                FormatTime(weekStr, sizeof(weekStr), "%A", GetTime());
                AddToName(newName, weekStr, sizeof(newName));
            }
            if (sm_rdescription.BoolValue && g_DescriptionCount > 0)
            {
                AddToName(newName, g_Descriptions[g_CurrentDescription], sizeof(newName));
            }

            char currentName[256];
            GetClientName(client, currentName, sizeof(currentName));

            if (!StrEqual(currentName, newName))
            {
                SetClientName(client, newName);
            }
        }
    }

    return Plugin_Continue;
}

////////////////////////////////////////////// Bot Source TV updating name.

public Action UpdateSourceTVBotName(Handle timer)
{
    if (!sm_drn_enabled.BoolValue || !sm_stvchanges.BoolValue)
    {
        return Plugin_Continue;
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
        {
            continue;
        }

        if (IsClientSourceTV(client))
        {
            char baseName[32];
            GetConVarString(sm_stvname, baseName, sizeof(baseName));

            char newName[256];
            strcopy(newName, sizeof(newName), baseName);

            // Add details to SourceTV Bot name
            if (sm_stvtime.BoolValue)
            {
                char timeStr[32];
                FormatTime(timeStr, sizeof(timeStr), "%H:%M", GetTime());
                AddToName(newName, timeStr, sizeof(newName));
            }
            if (sm_stvday.BoolValue)
            {
                char dayStr[16];
                FormatTime(dayStr, sizeof(dayStr), "%d/%m/%Y", GetTime());
                AddToName(newName, dayStr, sizeof(newName));
            }
            if (sm_stvmonth.BoolValue)
            {
                char monthStr[16];
                FormatTime(monthStr, sizeof(monthStr), "%B", GetTime());
                AddToName(newName, monthStr, sizeof(newName));
            }
            if (sm_stvweek.BoolValue)
            {
                char weekStr[16];
                FormatTime(weekStr, sizeof(weekStr), "%A", GetTime());
                AddToName(newName, weekStr, sizeof(newName));
            }
            if (sm_stvdescription.BoolValue && g_DescriptionCount > 0)
            {
                AddToName(newName, g_Descriptions[g_CurrentDescription], sizeof(newName));
            }

            char currentName[256];
            GetClientName(client, currentName, sizeof(currentName));

            if (!StrEqual(currentName, newName))
            {
                SetClientName(client, newName);
            }
        }
    }

    return Plugin_Continue;
}

////////////////////////////////////////////// Block name change broadcast

public Action:SayText2(UserMsg:msg_id, Handle:bf, players[], playersNum, bool:reliable, bool:init)
{
    if (sm_rblockbroadcast.BoolValue)
    {
        new String:buffer[25];

        if (GetUserMessageType() == UM_Protobuf)
        {
            PbReadString(bf, "msg_name", buffer, sizeof(buffer));

            // If the message is a name change, BLOCK IT!
            if (StrEqual(buffer, "#TF_Name_Change"))
            {
                return Plugin_Handled;
            }
        }
        else
        {
            BfReadChar(bf);
            BfReadChar(bf);
            BfReadString(bf, buffer, sizeof(buffer));
			
            if (StrEqual(buffer, "#TF_Name_Change"))
            {
                return Plugin_Handled;
            }
        }
    }
	
    return Plugin_Continue;
}

////////////////////////////////////////////// Special character for settings

void AddToName(char[] baseName, const char[] addition, int maxLength)
{
    if (strlen(baseName) > 0)
    {
        StrCat(baseName, maxLength, " | ");
    }
    StrCat(baseName, maxLength, addition);
}
