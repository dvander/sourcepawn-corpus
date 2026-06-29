#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <dhooks>
#include <tf2attributes>

#define VERSION "1.0"

#define MAX_EDICTS 2048

#define ROCKET_DAMAGE 180.0
#define ROCKET_SPEED 1500.0

#define STATE_CYBERDEMON_WALK 0
#define STATE_CYBERDEMON_AIM 1
#define STATE_CYBERDEMON_FIRE 2

#define SPRITE_F 0
#define SPRITE_RF 1
#define SPRITE_R 2
#define SPRITE_LB 3
#define SPRITE_B 4
#define SPRITE_RB 5
#define SPRITE_L 6
#define SPRITE_LF 7

public Plugin myinfo = 
{
	name = "[TF2] (Doom) Be the Cyberdemon",
	author = "Bloomstorm",
	description = "Be the Cyberdemon",
	version = "1.0",
}

bool g_bIsBoss[MAXPLAYERS + 1];
int g_iCyberdemonSprites[MAXPLAYERS + 1][8];
//int g_iCyberdemonAimSprites[MAXPLAYERS + 1][8];
int g_iCyberdemonFireSprites[MAXPLAYERS + 1][8];
float g_flBossSightCooldown[MAXPLAYERS + 1];
float g_flBossWalkCooldown[MAXPLAYERS + 1];
float g_flBossSightRaycastCooldown[MAXPLAYERS + 1];
float g_flBossAttackCooldown[MAXPLAYERS + 1];
float g_flBossDamageCooldown[MAXPLAYERS + 1];
int g_iBossAttackState[MAXPLAYERS + 1];
bool g_bBossWalked[MAXPLAYERS + 1];

Handle g_hIsDeflectable;
Handle g_hIsDestroyable;

ConVar g_CVar_no_dominations;
ConVar g_CVar_melee_push;
ConVar g_CVar_default_rocket;
ConVar g_CVar_max_cyberdemons;
ConVar g_CVar_no_heal;

// TODO: Replace with ArrayList
int g_iRocketSprites[MAX_EDICTS + 1][8];
bool g_bSignatureLaughFallback;

public void OnPluginStart()
{
	RegAdminCmd("sm_cyberdemon", Cmd_Cyberdemon, ADMFLAG_BAN);
	
	CreateConVar("sm_cyberdemon_version", VERSION, "Plugin version", FCVAR_NOTIFY);
	g_CVar_no_dominations = CreateConVar("sm_cyberdemon_no_dominations", "0", "Allow cyberdemon to dominate on players? 0 - Allow, 1 - Allow, but clear on cyberdemon death, 2 - Disallow");
	g_CVar_melee_push = CreateConVar("sm_cyberdemon_melee_push", "1", "Push away victims after cyberdemon's punch? 0 - No, 1 - Yes");
	g_CVar_default_rocket = CreateConVar("sm_cyberdemon_default_rocket", "0", "Use default 3D soldier rocket instead of sprites? 0 - No, 1 - Yes");
	g_CVar_max_cyberdemons = CreateConVar("sm_cyberdemon_max_cyberdemons", "8", "Max cyberdemons to have to avoid edict overflow: 0 - No limit");
	g_CVar_no_heal = CreateConVar("sm_cyberdemon_no_heal", "0", "Disallow medics to heal cyberdemon? 0 - Allow, 1 - Disallow");
	
	GameData hGamedata = LoadGameConfigFile("tf2.cyberdemon");
	
	if (hGamedata == null)
	{
		SetFailState("No tf2.cyberdemon.txt gamedata");
	}
	
	int iOffset;
	
	iOffset = GameConfGetOffset(hGamedata, "CTFProjectileRocket::IsDeflectable");
	g_hIsDeflectable = DHookCreate(iOffset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, Hook_Rocket_IsDeflectable);
	
	iOffset = GameConfGetOffset(hGamedata, "CTFBaseProjectile::IsDestroyable");
	g_hIsDestroyable = DHookCreate(iOffset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, Hook_Rocket_IsDestroyable);
	
	DynamicDetour hDetour;
	hDetour = DynamicDetour.FromConf(hGamedata, "CTFPlayer::CanBeForcedToLaugh");
	if (hDetour)
	{
		hDetour.Enable(Hook_Pre, Hook_TFPlayer_CanBeForcedToLaugh);
		hDetour.Enable(Hook_Post, Hook_TFPlayer_CanBeForcedToLaugh);
	}
	else
	{
		// Looks like signature is outdated, using TF2_OnConditionAdded hook
		g_bSignatureLaughFallback = true;
	}
	
	delete hDetour;
	
	delete hGamedata;
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
	HookEvent("player_domination", Event_PlayerDomination);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
	}
}

