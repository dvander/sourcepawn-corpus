#pragma semicolon 1
#pragma newdecls required

//#define DEBUG

#define PLUGIN_AUTHOR "xZk"
#define PLUGIN_VERSION "1.2.7"

#include <sourcemod>
#include <sdkhooks>
#include <l4d_stocks>

#define MAXENTITIES 2048
#define IS_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)

#define IS_VALID_CLIENT(%1) (IS_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_VALID_SURVIVOR(%1) (IS_VALID_CLIENT(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_CLIENT(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

// #define model1_weapon_rifle "models/w_models/weapons/w_rifle_m16a2.mdl"
// #define model1_weapon_autoshotgun "models/w_models/weapons/w_autoshot_m4super.mdl"
// #define model1_weapon_pumpshotgun "models/w_models/Weapons/w_shotgun.mdl"
// #define model1_weapon_hunting_rifle "models/w_models/weapons/w_sniper_mini14.mdl"
// #define model1_weapon_smg "models/w_models/Weapons/w_smg_uzi.mdl"
#define model1_weapon_pistol "models/w_models/Weapons/w_pistol_1911.mdl"
// #define model1_weapon_molotov "models/w_models/weapons/w_eq_molotov.mdl"
// #define model1_weapon_pipe_bomb "models/w_models/weapons/w_eq_pipebomb.mdl"
// #define model1_weapon_first_aid_kit "models/w_models/weapons/w_eq_Medkit.mdl"
// #define model1_weapon_pain_pills "models/w_models/weapons/w_eq_painpills.mdl"

#define model_weapon_rifle "models/w_models/weapons/w_rifle_m16a2.mdl"
#define model_weapon_rifle_sg552 "models/w_models/weapons/w_rifle_sg552.mdl"
#define model_weapon_rifle_desert "models/w_models/weapons/w_desert_rifle.mdl"
#define model_weapon_rifle_ak47 "models/w_models/weapons/w_rifle_ak47.mdl"
#define model_weapon_smg "models/w_models/weapons/w_smg_uzi.mdl"
#define model_weapon_smg_silenced "models/w_models/weapons/w_smg_a.mdl"
#define model_weapon_smg_mp5 "models/w_models/weapons/w_smg_mp5.mdl"
#define model_weapon_pumpshotgun "models/w_models/weapons/w_shotgun.mdl"
#define model_weapon_shotgun_chrome "models/w_models/weapons/w_pumpshotgun_A.mdl"
#define model_weapon_autoshotgun "models/w_models/weapons/w_autoshot_m4super.mdl"
#define model_weapon_shotgun_spas "models/w_models/weapons/w_shotgun_spas.mdl"
#define model_weapon_hunting_rifle "models/w_models/weapons/w_sniper_mini14.mdl"
#define model_weapon_sniper_scout "models/w_models/weapons/w_sniper_scout.mdl"
#define model_weapon_sniper_military "models/w_models/weapons/w_sniper_military.mdl"
#define model_weapon_sniper_awp "models/w_models/weapons/w_sniper_awp.mdl"
#define model_weapon_rifle_m60 "models/w_models/weapons/w_m60.mdl"
#define model_weapon_grenade_launcher "models/w_models/weapons/w_grenade_launcher.mdl"
#define model_weapon_pistol "models/w_models/weapons/w_pistol_A.mdl"
#define model_weapon_pistol2 "models/w_models/weapons/w_pistol_B.mdl"

