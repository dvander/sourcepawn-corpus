#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

#define KNIFEFIGHT_VERSION      "1.3.7a"
#define MAX_FILE_LEN            80
#define SOUND_EXPLODE           "ambient/explosions/explode_8.wav"
#define SOUND_TIMER             "ambient/tones/floor1.wav"

#define MAX_WEAPONS             35  // max weapons
#define CS_SLOT_KNIFE           2   // melee weapon slot
#define TEAM_T                  2
#define TEAM_CT                 3

#define MAX_CHAT_SIZE           192

#define YELLOW                  0x01
#define NAME_TEAMCOLOR          0x02
#define TEAMCOLOR               0x03
#define GREEN                   0x04

#include "knifefight/chat.h"
#include "knifefight/chat.sp"

public Plugin:myinfo =
{
    name = "Knife Fight",
    author = "XARiUS, Otstrel.Ru Team (MOD by Snake 60)",
    description = "Let the last two players alive choose whether to knife it out.",
    version = KNIFEFIGHT_VERSION,
    url = "http://www.the-otc.com/, http://otstrel.ru"
};

new Float:teleloc[3];
new Float:g_winnerspeed;
new String:language[4];
new String:languagecode[4];
new String:ctname[MAX_NAME_LENGTH];
new String:tname[MAX_NAME_LENGTH];
new String:ctitems[8][64];
new String:titems[8][64];
new String:winnername[MAX_NAME_LENGTH];
new String:losername[MAX_NAME_LENGTH];
new String:g_declinesound[MAX_FILE_LEN];
new String:g_beaconsound[MAX_FILE_LEN];
new String:g_fightsongs[256];
new String:fightsong[20][256];
new String:song[256];
new String:itemswon[256];
new bool:g_winnereffects;
new bool:g_losereffects;
new bool:g_forcefight;
new bool:g_enabled;
new bool:g_alltalk;
new bool:g_alltalkenabled   = false;
new bool:g_block;
new bool:g_blockenabled     = false;
new bool:g_throwingknives; // MOD by Snake 60
new bool:g_throwingknivesenabled = false; // MOD by Snake 60
new bool:g_randomkill;
new bool:g_useteleport;
new bool:g_restorehealth;
new bool:g_locatorbeam;
new bool:g_stopmusic;
new bool:g_intermission;
new bool:isFighting     = false;
new bool:bombplanted    = false;
new ctid, tid, winner, loser, alivect, alivet;
new g_winnerid  = 0;
new ctagree     = -1;
new tagree      = -1;
new songsfound  = 0;
new timesrepeated;
new g_iMyWeapons, g_iHealth, g_iAccount, g_iSpeed;
new g_beamsprite, g_halosprite, g_lightning, g_locatebeam, g_locatehalo;
new g_countdowntimer, g_winnerhealth, g_winnermoney, g_minplayers;
new g_fighttimer, fighttimer;
new Float:g_beaconragius;
new Handle:g_Cvarenabled        = INVALID_HANDLE;
new Handle:g_Cvaralltalk        = INVALID_HANDLE;
new Handle:g_Cvarblock          = INVALID_HANDLE;
new Handle:g_Cvarthrowingknives = INVALID_HANDLE; //MOD by Snake 60
new Handle:g_Cvarrandomkill     = INVALID_HANDLE;
new Handle:g_Cvarminplayers     = INVALID_HANDLE;
new Handle:g_Cvardeclinesound   = INVALID_HANDLE;
new Handle:g_Cvarbeaconsound    = INVALID_HANDLE;
new Handle:g_Cvarfightsongs     = INVALID_HANDLE;
new Handle:g_Cvaruseteleport    = INVALID_HANDLE;
new Handle:g_Cvarrestorehealth  = INVALID_HANDLE;
new Handle:g_Cvarwinnerspeed    = INVALID_HANDLE;
new Handle:g_Cvarwinnerhealth   = INVALID_HANDLE;
new Handle:g_Cvarwinnermoney    = INVALID_HANDLE;
new Handle:g_Cvarwinnereffects  = INVALID_HANDLE;
new Handle:g_Cvarlosereffects   = INVALID_HANDLE;
new Handle:g_Cvarlocatorbeam    = INVALID_HANDLE;
new Handle:g_Cvarstopmusic      = INVALID_HANDLE;
new Handle:g_Cvarforcefight     = INVALID_HANDLE;
new Handle:g_Cvarcountdowntimer = INVALID_HANDLE;
new Handle:g_Cvarfighttimer     = INVALID_HANDLE;
new Handle:g_Cvarbeaconradius   = INVALID_HANDLE;
new Handle:g_Cvar_Debug         = INVALID_HANDLE;
new bool:g_debug                = false;
new UserMsg:g_VGUIMenu;

new Handle:g_WeaponSlots    = INVALID_HANDLE;

new String:g_WeaponNames[MAX_WEAPONS][ ] = 
{ 
    "primammo",     "secammo",  "vest",         "vesthelm",
    "defuser",      "nvgs",     "flashbang",    "hegrenade",
    "smokegrenade", "galil",    "ak47",         "scout",
    "sg552",        "awp",      "g3sg1",        "famas", 
    "m4a1",         "aug",      "sg550",        "glock",
    "usp",          "p228",     "deagle",       "elite",
    "fiveseven",    "m3",       "xm1014",       "mac10",
    "tmp",          "mp5navy",  "ump45",        "p90",
    "m249",         "c4",       "knife"
};

new Handle:sv_alltalk               = INVALID_HANDLE;
new Handle:sm_noblock               = INVALID_HANDLE;
new Handle:sm_throwingknives_enable = INVALID_HANDLE;// MOD by Snake 60
new g_WeaponParent;

new Handle:g_Cvar_SoundPrefDefault  = INVALID_HANDLE;
new Handle:g_Cookie_SoundPref       = INVALID_HANDLE;
new g_soundPrefs[MAXPLAYERS+1];
new Handle:g_Cookie_FightPref       = INVALID_HANDLE;
new g_fightPrefs[MAXPLAYERS+1];
new Handle:g_Cvar_IsBotFightAllowed = INVALID_HANDLE;
new bool:g_isBotFightAllowed        = false;

new g_showWinner;
new g_removeNewPlayer;
new Handle:g_Cvar_ShowWinner        = INVALID_HANDLE;
new Handle:g_Cvar_RemoveNewPlayer   = INVALID_HANDLE;

new Handle:g_mp_ignorerwc   = INVALID_HANDLE; // Added by Emper0r

