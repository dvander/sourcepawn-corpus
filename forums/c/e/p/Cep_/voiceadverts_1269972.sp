/**
 * =============================================================================
 * Cep>|< - Russian BugTrack group Voice Adverts Plugin
 * Playing voice messages to players.
 *
 * Cep>|< - Russian BugTrack group (C) 2010
 * =============================================================================
 */
#pragma semicolon 1

#include <sdktools>

#define NUM_SOUNDS 32
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Voice Adverts",
	author = "Cep>|< - Russian BugTrack group",
	description = "Voice Adverts",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:g_CvarEnabled = INVALID_HANDLE;
new String:g_soundsList[1][NUM_SOUNDS][PLATFORM_MAX_PATH];
new String:ConfigFile[PLATFORM_MAX_PATH];
new Handle:g_vAdvertTimer = INVALID_HANDLE;
new Handle:g_vAdvertTime = INVALID_HANDLE;
new MaxSounds;
new nAdvert = 0;

public OnPluginStart()
{   g_CvarEnabled = CreateConVar("sm_voiceadverts", "1", "Enable/disable Voice Adverts plugi");
    g_vAdvertTime = CreateConVar("sm_voiceadverts_time", "300", "Duration between voice adverts (in seconds)");
    CreateConVar("sm_voiceadverts_version", PLUGIN_VERSION, "Voice Adverts version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    AutoExecConfig(true, "voiceadverts");
    LoadAdvSounds();
}
public OnMapStart()
{   if(!GetConVarBool(g_CvarEnabled)) return;
    nAdvert = 0;
    for(new i = 1; i <= MaxSounds; i++)
    {
    	PrepareSound(i);
	}
    g_vAdvertTimer = CreateTimer(float(GetConVarInt(g_vAdvertTime)), PlayVoiceAdv);
}
public Action:PlayVoiceAdv(Handle:timer){
    g_vAdvertTimer = CreateTimer(float(GetConVarInt(g_vAdvertTime)), PlayVoiceAdv);
    if(!GetConVarBool(g_CvarEnabled)) return;
    nAdvert++;
    EmitSoundToAll(g_soundsList[0][nAdvert]);
    if (nAdvert > MaxSounds) nAdvert = 0;
}
public OnMapEnd()
{
	if(g_vAdvertTimer != INVALID_HANDLE)
	{
		KillTimer(g_vAdvertTimer);
		g_vAdvertTimer = INVALID_HANDLE;
	}
}
LoadAdvSounds()
{
	BuildPath(Path_SM,ConfigFile,sizeof(ConfigFile),"configs/va_sound_list.cfg");
	if(!FileExists(ConfigFile)) {
		LogMessage("va_sound_list.cfg not parsed...file doesn't exist!");
	}else{
        new Handle:filehandle = OpenFile(ConfigFile, "r");
        decl String:buffer[32];
        while(!IsEndOfFile(filehandle))
		{
            ReadFileLine(filehandle, buffer, sizeof(buffer));
            TrimString(buffer);
            if(buffer[0] == '/' || buffer[0] == '\0') continue;
            MaxSounds++;
            g_soundsList[0][MaxSounds] = buffer;
 		}
	CloseHandle(filehandle);
	}
}
public PrepareSound(sound)
{
	new String:downloadFile[PLATFORM_MAX_PATH];

	if(!StrEqual(g_soundsList[0][sound], ""))
	{   Format(downloadFile, PLATFORM_MAX_PATH, "sound/%s", g_soundsList[0][sound]);
            if(!FileExists(downloadFile,true) && !FileExists(downloadFile,false)){
            LogError("[Voice Adverts] File not found - %s" , g_soundsList[0][sound]);
            return;
            }
            PrecacheSound(g_soundsList[0][sound], true);
            AddFileToDownloadsTable(downloadFile);
	}else{
        LogError("[Voice Adverts] Failed loading file - %s" , g_soundsList[0][sound]);
    }
}