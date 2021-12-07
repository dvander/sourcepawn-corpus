/*
* #################################
* #      DoD:S Capture Bonus      #
* #################################
* 
* @author BackAgain aka sMash
* @email owner@hpherzog.de
* @version 1.2.0
*/

#include <sourcemod>
#include <sdktools>

// Plugin
#define PLUGIN_VERSION 		"1.2.0"
#define PLUGIN_TAG 			"[Capture Bonus]"
#define PLUGIN_CONFIG_FILE 	"dod_capture_bonus.cfg"

// Maximum buffer size
#define MAX_LENGTH_WEAPON 		64
#define MAX_LENGTH_MENU_ITEM 	128
#define MAX_LENGTH_PHRASE		1024
#define MAX_PLAYERS 			64
#define MAX_WEAPONS 			24
#define MAX_WEAPON_CLASSES		6
#define MAX_WEAPON_SLOTS		4
#define MAX_BONI				7

// Teams
#define TEAM_ALLIES 	0
#define TEAM_AXIS 		1

// Classes
#define CLASS_RIFLEMAN 	0
#define CLASS_ASSAULT 	1
#define CLASS_SUPPORT 	2
#define CLASS_SNIPER 	3
#define CLASS_MG 		4
#define CLASS_ROCKET 	5

#define WEAPON_EMPTY			-1
#define WEAPON_AMERKNIFE 		0
#define WEAPON_SPADE 			1
#define WEAPON_SMOKE_US			2
#define WEAPON_SMOKE_GER		3
#define WEAPON_FRAG_US			4
#define WEAPON_FRAG_GER			5
#define WEAPON_RIFLEGREN_US		6
#define WEAPON_RIFLEGREN_GER	7
#define WEAPON_COLT				8
#define WEAPON_P38				9
#define WEAPON_GARAND			10
#define WEAPON_K98				11
#define WEAPON_THOMPSON			12
#define WEAPON_MP40				13
#define WEAPON_BAR				14
#define WEAPON_MP44				15
#define WEAPON_30CAL			16
#define WEAPON_MG42				17
#define WEAPON_SPRING			18
#define WEAPON_K98_SCOPED		19
#define WEAPON_BAZOOKA			20
#define WEAPON_PSCHRECK			21
#define WEAPON_M1CARBINE		22
#define WEAPON_C96				23

#define WEAPON_SLOT1			0
#define WEAPON_SLOT2			1
#define WEAPON_SLOT3			2
#define WEAPON_SLOT4			3

#define BONUS_EXTRA_AMMO		0
#define BONUS_EXTRA_HEALTH		1
#define BONUS_GOD				2
#define BONUS_INVISIBLE			3
#define BONUS_GRANADES			4
#define BONUS_SECONDARY			5
#define BONUS_STAMINA			6

// All boni
new String:Boni[][] = {
	"extra_ammo",
	"extra_health",
	"god",
	"invisible",
	"unlimited_granades",
	"secondary_weapon",
	"unlimited_stamina"
}

// All weapons
new String:Weapons[][] = {

		"weapon_amerknife",
		"weapon_spade",
		"weapon_smoke_us",
		"weapon_smoke_ger",
		"weapon_frag_us",
		"weapon_frag_ger",
		"weapon_riflegren_us",
		"weapon_riflegren_ger",
		"weapon_colt",
		"weapon_p38",
		"weapon_garand",
		"weapon_k98",
		"weapon_thompson",
		"weapon_mp40",
		"weapon_bar",
		"weapon_mp44",
		"weapon_30cal",
		"weapon_mg42",
		"weapon_spring",
		"weapon_k98_scoped",
		"weapon_bazooka",
		"weapon_pschreck",
		"weapon_m1carbine",
		"weapon_c96"
}

