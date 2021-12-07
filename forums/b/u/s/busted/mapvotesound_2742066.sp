#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <emitsoundany>
#include <mapchooser>

#define VERSION "1.0"
#pragma semicolon 1

ConVar g_SoundStart;
ConVar g_SoundEnd;
//ConVar g_SoundFailure;

char g_vSoundStart[PLATFORM_MAX_PATH];
char g_vSoundEnd[PLATFORM_MAX_PATH];
//char g_vSoundFailure[PLATFORM_MAX_PATH];
char sBuffer[PLATFORM_MAX_PATH];
char eBuffer[PLATFORM_MAX_PATH];
//char fBuffer[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
    name = "Map Vote Sound",
    author = "Busted",
    description = "Play a sound when Start/end map vote",
    version = VERSION,
    url = "https://attawaybaby.com/"
};

public void OnPluginStart()
{
    CreateConVar("sm_mvs_version", VERSION, "Map Vote Sound Version.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_SoundStart = CreateConVar("sm_vmstart", "attawaybaby/vote/vote_started.mp3", "Path of map vote START sound. Don't include Sound folder in the path");
    g_SoundEnd = CreateConVar("sm_vmstop", "attawaybaby/vote/vote_success.mp3", "Path of map vote END sound. Don't include Sound folder in the path");
    //g_SoundFailure = CreateConVar("sm_vmfail", "attawaybaby/vote/vote_failure.mp3", "Path of map vote FAILURE sound. Don't include Sound folder in the path");

    AutoExecConfig(true, "mapvotesound");

    //Start
    GetConVarString(g_SoundStart, g_vSoundStart, sizeof(g_vSoundStart));
    Format(sBuffer, sizeof(sBuffer), "sound/%s", g_vSoundStart);


    //End
    GetConVarString(g_SoundEnd, g_vSoundEnd, sizeof(g_vSoundEnd));
    Format(eBuffer, sizeof(eBuffer), "sound/%s", g_vSoundEnd);

    //Failure
    //GetConVarString(g_SoundFailure, g_vSoundFailure, sizeof(g_vSoundFailure));
    //Format(fBuffer, sizeof(fBuffer), "sound/%s", g_vSoundFailure);


}
public OnConfigsExecuted()
{
    PrecacheSoundAny(g_vSoundStart);
    PrecacheSoundAny(g_vSoundEnd);
//    PrecacheSoundAny(g_vSoundFailure);
    AddFileToDownloadsTable(sBuffer);
    AddFileToDownloadsTable(eBuffer);
//    AddFileToDownloadsTable(fBuffer);
}
public OnMapVoteStarted()
{
    EmitSoundToAllAny(g_vSoundStart);
    CreateTimer(0.1, timerCheckVoteEnd, _, TIMER_REPEAT);
}

public Action timerCheckVoteEnd(Handle timer) 
{
    if (HasEndOfMapVoteFinished()) 
    {
        EmitSoundToAllAny(g_vSoundEnd);
        return Plugin_Stop;
    }
    return Plugin_Continue;
}