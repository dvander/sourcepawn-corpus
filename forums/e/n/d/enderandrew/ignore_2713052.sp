/*
    Ignore List
    By: Chdata


    This is what I plan to follow for the cvar determining how people see "You are being ignored"

    // Specifies how admin activity should be relayed to users.  Add up the values
    // below to get the functionality you want.
    // 1: Show admin activity to non-admins anonymously.
    // 2: If 1 is specified, admin names will be shown.
    // 4: Show admin activity to admins anonymously.
    // 8: If 4 is specified, admin names will be shown.
    // 16: Always show admin names to root users.
    // --
    // Default: 13 (1+4+8) 14 for players to see names
    sm_show_activity 13

    This is for who you can target with the ignore list

    // Sets how SourceMod should check immunity levels when administrators target 
    // each other.
    // 0: Ignore immunity levels (except for specific group immunities).
    // 1: Protect from admins of lower access only.
    // 2: Protect from admins of equal to or lower access.
    // 3: Same as 2, except admins with no immunity can affect each other.
    // --
    // Default: 1
    sm_immunity_mode 1
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <chat-processor>

#define PLUGIN_VERSION "0x04"

public Plugin myinfo =
{
    name = "Ignore list",
    author = "Chdata",
    description = "Provides a way to ignore communication.",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/tf2data/"
};

enum struct Targeting
{
    char arg[MAX_NAME_LENGTH];
    int buffer[MAXPLAYERS];
    int buffersize;
    char targetname[MAX_TARGET_LENGTH];
    bool tn_is_ml;
}

static Targeting Target;

enum struct IgnoreStatus
{
    bool Chat;
    bool Voice;
}

static IgnoreStatus IgnoreMatrix[MAXPLAYERS + 1][MAXPLAYERS + 1];

static bool g_bEnabled = false;

public void OnPluginStart()
{
    CreateConVar(
        "sm_ignorelist_version", PLUGIN_VERSION,
        "Ignore List Version",
        FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT
    );

    LoadTranslations("common.phrases");

    RegConsoleCmd("sm_ignore",   Command_Ignore,   "Usage: sm_ignore <#userid|name> | Set target's communications to be ignored.");
    RegConsoleCmd("sm_block",    Command_Ignore,   "Usage: sm_block <#userid|name> | Set target's communications to be ignored.");
    RegConsoleCmd("sm_unignore", Command_UnIgnore, "Usage: sm_unignore <#userid|name> | Unignore target.");
    RegConsoleCmd("sm_unblock",  Command_UnIgnore, "Usage: sm_unblock <#userid|name> | Unignore target.");

    RegConsoleCmd("sm_ignore_chat", Command_IgnoreChat, "Usage: sm_ignorec <#userid|name> | Set target's chat to be ignored.");
    RegConsoleCmd("sm_ignorechat", Command_IgnoreChat, "Usage: sm_ignorec <#userid|name> | Set target's chat to be ignored.");
    RegConsoleCmd("sm_ignore_c", Command_IgnoreChat, "Usage: sm_ignorec <#userid|name> | Set target's chat to be ignored.");
    RegConsoleCmd("sm_ignorec", Command_IgnoreChat, "Usage: sm_ignorec <#userid|name> | Set target's chat to be ignored.");

    RegConsoleCmd("sm_ignore_voice", Command_IgnoreVoice, "Usage: sm_ignorev <#userid|name> | Set target's voice to be ignored.");
    RegConsoleCmd("sm_ignorevoice", Command_IgnoreVoice, "Usage: sm_ignorev <#userid|name> | Set target's voice to be ignored.");
    RegConsoleCmd("sm_ignore_v", Command_IgnoreVoice, "Usage: sm_ignorev <#userid|name> | Set target's voice to be ignored.");
    RegConsoleCmd("sm_ignorev", Command_IgnoreVoice, "Usage: sm_ignorev <#userid|name> | Set target's voice to be ignored.");

    RegConsoleCmd("sm_unignore_chat", Command_UnIgnoreChat, "Usage: sm_unignorec <#userid|name> | Unignore target's chat.");
    RegConsoleCmd("sm_unignorechat", Command_UnIgnoreChat, "Usage: sm_unignorec <#userid|name> | Unignore target's chat.");
    RegConsoleCmd("sm_unignore_c", Command_UnIgnoreChat, "Usage: sm_unignorec <#userid|name> | Unignore target's chat.");
    RegConsoleCmd("sm_unignorec", Command_UnIgnoreChat, "Usage: sm_unignorec <#userid|name> | Unignore target's chat.");

    RegConsoleCmd("sm_unignore_voice", Command_UnIgnoreVoice, "Usage: sm_unignorev <#userid|name> | Unignore target's voice.");
    RegConsoleCmd("sm_unignorevoice", Command_UnIgnoreVoice, "Usage: sm_unignorev <#userid|name> | Unignore target's voice.");
    RegConsoleCmd("sm_unignore_v", Command_UnIgnoreVoice, "Usage: sm_unignorev <#userid|name> | Unignore target's voice.");
    RegConsoleCmd("sm_unignorev", Command_UnIgnoreVoice, "Usage: sm_unignorev <#userid|name> | Unignore target's voice.");
}

public void OnAllPluginsLoaded()                     //  Check for necessary plugin dependencies and shut down this plugin if not found.
{
    if (!LibraryExists("scp"))
    {
        SetFailState("Simple Chat Processor is not loaded. It is required for this plugin to work.");
    }
}

public void OnLibraryAdded(const char[] name)      //  Enable the plugin if the necessary library is added
{
    if (StrEqual(name, "scp"))
    {
        g_bEnabled = true;
    }
}

public void OnLibraryRemoved(const char[] name)    //  If a necessary plugin is removed, also shut this one down.
{
    if (StrEqual(name, "scp"))
    {
        g_bEnabled = false;
    }
}

public void OnClientDisconnect(int client)
{
    for (int i = 0; i <= MAXPLAYERS; i++)
    {
        IgnoreMatrix[client][i].Chat = false;
        IgnoreMatrix[client][i].Voice = false;
    }
}

public Action OnChatMessage(int &author, Handle recipients, char[] name, char[] message)
{
    if ((author < 0) || (author > MaxClients))
    {
        LogError("[Ignore list] Warning: author is out of bounds: %d", author);
        return Plugin_Continue;
    }
    int i = 0;
    int client;
    while (i < GetArraySize(recipients))
    {
        client = GetArrayCell(recipients, i);
        if ((client < 0) || (client > MaxClients))
        {
            LogError("[Ignore list] Warning: client is out of bounds: %d, Try updating SCP", client);
            i++;
            continue;
        }
        if (IgnoreMatrix[client][author].Chat)
        {
            RemoveFromArray(recipients, i);
        }
        else
        {
            i++;
        }
    }
    return Plugin_Changed;
}

public Action Command_Ignore(int iClient, int iArgs)
{
    if (!g_bEnabled || !iClient)
    {
        return Plugin_Handled;
    }

    if (iArgs < 1)
    {
        Menu_PlayerList(iClient);
        return Plugin_Handled;
    }
    
    ProcessIgnore(iClient, true, true, 1|2);

    return Plugin_Handled;
}

public Action Command_IgnoreChat(int iClient, int iArgs)
{
    if (!g_bEnabled || !iClient)
    {
        return Plugin_Handled;
    }

    if (iArgs < 1)
    {
        Menu_PlayerList(iClient);
        return Plugin_Handled;
    }
    
    ProcessIgnore(iClient, true, _, 1);

    return Plugin_Handled;
}

public Action Command_IgnoreVoice(int iClient, int iArgs)
{
    if (!g_bEnabled || !iClient)
    {
        return Plugin_Handled;
    }

    if (iArgs < 1)
    {
        Menu_PlayerList(iClient);
        return Plugin_Handled;
    }

    ProcessIgnore(iClient, _, true, 2);

    return Plugin_Handled;
}

public Action Command_UnIgnore(int iClient, int iArgs)
{
    if (!g_bEnabled || !iClient)
    {
        return Plugin_Handled;
    }

    if (iArgs < 1)
    {
        Menu_PlayerList(iClient);
        return Plugin_Handled;
    }
    
    ProcessIgnore(iClient, false, false, 1|2);

    return Plugin_Handled;
}

public Action Command_UnIgnoreChat(int iClient, int iArgs)
{
    if (!g_bEnabled || !iClient)
    {
        return Plugin_Handled;
    }

    if (iArgs < 1)
    {
        Menu_PlayerList(iClient);
        return Plugin_Handled;
    }
    
    ProcessIgnore(iClient, false, _, 1);

    return Plugin_Handled;
}

public Action Command_UnIgnoreVoice(int iClient, int iArgs)
{
    if (!g_bEnabled || !iClient)
    {
        return Plugin_Handled;
    }

    if (iArgs < 1)
    {
        Menu_PlayerList(iClient);
        return Plugin_Handled;
    }

    ProcessIgnore(iClient, _, false, 2);

    return Plugin_Handled;
}


int Menu_PlayerList(int iClient)
{
    Handle hPlayerListMenu = CreateMenu(MenuHandler_PlayerList);
    SetMenuTitle(hPlayerListMenu, "Choose a player");

    char s[12];
    char n[MAXLENGTH_NAME];

    int iTargets = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (i != iClient && IsClientInGame(i) && !IsFakeClient(i))
        {
            IntToString(GetClientUserId(i), s, sizeof(s)); 
            GetClientName(i, n, sizeof(n));
            AddMenuItem(hPlayerListMenu, s, n); // Userid - Username
            iTargets++;
        }
    }

    if (iTargets)
    {
        DisplayMenu(hPlayerListMenu, iClient, MENU_TIME_FOREVER);
    }
    else
    {
        ReplyToCommand(iClient, "[SM] No players found.");
        CloseHandle(hPlayerListMenu);
    }
}

public int MenuHandler_PlayerList(Handle hMenu, MenuAction iAction, int iClient, int iParam)
{
    switch (iAction)
    {
        case MenuAction_Select:
        {
            char szUserid[12]; // Grab the Userid of player to check ignore status
            GetMenuItem(hMenu, iParam, szUserid, sizeof(szUserid));
            int iTarget = GetClientOfUserId(StringToInt(szUserid));

            if (iTarget == 0)
            {
                PrintToChat(iClient, "[SM] Target has disconnected.");
            }
            else
            {
                Menu_IgnoreList(iClient, iTarget);
            }
            //CloseHandle(hMenu);
        }
        case MenuAction_End:
        {
            CloseHandle(hMenu);
        }
    }
}

int Menu_IgnoreList(int iClient, int iTarget)
{
    Handle hIgnoreListMenu = CreateMenu(MenuHandler_IgnoreList);
    SetMenuTitle(hIgnoreListMenu, "%N's ignore status (select to toggle)", iTarget);

    char s[12];
    char m[64];
    IntToString(GetClientUserId(iTarget), s, sizeof(s)); 

    Format(m, sizeof(m), "Chat (%s)", IgnoreMatrix[iClient][iTarget].Chat ? "OFF" : "ON");
    AddMenuItem(hIgnoreListMenu, s, m);

    Format(m, sizeof(m),  "Mic (%s)", IgnoreMatrix[iClient][iTarget].Voice ? "OFF" : "ON");
    AddMenuItem(hIgnoreListMenu, s, m);
    //AddMenuItem(hIgnoreListMenu, "2", "Voice Commands (visible)", );

    // SetMenuExitBackButton(hIgnoreListMenu, true);
    DisplayMenu(hIgnoreListMenu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_IgnoreList(Handle hMenu, MenuAction iAction, int iClient, int iParam)
{
    switch (iAction)
    {
        case MenuAction_Select:
        {
            char szUserid[12]; // Grab the Userid of player to check ignore status
            GetMenuItem(hMenu, iParam, szUserid, sizeof(szUserid));
            int iTarget = GetClientOfUserId(StringToInt(szUserid));

            if (iTarget == 0)
            {
                PrintToChat(iClient, "[SM] Target has disconnected.");
            }
            else
            {
                int which; // = 0;
                switch (iParam)
                {
                    case 0: which |= 1;
                    case 1: which |= 2;
                }
                ToggleIgnoreStatus(iClient, iTarget, !IgnoreMatrix[iClient][iTarget].Chat, !IgnoreMatrix[iClient][iTarget].Voice, which, false);
                Menu_IgnoreList(iClient, iTarget);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(hMenu);
        }
    }
}

/*
    client is the person ignoring someone
    the chat/voice bool says what we want to set their status to
    which says whether or not we're actually changing chat 1, voice 2, or both 3

*/
stock void ProcessIgnore(int client, const bool chat = false, const bool voice = false, const int which)
{
    GetCmdArg(1, Target.arg, MAX_NAME_LENGTH);

    bool bTargetAll = false;

    if (strcmp(Target.arg, "@all", false) == 0)
    {
        bTargetAll = true;
    }

    Target.buffersize = ProcessTargetString(Target.arg, client, Target.buffer, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_NO_IMMUNITY, Target.targetname, MAX_TARGET_LENGTH, Target.tn_is_ml);

    if (Target.buffersize <= 0)
    {
        ReplyToTargetError(client, Target.buffersize);
        return;
    }

    for (int i = 0; i < Target.buffersize; i++)
    {
        ToggleIgnoreStatus(client, Target.buffer[i], chat, voice, which, bTargetAll);      
    }

    if (bTargetAll)
    {
        char s[MAXLENGTH_MESSAGE];

        Format(s, sizeof(s), "[SM] All Players - Chat: %s | Voice: %s",
            !(which & 1) ? "Unchanged" : chat ? "OFF" : "ON",
            !(which & 2) ? "Unchanged" : voice ? "OFF" : "ON"
        );

        ReplyToCommand(client, s);
    }

    return;
}

