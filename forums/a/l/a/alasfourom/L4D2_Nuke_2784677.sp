#pragma semicolon 1
#pragma newdecls required
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.4"
#define TEAM_SURVIVOR 2

#define NUKE_SOUND "animation/overpass_jets.wav"
#define EXPLOSION_SOUND "ambient/explosions/explode_1.wav"
#define EXPLOSION_DEBRIS "animation/plantation_exlposion.wav"
#define FIRE_PARTICLE "gas_explosion_ground_fire"
#define EXPLOSION_PARTICLE "FluidExplosion_fps"

#define FFADE_IN            0x0001
#define FFADE_OUT           0x0002
#define FFADE_MODULATE      0x0004
#define FFADE_STAYOUT       0x0008
#define FFADE_PURGE         0x0010

ConVar 	g_hNukeEnable;
ConVar 	g_hNukeTime;
ConVar 	g_hAnnounce;
ConVar 	g_hWarning;
ConVar 	g_hFadeEffect;
ConVar 	g_hExplosion;
ConVar 	g_hNukePause;
ConVar 	g_hFinalsOnly;

Handle 	g_hTimer;
Handle 	g_hStrike;
float 	g_fEnd;

public Plugin myinfo =
{
	name = "L4D2 Nuke",
	version = PLUGIN_VERSION,
	description = "City Will Be Nuked After Countdown Time Passes",
	author = "alasfourom, Grey83",
	url = "https://forums.alliedmods.net/showthread.php?t=338742"
}

public void OnPluginStart()
{
	CreateConVar ("l4d2_nuke_version", PLUGIN_VERSION, "L4D2 Nuke" ,FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hNukeEnable = CreateConVar("l4d2_nuke_enable", "1.0", "Enable L4D2 Nuke Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hNukeTime   = CreateConVar("l4d2_nuke_timer", "600.0", "Set The Time In Seconds At Which Players Will Be Nuked", FCVAR_NOTIFY, true, 1.0, true, 5400.0);
	g_hAnnounce   = CreateConVar("l4d2_nuke_announcer", "90.0", "At What Time In Seconds You Want The Hint Text Announcement To Be Displayed", FCVAR_NOTIFY, true, 0.0, true, 5400.0);
	g_hWarning 	  = CreateConVar("l4d2_nuke_warning", "1", "Display Nuke Warning Text When Players Leave Saferoom", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hFadeEffect = CreateConVar("l4d2_nuke_fade", "1", "Allow White Fading Effect When Players Are Nuked", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hExplosion  = CreateConVar("l4d2_nuke_explosion", "1", "Allow Explosion Effect When Players Are Nuked [ Disable If The Explosion Crashes Your Game ]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hNukePause  = CreateConVar("l4d2_nuke_pause", "1", "Pausing Nuke Countdown When A Survivor Reaches The Check Point", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hFinalsOnly = CreateConVar("l4d2_nuke_finals", "1", "Allow Nuke Plugin At Finals Only", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig(true, "L4D2_Nuke");
	
	HookEvent("player_entered_checkpoint", Event_EnteredCheckPoint);
	HookEvent("player_left_start_area", Event_LeftStartArea);
	HookEvent("player_left_safe_area", Event_LeftStartArea);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	RegConsoleCmd("sm_nuke", Cmd_Nuke, "Print Nuke Countdown To Players");
}

public void OnMapStart()
{
	PrecacheSound(NUKE_SOUND);
	PrecacheSound(EXPLOSION_SOUND);
	PrecacheSound(EXPLOSION_DEBRIS);

	PrecacheParticle("gas_explosion_ground_fire");
	PrecacheParticle("FluidExplosion_fps");

	delete g_hTimer;
	delete g_hStrike;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	delete g_hTimer;
	delete g_hStrike;
}

public void Event_LeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_hNukeEnable.BoolValue || g_hTimer) return;
	
	
	if (g_hFinalsOnly.BoolValue && IsFinalMap())
	{
		g_fEnd = GetEngineTime() + g_hNukeTime.FloatValue;
		g_hTimer = CreateTimer(g_hNukeTime.FloatValue - g_hAnnounce.FloatValue, Timer_StartCountDown);
	
		if(g_hWarning.BoolValue)
		{
			int time = RoundToNearest(g_hNukeTime.FloatValue);
			PrintToChatAll("\x04[Warning] \x01Nuke Countdown Started: \x03%d min %d sec", time / 60, time % 60);
		}
	}
	
	else if (!g_hFinalsOnly.BoolValue)
	{
		g_fEnd = GetEngineTime() + g_hNukeTime.FloatValue;
		g_hTimer = CreateTimer(g_hNukeTime.FloatValue - g_hAnnounce.FloatValue, Timer_StartCountDown);
	
		if(g_hWarning.BoolValue)
		{
			int time = RoundToNearest(g_hNukeTime.FloatValue);
			PrintToChatAll("\x04[Warning] \x01Nuke Countdown Started: \x03%d min %d sec", time / 60, time % 60);
		}
	}
}

public void Event_EnteredCheckPoint(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hNukePause.BoolValue) return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client))
	{
		delete g_hTimer;
		delete g_hStrike;
	}
}

