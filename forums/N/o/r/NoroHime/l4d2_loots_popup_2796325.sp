#define PLUGIN_VERSION		"1.1"
#define PLUGIN_PREFIX		"l4d2_"
#define PLUGIN_NAME			"loots_popup"
#define PLUGIN_NAME_FULL	"[L4D2] Loots Popup"
#define PLUGIN_DESCRIPTION	"another loot system with popup animation"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=341113"

/*
 *	v1.0 (1-January-2023)
 *		- just released
 *	v1.0.1 (11-April-2023)
 *		- fix *_loot_extra not work when too many items specified
 *	v1.1 (17-April-2023)
 *		- add plugin 'clear_weapon_drop' support, require latest version (https://github.com/fbef0102/L4D1_2-Plugins/tree/master/clear_weapon_drop)
 *		- fix *_ammo_max not work properly
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsAliveHumanSurvivor(%1) ( IsClient(%1) && !IsFakeClient(%1) && GetClientTeam(%1) == 2 && IsPlayerAlive(%1) )

bool bIsClearWeaponDropExists;
native int Timer_Delete_Weapon(int entity);

enum L4D2IntWeaponAttributes
{
	L4D2IWA_Damage,
	L4D2IWA_Bullets,
	L4D2IWA_ClipSize,
	L4D2IWA_Bucket,
	L4D2IWA_Tier, // L4D2 only
	MAX_SIZE_L4D2IntWeaponAttributes
};

enum L4D2GlowType
{
	L4D2Glow_None					= 0,
	L4D2Glow_OnUse					= 1,
	L4D2Glow_OnLookAt				= 2,
	L4D2Glow_Constant				= 3
}

native int L4D2_GetIntWeaponAttribute(const char[] weaponName, L4D2IntWeaponAttributes attr);

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

bool bLateLoad;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;

	MarkNativeAsOptional("L4D2_GetIntWeaponAttribute");
	MarkNativeAsOptional("Timer_Delete_Weapon");

	return APLRes_Success;
}

public void OnAllPluginsLoaded() {
	// Require Left4DHooks
	if( LibraryExists("left4dhooks") == false ) {
		LogMessage	("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
		SetFailState("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
	}
	bIsClearWeaponDropExists = FindConVar("sm_drop_clear_survivor_weapon_time") != null;
}

Handle sdkCreateGift, sdkUseAmmo;

#define MODEL_AMMOPILE		"models/props/terror/ammo_stack.mdl"
#define SOUND_REWARD		"ui/bigreward.wav"

static const char CLASSES_WEAPON[][] = {
	"weapon_hunting_rifle",
	"weapon_sniper_military",
	"weapon_sniper_scout",
	"weapon_sniper_awp",
	"weapon_rifle",
	"weapon_rifle_sg552",
	"weapon_rifle_desert",
	"weapon_rifle_ak47",
	"weapon_rifle_m60",
	"weapon_smg",
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_pumpshotgun",
	"weapon_shotgun_chrome",
	"weapon_autoshotgun",
	"weapon_shotgun_spas",
	"weapon_grenade_launcher",
};

StringMap mapWeapons;

ConVar cChance;		float flChance;
ConVar cChanceSI;	float flChanceSI;
ConVar cChanceBoss;	float flChanceBoss;
ConVar cAmmoMax;	int iAmmoMax;
ConVar cMethod;		int iMethod;
ConVar cChanceAdd;	float flChanceAdd;
ConVar cGlowMin;	int iGlowMin;
ConVar cGlowMax;	int iGlowMax;
ConVar cGlowFlash;	bool bGlowFlash;
ConVar cLootAmmo;	float flLootAmmo;
ConVar cLootExtra;	ArrayList listLootExtra;

public void OnPluginStart() {

	// load gamedata
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", PLUGIN_PREFIX ... PLUGIN_NAME);

	if( !FileExists(sPath) )
		SetFailState("missing gamedata file %s, please check installation guide", sPath);

	Handle hGameData = LoadGameConfigFile(PLUGIN_PREFIX ... PLUGIN_NAME);

	if( hGameData == null )
		SetFailState("fail to load gamedata file %s.txt", PLUGIN_PREFIX ... PLUGIN_NAME);

	// prepare SDKCall CHolidayGift::Create
	StartPrepSDKCall(SDKCall_Static);
	if( !PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CHolidayGift::Create") )
		SetFailState("Could not load the \"CHolidayGift::Create\" gamedata signature.");

	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkCreateGift = EndPrepSDKCall();
	if( sdkCreateGift == null )
		SetFailState("Could not prep the \"CHolidayGift::Create\" function.");

	// prepare SDKCall CWeaponAmmoSpawn::Use
	StartPrepSDKCall(SDKCall_Entity);
	if( !PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CWeaponAmmoSpawn::Use") )
		SetFailState("Could not load the \"CWeaponAmmoSpawn::Use\" gamedata signature.");

	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkUseAmmo = EndPrepSDKCall();
	if( sdkUseAmmo == null )
		SetFailState("Could not prep the \"CWeaponAmmoSpawn::Use\" function.");

	delete hGameData;

	CreateConVar				(PLUGIN_NAME, PLUGIN_VERSION,							"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cChance =		CreateConVar(PLUGIN_NAME ... "_chance", "0.01",						"loot chance base", FCVAR_NOTIFY);
	cChanceSI =		CreateConVar(PLUGIN_NAME ... "_chance_si", "4",						"loot chance si multiplier -1=certainly", FCVAR_NOTIFY);
	cChanceBoss =	CreateConVar(PLUGIN_NAME ... "_chance_boss", "-1",					"loot chance boss multiplier -1=certainly", FCVAR_NOTIFY);
	cAmmoMax =		CreateConVar(PLUGIN_NAME ... "_ammo_max", "50",						"max ammo can loot by once, to solve too large clip like m60, -1=clip only", FCVAR_NOTIFY);
	cMethod =		CreateConVar(PLUGIN_NAME ... "_ammo_method", "3",					"method to loot ammo 1=Touch 2=Use 3=Both", FCVAR_NOTIFY);
	cChanceAdd =	CreateConVar(PLUGIN_NAME ... "_chance_add", "0.01",					"chance will increase every failed 0=disabled", FCVAR_NOTIFY);
	cGlowMin =		CreateConVar(PLUGIN_NAME ... "_glow_min", "0",						"glow min range", FCVAR_NOTIFY);
	cGlowMax =		CreateConVar(PLUGIN_NAME ... "_glow_max", "800",					"glow max range", FCVAR_NOTIFY);
	cGlowFlash =	CreateConVar(PLUGIN_NAME ... "_glow_flash", "0",					"does glow flashing", FCVAR_NOTIFY);
	cLootAmmo =		CreateConVar(PLUGIN_NAME ... "_loot_ammo", "0.75",					"does loot ammo 0=disabled 0.75=76% chance ammo 25% chance *_loot_extra", FCVAR_NOTIFY);
	cLootExtra =	CreateConVar(PLUGIN_NAME ... "_loot_extra", "molotov,gascan",		"extra custom loot list empty=disabled", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cChance.AddChangeHook(OnConVarChanged);
	cChanceSI.AddChangeHook(OnConVarChanged);
	cChanceBoss.AddChangeHook(OnConVarChanged);
	cAmmoMax.AddChangeHook(OnConVarChanged);
	cMethod.AddChangeHook(OnConVarChanged);
	cChanceAdd.AddChangeHook(OnConVarChanged);
	cGlowMin.AddChangeHook(OnConVarChanged);
	cGlowMax.AddChangeHook(OnConVarChanged);
	cGlowFlash.AddChangeHook(OnConVarChanged);
	cLootAmmo.AddChangeHook(OnConVarChanged);
	cLootExtra.AddChangeHook(OnConVarChanged);

	HookEvent("player_death", OnPlayerDeath);

	mapWeapons = new StringMap();
	listLootExtra = new ArrayList(32);

	ApplyCvars();

	// build map for weapons
	for (int i = 0; i < sizeof(CLASSES_WEAPON); i++)
		mapWeapons.SetValue(CLASSES_WEAPON[i], i);

	// Late Load
	if (bLateLoad) {
		for (int i = MaxClients + 1; i < 2048; i++)
			if (IsValidEntity(i)) {
				char classname[32];
				GetEntityClassname(i, classname, sizeof(classname));
				OnEntityCreated(i, classname);
			}
	}
}

void ApplyCvars() {
	flChance = cChance.FloatValue;
	flChanceSI = cChanceSI.FloatValue;
	flChanceBoss = cChanceBoss.FloatValue;
	iAmmoMax = cAmmoMax.IntValue;
	iMethod = cMethod.IntValue;
	flChanceAdd = cChanceAdd.FloatValue;
	iGlowMin = cGlowMin.IntValue;
	iGlowMax = cGlowMax.IntValue;
	bGlowFlash = cGlowFlash.BoolValue;
	flLootAmmo = cLootAmmo.FloatValue;

	listLootExtra.Clear();

	static char sBuffer[32*32], sBufferSub[32][32];
	int size;

	cLootExtra.GetString(sBuffer, sizeof(sBuffer));
	
	size = ExplodeString(sBuffer, ",", sBufferSub, 32, 32);

	for (int i = 0; i < size; i++)
		if (sBufferSub[i][0])
			listLootExtra.PushString(sBufferSub[i]);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void OnMapStart() {
	PrecacheModel(MODEL_AMMOPILE);
	PrecacheSound(SOUND_REWARD);
}

bool bIsGiftCreating;
int iClipMax [2048];

void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	static char name_victim[32];
	float pos_victim[3];

	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if ( !IsAliveHumanSurvivor(attacker) )
		return;

	float lucky = flChance;

	event.GetString("victimname", name_victim, sizeof(name_victim));

	switch (name_victim[0]) {

		case 'I' : 
			lucky *= 1.0;

		case 'S', 'B', 'H', 'J', 'C' :
			lucky *= flChanceSI;

		case 'W', 'T' :
			lucky *= flChanceBoss;

		default : return;
	}

	pos_victim[0] = event.GetFloat("victim_x");
	pos_victim[1] = event.GetFloat("victim_y");
	pos_victim[2] = event.GetFloat("victim_z");

	if ( Gacha(lucky) ) {

		if (listLootExtra.Length > 0 && flLootAmmo < GetURandomFloat()) {

			int luck = RoundToFloor( listLootExtra.Length * GetURandomFloat() );

			static char name_entity[32];

			listLootExtra.GetString(luck, name_entity, sizeof(name_entity));

			Format(name_entity, sizeof(name_entity), "weapon_%s", name_entity);

			int entity = CreateEntityByName(name_entity);

			if (entity != INVALID_ENT_REFERENCE) {

				EmitSoundToClient(attacker, SOUND_REWARD);

				float vVel[3];
				vVel[0] = -100.0 + GetURandomFloat() * 200.0;
				vVel[1] = -100.0 + GetURandomFloat() * 200.0;
				vVel[2] = GetRandomFloat(100.0, 300.0);
				DispatchSpawn(entity);
				TeleportEntity(entity, pos_victim, NULL_VECTOR, vVel);

				L4D2_SetEntityGlow(entity, L4D2Glow_OnLookAt, iGlowMax, iGlowMin, {150, 150, 150}, bGlowFlash);

				if (bIsClearWeaponDropExists)
					Timer_Delete_Weapon(entity);
			}

		} else if (flLootAmmo > 0) {

			bIsGiftCreating = true;

			EmitSoundToClient(attacker, SOUND_REWARD);

			SDKCall(
				sdkCreateGift, 
				pos_victim, 
				view_as<float>({0.0, 0.0, 0.0}), 
				view_as<float>({0.0, 0.0, 0.0}), 
				view_as<float>({0.0, 0.0, 0.0}), 
				0
			);

			bIsGiftCreating = false;
		}
	}
}

bool Gacha(float chance) {

	static failed = 0;

	bool loot = false;

	if (1 > chance > 0)
		loot = (chance + flChanceAdd * failed) > GetURandomFloat();
	else
		loot = true;

	if ( !loot ) {
		failed++;
		return false;
	} else {
		failed = 0;
		return true;
	}
}

public void OnEntityCreated(int entity, const char[] classname) {

	if ( bIsGiftCreating && strcmp(classname, "holiday_gift") == 0 ) {

		SDKHook(entity, SDKHook_SpawnPost, OnGiftSpawn);
		SDKHook(entity, SDKHook_Touch, OnGiftTouch);
		SDKHook(entity, SDKHook_UsePost, OnGiftUsePost);

	} else if (classname[0] == 'w') {

		int index;

		if (mapWeapons.GetValue(classname, index))
			iClipMax[entity] = L4D2_GetIntWeaponAttribute(classname, L4D2IWA_ClipSize);
	}
}

public void OnEntityDestroyed(int entity) {

	if (2048 > entity > MaxClients)
		iClipMax[entity] = 0;
}

enum {
	LootOnTouch = (1 << 0),
	LootOnUse = (1 << 1),
}

void OnGiftUsePost(int entity, int activator, int caller, UseType type, float value) {
	if ( iMethod & LootOnUse && IsAliveHumanSurvivor(caller) && GiveClip(entity, caller) )
		RemoveEntity(entity);
}

void OnGiftSpawn(int entity) {

	// cancel origin glow
	L4D2_SetEntityGlow_MinRange(entity, 0);
	L4D2_SetEntityGlow_Range(entity, 1);

	int glow = CreateEntityByName("prop_dynamic_override");

	if (glow != INVALID_ENT_REFERENCE) {
		// set same model
		SetEntityModel(glow, MODEL_AMMOPILE);
		DispatchSpawn(glow);

		float vPos[3], vAng[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(glow, vPos, vAng, NULL_VECTOR);
		// set glow param
		L4D2_SetEntityGlow(glow, L4D2Glow_OnLookAt, iGlowMax, iGlowMin, {150, 150, 150}, bGlowFlash)
		// start glow
		AcceptEntityInput(glow, "StartGlowing");
		// set model transparent
		SetEntityRenderMode(glow, RENDER_TRANSCOLOR);
		SetEntityRenderColor(glow, 0, 0, 0, 0);
		// set parent to gift
		SetVariantString("!activator");
		AcceptEntityInput(glow, "SetParent", entity);
	}

	SetEntityModel(entity, MODEL_AMMOPILE);
}

Action OnGiftTouch(int entity, int other) {

	if (iMethod & LootOnTouch && IsAliveHumanSurvivor(other) && GiveClip(entity, other))
		return Plugin_Continue;
	else
		return Plugin_Stop;
}

bool GiveClip(int entity, int client) {

	Survivor survivor = Survivor(client);

	if (survivor.valid) {

		Weapon weapon = survivor.slot(0);

		if (weapon.valid && iClipMax[weapon.index] > 0) {
			
			int reserved_before = weapon.GetAmmo(client);

			SDKCall(
				sdkUseAmmo, 
				entity,
				client,
				entity,
				1,
				0.0
			);

			int reserved_after = weapon.GetAmmo(client),
				ammo_increased = reserved_after - reserved_before;

			if ( ammo_increased > 0) {

				if (ammo_increased > iClipMax[weapon.index] || ammo_increased > iAmmoMax > 0) {

					int ammo_increase_fixed = iClipMax[weapon.index] > iAmmoMax > 0 ? iAmmoMax : iClipMax[weapon.index];
					weapon.SetAmmo(client, reserved_before + ammo_increase_fixed);
				}

				return true;
			} else
				return false;
		}
	}
	return false;
}


/**
 * Set entity glow. This is consider safer and more robust over setting each glow property on their own because glow offset will be check first.
 *
 * @param entity		Entity index.
 * @parma type			Glow type.
 * @param range			Glow max range, 0 for unlimited.
 * @param minRange		Glow min range.
 * @param colorOverride	Glow color, RGB.
 * @param flashing		Whether the glow will be flashing.
 * @return				True if glow was set, false if entity does not support glow.
 */
