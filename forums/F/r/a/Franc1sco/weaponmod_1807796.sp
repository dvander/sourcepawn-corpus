#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.6"

#define HITGROUP_HEAD 1
#define HITGROUP_CHEST 2
#define HITGROUP_STOMACH 3
#define HITGROUP_LEFTARM 4
#define HITGROUP_RIGHTARM 5
#define HITGROUP_LEFTLEG 6
#define HITGROUP_RIGHTLEG 7

#define DISABLE_COMMAND_NOTIFICATION 1
#define DISABLE_EQUIP_NOTIFICATION 2
#define DISABLE_MENU_NOTIFICATION 4

enum WeaponAttributes
{
	Float:RecoilType1,
	Float:RecoilType2,
	Float:FireRate,
	AutoMode,
	Float:RunSpeed,
	Float:GenericDamage,
	Float:HeadDamage,
	Float:ChestDamage,
	Float:StomachDamage,
	Float:ArmDamage,
	Float:LegDamage,
	BurstMode,
	InfiniteAmmo,
	QuickSwitch,
	Float:ModeFireRate 
};

enum ProcessAttributes
{
	ProcessRecoil,
	ProcessFireRate,
	ProcessAltMode,
	ProcessQuickSwitch
};

enum AltModeState
{
	bool:PistolAuto,
	bool:SmgBurst
};

new Float:PreviousPunchAngle[MAXPLAYERS+1][3];
new BurstShotsFired[MAXPLAYERS+1];
new ModeStateArray[MAXPLAYERS+1][AltModeState];
new ProcessArray[MAXPLAYERS+1][ProcessAttributes];

new Handle:WeaponTypeTrie;
new Handle:WeaponZoomSpeedTrie;
new Handle:hNotifications;

new Notify;
new Handle:WeaponmodMenu;

public Plugin:myinfo =
{
	name = "Weapon Mod",
	author = "Blodia",
	description = "Lets you modify certain attributes of weapons.",
	version = "1.6",
	url = ""
}

