#include <sourcemod> // OnPluginStart(), ..

#define CHECK_SV_SKYNAME_TOO /** Delete this definition, if you are using a Sky Changer plug-in ... */

/**
 * The File's Version, Must Be A String Value
 */
#define CSGOACCC_VERSION "3.1"

//
// Don't Make The Counter-Strike Source Mod's Extension Required For This File
//

#if !defined CS_TEAM_T
    #define CS_TEAM_T   2 // Terrorist
#endif

#if !defined CS_TEAM_CT
    #define CS_TEAM_CT  3 // Counter-Terrorist
#endif

public Plugin myinfo =
{
    name        =   "CS:GO AC: Cheating ConVars"                            , \
    author      =   "Hattrick HKS (claudiuhks)"                             , \
    description =   "Bans Players For Changing Illegal ConVars"             , \
    version     =   CSGOACCC_VERSION                                        , \
    url         =   "https://forums.alliedmods.net/showthread.php?t=324601" ,
};

/**
 * Seconds Delay Between The Original OnClientPutInServer Call And The Moment Of Beginning To Check The Client's ConVars,
 * Must Be A Floating Point Number
 */
#define ONCLIENTPUTINSERVER_DELAY   GetRandomFloat(8.0, 16.0) // Maybe Someone Would Like To Change This

/**
 * Seconds Delay Between Every Global Replicated "sv_skyname" ConVar Checking Issued On Every Player Playing On The Actual Game Server,
 * Must Be A Floating Point Number
 */
#if defined CHECK_SV_SKYNAME_TOO
#define SV_SKYNAME_INTERVAL         30.0 // Maybe Someone Would Like To Change This
#endif

//
// Global Variables Below
//

int g_nTotalEnabledConVars      = 0; // How Many ConVars Are Enabled For Checking

Handle g_hConVarsNames          = INVALID_HANDLE; // Enabled ConVars' Names
Handle g_hConVarsValues         = INVALID_HANDLE; // Enabled ConVars' String Values

Handle g_hConVarPluginVersion   = INVALID_HANDLE; // ConVar For The Plug-in's Version
Handle g_hConVarBanMinutes      = INVALID_HANDLE; // ConVar To Allow The Game Server's Owners To Decide How Long The Ban Will Be

int g_nConVarIndex[MAXPLAYERS]  = { 0, ... }; // Which ConVar Is Assigned To The Player, To Check Its Value

bool g_bLateLoaded              = false; // Whether The Plug-in Has Been Loaded During Game Play Or Not
bool g_bMapEnded                = false; // Whether The Map Has Ended And A New One Begins Or Not

//
// Public Functions Below
//

public APLRes AskPluginLoad2(Handle hSelf, bool bLateLoaded, char[] szError, int nErrorMaxLen) // Called Before OnPluginStart
{
    g_bLateLoaded = bLateLoaded; // Loaded During Game Play Or Not

    if (Engine_CSGO != GetEngineVersion()) // Not Installed On A CS:GO Game Server
    {
        FormatEx(szError, nErrorMaxLen, "This Plug-in Only Works On Counter-Strike: Global Offensive");

        return APLRes_Failure; // Stop The Plug-in Load Process
    }

    return APLRes_Success; // Continue The Plug-in Load Process
}

public void OnPluginStart()
{
    // FCVAR_NOTIFY | FCVAR_SPONLY https://github.com/alliedmodders/sourcemod/blob/master/core/sourcemm_api.cpp#L66
    //
    g_hConVarPluginVersion =    CreateConVar(   "csgo_ac_cheating_convars"                      , \
                                                CSGOACCC_VERSION                                , \
                                                "CS:GO AC: Cheating ConVars Plug-in's Version"  , \
                                                FCVAR_SPONLY | FCVAR_NOTIFY                     , \
                                                true    /* Has Min Limit */                     , \
                                                1.0                                             , \
                                                false   /* No Max Limit */                      , \
                                                0.0                                             );

    g_hConVarBanMinutes =       CreateConVar(   "csgo_ac_cheating_convars_ban_time"                                     , \
                                                "0"                                                                     , \
                                                "Minutes To Ban The Hacker, 0 Means Permanent, 1051000 Means Two Years" , \
                                                FCVAR_NONE                                                              , \
                                                true        /* Has Min Limit */                                         , \
                                                0.0                                                                     , \
                                                true        /* Has Max Limit */                                         , \
                                                1051000.0   /* 1.051e+6 Two Years */                                    );

    AutoExecConfig(true,        "csgo_ac_cheating_convars");

    g_hConVarsNames =           CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
    g_hConVarsValues =          CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));

    if (g_bLateLoaded) // If Loaded During Game Play
    {
        OnMapStart();
        OnConfigsExecuted(); // Make Sure To Update The File Version's ConVar

        for (int nClient = 1; nClient <= MaxClients; nClient++) // Loop Through All Players
        {
            if (goodPlayer(nClient)) // The Player Seems Connected To The Game Server And Validated As Well
            {
                OnClientPutInServer(nClient); // Call OnClientPutInServer For Every Connected Player
            }
        }
    }
}

