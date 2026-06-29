 //////////////////////////////////////////////
//
// SourceMod Script
//
// DoD BasicGore
//
// Developed by FeuerSturm
//
// - Thanks to all Beta Testers!
//
//////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "DoD BasicGore", 
	author = "FeuerSturm", 
	description = "Adds some more Blood/Gore to DoD:Source!", 
	version = PLUGIN_VERSION, 
	url = "http://www.dodsplugins.net"
}

new g_BloodSprite
new g_SpraySprite
new Handle:BasicGoreStatus = INVALID_HANDLE
new Handle:BasicGoreGibPlayers = INVALID_HANDLE
new Handle:BasicGoreMinDmg = INVALID_HANDLE
new Handle:BasicGoreLifeTime = INVALID_HANDLE
new Handle:BasicGoreBloodFountain = INVALID_HANDLE
new Handle:BasicGoreConstBleeding = INVALID_HANDLE
new Handle:BasicGoreLowHealth = INVALID_HANDLE
new Handle:BasicGoreHitBlood = INVALID_HANDLE
new Handle:BasicGoreDeathBloodSplash = INVALID_HANDLE
new Handle:BasicGoreHSFountain = INVALID_HANDLE
new Handle:BasicGoreHSBloodSplash = INVALID_HANDLE
new Handle:BasicGoreLowHealthOverlay = INVALID_HANDLE
new Handle:BasicGoreDeathOverlay = INVALID_HANDLE
new Handle:BasicGoreHSOverlay = INVALID_HANDLE
new bool:ExplodePlayer[MAXPLAYERS + 1]
new bool:g_bleeding[MAXPLAYERS + 1]
new bool:g_headshot[MAXPLAYERS + 1]
static const g_BloodColor[] =  { 85, 0, 0, 255 }

#define MAXBONES 8

new String:BoneModel[MAXBONES][] = 
{
	"models/gibs/hgibs.mdl", 
	"models/gibs/hgibs_rib.mdl", "models/gibs/hgibs_rib.mdl", "models/gibs/hgibs_rib.mdl", "models/gibs/hgibs_rib.mdl", 
	"models/gibs/hgibs_scapula.mdl", "models/gibs/hgibs_scapula.mdl", 
	"models/gibs/hgibs_spine.mdl"
}

new String:BloodSprites[2][] = 
{
	"materials/sprites/blood.vmt", "materials/sprites/bloodspray.vmt"
}

new String:BloodParticles[2][] = 
{
	"UnlitGeneric\r{\r\"$translucent\" 1\r\"$basetexture\" \"Decals/blood_gunshot_decal\"\r\"$vertexcolor\" 1\r}", 
	"materials/particle/particledefault.vmt"
}

new Handle:ParticleFile = INVALID_HANDLE