#define model_weapon_pistol_magnum "models/w_models/weapons/w_desert_eagle.mdl"
#define model_weapon_chainsaw "models/weapons/melee/w_chainsaw.mdl"
#define model_weapon_melee_fireaxe "models/weapons/melee/w_fireaxe.mdl"
#define model_weapon_melee_baseball_bat "models/weapons/melee/w_bat.mdl"
#define model_weapon_melee_crowbar "models/weapons/melee/w_crowbar.mdl"
#define model_weapon_melee_electric_guitar "models/weapons/melee/w_electric_guitar.mdl"
#define model_weapon_melee_cricket_bat "models/weapons/melee/w_cricket_bat.mdl"
#define model_weapon_melee_frying_pan  "models/weapons/melee/w_frying_pan.mdl"
#define model_weapon_melee_golfclub  "models/weapons/melee/w_golfclub.mdl"
#define model_weapon_melee_machete  "models/weapons/melee/w_machete.mdl"
#define model_weapon_melee_katana  "models/weapons/melee/w_katana.mdl"
#define model_weapon_melee_tonfa  "models/weapons/melee/w_tonfa.mdl"
#define model_weapon_melee_knife  "models/weapons/melee/w_knife.mdl"
#define model_weapon_melee_riotshield  "models/weapons/melee/w_riotshield.mdl"
#define model_weapon_molotov "models/w_models/weapons/w_eq_molotov.mdl"
#define model_weapon_pipe_bomb "models/w_models/weapons/w_eq_pipebomb.mdl"
#define model_weapon_vomitjar "models/w_models/weapons/w_eq_bile_flask.mdl"
#define model_weapon_first_aid_kit "models/w_models/weapons/w_eq_Medkit.mdl"
#define model_weapon_defibrillator "models/w_models/weapons/w_eq_defibrillator.mdl"
#define model_weapon_upgradepack_explosive "models/w_models/weapons/w_eq_explosive_ammopack.mdl"
#define model_weapon_upgradepack_incendiary "models/w_models/weapons/w_eq_incendiary_ammopack.mdl"
#define model_weapon_pain_pills "models/w_models/weapons/w_eq_painpills.mdl"
#define model_weapon_adrenaline "models/w_models/weapons/w_eq_adrenaline.mdl"

#define model_weapon_fireworkcrate "/props_junk/explosive_box001.mdl"
#define model_weapon_gascan "/props_junk/gascan001a.mdl"
#define model_weapon_propanetank "/props_junk/propanecanister001.mdl"
#define model_weapon_oxygentank "/props_equipment/oxygentank01.mdl"
#define model_weapon_cola_bottles "/w_models/weapons/w_cola.mdl"
#define model_weapon_gnome "/props_junk/gnome.mdl"

ConVar weapon_cleaner_enable;
ConVar weapon_cleaner_exclude;
ConVar weapon_cleaner_drop;
ConVar weapon_cleaner_class;
ConVar weapon_cleaner_map;
ConVar weapon_cleaner_delay;
ConVar weapon_cleaner_effect_mode;
ConVar weapon_cleaner_effect_time;
ConVar weapon_cleaner_effect_glowcolor;
ConVar weapon_cleaner_effect_glowrange;
ConVar weapon_cleaner_visible;
ConVar weapon_cleaner_visible_mode;

bool Is_enable = true;
bool Is_drop;
bool Is_visible;
bool Is_map;
int Class_weapon;
int Clean_delay;
int Effect_mode;
float Effect_starttime;
char Effect_glowcolor[16];
int Effect_glowrange;
int Visible_mode;
char Weapons_excluded[256];

Handle DelayClean[MAXENTITIES + 1];
int ItemTime[MAXENTITIES + 1] = -1;
int EntRef[MAXENTITIES + 1];
int GlowColor[] =  { 200, 200, 200 }; //C8C8C8
char WhiteList[50][32];
bool IsL4D2;
bool IsSpawnedEntsMap;

