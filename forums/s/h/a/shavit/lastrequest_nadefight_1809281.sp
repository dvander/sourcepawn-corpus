#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <hosties>
#include <lastrequest>

#define EXPLODE_SOUND	"physics/glass/glass_bottle_impact_hard3.wav"
#define EXPLODE_SOUND2	"ambient/fire/mtov_flame2.wav"

#pragma semicolon 1

#define FragColor {255,75,75,255}

#define PLUGIN_VERSION "2.8"

// This global will store the index number for the new Last Request
new g_LREntryNum;

new String:g_sLR_Name[64];

new Handle:gH_Timer_Countdown = INVALID_HANDLE;

new bool:bAllCountdownsCompleted = false, bool:NadeWarActive = false;
new Prisoner;
new Guard;

public Plugin:myinfo =
{
	name = "Last Request: Nade Fight",
	author = "Franc1sco (Plugin) & TimeBomb (LR)",
	version = PLUGIN_VERSION
};

public OnPluginStart()
{
	LoadTranslations("nadefight.phrases");
	Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "Nade Fight", LANG_SERVER);
}

public OnConfigsExecuted()
{
	static bool:bAddedNadeWars = false;
	if(!bAddedNadeWars)
	{
		g_LREntryNum = AddLastRequestToList(NadeWars_Start, NadeWars_Stop, g_sLR_Name);
		bAddedNadeWars = true;
	}	
	PrecacheModel("models/props_junk/garbage_glassbottle003a.mdl");
	PrecacheSound(EXPLODE_SOUND, true);
	PrecacheSound(EXPLODE_SOUND2, true);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, EventHurt);
}

public Action:EventHurt(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(!IsValidClient(victim, true) || !IsValidClient(attacker, true))
	{
		return Plugin_Continue;
	}
	
	decl String:sWeapon[32];
	GetEntityClassname(inflictor, sWeapon, 32);
	
	if(NadeWarActive && (victim == Guard || victim == Prisoner) && (StrEqual(sWeapon, "env_fire") || StrEqual(sWeapon, "weapon_hegrenade")))
	{
		IgniteEntity(victim, 4.0);
	}
	
	return Plugin_Changed;
}

public OnPluginEnd()
{
	RemoveLastRequestFromList(NadeWars_Start, NadeWars_Stop, g_sLR_Name);
}

public NadeWars_Start(Handle:LR_Array, iIndexInArray)
{
	new This_LR_Type = GetArrayCell(LR_Array, iIndexInArray, _:Block_LRType);
	if (This_LR_Type == g_LREntryNum)
	{		
		new LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner);
		new LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, _:Block_Guard);
		Prisoner = LR_Player_Prisoner;
		Guard = LR_Player_Guard;
		
		StripAllWeapons(Prisoner);
		StripAllWeapons(Guard);
	
		new LR_Pack_Value = GetArrayCell(LR_Array, iIndexInArray, _:Block_Global1);	
		switch (LR_Pack_Value)
		{
			case -1:
			{
				PrintToServer("no info included");
			}
		}
		
		SetArrayCell(LR_Array, iIndexInArray, 3, _:Block_Global1);
		
		if (gH_Timer_Countdown == INVALID_HANDLE)
		{
			gH_Timer_Countdown = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		
		PrintToChatAll(CHAT_BANNER, "Nadefight Start", LR_Player_Prisoner, LR_Player_Guard);
		NadeWarActive = true;
	}
}

public NadeWars_Stop(This_LR_Type, LR_Player_Prisoner, LR_Player_Guard)
{
	if(This_LR_Type == g_LREntryNum)
	{
		if(IsClientInGame(LR_Player_Prisoner))
		{
			SetEntityGravity(LR_Player_Prisoner, 1.0);
			if (IsPlayerAlive(LR_Player_Prisoner))
			{
				SetEntityHealth(LR_Player_Prisoner, 100);
				GivePlayerItem(LR_Player_Prisoner, "weapon_knife");
				PrintToChatAll(CHAT_BANNER, "Nadefight Win", LR_Player_Prisoner);
			}
		}
		if(IsClientInGame(LR_Player_Guard))
		{
			SetEntityGravity(LR_Player_Guard, 1.0);
			if (IsPlayerAlive(LR_Player_Guard))
			{
				SetEntityHealth(LR_Player_Guard, 100);
				GivePlayerItem(LR_Player_Guard, "weapon_knife");
				PrintToChatAll(CHAT_BANNER, "Nadefight Win", LR_Player_Guard);
			}
		}
		NadeWarActive = false;
	}
}

