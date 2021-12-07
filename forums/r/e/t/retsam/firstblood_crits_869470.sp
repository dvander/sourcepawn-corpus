/* 
* [TF2] First Blood Crits
* Author(s): -MCG-Retsam
* File: firstblood_crits.sp
* Description: Player who gets first kill is awarded with crits.
*
* 1.0 - Various code fixes....
* 0.9 - Added some particle effects. Added a birthday soundfile with cvar, and a 5 sec countdown soundfile.
* 0.8 - Changed handling of cvar changes.  Changed default period to 10.0 instead of 5.0. Few other small things.
* 0.7 - Fixed dead ringers triggering first blood. Coding mistake.
* 0.6 - Added a cvar to disable tf2's own first blood arena cvar. Added cvar for center screen timer as well.
* 0.5 - Cleaned up a few things and added a few more killtimer checks
* 0.4	- Added some more arena detection so it auto-disables in arena mode
* 0.3	- Added enable/disable cvar
* 0.2	- Added some more cvars to enable/disable the messages and sounds
* 0.1	- Initial Release
*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

#define SOUND_FIRSTBLOOD2 	"vo/announcer_am_firstblood02.wav"
#define SOUND_BDAY 	"misc/happy_birthday.wav"
#define SOUND_MEDICALERT 	"ui/medic_alert.wav"

#define NO_ATTACH		0
#define ATTACH_NORMAL	1
#define ATTACH_HEAD		2

new Handle:g_fbcenabled = INVALID_HANDLE;
new Handle:g_FB_Msg = INVALID_HANDLE;
new Handle:g_FB_Sound = INVALID_HANDLE;
new Handle:g_FB_BDAY_Sound = INVALID_HANDLE;
new Handle:g_FB_critsTimer = INVALID_HANDLE;
new Handle:g_FB_critsPeriod	= INVALID_HANDLE;
new Handle:g_ArenaFBCvar = INVALID_HANDLE;

new Handle:g_CritsTimerHandle[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

new g_iFirstkill;
new g_iRoundStarts;
new g_firstbloodMsg;
new g_firstbloodSound;
new g_firstbloodBdaySound;
new g_firstbloodTimer;
new g_firstbloodPeriod;

new bool:g_bPreGameChk;
new String:TimeMessage1[32];

new bool:g_bIsFbcEnabled = true;
new bool:g_bIsFBarenaEnabled = true;

new CTimerCount[MAXPLAYERS+1] = { 0, ... };
new PlayerCritsChk[MAXPLAYERS+1] = { 0, ... };


public Plugin:myinfo = 
{
	name = "First Blood Crits",
	author = "-MCG-retsam",
	description = "Player who gets first blood wins crits for set duration",
	version = PLUGIN_VERSION,
	url = "www.multiclangaming.net"
};

public OnPluginStart()
{
	CreateConVar("sm_firstbloodcrits_version", PLUGIN_VERSION, "FirstBlood Crits version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_fbcenabled = CreateConVar("sm_firstbloodcrits_enabled", "1", "Enable/Disable firstbloodcrits plugin (1/0 = yes/no)");
	g_FB_critsPeriod = CreateConVar("sm_firstbloodcrits_period", "10.0", "Period in seconds for crits duration");
	g_FB_Msg = CreateConVar("sm_firstbloodcrits_msg", "1", "Display first blood crits msg? (1/0 = yes/no)");
	g_FB_Sound = CreateConVar("sm_firstbloodcrits_emitsound", "1", "Emit the first blood sound and timer files? (1/0 = yes/no)");
	g_FB_BDAY_Sound = CreateConVar("sm_firstbloodcrits_bdaysound", "1", "Emit the birthday sound file? (1/0 = yes/no)");
	g_FB_critsTimer = CreateConVar("sm_firstbloodcrits_timer", "1", "Enable the center screen timer countdown? (1/0 = yes/no)");
	g_ArenaFBCvar    = CreateConVar("sm_arenafirstblood","1","Enable tf2 first blood cvar in arena mode? (1/0 = yes/no)");

	HookConVarChange(g_fbcenabled, Cvars_Changed);
	HookConVarChange(g_FB_Msg, Cvars_Changed);
	HookConVarChange(g_FB_Sound, Cvars_Changed);
	HookConVarChange(g_FB_BDAY_Sound, Cvars_Changed);
	HookConVarChange(g_FB_critsTimer, Cvars_Changed);
	HookConVarChange(g_FB_critsPeriod, Cvars_Changed);
	
	HookEvent("player_death", Hook_PlayerDeath, EventHookMode_Post);
	HookEvent("teamplay_round_start", Hook_Roundstart, EventHookMode_Post);

	AutoExecConfig(true, "plugin.firstbloodcrits");
}

public OnClientPostAdminCheck(client)
{
	CTimerCount[client] = 0;
	PlayerCritsChk[client] = 0;
}

public OnClientDisconnect(client)
{
	if(g_CritsTimerHandle[client] != INVALID_HANDLE)
	{
		CloseHandle(g_CritsTimerHandle[client]);
		g_CritsTimerHandle[client] = INVALID_HANDLE;
	}

	CTimerCount[client] = 0;
	PlayerCritsChk[client] = 0;
}

public OnMapStart()
{
	new Handle:cvarArena = FindConVar("tf_gamemode_arena");
	if(GetConVarBool(cvarArena))
	g_bIsFbcEnabled = false;
	
	g_bPreGameChk = false;
	g_iRoundStarts = 0;
	g_iFirstkill = 0;
	
	PrecacheSound(SOUND_FIRSTBLOOD2, true);
	PrecacheSound(SOUND_BDAY, true);
	PrecacheSound(SOUND_MEDICALERT, true);
}

public OnConfigsExecuted()
{
	g_bIsFbcEnabled = GetConVarBool(g_fbcenabled);
	g_bIsFBarenaEnabled = GetConVarBool(g_ArenaFBCvar);
	
	g_firstbloodMsg = GetConVarInt(g_FB_Msg);
	g_firstbloodSound = GetConVarInt(g_FB_Sound);
	g_firstbloodTimer = GetConVarInt(g_FB_critsTimer);
	g_firstbloodBdaySound = GetConVarInt(g_FB_BDAY_Sound);
	g_firstbloodPeriod = GetConVarInt(g_FB_critsPeriod);

	Format(TimeMessage1, sizeof(TimeMessage1), "%i", GetConVarInt(g_FB_critsPeriod));
	HookConVarChange(g_FB_critsPeriod, ConVarChange_CritsPeriod);
	HookConVarChange(g_ArenaFBCvar, ConVarChange_ArenaFBCvar);

	ArenaCvar_Check();
}

public ArenaCvar_Check()
{
	if(!g_bIsFBarenaEnabled)
	{
		ServerCommand ("sm_cvar tf_arena_first_blood 0");
	}      
}

public ConVarChange_CritsPeriod(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Format(TimeMessage1, sizeof(TimeMessage1), "%i", StringToInt(newValue));
}

public ConVarChange_ArenaFBCvar(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(newValue[0] == '0')
	{
		ServerCommand ("sm_cvar tf_arena_first_blood 0");
	}
	else
	{
		ServerCommand ("sm_cvar tf_arena_first_blood 1.0");
	}
} 

public Hook_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{		
	if(!g_bIsFbcEnabled)
	return;

	new deathflags = GetEventInt(event, "death_flags");
	if(deathflags & TF_DEATHFLAG_DEADRINGER) return;

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:suicide = false;

	if(attacker == victim || !IsClientInGame(attacker))
	suicide = true;

	if(!suicide)
	{
		if(g_iFirstkill <= 1)
		FirstBloodChk(attacker, victim);
	}

	if(PlayerCritsChk[victim] == 1)
	{
		if(g_CritsTimerHandle[victim] != INVALID_HANDLE)
		{
			CloseHandle(g_CritsTimerHandle[victim]);
			g_CritsTimerHandle[victim] = INVALID_HANDLE;
		}
		
		CTimerCount[victim] = 0;
		PlayerCritsChk[victim] = 0;
		
		if(g_firstbloodSound == 1)
		StopSound(victim, SNDCHAN_AUTO, SOUND_MEDICALERT);
	}
}

public Hook_Roundstart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iFirstkill = 0;
	
	if(g_iRoundStarts++ < 1)
	{
		g_bPreGameChk = true;
	}
	else
	{
		g_bPreGameChk = false;
	}
}

FirstBloodChk(attacker, victim)
{
	new Handle:cvarArena = FindConVar("tf_gamemode_arena");
	
	if(!IsClientInGame(attacker) || !IsPlayerAlive(attacker))
	return;

	if(!GetConVarBool(cvarArena) && !g_bPreGameChk && g_iFirstkill++ == 0)
	{
		decl String:FirstBlood[125];
		if(g_firstbloodSound == 1)
		{
			EmitSoundToAll(SOUND_FIRSTBLOOD2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		}
		
		AttachParticleTimer("mini_fireworks", 5.0, attacker, ATTACH_NORMAL, 0.0, 0.0, 50.0);
		AttachParticleTimer("bday_confetti", 4.0, attacker, ATTACH_NORMAL, 0.0, 0.0, 20.0);

		if(g_firstbloodMsg == 1)
		{	
			Format(FirstBlood, sizeof(FirstBlood), "\x05>> \x03%N \x01got \x04first blood\x01 this round by killing \x04%N\x01 and won \x05CRITS\x01!", attacker, victim);
			SayText2All(attacker, FirstBlood);
		}

		FBCritsEnable(attacker);
	}
}

public FBCritsEnable(client)
{
	PlayerCritsChk[client] = 1;
	
	new team = GetClientTeam(client);

	if(g_firstbloodBdaySound == 1)
	EmitSoundToAll(SOUND_BDAY, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	
	if(team == 2)
	{
		AttachParticleTimer("electrocuted_gibbed_red", 3.0, client, ATTACH_NORMAL, 0.0, 0.0, 20.0);
		AttachParticleTimer("electrocuted_gibbed_red", 3.0, client, ATTACH_NORMAL, 0.0, 0.0, 20.0);
	}
	else
	{
		AttachParticleTimer("electrocuted_gibbed_blue", 3.0, client, ATTACH_NORMAL, 0.0, 0.0, 20.0);
		AttachParticleTimer("electrocuted_gibbed_blue", 3.0, client, ATTACH_NORMAL, 0.0, 0.0, 20.0);
	}
	
	if(g_CritsTimerHandle[client] != INVALID_HANDLE)
	{
		CloseHandle(g_CritsTimerHandle[client]);
		g_CritsTimerHandle[client] = INVALID_HANDLE;
	}
	
	CTimerCount[client] = 0;
	if(g_firstbloodTimer == 1)
	{
		PrintCenterText(client, "%i", g_firstbloodPeriod);
		g_CritsTimerHandle[client] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
	}
	
	CreateTimer(GetConVarFloat(g_FB_critsPeriod), FBCritsOff, client);
}

public Action:Timer_Countdown(Handle:Timer, any:client)
{
	CTimerCount[client]++;
	
	if(PlayerCritsChk[client] == 1)
	{
		PrintCenterText(client, "%i", g_firstbloodPeriod - CTimerCount[client]);

		if(g_firstbloodPeriod - CTimerCount[client] == 5)
		{
			if(g_firstbloodSound == 1)
			{
				EmitSoundToClient(client, SOUND_MEDICALERT, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:FBCritsOff(Handle:Timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	return;
	
	if(PlayerCritsChk[client] == 1)
	{
		if(g_firstbloodMsg == 1)
		{
			new String:nm[255];
			Format(nm, sizeof(nm), "\x01[SM] \x03%N's\x01 \x05CRITS \x01wore off.", client);
			SayText2All(client, nm);
		}
		
		if(g_CritsTimerHandle[client] != INVALID_HANDLE)
		{
			CloseHandle(g_CritsTimerHandle[client]);
			g_CritsTimerHandle[client] = INVALID_HANDLE;
		}
		
		CTimerCount[client] = 0;
		PlayerCritsChk[client] = 0;
	}
}

/*
stock bool:IsValidClient(client)
{
	if (client
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& IsPlayerAlive(client)
		&& !IsFakeClient(client))
		return true;
	else
		return false;
}
*/