public void OnMapStart()
{
	PrecacheModel("materials/doom/proj_rocket/v1/back.vmt");
	PrecacheModel("materials/doom/proj_rocket/v1/back_left.vmt");
	PrecacheModel("materials/doom/proj_rocket/v1/back_right.vmt");
	PrecacheModel("materials/doom/proj_rocket/v1/front.vmt");
	PrecacheModel("materials/doom/proj_rocket/v1/front_left.vmt");
	PrecacheModel("materials/doom/proj_rocket/v1/front_right.vmt");
	PrecacheModel("materials/doom/proj_rocket/v1/left.vmt");
	PrecacheModel("materials/doom/proj_rocket/v1/right.vmt");
	
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/back.vmt");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/back.vtf");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/back_left.vmt");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/back_left.vtf");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/back_right.vmt");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/back_right.vtf");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/front.vmt");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/front.vtf");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/front_left.vmt");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/front_left.vtf");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/front_right.vmt");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/front_right.vtf");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/left.vmt");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/left.vtf");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/right.vmt");
	AddFileToDownloadsTable("materials/doom/proj_rocket/v1/right.vtf");
	
	PrecacheModel("materials/doom/cyberdemon/v2/back.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/back_left.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/back_right.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/front.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/front_left.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/front_right.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/left.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/right.vmt");
	
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/back.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/back.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/back_left.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/back_left.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/back_right.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/back_right.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/front.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/front.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/front_left.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/front_left.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/front_right.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/front_right.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/left.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/left.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/right.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/right.vtf");
	
	PrecacheModel("materials/doom/cyberdemon/v2/fire_back.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/fire_back_left.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/fire_back_right.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/fire_front.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/fire_front_left.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/fire_front_right.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/fire_left.vmt");
	PrecacheModel("materials/doom/cyberdemon/v2/fire_right.vmt");
	
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_back.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_back.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_back_left.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_back_left.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_back_right.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_back_right.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_front.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_front.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_front_left.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_front_left.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_front_right.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_front_right.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_left.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_left.vtf");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_right.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/fire_right.vtf");
	
	PrecacheModel("materials/doom/cyberdemon/v2/death.vmt");
	
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/death.vmt");
	AddFileToDownloadsTable("materials/doom/cyberdemon/v2/death.vtf");
	
	AddFileToDownloadsTable("sound/pj/doom/barrel_explosion.mp3");
	AddFileToDownloadsTable("sound/pj/doom/cyberdemon_attack.mp3");
	AddFileToDownloadsTable("sound/pj/doom/cyberdemon_sight.mp3");
	AddFileToDownloadsTable("sound/pj/doom/cyberdemon_walk.mp3");
	AddFileToDownloadsTable("sound/pj/doom/cyberdemon_walk_2.mp3");
	AddFileToDownloadsTable("sound/pj/doom/cyberdemon_death.mp3");
	AddFileToDownloadsTable("sound/pj/doom/cyberdemon_hurt.mp3");
	
	PrecacheSound("pj/doom/barrel_explosion.mp3");
	PrecacheSound("pj/doom/cyberdemon_attack.mp3");
	PrecacheSound("pj/doom/cyberdemon_sight.mp3");
	PrecacheSound("pj/doom/cyberdemon_walk.mp3");
	PrecacheSound("pj/doom/cyberdemon_walk_2.mp3");
	PrecacheSound("pj/doom/cyberdemon_death.mp3");
	PrecacheSound("pj/doom/cyberdemon_hurt.mp3");
}

public void OnPluginEnd()
{
	int iEnt = -1;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			DestroyClientSprites(i);
		}
	}
	for (int i = 1; i <= MAX_EDICTS; i++)
	{
		for (int k = 0; k < 8; k++)
		{
			iEnt = EntRefToEntIndex(g_iRocketSprites[i][k]);
			if (iEnt > 0)
				AcceptEntityInput(iEnt, "Kill");
		}
	}
}

public void Event_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_bIsBoss[client])
	{
		int iWeapon = GetPlayerWeaponSlot(client, 0);
		if (iWeapon > 0)
			TF2_RemoveWeaponSlot(client, 0);
		iWeapon = GetPlayerWeaponSlot(client, 1);
		if (iWeapon > 0)
			TF2_RemoveWeaponSlot(client, 1);
		iWeapon = GetPlayerWeaponSlot(client, 2);
		if (iWeapon > 0)
		{
			SetEntityAlpha(iWeapon, 0);
			SetEntProp(iWeapon, Prop_Send, "m_nRenderMode", 1);
		}
		int iEnt = -1;
		while ((iEnt = FindEntityByClassname(iEnt, "tf_wearable")) != INVALID_ENT_REFERENCE)
		{
			if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") != client)
				continue;
			AcceptEntityInput(iEnt, "Kill");
		}
		TF2_SetHealth(client, 4000);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_bIsBoss[client])
	{
		g_bIsBoss[client] = false;
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		TF2Attrib_RemoveByName(client, "max health additive bonus");
		TF2Attrib_RemoveByName(client, "cannot be backstabbed");
		TF2Attrib_RemoveByName(client, "damage force reduction");
		TF2Attrib_RemoveByName(client, "airblast vulnerability multiplier");
		TF2Attrib_RemoveByName(client, "overheal penalty");
		TF2Attrib_RemoveByName(client, "SPELL: Halloween voice modulation");
		DestroyClientSprites(client);
		SDKUnhook(client, SDKHook_OnTakeDamage, Hook_Cyberdemon_OnTakeDamage);
		
		if (g_CVar_no_dominations.IntValue == 1)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (i == client || !IsClientInGame(i))
					continue;
				SetEntProp(client, Prop_Send, "m_bPlayerDominated", 0, 2, i);
				SetEntProp(i, Prop_Send, "m_bPlayerDominatingMe", 0, 2, client);
			}
		}
		
		int iEnt = CreateEntityByName("env_sprite");
		if (iEnt > 0)
		{
			// FIXME: In some case, frame can start with 1, 2, or 3 instead of 0
			// I think because of delay between server spawn sprite and server send info about spawned sprite
			// So here's the problem:
			// Server spawns env_sprite with death animation, frame 0
			// Some time left in miliseconds, possibly frame is 1 or 2, depends on delay
			// Client received info about spawned env_sprite, but because of delay, frame is 1, 2
			// So client will play with 2 frame instead of 0
			// Solution: Try experiment env_sprite_clientside, so delay will be not a big deal?
			// Problem: How to destroy env_sprite_clientside manually?
			// Solution 2: Create death frames by death_01.vmt death_02.vmt death_03.vmt etc, spawn ents and kill ents manually by framerate
			// Problem 2: Is that is really good solution?
			DispatchKeyValue(iEnt, "model", "doom/cyberdemon/v2/death.vmt");
			DispatchKeyValue(iEnt, "scale", "1.5");
			DispatchKeyValue(iEnt, "rendermode", "2");
			DispatchKeyValue(iEnt, "frame", "0");
			DispatchKeyValue(iEnt, "framerate", "0.4");
			
			float vecPos[3];
			GetClientAbsOrigin(client, vecPos);
			TeleportEntity(iEnt, vecPos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(iEnt);
			
			SetVariantString("OnUser1 !self:kill:3.5:1");
			AcceptEntityInput(iEnt, "AddOutput");
			AcceptEntityInput(iEnt, "FireUser1");
			EmitSoundToAll("pj/doom/cyberdemon_death.mp3", iEnt, SNDCHAN_AUTO, 115);
			
			RequestFrame(Frame_CheckForRagdoll, client);
		}
	}
}