public OnPluginStart()
{
    CHAT_DetectColorMsg();
    sv_alltalk = FindConVar("sv_alltalk");
    if ( sv_alltalk == INVALID_HANDLE )
    {
        LogError("FATAL: Cannot find sv_alltalk cvar.");
        SetFailState("[KnifeFight] Cannot find sv_alltalk cvar.");
    }
    
    LoadTranslations("knifefight.phrases");
    new Handle:Cvar_Version = CreateConVar("sm_knifefight_version", KNIFEFIGHT_VERSION, 
        "Knife Fight Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    // KLUGE: Update version cvar if plugin updated on map change.
    SetConVarString(Cvar_Version, KNIFEFIGHT_VERSION);
    
    g_Cvarenabled       = CreateConVar("sm_knifefight_enabled",     "1", 
        "Enable this plugin. 0 = Disabled");
    g_Cvar_Debug        = CreateConVar("sm_knifefight_debug",       "0", 
        "Enable debug. 0 = Disabled");
    g_debug             = GetConVarBool(g_Cvar_Debug);
    g_Cvaralltalk       = CreateConVar("sm_knifefight_alltalk",     "1", 
        "Enable alltalk while knife fight. 0 = Disabled");
    g_Cvarblock         = CreateConVar("sm_knifefight_block",     "0", 
        "Enable player blocking (disable sm_noblock) if sm_noblock is enabled while knife fight. 0 = Disabled");
    g_Cvarthrowingknives = CreateConVar("sm_knifefight_throwingknives",     "1", // MOD by Snake 60
        "Disable player throwing knives during knife fight (set sm_throwingknives_enable 0). 1 = Disabled"); // MOD by Snake 60
    g_Cvarrandomkill    = CreateConVar("sm_knifefight_randomkill",  "0", 
        "Enable random kill after knife fight time end. 0 = Disabled");
    g_Cvarminplayers    = CreateConVar("sm_knifefight_minplayers",  "4", 
        "Minimum number of players before knife fights will trigger.");
    g_Cvaruseteleport   = CreateConVar("sm_knifefight_useteleport", "1", 
        "Use smart teleport system prior to knife fight. 0 = Disabled");
    g_Cvarrestorehealth = CreateConVar("sm_knifefight_restorehealth",   "1", 
        "Give players full health before knife fight. 0 = Disabled");
    g_Cvarforcefight    = CreateConVar("sm_knifefight_forcefight",  "0", 
        "Force knife fight at end of round instead of prompting with menus. 0 = Disabled");
    g_Cvarwinnerhealth  = CreateConVar("sm_knifefight_winnerhealth",    "0", 
        "Total health to give the winner. 0 = Disabled");
    g_Cvarwinnerspeed   = CreateConVar("sm_knifefight_winnerspeed", "0", 
        "Total speed given to the winner. 0 = Disabled (1.0 is normal speed, 2.0 is twice normal)");
    g_Cvarwinnermoney   = CreateConVar("sm_knifefight_winnermoney", "0", 
        "Total extra money given to the winner. 0 = Disabled");
    g_Cvarwinnereffects = CreateConVar("sm_knifefight_winnereffects",   "1", 
        "Enable special effects on the winner. 0 = Disabled");
    g_Cvarlosereffects  = CreateConVar("sm_knifefight_losereffects",    "1", 
        "Dissolve loser body using special effects. 0 = Disabled");
    g_Cvarlocatorbeam   = CreateConVar("sm_knifefight_locatorbeam", "1", 
        "Use locator beam between players if they are far apart. 0 = Disabled");
    g_Cvarstopmusic     = CreateConVar("sm_knifefight_stopmusic",   "0", 
        "Stop music when fight is over. Useful when used with gungame. 0 = Disabled");
    g_Cvardeclinesound  = CreateConVar("sm_knifefight_declinesound",    "knifefight/chicken.wav", 
        "The sound to play when player declines to knife.");
    g_Cvarbeaconsound   = CreateConVar("sm_knifefight_beaconsound", "buttons/blip1.wav", 
        "The sound to play when beacon ring shows.");
    g_Cvarcountdowntimer    = CreateConVar("sm_knifefight_countdowntimer",  "3", 
        "Number of seconds to count down before a knife fight.");
    g_Cvarfighttimer    = CreateConVar("sm_knifefight_fighttimer",  "30", 
        "Number of seconds to allow for knifing.    Players get slayed after this time limit expires.");
    g_Cvarbeaconradius  = CreateConVar("sm_knifefight_beaconradius",    "800",  
        "Beacon radius.");
    g_Cvarfightsongs    = CreateConVar("sm_knifefight_fightsongs",  "", 
        "Songs to play during the fight, comma delimited. (example: knifefight/song1.mp3,knifefight/song2.mp3,knifefight/song3.mp3) (max: 20)");
    g_Cvar_IsBotFightAllowed    = CreateConVar("sm_knifefight_botfight",       "0", 
        "Allow bot to knife fight with bot. 0 = Disabled");
    g_isBotFightAllowed         = GetConVarBool(g_Cvar_IsBotFightAllowed);
    g_Cvar_ShowWinner       = CreateConVar("sm_knifefight_showwinner",    "0",
        "Show winner. (0 - Top left, 1 - Chat)");
    g_showWinner            = GetConVarInt(g_Cvar_ShowWinner);
    g_Cvar_RemoveNewPlayer  = CreateConVar("sm_knifefight_removenewplayer",    "0",
        "Remove player connected when fight is started. (0 - Slay, 1 - Move to spec)");
    g_removeNewPlayer       = GetConVarInt(g_Cvar_RemoveNewPlayer);

    GetLanguageInfo(GetServerLanguage(), languagecode, sizeof(languagecode), language, sizeof(language));

    new f_WeaponSlots[MAX_WEAPONS] =
    {
         -1, -1, -1, -1, -1, -1,
        CS_SLOT_GRENADE,    CS_SLOT_GRENADE,    CS_SLOT_GRENADE,    CS_SLOT_PRIMARY,
        CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,
        CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,
        CS_SLOT_PRIMARY,    CS_SLOT_SECONDARY,  CS_SLOT_SECONDARY,  CS_SLOT_SECONDARY,
        CS_SLOT_SECONDARY,  CS_SLOT_SECONDARY,  CS_SLOT_SECONDARY,  CS_SLOT_PRIMARY,
        CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,
        CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_C4, 
        CS_SLOT_KNIFE
    };

    g_WeaponSlots = CreateTrie( );
    for(new i = 0; i < MAX_WEAPONS; i++)
    {
         SetTrieValue(g_WeaponSlots, g_WeaponNames[i], f_WeaponSlots[i]);
    }
    
    g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
    
    HookEvent("player_spawn",   EventPlayerSpawn,   EventHookMode_Post);
    HookEvent("player_death",   EventPlayerDeath,   EventHookMode_Post);
    HookEvent("item_pickup",    EventItemPickup,    EventHookMode_Post);    
    HookEvent("bomb_planted",   EventBombPlanted,   EventHookMode_PostNoCopy);
    HookEvent("round_end",      EventBombPlanted,   EventHookMode_PostNoCopy);
    HookEvent("round_start",    EventRoundStart,    EventHookMode_PostNoCopy);

    g_VGUIMenu = GetUserMessageId("VGUIMenu");
    if (g_VGUIMenu == INVALID_MESSAGE_ID)
    {
        LogError("FATAL: Cannot find VGUIMenu user message id.");
        SetFailState("[KnifeFight] VGUIMenu Not Found");
    }
    // TODO: Enable after fix: https://bugs.alliedmods.net/show_bug.cgi?id=3817
    //HookUserMessage(g_VGUIMenu, UserMsg_VGUIMenu);

    HookConVarChange(g_Cvarenabled,             OnSettingChanged);
    HookConVarChange(g_Cvaralltalk,             OnSettingChanged);
    HookConVarChange(g_Cvarblock,               OnSettingChanged);
    HookConVarChange(g_Cvarthrowingknives,      OnSettingChanged); // MOD by Snake 60
    HookConVarChange(g_Cvarrandomkill,          OnSettingChanged);
    HookConVarChange(g_Cvarminplayers,          OnSettingChanged);
    HookConVarChange(g_Cvaruseteleport,         OnSettingChanged);
    HookConVarChange(g_Cvarrestorehealth,       OnSettingChanged);
    HookConVarChange(g_Cvarwinnerhealth,        OnSettingChanged);
    HookConVarChange(g_Cvarwinnerspeed,         OnSettingChanged);
    HookConVarChange(g_Cvarwinnermoney,         OnSettingChanged);
    HookConVarChange(g_Cvarwinnereffects,       OnSettingChanged);
    HookConVarChange(g_Cvarlosereffects,        OnSettingChanged);
    HookConVarChange(g_Cvarlocatorbeam,         OnSettingChanged);
    HookConVarChange(g_Cvarstopmusic,           OnSettingChanged);
    HookConVarChange(g_Cvarforcefight,          OnSettingChanged);
    HookConVarChange(g_Cvarcountdowntimer,      OnSettingChanged);
    HookConVarChange(g_Cvarfighttimer,          OnSettingChanged);
    HookConVarChange(g_Cvarbeaconradius,        OnSettingChanged);
    HookConVarChange(g_Cvar_Debug,              OnSettingChanged);
    HookConVarChange(g_Cvar_IsBotFightAllowed,  OnSettingChanged);
    HookConVarChange(g_Cvar_ShowWinner,         OnSettingChanged);
    HookConVarChange(g_Cvar_RemoveNewPlayer,    OnSettingChanged);

    g_Cvar_SoundPrefDefault     = CreateConVar("sm_knifefight_soundprefdefault", "1", 
        "Default sound setting for new users.");
    g_Cookie_SoundPref      = RegClientCookie("sm_knifefight_soundpref", 
        "Knifefight Sound Pref", CookieAccess_Private);
    g_Cookie_FightPref      = RegClientCookie("sm_knifefight_fightpref", 
        "Knifefight Fight Pref", CookieAccess_Private);
    RegConsoleCmd("kfmenu", MenuKnifeFight, "Show knife fight settings menu.");
    for(new i = 1; i <= MaxClients; i++) 
    {
        g_soundPrefs[i] = GetConVarInt(g_Cvar_SoundPrefDefault);
        g_fightPrefs[i] = 0;
    }

    SetupOffsets(); 
    AutoExecConfig(true, "knifefight");
}


public OnConfigsExecuted()
{
    decl String:buffer[MAX_FILE_LEN];
    g_beamsprite    = PrecacheModel("materials/sprites/lgtning.vmt");
    g_halosprite    = PrecacheModel("materials/sprites/halo01.vmt");
    g_lightning     = PrecacheModel("materials/sprites/tp_beam001.vmt");
    g_locatebeam    = PrecacheModel("materials/sprites/physbeam.vmt");
    g_locatehalo    = PrecacheModel("materials/sprites/plasmahalo.vmt");
    PrecacheSound(SOUND_EXPLODE,true);
    PrecacheSound(SOUND_TIMER,true);
    
    GetConVarString(g_Cvardeclinesound, g_declinesound, sizeof(g_declinesound));
    if (!PrecacheSound(g_declinesound, true))
    {
        SetFailState("[KnifeFight] Could not pre-cache sound: %s", g_declinesound);
    }
    else
    {
        Format(buffer, MAX_FILE_LEN, "sound/%s", g_declinesound);
        AddFileToDownloadsTable(buffer);
    }
    
    GetConVarString(g_Cvarbeaconsound, g_beaconsound, sizeof(g_beaconsound));
    if (!PrecacheSound(g_beaconsound, true))
    {
        SetFailState("[KnifeFight] Could not pre-cache sound: %s", g_beaconsound);
    }
    else
    {
        Format(buffer, MAX_FILE_LEN, "sound/%s", g_beaconsound);
        AddFileToDownloadsTable(buffer);
    }
    
    GetConVarString(g_Cvarfightsongs, g_fightsongs, sizeof(g_fightsongs));
    if (!StrEqual(g_fightsongs, "", false))
    {
        songsfound = ExplodeString(g_fightsongs, ",", fightsong, 20, 256);
        for (new i = 0; i < songsfound; i++)
        {
            if (!PrecacheSound(fightsong[i], true))
            {
                SetFailState("[KnifeFight] Could not pre-cache sound: %s", fightsong[i]);
            }
            else
            {
                Format(buffer, MAX_FILE_LEN, "sound/%s", fightsong[i]);
                AddFileToDownloadsTable(buffer);
            }
        }
    }
    g_enabled           = GetConVarBool(g_Cvarenabled);
    g_alltalk           = GetConVarBool(g_Cvaralltalk);
    g_block             = GetConVarBool(g_Cvarblock);
    g_throwingknives    = GetConVarBool(g_Cvarthrowingknives); // MOD by Snake 60
    g_randomkill        = GetConVarBool(g_Cvarrandomkill);
    g_minplayers        = GetConVarInt(g_Cvarminplayers);
    g_useteleport       = GetConVarBool(g_Cvaruseteleport);
    g_restorehealth     = GetConVarBool(g_Cvarrestorehealth);
    g_winnerhealth      = GetConVarInt(g_Cvarwinnerhealth);
    g_winnerspeed       = GetConVarFloat(g_Cvarwinnerspeed);
    g_winnereffects     = GetConVarBool(g_Cvarwinnereffects);
    g_losereffects      = GetConVarBool(g_Cvarlosereffects);
    g_locatorbeam       = GetConVarBool(g_Cvarlocatorbeam);
    g_stopmusic         = GetConVarBool(g_Cvarstopmusic);
    g_forcefight        = GetConVarBool(g_Cvarforcefight);
    g_countdowntimer    = GetConVarInt(g_Cvarcountdowntimer);
    g_fighttimer        = GetConVarInt(g_Cvarfighttimer);
    g_beaconragius      = GetConVarFloat(g_Cvarbeaconradius);
}

SetupOffsets()
{
    g_iMyWeapons = FindSendPropOffs("CBaseCombatCharacter", "m_hMyWeapons");
    if (g_iMyWeapons == -1)
    {
        SetFailState("[KnifeFight] Error - Unable to get offset for CBaseCombatCharacter::m_hMyWeapons");
    }

    g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
    if (g_iHealth == -1)
    {
        SetFailState("[KnifeFight] Error - Unable to get offset for CSSPlayer::m_iHealth");
    }

    g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
    if (g_iAccount == -1)
    {
        SetFailState("[KnifeFight] Error - Unable to get offset for CSSPlayer::m_iAccount");
    }

    g_iSpeed = FindSendPropOffs("CCSPlayer", "m_flLaggedMovementValue");
    if (g_iSpeed == -1)
    {
        SetFailState("[KnifeFight] Error - Unable to get offset for CSSPlayer::m_flLaggedMovementValue");
    }
}

public OnAutoConfigsBuffered()
{
    g_intermission = false;
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if      (convar == g_Cvarenabled)               g_enabled           = (newValue[0] == '1');
    else if (convar == g_Cvaralltalk)               g_alltalk           = (newValue[0] == '1');
    else if (convar == g_Cvarblock)                 g_block             = (newValue[0] == '1');
    else if (convar == g_Cvarthrowingknives)        g_throwingknives    = (newValue[0] == '1'); // MOD by Snake 60
    else if (convar == g_Cvarrandomkill)            g_randomkill        = (newValue[0] == '1');
    else if (convar == g_Cvaruseteleport)           g_useteleport       = (newValue[0] == '1');
    else if (convar == g_Cvarrestorehealth)         g_restorehealth     = (newValue[0] == '1');
    else if (convar == g_Cvarwinnereffects)         g_winnereffects     = (newValue[0] == '1');
    else if (convar == g_Cvarlosereffects)          g_losereffects      = (newValue[0] == '1');
    else if (convar == g_Cvarlocatorbeam)           g_locatorbeam       = (newValue[0] == '1');
    else if (convar == g_Cvarstopmusic)             g_stopmusic         = (newValue[0] == '1');
    else if (convar == g_Cvarforcefight)            g_forcefight        = (newValue[0] == '1');
    else if (convar == g_Cvarwinnerhealth)          g_winnerhealth      = StringToInt(newValue);
    else if (convar == g_Cvarwinnerspeed)           g_winnerspeed       = StringToFloat(newValue);
    else if (convar == g_Cvarwinnermoney)           g_winnermoney       = StringToInt(newValue);
    else if (convar == g_Cvarcountdowntimer)        g_countdowntimer    = StringToInt(newValue);
    else if (convar == g_Cvarfighttimer)            g_fighttimer        = StringToInt(newValue);
    else if (convar == g_Cvarbeaconradius)          g_beaconragius      = StringToFloat(newValue);
    else if (convar == g_Cvarminplayers)            g_minplayers        = StringToInt(newValue);
    else if (convar == g_Cvar_Debug)                g_debug             = (newValue[0] == '1');
    else if (convar == g_Cvar_IsBotFightAllowed)    g_isBotFightAllowed = (newValue[0] == '1');
    else if (convar == g_Cvar_ShowWinner)           g_showWinner        = GetConVarInt(g_Cvar_ShowWinner);
    else if (convar == g_Cvar_RemoveNewPlayer)      g_removeNewPlayer   = GetConVarInt(g_Cvar_RemoveNewPlayer);
}

public Action:UserMsg_VGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
    if (g_intermission)
    {
        return Plugin_Handled;
    }
    
    decl String:type[15];

    if (BfReadString(bf, type, sizeof(type)) < 0)
    {
        return Plugin_Handled;
    }
 
    if (BfReadByte(bf) == 1 && BfReadByte(bf) == 0 && (strcmp(type, "scores", false) == 0))
    {
        g_intermission = true;
    }
    return Plugin_Handled;
}

