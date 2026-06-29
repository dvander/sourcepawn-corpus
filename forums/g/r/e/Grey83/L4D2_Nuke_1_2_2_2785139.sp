#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools>

static const char
	PL_NAME[]			= "L4D2 Nuke",
	PL_VER[]			= "1.2.2",

	NUKE_SOUND[]		= "animation/overpass_jets.wav",
	FIRE_PARTICLE[]		= "gas_explosion_ground_fire",
	EXPLOSION_SOUND[]	= "ambient/explosions/explode_1.wav",
	EXPLOSION_DEBRIS[]	= "animation/plantation_exlposion.wav",
	EXPLOSION_PARTICLE[]= "FluidExplosion_fps";

enum
{
	FFADE_IN		= 0x0001,
	FFADE_OUT		= 0x0002,
	FFADE_MODULATE	= 0x0004,
	FFADE_STAYOUT	= 0x0008,
	FFADE_PURGE		= 0x0010
};

float fNuke, fAnnounce, fEnd;
Handle hTimer, hStrike;
bool bWarning, bFading, bExplosion;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "City Will Be Nuked After Countdown Time Passes",
	author		= "alasfourom, Grey83",
	url			= "https://forums.alliedmods.net/showthread.php?t=338742"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_nuke_version", PL_VER, PL_NAME, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar cvar;
	cvar = CreateConVar("l4d2_nuke_timer", "600.0", "Set The Time In Seconds At Which Players Will Be Nuked", FCVAR_NOTIFY, true, 1.0, true, 5400.0);
	cvar.AddChangeHook(CVarChange_Nuke);
	fNuke = cvar.FloatValue;

	cvar = CreateConVar("l4d2_nuke_announcer", "90.0", "At What Time In Seconds You Want The Hint Text Announcement To Be Displayed", FCVAR_NOTIFY, true, _, true, 5400.0);
	cvar.AddChangeHook(CVarChange_Announce);
	fAnnounce = cvar.FloatValue;

	cvar = CreateConVar("l4d2_nuke_warning", "1", "Display Nuke Warning Text When Players Leave Saferoom", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Warning);
	bWarning = cvar.BoolValue;

	cvar = CreateConVar("l4d2_nuke_fade", "1", "Allow White Fading Effect When Players Are Nuked", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Fading);
	bFading = cvar.BoolValue;

	cvar = CreateConVar("l4d2_nuke_explosion", "1", "Allow Explosion Effect When Players Are Nuked [ Disable If The Explosion Crashes Your Game ]", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Explosion);
	bExplosion = cvar.BoolValue;

	AutoExecConfig(true, "L4D2_Nuke");

	RegConsoleCmd("sm_nuke", Cmd_Nuke, "Print Nuke Countdown To Players");

	HookEvent("player_left_start_area", Event_LeftStartArea, EventHookMode_PostNoCopy);
	HookEvent("player_entered_checkpoint", Event_EnteredCheckPoint);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public void CVarChange_Nuke(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fNuke = cvar.FloatValue;
}

public void CVarChange_Announce(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fAnnounce = cvar.FloatValue;
}

public void CVarChange_Warning(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bWarning = cvar.BoolValue;
}

public void CVarChange_Fading(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bFading = cvar.BoolValue;
}

public void CVarChange_Explosion(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bExplosion = cvar.BoolValue;
}

public void OnMapStart()
{
	PrecacheSound(NUKE_SOUND);
	PrecacheSound(EXPLOSION_SOUND);
	PrecacheSound(EXPLOSION_DEBRIS);

	StopTimers();
}

stock void StopTimers()
{
	if(hTimer) delete hTimer;
	if(hStrike) delete hStrike;
}

public void OnMapEnd()
{
	StopTimers();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	StopTimers();
}

public void Event_LeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	if(hTimer) return;
/*
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client) return;
*/
	fEnd = GetEngineTime() + fNuke;
	hTimer = CreateTimer(fNuke - fAnnounce, Timer_StartCountDown);

	if(bWarning)
	{
		int time = RoundToNearest(fNuke);
		PrintToChatAll("\x04[Warning] \x01Nuke Countdown Started: \x03%d min %d sec", time / 60, time % 60);
	}
}

