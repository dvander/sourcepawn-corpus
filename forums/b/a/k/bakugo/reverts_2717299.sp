#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_FILE "reverts"
#define PLUGIN_NAME "TF2 Weapon Reverts"
#define PLUGIN_DESC "Reverts nerfed weapons back to their glory days"
#define PLUGIN_AUTHOR "Bakugo"
#define PLUGIN_VERSION "1.1.3"
#define PLUGIN_URL "https://steamcommunity.com/profiles/76561198020610103"

public Plugin myinfo = {
	name = PLUGIN_NAME,
	description = PLUGIN_DESC,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

#define ITEMS_MAX 50
#define ITEM_MENU_TIME (60*3)
#define ITEM_COOKIE_VER 1
#define ITEM_FL_PICKABLE (1 << 0) // players can choose to toggle this item
#define ITEM_FL_DISABLED (1 << 1) // this item is disabled by default (unused)
#define BALANCE_CIRCUIT_METAL 10
#define BALANCE_CIRCUIT_DAMAGE 10.0
#define BALANCE_CIRCUIT_RECOVERY 0.25
#define PLAYER_CENTER_HEIGHT (82.0 / 2.0) // constant for tf2 players

// game code defs
#define EF_NODRAW 0x20
#define FSOLID_USE_TRIGGER_BOUNDS 0x80
#define DMG_MELEE DMG_BLAST_SURFACE
#define DMG_DONT_COUNT_DAMAGE_TOWARDS_CRIT_RATE DMG_DISSOLVE
#define TF_DMG_CUSTOM_NONE 0
#define TF_DMG_CUSTOM_BASEBALL 22
#define TF_DMG_CUSTOM_PICKAXE 27
#define TF_DMG_CUSTOM_STICKBOMB_EXPLOSION 42
#define TF_DMG_CUSTOM_CANNONBALL_PUSH 61
#define TF_DEATH_FEIGN_DEATH 0x20

enum struct Item {
	char key[64];
	char name[64];
	char desc[128];
	int flags;
	Handle cvar;
}

enum struct Player {
	bool items_pick[ITEMS_MAX]; // enabled items the player has chosen
	bool items_life[ITEMS_MAX]; // enabled items for this life (inc cvar)
	bool change; // are there pending attrib changes?
	bool picked; // made any changes in the pick menu
	int respawn; // frame to force a respawn after
	
	// gameplay vars
	float resupply_time;
	int headshot_frame;
	int projectile_touch_frame;
	int projectile_touch_entity;
	float stunball_fix_time_bonk;
	float stunball_fix_time_wear;
	float spy_cloak_meter;
	bool spy_is_feigning;
	int ammo_grab_frame;
	int bonk_cond_frame;
	int bison_hit_frame;
	int beggars_ammo;
	int sleeper_ammo;
	int sleeper_piss_frame;
	float sleeper_piss_duration;
	bool sleeper_piss_explode;
	int medic_medigun_defidx;
	float medic_medigun_charge;
	float parachute_cond_time;
	float cleaver_regen_time;
	float icicle_regen_time;
	int scout_airdash_value;
	int scout_airdash_count;
	int player_damage_frame;
}

enum struct Entity {
	bool exists;
	float spawn_time;
	bool is_demo_shield;
}

Handle cvar_enable;
Handle cvar_extras;
Handle cvar_ref_tf_airblast_cray;
Handle cvar_ref_tf_bison_tick_time;
Handle cvar_ref_tf_dropped_weapon_lifetime;
Handle cvar_ref_tf_feign_death_activate_damage_scale;
Handle cvar_ref_tf_feign_death_damage_scale;
Handle cvar_ref_tf_feign_death_duration;
Handle cvar_ref_tf_feign_death_speed_duration;
Handle cvar_ref_tf_fireball_radius;
Handle cvar_ref_tf_parachute_aircontrol;
Handle cvar_ref_tf_parachute_maxspeed_onfire_z;
Handle cvar_ref_tf_scout_hype_mod;
Handle cookie_reverts[3];
Handle sdkcall_JarExplode;
Handle sdkcall_GetMaxHealth;
Handle dhook_CTFWeaponBase_PrimaryAttack;
Handle dhook_CTFWeaponBase_SecondaryAttack;
Handle dhook_CTFBaseRocket_GetRadius;
Item items[ITEMS_MAX];
Player players[MAXPLAYERS+1];
Entity entities[2048];
int frame;
Handle hudsync;
Menu menu_main;
Menu menu_pick;
int rocket_create_entity;
int rocket_create_frame;

public void OnPluginStart() {
	int idx;
	Handle conf;
	char tmp[64];
	
	CreateConVar(("sm_" ... PLUGIN_FILE ... "__version"), PLUGIN_VERSION, (PLUGIN_NAME ... " - Version"), (FCVAR_NOTIFY|FCVAR_DONTRECORD));
	
	cvar_enable = CreateConVar(("sm_" ... PLUGIN_FILE ... "__enable"), "1", (PLUGIN_NAME ... " - Enable plugin"), _, true, 0.0, true, 1.0);
	cvar_extras = CreateConVar(("sm_" ... PLUGIN_FILE ... "__extras"), "0", (PLUGIN_NAME ... " - Enable some fun extra features"), _, true, 0.0, true, 1.0);
	
	ItemDefine("Airblast", "airblast", "All flamethrowers' airblast mechanics are reverted to pre-inferno", ITEM_FL_PICKABLE);
	ItemDefine("Air Strike", "airstrike", "Reverted to pre-toughbreak, no extra blast radius penalty when blast jumping");
	ItemDefine("Ambassador", "ambassador", "Reverted to pre-inferno, deals full headshot damage (102) at all ranges");
	ItemDefine("Atomizer", "atomizer", "Reverted to pre-inferno, can always triple jump, taking 10 damage each time", ITEM_FL_PICKABLE);
	ItemDefine("Axtinguisher", "axtinguish", "Reverted to pre-love&war, always deals 195 damage crits to burning targets", ITEM_FL_PICKABLE);
	ItemDefine("B.A.S.E. Jumper", "basejump", "Reverted to pre-toughbreak, can redeploy, more air control, fire updraft");
	ItemDefine("Baby Face's Blaster", "babyface", "Reverted to pre-gunmettle, no boost loss on damage, only -25% on jump");
	ItemDefine("Beggar's Bazooka", "beggars", "Reverted to pre-2013, no radius penalty, misfires don't remove ammo");
	ItemDefine("Bonk! Atomic Punch", "bonk", "Reverted to pre-inferno, no longer slows after the effect wears off");
	ItemDefine("Booties & Bootlegger", "booties", "Reverted to pre-matchmaking, shield not required for speed bonus");
	ItemDefine("Chargin' Targe", "targe", "Reverted to pre-toughbreak, 40% blast resistance, afterburn immunity");
	ItemDefine("Dead Ringer", "ringer", "Reverted to pre-gunmettle, can pick up ammo, 80% dmg resist for 4s", ITEM_FL_PICKABLE);
	ItemDefine("Degreaser", "degreaser", "Reverted to pre-toughbreak, full switch speed for all weapons, old penalties");
	ItemDefine("Dragon's Fury", "dragonfury", "Reverted -25% projectile size nerf");
	ItemDefine("Enforcer", "enforcer", "Reverted to pre-gunmettle, damage bonus while undisguised, no piercing", ITEM_FL_PICKABLE);
	ItemDefine("Equalizer & Escape Plan", "equalizer", "Merged back together, no healing, no mark-for-death", ITEM_FL_PICKABLE);
	ItemDefine("Eviction Notice", "eviction", "Reverted to pre-inferno, no health drain, +20% damage taken", ITEM_FL_PICKABLE);
	ItemDefine("Fists of Steel", "fiststeel", "Reverted to pre-inferno, no healing penalties", ITEM_FL_PICKABLE);
	ItemDefine("Flying Guillotine", "guillotine", "Reverted to pre-inferno, stun crits, distance mini-crits, no recharge", ITEM_FL_PICKABLE);
	ItemDefine("Gloves of Running Urgently", "glovesru", "Reverted to pre-inferno, no health drain, marks for death", ITEM_FL_PICKABLE);
	ItemDefine("Half-Zatoichi", "zatoichi", "Reverted to pre-toughbreak, fast switch, old honorbound, full heal, crits", ITEM_FL_PICKABLE);
	ItemDefine("Liberty Launcher", "liberty", "Reverted to release, +40% projectile speed, -25% clip size", ITEM_FL_PICKABLE);
	ItemDefine("Loch n Load", "lochload", "Reverted to pre-gunmettle, +20% damage against everything");
	ItemDefine("Loose Cannon", "cannon", "Reverted to pre-toughbreak, +50% projectile speed, constant 60 dmg impacts", ITEM_FL_PICKABLE);
	ItemDefine("Market Gardener", "gardener", "Reverted to pre-toughbreak, no attack speed penalty");
	ItemDefine("Pomson 6000", "pomson", "Increased hitbox size (same as Bison), passes through team, full drains");
	ItemDefine("Reserve Shooter", "reserve", "Deals minicrits to airblasted targets again");
	ItemDefine("Righteous Bison", "bison", "Increased hitbox size, can hit the same player more times");
	ItemDefine("Sandman", "sandman", "Reverted to pre-inferno, stuns players on hit again");
	ItemDefine("Short Circuit", "circuit", "Reverted to post-gunmettle, alt fire destroys projectiles, -cost +speed", ITEM_FL_PICKABLE);
	ItemDefine("Shortstop", "shortstop", "Reverted reload time to release version, with +40% push force", ITEM_FL_PICKABLE);
	ItemDefine("Soda Popper", "sodapop", "Reverted to pre-2013, run to build hype and auto gain minicrits", ITEM_FL_PICKABLE);
	ItemDefine("Solemn Vow", "solemn", "Reverted to pre-gunmettle, firing speed penalty removed");
	ItemDefine("Spy-cicle", "spycicle", "Reverted to pre-gunmettle, fire immunity for 3s, silent killer", ITEM_FL_PICKABLE);
	ItemDefine("Sticky Jumper", "stkjumper", "Can have 8 stickies out at once again");
	ItemDefine("Sydney Sleeper", "sleeper", "Reverted to pre-2018, restored jarate explosion, no headshots", ITEM_FL_PICKABLE);
	ItemDefine("Tide Turner", "turner", "Can deal full crits like other shields again");
	ItemDefine("Ullapool Caber", "caber", "Reverted to pre-gunmettle, always deals 175+ damage on melee explosion");
	ItemDefine("Vita-Saw", "vitasaw", "Reverted to pre-inferno, always preserves up to 20% uber on death", ITEM_FL_PICKABLE);
	ItemDefine("Your Eternal Reward", "eternal", "Reverted to pre-inferno, cannot disguise, no cloak drain penalty", ITEM_FL_PICKABLE);
	
	menu_main = CreateMenu(MenuHandler_Main, (MenuAction_Select));
	SetMenuTitle(menu_main, "Weapon Reverts");
	SetMenuPagination(menu_main, MENU_NO_PAGINATION);
	SetMenuExitButton(menu_main, true);
	AddMenuItem(menu_main, "info", "Show information about each revert");
	AddMenuItem(menu_main, "pick", "Pick which reverts you want to use");
	// why doesn't this shit work
	// AddMenuItem(menu_main, "", "", (ITEMDRAW_SPACER|ITEMDRAW_RAWLINE));
	// AddMenuItem(menu_main, "bugs1", "If you find any issues, please report them to Bakugo");
	// AddMenuItem(menu_main, "bugs2", "at https://steamcommunity.com/id/bakugo");
	
	menu_pick = CreateMenu(MenuHandler_Main, (MenuAction_Select|MenuAction_Cancel|MenuAction_DrawItem|MenuAction_DisplayItem));
	SetMenuTitle(menu_pick, "Reverts Picker");
	SetMenuPagination(menu_pick, 10);
	SetMenuExitButton(menu_pick, true);
	
	ItemFinalize();
	
	AutoExecConfig(false, PLUGIN_FILE, "sourcemod");
	
	hudsync = CreateHudSynchronizer();
	
	cvar_ref_tf_airblast_cray = FindConVar("tf_airblast_cray");
	cvar_ref_tf_bison_tick_time = FindConVar("tf_bison_tick_time");
	cvar_ref_tf_dropped_weapon_lifetime = FindConVar("tf_dropped_weapon_lifetime");
	cvar_ref_tf_feign_death_activate_damage_scale = FindConVar("tf_feign_death_activate_damage_scale");
	cvar_ref_tf_feign_death_damage_scale = FindConVar("tf_feign_death_damage_scale");
	cvar_ref_tf_feign_death_duration = FindConVar("tf_feign_death_duration");
	cvar_ref_tf_feign_death_speed_duration = FindConVar("tf_feign_death_speed_duration");
	cvar_ref_tf_fireball_radius = FindConVar("tf_fireball_radius");
	cvar_ref_tf_parachute_aircontrol = FindConVar("tf_parachute_aircontrol");
	cvar_ref_tf_parachute_maxspeed_onfire_z = FindConVar("tf_parachute_maxspeed_onfire_z");
	cvar_ref_tf_scout_hype_mod = FindConVar("tf_scout_hype_mod");
	
	RegConsoleCmd("sm_revert", Command_Menu, (PLUGIN_NAME ... " - Open reverts menu"), 0);
	RegConsoleCmd("sm_reverts", Command_Menu, (PLUGIN_NAME ... " - Open reverts menu"), 0);
	RegConsoleCmd("sm_revertinfo", Command_Info, (PLUGIN_NAME ... " - Show reverts info in console"), 0);
	RegConsoleCmd("sm_revertsinfo", Command_Info, (PLUGIN_NAME ... " - Show reverts info in console"), 0);
	RegConsoleCmd("sm_revertpick", Command_Pick, (PLUGIN_NAME ... " - Pick which reverts to enable"), 0);
	RegConsoleCmd("sm_revertspick", Command_Pick, (PLUGIN_NAME ... " - Pick which reverts to enable"), 0);
	
	for (idx = 0; idx < sizeof(cookie_reverts); idx++) {
		Format(tmp, sizeof(tmp), "reverts.%d", (idx+1));
		cookie_reverts[idx] = RegClientCookie(tmp, PLUGIN_NAME, CookieAccess_Protected);
	}
	
	HookEvent("player_spawn", OnGameEvent);
	HookEvent("player_death", OnGameEvent);
	HookEvent("post_inventory_application", OnGameEvent);
	HookEvent("item_pickup", OnGameEvent);
	
	AddNormalSoundHook(OnSoundNormal);
	
	
	conf = LoadGameConfigFile(PLUGIN_FILE);
	
	if (conf == null) SetFailState("Failed to load conf");
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "JarExplode");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int iEntIndex
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer); // CTFPlayer *pAttacker
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer); // CBaseEntity *pOriginalWeapon
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer); // CBaseEntity *pWeapon
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef); // const Vector& vContactPoint
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int iTeam
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain); // float flRadius
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // ETFCond cond
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain); // float flDuration
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer); // const char* pszImpactEffect
	sdkcall_JarExplode = EndPrepSDKCall();
	
	dhook_CTFWeaponBase_PrimaryAttack = DHookCreateFromConf(conf, "CTFWeaponBase::PrimaryAttack");
	dhook_CTFWeaponBase_SecondaryAttack = DHookCreateFromConf(conf, "CTFWeaponBase::SecondaryAttack");
	dhook_CTFBaseRocket_GetRadius = DHookCreateFromConf(conf, "CTFBaseRocket::GetRadius");
	
	delete conf;
	
	conf = LoadGameConfigFile("sdkhooks.games");
	
	if (conf == null) SetFailState("Failed to load conf");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	sdkcall_GetMaxHealth = EndPrepSDKCall();
	
	delete conf;
	
	if (sdkcall_JarExplode == null) SetFailState("Failed to create sdkcall_JarExplode");
	if (sdkcall_GetMaxHealth == null) SetFailState("Failed to create sdkcall_GetMaxHealth");
	if (dhook_CTFWeaponBase_PrimaryAttack == null) SetFailState("Failed to create dhook_CTFWeaponBase_PrimaryAttack");
	if (dhook_CTFWeaponBase_SecondaryAttack == null) SetFailState("Failed to create dhook_CTFWeaponBase_SecondaryAttack");
	
	
	for (idx = 1; idx <= MaxClients; idx++) {
		if (IsClientConnected(idx)) OnClientConnected(idx);
		if (IsClientInGame(idx)) OnClientPutInServer(idx);
		if (AreClientCookiesCached(idx)) OnClientCookiesCached(idx);
	}
}

