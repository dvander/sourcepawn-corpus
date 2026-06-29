#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <smlib>
#include <emitsoundany>
#include <fpvm_interface>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

#define BLOOD_LIFETIME 10.0

// Make sure this is not one of the damage types when slashing with the axe.
// If you don't, then the crossbow will deal 0 damage.
#define DMG_CROSSBOW DMG_BULLET

public Plugin myinfo = 
{
	name = "[CS:GO] Crossbow like Backwards", 
	author = "Eyal282", 
	description = "Crossbow gun like in the TTT server of backwards'", 
	version = PLUGIN_VERSION, 
	url = "N/A"
}

#define EF_NODRAW 32

bool bHoldingCrossbow[MAXPLAYERS + 1];

int SpawnSerial[MAXPLAYERS + 1];

int v_Crossbow, w_Crossbow;

ConVar hcv_mpTeammatesAreEnemies;

char HitSound[] = "hostage/hpain/hpain6.wav";

public void OnMapStart()
{
	LoadDirOfModels("materials/models/weapons/eminem/advanced_crossbow");
	LoadDirOfModels("models/weapons/eminem/advanced_crossbow");
	LoadDirOfModels("sound/weapons/eminem/advanced_crossbow");
	
	v_Crossbow = PrecacheModel("models/weapons/eminem/advanced_crossbow/v_advanced_crossbow.mdl", true);
	w_Crossbow = PrecacheModel("models/weapons/eminem/advanced_crossbow/w_advanced_crossbow.mdl", true);
	//PrecacheModel("models/weapons/eminem/advanced_crossbow/w_advanced_crossbow_dropped.mdl", true);
	PrecacheModel("models/weapons/eminem/advanced_crossbow/w_crossbow_bolt_dropped.mdl", true);
	
	PrecacheSoundAny(HitSound, true);
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	hcv_mpTeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		Func_OnClientPutInServer(i);
	}
}

public void OnClientConnected(int client)
{
	SpawnSerial[client] = 0;
}
public void OnClientPutInServer(int client)
{
	Func_OnClientPutInServer(client);
}

public void Func_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
}

public Action OnWeaponDrop(int client, int wpnid)
{
	if(wpnid < 1)
	{
		return;
	}
	
	CreateTimer(0.0, SetWorldModel, EntIndexToEntRef(wpnid));
}


public Action SetWorldModel(Handle tmr, any ref)
{
	int weapon = EntRefToEntIndex(ref);
	
	if(weapon == INVALID_ENT_REFERENCE || !IsValidEntity(weapon) || !IsValidEdict(weapon))
		return;
	
	else if(!IsEntityAxe(weapon))
		return;
		
	SetEntityModel(weapon, "models/weapons/eminem/advanced_crossbow/w_advanced_crossbow.mdl");
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if (weapon == -1)
		return Plugin_Continue;
	
	else if (!IsEntityAxe(weapon))
		return Plugin_Continue;
	
	GivePlayerAxe(client);
	AcceptEntityInput(weapon, "Kill");
	return Plugin_Handled;
}
public void OnWeaponSwitchPost(int client, int weapon)
{
	bHoldingCrossbow[client] = false;
	
	if (weapon == -1)
		return;
	
	else if (!IsEntityAxe(weapon))
		return;
	
	bHoldingCrossbow[client] = true;
}

