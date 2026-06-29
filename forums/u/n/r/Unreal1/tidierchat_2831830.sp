#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0"

ConVar g_cvEnabled;
ConVar g_cvVoice;
ConVar g_cvConnect;
ConVar g_cvDisconnect;
ConVar g_cvChangeClass;
ConVar g_cvTeam;
ConVar g_cvArenaResize;
ConVar g_cvArenaMaxStreak;
ConVar g_cvStrangeLevel;
ConVar g_cvCvar;
ConVar g_cvAllText;

EngineVersion g_engine = Engine_Unknown;

public Plugin myinfo = 
{
    name = "Tidier Chat",
    author = "Unreal1 & thanks to linux_lover",
    description = "Cleans up the chat area.",
    version = PLUGIN_VERSION,
    url = "https://davidivashenko.com"
};

public void OnPluginStart()
{
    CreateConVar("sm_tidierchat_version", PLUGIN_VERSION, "Tidier Chat Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cvEnabled = CreateConVar("sm_tidierchat_on", "1", "Enable/disable plugin");
    g_cvVoice = CreateConVar("sm_tidierchat_voice", "1", "Clean up voice messages");
    g_cvConnect = CreateConVar("sm_tidierchat_connect", "0", "Clean up connect messages");
    g_cvDisconnect = CreateConVar("sm_tidierchat_disconnect", "0", "Clean up disconnect messages");
    g_cvChangeClass = CreateConVar("sm_tidierchat_class", "1", "Clean up class change messages");
    g_cvTeam = CreateConVar("sm_tidierchat_team", "1", "Clean up team join messages");
    g_cvArenaResize = CreateConVar("sm_tidierchat_arena_resize", "1", "Clean up arena team resize messages");
    g_cvArenaMaxStreak = CreateConVar("sm_tidierchat_arena_maxstreak", "1", "Clean up arena team scramble messages");
    g_cvStrangeLevel = CreateConVar("sm_tidierchat_strange_level", "0", "Tidy strange level up messages to other players");
    g_cvCvar = CreateConVar("sm_tidierchat_cvar", "1", "Clean up cvar messages");
    g_cvAllText = CreateConVar("sm_tidierchat_alltext", "0", "Clean up all chat messages from plugins");

    g_engine = GetEngineVersion();

    HookEvents();
}

void HookEvents()
{
    // Mod-independent hooks  
    HookEvent("player_connect_client", Event_PlayerConnect, EventHookMode_Pre);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
    HookEvent("server_cvar", Event_Cvar, EventHookMode_Pre);
    HookUserMessage(GetUserMessageId("TextMsg"), UserMsg_TextMsg, true);

    // Game-dependent hooks
    switch (g_engine)
    {
        case Engine_TF2:
        {
            HookUserMessage(GetUserMessageId("VoiceSubtitle"), UserMsg_VoiceSubtitle, true);
            HookEvent("arena_match_maxstreak", Event_MaxStreak, EventHookMode_Pre);
        }
        case Engine_CSGO:
        {
            HookEvent("player_connect_full", Event_PlayerConnect, EventHookMode_Pre);
        }
        // Add more game-specific hooks here if needed
    }
}

Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvEnabled.BoolValue && g_cvConnect.BoolValue)
    {
        event.BroadcastDisabled = true;
    }
    
    return Plugin_Continue;
}

Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvEnabled.BoolValue && g_cvDisconnect.BoolValue)
    {
        event.BroadcastDisabled = true;
    }
    
    return Plugin_Continue;
}

Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    if (g_engine == Engine_CSGO)
    {
        dontBroadcast = true;
    }

    if (g_cvEnabled.BoolValue && g_cvTeam.BoolValue)
    {
        if (!event.GetBool("silent"))
        {
            event.BroadcastDisabled = true;
        }
    }
    
    return Plugin_Continue;
}

Action Event_MaxStreak(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvEnabled.BoolValue && g_cvArenaMaxStreak.BoolValue)
    {
        event.BroadcastDisabled = true;
    }
    
    return Plugin_Continue;
}

Action Event_Cvar(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvEnabled.BoolValue && g_cvCvar.BoolValue)
    {
        event.BroadcastDisabled = true;
    }
    
    return Plugin_Continue;
}

Action UserMsg_VoiceSubtitle(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if (g_cvEnabled.BoolValue && g_cvVoice.BoolValue)
    {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

Action UserMsg_TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if (g_cvEnabled.BoolValue)
    {
        if (g_cvAllText.BoolValue) return Plugin_Handled;

        if (g_engine == Engine_TF2)
        {
            char message[32];
            msg.ReadByte();
            msg.ReadString(message, sizeof(message));

            if (g_cvChangeClass.BoolValue && (strcmp(message, "#game_respawn_as") == 0 || strcmp(message, "#game_spawn_as") == 0))
            {
                return Plugin_Handled;
            }

            if (g_cvArenaResize.BoolValue && strncmp(message, "#TF_Arena_TeamSize", 18) == 0)
            {
                return Plugin_Handled;
            }
			
			if (g_cvStrangeLevel.BoolValue && strcmp(message, "#TF_HUD_Event_KillEater_Leveled_Chat") == 0)
            {
                return Plugin_Handled;
            }
        }
    }
    
    return Plugin_Continue;
}