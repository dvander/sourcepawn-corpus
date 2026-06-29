#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "[L4D] Christmas on Bloody Witch //^_^\\",
    author = "Dragokas",
    description = "Happy New Year and Merry Christmas!!!",
    version = "1.1",
    url = "https://dragokas.com/"
}

#define ENABLE_SOUND 1
#define ENABLE_FLY_BALLS 1
#define ENABLE_FIREFLY 1
#define ENABLE_SNOW 1
#define ENABLE_WIND 1
#define ENABLE_RAIN 1 // use with ENABLE_SNOW

const int MAX_PARTICLE_LIGHTS = 10;

/*
	ChangeLog:
	
	1.0
	 - First release
*/

int g_iParticleLight = 0;

ArrayList g_SoundPath;
int g_iSndIdx = -1;

int g_iSnowing;

public void OnPluginStart()
{
	g_SoundPath = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	
	HookEvent("round_start", 			Event_RoundStart,	EventHookMode_PostNoCopy);
	
	SetRandomSeed(GetTime());
}

stock void AddSounds()
{
	g_SoundPath.PushString("jinge/Jingle_10_mario.mp3");
	g_SoundPath.PushString("jinge/Jingle_11_voice_w.mp3");
	g_SoundPath.PushString("jinge/Jingle_12_ding.mp3");
	g_SoundPath.PushString("jinge/Jingle_13_ding_range.mp3");
	g_SoundPath.PushString("jinge/Jingle_15_dog.mp3");
	g_SoundPath.PushString("jinge/Jingle_16_voice_m.mp3");
	g_SoundPath.PushString("jinge/Jingle_17_RMB.mp3");
	g_SoundPath.PushString("jinge/Jingle_1_ding.mp3");
	g_SoundPath.PushString("jinge/Jingle_2_ding.mp3");
	g_SoundPath.PushString("jinge/Jingle_3_progressive.mp3");
	g_SoundPath.PushString("jinge/Jingle_4_ding+.mp3");
	g_SoundPath.PushString("jinge/Jingle_5_ding.mp3");
	g_SoundPath.PushString("jinge/Jingle_8_bit.mp3");
	g_SoundPath.PushString("jinge/Jingle_9_idiot.mp3");
	g_SoundPath.PushString("jinge/Festive_Cheer2.mp3");
	g_SoundPath.PushString("jinge/Winter_Wonder2.mp3");
}

public void Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	g_iSnowing = 0;

	#if ENABLE_SNOW || ENABLE_WIND
		CreateTimer(10.0, Timer_WeatherDelayed, 0, TIMER_FLAG_NO_MAPCHANGE);
	#endif
	
	#if ENABLE_SNOW
		CreateTimer(GetRandomFloat(120.0, 180.0), Timer_ManageSnow, 0, TIMER_FLAG_NO_MAPCHANGE); // 5 min
	#endif
	
	#if ENABLE_WIND
		CreateTimer(30.0, Timer_ManageWind, 0, TIMER_FLAG_NO_MAPCHANGE); // 30 sec.
	#endif
	
	#if ENABLE_FIREFLY
	CreateTimer(300.0, Timer_LoadFireFly, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(600.0, Timer_LoadFireFly, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	#endif
	
	g_iParticleLight = 0;
}

public Action Timer_WeatherDelayed(Handle timer)
{
	#if ENABLE_SNOW
		g_iSnowing = 1;
		ServerCommand("sm_snows");
	#endif
	#if ENABLE_WIND
		ServerCommand("sm_wind");
	#endif
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		OnClientInGame(client);
	}
}

