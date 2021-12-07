#include <sourcemod>

#pragma newdecls  required
#pragma semicolon 1

#define AVAILABLE_TOKENS            "\nAvailable tokens:\n" ... TOKEN_UID_DESCRIPTION ... "\n" ... TOKEN_NAME_DESCRIPTION ... "\n" ... TOKEN_STEAM_DESCRIPTION ... "\n" ... TOKEN_IPADDR_DESCRIPTION

#define TOKEN_UID                   "{UID}"
#define TOKEN_NAME                  "{NAME}"
#define TOKEN_STEAM                 "{STEAM}"
#define TOKEN_IPADDR                "{IPADDR}"

#define TOKEN_UID_DESCRIPTION       TOKEN_UID ... " - Administrator User ID"
#define TOKEN_NAME_DESCRIPTION      TOKEN_NAME ... " - Administrator Username"
#define TOKEN_STEAM_DESCRIPTION     TOKEN_STEAM ... " - Administrator SteamID v2, if available."
#define TOKEN_IPADDR_DESCRIPTION    TOKEN_IPADDR ... " - Administrator IP Address"

#define CALL_CONVARHOOK(%0,%1)  %0(%1, NULL_STRING, NULL_STRING)

#define PLUGIN_VERSION              "1.0"

float   g_flFirstActionTime[MAXPLAYERS+1];
int     g_iActionsCounter[MAXPLAYERS+1];

// Config
float   g_flMaxExceededTime;
int     g_iImmunableAdmins;
char    g_szCommand[256];
int     g_iMaxActions;
bool    g_bEnabled;

ConVar  g_hMaxExceededTime;
ConVar  g_hImmunableAdmins;
ConVar  g_hMaxActions;
ConVar  g_hCommand;
ConVar  g_hEnabled;

// myinfo
public Plugin myinfo = {
    description = "Punish your administrators for excessive activity!",
    version     = PLUGIN_VERSION,
    author      = "CrazyHackGUT aka Kruzya",
    name        = "[ANY] Admin Actions Punisher",
    url         = "https://kruzefag.ru/"
};

public void OnPluginStart() {
    g_hMaxExceededTime  = CreateConVar("sm_adminpunish_maxtime",    "30.0",                                                                                 "The time after which the plug-in resets the number of actions of the admin.",  _,  true,   0.0);
    g_hImmunableAdmins  = CreateConVar("sm_adminpunish_immune",     "z",                                                                                    "Flags of the administrators who should be ignored by the plugin. Leave empty, if you don't need immunable admins");
    g_hMaxActions       = CreateConVar("sm_adminpunish_maxactions", "10",                                                                                   "Number of actions after which the administrator will be punished.",            _,  true,   0.0);
    g_hCommand          = CreateConVar("sm_adminpunish_command",    "sm_kick #{UID} You exceeded the permissible number of administrator actions.",         "The command to execute after exceeding the limit.\n" ... AVAILABLE_TOKENS);
    g_hEnabled          = CreateConVar("sm_adminpunish_enabled",    "1",                                                                                    "Enables/disables plugin",                                                      _,  true,   0.0,    true,   1.0);

    g_hMaxExceededTime.AddChangeHook(OnConVarChanged);
    g_hImmunableAdmins.AddChangeHook(OnConVarChanged);
    g_hMaxActions.AddChangeHook(OnConVarChanged);
    g_hCommand.AddChangeHook(OnConVarChanged);
    g_hEnabled.AddChangeHook(OnConVarChanged);

    AutoExecConfig(true, "adminpunish");

    CreateConVar("sm_adminpunish_version", PLUGIN_VERSION, "Admin Actions Punisher Version", FCVAR_NOTIFY);
}

public void OnConfigsExecuted() {
    CALL_CONVARHOOK(OnConVarChanged,    g_hMaxExceededTime);
    CALL_CONVARHOOK(OnConVarChanged,    g_hImmunableAdmins);
    CALL_CONVARHOOK(OnConVarChanged,    g_hMaxActions);
    CALL_CONVARHOOK(OnConVarChanged,    g_hEnabled);
    CALL_CONVARHOOK(OnConVarChanged,    g_hCommand);
}

public void OnConVarChanged(ConVar hCvar, const char[] szOV, const char[] szNV) {
    if (hCvar == g_hMaxExceededTime)
        g_flMaxExceededTime = g_hMaxExceededTime.FloatValue;
    else if (hCvar == g_hMaxActions)
        g_iMaxActions       = g_hMaxActions.IntValue;
    else if (hCvar == g_hEnabled)
        g_bEnabled          = g_hEnabled.BoolValue;
    else if (hCvar == g_hCommand)
        g_hCommand.GetString(g_szCommand, sizeof(g_szCommand));
    else {
        char szFlags[32];
        g_hImmunableAdmins.GetString(szFlags, sizeof(szFlags));
        TrimString(szFlags);

        g_iImmunableAdmins = ReadFlagString(szFlags);
    }
}

public Action OnLogAction(Handle hSrc, Identity eIdentity, int iClient, int iTarget, const char[] szMsg) {
    if (g_bEnabled == false || eIdentity != Identity_Plugin || GetUserAdmin(iClient) == INVALID_ADMIN_ID || GetUserFlagBits(iClient) & g_iImmunableAdmins) {
        return;
    }

    float flCurrentTime = GetEngineTime();
    if (g_flFirstActionTime[iClient] == -1.0 || g_flFirstActionTime[iClient]+g_flMaxExceededTime < flCurrentTime) {
        g_flFirstActionTime[iClient] = flCurrentTime;
        g_iActionsCounter[iClient] = 1;
        return;
    }

    g_iActionsCounter[iClient]++;
    if (g_iActionsCounter[iClient] > g_iMaxActions) {
        // oh...
        char szCommand[256];
        strcopy(szCommand, sizeof(szCommand), g_szCommand);

        // start...
        char szBuffer[32];
        if (StrContains(szCommand, TOKEN_UID, true) != -1) {
            IntToString(GetClientUserId(iClient), szBuffer, sizeof(szBuffer));
            ReplaceString(szCommand, sizeof(szCommand), TOKEN_UID, szBuffer, true);
        }

        if (StrContains(szCommand, TOKEN_NAME, true) != -1) {
            GetClientName(iClient, szBuffer, sizeof(szBuffer));
            ReplaceString(szCommand, sizeof(szCommand), TOKEN_NAME, szBuffer, true);
        }

        if (StrContains(szCommand, TOKEN_STEAM, true) != -1) {
            if (!GetClientAuthId(iClient, AuthId_Steam2, szBuffer, sizeof(szBuffer)))
                GetClientAuthId(iClient, AuthId_Engine, szBuffer, sizeof(szBuffer));

            ReplaceString(szCommand, sizeof(szCommand), TOKEN_STEAM, szBuffer, true);
        }

        if (StrContains(szCommand, TOKEN_IPADDR, true) != -1) {
            GetClientIP(iClient, szBuffer, sizeof(szBuffer));
            ReplaceString(szCommand, sizeof(szCommand), TOKEN_IPADDR, szBuffer, true);
        }

        // execute.
        ServerCommand("%s", szCommand);

        // reset data (dummy buffer).
        OnClientConnect(iClient, szBuffer, sizeof(szBuffer));
    }
}

public bool OnClientConnect(int iClient, char[] szMsg, int iMaxLength) {
    g_flFirstActionTime[iClient] = -1.0;
    g_iActionsCounter[iClient] = 0;

    return true;
}