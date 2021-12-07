#include <cssthrowingknives>
//#include <zr_lasermines>

#define DMG_GENERIC									0
#define DMG_CRUSH										(1 << 0)
#define DMG_BULLET									(1 << 1)
#define DMG_SLASH										(1 << 2)
#define DMG_BURN										(1 << 3)
#define DMG_VEHICLE									(1 << 4)
#define DMG_FALL										(1 << 5)
#define DMG_BLAST										(1 << 6)
#define DMG_CLUB										(1 << 7)
#define DMG_SHOCK										(1 << 8)
#define DMG_SONIC										(1 << 9)
#define DMG_ENERGYBEAM							(1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE		(1 << 11)
#define DMG_NEVERGIB								(1 << 12)
#define DMG_ALWAYSGIB								(1 << 13)
#define DMG_DROWN										(1 << 14)
#define DMG_TIMEBASED								(DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE								(1 << 15)
#define DMG_NERVEGAS								(1 << 16)
#define DMG_POISON									(1 << 17)
#define DMG_RADIATION								(1 << 18)
#define DMG_DROWNRECOVER						(1 << 19)
#define DMG_ACID										(1 << 20)
#define DMG_SLOWBURN								(1 << 21)
#define DMG_REMOVENORAGDOLL					(1 << 22)
#define DMG_PHYSGUN									(1 << 23)
#define DMG_PLASMA									(1 << 24)
#define DMG_AIRBOAT									(1 << 25)
#define DMG_DISSOLVE								(1 << 26)
#define DMG_BLAST_SURFACE						(1 << 27)
#define DMG_DIRECT									(1 << 28)
#define DMG_BUCKSHOT								(1 << 29)

#define NADE_DISTANCE 600.0
#define NADE_COLOR	{75,255,75,255}

//#define EXPLODE_SOUND	"ambient/explosions/explode_8.wav"

#define VERSION2 "by Franc1sco Franug"


// Handles
new Handle:cvarInterval;
new Handle:AmmoTimer;
new Handle:kvProps = INVALID_HANDLE;
new Handle:g_cvJumpBoost = INVALID_HANDLE;
new Handle:g_cvJumpMax = INVALID_HANDLE;
new Handle:cvarInterval2;
new Handle:AmmoTimer2;
new Handle:AmmoTimer3;
new Handle:cvarInterval3;
new Handle:cvarCreditsMax = INVALID_HANDLE;
new Handle:disparos = INVALID_HANDLE;
new Handle:dorada = INVALID_HANDLE;
new Handle:cvarCreditsKill = INVALID_HANDLE;
//new Handle:hTimer;
//new Handle:hTimer2;
new Handle:hPush;
new Handle:hHeight;

// Bools
new bool:barricada = true;
new bool:g_Saltador[MAXPLAYERS+1] = {false, ...};
new bool:cuchillos[MAXPLAYERS+1] = {false, ...};
new bool:infectado[MAXPLAYERS+1] = {false, ...};
new bool:NoCurar = false;
new bool:g_AmmoInfi[MAXPLAYERS+1] = {false, ...};

// Int, Float, String
new offsEyeAngle0;
new Float:g_flBoost = 250.0;
new g_fLastButtons[MAXPLAYERS+1];
new g_fLastFlags[MAXPLAYERS+1];
new g_iJumps[MAXPLAYERS+1];
new g_iJumpMax;
new String:g_MapName[128];
new VelocityOffset_0;
new VelocityOffset_1;
new BaseVelocityOffset;
new BeamSprite;
//new Nemesis = 0;
new Survivor = 0;
new g_iCredits[MAXPLAYERS+1];
new g_props[MAXPLAYERS+1];
new inmunidad[MAXPLAYERS+1];
new g_Movimientos[MAXPLAYERS+1];
new maxents;
new activeOffset = -1;
new clip1Offset = -1;
new clip2Offset = -1;
new secAmmoTypeOffset = -1;
new priAmmoTypeOffset = -1;

public Plugin:myinfo =
{
	name = "SM Zombie Plague by Franug",
	author = "Franc1sco steam: franug",
	description = "Para comprar premios en zombies",
	version = VERSION2,
	url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStartZM()
{
	LoadTranslations("zprop.phrases");
	LoadTranslations ("plague.phrases");
	// ======================================================================
	
	// ======================================================================
	
	RegConsoleCmd("sm_awards", DOMenu);
	RegConsoleCmd("sm_creditos", VerCreditos);
	RegConsoleCmd("sm_zp", DOMenu);
	RegConsoleCmd("sm_premios", DOMenu);	
	RegConsoleCmd("sm_skills", DOMenu);	
	RegConsoleCmd("sm_medico", Curarse);
	RegConsoleCmd("sm_enfer", Curarse);
	RegConsoleCmd("sm_viewcredits", VerCreditosClient);
	RegConsoleCmd("sm_givecredits", Dar);
	RegAdminCmd("sm_giveme", Darme, ADMFLAG_CUSTOM2);
	RegConsoleCmd("sm_detonar", Bumb);
	//RegConsoleCmd("sm_detonatee", Bumb);
	RegAdminCmd("sm_setcredits", FijarCreditos, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_rondanemesis", NemesisA, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_rondazplague", Ronda_PlagueA, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_rondasurvivor", SurvivorA, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_noprops", NoProps, ADMFLAG_CUSTOM1);

	RegAdminCmd("sm_municionall", municionall, ADMFLAG_CUSTOM2);
	
	// ======================================================================
	
	// ======================================================================
	offsEyeAngle0 = FindSendPropInfo("CCSPlayer", "m_angEyeAngles[0]");
	if (offsEyeAngle0 == -1)
	{
		SetFailState("Couldn't find \"m_angEyeAngles[0]\"!");
	}
	
	cvarCreditsMax = CreateConVar("zombieplague_credits_max", "250", "Max credits(0: No limit)");
	cvarCreditsKill = CreateConVar("zombieplague_credits_kill", "2", "Number of credits for kill");
	disparos = CreateConVar("zombieplague_shots", "8", "Number of shots to zombies for receive credits");
	dorada = CreateConVar("zombieplague_dorada", "15.0", "Multipliear of damage for golden weapons");
	
	cvarInterval = CreateConVar("ammo_interval", "5", "How often to reset ammo (in seconds).", _, true, 1.0);
	cvarInterval2 = CreateConVar("credits_interval", "60", "Receive credits each X seconds.", _, true, 1.0);
	cvarInterval3 = CreateConVar("hp_interval", "1", "Show HP of survivor/nemesis each X second.", _, true, 1.0);
	activeOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	
	clip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	clip2Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip2");
	
	priAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoCount");
	secAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iSecondaryAmmoCount");
	g_cvJumpBoost = CreateConVar("sm_doublejump_boost", "350.0","The amount of vertical boost to apply to double jumps (double jump award).");
	
	g_cvJumpMax = CreateConVar("sm_doublejump_max", "1","The maximum number of re-jumps allowed while already jumping (double jump award).");
	g_flBoost = GetConVarFloat(g_cvJumpBoost);
	g_iJumpMax = GetConVarInt(g_cvJumpMax);	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	CreateConVar("ZombieReloaded con Premios", VERSION2, "plugin info", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	//CreateConVar("www.servers-cfg.foroactivo.com", "Pagina de configuraciones y plugins en Castellano", "version del plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	// Hooks event changes
	//HookEvent("hegrenade_detonate", NadeDetonate);
	// Find offsets
	VelocityOffset_0=FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	if(VelocityOffset_0==-1)
	SetFailState("[BunnyHop] Error: Failed to find Velocity[0] offset, aborting");
	VelocityOffset_1=FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	if(VelocityOffset_1==-1)
	SetFailState("[BunnyHop] Error: Failed to find Velocity[1] offset, aborting");
	BaseVelocityOffset=FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	if(BaseVelocityOffset==-1)
	SetFailState("[BunnyHop] Error: Failed to find the BaseVelocity offset, aborting");
	
	// Create cvars
	hPush=CreateConVar("bunnyhop_push","1.0","The forward push when you jump (for nemesis)");
	hHeight=CreateConVar("bunnyhop_height","5.0","The upward push when you jump (for nemesis)");
	
	AutoExecConfig(true, "zombiereloaded/zombie_plague");
	
	OnPluginStart20();
	OnPluginStart2();
	OnPluginStartbomba();
}
public OnMapStartZM()
{
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	
	GetCurrentMap(g_MapName, sizeof(g_MapName));
	if (StrContains(g_MapName, "zm_") == 0 || StrContains(g_MapName, "ZM_") == 0)
	{
		barricada = true;
	}
	else if (StrContains(g_MapName, "ze_") == 0 || StrContains(g_MapName, "ZE_") == 0)
	{
		barricada = false;
	
	}
	PrecacheModel("models/props/de_train/barrel.mdl");
	PrecacheSound("franug/zombie_plague/survivor1.wav");
	PrecacheSound("franug/zombie_plague/survivor2.wav");
	PrecacheSound("franug/zombie_plague/es_survivor.wav");
	PrecacheSound("franug/zombie_plague/nemesis1.wav");
	PrecacheSound("franug/zombie_plague/nemesis2.wav");
	PrecacheSound("franug/zombie_plague/es_nemesis.wav");
	//PrecacheSound("items/smallmedkit1.wav");
	//PrecacheSound("medicsound/medic.wav");
	//AddFileToDownloadsTable("sound/medicsound/medic.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/survivor1.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/survivor2.wav");
	//AddFileToDownloadsTable("sound/franug/zombie_plague/es_survivor.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/nemesis_pain1.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/nemesis_pain2.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/nemesis_pain3.wav");
	PrecacheSound("franug/zombie_plague/nemesis_pain1.wav");
	PrecacheSound("franug/zombie_plague/nemesis_pain2.wav");
	PrecacheSound("franug/zombie_plague/nemesis_pain3.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/nemesis1.wav");
	AddFileToDownloadsTable("sound/franug/zombie_plague/nemesis2.wav");
	//AddFileToDownloadsTable("sound/franug/zombie_plague/es_nemesis.wav");
	AddFileToDownloadsTable("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.dx80.vtx");
	AddFileToDownloadsTable("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.dx90.vtx");
	AddFileToDownloadsTable("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.mdl");
	AddFileToDownloadsTable("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.phy");
	AddFileToDownloadsTable("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.sw.vtx");
	AddFileToDownloadsTable("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.vvd");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_00.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_00.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_00n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_01.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_01.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_01n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_02.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_02.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_02n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_04.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_04.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_04n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_05.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_05.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_05n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_06.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_06.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_06n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_07.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_07.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_07n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_08.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_08.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_08n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_09.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_09.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_09n.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens1_10.vtf");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens2_pipea.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens2_pipeb.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/ens2_pipec.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/eyeball_l.vmt");
	AddFileToDownloadsTable("materials/models/player/pil/re_chronicles/nemesis/iris.vtf");
	PrecacheModel("models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.mdl");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_ammo_belt.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_ammo_belt.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_ammo_belt_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_ammo_belt_phong.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_body.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_body.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_body_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_boots.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_boots.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_boots_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_eyes.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_fingers.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_hands.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_hands.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_hands_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_hat.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_hat.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_hat_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_head.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_head.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_head_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun_belts.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun_light.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun_phong.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_minigun_plastic.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_necklace.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_pants.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_pants.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_pants_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_phong.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_shades.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_shades_glass.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_shades_glass_phong.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_shades_nophong.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_teeth.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_vest.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_vest.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_vest_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/amberlyn/re5/majini_minigun/slow_vest_nocull.vmt");
	AddFileToDownloadsTable("models/player/slow/amberlyn/re5/majini_minigun/slow.dx80.vtx");
	AddFileToDownloadsTable("models/player/slow/amberlyn/re5/majini_minigun/slow.dx90.vtx");
	AddFileToDownloadsTable("models/player/slow/amberlyn/re5/majini_minigun/slow.mdl");
	AddFileToDownloadsTable("models/player/slow/amberlyn/re5/majini_minigun/slow.phy");
	AddFileToDownloadsTable("models/player/slow/amberlyn/re5/majini_minigun/slow.sw.vtx");
	AddFileToDownloadsTable("models/player/slow/amberlyn/re5/majini_minigun/slow.vvd");
	PrecacheModel("models/player/slow/amberlyn/re5/majini_minigun/slow.mdl");
	PrecacheSound("franug/zombie_plague/golpear_escudo2.mp3");
	AddFileToDownloadsTable("sound/franug/zombie_plague/golpear_escudo2.mp3");

	if (AmmoTimer != INVALID_HANDLE) {
		KillTimer(AmmoTimer);
	}
	
	new Float:interval = GetConVarFloat(cvarInterval);
	AmmoTimer = CreateTimer(interval, ResetAmmo, _, TIMER_REPEAT);

	if (AmmoTimer2 != INVALID_HANDLE) {
		KillTimer(AmmoTimer2);
	}

	new Float:interval2 = GetConVarFloat(cvarInterval2);
	AmmoTimer2 = CreateTimer(interval2, ResetAmmo2, _, TIMER_REPEAT);

	if (AmmoTimer3 != INVALID_HANDLE) {
		KillTimer(AmmoTimer3);
	}
	
	new Float:interval3 = GetConVarFloat(cvarInterval3);
	AmmoTimer3 = CreateTimer(interval3, ResetAmmo3, _, TIMER_REPEAT);

	if (kvProps != INVALID_HANDLE)
	CloseHandle(kvProps);
	
	kvProps = CreateKeyValues("zprops");
	
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/zprops.txt");
	
	if (!FileToKeyValues(kvProps, path))
	{
		SetFailState("\"%s\" missing from server", path);
	
	}
	OnMapStart20();
	OnMapStart2();
	OnMapStartbomba();
}
public DisparosZM(index, const String:weapon[])
{
	if (!IsFakeClient(index))
	{
		if(StrEqual(weapon, "knife"))
		{
			if(flameAmount[index] > 0)
			{
				Flame(index);
			}
			cuchillos[index] = true;
			CreateTimer(0.3, NoCuchillo, index);
		}
	}
}
public Action:NoCuchillo(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		cuchillos[client] = false;
	}
}
public Action:MensajesSpawn(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		PrintToChat(client, "\x04[aSO] \x05%t", "Mata jugadores para conseguir creditos");
		PrintToChat(client, "\x04[aSO] \x05%t", "Escribe !premios para gastar tus creditos en premios");
	}
}
public Action:Pasado(Handle:timer)
{
	NoCurar = false;
}

