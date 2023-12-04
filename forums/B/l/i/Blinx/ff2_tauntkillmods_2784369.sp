#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>
#include <morecolors>
#include <freak_fortress_2>

//#pragma newdecls required

#define MAXDAMAGECUSTOMS 83
#define MAXTF2PLAYERS 36
#define DISPENSERSUCCESSSOUND "ui/item_acquired.wav"

bool DEBUG = false;

bool g_bModifyTauntKills = true;
bool g_bIsCustomTauntKill[MAXDAMAGECUSTOMS] = {false, ...};
float g_fTauntKillDmgMult[MAXDAMAGECUSTOMS] = {1.0, ...};
char g_sSoundPath[PLATFORM_MAX_PATH] = "misc/killstreak.wav";

int g_TauntKillDamage[MAXTF2PLAYERS] = {0, ...};
int g_TauntKills[MAXTF2PLAYERS] = {0, ...};

bool g_bCanHuntsmanTaunt[MAXTF2PLAYERS] = {true, ...};
int g_HuntsmanWeapons[] = {56, 1005, 1092};
float g_fHuntsmanTauntCooldown = 5.0;

float g_fTauntKillDamageThreshold = 75.0;
float g_fTauntKillFixedDamage = 500.0;
float g_fBossHealthPercentage = 0.25;
float g_fTauntKillMaxDamage = 10000.0;

bool g_bShredAlertTauntKill = true;
int g_ShredAlertDamageRadius = 160; //Radius to affect other players
float g_fShredAlertDelay = 3.10; //How long after starting the taunt before the damage hits
float g_fShredAlertDmgMult = 0.9; 

bool g_bPootisPowEnable = true;
bool g_bPootisPowWindowOpen[MAXTF2PLAYERS] = {false, ...}; //Activating "Pootis Spencer here" while this is open allows a Dispenser to spawn
bool g_bCanPootisPowDispenser[MAXTF2PLAYERS] = {false, ...}; //At the "Pow", when this is true, causes a Dispenser to spawn
int g_PootisPowWeapons[] = {5, 195, 587, 656}; //List of weapon indexes that can do the showdown taunt
int g_PootisPowDispenserHealth = 50; //Health of the spawned dispenser
float g_fPootisPowRange = 5000.0; //Max range that a pootis pow spencer can be spawned
float g_fPootisPowWindowOpen = 0.90; //How long after initiating the taunt the window opens
float g_fPootisPowWindowDuration = 0.17; //How long the window remains open (cannot be less than 0.1)
float g_fPootisPowAfterTaunt = 1.65; //How long it takes to say "Pow" after taunting
float g_fPootisPowDispenserDuration = 10.0; //How long for a Pootis Pow Dispenser to last

bool g_bTextAnnounce = true;
bool g_bSoundAnnounce = true;
Handle AnnounceHud;
float g_fAnnounceDuration = 5.0;

Handle KvValues;

public Plugin:myinfo = {
   name = "Freak Fortress 2: Taunt Kill Modifications",
   author = "Ankhxy",
   description = "Adds various functionality around taunt kills",
   version = "1.2"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max)
{
	CreateNative("TKM_GetTauntKillDamage", Native_GetTauntKillDamage);
	CreateNative("TKM_GetTauntKills", Native_GetTauntKills);
}

public OnPluginStart()
{
	AddCommandListener(OnTaunt, "taunt");
	AddCommandListener(OnTaunt, "+taunt");
	AddCommandListener(OnVoiceMenu, "voicemenu");
	
	HookEvent("teamplay_round_start", OnRoundStart);
	
	RegAdminCmd("tkm_reload", ReloadKV, ADMFLAG_GENERIC, "Reload Taunt Kill Mods Values from KV");
	
	AnnounceHud = CreateHudSynchronizer();
	
	initTauntKillValues();
	
	PrecacheSound(DISPENSERSUCCESSSOUND, true);
	PrecacheSound(g_sSoundPath, true);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	g_TauntKillDamage[client] = 0;
	g_TauntKills[client] = 0;
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	g_TauntKillDamage[client] = 0;
	g_TauntKills[client] = 0;
}

public void OnMapStart()
{
	LoadKeyValues();
	
	for(int client = 1; client < MAXTF2PLAYERS; client++)
	{
		g_TauntKillDamage[client] = 0;
		g_TauntKills[client] = 0;
	}
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client < MAXTF2PLAYERS; client++)
	{
		g_TauntKillDamage[client] = 0;
		g_TauntKills[client] = 0;
	}
}

