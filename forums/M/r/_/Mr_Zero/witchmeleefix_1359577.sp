#include <sourcemod>
#include <sdktools>

#define REQUIRE_EXTENSIONS
#include <sdkhooks>

#define PLUGIN_VERSION	"1.1.2"
#define MAXENTITIES 	2048
#define TEAM_SURVIVOR	2
//#define DEBUG

static 			bool:	g_bIsWitchHooked[MAXENTITIES] 					= {false};
static					g_iWitchRestoreHealth[MAXENTITIES]				= {-1}

static					g_iMeleeWeaponOwner[MAXENTITIES] 				= {-1};
static 					g_iMeleeDamage 									= 250;
static	const	Float:	MELEE_COOLDOWN									= 0.3;
static			bool:	g_bInMeleeCooldown[MAXPLAYERS + 1][MAXENTITIES];

static					g_iDamageDoneToWitch[MAXPLAYERS + 1] 			= {0};
#if defined DEBUG
static			bool:	g_bHavePrinted[MAXPLAYERS + 1]					= {false}; // Used to prevent print spam, only need for debug mode
#endif

public Plugin:myinfo = 
{
	name = "Witch Melee Fix",
	author = "Mr. Zero",
	description = "Applies melee damage in a correct manner on witches for servers with customized witch health",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=144144"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (!IsDedicatedServer())
	{
		strcopy(error, err_max, "Plugin only support dedicated servers");
		return APLRes_Failure; // Plugin does not support client listen servers, return
	}

	decl String:buffer[128];
	GetGameFolderName(buffer, 128);

	if (!StrEqual(buffer, "left4dead2", false))
	{
		strcopy(error, err_max, "Plugin only support Left 4 Dead 2");
		return APLRes_Failure; // Plugin does not support this game, return
	}

	return APLRes_Success; // Allow load
}

public OnPluginStart()
{
	CreateConVar("l4d2_witch_melee_fix_version", PLUGIN_VERSION, "Witch Melee Fix Version", FCVAR_PLUGIN | FCVAR_NOTIFY);
	new Handle:cvar = CreateConVar("l4d2_witch_melee_fix_damage", "250", "How much damage melee weapons does to the witch (0 will completly block all melee damage to the witch, 250 is the default value).", FCVAR_PLUGIN);
	g_iMeleeDamage = GetConVarInt(cvar);
	HookConVarChange(cvar, MeleeDamageCvarChange);

	HookEvent("round_start", OnRoundStart);
	HookEvent("witch_spawn", OnWitchSpawn);
	HookEvent("witch_killed", OnWitchKilled);
	HookEvent("item_pickup", OnItemPickup);
	HookEvent("weapon_drop", OnWeaponDrop);
}

public OnAllPluginsLoaded()
{
	/* Account for late loading */

	new weapon;
	decl String:classname[32];
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR || !IsPlayerAlive(client)) continue;

		weapon = GetPlayerWeaponSlot(client, 1);
		if (weapon < 1 || weapon > MAXENTITIES || !IsValidEntity(weapon)) continue;

		GetEdictClassname(weapon, classname, sizeof(classname));
		if (!StrEqual(classname, "weapon_melee")) continue;

		g_iMeleeWeaponOwner[weapon] = client;
		DebugPrintToChatAll("LateLoad: Melee weapon %i is now owned by %N (%i)", weapon, client, client);
	}

	for (new entity = 1; entity < MAXENTITIES; entity++)
	{
		if (!IsValidEntity(entity)) continue;

		GetEdictClassname(entity, classname, sizeof(classname));
		if (!StrEqual(classname, "witch")) continue;

		SDKHook(entity, SDKHook_OnTakeDamage, OnWitchTakeDamage);
		SDKHook(entity, SDKHook_OnTakeDamagePost , OnWitchTakeDamage_Post);
		g_bIsWitchHooked[entity] = true;
		g_iWitchRestoreHealth[entity] = -1;
		DebugPrintToChatAll("LateLoad: Hooked witch %i", entity);
	}
}

public MeleeDamageCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iMeleeDamage = StringToInt(newValue);
	if (g_iMeleeDamage < 0) g_iMeleeDamage = 0; // Healing melee weapons? :3
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new entity = 1; entity < MAXENTITIES; entity++)
	{
		if (g_bIsWitchHooked[entity])
		{
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnWitchTakeDamage);
			SDKUnhook(entity, SDKHook_OnTakeDamagePost , OnWitchTakeDamage_Post);
			g_bIsWitchHooked[entity] = false;
		}
		g_iMeleeWeaponOwner[entity] = -1;
	}
}

public OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) return;

	decl String:itemName[32];
	GetEventString(event, "item", itemName, sizeof(itemName));

	if (!StrEqual(itemName, "melee")) return;

	new weapon = GetPlayerWeaponSlot(client, 1); // Get melee weapon entity
	if (weapon < 1 || weapon > MAXENTITIES || !IsValidEntity(weapon)) return;

	g_iMeleeWeaponOwner[weapon] = client;
	DebugPrintToChatAll("Melee weapon %i is now owned by %N (%i)", weapon, client, client);
}

public OnWeaponDrop(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:itemName[32];
	GetEventString(event, "item", itemName, sizeof(itemName));

	if (!StrEqual(itemName, "melee")) return;

	new weapon = GetEventInt(event, "propid");
	g_iMeleeWeaponOwner[weapon] = -1;
	DebugPrintToChatAll("Melee weapon %i is no longer owned", weapon);
}

public OnWitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new witch = GetEventInt(event, "witchid");
	SDKHook(witch, SDKHook_OnTakeDamage, OnWitchTakeDamage);
	SDKHook(witch, SDKHook_OnTakeDamagePost , OnWitchTakeDamage_Post);
	g_bIsWitchHooked[witch] = true;
	g_iWitchRestoreHealth[witch] = -1;
}

public OnWitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new witch = GetEventInt(event, "witchid");
	SDKUnhook(witch, SDKHook_OnTakeDamage, OnWitchTakeDamage);
	SDKUnhook(witch, SDKHook_OnTakeDamagePost , OnWitchTakeDamage_Post);
	g_bIsWitchHooked[witch] = false;
	g_iWitchRestoreHealth[witch] = -1;
}

public Action:OnWitchTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	/* Both attacker and inflictor returns melee weapon entity index, not the
	 * attacking client. */

	new client = g_iMeleeWeaponOwner[attacker];
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR) return Plugin_Continue;

	/* Each melee swing triggers OnTakeDamage multiple times, probably
	 * the tracers that hit a part of the witch. However we only need to
	 * apply damage to the witch once, therefore ignore multiple tracers. */
	if (g_bInMeleeCooldown[client][victim]) return Plugin_Handled;

	new statsDamage = GetEntProp(client, Prop_Send, "m_checkpointDamageToWitch"); // Survivor stats
	DebugPrintToChatAll("Damage to witch: %i", statsDamage);

	new health = GetEntProp(victim, Prop_Data, "m_iHealth");
	health -= g_iMeleeDamage;
	DebugPrintToChatAll("Witch health after melee: %i", health);

	if (health > 0) // if this melee hit won't kill the witch
	{
		DebugPrintToChatAll("God mode applied");
		SetEntProp(victim, Prop_Data, "m_iHealth", 999999); // Apply god mode to the witch!
		g_iWitchRestoreHealth[victim] = health; // Restore her health after melee damage has been applied

		statsDamage += g_iMeleeDamage; // Apply correct damage to stats
	}
	else
	{
		statsDamage += GetEntProp(victim, Prop_Data, "m_iHealth"); // Apply correct damage to stats

		DebugPrintToChatAll("Health set to 1");
		SetEntProp(victim, Prop_Data, "m_iHealth", 1); // Witch should die on this melee hit, set her health to 1
	}

	g_iDamageDoneToWitch[client] = statsDamage;

	g_bInMeleeCooldown[client][victim] = true;
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, victim);
	CreateTimer(MELEE_COOLDOWN, MeleeDamageCooldown_Timer, pack);

	return Plugin_Continue;
}

public OnWitchTakeDamage_Post(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (g_iWitchRestoreHealth[victim] != -1)
	{
		SetEntProp(victim, Prop_Data, "m_iHealth", g_iWitchRestoreHealth[victim]);
		g_iWitchRestoreHealth[victim] = -1;
		DebugPrintToChatAll("Witch health restored");
	}

	/* Fix survivor stats */
	new client = g_iMeleeWeaponOwner[attacker];
	if (client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR)
	{
		SetEntProp(client, Prop_Send, "m_checkpointDamageToWitch", g_iDamageDoneToWitch[client]);
#if defined DEBUG
		if (!g_bHavePrinted[client])
		{
			DebugPrintToChatAll("Damage to witch after: %i", g_iDamageDoneToWitch[client]);
			g_bHavePrinted[client] = true;
		}
#endif
	}
}

public Action:MeleeDamageCooldown_Timer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new victim = ReadPackCell(pack);
	CloseHandle(pack);
	g_bInMeleeCooldown[client][victim] = false;

#if defined DEBUG
	g_bHavePrinted[client] = false;
#endif

	return Plugin_Stop;
}

static DebugPrintToChatAll(const String:format[], any:...)
{
#pragma unused format // make the compiler silent about format nothing being used
#if defined DEBUG
	decl String:buffer[256];
	VFormat(buffer, 256, format, 2);
	PrintToChatAll("[DEBUG] %s", buffer);
#endif
}