public Plugin myinfo = 
{
	name = "Weapon Cleaner", 
	author = PLUGIN_AUTHOR, 
	description = "Clean drop weapons on the ground with delay timer, like KF2", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	weapon_cleaner_enable           = CreateConVar("weapon_cleaner_enable", "1", "0:Disable, 1:Enable Plugin", FCVAR_NONE);
	weapon_cleaner_map           	= CreateConVar("weapon_cleaner_map", "0", "0:Ignore map weapons, 1:Detect all weapons generated by the map");
	weapon_cleaner_drop             = CreateConVar("weapon_cleaner_drop", "0", "0: Clean all weapons not equipped in the game, 1: Clean only dropped weapons when taking another weapon", FCVAR_NONE);
	weapon_cleaner_class            = CreateConVar("weapon_cleaner_class", "1", "1:Clean only Weapons that do not belong to the spawn class, 2:Clean only Weapons of the class with suffix: \"_spawn\", 3:All weapons with any class name(\"weapon_*\")", FCVAR_NONE, true, 1.0, true, 3.0);
	weapon_cleaner_delay            = CreateConVar("weapon_cleaner_delay", "300", "Set delay to clean each weapon in seconds", FCVAR_NONE, true, 1.0);
	weapon_cleaner_effect_mode      = CreateConVar("weapon_cleaner_effect_mode", "1", "0:Disable effects on weapons in timer cleaning, 1:Set blink effect(RenderFx), 2:Set glow effect(L4D2), 3:All effects modes");
	weapon_cleaner_effect_time      = CreateConVar("weapon_cleaner_effect_time", "0.5", "Set percentage of delay time to activate effects on weapons, ex:(\"0.2\")=>(0.2*delay=0.2*300s=60s) or Set time in seconds value if: (value >= 1), ex:(\"60\")s", FCVAR_NONE, true, 0.01);
	weapon_cleaner_effect_glowcolor = CreateConVar("weapon_cleaner_effect_glowcolor", "128,128,128", "Set glow color in RGB Format (L4D2)");
	weapon_cleaner_effect_glowrange = CreateConVar("weapon_cleaner_effect_glowrange", "1000", "Set maximum range of glow (L4D2)");
	weapon_cleaner_visible          = CreateConVar("weapon_cleaner_visible", "0", "0:Disable, 1:Enable visibility filter on weapons");
	weapon_cleaner_visible_mode     = CreateConVar("weapon_cleaner_visible_mode", "0", "0:Pause timer if is visible weapon , 1:Pause timer if someone is aiming at the weapon, 2:Reset timer if is visible weapon, 3:Reset timer if someone is aiming at the weapon", FCVAR_NONE, true, 0.0, true, 3.0);
	weapon_cleaner_exclude          = CreateConVar("weapon_cleaner_exclude", "gascan,cola_bottles", "Set name weapons to exclude(WhiteList), example: gascan,propanetank,first_aid_kit,...(etc) (https://wiki.alliedmods.net/Left_4_Dead_2_Weapons)");
	GameCheck();
	
	weapon_cleaner_enable.AddChangeHook(CvarChange_Enable);
	weapon_cleaner_map.AddChangeHook(CvarChange_Map);
	weapon_cleaner_drop.AddChangeHook(CvarChange_Mode);
	weapon_cleaner_class.AddChangeHook(CvarChange_Class);
	weapon_cleaner_delay.AddChangeHook(CvarChange_Delay);
	weapon_cleaner_visible.AddChangeHook(CvarChange_Visible);
	weapon_cleaner_visible_mode.AddChangeHook(CvarChange_VisibleMode);
	weapon_cleaner_effect_mode.AddChangeHook(CvarChange_EffectMode);
	weapon_cleaner_effect_time.AddChangeHook(CvarChange_EffectTime);
	weapon_cleaner_effect_glowcolor.AddChangeHook(CvarChange_GlowColor);
	weapon_cleaner_effect_glowrange.AddChangeHook(CvarChange_GlowRange);
	weapon_cleaner_exclude.AddChangeHook(CvarChange_Exclude);
	
	//HookEvent("round_start", Event_RoundReset); //bug detect map weapons
	HookEvent("round_end", Event_RoundReset);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	
	AutoExecConfig(true, "weapon_cleaner");
}

public void OnPluginEnd() {
	UnloadPlugin();
}

public void OnConfigsExecuted() {
	Is_enable        = weapon_cleaner_enable.BoolValue;
	Is_map       	 = weapon_cleaner_map.BoolValue;
	Is_drop          = weapon_cleaner_drop.BoolValue;
	Class_weapon     = weapon_cleaner_class.IntValue;
	Clean_delay      = weapon_cleaner_delay.IntValue;
	Is_visible       = weapon_cleaner_visible.BoolValue;
	Visible_mode     = weapon_cleaner_visible_mode.IntValue;
	Effect_mode      = weapon_cleaner_effect_mode.IntValue;
	Effect_starttime = weapon_cleaner_effect_time.FloatValue;
	weapon_cleaner_effect_glowcolor.GetString(Effect_glowcolor, sizeof(Effect_glowcolor));
	Effect_glowrange = weapon_cleaner_effect_glowrange.IntValue;
	weapon_cleaner_exclude.GetString(Weapons_excluded, sizeof(Weapons_excluded));
}

void GameCheck()
{
	char GameName[16];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
		IsL4D2 = true;
	else
		IsL4D2 = false;
}

public void CvarChange_Enable(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	Is_enable = cvar.BoolValue;
	if (Is_enable && !StringToInt(oldVal))
		ReloadPlugin();
	else if (!Is_enable && StringToInt(oldVal))
		UnloadPlugin();
}

