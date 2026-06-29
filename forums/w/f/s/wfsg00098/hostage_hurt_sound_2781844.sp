#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Badegg"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <emitsoundany>

public Plugin myinfo = 
{
	name = "[CS:GO] Hostage hurt sound", 
	author = PLUGIN_AUTHOR, 
	description = "play sound when hostage hurts", 
	version = PLUGIN_VERSION, 
	url = "guaiqihen.com"
};

public void OnPluginStart()
{
	HookEvent("hostage_hurt", OnHostageHurt, EventHookMode_Post);
}	

public void OnMapStart()
{
	DownloadAndPre();
}

public void OnHostageHurt(Event e, const char[] name, bool dontBroadcast)
{
	float origin[3];
	int hostage_id = GetEventInt(e, "hostage");
	GetEntPropVector(hostage_id, Prop_Data, "m_vecOrigin", origin, 0);
	char path[256];
	int sound_id = GetRandomInt(1,6);
	Format(path, 256, "hostage_hurt/hpain%d.mp3", sound_id);
	EmitAmbientSoundAny(path, origin);

}


void DownloadAndPre()
{
	PrecacheSoundAny("hostage_hurt/hpain1.mp3");
	AddFileToDownloadsTable("sound/hostage_hurt/hpain1.mp3");
	PrecacheSoundAny("hostage_hurt/hpain2.mp3");
	AddFileToDownloadsTable("sound/hostage_hurt/hpain2.mp3");
	PrecacheSoundAny("hostage_hurt/hpain3.mp3");
	AddFileToDownloadsTable("sound/hostage_hurt/hpain3.mp3");
	PrecacheSoundAny("hostage_hurt/hpain4.mp3");
	AddFileToDownloadsTable("sound/hostage_hurt/hpain4.mp3");
	PrecacheSoundAny("hostage_hurt/hpain5.mp3");
	AddFileToDownloadsTable("sound/hostage_hurt/hpain5.mp3");
	PrecacheSoundAny("hostage_hurt/hpain6.mp3");
	AddFileToDownloadsTable("sound/hostage_hurt/hpain6.mp3");
}