public void OnMapStart() {
	PrecacheSound("misc/banana_slip.wav");
}

public void OnGameFrame() {
	int idx;
	char class[64];
	float cloak;
	int weapon;
	int ammo;
	int clip;
	int ent;
	float timer;
	float pos1[3];
	float pos2[3];
	float maxs[3];
	float mins[3];
	float hype;
	int airdash_value;
	int airdash_limit_old;
	int airdash_limit_new;
	
	frame++;
	
	// run every frame
	if (frame % 1 == 0) {
		for (idx = 1; idx <= MaxClients; idx++) {
			if (
				IsClientInGame(idx) &&
				IsPlayerAlive(idx)
			) {
				{
					// respawn to apply attibs
					
					if (players[idx].respawn > 0) {
						if ((players[idx].respawn + 2) == GetGameTickCount()) {
							TF2_RespawnPlayer(idx);
							players[idx].respawn = 0;
							
							PrintToChat(idx, "[SM] Revert changes have been applied");
						}
						
						continue;
					}
				}
				
				{
					// reset medigun info
					// if player is medic, this will be set again this frame
					
					players[idx].medic_medigun_defidx = 0;
					players[idx].medic_medigun_charge = 0.0;
				}
				
				if (TF2_GetPlayerClass(idx) == TFClass_Scout) {
					{
						// extra jump stuff (atomizer/sodapop)
						// truly a work of art
						
						airdash_limit_old = 1; // multijumps allowed by game
						airdash_limit_new = 1; // multijumps we want to allow
						
						weapon = GetPlayerWeaponSlot(idx, TFWeaponSlot_Melee);
						
						if (weapon > 0) {
							GetEntityClassname(weapon, class, sizeof(class));
							
							if (
								StrEqual(class, "tf_weapon_bat") &&
								GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 450
							) {
								if (ItemIsEnabled("atomizer", idx)) {
									airdash_limit_new = 2;
								} else {
									if (weapon == GetEntPropEnt(idx, Prop_Send, "m_hActiveWeapon")) {
										airdash_limit_old = 2;
										airdash_limit_new = 2;
									}
								}
							}
						}
						
						if (TF2_IsPlayerInCondition(idx, TFCond_CritHype)) {
							airdash_limit_old = 5;
							
							if (ItemIsEnabled("sodapop", idx) == false) {
								airdash_limit_new = 5;
							}
						}
						
						if (TF2_IsPlayerInCondition(idx, TFCond_HalloweenSpeedBoost)) {
							airdash_limit_old = 999;
							airdash_limit_new = 999;
						}
						
						airdash_value = GetEntProp(idx, Prop_Send, "m_iAirDash");
						
						if (airdash_value > players[idx].scout_airdash_value) {
							// airdash happened this frame
							
							players[idx].scout_airdash_count++;
							
							if (
								airdash_limit_new == 2 &&
								players[idx].scout_airdash_count == 2 &&
								ItemIsEnabled("atomizer", idx)
							) {
								// atomizer global jump
								SDKHooks_TakeDamage(idx, idx, idx, 10.0, (DMG_MELEE|DMG_PREVENT_PHYSICS_FORCE), -1, NULL_VECTOR, NULL_VECTOR);
								
								if (airdash_limit_new > airdash_limit_old) {
									// only play sound if the game doesn't play it
									EmitSoundToAll("misc/banana_slip.wav", idx, SNDCHAN_AUTO, 30, (SND_CHANGEVOL|SND_CHANGEPITCH), 1.0, 100);
								}
							}
						} else {
							if ((GetEntityFlags(idx) & FL_ONGROUND) != 0) {
								players[idx].scout_airdash_count = 0;
							}
						}
						
						if (airdash_value >= 1) {
							if (
								airdash_value >= airdash_limit_old &&
								players[idx].scout_airdash_count < airdash_limit_new
							) {
								airdash_value = (airdash_limit_old - 1);
							}
							
							if (
								airdash_value < airdash_limit_old &&
								players[idx].scout_airdash_count >= airdash_limit_new
							) {
								airdash_value = airdash_limit_old;
							}
						}
						
						players[idx].scout_airdash_value = airdash_value;
						
						if (airdash_value != GetEntProp(idx, Prop_Send, "m_iAirDash")) {
							SetEntProp(idx, Prop_Send, "m_iAirDash", airdash_value);
						}
					}
					
					{
						// bonk effect
						
						if (TF2_IsPlayerInCondition(idx, TFCond_Bonked)) {
							players[idx].bonk_cond_frame = GetGameTickCount();
						}
					}
					
					{
						// shortstop shove
						
						if (ItemIsEnabled("shortstop", idx)) {
							weapon = GetEntPropEnt(idx, Prop_Send, "m_hActiveWeapon");
							
							if (weapon > 0) {
								GetEntityClassname(weapon, class, sizeof(class));
								
								if (StrEqual(class, "tf_weapon_handgun_scout_primary")) {
									// disable secondary attack
									// this is somewhat broken, can still shove by holding m2 when reload ends
									// SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", (GetGameTime() + 1.0));
								}
							}
						}
					}
					
					{
						// guillotine recharge
						
						if (ItemIsEnabled("guillotine", idx)) {
							weapon = GetPlayerWeaponSlot(idx, TFWeaponSlot_Secondary);
							
							if (weapon > 0) {
								GetEntityClassname(weapon, class, sizeof(class));
								
								if (StrEqual(class, "tf_weapon_cleaver")) {
									timer = GetEntPropFloat(weapon, Prop_Send, "m_flEffectBarRegenTime");
									
									if (
										timer > 0.1 &&
										players[idx].cleaver_regen_time > 0.1 &&
										(players[idx].cleaver_regen_time - timer) > 1.49 &&
										(players[idx].cleaver_regen_time - timer) < 1.51
									) {
										timer = players[idx].cleaver_regen_time;
										SetEntPropFloat(weapon, Prop_Send, "m_flEffectBarRegenTime", timer);
									}
									
									players[idx].cleaver_regen_time = timer;
								}
							}
						}
					}
					
					{
						// sodapopper stuff
						
						if (ItemIsEnabled("sodapop", idx)) {
							weapon = GetPlayerWeaponSlot(idx, TFWeaponSlot_Primary);
							
							weapon = GetEntPropEnt(idx, Prop_Send, "m_hActiveWeapon");
							
							if (weapon > 0) {
								GetEntityClassname(weapon, class, sizeof(class));
								
								if (
									StrEqual(class, "tf_weapon_soda_popper") &&
									TF2_IsPlayerInCondition(idx, TFCond_CritHype) == false
								) {
									if (GetEntPropFloat(idx, Prop_Send, "m_flHypeMeter") >= 100.0) {
										TF2_AddCondition(idx, TFCond_CritHype, 10.0, 0);
									}
									
									if (
										weapon == GetEntPropEnt(idx, Prop_Send, "m_hActiveWeapon") &&
										GetEntProp(idx, Prop_Data, "m_nWaterLevel") <= 1 &&
										GetEntityMoveType(idx) == MOVETYPE_WALK
									) {
										// add hype according to speed
										
										GetEntPropVector(idx, Prop_Data, "m_vecVelocity", pos1);
										
										hype = GetVectorLength(pos1);
										hype = (hype * GetTickInterval());
										hype = (hype / GetConVarFloat(cvar_ref_tf_scout_hype_mod));
										hype = (hype + GetEntPropFloat(idx, Prop_Send, "m_flHypeMeter"));
										hype = (hype > 100.0 ? 100.0 : hype);
										
										SetEntPropFloat(idx, Prop_Send, "m_flHypeMeter", hype);
									}
								}
							}
						}
					}
				}
				
				if (TF2_GetPlayerClass(idx) == TFClass_Soldier) {
					{
						// beggars overload
						
						// overload is detected via rocket entity spawn/despawn and ammo change
						// pretty hacky but it works I guess
						
						weapon = GetPlayerWeaponSlot(idx, TFWeaponSlot_Primary);
						
						if (weapon > 0) {
							GetEntityClassname(weapon, class, sizeof(class));
							
							if (
								StrEqual(class, "tf_weapon_rocketlauncher") &&
								GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 730
							) {
								clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
								ammo = GetEntProp(idx, Prop_Send, "m_iAmmo", 4, 1);
								
								if (
									ItemIsEnabled("beggars", idx) &&
									players[idx].beggars_ammo == 3 &&
									clip == (players[idx].beggars_ammo - 1) &&
									rocket_create_entity == -1 &&
									(rocket_create_frame + 1) == GetGameTickCount() &&
									ammo > 0
								) {
									clip = (clip + 1);
									SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
									SetEntProp(idx, Prop_Send, "m_iAmmo", (ammo - 1), 4, 1);
								}
								
								players[idx].beggars_ammo = clip;
							}
						}
					}
				}
				
				if (TF2_GetPlayerClass(idx) == TFClass_Medic) {
					{
						// vitasaw charge store
						
						weapon = GetPlayerWeaponSlot(idx, TFWeaponSlot_Secondary);
						
						if (weapon > 0) {
							GetEntityClassname(weapon, class, sizeof(class));
							
							if (StrEqual(class, "tf_weapon_medigun")) {
								players[idx].medic_medigun_defidx = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
								players[idx].medic_medigun_charge = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel");
							}
						}
					}
				}
				
				if (TF2_GetPlayerClass(idx) == TFClass_Sniper) {
					{
						// sleeper teammate extinguish
						
						// shots are detected via ammo change, again pretty hacky
						// no lagcomp so a decently large hull trace is used instead
						
						weapon = GetPlayerWeaponSlot(idx, TFWeaponSlot_Primary);
						
						if (weapon > 0) {
							GetEntityClassname(weapon, class, sizeof(class));
							
							if (
								StrEqual(class, "tf_weapon_sniperrifle") &&
								GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 230
							) {
								ammo = GetEntProp(idx, Prop_Send, "m_iAmmo", 4, 1);
								
								if (
									ItemIsEnabled("sleeper", idx) &&
									ammo == (players[idx].sleeper_ammo - 1)
								) {
									GetClientEyePosition(idx, pos1);
									
									GetClientEyeAngles(idx, pos2);
									GetAngleVectors(pos2, pos2, NULL_VECTOR, NULL_VECTOR);
									ScaleVector(pos2, 10000.0);
									AddVectors(pos1, pos2, pos2);
									
									maxs[0] = 20.0;
									maxs[1] = 20.0;
									maxs[2] = 5.0;
									
									mins[0] = (0.0 - maxs[0]);
									mins[1] = (0.0 - maxs[1]);
									mins[2] = (0.0 - maxs[2]);
									
									TR_TraceHullFilter(pos1, pos2, mins, maxs, MASK_SOLID, TraceFilter_ExcludeSingle, idx);
									
									if (TR_DidHit()) {
										ent = TR_GetEntityIndex();
										
										if (
											ent >= 1 &&
											ent <= MaxClients &&
											GetClientTeam(ent) == GetClientTeam(idx) &&
											TF2_IsPlayerInCondition(ent, TFCond_OnFire)
										) {
											// this will remove fire and play the appropriate sound
											AcceptEntityInput(ent, "ExtinguishPlayer");
										}
									}
								}
								
								players[idx].sleeper_ammo = ammo;
							}
						}
					}
				}
				
				if (TF2_GetPlayerClass(idx) == TFClass_Spy) {
					{
						// dead ringer cloak meter mechanics
						
						if (players[idx].spy_is_feigning == false) {
							if (TF2_IsPlayerInCondition(idx, TFCond_DeadRingered)) {
								players[idx].spy_is_feigning = true;
							}
						} else {
							if (
								TF2_IsPlayerInCondition(idx, TFCond_Cloaked) == false &&
								TF2_IsPlayerInCondition(idx, TFCond_DeadRingered) == false
							) {
								players[idx].spy_is_feigning = false;
								
								if (ItemIsEnabled("ringer", idx)) {
									// when uncloaking, cloak is drained to 40%
									
									if (GetEntPropFloat(idx, Prop_Send, "m_flCloakMeter") > 40.0) {
										SetEntPropFloat(idx, Prop_Send, "m_flCloakMeter", 40.0);
									}
								}
							}
						}
						
						cloak = GetEntPropFloat(idx, Prop_Send, "m_flCloakMeter");
						
						if (ItemIsEnabled("ringer", idx)) {
							if (
								(cloak - players[idx].spy_cloak_meter) > 35.0 &&
								(players[idx].ammo_grab_frame + 1) == GetGameTickCount()
							) {
								weapon = GetPlayerWeaponSlot(idx, TFWeaponSlot_Building);
								
								if (weapon > 0) {
									GetEntityClassname(weapon, class, sizeof(class));
									
									if (
										StrEqual(class, "tf_weapon_invis") &&
										GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 59
									) {
										// ammo boxes only give 35% cloak max
										
										cloak = (players[idx].spy_cloak_meter + 35.0);
										SetEntPropFloat(idx, Prop_Send, "m_flCloakMeter", cloak);
									}
								}
							}
						}
						
						players[idx].spy_cloak_meter = cloak;
					}
					
					{
						// spycicle recharge
						
						if (ItemIsEnabled("spycicle", idx)) {
							weapon = GetPlayerWeaponSlot(idx, TFWeaponSlot_Melee);
							
							if (weapon > 0) {
								GetEntityClassname(weapon, class, sizeof(class));
								
								if (
									StrEqual(class, "tf_weapon_knife") &&
									GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 649
								) {
									timer = GetEntPropFloat(weapon, Prop_Send, "m_flKnifeMeltTimestamp");
									
									if (
										timer > 0.1 &&
										players[idx].icicle_regen_time > 0.1 &&
										players[idx].icicle_regen_time > timer &&
										(players[idx].ammo_grab_frame + 1) == GetGameTickCount()
									) {
										timer = players[idx].icicle_regen_time;
										SetEntPropFloat(weapon, Prop_Send, "m_flKnifeMeltTimestamp", timer);
									}
									
									players[idx].icicle_regen_time = timer;
								}
							}
						}
					}
				} else {
					// reset if player isn't spy
					players[idx].spy_is_feigning = false;
				}
				
				if (
					TF2_GetPlayerClass(idx) == TFClass_Soldier ||
					TF2_GetPlayerClass(idx) == TFClass_DemoMan
				) {
					{
						// zatoichi honorbound
						
						if (ItemIsEnabled("zatoichi", idx)) {
							weapon = GetEntPropEnt(idx, Prop_Send, "m_hActiveWeapon");
							
							if (weapon > 0) {
								GetEntityClassname(weapon, class, sizeof(class));
								
								if (StrEqual(class, "tf_weapon_katana")) {
									if (
										GetEntProp(idx, Prop_Send, "m_iKillCountSinceLastDeploy") == 0 &&
										GetGameTime() >= GetEntPropFloat(idx, Prop_Send, "m_flFirstPrimaryAttack") &&
										(GetGameTime() - players[idx].resupply_time) > 1.5
									) {
										// this cond is very convenient
										TF2_AddCondition(idx, TFCond_RestrictToMelee, 0.100, 0);
									}
								}
							}
						}
					}
					
					{
						// parachute redeploy & updraft
						
						if (TF2_IsPlayerInCondition(idx, TFCond_Parachute)) {
							players[idx].parachute_cond_time = GetGameTime();
							
							if (
								ItemIsEnabled("basejump", idx) &&
								TF2_IsPlayerInCondition(idx, TFCond_OnFire) &&
								GetEntProp(idx, Prop_Data, "m_nWaterLevel") == 0
							) {
								GetEntPropVector(idx, Prop_Data, "m_vecVelocity", pos1);
								
								if (pos1[2] < GetConVarFloat(cvar_ref_tf_parachute_maxspeed_onfire_z)) {
									pos1[2] = GetConVarFloat(cvar_ref_tf_parachute_maxspeed_onfire_z);
									TeleportEntity(idx, NULL_VECTOR, NULL_VECTOR, pos1);
								}
							}
						} else {
							if (
								TF2_IsPlayerInCondition(idx, TFCond_ParachuteDeployed) &&
								(GetGameTime() - players[idx].parachute_cond_time) > 0.2 &&
								ItemIsEnabled("basejump", idx)
							) {
								// this cond is what stops redeploy
								// tf_parachute_deploy_toggle_allowed can also be used
								TF2_RemoveCondition(idx, TFCond_ParachuteDeployed);
							}
						}
					}
				}
			} else {
				// reset if player is dead
				players[idx].spy_is_feigning = false;
				players[idx].scout_airdash_value = 0;
				players[idx].scout_airdash_count = 0;
			}
		}
	}
	
	// run every 3 frames
	if (frame % 3 == 0) {
		for (idx = 1; idx <= MaxClients; idx++) {
			if (
				IsClientInGame(idx) &&
				IsPlayerAlive(idx)
			) {
				{
					// fix weapons being invisible after sandman stun
					// this bug apparently existed before sandman nerf
					
					weapon = GetEntPropEnt(idx, Prop_Send, "m_hActiveWeapon");
					
					if (
						weapon > 0 &&
						(GetEntProp(weapon, Prop_Send, "m_fEffects") & EF_NODRAW) != 0 &&
						(GetGameTime() - players[idx].stunball_fix_time_bonk) < 10.0 &&
						TF2_IsPlayerInCondition(idx, TFCond_Dazed) == false
					) {
						if (players[idx].stunball_fix_time_wear == 0.0) {
							players[idx].stunball_fix_time_wear = GetGameTime();
						} else {
							if ((GetGameTime() - players[idx].stunball_fix_time_wear) > 0.100) {
								SetEntProp(weapon, Prop_Send, "m_fEffects", (GetEntProp(weapon, Prop_Send, "m_fEffects") & ~EF_NODRAW));
								
								players[idx].stunball_fix_time_bonk = 0.0;
								players[idx].stunball_fix_time_wear = 0.0;
							}
						}
					}
				}
			}
		}
	}
	
	// run every 66 frames (~1s)
	if (frame % 66 == 0) {
		{
			// set all the convars needed
			
			// weapon pickups are disabled to ensure attribute consistency
			SetConVarMaybe(cvar_ref_tf_dropped_weapon_lifetime, "0", GetConVarBool(cvar_enable));
			
			// these cvars are changed just-in-time, reset them
			SetConVarReset(cvar_ref_tf_airblast_cray);
			SetConVarReset(cvar_ref_tf_feign_death_duration);
			SetConVarReset(cvar_ref_tf_feign_death_speed_duration);
			SetConVarReset(cvar_ref_tf_feign_death_activate_damage_scale);
			SetConVarReset(cvar_ref_tf_feign_death_damage_scale);
			
			// these cvars are global, set them to the desired value
			SetConVarMaybe(cvar_ref_tf_bison_tick_time, "0.001", ItemIsEnabled("bison", 0));
			SetConVarMaybe(cvar_ref_tf_fireball_radius, "30.0", ItemIsEnabled("dragonfury", 0));
			SetConVarMaybe(cvar_ref_tf_parachute_aircontrol, "5", ItemIsEnabled("basejump", 0));
		}
	}
}