public void CvarChange_Map(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	Is_map = cvar.BoolValue;
}

public void CvarChange_Mode(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	Is_drop = cvar.BoolValue;
}

public void CvarChange_Class(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	Class_weapon = cvar.IntValue;
}

public void CvarChange_Delay(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	Clean_delay = cvar.IntValue;
}

public void CvarChange_Visible(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	Is_visible = cvar.BoolValue;
}

public void CvarChange_VisibleMode(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	Visible_mode = cvar.IntValue;
}

public void CvarChange_EffectMode(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	Effect_mode = cvar.IntValue;
}

public void CvarChange_EffectTime(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	Effect_starttime = cvar.FloatValue;
}

public void CvarChange_GlowColor(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	cvar.GetString(Effect_glowcolor, sizeof(Effect_glowcolor));
}

public void CvarChange_GlowRange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	Effect_glowrange = cvar.IntValue;
}

public void CvarChange_Exclude(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	cvar.GetString(Weapons_excluded, sizeof(Weapons_excluded));
}


public void Event_RoundReset(Event event, const char[] name, bool dontBroadcast)
{
	if (!Is_enable)
		return;
	StopTimers();
	IsSpawnedEntsMap = false;
}

public void Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast) {  //postcheck weapons spowned by map
	IsSpawnedEntsMap = true;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!Is_enable || (!IsSpawnedEntsMap && !Is_map) || Is_drop) {
		return;
	}
	if (StrContains(classname, "weapon_") == 0 )
	{
		SDKHook(entity, SDKHook_SpawnPost, OnSpawn);
	}
	
}

public void OnEntityDestroyed(int entity)
{
	if (IsItemValid(entity))
	{
		StopItemTimer(entity);
		_debug("deleted:%d ", entity);
	}
}

public void OnClientPutInServer(int client) {
	
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
	SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
	SDKUnhook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
}

public void OnSpawn(int entity) {
	if (IsItemValid(entity) && !IsWeaponInUse(entity)) {
		StopItemTimer(entity);
		StartItemTimer(entity);
		_debug("Spawn:%d", entity);
	}
}

public void OnThink(int entity) {  // check weapon on ground
	
	if (IsItemValid(entity) && !IsWeaponInUse(entity)) {
		if(IsWeaponTimerOn(entity)){
			SDKUnhook(entity, SDKHook_ThinkPost, OnThink);
		}
		else {
			SDKUnhook(entity, SDKHook_ThinkPost, OnThink); 
			StopItemTimer(entity);
			StartItemTimer(entity);
			_debug("Unequip_weapon:%d", entity);
		}
	}
}

public void OnWeaponEquip(int client, int weapon) {
	
	if (IS_VALID_SURVIVOR(client) && IsItemValid(weapon))
	{
		StopItemTimer(weapon);
		RemoveEffects(weapon);
		SDKUnhook(weapon, SDKHook_ThinkPost, OnThink);
		SDKHook(weapon, SDKHook_ThinkPost, OnThink);
		_debug("HOOK-player:%d Equip : %d", client, weapon);
	}
}

public void OnWeaponDrop(int client, int weapon) {
	
	if (!Is_enable)
		return;
	
	if (IS_VALID_SURVIVOR(client) && IsItemValid(weapon))
	{
		SDKUnhook(weapon, SDKHook_ThinkPost, OnThink);
		RemoveEffects(weapon);
		StopItemTimer(weapon);
		StartItemTimer(weapon);
		_debug("HOOK-player:%d Drop : %d", client, weapon);
	}
}