public void Event_EnteredCheckPoint(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientSurvivor(client)) StopTimers();
}

public Action Cmd_Nuke(int client, int args)
{
	if(hTimer)
	{
		int timeleft = RoundToNearest(fEnd - GetEngineTime());
		if(timeleft > 0)
			PrintToChatAll("\x04[Warning] \x01Nuke Timeleft: \x03%d min %d sec", timeleft / 60, timeleft % 60);
		else PrintToChat(client, "\x04[Warning] \x03%N, \x01You Have Been \x05Nuked", client);
	}
	else
	{
		int timestart = RoundToNearest(fNuke);
		PrintToChatAll("\x04[Warning] \x01Nuke Timeleft: \x03%d min %d sec", timestart / 60, timestart % 60);
	}

	return Plugin_Handled;
}

public Action Timer_StartCountDown(Handle timer)
{
	hTimer = CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT);
	TriggerTimer(hTimer);
	return Plugin_Stop;
}

public Action Timer_CountDown(Handle timer, int client)
{
	float time = fEnd - GetEngineTime();
	if(time >= 0.0)
	{
		PrintHintTextToAll("Nuke Timer: %d", RoundToNearest(time));
		return Plugin_Continue;
	}

	EmitSoundToAll(NUKE_SOUND);

	if(bFading) CreateTimer(0.1, Timer_FadePlayers, _, TIMER_FLAG_NO_MAPCHANGE);

	CreateTimer(2.5, Timer_Incap, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(6.0, Timer_SlayPlayers, _, TIMER_FLAG_NO_MAPCHANGE);

	if(bExplosion)
	{
		hStrike = CreateTimer(2.0, Timer_Strike, _, TIMER_REPEAT);
		CreateTimer(6.0, Timer_StrikeTimeout, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	hTimer = null;
	return Plugin_Stop;
}

public Action Timer_FadePlayers(Handle timer)
{
	CreateTimer(0.1, Timer_FadeIn, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public Action Timer_FadeIn(Handle timer)
{
	CreateFade(FFADE_OUT);
	CreateTimer(2.5, Timer_FadeOut, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public Action Timer_FadeOut(Handle timer)
{
	CreateFade(FFADE_IN);
	return Plugin_Stop;
}

stock void CreateFade(int type)
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
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		SetEntityHealth(i, 1);
		SDKHooks_TakeDamage(i, i, i, 100.0);
	}
	return Plugin_Stop;
}

public Action Timer_SlayPlayers(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientSurvivor(i)) ForcePlayerSuicide(i);
	return Plugin_Stop;
}

public Action Timer_Strike(Handle timer)
{
	float radius = 1.0, pos[3];

	for(int i = 1; i <= MaxClients; i++) if(IsClientSurvivor(i, false))
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
	if(hTimer) delete hTimer;
	return Plugin_Stop;
}

stock void CreateExplosion(float pos[3], const float duration = 6.0)
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

	EmitAmbientGenericSound(pos, EXPLOSION_SOUND);
	EmitAmbientGenericSound(pos, EXPLOSION_DEBRIS);

	static const float power = 1.0, flMxDistance = 1.0;
	float orig[3], vec[3], result[3];
	for(int i = 1; i <= MaxClients; i++) if(IsClientSurvivor(i))
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

stock void EmitAmbientGenericSound(float pos[3], const char[] snd)
{
	int ent = CreateEntityByName("ambient_generic");
	if(ent == -1) return;

	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(ent, "message", snd);
	DispatchKeyValue(ent, "health", "10");
	DispatchKeyValue(ent, "spawnflags", "48");
	DispatchSpawn(ent);
	ActivateEntity(ent);

	AcceptEntityInput(ent, "PlaySound");
	AcceptEntityInput(ent, "Kill");
}

stock bool IsClientSurvivor(int client, bool alive = true)
{
	return IsClientInGame(client) && (!alive || IsPlayerAlive(client)) && GetClientTeam(client) == 2;
}