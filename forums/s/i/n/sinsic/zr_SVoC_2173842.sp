#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"
//Updates With 1.0.1: Fixed the problem with gun volumes

//CVARS
new Handle:zr_SVoC_version	= INVALID_HANDLE;
new Handle:zr_SVoC_Enabled	= INVALID_HANDLE;
new Handle:zr_SVoC_MLevel	= INVALID_HANDLE;
new Handle:zr_SVoC_WLevel	= INVALID_HANDLE;

new String:g_sSample[30][PLATFORM_MAX_PATH] = {"",")weapons/p228/p228-1.wav",")weapons/glock/glock18-1.wav",")weapons/scout/scout_fire-1-1.wav","",")weapons/xm1014/xm1014-1.wav","",")weapons/mac10/mac10-1.wav",")weapons/aug/aug-1.wav","",")weapons/elite/elite-1.wav",")weapons/fiveseven/fiveseven-1.wav",")weapons/ump45/ump45-1.wav",")weapons/sg550/sg550-1.wav",")weapons/galil/galil-1.wav",")weapons/famas/famas-1.wav",")weapons/usp/usp1.wav",")weapons/awp/awp1.wav",")weapons/mp5navy/mp5-1.wav",")weapons/m249/m249-1.wav",")weapons/m3/m3-1.wav",")weapons/m4a1/m4a1-1.wav",")weapons/tmp/tmp-1.wav",")weapons/g3sg1/g3sg1-1.wav","",")weapons/deagle/deagle-1.wav",")weapons/sg552/sg552-1.wav",")weapons/ak47/ak47-1.wav","",")weapons/p90/p90-1.wav"};

//Info
public Plugin:myinfo =
{
	name = "Sound Volume Control",
	author = "sinsic",
	description = "Change map music and weapon sound levels.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	for (new i = 0; i < 30; i++)
	{
		if (strcmp(g_sSample[i],"") != 0)
		{
			PrecacheSound(g_sSample[i], true);
		}
	}
	//Convars
	zr_SVoC_version = CreateConVar("zr_SVoC_version", PLUGIN_VERSION, "Sound Volume Control version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	zr_SVoC_Enabled = CreateConVar("zr_SVoC_Enabled", "3", "If plugin is enabled (0: Disable | 1: Map Music Control | 2: Weapon Sound Control | 3: Both)");
	zr_SVoC_MLevel = CreateConVar("zr_SVoC_MLevel", "0.3", "Map music volume adjustment (0.0: No sound | 1.0: Full sound)");
	zr_SVoC_WLevel = CreateConVar("zr_SVoC_WLevel", "0.3", "Weapon volume adjustment (0.0: No sound | 1.0: Full sound)");
	
	//Keep track if somebody changed the plugin_version
	SetConVarString(zr_SVoC_version, PLUGIN_VERSION);
	HookConVarChange(zr_SVoC_version, SVoC_versionchange);
	
	//Hooks
	AddAmbientSoundHook(AmbientSHook);
	AddTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);
	
	AutoExecConfig(true, "zr_SVoC", "sourcemod/zombiereloaded");
}

//If somebody changed the plugin version set it back to right one, otherwise they might not realize updates
public SVoC_versionchange(Handle:convar, const String:oldValue[], const String:newValue[])
	{
	SetConVarString(convar, PLUGIN_VERSION);
}

//Hook for musics
public Action:AmbientSHook(String:sample[PLATFORM_MAX_PATH], &entity, &Float:volume, &level, &pitch, Float:pos[3], &flags, &Float:delay)
{
	if (GetConVarInt(zr_SVoC_Enabled)==1 || GetConVarInt(zr_SVoC_Enabled)==3)
	{
		new len = strlen(sample);
		if (len > 4 && (StrEqual(sample[len-3], "mp3") || StrEqual(sample[len-3], "wav")))
		{
			new Float:fVolume = GetConVarFloat(zr_SVoC_MLevel);
			volume = volume*fVolume;
			return Plugin_Changed;
		} else {
			return Plugin_Continue;
		}
	} else {
		return Plugin_Continue;
	}
}  

public Action:CSS_Hook_ShotgunShot(const String:te_name[], const Players[], numClients, Float:delay)
{

	if (GetConVarInt(zr_SVoC_Enabled)==2 || GetConVarInt(zr_SVoC_Enabled)==3)
	{
		new Float:fVolume = GetConVarFloat(zr_SVoC_WLevel);
		new client = TE_ReadNum("m_iPlayer") + 1;
		new newClients[MaxClients];
		new newTotal = 0;
		
		for (new i = 0; i < numClients; i++)
		{
			newClients[newTotal++] = Players[i];
		}
		
		EmitSound(newClients, newTotal, g_sSample[TE_ReadNum( "m_iWeaponID" )], client ,SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, fVolume);
		
		return Plugin_Handled;
	} else {
		return Plugin_Continue;
	}
}