void OnClientInGame(int client)
{
	#if ENABLE_FLY_BALLS
		if (g_iParticleLight <= MAX_PARTICLE_LIGHTS) {
			CreateTimer(0.1, Timer_LoadParticles, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(15.0, Timer_LoadParticles, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(25.0, Timer_LoadParticles, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	#endif
	
	#if ENABLE_SOUND
		CreateTimer(17.0, Timer_PlayMusic, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);	
	#endif
}

public Action Timer_PlayMusic(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if (client != 0 && IsClientInGame(client)) {
		
		char sPath[PLATFORM_MAX_PATH];
		g_SoundPath.GetString(g_iSndIdx, sPath, sizeof(sPath));
		
		EmitSoundToClient(client, sPath, _, _, SNDLEVEL_GUNFIRE, _, 1.0);
	}
	return Plugin_Continue;
}

public Action Timer_LoadParticles(Handle timer, int UserId)
{
	int cnt = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2) {
			if (g_iParticleLight <= MAX_PARTICLE_LIGHTS)
				SpawnEffect(i, "runway_lights");
			g_iParticleLight++;
			cnt++;
			if (cnt >= 4) break;
		}
	}
	
	#if ENABLE_FIREFLY
		CreateTimer(10.0, Timer_LoadFireFly, UserId, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	#endif
	return Plugin_Continue;
}

public Action Timer_LoadFireFly(Handle timer, int UserId)
{
	static int iTimes = 0;
	CreateTimer(1.0, Timer_LoadFireFlySeveral, UserId, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	iTimes += 1;
	if (iTimes % 10 == 0) return Plugin_Stop;
	return Plugin_Continue;
}

public Action Timer_LoadFireFlySeveral(Handle timer, int UserId)
{
	static int iTimes = 0;
	
	int client = GetClientOfUserId(UserId);
	if (client == 0 || !IsClientInGame(client))
		client = GetAnyValidClient();
	
	if (client != 0) {
		if (g_iSnowing == 0)
		{
			SpawnEffect(client, "Fireflies_cornfield");
		}
	}
	
	iTimes += 1;
	if (iTimes % 5 == 0) return Plugin_Stop;
	return Plugin_Continue;
}

int GetAnyValidClient()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			return i;
	}
	return 0;
}

void SpawnEffect(int client, char[] sParticleName)
{
	float pos[3];
//	GetClientAbsOrigin(client, pos);
	GetClientEyePosition(client, pos);
	int iEntity = CreateEntityByName("info_particle_system", -1);
	if (iEntity != -1)
	{
		DispatchKeyValue(iEntity, "effect_name", sParticleName);
		DispatchKeyValueVector(iEntity, "origin", pos);
		DispatchSpawn(iEntity);
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", client);
		ActivateEntity(iEntity);
		AcceptEntityInput(iEntity, "Start");
		SetVariantString("OnUser1 !self:kill::1.5:1");
		AcceptEntityInput(iEntity, "AddOutput");
		AcceptEntityInput(iEntity, "FireUser1");
	}
}

stock void PrecacheEffect(const char[] sEffectName) // thanks to _GamerX
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("EffectDispatch");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}

stock void PrecacheParticleEffect(const char[] sEffectName) // thanks to _GamerX
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("ParticleEffectNames");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}  

public void OnMapStart()
{
	PrecacheEffect("ParticleEffect");
	PrecacheGeneric("particles/environmental_fx.pcf", true);
	
	#if ENABLE_FLY_BALLS
		PrecacheParticleEffect("runway_lights");
	#endif
	
	#if ENABLE_FIREFLY
		PrecacheParticleEffect("Fireflies_cornfield");
	#endif
	
	#if ENABLE_SOUND
		if (g_iSndIdx != -1)
		{
			g_SoundPath.Erase(g_iSndIdx);
		}
		if (g_SoundPath.Length == 0)
		{
			AddSounds();
		}
		g_iSndIdx = GetRandomInt(0, g_SoundPath.Length - 1);
		
		char sSoundPath[PLATFORM_MAX_PATH];
		char sDLPath[PLATFORM_MAX_PATH];
		g_SoundPath.GetString(g_iSndIdx, sSoundPath, sizeof(sSoundPath));
		Format(sDLPath, sizeof(sDLPath), "sound/%s", sSoundPath);
		AddFileToDownloadsTable(sDLPath);
		PrecacheSound(sSoundPath);
	#endif
}

public Action Timer_ManageWind(Handle timer, int iAction)
{
	ServerCommand("sm_wind");
	CreateTimer( iAction == 0 ? GetRandomFloat(5.0, 60.0) : GetRandomFloat(40.0, 60.0), Timer_ManageWind, iAction, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_ManageSnow(Handle timer, int iAction)
{
	switch(iAction) {
		case 0: { // disable
			g_iSnowing ^= 1;
			ServerCommand("sm_snows");
			if (GetRandomInt(0, 1) == 1) {
				#if ENABLE_RAIN
					ServerCommand("sm_rains");
					CreateTimer(GetRandomFloat(30.0, 60.0), Timer_ManageRain, 0, TIMER_FLAG_NO_MAPCHANGE);
				#endif
			}
			CreateTimer(GetRandomFloat(30.0, 60.0), Timer_ManageSnow, 1, TIMER_FLAG_NO_MAPCHANGE);
		}
		case 1: { //enable
			g_iSnowing ^= 1;
			ServerCommand("sm_snows");
			CreateTimer(GetRandomFloat(120.0, 180.0), Timer_ManageSnow, 1, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action Timer_ManageRain(Handle timer, int iAction)
{
	ServerCommand("sm_rains");
	return Plugin_Continue;
}