// Weapon class definitions
new WeaponClasses[][][] = 
{
	{
		{WEAPON_GARAND,WEAPON_EMPTY,WEAPON_AMERKNIFE,WEAPON_RIFLEGREN_US},
		{WEAPON_THOMPSON,WEAPON_COLT,WEAPON_SMOKE_US,WEAPON_FRAG_US},
		{WEAPON_BAR,WEAPON_EMPTY,WEAPON_AMERKNIFE,WEAPON_FRAG_US},
		{WEAPON_SPRING,WEAPON_COLT,WEAPON_AMERKNIFE,WEAPON_EMPTY},
		{WEAPON_30CAL,WEAPON_COLT,WEAPON_AMERKNIFE,WEAPON_EMPTY},
		{WEAPON_BAZOOKA,WEAPON_M1CARBINE,WEAPON_AMERKNIFE,WEAPON_EMPTY}
	},

	{
		{WEAPON_K98,WEAPON_EMPTY,WEAPON_SPADE,WEAPON_RIFLEGREN_GER},
		{WEAPON_MP40,WEAPON_P38,WEAPON_SMOKE_GER,WEAPON_FRAG_GER},
		{WEAPON_MP44,WEAPON_EMPTY,WEAPON_SPADE,WEAPON_FRAG_GER},
		{WEAPON_K98_SCOPED,WEAPON_P38,WEAPON_SPADE,WEAPON_EMPTY},
		{WEAPON_MG42,WEAPON_P38,WEAPON_SPADE,WEAPON_EMPTY},
		{WEAPON_PSCHRECK,WEAPON_C96,WEAPON_SPADE,WEAPON_EMPTY}
	}
}

// Property offsets
new WeaponAmmoOffsets[] = {
		
		0,0,68,72,52,56,84,88,4,8,16,20,32,32,36,32,40,44,28,20,48,48,24,12
}

// Default weapon clip sizes
new WeaponClipSizes[] = {
		
		0,0,1,1,1,1,1,1,7,8,8,5,30,30,20,30,150,250,5,5,1,1,15,20
}

new PlayerCapturedFlags[MAX_PLAYERS+1]
new bool:PlayerIsGod[MAX_PLAYERS+1]
new bool:PlayerIsInvisible[MAX_PLAYERS+1]
new Handle:PlayerGranadeTimer[MAX_PLAYERS+1]
new Handle:PlayerStaminaTimer[MAX_PLAYERS+1]

// Configuration variables
new Handle:Config

// Extra ammo
new ExtraAmmoEnabled = 0
new ExtraAmmoFlags = 0
new ExtraAmmoPeriodic = 0
new ExtraAmmoClips[MAX_WEAPONS]

// Extra health
new ExtraHealthEnabled = 0
new ExtraHealthFlags = 0
new ExtraHealthPeriodic = 0
new ExtraHealthAmount = 0

// God mode
new GodModeEnabled = 0
new GodModeFlags = 0
new GodModePeriodic = 0
new GodModeTime = 0

// Invisible
new InvisibleEnabled = 0
new InvisibleFlags = 0
new InvisiblePeriodic = 0
new InvisibleTime = 0

// Unlimited granades
new GranadesEnabled = 0
new GranadesFlags = 0
new GranadesPeriodic = 0

// Secondary weapon
new SecondaryEnabled = 0
new SecondaryFlags = 0
new SecondaryPeriodic = 0
new SecondaryClips = 0

// Stamina
new StaminaEnabled = 0
new StaminaFlags = 0
new StaminaPeriodic = 0
new StaminaTime = 0

// Cvars
new Handle:CvarEnabled

public Plugin:myinfo = 
{
	name = "DoD:S Capture Bonus",
	author = "BackAgain",
	description = "After capturing an amount of flags you can get a bonus, like extra ammo or extra health.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart() {
	Init()
}

