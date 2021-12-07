#include <sourcemod>
#include <emitsoundany>

new Handle:soundPath = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Round Start events",
	author = "ReiGekkouga/Annrio",
	description = "Plays RoundStart sound",
	version = "v1.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("round_start",RoundStart,EventHookMode_PostNoCopy)
	
	soundPath = CreateConVar("sm_beginsound", "quake/prepare.mp3", "Soundpath (sound/* already included", FCVAR_PLUGIN);
	AutoExecConfig(true, "plugin.RoundStartSounds");
}

public OnConfigsExecuted()
{
	decl String:RSsoundPath[128], String:RSsoundPathDL[192];
	GetConVarString(soundPath, RSsoundPath, sizeof(RSsoundPath));
	Format(RSsoundPathDL, sizeof(RSsoundPathDL), "sound/%s", RSsoundPath);
	
	AddFileToDownloadsTable(RSsoundPathDL);
	PrecacheSoundAny(RSsoundPath, true);
}
public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:RSsoundPath[128];
	GetConVarString(soundPath, RSsoundPath, sizeof(RSsoundPath));
	
	EmitSoundToAllAny(RSsoundPath);
}