SayText2All(author, const String:message[])
{
	new Handle:buffer = StartMessageAll("SayText2");
	if (buffer != INVALID_HANDLE)
	{
		BfWriteByte(buffer, author);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, message);
		EndMessage();
	}
}

stock Handle:AttachParticleTimer(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	new particle = CreateEntityByName("info_particle_system");
	
	// Check if it was created correctly
	if (IsValidEntity(particle))
	{
		decl Float:pos[3];

		// Get position of entity
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		
		// Add position offsets
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;
		
		// Teleport, set up
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);

		if (attach != NO_ATTACH)
		{
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity, particle, 0);
			
			if (attach == ATTACH_HEAD)
			{
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
		}
		
		// All entities in presents are given a targetname to make clean up easier
		DispatchKeyValue(particle, "targetname", "present");

		// Spawn and start
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		
		return CreateTimer(time, DeleteParticleTime, particle);
	} else {
		LogError("(CreateParticleTime): Could not create info_particle_system");
	}
	
	return INVALID_HANDLE;
}

public Action:DeleteParticleTime(Handle:timer, any:particle)
{
	if(IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if(StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "kill");
		}
	}
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(PlayerCritsChk[client] == 1)
	{
		result = true;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_fbcenabled)
	{
		if(StringToInt(newValue) == 0)
		{
			g_bIsFbcEnabled = false;
			UnhookEvent("player_death", Hook_PlayerDeath, EventHookMode_Post);
			UnhookEvent("teamplay_round_start", Hook_Roundstart, EventHookMode_Post);
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i))
				{
					continue;
				}
				
				if(PlayerCritsChk[i] == 1)
				{
					if(g_CritsTimerHandle[i] != INVALID_HANDLE)
					{
						CloseHandle(g_CritsTimerHandle[i]);
						g_CritsTimerHandle[i] = INVALID_HANDLE;
					}
					CTimerCount[i] = 0;
					PlayerCritsChk[i] = 0;
				}
			}
		}
		else
		{
			g_bIsFbcEnabled = true;
			HookEvent("player_death", Hook_PlayerDeath, EventHookMode_Post);
			HookEvent("teamplay_round_start", Hook_Roundstart, EventHookMode_Post);
			g_iFirstkill = 0;
		}
	}
	else if(convar == g_FB_Msg)
	{
		g_firstbloodMsg = StringToInt(newValue);
	}
	else if(convar == g_FB_Sound)
	{
		g_firstbloodSound = StringToInt(newValue);
	}
	else if(convar == g_FB_BDAY_Sound)
	{
		g_firstbloodBdaySound = StringToInt(newValue);
	}
	else if(convar == g_FB_critsTimer)
	{
		g_firstbloodTimer = StringToInt(newValue);
	}
	else if(convar == g_FB_critsPeriod)
	{
		g_firstbloodPeriod = StringToInt(newValue);
	}
}