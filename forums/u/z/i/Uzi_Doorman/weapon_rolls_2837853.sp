#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
#include <weaponhandling>

#define OVERALL_ATTRIBUTE_CHANCE 0.20
#define CHAPTER_CHANCE_BONUS 0.15
#define GOD_ROLL_CHANCE 0.05
#define MIN_DISPLAY_MULTI 0.05
#define MIN_DISPLAY_AMMO 0.01
#define CHAPTER_DOWNGRADE_CHANCE 0.5
#define BASE_DMG 1
#define BASE_AMMO_CHANCE 0.02
#define MAX_AMMO_CHANCE 0.15
#define MIN_FIRERATE 0.7
#define MAX_FIRERATE 2.5
#define MIN_RELOADSPEED 0.7
#define MAX_RELOADSPEED 2.0
#define BASE_FIRERATE_CHANCE 0.1
#define HEAVY_SLOWDOWN 0.75		// 25% slower
#define LIGHT_SPEEDBOOST 1.10	// 10% faster
#define SCOUT_SPEEDBOOST 1.30	// 30% faster
#define EXPLOSION_RADIUS 200.0
#define SURVIVAL_MULTI 7.5
#define VERSUS_MULTI 1.5
#define SCAVENGE_MULTI 5.0
#define SET_BONUSCHANCE 0.005

//class bitflags
#define CLASS_SMG (1<<0)
#define CLASS_PUMPSHOTGUN (1<<1)
#define CLASS_AUTOSHOTGUN (1<<2)
#define CLASS_RIFLE (1<<3)
#define CLASS_HUNTING_RIFLE (1<<4)
#define CLASS_SMG_SILENCED (1<<5)
#define CLASS_SHOTGUN_CHROME (1<<6)
#define CLASS_RIFLE_DESERT (1<<7)
#define CLASS_SNIPER_MILITARY (1<<8)
#define CLASS_SHOTGUN_SPAS (1<<9)
#define CLASS_GRENADE_LAUNCHER (1<<10)
#define CLASS_RIFLE_AK47 (1<<11)
#define CLASS_SMG_MP5 (1<<12)
#define CLASS_RIFLE_SG552 (1<<13)
#define CLASS_SNIPER_AWP (1<<14)
#define CLASS_SNIPER_SCOUT (1<<15)
#define CLASS_RIFLE_M60 (1<<16)

#define CATEGORY_SMG (CLASS_SMG | CLASS_SMG_MP5 | CLASS_SMG_SILENCED)
#define CATEGORY_SHOTGUN (CLASS_SHOTGUN_CHROME | CLASS_SHOTGUN_SPAS | CLASS_PUMPSHOTGUN | CLASS_AUTOSHOTGUN)
#define CATEGORY_RIFLE (CLASS_RIFLE | CLASS_RIFLE_AK47 | CLASS_RIFLE_DESERT | CLASS_RIFLE_SG552 | CLASS_RIFLE_M60)
#define CATEGORY_SNIPER (CLASS_HUNTING_RIFLE | CLASS_SNIPER_AWP | CLASS_SNIPER_MILITARY | CLASS_SNIPER_SCOUT)
#define CATEGORY_ALL (0xFFFF)

static const char weps[][] = {
	"weapon_smg", "weapon_pumpshotgun", "weapon_autoshotgun", "weapon_rifle",
	"weapon_hunting_rifle", "weapon_smg_silenced", "weapon_shotgun_chrome",
	"weapon_rifle_desert", "weapon_sniper_military", "weapon_shotgun_spas",
	"weapon_grenade_launcher", "weapon_rifle_ak47", "weapon_smg_mp5",
	"weapon_rifle_sg552", "weapon_sniper_awp", "weapon_sniper_scout",
	"weapon_rifle_m60"
};

static const char negative_adjectives[][24] = {
	"Cursed", "Rusted", "Blighted", "Corroded", "Hollowed", "Cracked", "Broken", 
	"Forsaken", "Vile", "Rotten", "Defiled", "Tainted", "Shameful", "Feeble", 
	"Worthless", "Shoddy", "Damaged", "Withered", "Decrepit", "Frail", "Weak",
	"Pathetic", "Miserable", "Dismal", "Lamentable", "Pitiful", "Woeful", "Abysmal",
	"Appalling", "Dreadful", "Atrocious", "Ghastly", "Horrid", "Execrable", "Abominable",
	"Detestable", "Despicable", "Contemptible", "Reprehensible", "Odious", "Vicious",
	"Malignant", "Pernicious", "Deleterious", "Baleful", "Baneful", "Noxious", "Pestilent",
	"Venomous", "Toxic", "Putrid", "Festering", "Decaying", "Decomposing", "Foul"
};

static const char neutral_adjectives[][24] = {
	"Standard", "Common", "Ordinary", "Regular", "Typical", "Usual", "Conventional",
	"Everyday", "Plain", "Simple", "Basic", "Routine", "Normal", "Average", "Mundane",
	"Unremarkable", "Unexceptional", "Mediocre", "Adequate", "Passable", "Acceptable",
	"Moderate", "Reasonable", "Fair", "Decent", "Satisfactory", "Tolerable", "Functional",
	"Practical", "Utilitarian", "Unadorned", "Unembellished", "Unpretentious", "Humble",
	"Modest", "Unassuming", "Unostentatious", "Unobtrusive", "Subdued", "Understated",
	"Quiet", "Subtle", "Discreet", "Reserved", "Conservative", "Traditional", "Classic",
	"Vintage", "Timeworn", "Weathered"
};

static const char positive_adjectives[][24] = {
	"Tactical", "Veteran", "Precise", "Reliable", "Sturdy", "Durable", "Robust",
	"Resilient", "Stalwart", "Hardy", "Stout", "Potent", "Effective", "Efficient",
	"Superior", "Enhanced", "Improved", "Upgraded", "Advanced", "Premium", "Prime",
	"Choice", "Select", "Elite", "Exceptional", "Superb", "Splendid", "Magnificent",
	"Grand", "Noble", "Exalted", "Eminent", "Distinguished", "Illustrious", "Renowned",
	"Celebrated", "Famed", "Notable", "Noteworthy", "Remarkable", "Extraordinary",
	"Phenomenal", "Prodigious", "Stupendous", "Colossal", "Titanic", "Monumental",
	"Tremendous", "Gigantic", "Immense"
};

static const char godly_adjectives[][24] = {
	"Divine", "Eternal", "Celestial", "Sacred", "Hallowed", "Legendary", "Mythic",
	"Exalted", "Immortal", "Infernal", "Angelic", "Demonic", "Blessed", "Almighty",
	"Omnipotent", "Transcendent", "Unholy", "Apocalyptic", "Cosmic", "Primordial",
	"Godlike", "Deific", "Seraphic", "Cherubic", "Archangelic", "Demiurgic", "Protean",
	"Omniscient", "Ubiquitous", "Infinite", "Boundless", "Limitless", "Immeasurable",
	"Unfathomable", "Unlimited", "Absolute", "Supreme", "Paramount", "Preeminent",
	"Unrivaled", "Peerless", "Matchless", "Unsurpassed", "Unparalleled", "Incomparable",
	"Unbeatable", "Invincible", "Invulnerable", "Indestructible", "Imperishable"
};

static const char negative_suffixes[][32] = {
	"of Failure", "of Weakness", "of Shame", "of Misfortune", "of the Damned",
	"of Regret", "of Sorrow", "of Despair", "of the Loser", "of the Fool",
	"of Broken Dreams", "of Lost Hope", "of the Coward", "of the Unworthy",
	"of Incompetence", "of Mediocrity", "of Deficiency", "of Ineptitude",
	"of Inadequacy", "of Shortcoming", "of Imperfection", "of Flaw", "of Defect",
	"of Fault", "of Blemish", "of Stain", "of Taint", "of Corruption", "of Degradation",
	"of Deterioration", "of Decay", "of Rot", "of Putrefaction", "of Decomposition",
	"of Dilapidation", "of Ruin", "of Desolation", "of Devastation", "of Destruction",
	"of Annihilation", "of Oblivion", "of Nothingness", "of the Void", "of Emptiness",
	"of Barrenness", "of Sterility", "of Futility", "of Hopelessness", "of Helplessness",
	"of Powerlessness"
};

static const char neutral_suffixes[][32] = {
	"of the Common", "of the Ordinary", "of the Average", "of the Usual", "of the Typical",
	"of the Routine", "of the Everyday", "of the Standard", "of the Regular", "of the Norm",
	"of the Conventional", "of the Traditional", "of the Customary", "of the Habitual",
	"of the Familiar", "of the Known", "of the Expected", "of the Predictable", "of the Safe",
	"of the Secure", "of the Steady", "of the Stable", "of the Balanced", "of the Moderate",
	"of the Temperate", "of the Reasonable", "of the Sensible", "of the Practical",
	"of the Functional", "of the Utilitarian", "of the Adequate", "of the Sufficient",
	"of the Satisfactory", "of the Passable", "of the Tolerable", "of the Acceptable",
	"of the Decent", "of the Respectable", "of the Presentable", "of the Middling",
	"of the Medium", "of the Midpoint", "of the Center", "of the Core", "of the Heart",
	"of the Essence", "of the Basis", "of the Foundation", "of the Ground", "of the Earth"
};

static const char positive_suffixes[][32] = {
	"of Precision", "of Accuracy", "of Reliability", "of Durability", "of Sturdiness",
	"of Resilience", "of Potency", "of Effectiveness", "of Efficiency", "of Superiority",
	"of Enhancement", "of Improvement", "of Advancement", "of Excellence", "of Greatness",
	"of Grandeur", "of Magnificence", "of Splendor", "of Majesty", "of Nobility",
	"of Distinction", "of Renown", "of Fame", "of Acclaim", "of Praise", "of Honor",
	"of Glory", "of Triumph", "of Victory", "of Conquest", "of Dominance", "of Supremacy",
	"of Leadership", "of Mastery", "of Expertise", "of Skill", "of Prowess", "of Might",
	"of Power", "of Strength", "of Force", "of Energy", "of Vigor", "of Vitality",
	"of Life", "of Vitality", "of Vigor", "of Zeal", "of Passion", "of Fire"
};