public void OnGameEvent(Event event, const char[] name, bool dontbroadcast) {
	int client;
	int attacker;
	int weapon;
	int health_cur;
	int health_max;
	char class[64];
	float charge;
	Event event1;
	
	if (StrEqual(name, "player_spawn")) {
		client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		{
			// apply attrib changes
			
			if (IsPlayerAlive(client)) {
				ItemPlayerApply(client);
				
				if (players[client].change) {
					// tf2 only respawns a player's weapon/wearable entities when those entities are different from
					// the ones that should be equipped, aka when the player changes class or equips a different weapon.
					// we manually force it to happen by removing the entities and respawning the player a few ticks later.
					
					PlayerRemoveEquipment(client);
					
					players[client].respawn = GetGameTickCount();
					players[client].change = false;
				}
			}
		}
		
		{
			// vitasaw charge apply
			
			if (
				ItemIsEnabled("vitasaw", client) &&
				IsPlayerAlive(client) &&
				TF2_GetPlayerClass(client) == TFClass_Medic &&
				GameRules_GetRoundState() == RoundState_RoundRunning
			) {
				weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				
				if (weapon > 0) {
					GetEntityClassname(weapon, class, sizeof(class));
					
					if (
						StrEqual(class, "tf_weapon_bonesaw") &&
						GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 173
					) {
						weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
						
						if (weapon > 0) {
							GetEntityClassname(weapon, class, sizeof(class));
							
							if (
								StrEqual(class, "tf_weapon_medigun") &&
								GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") < 0.01 &&
								GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == players[client].medic_medigun_defidx
							) {
								charge = players[client].medic_medigun_charge;
								charge = (charge > 0.20 ? 0.20 : charge);
								
								SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", charge);
							}
						}
					}
				}
			}
		}
	}
	
	if (StrEqual(name, "player_death")) {
		client = GetClientOfUserId(GetEventInt(event, "userid"));
		attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		{
			// zatoichi heal on kill
			
			if (
				client > 0 &&
				client < MaxClients &&
				attacker > 0 &&
				attacker < MaxClients &&
				IsClientInGame(client) &&
				IsClientInGame(attacker) &&
				client != attacker &&
				(GetEventInt(event, "death_flags") & TF_DEATH_FEIGN_DEATH) == 0 &&
				GetEventInt(event, "inflictor_entindex") == attacker && // make sure it wasn't a "finished off" kill
				IsPlayerAlive(attacker)
			) {
				weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
				
				if (weapon > 0) {
					GetEntityClassname(weapon, class, sizeof(class));
					
					if (
						ItemIsEnabled("zatoichi", attacker) &&
						StrEqual(class, "tf_weapon_katana")
					) {
						health_cur = GetClientHealth(attacker);
						health_max = SDKCall(sdkcall_GetMaxHealth, attacker);
						
						if (health_cur < health_max) {
							SetEntProp(attacker, Prop_Send, "m_iHealth", health_max);
							
							event1 = CreateEvent("player_healonhit", true);
							
							SetEventInt(event1, "amount", health_max);
							SetEventInt(event1, "entindex", attacker);
							SetEventInt(event1, "weapon_def_index", -1);
							
							FireEvent(event1);
						}
					}
				}
			}
		}
	}
	
	if (StrEqual(name, "post_inventory_application")) {
		client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		// keep track of resupply time
		players[client].resupply_time = GetGameTime();
	}
	
	if (StrEqual(name, "item_pickup")) {
		client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		GetEventString(event, "item", class, sizeof(class));
		
		if (
			StrContains(class, "ammopack_") == 0 || // normal map pickups
			StrContains(class, "tf_ammo_") == 0 // ammo dropped on death
		) {
			players[client].ammo_grab_frame = GetGameTickCount();
		}
	}
}