public PlayerDeathZM(any:attacker, any:client)
{
	//new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidClient(attacker))
	return;
	if (attacker == client)
	return;
	g_iCredits[attacker] += GetConVarInt(cvarCreditsKill);
	
	if (g_iCredits[attacker] < GetConVarInt(cvarCreditsMax))
	{
		PrintHintText(attacker, "[aSO]%t (+2)", "Tus creditos", g_iCredits[attacker]);
	}
	else
	{
		g_iCredits[attacker] = GetConVarInt(cvarCreditsMax);
		PrintToChat(attacker, "\x04[aSO] \x05%t", "Tus creditosM", g_iCredits[attacker]);
	}
	
	
}
public PlayerSpawnZM(any:client)
{
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(client) == 1 && !IsPlayerAlive(client))
	{
		return;
	}
	CreateTimer(1.0, MensajesSpawn, client);
	g_AmmoInfi[client] = false;
	if(GetEntProp(client, Prop_Data, "m_takedamage", 1) == 0)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	g_Saltador[client] = false;
	g_Bomba[client] = false;
	Es_Nemesis[client] = false;
	infectado[client] = false;
	g_Movimientos[client] = 0;
	flameAmount[client] = 0;
	inmunidad[client] = 0;
	nade_infect[client] = 0;
	nade_count[client] = 0;
}
public Event_hurtZM(any:attacker)
{
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!IsValidClient(attacker) || !IsPlayerAlive(attacker))
	return;
	g_Movimientos[attacker] += 1;
	if(g_Movimientos[attacker] > GetConVarInt(disparos))
	{
		g_iCredits[attacker] += 1;
		
		if (g_iCredits[attacker] < GetConVarInt(cvarCreditsMax))
		{
			PrintHintText(attacker, "[aSO] %t (+1)", "Tus creditos", g_iCredits[attacker]);
		}
		else
		{
			g_iCredits[attacker] = GetConVarInt(cvarCreditsMax);
			PrintHintText(attacker, "[aSO] %t", "Tus creditosM", g_iCredits[attacker]);
		}
		g_Movimientos[attacker] = 0;
	}
	
}
public Event_hurtZMGranadas(index, attacker, const String:weapon[])
{
	if (!IsValidClient(attacker) || !IsPlayerAlive(attacker))
	return;
	if (!IsValidClient(index) || !IsPlayerAlive(index))
	return;
	if (g_Bomba[index])
	{
		if (GetClientTeam(attacker) != GetClientTeam(index))
		{
			Detonate(index);
		}
	}
	if (!b_napalm_he)
	{
		return;
	}
	
	if (!StrEqual(weapon, "hegrenade", false))
	{
		return;
	}
	
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (ZR_IsClientHuman(index))
	{
		return;
	}
	if (!ZR_IsClientHuman(attacker))
	{
		return;
	}
	
	
	new Action:result, Float:dummy_duration = f_napalm_he_duration;
	result = Forward_OnClientIgnite(index, attacker, dummy_duration);
	
	switch (result)
	{
	case Plugin_Handled, Plugin_Stop :
		{
			return;
		}
	case Plugin_Continue :
		{
			dummy_duration = f_napalm_he_duration;
		}
	}
	
	IgniteEntity(index, dummy_duration);
	
	Forward_OnClientIgnited(index, attacker, dummy_duration);
	
}
public IsValidClient( client ) 
{ 
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
	return false; 
	
	return true; 
}
public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
	if (!IsValidClient(attacker))
	return Plugin_Continue;
	g_iCredits[attacker] += GetConVarInt(cvarCreditsKill);
	infectado[attacker] = true;
	
	if (g_iCredits[attacker] < GetConVarInt(cvarCreditsMax))
	{
		PrintHintText(attacker, "[aSO] %t (+2)", "Tus creditos", g_iCredits[attacker]);
	}
	else
	{
		g_iCredits[attacker] = GetConVarInt(cvarCreditsMax);
		PrintToChat(attacker, "\x04[aSO] \x05%t", "Tus creditosM", g_iCredits[attacker]);
	}
	if(Es_Nemesis[attacker])
	{
		DealDamage(client,3000,attacker,DMG_SLASH,"zombie_claws_of_death");
		g_iCredits[attacker] += GetConVarInt(cvarCreditsKill);
		
		if (g_iCredits[attacker] < GetConVarInt(cvarCreditsMax))
		{
			PrintHintText(attacker, "[aSO] %t (+2)", "Tus creditos", g_iCredits[attacker]);
		}
		else
		{
			g_iCredits[attacker] = GetConVarInt(cvarCreditsMax);
			PrintToChat(attacker, "\x04[aSO] \x05%t", "Tus creditosM", g_iCredits[attacker]);
		}
		return Plugin_Handled;
	}
	else if(inmunidad[client] > 0)
	{
		inmunidad[client] -= 1;
		new Float:pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		EmitSoundToAll("franug/zombie_plague/golpear_escudo2.mp3", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
		PrintToChat(client, "\x04[aSO] \x05%t" ,"La armadura anti", inmunidad[client]);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:VerCreditos(client, args)
{
	PrintToChat(client, "\x04[aSO] \x05%t", "Tus creditos actuales son", g_iCredits[client]);
}
public Action:DOMenu(client,args)
{
	DID(client);
	PrintToChat(client, "\x04[aSO] \x05%t" ,"Tus creditos", g_iCredits[client]);
}
public Action:OnClientDisconnectZM(client)
{
	if (!client || IsFakeClient(client))
	return;
	if(Nemesis == client)
	{
		ServerCommand("mp_restartgame 2");
		Nemesis = 0;
		PrintToChatAll("\x04[aSO] \x05%t","El jugador NEMESIS se ha desconectado");
	}
	else if(Survivor == client)
	{
		ServerCommand("mp_restartgame 2");
		Survivor = 0;
		PrintToChatAll("\x04[aSO] \x05%t","El jugador SURVIVOR se ha desconectado");
	}
}
public Action:Curarse(client,args)
{
	if (IsPlayerAlive(client))
	{
		if (g_iCredits[client] >= 7)
		{
			if (!ZR_IsClientZombie(client))
			{
				SetEntityHealth(client, 100);
				g_iCredits[client] -= 7;
				PrintToChat(client, "\x04[aSO] \x05%t (-7)","Te has aplicado cirugia. Tus creditos", g_iCredits[client]);
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t","Tienes que ser humano para poder comprar este premio");
			}
		}
		else
		{
			PrintToChat(client, "\x04[aSO] \x05%t 7)","Necesitas creditos", g_iCredits[client]);
		}
	}
	else
	{
		PrintToChat(client, "\x04[aSO] \x05%t","Pero si estas muerto");
	}
}
public Action:FijarCreditos(client, args)
{
	if(args < 2) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Utiliza: sm_setcredits <#userid|nombre> [cantidad]");
		return Plugin_Handled;
	}
	decl String:arg2[10];
	//GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	new amount = StringToInt(arg2);
	//new target;
	//decl String:patt[MAX_NAME]
	//if(args == 1) 
	//{ 
	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 
	// Process the targets 
	decl String:strTargetName[MAX_TARGET_LENGTH]; 
	decl TargetList[MAXPLAYERS], TargetCount; 
	decl bool:TargetTranslate; 
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
					strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{ 
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	} 
	// Apply to all targets 
	for (new i = 0; i < TargetCount; i++) 
	{ 
		new iClient = TargetList[i]; 
		if (IsClientInGame(iClient)) 
		{ 
			g_iCredits[iClient] = amount;
			PrintToChat(client, "\x04[aSO] \x05Puesto %i creditos en el jugador %N", amount, iClient);
		} 
	} 
	//}  
	//    SetEntProp(target, Prop_Data, "m_iDeaths", amount);
	return Plugin_Continue;
}
public Action:municionall(client, args)
{
	for (new i = 1; i < GetMaxClients(); i++)
	{
		if ((IsClientInGame(i)) && (IsPlayerAlive(i)))
		{
			g_AmmoInfi[i] = true;
		}
	}
	PrintToChatAll("\x04[aSO] \x05%t", "Activada MUNICION INFINITA");
} 
public Client_ResetAmmo(client)
{
	new zomg = GetEntDataEnt2(client, activeOffset);
	if (clip1Offset != -1 && zomg != -1)
	SetEntData(zomg, clip1Offset, 999, 4, true);
	if (clip2Offset != -1 && zomg != -1)
	SetEntData(zomg, clip2Offset, 999, 4, true);
	if (priAmmoTypeOffset != -1 && zomg != -1)
	SetEntData(zomg, priAmmoTypeOffset, 999, 4, true);
	if (secAmmoTypeOffset != -1 && zomg != -1)
	SetEntData(zomg, secAmmoTypeOffset, 999, 4, true);
}
public Action:OpcionNumero16c(Handle:timer, any:client)
{
	if ( (IsClientInGame(client)) && (IsPlayerAlive(client)) )
	{
		PrintToChat(client, "\x04[aSO] \x05%t","Ya no eres INVULNERABLE!");
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}
public Action:OnClientPostAdminCheckZM(client)
{
	g_iCredits[client] = 0;
	g_props[client] = 0;
	//g_Zombie[client] = false;
	//g_Monster[client] = false;
	g_AmmoInfi[client] = false;
	//g_Usando[client] = false;
}
public Action:DID(clientId) 
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu, "Menu de premios - ArStrike Organization");
	decl String:MenuItem[128];
	Format(MenuItem, sizeof(MenuItem),"%T", "Ver informacion del plugin", clientId);
	AddMenuItem(menu, "option1", MenuItem);
	decl String:MenuItem2[128];
	Format(MenuItem2, sizeof(MenuItem2),"%T", "Curarse a 100 HP (humanos) - 7  Creditos", clientId);
	AddMenuItem(menu, "option2", MenuItem2);
	decl String:MenuItem3[128];
	Format(MenuItem3, sizeof(MenuItem3),"%T", "Tener 250 hp de vida (humanos) - 8 Creditos", clientId);
	AddMenuItem(menu, "option3", MenuItem3);
	if (barricada)
	{
		decl String:MenuItem4[128];
		Format(MenuItem4, sizeof(MenuItem4),"%T", "Municion de lanzallamas (ambos) - 9  Creditos", clientId);
		AddMenuItem(menu, "option4", MenuItem4);
		decl String:MenuItem5[128];
		Format(MenuItem5, sizeof(MenuItem5),"%T", "Doble salto (ambos) - 9  Creditos", clientId);
		AddMenuItem(menu, "option5", MenuItem5);
		decl String:MenuItem6[128];
		Format(MenuItem6, sizeof(MenuItem6),"%T", "Cuchillo arrojadizo (ambos) - 14  Creditos", clientId);
		AddMenuItem(menu, "option6", MenuItem6);
	}
	decl String:MenuItem7[128];
	Format(MenuItem7, sizeof(MenuItem7),"%T", "Escudo anti (humanos) - 15  Creditos", clientId);
	AddMenuItem(menu, "option7", MenuItem7);
	if (barricada)
	{
		decl String:MenuItem8[128];
		Format(MenuItem8, sizeof(MenuItem8),"%T", "Mas velocidad (ambos) - 15  Creditos", clientId);
		AddMenuItem(menu, "option8", MenuItem8);
	}
	decl String:MenuItem9[128];
	Format(MenuItem9, sizeof(MenuItem9),"%T", "Disfrazarse de barril (ambos)  - 15 Creditos", clientId);
	AddMenuItem(menu, "option9", MenuItem9);
	decl String:MenuItem10[128];
	Format(MenuItem10, sizeof(MenuItem10),"%T", "Municion Infinita (humanos) - 16  Creditos", clientId);
	AddMenuItem(menu, "option10", MenuItem10);
	decl String:MenuItem11[128];
	Format(MenuItem11, sizeof(MenuItem11),"%T", "Curarse con Antidoto (zombis) - 18  Creditos", clientId);
	AddMenuItem(menu, "option11", MenuItem11);
	if (barricada)
	{
		decl String:MenuItem12[128];
		Format(MenuItem12, sizeof(MenuItem12),"%T", "Ser invisible (ambos) - 20 Creditos", clientId);
		AddMenuItem(menu, "option12", MenuItem12);
		decl String:MenuItem13[128];
		Format(MenuItem13, sizeof(MenuItem13),"%T", "Furia INVULNERABLE 5 segundos (ambos) - 50  Creditos", clientId);
		AddMenuItem(menu, "option13", MenuItem13);
	}
	decl String:MenuItem14[128];
	Format(MenuItem14, sizeof(MenuItem14),"%T", "Deagle Dorada Ardiente (humanos) - 50  Creditos", clientId);
	AddMenuItem(menu, "option14", MenuItem14);
	if (barricada)
	{
		decl String:MenuItem15[128];
		Format(MenuItem15, sizeof(MenuItem15),"%T", "Bomba de infeccion (zombis) - 60  Creditos", clientId);
		AddMenuItem(menu, "option15", MenuItem15);
		decl String:MenuItem16[128];
		Format(MenuItem16, sizeof(MenuItem16),"%T", "Bomba de antidoto (humanos) - 60  Creditos", clientId);
		AddMenuItem(menu, "option16", MenuItem16);
		decl String:MenuItem17[128];
		Format(MenuItem17, sizeof(MenuItem17),"%T", "KAMIKAZE EXPLOSIVO (ambos) - 60  Creditos", clientId);
		AddMenuItem(menu, "option17", MenuItem17);
	}
	decl String:MenuItem18[128];
	Format(MenuItem18, sizeof(MenuItem18),"%T", "MP5 Dorada Ardiente (humanos) - 60  Creditos", clientId);
	AddMenuItem(menu, "option18", MenuItem18);
	decl String:MenuItem19[128];
	Format(MenuItem19, sizeof(MenuItem19),"%T", "M3 (humanos) - 95  Creditos", clientId);
	AddMenuItem(menu, "option19", MenuItem19);	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public Action:ResetAmmo(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && IsPlayerAlive(client) && (g_AmmoInfi[client]))
		{
			Client_ResetAmmo(client);
		}
	}
}
public Action:ResetAmmo2(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client))
		{
			g_iCredits[client] += 1;
		}
	}
	PrintToChatAll("\x04[aSO] \x05%t","Has recibido 1 credito gratis! cada minuto recibiras 1 credito gratuito");
}
public Action:ResetAmmo3(Handle:timer)
{
	if(IsValidClient(Nemesis) && IsPlayerAlive(Nemesis) && rondanemesis)
	{
		for(new i=1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i) && Nemesis != i)
			{
				ZR_HumanClient(i);
			}
		}
		new vida_nemesiss = GetClientHealth(Nemesis);
		PrintCenterTextAll("%t","Vida del NEMESIS", vida_nemesiss);
	}
	else if(IsValidClient(Survivor) && IsPlayerAlive(Survivor) && rondasurvivor)
	{
		for(new i=1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i) && Survivor != i)
			{
				ZR_InfectClient(i);
			}
		}
		new vida_survivors = GetClientHealth(Survivor);
		PrintCenterTextAll("%t","Vida del SURVIVOR", vida_survivors);
	}
