#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.5"

#define HITGROUP_HEAD 1
#define HITGROUP_CHEST 2
#define HITGROUP_STOMACH 3
#define HITGROUP_LEFTARM 4
#define HITGROUP_RIGHTARM 5
#define HITGROUP_LEFTLEG 6
#define HITGROUP_RIGHTLEG 7

#define DISABLE_COMMAND_NOTIFICATION 1
#define DISABLE_EQUIP_NOTIFICATION 2

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
new AmmoOffset;
new Handle:WeaponmodMenu;

public Plugin:myinfo =
{
	name = "Weapon Mod",
	author = "Blodia",
	description = "Lets you modify certain attributes of weapons.",
	version = "1.5",
	url = ""
}

public OnPluginStart()
{
	ServerCommand("sv_maxspeed 1500");
	
	WeaponTypeTrie = CreateTrie();
	WeaponZoomSpeedTrie = CreateTrie();
	
	CreateConVar("weaponmod_version", PLUGIN_VERSION, "Weaponmod version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	hNotifications = CreateConVar("weaponmod_disablenotifications", "0", "0 show all notifications, 1 disable server command notifications, 2 disable weapon equip notifications, 3 disable all notifications", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 3.0);
	
	HookConVarChange(hNotifications, ConVarChange);
	Notify = GetConVarInt(hNotifications);
	
	RegServerCmd("weaponmod", ModAttribute, "modify a weapons attribute usage:weaponmod <weapon> <attribute> <value>");
	
	AmmoOffset = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team"); 
	HookEvent("round_start", Event_RoundStart);
	
	WeaponmodMenu = CreateMenu(WeaponmodMenuHandler);
	SetMenuTitle(WeaponmodMenu, "Weaponmod settings");
	AddMenuItem(WeaponmodMenu, "galilar", "galilar");
	AddMenuItem(WeaponmodMenu, "ak47", "ak47");
	AddMenuItem(WeaponmodMenu, "bizon", "bizon");
	AddMenuItem(WeaponmodMenu, "famas", "famas");
	AddMenuItem(WeaponmodMenu, "m4a1", "m4a1");
	AddMenuItem(WeaponmodMenu, "aug", "aug");
	AddMenuItem(WeaponmodMenu, "nova", "nova");
	AddMenuItem(WeaponmodMenu, "sg556", "sg556");
	AddMenuItem(WeaponmodMenu, "awp", "awp");
	AddMenuItem(WeaponmodMenu, "negev", "negev");
	AddMenuItem(WeaponmodMenu, "bizon", "bizon");
	AddMenuItem(WeaponmodMenu, "sawedoff", "sawedoff");
	AddMenuItem(WeaponmodMenu, "xm1014", "xm1014");
	AddMenuItem(WeaponmodMenu, "mac10", "mac10");
	AddMenuItem(WeaponmodMenu, "mp9", "mp9");
	AddMenuItem(WeaponmodMenu, "mp7", "mp7");
	AddMenuItem(WeaponmodMenu, "ump45", "ump45");
	AddMenuItem(WeaponmodMenu, "p90", "p90");
	AddMenuItem(WeaponmodMenu, "m249", "m249");
	AddMenuItem(WeaponmodMenu, "glock", "glock");
	AddMenuItem(WeaponmodMenu, "tec9", "tec9");
	AddMenuItem(WeaponmodMenu, "p250", "p250");
	AddMenuItem(WeaponmodMenu, "deagle", "deagle");
	AddMenuItem(WeaponmodMenu, "elite", "elite");
	AddMenuItem(WeaponmodMenu, "fiveseven", "fiveseven");
	AddMenuItem(WeaponmodMenu, "knifegg", "knifegg");
	AddMenuItem(WeaponmodMenu, "knife", "knife");
	AddMenuItem(WeaponmodMenu, "mag7", "mag7");
	AddMenuItem(WeaponmodMenu, "hkp2000", "hkp2000");
	AddMenuItem(WeaponmodMenu, "scar20", "scar20");
	AddMenuItem(WeaponmodMenu, "g3sg1", "g3sg1");
	AddMenuItem(WeaponmodMenu, "ssg08", "ssg08");
	AddMenuItem(WeaponmodMenu, "none", "none");

	new galilarInfo[WeaponAttributes];
	galilarInfo[RecoilType1] = 1.0;
	galilarInfo[RecoilType2] = -1.0;
	galilarInfo[FireRate] = 1.0;
	galilarInfo[AutoMode] = -1;
	galilarInfo[RunSpeed] = 1.0;
	galilarInfo[GenericDamage] = -1.0;
	galilarInfo[HeadDamage] = 3.0;
	galilarInfo[ChestDamage] = 3.0;
	galilarInfo[StomachDamage] = 3.0;
	galilarInfo[ArmDamage] = 3.0;
	galilarInfo[LegDamage] = 3.0;
	galilarInfo[BurstMode] = -1;
	galilarInfo[InfiniteAmmo] = 0;
	galilarInfo[QuickSwitch] = 0;
	galilarInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "galilar", galilarInfo[0], 15);
	
	new Ak47Info[WeaponAttributes];
	Ak47Info[RecoilType1] = 1.0;
	Ak47Info[RecoilType2] = -1.0;
	Ak47Info[FireRate] = 1.0;
	Ak47Info[AutoMode] = -1;
	Ak47Info[RunSpeed] = 1.0;
	Ak47Info[GenericDamage] = -1.0;
	Ak47Info[HeadDamage] = 3.0;
	Ak47Info[ChestDamage] = 3.0;
	Ak47Info[StomachDamage] = 3.0;
	Ak47Info[ArmDamage] = 3.0;
	Ak47Info[LegDamage] = 3.0;
	Ak47Info[BurstMode] = -1;
	Ak47Info[InfiniteAmmo] = 0;
	Ak47Info[QuickSwitch] = 0;
	Ak47Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "ak47", Ak47Info[0], 15);
	
	new novaInfo[WeaponAttributes];
	novaInfo[RecoilType1] = -1.0;
	novaInfo[RecoilType2] = 1.0;
	novaInfo[FireRate] = 1.0;
	novaInfo[AutoMode] = -1;
	novaInfo[RunSpeed] = 1.0;
	novaInfo[GenericDamage] = -1.0;
	novaInfo[HeadDamage] = 3.0;
	novaInfo[ChestDamage] = 3.0;
	novaInfo[StomachDamage] = 3.0;
	novaInfo[ArmDamage] = 3.0;
	novaInfo[LegDamage] = 3.0;
	novaInfo[BurstMode] = -1;
	novaInfo[InfiniteAmmo] = 0;
	novaInfo[QuickSwitch] = 0;
	novaInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "nova", novaInfo[0], 14);
	
	new sg556Info[WeaponAttributes];
	sg556Info[RecoilType1] = 1.0;
	sg556Info[RecoilType2] = -1.0;
	sg556Info[FireRate] = 1.0;
	sg556Info[AutoMode] = -1;
	sg556Info[RunSpeed] = 1.0;
	sg556Info[GenericDamage] = -1.0;
	sg556Info[HeadDamage] = 3.0;
	sg556Info[ChestDamage] = 3.0;
	sg556Info[StomachDamage] = 3.0;
	sg556Info[ArmDamage] = 3.0;
	sg556Info[LegDamage] = 3.0;
	sg556Info[BurstMode] = -1;
	sg556Info[InfiniteAmmo] = 0;
	sg556Info[QuickSwitch] = 0;
	sg556Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "sg556", sg556Info[0], 15);
	
	new AwpInfo[WeaponAttributes];
	AwpInfo[RecoilType1] = -1.0;
	AwpInfo[RecoilType2] = 1.0;
	AwpInfo[FireRate] = 1.0;
	AwpInfo[AutoMode] = -1;
	AwpInfo[RunSpeed] = 1.0;
	AwpInfo[GenericDamage] = -1.0;
	AwpInfo[HeadDamage] = 2.0;
	AwpInfo[ChestDamage] = 2.0;
	AwpInfo[StomachDamage] = 2.0;
	AwpInfo[ArmDamage] = 2.0;
	AwpInfo[LegDamage] = 2.0;
	AwpInfo[BurstMode] = -1;
	AwpInfo[InfiniteAmmo] = 0;
	AwpInfo[QuickSwitch] = 0;
	AwpInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "awp", AwpInfo[0], 15);
	
	new negevInfo[WeaponAttributes];
	negevInfo[RecoilType1] = -1.0;
	negevInfo[RecoilType2] = 1.0;
	negevInfo[FireRate] = 1.0;
	negevInfo[AutoMode] = -1;
	negevInfo[RunSpeed] = 1.0;
	negevInfo[GenericDamage] = -1.0;
	negevInfo[HeadDamage] = 3.0;
	negevInfo[ChestDamage] = 3.0;
	negevInfo[StomachDamage] = 3.0;
	negevInfo[ArmDamage] = 3.0;
	negevInfo[LegDamage] = 3.0;
	negevInfo[BurstMode] = -1;
	negevInfo[InfiniteAmmo] = 0;
	negevInfo[QuickSwitch] = 0;
	negevInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "negev", negevInfo[0], 15);
	
	new FamasInfo[WeaponAttributes];
	FamasInfo[RecoilType1] = 1.0;
	FamasInfo[RecoilType2] = -1.0;
	FamasInfo[FireRate] = 1.0;
	FamasInfo[AutoMode] = -1;
	FamasInfo[RunSpeed] = 1.0;
	FamasInfo[GenericDamage] = -1.0;
	FamasInfo[HeadDamage] = 3.0;
	FamasInfo[ChestDamage] = 3.0;
	FamasInfo[StomachDamage] = 3.0;
	FamasInfo[ArmDamage] = 3.0;
	FamasInfo[LegDamage] = 3.0;
	FamasInfo[BurstMode] = -1;
	FamasInfo[InfiniteAmmo] = 0;
	FamasInfo[QuickSwitch] = 0;
	FamasInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "famas", FamasInfo[0], 15);
	
	new m4a1Info[WeaponAttributes];
	m4a1Info[RecoilType1] = 1.0;
	m4a1Info[RecoilType2] = -1.0;
	m4a1Info[FireRate] = 1.0;
	m4a1Info[AutoMode] = -1;
	m4a1Info[RunSpeed] = 1.0;
	m4a1Info[GenericDamage] = -1.0;
	m4a1Info[HeadDamage] = 3.0;
	m4a1Info[ChestDamage] = 3.0;
	m4a1Info[StomachDamage] = 3.0;
	m4a1Info[ArmDamage] = 3.0;
	m4a1Info[LegDamage] = 3.0;
	m4a1Info[BurstMode] = -1;
	m4a1Info[InfiniteAmmo] = 0;
	m4a1Info[QuickSwitch] = 0;
	m4a1Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "m4a1", m4a1Info[0], 15);
	
	new AugInfo[WeaponAttributes];
	AugInfo[RecoilType1] = 1.0;
	AugInfo[RecoilType2] = -1.0;
	AugInfo[FireRate] = 1.0;
	AugInfo[AutoMode] = -1;
	AugInfo[RunSpeed] = 1.0;
	AugInfo[GenericDamage] = -1.0;
	AugInfo[HeadDamage] = 3.0;
	AugInfo[ChestDamage] = 3.0;
	AugInfo[StomachDamage] = 3.0;
	AugInfo[ArmDamage] = 3.0;
	AugInfo[LegDamage] = 3.0;
	AugInfo[BurstMode] = -1;
	AugInfo[InfiniteAmmo] = 0;
	AugInfo[QuickSwitch] = 0;
	AugInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "aug", AugInfo[0], 15);
	
	new bizonInfo[WeaponAttributes];
	bizonInfo[RecoilType1] = -1.0;
	bizonInfo[RecoilType2] = 1.0;
	bizonInfo[FireRate] = 1.0;
	bizonInfo[AutoMode] = -1;
	bizonInfo[RunSpeed] = 1.0;
	bizonInfo[GenericDamage] = -1.0;
	bizonInfo[HeadDamage] = 3.0;
	bizonInfo[ChestDamage] = 3.0;
	bizonInfo[StomachDamage] = 3.0;
	bizonInfo[ArmDamage] = 3.0;
	bizonInfo[LegDamage] = 3.0;
	bizonInfo[BurstMode] = -1;
	bizonInfo[InfiniteAmmo] = 0;
	bizonInfo[QuickSwitch] = 0;
	bizonInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "bizon", bizonInfo[0], 15);
	
	new GlockInfo[WeaponAttributes];
	GlockInfo[RecoilType1] = -1.0;
	GlockInfo[RecoilType2] = -1.0;
	GlockInfo[FireRate] = 1.0;
	GlockInfo[AutoMode] = 0;
	GlockInfo[RunSpeed] = 1.0;
	GlockInfo[GenericDamage] = -1.0;
	GlockInfo[HeadDamage] = 3.0;
	GlockInfo[ChestDamage] = 3.0;
	GlockInfo[StomachDamage] = 3.0;
	GlockInfo[ArmDamage] = 3.0;
	GlockInfo[LegDamage] = 3.0;
	GlockInfo[BurstMode] = -1;
	GlockInfo[InfiniteAmmo] = 0;
	GlockInfo[QuickSwitch] = 0;
	GlockInfo[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "glock", GlockInfo[0], 15);
	
	new tec9Info[WeaponAttributes];
	tec9Info[RecoilType1] = -1.0;
	tec9Info[RecoilType2] = 1.0;
	tec9Info[FireRate] = 1.0;
	tec9Info[AutoMode] = 0;
	tec9Info[RunSpeed] = 1.0;
	tec9Info[GenericDamage] = -1.0;
	tec9Info[HeadDamage] = 3.0;
	tec9Info[ChestDamage] = 3.0;
	tec9Info[StomachDamage] = 3.0;
	tec9Info[ArmDamage] = 3.0;
	tec9Info[LegDamage] = 3.0;
	tec9Info[BurstMode] = -1;
	tec9Info[InfiniteAmmo] = 0;
	tec9Info[QuickSwitch] = 0;
	tec9Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "tec9", tec9Info[0], 15);
	
	new p250Info[WeaponAttributes];
	p250Info[RecoilType1] = -1.0;
	p250Info[RecoilType2] = 1.0;
	p250Info[FireRate] = 1.0;
	p250Info[AutoMode] = 0;
	p250Info[RunSpeed] = 1.0;
	p250Info[GenericDamage] = -1.0;
	p250Info[HeadDamage] = 3.0;
	p250Info[ChestDamage] = 3.0;
	p250Info[StomachDamage] = 3.0;
	p250Info[ArmDamage] = 3.0;
	p250Info[LegDamage] = 3.0;
	p250Info[BurstMode] = -1;
	p250Info[InfiniteAmmo] = 0;
	p250Info[QuickSwitch] = 0;
	p250Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "p250", p250Info[0], 15);
	
	new DeagleInfo[WeaponAttributes];
	DeagleInfo[RecoilType1] = -1.0;
	DeagleInfo[RecoilType2] = 1.0;
	DeagleInfo[FireRate] = 1.0;
	DeagleInfo[AutoMode] = 0;
	DeagleInfo[RunSpeed] = 1.0;
	DeagleInfo[GenericDamage] = -1.0;
	DeagleInfo[HeadDamage] = 3.0;
	DeagleInfo[ChestDamage] = 3.0;
	DeagleInfo[StomachDamage] = 3.0;
	DeagleInfo[ArmDamage] = 3.0;
	DeagleInfo[LegDamage] = 3.0;
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
	EliteInfo[HeadDamage] = 3.0;
	EliteInfo[ChestDamage] = 3.0;
	EliteInfo[StomachDamage] = 3.0;
	EliteInfo[ArmDamage] = 3.0;
	EliteInfo[LegDamage] = 3.0;
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
	FivesevenInfo[HeadDamage] = 3.0;
	FivesevenInfo[ChestDamage] = 3.0;
	FivesevenInfo[StomachDamage] = 3.0;
	FivesevenInfo[ArmDamage] = 3.0;
	FivesevenInfo[LegDamage] = 3.0;
	FivesevenInfo[BurstMode] = -1;
	FivesevenInfo[InfiniteAmmo] = 0;
	FivesevenInfo[QuickSwitch] = 0;
	FivesevenInfo[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "fiveseven", FivesevenInfo[0], 15);
	
	new sawedoffInfo[WeaponAttributes];
	sawedoffInfo[RecoilType1] = -1.0;
	sawedoffInfo[RecoilType2] = 1.0;
	sawedoffInfo[FireRate] = 1.0;
	sawedoffInfo[AutoMode] = -1;
	sawedoffInfo[RunSpeed] = 1.0;
	sawedoffInfo[GenericDamage] = -1.0;
	sawedoffInfo[HeadDamage] = 3.0;
	sawedoffInfo[ChestDamage] = 3.0;
	sawedoffInfo[StomachDamage] = 3.0;
	sawedoffInfo[ArmDamage] = 3.0;
	sawedoffInfo[LegDamage] = 3.0;
	sawedoffInfo[BurstMode] = -1;
	sawedoffInfo[InfiniteAmmo] = 0;
	sawedoffInfo[QuickSwitch] = 0;
	sawedoffInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "sawedoff", sawedoffInfo[0], 15);
	
	new Xm1014Info[WeaponAttributes];
	Xm1014Info[RecoilType1] = -1.0;
	Xm1014Info[RecoilType2] = 1.0;
	Xm1014Info[FireRate] = 1.0;
	Xm1014Info[AutoMode] = -1;
	Xm1014Info[RunSpeed] = 1.0;
	Xm1014Info[GenericDamage] = -1.0;
	Xm1014Info[HeadDamage] = 3.0;
	Xm1014Info[ChestDamage] = 3.0;
	Xm1014Info[StomachDamage] = 3.0;
	Xm1014Info[ArmDamage] = 3.0;
	Xm1014Info[LegDamage] = 3.0;
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
	Mac10Info[HeadDamage] = 3.0;
	Mac10Info[ChestDamage] = 3.0;
	Mac10Info[StomachDamage] = 3.0;
	Mac10Info[ArmDamage] = 3.0;
	Mac10Info[LegDamage] = 3.0;
	Mac10Info[BurstMode] = 0;
	Mac10Info[InfiniteAmmo] = 0;
	Mac10Info[QuickSwitch] = 0;
	Mac10Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "mac10", Mac10Info[0], 15);
	
	new mp9Info[WeaponAttributes];
	mp9Info[RecoilType1] = 1.0;
	mp9Info[RecoilType2] = -1.0;
	mp9Info[FireRate] = 1.0;
	mp9Info[AutoMode] = -1;
	mp9Info[RunSpeed] = 1.0;
	mp9Info[GenericDamage] = -1.0;
	mp9Info[HeadDamage] = 3.0;
	mp9Info[ChestDamage] = 3.0;
	mp9Info[StomachDamage] = 3.0;
	mp9Info[ArmDamage] = 3.0;
	mp9Info[LegDamage] = 3.0;
	mp9Info[BurstMode] = 0;
	mp9Info[InfiniteAmmo] = 0;
	mp9Info[QuickSwitch] = 0;
	mp9Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "mp9", mp9Info[0], 15);
	
	new mp7Info[WeaponAttributes];
	mp7Info[RecoilType1] = 1.0;
	mp7Info[RecoilType2] = -1.0;
	mp7Info[FireRate] = 1.0;
	mp7Info[AutoMode] = -1;
	mp7Info[RunSpeed] = 1.0;
	mp7Info[GenericDamage] = -1.0;
	mp7Info[HeadDamage] = 3.0;
	mp7Info[ChestDamage] = 3.0;
	mp7Info[StomachDamage] = 3.0;
	mp7Info[ArmDamage] = 3.0;
	mp7Info[LegDamage] = 3.0;
	mp7Info[BurstMode] = 0;
	mp7Info[InfiniteAmmo] = 0;
	mp7Info[QuickSwitch] = 0;
	mp7Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "mp7", mp7Info[0], 15);
	
	new Ump45Info[WeaponAttributes];
	Ump45Info[RecoilType1] = 1.0;
	Ump45Info[RecoilType2] = -1.0;
	Ump45Info[FireRate] = 1.0;
	Ump45Info[AutoMode] = -1;
	Ump45Info[RunSpeed] = 1.0;
	Ump45Info[GenericDamage] = -1.0;
	Ump45Info[HeadDamage] = 3.0;
	Ump45Info[ChestDamage] = 3.0;
	Ump45Info[StomachDamage] = 3.0;
	Ump45Info[ArmDamage] = 3.0;
	Ump45Info[LegDamage] = 3.0;
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
	P90Info[HeadDamage] = 3.0;
	P90Info[ChestDamage] = 3.0;
	P90Info[StomachDamage] = 3.0;
	P90Info[ArmDamage] = 3.0;
	P90Info[LegDamage] = 3.0;
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
	M249Info[HeadDamage] = 3.0;
	M249Info[ChestDamage] = 3.0;
	M249Info[StomachDamage] = 3.0;
	M249Info[ArmDamage] = 3.0;
	M249Info[LegDamage] = 3.0;
	M249Info[BurstMode] = -1;
	M249Info[InfiniteAmmo] = 0;
	M249Info[QuickSwitch] = 0;
	M249Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "m249", M249Info[0], 15);
	
	new knifeggInfo[WeaponAttributes];
	knifeggInfo[RecoilType1] = -1.0;
	knifeggInfo[RecoilType2] = -1.0;
	knifeggInfo[FireRate] = -1.0;
	knifeggInfo[AutoMode] = -1;
	knifeggInfo[RunSpeed] = 1.0;
	knifeggInfo[GenericDamage] = 3.0;
	knifeggInfo[HeadDamage] = 3.0;
	knifeggInfo[ChestDamage] = 3.0;
	knifeggInfo[StomachDamage] = 3.0;
	knifeggInfo[ArmDamage] = 3.0;
	knifeggInfo[LegDamage] = 3.0;
	knifeggInfo[BurstMode] = -1;
	knifeggInfo[InfiniteAmmo] = 0;
	knifeggInfo[QuickSwitch] = 0;
	knifeggInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "knifegg", knifeggInfo[0], 15);
	
	new knifeInfo[WeaponAttributes];
	knifeInfo[RecoilType1] = -1.0;
	knifeInfo[RecoilType2] = -1.0;
	knifeInfo[FireRate] = -1.0;
	knifeInfo[AutoMode] = -1;
	knifeInfo[RunSpeed] = 1.0;
	knifeInfo[GenericDamage] = 3.0;
	knifeInfo[HeadDamage] = 3.0;
	knifeInfo[ChestDamage] = 3.0;
	knifeInfo[StomachDamage] = 3.0;
	knifeInfo[ArmDamage] = 3.0;
	knifeInfo[LegDamage] = 3.0;
	knifeInfo[BurstMode] = -1;
	knifeInfo[InfiniteAmmo] = 0;
	knifeInfo[QuickSwitch] = 0;
	knifeInfo[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "knife", knifeInfo[0], 15);
	
	new mag7Info[WeaponAttributes];
	mag7Info[RecoilType1] = 1.0;
	mag7Info[RecoilType2] = -1.0;
	mag7Info[FireRate] = 1.0;
	mag7Info[AutoMode] = -1;
	mag7Info[RunSpeed] = 1.0;
	mag7Info[GenericDamage] = -1.0;
	mag7Info[HeadDamage] = 3.0;
	mag7Info[ChestDamage] = 3.0;
	mag7Info[StomachDamage] = 3.0;
	mag7Info[ArmDamage] = 3.0;
	mag7Info[LegDamage] = 3.0;
	mag7Info[BurstMode] = -1;
	mag7Info[InfiniteAmmo] = 0;
	mag7Info[QuickSwitch] = 0;
	mag7Info[ModeFireRate] = -1.0;
	SetTrieArray(WeaponTypeTrie, "mag7", mag7Info[0], 15);
	
	new hkp2000Info[WeaponAttributes];
	hkp2000Info[RecoilType1] = 1.0;
	hkp2000Info[RecoilType2] = -1.0;
	hkp2000Info[FireRate] = 1.0;
	hkp2000Info[AutoMode] = -1;
	hkp2000Info[RunSpeed] = 1.0;
	hkp2000Info[GenericDamage] = -1.0;
	hkp2000Info[HeadDamage] = 3.0;
	hkp2000Info[ChestDamage] = 3.0;
	hkp2000Info[StomachDamage] = 3.0;
	hkp2000Info[ArmDamage] = 3.0;
	hkp2000Info[LegDamage] = 3.0;
	hkp2000Info[BurstMode] = 0;
	hkp2000Info[InfiniteAmmo] = 0;
	hkp2000Info[QuickSwitch] = 0;
	hkp2000Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "hkp2000", hkp2000Info[0], 15);

	new scar20Info[WeaponAttributes];
	scar20Info[RecoilType1] = 1.0;
	scar20Info[RecoilType2] = -1.0;
	scar20Info[FireRate] = 1.0;
	scar20Info[AutoMode] = -1;
	scar20Info[RunSpeed] = 1.0;
	scar20Info[GenericDamage] = -1.0;
	scar20Info[HeadDamage] = 3.0;
	scar20Info[ChestDamage] = 3.0;
	scar20Info[StomachDamage] = 3.0;
	scar20Info[ArmDamage] = 3.0;
	scar20Info[LegDamage] = 3.0;
	scar20Info[BurstMode] = 0;
	scar20Info[InfiniteAmmo] = 0;
	scar20Info[QuickSwitch] = 0;
	scar20Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "scar20", scar20Info[0], 15);

	new g3sg1Info[WeaponAttributes];
	g3sg1Info[RecoilType1] = 1.0;
	g3sg1Info[RecoilType2] = -1.0;
	g3sg1Info[FireRate] = 1.0;
	g3sg1Info[AutoMode] = -1;
	g3sg1Info[RunSpeed] = 1.0;
	g3sg1Info[GenericDamage] = -1.0;
	g3sg1Info[HeadDamage] = 3.0;
	g3sg1Info[ChestDamage] = 3.0;
	g3sg1Info[StomachDamage] = 3.0;
	g3sg1Info[ArmDamage] = 3.0;
	g3sg1Info[LegDamage] = 3.0;
	g3sg1Info[BurstMode] = 0;
	g3sg1Info[InfiniteAmmo] = 0;
	g3sg1Info[QuickSwitch] = 0;
	g3sg1Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "g3sg1", g3sg1Info[0], 15);

	new ssg08Info[WeaponAttributes];
	ssg08Info[RecoilType1] = 1.0;
	ssg08Info[RecoilType2] = -1.0;
	ssg08Info[FireRate] = 1.0;
	ssg08Info[AutoMode] = -1;
	ssg08Info[RunSpeed] = 1.0;
	ssg08Info[GenericDamage] = -1.0;
	ssg08Info[HeadDamage] = 3.0;
	ssg08Info[ChestDamage] = 3.0;
	ssg08Info[StomachDamage] = 3.0;
	ssg08Info[ArmDamage] = 3.0;
	ssg08Info[LegDamage] = 3.0;
	ssg08Info[BurstMode] = 0;
	ssg08Info[InfiniteAmmo] = 0;
	ssg08Info[QuickSwitch] = 0;
	ssg08Info[ModeFireRate] = 3.0;
	SetTrieArray(WeaponTypeTrie, "ssg08", ssg08Info[0], 15);
	
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
	
	SetTrieValue(WeaponZoomSpeedTrie, "nova", 1.1818181);
	SetTrieValue(WeaponZoomSpeedTrie, "sg556", 1.175);
	SetTrieValue(WeaponZoomSpeedTrie, "awp", 1.4);
	SetTrieValue(WeaponZoomSpeedTrie, "bizon", 1.4);
	
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- aug, sg556, awp, scar20, g3sg1, ssg08, m4a1, ak47");
			PrintToServer("********** weaponmod: continued:- famas, galilar, bizon, mag7, mac10, mp9, mp7, ump45, p90");
			PrintToServer("********** weaponmod: continued:- fiveseven, hkp2000, glock, tec9, p250, deagle, elite, m249, negev");
			PrintToServer("********** weaponmod: continued:- xm1014, sawedoff, nova, knifegg, knife");
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- aug, sg556, awp, scar20, g3sg1, ssg08, m4a1, ak47");
			PrintToServer("********** weaponmod: continued:- famas, galilar, bizon, mag7, mac10, mp9, mp7, ump45, p90");
			PrintToServer("********** weaponmod: continued:- fiveseven, hkp2000, glock, tec9, p250, deagle, elite, m249, negev");
			PrintToServer("********** weaponmod: continued:- xm1014, sawedoff, nova, knifegg, knife");
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- glock, famas");
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- aug, sg556, awp, scar20, g3sg1, ssg08, m4a1, ak47");
			PrintToServer("********** weaponmod: continued:- famas, galilar, bizon, mag7, mac10, mp9, mp7, ump45, p90");
			PrintToServer("********** weaponmod: continued:- fiveseven, hkp2000, glock, tec9, p250, deagle, elite, m249, negev");
			PrintToServer("********** weaponmod: continued:- xm1014, sawedoff, nova, knifegg, knife");
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
			PrintToServer("********** weaponmod: continued:- knifegg, knife");
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- aug, sg556, awp, scar20, g3sg1, ssg08, m4a1, ak47");
			PrintToServer("********** weaponmod: continued:- famas, galilar, bizon, mag7, mac10, mp9, mp7, ump45, p90");
			PrintToServer("********** weaponmod: continued:- fiveseven, hkp2000, glock, tec9, p250, deagle, elite, m249, negev");
			PrintToServer("********** weaponmod: continued:- xm1014, sawedoff, nova, knifegg, knife");
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- aug, sg556, awp, scar20, g3sg1, ssg08, m4a1, ak47");
			PrintToServer("********** weaponmod: continued:- famas, galilar, bizon, mag7, mac10, mp9, mp7, ump45, p90");
			PrintToServer("********** weaponmod: continued:- fiveseven, hkp2000, glock, tec9, p250, deagle, elite, m249, negev");
			PrintToServer("********** weaponmod: continued:- xm1014, sawedoff, nova, knifegg, knife");
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- aug, sg556, awp, scar20, g3sg1, ssg08, m4a1, ak47");
			PrintToServer("********** weaponmod: continued:- famas, galilar, bizon, mag7, mac10, mp9, mp7, ump45, p90");
			PrintToServer("********** weaponmod: continued:- fiveseven, hkp2000, glock, tec9, p250, deagle, elite, m249, negev");
			PrintToServer("********** weaponmod: continued:- xm1014, sawedoff, nova, knifegg, knife");
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- aug, sg556, awp, scar20, g3sg1, ssg08, m4a1, ak47");
			PrintToServer("********** weaponmod: continued:- famas, galilar, bizon, mag7, mac10, mp9, mp7, ump45, p90");
			PrintToServer("********** weaponmod: continued:- fiveseven, hkp2000, glock, tec9, p250, deagle, elite, m249, negev");
			PrintToServer("********** weaponmod: continued:- xm1014, sawedoff, nova, knifegg, knife");
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- aug, sg556, awp, scar20, g3sg1, ssg08, m4a1, ak47");
			PrintToServer("********** weaponmod: continued:- famas, galilar, bizon, mag7, mac10, mp9, mp7, ump45, p90");
			PrintToServer("********** weaponmod: continued:- fiveseven, hkp2000, glock, tec9, p250, deagle, elite, m249, negev");
			PrintToServer("********** weaponmod: continued:- xm1014, sawedoff, nova, knifegg, knife");
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- famas, glock");
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- aug, sg556, awp, scar20, g3sg1, ssg08, m4a1, ak47");
			PrintToServer("********** weaponmod: continued:- famas, galilar, bizon, mag7, mac10, mp9, mp7, ump45, p90");
			PrintToServer("********** weaponmod: continued:- fiveseven, hkp2000, glock, tec9, p250, deagle, elite, m249, negev");
			PrintToServer("********** weaponmod: continued:- xm1014, sawedoff, nova, knifegg, knife");
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- aug, sg556, awp, scar20, g3sg1, ssg08, m4a1, ak47");
			PrintToServer("********** weaponmod: continued:- famas, galilar, bizon, mag7, mac10, mp9, mp7, ump45, p90");
			PrintToServer("********** weaponmod: continued:- fiveseven, hkp2000, glock, tec9, p250, deagle, elite, m249, negev");
			PrintToServer("********** weaponmod: continued:- xm1014, sawedoff, nova, knifegg, knife");
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
			PrintToServer("********** weaponmod: valid weapons for this atrribute are:- aug, sg556, awp, scar20, g3sg1, ssg08, m4a1, ak47");
			PrintToServer("********** weaponmod: continued:- famas, galilar, bizon, mag7, mac10, mp9, mp7, ump45, p90");
			PrintToServer("********** weaponmod: continued:- fiveseven, hkp2000, glock, tec9, p250, deagle, elite, m249, negev");
			PrintToServer("********** weaponmod: continued:- xm1014, sawedoff, nova, knifegg, knife");
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
	
	if (WeaponIndex == -1)
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
	if (WeaponIndex != -1)
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
		
		if (WeaponIndex == -1) return;
		
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
				new AmmoReserve;
				new ArrayOffset;
				if (StrEqual("knifegg", WeaponName, false))
				{
					ArrayOffset = AmmoOffset + 44;
				}
				else if (StrEqual("knife", WeaponName, false))
				{
					ArrayOffset = AmmoOffset + 48;
				}
				else if (StrEqual("mag7", WeaponName, false))
				{
					ArrayOffset = AmmoOffset + 52;
				}
				
				AmmoReserve = 2;
				SetEntData(client, ArrayOffset, AmmoReserve);
				ChangeEdictState(client,ArrayOffset);
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
			else if (StrEqual("tec9", WeaponName, false))
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
}

// called just after weapons fire.
public OnPostThinkPost(client)
{
	if (!IsPlayerAlive(client)) return;
	
	new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (WeaponIndex == -1) return;
	
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
		else if (StrEqual("tec9", WeaponName, false))
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
		if (StrEqual("tec9", WeaponName, false))
		{
			if (!GetEntProp(WeaponIndex, Prop_Send, "m_bSilencerOn"))
			{
				SetEntProp(ViewModel, Prop_Send, "m_nSequence", 8);
				return;
			}
		}
		else if (StrEqual("m4a4", WeaponName, false))
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
		
		if (WeaponIndex == -1) return Plugin_Continue;
		
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
	new String:text[15];
	GetCmdArg(1, text, sizeof(text));
 
	if (StrEqual(text, "!weaponmod", false))
	{
		DisplayMenu(WeaponmodMenu, client, MENU_TIME_FOREVER);
		
		return Plugin_Handled;
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
	PrintToChatAll("QuicKill GunGame");
}