WeaponHandler(client, teamid)
{
    if ( isFighting )
    {
        new count = 0;
        for (new i = 0; i <= 128; i += 4)
        {
            new weaponentity = -1;
            new String:weaponname[32];
            weaponentity = GetEntDataEnt2(client, (g_iMyWeapons + i));
            if ( IsValidEdict(weaponentity) )
            {
                GetEdictClassname(weaponentity, weaponname, sizeof(weaponname));
                if ( (weaponentity != -1) && !StrEqual(weaponname, "worldspawn", false) )
                {
                    if ( teamid == 3 || teamid == 2 )
                    {
                        RemovePlayerItem(client, weaponentity);
                        RemoveEdict(weaponentity);
                        if ( teamid == 3 )
                        {
                            ctitems[count++] = weaponname;
                        }
                        else if ( teamid == 2 )
                        {
                            titems[count++] = weaponname;
                        }
                    }
                }
            }
        }
    }
    else
    {
        // we have a winner, so give all its weapons we removed before
        RemoveWeapon(client, "knife");
        for ( new i = 0; i <= 7 ; i++ )
        {
            if ( IsClientInGame(client) )
            {   
                if (teamid == 3)
                {
                    if ( !StrEqual(ctitems[i], "", false) )
                    {
                        GivePlayerItem(client, ctitems[i]);
                    }
                }
                else if (teamid == 2)
                {
                    if ( !StrEqual(titems[i], "", false) )
                    {
                        GivePlayerItem(client, titems[i]);
                    }
                }
            }
        }
    }
}