static const char godly_suffixes[][32] = {
	"of the Gods", "of Divinity", "of Eternity", "of Immortality", "of the Heavens",
	"of the Cosmos", "of Creation", "of Genesis", "of the Beginning", "of the End",
	"of Apotheosis", "of Ascension", "of Transcendence", "of Omnipotence", "of Omniscience",
	"of Ubiquity", "of Infinity", "of the Void", "of the Abyss", "of the Nexus",
	"of the Multiverse", "of Reality", "of Existence", "of Essence", "of the Soul",
	"of the Spirit", "of Enlightenment", "of Perfection", "of Purity", "of Absolution",
	"of Redemption", "of Salvation", "of Damnation", "of Hellfire", "of the Inferno",
	"of the Pit", "of the Chasm", "of the Depths", "of the Heights", "of the Zenith",
	"of the Pinnacle", "of the Apex", "of the Summit", "of the Peak", "of the Crown",
	"of the Throne", "of Sovereignty", "of Dominion", "of Empire", "of Kingdom"
};

enum Effect
{
	EFFECT_GLITCH,
}

enum struct Roll
{
	int effect;
	int uid;
	int damage;
	float multi;
	int damageType;
	float ammoChance;
	bool hasAttributes;
	bool isGodRoll;
	int effectiveChapter;
	bool unrefillable;
	bool heavy;
	bool light;
	bool vampiric;
	bool heat;
	bool recharge;
	bool isSetItem;
	bool noBullet;
	float fireRate;
	float reloadSpeed;
	bool scout;
	int savedClip;
	int savedReserve;
	float toxicMulti;
	float toxicDmg;
	float heatDmg;
	char display[256];
}

enum struct Set
{
	char name[256];
	char cmd[256];
	Roll roll;
	int class;
	float chance;
}

StringMap g_WeaponSets;
StringMap g_WeaponRolls;
StringMap g_WeaponSpawnRolls;
StringMap g_UnrefillableWeapon;
int g_LastSpawnUsed[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
Handle g_hSpawnTimer[MAXPLAYERS+1] = {null, ...};
StringMap g_sCache;
bool g_bUnrefillableActive[MAXPLAYERS+1];
bool g_bRestore[MAXPLAYERS+1];
bool g_bAmmoCheck;
int g_iWeaponUID = 1;

public Plugin myinfo = {
	name = "Weapon Rolls",
	author = "Uzi",
	description = "Diablo2-style weapon rolls.",
	version = "1.0.1",
	url = ""
};

public void OnPluginStart()
{
	g_WeaponSets = new StringMap();
	g_WeaponRolls = new StringMap();
	g_WeaponSpawnRolls = new StringMap();
	g_sCache = new StringMap();
	g_UnrefillableWeapon = new StringMap();
	
	LoadSets();
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("mission_lost", Event_Lost, EventHookMode_Post);
	HookEvent("round_end", Event_Lost, EventHookMode_Post);
	HookEvent("survival_round_start", Event_Start, EventHookMode_Post);
	HookEvent("versus_round_start", Event_Start, EventHookMode_Post);
	HookEvent("scavenge_round_start", Event_Start, EventHookMode_Post);
	HookEvent("weapon_fire", Event_WFire, EventHookMode_Post);
	
	RegAdminCmd("sm_wr_set", Command_GiveSet, ADMFLAG_ROOT, "Give yourself a weapon rolls set item");
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (g_hSpawnTimer[client] != null) {
		KillTimer(g_hSpawnTimer[client]);
		g_hSpawnTimer[client] = null;
	}
	g_LastSpawnUsed[client] = INVALID_ENT_REFERENCE;
	char steamid[32];
	if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
		StrClear(steamid);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		// Reset speed modifiers on spawn
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		g_bUnrefillableActive[client] = false;
	}
}

public void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "weapon_ammo_spawn")) != -1) {
		SDKHook(entity, SDKHook_Use, OnUseAmmoPile);
	}
}

public void Event_WFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == -1) return;
	int weapon = event.GetInt("weaponid");
	if (weapon == -1) return;
	int ref = EntIndexToEntRef(weapon);
	char key[12];
	IntToString(ref, key, sizeof(key));
	Roll roll;
	char steamid[32];
	if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
	{
		if (g_WeaponRolls.GetArray(key, roll, sizeof(roll)) && roll.unrefillable)
		{
			int ammo = event.GetInt("count");
			int reserve = L4D_GetReserveAmmo(client, weapon);
			roll.savedClip = ammo;
			roll.savedReserve = reserve;
			StrAddRoll(steamid, roll);
			g_WeaponRolls.SetArray(key, roll, sizeof(roll));
		}
	}
}

void SetRestore()
{
	g_bAmmoCheck = true;
	for (int client = 1; client <= MaxClients; client++)
	{
		g_bRestore[client] = true;
		g_LastSpawnUsed[client] = INVALID_ENT_REFERENCE;
	}
}

public void OnMapStart()
{
	if (L4D_IsFirstMapInScenario())
		g_sCache.Clear();
		
	g_UnrefillableWeapon.Clear();
	g_bAmmoCheck = false;
	g_WeaponRolls.Clear();
	g_WeaponSpawnRolls.Clear(); // Clear spawn rolls on map start
	SetRestore();
	CreateTimer(0.1, Timer_Hook, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
	Fail();
	return Plugin_Continue;
}

public Action Timer_Hook(Handle timer)
{
	g_WeaponSpawnRolls.Clear();
	g_UnrefillableWeapon.Clear();
	int ammo = -1;
	while ((ammo = FindEntityByClassname(ammo, "weapon_ammo_spawn")) != -1) {
		SDKHook(ammo, SDKHook_Use, OnUseAmmoPile);
	}
	int inf = -1;
	while ((inf = FindEntityByClassname(inf, "infected")) != -1) {
		SDKHook(inf, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	for (int wep = -1; wep < 2048; wep++)
	{
		if (IsValidEntity(wep))
		{
			char class[32];
			GetEntityClassname(wep, class, sizeof(class));
			if (StrContains(class, "weapon") != -1 && StrContains(class, "ammo") == -1)
			{
				SDKHook(wep, SDKHook_Use, OnUseWeaponSpawn);
			}
		}
	}
	return Plugin_Handled;
}

public Action OnUseWeaponSpawn(int entity, int activator, int caller, UseType type, float value)
{
	if (!IsValidEntity(entity))
		return Plugin_Handled;
		
	if (activator > 0 && activator <= MaxClients && IsClientInGame(activator))
	{
		// Check if this spawn has a saved roll for this player
		char steamid[32];
		if (!GetClientAuthId(activator, AuthId_Steam2, steamid, sizeof(steamid)))
			return Plugin_Continue;
			
		int spawnRef = EntIndexToEntRef(entity);
		char key[64];
		Format(key, sizeof(key), "%d_%s", spawnRef, steamid);
		
		Roll savedRoll;
		if (g_WeaponSpawnRolls.GetArray(key, savedRoll, sizeof(savedRoll)))
		{
			// Block if unrefillable attribute exists
			if (savedRoll.unrefillable) {
				bool found = false;
				for (int client = 1; client <= MaxClients; client++)
				{
					if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
					{
						int primary = GetPlayerWeaponSlot(client, 0);
						if (primary != -1)
						{
							int ref = EntIndexToEntRef(primary);
							char rkey[12];
							IntToString(ref, rkey, sizeof(rkey));
							Roll wepRoll;
							if (g_WeaponRolls.GetArray(rkey, wepRoll, sizeof(wepRoll)))
							{
								if (CompareRolls(wepRoll, savedRoll))
								{
									found = true;
									break;
								}
							}
						}
					}
				}
				if (!found)
				{
					for (int wep = -1; wep < 2048; wep++)
					{
						if (IsValidEntity(wep) && wep != entity)
						{
							int ref = EntIndexToEntRef(wep);
							char rkey[12];
							IntToString(ref, rkey, sizeof(rkey));
							Roll wepRoll;
							if (g_WeaponRolls.GetArray(rkey, wepRoll, sizeof(wepRoll)))
							{
								if (CompareRolls(wepRoll, savedRoll))
								{
									found = true;
									break;
								}
							}
						}
					}
				}
				if (found)
				{
					PrintHintText(activator, "You can't refill this weapon.");
					return Plugin_Handled;
				}
			}
		}
		
		// Set up spawn usage tracking
		if (g_hSpawnTimer[activator] != null) {
			KillTimer(g_hSpawnTimer[activator]);
			g_hSpawnTimer[activator] = null;
		}
		g_LastSpawnUsed[activator] = spawnRef;
		g_hSpawnTimer[activator] = CreateTimer(5.0, Timer_ClearLastSpawn, activator);
	}	
	return Plugin_Continue;
}

public Action Timer_ClearLastSpawn(Handle timer, int client)
{
	g_LastSpawnUsed[client] = INVALID_ENT_REFERENCE;
	g_hSpawnTimer[client] = null;
	return Plugin_Stop;
}

public Action L4D1_OnSavingEntities()
{
	SaveWeapons();
	return Plugin_Continue;
}

public Action L4D2_OnSavingEntities()
{
	SaveWeapons();
	return Plugin_Continue;
}

public void Event_Lost(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bAmmoCheck)
		Fail();
}

void Fail()
{
	g_WeaponRolls.Clear();
	g_WeaponSpawnRolls.Clear();
	SetRestore();
}

void SaveWeapons()
{
	g_sCache.Clear();
	for (int client = 1; client < MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			int weapon = GetPlayerWeaponSlot(client, 0);
			if (weapon != -1)
			{
				int ref = EntIndexToEntRef(weapon);
				char key[12];
				IntToString(ref, key, sizeof(key));
				if (g_WeaponRolls.ContainsKey(key))
				{
					Roll roll;
					if (g_WeaponRolls.GetArray(key, roll, sizeof(roll)))
					{
						if (roll.hasAttributes)
						{
							char auth[128];
							GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
							g_sCache.SetArray(auth, roll, sizeof(roll));
						}
					}
				}
			}
		}
	}
	g_WeaponRolls.Clear();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity <= -1)
		return;
		
	if (!IsValidEntity(entity))
		return;
	
	if (StrEqual(classname, "infected")) {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		return;
	}
	
	if (StrEqual(classname, "weapon_ammo_spawn")) {
		SDKHook(entity, SDKHook_Use, OnUseAmmoPile);
		return;
	}
}

