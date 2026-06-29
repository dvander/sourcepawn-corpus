#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d_info_editor>

//#define DEBUG

#define PLUGIN_NAME			  "[L4D2]Incapped Weapons"
#define PLUGIN_AUTHOR		  "z☣"
#define PLUGIN_DESCRIPTION	  "incapped survivors can switch all your weapons"
#define PLUGIN_VERSION		  "1.4.5"
#define PLUGIN_URL			  "https://forums.alliedmods.net/showthread.php?t=320829"

#define CFG_FILENAME		  "incapped_weapons"
#define CFG_WEAPONLIST		  "data/incapped_weapons_classnamelist.cfg"
#define MAX_STRING_LENGTH	  4096

ConVar cvarEnable;
ConVar cvarSwitch;
ConVar cvarBlockGive;
ConVar cvarSlot[5];

StringMap g_smWeaponClassList;

bool g_bEnable;
bool g_bBockGive;
int g_iSlot[5];
int g_iSwitch;

bool g_bLeft4Dead2;
bool g_bDone;
bool g_bWeaponAllowed;
bool g_bMeleeIncap;
int ipThisIncap;
int g_iMelee[MAXPLAYERS + 1];

char g_sClassNameList[][] =
{	
	//"weapon_pistol",
	//"weapon_pistol_magnum",
	"weapon_chainsaw",
	"weapon_melee",
	"weapon_smg",			
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_pumpshotgun",	
	"weapon_shotgun_chrome",		
	"weapon_shotgun_spas",	
	"weapon_autoshotgun",			
	"weapon_rifle",
	"weapon_rifle_ak47",	
	"weapon_rifle_desert",
	"weapon_rifle_sg552",
	"weapon_rifle_m60",
	"weapon_hunting_rifle",	
	"weapon_sniper_military",	
	"weapon_sniper_scout",
	"weapon_sniper_awp",
	"weapon_grenade_launcher",
	"weapon_pipe_bomb",	
	"weapon_molotov",	
	"weapon_vomitjar",
	"weapon_first_aid_kit",		
	"weapon_defibrillator",		
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary",
	"weapon_pain_pills",		
	"weapon_adrenaline"
};

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_smWeaponClassList = new StringMap();
	LoadWeaponList();
	
	cvarEnable	  = CreateConVar("incapped_weapons_enable", "1","0:Disable, 1:Enable plugin");
	cvarSwitch	  = CreateConVar("incapped_weapons_switch", "2","0:Disable, 1:Force switch to primary weapon, 2: Force switch to secondary weapon");
	cvarBlockGive = CreateConVar("incapped_weapons_blockgive", "0","0:Disable, 1:Prevent give pistol on incapped");
	cvarSlot[0]	  = CreateConVar("incapped_weapons_slot1", "1","0: Disable, 1: Allow weapons of slot1, -1: Allow only switch weapons of slot1");
	cvarSlot[1]	  = CreateConVar("incapped_weapons_slot2", "1","0: Disable, 1: Allow weapons of slot2, -1: Allow only switch weapons of slot2");
	cvarSlot[2]	  = CreateConVar("incapped_weapons_slot3", "1","0: Disable, 1: Allow weapons of slot3, -1: Allow only switch weapons of slot3");
	cvarSlot[3]	  = CreateConVar("incapped_weapons_slot4", "1","0: Disable, 1: Allow weapons of slot4, -1: Allow only switch weapons of slot4");
	cvarSlot[4]	  = CreateConVar("incapped_weapons_slot5", "1","0: Disable, 1: Allow weapons of slot5, -1: Allow only switch weapons of slot5");
	AutoExecConfig(true, CFG_FILENAME);
	
	cvarEnable.AddChangeHook(CvarChanged_Enable);
	cvarSwitch.AddChangeHook(CvarsChanged);
	cvarBlockGive.AddChangeHook(CvarsChanged);
	cvarSlot[0].AddChangeHook(CvarsChanged);
	cvarSlot[1].AddChangeHook(CvarsChanged);
	cvarSlot[2].AddChangeHook(CvarsChanged);
	cvarSlot[3].AddChangeHook(CvarsChanged);
	cvarSlot[4].AddChangeHook(CvarsChanged);
	
	RegAdminCmd("sm_iw_reload", CmdReloadCfg, ADMFLAG_CHEATS, "reload config data weapons list(incapped_weapons_classnamelist.cfg)");
	EnablePlugin();
}

