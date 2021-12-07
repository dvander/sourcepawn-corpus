#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.4"
#define INFECTED_TEAM	 4
#define RED_TEAM	 3
#define BLUE_TEAM	 2
#define NO_TEAM	 1
#define MAX_SURVIVORS GetConVarInt(FindConVar("survivor_limit"))
#define SNIPER	 1
#define ASSAULT 2
#define MEDIC 3
#define SHOTGUN 4
#define HEAVYGUN 5
#define CUSTOM 6
#define ALLOWSPAWN	 2
#define DISALLOWSPAWN	 1
#define MULTIONE 	"ui/pickup_guitarriff10.wav"
#define MULTITWO 	"player/orch_hit_csharp_short.wav"
#define MULTITHREE 	"player/hunter/voice/warn/hunter_warn_10.wav"
#define MULTIFOUR 	"player/charger/voice/attack/charger_charge_02.wav"
#define MULTIFIVE	"player/tank/voice/pain/tank_fire_06.wav"
#define WINSOUND	"music/safe/themonsterswithout.wav"
#define FIRSTBLOODELLIS	"player/survivor/voice/mechanic/battlecry01.wav"
#define FIRSTBLOODROCHELLE	"player/survivor/voice/producer/battlecry02.wav"
#define FIRSTBLOODCOACH	"player/survivor/voice/coach/battlecry09.wav"
#define FIRSTBLOODNICK	"player/survivor/voice/gambler/battlecry03.wav"
#define BOOM_ONE_NICK "player/survivor/voice/gambler/cough03.wav"
#define BOOM_TWO_NICK "player/survivor/voice/gambler/deathscream02.wav"
#define BOOM_THREE_NICK "player/survivor/voice/gambler/deathscream05.wav"
#define BOOM_ONE_COACH "player/survivor/voice/gambler/cough08.wav"
#define BOOM_TWO_COACH "player/survivor/voice/gambler/deathscream01.wav"
#define BOOM_THREE_COACH "player/survivor/voice/gambler/deathscream02.wav"
#define BOOM_ONE_ELLIS "player/survivor/voice/gambler/cough02.wav"
#define BOOM_TWO_ELLIS "player/survivor/voice/gambler/deathscream01.wav"
#define BOOM_THREE_ELLIS "player/survivor/voice/gambler/deathscream03.wav"
#define BOOM_ONE_ROCHELLE "player/survivor/voice/gambler/cough01.wav"
#define BOOM_TWO_ROCHELLE "player/survivor/voice/gambler/deathscream01.wav"
#define BOOM_THREE_ROCHELLE "player/survivor/voice/gambler/hurtcritical01.wav"
#define DARK_CARNIVAL 1
#define THE_PARISH 2
#define DEAD_CENTER 3
#define SWAMP_FEVER 4
#define HARD_RAIN 5
#define MODEL_V_PIPEBOMB "models/v_models/v_pipebomb.mdl"
#define MODEL_V_VOMITJAR "models/v_models/v_bile_flask.mdl"
#define MODEL_V_MOLOTOV "models/v_models/v_molotov.mdl"
#define MODEL_PROPANE "models/props_junk/propanecanister001a.mdl"
#define MODEL_BARREL "models/props_junk/barrel_fire.mdl"
#define MODEL_GASCAN "models/props_junk/gascan001a.mdl"
#define MODEL_W_PIPEBOMB "models/w_models/weapons/w_eq_pipebomb.mdl"
#define MODEL_W_VOMITJAR "models/w_models/weapons/w_eq_bile_flask.mdl"
#define MODEL_W_MOLOTOV "models/w_models/weapons/w_eq_molotov.mdl"
#define SOUND_PIPEBOMB "weapons/hegrenade/beep.wav"
#define SOUND_VOMITJAR ")weapons/ceda_jar/ceda_jar_explode.wav"
#define SOUND_MOLOTOV "weapons/molotov/fire_ignite_2.wav"
#define MODEL_V_PISTOL "models/v_models/v_pistola.mdl"
#define MODEL_V_DUALPISTOL "models/v_models/v_dual_pistola.mdl"
#define MODEL_V_MAGNUM "models/v_models/v_desert_eagle.mdl"
#define SOUND_PISTOL "weapons/pistol/gunfire/pistol_fire.wav"
#define SOUND_DUAL_PISTOL ")weapons/pistol/gunfire/pistol_dual_fire.wav"
#define SOUND_MAGNUM ")weapons/magnum/gunfire/magnum_shoot.wav"
#define SMOKE_DAMAGE "player/survivor/voice/choke_5.wav"
#define BOUNCE_TIME 1 //was 10
#define TEAM_SURVIVOR 2
#define SMOKEGRENADE "particle/particle_smokegrenade1.vmt"
#define SPRITE_HALO "materials/sprites/halo01.vmt"
#define SPRITE_BEAM "materials/sprites/laserbeam.vmt"
#define CRYSTAL_BEAM "materials/sprites/crystal_beam1.vmt"//test this OUT!!
#define VERTICAL 1
#define SPRITE_GLOW "materials/sprites/glow01.vmt"
#define MOVETYPE_WALK 2
#define MOVETYPE_FLYGRAVITY 5
#define MOVECOLLIDE_DEFAULT 0
#define MOVECOLLIDE_FLY_BOUNCE 1

new String:g_sSound[255]	= "vehicles/v8/v8_idle_loop1.wav";
new g_Crystalsprite;
new g_GlowSprite;
new RandomBonusMode;
new humancounter;
new mapNum;
new PropMoveCollide;
new PropMoveType;
new PropVelocity;
new Restarting;
new random_teleport;
new Handle:JetPacks;
new Handle:g_t_PipeTicks;
new Handle:h_scorehandlerBoomer;
new g_PipebombBounce[MAXPLAYERS+1];
new Handle:h_RoundEnd = INVALID_HANDLE;
static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;
new Handle:L4DDMConf = INVALID_HANDLE;
new Float:g_PlayerGameTime[MAXPLAYERS+1];
new Handle:FollowBeamTimers[MAXPLAYERS];
new IamNowFuelling[MAXPLAYERS];
new Handle:L4DTakeoverSHS = INVALID_HANDLE;
new Handle:L4DTakeoverTOB = INVALID_HANDLE;
new Handle:ClientTimer[65];
new Handle:RespawnTimer[MAXPLAYERS + 1];
new MoloSecondsIn[MAXPLAYERS + 1];
new JetpackFuel[MAXPLAYERS + 1];
new Handle:RespawnTime;
new Handle:damage_multiplier;
new g_got_biled[MAXPLAYERS + 1];
new JumpTimer[MAXPLAYERS + 1];
new Handle: g_biled_countdown[MAXPLAYERS + 1];
new Handle: g_bile_timer[MAXPLAYERS + 1];
new g_biled_timeleft[MAXPLAYERS + 1];
new bool:g_b_AllowThrow[MAXPLAYERS+1];
new CustomMagic[MAXPLAYERS + 1];
new KillBonuses[MAXPLAYERS + 1];
new g_ActiveWeaponOffset;
new g_MagnumModel;
new g_DualPistolModel;
new g_PistolModel;
new AlphaBoomer[MAXPLAYERS+1];
new Test_Sprites[MAXPLAYERS+1];
new Handle:g_t_GrenadeOwner;
new Handle:g_h_GrenadeTimer[MAXPLAYERS+1];
new Remove_dropped[MAXPLAYERS + 1];
new Handle:CountdownS[MAXPLAYERS + 1];
new Handle:Streak_sound[MAXPLAYERS + 1];
new Float: Bullet_impact[MAXPLAYERS + 1][3];
new Handle:SmokerPositioning[MAXPLAYERS + 1];
new CanISpawn[MAXPLAYERS+1];
new HaveISpawned[MAXPLAYERS+1];
new primaryChosen[MAXPLAYERS+1];
new GrenadeChosen[MAXPLAYERS+1];
new SecondaryChosen[MAXPLAYERS+1];
new DoIHaveMyBonus[MAXPLAYERS+1];
new PrimaryGiven[MAXPLAYERS+1];
new SecondaryGiven[MAXPLAYERS+1];
new EmergencyGiven[MAXPLAYERS+1];
new EmergencyChosen[MAXPLAYERS+1];
new GrenadeGiven[MAXPLAYERS+1];
new WeaponsGiven[MAXPLAYERS+1];
new TeamState[MAXPLAYERS+1];
new SurvivorClass[MAXPLAYERS+1];
new playerscore[MAXPLAYERS+1];
new Deaths[MAXPLAYERS+1];
new playerscoreTemp[MAXPLAYERS+1];
new MAX_scores[MAXPLAYERS+1];
new iHaveChompsky[MAXPLAYERS+1];
new Handle:Each_round_time;
new Handle:MaxKills;
new Handle:MaxKillsFFA;
new String:Red[] = "255 0 0";
new String:Blue[] = "0 0 255";
new Handle: GameType;
new Handle:h_BonusGames;
new Handle:OddGnomeLimit;
new Handle:JetPackFuel;
new Handle: WelcomeTimers[MAXPLAYERS + 1];
new Handle: JetRefuelTimers[MAXPLAYERS + 1];
new Handle: DisableTheHud[MAXPLAYERS + 1];
new Handle:hurtdata[MAXPLAYERS+1][128];
new Handle:timer_handle[MAXPLAYERS+1][128];
new Handle:h_CvarVomitjarRadius;
new Handle:h_CvarSmokeRadius;
new Handle:h_CvarVomitjarGlowDuration;
new Handle:h_CvarMolotovCLOUDDuration;
new Handle:h_CvarPipebombDuration;
new Handle:h_CvarMoloDamage;
new SecondstoGo[MAXPLAYERS + 1];
new MultipleKill[MAXPLAYERS + 1];
//new Handle: MultipleKill_Timer[MAXPLAYERS + 1];
new clientX = 0;
new Full_score_red =0;
new Full_score_blue =0;
new bool:First_fourMinutes;
new bool:Stop_spawning;
new bool:initial_stage;
new bool:Force_spawns;
new bool:Round_two;
new bool:First_blood;
new bool:Round_started;
new bool:Stop_guns;
new bool:Team_chosen;
static LagMovement = 0;
new Distance;
new Ent;
new Float:Teleport_one[3];
new Float:Teleport_two[3];
new Float:Teleport_three[3];
new Float:Teleport_four[3];
new Float:Teleport_five[3];
new Float:Teleport_six[3];
new Float:Teleport_seven[3];
new Float:Teleport_eight[3];
new Float:Teleport_nine[3];
new Float:Teleport_ten[3];
new Float:Red_Teleport[3];
new Float:Blue_Teleport[3];
new g_sprite;
new secondsToGo_two;
new Float:myPos[3], Float:trsPos[3], Float:trsPos002[3],Float:GnomeLocation[3];
new Float:Boundaries[3];//keeps players inside the fighting area
new GRENADE_TYPE:g_PlayerIncapacitated[MAXPLAYERS+1];
new g_VomitjarModel,g_PipebombModel,g_MolotovModel, g_HaloSprite;
new g_ThrewGrenade[MAXPLAYERS+1];
new bool:g_b_InAction[MAXPLAYERS+1];
new bool:g_boomed[MAXPLAYERS+1];
new AllowHighJump[MAXPLAYERS+1];
new bool:GnomeSpawned;
new UserMsg:g_FadeUserMsgId; // UserMessageId for Fade.
new scoreset;
new g_BeamSprite;
new propinfoghost;
new bool:elig;
new bool:Flying[MAXPLAYERS+1];
new bool:Eligible[MAXPLAYERS+1];
enum GRENADE_TYPE
{
	NONE,
	PIPEBOMB,
	MOLOTOV,
	VOMITJAR
}

new const String:g_VoiceMolotovNick[4][] =
{
	"grenade03",
	"grenade04",
	"grenade06",
	"grenade08"
}

new const String:g_VoiceMolotovRochelle[3][] =
{
	"grenade03",
	"grenade04",
	"grenade06"
}

new const String:g_VoiceMolotovEllis[4][] =
{
	"grenade05",
	"grenade06",
	"grenade08",
	"grenade10"
}

new const String:g_VoiceMolotovCoach[3][] =
{
	"grenade02",
	"grenade04",
	"grenade05"
}

new const String:g_VoicePipebombNick[7][] =
{
	"grenade01",
	"grenade02",
	"grenade05",
	"grenade07",
	"grenade09",
	"grenade11",
	"grenade13"
}

new const String:g_VoiceVomitjarNick[][] =
{
	"boomerjar08",
	"boomerjar09",
	"boomerjar10"
}

new const String:g_VoicePipebombRochelle[4][] =
{
	"grenade01",
	"grenade02",
	"grenade05",
	"grenade07"
}

new const String:g_VoiceVomitjarRochelle[3][] =
{
	"boomerjar07",
	"boomerjar08",
	"boomerjar09"
}

new const String:g_VoicePipebombCoach[6][] =
{
	"grenade01",
	"grenade03",
	"grenade06",
	"grenade07",
	"grenade11",
	"grenade12"
}

new const String:g_VoicePipebombEllis[8][] =
{
	"grenade01",
	"grenade02",
	"grenade03",
	"grenade07",
	"grenade09",
	"grenade11",
	"grenade12",
	"grenade13"
}

new const String:g_VoiceVomitjarEllis[6][] =
{
	"boomerjar08",
	"boomerjar09",
	"boomerjar10",
	"boomerjar12",
	"boomerjar13",
	"boomerjar14"
}

new const String:g_VoiceVomitjarCoach[3][] =
{
	"boomerjar09",
	"boomerjar10",
	"boomerjar11"
}

public Plugin:myinfo =
{
	name = "[L4D2] Team_Deathmatch",
	author = "Fleep",
	description = "Play Survivors VS survivors in L4D2",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=136615"
}

public OnPluginStart()
{
	hGameConf = LoadGameConfigFile("l4d2Teamdm");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
	hRoundRespawn = EndPrepSDKCall();
	if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
	//Look up what game we're running,
	decl String:game[16]
	GetGameFolderName(game, sizeof(game))
	//and don't load if it's not L4D2.
	if (!StrEqual(game, "left4dead2", false)) SetFailState("Plugin supports Left 4 Dead 2 only.")
	CreateConVar("L4D2_TeamDeathmatch_version", PLUGIN_VERSION, "Version of L4D2 Survivors Deathmatch", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	GameType = CreateConVar("GameType","2", "0=Plugin Off, 1=TeamDeathmatch, play as a team 2=Free For All deathmatch, play on your own.", FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,2.0);
	RespawnTime = CreateConVar("RespawnTime", "5", "How many seconds till the Survivor respawns (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
	damage_multiplier= CreateConVar("damage_multiplier","1.0", "For those of you who don't think default damage is good enough(Not recommended above 1.5)", FCVAR_PLUGIN);
	Each_round_time = CreateConVar("Each_round_time", "300.0", "How many seconds does each round last (Def 300, 5 minutes)", FCVAR_PLUGIN, true, 0.0, false, _);
	MaxKills = CreateConVar("MaxKills", "30", "How many Kills does one team need to get to win (Def 30, adjust according to amount of players you intend to have(<--4 vs 4 for these values))", FCVAR_PLUGIN, true, 0.0, false, _);
	MaxKillsFFA = CreateConVar("MaxKillsFFA", "20", "How many Kills a player need to get in Free for all deathmatch (Def 20, adjust according to amount of players you intend to have(<--8 for these values))", FCVAR_PLUGIN, true, 0.0, false, _);
	h_CvarVomitjarRadius = CreateConVar("l4d_vomitjar_radius", "140.0", "Vomitjar radius, how close does the bile need to be to get the player", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 500.0)
	h_CvarSmokeRadius = CreateConVar("l4d_Smoke_radius", "200.0", "Molotov damage smoke radius, how close does the smoke from the molo need to be to damage the player", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 500.0)
	h_CvarVomitjarGlowDuration = CreateConVar("l4d_vomitjar_glowduration", "4.0", "Vomitjar glow duration, how long does the Biled person stay blind", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 50.0)
	h_CvarMolotovCLOUDDuration = CreateConVar("l4d_Molotov_duration", "8.0", "Molotovs create clouds that damage enemies, how long do does the CLOUD last?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 30.0)
	h_CvarMoloDamage= CreateConVar("l4d_Molotov_damage", "12.0", "Molotov clouds damages players,how much damage per second does the smoke cause", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 30.0)
	h_CvarPipebombDuration = CreateConVar("l4d_pipebomb_duration", "2.0", "Pipebomb duration, how long untill pipe bomb detonates", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 30.0)
	h_BonusGames = CreateConVar("l4d_BonusGames","1", "0=No bonus gamemodes, 1=Bonus gamemodes active, these replace 2nd ROUNDS,Current gamemodes available; INFECTION, ODDGNOME(chosen randomly)",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,2.0);
	OddGnomeLimit = CreateConVar("l4d_OddGnomeScore_Limit","50", "How many points for a player to win in OddGnome, for every 3 secs a player holds the gnome he earns 1 point",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,100.0);
	JetPackFuel = CreateConVar("l4d_JetPackFuel","100", "How much fuel does a jetpack have, the jetpack refuels itself after 4 secs of being empty(needs l4d_JetPacks turned on)",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,500.0);
	JetPacks = CreateConVar("l4d_JetPacks", "1", "Allow players to use Jetpacks in deathmatch mode?.",FCVAR_PLUGIN,true,0.0,true,1.0);
	AutoExecConfig(true, "L4D2_Survivors_deathmatch");
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon")
	PropMoveCollide = FindSendPropOffs("CBaseEntity",   "movecollide");
	PropMoveType    = FindSendPropOffs("CBaseEntity",   "movetype");
	PropVelocity    = FindSendPropOffs("CBasePlayer",   "m_vecVelocity[0]");
	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	if (FileExists("addons/sourcemod/gamedata/l4d2Teamdm.txt"))
	{
		// SDK handles for survivor bot takeover
		L4DDMConf = LoadGameConfigFile("l4d2Teamdm");
		
		if (L4DDMConf == INVALID_HANDLE)
		{
			SetFailState("L4d2 Team Deathmatch could not load gamedata/l4d2Teamdm.txt");
			return;
		}
		else
		{
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(L4DDMConf, SDKConf_Signature, "SetHumanSpec");
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			L4DTakeoverSHS = EndPrepSDKCall();
			
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(L4DDMConf, SDKConf_Signature, "TakeOverBot");
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			L4DTakeoverTOB = EndPrepSDKCall();
		}
	}
	else
	{
		SetFailState("Survivor Bot Takeover is disabled because could not load gamedata/l4d_takeover.txt");
		return;
	}	
	
	PrecacheWeaponModels();
	CreateTimer(1.0, InitHiddenWeaponsDelayed);
	CreateTimer(3.0,Inform_GnomeLocation, _, TIMER_REPEAT);
	CreateTimer(0.5,kill_infected, _, TIMER_REPEAT);//stops the director and any infected from spawning
	CreateTimer(40.0, DisPlayPanel, _, TIMER_REPEAT)
	HookEvent("pills_used", pills_used);
	HookEvent("item_pickup", EventItemPickup)
	HookEvent("adrenaline_used", UsedAdrenaline);
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookEvent("player_shoved", Event_Player_Shoved)
	HookEvent("player_spawn", Event_Player_Spawn); //Player spawned
	HookEvent("player_death", Event_Player_Death); //Player died	
	HookEvent("player_hurt", Event_Player_Hurt); //Player took damage
	HookEvent("player_hurt", Event_player_hurt_before, EventHookMode_Pre)
	HookEvent("bullet_impact", Event_BulletImpact);
	HookEvent("player_falldamage", Event_Falling_damage, EventHookMode_Pre);
	HookEvent("player_now_it", Boomer_vomit);
	HookEvent("player_no_longer_it", Boomer_vomit_No_longer);
	
	RegConsoleCmd("dm", team_menu);//for testing purposes
	RegConsoleCmd("bile", TestBile);//for testing purposes
	RegConsoleCmd("molo", TestMolo);//for testing purposes
	RegAdminCmd("bot", spawn_test_human,ADMFLAG_GENERIC);//for testing purposes
	RegAdminCmd("tank", spawn_test_Tank,ADMFLAG_GENERIC);//for testing purposes
	RegAdminCmd("boots", TurnBootsOn,ADMFLAG_GENERIC);//for testing purposes
	RegConsoleCmd("pipe", TestPipe);//for testing purposes
	Round_two = true;
	Stop_guns = true;
	Team_chosen = true;
	Round_started=true;
	First_blood = true;
	g_t_PipeTicks = CreateTrie()
	g_t_GrenadeOwner = CreateTrie()
	g_FadeUserMsgId = GetUserMessageId("Fade");
}

public OnConfigsExecuted()
{
	InitPrecache();
}

InitPrecache()
{	
	PrecacheSound(BOOM_ONE_NICK, true);
	PrecacheSound(BOOM_TWO_NICK , true);
	PrecacheSound(BOOM_THREE_NICK , true);
	PrecacheSound(BOOM_ONE_COACH , true);
	PrecacheSound(BOOM_TWO_COACH , true);
	PrecacheSound(BOOM_THREE_COACH , true);
	PrecacheSound(BOOM_ONE_ELLIS , true);
	PrecacheSound(BOOM_TWO_ELLIS , true);
	PrecacheSound(BOOM_THREE_ELLIS , true);
	PrecacheSound(BOOM_ONE_ROCHELLE  , true);
	PrecacheSound(BOOM_TWO_ROCHELLE  , true);
	PrecacheSound(BOOM_THREE_ROCHELLE  , true);		
	PrecacheSound(FIRSTBLOODCOACH, true);
	PrecacheSound(FIRSTBLOODROCHELLE, true);
	PrecacheSound(FIRSTBLOODELLIS, true);
	PrecacheSound(FIRSTBLOODNICK, true);
	PrecacheSound(SMOKE_DAMAGE, true);
	PrecacheSound(MULTIONE, true);
	PrecacheSound(MULTITWO, true);
	PrecacheSound(MULTITHREE, true);
	PrecacheSound(MULTIFOUR, true);
	PrecacheSound(MULTIFIVE, true);
	PrecacheSound(WINSOUND, true);
	PrecacheSound(g_sSound, true);
}

static PrecacheWeaponModels()
{
	//Precache weapon models if they're not loaded.
	CheckModelPreCache("models/w_models/weapons/w_rifle_sg552.mdl");
	CheckModelPreCache("models/w_models/weapons/w_smg_mp5.mdl");
	CheckModelPreCache("models/w_models/weapons/w_sniper_awp.mdl");
	CheckModelPreCache("models/w_models/weapons/w_sniper_scout.mdl");
	CheckModelPreCache("models/w_models/weapons/w_eq_bile_flask.mdl");
	CheckModelPreCache("models/v_models/v_rif_sg552.mdl");
	CheckModelPreCache("models/v_models/v_smg_mp5.mdl");
	CheckModelPreCache("models/v_models/v_snip_awp.mdl");
	CheckModelPreCache("models/v_models/v_snip_scout.mdl");
	CheckModelPreCache("models/v_models/v_bile_flask.mdl");
	CheckModelPreCache("models/w_models/weapons/w_m60.mdl");
	CheckModelPreCache("models/v_models/v_m60.mdl");
}

stock CheckModelPreCache(const String:Modelfile[])
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile);
	}
}

public Action:InitHiddenWeaponsDelayed(Handle:timer, any:client)
{
	//Spawn and delete the hidden weapons,
	PreCacheGun("weapon_rifle_sg552");
	PreCacheGun("weapon_smg_mp5");
	PreCacheGun("weapon_sniper_awp");
	PreCacheGun("weapon_sniper_scout");
	PreCacheGun("weapon_rifle_m60");
	
	decl String:Map[56];
	GetCurrentMap(Map, sizeof(Map));
	ForceChangeLevel(Map, "Hidden weapon initialization.");//taken from atomic strykers gun control
}

public Action:MapRotation(Handle:timer)
{
	//PrintToChatAll("MAP ROTATION NAWWWW");
	new String:mapName[40];
	GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
	new String:charArr[5][5];
	ExplodeString(mapName, "_", charArr, 5, 5);
	new String:mapAbbriv[5];
	strcopy(mapAbbriv, 5, charArr[0]);
	
	if(strcmp(mapAbbriv, "c1m4") == 0)
	{
		ServerCommand("changelevel c2m1_highway")
	}
	else if(strcmp(mapAbbriv, "c2m5") == 0)
	{
		ServerCommand("changelevel c5m1_waterfront")
	}
	else if(strcmp(mapAbbriv, "c5m5") == 0)
	{
		ServerCommand("changelevel c3m1_plankcountry")
	}
	else if(strcmp(mapAbbriv, "c3m4") == 0)
	{
		ServerCommand("changelevel c4m1_milltown_a")
	}
	else if(strcmp(mapAbbriv, "c4m5") == 0)
	{
		ServerCommand("changelevel c1m1_hotel")
	}
}

/*
public OnClientPostAdminCheck(client)
{
SDKHook(client,    SDKHook_OnTakeDamage,     TakeDamageHook);
}
*/
/*
public Action:TakeDamageHook(client, &attacker, &inflictor, &Float:damage, &damagetype)//maybe use when sdk hooks is good for l4d2 again
{    
//damagetype: 34603010 = headshot
//boom Headshot
PrintToChatAll("HEADSHOT DETECTED!");
if(damagetype == 34603010)
{
damage *= 999.0;
return Plugin_Changed;
}

return Plugin_Continue;
}  
*/

static PreCacheGun(const String:GunEntity[])
{
	new index = CreateEntityByName(GunEntity);
	DispatchSpawn(index);
	RemoveEdict(index);
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	Stop_guns = true;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) 
		{
			playerscore[i]=0;
			Deaths[i]=0;
			playerscoreTemp[i]=0;
			AllowHighJump[i]=0;
		}
	}
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Round_started=false;
	Team_chosen = true;
	CreateTimer(5.0, Setgamemode)
	CreateTimer(1.0, Give_weapons, _, TIMER_REPEAT)
	CreateTimer(1.0, Give_Custom_weapons, _, TIMER_REPEAT)
	CreateTimer(30.0, Sort_Decoy)
	CreateTimer(4.0, TestSprite, _,  TIMER_REPEAT);
	CreateTimer(5.0, FixSIXTYTHOUSANDbug, _, TIMER_REPEAT)
	Full_score_red=0;
	Full_score_blue=0;
	initial_stage = true;
	Force_spawns = true;
	First_fourMinutes = true;
	First_blood = true;
	Stop_spawning=false;
	scoreset=0;
	RandomBonusMode=0;
	humancounter=1;
	GnomeSpawned=false;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) 
		{	
			EmergencyGiven[i]=0;
			KillBonuses[i]=0;
			CustomMagic[i]=0;
			HaveISpawned[i]=0;
			playerscore[i]=0;
			Deaths[i]=0;
			playerscoreTemp[i]=0;
			CanISpawn[i]=ALLOWSPAWN;
			MAX_scores[i]=0;
			iHaveChompsky[i]=0;
			PrimaryGiven[i]=0;
			SecondaryGiven[i]=0;
			primaryChosen[i]=0;
			SecondaryChosen[i]=0;
			GrenadeChosen[i]=0;
			GrenadeGiven[i]=0;
			AllowHighJump[i]=0;
			JumpTimer[i]=0;
			IamNowFuelling[i]=0;
			AlphaBoomer[i]=0;
			KillFollowBeam(i);
			for (new klient = 1; klient <= 64; klient++)
			{
				for (new j = 1; j > 0 ; j--)
				{
					if (timer_handle[klient][j] != INVALID_HANDLE)
					{
						KillTimer(timer_handle[klient][j]);
						timer_handle[klient][j] = INVALID_HANDLE;
						CloseHandle(hurtdata[klient][j]);
					}
				}
			}
		}
	}
}

public OnClientPutInServer(client)
{	
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{
		if (IsFakeClient(client))
			return
		
		WelcomeTimers[client] = CreateTimer(20.0, Timer_Notify, client)
		TeamState[client]=NO_TEAM;
		WeaponsGiven[client]=0;
		CanISpawn[client]=ALLOWSPAWN;
		CreateTimer(10.0, allow_to_play)
		playerscore[client]=0;
		Deaths[client]=0;
		HaveISpawned[client]=0;
		playerscoreTemp[client]=0;
		PrimaryGiven[client]=0
		AlphaBoomer[client]=0; 
		g_PlayerIncapacitated[client] = NONE
		g_b_InAction[client] = false
		g_b_AllowThrow[client] = false
		AllowHighJump[client]=0;
		g_PlayerGameTime[client] = 0.0
		g_ThrewGrenade[client] = 0
		IamNowFuelling[client]=0;
		g_PipebombBounce[client] = 0
		JumpTimer[client] = 0;
		AlphaBoomer[client]=0;
	}
	
}

public OnClientDisconnect(client)
{
	if(AlphaBoomer[client]==1)
	{
		new counter = GetRandomPlayer();
		if (counter != -1)
		{
			ForcePlayerSuicide(counter);
			TeamState[counter]=INFECTED_TEAM
			TeleportEntity(counter, Blue_Teleport, NULL_VECTOR, NULL_VECTOR);
			AlphaBoomer[counter]=1;
			PrintToChatAll("\x03%N \x04has become the new \x03ALPHA \x04BOOMER", counter);
			
		}
		StopJetpack(client);
	}
	
}
public Action:Timer_Notify(Handle:Timer, any:client)
{
	if (RandomBonusMode == 1)
	{	
		PrintHintTextToAll("BONUS GAMEMODE INFECTION!!");
		PrintToChatAll("\x04BONUS GAMEMODE \x03INFECTION!!");
		PrintHintText(client, "AVOID BOOMERS AND THEIR VOMIT AT ALL COSTS");
	}
	else if(RandomBonusMode == 2)
	{
		PrintHintTextToAll("BONUS GAMEMODE ODDGNOME!!");
		PrintToChatAll("\x04BONUS GAMEMODE \x03ODDGNOME!!");
		PrintHintText(client, "HOLD GNOME CHOMPSKY FOR AS LONG AS POSSIBLE TO WIN");
	}
	else
	{	
		if (GetConVarInt(GameType)==1)
		{
			if(IsClientInGame(client))
			{
				PrintToChat(client, "\x01\x03-------------------------------------");
				PrintToChat(client, "\x01\x03L4D2,\x04 \x03TEAM \x04DEATHMATCH!");
				PrintToChat(client, "\x01\x04-------------------------------------");
				PrintHintText(client, "KILL enemy survivors in order to WIN");
			}
		}
		if (GetConVarInt(GameType)==2)
		{
			if(IsClientInGame(client))
			{
				PrintToChat(client, "\x01\x03-------------------------------------");
				PrintToChat(client, "\x01\x03L4D2,\x04 \x03FFA \x04DEATHMATCH!");
				PrintToChat(client, "\x01\x04------------------------------------");
				PrintHintText(client, "KILL other survivors in order to WIN");
				
			}
		}
	}
	return Plugin_Stop
}


public Action:Countdown(Handle:timer, any:attacker)
{
	SecondstoGo[attacker]--;
	//PrintHintTextToAll("Spree disabled in %i ", SecondstoGo[attacker]);
	
	if (IsClientInGame(attacker) && SecondstoGo[attacker] <1 )//had > 1
	{
		if(CountdownS[attacker] != INVALID_HANDLE)
		{
			KillTimer(CountdownS[attacker]);
			CountdownS[attacker] = INVALID_HANDLE;			
		}
		SecondstoGo[attacker]=0;
		MultipleKill[attacker] =0;
		
	}
	if (IsClientInGame(attacker) && SecondstoGo[attacker]==49)
	{
		MoreThanOneKills(attacker);
	}
}

MoreThanOneKills(attacker)
{
	MultipleKill[attacker] ++;
	if(MultipleKill[attacker]==1)
	{
		//PrintToChatAll("Single kill achieved");
	} 
	if(MultipleKill[attacker]==2)
	{
		PrintHintText(attacker, "DOUBLE KILL");
	}
	if(MultipleKill[attacker]==3)
	{
		Streak_sound[attacker] = CreateTimer(0.5, PlayMusic, attacker)
	}
	if(MultipleKill[attacker]==4)
	{
		Streak_sound[attacker] = CreateTimer(0.5, PlayMusic_two, attacker)
	}
	if(MultipleKill[attacker]==5)
	{
		Streak_sound[attacker] = CreateTimer(0.5, PlayMusic_three, attacker)
	}
	if(MultipleKill[attacker]==6)
	{
		Streak_sound[attacker] = CreateTimer(0.5, PlayMusic_four, attacker)
		
	}
	if(MultipleKill[attacker]>=7)
	{
		Streak_sound[attacker] = CreateTimer(0.5, PlayMusic_five, attacker)
	}
	
}
public Action:PlayMusic(Handle:timer, any:attacker)
{
	
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==2)
		{
			EmitSoundToAll(
			MULTIONE, i,
			SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
			90, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	PrintToChatAll("\x04| %N |  \x03TRIPLE KILL!", attacker);
	
}

public Action:PlayMusic_two(Handle:timer, any:attacker)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==2)
		{
			EmitSoundToAll(
			MULTITWO, i,
			SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
			90, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	PrintToChatAll("\x04| %N |  \x03MULTIKILL!", attacker);
}

public Action:PlayMusic_three(Handle:timer, any:attacker)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==2)
		{
			EmitSoundToAll(
			MULTITHREE, i,
			SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
			90, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	PrintToChatAll("\x04| %N |  \x03MEGAKILL!", attacker);
}

public Action:PlayMusic_four(Handle:timer, any:attacker)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==2)
		{
			EmitSoundToAll(
			MULTIFOUR, i,
			SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
			90, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	PrintToChatAll("\x04| %N |  \x03MONSTERKILL!", attacker);
}

public Action:PlayMusic_five(Handle:timer, any:attacker)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==2)
		{
			EmitSoundToAll(
			MULTIFIVE, i,
			SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
			90, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	PrintToChatAll("\x04| %N |  \x03RAMPAGE!", attacker);
}

public Action:TestBile(client, args)
{
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	FakeClientCommand(client, "give vomitjar");   
	SetCommandFlags("give", flags|FCVAR_CHEAT);  
}

public Action:TestMolo(client, args)
{
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	FakeClientCommand(client, "give molotov");   
	SetCommandFlags("give", flags|FCVAR_CHEAT);  
}

public Action:TestPipe(client, args)
{
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	FakeClientCommand(client, "give pipe_bomb");   
	SetCommandFlags("give", flags|FCVAR_CHEAT);   
}



public Action:team_menu(client, args)
{
	//if(IsPlayerAlive) return;//uncomment after testing
	if(TeamState[client]==NO_TEAM)
	
	{
		ChooseTeamMenu(client);
	}
	else
	{
		ChooseClassMenu(client);
	}
}




public Action:ChooseTeamMenuAlive(clientId) 
{
	if(Team_chosen==true)
	{
		new Handle:menu = CreateMenu(ChooseTeamMenuHandlerAlive);
		SetMenuTitle(menu, "Choose your TEAM")
		AddMenuItem(menu, "option1", "RED TEAM")
		AddMenuItem(menu, "option2", "BLUE TEAM")
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, clientId, 10);
		
		//	return Plugin_Handled;
	}
}

public Action:ChooseTeamMenu(clientId) 
{
	if(Team_chosen==true)
	{
		new Handle:menu = CreateMenu(ChooseTeamMenuHandler);
		SetMenuTitle(menu, "Choose your TEAM")
		AddMenuItem(menu, "option1", "RED TEAM")
		AddMenuItem(menu, "option2", "BLUE TEAM")
		
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, clientId, 10);
		
		//	return Plugin_Handled;
	}
}
public ChooseTeamMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if(Team_chosen==true)
	{
		new Handle:gamemodevar = FindConVar("mp_gamemode");
		new String:gamemode[25];
		GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
		if ( action == MenuAction_Select ) 
		{
			switch (itemNum)
			{
				case 0: //normal
				{
					PrintToChat( client, "\x04Red \x03Team");	
					TeamState[client]=RED_TEAM;
					ChooseClassMenu(client);
					
				}
				case 1: //special
				{
					PrintToChat(client, "\x04Blue \x03Team");	
					TeamState[client]=BLUE_TEAM;
					ChooseClassMenu(client);
				}
				
			}
		}
	}
}

public ChooseTeamMenuHandlerAlive(Handle:menu, MenuAction:action, client, itemNum)
{
	if(Team_chosen==true)
	{
		new Handle:gamemodevar = FindConVar("mp_gamemode");
		new String:gamemode[25];
		GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
		if ( action == MenuAction_Select ) 
		{
			switch (itemNum)
			{
				case 0: //normal
				{
					PrintToChat( client, "\x04Red \x03Team");	
					TeamState[client]=RED_TEAM;
					ChooseClassMenuAlive(client);
					
				}
				case 1: //special
				{
					PrintToChat(client, "\x04Blue \x03Team");	
					TeamState[client]=BLUE_TEAM;
					ChooseClassMenuAlive(client);
				}
				
			}
		}
	}
}

stock Paint_red(client)
{
	if(IsClientInGame(client))
	{
		SetEntityRenderMode(client, RenderMode:0);
		DispatchKeyValue(client, "rendercolor", Red);
	}
}

stock Paint_blue(client)
{
	if(IsClientInGame(client))
	{
		SetEntityRenderMode(client, RenderMode:0);
		DispatchKeyValue(client, "rendercolor", Blue);
	}
}
public Action:TierOneOrTwo(client) 
{
	if(First_fourMinutes==true)
	{
		TierOneSetOfWeaponsPrimary(client);
	}
	else
	{
		TierTwoSetOfWeaponsPrimary(client);
	}
	
}

public Action:TierOneSetOfWeaponsPrimary(clientId) 
{
	
	new Handle:menu = CreateMenu(PrimaryTierOneMenuHandler);
	SetMenuTitle(menu, "Choose your main Tier 1 weapon")
	AddMenuItem(menu, "option1", "PumpShotgun")
	AddMenuItem(menu, "option2", "Chrome Shotgun")
	AddMenuItem(menu, "option3", "Submachine Gun")
	AddMenuItem(menu, "option4", "Silenced Submachine Gun")
	AddMenuItem(menu, "option5", "Mp5n")
	AddMenuItem(menu, "option6", "Hunting rifle")
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 30);
	
	return Plugin_Handled;
}