public void OnMapEnd()
{
    g_bMapEnded = true; // The Map Has Ended And A New One Begins, Stop Checking The Players' ConVars
}

public void OnConfigsExecuted()
{
    if (g_hConVarPluginVersion != INVALID_HANDLE)
    {
        SetConVarString(g_hConVarPluginVersion, CSGOACCC_VERSION); // Update The Version's ConVar
    }
}

public void OnMapStart()
{
    g_bMapEnded = false; // The New Map Has Started, Let's Check The Players' ConVars Again, From The Scratch

    ClearArray(g_hConVarsNames);  // Resets All Enabled ConVars
    ClearArray(g_hConVarsValues); // Resets All Enabled ConVars

    g_nTotalEnabledConVars = 0;   // Resets All Enabled ConVars

    char szFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szFile, sizeof(szFile), "configs/cheating_convars_enabled.ini");

    if (!FileExists(szFile))
    {
        LogError("File %s Is Missing", szFile);
    }

    else
    {
        Handle hFile = OpenFile(szFile, "r");

        if (hFile == INVALID_HANDLE)
        {
            LogError("File %s Exists But Can't Be Opened For Reading", szFile);
        }

        else
        {
            char szString[PLATFORM_MAX_PATH], szConVarName[PLATFORM_MAX_PATH], szConVarValue[PLATFORM_MAX_PATH];

            int nLineIndex = 0;

            while (!IsEndOfFile(hFile)) // While The File Hasn't Ended Yet
            {
                if (ReadFileLine(hFile, szString, sizeof(szString)))
                {
                    nLineIndex++; // Every Line We Read

                    TrimString(szString); // Trims The White Spaces

                    if (szString[0] != '"'          && \
                        szString[0] != '_'          && \
                        !IsCharNumeric(szString[0]) && \
                        !IsCharAlpha(szString[0])   ) // The String Is A Comment Or An Empty String, It Doesn't Start With ", _, a-z, A-Z or 0-9
                    {
                        continue; // Keep Going Further
                    }

                    int nBSRes = BreakString(szString, szConVarName, sizeof(szConVarName)); // Retrieve The Enabled ConVar's Name

                    if (nBSRes == -1) // After Reading The ConVar's Name We Found Out There Is No Value Written After Its Name
                    {
                        LogError("The Enabled ConVar \"%s\" Has No Original Value Defined Inside %s At Line %d",    szConVarName    , \
                                                                                                                    szFile          , \
                                                                                                                    nLineIndex      );

                        continue; // Keep Going Further
                    }

                    BreakString(szString[nBSRes], szConVarValue, sizeof(szConVarValue)); // Retrieve The Enabled ConVar's String Value

                    //
                    // Valid Enabled ConVars
                    //

                    g_nTotalEnabledConVars++;

                    PushArrayString(g_hConVarsNames,    szConVarName);
                    PushArrayString(g_hConVarsValues,   szConVarValue);

#if 1 // Maybe Someone Wants To Disable This Log, 0 To Disable

                    LogMessage("Added ConVar \"%s\" With Value \"%s\"", szConVarName, szConVarValue);

#endif
                }
            }

            LogMessage("Successfully Added %d Enabled ConVars For Checking", g_nTotalEnabledConVars);

            CloseHandle(hFile); // Frees The Opened File
        }
    }

#if defined CHECK_SV_SKYNAME_TOO
    CreateTimer(SV_SKYNAME_INTERVAL, Timer_SkyName_Global_Check, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
#endif
}

