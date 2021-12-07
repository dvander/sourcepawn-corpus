#include sourcemod
#include sdktools
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.1"

new Handle:v_SoundHandler = INVALID_HANDLE;
new Handle:v_PlayToSniper = INVALID_HANDLE;
new Handle:v_SoundFile = INVALID_HANDLE;
new Handle:v_Enabled = INVALID_HANDLE;
new Handle:v_SelfKill = INVALID_HANDLE;

new bool:g_PlayToMe[MAXPLAYERS+1] = {true, ...};

public Plugin:myinfo = 
{
	name = "[TF2] Crit Hallelujah!",
	author = "DarthNinja",
	description = "Plays a sound triggered by crit kills!)",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	CreateConVar("sm_hallelujah_version", PLUGIN_VERSION, "Crit Hallelujah Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	v_SoundHandler = CreateConVar("sm_ch_soundhandler", "1", "1 = Play sound to attacker, 2 = Play to players near the attacker,  3 = Play to both attacker and victim", 0, true, 1.0, true, 3.0);
	v_PlayToSniper = CreateConVar("sm_ch_playforheadshot", "0", "Play sound for sniper headshots <1/0>", 0, true, 0.0, true, 1.0);
	v_SoundFile = CreateConVar("sm_ch_soundfile", "player/taunt_wormshhg.wav", "path/file.ext to sound file");
	v_Enabled = CreateConVar("sm_ch_enabled", "1", "Enable/Disable Crit Hallelujah <1/0>", 0, true, 0.0, true, 1.0);
	v_SelfKill = CreateConVar("sm_ch_suicide", "0", "Play sound if player kills themself with a crit <1/0>", 0, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_critsound", Command_ToggleSound, "sm_critsound - toggles the crit sound");
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

public Action:Command_ToggleSound(client, args)
{
	if (g_PlayToMe[client] == true)
	{
		g_PlayToMe[client] = false
		PrintToChat(client, "[Crit Sounds] You will no longer hear crit sounds!")
		return Plugin_Handled;
	}
	else if (g_PlayToMe[client] == false)
	{
		g_PlayToMe[client] = true
		PrintToChat(client, "[Crit Sounds] You will now hear crit sounds!")
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(v_Enabled))
	{
		//Get vars
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
		if (attacker > MaxClients || attacker < 1)
			return Plugin_Continue;
			
		new victim = GetClientOfUserId(GetEventInt(event, "userid"))
		new KillType = GetEventInt(event, "customkill")
		new TFClassType:playerClassAtt = TF2_GetPlayerClass(attacker);
		
		if (!GetConVarBool(v_PlayToSniper) && KillType == 1 && playerClassAtt == TFClass_Sniper)
			return Plugin_Continue;
			
		//is it a crit kill?
		new damagebits = GetEventInt(event, "damagebits");
		if (damagebits & 1048576)
			PlaySound(attacker, victim)
	}
	return Plugin_Continue;
}


PlaySound(attacker, victim)
{
	new SoundHandler = GetConVarInt(v_SoundHandler);
	new String:SoundFile[128]
	GetConVarString(v_SoundFile, SoundFile, sizeof(SoundFile))
	
	if (attacker == victim && !GetConVarBool(v_SelfKill))
	{
		return;
	}
	
	if (SoundHandler == 1 && g_PlayToMe[attacker])
	{
		EmitSoundToClient(attacker, SoundFile, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	}
	else if (SoundHandler == 2 && g_PlayToMe[attacker])
	{
		EmitSoundToAll(SoundFile, attacker)
	}
	else if (SoundHandler == 3)
	{
		if (g_PlayToMe[attacker])
		{
			EmitSoundToClient(attacker, SoundFile, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		}
		if (g_PlayToMe[victim])
		{
			EmitSoundToClient(victim, SoundFile, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		}
	}
	return;
}