public Action OnUseAmmoPile(int entity, int activator, int caller, UseType type, float value)
{
	if (!IsValidEntity(entity))
		return Plugin_Handled;
		
	if (activator > 0 && activator <= MaxClients && IsClientInGame(activator)) {
		int activeWeapon = GetPlayerWeaponSlot(activator, 0);
		if (activeWeapon != -1) {
			char key[12];
			IntToString(EntIndexToEntRef(activeWeapon), key, sizeof(key));
			Roll roll;
			if (g_WeaponRolls.GetArray(key, roll, sizeof(roll)) && roll.hasAttributes && roll.unrefillable) {
				PrintHintText(activator, "You can't refill with this weapon.");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, Event_EquipWeapon);
	SDKHook(client, SDKHook_WeaponDropPost, Event_WeaponDrop);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	g_bUnrefillableActive[client] = false;
	g_LastSpawnUsed[client] = INVALID_ENT_REFERENCE;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!(damagetype & DMG_BULLET))
		return Plugin_Continue;
	
	if (IsPlayer(victim) && IsClientInGame(victim) && IsPlayerAlive(victim))
	{
		if (GetClientTeam(victim) == 2)
			return Plugin_Continue;
			
		if (GetClientTeam(victim) == 3 && GetEntProp(victim, Prop_Send, "m_zombieClass") == 8)
		{
			if (GetClientHealth(victim) <= 100)
			{
				if (damagetype & DMG_BURN)
					damagetype &= ~DMG_BURN;
					
				if (damagetype & DMG_BLAST)
					damagetype &= ~DMG_BLAST;
			
				if (damagetype & DMG_RADIATION)
					damagetype &= ~DMG_RADIATION;
			}
		}
	}
	
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && IsPlayerAlive(attacker)) {
		int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (weapon != -1) {
			char key[12];
			IntToString(EntIndexToEntRef(weapon), key, sizeof(key));
			
			Roll roll;
			if (g_WeaponRolls.GetArray(key, roll, sizeof(Roll)) && roll.hasAttributes) {
				
				switch(roll.effect)
				{
					case EFFECT_GLITCH:
					{
						int uid = roll.uid;
						DefaultRoll(roll);
						roll.effect = EFFECT_GLITCH;
						roll.uid = uid;
						int min = GetRandomInt(-500, -1);
						int max = GetRandomInt(1, 500);
						roll.damage = GetRandomInt(min, max);
						int type = GetRandomInt(1, 10);
						switch(type)
						{
							case 1: type = DMG_BURN;
							case 2: type = DMG_BUCKSHOT;
							case 3: type = DMG_BLAST;
							case 4: type = DMG_RADIATION;
							default: type = DMG_BULLET;
						}
						roll.damageType = type;
						if (GetRandomFloat() < 0.10)
							roll.vampiric = true;
							
						if (GetRandomFloat() < 0.10)
							roll.heat = true;
							
						if (roll.damageType == DMG_RADIATION)
						{
							roll.toxicMulti = GetRandomFloat();
							if (GetRandomFloat() < 0.25)
								roll.toxicDmg = GetRandomFloat(-100.0, 100.0);
						}
						if (roll.heat)
							if (GetRandomFloat() < 0.25)
								roll.heatDmg = GetRandomFloat(1.0, 100.0);
					}
				}
				
				// Apply damage multiplier
				damage *= roll.multi;
				
				// Add flat damage
				damage += float(roll.damage);
				
				// Add damage type instead of overriding
				if (roll.damageType != DMG_BULLET) {
					damagetype |= roll.damageType;
				}
				
				if (roll.noBullet)
				{
					damagetype &= ~DMG_BULLET;
				}
				
				if (IsPlayer(victim) && GetClientTeam(victim) == 3 && GetEntProp(victim, Prop_Send, "m_zombieClass") == 8)
				{
					if (damagetype & DMG_BLAST)
						damagetype &= ~DMG_BLAST;
				}
				
				// Handle vampiric heal
				if (roll.vampiric) {
					char classname[64];
					GetEntityClassname(weapon, classname, sizeof(classname));
					
					float healChance = 0.10;
					float minHeal = 0.05;
					float maxHeal = 0.10;
					
					if (GetRandomFloat() < healChance) {
						float healPercent = GetRandomFloat(minHeal, maxHeal);
						int healAmount = RoundToCeil(damage * healPercent);
						if (healAmount > 0) {
							int health = GetClientHealth(attacker);
							int maxHealth = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
							if (health + healAmount > maxHealth) {
								SetEntityHealth(attacker, maxHealth);
							} else {
								SetEntityHealth(attacker, health + healAmount);
							}
						}
					}
				}
				
				// Handle heat effect
				if (roll.heat) {
					float pos[3];
					if (victim <= MaxClients && victim > 0) {
						GetClientAbsOrigin(victim, pos);
					} else {
						GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
					}
					
					// Deal splash damage to nearby common infected
					int entity = -1;
					while ((entity = FindEntityByClassname(entity, "infected")) != -1) {
						if (entity != victim && GetEntProp(entity, Prop_Data, "m_iHealth") > 0) {
							float targetPos[3];
							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", targetPos);
							
							float distance = GetVectorDistance(pos, targetPos);
							if (distance < EXPLOSION_RADIUS) {
								float splashDamage = damage * GetRandomFloat(0.05, 0.1) + roll.heatDmg;
								SDKHooks_TakeDamage(entity, attacker, attacker, splashDamage, DMG_BUCKSHOT, weapon);
							}
						}
					}
					
					// Deal splash damage to nearby special infected
					for (int i = 1; i <= MaxClients; i++) {
						if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && !L4D_IsPlayerGhost(i) && i != victim) {
							float targetPos[3];
							GetClientAbsOrigin(i, targetPos);
							
							float distance = GetVectorDistance(pos, targetPos);
							if (distance < EXPLOSION_RADIUS) {
								float splashDamage = damage * GetRandomFloat(0.01, 0.05) + roll.heatDmg;
								SDKHooks_TakeDamage(i, attacker, attacker, splashDamage, DMG_BLAST, weapon);
							}
						}
					}
				}
				
				// Handle ammo chance
				if (roll.ammoChance > 0.0 && GetRandomFloat() <= roll.ammoChance) {
					int ammo = L4D_GetReserveAmmo(attacker, weapon);
					L4D_SetReserveAmmo(attacker, weapon, ammo + 1);
					if (roll.unrefillable)
					{
						char steamid[32];
						if (GetClientAuthId(attacker, AuthId_Steam2, steamid, sizeof(steamid)))
						{
							ammo = GetEntProp(weapon, Prop_Data, "m_iClip1");
							int reserve = L4D_GetReserveAmmo(attacker, weapon);
							roll.savedClip = ammo;
							roll.savedReserve = reserve;
							StrAddRoll(steamid, roll);
							g_WeaponRolls.SetArray(key, roll, sizeof(roll));
						}
					}
				}
				
				if (roll.damageType & DMG_RADIATION)
				{
					DataPack data = new DataPack();
					data.WriteCell(EntIndexToEntRef(victim));
					data.WriteCell(GetClientUserId(attacker));
					data.WriteCell(EntIndexToEntRef(weapon));
					data.WriteFloat(damage * roll.toxicMulti + roll.toxicDmg);
					data.WriteFloat(GetGameTime() + 10.0);
					CreateTimer(1.0, Timer_Radiation, data, TIMER_REPEAT);
				}
				
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Radiation(Handle timer, DataPack data)
{
	data.Reset();
	int victim = EntRefToEntIndex(data.ReadCell());
	int attacker = GetClientOfUserId(data.ReadCell());
	int weapon = EntRefToEntIndex(data.ReadCell());
	float damage = data.ReadFloat();
	float endTime = data.ReadFloat();
	bool validVictim = IsValidEntity(victim) && (!IsPlayer(victim) || (IsClientInGame(victim) && IsPlayerAlive(victim)));
	bool validAttacker = attacker > 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker);
	if (!validVictim || !validAttacker || weapon == -1 || GetGameTime() > endTime)
	{
		delete data;
		return Plugin_Stop;
	}
	if (IsPlayer(victim) && IsTank(victim) && GetClientHealth(victim) <= 100)
	{
		delete data;
		return Plugin_Stop;
	}
	
	if (damage < 1.5)
		damage = 1.5;
		
	SDKHooks_TakeDamage(victim, weapon, attacker, damage, DMG_RADIATION);
	return Plugin_Continue;
}

bool IsPlayer(int client)
{
	char class[64];
	if (client <= 0 || client > MAXPLAYERS+1) return false;
	GetEntityClassname(client, class, sizeof(class));
	if (!StrEqual(class, "player")) return false;
	return true;
}

bool IsTank(int client)
{
	return IsClientInGame(client) && 
		   GetClientTeam(client) == 3 && 
		   GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}

public Action Timer_Restore(Handle timer, int client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		int weapon = GetPlayerWeaponSlot(client, 0);
		if (weapon != -1)
		{
			Roll roll;
			char auth[128];
			GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
			if (g_sCache.GetArray(auth, roll, sizeof(roll)))
			{
				int ref = EntIndexToEntRef(weapon);
				char key[12];
				IntToString(ref, key, sizeof(key));
				g_WeaponRolls.SetArray(key, roll, sizeof(roll));
				
				// Display the restored attributes
				if (roll.hasAttributes) {
					PrintToChat(client, roll.display);
				}
				
				// Apply all effects
				g_bUnrefillableActive[client] = roll.unrefillable;
				
				if (roll.recharge) {
					RechargeAmmo(client, weapon);
					SDKHook(weapon, SDKHook_ReloadPost, WeaponReload);
				}
				
				// Apply speed modifiers for active weapon
				if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == weapon) {
					ApplySpeedModifier(client, roll);
				}
			}
		}
	}
	g_bRestore[client] = false;
	return Plugin_Handled;
}