/*
    @chat says what we're toggling the status to
    @voice says what we're toggling the status to
    @which says which of the above we actually are effecting
*/
void ToggleIgnoreStatus(const int client, const int target, const bool chat, const bool voice, const int which, const bool bTargetAll)
{
    if (GetUserFlagBits(target) & ADMFLAG_SLAY)
    {
        if (!bTargetAll)
        {
            ReplyToCommand(client, "[SM] You cannot ignore admins.");
        }

        return;
    }

    if (which & 1)
    {
        IgnoreMatrix[client][target].Chat = chat;
    }

    if (which & 2)
    {
        IgnoreMatrix[client][target].Voice = voice;

        if (IgnoreMatrix[client][target].Voice)
        {
            SetListenOverride(client, target, Listen_No);
        }
        else
        {
            SetListenOverride(client, target, Listen_Default);
        }
    }

    if (bTargetAll)
    {
        return;
    }

    char s[MAXLENGTH_MESSAGE];

    Format(s, sizeof(s), "[SM] %N - Chat: %s | Voice: %s",
        target,
        IgnoreMatrix[client][target].Chat ? "OFF" : "ON",
        IgnoreMatrix[client][target].Voice ? "OFF" : "ON"
    );

    ReplyToCommand(client, s);
    return;
}

stock bool IsValidClient(int iClient)
{
    return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}

//  Sets up a native to send whether or not a client is ignoring a specific target's chat
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("GetIgnoreMatrix", Native_GetIgnoreMatrix);

    RegPluginLibrary("ignorematrix");

    return APLRes_Success;
}

//  The native itself
public int Native_GetIgnoreMatrix(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int target = GetNativeCell(2);

    return IgnoreMatrix[client][target].Chat;
}