public Action OnSoundNormal(int clients[MAXPLAYERS], int &clients_num, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundentry[PLATFORM_MAX_PATH], int &seed) {
	int idx;
	
	if (StrContains(sample, "player/pl_impact_stun") == 0) {
		for (idx = 1; idx < MaxClients; idx++) {
			if (
				ItemIsEnabled("sandman", idx) &&
				players[idx].projectile_touch_frame == GetGameTickCount()
			) {
				// cancel duplicate sandman stun sounds
				// we cancel the default stun and apply our own
				return Plugin_Stop;
			}
			
			if (
				ItemIsEnabled("bonk", idx) &&
				players[idx].bonk_cond_frame == GetGameTickCount()
			) {
				// cancel bonk stun sound
				return Plugin_Stop;
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnClientConnected(int client) {
	int idx;
	
	for (idx = 0; idx < ITEMS_MAX; idx++) {
		players[client].items_pick[idx] = true;
	}
	
	// apply item picks
	ItemPlayerApply(client);
	players[client].change = IsClientInGame(client);
	
	// reset these per player
	players[client].respawn = 0;
	players[client].resupply_time = 0.0;
	players[client].medic_medigun_defidx = 0;
	players[client].medic_medigun_charge = 0.0;
	players[client].parachute_cond_time = 0.0;
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_TraceAttack, SDKHookCB_TraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, SDKHookCB_OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlive, SDKHookCB_OnTakeDamageAlive);
}

public void OnClientCookiesCached(int client) {
	if (IsFakeClient(client) == false) {
		ItemCookieLoad(client);
	}
}

public void OnEntityCreated(int entity, const char[] class) {
	if (entity < 0 || entity >= 2048) {
		// sourcemod calls this with entrefs for non-networked ents ??
		return;
	}
	
	entities[entity].exists = true;
	entities[entity].spawn_time = 0.0;
	entities[entity].is_demo_shield = false;
	
	if (StrEqual(class, "tf_wearable_demoshield")) {
		entities[entity].is_demo_shield = true;
	}
	
	if (
		StrEqual(class, "tf_projectile_stun_ball") ||
		StrEqual(class, "tf_projectile_energy_ring") ||
		StrEqual(class, "tf_projectile_cleaver")
	) {
		SDKHook(entity, SDKHook_Spawn, SDKHookCB_Spawn);
		SDKHook(entity, SDKHook_SpawnPost, SDKHookCB_SpawnPost);
		SDKHook(entity, SDKHook_Touch, SDKHookCB_Touch);
	}
	
	if (StrEqual(class, "tf_projectile_rocket")) {
		// keep track of when rockets are created
		
		rocket_create_entity = entity;
		rocket_create_frame = GetGameTickCount();
		
		DHookEntity(dhook_CTFBaseRocket_GetRadius, true, entity, _, DHookCallback_CTFBaseRocket_GetRadius);
	}
	
	if (
		StrEqual(class, "tf_weapon_flamethrower") ||
		StrEqual(class, "tf_weapon_rocketlauncher_fireball")
	) {
		DHookEntity(dhook_CTFWeaponBase_SecondaryAttack, false, entity, _, DHookCallback_CTFWeaponBase_SecondaryAttack);
	}
	
	if (
		StrEqual(class, "tf_weapon_mechanical_arm")
	) {
		DHookEntity(dhook_CTFWeaponBase_PrimaryAttack, false, entity, _, DHookCallback_CTFWeaponBase_PrimaryAttack);
		DHookEntity(dhook_CTFWeaponBase_SecondaryAttack, false, entity, _, DHookCallback_CTFWeaponBase_SecondaryAttack);
	}
}

public void OnEntityDestroyed(int entity) {
	if (entity < 0 || entity >= 2048) {
		return;
	}
	
	entities[entity].exists = false;
	
	if (
		rocket_create_entity == entity &&
		rocket_create_frame == GetGameTickCount()
	) {
		// this rocket was created and destroyed on the same frame
		// this likely means a beggars overload happened
		
		rocket_create_entity = -1;
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition) {
	float cloak;
	
	// this function is called on a per-frame basis
	// if two conds are added within the same game frame,
	// they will both be present when this is called for each
	
	{
		// bonk cancel stun
		
		if (
			ItemIsEnabled("bonk", client) &&
			condition == TFCond_Dazed &&
			(players[client].bonk_cond_frame + 1) == GetGameTickCount()
		) {
			TF2_RemoveCondition(client, TFCond_Dazed);
		}
	}
	
	{
		// dead ringer stuff
		
		if (
			ItemIsEnabled("ringer", client) &&
			TF2_GetPlayerClass(client) == TFClass_Spy
		) {
			if (condition == TFCond_DeadRingered) {
				cloak = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
				
				if (
					cloak > 49.0 &&
					cloak < 51.0
				) {
					// undo 50% drain on activated
					SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 100.0);
				}
			}
			
			if (TF2_IsPlayerInCondition(client, TFCond_DeadRingered)) {
				if (condition == TFCond_SpeedBuffAlly) {
					// cancel speed buff
					// sound still plays clientside :(
					
					TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
				}
				
				if (
					condition == TFCond_AfterburnImmune &&
					TF2_IsPlayerInCondition(client, TFCond_FireImmune) == false // didn't use spycicle
				) {
					// grant aferburn immunity for a bit
					
					// this may look like it overrides spycicle afterburn immune in some cases, but it doesn't
					// this function is not called when a condition is gained that we already had before
					
					TF2_RemoveCondition(client, TFCond_AfterburnImmune);
					TF2_AddCondition(client, TFCond_AfterburnImmune, 0.5, 0);
				}
			}
		}
	}
	
	{
		// spycicle fire immune
		
		if (
			ItemIsEnabled("spycicle", client) &&
			TF2_GetPlayerClass(client) == TFClass_Spy &&
			condition == TFCond_FireImmune &&
			TF2_IsPlayerInCondition(client, TFCond_AfterburnImmune)
		) {
			TF2_RemoveCondition(client, TFCond_FireImmune);
			TF2_RemoveCondition(client, TFCond_AfterburnImmune);
			
			TF2_AddCondition(client, TFCond_FireImmune, 3.0, 0);
		}
	}
}

public Action TF2Items_OnGiveNamedItem(int client, char[] class, int index, Handle& item) {
	Handle item1;
	
	if (
		ItemIsEnabled("ambassador", client) &&
		StrEqual(class, "tf_weapon_revolver") &&
		(index == 61 || index == 1006)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 1);
		TF2Items_SetAttribute(item1, 0, 868, 0.0); // crit dmg falloff
	}
	
	if (
		ItemIsEnabled("atomizer", client) &&
		StrEqual(class, "tf_weapon_bat") &&
		(index == 450)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 4);
		TF2Items_SetAttribute(item1, 0, 5, 1.30); // fire rate penalty
		TF2Items_SetAttribute(item1, 1, 138, 0.80); // dmg penalty vs players
		TF2Items_SetAttribute(item1, 2, 250, 0.0); // air dash count
		TF2Items_SetAttribute(item1, 3, 773, 1.0); // single wep deploy time increased
	}
	
	if (
		ItemIsEnabled("axtinguish", client) &&
		StrEqual(class, "tf_weapon_fireaxe") &&
		(index == 38 || index == 457 || index == 1000)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 7);
		TF2Items_SetAttribute(item1, 0, 1, 1.00); // damage penalty
		TF2Items_SetAttribute(item1, 1, 15, 0.0); // crit mod disabled
		TF2Items_SetAttribute(item1, 2, 20, 1.0); // crit vs burning players
		TF2Items_SetAttribute(item1, 3, 21, 0.50); // dmg penalty vs nonburning
		TF2Items_SetAttribute(item1, 4, 22, 1.0); // no crit vs nonburning
		TF2Items_SetAttribute(item1, 5, 772, 1.00); // single wep holster time increased
		TF2Items_SetAttribute(item1, 6, 2067, 0.0); // attack minicrits and consumes burning
	}
	
	if (
		ItemIsEnabled("babyface", client) &&
		StrEqual(class, "tf_weapon_pep_brawler_blaster")
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 2);
		TF2Items_SetAttribute(item1, 0, 419, 25.0); // hype resets on jump
		TF2Items_SetAttribute(item1, 1, 733, 0.0); // lose hype on take damage
	}
	
	if (
		ItemIsEnabled("beggars", client) &&
		StrEqual(class, "tf_weapon_rocketlauncher") &&
		(index == 730)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 1);
		TF2Items_SetAttribute(item1, 0, 100, 1.0); // blast radius decreased
	}
	
	if (
		ItemIsEnabled("booties", client) &&
		StrEqual(class, "tf_wearable") &&
		(index == 405 || index == 608)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 2);
		TF2Items_SetAttribute(item1, 0, 107, 1.10); // move speed bonus
		TF2Items_SetAttribute(item1, 1, 788, 1.00); // move speed bonus shield required
	}
	
	if (
		ItemIsEnabled("caber", client) &&
		StrEqual(class, "tf_weapon_stickbomb")
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 2);
		TF2Items_SetAttribute(item1, 0, 5, 1.00); // fire rate penalty
		TF2Items_SetAttribute(item1, 1, 773, 1.00); // single wep deploy time increased
	}
	
	if (
		ItemIsEnabled("cannon", client) &&
		StrEqual(class, "tf_weapon_cannon")
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 1);
		TF2Items_SetAttribute(item1, 0, 103, 1.50); // projectile speed increased
	}
	
	if (
		ItemIsEnabled("degreaser", client) &&
		StrEqual(class, "tf_weapon_flamethrower") &&
		(index == 215)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 6);
		TF2Items_SetAttribute(item1, 0, 1, 0.90); // damage penalty
		TF2Items_SetAttribute(item1, 1, 72, 0.75); // weapon burn dmg reduced
		TF2Items_SetAttribute(item1, 2, 170, 1.00); // airblast cost increased
		TF2Items_SetAttribute(item1, 3, 178, 0.35); // deploy time decreased
		TF2Items_SetAttribute(item1, 4, 199, 1.00); // switch from wep deploy time decreased
		TF2Items_SetAttribute(item1, 5, 547, 1.00); // single wep deploy time decreased
	}
	
	if (
		ItemIsEnabled("enforcer", client) &&
		StrEqual(class, "tf_weapon_revolver") &&
		(index == 460)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 2);
		TF2Items_SetAttribute(item1, 0, 410, 1.0); // damage bonus while disguised
		TF2Items_SetAttribute(item1, 1, 797, 0.0); // dmg pierces resists absorbs
	}
	
	if (
		ItemIsEnabled("equalizer", client) &&
		StrEqual(class, "tf_weapon_shovel") &&
		(index == 128 || index == 775)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 4);
		TF2Items_SetAttribute(item1, 0, 236, 1.0); // mod weapon blocks healing
		TF2Items_SetAttribute(item1, 1, 414, 0.0); // self mark for death
		TF2Items_SetAttribute(item1, 2, 740, 1.0); // reduced healing from medics
		
		if (index == 128) {
			TF2Items_SetAttribute(item1, 3, 115, 2.0); // mod shovel damage boost
		} else {
			TF2Items_SetAttribute(item1, 3, 235, 2.0); // mod shovel speed boost
		}
	}
	
	if (
		ItemIsEnabled("eternal", client) &&
		StrEqual(class, "tf_weapon_knife") &&
		(index == 225 || index == 574)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 2);
		TF2Items_SetAttribute(item1, 0, 34, 1.00); // mult cloak meter consume rate
		TF2Items_SetAttribute(item1, 1, 155, 1.00); // cannot disguise
	}
	
	if (
		ItemIsEnabled("eviction", client) &&
		StrEqual(class, "tf_weapon_fists") &&
		(index == 426)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 2);
		TF2Items_SetAttribute(item1, 0, 412, 1.20); // dmg taken increased
		TF2Items_SetAttribute(item1, 1, 855, 0.0); // mod maxhealth drain rate
	}
	
	if (
		ItemIsEnabled("fiststeel", client) &&
		StrEqual(class, "tf_weapon_fists") &&
		(index == 331)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 2);
		TF2Items_SetAttribute(item1, 0, 853, 1.0); // mult patient overheal penalty active
		TF2Items_SetAttribute(item1, 1, 854, 1.0); // mult health fromhealers penalty active
	}
	
	if (
		ItemIsEnabled("gardener", client) &&
		StrEqual(class, "tf_weapon_shovel") &&
		(index == 416)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 1);
		TF2Items_SetAttribute(item1, 0, 5, 1.0); // fire rate penalty
	}
	
	if (
		ItemIsEnabled("glovesru", client) &&
		StrEqual(class, "tf_weapon_fists") &&
		(index == 239 || index == 1084 || index == 1100)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 4);
		TF2Items_SetAttribute(item1, 0, 1, 0.75); // damage penalty
		TF2Items_SetAttribute(item1, 1, 414, 3.0); // self mark for death
		TF2Items_SetAttribute(item1, 2, 772, 1.5); // single wep holster time increased
		TF2Items_SetAttribute(item1, 3, 855, 0.0); // mod maxhealth drain rate
	}
	
	if (
		ItemIsEnabled("guillotine", client) &&
		StrEqual(class, "tf_weapon_cleaver")
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 1);
		TF2Items_SetAttribute(item1, 0, 437, 65536.0); // crit vs stunned players
	}
	
	if (
		ItemIsEnabled("liberty", client) &&
		StrEqual(class, "tf_weapon_rocketlauncher") &&
		(index == 414)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 4);
		TF2Items_SetAttribute(item1, 0, 1, 1.00); // damage penalty
		TF2Items_SetAttribute(item1, 1, 3, 0.75); // clip size penalty
		TF2Items_SetAttribute(item1, 2, 4, 1.00); // clip size bonus
		TF2Items_SetAttribute(item1, 3, 135, 1.00); // rocket jump damage reduction
	}
	
	if (
		ItemIsEnabled("lochload", client) &&
		StrEqual(class, "tf_weapon_grenadelauncher") &&
		(index == 308)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 2);
		TF2Items_SetAttribute(item1, 0, 2, 1.20); // damage bonus
		TF2Items_SetAttribute(item1, 1, 137, 1.00); // dmg bonus vs buildings
	}
	
	if (
		ItemIsEnabled("ringer", client) &&
		StrEqual(class, "tf_weapon_invis") &&
		(index == 59)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 5);
		TF2Items_SetAttribute(item1, 0, 35, 1.8); // mult cloak meter regen rate
		TF2Items_SetAttribute(item1, 1, 82, 1.6); // cloak consume rate increased
		TF2Items_SetAttribute(item1, 2, 83, 1.0); // cloak consume rate decreased
		TF2Items_SetAttribute(item1, 3, 726, 0.1); // cloak consume on feign death activate
		TF2Items_SetAttribute(item1, 4, 810, 0.0); // mod cloak no regen from items
	}
	
	if (
		ItemIsEnabled("shortstop", client) &&
		StrEqual(class, "tf_weapon_handgun_scout_primary")
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 3);
		TF2Items_SetAttribute(item1, 0, 241, 1.0); // reload time increased hidden
		TF2Items_SetAttribute(item1, 1, 534, 1.4); // airblast vulnerability multiplier hidden
		TF2Items_SetAttribute(item1, 2, 535, 1.4); // damage force increase hidden
	}
	
	if (
		ItemIsEnabled("sleeper", client) &&
		StrEqual(class, "tf_weapon_sniperrifle") &&
		(index == 230)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 2);
		TF2Items_SetAttribute(item1, 0, 42, 0.0); // sniper no headshots
		TF2Items_SetAttribute(item1, 1, 175, 0.0); // jarate duration
	}
	
	if (
		ItemIsEnabled("sodapop", client) &&
		StrEqual(class, "tf_weapon_soda_popper")
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 2);
		TF2Items_SetAttribute(item1, 0, 15, 0.0); // crit mod disabled
		TF2Items_SetAttribute(item1, 1, 793, 0.0); // hype on damage
	}
	
	if (
		ItemIsEnabled("solemn", client) &&
		StrEqual(class, "tf_weapon_bonesaw") &&
		(index == 413)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 1);
		TF2Items_SetAttribute(item1, 0, 5, 1.0); // fire rate penalty
	}
	
	if (
		ItemIsEnabled("spycicle", client) &&
		StrEqual(class, "tf_weapon_knife") &&
		(index == 649)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 1);
		TF2Items_SetAttribute(item1, 0, 156, 1.0); // silent killer
	}
	
	if (
		ItemIsEnabled("stkjumper", client) &&
		StrEqual(class, "tf_weapon_pipebomblauncher") &&
		(index == 265)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 1);
		TF2Items_SetAttribute(item1, 0, 89, 0.0); // max pipebombs decreased
	}
	
	if (
		ItemIsEnabled("targe", client) &&
		StrEqual(class, "tf_wearable_demoshield") &&
		(index == 131)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 2);
		TF2Items_SetAttribute(item1, 0, 64, 0.6); // dmg taken from blast reduced
		TF2Items_SetAttribute(item1, 1, 527, 1.0); // afterburn immunity
	}
	
	if (
		ItemIsEnabled("turner", client) &&
		StrEqual(class, "tf_wearable_demoshield") &&
		(index == 1099)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 1);
		TF2Items_SetAttribute(item1, 0, 676, 0.0); // lose demo charge on damage when charging
	}
	
	if (
		ItemIsEnabled("vitasaw", client) &&
		StrEqual(class, "tf_weapon_bonesaw") &&
		(index == 173)
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 2);
		TF2Items_SetAttribute(item1, 0, 188, 20.0); // preserve ubercharge (doesn't work)
		TF2Items_SetAttribute(item1, 1, 811, 0.0); // ubercharge preserved on spawn max
	}
	
	if (
		ItemIsEnabled("zatoichi", client) &&
		StrEqual(class, "tf_weapon_katana")
	) {
		item1 = TF2Items_CreateItem(0);
		TF2Items_SetFlags(item1, (OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES));
		TF2Items_SetNumAttributes(item1, 5);
		TF2Items_SetAttribute(item1, 0, 15, 1.0); // crit mod disabled
		TF2Items_SetAttribute(item1, 1, 199, 0.58); // switch from wep deploy time decreased
		TF2Items_SetAttribute(item1, 2, 220, 0.0); // restore health on kill
		TF2Items_SetAttribute(item1, 3, 226, 0.0); // honorbound
		TF2Items_SetAttribute(item1, 4, 547, 0.58); // single wep deploy time decreased
		
		// TF2Items_SetAttribute(item1, 0, 781, 0.0); // is a sword
	}
	
	if (item1 != null) {
		item = item1;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

Action SDKHookCB_Spawn(int entity) {
	char class[64];
	
	GetEntityClassname(entity, class, sizeof(class));
	
	if (StrContains(class, "tf_projectile_") == 0) {
		entities[entity].spawn_time = GetGameTime();
	}
}

void SDKHookCB_SpawnPost(int entity) {
	char class[64];
	float maxs[3];
	float mins[3];
	int owner;
	int weapon;
	
	// for some reason this is called twice
	// on the first call m_hLauncher is empty??
	
	GetEntityClassname(entity, class, sizeof(class));
	
	{
		// bison/pomson hitboxes
		
		if (StrEqual(class, "tf_projectile_energy_ring")) {
			owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");
			
			if (
				owner > 0 &&
				weapon > 0
			) {
				GetEntityClassname(weapon, class, sizeof(class));
				
				if (
					(ItemIsEnabled("bison", owner) && StrEqual(class, "tf_weapon_raygun")) ||
					(ItemIsEnabled("pomson", owner) && StrEqual(class, "tf_weapon_drg_pomson"))
				) {
					maxs[0] = 2.0;
					maxs[1] = 2.0;
					maxs[2] = 10.0;
					
					mins[0] = (0.0 - maxs[0]);
					mins[1] = (0.0 - maxs[1]);
					mins[2] = (0.0 - maxs[2]);
					
					SetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);
					SetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
					
					SetEntProp(entity, Prop_Send, "m_usSolidFlags", (GetEntProp(entity, Prop_Send, "m_usSolidFlags") | FSOLID_USE_TRIGGER_BOUNDS));
					SetEntProp(entity, Prop_Send, "m_triggerBloat", 24);
				}
			}
		}
	}
}