public Action CleanWeapon(Handle timer, int ent) {
	
	if (!Is_enable) {
		StopTimers();
		return Plugin_Stop;
	}
	int weapon = EntRefToEntIndex(EntRef[ent]);
	if (IsItemValid(weapon)) {
		if (ItemTime[weapon] >= 0) {
			if (IsWeaponInUse(weapon))
			{
				_debug("USER: %d", weapon);
				RemoveEffects(weapon);
				StopItemTimer(weapon);
				return Plugin_Stop;
			} else if (ItemTime[weapon] == 0) {
				StopItemTimer(weapon);
				AcceptEntityInput(weapon, "kill");
				return Plugin_Stop;
			}
			if (Is_visible && IsVisibleToPlayers(weapon)) {
				SetEffects(weapon);
				switch (Visible_mode) {
					case 0: {  //Pause Timer
						_debug("Time: %d", ItemTime[weapon]);
						return Plugin_Continue;
					}
					case 1: {  //Pause Timer on aiming
						if (IsAimToPlayers(weapon)) {
							_debug("Time: %d", ItemTime[weapon]);
							return Plugin_Continue;
						}
					}
					case 2: {  //Reset Timer
						ItemTime[weapon] = Clean_delay;
						RemoveEffects(weapon);
					}
					case 3: {  //Reset Timer on aiming
						if (IsAimToPlayers(weapon)) {
							ItemTime[weapon] = Clean_delay;
							RemoveEffects(weapon);
						}
					}
				}
			}
		} else {
			StopItemTimer(weapon);
			return Plugin_Stop;
		}
		
		SetEffects(weapon);
		ItemTime[weapon]--;
		_debug("Time: %d", ItemTime[weapon]);
	} else {
		StopItemTimer(ent);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void SetEffects(int item) {
	int time_fx;
	if (Effect_starttime < 1.0) {
		time_fx = RoundFloat(float(Clean_delay) * Effect_starttime);
	} else {
		time_fx = RoundFloat(Effect_starttime);
	}
	
	if (ItemTime[item] <= time_fx)
	{
		if (Effect_mode & 1) {
			if (ItemTime[item] == (time_fx / 4)) {
				SetEntityRenderFx(item, RENDERFX_STROBE_FASTER);
			} else if (ItemTime[item] == (time_fx / 2)) {
				SetEntityRenderFx(item, RENDERFX_STROBE_FAST);
			} else if (ItemTime[item] == time_fx) {
				SetEntityRenderFx(item, RENDERFX_STROBE_SLOW);
			}
			
		}
		if (Effect_mode & 2) {
			if (IsL4D2) {
				GlowColor = StringToRGB(Effect_glowcolor);
				if (ItemTime[item] == (time_fx / 2)) {
					L4D2_SetEntityGlow(item, L4D2Glow_OnLookAt, Effect_glowrange, 100, GlowColor, true);
				} else if (ItemTime[item] == time_fx) {
					L4D2_SetEntityGlow(item, L4D2Glow_OnLookAt, Effect_glowrange, 100, GlowColor, false);
				}
				
			}
		}
	}
}

void RemoveEffects(int item) {
	if (IsL4D2) {
		L4D2_RemoveEntityGlow(item);
	}
	SetEntityRenderFx(item, RENDERFX_NONE);
}

bool IsVisibleToPlayers(int entity) {
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IS_SURVIVOR_ALIVE(i) && (GetClientAimTarget(i, false) == entity || IsVisibleTo(i, entity))) {
			return true;
		}
	}
	return false;
}

bool IsAimToPlayers(int entity) {
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IS_SURVIVOR_ALIVE(i) && GetClientAimTarget(i, false) == entity) {
			return true;
		}
	}
	return false;
}

static bool IsVisibleTo(int client, int entity) // check an entity for being visible to a client
{
	float vAngles[3], vOrigin[3], vEnt[3], vLookAt[3];
	
	GetClientEyePosition(client, vOrigin); // get both player and zombie position
	//GetEntityAbsOrigin(entity, vEnt);											/***BUG M60***/
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vEnt);
	MakeVectorFromPoints(vOrigin, vEnt, vLookAt); // compute vector from player to zombie
	
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	// execute Trace
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, _DI_TraceFilter);
	
	bool isVisible = false;
	if (TR_DidHit(trace))
	{
		float vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		
		if ((GetVectorDistance(vOrigin, vStart, false) + 35.0) >= GetVectorDistance(vOrigin, vEnt))
		{
			isVisible = true; // if trace ray lenght plus tolerance equal or bigger absolute distance, you hit the targeted zombie
		}
	}
	else
	{
		//LogError("Zombie Despawner Bug: Player-Zombie Trace did not hit anything, WTF");
		isVisible = true;
	}
	delete trace;
	return isVisible;
}

public bool _DI_TraceFilter(int entity, int contentsMask)
{
	if (entity <= MaxClients || !IsValidEntity(entity)) // dont let WORLD, players, or invalid entities be hit
	{
		return false;
	}
	char class[128];
	GetEdictClassname(entity, class, sizeof(class));
	if (StrEqual(class, "witch", false))return false;
	if (StrEqual(class, "infected", false))return false;
	if (StrEqual(class, "prop_physics", false))return false;
	if (StrContains(class, "weapon") != -1)return false;
	
	return true;
}

