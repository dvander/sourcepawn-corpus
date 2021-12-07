#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = 
{
	name = "Pyro Explode v3",
	author = "teh_lame",
	description = "Pyros will explode upon death. Who they hurt and how badly is up to server admins.",
	version = "3.0",
	url = "http://www.phoneticlight.com"
}

new Handle:sm_pyro_explode_enable = INVALID_HANDLE;
new Handle:sm_pyro_explode_radius = INVALID_HANDLE;
new Handle:sm_pyro_explode_damage = INVALID_HANDLE;
new Handle:sm_pyro_explode_mode   = INVALID_HANDLE;

new orange;
new g_HaloSprite;
new g_ExplosionSprite;

public OnPluginStart()
{
	// Set up our convars, simple enough
	sm_pyro_explode_enable = CreateConVar("sm_pyro_explode_enable","1","Enable/Disable pyros exploding on death", FCVAR_PLUGIN);
	sm_pyro_explode_radius = CreateConVar("sm_pyro_explode_radius","600","How far the explosion will damage people", FCVAR_PLUGIN);
	sm_pyro_explode_damage = CreateConVar("sm_pyro_explode_damage","220","How much damage the explosion does (def 220)", FCVAR_PLUGIN);
	sm_pyro_explode_mode   = CreateConVar("sm_pyro_explode_mode","0","Who the explosion targets (0=everyone 1=victim's team 2=attacker's team)", FCVAR_PLUGIN);
	HookEvent("player_death",Event_PlayerDeath,EventHookMode_Pre);
}

public OnMapStart()
{
	// Prepare materials/sounds/etc. for plugin
	orange = PrecacheModel("materials/sprites/fire2.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound("ambient/explosions/explode_8.wav",true);
}
	
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// id for victim
	new victimId = GetClientOfUserId(GetEventInt(event,"userid"));
	
	// If mod is enabled..
	if(GetConVarBool(sm_pyro_explode_enable))
	{
		// and victim is a pyro...
		if((TF2_GetPlayerClass(victimId) == TFClass_Pyro) && (IsClientInGame(victimId)))
		{
			// BOOM
			Explode(victimId);		
		}
	}
	
	return Plugin_Continue;
}

// Function to explode based on victim details
stock Explode(id)
{
	// First stuff here is mostly for show
	decl Float:location[3]
	GetClientAbsOrigin(id,location);
	new radius = GetConVarInt(sm_pyro_explode_radius);

	new color[4]={188,220,255,200};
	Boom("ambient/explosions/explode_8.wav", location);
	TE_SetupExplosion(location,g_ExplosionSprite,10.0,1,0,radius,5000);
	TE_SendToAll();
	TE_SetupBeamRingPoint(location,10.0,500.0,orange,g_HaloSprite,0,10,0.6,10.0,0.5,color,10,0);
	TE_SendToAll();

	location[2] += 10;
	Boom("ambient/explosions/explode_8.wav",location);
	TE_SetupExplosion(location,g_ExplosionSprite,10.0,1,0,radius,5000);
	TE_SendToAll();

	// We actually start hurting people here.
	new damage = GetConVarInt(sm_pyro_explode_damage);
	new mode   = GetConVarInt(sm_pyro_explode_mode);
	location[2] -= 10;
	new maxClients = GetMaxClients();

	for (new i = 1; i < maxClients; ++i) {
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || id == i)
			continue;
		if (((mode == 1) && (GetClientTeam(i) != GetClientTeam(id)))
				|| ((mode == 2) && (GetClientTeam(i) == GetClientTeam(id))))
			continue;
		
		new Float:pos[3];
		GetClientEyePosition(i,pos);
		new Float:distance = GetVectorDistance(location,pos);
		if (distance > radius)
			continue;
		
		damage = RoundToFloor(damage * (radius - distance) / radius);
		SlapPlayer(i,damage,false);
		TE_SetupExplosion(pos,g_ExplosionSprite,0.05,1,0,1,1);
		TE_SendToAll();
	}
}

public Boom(const String:sound[],const Float:orig[3])
{
	// Simply play the given sound with the given origin
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}
