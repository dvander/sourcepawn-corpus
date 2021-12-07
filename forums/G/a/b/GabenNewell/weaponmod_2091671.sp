#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.8-fix"

#define HITGROUP_HEAD 1
#define HITGROUP_CHEST 2
#define HITGROUP_STOMACH 3
#define HITGROUP_LEFTARM 4
#define HITGROUP_RIGHTARM 5
#define HITGROUP_LEFTLEG 6
#define HITGROUP_RIGHTLEG 7

#define DISABLE_EQUIP_NOTIFICATION 1
#define DISABLE_MENU_NOTIFICATION 2

enum WeaponAttributes
{
	Float:RecoilType1,
	Float:RecoilType2,
	Float:FireRate,
	AutoMode,
	Float:GenericDamage,
	Float:HeadDamage,
	Float:TorsoDamage,
	Float:LimbDamage,
	Float:RagdollForce,
	BurstMode,
	InfiniteAmmo,
	QuickSwitch,
	Float:ModeFireRate,
	Float:StandSpread,
	Float:MoveSpread,
	Float:CrouchSpread,
	Float:MiscSpread
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
new Float:CurrentRagdollForce[MAXPLAYERS+1];

new Handle:WeaponTypeTrie;
new Handle:hNotifications;
new Handle:WeaponmodMenu;
new Handle:hEnable;

new Notify;
new IsEnabled;

public Plugin:myinfo =
{
	name = "[CS:GO] Weapon Mod",
	author = "Blodia, GabenNewell",
	description = "Lets you modify certain attributes of weapons.",
	version = "1.8-fix",
	url = ""
}

public OnPluginStart()
{
	WeaponTypeTrie = CreateTrie();
	
	CreateConVar("weaponmod_version", PLUGIN_VERSION, "Weaponmod version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	hNotifications = CreateConVar("weaponmod_disablenotifications", "0", "0 show all notifications, 1 disable weapon equip notifications, 2 disable weapon menu. this cvar is bitwise so you can add values together to remove more than 1 notification", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 3.0);
	hEnable = CreateConVar("weaponmod_enable", "1", "1 enables plugin, 0 disables plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	
	HookConVarChange(hNotifications, ConVarChange);
	HookConVarChange(hEnable, ConVarChange);
	
	Notify = GetConVarInt(hNotifications);
	IsEnabled = GetConVarInt(hEnable);
	
	RegServerCmd("weaponmod", ModAttribute, "modify a weapons attribute usage:weaponmod <weapon> <attribute> <value>");
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team"); 
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	WeaponmodMenu = CreateMenu(WeaponmodMenuHandler);
	SetMenuTitle(WeaponmodMenu, "Weapon Mod Settings:");
	AddMenuItem(WeaponmodMenu, "m4a1_silencer", "M4A1-S");
	AddMenuItem(WeaponmodMenu, "m4a1", "M4A4");
	AddMenuItem(WeaponmodMenu, "ak47", "AK-47");
	AddMenuItem(WeaponmodMenu, "awp", "AWP");
	AddMenuItem(WeaponmodMenu, "ssg08", "SSG 08");
	AddMenuItem(WeaponmodMenu, "scar20", "SCAR-20");
	AddMenuItem(WeaponmodMenu, "g3sg1", "G3SG1");
	AddMenuItem(WeaponmodMenu, "famas", "Famas");
	AddMenuItem(WeaponmodMenu, "galilar", "Galil AR");
	AddMenuItem(WeaponmodMenu, "aug", "AUG");
	AddMenuItem(WeaponmodMenu, "sg556", "SG 556");
	AddMenuItem(WeaponmodMenu, "mac10", "MAC-10");
	AddMenuItem(WeaponmodMenu, "mp9", "MP9");
	AddMenuItem(WeaponmodMenu, "mp7", "MP7");
	AddMenuItem(WeaponmodMenu, "ump45", "UMP-45");
	AddMenuItem(WeaponmodMenu, "p90", "P90");	
	AddMenuItem(WeaponmodMenu, "bizon", "PP-Bizon");
	AddMenuItem(WeaponmodMenu, "nova", "Nova");
	AddMenuItem(WeaponmodMenu, "xm1014", "XM1014");
	AddMenuItem(WeaponmodMenu, "mag7", "MAG-7");
	AddMenuItem(WeaponmodMenu, "sawedoff", "Sawed-Off");	
	AddMenuItem(WeaponmodMenu, "m249", "M249");
	AddMenuItem(WeaponmodMenu, "negev", "Negev");
	AddMenuItem(WeaponmodMenu, "usp_silencer", "USP-S");
	AddMenuItem(WeaponmodMenu, "hkp2000", "P2000");
	AddMenuItem(WeaponmodMenu, "glock", "Glock-18");
	AddMenuItem(WeaponmodMenu, "elite", "Dual Berettas");
	AddMenuItem(WeaponmodMenu, "p250", "P250");
	AddMenuItem(WeaponmodMenu, "deagle", "Desert Eagle");
	AddMenuItem(WeaponmodMenu, "fiveseven", "Five-Seven");
	AddMenuItem(WeaponmodMenu, "tec9", "Tec-9");
	AddMenuItem(WeaponmodMenu, "hegrenade", "HE Grenade");
	AddMenuItem(WeaponmodMenu, "flashbang", "Flashbang");
	AddMenuItem(WeaponmodMenu, "smokegrenade", "Smoke Grenade");
	AddMenuItem(WeaponmodMenu, "molotov", "Molotov");
	AddMenuItem(WeaponmodMenu, "decoy", "Decoy");
	AddMenuItem(WeaponmodMenu, "knife", "Knife");
	AddMenuItem(WeaponmodMenu, "knifestab", "Knife Stab");
	AddMenuItem(WeaponmodMenu, "knifebackstab", "Knife Backstab");
	AddMenuItem(WeaponmodMenu, "taser", "Zeus x27");
	AddMenuItem(WeaponmodMenu, "c4", "C4");
	
	new M4a1sInfo[WeaponAttributes];
	M4a1sInfo[RecoilType1] = 1.0;
	M4a1sInfo[RecoilType2] = -5.0;
	M4a1sInfo[FireRate] = -1.0;
	M4a1sInfo[AutoMode] = -5;
	M4a1sInfo[GenericDamage] = -5.0;
	M4a1sInfo[HeadDamage] = 1.0;
	M4a1sInfo[TorsoDamage] = 1.0;
	M4a1sInfo[LimbDamage] = 1.0;
	M4a1sInfo[RagdollForce] = 5.0;
	M4a1sInfo[BurstMode] = -5;
	M4a1sInfo[InfiniteAmmo] = 0;
	M4a1sInfo[QuickSwitch] = 0;
	M4a1sInfo[ModeFireRate] = -5.0;
	M4a1sInfo[StandSpread] = -1.0;
	M4a1sInfo[MoveSpread] = -1.0;
	M4a1sInfo[CrouchSpread] = -1.0;
	M4a1sInfo[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "m4a1_silencer", M4a1sInfo[0], 17);
	
	new M4a1Info[WeaponAttributes];
	M4a1Info[RecoilType1] = 1.0;
	M4a1Info[RecoilType2] = -5.0;
	M4a1Info[FireRate] = -1.0;
	M4a1Info[AutoMode] = -5;
	M4a1Info[GenericDamage] = -5.0;
	M4a1Info[HeadDamage] = 1.0;
	M4a1Info[TorsoDamage] = 1.0;
	M4a1Info[LimbDamage] = 1.0;
	M4a1Info[RagdollForce] = 5.0;
	M4a1Info[BurstMode] = -5;
	M4a1Info[InfiniteAmmo] = 0;
	M4a1Info[QuickSwitch] = 0;
	M4a1Info[ModeFireRate] = -5.0;
	M4a1Info[StandSpread] = -1.0;
	M4a1Info[MoveSpread] = -1.0;
	M4a1Info[CrouchSpread] = -1.0;
	M4a1Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "m4a1", M4a1Info[0], 17);
	
	new Ak47Info[WeaponAttributes];
	Ak47Info[RecoilType1] = 1.0;
	Ak47Info[RecoilType2] = -5.0;
	Ak47Info[FireRate] = -1.0;
	Ak47Info[AutoMode] = -5;
	Ak47Info[GenericDamage] = -5.0;
	Ak47Info[HeadDamage] = 1.0;
	Ak47Info[TorsoDamage] = 1.0;
	Ak47Info[LimbDamage] = 1.0;
	Ak47Info[RagdollForce] = 5.0;
	Ak47Info[BurstMode] = -5;
	Ak47Info[InfiniteAmmo] = 0;
	Ak47Info[QuickSwitch] = 0;
	Ak47Info[ModeFireRate] = -5.0;
	Ak47Info[StandSpread] = -1.0;
	Ak47Info[MoveSpread] = -1.0;
	Ak47Info[CrouchSpread] = -1.0;
	Ak47Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "ak47", Ak47Info[0], 17);
	
	new AwpInfo[WeaponAttributes];
	AwpInfo[RecoilType1] = -5.0;
	AwpInfo[RecoilType2] = 1.0;
	AwpInfo[FireRate] = -1.0;
	AwpInfo[AutoMode] = -5;
	AwpInfo[GenericDamage] = -5.0;
	AwpInfo[HeadDamage] = 1.0;
	AwpInfo[TorsoDamage] = 1.0;
	AwpInfo[LimbDamage] = 1.0;
	AwpInfo[RagdollForce] = 5.0;
	AwpInfo[BurstMode] = -5;
	AwpInfo[InfiniteAmmo] = 0;
	AwpInfo[QuickSwitch] = 0;
	AwpInfo[ModeFireRate] = -5.0;
	AwpInfo[StandSpread] = -5.0;
	AwpInfo[MoveSpread] = -5.0;
	AwpInfo[CrouchSpread] = -5.0;
	AwpInfo[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "awp", AwpInfo[0], 17);
	
	new Ssg08Info[WeaponAttributes];
	Ssg08Info[RecoilType1] = -5.0;
	Ssg08Info[RecoilType2] = 1.0;
	Ssg08Info[FireRate] = -1.0;
	Ssg08Info[AutoMode] = -5;
	Ssg08Info[GenericDamage] = -1.0;
	Ssg08Info[HeadDamage] = 1.0;
	Ssg08Info[TorsoDamage] = 1.0;
	Ssg08Info[LimbDamage] = 1.0;
	Ssg08Info[RagdollForce] = 5.0;
	Ssg08Info[BurstMode] = -5;
	Ssg08Info[InfiniteAmmo] = 0;
	Ssg08Info[QuickSwitch] = 0;
	Ssg08Info[ModeFireRate] = -5.0;
	Ssg08Info[StandSpread] = -5.0;
	Ssg08Info[MoveSpread] = -5.0;
	Ssg08Info[CrouchSpread] = -5.0;
	Ssg08Info[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "ssg08", Ssg08Info[0], 17);
	
	new Scar20Info[WeaponAttributes];
	Scar20Info[RecoilType1] = -5.0;
	Scar20Info[RecoilType2] = 1.0;
	Scar20Info[FireRate] = -1.0;
	Scar20Info[AutoMode] = -5;
	Scar20Info[GenericDamage] = -5.0;
	Scar20Info[HeadDamage] = 1.0;
	Scar20Info[TorsoDamage] = 1.0;
	Scar20Info[LimbDamage] = 1.0;
	Scar20Info[RagdollForce] = 5.0;
	Scar20Info[BurstMode] = -5;
	Scar20Info[InfiniteAmmo] = 0;
	Scar20Info[QuickSwitch] = 0;
	Scar20Info[ModeFireRate] = -5.0;
	Scar20Info[StandSpread] = -1.0;
	Scar20Info[MoveSpread] = -1.0;
	Scar20Info[CrouchSpread] = -1.0;
	Scar20Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "scar20", Scar20Info[0], 17);
	