public Action:TierTwoSetOfWeaponsPrimary(clientId) 
{
	
	new Handle:menu = CreateMenu(PrimaryTierTwoMenuHandler);
	SetMenuTitle(menu, "Choose your main Tier 2 weapon")
	AddMenuItem(menu, "option1", "XM1014 auto shotgun")
	AddMenuItem(menu, "option2", "SPAS-12")
	AddMenuItem(menu, "option3", "M-16")
	AddMenuItem(menu, "option4", "AK-47")
	AddMenuItem(menu, "option5", "SCAR-H")
	AddMenuItem(menu, "option6", "Sg-552 Assault Rifle")
	AddMenuItem(menu, "option7", "HK41 sniper")
	AddMenuItem(menu, "option8", "SCOUT sniper")
	AddMenuItem(menu, "option9", "AWP sniper")
	AddMenuItem(menu, "option10", "M60 Machine Gun")
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 30);
	
	return Plugin_Handled;
}

public Action:TierOneSetOfWeaponsSecondary(clientId) 
{
	
	new Handle:menu = CreateMenu(SecondaryTierOneMenuHandler);
	SetMenuTitle(menu, "Choose your secondary weapon")
	AddMenuItem(menu, "option1", "Pistols")
	AddMenuItem(menu, "option2", "Melee weapon")
	//AddMenuItem(menu, "option2", "Magnum pistol")// tier 2
	//AddMenuItem(menu, "option4", "Chainsaw")//tier 2
	
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 30);
	
	return Plugin_Handled;
}

public Action:TierTwoSetOfWeaponsSecondary(clientId) 
{
	
	new Handle:menu = CreateMenu(SecondaryTierTWOMenuHandler);
	SetMenuTitle(menu, "Choose your secondary weapon")
	AddMenuItem(menu, "option1", "Pistols")
	AddMenuItem(menu, "option3", "Melee weapon")
	AddMenuItem(menu, "option2", "Magnum pistol")// tier 2
	AddMenuItem(menu, "option4", "Chainsaw")//tier 2
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 30);
	
	return Plugin_Handled;
}

public Action:EmergencyEquipment(clientId) 
{
	
	new Handle:menu = CreateMenu(EmergencyEquipmentMenuHandler);
	SetMenuTitle(menu, "Choose your Healing equipment")
	AddMenuItem(menu, "option1", "Pills")
	AddMenuItem(menu, "option2", "Adrenaline")
	
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 30);
	
	return Plugin_Handled;
}

public Action:ChooseNade(clientId) 
{
	
	new Handle:menu = CreateMenu(GrenadeEquipmentHandler);
	SetMenuTitle(menu, "Choose your Grenade")
	AddMenuItem(menu, "option1", "VomitJar")
	AddMenuItem(menu, "option2", "Pipe Bomb")
	AddMenuItem(menu, "option3", "Molotov")
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 30);
	
	return Plugin_Handled;
}

public Action:ChooseClassMenuAlive(clientId)
{
	new Handle:menu = CreateMenu(ClassChooseMenuHandlerAlive);
	SetMenuTitle(menu, "Choose your Weapon class")
	AddMenuItem(menu, "option1", "Custom Class")
	AddMenuItem(menu, "option2", "Sniper")
	AddMenuItem(menu, "option3", "Assault")
	AddMenuItem(menu, "option4", "Medic")
	AddMenuItem(menu, "option5", "Shotgun")
	AddMenuItem(menu, "option6", "HeavyGun")
	
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 10);
	
	return Plugin_Handled;
}


public Action:ChooseClassMenu(clientId) {
	
	new Handle:menu = CreateMenu(ClassChooseMenuHandler);
	SetMenuTitle(menu, "Choose your Weapon class")
	AddMenuItem(menu, "option1", "Custom Class")
	AddMenuItem(menu, "option2", "Sniper")
	AddMenuItem(menu, "option3", "Assault")
	AddMenuItem(menu, "option4", "Medic")
	AddMenuItem(menu, "option5", "Shotgun")
	AddMenuItem(menu, "option6", "HeavyGun")
	
	
	//AddMenuItem(menu, "option6", "Jockey Dual")	think of new class
	
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 10);
	
	return Plugin_Handled;
}


public SecondaryTierOneMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	
	new Handle:gamemodevar = FindConVar("mp_gamemode");
	new String:gamemode[25];
	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
	if ( action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0: //normal
			{
				//FakeClientCommand(i, "give pumpshotgun");//or spaz
				SecondaryChosen[client]=1;
				EmergencyEquipment(client);
			}
			case 1: //special
			{
				//chrome
				SecondaryChosen[client]=2;
				EmergencyEquipment(client);
			}
			
			
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	
}

public SecondaryTierTWOMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	
	new Handle:gamemodevar = FindConVar("mp_gamemode");
	new String:gamemode[25];
	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
	if ( action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0: //normal
			{
				//Pistols
				SecondaryChosen[client]=1;
				EmergencyEquipment(client);
			}
			case 1: //Magnum
			{
				//chrome
				SecondaryChosen[client]=2;
				EmergencyEquipment(client);
			}
			case 2: //normal
			{
				//Melee
				SecondaryChosen[client]=3;
				EmergencyEquipment(client);
			}
			
			case 3: //special// theres currently a sound bug, im not sure how to fix it but untill then chainsaw is unavailable
			{
				//Chainsaw
				SecondaryChosen[client]=4;
				EmergencyEquipment(client);
			}
			
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	
}


public EmergencyEquipmentMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	
	new Handle:gamemodevar = FindConVar("mp_gamemode");
	new String:gamemode[25];
	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
	if ( action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0: //normal
			{
				//Pills
				EmergencyChosen[client]=1;
				ChooseNade(client);
			}
			case 1: //Magnum
			{
				//adren
				EmergencyChosen[client]=2;
				ChooseNade(client);
			}
			
			
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	
}


public GrenadeEquipmentHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	
	new Handle:gamemodevar = FindConVar("mp_gamemode");
	new String:gamemode[25];
	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
	if ( action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0: //vomit
			{
				
				GrenadeChosen[client]=1;
			}
			case 1: //pipe
			{
				GrenadeChosen[client]=2;
			}
			case 2: //pipe
			{
				GrenadeChosen[client]=3;
			}
			
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	
}


public PrimaryTierOneMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	
	new Handle:gamemodevar = FindConVar("mp_gamemode");
	new String:gamemode[25];
	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
	if ( action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0: //normal
			{
				//FakeClientCommand(i, "give pumpshotgun");//or spaz
				primaryChosen[client]=1;
				TierOneSetOfWeaponsSecondary(client);
			}
			case 1: //special
			{
				//chrome
				primaryChosen[client]=2;
				TierOneSetOfWeaponsSecondary(client);
			}
			
			case 2: //normal
			{
				
				//AddMenuItem(menu, "option3", "Submachine Gun")
				primaryChosen[client]=3;
				TierOneSetOfWeaponsSecondary(client);
			}
			case 3: //special
			{
				primaryChosen[client]=4;
				TierOneSetOfWeaponsSecondary(client);
				//AddMenuItem(menu, "option4", "Silenced Submachine Gun")
			}
			case 4: //special
			{
				primaryChosen[client]=5;
				TierOneSetOfWeaponsSecondary(client);
			}
			case 5: //special
			{
				//AddMen  hunting rifle
				primaryChosen[client]=6;
				TierOneSetOfWeaponsSecondary(client);
			}
			
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	
}


public PrimaryTierTwoMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	
	new Handle:gamemodevar = FindConVar("mp_gamemode");
	new String:gamemode[25];
	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
	if ( action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0: //normal
			{
				//XM1014
				primaryChosen[client]=7;
				TierTwoSetOfWeaponsSecondary(client);
			}
			case 1: //special
			{
				//SPAS-
				primaryChosen[client]=8;
				TierTwoSetOfWeaponsSecondary(client);
			}
			
			case 2: //normal
			{
				
				//AddMenuItem(menu, "option3", "M-16 Gun")
				primaryChosen[client]=9;
				TierTwoSetOfWeaponsSecondary(client);
			}
			case 3: //special
			{
				primaryChosen[client]=10;
				TierTwoSetOfWeaponsSecondary(client);
				//AddMenuItem(menu, "option4", "AK ")
			}
			case 4: //special
			{
				//AddMenuItem(menu, "option5", "SCAR")
				primaryChosen[client]=11;
				TierTwoSetOfWeaponsSecondary(client);
			}
			case 5: //special
			{
				//AddMenuItem(menu, "option5", "sg-552")
				primaryChosen[client]=12;
				TierTwoSetOfWeaponsSecondary(client);
			}
			case 6: //special
			{
				///AddMenuItem(menu, "option5", "HK41")
				primaryChosen[client]=13;
				TierTwoSetOfWeaponsSecondary(client);
			}
			case 7: //special
			{
				//AddMenuItem(menu, "option5", "SCOUT")
				primaryChosen[client]=14;
				TierTwoSetOfWeaponsSecondary(client);
			}
			case 8: //special
			{
				//AddMenuItem(menu, "option5", "AWP")
				primaryChosen[client]=15;
				TierTwoSetOfWeaponsSecondary(client);
			}
			case 9: //special
			{
				//AddMenuItem(menu, "option5", "m60")
				primaryChosen[client]=16;
				TierTwoSetOfWeaponsSecondary(client);
			}
			case 10: //special
			{
				//AddMenuItem(menu, "option5", "m60")
				primaryChosen[client]=17;
				TierTwoSetOfWeaponsSecondary(client);
			}
			
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	
}



public ClassChooseMenuHandlerAlive(Handle:menu, MenuAction:action, client, itemNum)
{
	
	new Handle:gamemodevar = FindConVar("mp_gamemode");
	new String:gamemode[25];
	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
	if ( action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			
			case 0: //special
			{
				
				SurvivorClass[client]=CUSTOM
				TierOneOrTwo(client);
				
			}
			case 1: //normal
			{
				PrintHintText(client, "Class will be changed on respawn");
				//PrintToChat(client, "You have chosen Sniper class");	
				SurvivorClass[client]=SNIPER
			}
			case 2: //special
			{
				PrintHintText(client, "Class will be changed on respawn");
				//PrintToChat(client, "You have chosen Assault Rifle class");	
				SurvivorClass[client]=ASSAULT
				
			}
			
			case 3: //normal
			{
				PrintHintText(client, "Class will be changed on respawn");
				//PrintToChat(client, "You have chosen Medic class");	
				SurvivorClass[client]=MEDIC
			}
			case 4: //special
			{
				PrintHintText(client, "Class will be changed on respawn");
				//PrintToChat(client, "You have chosen Shotgun class");
				SurvivorClass[client]=SHOTGUN
			}
			case 5: //special
			{
				PrintHintText(client, "Class will be changed on respawn");
				//PrintToChat(client, "You have chosen Shotgun class");
				SurvivorClass[client]=HEAVYGUN
			}
			
			
			
			
			
		}
	}
	
}

public ClassChooseMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	new Handle:gamemodevar = FindConVar("mp_gamemode");
	new String:gamemode[25];
	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
	if ( action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			
			case 0: 
			{
				SurvivorClass[client]=CUSTOM
				TierOneOrTwo(client);
			}
			case 1:
			{
				SurvivorClass[client]=SNIPER
			}
			case 2: 
			{
				SurvivorClass[client]=ASSAULT
			}
			
			case 3: 
			{
				SurvivorClass[client]=MEDIC
			}
			case 4: 
			{
				SurvivorClass[client]=SHOTGUN
			}
			
			case 5: 
			{
				SurvivorClass[client]=HEAVYGUN
			}
			
			
			
			
		}
	}
	
}


public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	WeaponsGiven[client]=0;
	CanISpawn[client]=DISALLOWSPAWN;
	CustomMagic[client]=1;	
	PrimaryGiven[client]=0;
	SecondaryGiven[client]=0;
	EmergencyGiven[client]=0;
	Remove_dropped[client]=0;
	g_b_AllowThrow[client]= false;
	g_PlayerIncapacitated[client] = NONE;
	GrenadeGiven[client]=0;
	MoloSecondsIn[client]=0;
	JetpackFuel[client]=GetConVarInt(JetPackFuel);
	Flying[client]=false;
	if (RandomBonusMode == 1)
	{	
		if(IsPlayerBoomer(client))
		{
			if(AlphaBoomer[client]==1)
			{
				SetEntityHealth(client, 450)
			}
			else
			{
				SetEntityHealth(client, 300)
			}
		}
	}
	else if (RandomBonusMode == 2)
	{
		PrintToChat(client, "\x04Carry \x03GNOME CHOMPSKY\x04 to \x03WIN");
	}
}

public Action:Event_player_hurt_before(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(GameType)==1)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (IsValidClient(attacker) && GetClientTeam(victim) == 2)
		{
			if (RandomBonusMode == 1 || RandomBonusMode ==2)
			{
				if(GetClientTeam(victim) == GetClientTeam(attacker))
				{
					SetEntityHealth(victim,(GetEventInt(event,"dmg_health")+ GetEventInt(event,"health")));
				}
				
				
			}
			else
			{
				if(TeamState[attacker]==TeamState[victim])
				{
					SetEntityHealth(victim,(GetEventInt(event,"dmg_health")+ GetEventInt(event,"health")));
				}
			}
		}
	}
}

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (RandomBonusMode == 1)
	{
		
	}
	else if (RandomBonusMode == 2)
	{
		
	}
	else
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		decl Float:ClientOrigin[3]
		ClientOrigin[2]-=2;
		decl String:weapon[64]
		if (IsValidClient(attacker) && GetClientTeam(client) == 2)
		{	
			if (GetConVarInt(GameType)==1)
			{
				if(TeamState[attacker]!=TeamState[client])
				{
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientOrigin)
					GetClientEyePosition(client, ClientOrigin);
					
					
					GetClientWeapon(attacker, weapon, sizeof(weapon));
					SetEntProp(client, Prop_Send, "m_iGlowType", 3)
					SetEntProp(client, Prop_Send, "m_glowColorOverride", 254);
					CreateTimer(0.3, HitmarkerGlow, client)	
				}
				
				
				if (StrEqual(weapon, "weapon_melee"))
				{
					if(TeamState[attacker]!=TeamState[client])
					{
						if (StrEqual(weapon, "weapon_melee"))
						{
							
							new health = GetClientHealth(client);
							new damage = 20;
							if (health-damage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-damage);
						}
					}
					//PrintToChatAll("%N was hit with a melee", client);
				}
				else
				{
					if(TeamState[attacker]!=TeamState[client])
					{	
						GetEventString(event, "weapon", weapon, sizeof(weapon))
						if (StrEqual(weapon, "sniper_awp"))
						{
							
							//PrintToChatAll("\x03 %N \x04 was sniped by \x03%N", client, attacker);	
							new health = GetClientHealth(client);
							new Float:damage = 43.0;
							new ActualDamage;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							damage *= (GetConVarInt(damage_multiplier));
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								damage *= 1.5;
							}
							if (health-ActualDamage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-ActualDamage);
						}
						if (StrEqual(weapon, "sniper_scout"))
						{
							
							//PrintToChatAll("\x03 %N \x04 was sniped by \x03%N", client, attacker);	
							new health = GetClientHealth(client);
							new Float:damage = 34.0;
							new ActualDamage;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							damage *= (GetConVarInt(damage_multiplier));
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								damage *= 1.5;
							}
							if (health-ActualDamage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-ActualDamage);
						}
						
						if (StrEqual(weapon, "sniper_military"))
						{
							new health = GetClientHealth(client);
							new Float:damage = 15.0;
							new ActualDamage;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							damage *= (GetConVarInt(damage_multiplier));
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								damage *= 1.5;
								ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							}
							if (health-ActualDamage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-ActualDamage);
							
						}
						
						if (StrEqual(weapon, "hunting_rifle"))
						{
							new health = GetClientHealth(client);
							new Float:damage = 14.0;
							new ActualDamage;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								damage *= 1.5;
								ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							}
							//PrintToChatAll("damage caused = %i", ActualDamage);
							if (health-ActualDamage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-ActualDamage);
						}
						
						if (StrEqual(weapon, "rifle") || StrEqual(weapon, "rifle_ak47") || StrEqual(weapon, "rifle_sg552"))
						{
							new health = GetClientHealth(client);
							new Float:damage = 10.0;
							new ActualDamage;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							damage *= (GetConVarInt(damage_multiplier));
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								damage *= 1.5;
								ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							}
							//PrintToChatAll("damage caused by AR = %i", ActualDamage);
							if (health-ActualDamage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-ActualDamage);
							
						}	
						
						if (StrEqual(weapon, "rifle_desert"))
						{
							new health = GetClientHealth(client);
							new Float:damage = 7.0;//test
							new ActualDamage;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							damage *= (GetConVarInt(damage_multiplier));
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								damage *= 1.5;
								ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							}
							//new Float:damage = 7.0;
							if (health-ActualDamage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-ActualDamage);
						}	
						
						if (StrEqual(weapon, "smg")|| StrEqual(weapon, "smg_mp5")|| StrEqual(weapon, "smg_silenced"))
						{
							new health = GetClientHealth(client);
							new Float:damage = 7.0;//test
							new ActualDamage;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							damage *= (GetConVarInt(damage_multiplier));
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								damage *= 1.5;
								ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							}
							if (health-ActualDamage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-ActualDamage);			
						}
						
						if (StrEqual(weapon, "rifle_m60"))
						{
							new health = GetClientHealth(client);
							new Float:damage = 10.0;//test
							new ActualDamage;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							damage *= (GetConVarInt(damage_multiplier));
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								damage *= 1.5;
								ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							}
							if (health-ActualDamage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-ActualDamage);
						}	
						if (StrEqual(weapon, "pistol"))
						{
							new health = GetClientHealth(client);
							new Float:damage = 7.0;//test
							new ActualDamage;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							damage *= (GetConVarInt(damage_multiplier));
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								damage *= 1.5;
								ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							}
							if (health-ActualDamage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-ActualDamage);
							
						}
						if (StrEqual(weapon, "pistol_magnum"))
						{
							new health = GetClientHealth(client);
							new Float:damage = 16.0;//test
							new ActualDamage;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							damage *= (GetConVarInt(damage_multiplier));
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								damage *= 1.5;
								ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							}
							if (health-ActualDamage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-ActualDamage);
						}
						if (StrEqual(weapon, "chainsaw"))
						{
							if(TeamState[attacker]!=TeamState[client])
							{
								new health = GetClientHealth(client);
								new Float:damage = 25.0;
								new ActualDamage;
								ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
								damage *= (GetConVarInt(damage_multiplier));
								if (health-ActualDamage < 0)
								{
									SetEntityHealth(client, 0)
									
									// first remove any the player has..
									new entity;
									for (new i=0; i<4; i++) 
									{
										entity = GetPlayerWeaponSlot(client, i);
										if (IsValidEdict(entity)) 
										{
											RemovePlayerItem(client, entity);
											RemoveEdict(entity);
										}
									} 
								}
								else SetEntityHealth(client, health-ActualDamage);	
							}	
						}
						
						
						
						if (StrEqual(weapon, "autoshotgun")|| StrEqual(weapon, "shotgun_spas"))
						{			
							new health = GetClientHealth(client);
							new Float:damage = 4.0;//test
							new ActualDamage;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							damage *= (GetConVarInt(damage_multiplier));
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								damage *= 1.5;
								ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							}
							if (health-ActualDamage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-ActualDamage);			
							
						}
						if (StrEqual(weapon, "shotgun_chrome")|| StrEqual(weapon, "pumpshotgun"))
						{			
							new health = GetClientHealth(client);
							new Float:damage = 4.0;//test
							new ActualDamage;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							damage *= (GetConVarInt(damage_multiplier));
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								damage *= 1.5;
								ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
							}
							if (health-ActualDamage < 0)
							{
								SetEntityHealth(client, 0)
								
								// first remove any the player has..
								new entity;
								for (new i=0; i<4; i++) 
								{
									entity = GetPlayerWeaponSlot(client, i);
									if (IsValidEdict(entity)) 
									{
										RemovePlayerItem(client, entity);
										RemoveEdict(entity);
									}
								} 
							}
							else SetEntityHealth(client, health-ActualDamage);
							
						}	
					}
					
				}	
				//PrintToChatAll("\x03 %N \x04 was shot with %N  by\x03 %N ", client, weapon, attacker);
				
				
			}
			if (GetConVarInt(GameType)==2)
			{
				
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientOrigin)
				GetClientEyePosition(client, ClientOrigin);
				
				GetClientWeapon(attacker, weapon, sizeof(weapon));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3)
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 254);
				CreateTimer(0.3, HitmarkerGlow, client)	
				
				
				if (StrEqual(weapon, "weapon_melee"))
				{
					
					new health = GetClientHealth(client);
					new damage = 20;
					if (health-damage < 0)
					{
						SetEntityHealth(client, 0)
						
						// first remove any the player has..
						new entity;
						for (new i=0; i<4; i++) 
						{
							entity = GetPlayerWeaponSlot(client, i);
							if (IsValidEdict(entity)) 
							{
								RemovePlayerItem(client, entity);
								RemoveEdict(entity);
							}
						} 
					}
					else SetEntityHealth(client, health-damage);
					
					//PrintToChatAll("%N was hit with a melee", client);
				}
				else
				{
					
					GetEventString(event, "weapon", weapon, sizeof(weapon))
					if (StrEqual(weapon, "sniper_awp"))
					{
						
						//PrintToChatAll("\x03 %N \x04 was sniped by \x03%N", client, attacker);	
						new health = GetClientHealth(client);
						new Float:damage = 43.0;
						new ActualDamage;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						damage *= (GetConVarInt(damage_multiplier));
						if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
						{
							damage *= 1.5;
						}
						if (health-ActualDamage < 0)
						{
							SetEntityHealth(client, 0)
							
							// first remove any the player has..
							new entity;
							for (new i=0; i<4; i++) 
							{
								entity = GetPlayerWeaponSlot(client, i);
								if (IsValidEdict(entity)) 
								{
									RemovePlayerItem(client, entity);
									RemoveEdict(entity);
								}
							} 
						}
						else SetEntityHealth(client, health-ActualDamage);
					}
					if (StrEqual(weapon, "sniper_scout"))
					{
						
						//PrintToChatAll("\x03 %N \x04 was sniped by \x03%N", client, attacker);	
						new health = GetClientHealth(client);
						new Float:damage = 34.0;
						new ActualDamage;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						damage *= (GetConVarInt(damage_multiplier));
						if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
						{
							damage *= 1.5;
						}
						if (health-ActualDamage < 0)
						{
							SetEntityHealth(client, 0)
							
							// first remove any the player has..
							new entity;
							for (new i=0; i<4; i++) 
							{
								entity = GetPlayerWeaponSlot(client, i);
								if (IsValidEdict(entity)) 
								{
									RemovePlayerItem(client, entity);
									RemoveEdict(entity);
								}
							} 
						}
						else SetEntityHealth(client, health-ActualDamage);
					}
					
					if (StrEqual(weapon, "sniper_military"))
					{
						new health = GetClientHealth(client);
						new Float:damage = 15.0;
						new ActualDamage;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						damage *= (GetConVarInt(damage_multiplier));
						if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
						{
							damage *= 1.5;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						}
						if (health-ActualDamage < 0)
						{
							SetEntityHealth(client, 0)
							
							// first remove any the player has..
							new entity;
							for (new i=0; i<4; i++) 
							{
								entity = GetPlayerWeaponSlot(client, i);
								if (IsValidEdict(entity)) 
								{
									RemovePlayerItem(client, entity);
									RemoveEdict(entity);
								}
							} 
						}
						else SetEntityHealth(client, health-ActualDamage);
						
					}
					
					if (StrEqual(weapon, "hunting_rifle"))
					{
						new health = GetClientHealth(client);
						new Float:damage = 14.0;
						new ActualDamage;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
						{
							damage *= 1.5;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						}
						//PrintToChatAll("damage caused = %i", ActualDamage);
						if (health-ActualDamage < 0)
						{
							SetEntityHealth(client, 0)
							
							// first remove any the player has..
							new entity;
							for (new i=0; i<4; i++) 
							{
								entity = GetPlayerWeaponSlot(client, i);
								if (IsValidEdict(entity)) 
								{
									RemovePlayerItem(client, entity);
									RemoveEdict(entity);
								}
							} 
						}
						else SetEntityHealth(client, health-ActualDamage);
					}
					
					if (StrEqual(weapon, "rifle") || StrEqual(weapon, "rifle_ak47") || StrEqual(weapon, "rifle_sg552"))
					{
						new health = GetClientHealth(client);
						new Float:damage = 10.0;
						new ActualDamage;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						damage *= (GetConVarInt(damage_multiplier));
						if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
						{
							damage *= 1.5;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						}
						//PrintToChatAll("damage caused by AR = %i", ActualDamage);
						if (health-ActualDamage < 0)
						{
							SetEntityHealth(client, 0)
							
							// first remove any the player has..
							new entity;
							for (new i=0; i<4; i++) 
							{
								entity = GetPlayerWeaponSlot(client, i);
								if (IsValidEdict(entity)) 
								{
									RemovePlayerItem(client, entity);
									RemoveEdict(entity);
								}
							} 
						}
						else SetEntityHealth(client, health-ActualDamage);
						
					}	
					
					if (StrEqual(weapon, "rifle_desert"))
					{
						new health = GetClientHealth(client);
						new Float:damage = 7.0;//test
						new ActualDamage;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						damage *= (GetConVarInt(damage_multiplier));
						if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
						{
							damage *= 1.5;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						}
						//new Float:damage = 7.0;
						if (health-ActualDamage < 0)
						{
							SetEntityHealth(client, 0)
							
							// first remove any the player has..
							new entity;
							for (new i=0; i<4; i++) 
							{
								entity = GetPlayerWeaponSlot(client, i);
								if (IsValidEdict(entity)) 
								{
									RemovePlayerItem(client, entity);
									RemoveEdict(entity);
								}
							} 
						}
						else SetEntityHealth(client, health-ActualDamage);
					}	
					
					if (StrEqual(weapon, "smg")|| StrEqual(weapon, "smg_mp5")|| StrEqual(weapon, "smg_silenced"))
					{
						new health = GetClientHealth(client);
						new Float:damage = 7.0;//test
						new ActualDamage;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						damage *= (GetConVarInt(damage_multiplier));
						if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
						{
							damage *= 1.5;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						}
						if (health-ActualDamage < 0)
						{
							SetEntityHealth(client, 0)
							
							// first remove any the player has..
							new entity;
							for (new i=0; i<4; i++) 
							{
								entity = GetPlayerWeaponSlot(client, i);
								if (IsValidEdict(entity)) 
								{
									RemovePlayerItem(client, entity);
									RemoveEdict(entity);
								}
							} 
						}
						else SetEntityHealth(client, health-ActualDamage);			
					}
					
					if (StrEqual(weapon, "rifle_m60"))
					{
						new health = GetClientHealth(client);
						new Float:damage = 11.0;//test
						new ActualDamage;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						damage *= (GetConVarInt(damage_multiplier));
						if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
						{
							damage *= 1.5;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						}
						if (health-ActualDamage < 0)
						{
							SetEntityHealth(client, 0)
							
							// first remove any the player has..
							new entity;
							for (new i=0; i<4; i++) 
							{
								entity = GetPlayerWeaponSlot(client, i);
								if (IsValidEdict(entity)) 
								{
									RemovePlayerItem(client, entity);
									RemoveEdict(entity);
								}
							} 
						}
						else SetEntityHealth(client, health-ActualDamage);
					}	
					if (StrEqual(weapon, "pistol"))
					{
						new health = GetClientHealth(client);
						new Float:damage = 7.0;//test
						new ActualDamage;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						damage *= (GetConVarInt(damage_multiplier));
						if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
						{
							damage *= 1.5;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						}
						if (health-ActualDamage < 0)
						{
							SetEntityHealth(client, 0)
							
							// first remove any the player has..
							new entity;
							for (new i=0; i<4; i++) 
							{
								entity = GetPlayerWeaponSlot(client, i);
								if (IsValidEdict(entity)) 
								{
									RemovePlayerItem(client, entity);
									RemoveEdict(entity);
								}
							} 
						}
						else SetEntityHealth(client, health-ActualDamage);
						
					}
					if (StrEqual(weapon, "pistol_magnum"))
					{
						new health = GetClientHealth(client);
						new Float:damage = 16.0;//test
						new ActualDamage;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						damage *= (GetConVarInt(damage_multiplier));
						if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
						{
							damage *= 1.5;
							ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						}
						if (health-ActualDamage < 0)
						{
							SetEntityHealth(client, 0)
							
							// first remove any the player has..
							new entity;
							for (new i=0; i<4; i++) 
							{
								entity = GetPlayerWeaponSlot(client, i);
								if (IsValidEdict(entity)) 
								{
									RemovePlayerItem(client, entity);
									RemoveEdict(entity);
								}
							} 
						}
						else SetEntityHealth(client, health-ActualDamage);
					}
					if (StrEqual(weapon, "chainsaw"))
					{
						new health = GetClientHealth(client);
						new Float:damage = 35.0;
						new ActualDamage;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
						damage *= (GetConVarInt(damage_multiplier));
						if (health-ActualDamage < 0)
						{
							SetEntityHealth(client, 0)
							
							// first remove any the player has..
							new entity;
							for (new i=0; i<4; i++) 
							{
								entity = GetPlayerWeaponSlot(client, i);
								if (IsValidEdict(entity)) 
								{
									RemovePlayerItem(client, entity);
									RemoveEdict(entity);
								}
							} 
						}
						else SetEntityHealth(client, health-ActualDamage);	
					}	
				}
				
				
				
				if (StrEqual(weapon, "autoshotgun")|| StrEqual(weapon, "shotgun_spas"))
				{			
					new health = GetClientHealth(client);
					new Float:damage = 4.0;//test
					new ActualDamage;
					ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
					damage *= (GetConVarInt(damage_multiplier));
					if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
					{
						damage *= 1.5;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
					}
					if (health-ActualDamage < 0)
					{
						SetEntityHealth(client, 0)
						
						// first remove any the player has..
						new entity;
						for (new i=0; i<4; i++) 
						{
							entity = GetPlayerWeaponSlot(client, i);
							if (IsValidEdict(entity)) 
							{
								RemovePlayerItem(client, entity);
								RemoveEdict(entity);
							}
						} 
					}
					else SetEntityHealth(client, health-ActualDamage);			
					
				}
				if (StrEqual(weapon, "shotgun_chrome")|| StrEqual(weapon, "pumpshotgun"))
				{			
					new health = GetClientHealth(client);
					new Float:damage = 4.0;//test
					new ActualDamage;
					ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
					damage *= (GetConVarInt(damage_multiplier));
					if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
					{
						damage *= 1.5;
						ActualDamage= RoundToNearest(damage *= (GetConVarFloat(damage_multiplier)));
					}
					if (health-ActualDamage < 0)
					{
						SetEntityHealth(client, 0)
						
						// first remove any the player has..
						new entity;
						for (new i=0; i<4; i++) 
						{
							entity = GetPlayerWeaponSlot(client, i);
							if (IsValidEdict(entity)) 
							{
								RemovePlayerItem(client, entity);
								RemoveEdict(entity);
							}
						} 
					}
					else SetEntityHealth(client, health-ActualDamage);
				}	
				
			}
			
			
		}
	}
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (RandomBonusMode == 1)
	{
		
	}
	else if (RandomBonusMode == 2)
	{
		
	}
	else
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new time = GetConVarInt(RespawnTime);
		decl Float:ClientOrigin[3]
		ClientOrigin[2]-=2;
		
		if (GetConVarInt(GameType)==1)
		{	
			decl String:weapon[64]
			
			if (IsValidClient(attacker) && !IsFakeClient(client) && client != attacker)
			{	
				if(GetClientTeam(client) == 2)
				{
					if(CountdownS[attacker] != INVALID_HANDLE)
					{
						KillTimer(CountdownS[attacker]);
						CountdownS[attacker] = INVALID_HANDLE;
					}
					GetClientWeapon(attacker, weapon, sizeof(weapon));
					playerscore[attacker]++;
					CountdownS[attacker] = CreateTimer(0.1, Countdown, attacker, TIMER_REPEAT)
					SecondstoGo[attacker]=50;	
					Remove_dropped[client]=1;
					iHaveChompsky[client]=0;
				}
				if(GetClientTeam(client) == 3)
				{
					if (RandomBonusMode == 1)
					{
						if(IsPlayerBoomer(client))
						{
							playerscore[attacker]++;
							playerscoreTemp[attacker]++;
						}
					}
				}
			}
			
			if (IsValidClient(attacker) && GetClientTeam(client) == 2 && !IsFakeClient(client) && client != attacker)
			{	
				if(TeamState[attacker]!=TeamState[client])
				{
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientOrigin)
					GetClientEyePosition(client, ClientOrigin);
					HaveISpawned[client]=1;
					RespawnTimer[client] = CreateTimer(GetConVarFloat(RespawnTime), Respawn, client); 
					PrintHintText(client, "You will respawn in %i seconds.", time);
					//PrintToChat(client, "\x04Press\x03 SHIFT(WALK)\x04 to change \x03WEAPON\x04 class");
					CanISpawn[client]=DISALLOWSPAWN;
					Deaths[client]++;
					DoIHaveMyBonus[attacker]=1;
					KillBonuses[attacker]++;
					KillBonuses[client]=0;
				}
				
				if (StrEqual(weapon, "weapon_melee"))
				{
					if(!IsFakeClient(client))
					{
						PrintToChatAll("\x03%N\x04 Meleed \x03%N", attacker, client);
						if(First_blood==true)
						{
							First_blood=false;
							CreateTimer(1.0, Declare_first_blood, attacker)	
						}
					}
				}
				else
				{
					
					if(!IsFakeClient(client))
					{
						GetEventString(event, "weapon", weapon, sizeof(weapon))
						if (StrEqual(weapon, "sniper_awp"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								PrintToChatAll("\x03 %N \x04 Arctic Warfare Magnum sniper HEADSHOT \x03%N", attacker, client);	
								
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 Arctic Warfare Magnum sniper  \x03%N", attacker, client);	
							}
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}
						if (StrEqual(weapon, "sniper_military"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
							{
								PrintToChatAll("\x03 %N \x04 HK41 sniper HEADSHOT \x03%N", attacker, client);	
								
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 HK41 sniper \x03%N", attacker, client);	
							}
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}
						if (StrEqual(weapon, "sniper_scout"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 Scout sniper HEADSHOT \x03%N", attacker, client);	
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 Scout sniper \x03%N", attacker, client);	
							}
							
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}			
						if (StrEqual(weapon, "hunting_rifle"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 M21 sniper HEADSHOT \x03%N", attacker, client);	
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 M21 sniper \x03%N", attacker, client);	
							}
							
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}			
						
						if (StrEqual(weapon, "rifle"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 M-16 Assault Rifle HEADSHOT \x03%N", attacker, client);
								
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 M-16 Assault Rifle \x03%N", attacker, client);	
							}
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}
						if (StrEqual(weapon, "rifle_ak47"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 AK-47 Assault Rifle HEADSHOT\x03%N", attacker, client);		
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 AK-47 Assault Rifle \x03%N", attacker, client);	
							}			
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}
						if (StrEqual(weapon, "rifle_desert"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 SCAR-H Assault Rifle HEADSHOT\x03%N", attacker, client);					
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 SCAR-H Assault Rifle \x03%N", attacker, client);	
							}	
							
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}
						if (StrEqual(weapon, "rifle_m60"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 M60 Machine Gun HEADSHOT\x03%N", attacker, client);				
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 M60 Machine Gun \x03%N", attacker, client);
							}	
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}			
						if (StrEqual(weapon, "rifle_sg552"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 Krieg 552 Assault Rifle HEADSHOT\x03%N", attacker, client);							
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 Krieg 552 Assault Rifle \x03%N", attacker, client);	
							}	
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}	
						if (StrEqual(weapon, "smg"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 Uzi Submachine gun HEADSHOT\x03%N", attacker, client);			
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 Uzi Submachine gun \x03%N", attacker, client);	
							}	
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}	
						if (StrEqual(weapon, "smg_mp5"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 Mp5n Submachine gun HEADSHOT\x03%N", attacker, client);	
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 Mp5n Submachine gun \x03%N", attacker, client);	
							}	
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}	
						if (StrEqual(weapon, "smg_silenced"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 Silenced Uzi Submachine gun HEADSHOT\x03%N", attacker, client);		
							}
							else
							{
								PrintToChatAll("\x03 %N \x04Silenced Uzi Submachine gun \x03%N", attacker, client);	
							}	
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}	
						
						if (StrEqual(weapon, "autoshotgun"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 XM1014 shotgun \x03%N HEADSHOT", attacker, client);		
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 XM1014 shotgun \x03%N", attacker, client);	
							}	
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}
						if (StrEqual(weapon, "shotgun_chrome"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04  Remington 870 shotgun HEADSHOT\x03%N", attacker, client);	
							}
							else
							{
								PrintToChatAll("\x03 %N \x04  Remington 870 shotgun \x03%N", attacker, client);	
							}	
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}			
						if (StrEqual(weapon, "shotgun_spas"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 Franchi SPAS-12 shotgun HEADSHOT\x03%N", attacker, client);	
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 Franchi SPAS-12 shotgun \x03%N", attacker, client);
							}	
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}
						if (StrEqual(weapon, "pumpshotgun"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 M3 pump-action shotgun HEADSHOT\x03%N", attacker, client);	
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 M3 pump-action shotgun \x03%N", attacker, client);	
							}	
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}
						
						if (StrEqual(weapon, "pistol"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04  P220 Pistol HEADSHOT\x03%N", attacker, client);
							}
							else
							{
								PrintToChatAll("\x03 %N \x04  P220 Pistol \x03 %N", attacker, client);
							}	
							
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}
						if (StrEqual(weapon, "pistol_magnum"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 .50 Desert Cobra handgun HEADSHOT\x03%N", attacker, client);	
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 .50 Desert Cobra handgun \x03%N", attacker, client);	
							}	
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}
						
						
						if (StrEqual(weapon, "dual_pistols"))
						{
							if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
							{
								PrintToChatAll("\x03 %N \x04 P220 Pistol & Glock akimbo HEADSHOT\x03%N", attacker, client);		
							}
							else
							{
								PrintToChatAll("\x03 %N \x04 P220 Pistol & Glock akimbo \x03%N", attacker, client);	
							}	
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
							
						}
						if (StrEqual(weapon, "chainsaw"))
						{
							
							PrintToChatAll("\x03 %N \x04 Chainsaw shredded \x03%N", attacker, client);	
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
							
						}
						
					}
				}
			}
			WeaponsGiven[client]=0;
		}
		
		
		if (GetConVarInt(GameType)==2)//ffa
		{
			{	
				decl String:weapon[64]
				if (IsValidClient(attacker) && !IsFakeClient(client) && client != attacker)
				{	
					if(GetClientTeam(client) == 2)
					{
						if(CountdownS[attacker] != INVALID_HANDLE)
						{
							KillTimer(CountdownS[attacker]);
							CountdownS[attacker] = INVALID_HANDLE;
						}
						GetClientWeapon(attacker, weapon, sizeof(weapon));
						playerscore[attacker]++;
						CountdownS[attacker] = CreateTimer(0.1, Countdown, attacker, TIMER_REPEAT)
						SecondstoGo[attacker]=50;	
						Remove_dropped[client]=1;
						iHaveChompsky[client]=0;
					}
					if(GetClientTeam(client) == 3)
					{
						if (RandomBonusMode == 1)
						{
							if(IsPlayerBoomer(client))
							{
								playerscore[attacker]++;
							}
						}
						if (RandomBonusMode == 2)
						{
							if(IsPlayerBoomer(client))
							{
								
							}
						}
					}
				}
				
				if (IsValidClient(client) && !IsFakeClient(client) && GetClientTeam(client) == 2) //comment here for streak testing 
				{	
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientOrigin)
					GetClientEyePosition(client, ClientOrigin);
					HaveISpawned[client]=1;
					RespawnTimer[client] = CreateTimer(GetConVarFloat(RespawnTime), Respawn, client); 
					PrintHintText(client, "You will respawn in %i seconds.", time);
					//PrintToChat(client, "\x04Press\x03 SHIFT(WALK)\x04 to change \x03WEAPON\x04 class");
					CanISpawn[client]=DISALLOWSPAWN;
					Deaths[client]++;
					DoIHaveMyBonus[attacker]=1;
					KillBonuses[attacker]++;
					KillBonuses[client]=0;
					
					if (StrEqual(weapon, "weapon_melee"))
					{
						if(!IsFakeClient(client))//comment here for streak testing
						{
							PrintToChatAll("\x03%N\x04 Meleed \x03%N", attacker, client);
							if(First_blood==true)
							{
								First_blood=false;
								CreateTimer(1.0, Declare_first_blood, attacker)	
							}
						}
					}
					else
					{
						
						if(!IsFakeClient(client))
						{
							GetEventString(event, "weapon", weapon, sizeof(weapon))
							if (StrEqual(weapon, "sniper_awp"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
								{
									PrintToChatAll("\x03 %N \x04 Arctic Warfare Magnum sniper HEADSHOT \x03%N", attacker, client);	
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 Arctic Warfare Magnum sniper  \x03%N", attacker, client);	
								}
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}
							if (StrEqual(weapon, "sniper_military"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
								{
									PrintToChatAll("\x03 %N \x04 HK41 sniper HEADSHOT \x03%N", attacker, client);	
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 HK41 sniper \x03%N", attacker, client);	
								}
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}
							if (StrEqual(weapon, "sniper_scout"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 Scout sniper HEADSHOT \x03%N", attacker, client);	
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 Scout sniper \x03%N", attacker, client);	
								}
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}			
							if (StrEqual(weapon, "hunting_rifle"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 M21 sniper HEADSHOT \x03%N", attacker, client);	
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 M21 sniper \x03%N", attacker, client);	
								}
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}			
							
							if (StrEqual(weapon, "rifle"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 M-16 Assault Rifle HEADSHOT \x03%N", attacker, client);	
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 M-16 Assault Rifle \x03%N", attacker, client);	
								}
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}
							if (StrEqual(weapon, "rifle_ak47"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 AK-47 Assault Rifle HEADSHOT\x03%N", attacker, client);		
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 AK-47 Assault Rifle \x03%N", attacker, client);	
								}			
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}
							if (StrEqual(weapon, "rifle_desert"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 SCAR-H Assault Rifle HEADSHOT\x03%N", attacker, client);			
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 SCAR-H Assault Rifle \x03%N", attacker, client);	
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}
							if (StrEqual(weapon, "rifle_m60"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 M60 Machine Gun HEADSHOT\x03%N", attacker, client);		
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 M60 Machine Gun \x03%N", attacker, client);
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}			
							if (StrEqual(weapon, "rifle_sg552"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 Krieg 552 Assault Rifle HEADSHOT\x03%N", attacker, client);		
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 Krieg 552 Assault Rifle \x03%N", attacker, client);	
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}	
							if (StrEqual(weapon, "smg"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 Uzi Submachine gun HEADSHOT\x03%N", attacker, client);		
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 Uzi Submachine gun \x03%N", attacker, client);	
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}	
							if (StrEqual(weapon, "smg_mp5"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 Mp5n Submachine gun HEADSHOT\x03%N", attacker, client);	
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 Mp5n Submachine gun \x03%N", attacker, client);	
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}	
							if (StrEqual(weapon, "smg_silenced"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 Silenced Uzi Submachine gun HEADSHOT\x03%N", attacker, client);		
								}
								else
								{
									PrintToChatAll("\x03 %N \x04Silenced Uzi Submachine gun \x03%N", attacker, client);	
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}	
							
							if (StrEqual(weapon, "autoshotgun"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 XM1014 shotgun \x03%N HEADSHOT", attacker, client);		
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 XM1014 shotgun \x03%N", attacker, client);	
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}
							if (StrEqual(weapon, "shotgun_chrome"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04  Remington 870 shotgun HEADSHOT\x03%N", attacker, client);	
								}
								else
								{
									PrintToChatAll("\x03 %N \x04  Remington 870 shotgun \x03%N", attacker, client);	
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}			
							if (StrEqual(weapon, "shotgun_spas"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 Franchi SPAS-12 shotgun HEADSHOT\x03%N", attacker, client);	
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 Franchi SPAS-12 shotgun \x03%N", attacker, client);
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}
							if (StrEqual(weapon, "pumpshotgun"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 M3 pump-action shotgun HEADSHOT\x03%N", attacker, client);	
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 M3 pump-action shotgun \x03%N", attacker, client);	
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}
							
							if (StrEqual(weapon, "pistol"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04  P220 Pistol HEADSHOT\x03%N", attacker, client);
								}
								else
								{
									PrintToChatAll("\x03 %N \x04  P220 Pistol \x03 %N", attacker, client);
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}
							if (StrEqual(weapon, "pistol_magnum"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 .50 Desert Cobra handgun HEADSHOT\x03%N", attacker, client);	
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 .50 Desert Cobra handgun \x03%N", attacker, client);	
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}
							
							
							if (StrEqual(weapon, "dual_pistols"))
							{
								if (GetVectorDistance(ClientOrigin, Bullet_impact[attacker]) <= 11.0)
								{
									PrintToChatAll("\x03 %N \x04 P220 Pistol & Glock akimbo HEADSHOT\x03%N", attacker, client);		
								}
								else
								{
									PrintToChatAll("\x03 %N \x04 P220 Pistol & Glock akimbo \x03%N", attacker, client);	
								}	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
								
							}
							if (StrEqual(weapon, "chainsaw"))
							{
								
								PrintToChatAll("\x03 %N \x04 Chainsaw shredded \x03%N", attacker, client);	
								if(First_blood==true)
								{
									First_blood=false;
									CreateTimer(1.0, Declare_first_blood, attacker)	
								}
							}
						}
					}
					WeaponsGiven[client]=0;
				}
			}
			
		}
	}
}


public ThrowVomitjar(i_Client)
{
	decl i_Ent, Float:f_Position[3], Float:f_Speed[3], Float:f_Angles[3], String:s_TargetName[32], Float:f_CvarSpeed, String:s_Ent[4]
	
	i_Ent = CreateEntityByName("vomitjar_projectile")
	
	if (IsValidEntity(i_Ent))
	{
		SetEntPropEnt(i_Ent, Prop_Data, "m_hOwnerEntity", i_Client)
		SetEntityModel(i_Ent, MODEL_W_VOMITJAR)
		FormatEx(s_TargetName, sizeof(s_TargetName), "vomitjar%d", i_Ent)
		DispatchKeyValue(i_Ent, "targetname", s_TargetName)
		DispatchSpawn(i_Ent)
	}
	
	g_ThrewGrenade[i_Client] = i_Ent
	
	GetClientEyePosition(i_Client, f_Position)
	GetClientEyeAngles(i_Client, f_Angles)
	GetAngleVectors(f_Angles, f_Speed, NULL_VECTOR, NULL_VECTOR)
	f_CvarSpeed = 1000.0
	
	f_Speed[0] *= f_CvarSpeed
	f_Speed[1] *= f_CvarSpeed
	f_Speed[2] *= f_CvarSpeed
	
	GetRandomAngles(f_Angles)
	TeleportEntity(i_Ent, f_Position, f_Angles, f_Speed)
	
	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	SetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	
	g_h_GrenadeTimer[i_Client] = CreateTimer(0.1, VomitjarThink, i_Ent, TIMER_REPEAT)
}

public Action:VomitjarThink(Handle:h_Timer, any:i_Ent)
{
	decl i_Client, String:s_Ent[4], String:s_ClassName[32]
	
	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	GetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	GetEdictClassname(i_Ent, s_ClassName, sizeof(s_ClassName))
	
	if (!IsValidEdict(i_Ent) || StrContains(s_ClassName, "projectile") == -1)
	{
		if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i_Client])
			g_h_GrenadeTimer[i_Client] = INVALID_HANDLE
			g_ThrewGrenade[i_Client] = 0
			RemoveFromTrie(g_t_GrenadeOwner, s_Ent)
		}	
		
		return Plugin_Handled
	}
	
	decl Float:f_Origin[3]
	
	GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin)
	
	if (0.0 < OnGroundUnits(i_Ent) <= 15.0)
	{
		decl Float:f_EntOrigin[3], i_MaxEntities, String:s_ModelName[64], i_InfoEnt, Float:f_CvarDuration
		
		if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i_Client])
			g_h_GrenadeTimer[i_Client] = INVALID_HANDLE
		}	
		
		g_ThrewGrenade[i_Client] = 0
		EmitSoundToAll(SOUND_VOMITJAR, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, f_Origin, NULL_VECTOR, false, 0.0)
		f_CvarDuration = 10.0
		RemoveEdict(i_Ent)
		DisplayParticle(f_Origin, "vomit_jar", f_CvarDuration);
		
		i_InfoEnt = CreateEntityByName("info_goal_infected_chase")
		DispatchKeyValueVector(i_InfoEnt, "origin", f_Origin)
		DispatchSpawn(i_InfoEnt)
		AcceptEntityInput(i_InfoEnt, "Enable")
		CreateTimer(f_CvarDuration, DeleteEntity, i_InfoEnt)
		CreateLaserEffectVomitjar(f_Origin, 100, 230, 80, 230, 6.0, 4.0, VERTICAL);
		i_MaxEntities = GetMaxEntities()
		for (new i = 1; i <= i_MaxEntities; i++)
		{
			if (IsValidEdict(i) && IsValidEntity(i))
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName))
				
				if (StrContains(s_ModelName, "survivors") != -1)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", f_EntOrigin)
					
					if (GetVectorDistance(f_Origin, f_EntOrigin) <= GetConVarFloat(h_CvarVomitjarRadius))
					{
						
						if (IsClientInGame(i) && GetClientTeam(i)==2 && IsPlayerAlive(i) &&  !IsFakeClient(i))
						{
							SetEntDataFloat(i, LagMovement, 0.3, true);
							SetEntProp(i, Prop_Send, "m_iGlowType", 3)
							SetEntProp(i, Prop_Send, "m_glowColorOverride", -4713783)
							CreateTimer(0.1, Bile_effect, i)//Inflict players with bile consequences
						}
					}
				}
			}
		}
		
		return Plugin_Continue
	}
	else
	{
		decl Float:f_Angles[3]
		
		GetRandomAngles(f_Angles)
		TeleportEntity(i_Ent, NULL_VECTOR, f_Angles, NULL_VECTOR)
	}
	
	return Plugin_Continue
}