Action SDKHookCB_Touch(int entity, int other) {
	char class[64];
	int owner;
	int weapon;
	
	GetEntityClassname(entity, class, sizeof(class));
	
	{
		// projectile touch
		
		if (StrContains(class, "tf_projectile_") == 0) {
			if (
				other >= 1 &&
				other <= MaxClients
			) {
				players[other].projectile_touch_frame = GetGameTickCount();
				players[other].projectile_touch_entity = entity;
			}
		}
	}
	
	{
		// pomson pass thru team
		
		if (StrEqual(class, "tf_projectile_energy_ring")) {
			if (
				other >= 1 &&
				other <= MaxClients
			) {
				owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
				weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");
				
				if (
					owner > 0 &&
					weapon > 0
				) {
					GetEntityClassname(weapon, class, sizeof(class));
					
					if (StrEqual(class, "tf_weapon_drg_pomson")) {
						if (
							ItemIsEnabled("pomson", owner) &&
							TF2_GetClientTeam(owner) == TF2_GetClientTeam(other)
						) {
							return Plugin_Handled;
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

Action SDKHookCB_TraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup) {
	if (
		victim >= 1 && victim <= MaxClients &&
		attacker >= 1 && attacker <= MaxClients
	) {
		if (
			hitgroup == 1 &&
			(
				(damagetype & DMG_USE_HITLOCATIONS) != 0 || // for ambassador
				TF2_GetPlayerClass(attacker) == TFClass_Sniper // for sydney sleeper
			)
		) {
			players[attacker].headshot_frame = GetGameTickCount();
		}
	}
	
	return Plugin_Continue;
}

Action SDKHookCB_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageforce[3], float damageposition[3], int damagecustom) {
	int idx;
	char class[64];
	float pos1[3];
	float pos2[3];
	float stun_amt;
	float stun_dur;
	int stun_fls;
	float charge;
	float damage1;
	int health_cur;
	int health_max;
	int weapon1;
	
	if (
		victim >= 1 &&
		victim <= MaxClients
	) {
		// damage from any source
		
		{
			// dead ringer cvars set
			
			if (TF2_GetPlayerClass(victim) == TFClass_Spy) {
				weapon1 = GetPlayerWeaponSlot(victim, TFWeaponSlot_Building);
				
				if (weapon1 > 0) {
					GetEntityClassname(weapon1, class, sizeof(class));
					
					if (
						StrEqual(class, "tf_weapon_invis") &&
						GetEntProp(weapon1, Prop_Send, "m_iItemDefinitionIndex") == 59
					) {
						if (ItemIsEnabled("ringer", victim)) {
							SetConVarFloat(cvar_ref_tf_feign_death_duration, 4.0);
							SetConVarFloat(cvar_ref_tf_feign_death_speed_duration, 4.0);
							SetConVarFloat(cvar_ref_tf_feign_death_activate_damage_scale, 0.10);
							SetConVarFloat(cvar_ref_tf_feign_death_damage_scale, 0.20);
						} else {
							SetConVarReset(cvar_ref_tf_feign_death_duration);
							SetConVarReset(cvar_ref_tf_feign_death_speed_duration);
							SetConVarReset(cvar_ref_tf_feign_death_activate_damage_scale);
							SetConVarReset(cvar_ref_tf_feign_death_damage_scale);
						}
					}
				}
			}
		}
		
		{
			// turner charge loss on damage taken
			
			if (
				ItemIsEnabled("turner", victim) &&
				victim != attacker &&
				(damagetype & DMG_FALL) == 0 &&
				TF2_GetPlayerClass(victim) == TFClass_DemoMan &&
				TF2_IsPlayerInCondition(victim, TFCond_Charging)
			) {
				for (idx = (MaxClients + 1); idx < 2048; idx++) {
					if (
						entities[idx].exists &&
						entities[idx].is_demo_shield &&
						IsValidEntity(idx)
					) {
						GetEntityClassname(idx, class, sizeof(class));
						
						if (
							StrEqual(class, "tf_wearable_demoshield") &&
							GetEntPropEnt(idx, Prop_Send, "m_hOwnerEntity") == victim &&
							GetEntProp(idx, Prop_Send, "m_iItemDefinitionIndex") == 1099
						) {
							charge = GetEntPropFloat(victim, Prop_Send, "m_flChargeMeter");
							
							charge = (charge - damage);
							charge = (charge < 0.0 ? 0.0 : charge);
							
							SetEntPropFloat(victim, Prop_Send, "m_flChargeMeter", charge);
							
							break;
						}
					}
				}
			}
		}
	}
	
	if (
		victim >= 1 && victim <= MaxClients &&
		attacker >= 1 && attacker <= MaxClients
	) {
		// damage from players only
		
		if (weapon > MaxClients) {
			GetEntityClassname(weapon, class, sizeof(class));
			
			{
				// caber damage
				
				if (
					ItemIsEnabled("caber", attacker) &&
					StrEqual(class, "tf_weapon_stickbomb")
				) {
					if (
						damagecustom == TF_DMG_CUSTOM_NONE &&
						damage == 55.0
					) {
						// melee damage is always 35
						damage = 35.0;
						return Plugin_Changed;
					}
					
					if (damagecustom == TF_DMG_CUSTOM_STICKBOMB_EXPLOSION) {
						// base explosion is 100 damage
						damage = 100.0;
						
						if (
							victim != attacker &&
							(damagetype & DMG_CRIT) == 0
						) {
							GetClientEyePosition(attacker, pos1);
							
							GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos2);
							
							pos2[2] += PLAYER_CENTER_HEIGHT;
							
							// ghetto ramp up calculation
							// current tf2 applies 10% ramp up, we apply ~37% extra here (old was 50%)
							damage = (damage * (1.0 + (0.37 * (1.0 - (GetVectorDistance(pos1, pos2) / 512.0)))));
						}
						
						return Plugin_Changed;
					}
				}
			}
			
			{
				// cannon impact damage
				
				if (
					ItemIsEnabled("cannon", attacker) &&
					StrEqual(class, "tf_weapon_cannon")
				) {
					if (
						damagecustom == TF_DMG_CUSTOM_CANNONBALL_PUSH &&
						damage > 20.0 &&
						damage < 51.0
					) {
						damage = 60.0;
						return Plugin_Changed;
					}
				}
			}
			
			{
				// ambassador headshot crits
				
				if (
					ItemIsEnabled("ambassador", attacker) &&
					StrEqual(class, "tf_weapon_revolver") &&
					players[attacker].headshot_frame == GetGameTickCount() &&
					(
						GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 61 ||
						GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 1006
					)
				) {
					damagetype = (damagetype | DMG_CRIT);
					return Plugin_Changed;
				}
			}
			
			{
				// enforcer damage bonus
				// the old attrib doesnt work :(
				
				if (
					ItemIsEnabled("enforcer", attacker) &&
					StrEqual(class, "tf_weapon_revolver") &&
					GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 460
				) {
					if (TF2_IsPlayerInCondition(attacker, TFCond_Disguised) == false) {
						damage = (damage * 1.20);
						return Plugin_Changed;
					}
				}
			}
			
			{
				// equalizer damage bonus
				
				if (
					ItemIsEnabled("equalizer", attacker) &&
					StrEqual(class, "tf_weapon_shovel") &&
					damagecustom == TF_DMG_CUSTOM_PICKAXE &&
					(
						GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 128 ||
						GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 775
					)
				) {
					health_cur = GetClientHealth(attacker);
					health_max = SDKCall(sdkcall_GetMaxHealth, attacker);
					
					damage = (damage * ValveRemapVal(float(health_cur), 0.0, float(health_max), 1.65, 0.5));
					
					return Plugin_Changed;
				}
			}
			
			{
				// reserve airblast minicrits
				
				if (
					ItemIsEnabled("reserve", attacker) &&
					StrContains(class, "tf_weapon_shotgun") == 0 &&
					GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 415
				) {
					if (
						(GetEntityFlags(victim) & FL_ONGROUND) == 0 &&
						GetEntProp(victim, Prop_Data, "m_nWaterLevel") == 0 &&
						TF2_IsPlayerInCondition(victim, TFCond_KnockedIntoAir) == true &&
						TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeathSilent) == false
					) {
						// seems to be the best way to force a minicrit
						TF2_AddCondition(victim, TFCond_MarkedForDeathSilent, 0.001, 0);
					}
				}
			}
			
			{
				// soda popper minicrits
				
				if (
					ItemIsEnabled("sodapop", attacker) &&
					TF2_IsPlayerInCondition(attacker, TFCond_CritHype) == true &&
					TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeathSilent) == false
				) {
					TF2_AddCondition(victim, TFCond_MarkedForDeathSilent, 0.001, 0);
				}
			}
			
			{
				// sandman stun
				
				if (
					ItemIsEnabled("sandman", attacker) &&
					StrEqual(class, "tf_weapon_bat_wood") &&
					damagecustom == TF_DMG_CUSTOM_BASEBALL
				) {
					if (players[victim].projectile_touch_frame == GetGameTickCount()) {
						players[victim].projectile_touch_frame = 0;
						
						TF2_RemoveCondition(victim, TFCond_Dazed);
						
						if (GetEntProp(victim, Prop_Data, "m_nWaterLevel") != 3) {
							// exact replica of the original stun time formula as far as I can tell (from the source leak)
							
							stun_amt = (GetGameTime() - entities[players[victim].projectile_touch_entity].spawn_time);
							
							if (stun_amt > 1.0) stun_amt = 1.0;
							
							if (stun_amt > 0.1) {
								stun_dur = stun_amt;
								stun_dur = (stun_dur * 6.0);
								
								if ((damagetype & DMG_CRIT) != 0) {
									stun_dur = (stun_dur + 2.0);
								}
								
								stun_fls = TF_STUNFLAGS_SMALLBONK;
								
								if (stun_amt >= 1.0) {
									// moonshot!
									
									stun_dur = (stun_dur + 1.0);
									stun_fls = TF_STUNFLAGS_BIGBONK;
									
									if (GetConVarBool(cvar_extras)) {
										SetHudTextParams(-1.0, 0.09, 4.0, 255, 255, 255, 255, 2, 0.5, 0.01, 1.0);
										
										for (idx = 1; idx < MaxClients; idx++) {
											if (IsClientInGame(idx)) {
												ShowSyncHudText(idx, hudsync, "%N just landed a MOONSHOT on %N !", attacker, victim);
											}
										}
									}
								}
								
								TF2_StunPlayer(victim, stun_dur, 0.5, stun_fls, attacker);
								
								players[victim].stunball_fix_time_bonk = GetGameTime();
								players[victim].stunball_fix_time_wear = 0.0;
							}
						}
					}
					
					if (damage == 22.5) {
						// always deal 15 impact damage at any range
						damage = 15.0;
					}
					
					return Plugin_Changed;
				}
			}
			
			{
				// sleeper jarate mechanics
				
				if (
					ItemIsEnabled("sleeper", attacker) &&
					StrEqual(class, "tf_weapon_sniperrifle") &&
					GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 230
				) {
					if (
						GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") > 0.1 &&
						PlayerIsInvulnerable(victim) == false
					) {
						charge = GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage");
						
						// this should cause a jarate application
						players[attacker].sleeper_piss_frame = GetGameTickCount();
						players[attacker].sleeper_piss_duration = ValveRemapVal(charge, 50.0, 150.0, 2.0, 8.0);
						players[attacker].sleeper_piss_explode = false;
						
						if (
							GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") > 149.0 ||
							players[attacker].headshot_frame == GetGameTickCount()
						) {
							// this should also cause a jarate explosion
							players[attacker].sleeper_piss_explode = true;
						}
					}
					
					// disable headshot crits
					// ...is this even needed?
					if (damagetype & DMG_CRIT != 0) {
						damagetype = (damagetype & ~DMG_CRIT);
						return Plugin_Changed;
					}
				}
			}
			
			{
				// zatoichi duels
				
				if (StrEqual(class, "tf_weapon_katana")) {
					weapon1 = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
					
					if (weapon1 > 0) {
						GetEntityClassname(weapon1, class, sizeof(class));
						
						if (StrEqual(class, "tf_weapon_katana")) {
							if (
								ItemIsEnabled("zatoichi", attacker) ||
								ItemIsEnabled("zatoichi", victim)
							) {
								damage1 = (float(GetEntProp(victim, Prop_Send, "m_iHealth")) * 3.0);
								
								if (damage1 > damage) {
									damage = damage1;
								}
								
								damagetype = (damagetype | DMG_DONT_COUNT_DAMAGE_TOWARDS_CRIT_RATE);
								
								return Plugin_Changed;
							}
						}
					}
					
					return Plugin_Continue;
				}
			}
			
			{
				// guillotine minicrits
				
				if (
					ItemIsEnabled("guillotine", attacker) &&
					StrEqual(class, "tf_weapon_cleaver") &&
					damage > 20.0 // don't count bleed damage
				) {
					if (
						players[victim].projectile_touch_frame == GetGameTickCount() &&
						(GetGameTime() - entities[players[victim].projectile_touch_entity].spawn_time) >= 1.0
					) {
						TF2_AddCondition(victim, TFCond_MarkedForDeathSilent, 0.001, 0);
					}
					
					return Plugin_Continue;
				}
			}
			
			if (inflictor > MaxClients) {
				GetEntityClassname(inflictor, class, sizeof(class));
				
				{
					// bison/pomson stuff
					
					if (StrEqual(class, "tf_projectile_energy_ring")) {
						GetEntityClassname(weapon, class, sizeof(class));
						
						if (
							(ItemIsEnabled("bison", attacker) && StrEqual(class, "tf_weapon_raygun")) ||
							(ItemIsEnabled("pomson", attacker) && StrEqual(class, "tf_weapon_drg_pomson"))
						) {
							if (
								(players[victim].bison_hit_frame + 0) == GetGameTickCount() ||
								(players[victim].bison_hit_frame + 1) == GetGameTickCount()
							) {
								// don't allow bison to hit more than once every other frame
								return Plugin_Stop;
							}
							
							GetEntPropVector(inflictor, Prop_Send, "m_vecOrigin", pos1);
							GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos2);
							
							pos2[2] += PLAYER_CENTER_HEIGHT;
							
							TR_TraceRayFilter(pos1, pos2, MASK_SOLID, RayType_EndPoint, TraceFilter_ExcludePlayers);
							
							if (TR_DidHit()) {
								// there's a wall between the projectile and the target, cancel the hit
								return Plugin_Stop;
							}
							
							if (StrEqual(class, "tf_weapon_raygun")) {
								pos1[2] = 0.0;
								pos2[2] = 0.0;
								
								if (GetVectorDistance(pos1, pos2) > 55.0) {
									// target is too far from the projectile, cancel the hit
									return Plugin_Stop;
								}
								
								players[victim].bison_hit_frame = GetGameTickCount();
							}
							
							if (
								StrEqual(class, "tf_weapon_drg_pomson") &&
								PlayerIsInvulnerable(victim) == false
							) {
								// cloak/uber drain
								
								GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", pos1);
								GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos2);
								
								damage1 = ValveRemapVal(Pow(GetVectorDistance(pos1, pos2), 2.0), Pow(512.0, 2.0), Pow(1536.0, 2.0), 1.0, 0.0);
								
								if (TF2_GetPlayerClass(victim) == TFClass_Medic) {
									weapon1 = GetPlayerWeaponSlot(victim, TFWeaponSlot_Secondary);
									
									if (weapon1 > 0) {
										GetEntityClassname(weapon1, class, sizeof(class));
										
										if (StrEqual(class, "tf_weapon_medigun")) {
											if (
												GetEntProp(weapon1, Prop_Send, "m_bChargeRelease") == 0 ||
												GetEntProp(weapon1, Prop_Send, "m_bHolstered") == 1
											) {
												damage1 = (10.0 * (1.0 - damage1));
												damage1 = float(RoundToCeil(damage1));
												
												charge = GetEntPropFloat(weapon1, Prop_Send, "m_flChargeLevel");
												
												charge = (charge - (damage1 / 100.0));
												charge = (charge < 0.0 ? 0.0 : charge);
												
												if (charge > 0.1) {
													// fix 0.89999999 values
													charge = (charge += 0.001);
												}
												
												SetEntPropFloat(weapon1, Prop_Send, "m_flChargeLevel", charge);
											}
										}
									}
								}
								
								if (TF2_GetPlayerClass(victim) == TFClass_Spy) {
									damage1 = (20.0 * (1.0 - damage1));
									damage1 = float(RoundToCeil(damage1));
									
									charge = GetEntPropFloat(victim, Prop_Send, "m_flCloakMeter");
									
									charge = (charge - damage1);
									charge = (charge < 0.0 ? 0.0 : charge);
									
									SetEntPropFloat(victim, Prop_Send, "m_flCloakMeter", charge);
								}
							}
						}
						
						return Plugin_Continue;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

Action SDKHookCB_OnTakeDamageAlive(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageforce[3], float damageposition[3], int damagecustom) {
	if (
		victim >= 1 && victim <= MaxClients &&
		attacker >= 1 && attacker <= MaxClients
	) {
		{
			// sleeper jarate application
			
			if (
				ItemIsEnabled("sleeper", attacker) &&
				players[attacker].sleeper_piss_frame == GetGameTickCount()
			) {
				// condition must be added in OnTakeDamageAlive, otherwise initial shot will crit
				TF2_AddCondition(victim, TFCond_Jarated, players[attacker].sleeper_piss_duration, 0);
				
				ParticleShowSimple("peejar_impact_small", damageposition);
				
				if (players[attacker].sleeper_piss_explode) {
					// call into game code to cause a jarate explosion on the target
					SDKCall(sdkcall_JarExplode, victim, attacker, inflictor, inflictor, damageposition, GetClientTeam(attacker), 100.0, TFCond_Jarated, players[attacker].sleeper_piss_duration, "peejar_impact");
				}
			}
		}
	}
	
	return Plugin_Continue;
}

Action Command_Menu(int client, int args) {
	if (client > 0) {
		if (GetConVarBool(cvar_enable)) {
			DisplayMenu(menu_main, client, ITEM_MENU_TIME);
		} else {
			ReplyToCommand(client, "[SM] Weapon reverts are not enabled right now");
		}
	}
	
	return Plugin_Handled;
}

Action Command_Info(int client, int args) {
	if (client > 0) {
		ShowItemsDetails(client);
	}
	
	return Plugin_Handled;
}

Action Command_Pick(int client, int args) {
	if (client > 0) {
		players[client].picked = false;
		DisplayMenu(menu_pick, client, ITEM_MENU_TIME);
	}
	
	return Plugin_Handled;
}

void SetConVarMaybe(Handle cvar, char[] value, bool maybe) {
	if (maybe) {
		SetConVarString(cvar, value);
	} else {
		SetConVarReset(cvar);
	}
}

void SetConVarReset(Handle cvar) {
	char tmp[64];
	GetConVarDefault(cvar, tmp, sizeof(tmp));
	SetConVarString(cvar, tmp);
}

bool TraceFilter_ExcludeSingle(int entity, int contentsmask, any data) {
	return (entity != data);
}

bool TraceFilter_ExcludePlayers(int entity, int contentsmask, any data) {
	return (entity < 1 || entity > MaxClients);
}

bool TraceFilter_CustomShortCircuit(int entity, int contentsmask, any data) {
	char class[64];
	
	if (entity == data) {
		return false;
	}
	
	if (entity <= MaxClients) {
		return false;
	}
	
	GetEntityClassname(entity, class, sizeof(class));
	
	if (
		StrContains(class, "obj_") == 0 ||
		StrContains(class, "tf_projectile_") == 0
	) {
		return false;
	}
	
	return true;
}

bool PlayerIsInvulnerable(int client) {
	return (
		TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_PasstimeInterception)
	);
}

void PlayerRemoveEquipment(int client) {
	int idx;
	char class[64];
	
	TF2_RemoveAllWeapons(client);
	
	for (idx = (MaxClients + 1); idx < 2048; idx++) {
		if (IsValidEntity(idx)) {
			GetEntityClassname(idx, class, sizeof(class));
			
			if (
				StrContains(class, "tf_wearable") == 0 &&
				GetEntPropEnt(idx, Prop_Send, "m_hOwnerEntity") == client
			) {
				TF2_RemoveWearable(client, idx);
			}
		}
	}
}

float ValveRemapVal(float val, float a, float b, float c, float d) {
	// https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/public/mathlib/mathlib.h#L648
	
	float tmp;
	
	if (a == b) {
		return (val >= b ? d : c);
	}
	
	tmp = ((val - a) / (b - a));
	
	if (tmp < 0.0) tmp = 0.0;
	if (tmp > 1.0) tmp = 1.0;
	
	return (c + (d - c) * tmp);
}

void ParticleShowSimple(char[] name, float position[3]) {
	int idx;
	int table;
	int strings;
	int particle;
	char tmp[64];
	
	table = FindStringTable("ParticleEffectNames");
	strings = GetStringTableNumStrings(table);
	
	particle = -1;
	
	for (idx = 0; idx < strings; idx++) {
		ReadStringTable(table, idx, tmp, sizeof(tmp));
		
		if (StrEqual(tmp, name)) {
			particle = idx;
			break;
		}
	}
	
	if (particle >= 0) {
		TE_Start("TFParticleEffect");
		TE_WriteFloat("m_vecOrigin[0]", position[0]);
		TE_WriteFloat("m_vecOrigin[1]", position[1]);
		TE_WriteFloat("m_vecOrigin[2]", position[2]);
		TE_WriteNum("m_iParticleSystemIndex", particle);
		TE_SendToAllInRange(position, RangeType_Visibility, 0.0);
	}
}

void ItemDefine(char[] name, char[] key, char[] desc, int flags = 0) {
	int idx;
	
	for (idx = 0; idx < ITEMS_MAX; idx++) {
		if (strlen(items[idx].key) == 0) {
			strcopy(items[idx].key, sizeof(items[].key), key);
			strcopy(items[idx].name, sizeof(items[].name), name);
			strcopy(items[idx].desc, sizeof(items[].desc), desc);
			items[idx].flags = flags;
			
			return;
		}
	}
	
	SetFailState("Not enough item slots to define new item");
}

void ItemFinalize() {
	int idx;
	char cvar_name[64];
	char cvar_desc[256];
	
	for (idx = 0; idx < ITEMS_MAX; idx++) {
		if (strlen(items[idx].key) > 0) {
			if (items[idx].cvar != null) {
				SetFailState("Tried to initialize items more than once");
			}
			
			AddMenuItem(menu_pick, items[idx].key, "ERROR", _);
			
			Format(cvar_name, sizeof(cvar_name), ("sm_" ... PLUGIN_FILE ... "__item_%s"), items[idx].key);
			Format(cvar_desc, sizeof(cvar_desc), (PLUGIN_NAME ... " - Revert nerfs to %s"), items[idx].name);
			
			items[idx].cvar = CreateConVar(cvar_name, "1", cvar_desc, _, true, 0.0, true, 1.0);
		}
	}
}

int ItemKeyToNum(char[] key) {
	int idx;
	
	for (idx = 0; idx < ITEMS_MAX; idx++) {
		if (
			items[idx].key[0] != 0 &&
			StrEqual(key, items[idx].key)
		) {
			return idx;
		}
	}
	
	return -1;
}


bool ItemIsEnabled(char[] key, int client = 0) {
	int item;
	
	if (client <= MaxClients) {
		item = ItemKeyToNum(key);
		
		if (item >= 0) {
			if (client > 0) {
				return players[client].items_life[item];
			} else {
				return (
					GetConVarBool(cvar_enable) &&
					GetConVarBool(items[item].cvar)
				);
			}
		} else {
			LogError("ItemIsEnabled called for undefined item (%s)", key);
		}
	} else {
		LogError("ItemIsEnabled called for invalid client (%d)", client);
	}
	
	return false;
}

void ItemPlayerApply(int client) {
	int idx;
	bool value;
	
	for (idx = 0; idx < ITEMS_MAX; idx++) {
		if (strlen(items[idx].key) > 0) {
			value = false;
			
			if (
				GetConVarBool(cvar_enable) &&
				GetConVarBool(items[idx].cvar) &&
				(
					(items[idx].flags & ITEM_FL_PICKABLE) == 0 ||
					players[client].items_pick[idx] == true
				)
			) {
				value = true;
			}
			
			if (players[client].items_life[idx] != value) {
				players[client].items_life[idx] = value;
				players[client].change = true;
			}
		}
	}
}

void ItemCookieSave(int client) {
	int idx;
	int item;
	char value[100];
	
	item = 0;
	
	for (idx = 0; idx < sizeof(cookie_reverts); idx++) {
		strcopy(value, sizeof(value), "");
		
		for (;;) {
			if (item >= ITEMS_MAX) {
				break;
			}
			
			if (item == 0) {
				// tag the cookie with a version
				Format(value, sizeof(value), "$ver=%d", ITEM_COOKIE_VER);
			}
			
			if (
				strlen(items[item].key) > 0 &&
				(items[item].flags & ITEM_FL_PICKABLE) != 0
			) {
				// cookies can only be 99 chars long (why not 100?)
				if ((strlen(value) + strlen(items[item].key) + 4) > 100) {
					break;
				}
				
				if (strlen(value) > 0) {
					StrCat(value, sizeof(value), ",");
				}
				
				StrCat(value, sizeof(value), items[item].key);
				StrCat(value, sizeof(value), "=");
				StrCat(value, sizeof(value), (players[client].items_pick[item] ? "1" : "0"));
			}
			
			item++;
		}
		
		SetClientCookie(client, cookie_reverts[idx], value);
	}
}

void ItemCookieLoad(int client) {
	int idx1;
	int idx2;
	int item;
	char value[1024];
	char explode1[ITEMS_MAX][64];
	char explode2[2][64];
	int count;
	
	for (idx1 = 0; idx1 < sizeof(cookie_reverts); idx1++) {
		GetClientCookie(client, cookie_reverts[idx1], value, sizeof(value));
		
		count = ExplodeString(value, ",", explode1, sizeof(explode1), sizeof(explode1[]), false);
		
		for (idx2 = 0; idx2 < count; idx2++) {
			if (
				strlen(explode1[idx2]) == 0 ||
				StrContains(explode1[idx2], "=") == -1
			) {
				continue;
			}
			
			ExplodeString(explode1[idx2], "=", explode2, sizeof(explode2), sizeof(explode2[]), false);
			
			if (StrEqual(explode2[0], "$ver")) {
				if (StringToInt(explode2[1]) < ITEM_COOKIE_VER) {
					// this cookie is outdated, ignore
					return;
				}
			}
			
			item = ItemKeyToNum(explode2[0]);
			
			if (item >= 0) {
				players[client].items_pick[item] = (explode2[1][0] == '1');
			}
		}
	}
	
	ItemPlayerApply(client);
	
	if (IsClientInGame(client) == false) {
		players[client].change = false;
	}
}

int MenuHandler_Main(Menu menu, MenuAction action, int param1, int param2) {
	int item;
	bool item_enable;
	char item_suffix[64];
	char info[64];
	char tmp[128];
	int style;
	
	if (menu == menu_main) {
		if (action == MenuAction_Select) {
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if (StrEqual(info, "info")) {
				ShowItemsDetails(param1);
			}
			
			if (StrEqual(info, "pick")) {
				players[param1].picked = false;
				DisplayMenu(menu_pick, param1, ITEM_MENU_TIME);
			}
		}
	}
	
	if (menu == menu_pick) {
		if (
			action == MenuAction_Select ||
			action == MenuAction_DrawItem ||
			action == MenuAction_DisplayItem
		) {
			GetMenuItem(menu, param2, info, sizeof(info), style);
			
			item = ItemKeyToNum(info);
			
			if (item >= 0) {
				item_enable = true;
				
				if (items[item].flags & ITEM_FL_PICKABLE != 0) {
					if (players[param1].items_pick[item] == false) {
						item_enable = false;
					}
				} else {
					strcopy(item_suffix, sizeof(item_suffix), "enabled globally");
				}
				
				if (GetConVarBool(items[item].cvar) == false) {
					item_enable = false;
					strcopy(item_suffix, sizeof(item_suffix), "disabled by server");
				}
			}
		}
		
		if (action == MenuAction_Select) {
			if (item >= 0) {
				players[param1].items_pick[item] = (players[param1].items_pick[item] == false);
				players[param1].picked = true;
			}
			
			DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), ITEM_MENU_TIME);
		}
		
		if (action == MenuAction_Cancel) {
			if (
				IsClientInGame(param1) &&
				players[param1].picked == true
			) {
				ItemCookieSave(param1);
				PrintToChat(param1, "[SM] Changes will be applied on next spawn");
			}
		}
		
		if (action == MenuAction_DrawItem) {
			if (item >= 0) {
				if (
					(items[item].flags & ITEM_FL_PICKABLE) == 0 ||
					GetConVarBool(items[item].cvar) == false
				) {
					return ITEMDRAW_DISABLED;
				}
			}
			
			return style;
		}
		
		if (action == MenuAction_DisplayItem) {
			if (item >= 0) {
				if (strlen(item_suffix) > 0) {
					Format(item_suffix, sizeof(item_suffix), " (%s)", item_suffix);
				}
				
				Format(tmp, sizeof(tmp), " %s %s%s", (item_enable ? "✔" : "✘"), items[item].name, item_suffix);
				
				return RedrawMenuItem(tmp);
			}
		}
	}
	
	return 0;
}

void ShowItemsDetails(int client) {
	int idx;
	int count;
	char msg[ITEMS_MAX][128];
	
	count = 0;
	
	if (GetConVarBool(cvar_enable)) {
		for (idx = 0; idx < ITEMS_MAX; idx++) {
			if (
				strlen(items[idx].key) > 0 &&
				GetConVarBool(items[idx].cvar)
			) {
				Format(msg[count], sizeof(msg[]), "%s - %s", items[idx].name, items[idx].desc);
				count++;
			}
		}
	}
	
	ReplyToCommand(client, "[SM] Weapon revert details printed to console");
	
	PrintToConsole(client, "\n");
	PrintToConsole(client, "Weapon reverts currently enabled on this server:");
	
	if (count > 0) {
		for (idx = 0; idx < sizeof(msg); idx++) {
			if (strlen(msg[idx]) > 0) {
				PrintToConsole(client, "  %s", msg[idx]);
			}
		}
	} else {
		PrintToConsole(client, "  There's nothing here... for some reason, all item cvars are off :\\");
	}
	
	PrintToConsole(client, "");
}

MRESReturn DHookCallback_CTFWeaponBase_PrimaryAttack(int entity) {
	return MRES_Ignored;
}

MRESReturn DHookCallback_CTFWeaponBase_SecondaryAttack(int entity) {
	int idx;
	int owner;
	char class[64];
	float player_pos[3];
	float target_pos[3];
	float angles1[3];
	float angles2[3];
	float vector[3];
	float distance;
	float limit;
	int metal;
	
	GetEntityClassname(entity, class, sizeof(class));
	
	owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if (owner > 0) {
		if (
			StrEqual(class, "tf_weapon_flamethrower") ||
			StrEqual(class, "tf_weapon_rocketlauncher_fireball")
		) {
			// airblast set type cvar
			
			SetConVarMaybe(cvar_ref_tf_airblast_cray, "0", ItemIsEnabled("airblast", owner));
			
			return MRES_Ignored;
		}
		
		if (
			ItemIsEnabled("circuit", owner) &&
			StrEqual(class, "tf_weapon_mechanical_arm")
		) {
			// short circuit secondary fire
			
			SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", (GetGameTime() + BALANCE_CIRCUIT_RECOVERY));
			SetEntPropFloat(entity, Prop_Send, "m_flNextSecondaryAttack", (GetGameTime() + BALANCE_CIRCUIT_RECOVERY));
			
			metal = GetEntProp(owner, Prop_Data, "m_iAmmo", 4, 3);
			
			if (metal >= BALANCE_CIRCUIT_METAL) {
				for (idx = 1; idx < MaxClients; idx++) {
					if (
						IsClientInGame(idx) &&
						(
							idx != owner ||
							metal < 65
						)
					) {
						EmitGameSoundToClient(idx, "Weapon_BarretsArm.Shot", owner);
					}
				}
				
				SetEntProp(owner, Prop_Data, "m_iAmmo", (metal - BALANCE_CIRCUIT_METAL), 4, 3);
				
				GetClientEyePosition(owner, player_pos);
				GetClientEyeAngles(owner, angles1);
				
				for (idx = 1; idx < 2048; idx++) {
					if (IsValidEntity(idx)) {
						GetEntityClassname(idx, class, sizeof(class));
						
						if (
							(idx <= MaxClients) ||
							StrEqual(class, "tf_projectile_rocket") ||
							StrEqual(class, "tf_projectile_sentryrocket") ||
							StrEqual(class, "tf_projectile_pipe") ||
							StrEqual(class, "tf_projectile_pipe_remote") ||
							StrEqual(class, "tf_projectile_arrow") ||
							StrEqual(class, "tf_projectile_flare") ||
							StrEqual(class, "tf_projectile_stun_ball") ||
							StrEqual(class, "tf_projectile_ball_ornament") ||
							StrEqual(class, "tf_projectile_cleaver")
						) {
							if (GetEntProp(idx, Prop_Send, "m_iTeamNum") != GetClientTeam(owner)) {
								GetEntPropVector(idx, Prop_Send, "m_vecOrigin", target_pos);
								
								if (idx <= MaxClients) {
									target_pos[2] += PLAYER_CENTER_HEIGHT;
								}
								
								distance = GetVectorDistance(player_pos, target_pos);
								
								if (distance < 300.0) {
									MakeVectorFromPoints(player_pos, target_pos, vector);
									
									GetVectorAngles(vector, angles2);
									
									angles2[1] = FixViewAngleY(angles2[1]);
									
									angles1[0] = 0.0;
									angles2[0] = 0.0;
									
									if (idx <= MaxClients) {
										limit = ValveRemapVal(distance, 0.0, 150.0, 70.0, 25.0);
									} else {
										limit = ValveRemapVal(distance, 0.0, 200.0, 80.0, 40.0);
									}
									
									if (CalcViewsOffset(angles1, angles2) < limit) {
										TR_TraceRayFilter(player_pos, target_pos, MASK_SOLID, RayType_EndPoint, TraceFilter_CustomShortCircuit, idx);
										
										if (TR_DidHit() == false) {
											if (idx <= MaxClients) {
												SDKHooks_TakeDamage(idx, entity, owner, BALANCE_CIRCUIT_DAMAGE, DMG_SHOCK, entity, NULL_VECTOR, target_pos);
											} else {
												RemoveEntity(idx);
											}
										}
									}
								}
							}
						}
					}
				}
			}
			
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

MRESReturn DHookCallback_CTFBaseRocket_GetRadius(int entity, Handle return_) {
	int owner;
	int weapon;
	char class[64];
	float value;
	
	GetEntityClassname(entity, class, sizeof(class));
	
	owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");
	
	if (
		owner > 0 &&
		weapon > 0
	) {
		if (StrEqual(class, "tf_projectile_rocket")) {
			GetEntityClassname(weapon, class, sizeof(class));
			
			if (
				ItemIsEnabled("airstrike", owner) &&
				StrEqual(class, "tf_weapon_rocketlauncher_airstrike") &&
				IsPlayerAlive(owner) &&
				TF2_IsPlayerInCondition(owner, TFCond_BlastJumping)
			) {
				// for some reason, doing this in one line doesn't work
				// we have to get the value to a var and then set it
				
				value = DHookGetReturn(return_);
				value = (value / 0.80); // undo airstrike attrib
				DHookSetReturn(return_, value);
				
				return MRES_Override;
			}
		}
	}
	
	return MRES_Ignored;
}

float CalcViewsOffset(float angle1[3], float angle2[3]) {
	float v1;
	float v2;
	
	v1 = FloatAbs(angle1[0] - angle2[0]);
	v2 = FloatAbs(angle1[1] - angle2[1]);
	
	v2 = FixViewAngleY(v2);
	
	return SquareRoot(Pow(v1, 2.0) + Pow(v2, 2.0));
}

float FixViewAngleY(float angle) {
	return (angle > 180.0 ? (angle - 360.0) : angle);
}


/*

bool ItemIsThisDef(char[] key, char[] class, int index) {
	if (
		StrEqual(key, "ambassador") &&
		StrEqual(class, "tf_weapon_revolver") &&
		(index == 61 || index == 1006)
	) { return true; }
	
	return false;
}

bool ItemIsThisEnt(char[] key, int entity) {
	char class[64];
	
	if (entity > MaxClients) {
		GetEntityClassname(entity, class, sizeof(class));
		
		if (
			StrContains(class, "tf_weapon_") == 0 ||
			StrContains(class, "tf_wearable_") == 0
		) {
			return ItemIsThisDef(key, class, GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"));
		}
	}
	
	return false;
}

*/
