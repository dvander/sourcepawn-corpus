/*
* V0.5.3
* Fixed bug with the spamming announce
* Fixed bug with on/ off option
* Fixed logic bug -.--.-.-.-.-.-.-.-.-.-.-.-.-
* Code optimization
* 
* V0.5
* Changed cvar soundlist to keyvaluesoundlist
* Added more options for sm_deathsound_playto 
* Added On/off option for Players
* Added announce
* +Cvar to control the announce
* +Cvar to emit a sound on the map or play a sound direct to a player
* +Cvar to disable the player on / off option
* 
* V0.4.2
* Added some code
* 
* V0.4
* +Cvar to control who can hear sound
* +Cvar to control which sound the players hear
*
* V0.3.1
* Fixed bug with client index
*
* V0.3
* +cvar plugin on/off: sm_deathsound_enable
* +cvar soundlist: sm_deathsound_soundlist
* +autoconfigfile:cfg/sourcemod/plugin.deathsound.cfg
* Recoded the [CSS]RoundSound part.
*
* V 0.2:
* Added singel soundfile check.
*
* V 0.1:
* Basic Plugin, based on [CSS]RoundSound. 
* 
* 
* 
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <timers>

#define PLUGIN_VERSION "0.5.3"


public Plugin:myinfo = 
{
	name = "DeathSound",	
	author = "Keksmampfer",
	description = "Plays a sound to the dieing player.",
	version = PLUGIN_VERSION,
	url = "NA"
};

new Handle:g_version = INVALID_HANDLE;
new String:g_sounds[10][255];
new g_count;
new Handle:g_enable = INVALID_HANDLE;
new Handle:g_playto = INVALID_HANDLE;
new Handle:g_samesound = INVALID_HANDLE;
new Handle:g_stoplastsound = INVALID_HANDLE;
new String:g_lastsound[MAXPLAYERS+1][256];
new Handle:g_cookie_disable = INVALID_HANDLE;
new Handle:g_announce = INVALID_HANDLE;
new Handle:g_emit = INVALID_HANDLE;
new Handle:g_allow_disable = INVALID_HANDLE;
new g_lastenity[MAXPLAYERS+1];

public OnPluginStart() {
	
	g_version = CreateConVar("sm_deathsound_version", PLUGIN_VERSION, "DeathSound plugin version", FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_enable = CreateConVar("sm_deathsound_enable", "1", "1 - Turn the plugin On\n0 - Turn the plugin OFF", _, true, 0.0, true, 1.0);
	g_playto = CreateConVar("sm_deathsound_playto", "1", "Play a sound to:\n +1 :the dieing player\n +2 :the attacker\n +4 :the team of the dieing player\n +8 :the team of the attacker\n +16 :all dead players\n +32 :all alive players", _, true, 0.0, true, 63.0);
	g_samesound = CreateConVar("sm_deathsound_samesound", "1", "1 - Everyone hears the same sound\n0 - Everyone hears a different sound", _, true, 0.0, true, 1.0);
	g_stoplastsound = CreateConVar("sm_deathsound_stoplastsound", "1", "1 - Stops the sound bevore\n0 - don't stop" , _, true, 0.0,true,1.0);
	g_announce = CreateConVar("sm_deathsound_announce", "1", "0 - No Announce\n1 - 1 Every 45 seconds the announce: Type /deathsound or !deathsound to turn on / off the deathsound.", _, true, 0.0, true, 1.0);
	g_emit = CreateConVar("sm_deathsound_emit", "1", "1 - Emits a sound at the position of the daed player\n0 - Plays the sound directly to the players", _, true, 0.0, true, 1.0);
	g_allow_disable = CreateConVar("sm_deathsound_allow_disable", "1", "1 - Allows the player to turn off his / her deathsounds \n0 - Doesn't allows the player to turn off his / her deathsounds", _, true, 0.0, true, 1.0); 
	
	AutoExecConfig(true,"plugin.deathsound");
	
	RegConsoleCmd("sm_deathsound", cb_disable, "Disable / Enable the deathsound");
	
	g_cookie_disable = RegClientCookie("deathsound_disable", "Cookie to enable / disable the deathsound", CookieAccess_Protected);
	
	SetConVarString(g_version, PLUGIN_VERSION);
	
	if(GetConVarBool(g_enable))
	{
		HookEvent("player_death", EventPlayerDeath);
	}
	
	if(GetConVarBool(g_announce))
	{
		CreateTimer(45.0, Announce);
		
	}
	
}

public OnMapStart()
{  
	AutoExecConfig(true,"plugin.deathsound");
	
	new String:longsound[130];
	new String:sound[100];
	
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, PLATFORM_MAX_PATH, "configs/deathsound.txt");
	
	new Handle:kv = CreateKeyValues("deathsound");
	FileToKeyValues(kv, file);
	g_count = 0;
	if (KvJumpToKey(kv, "soundlist") )
	{
		decl count;
		new String:istring[3];
		
		count = KvGetNum(kv, "count");
		
		for (new i = 0; i < count; i++)
		{
			IntToString(i, istring, 2);
			KvGetString(kv, istring, sound, sizeof(sound));
			
			Format(longsound,sizeof(longsound), "sound/%s", sound);
			if(FileExists(longsound,true)) 
			{
				AddFileToDownloadsTable(longsound); 
				PrecacheSound(sound, true);			
				g_count++;
				g_sounds[i] =  sound;
				LogMessage("Load %s ok", sound);
			}
			else {
				LogError("Check %s" , longsound);
			}		
			
		}
		
		CloseHandle(kv);
	}
	else
	{
		LogError("Check the configs/deathsound.txt");
	}
	LogMessage("%i", g_count);
}

public Action:Announce(Handle:timer)
{
	PrintToChatAll("\x04Type /deathsound or !deathsound to turn on / off the deathsound.");
	if(GetConVarBool(g_announce))
	{
		CreateTimer(45.0, Announce);
		
	}
	return Plugin_Continue;
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	if(GetConVarBool(g_enable) && g_count > 0)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new buffer = GetConVarInt(g_playto);
		new playsoundto[MaxClients+1];
		
		if(buffer-32 >= 0)
		{
			buffer= buffer - 32;
			for(new i=1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
				{
					playsoundto[i] = 1;
				}
			}	
		}
		
		if(buffer-16 >= 0)
		{
			buffer= buffer - 16;
			for(new i=1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i))
				{
					playsoundto[i] = 1;
				}
			}	
		}
		
		if(buffer-8 >= 0)
		{
			new teamofattacker = GetClientTeam(GetClientOfUserId(GetEventInt(event, "attacker")));
			buffer= buffer - 8;
			for(new i=1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == teamofattacker)
				{
					playsoundto[i] = 1;
				}
			}	
		}
		
		if(buffer - 4 >= 0)
		{
			buffer = buffer -4;
			new teamofvictim = GetClientTeam(victim);
			buffer= buffer - 4;
			for(new i=1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					if(GetClientTeam(i) == teamofvictim)
					{
						playsoundto[i] = 1;
					}
				}
			}	
		}
		
		if(buffer -2 >= 0)
		{
			buffer= buffer -2;
			new client = GetClientOfUserId(GetEventInt(event, "attacker"));
			playsoundto[client] = 1;
		}
		
		if(buffer -1 >= 0)
		{
			playsoundto[victim] = 1;
			
		}
		
		new rnd;
		for(new i=1; i <= MaxClients; i++)
		{
			if(GetConVarBool(g_allow_disable))
			{
				new String:bufferr[2];
				GetClientCookie(i, g_cookie_disable , bufferr, 2 );
				if(StrEqual(bufferr, "1"))
				{
					playsoundto[i]= 0;
				}
			}
			
			if(i==1)
			{	
				rnd = GetRandomInt(0, g_count-1); 
			}
			else if(!GetConVarBool(g_samesound))
			{
				rnd = GetRandomInt(0, g_count-1);  
			}
			
			if(playsoundto[i] == 1)
			{
				PlaySound(i , rnd, victim);
			}	
		}
	}
}

public Action:cb_disable(client , args)
{
	if(client == 0)
	{
		ReplyToCommand( client, "[SM] This command is not aviable for console");
		return Plugin_Handled;
	}
	
	decl String:buffer[2];
	new String:message[255];
	GetClientCookie(client, g_cookie_disable , buffer, 2 );
	if(StrEqual(buffer , "0") || StrEqual(buffer, ""))
	{
		SetClientCookie(client, g_cookie_disable, "1");
		message = "[SM] The DeathSounds are now off.";
	}
	else if( StrEqual(buffer, "1"))
	{
		SetClientCookie(client, g_cookie_disable, "0");
		message = "[SM] The DeathSounds are now on.";
	}
	
	if(!GetConVarBool(g_allow_disable))
	{
		Format(message, sizeof(message), "%s But this option is disabled." , message);		
	}
	ReplyToCommand(client, message);
	
	return Plugin_Handled;
}

PlaySound(const client,const number, victim) 
{
	
	if(IsClientInGame(client) && !IsFakeClient(client) && !StrEqual(g_sounds[number], ""))
	{		
		if(GetConVarBool(g_stoplastsound) )
		{
			StopLastSound(client);
		}
		
		if(GetConVarBool(g_emit))
		{
			new Float:pos[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
			EmitSoundToClient(client, g_sounds[number],SOUND_FROM_WORLD, SNDCHAN_AUTO,SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
			g_lastenity[client] = victim;
		}
		else
		{
			EmitSoundToClient( client, g_sounds[number]);
			g_lastenity[client] = client;
		}
		
		strcopy(g_lastsound[client], sizeof(g_lastsound[]), g_sounds[number]);
	}
	else if(StrEqual(g_sounds[number], ""))
	{
		LogError("Sound input works not correct");
	}
	return;
}

public StopLastSound(client)
{
	StopSound(g_lastenity[client], SNDCHAN_AUTO, g_lastsound[client]);
	g_lastsound[client] = "";
}