public void Res_FinishedCheckingAConVar(    QueryCookie         xCookie         , \
                                            int                 nClient         , \
                                            ConVarQueryResult   xRes            , \
                                            const char[]        szConVarName    , \
                                            const char[]        szConVarValue   , \
                                            any                 hUserDataPack   )
{
    static char szRequiredConVarValue[PLATFORM_MAX_PATH]; // Enough Room For A Big ConVar Value

    if (xRes == ConVarQuery_Okay) // The Query Succeeded, All Good
    {
        ResetPack(hUserDataPack); // Reset The Custom User Data Pack To Read It From The Scratch

        ReadPackString(hUserDataPack, szRequiredConVarValue, sizeof(szRequiredConVarValue)); // Read The Required Original ConVar's Value

        CloseHandle(hUserDataPack); // Avoid Memory Leaks Freeing What We Have To Free

#if 0 // Debugging Purposes Only

        if (goodPlayer(nClient))
        {
            LogMessage("@ ConVar \"%s\" Required Value \"%s\" Player \"%N\" [#%d] Has Value \"%s\"",    szConVarName                , \
                                                                                                        szRequiredConVarValue       , \
                                                                                                        nClient                     , \
                                                                                                        GetClientUserId(nClient)    , \
                                                                                                        szConVarValue               );
        }

#endif

        if (!StrEqual(szConVarValue, szRequiredConVarValue)) // The Client's ConVar's Value Does Not Match With The Original Required One
        {
            if (StringToFloat(szConVarValue) != StringToFloat(szRequiredConVarValue)) // The Client's ConVar's Value Does REALLY Not Match With The Original Required One
            {
                if (goodPlayer(nClient)) // The Player Is In Game And Validated As Well
                {
                    static Handle hCheatsConVar = INVALID_HANDLE; // Only Find "sv_cheats" ConVar's Handle Once

                    if (hCheatsConVar == INVALID_HANDLE)
                    {
                        hCheatsConVar = FindConVar("sv_cheats"); // Assigning "sv_cheats" ConVar's Handle
                    }

                    if (hCheatsConVar != INVALID_HANDLE) // hCheatsConVar Should Never Be Invalid
                    {
                        if (!GetConVarBool(hCheatsConVar)) // Make Sure "sv_cheats" Is Actually Disabled Not To Ban The Player By Mistake
                        {
                            ServerCommand("sm_ban #%d %d \"%s\";",  GetClientUserId(nClient)            , \
                                                                    GetConVarInt(g_hConVarBanMinutes)   , \
                                                                    szConVarName                        ); // Issue A Regular Ban
                        }
                    }
                }
            }

            else // Client's ConVar's Float Value Matched The Original Required One, All Good, Check Further, ..
            {
                QueryClientCheatingConVar(nClient); // Keep Checking
            }
        }

        else // Client's ConVar's String Value Matched The Original Required One, All Good, Check Further, ..
        {
            QueryClientCheatingConVar(nClient); // Keep Checking
        }
    }

    else // Maybe A ConVar Is Not Valid Anymore Because Of A Game Update Or Something, So Just Continue Checking What We Still Have To Check, ..
    {
        CloseHandle(hUserDataPack); // Avoid Memory Leaks Freeing What We Have To Free

        QueryClientCheatingConVar(nClient); // Keep Checking
    }
}

#if defined CHECK_SV_SKYNAME_TOO
public void Res_FinishedCheckingSkyName(    QueryCookie         xCookie         , \
                                            int                 nClient         , \
                                            ConVarQueryResult   xRes            , \
                                            const char[]        szConVarName    , \
                                            const char[]        szConVarValue   )
{
    static char szRequiredConVarValue[PLATFORM_MAX_PATH]; // Enough Room For A Big ConVar Value

    static Handle hSkyNameConVar = INVALID_HANDLE; // Pointer To The "sv_skyname" ConVar

    if (hSkyNameConVar == INVALID_HANDLE)
    {
        hSkyNameConVar = FindConVar(szConVarName); // Find The "sv_skyname" ConVar Only Once
    }

    if (xRes == ConVarQuery_Okay) // The Query Succeeded, All Good
    {
        if (hSkyNameConVar != INVALID_HANDLE) // "sv_skyname" ConVar Exists, Good
        {
            GetConVarString(hSkyNameConVar, szRequiredConVarValue, sizeof(szRequiredConVarValue)); // Retrieve The Game Server's "sv_skyname" ConVar's String Value

#if 0 // Debugging Purposes Only

        if (goodPlayer(nClient))
        {
            LogMessage("@ ConVar \"%s\" Required Value \"%s\" Player \"%N\" [#%d] Has Value \"%s\"",    szConVarName                , \
                                                                                                        szRequiredConVarValue       , \
                                                                                                        nClient                     , \
                                                                                                        GetClientUserId(nClient)    , \
                                                                                                        szConVarValue               );
        }

#endif

            if (!StrEqual(szConVarValue, szRequiredConVarValue, false)) // The Client's ConVar's Value Does Not Match With The Original Required One
            {
                if (goodPlayer(nClient)) // The Player Is In Game And Validated As Well
                {
                    static Handle hCheatsConVar = INVALID_HANDLE; // Only Find "sv_cheats" ConVar's Handle Once

                    if (hCheatsConVar == INVALID_HANDLE)
                    {
                        hCheatsConVar = FindConVar("sv_cheats"); // Assigning "sv_cheats" ConVar's Handle
                    }

                    if (hCheatsConVar != INVALID_HANDLE) // hCheatsConVar Should Never Be Invalid
                    {
                        if (!GetConVarBool(hCheatsConVar)) // Make Sure "sv_cheats" Is Actually Disabled Not To Ban The Player By Mistake
                        {
                            ServerCommand("sm_ban #%d %d \"%s\";",  GetClientUserId(nClient)            , \
                                                                    GetConVarInt(g_hConVarBanMinutes)   , \
                                                                    szConVarName                        ); // Issue A Regular Ban
                        }
                    }
                }
            }
        }
    }
}
#endif