public Action Cmd_Nuke(int client, int args)
{
	if (!g_hNukeEnable.BoolValue) return Plugin_Handled;
	if (g_hFinalsOnly.BoolValue && IsFinalMap())
	{
		if (g_hTimer)
		{
			int timeleft = RoundToNearest(g_fEnd - GetEngineTime());
			if(timeleft > 0) PrintToChatAll("\x04[Warning] \x01Nuke Timeleft: \x03%d min %d sec", timeleft / 60, timeleft % 60);
		}
		else
		{
			int timestart = RoundToNearest(g_hNukeTime.FloatValue);
			PrintToChatAll("\x04[Warning] \x01Nuke Timeleft: \x03%d min %d sec", timestart / 60, timestart % 60);
		}
	}
	
	else if (g_hFinalsOnly.BoolValue && !IsFinalMap())
		PrintToChat(client, "\x04[Warning] \x01Nuke Will Launch At \x03Final Chapter\x01.");
	
	else if (!g_hFinalsOnly.BoolValue)
	{
		if (g_hTimer)
		{
			int timeleft = RoundToNearest(g_fEnd - GetEngineTime());
			if(timeleft > 0) PrintToChatAll("\x04[Warning] \x01Nuke Timeleft: \x03%d min %d sec", timeleft / 60, timeleft % 60);
		}
		else
		{
			int timestart = RoundToNearest(g_hNukeTime.FloatValue);
			PrintToChatAll("\x04[Warning] \x01Nuke Timeleft: \x03%d min %d sec", timestart / 60, timestart % 60);
		}
	}
	return Plugin_Handled;
}

public Action Timer_StartCountDown(Handle timer)
{
	g_hTimer = CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT);
	TriggerTimer(g_hTimer);
	return Plugin_Stop;
}