// Does very important initialization stuff
public Init() {
	
	LoadTranslations("dod_capture_bonus.phrases")
	LoadConfigFile(PLUGIN_CONFIG_FILE)
	
	CreateConVar("sm_capbon_version", PLUGIN_VERSION,"DoD:S Capture Bonus version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED)
	CvarEnabled = CreateConVar("sm_capbon_enabled", "1", "Enables or disables DoD:S Capture Bonus.",FCVAR_PLUGIN|FCVAR_REPLICATED)
	
	HookConVarChange(CvarEnabled, OnEnabledChange)
	
	HookEvent("dod_point_captured", EventPointCaptured)
	HookEvent("player_hurt", EventPlayerHurt)
	HookEvent("player_spawn", EventPlayerSpawn)
}

// Cleans up this plugin
public Dispose() {
	UnhookEvent("dod_point_captured", EventPointCaptured)
	UnhookEvent("player_hurt", EventPlayerHurt)
	UnhookEvent("player_spawn", EventPlayerSpawn)
}

// Handles the change of the cvar "sm_capbon_enabled"
public OnEnabledChange(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (StringToInt(newVal) == 1) {
		Init()
		PrintChatAll("Enabled!")
	}
	else {
		Dispose()
		PrintChatAll("Disabled!")
	}
}

// Loads the config file into global variables
public LoadConfigFile(const String:configFile[])
{	
	// File to key values
	new String:configFilePath[PLATFORM_MAX_PATH]
	BuildPath(Path_SM,configFilePath,sizeof(configFilePath),"configs/%s",configFile)
	Config = CreateKeyValues("dod_capture_bonus")
	FileToKeyValues(Config,configFilePath)
	
	// Extra ammo
	KvJumpToKey(Config,Boni[BONUS_EXTRA_AMMO])
	ExtraAmmoEnabled = KvGetNum(Config,"enabled",0)
	ExtraAmmoFlags = KvGetNum(Config,"flags",0)
	ExtraAmmoPeriodic = KvGetNum(Config,"periodic",0)
	KvJumpToKey(Config,"clips")
	for(new i=0; i < sizeof(ExtraAmmoClips); i++) {
		ExtraAmmoClips[i] = KvGetNum(Config,Weapons[i],0)	
	}
	KvRewind(Config)
	
	// Extra health
	KvJumpToKey(Config,Boni[BONUS_EXTRA_HEALTH])
	ExtraHealthEnabled = KvGetNum(Config,"enabled",0)
	ExtraHealthFlags = KvGetNum(Config,"flags",0)
	ExtraHealthPeriodic = KvGetNum(Config,"periodic",0)
	ExtraHealthAmount = KvGetNum(Config,"amount",0)
	KvRewind(Config)	

	// God mode
	KvJumpToKey(Config,Boni[BONUS_GOD])
	GodModeEnabled = KvGetNum(Config,"enabled",0)
	GodModeFlags = KvGetNum(Config,"flags",0)
	GodModePeriodic = KvGetNum(Config,"periodic",0)
	GodModeTime = KvGetNum(Config,"time",0)
	KvRewind(Config)
	
	// Invisible
	KvJumpToKey(Config,Boni[BONUS_INVISIBLE])
	InvisibleEnabled = KvGetNum(Config,"enabled",0)
	InvisibleFlags = KvGetNum(Config,"flags",0)
	InvisiblePeriodic = KvGetNum(Config,"periodic",0)
	InvisibleTime = KvGetNum(Config,"time",0)
	KvRewind(Config)
	
	// Unlimited granades
	KvJumpToKey(Config,Boni[BONUS_GRANADES])
	GranadesEnabled = KvGetNum(Config,"enabled",0)
	GranadesFlags = KvGetNum(Config,"flags",0)
	GranadesPeriodic = KvGetNum(Config,"periodic",0)
	KvRewind(Config)
	
	// Secondary weapon
	KvJumpToKey(Config,Boni[BONUS_SECONDARY])
	SecondaryEnabled = KvGetNum(Config,"enabled",0)
	SecondaryFlags = KvGetNum(Config,"flags",0)
	SecondaryPeriodic = KvGetNum(Config,"periodic",0)
	SecondaryClips = KvGetNum(Config,"clips",0)
	KvRewind(Config)
	
	// Stamina
	KvJumpToKey(Config,Boni[BONUS_STAMINA])
	StaminaEnabled = KvGetNum(Config,"enabled",0)
	StaminaFlags = KvGetNum(Config,"flags",0)
	StaminaPeriodic = KvGetNum(Config,"periodic",0)
	StaminaTime = KvGetNum(Config,"time",0)
	KvRewind(Config)
}

// Resets client data
public ResetClientData(client) {
	ResetFlags(client)
	ResetBonusData(client)
}

public ResetBonusData(client) {
	PlayerIsGod[client] = false
	PlayerIsInvisible[client] = false
	
	if(PlayerStaminaTimer[client] != INVALID_HANDLE) {
		CloseHandle(PlayerStaminaTimer[client])
		PlayerStaminaTimer[client] = INVALID_HANDLE
	}
	
	if(PlayerGranadeTimer[client] != INVALID_HANDLE) {
		CloseHandle(PlayerGranadeTimer[client])
		PlayerGranadeTimer[client] = INVALID_HANDLE
	}
}

public ResetFlags(client) {
	PlayerCapturedFlags[client] = 0
}

public OnClientPutInServer(client) {
	ResetClientData(client)
}

public OnClientDisconnect(client) {
	ResetClientData(client)
}

// Prints a chat message to all players
public PrintChatAll(const String:message[]) {
	PrintToChatAll("\x04%s \x01%s",PLUGIN_TAG,message)
}

// Prints a chat message to a player
public PrintChat(client,const String:message[]) {
	PrintToChat(client,"\x04%s \x01%s",PLUGIN_TAG,message)
}

// Sets the color of all weapons
public DodSetWeaponColor(client,r,g,b,o) {
	for(new i=0; i < 4; i++) {
		new entity = GetPlayerWeaponSlot(client,i)
		if(entity != -1) {
			SetEntityRenderMode(entity,RENDER_TRANSCOLOR)
			SetEntityRenderColor(entity,r,g,b,o)		
		}
	}	
}

/*
* ####################
* #  Bonus handling  #
* ####################
*/

// Apply bonus
public ApplyBonus(client,const String:bonus[]) {
	
	// Extra ammo
	if(StrEqual(Boni[BONUS_EXTRA_AMMO],bonus,false)) {
		DodStartExtraAmmo(client)
	}
	// Extra health
	else if(StrEqual(Boni[BONUS_EXTRA_HEALTH],bonus,false)) {
		DodStartExtraHealth(client)
	}
	// God mode
	else if(StrEqual(Boni[BONUS_GOD],bonus,false)) {
		DodStartGodMode(client)
	}
	// Invisible
	else if(StrEqual(Boni[BONUS_INVISIBLE],bonus,false)) {
		DodStartInvisible(client)
	}
	// Unlimited granades
	else if(StrEqual(Boni[BONUS_GRANADES],bonus,false)) {
		DodStartGranades(client)
	}
	// Secondary weapon
	else if(StrEqual(Boni[BONUS_SECONDARY],bonus,false)) {
		DodStartSecondaryWeapon(client)
	}
	// Unlimited stamina
	else if(StrEqual(Boni[BONUS_STAMINA],bonus,false)) {
		DodStartStamina(client)
	}
}

// Handles the bonus
public HandleBonus(client) {

	new bonusCount = 0
	new bool:playerBoni[sizeof(Boni)]
	
	// Extra ammo
	if(ExtraAmmoEnabled == 1) {
		new bool:period = false
		if(ExtraAmmoPeriodic == 1 && PlayerCapturedFlags[client] > 0 && ExtraAmmoFlags > 0) {
			period = (PlayerCapturedFlags[client]%ExtraAmmoFlags) == 0
		}
		
		if(ExtraAmmoFlags == 0 || PlayerCapturedFlags[client] == ExtraAmmoFlags || period) {
			bonusCount++
			playerBoni[BONUS_EXTRA_AMMO] = true
		}
	}
	
	// Extra health
	if(ExtraHealthEnabled == 1) {
		new bool:period = false
		if(ExtraHealthPeriodic == 1 && PlayerCapturedFlags[client] > 0 && ExtraHealthFlags > 0) {
			period = (PlayerCapturedFlags[client]%ExtraHealthFlags) == 0
		}	
	
		if(ExtraHealthFlags == 0 || PlayerCapturedFlags[client] == ExtraHealthFlags || period) {
			bonusCount++
			playerBoni[BONUS_EXTRA_HEALTH] = true
		}		
	}
	
	// God mode
	if(GodModeEnabled == 1) {
		new bool:period = false
		if(GodModePeriodic == 1 && PlayerCapturedFlags[client] > 0 && GodModeFlags > 0) {
			period = (PlayerCapturedFlags[client]%GodModeFlags) == 0
		}		
		
		if(GodModeFlags == 0 || PlayerCapturedFlags[client] == GodModeFlags || period) {
			bonusCount++
			playerBoni[BONUS_GOD] = true
		}		
	}
	
	// Invisible
	if(InvisibleEnabled == 1) {
		new bool:period = false
		if(InvisiblePeriodic == 1 && PlayerCapturedFlags[client] > 0 && InvisibleFlags > 0) {
			period = (PlayerCapturedFlags[client]%InvisibleFlags) == 0
		}		
		
		if(InvisibleFlags == 0 || PlayerCapturedFlags[client] == InvisibleFlags || period) {
			bonusCount++
			playerBoni[BONUS_INVISIBLE] = true
		}		
	}

	// Unlimited granades
	if(GranadesEnabled == 1) {
		new bool:period = false
		if(GranadesPeriodic == 1 && PlayerCapturedFlags[client] > 0 && GranadesFlags > 0) {
			period = (PlayerCapturedFlags[client]%GranadesFlags) == 0
		}		
		
		if(GranadesFlags == 0 || PlayerCapturedFlags[client] == GranadesFlags || period) {
			bonusCount++
			playerBoni[BONUS_GRANADES] = true
		}		
	}	

	// Secondary weapon
	if(SecondaryEnabled == 1) {
		new bool:period = false
		if(SecondaryPeriodic == 1 && PlayerCapturedFlags[client] > 0 && SecondaryFlags > 0) {
			period = (PlayerCapturedFlags[client]%SecondaryFlags) == 0
		}		
		
		if(SecondaryFlags == 0 || PlayerCapturedFlags[client] == SecondaryFlags || period) {
			bonusCount++
			playerBoni[BONUS_SECONDARY] = true
		}		
	}	

	// Stamina
	if(StaminaEnabled == 1) {
		new bool:period = false
		if(StaminaPeriodic == 1 && PlayerCapturedFlags[client] > 0 && StaminaFlags > 0) {
			period = (PlayerCapturedFlags[client]%StaminaFlags) == 0
		}		
		
		if(StaminaFlags == 0 || PlayerCapturedFlags[client] == StaminaFlags || period) {
			bonusCount++
			playerBoni[BONUS_STAMINA] = true
		}		
	}	
	
	if(bonusCount > 1) {
		ShowBonusMenu(client,playerBoni)
	} else {
		for(new i=0; i < sizeof(playerBoni); i++) {
			if(playerBoni[i]) {
				ApplyBonus(client,Boni[i])
			}
		}
	}
}

// Handles the bonus menu
public HandleBonusMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		new String:item[MAX_LENGTH_MENU_ITEM]
		GetMenuItem(menu, param2, item, sizeof(item))
		ApplyBonus(param1,item)
	} 
	else if (action == MenuAction_Cancel) {
		
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu)
	}
}
 