public void OnClientPutInServer(int nClient) // IsClientInGame Will Return True At This Point
{
    g_nConVarIndex[nClient] = 0; // Reset The ConVars' Index For This Player To Start Checking From The Scratch

    if (!g_bMapEnded) // If The Map Hasn't Ended
    {
        if (g_nTotalEnabledConVars > 0) // Only If There Are Enabled ConVars To Check
        {
            if (goodPlayer(nClient, false /* Already In Game, No Need To Call IsClientInGame */)) // The Client Is Not A Fake One
            {
                CreateTimer(    ONCLIENTPUTINSERVER_DELAY   , \
                                Timer_PutInServer_Delayed   , \
                                GetClientUserId(nClient)    , \
                                TIMER_FLAG_NO_MAPCHANGE     ); // Delay The ConVars Checking A Few Seconds
            }
        }
    }
}

public Action Timer_PutInServer_Delayed(Handle hTimer, any nClientUserId) // Delayed OnClientPutInServer
{
    int nClient = GetClientOfUserId(nClientUserId); // Retrieve The Client's Index By The Client's User Index

    if (goodPlayer(nClient)) // Player OK, Unique
    {
        QueryClientCheatingConVar(nClient); // Start Checking The Player's ConVars
    }
}

#if defined CHECK_SV_SKYNAME_TOO
public Action Timer_SkyName_Global_Check(Handle hTimer) // Check All The Players Against "sv_skyname" ConVar
{
    for (int nPlayer = 1; nPlayer <= MaxClients; nPlayer++) // Loop Through All The Players
    {
        if (goodPlayer(nPlayer)) // The Player Is On The Game Server
        {
            int nTeam = GetClientTeam(nPlayer); // Retrieve The Player's Team

            if (nTeam == CS_TEAM_T || nTeam == CS_TEAM_CT) // The Player Is Actually Playing
            {
                QueryClientConVar(nPlayer, "sv_skyname", Res_FinishedCheckingSkyName); // Retrieve The Player's "sv_skyname" ConVar's String Value
            }
        }
    }
}
#endif

//
// Private Functions Below
//

void QueryClientCheatingConVar(int nClient) // Local Defined Function Intended To Check All The Client's ConVars
{
    static char szConVarName[PLATFORM_MAX_PATH], szConVarValue[PLATFORM_MAX_PATH]; // Only Create The Large Variables Once

    if (!g_bMapEnded) // Only If The Map Hasn't Ended Yet
    {
        if (g_nTotalEnabledConVars > 0) // Only If There Are Enabled ConVars To Check
        {
            if (g_nConVarIndex[nClient] < g_nTotalEnabledConVars) // Only If We Haven't Checked All The Enabled ConVars For This Player
            {
                if (goodPlayer(nClient)) // Only If The Client Is In Game And Validated
                {
                    Handle hUserDataPack = CreateDataPack();

                    if (hUserDataPack != INVALID_HANDLE) // It Should Never Be Invalid
                    {
                        GetArrayString(g_hConVarsNames,     g_nConVarIndex[nClient],    szConVarName,   sizeof(szConVarName));
                        GetArrayString(g_hConVarsValues,    g_nConVarIndex[nClient],    szConVarValue,  sizeof(szConVarValue));

                        WritePackString(hUserDataPack,      szConVarValue); // The Enabled ConVar's Original Value The Client's Must Match

                        QueryClientConVar(nClient, szConVarName, Res_FinishedCheckingAConVar, hUserDataPack);

                        g_nConVarIndex[nClient]++;
                    }
                }
            }
        }
    }
}

/**
 * Whether Or Not The Player Should Or Can Be Asked For ConVars
 */
bool goodPlayer(int nClient, bool bDoThePutInServerCheck = true /* Use False While Calling Inside OnClientPutInServer */)
{
    if (nClient < 1 || nClient > MaxClients) // Invalid Player, Not A Player
    {
        return false;
    }

    if (bDoThePutInServerCheck) // Not Called Inside OnClientPutInServer
    {
        if (!IsClientInGame(nClient)) // The Player Is Not Connected
        {
            return false;
        }
    }

    if (IsFakeClient        (nClient)   || \
        IsClientSourceTV    (nClient)   || \
        IsClientReplay      (nClient)   || \
        IsClientInKickQueue (nClient)   || \
        IsClientTimingOut   (nClient)   ) // The Player Is Useless
    {
        return false;
    }

    return true; // The Player Is Fine And Can Be Checked
}