	new G3sg1Info[WeaponAttributes];
	G3sg1Info[RecoilType1] = -5.0;
	G3sg1Info[RecoilType2] = 1.0;
	G3sg1Info[FireRate] = -1.0;
	G3sg1Info[AutoMode] = -5;
	G3sg1Info[GenericDamage] = -5.0;
	G3sg1Info[HeadDamage] = 1.0;
	G3sg1Info[TorsoDamage] = 1.0;
	G3sg1Info[LimbDamage] = 1.0;
	G3sg1Info[RagdollForce] = 5.0;
	G3sg1Info[BurstMode] = -5;
	G3sg1Info[InfiniteAmmo] = 0;
	G3sg1Info[QuickSwitch] = 0;
	G3sg1Info[ModeFireRate] = -5.0;
	G3sg1Info[StandSpread] = -1.0;
	G3sg1Info[MoveSpread] = -1.0;
	G3sg1Info[CrouchSpread] = -1.0;
	G3sg1Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "g3sg1", G3sg1Info[0], 17);
	
	new FamasInfo[WeaponAttributes];
	FamasInfo[RecoilType1] = 1.0;
	FamasInfo[RecoilType2] = -5.0;
	FamasInfo[FireRate] = -1.0;
	FamasInfo[AutoMode] = -5;
	FamasInfo[GenericDamage] = -5.0;
	FamasInfo[HeadDamage] = 1.0;
	FamasInfo[TorsoDamage] = 1.0;
	FamasInfo[LimbDamage] = 1.0;
	FamasInfo[RagdollForce] = 5.0;
	FamasInfo[BurstMode] = -5;
	FamasInfo[InfiniteAmmo] = 0;
	FamasInfo[QuickSwitch] = 0;
	FamasInfo[ModeFireRate] = -1.0;
	FamasInfo[StandSpread] = -1.0;
	FamasInfo[MoveSpread] = -1.0;
	FamasInfo[CrouchSpread] = -1.0;
	FamasInfo[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "famas", FamasInfo[0], 17);
	
	new GalilarInfo[WeaponAttributes];
	GalilarInfo[RecoilType1] = 1.0;
	GalilarInfo[RecoilType2] = -5.0;
	GalilarInfo[FireRate] = -1.0;
	GalilarInfo[AutoMode] = -5;
	GalilarInfo[GenericDamage] = -5.0;
	GalilarInfo[HeadDamage] = 1.0;
	GalilarInfo[TorsoDamage] = 1.0;
	GalilarInfo[LimbDamage] = 1.0;
	GalilarInfo[RagdollForce] = 5.0;
	GalilarInfo[BurstMode] = -5;
	GalilarInfo[InfiniteAmmo] = 0;
	GalilarInfo[QuickSwitch] = 0;
	GalilarInfo[ModeFireRate] = -5.0;
	GalilarInfo[StandSpread] = -1.0;
	GalilarInfo[MoveSpread] = -1.0;
	GalilarInfo[CrouchSpread] = -1.0;
	GalilarInfo[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "galilar", GalilarInfo[0], 17);
	
	new AugInfo[WeaponAttributes];
	AugInfo[RecoilType1] = 1.0;
	AugInfo[RecoilType2] = -5.0;
	AugInfo[FireRate] = -1.0;
	AugInfo[AutoMode] = -5;
	AugInfo[GenericDamage] = -5.0;
	AugInfo[HeadDamage] = 1.0;
	AugInfo[TorsoDamage] = 1.0;
	AugInfo[LimbDamage] = 1.0;
	AugInfo[RagdollForce] = 5.0;
	AugInfo[BurstMode] = -5;
	AugInfo[InfiniteAmmo] = 0;
	AugInfo[QuickSwitch] = 0;
	AugInfo[ModeFireRate] = -5.0;
	AugInfo[StandSpread] = -1.0;
	AugInfo[MoveSpread] = -1.0;
	AugInfo[CrouchSpread] = -1.0;
	AugInfo[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "aug", AugInfo[0], 17);
	
	new Sg556Info[WeaponAttributes];
	Sg556Info[RecoilType1] = 1.0;
	Sg556Info[RecoilType2] = -5.0;
	Sg556Info[FireRate] = -1.0;
	Sg556Info[AutoMode] = -5;
	Sg556Info[GenericDamage] = -5.0;
	Sg556Info[HeadDamage] = 1.0;
	Sg556Info[TorsoDamage] = 1.0;
	Sg556Info[LimbDamage] = 1.0;
	Sg556Info[RagdollForce] = 5.0;
	Sg556Info[BurstMode] = -5;
	Sg556Info[InfiniteAmmo] = 0;
	Sg556Info[QuickSwitch] = 0;
	Sg556Info[ModeFireRate] = -5.0;
	Sg556Info[StandSpread] = -1.0;
	Sg556Info[MoveSpread] = -1.0;
	Sg556Info[CrouchSpread] = -1.0;
	Sg556Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "sg556", Sg556Info[0], 17);
	
	new Mac10Info[WeaponAttributes];
	Mac10Info[RecoilType1] = 1.0;
	Mac10Info[RecoilType2] = -5.0;
	Mac10Info[FireRate] = -1.0;
	Mac10Info[AutoMode] = -5;
	Mac10Info[GenericDamage] = -5.0;
	Mac10Info[HeadDamage] = 1.0;
	Mac10Info[TorsoDamage] = 1.0;
	Mac10Info[LimbDamage] = 1.0;
	Mac10Info[RagdollForce] = 5.0;
	Mac10Info[BurstMode] = 0;
	Mac10Info[InfiniteAmmo] = 0;
	Mac10Info[QuickSwitch] = 0;
	Mac10Info[ModeFireRate] = -1.0;
	Mac10Info[StandSpread] = -1.0;
	Mac10Info[MoveSpread] = -1.0;
	Mac10Info[CrouchSpread] = -1.0;
	Mac10Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "mac10", Mac10Info[0], 17);
	
	new Mp9Info[WeaponAttributes];
	Mp9Info[RecoilType1] = 1.0;
	Mp9Info[RecoilType2] = -5.0;
	Mp9Info[FireRate] = -1.0;
	Mp9Info[AutoMode] = -5;
	Mp9Info[GenericDamage] = -5.0;
	Mp9Info[HeadDamage] = 1.0;
	Mp9Info[TorsoDamage] = 1.0;
	Mp9Info[LimbDamage] = 1.0;
	Mp9Info[RagdollForce] = 5.0;
	Mp9Info[BurstMode] = 0;
	Mp9Info[InfiniteAmmo] = 0;
	Mp9Info[QuickSwitch] = 0;
	Mp9Info[ModeFireRate] = -1.0;
	Mp9Info[StandSpread] = -1.0;
	Mp9Info[MoveSpread] = -1.0;
	Mp9Info[CrouchSpread] = -1.0;
	Mp9Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "mp9", Mp9Info[0], 17);
	
	new Mp7Info[WeaponAttributes];
	Mp7Info[RecoilType1] = 1.0;
	Mp7Info[RecoilType2] = -5.0;
	Mp7Info[FireRate] = -1.0;
	Mp7Info[AutoMode] = -5;
	Mp7Info[GenericDamage] = -5.0;
	Mp7Info[HeadDamage] = 1.0;
	Mp7Info[TorsoDamage] = 1.0;
	Mp7Info[LimbDamage] = 1.0;
	Mp7Info[RagdollForce] = 5.0;
	Mp7Info[BurstMode] = 0;
	Mp7Info[InfiniteAmmo] = 0;
	Mp7Info[QuickSwitch] = 0;
	Mp7Info[ModeFireRate] = -1.0;
	Mp7Info[StandSpread] = -1.0;
	Mp7Info[MoveSpread] = -1.0;
	Mp7Info[CrouchSpread] = -1.0;
	Mp7Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "mp7", Mp7Info[0], 17);
	
	new Ump45Info[WeaponAttributes];
	Ump45Info[RecoilType1] = 1.0;
	Ump45Info[RecoilType2] = -5.0;
	Ump45Info[FireRate] = -1.0;
	Ump45Info[AutoMode] = -5;
	Ump45Info[GenericDamage] = -5.0;
	Ump45Info[HeadDamage] = 1.0;
	Ump45Info[TorsoDamage] = 1.0;
	Ump45Info[LimbDamage] = 1.0;
	Ump45Info[RagdollForce] = 5.0;
	Ump45Info[BurstMode] = 0;
	Ump45Info[InfiniteAmmo] = 0;
	Ump45Info[QuickSwitch] = 0;
	Ump45Info[ModeFireRate] = -1.0;
	Ump45Info[StandSpread] = -1.0;
	Ump45Info[MoveSpread] = -1.0;
	Ump45Info[CrouchSpread] = -1.0;
	Ump45Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "ump45", Ump45Info[0], 17);
	
	new P90Info[WeaponAttributes];
	P90Info[RecoilType1] = 1.0;
	P90Info[RecoilType2] = -5.0;
	P90Info[FireRate] = -1.0;
	P90Info[AutoMode] = -5;
	P90Info[GenericDamage] = -5.0;
	P90Info[HeadDamage] = 1.0;
	P90Info[TorsoDamage] = 1.0;
	P90Info[LimbDamage] = 1.0;
	P90Info[RagdollForce] = 5.0;
	P90Info[BurstMode] = 0;
	P90Info[InfiniteAmmo] = 0;
	P90Info[QuickSwitch] = 0;
	P90Info[ModeFireRate] = -1.0;
	P90Info[StandSpread] = -1.0;
	P90Info[MoveSpread] = -1.0;
	P90Info[CrouchSpread] = -1.0;
	P90Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "p90", P90Info[0], 17);
	
	new BizonInfo[WeaponAttributes];
	BizonInfo[RecoilType1] = 1.0;
	BizonInfo[RecoilType2] = -5.0;
	BizonInfo[FireRate] = -1.0;
	BizonInfo[AutoMode] = -5;
	BizonInfo[GenericDamage] = -5.0;
	BizonInfo[HeadDamage] = 1.0;
	BizonInfo[TorsoDamage] = 1.0;
	BizonInfo[LimbDamage] = 1.0;
	BizonInfo[RagdollForce] = 5.0;
	BizonInfo[BurstMode] = 0;
	BizonInfo[InfiniteAmmo] = 0;
	BizonInfo[QuickSwitch] = 0;
	BizonInfo[ModeFireRate] = -1.0;
	BizonInfo[StandSpread] = -1.0;
	BizonInfo[MoveSpread] = -1.0;
	BizonInfo[CrouchSpread] = -1.0;
	BizonInfo[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "bizon", BizonInfo[0], 17);
	
	new NovaInfo[WeaponAttributes];
	NovaInfo[RecoilType1] = -5.0;
	NovaInfo[RecoilType2] = 1.0;
	NovaInfo[FireRate] = -1.0;
	NovaInfo[AutoMode] = -5;
	NovaInfo[GenericDamage] = -5.0;
	NovaInfo[HeadDamage] = 1.0;
	NovaInfo[TorsoDamage] = 1.0;
	NovaInfo[LimbDamage] = 1.0;
	NovaInfo[RagdollForce] = 5.0;
	NovaInfo[BurstMode] = -5;
	NovaInfo[InfiniteAmmo] = 0;
	NovaInfo[QuickSwitch] = 0;
	NovaInfo[ModeFireRate] = -5.0;
	NovaInfo[StandSpread] = -5.0;
	NovaInfo[MoveSpread] = -5.0;
	NovaInfo[CrouchSpread] = -5.0;
	NovaInfo[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "nova", NovaInfo[0], 17);
	
	new Xm1014Info[WeaponAttributes];
	Xm1014Info[RecoilType1] = -5.0;
	Xm1014Info[RecoilType2] = 1.0;
	Xm1014Info[FireRate] = -1.0;
	Xm1014Info[AutoMode] = -5;
	Xm1014Info[GenericDamage] = -5.0;
	Xm1014Info[HeadDamage] = 1.0;
	Xm1014Info[TorsoDamage] = 1.0;
	Xm1014Info[LimbDamage] = 1.0;
	Xm1014Info[RagdollForce] = 5.0;
	Xm1014Info[BurstMode] = -5;
	Xm1014Info[InfiniteAmmo] = 0;
	Xm1014Info[QuickSwitch] = 0;
	Xm1014Info[ModeFireRate] = -5.0;
	Xm1014Info[StandSpread] = -5.0;
	Xm1014Info[MoveSpread] = -5.0;
	Xm1014Info[CrouchSpread] = -5.0;
	Xm1014Info[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "xm1014", Xm1014Info[0], 17);
	
	new Mag7Info[WeaponAttributes];
	Mag7Info[RecoilType1] = -5.0;
	Mag7Info[RecoilType2] = 1.0;
	Mag7Info[FireRate] = -1.0;
	Mag7Info[AutoMode] = -5;
	Mag7Info[GenericDamage] = -5.0;
	Mag7Info[HeadDamage] = 1.0;
	Mag7Info[TorsoDamage] = 1.0;
	Mag7Info[LimbDamage] = 1.0;
	Mag7Info[RagdollForce] = 5.0;
	Mag7Info[BurstMode] = -5;
	Mag7Info[InfiniteAmmo] = 0;
	Mag7Info[QuickSwitch] = 0;
	Mag7Info[ModeFireRate] = -5.0;
	Mag7Info[StandSpread] = -5.0;
	Mag7Info[MoveSpread] = -5.0;
	Mag7Info[CrouchSpread] = -5.0;
	Mag7Info[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "mag7", Mag7Info[0], 17);
	
	new SawedoffInfo[WeaponAttributes];
	SawedoffInfo[RecoilType1] = -5.0;
	SawedoffInfo[RecoilType2] = 1.0;
	SawedoffInfo[FireRate] = -1.0;
	SawedoffInfo[AutoMode] = -5;
	SawedoffInfo[GenericDamage] = -5.0;
	SawedoffInfo[HeadDamage] = 1.0;
	SawedoffInfo[TorsoDamage] = 1.0;
	SawedoffInfo[LimbDamage] = 1.0;
	SawedoffInfo[RagdollForce] = 5.0;
	SawedoffInfo[BurstMode] = -5;
	SawedoffInfo[InfiniteAmmo] = 0;
	SawedoffInfo[QuickSwitch] = 0;
	SawedoffInfo[ModeFireRate] = -5.0;
	SawedoffInfo[StandSpread] = -5.0;
	SawedoffInfo[MoveSpread] = -5.0;
	SawedoffInfo[CrouchSpread] = -5.0;
	SawedoffInfo[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "sawedoff", SawedoffInfo[0], 17);
	
	new M249Info[WeaponAttributes];
	M249Info[RecoilType1] = 1.0;
	M249Info[RecoilType2] = -5.0;
	M249Info[FireRate] = -1.0;
	M249Info[AutoMode] = -5;
	M249Info[GenericDamage] = -5.0;
	M249Info[HeadDamage] = 1.0;
	M249Info[TorsoDamage] = 1.0;
	M249Info[LimbDamage] = 1.0;
	M249Info[RagdollForce] = 5.0;
	M249Info[BurstMode] = -5;
	M249Info[InfiniteAmmo] = 0;
	M249Info[QuickSwitch] = 0;
	M249Info[ModeFireRate] = -5.0;
	M249Info[StandSpread] = -1.0;
	M249Info[MoveSpread] = -1.0;
	M249Info[CrouchSpread] = -1.0;
	M249Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "m249", M249Info[0], 17);
	
	new NegevInfo[WeaponAttributes];
	NegevInfo[RecoilType1] = 1.0;
	NegevInfo[RecoilType2] = -5.0;
	NegevInfo[FireRate] = -1.0;
	NegevInfo[AutoMode] = -5;
	NegevInfo[GenericDamage] = -5.0;
	NegevInfo[HeadDamage] = 1.0;
	NegevInfo[TorsoDamage] = 1.0;
	NegevInfo[LimbDamage] = 1.0;
	NegevInfo[RagdollForce] = 5.0;
	NegevInfo[BurstMode] = -5;
	NegevInfo[InfiniteAmmo] = 0;
	NegevInfo[QuickSwitch] = 0;
	NegevInfo[ModeFireRate] = -5.0;
	NegevInfo[StandSpread] = -1.0;
	NegevInfo[MoveSpread] = -1.0;
	NegevInfo[CrouchSpread] = -1.0;
	NegevInfo[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "negev", NegevInfo[0], 17);
	
	new UspsilencerInfo[WeaponAttributes];
	UspsilencerInfo[RecoilType1] = -5.0;
	UspsilencerInfo[RecoilType2] = 1.0;
	UspsilencerInfo[FireRate] = -1.0;
	UspsilencerInfo[AutoMode] = 0;
	UspsilencerInfo[GenericDamage] = -5.0;
	UspsilencerInfo[HeadDamage] = 1.0;
	UspsilencerInfo[TorsoDamage] = 1.0;
	UspsilencerInfo[LimbDamage] = 1.0;
	UspsilencerInfo[RagdollForce] = 5.0;
	UspsilencerInfo[BurstMode] = -5;
	UspsilencerInfo[InfiniteAmmo] = 0;
	UspsilencerInfo[QuickSwitch] = 0;
	UspsilencerInfo[ModeFireRate] = -1.0;
	UspsilencerInfo[StandSpread] = -1.0;
	UspsilencerInfo[MoveSpread] = -1.0;
	UspsilencerInfo[CrouchSpread] = -1.0;
	UspsilencerInfo[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "usp_silencer", UspsilencerInfo[0], 17);
	
	new Hkp2000Info[WeaponAttributes];
	Hkp2000Info[RecoilType1] = -5.0;
	Hkp2000Info[RecoilType2] = 1.0;
	Hkp2000Info[FireRate] = -1.0;
	Hkp2000Info[AutoMode] = 0;
	Hkp2000Info[GenericDamage] = -5.0;
	Hkp2000Info[HeadDamage] = 1.0;
	Hkp2000Info[TorsoDamage] = 1.0;
	Hkp2000Info[LimbDamage] = 1.0;
	Hkp2000Info[RagdollForce] = 5.0;
	Hkp2000Info[BurstMode] = -5;
	Hkp2000Info[InfiniteAmmo] = 0;
	Hkp2000Info[QuickSwitch] = 0;
	Hkp2000Info[ModeFireRate] = -1.0;
	Hkp2000Info[StandSpread] = -1.0;
	Hkp2000Info[MoveSpread] = -1.0;
	Hkp2000Info[CrouchSpread] = -1.0;
	Hkp2000Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "hkp2000", Hkp2000Info[0], 17);
	
	new GlockInfo[WeaponAttributes];
	GlockInfo[RecoilType1] = -5.0;
	GlockInfo[RecoilType2] = 0.0;
	GlockInfo[FireRate] = -1.0;
	GlockInfo[AutoMode] = 0;
	GlockInfo[GenericDamage] = -5.0;
	GlockInfo[HeadDamage] = 1.0;
	GlockInfo[TorsoDamage] = 1.0;
	GlockInfo[LimbDamage] = 1.0;
	GlockInfo[RagdollForce] = 5.0;
	GlockInfo[BurstMode] = -5;
	GlockInfo[InfiniteAmmo] = 0;
	GlockInfo[QuickSwitch] = 0;
	GlockInfo[ModeFireRate] = -1.0;
	GlockInfo[StandSpread] = -1.0;
	GlockInfo[MoveSpread] = -1.0;
	GlockInfo[CrouchSpread] = -1.0;
	GlockInfo[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "glock", GlockInfo[0], 17);
	
	new EliteInfo[WeaponAttributes];
	EliteInfo[RecoilType1] = -5.0;
	EliteInfo[RecoilType2] = 1.0;
	EliteInfo[FireRate] = -1.0;
	EliteInfo[AutoMode] = 0;
	EliteInfo[GenericDamage] = -5.0;
	EliteInfo[HeadDamage] = 1.0;
	EliteInfo[TorsoDamage] = 1.0;
	EliteInfo[LimbDamage] = 1.0;
	EliteInfo[RagdollForce] = 5.0;
	EliteInfo[BurstMode] = -5;
	EliteInfo[InfiniteAmmo] = 0;
	EliteInfo[QuickSwitch] = 0;
	EliteInfo[ModeFireRate] = -1.0;
	EliteInfo[StandSpread] = -1.0;
	EliteInfo[MoveSpread] = -1.0;
	EliteInfo[CrouchSpread] = -1.0;
	EliteInfo[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "elite", EliteInfo[0], 17);
	
	new P250Info[WeaponAttributes];
	P250Info[RecoilType1] = -5.0;
	P250Info[RecoilType2] = 1.0;
	P250Info[FireRate] = -1.0;
	P250Info[AutoMode] = 0;
	P250Info[GenericDamage] = -5.0;
	P250Info[HeadDamage] = 1.0;
	P250Info[TorsoDamage] = 1.0;
	P250Info[LimbDamage] = 1.0;
	P250Info[RagdollForce] = 5.0;
	P250Info[BurstMode] = -5;
	P250Info[InfiniteAmmo] = 0;
	P250Info[QuickSwitch] = 0;
	P250Info[ModeFireRate] = -1.0;
	P250Info[StandSpread] = -1.0;
	P250Info[MoveSpread] = -1.0;
	P250Info[CrouchSpread] = -1.0;
	P250Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "p250", P250Info[0], 17);
	
	new DeagleInfo[WeaponAttributes];
	DeagleInfo[RecoilType1] = -5.0;
	DeagleInfo[RecoilType2] = 1.0;
	DeagleInfo[FireRate] = -1.0;
	DeagleInfo[AutoMode] = 0;
	DeagleInfo[GenericDamage] = -5.0;
	DeagleInfo[HeadDamage] = 1.0;
	DeagleInfo[TorsoDamage] = 1.0;
	DeagleInfo[LimbDamage] = 1.0;
	DeagleInfo[RagdollForce] = 5.0;
	DeagleInfo[BurstMode] = -5;
	DeagleInfo[InfiniteAmmo] = 0;
	DeagleInfo[QuickSwitch] = 0;
	DeagleInfo[ModeFireRate] = -1.0;
	DeagleInfo[StandSpread] = -1.0;
	DeagleInfo[MoveSpread] = -1.0;
	DeagleInfo[CrouchSpread] = -1.0;
	DeagleInfo[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "deagle", DeagleInfo[0], 17);
	
	new FivesevenInfo[WeaponAttributes];
	FivesevenInfo[RecoilType1] = -5.0;
	FivesevenInfo[RecoilType2] = 1.0;
	FivesevenInfo[FireRate] = -1.0;
	FivesevenInfo[AutoMode] = 0;
	FivesevenInfo[GenericDamage] = -5.0;
	FivesevenInfo[HeadDamage] = 1.0;
	FivesevenInfo[TorsoDamage] = 1.0;
	FivesevenInfo[LimbDamage] = 1.0;
	FivesevenInfo[RagdollForce] = 5.0;
	FivesevenInfo[BurstMode] = -5;
	FivesevenInfo[InfiniteAmmo] = 0;
	FivesevenInfo[QuickSwitch] = 0;
	FivesevenInfo[ModeFireRate] = -1.0;
	FivesevenInfo[StandSpread] = -1.0;
	FivesevenInfo[MoveSpread] = -1.0;
	FivesevenInfo[CrouchSpread] = -1.0;
	FivesevenInfo[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "fiveseven", FivesevenInfo[0], 17);
	
	new Tec9Info[WeaponAttributes];
	Tec9Info[RecoilType1] = -5.0;
	Tec9Info[RecoilType2] = 1.0;
	Tec9Info[FireRate] = -1.0;
	Tec9Info[AutoMode] = 0;
	Tec9Info[GenericDamage] = -5.0;
	Tec9Info[HeadDamage] = 1.0;
	Tec9Info[TorsoDamage] = 1.0;
	Tec9Info[LimbDamage] = 1.0;
	Tec9Info[RagdollForce] = 5.0;
	Tec9Info[BurstMode] = -5;
	Tec9Info[InfiniteAmmo] = 0;
	Tec9Info[QuickSwitch] = 0;
	Tec9Info[ModeFireRate] = -1.0;
	Tec9Info[StandSpread] = -1.0;
	Tec9Info[MoveSpread] = -1.0;
	Tec9Info[CrouchSpread] = -1.0;
	Tec9Info[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "tec9", Tec9Info[0], 17);
	
	new HegrenadeInfo[WeaponAttributes];
	HegrenadeInfo[RecoilType1] = -5.0;
	HegrenadeInfo[RecoilType2] = -5.0;
	HegrenadeInfo[FireRate] = -5.0;
	HegrenadeInfo[AutoMode] = -5;
	HegrenadeInfo[GenericDamage] = 1.0;
	HegrenadeInfo[HeadDamage] = -5.0;
	HegrenadeInfo[TorsoDamage] = -5.0;
	HegrenadeInfo[LimbDamage] = -5.0;
	HegrenadeInfo[RagdollForce] = 5.0;
	HegrenadeInfo[BurstMode] = -5;
	HegrenadeInfo[InfiniteAmmo] = 0;
	HegrenadeInfo[QuickSwitch] = 0;
	HegrenadeInfo[ModeFireRate] = -5.0;
	HegrenadeInfo[StandSpread] = -5.0;
	HegrenadeInfo[MoveSpread] = -5.0;
	HegrenadeInfo[CrouchSpread] = -5.0;
	HegrenadeInfo[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "hegrenade", HegrenadeInfo[0], 17);
	
	new FlashbangInfo[WeaponAttributes];
	FlashbangInfo[RecoilType1] = -5.0;
	FlashbangInfo[RecoilType2] = -5.0;
	FlashbangInfo[FireRate] = -5.0;
	FlashbangInfo[AutoMode] = -5;
	FlashbangInfo[GenericDamage] = 1.0;
	FlashbangInfo[HeadDamage] = -5.0;
	FlashbangInfo[TorsoDamage] = -5.0;
	FlashbangInfo[LimbDamage] = -5.0;
	FlashbangInfo[RagdollForce] = 5.0;
	FlashbangInfo[BurstMode] = -5;
	FlashbangInfo[InfiniteAmmo] = 0;
	FlashbangInfo[QuickSwitch] = 0;
	FlashbangInfo[ModeFireRate] = -5.0;
	FlashbangInfo[StandSpread] = -5.0;
	FlashbangInfo[MoveSpread] = -5.0;
	FlashbangInfo[CrouchSpread] = -5.0;
	FlashbangInfo[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "flashbang", FlashbangInfo[0], 17);
	
	new SmokegrenadeInfo[WeaponAttributes];
	SmokegrenadeInfo[RecoilType1] = -5.0;
	SmokegrenadeInfo[RecoilType2] = -5.0;
	SmokegrenadeInfo[FireRate] = -5.0;
	SmokegrenadeInfo[AutoMode] = -5;
	SmokegrenadeInfo[GenericDamage] = 1.0;
	SmokegrenadeInfo[HeadDamage] = -5.0;
	SmokegrenadeInfo[TorsoDamage] = -5.0;
	SmokegrenadeInfo[LimbDamage] = -5.0;
	SmokegrenadeInfo[RagdollForce] = 5.0;
	SmokegrenadeInfo[BurstMode] = -5;
	SmokegrenadeInfo[InfiniteAmmo] = 0;
	SmokegrenadeInfo[QuickSwitch] = 0;
	SmokegrenadeInfo[ModeFireRate] = -5.0;
	SmokegrenadeInfo[StandSpread] = -5.0;
	SmokegrenadeInfo[MoveSpread] = -5.0;
	SmokegrenadeInfo[CrouchSpread] = -5.0;
	SmokegrenadeInfo[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "smokegrenade", SmokegrenadeInfo[0], 17);
	
	new MolotovInfo[WeaponAttributes];
	MolotovInfo[RecoilType1] = -5.0;
	MolotovInfo[RecoilType2] = -5.0;
	MolotovInfo[FireRate] = -5.0;
	MolotovInfo[AutoMode] = -5;
	MolotovInfo[GenericDamage] = 1.0;
	MolotovInfo[HeadDamage] = -5.0;
	MolotovInfo[TorsoDamage] = -5.0;
	MolotovInfo[LimbDamage] = -5.0;
	MolotovInfo[RagdollForce] = 5.0;
	MolotovInfo[BurstMode] = -5;
	MolotovInfo[InfiniteAmmo] = 0;
	MolotovInfo[QuickSwitch] = 0;
	MolotovInfo[ModeFireRate] = -5.0;
	MolotovInfo[StandSpread] = -5.0;
	MolotovInfo[MoveSpread] = -5.0;
	MolotovInfo[CrouchSpread] = -5.0;
	MolotovInfo[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "molotov", MolotovInfo[0], 17);
	
	new DecoyInfo[WeaponAttributes];
	DecoyInfo[RecoilType1] = -5.0;
	DecoyInfo[RecoilType2] = -5.0;
	DecoyInfo[FireRate] = -5.0;
	DecoyInfo[AutoMode] = -5;
	DecoyInfo[GenericDamage] = 1.0;
	DecoyInfo[HeadDamage] = -5.0;
	DecoyInfo[TorsoDamage] = -5.0;
	DecoyInfo[LimbDamage] = -5.0;
	DecoyInfo[RagdollForce] = 5.0;
	DecoyInfo[BurstMode] = -5;
	DecoyInfo[InfiniteAmmo] = 0;
	DecoyInfo[QuickSwitch] = 0;
	DecoyInfo[ModeFireRate] = -5.0;
	DecoyInfo[StandSpread] = -5.0;
	DecoyInfo[MoveSpread] = -5.0;
	DecoyInfo[CrouchSpread] = -5.0;
	DecoyInfo[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "decoy", DecoyInfo[0], 17);
	
	new KnifeInfo[WeaponAttributes];
	KnifeInfo[RecoilType1] = -5.0;
	KnifeInfo[RecoilType2] = -5.0;
	KnifeInfo[FireRate] = -1.0;
	KnifeInfo[AutoMode] = -5;
	KnifeInfo[GenericDamage] = 1.0;
	KnifeInfo[HeadDamage] = -5.0;
	KnifeInfo[TorsoDamage] = -5.0;
	KnifeInfo[LimbDamage] = -5.0;
	KnifeInfo[RagdollForce] = 5.0;
	KnifeInfo[BurstMode] = -5;
	KnifeInfo[InfiniteAmmo] = -5;
	KnifeInfo[QuickSwitch] = 0;
	KnifeInfo[ModeFireRate] = -5.0;
	KnifeInfo[StandSpread] = -5.0;
	KnifeInfo[MoveSpread] = -5.0;
	KnifeInfo[CrouchSpread] = -5.0;
	KnifeInfo[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "knife", KnifeInfo[0], 17);
	
	new KnifestabInfo[WeaponAttributes];
	KnifestabInfo[RecoilType1] = -5.0;
	KnifestabInfo[RecoilType2] = -5.0;
	KnifestabInfo[FireRate] = -1.0;
	KnifestabInfo[AutoMode] = -5;
	KnifestabInfo[GenericDamage] = 1.0;
	KnifestabInfo[HeadDamage] = -5.0;
	KnifestabInfo[TorsoDamage] = -5.0;
	KnifestabInfo[LimbDamage] = -5.0;
	KnifestabInfo[RagdollForce] = 5.0;
	KnifestabInfo[BurstMode] = -5;
	KnifestabInfo[InfiniteAmmo] = -5;
	KnifestabInfo[QuickSwitch] = -5;
	KnifestabInfo[ModeFireRate] = -5.0;
	KnifestabInfo[StandSpread] = -5.0;
	KnifestabInfo[MoveSpread] = -5.0;
	KnifestabInfo[CrouchSpread] = -5.0;
	KnifestabInfo[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "knifestab", KnifestabInfo[0], 17);
	
	new KnifebackstabInfo[WeaponAttributes];
	KnifebackstabInfo[RecoilType1] = -5.0;
	KnifebackstabInfo[RecoilType2] = -5.0;
	KnifebackstabInfo[FireRate] = -5.0;
	KnifebackstabInfo[AutoMode] = -5;
	KnifebackstabInfo[GenericDamage] = 1.0;
	KnifebackstabInfo[HeadDamage] = -5.0;
	KnifebackstabInfo[TorsoDamage] = -5.0;
	KnifebackstabInfo[LimbDamage] = -5.0;
	KnifebackstabInfo[RagdollForce] = 5.0;
	KnifebackstabInfo[BurstMode] = -5;
	KnifebackstabInfo[InfiniteAmmo] = -5;
	KnifebackstabInfo[QuickSwitch] = -5;
	KnifebackstabInfo[ModeFireRate] = -5.0;
	KnifebackstabInfo[StandSpread] = -5.0;
	KnifebackstabInfo[MoveSpread] = -5.0;
	KnifebackstabInfo[CrouchSpread] = -5.0;
	KnifebackstabInfo[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "knifebackstab", KnifebackstabInfo[0], 17);
	
	new TaserInfo[WeaponAttributes];
	TaserInfo[RecoilType1] = -5.0;
	TaserInfo[RecoilType2] = 1.0;
	TaserInfo[FireRate] = -1.0;
	TaserInfo[AutoMode] = 0;
	TaserInfo[GenericDamage] = -5.0;
	TaserInfo[HeadDamage] = 1.0;
	TaserInfo[TorsoDamage] = 1.0;
	TaserInfo[LimbDamage] = 1.0;
	TaserInfo[RagdollForce] = 5.0;
	TaserInfo[BurstMode] = -5;
	TaserInfo[InfiniteAmmo] = 0;
	TaserInfo[QuickSwitch] = 0;
	TaserInfo[ModeFireRate] = -1.0;
	TaserInfo[StandSpread] = -1.0;
	TaserInfo[MoveSpread] = -1.0;
	TaserInfo[CrouchSpread] = -1.0;
	TaserInfo[MiscSpread] = -1.0;
	SetTrieArray(WeaponTypeTrie, "taser", TaserInfo[0], 17);
	
	new C4Info[WeaponAttributes];
	C4Info[RecoilType1] = -5.0;
	C4Info[RecoilType2] = -5.0;
	C4Info[FireRate] = -5.0;
	C4Info[AutoMode] = -5;
	C4Info[GenericDamage] = -5.0;
	C4Info[HeadDamage] = -5.0;
	C4Info[TorsoDamage] = -5.0;
	C4Info[LimbDamage] = -5.0;
	C4Info[RagdollForce] = 5.0;
	C4Info[BurstMode] = -5;
	C4Info[InfiniteAmmo] = -5;
	C4Info[QuickSwitch] = 0;
	C4Info[ModeFireRate] = -5.0;
	C4Info[StandSpread] = -5.0;
	C4Info[MoveSpread] = -5.0;
	C4Info[CrouchSpread] = -5.0;
	C4Info[MiscSpread] = -5.0;
	SetTrieArray(WeaponTypeTrie, "c4", C4Info[0], 17);
	
	for (new client = 1; client <= MaxClients; client++) 
	{ 
        if (IsClientInGame(client))
		{
			if (IsPlayerAlive(client))
			{
				SDKHook(client, SDKHook_PostThink, OnPostThink);
				SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
				SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
				SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
				SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
			}
		}
    }
}

public ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == hNotifications)
	{
		Notify = StringToInt(newVal);
	}
	
	else if (cvar == hEnable)
	{
		IsEnabled = StringToInt(newVal);
		
		if (IsEnabled)
		{
			for (new client = 1; client <= MaxClients; client++) 
			{ 
				if (IsClientInGame(client))
				{
					if (IsPlayerAlive(client))
					{
						SDKHook(client, SDKHook_PostThink, OnPostThink);
						SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
						SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
						SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
						SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
						SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
					}
				}
			}
		}
		else
		{
			for (new client = 1; client <= MaxClients; client++) 
			{ 
				if (IsClientInGame(client))
				{
					SDKUnhook(client, SDKHook_PostThink, OnPostThink);
					SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
					SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
					SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
					SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
					SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
				}
			}
		}
	}
}

public OnPluginEnd()
{
	CloseHandle(WeaponTypeTrie);
	CloseHandle(WeaponmodMenu);
}

public Action:ModAttribute(args)
{
	if (!IsEnabled)
	{
		PrintToServer("********** weaponmod is disabled");
		return Plugin_Handled;
	}
	
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
	if (!GetTrieArray(WeaponTypeTrie, WeaponName, EditWeapon[0], 17))
	{
		PrintToServer("********** weaponmod: weapon doesn't exist");
		PrintToServer("********** weaponmod: valid weapons are:- m4a1_silencer, m4a1, ak47, awp, ssg08, scar20, g3sg1, famas, galilar, aug, sg556,");
		PrintToServer("********** weaponmod: continued:- mac10, mp9, mp7, ump45, p90, bizon, nova, xm1014, mag7, sawedoff, m249, negev,");
		PrintToServer("********** weaponmod: continued:- usp_silencer, hkp2000, glock, elite, p250, deagle, fiveseven, tec9, taser,");
		PrintToServer("********** weaponmod: continued:- hegrenade, flashbang, smokegrenade, molotov, decoy, knife, knifestab, knifebackstab, c4");
		
		return Plugin_Handled;
	}
	
	if (StrEqual("recoil", AttributeName, false))
	{
		if (EditWeapon[RecoilType1] != -5.0)
		{
			CheckAttributeRange(WeaponName, RecoilType1, AttributeValue, true, 0.0, 10.0);
		}
		else if (EditWeapon[RecoilType2] != -5.0)
		{
			CheckAttributeRange(WeaponName, RecoilType2, AttributeValue, true, 0.0, 10.0);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("firerate", AttributeName, false))
	{
		if (EditWeapon[FireRate] != -5.0)
		{
			CheckAttributeRange(WeaponName, FireRate, AttributeValue, true, 0.0, 10.0);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("automode", AttributeName, false))
	{
		if (EditWeapon[AutoMode] != -5)
		{
			CheckAttributeRange(WeaponName, AutoMode, AttributeValue, false);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("genericdamage", AttributeName, false))
	{
		if (EditWeapon[GenericDamage] != -5.0)
		{
			CheckAttributeRange(WeaponName, GenericDamage, AttributeValue, true, 0.0, 1000.0);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("headdamage", AttributeName, false))
	{
		if (EditWeapon[HeadDamage] != -5.0)
		{
			CheckAttributeRange(WeaponName, HeadDamage, AttributeValue, true, 0.0, 1000.0);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("torsodamage", AttributeName, false))
	{
		if (EditWeapon[TorsoDamage] != -5.0)
		{
			CheckAttributeRange(WeaponName, TorsoDamage, AttributeValue, true, 0.0, 1000.0);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("limbdamage", AttributeName, false))
	{
		if (EditWeapon[LimbDamage] != -5.0)
		{
			CheckAttributeRange(WeaponName, LimbDamage, AttributeValue, true, 0.0, 1000.0);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("ragdollforce", AttributeName, false))
	{
		if (EditWeapon[RagdollForce] != -5.0)
		{
			CheckAttributeRange(WeaponName, RagdollForce, AttributeValue, true, 5.0, 10000.0);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("burstmode", AttributeName, false))
	{
		if (EditWeapon[BurstMode] != -5)
		{
			CheckAttributeRange(WeaponName, BurstMode, AttributeValue, false);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("infiniteammo", AttributeName, false))
	{
		if (EditWeapon[InfiniteAmmo] != -5)
		{
			CheckAttributeRange(WeaponName, InfiniteAmmo, AttributeValue, false);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("quickswitch", AttributeName, false))
	{
		if (EditWeapon[QuickSwitch] != -5)
		{
			CheckAttributeRange(WeaponName, QuickSwitch, AttributeValue, false);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("modefirerate", AttributeName, false))
	{
		if (EditWeapon[ModeFireRate] != -5.0)
		{
			CheckAttributeRange(WeaponName, ModeFireRate, AttributeValue, true, 0.0, 10.0);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("standspread", AttributeName, false))
	{
		if (EditWeapon[StandSpread] != -5.0)
		{
			CheckAttributeRange(WeaponName, StandSpread, AttributeValue, true, 0.0, 1.0);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("movespread", AttributeName, false))
	{
		if (EditWeapon[MoveSpread] != -5.0)
		{
			CheckAttributeRange(WeaponName, MoveSpread, AttributeValue, true, 0.0, 1.0);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("crouchspread", AttributeName, false))
	{
		if (EditWeapon[CrouchSpread] != -5.0)
		{
			CheckAttributeRange(WeaponName, CrouchSpread, AttributeValue, true, 0.0, 1.0);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else if (StrEqual("miscspread", AttributeName, false))
	{
		if (EditWeapon[MiscSpread] != -5.0)
		{
			CheckAttributeRange(WeaponName, MiscSpread, AttributeValue, true, 0.0, 1.0);
		}
		else
		{
			PrintToServer("********** weaponmod: invalid attribute for this weapon");
		}
	}
	
	else
	{
		PrintToServer("********** weaponmod: attribute doesn't exist");
		PrintToServer("********** weaponmod: valid atrributes are:- recoil, firerate, automode, genericdamage");
		PrintToServer("********** weaponmod: continued:- headdamage, torsodamage, limbdamage, burstmode");
		PrintToServer("********** weaponmod: continued:- infiniteammo, quickswitch, modefirerate, ragdollforce");
		PrintToServer("********** weaponmod: continued:- standspread, movespread, crouchspread, miscspread");
	}
	
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	static OldButtons[MAXPLAYERS + 1];
	
	if (!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	if (!IsEnabled)
	{
		return Plugin_Continue;
	}
	
	new ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	// make sure the active weapon exists.
	if (!IsValidEdict(ActiveWeapon) || (ActiveWeapon == -1))
	{
		return Plugin_Continue;
	}
	
	// if the classname without the weapon_ prefix doesn't exist in the trie then this most likely isn't a weapon.
	decl String:WeaponName[30];
	GetEdictClassname(ActiveWeapon, WeaponName, sizeof(WeaponName));
	ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
	
	new GetWeaponInfo[WeaponAttributes];
	if (!GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 17))
	{
		return Plugin_Continue;
	}
	
	// if the player fired while in burst mode and has ammo then force them to attack until they fire 3 shots.
	if ((GetWeaponInfo[BurstMode] == 1) && (BurstShotsFired[client]) && (ModeStateArray[client][SmgBurst]))
	{
		if (GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1"))
		{
			buttons |= IN_ATTACK;
		}
		else
		{
			BurstShotsFired[client] = 0;
		}
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

// called just before weapons fire.
public OnPostThink(client)
{
	new Buttons = GetClientButtons(client);
	
	new Float:GameTime = GetGameTime();
	
	if (Buttons & IN_ATTACK)
	{
		new ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (!IsValidEdict(ActiveWeapon) || (ActiveWeapon == -1))
		{
			return;
		}
		
		decl String:WeaponName[30];
		GetEdictClassname(ActiveWeapon, WeaponName, sizeof(WeaponName));
		ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
		
		new GetWeaponInfo[WeaponAttributes];
		if (!GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 17))
		{
			return;
		}
		
		// weapon can't fire yet.
		if (GameTime < GetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack"))
		{
			return;
		}
		
		//player can't attack yet.
		if (GameTime < GetEntPropFloat(client, Prop_Send, "m_flNextAttack"))
		{
			return;
		}
		
		// no ammo in clip.
		new ClipAmmo = GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1");
		if (!ClipAmmo)
		{
			return;
		}
		
		// if the weapon is a pistol in semi-automatic mode then ignore it.
		if ((GetWeaponInfo[AutoMode] != -5) && (GetEntProp(client, Prop_Send, "m_iShotsFired")))
		{
			return;
		}
		
		if (GetWeaponInfo[InfiniteAmmo] == 1)
		{
			// set ammo clip to 5 if it has one everytime the weapon is about to fire.
			if (ClipAmmo != -1)
			{
				SetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", 5);
			}
			// projectiles don't have an ammo clip
			else
			{
				if (StrEqual("hegrenade", WeaponName, false))
				{
					SetEntProp(client, Prop_Send, "m_iAmmo", 2, 4, 11);
				}
				else if (StrEqual("flashbang", WeaponName, false))
				{
					SetEntProp(client, Prop_Send, "m_iAmmo", 2, 4, 12);
				}
				else if (StrEqual("smokegrenade", WeaponName, false))
				{
					SetEntProp(client, Prop_Send, "m_iAmmo", 2, 4, 13);
				}
				else if (StrEqual("molotov", WeaponName, false))
				{
					SetEntProp(client, Prop_Send, "m_iAmmo", 2, 4, 14);
				}
				else if (StrEqual("decoy", WeaponName, false))
				{
					SetEntProp(client, Prop_Send, "m_iAmmo", 2, 4, 15);
				}
			}
		}
		
		new Float:Spread;
		
		new Float:Vel[3];
		GetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", Vel);
		// inaccuracy in air/in water/on ladder
		if (!(GetEntityFlags(client) & FL_ONGROUND) || (GetEntityMoveType(client) == MOVETYPE_LADDER))
		{
			Spread = GetWeaponInfo[MiscSpread];
		}
		// inaccuracy crouching
		else if (GetEntityFlags(client) & FL_DUCKING)
		{
			Spread = GetWeaponInfo[CrouchSpread];
		}
		// inaccuracy running/walking
		else if ((GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]") != 0.0) || (GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]") != 0.0))
		{
			Spread = GetWeaponInfo[MoveSpread];
		}
		// inaccuracy standing still/the rest
		else
		{
			Spread = GetWeaponInfo[StandSpread];
		}
		
		if (Spread >= 0.0)
		{
			SetEntPropFloat(ActiveWeapon, Prop_Send, "m_fAccuracyPenalty", Spread);
		}
		
		if (GetWeaponInfo[BurstMode] == 1)
		{
			if (ModeStateArray[client][SmgBurst])
			{
				ProcessArray[client][ProcessAltMode] = 2;
				
				return;
			}
		}
		else if ((GetWeaponInfo[BurstMode] != 1) && (ModeStateArray[client][SmgBurst]))
		{
			ModeStateArray[client][SmgBurst] = false;
		}
		
		if ((GetWeaponInfo[RecoilType1] >= 0.0) && (GetWeaponInfo[RecoilType1] != 1.0))
		{
			ProcessArray[client][ProcessRecoil] = 2;
		}
		else if (GetWeaponInfo[RecoilType2] >= 0.0)
		{
			// store current recoil.
			
			// Error: m_vecPunchAngle not found.
			//GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", PreviousPunchAngle[client]);
			
			if ((StrEqual("glock", WeaponName, false)) && (GetWeaponInfo[RecoilType2] != 0.0))
			{
				ProcessArray[client][ProcessRecoil] = 1;
			}
			else if (GetWeaponInfo[RecoilType2] != 1.0)
			{
				ProcessArray[client][ProcessRecoil] = 2;
			}
		}
		
		if (GetWeaponInfo[AutoMode] == 1)
		{
			// make sure automatic mode ovverrides default alt modes.
			/* "m_flNextSecondaryAttack" is when the player can use the alt mode again.
			setting it high blocks it with out prediction issues caused by hooking the key press instead. */
			if (StrEqual("glock", WeaponName, false))
			{
				SetEntProp(ActiveWeapon, Prop_Send, "m_bBurstMode", 0);
				SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", (GetGameTime() + 999999.0));
			}
			else if (StrEqual("usp_silencer", WeaponName, false))
			{
				SetEntProp(ActiveWeapon, Prop_Send, "m_bSilencerOn", 0);
				SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", (GetGameTime() + 999999.0));
			}
			
			if (ModeStateArray[client][PistolAuto])
			{
				ProcessArray[client][ProcessAltMode] = 1;
				
				return;
			}
		}
		else if ((GetWeaponInfo[AutoMode] != 1) && (ModeStateArray[client][PistolAuto]))
		{
			ModeStateArray[client][PistolAuto] = false;
		}
		
		if (GetWeaponInfo[FireRate] >= 0.0)
		{
			ProcessArray[client][ProcessFireRate] = 1;
		}
		
		if ((StrEqual("glock", WeaponName, false)) || (StrEqual("famas", WeaponName, false)))
		{
			if ((GetEntProp(ActiveWeapon, Prop_Send, "m_bBurstMode")) && (GetWeaponInfo[ModeFireRate] >= 0.0))
			{
				ProcessArray[client][ProcessFireRate] = 3;
			}
		}
	}
	
	// this is for knife stab.
	else if (Buttons & IN_ATTACK2)
	{
		new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		decl String:WeaponName[30];
		if (WeaponIndex != -1)
		{
			GetEdictClassname(WeaponIndex, WeaponName, sizeof(WeaponName));
			ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
		}
		else
		{
			strcopy(WeaponName, sizeof(WeaponName), "none");
		}
		
		if (StrEqual("knife", WeaponName, false))
		{
			// knife can't attack yet.
			if (GameTime < GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack"))
			{
				return;
			}
			
			// player can't attack yet.
			if (GameTime < GetEntPropFloat(client, Prop_Send, "m_flNextAttack"))
			{
				return;
			}
			
			new GetWeaponInfo[WeaponAttributes];
			GetTrieArray(WeaponTypeTrie, "knifestab", GetWeaponInfo[0], 17);
			
			if (GetWeaponInfo[FireRate] >= 0.0)
			{
				ProcessArray[client][ProcessFireRate] = 2;
			}
		}
		
	}
}

// called just after weapons fire.
public OnPostThinkPost(client)
{
	new ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (!IsValidEdict(ActiveWeapon) || (ActiveWeapon == -1))
	{
		return;
	}
	
	decl String:WeaponName[30];
	GetEdictClassname(ActiveWeapon, WeaponName, sizeof(WeaponName));
	ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
	
	new GetWeaponInfo[WeaponAttributes];
	if (!GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 17))
	{
		return;
	}
	
	new Float:GameTime = GetGameTime();
	
	if (ProcessArray[client][ProcessFireRate] == 1)
	{
		ProcessArray[client][ProcessFireRate] = 0;
		
		// "m_flNextPrimaryAttack" is when the weapon can next attack relative to GetGameTime,
		new Float:NextAttackTime = GetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack");
		NextAttackTime = GameTime + GetWeaponInfo[FireRate];
		SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", NextAttackTime);
	}
	// adjust knife stab fire rate, same as above but uses "m_flNextSecondaryAttack" instead.
	else if (ProcessArray[client][ProcessFireRate] == 2)
	{
		ProcessArray[client][ProcessFireRate] = 0;
		
		new GetKnifeInfo[WeaponAttributes];
		GetTrieArray(WeaponTypeTrie, "knifestab", GetKnifeInfo[0], 17);
		
		new Float:NextAttackTime = GetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextSecondaryAttack");
		NextAttackTime = GameTime + GetKnifeInfo[FireRate];
		SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", NextAttackTime);
	}
	else if (ProcessArray[client][ProcessFireRate] == 3)
	{
		ProcessArray[client][ProcessFireRate] = 0;
		
		new Float:NextAttackTime = GetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack");
		NextAttackTime = GameTime + GetWeaponInfo[ModeFireRate];
		SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", NextAttackTime);
	}
	
	/* "m_iShotsFired" is used to make pistols fire semi-automatic when the attack button is held.
	if it is 1 the pistol will not fire again until the attack key is released then pressed again which will reset it.
	it is also used to calculate recoil on fully automatic weapons. */
	if (ProcessArray[client][ProcessAltMode] == 1) // pistol auto
	{
		ProcessArray[client][ProcessAltMode] = 0;
		
		SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
		
		if (GetWeaponInfo[ModeFireRate] >= 0.0)
		{
			new Float:NextAttackTime = GetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack");
			NextAttackTime = GameTime + GetWeaponInfo[ModeFireRate];
			SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", NextAttackTime);
		}
	}
	else if (ProcessArray[client][ProcessAltMode] == 2) // smg burst
	{
		ProcessArray[client][ProcessAltMode] = 0;
		
		// on the last shot of a burstfire add a delay.
		if (++BurstShotsFired[client] == 3)
		{
			if (GetWeaponInfo[ModeFireRate] >= 0.0)
			{
				new Float:NextAttackTime = GetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack");
				NextAttackTime = GameTime + GetWeaponInfo[ModeFireRate];
				SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", NextAttackTime);
			}
			
			BurstShotsFired[client] = 0;
		}
		else
		{
			// remove any recoil.from first 2 shots.
			SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
			new Float:NoRecoil[3];
			SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", NoRecoil);
			
			new Float:NextAttackTime = GetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack");
			
			NextAttackTime = GameTime + 0.1;
			
			SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", NextAttackTime);
		}
	}
	
	if (ProcessArray[client][ProcessRecoil] == 1) // glock recoil
	{
		ProcessArray[client][ProcessRecoil] = 0;
		
		decl Float:CurrentPunchAngle[3];
		GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", CurrentPunchAngle);
		
		CurrentPunchAngle[0] -= (2.0 * GetWeaponInfo[RecoilType2]);
		
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", CurrentPunchAngle);
	}
	// recoil is calculated in 2 ways depending on the weapon.
	else if (ProcessArray[client][ProcessRecoil] == 2)
	{
		ProcessArray[client][ProcessRecoil] = 0;
		
		// get new recoil and compare it with the old one in the 2nd recoil method.
		decl Float:CurrentPunchAngle[3];
		
		// Error: m_vecPunchAngle not found.
		//GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", CurrentPunchAngle);
		
		if (GetWeaponInfo[RecoilType1] >= 0.0)
		{
			if (GetWeaponInfo[RecoilType1] != 0.0)
			{
				CurrentPunchAngle[0] *= GetWeaponInfo[RecoilType1];
			}
			else
			{
				// remove any recoil.
				SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
				CurrentPunchAngle[0] = 0.0;
				CurrentPunchAngle[1] = 0.0;
			}
		}
		else if (GetWeaponInfo[RecoilType2] >= 0.0)
		{
			if (GetWeaponInfo[RecoilType2] != 0.0)
			{
				CurrentPunchAngle[0] -= PreviousPunchAngle[client][0];
				CurrentPunchAngle[0] *= GetWeaponInfo[RecoilType2];
				CurrentPunchAngle[0] += PreviousPunchAngle[client][0];
			}
			// remove any recoil.
			else
			{
				CurrentPunchAngle[0] = 0.0;
				CurrentPunchAngle[1] = 0.0;
			}
		}
		
		// cap recoil so the players view doesn't turn upside down.
		if (CurrentPunchAngle[0] < -90.0)
		{
			CurrentPunchAngle[0] = -90.0;
		}
		
		// Error: m_vecPunchAngle not found.
		//SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", CurrentPunchAngle);
	}
	
	/* "m_flNextSecondaryAttack" is when the player can use the alt mode again.
	setting it high blocks it with out prediction issues caused by hooking the key press instead. */
	if (GetWeaponInfo[AutoMode]== 1)
	{
		if (StrEqual("glock", WeaponName, false))
		{
			SetEntProp(ActiveWeapon, Prop_Send, "m_bBurstMode", 0);
			SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", (GameTime + 999999.0));
		}
		else if (StrEqual("usp_silencer", WeaponName, false))
		{
			SetEntProp(ActiveWeapon, Prop_Send, "m_bSilencerOn", 0);
			SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", (GameTime + 999999.0));
		}
	}
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if ((attacker > 0) && (attacker <= MaxClients) && (attacker == inflictor))
	{
		new WeaponIndex = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		if (WeaponIndex == -1)
		{
			return Plugin_Continue;
		}
		
		decl String:WeaponName[30];
		GetEdictClassname(WeaponIndex, WeaponName, sizeof(WeaponName));
		ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
		
		new GetWeaponInfo[WeaponAttributes];
		GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 17);
		
		CurrentRagdollForce[victim] = GetWeaponInfo[RagdollForce];
		
		if ((GetWeaponInfo[HeadDamage] != 1.0) && (GetWeaponInfo[HeadDamage] >= 0.0) && (hitgroup == HITGROUP_HEAD))
		{
			if (GetWeaponInfo[HeadDamage] == 0.0)
			{
				return Plugin_Handled;
			}
			else
			{
				damage *= GetWeaponInfo[HeadDamage];
				
				return Plugin_Changed;
			}
		}
		else if ((GetWeaponInfo[TorsoDamage] != 1.0) && (GetWeaponInfo[TorsoDamage] >= 0.0) && ((hitgroup == HITGROUP_STOMACH) || (hitgroup == HITGROUP_CHEST)))
		{
			if (GetWeaponInfo[TorsoDamage] == 0.0)
			{
				return Plugin_Handled;
			}
			else
			{
				damage *= GetWeaponInfo[TorsoDamage];
				
				return Plugin_Changed;
			}
		}
		else if ((GetWeaponInfo[LimbDamage] != 1.0) && (GetWeaponInfo[LimbDamage] >= 0.0) && ((hitgroup == HITGROUP_LEFTARM) || (hitgroup == HITGROUP_RIGHTARM) || (hitgroup == HITGROUP_LEFTLEG) || (hitgroup == HITGROUP_RIGHTLEG)))
		{
			if (GetWeaponInfo[LimbDamage] == 0.0)
			{
				return Plugin_Handled;
			}
			else
			{
				damage *= GetWeaponInfo[LimbDamage];
				
				return Plugin_Changed;
			}
		}
		
		new ActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		if (!IsValidEdict(ActiveWeapon) || (ActiveWeapon == -1))
		{
			return Plugin_Continue;
		}
		
		decl String:AttackerWeaponName[30];
		GetEdictClassname(ActiveWeapon, AttackerWeaponName, sizeof(AttackerWeaponName));
		ReplaceString(AttackerWeaponName, sizeof(AttackerWeaponName), "weapon_", "", false);
		
		if (StrEqual("knife", AttackerWeaponName, false))
		{
			new GetKnifeInfo[WeaponAttributes];
			
			if (damage <= 30.0)
			{
				GetTrieArray(WeaponTypeTrie, "knife", GetKnifeInfo[0], 17);
			}
			else if ((damage > 30.0) && (damage <= 100.0))
			{
				GetTrieArray(WeaponTypeTrie, "knifestab", GetKnifeInfo[0], 17);
			}
			else
			{
				GetTrieArray(WeaponTypeTrie, "knifebackstab", GetKnifeInfo[0], 17);
			}
			
			CurrentRagdollForce[victim] = GetWeaponInfo[RagdollForce];
			
			if (GetKnifeInfo[GenericDamage] == 0.0)
			{
				return Plugin_Handled;
			}
			else if ((GetKnifeInfo[GenericDamage] != 1.0) && (GetKnifeInfo[GenericDamage] >= 0.0))
			{
				damage *= GetKnifeInfo[GenericDamage];
				
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

// physics damage from projectiles doesn't fire traceattack so use takedamage, added grenade in here aswell.
public Action: OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if ((attacker > 0) && (attacker <= MaxClients) && (attacker != inflictor))
	{
		decl String:WeaponName[30];
		GetEdictClassname(inflictor, WeaponName, sizeof(WeaponName));
		ReplaceString(WeaponName, sizeof(WeaponName), "_projectile", "", false);
		
		new GetWeaponInfo[WeaponAttributes];
		
		if (GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 17))
		{
			CurrentRagdollForce[victim] = GetWeaponInfo[RagdollForce];
			
			if (GetWeaponInfo[GenericDamage] == 0.0)
			{
				return Plugin_Handled;
			}
			else if ((GetWeaponInfo[GenericDamage] != 1.0) && (GetWeaponInfo[GenericDamage] >= 0.0))
			{
				damage *= GetWeaponInfo[GenericDamage];
				
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

public OnWeaponEquipPost(client, weapon)
{
	new String:WeaponName[30];
	GetEdictClassname(weapon, WeaponName, sizeof(WeaponName));
	ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
	
	new GetWeaponInfo[WeaponAttributes];
	GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 15);
	
	if (GetWeaponInfo[AutoMode] == 1)
	{
		ModeStateArray[client][PistolAuto] = false;
		
		if (!(Notify & DISABLE_EQUIP_NOTIFICATION))
		{
			PrintToChat(client, " \x04[Weapon Mod] \x01press alternate attack to switch fire modes on this %s", WeaponName);
		}
	}
	
	if (GetWeaponInfo[BurstMode] == 1)
	{
		ModeStateArray[client][SmgBurst] = false;
		
		if (!(Notify & DISABLE_EQUIP_NOTIFICATION))
		{
			PrintToChat(client, " \x04[Weapon Mod] \x01press alternate attack to switch fire modes on this %s", WeaponName);
		}
	}
	
	if (GetWeaponInfo[InfiniteAmmo] == 1)
	{
		if (!(Notify & DISABLE_EQUIP_NOTIFICATION))
		{
			PrintToChat(client, " \x04[Weapon Mod] \x01This %s has infinite ammo enabled", WeaponName);
		}
	}
	
	if (GetWeaponInfo[QuickSwitch] == 1)
	{
		if (!(Notify & DISABLE_EQUIP_NOTIFICATION))
		{
			PrintToChat(client, " \x04[Weapon Mod] \x01This %s has quick switch enabled, You can attack immediately after switching to this weapon.", WeaponName);
		}
	}
}

public OnWeaponSwitchPost(client, weapon)
{
	BurstShotsFired[client] = 0;
	
	decl String:WeaponName[30];
	GetEdictClassname(weapon, WeaponName, sizeof(WeaponName));
	ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
	
	new GetWeaponInfo[WeaponAttributes];
	GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 17);
	
	/* if quickswitch was used change from the deploy animation back to the idle one on the players viewmodel.
	also remove the attack delay from switching weapons. */
	if (GetWeaponInfo[QuickSwitch] == 1)
	{
		/* "m_flNextAttack" is whent the player can next attack, set it to next game frame
		instead of the deploy animation length */
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime());
		
		new ViewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
		
		// make sure the correct animation is used if the silencer is on.
		if (StrEqual("usp_silencer", WeaponName, false))
		{
			if (!GetEntProp(weapon, Prop_Send, "m_bSilencerOn"))
			{
				SetEntProp(ViewModel, Prop_Send, "m_nSequence", 8);
				return;
			}
		}
		else if (StrEqual("m4a1_silencer", WeaponName, false))
		{
			if (!GetEntProp(weapon, Prop_Send, "m_bSilencerOn"))
			{
				SetEntProp(ViewModel, Prop_Send, "m_nSequence", 7);
				return;
			}
		}
		
		SetEntProp(ViewModel, Prop_Send, "m_nSequence", 0);
	}
}

public Action:Command_Say(client, const String:command[], argc)
{
	if (!IsEnabled)
	{
		return Plugin_Continue;
	}
	
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
			GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 17);
			
			new Handle:AttributeMenu = CreateMenu(MenuHandler);
			SetMenuTitle(AttributeMenu, "%s settings", WeaponName);
			
			new String:menubuffer[100];
			new String:FloatString[20];
			
			if (GetWeaponInfo[RecoilType1] != -5.0)
			{
				FloatToString(GetWeaponInfo[RecoilType1], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Recoil = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[RecoilType2] != -5.0)
			{
				FloatToString(GetWeaponInfo[RecoilType2], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Recoil = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[FireRate] != -5.0)
			{
				FloatToString(GetWeaponInfo[FireRate], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Fire Rate = %s", FloatString);
				
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[AutoMode] != -5)
			{
				Format(menubuffer, sizeof(menubuffer), "Automatic Mode = %i",GetWeaponInfo[AutoMode]);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
				
				if (GetWeaponInfo[ModeFireRate] != -5.0)
				{
					FloatToString(GetWeaponInfo[ModeFireRate], FloatString, sizeof(FloatString));
					Format(menubuffer, sizeof(menubuffer), "Mode Fire Rate = %s", FloatString);
					
					AddMenuItem(AttributeMenu, menubuffer, menubuffer);
				}
			}
			
			if (GetWeaponInfo[GenericDamage] != -5.0)
			{
				FloatToString(GetWeaponInfo[GenericDamage], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Generic Damage = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[HeadDamage] != -5.0)
			{
				FloatToString(GetWeaponInfo[HeadDamage], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Head Damage = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[TorsoDamage] != -5.0)
			{
				FloatToString(GetWeaponInfo[TorsoDamage], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Torso Damage = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[LimbDamage] != -5.0)
			{
				FloatToString(GetWeaponInfo[LimbDamage], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Limb Damage = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[BurstMode] != -5)
			{
				Format(menubuffer, sizeof(menubuffer), "Automatic Mode = %i",GetWeaponInfo[BurstMode]);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
				
				if (GetWeaponInfo[ModeFireRate] != -5.0)
				{
					FloatToString(GetWeaponInfo[ModeFireRate], FloatString, sizeof(FloatString));
					Format(menubuffer, sizeof(menubuffer), "BurstFire Fire Rate = %s", FloatString);
					
					AddMenuItem(AttributeMenu, menubuffer, menubuffer);
				}
			}
			
			if (GetWeaponInfo[InfiniteAmmo] != -5)
			{
				Format(menubuffer, sizeof(menubuffer), "Automatic Mode = %i",GetWeaponInfo[InfiniteAmmo]);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[QuickSwitch] != -5)
			{
				Format(menubuffer, sizeof(menubuffer), "Automatic Mode = %i",GetWeaponInfo[QuickSwitch]);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[RagdollForce] != -5.0)
			{
				FloatToString(GetWeaponInfo[RagdollForce], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Ragdoll Force = %s multiplier", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[StandSpread] != -5.0)
			{
				FloatToString(GetWeaponInfo[StandSpread], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Stand Spread = %s", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[MoveSpread] != -5.0)
			{
				FloatToString(GetWeaponInfo[MoveSpread], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Move Spread = %s", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[CrouchSpread] != -5.0)
			{
				FloatToString(GetWeaponInfo[CrouchSpread], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Crouch Spread = %s", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			if (GetWeaponInfo[MiscSpread] != -5.0)
			{
				FloatToString(GetWeaponInfo[MiscSpread], FloatString, sizeof(FloatString));
				Format(menubuffer, sizeof(menubuffer), "Misc Spread = %s", FloatString);
				
				AddMenuItem(AttributeMenu, menubuffer, menubuffer);
			}
			
			DisplayMenu(AttributeMenu, param1, MENU_TIME_FOREVER);
		}
	}
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		DisplayMenu(WeaponmodMenu, param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsEnabled)
	{
		return;
	}
	
	if (!(Notify & DISABLE_MENU_NOTIFICATION))
	{
		PrintToChatAll("\x01Type \x04!weaponmod \x01in chat to see if any weapons have been modified.");
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsEnabled)
	{
		return;
	}
	
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);
	
	SDKHook(client, SDKHook_PostThink, OnPostThink);
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	if (!IsEnabled)
	{
		return;
	}
	
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);
	new String:WeaponName[30];
	GetEventString(event, "weapon", WeaponName, sizeof(WeaponName));
	
	SDKUnhook(client, SDKHook_PostThink, OnPostThink);
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	
	new GetWeaponInfo[WeaponAttributes];
	if (!GetTrieArray(WeaponTypeTrie, WeaponName, GetWeaponInfo[0], 17))
	{
		return;
	}
	
	if (CurrentRagdollForce[client] == -1.0)
	{
		return;
	}
	
	//"m_hRagdoll" points to the playes ragdoll.
	new Ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (Ragdoll == -1)
	{
		return;
	}
	
	//the force applied to the entire ragdoll for non hitbox specific damage..
	new Float:Velocity[3];
	GetEntPropVector(Ragdoll, Prop_Send, "m_vecRagdollVelocity", Velocity);
	ScaleVector(Velocity, CurrentRagdollForce[client]);
	SetEntPropVector(Ragdoll, Prop_Send, "m_vecRagdollVelocity", Velocity);
	
	//the force applied to a ragdolls bone for hitbox specific damage.
	new Float:Force[3];
	GetEntPropVector(Ragdoll, Prop_Send, "m_vecForce", Force);
	ScaleVector(Force, CurrentRagdollForce[client]);
	SetEntPropVector(Ragdoll, Prop_Send, "m_vecForce", Force);
}

CheckAttributeRange(const String:Weapon[], WeaponAttributes:Attribute, const String:Value[], bool:IsFloat=false, Float:Min=0.0, Float:Max=0.0)
{
	if (IsFloat)
	{
		new Float:EditWeapon[WeaponAttributes];
		GetTrieArray(WeaponTypeTrie, Weapon, EditWeapon[0], 17);
	
		new Float:AttributeValue = StringToFloat(Value);
		
		new String:FloatString[20];
		FloatToString(AttributeValue, FloatString, sizeof(FloatString));
		
		if (AttributeValue > Max)
		{
			AttributeValue = Max;
			FloatToString(AttributeValue, FloatString, sizeof(FloatString));
			PrintToServer("********** weaponmod: %s %s max value capped to %s", Weapon, Attribute, FloatString);
		}
		else if ((AttributeValue < Min) && (AttributeValue != -1.0))
		{
			AttributeValue = Min;
			FloatToString(AttributeValue, FloatString, sizeof(FloatString));
			PrintToServer("********** weaponmod: %s %s min value capped to %s", Weapon, Attribute, FloatString);
		}
		
		EditWeapon[Attribute] = AttributeValue;
		SetTrieArray(WeaponTypeTrie, Weapon, EditWeapon[0], 17);
	}
	else
	{
		new EditWeapon[WeaponAttributes];
		GetTrieArray(WeaponTypeTrie, Weapon, EditWeapon[0], 17);
	
		new AttributeValue = StringToInt(Value);
		
		if ((AttributeValue != 1) && (AttributeValue != 0))
		{
			AttributeValue = 0;
			PrintToServer("********** weaponmod: value must be 0 or 1 else default value of 0 is used");
		}
		
		EditWeapon[Attribute] = AttributeValue;
		SetTrieArray(WeaponTypeTrie, Weapon, EditWeapon[0], 17);
	}
}