public void Event_EquipWeapon(int client, int weapon)
{
	if (weapon == -1) return;
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2) return;
	char steamid[32];
	bool authed = GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	if (g_bAmmoCheck)
	{
		g_bAmmoCheck = false;
		CreateTimer(0.1, Timer_Hook, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	char class[64];
	GetEntityClassname(weapon, class, sizeof(class));
	if (IsWeapon(class)) {
		int ref = EntIndexToEntRef(weapon);
		char key[12];
		IntToString(ref, key, sizeof(key));
		
		if (g_bRestore[client])
		{
			CreateTimer(1.0, Timer_Restore, client);
			return;
		}
		
		// Check for saved spawn roll
		if (g_LastSpawnUsed[client] != INVALID_ENT_REFERENCE) 
		{
			
			if (authed)
			{
				char spawnKey[64];
				Format(spawnKey, sizeof(spawnKey), "%d_%s", g_LastSpawnUsed[client], steamid);
				
				Roll savedRoll;
				if (g_WeaponSpawnRolls.GetArray(spawnKey, savedRoll, sizeof(savedRoll)))
				{
					// Apply saved roll to this weapon
					g_WeaponRolls.SetArray(key, savedRoll, sizeof(savedRoll));
					
					if (savedRoll.hasAttributes) {
						PrintToChat(client, savedRoll.display);
					}
					if (savedRoll.unrefillable && StrHasRoll(steamid, savedRoll))
					{
						char mapKey[64];
						if (StrGetKey(steamid, savedRoll, mapKey, sizeof(mapKey)))
						{
							Roll wepRoll;
							if (g_UnrefillableWeapon.GetArray(mapKey, wepRoll, sizeof(wepRoll)))
							{
								DataPack data = new DataPack();
								data.WriteCell(GetClientUserId(client));
								data.WriteCell(weapon);
								data.WriteCell(wepRoll.savedClip);
								data.WriteCell(wepRoll.savedReserve);
								CreateTimer(0.1, Timer_SetAmmo, data, TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						StrAddRoll(steamid, savedRoll);
					}
					
					// Clear spawn timer and reference
					if (g_hSpawnTimer[client] != null) {
						KillTimer(g_hSpawnTimer[client]);
						g_hSpawnTimer[client] = null;
					}
					g_LastSpawnUsed[client] = INVALID_ENT_REFERENCE;
					
					// Apply speed modifier for this weapon
					ApplySpeedModifier(client, savedRoll);
					return;
				}
			}
		}
		
		// No saved roll - generate new one
		if (!g_WeaponRolls.ContainsKey(key)) {
			RollAttributes(key, class, false, "");
		}
		
		Roll roll;
		if (g_WeaponRolls.GetArray(key, roll, sizeof(Roll))) {
			if (roll.hasAttributes) {
				PrintToChat(client, roll.display);
			}
			
			// Set unrefillable flag
			g_bUnrefillableActive[client] = roll.unrefillable;
			
			if (roll.unrefillable)
			{
				int ammo = GetEntProp(weapon, Prop_Data, "m_iClip1");
				int reserve = L4D_GetReserveAmmo(client, weapon);
				roll.savedClip = ammo;
				roll.savedReserve = reserve;
				StrAddRoll(steamid, roll);
				g_WeaponRolls.SetArray(key, roll, sizeof(roll));
			}
			
			if (roll.recharge)
			{
				RechargeAmmo(client, weapon);
				SDKHook(weapon, SDKHook_ReloadPost, WeaponReload);
			}
			
			// Apply speed modifier for this weapon
			ApplySpeedModifier(client, roll);
			
			// Save new roll to spawn if applicable
			if (g_LastSpawnUsed[client] != INVALID_ENT_REFERENCE) 
			{
				if (authed)
				{
					char spawnKey[64];
					Format(spawnKey, sizeof(spawnKey), "%d_%s", g_LastSpawnUsed[client], steamid);
					g_WeaponSpawnRolls.SetArray(spawnKey, roll, sizeof(roll));
				}
				
				// Clear spawn timer and reference
				if (g_hSpawnTimer[client] != null) {
					KillTimer(g_hSpawnTimer[client]);
					g_hSpawnTimer[client] = null;
				}
				g_LastSpawnUsed[client] = INVALID_ENT_REFERENCE;
			}
		}
	}
}

public Action Timer_SetAmmo(Handle timer, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int weapon = data.ReadCell();
	if (client != -1 && weapon != -1)
	{
		
		int clip = data.ReadCell();
		int reserve = data.ReadCell();
		SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
		SetEntProp(weapon, Prop_Data, "m_iClip1", clip);
		L4D_SetReserveAmmo(client, weapon, reserve);
	}
	delete(data);
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
		
	if (GetClientTeam(client) != 2)
		return Plugin_Continue;
	
	char steamid[32];
	bool authed = GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	if (buttons & IN_RELOAD)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (weapon == -1)
			return Plugin_Continue;
		
		int ref = EntIndexToEntRef(weapon);
		char key[12];
		IntToString(ref, key, sizeof(key));
		Roll roll;
		if (g_WeaponRolls.GetArray(key, roll, sizeof(roll)))
		{
			if (roll.unrefillable)
			{
				if (authed)
				{
					int ammo = GetEntProp(weapon, Prop_Data, "m_iClip1");
					int reserve = L4D_GetReserveAmmo(client, weapon);
					roll.savedClip = ammo;
					roll.savedReserve = reserve;
					StrAddRoll(steamid, roll);
					g_WeaponRolls.SetArray(key, roll, sizeof(roll));
				}
			}
			
			if (roll.recharge)
			{
				buttons &= ~IN_RELOAD;
				return Plugin_Changed;
			}
		}
	}	
	return Plugin_Continue;
}

public void WeaponReload(int weapon, bool successful)
{
	if (successful)
	{
		int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
		if (client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			if (g_hSpawnTimer[client] == null)
			{
				DataPack data = new DataPack();
				data.WriteCell(GetClientUserId(client));
				data.WriteCell(weapon);
				g_hSpawnTimer[client] = CreateTimer(0.1, Timer_Recharge, data, TIMER_REPEAT);
			}
		}
	}
}

public Action Timer_Recharge(Handle timer, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int weapon = data.ReadCell();
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{
		g_hSpawnTimer[client] = null;
		delete data;
		return Plugin_Stop;
	}
	if (weapon == -1 || !IsValidEntity(weapon))
	{
		g_hSpawnTimer[client] = null;
		delete data;
		return Plugin_Stop;
	}
	if (GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity") != client)
	{
		g_hSpawnTimer[client] = null;
		delete data;
		return Plugin_Stop;
	}
	int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	if (clip > 1)
	{
		RechargeAmmo(client, weapon);
		g_hSpawnTimer[client] = null;
		delete data;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void RechargeAmmo(int client, int weapon)
{
	int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	int reserve = L4D_GetReserveAmmo(client, weapon);
	if (clip > 1) {
		SetEntProp(weapon, Prop_Send, "m_iClip1", 1);
		SetEntProp(weapon, Prop_Data, "m_iClip1", 1);
		L4D_SetReserveAmmo(client, weapon, reserve + (clip - 1));
	}
}

public void Event_WeaponDrop(int client, int weapon)
{
	if (weapon == -1) return;
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2) return;
	
	char key[12];
	IntToString(EntIndexToEntRef(weapon), key, sizeof(key));
	
	Roll roll;
	if (g_WeaponRolls.GetArray(key, roll, sizeof(Roll))) {
		// Only reset if this weapon had a modifier
		if (roll.heavy || roll.light || roll.scout) {
			// Reset speed to default when dropping weapon
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
		
		if (roll.unrefillable)
		{
			char steamid[32];
			if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
			{
				int ammo = GetEntProp(weapon, Prop_Data, "m_iClip1");
				int reserve = L4D_GetReserveAmmo(client, weapon);
				roll.savedClip = ammo;
				roll.savedReserve = reserve;
				g_WeaponRolls.SetArray(key, roll, sizeof(roll));
				StrAddRoll(steamid, roll); // Update global storage
			}
		}
		
		// Clear unrefillable flag
		g_bUnrefillableActive[client] = false;
	}
}

void ApplySpeedModifier(int client, Roll roll)
{
	// Reset to base speed first
	float currentSpeed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
	if (currentSpeed != 1.0) {
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
	
	// Apply new modifier
	if (roll.heavy)
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0 * HEAVY_SLOWDOWN);
	else if (roll.light)
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0 * LIGHT_SPEEDBOOST);
	else if (roll.scout)
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0 * SCOUT_SPEEDBOOST);
}

bool IsWeapon(const char[] classname)
{
	for (int i = 0; i < sizeof(weps); i++)
		if (StrEqual(classname, weps[i])) return true;
	return false;
}

public void WH_OnGetRateOfFire(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return;
		
	int ref = EntIndexToEntRef(weapon);
	char key[12];
	IntToString(ref, key, sizeof(key));
	Roll roll;
	if (g_WeaponRolls.GetArray(key, roll, sizeof(roll)))
	{
		if (roll.fireRate != 1.0)
			speedmodifier = speedmodifier * roll.fireRate;
	}
}

public void WH_OnReloadModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return;
		
	int ref = EntIndexToEntRef(weapon);
	char key[12];
	IntToString(ref, key, sizeof(key));
	Roll roll;
	if (g_WeaponRolls.GetArray(key, roll, sizeof(roll)))
	{
		if (roll.reloadSpeed != 1.0)
			speedmodifier = speedmodifier * roll.reloadSpeed;
	}
}

bool CompareRolls(const Roll roll1, const Roll roll2)
{
	if (roll1.uid != roll2.uid) return false;
	if (roll1.damage != roll2.damage) return false;
	if (FloatAbs(roll1.multi - roll2.multi) > 0.001) return false;
	if (roll1.damageType != roll2.damageType) return false;
	if (FloatAbs(roll1.ammoChance - roll2.ammoChance) > 0.001) return false;
	if (roll1.hasAttributes != roll2.hasAttributes) return false;
	if (roll1.isGodRoll != roll2.isGodRoll) return false;
	if (roll1.effectiveChapter != roll2.effectiveChapter) return false;
	if (roll1.unrefillable != roll2.unrefillable) return false;
	if (roll1.heavy != roll2.heavy) return false;
	if (roll1.light != roll2.light) return false;
	if (roll1.scout != roll2.scout) return false;
	if (roll1.vampiric != roll2.vampiric) return false;
	if (roll1.heat != roll2.heat) return false;
	if (roll1.recharge != roll2.recharge) return false;
	if (roll1.isSetItem != roll2.isSetItem) return false;
	if (roll1.noBullet != roll2.noBullet) return false;
	if (FloatAbs(roll1.fireRate - roll2.fireRate) > 0.001) return false;
	if (FloatAbs(roll1.reloadSpeed - roll2.reloadSpeed) > 0.001) return false;
	if (FloatAbs(roll1.toxicMulti - roll2.toxicMulti) > 0.001) return false;
	if (roll1.scout != roll2.scout) return false;
	if (FloatAbs(roll1.toxicDmg - roll2.toxicDmg) > 0.001) return false;
	if (FloatAbs(roll1.heatDmg - roll2.heatDmg) > 0.001) return false;
	if (roll1.effect != roll2.effect) return false;
	
	return true;
}

void DefaultRoll(Roll roll)
{
	roll.effect = -1;
	roll.uid = 0;
	roll.damage = 0;
	roll.multi = 1.0;
	roll.damageType = DMG_BULLET;
	roll.ammoChance = 0.0;
	roll.hasAttributes = false;
	roll.isGodRoll = false;
	roll.unrefillable = false;
	roll.heavy = false;
	roll.light = false;
	roll.vampiric = false;
	roll.heat = false;
	roll.recharge = false;
	roll.isSetItem = false;
	roll.noBullet = false;
	roll.fireRate = 1.0;
	roll.reloadSpeed = 1.0;
	roll.scout = false;
	roll.savedClip = -1;
	roll.savedReserve = -1;
	roll.toxicMulti = 0.0;
	roll.toxicDmg = 0.0;
	roll.heatDmg = 0.0;
}

bool InClassSet(const char[] classname, int classbitflag)
{
	for (int i = 0; i < sizeof(weps); i++) {
		if (StrEqual(classname, weps[i], false)) {
			return (classbitflag & (1 << i)) != 0;
		}
	}
	return false;
}

void CreateSet(const char setname[256], int class, Roll roll, float chance)
{
	roll.isSetItem = true;
	roll.hasAttributes = true;
	Set set;
	set.cmd = setname;
	set.roll = roll;
	set.class = class;
	set.chance = chance;
	g_WeaponSets.SetArray(setname, set, sizeof(set));
}

void LoadSets()
{
	Roll roll;
	DefaultRoll(roll);
	roll.vampiric = true;
	roll.fireRate = 1.3;
	roll.reloadSpeed = 1.3;
	CreateSet("vampiric", CATEGORY_ALL, roll, 0.03);
	
	DefaultRoll(roll);
	roll.multi = 0.1;
	roll.damageType = DMG_BURN;
	roll.unrefillable = true;
	roll.ammoChance = 0.8;
	roll.noBullet = true;
	CreateSet("flamethrower", CLASS_RIFLE_M60, roll, 0.03);
	
	DefaultRoll(roll);
	roll.damage = -1;
	roll.multi = 5.0;
	roll.heavy = true;
	roll.ammoChance = 0.05;
	roll.unrefillable = true;
	CreateSet("awpdestruction", CLASS_SNIPER_AWP, roll, 0.01);
	
	DefaultRoll(roll);
	roll.damage = 25;
	roll.multi = 2.0;
	roll.damageType = DMG_BURN | DMG_ENERGYBEAM | DMG_RADIATION;
	roll.heat = true;
	roll.heatDmg = 15.0;
	roll.toxicMulti = 0.1;
	roll.recharge = true;
	CreateSet("laserrifle", CLASS_HUNTING_RIFLE, roll, 0.01);
	
	DefaultRoll(roll);
	roll.damage = 2;
	roll.multi = 0.3;
	roll.damageType = DMG_BUCKSHOT;
	roll.fireRate = 2.5;
	roll.reloadSpeed = 0.3;
	roll.ammoChance = 1.0;
	roll.heavy = true;
	CreateSet("minigun", CLASS_RIFLE_M60, roll, 0.02);
	
	DefaultRoll(roll);
	roll.damage = 2;
	roll.fireRate = 1.2;
	roll.reloadSpeed = 1.5;
	roll.ammoChance = 0.1;
	roll.light = true;
	CreateSet("specops", CLASS_RIFLE | CLASS_SNIPER_MILITARY | CLASS_AUTOSHOTGUN | CLASS_RIFLE_SG552 | CLASS_SMG_MP5 | CLASS_SNIPER_AWP | CLASS_RIFLE_DESERT, roll, 0.02);
	
	DefaultRoll(roll);
	roll.reloadSpeed = 0.9;
	roll.damageType = DMG_BLAST;
	roll.heat = true;
	int flag = CATEGORY_ALL;
	int banned = CLASS_GRENADE_LAUNCHER;
	flag &= ~banned;
	CreateSet("magnetized", flag, roll, 0.02);
	
	DefaultRoll(roll);
	roll.fireRate = 1.5;
	roll.damage = -5;
	roll.damageType = DMG_SONIC;
	flag = CATEGORY_RIFLE | CATEGORY_SMG;
	banned = CLASS_RIFLE_M60;
	flag &= ~banned;
	CreateSet("supersonic", flag, roll, 0.02);
	
	DefaultRoll(roll);
	roll.multi = 1.3;
	roll.heat = true;
	roll.heavy = true;
	CreateSet("riot", CLASS_AUTOSHOTGUN | CLASS_SHOTGUN_SPAS, roll, 0.02);
	
	DefaultRoll(roll);
	roll.fireRate = 1.5;
	roll.reloadSpeed = 1.3;
	roll.scout = true;
	CreateSet("scout", CATEGORY_SHOTGUN, roll, 0.02);
	
	DefaultRoll(roll);
	roll.damageType = DMG_BLAST | DMG_BURN;
	roll.multi = 1.5;
	roll.heat = true;
	roll.unrefillable = true;
	roll.ammoChance = 0.5;
	CreateSet("nick", CLASS_SHOTGUN_CHROME | CLASS_PUMPSHOTGUN, roll, 0.01);
	
	DefaultRoll(roll);
	roll.damageType = DMG_RADIATION | DMG_BUCKSHOT;
	roll.fireRate = 0.8;
	roll.ammoChance = 0.1;
	roll.reloadSpeed = 1.2;
	roll.multi = 0.8;
	roll.damage = -20;
	flag = CATEGORY_ALL;
	banned = CLASS_GRENADE_LAUNCHER;
	flag &= ~banned;
	CreateSet("toxic", flag, roll, 0.02);
	
	DefaultRoll(roll);
	roll.damageType = DMG_RADIATION | DMG_BURN | DMG_BLAST;
	roll.reloadSpeed = 0.5;
	roll.multi = 0.0;
	roll.toxicDmg = 75.0;
	roll.recharge = true;
	roll.heat = true;
	roll.heatDmg = 100.0;
	roll.unrefillable = true;
	CreateSet("infernal", CLASS_SMG, roll, 0.02);
	
	DefaultRoll(roll);
	roll.damage = 25;
	roll.multi = 2.5;
	roll.unrefillable = true;
	CreateSet("chinese", CLASS_SNIPER_AWP, roll, 0.02);
	
	DefaultRoll(roll);
	roll.effect = EFFECT_GLITCH;
	CreateSet("glitched", CATEGORY_ALL, roll, 0.005);
}

bool TrySetRoll(const char[] classname, Roll roll, bool isGodRoll)
{
	StringMapSnapshot snap = g_WeaponSets.Snapshot();
	int setCount = snap.Length;
	for (int i = 0; i < setCount; i++)
	{
		float bonus = isGodRoll ? SET_BONUSCHANCE : 0.0;
		char setName[256];
		snap.GetKey(i, setName, sizeof(setName));
		Set set;
		if (g_WeaponSets.GetArray(setName, set, sizeof(set)))
		{
			if (InClassSet(classname, set.class))
			{
				if (GetRandomFloat() <= set.chance + bonus)
				{
					Roll modified;
					modified = set.roll;
					ModifyRoll(set.cmd, classname, modified);
					roll = modified;
					delete snap;
					return true;
				}
			}
		}
	}
	delete snap;
	return false;
}

void ModifyRoll(const char[] name, const char[] class, Roll roll)
{
	if (roll.unrefillable)
		roll.uid = g_iWeaponUID++;
	if (StrEqual(name, "vampiric"))
	{
		roll.damage = GetRandomInt(-3, -1);
		if (InClassSet(class, CATEGORY_SHOTGUN))
			roll.multi = GetRandomFloat(0.4, 0.6);
		else
			roll.multi = GetRandomFloat(0.7, 0.8);
		
		GenerateDisplay(class, roll, false, "Vampiric %s");
		return;
	}
	if (StrEqual(name, "awpdestruction"))
	{
		GenerateDisplay(class, roll, false, "Awp Of Destruction", true);
		return;
	}
	if (StrEqual(name, "laserrifle"))
	{
		GenerateDisplay(class, roll, false, "Laser Rifle Of The Cosmos", true);
		return;
	}
	if (StrEqual(name, "flamethrower"))
	{
		GenerateDisplay(class, roll, false, "Flamethrower", true, true, "There's no escaping from the inferno");
		return;
	}
	if (StrEqual(name, "minigun"))
	{
		GenerateDisplay(class, roll, false, "$400 000", true, true, "I think I'll take Sasha");
		return;
	}
	if (StrEqual(name, "specops"))
	{
		GenerateDisplay(class, roll, false, "Special Operations %s");
		return;
	}
	if (StrEqual(name, "magnetized"))
	{
		if (InClassSet(class, CATEGORY_SHOTGUN))
			roll.fireRate = 0.4;
			
		if (InClassSet(class, CATEGORY_RIFLE))
			roll.fireRate = 0.6;
			
		if (InClassSet(class, CATEGORY_SNIPER))
			roll.fireRate = 0.7;
			
		if (InClassSet(class, CATEGORY_SMG))
			roll.fireRate = 0.5;
			
		if (InClassSet(class, CLASS_PUMPSHOTGUN | CLASS_SHOTGUN_CHROME))
			roll.fireRate = 0.6;
		
		roll.damage = GetRandomInt(1, 5);
		GenerateDisplay(class, roll, false, "Magnetized %s");
		return;
	}
	if (StrEqual(name, "supersonic"))
	{
		GenerateDisplay(class, roll, false, "SuperSonic %s");
		return;
	}
	if (StrEqual(name, "riot"))
	{
		GenerateDisplay(class, roll, false, "Riot %s");
		return;
	}
	if (StrEqual(name, "scout"))
	{
		GenerateDisplay(class, roll, false, "Scout!", true, true, "No smoking!");
		return;
	}
	if (StrEqual(name, "nick"))
	{
		GenerateDisplay(class, roll, false, "Nick's Shotgun", true, true, "Shotgun, you complete me.");
		return;
	}
	if (StrEqual(name, "toxic"))
	{
		if (InClassSet(class, CATEGORY_SNIPER))
			roll.toxicMulti = 0.2;
			
		if (InClassSet(class, CATEGORY_SMG))
			roll.toxicMulti = 0.6;
			
		if (InClassSet(class, CATEGORY_SHOTGUN))
			roll.toxicMulti = 1.5;
			
		if (InClassSet(class, CATEGORY_RIFLE))
			roll.toxicMulti = 0.3;
			
		if (InClassSet(class, CLASS_SNIPER_AWP | CLASS_SNIPER_SCOUT))
			roll.toxicMulti = 0.05;
			
		GenerateDisplay(class, roll, false, "Toxic %s", false, true, "There are no accidents.");
		return;
	}
	if (StrEqual(name, "infernal"))
	{
		GenerateDisplay(class, roll, false, "Infernal Dissolver", true);
		return;
	}
	if (StrEqual(name, "chinese"))
	{
		GenerateDisplay(class, roll, false, "Lacky", true, true, "Did you get the money.");
		return;
	}
	if (StrEqual(name, "glitched"))
	{
		GenerateDisplay(class, roll, false, "Gl1tch3d %s", false, true, "Error, please contact the developer.");
		return;
	}
}

void GenerateDisplay(const char[] class, Roll roll, bool defaultGeneration = true, const char[] nameFormat = "",
					 bool overrideName = false, bool overrideAtts = false, const char[] atts = "")
{
	char colorCode[8] = "\x01";
	if (roll.isSetItem) {
		colorCode = "\x04";
	} else if (roll.isGodRoll) {
		colorCode = "\x05";
	} else if (roll.damage < 0 || roll.multi < 0.9) {
		colorCode = "\x02";
	} else if (roll.damage > (roll.effectiveChapter * 2) || roll.multi > 1.2) {
		colorCode = "\x03";
	}
	
	char fullName[128];
	char baseName[64];
	if (defaultGeneration) {
		char adj[32];
		char suffix[32];
		if (roll.isSetItem || roll.isGodRoll) {
			strcopy(adj, sizeof(adj), godly_adjectives[GetRandomInt(0, sizeof(godly_adjectives) - 1)]);
			strcopy(suffix, sizeof(suffix), godly_suffixes[GetRandomInt(0, sizeof(godly_suffixes) - 1)]);
		} else if (roll.damage < 0 || roll.multi < 0.9) {
			strcopy(adj, sizeof(adj), negative_adjectives[GetRandomInt(0, sizeof(negative_adjectives) - 1)]);
			strcopy(suffix, sizeof(suffix), negative_suffixes[GetRandomInt(0, sizeof(negative_suffixes) - 1)]);
		} else if (roll.damage > (roll.effectiveChapter * 2) || roll.multi > 1.2) {
			strcopy(adj, sizeof(adj), positive_adjectives[GetRandomInt(0, sizeof(positive_adjectives) - 1)]);
			strcopy(suffix, sizeof(suffix), positive_suffixes[GetRandomInt(0, sizeof(positive_suffixes) - 1)]);
		} else {
			strcopy(adj, sizeof(adj), neutral_adjectives[GetRandomInt(0, sizeof(neutral_adjectives) - 1)]);
			strcopy(suffix, sizeof(suffix), neutral_suffixes[GetRandomInt(0, sizeof(neutral_suffixes) - 1)]);
		}
		GetWeaponBaseName(class, baseName, sizeof(baseName));
		if (GetRandomFloat() < 0.75) {
			Format(fullName, sizeof(fullName), "%s %s %s", adj, baseName, suffix);
		} else {
			Format(fullName, sizeof(fullName), "%s %s", adj, baseName);
		}
	}
	else {
		if (overrideName) {
			strcopy(fullName, sizeof(fullName), nameFormat);
		} else if (nameFormat[0] != '\0') {
			GetWeaponBaseName(class, baseName, sizeof(baseName));
			Format(fullName, sizeof(fullName), nameFormat, baseName);
		} else {
			GetWeaponBaseName(class, fullName, sizeof(fullName));
		}
	}
	char attrBuffer[256];
	if (overrideAtts) {
		Format(attrBuffer, sizeof(attrBuffer), "\n", attrBuffer);
		Format(attrBuffer, sizeof(attrBuffer), "%s%s",attrBuffer, atts);
	} else {
		Format(attrBuffer, sizeof(attrBuffer), "");
		if (roll.damage != 0) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nDamage: %s%d", attrBuffer, roll.damage > 0 ? "+" : "", roll.damage);
		}
		if (FloatAbs(roll.multi - 1.0) >= MIN_DISPLAY_MULTI) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nDamage Multiplier: x%.2f", attrBuffer, roll.multi);
		}
		if (roll.damageType != DMG_BULLET) {
			int dmgBits = roll.damageType;
			char dmgTypeList[256];
			dmgTypeList[0] = '\0';
			static const int knownTypes[] = {
				DMG_BURN,
				DMG_BUCKSHOT,
				DMG_BLAST,
				DMG_SONIC,
				DMG_RADIATION,
				DMG_ENERGYBEAM,
			};
			static const char knownNames[][] = {
				"Fire",
				"Buckshot",
				"Blast",
				"SuperSonic",
				"Radiation",
				"Energy",
			};
			int count = 0;
			for (int i = 0; i < sizeof(knownTypes); i++) {
				if (dmgBits & knownTypes[i]) {
					if (count++ > 0) {
						StrCat(dmgTypeList, sizeof(dmgTypeList), ", ");
					}
					StrCat(dmgTypeList, sizeof(dmgTypeList), knownNames[i]);
				}
			}
			if (count == 0) {
				StrCat(dmgTypeList, sizeof(dmgTypeList), "Unknown");
			}
			Format(attrBuffer, sizeof(attrBuffer), "%s\nDamage Type: %s", attrBuffer, dmgTypeList);
		}
		if (roll.ammoChance >= MIN_DISPLAY_AMMO) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nAmmo Return Chance: %.0f%%", attrBuffer, roll.ammoChance * 100);
		}
		if (roll.fireRate != 1.0) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nFire Rate: x%.2f", attrBuffer, roll.fireRate);
		}
		if (roll.reloadSpeed != 1.0) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nReload Speed: x%.2f", attrBuffer, roll.reloadSpeed);
		}
		if (roll.unrefillable) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nUnrefillable: No ammo pickups", attrBuffer);
		}
		if (roll.heavy) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nHeavy: 25%% slower", attrBuffer);
		}
		else if (roll.light) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nLight: 10%% faster", attrBuffer);
		}
		if (roll.vampiric) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nVampiric", attrBuffer);
		}
		if (roll.heat) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nHeat", attrBuffer);
		}
		if (roll.recharge) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nRecharge", attrBuffer);
		}
		if (roll.toxicMulti != 0.0) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nToxic Multi: %.2f", attrBuffer, roll.toxicMulti);
		}
		if (roll.toxicDmg != 0.0) {
			Format(attrBuffer, sizeof(attrBuffer), "%s\nToxic Damage: %.2f", attrBuffer, roll.toxicDmg);
		}
	}
	Format(roll.display, sizeof(roll.display), "%s%s\x01\n \nAttributes:%s", colorCode, fullName, attrBuffer);
}