public void Frame_CheckForRagdoll(int client)
{
	int iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (iRagdoll > 0)
		AcceptEntityInput(iRagdoll, "Kill");
}

public void Event_PlayerDomination(Event event, const char[] name, bool dontBroadcast)
{
	int iDominator = GetClientOfUserId(event.GetInt("dominator"));
	int iDominated = GetClientOfUserId(event.GetInt("dominated"));
	
	if (g_CVar_no_dominations.IntValue != 2)
		return;
	
	if (iDominator > 0 && iDominator <= MaxClients && iDominated > 0 && iDominated <= MaxClients && g_bIsBoss[iDominator])
	{
		SetEntProp(iDominator, Prop_Send, "m_bPlayerDominated", 0, 2, iDominated);
		SetEntProp(iDominated, Prop_Send, "m_bPlayerDominatingMe", 0, 2, iDominator);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "tf_projectile_rocket"))
	{
		SDKHook(entity, SDKHook_Spawn, Hook_Rocket_Spawn);
	}
}

public Action Hook_Rocket_Spawn(int entity)
{
	int iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (iOwner > 0 && iOwner <= MaxClients && g_bIsBoss[iOwner])
	{
		DHookEntity(g_hIsDeflectable, false, entity);
		DHookEntity(g_hIsDeflectable, true, entity);
		DHookEntity(g_hIsDestroyable, false, entity);
		DHookEntity(g_hIsDestroyable, true, entity);
	}
	return Plugin_Continue;
}

// Feature: ngineers with short curcuit can't destroy cyberdemon's rockets
public MRESReturn Hook_Rocket_IsDestroyable(int pThis, Handle hReturn)
{
	DHookSetReturn(hReturn, false);
	return MRES_Supercede;
}

// Feature: pyros/heavies can't deflect cyberdemon's rockets
public MRESReturn Hook_Rocket_IsDeflectable(int pThis, Handle hReturn)
{
	DHookSetReturn(hReturn, false);
	return MRES_Supercede;
}

