/*
advancedc4timer.sp

Description:
    Advanced c4 countdown timer.  Based on the original sm c4 timer by sslice.

Versions:
    0.5
        * Initial Release
        
    0.6
        * Restructued most of the code
        * Added user configuration of sounds
        * Added optional announcement
        * Changed timer to go 30, 20, 10, 9.....1
        
    1.0
        * Minor code and naming standards changes
        * Added support for late loading
        
    1.1
        * Added an exit option to the settings menu
        * Changed command to sm_c4timer
        * Made the SoundNames array const
        * Added new hud text
        
    1.1.1
        * Fixed voice countdown bug
        
    1.2
        * Added translations
        * Added name to bomb exploded message
        * Added bomb defused hud message
        
    1.2.1
        * Updated translation files and script to match
        * Changed menu behavior
        
    1.3
        * Changed naming convention to be more in line with base sourcemod
        * Improved timer synchronization
        * Changed from panels to menus
        
    1.4
        * Removed duplicate menu exit
        * Added autoloading of config file
        * Added verbose, flexible bombtimer messages
        * Added the ability to have the voice or text messages start at 10 instead of 30
        
    1.4.1
        * Added individual sounds
	
	1.5
		* Fixed some code.
		* Timer has 90 seconds now.
        
*/
        
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#pragma tabsize 0

#define PLUGIN_VERSION "1.5"
#define NUM_SOUNDS 18
#define TIMER 90

#define TWENTY 0
#define ONE 1
#define TWO 2
#define THREE 3
#define FOUR 4
#define FIVE 5
#define SIX 6
#define SEVEN 7
#define EIGHT 8
#define NINE 9
#define TEN 10
#define THIRTY 11
#define FOURTY 12
#define FIFTY 13
#define SIXTY 14
#define SEVENTY 15
#define EIGHTY 16
#define NINETY 17

#define NUM_PREFS 4
#define SOUND 0
#define CHAT 1
#define CENTER 2
#define HUD 3

#define SOUND_AT_TEN 1
#define TEXT_AT_TEN 2

public Plugin:myinfo = 
{
    name = "Advanced c4 Countdown Timer",
    author = "dalto & MaxiMuM",
    description = "Plugin that gives a countdown for the C4 explosion in Counter-Strike Source.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
};


// Global Variables
new String:g_soundsList[1][NUM_SOUNDS][PLATFORM_MAX_PATH];
new g_c4Preferences[MAXPLAYERS + 1][NUM_PREFS];
new Handle:g_kvC4 = INVALID_HANDLE;
new String:g_filenameC4[PLATFORM_MAX_PATH];
new Handle:g_CvarEnable = INVALID_HANDLE;
new Handle:g_CvarMPc4Timer = INVALID_HANDLE;
new Handle:g_CvarAnnounce = INVALID_HANDLE;
new Handle:g_CvarChatDefault = INVALID_HANDLE;
new Handle:g_CvarSoundDefault = INVALID_HANDLE;
new Handle:g_CvarHUDDefault = INVALID_HANDLE;
new Handle:g_CvarCenterDefault = INVALID_HANDLE;
new Handle:g_CvarAltStart = INVALID_HANDLE;
new Float:g_explosionTime;
new g_countdown;
new bool:g_lateLoaded;
new String:g_planter[40];
static const String:g_soundNames[NUM_SOUNDS][] = {"20", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "30", "40", "50", "60", "70", "80", "90"};
new Handle:hTimer = INVALID_HANDLE;

// We need to capture if the plugin was late loaded so we can make sure initializations
// are handled properly
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    g_lateLoaded = late;
    return APLRes_Success;
}