public Action:Timer_Countdown(Handle:timer)
{
	new numberOfLRsActive = ProcessAllLastRequests(ShotgunWars_Countdown, g_LREntryNum);
	if ((numberOfLRsActive <= 0) || bAllCountdownsCompleted)
	{
		gH_Timer_Countdown = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public ShotgunWars_Countdown(Handle:LR_Array, iIndexInArray)
{
	new LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner);
	new LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, _:Block_Guard);
	
	new countdown = GetArrayCell(LR_Array, iIndexInArray, _:Block_Global1);
	if(countdown > 0)
	{
		bAllCountdownsCompleted = false;
		PrintCenterText(LR_Player_Prisoner, "LR begins in %i...", countdown);
		PrintCenterText(LR_Player_Guard, "LR begins in %i...", countdown);
		SetArrayCell(LR_Array, iIndexInArray, --countdown, _:Block_Global1);		
	}
	else if(countdown == 0)
	{
		bAllCountdownsCompleted = true;
		SetArrayCell(LR_Array, iIndexInArray, --countdown, _:Block_Global1);	
		
		new iAmmo = FindSendPropInfo("CBasePlayer", "m_iAmmo");
		SetEntData(LR_Player_Prisoner, iAmmo + (_:12 * 4), 0, _, true);
		SetEntData(LR_Player_Guard, iAmmo + (_:12 * 4), 0, _, true);
		
		SetEntData(LR_Player_Prisoner, FindSendPropOffs("CBasePlayer", "m_iHealth"), 250);
		SetEntData(LR_Player_Guard, FindSendPropOffs("CBasePlayer", "m_iHealth"), 250);
		SetEntData(LR_Player_Prisoner, FindSendPropOffs("CCSPlayer", "m_ArmorValue"), 0);
		SetEntData(LR_Player_Guard, FindSendPropOffs("CCSPlayer", "m_ArmorValue"), 0);
		
		GivePlayerItem(LR_Player_Prisoner, "weapon_hegrenade");
		GivePlayerItem(LR_Player_Guard, "weapon_hegrenade");
	}
}

public Action:Timer_RemoveThinkTick(Handle:timer, any:entity)
{
	if(NadeWarActive)
	{
		CreateTimer(0.8, Timer_RemoveFlashbang, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_RemoveFlashbang(Handle:timer, any:entity)
{
	if(IsValidEntity(entity))
	{
		new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		
		if(NadeWarActive && IsClientInLastRequest(client) && IsClientInGame(client) && IsPlayerAlive(client))
		{
			new grenade = CreateEntityByName("weapon_hegrenade");
			DispatchSpawn(grenade);
			EquipPlayerWeapon(client, grenade);
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(NadeWarActive && StrEqual(classname, "hegrenade_projectile"))
	{
		SDKHook(entity, SDKHook_SpawnPost, ProjectileSpawned);
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
}

public ProjectileSpawned(entity)
{
	decl Float:origin2[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin2);
	SetEntityModel(entity, "models/props_junk/garbage_glassbottle003a.mdl");
	EmitAmbientSound(EXPLODE_SOUND2, origin2, entity, SNDLEVEL_NORMAL);
	IgniteEntity(entity, 1.2);
	CreateTimer(1.3, Creando, entity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Creando(Handle:timer, any:entity)
{
	if(!IsValidEdict(entity))
	{
		return Plugin_Stop;
	}
	
	decl String:g_szClassname[64];
	GetEdictClassname(entity, g_szClassname, sizeof(g_szClassname));
	if(StrEqual(g_szClassname, "hegrenade_projectile", false))
	{
		decl Float:origin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		Fuego(origin);
	}
	
	return Plugin_Stop;
}

Fuego(Float:pos[3])
{
	new fire = CreateEntityByName("env_fire");
	DispatchKeyValue(fire, "firesize", "220");
	DispatchKeyValue(fire, "health", "5");
	DispatchKeyValue(fire, "firetype", "Normal");
	DispatchKeyValueFloat(fire, "damagescale", 0.0);
	DispatchKeyValue(fire, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(fire, "DispatchEffect"); 
	DispatchSpawn(fire);
	TeleportEntity(fire, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(fire, "StartFire");
	EmitAmbientSound(EXPLODE_SOUND, pos, fire, SNDLEVEL_NORMAL);
}

public OnEntitySpawned(entity)
{
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	decl String:classname[32];
	GetEdictClassname(entity, classname, sizeof(classname));
	
	if(client == Prisoner || client == Guard)
	{
		CreateTimer(0.0, Timer_RemoveThinkTick, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
}

// Credit to -sNeeP!
stock bool:IsValidClient(client, bool:bAlive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bAlive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}