public ThrowMolotov(i_Client)
{
	decl i_Ent, Float:f_Origin[3], Float:f_Speed[3], Float:f_Angles[3], String:s_TargetName[32], Float:f_CvarSpeed, String:s_Ent[4]
	
	i_Ent = CreateEntityByName("molotov_projectile")
	
	if (IsValidEntity(i_Ent))
	{
		SetEntPropEnt(i_Ent, Prop_Data, "m_hOwnerEntity", i_Client)
		SetEntityModel(i_Ent, MODEL_W_MOLOTOV)
		FormatEx(s_TargetName, sizeof(s_TargetName), "molotov%d", i_Ent)
		DispatchKeyValue(i_Ent, "targetname", s_TargetName)
		DispatchSpawn(i_Ent)
	}
	
	g_ThrewGrenade[i_Client] = i_Ent
	
	GetClientEyePosition(i_Client, f_Origin)
	GetClientEyeAngles(i_Client, f_Angles)
	GetAngleVectors(f_Angles, f_Speed, NULL_VECTOR, NULL_VECTOR)
	f_CvarSpeed = 1000.0 
	
	f_Speed[0] *= f_CvarSpeed
	f_Speed[1] *= f_CvarSpeed
	f_Speed[2] *= f_CvarSpeed
	
	GetRandomAngles(f_Angles)
	TeleportEntity(i_Ent, f_Origin, f_Angles, f_Speed)
	EmitSoundToAll(SOUND_MOLOTOV, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, f_Origin, NULL_VECTOR, false, 0.0)
	
	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	SetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	
	g_h_GrenadeTimer[i_Client] = CreateTimer(0.1, MolotovThink, i_Ent, TIMER_REPEAT)
}

public Action:MolotovThink(Handle:h_Timer, any:i_Ent)
{
	decl i_Client, String:s_Ent[4], String:s_ClassName[32]
	
	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	GetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	GetEdictClassname(i_Ent, s_ClassName, sizeof(s_ClassName))
	
	if (!IsValidEdict(i_Ent) || StrContains(s_ClassName, "projectile") == -1)
	{
		if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i_Client])
			g_h_GrenadeTimer[i_Client] = INVALID_HANDLE
			g_ThrewGrenade[i_Client] = 0
			RemoveFromTrie(g_t_GrenadeOwner, s_Ent)
		}
		
		return Plugin_Handled
	}
	
	decl Float:f_Origin[3]
	GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin)
	
	if (0.0 < OnGroundUnits(i_Ent) <= 10.0)
	{	
		if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i_Client])
			g_h_GrenadeTimer[i_Client] = INVALID_HANDLE
			
		}	
		
		g_ThrewGrenade[i_Client] = 0
		RemoveEdict(i_Ent)
		
		i_Ent = CreateEntityByName("prop_physics")
		DispatchKeyValue(i_Ent, "physdamagescale", "0.0")
		DispatchKeyValue(i_Ent, "model", MODEL_BARREL)
		DispatchSpawn(i_Ent)
		TeleportEntity(i_Ent, f_Origin, NULL_VECTOR, NULL_VECTOR)
		CreateGasCloud(i_Ent, f_Origin);//creaTE THE sMoKe
		SetEntityMoveType(i_Ent, MOVETYPE_VPHYSICS) 
		AcceptEntityInput(i_Ent, "Break")
		
		CloudPositioning(i_Client, f_Origin);
		//CreateTimer(1.0, CloudDamage,f_Origin, TIMER_REPEAT);//add handle
		
		
	}
	return Plugin_Continue
}


static CloudPositioning(client, Float:f_Origin[3])
{
	MoloSecondsIn[client]=0;
	if(SmokerPositioning[client] != INVALID_HANDLE)
	{
		KillTimer(SmokerPositioning[client])
		SmokerPositioning[client] = INVALID_HANDLE
	}
	
	new Float:targettime = GetEngineTime() + GetConVarFloat(h_CvarSmokeRadius);
	
	new Handle:data = CreateDataPack();
	WritePackCell(data, client);
	WritePackFloat(data, f_Origin[0]);
	WritePackFloat(data, f_Origin[1]);
	WritePackFloat(data, f_Origin[2]);
	WritePackFloat(data, targettime);
	
	SmokerPositioning[client]=CreateTimer(1.0, CloudDamage, data, TIMER_REPEAT);
}

public Action:CloudDamage(Handle:timer, Handle:hurt)
{
	
	ResetPack(hurt);
	new client = ReadPackCell(hurt);
	decl Float:f_Origin[3];
	f_Origin[0] = ReadPackFloat(hurt);
	f_Origin[1] = ReadPackFloat(hurt);
	f_Origin[2] = ReadPackFloat(hurt);
	new Float:targettime = ReadPackFloat(hurt);
	
	if(MoloSecondsIn[client]>=GetConVarInt(h_CvarMolotovCLOUDDuration))
	{
		if(SmokerPositioning[client] != INVALID_HANDLE)
		{
			KillTimer(SmokerPositioning[client])
			SmokerPositioning[client] = INVALID_HANDLE
			MoloSecondsIn[client]=0;
		}
	}
	else
	{
		MoloSecondsIn[client]++;
		if (targettime - GetEngineTime() < 0)
		{
			CloseHandle(hurt);
			return Plugin_Stop;
		}
		
		decl Float:f_EntOrigin[3]
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i)!=1 && IsPlayerAlive(i) && !IsFakeClient(i) && i != client)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", f_EntOrigin)
				GetClientAbsOrigin(i, f_EntOrigin);
				
				new health = GetClientHealth(i);
				new Float:damage;
				new ActualDamage;
				if (GetVectorDistance(f_Origin, f_EntOrigin) <=GetConVarFloat(h_CvarSmokeRadius))
				{
					SetEntProp(i, Prop_Send, "m_iGlowType", 3)
					SetEntProp(i, Prop_Send, "m_glowColorOverride", 61184);	
					CreateTimer(0.3, HitmarkerGlow, i)	
					
					damage = GetConVarFloat(h_CvarMoloDamage);
					ActualDamage = RoundToNearest(damage);
					
					if (health-ActualDamage < 0)
					{
						SetEntityHealth(i, 0)
						ForcePlayerSuicide(i)
						PrintToChatAll("\x03 %N\x04 Gas Molo \x03%N",client, i);	
						if (GetConVarInt(GameType)==1)//TD
						{
							if(TeamState[client]!=TeamState[i])
							{
								playerscore[client]++;
								playerscoreTemp[client]++;
							}
						}
						
						if (GetConVarInt(GameType)==2)//ffa
						{
							playerscore[client]++;
						}
						
						new entity;
						for (new j=0; j<4; j++) 
						{
							entity = GetPlayerWeaponSlot(i, j);
							if (IsValidEdict(entity)) 
							{
								RemovePlayerItem(i, entity);
								RemoveEdict(entity);
							}
						} 
					}
					
					else SetEntityHealth(i, health-ActualDamage);
				}
				
			}
			
			
			
		}
	}
	return Plugin_Continue
	
	
}


public Action:CreateGasCloud(Molotov, Float:f_Origin[3])
{
	new Float:pos[3];						
	pos=f_Origin;		
	pos[2] += 10.0;
	
	TE_SetupSparks(pos, NULL_VECTOR, 2, 1);
	TE_SendToAll(0.1);
	TE_SetupSparks(pos, NULL_VECTOR, 2, 2);
	TE_SendToAll(0.4);
	TE_SetupSparks(pos, NULL_VECTOR, 1, 1);
	TE_SendToAll(1.0);
	
	
	new Float:whooshtime;
	whooshtime = 0.1;
	new Handle:gasdata = CreateDataPack();
	CreateTimer(whooshtime, CreateGas, gasdata);
	
	WritePackCell(gasdata, Molotov);
	WritePackFloat(gasdata, pos[0]);
	WritePackFloat(gasdata, pos[1]);
	WritePackFloat(gasdata, pos[2]);
	WritePackCell(gasdata, 1);	
	return Plugin_Handled;
}



public Action:CreateGas(Handle:timer, Handle:gasdata)
{
	ResetPack(gasdata);
	new client = ReadPackCell(gasdata);
	new Float:location[3];
	location[0] = ReadPackFloat(gasdata);
	location[1] = ReadPackFloat(gasdata);
	location[2] = ReadPackFloat(gasdata);
	new gasNumber = ReadPackCell(gasdata);
	CloseHandle(gasdata);
	
	new pointHurt;
	new ff_on = GetConVarInt(FindConVar("mp_friendlyfire"));
	new String:originData[64];
	Format(originData, sizeof(originData), "%f %f %f", location[0], location[1], location[2]);
	new String:gasRadius[64];
	Format(gasRadius, sizeof(gasRadius), "%i", GetConVarInt(h_CvarSmokeRadius));
	
	new String:gasDamage[64];
	Format(gasDamage, sizeof(gasDamage), "%i", 0);// damage cause by gas
	
	if (ff_on)
	{
		// Create the PointHurt
		pointHurt = CreateEntityByName("point_hurt");
		DispatchKeyValue(pointHurt,"Origin", originData);
		DispatchKeyValue(pointHurt,"Damage", gasDamage);
		DispatchKeyValue(pointHurt,"DamageRadius", gasRadius);
		DispatchKeyValue(pointHurt,"DamageDelay", "1.0");
		DispatchKeyValue(pointHurt,"DamageType", "2097152");//was 65536
		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "TurnOn");
		
	}
	else
	{
		hurtdata[client][gasNumber] = CreateDataPack();
		WritePackCell(hurtdata[client][gasNumber], client);
		WritePackCell(hurtdata[client][gasNumber], gasNumber);
		WritePackFloat(hurtdata[client][gasNumber], location[0]);
		WritePackFloat(hurtdata[client][gasNumber], location[1]);
		WritePackFloat(hurtdata[client][gasNumber], location[2]);
		timer_handle[client][gasNumber] = CreateTimer(1.0, Point_Hurt, hurtdata[client][gasNumber], TIMER_REPEAT);
	}
	
	new String:colorData[64];
	Format(colorData, sizeof(colorData), "%i %i %i", 180, 210, 0);
	
	// Create the Gas Cloud
	new String:gas_name[128];
	Format(gas_name, sizeof(gas_name), "Gas%i", client);
	new gascloud = CreateEntityByName("env_smokestack");
	DispatchKeyValue(gascloud,"targetname", gas_name);
	DispatchKeyValue(gascloud,"Origin", originData);
	DispatchKeyValue(gascloud,"BaseSpread", "100");
	DispatchKeyValue(gascloud,"SpreadSpeed", "10");
	DispatchKeyValue(gascloud,"Speed", "80");
	DispatchKeyValue(gascloud,"StartSize", "160");
	DispatchKeyValue(gascloud,"EndSize", "2");
	DispatchKeyValue(gascloud,"Rate", "15");
	DispatchKeyValue(gascloud,"JetLength", "300");
	DispatchKeyValue(gascloud,"Twist", "4");
	DispatchKeyValue(gascloud,"RenderColor", colorData);
	DispatchKeyValue(gascloud,"RenderAmt", "100");
	DispatchKeyValue(gascloud,"SmokeMaterial", SMOKEGRENADE);
	
	DispatchSpawn(gascloud);
	AcceptEntityInput(gascloud, "TurnOn");
	
	new Float:length;
	length = GetConVarFloat(h_CvarMolotovCLOUDDuration);
	if (length <= 8.0)
	{
		length = 8.0;
	}
	
	new Handle:entitypack = CreateDataPack();
	CreateTimer(length, RemoveGas, entitypack);
	length = length + 5.0;
	CreateTimer(length, KillGas, entitypack);
	WritePackCell(entitypack, gascloud);
	WritePackCell(entitypack, pointHurt);
	WritePackCell(entitypack, ff_on);
	WritePackCell(entitypack, gasNumber);
	WritePackCell(entitypack, client);
}

public Action:RemoveGas(Handle:timer, Handle:entitypack)
{
	ResetPack(entitypack);
	new gascloud = ReadPackCell(entitypack);
	new pointHurt = ReadPackCell(entitypack);
	new ff_on = ReadPackCell(entitypack);
	new gasNumber = ReadPackCell(entitypack);
	new client = ReadPackCell(entitypack);
	
	if (IsValidEntity(gascloud))
		AcceptEntityInput(gascloud, "TurnOff");
	
	if (ff_on)
	{
		if (IsValidEntity(pointHurt))
			AcceptEntityInput(pointHurt, "TurnOff");
	}
	else
	{
		if (timer_handle[client][gasNumber] != INVALID_HANDLE)
		{
			KillTimer(timer_handle[client][gasNumber]);
			timer_handle[client][gasNumber] = INVALID_HANDLE;
			CloseHandle(hurtdata[client][gasNumber]);
		}
	}
}

public Action:KillGas(Handle:timer, Handle:entitypack)
{
	ResetPack(entitypack);
	new gascloud = ReadPackCell(entitypack);
	new pointHurt = ReadPackCell(entitypack);
	new ff_on = ReadPackCell(entitypack);
	
	if (IsValidEntity(gascloud))
		AcceptEntityInput(gascloud, "Kill");
	
	if (ff_on)
	{
		if (IsValidEntity(pointHurt))
			AcceptEntityInput(pointHurt, "Kill");
	}
	CloseHandle(entitypack);
}

public Action:Point_Hurt(Handle:timer, Handle:hurt)
{
	PrintToChatAll("Point_Hurt started");
	ResetPack(hurt);
	new client = ReadPackCell(hurt);
	new gasNumber = ReadPackCell(hurt);
	new Float:location[3];
	location[0] = ReadPackFloat(hurt);
	location[1] = ReadPackFloat(hurt);
	location[2] = ReadPackFloat(hurt);
	
	if (Round_started==true)
	{
		PrintToChatAll("Round_started = true");
		for (new target = 1; target <= GetMaxClients(); target++)
		{
			if (IsClientInGame(target))
			{
				if (IsPlayerAlive(target))
				{
					if (GetClientTeam(client) != GetClientTeam(target))
					{
						new Float:targetVector[3];
						GetClientAbsOrigin(target, targetVector);
						
						new Float:distance = GetVectorDistance(targetVector, location);
						
						if (distance < 300)
						{	
							if (GetConVarInt(GameType)==1)//Tdm
							{
								if(TeamState[target]!=TeamState[client])
								{
									new target_health;
									target_health = GetClientHealth(target);
									
									target_health -= 15;//was 20, damage cause by gas per second (add cvar if requested)
									
									if (target_health <= 15 + 1)
									{
										ForcePlayerSuicide(target);
										PrintToChatAll("\x03 %N \x04 Molotov gassed \x03%N", client, target);
										playerscore[client]++;
										playerscoreTemp[client]++;
									}
									else
									SetEntityHealth(target, target_health);	
								}	
								
							}
							
							
							if (GetConVarInt(GameType)==2)//ffa
							{
								new target_health;
								target_health = GetClientHealth(target);
								
								target_health -= 15;
								PrintToChatAll("eLSE HAPPEND");
								if (target_health <= 15 + 1)
								{
									ForcePlayerSuicide(target);
									LogAction(client, target, "\"%L\" gassed \"%L\"", client, target);
									PrintToChatAll("\x03 %L \x04 Molotov gassed \x03%L", client, target);
									playerscore[client]++;
								}
								else
								SetEntityHealth(target, target_health);
								PrintToChatAll("eLSE HAPPEND");
							}
						}
						//PrintToChatAll("%i - %f", target, distance)
					}
				}
			}
		}
	}
	else
	{
		KillTimer(timer);
		timer_handle[client][gasNumber] = INVALID_HANDLE;
		CloseHandle(hurt);
	}
}



/*
public Action:Molo_effect(Handle:timer, any:client)
{
if(GetClientTeam(client) == 2 && IsPlayerAlive(client ))  //is client on survivors team
{
//SetEntDataFloat(client, LagMovement, 1.0, true);
//PrintToChatAll("\x03%N \x4WAS \x03BILED",client);
if (g_got_burnt[client] == 1)
{
KillTimer(g_fire_timer[client])
KillTimer(g_flamed_countdown[client])
g_got_burnt[client] = 0;
SetEntDataFloat(client, LagMovement, 1.0, true);
}
g_boomed[client]=true
CreateTimer(0.1, Timer_got_burnt, client, TIMER_FLAG_NO_MAPCHANGE);
g_flamed_countdown[client] = CreateTimer(0.1, Timer_fire_Countdown, client, TIMER_REPEAT);
g_fire_timer[client] = CreateTimer(GetConVarFloat(h_CvarVomitjarGlowDuration), Timer_EndFire, client, TIMER_FLAG_NO_MAPCHANGE);
}
}	

public Action:Timer_EndFire(Handle:Timer, any:client)
{		
g_got_burnt[client] = 0
g_boomed[client]=false
}

public Action:Timer_got_burnt(Handle:Timer, any:client)
{
g_burnt_timeleft[client] = GetConVarInt(h_CvarVomitjarGlowDuration)*10;
g_burnt_timeleft[client] -= 1;
g_got_burnt[client] = 1
}

public Action:Timer_fire_Countdown(Handle:timer, any:client)
{
if(g_burnt_timeleft[client] == 0) //Powerups ran out
{
new clientsx[2];
clientsx[0] = client;
ExtinguishEntity(client)
PrintHintText(client,"Returning to normal...");
g_burnt_timeleft[client] = GetConVarInt(h_CvarVomitjarGlowDuration);//change 
g_boomed[client]=false
SetEntProp(client, Prop_Send, "m_iGlowType", 0)
SetEntProp(client, Prop_Send, "m_glowColorOverride", 0)
return Plugin_Stop;
}
else //Countdown progress
{		
new clients[2];
clients[0] = client;
IgniteEntity(client, 0.5)
g_burnt_timeleft[client] -= 1;
SetEntProp(client, Prop_Send, "m_iGlowType", 3)
SetEntProp(client, Prop_Send, "m_glowColorOverride", 61184);
return Plugin_Continue;
}
}
*/
public Action:Bile_effect(Handle:timer, any:client)
{
	if(GetClientTeam(client) == 2 && IsPlayerAlive(client))  //is client on survivors team
	{
		SetEntDataFloat(client, LagMovement, 1.0, true);
		//PrintToChatAll("\x03%N \x4WAS \x03BILED",client);
		if (g_got_biled[client] == 1)
		{
			KillTimer(g_bile_timer[client])
			KillTimer(g_biled_countdown[client])
			g_got_biled[client] = 0;
			SetEntDataFloat(client, LagMovement, 1.0, true);
		}
		g_boomed[client]=true
		CreateTimer(0.1, Timer_got_biled, client, TIMER_FLAG_NO_MAPCHANGE);
		g_biled_countdown[client] = CreateTimer(0.1, Timer_bile_Countdown, client, TIMER_REPEAT);
		g_bile_timer[client] = CreateTimer(GetConVarFloat(h_CvarVomitjarGlowDuration), Timer_EndBile, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}	


public Action:Disable_Jump_boots(Handle:Timer, any:client)
{		
	AllowHighJump[client]=0;
}

public Action:Timer_EndBile(Handle:Timer, any:client)
{		
	g_got_biled[client] = 0
	g_boomed[client]=false
}

public Action:Timer_got_biled(Handle:Timer, any:client)
{
	g_biled_timeleft[client] = GetConVarInt(h_CvarVomitjarGlowDuration)*10;
	g_biled_timeleft[client] -= 1;
	g_got_biled[client] = 1
}

public Action:Timer_bile_Countdown(Handle:timer, any:client)
{
	if(g_biled_timeleft[client] == 0) //Powerups ran out
	{
		new clientsx[2];
		clientsx[0] = client;
		new Handle:message = StartMessageEx(g_FadeUserMsgId, clientsx, 1);
		BfWriteShort(message, 255);
		BfWriteShort(message, 255);
		BfWriteShort(message, (0x0010));
		BfWriteByte(message, (0));
		BfWriteByte(message, (0));
		BfWriteByte(message, (0));
		BfWriteByte(message, (0));
		EndMessage();
		//PrintHintText(client,"Returning to normal...");
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		g_biled_timeleft[client] = GetConVarInt(h_CvarVomitjarGlowDuration);//change 
		g_boomed[client]=false
		SetEntProp(client, Prop_Send, "m_iGlowType", 0)
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 0)
		return Plugin_Stop;
	}
	else //Countdown progress
	{		
		new clients[2];
		clients[0] = client;
		new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
		BfWriteShort(message, 255);
		BfWriteShort(message, 255);
		BfWriteShort(message, (0x0008));
		BfWriteByte(message, GetRandomInt(253,255));
		BfWriteByte(message, GetRandomInt(253,255));
		BfWriteByte(message, GetRandomInt(253,255));
		BfWriteByte(message, GetRandomInt(253,255));
		EndMessage();
		
		SetEntProp(client, Prop_Send, "m_iHideHUD", 64);
		//PrintHintText(client,"Recovering from bile: %d", g_biled_timeleft[client]);
		g_biled_timeleft[client] -= 1;
		SetEntProp(client, Prop_Send, "m_iGlowType", 3)
		SetEntProp(client, Prop_Send, "m_glowColorOverride", -4713783)
		return Plugin_Continue;
	}
}


public DisplayParticle(Float:f_Position[3], String:s_Name[], Float:f_Time)
{
	decl i_Particle
	
	i_Particle = CreateEntityByName("info_particle_system")
	if (IsValidEdict(i_Particle))
	{
		TeleportEntity(i_Particle, f_Position, NULL_VECTOR, NULL_VECTOR)
		DispatchKeyValue(i_Particle, "effect_name", s_Name)
		DispatchSpawn(i_Particle)
		ActivateEntity(i_Particle)
		AcceptEntityInput(i_Particle, "Start")
		CreateTimer(f_Time, DeleteEntity, i_Particle)
	}
}

public Action:DeleteEntity(Handle:h_Timer, any:i_Ent)
{
	if (IsValidEntity(i_Ent))
		RemoveEdict(i_Ent)
}

stock GetRandomAngles(Float:f_Angles[3])
{
	f_Angles[0] = GetRandomFloat(-180.0, 180.0)
	f_Angles[1] = GetRandomFloat(-180.0, 180.0)
	f_Angles[2] = GetRandomFloat(-180.0, 180.0)
}

public Action:DisableGlow(Handle:h_Timer, any:i_Ent)
{
	decl String:s_ModelName[64]
	
	if (!IsValidEdict(i_Ent) || !IsValidEntity(i_Ent))
		return Plugin_Handled
	
	GetEntPropString(i_Ent, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName))
	
	if (StrContains(s_ModelName, "survivors") != -1)
	{
		SetEntProp(i_Ent, Prop_Send, "m_iGlowType", 0)
		SetEntProp(i_Ent, Prop_Send, "m_glowColorOverride", 0)
	}
	
	return Plugin_Continue
}


public ThrowPipebomb(i_Client)
{
	decl i_Ent, Float:f_Position[3], Float:f_Angles[3], Float:f_Speed[3], String:s_Ent[4], String:s_TargetName[32],
	Float:f_CvarSpeed
	//PrintToChatAll("ThrowPipebomb initiated");
	/*
	new entity;
	entity = GetPlayerWeaponSlot(i_Client, 2);
	if (IsValidEdict(entity)) 
	{
	RemovePlayerItem(i_Client, entity);
	RemoveEdict(entity);
	}
	*/
	
	i_Ent = CreateEntityByName("pipe_bomb_projectile")
	if (IsValidEntity(i_Ent))
	{
		SetEntPropEnt(i_Ent, Prop_Data, "m_hOwnerEntity", i_Client)
		SetEntityModel(i_Ent, MODEL_W_PIPEBOMB)
		FormatEx(s_TargetName, sizeof(s_TargetName), "pipebomb%d", i_Ent)
		DispatchKeyValue(i_Ent, "targetname", s_TargetName)
		DispatchSpawn(i_Ent)
	}
	
	g_ThrewGrenade[i_Client] = i_Ent
	
	GetClientEyePosition(i_Client, f_Position)
	GetClientEyeAngles(i_Client, f_Angles)
	GetAngleVectors(f_Angles, f_Speed, NULL_VECTOR, NULL_VECTOR)
	f_CvarSpeed = 1000.0//GetConVarFloat(h_CvarPipebombSpeed)maybe increase after testing
	
	f_Speed[0] *= f_CvarSpeed
	f_Speed[1] *= f_CvarSpeed
	f_Speed[2] *= f_CvarSpeed
	
	GetRandomAngles(f_Angles)
	TeleportEntity(i_Ent, f_Position, f_Angles, f_Speed)
	//AttachParticle(i_Ent, "weapon_pipebomb_blinking_light", f_Position)
	AttachParticle(i_Ent, "weapon_pipebomb_fuse", f_Position)
	AttachInfected(i_Ent, f_Position)
	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	SetTrieValue(g_t_PipeTicks, s_Ent, 0)
	SetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	
	g_h_GrenadeTimer[i_Client] = CreateTimer(0.1, PipebombThink, i_Ent, TIMER_REPEAT)
}




public AttachInfected(i_Ent, Float:f_Origin[3])
{
	decl i_InfoEnt, String:s_TargetName[32]
	
	i_InfoEnt = CreateEntityByName("info_goal_infected_chase")
	
	if (IsValidEdict(i_InfoEnt))
	{
		f_Origin[2] += 20.0
		DispatchKeyValueVector(i_InfoEnt, "origin", f_Origin)
		FormatEx(s_TargetName, sizeof(s_TargetName), "goal_infected%d", i_Ent)
		DispatchKeyValue(i_InfoEnt, "targetname", s_TargetName)
		GetEntPropString(i_Ent, Prop_Data, "m_iName", s_TargetName, sizeof(s_TargetName))
		DispatchKeyValue(i_InfoEnt, "parentname", s_TargetName)
		DispatchSpawn(i_InfoEnt)
		SetVariantString(s_TargetName)
		AcceptEntityInput(i_InfoEnt, "SetParent", i_InfoEnt, i_InfoEnt, 0)
		ActivateEntity(i_InfoEnt)
		AcceptEntityInput(i_InfoEnt, "Enable")
	}
	
	return i_InfoEnt
}