public Action Timer_CountDown(Handle timer, int client)
{
	float time = g_fEnd - GetEngineTime();
	if(time >= 0.0)
	{
		PrintHintTextToAll("Nuke Timer: %d", RoundToNearest(time));
		return Plugin_Continue;
	}

	if(g_hFadeEffect.BoolValue) CreateTimer(0.1, Timer_FadePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	
	EmitSoundToAll(NUKE_SOUND);
	CreateTimer(2.5, Timer_Incap, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(6.0, Timer_SlayPlayers, _, TIMER_FLAG_NO_MAPCHANGE);

	if(g_hExplosion.BoolValue)
	{
		g_hStrike = CreateTimer(2.0, Timer_Strike, _, TIMER_REPEAT);
		CreateTimer(6.0, Timer_StrikeTimeout, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	g_hTimer = null;
	return Plugin_Stop;
}

public Action Timer_FadePlayers(Handle timer)
{
	CreateTimer(0.1, Timer_FadeOut, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public Action Timer_FadeOut(Handle timer)
{
	CreateFade(FFADE_OUT);
	CreateTimer(2.5, Timer_FadeIn, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public Action Timer_FadeIn(Handle timer)
{
	CreateFade(FFADE_IN);
	return Plugin_Stop;
}

void CreateFade(int type)
{
	Handle hFadeClient = StartMessageAll("Fade");
	BfWriteShort(hFadeClient, 800);
	BfWriteShort(hFadeClient, 800);
	BfWriteShort(hFadeClient, (FFADE_PURGE|type|FFADE_STAYOUT));
	BfWriteByte(hFadeClient, 255);
	BfWriteByte(hFadeClient, 255);
	BfWriteByte(hFadeClient, 255);
	BfWriteByte(hFadeClient, 255);
	EndMessage();
}

public Action Timer_Incap(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
	{
		SetEntityHealth(i, 1);
		SDKHooks_TakeDamage(i, i, i, 100.0);
	}
	return Plugin_Stop;
}

public Action Timer_SlayPlayers(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && IsPlayerAlive(i)) ForcePlayerSuicide(i);
	return Plugin_Stop;
}

public Action Timer_Strike(Handle timer)
{
	float radius = 1.0, pos[3];
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
	{
		GetClientAbsOrigin(i, pos);
		pos[0] += GetRandomFloat(radius*-1, radius);
		pos[1] += GetRandomFloat(radius*-1, radius);
		CreateExplosion(pos);
	}
	return Plugin_Continue;
}

public Action Timer_StrikeTimeout(Handle timer)
{
	delete g_hTimer;
	return Plugin_Stop;
}

void CreateExplosion(float pos[3], const float duration = 6.0)
{
	static char buffer[32];

	int ent = CreateEntityByName("info_particle_system");
	if(ent != -1)
	{
		DispatchKeyValue(ent, "effect_name", FIRE_PARTICLE);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
		ActivateEntity(ent);

		AcceptEntityInput(ent, "Start");
		FormatEx(buffer, sizeof(buffer), "OnUser1 !self:Stop::%f:1", duration);
		SetVariantString(buffer);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
	FormatEx(buffer, sizeof(buffer), "OnUser1 !self:Kill::%f:1", duration+1.5);

	if((ent = CreateEntityByName("info_particle_system")) != -1)
	{
		DispatchKeyValue(ent, "effect_name", EXPLOSION_PARTICLE);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
		ActivateEntity(ent);

		AcceptEntityInput(ent, "Start");
		SetVariantString(buffer);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
	if((ent = CreateEntityByName("env_explosion")) != -1)
	{
		DispatchKeyValue(ent, "fireballsprite", "sprites/muzzleflash4.vmt");
		DispatchKeyValue(ent, "iMagnitude", "1");
		DispatchKeyValue(ent, "iRadiusOverride", "1");
		DispatchKeyValue(ent, "spawnflags", "828");
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);

		AcceptEntityInput(ent, "Explode");
		SetVariantString(buffer);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
	if((ent = CreateEntityByName("env_physexplosion")) != -1)
	{
		DispatchKeyValue(ent, "radius", "1");
		DispatchKeyValue(ent, "magnitude", "1");
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);

		AcceptEntityInput(ent, "Explode");
		SetVariantString(buffer);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}

	EmitAmbientSound(EXPLOSION_SOUND, pos);
	EmitAmbientSound(EXPLOSION_DEBRIS, pos);

	static const float power = 1.0, flMxDistance = 1.0;
	float orig[3], vec[3], result[3];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
		{
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", orig);
			if(GetVectorDistance(pos, orig) <= flMxDistance)
			{
				MakeVectorFromPoints(pos, orig, vec);
				GetVectorAngles(vec, result);

				GetEntPropVector(i, Prop_Data, "m_vecVelocity", vec);

				result[0] = Cosine(DegToRad(result[1])) * power + vec[0];
				result[1] = Sine(DegToRad(result[1])) * power + vec[1];
				result[2] = power;

				TeleportEntity(i, orig, NULL_VECTOR, result);
			}
		}
	}
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if ( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}
	if ( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

stock bool IsFinalMap()
{
	return (FindEntityByClassname(-1, "info_changelevel") == -1
		&& FindEntityByClassname(-1, "trigger_changelevel") == -1);
}