// Feature: cyberdemons can't laugh
public MRESReturn Hook_TFPlayer_CanBeForcedToLaugh(int pThis, Handle hReturn)
{
	if (g_bIsBoss[pThis])
	{
		DHookSetReturn(hReturn, false);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_Victim_OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	g_bIsBoss[client] = false;
	g_flBossSightCooldown[client] = 0.0;
	g_flBossWalkCooldown[client] = 0.0;
	g_flBossSightRaycastCooldown[client] = 0.0;
	g_flBossAttackCooldown[client] = 0.0;
	g_flBossDamageCooldown[client] = 0.0;
	g_iBossAttackState[client] = 0;
	g_bBossWalked[client] = false;
	DestroyClientSprites(client);
}

public void OnEntityDestroyed(int entity)
{
	if (entity > MaxClients && entity <= MAX_EDICTS)
	{
		char szClassName[32];
		GetEdictClassname(entity, szClassName, sizeof(szClassName));
		if (StrEqual(szClassName, "tf_projectile_rocket"))
		{
			int iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if (iOwner > 0 && iOwner <= MaxClients && g_bIsBoss[iOwner])
			{
				EmitSoundToAll("pj/doom/barrel_explosion.mp3", entity, SNDCHAN_AUTO, 95); //120
			}
			for (int i = 0; i < 8; i++)
			{
				int iEnt = EntRefToEntIndex(g_iRocketSprites[entity][i]);
				if (iEnt > 0)
				{
					AcceptEntityInput(iEnt, "Kill");
					g_iRocketSprites[entity][i] = 0;
				}
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if (g_bIsBoss[client])
	{
		int iEnt = -1;
		float vecCyberdemonPos[3];
		GetClientAbsOrigin(client, vecCyberdemonPos);
		for (int i = 0; i < 8; i++)
		{
			iEnt = EntRefToEntIndex(g_iCyberdemonSprites[client][i]);
			if (iEnt > 0)
			{
				// Dont parent, because of Valve fake-cosmetics war. Parented sprite will be invisible
				// TODO: Maybe we can parent env_sprite to info_target and parent that info_target to player, so info_target will be 'invisible', but env_sprite not
				TeleportEntity(iEnt, vecCyberdemonPos, NULL_VECTOR, NULL_VECTOR);
			}
			iEnt = EntRefToEntIndex(g_iCyberdemonFireSprites[client][i]);
			if (iEnt > 0)
			{
				TeleportEntity(iEnt, vecCyberdemonPos, NULL_VECTOR, NULL_VECTOR);
			}
		}
		if (GetGameTime() > g_flBossWalkCooldown[client] && 
			(buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT))
		{
			if (g_bBossWalked[client])
			{
				EmitSoundToAll("pj/doom/cyberdemon_walk.mp3", client, SNDCHAN_AUTO, 95);
				g_bBossWalked[client] = false;
			}
			else
			{
				EmitSoundToAll("pj/doom/cyberdemon_walk_2.mp3", client, SNDCHAN_AUTO, 95);
				g_bBossWalked[client] = true;
			}
			g_flBossWalkCooldown[client] = GetGameTime() + 0.6;
		}
		if (GetGameTime() > g_flBossAttackCooldown[client] && g_iBossAttackState[client] > 0)
		{
			g_iBossAttackState[client] = STATE_CYBERDEMON_WALK;
		}
		if (GetGameTime() > g_flBossSightRaycastCooldown[client] && GetGameTime() > g_flBossSightCooldown[client])
		{
			float vecCyberdemonEyeAngles[3], vecCyberdemonEyePosition[3];
			
			GetClientEyePosition(client, vecCyberdemonEyePosition);
			GetClientEyeAngles(client, vecCyberdemonEyeAngles);
			
			Handle hTrace = TR_TraceRayFilterEx(vecCyberdemonEyePosition, vecCyberdemonEyeAngles, MASK_VISIBLE, RayType_Infinite, TraceEntityFilter_DontHitSelfPlayer, client);
				
			int iTempEnt = -1;
			if (TR_DidHit(hTrace))
			{
				iTempEnt = TR_GetEntityIndex(hTrace);
			}
			delete hTrace;
			
			if (iTempEnt > 0 && iTempEnt <= MaxClients && GetClientTeam(iTempEnt) != GetClientTeam(client))
			{
				EmitSoundToAll("pj/doom/cyberdemon_sight.mp3", client, SNDCHAN_AUTO, 95);
				g_flBossSightCooldown[client] = GetGameTime() + 5.0;
			}
			g_flBossSightRaycastCooldown[client] = GetGameTime() + 0.35;
		}
		if (GetGameTime() > g_flBossAttackCooldown[client] && buttons & IN_ATTACK2)
		{
			// Using same rocket offsets from CTFWeaponBaseGun::FireRocket
			// game/shared/tf/tf_weaponbase_gun.cpp L529
			// And projectile position from CTFWeaponBase::GetProjectileFireSetup
			// game/shared/tf/tf_weaponbase.cpp
			// TODO: Use raycast for more accuracy
			float vecPosition[3], vecRotation[3], vecVelocity[3], vecForward[3], vecRight[3], vecUp[3];
			float vecOffset[3] = { 23.5, 12.0, -3.0 };
			GetClientEyePosition(client, vecPosition);
			GetClientEyeAngles(client, vecRotation);
			
			GetAngleVectors(vecRotation, vecForward, vecRight, vecUp);
			
			float vecSrc[3];
			
			vecVelocity = vecForward;
			ScaleVector(vecVelocity, ROCKET_SPEED);
			
			vecSrc = vecPosition;
			
			ScaleVector(vecForward, vecOffset[0]);
			ScaleVector(vecRight, vecOffset[1]);
			ScaleVector(vecUp, vecOffset[2]);
				
			vecSrc[0] += vecForward[0];
			vecSrc[1] += vecForward[1];
			vecSrc[2] += vecForward[2];
			
			vecSrc[0] += vecRight[0];
			vecSrc[1] += vecRight[1];
			vecSrc[2] += vecRight[2];
			
			vecSrc[0] += vecUp[0];
			vecSrc[1] += vecUp[1];
			vecSrc[2] += vecUp[2];
			
			int iRocket = CreateEntityByName("tf_projectile_rocket");
			if (iRocket > 0)
			{
				SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", client);
				SetEntDataFloat(iRocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ROCKET_DAMAGE, true);
				TeleportEntity(iRocket, vecSrc, vecRotation, vecVelocity);
				DispatchSpawn(iRocket);
				// If Valve adds 4096 edict limit, array will be still 2049 and cause 'entity leak' (sprites will be not destroyed after explosion)
				// The only way to fix this is replace to ArrayList
				if (iRocket <= MAX_EDICTS && g_CVar_default_rocket.IntValue <= 0)
				{
					CreateSpritesForRocket(iRocket);
				}
				EmitSoundToAll("pj/doom/cyberdemon_attack.mp3", client, SNDCHAN_AUTO, 95);
			}
			
			// Code to fire from player eyes instead of offset - START
			/* float vecEntPosition[3], vecEntRotation[3], vecVelocity[3];
			GetClientEyePosition(client, vecEntPosition);
			GetClientEyeAngles(client, vecEntRotation);
			
			GetAngleVectors(vecEntRotation, vecVelocity, NULL_VECTOR, NULL_VECTOR);
			
			ScaleVector(vecVelocity, 1100.0);
			
			int iRocket = CreateEntityByName("tf_projectile_rocket");
			if (iRocket > 0)
			{
				SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", client);
				SetEntDataFloat(iRocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 180.0, true);
				TeleportEntity(iRocket, vecEntPosition, vecEntRotation, vecVelocity);
				DispatchSpawn(iRocket);
				EmitSoundToAll("pj/bloomstorm/idlemskru/doom/cyberdemon_attack.mp3", client);
			} */
			// END
			
			g_iBossAttackState[client] = STATE_CYBERDEMON_FIRE;
			g_flBossAttackCooldown[client] = GetGameTime() + 0.65;
		}
	}
	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (g_bIsBoss[client])
	{
		// Feature: Impossible to scare or stun cyberdemon
		if (condition == TFCond_Dazed)
		{
			TF2_RemoveCondition(client, TFCond_Dazed);
		}
		
		// Fallback: If we failed hook signature CTFPlayer::CanBeForcedToLaugh, we remove taunt cond to stop laugh
		if (g_bSignatureLaughFallback && condition == TFCond_Taunting)
		{
			// Cyberdemon unable to taunt himself, but because cyberdemon is actually 2D sprite rather than 3D, it's not a big deal
			// Actually we can check m_iTauntIndex for laugh instead, looks like 1 stands for laugh, but I'm not sure
			TF2_RemoveCondition(client, TFCond_Taunting);
		}
	}
}

public Action Hook_Cyberdemon_TransmitSprite(int entity, int client)
{
	// Entity set back to former edict flags. So we need to remove these flags every transmit hook
	SetEdictFlags(entity, GetEdictFlags(entity) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	//if (GetEdictFlags(entity) & FL_EDICT_ALWAYS)
		//SetEdictFlags(entity, GetEdictFlags(entity) ^ FL_EDICT_ALWAYS);
	int iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (iOwner <= 0)
	{
		return Plugin_Continue;
	}
	
	if (client == iOwner)
	{
		// Dont render for player-boss in first person mode
		if (GetEntProp(iOwner, Prop_Send, "m_nForceTauntCam") == 0)
		{
			return Plugin_Handled;
		}
		else
		{
			// Always render back sprite to owner
			int iEntBack = -1;
			if (g_iBossAttackState[iOwner] == 1)
			{
				//iEntBack = EntRefToEntIndex(g_iCyberdemonAimSprites[iOwner][SPRITE_B]);
			}
			else if (g_iBossAttackState[iOwner] == 2)
			{
				iEntBack = EntRefToEntIndex(g_iCyberdemonFireSprites[iOwner][SPRITE_B]);
			}
			else
			{
				iEntBack = EntRefToEntIndex(g_iCyberdemonSprites[iOwner][SPRITE_B]);
			}
			if (iEntBack > 0 && entity == iEntBack)
				return Plugin_Continue;
			else
				return Plugin_Handled;
		}
	}
	
	int iSpriteIndex = GetAngleSpriteIndex(GetSpriteEntityAngle(iOwner, client));
	
	int iEnt = -1;
	if (g_iBossAttackState[iOwner] == STATE_CYBERDEMON_AIM)
	{
		//iEnt = EntRefToEntIndex(g_iCyberdemonAimSprites[iOwner][iSpriteIndex]);
	}
	else if (g_iBossAttackState[iOwner] == STATE_CYBERDEMON_FIRE)
	{
		iEnt = EntRefToEntIndex(g_iCyberdemonFireSprites[iOwner][iSpriteIndex]);
	}
	else
	{
		iEnt = EntRefToEntIndex(g_iCyberdemonSprites[iOwner][iSpriteIndex]);
	}
	
	if (iEnt > 0 && iEnt == entity)
		return Plugin_Continue;
	return Plugin_Handled;
}

public Action Hook_Rocket_TransmitSprite(int entity, int client)
{
	// Just in case if Valve add support for 4096 edicts and more to avoid runtime exceptions
	if (entity > MAX_EDICTS)
		return Plugin_Continue;
	
	int iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (iOwner <= 0)
	{
		return Plugin_Continue;
	}
	
	SetEdictFlags(entity, GetEdictFlags(entity) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	
	float vecPos[3];
	
	for (int i = 0; i < 8; i++)
	{
		int iEnt = EntRefToEntIndex(g_iRocketSprites[iOwner][i]);
		if (iEnt > 0)
		{
			GetEntPropVector(iOwner, Prop_Send, "m_vecOrigin", vecPos);
			TeleportEntity(iEnt, vecPos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	int iSpriteIndex = GetAngleSpriteIndex(GetSpriteEntityAngle(iOwner, client));
	
	int iEnt = EntRefToEntIndex(g_iRocketSprites[iOwner][iSpriteIndex]);
	
	if (iEnt > 0 && iEnt == entity)
		return Plugin_Continue;
	return Plugin_Handled;
}

public Action Hook_Victim_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (g_bIsBoss[victim])
		return Plugin_Continue;
	if (attacker > 0 && attacker <= MaxClients && g_bIsBoss[attacker])
	{
		if (g_CVar_melee_push.IntValue >= 1 && GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(attacker, 2))
		{
			float vecPlayerPos[3], vecTargetPos[3], vecEyeAngles[3];
			GetClientAbsOrigin(victim, vecTargetPos);
			GetClientAbsOrigin(attacker, vecPlayerPos);
			GetClientEyeAngles(attacker, vecEyeAngles);
			if (GetVectorDistance(vecPlayerPos, vecTargetPos) <= 150.0)
			{
				float vecForward[3];
				vecEyeAngles[0] = 0.0;
					
				GetAngleVectors(vecEyeAngles, vecForward, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(vecForward, vecForward);
				ScaleVector(vecForward, 500.0);
				// Add to Y to push corretly
				vecForward[2] += 500.0;
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vecForward);
			}
		}
		
		// Looks like victim is a boss, 180 rocket damage is nothing to him, let's fix that
		if (GetEntProp(victim, Prop_Send, "m_iHealth") >= 500)
		{
			damage = GetEntProp(victim, Prop_Send, "m_iHealth") + 5.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action Hook_Cyberdemon_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (g_bIsBoss[victim])
	{
		// Rockets from teammates still call this hook, it's doens't actually damage cyberdemon, but it will force cyberdemon make pain sounds
		if (attacker > 0 && GetEntProp(attacker, Prop_Send, "m_iTeamNum") == GetEntProp(victim, Prop_Send, "m_iTeamNum"))
			return Plugin_Continue;
		// In original Doom, Cyberdemon has blast immunity
		if (damagetype & DMG_BLAST)
		{
			float vecMin[3] = { -10.0, -10.0, -10.0 };
			float vecMax[3] = { 10.0, 10.0, 10.0 };
			
			TR_TraceHullFilter(damagePosition, damagePosition, vecMin, vecMax, MASK_PLAYERSOLID, TraceEntityFilter_OnlySelf, victim);
			
			if (TR_GetEntityIndex() != victim)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		// 5.47%
		if (GetRandomInt(0, 255) <= 20)
		{
			// TODO: Pain state
		}
		
		if (GetGameTime() > g_flBossDamageCooldown[victim])
		{
			EmitSoundToAll("pj/doom/cyberdemon_hurt.mp3", victim, SNDCHAN_AUTO, 95);
			g_flBossDamageCooldown[victim] = GetGameTime() + 1.0;
		}
	}
	return Plugin_Continue;
}

public Action Cmd_Cyberdemon(int client, int args)
{
	char szArg[32];
	
	char szTargetName[64];
	int iTargetList[MAXPLAYERS];
	int iTargetCount;
	bool bTnIsMl;
	if (args < 1)
	{
		szArg = "@me";
	}
	else
	{
		GetCmdArg(1, szArg, sizeof(szArg));
	}
	
	if (!StrEqual(szArg, "@me") && !CheckCommandAccess(client, "sm_cyberdemon_others", ADMFLAG_CHEATS))
	{
		ReplyToCommand(client, "No access to made others the cyberdemon");
		return Plugin_Handled;
	}
	
	if ((iTargetCount = ProcessTargetString(szArg, client, iTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
		szTargetName,
		sizeof(szTargetName),
		bTnIsMl)) <= 0)
	{
		ReplyToCommand(client, "[SM] Invalid");
		return Plugin_Handled;
	}
	
	bool bNotify = false;
	bool bMadeBoss = false;
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bIsBoss[i])
			iCount++;
	}
	
	for (int i = 0; i < iTargetCount; i++)
	{
		if (g_CVar_max_cyberdemons.IntValue > 0 && iCount >= g_CVar_max_cyberdemons.IntValue)
		{
			bNotify = true;
			continue;
		}
		if (g_bIsBoss[iTargetList[i]])
			continue;
		MakeClientCyberdemon(iTargetList[i]);
		g_bIsBoss[iTargetList[i]] = true;
		bMadeBoss = true;
		iCount++;
	}
	if (bMadeBoss)
		ReplyToCommand(client, "Made %s the cyberdemon", szTargetName);
	if (bNotify)
		ReplyToCommand(client, "Can't made %s the cyberdemon because there is %i cyberdemons. Check sm_cyberdemon_max_cyberdemons for more info", szTargetName, iCount);
	return Plugin_Handled;
}

void CreateSpritesForClient(int client)
{
	// We need to remove FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK flags to call first hook
	// And remove these flags every hook call
	// If we don't remove in the first time, the hook will never call
	int iEnt = CreateSprite(client, "doom/cyberdemon/v2/front.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonSprites[client][0] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/front_right.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonSprites[client][1] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/right.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonSprites[client][2] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/back_right.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonSprites[client][3] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/back.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonSprites[client][4] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/back_left.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonSprites[client][5] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/left.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonSprites[client][6] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/front_left.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonSprites[client][7] = EntIndexToEntRef(iEnt);
	
	//Fire sprites
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/fire_front.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonFireSprites[client][0] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/fire_front_right.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonFireSprites[client][1] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/fire_right.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonFireSprites[client][2] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/fire_back_right.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonFireSprites[client][3] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/fire_back.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonFireSprites[client][4] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/fire_back_left.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonFireSprites[client][5] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/fire_left.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonFireSprites[client][6] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(client, "doom/cyberdemon/v2/fire_front_left.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Cyberdemon_TransmitSprite);
	g_iCyberdemonFireSprites[client][7] = EntIndexToEntRef(iEnt);
}

void CreateSpritesForRocket(int entity)
{
	int iEnt = CreateSprite(entity, "doom/proj_rocket/v1/front.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Rocket_TransmitSprite);
	g_iRocketSprites[entity][0] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(entity, "doom/proj_rocket/v1/front_right.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Rocket_TransmitSprite);
	g_iRocketSprites[entity][1] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(entity, "doom/proj_rocket/v1/right.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Rocket_TransmitSprite);
	g_iRocketSprites[entity][2] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(entity, "doom/proj_rocket/v1/back_right.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Rocket_TransmitSprite);
	g_iRocketSprites[entity][3] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(entity, "doom/proj_rocket/v1/back.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Rocket_TransmitSprite);
	g_iRocketSprites[entity][4] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(entity, "doom/proj_rocket/v1/back_left.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Rocket_TransmitSprite);
	g_iRocketSprites[entity][5] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(entity, "doom/proj_rocket/v1/left.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Rocket_TransmitSprite);
	g_iRocketSprites[entity][6] = EntIndexToEntRef(iEnt);
	
	iEnt = CreateSprite(entity, "doom/proj_rocket/v1/front_left.vmt", "1.5");
	SetEdictFlags(iEnt, GetEdictFlags(iEnt) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Rocket_TransmitSprite);
	g_iRocketSprites[entity][7] = EntIndexToEntRef(iEnt);
	
	SetEntProp(entity, Prop_Send, "m_nRenderMode", 2);
	SetEntityAlpha(entity, 0);
	SetEntProp(entity, Prop_Send, "m_fEffects", 32);
}

int CreateSprite(int client, const char[] spritePath, const char[] scale)
{
	int iEnt = CreateEntityByName("env_sprite");
	if (iEnt <= 0)
		return -1;
	DispatchKeyValue(iEnt, "model", spritePath);
	DispatchKeyValue(iEnt, "scale", scale);
	//Texture Render mode
	DispatchKeyValue(iEnt, "rendermode", "2");
	
	float vecPos[3];
	if (client > MaxClients)
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", vecPos);
	else
		GetClientAbsOrigin(client, vecPos);
	TeleportEntity(iEnt, vecPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(iEnt);
	SetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity", client);
	return iEnt;
}

void DestroyClientSprites(int client)
{
	for (int k = 0; k < 8; k++)
	{
		int iEnt = EntRefToEntIndex(g_iCyberdemonSprites[client][k]);
		if (iEnt > 0)
			AcceptEntityInput(iEnt, "Kill");
		iEnt = EntRefToEntIndex(g_iCyberdemonFireSprites[client][k]);
		if (iEnt > 0)
			AcceptEntityInput(iEnt, "Kill");
	}
}

void MakeClientCyberdemon(int client)
{
	if (g_bIsBoss[client])
		return;
	
	CreateSpritesForClient(client);
	g_bIsBoss[client] = true;
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	UpdatePlayerHitboxSize(client, 1.75);
	
	int iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (iRagdoll > 0)
		AcceptEntityInput(iRagdoll, "Kill");
	
	SDKHook(client, SDKHook_OnTakeDamage, Hook_Cyberdemon_OnTakeDamage);
	
	TF2_SetHealth(client, 4000);
	TF2Attrib_SetByName(client, "max health additive bonus", 4000.0);
	TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
	TF2Attrib_SetByName(client, "overheal penalty", 0.01);
	TF2Attrib_SetByName(client, "SPELL: Halloween voice modulation", 1.0);
	
	if (g_CVar_no_heal.IntValue >= 1)
		TF2Attrib_SetByName(client, "mod weapon blocks healing", 1.0);
	
	int iWeapon = GetPlayerWeaponSlot(client, 0);
	if (iWeapon > 0)
		TF2_RemoveWeaponSlot(client, 0);
	iWeapon = GetPlayerWeaponSlot(client, 1);
	if (iWeapon > 0)
		TF2_RemoveWeaponSlot(client, 1);
	iWeapon = GetPlayerWeaponSlot(client, 2);
	if (iWeapon > 0)
	{
		SetEntityAlpha(iWeapon, 0);
		SetEntProp(iWeapon, Prop_Send, "m_nRenderMode", 1);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
		TF2Attrib_SetByName(client, "damage bonus", 1.5);
	}
	
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "tf_wearable")) != INVALID_ENT_REFERENCE)
	{
		if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") != client)
			continue;
		// Wearable is strange quality, allow cyberdemons to earn strange points
		if (GetEntProp(iEnt, Prop_Send, "m_iEntityQuality") == 11)
		{
			SetEntityAlpha(iEnt, 0);
			SetEntProp(iEnt, Prop_Send, "m_nRenderMode", 1);
		}
		else
		{
			AcceptEntityInput(iEnt, "Kill");
		}
	}
	
	SetEntityAlpha(client, 0);
	SetEntProp(client, Prop_Send, "m_nRenderMode", 1);
}

stock bool IsSafeToPlaceCyberdemon()
{
	if (g_CVar_max_cyberdemons.IntValue <= 0)
		return true;
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && g_bIsBoss[i])
			iCount++;
	}
	// 16 = 8 walk sprites + 8 fire sprites
	return GetEntityCount() + (iCount * 16) <= 1800;
}

stock float GetSpriteEntityAngle(int entity, int client)
{
	// We will call this method a lot in hooks, etc, so make it's static
	static float vecEntPosition[3], vecClientPosition[3], vecClientRotation[3], vecEntRotation[3], vecA[3], vecB[3];
	
	GetClientAbsOrigin(client, vecClientPosition);
	GetClientEyeAngles(client, vecClientRotation);
	
	if (entity <= MaxClients)
	{
		GetClientAbsOrigin(entity, vecEntPosition);
		GetClientEyeAngles(entity, vecEntRotation);
	}
	else
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecEntPosition);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", vecEntRotation);
	}
	
	vecClientPosition[2] = vecEntPosition[2];
	
	SubtractVectors(vecClientPosition, vecEntPosition, vecA);
	NormalizeVector(vecA, vecA);
	
	// Get entity forward direction
	GetAngleVectors(vecEntRotation, vecB, NULL_VECTOR, NULL_VECTOR);
	
	float flAngle = MathYEGE_SignedAngle(vecA, vecB, { 0.0, 0.0, 1.0 });
	
	return flAngle;
}

stock int GetAngleSpriteIndex(float angle)
{
	if (angle > -22.5 && angle < 22.6)
		return 0;
	if (angle >= 22.5 && angle < 67.5)
		return 7;
	if (angle >= 67.5 && angle < 112.5)
		return 6;
	if (angle >= 112.5 && angle < 157.5)
		return 5;
	
	if (angle <= -157.5 || angle >= 157.5)
		return 4;
	if (angle >= -157.4 && angle < -112.5)
		return 3;
	if (angle >= -112.5 && angle < -67.5)
		return 2;
	if (angle >= -67.5 && angle <= -22.5)
		return 1;
	return 0;
}

stock bool TraceEntityFilter_DontHitSelfPlayer(int entity, int mask, int pl)
{
	if (entity == pl)
		return false;
	if (entity > MaxClients)
		return false;
	return true;
}

stock bool TraceEntityFilter_OnlySelf(int entity, int mask, int pl)
{
	if (entity == pl)
		return true;
	return false;
}

stock void TF2_SetHealth(int client, int health)
{
	SetEntProp(client, Prop_Send, "m_iHealth", health, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", health, 1);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", health);
}

stock void SetEntityAlpha(int ent, int alpha)
{
	SetEntData(ent, GetEntSendPropOffs(ent, "m_clrRender") + 3, alpha);
}

stock void UpdatePlayerHitboxSize(int client, float scale)
{
	static const float vecPlayerMin[3] = { -24.5, -24.5, 0.0 };
	static const float vecPlayerMax[3] = { 24.5, 24.5, 83.0 };
	
	float vecTempMin[3], vecTempMax[3];
	
	vecTempMin = vecPlayerMin;
	vecTempMax = vecPlayerMax;
	
	ScaleVector(vecTempMin, scale);
	ScaleVector(vecTempMax, scale);
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecTempMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecTempMax);
}

// Matematika YEGE 100 ballov
// math Unified State Exam 100 score points
// Source: Unity Engine

#define YEGE_Y 2
#define YEGE_Z 0
#define YEGE_X 1

stock float MathYEGE_SignedAngle(float from[3], float to[3], float axis[3])
{
	float flNum = MathYEGE_Angle(from, to);
	float flNum2 = from[YEGE_Y] * to[YEGE_Z] - from[YEGE_Z] * to[YEGE_Y];
	float flNum3 = from[YEGE_Z] * to[YEGE_X] - from[YEGE_X] * to[YEGE_Z];
	float flNum4 = from[YEGE_X] * to[YEGE_Y] - from[YEGE_Y] * to[YEGE_X];
	float flNum5 = MathYEGE_Sign(axis[YEGE_X] * flNum2 + axis[YEGE_Y] * flNum3 + axis[YEGE_Z] * flNum4);
	return flNum * flNum5;
}

stock float MathYEGE_Sign(float f)
{
	return (f >= 0.0) ? 1.0 : (-1.0);
}

float MathYEGE_Angle(float from[3], float to[3])
{
	float flNum = SquareRoot(SqrMagnitude(from) * SqrMagnitude(to));
	
	//if (flNum < 1E-15f)
		//return 0.0;
	if (flNum < 0.000000000000001)
		return 0.0;
	
	float flNum2 = MathYEGE_Clamp(GetVectorDotProduct(from, to) / flNum, -1.0, 1.0);
	return ArcCosine(flNum2) * 57.29578; // 57.29578 == 360.0 / (FLOAT_PI * 2.0)
}

stock float MathYEGE_Clamp(float f1, float f2, float f3)
{
	return (f1 > f3 ? f3 : (f1 < f2 ? f2 : f1));
}

float SqrMagnitude(float vec[3])
{
	return vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2];
}

// End of YEGE 100 ballov