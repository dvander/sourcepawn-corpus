#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Player Explode",
	author = "TechKnow & Twilight Suzuka",
	description = "Player explodes on death",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

new Handle:Cvar_ExplodeEnable = INVALID_HANDLE;

new orange;
new g_HaloSprite;
new g_ExplosionSprite;

public OnPluginStart()
{
        CreateConVar("sm_playerexplode_version", PLUGIN_VERSION, "Player Explode Version",         FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	Cvar_ExplodeEnable = CreateConVar("explode_on", "1", "1 explosions on 0 is off", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEventEx("player_death", Explode, EventHookMode_Pre);
}

public OnMapStart()
{
	orange=PrecacheModel("materials/sprites/fire2.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound( "ambient/explosions/explode_8.wav", true);
}

public Action:Explode(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (!GetConVarBool(Cvar_ExplodeEnable))
	{
		return Plugin_Continue;
	}
	new id = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsClientInGame(id))
	{
		ExplodePlayer(id);
	}
	
	return Plugin_Continue;
}

stock ExplodePlayer(id)
{
	decl Float:location[3]
	GetClientAbsOrigin(id, location);
			
	Explode1(location);
	Explode2(location);
}

public Explode1(Float:vec1[3])
{
	new color[4]={188,220,255,200};
	Boom("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 500.0, orange, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
  	TE_SendToAll();
}

public Explode2(Float:vec1[3])
{
	vec1[2] += 10;
	Boom("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
}

public Boom(const String:sound[],const Float:orig[3])
{
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}