public EquipKnife(client)
{
    GivePlayerItem(client, "weapon_knife");
    FakeClientCommand(client, "use weapon_knife");
}

public Action:WinnerEffects()
{
    CreateTimer(0.1, LightningTimer, _, TIMER_REPEAT);
    CreateTimer(0.6, ExplosionTimer, _, TIMER_REPEAT);
}

public Action:DelayWeapon(Handle:timer, any:data)
{
    new Handle:pack = data;
    ResetPack(pack);
    new client = ReadPackCell(pack);
    new String:item[64];
    ReadPackString(pack, item, sizeof(item));
    CloseHandle(pack);
    if ( !isFighting )
    {
        return;
    }
    RemoveWeapon(client, item);
    //WeaponHandler(clientid, 0);
}

public Action:LightningTimer(Handle:timer)
{
    if (winner != 0)
    {
        static TimesRepeated = 0;
        if (TimesRepeated++ <= 30)
        {
            Lightning();
            return Plugin_Continue;
        }
        else
        {
            TimesRepeated = 0;
            return Plugin_Stop;
        }
    }
    return Plugin_Stop;
}

public Action:ExplosionTimer(Handle:timer)
{
    if (winner != 0)
    {
        static TimesRepeated = 0;
        new Float:playerpos[3];
        if (TimesRepeated++ <= 3 && IsClientInGame(winner))
        {
            GetClientAbsOrigin(winner,playerpos);
            EmitAmbientSound(SOUND_EXPLODE, 
                playerpos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
            return Plugin_Continue;
        }
        else
        {
            TimesRepeated = 0;
            return Plugin_Stop;
        }
    }
    return Plugin_Stop;
}

public Action:KillPlayer(Handle:timer, any:clientid)
{
    if ( IsClientInGame(clientid) && IsPlayerAlive(clientid) )
    {
        if ( !isFighting && (clientid != ctid) && (clientid != tid) )
        {
            return;
        }
        if ( (g_removeNewPlayer == 1) && isFighting && (clientid != ctid) && (clientid != tid))
        {
            ChangeClientTeam(clientid, 1);
            RemoveAllWeapons();
            return;
        }
        ForcePlayerSuicide(clientid);
    }
}

public Action:SlapTimer(Handle:timer)
{
    static TimesRepeated = 0;
    if (TimesRepeated <= 1)
    {
        SlapPlayer(ctid, 0, false);
        TimesRepeated++;
        return Plugin_Continue;
    }
    else
    {
        TimesRepeated = 0;
        return Plugin_Stop;
    }
}

public Action:TeleportTimer(Handle:timer)
{
    TeleportEntity(tid, teleloc, NULL_VECTOR, NULL_VECTOR);
}

public Action:ItemsWon(Handle:timer, any:client)
{
    static TimesRepeated = 0;
    if ( !IsClientInGame(client) )
    {
        return Plugin_Stop;
    }

    if ( TimesRepeated <= 2 )
    {
        PrintHintText(client, itemswon);
        TimesRepeated++;
        return Plugin_Continue;
    }

    TimesRepeated = 0;
    itemswon = "";
    return Plugin_Stop;
}

public Action:StartFight()
{    
    // check if one player left server
    if (ctid == 0 || tid == 0)
    {
        return;
    }
    
    // check if there are only two players
    alivect = 0, alivet = 0;
    for (new i = 1; i <= MaxClients; i++)
    {
        new team;
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            team = GetClientTeam(i);
            if (team == 3) { alivect++; }
            else if (team == 2) { alivet++; }
        }
    }
    
    // check if there are only two players and round has 
    // not ended or bomb is not planted
    if (alivect != 1 || alivet != 1 || bombplanted)
    {
        return;
    }
    
    // start fight
    isFighting = true;
    g_mp_ignorerwc = FindConVar("mp_ignore_round_win_conditions"); // Added by Emper0r
    SetConVarInt(g_mp_ignorerwc, 1); // Added by Emper0r
    Trace("Fight is started.");
    if (!IsPlayerAlive(ctid) || !IsPlayerAlive(tid) || (GetClientCount() < g_minplayers))
    {
        CancelFight();
        return;
    }
    
    Trace("Removing all weapons on the map.");
    
    // remove all weapons from the map
    RemoveAllWeapons();
    
    // play fight song
    if (songsfound > 0)
    {
        new randomsong = 0;
        if (songsfound > 1)
        {
            randomsong = GetRandomInt(0, songsfound - 1);
        }
        strcopy(song, sizeof(song), fightsong[randomsong]);
        
        new clients[MaxClients];
        new total = 0;
        for (new i=1; i<=MaxClients; i++)
        {
            if (IsClientInGame(i) && g_soundPrefs[i])
            {
                clients[total++] = i;
            }
        }

        if (total)
        {
            Trace("Starting fight song.");
            EmitSound(clients, total, song, 
                _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
        }
    }
    
    Trace("Starting beacons.");
    // start beacons
    CreateTimer(2.0, StartBeacon, ctid, TIMER_REPEAT);
    CreateTimer(1.0, StartBeaconT, tid);

    // remove weapons from players
    PrintHintTextToAll("%t", "Removing weapons");
    WeaponHandler(ctid, 3);
    WeaponHandler(tid, 2);
    
    // switch alltalk
    if (g_alltalk) 
    {
        g_alltalkenabled = GetConVarBool(sv_alltalk);
        if ( !g_alltalkenabled )
        {
            SetConVarInt(sv_alltalk, 1);
        }
        g_alltalkenabled = !g_alltalkenabled;
    }
    
    // switch blocking
    if ( g_block )
    {
        if ( sm_noblock == INVALID_HANDLE )
        {
            sm_noblock = FindConVar("sm_noblock");
        }
        if ( sm_noblock != INVALID_HANDLE )
        {
            g_blockenabled = !GetConVarBool(sm_noblock);
            if ( !g_blockenabled )
            {
                SetConVarInt(sm_noblock, 0);
            }
            g_blockenabled = !g_blockenabled;
        }
    }
    // (MOD by Snake 60) switch throwingknives plugin
    if ( g_throwingknives )
    {
        if ( sm_throwingknives_enable == INVALID_HANDLE )
        {
            sm_throwingknives_enable = FindConVar("sm_throwingknives_enable");
        }
        if ( sm_throwingknives_enable != INVALID_HANDLE )
        {
            g_throwingknivesenabled = !GetConVarBool(sm_throwingknives_enable);
            if ( !g_throwingknivesenabled )
            {
                SetConVarInt(sm_throwingknives_enable, 0);
            }
            g_throwingknivesenabled = !g_throwingknivesenabled;
        }
    }

    // teleport players
    if (g_useteleport)
    {
        SetEntData(ctid, g_iHealth, 400);
        SetEntData(tid, g_iHealth, 400);
        new Float:ctvec[3];
        new Float:tvec[3];
        new Float:distance[1];
        GetClientAbsOrigin(ctid,Float:ctvec);
        GetClientAbsOrigin(tid,Float:tvec);
        distance[0] = GetVectorDistance(ctvec, tvec, true);
        if (distance[0] >= 600000.0)
        {
            teleloc = ctvec;
            CreateTimer(0.1, SlapTimer, _, TIMER_REPEAT);
            CreateTimer(0.5, TeleportTimer);
        }
        else if (g_locatorbeam)
        {
            CreateTimer(0.1, DrawBeamsTimer, _, TIMER_REPEAT);
        }
    }
    else if (g_locatorbeam)
    {
        CreateTimer(0.1, DrawBeamsTimer, _, TIMER_REPEAT);
    }
    
    // display prepare to fight
    CreateTimer(1.0, Countdown, _, TIMER_REPEAT);
}

public Action:CancelFight()
{
    ctagree = -1;
    tagree = -1;
    isFighting = false;
    g_mp_ignorerwc = FindConVar("mp_ignore_round_win_conditions"); // Added by Emper0r
    SetConVarInt(g_mp_ignorerwc, 0); // Added by Emper0r
    Trace("Fight is ended.");
    if (g_stopmusic && songsfound > 0)
    {
        new clients[MaxClients];
        new total = 0;
        for (new i=1; i<=MaxClients; i++)
        {
            if (IsClientInGame(i) && g_soundPrefs[i])
            {
                clients[total++] = i;
            }
        }

        if (total)
        {
            EmitSound(clients, total, song, 
                _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL);
        }
    }
    if (winner != 0)
    {
        if (IsPlayerAlive(winner))
        {
            WeaponHandler(winner, GetClientTeam(winner));
            for (new i = 0; i <= 7; i++)
            {
                ctitems[i] = "";
                titems[i] = "";
            }
        }
    }
}  

public Action:FightTimer(Handle:timer)
{
    if ( !isFighting )
    {
        return Plugin_Stop;
    }

    if ( fighttimer >= 0 )
    {
        PrintHintTextToAll("%t: %i", "Time remaining", fighttimer);
        if ( fighttimer < 6 ) 
        {
            EmitSoundToAll(SOUND_TIMER);
        }
        fighttimer--;
        return Plugin_Continue;
    }

    // fight draw, fight timer is up
    new healthCT = GetClientHealth(ctid);
    new healthT = GetClientHealth(tid);
    if ( healthCT == healthT )
    {
        if ( g_randomkill )
        {
            new rnd = GetRandomInt(0,1);
            if (rnd)
            {
                CreateTimer(0.1, KillPlayer, ctid);
                CreateTimer(0.1, KillPlayer, tid);
            }
            else
            {
                CreateTimer(0.1, KillPlayer, tid);
                CreateTimer(0.1, KillPlayer, ctid);
            }
        }
        else
        {
            CreateTimer(0.1, KillPlayer, ctid);
            CreateTimer(0.1, KillPlayer, tid);
        }
    }
    else
    {
        if ( healthT < healthCT )
        {
            CreateTimer(0.1, KillPlayer, tid);
        }
        else
        {
            CreateTimer(0.1, KillPlayer, ctid);
        }
    }
    PrintHintTextToAll("%t", "Fight draw");

    return Plugin_Stop;
}

public Action:Countdown(Handle:timer)
{
    if (!isFighting)
    {
        timesrepeated = g_countdowntimer;
        return Plugin_Stop;
    }
    // isFighting
    SetEntData(ctid, g_iSpeed, 1.0);
    SetEntData(tid, g_iSpeed, 1.0);

    if (timesrepeated >= 1)
    {
        PrintHintTextToAll("%t: %i", "Prepare fight", timesrepeated);
        timesrepeated--;
    }
    else
    {
        // restore players health
        if (g_restorehealth)
        {
            SetEntData(ctid, g_iHealth, 100);
            SetEntData(tid, g_iHealth, 100);
        }
        PrintHintTextToAll("%t", "Fight");

        // give players knifes
        EquipKnife(ctid);
        EquipKnife(tid);
        timesrepeated = g_countdowntimer;
        CreateTimer(1.0, FightTimer, _, TIMER_REPEAT);
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public Action:DrawBeamsTimer(Handle:timer)
{
    if ( !isFighting || !IsPlayerAlive(ctid) || !IsPlayerAlive(tid) )
    {
        return Plugin_Stop;
    }
    
    // we are fighting and alive
    new Float:ctvec[3];
    new Float:tvec[3];
    new Float:distance[1];
    new color[4] = {255, 75, 75, 255};
    GetClientEyePosition(ctid,Float:ctvec);
    GetClientEyePosition(tid,Float:tvec);
    distance[0] = GetVectorDistance(ctvec, tvec, true);
    if ( distance[0] < 200000.0 )
    {
        return Plugin_Stop;
    }

    // we are far apart
    TE_SetupBeamPoints(ctvec, tvec, g_locatebeam, g_locatehalo, 1, 1, 0.1, 5.0, 5.0, 0, 10.0, color, 255);
    TE_SendToClient(tid);
    TE_SetupBeamPoints(tvec, ctvec, g_locatebeam, g_locatehalo, 1, 1, 0.1, 5.0, 5.0, 0, 10.0, color, 255);
    TE_SendToClient(ctid);

    return Plugin_Continue;
}

public Action:StartBeaconT(Handle:timer)
{
    CreateTimer(2.0, StartBeacon, tid, TIMER_REPEAT);
}

public Action:StartBeacon(Handle:timer, any:client)
{
    if (!isFighting || !IsClientInGame(ctid) || !IsClientInGame(tid))
    {
        return Plugin_Stop;
    }

    // isFighting && both fighters alive
    new redColor[4] = {255, 75, 75, 255};
    new blueColor[4] = {75, 75, 255, 255};
    new team = GetClientTeam(client);
    new Float:vec[3];
    GetClientAbsOrigin(client, vec);
    vec[2] += 10;

    if (team == 2)
    {
        TE_SetupBeamRingPoint(vec, 10.0, g_beaconragius, g_beamsprite, g_halosprite, 
            0, 10, 1.0, 10.0, 0.0, redColor, 0, 0);
    }
    else if (team == 3)
    {
        TE_SetupBeamRingPoint(vec, 10.0, g_beaconragius, g_beamsprite, g_halosprite, 
            0, 10, 1.0, 10.0, 0.0, blueColor, 0, 0);
    }
    TE_SendToAll();

    GetClientEyePosition(client, vec);
    EmitAmbientSound(g_beaconsound, vec, client, SNDLEVEL_RAIDSIREN);  
    return Plugin_Continue;
}

public Action:VerifyConditions(Handle:timer)
{
    new Handle:warmup = INVALID_HANDLE;
    warmup = FindConVar("sm_warmupround_active");
    if (warmup != INVALID_HANDLE)
    {
        if (GetConVarBool(warmup))
        {
            return;
        }
    }
    if (g_intermission)
    {
        return;
    }
    if (ctid == 0 || tid == 0)
    {
        return;
    }
    if (GetClientCount() < g_minplayers)
    {
        return;
    }
    if ( IsClientInGame(ctid) && IsPlayerAlive(ctid) && IsClientInGame(tid) &&  IsPlayerAlive(tid) )
    {
        if ( IsFakeClient(ctid) &&  IsFakeClient(tid) )
        {
            if ( !g_isBotFightAllowed )
            {
                return;
            }
        }

        winner = 0;
        GetClientName(ctid, ctname, sizeof(ctname));
        GetClientName(tid, tname, sizeof(tname));
        PrintHintTextToAll("%t", "1v1 situation");
        if ( g_forcefight )
        {
            CreateTimer(0.5, DelayFight);
        }
        else
        {
            SendKnifeMenus(ctid,tid);
        }
    }
}

public Action:DelayFight(Handle:timer)
{
    StartFight();
}

public OnClientDisconnect(client)
{
    if ( !isFighting )
    {
        return;
    }

    if ( client == ctid )
    {
        winner = tid;
        loser = tid;
        CancelFight();
    }
    else if ( client == tid )
    {
        winner = ctid;
        loser = ctid;
        CancelFight();
    }
}

public EventRoundStart(Handle:event, const String:name[],bool:dontBroadcast)
{
    if ( !g_enabled )
    {
        return;
    }
    if ( g_alltalk && g_alltalkenabled ) 
    {
        g_alltalkenabled = false;
        SetConVarInt(sv_alltalk, 0);
    }
    // switch blocking
    if ( g_block && g_blockenabled )
    {
        g_blockenabled = false;
        if ( sm_noblock == INVALID_HANDLE )
        {
            sm_noblock = FindConVar("sm_noblock");
        }
        if ( sm_noblock != INVALID_HANDLE )
        {
            SetConVarInt(sm_noblock, 1);
        }
    }
    
    //(MOD by Snake 60) switch throwingknives plugin
    if ( g_throwingknives && g_throwingknivesenabled )
    {
        g_throwingknivesenabled = true;
        if ( sm_throwingknives_enable == INVALID_HANDLE )
        {
            sm_throwingknives_enable = FindConVar("sm_throwingknives_enable");
        }
        if ( sm_throwingknives_enable != INVALID_HANDLE )
        {
            SetConVarInt(sm_throwingknives_enable, 1);
        }
    }
    
    if (isFighting)
    {
        // HINT: CancelFight gives weapons to winner!
        // We will be here after warmup end.
        // Winner is 0, so no extra weapon will be given.
        CancelFight();
    }
    ctname          = "";
    tname           = "";
    winnername      = "";
    losername       = "";
    alivect         = 0;
    alivet          = 0;
    ctid            = 0;
    tid             = 0;
    loser           = 0;
    bombplanted     = false;
    timesrepeated   = g_countdowntimer;
    fighttimer      = g_fighttimer;
}

public EventBombPlanted(Handle:event, const String:name[],bool:dontBroadcast)
{
    if ( g_enabled )
    {
        bombplanted = true;
    }
}

public Action:EventItemPickup(Handle:event, const String:name[],bool:dontBroadcast)
{
    if ( !g_enabled || !isFighting )
    {
        return;
    }

    new clientid = GetClientOfUserId(GetEventInt(event, "userid"));
    if ( clientid == ctid || clientid == tid )
    {
        new String:item[64];
        GetEventString(event, "item", item, sizeof(item));
        if ( !StrEqual(item, "knife", false) )
        {
            FakeClientCommand(clientid, "use weapon_knife");
            // HINT: delay is needed to check isFighting 
            // before weapon remove and also
            // to prevent crashes with Gungame4 Turbo
            new Handle:pack = CreateDataPack();
            WritePackCell(pack, clientid);
            WritePackString(pack, item);
            CreateTimer(0.1, DelayWeapon, pack);
        }
    }
}

UTIL_PrintToUpperLeft(client, r, g, b, const String:source[], any:...)
{
    if (client && IsFakeClient(client))
    {
        return;
    }

    decl String:Buffer[56];
    VFormat(Buffer, sizeof(Buffer), source, 6);

    new Handle:Msg = CreateKeyValues("msg");

    if(Msg != INVALID_HANDLE)
    {
        KvSetString(Msg, "title", Buffer);
        KvSetColor(Msg, "color", r, g, b, 255);
        KvSetNum(Msg, "level", 0);
        KvSetNum(Msg, "time", 10);

        if(client == 0)
        {
            for(new i = 1; i <= MaxClients; i++)
            {
                if(IsClientInGame(i))
                {
                    CreateDialog(i, Msg, DialogType_Msg);
                }
            }
        }
        else
        {
            CreateDialog(client, Msg, DialogType_Msg);
        }

        CloseHandle(Msg);
    }
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
    alivect = 0, alivet = 0;
    if (g_enabled && isFighting)
    {
        loser = GetClientOfUserId(GetEventInt(event, "userid"));
        if (loser == ctid || loser == tid)
        {
            winner = GetClientOfUserId(GetEventInt(event, "attacker"));
            if ( (winner != loser) && (winner != 0) )
            {
                if (g_losereffects)
                {
                    CreateTimer(0.4, DissolveRagdoll, loser);
                }
                g_winnerid = winner;
                GetClientName(winner, winnername, sizeof(winnername));
                
                if ( g_showWinner == 0 )
                {
                    new team = GetClientTeam(winner);
                    new r = (team == TEAM_T ? 255 : 0);
                    new g =  team == TEAM_CT ? 128 : (team == TEAM_T ? 0 : 255);
                    new b = (team == TEAM_CT ? 255 : 0);
                    UTIL_PrintToUpperLeft(0, r, g, b, "[Knife Fight] %s %t", winnername, "has won");
                }
                else if ( g_showWinner == 1 )
                {
                    new String:msg[MAX_CHAT_SIZE];
                    Format(msg, sizeof(msg), "%c[%cKnife Fight%c] %c%s %c%t",
                        GREEN, YELLOW, GREEN, isColorMsg ? TEAMCOLOR : YELLOW, winnername, GREEN, "has won");
                    CHAT_SayText(0, winner, msg);
                }
                
                if (g_winnereffects)
                {
                    WinnerEffects();
                }
                CancelFight();
            }
            else
            // winner == loser
            {
                if (ctid == loser)
                {
                    winner = tid;
                    CancelFight();
                }
                else if (tid == loser)
                {
                    winner = ctid;
                    CancelFight();
                }
            }
        }
    }  
    else if (g_enabled && !isFighting)
    {
        for (new i = 1; i <= MaxClients; i++)
        {
            new team;
            if (IsClientInGame(i) && IsPlayerAlive(i))
            {
                team = GetClientTeam(i);
                if (team == 3) { ctid = i; alivect++; }
                else if (team == 2) { tid = i; alivet++; }
            }
        }
        if (alivect == 1 && alivet == 1 && !bombplanted)
        {
            CreateTimer(0.5, VerifyConditions);
        }
    }
}

public EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
    if ( !g_enabled )
    {
        return;
    }
    // g_enabled == true
    new clientid = GetClientOfUserId(GetEventInt(event, "userid"));
    if ( isFighting )
    {
        CreateTimer(0.1, KillPlayer, clientid);
        return;
    }
    // isFighting == false
    if ( clientid == g_winnerid )
    {
        if ( g_winnerhealth > 0 || g_winnermoney > 0 || g_winnerspeed > 0 )
        {
            new String:buffer[256];
            Format(buffer, sizeof(buffer), "%t:\n\n", "Items won");
            StrCat(itemswon, sizeof(itemswon), buffer);
            if (g_winnerhealth > 0)
            {
                SetEntData(clientid, g_iHealth, g_winnerhealth);
                Format(buffer, sizeof(buffer), "%t: %i\n", "Health", g_winnerhealth);
                StrCat(itemswon, sizeof(itemswon), buffer);
            }
            if (g_winnermoney > 0)
            {
                new totalmoney = GetEntData(clientid, g_iAccount) + g_winnermoney;
                SetEntData(clientid, g_iAccount, totalmoney);
                Format(buffer, sizeof(buffer), " %t: $%i\n", "Money", g_winnermoney);
                StrCat(itemswon, sizeof(itemswon), buffer);
            }
            if (g_winnerspeed > 0)
            {
                SetEntData(clientid, g_iSpeed, g_winnerspeed);
                Format(buffer, sizeof(buffer), "%t: %.2fx", "Speed", g_winnerspeed);
                StrCat(itemswon, sizeof(itemswon), buffer);
            }
            CreateTimer(1.0, ItemsWon, clientid, TIMER_REPEAT);
            g_winnerid = 0;
        }
    }
}

public Action:DissolveRagdoll(Handle:timer, any:client)
{
    if (!IsValidEntity(client) || IsPlayerAlive(client))
    {
        return;
    }

    new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

    if (ragdoll < 0)
    {
        return;
    }

    new String:dname[32];
    Format(dname, sizeof(dname), "dis_%d", client);

    new entid = CreateEntityByName("env_entity_dissolver");

    if (entid > 0)
    {
        DispatchKeyValue(ragdoll, "targetname", dname);
        DispatchKeyValue(entid, "dissolvetype", "0");
        DispatchKeyValue(entid, "target", dname);
        AcceptEntityInput(entid, "Dissolve");
        AcceptEntityInput(entid, "kill");
    }
}

SendKnifeMenus(ct,t)
{
    ctagree = -1;
    tagree = -1;

    new String:msg[MAX_CHAT_SIZE];
    if (IsFakeClient(ct) || g_fightPrefs[ct] == 1)
    {
        Format(msg, sizeof(msg), "%c[%cKnife Fight%c] %c%s %c%t",
            GREEN, YELLOW, GREEN, isColorMsg ? TEAMCOLOR : YELLOW, ctname, GREEN, "Player agrees");
        CHAT_SayText(0, ct, msg);
        ctagree = 1;
    }
    else if (g_fightPrefs[ct] == -1)
    {
        Format(msg, sizeof(msg), "%c[%cKnife Fight%c] %c%s %c%t",
            GREEN, YELLOW, GREEN, isColorMsg ? TEAMCOLOR : YELLOW, ctname, GREEN, "Player disagrees");
        CHAT_SayText(0, ct, msg);
        ctagree = 0;
        EmitSoundToAll(g_declinesound);
    }
    else
    {
        SendKnifeMenu(ct);
    }

    if (IsFakeClient(t) || g_fightPrefs[t] == 1)
    {
        Format(msg, sizeof(msg), "%c[%cKnife Fight%c] %c%s %c%t",
            GREEN, YELLOW, GREEN, isColorMsg ? TEAMCOLOR : YELLOW, tname, GREEN, "Player agrees");
        CHAT_SayText(0, t, msg);
        tagree = 1;
    }
    else if (g_fightPrefs[t] == -1)
    {
        Format(msg, sizeof(msg), "%c[%cKnife Fight%c] %c%s %c%t",
            GREEN, YELLOW, GREEN, isColorMsg ? TEAMCOLOR : YELLOW, tname, GREEN, "Player disagrees");
        CHAT_SayText(0, t, msg);
        tagree = 0;
        EmitSoundToAll(g_declinesound);
    }
    else
    {
        SendKnifeMenu(t);
    }
    
    if ( ctagree == 1 && tagree == 1)
    {
        Format(msg, sizeof(msg), "%c[%cKnife Fight%c] %c%t",
            GREEN, YELLOW, GREEN, GREEN, "Both agree");
        CHAT_SayText(0, 0, msg);
        CreateTimer(0.5, DelayFight);
    }
}

SendKnifeMenu(client)
{
    new String:title[128];
    new String:question[128];
    new String:yes[128];
    new String:no[128];
    Format(title,127, "%t", "Knife menu title");
    Format(question,127, "%t", "Knife question");
    Format(yes,127, "%t", "Yes option");
    Format(no,127, "%t", "No option");

    new Handle:panel = CreatePanel();  
    SetPanelTitle(panel,title);
    DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
    DrawPanelText(panel,question);
    DrawPanelText(panel, "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~");
    DrawPanelItem(panel,yes);
    DrawPanelItem(panel,no);
    DrawPanelText(panel, "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~");
    SendPanelToClient(panel, client, PanelHandler, 10);
    CloseHandle(panel);
}

public PanelHandler(Handle:menu, MenuAction:action, client, item)
{
    new String:msg[MAX_CHAT_SIZE];
    if (action == MenuAction_Select)
    {
        if (item == 1 && client != 0)
        {
            if (GetClientTeam(client) == 3 && client == ctid && IsClientInGame(tid) && IsPlayerAlive(tid))
            {
                Format(msg, sizeof(msg), "%c[%cKnife Fight%c] %c%s %c%t",
                    GREEN, YELLOW, GREEN, isColorMsg ? TEAMCOLOR : YELLOW, ctname, GREEN, "Player agrees");
                CHAT_SayText(0, client, msg);
                ctagree = 1;
            } 
            else if (GetClientTeam(client) == 2 && client == tid && IsClientInGame(ctid) && IsPlayerAlive(ctid))
            {
                Format(msg, sizeof(msg), "%c[%cKnife Fight%c] %c%s %c%t",
                    GREEN, YELLOW, GREEN, isColorMsg ? TEAMCOLOR : YELLOW, tname, GREEN, "Player agrees");
                CHAT_SayText(0, client, msg);
                tagree = 1;
            }
        }
        else if (item == 2 && client != 0)
        {
            if (GetClientTeam(client) == 3 && client == ctid && IsClientInGame(tid) && IsPlayerAlive(tid))
            {
                Format(msg, sizeof(msg), "%c[%cKnife Fight%c] %c%s %c%t",
                    GREEN, YELLOW, GREEN, isColorMsg ? TEAMCOLOR : YELLOW, ctname, GREEN, "Player disagrees");
                CHAT_SayText(0, client, msg);
                ctagree = 0;
                EmitSoundToAll(g_declinesound);
            } 
            else if (GetClientTeam(client) == 2 && client == tid && IsClientInGame(ctid) && IsPlayerAlive(ctid))
            {
                Format(msg, sizeof(msg), "%c[%cKnife Fight%c] %c%s %c%t",
                    GREEN, YELLOW, GREEN, isColorMsg ? TEAMCOLOR : YELLOW, tname, GREEN, "Player disagrees");
                CHAT_SayText(0, client, msg);
                tagree = 0;
                EmitSoundToAll(g_declinesound);
            }
        }
    }
    else if ( action == MenuAction_Cancel )
    {
        if ( IsClientInGame(client) && IsPlayerAlive(client) )
        {
            Format(msg, sizeof(msg), "%c[%cKnife Fight%c] %c%t %c!kfmenu %c%t %c2 %c%t",
                GREEN, YELLOW, GREEN, GREEN, "Say", YELLOW, GREEN, "And press", YELLOW, GREEN, "Restore fight menu");
            CHAT_SayText(client, 0, msg);
        }
    }

    if ( ctagree == 1 && tagree == 1 )
    {
        Format(msg, sizeof(msg), "%c[%cKnife Fight%c] %c%t",
            GREEN, YELLOW, GREEN, GREEN, "Both agree");
        CHAT_SayText(0, 0, msg);
        StartFight();
    }
}

Lightning()
{
    if ( !IsClientInGame(winner) || !IsPlayerAlive(winner) )
    {
        return;
    }
    new Float:playerpos[3];
    GetClientAbsOrigin(winner,playerpos);
    new Float:toppos[3];
    toppos[0]                       = playerpos[0];
    toppos[1]                       = playerpos[1];
    toppos[2]                       = playerpos[2]+1000;
    new lightningcolor[4];
    lightningcolor[0]               = 255;
    lightningcolor[1]               = 255;
    lightningcolor[2]               = 255;
    lightningcolor[3]               = 255;
    new Float:lightninglife         = 0.1;
    new Float:lightningwidth        = 40.0;
    new Float:lightningendwidth     = 10.0;
    new lightningstartframe         = 0;
    new lightningframerate          = 20;
    new lightningfadelength         = 1;
    new Float:lightningamplitude    = 20.0;
    new lightningspeed              = 250;
    TE_SetupBeamPoints(toppos, playerpos, g_lightning, g_lightning, 
        lightningstartframe, lightningframerate, lightninglife, lightningwidth, lightningendwidth, 
        lightningfadelength, lightningamplitude, lightningcolor, lightningspeed);
    TE_SendToAll(0.0);
}

RemoveWeapon(client, String:weapon[])
{
    new slot, curr_weapon;
    GetTrieValue(g_WeaponSlots, weapon, slot);
    curr_weapon = GetPlayerWeaponSlot(client, slot);

    if(client == 0 || !IsValidEntity(curr_weapon))
    {
        return;
    }
    RemovePlayerItem(client, curr_weapon);
}

public OnClientPutInServer(client)
{
    g_soundPrefs[client] = GetConVarInt(g_Cvar_SoundPrefDefault);
    g_fightPrefs[client] = 0;

    if(!IsFakeClient(client))
    {   
        if (AreClientCookiesCached(client))
        {
            loadClientCookies(client);
        } 
    }
}

public OnClientCookiesCached(client)
{
    if(IsClientInGame(client) && !IsFakeClient(client))
    {
        loadClientCookies(client);  
    }
}

loadClientCookies(client)
{
    decl String:buffer[5];
    GetClientCookie(client, g_Cookie_SoundPref, buffer, 5);
    if(!StrEqual(buffer, ""))
    {
        g_soundPrefs[client] = StringToInt(buffer);
    }
    GetClientCookie(client, g_Cookie_FightPref, buffer, 5);
    if(!StrEqual(buffer, ""))
    {
        g_fightPrefs[client] = StringToInt(buffer);
    }
}


public MenuHandlerKnifeFight(Handle:menu, MenuAction:action, client, item)
{
    if(action == MenuAction_Select) 
    {
        if(item == 0)
        {
            g_soundPrefs[client] = g_soundPrefs[client] ? 0 : 1;
            decl String:buffer[5];
            IntToString(g_soundPrefs[client], buffer, 5);
            SetClientCookie(client, g_Cookie_SoundPref, buffer);
            MenuKnifeFight(client, 0);
        }
        else if(item == 1)
        {
            if ( !isFighting && (tid == client || ctid==client) && alivect == 1 && alivet == 1 && (GetClientCount() >= g_minplayers) )
            {
                SendKnifeMenu(client);
            }
            else
            {
                MenuKnifeFight(client, 0);
            }
        }
        else if (item == 2 || item == 3)
        {
            if ( ( item == 2 && g_fightPrefs[client] == 1 ) || ( item == 3 && g_fightPrefs[client] == -1 ) )
            {
                g_fightPrefs[client] = 0;
            }
            else
            {
                g_fightPrefs[client] = item == 2 ? 1 : -1;
            }
            decl String:buffer[5];
            IntToString(g_fightPrefs[client], buffer, 5);
            SetClientCookie(client, g_Cookie_FightPref, buffer);
            MenuKnifeFight(client, 0);
        }
    } 
    else if(action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}
 
public Action:MenuKnifeFight(client, args)
{
    new Handle:menu = CreateMenu(MenuHandlerKnifeFight);
    decl String:buffer[64];

    Format(buffer, sizeof(buffer), "%t", "KnifeFight settings");
    SetMenuTitle(menu, buffer);

    Format(buffer, sizeof(buffer), "%t %t", "Play fight songs", 
        g_soundPrefs[client] ? "Selected" : "NotSelected");
    AddMenuItem(menu, "Play fight songs", buffer);
    Format(buffer, sizeof(buffer), "%t", "Show fight panel");
    AddMenuItem(menu, "Show fight panel", buffer, 
        ( !isFighting && (tid == client || ctid==client) && alivect == 1 && alivet == 1 && (GetClientCount() >= g_minplayers) ) 
            ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "%t %t", "Always agree to knife fight", 
        g_fightPrefs[client] == 1 ? "Selected" : "NotSelected");
    AddMenuItem(menu, "Always agree to knife fight", buffer);    
    Format(buffer, sizeof(buffer), "%t %t", "Always disagree to knife fight", 
        g_fightPrefs[client] == -1 ? "Selected" : "NotSelected");
    AddMenuItem(menu, "Always disagree to knife fight", buffer);    

    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 20);
    return Plugin_Handled;
}

public Trace(const String:text[])
{
    if ( g_debug )
    {
        LogError("[DEBUG] %s", text);
    }
}

RemoveAllWeapons()
{
    new maxent = GetMaxEntities(), String:weapon[64];
    for (new i=MaxClients;i<maxent;i++)
    {
        if ( IsValidEdict(i) && IsValidEntity(i) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
        {
            GetEdictClassname(i, weapon, sizeof(weapon));
            if (    StrContains(weapon, "weapon_") != -1                // remove weapons
                    || StrEqual(weapon, "hostage_entity", true)         // remove hostages
                    || StrContains(weapon, "item_") != -1           )   // remove bombs
            {
                RemoveEdict(i);
            }
        }
    }
}    