public Action:PipebombThink(Handle:h_Timer, any:i_Ent)
{
	decl i_Client, String:s_Ent[4], String:s_ClassName[32]
	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	GetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	GetEdictClassname(i_Ent, s_ClassName, sizeof(s_ClassName))
	//PrintToChatAll("%N threw the pipe?", i_Client);
	if (!IsValidEdict(i_Ent) || StrContains(s_ClassName, "projectile") == -1)
	{
		if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i_Client])
			g_h_GrenadeTimer[i_Client] = INVALID_HANDLE
			g_ThrewGrenade[i_Client] = 0
			g_PipebombBounce[i_Client] = 0
			RemoveFromTrie(g_t_PipeTicks, s_Ent)
			RemoveFromTrie(g_t_GrenadeOwner, s_Ent)
		}
		
		return Plugin_Handled
	}
	
	decl i_Count, Float:f_Angles[3], Float:f_Origin[3], Float:f_Units, Float:f_CvarDuration
	
	GetTrieValue(g_t_PipeTicks, s_Ent, i_Count)
	GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin)
	f_CvarDuration = GetConVarFloat(h_CvarPipebombDuration) * 10
	
	if (i_Count >= f_CvarDuration)
	{
		if (g_h_GrenadeTimer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_h_GrenadeTimer[i_Client])
			g_h_GrenadeTimer[i_Client] = INVALID_HANDLE
		}	
		
		g_ThrewGrenade[i_Client] = 0
		g_PipebombBounce[i_Client] = 0
		RemoveFromTrie(g_t_PipeTicks, s_Ent)
		RemoveFromTrie(g_t_GrenadeOwner, s_Ent)
		RemoveEdict(i_Ent)
		
		i_Ent = CreateEntityByName("prop_physics")
		DispatchKeyValue(i_Ent, "physdamagescale", "0.0")
		DispatchKeyValue(i_Ent, "model", MODEL_PROPANE)
		DispatchSpawn(i_Ent)
		TeleportEntity(i_Ent, f_Origin, NULL_VECTOR, NULL_VECTOR)
		SetEntityMoveType(i_Ent, MOVETYPE_VPHYSICS)
		AcceptEntityInput(i_Ent, "Break")
		
		decl Float:f_EntOrigin[3]
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i)!=1 && IsPlayerAlive(i) && !IsFakeClient(i) && i != i_Client)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", f_EntOrigin)
				GetClientAbsOrigin(i, f_EntOrigin);
				
				new health = GetClientHealth(i);
				new Float:damage;
				new ActualDamage;
				if (GetVectorDistance(f_Origin, f_EntOrigin) >1 && GetVectorDistance(f_Origin, f_EntOrigin) <70)
				{
					SetEntProp(i, Prop_Send, "m_iGlowType", 3)
					SetEntProp(i, Prop_Send, "m_glowColorOverride", 254);	
					CreateTimer(0.3, HitmarkerGlow, i)	
					damage = 80.0;//+propane damage
					ActualDamage= RoundToNearest(damage);
					
					if (health-ActualDamage < 0)
					{
						SetEntityHealth(i, 0)
						ForcePlayerSuicide(i)
						PrintToChatAll("\x03 %N\x04 Pipe Bomb \x03%N",i_Client, i);	
						if (GetConVarInt(GameType)==1)//ffa
						{
							if(TeamState[i_Client]!=TeamState[i])
							{
								playerscore[i_Client]++;
								playerscoreTemp[i_Client]++;//add friendly fire block here
							}
						}
						
						if (GetConVarInt(GameType)==2)//ffa
						{
							playerscore[i_Client]++;
						}
						
						new entity;
						for (new j=0; j<4; j++) 
						{
							entity = GetPlayerWeaponSlot(i, j);
							if (IsValidEdict(entity)) 
							{
								RemovePlayerItem(i, entity);
								RemoveEdict(entity);
							}
						} 
					}
					
					else SetEntityHealth(i, health-ActualDamage);
				}
				if (GetVectorDistance(f_Origin, f_EntOrigin) >70 && GetVectorDistance(f_Origin, f_EntOrigin) <160)
				{
					SetEntProp(i, Prop_Send, "m_iGlowType", 3)
					SetEntProp(i, Prop_Send, "m_glowColorOverride", 254);	
					CreateTimer(0.3, HitmarkerGlow, i)	
					damage = 50.0;//+propane damage
					ActualDamage= RoundToNearest(damage);
					
					if (health-ActualDamage < 0)
					{
						SetEntityHealth(i, 0)
						ForcePlayerSuicide(i)
						PrintToChatAll("\x03 %N\x04 Pipe Bomb \x03%N",i_Client, i);
						if (GetConVarInt(GameType)==1)//ffa
						{
							if(TeamState[i_Client]!=TeamState[i])
							{
								playerscore[i_Client]++;
								playerscoreTemp[i_Client]++;//add friendly fire block here
							}
						}
						
						if (GetConVarInt(GameType)==2)//ffa
						{
							playerscore[i_Client]++;
						}
						new entity;
						for (new j=0; j<4; j++) 
						{
							entity = GetPlayerWeaponSlot(i, j);
							if (IsValidEdict(entity)) 
							{
								RemovePlayerItem(i, entity);
								RemoveEdict(entity);
							}
						} 
					}
					
					else SetEntityHealth(i, health-ActualDamage);
				}
				if (GetVectorDistance(f_Origin, f_EntOrigin) >160 && GetVectorDistance(f_Origin, f_EntOrigin) <240)
				{
					SetEntProp(i, Prop_Send, "m_iGlowType", 3)
					SetEntProp(i, Prop_Send, "m_glowColorOverride", 254);	
					CreateTimer(0.3, HitmarkerGlow, i)	
					damage = 30.0;
					ActualDamage= RoundToNearest(damage);
					
					if (health-ActualDamage < 0)
					{
						SetEntityHealth(i, 0)
						ForcePlayerSuicide(i)
						PrintToChatAll("\x03 %N\x04 Pipe Bomb \x03%N",i_Client, i);	
						if (GetConVarInt(GameType)==1)//ffa
						{
							if(TeamState[i_Client]!=TeamState[i])
							{
								playerscore[i_Client]++;
								playerscoreTemp[i_Client]++;//add friendly fire block here
							}
						}
						
						if (GetConVarInt(GameType)==2)//ffa
						{
							playerscore[i_Client]++;
						}
						new entity;
						for (new j=0; j<4; j++) 
						{
							entity = GetPlayerWeaponSlot(i, j);
							if (IsValidEdict(entity)) 
							{
								RemovePlayerItem(i, entity);
								RemoveEdict(entity);
							}
						} 
					}		
					else SetEntityHealth(i, health-ActualDamage);
				}
				
				
			}
			
		}
		
		
		return Plugin_Continue
	}
	
	if (i_Count >= BOUNCE_TIME)
	{
		f_Angles[0] = 90.0
		f_Angles[1] = 0.0
		f_Angles[2] = 0.0
		
		TeleportEntity(i_Ent, NULL_VECTOR, f_Angles, NULL_VECTOR)
		
		f_Units = OnGroundUnits(i_Ent)
		
		if (0.0 < f_Units <= 7.0)
		{
			f_Origin[2] -= f_Units - 2.0
			SetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin)
			SetEntityMoveType(i_Ent, MOVETYPE_NONE)
		}
	}
	else
	{
		GetRandomAngles(f_Angles)
		TeleportEntity(i_Ent, NULL_VECTOR, f_Angles, NULL_VECTOR)
	}
	
	switch (i_Count)
	{
		case 4,8,12,16,20,23,26,29,32,35,37,39,41,43,45:
		EmitSoundToAll(SOUND_PIPEBOMB, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, f_Origin, NULL_VECTOR, false, 0.0)
	}
	
	if (i_Count > 45)
		EmitSoundToAll(SOUND_PIPEBOMB, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, f_Origin, NULL_VECTOR, false, 0.0)
	
	i_Count++
	SetTrieValue(g_t_PipeTicks, s_Ent, i_Count)
	
	return Plugin_Continue
}

public Float:OnGroundUnits(i_Ent)
{
	if (!(GetEntityFlags(i_Ent) & (FL_ONGROUND)))
	{ 
		decl Handle:h_Trace, Float:f_Origin[3], Float:f_Position[3], Float:f_Down[3] = { 90.0, 0.0, 0.0 }
		
		GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin)
		h_Trace = TR_TraceRayFilterEx(f_Origin, f_Down, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceFilterClients, i_Ent)
		
		if (TR_DidHit(h_Trace))
		{
			decl Float:f_Units
			TR_GetEndPosition(f_Position, h_Trace)
			
			f_Units = f_Origin[2] - f_Position[2]
			
			CloseHandle(h_Trace)
			
			return f_Units
		} 
		
		CloseHandle(h_Trace)
	} 
	
	return 0.0
}	

public bool:TraceFilterClients(i_Entity, i_Mask, any:i_Data)
{
	if (i_Entity == i_Data)
		return false
	if (i_Entity >= 1 && i_Entity <= MaxClients)
		return false
	
	return true
}


public Action:Event_Player_Shoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (RandomBonusMode == 2)
	{
		decl Main_weapon, String:s_ModelName[128]
		Main_weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (IsValidEdict(Main_weapon))
		{
			GetEdictClassname(Main_weapon, s_ModelName, sizeof(s_ModelName)); 
			if (StrContains(s_ModelName, "gnome", false) != -1)
			{
				SetEntProp(client, Prop_Send, "m_iGlowType", 3)
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 254);
				CreateTimer(0.3, HitmarkerGlow, client)	
				new health = GetClientHealth(client);
				new damage = 70;
				if (health-damage < 0)
				{		
					SetEntityHealth(client, 0);
					ForcePlayerSuicide(client)
					PrintToChatAll("\x03 %N \x04 CHOMPSKY SMACKED \x03%N to DEATH", attacker, client);	
				}
				else SetEntityHealth(client, health-damage);
			}
			
		}
		
	}
	else
	{
		if (GetConVarInt(GameType)==1)
		{	
			if(!IsFakeClient(client))
			{
				if(TeamState[attacker]!=TeamState[client])
				{
					SetEntProp(client, Prop_Send, "m_iGlowType", 3)
					SetEntProp(client, Prop_Send, "m_glowColorOverride", 254);
					CreateTimer(0.3, HitmarkerGlow, client)	
					new health = GetClientHealth(client);
					new damage = 27;
					if (health-damage < 0)
					{		
						SetEntityHealth(client, 0);
						ForcePlayerSuicide(client)
						playerscore[attacker]++;
						playerscoreTemp[attacker]++;
						PrintToChatAll("\x03 %N \x04 BEAT \x03%N to DEATH", attacker, client);	
					}
					else SetEntityHealth(client, health-damage);
				}	
			}	
		}
		if (GetConVarInt(GameType)==2)
		{
			if(!IsFakeClient(client))
			{
				SetEntProp(client, Prop_Send, "m_iGlowType", 3)
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 254);
				CreateTimer(0.3, HitmarkerGlow, client)	
				new health = GetClientHealth(client);
				new damage = 27;
				if (health-damage < 0)
				{		
					SetEntityHealth(client, 0);
					ForcePlayerSuicide(client)
					playerscore[attacker]++;
					PrintToChatAll("\x03 %N \x04 BEAT \x03%N to DEATH", attacker, client);	
				}
				else SetEntityHealth(client, health-damage);
			}
		}
	}
	
	
	
	
	
	
	
	
	
	
}

public Action:UsedAdrenaline(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{
		new client = GetClientOfUserId(GetEventInt(event, "subject"));
		new temphpoffset = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
		SetEntDataFloat(client, temphpoffset, 50.0, true);
	}
}

public Action:pills_used(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{
		new client = GetClientOfUserId(GetEventInt(event, "subject"));
		new temphpoffset = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
		SetEntDataFloat(client, temphpoffset, 70.0, true);
		
	}
}



public Action:Event_BulletImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{
		new userid = GetClientOfUserId(GetEventInt(event, "userid"));
		
		new Float:x=GetEventFloat(event, "x");
		new Float:y=GetEventFloat(event, "y");
		new Float:z=GetEventFloat(event, "z");
		
		decl Float:BulletPos[3];
		BulletPos[0]=x;
		BulletPos[1]=y;
		BulletPos[2]=z;
		Bullet_impact[userid]=BulletPos;
	}	
}

public Action:Event_Falling_damage(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new health = GetClientHealth(client)
		new Float:damages = GetEventFloat(event,"damage") 
		new IntDamage = RoundToNearest(damages);
		if (IsValidClient(client))
		{
			SetEntityHealth(client, (IntDamage + health));
		}
	}
}

public Action:Boomer_vomit(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new bool:COD = GetEventBool(event, "exploded");
		
		if(COD==false)
		{
			if (RandomBonusMode == 1)
			{
				if(IsClientInGame(client) && IsValidClient(attacker) && !IsFakeClient(client))
				{	
					//add some kind of special laser from the sky here and freeze the player, make them look infected, done
					TeamState[client]=INFECTED_TEAM;
					PrintToChatAll("\x03 %N \x04 Has been infected by \x03%N", client, attacker);
					playerscore[attacker]++;
					CreateTimer(0.5, DisplayLaser, client);
				}
			}
		}
		else
		{
			//PrintToChatAll("Cause of death = Explosion");
		}
	}
}

public Action:DisplayLaser(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		CreateLaserEffectFreeze(client, 100, 230, 80, 230, 6.0, 4.0, VERTICAL);
	}
}

public CreateLaserEffectVomitjar(Float:entityxyz[3], colRed, colGre, colBlu, alpha, Float:width, Float:duration, mode)
{
	decl color[4];
	color[0] = colRed;
	color[1] = colGre;
	color[2] = colBlu;
	color[3] = alpha;
	decl Float:lchPos[3];
	
	lchPos=entityxyz;
	lchPos[2] += 50;
	
	if(mode == VERTICAL)
	{
		TE_SetupGlowSprite(lchPos, g_GlowSprite, 1.5, 2.8, 230);
		TE_SendToAll();
	}
}

public CreateLaserEffectFreeze(client, colRed, colGre, colBlu, alpha, Float:width, Float:duration, mode)
{
	decl color[4];
	color[0] = colRed;
	color[1] = colGre;
	color[2] = colBlu;
	color[3] = alpha;
	decl Float:pos[3];
	decl Float:lchPos[3];
	GetClientAbsOrigin(client, pos);
	
	SetEntDataFloat(client, LagMovement, 0.0, true);
	lchPos=pos;
	lchPos[2] += 650;
	
	if(mode == VERTICAL)
	{
		TE_SetupBeamPoints(lchPos, pos, g_BeamSprite, 0, 0, 0,
		duration, width, width, 1, 2.0, color, 0);
		TE_SendToAll();
		TE_SetupGlowSprite(lchPos, g_GlowSprite, 1.5, 2.8, 230);
		TE_SendToAll();
	}
	
	
	decl String:s_Model[128], i_Random
	
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, sizeof(s_Model))
	
	if (StrContains(s_Model, "gambler") != -1)
	{
		i_Random = GetRandomInt(1,3)
		switch (i_Random)
		{
			case 1:
			{
				EmitSoundToAll(
				BOOM_ONE_NICK, client,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			case 2:
			{
				EmitSoundToAll(
				BOOM_TWO_NICK, client,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			case 3:
			{
				EmitSoundToAll(
				BOOM_THREE_NICK, client,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			
		}
	}
	else if (StrContains(s_Model, "coach") != -1)
	{
		i_Random = GetRandomInt(1,3)
		switch (i_Random)
		{
			case 1:
			{
				EmitSoundToAll(
				BOOM_ONE_COACH, client,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				
			}
			case 2:
			{
				EmitSoundToAll(
				BOOM_TWO_COACH, client,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			case 3:
			{
				EmitSoundToAll(
				BOOM_THREE_COACH, client,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			
		}
	}
	else if (StrContains(s_Model, "mechanic") != -1)
	{
		i_Random = GetRandomInt(1,3)
		switch (i_Random)
		{
			case 1:
			{
				EmitSoundToAll(
				BOOM_ONE_ELLIS, client,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			case 2:
			{
				EmitSoundToAll(
				BOOM_TWO_ELLIS, client,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			case 3:
			{
				EmitSoundToAll(
				BOOM_THREE_ELLIS, client,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			
		}
	}
	else if (StrContains(s_Model, "producer") != -1)
	{
		i_Random = GetRandomInt(1,3)
		switch (i_Random)
		{
			case 1:
			{
				EmitSoundToAll(
				BOOM_ONE_ROCHELLE, client,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			case 2:
			{
				EmitSoundToAll(
				BOOM_TWO_ROCHELLE, client,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			case 3:
			{
				EmitSoundToAll(
				BOOM_THREE_ROCHELLE, client,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			
		}
	}
	
}

public Action:Boomer_vomit_No_longer(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		
		if (RandomBonusMode == 1)
		{
			ForcePlayerSuicide(client)
		}
	}
}



public Action:Declare_first_blood(Handle:timer, any:client)
{
	
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{	
		decl String:Model[150]
		GetClientModel(client, Model, sizeof(Model));
		
		if(StrContains(Model, "mechanic", false) > -1)
			
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i)==2)
			{
				EmitSoundToAll(
				FIRSTBLOODELLIS, i,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
		}	
		
		else if(StrContains(Model, "coach", false) > -1)
			
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i)==2)
			{
				EmitSoundToAll(
				FIRSTBLOODCOACH, i,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
		}				
		
		else if(StrContains(Model, "producer", false) > -1)
			
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i)==2)
			{
				EmitSoundToAll(
				FIRSTBLOODROCHELLE, i,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				
			}
		}				
		
		else if(StrContains(Model, "gambler", false) > -1)
			
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i)==2)
			{
				EmitSoundToAll(
				FIRSTBLOODNICK, i,
				SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
				100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				
			}
		}	
		PrintToChatAll("\x03%N\x04 F1RST BL00D!!", client);
		
		
	}
}

public Action:HitmarkerGlow(Handle:h_Timer, any:i_Ent)
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{
		decl String:s_ModelName[64]
		
		if (IsValidEdict(i_Ent) || IsValidEntity(i_Ent))
		{
			
			GetEntPropString(i_Ent, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName))
			
			if (StrContains(s_ModelName, "infected") || StrContains(s_ModelName, "survivors") != -1)
			{
				SetEntProp(i_Ent, Prop_Send, "m_iGlowType", 0)
				SetEntProp(i_Ent, Prop_Send, "m_glowColorOverride", 0)
			}
		}
		
	}
}

public Action:KillInfectedHuman(Handle:Timer, any:client)
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{
		
		ForcePlayerSuicide(client);
		
		
	}
}

/*
public IsSpawnFree(Teleport_accessed)
{
decl Float:f_EntOrigin[3]
if(initial_stage==false)
{
for (new j = 1; j <= MaxClients; j++)
{
if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX) 
{
//GetEntPropVector(j, Prop_Send, "m_vecOrigin", Teleport_accessed)
GetEntPropVector(j, Prop_Send, "m_vecOrigin", f_EntOrigin)
GetClientAbsOrigin(j, f_EntOrigin)
if (GetVectorDistance(f_EntOrigin, Teleport_accessed) <= 60)
{		
return false;
}

}
}
return true;
}
else
{
return false;
}
}
*/

public IsValidClient(client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsValidEntity(client))
		return false;
	
	return true;
}




public Action:Setgamemode(Handle:timer)
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{	
		SetConVarString(FindConVar("mp_gamemode"), "versus")
		SetConVarString(FindConVar("z_difficulty"), "Hard")	
		CreateTimer(1.0,Decide_Spawn_positions);//depending on map, the red and blue team spawns vary
	}
}



public Action:Give_Custom_weapons(Handle:timer)
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{	
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==2)
			{
				if(PrimaryGiven[i]==0)
				{
					new flags = GetCommandFlags("give");
					SetCommandFlags("give", flags & ~FCVAR_CHEAT);
					if (SurvivorClass[i]==CUSTOM)
					{
						if(primaryChosen[i]==1)
						{
							FakeClientCommand(i, "give pumpshotgun");
							PrimaryGiven[i]=1;
						}
						if(primaryChosen[i]==2)
						{
							FakeClientCommand(i, "give shotgun_chrome");
							PrimaryGiven[i]=1;
						}
						if(primaryChosen[i]==3)
						{
							FakeClientCommand(i, "give smg");
							PrimaryGiven[i]=1;					
							
						}					
						if(primaryChosen[i]==4)
						{
							FakeClientCommand(i, "give smg_silenced");
							PrimaryGiven[i]=1;					
							
						}					
						if(primaryChosen[i]==5)
						{
							FakeClientCommand(i, "give smg_mp5");
							PrimaryGiven[i]=1;					
							
						}
						
						if(primaryChosen[i]==6)
						{
							FakeClientCommand(i, "give hunting_rifle");
							PrimaryGiven[i]=1;					
						}
						
						if(primaryChosen[i]==7)
						{
							FakeClientCommand(i, "give autoshotgun");
							PrimaryGiven[i]=1;					
						}
						
						if(primaryChosen[i]==8)
						{
							FakeClientCommand(i, "give shotgun_spas");
							PrimaryGiven[i]=1;					
						}
						
						if(primaryChosen[i]==9)
						{
							FakeClientCommand(i, "give rifle");
							PrimaryGiven[i]=1;					
						}
						
						if(primaryChosen[i]==10)
						{
							FakeClientCommand(i, "give rifle_ak47");
							PrimaryGiven[i]=1;					
						}
						
						if(primaryChosen[i]==11)
						{
							FakeClientCommand(i, "give rifle_desert");
							PrimaryGiven[i]=1;					
						}
						if(primaryChosen[i]==12)
						{
							FakeClientCommand(i, "give rifle_sg552");
							PrimaryGiven[i]=1;					
						}
						if(primaryChosen[i]==13)
						{
							FakeClientCommand(i, "give sniper_military");
							PrimaryGiven[i]=1;					
						}
						if(primaryChosen[i]==14)
						{
							FakeClientCommand(i, "give sniper_scout");
							PrimaryGiven[i]=1;					
						}
						if(primaryChosen[i]==15)
						{
							FakeClientCommand(i, "give sniper_awp");
							PrimaryGiven[i]=1;					
						}
						if(primaryChosen[i]==16)
						{
							FakeClientCommand(i, "give rifle_m60");
							PrimaryGiven[i]=1;					
						}
						
					}
					
					SetCommandFlags("give", flags|FCVAR_CHEAT);	
					
				}
				if(SecondaryGiven[i]==0)
				{
					new flags = GetCommandFlags("give");
					SetCommandFlags("give", flags & ~FCVAR_CHEAT);
					if (SurvivorClass[i]==CUSTOM)
					{
						if(SecondaryChosen[i]==1)
						{
							FakeClientCommand(i, "give pistol");
							SecondaryGiven[i]=1;
						}
						if(SecondaryChosen[i]==2)
						{
							if(mapNum==DARK_CARNIVAL)
							{
								new randomMelee= GetRandomInt(0, 3)
								if(randomMelee==0)
								{
									FakeClientCommand(i, "give fireaxe");
								}
								if(randomMelee==1)
								{
									FakeClientCommand(i, "give crowbar");
								}
								if(randomMelee==2)
								{
									FakeClientCommand(i, "give electric_guitar");
								}
								if(randomMelee==3)
								{
									FakeClientCommand(i, "give katana");
								}
							}
							else if(mapNum==THE_PARISH)
							{
								new randomMelee= GetRandomInt(0, 3)
								if(randomMelee==0)
								{
									FakeClientCommand(i, "give frying_pan");
								}
								if(randomMelee==1)
								{
									FakeClientCommand(i, "give machete");
								}
								if(randomMelee==2)
								{
									FakeClientCommand(i, "give tonfa");
								}
								if(randomMelee==3)
								{
									FakeClientCommand(i, "give electric_guitar");
								}
							}
							else if(mapNum==DEAD_CENTER)
							{
								new randomMelee= GetRandomInt(0, 3)
								if(randomMelee==0)
								{
									FakeClientCommand(i, "give fireaxe");
								}
								if(randomMelee==1)
								{
									FakeClientCommand(i, "give baseball_bat");
								}
								if(randomMelee==2)
								{
									FakeClientCommand(i, "give cricket_bat");
								}
								if(randomMelee==3)
								{
									FakeClientCommand(i, "give katana");
								}
							}
							else if(mapNum==HARD_RAIN)
							{
								//not available yet
							}
							else if(mapNum==SWAMP_FEVER)
							{
								
							}
							else
							{
								new randomMelee= GetRandomInt(0, 7)
								if(randomMelee==0)
								{
									FakeClientCommand(i, "give fireaxe");
								}
								if(randomMelee==1)
								{
									FakeClientCommand(i, "give baseball_bat");
								}
								if(randomMelee==2)
								{
									FakeClientCommand(i, "give cricket_bat");
								}
								if(randomMelee==3)
								{
									FakeClientCommand(i, "give katana");
								}
								if(randomMelee==4)
								{
									FakeClientCommand(i, "give frying_pan");
								}
								if(randomMelee==5)
								{
									FakeClientCommand(i, "give machete");
								}
								if(randomMelee==6)
								{
									FakeClientCommand(i, "give tonfa");
								}
								if(randomMelee==7)
								{
									FakeClientCommand(i, "give electric_guitar");
								}
							}
							SecondaryGiven[i]=1;
							
							
							
						}
						if(SecondaryChosen[i]==3)
						{
							FakeClientCommand(i, "give pistol_magnum");
							SecondaryGiven[i]=1;					
							
						}					
						if(SecondaryChosen[i]==4)
						{
							FakeClientCommand(i, "give chainsaw");
							SecondaryGiven[i]=1;					
						}					
						
						
					}
					SetCommandFlags("give", flags|FCVAR_CHEAT);	
				}
				if(EmergencyGiven[i]==0)
				{
					new flags = GetCommandFlags("give");
					SetCommandFlags("give", flags & ~FCVAR_CHEAT);
					if (SurvivorClass[i]==CUSTOM)
					{
						if(EmergencyChosen[i]==1)
						{
							FakeClientCommand(i, "give pain_pills");
							EmergencyGiven[i]=1;
						}
						if(EmergencyChosen[i]==2)
						{
							FakeClientCommand(i, "give adrenaline");
							EmergencyGiven[i]=1;
						}
						
					}
					SetCommandFlags("give", flags|FCVAR_CHEAT);	
				}
				if(GrenadeGiven[i]==0)
				{
					new flags = GetCommandFlags("give");
					SetCommandFlags("give", flags & ~FCVAR_CHEAT);
					if (SurvivorClass[i]==CUSTOM)
					{
						if(GrenadeChosen[i]==1)
						{
							FakeClientCommand(i, "give vomitjar");
							GrenadeGiven[i]=1;
						}
						if(GrenadeChosen[i]==2)
						{
							FakeClientCommand(i, "give pipe_bomb");
							GrenadeGiven[i]=1;
						}
						if(GrenadeChosen[i]==3)
						{
							FakeClientCommand(i, "give molotov");
							GrenadeGiven[i]=1;
						}
						
					}
					SetCommandFlags("give", flags|FCVAR_CHEAT);	
				}
				
				
				
				
			}
			
			WeaponsGiven[i]=1;	
		}
	}
}

public Action:Give_weapons(Handle:timer)
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{	
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i)==3)
			{
				CanISpawn[i]=ALLOWSPAWN;
			}
			
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==2)
			{
				if(WeaponsGiven[i]==0)
				{
					//RemoveItems(i);
					//PrintToChatAll( "REMOVE ITEMS STARTED");	
					new flags = GetCommandFlags("give");
					SetCommandFlags("give", flags & ~FCVAR_CHEAT);
					if(SurvivorClass[i]==SNIPER)
					{
						//PrintToChatAll( "SNIPER found");
						//idea for the first 4 minutes of the game only give tier 1 weapons the rest, tier 2
						//also switch map areas between 4 minutes 8 minutes total
						// to add other weapons use getrandom int and add all other weapons etc
						
						new snipe_kit;
						snipe_kit=GetRandomInt(0,2)
						if(First_fourMinutes==true)
						{
							snipe_kit=3;
						}
						if(snipe_kit==0)
						{
							FakeClientCommand(i, "give baseball_bat");
							FakeClientCommand(i, "give sniper_awp");
							FakeClientCommand(i, "give adrenaline");
							FakeClientCommand(i, "give vomitjar"); 
						}
						if(snipe_kit==1)
						{
							FakeClientCommand(i, "give baseball_bat");
							FakeClientCommand(i, "give sniper_scout");
							FakeClientCommand(i, "give pain_pills");
							FakeClientCommand(i, "give pipe_bomb"); 
						}
						if(snipe_kit==2)
						{
							FakeClientCommand(i, "give crowbar");
							FakeClientCommand(i, "give sniper_military");
							FakeClientCommand(i, "give pain_pills");
							FakeClientCommand(i, "give vomitjar"); 
						}
						if(snipe_kit==3)
						{
							FakeClientCommand(i, "give katana");
							FakeClientCommand(i, "give hunting_rifle");//tier 1 class
							FakeClientCommand(i, "give adrenaline");
							FakeClientCommand(i, "give pipe_bomb"); 
						}
						
						
						WeaponsGiven[i]=1;
					}
					
					
					else if (SurvivorClass[i]==ASSAULT)
					{
						new assault_kit;
						assault_kit=GetRandomInt(0,3)
						if(First_fourMinutes==true)
						{
							assault_kit=4;
						}
						if(assault_kit==0)
						{
							FakeClientCommand(i, "give rifle");
							FakeClientCommand(i, "give fireaxe");
							FakeClientCommand(i, "give pain_pills");
							FakeClientCommand(i, "give pipe_bomb"); 
						}
						
						if(assault_kit==1)
						{
							FakeClientCommand(i, "give pistol");
							FakeClientCommand(i, "give rifle_ak47");
							FakeClientCommand(i, "give adrenaline");
							FakeClientCommand(i, "give vomitjar"); 
						}
						if(assault_kit==2)
						{
							FakeClientCommand(i, "give pistol");
							FakeClientCommand(i, "give rifle_desert");
							FakeClientCommand(i, "give pain_pills");
							FakeClientCommand(i, "give pipe_bomb"); 
						}
						if(assault_kit==3)
						{
							FakeClientCommand(i, "give pistol_magnum");
							FakeClientCommand(i, "give rifle_sg552");
							FakeClientCommand(i, "give adrenaline");
							FakeClientCommand(i, "give vomitjar"); 
						}
						if(assault_kit==4)
						{
							FakeClientCommand(i, "give pistol");
							FakeClientCommand(i, "give smg");
							FakeClientCommand(i, "give pain_pills");
							FakeClientCommand(i, "give pipe_bomb"); 
						}			
						WeaponsGiven[i]=1;
					}
					
					
					else if (SurvivorClass[i]==MEDIC)//ideas:crouch to heal yourself(no crouch walking), 
					{
						new medic_kit;
						medic_kit=GetRandomInt(0,2)
						if(First_fourMinutes==true)
						{
							medic_kit=3;
						}
						if(medic_kit==0)
						{
							FakeClientCommand(i, "give pumpshotgun");
							FakeClientCommand(i, "give pain_pills");
							FakeClientCommand(i, "give first_aid_kit");
							FakeClientCommand(i, "give katana");
							FakeClientCommand(i, "give pipe_bomb"); 
						}
						if(medic_kit==1)
						{		
							FakeClientCommand(i, "give smg_silenced");
							FakeClientCommand(i, "give pain_pills");
							FakeClientCommand(i, "give first_aid_kit");
							FakeClientCommand(i, "give pistol_magnum");	
							FakeClientCommand(i, "give vomitjar"); 
						}
						if(medic_kit==2)
						{		
							FakeClientCommand(i, "give shotgun_chrome");
							FakeClientCommand(i, "give pain_pills");
							FakeClientCommand(i, "give first_aid_kit");
							FakeClientCommand(i, "give pistol");		
							FakeClientCommand(i, "give pipe_bomb"); 
						}
						if(medic_kit==3)
						{		
							//FakeClientCommand(i, "give shotgun_chrome");
							FakeClientCommand(i, "give pain_pills");
							FakeClientCommand(i, "give first_aid_kit");
							FakeClientCommand(i, "give pistol_magnum");		
							FakeClientCommand(i, "give vomitjar"); 
						}		
						WeaponsGiven[i]=1;
					}
					else if (SurvivorClass[i]==SHOTGUN)
					{
						new shotgun_kit;
						shotgun_kit=GetRandomInt(0,1)
						if(First_fourMinutes==true)
						{
							shotgun_kit=2;
						}
						if(shotgun_kit==0)
						{
							FakeClientCommand(i, "give fireaxe");
							FakeClientCommand(i, "give autoshotgun");//or spaz
							FakeClientCommand(i, "give pain_pills");
							FakeClientCommand(i, "give pipe_bomb"); 
						}	
						if(shotgun_kit==1)
						{
							FakeClientCommand(i, "give pistol_magnum");
							FakeClientCommand(i, "give shotgun_spas");//or spaz
							FakeClientCommand(i, "give adrenaline");
							FakeClientCommand(i, "give vomitjar"); 
						}	
						
						if(shotgun_kit==2)
						{
							FakeClientCommand(i, "give fireaxe");
							FakeClientCommand(i, "give pumpshotgun");//or spaz
							FakeClientCommand(i, "give pain_pills");
							FakeClientCommand(i, "give vomitjar"); 
						}	
						WeaponsGiven[i]=1;
					}
					else if (SurvivorClass[i]==HEAVYGUN)
					{
						new heavygun_kit;
						heavygun_kit=GetRandomInt(0,1)
						if(First_fourMinutes==true)
						{
							heavygun_kit=2;
						}
						if(heavygun_kit==0)
						{
							FakeClientCommand(i, "give pistol_magnum");//or spaz
							FakeClientCommand(i, "give rifle_m60");//or spaz
							FakeClientCommand(i, "give vomitjar"); 
						}	
						if(heavygun_kit==1)
						{
							FakeClientCommand(i, "give rifle_m60");
							FakeClientCommand(i, "give pistol_magnum");//or spaz
							FakeClientCommand(i, "give pipe_bomb"); 
						}	
						
						if(heavygun_kit==2)
						{
							FakeClientCommand(i, "give fireaxe");
							FakeClientCommand(i, "give pumpshotgun");//or spaz
							FakeClientCommand(i, "give pain_pills");
							FakeClientCommand(i, "give vomitjar"); 
						}	
						WeaponsGiven[i]=1;
					}
					
					
					
					SetCommandFlags("give", flags|FCVAR_CHEAT);
				}
				
				
			}
			
			
		}			
		
	}
}



bool:SpawnBebopFakeClient()
{
	// init ret value
	new bool:ret = false;
	// create fake client
	new client = 0;
	client = CreateFakeClient("Fake_player");
	
	// if entity is valid
	if (client != 0)
	{
		// move into survivor team
		ChangeClientTeam(client, 2);
		//FakeClientCommand(client, "jointeam %i", ID_TEAM_SURVIVOR);
		
		// set entity classname to survivorbot
		if (DispatchKeyValue(client, "classname", "survivorbot") == true)
		{
			// spawn the client
			if (DispatchSpawn(client) == true)
			{
				// kick the fake client to make the bot take over
				CreateTimer(0.1, Timer_KickBebopFakeClient, client, TIMER_REPEAT);
				ret = true;
			}
			else
			{
			}
		}
		else
		{	
		}
		
		// if something went wrong kick the created fake client
		if (ret == false)
		{
			KickClient(client, "");
		}
	}
	else
	{
		
	}
	
	return ret;
}

public Action:Timer_KickBebopFakeClient(Handle:timer, any:client)
{
	if (IsClientConnected(client))
	{
		KickClient(client, "client_is_bebop_fakeclient");
	}
	
	return Plugin_Stop;
}

public OnMapStart()
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{	
		HookEvent("player_disconnect", PlayerDisconnectEvent);
		Round_two = true;
		
		g_PipebombModel = PrecacheModel(MODEL_V_PIPEBOMB, true)
		g_VomitjarModel = PrecacheModel(MODEL_V_VOMITJAR, true)
		g_MolotovModel = PrecacheModel(MODEL_V_MOLOTOV, true)
		g_HaloSprite = PrecacheModel(SPRITE_HALO);
		g_BeamSprite = PrecacheModel(SPRITE_BEAM);
		g_GlowSprite = PrecacheModel(SPRITE_GLOW);
		g_Crystalsprite = PrecacheModel(CRYSTAL_BEAM);
		
		PrecacheModel(SMOKEGRENADE);
		if (!IsModelPrecached(MODEL_PROPANE))
			PrecacheModel(MODEL_PROPANE, true)
		if (!IsModelPrecached(MODEL_GASCAN))
			PrecacheModel(MODEL_GASCAN, true)
		if (!IsModelPrecached(MODEL_BARREL))
			PrecacheModel(MODEL_BARREL, true)
		if (!IsModelPrecached(MODEL_W_PIPEBOMB))
			PrecacheModel(MODEL_W_PIPEBOMB, true)
		if (!IsSoundPrecached(SOUND_PIPEBOMB))
			PrecacheSound(SOUND_PIPEBOMB, true)
		
		g_PistolModel = PrecacheModel(MODEL_V_PISTOL, true)
		g_DualPistolModel = PrecacheModel(MODEL_V_DUALPISTOL, true)
		g_MagnumModel = PrecacheModel(MODEL_V_MAGNUM, true)
	}
}

public CreateRingEffectGnome(String:ent[64], colRed, colGre, colBlu, alpha, Float:width, Float:duration)
{
	new Float:pos[3];
	GetEntPropVector(sizeof(ent), Prop_Send, "m_vecOrigin", pos);
	
	decl color[4];
	color[0] = colRed;
	color[1] = colGre;
	color[2] = colBlu;
	color[3] = alpha;
	
	TE_SetupBeamRingPoint(pos, 300.0, 10.0, g_BeamSprite,
	g_HaloSprite, 0, 10, 1.2, 4.0, 0.5,
	{150, 150, 230, 230}, 80, 0);
	TE_SendToAll();
}

public CreateLaserEffectTestBoomer(client)
{
	TE_SetupBeamFollow(client, g_Crystalsprite, 0, 1.0, 10.0, 10.0, 10, {255,0,0,255});
	TE_SendToAll();	
}
public CreateLaserEffectJetpack(client)
{
	decl Float:pos[3];
	decl Float:lchPos[3];
	GetClientAbsOrigin(client, pos)
	decl color[4];
	color[0] = 0;
	color[1] = 100;
	color[2] = 80;
	color[3] = 230;					
	lchPos=pos;
	lchPos[2] -= 100;					
	//TE_SetupBeamPoints(lchPos, pos, g_BeamSprite, 0, 0, 0,
	//2.0, 3.0, 3.0, 1, 0.5, color, 0);
	//TE_SendToAll();
	
	TE_SetupGlowSprite(lchPos, g_GlowSprite, 1.5, 2.8, 230);
	TE_SendToAll();
}


public CreateLaserEffectTestHuman(client)
{
	TE_SetupBeamFollow(client, g_Crystalsprite, 0, 1.0, 10.0, 10.0, 10, {0,255,0,255});
	TE_SendToAll();	
}



public CreateRingEffect(client, colRed, colGre, colBlu, alpha, Float:width, Float:duration)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	decl color[4];
	color[0] = colRed;
	color[1] = colGre;
	color[2] = colBlu;
	color[3] = alpha;
	
	TE_SetupBeamRingPoint(pos, 300.0, 10.0, g_BeamSprite,
	g_HaloSprite, 0, 10, 1.2, 4.0, 0.5,
	{150, 150, 230, 230}, 80, 0);
	TE_SendToAll();
}

