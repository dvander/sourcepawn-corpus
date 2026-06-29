#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define FADE_IN  0x0001
#define FADE_OUT 0x0002

public Plugin:myinfo = 
{
	name = "Pyro Explosions",
	author = "Twilight Suzuka",
	description = "Pyro's explode and make things explode",
	version = "Alpha:1",
	url = "http://www.sourcemod.net/"
};

new Handle:Cvar_Enable = INVALID_HANDLE;
new Handle:Cvar_PyroDamages = INVALID_HANDLE

new fire;
new white;
new g_HaloSprite;
new g_ExplosionSprite;

public OnPluginStart()
{
	Cvar_Enable = CreateConVar("pyro_explode_on", "1", "1 turns the plugin on 0 is off", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_PyroDamages = CreateConVar("pyro_explode_objects", "0", "Objects pyro's destroy explode", FCVAR_PLUGIN)
	
	HookEventEx("player_death", PyroModify, EventHookMode_Pre);
	HookEventEx("object_destroyed", PyroObjectModify, EventHookMode_Pre);
}

public OnMapStart()
{
	fire=PrecacheModel("materials/sprites/fire2.vmt");
	white=PrecacheModel("materials/sprites/white.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");

	PrecacheSound( "ambient/explosions/explode_8.wav", true);
}

public Action:PyroModify(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Cvar_Enable)) return Plugin_Continue;
	
	new id = GetClientOfUserId(GetEventInt(event,"userid"));

	if(TF2_GetPlayerClass(id) == TFClass_Pyro)
	{
		PyroEffect(id);
	}
	
	return Plugin_Continue;
}

public Action:PyroObjectModify(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Cvar_Enable)) return Plugin_Continue;
	if(GetConVarInt(Cvar_PyroDamages)) return Plugin_Continue;
	
	if(TF2_GetPlayerClass(GetClientOfUserId(GetEventInt(event,"attacker"))) == TFClass_Pyro)
	{
		PyroEffect(GetClientOfUserId(GetEventInt(event,"userid")));
	}
	
	return Plugin_Continue;
}

stock PyroEffect(id)
{
	decl Float:forigin[3]
	GetClientAbsOrigin(id, forigin);
			
	PyroExplode(forigin);
	PyroExplode2(forigin);
		
	ExplosionDamage(forigin);
}

stock ExplosionDamage(Float:origin[3])
{
	new maxplayers = GetMaxClients();
	
	decl Float:PlayerVec[3], Float:distance
	for(new i = 1; i <= maxplayers; i++)
	{
		if( !IsClientInGame(i) || !IsPlayerAlive(i) ) continue;
		GetClientAbsOrigin(i, PlayerVec);
		
		distance = GetVectorDistance(origin, PlayerVec, true);
		if(distance > 2000.0) continue;
		
		new dmg = RoundFloat(2000.0 - distance) / 20;
		SetEntityHealth(i,GetClientHealth(i) - dmg);
	}
}

public PyroExplode(Float:vec1[3])
{
	new color[4]={188,220,255,200};
	EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 0, 750); // 600
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 500.0, white, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
  	TE_SendToAll();
}

public PyroExplode2(Float:vec1[3])
{
	vec1[2] += 10;
	new color[4]={188,220,255,255};
	EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 0, 1000); // 600
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 750.0, fire, g_HaloSprite, 0, 66, 6.0, 128.0, 0.2, color, 25, 0);
  	TE_SendToAll();
}

public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}