void GetWeaponBaseName(const char[] classname, char[] buffer, int maxlength)
{
	if (StrEqual(classname, "weapon_smg"))
		strcopy(buffer, maxlength, "Tactical SMG");
	else if (StrEqual(classname, "weapon_smg_silenced"))
		strcopy(buffer, maxlength, "Silenced SMG");
	else if (StrEqual(classname, "weapon_smg_mp5"))
		strcopy(buffer, maxlength, "MP5");
	else if (StrEqual(classname, "weapon_pumpshotgun"))
		strcopy(buffer, maxlength, "Pump Shotgun");
	else if (StrEqual(classname, "weapon_shotgun_chrome"))
		strcopy(buffer, maxlength, "Chrome Shotgun");
	else if (StrEqual(classname, "weapon_autoshotgun"))
		strcopy(buffer, maxlength, "Auto Shotgun");
	else if (StrEqual(classname, "weapon_shotgun_spas"))
		strcopy(buffer, maxlength, "SPAS Shotgun");
	else if (StrEqual(classname, "weapon_rifle"))
		strcopy(buffer, maxlength, "Assault Rifle");
	else if (StrEqual(classname, "weapon_rifle_ak47"))
		strcopy(buffer, maxlength, "AK-47");
	else if (StrEqual(classname, "weapon_rifle_desert"))
		strcopy(buffer, maxlength, "Desert Rifle");
	else if (StrEqual(classname, "weapon_rifle_sg552"))
		strcopy(buffer, maxlength, "SG552");
	else if (StrEqual(classname, "weapon_hunting_rifle"))
		strcopy(buffer, maxlength, "Hunting Rifle");
	else if (StrEqual(classname, "weapon_sniper_military"))
		strcopy(buffer, maxlength, "Military Sniper");
	else if (StrEqual(classname, "weapon_sniper_awp"))
		strcopy(buffer, maxlength, "AWP");
	else if (StrEqual(classname, "weapon_sniper_scout"))
		strcopy(buffer, maxlength, "Scout");
	else if (StrEqual(classname, "weapon_grenade_launcher"))
		strcopy(buffer, maxlength, "Grenade Launcher");
	else if (StrEqual(classname, "weapon_rifle_m60"))
		strcopy(buffer, maxlength, "M60");
	else
	{
		char temp[64];
		strcopy(temp, sizeof(temp), classname);
		ReplaceString(temp, sizeof(temp), "weapon_", "");
		ReplaceString(temp, sizeof(temp), "_", " ");
		String_ToTitle(temp, sizeof(temp));
		strcopy(buffer, maxlength, temp);
	}
}