bool IsWeaponInUse(int entity)
{	
	if(!IsWeaponSpawn(entity)){
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwner");
		if (IS_VALID_CLIENT(client))
			return true;
		
		client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if (IS_VALID_CLIENT(client))
			return true;
		
		for (int i = 1; i <= MaxClients; i++) {
			if ( IS_VALID_CLIENT(i) ){
				if ( GetActiveWeapon(i) == entity )
					return true;
				if ( IsWeaponEquipped(i, entity) )
					return true;
			}
		}
	
	}
	return false;
}

void GetItemClass(int ent,  char classname[64])
{
	classname = "";

	if(IsValidEnt(ent))
	{
		if(IsValidWeapon(ent))
		{
			char model[128];
			GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
			//guns
			if(StrContains(model, "w_pistol_")>=0)classname="weapon_pistol";
			else if(StrEqual(model, model_weapon_pistol_magnum))classname="weapon_pistol_magnum";
			else if(StrEqual(model, model_weapon_chainsaw))classname="weapon_chainsaw";
			else if(StrEqual(model, model_weapon_smg))classname="weapon_smg";
			else if(StrEqual(model, model_weapon_smg_silenced))classname="weapon_smg_silenced";
			else if(StrEqual(model, model_weapon_smg_mp5))classname="weapon_smg_mp5";
			else if(StrEqual(model, model_weapon_rifle))classname="weapon_rifle";
			else if(StrEqual(model, model_weapon_rifle_ak47))classname="weapon_rifle_ak47";
			else if(StrEqual(model, model_weapon_rifle_desert))classname="weapon_rifle_desert";
			else if(StrEqual(model, model_weapon_rifle_sg552))classname="weapon_rifle_sg552";
			else if(StrEqual(model, model_weapon_rifle_m60))classname="weapon_rifle_m60";
			else if(StrEqual(model, model_weapon_hunting_rifle))classname="weapon_hunting_rifle";
			else if(StrEqual(model, model_weapon_sniper_military))classname="weapon_sniper_military";
			else if(StrEqual(model, model_weapon_sniper_scout))classname="weapon_sniper_scout";
			else if(StrEqual(model, model_weapon_sniper_awp))classname="weapon_sniper_awp";
			else if(StrEqual(model, model_weapon_pumpshotgun))classname="weapon_pumpshotgun";
			else if(StrEqual(model, model_weapon_shotgun_chrome))classname="weapon_shotgun_chrome";
			else if(StrEqual(model, model_weapon_autoshotgun))classname="weapon_autoshotgun";
			else if(StrEqual(model, model_weapon_shotgun_spas))classname="model_weapon_shotgun_spas";
			else if(StrEqual(model, model_weapon_grenade_launcher))classname="weapon_grenade_launcher";
			else if(StrEqual(model, model_weapon_molotov))classname="weapon_molotov";
			else if(StrEqual(model, model_weapon_pipe_bomb))classname="weapon_pipe_bomb";
			else if(StrEqual(model, model_weapon_vomitjar))classname="weapon_vomitjar";
			else if(StrEqual(model, model_weapon_first_aid_kit))classname="weapon_first_aid_kit";
			else if(StrEqual(model, model_weapon_defibrillator))classname="weapon_defibrillator";
			else if(StrEqual(model, model_weapon_upgradepack_explosive))classname="weapon_upgradepack_explosive";
			else if(StrEqual(model, model_weapon_upgradepack_incendiary))classname="model_weapon_upgradepack_incendiary";
			else if(StrEqual(model, model_weapon_pain_pills))classname="weapon_pain_pills";
			else if(StrEqual(model, model_weapon_adrenaline))classname="weapon_adrenaline";
			//melees
			else if(StrContains(model, "fireaxe")>=0)classname="weapon_melee_fireaxe";
			else if(StrContains(model, "v_bat")>=0)	classname="weapon_melee_baseball_bat";
			else if(StrContains(model, "crowbar")>=0)classname="weapon_melee_crowbar";
			else if(StrContains(model, "electric_guitar")>=0)classname="weapon_melee_electric_guitar";
			else if(StrContains(model, "cricket_bat")>=0)classname="weapon_melee_cricket_bat";
			else if(StrContains(model, "frying_pan")>=0)classname="weapon_melee_frying_pan";
			else if(StrContains(model, "golfclub")>=0)classname="weapon_melee_golfclub";
			else if(StrContains(model, "machete")>=0)classname="weapon_melee_machete";
			else if(StrContains(model, "katana")>=0)classname="weapon_melee_katana";
			else if(StrContains(model, "tonfa")>=0)classname="weapon_melee_tonfa";
			else if(StrContains(model, "riotshield")>=0)classname="weapon_melee_riotshield";
			else if(StrContains(model, "knife")>=0)classname="weapon_melee_knife";
			//carry objects
			else if(StrEqual(model, model_weapon_fireworkcrate))classname="weapon_fireworkcrate";
			else if(StrEqual(model, model_weapon_gascan))classname="weapon_gascan";
			else if(StrEqual(model, model_weapon_oxygentank))classname="weapon_oxygentank";
			else if(StrEqual(model, model_weapon_gascan))classname="weapon_propanetank";
			else if(StrEqual(model, model_weapon_gnome))classname="weapon_gnome";
			else if(StrEqual(model, model_weapon_cola_bottles))classname="weapon_cola_bottles";
			else classname="";
		}
	}
}