public OnPluginStart()
{
	CreateConVar("dod_basicgore_version", PLUGIN_VERSION, "DoD BasicGore Version (DO NOT CHANGE!)", FCVAR_DONTRECORD | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY)
	SetConVarString(FindConVar("dod_basicgore_version"), PLUGIN_VERSION)
	BasicGoreStatus = CreateConVar("dod_basicgore_status", "1", "<1/0> = enable/disable DoD BasicGore", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	BasicGoreMinDmg = CreateConVar("dod_basicgore_gibmindamage", "75", "<#> = set minimum of damage to explode players", FCVAR_PLUGIN, true, 1.0, true, 100.0)
	BasicGoreLifeTime = CreateConVar("dod_basicgore_giblifetime", "30", "<#> = set time in seconds bones stay on the map", FCVAR_PLUGIN, true, 5.0, true, 120.0)
	BasicGoreBloodFountain = CreateConVar("dod_basicgore_gibbloodfountain", "1", "<1/0> = enable/disable blood fountain while exploding", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	BasicGoreGibPlayers = CreateConVar("dod_basicgore_gibplayers", "1", "<1/0> = enable/disable exploding players on grenade/rocket impact", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	BasicGoreConstBleeding = CreateConVar("dod_basicgore_lowhealthbleeding", "1", "<1/0> = enable/disable some additional blood effects on low health", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	BasicGoreLowHealth = CreateConVar("dod_basicgore_lowhealthhp", "35", "<#> = amount of HP left for a player that will be considered as low health", FCVAR_PLUGIN, true, 1.0, true, 99.0)
	BasicGoreHitBlood = CreateConVar("dod_basicgore_hitblood", "1", "<1/0> = enable/disable blood particles on bullet impact", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	BasicGoreDeathBloodSplash = CreateConVar("dod_basicgore_deathbloodsplash", "1", "<1/0> = enable/disable displaying a big blood splash on deadly impacts", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	BasicGoreHSFountain = CreateConVar("dod_basicgore_hsbloodfountain", "1", "<1/0> = enable/disable bloodfountain on Headshots", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	BasicGoreHSBloodSplash = CreateConVar("dod_basicgore_hsbloodsplash", "1", "<1/0> = enable/disable blood splash for headshots", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	BasicGoreLowHealthOverlay = CreateConVar("dod_basicgore_lowhealthoverlay", "0", "<1/0> = enable/disable displaying blood on the screen on low health", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	BasicGoreDeathOverlay = CreateConVar("dod_basicgore_deathoverlay", "0", "<1/0> = enable/disable displaying blood on the screen on death", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	BasicGoreHSOverlay = CreateConVar("dod_basicgore_hsoverlay", "0", "<1/0> = enable/disable displaying blood on the screen on Headshots", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	HookEventEx("player_hurt", OnPlayerHurt, EventHookMode_Post)
	HookEventEx("player_death", OnPlayerDeath, EventHookMode_Post)
	HookEventEx("dod_stats_player_damage", OnPlayerDamage, EventHookMode_Pre)
	HookEventEx("dod_stats_player_killed", OnPlayerKilled, EventHookMode_Post)
	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
	if (!FileExists(BloodParticles[1], true))
	{
		ParticleFile = OpenFile(BloodParticles[1], "a")
		if (ParticleFile != INVALID_HANDLE)
		{
			WriteFileString(ParticleFile, BloodParticles[0], false)
			CloseHandle(ParticleFile)
		}
	}
	AutoExecConfig(true, "dod_basicgore", "dod_basicgore")
}

public OnMapStart()
{
	AddFileToDownloadsTable(BloodParticles[1])
	for (new i = 0; i < MAXBONES; i++)
	{
		if (!IsModelPrecached(BoneModel[i]))
		{
			PrecacheModel(BoneModel[i], true)
		}
	}
	PrecacheModel(BloodParticles[1], true)
	g_BloodSprite = PrecacheModel(BloodSprites[0], true)
	g_SpraySprite = PrecacheModel(BloodSprites[1], true)
}

public OnClientPostAdminCheck(client)
{
	ExplodePlayer[client] = false
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		g_bleeding[client] = false
		ExplodePlayer[client] = false
		g_headshot[client] = false
		ResetOverlay(client)
		return Plugin_Continue
	}
	return Plugin_Continue
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(BasicGoreStatus) == 0)
	{
		return Plugin_Continue
	}
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	if (attacker != 0)
	{
		return Plugin_Continue
	}
	new health = GetEventInt(event, "health")
	new damage = GetEventInt(event, "damage")
	if (health > 0 && health < GetConVarInt(BasicGoreLowHealth))
	{
		if (GetConVarInt(BasicGoreConstBleeding) == 1)
		{
			if (!g_bleeding[victim])
			{
				g_bleeding[victim] = true
				CreateTimer(1.0, ConstantBleeding, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE)
			}
		}
		if (GetConVarInt(BasicGoreLowHealthOverlay) == 1)
		{
			ShowLowHealthOverlay(victim)
		}
	}
	else if (health < 1)
	{
		if (GetConVarInt(BasicGoreDeathOverlay) == 1)
		{
			ShowDeathOverlay(victim)
		}
	}
	if (GetConVarInt(BasicGoreHitBlood) == 1)
	{
		HitBlood(victim, damage)
	}
	return Plugin_Continue
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(BasicGoreStatus) == 0)
	{
		return Plugin_Continue
	}
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	if (attacker != 0)
	{
		return Plugin_Continue
	}
	if (GetConVarInt(BasicGoreDeathBloodSplash) == 1)
	{
		KillBloodPuff(victim)
	}
	if (GetConVarInt(BasicGoreGibPlayers) == 1)
	{
		SetupPlayerExplosion(victim)
	}
	if (GetConVarInt(BasicGoreDeathOverlay) == 1)
	{
		ShowDeathOverlay(victim)
	}
	return Plugin_Continue
}

public Action:OnPlayerDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(BasicGoreStatus) == 0)
	{
		return Plugin_Continue
	}
	new victim = GetClientOfUserId(GetEventInt(event, "victim"))
	new damage = GetEventInt(event, "damage")
	new hitgroup = GetEventInt(event, "hitgroup")
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new weapon = GetEventInt(event, "weapon")
	new health = GetClientHealth(victim)
	if (health > 0)
	{
		if (GetConVarInt(BasicGoreHitBlood) == 1)
		{
			HitBlood(victim, damage)
		}
		if (health < GetConVarInt(BasicGoreLowHealth))
		{
			if (GetConVarInt(BasicGoreConstBleeding) == 1)
			{
				if (!g_bleeding[victim])
				{
					g_bleeding[victim] = true
					CreateTimer(1.0, ConstantBleeding, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE)
				}
			}
			if (GetConVarInt(BasicGoreLowHealthOverlay) == 1)
			{
				ShowLowHealthOverlay(victim)
			}
		}
	}
	else
	{
		if (victim == 0 || attacker == 0 || weapon < 17 || weapon > 28 || damage < GetConVarInt(BasicGoreMinDmg))
		{
			ExplodePlayer[victim] = false
		}
		else
		{
			ExplodePlayer[victim] = true
		}
		if (hitgroup == 1 && !ExplodePlayer[victim])
		{
			g_headshot[victim] = true
			if (GetConVarInt(BasicGoreHSFountain) == 1)
			{
				for (new i = 1; i < 10; i++)
				{
					HSBloodFountain(victim)
				}
			}
			if (GetConVarInt(BasicGoreHSBloodSplash) == 1)
			{
				HSBloodPuff(victim)
			}
			if (GetConVarInt(BasicGoreHSOverlay) == 1)
			{
				ShowHeadshotOverlay(victim)
			}
		}
		else
		{
			if (GetConVarInt(BasicGoreDeathBloodSplash) == 1)
			{
				KillBloodPuff(victim)
			}
			if (GetConVarInt(BasicGoreDeathOverlay) == 1)
			{
				ShowDeathOverlay(victim)
			}
		}
	}
	return Plugin_Continue
}

HSBloodPuff(victim)
{
	new Float:VictimHead[3]
	GetClientEyePosition(victim, VictimHead)
	VictimHead[2] += 10
	TE_SetupBloodSprite(VictimHead, NULL_VECTOR, g_BloodColor, 13, g_SpraySprite, g_BloodSprite)
	TE_SendToAll()
}

KillBloodPuff(victim)
{
	new Float:VictimBody[3]
	GetClientAbsOrigin(victim, VictimBody)
	VictimBody[2] += 20
	TE_SetupBloodSprite(VictimBody, NULL_VECTOR, g_BloodColor, 40, g_SpraySprite, g_BloodSprite)
	TE_SendToAll()
}

ExplodeBloodPuff(victim, Float:DeathOrigin[3])
{
	GetClientAbsOrigin(victim, DeathOrigin)
	TE_SetupBloodSprite(DeathOrigin, NULL_VECTOR, g_BloodColor, 60, g_SpraySprite, g_BloodSprite)
	TE_SendToAll()
}

public Action:OnPlayerKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"))
	if (g_bleeding[victim])
	{
		g_bleeding[victim] = false
	}
	if (GetConVarInt(BasicGoreStatus) == 0 || !ExplodePlayer[victim] || g_headshot[victim])
	{
		g_headshot[victim] = false
		return Plugin_Continue
	}
	if (GetConVarInt(BasicGoreGibPlayers) == 1)
	{
		SetupPlayerExplosion(victim)
	}
	return Plugin_Continue
}

public Action:ConstantBleeding(Handle:timer, any:victim)
{
	if (IsClientInGame(victim) && IsPlayerAlive(victim) && g_bleeding[victim])
	{
		new health = GetClientHealth(victim)
		if (health > 0 && health < GetConVarInt(BasicGoreLowHealth))
		{
			decl String:amount[4]
			IntToString((100 - health) / 2, amount, sizeof(amount))
			decl String:flags[] = "15"
			DisplayBlood(victim, amount, flags)
			return Plugin_Handled
		}
		else
		{
			g_bleeding[victim] = false
			ResetOverlay(victim)
			return Plugin_Stop
		}
	}
	g_bleeding[victim] = false
	return Plugin_Stop
}

public OnClientPutInServer(client)
{
	g_bleeding[client] = false
	g_headshot[client] = false
}

SetupPlayerExplosion(victim)
{
	new Float:DeathOrigin[3]
	GetClientAbsOrigin(victim, DeathOrigin)
	ExplodeBloodPuff(victim, DeathOrigin)
	new ShowBloodFount = GetConVarInt(BasicGoreBloodFountain)
	for (new i = 0; i < MAXBONES; i++)
	{
		PlayerExplode(DeathOrigin, BoneModel[i])
		if (ShowBloodFount == 1)
		{
			ExplodeBloodFountain(victim)
		}
	}
	RemoveRagdoll(victim)
}

PlayerExplode(Float:DeathOrigin[3], String:BoneMdl[])
{
	new Bone = CreateEntityByName("prop_physics")
	DispatchKeyValue(Bone, "model", BoneMdl)
	SetEntProp(Bone, Prop_Send, "m_CollisionGroup", 1)
	DispatchSpawn(Bone)
	DeathOrigin[0] += GetRandomFloat(1.0, 3.0)
	DeathOrigin[1] += GetRandomFloat(1.0, 3.0)
	DeathOrigin[2] += GetRandomFloat(10.0, 15.0)
	new Float:Velocity[3]
	Velocity[2] = GetRandomFloat(1.0, 5.0)
	new Float:Angles[3]
	Angles[2] = GetRandomFloat(25.0, 80.0)
	TeleportEntity(Bone, DeathOrigin, Angles, Velocity)
	CreateTimer(GetConVarFloat(BasicGoreLifeTime), RemoveBone, Bone, TIMER_FLAG_NO_MAPCHANGE)
}

DisplayBlood(client, String:amount[], String:flags[])
{
	new BloodSplash = CreateEntityByName("env_blood")
	DispatchSpawn(BloodSplash)
	DispatchKeyValue(BloodSplash, "color", "0")
	DispatchKeyValue(BloodSplash, "amount", amount)
	DispatchKeyValue(BloodSplash, "spawnflags", flags)
	AcceptEntityInput(BloodSplash, "EmitBlood", client)
	RemoveEdict(BloodSplash)
}

HSBloodFountain(victim)
{
	decl String:amount[] = "75.0"
	decl String:flags[] = "15"
	DisplayBlood(victim, amount, flags)
}

ExplodeBloodFountain(victim)
{
	decl String:amount[] = "5000.0"
	decl String:flags[] = "15"
	DisplayBlood(victim, amount, flags)
}

HitBlood(victim, damage)
{
	decl String:amount[4]
	IntToString(damage, amount, sizeof(amount))
	decl String:flags[] = "15"
	DisplayBlood(victim, amount, flags)
}

ShowDeathOverlay(victim)
{
	ClientCommand(victim, "r_screenoverlay effects/mh_blood1")
}

ShowLowHealthOverlay(victim)
{
	ClientCommand(victim, "r_screenoverlay effects/mh_blood2")
}

ShowHeadshotOverlay(victim)
{
	ClientCommand(victim, "r_screenoverlay effects/mh_blood3")
}

ResetOverlay(victim)
{
	ClientCommand(victim, "r_screenoverlay 0")
}

public Action:RemoveBone(Handle:Timer, any:Bone)
{
	if (IsValidEdict(Bone))
	{
		RemoveEdict(Bone)
	}
	return Plugin_Handled
}

RemoveRagdoll(victim)
{
	new Ragdoll = GetEntPropEnt(victim, Prop_Send, "m_hRagdoll")
	if (IsValidEdict(Ragdoll))
	{
		RemoveEdict(Ragdoll)
	}
} 