// Shows up the bonus menu
public ShowBonusMenu(client,bool:playerBoni[]) {
	
	new Handle:menu = CreateMenu(HandleBonusMenu)
	
	new String:menuTitle[MAX_LENGTH_MENU_ITEM]
	Format(menuTitle, sizeof(menuTitle), "%T", "menu_title", LANG_SERVER)
	SetMenuTitle(menu,menuTitle)
	
	for(new i=0; i < MAX_BONI; i++) {
		if(playerBoni[i]) {
			new String:menuItemName[MAX_LENGTH_MENU_ITEM]
			Format(menuItemName,sizeof(menuItemName),"menu_%s",Boni[i])
			
			new String:menuItem[MAX_LENGTH_MENU_ITEM]
			Format(menuItem, sizeof(menuItem), "%T", menuItemName, LANG_SERVER)
			AddMenuItem(menu,Boni[i],menuItem)
		}
	}
	
	SetMenuExitButton(menu, false)
	DisplayMenu(menu, client, 20)
}

/*
* #####################
* #       Events      #
* #####################
*/

// Handles the "dod_point_captured" event
public Action:EventPointCaptured(Handle:event, const String:name[], bool:dontBroadcast) {
	
	new String:cappers[256]
	GetEventString(event,"cappers",cappers,sizeof(cappers))
	for(new i=0; i < strlen(cappers); i++) {
		new client = cappers[i]
		PlayerCapturedFlags[client]++
		HandleBonus(client)
	}
}