void String_ToTitle(char[] str, int maxlength)
{
	bool newWord = true;
	int len = strlen(str);
	
	for (int i = 0; i < len && i < maxlength; i++)
	{
		if (newWord)
		{
			str[i] = CharToUpper(str[i]);
			newWord = false;
		}
		else
		{
			str[i] = CharToLower(str[i]);
		}
		
		if (str[i] == ' ' || str[i] == '_' || str[i] == '-')
			newWord = true;
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		char classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if (IsWeapon(classname))
		{
			char key[12];
			IntToString(EntIndexToEntRef(entity), key, sizeof(key));
			g_WeaponRolls.Remove(key);
		}
		else if (StrContains(classname, "weapon_") == 0)
		{
			// Clean up spawn rolls when spawn entity is removed
			int ref = EntIndexToEntRef(entity);
			char searchKey[32];
			Format(searchKey, sizeof(searchKey), "%d_", ref);
			
			StringMapSnapshot snap = g_WeaponSpawnRolls.Snapshot();
			char key[64];
			for (int i = 0; i < snap.Length; i++) {
				snap.GetKey(i, key, sizeof(key));
				if (StrContains(key, searchKey) == 0) {
					g_WeaponSpawnRolls.Remove(key);
				}
			}
			delete snap;
		}
	}
}