public Action:Remove_Grenades(Handle:Timer) //lazy way to fix the high health bug, untill i find out whats the cause
{
	for (new j = 1; j <= MaxClients; j++)
	{
		if (IsClientInGame(j))
		{
			new entity;
			entity = GetPlayerWeaponSlot(j, 2);
			if (IsValidEdict(entity)) 
			{
				RemovePlayerItem(j, entity);
				RemoveEdict(entity);
			}
		}  
	}
	
}

public PlayerDisconnectEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		for (new i = 1; i > 0 ; i--)
		{
			if (timer_handle[client][i] != INVALID_HANDLE)
			{
				KillTimer(timer_handle[client][i]);
				timer_handle[client][i] = INVALID_HANDLE;
				CloseHandle(hurtdata[client][i]);
			}
		}
	}
}


public Action:FixSIXTYTHOUSANDbug(Handle:Timer) //lazy way to fix the high health bug, untill i find out whats the cause
{
	for (new j = 1; j <= MaxClients; j++)
	{
		if (IsClientInGame(j))
		{
			new health = GetClientHealth(j)
			if(health>2000)	
			{
				SetEntityHealth(j, 100)
			}
		}
		
	}
	
}


public Action:Sort_Decoy(Handle:Timer) 
{
	if (GetConVarInt(GameType)==1)//TEAM
	{
		if(Round_started==false)
		{
			Round_started=true;
			CreateTimer(0.5, Check_burning, _,  TIMER_REPEAT);
			CreateTimer(3.5, Add_HaloETC, _,  TIMER_REPEAT);
			CreateTimer(0.1, Keep_high_Health, _,  TIMER_REPEAT)
			CreateTimer(0.5, Determine_nades, _,  TIMER_REPEAT);
			CreateTimer(1.0, Award_Bonuses, _, TIMER_REPEAT)
			CreateTimer(0.3, Custom_stuff, _, TIMER_REPEAT)
			CreateTimer(1.8, Tell_them_whos_who, _, TIMER_REPEAT)
			CreateTimer(25.0, Sort_teams_out)
			CreateTimer(15.0,Remove_corpse);
			CreateTimer(1.0, keep_em_survivors, _, TIMER_REPEAT)
			CreateTimer(2.0, Paint_Teams, _, TIMER_REPEAT)
			CreateTimer(3.0, Spawn_non_survivors, _, TIMER_REPEAT)
			CreateTimer(2.0, ScoreUpdate, _, TIMER_REPEAT)
			
			
			for (new j = 1; j <= MaxClients; j++)
			{
				if (IsClientInGame(j)) 
				{
					
					if(TeamState[j]==NO_TEAM)
					{
						ChooseTeamMenu(j);
						
					}
					else
					{
						ChooseClassMenu(j);
						
					}
				}
			}
			
			if(Round_two == false)
			{
				CreateTimer(GetConVarFloat(Each_round_time)+9.0, MapRotation)
				CreateTimer(1.0, start_game)
				//PrintToChatAll("MAP ROTATIONS TIMER STARTED");
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i)) 
					{
						if(TeamState[i]==BLUE_TEAM)
						{
							TeamState[i]=RED_TEAM
						}
						else if(TeamState[i]==RED_TEAM)
						{
							TeamState[i]=BLUE_TEAM
						}
					}
				}
			}
			else
			{
				//PrintToChatAll("ROUND ONE DETECTED TIMER START");
				CreateTimer(20.0, start_game)
			}
			SpawnBebopDECOY();
		}
	}
	if (GetConVarInt(GameType)==2)
	{
		if(Round_started==false)
		{
			Round_started=true;
			CreateTimer(0.5, Check_burning, _,  TIMER_REPEAT);
			CreateTimer(3.5, Add_HaloETC, _,  TIMER_REPEAT);
			CreateTimer(0.5, Determine_nades, _,  TIMER_REPEAT);
			CreateTimer(0.1, Keep_high_Health, _,  TIMER_REPEAT);
			CreateTimer(1.0, Award_Bonuses, _, TIMER_REPEAT)
			CreateTimer(0.3, Custom_stuff, _, TIMER_REPEAT)
			CreateTimer(1.8, Tell_them_whos_who, _, TIMER_REPEAT)
			CreateTimer(15.0,Remove_corpse);
			CreateTimer(15.0,Spawn_OddGnome);
			CreateTimer(1.0, keep_em_survivors, _, TIMER_REPEAT)
			CreateTimer(3.0, Spawn_non_survivors, _, TIMER_REPEAT)
			CreateTimer(2.0, ScoreUpdate, _, TIMER_REPEAT)
			
			if(h_scorehandlerBoomer != INVALID_HANDLE)
			{
				KillTimer(h_scorehandlerBoomer)
				h_scorehandlerBoomer=INVALID_HANDLE;
			}
			
			h_scorehandlerBoomer=CreateTimer(25.0, ScoreUpdateBoomer, _, TIMER_REPEAT)
			for (new j = 1; j <= MaxClients; j++)
			{
				if (IsClientInGame(j)) 
				{
					ChooseClassMenu(j);
				}
			}
			
			if(Round_two == false)
			{
				CreateTimer(GetConVarFloat(Each_round_time)+9.0, MapRotation)
				if(GetConVarInt(h_BonusGames))//bonus game modes on
				{
					RandomBonusMode= GetRandomInt(1,2)
					//RandomBonusMode=1;
					if (RandomBonusMode == 1)
					{
						CreateTimer(1.0, start_gameBONUSINFECTION)//add also to gametype 1
						CreateTimer(1.0, keep_BOOMERS_infected, _, TIMER_REPEAT)
					}
					else if (RandomBonusMode == 2)//add ODDGNOME
					{
						CreateTimer(1.0, start_gameBONUSODDGNOME)//add also to gametype 1
					}
				}
				else
				{
					CreateTimer(1.0, start_gameFFA)
				}
			}
			else
			{
				CreateTimer(10.0, start_gameFFA)
			}
			SpawnBebopDECOY();	
		}
		
	}
	
}

public Action:Reactivate_jump(Handle:Timer, any:client) 
{
	if(IsClientInGame(client))
	{
		new NotJumping = (GetEntityFlags(client) & FL_ONGROUND)	
		if (NotJumping)
		{
			JumpTimer[client]=0;
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action:Reactivate_Jetpack(Handle:Timer, any:client) 
{
	if(IsClientInGame(client))
	{
		new NotJumping = (GetEntityFlags(client) & FL_ONGROUND)	
		if (NotJumping)
		{
			if(JetRefuelTimers[client] != INVALID_HANDLE)
			{
				KillTimer(JetRefuelTimers[client]);
				JetRefuelTimers[client] = INVALID_HANDLE;
			}
			IamNowFuelling[client]=0;
			PrintHintText(client, "JETPACK refuelled,hold JUMP to use...");
			JetpackFuel[client]=GetConVarInt(JetPackFuel);
		}
	}
}

public Action:ScoreUpdateBoomer(Handle:Timer) 
{
	if(GetConVarInt(h_BonusGames))
	{
		if (RandomBonusMode == 1)//INFECTION
		{
			humancounter=0;
			if(initial_stage==false) 
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)== 2 && i != clientX && TeamState[i] != INFECTED_TEAM) 
					{
						playerscore[i]++;
					}
				}
				for (new J = 1; J <= MaxClients; J++)
				{
					if (IsClientInGame(J) && !IsFakeClient(J) && GetClientTeam(J)== 2 && J != clientX) 
					{
						humancounter++;
					}
				}
			}	
		}
	}
}	

public Action:ScoreUpdate(Handle:Timer) 
{
	if (RandomBonusMode == 1)//INFECTION
	{
		if(initial_stage==false) 
		{
			if(Restarting)
			{
				//PrintToChatAll("humancounter= %i", humancounter);
				if(humancounter==0)
				{
					if(scoreset==0)
					{
						PrintToChatAll("\x04All players have been \x03infected");
						if(secondsToGo_two>GetConVarFloat(Each_round_time)-90.0)
						{
							scoreset=1;
							Check_winnerBonusBoomer();
							CreateTimer(15.0, Finish_chapter); 
							Force_spawns = true;
							First_fourMinutes = true;
							initial_stage = true;
							Round_two = false;
							
							for (new j = 1; j <= MaxClients; j++)
							{
								if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX)//
								{
									EmitSoundToClient(
									j,WINSOUND,SOUND_FROM_PLAYER,
									SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
									90, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
							}
						}
						else
						{
							for (new j = 1; j <= MaxClients; j++)
							{
								TeamState[j]=NO_TEAM;
							}
							CreateTimer(13.0, UnFreezePlayer);
							CreateTimer(3.0, Teleport_survivorsBonusesStart)
							CreateTimer(3.0, ChooseAlphaBoomer)//WAS 10
							Restarting=0;//allows infection gamemode to be played untill the round is nearly over
						}
					}
				}
			}
		}
	}
	else if (RandomBonusMode == 2)//ODDGNOME
	{
		if(initial_stage==false) 
		{	
			decl Float:lchPos[3];
			new Float:Location[3];
			new entcount = GetEntityCount();
			decl String:ModelName[128];
			for (new i=1;i<=entcount;i++)
			{
				if(IsValidEntity(i))
				{
					new AllowGlow=0;
					for (new j = 1; j <= MaxClients; j++)
					{
						if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX && iHaveChompsky[j]>0)
						{
							AllowGlow++;
							//PrintToChatAll("allowglow ++? %i", AllowGlow);
						}
					}
					
					if(AllowGlow<1)
					{
						GetEntPropString(i, Prop_Data, "m_ModelName", ModelName, 128);
						if (StrContains(ModelName, "gnome.mdl", true) != -1)
						{
							SetEntProp(i, Prop_Send, "m_iGlowType", 0)
							SetEntProp(i, Prop_Send, "m_glowColorOverride", 0);
							new RandomGlow=GetRandomInt(1,2)
							switch (RandomGlow)
							{
								case 1:
								{
									//PrintToChatAll("STREQUAL BYPASSED");
									GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
									decl color[4];
									color[0] = 0;
									color[1] = 100;
									color[2] = 80;
									color[3] = 230;					
									lchPos=Location;
									lchPos[2] += 650;					
									TE_SetupBeamPoints(lchPos, Location, g_BeamSprite, 0, 0, 0,
									2.0, 3.0, 3.0, 1, 0.5, color, 0);
									TE_SendToAll();
									TE_SetupGlowSprite(lchPos, g_GlowSprite, 1.5, 2.8, 230);
									TE_SendToAll();
									
									TE_SetupBeamRingPoint(Location, 300.0, 10.0, g_BeamSprite,
									g_HaloSprite, 0, 10, 1.2, 4.0, 0.5,
									{150, 150, 230, 230}, 80, 0);
									TE_SendToAll();
									
									if (GetVectorDistance(Boundaries, Location) >= Distance)//keeps Gnome from leaving the designated fighting area
									{
										TeleportEntity(i, GnomeLocation, NULL_VECTOR, NULL_VECTOR);  
									}	
									
								}
								case 2:
								{
									GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
									decl color[4];
									color[0] = 0;
									color[1] = 100;
									color[2] = 80;
									color[3] = 230;					
									lchPos=Location;
									lchPos[2] += 650;					
									TE_SetupBeamPoints(lchPos, Location, g_BeamSprite, 0, 0, 0,
									2.0, 3.0, 3.0, 1, 0.5, color, 0);
									TE_SendToAll();
									TE_SetupGlowSprite(lchPos, g_GlowSprite, 1.5, 2.8, 230);
									TE_SendToAll();
									
									TE_SetupBeamRingPoint(Location, 300.0, 10.0, g_BeamSprite,
									g_HaloSprite, 0, 10, 1.2, 4.0, 0.5,
									{150, 150, 230, 230}, 80, 0);
									TE_SendToAll();
									
									if (GetVectorDistance(Boundaries, Location) >= Distance)//keeps Gnome from leaving the designated fighting area
									{
										TeleportEntity(i, GnomeLocation, NULL_VECTOR, NULL_VECTOR);  
									}	
								}
							}
						}
						else
						{
							//PrintToChatAll("gnome is not picked up? jennys dirty tampons");
						}
						
						
						
					}
				}
			}
		}
	}
	else
	{
		if (GetConVarInt(GameType)==1)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i)) 
				{
					if(TeamState[i]==BLUE_TEAM)
					{
						if(playerscoreTemp[i]>0)
						{
							Full_score_blue=(playerscoreTemp[i]+Full_score_blue);
							MAX_scores[i]=Full_score_blue;
							playerscoreTemp[i]=0;
							
						}
					}
					else if(TeamState[i]==RED_TEAM)
					{
						if(playerscoreTemp[i]>0)
						{
							Full_score_red=(playerscoreTemp[i]+Full_score_red);
							MAX_scores[i]=Full_score_red;
							playerscoreTemp[i]=0;
						}
					}
				}
			}
			//PrintHintTextToAll("Points: Red Team:%i    Blue Team:%i", Full_score_red, Full_score_blue);
			if(scoreset==0)
			{
				if(Full_score_red>=GetConVarInt(MaxKills)||Full_score_blue>=GetConVarInt(MaxKills))
				{
					if(h_RoundEnd!=INVALID_HANDLE)
					{
						KillTimer(h_RoundEnd)
						h_RoundEnd=INVALID_HANDLE;
					}
					
					scoreset=1;
					Check_winner();
					CreateTimer(10.0, Finish_chapter); 
					Force_spawns = true;
					First_fourMinutes = true;
					initial_stage = true;
					Round_two = false;
					
					for (new i = 1; i <= MaxClients; i++)
					{
						EmitSoundToAll(
						WINSOUND, i,
						SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
						100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
					}
				}
				
			}
		}
		
		
		if (GetConVarInt(GameType)==2)
		{
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i)) 
				{
					
					if(scoreset==0)
					{
						if(playerscore[i]>=GetConVarInt(MaxKillsFFA))
						{
							scoreset=1;
							if(h_RoundEnd!=INVALID_HANDLE)
							{
								KillTimer(h_RoundEnd)
								h_RoundEnd=INVALID_HANDLE;
							}
							
							Check_winnerFFA();
							CreateTimer(10.0, Finish_chapter); 
							Force_spawns = true;
							First_fourMinutes = true;
							initial_stage = true;
							Round_two = false;
							
							for (new j = 1; j <= MaxClients; j++)
							{
								if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX)//
								{
									EmitSoundToClient(
									j,WINSOUND,SOUND_FROM_PLAYER,
									SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
									90, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								}
							}
							
						}
					}
				}	
				
			}
			
		}
	}
}

public Action:EventItemPickup(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	if (RandomBonusMode == 2)
	{
		decl i_UserID, i_Client, String:chompsky[16]
		
		i_UserID = GetEventInt(h_Event, "userid")
		i_Client = GetClientOfUserId(i_UserID)
		decl Float:pos[3];
		decl Float:lchPos[3];
		GetEventString(h_Event, "item", chompsky, sizeof(chompsky))
		GetClientAbsOrigin(i_Client, pos)
		
		//PrintToChatAll("%s", chompsky);
		if (StrEqual(chompsky, "gnome"))
		{
			PrintHintTextToAll("%N has taken control of GNOME CHOMPSkY", i_Client);
			
			decl color[4];
			color[0] = 100;
			color[1] = 100;
			color[2] = 80;
			color[3] = 230;					
			lchPos=pos;
			lchPos[2] += 650;					
			TE_SetupBeamPoints(lchPos, pos, g_BeamSprite, 0, 0, 0,
			2.0, 5.0, 5.0, 1, 2.0, color, 0);
			TE_SendToAll();
			TE_SetupGlowSprite(lchPos, g_GlowSprite, 1.5, 2.8, 230);
			TE_SendToAll();
			
			TE_SetupBeamRingPoint(pos, 300.0, 10.0, g_BeamSprite,
			g_HaloSprite, 0, 10, 1.2, 4.0, 0.5,
			{150, 150, 230, 230}, 80, 0);
			TE_SendToAll();
			
			iHaveChompsky[i_Client]=1;
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && i != i_Client) 
				{
					iHaveChompsky[i_Client]=0;
				}
			}
		}
	}
}






public Action:Inform_GnomeLocation(Handle:timer)
{
	if (GetConVarInt(GameType)==2)//ALSO ADD ONE ONCE TESTING HAS BEEN DONE
	{
		if (RandomBonusMode == 2)
		{
			new h;
			if(GnomeSpawned==true)
			{
				decl Main_weapon, String:s_ModelName[128]
				for (h = 1; h <= MaxClients; h++)
				{
					if (IsClientInGame(h) && !IsFakeClient(h) && h != clientX)
					{
						Main_weapon = GetEntPropEnt(h, Prop_Send, "m_hActiveWeapon");
						if (IsValidEdict(Main_weapon))
						{
							
							for (new z = 1; z <= MaxClients; z++)
							{
								if (IsClientInGame(z) && !IsFakeClient(z) && z != clientX && z != h && iHaveChompsky[z]>0 && z != h)//
								{
									PrintHintText(z, "%N has GNOME CHOMPSkY KILL THEM and take the gnome for points", h);
								}
							}
							
							SetEntProp(h, Prop_Send, "m_iGlowType", 0)
							SetEntProp(h, Prop_Send, "m_glowColorOverride", 0);
							GetEdictClassname(Main_weapon, s_ModelName, sizeof(s_ModelName)); 
							if (StrContains(s_ModelName, "gnome", false) != -1)
							{
								new randomcolor = GetRandomInt(1,2)
								if(randomcolor==1)
								{
									SetEntProp(h, Prop_Send, "m_iGlowType", 3)
									SetEntProp(h, Prop_Send, "m_glowColorOverride", 254);
								}
								else if(randomcolor==2)
								{
									SetEntProp(h, Prop_Send, "m_iGlowType", 3)
									SetEntProp(h, Prop_Send, "m_glowColorOverride", 61184);
								}
								iHaveChompsky[h]=1;
								decl Float:pos[3];
								decl Float:lchPos[3];
								
								for (new j = 1; j <= MaxClients; j++)
								{
									if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX && j != h && iHaveChompsky[j]>0)//
									{
										iHaveChompsky[j]=0;
									}
								}
								
								for (new i = 1; i <= MaxClients; i++)
								{
									if (IsClientInGame(i) && !IsFakeClient(i) && i != clientX  && iHaveChompsky[i]>0)
									{
										GetClientAbsOrigin(i, pos)
										decl color[4];
										color[0] = 0;
										color[1] = 100;
										color[2] = 80;
										color[3] = 230;					
										lchPos=pos;
										lchPos[2] += 650;					
										TE_SetupBeamPoints(lchPos, pos, g_BeamSprite, 0, 0, 0,
										2.0, 3.0, 3.0, 1, 0.5, color, 0);
										TE_SendToAll();
										TE_SetupGlowSprite(lchPos, g_GlowSprite, 1.5, 2.8, 230);
										TE_SendToAll();
										
										TE_SetupBeamRingPoint(pos, 300.0, 10.0, g_BeamSprite,
										g_HaloSprite, 0, 10, 1.2, 4.0, 0.5,
										{150, 150, 230, 230}, 80, 0);
										TE_SendToAll();
										
										playerscore[i]++;	
										
									}
								}
								
								
								
								for (new j = 1; j <= MaxClients; j++)
								{
									if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX && iHaveChompsky[j]>0)//
									{
										if(playerscore[j]>=GetConVarInt(OddGnomeLimit))//add score cvar
										{
											if(scoreset==0)
											{
												PrintToChatAll("\x03%N WON ODDGNOME!!", j);
												ClientCommand(j, "thirdpersonshoulder");
												ClientCommand(j, "c_thirdpersonshoulderoffset 0");
												ClientCommand(j, "c_thirdpersonshoulderaimdist 720");
												ClientCommand(j, "cam_ideallag 0");
												ClientCommand(j, "cam_idealdist 100");
												AttachParticleV2(j, "achieved");
												SetEntityHealth(j, 50000)
												scoreset=1;
												Check_winnerBonusGnome();
												CreateTimer(15.0, Finish_chapter); 
												Force_spawns = true;
												First_fourMinutes = true;
												initial_stage = true;
												Round_two = false;
												
												for (new u = 1; u <= MaxClients; u++)
												{
													if (IsClientInGame(u) && !IsFakeClient(u) && u != clientX)//
													{
														EmitSoundToClient(
														u,WINSOUND,SOUND_FROM_PLAYER,
														SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
														90, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
													}
												}
											}
										}
									}
								}
								
								
							}
							else
							{
								iHaveChompsky[h]=0;
							}
						}
						
					}
					
					
				}
			}
			
			
			
			
		}
	}
}



public Action:Spawn_OddGnome(Handle:timer)
{
	if (RandomBonusMode == 2)
	{
		new entcount = GetEntityCount();
		decl String:ModelName[128];
		for (new i=1;i<=entcount;i++)
		{
			if(IsValidEntity(i))
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", ModelName, 128);
				if (StrContains(ModelName, "gnome.mdl", true) != -1)
				{
					RemoveEdict(i)
				}
			}
		}
		GnomeLocation[0] = Boundaries[0];
		GnomeLocation[1] = Boundaries[1];
		GnomeLocation[2] = Boundaries[2];
		PrintHintTextToAll("Hold GNOME Chompsky for as long as you can to win the round");
		Ent = CreateEntityByName("weapon_gnome");
		DispatchSpawn(Ent);
		GnomeSpawned=true;
		TeleportEntity(Ent, GnomeLocation, NULL_VECTOR, NULL_VECTOR);  
	}
}

public Action:keep_em_survivors(Handle:timer)
{
	//PrintHintTextToAll("KEEP_EM_SURVIVORS RUNNING");f
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)!=2 && TeamState[i] != INFECTED_TEAM) 
		{
			ChangeClientTeam(i, 1)
			HaveISpawned[i]=0;
		}
	}
}

public Action:Spawn_non_survivors(Handle:timer)
{
	if(Stop_spawning==false)
	{
		//PrintToChatAll("Spawn_non_survivors RUNNING");
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsPlayerAlive(i) && !IsFakeClient(i) && HaveISpawned[i]==0) 
			{
				ExecuteTakeover(i);
				SpawnBebopFakeClient();
			}
			
		}
	}	
}

stock bool:ExecuteTakeover(client)
{
	//find a bot controlled living survivor
	new bot = TOFindBot();
	if (bot <= 0)
		return false;
	
	//PrintToChatAll("BOT HAS NOW BEEN sucefully taken over? %N", bot);
	decl String:playername[64], String:botname[64];
	
	GetClientName(client, playername, sizeof(playername));
	GetClientName(bot, botname, sizeof(botname));
	
	//change the team to spectators before the takeover
	ChangeClientTeam(client, 1);
	
	//have to do this to give control of a survivor bot
	SDKCall(L4DTakeoverSHS, bot, client);
	SDKCall(L4DTakeoverTOB, client, true);
	//PrintToChatAll("EXECTUTING TAKE OVER of bot");
	//PrintToChatAll("Player \x05%s \x01was put in control of a survivor bot (\x03%s\x01).", playername, botname);
	
	return true;
}


stock TOFindBot()
{
	
	//PrintToChatAll("EXECUTING to find bot");
	
	for (new bot = 1; bot <= MaxClients; bot++)
	{
		if (IsClientInGame(bot) &&  bot != clientX && IsFakeClient(bot) && GetClientTeam(bot) == 2)
		{
			//PrintToChatAll("Found and returning bot it = %N", bot);
			return bot;
		}
	}
	
	return 0;
}

public Action:Paint_Teams(Handle:Timer) 
{
	//PrintHintTextToAll("Paint teams running");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) 
		{
			if(TeamState[i]==RED_TEAM)
			{
				ClientTimer[i] = CreateTimer(1.0, Paint_me_red, i);
			}
			else if(TeamState[i]==BLUE_TEAM)
			{
				ClientTimer[i] = CreateTimer(1.0, Paint_me_blue, i);
			}
			
		}
	}
}


public Action:Paint_me_red(Handle:timer, any:client)
{	
	Paint_red(client);
	//PrintToChatAll("%N was painted red", client);
}

public Action:Paint_me_blue(Handle:timer, any:client)
{	
	Paint_blue(client);
	//PrintToChatAll("%N was painted blue", client);
}

public Action:allow_to_play(Handle:Timer) 
{
	if (GetConVarInt(GameType)==1)
	{
		if(initial_stage==false)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i)) 
				{
					
					if(TeamState[i]==NO_TEAM)
					{
						ChooseTeamMenu(i);
						CreateTimer(10.0, Join_random_team, i)
					}
					else
					{
						ChooseClassMenu(i);
					}
				}
			}
		}	
	}
}

public Action:keep_BOOMERS_infected(Handle:Timer) 
{
	if(initial_stage==false)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && i != clientX && !IsFakeClient(i) && TeamState[i]==INFECTED_TEAM) 
			{
				if(IsPlayerAlive(i))
				{
					ChangeClientTeam(i, 3);
				}
				else
				{
					CheatCommand (i, "z_spawn", "boomer auto");
					ChangeClientTeam(i, 3);
				}
			}
		}
	}	
}

public Action:start_gameBONUSODDGNOME(Handle:Timer) 
{
	if(RandomBonusMode==2)
	{
		PrintHintTextToAll("HOLD GNOME CHOMPSKY FOR AS LONG AS POSSIBLE TO WIN");
	}
	if(h_RoundEnd!=INVALID_HANDLE)
	{
		KillTimer(h_RoundEnd)
		h_RoundEnd=INVALID_HANDLE;
	}
	secondsToGo_two=0;
	CreateTimer(2.0,Setting_boundaries, _, TIMER_REPEAT); 
	CreateTimer(13.0, UnFreezePlayer);
	CreateTimer(3.0, Teleport_survivorsFFA)
	h_RoundEnd = CreateTimer(1.0, End_round, _,TIMER_REPEAT)
	
	Force_spawns = false;
	initial_stage = false;
	
	if(Round_two == false)
	{
		Round_two = true;
		First_fourMinutes = false;
	}
}

public Action:start_gameBONUSINFECTION(Handle:Timer) 
{
	if (RandomBonusMode == 1)
	{
		if(h_RoundEnd!=INVALID_HANDLE)
		{
			KillTimer(h_RoundEnd)
			h_RoundEnd=INVALID_HANDLE;
		}
		secondsToGo_two=0;
		CreateTimer(2.0,Setting_boundaries, _, TIMER_REPEAT);
		CreateTimer(13.0, UnFreezePlayer);
		CreateTimer(3.0, Teleport_survivorsBonusesStart)
		CreateTimer(10.0, ChooseAlphaBoomer)
		h_RoundEnd = CreateTimer(1.0, End_round, _,TIMER_REPEAT)
		
		Force_spawns = false;
		initial_stage = false;
		
		if(Round_two == false)
		{
			Round_two = true;
			First_fourMinutes = false;
		}
	}
}


public Action:start_gameFFA(Handle:Timer) 
{
	if(h_RoundEnd!=INVALID_HANDLE)
	{
		KillTimer(h_RoundEnd)
		h_RoundEnd=INVALID_HANDLE;
	}
	secondsToGo_two=0;
	CreateTimer(2.0,Setting_boundaries, _, TIMER_REPEAT);
	CreateTimer(13.0, UnFreezePlayer);
	CreateTimer(3.0, Teleport_survivorsFFAStart)
	CreateTimer(10.0, Teleport_survivorsFFA)
	h_RoundEnd = CreateTimer(1.0, End_round, _,TIMER_REPEAT)
	
	Force_spawns = false;
	initial_stage = false;
	
	if(Round_two == false)
	{
		PrintHintTextToAll("Free For All ROUND 2");
		Round_two = true;
		First_fourMinutes = false;
	}
	else 
	{
		CreateTimer(GetConVarFloat(Each_round_time)/2, Tier_two)//increase to 480 after testing per round(depending on the outcome)
		PrintHintTextToAll("Free For All ROUND 1");
	}
	
}

public Action:start_game(Handle:Timer) 
{
	if(h_RoundEnd!=INVALID_HANDLE)
	{
		KillTimer(h_RoundEnd)
		h_RoundEnd=INVALID_HANDLE;
	}
	secondsToGo_two=0;
	CreateTimer(50.0, Sort_teams_Balance, _, TIMER_REPEAT)
	CreateTimer(2.0,Setting_boundaries, _, TIMER_REPEAT);
	CreateTimer(13.0, UnFreezePlayer);
	CreateTimer(3.0, Teleport_survivors)
	CreateTimer(5.0, Teleport_survivors)
	CreateTimer(7.0, Teleport_survivors)
	h_RoundEnd = CreateTimer(1.0, End_round, _,TIMER_REPEAT)
	Force_spawns = false;
	initial_stage = false;
	if(Round_two == false)
	{
		PrintHintTextToAll("Team Deathmatch ROUND 2");
		Round_two = true;
		First_fourMinutes = false;
	}
	else 
	{
		CreateTimer(GetConVarFloat(Each_round_time)/2, Tier_two)//increase to 480 after testing per round(depending on the outcome)
		PrintHintTextToAll("Team Deathmatch ROUND 1");
	}
	
}

public Action:Join_random_team(Handle:Timer, any:client) //used for people that join the game halfway through and dont choose a team
{
	if(IsClientInGame(client))
	{
		if(TeamState[client]==NO_TEAM)
		{
			new random_team=GetRandomInt(1,2)
			if(random_team==1)
			{
				PrintHintText(client, "Team DEATHMATCH, Fight against the RED TEAM");
				TeamState[client]=BLUE_TEAM
			}
			else
			{
				TeamState[client]=RED_TEAM
				PrintHintText(client, "Team DEATHMATCH, Fight against the BLUE TEAM");
			}
		}
	}
	
}

public bool:TraceRayDontHitSelfAndSurvivor(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}


public Action:Teleport_survivorsFFA(Handle:Timer) 
{
	//PrintToChatAll("Random weapon awarded now?");
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && i != clientX && !IsFakeClient(i)) 
		{
			//if(WeaponsGiven[i]==0)
			//{
			new random_CLASS=GetRandomInt(0,3)
			if(random_CLASS==0)
			{
				SurvivorClass[i]=ASSAULT
			}
			if(random_CLASS==1)
			{
				SurvivorClass[i]=SNIPER	
			}
			if(random_CLASS==2)
			{
				SurvivorClass[i]=SHOTGUN	
			}
			if(random_CLASS==3)
			{
				SurvivorClass[i]=HEAVYGUN	
			}
			//}
		}
		
	}
}


public Action:Random_weapon_New_Player(Handle:Timer, any:client) 
{
	//PrintToChatAll("Choosing random class for %N", client);
	if(initial_stage==false) 
	{
		if (IsClientInGame(client) && client != clientX && !IsFakeClient(client)) 
		{
			//PrintToChatAll("%N bypassed weapons given and primary given", client);
			new random_CLASS=GetRandomInt(0,4)
			if(random_CLASS==0)
			{
				SurvivorClass[client]=ASSAULT	
			}
			if(random_CLASS==1)
			{
				SurvivorClass[client]=SNIPER	
			}
			if(random_CLASS==2)
			{
				SurvivorClass[client]=MEDIC	
			}
			if(random_CLASS==3)
			{
				SurvivorClass[client]=SHOTGUN	
			}
			if(random_CLASS==4)
			{
				SurvivorClass[client]=HEAVYGUN	
			}
		}
	}
}




public Action:Teleport_survivorsFFAStart(Handle:Timer) 
{
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	Team_chosen = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && i != clientX && !IsFakeClient(i)) 
		{
			SetEntDataFloat(i, LagMovement, 0.0, true);
			random_teleport++;
			
			if(random_teleport==1)
			{
				TeleportEntity(i, Teleport_one, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==2)
			{
				TeleportEntity(i, Teleport_two, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==3)
			{
				TeleportEntity(i, Teleport_three, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==4)
			{
				TeleportEntity(i, Teleport_four, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==5)
			{
				TeleportEntity(i, Teleport_five, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==6)
			{
				TeleportEntity(i, Teleport_six, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==7)
			{
				TeleportEntity(i, Teleport_seven, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==8)
			{
				TeleportEntity(i, Teleport_eight, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==9)
			{
				TeleportEntity(i, Teleport_nine, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==10)
			{
				TeleportEntity(i, Teleport_ten, NULL_VECTOR, NULL_VECTOR);
				random_teleport=0;				
			}			
			
			
		}
	}
}


public Action:ChooseAlphaBoomer(Handle:Timer) 
{
	if (RandomBonusMode == 1)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && i != clientX && !IsFakeClient(i)) 
			{
				AlphaBoomer[i]=0;
			}
			
		}
		PrintHintTextToAll("INFECTION, survive the longest without being vomited on to Win");
		new counter = GetRandomPlayer();
		if (counter != -1)
		{
			ForcePlayerSuicide(counter);	
			TeamState[counter]=INFECTED_TEAM
			TeleportEntity(counter, Blue_Teleport, NULL_VECTOR, NULL_VECTOR);
			AlphaBoomer[counter]=1;
			PrintToChatAll("\x03%N \x04has become the \x03ALPHA \x04BOOMER", counter);
		}
	}
}


public Action:Teleport_survivorsBonusesStart(Handle:Timer) 
{
	
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	Team_chosen = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && i != clientX && !IsFakeClient(i)) 
		{
			SetEntDataFloat(i, LagMovement, 0.0, true);
			random_teleport++;
			
			if(random_teleport==1)
			{
				TeleportEntity(i, Teleport_one, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==2)
			{
				TeleportEntity(i, Teleport_two, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==3)
			{
				TeleportEntity(i, Teleport_three, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==4)
			{
				TeleportEntity(i, Teleport_four, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==5)
			{
				TeleportEntity(i, Teleport_five, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==6)
			{
				TeleportEntity(i, Teleport_six, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==7)
			{
				TeleportEntity(i, Teleport_seven, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==8)
			{
				TeleportEntity(i, Teleport_eight, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==9)
			{
				TeleportEntity(i, Teleport_nine, NULL_VECTOR, NULL_VECTOR);	
			}
			if(random_teleport==10)
			{
				TeleportEntity(i, Teleport_ten, NULL_VECTOR, NULL_VECTOR);
				random_teleport=0;				
			}			
			
			
		}
	}
}

public Action:Teleport_survivors(Handle:Timer) 
{
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	Team_chosen = false;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && i != clientX && !IsFakeClient(i)) 
		{
			
			SetEntDataFloat(i, LagMovement, 0.0, true);
			if(TeamState[i]==NO_TEAM)
			{
				new random_team=GetRandomInt(1,2)
				if(random_team==1)
				{
					TeamState[i]=BLUE_TEAM
				}
				else
				{
					TeamState[i]=RED_TEAM
				}
				
				new random_CLASS=GetRandomInt(0,4)
				
				if(random_CLASS==0)
				{
					SurvivorClass[i]=ASSAULT	
				}
				if(random_CLASS==1)
				{
					SurvivorClass[i]=SNIPER	
				}
				if(random_CLASS==2)
				{
					SurvivorClass[i]=MEDIC	
				}
				if(random_CLASS==3)
				{
					SurvivorClass[i]=SHOTGUN	
				}
				if(random_CLASS==4)
				{
					SurvivorClass[i]=HEAVYGUN	
				}
				
				PrintHintText(i, "Random Class and team chosen");
			}
			
		}
	}
	
	for (new j = 1; j <= MaxClients; j++)
	{
		if (IsClientInGame(j) && IsPlayerAlive(j) && !IsFakeClient(j)) 
		{
			if(TeamState[j]==RED_TEAM)
			{
				PrintHintText(j, "Round starting, Fight against the BLUE TEAM");
				TeleportEntity(j, Red_Teleport, NULL_VECTOR, NULL_VECTOR);	
			}
			else if(TeamState[j]==BLUE_TEAM)
			{
				PrintHintText(j, "Round starting, Fight against the RED TEAM");
				TeleportEntity(j, Blue_Teleport, NULL_VECTOR, NULL_VECTOR);		
			}
			
		}
	}
}
public Action:UnFreezePlayer(Handle:timer)
{
	Restarting=1;
	Stop_guns = false;
	Team_chosen = true;
	for (new j = 1; j <= MaxClients; j++)
	{
		if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX) 
		{
			LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
			SetEntDataFloat(j, LagMovement, 1.0, true);
		}
	}
	
}  

public Action:DisPlayPanel(Handle:timer)
{
	if(initial_stage==false)
	{
		if (RandomBonusMode == 0)
		{
			new randomMessage = GetRandomInt(1,3)
			if(randomMessage==1)
			{
				PrintToChatAll("\x04Press \x03TAB \x04to see scores"); //makes sure teams arent unbalanced
			}
			
			else if(randomMessage==2)
			{
				PrintToChatAll("\x04Press\x03 SHIFT(WALK)\x04 to change \x03WEAPONS & \x04ITEMS");
			}
			
			else if(randomMessage==3)
			{
				if (GetConVarBool(JetPacks))
				{
					PrintToChatAll("\x04Hold\x03 SPACE(JUMP)\x04 to use your \x03JETPACK");
				}
			}
		}
		else if (RandomBonusMode == 1)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i)) 
				{
					new randomMessage = GetRandomInt(1,4)
					if(randomMessage==1)
					{
						if(GetClientTeam(i)==3)
						{
							PrintToChat(i, "\x04Press \x03TAB \x04to see INFECTION scores"); //makes sure teams arent unbalanced
						}
						if(GetClientTeam(i)==2)
						{
							PrintToChat(i, "\x04Press \x03TAB \x04to see INFECTION scores"); 
						}
					}
					
					else if(randomMessage==2)
					{
						if(GetClientTeam(i)==3)
						{
							PrintToChat(i, "\x04Vomit\x03 on\x04 survivors to \x03INFECT THEM");
						}
						if(GetClientTeam(i)==2)
						{
							PrintToChat(i, "\x04Avoid \x03boomers'S VOMIT\x04at all costs, melee \x03BOOMERS\x04 if they get too close");
						}
					}
					else if(randomMessage==3)
					{
						if(GetClientTeam(i)==3)
						{
							PrintToChat(i, "\x04Vomit\x03 on\x04 survivors to \x03INFECT THEM");
						}
						if(GetClientTeam(i)==2)
						{
							PrintToChat(i, "\x03MELEE Boomers \x04 without being vomited on stay \x03ALIVE");
						}
					}
					else if(randomMessage==4)
					{
						if(GetClientTeam(i)==3)
						{
							PrintToChat(i, "\x04Vomit on a \x03survivor \x04 before they \x03melee you");
						}
						if(GetClientTeam(i)==2)
						{
							PrintToChat(i, "\x03AVOID \x04 the \x03ALPHA BOOMER\x04  at all \x03costs,\x04 hes much faster");
						}
					}
				}
			}
		}
		else if (RandomBonusMode == 2)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i)) 
				{
					new randomMessage = GetRandomInt(1,2)
					if(randomMessage==1)
					{
						if(GetClientTeam(i)==2)
						{
							PrintToChat(i, "\x04Hold Gnome\x03 CHOMPSKY  \x04 to gain points"); 
						}
					}
					
					else if(randomMessage==2)
					{
						if(GetClientTeam(i)==2)
						{
							PrintToChat(i, "\x04First player to \x03 %i\x04 points WINS",GetConVarInt(OddGnomeLimit));
						}
					}
					
				}
			}
		}
	}
	
}
public Action:Sort_teams_Balance(Handle:timer)
{
	
	//PrintToChatAll("Sorting players out"); //makes sure teams arent unbalanced
	new reds;
	new blues;
	if(initial_stage==false)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i)) 
			{
				if(TeamState[i]==BLUE_TEAM)
				{
					blues++;
				}
				if(TeamState[i]==RED_TEAM)
				{
					reds++;
				}
				
			}
		}
		//PrintToChatAll("there are %i red players", reds);
		//PrintToChatAll("there are %i blue players", blues);
		
		if(reds>blues+1)//(reds>blues+1)
		{
			new counter = GetRandomPlayerRed();
			if (counter != -1)
			{
				TeamState[counter]=BLUE_TEAM	
				TeleportEntity(counter, Blue_Teleport, NULL_VECTOR, NULL_VECTOR);
				PrintToChatAll("\x04Autobalancing teams", counter);
			}
		}
		if(blues>reds+1)//(blues>reds+1)
		{
			new counter = GetRandomPlayerBlue();
			if (counter != -1)
			{
				TeamState[counter]=RED_TEAM
				TeleportEntity(counter, Red_Teleport, NULL_VECTOR, NULL_VECTOR);
				PrintToChatAll("\x04Autobalancing teams", counter);
			}
		}
		
	}
	
}  


