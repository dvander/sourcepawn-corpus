#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION    "v1.1"
#define PLUGIN_NAME       "Timed Message"

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = "heize",
    description = "Prints a message in chat at a specific time.",
    version = PLUGIN_VERSION,
    url = "http://heizemod.us"
};

// Path to the configuration file
#define CONFIG_FILE "cfg/sourcemod/timed_message.cfg"

// Declaration of CVars
ConVar g_hCvarHour;
ConVar g_hCvarMinute;
ConVar g_hCvarAMPM;
ConVar g_hCvarMessage;
ConVar g_hCvarTimezone;

int lastSentHour = -1;
int lastSentMinute = -1;

// Timezone Offset Map
int GetTimezoneOffset(const char[] tz)
{
    if (StrEqual(tz, "UTC", false)) return 0; // Default - Coordinated Universal Time
    if (StrEqual(tz, "EST", false)) return -5 * 60; // Eastern Standard Time
    if (StrEqual(tz, "CST", false)) return -6 * 60; // Central Standard Time
    if (StrEqual(tz, "MST", false)) return -7 * 60; // Mountain Standard Time
    if (StrEqual(tz, "PST", false)) return -8 * 60; // Pacific Standard Time
    if (StrEqual(tz, "BST", false)) return 1 * 60;  // British Summer Time
    if (StrEqual(tz, "CET", false)) return 1 * 60;  // Central European Time
    if (StrEqual(tz, "EET", false)) return 2 * 60;  // Eastern European Time
    if (StrEqual(tz, "IST", false)) return 5 * 60;  // India Standard Time
    if (StrEqual(tz, "JST", false)) return 9 * 60;  // Japan Standard Time
    if (StrEqual(tz, "AEST", false)) return 10 * 60; // Australian Eastern Standard Time
    if (StrEqual(tz, "AEDT", false)) return 10 * 60; // Australian Eastern Daylight Time
    if (StrEqual(tz, "ACST", false)) return 9 * 60 + 30; // Australian Central Standard Time (9.5 hours = 570 minutes)
    if (StrEqual(tz, "ACDT", false)) return 10 * 60 + 30; // Australian Central Daylight Time (10.5 hours = 630 minutes)
    if (StrEqual(tz, "AWST", false)) return 8 * 60;  // Australian Western Standard Time
    if (StrEqual(tz, "AWDT", false)) return 9 * 60;  // Australian Western Daylight Time
    if (StrEqual(tz, "KST", false)) return 9 * 60;   // Korea Standard Time
    if (StrEqual(tz, "NPT", false)) return 5 * 60 + 45; // Nepal Time (5.75 hours = 345 minutes)
    if (StrEqual(tz, "MSK", false)) return 3 * 60;   // Moscow Standard Time
    if (StrEqual(tz, "MSD", false)) return 4 * 60;   // Moscow Daylight Time
    if (StrEqual(tz, "AST", false)) return -4 * 60;  // Atlantic Standard Time
    if (StrEqual(tz, "ADT", false)) return -3 * 60;  // Atlantic Daylight Time
    if (StrEqual(tz, "EDT", false)) return -4 * 60;  // Eastern Daylight Time
    if (StrEqual(tz, "CDT", false)) return -5 * 60;  // Central Daylight Time
    if (StrEqual(tz, "MDT", false)) return -6 * 60;  // Mountain Daylight Time
    if (StrEqual(tz, "PDT", false)) return -7 * 60;  // Pacific Daylight Time
    if (StrEqual(tz, "AKST", false)) return -9 * 60; // Alaska Standard Time
    if (StrEqual(tz, "AKDT", false)) return -8 * 60; // Alaska Daylight Time
    if (StrEqual(tz, "HST", false)) return -10 * 60; // Hawaii-Aleutian Standard Time
    if (StrEqual(tz, "HDT", false)) return -9 * 60;  // Hawaii-Aleutian Daylight Time
    if (StrEqual(tz, "SST", false)) return -11 * 60; // Samoa Standard Time
    if (StrEqual(tz, "SDT", false)) return -10 * 60; // Samoa Daylight Time
    if (StrEqual(tz, "NZST", false)) return 12 * 60; // New Zealand Standard Time
    if (StrEqual(tz, "NZDT", false)) return 13 * 60; // New Zealand Daylight Time
    return 0; // Default to UTC if invalid
}

// Initializes the plugin and creates CVars from the config file
public void OnPluginStart()
{
    g_hCvarHour = CreateConVar("timed_message_hour", "2", "Set the hour (1-12) for the timed message", FCVAR_NOTIFY | FCVAR_ARCHIVE);
    g_hCvarMinute = CreateConVar("timed_message_minute", "30", "Set the minute (0-59) for the timed message", FCVAR_NOTIFY | FCVAR_ARCHIVE);
    g_hCvarAMPM = CreateConVar("timed_message_setting", "PM", "Set the time setting (AM or PM)", FCVAR_NOTIFY | FCVAR_ARCHIVE);
    g_hCvarMessage = CreateConVar("timed_message_text", "This is a timed message!", "Set the message to display at the specified time", FCVAR_NOTIFY | FCVAR_ARCHIVE);
    g_hCvarTimezone = CreateConVar("timed_message_timezone", "UTC", "Set the timezone (e.g., UTC, EST, PST)", FCVAR_NOTIFY | FCVAR_ARCHIVE);

    AutoExecConfig(true, "timed_message");

    CreateTimer(1.0, Timer_CheckTime, _, TIMER_REPEAT);
}

// Time checking function with timezone adjustment
public Action Timer_CheckTime(Handle timer)
{
    char formattedTime[16];
    int currentTime = GetTime();

    // Retrieve timezone offset
    char cvarTimezone[8];
    g_hCvarTimezone.GetString(cvarTimezone, sizeof(cvarTimezone));
    int timezoneOffset = GetTimezoneOffset(cvarTimezone);

    // Adjust time for the selected timezone
    FormatTime(formattedTime, sizeof(formattedTime), "%I:%M %p", currentTime + timezoneOffset);

    // Retrieve the configured scheduled time
    char cvarAMPM[4];
    g_hCvarAMPM.GetString(cvarAMPM, sizeof(cvarAMPM));
    
    int scheduledHour = GetConVarInt(g_hCvarHour);
    int scheduledMinute = GetConVarInt(g_hCvarMinute);

    PrintToServer("Current Time (%s): %s | Scheduled Time: %02d:%02d %s", cvarTimezone, formattedTime, scheduledHour, scheduledMinute, cvarAMPM);

    // Ensure the message is only sent once per occurrence
    if (lastSentHour == scheduledHour && lastSentMinute == scheduledMinute)
    {
        return Plugin_Continue;
    }

    // Check if the current time matches the scheduled time
    char scheduledTime[16];
    Format(scheduledTime, sizeof(scheduledTime), "%02d:%02d %s", scheduledHour, scheduledMinute, cvarAMPM);

    if (StrEqual(formattedTime, scheduledTime))
    {
        char message[256];
        g_hCvarMessage.GetString(message, sizeof(message));

        PrintToChatAll("%s", message);
        PrintToServer("Message sent: %s", message);

        lastSentHour = scheduledHour;
        lastSentMinute = scheduledMinute;
    }

    return Plugin_Continue;
}