public OnPluginStart()
{
	ServerCommand("sv_maxspeed 1500");
	
	WeaponTypeTrie = CreateTrie();
	WeaponZoomSpeedTrie = CreateTrie();
	
	CreateConVar("weaponmod_version", PLUGIN_VERSION, "Weaponmod version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	hNotifications = CreateConVar("weaponmod_disablenotifications", "0", "0 show all notifications, 1 disable server command notifications, 2 disable weapon equip notifications, 4 disable weapon menu. this cvar is bitwise so you can add values together to remove more than 1 notification", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 7.0);
	
	HookConVarChange(hNotifications, ConVarChange);
	Notify = GetConVarInt(hNotifications);
	
	RegServerCmd("weaponmod", ModAttribute, "modify a weapons attribute usage:weaponmod <weapon> <attribute> <value>");
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team"); 
	HookEvent("round_start", Event_RoundStart);
	
	WeaponmodMenu = CreateMenu(WeaponmodMenuHandler);
	SetMenuTitle(WeaponmodMenu, "Weaponmod settings");
	AddMenuItem(WeaponmodMenu, "galil", "galil");
	AddMenuItem(WeaponmodMenu, "ak47", "ak47");
	AddMenuItem(WeaponmodMenu, "sg550", "sg550");
	AddMenuItem(WeaponmodMenu, "famas", "famas");
	AddMenuItem(WeaponmodMenu, "m4a1", "m4a1");
	AddMenuItem(WeaponmodMenu, "aug", "aug");
	AddMenuItem(WeaponmodMenu, "scout", "scout");
	AddMenuItem(WeaponmodMenu, "sg552", "sg552");
	AddMenuItem(WeaponmodMenu, "awp", "awp");
	AddMenuItem(WeaponmodMenu, "g3sg1", "g3sg1");
	AddMenuItem(WeaponmodMenu, "sg550", "sg550");
	AddMenuItem(WeaponmodMenu, "m3", "m3");
	AddMenuItem(WeaponmodMenu, "xm1014", "xm1014");
	AddMenuItem(WeaponmodMenu, "mac10", "mac10");
	AddMenuItem(WeaponmodMenu, "tmp", "tmp");
	AddMenuItem(WeaponmodMenu, "mp5navy", "mp5navy");
	AddMenuItem(WeaponmodMenu, "ump45", "ump45");
	AddMenuItem(WeaponmodMenu, "p90", "p90");
	AddMenuItem(WeaponmodMenu, "m249", "m249");
	AddMenuItem(WeaponmodMenu, "glock", "glock");
	AddMenuItem(WeaponmodMenu, "usp", "usp");
	AddMenuItem(WeaponmodMenu, "p228", "p228");
	AddMenuItem(WeaponmodMenu, "deagle", "deagle");
	AddMenuItem(WeaponmodMenu, "elite", "elite");
	AddMenuItem(WeaponmodMenu, "fiveseven", "fiveseven");
	AddMenuItem(WeaponmodMenu, "hegrenade", "hegrenade");
	AddMenuItem(WeaponmodMenu, "flashbang", "flashbang");
	AddMenuItem(WeaponmodMenu, "smokegrenade", "smoke grenade");
	AddMenuItem(WeaponmodMenu, "knife", "knife");
	AddMenuItem(WeaponmodMenu, "knifestab", "knifestab");
	AddMenuItem(WeaponmodMenu, "knifebackstab", "knifebackstab");
	AddMenuItem(WeaponmodMenu, "c4", "c4");
	AddMenuItem(WeaponmodMenu, "none", "none");

	new GalilInfo[WeaponAttributes];
	GalilInfo[RecoilType1] = 1.0;
	GalilInfo[RecoilType2] = -1.0;
	GalilInfo[FireRate] = 1.0;
	GalilInfo[AutoMode] = -1;
	GalilInfo[RunSpeed] = 1.0;
	GalilInfo[GenericDamage] = -1.0;
	GalilInfo[HeadDamage] = 1.0;
	GalilInfo[ChestDamage] = 1.0;
	GalilInfo[StomachDamage] = 1.0;
	GalilInfo[ArmDamage] = 1.0;
	GalilInfo[LegDamage] = 1.0;
	GalilInfo[BurstMode] = -1;
	GalilInfo[InfiniteAmmo] = 0;
	GalilInfo[QuickSwitch] = 0;
	GalilInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "galil", GalilInfo[0], 15);
	
	new Ak47Info[WeaponAttributes];
	Ak47Info[RecoilType1] = 1.0;
	Ak47Info[RecoilType2] = -1.0;
	Ak47Info[FireRate] = 1.0;
	Ak47Info[AutoMode] = -1;
	Ak47Info[RunSpeed] = 1.0;
	Ak47Info[GenericDamage] = -1.0;
	Ak47Info[HeadDamage] = 1.0;
	Ak47Info[ChestDamage] = 1.0;
	Ak47Info[StomachDamage] = 1.0;
	Ak47Info[ArmDamage] = 1.0;
	Ak47Info[LegDamage] = 1.0;
	Ak47Info[BurstMode] = -1;
	Ak47Info[InfiniteAmmo] = 0;
	Ak47Info[QuickSwitch] = 0;
	Ak47Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "ak47", Ak47Info[0], 15);
	
	new ScoutInfo[WeaponAttributes];
	ScoutInfo[RecoilType1] = -1.0;
	ScoutInfo[RecoilType2] = 1.0;
	ScoutInfo[FireRate] = 1.0;
	ScoutInfo[AutoMode] = -1;
	ScoutInfo[RunSpeed] = 1.0;
	ScoutInfo[GenericDamage] = -1.0;
	ScoutInfo[HeadDamage] = 1.0;
	ScoutInfo[ChestDamage] = 1.0;
	ScoutInfo[StomachDamage] = 1.0;
	ScoutInfo[ArmDamage] = 1.0;
	ScoutInfo[LegDamage] = 1.0;
	ScoutInfo[BurstMode] = -1;
	ScoutInfo[InfiniteAmmo] = 0;
	ScoutInfo[QuickSwitch] = 0;
	ScoutInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "scout", ScoutInfo[0], 15);
	
	new Sg552Info[WeaponAttributes];
	Sg552Info[RecoilType1] = 1.0;
	Sg552Info[RecoilType2] = -1.0;
	Sg552Info[FireRate] = 1.0;
	Sg552Info[AutoMode] = -1;
	Sg552Info[RunSpeed] = 1.0;
	Sg552Info[GenericDamage] = -1.0;
	Sg552Info[HeadDamage] = 1.0;
	Sg552Info[ChestDamage] = 1.0;
	Sg552Info[StomachDamage] = 1.0;
	Sg552Info[ArmDamage] = 1.0;
	Sg552Info[LegDamage] = 1.0;
	Sg552Info[BurstMode] = -1;
	Sg552Info[InfiniteAmmo] = 0;
	Sg552Info[QuickSwitch] = 0;
	Sg552Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "sg552", Sg552Info[0], 15);
	
	new AwpInfo[WeaponAttributes];
	AwpInfo[RecoilType1] = -1.0;
	AwpInfo[RecoilType2] = 1.0;
	AwpInfo[FireRate] = 1.0;
	AwpInfo[AutoMode] = -1;
	AwpInfo[RunSpeed] = 1.0;
	AwpInfo[GenericDamage] = -1.0;
	AwpInfo[HeadDamage] = 1.0;
	AwpInfo[ChestDamage] = 1.0;
	AwpInfo[StomachDamage] = 1.0;
	AwpInfo[ArmDamage] = 1.0;
	AwpInfo[LegDamage] = 1.0;
	AwpInfo[BurstMode] = -1;
	AwpInfo[InfiniteAmmo] = 0;
	AwpInfo[QuickSwitch] = 0;
	AwpInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "awp", AwpInfo[0], 15);
	
	new G3sg1Info[WeaponAttributes];
	G3sg1Info[RecoilType1] = -1.0;
	G3sg1Info[RecoilType2] = 1.0;
	G3sg1Info[FireRate] = 1.0;
	G3sg1Info[AutoMode] = -1;
	G3sg1Info[RunSpeed] = 1.0;
	G3sg1Info[GenericDamage] = -1.0;
	G3sg1Info[HeadDamage] = 1.0;
	G3sg1Info[ChestDamage] = 1.0;
	G3sg1Info[StomachDamage] = 1.0;
	G3sg1Info[ArmDamage] = 1.0;
	G3sg1Info[LegDamage] = 1.0;
	G3sg1Info[BurstMode] = -1;
	G3sg1Info[InfiniteAmmo] = 0;
	G3sg1Info[QuickSwitch] = 0;
	G3sg1Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "g3sg1", G3sg1Info[0], 15);
	
	new FamasInfo[WeaponAttributes];
	FamasInfo[RecoilType1] = 1.0;
	FamasInfo[RecoilType2] = -1.0;
	FamasInfo[FireRate] = 1.0;
	FamasInfo[AutoMode] = -1;
	FamasInfo[RunSpeed] = 1.0;
	FamasInfo[GenericDamage] = -1.0;
	FamasInfo[HeadDamage] = 1.0;
	FamasInfo[ChestDamage] = 1.0;
	FamasInfo[StomachDamage] = 1.0;
	FamasInfo[ArmDamage] = 1.0;
	FamasInfo[LegDamage] = 1.0;
	FamasInfo[BurstMode] = -1;
	FamasInfo[InfiniteAmmo] = 0;
	FamasInfo[QuickSwitch] = 0;
	FamasInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "famas", FamasInfo[0], 15);
	
	new M4a1Info[WeaponAttributes];
	M4a1Info[RecoilType1] = 1.0;
	M4a1Info[RecoilType2] = -1.0;
	M4a1Info[FireRate] = 1.0;
	M4a1Info[AutoMode] = -1;
	M4a1Info[RunSpeed] = 1.0;
	M4a1Info[GenericDamage] = -1.0;
	M4a1Info[HeadDamage] = 1.0;
	M4a1Info[ChestDamage] = 1.0;
	M4a1Info[StomachDamage] = 1.0;
	M4a1Info[ArmDamage] = 1.0;
	M4a1Info[LegDamage] = 1.0;
	M4a1Info[BurstMode] = -1;
	M4a1Info[InfiniteAmmo] = 0;
	M4a1Info[QuickSwitch] = 0;
	M4a1Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "m4a1", M4a1Info[0], 15);
	
	new AugInfo[WeaponAttributes];
	AugInfo[RecoilType1] = 1.0;
	AugInfo[RecoilType2] = -1.0;
	AugInfo[FireRate] = 1.0;
	AugInfo[AutoMode] = -1;
	AugInfo[RunSpeed] = 1.0;
	AugInfo[GenericDamage] = -1.0;
	AugInfo[HeadDamage] = 1.0;
	AugInfo[ChestDamage] = 1.0;
	AugInfo[StomachDamage] = 1.0;
	AugInfo[ArmDamage] = 1.0;
	AugInfo[LegDamage] = 1.0;
	AugInfo[BurstMode] = -1;
	AugInfo[InfiniteAmmo] = 0;
	AugInfo[QuickSwitch] = 0;
	AugInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "aug", AugInfo[0], 15);
	
	new Sg550Info[WeaponAttributes];
	Sg550Info[RecoilType1] = -1.0;
	Sg550Info[RecoilType2] = 1.0;
	Sg550Info[FireRate] = 1.0;
	Sg550Info[AutoMode] = -1;
	Sg550Info[RunSpeed] = 1.0;
	Sg550Info[GenericDamage] = -1.0;
	Sg550Info[HeadDamage] = 1.0;
	Sg550Info[ChestDamage] = 1.0;
	Sg550Info[StomachDamage] = 1.0;
	Sg550Info[ArmDamage] = 1.0;
	Sg550Info[LegDamage] = 1.0;
	Sg550Info[BurstMode] = -1;
	Sg550Info[InfiniteAmmo] = 0;
	Sg550Info[QuickSwitch] = 0;
	Sg550Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "sg550", Sg550Info[0], 15);
	
	new GlockInfo[WeaponAttributes];
	GlockInfo[RecoilType1] = -1.0;
	GlockInfo[RecoilType2] = -1.0;
	GlockInfo[FireRate] = 1.0;
	GlockInfo[AutoMode] = 0;
	GlockInfo[RunSpeed] = 1.0;
	GlockInfo[GenericDamage] = -1.0;
	GlockInfo[HeadDamage] = 1.0;
	GlockInfo[ChestDamage] = 1.0;
	GlockInfo[StomachDamage] = 1.0;
	GlockInfo[ArmDamage] = 1.0;
	GlockInfo[LegDamage] = 1.0;
	GlockInfo[BurstMode] = -1;
	GlockInfo[InfiniteAmmo] = 0;
	GlockInfo[QuickSwitch] = 0;
	GlockInfo[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "glock", GlockInfo[0], 15);
	
	new UspInfo[WeaponAttributes];
	UspInfo[RecoilType1] = -1.0;
	UspInfo[RecoilType2] = 1.0;
	UspInfo[FireRate] = 1.0;
	UspInfo[AutoMode] = 0;
	UspInfo[RunSpeed] = 1.0;
	UspInfo[GenericDamage] = -1.0;
	UspInfo[HeadDamage] = 1.0;
	UspInfo[ChestDamage] = 1.0;
	UspInfo[StomachDamage] = 1.0;
	UspInfo[ArmDamage] = 1.0;
	UspInfo[LegDamage] = 1.0;
	UspInfo[BurstMode] = -1;
	UspInfo[InfiniteAmmo] = 0;
	UspInfo[QuickSwitch] = 0;
	UspInfo[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "usp", UspInfo[0], 15);
	
	new P228Info[WeaponAttributes];
	P228Info[RecoilType1] = -1.0;
	P228Info[RecoilType2] = 1.0;
	P228Info[FireRate] = 1.0;
	P228Info[AutoMode] = 0;
	P228Info[RunSpeed] = 1.0;
	P228Info[GenericDamage] = -1.0;
	P228Info[HeadDamage] = 1.0;
	P228Info[ChestDamage] = 1.0;
	P228Info[StomachDamage] = 1.0;
	P228Info[ArmDamage] = 1.0;
	P228Info[LegDamage] = 1.0;
	P228Info[BurstMode] = -1;
	P228Info[InfiniteAmmo] = 0;
	P228Info[QuickSwitch] = 0;
	P228Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "p228", P228Info[0], 15);
	
	new DeagleInfo[WeaponAttributes];
	DeagleInfo[RecoilType1] = -1.0;
	DeagleInfo[RecoilType2] = 1.0;
	DeagleInfo[FireRate] = 1.0;
	DeagleInfo[AutoMode] = 0;
	DeagleInfo[RunSpeed] = 1.0;
	DeagleInfo[GenericDamage] = -1.0;
	DeagleInfo[HeadDamage] = 1.0;
	DeagleInfo[ChestDamage] = 1.0;
	DeagleInfo[StomachDamage] = 1.0;
	DeagleInfo[ArmDamage] = 1.0;
	DeagleInfo[LegDamage] = 1.0;
	DeagleInfo[BurstMode] = -1;
	DeagleInfo[InfiniteAmmo] = 0;
	DeagleInfo[QuickSwitch] = 0;
	DeagleInfo[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "deagle", DeagleInfo[0], 15);
	
	new EliteInfo[WeaponAttributes];
	EliteInfo[RecoilType1] = -1.0;
	EliteInfo[RecoilType2] = 1.0;
	EliteInfo[FireRate] = 1.0;
	EliteInfo[AutoMode] = 0;
	EliteInfo[RunSpeed] = 1.0;
	EliteInfo[GenericDamage] = -1.0;
	EliteInfo[HeadDamage] = 1.0;
	EliteInfo[ChestDamage] = 1.0;
	EliteInfo[StomachDamage] = 1.0;
	EliteInfo[ArmDamage] = 1.0;
	EliteInfo[LegDamage] = 1.0;
	EliteInfo[BurstMode] = -1;
	EliteInfo[InfiniteAmmo] = 0;
	EliteInfo[QuickSwitch] = 0;
	EliteInfo[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "elite", EliteInfo[0], 15);
	
	new FivesevenInfo[WeaponAttributes];
	FivesevenInfo[RecoilType1] = -1.0;
	FivesevenInfo[RecoilType2] = 1.0;
	FivesevenInfo[FireRate] = 1.0;
	FivesevenInfo[AutoMode] = 0;
	FivesevenInfo[RunSpeed] = 1.0;
	FivesevenInfo[GenericDamage] = -1.0;
	FivesevenInfo[HeadDamage] = 1.0;
	FivesevenInfo[ChestDamage] = 1.0;
	FivesevenInfo[StomachDamage] = 1.0;
	FivesevenInfo[ArmDamage] = 1.0;
	FivesevenInfo[LegDamage] = 1.0;
	FivesevenInfo[BurstMode] = -1;
	FivesevenInfo[InfiniteAmmo] = 0;
	FivesevenInfo[QuickSwitch] = 0;
	FivesevenInfo[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "fiveseven", FivesevenInfo[0], 15);
	
	new M3Info[WeaponAttributes];
	M3Info[RecoilType1] = -1.0;
	M3Info[RecoilType2] = 1.0;
	M3Info[FireRate] = 1.0;
	M3Info[AutoMode] = -1;
	M3Info[RunSpeed] = 1.0;
	M3Info[GenericDamage] = -1.0;
	M3Info[HeadDamage] = 1.0;
	M3Info[ChestDamage] = 1.0;
	M3Info[StomachDamage] = 1.0;
	M3Info[ArmDamage] = 1.0;
	M3Info[LegDamage] = 1.0;
	M3Info[BurstMode] = -1;
	M3Info[InfiniteAmmo] = 0;
	M3Info[QuickSwitch] = 0;
	M3Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "m3", M3Info[0], 15);
	
	new Xm1014Info[WeaponAttributes];
	Xm1014Info[RecoilType1] = -1.0;
	Xm1014Info[RecoilType2] = 1.0;
	Xm1014Info[FireRate] = 1.0;
	Xm1014Info[AutoMode] = -1;
	Xm1014Info[RunSpeed] = 1.0;
	Xm1014Info[GenericDamage] = -1.0;
	Xm1014Info[HeadDamage] = 1.0;
	Xm1014Info[ChestDamage] = 1.0;
	Xm1014Info[StomachDamage] = 1.0;
	Xm1014Info[ArmDamage] = 1.0;
	Xm1014Info[LegDamage] = 1.0;
	Xm1014Info[BurstMode] = -1;
	Xm1014Info[InfiniteAmmo] = 0;
	Xm1014Info[QuickSwitch] = 0;
	Xm1014Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "xm1014", Xm1014Info[0], 15);
	
	new Mac10Info[WeaponAttributes];
	Mac10Info[RecoilType1] = 1.0;
	Mac10Info[RecoilType2] = -1.0;
	Mac10Info[FireRate] = 1.0;
	Mac10Info[AutoMode] = -1;
	Mac10Info[RunSpeed] = 1.0;
	Mac10Info[GenericDamage] = -1.0;
	Mac10Info[HeadDamage] = 1.0;
	Mac10Info[ChestDamage] = 1.0;
	Mac10Info[StomachDamage] = 1.0;
	Mac10Info[ArmDamage] = 1.0;
	Mac10Info[LegDamage] = 1.0;
	Mac10Info[BurstMode] = 0;
	Mac10Info[InfiniteAmmo] = 0;
	Mac10Info[QuickSwitch] = 0;
	Mac10Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "mac10", Mac10Info[0], 15);
	
	new TmpInfo[WeaponAttributes];
	TmpInfo[RecoilType1] = 1.0;
	TmpInfo[RecoilType2] = -1.0;
	TmpInfo[FireRate] = 1.0;
	TmpInfo[AutoMode] = -1;
	TmpInfo[RunSpeed] = 1.0;
	TmpInfo[GenericDamage] = -1.0;
	TmpInfo[HeadDamage] = 1.0;
	TmpInfo[ChestDamage] = 1.0;
	TmpInfo[StomachDamage] = 1.0;
	TmpInfo[ArmDamage] = 1.0;
	TmpInfo[LegDamage] = 1.0;
	TmpInfo[BurstMode] = 0;
	TmpInfo[InfiniteAmmo] = 0;
	TmpInfo[QuickSwitch] = 0;
	TmpInfo[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "tmp", TmpInfo[0], 15);
	
	new Mp5navyInfo[WeaponAttributes];
	Mp5navyInfo[RecoilType1] = 1.0;
	Mp5navyInfo[RecoilType2] = -1.0;
	Mp5navyInfo[FireRate] = 1.0;
	Mp5navyInfo[AutoMode] = -1;
	Mp5navyInfo[RunSpeed] = 1.0;
	Mp5navyInfo[GenericDamage] = -1.0;
	Mp5navyInfo[HeadDamage] = 1.0;
	Mp5navyInfo[ChestDamage] = 1.0;
	Mp5navyInfo[StomachDamage] = 1.0;
	Mp5navyInfo[ArmDamage] = 1.0;
	Mp5navyInfo[LegDamage] = 1.0;
	Mp5navyInfo[BurstMode] = 0;
	Mp5navyInfo[InfiniteAmmo] = 0;
	Mp5navyInfo[QuickSwitch] = 0;
	Mp5navyInfo[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "mp5navy", Mp5navyInfo[0], 15);
	
	new Ump45Info[WeaponAttributes];
	Ump45Info[RecoilType1] = 1.0;
	Ump45Info[RecoilType2] = -1.0;
	Ump45Info[FireRate] = 1.0;
	Ump45Info[AutoMode] = -1;
	Ump45Info[RunSpeed] = 1.0;
	Ump45Info[GenericDamage] = -1.0;
	Ump45Info[HeadDamage] = 1.0;
	Ump45Info[ChestDamage] = 1.0;
	Ump45Info[StomachDamage] = 1.0;
	Ump45Info[ArmDamage] = 1.0;
	Ump45Info[LegDamage] = 1.0;
	Ump45Info[BurstMode] = 0;
	Ump45Info[InfiniteAmmo] = 0;
	Ump45Info[QuickSwitch] = 0;
	Ump45Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "ump45", Ump45Info[0], 15);
	
	new P90Info[WeaponAttributes];
	P90Info[RecoilType1] = 1.0;
	P90Info[RecoilType2] = -1.0;
	P90Info[FireRate] = 1.0;
	P90Info[AutoMode] = -1;
	P90Info[RunSpeed] = 1.0;
	P90Info[GenericDamage] = -1.0;
	P90Info[HeadDamage] = 1.0;
	P90Info[ChestDamage] = 1.0;
	P90Info[StomachDamage] = 1.0;
	P90Info[ArmDamage] = 1.0;
	P90Info[LegDamage] = 1.0;
	P90Info[BurstMode] = 0;
	P90Info[InfiniteAmmo] = 0;
	P90Info[QuickSwitch] = 0;
	P90Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "p90", P90Info[0], 15);
	
	new M249Info[WeaponAttributes];
	M249Info[RecoilType1] = 1.0;
	M249Info[RecoilType2] = -1.0;
	M249Info[FireRate] = 1.0;
	M249Info[AutoMode] = -1;
	M249Info[RunSpeed] = 1.0;
	M249Info[GenericDamage] = -1.0;
	M249Info[HeadDamage] = 1.0;
	M249Info[ChestDamage] = 1.0;
	M249Info[StomachDamage] = 1.0;
	M249Info[ArmDamage] = 1.0;
	M249Info[LegDamage] = 1.0;
	M249Info[BurstMode] = -1;
	M249Info[InfiniteAmmo] = 0;
	M249Info[QuickSwitch] = 0;
	M249Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "m249", M249Info[0], 15);
	
	new KnifeInfo[WeaponAttributes];
	KnifeInfo[RecoilType1] = -1.0;
	KnifeInfo[RecoilType2] = -1.0;
	KnifeInfo[FireRate] = 1.0;
	KnifeInfo[AutoMode] = -1;
	KnifeInfo[RunSpeed] = 1.0;
	KnifeInfo[GenericDamage] = 1.0;
	KnifeInfo[HeadDamage] = -1.0;
	KnifeInfo[ChestDamage] = -1.0;
	KnifeInfo[StomachDamage] = -1.0;
	KnifeInfo[ArmDamage] = -1.0;
	KnifeInfo[LegDamage] = -1.0;
	KnifeInfo[BurstMode] = -1;
	KnifeInfo[InfiniteAmmo] = -1;
	KnifeInfo[QuickSwitch] = 0;
	KnifeInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "knife", KnifeInfo[0], 15);
	
	new KnifestabInfo[WeaponAttributes];
	KnifestabInfo[RecoilType1] = -1.0;
	KnifestabInfo[RecoilType2] = -1.0;
	KnifestabInfo[FireRate] = 1.0;
	KnifestabInfo[AutoMode] = -1;
	KnifestabInfo[RunSpeed] = -1.0;
	KnifestabInfo[GenericDamage] = 1.0;
	KnifestabInfo[HeadDamage] = -1.0;
	KnifestabInfo[ChestDamage] = -1.0;
	KnifestabInfo[StomachDamage] = -1.0;
	KnifestabInfo[ArmDamage] = -1.0;
	KnifestabInfo[LegDamage] = -1.0;
	KnifestabInfo[BurstMode] = -1;
	KnifestabInfo[InfiniteAmmo] = -1;
	KnifestabInfo[QuickSwitch] = -1;
	KnifestabInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "knifestab", KnifestabInfo[0], 15);
	
	new KnifebackstabInfo[WeaponAttributes];
	KnifebackstabInfo[RecoilType1] = -1.0;
	KnifebackstabInfo[RecoilType2] = -1.0;
	KnifebackstabInfo[FireRate] = -1.0;
	KnifebackstabInfo[AutoMode] = -1;
	KnifebackstabInfo[RunSpeed] = -1.0;
	KnifebackstabInfo[GenericDamage] = 1.0;
	KnifebackstabInfo[HeadDamage] = -1.0;
	KnifebackstabInfo[ChestDamage] = -1.0;
	KnifebackstabInfo[StomachDamage] = -1.0;
	KnifebackstabInfo[ArmDamage] = -1.0;
	KnifebackstabInfo[LegDamage] = -1.0;
	KnifebackstabInfo[BurstMode] = -1;
	KnifebackstabInfo[InfiniteAmmo] = -1;
	KnifebackstabInfo[QuickSwitch] = -1;
	KnifebackstabInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "knifebackstab", KnifebackstabInfo[0], 15);
	
	new HegrenadeInfo[WeaponAttributes];
	HegrenadeInfo[RecoilType1] = -1.0;
	HegrenadeInfo[RecoilType2] = -1.0;
	HegrenadeInfo[FireRate] = -1.0;
	HegrenadeInfo[AutoMode] = -1;
	HegrenadeInfo[RunSpeed] = 1.0;
	HegrenadeInfo[GenericDamage] = 1.0;
	HegrenadeInfo[HeadDamage] = -1.0;
	HegrenadeInfo[ChestDamage] = -1.0;
	HegrenadeInfo[StomachDamage] = -1.0;
	HegrenadeInfo[ArmDamage] = -1.0;
	HegrenadeInfo[LegDamage] = -1.0;
	HegrenadeInfo[BurstMode] = -1;
	HegrenadeInfo[InfiniteAmmo] = 0;
	HegrenadeInfo[QuickSwitch] = 0;
	HegrenadeInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "hegrenade", HegrenadeInfo[0], 15);
	
	new FlashbangInfo[WeaponAttributes];
	FlashbangInfo[RecoilType1] = -1.0;
	FlashbangInfo[RecoilType2] = -1.0;
	FlashbangInfo[FireRate] = -1.0;
	FlashbangInfo[AutoMode] = -1;
	FlashbangInfo[RunSpeed] = 1.0;
	FlashbangInfo[GenericDamage] = 1.0;
	FlashbangInfo[HeadDamage] = -1.0;
	FlashbangInfo[ChestDamage] = -1.0;
	FlashbangInfo[StomachDamage] = -1.0;
	FlashbangInfo[ArmDamage] = -1.0;
	FlashbangInfo[LegDamage] = -1.0;
	FlashbangInfo[BurstMode] = -1;
	FlashbangInfo[InfiniteAmmo] = 0;
	FlashbangInfo[QuickSwitch] = 0;
	FlashbangInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "flashbang", FlashbangInfo[0], 15);
	
	new SmokegrenadeInfo[WeaponAttributes];
	SmokegrenadeInfo[RecoilType1] = -1.0;
	SmokegrenadeInfo[RecoilType2] = -1.0;
	SmokegrenadeInfo[FireRate] = -1.0;
	SmokegrenadeInfo[AutoMode] = -1;
	SmokegrenadeInfo[RunSpeed] = 1.0;
	SmokegrenadeInfo[GenericDamage] = 1.0;
	SmokegrenadeInfo[HeadDamage] = -1.0;
	SmokegrenadeInfo[ChestDamage] = -1.0;
	SmokegrenadeInfo[StomachDamage] = -1.0;
	SmokegrenadeInfo[ArmDamage] = -1.0;
	SmokegrenadeInfo[LegDamage] = -1.0;
	SmokegrenadeInfo[BurstMode] = -1;
	SmokegrenadeInfo[InfiniteAmmo] = 0;
	SmokegrenadeInfo[QuickSwitch] = 0;
	SmokegrenadeInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "smokegrenade", SmokegrenadeInfo[0], 15);
	
	new C4Info[WeaponAttributes];
	C4Info[RecoilType1] = -1.0;
	C4Info[RecoilType2] = -1.0;
	C4Info[FireRate] = -1.0;
	C4Info[AutoMode] = -1;
	C4Info[RunSpeed] = 1.0;
	C4Info[GenericDamage] = -1.0;
	C4Info[HeadDamage] = -1.0;
	C4Info[ChestDamage] = -1.0;
	C4Info[StomachDamage] = -1.0;
	C4Info[ArmDamage] = -1.0;
	C4Info[LegDamage] = -1.0;
	C4Info[BurstMode] = -1;
	C4Info[InfiniteAmmo] = -1;
	C4Info[QuickSwitch] = 0;
	C4Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "c4", C4Info[0], 15);
	
	new NoWeaponInfo[WeaponAttributes];
	NoWeaponInfo[RecoilType1] = -1.0;
	NoWeaponInfo[RecoilType2] = -1.0;
	NoWeaponInfo[FireRate] = -1.0;
	NoWeaponInfo[AutoMode] = -1;
	NoWeaponInfo[RunSpeed] = 1.0;
	NoWeaponInfo[GenericDamage] = -1.0;
	NoWeaponInfo[HeadDamage] = -1.0;
	NoWeaponInfo[ChestDamage] = -1.0;
	NoWeaponInfo[StomachDamage] = -1.0;
	NoWeaponInfo[ArmDamage] = -1.0;
	NoWeaponInfo[LegDamage] = -1.0;
	NoWeaponInfo[BurstMode] = -1;
	NoWeaponInfo[InfiniteAmmo] = -1;
	NoWeaponInfo[QuickSwitch] = -1;
	NoWeaponInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "none", NoWeaponInfo[0], 15);
	
	SetTrieValue(WeaponZoomSpeedTrie, "scout", 1.1818181);
	SetTrieValue(WeaponZoomSpeedTrie, "sg552", 1.175);
	SetTrieValue(WeaponZoomSpeedTrie, "awp", 1.4);
	SetTrieValue(WeaponZoomSpeedTrie, "sg550", 1.4);
	
	for (new client = 1; client <= MaxClients; client++) 
	{ 
        if (IsClientInGame(client)) 
        {
			SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost);
			SDKHook(client, SDKHook_PostThink, OnPostThink);
			SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
			SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
			SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
        } 
    }
}

public ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == hNotifications) Notify = GetConVarInt(hNotifications);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost);
	SDKHook(client, SDKHook_PostThink, OnPostThink);
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public OnPluginEnd()
{
	CloseHandle(WeaponTypeTrie);
	CloseHandle(WeaponZoomSpeedTrie);
	CloseHandle(WeaponmodMenu);
}

public Action:ModAttribute(args)
{
	if (GetCmdArgs() != 3)
	{
		PrintToServer("********** weaponmod: must be 3 arguments - <weapon> <attribute> <value>");
		return Plugin_Handled;
	}
	
	new String:AttributeName[30];
	new String:WeaponName[30];
	new String:AttributeValue[20];
	
	GetCmdArg(1, WeaponName, sizeof(WeaponName));
	GetCmdArg(2, AttributeName, sizeof(AttributeName));
	GetCmdArg(3, AttributeValue, sizeof(AttributeValue));
	
	new EditWeapon[WeaponAttributes];
	if (!GetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15))
	{
		PrintToServer("********** weaponmod: weapon doesn't exist");
		return Plugin_Handled;
	}
	
	new Float:FloatVal;
	new IntVal;
	decl String:FloatString[20];
	
	if (StrEqual("recoil", AttributeName, false))
	{
		FloatVal = StringToFloat(AttributeValue);
		if (FloatVal > 10.0)
		{
			FloatVal = 10.0;
			PrintToServer("********** weaponmod: max value capped to 10.0");
		}
		else if (FloatVal < 0.0)
		{
			FloatVal = 0.0;
			PrintToServer("********** weaponmod: min value capped to 0.0");
		}
		
		FloatToString(FloatVal, FloatString, sizeof(FloatString));
		
		if (EditWeapon[RecoilType1] != -1.0)
		{
			EditWeapon[RecoilType1] = FloatVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) PrintToChatAll("\x04[Weapon Mod]\x05 %s recoil multiplier changed to %s", WeaponName, FloatString);
		}
		else if (EditWeapon[RecoilType2] != -1.0)
		{
			EditWeapon[RecoilType2] = FloatVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) PrintToChatAll("\x04[Weapon Mod]\x05 %s recoil multiplier changed to %s", WeaponName, FloatString);
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- galil, ak47, scout, sg552, awp");
			PrintToServer("********** weaponmod: continued:- g3sg1, famas, m4a1, aug, sg550, usp, p228, deagle, elite");
			PrintToServer("********** weaponmod: continued:- fiveseven, m3, xm1014, mac10, tmp, mp5navy, ump45, p90, m249");
		}
	}
	
	else if (StrEqual("firerate", AttributeName, false))
	{
		FloatVal = StringToFloat(AttributeValue);
		if (FloatVal > 100.0)
		{
			FloatVal = 100.0;
			PrintToServer("********** weaponmod: max value capped to 100.0");
		}
		else if (FloatVal < 0.1)
		{
			FloatVal = 0.1;
			PrintToServer("********** weaponmod: min value capped to 0.1");
		}
		
		FloatToString(FloatVal, FloatString, sizeof(FloatString));
		
		if (EditWeapon[FireRate] != -1.0)
		{
			EditWeapon[FireRate] = FloatVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) PrintToChatAll("\x04[Weapon Mod]\x05 %s fire rate multiplier changed to %s", WeaponName, FloatString);
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- galil, ak47, scout, sg552, awp, g3sg1");
			PrintToServer("********** weaponmod: continued:- famas, m4a1, aug, sg550, glock, usp, p228, deagle, elite, fiveseven");
			PrintToServer("********** weaponmod: continued:- m3, xm1014, mac10, tmp, mp5navy, ump45, p90, m249, knife, knifestab");
		}
	}
	
	else if (StrEqual("automode", AttributeName, false))
	{
		IntVal = StringToInt(AttributeValue);
		if ((IntVal != 1) && (IntVal != 0))
		{
			IntVal = 0;
			PrintToServer("********** weaponmod: value must be 0 or 1 else default value of 0 is used");
		}
		
		if (EditWeapon[AutoMode] != -1)
		{
			EditWeapon[AutoMode] = IntVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION))
			{
				if (IntVal)
				{
					PrintToChatAll("\x04[Weapon Mod]\x05 %s automatic mode enabled", WeaponName);
				}
				else
				{
					PrintToChatAll("\x04[Weapon Mod]\x05 %s automatic mode disabled", WeaponName);
				}
			}
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- glock, usp, p228, deagle, elite, fiveseven");
		}
	}
	
	else if (StrEqual("runspeed", AttributeName, false))
	{
		FloatVal = StringToFloat(AttributeValue);
		if (FloatVal > 5.0)
		{
			FloatVal = 5.0;
			PrintToServer("********** weaponmod: max value capped to 5.0");
		}
		else if (FloatVal < 0.5)
		{
			FloatVal = 0.5;
			PrintToServer("********** weaponmod: min value capped to 0.5");
		}
		
		FloatToString(FloatVal, FloatString, sizeof(FloatString));
		
		if (EditWeapon[RunSpeed] != -1.0)
		{
			EditWeapon[RunSpeed] = FloatVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) PrintToChatAll("\x04[Weapon Mod]\x05 %s run speed multiplier changed to %s", WeaponName, FloatString);
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- galil, ak47, scout, sg552, awp, g3sg1");
			PrintToServer("********** weaponmod: continued:- famas, m4a1, aug, sg550, glock, usp, p228, deagle, elite, fiveseven");
			PrintToServer("********** weaponmod: continued:- m3, xm1014, mac10, tmp, mp5navy, ump45, p90, m249, knife, hegrenade");
			PrintToServer("********** weaponmod: continued:- flashbang, smokegrenade, c4, none");
		}
	}
	
	else if (StrEqual("genericdamage", AttributeName, false))
	{
		FloatVal = StringToFloat(AttributeValue);
		if (FloatVal > 1000.0)
		{
			FloatVal = 1000.0;
			PrintToServer("********** weaponmod: max value capped to 1000.0");
		}
		else if (FloatVal < 0.0)
		{
			FloatVal = 0.0;
			PrintToServer("********** weaponmod: min value capped to 0.0");
		}
		
		FloatToString(FloatVal, FloatString, sizeof(FloatString));
		
		if (EditWeapon[GenericDamage] != -1.0)
		{
			EditWeapon[GenericDamage] = FloatVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) PrintToChatAll("\x04[Weapon Mod]\x05 %s generic damage multiplier changed to %s", WeaponName, FloatString);
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- knife, knifestab, knifebackstab");
			PrintToServer("********** weaponmod: continued:- hegrenade, flashbang, smokegrenade");
		}
	}
	
	else if (StrEqual("headdamage", AttributeName, false))
	{
		FloatVal = StringToFloat(AttributeValue);
		if (FloatVal > 1000.0)
		{
			FloatVal = 1000.0;
			PrintToServer("********** weaponmod: max value capped to 1000.0");
		}
		else if (FloatVal < 0.0)
		{
			FloatVal = 0.0;
			PrintToServer("********** weaponmod: min value capped to 0.0");
		}
		
		FloatToString(FloatVal, FloatString, sizeof(FloatString));
		
		if (EditWeapon[HeadDamage] != -1.0)
		{
			EditWeapon[HeadDamage] = FloatVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) PrintToChatAll("\x04[Weapon Mod]\x05 %s head damage multiplier changed to %s", WeaponName, FloatString);
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- galil, ak47, scout, sg552, awp");
			PrintToServer("********** weaponmod: continued:- g3sg1, famas, m4a1, aug, sg550, glock, usp, p228, deagle, elite");
			PrintToServer("********** weaponmod: continued:- fiveseven, m3, xm1014, mac10, tmp, mp5navy, ump45, p90, m249");
		}
	}
	
	else if (StrEqual("chestdamage", AttributeName, false))
	{
		FloatVal = StringToFloat(AttributeValue);
		if (FloatVal > 1000.0)
		{
			FloatVal = 1000.0;
			PrintToServer("********** weaponmod: max value capped to 1000.0");
		}
		else if (FloatVal < 0.0)
		{
			FloatVal = 0.0;
			PrintToServer("********** weaponmod: min value capped to 0.0");
		}
		
		FloatToString(FloatVal, FloatString, sizeof(FloatString));
		
		if (EditWeapon[ChestDamage] != -1.0)
		{
			EditWeapon[ChestDamage] = FloatVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) PrintToChatAll("\x04[Weapon Mod]\x05 %s chest damage multiplier changed to %s", WeaponName, FloatString);
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- galil, ak47, scout, sg552, awp");
			PrintToServer("********** weaponmod: continued:- g3sg1, famas, m4a1, aug, sg550, glock, usp, p228, deagle, elite");
			PrintToServer("********** weaponmod: continued:- fiveseven, m3, xm1014, mac10, tmp, mp5navy, ump45, p90, m249");
		}
	}
	
	else if (StrEqual("stomachdamage", AttributeName, false))
	{
		FloatVal = StringToFloat(AttributeValue);
		if (FloatVal > 1000.0)
		{
			FloatVal = 1000.0;
			PrintToServer("********** weaponmod: max value capped to 1000.0");
		}
		else if (FloatVal < 0.0)
		{
			FloatVal = 0.0;
			PrintToServer("********** weaponmod: min value capped to 0.0");
		}
		
		FloatToString(FloatVal, FloatString, sizeof(FloatString));
		
		if (EditWeapon[StomachDamage] != -1.0)
		{
			EditWeapon[StomachDamage] = FloatVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) PrintToChatAll("\x04[Weapon Mod]\x05 %s stomach damage multiplier changed to %s", WeaponName, FloatString);
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- galil, ak47, scout, sg552, awp");
			PrintToServer("********** weaponmod: continued:- g3sg1, famas, m4a1, aug, sg550, glock, usp, p228, deagle, elite");
			PrintToServer("********** weaponmod: continued:- fiveseven, m3, xm1014, mac10, tmp, mp5navy, ump45, p90, m249");
		}
	}
	
	else if (StrEqual("armdamage", AttributeName, false))
	{
		FloatVal = StringToFloat(AttributeValue);
		if (FloatVal > 1000.0)
		{
			FloatVal = 1000.0;
			PrintToServer("********** weaponmod: max value capped to 1000.0");
		}
		else if (FloatVal < 0.0)
		{
			FloatVal = 0.0;
			PrintToServer("********** weaponmod: min value capped to 0.0");
		}
		
		FloatToString(FloatVal, FloatString, sizeof(FloatString));
		
		if (EditWeapon[ArmDamage] != -1.0)
		{
			EditWeapon[ArmDamage] = FloatVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) PrintToChatAll("\x04[Weapon Mod]\x05 %s arm damage multiplier changed to %s", WeaponName, FloatString);
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- galil, ak47, scout, sg552, awp");
			PrintToServer("********** weaponmod: continued:- g3sg1, famas, m4a1, aug, sg550, glock, usp, p228, deagle, elite");
			PrintToServer("********** weaponmod: continued:- fiveseven, m3, xm1014, mac10, tmp, mp5navy, ump45, p90, m249");
		}
	}
	
	else if (StrEqual("legdamage", AttributeName, false))
	{
		FloatVal = StringToFloat(AttributeValue);
		if (FloatVal > 1000.0)
		{
			FloatVal = 1000.0;
			PrintToServer("********** weaponmod: max value capped to 1000.0");
		}
		else if (FloatVal < 0.0)
		{
			FloatVal = 0.0;
			PrintToServer("********** weaponmod: min value capped to 0.0");
		}
		
		FloatToString(FloatVal, FloatString, sizeof(FloatString));
		
		if (EditWeapon[LegDamage] != -1.0)
		{
			EditWeapon[LegDamage] = FloatVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) PrintToChatAll("\x04[Weapon Mod]\x05 %s leg damage multiplier changed to %s", WeaponName, FloatString);
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- galil, ak47, scout, sg552, awp");
			PrintToServer("********** weaponmod: continued:- g3sg1, famas, m4a1, aug, sg550, glock, usp, p228, deagle, elite");
			PrintToServer("********** weaponmod: continued:- fiveseven, m3, xm1014, mac10, tmp, mp5navy, ump45, p90, m249");
		}
	}
	
	else if (StrEqual("burstmode", AttributeName, false))
	{
		IntVal = StringToInt(AttributeValue);
		if ((IntVal != 1) && (IntVal != 0))
		{
			IntVal = 0;
			PrintToServer("********** weaponmod: value must be 0 or 1 else default value of 0 is used");
		}
		
		if (EditWeapon[BurstMode] != -1)
		{
			EditWeapon[BurstMode] = IntVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) 
			{
				if (IntVal)
				{
					PrintToChatAll("\x04[Weapon Mod]\x05 %s Burst mode enabled", WeaponName);
				}
				else
				{
					PrintToChatAll("\x04[Weapon Mod]\x05 %s Burst mode disabled", WeaponName);
				}
			}
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- mac10, tmp, mp5navy, ump45, p90");
		}
	}
	
	else if (StrEqual("infiniteammo", AttributeName, false))
	{
		IntVal = StringToInt(AttributeValue);
		if ((IntVal != 1) && (IntVal != 0))
		{
			IntVal = 0;
			PrintToServer("********** weaponmod: value must be 0 or 1 else default value of 0 is used");
		}
		
		if (EditWeapon[InfiniteAmmo] != -1)
		{
			EditWeapon[InfiniteAmmo] = IntVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) 
			{
				if(IntVal == 1)
				{
					PrintToChatAll("\x04[Weapon Mod]\x05 %s infinite ammo enabled", WeaponName);
				}
				else
				{
					PrintToChatAll("\x04[Weapon Mod]\x05 %s infinite ammo disabled", WeaponName);
				}
			}
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- galil, ak47, scout, sg552, awp, g3sg1");
			PrintToServer("********** weaponmod: continued:- famas, m4a1, aug, sg550, glock, usp, p228, deagle, elite");
			PrintToServer("********** weaponmod: continued:- fiveseven, m3, xm1014, mac10, tmp, mp5navy, ump45, p90, m249");
			PrintToServer("********** weaponmod: continued:- hegrenade, flashbang, smokegrenade");
		}
	}
	
	else if (StrEqual("quickswitch", AttributeName, false))
	{
		IntVal = StringToInt(AttributeValue);
		if ((IntVal != 1) && (IntVal != 0))
		{
			IntVal = 0;
			PrintToServer("********** weaponmod: value must be 0 or 1 else default value of 0 is used");
		}
		
		if (EditWeapon[QuickSwitch] != -1)
		{
			EditWeapon[QuickSwitch] = IntVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) 
			{
				if (IntVal)
				{
					PrintToChatAll("\x04[Weapon Mod]\x05 %s quick switch enabled", WeaponName);
				}
				else
				{
					PrintToChatAll("\x04[Weapon Mod]\x05 %s quicks witch disabled", WeaponName);
				}
			}
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- galil, ak47, scout, sg552, awp, g3sg1");
			PrintToServer("********** weaponmod: continued:- famas, m4a1, aug, sg550, glock, usp, p228, deagle, elite");
			PrintToServer("********** weaponmod: continued:- fiveseven, m3, xm1014, mac10, tmp, mp5navy, ump45, p90, m249");
			PrintToServer("********** weaponmod: continued:- knife, hegrenade, flashbang, smokegrenade, c4");
		}
	}
	
	else if (StrEqual("modefirerate", AttributeName, false))
	{
		FloatVal = StringToFloat(AttributeValue);
		if (FloatVal > 100.0)
		{
			FloatVal = 100.0;
			PrintToServer("********** weaponmod: max value capped to 100.0");
		}
		else if (FloatVal < 1.0)
		{
			FloatVal = 1.0;
			PrintToServer("********** weaponmod: min value capped to 1.0");
		}
		
		FloatToString(FloatVal, FloatString, sizeof(FloatString));
		
		if (EditWeapon[ModeFireRate] != -1.0)
		{
			EditWeapon[ModeFireRate] = FloatVal;
			SetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 15);
			
			if (!(Notify & DISABLE_COMMAND_NOTIFICATION)) PrintToChatAll("\x04[Weapon Mod]\x05 %s alt mode fire rate multiplier changed to %s", WeaponName, FloatString);
		}
		else
		{
			PrintToServer("********** weaponmod: attribute for this weapon doesn't exist");
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- glock, usp, p228, deagle");
			PrintToServer("********** weaponmod: continued:- elite, fiveseven, mac10, tmp, mp5navy, ump45, p90");
		}
	}
	
	else
	{
		PrintToServer("********** weaponmod: attribute doesn't exist");
		PrintToServer("********** weaponmod: valid atrributes are:- recoil, firerate, automode, runspeed, genericdamage");
		PrintToServer("********** weaponmod: continued:- headdamage, chestdamage, stomachdamage, armdamage, legdamage");
		PrintToServer("********** weaponmod: continued:- burstmode, infiniteammo, quickswitch, modefirerate");
	}
	
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static OldButtons[MAXPLAYERS + 1];
	
	if (!IsPlayerAlive(client)) return Plugin_Continue;
	
	if (vel[0] < 0.0) vel[0] = -1500.0;
	else if (vel[0] > 0.0) vel[0] = 1500.0;
	
	if (vel[1] < 0.0) vel[1] = -1500.0;
	else if (vel[1] > 0.0) vel[1] = 1500.0;
	
	new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (!IsValidEdict(WeaponIndex))
	{
		OldButtons[client] = buttons;
		return Plugin_Continue;
	}
	
	decl String:WeaponName[30];
	GetEdictClassname(WeaponIndex, WeaponName, sizeof(WeaponName));
	ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
	
	new GetWeaponInfo[WeaponAttributes];
	GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 15);
	
	// if the player fired while in burst mode and have ammo then force them to attack until they fire 3 shots.
	if ((GetWeaponInfo[BurstMode] == 1) && (BurstShotsFired[client]) && (ModeStateArray[client][SmgBurst]))
	{
		if (GetEntProp(WeaponIndex, Prop_Send, "m_iClip1")) buttons |= IN_ATTACK;
		else BurstShotsFired[client] = 0;
	}
	
	// switch fire modes
	// only check the first keypress to stop spam.
	if ((!(OldButtons[client] & IN_ATTACK2)) && (buttons & IN_ATTACK2))
	{
		if (GetWeaponInfo[AutoMode] == 1)
		{
			if (!ModeStateArray[client][PistolAuto])
			{
				ModeStateArray[client][PistolAuto] = true;
				PrintCenterText(client, "switched to automatic-fire mode");
			}
			else
			{
				ModeStateArray[client][PistolAuto] = false;
				PrintCenterText(client, "switched to normal mode");
			}
		}
		else if (GetWeaponInfo[BurstMode] == 1)
		{
			if (!ModeStateArray[client][SmgBurst])
			{
				ModeStateArray[client][SmgBurst] = true;
				PrintCenterText(client, "switched to burst-fire mode");
			}
			else
			{
				ModeStateArray[client][SmgBurst] = false;
				PrintCenterText(client, "switched to normal mode");
				BurstShotsFired[client] = 0;
			}
		}
	}
	
	OldButtons[client] = buttons;
	return Plugin_Continue;
}