public OnPluginStart()
{
    CreateConVar("sm_c4_timer_version", PLUGIN_VERSION, "Advanced c4 Timer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_CvarEnable = CreateConVar("sm_c4_timer_enable", "1", "Enables the c4 timer");
    g_CvarAnnounce = CreateConVar("sm_c4_timer_announce", "1", "Announcement preferences");
    g_CvarChatDefault = CreateConVar("sm_c4_timer_chat_default", "0", "Default setting for chat preference");
    g_CvarCenterDefault = CreateConVar("sm_c4_timer_center_default", "0", "Default setting for center preference");
    g_CvarHUDDefault = CreateConVar("sm_c4_timer_hud_default", "1", "Default setting for HUD preference");
    g_CvarSoundDefault = CreateConVar("sm_c4_timer_sound_default", "1", "Default setting for sound preference");
    g_CvarAltStart = CreateConVar("sm_c4_timer_start_at_ten", "0", "1 voice starts at 10, 2 text starts at 10, 3 both start at 10");

    g_CvarMPc4Timer = FindConVar("mp_c4timer");
    
    LoadTranslations("plugin.advancedc4timer");

    // Execute the config file
    AutoExecConfig(true, "advancedc4timer");
    
    HookEvent("bomb_planted", EventBombPlanted, EventHookMode_Pre);
    HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", EventRoundEnd, EventHookMode_PostNoCopy);
    HookEvent("bomb_exploded", EventBombExploded, EventHookMode_PostNoCopy);
    HookEvent("bomb_defused", EventBombDefused, EventHookMode_Post);
    RegConsoleCmd("sm_c4timer", SettingsMenu);

    LoadSounds();
    
    g_kvC4=CreateKeyValues("c4UserSettings");
    BuildPath(Path_SM, g_filenameC4, PLATFORM_MAX_PATH, "data/c4usersettings.txt");
    if(!FileToKeyValues(g_kvC4, g_filenameC4))
        KeyValuesToFile(g_kvC4, g_filenameC4);
        
    // if the plugin was loaded late we have a bunch of initialization that needs to be done
    if(g_lateLoaded)
    {
        // Next we need to whatever we would have done as each client authorized
        for(new i = 1; i <= GetMaxClients(); i++)
        {
            if(IsClientInGame(i))
            {
                PrepareClient(i);
            }
        }
    }
}

public OnMapStart()
{
    for(new i = 0; i < NUM_SOUNDS; i++)
    {
        PrepareSound(i);
    }
}

// When a new client is authorized we create sound preferences
// for them if they do not have any already
public OnClientAuthorized(client, const String:auth[])
{
    PrepareClient(client);
}

public Action:EventBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!GetConVarBool(g_CvarEnable))
    {
        return Plugin_Continue;
    }
    
    g_explosionTime = GetEngineTime() + GetConVarFloat(g_CvarMPc4Timer);
    
    GetClientName(GetClientOfUserId(GetEventInt(event, "userid")), g_planter, sizeof(g_planter));
    
    g_countdown = GetConVarInt(g_CvarMPc4Timer) - 1;

    hTimer = CreateTimer((g_explosionTime - float(g_countdown)) - GetEngineTime(), TimerCountdown);
    
    return Plugin_Continue;
}

public EventBombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!GetConVarBool(g_CvarEnable))
    {
        return;
    }
    
    if(hTimer != INVALID_HANDLE)
    {
        KillTimer(hTimer);
        hTimer = INVALID_HANDLE;
    }
    decl String:defuser[40];
    GetClientName(GetClientOfUserId(GetEventInt(event, "userid")), defuser, sizeof(defuser));
    for(new i = 1; i <= GetMaxClients(); i++)
    {
        if(IsClientInGame(i) && !IsFakeClient(i) && g_c4Preferences[i][HUD])
        {
            PrintHintText(i, "%T", "bomb defused", i, defuser);
        }
    }
}

public Action:TimerCountdown(Handle:timer, any:data)
{
    BombMessage(g_countdown);
    if(--g_countdown)
    {
        hTimer = CreateTimer((g_explosionTime - float(g_countdown)) - GetEngineTime(), TimerCountdown);
    }
    else
    {
        hTimer = INVALID_HANDLE;
    }
}

// Loads the soundsList array with the c4 sounds
public LoadSounds()
{
    new Handle:kvQSL = CreateKeyValues("c4SoundsList");
    new String:fileQSL[PLATFORM_MAX_PATH];

    BuildPath(Path_SM, fileQSL, PLATFORM_MAX_PATH, "configs/c4soundslist.cfg");
    FileToKeyValues(kvQSL, fileQSL);
    
    if (!KvGotoFirstSubKey(kvQSL))
    {
        SetFailState("configs/c4soundslist.cfg not found or not correctly structured");
        CloseHandle(kvQSL);
        return;
    }

    for(new i = 0; i < NUM_SOUNDS; i++)
    {
        KvGetString(kvQSL, g_soundNames[i], g_soundsList[0][i], PLATFORM_MAX_PATH);
    }
    
    CloseHandle(kvQSL);
}

