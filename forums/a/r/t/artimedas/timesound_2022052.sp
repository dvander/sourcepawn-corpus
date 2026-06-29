#include <sdktools>
#include <sourcemod>
#include <colors>
//--------------pragma---------------
#pragma semicolon 1
new Handle:g_hRoundTime; // Store timer
new m_iRoundTime;
new Float:m_fRoundStartTime;
new roundtimeleft;

//--------------plugin---------------
new String:UctSoundList[][PLATFORM_MAX_PATH]=
{
        "phantommunity/music/uct.mp3",
        "phantommunity/music/uct1.mp3",
        "phantommunity/music/uct2.mp3",
		"phantommunity/music/uct3.mp3",
		"phantommunity/music/uct4.mp3"
};
 
public Plugin:myinfo = {
        name = "Tempo Esaurito",
        author = "Master & Thunder",
        version = "1.4",
        description = "Plugin ultimo CT",
        url = "http://phantommunity.it"
};
 

 
public OnPluginStart( )
{
    HookEventEx("round_freeze_end", rounds);
    HookEventEx("round_start", rounds);
    HookEventEx("round_end", rounds);
}
 
public OnMapStart()
{
        decl String:downloadpath[PLATFORM_MAX_PATH];
        for(new i=0; i<sizeof(UctSoundList); i++)
        {
                PrecacheSound(UctSoundList[i],true);
                Format(downloadpath,PLATFORM_MAX_PATH,"sound/%s",UctSoundList[i]);
                AddFileToDownloadsTable(downloadpath);
        }
}

public rounds(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(g_hRoundTime != INVALID_HANDLE) // Timer is unfinished!
    {
        KillTimer(g_hRoundTime);
        g_hRoundTime = INVALID_HANDLE;
    }

    if(StrEqual(name, "round_freeze_end", false))
    {
        m_iRoundTime = GameRules_GetProp("m_iRoundTime");
        m_fRoundStartTime = GetGameTime();

        g_hRoundTime = CreateTimer(1.0, RoundTime, _, TIMER_REPEAT);
    }
}

public Action:RoundTime(Handle:timer)
{
    roundtimeleft = (RoundToNearest(m_fRoundStartTime) + m_iRoundTime) - RoundToNearest(GetGameTime());

    if(roundtimeleft <= 0)
    {
        g_hRoundTime = INVALID_HANDLE; // First priority, clear Handle when timer executed last time!
        new UctCurrentSound;
        UctCurrentSound = GetRandomInt(1, sizeof(UctSoundList));
        PrintCenterTextAll(".::ULTIMO CT::.");
        CPrintToChatAll("{green} ==================");
        CPrintToChatAll("{green}   ==== {blue}ULTIMO CT {green}====");
        CPrintToChatAll("{green} ==================");
        EmitSoundToAll(UctSoundList[UctCurrentSound]);
        return Plugin_Stop; // stop timer
    }
    return Plugin_Continue;
}