stock int GetActiveWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
}

stock bool IsWeaponEquipped(int client, int weapon){	

	int weapons[5];
	weapons=GetWeapons(client);
	
	for (int i=0; i < sizeof(weapons); i++) 
	{
		if (IsValidWeapon(weapons[i])){
			//PrintToChatAll("%d",i+1);
			if (weapons[i]==weapon)
			{
				return true;
			}
		}
	}
	return false;
}

stock int GetWeapons(int client){
	int weapons[5];
	for (int i=0; i < sizeof(weapons); i++)
	{
		int weapon = GetPlayerWeaponSlot(client, i);
		if (IsValidWeapon(weapon)){
			weapons[i]=weapon;
		}
	}
	return weapons;
}

stock bool SplitStringRight(const char[] source, const char[] split, char[] part, int partLen)
{
	int index = StrContains(source, split); // get start index of split string 
	
	if (index == -1) // split string not found.. 
		return false;
	
	index += strlen(split); // get end index of split string
	
	if (index == strlen(source) - 1) // no right side exist
		return false;
	
	strcopy(part, partLen, source[index]); // copy everything after source[ index ] to part 
	return true;
}

stock void _debug(const char[] szFormat, int ...)
{
	char szText[4096];
	VFormat(szText, sizeof(szText), szFormat, 2);
	//server_print("#DEBUG: %s", szText);
	#if defined DEBUG
	PrintToChatAll("#DEBUG: %s", szText);
	#endif
	
}

stock void GetNameWeaponMelee(int weapon, char[] melee_name, int size){
	if(IsWeaponMeleeClass(weapon))
		GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", melee_name, size);
}

stock bool IsWeaponMeleeClass(int weapon){
	
	if(IsValidWeapon(weapon))
	{
		char class_name[64];
		GetEntityClassname(weapon, class_name, sizeof(class_name));
		return (StrEqual(class_name, "weapon_melee") );
	}
	return false;
}

stock bool IsValidEnt(int entity){
	return (entity > 0 && entity > MaxClients && IsValidEntity(entity) && entity != INVALID_ENT_REFERENCE);
}

bool IsValidWeapon(int weapon)
{
	if (!IsValidEnt(weapon)) 
		return false;
	
	char class_name[64];
	GetEntityClassname(weapon, class_name, sizeof(class_name));
	if (StrContains(class_name, "weapon_") == 0)
		return true;
	else
		return false;
}

bool IsWeaponSpawn(int weapon)
{
	char class_name[64];
	GetEntityClassname(weapon, class_name, sizeof(class_name));
	if (IsValidWeapon(weapon) && StrContains(class_name, "_spawn") != -1)
		return true;
	else
		return false;
}

bool IsWeaponClassEnable(int weapon) {
	if (!IsWeaponSpawn(weapon) && Class_weapon & 1)
		return true;
	
	if (IsWeaponSpawn(weapon) && Class_weapon & 2)
		return true;
	
	return false;
}

