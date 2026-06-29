/* TO DO: Fix laser/tracer client crashes (sigh)
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#define VERSION "0.992"
#define MAXWEAPONS 26

public Plugin:myinfo =
{
	name = "Bling My Server",
	author = "XARiUS",
	description = "Various fun related goodies.  No-Scope only, headshot only, one shot kill, blood/gore effects, headshot sounds, knife kill sounds, dissolver effects, noblock, welcome sound.",
	version = "0.992",
	url = "http://xari.us/"
};

new String:language[4];
new String:languagecode[4];
new String:g_headsounds[256];
new String:headsounds[5][256];
new String:g_knifesounds[256];
new String:knifesounds[5][256];
new String:menutext[256];
new String:g_joinsound[PLATFORM_MAX_PATH];
new String:g_onlyweapon[64];
new String:g_particle_file[] = "materials/particle/particledefault.vmt";
new String:g_particle[] = "UnlitGeneric\r{\r\"$translucent\" 1\r\"$basetexture\" \"Decals/blood_gunshot_decal\"\r\"$vertexcolor\" 1\r}";
new String:bloodmodel[] = "materials/sprites/blood.vmt";
new String:bloodsprite[] = "materials/sprites/bloodspray.vmt";
new String:blockbuysound[] = "buttons/weapon_cant_buy.wav";
new String:weapons[MAXWEAPONS][256] = {	"glock", "usp", "p228", "deagle", "elite",
										"fiveseven", "m3", "xm1014", "mac10", "tmp",
										"mp5navy", "ump45", "p90", "galil", "famas",
										"ak47", "m4a1", "sg552", "aug", "m249",
										"scout", "awp", "g3sg1", "sg550", "hegrenade", "knife" };
new String:g_warmupweapons[256];
new String:g_warmuppreexec[32];
new String:g_warmuppostexec[32];
new String:warmupweapons[3][256];
new bool:isWarmup = false;
new bool:g_warmup;
new bool:g_warmuprespawn;
new bool:g_warmupff;
new bool:g_headshot;
new bool:g_headshotsounds;
new bool:g_headshotsoundsemit;
new bool:g_knifekillsounds;
new bool:g_knifekillsoundsemit;
new bool:g_scoutnoscope;
new bool:g_awpnoscope;
new bool:g_g3sg1noscope;
new bool:g_sg550noscope;
new bool:g_bulletpath;
new bool:g_noblock;
new bool:g_oneshotkill;
new bool:g_oneshotkillnxtrnd = false;
new bool:g_blood;
new bool:g_roundrestricted;
new bool:g_roundrestrictednxtrnd = false;
new bool:g_unlimitedhe;
new bool:g_unlimitedhenxtrnd;
new bool:g_unlimitedflash;
new bool:g_unlimitedflashnxtrnd = false;
new bool:g_unlimitedsmoke;
new bool:g_unlimitedsmokenxtrnd = false;
new bool:g_unlimitedammo;
new bool:g_bank;
new bool:g_removeweps;
new bool:g_cookiescached[MAXPLAYERS + 1];
new soundsfound;
new ksoundsfound;
new g_dissolver;
new g_laser;
new g_voffset0;
new g_voffset1;
new g_voffset2;
new g_bloodamount;
new g_bloodflags;
new g_bloodmodel;
new g_bloodsprite;
new g_bankmaxbalance;
new g_mugging;
new g_mugginghealth;
new g_warmuptime;
new timesrepeated;
new Handle:g_Cvarheadshot = INVALID_HANDLE;
new Handle:g_Cvarheadsounds = INVALID_HANDLE;
new Handle:g_Cvarheadshotsounds = INVALID_HANDLE;
new Handle:g_Cvarheadshotsoundsemit = INVALID_HANDLE;
new Handle:g_Cvarknifesounds = INVALID_HANDLE;
new Handle:g_Cvarknifekillsounds = INVALID_HANDLE;
new Handle:g_Cvarknifekillsoundsemit = INVALID_HANDLE;
new Handle:g_Cvarscoutnoscope = INVALID_HANDLE;
new Handle:g_Cvarawpnoscope = INVALID_HANDLE;
new Handle:g_Cvarg3sg1noscope = INVALID_HANDLE;
new Handle:g_Cvarsg550noscope = INVALID_HANDLE;
new Handle:g_Cvarbulletpath = INVALID_HANDLE;
new Handle:g_Cvardissolver = INVALID_HANDLE;
new Handle:g_Cvarjoinsound = INVALID_HANDLE;
new Handle:g_Cvarnoblock = INVALID_HANDLE;
new Handle:g_Cvaroneshotkill = INVALID_HANDLE;
new Handle:g_Cvarblood = INVALID_HANDLE;
new Handle:g_Cvarbloodamount = INVALID_HANDLE;
new Handle:g_Cvarbloodflags = INVALID_HANDLE;
new Handle:g_Cvaronlyweapon = INVALID_HANDLE;
new Handle:g_Cvarunlimitedhe = INVALID_HANDLE;
new Handle:g_Cvarunlimitedflash = INVALID_HANDLE;
new Handle:g_Cvarunlimitedsmoke = INVALID_HANDLE;
new Handle:g_Cvarunlimitedammo = INVALID_HANDLE;
new Handle:g_Cvarmugging = INVALID_HANDLE;
new Handle:g_Cvarmuggingpercent = INVALID_HANDLE;
new Handle:g_Cvarmugginghealth = INVALID_HANDLE;
new Handle:g_Cvarbank = INVALID_HANDLE;
new Handle:g_Cvarbankmaxbalance= INVALID_HANDLE;
new Handle:g_file_handle = INVALID_HANDLE;
new Handle:g_bankcookie = INVALID_HANDLE;
new Handle:g_warmuptimer = INVALID_HANDLE;
new Handle:g_Cvarwarmup = INVALID_HANDLE;
new Handle:g_Cvarwarmuprespawn = INVALID_HANDLE;
new Handle:g_Cvarwarmupff = INVALID_HANDLE;
new Handle:g_Cvarwarmuptime = INVALID_HANDLE;
new Handle:g_Cvarwarmuppreexec = INVALID_HANDLE;
new Handle:g_Cvarwarmuppostexec = INVALID_HANDLE;
new Handle:g_Cvarwarmupweapons = INVALID_HANDLE;
new Handle:g_Cvarwarmupactive = INVALID_HANDLE;
new Handle:g_Cvarremoveweps = INVALID_HANDLE;

//	new Handle:g_headshotsoundscookie = INVALID_HANDLE;
new Handle:hAdminMenu = INVALID_HANDLE;
new g_ownerentity, g_iAccount, g_iHealth, g_Armor, g_block, g_weapons;
static const g_bloodcolor[] = {85,0,0,255};

public OnPluginStart()
{
	LoadTranslations("bling.phrases");
	LoadTranslations("bling.menu.phrases");
	LoadTranslations("common.phrases");
	GetLanguageInfo(GetServerLanguage(), languagecode, sizeof(languagecode), language, sizeof(language));
	CreateConVar("sm_bling_version", VERSION, "Bling", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvarjoinsound = CreateConVar("sm_bling_joinsound", "", "Sound file to play to connecting clients.  Place file in sound/bling/");
	g_Cvarheadshot = CreateConVar("sm_bling_headshot", "0", "<1/0> Enable/Disable headshots only.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarheadshotsounds = CreateConVar("sm_bling_headshotsounds", "1", "<1/0> Enable/Disable headshot sounds.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarheadsounds = CreateConVar("sm_bling_headsounds", "", "Sound files to indicate headshots. (Max: 5, comma seperated)  Leave blank for default sounds.  Place files in sound/bling/");
	g_Cvarheadshotsoundsemit = CreateConVar("sm_bling_headshotemit", "0", "<1 = Attacker/0 = Victim> Emit headshot sounds from victim or attacker.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarknifekillsounds = CreateConVar("sm_bling_knifekillsounds", "1", "<1/0> Enable/Disable knife kill sounds.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarknifesounds = CreateConVar("sm_bling_knifesounds", "", "Sound files to indicate knife kills. (Max: 5, comma seperated)  Leave blank for default sounds.  Place files in sound/bling/");
	g_Cvarknifekillsoundsemit = CreateConVar("sm_bling_knifekillemit", "0", "<1 = Attacker/0 = Victim> Emit knife sounds from victim or attacker. 0 = Victim, 1 = Attacker", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarscoutnoscope = CreateConVar("sm_bling_scoutnoscope", "0", "<1/0> Enable/Disable Scout No Scope Only", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarawpnoscope = CreateConVar("sm_bling_awpnoscope", "0", "<1/0> Enable/Disable AWP No Scope Only", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarg3sg1noscope = CreateConVar("sm_bling_g3sg1noscope", "0", "<1/0> Enable/Disable G3SG1 No Scope Only", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarsg550noscope = CreateConVar("sm_bling_sg550noscope", "0", "<1/0> Enable/Disable SG550 No Scope Only", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarbulletpath = CreateConVar("sm_bling_bulletpaths", "0", "<1/0> Enable/Disable Bullet Paths using a small laser beam.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvardissolver = CreateConVar("sm_bling_dissolver", "1", "<3 = Electrical/2 = Energy/1 = Random/0 = Disabled> Ragdoll Dissolve Effects to use.", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_Cvarnoblock = CreateConVar("sm_bling_noblock", "0", "<1/0> Enable/Disable No-Block (players move through each other)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvaroneshotkill = CreateConVar("sm_bling_oneshotkill", "0", "<1/0> Enable/Disable One shot kills.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarblood = CreateConVar("sm_bling_blood", "1", "<1/0> Enable/Disable extra blood/gibs on headshots and knife kills.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarbloodamount = CreateConVar("sm_bling_bloodamount", "300.0", "Amount of blood to emit.", FCVAR_PLUGIN, true, 50.0, true, 5000.0);
	g_Cvarbloodflags = CreateConVar("sm_bling_bloodflags", "15", "Flags used to generate blood (research env_blood flags online)", FCVAR_PLUGIN, true, 1.0, true, 15.0);
	g_Cvaronlyweapon = CreateConVar("sm_bling_onlyweapon", "none", "Restrict rounds to a specific weapon only.  Weapon will be given on spawn, buying is disabled. (example: \"knife\")",FCVAR_PLUGIN);
	g_Cvarunlimitedhe = CreateConVar("sm_bling_unlimitedhe", "0", "<1/0> Enable/Disable unlimited HE Grenades (no purchase neccesary).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarunlimitedflash = CreateConVar("sm_bling_unlimitedflash", "0", "<1/0> Enable/Disable unlimited Flashbang Grenades (no purchase neccesary).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarunlimitedsmoke = CreateConVar("sm_bling_unlimitedsmoke", "0", "<1/0> Enable/Disable unlimited Smoke Grenades (no purchase neccesary).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarunlimitedammo = CreateConVar("sm_bling_unlimitedammo", "0", "<1/0> Enable/Disable unlimited ammunition for weapons.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarmugging = CreateConVar("sm_bling_mugging", "0", "<3 = Cash & Health/2 = Steal Health/1 = Steal Cash/0 = Disabled> Mug someone when killed with a knife.", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_Cvarmuggingpercent = CreateConVar("sm_bling_muggingpercent", "0.30", "<0.01 - 1.00> Percent of cash to steal when mugging. (0.30 = 30%)", FCVAR_PLUGIN, true, 0.01, true, 1.0);
	g_Cvarmugginghealth = CreateConVar("sm_bling_mugginghealth", "40", "Amount of health to give to the killer ", FCVAR_PLUGIN, true, 1.0, true, 100.0);
	g_Cvarbank = CreateConVar("sm_bling_bank", "0", "<1/0> Enable/Disable the bank functionality.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarbankmaxbalance = CreateConVar("sm_bling_bankmaxbalance", "50000", "<1000 - 500000> Limit the maximum balance for each bank account.", FCVAR_PLUGIN, true, 1000.0, true, 500000.0);
	g_Cvarwarmup = CreateConVar("sm_bling_warmup", "1", "<1/0> Enable/Disable Warm Up Round.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarwarmuprespawn = CreateConVar("sm_bling_warmuprespawn", "1", "<1/0> Enable/Disable Respawning players during warmup round.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarwarmupff = CreateConVar("sm_bling_warmupff", "0", "<1/0> Enable/Disable Friendly Fire during warmup round.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvarwarmuptime = CreateConVar("sm_bling_warmuptime", "30", "<5 - 300> Warm Up Round time in seconds.", FCVAR_PLUGIN, true, 5.0, true, 300.0);
	g_Cvarwarmupweapons = CreateConVar("sm_bling_warmupweapons", "random", "Weapons to give each player during warmup, comma seperated.  Maximum of 3.  Example: \"HEGrenade,Deagle,Mac10\" or \"random\".", FCVAR_PLUGIN);
	g_Cvarwarmuppreexec = CreateConVar("sm_bling_warmuppreexec", "", "Config file to execute prior to warmup round starting.  File goes in /cfg/ directory.  (Example: 'prewarmup.cfg' | Leave blank for none)", FCVAR_PLUGIN);
	g_Cvarwarmuppostexec = CreateConVar("sm_bling_warmuppostexec", "", "Config file to execute after warmup round has ended.  File goes in /cfg/ directory.  (Example: 'postwarmup.cfg' | Leave blank for none)", FCVAR_PLUGIN);
	g_Cvarwarmupactive = CreateConVar("sm_bling_warmupactive", "0", "DO NOT MODIFY THIS VALUE - USED FOR STATS TRACKING", FCVAR_DONTRECORD);
	g_Cvarremoveweps = CreateConVar("sm_bling_removeweps", "0", "<1/0> Enable/Disable Removing of weapons from the ground on map start and when a player dies.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_bankcookie = RegClientCookie("blingbank", "Bling Bank Balance", CookieAccess_Private);
//	g_headshotsoundscookie = RegClientCookie("blinghssounds", "Head Shot Sounds", CookieAccess_Public);

	RegConsoleCmd("buy", Command_Buy);
	RegConsoleCmd("deposit", Command_Deposit, "Deposit Money into the Bank of Bling");
	RegConsoleCmd("withdraw", Command_Withdraw, "Withdraw Money from the Bank of Bling");
	RegConsoleCmd("balance", Command_Balance, "Show your balance with the Bank of Bling");
	RegAdminCmd("sm_givecash", Command_GiveCash, ADMFLAG_KICK, "sm_givecash <#userid|name|@all|@ct|@t> <amount>");
	RegAdminCmd("sm_giveitem", Command_GiveItem, ADMFLAG_KICK, "sm_giveitem <#userid|name|@all|@ct|@t> <item> (ie: weapon_awp)");
	RegAdminCmd("sm_sethealth", Command_SetHealth, ADMFLAG_KICK, "sm_sethealth <#userid|name|@all|@ct|@t> <amount>");
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_KICK, "sm_sethealth <#userid|name|@all|@ct|@t>");

	HookEvent("player_hurt", EventPlayerHurt, EventHookMode_Pre);
	HookEvent("weapon_zoom", EventWeaponZoom, EventHookMode_Post);
	HookEvent("weapon_fire", EventWeaponFire, EventHookMode_Post);
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("round_start", EventRoundStart, EventHookMode_Pre);
	HookEvent("round_end", EventRoundEnd, EventHookMode_Post);
	HookEvent("game_start", EventGameStart, EventHookMode_Post);
	HookEvent("item_pickup", EventItemPickup, EventHookMode_Post);
	HookEvent("hegrenade_detonate", EventHEGrenadeDetonate, EventHookMode_Post);
	HookEvent("flashbang_detonate", EventFlashBangDetonate, EventHookMode_Post);
	HookEvent("smokegrenade_detonate", EventSmokeGrenadeDetonate, EventHookMode_Post);
	HookConVarChange(g_Cvarheadshot, OnSettingChanged);
	HookConVarChange(g_Cvarheadshotsounds, OnSettingChanged);
	HookConVarChange(g_Cvarheadshotsoundsemit, OnSettingChanged);
	HookConVarChange(g_Cvarknifekillsounds, OnSettingChanged);
	HookConVarChange(g_Cvarknifekillsoundsemit, OnSettingChanged);
	HookConVarChange(g_Cvarscoutnoscope, OnSettingChanged);
	HookConVarChange(g_Cvarawpnoscope, OnSettingChanged);
	HookConVarChange(g_Cvarg3sg1noscope, OnSettingChanged);
	HookConVarChange(g_Cvarsg550noscope, OnSettingChanged);
	HookConVarChange(g_Cvarbulletpath, OnSettingChanged);
	HookConVarChange(g_Cvardissolver, OnSettingChanged);
	HookConVarChange(g_Cvarnoblock, OnSettingChanged);
	HookConVarChange(g_Cvaroneshotkill, OnSettingChanged);
	HookConVarChange(g_Cvarblood, OnSettingChanged);
	HookConVarChange(g_Cvarbloodamount, OnSettingChanged);
	HookConVarChange(g_Cvarbloodflags, OnSettingChanged);
	HookConVarChange(g_Cvaronlyweapon, OnSettingChanged);
	HookConVarChange(g_Cvarunlimitedhe, OnSettingChanged);
	HookConVarChange(g_Cvarunlimitedflash, OnSettingChanged);
	HookConVarChange(g_Cvarunlimitedsmoke, OnSettingChanged);
	HookConVarChange(g_Cvarunlimitedammo, OnSettingChanged);
	HookConVarChange(g_Cvarmugging, OnSettingChanged);
	HookConVarChange(g_Cvarmuggingpercent, OnSettingChanged);
	HookConVarChange(g_Cvarmugginghealth, OnSettingChanged);
	HookConVarChange(g_Cvarbank, OnSettingChanged);
	HookConVarChange(g_Cvarbankmaxbalance, OnSettingChanged);
	HookConVarChange(g_Cvarwarmup, OnSettingChanged);
	HookConVarChange(g_Cvarwarmuprespawn, OnSettingChanged);
	HookConVarChange(g_Cvarwarmupff, OnSettingChanged);
	HookConVarChange(g_Cvarwarmuptime, OnSettingChanged);
	HookConVarChange(g_Cvarwarmuppreexec, OnSettingChanged);
	HookConVarChange(g_Cvarwarmuppostexec, OnSettingChanged);
	HookConVarChange(g_Cvarwarmupweapons, OnSettingChanged);
	HookConVarChange(g_Cvarremoveweps, OnSettingChanged);
	timesrepeated = g_warmuptime;
	
	g_laser = PrecacheModel("materials/sprites/laser.vmt");
	g_bloodmodel = PrecacheModel(bloodmodel, true);
	g_bloodsprite = PrecacheModel(bloodsprite, true);

	if (!FileExists(g_particle_file, true))
	{
		g_file_handle = OpenFile(g_particle_file,"a");
		if (g_file_handle != INVALID_HANDLE)
		{
			WriteFileString(g_file_handle,g_particle,false);
			CloseHandle(g_file_handle);
		}
	}
	AddFileToDownloadsTable(g_particle_file);
	PrecacheModel(g_particle_file, true);
	g_ownerentity = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	if (g_ownerentity == -1)
	{
		LogError("Bling: Error - Unable to get offset for CBaseCombatWeapon::m_hOwnerEntity");
		SetFailState("Bling: Error - Unable to get offset for CBaseCombatWeapon::m_hOwnerEntity");
	}
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if (g_iAccount == -1)
	{
		LogError("Bling: Error - Unable to get offset for CSSPlayer::m_iAccount");
		SetFailState("Bling: Error - Unable to get offset for CSSPlayer::m_iAccount");
	}
	g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
	if (g_iHealth == -1)
	{
		LogError("Bling: Error - Unable to get offset for CSSPlayer::m_iHealth");
		SetFailState("Bling: Error - Unable to get offset for CSSPlayer::m_iHealth");
	}
	g_Armor = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	if (g_Armor == -1)
	{
		LogError("Bling: Error - Unable to get offset for CSSPlayer::m_ArmorValue");
		SetFailState("Bling: Error - Unable to get offset for CSSPlayer::m_ArmorValue");
	}
	g_block = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (g_block == -1)
	{
		LogError("Bling: Error - Unable to get offset for CBaseEntity::m_CollisionGroup");
		SetFailState("Bling: Error - Unable to get offset for CBaseEntity::m_CollisionGroup");
	}
	g_voffset0 = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	if (g_voffset0 == -1)
	{
		LogError("Bling: Error - Unable to get offset for CBasePlayer::m_vecVelocity[0]");
		SetFailState("Bling: Error - Unable to get offset for CBasePlayer::m_vecVelocity[0]");
	}	
	g_voffset1 = FindSendPropOffs("CBasePlayer", "m_vecVelocity[1]");
	if (g_voffset1 == -1)
	{
		LogError("Bling: Error - Unable to get offset for CBasePlayer::m_vecVelocity[1]");
		SetFailState("Bling: Error - Unable to get offset for CBasePlayer::m_vecVelocity[1]");
	}	
	g_voffset2 = FindSendPropOffs("CBasePlayer", "m_vecVelocity[2]");
	if (g_voffset2 == -1)
	{
		LogError("Bling: Error - Unable to get offset for CBasePlayer::m_vecVelocity[2]");
		SetFailState("Bling: Error - Unable to get offset for CBasePlayer::m_vecVelocity[2]");
	}
	g_weapons = FindSendPropOffs("CBaseCombatCharacter", "m_hMyWeapons");
	if (g_weapons == -1)
	{
		LogError("Bling: Error - Unable to get offset for CBaseCombatCharacter::m_hMyWeapons");
		SetFailState("Bling: Error - Unable to get offset for CBaseCombatCharacter::m_hMyWeapons");
	}	
	
	 /* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	AutoExecConfig(true, "bling");
}

public OnConfigsExecuted()
{
	GetConVarString(g_Cvarjoinsound, g_joinsound, sizeof(g_joinsound));
	GetConVarString(g_Cvarheadsounds, g_headsounds, sizeof(g_headsounds));
	GetConVarString(g_Cvarknifesounds, g_knifesounds, sizeof(g_knifesounds));
	GetConVarString(g_Cvaronlyweapon, g_onlyweapon, sizeof(g_onlyweapon));
	GetConVarString(g_Cvarwarmupweapons, g_warmupweapons, sizeof(g_warmupweapons));
	CheckWeaponString(g_warmupweapons);
	GetConVarString(g_Cvarwarmuppreexec, g_warmuppreexec, sizeof(g_warmuppreexec));
	GetConVarString(g_Cvarwarmuppostexec, g_warmuppostexec, sizeof(g_warmuppostexec));
	g_headshot = GetConVarBool(g_Cvarheadshot);
	g_headshotsounds = GetConVarBool(g_Cvarheadshotsounds);
	g_headshotsoundsemit = GetConVarBool(g_Cvarheadshotsoundsemit);
	g_knifekillsounds = GetConVarBool(g_Cvarknifekillsounds);
	g_knifekillsoundsemit = GetConVarBool(g_Cvarknifekillsoundsemit);
	g_scoutnoscope = GetConVarBool(g_Cvarscoutnoscope);
	g_bulletpath = GetConVarBool(g_Cvarbulletpath);
	g_dissolver = GetConVarInt(g_Cvardissolver);
	g_noblock = GetConVarBool(g_Cvarnoblock);
	g_oneshotkill = GetConVarBool(g_Cvaroneshotkill);
	g_blood = GetConVarBool(g_Cvarblood);
	g_unlimitedhe = GetConVarBool(g_Cvarunlimitedhe);
	g_unlimitedflash = GetConVarBool(g_Cvarunlimitedflash);
	g_unlimitedsmoke = GetConVarBool(g_Cvarunlimitedsmoke);
	g_unlimitedammo = GetConVarBool(g_Cvarunlimitedammo);
	g_removeweps = GetConVarBool(g_Cvarremoveweps);
	g_bank = GetConVarBool(g_Cvarbank);
	g_warmup = GetConVarBool(g_Cvarwarmup);
	g_warmuprespawn = GetConVarBool(g_Cvarwarmuprespawn);
	g_warmupff = GetConVarBool(g_Cvarwarmupff);
	g_bloodamount = GetConVarInt(g_Cvarbloodamount);
	g_bloodflags = GetConVarInt(g_Cvarbloodflags);
	g_bankmaxbalance = GetConVarInt(g_Cvarbankmaxbalance);
	g_mugging = GetConVarInt(g_Cvarmugging);
	g_mugginghealth = GetConVarInt(g_Cvarmugginghealth);
	g_warmuptime = GetConVarInt(g_Cvarwarmuptime);
	
	//SetCookiePrefabMenu(Handle:g_headshotsoundscookie, CookieMenu_OnOff, "Headshot Sounds");

	PrecacheSound(blockbuysound, true);
	
	decl String:jbuffer[PLATFORM_MAX_PATH];
	if (!StrEqual(g_joinsound, "", false))
	{
		Format(jbuffer, PLATFORM_MAX_PATH, "bling/%s", g_joinsound);
		if (!PrecacheSound(jbuffer, true))
		{
			LogError("Bling: Could not pre-cache defined join sound: %s", jbuffer);
			SetFailState("Bling: Could not pre-cache defined join sound: %s", jbuffer);
		}
		else
		{
			Format(jbuffer, PLATFORM_MAX_PATH, "sound/bling/%s", g_joinsound);
			AddFileToDownloadsTable(jbuffer);
			Format(g_joinsound, PLATFORM_MAX_PATH, "bling/%s", g_joinsound);
		}
	}
	if (!StrEqual(g_headsounds, "", false))
	{
		new String:buffer[256];
		soundsfound = ExplodeString(g_headsounds, ",", headsounds, 5, 64);
		if (soundsfound > 0)
		{
			for (new i = 0; i <= soundsfound -1; i++)
			{
				Format(buffer, PLATFORM_MAX_PATH, "bling/%s", headsounds[i]);
				if (!PrecacheSound(buffer, true))
				{
					LogError("Bling: Could not pre-cache defined headshot sound: %s", buffer);
					SetFailState("Bling: Could not pre-cache defined headshot sound: %s", buffer);
				}
				else
				{
					Format(buffer, PLATFORM_MAX_PATH, "sound/bling/%s", headsounds[i]);
					AddFileToDownloadsTable(buffer);
					buffer = "bling/";
					StrCat(buffer, sizeof(buffer), headsounds[i]);
					headsounds[i] = buffer;
				}
			}
		}
	}
	
	if (soundsfound < 1)
	{
		soundsfound = 5;
		headsounds[0] = "physics/flesh/flesh_squishy_impact_hard1.wav";
		headsounds[1] = "physics/flesh/flesh_squishy_impact_hard2.wav";
		headsounds[2] = "physics/flesh/flesh_squishy_impact_hard3.wav";
		headsounds[3] = "physics/flesh/flesh_squishy_impact_hard4.wav";
		headsounds[4] = "physics/flesh/flesh_bloody_break.wav";
		PrecacheSound(headsounds[0], true);
		PrecacheSound(headsounds[1], true);
		PrecacheSound(headsounds[2], true);
		PrecacheSound(headsounds[3], true);
		PrecacheSound(headsounds[4], true);
	}

	if (!StrEqual(g_knifesounds, "", false))
	{
		new String:kbuffer[256];
		ksoundsfound = ExplodeString(g_knifesounds, ",", knifesounds, 5, 64);
		if (ksoundsfound > 0)
		{
			for (new i = 0; i <= ksoundsfound -1; i++)
			{
				Format(kbuffer, PLATFORM_MAX_PATH, "bling/%s", knifesounds[i]);
				if (!PrecacheSound(kbuffer, true))
				{
					LogError("Bling: Could not pre-cache defined knifekill sound: %s", kbuffer);
					SetFailState("Bling: Could not pre-cache defined knifekill sound: %s", kbuffer);
				}
				else
				{
					Format(kbuffer, PLATFORM_MAX_PATH, "sound/bling/%s", knifesounds[i]);
					AddFileToDownloadsTable(kbuffer);
					kbuffer = "bling/";
					StrCat(kbuffer, sizeof(kbuffer), knifesounds[i]);
					knifesounds[i] = kbuffer;
				}
			}
		}
	}
	if (ksoundsfound < 1)
	{
		ksoundsfound = 5;
		knifesounds[0] = "physics/flesh/flesh_squishy_impact_hard1.wav";
		knifesounds[1] = "physics/flesh/flesh_squishy_impact_hard2.wav";
		knifesounds[2] = "physics/flesh/flesh_squishy_impact_hard3.wav";
		knifesounds[3] = "physics/flesh/flesh_squishy_impact_hard4.wav";
		knifesounds[4] = "physics/flesh/flesh_bloody_break.wav";
		PrecacheSound(knifesounds[0], true);
		PrecacheSound(knifesounds[1], true);
		PrecacheSound(knifesounds[2], true);
		PrecacheSound(knifesounds[3], true);
		PrecacheSound(knifesounds[4], true);
	}

	if (g_warmuptimer != INVALID_HANDLE)
	{
		KillTimer(g_warmuptimer);
	}
	if (g_warmup)
	{
		SetConVarBool(g_Cvarwarmupactive, true, false, false);
		timesrepeated = g_warmuptime;
		isWarmup = true;
		decl String:buffer[32] = "cfg/";
		StrCat(buffer, sizeof(buffer), g_warmuppreexec);
		if (FileExists(buffer))
		{
			ServerCommand("exec %s", g_warmuppreexec);
		}
		if (g_warmupff)
		{
			ServerCommand("mp_friendlyfire 0");
		}
		g_warmuptimer = CreateTimer(1.0, Countdown, _, TIMER_REPEAT);
	}
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_Cvarheadshot)
	{
		if (newValue[0] == '1')
		{
			g_headshot = true;
			PrintHintTextToAll("%t", "headshot enabled");
			EmitSoundToAll("player/bhit_helmet-1.wav");
		}
		else
		{
			g_headshot = false;
			PrintHintTextToAll("%t", "headshot disabled");
			EmitSoundToAll("player/bhit_helmet-1.wav");
		}
	}
	if (convar == g_Cvarheadshotsounds)
	{
		if (newValue[0] == '1')
		{
			g_headshotsounds = true;
		}
		else
		{
			g_headshotsounds = false;
		}
	}
	if (convar == g_Cvarheadshotsoundsemit)
	{
		if (newValue[0] == '1')
		{
			g_headshotsoundsemit = true;
		}
		else
		{
			g_headshotsoundsemit = false;
		}
	}	
	if (convar == g_Cvarknifekillsounds)
	{
		if (newValue[0] == '1')
		{
			g_knifekillsounds = true;
		}
		else
		{
			g_knifekillsounds = false;
		}
	}
	if (convar == g_Cvarknifekillsoundsemit)
	{
		if (newValue[0] == '1')
		{
			g_knifekillsoundsemit = true;
		}
		else
		{
			g_knifekillsoundsemit = false;
		}
	}
	if (convar == g_Cvarscoutnoscope)
	{
		if (newValue[0] == '1')
		{
			PrintHintTextToAll("%t", "scoutnoscope enabled");
			EmitSoundToAll("weapons/zoom.wav");
			g_scoutnoscope = true;
		}
		else
		{
			PrintHintTextToAll("%t", "scoutnoscope disabled");
			EmitSoundToAll("weapons/zoom.wav");
			g_scoutnoscope = false;
		}
	}
	if (convar == g_Cvarawpnoscope)
	{
		if (newValue[0] == '1')
		{
			PrintHintTextToAll("%t", "awpnoscope enabled");
			EmitSoundToAll("weapons/zoom.wav");
			g_awpnoscope = true;
		}
		else
		{
			PrintHintTextToAll("%t", "awpnoscope disabled");
			EmitSoundToAll("weapons/zoom.wav");
			g_awpnoscope = false;
		}
	}
	if (convar == g_Cvarg3sg1noscope)
	{
		if (newValue[0] == '1')
		{
			PrintHintTextToAll("%t", "g3sg1noscope enabled");
			EmitSoundToAll("weapons/zoom.wav");
			g_g3sg1noscope = true;
		}
		else
		{
			PrintHintTextToAll("%t", "g3sg1noscope disabled");
			EmitSoundToAll("weapons/zoom.wav");
			g_g3sg1noscope = false;
		}
	}
	if (convar == g_Cvarsg550noscope)
	{
		if (newValue[0] == '1')
		{
			PrintHintTextToAll("%t", "sg550noscope enabled");
			EmitSoundToAll("weapons/zoom.wav");
			g_sg550noscope = true;
		}
		else
		{
			PrintHintTextToAll("%t", "sg550noscope disabled");
			EmitSoundToAll("weapons/zoom.wav");
			g_sg550noscope = false;
		}
	}
	if (convar == g_Cvarbulletpath)
	{
		if (newValue[0] == '1')
		{
			PrintHintTextToAll("%t", "bulletpath enabled");
			g_bulletpath = true;
		}
		else
		{
			PrintHintTextToAll("%t", "bulletpath disabled");
			g_bulletpath = false;
		}
	}  
	if (convar == g_Cvarnoblock)
	{
		if (newValue[0] == '1')
		{
			PrintHintTextToAll("%t", "noblock enabled");
			g_noblock = true;
		}
		else
		{
			PrintHintTextToAll("%t", "bulletpath disabled");
			g_noblock = false;
		}
	}
	if (convar == g_Cvaroneshotkill)
	{
		if (newValue[0] == '1')
		{
			g_oneshotkill = true;
			g_oneshotkillnxtrnd = true;
			PrintHintTextToAll("%t", "oneshotkill enabled");
		}
		else
		{
			g_oneshotkill = false;
			g_oneshotkillnxtrnd = false;
			PrintHintTextToAll("%t", "oneshotkill disabled");
		}
	}	
	if (convar == g_Cvardissolver)
	{
		g_dissolver = StringToInt(newValue);
	}
	if (convar == g_Cvarheadshotsounds)
	{
		if (newValue[0] == '1')
		{
			g_headshotsounds = true;
		}
		else
		{
		g_headshotsounds = false;
		}
	}
	if (convar == g_Cvarblood)
	{
		if (newValue[0] == '1')
		{
			g_blood = true;
		}
		else
		{
			g_blood = false;
		}
	}	
	if (convar == g_Cvarunlimitedhe)
	{
		if (newValue[0] == '1')
		{
			PrintHintTextToAll("%t", "unlimitedhe enabled");
			g_unlimitedhe = true;
			g_unlimitedhenxtrnd = true;
		}
		else
		{
			PrintHintTextToAll("%t", "unlimitedhe disabled");
			g_unlimitedhe = false;
			g_unlimitedhenxtrnd = false;
		}
	}	
	if (convar == g_Cvarunlimitedflash)
	{
		if (newValue[0] == '1')
		{
			PrintHintTextToAll("%t", "unlimitedflash enabled");
			g_unlimitedflash = true;
			g_unlimitedflashnxtrnd = true;
		}
		else
		{
			PrintHintTextToAll("%t", "unlimitedflash disabled");
			g_unlimitedflash = false;
			g_unlimitedflashnxtrnd = false;
		}
	}	
	if (convar == g_Cvarunlimitedsmoke)
	{
		if (newValue[0] == '1')
		{
			PrintHintTextToAll("%t", "unlimitedsmoke enabled");
			g_unlimitedsmoke = true;
			g_unlimitedsmokenxtrnd = true;
		}
		else
		{
			PrintHintTextToAll("%t", "unlimitedsmoke disabled");
			g_unlimitedsmoke = false;
			g_unlimitedsmokenxtrnd = true;
		}
	}	
	if (convar == g_Cvarunlimitedammo)
	{
		if (newValue[0] == '1')
		{
			PrintHintTextToAll("%t", "unlimitedammo enabled");
			g_unlimitedammo = true;
		}
		else
		{
			PrintHintTextToAll("%t", "unlimitedammo disabled");
			g_unlimitedammo = false;
		}
	}	
	if (convar == g_Cvarbloodamount)
	{
		g_bloodamount = StringToInt(newValue);
	}
	if (convar == g_Cvarbloodflags)
	{
		g_bloodflags = StringToInt(newValue);
	}
	if (convar == g_Cvarmugging)
	{
		if (newValue[0] > 0)
		{
			PrintHintTextToAll("%t", "mugging enabled");
			g_mugging = StringToInt(newValue);
		}
		else
		{
			PrintHintTextToAll("%t", "mugging disabled");
			g_mugging = StringToInt(newValue);
		}
	}
	if (convar == g_Cvarmugginghealth)
	{
		g_mugginghealth = StringToInt(newValue);
	}
	if (convar == g_Cvarbank)
	{
		if (newValue[0] == '1')
		{
			PrintHintTextToAll("%t", "bank enabled");
			g_bank = true;
		}
		else
		{
			PrintHintTextToAll("%t", "bank disabled");
			g_bank = false;
		}
	}
	if (convar == g_Cvarbankmaxbalance)
	{
		g_bankmaxbalance = StringToInt(newValue);
	}
	if (convar == g_Cvaronlyweapon)
	{
		new bool:valid = false;
		for (new i = 0; i <= MAXWEAPONS - 1; i++)
		{
			if (StrEqual(newValue, weapons[i], false))
			{
				valid = true;
			}
		}
		if (StrEqual(newValue, "none", false))
		{
			PrintHintTextToAll("%t", "weaponlimited disabled");
			strcopy(g_onlyweapon, sizeof(g_onlyweapon), newValue);
			SetConVarString(g_Cvaronlyweapon, newValue);
			g_roundrestricted = false;
			g_roundrestrictednxtrnd = false;
			return;
		}
		if (!valid)
		{
			PrintToServer("[Bling] Weapon selection: %s, is not valid.  Please try setting sm_bling_onlyweapon again.", newValue);
		}
		else
		{
			strcopy(g_onlyweapon, sizeof(g_onlyweapon), newValue);
			SetConVarString(g_Cvaronlyweapon, newValue);
			PrintHintTextToAll("%t %s", "weaponlimited enabled", g_onlyweapon);
			g_roundrestricted = true;
			g_roundrestrictednxtrnd = true;
		}
	}
	if (convar == g_Cvarwarmup)
	{
		if (newValue[0] == '1')
		{
			g_warmup = true;
		}
		else
		{
			g_warmup = false;
		}
	}
	if (convar == g_Cvarwarmuprespawn)
	{
		if (newValue[0] == '1')
		{
			g_warmuprespawn = true;
		}
		else
		{
		  g_warmuprespawn = false;
		}
	}
	if (convar == g_Cvarwarmupff)
	{
		if (newValue[0] == '1')
		{
			g_warmupff = true;
		}
		else
		{
		  g_warmupff = false;
		}
	}
	if (convar == g_Cvarwarmupweapons)
	{
		CheckWeaponString(newValue);
	}
	if (convar == g_Cvarwarmuptime)
	{
		g_warmuptime = StringToInt(newValue);
	}
	if (convar == g_Cvarwarmuppreexec)
	{
		strcopy(g_warmuppreexec, sizeof(g_warmuppreexec), newValue);
	}
	if (convar == g_Cvarwarmuppostexec)
	{
		strcopy(g_warmuppostexec, sizeof(g_warmuppostexec), newValue);
	}
	if (convar == g_Cvarremoveweps)
	{
		if (newValue[0] == '1')
		{
			g_removeweps = true;
		}
		else
		{
		  g_removeweps = false;
		}
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hAdminMenu = INVALID_HANDLE;
	}
}
 
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	hAdminMenu = topmenu;
	new TopMenuObject:obj_blingoptions = AddToTopMenu(hAdminMenu,"Bling Options",TopMenuObject_Category,Bling_CategoryHandler,INVALID_TOPMENUOBJECT);
	new TopMenuObject:obj_blingrestrict = AddToTopMenu(hAdminMenu,"Bling Restrict Options",TopMenuObject_Category,Bling_RestrictCategoryHandler,INVALID_TOPMENUOBJECT);
	new Handle:BlingOptions = CreateKeyValues("Bling");
	if (FileToKeyValues(BlingOptions, "addons/sourcemod/configs/bling_menu_settings.txt"))
	{
		if (KvJumpToKey(BlingOptions, "Bling Options"))
		{
			decl String:menuitem[255];
			decl String:status[64];
			decl String:override[64];
			KvGotoFirstSubKey(BlingOptions);
			do
			{
				KvGetSectionName(BlingOptions, menuitem, sizeof(menuitem));
				KvGetString(BlingOptions, "status", status, sizeof(status));
				KvGetString(BlingOptions, "override", override, sizeof(override));
//				LogMessage("Menuitem: %s = Key: status, Value: %s | Key: override, Value: %s", menuitem, status, override);
				if (StrEqual(status, "enabled", false))
				{
					AddToTopMenu(hAdminMenu,menuitem,TopMenuObject_Item,Bling_MenuHandler,obj_blingoptions,override,ADMFLAG_GENERIC);
				}
			} while (KvGotoNextKey(BlingOptions));
			KvRewind(BlingOptions);
		}
		else
		{
			LogError("Bling: addons/sourcemod/configs/bling_menu_settings.txt - Bling Options section contains errors, please check the syntax.");
		}
		if (KvJumpToKey(BlingOptions, "Bling Restrict Options"))
		{
			decl String:menuitem[255];
			decl String:status[64];
			decl String:override[64];
			decl String:info[64];
			KvGotoFirstSubKey(BlingOptions);
			do
			{
				KvGetSectionName(BlingOptions, menuitem, sizeof(menuitem));
				KvGetString(BlingOptions, "status", status, sizeof(status));
				KvGetString(BlingOptions, "override", override, sizeof(override));
				KvGetString(BlingOptions, "info", info, sizeof(override));
//				LogMessage("Menuitem: %s = Key: status, Value: %s | Key: override, Value: %s", menuitem, status, override);
				if (StrEqual(status, "enabled", false))
				{
					AddToTopMenu(hAdminMenu,menuitem,TopMenuObject_Item,Bling_RestrictMenuHandler,obj_blingrestrict,override,ADMFLAG_GENERIC, info);
				}
			} while (KvGotoNextKey(BlingOptions));
		}
		else
		{
			LogError("Bling: addons/sourcemod/configs/bling_menu_settings.txt - Bling Options section contains errors, please check the syntax.");
		}		
	}
	else
	{
		LogError("Bling: addons/sourcemod/configs/bling_menu_settings.txt - Unable to import key value pairs.");		
	}
	CloseHandle(BlingOptions);
}

public Bling_RestrictMenuHandler(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	new String:obj_str[64];
	new String:wepname[64];
	GetTopMenuObjName(topmenu, object_id, obj_str, sizeof(obj_str));
	GetTopMenuInfoString(topmenu, object_id, wepname, sizeof(wepname));
	if (action == TopMenuAction_DisplayOption)
	{
		if (StrEqual(g_onlyweapon, wepname, false))
		{
			Format(buffer, maxlength, "%s %t: %t", wepname, "menu_only", "menu_enabled");
		}
		else
		{
			Format(buffer, maxlength, "%s %t", wepname, "menu_only");
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (StrEqual(g_onlyweapon, wepname, false))
		{
			SetConVarString(g_Cvaronlyweapon, "none");
		}
		else
		{
			SetConVarString(g_Cvaronlyweapon, wepname);
		}
		RedisplayAdminMenu(Handle:hAdminMenu,param);		
	}
}

public Bling_MenuHandler(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	new String:obj_str[64];
	GetTopMenuObjName(topmenu, object_id, obj_str, sizeof(obj_str));
	if (action == TopMenuAction_DisplayOption)
	{
		if (StrEqual(obj_str, "sm_bling_removeweps", false))
		{
			if (g_removeweps)
			{
				Format(menutext, maxlength, "%t: %t", "menu_removeweps", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_removeweps", "menu_disabled");
			}
		}
		if (StrEqual(obj_str, "sm_bling_warmup", false))
		{
			if (g_warmup)
			{
				Format(menutext, maxlength, "%t: %t", "menu_warmup", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_warmup", "menu_disabled");
			}
		}
		if (StrEqual(obj_str, "sm_bling_scoutnoscope", false))
		{
			if (g_scoutnoscope)
			{
				Format(menutext, maxlength, "%t: %t", "menu_noscopescout", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_noscopescout", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_awpnoscope", false))
		{
			if (g_awpnoscope)
			{
				Format(menutext, maxlength, "%t: %t", "menu_noscopeawp", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_noscopeawp", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_g3sg1noscope", false))
		{
			if (g_g3sg1noscope)
			{
				Format(menutext, maxlength, "%t: %t", "menu_noscopeg3sg1", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_noscopeg3sg1", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_sg550noscope", false))
		{
			if (g_sg550noscope)
			{
				Format(menutext, maxlength, "%t: %t", "menu_noscopesg550", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_noscopesg550", "menu_disabled");
			}
		}		
		else if (StrEqual(obj_str, "sm_bling_headshot", false))
		{
			if (g_headshot)
			{
				Format(menutext, maxlength, "%t: %t", "menu_headshotonly", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_headshotonly", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_headshotsounds", false))
		{
			if (g_headshotsounds)
			{
				Format(menutext, maxlength, "%t: %t", "menu_headshotsounds", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_headshotsounds", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_knifekillsounds", false))
		{
			if (g_knifekillsounds)
			{
				Format(menutext, maxlength, "%t: %t", "menu_knifekillsounds", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_knifekillsounds", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_bulletpath", false))
		{
			if (g_bulletpath)
			{
				Format(menutext, maxlength, "%t: %t", "menu_laserbulletpaths", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_laserbulletpaths", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_ragdolldissolver", false))
		{
			if (g_dissolver == 0)
			{
				Format(menutext, maxlength, "%t: %t", "menu_ragdolldissolver", "menu_disabled");
			}
			else if (g_dissolver == 1)
			{
				Format(menutext, maxlength, "%t: %t", "menu_ragdolldissolver", "menu_random");
			}
			else if (g_dissolver == 2)
			{
				Format(menutext, maxlength, "%t: %t", "menu_ragdolldissolver", "menu_energy");
			}
			else if (g_dissolver == 3)
			{
				Format(menutext, maxlength, "%t: %t", "menu_ragdolldissolver", "menu_energyelectrical");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_oneshotkill", false))
		{
			if (g_oneshotkill)
			{
				Format(menutext, maxlength, "%t: %t", "menu_oneshotkill", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_oneshotkill", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_blood", false))
		{
			if (g_blood)
			{
				Format(menutext, maxlength, "%t: %t", "menu_bloodeffects", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_bloodeffects", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_noblock", false))
		{
			if (g_noblock)
			{
				Format(menutext, maxlength, "%t: %t", "menu_noblock", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_noblock", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_unlimitedhe", false))
		{
			if (g_unlimitedhe)
			{
				Format(menutext, maxlength, "%t: %t", "menu_unlimitedhe", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_unlimitedhe", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_unlimitedflash", false))
		{
			if (g_unlimitedflash)
			{
				Format(menutext, maxlength, "%t: %t", "menu_unlimitedflash", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_unlimitedflash", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_unlimitedsmoke", false))
		{
			if (g_unlimitedsmoke)
			{
				Format(menutext, maxlength, "%t: %t", "menu_unlimitedsmoke", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_unlimitedsmoke", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_unlimitedammo", false))
		{
			if (g_unlimitedammo)
			{
				Format(menutext, maxlength, "%t: %t", "menu_unlimitedammo", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_unlimitedammo", "menu_disabled");
			}
		}
		else if (StrEqual(obj_str, "sm_bling_mugging", false))
		{
			if (g_mugging == 0)
			{
				Format(menutext, maxlength, "%t: %t", "menu_mugging", "menu_disabled");
			}
			if (g_mugging == 1)
			{
				Format(menutext, maxlength, "%t: %t", "menu_mugging", "menu_mugging_cash");
			}
			else if (g_mugging == 2)
			{
				Format(menutext, maxlength, "%t: %t", "menu_mugging", "menu_mugging_health");
			}
			else if (g_mugging == 3)
			{
				Format(menutext, maxlength, "%t: %t", "menu_mugging", "menu_mugging_cashhealth");
			}
		}		
		else if (StrEqual(obj_str, "sm_bling_bank", false))
		{
			if (g_bank)
			{
				Format(menutext, maxlength, "%t: %t", "menu_bank", "menu_enabled");
			}
			else
			{
				Format(menutext, maxlength, "%t: %t", "menu_bank", "menu_disabled");
			}
		}				
		Format(buffer, maxlength, menutext);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (StrEqual(obj_str, "sm_bling_removeweps", false))
		{
			if (g_removeweps)
			{
				SetConVarBool(Handle:g_Cvarremoveweps, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarremoveweps, true);
			}
		}
		if (StrEqual(obj_str, "sm_bling_warmup", false))
		{
			if (g_warmup)
			{
				SetConVarBool(Handle:g_Cvarwarmup, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarwarmup, true);
			}
		}
		if (StrEqual(obj_str, "sm_bling_scoutnoscope", false))
		{
			if (g_scoutnoscope)
			{
				SetConVarBool(Handle:g_Cvarscoutnoscope, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarscoutnoscope, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_awpnoscope", false))
		{
			if (g_awpnoscope)
			{
				SetConVarBool(Handle:g_Cvarawpnoscope, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarawpnoscope, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_g3sg1noscope", false))
		{
			if (g_g3sg1noscope)
			{
				SetConVarBool(Handle:g_Cvarg3sg1noscope, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarg3sg1noscope, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_sg550noscope", false))
		{
			if (g_sg550noscope)
			{
				SetConVarBool(Handle:g_Cvarsg550noscope, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarsg550noscope, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_headshot", false))
		{
			if (g_headshot)
			{
				SetConVarBool(Handle:g_Cvarheadshot, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarheadshot, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_headshotsounds", false))
		{
			if (g_headshotsounds)
			{
				SetConVarBool(Handle:g_Cvarheadshotsounds, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarheadshotsounds, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_knifekillsounds", false))
		{
			if (g_knifekillsounds)
			{
				SetConVarBool(Handle:g_Cvarknifekillsounds, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarknifekillsounds, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_bulletpath", false))
		{
			if (g_bulletpath)
			{
				SetConVarBool(Handle:g_Cvarbulletpath, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarbulletpath, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_ragdolldissolver", false))
		{
			if (g_dissolver == 0)
			{
				SetConVarInt(Handle:g_Cvardissolver, 1);
			}
			else if (g_dissolver == 1)
			{
				SetConVarInt(Handle:g_Cvardissolver, 2);
			}
			else if (g_dissolver == 2)
			{
				SetConVarInt(Handle:g_Cvardissolver, 3);
			}
			else if (g_dissolver == 3)
			{
				SetConVarInt(Handle:g_Cvardissolver, 0);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_oneshotkill", false))
		{
			if (g_oneshotkill)
			{
				SetConVarBool(Handle:g_Cvaroneshotkill, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvaroneshotkill, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_blood", false))
		{
			if (g_blood)
			{
				SetConVarBool(Handle:g_Cvarblood, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarblood, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_noblock", false))
		{
			if (g_noblock)
			{
				SetConVarBool(Handle:g_Cvarnoblock, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarnoblock, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_unlimitedhe", false))
		{
			if (g_unlimitedhe)
			{
				SetConVarBool(Handle:g_Cvarunlimitedhe, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarunlimitedhe, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_unlimitedflash", false))
		{
			if (g_unlimitedflash)
			{
				SetConVarBool(Handle:g_Cvarunlimitedflash, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarunlimitedflash, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_unlimitedsmoke", false))
		{
			if (g_unlimitedsmoke)
			{
				SetConVarBool(Handle:g_Cvarunlimitedsmoke, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarunlimitedsmoke, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_unlimitedammo", false))
		{
			if (g_unlimitedammo)
			{
				SetConVarBool(Handle:g_Cvarunlimitedammo, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarunlimitedammo, true);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_mugging", false))
		{
			if (g_mugging == 0)
			{
				SetConVarInt(Handle:g_Cvarmugging, 1);
			}
			else if (g_mugging == 1)
			{
				SetConVarInt(Handle:g_Cvarmugging, 2);
			}
			else if (g_mugging == 2)
			{
				SetConVarInt(Handle:g_Cvarmugging, 3);
			}
			else if (g_mugging == 3)
			{
				SetConVarInt(Handle:g_Cvarmugging, 0);
			}
		}
		else if (StrEqual(obj_str, "sm_bling_bank", false))
		{
			if (g_bank)
			{
				SetConVarBool(Handle:g_Cvarbank, false);
			}
			else
			{
				SetConVarBool(Handle:g_Cvarbank, true);
			}
		}
		RedisplayAdminMenu(Handle:hAdminMenu,param);
	}
}

public Bling_CategoryHandler(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	new String:menusorterror[512];
	if (!LoadTopMenuConfig(topmenu, "addons/sourcemod/configs/bling_menu_sorting.txt", menusorterror, sizeof(menusorterror)))
	{
		LogError("Bling: Menu Sorting Error: %s", menusorterror);
	}

	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "%t:", "menutitle_blingfunoptions");
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%t", "menutitle_blingfunoptions");
	}
}

public Bling_RestrictCategoryHandler(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "%t:", "menutitle_blingweaponoptions");
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%t", "menutitle_blingweaponoptions");
	}
}

public OnClientPostAdminCheck(client)
{
	if (!StrEqual(g_joinsound, ""))
	{
		CreateTimer(1.0, PlayJoinSound, client);
	}
}

public OnClientCookiesCached(client)
{
	g_cookiescached[client] = true;
}

public CheckWeaponString(const String:weaponstring[])
{
	if (!StrEqual(weaponstring, "", false))
	{
		if (StrEqual(weaponstring, "random", false))
		{
			SetRandomSeed(GetTime());
			warmupweapons[0] = weapons[GetRandomInt(0,MAXWEAPONS-1)];
			warmupweapons[1] = "";
			warmupweapons[2] = "";
		}
		else
		{
			new weaponsfound = 0;
			weaponsfound = ExplodeString(weaponstring, ",", warmupweapons, 5, 64);
			if (weaponsfound > 0)
			{
				for (new w = 0; w <= 2; w++)
				{
					if (strlen(warmupweapons[w]) > 0)
					{
						new bool:valid = false;
						for (new i = 0; i <= MAXWEAPONS - 1; i++)
						{
							if (StrEqual(warmupweapons[w], weapons[i], false))
							{
								valid = true;
							}
						}
						if (!valid)
						{
							LogMessage("Setting to hegrenade!");
							warmupweapons[0] = "hegrenade";
							warmupweapons[1] = "";
							warmupweapons[2] = "";
							PrintToServer("[Bling] Warmup Weapon selection: %s, is not valid.  Please try setting sm_bling_warmupweapons again.", warmupweapons[w]);
							LogError("[Bling] Warmup Weapon selection: %s, is not valid.  Please try setting sm_bling_warmupweapons again.", warmupweapons[w]);
							return;
						}
					}
				}
			}
		}
	}
}

public Action:CancelWarmup()
{
	SetConVarBool(g_Cvarwarmupactive, false, false, false);
	g_warmuptimer = INVALID_HANDLE;
	isWarmup = false;
	ServerCommand("mp_restartgame 1");
	decl String:buffer[32] = "cfg/";
	StrCat(buffer, sizeof(buffer), g_warmuppostexec);
	if (FileExists(buffer))
	{
		ServerCommand("exec %s", g_warmuppostexec);
	}
	if (g_warmupff)
	{
		ServerCommand("mp_friendlyfire 1");
	}
}  

public Action:Countdown(Handle:timer)
{
	if (isWarmup)
	{
		if (timesrepeated >= 1)
		{
			PrintHintTextToAll("%t: %i", "warmup time", timesrepeated);
			timesrepeated--;
		}
		else if (timesrepeated == 0)
		{
			timesrepeated = g_warmuptime;
			CancelWarmup();
			return Plugin_Stop;
		}
	}
	else
	{
		timesrepeated = g_warmuptime;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:SpawnPlayer(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		CS_RespawnPlayer(client);
	}
}

public Action:Command_GiveCash(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_givecash <#userid|name|@all|@ct|@t> <amount>");
		return Plugin_Handled;
	}
	new String:arg1[32];
	new String:arg2[32];
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	GetCmdArg(1,arg1, sizeof(arg1));
	GetCmdArg(2,arg2, sizeof(arg2));
	new arg = StringToInt(arg2);
	if ((target_count = ProcessTargetString(arg1,client,target_list,MAXPLAYERS,COMMAND_FILTER_NO_IMMUNITY,target_name,sizeof(target_name),tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	if (arg > 0 && arg < 16000)
	{
		for (new i = 0; i < target_count; i++)
		{
			new targetmoney = GetPlayerMoney(target_list[i]);
			targetmoney = targetmoney + arg;
			if (targetmoney > 16000)
			{
				targetmoney = 16000;
			}
			SetPlayerMoney(target_list[i], targetmoney);
		}
		if (tn_is_ml)
		{
			ShowActivity2(client, "[SM] ", "Gave %t $%i!", target_name, arg);
		}
		else
		{
			ShowActivity2(client, "[SM] ", "Gave %s $%i!", target_name, arg);
		}
	}
	return Plugin_Handled;
}

public Action:Command_GiveItem(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_giveitem <#userid|name|@all|@ct|@t> <item> (ie: weapon_awp)");
		return Plugin_Handled;
	}
	new String:arg1[32];
	new String:arg2[32];
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	GetCmdArg(1,arg1, sizeof(arg1));
	GetCmdArg(2,arg2, sizeof(arg2));
	if ((target_count = ProcessTargetString(arg1,client,target_list,MAXPLAYERS,COMMAND_FILTER_NO_IMMUNITY,target_name,sizeof(target_name),tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		GivePlayerItem(target_list[i], arg2);
	}
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Gave %t %s.", target_name, arg2);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Gave %s $%s.", target_name, arg2);
	}
	return Plugin_Handled;
}
public Action:Command_SetHealth(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sethealth <#userid|name|@all|@ct|@t> <amount>");
		return Plugin_Handled;
	}
	new String:arg1[32];
	new String:arg2[32];
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	GetCmdArg(1,arg1, sizeof(arg1));
	GetCmdArg(2,arg2, sizeof(arg2));
	new arg = StringToInt(arg2);
	if ((target_count = ProcessTargetString(arg1,client,target_list,MAXPLAYERS,COMMAND_FILTER_NO_IMMUNITY,target_name,sizeof(target_name),tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	if (arg > 0 && arg < 1000)
	{
		for (new i = 0; i < target_count; i++)
		{
			SetEntData(target_list[i], g_iHealth, arg, 4, true);
		}
		if (tn_is_ml)
		{
			ShowActivity2(client, "[SM] ", "Set %t to %i health.", target_name, arg);
		}
		else
		{
			ShowActivity2(client, "[SM] ", "Gave %s to %i health.", target_name, arg);
		}
	}
	return Plugin_Handled;
}

public Action:Command_Respawn(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_respawn <#userid|name|@all|@ct|@t>");
		return Plugin_Handled;
	}
	new String:arg1[32];
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	GetCmdArg(1,arg1, sizeof(arg1));
	if ((target_count = ProcessTargetString(arg1,client,target_list,MAXPLAYERS,COMMAND_FILTER_DEAD,target_name,sizeof(target_name),tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		CreateTimer(0.1, SpawnPlayer, target_list[i]);
	}
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Respawned %t.", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Respawned %s.", target_name);
	}
	return Plugin_Handled;
}

public Action:Command_Balance(client, args)
{
	if (g_bank)
	{
		if (!g_cookiescached[client])
		{
			PrintToChat(client, "%t %t", "bling bank", "bank not ready");
			return Plugin_Handled;
		}
		new String:bankcookie[64];
		GetClientCookie(client, g_bankcookie, bankcookie, sizeof(bankcookie));
		if (StrEqual(bankcookie, ""))
		{
			SetClientCookie(client, g_bankcookie, "0");
			GetClientCookie(client, g_bankcookie, bankcookie, sizeof(bankcookie));
		}
		if (StringToInt(bankcookie) > g_bankmaxbalance)
		{
			IntToString(g_bankmaxbalance, bankcookie, sizeof(bankcookie));
			SetClientCookie(client, g_bankcookie, bankcookie);
		}
		PrintToChat(client, "%t %t: $%s", "bling bank", "bank balance", bankcookie);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_Deposit(client, args)
{
	if (g_bank)
	{
		if (!g_cookiescached[client])
		{
			PrintToChat(client, "%t %t", "bling bank", "bank not ready");
			return Plugin_Handled;
		}
		new String:bankcookie[64];
		GetClientCookie(client, g_bankcookie, bankcookie, sizeof(bankcookie));
		if (StrEqual(bankcookie, ""))
		{
			SetClientCookie(client, g_bankcookie, "0");
		}
		if (args < 1)
		{
			PrintToChat(client, "%t %t", "bling bank", "bank usage");
		}
		else
		{
			if (StringToInt(bankcookie) > g_bankmaxbalance)
			{
				IntToString(g_bankmaxbalance, bankcookie, sizeof(bankcookie));
				SetClientCookie(client, g_bankcookie, bankcookie);
			}
			new String:buffer[64];
			new deposit;
			GetCmdArg(1, buffer, sizeof(buffer));
			if (StrEqual(buffer, "all", false))
			{
				deposit = GetPlayerMoney(client);
			}
			else
			{
				deposit = StringToInt(buffer);
			}
			if (deposit > GetPlayerMoney(client))
			{
				PrintToChat(client, "%t %t", "bling bank", "bank deposit insufficient");
			}
			else
			{
				if ((StringToInt(bankcookie) + deposit) > g_bankmaxbalance)
				{
					new maxdiff = (g_bankmaxbalance - StringToInt(bankcookie));
					deposit = maxdiff;
					PrintToChat(client, "%t %t", "bling bank", "bank maximum balance");
				}
				SetPlayerMoney(client, (GetPlayerMoney(client) - deposit));
				new newbalance = (deposit + StringToInt(bankcookie));
				new String:deposit1[64];
				IntToString(newbalance, deposit1, sizeof(deposit1));
				SetClientCookie(client, g_bankcookie, deposit1);
				PrintToChat(client, "%t %t: $%i - %t: $%i", "bling bank", "bank deposit", deposit, "available balance", newbalance);
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_Withdraw(client, args)
{
	if (g_bank)
	{
		if (!g_cookiescached[client])
		{
			PrintToChat(client, "%t %t", "bling bank", "bank not ready");
			return Plugin_Handled;
		}
		new String:bankcookie[64];
		GetClientCookie(client, g_bankcookie, bankcookie, sizeof(bankcookie));
		if (StrEqual(bankcookie, ""))
		{
			SetClientCookie(client, g_bankcookie, "0");
		}
		if (args < 1)
		{
			PrintToChat(client, "%t %t", "bling bank", "bank usage");
		}
		else
		{
			if (StringToInt(bankcookie) > g_bankmaxbalance)
			{
				IntToString(g_bankmaxbalance, bankcookie, sizeof(bankcookie));
				SetClientCookie(client, g_bankcookie, bankcookie);
			}
			new String:buffer[64];
			new withdraw;
			GetCmdArg(1, buffer, sizeof(buffer));
			if (StrEqual(buffer, "all", false) || StrEqual(buffer, "max", false))
			{
				if ((StringToInt(bankcookie) + GetPlayerMoney(client)) <= 16000)
				{
					withdraw = StringToInt(bankcookie);
				}
				else
				{
					withdraw = (16000 - GetPlayerMoney(client));
				}
			}
			else
			{
				withdraw = StringToInt(buffer);
			}
			if (withdraw > StringToInt(bankcookie))
			{
				PrintToChat(client, "%t %t", "bling bank", "bank withdraw insufficient");
			}
			else if ((withdraw + GetPlayerMoney(client)) > 16000)
			{
				PrintToChat(client, "%t %t", "bling bank", "bank withdraw overage");
			}
			else
			{
				SetPlayerMoney(client, (GetPlayerMoney(client) + withdraw));
				new newbalance = (StringToInt(bankcookie) - withdraw);
				new String:withdraw1[64];
				IntToString(newbalance, withdraw1, sizeof(withdraw1));
				SetClientCookie(client, g_bankcookie, withdraw1);
				PrintToChat(client, "%t %t: $%i - %t: $%i", "bling bank", "bank withdraw", withdraw, "available balance", newbalance);
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:RestrictWeapons(Handle:timer, any:client)
{
	if ((g_roundrestricted && IsClientInGame(client) && !g_roundrestrictednxtrnd) || isWarmup)
	{
		new String:buffer[32];
		new KnifeEnt;
		new bool:hasweapon = false;
		new bool:removeitem = true;
		decl String:weaponname[64] = "";
		Format(buffer, sizeof(buffer), "weapon_%s", g_onlyweapon);
		static Slot = 0, EntityIndex = 0;
		for (Slot = 0; Slot <= (32 * 4); Slot += 4)
		{
			EntityIndex = GetEntDataEnt2(client, (g_weapons + Slot));
			if (EntityIndex != 0 && IsValidEdict(EntityIndex))
			{
				GetEdictClassname(EntityIndex, weaponname, sizeof(weaponname));
				if (!StrEqual(weaponname, "worldspawn", false))
				{
					if (isWarmup)
					{
						for (new i = 0; i <= 2; i++)
						{
//							PrintToChatAll("Has Weapon | Slot: %i | Weapon: %s", Slot, weaponname);
							Format(buffer, sizeof(buffer), "weapon_%s", warmupweapons[i]);
							if (StrEqual(weaponname, "weapon_knife", false))
							{
								KnifeEnt = EntityIndex;
								removeitem = false;
							}
							else
							{
								removeitem = true;
							}
						}
					}
					else
					{
						if (StrEqual(weaponname, buffer, false))
						{
	//						PrintToChatAll("Has Weapon | Slot: %i | Weapon: %s", Slot, weaponname);
							hasweapon = true;
							removeitem = false;
						}
						if (StrEqual(weaponname, "weapon_knife", false))
						{
							KnifeEnt = EntityIndex;
							removeitem = false;
	//						PrintToChatAll("Has Knife | Slot: %i | Weapon: %s | EntityIndex: %i", Slot, weaponname, KnifeEnt);						
						}
						if (StrEqual(weaponname, "weapon_hegrenade", false) && g_unlimitedhe)
						{
							removeitem = false;
						}
						else if (StrEqual(weaponname, "weapon_flashbang", false) && g_unlimitedflash)
						{
							removeitem = false;
						}
						else if (StrEqual(weaponname, "weapon_smokegrenade", false) && g_unlimitedsmoke)
						{
							removeitem = false;
						}
						else if (StrEqual(weaponname, "weapon_c4", false) && g_unlimitedsmoke)
						{
							removeitem = false;
						}
					}
					if (removeitem)
					{
//						PrintToChatAll("Remove Item | Slot: %i | Weapon: %s", Slot, weaponname);
						RemovePlayerItem(client, EntityIndex);
						RemoveEdict(EntityIndex);
						removeitem = true;
					}
				}
			}
		}
		if ((!hasweapon && IsPlayerAlive(client)) && !isWarmup)
		{
			GivePlayerItem(client, buffer);
		}
		else if (isWarmup)
		{
			for (new i = 0; i <= 2; i++)
			{
//				PrintToChatAll("Warmup Weapon %i: %s", i, warmupweapons[i]);
				if (!StrEqual(warmupweapons[i], "", false))
				{
					if (!StrEqual(warmupweapons[i], "knife"))
					{
						Format(buffer, sizeof(buffer), "weapon_%s", warmupweapons[i]);
//						PrintToChatAll("Giving Warmup Weapon: %s", warmupweapons[i]);
						GivePlayerItem(client, buffer);
					}
					else
					{
						EquipPlayerWeapon(client, KnifeEnt);
					}
				}
			}
		}
		if (StrEqual(g_onlyweapon, "knife", false) && !isWarmup)
		{
			EquipPlayerWeapon(client, KnifeEnt);
		}
		Slot = 0;
		EntityIndex = 0;
	}
}

public Action:Command_Buy(client, args)
{
  if ((g_roundrestricted && IsClientInGame(client)) || isWarmup)
  {
    EmitSoundToClient(client, blockbuysound);
    PrintToChat(client, "%t %t", "bling", "deny buy");
    return Plugin_Handled;
  }
  return Plugin_Continue;
}

public Action:PlayJoinSound(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		EmitSoundToClient(client, g_joinsound);
	}
}

public Action:GiveScout(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		GivePlayerItem(client, "weapon_scout");
	}
}

public Action:GiveAwp(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		GivePlayerItem(client, "weapon_awp");
	}
}

public Action:GiveG3(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		GivePlayerItem(client, "weapon_g3sg1");
	}
}

public Action:GiveSG(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		GivePlayerItem(client, "weapon_sg550");
	}
}

public Action:GiveNades(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (g_unlimitedhe && !g_unlimitedhenxtrnd)
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}
		if (g_unlimitedflash && !g_unlimitedflashnxtrnd)
		{
			GivePlayerItem(client, "weapon_flashbang");
			GivePlayerItem(client, "weapon_flashbang");
		}
		if (g_unlimitedsmoke && !g_unlimitedsmokenxtrnd)
		{
			GivePlayerItem(client, "weapon_smokegrenade");
		}
	}
}

public DrawLaser(client)
{
	new Float:clientOrigin[3], Float:impactOrigin[3];
	new Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client,vAngles);
	new color[4];

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer, client);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(impactOrigin, trace);
		CloseHandle(trace);
		GetClientEyePosition(client, clientOrigin);
		clientOrigin[2] -= 1;
		if (GetClientTeam(client) == 3)
		{
			color = {75, 75, 255, 255};
		}
		else
		{
			color = {255, 75, 75, 255};
		}
		TE_SetupBeamPoints(clientOrigin, impactOrigin, g_laser, 0, 0, 0, 0.25, 1.0, 1.0, 10, 0.0, color, 0);
		TE_SendToAll(); 
	}
}

public Action:DissolveRagdoll(Handle:timer, any:client)
{
	if (!IsValidEntity(client) || IsPlayerAlive(client))
	{
		return;
	}
	else if (IsClientInGame(client))
	{
		new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

		if (ragdoll < 0)
		{
			return;
		}
		new String:dname[32];
		Format(dname, sizeof(dname), "dis_%d", client);
		new entid = CreateEntityByName("env_entity_dissolver");

		new String:dtype[32];
		if (g_dissolver == 1)
		{
			IntToString(GetRandomInt(0, 2), dtype, sizeof(dtype));
		}
		else if (g_dissolver == 2)
		{
			IntToString(0, dtype, sizeof(dtype));
		}
		else if (g_dissolver == 3)
		{
			IntToString(1, dtype, sizeof(dtype));
		}
		else
		{
			IntToString(0, dtype, sizeof(dtype));
		}
		if (entid > 0)
		{
			DispatchKeyValue(ragdoll, "targetname", dname);
			DispatchKeyValue(entid, "dissolvetype", dtype);
			DispatchKeyValue(entid, "target", dname);
			AcceptEntityInput(entid, "Dissolve");
			AcceptEntityInput(entid, "kill");
		}
	}
}

public bool:TraceEntityFilterPlayer(entity, mask, any:data)
{
	return data != entity;
}

GenerateBloodSpray(victim)
{
	if (IsClientInGame(victim))
	{
		new Float:vichead[3];
		GetClientEyePosition(victim, vichead);
		vichead[2] += 10;
		TE_SetupBloodSprite(vichead, NULL_VECTOR, g_bloodcolor, 15, g_bloodsprite, g_bloodmodel);
		TE_SendToAll();
	}
}

GenerateBlood(victim)
{
	if (IsClientInGame(victim))
	{
		new bloodent = CreateEntityByName("env_blood");
		if ((bloodent == -1) || (!IsValidEdict(bloodent)))
		{
			return;
		}
		new String:bloodamount[6];
		new String:bloodflags[6];
		IntToString(g_bloodamount, bloodamount, sizeof(bloodamount));
		IntToString(g_bloodflags, bloodflags, sizeof(bloodflags));
		DispatchSpawn(bloodent);
		DispatchKeyValue(bloodent, "spawnflags", bloodflags);
		DispatchKeyValue(bloodent, "amount", bloodamount);
		DispatchKeyValue(bloodent, "color", "0");
		AcceptEntityInput(bloodent, "emitblood", victim);
		AcceptEntityInput(bloodent, "kill", victim);
		RemoveEdict(bloodent);
	}
}

GetPlayerMoney(client)
{
	return GetEntData(client, g_iAccount);
}

SetPlayerMoney(client, amount)
{
	SetEntData(client, g_iAccount, amount);
}

// Thanks to Kigen for the entity remover!
RemoveGroundWeapons()
{
	new maxent = GetMaxEntities(), String:name[64];
	for (new i = GetMaxClients(); i < maxent; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, name, sizeof(name));
			if ((StrContains(name, "weapon_") != -1 || StrContains(name, "item_") != -1) && GetEntDataEnt2(i, g_ownerentity) == -1)
			{
				if (!StrEqual(name, "weapon_c4", false))
				{
					RemoveEdict(i);
				}
			}
		}
	}
}

public Action:EventGameStart(Handle:event,const String:name[],bool:dontBroadcast)
{
}

public Action:EventRoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (g_removeweps)
	{
		RemoveGroundWeapons();
	}
}

public Action:EventRoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (g_roundrestricted && g_roundrestrictednxtrnd)
	{
		g_roundrestrictednxtrnd = false;
	}
	if (g_unlimitedhe && g_unlimitedhenxtrnd)
	{
		g_unlimitedhenxtrnd = false;
	}
	if (g_unlimitedflash && g_unlimitedflashnxtrnd)
	{
		g_unlimitedflashnxtrnd = false;
	}
	if (g_unlimitedsmoke && g_unlimitedsmokenxtrnd)
	{
		g_unlimitedsmokenxtrnd = false;
	}
	if (g_oneshotkill && g_oneshotkillnxtrnd)
	{
		g_oneshotkillnxtrnd = false;
	}
	return Plugin_Continue;
}

public Action:EventWeaponZoom(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (g_scoutnoscope)
	{
		if (StrEqual(weaponname, "weapon_scout", false))
		{
			new weapon = GetPlayerWeaponSlot(client, 0);
			if (IsValidEdict(weapon))
			{
				RemovePlayerItem(client, weapon);
				RemoveEdict(weapon);
				CreateTimer(0.1, GiveScout, client);
				PrintHintText(client, "%t", "scope disabled");
			}
		}
	}
	if (g_awpnoscope)
	{
		if (StrEqual(weaponname, "weapon_awp", false))
		{
			new weapon = GetPlayerWeaponSlot(client, 0);
			if (IsValidEdict(weapon))
			{
				RemovePlayerItem(client, weapon);
				RemoveEdict(weapon);
				CreateTimer(0.1, GiveAwp, client);
				PrintHintText(client, "%t", "Not Allowed");
			}
		}
	}
	if (g_g3sg1noscope)
	{
		if (StrEqual(weaponname, "weapon_g3sg1", false))
		{
			new weapon = GetPlayerWeaponSlot(client, 0);
			if (IsValidEdict(weapon))
			{
				RemovePlayerItem(client, weapon);
				RemoveEdict(weapon);
				CreateTimer(0.1, GiveG3, client);
				PrintHintText(client, "%t", "Not Allowed");
			}
		}
	}
	if (g_sg550noscope)
	{
		if (StrEqual(weaponname, "weapon_sg550", false))
		{
			new weapon = GetPlayerWeaponSlot(client, 0);
			if (IsValidEdict(weapon))
			{
				RemovePlayerItem(client, weapon);
				RemoveEdict(weapon);
				CreateTimer(0.1, GiveSG, client);
				PrintHintText(client, "%t", "Not Allowed");
			}
		}
	}	
	return Plugin_Continue;
}

public Action:EventWeaponFire(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bulletpath)
	{
		DrawLaser(client);
	}
	if (g_unlimitedammo)
	{
		new iWeapon = GetEntDataEnt2(client, FindSendPropInfo("CCSPlayer", "m_hActiveWeapon"));
		new ammo = GetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"));
		SetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), ammo + 1);
	}
	return Plugin_Continue;
}

public Action:EventPlayerHurt(Handle:event, const String:name[],bool:dontBroadcast)
{
	new hitgroup = GetEventInt(event, "hitgroup");
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new dhealth = GetEventInt(event, "dmg_health");
	new darmor = GetEventInt(event, "dmg_armor");
	new health = GetEventInt(event, "health");
	new armor = GetEventInt(event, "armor");

	if (hitgroup == 1 && health < 1)
	{
		if (g_blood)
		{
			GenerateBlood(victim);
			GenerateBloodSpray(victim);
		}
		if (g_headshotsounds)
		{
			if (g_headshotsoundsemit)
			{
				new Float:vicpos[3];
				GetClientEyePosition(attacker, vicpos);
				EmitAmbientSound(headsounds[GetRandomInt(0, soundsfound -1)], vicpos, attacker, SNDLEVEL_RAIDSIREN);
			}
			else
			{
				new Float:vicpos[3];
				GetClientEyePosition(victim, vicpos);
				EmitAmbientSound(headsounds[GetRandomInt(0, soundsfound -1)], vicpos, victim, SNDLEVEL_RAIDSIREN);
			}
		}
	}
	if (g_headshot)
	{
		if (hitgroup == 1)
		{
			return Plugin_Continue;
		}
		else if (attacker != victim && victim != 0 && attacker != 0)
		{
			if (dhealth > 0)
			{
				SetEntData(victim, g_iHealth, (health + dhealth), 4, true);
			}
			if (darmor > 0)
			{
				SetEntData(victim, g_Armor, (armor + darmor), 4, true);
			}
		}
	}
	return Plugin_Changed;
}

public EventHEGrenadeDetonate(Handle:event,const String:name[],bool:dontBroadcast)
{
	if ((g_roundrestricted && StrEqual(g_onlyweapon, "hegrenade", false)) || g_unlimitedhe || isWarmup)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if ((g_unlimitedhe && !isWarmup) || isWarmup)
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}
}

public EventFlashBangDetonate(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (g_unlimitedflash && !isWarmup)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_flashbang");
		}
	}
}

public EventSmokeGrenadeDetonate(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (g_unlimitedsmoke && !isWarmup)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_smokegrenade");
		}
	}
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weaponname[32];
	GetEventString(event, "weapon", weaponname, sizeof(weaponname));
	if ((isWarmup && g_warmuprespawn) || g_removeweps)
	{
		RemoveGroundWeapons();
		if (isWarmup && g_warmuprespawn)
		{
			CreateTimer(0.5, SpawnPlayer, victim);
		}
	}
	if (g_mugging > 0 && StrEqual(weaponname, "knife", false))
	{
		new String:victimname[128];
		new String:attackername[128];
		new String:mugstr[128];	
		GetClientName(victim,victimname,100);
		GetClientName(attacker,attackername,100);
		Format(mugstr, sizeof(mugstr), "%t %s %t!  %s %t ", "bling", victimname, "just_got_mugged", attackername, "stole");
		new stolen = 0;
		if (g_mugging == 1 || g_mugging == 3)
		{
			new Float:percent = GetConVarFloat(g_Cvarmuggingpercent);
			new victimmoney = GetPlayerMoney(victim);
			new attackermoney = GetPlayerMoney(attacker);
			stolen = RoundFloat(float(victimmoney) * percent);
			if (stolen > 16000)
			{
				stolen = 16000;
			}
			SetPlayerMoney(victim, (RoundFloat(float(victimmoney) - float(victimmoney) * percent)));
			SetPlayerMoney(attacker, (RoundFloat(float(attackermoney) + float(victimmoney) * percent)));
			new String:mugcashstr[128];
			Format(mugcashstr, sizeof(mugstr), "$%i", stolen);
			StrCat(mugstr, sizeof(mugstr), mugcashstr);
			if (g_mugging == 3)
			{
				new String:mughealthstr[128];
				SetEntData(attacker, g_iHealth, (GetEntData(attacker, g_iHealth) + g_mugginghealth), 4, true);
				Format(mughealthstr, sizeof(mugstr), " %t %i %t!", "and", g_mugginghealth, "health");
				StrCat(mugstr, sizeof(mugstr), mughealthstr);
			}
			
		}
		if (g_mugging == 2)
		{
			new String:mughealthstr[128];
			SetEntData(attacker, g_iHealth, (GetEntData(attacker, g_iHealth) + g_mugginghealth), 4, true);
			Format(mughealthstr, sizeof(mugstr), " %i %t!", g_mugginghealth, "health");
			StrCat(mugstr, sizeof(mugstr), mughealthstr);
		}
		PrintToChatAll(mugstr);
	}
	if (g_blood)
	{
		if (StrEqual(weaponname, "knife", false))
		{
			GenerateBlood(victim);
		}
	}
	if (g_knifekillsounds)
	{
		if (StrEqual(weaponname, "knife", false))
		{
			if (g_knifekillsoundsemit)
			{
				new Float:vicpos[3];
				GetClientEyePosition(attacker, vicpos);
				EmitAmbientSound(knifesounds[GetRandomInt(0, ksoundsfound -1)], vicpos, attacker, SNDLEVEL_RAIDSIREN);
			}
			else
			{
				new Float:vicpos[3];
				GetClientEyePosition(victim, vicpos);
				EmitAmbientSound(knifesounds[GetRandomInt(0, ksoundsfound -1)], vicpos, victim, SNDLEVEL_RAIDSIREN);
			}
		}
	}
	if (g_dissolver > 0)
	{
		CreateTimer(0.4, DissolveRagdoll, GetClientOfUserId(GetEventInt(event, "userid")));
	}
}

public Action:EventItemPickup(Handle:event, const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_roundrestricted && !g_roundrestrictednxtrnd && !isWarmup)
	{
		new String:item[64];
		GetEventString(event, "item", item, sizeof(item));
		if (!StrEqual(item, "knife", false) || !StrEqual(item, g_onlyweapon, false))
		{
			CreateTimer(0.1, RestrictWeapons, client);
		}
	}
	return Plugin_Continue;
}
public Action:EventPlayerSpawn(Handle:event, const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	if (g_oneshotkill && !g_oneshotkillnxtrnd && !isWarmup)
	{
		SetEntData(client, g_iHealth, 5, 4, true);
		SetEntData(client, g_Armor, 0, 4, true);
	}
	if (g_noblock && team > 1)
	{
		SetEntData(client, g_block, 2);
	}
	if ((g_roundrestricted && !g_roundrestrictednxtrnd) || isWarmup)
	{
		if (team > 1)
		{
			CreateTimer(0.1, RestrictWeapons, client);
		}
	}
	if (g_unlimitedhe || g_unlimitedflash || g_unlimitedsmoke && !isWarmup)
	{
		CreateTimer(0.1, GiveNades, client);
	}
	return Plugin_Continue;
}