public PrepareSound(sound)
{
    new String:downloadFile[PLATFORM_MAX_PATH];

    if(!StrEqual(g_soundsList[0][sound], ""))
    {
        PrecacheSound(g_soundsList[0][sound], true);
        Format(downloadFile, PLATFORM_MAX_PATH, "sound/%s", g_soundsList[0][sound]);
        AddFileToDownloadsTable(downloadFile);
    }
}

// Sends the bomb message
public BombMessage(count)
{
    new soundKey;
    decl String:buffer[200];
    
	switch(count)
	{
		case 1, 2, 3, 4, 5, 6, 7, 8, 9, 10:
			soundKey = count;
		case 20:
			soundKey = TWENTY;
		case 30:
			soundKey = THIRTY;
		case 40:
			soundKey = FOURTY;
		case 50:
			soundKey = FIFTY;
		case 60:
			soundKey = SIXTY;
		case 70:
			soundKey = SEVENTY;
		case 80:
			soundKey = EIGHTY;
		case 90:
			soundKey = NINETY;
		default:
			return;
	}

    for (new i = 1; i <= GetMaxClients(); i++)
    {
        if(IsClientInGame(i) && !IsFakeClient(i) && !StrEqual(g_soundsList[0][soundKey], ""))
        {
            Format(buffer, sizeof(buffer), "countdown %i", count);
            Format(buffer, sizeof(buffer), "%T", buffer, i, count);
            if(g_c4Preferences[i][SOUND] && !(GetConVarInt(g_CvarAltStart) & SOUND_AT_TEN && (soundKey < 1 || soundKey > 10)))
            {
                EmitSoundToClient(i, g_soundsList[0][soundKey]);
            }
            if(!(GetConVarInt(g_CvarAltStart) & TEXT_AT_TEN && (soundKey < 1 || soundKey > 10)))
            {
                if(g_c4Preferences[i][CHAT])
                {
                    PrintToChat(i, "Bomb: %s", buffer);
                }
                if(g_c4Preferences[i][CENTER])
                {
                    PrintCenterText(i, buffer);
                }
                if(g_c4Preferences[i][HUD])
                {
                    PrintHintText(i, buffer);
                }
            }
        }
    }
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
    if(IsClientInGame(client))
    {
        PrintToChat(client, "%t", "announce");
    }
}

//  This selects or disables the c4 settings
public SettingsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select)
    {
        // Update both the soundPreference array and User Settings KV
        switch(param2)
        {
            case 0:
                g_c4Preferences[param1][SOUND] = Flip(g_c4Preferences[param1][SOUND]);
            case 1:
                g_c4Preferences[param1][CHAT] = Flip(g_c4Preferences[param1][CHAT]);
            case 2:
                g_c4Preferences[param1][CENTER] = Flip(g_c4Preferences[param1][CENTER]);
            case 3:
                g_c4Preferences[param1][HUD] = Flip(g_c4Preferences[param1][HUD]);
        }
        new String:steamId[20];
        GetClientAuthString(param1, steamId, 20);
        KvRewind(g_kvC4);
        KvJumpToKey(g_kvC4, steamId);
        KvSetNum(g_kvC4, "sound", g_c4Preferences[param1][SOUND]);
        KvSetNum(g_kvC4, "chat", g_c4Preferences[param1][CHAT]);
        KvSetNum(g_kvC4, "center", g_c4Preferences[param1][CENTER]);
        KvSetNum(g_kvC4, "hud", g_c4Preferences[param1][HUD]);
        KvSetNum(g_kvC4, "timestamp", GetTime());
        SettingsMenu(param1, 0);
    } else if(action == MenuAction_End)    {
        CloseHandle(menu);
    }
}
 
