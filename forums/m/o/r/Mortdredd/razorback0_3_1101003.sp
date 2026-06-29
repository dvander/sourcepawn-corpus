//**********************************************************************************
//* Name: Razorback Utility Kit
//* Description: Snipers Razorback Utility Kit
//* Creator: Mortdredd
//**********************************************************************************

//**********************************************************************************
//* Includes
//**********************************************************************************

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "0.3"

//**********************************************************************************
//* Name: Handles
//* Description: Define New Handles
//**********************************************************************************
new Handle:sm_razorback_respawn_enable   = INVALID_HANDLE;
new Handle:sm_razorback_explode_enable = INVALID_HANDLE;
new Handle:sm_razorback_explode_radius = INVALID_HANDLE;
new Handle:sm_razorback_explode_damage = INVALID_HANDLE;
new Handle:sm_razorback_explode_mode   = INVALID_HANDLE;
new Handle:sm_razorback_burn_enable   = INVALID_HANDLE;

new orange;
new g_HaloSprite;
new g_ExplosionSprite;

//**********************************************************************************
//* Name: my info
//* Description: basic information about the plugin
//**********************************************************************************

public Plugin:myinfo = 
{
    name = "Razorback Respawner",
    author = "Mortdredd",
    description = "Snipers Razorback respawns after destruction",
    version = "0.1",
    url = "http://www.alliedmods.net"
}

//**********************************************************************************
//* Name: On Plugin Start - Event Handler
//* Description: Set up the Hooks etc
//**********************************************************************************

public OnPluginStart()
{
	//Cvars
	CreateConVar("sm_razorback_version", PLUGIN_VERSION, "Razorback Replenisher Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    sm_razorback_respawn_enable = CreateConVar("sm_razorback_respawn_enable","1","Enable/Disable respawning razorback", FCVAR_PLUGIN);
	sm_razorback_explode_enable = CreateConVar("sm_razorback_explode_enable","1","Enable/Disable exploding razorback", FCVAR_PLUGIN);
	sm_razorback_explode_radius = CreateConVar("sm_razorback_explode_radius","600","How far the explosion will damage people", FCVAR_PLUGIN);
	sm_razorback_explode_damage = CreateConVar("sm_razorback_explode_damage","220","How much damage the explosion does (def 220)", FCVAR_PLUGIN);
	sm_razorback_explode_mode   = CreateConVar("sm_razorback_explode_mode","0","Who the explosion targets (0=everyone 1=victim's team 2=attacker's team)", FCVAR_PLUGIN);
	sm_razorback_burn_enable = CreateConVar("sm_razorback_burn_enable","1","Enable/Disable razorback firetrap", FCVAR_PLUGIN);
	
	//Hooks
	HookEvent("player_shield_blocked",player_shield_blocked);
}

//**********************************************************************************
//* Name: On Map Start 
//* Description: // Prepare materials/sounds/etc. for Explosion
//**********************************************************************************

public OnMapStart()
{
	// Prepare materials/sounds/etc. for explode
	orange = PrecacheModel("materials/sprites/fire2.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound("ambient/explosions/explode_8.wav",true);
}

//**********************************************************************************
//* Name: The Event
//* Description:The durtah spaih stickin the Knife in!
//**********************************************************************************

public Action:player_shield_blocked(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetConVarInt(sm_razorback_respawn_enable) == 1)
	{
	new client_id = GetEventInt(event, "blocker_entindex");
    new client = GetClientOfUserId(client_id);
    if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{
       CreateTimer(0.5, GiveEquipment, client);
		}
	}
	
	if(GetConVarInt(sm_razorback_explode_enable) == 1 & ADMFLAG_CUSTOM1)
	{
	new victimId = GetClientOfUserId(GetEventInt(event,"userid"));
	Explode(victimId);
	}
	
	if(GetConVarInt(sm_razorback_burn_enable) == 1)
	{
	new client_id = GetEventInt(event, "attacker_entindex");
    new client = GetClientOfUserId(client_id);
    if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{
       TF2_IgnitePlayer(client, client);
		}
	}
}

//**********************************************************************************
//* Name: GiveEquipment
//* Description: create the timer that gives out Razorback
//**********************************************************************************

public Action:GiveEquipment(Handle:timer, any:client)
{
	new weapon = GetPlayerWeaponSlot(client, 1);
	if (IsValidEntity(weapon))
	{
		if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 57)
		{
		GivePlayerItem(client, "m_iItemDefinitionIndex", 57);
		}
	}
	CloseHandle(timer);
}

//**********************************************************************************
//* Name: Explosion
//* Description: Controls the Explosion
//**********************************************************************************

stock Explode(id)
{
	// First stuff here is mostly for show
	decl Float:location[3]
	GetClientAbsOrigin(id,location);
	new radius = GetConVarInt(sm_razorback_explode_radius);

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
	new damage = GetConVarInt(sm_razorback_explode_damage);
	new mode   = GetConVarInt(sm_razorback_explode_mode);
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