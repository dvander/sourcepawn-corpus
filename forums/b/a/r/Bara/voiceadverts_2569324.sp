/**
 * =============================================================================
 * Cep>|< - Russian BugTrack group Voice Adverts Plugin
 * Playing voice messages to players.
 *
 * Cep>|< - Russian BugTrack group (C) 2010
 * =============================================================================
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <emitsoundany>

#pragma newdecls required

#define NUM_SOUNDS 32
#define PLUGIN_VERSION "1.1"

public Plugin myinfo =
{
	name = "Voice Adverts",
	author = "Cep>|< & Bara",
	description = "Voice Adverts",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

ConVar g_CvarEnabled = null;
char g_soundsList[1][NUM_SOUNDS][PLATFORM_MAX_PATH];
char ConfigFile[PLATFORM_MAX_PATH];
Handle g_vAdvertTimer = null;
ConVar g_vAdvertTime = null;
int MaxSounds;
int nAdvert = 0;

public void OnPluginStart()
{
	g_CvarEnabled = CreateConVar("sm_voiceadverts", "1", "Enable/disable Voice Adverts plugi");
	g_vAdvertTime = CreateConVar("sm_voiceadverts_time", "300", "Duration between voice adverts (in seconds)");
	CreateConVar("sm_voiceadverts_version", PLUGIN_VERSION, "Voice Adverts version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "voiceadverts");
	LoadAdvSounds();
}
public void OnMapStart()
{
	if(!g_CvarEnabled.BoolValue)
	{
		return;
	}
	
	nAdvert = 0;
	
	for(int i = 1; i <= MaxSounds; i++)
	{
		PrepareSound(i);
	}
	
	g_vAdvertTimer = CreateTimer(g_vAdvertTime.FloatValue, PlayVoiceAdv);
}
public Action PlayVoiceAdv(Handle timer)
{
	if(!g_CvarEnabled.BoolValue)
	{
		return;
	}
	
	g_vAdvertTimer = CreateTimer(g_vAdvertTime.FloatValue, PlayVoiceAdv);
	
	nAdvert++;
	
	EmitSoundToAllAny(g_soundsList[0][nAdvert]);
	if (nAdvert > MaxSounds)
	{
		nAdvert = 0;
	}
}
public void OnMapEnd()
{
	delete g_vAdvertTimer;
}

void LoadAdvSounds()
{
	BuildPath(Path_SM,ConfigFile,sizeof(ConfigFile),"configs/va_sound_list.cfg");
	
	if(!FileExists(ConfigFile))
	{
		LogMessage("va_sound_list.cfg not parsed...file doesn't exist!");
	}
	else
	{
		Handle filehandle = OpenFile(ConfigFile, "r");
		char buffer[32];
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
void PrepareSound(int sound)
{
	char downloadFile[PLATFORM_MAX_PATH];
	
	if(!StrEqual(g_soundsList[0][sound], ""))
	{
		Format(downloadFile, PLATFORM_MAX_PATH, "sound/%s", g_soundsList[0][sound]);
		
		if(!FileExists(downloadFile,true) && !FileExists(downloadFile,false))
		{
			LogError("[Voice Adverts] File not found - %s" , g_soundsList[0][sound]);
			return;
		}
		
		PrecacheSoundAny(g_soundsList[0][sound]);
		AddFileToDownloadsTable(downloadFile);
	}
	else
	{
		LogError("[Voice Adverts] Failed loading file - %s" , g_soundsList[0][sound]);
	}
}