void ListSets(char setList[512])
{
	Format(setList, sizeof(setList), "Available sets: ");
	StringMapSnapshot snap = g_WeaponSets.Snapshot();
	for (int i = 0; i < snap.Length; i++) {
		char setName[256];
		snap.GetKey(i, setName, sizeof(setName));
		Set set;
		g_WeaponSets.GetArray(setName, set, sizeof(set));
		if (i > 0) StrCat(setList, sizeof(setList), ", ");
		StrCat(setList, sizeof(setList), set.cmd);
	}
	delete snap;
}

public Action Command_GiveSet(int client, int args)
{
	if (args < 1) {
		char setList[512];
		ListSets(setList);
		ReplyToCommand(client, setList);
		return Plugin_Handled;
	}
	char setname[32];
	GetCmdArg(1, setname, sizeof(setname));
	Set set;
	if (!g_WeaponSets.GetArray(setname, set, sizeof(set)))
	{
		char setList[512];
		ListSets(setList);
		ReplyToCommand(client, setList);
		return Plugin_Handled;
	}
	ArrayList validWeps = new ArrayList(ByteCountToCells(64));
	for (int i = 0; i < sizeof(weps); i++) {
		if (InClassSet(weps[i], set.class)) {
			validWeps.PushString(weps[i]);
		}
	}
	if (validWeps.Length == 0) {
		ReplyToCommand(client, "No valid weapons found for this set");
		delete validWeps;
		return Plugin_Handled;
	}
	char classname[64];
	validWeps.GetString(GetRandomInt(0, validWeps.Length - 1), classname, sizeof(classname));
	delete validWeps;
	GiveSetWeapon(client, classname, true, set.cmd);
	return Plugin_Handled;
}

void GiveSetWeapon(int client, const char[] classname, bool forceSet, const char[] setname)
{
	int oldWeapon = GetPlayerWeaponSlot(client, 0);
	if (oldWeapon != -1) {
		RemovePlayerItem(client, oldWeapon);
		RemoveEntity(oldWeapon);
	}
	int weapon = GivePlayerItem(client, classname);
	EquipPlayerWeapon(client, weapon);
	int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammoType != -1) {
		int maxAmmo = GetDefaultMaxAmmo(weapon);
		SetEntProp(client, Prop_Send, "m_iAmmo", maxAmmo, _, ammoType);
	}
	char key[12];
	IntToString(EntIndexToEntRef(weapon), key, sizeof(key));
	
	RollAttributes(key, classname, forceSet, setname, client);
	
	Roll roll;
	if (g_WeaponRolls.GetArray(key, roll, sizeof(Roll))) {
		if (StrEqual(classname, "weapon_sniper_awp") && roll.multi == 5.0) {
			if (ammoType != -1) {
				SetEntProp(client, Prop_Send, "m_iAmmo", 50, _, ammoType);
			}
		}
		if (roll.recharge)
		{
			RechargeAmmo(client, weapon);
			SDKHook(weapon, SDKHook_ReloadPost, WeaponReload);
		}
		// Apply speed modifier for this weapon
		ApplySpeedModifier(client, roll);
	}
}

int GetDefaultMaxAmmo(int weapon)
{
	char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	
	if (StrEqual(classname, "weapon_rifle") || StrEqual(classname, "weapon_rifle_desert") || 
		StrEqual(classname, "weapon_rifle_ak47") || StrEqual(classname, "weapon_rifle_sg552")) {
		return 360;
	}
	else if (StrEqual(classname, "weapon_smg") || StrEqual(classname, "weapon_smg_silenced") || 
			 StrEqual(classname, "weapon_smg_mp5")) {
		return 650;
	}
	else if (StrEqual(classname, "weapon_pumpshotgun") || StrEqual(classname, "weapon_shotgun_chrome") || 
			 StrEqual(classname, "weapon_autoshotgun") || StrEqual(classname, "weapon_shotgun_spas")) {
		return 64;
	}
	else if (StrEqual(classname, "weapon_hunting_rifle")) {
		return 150;
	}
	else if (StrEqual(classname, "weapon_sniper_military") || StrEqual(classname, "weapon_sniper_scout") || 
			 StrEqual(classname, "weapon_sniper_awp")) {
		return 180;
	}
	else if (StrEqual(classname, "weapon_grenade_launcher")) {
		return 30;
	}
	else if (StrEqual(classname, "weapon_rifle_m60")) {
		return 150;
	}
	
	return 0;
}

any Clamp(any val, any min = -999999999999, any max = 999999999999)
{
	if (val < min)
		return min;
	if (val > max)
		return max;
	return val;
}

