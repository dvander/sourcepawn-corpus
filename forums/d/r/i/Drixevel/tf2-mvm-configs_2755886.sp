#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

ConVar convar_Config_WaveStart;
ConVar convar_Config_WaveEnd;
ConVar convar_Config_WaveFailed;

public Plugin myinfo = 
{
	name = "[TF2] MvM Configs", 
	author = "Drixevel", 
	description = "Executes certain configuration files whenever MvM waves start and complete.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	convar_Config_WaveStart = CreateConVar("sm_mvm_configs_wave_start", "wave_start", "What configuration file should be executed at the start of waves?", FCVAR_NOTIFY);
	convar_Config_WaveEnd = CreateConVar("sm_mvm_configs_wave_end", "wave_end", "What configuration file should be executed at the end of waves?", FCVAR_NOTIFY);
	convar_Config_WaveFailed = CreateConVar("sm_mvm_configs_wave_failed", "wave_failed", "What configuration file should be executed if a wave fails?", FCVAR_NOTIFY);
	AutoExecConfig();

	HookEvent("mvm_begin_wave", Event_OnWaveStart);
	HookEvent("mvm_wave_complete", Event_OnWaveComplete);
	HookEvent("mvm_wave_failed", Event_OnWaveFailed);
}

public void Event_OnWaveStart(Event event, const char[] name, bool dontBroadcast)
{
	char sConfig[PLATFORM_MAX_PATH];
	convar_Config_WaveStart.GetString(sConfig, sizeof(sConfig));

	if (strlen(sConfig) > 0)
		ServerCommand("exec %s", sConfig);
}

public void Event_OnWaveComplete(Event event, const char[] name, bool dontBroadcast)
{
	char sConfig[PLATFORM_MAX_PATH];
	convar_Config_WaveEnd.GetString(sConfig, sizeof(sConfig));

	if (strlen(sConfig) > 0)
		ServerCommand("exec %s", sConfig);
}

public void Event_OnWaveFailed(Event event, const char[] name, bool dontBroadcast)
{
	char sConfig[PLATFORM_MAX_PATH];
	convar_Config_WaveFailed.GetString(sConfig, sizeof(sConfig));

	if (strlen(sConfig) > 0)
		ServerCommand("exec %s", sConfig);
}