public OnPreThinkPost(client)
{
	if (!IsPlayerAlive(client)) return;
	
	new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	decl String:WeaponName[30];
	if (IsValidEdict(WeaponIndex))
	{
		GetEdictClassname(WeaponIndex, WeaponName, sizeof(WeaponName));
		ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
	}
	else strcopy(WeaponName, sizeof(WeaponName), "none");
	
	new GetWeaponInfo[WeaponAttributes];
	GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 15);
	
	if ((GetWeaponInfo[RunSpeed] != 1.0) && (GetWeaponInfo[RunSpeed] != -1.0))
	{
		// adjust the maximum speed the player can move at.
		GetWeaponInfo[RunSpeed] *= GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");
		
		// some weapons change player speed if they're scoped.
		new Float:WeaponZoomSpeed;
		if (GetTrieValue(WeaponZoomSpeedTrie, WeaponName, WeaponZoomSpeed))
		{
			new Fov = GetEntProp(client,Prop_Data,"m_iFOV");
			if ((Fov != 90) && (Fov != 0)) GetWeaponInfo[RunSpeed] /= WeaponZoomSpeed;
		}
		
		SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", GetWeaponInfo[RunSpeed]);
	}
}

// called just before weapons fire.
public OnPostThink(client)
{
	if (!IsPlayerAlive(client)) return;
	
	new Buttons = GetClientButtons(client);
	
	if (Buttons & IN_ATTACK)
	{
		new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (!IsValidEdict(WeaponIndex)) return;
		
		// weapon can't fire yet.
		if (GetGameTime() < GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack")) return;
		
		//player can't attack yet.
		if (GetGameTime() < GetEntPropFloat(client, Prop_Send, "m_flNextAttack")) return;
		
		// no ammo in clip.
		new ClipAmmo = GetEntProp(WeaponIndex, Prop_Send, "m_iClip1");
		if (!ClipAmmo) return;
		
		decl String:WeaponName[30];
		GetEdictClassname(WeaponIndex, WeaponName, sizeof(WeaponName));
		ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
		
		new GetWeaponInfo[WeaponAttributes];
		GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 15);
		
		// if the weapon is a pistol in semi-automatic mode then ignore it.
		if ((GetWeaponInfo[AutoMode] != -1) && (GetEntProp(client, Prop_Send, "m_iShotsFired"))) return;
		
		if (GetWeaponInfo[InfiniteAmmo] == 1)
		{
			// set ammo clip to 5 if it has one everytime the weapon is about to fire.
			if (ClipAmmo != -1) SetEntProp(WeaponIndex, Prop_Send, "m_iClip1", 5);
			// projectiles don't have an ammo clip
			else
			{
				if (StrEqual("hegrenade", WeaponName, false))
				{
					SetEntProp(client, Prop_Send, "m_iAmmo", 2, 11);
				}
				else if (StrEqual("flashbang", WeaponName, false))
				{
					SetEntProp(client, Prop_Send, "m_iAmmo", 2, 12);
				}
				else if (StrEqual("smokegrenade", WeaponName, false))
				{
					SetEntProp(client, Prop_Send, "m_iAmmo", 2, 13);
				}
			}
		}
		
		// ignore bursts shots on glock/famas.
		if ((StrEqual("glock", WeaponName, false)) || (StrEqual("famas", WeaponName, false)))
		{
			if ((GetEntProp(WeaponIndex, Prop_Send, "m_bBurstMode")) && (GetWeaponInfo[AutoMode] != 1)) return;
		}
		
		if (GetWeaponInfo[BurstMode] == 1)
		{
			if (ModeStateArray[client][SmgBurst])
			{
				ProcessArray[client][ProcessAltMode] = 2;
				
				return;
			}
		}
		else if ((GetWeaponInfo[BurstMode] != 1) && (ModeStateArray[client][SmgBurst])) ModeStateArray[client][SmgBurst] = false;
		
		if ((GetWeaponInfo[RecoilType1] != -1.0) && (GetWeaponInfo[RecoilType1] != 1.0)) ProcessArray[client][ProcessRecoil] = 1;
		else if ((GetWeaponInfo[RecoilType2] != -1.0) && (GetWeaponInfo[RecoilType2] != 1.0))
		{
			// store current recoil.
			GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", PreviousPunchAngle[client]);
			
			ProcessArray[client][ProcessRecoil] = 1;
		}
		
		if (GetWeaponInfo[AutoMode] == 1)
		{
			// make sure automatic mode ovverrides default alt modes.
			/* "m_flNextSecondaryAttack" is when the player can use the alt mode again.
			setting it high blocks it with out prediction issues  caused by hooking the key press instead. */
			if (StrEqual("glock", WeaponName, false))
			{
				SetEntProp(WeaponIndex, Prop_Send, "m_bBurstMode", 0);
				SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack", (GetGameTime() + 999999.0));
			}
			else if (StrEqual("usp", WeaponName, false))
			{
				SetEntProp(WeaponIndex, Prop_Send, "m_bSilencerOn", 0);
				SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack", (GetGameTime() + 999999.0));
			}
			
			if (ModeStateArray[client][PistolAuto])
			{
				ProcessArray[client][ProcessAltMode] = 1;
				
				return;
			}
		}
		else if ((GetWeaponInfo[AutoMode] != 1) && (ModeStateArray[client][PistolAuto])) ModeStateArray[client][PistolAuto] = false;
		
		if ((GetWeaponInfo[FireRate] != -1.0) && (GetWeaponInfo[FireRate] != 1.0)) ProcessArray[client][ProcessFireRate] = 1;
	}
	
	// this is for knife stab.
	else if (Buttons & IN_ATTACK2)
	{
		new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		decl String:WeaponName[30];
		if (IsValidEdict(WeaponIndex))
		{
			GetEdictClassname(WeaponIndex, WeaponName, sizeof(WeaponName));
			ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
		}
		else strcopy(WeaponName, sizeof(WeaponName), "none");
		
		if (StrEqual("knife", WeaponName, false))
		{
			// knife can't attack yet.
			if (GetGameTime() < GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack")) return;
			
			// player can't attack yet.
			if (GetGameTime() < GetEntPropFloat(client, Prop_Send, "m_flNextAttack")) return;
			
			new GetWeaponInfo[WeaponAttributes];
			GetTrieArray(WeaponTypeTrie, "knifestab", GetWeaponInfo[0], 15);
			
			if (GetWeaponInfo[FireRate] != 1.0) ProcessArray[client][ProcessFireRate] = 2;
		}
		
	}
}

// called just after weapons fire.
public OnPostThinkPost(client)
{
	if (!IsPlayerAlive(client)) return;
	
	new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (!IsValidEdict(WeaponIndex)) return;
	
	decl String:WeaponName[30];
	GetEdictClassname(WeaponIndex, WeaponName, sizeof(WeaponName));
	ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
	
	new GetWeaponInfo[WeaponAttributes];
	GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 15);
	
	if (ProcessArray[client][ProcessFireRate] == 1)
	{
		ProcessArray[client][ProcessFireRate] = 0;
		
		/* "m_flNextPrimaryAttack" is when the weapon can next attack relative to GetGameTime,
		adjust it with the multiplier*/
		if (GetWeaponInfo[FireRate] != 100.0)
		{
			new Float:NextAttackTime = GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack");
			
			NextAttackTime -= GetGameTime();
			NextAttackTime /= GetWeaponInfo[FireRate];
			NextAttackTime += GetGameTime();
			
			SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack", NextAttackTime);
		}
		// if the fire rate multiplier is set to maximum value just make the weapon fire every game frame
		else SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
	}
	// adjust knife stab fire rate, same as above but uses "m_flNextSecondaryAttack" instead.
	else if (ProcessArray[client][ProcessFireRate] == 2)
	{
		ProcessArray[client][ProcessFireRate] = 0;
		
		new GetKnifeInfo[WeaponAttributes];
		GetTrieArray(WeaponTypeTrie, "knifestab", GetKnifeInfo[0], 15);
		
		if (GetKnifeInfo[FireRate] != 100.0)
		{
			new Float:NextAttackTime = GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack");
			
			NextAttackTime -= GetGameTime();
			NextAttackTime /= GetKnifeInfo[FireRate];
			NextAttackTime += GetGameTime();
			
			SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack", NextAttackTime);
		}
		else SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack", GetGameTime());
	}
	
	/* "m_iShotsFired" is used to make pistols fire semi-automatic when the attack button is held.
	if it is 1 the pistol will not fire again until the attack key is released then pressed again which will reset it.
	it is also used to calculate recoil on fully automatic weapons. */
	if (ProcessArray[client][ProcessAltMode] == 1)
	{
		ProcessArray[client][ProcessAltMode] = 0;
		
		SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
		
		if (GetWeaponInfo[ModeFireRate] != 100.0)
		{
			new Float:NextAttackTime = GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack");
			
			NextAttackTime -= GetGameTime();
			NextAttackTime /= GetWeaponInfo[ModeFireRate];
			NextAttackTime += GetGameTime();
			
			SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack", NextAttackTime);
		}
		// if the fire rate multiplier is set to maximum value just make the weapon fire every game frame
		else SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
	}
	else if (ProcessArray[client][ProcessAltMode] == 2)
	{
		ProcessArray[client][ProcessAltMode] = 0;
		
		// on the last shot of a burstfire add a delay.
		if (++BurstShotsFired[client] == 3)
		{
			new Float:NextAttackTime = GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack");
			
			NextAttackTime = GetGameTime() + 0.5;
			
			SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack", NextAttackTime);
			
			BurstShotsFired[client] = 0;
		}
		else
		{
			// remove any recoil.from first 2 shots.
			SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
			new Float:NoRecoil[3];
			SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", NoRecoil);
			
			if (GetWeaponInfo[ModeFireRate] != 100.0)
			{
				new Float:NextAttackTime = GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack");
				
				NextAttackTime -= GetGameTime();
				NextAttackTime /= GetWeaponInfo[ModeFireRate];
				NextAttackTime += GetGameTime();
				
				SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack", NextAttackTime);
			}
			// if the fire rate multiplier is set to maximum value just make the weapon fire every game frame
			else SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
		}
	}
	
	// recoil is calculated in 2 ways depending on the weapon.
	if (ProcessArray[client][ProcessRecoil] == 1)
	{
		ProcessArray[client][ProcessRecoil] = 0;
		
		// get new recoil and compare it with the old one in the 2nd recoil method.
		decl Float:CurrentPunchAngle[3];
		GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", CurrentPunchAngle);
		
		if (GetWeaponInfo[RecoilType1] != -1.0)
		{
			if (GetWeaponInfo[RecoilType1] != 0.0) CurrentPunchAngle[0] *= GetWeaponInfo[RecoilType1];
			else
			{
				// remove any recoil.
				SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
				CurrentPunchAngle[0] = 0.0;
				CurrentPunchAngle[1] = 0.0;
			}
		}
		else if (GetWeaponInfo[RecoilType2] != -1.0)
		{
			if (GetWeaponInfo[RecoilType2] != 0.0)
			{
				CurrentPunchAngle[0] -= PreviousPunchAngle[client][0];
				CurrentPunchAngle[0] *= GetWeaponInfo[RecoilType2];
				CurrentPunchAngle[0] += PreviousPunchAngle[client][0];
			}
			// remove any recoil.
			else CurrentPunchAngle[0] = 0.0;
		}
		
		// cap recoil so the players view doesn't turn upside down.
		if (CurrentPunchAngle[0] < -90.0) CurrentPunchAngle[0] = -90.0;
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", CurrentPunchAngle);
	}
	
	/* "m_flNextSecondaryAttack" is when the player can use the alt mode again.
	setting it high blocks it with out prediction issues caused by hooking the key press instead. */
	if (GetWeaponInfo[AutoMode] == 1)
	{
		if (StrEqual("glock", WeaponName, false))
		{
			SetEntProp(WeaponIndex, Prop_Send, "m_bBurstMode", 0);
			SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack", (GetGameTime() + 999999.0));
		}
		else if (StrEqual("usp", WeaponName, false))
		{
			SetEntProp(WeaponIndex, Prop_Send, "m_bSilencerOn", 0);
			SetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack", (GetGameTime() + 999999.0));
		}
	}
	
	/* if quickswitch was used change from the deploy animation back to the idle one on the players viewmodel.
	also remove the attack delay from switching weapons. */
	if (ProcessArray[client][ProcessQuickSwitch] == 1)
	{
		ProcessArray[client][ProcessQuickSwitch] = 0;
		
		/* "m_flNextAttack" is whent the player can next attack, set it to next game frame
		instead of the deploy animation length */
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime());
		
		new ViewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
		
		// make sure the correct animation is used if the silencer is on.
		if (StrEqual("usp", WeaponName, false))
		{
			if (!GetEntProp(WeaponIndex, Prop_Send, "m_bSilencerOn"))
			{
				SetEntProp(ViewModel, Prop_Send, "m_nSequence", 8);
				return;
			}
		}
		else if (StrEqual("m4a1", WeaponName, false))
		{
			if (!GetEntProp(WeaponIndex, Prop_Send, "m_bSilencerOn"))
			{
				SetEntProp(ViewModel, Prop_Send, "m_nSequence", 7);
				return;
			}
		}
		
		SetEntProp(ViewModel, Prop_Send, "m_nSequence", 0);
	}
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if ((attacker > 0) && (attacker <= MaxClients) && (attacker == inflictor))
	{
		new WeaponIndex = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		if (!IsValidEdict(WeaponIndex)) return Plugin_Continue;
		
		decl String:WeaponName[30];
		GetEdictClassname(WeaponIndex, WeaponName, sizeof(WeaponName));
		ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
		
		new GetWeaponInfo[WeaponAttributes];
		GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 15);
		
		if ((GetWeaponInfo[HeadDamage] != 1.0) && (hitgroup == HITGROUP_HEAD))
		{
			if (GetWeaponInfo[HeadDamage] == 0.0) return Plugin_Handled;
			else
			{
				damage *= GetWeaponInfo[HeadDamage];
				
				return Plugin_Changed;
			}
		}
		else if ((GetWeaponInfo[ChestDamage] != 1.0) && (hitgroup == HITGROUP_CHEST))
		{
			if (GetWeaponInfo[ChestDamage] == 0.0) return Plugin_Handled;
			else
			{
				damage *= GetWeaponInfo[ChestDamage];
				
				return Plugin_Changed;
			}
		}
		else if ((GetWeaponInfo[StomachDamage] != 1.0) && (hitgroup == HITGROUP_STOMACH))
		{
			if (GetWeaponInfo[StomachDamage] == 0.0) return Plugin_Handled;
			else
			{
				damage *= GetWeaponInfo[StomachDamage];
				
				return Plugin_Changed;
			}
		}
		else if ((GetWeaponInfo[ArmDamage] != 1.0) && ((hitgroup == HITGROUP_LEFTARM) || (hitgroup == HITGROUP_RIGHTARM)))
		{
			if (GetWeaponInfo[ArmDamage] == 0.0) return Plugin_Handled;
			else
			{
				damage *= GetWeaponInfo[ArmDamage];
				
				return Plugin_Changed;
			}
		}
		else if ((GetWeaponInfo[LegDamage] != 1.0) && ((hitgroup == HITGROUP_LEFTLEG) || (hitgroup == HITGROUP_RIGHTLEG)))
		{
			if (GetWeaponInfo[LegDamage] == 0.0) return Plugin_Handled;
			else
			{
				damage *= GetWeaponInfo[LegDamage];
				
				return Plugin_Changed;
			}
		}
		
		if (StrEqual("knife", WeaponName, false))
		{
			new GetKnifeInfo[WeaponAttributes];
			
			if (damage <= 30.0) GetTrieArray(WeaponTypeTrie, "knife", GetKnifeInfo[0], 15);
			else if ((damage > 30.0) && (damage <= 100.0)) GetTrieArray(WeaponTypeTrie, "knifestab", GetKnifeInfo[0], 15);
			else GetTrieArray(WeaponTypeTrie, "knifebackstab", GetKnifeInfo[0], 15);
			
			if (GetKnifeInfo[GenericDamage] == 0.0) return Plugin_Handled;
			else
			{
				damage *= GetKnifeInfo[GenericDamage];
				
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

// physics damage from projectiles doesn't fire traceattack so use takedamage, stuck grenade in here aswell.
public Action: OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((attacker > 0) && (attacker <= MaxClients) && (attacker != inflictor))
	{
		decl String:WeaponName[30];
		GetEdictClassname(inflictor, WeaponName, sizeof(WeaponName));
		ReplaceString(WeaponName, sizeof(WeaponName), "_projectile", "", false);
		
		new GetWeaponInfo[WeaponAttributes];
		if (GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 15))
		{
			if (GetWeaponInfo[GenericDamage] == 0.0) return Plugin_Handled;
			else
			{
				damage *= GetWeaponInfo[GenericDamage];
				
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:OnWeaponEquip(client, weapon)
{
	new String:WeaponName[30];
	GetEdictClassname(weapon, WeaponName, sizeof(WeaponName));
	ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
	
	new GetWeaponInfo[WeaponAttributes];
	GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 15);
	
	if (GetWeaponInfo[AutoMode] != -1)
	{
		ModeStateArray[client][PistolAuto] = false;
		
		if (GetWeaponInfo[AutoMode])
		{
			if (!(Notify & DISABLE_EQUIP_NOTIFICATION)) PrintToChat(client, "\x04[Weapon Mod]\x05 press alternate attack to switch fire modes on this %s", WeaponName);
		}
	}
	
	if (GetWeaponInfo[BurstMode] != -1)
	{
		ModeStateArray[client][SmgBurst] = false;
		
		if (GetWeaponInfo[BurstMode])
		{
			if (!(Notify & DISABLE_EQUIP_NOTIFICATION)) PrintToChat(client, "\x04[Weapon Mod]\x05 press alternate attack to switch fire modes on this %s", WeaponName);
		}
	}
	
	if (GetWeaponInfo[InfiniteAmmo] == 1)
	{
		if (!(Notify & DISABLE_EQUIP_NOTIFICATION)) PrintToChat(client, "\x04[Weapon Mod]\x05 This %s has infinite ammo enabled", WeaponName);
	}
	
	if (GetWeaponInfo[QuickSwitch] == 1)
	{
		if (!(Notify & DISABLE_EQUIP_NOTIFICATION)) PrintToChat(client, "\x04[Weapon Mod]\x05 This %s has quick switch enabled, You can attack immediately after switching to this weapon.", WeaponName);
	}
	
	return Plugin_Continue;
}

public Action:OnWeaponSwitch(client, weapon)
{
	BurstShotsFired[client] = 0;
	
	decl String:WeaponName[30];
	GetEdictClassname(weapon, WeaponName, sizeof(WeaponName));
	ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
	
	new GetWeaponInfo[WeaponAttributes];
	GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 15);
	
	if (GetWeaponInfo[QuickSwitch] == 1) ProcessArray[client][ProcessQuickSwitch] = 1;
	
	return Plugin_Continue;
}

public Action:Command_Say(client, const String:command[], argc)
{
	
	if (!(Notify & DISABLE_MENU_NOTIFICATION))
	{
		new String:text[15];
		GetCmdArg(1, text, sizeof(text));
		
		if (StrEqual(text, "!weaponmod", false))
		{
			DisplayMenu(WeaponmodMenu, client, MENU_TIME_FOREVER);
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public WeaponmodMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:WeaponName[30];
		if (GetMenuItem(menu, param2, WeaponName, sizeof(WeaponName)))
		{
			new GetWeaponInfo[WeaponAttributes];
			GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 15);
			
			new Handle:AttributeMenu = CreateMenu(MenuHandler);
			SetMenuTitle(AttributeMenu, "%s settings", WeaponName);
			
			new String:menubuffer[100];
			new String:FloatString[20];
			
			if (GetWeaponInfo[RecoilType1] != -1.0)
			{
				FloatToString(GetWeaponInfo[RecoilType1], FloatString, sizeof(FloatString));
				
				if (GetWeaponInfo[RecoilType1] != 0.0)
				{
					Format(menubuffer, sizeof(menubuffer), "Recoil = %s multiplier", FloatString);
				}
				else
				{
					Format(menubuffer, sizeof(menubuffer), "Recoil = Disabled");
				}
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[RecoilType2] != -1.0)
			{
				FloatToString(GetWeaponInfo[RecoilType2], FloatString, sizeof(FloatString));
				
				if (GetWeaponInfo[RecoilType1] != 0.0)
				{
					Format(menubuffer, sizeof(menubuffer), "Recoil = %s multiplier", FloatString);
				}
				else
				{
					Format(menubuffer, sizeof(menubuffer), "Recoil = Disabled");
				}
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[FireRate] != -1.0)
			{
				FloatToString(GetWeaponInfo[FireRate], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Fire Rate = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[AutoMode] != -1)
			{
				if (GetWeaponInfo[AutoMode] == 1)
				{
					Format(menubuffer, sizeof(menubuffer), "Automatic Mode = Enabled");
				}
				else
				{
					Format(menubuffer, sizeof(menubuffer), "Automatic Mode = Disabled");
				}
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
				
				if (GetWeaponInfo[ModeFireRate] != -1.0)
				{
					FloatToString(GetWeaponInfo[ModeFireRate], FloatString, sizeof(FloatString));
					Format(menubuffer, sizeof(menubuffer), "Automatic Fire Rate = %s multiplier", FloatString);
					
					AddMenuItem(AttributeMenu, menubuffer, menubuffer);
				}
			}
			
			if (GetWeaponInfo[RunSpeed] != -1.0)
			{
				FloatToString(GetWeaponInfo[RunSpeed], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Run Speed = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[GenericDamage] != -1.0)
			{
				FloatToString(GetWeaponInfo[GenericDamage], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Generic Damage = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[HeadDamage] != -1.0)
			{
				FloatToString(GetWeaponInfo[HeadDamage], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Head Damage = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[ChestDamage] != -1.0)
			{
				FloatToString(GetWeaponInfo[ChestDamage], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Chest Damage = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[StomachDamage] != -1.0)
			{
				FloatToString(GetWeaponInfo[StomachDamage], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Stomach Damage = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[ArmDamage] != -1.0)
			{
				FloatToString(GetWeaponInfo[ArmDamage], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Arm Damage = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[LegDamage] != -1.0)
			{
				FloatToString(GetWeaponInfo[LegDamage], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Leg Damage = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[BurstMode] != -1)
			{
				if (GetWeaponInfo[BurstMode] == 1)
				{
					Format(menubuffer, sizeof(menubuffer), "BurstFire Mode = Enabled");
				}
				else
				{
					Format(menubuffer, sizeof(menubuffer), "BurstFire Mode = Disabled");
				}
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
				
				if (GetWeaponInfo[ModeFireRate] != -1.0)
				{
					FloatToString(GetWeaponInfo[ModeFireRate], FloatString, sizeof(FloatString));
					Format(menubuffer, sizeof(menubuffer), "BurstFire Fire Rate = %s multiplier", FloatString);
					
					AddMenuItem(AttributeMenu, menubuffer, menubuffer);
				}
			}
			
			if (GetWeaponInfo[InfiniteAmmo] != -1)
			{
				if (GetWeaponInfo[InfiniteAmmo] == 1)
				{
					Format(menubuffer, sizeof(menubuffer), "Infinite Ammo = Enabled");
				}
				else
				{
					Format(menubuffer, sizeof(menubuffer), "Infinite Ammo = Disabled");
				}
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[QuickSwitch] != -1)
			{
				if (GetWeaponInfo[QuickSwitch] == 1)
				{
					Format(menubuffer, sizeof(menubuffer), "Quick Switch = Enabled");
				}
				else
				{
					Format(menubuffer, sizeof(menubuffer), "Quick Switch = Disabled");
				}
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			DisplayMenu(AttributeMenu, param1, MENU_TIME_FOREVER);
		}
	}
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) DisplayMenu(WeaponmodMenu, param1, MENU_TIME_FOREVER);
	else if (action == MenuAction_End) CloseHandle(menu);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!(Notify & DISABLE_MENU_NOTIFICATION)) PrintToChatAll("\x04[Weapon Mod]\x05 Type !weaponmod in chat to see if any weapons have been modified.");
}