// Handles the "player_hurt" event
public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	
	new client = GetClientOfUserId(GetEventInt(event,"userid"))
	
	// God mode
	if(PlayerIsGod[client]) {
			DodSetHealth(client,1000)
	}
}

// Handles the "player_spawn" event
public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	
	new client = GetClientOfUserId(GetEventInt(event,"userid"))
	ResetBonusData(client)	
}

/*
* #####################
* # Player properties #
* #####################
*/

// Gets the players health
public DodGetHealth(client) {
	return GetEntProp(client,Prop_Send,"m_iHealth")
}

// Sets the health of a player
public DodSetHealth(client,health) {
	SetEntProp(client,Prop_Send,"m_iHealth",health)
}

// Gets the players class
public DodGetClass(client) {
	return GetEntProp(client,Prop_Send,"m_iPlayerClass")
}

// Gets the players team
public DodGetTeam(client) {
	return GetEntProp(client,Prop_Send,"m_iTeamNum") - 2
}

// Gets the ammo of a players weapon
public DodGetAmmo(client,weapon) {
	new offset = FindSendPropOffs("CDODPlayer", "m_iAmmo")
	return GetEntData(client,offset + WeaponAmmoOffsets[weapon],4)
}

// Sets the ammo of a given player and weapon
public DodSetAmmo(client,weapon,ammo) {
	new offset = FindSendPropOffs("CDODPlayer", "m_iAmmo")
	SetEntData(client,offset+WeaponAmmoOffsets[weapon],ammo,4,true)
}