public Action OnTakeDamage(client, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom)
{
	if(!IsValidClient(attacker) || !IsValidClient(client) || !g_bModifyTauntKills)
		return Plugin_Continue;
		
	int Boss = FF2_GetBossIndex(client);
	
	if(Boss >= 0 && client != attacker && !IsPlayerInvuln(client))
	{	
		if(damagecustom <= sizeof(g_bIsCustomTauntKill) && damagecustom > 0)
		{	
			if(g_bIsCustomTauntKill[damagecustom])
			{
				if((damagecustom == 13 || damagecustom == 29 || damagecustom == 38 || damagecustom == 53) && damage < g_fTauntKillDamageThreshold) //These are the taunts that have "wind ups" with small damage before the big hit, we don't want to do anything with the small hits
					return Plugin_Continue;
				
				int bossHealth = FF2_GetBossMaxHealth(Boss);
				float damageAmount = (g_fTauntKillFixedDamage + (bossHealth*g_fBossHealthPercentage))*g_fTauntKillDmgMult[damagecustom];
				
				if(damageAmount > g_fTauntKillMaxDamage)
					damageAmount = g_fTauntKillMaxDamage;
					
				damage = damageAmount;
				
				AnnounceTauntKill(attacker, client, damageAmount);
				
				if(DEBUG) CPrintToChatAll("{red}[DEBUG]{default} Damage: %1.0f | Boss Health: %i | 20 Boss Health: %1.0f | Damage Mult: %f | Damage Custom: %i", damage, bossHealth, bossHealth*g_fBossHealthPercentage, g_fTauntKillDmgMult[damagecustom], damagecustom);
				
				return Plugin_Changed;
			}
		}
		else
		{
			char Classname[32];
			GetEdictClassname(inflictor, Classname, sizeof(Classname));
			if(StrEqual("env_explosion", Classname, false))
			{
				if(IsValidClient(attacker))
				{
					if(TF2_IsPlayerInCondition(attacker, TFCond_Taunting) && GetEntProp(attacker, Prop_Send, "m_iTauntItemDefIndex") == 1015)
					{
						int bossHealth = FF2_GetBossMaxHealth(Boss);
						float damageAmount = (g_fTauntKillFixedDamage + (bossHealth*g_fBossHealthPercentage))*g_fShredAlertDmgMult;
						
						if(damageAmount > g_fTauntKillMaxDamage)
							damageAmount = g_fTauntKillMaxDamage;
							
						damage = damageAmount;
							
						AnnounceTauntKill(attacker, client, damageAmount);
						
						if(DEBUG) CPrintToChatAll("{red}[DEBUG]{default} Damage: %1.0f | Boss Health: %i | 20 Boss Health: %1.0f | Damage Mult: %f | Damage Custom: %i", damage, bossHealth, bossHealth*g_fBossHealthPercentage, g_fShredAlertDmgMult, damagecustom);
						
						return Plugin_Changed;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnTaunt(int client, const char[] command, int args)
{
	static char arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	
	if(StrEqual(arg, "0")) //Greater than 0 means it came from the taunt menu, 0 means it's just the stock weapon taunt
	{
		if(g_bPootisPowEnable)
		{
			for(int i = 0; i < sizeof(g_PootisPowWeapons); i++)
			{
				if(ActiveWeaponIndex(client) == g_PootisPowWeapons[i])
				{
					if(DEBUG) CPrintToChatAll("{red}[DEBUG]{default} Started Pootis Pow sequence");
					g_bPootisPowWindowOpen[client] = false;
					g_bCanPootisPowDispenser[client] = false;
					CreateTimer(g_fPootisPowWindowOpen, t_PootisPowWindowOpen, client, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(g_fPootisPowAfterTaunt, t_CreatePootisPowSpencer, client, TIMER_FLAG_NO_MAPCHANGE);
					
					break;
				}
			}
		}
		
		for(int i = 0; i < sizeof(g_HuntsmanWeapons); i++)
		{
			if(ActiveWeaponIndex(client) == g_HuntsmanWeapons[i])
			{
				if(g_bCanHuntsmanTaunt[client])
				{
					if(g_fHuntsmanTauntCooldown >= 0.1)
					{
						g_bCanHuntsmanTaunt[client] = false;
						CreateTimer(g_fHuntsmanTauntCooldown, t_EnableHuntsmanTaunt, client, TIMER_FLAG_NO_MAPCHANGE);
						
						return Plugin_Continue;
					}
				}
				else
				{
					return Plugin_Handled;
				}
				
				break;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action t_PootisPowWindowOpen(Handle timer, int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		if(DEBUG) CPrintToChatAll("{red}[DEBUG]{default} Pootis Pow Window Open");
		g_bPootisPowWindowOpen[client] = true;
		CreateTimer(g_fPootisPowWindowDuration, t_ClosePootisPowWindow, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action OnVoiceMenu(int client, const char[] command, int args)
{
	if(g_bPootisPowEnable)
	{
		static char arg1[4], arg2[4];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		int voiceMenu[2]; 
		voiceMenu[0] = StringToInt(arg1);
		voiceMenu[1] = StringToInt(arg2);
		
		if (voiceMenu[0] == 1 && voiceMenu[1] == 4) //Need a dispenser here
		{
			if(g_bPootisPowWindowOpen[client] && TF2_IsPlayerInCondition(client, TFCond_Taunting))
			{
				g_bCanPootisPowDispenser[client] = true;
			}
		}
	}
}

public Action t_ClosePootisPowWindow(Handle timer, int client)
{
	if(DEBUG) CPrintToChatAll("{red}[DEBUG]{default} Pootis Pow Window close");
	g_bPootisPowWindowOpen[client] = false;
	
	return Plugin_Continue;
}

public Action t_CreatePootisPowSpencer(Handle timer, int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && g_bCanPootisPowDispenser[client] && TF2_IsPlayerInCondition(client, TFCond_Taunting))
	{
		if(DEBUG) CPrintToChatAll("{red}[DEBUG]{default} Tried to create dispenser");
		EmitSoundToClient(client, DISPENSERSUCCESSSOUND);
		CreatePopUpBuilding(client, g_fPootisPowDispenserDuration, 0, g_PootisPowDispenserHealth, false);
	}
}

public Action t_EnableHuntsmanTaunt(Handle timer, int client)
{
	g_bCanHuntsmanTaunt[client] = true;
	
	return Plugin_Continue;
}

public TF2_OnConditionAdded(client, TFCond cond)
{
	if(g_bShredAlertTauntKill)
	{
		if(cond == TFCond_Taunting)
		{	
			if(GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex") == 1015) //Shred Alert
			{
				CreateTimer(g_fShredAlertDelay, t_ShredAlertTauntKill, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action t_ShredAlertTauntKill(Handle timer, int client)
{
	if(!IsValidClient(client))
		return Plugin_Continue;
	
	if(TF2_IsPlayerInCondition(client, TFCond_Taunting) && GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex") == 1015)
	{
		CreateExplosion(500, g_ShredAlertDamageRadius, 100.0, client, client, 5.0, true);
	}
	
	return Plugin_Continue;
}

void CreateExplosion(int damage = 100, int radius = 500, float force = 100.0, entityToSpawnAt = 0, owner = 0, float zOffset = 0.0, bool silent = false) //Why is the radius an int tho
{
	int explosion = CreateEntityByName("env_explosion");
	
	DispatchKeyValueFloat(explosion, "DamageForce", force);
	SetEntProp(explosion, Prop_Data, "m_iMagnitude", damage, 4);
	SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", radius, 4);
	
	if(IsValidClient(owner))
		SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", owner);
		
	if(silent)
	{
		SetVariantString("spawnflags 852");
		AcceptEntityInput(explosion,"AddOutput");
	}

	DispatchSpawn(explosion);

	float pos[3];
	
	if (IsValidEntity(entityToSpawnAt) && entityToSpawnAt > 0)
		GetEntPropVector(entityToSpawnAt, Prop_Send, "m_vecOrigin", pos);
		
	pos[2] += zOffset;
		
	TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);
	
	AcceptEntityInput(explosion, "Explode");
	AcceptEntityInput(explosion, "Kill");
}

int CreatePopUpBuilding(int client, float duration = 10.0, int buildingType = 0 /*1 Sentry, 0 Dispenser*/, int health = 100, bool solid = true)
{
	static char classname[64];
	float pos[3], fNormal[3];
	
	float vecClientEyePos[3];
	float vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos); 
	GetClientEyeAngles(client, vecClientEyeAng);

	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitClients);

	if(!TR_DidHit(INVALID_HANDLE))
		return -1;
	
	int TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
	GetEdictClassname(TRIndex, classname, sizeof(classname));
	if(!StrEqual(classname, "worldspawn"))
	return -1;
	
	TR_GetEndPosition(pos);
	float distance = GetVectorDistance(vecClientEyePos, pos);

	if(distance >= g_fPootisPowRange)
		return -1;

	TR_GetPlaneNormal(INVALID_HANDLE, fNormal);
	GetVectorAngles(fNormal, fNormal);
	fNormal[0] += 90.0;
	
	if (fNormal[0] >= 360.0)
		fNormal[0] -= 360.0;
	
	if (fNormal[0] > 110.0)
		return -1;
	
	int building = buildingType ? CreateEntityByName("obj_sentrygun") : CreateEntityByName("obj_dispenser");

	DispatchKeyValueVector(building, "origin", pos);
	DispatchKeyValueVector(building, "angles", fNormal);
	
	SetEntProp(building, Prop_Send, "m_bMiniBuilding", 1);
	SetEntProp(building, Prop_Send, "m_iHighestUpgradeLevel", 1);
	SetEntProp(building, Prop_Send, "m_bBuilding", 1);
	SetEntPropFloat(building, Prop_Send, "m_flModelScale", 0.75);
	SetVariantInt(solid ? 1 : 0);
	AcceptEntityInput(building, "SetSolidToPlayer"); //Note: a building is ALWAYS solid to the builder, this only modifies how other clients collide with it
	
	DispatchSpawn(building);

	SetVariantInt(TF2_GetClientTeam(client) == TFTeam_Red ? 2 : 3);
	AcceptEntityInput(building, "SetTeam");
	AcceptEntityInput(building, "Skin");

	ActivateEntity(building);
	SetEntPropEnt(building, Prop_Send, "m_hBuilder", client);
	
	SetVariantInt(health);
	AcceptEntityInput(building, "SetHealth");
	
	if(duration < 0.1)
		duration = 0.1;
	
	CreateTimer(duration, t_BuildingExpire, EntIndexToEntRef(building), TIMER_FLAG_NO_MAPCHANGE);
	
	return building;
}

public Action t_BuildingExpire(Handle timer, int building)
{
	building = EntRefToEntIndex(building);
	
	if(!IsValidEntity(building))
		return Plugin_Continue;

	Event boom = CreateEvent("object_removed", true);
	boom.SetInt("userid", GetClientUserId(GetEntPropEnt(building, Prop_Send, "m_hBuilder")));
	boom.SetInt("index", building);
	boom.Fire();
	
	SetVariantInt(GetEntPropEnt(building, Prop_Send, "m_iMaxHealth")+1);
	AcceptEntityInput(building, "RemoveHealth");
	
	AcceptEntityInput(building, "kill");
	
	int explosion = CreateEntityByName("env_explosion");

	DispatchSpawn(explosion);

	float pos[3];
	GetEntPropVector(building, Prop_Send, "m_vecOrigin", pos);

	TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(explosion, "Explode");
	
	AcceptEntityInput(explosion, "Kill");
	
	return Plugin_Continue;
}

void AnnounceTauntKill(attacker, boss, float damage)
{
	CreateDamageEvent(boss, attacker);
	
	g_TauntKillDamage[attacker] += RoundFloat(damage);
	g_TauntKills[attacker]++;
	
	if(g_bSoundAnnounce)
	{
		EmitSoundToAll(g_sSoundPath);
	}
	
	if(g_bTextAnnounce)
	{
		SetHudTextParams(-1.0, 0.2, g_fAnnounceDuration, 255, 255, 255, 255);
		
		for(int client = 1; client < MAXTF2PLAYERS; client++)
		{
			if(IsValidClient(client))
			{
				if(client == boss)
					ShowSyncHudText(client, AnnounceHud, "%N got a taunt kill against you for %1.0f damage!", attacker, damage);
				else if(client == attacker)
					ShowSyncHudText(client, AnnounceHud, "You got a taunt kill against %N for %1.0f damage!", boss, damage);
				else
					ShowSyncHudText(client, AnnounceHud, "%N got a taunt kill against %N for %1.0f damage!", attacker, boss, damage);
			}
		}
	}
}

void CreateDamageEvent(client, attacker)
{
	new Handle:HurtEvent = CreateEvent("player_hurt", true);
	SetEventInt(HurtEvent, "userid", GetClientUserId(client));
	SetEventInt(HurtEvent, "attacker", GetClientUserId(attacker));
	SetEventBool(HurtEvent, "crit", true);
	SetEventBool(HurtEvent, "allseecrit", true);
	FireEvent(HurtEvent);
}

void initTauntKillValues()
{
	g_bIsCustomTauntKill[7] = true;		//Hadouken
	g_bIsCustomTauntKill[9] = true;		//Showdown
	g_bIsCustomTauntKill[10] = true;	//Homerun
	g_bIsCustomTauntKill[13] = true;	//Fencing
	g_bIsCustomTauntKill[15] = true;	//Arrow stab
	//g_bIsCustomTauntKill[20] = true;	//Decapitation
	g_bIsCustomTauntKill[21] = true;	//Grenade
	g_bIsCustomTauntKill[24] = true;	//Decapitation again? (Barbarian Swing)
	g_bIsCustomTauntKill[29] = true;	//Uber taunt
	g_bIsCustomTauntKill[33] = true;	//Guitar Smash
	g_bIsCustomTauntKill[38] = true;	//Taunt engineer arm
	g_bIsCustomTauntKill[52] = true;	//Armageddon
	g_bIsCustomTauntKill[53] = true;	//Scorch Shot
	g_bIsCustomTauntKill[82] = true;	//Gas Blast
	
	g_fTauntKillDmgMult[7] = 1.0;		//Hadouken
	g_fTauntKillDmgMult[9] = 1.0;		//Showdown
	g_fTauntKillDmgMult[10] = 1.2;		//Homerun
	g_fTauntKillDmgMult[13] = 1.2;		//Fencing
	g_fTauntKillDmgMult[15] = 0.5;		//Arrow stab
	//g_fTauntKillDmgMult[20] = 0.4;		//Decapitation
	g_fTauntKillDmgMult[21] = 1.5;		//Grenade
	g_fTauntKillDmgMult[24] = 0.4;		//Decapitation again? (Barbarian Swing)
	g_fTauntKillDmgMult[29] = 1.1;		//Uber taunt
	g_fTauntKillDmgMult[33] = 0.35;		//Guitar Smash
	g_fTauntKillDmgMult[38] = 1.1;		//Gunslinger
	g_fTauntKillDmgMult[52] = 1.0;		//Armageddon
	g_fTauntKillDmgMult[53] = 1.0;		//Scorch Shot
	g_fTauntKillDmgMult[82] = 1.2;		//Gas Blast
}

int ActiveWeaponIndex(int client)
{
	if(!IsValidClient(client) || !IsPlayerAlive(client))
		return -2;

	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(!activeWeapon)
		return -1;
		
	return GetEntProp(activeWeapon, Prop_Send, "m_iItemDefinitionIndex");
}

public bool TraceRayDontHitClients(int entity, int mask)
{
	return (entity > MaxClients || entity < 1);
}

public Action ReloadKV(int client, int args)
{
	bool success = LoadKeyValues();
	
	if(success)
		PrintToChat(client, "[TKM] Reloaded Key Values");
	else
		PrintToChat(client, "[TKM] Could not find KV file");

	return Plugin_Handled;
}

bool LoadKeyValues()
{
	KvValues = CreateKeyValues("");
	
	char KvFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, KvFile, PLATFORM_MAX_PATH, "data/freak_fortress_2/tauntkillmods.cfg");
	
	bool FoundFile = true;
	
	if(!FileExists(KvFile))
	{
		LogError("[FF2 Taunt Kill Mods] Could not load cfg file -- using defaults");
		FoundFile = false;
	}
	
	if(FoundFile)
		FileToKeyValues(KvValues, KvFile);
	
	KvRewind(KvValues);
	KvGotoFirstSubKey(KvValues);
	
	g_bModifyTauntKills = view_as<bool>(KvGetNum(KvValues, "ModifyTauntKillDamage", 1));
	g_fTauntKillDamageThreshold = KvGetFloat(KvValues, "DamageThreshold", 75.0);
	g_fTauntKillFixedDamage = KvGetFloat(KvValues, "FixedDamage", 500.0);
	g_fTauntKillMaxDamage = KvGetFloat(KvValues, "MaxDamage", 7500.0);
	g_fBossHealthPercentage = KvGetFloat(KvValues, "BossHealthPercentage", 0.25);
	
	g_fTauntKillDmgMult[7] = KvGetFloat(KvValues, "DamageMult_Hadouken", 1.0);
	g_fTauntKillDmgMult[9] = KvGetFloat(KvValues, "DamageMult_Showdown", 1.0);
	g_fTauntKillDmgMult[10] = KvGetFloat(KvValues, "DamageMult_Homerun", 1.2);
	g_fTauntKillDmgMult[13] = KvGetFloat(KvValues, "DamageMult_Fencing", 1.2);
	g_fTauntKillDmgMult[15] = KvGetFloat(KvValues, "DamageMult_Arrow", 0.5);
	//g_fTauntKillDmgMult[20] = KvGetFloat(KvValues, "DamageMult_Decapitation", 1.2);	//woops, this is any weapon that causes decapitations, not the taunt kill
	g_fTauntKillDmgMult[21] = KvGetFloat(KvValues, "DamageMult_Grenade", 1.5);
	g_fTauntKillDmgMult[24] = KvGetFloat(KvValues, "DamageMult_Decapitation", 1.2);
	g_fTauntKillDmgMult[29] = KvGetFloat(KvValues, "DamageMult_Ubersaw", 1.1);
	g_fTauntKillDmgMult[33] = KvGetFloat(KvValues, "DamageMult_Guitarsmash", 1.1);
	g_fTauntKillDmgMult[38] = KvGetFloat(KvValues, "DamageMult_Gunslinger", 1.1);
	g_fTauntKillDmgMult[52] = KvGetFloat(KvValues, "DamageMult_Armageddon", 1.0);
	g_fTauntKillDmgMult[53] = KvGetFloat(KvValues, "DamageMult_Scorchshot", 1.0);
	g_fTauntKillDmgMult[82] = KvGetFloat(KvValues, "DamageMult_Gasblast", 1.2);
	g_fShredAlertDmgMult = KvGetFloat(KvValues, "DamageMult_Shredalert", 0.9);
	
	g_bPootisPowEnable = view_as<bool>(KvGetNum(KvValues, "PootisPowDispenser_Enable", 1));
	g_fPootisPowDispenserDuration = KvGetFloat(KvValues, "PootisPowDispenser_Duration", 10.0);
	g_fPootisPowWindowOpen = KvGetFloat(KvValues, "PootisPowDispenser_WindowOpen", 0.9);
	g_fPootisPowWindowDuration = KvGetFloat(KvValues, "PootisPowDispenser_WindowDuration", 0.17);
	g_PootisPowDispenserHealth = KvGetNum(KvValues, "PootisPowDispenser_Health", 50);
	
	g_bShredAlertTauntKill = view_as<bool>(KvGetNum(KvValues, "ShredAlert_TauntKill", 1));
	g_ShredAlertDamageRadius = KvGetNum(KvValues, "ShredAlert_Radius", 160);
	g_fShredAlertDelay = KvGetFloat(KvValues, "ShredAlert_Delay", 3.1);
	
	g_fHuntsmanTauntCooldown = KvGetFloat(KvValues, "Huntsman_Cooldown", 10.0);
	
	g_bTextAnnounce = view_as<bool>(KvGetNum(KvValues, "TextAnnounce", 1));
	g_bSoundAnnounce = view_as<bool>(KvGetNum(KvValues, "SoundAnnounce", 1));
	g_fAnnounceDuration = KvGetFloat(KvValues, "AnnounceDuration", 5.0);
	KvGetString(KvValues, "SoundAnnounce_SoundPath", g_sSoundPath, sizeof(g_sSoundPath), "misc/killstreak.wav");
	
	PrecacheSound(g_sSoundPath, true);
	
	if(g_fHuntsmanTauntCooldown < 0.0)
	{
		for(new client = 1; client < MAXTF2PLAYERS; client++)
		{
			g_bCanHuntsmanTaunt[client] = false;
		}
	}
	else
	{
		for(new client = 1; client < MAXTF2PLAYERS; client++)
		{
			g_bCanHuntsmanTaunt[client] = true;
		}
	}
	
	return FoundFile;
}

bool IsPlayerInvuln(client)
{
	if(!IsValidClient(client))
		return false;
	
	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) return true;
	if(TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden)) return true;
	if(TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen)) return true;
	if(TF2_IsPlayerInCondition(client, TFCond_Bonked)) return true;
	
	return false;
}

public Native_GetTauntKillDamage(Handle plugin, numParams)
{
	return g_TauntKillDamage[GetNativeCell(1)];
}

public Native_GetTauntKills(Handle plugin, numParams)
{
	return g_TauntKills[GetNativeCell(1)];
}

stock bool IsValidClient(client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client))
			return false;
	}
	return true;
}