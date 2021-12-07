#include sourcemod
#include sdktools
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"

new Handle:v_SoundHandler = INVALID_HANDLE;
new Handle:v_ClassHandler = INVALID_HANDLE;
new Handle:v_SoundFile = INVALID_HANDLE;
new Handle:v_Enabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Boom Headshot Remake!",
	author = "DarthNinja",
	description = "Plays a sound to Snipers and their Victims. (Now also for Ambassador Spies!)",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	CreateConVar("sm_bhs_version", PLUGIN_VERSION, "Boom Headshot Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	v_SoundHandler = CreateConVar("sm_bhs_soundhandler", "3", "1 = Play sound to sniper, 2 = Play to victim, 3 = Play to both, 4 = Play to all players, 5 = Play to players near the attacker", 0, true, 1.0, true, 5.0);
	v_ClassHandler = CreateConVar("sm_bhs_classhandler", "1", "1 = Play for Snipers and Ambassador Spies, 2 = Play only for Snipers, 3 = Play only for spies", 0, true, 1.0, true, 3.0);
	v_SoundFile = CreateConVar("sm_bhs_soundfile", "bhs/boomheadshot.mp3", "path/file.ext to sound file");
	v_Enabled = CreateConVar("sm_bhs_enabled", "1", "Enable/Disable BoomHeadshot <1/0>", 0, true, 0.0, true, 1.0);
}

public OnMapStart() 
{
	new String:SoundFile[128]
	GetConVarString(v_SoundFile, SoundFile, sizeof(SoundFile))
	PrecacheSound(SoundFile);
	decl String:SoundFileLong[192];
	Format(SoundFileLong, sizeof(SoundFileLong), "sound/%s", SoundFile);
	AddFileToDownloadsTable(SoundFileLong);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(v_Enabled))
	{
		//Get vars
		new Atckr = GetClientOfUserId(GetEventInt(event, "attacker"))
		new Vic = GetClientOfUserId(GetEventInt(event, "userid"))
		new KillType = GetEventInt(event, "customkill")
		
		new ClassHandler = GetConVarInt(v_ClassHandler)
		new String:SoundFile[128]
		GetConVarString(v_SoundFile, SoundFile, sizeof(SoundFile))
		
		if (KillType == 1)
		{
			new TFClassType:playerClass = TF2_GetPlayerClass(Atckr);				
			if (ClassHandler == 2 && playerClass == TFClass_Sniper)
			{
				PlaySound(Atckr, Vic)
				return Plugin_Continue;
			}
			else if (ClassHandler == 3 && playerClass == TFClass_Spy)
			{
				PlaySound(Atckr, Vic)
				return Plugin_Continue;
			}
			else if (ClassHandler == 1)
			{
				PlaySound(Atckr, Vic)
				return Plugin_Continue;
			}		
		}
	}
	return Plugin_Continue;
}

PlaySound(Atckr, Vic)
{
	new SoundHandler = GetConVarInt(v_SoundHandler);
	new String:SoundFile[128]
	GetConVarString(v_SoundFile, SoundFile, sizeof(SoundFile))
	
	if (SoundHandler == 1)
	{
		EmitSoundToClient(Atckr, SoundFile, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	}
	else if (SoundHandler == 2)
	{
		EmitSoundToClient(Vic, SoundFile, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	}
	else if (SoundHandler == 3)
	{
		EmitSoundToClient(Atckr, SoundFile, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		EmitSoundToClient(Vic, SoundFile, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	}
	else if (SoundHandler == 4)
	{
		EmitSoundToAll(SoundFile)
	}
	else if (SoundHandler == 5)
	{
		EmitSoundToAll(SoundFile,Atckr)
	}
}