//  This creates the settings panel
public Action:SettingsMenu(client, args)
{
    decl String:buffer[100];
    new Handle:menu = CreateMenu(SettingsMenuHandler);
    Format(buffer, sizeof(buffer), "%T", "c4 menu", client);
    SetMenuTitle(menu, buffer);
    if(g_c4Preferences[client][SOUND] == 1)
    {
        Format(buffer, sizeof(buffer), "%T", "disable sound", client);
    } else {
        Format(buffer, sizeof(buffer), "%T", "enable sound", client);
    }
    AddMenuItem(menu, "menu item", buffer);

    if(g_c4Preferences[client][CHAT] == 1)
    {
        Format(buffer, sizeof(buffer), "%T", "disable chat", client);
    }
    else {
        Format(buffer, sizeof(buffer), "%T", "enable chat", client);
    }
    AddMenuItem(menu, "menu item", buffer);
    
    if(g_c4Preferences[client][CENTER] == 1)
    {
        Format(buffer, sizeof(buffer), "%T", "disable center", client);
    } else {
        Format(buffer, sizeof(buffer), "%T", "enable center", client);
    }
    AddMenuItem(menu, "menu item", buffer);
    
    if(g_c4Preferences[client][HUD] == 1)
    {
        Format(buffer, sizeof(buffer), "%T", "disable hud", client);
    }
    else {
        Format(buffer, sizeof(buffer), "%T", "enable hud", client);
    }
    AddMenuItem(menu, "menu item", buffer);

    DisplayMenu(menu, client, 15);
     
    return Plugin_Handled;
}

// Switches a non-zero number to a 0 and a 0 to a 1
public Flip(flipNum)
{
    if(flipNum == 0)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

// Initializations to be done at the beginning of the round
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Save user settings to a file
    KvRewind(g_kvC4);
    KeyValuesToFile(g_kvC4, g_filenameC4);
    if(hTimer != INVALID_HANDLE)
    {
        KillTimer(hTimer);
        hTimer = INVALID_HANDLE;
    }
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (hTimer != INVALID_HANDLE)
    {
        KillTimer(hTimer);
        hTimer = INVALID_HANDLE;
    }
	
}

// When a user disconnects we need to update their timestamp in kvC4
public OnClientDisconnect(client)
{
    new String:steamId[20];
    if(client && !IsFakeClient(client))
    {
        GetClientAuthString(client, steamId, 20);
        KvRewind(g_kvC4);
        if(KvJumpToKey(g_kvC4, steamId))
        {
            KvSetNum(g_kvC4, "timestamp", GetTime());
        }
    }
}

public PrepareClient(client)
{
    new String:steamId[20];
    if(client)
    {
        if(!IsFakeClient(client))
        {
            // Get the users saved setting or create them if they don't exist
            GetClientAuthString(client, steamId, 20);
            KvRewind(g_kvC4);
            if(KvJumpToKey(g_kvC4, steamId))
            {
                g_c4Preferences[client][SOUND] = KvGetNum(g_kvC4, "sound", GetConVarInt(g_CvarSoundDefault));
                g_c4Preferences[client][CHAT] = KvGetNum(g_kvC4, "chat", GetConVarInt(g_CvarChatDefault));
                g_c4Preferences[client][CENTER] = KvGetNum(g_kvC4, "center", GetConVarInt(g_CvarCenterDefault));
                g_c4Preferences[client][HUD] = KvGetNum(g_kvC4, "hud", GetConVarInt(g_CvarHUDDefault));
            } else {
                KvRewind(g_kvC4);
                KvJumpToKey(g_kvC4, steamId, true);
                KvSetNum(g_kvC4, "sound", GetConVarInt(g_CvarSoundDefault));
                KvSetNum(g_kvC4, "chat", GetConVarInt(g_CvarChatDefault));
                KvSetNum(g_kvC4, "center", GetConVarInt(g_CvarCenterDefault));
                KvSetNum(g_kvC4, "hud", GetConVarInt(g_CvarHUDDefault));
                g_c4Preferences[client][SOUND] = GetConVarInt(g_CvarSoundDefault);
                g_c4Preferences[client][CHAT] = GetConVarInt(g_CvarChatDefault);
                g_c4Preferences[client][CENTER] = GetConVarInt(g_CvarCenterDefault);
                g_c4Preferences[client][HUD] = GetConVarInt(g_CvarHUDDefault);
            }
            KvRewind(g_kvC4);

            // Make the announcement in 30 seconds unless announcements are turned off
            if(GetConVarBool(g_CvarAnnounce))
            {
                CreateTimer(30.0, TimerAnnounce, client);
            }
        }
    }
}

public EventBombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(hTimer != INVALID_HANDLE)
    {
        KillTimer(hTimer);
        hTimer = INVALID_HANDLE;
    }
	
    for(new i = 1; i <= GetMaxClients(); i++)
    {
        if(IsClientInGame(i) && !IsFakeClient(i) && g_c4Preferences[i][HUD])
        {
            PrintHintText(i, "%T", "bomb exploded", i, g_planter);
        }
    }
}