// Gets the weapon of a specific slot
public DodGetWeapon(client,slot) {
	
	new entity = GetPlayerWeaponSlot(client, slot)
	new String:weaponName[MAX_LENGTH_WEAPON]
	if(entity != -1) {
		GetEdictClassname(entity,weaponName,sizeof(weaponName))
		for(new i=0; i < sizeof(Weapons); i++) {
			if(StrEqual(weaponName,Weapons[i],false)) {
				return i
			}
		}
	}
	return WEAPON_EMPTY
}

// Gets the default weapon of a given slot
public DodGetDefaultWeapon(client,slot) {
	new team = DodGetTeam(client)
	new class = DodGetClass(client)
	return WeaponClasses[team][class][slot]	
}

// Gets the stamina
public Float:DodGetStamina(client) {
	GetEntPropFloat(client,Prop_Send,"m_flStamina")
}

// Sets the stamina
public DodSetStamina(client,Float:stamina) {
	SetEntPropFloat(client,Prop_Send,"m_flStamina",stamina)
}

/*
* ####################
* #  Player actions  #
* ####################
*/

// Adds clips to a players weapon
public DodGiveClips(client,weapon,clips) {
	new ammo = DodGetAmmo(client,weapon)
	DodSetAmmo(client,weapon,ammo+WeaponClipSizes[weapon]*clips)
}