/*
	else if(rondaplague)
	{
		for(new i=1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i) && !Es_Nemesis[i])
			{
				ForcePlayerSuicide(i);
			}
		}
	}
*/
}
public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		if ( strcmp(info,"option1") == 0 ) 
		{
			PrintToChat(client,"\x04[aSO] \x05%t","Dispara a los zombies o infecta humanos para ganar creditos");
			PrintToChat(client, "\x04[aSO] \x05%t","creado para SourceMod, encuentralo en www.servers-cfg.foroactivo.com", VERSION2);
			DID(client);
		}
		else if ( strcmp(info,"option2") == 0 ) 
		{
			
			if (g_iCredits[client] >= 7)
			{
				if (IsPlayerAlive(client))
				{
					if (!ZR_IsClientZombie(client))
					{
						if(client == Nemesis || client == Survivor)
						{
							PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
							return;
						}
						SetEntityHealth(client, 100);
						g_iCredits[client] -= 7;
						//EmitSoundToAll("medicsound/medic.wav");
						//decl String:nombre[32];
						//GetClientName(client, nombre, sizeof(nombre));
						//PrintToChatAll("\x04[aSO] \x05El jugador\x03 %s \x05se ha curado!", nombre);
						PrintToChat(client, "\x04[aSO] \x05%t (-7)","Te has aplicado cirugia. Tus creditos", g_iCredits[client]);
					}
					else
					{
						PrintToChat(client, "\x04[aSO] \x05%t","Tienes que ser humano para poder comprar este premio");
					}
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 7)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
		}
		else if ( strcmp(info,"option3") == 0 ) 
		{
			if (g_iCredits[client] >= 8)
			{
				if (IsPlayerAlive(client))
				{
					if (!ZR_IsClientZombie(client))
					{
						if(client == Nemesis || client == Survivor)
						{
							PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
							return;
						}
						SetEntityHealth(client, 250);
						g_iCredits[client] -= 8;
						//EmitSoundToAll("medicsound/medic.wav");
						PrintToChat(client, "\x04[aSO] \x05%t (-8)","ahora tienes 250 HP. Tus creditos", g_iCredits[client]);
					}
					else
					{
						PrintToChat(client, "\x04[aSO] \x05%t","Tienes que ser humano para poder comprar este premio");
					}
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 8)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		else if ( strcmp(info,"option4") == 0 ) 
		{
			
			if (g_iCredits[client] >= 9)
			{
				if (GetClientTeam(client) != 1 && IsPlayerAlive(client))
				{
					if(client == Nemesis || client == Survivor)
					{
						PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
						return;
					}
					flameAmount[client] += 1;
					g_iCredits[client] -= 9;
					PrintToChat(client, "\x04[aSO] \x05%t (-9)","Has comprado una municion para LANZALLAMAS! Se usa apretando boton derecho del raton a cuxi.  Tus creditos", g_iCredits[client]);
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 9)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		else if ( strcmp(info,"option5") == 0 ) 
		{
			
			if (g_iCredits[client] >= 9)
			{
				if (GetClientTeam(client) != 1 && IsPlayerAlive(client))
				{
					if(client == Nemesis || client == Survivor)
					{
						PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
						return;
					}
					g_Saltador[client] = true;
					g_iCredits[client] -= 9;
					PrintToChat(client, "\x04[aSO] \x05%t (-9)","Ahora tienes DOBLE SALTO y puedes saltar en el aire! Tus creditos", g_iCredits[client]);
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 9)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		else if ( strcmp(info,"option6") == 0 ) 
		{
			
			if (g_iCredits[client] >= 6)
			{
				if (GetClientTeam(client) != 1 && IsPlayerAlive(client))
				{
					if(client == Nemesis || client == Survivor)
					{
						PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
						return;
					}
					new cuchillos13 = GetClientThrowingKnives(client);
					cuchillos13 += 1;
					SetClientThrowingKnives(client, cuchillos13);
					g_iCredits[client] -= 6;
					PrintToChat(client, "\x04[aSO] \x05%t (-6)","Has comprado un cuchillo arrojadizo. Tus creditos", g_iCredits[client]);
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 6)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		else if ( strcmp(info,"option7") == 0 ) 
		{
			if (g_iCredits[client] >= 15)
			{
				if (IsPlayerAlive(client))
				{
					if (!ZR_IsClientZombie(client))
					{
						if(client == Nemesis || client == Survivor)
						{
							PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
							return;
						}
						inmunidad[client] = 5;
						g_iCredits[client] -= 15;
						PrintToChat(client, "\x04[aSO] \x05%t (-15)","Has comprado un escudo anti-infeccion que resiste 5 golpes! Tus creditos", g_iCredits[client]);
					}
					else
					{
						PrintToChat(client, "\x04[aSO] \x05%t","Tienes que ser humano para poder comprar este premio");
					}
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 15)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
		}
		else if ( strcmp(info,"option8") == 0 ) 
		{
			
			if (g_iCredits[client] >= 15)
			{
				if (IsPlayerAlive(client))
				{
					if(client == Nemesis || client == Survivor)
					{
						PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
						return;
					}
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.4);
					g_iCredits[client] -= 15;
					PrintToChat(client, "\x04[aSO] \x05%t (-15)","Ahora tienes mas velocidad! Tus creditos", g_iCredits[client]);
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 15)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		else if ( strcmp(info,"option9") == 0 ) 
		{
			
			if (g_iCredits[client] >= 15)
			{
				if (IsPlayerAlive(client))
				{
					if(client == Nemesis || client == Survivor)
					{
						PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
						return;
					}
					SetEntityModel(client, "models/props/de_train/barrel.mdl");
					g_iCredits[client] -= 15;
					PrintToChat(client, "\x04[aSO] \x05%t (-15)","Ahora eres un Barril! Tus creditos", g_iCredits[client]);
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 15)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		else if ( strcmp(info,"option10") == 0 ) 
		{
			
			if (g_iCredits[client] >= 16)
			{
				if (IsPlayerAlive(client))
				{
					if (!ZR_IsClientZombie(client))
					{
						if(client == Nemesis || client == Survivor)
						{
							PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
							return;
						}
						g_AmmoInfi[client] = true;
						g_iCredits[client] -= 16;
						PrintToChat(client, "\x04[aSO] \x05%t (-16)","Ahora tienes municion infinita! Tus creditos", g_iCredits[client]);
					}
					else
					{
						PrintToChat(client, "\x04[aSO] \x05%t","Tienes que ser humano para poder comprar este premio");
					}
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 16)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		else if ( strcmp(info,"option11") == 0 ) 
		{
			
			if (g_iCredits[client] >= 18)
			{
				if (IsPlayerAlive(client))
				{
					if (ZR_IsClientZombie(client))
					{
						if(client == Nemesis || client == Survivor)
						{
							PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
							return;
						}
						if(NoCurar)
						{
							PrintToChat(client,"\x04[aSO] \x05%t","No puedes curarte al empezar la ronda hasta que no pase 1 minuto");
							return;
						}
						if(!infectado[client])
						{
							PrintToChat(client,"\x04[aSO] \x05No puedes curarte siendo mother zombie o no habiendo infectado a alguien primero");
							return;
						}
						ZR_HumanClient(client, false, false);
						
						GivePlayerItem(client, "weapon_usp");
						GivePlayerItem(client, "weapon_mp5navy");
						g_iCredits[client] -= 18;
						new Float:iVec[ 3 ];
						GetClientAbsOrigin( client, Float:iVec );
						EmitAmbientSound("items/smallmedkit1.wav", iVec, client, SNDLEVEL_NORMAL );
						decl String:nombre[32];
						GetClientName(client, nombre, sizeof(nombre));
						PrintCenterTextAll("%t","a vuelto a ser humano con un antidoto", nombre);
						PrintToChat(client, "\x04[aSO] \x05%t (-18)","Te has curado y vuelves a ser humano! Tus creditos", g_iCredits[client]);
					}
					else
					{
						PrintToChat(client, "\x04[aSO] \x05%t","Tienes que ser zombie para poder comprar este premio");
					}
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 18)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		
		else if ( strcmp(info,"option12") == 0 ) 
		{
			if (g_iCredits[client] >= 20)
			{
				if (IsPlayerAlive(client))
				{
					if(client == Nemesis || client == Survivor)
					{
						PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
						return;
					}
					SetEntityRenderMode(client, RENDER_TRANSCOLOR);
					SetEntityRenderColor(client, 255, 255, 255, 10);
					g_iCredits[client] -= 20;
					PrintToChat(client, "\x04[aSO] \x05%t (-20)","Ahora eres invisible! Tus creditos", g_iCredits[client]);
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 20)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
		}
		else if ( strcmp(info,"option13") == 0 ) 
		{
			
			if (g_iCredits[client] >= 40)
			{
				if (IsPlayerAlive(client))
				{
					if(client == Nemesis || client == Survivor)
					{
						PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
						return;
					}
					SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
					SetEntityRenderColor(client, 255, 0, 0, 255);
					CreateTimer(5.0, OpcionNumero16c, client);
					g_iCredits[client] -= 40;
					PrintToChat(client, "\x04[aSO] \x05%t (-40)","Ahora eres INVULNERABLE durante 5 segundos! Tus creditos", g_iCredits[client]);
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 40)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
		}
		else if ( strcmp(info,"option14") == 0 ) 
		{
			
			if (g_iCredits[client] >= 50)
			{
				if (IsPlayerAlive(client))
				{
					if (!ZR_IsClientZombie(client))
					{
						if(client == Nemesis || client == Survivor)
						{
							PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
							return;
						}
						g_iCredits[client] -= 50;
						// Gets the Clients weapon in slot 0 - Primary
						new index = GetPlayerWeaponSlot(client, 1);
						// If the index is not -1 - Client has a Primary weapon 
						if(index != -1)
						{
							CS_DropWeapon(client, index, false, true);
						}
						new ent = GivePlayerItem(client,"weapon_deagle");
						bIsGoldenGun[ent]=true;
						SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
						SetEntityRenderColor(ent, 255, 215, 0);
						//SetEntData(ent, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 999);
						//IgniteEntity(ent, 0.0);
						new String:tName[128];
						Format(tName, sizeof(tName), "lighttarget%i", ent);
						DispatchKeyValue(ent, "targetname", tName);
						
						new String:light_name[128];
						Format(light_name, sizeof(light_name), "light%i", ent);
						
						new luz = CreateEntityByName("light_dynamic");
						
						
						DispatchKeyValue(luz,"targetname", light_name);
						DispatchKeyValue(luz, "parentname", tName);
						DispatchKeyValue(luz, "inner_cone", "0");
						DispatchKeyValue(luz, "cone", "100");
						DispatchKeyValue(luz, "brightness", "1");
						DispatchKeyValueFloat(luz, "spotlight_radius", 300.0);
						
						DispatchKeyValue(luz, "pitch", "200");
						DispatchKeyValue(luz, "style", "5");
						DispatchKeyValue(luz, "classname", "luzxd");
						DispatchKeyValue(luz, "_light", "255 255 0 255");
						DispatchKeyValueFloat(luz, "distance", 300.0);
						DispatchSpawn(luz);
						
						new Float:ClientsPos[3];
						GetClientAbsOrigin(client, ClientsPos);
						//ClientsPos[2] += 90.0;
						TeleportEntity(luz, ClientsPos, NULL_VECTOR, NULL_VECTOR);
						SetVariantString(tName);
						AcceptEntityInput(luz, "SetParent");
						SetEntPropEnt(ent, Prop_Send, "m_hEffectEntity", luz);
						//Entity_SetParent(luz, ent);
						AcceptEntityInput(luz, "TurnOn");
						//AcceptEntityInput(luz, "DisableShadow");
						
						//SetEntData(ent, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 999);
						//IgniteEntity(ent, 0.0);
						new ent2 = CreateEntityByName("_firesmoke");
						if(ent2 != -1)
						{
							DispatchKeyValue(ent2, "classname", "fuegoxd");
							DispatchSpawn(ent2);
							TeleportEntity(ent2, ClientsPos, NULL_VECTOR, NULL_VECTOR);
							SetVariantString("!activator");
							AcceptEntityInput(ent2, "SetParent", ent);
						}
						
						PrintToChat(client, "\x04[aSO] \x05%t (-50)","Ahora tienes una Deagle DORADA ARDIENTE que produce mas damage y quema! Tus creditos", g_iCredits[client]);
					}
					else
					{
						PrintToChat(client, "\x04[aSO] \x05%t","Tienes que ser humano para poder comprar este premio");
					}
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 50)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		else if ( strcmp(info,"option15") == 0 ) 
		{
			
			if (g_iCredits[client] >= 60)
			{
				if (IsPlayerAlive(client))
				{
					if (ZR_IsClientZombie(client))
					{
						if(client == Nemesis || client == Survivor)
						{
							PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
							return;
						}
						g_iCredits[client] -= 60;
						nade_infect[client] += 1;
						GivePlayerItem(client, "weapon_hegrenade");
						PrintToChat(client, "\x04[aSO] \x05%t (-60)","Has comprado una BOMBA DE INFECCION! Tus creditos", g_iCredits[client]);
					}
					else
					{
						PrintToChat(client, "\x04[aSO] \x05%t","Tienes que ser zombie para poder comprar este premio");
					}
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 60)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		else if ( strcmp(info,"option16") == 0 ) 
		{
			
			if (g_iCredits[client] >= 60)
			{
				if (IsPlayerAlive(client))
				{
					if (!ZR_IsClientZombie(client))
					{
						if(client == Nemesis || client == Survivor)
						{
							PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
							return;
						}
						g_iCredits[client] -= 60;
						nade_count[client] += 1;
						GivePlayerItem(client, "weapon_hegrenade");
						PrintToChat(client, "\x04[aSO] \x05%t (-60)","Has comprado una BOMBA DE ANTIDOTO! Tus creditos", g_iCredits[client]);
					}
					else
					{
						PrintToChat(client, "\x04[aSO] \x05%t","Tienes que ser humano para poder comprar este premio");
					}
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 60)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		else if ( strcmp(info,"option17") == 0 ) 
		{
			
			if (g_iCredits[client] >= 65)
			{
				if (IsPlayerAlive(client))
				{
					if(client == Nemesis || client == Survivor)
					{
						PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
						return;
					}
					g_iCredits[client] -= 65;
					//SetEntityRenderColor(client, 255, 30, 10, 255);
					g_Bomba[client] = true;
					PrintToChat(client, "\x04[aSO] \x05%t (-65)","Ahora eres una KAMIKAZE EXPLOSIVO! escribe !detonar para estallar! Tus creditos", g_iCredits[client]);
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 65)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		else if ( strcmp(info,"option18") == 0 ) 
		{
			
			if (g_iCredits[client] >= 75)
			{
				if (IsPlayerAlive(client))
				{
					if (!ZR_IsClientZombie(client))
					{
						if(client == Nemesis || client == Survivor)
						{
							PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
							return;
						}
						g_iCredits[client] -= 75;
						// Gets the Clients weapon in slot 0 - Primary
						new index = GetPlayerWeaponSlot(client, 0);
						// If the index is not -1 - Client has a Primary weapon 
						if(index != -1)
						{
							CS_DropWeapon(client, index, false, true);
						}
						new ent = GivePlayerItem(client,"weapon_tmp");
						bIsGoldenGun[ent]=true;
						SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
						SetEntityRenderColor(ent, 255, 215, 0);
						//SetEntData(ent, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 999);
						//IgniteEntity(ent, 0.0);
						new String:tName[128];
						Format(tName, sizeof(tName), "lighttarget%i", ent);
						DispatchKeyValue(ent, "targetname", tName);
						
						new String:light_name[128];
						Format(light_name, sizeof(light_name), "light%i", ent);
						
						new luz = CreateEntityByName("light_dynamic");
						
						
						DispatchKeyValue(luz,"targetname", light_name);
						DispatchKeyValue(luz, "parentname", tName);
						DispatchKeyValue(luz, "inner_cone", "0");
						DispatchKeyValue(luz, "classname", "luzxd");
						DispatchKeyValue(luz, "cone", "100");
						DispatchKeyValue(luz, "brightness", "1");
						DispatchKeyValueFloat(luz, "spotlight_radius", 300.0);
						
						DispatchKeyValue(luz, "pitch", "200");
						DispatchKeyValue(luz, "style", "5");
						DispatchKeyValue(luz, "_light", "255 255 0 255");
						DispatchKeyValueFloat(luz, "distance", 300.0);
						DispatchSpawn(luz);
						
						new Float:ClientsPos[3];
						GetClientAbsOrigin(client, ClientsPos);
						//ClientsPos[2] += 90.0;
						TeleportEntity(luz, ClientsPos, NULL_VECTOR, NULL_VECTOR);
						SetVariantString(tName);
						AcceptEntityInput(luz, "SetParent");
						SetEntPropEnt(ent, Prop_Send, "m_hEffectEntity", luz);
						//Entity_SetParent(luz, ent);
						AcceptEntityInput(luz, "TurnOn");
						//AcceptEntityInput(luz, "DisableShadow");
						new ent2 = CreateEntityByName("_firesmoke");
						if(ent2 != -1)
						{
							DispatchKeyValue(ent2, "classname", "fuegoxd");
							DispatchSpawn(ent2);
							TeleportEntity(ent2, ClientsPos, NULL_VECTOR, NULL_VECTOR);
							SetVariantString("!activator");
							AcceptEntityInput(ent2, "SetParent", ent);
						}
						
						PrintToChat(client, "\x04[aSO] \x05%t (-75)","Ahora tienes una MP5 NAVY DORADA ARDIENTE que produce mas damage y quema! Tus creditos", g_iCredits[client]);
					}
					else
					{
						PrintToChat(client, "\x04[aSO] \x05%t","Tienes que ser humano para poder comprar este premio");
					}
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 75)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);
			
			
		}
		else if ( strcmp(info,"option19") == 0 ) 
		{
			
			if (g_iCredits[client] >= 130)
			{
				if (IsPlayerAlive(client))
				{
					if (!ZR_IsClientZombie(client))
					{
						if(client == Nemesis || client == Survivor)
						{
							PrintToChat(client,"\x04[aSO] \x05%t","No puedes comprar cosas siendo un ser especial");
							return;
						}
						g_iCredits[client] -= 130;
						// Gets the Clients weapon in slot 0 - Primary
						new index = GetPlayerWeaponSlot(client, 0);
						// If the index is not -1 - Client has a Primary weapon 
						if(index != -1)
						{
							CS_DropWeapon(client, index, false, true);
						}
						new ent = GivePlayerItem(client,"weapon_m3");
						bIsGoldenGun[ent]=true;
						SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
						SetEntityRenderColor(ent, 255, 215, 0);
						//SetEntData(ent, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 999);
						//IgniteEntity(ent, 0.0);
						new String:tName[128];
						Format(tName, sizeof(tName), "lighttarget%i", ent);
						DispatchKeyValue(ent, "targetname", tName);
						
						new String:light_name[128];
						Format(light_name, sizeof(light_name), "light%i", ent);
						
						new luz = CreateEntityByName("light_dynamic");
						
						
						DispatchKeyValue(luz,"targetname", light_name);
						DispatchKeyValue(luz, "parentname", tName);
						DispatchKeyValue(luz, "inner_cone", "0");
						DispatchKeyValue(luz, "classname", "luzxd");
						DispatchKeyValue(luz, "cone", "100");
						DispatchKeyValue(luz, "brightness", "1");
						DispatchKeyValueFloat(luz, "spotlight_radius", 300.0);
						
						DispatchKeyValue(luz, "pitch", "200");
						DispatchKeyValue(luz, "style", "5");
						DispatchKeyValue(luz, "_light", "255 255 0 255");
						DispatchKeyValueFloat(luz, "distance", 300.0);
						DispatchSpawn(luz);
						
						new Float:ClientsPos[3];
						GetClientAbsOrigin(client, ClientsPos);
						//ClientsPos[2] += 90.0;
						TeleportEntity(luz, ClientsPos, NULL_VECTOR, NULL_VECTOR);
						SetVariantString(tName);
						AcceptEntityInput(luz, "SetParent");
						SetEntPropEnt(ent, Prop_Send, "m_hEffectEntity", luz);
						//Entity_SetParent(luz, ent);
						AcceptEntityInput(luz, "TurnOn");
						//AcceptEntityInput(luz, "DisableShadow");
						new ent2 = CreateEntityByName("_firesmoke");
						if(ent2 != -1)
						{
							DispatchKeyValue(ent2, "classname", "fuegoxd");
							DispatchSpawn(ent2);
							TeleportEntity(ent2, ClientsPos, NULL_VECTOR, NULL_VECTOR);
							SetVariantString("!activator");
							AcceptEntityInput(ent2, "SetParent", ent);
						}
						
						PrintToChat(client, "\x04[aSO] \x05%t (-130)","Tenes una Escopeta Dorada, usala bien!! Tus creditos", g_iCredits[client]);
					}
					else
					{
						PrintToChat(client, "\x04[aSO] \x05%t","Tienes que ser humano para poder comprar este premio");
					}
				}
				else
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Tienes que estar vivo para poder comprar premios");
				}
			}
			else
			{
				PrintToChat(client, "\x04[aSO] \x05%t 130)","Necesitas creditos", g_iCredits[client]);
			}
			DID(client);			
						
		}
	}
	else if (action == MenuAction_Cancel) 
	{ 
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", client, itemNum); 
	} 
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
JugadorAleatorio()
{
	new clients[MaxClients+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && IsPlayerAlive(i))
	clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
} 
Event_RoundStartZM()
{
	Nemesis = 0;
	Survivor = 0;
	NoCurar = true;
	CreateTimer(60.0, Pasado);
	new maxent = GetMaxEntities();
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			if(bIsGoldenGun[i])
			{
				bIsGoldenGun[i]=false;
				//new luzentity = GetEntPropEnt(i, Prop_Send, "m_hEffectEntity");
				//AcceptEntityInput(luzentity, "kill");
			}
			
		}
	}
	new index22 = -1;
	while ((index22 = FindEntityByClassname2(index22, "fuegoxd")) != -1)
	RemoveEdict(index22);
	new index33 = -1;
	while ((index33 = FindEntityByClassname2(index33, "luzxd")) != -1)
	RemoveEdict(index33);
	rondaplague = false;
	rondasurvivor = false;
	rondanemesis = false;
	//ServerCommand("zr_hitgroups 1");
	new random = GetRandomInt(10, 15);
	new Float:numeroR = random * 1.0;
	CreateTimer(numeroR, RondaQ);
	for (new i = 1; i < GetMaxClients(); i++)
	{
		if (IsClientInGame(i))
		{
			g_props[i] = 0;
		}
	}
	OnRoundStart2();
	if(barricada)
		ServerCommand("zr_respawn 1");

	ServerCommand("zr_zspawn 1");
}
public Action:RondaQ(Handle:timer)
{
	if (barricada)
	{
		new zombi = 0;
		for(new i=1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i))
			{
				zombi++;
			}
		}
		if (zombi == 0)
		{
			new random = GetRandomInt(1, 21);
			
			switch(random)
			{
			case 1:
				{
					Ronda_Nemesis(); 
				}
			case 2:
				{
					Ronda_Survivor();
				}
			case 3:
				{
					Ronda_Plague();
				}
			}
		}
	}
}
Ronda_Plague()
{
	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			jugadores++;
		}
	}  
	new vida_total = (jugadores * 1000);
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			if(GetClientTeam(i) == 2)
			{
				ZR_InfectClient(i);
				SetEntityHealth(i, vida_total);
				CS_SwitchTeam(i, CS_TEAM_T);
				SetEntityModel(i, "models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.mdl");
				Es_Nemesis[i] = true;
			}
			else if(GetClientTeam(i) == 3)
			{
				SetEntityHealth(i, vida_total);
				CS_SwitchTeam(i, CS_TEAM_CT);
				bZombie[i] = false;
				g_AmmoInfi[i] = true;
				new wepIdx;
				// strip all weapons
				for (new s = 0; s < 4; s++)
				{
					if ((wepIdx = GetPlayerWeaponSlot(i, s)) != -1)
					{
						RemovePlayerItem(i, wepIdx);
						RemoveEdict(wepIdx);
					}
				}
				GivePlayerItem(i, "weapon_knife");
				new ent = GivePlayerItem(i,"weapon_deagle");
				bIsGoldenGun[ent]=true;
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent, 255, 215, 0);
				new ent2 = GivePlayerItem(i,"weapon_m249");
				bIsGoldenGun[ent2]=true;
				SetEntityRenderMode(ent2, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent2, 255, 215, 0);
				SetEntityModel(i, "models/player/slow/amberlyn/re5/majini_minigun/slow.mdl");
				
			}
		}
	}    
	PrintToChatAll("\x04[aSO] \x05%t","RONDA Plague!");
	// Mother zombies have been infected.    
	g_bZombieSpawned = true;
	// If infect timer is running, then kill it.    
	if (tInfect != INVALID_HANDLE)    
	{
		// Kill timer.
		KillTimer(tInfect);         
		// Reset timer handle.       
		tInfect = INVALID_HANDLE;    
	}
	rondaplague = true;
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
}
public Action:Ronda_PlagueA(client, args)
{
	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			//ZR_InfectClient(i, -1, true, false, false);
			//ZR_InfectClient(i);
			jugadores++;
		}
	}  
	new vida_total = (jugadores * 1000);
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			if(GetClientTeam(i) == 2)
			{
				ZR_InfectClient(i);
				SetEntityHealth(i, vida_total);
				CS_SwitchTeam(i, CS_TEAM_T);
				SetEntityModel(i, "models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.mdl");
				Es_Nemesis[i] = true;
			}
			else if(GetClientTeam(i) == 3)
			{
				SetEntityHealth(i, vida_total);
				CS_SwitchTeam(i, CS_TEAM_CT);
				bZombie[i] = false;
				g_AmmoInfi[i] = true;
				new wepIdx;
				// strip all weapons
				for (new s = 0; s < 4; s++)
				{
					if ((wepIdx = GetPlayerWeaponSlot(i, s)) != -1)
					{
						RemovePlayerItem(i, wepIdx);
						RemoveEdict(wepIdx);
					}
				}
				GivePlayerItem(i, "weapon_knife");
				new ent = GivePlayerItem(i,"weapon_deagle");
				bIsGoldenGun[ent]=true;
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent, 255, 215, 0);
				new ent2 = GivePlayerItem(i,"weapon_m249");
				bIsGoldenGun[ent2]=true;
				SetEntityRenderMode(ent2, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent2, 255, 215, 0);
				SetEntityModel(i, "models/player/slow/amberlyn/re5/majini_minigun/slow.mdl");
				
			}
		}
	}    
	PrintToChatAll("\x04[aSO] \x05%t","RONDA Plague!");
	// Mother zombies have been infected.    
	g_bZombieSpawned = true;
	// If infect timer is running, then kill it.    
	if (tInfect != INVALID_HANDLE)    
	{
		// Kill timer.
		KillTimer(tInfect);         
		// Reset timer handle.       
		tInfect = INVALID_HANDLE;    
	}
	rondaplague = true;
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
}
Ronda_Survivor()
{
	Survivor = JugadorAleatorio(); 
	if(Survivor < 0)
	return;
	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && Survivor != i)
		{
			
			ZR_InfectClient(i);
			jugadores++;
		}
	}   
	PrintToChatAll("\x04[aSO] \x05%t","RONDA SURVIVOR!");
	new vida_survivor = jugadores * 100;
	SetEntityHealth(Survivor, vida_survivor);
	CS_SwitchTeam(Survivor, CS_TEAM_CT);
	bZombie[Survivor] = false;
	g_AmmoInfi[Survivor] = true;
	new wepIdx;
	// strip all weapons
	for (new s = 0; s < 4; s++)
	{
		if ((wepIdx = GetPlayerWeaponSlot(Survivor, s)) != -1)
		{
			RemovePlayerItem(Survivor, wepIdx);
			RemoveEdict(wepIdx);
		}
	}
	GivePlayerItem(Survivor, "weapon_knife");
	new ent = GivePlayerItem(Survivor,"weapon_deagle");
	bIsGoldenGun[ent]=true;
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 255, 215, 0);
	new ent2 = GivePlayerItem(Survivor,"weapon_m249");
	bIsGoldenGun[ent2]=true;
	SetEntityRenderMode(ent2, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent2, 255, 215, 0);
	new random = GetRandomInt(1, 2);
	switch(random)
	{
	case 1:
		{
			EmitSoundToAll("franug/zombie_plague/survivor1.wav");
		}
	case 2:
		{
			EmitSoundToAll("franug/zombie_plague/survivor2.wav");
		}
	}
	// Move all clients to CT
	for (new x = 1; x <= MaxClients; x++)
	{        
		// If client isn't in-game, then stop.
		if (!IsClientInGame(x))
		{
			continue;
		}
		
		// If client is dead, then stop.
		if (!IsPlayerAlive(x) || x == Survivor)
		{
			continue;
		}
		
		// Switch client to CT team.
		CS_SwitchTeam(x, CS_TEAM_T);
	} 
	// Mother zombies have been infected.    
	g_bZombieSpawned = true;
	// If infect timer is running, then kill it.    
	if (tInfect != INVALID_HANDLE)    
	{
		// Kill timer.
		KillTimer(tInfect);         
		// Reset timer handle.       
		tInfect = INVALID_HANDLE;    
	}
	SetEntityModel(Survivor, "models/player/slow/amberlyn/re5/majini_minigun/slow.mdl");
	
	rondasurvivor = true;
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
}
Ronda_Nemesis()
{
	Nemesis = JugadorAleatorio();
	if(Nemesis < 0)
	return;
	//ServerCommand("zr_hitgroups 0");
	//ZR_InfectClient(Nemesis, -1, true, false, false);
	ZR_InfectClient(Nemesis);
	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			jugadores++;
		}
	}
	PrintToChatAll("\x04[aSO] \x05%t","RONDA NEMESIS!");
	new vida_nemesis = (jugadores * 1000);
	SetEntityHealth(Nemesis, vida_nemesis);
	CS_SwitchTeam(Nemesis, CS_TEAM_T);
	new random = GetRandomInt(1, 2);
	switch(random)
	{
	case 1:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis1.wav");
		}
	case 2:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis2.wav");
		}
	}
	// Move all clients to CT
	for (new x = 1; x <= MaxClients; x++)
	{        
		// If client isn't in-game, then stop.
		if (!IsClientInGame(x))
		{
			continue;
		}
		
		// If client is dead, then stop.
		if (!IsPlayerAlive(x) || x == Nemesis)
		{
			continue;
		}
		
		// Switch client to CT team.
		CS_SwitchTeam(x, CS_TEAM_CT);
		bZombie[x] = false;
	} 
	// Mother zombies have been infected.    
	g_bZombieSpawned = true;
	// If infect timer is running, then kill it.    
	if (tInfect != INVALID_HANDLE)    
	{
		// Kill timer.
		KillTimer(tInfect);         
		// Reset timer handle.       
		tInfect = INVALID_HANDLE;    
	}
	SetEntityModel(Nemesis, "models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.mdl");
	Es_Nemesis[Nemesis] = true;
	rondanemesis = true;
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
}
public Action:NemesisA(client, args)
{
	if(args < 1) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Utiliza: sm_nemesis <#userid|nombre>");
		return Plugin_Handled;
	}
	decl String:arg[30];
	GetCmdArg(1, arg, sizeof(arg));
	new target;
	if((target = FindTarget(client, arg)) == -1)
	{
		PrintToChat(client, "\x04[aSO] \x05Objetivo no encontrado");
		return Plugin_Handled; // Target not found...
	}
	Nemesis = target;
	if(Nemesis < 0)
	return Plugin_Continue;
	//ServerCommand("zr_hitgroups 0");
	//ZR_InfectClient(Nemesis, -1, true, false, false);
	ZR_InfectClient(Nemesis);
	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			jugadores++;
		}
	}
	PrintToChatAll("\x04[aSO] \x05%t","RONDA NEMESIS!");
	new vida_nemesis = (jugadores * 1000);
	SetEntityHealth(Nemesis, vida_nemesis);
	CS_SwitchTeam(Nemesis, CS_TEAM_T);
	new random = GetRandomInt(1, 2);
	switch(random)
	{
	case 1:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis1.wav");
		}
	case 2:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis2.wav");
		}
	}
	// Move all clients to CT
	for (new x = 1; x <= MaxClients; x++)
	{        
		// If client isn't in-game, then stop.
		if (!IsClientInGame(x))
		{
			continue;
		}
		
		// If client is dead, then stop.
		if (!IsPlayerAlive(x) || x == Nemesis)
		{
			continue;
		}
		
		// Switch client to CT team.
		CS_SwitchTeam(x, CS_TEAM_CT);
		bZombie[x] = false;
	} 
	// Mother zombies have been infected.    
	g_bZombieSpawned = true;
	// If infect timer is running, then kill it.    
	if (tInfect != INVALID_HANDLE)    
	{
		// Kill timer.
		KillTimer(tInfect);         
		// Reset timer handle.       
		tInfect = INVALID_HANDLE;    
	}
	rondanemesis = true;
	SetEntityModel(Nemesis, "models/player/pil/re_chronicles/nemesis_larger/nemesis_pil.mdl");
	Es_Nemesis[Nemesis] = true;
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
	return Plugin_Continue;
}
public Action:SurvivorA(client, args)
{
	if(args < 1) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Utiliza: sm_survivor <#userid|nombre>");
		return Plugin_Handled;
	}
	decl String:arg[30];
	GetCmdArg(1, arg, sizeof(arg));
	new target;
	if((target = FindTarget(client, arg)) == -1)
	{
		PrintToChat(client, "\x04[aSO] \x05Objetivo no encontrado");
		return Plugin_Handled; // Target not found...
	}
	Survivor = target;
	if(Survivor < 0)
	return Plugin_Continue;
	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && Survivor != i)
		{
			//ZR_InfectClient(i, -1, true, false, false);
			ZR_InfectClient(i);
			jugadores++;
		}
	}   
	PrintToChatAll("\x04[aSO] \x05%t","RONDA SURVIVOR!");
	new vida_survivor = jugadores * 100;
	SetEntityHealth(Survivor, vida_survivor);
	CS_SwitchTeam(Survivor, CS_TEAM_CT);
	bZombie[Survivor] = false;
	g_AmmoInfi[Survivor] = true;
	new wepIdx;
	// strip all weapons
	for (new s = 0; s < 4; s++)
	{
		if ((wepIdx = GetPlayerWeaponSlot(Survivor, s)) != -1)
		{
			RemovePlayerItem(Survivor, wepIdx);
			RemoveEdict(wepIdx);
		}
	}
	GivePlayerItem(Survivor, "weapon_knife");
	new ent = GivePlayerItem(Survivor,"weapon_deagle");
	bIsGoldenGun[ent]=true;
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 255, 215, 0);
	new ent2 = GivePlayerItem(Survivor,"weapon_m249");
	bIsGoldenGun[ent2]=true;
	SetEntityRenderMode(ent2, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent2, 255, 215, 0);
	
	new random = GetRandomInt(1, 2);
	switch(random)
	{
	case 1:
		{
			EmitSoundToAll("franug/zombie_plague/survivor1.wav");
		}
	case 2:
		{
			EmitSoundToAll("franug/zombie_plague/survivor2.wav");
		}
	}
	// Move all clients to CT
	for (new x = 1; x <= MaxClients; x++)
	{        
		// If client isn't in-game, then stop.
		if (!IsClientInGame(x))
		{
			continue;
		}
		
		// If client is dead, then stop.
		if (!IsPlayerAlive(x) || x == Survivor)
		{
			continue;
		}
		
		// Switch client to CT team.
		CS_SwitchTeam(x, CS_TEAM_T);
	} 
	// Mother zombies have been infected.    
	g_bZombieSpawned = true;
	// If infect timer is running, then kill it.    
	if (tInfect != INVALID_HANDLE)    
	{
		// Kill timer.
		KillTimer(tInfect);         
		// Reset timer handle.       
		tInfect = INVALID_HANDLE;    
	}
	rondasurvivor = true;
	SetEntityModel(Survivor, "models/player/slow/amberlyn/re5/majini_minigun/slow.mdl");
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
	
	return Plugin_Continue;
}
stock DealDamage(nClientVictim, nDamage, nClientAttacker = 0, nDamageType = DMG_GENERIC, String:sWeapon[] = "")
// ----------------------------------------------------------------------------
{
	// taken from: http://forums.alliedmods.net/showthread.php?t=111684
	// thanks to the authors!
	if(	nClientVictim > 0 &&
			IsValidEdict(nClientVictim) &&
			IsClientInGame(nClientVictim) &&
			IsPlayerAlive(nClientVictim) &&
			nDamage > 0)
	{
		new EntityPointHurt = CreateEntityByName("point_hurt");
		if(EntityPointHurt != 0)
		{
			new String:sDamage[16];
			IntToString(nDamage, sDamage, sizeof(sDamage));
			new String:sDamageType[32];
			IntToString(nDamageType, sDamageType, sizeof(sDamageType));
			DispatchKeyValue(nClientVictim,			"targetname",		"war3_hurtme");
			DispatchKeyValue(EntityPointHurt,		"DamageTarget",	"war3_hurtme");
			DispatchKeyValue(EntityPointHurt,		"Damage",				sDamage);
			DispatchKeyValue(EntityPointHurt,		"DamageType",		sDamageType);
			if(!StrEqual(sWeapon, ""))
			DispatchKeyValue(EntityPointHurt,	"classname",		sWeapon);
			DispatchSpawn(EntityPointHurt);
			AcceptEntityInput(EntityPointHurt,	"Hurt",					(nClientAttacker != 0) ? nClientAttacker : -1);
			DispatchKeyValue(EntityPointHurt,		"classname",		"point_hurt");
			DispatchKeyValue(nClientVictim,			"targetname",		"war3_donthurtme");
			RemoveEdict(EntityPointHurt);
		}
	}
}
public Action:Command_Say(client, argc)
{
	if (barricada)
	{
		decl String:args[192];
		
		GetCmdArgString(args, sizeof(args));
		//ReplaceString(args, sizeof(args), "\"", "");
		
		if (StrEqual(args, "!zprops", false))
		{
			if (!IsPlayerAlive(client))
			return Plugin_Handled;
			
			MainMenu(client);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}
MainMenu(client)
{
	new Handle:menu_main = CreateMenu(MainMenuHandle);
	
	SetGlobalTransTarget(client);
	
	SetMenuTitle(menu_main, "%t\n ", "Menu title", g_iCredits[client]);
	
	decl String:propname[64];
	decl String:display[64];
	
	KvRewind(kvProps);
	if (KvGotoFirstSubKey(kvProps))
	{
		do
		{
			KvGetSectionName(kvProps, propname, sizeof(propname));
			new cost = KvGetNum(kvProps, "cost");
			Format(display, sizeof(display), "%t", "Menu option", propname, cost);
			
			if (g_iCredits[client] >= cost)
			{
				AddMenuItem(menu_main, propname, display);
			}
			else
			{
				AddMenuItem(menu_main, propname, display, ITEMDRAW_DISABLED);
			}
		} while (KvGotoNextKey(kvProps));
	}
	
	DisplayMenu(menu_main, client, MENU_TIME_FOREVER);
}
public MainMenuHandle(Handle:menu_main, MenuAction:action, client, slot)
{
	if (action == MenuAction_Select)
	{
		decl String:propname[64];
		if (GetMenuItem(menu_main, slot, propname, sizeof(propname)))
		{
			KvRewind(kvProps);
			if (KvJumpToKey(kvProps, propname))
			{
				new cost = KvGetNum(kvProps, "cost");
				if (g_iCredits[client] < cost)
				{
					PrintToChat(client, "\x04[%t] \x01%t", "ZProp", "Insufficient credits", g_iCredits[client], cost);
					MainMenu(client);
					
					return;
				}
				if (g_props[client] >= 15)
				{
					PrintToChat(client, "\x04[aSO] \x05%t","Has superado el limite de props que puedes poner. Maximo: 15");
					MainMenu(client);
					
					return;
				}
				new vida13 = KvGetNum(kvProps, "vida");
				
				new Float:vecOrigin[3];
				new Float:vecAngles[3];
				
				GetClientAbsOrigin(client, vecOrigin);
				GetClientAbsAngles(client, vecAngles);
				
				vecAngles[0] = GetEntDataFloat(client, offsEyeAngle0);
				
				vecOrigin[2] += 100;
				
				decl Float:vecFinal[3];
				AddInFrontOf(vecOrigin, vecAngles, 35, vecFinal);
				
				decl String:propmodel[128];
				KvGetString(kvProps, "model", propmodel, sizeof(propmodel));
				
				decl String:proptype[24];
				KvGetString(kvProps, "type", proptype, sizeof(proptype), "prop_physics");
				
				new prop = CreateEntityByName(proptype);

				decl String:bomba[24];
				KvGetString(kvProps, "bombazo", bomba, 24, "no");

				if (StrContains(bomba, "no", true) == -1)
				{
					DispatchKeyValue(prop, "exploderadius", "1000");
					DispatchKeyValue(prop, "explodedamage", "50");
				}
				
				PrecacheModel(propmodel);
				SetEntityModel(prop, propmodel);
				DispatchKeyValue(prop, "classname", "barricada_prop");
				
				DispatchSpawn(prop);
				
				TeleportEntity(prop, vecFinal, NULL_VECTOR, NULL_VECTOR);
				SetEntityRenderColor(prop, 255, 0, 0, 255);
				SetEntProp(prop, Prop_Data, "m_takedamage", 2, 1);
				SetEntProp(prop, Prop_Data, "m_iHealth", vida13);
				SDKHook(prop, SDKHook_OnTakeDamage, OnTakeDamage2);
				
				g_iCredits[client] -= cost;
				
				ZProp_HudHint(client, "Credits left spend", cost, g_iCredits[client]);
				PrintToChat(client, "\x04[%t] \x01%t", "ZProp", "Spawn prop", propname);
				g_props[client] += 1;
				MainMenu(client);
			}
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu_main);
	}
}
public Action:NoProps(client,args)
{ 
	new index2 = -1;
	while ((index2 = FindEntityByClassname2(index2, "barricada_prop")) != -1)
	RemoveEdict(index2);
	decl String:nombre[32];
	GetClientName(client, nombre, sizeof(nombre));
	PrintToChat(client, "\x04[aSO] \x05%t","El admin ha borrado todos los props que se habian puesto", nombre); // english
	return Plugin_Handled;
}
// Thanks to exvel for the function below. Exvel posted that in the FindEntityByClassname API.
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
AddInFrontOf(Float:vecOrigin[3], Float:vecAngle[3], units, Float:output[3])
{
	new Float:vecView[3];
	GetViewVector(vecAngle, vecView);
	
	output[0] = vecView[0] * units + vecOrigin[0];
	output[1] = vecView[1] * units + vecOrigin[1];
	output[2] = vecView[2] * units + vecOrigin[2];
}
GetViewVector(Float:vecAngle[3], Float:output[3])
{
	output[0] = Cosine(vecAngle[1] / (180 / FLOAT_PI));
	output[1] = Sine(vecAngle[1] / (180 / FLOAT_PI));
	output[2] = -Sine(vecAngle[0] / (180 / FLOAT_PI));
}
ZProp_HudHint(client, any:...)
{
	SetGlobalTransTarget(client);
	
	decl String:phrase[192];
	
	VFormat(phrase, sizeof(phrase), "%t", 2);
	
	new Handle:hHintText = StartMessageOne("HintText", client);
	if (hHintText != INVALID_HANDLE)
	{
		BfWriteByte(hHintText, -1); 
		BfWriteString(hHintText, phrase);
		EndMessage();
	}
}
public Action:Dar(client, args)
{
	if(args < 2) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Utiliza: sm_dar <#userid|nombre> [cantidad]");
		return Plugin_Handled;
	}
	decl String:arg[30], String:arg2[10];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	new amount = StringToInt(arg2);
	if(amount > g_iCredits[client])
	{
		PrintToChat(client, "\x04[aSO] \x05%t","Tu no tienes tantos creditos!");
		return Plugin_Handled; // Target not found...
	}
	if(amount <= 0)
	{
		PrintToChat(client, "\x04[aSO] \x05%t","No puedes dar menos de 0 creditos!");
		return Plugin_Handled; // Target not found...
	}
	new target;
	if((target = FindTarget(client, arg, false, false)) == -1)
	{
		PrintToChat(client, "\x04[aSO] \x05Objetivo no encontrado (not found)");
		return Plugin_Handled; // Target not found...
	}
	//    SetEntProp(target, Prop_Data, "m_iDeaths", amount);
	g_iCredits[target] += amount;
	g_iCredits[client] -= amount;
	decl String:nombre[32];
	GetClientName(client, nombre, sizeof(nombre));
	decl String:nombre2[32];
	GetClientName(target, nombre2, sizeof(nombre2));
	PrintToChat(client, "\x04[aSO] \x05%t","Entregados", amount, nombre2);
	PrintToChat(target, "\x04[aSO] \x05%t","Te ha Entregado", amount, nombre);
	return Plugin_Continue;
} 
public Action:Darme(client, args)
{
	decl String:arg1[10];
	GetCmdArg(1, arg1, sizeof(arg1));
	new amount = StringToInt(arg1);
	g_iCredits[client] += amount;
	PrintToChat(client, "\x04[aSO] \x05Te has dado %i creditos", amount);
	return Plugin_Continue;
}  
public Action:VerCreditosClient(client, args)
{
	if(args < 1) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Utiliza: sm_vercreditos <#userid|nombre>");
		return Plugin_Handled;
	}
	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 
	// Process the targets 
	decl String:strTargetName[MAX_TARGET_LENGTH]; 
	decl TargetList[MAXPLAYERS], TargetCount; 
	decl bool:TargetTranslate; 
	if ((TargetCount = ProcessTargetString(strTarget, 0, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
					strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{ 
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	} 
	// Apply to all targets 
	for (new i = 0; i < TargetCount; i++) 
	{ 
		new iClient = TargetList[i]; 
		if (IsClientInGame(iClient)) 
		{ 
			//g_iCredits[iClient] = amount;
			PrintToChat(client, "\x04[aSO] \x05%N Creditos: %i", iClient, g_iCredits[iClient]);
			//PrintToChat(client, "\x04[aSO] \x05Puesto %i creditos en el jugador %N", amount, iClient);
		} 
	}   
	return Plugin_Continue;
}
public Action:PlayerJumpZM(any:client)
{
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (Es_Nemesis[client]) saltoalto13(client);
}
saltoalto13(client)
{
	new Float:finalvec[3];
	finalvec[0]=GetEntDataFloat(client,VelocityOffset_0)*GetConVarFloat(hPush)/2.0;
	finalvec[1]=GetEntDataFloat(client,VelocityOffset_1)*GetConVarFloat(hPush)/2.0;
	finalvec[2]=GetConVarFloat(hHeight)*50.0;
	SetEntDataVector(client,BaseVelocityOffset,finalvec,true);
	new Float:pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	new number = GetRandomInt(1, 3);
	switch (number)
	{
	case 1:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis_pain1.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
		}
	case 2:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis_pain2.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
		}
	case 3:
		{
			EmitSoundToAll("franug/zombie_plague/nemesis_pain3.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
		}
	}
}
//  Things to do on Gameframe & RunCmd
public OnGameFrame() 
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && IsClientConnected(i) && GetClientTeam(i) > 1 && IsPlayerAlive(i)) 
		{
			if (g_Saltador[i])
			{
				DoubleJump(i);
			}
		}
	}
}
stock DoubleJump(const any:client) {
	new fCurFlags	= GetEntityFlags(client);		// current flags
	new fCurButtons	= GetClientButtons(client);		// current buttons
	
	if (g_fLastFlags[client] & FL_ONGROUND) {		// was grounded last frame
		if (
				!(fCurFlags & FL_ONGROUND) &&			// becomes airbirne this frame
				!(g_fLastButtons[client] & IN_JUMP) &&	// was not jumping last frame
				fCurButtons & IN_JUMP					// started jumping this frame
				) {
			OriginalJump(client);					// process jump from the ground
		}
	} else if (										// was airborne last frame
			fCurFlags & FL_ONGROUND						// becomes grounded this frame
			) {
		Landed(client);								// process landing on the ground
	} else if (										// remains airborne this frame
			!(g_fLastButtons[client] & IN_JUMP) &&		// was not jumping last frame
			fCurButtons & IN_JUMP						// started jumping this frame
			) {
		ReJump(client);								// process attempt to double-jump
	}
	
	g_fLastFlags[client]	= fCurFlags;				// update flag state for next frame
	g_fLastButtons[client]	= fCurButtons;			// update button state for next frame
}
stock OriginalJump(const any:client) {
	g_iJumps[client]++;	// increment jump count
}
stock Landed(const any:client) {
	g_iJumps[client] = 0;	// reset jumps count
}
stock ReJump(const any:client) {
	if ( 1 <= g_iJumps[client] <= g_iJumpMax) {						// has jumped at least once but hasn't exceeded max re-jumps
		g_iJumps[client]++;											// increment jump count
		decl Float:vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);	// get current speeds
		
		vVel[2] = g_flBoost;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);		// boost player
	}
}
public OnEntityCreated(entity, const String:classname[])
{
	if (IsValidEntity(entity))
	{
		
		if (!strcmp(classname, "hegrenade_projectile"))
		{
			CreateTimer(0.1, timer1345, entity);
		}
		else if (!strcmp(classname, "flashbang_projectile"))
		{
			CreateTimer(0.1, timer69, entity);
		}
		else if (!strcmp(classname, "smokegrenade_projectile"))
		{
			if (b_smoke_freeze)
			{
				BeamFollowCreate(entity, FreezeColor);
				CreateTimer(1.3, CreateEvent_SmokeDetonate, entity, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				BeamFollowCreate(entity, SmokeColor);
			}
		}
		else if (b_smoke_freeze && !strcmp(classname, "env_particlesmokegrenade"))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
}
public Action:timer1345(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		
		if (StrEqual(classname, "hegrenade_projectile"))
		{
			new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if (IsValidClient(client) && IsPlayerAlive(client))
			{
				if (ZR_IsClientZombie(client))
				{
					TE_SetupBeamFollow(entity, BeamSprite, 0, 1.0, 10.0, 10.0, 5, NADE_COLOR);
					TE_SendToAll();	
				}
				else
				{
					if(nade_count[client] > 0)
					{
						TE_SetupBeamFollow(entity, BeamSprite,	0, 1.0, 10.0, 10.0, 5, NADE_COLOR2);
						TE_SendToAll();	
					}
					else
					{
						BeamFollowCreate(entity, FragColor);
						if (b_napalm_he)
						{
							IgniteEntity(entity, 2.0);
						}
					}
				}
			}
		}
	}
	return Plugin_Stop;
}  
public Action:timer69(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		
		if (StrEqual(classname, "flashbang_projectile"))
		{
			new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if (IsValidClient(client) && IsPlayerAlive(client))
			{
				if (!cuchillos[client])
				{
					if (b_flash_light)
					{
						CreateTimer(1.0, DoFlashLight, entity, TIMER_FLAG_NO_MAPCHANGE);
					}
					BeamFollowCreate(entity, FlashColor);
				}
			}
		}
	}
	return Plugin_Stop;
} 
public OnClientPutInServerD(client)
{  
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidClient(attacker))
	{
		//PrintToChat(attacker, "atacado");
		new WeaponIndex = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		if (WeaponIndex < 0) return Plugin_Continue;
		if(IsValidEntity(WeaponIndex) && bIsGoldenGun[WeaponIndex])  
		{ 
			//PrintToChat(attacker, "atacado con dorada");
			if (GetClientTeam(attacker) != GetClientTeam(victim))
			{
				IgniteEntity(victim, 1.0);
				damage = (damage * GetConVarFloat(dorada));
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage2(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidEdict(victim))
	{
		if (IsValidClient(attacker))
		{
			decl String:szWeapon[32];
			GetClientWeapon(attacker, szWeapon, 32);
			if (StrContains(szWeapon, "knife", true) == -1)
			{
				return Plugin_Handled;
			}
		}
		new mullado = GetRandomInt(1, 2);
		switch (mullado)
		{
			case 1:
			{
				new Float:pos[3];
				GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
				EmitSoundToAll("physics/metal/metal_box_break1.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
			}
			case 2:
			{
				new Float:pos[3];
				GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
				EmitSoundToAll("physics/metal/metal_box_break2.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
			}
		}
	}
	return Plugin_Continue;
}