bool IsItemExclude(int item) {

	if(IsValidWeapon(item)){
		TrimString(Weapons_excluded);
		ExplodeString(Weapons_excluded, ",", WhiteList, sizeof(WhiteList), 32);
		
		char weapon_class[64], item_name[64];
		if(IsWeaponSpawn(item)){
			GetItemClass(item, weapon_class);
			//PrintToChatAll("wclass: %s",weapon_class);
			if(StrContains(weapon_class,"weapon_melee") == 0)
				SplitStringRight(weapon_class, "weapon_melee_", item_name, sizeof(item_name));
			else
				SplitStringRight(weapon_class, "weapon_", item_name, sizeof(item_name));
			//PrintToChatAll(item_name);
		}else{
			if (IsWeaponMeleeClass(item))
				GetNameWeaponMelee(item, item_name, sizeof(item_name));
			else{
				GetEntityClassname(item, weapon_class, sizeof(weapon_class));
				SplitStringRight(weapon_class, "weapon_", item_name, sizeof(item_name));
			}
			//PrintToChatAll("wspawn: %s",weapon_class);
		}
		//PrintToChatAll("item: %s",item_name);
		for (int i; i < sizeof(WhiteList); i++) {
			if (!StrEqual(WhiteList[i], "") && StrEqual(WhiteList[i], item_name)) {
				return true;
			}
		}
	
	}
	return false;
}

bool IsItemValid(int item) {
	return IsValidWeapon(item) && IsWeaponClassEnable(item) && !IsItemExclude(item);
}

int StringToRGB(char[] ColorString) {
	int colorRGB[3];
	char str_color[16][3];
	TrimString(ColorString);
	ExplodeString(ColorString, ",", str_color, sizeof(str_color), 16);
	colorRGB[0] = StringToInt(str_color[0]);
	colorRGB[1] = StringToInt(str_color[1]);
	colorRGB[2] = StringToInt(str_color[2]);
	
	return colorRGB;
}

bool IsWeaponTimerOn(int weapon){
	return (ItemTime[weapon] > 0 
	&& IsItemValid( EntRefToEntIndex(EntRef[weapon]) ) 
	&& DelayClean[weapon] != INVALID_HANDLE);
}

void StartItemTimer(int weapon) {
	ItemTime[weapon] = Clean_delay;
	EntRef[weapon] = EntIndexToEntRef(weapon);
	DelayClean[weapon] = CreateTimer(1.0, CleanWeapon, weapon, TIMER_REPEAT);
}

void StopItemTimer(int item) {
	if (DelayClean[item] != INVALID_HANDLE)
	{
		KillTimer(DelayClean[item]);
	}
	DelayClean[item] = INVALID_HANDLE;
	ItemTime[item] = -1;
	EntRef[item] = 0;
}

void StopTimers() {
	for (int i = 1; i < sizeof(DelayClean); i++) {
		if (DelayClean[i] != INVALID_HANDLE)
		{
			KillTimer(DelayClean[i]);
		}
		DelayClean[i] = INVALID_HANDLE;
		ItemTime[i] = -1;
		EntRef[i] = 0;
	}
}

void ReloadPlugin() {
	
	for (int i = MaxClients + 1; i <= GetMaxEntities(); i++) {
		if (IsItemValid(i) && !IsWeaponInUse(i)) {
			// SDKUnhook(i, SDKHook_ThinkPost, OnThink);
			// SDKHook(i, SDKHook_ThinkPost, OnThink);
			StartItemTimer(i);
		}
	}
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IS_VALID_CLIENT(i)) {
			SDKUnhook(i, SDKHook_WeaponEquip, OnWeaponEquip);
			SDKUnhook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			SDKHook(i, SDKHook_WeaponEquip, OnWeaponEquip);
			SDKHook(i, SDKHook_WeaponDrop, OnWeaponDrop);
		}
	}
}

void UnloadPlugin() {
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IS_VALID_CLIENT(i)) {
			SDKUnhook(i, SDKHook_WeaponEquip, OnWeaponEquip);
			SDKUnhook(i, SDKHook_WeaponDrop, OnWeaponDrop);
		}
	}
	for (int i = MaxClients + 1; i <= GetMaxEntities(); i++) {
		if (IsItemValid(i)) {
			SDKUnhook(i, SDKHook_SpawnPost, OnSpawn);
			SDKUnhook(i, SDKHook_ThinkPost, OnThink);
			RemoveEffects(i);
		}
	}
	StopTimers();
}