// L4D2 only.
bool L4D2_SetEntityGlow(int entity, L4D2GlowType type, int range, int minRange, colorOverride[3], bool flashing)
{
	if (!IsValidEntity(entity))
	{
		return false;
	}

	char netclass[128];
	GetEntityNetClass(entity, netclass, sizeof(netclass));

	int offset = FindSendPropInfo(netclass, "m_iGlowType");

	if (offset < 1)
	{
		return false;
	}

	L4D2_SetEntityGlow_Type(entity, type);
	L4D2_SetEntityGlow_Range(entity, range);
	L4D2_SetEntityGlow_MinRange(entity, minRange);
	L4D2_SetEntityGlow_Color(entity, colorOverride);
	L4D2_SetEntityGlow_Flashing(entity, flashing);
	return true;
}


/**
 * Set entity glow type.
 *
 * @param entity		Entity index.
 * @parma type			Glow type.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
void L4D2_SetEntityGlow_Type(int entity, L4D2GlowType type)
{
	SetEntProp(entity, Prop_Send, "m_iGlowType", type);
}

/**
 * Set entity glow range.
 *
 * @param entity		Entity index.
 * @parma range			Glow range.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
void L4D2_SetEntityGlow_Range(int entity, int range)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
}

/**
 * Set entity glow min range.
 *
 * @param entity		Entity index.
 * @parma minRange		Glow min range.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
void L4D2_SetEntityGlow_MinRange(int entity, int minRange)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", minRange);
}

/**
 * Set entity glow color.
 *
 * @param entity		Entity index.
 * @parma colorOverride	Glow color, RGB.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
void L4D2_SetEntityGlow_Color(int entity, int colorOverride[3])
{
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", colorOverride[0] + (colorOverride[1] * 256) + (colorOverride[2] * 65536));
}

/**
 * Set entity glow flashing state.
 *
 * @param entity		Entity index.
 * @parma flashing		Whether glow will be flashing.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
void L4D2_SetEntityGlow_Flashing(int entity, bool flashing)
{
	SetEntProp(entity, Prop_Send, "m_bFlashing", flashing);
}


///////////////////////////
// Method Map Below		//
/////////////////////////

methodmap Survivor {
	property int index {
		public get() {
			return view_as<int>(this);
		}
	}

	public Survivor(int index) {
		return view_as<Survivor>(index);
	}

	property Weapon weapon {
		public get() {
			return Weapon(GetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon"));
		}
	}

	property int userid {
		public get() {
			return GetClientUserId(this.index);
		}
	}
	
	public Weapon slot(int slot) {
		return Weapon(GetPlayerWeaponSlot(this.index, slot));
	}

	property bool valid {
		public get() {
			int index = this.index;
			return (1 <= index <= MaxClients) && IsClientInGame(index) && GetClientTeam(index) == 2;
		}
	}
	
}

methodmap Weapon {

	property int index {
		public get() {
			return view_as<int>(this);
		}
	}

	public Weapon(int index) {
		return view_as<Weapon>(index);
	}

	property bool valid {
		public get() {
			int index = this.index;
			return (2048 > index > MaxClients) && IsValidEntity(index);
		}
	}

	property int ref {
		public get() {
			return EntIndexToEntRef(this.index);
		}
	}

	property int owner {
		public get() {
			return GetEntPropEnt(this.index, Prop_Send, "m_hOwnerEntity");
		}
		public set(int entity) {
			SetEntPropEnt(this.index, Prop_Send, "m_hOwnerEntity", entity)
		}
	}

	//on target = 0x40, not carried = 0, carrying = 1, activating = 2;
	property int state {
		public get() {
			return GetEntProp(this.index, Prop_Data, "m_iState");
		}
	}

	property bool melee {
		public get() {
			static char name[32];

			GetEntityClassname(this.index, name, sizeof(name));

			return strcmp(name, "weapon_melee") == 0;
		}
	}

	property float attacktime {
		public get() {
			return GetEntPropFloat(this.index, Prop_Send, "m_flNextPrimaryAttack");
		}
		public set(float gametime) {
			SetEntPropFloat(this.index, Prop_Send, "m_flNextPrimaryAttack", gametime);
		}
	}

	property float playback {
		public get() {
			return GetEntPropFloat(this.index, Prop_Send, "m_flPlaybackRate");
		}
		public set(float rate) {
			SetEntPropFloat(this.index, Prop_Send, "m_flPlaybackRate", rate);
		}
	}

	property bool reloading {
		public get() {
			return view_as<bool>(GetEntProp(this.index, Prop_Send, "m_bInReload"));
		}
	}

	property bool firing {
		public get() {
			return view_as<bool>(GetEntProp(this.index, Prop_Send, "m_isHoldingFireButton"));
		}
	}

	property bool reloadingempty {
		public get() {
			return view_as<bool>(GetEntProp(this.index, Prop_Send, "m_reloadFromEmpty"));
		}
	}

	property int clip {
		public get() {
			return GetEntProp(this.index, Prop_Send, "m_iClip1")
		}
		public set(int amount) {
			SetEntProp(this.index, Prop_Send, "m_iClip1", amount);
		}
	}

	property int ammo {
		public get() {
			return GetEntProp(this.index, Prop_Send, "m_iExtraPrimaryAmmo")
		}
		public set(int amount) {
			SetEntProp(this.index, Prop_Send, "m_iExtraPrimaryAmmo", amount);
		}
	}

	property int ammotype {
		public get() {
			return GetEntProp(this.index, Prop_Data, "m_iPrimaryAmmoType")
		}
	}

	property int upgraded {
		public get() {
			return GetEntProp(this.index, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded")
		}
		public set(int amount) {
			SetEntProp(this.index, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", amount);
		}
	}

	property int upgradetype {
		public get() {
			return GetEntProp(this.index, Prop_Send, "m_upgradeBitVec")
		}
		public set(int bit) {
			SetEntProp(this.index, Prop_Send, "m_upgradeBitVec", bit);
		}
	}

	public void SetAmmo(int client, int size) {

		static int ammo_offset_terror = -1;

		if (ammo_offset_terror == -1)
			ammo_offset_terror = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

		SetEntData( client, ammo_offset_terror + this.ammotype * 4, size);
	}

	public int GetAmmo(int client) {

		static int ammo_offset_terror = -1;

		if (ammo_offset_terror == -1)
			ammo_offset_terror = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

		return GetEntData( client, ammo_offset_terror + this.ammotype * 4 );
	}

	public void Remove() {
		RemoveEntity(this.index);
	}

	public bool RemoveFrom(int client, bool clear = true) {

		bool result = RemovePlayerItem(client, this.index);

		if (clear)
			this.Remove();

		return result;
	}

	property bool dual {
		public get() {
			return view_as<bool>(GetEntProp(this.index, Prop_Send, "m_hasDualWeapons"));
		}
	}
}