public Action:Award_Bonuses(Handle:timer)
{
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(DoIHaveMyBonus[i]>0)
		{	
			if(KillBonuses[i]==3)
			{
				PrintHintText(i, "3 Kill spree received laser sights");
				CheatCommand(i, "upgrade_add", "LASER_SIGHT");
				DoIHaveMyBonus[i]=0;
				
			}
			
			if(KillBonuses[i]==5)
			{
				
				AllowHighJump[i]=1;
				CreateTimer(120.0, Disable_Jump_boots, i)//gives player higher jump
				DoIHaveMyBonus[i]=0;
				PrintHintText(i, "5 Kill spree received Jump Boots");
				//ADD JUMP BOOTS HERE
				PrintToChatAll("\x04| %N |  \x03 5 Killing Spree!", i);
				
			}
			
			if(KillBonuses[i]==7)
			{
				DoIHaveMyBonus[i]=0;
				
				PrintHintText(i, "5 Kill spree received Jump Boots");
				
			}
			
			
			if(KillBonuses[i]==10)
			{	
				//add something here
				DoIHaveMyBonus[i]=0;
				
				PrintToChatAll("\x04| %N |  \x03RAMPAGE! 10 kill spree", i);
			}
			
		}
		
	}
	
	
}
public Action:Custom_stuff(Handle:timer)
{
	if (GetConVarInt(GameType)==1)	
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if(CustomMagic[i]>0)
			{	
				
				//PrintToChatAll("custom maps bypassed");
				if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i)) 
				{
					if(TeamState[i]==RED_TEAM)
					{
						TeleportEntity(i, Red_Teleport, NULL_VECTOR, NULL_VECTOR);		
						CustomMagic[i]=0;
					}
					else if(TeamState[i]==BLUE_TEAM)
					{
						TeleportEntity(i, Blue_Teleport, NULL_VECTOR, NULL_VECTOR);		
						CustomMagic[i]=0;
					}
					
				}
			}
		}
	}
	if (GetConVarInt(GameType)==2)
		
	for (new i = 1; i <= MaxClients; i++)
	{
		if(CustomMagic[i]>0)
		{	
			
			//PrintToChatAll("custom maps bypassed");
			if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i)) 
			{
				new random_spawn;
				random_spawn=GetRandomInt(1,10)//increase when more spawns are available
				
				if(random_spawn==1)
				{
					TeleportEntity(i, Teleport_one, NULL_VECTOR, NULL_VECTOR);	
					CustomMagic[i]=0;
				}
				if(random_spawn==2)
				{
					TeleportEntity(i, Teleport_two, NULL_VECTOR, NULL_VECTOR);	
					CustomMagic[i]=0;
				}
				if(random_spawn==3)
				{
					TeleportEntity(i, Teleport_three, NULL_VECTOR, NULL_VECTOR);	
					CustomMagic[i]=0;
				}
				if(random_spawn==4)
				{
					TeleportEntity(i, Teleport_four, NULL_VECTOR, NULL_VECTOR);	
					CustomMagic[i]=0;
				}
				if(random_spawn==5)
				{
					TeleportEntity(i, Teleport_five, NULL_VECTOR, NULL_VECTOR);
					CustomMagic[i]=0;
					
				}
				if(random_spawn==6)
				{
					TeleportEntity(i, Teleport_six, NULL_VECTOR, NULL_VECTOR);	
					CustomMagic[i]=0;
				}
				if(random_spawn==7)
				{
					TeleportEntity(i, Teleport_seven, NULL_VECTOR, NULL_VECTOR);	
					CustomMagic[i]=0;
				}
				if(random_spawn==8)
				{
					TeleportEntity(i, Teleport_eight, NULL_VECTOR, NULL_VECTOR);
					CustomMagic[i]=0;							
				}
				if(random_spawn==9)
				{
					TeleportEntity(i, Teleport_nine, NULL_VECTOR, NULL_VECTOR);
					CustomMagic[i]=0;
				}
				if(random_spawn==10)
				{
					TeleportEntity(i, Teleport_ten, NULL_VECTOR, NULL_VECTOR);
					CustomMagic[i]=0;
				}	
				
			}
		}
	}
}	


public Action:Tell_them_whos_who(Handle:timer)
{
	//PrintToChatAll("Sorting players out"); //makes sure teams arent unbalanced
	
	if(initial_stage==false)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			GetTracePosition(i);
			CreateLaserEffect(i, 0, 0, 0, 0, 1.0, 0.5);//0 on 3 was 200
		}	
	}
}

public GetTracePosition(client)
{
	decl Float:myAng[3];
	if(IsClientInGame(client))
	{
		GetClientEyePosition(client, myPos);
		GetClientEyeAngles(client, myAng);
		
		new Handle:trace = TR_TraceRayFilterEx(myPos, myAng, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndSurvivor, client);
		
		if(TR_DidHit(trace))
			//	PrintToChatAll("was this person hit? %N",client);
		TR_GetEndPosition(trsPos, trace);
		CloseHandle(trace);
		Tell_them_Status(trsPos, client);
		for(new i = 0; i < 3; i++)
			trsPos002[i] = trsPos[i];
	}
}


public CreateLaserEffect(client, colRed, colGre, colBlu, alpha, Float:width, Float:duration)
{
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		decl Float:tmpVec[3];
		SubtractVectors(myPos, trsPos, tmpVec);
		NormalizeVector(tmpVec, tmpVec);
		ScaleVector(tmpVec, 36.0);
		SubtractVectors(myPos, tmpVec, trsPos);
		
		decl color[4];
		color[0] = colRed; 
		color[1] = colGre;
		color[2] = colBlu;
		color[3] = alpha;
		TE_SetupBeamPoints(myPos, trsPos002, g_sprite, 0, 0, 0, 0.06, width, 0.08, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	
}

public Tell_them_Status(Float:pos[3], client)
{	
	if (GetConVarInt(GameType)==1)
	{
		decl Float:f_EntOrigin[3]//, String:s_ModelName[64]
		//new iMaxEnts = GetMaxEntities();
		
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i)!=1 && i != client)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", f_EntOrigin)
				GetClientEyePosition(i, f_EntOrigin);
				
				if (GetVectorDistance(pos, f_EntOrigin) >1 && GetVectorDistance(pos, f_EntOrigin) <=50 )
				{
					if(TeamState[i]==TeamState[client])
					{
						PrintHintText(client, "Name:%N  Status:  FRIEND", i)
						DisableTheHud[client] = CreateTimer(3.0, DisableHud, client)
					}
					if(TeamState[i]!=TeamState[client])
					{
						PrintHintText(client, "Name:%N  Status: ENEMY", i)
						DisableTheHud[client] = CreateTimer(3.0, DisableHud, client)
						
					}
				}
				
			}
			
		}
	}
	if (GetConVarInt(GameType)==2)
	{
		decl Float:f_EntOrigin[3]//, String:s_ModelName[64]
		//new iMaxEnts = GetMaxEntities();
		
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i)!=1 && i != client)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", f_EntOrigin)
				GetClientEyePosition(i, f_EntOrigin);
				
				if (GetVectorDistance(pos, f_EntOrigin) >1 && GetVectorDistance(pos, f_EntOrigin) <=50 )
				{
					PrintHintText(client, "Name:%N  Status: ENEMY", i)
					DisableTheHud[client] = CreateTimer(3.0, DisableHud, client)
					
				}
			}
			
		}
		
	}
	
}

public Action:DisableHud(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		PrintHintText(client, "-")
	}
}

public Action:Sort_teams_out(Handle:timer)
{
	//PrintToChatAll("Sorting players out"); //makes sure teams arent unbalanced
	new reds;
	new blues;
	if(initial_stage==false)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i)) 
			{
				if(TeamState[i]==BLUE_TEAM)
				{
					blues++;
				}
				if(TeamState[i]==RED_TEAM)
				{
					reds++;
				}
				
			}
		}
		//PrintToChatAll("there are %i red players", reds);
		//PrintToChatAll("there are %i blue players", blues);
		
		if(reds>blues+1)//(reds>blues+1)
		{
			new counter = GetRandomPlayerRed();
			if (counter != -1)
			{
				TeamState[counter]=BLUE_TEAM	
				TeleportEntity(counter, Blue_Teleport, NULL_VECTOR, NULL_VECTOR);
				PrintToChatAll("\x04Autobalancing teams", counter);
			}
		}
		if(blues>reds+1)//(blues>reds+1)
		{
			new counter = GetRandomPlayerBlue();
			if (counter != -1)
			{
				TeamState[counter]=RED_TEAM
				TeleportEntity(counter, Red_Teleport, NULL_VECTOR, NULL_VECTOR);
				PrintToChatAll("\x04Autobalancing teams", counter);
			}
		}
		
	}
	
} 

GetRandomPlayer()
{
	new clients[MaxClients+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
	clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}     

GetRandomPlayerRed()
{
	new clients[MaxClients+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && TeamState[i]==RED_TEAM && IsPlayerAlive(i))
	clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}    

GetRandomPlayerBlue()
{
	new clients[MaxClients+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && TeamState[i]==BLUE_TEAM && IsPlayerAlive(i))
	clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}



public Action:Setting_boundaries(Handle:timer)
{
	
	if (GetConVarInt(GameType)==1)
	{
		decl Float:f_EntOrigin[3]
		if(initial_stage==false)
		{
			for (new j = 1; j <= MaxClients; j++)
			{
				if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX) 
				{
					GetEntPropVector(j, Prop_Send, "m_vecOrigin", f_EntOrigin)
					GetClientAbsOrigin(j, f_EntOrigin)
					if (GetVectorDistance(Boundaries, f_EntOrigin) >= Distance)//keeps players from leaving the designated fighting area
					{		
						if(initial_stage==false)
						{
							PrintHintText(j,"You were teleported back into the fighting zone")
						}
						new random_spawn;
						random_spawn=GetRandomInt(1,10)//increase when more spawns are available
						
						if(random_spawn==1)
						{
							
							TeleportEntity(j, Teleport_one, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==2)
						{
							TeleportEntity(j, Teleport_two, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==3)
						{
							TeleportEntity(j, Teleport_three, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==4)
						{
							TeleportEntity(j, Teleport_four, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==5)
						{
							TeleportEntity(j, Teleport_five, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==6)
						{
							TeleportEntity(j, Teleport_six, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==7)
						{
							TeleportEntity(j, Teleport_seven, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==8)
						{
							TeleportEntity(j, Teleport_eight, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==9)
						{
							TeleportEntity(j, Teleport_nine, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==10)
						{
							TeleportEntity(j, Teleport_ten, NULL_VECTOR, NULL_VECTOR);	
						}			
						
					}
				}
			}
		}
	}
	if (GetConVarInt(GameType)==2)
	{
		decl Float:f_EntOrigin[3]
		if(initial_stage==false)
		{
			for (new j = 1; j <= MaxClients; j++)
			{
				if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX) 
				{
					GetEntPropVector(j, Prop_Send, "m_vecOrigin", f_EntOrigin)
					GetClientAbsOrigin(j, f_EntOrigin)
					if (GetVectorDistance(Boundaries, f_EntOrigin) >= Distance)//keeps players from leaving the designated fighting area
					{
						if(initial_stage==false)
						{
							PrintHintText(j,"You were teleported back into the fighting zone")
						}
						new random_spawn;
						random_spawn=GetRandomInt(1,10)//increase when more spawns are available
						
						if(random_spawn==1)
						{
							
							TeleportEntity(j, Teleport_one, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==2)
						{
							TeleportEntity(j, Teleport_two, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==3)
						{
							TeleportEntity(j, Teleport_three, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==4)
						{
							TeleportEntity(j, Teleport_four, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==5)
						{
							TeleportEntity(j, Teleport_five, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==6)
						{
							TeleportEntity(j, Teleport_six, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==7)
						{
							TeleportEntity(j, Teleport_seven, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==8)
						{
							TeleportEntity(j, Teleport_eight, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==9)
						{
							TeleportEntity(j, Teleport_nine, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==10)
						{
							TeleportEntity(j, Teleport_ten, NULL_VECTOR, NULL_VECTOR);	
						}				
					}
				}
			}
		}
		
		
		
	}
	
}  

public Action:Team_display(Handle:timer)
{
	
	if(initial_stage==false)
	{
		for (new j = 1; j <= MaxClients; j++)
		{
			if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX) 
			{
				
				if(TeamState[j]==BLUE_TEAM)
				{
					//	PrintCenterTextAll("I AM IN THE BLUE TEAM")	
				}
				if(TeamState[j]==RED_TEAM)
				{
					//	PrintCenterTextAll("I AM IN THE RED TEAM")	
				}			
				
				
			}
		}
	}
	
}  




public Action:Tier_two(Handle:Timer) 
{
	PrintHintTextToAll("TIER 2 WEAPONS ENABLED, press SHIFT(Walk) to choose them");
	First_fourMinutes = false;
}

public Action:Finish_chapter(Handle:Timer) 
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			ForcePlayerSuicide(i);
		}
	}
}

public Action:Play_End_music(Handle:Timer) 
{
	EmitSoundToAll(WINSOUND);
	//currently repeating more than once ftl
}

public Action:End_round(Handle:Timer) 
{
	if (RandomBonusMode == 1)
	{
		secondsToGo_two ++;
		//PrintHintTextToAll("Is the timer working ? %i", secondsToGo_two);
		if (secondsToGo_two == GetConVarFloat(Each_round_time))
		{
			Stop_spawning=true;
			if(h_RoundEnd!=INVALID_HANDLE)
			{
				KillTimer(h_RoundEnd)
				h_RoundEnd=INVALID_HANDLE;
			}
			CreateTimer(0.5, Play_End_music)
			Check_winnerBonusBoomer();
			CreateTimer(8.0, Finish_chapter)
			Force_spawns = true;
			First_fourMinutes = true;
			initial_stage = true;
			Round_two = false;
			
		}
	}
	else if (RandomBonusMode == 2)
	{
		secondsToGo_two ++;
		//PrintHintTextToAll("Is the timer working ? %i", secondsToGo_two);
		
		if (secondsToGo_two == GetConVarFloat(Each_round_time))
		{
			Stop_spawning=true;
			if(h_RoundEnd!=INVALID_HANDLE)
			{
				KillTimer(h_RoundEnd)
				h_RoundEnd=INVALID_HANDLE;
			}
			CreateTimer(0.5, Play_End_music)
			//PrintToChatAll("\x03%N WON ODDGNOME!!", j);
			scoreset=1;
			Check_winnerBonusGnome();
			CreateTimer(15.0, Finish_chapter); 
			Force_spawns = true;
			First_fourMinutes = true;
			initial_stage = true;
			Round_two = false;
			
		}
	}
	else
	{
		if (GetConVarInt(GameType)==1)
		{
			secondsToGo_two ++;
			//PrintHintTextToAll("Is the timer working ? %i", secondsToGo_two);
			
			if (secondsToGo_two == GetConVarFloat(Each_round_time))
			{
				Stop_spawning=true;
				if(h_RoundEnd!=INVALID_HANDLE)
				{
					KillTimer(h_RoundEnd)
					h_RoundEnd=INVALID_HANDLE;
				}
				CreateTimer(0.5, Play_End_music)
				Check_winner();
				CreateTimer(8.0, Finish_chapter)
				Force_spawns = true;
				First_fourMinutes = true;
				initial_stage = true;
				Round_two = false;
			}
		}
		else if (GetConVarInt(GameType)==2)
		{
			secondsToGo_two ++;
			//PrintHintTextToAll("Is the timer working ? %i", secondsToGo_two);
			if (secondsToGo_two == GetConVarFloat(Each_round_time))
			{
				Stop_spawning=true;
				if(h_RoundEnd!=INVALID_HANDLE)
				{
					KillTimer(h_RoundEnd)
					h_RoundEnd=INVALID_HANDLE;
				}
				
				
				CreateTimer(0.5, Play_End_music)
				
				Check_winnerFFA();
				CreateTimer(8.0, Finish_chapter)
				Force_spawns = true;
				First_fourMinutes = true;
				initial_stage = true;
				Round_two = false;
			}
		}
	}
}

Check_winnerBonusBoomer()
{
	decl players[MAXPLAYERS][2], i 
	
	new playercount 
	
	for(i = 1; i <= MaxClients; i++) 
	{ 
		if(IsClientInGame(i) && !IsFakeClient(i))
		{ 
			players[playercount][0] = i 
			players[playercount++][1] = playerscore[i] 
			primaryChosen[i]=0;
			SecondaryChosen[i]=0;
		} 
	} 
	SortCustom2D(players,playercount,SortPlayerPoints) 
	for(i = 0; i < playercount; i++) 
	{ 
		PrintToChatAll("\x04Rank \x03#%d: %N \x04with \x03%d \x04Points",i+1,players[i][0],players[i][1]) 
	} 
} 

Check_winnerBonusGnome()
{
	decl players[MAXPLAYERS][2], i 
	new playercount 
	for(i = 1; i <= MaxClients; i++) 
	{ 
		if(IsClientInGame(i) && !IsFakeClient(i))
		{ 
			players[playercount][0] = i 
			players[playercount++][1] = playerscore[i] 
			primaryChosen[i]=0;
			SecondaryChosen[i]=0;
		} 
	} 
	
	SortCustom2D(players,playercount,SortPlayerPoints) 
	
	for(i = 0; i < playercount; i++) 
	{ 
		PrintToChatAll("\x04Rank \x03#%d: %N \x04with \x03%d \x04Points",i+1,players[i][0],players[i][1]) 
	} 
} 

Check_winnerFFA()
{
	decl players[MAXPLAYERS][2], i 
	
	new playercount 
	
	for(i = 1; i <= MaxClients; i++) 
	{ 
		if(IsClientInGame(i) && !IsFakeClient(i))
		{ 
			players[playercount][0] = i 
			players[playercount++][1] = playerscore[i] 
			primaryChosen[i]=0;
			SecondaryChosen[i]=0;
		} 
	} 
	
	SortCustom2D(players,playercount,SortPlayerPoints) //UNTESTED
	
	for(i = 0; i < playercount; i++) 
	{ 
		PrintToChatAll("\x04Rank \x03#%d: %N \x04with \x03%d \x04Kills",i+1,players[i][0],players[i][1]) 
	} 
} 

public SortPlayerPoints(elem1[],elem2[],const array[][],Handle:hndl) 
{ 
	if(elem1[1] > elem2[1]) { 
		return -1 
	} 
	else if(elem1[1] < elem2[1]) { 
		return 1 
	} 
	
	return 0 
}  


Check_winner()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) 
		{
			if(TeamState[i]==BLUE_TEAM)
			{
				if(playerscoreTemp[i]>0)
				{
					primaryChosen[i]=0;
					SecondaryChosen[i]=0;
					Full_score_blue=(playerscoreTemp[i]+Full_score_blue);
					MAX_scores[i]=Full_score_blue;
					playerscoreTemp[i]=0;
					
				}
			}
			else if(TeamState[i]==RED_TEAM)
			{
				if(playerscoreTemp[i]>0)
				{
					Full_score_red=(playerscoreTemp[i]+Full_score_red);
					MAX_scores[i]=Full_score_red;
					playerscoreTemp[i]=0;
				}
			}
		}
	}
	PrintToChatAll("\x04Points: \x03Red Team:  \x04%i   \x03Blue Team: \x04%i", Full_score_red, Full_score_blue);
	if(Full_score_blue>Full_score_red)
	{
		PrintToChatAll("\x04Blue team \x03WINS");
		for (new j = 1; j <= MaxClients; j++)
		{
			if (IsClientInGame(j) && !IsFakeClient(j))
			{
				ClientCommand(j, "thirdpersonshoulder");
				ClientCommand(j, "c_thirdpersonshoulderoffset 0");
				ClientCommand(j, "c_thirdpersonshoulderaimdist 720");
				ClientCommand(j, "cam_ideallag 0");
				ClientCommand(j, "cam_idealdist 100");
				
				if (IsClientInGame(j) && TeamState[j]==BLUE_TEAM ) 
				{
					AttachParticleV2(j, "achieved");
					SetEntityHealth(j, 50000)
				}
				
			}	
		}
	}
	if(Full_score_blue<Full_score_red)
	{
		PrintToChatAll("\x04Red team \x03WINS");
		
		for (new j = 1; j <= MaxClients; j++)
		{
			if (IsClientInGame(j) && !IsFakeClient(j))
			{
				ClientCommand(j, "thirdpersonshoulder");
				ClientCommand(j, "c_thirdpersonshoulderoffset 0");
				ClientCommand(j, "c_thirdpersonshoulderaimdist 720");
				ClientCommand(j, "cam_ideallag 0");
				ClientCommand(j, "cam_idealdist 100");
				if (TeamState[j]==RED_TEAM ) 
				{
					AttachParticleV2(j, "achieved");
					SetEntityHealth(j, 50000)
				}
				
			}
		}
	}
	if(Full_score_blue==Full_score_red)
	{
		PrintToChatAll("\x04No team Won!?, its a \x03draw");
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				ClientCommand(i, "thirdpersonshoulder");
				ClientCommand(i, "c_thirdpersonshoulderoffset 0");
				ClientCommand(i, "c_thirdpersonshoulderaimdist 720");
				ClientCommand(i, "cam_ideallag 0");
				ClientCommand(i, "cam_idealdist 100");
				
				if (TeamState[i] != NO_TEAM) 
				{
					AttachParticleV2(i, "achieved");
				}
				
			}
		}
	}
}


public AttachParticle(i_Ent, String:s_Effect[], Float:f_Origin[3])
{
	decl i_Particle, String:s_TargetName[32]
	
	i_Particle = CreateEntityByName("info_particle_system")
	
	if (IsValidEdict(i_Particle))
	{
		if (StrEqual(s_Effect, "weapon_pipebomb_fuse"))
		{
			f_Origin[0] += 0.3
			f_Origin[1] += 1.7
			f_Origin[2] += 7.5
		}
		TeleportEntity(i_Particle, f_Origin, NULL_VECTOR, NULL_VECTOR)
		FormatEx(s_TargetName, sizeof(s_TargetName), "particle%d", i_Ent)
		DispatchKeyValue(i_Particle, "targetname", s_TargetName)
		GetEntPropString(i_Ent, Prop_Data, "m_iName", s_TargetName, sizeof(s_TargetName))
		DispatchKeyValue(i_Particle, "parentname", s_TargetName)
		DispatchKeyValue(i_Particle, "effect_name", s_Effect)
		DispatchSpawn(i_Particle)
		SetVariantString(s_TargetName)
		AcceptEntityInput(i_Particle, "SetParent", i_Particle, i_Particle, 0)
		ActivateEntity(i_Particle)
		AcceptEntityInput(i_Particle, "Start")
	}
	
	return i_Particle
}


AttachParticleV2(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system");
	
	
	if (IsValidEdict(particle))
	{
		new String:tName[128];
		new Float:pos[3];
		
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 60;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		//CreateTimer(time, DeleteParticle, particle);
	}
}

/*
public Action:DeleteParticle(Handle:timer, any:particle)
{
if (IsValidEntity(particle))
{
new String:classname[128];
GetEdictClassname(particle, classname, sizeof(classname));
if (StrEqual(classname, "info_particle_system", false))
{
RemoveEdict(particle);
}
else
{
LogError("DeleteParticles: not removing entity - not a particle '%s'", classname);
}
}
}
*/

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		//CreateTimer(time, DeleteParticle, particle);
	}
	else
	{
		LogError("ShowParticle: could not create info_particle_system");
	}    
}


bool:SpawnBebopDECOY()
{
	// init ret value
	new bool:ret = false;
	
	// create fake client
	//new client = 0;
	clientX = CreateFakeClient("I_Keep_This_TDM_from_ending");
	
	// if entity is valid
	if (clientX != 0)
	{
		// move into survivor team
		ChangeClientTeam(clientX, 2);
		//FakeClientCommand(client, "jointeam %i", ID_TEAM_SURVIVOR);
		
		// set entity classname to survivorbot
		if (DispatchKeyValue(clientX, "classname", "survivorbot") == true)
		{
			// spawn the client
			if (DispatchSpawn(clientX) == true)
			{
				SetEntityHealth(clientX, 60000);
				ret = true;
				
			}
			else
			{
				
			}
		}
		else
		{
		}
		
		// if something went wrong kick the created fake client
		if (ret == false)
		{
			KickClient(clientX, "");
		}
	}
	else
	{
		
	}
	
	return ret;
	
}


public Action:Determine_nades(Handle:timer)
{
	decl Main_weapon, String:s_ModelName[128]
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && i != clientX)
		{
			Main_weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if (IsValidEdict(Main_weapon))
			{
				GetEdictClassname(Main_weapon, s_ModelName, sizeof(s_ModelName)); 
				if (StrContains(s_ModelName, "weapon_pipe_bomb", false) != -1)
				{
					g_PlayerIncapacitated[i] = PIPEBOMB
					g_b_AllowThrow[i] = true
					//PrintToChatAll("%N allowed to pipe", i);
					
				}
				
				else if (StrContains(s_ModelName, "weapon_vomitjar", false) != -1)
				{
					g_PlayerIncapacitated[i] = VOMITJAR
					g_b_AllowThrow[i] = true
					//PrintToChatAll("%N allowed to jar", i);
				}
				else if (StrContains(s_ModelName, "weapon_molotov", false) != -1)
				{
					g_PlayerIncapacitated[i] = MOLOTOV
					g_b_AllowThrow[i] = true
					//PrintToChatAll("%N allowed to jar", i);
				}
			}
			else
			{
				g_b_AllowThrow[i] = false
			}
		}
		
	}	
	
	
}
public Action:Keep_high_Health(Handle:timer)
{
	if (IsClientInGame(clientX) && IsPlayerAlive(clientX))
	{
		SetEntityHealth(clientX, 60000);//look into
	}
}

public Action:Add_HaloETC(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && i != clientX && IsPlayerAlive(i))
		{
			if (RandomBonusMode == 1)
			{
				if(IsPlayerBoomer(i))
				{
					if(AlphaBoomer[i]==1)
					{
						CreateRingEffect(i, 150, 150, 230, 230, 2.0, 200.0);
					}
					
				}
			}
		}
	}
	
}

public Action:TestSprite(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && i != clientX && IsPlayerAlive(i))
		{
			if(FollowBeamTimers[i] != INVALID_HANDLE)
			{
				KillTimer(FollowBeamTimers[i]);
				FollowBeamTimers[i]=INVALID_HANDLE;
			}
			FollowBeamTimers[i] = CreateTimer(0.1, Timer_FollowBeam, i, TIMER_REPEAT);//Thanks to Evol creator of HUNTER GAMES for this code 
		}
	}
}

public Action:Timer_FollowBeam(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{	
		if (RandomBonusMode == 0)
		{
			if(Flying[client])
			{
				CreateLaserEffectJetpack(client);//make player red for flying
			}
		}
		/*
		else if (RandomBonusMode == 1)
		{
		if(GetClientTeam(client)==3)
		{
		
		if(IsPlayerBoomer(client))
		{
		if(TeamState[client]==INFECTED_TEAM)
		{
		CreateLaserEffectTestBoomer(client);
		}
		}
		
		}
		else if(GetClientTeam(client)==2)
		{
		CreateLaserEffectTestHuman(client);
		}
		}
		*/
	}
}

KillFollowBeam(client)
{
	if (FollowBeamTimers[client] != INVALID_HANDLE)
	{
		KillTimer(FollowBeamTimers[client]);
		FollowBeamTimers[client] = INVALID_HANDLE;
	}
}


public Action:Check_burning(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && i != clientX)
		{
			if (RandomBonusMode == 1)
			{
				if(GetClientTeam(i)==2)
				{
					AllowHighJump[i]=1;
				}
				if(GetClientTeam(i)==3)
				{
					AllowHighJump[i]=0;
					
				}
			}
		}
		
	}
}



public Action:Timer_KickAllBots(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && i != clientX)
		{
			KickClient(i, "BotKicked");
		}
		
	}	
	
	
	return Plugin_Stop;
}


public Action:reset_health(Handle:Timer, any:client) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntityHealth(client, 100)
	}
	
}


public Action:reset_speed(Handle:Timer, any:client) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntDataFloat(client, LagMovement, 1.0, true);
	}
	
}



public Action:Give_health_onRespawn(Handle:Timer, any:client) 
{
	SetEntityHealth(client, 1337)
	//PrintToChatAll(" give health before custom maps bypassed");
}


public Action:Respawn(Handle:timer, any:client)
{	
	if (GetConVarInt(GameType)==1)
	{
		if (IsValidClient(client) && Force_spawns == false)
		{
			CanISpawn[client]=ALLOWSPAWN;
			SDKCall(hRoundRespawn, client);
			
			CreateTimer(3.0,Give_health_onRespawn, client);//add the vectors part here 
			CreateTimer(6.5,reset_health, client);
			
		}
	}
	if (GetConVarInt(GameType)==2)
	{
		if (IsValidClient(client) && Force_spawns == false)
		{
			CanISpawn[client]=ALLOWSPAWN;
			SDKCall(hRoundRespawn, client);
			
			CreateTimer(3.0,Give_health_onRespawn, client);//add the vectors part here 
			CreateTimer(4.5,reset_health, client);
			
		}	
	}
}

public Action:Remove_corpse(Handle:timer)
{	
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{
		new String:name[64];
		new EntCount = GetEntityCount();
		for (new i = 0; i <= EntCount; i++)
		{
			if(IsValidEntity(i))
			{
				GetEdictClassname(i, name, sizeof(name));
				if (StrEqual(name, "survivor_death_model", false) || StrEqual(name, "physics_prop_ragdoll", false))
				{
					RemoveEdict(i);
				}	
			}
			
		}
	}
}

public Action:kill_infected(Handle:timer)
{	
	if (GetConVarInt(GameType)==1||GetConVarInt(GameType)==2)
	{	
		new anyclient = GetAnyClient();
		if (anyclient > 0)
		{
			DirectorCommand(anyclient, "director_stop");
		}
		SetConVarInt(FindConVar("survivor_ledge_grab_health"), 1);
		SetConVarInt(FindConVar("tank_stuck_time_suicide"), 1);
		SetConVarInt(FindConVar("z_health"), 1);
		SetConVarInt(FindConVar("z_speed"), 0);
		SetConVarInt(FindConVar("sv_alltalk"), 1);
		SetConVarInt(FindConVar("z_walk_speed"), 0);
		SetConVarInt(FindConVar("director_no_mobs"), 1);
		SetConVarInt(FindConVar("sv_disable_glow_survivors"), 1);
		SetConVarInt(FindConVar("director_tank_lottery_selection_time"), 5000);//ensures no1 gets tank
		SetConVarInt(FindConVar("director_no_bosses"), 1);
		SetConVarInt(FindConVar("director_no_specials"), 1);
		SetConVarInt(FindConVar("z_common_limit"), 0);
		SetConVarInt(FindConVar("z_mega_mob_size"), 1);	
		SetConVarInt(FindConVar("versus_tank_chance_intro"), 0);
		SetConVarInt(FindConVar("versus_tank_chance_finale"), 0);
		SetConVarInt(FindConVar("versus_tank_chance"), 0);
		SetConVarInt(FindConVar("sb_all_bot_team"), 1);
		SetConVarInt(FindConVar("vs_max_team_switches"), 50);// set to 0 after testing the auto spawn
		SetConVarInt(FindConVar("sb_stop"), 1);
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 0);
		
		SetConVarFloat(FindConVar("z_vomit_velocity"), 1500.0);//for bonus infection mode
		SetConVarInt(FindConVar("z_vomit_range"), 200);
		SetConVarInt(FindConVar("z_vomit_interval"), 20);
		
		new String:name[64];
		new EntCount = GetEntityCount();
		for (new i = 0; i <= EntCount; i++)
		{
			if(IsValidEntity(i))
			{
				GetEdictClassname(i, name, sizeof(name));
				
				if (StrEqual(name, "survivor_death_model", false) || StrEqual(name, "physics_prop_ragdoll", false))
				{
					RemoveEdict(i);
				}
				
				if (StrContains(name, "prop_door_rotating", false) != -1)
				{
					RemoveEdict(i);
				}
			}
		}
		
		new entcount = GetEntityCount();
		decl String:ModelName[128];
		for (new i=1;i<=entcount;i++)
		{
			if(IsValidEntity(i))
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", ModelName, 128);
				
				if(StrContains(ModelName, "infected", true) != -1)
				{
					if(StrContains(ModelName, "witch.mdl", true) != -1)
					{
						RemoveEdict(i);
					}
					
					else if (StrContains(ModelName, "spitter.mdl", true) != -1 ||
					StrContains(ModelName, "smoker.mdl", true) != -1  ||
					StrContains(ModelName, "hunter.mdl", true) != -1  ||
					StrContains(ModelName, "charger.mdl", true) != -1 ||
					StrContains(ModelName, "jockey.mdl", true) != -1 ||
					StrContains(ModelName, "hulk.mdl", true) != -1 )
					{
						ForcePlayerSuicide(i);
					}
					
					for (new j = 1; j <= MaxClients; j++)
					{
						if (IsClientInGame(j) && IsFakeClient(j) && j != clientX && IsPlayerBoomer(j)) 
						{
							ForcePlayerSuicide(j)
						}
						
					}
				}
				
				
			}
		}
	}
}


public Action:TurnBootsOn(client, args)
{	
	//AllowHighJump[client]=true;
	Test_Sprites[client]=1;
}

public Action:spawn_test_Tank(client, args)
{	
	new flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "z_spawn tank");
	SetCommandFlags("z_spawn", flags);
	return;
}


public Action:spawn_test_human(client, args)
{	
	SpawnBebopFakeClient();	
}