void RollAttributes(const char[] key, const char[] classname, bool forceSet, const char[] setname, int client = -1)
{
	Roll roll;
	DefaultRoll(roll);
	
	if (forceSet) {
		Set set;
		if (g_WeaponSets.GetArray(setname, set, sizeof(set))) {
			Roll modified;
			modified = set.roll;
			ModifyRoll(set.cmd, classname, modified);
			roll = modified;
		}
		if (client != -1)
			PrintToChat(client, "%s", roll.display);
		g_WeaponRolls.SetArray(key, roll, sizeof(roll));
		return;
	}
	
	// Normal attribute rolling
	int currentChapter = L4D_GetCurrentChapter();
	int gamemode = L4D_GetGameModeType();
	float mode_multi = 1.0;
	switch(gamemode)
	{
		case GAMEMODE_SURVIVAL:
		{
			mode_multi = SURVIVAL_MULTI;
			currentChapter = 1;
		}
		case GAMEMODE_VERSUS: mode_multi = VERSUS_MULTI;
		case GAMEMODE_SCAVENGE:
		{
			mode_multi = SCAVENGE_MULTI;
			currentChapter = 1;
		}
		default: mode_multi = 1.0;
	}
	
	mode_multi = GetRandomFloat(1.0, mode_multi);
	
	// Determine effective chapter
	int rnd_multi = RoundFloat(mode_multi);
	roll.effectiveChapter = currentChapter * rnd_multi;
	if (GetRandomFloat() < CHAPTER_DOWNGRADE_CHANCE && currentChapter > 1) {
		roll.effectiveChapter = GetRandomInt(1, currentChapter - 1);
	}
	
	// First roll: chance for any attributes
	if (GetRandomFloat() > (OVERALL_ATTRIBUTE_CHANCE + (roll.effectiveChapter - 1) * CHAPTER_CHANCE_BONUS)) {
		g_WeaponRolls.SetArray(key, roll, sizeof(Roll));
		return;
	}
	
	// If no set item, proceed with normal attribute rolling
	roll.isGodRoll = (GetRandomFloat() < GOD_ROLL_CHANCE * GetRandomFloat(1.0, Clamp(mode_multi/2, 1.0)));
	
	// If we passed the attribute chance, now try for set items
	if (TrySetRoll(classname, roll, roll.isGodRoll)) {
		roll.hasAttributes = true;
		roll.isSetItem = true;
		g_WeaponRolls.SetArray(key, roll, sizeof(Roll));
		return;
	}
	
	// Roll attributes
	int attributesRolled = 0;
	
	// 1. Flat Damage (non-linear scaling)
	if (GetRandomFloat() < 0.7) {
		float power = 1.0 + (roll.effectiveChapter * 0.15);
		int maxDmg = RoundFloat(Pow(float(BASE_DMG * roll.effectiveChapter), power));
		
		if (roll.isGodRoll) {
			roll.damage = GetRandomInt(maxDmg, maxDmg * 3);
		}
		else {
			roll.damage = GetRandomInt(-maxDmg/2, maxDmg);
		}
		attributesRolled++;
	}
	
	// 2. Damage Multiplier (non-linear scaling)
	if (GetRandomFloat() < 0.5) {
		float minMulti = 1.0 - (0.15 / Pow(1.3, float(roll.effectiveChapter) - 1));
		float maxMulti = 1.0 + (0.25 * Pow(1.5, float(roll.effectiveChapter) - 1));
		
		roll.multi = GetRandomFloat(minMulti, maxMulti);
		
		if (roll.isGodRoll) {
			if (roll.multi < 1.0) {
				roll.multi = 1.0 + (1.0 - roll.multi);
			}
			roll.multi = GetRandomFloat(roll.multi, maxMulti * 1.8);
		}
		attributesRolled++;
	}
	
	// 3. Damage Type
	if (GetRandomFloat() < (0.1 + 0.05 * float(roll.effectiveChapter))) {
		int dType = GetRandomInt(7, 10);
		switch(dType) {
			case 7: roll.damageType = DMG_RADIATION;
			case 8: roll.damageType = DMG_BURN;
			case 9: roll.damageType = DMG_BUCKSHOT;
			case 10: roll.damageType = DMG_BLAST;
		}
		attributesRolled++;
	}
	
	// 4. Ammo Chance
	if (GetRandomFloat() < 0.4) {
		float maxAmmo = BASE_AMMO_CHANCE * Pow(1.35, float(roll.effectiveChapter) - 1);
		if (maxAmmo > MAX_AMMO_CHANCE) maxAmmo = MAX_AMMO_CHANCE;
		
		roll.ammoChance = GetRandomFloat(-maxAmmo, maxAmmo);
		
		if (roll.isGodRoll) {
			roll.ammoChance = FloatAbs(roll.ammoChance);
			roll.ammoChance = GetRandomFloat(roll.ammoChance, MAX_AMMO_CHANCE);
		}
		else if (roll.ammoChance < 0.0) {
			roll.ammoChance = 0.0;
		}
		attributesRolled++;
	}
	
	// Add Heavy/Light attributes (mutually exclusive)
	if (GetRandomFloat() < 0.1) {
		if (GetRandomFloat() < 0.5) {
			roll.heavy = true;
		} else {
			roll.light = true;
		}
	}
	
	// Fire Rate Attribute Roll
	if (GetRandomFloat() < 0.2) {  // 20% base chance to get fire rate attribute
		float positiveChance = 0.6 + (0.05 * float(roll.effectiveChapter)); // Base 60% + 5% per chapter
		positiveChance = Clamp(positiveChance, 0.6, 0.85); // Cap between 60-85%
		
		if (GetRandomFloat() < positiveChance) {
			// Positive roll (faster firing)
			float minRate = 1.0 + (0.05 * float(roll.effectiveChapter)); 
			float maxRate = 1.0 + (0.15 * float(roll.effectiveChapter)); 
			roll.fireRate = GetRandomFloat(minRate, maxRate);
		} else {
			// Negative roll (slower firing)
			float severity = 1.0 / float(roll.effectiveChapter); // Less severe in later chapters
			float minRate = 1.0 - (0.10 * severity); 
			float maxRate = 1.0 - (0.03 * severity);
			roll.fireRate = GetRandomFloat(minRate, maxRate);
		}
		
		// Apply god roll bonus
		if (roll.isGodRoll) {
			if (roll.fireRate < 1.0) {
				// Convert negative to strong positive
				roll.fireRate = GetRandomFloat(1.5, MAX_FIRERATE);
			} else {
				// Boost existing positive
				roll.fireRate = GetRandomFloat(roll.fireRate, MAX_FIRERATE);
			}
		}
		
		// Final clamping
		roll.fireRate = Clamp(roll.fireRate, MIN_FIRERATE, MAX_FIRERATE);
	}
	
	if (GetRandomFloat() < 0.2) {  // 20% base chance to get reload speed attribute
		float positiveChance = 0.6 + (0.05 * float(roll.effectiveChapter)); // Base 60% + 5% per chapter
		positiveChance = Clamp(positiveChance, 0.6, 0.85); // Cap between 60-85%
		
		if (GetRandomFloat() < positiveChance) {
			float minRate = 1.0 + (0.05 * float(roll.effectiveChapter)); 
			float maxRate = 1.0 + (0.15 * float(roll.effectiveChapter)); 
			roll.reloadSpeed = GetRandomFloat(minRate, maxRate);
		} else {
			float severity = 1.0 / float(roll.effectiveChapter); // Less severe in later chapters
			float minRate = 1.0 - (0.10 * severity); 
			float maxRate = 1.0 - (0.03 * severity);
			roll.reloadSpeed = GetRandomFloat(minRate, maxRate);
		}
		
		// Apply god roll bonus
		if (roll.isGodRoll) {
			if (roll.reloadSpeed < 1.0) {
				roll.reloadSpeed = GetRandomFloat(1.3, MAX_RELOADSPEED);
			} else {
				// Boost existing positive
				roll.reloadSpeed = GetRandomFloat(roll.reloadSpeed, MAX_RELOADSPEED);
			}
		}
		
		// Final clamping
		roll.reloadSpeed = Clamp(roll.reloadSpeed, MIN_RELOADSPEED, MAX_RELOADSPEED);
	}
	
	// Add Unrefillable attribute
	float unrefillableChance = 0.05;
	
	// Damage-based chance
	if (roll.damage > 20) {
		unrefillableChance = 0.15 + (0.10 * (roll.damage - 20) / 20);
	}
	
	// Multiplier-based chance
	if (roll.multi > 1.5) {
		float bonus = (roll.multi - 1.5) / 0.2 * 0.05;
		if (bonus > unrefillableChance) unrefillableChance = bonus;
	}
	
	if (GetRandomFloat() < unrefillableChance) {
		roll.unrefillable = true;
	}
	
	// Set Unrefillable for Blast damage type
	if (roll.damageType == DMG_BLAST) {
		roll.unrefillable = true;
	}
	
	if (roll.damageType == DMG_RADIATION)
		roll.toxicMulti = GetRandomFloat(0.12, 0.23);
		
	if (GetRandomFloat() <= 0.05 && roll.damageType == DMG_RADIATION)
		roll.toxicDmg = GetRandomFloat(1.0, 10.0);
	
	// Check if we have any significant attributes
	bool hasSignificantAttributes = false;
	
	if (roll.damage != 0) hasSignificantAttributes = true;
	if (FloatAbs(roll.multi - 1.0) >= MIN_DISPLAY_MULTI) hasSignificantAttributes = true;
	if (roll.damageType != DMG_BULLET) hasSignificantAttributes = true;
	if (roll.ammoChance >= MIN_DISPLAY_AMMO) hasSignificantAttributes = true;
	if (roll.unrefillable) hasSignificantAttributes = true;
	if (roll.heavy || roll.light || roll.scout) hasSignificantAttributes = true;
	if (roll.heat) hasSignificantAttributes = true;
	if (roll.recharge) hasSignificantAttributes = true;
	if (roll.fireRate != 1.0) hasSignificantAttributes = true;
	if (roll.reloadSpeed != 1.0) hasSignificantAttributes = true;
	if (roll.toxicMulti != 0.0) hasSignificantAttributes = true;
	if (roll.toxicDmg != 0.0) hasSignificantAttributes = true;
	if (roll.heatDmg != 0.0) hasSignificantAttributes = true;
	if (roll.effect != -1) hasSignificantAttributes = true;
	
	// If no significant attributes, treat as normal weapon
	if (!hasSignificantAttributes) {
		g_WeaponRolls.SetArray(key, roll, sizeof(Roll));
		return;
	}
	
	if (roll.unrefillable && roll.uid == 0)
	{
		roll.uid = g_iWeaponUID++;
	}
	
	roll.hasAttributes = true;
	GenerateDisplay(classname, roll, true);
	g_WeaponRolls.SetArray(key, roll, sizeof(Roll));
}

bool StrHasRoll(const char[] steamid, const Roll roll)
{
	if (roll.uid == 0) return false;
	char key[64];
	Format(key, sizeof(key), "%s_%d", steamid, roll.uid);
	return g_UnrefillableWeapon.ContainsKey(key);
}

void StrClear(const char[] steamid)
{
	int len = strlen(steamid);
	StringMapSnapshot snap = g_UnrefillableWeapon.Snapshot();
	for (int i = 0; i < snap.Length; i++) {
		int keySize = snap.KeyBufferSize(i);
		char[] keyBuffer = new char[keySize];
		snap.GetKey(i, keyBuffer, keySize);
		if (strncmp(keyBuffer, steamid, len) == 0 && keyBuffer[len] == '_') {
			g_UnrefillableWeapon.Remove(keyBuffer);
		}
	}
	delete snap;
}

bool StrGetKey(const char[] steamid, const Roll roll, char[] buffer, int maxlen)
{
	if (roll.uid == 0) return false;
	Format(buffer, maxlen, "%s_%d", steamid, roll.uid);
	return g_UnrefillableWeapon.ContainsKey(buffer);
}

void StrAddRoll(const char[] steamid, const Roll roll)
{
	if (roll.uid == 0) return;
	char key[64];
	Format(key, sizeof(key), "%s_%d", steamid, roll.uid);
	if (g_UnrefillableWeapon.ContainsKey(key)) {
		g_UnrefillableWeapon.Remove(key);
	}
	g_UnrefillableWeapon.SetArray(key, roll, sizeof(roll));
}