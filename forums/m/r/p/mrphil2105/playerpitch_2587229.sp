#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.1"
#define SM_PREFIX "\x05[SM]\x01 "
#define MIN_PITCH 30
#define MAX_PITCH 250
#define DEFAULT_PITCH 100

Handle g_hLow;  int g_iLow;
Handle g_hHigh; int g_iHigh;

int g_iValueStates[MAXPLAYERS + 1] = { DEFAULT_PITCH, ... };

public Plugin myinfo =
{
    name = "Player Pitch",
    author = "mrphil2105",
    description = "Changes the voice command pitch of players.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2587229"
};

public void OnPluginStart()
{
    LoadTranslations("common.phrases.txt");

    CreateConVar("sm_playerpitch_version", PLUGIN_VERSION, "Player Pitch Version - Do not change this!",
        FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
    g_hLow = CreateConVar("sm_playerpitch_low", "50", "The value for the sm_lowpitch command.",
        FCVAR_NOTIFY, true, MIN_PITCH * 1.0, true, DEFAULT_PITCH * 1.0); // We multiply by 1.0 to convert to a float.
    g_hHigh = CreateConVar("sm_playerpitch_high", "200", "The value for the sm_highpitch command.",
        FCVAR_NOTIFY, true, DEFAULT_PITCH * 1.0, true, MAX_PITCH * 1.0); // We multiply by 1.0 to convert to a float.

    HookConVarChange(g_hLow, ConVarChange);     g_iLow = GetConVarInt(g_hLow);
    HookConVarChange(g_hHigh, ConVarChange);    g_iHigh = GetConVarInt(g_hHigh);

    AutoExecConfig(true);

    RegAdminCmd("sm_lowpitch", Command_LowPitch, ADMFLAG_GENERIC, "Set voice commands to a low pitch.");
    RegAdminCmd("sm_highpitch", Command_HighPitch, ADMFLAG_GENERIC, "Set voice commands to a high pitch.");
    RegAdminCmd("sm_pitch", Command_Pitch, ADMFLAG_ROOT, "Set voice commands to a custom pitch.");
    RegAdminCmd("sm_resetpitch", Command_ResetPitch, ADMFLAG_GENERIC, "Reset voice commands to the normal pitch.");

    AddNormalSoundHook(NormalSoundHook);
}

public void OnClientDisconnect(int iClient)
{
    g_iValueStates[iClient] = DEFAULT_PITCH;
}

public void ConVarChange(Handle hCvar, const char[] sOldValue, const char[] sNewValue)
{
    if (hCvar == g_hLow)
        g_iLow = StringToInt(sNewValue);
    else if (hCvar == g_hHigh)
        g_iHigh = StringToInt(sNewValue);
}

public Action Command_LowPitch(int iClient, int iArgs)
{
    if (!IsValidClient(iClient))
        return Plugin_Handled;

    if (CheckCommandAccess(iClient, "sm_playerpitch_target", ADMFLAG_GENERIC))
    {
        if (iArgs < 1)
        {
            ReplyToCommand(iClient, "%sUsage: sm_lowpitch <player>", SM_PREFIX);
            return Plugin_Handled;
        }

        char sArg1[MAX_NAME_LENGTH];
        GetCmdArg(1, sArg1, sizeof(sArg1));

        PerformPitchMultiple(iClient, sArg1, g_iLow);
        return Plugin_Handled;
    }

    PerformPitch(iClient, g_iLow);
    return Plugin_Handled;
}

public Action Command_HighPitch(int iClient, int iArgs)
{
    if (!IsValidClient(iClient))
        return Plugin_Handled;

    if (CheckCommandAccess(iClient, "sm_playerpitch_target", ADMFLAG_GENERIC))
    {
        if (iArgs < 1)
        {
            ReplyToCommand(iClient, "%sUsage: sm_highpitch <player>", SM_PREFIX);
            return Plugin_Handled;
        }

        char sArg1[MAX_NAME_LENGTH];
        GetCmdArg(1, sArg1, sizeof(sArg1));

        PerformPitchMultiple(iClient, sArg1, g_iHigh);
        return Plugin_Handled;
    }

    PerformPitch(iClient, g_iHigh);
    return Plugin_Handled;
}

public Action Command_Pitch(int iClient, int iArgs)
{
    if (!IsValidClient(iClient))
        return Plugin_Handled;

    if (CheckCommandAccess(iClient, "sm_playerpitch_target", ADMFLAG_GENERIC))
    {
        if (iArgs < 2)
        {
            ReplyToCommand(iClient, "%sUsage: sm_pitch <player> <%i-%i>", SM_PREFIX, MIN_PITCH, MAX_PITCH);
            return Plugin_Handled;
        }

        char sArg1[MAX_NAME_LENGTH];
        GetCmdArg(1, sArg1, sizeof(sArg1));

        char sArg2[4];
        GetCmdArg(2, sArg2, sizeof(sArg2));
        int iValue = StringToInt(sArg2);

        PerformPitchMultiple(iClient, sArg1, iValue);
        return Plugin_Handled;
    }

    if (iArgs < 1)
    {
        ReplyToCommand(iClient, "%sUsage: sm_pitch <%i-%i>", SM_PREFIX, MIN_PITCH, MAX_PITCH);
        return Plugin_Handled;
    }

    char sArg1[4];
    GetCmdArg(1, sArg1, sizeof(sArg1));
    int iValue = StringToInt(sArg1);

    PerformPitch(iClient, iValue);
    return Plugin_Handled;
}

public Action Command_ResetPitch(int iClient, int iArgs)
{
    if (!IsValidClient(iClient))
        return Plugin_Handled;

    if (CheckCommandAccess(iClient, "sm_playerpitch_target", ADMFLAG_GENERIC))
    {
        if (iArgs < 1)
        {
            ReplyToCommand(iClient, "%sUsage: sm_resetpitch <player>", SM_PREFIX);
            return Plugin_Handled;
        }

        char sArg1[MAX_NAME_LENGTH];
        GetCmdArg(1, sArg1, sizeof(sArg1));

        PerformPitchMultiple(iClient, sArg1, DEFAULT_PITCH);
        return Plugin_Handled;
    }

    PerformPitch(iClient, DEFAULT_PITCH);
    return Plugin_Handled;
}

static bool CheckPitch(int iClient, int iValue)
{
    if (iValue < MIN_PITCH || iValue > MAX_PITCH)
    {
        ReplyToCommand(iClient, "%sPitch must be between %i and %i", SM_PREFIX, MIN_PITCH, MAX_PITCH);
        return false;
    }

    return true;
}

static void PerformPitch(int iClient, int iValue)
{
    if (!CheckPitch(iClient, iValue))
        return;

    g_iValueStates[iClient] = iValue;
    PitchReply(iClient, iValue);
}

static void PerformPitchMultiple(int iClient, const char[] sPattern, int iValue)
{
    if (!CheckPitch(iClient, iValue))
        return;

    char sTargetName[MAX_TARGET_LENGTH];
    int iTargets[MAXPLAYERS + 1];
    int iTargetCount;

    if ((iTargetCount = GetTargets(sPattern, iClient, iTargets, sTargetName)) <= 0)
        return;

    for (int i = 0; i < iTargetCount; i++)
    {
        int iTarget = iTargets[i];
        g_iValueStates[iTarget] = iValue;
    }

    PitchReply(iClient, iValue, sTargetName);
}

static void PitchReply(int iClient, int iValue, const char[] sTargetName = "")
{
    if (iValue != DEFAULT_PITCH)
    {
        char sValue[5];

        if (iValue == g_iLow)
            sValue = "low";
        else if (iValue == g_iHigh)
            sValue = "high";
        else
            IntToString(iValue, sValue, sizeof(sValue));

        if (sTargetName[0])
            ShowActivity2(iClient, SM_PREFIX, "%s's pitch has been set to %s", sTargetName, sValue);
        else
            ReplyToCommand(iClient, "%sYour pitch has been set to %s", SM_PREFIX, sValue);
    }
    else
    {
        if (sTargetName[0])
            ShowActivity2(iClient, SM_PREFIX, "%s's pitch has been reset", sTargetName);
        else
            ReplyToCommand(iClient, "%sYour pitch has been reset", SM_PREFIX);
    }
}

public Action NormalSoundHook(int iClients[64], int &iClientCount,
    char sSoundPath[PLATFORM_MAX_PATH], int &iEntity, int &iChannel,
    float &fVolume, int &iLevel, int &iPitch, int &iFlags)
{
    if (iChannel == SNDCHAN_VOICE && IsValidClient(iEntity) &&
        g_iValueStates[iEntity] != DEFAULT_PITCH)
    {
        iPitch = g_iValueStates[iEntity];
        iFlags |= SND_CHANGEPITCH;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

// Imported from essentials.inc.

stock bool IsValidClient(int iClient)
{
    if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) ||
        IsClientSourceTV(iClient) || IsClientReplay(iClient))
    {
        return false;
    }

    return true;
}

stock int GetTargets(const char[] sPattern, int iClient, int iTargets[MAXPLAYERS + 1],
    char sTargetName[MAX_TARGET_LENGTH], bool &bTargetNameIsML = false)
{
    int iTargetCount;

    if ((iTargetCount = ProcessTargetString(sPattern, iClient, iTargets, sizeof(iTargets),
        0, sTargetName, sizeof(sTargetName), bTargetNameIsML)) <= 0)
    {
        ReplyToTargetError(iClient, iTargetCount);
    }

    return iTargetCount;
}