public Action:OnPlayerRunCmd(i_Client, &i_Buttons, &i_Impulse, Float:f_Velocity[3], Float:f_Angles[3], &i_Weapon)
{
	if (GetConVarInt(GameType)==1 || GetConVarInt(GameType)==2)
	{
		if(initial_stage == false)
		{
			if (RandomBonusMode == 0)
			{
				if (GetConVarBool(JetPacks))
				{
					elig = isEligible(i_Client);
					
					Eligible[i_Client] = elig;
					
					if (elig)
					{
						if(i_Buttons & IN_JUMP)//WAS RELOAD
						{	
							new onground = (GetEntityFlags(i_Client) & FL_ONGROUND)	
							if (onground)
							{
								StopJetpack(i_Client);
								if(JetpackFuel[i_Client]<1)
								{
									if(IamNowFuelling[i_Client]==0)
									{
										IamNowFuelling[i_Client]=1;
										StopFlying(i_Client);
										StopJetpack(i_Client);
										PrintHintText(i_Client, "Empty fuel tank, auto refuelling...");
										SetEntPropFloat(i_Client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
										SetEntPropFloat(i_Client, Prop_Send, "m_flProgressBarDuration", 4.0);  
										if(JetRefuelTimers[i_Client] != INVALID_HANDLE)
										{
											KillTimer(JetRefuelTimers[i_Client]);
											JetRefuelTimers[i_Client] = INVALID_HANDLE;
										}
										JetRefuelTimers[i_Client] = CreateTimer(4.0, Reactivate_Jetpack, i_Client, TIMER_REPEAT)
									}
								}
							}
							if(JetpackFuel[i_Client]>0)
							{					
								JetpackFuel[i_Client]--;
								if (Flying[i_Client])
								{
									/*new Float:vecPos[3];
									GetClientAbsOrigin(i_Client, vecPos);
									EmitSoundToAll(g_sSound, i_Client, 
									SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,
									0.8, SNDPITCH_NORMAL, -1, 
									vecPos, NULL_VECTOR, true, 0.0);
									*/
									KeepFlying(i_Client);
									
									
								}
								else	
								{
									StartFlying(i_Client);
								}
							}
						}
						else
						{
							if (Flying[i_Client])
								StopFlying(i_Client);
						}	
					}
					else
					{
						if (Flying[i_Client])
							StopFlying(i_Client);
					}
				}
			}
		}
		if(i_Buttons & IN_USE)
		{
			if (IsClientInGame(i_Client) && GetClientTeam(i_Client) == 3 && IsPlayerGhost(i_Client))
			{
				ForcePlayerSuicide(i_Client)
			}
		}
		if(i_Buttons & IN_SCORE)
		{
			if (IsClientInGame(i_Client) && Force_spawns == false) 
			{
				if (RandomBonusMode == 1)
				{
					PrintMidGameScoreBonusBoomer(i_Client)
				}
				else if (RandomBonusMode == 2)
				{
					PrintMidGameScoreBonusGnome(i_Client)
				}
				else
				{
					if (GetConVarInt(GameType)==1)
					{
						PrintTeamsToClient(i_Client)
					}
					if (GetConVarInt(GameType)==2)
					{
						PrintMidGameScore(i_Client)
					}
				}
			}
		}
		i_Buttons = i_Buttons & ~IN_SCORE;
		
		if(i_Buttons & IN_JUMP)
		{
			new NotJumping = (GetEntityFlags(i_Client) & FL_ONGROUND)	
			if (NotJumping)
			{
				if(AllowHighJump[i_Client]==1) 
				{
					if(JumpTimer[i_Client]==0)
					{
						jump(i_Client);
						JumpTimer[i_Client]=1;
						CreateTimer(0.6, Reactivate_jump, i_Client, TIMER_REPEAT)
					}
				}
			}
			
			if(IsPlayerBoomer(i_Client))
			{	
				if (NotJumping)
				{
					if(JumpTimer[i_Client]==0)
					{
						JumpTimer[i_Client]=1;
						CreateTimer(0.6, Reactivate_jump, i_Client, TIMER_REPEAT)
						
						if (RandomBonusMode == 1)
						{
							if(AlphaBoomer[i_Client]==1)
							{
								Suicide_jump_Alpha(i_Client);
							}
							else
							{
								Suicide_jump(i_Client);
							}
						}
					}
					
				}
			}
			//i_Buttons = i_Buttons & ~IN_JUMP;
		}
		if(Stop_guns == true)
		{
			if(i_Buttons & IN_ATTACK)
			{
				i_Buttons = i_Buttons & ~IN_ATTACK;
				PrintHintText(i_Client, "Wait untill the fight starts to use your weapons");
			}
			if(i_Buttons & IN_ATTACK2)
			{
				i_Buttons = i_Buttons & ~IN_ATTACK2;
				PrintHintText(i_Client, "Wait untill the fight starts to use your weapons");
			}
		}
		
		if(i_Buttons & IN_SPEED)
		{		
			if(initial_stage == false)
			{
				if(TeamState[i_Client] == INFECTED_TEAM)
				{
					i_Buttons = i_Buttons & ~IN_SPEED;
				}
				if (GetConVarInt(GameType)==1)
				{
					if (IsClientInGame(i_Client) && Force_spawns == false && CanISpawn[i_Client]==ALLOWSPAWN) 
					{
						if(!IsPlayerAlive(i_Client))
						{
							if(TeamState[i_Client]==NO_TEAM)
							{
								ChooseTeamMenu(i_Client);
							}
							else
							{
								ChooseClassMenu(i_Client);
							}
						}
					}
					else
					{
						
						if(TeamState[i_Client]==NO_TEAM)
						{
							ChooseTeamMenuAlive(i_Client);
						}
						else
						{
							ChooseClassMenuAlive(i_Client);
						}
					}
				}
				if (GetConVarInt(GameType)==2)
				{
					if(RandomBonusMode!=1)//INFECTION
					{
						if(!IsPlayerAlive(i_Client))
						{
							ChooseClassMenu(i_Client);
						}
						
						else
						{
							ChooseClassMenuAlive(i_Client);
						}
					}
					
					
				}
				
			}
		}
		
		if (IsFakeClient(i_Client))
			return Plugin_Continue
		//PrintHintTextToAll("%N is not a fake client", i_Client);
		if (!g_b_AllowThrow[i_Client])
			return Plugin_Continue
		//PrintToChatAll("%N is allowed to throw", i_Client);
		if (!g_PlayerIncapacitated[i_Client])
			return Plugin_Continue
		//PrintToChatAll("%N bypassed g_PlayerIncapacitated", i_Client);
		if (g_b_InAction[i_Client] && (i_Buttons & IN_ATTACK))
		{
			decl i_Viewmodel
			
			//PrintToChatAll("%N bypassed g_b_InAction", i_Client);
			
			i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
			SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 5)
		}
		else if (g_b_InAction[i_Client])
		{
			g_b_InAction[i_Client] = false
			decl i_Viewmodel, i_Grenade
			
			i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
			SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 6)
			SetEntPropFloat(i_Viewmodel, Prop_Send, "m_flLayerStartTime", GetGameTime())
			
			PlayScene(i_Client)
			
			switch (g_PlayerIncapacitated[i_Client])
			{
				case PIPEBOMB: ThrowPipebomb(i_Client)
				case VOMITJAR: ThrowVomitjar(i_Client)
				case MOLOTOV: ThrowMolotov(i_Client)
			}
			
			i_Grenade = GetPlayerWeaponSlot(i_Client, 2)		
			if (IsValidEdict(i_Grenade))
				RemoveEdict(i_Grenade)
			g_PlayerIncapacitated[i_Client] = NONE
			
			i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
			
			if (i_Weapon != -1)
				SetEntPropFloat(i_Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0)	
			
			CreateTimer(1.0, ReturnPistolDelay, i_Client)
			
			return Plugin_Continue
		}
		
		decl i_GrenadeType
		i_GrenadeType = 0
		
		switch (g_PlayerIncapacitated[i_Client])
		{
			case PIPEBOMB: i_GrenadeType = g_PipebombModel
			case VOMITJAR: i_GrenadeType = g_VomitjarModel
			case MOLOTOV: i_GrenadeType = g_MolotovModel
		}
		
		if (i_GrenadeType)//&& !(i_Buttons & IN_FORWARD)
		{
			decl i_Viewmodel, i_Model
			i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
			i_Model = GetEntProp(i_Viewmodel, Prop_Send, "m_nModelIndex")
			
			if (i_Model == i_GrenadeType)
				SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 1)
			
			if (i_Buttons & IN_ATTACK)
			{
				if (i_Model != i_GrenadeType)
					return Plugin_Continue
				
				LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
				SetEntDataFloat(i_Client, LagMovement, 0.8, true);
				
				CreateTimer(0.7,reset_speed, i_Client);
				
				SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 5)
				SetEntPropFloat(i_Viewmodel, Prop_Send, "m_flLayerStartTime", GetGameTime())
				
				i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
				
				if (i_Weapon != -1)
					SetEntPropFloat(i_Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 100.0)
				
				g_b_InAction[i_Client] = true
				//PrintToChatAll("FAKE GRENADE THROWN");
				decl String:s_Sound[64]
				
				FormatEx(s_Sound, sizeof(s_Sound), ")%s", SOUND_PISTOL)
				StopSound(i_Client, SNDCHAN_WEAPON, s_Sound)
				StopSound(i_Client, SNDCHAN_WEAPON, SOUND_DUAL_PISTOL)
				StopSound(i_Client, SNDCHAN_WEAPON, SOUND_MAGNUM)
				
				
			}
			else if (i_Buttons & IN_ATTACK2)
			{
				if ((GetGameTime() - g_PlayerGameTime[i_Client]) < 1.0)
					return Plugin_Continue
				
				i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
				
				if (i_Weapon != -1 && GetEntProp(i_Weapon, Prop_Data, "m_bInReload"))
					return Plugin_Continue
				
				if (i_Model != i_GrenadeType)
				{
					SetEntProp(i_Viewmodel, Prop_Send, "m_nModelIndex", i_GrenadeType, 2)
					SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 1)
					g_PlayerGameTime[i_Client] = GetGameTime()
				}
				else
				{
					SetPlayerWeaponModel(i_Client, i_Weapon)
					g_PlayerGameTime[i_Client] = GetGameTime()
				}
			}
			
		}
	}
	return Plugin_Continue
}

StopJetpack(client)
{
	StopSound(client, SNDCHAN_AUTO, g_sSound);
}

bool:isEligible(client)
{
	
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (GetClientTeam(client)!=2) return false;
	if (!IsPlayerAlive(client)) return false;
	return true;
}

public Action:StartFlying(client)
{
	Flying[client]=true;
	SetMoveType(client, MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE);
	AddVelocity(client, 50.0);
	return Plugin_Continue;
}

public Action:KeepFlying(client)
{
	AddVelocity(client, 50.0);
	return Plugin_Continue;
}

public Action:StopFlying(client)
{
	Flying[client]=false;
	SetMoveType(client, MOVETYPE_WALK, MOVECOLLIDE_DEFAULT);
	return Plugin_Continue;
}