// Sets clips of a palyers weapon
public DodSetClips(client,weapon,clips) {
	DodSetAmmo(client,weapon,WeaponClipSizes[weapon]*clips)
}

// Removes a weapon of a given slot
public DodRemoveWeapon(client,slot) {
	new entity = GetPlayerWeaponSlot(client, slot)
	if(entity != -1) {
		RemovePlayerItem(client,entity)
	}
}

// Removes all the players weapons
public DodRemoveWeapons(client) {
	for(new i=0; i < 4; i++) {
		DodRemoveWeapon(client,i)
	}
}

/*
* ####################
* #        Boni      #
* ####################
*/

/*
* Extra ammo
*/

// Gives a player an extra amount of ammo
public DodStartExtraAmmo(client) {
	
	for(new slot=WEAPON_SLOT1; slot < MAX_WEAPON_SLOTS; slot++) {
		new weapon = DodGetWeapon(client,slot)
		new defaultWeapon = DodGetDefaultWeapon(client,slot)
		
		if(weapon == WEAPON_EMPTY && defaultWeapon != WEAPON_EMPTY) {
			GivePlayerItem(client,Weapons[defaultWeapon])
			DodSetClips(client,defaultWeapon,ExtraAmmoClips[defaultWeapon])
		}
		else if(weapon != WEAPON_EMPTY) {
			DodGiveClips(client,weapon,ExtraAmmoClips[weapon])
		}
	}
	
	new String:message[MAX_LENGTH_PHRASE]
	Format(message, sizeof(message), "%T", "message_extra_ammo", LANG_SERVER, client)
	PrintChat(client,message)	
}

/*
* Extra health
*/

// Gives a player some extra health
public DodStartExtraHealth(client) {
	new newHealth = DodGetHealth(client)+ExtraHealthAmount
	DodSetHealth(client,newHealth)
	
	new String:message[MAX_LENGTH_PHRASE]
	Format(message, sizeof(message), "%T", "message_extra_health", LANG_SERVER, client, ExtraHealthAmount, newHealth)
	PrintChat(client,message)
}

/*
* God
*/

// Starts god mode
public DodStartGodMode(client) {
	SetEntityRenderMode(client,RENDER_TRANSCOLOR)
	SetEntityRenderColor(client,0,255,0,255)
	DodSetWeaponColor(client,0,255,0,255)
	DodSetHealth(client,1000)
	PlayerIsGod[client] = true
	CreateTimer(float(GodModeTime),DodStopGodMode,client,TIMER_FLAG_NO_MAPCHANGE)
	
	new String:message[MAX_LENGTH_PHRASE]
	Format(message, sizeof(message), "%T", "message_god_start", LANG_SERVER, client, GodModeTime)
	PrintChat(client,message)
}

// Stops god mode
public Action:DodStopGodMode(Handle:timer, any:client) {
	SetEntityRenderMode(client,RENDER_NORMAL)
	SetEntityRenderColor(client)
	DodSetWeaponColor(client,255,255,255,255)
	DodSetHealth(client,100)
	PlayerIsGod[client] = false
	
	new String:message[MAX_LENGTH_PHRASE]
	Format(message, sizeof(message), "%T", "message_god_end", LANG_SERVER, client)
	PrintChat(client,message)
}

/*
* Invisible
*/

// Starts invisibility
public DodStartInvisible(client) {
	SetEntityRenderMode(client,RENDER_TRANSCOLOR)
	SetEntityRenderColor(client,255,255,255,0)
	DodSetWeaponColor(client,255,255,255,0)
	PlayerIsInvisible[client] = true
	CreateTimer(float(InvisibleTime),DodStopInvisible,client,TIMER_FLAG_NO_MAPCHANGE)
	
	new String:message[MAX_LENGTH_PHRASE]
	Format(message, sizeof(message), "%T", "message_invisible_start", LANG_SERVER, client, InvisibleTime)
	PrintChat(client,message)
}

