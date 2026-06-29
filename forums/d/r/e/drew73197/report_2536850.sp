#include <sourcemod>
#include <sdktools> 
#include <dbi>

#define ADVERTISEMENT_INTERVAL 900.0 // 15 minutes in seconds
#define COMMAND_COOLDOWN 300.0 // 5 minutes in seconds

public Plugin myinfo =
{
    name = "Report tool",
    author = "Reo",
    description = "Adds a report to a database",
    version = "2.0",
    url = "https://reo.tf"
};

char g_sHostname[100];
new Float:gf_LastUsedReport[MAXPLAYERS + 1];

public void OnPluginStart()
{
    RegConsoleCmd("sm_report", Command_Report);
    CreateTimer(ADVERTISEMENT_INTERVAL, AdvertiseQueue, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Command_Report(int client, int args)
{
    Handle tmp = FindConVar("hostname");
    GetConVarString(tmp, g_sHostname, sizeof(g_sHostname)); 
    CloseHandle(tmp);
    
    char error[255], conf[255] = "reports";
    Database db = SQL_Connect(conf, true, error, sizeof(error));
    char arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    int target = FindTargetEx(client, arg1, true, false);
    if (db == null)
    {
        ReplyToCommand(client, "[SM] Couldn't connect to the database: %s", error);
        return Plugin_Handled;
    }

    if (args < 2) // Requires at least suspect and reason
    {
        ReplyToCommand(client, "[SM] Usage: !report <player> <reason>");
        return Plugin_Handled;
    }
    
    if (target == -1)
    {
        ReplyToCommand(client, "[SM] No player found try using their userID.");
        return Plugin_Handled;
    }

    if (!CheckCooldown(client, gf_LastUsedReport))
    {
        ReplyToCommand(client, "[SM] Please wait before using this command again.");
        return Plugin_Handled;
    }

    char reason[256], query[512];
    CollectReasonFromArguments(reason, sizeof(reason), 2, args);
    char SuspectName[MAX_NAME_LENGTH], SuspectID[32], ReporterName[MAX_NAME_LENGTH], ReporterID[32];
    GetClientAuthId(target, AuthId_Steam2, SuspectID, sizeof(SuspectID));
    GetClientName(target, SuspectName, sizeof(SuspectName));
    GetClientAuthId(client, AuthId_Steam2, ReporterID, sizeof(ReporterID));
    GetClientName(client, ReporterName, sizeof(ReporterName));
    
    char escapedReason[512], escapedSuspectName[64], escapedReporterName[64];
    SQL_EscapeString(db, reason, escapedReason, sizeof(escapedReason));
    SQL_EscapeString(db, SuspectName, escapedSuspectName, sizeof(escapedSuspectName));
    SQL_EscapeString(db, ReporterName, escapedReporterName, sizeof(escapedReporterName));
    
    Format(query, sizeof(query), "INSERT INTO sb_reports (server_name, reporter, reporter_id, suspect, suspect_id, reason) VALUES ('%s', '%s', '%s', '%s', '%s', '%s');", g_sHostname, escapedReporterName, ReporterID, escapedSuspectName, SuspectID, escapedReason);
    if (SQL_FastQuery(db, query))
    {
        ReplyToCommand(client, "[SM] Your report has been sent to the admins!");
    }
    else
    {
        ReplyToCommand(client, "[SM] Couldn't send your report!");
    }
    return Plugin_Handled;
}

// Function to collect reason from command arguments
void CollectReasonFromArguments(char[] buffer, int buffer_size, int start_arg, int total_args)
{
    buffer[0] = '\0'; // Initialize the buffer to empty string
    for (int i = start_arg; i <= total_args; i++)
    {
        char arg[256];
        GetCmdArg(i, arg, sizeof(arg));
        StrCat(buffer, buffer_size, arg);
        if (i < total_args)
        {
            StrCat(buffer, buffer_size, " "); // Add space between words
        }
    }
}

public bool CheckCooldown(int client, float[] lastUsedArray)
{
    float lastUsed = lastUsedArray[client];
    float currentTime = float(GetTime());

    if (currentTime - lastUsed < COMMAND_COOLDOWN)
    {
        return false;
    }

    lastUsedArray[client] = currentTime; // Update last used time
    return true;
}

// Advertise queue every 15 minutes
public Action AdvertiseQueue(Handle timer, any data)
{
    PrintToChatAll("Send a report to the admins with /report");
    return Plugin_Continue;
}

FindTargetEx(client, const String:target[], bool:nobots = false, bool:immunity = true, bool:replyToError = true) {
    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[1], target_count, bool:tn_is_ml;
    
    new flags = COMMAND_FILTER_NO_MULTI;
    if(nobots) {
        flags |= COMMAND_FILTER_NO_BOTS;
    }
    if(!immunity) {
        flags |= COMMAND_FILTER_NO_IMMUNITY;
    }
    
    if((target_count = ProcessTargetString(
            target,
            client, 
            target_list, 
            1, 
            flags,
            target_name,
            sizeof(target_name),
            tn_is_ml)) > 0)
    {
        return target_list[0];
    } else {
        if(replyToError) {
            ReplyToTargetError(client, target_count);
        }
        return -1;
    }
}