public void OnAllPluginsLoaded()
{
	if( LibraryExists("info_editor") == false )
	{
		SetFailState("Info Editor Test cannot start 'l4d_info_editor.smx' plugin not loaded.");
	}
}

public Action CmdReloadCfg(int client, int args)
{	
	LoadWeaponList();
	ReplyToCommand(client, "reloaded: incapped_weapons_classnamelist.cfg");
	return Plugin_Handled;
}

void LoadWeaponList(){
	//get file
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CFG_WEAPONLIST);
	//create file
	KeyValues hFile = new KeyValues("weaponlist");
	if(!FileExists(sPath)){
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
		
		if(KvJumpToKey(hFile, "classname", true))
		{
			for( int i = 0; i < sizeof(g_sClassNameList); i++ )
				hFile.SetNum(g_sClassNameList[i], 1);
			hFile.Rewind();
			hFile.ExportToFile(sPath);
		}
		BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CFG_WEAPONLIST);
	}
	// Load config
	if(FileExists(sPath)){
		if( hFile.ImportFromFile(sPath) )
		{
			if(KvJumpToKey(hFile, "classname", true)){
				for( int i = 0; i < sizeof(g_sClassNameList); i++ ){
					if(hFile.GetNum(g_sClassNameList[i]) != 0)
						g_smWeaponClassList.SetValue(g_sClassNameList[i], true, true);
					else
						g_smWeaponClassList.SetValue(g_sClassNameList[i], false, true);
				}
				hFile.Rewind();
			}
		}
	}
	delete hFile;
}

void EnablePlugin(){
	g_bEnable = cvarEnable.BoolValue;
	if(g_bEnable){
		HookEvents();
	}
	GetCvars();
}

public void CvarChanged_Enable(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnable = convar.BoolValue;
	if (g_bEnable && !StringToInt(oldValue))
		HookEvents();
	else if (!g_bEnable && StringToInt(oldValue))
		UnHookEvents();
}

public void CvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars(){
	g_iSwitch = cvarSwitch.IntValue;
	g_bBockGive = cvarBlockGive.BoolValue;
	g_iSlot[0] = cvarSlot[0].IntValue;
	g_iSlot[1] = cvarSlot[1].IntValue;
	g_iSlot[2] = cvarSlot[2].IntValue;
	g_iSlot[3] = cvarSlot[3].IntValue;
	g_iSlot[4] = cvarSlot[4].IntValue;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(IsValidSurvivor(client) && IsPlayerAlive(client) && IsPlayerIncapped(client)){
		int weapon = GetActiveWeapon(client);
		int slot = GetSlotWeapon(client, weapon);
		if((buttons & IN_ATTACK)){
			SetIncappedWeapons();
			if(IsValidWeapon(weapon) && (slot >= 0) && (g_iSlot[slot] == -1))
				SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 1.0);
		}
	}
}

int GetSlotWeapon(int client, int weapon, int maxslots = 5){

	for (int i=0; i < maxslots; i++) 
	{
		int w = GetPlayerWeaponSlot(client, i);
		if (IsValidWeapon(w)){
			if (w == weapon)
			{
				return i;
			}
		}
	}
	return -1;
}