// Stops invisibility
public Action:DodStopInvisible(Handle:timer, any:client) {
	SetEntityRenderMode(client,RENDER_NORMAL)
	SetEntityRenderColor(client)
	DodSetWeaponColor(client,255,255,255,255)
	PlayerIsInvisible[client] = false
	
	new String:message[MAX_LENGTH_PHRASE]
	Format(message, sizeof(message), "%T", "message_invisible_end", LANG_SERVER, client)
	PrintChat(client,message)	
}

/*
* Unlimited granades
*/

public DodStartGranades(client) {
	
	new team = DodGetTeam(client)
	DodRemoveWeapon(client,WEAPON_SLOT4)
	
	if(team == TEAM_ALLIES) {
		GivePlayerItem(client,Weapons[WEAPON_FRAG_US])
		DodSetClips(client,WEAPON_FRAG_US,99)
	} 
	else if(team == TEAM_AXIS){
		GivePlayerItem(client,Weapons[WEAPON_FRAG_GER])
		DodSetClips(client,WEAPON_FRAG_GER,99)
	}
	
	PlayerGranadeTimer[client] = CreateTimer(0.5,DodResetGranades,client,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)
	
	new String:message[MAX_LENGTH_PHRASE]
	Format(message, sizeof(message), "%T", "message_unlimited_granades", LANG_SERVER, client)
	PrintChat(client,message)	
}

// Resets granades
public Action:DodResetGranades(Handle:timer, any:client) {
	
	new team = DodGetTeam(client)
	if(team == TEAM_ALLIES) {
		DodSetClips(client,WEAPON_FRAG_US,99)
	} 
	else if(team == TEAM_AXIS){
		DodSetClips(client,WEAPON_FRAG_GER,99)
	}
}

/*
* Secondary weapon
*/

public DodStartSecondaryWeapon(client) {
	
	new class = DodGetClass(client)
	new team = DodGetTeam(client)
	if(class != CLASS_ROCKET) {
		DodRemoveWeapon(client,WEAPON_SLOT2)
		if(team == TEAM_ALLIES) {
			GivePlayerItem(client,Weapons[WEAPON_M1CARBINE])
			DodGiveClips(client,WEAPON_M1CARBINE,SecondaryClips)
		}
		else if(team == TEAM_AXIS) {
			GivePlayerItem(client,Weapons[WEAPON_C96])
			DodGiveClips(client,WEAPON_C96,SecondaryClips)		
		}
	}
	
	new String:message[MAX_LENGTH_PHRASE]
	Format(message, sizeof(message), "%T", "message_secondary_weapon", LANG_SERVER, client)
	PrintChat(client,message)	
}

/*
* Stamina
*/

// Starts stamina mode
public DodStartStamina(client) {
	DodSetStamina(client,100.0)
	CreateTimer(float(StaminaTime),DodStopStamina,client)
	PlayerStaminaTimer[client] = CreateTimer(0.1,DodResetStamina,client,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)
	
	new String:message[MAX_LENGTH_PHRASE]
	Format(message, sizeof(message), "%T", "message_unlimited_stamina_start", LANG_SERVER, client, StaminaTime)
	PrintChat(client,message)	
}

// Stops stamina mode
public Action:DodStopStamina(Handle:timer, any:client) {
	if(PlayerStaminaTimer[client] != INVALID_HANDLE) {
		CloseHandle(PlayerStaminaTimer[client])
		PlayerStaminaTimer[client] = INVALID_HANDLE
	}
	
	new String:message[MAX_LENGTH_PHRASE]
	Format(message, sizeof(message), "%T", "message_unlimited_stamina_end", LANG_SERVER, client)
	PrintChat(client,message)	
}

// Resets stamina
public Action:DodResetStamina(Handle:timer, any:client) {
	if(PlayerStaminaTimer[client] != INVALID_HANDLE) {
		DodSetStamina(client,100.0)
	}
}