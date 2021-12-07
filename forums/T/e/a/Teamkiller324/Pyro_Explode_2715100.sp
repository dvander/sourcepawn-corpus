#include	<sourcemod>
#include	<sdktools>
#include	<tf2>
#include	<tf2_stocks>

#pragma		semicolon 1
#pragma 	newdecls required

#define		FADE_IN  0x0001
#define		FADE_OUT 0x0002

Plugin myinfo = 
{
	name		=	"Pyro Explosions",
	author		=	"Twilight Suzuka",
	description	=	"Pyro's explode and make things explode",
	version		=	"1.0.1",
	url			=	"http://www.sourcemod.net/"
};

ConVar	Cvar_Enable,
		Cvar_PyroDamages;

int fire,
	white,
	g_HaloSprite,
	g_ExplosionSprite;

public void OnPluginStart()
{
	Cvar_Enable			= CreateConVar("tf_pyro_explode",			"1",	"Determine if plugin should be on/off \n0 = Off \n1 = On",	FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_PyroDamages	= CreateConVar("tf_pyro_explode_objects",	"0",	"Objects pyro's destroy explode");
	
	HookEventEx("player_death",		PyroModify,			EventHookMode_Pre);
	HookEventEx("object_destroyed",	PyroObjectModify,	EventHookMode_Pre);
}

public void OnMapStart()
{
	fire				=	PrecacheModel("materials/sprites/fire2.vmt");
	white				=	PrecacheModel("materials/sprites/white.vmt");
	g_HaloSprite		=	PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite	=	PrecacheModel("sprites/sprite_fire01.vmt");

	PrecacheSound("ambient/explosions/explode_8.wav", true);
}

Action PyroModify(Event event, const char[] name, bool dontBroadcast)
{
	if(Cvar_Enable.BoolValue)
		return Plugin_Continue;
		
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(TF2_GetPlayerClass(client) == TFClass_Pyro)
		PyroEffect(client);
	
	return Plugin_Continue;
}

Action PyroObjectModify(Event event, const char[] name, bool dontBroadcast)
{
	if(Cvar_Enable.BoolValue)
		return Plugin_Continue;
	if(Cvar_PyroDamages.BoolValue)
		return Plugin_Continue;
	
	if(TF2_GetPlayerClass(GetClientOfUserId(GetEventInt(event,"attacker"))) == TFClass_Pyro)
		PyroEffect(GetClientOfUserId(GetEventInt(event,	"userid")));
	
	return Plugin_Continue;
}

void PyroEffect(int client)
{
	float origin[3];
	GetClientAbsOrigin(client, origin);
			
	PyroExplode(origin);
	PyroExplode2(origin);
		
	ExplosionDamage(origin);
}

void ExplosionDamage(float origin[3])
{
	int maxplayers = MaxClients;
	
	float PlayerVec[3], distance;
	for(int i = 1; i <= maxplayers; i++)
	{
		if( !IsClientInGame(i) || !IsPlayerAlive(i) ) continue;
		GetClientAbsOrigin(i, PlayerVec);
		
		distance = GetVectorDistance(origin, PlayerVec, true);
		if(distance > 2000.0) continue;
		
		int dmg = RoundFloat(2000.0 - distance) / 20;
		SetEntityHealth(i, GetClientHealth(i) - dmg);
	}
}

void PyroExplode(float vec1[3])
{
	int color[4]={188,220,255,200};
	EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 0, 750); // 600
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 500.0, white, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
  	TE_SendToAll();
}

void PyroExplode2(float vec1[3])
{
	vec1[2] += 10;
	int color[4]={188,220,255,255};
	EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 0, 1000); // 600
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 750.0, fire, g_HaloSprite, 0, 66, 6.0, 128.0, 0.2, color, 25, 0);
  	TE_SendToAll();
}

void EmitSoundFromOrigin(const char[] sound, const float orig[3])
{
	EmitSoundToAll(sound, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1,	orig, NULL_VECTOR, true, 0.0);
}