public Action OnWeaponEquip(int client, int weapon) {
	SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	if(IsValidSurvivor(client) && IsPlayerAlive(client) && IsPlayerIncapped(client)){
		int wmelee = EntRefToEntIndex(g_iMelee[client]);
		if(IsWeaponMelee(wmelee)){
			EquipPlayerWeapon(client, wmelee);
			g_iMelee[client] = 0;
			if(IsWeaponSinglePistol(weapon))
				return Plugin_Handled;
		}
		else if(g_bBockGive && IsWeaponSinglePistol(weapon)){
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void Event_ResetInfoWeapons(Event event, const char[] name, bool dontBroadcast)
{
	UnSetIncappedWeapons();
}

public Action Event_IncappedStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	if(IsValidSurvivor(client) && IsPlayerAlive(client)){
		SetIncappedWeapons();
		
		if(!g_bLeft4Dead2)
			return;
			
		int wslot2 = GetPlayerWeaponSlot(client, 1);
		g_smWeaponClassList.GetValue("weapon_melee", g_bWeaponAllowed);
		if(IsWeaponMelee(wslot2) && g_iSlot[1] && g_bWeaponAllowed && !g_bMeleeIncap){
			g_iMelee[client] = EntIndexToEntRef(wslot2);
			RemovePlayerItem(client, wslot2);
			SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
			return;
		}else
			g_iMelee[client] = 0;
		
		if(wslot2 == -1){
			SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		}
	}
}

public void Event_Incapped(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	if(IsValidSurvivor(client) && IsPlayerAlive(client) && IsPlayerIncapped(client)){
		SetIncappedWeapons();
	
		if(!g_iSwitch)
			return;
			
		int weapon_active=GetActiveWeapon(client);
		int weapon_second=GetPlayerWeaponSlot(client, 1);
		int weapon_primary=GetPlayerWeaponSlot(client, 0);
		if(IsValidWeapon(weapon_active)){
			if(weapon_active == weapon_second && g_iSwitch == 2)
				return;
			if(weapon_active == weapon_primary && g_iSwitch == 1)
				return;
		}
		CreateTimer(0.1, SwitchWeaponIncapped, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void Event_CheckIncappeds(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	if(IsValidSurvivor(client)){
		CreateTimer(0.5, CheckIncappeds, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action CheckIncappeds(Handle timer){
	if(!IsAnySurvivorIncap()){
		UnSetIncappedWeapons();
	}	
}

public void OnGetWeaponsInfo(int pThis, const char[] classname)
{
	if(!g_bEnable)
		return;
	
	if(ipThisIncap == -1)
		ipThisIncap = pThis;
	if(ipThisIncap == pThis)
	{
		char sResult[MAX_STRING_LENGTH];
		InfoEditor_GetString(pThis, "bucket", sResult, sizeof sResult);
		int slot = -1;
		StringToIntEx(sResult, slot);
		if(slot < 0 || slot > 4 || !g_iSlot[slot]){
			return;
		}

		if(g_smWeaponClassList.GetValue(classname, g_bWeaponAllowed) && g_bWeaponAllowed)
		{	
			InfoEditor_SetString(pThis, "WeaponType", "pistol");
		}
		
	}else{
		g_bDone = false;
	}
		
	if((strcmp(classname, "weapon_melee") == 0)){
		char sTemp[32];
		InfoEditor_GetString(pThis, "WeaponType", sTemp, sizeof(sTemp));
		g_bMeleeIncap = (strcmp(sTemp, "pistol") == 0);
	}
}

public Action SwitchWeaponIncapped(Handle timer, any userid){
	int client = GetClientOfUserId(userid);
	if(!IsValidSurvivor(client) || !IsPlayerAlive(client) || !IsPlayerIncapped(client))
		return;
		
	int weapon_switch;
	int weapon_active=GetActiveWeapon(client);
	int weapon_second=GetPlayerWeaponSlot(client, 1);
	int weapon_primary=GetPlayerWeaponSlot(client, 0);
	
	if(IsValidWeapon(weapon_active)){
		if(weapon_active == weapon_second && g_iSwitch == 2)
			return;
		if(weapon_active == weapon_primary && g_iSwitch == 1)
			return;
	}
	
	if(g_iSwitch == 1){
		weapon_switch = IsValidWeapon(weapon_primary) ? weapon_primary : weapon_second;
	}else if(g_iSwitch == 2){
		weapon_switch = IsValidWeapon(weapon_second) ? weapon_second : weapon_primary;
	}

	if(IsValidWeapon(weapon_switch) && IsPlayerWeapon(client, weapon_switch)){
		char weapon_name[64];
		GetEntityClassname(weapon_switch, weapon_name, sizeof(weapon_name));
		FakeClientCommand(client, "use %s", weapon_name);
	}
}

bool IsPlayerWeapon(int client, int weapon){

	int owner = GetEntPropEnt(weapon, Prop_Data, "m_hOwner");
	int ownerent = GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity");
	return (ownerent == client && owner == client);
}

bool IsAnySurvivorIncap(){
	for (int i = 1; i <= MaxClients; i++){
		if ( IsValidSurvivor(i) && IsPlayerAlive(i) && IsPlayerIncapped(i) ){
			return true;
		}
	}
	return false;
}

void SetIncappedWeapons(){
	if(!g_bDone){
		g_bDone = true;
		ipThisIncap = -1;
		InfoEditor_ReloadData();
		//ServerCommand("sm_info_reload");
	}
}

void UnSetIncappedWeapons(){
	if(g_bDone){
		g_bDone = false;
		InfoEditor_ReloadData();
		//ServerCommand("sm_info_reload");
	}
}

bool IsWeaponMelee(int weapon){
	return (IsWeaponMeleeClass(weapon) || IsWeaponChainSaw(weapon));
}

stock int GetActiveWeapon(int client){
	return GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
}

stock void SetActiveWeapon(int client, int weapon){
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	ChangeEdictState(client, FindDataMapInfo(client, "m_hActiveWeapon"));
}

stock bool IsWeaponChainSaw(int weapon){

	if(IsValidWeapon(weapon))
	{
		char class_name[64];
		GetEntityClassname(weapon, class_name, sizeof(class_name));
		return (strcmp(class_name, "weapon_chainsaw") == 0);
	}
	return false;
}

stock bool IsWeaponMeleeClass(int weapon){
	if(IsValidWeapon(weapon))
	{
		char class_name[64];
		GetEntityClassname(weapon, class_name, sizeof(class_name));
		return (strcmp(class_name, "weapon_melee") == 0);
	}
	return false;
}

stock bool IsWeaponSinglePistol(int weapon){
	if(IsValidWeapon(weapon))
	{
		char class_name[64];
		GetEntityClassname(weapon, class_name, sizeof(class_name));
		return (strcmp(class_name, "weapon_pistol") == 0 && GetEntProp(weapon, Prop_Send, "m_hasDualWeapons") == 0);
	}
	return false;
}

stock bool IsValidWeapon(int weapon)
{
	if (IsValidEnt(weapon)) {
		char class_name[64];
		GetEntityClassname(weapon,class_name,sizeof(class_name));
		return (strncmp(class_name, "weapon_", 7) == 0);
	}
	return false;
}

stock bool IsPlayerHanding(int client){
	return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 1);
}

stock bool IsPlayerIncapped(int client){
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1);
}

stock bool IsValidSpect(int client){ 
	return (IsValidClient(client) && GetClientTeam(client) == 1 );
}

stock bool IsValidSurvivor(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 2 );
}

stock bool IsValidInfected(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 3 );
}

stock bool IsValidClient(int client){
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsValidEnt(int entity){
	return (entity != INVALID_ENT_REFERENCE && entity > MaxClients && IsValidEntity(entity));
}

void HookEvents(){
	HookEvent("player_incapacitated", Event_Incapped);
	HookEvent("player_incapacitated_start",	Event_IncappedStart, EventHookMode_Pre);
	if(g_bLeft4Dead2){
		HookEvent("round_end", Event_ResetInfoWeapons);
		HookEvent("server_spawn", Event_ResetInfoWeapons);
		HookEvent("map_transition", Event_ResetInfoWeapons);
		HookEvent("finale_win", Event_ResetInfoWeapons);
		HookEvent("revive_success",	Event_CheckIncappeds);
		HookEvent("player_death",	Event_CheckIncappeds);
	}
}	

void UnHookEvents(){
	UnhookEvent("player_incapacitated", Event_Incapped);
	UnhookEvent("player_incapacitated_start", Event_IncappedStart, EventHookMode_Pre);
	if(g_bLeft4Dead2){
		UnhookEvent("round_end", Event_ResetInfoWeapons);
		UnhookEvent("server_spawn", Event_ResetInfoWeapons);
		UnhookEvent("map_transition", Event_ResetInfoWeapons);
		UnhookEvent("finale_win", Event_ResetInfoWeapons);
		UnhookEvent("revive_success", Event_CheckIncappeds);
		UnhookEvent("player_death", Event_CheckIncappeds);
	}
} 