AddVelocity(client, Float:speed)
{
	new Float:maxSpeed = 200.0;//was 500, try different values
	new Float:vecVelocity[3];
	GetEntDataVector(client, PropVelocity, vecVelocity);
	if ((vecVelocity[2]+speed) > maxSpeed)
		vecVelocity[2] = maxSpeed;
	else
	vecVelocity[2] += speed;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

SetMoveType(client, movetype, movecollide)
{
	SetEntData(client, PropMoveType, movetype);
	SetEntData(client, PropMoveCollide, movecollide);
}

public Notify(client,time)
{
	CreateTimer((3.0+time), NotifyClient, client);
}

public Action:NotifyClient(Handle:timer, any:client)
{
	if (isEligible(client)){
		PrintToChat(client, "Right click to use the Jetpack.");
	}
}



bool:Suicide_jump(client)
{
	//client still there?
	if (!IsClientInGame(client)) return false;
	new Float:vec[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
	vec[0] *= 2.0;
	vec[1] *= 2.0;
	vec[2] = 440.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
	return true;
}


bool:Suicide_jump_Alpha(client)
{
	//client still there?
	if (!IsClientInGame(client)) return false;
	
	new Float:vec[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
	
	vec[0] *= 2.0;//3
	vec[1] *= 2.0;
	vec[2] = 600.0;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
	
	return true;
	
}



public Action:jump(any:client)
{
	if (IsClientInGame(client))
	{
		new Float:vec[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
		
		if (vec[0] == 0.0)
		{
			// PrintCenterText(client, "You must be on the move to ghost pounce");
			return Plugin_Handled;
		}
		if (vec[1] == 0.0)
		{
			// PrintCenterText(client, "You must be on the move to ghost pounce");
			return Plugin_Handled;
		}
		
		vec[0] *= 1.5;
		vec[1] *= 1.5;
		vec[2] = 400.0;
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
	}
	return Plugin_Continue;
	//return true;
}

public Action:ReturnPistolDelay(Handle:h_Timer, any:i_Client)
{
	decl i_Viewmodel, i_Weapon
	
	if (!i_Client && !IsClientInGame(i_Client))
		return Plugin_Handled
	
	i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
	i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
	SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 2)
	if (i_Weapon != -1)
		SetPlayerWeaponModel(i_Client, i_Weapon)
	SetEntPropFloat(i_Viewmodel, Prop_Send, "m_flLayerStartTime", GetGameTime())
	
	return Plugin_Continue
}



public SetPlayerWeaponModel(i_Client, i_Weapon)//maybe add all other possible weapons here 
{
	decl i_Viewmodel, String:s_ClassName[32]
	
	i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
	GetEdictClassname(i_Weapon, s_ClassName, sizeof(s_ClassName))
	
	if (StrEqual(s_ClassName, "weapon_pistol_magnum"))
		SetEntProp(i_Viewmodel, Prop_Send, "m_nModelIndex", g_MagnumModel)
	else if (StrEqual(s_ClassName, "weapon_pistol"))
	{
		if (GetEntProp(i_Weapon, Prop_Send, "m_hasDualWeapons"))
			SetEntProp(i_Viewmodel, Prop_Send, "m_nModelIndex", g_DualPistolModel, 2)
		else
			SetEntProp(i_Viewmodel, Prop_Send, "m_nModelIndex", g_PistolModel, 2)
	}
	SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 1)
}

public PlayScene(i_Client)
{
	decl i_Ent, String:s_Model[128], String:s_SceneFile[32], i_Random
	
	GetEntPropString(i_Client, Prop_Data, "m_ModelName", s_Model, sizeof(s_Model))
	
	
	if (StrContains(s_Model, "gambler") != -1)
	{
		switch (g_PlayerIncapacitated[i_Client])
		{
			case PIPEBOMB:
			{
				i_Random = GetRandomInt(0, sizeof(g_VoicePipebombNick)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/gambler/%s.vcd", g_VoicePipebombNick[i_Random])
			}
			case VOMITJAR:
			{
				i_Random = GetRandomInt(0, sizeof(g_VoiceVomitjarNick)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/gambler/%s.vcd", g_VoiceVomitjarNick[i_Random])
			}
			case MOLOTOV:
			{
				i_Random = GetRandomInt(0, sizeof(g_VoiceMolotovNick)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/gambler/%s.vcd", g_VoiceMolotovNick[i_Random])
			}
			
		}
	}
	else if (StrContains(s_Model, "coach") != -1)
	{
		switch (g_PlayerIncapacitated[i_Client])
		{
			case PIPEBOMB:
			{
				i_Random = GetRandomInt(0, sizeof(g_VoicePipebombCoach)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/coach/%s.vcd", g_VoicePipebombCoach[i_Random])
			}
			case VOMITJAR:
			{
				i_Random = GetRandomInt(0, sizeof(g_VoiceVomitjarCoach)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/coach/%s.vcd", g_VoiceVomitjarCoach[i_Random])
			}
			case MOLOTOV:
			{
				i_Random = GetRandomInt(0, sizeof(g_VoiceMolotovCoach)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/coach/%s.vcd", g_VoiceMolotovCoach[i_Random])
			}
		}	
	}
	else if (StrContains(s_Model, "mechanic") != -1)
	{
		switch (g_PlayerIncapacitated[i_Client])
		{
			case PIPEBOMB:
			{
				i_Random = GetRandomInt(0, sizeof(g_VoicePipebombEllis)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/mechanic/%s.vcd", g_VoicePipebombEllis[i_Random])
			}
			case VOMITJAR:
			{
				i_Random = GetRandomInt(0, sizeof(g_VoiceVomitjarEllis)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/mechanic/%s.vcd", g_VoiceVomitjarEllis[i_Random])
			}
			case MOLOTOV:
			{
				i_Random = GetRandomInt(0, sizeof(g_VoiceMolotovEllis)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/mechanic/%s.vcd", g_VoiceMolotovEllis[i_Random])
			}
		}	
	}
	else if (StrContains(s_Model, "producer") != -1)
	{
		switch (g_PlayerIncapacitated[i_Client])
		{
			case PIPEBOMB:
			{
				i_Random = GetRandomInt(0, sizeof(g_VoicePipebombRochelle)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/producer/%s.vcd", g_VoicePipebombRochelle[i_Random])
			}
			case VOMITJAR:
			{
				i_Random = GetRandomInt(0, sizeof(g_VoiceVomitjarRochelle)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/producer/%s.vcd", g_VoiceVomitjarRochelle[i_Random])
			}
			case MOLOTOV:
			{
				i_Random = GetRandomInt(0, sizeof(g_VoiceMolotovRochelle)-1)
				FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/producer/%s.vcd", g_VoiceMolotovRochelle[i_Random])
			}
		}	
	}
	
	
	i_Ent = CreateEntityByName("instanced_scripted_scene")
	DispatchKeyValue(i_Ent, "SceneFile", s_SceneFile)
	DispatchSpawn(i_Ent)
	SetEntPropEnt(i_Ent, Prop_Data, "m_hOwner", i_Client)
	ActivateEntity(i_Ent)
	AcceptEntityInput(i_Ent, "Start", i_Client, i_Client)
}


public Action:DeadCenterThreeissue(Handle:Timer)
{
	decl Float:f_EntOrigin[3]
	decl Float:Boundaries_DEADCENTERTHREE[3]={6476.764648, -2497.810059, 202.131500};
	if(initial_stage==false)
	{
		for (new j = 1; j <= MaxClients; j++)
		{
			if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX) 
			{
				GetEntPropVector(j, Prop_Send, "m_vecOrigin", f_EntOrigin)
				GetClientAbsOrigin(j, f_EntOrigin)
				if (GetVectorDistance(Boundaries_DEADCENTERTHREE, f_EntOrigin) <= 200)//keeps players from leaving the designated fighting area
				{		
					if(TeamState[j]==BLUE_TEAM)
					{
						TeleportEntity(j, Blue_Teleport, NULL_VECTOR, NULL_VECTOR);
						//PrintToChat(j, "Don't leave the fighting area you coward");
					}
					if(TeamState[j]==RED_TEAM)
					{
						TeleportEntity(j, Red_Teleport, NULL_VECTOR, NULL_VECTOR);
						//PrintToChat(j, "Don't leave the fighting area you coward");
					}			
					
				}
			}
		}
	}
	
}
public Action:CarnivalFIVEissue(Handle:Timer) //nightmare :-(, decides who gets the adrenaline
{
	if (GetConVarInt(GameType)==1)
	{
		decl Float:f_EntOrigin[3]
		decl Float:Boundaries_CARNIVALFIVE[3]={-872.263672, 2217.686768, -255.968887};
		if(initial_stage==false)
		{
			for (new j = 1; j <= MaxClients; j++)
			{
				if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX) 
				{
					GetEntPropVector(j, Prop_Send, "m_vecOrigin", f_EntOrigin)
					GetClientAbsOrigin(j, f_EntOrigin)
					if (GetVectorDistance(Boundaries_CARNIVALFIVE, f_EntOrigin) <= 400)//keeps players from leaving the designated fighting area
					{		
						if(TeamState[j]==BLUE_TEAM)
						{
							TeleportEntity(j, Blue_Teleport, NULL_VECTOR, NULL_VECTOR);
							//PrintToChat(j, "Don't leave the fighting area you coward");
						}
						if(TeamState[j]==RED_TEAM)
						{
							TeleportEntity(j, Red_Teleport, NULL_VECTOR, NULL_VECTOR);
							//PrintToChat(j, "Don't leave the fighting area you coward");
						}			
						
					}
				}
			}
		}
	}
	if (GetConVarInt(GameType)==2)	
	{
		decl Float:f_EntOrigin[3]
		decl Float:Boundaries_CARNIVALFIVE[3]={-872.263672, 2217.686768, -255.968887};
		if(initial_stage==false)
		{
			for (new j = 1; j <= MaxClients; j++)
			{
				if (IsClientInGame(j) && !IsFakeClient(j) && j != clientX) 
				{
					GetEntPropVector(j, Prop_Send, "m_vecOrigin", f_EntOrigin)
					GetClientAbsOrigin(j, f_EntOrigin)
					if (GetVectorDistance(Boundaries_CARNIVALFIVE, f_EntOrigin) <= 400)//keeps players from leaving the designated fighting area
					{		
						new random_spawn;
						random_spawn=GetRandomInt(1,10)//increase when more spawns are available
						
						if(random_spawn==1)
						{
							//	if(IsSpawnFree(Teleport_one))
							//{
							TeleportEntity(j, Teleport_one, NULL_VECTOR, NULL_VECTOR);	
							//PrintToChatAll("Spawn is free no players detected around it")
							//}
						}
						if(random_spawn==2)
						{
							TeleportEntity(j, Teleport_two, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==3)
						{
							TeleportEntity(j, Teleport_three, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==4)
						{
							TeleportEntity(j, Teleport_four, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==5)
						{
							TeleportEntity(j, Teleport_five, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==6)
						{
							TeleportEntity(j, Teleport_six, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==7)
						{
							TeleportEntity(j, Teleport_seven, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==8)
						{
							TeleportEntity(j, Teleport_eight, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==9)
						{
							TeleportEntity(j, Teleport_nine, NULL_VECTOR, NULL_VECTOR);	
						}
						if(random_spawn==10)
						{
							TeleportEntity(j, Teleport_ten, NULL_VECTOR, NULL_VECTOR);	
						}				
						
						
					}
				}
			}
		}
		
		
	}
}


public Action:Decide_Spawn_positions(Handle:Timer) 
{
	decl String:Map[56];
	GetCurrentMap(Map, sizeof(Map));
	if(StrContains(Map, "l4d_dm_rooftop_edit.bsp", false)) //specific method to detect custom maps
	{
		mapNum=12;//random number above 5 
		
		
		Teleport_one[0] =7426.653320;
		Teleport_one[1] =8409.344727;
		Teleport_one[2] =5940.451172;
		
		Teleport_two[0] =5515.789551;
		Teleport_two[1] =8505.540039;
		Teleport_two[2] =6040.031250;	
		
		Teleport_three[0] =7700.057617;
		Teleport_three[1] =8362.639648;
		Teleport_three[2] =5788.201172;
		
		Teleport_four[0] =7301.141602;
		Teleport_four[1] =8592.031250;
		Teleport_four[2] =5920.031250;
		
		Teleport_five[0] =6117.615234;
		Teleport_five[1] =9175.504883;
		Teleport_five[2] =5920.031250;
		
		Teleport_six[0] =6356.089355;
		Teleport_six[1] =7591.496582;
		Teleport_six[2] =5920.031250;
		
		Teleport_seven[0] =7162.216797;
		Teleport_seven[1] =8040.937988;
		Teleport_seven[2] =5813.117676;
		
		Teleport_eight[0] =6053.224609;
		Teleport_eight[1] =7707.348145;
		Teleport_eight[2] =6080.031250;
		
		Teleport_nine[0] =5352.914063;
		Teleport_nine[1] =8421.849609;
		Teleport_nine[2] =	6211.818848;
		
		Teleport_ten[0] =7574.462402;
		Teleport_ten[1] =8719.652344;
		Teleport_ten[2] =5920.031250;
		
		Red_Teleport[0] =7426.653320;
		Red_Teleport[1] =8409.344727;
		Red_Teleport[2] =5940.451172;
		
		Blue_Teleport[0] =5515.789551;
		Blue_Teleport[1] =8505.540039;
		Blue_Teleport[2] =6040.031250;	
		
		Boundaries[0] = 6500.817871;
		Boundaries[1] = 8546.149414;
		Boundaries[2] = 6211.793945;
		Distance=10000;	
	}	
	
	
	new String:mapName[40];
	GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
	new String:charArr[5][5];
	ExplodeString(mapName, "_", charArr, 5, 5);
	new String:mapAbbriv[5];
	strcopy(mapAbbriv, 5, charArr[0]);
	
	
	
	if(strcmp(mapAbbriv, "c1m1") == 0)
	{
		
		Teleport_one[0] =2212.373047;
		Teleport_one[1] =4624.605957;
		Teleport_one[2] =1184.031250;
		
		Teleport_two[0] =337.129242;
		Teleport_two[1] =4796.791016;
		Teleport_two[2] =1184.031250;
		
		
		Teleport_three[0] =1104.031250;
		Teleport_three[1] =4978.152832;
		Teleport_three[2] =1184.031250;
		
		Teleport_four[0] =561.655945;
		Teleport_four[1] =4080.562012;
		Teleport_four[2] =1184.031250;
		
		Teleport_five[0] =1064.275635;
		Teleport_five[1] =4100.623535;
		Teleport_five[2] =1184.031250;
		
		Teleport_six[0] =911.968750;
		Teleport_six[1] =5007.968750;
		Teleport_six[2] =1184.031250;
		
		Teleport_seven[0] =179.509338;
		Teleport_seven[1] =5161.685059;
		Teleport_seven[2] =1184.031250;
		
		Teleport_eight[0] =1807.968750;
		Teleport_eight[1] =4773.142090;
		Teleport_eight[2] =1184.031250;	
		
		Teleport_nine[0] =1805.037354;
		Teleport_nine[1] =4184.875000;
		Teleport_nine[2] =	1184.031250;
		
		Teleport_ten[0] =2055.532959;
		Teleport_ten[1] =4639.968750;
		Teleport_ten[2] =1184.031250;
		
		mapNum=DEAD_CENTER;
		Red_Teleport[0] =2212.373047;
		Red_Teleport[1] =4624.605957;
		Red_Teleport[2] =1184.031250;
		
		Blue_Teleport[0] =337.129242;
		Blue_Teleport[1] =4796.791016;
		Blue_Teleport[2] =1184.031250;
		
		Boundaries[0] = 1057.689453;
		Boundaries[1] = 4543.709961;
		Boundaries[2] = 1184.031250;
		Distance=1300;
	}
	else if(strcmp(mapAbbriv, "c1m2") == 0){
		
		Teleport_one[0] =-7210.471191;
		Teleport_one[1] =-4611.237305;
		Teleport_one[2] =384.281250;
		
		Teleport_two[0] =-9038.011719;
		Teleport_two[1] =-1962.257690;
		Teleport_two[2] =388.281250;
		
		
		Teleport_three[0] =-9197.968750;
		Teleport_three[1] =-2195.725586;
		Teleport_three[2] =390.281250;
		
		Teleport_four[0] =-7570.618652;
		Teleport_four[1] =-2467.431641;
		Teleport_four[2] =391.031250;
		
		Teleport_five[0] =-8341.555664;
		Teleport_five[1] =-1960.313721;
		Teleport_five[2] =384.031250;
		
		Teleport_six[0] =-8023.034180;
		Teleport_six[1] =-3274.634277;
		Teleport_six[2] =388.281250;
		
		Teleport_seven[0] =-8854.493164;
		Teleport_seven[1] =-3952.138672;
		Teleport_seven[2] =388.281250;
		
		Teleport_eight[0] =-8991.962891;
		Teleport_eight[1] =-4536.715332;
		Teleport_eight[2] =384.031250;	
		
		Teleport_nine[0] =-8325.990234;
		Teleport_nine[1] =-1051.754150;
		Teleport_nine[2] =	384.031250;
		
		Teleport_ten[0] =-7577.352051;
		Teleport_ten[1] =-1282.753174;
		Teleport_ten[2] =384.031250;
		
		Red_Teleport[0] =-7210.471191;
		Red_Teleport[1] =-4611.237305;
		Red_Teleport[2] =384.281250;
		
		Blue_Teleport[0] =-9038.011719;
		Blue_Teleport[1] =-1962.257690;
		Blue_Teleport[2] =388.281250;
		
		Boundaries[0] = -8346.177734;
		Boundaries[1] = -2718.531250;
		Boundaries[2] = 384.031250;
		Distance=2200;
		
	}else if(strcmp(mapAbbriv, "c1m3") == 0){
		
		
		Teleport_one[0] =6460.995605;
		Teleport_one[1] =-3601.515381;
		Teleport_one[2] =24.031250;
		
		Teleport_two[0] =6631.224121;
		Teleport_two[1] =-1431.094971;
		Teleport_two[2] =24.031250;
		
		Teleport_three[0] =6202.978516;
		Teleport_three[1] =-1616.031250;
		Teleport_three[2] =24.031250;
		
		Teleport_four[0] =5339.443359;
		Teleport_four[1] =-2588.542969;
		Teleport_four[2] =0.031250;
		
		Teleport_five[0] =5312.005371;
		Teleport_five[1] =-3583.420898;
		Teleport_five[2] =0.031250;
		
		Teleport_six[0] =6953.050781;
		Teleport_six[1] =-3381.031250;
		Teleport_six[2] =24.031250;
		
		Teleport_seven[0] =7599.968750;
		Teleport_seven[1] =-3166.801758;
		Teleport_seven[2] =24.031250;
		
		Teleport_eight[0] =7356.751465;
		Teleport_eight[1] =-2288.031738;
		Teleport_eight[2] =24.031250;	
		
		Teleport_nine[0] =6932.239258;
		Teleport_nine[1] =-1886.765991;
		Teleport_nine[2] =	24.031250;
		
		Teleport_ten[0] =6499.885742;
		Teleport_ten[1] =-2295.968750;
		Teleport_ten[2] =27.631248;
		
		
		Red_Teleport[0] =6460.995605;
		Red_Teleport[1] =-3601.515381;
		Red_Teleport[2] =24.031250;
		
		Blue_Teleport[0] =6631.224121;
		Blue_Teleport[1] =-1431.094971;
		Blue_Teleport[2] =24.031250;
		
		Boundaries[0] = 6580.867676;
		Boundaries[1] = -2209.931641;
		Boundaries[2] = 88.152374;
		Distance=2000;
		CreateTimer(1.0, DeadCenterThreeissue, _, TIMER_REPEAT);
		
	}else if(strcmp(mapAbbriv, "c1m4") == 0){
		
		Teleport_one[0] =-6113.602051;
		Teleport_one[1] =-3487.383301;
		Teleport_one[2] =0.031250;
		
		Teleport_two[0] =-2797.349365;
		Teleport_two[1] =-3458.290771;
		Teleport_two[2] =0.031250;
		
		Teleport_three[0] =-5437.057617;
		Teleport_three[1] =-4463.968750;
		Teleport_three[2] =0.031250;
		
		Teleport_four[0] =-4119.883789;
		Teleport_four[1] =-4431.968750;
		Teleport_four[2] =280.031250;
		
		Teleport_five[0] =-6150.907227;
		Teleport_five[1] =-3365.059326;
		Teleport_five[2] =280.531250;
		
		Teleport_six[0] =-5429.842773;
		Teleport_six[1] =-4452.118652;
		Teleport_six[2] =280.031250;
		
		Teleport_seven[0] =-3400.468750;
		Teleport_seven[1] =-4200.234863;
		Teleport_seven[2] =0.031250;
		
		Teleport_eight[0] =-4847.968750;
		Teleport_eight[1] =-2337.232910;
		Teleport_eight[2] =0.031250;	
		
		Teleport_nine[0] =-5872.031250;
		Teleport_nine[1] =-3280.031250;
		Teleport_nine[2] =	0.031250;
		
		Teleport_ten[0] =-3155.968750;
		Teleport_ten[1] =-3280.031250;
		Teleport_ten[2] =0.031250;
		
		Red_Teleport[0] =-6113.602051;
		Red_Teleport[1] =-3487.383301;
		Red_Teleport[2] =0.031250;
		
		Blue_Teleport[0] =-2797.349365;
		Blue_Teleport[1] =-3458.290771;
		Blue_Teleport[2] =0.031250;
		
		Boundaries[0] = -3829.647705;
		Boundaries[1] = -3810.183105;
		Boundaries[2] = 0.031250;
		Distance=4000;
	}
	else if(strcmp(mapAbbriv, "c2m1") == 0){	
		mapNum=DARK_CARNIVAL;
		
		Teleport_one[0] =1959.321167;
		Teleport_one[1] =6121.870605;
		Teleport_one[2] =-974.683350;
		
		Teleport_two[0] =1108.322876;
		Teleport_two[1] =3414.408691;
		Teleport_two[2] =-967.968750;
		
		Teleport_three[0] =1035.014282;
		Teleport_three[1] =4270.081543;
		Teleport_three[2] =	-807.968750;
		
		Teleport_four[0] =2215.076904;
		Teleport_four[1] =4225.037598;
		Teleport_four[2] =-1047.968750;
		
		Teleport_five[0] =2406.981201;
		Teleport_five[1] =5970.456543;
		Teleport_five[2] =-967.968750;
		
		Teleport_six[0] =1094.564209;
		Teleport_six[1] =4910.323730;
		Teleport_six[2] =-967.968750;
		
		Teleport_seven[0] =783.968750;
		Teleport_seven[1] =3273.974121;
		Teleport_seven[2] =	-967.971191;
		
		Teleport_eight[0] =1161.126709;
		Teleport_eight[1] =5435.227539;
		Teleport_eight[2] =	-807.968750;	
		
		Teleport_nine[0] =708.753784;
		Teleport_nine[1] =5520.948242;
		Teleport_nine[2] =-975.968750;
		
		Teleport_ten[0] =874.557434;
		Teleport_ten[1] =4667.150879;
		Teleport_ten[2] =-967.968750;			
		
		Red_Teleport[0] =1959.321167;
		Red_Teleport[1] =6121.870605;
		Red_Teleport[2] =-974.683350;
		
		Blue_Teleport[0] =1108.322876;
		Blue_Teleport[1] =3414.408691;
		Blue_Teleport[2] =-967.968750;
		
		Boundaries[0] = 2081.958008;
		Boundaries[1] = 4811.162598;
		Boundaries[2] = -975.968750;
		Distance=2100;
		
	}else if(strcmp(mapAbbriv, "c2m2") == 0){		
		
		Teleport_one[0] =2123.169434;
		Teleport_one[1] =1098.993408;
		Teleport_one[2] =2.305975;
		
		Teleport_two[0] =3564.277344;
		Teleport_two[1] =-2094.656494;
		Teleport_two[2] =0.031250;
		
		Teleport_three[0] =3980.455566;
		Teleport_three[1] =464.444275;
		Teleport_three[2] =0.031250;
		
		Teleport_four[0] =4449.355957;
		Teleport_four[1] =-630.980652;
		Teleport_four[2] =0.031250;
		
		Teleport_five[0] =3254.506348;
		Teleport_five[1] =1043.086914;
		Teleport_five[2] =0.031250;
		
		Teleport_six[0] =4162.800293;
		Teleport_six[1] =-354.220123;
		Teleport_six[2] =0.031250;
		
		Teleport_seven[0] =2273.662598;
		Teleport_seven[1] =-1409.492554;
		Teleport_seven[2] =	0.031250;
		
		Teleport_eight[0] =2202.024902;
		Teleport_eight[1] =-1560.998169;
		Teleport_eight[2] =2.652479	;	
		
		Teleport_nine[0] =4618.979492;
		Teleport_nine[1] =-1700.031250;
		Teleport_nine[2] =0.031250;
		
		Teleport_ten[0] =3401.499512;
		Teleport_ten[1] =1007.124573;
		Teleport_ten[2] =0.031250;		
		
		
		Red_Teleport[0] =2123.169434;
		Red_Teleport[1] =1098.993408;
		Red_Teleport[2] =2.305975;
		
		Blue_Teleport[0] =3564.277344;
		Blue_Teleport[1] =-2094.656494;
		Blue_Teleport[2] =0.031250;		
		
		Boundaries[0] = 3339.542236;
		Boundaries[1] = -37.460201;
		Boundaries[2] = 7.823051;
		Distance=2100;
		
	}else if(strcmp(mapAbbriv, "c2m3") == 0){
		
		Teleport_one[0] =-494.387634;
		Teleport_one[1] =1656.597046;
		Teleport_one[2] =0.031250;
		
		Teleport_two[0] =-2626.977051;
		Teleport_two[1] =2804.427734;
		Teleport_two[2] =0.031250;
		
		Teleport_three[0] =179.189697;
		Teleport_three[1] =1842.552734;
		Teleport_three[2] =-7.983051;
		
		Teleport_four[0] =212.239670;
		Teleport_four[1] =1261.257690;
		Teleport_four[2] =-7.968750;
		
		Teleport_five[0] =-860.227539;
		Teleport_five[1] =2482.576660;
		Teleport_five[2] =0.031250;
		
		Teleport_six[0] =-625.572632;
		Teleport_six[1] =950.488403;
		Teleport_six[2] =2.153764;
		
		Teleport_seven[0] =-1642.726074;
		Teleport_seven[1] =1282.155396;
		Teleport_seven[2] =12.432203;
		
		Teleport_eight[0] =-1440.060303;
		Teleport_eight[1] =2015.724854;
		Teleport_eight[2] =39.825951;	
		
		Teleport_nine[0] =-2292.421387;
		Teleport_nine[1] =2097.669434;
		Teleport_nine[2] =0.031250;
		
		Teleport_ten[0] =-1645.500366;
		Teleport_ten[1] =1418.055542;
		Teleport_ten[2] =4.031250;	
		
		
		Red_Teleport[0] =-494.387634;
		Red_Teleport[1] =1656.597046;
		Red_Teleport[2] =0.031250;
		
		Blue_Teleport[0] =-2626.977051;
		Blue_Teleport[1] =2804.427734;
		Blue_Teleport[2] =0.031250;		
		
		Boundaries[0] = -1467.856323;
		Boundaries[1] = 1800.050903;
		Boundaries[2] = 0.003906;
		Distance=1800;
		
	}else if(strcmp(mapAbbriv, "c2m4") == 0){
		
		Teleport_one[0] =795.105713;
		Teleport_one[1] =1915.551758;
		Teleport_one[2] =-191.968750;
		
		Teleport_two[0] =-1750.966064;
		Teleport_two[1] =112.652779;
		Teleport_two[2] =-188.204208;	
		
		Teleport_three[0] =-1593.171997;
		Teleport_three[1] =111.142311;
		Teleport_three[2] =-187.557770;
		
		Teleport_four[0] =-2212.509033;
		Teleport_four[1] =951.852600;
		Teleport_four[2] =-191.968750;
		
		Teleport_five[0] =-1151.111816;
		Teleport_five[1] =911.331055;
		Teleport_five[2] =-191.968750;
		
		Teleport_six[0] =245.132370;
		Teleport_six[1] =1028.610352;
		Teleport_six[2] =-191.968750;
		
		Teleport_seven[0] =339.710175;
		Teleport_seven[1] =947.454712;
		Teleport_seven[2] =-191.968750;
		
		Teleport_eight[0] =-1939.982910;
		Teleport_eight[1] =917.093750;
		Teleport_eight[2] =-183.968750;
		
		Teleport_nine[0] =-920.544922;
		Teleport_nine[1] =951.968750;
		Teleport_nine[2] =-191.968750;
		
		Teleport_ten[0] =234.128647;
		Teleport_ten[1] =316.945129;
		Teleport_ten[2] =-191.968750;	
		
		
		Red_Teleport[0] =795.105713;
		Red_Teleport[1] =1915.551758;
		Red_Teleport[2] =-191.968750;
		
		Blue_Teleport[0] =-1750.966064;
		Blue_Teleport[1] =112.652779;
		Blue_Teleport[2] =-188.204208;		
		
		Boundaries[0] =-724.840698;
		Boundaries[1] =915.562317;
		Boundaries[2] =-153.552292;		
		Distance=1950;		
		
		
	}else if(strcmp(mapAbbriv, "c2m5") == 0){
		
		Teleport_one[0] =-1215.113525;
		Teleport_one[1] =3441.573242;
		Teleport_one[2] =-255.970276;
		
		Teleport_two[0] =-3828.233887;
		Teleport_two[1] =2843.329346;
		Teleport_two[2] =-255.968750;		
		
		Teleport_three[0] =-3413.824463;
		Teleport_three[1] =3480.743164;
		Teleport_three[2] =-255.968750;
		
		Teleport_four[0] =-1775.968750;
		Teleport_four[1] =3648.319580;
		Teleport_four[2] =-255.968750;
		
		Teleport_five[0] =-1043.062378;
		Teleport_five[1] =3572.859131;
		Teleport_five[2] =-255.968750;
		
		Teleport_six[0] =-2019.312378;
		Teleport_six[1] =1761.371948;
		Teleport_six[2] =128.031250;
		
		Teleport_seven[0] =-2891.968750;
		Teleport_seven[1] =3239.078125;
		Teleport_seven[2] =-255.968750;
		
		Teleport_eight[0] =-2202.848633;
		Teleport_eight[1] =2480.031250;
		Teleport_eight[2] =-255.968750;
		
		Teleport_nine[0] =-1868.324219;
		Teleport_nine[1] =3259.167236;
		Teleport_nine[2] =-175.968750;
		
		Teleport_ten[0] =-4264.638184;
		Teleport_ten[1] =3261.321777;
		Teleport_ten[2] =-255.968750;	
		
		Red_Teleport[0] =-1215.113525;
		Red_Teleport[1] =3441.573242;
		Red_Teleport[2] =-255.970276;
		
		Blue_Teleport[0] =-3828.233887;
		Blue_Teleport[1] =2843.329346;
		Blue_Teleport[2] =-255.968750;
		
		Boundaries[0] =-2289.593750;
		Boundaries[1] =3086.514893;
		Boundaries[2] =-160.822678;	
		Distance=2000;//look into fixing this
		CreateTimer(1.0, CarnivalFIVEissue, _, TIMER_REPEAT);
		
	}else if(strcmp(mapAbbriv, "c3m1") == 0){
		mapNum=SWAMP_FEVER;
		Teleport_one[0] =-6393.469238;
		Teleport_one[1] =6301.667969;
		Teleport_one[2] =32.031250;
		
		Teleport_two[0] =-7901.903809;
		Teleport_two[1] =9141.168945;
		Teleport_two[2] =32.031250;
		
		Teleport_three[0] =-7575.572754;
		Teleport_three[1] =8556.037109;
		Teleport_three[2] =59.114105;
		
		Teleport_four[0] =-8370.018555;
		Teleport_four[1] =6989.968750;
		Teleport_four[2] =72.031250;
		
		Teleport_five[0] =-7434.054688;
		Teleport_five[1] =6411.430176;
		Teleport_five[2] =32.031250;
		
		Teleport_six[0] =-6950.468750;
		Teleport_six[1] =7695.968750;
		Teleport_six[2] =72.031250;
		
		Teleport_seven[0] =-6351.997070;
		Teleport_seven[1] =6614.743652;
		Teleport_seven[2] =176.031250;
		
		Teleport_eight[0] =-6244.038574;
		Teleport_eight[1] =6172.188477;
		Teleport_eight[2] =31.913689;	
		
		Teleport_nine[0] =-6343.968750;
		Teleport_nine[1] =7731.586914;
		Teleport_nine[2] =48.031250;
		
		Teleport_ten[0] =-7230.401367;
		Teleport_ten[1] =6341.831543;
		Teleport_ten[2] =31.829853;
		
		Red_Teleport[0] =-6393.469238;
		Red_Teleport[1] =6301.667969;
		Red_Teleport[2] =32.031250;
		
		Blue_Teleport[0] =-7901.903809;
		Blue_Teleport[1] =9141.168945;
		Blue_Teleport[2] =32.031250;		
		
		Boundaries[0] =-7691.720703;
		Boundaries[1] =7420.656738;
		Boundaries[2] =21.565887;		
		Distance=2500;	
		
	}else if(strcmp(mapAbbriv, "c3m2") == 0){
		
		Teleport_one[0] =-7981.806641;
		Teleport_one[1] =5318.413574;
		Teleport_one[2] =-23.968750;
		
		Teleport_two[0] =-4708.387207;
		Teleport_two[1] =4502.607422;
		Teleport_two[2] =-2.349848;	
		
		
		Teleport_three[0] =-5438.197266;
		Teleport_three[1] =2944.413330;
		Teleport_three[2] =10.604512;
		
		Teleport_four[0] =-6771.253418;
		Teleport_four[1] =3325.010010;
		Teleport_four[2] =16.031250;
		
		Teleport_five[0] =-7130.129395;
		Teleport_five[1] =4087.310059;
		Teleport_five[2] =20.542974;
		
		Teleport_six[0] =-5508.161621;
		Teleport_six[1] =5623.572266;
		Teleport_six[2] =-25.813213;
		
		Teleport_seven[0] =-6655.711914;
		Teleport_seven[1] =5549.508789;
		Teleport_seven[2] =-8.843838;
		
		Teleport_eight[0] =-5074.096680;
		Teleport_eight[1] =5382.436035;
		Teleport_eight[2] =15.355801;	
		
		Teleport_nine[0] =-4878.144043;
		Teleport_nine[1] =3001.504395;
		Teleport_nine[2] =10.617865;
		
		Teleport_ten[0] =-5439.272461;
		Teleport_ten[1] =4307.103516;
		Teleport_ten[2] =20.091434;
		
		Red_Teleport[0] =-7981.806641;
		Red_Teleport[1] =5318.413574;
		Red_Teleport[2] =-23.968750;
		
		Blue_Teleport[0] =-4708.387207;
		Blue_Teleport[1] =4502.607422;
		Blue_Teleport[2] =-2.349848;		
		
		Boundaries[0] =-6140.144043;
		Boundaries[1] =4473.060547;
		Boundaries[2] =-1.799131;		
		Distance=2500;	
		
	}else if(strcmp(mapAbbriv, "c3m3") == 0){
		
		Teleport_one[0] =-5405.226074;
		Teleport_one[1] =-1437.612427;
		Teleport_one[2] =99.031250;		
		
		Teleport_two[0] =-3886.470215;
		Teleport_two[1] =-3010.539551;
		Teleport_two[2] =62.502365;	
		
		
		Teleport_three[0] =-3968.031250;
		Teleport_three[1] =-2011.822876;
		Teleport_three[2] =5.531250;
		
		Teleport_four[0] =-5736.059082;
		Teleport_four[1] =-2071.895752;
		Teleport_four[2] =92.275291;
		
		Teleport_five[0] =-4117.805664;
		Teleport_five[1] =-2497.968750;
		Teleport_five[2] =123.031250;
		
		Teleport_six[0] =-5358.367188;
		Teleport_six[1] =-3298.479980;
		Teleport_six[2] =115.680252;
		
		Teleport_seven[0] =-4657.848145;
		Teleport_seven[1] =-2183.972412;
		Teleport_seven[2] =-5.025378;
		
		Teleport_eight[0] =-4996.526855;
		Teleport_eight[1] =-522.019531;
		Teleport_eight[2] =-2.621494;	
		
		Teleport_nine[0] =-4202.071289;
		Teleport_nine[1] =-3704.802002;
		Teleport_nine[2] =-1.972394;
		
		Teleport_ten[0] =-3560.968750;
		Teleport_ten[1] =-1832.427734;
		Teleport_ten[2] =2.229663;
		
		Blue_Teleport[0] =-5405.226074;
		Blue_Teleport[1] =-1437.612427;
		Blue_Teleport[2] =99.031250;		
		
		Red_Teleport[0] =-3886.470215;
		Red_Teleport[1] =-3010.539551;
		Red_Teleport[2] =62.502365;		
		
		Boundaries[0] =-4861.828613;
		Boundaries[1] =-2136.437256;
		Boundaries[2] =100.944084;		
		Distance=2500;	
		
	}else if(strcmp(mapAbbriv, "c3m4") == 0){
		
		Teleport_one[0] =580.253296;
		Teleport_one[1] =1618.397461;
		Teleport_one[2] =128.031250;
		
		Teleport_two[0] =2764.817627;
		Teleport_two[1] =1554.649414;
		Teleport_two[2] =128.031250;			
		
		Teleport_three[0] =1871.968750;
		Teleport_three[1] =-537.968750;
		Teleport_three[2] =416.031250;
		
		Teleport_four[0] =1323.076782;
		Teleport_four[1] =72.031250;
		Teleport_four[2] =416.031250;
		
		Teleport_five[0] =2616.031250;
		Teleport_five[1] =-160.665512;
		Teleport_five[2] =224.031250;
		
		Teleport_six[0] =2751.987061 ;
		Teleport_six[1] =-472.031250;
		Teleport_six[2] =224.031250;
		
		Teleport_seven[0] =1260.860107;
		Teleport_seven[1] =1306.476929;
		Teleport_seven[2] =128.031250;
		
		Teleport_eight[0] =2383.968750;
		Teleport_eight[1] =18.985788;
		Teleport_eight[2] =132.729996;	
		
		Teleport_nine[0] =2224.000000;
		Teleport_nine[1] =1160.663086;
		Teleport_nine[2] =128.031250;
		
		Teleport_ten[0] =280.031250;
		Teleport_ten[1] =1576.031250;
		Teleport_ten[2] =134.230255;
		
		Red_Teleport[0] =580.253296;
		Red_Teleport[1] =1618.397461;
		Red_Teleport[2] =128.031250;
		
		Blue_Teleport[0] =2764.817627;
		Blue_Teleport[1] =1554.649414;
		Blue_Teleport[2] =128.031250;		
		
		Boundaries[0] =1783.476807;
		Boundaries[1] =906.364014;
		Boundaries[2] =168.031250;		
		Distance=2500;	
		
	}else if(strcmp(mapAbbriv, "c4m1") == 0){
		mapNum=HARD_RAIN;
		
		Teleport_one[0] =99.314781;
		Teleport_one[1] =5628.992676;
		Teleport_one[2] =104.031250;
		
		Teleport_two[0] =1555.999268;
		Teleport_two[1] =4150.543457;
		Teleport_two[2] =217.304245;	
		
		
		Teleport_three[0] =-27.153784;
		Teleport_three[1] =4298.997559;
		Teleport_three[2] =104.031250;
		
		Teleport_four[0] =-284.183960;
		Teleport_four[1] =4211.544434;
		Teleport_four[2] =104.031250;
		
		Teleport_five[0] =1486.424316;
		Teleport_five[1] =5597.703125;
		Teleport_five[2] =99.977478;
		
		Teleport_six[0] =1210.776978;
		Teleport_six[1] =5174.988770;
		Teleport_six[2] =103.840080;
		
		Teleport_seven[0] =-111.705147;
		Teleport_seven[1] = 5551.968750;
		Teleport_seven[2] =97.070641;
		
		Teleport_eight[0] =-438.033295;
		Teleport_eight[1] =6168.031250;
		Teleport_eight[2] =104.031250;	
		
		Teleport_nine[0] =-399.968750;
		Teleport_nine[1] = 6420.031250;
		Teleport_nine[2] =104.031250;
		
		Teleport_ten[0] =1270.526367;
		Teleport_ten[1] =6147.178223;
		Teleport_ten[2] =120.281250;
		
		Boundaries[0] =687.601501;
		Boundaries[1] =4960.415527;
		Boundaries[2] =96.031250;
		
		Red_Teleport[0] =99.314781;
		Red_Teleport[1] =5628.992676;
		Red_Teleport[2] =104.031250;
		
		Blue_Teleport[0] =1555.999268;
		Blue_Teleport[1] =4150.543457;
		Blue_Teleport[2] =217.304245;
		
		Distance=2500;	
		
	}else if(strcmp(mapAbbriv, "c4m2") == 0){
		Teleport_one[0] =2196.249268;
		Teleport_one[1] =-5606.818848;
		Teleport_one[2] =104.281250;
		
		Teleport_two[0] =473.949005;
		Teleport_two[1] =-5340.178711;
		Teleport_two[2] =96.281357;	
		
		
		Teleport_three[0] =473.949005;
		Teleport_three[1] =-5340.178711;
		Teleport_three[2] =96.281357;
		
		Teleport_four[0] =1265.857178;
		Teleport_four[1] =-5349.031250;
		Teleport_four[2] =96.281250;
		
		Teleport_five[0] =1497.377197;
		Teleport_five[1] =-6104.031250;
		Teleport_five[2] =104.281250;
		
		Teleport_six[0] =1371.401245;
		Teleport_six[1] =-5377.340332;
		Teleport_six[2] =228.281250;
		
		Teleport_seven[0] =1268.607300;
		Teleport_seven[1] =-6109.473145;
		Teleport_seven[2] =101.281250;
		
		Teleport_eight[0] =2044.272949;
		Teleport_eight[1] =-5568.528320;
		Teleport_eight[2] =228.294586;	
		
		Teleport_nine[0] =1327.968750;
		Teleport_nine[1] =-5348.031250;
		Teleport_nine[2] =228.281250;
		
		Teleport_ten[0] =725.222107;
		Teleport_ten[1] =-6319.968750;
		Teleport_ten[2] =101.643707;
		
		Red_Teleport[0] =2196.249268;
		Red_Teleport[1] =-5606.818848;
		Red_Teleport[2] =104.281250;
		
		Blue_Teleport[0] =473.949005;
		Blue_Teleport[1] =-5340.178711;
		Blue_Teleport[2] =96.281357;		
		
		Boundaries[0] =1280.121216;
		Boundaries[1] =-5747.871094;
		Boundaries[2] =228.281250;		
		Distance=2600;	
		
	}else if(strcmp(mapAbbriv, "c4m3") == 0){
		Teleport_one[0] =1438.537964;
		Teleport_one[1] =-4015.801270;
		Teleport_one[2] =104.484886;
		
		Teleport_two[0] =3468.467529;
		Teleport_two[1] =-4041.128906;
		Teleport_two[2] =112.888054;	
		
		
		Teleport_three[0] =2709.257080;
		Teleport_three[1] =-3616.031250;
		Teleport_three[2] =100.031250;
		
		Teleport_four[0] =3061.199219;
		Teleport_four[1] =-3619.332275;
		Teleport_four[2] =100.031250;
		
		Teleport_five[0] =3139.820313;
		Teleport_five[1] =-4792.254395;
		Teleport_five[2] =104.327911;
		
		Teleport_six[0] =2179.134766;
		Teleport_six[1] =-3891.968750;
		Teleport_six[2] =97.214859;
		
		Teleport_seven[0] =1834.684937;
		Teleport_seven[1] =-4831.968750;
		Teleport_seven[2] =96.031250;
		
		Teleport_eight[0] =866.793823;
		Teleport_eight[1] =-4178.637207;
		Teleport_eight[2] =96.031250;	
		
		Teleport_nine[0] =2087.427734;
		Teleport_nine[1] =-4703.204102;
		Teleport_nine[2] =267.262238;
		
		Teleport_ten[0] =3838.061768;
		Teleport_ten[1] =-4822.259766;
		Teleport_ten[2] =97.384552;
		
		Red_Teleport[0] =1438.537964;
		Red_Teleport[1] =-4015.801270;
		Red_Teleport[2] =104.484886;
		
		Blue_Teleport[0] =3468.467529;
		Blue_Teleport[1] =-4041.128906;
		Blue_Teleport[2] =112.888054;
		
		Boundaries[0] =2543.530029;
		Boundaries[1] =-4206.227539;
		Boundaries[2] =101.431183;		
		Distance=2800;	
		
	}else if(strcmp(mapAbbriv, "c4m4") == 0){
		Teleport_one[0] =3597.994385;
		Teleport_one[1] =-505.340393;
		Teleport_one[2] =96.031250;
		
		Teleport_two[0] =4109.449219;
		Teleport_two[1] =1549.609009;
		Teleport_two[2] =184.031250;	
		
		
		Teleport_three[0] =3967.574463;
		Teleport_three[1] =518.804810;
		Teleport_three[2] =101.031250;
		
		Teleport_four[0] =2842.533447;
		Teleport_four[1] =-103.276505;
		Teleport_four[2] =113.068703;
		
		Teleport_five[0] =3597.779785;
		Teleport_five[1] =658.104065;
		Teleport_five[2] =101.031250;
		
		Teleport_six[0] =4174.666504;
		Teleport_six[1] =1277.448730;
		Teleport_six[2] =184.031250;
		
		Teleport_seven[0] =3560.645508;
		Teleport_seven[1] =590.565613;
		Teleport_seven[2] =96.057503;
		
		Teleport_eight[0] =2900.933838;
		Teleport_eight[1] =1081.235962;
		Teleport_eight[2] =101.031250;	
		
		Teleport_nine[0] =4213.334961;
		Teleport_nine[1] =2282.618164;
		Teleport_nine[2] =96.031250;
		
		Teleport_ten[0] =4284.742676;
		Teleport_ten[1] =1700.031250;
		Teleport_ten[2] =184.031250;
		
		Blue_Teleport[0] =3597.994385;
		Blue_Teleport[1] =-505.340393;
		Blue_Teleport[2] =96.031250;
		
		Red_Teleport[0] =4109.449219;
		Red_Teleport[1] =1549.609009;
		Red_Teleport[2] =184.031250;		
		
		Boundaries[0] =1330.963013;
		Boundaries[1] =3642.415771;
		Boundaries[2] =120.566513;		
		Distance=3000;	
		
	}else if(strcmp(mapAbbriv, "c4m5") == 0){
		Teleport_one[0] =-5860.162598;
		Teleport_one[1] =8709.470703;
		Teleport_one[2] =110.072830;
		
		Teleport_two[0] =-5424.406738;
		Teleport_two[1] =6702.795410;
		Teleport_two[2] =99.112671;	
		
		
		Teleport_three[0] =-4708.188477;
		Teleport_three[1] =7158.410645;
		Teleport_three[2] =141.372116;
		
		Teleport_four[0] =-4712.473145;
		Teleport_four[1] =7809.742188;
		Teleport_four[2] = 100.796051;
		
		Teleport_five[0] =-4544.031250;
		Teleport_five[1] =8605.516602;
		Teleport_five[2] =96.031250;
		
		Teleport_six[0] =-6140.893066;
		Teleport_six[1] =7215.007813;
		Teleport_six[2] =104.031250;
		
		Teleport_seven[0] =-6328.896484;
		Teleport_seven[1] =6661.428223;
		Teleport_seven[2] =115.525978;
		
		Teleport_eight[0] =-5814.278320;
		Teleport_eight[1] =6636.455566;
		Teleport_eight[2] =100.347252;	
		
		Teleport_nine[0] =-6663.779785;
		Teleport_nine[1] =8032.242188;
		Teleport_nine[2] =96.031250;
		
		Teleport_ten[0] =-6890.278809;
		Teleport_ten[1] =7221.724609 ;
		Teleport_ten[2] =99.472672;
		
		Red_Teleport[0] =-5860.162598;
		Red_Teleport[1] =8709.470703;
		Red_Teleport[2] =110.072830;
		
		Blue_Teleport[0] =-5424.406738;
		Blue_Teleport[1] =6702.795410;
		Blue_Teleport[2] =99.112671;	
		
		Boundaries[0] =-5510.006836;
		Boundaries[1] =7404.557129;
		Boundaries[2] =250.604492;		
		Distance=3000;	
		
	}else if(strcmp(mapAbbriv, "c5m1") == 0){
		mapNum=THE_PARISH;
		
		Teleport_one[0] =780.423828;
		Teleport_one[1] =222.134689;
		Teleport_one[2] =-405.425446;
		
		Teleport_two[0] =-1434.104736;
		Teleport_two[1] =-87.880737;
		Teleport_two[2] =-375.968750;
		
		Teleport_three[0] =-1159.296875;
		Teleport_three[1] =-624.889954;
		Teleport_three[2] =-375.968750;
		
		Teleport_four[0] =302.572449;
		Teleport_four[1] =-340.031250;
		Teleport_four[2] =-367.968750;
		
		Teleport_five[0] =236.069717;
		Teleport_five[1] =1012.221436;
		Teleport_five[2] =-375.968750;
		
		Teleport_six[0] =-768.600464;
		Teleport_six[1] =-1132.011719;
		Teleport_six[2] =-374.234741;
		
		Teleport_seven[0] =-676.031250;
		Teleport_seven[1] =-438.113983;
		Teleport_seven[2] =-375.968750;
		
		Teleport_eight[0] =538.255066;
		Teleport_eight[1] =-259.981110;
		Teleport_eight[2] =-375.969086;	
		
		Teleport_nine[0] =-143.968750;
		Teleport_nine[1] =-303.968750;
		Teleport_nine[2] =	-360.968750;
		
		Teleport_ten[0] =-428.031250;
		Teleport_ten[1] =80.031250;
		Teleport_ten[2] =-371.176208;		
		
		Red_Teleport[0] =780.423828;
		Red_Teleport[1] =222.134689;
		Red_Teleport[2] =-405.425446;
		
		Blue_Teleport[0] =-1434.104736;
		Blue_Teleport[1] =-87.880737;
		Blue_Teleport[2] =-375.968750;
		
		Boundaries[0] =-456.285919;
		Boundaries[1] =236.299316;
		Boundaries[2] =-175.405563;	
		Distance=1550;//look into fixing this	
		
	}else if(strcmp(mapAbbriv, "c5m2") == 0){
		
		Teleport_one[0] =-6955.127441;
		Teleport_one[1] =-3879.360352;
		Teleport_one[2] =-231.215958;
		
		Teleport_two[0] =-7582.555176;
		Teleport_two[1] =-755.994873;
		Teleport_two[2] =-255.968750;	
		
		Teleport_three[0] =-7820.679688;
		Teleport_three[1] =-2248.031250;
		Teleport_three[2] =-255.369537;
		
		Teleport_four[0] =-6067.071289;
		Teleport_four[1] =-2888.528564;
		Teleport_four[2] =-255.954834;
		
		Teleport_five[0] =-5983.900391;
		Teleport_five[1] =-1736.702515;
		Teleport_five[2] =-252.346024;
		
		Teleport_six[0] =-8048.560547;
		Teleport_six[1] =-1158.968750;
		Teleport_six[2] =-255.968750;
		
		Teleport_seven[0] =-8238.960938;
		Teleport_seven[1] =-1680.031128;
		Teleport_seven[2] =-255.915390;
		
		Teleport_eight[0] =-8193.586914;
		Teleport_eight[1] =-2765.715332;
		Teleport_eight[2] =-248.199356;	
		
		Teleport_nine[0] =-6617.390625;
		Teleport_nine[1] =-3131.939697;
		Teleport_nine[2] =-255.829636	;
		
		Teleport_ten[0] =-6810.907227;
		Teleport_ten[1] =-2643.885742;
		Teleport_ten[2] =-240.620331;
		
		Red_Teleport[0] =-6955.127441;
		Red_Teleport[1] =-3879.360352;
		Red_Teleport[2] =-231.215958;
		
		Blue_Teleport[0] =-7582.555176;
		Blue_Teleport[1] =-755.994873;
		Blue_Teleport[2] =-255.968750;		
		
		Boundaries[0] =-6408.555664;
		Boundaries[1] =-2202.894531;
		Boundaries[2] =-9.014391;	
		Distance=2500;//look into fixing this	
		
	}else if(strcmp(mapAbbriv, "c5m3") == 0){
		
		Teleport_one[0] =5616.923828;
		Teleport_one[1] =973.939514;
		Teleport_one[2] =23.559608;
		
		Teleport_two[0] =6264.450195;
		Teleport_two[1] =-1801.274170;
		Teleport_two[2] =12.317764;	
		
		Teleport_three[0] =5644.120605;
		Teleport_three[1] =510.037323;
		Teleport_three[2] =21.857393;
		
		Teleport_four[0] =5626.897949;
		Teleport_four[1] =-981.118591;
		Teleport_four[2] =14.399786;
		
		Teleport_five[0] =6241.017578;
		Teleport_five[1] =-894.435608;
		Teleport_five[2] =0.800892;
		
		Teleport_six[0] =5542.444824;
		Teleport_six[1] =-1716.718750;
		Teleport_six[2] =15.571950;
		
		Teleport_seven[0] =6296.479492;
		Teleport_seven[1] =665.774475;
		Teleport_seven[2] =15.160362;
		
		Teleport_eight[0] =5942.061523;
		Teleport_eight[1] =472.777954;
		Teleport_eight[2] =-223.968750;	
		
		Teleport_nine[0] =6353.860352;
		Teleport_nine[1] =-1714.718750;
		Teleport_nine[2] =22.953022;
		
		Teleport_ten[0] =5524.271973;
		Teleport_ten[1] =-695.316711;
		Teleport_ten[2] =22.725124;
		
		Red_Teleport[0] =5616.923828;
		Red_Teleport[1] =973.939514;
		Red_Teleport[2] =23.559608;
		
		Blue_Teleport[0] =6264.450195;
		Blue_Teleport[1] =-1801.274170;
		Blue_Teleport[2] =12.317764;		
		
		Boundaries[0] =5949.443848;
		Boundaries[1] =-787.862366;
		Boundaries[2] =65.144287;	
		Distance=2200;
		
		
	}else if(strcmp(mapAbbriv, "c5m4") == 0){
		
		
		Teleport_one[0] =-953.346252;
		Teleport_one[1] =-1170.468018;
		Teleport_one[2] =96.031250;
		
		Teleport_two[0] =-2289.727295;
		Teleport_two[1] =-544.066833;
		Teleport_two[2] =96.031250;	
		
		
		Teleport_three[0] =-1867.977051;
		Teleport_three[1] =-1187.034302;
		Teleport_three[2] =66.531250;
		
		Teleport_four[0] =-1987.424805;
		Teleport_four[1] =-607.968750;
		Teleport_four[2] =96.031250;
		
		Teleport_five[0] =-1703.968750;
		Teleport_five[1] =-392.031250;
		Teleport_five[2] =65.418457;
		
		Teleport_six[0] =-550.386414;
		Teleport_six[1] =-1095.968750;
		Teleport_six[2] =68.403954;
		
		Teleport_seven[0] =-2650.262695;
		Teleport_seven[1] =-194.126038;
		Teleport_seven[2] =96.031250;
		
		Teleport_eight[0] =-1421.924683;
		Teleport_eight[1] =-1377.501587;
		Teleport_eight[2] =96.031250;	
		
		Teleport_nine[0] =-707.749390;
		Teleport_nine[1] =-1522.981445;
		Teleport_nine[2] =96.031250;
		
		Teleport_ten[0] =-1610.530151;
		Teleport_ten[1] =-1135.999878;
		Teleport_ten[2] =65.031250;
		
		Red_Teleport[0] =-953.346252;
		Red_Teleport[1] =-1170.468018;
		Red_Teleport[2] =96.031250;
		
		Blue_Teleport[0] =-2289.727295;
		Blue_Teleport[1] =-544.066833;
		Blue_Teleport[2] =96.031250;		
		
		Boundaries[0] =-1442.212769;
		Boundaries[1] =-875.125549;
		Boundaries[2] =65.031250;		
		Distance=1500;//look into fixing this	
		
		
	}else if(strcmp(mapAbbriv, "c5m5") == 0){
		
		Teleport_one[0] =7197.040527;
		Teleport_one[1] =3931.021240;
		Teleport_one[2] =168.031250;
		
		Teleport_two[0] =9091.016602;
		Teleport_two[1] =2435.592041;
		Teleport_two[2] =192.515945;	
		
		Teleport_three[0] =7609.263184;
		Teleport_three[1] =2290.464844;
		Teleport_three[2] =198.441849;
		
		Teleport_four[0] =8095.696289;
		Teleport_four[1] =2763.911377;
		Teleport_four[2] =192.031250;
		
		Teleport_five[0] =8512.961914;
		Teleport_five[1] =3253.520508;
		Teleport_five[2] =192.031250;
		
		Teleport_six[0] =8511.822266;
		Teleport_six[1] =1622.526001;
		Teleport_six[2] =192.031250;
		
		Teleport_seven[0] =9196.787109;
		Teleport_seven[1] =1576.849487;
		Teleport_seven[2] =192.031250;
		
		Teleport_eight[0] =9142.831055;
		Teleport_eight[1] =4240.820801;
		Teleport_eight[2] =195.877640;	
		
		Teleport_nine[0] =8126.769531;
		Teleport_nine[1] =4130.198730;
		Teleport_nine[2] =128.031250;
		
		Teleport_ten[0] =9287.417969;
		Teleport_ten[1] =3611.020752;
		Teleport_ten[2] =202.958710;
		
		Red_Teleport[0] =7197.040527;
		Red_Teleport[1] =3931.021240;
		Red_Teleport[2] =168.031250;
		
		Blue_Teleport[0] =9091.016602;
		Blue_Teleport[1] =2435.592041;
		Blue_Teleport[2] =192.515945;	
		
		Boundaries[0] =8444.657227;
		Boundaries[1] =3577.036621;
		Boundaries[2] =313.641083;	
		Distance=1500;//look into fixing this		
		
		
		
	}else if(strcmp(mapAbbriv, "c6m1") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m3") == 0){
		
	}
	
}

PrintMidGameScore(client)
{
	decl players[MAXPLAYERS][2], i 
	new playercount 
	new String:text[256];
	for(i = 1; i <= MaxClients; i++) 
	{ 
		if(IsClientInGame(i) && !IsFakeClient(i))
		{ 
			players[playercount][0] = i 
			players[playercount++][1] = playerscore[i] 
		} 
	} 
	SortCustom2D(players,playercount,SortPlayerPoints)
	new Handle:TeamPanel = CreatePanel();
	SetPanelTitle(TeamPanel, "Free For All viewer");
	DrawPanelText(TeamPanel, " \n");
	
	for(i = 0; i < playercount; i++) 
	{ 
		//PrintToChatAll("\x04Rank \x03#%d: %N \x04with \x03%d \x04Kills",i+1,players[i][0],players[i][1]) 
		Format(text, sizeof(text), "#%d: %N %d Kills",i+1,players[i][0],players[i][1]);
		DrawPanelText(TeamPanel, text);
	} 
	SendPanelToClient(TeamPanel, client, TeamPanelHandler, 14);
	CloseHandle(TeamPanel);
} 

PrintMidGameScoreBonusGnome(client)
{
	decl players[MAXPLAYERS][2], i 
	new playercount 
	new String:text[256];
	for(i = 1; i <= MaxClients; i++) 
	{ 
		if(IsClientInGame(i) && !IsFakeClient(i))
		{ 
			players[playercount][0] = i 
			players[playercount++][1] = playerscore[i] 
		} 
	} 
	SortCustom2D(players,playercount,SortPlayerPoints)
	new Handle:TeamPanel = CreatePanel();
	SetPanelTitle(TeamPanel, "OddGnome Game viewer");
	DrawPanelText(TeamPanel, " \n");
	
	for(i = 0; i < playercount; i++) 
	{ 
		Format(text, sizeof(text), "#%d: %N %d Points",i+1,players[i][0],players[i][1]);
		DrawPanelText(TeamPanel, text);
	} 
	SendPanelToClient(TeamPanel, client, TeamPanelHandler, 14);
	CloseHandle(TeamPanel);
} 


PrintMidGameScoreBonusBoomer(client)
{
	decl players[MAXPLAYERS][2], i 
	new playercount 
	new String:text[256];
	for(i = 1; i <= MaxClients; i++) 
	{ 
		if(IsClientInGame(i) && !IsFakeClient(i))
		{ 
			players[playercount][0] = i 
			players[playercount++][1] = playerscore[i] 
		} 
	} 
	SortCustom2D(players,playercount,SortPlayerPoints)
	new Handle:TeamPanel = CreatePanel();
	SetPanelTitle(TeamPanel, "INFECTION Game viewer");
	DrawPanelText(TeamPanel, " \n");
	
	for(i = 0; i < playercount; i++) 
	{ 
		Format(text, sizeof(text), "#%d: %N %d infected",i+1,players[i][0],players[i][1]);
		DrawPanelText(TeamPanel, text);
	} 
	SendPanelToClient(TeamPanel, client, TeamPanelHandler, 14);
	CloseHandle(TeamPanel);
} 


PrintTeamsToClient(client)
{
	if (GetConVarInt(GameType)==1)
	{
		//1. count and save
		
		new NumSurvivorsRed = TeamPlayersRed();
		new NumSurvivorsBlue = TeamPlayersBlue();
		new teamcounts[3];
		new tempteam;
		new playerteams[MaxClients+1];
		new i, j = (MaxClients);
		for (i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				
				tempteam = TeamState[i] - 1 ;
				if (tempteam == 0 || tempteam == 1)
				{
					//PrintToChatAll("Tempteam=%i and player is %N", tempteam, i);
					
					playerteams[i-1] = tempteam
					teamcounts[tempteam]++;
					
				}
			}
			
			//just to be sure
			else playerteams[i-1] = -1;
		}
		
		//2. build panel
		new Handle:TeamPanel = CreatePanel();
		SetPanelTitle(TeamPanel, "Deathmatch Team Viewer");
		DrawPanelText(TeamPanel, " \n");
		
		new count;
		new sum;
		new String:text[256];
		//How many Clients ingame?
		for (i = 0; i < 2; i++) sum += teamcounts[i];
		
		//Draw Spectators count line
		Format(text, sizeof(text), "RED TEAM: %d Kills   (%d) Players\n" , Full_score_red, NumSurvivorsRed);
		DrawPanelText(TeamPanel, text);
		
		//Get & Draw Spectator Player Names
		count = 1;
		for (j = 0; j < MaxClients; j++)
		{
			if (playerteams[j] != 0) continue;
			Format(text, sizeof(text), "  %N %d Kills %d Deaths", (j + 1), playerscore[count], Deaths[count]);
			DrawPanelText(TeamPanel, text);
			count++;
		}
		DrawPanelText(TeamPanel, " \n");
		
		//Draw Survivors count line
		Format(text, sizeof(text), "BLUE TEAM:%d Kills   (%d) Players\n", Full_score_blue, NumSurvivorsBlue);
		DrawPanelText(TeamPanel, text);
		
		//Get & Draw Survivor Player Names
		count = 1;
		for (j = 0; j < MaxClients; j++)
		{
			if (playerteams[j] != 1) continue;
			Format(text, sizeof(text), "  %N %d Kills %d Deaths", (j + 1), playerscore[count], Deaths[count]);
			DrawPanelText(TeamPanel, text);
			count++;
		}
		DrawPanelText(TeamPanel, " \n");
		
		//Draw Total connected Players & Draw Final
		//Format(text, sizeof(text), "Connected: %d/%d", (teamcounts[1] - botcounts[1]), MaxClients);
		//DrawPanelText(TeamPanel, text);	
		
		SendPanelToClient(TeamPanel, client, TeamPanelHandler, 14);
		CloseHandle(TeamPanel);
	}
	
	
	
	if (GetConVarInt(GameType)==2)
	{
		new AllFighters = AllPlayers();
		new teamcounts[1];
		new tempteam;
		new playerteams[MaxClients+1];
		new i, j = (MaxClients);
		
		for (i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				tempteam = TeamState[i] - 1 ;
				if (tempteam == 0 || tempteam == 1)
				{
					playerteams[i-1] = tempteam
					teamcounts[tempteam]++;
				}
			}
			//just to be sure
			else playerteams[i-1] = -1;
		}
		
		
		//2. build panel
		new Handle:TeamPanel = CreatePanel();
		SetPanelTitle(TeamPanel, "FFA Deathmatch Viewer");
		DrawPanelText(TeamPanel, " \n");
		
		new count;
		new sum;
		new String:text[256];
		//How many Clients ingame?
		for (i = 0; i < 1; i++) sum += teamcounts[i];
		
		//Draw Spectators count line
		Format(text, sizeof(text), "Players:(%d)\n" , (AllFighters));
		DrawPanelText(TeamPanel, text);
		
		//Get & Draw Spectator Player Names
		count = 1;
		for (j = 0; j < MaxClients; j++)
		{
			if (playerteams[j] != 0) continue;
			Format(text, sizeof(text), "%d  %N %d Kills %d Deaths",count, (j + 1), playerscore[count], Deaths[count]);
			DrawPanelText(TeamPanel, text);
			count++;
			
		}
		DrawPanelText(TeamPanel, " \n");
		SendPanelToClient(TeamPanel, client, TeamPanelHandler, 10);
		CloseHandle(TeamPanel);
		
	}	
}

public TeamPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	//nothing to do
}  

public AllPlayers()
{
	new int=0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientConnected(i)) continue;
		if (!IsClientInGame(i))    continue;
		if (GetClientTeam(i) != 2) continue;
		if (IsFakeClient(i)) continue;
		int++;
	}
	return int;
}



public TeamPlayersRed()
{
	new int=0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientConnected(i)) continue;
		if (!IsClientInGame(i))    continue;
		if (GetClientTeam(i) != 2) continue;
		if (IsFakeClient(i)) continue;
		if(TeamState[i]!=RED_TEAM) continue;
		int++;
	}
	return int;
}

public TeamPlayersBlue()
{
	new int=0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientConnected(i)) continue;
		if (!IsClientInGame(i))    continue;
		if (GetClientTeam(i) != 2) continue;
		if (IsFakeClient(i)) continue;
		if(TeamState[i]!=BLUE_TEAM) continue;
		int++;
	}
	return int;
}	


stock CheatCommand(client, String:command[], String:arguments[] = "")
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}
/*
bool:IsPlayerBurning(i)
{
if(GetEntProp(i, Prop_Data, "m_fFlags") & FL_ONFIRE) return true;
else return false;
}
*/
stock GetAnyClient()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
		{
			return i;
		}
	}
	return 0;
}

stock DirectorCommand(client, String:command[])
{
	if (client)
	{
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s", command);
		SetCommandFlags(command, flags);
	}
}

stock IsPlayerBoomer(client)//to remove 
{
	decl String:playermodel[96];
	GetClientModel(client, playermodel, sizeof(playermodel));
	return (StrContains(playermodel, "boomer", false) > -1 || StrContains(playermodel, "boomette", false) > -1); 
}

bool:IsPlayerGhost(client)
{
	new isghost = GetEntData(client, propinfoghost, 1);
	
	if (isghost == 1) return true;
	else return false;
}