public Action OnTakeDamage(int victim, int & attacker, int & inflictor, float & damage, int & damagetype)
{
	if (!IsPlayer(attacker))
		return Plugin_Continue;
	
	if (bHoldingCrossbow[attacker] && damagetype != DMG_CROSSBOW)
	{
		damage = 0.0;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
public Action OnPlayerRunCmd(int client, int & buttons, int & impulse, float vel[3], float angles[3], int & weapon, int & subtype, int & cmdnum, int & tickcount, int & seed, int mouse[2])
{
	if (bHoldingCrossbow[client])
	{
		int trueButtons = buttons;
		
		buttons &= ~IN_ATTACK2;
		buttons &= ~IN_ATTACK;
		
		if (!(trueButtons & IN_ATTACK))
			return Plugin_Changed;
		
		else if (GetEntPropFloat(client, Prop_Send, "m_flNextAttack") > GetGameTime())
			return Plugin_Changed;
		
		int bullet = CreateEntityByName("smokegrenade_projectile");
		
		//SetEntProp(bullet, Prop_Send, "m_usSolidFlags", 12); //FSOLID_NOT_SOLID|FSOLID_TRIGGER
		SetEntProp(bullet, Prop_Data, "m_nSolidType", 6); // SOLID_VPHYSICS
		//SetEntProp(bullet, Prop_Send, "m_CollisionGroup", 1); //COLLISION_GROUP_DEBRIS
		
		//SetEntityMoveType(bullet, MOVETYPE_FLY);
		
		// A random model to create a physics object.
		//SetEntityModel(bullet, "models/weapons/w_eq_fraggrenade_dropped.mdl");
		
		float speed = 1024.0;
		
		float fOrigin[3], fAngles[3], fFwd[3];
		
		GetClientEyePosition(client, fOrigin);
		GetClientEyeAngles(client, fAngles);
		
		GetAngleVectors(fAngles, fFwd, NULL_VECTOR, NULL_VECTOR);
		
		//fAngles = fFwd;
		NormalizeVector(fFwd, fFwd);
		ScaleVector(fFwd, speed);
		
		// While the bullet is a smokegrenade model, make it invisible.
		SetEntProp(bullet, Prop_Send, "m_fEffects", GetEntProp(bullet, Prop_Send, "m_fEffects") | EF_NODRAW);
		
		DispatchSpawn(bullet);
		ActivateEntity(bullet);
		
		AcceptEntityInput(bullet, "EnableMotion");
		
		TeleportEntity(bullet, fOrigin, fAngles, fFwd);
		
		//SetEntityMoveType(bullet, MOVETYPE_VPHYSICS);
		
		DataPack DP = new DataPack();
		DP.WriteCell(bullet);
		DP.WriteFloat(fFwd[2]);
		
		RequestFrame(Frame_NoGravity, DP);
		
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 1.0);
		
		// After the entity is created, give the real model.
		
		SetEntPropEnt(bullet, Prop_Send, "m_hOwnerEntity", client);
		SDKHook(bullet, SDKHook_StartTouchPost, OnStartTouch);
		RequestFrame(Frame_GiveModel, bullet);
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void OnStartTouch(int bullet, int toucher)
{
	int owner = GetEntPropEnt(bullet, Prop_Send, "m_hOwnerEntity");
	
	if (owner == -1)
		return;
	
	else if (IsPlayer(toucher))
	{
		if (toucher == owner)
			return;
		
		else if (GetClientTeam(toucher) == GetClientTeam(owner) && !hcv_mpTeammatesAreEnemies.BoolValue)
			return;
		
		OnPlayerHitByCrossbow(toucher, owner);
	}
	
	else
	{
		// If you hit glass or a JailBreak vent, break it!
		SDKHooks_TakeDamage(toucher, bullet, owner, 128.0, DMG_CROSSBOW);
	}
	
	AcceptEntityInput(bullet, "Kill");
}

public void OnPlayerHitByCrossbow(int victim, int attacker)
{
	float Origin[3];
	
	GetEntPropVector(victim, Prop_Data, "m_vecOrigin", Origin);
	
	EmitSoundByDistanceAny(3000.0, HitSound, victim, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 90, -1, Origin, NULL_VECTOR, true, 0.0);
	
	DataPack DP, DP2;
	
	CreateDataTimer(0.2, Timer_TakeBleedDamage, DP, TIMER_REPEAT);
	
	DP.WriteCell(GetClientUserId(victim));
	DP.WriteCell(GetClientUserId(attacker));
	DP.WriteCell(SpawnSerial[victim]);
	
	Handle hTimer = CreateDataTimer(0.5, Timer_AnimateBleed, DP2, TIMER_REPEAT);
	
	DP2.WriteCell(GetClientUserId(victim));
	DP2.WriteCell(SpawnSerial[victim]);
	
	TriggerTimer(hTimer, true);
	//TE_SetupBloodSprite(fOrigin, { 90.0, 0.0, 0.0 }, { 255, 0, 0, 255 }, 25, bloodModel, bloodPuddleModel);
	//TE_SendToAll();
}

public Action Timer_TakeBleedDamage(Handle hTimer, DataPack DP)
{
	DP.Reset();
	
	int victim = GetClientOfUserId(DP.ReadCell());
	int attacker = GetClientOfUserId(DP.ReadCell());
	int serial = DP.ReadCell();
	
	if (victim == 0 || attacker == 0)
		return Plugin_Stop;
	
	else if (!IsPlayerAlive(victim))
		return Plugin_Stop;
	
	else if (serial != SpawnSerial[victim])
		return Plugin_Stop;
	
	SetClientArmor(victim, 0);
	SDKHooks_TakeDamage(victim, victim, attacker, 1.0, DMG_CROSSBOW);
	
	return Plugin_Continue;
}

public Action Timer_AnimateBleed(Handle hTimer, DataPack DP)
{
	DP.Reset();
	
	int victim = GetClientOfUserId(DP.ReadCell());
	int serial = DP.ReadCell();
	
	if (victim == 0)
		return Plugin_Stop;
	
	else if (!IsPlayerAlive(victim))
		return Plugin_Stop;
	
	else if (serial != SpawnSerial[victim])
		return Plugin_Stop;
	
	CreateParticle(victim, "blood_pool");
	
	return Plugin_Continue;
}
void CreateParticle(int victim, char[] szName)
{
	int iEntity;
	iEntity = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(iEntity) && (victim > 0))
	{
		if (IsPlayerAlive(victim))
		{
			// Get players current position
			float vPosition[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", vPosition);
			
			// Move particle to player
			TeleportEntity(iEntity, vPosition, NULL_VECTOR, NULL_VECTOR);
			
			// Set entity name
			DispatchKeyValue(iEntity, "targetname", "particle");
			
			// Get player entity name
			char szParentName[64];
			GetEntPropString(victim, Prop_Data, "m_iName", szParentName, sizeof(szParentName));
			
			// Set the effect name
			DispatchKeyValue(iEntity, "effect_name", szName);
			
			// Spawn the particle
			DispatchSpawn(iEntity);
			
			// Activate the entity (starts animation)
			ActivateEntity(iEntity);
			AcceptEntityInput(iEntity, "Start");
			
			// Attach to parent model
			SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", victim);
			
			CreateTimer(BLOOD_LIFETIME, Timer_DeleteEntity, EntIndexToEntRef(iEntity), TIMER_FLAG_NO_MAPCHANGE);
			
			SetFlags(iEntity);
			SDKHook(iEntity, SDKHook_SetTransmit, OnSetTransmit);
			//g_unClientAura[iClient] = EntIndexToEntRef(iEntity);
		}
	}
}

public Action Timer_DeleteEntity(Handle hTimer, int Ref)
{
	int entity = EntRefToEntIndex(Ref);
	
	if (entity == INVALID_ENT_REFERENCE)
		return;
	
	AcceptEntityInput(entity, "Kill");
}

public void SetFlags(int iEdict)
{
	if (GetEdictFlags(iEdict) & FL_EDICT_ALWAYS)
	{
		SetEdictFlags(iEdict, (GetEdictFlags(iEdict) ^ FL_EDICT_ALWAYS));
	}
}

public Action OnSetTransmit(int iEnt, int iClient)
{
	int iOwner = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
	SetFlags(iEnt);
	if (iOwner && IsClientInGame(iOwner))
	{
		return Plugin_Continue;
		
	}
	
	return Plugin_Continue;
}

public void Frame_NoGravity(DataPack DP)
{
	ResetPack(DP);
	
	int bullet = DP.ReadCell();
	
	if (!IsValidEntity(bullet))
	{
		delete DP;
		return;
	}
	float Velocity[3];
	
	GetEntPropVector(bullet, Prop_Data, "m_vecVelocity", Velocity);
	
	Velocity[2] = DP.ReadFloat();
	
	TeleportEntity(bullet, NULL_VECTOR, NULL_VECTOR, Velocity);
	
	RequestFrame(Frame_NoGravity, DP);
}
public void Frame_GiveModel(int bullet)
{
	SetEntityModel(bullet, "models/weapons/eminem/advanced_crossbow/w_crossbow_bolt_dropped.mdl");
	
	SetEntProp(bullet, Prop_Send, "m_fEffects", GetEntProp(bullet, Prop_Send, "m_fEffects") & ~EF_NODRAW);
	//new Float:Origin[3];
}

public Action Event_PlayerSpawn(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	SpawnSerial[client]++;
	
	int crossbow = GivePlayerAxe(client);
	FPVMI_AddViewModelToClient(client, "weapon_axe", v_Crossbow);
	
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	bHoldingCrossbow[client] = false;
	
	if (weapon == -1)
		return;
	
	else if (!IsEntityAxe(weapon))
		return;
	
	bHoldingCrossbow[client] = true;
}

stock void LoadDirOfModels(char[] dirofmodels)
{
	char path[256];
	FileType type;
	char FileAfter[256];
	Handle dir = OpenDirectory(dirofmodels, false, "GAME");
	
	if (!dir)
	{
		return;
	}
	while (ReadDirEntry(dir, path, 256, type))
	{
		if (type == FileType_File)
		{
			FormatEx(FileAfter, 256, "%s/%s", dirofmodels, path);
			AddFileToDownloadsTable(FileAfter);
		}
	}
	CloseHandle(dir);
	dir = INVALID_HANDLE;
	return;
}

stock int GivePlayerAxe(int client)
{
	int entity = CreateEntityByName("weapon_axe");
	
	EquipPlayerWeapon(client, entity);
	
	return entity;
}


stock bool IsPlayer(int entity)
{
	if (entity < 1)
		return false;
	
	else if (entity > MaxClients)
		return false;
	
	return true;
}

stock bool IsEntityAxe(int entity)
{
	
	return GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == CS_WeaponIDToItemDefIndex(CSWeapon_AXE);
}

stock void SetClientArmor(int client, int amount)
{
	SetEntProp(client, Prop_Send, "m_ArmorValue", amount);
}

stock EmitSoundByDistanceAny(Float:distance, const String:sample[], 
                 entity = SOUND_FROM_PLAYER, 
                 channel = SNDCHAN_AUTO, 
                 level = SNDLEVEL_NORMAL, 
                 flags = SND_NOFLAGS, 
                 Float:volume = SNDVOL_NORMAL, 
                 pitch = SNDPITCH_NORMAL, 
                 speakerentity = -1, 
                 const Float:origin[3], 
                 const Float:dir[3] = NULL_VECTOR, 
                 bool:updatePos = true, 
                 Float:soundtime = 0.0)
{
	if(IsNullVector(origin))
	{
		ThrowError("Origin must not be null!");
	}
	
	new clients[MAXPLAYERS+1], count;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		new Float:iOrigin[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", iOrigin);
		
		if(GetVectorDistance(origin, iOrigin, false) < distance)
			clients[count++] = i;
	}
	
	EmitSoundAny(clients, count, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}