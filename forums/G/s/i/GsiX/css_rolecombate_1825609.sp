#define PLUGIN_VERSION	"0.0.0"
/*
v 0.0.0 - credit to Bacardi for the set parent problem.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#define TEAM_S			1
#define TEAM_T			2
#define TEAM_CT			3

#define COST_HT			600
#define COST_SH			1200
#define COST_SA			1200
#define COST_SS			1200
#define COST_CD			1200
#define COST_GR			200

#define PREDATOR_MDL	"models/player/techknow/predator_v2/predator.mdl"
#define HUSK_MDL		"models/player/slow/mass_effect/husk/slow.mdl"
#define TESLA_MDL		"models/player/slow/fallout_3/tesla_power_armor/slow.mdl"
#define CLOUD_MDL		"models/player/knifelemon/cloud.mdl"
#define STAR_1_MDL		"models/player/slow/amberlyn/sm_galaxy/star/slow.mdl"
#define STAR_2_MDL		"models/player/slow/amberlyn/sm_galaxy/star/slow_2.mdl"
#define MUSHROOM_MDL	"models/player/slow/amberlyn/sm_galaxy/life_mushroom/slow.mdl"

#define BEAMSPRITE		"materials/sprites/laserbeam.vmt"
#define BEAMOBJECT		"models/Shells/shell_9mm.mdl"
#define FIRESPIRIT		"materials/particle/predator/fire_1.vmt"
#define FIRESPIRIT1		"materials/particle/predator/fire_1.vtf"

#define PREDATOR_HURT_1	"ambient/machines/zap1.wav"
#define PREDATOR_HURT_2	"ambient/machines/zap2.wav"
#define PREDATOR_HURT_3	"ambient/machines/zap3.wav"

#define C4_1			"statsme/c4timer_1.mp3"
#define C4_2			"statsme/c4timer_2.mp3"
#define C4_3			"statsme/c4timer_3.mp3"
#define C4_4			"statsme/c4timer_4.mp3"
#define C4_5			"statsme/c4timer_5.mp3"
#define C4_6			"statsme/c4timer_6.mp3"
#define C4_7			"statsme/c4timer_7.mp3"
#define C4_8			"statsme/c4timer_8.mp3"
#define C4_9			"statsme/c4timer_9.mp3"
#define C4_10			"statsme/c4timer_10.mp3"

#define EXPLODE			"weapons/hegrenade/explode4.wav"
#define TRANSFORM		"gungame/default/nade_level.mp3"
#define NORM_HEALTH		"ambient/water_splash1.wav"
#define SUPER_HEALTH	"ambient/water_splash3.wav"
#define SUPER_ARMOR		"items/ammopickup.wav"
#define SUPER_SPEED		"items/nvg_on.wav"
#define CLOCK_DEVIC		"ambient/machines/pneumatic_drill_3.wav"
#define TIME_OUT		"ambient/machines/steam_release_2.wav"
#define AMMO			"items/gift_pickup.wav"
#define INVALID			"buttons/bell1.wav"
#define BONUS			"gungame/default/gg_handicap.mp3"

#define KEVLAR_1		"custom/metal_box_impact_bullet1.wav"
#define KEVLAR_2		"custom/metal_box_impact_bullet2.wav"
#define KEVLAR_3		"custom/metal_box_impact_bullet3.wav"

#define FIRSTBLD		"quake/firstblood.mp3"
#define DOUBLEKL		"quake/doublekill.mp3"
#define TRIPLEKL		"quake/triplekill.mp3"
#define MONSTEKL		"quake/monsterkill.mp3"
#define ULTRAKL			"quake/ultrakill.mp3"
#define GODLIKE			"quake/godlike.mp3"

#define LUDICROU		"quake/ludicrouskill.mp3"
#define RAMPAGE			"quake/rampage.mp3"
#define WICKEDSIK		"quake/wickedsick.mp3"

#define DOMINATE		"quake/dominating.mp3"
#define COMBHOW			"quake/combowhore.mp3"
#define HATTRIC			"quake/hattrick.mp3"

#define HEADSHOT		"quake/headshot.mp3"
#define HOLLYSHT		"quake/holyshit.mp3"
#define HEADHUNT		"quake/headhunter.mp3"

#define FUN_1			"quake/killingspree.mp3"
#define FUN_2			"quake/unstoppable.mp3"

#define TEAM_KILLER		"quake/teamkiller.mp3"
#define PLAYER_SLAYED	"custom/slayed.mp3"

new Handle:g_RoleCombate;
new Handle:g_RespawnDelay;
new Handle:g_PredatorChance;
new Handle:g_TeamPlay_T;
new Handle:g_TeamPlay_CT;
new Handle:g_PredatorBoost;
new Handle:g_PredatorHP;
new Handle:g_AlienHP;
new Handle:g_HuskHP;
new Handle:g_PredatorNum;
new Handle:g_tStartMoney;
new Handle:g_cStartMoney;
new Handle:g_AllCT;
new Handle:g_StartUpGun;
new Handle:g_TimerServerMSG;
new Handle:g_TimerRespawn[MAXPLAYERS+1]		= { INVALID_HANDLE,... };
new Handle:g_TimerAddHP[MAXPLAYERS+1]		= { INVALID_HANDLE,... };
new Handle:g_TimerPredKillSnd[MAXPLAYERS+1]	= { INVALID_HANDLE,... };
new Handle:g_SuperSpeedTime[MAXPLAYERS+1]	= { INVALID_HANDLE,... };
new Handle:g_ClockDeviceTime[MAXPLAYERS+1]	= { INVALID_HANDLE,... };
new Handle:g_TerrorLife[MAXPLAYERS+1]		= { INVALID_HANDLE,... };
new Handle:g_EvaLife						= INVALID_HANDLE;
new Handle:g_KirbyLife						= INVALID_HANDLE;
new Handle:g_MaxLife						= INVALID_HANDLE;
new Handle:g_TimerLookUp					= INVALID_HANDLE;

new bool:g_WinItemRemoved					= false;
new bool:g_BotAdded							= false;
new bool:g_SpawnBtn[MAXPLAYERS+1]			= { false,... };

new Float:g_Boost;

new WeaponSlot[MAXPLAYERS+1][5];
new g_FunSound[MAXPLAYERS+1]		= { 0,... };
new g_AddHealth[MAXPLAYERS+1]		= { 0,... };
new g_PredKillSnd[MAXPLAYERS+1][2];
new g_ModelSet[MAXPLAYERS+1]		= { 0,... };
new g_PropCount[MAXPLAYERS+1]		= { 0,... };
new g_CountDown[MAXPLAYERS+1]		= { 0,... };
new g_iAccount[MAXPLAYERS+1]		= { 0,... };
new g_LastHealth[MAXPLAYERS+1]		= { 0,... };
new g_ClientBeamSP[MAXPLAYERS+1]	= { 0,... };
new g_TerrorID[MAXPLAYERS+1][3];
new g_LookUpExpired					= 0;
new g_SpecialTerrorCount			= 0;
new g_MaxPredator					= 0;
new g_WarmUp						= 0;
new g_BeamSprite;
new g_FireSprite;

new static m_iAccount;
new static m_hOwnerEntity;

static const String:CT_Models[4][] = { "models/player/ct_urban.mdl","models/player/ct_gsg9.mdl","models/player/ct_sas.mdl","models/player/ct_gign.mdl" };
static const String:T_Models[4][] = { "models/player/t_phoenix.mdl","models/player/t_leet.mdl","models/player/t_arctic.mdl","models/player/t_guerilla.mdl" };

#define PRIMARY		18
#define SECONDARY	6
new const String:PrimaryNames[PRIMARY][32] =
{
	"weapon_tmp",	"weapon_mp5navy",	"weapon_ump45",	"weapon_p90",	"weapon_ak47",	"weapon_m4a1",		"weapon_sg552",		"weapon_aug",	"weapon_galil",
	"weapon_famas",	"weapon_scout",		"weapon_m249",	"weapon_mac10",	"weapon_m3",	"weapon_xm1014",	"weapon_awp",		"weapon_g3sg1",	"weapon_sg550"
};
new const i_PrimaryData[PRIMARY][2] =
{
	{24, 120},	{24, 120},	{32, 100},	{40, 100},	{8, 90},	{12, 90},	{12, 90},	{8, 90},	{12, 90},
	{12, 90},	{8, 90},	{16, 200},	{32, 100},	{28, 32},	{28, 32},	{20, 30},	{8, 90},	{12, 90}
};

new const String:SecondaryNames[SECONDARY][32] = { "weapon_glock", "weapon_usp", "weapon_p228", "weapon_deagle", "weapon_elite", "weapon_fiveseven" };
new const i_SecondaryData[SECONDARY][2] = { {24, 120},	{32, 100},	{36, 52},	{4, 35},	{24, 120},	{40, 100} };

public Plugin:myinfo =
{
	name = "CSS Role Combat",
	author = "GsiX",
	description = "Human on CT side play against Predator on T side.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1825609#post1825609"
}

public OnPluginStart()
{
	m_iAccount			= FindSendPropOffs("CCSPlayer", "m_iAccount");
	m_hOwnerEntity		= FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	
	CreateConVar( "css_rolecombat_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_DONTRECORD );
	g_RoleCombate		= CreateConVar( "css_rolecombat_enabled",		"1",		"0:Off, 1:On,  Toggle plugin on/of?", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_RespawnDelay		= CreateConVar( "css_rolecombat_delayed",		"30.0",		"Timer delayed for player respawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_PredatorChance	= CreateConVar( "css_rolecombat_chance",		"50",		"0% - 100%, Chance terroris become predator", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_TeamPlay_T		= CreateConVar( "css_rolecombat_bot_t",			"10",		"How many bot added for T at map start", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_TeamPlay_CT		= CreateConVar( "css_rolecombat_bot_ct",		"0",		"How many bot added for CT at map start", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_tStartMoney		= CreateConVar( "css_rolecombat_bot_money_t",	"16000",	"0:Off, 1:On, Terror bot fix money (or any value but bigger than 0).", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_cStartMoney		= CreateConVar( "css_rolecombat_bot_money_c",	"16000",	"0:Off, 1:On, CTerror bot fix money (or any value but bigger than 0).", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_PredatorBoost		= CreateConVar( "css_rolecombat_boost",			"20",		"0% - 100%, How much speed boost added to predator", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_PredatorHP		= CreateConVar( "css_rolecombat_predator_hp",	"100",		"How much health for the predator", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_AlienHP			= CreateConVar( "css_rolecombat_alien_hp",		"100",		"How much health for the alien", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_HuskHP			= CreateConVar( "css_rolecombat_husk_hp",		"800",		"How much health for the husk", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_PredatorNum		= CreateConVar( "css_rolecombat_number",		"20",		"0% - 100%, Max predator on map at once depend on Terror number", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_AllCT				= CreateConVar( "css_rolecombat_all_ct",		"1",		"0:Off, 1:On, If on, all human player will be forced to CT team.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_StartUpGun		= CreateConVar( "css_rolecombat_startup_gun",	"0",		"0:Off, 1 and above = If player money below this number give him random SMG", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	HookEvent( "player_hurt",			EVENT_PlayerHurt );
	HookEvent( "player_spawn",			EVENT_PlayerSpawn );
	HookEvent( "round_start",			EVENT_RoundStart, EventHookMode_Post );
	HookEvent( "round_end",				EVENT_RoundEnd );
	HookEvent( "player_death",			EVENT_PlayerDeath );
	HookEvent( "item_pickup",			EVENT_ItemPickUp );
	HookEvent( "player_team",			EVENT_PlayerTeam );
	
	HookConVarChange( g_RoleCombate,	CVARChanged );
	
	RegConsoleCmd( "cs_buy", CmdBuyPoint, "Command open buy menu.");
}

public OnMapStart()
{
	g_WarmUp				= 0;
	g_MaxPredator			= 0;
	g_SpecialTerrorCount	= 0;
	g_LookUpExpired			= 0;
	g_BotAdded				= false;
	g_WinItemRemoved		= false;
	g_TimerLookUp			= INVALID_HANDLE;
	g_TimerServerMSG		= INVALID_HANDLE;
	g_EvaLife 				= INVALID_HANDLE;
	g_KirbyLife				= INVALID_HANDLE;
	g_MaxLife				= INVALID_HANDLE;
	
	for (new i = 0; i <= MaxClients; i++)
	{
		for (new m = 0; m <= 4; m++)
		{
			WeaponSlot[i][m] = -1;
		}
		g_LastHealth[i]				= 0;
		g_FunSound[i]				= 0;
		g_AddHealth[i]				= 0;
		g_iAccount[i]				= 0;
		g_TerrorID[i][0]			= 0;
		g_TerrorID[i][1]			= 0;
		g_TerrorID[i][2]			= 0;
		g_PropCount[i]				= 0;
		g_PredKillSnd[i][0]			= 0;
		g_PredKillSnd[i][1]			= 0;
		g_SpawnBtn[i]				= false;
		g_ModelSet[i]				= -1;
		g_ClientBeamSP[i]			= -1;
		g_TimerRespawn[i]			= INVALID_HANDLE;
		g_SuperSpeedTime[i]			= INVALID_HANDLE;
		g_TimerPredKillSnd[i]		= INVALID_HANDLE;
		g_TimerAddHP[i]				= INVALID_HANDLE;
		g_TerrorLife[i]			= INVALID_HANDLE;
	}
	Precache_Sound_Model();
	CreateTimer( 1.0, Timer_TweakCvar);
}

public OnMapEnd()
{
	SetConVarInt( FindConVar( "mp_roundtime" ),						5);
	SetConVarInt( FindConVar( "mp_autoteambalance" ),				0);
	SetConVarInt( FindConVar( "mp_buytime" ),						5);
	SetConVarInt( FindConVar( "mp_maxrounds" ),						20);
	SetConVarInt( FindConVar( "mp_ignore_round_win_conditions" ),	0);
}

public OnClientConnected( client )
{
	g_LastHealth[client]		= 0;
	g_CountDown[client]			= 0;
	g_PropCount[client]			= 0;
	g_ModelSet[client]			= -1;
	g_SpawnBtn[client]			= false;
	g_iAccount[client]			= 0;
	g_TerrorID[client][0]		= 0;
	g_TerrorID[client][1]		= 0;
	g_TerrorID[client][2]		= 0;
	g_AddHealth[client]			= 0;
	g_TimerRespawn[client]		= INVALID_HANDLE;
	g_SuperSpeedTime[client]	= INVALID_HANDLE;
	g_ClockDeviceTime[client]	= INVALID_HANDLE;
	g_TimerPredKillSnd[client]	= INVALID_HANDLE;
	g_TimerAddHP[client]		= INVALID_HANDLE;
	g_TerrorLife[client]		= INVALID_HANDLE;
	
	for (new m = 0; m <= 4; m++)
	{
		WeaponSlot[client][m] = -1;
	}
}

public OnClientDisconnect( client )
{
	g_LastHealth[client]		= 0;
	g_FunSound[client]			= 0;
	g_CountDown[client]			= 0;
	g_PropCount[client]			= 0;
	g_ModelSet[client]			= -1;
	g_SpawnBtn[client]			= false;
	g_iAccount[client]			= 0;
	g_TerrorID[client][0]		= 0;
	g_TerrorID[client][1]		= 0;
	g_TerrorID[client][2]		= 0;
	g_AddHealth[client]			= 0;
	
	for (new m = 0; m <= 4; m++)
	{
		WeaponSlot[client][m] = -1;
	}
		
	if ( g_TimerRespawn[client] != INVALID_HANDLE )
	{
		KillTimer( g_TimerRespawn[client] );
		g_TimerRespawn[client] = INVALID_HANDLE;
	}
	if ( g_SuperSpeedTime[client] != INVALID_HANDLE )
	{
		KillTimer( g_SuperSpeedTime[client] );
		g_SuperSpeedTime[client] = INVALID_HANDLE;
	}
	if ( g_ClockDeviceTime[client] != INVALID_HANDLE )
	{
		KillTimer( g_ClockDeviceTime[client] );
		g_ClockDeviceTime[client] = INVALID_HANDLE;
	}
	if ( g_TimerAddHP[client] != INVALID_HANDLE )
	{
		KillTimer( g_TimerAddHP[client] );
		g_TimerAddHP[client] = INVALID_HANDLE;
	}
	if ( g_TimerPredKillSnd[client]	!= INVALID_HANDLE )
	{
		KillTimer( g_TimerPredKillSnd[client] );
		g_TimerPredKillSnd[client]	= INVALID_HANDLE;
	}
}

Precache_Sound_Model()
{
	AddFileToDownloadsTable( "materials/models/player/techknow/predator/chest.vmt" );
	AddFileToDownloadsTable( "materials/models/player/techknow/predator/chest.vtf" );
	AddFileToDownloadsTable( "materials/models/player/techknow/predator/chest_n.vtf" );
	AddFileToDownloadsTable( "materials/models/player/techknow/predator/crop.vtf" );
	AddFileToDownloadsTable( "materials/models/player/techknow/predator/crop.vmt" );
	AddFileToDownloadsTable( "materials/models/player/techknow/predator/crop_n.vtf" );
	AddFileToDownloadsTable( "materials/models/player/techknow/predator/head.vmt" );
	AddFileToDownloadsTable( "materials/models/player/techknow/predator/head.vtf" );
	AddFileToDownloadsTable( "materials/models/player/techknow/predator/head_n.vtf" );
	AddFileToDownloadsTable( "models/player/techknow/predator_v2/predator.dx80.vtx" );
	AddFileToDownloadsTable( "models/player/techknow/predator_v2/predator.dx90.vtx" );
	AddFileToDownloadsTable( "models/player/techknow/predator_v2/predator.phy" );
	AddFileToDownloadsTable( "models/player/techknow/predator_v2/predator.sw.vtx" );
	AddFileToDownloadsTable( "models/player/techknow/predator_v2/predator.vvd" );
	AddFileToDownloadsTable( PREDATOR_MDL );
	
	AddFileToDownloadsTable( "materials/models/player/slow/mass_effect/husk/slow_body.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/mass_effect/husk/slow_body.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/mass_effect/husk/slow_body_bump.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/mass_effect/husk/slow_body_exp.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/mass_effect/husk/slow_eyes_glow.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/mass_effect/husk/slow_eyes_glow.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/mass_effect/husk/slow_head.vmt" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow.dx80.vtx" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow.dx90.vtx" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow.phy" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow.sw.vtx" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow.vvd" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow_head.dx80.vtx" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow_head.dx90.vtx" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow_head.mdl" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow_head.phy" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow_head.sw.vtx" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow_head.vvd" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow_hs.dx80.vtx" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow_hs.dx90.vtx" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow_hs.mdl" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow_hs.phy" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow_hs.sw.vtx" );
	AddFileToDownloadsTable( "models/player/slow/mass_effect/husk/slow_hs.vvd" );
	AddFileToDownloadsTable( HUSK_MDL );
	
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_addon.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_addon.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_addon_bump.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_body.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_body.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_body_bump.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_cables.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_copper.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_eyes.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_1.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_10.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_11.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_12.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_13.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_14.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_2.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_3.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_5.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_6.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_7.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_8.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_fx_9.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_glow.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_glow.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_hands.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_hands.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_hands_bump.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_helmet.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_helmet.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_helmet_bump.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_knee_pads.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_tesla_glass.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_tesla_glass.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_tesla_glass_2.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_tesla_glass_bump.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_tesla_pack_glow.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/fallout_3/tesla_power_armor/slow_tesla_pack_glow.vtf" );
	AddFileToDownloadsTable( "models/player/slow/fallout_3/tesla_power_armor/slow.dx80.vtx" );
	AddFileToDownloadsTable( "models/player/slow/fallout_3/tesla_power_armor/slow.dx90.vtx" );
	AddFileToDownloadsTable( "models/player/slow/fallout_3/tesla_power_armor/slow.phy" );
	AddFileToDownloadsTable( "models/player/slow/fallout_3/tesla_power_armor/slow.sw.vtx" );
	AddFileToDownloadsTable( "models/player/slow/fallout_3/tesla_power_armor/slow.vvd" );
	AddFileToDownloadsTable( TESLA_MDL );
	
	AddFileToDownloadsTable( "materials/cloud/eyeball_l.vmt" );
	AddFileToDownloadsTable( "materials/cloud/eyeball_l.vtf" );
	AddFileToDownloadsTable( "materials/cloud/eyeball_r.vmt" );
	AddFileToDownloadsTable( "materials/cloud/eyeball_r.vtf" );
	AddFileToDownloadsTable( "materials/cloud/Part1.vmt" );
	AddFileToDownloadsTable( "materials/cloud/Part1.vtf" );
	AddFileToDownloadsTable( "materials/cloud/Part2.vmt" );
	AddFileToDownloadsTable( "materials/cloud/Part2.vtf" );
	AddFileToDownloadsTable( "materials/cloud/Part3.vmt" );
	AddFileToDownloadsTable( "materials/cloud/Part3.vtf" );
	AddFileToDownloadsTable( "materials/cloud/Part4.vmt" );
	AddFileToDownloadsTable( "materials/cloud/Part4.vtf" );
	AddFileToDownloadsTable( "materials/cloud/pupil_l.vtf" );
	AddFileToDownloadsTable( "materials/cloud/pupil_r.vtf" );
	AddFileToDownloadsTable( "models/player/knifelemon/cloud.dx80.vtx" );
	AddFileToDownloadsTable( "models/player/knifelemon/cloud.dx90.vtx" );
	AddFileToDownloadsTable( "models/player/knifelemon/cloud.phy" );
	AddFileToDownloadsTable( "models/player/knifelemon/cloud.sw.vtx" );
	AddFileToDownloadsTable( "models/player/knifelemon/cloud.vvd" );
	AddFileToDownloadsTable( CLOUD_MDL );
	
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/star/slow.dx80.vtx" );
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/star/slow.dx90.vtx" );
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/star/slow.phy" );
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/star/slow.sw.vtx" );
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/star/slow.vvd" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/star/slow_body.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/star/slow_body.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/star/slow_body_2.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/star/slow_body_2.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/star/slow_eye.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/star/slow_eye.vtf" );
	AddFileToDownloadsTable( STAR_1_MDL );
	
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/star/slow_2.dx80.vtx" );
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/star/slow_2.dx90.vtx" );
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/star/slow_2.phy" );
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/star/slow_2.sw.vtx" );
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/star/slow_2.vvd" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/star/slow_body.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/star/slow_body.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/star/slow_body_2.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/star/slow_body_2.vtf" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/star/slow_eye.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/star/slow_eye.vtf" );
	AddFileToDownloadsTable( STAR_2_MDL );
	
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/life_mushroom/slow.dx80.vtx" );
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/life_mushroom/slow.dx90.vtx" );
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/life_mushroom/slow.phy" );
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/life_mushroom/slow.sw.vtx" );
	AddFileToDownloadsTable( "models/player/slow/amberlyn/sm_galaxy/life_mushroom/slow.vvd" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/life_mushroom/slow_body.vmt" );
	AddFileToDownloadsTable( "materials/models/player/slow/amberlyn/sm_galaxy/life_mushroom/slow_body.vtf" );
	AddFileToDownloadsTable( MUSHROOM_MDL );
	
	AddFileToDownloadsTable( C4_1 );
	AddFileToDownloadsTable( C4_2 );
	AddFileToDownloadsTable( C4_3 );
	AddFileToDownloadsTable( C4_4 );
	AddFileToDownloadsTable( C4_5 );
	AddFileToDownloadsTable( C4_6 );
	AddFileToDownloadsTable( C4_7 );
	AddFileToDownloadsTable( C4_8 );
	AddFileToDownloadsTable( C4_9 );
	AddFileToDownloadsTable( C4_10 );
	
	AddFileToDownloadsTable( FIRSTBLD );
	AddFileToDownloadsTable( DOUBLEKL );
	AddFileToDownloadsTable( TRIPLEKL );
	AddFileToDownloadsTable( MONSTEKL );
	AddFileToDownloadsTable( ULTRAKL );
	AddFileToDownloadsTable( GODLIKE );

	AddFileToDownloadsTable( LUDICROU );
	AddFileToDownloadsTable( RAMPAGE );
	AddFileToDownloadsTable( WICKEDSIK );

	AddFileToDownloadsTable( DOMINATE );
	AddFileToDownloadsTable( COMBHOW );
	AddFileToDownloadsTable( HATTRIC );

	AddFileToDownloadsTable( HEADSHOT );
	AddFileToDownloadsTable( HOLLYSHT );
	AddFileToDownloadsTable( HEADHUNT );

	AddFileToDownloadsTable( FUN_1 );
	AddFileToDownloadsTable( FUN_2 );

	AddFileToDownloadsTable( TEAM_KILLER );
	AddFileToDownloadsTable( PLAYER_SLAYED );
	
	AddFileToDownloadsTable( FIRESPIRIT );
	AddFileToDownloadsTable( FIRESPIRIT1 );
	
	if ( !IsModelPrecached( PREDATOR_MDL ))	PrecacheModel( PREDATOR_MDL );
	if ( !IsModelPrecached( HUSK_MDL ))		PrecacheModel( HUSK_MDL );
	if ( !IsModelPrecached( TESLA_MDL ))	PrecacheModel( TESLA_MDL );
	if ( !IsModelPrecached( CLOUD_MDL ))	PrecacheModel( CLOUD_MDL );
	if ( !IsModelPrecached( STAR_1_MDL ))	PrecacheModel( STAR_1_MDL );
	if ( !IsModelPrecached( STAR_2_MDL ))	PrecacheModel( STAR_2_MDL );
	if ( !IsModelPrecached( MUSHROOM_MDL ))	PrecacheModel( MUSHROOM_MDL );
	if ( !IsModelPrecached( BEAMOBJECT ))	PrecacheModel( BEAMOBJECT );
	
	g_BeamSprite	= PrecacheModel( BEAMSPRITE );
	g_FireSprite	= PrecacheModel( FIRESPIRIT );

	PrecacheSound( C4_1, true );
	PrecacheSound( C4_2, true );
	PrecacheSound( C4_3, true );
	PrecacheSound( C4_4, true );
	PrecacheSound( C4_5, true );
	PrecacheSound( C4_6, true );
	PrecacheSound( C4_7, true );
	PrecacheSound( C4_8, true );
	PrecacheSound( C4_9, true );
	PrecacheSound( C4_10, true );
	
	PrecacheSound( EXPLODE, true );
	
	PrecacheSound( TRANSFORM, true );
	PrecacheSound( PREDATOR_HURT_1, true );
	PrecacheSound( PREDATOR_HURT_2, true );
	PrecacheSound( PREDATOR_HURT_3, true );

	PrecacheSound( NORM_HEALTH, true );
	PrecacheSound( SUPER_HEALTH, true );
	PrecacheSound( SUPER_ARMOR, true );
	PrecacheSound( SUPER_SPEED, true );
	PrecacheSound( CLOCK_DEVIC, true );
	PrecacheSound( TIME_OUT, true );
	PrecacheSound( INVALID, true );
	PrecacheSound( AMMO, true );
	PrecacheSound( BONUS, true );

	PrecacheSound( KEVLAR_1, true );
	PrecacheSound( KEVLAR_2, true );
	PrecacheSound( KEVLAR_3, true );

	PrecacheSound( FIRSTBLD, true );
	PrecacheSound( DOUBLEKL, true );
	PrecacheSound( TRIPLEKL, true );
	PrecacheSound( MONSTEKL, true );
	PrecacheSound( ULTRAKL, true );
	PrecacheSound( GODLIKE, true );
	
	PrecacheSound( LUDICROU, true );
	PrecacheSound( RAMPAGE, true );
	PrecacheSound( WICKEDSIK, true );
	
	PrecacheSound( DOMINATE, true );
	PrecacheSound( COMBHOW, true );
	PrecacheSound( HATTRIC, true );
	
	PrecacheSound( HEADSHOT, true );
	PrecacheSound( HOLLYSHT, true );
	PrecacheSound( HEADHUNT, true );
	
	PrecacheSound( FUN_1, true );
	PrecacheSound( FUN_2, true );
	PrecacheSound( TEAM_KILLER, true );
	PrecacheSound( PLAYER_SLAYED, true );
}

public Action:CmdBuyPoint( client, args )
{
	if ( IsClientConnected( client ) && IsClientInGame( client ) && IsPlayerAlive( client ))
	{
		DisplayMain( client );
	}
	else
	{
		PrintToChat( client, "\x01\x0B\x05You must alive to use \x01\x0B\x01command" );
	}
}

public Menu_Action(Handle:menu, MenuAction:action, client, param2 )
{
	if ( action == MenuAction_End )
	{
		CloseHandle( menu );
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[10];
		GetMenuItem(menu, param2, info, sizeof(info));
		new Num = StringToInt( info );
		switch( Num ) {
			case 1: { BuyAmmo( client )				;}
			case 2: { BuyHealth( client, 100 )		;}
			case 3: { BuyHealth( client, 200 )		;}
			case 4: { BuySuperArmor( client )		;}
			case 5: { BuySuperSpeed( client )		;}
			case 6: { BuyClockingDevice( client )	;}
			case 7: { DisplayMisc(client)			;}
		}
	}
	else if (action == MenuAction_Cancel)
	{

	}
}

public Menu_Action_Mis(Handle:menu, MenuAction:action, client, param2 )
{
	if ( action == MenuAction_End )
	{
		CloseHandle( menu );
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[10];
		GetMenuItem(menu, param2, info, sizeof(info));
		new Num = StringToInt( info );
		switch( Num ) {
			case 1: { BuyGranede( client, 1 )	;}
			case 2: { BuyGranede( client, 2 )	;}
			case 3: { BuyGranede( client, 3 )	;}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayMain( client );
	}
}

BuyAmmo( client )
{
	if ( IsPlayerAlive( client ))
	{
		if ( WeaponSlot[client][0] != -1 && IsValidEntity( WeaponSlot[client][0] ))
		{
			decl String:ammoPrim[32];
			GetEdictClassname( WeaponSlot[client][0] , ammoPrim, sizeof( ammoPrim ));
			new iAmmoOffset = FindDataMapOffs( client, "m_iAmmo" );
			new dataIndex = GetPrimaryAmmoIndex( ammoPrim );
			
			if ( dataIndex != -1 )
			{
				SetEntData(client, ( iAmmoOffset + i_PrimaryData[dataIndex][0] ), i_PrimaryData[dataIndex][1]);
			}
		}
		if ( WeaponSlot[client][1] != -1 && IsValidEntity( WeaponSlot[client][1] ))
		{
			decl String:ammoSec[32];
			GetEdictClassname( WeaponSlot[client][1] , ammoSec, sizeof( ammoSec ));
			new iAmmoOffset = FindDataMapOffs( client, "m_iAmmo" );
			new dataIndex = GetSecondaryAmmoIndex( ammoSec );
			
			if ( dataIndex != -1 )
			{
				SetEntData(client, ( iAmmoOffset + i_SecondaryData[dataIndex][0] ), i_SecondaryData[dataIndex][1]);
			}
		}
		PrintToChat( client, "\x01\x0B\x05Full ammo restored" );
		EmitSoundToClient( client, AMMO );
	}
	else
	{
		if ( !IsPlayerAlive( client ))
		{
			PrintToChat( client, "\x01\x0B\x05You must alive to buy \x01\x0B\x01Ammo" );
		}
		EmitSoundToClient( client, INVALID );
	}
}

BuyHealth( client, type )
{
	new heal = GetClientHealth( client );
	new mon = GetEntData( client, m_iAccount);
	new condition;
	
	switch( type ) {
		case 100: { condition = COST_HT	;}
		case 200: { condition = COST_SH	;}
	}
	
	if ( mon >= condition && heal < type && IsPlayerAlive( client ) && g_TimerAddHP[client] == INVALID_HANDLE )
	{
		mon -= condition;
		SetEntData( client, m_iAccount, mon );
		g_AddHealth[client] = type - heal;
		
		// make timer so adding HP is animated
		g_TimerAddHP[client] = CreateTimer( 0.1, Timer_AddHealth, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
		
		if ( type == 100 )
		{
			EmitSoundToClient( client, NORM_HEALTH );
		}
		else if ( type == 200 )
		{
			EmitSoundToClient( client, SUPER_HEALTH );
		}
	}
	else
	{
		if ( mon < condition )
		{
			PrintToChat( client, "\x01\x0B\x05You don't have enought \x01\x0B\x01Money" );
		}
		else if ( heal > type )
		{
			PrintToChat( client, "\x01\x0B\x05You still full \x01\x0B\x01HP" );
		}
		else if ( !IsPlayerAlive( client ))
		{
			PrintToChat( client, "\x01\x0B\x05You must alive to buy \x01\x0B\x01HP" );
		}
		else if ( g_TimerAddHP[client] != INVALID_HANDLE )
		{
			PrintToChat( client, "\x01\x0B\x05You currently adding HP" );
		}
		EmitSoundToClient( client, INVALID );
	}
}

BuySuperArmor( client )
{
	new armor = GetClientArmor( client );
	new mon = GetEntData( client, m_iAccount);
	if (( mon >= COST_SA ) && ( armor > 0 || armor < 125 ) && IsPlayerAlive( client ))
	{
		mon -= COST_SA;
		SetEntProp( client, Prop_Send, "m_ArmorValue", 125 );
		SetEntProp( client, Prop_Send, "m_bHasHelmet", 1 );
		SetEntData( client, m_iAccount, mon );
		EmitSoundToClient( client, SUPER_ARMOR );
		PrintToChat( client, "\x01\x0B\x05Super armor \x01\x0B\x01Activated" );
	}
	else
	{
		if ( mon < COST_SA )
		{
			PrintToChat( client, "\x01\x0B\x05You don't have enought \x01\x0B\x01Money" );
		}
		else if ( armor >= 125 )
		{
			PrintToChat( client, "\x01\x0B\x05You still full \x01\x0B\x01Super Armor" );
		}
		else if ( !IsPlayerAlive( client ))
		{
			PrintToChat( client, "\x01\x0B\x05You must alive to buy \x01\x0B\x01Super Armor" );
		}
		EmitSoundToClient( client, INVALID );
	}
}

BuySuperSpeed( client )
{
	new Float:speed = GetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue");
	new mon = GetEntData( client, m_iAccount);
	if (( mon >= COST_SS ) && ( speed == 1.0 ) && ( g_SuperSpeedTime[client] == INVALID_HANDLE ) && ( g_ClockDeviceTime[client] == INVALID_HANDLE ) && ( IsPlayerAlive( client )))
	{
		mon -= COST_SS;
		g_PropCount[client] = 11;
		SetEntData( client, m_iAccount, mon );
		EmitSoundToClient( client, SUPER_SPEED );
		
		g_SuperSpeedTime[client] = CreateTimer( 1.0, Timer_SetSpeedProp, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		PrintToChat( client, "\x01\x0B\x05Super speed \x01\x0B\x01Activated" );
	}
	else
	{
		if ( mon < COST_SS )
		{
			PrintToChat( client, "\x01\x0B\x05You don't have enought \x01\x0B\x01Money" );
		}
		else if ( speed == 2.0 || g_SuperSpeedTime[client] != INVALID_HANDLE )
		{
			PrintToChat( client, "\x01\x0B\x05You still in \x01\x0B\x01Super Speed \x01\x0B\x05mode" );
		}
		else if ( g_ClockDeviceTime[client] != INVALID_HANDLE )
		{
			PrintToChat( client, "\x01\x0B\x05Try again after \x01\x0B\x01Clocking Device \x01\x0B\x05cool down" );
		}
		else if ( !IsPlayerAlive( client ))
		{
			PrintToChat( client, "\x01\x0B\x05You must alive to buy \x01\x0B\x01Super Speed" );
		}
		EmitSoundToClient( client, INVALID );
	}
}

BuyClockingDevice( client )
{
	new mon = GetEntData( client, m_iAccount);
	
	if (( mon >= COST_CD ) && ( IsPlayerAlive( client )) && ( g_SuperSpeedTime[client] == INVALID_HANDLE ) && ( g_ClockDeviceTime[client] == INVALID_HANDLE ))
	{
		mon -= COST_CD;
		g_PropCount[client] = 11;
		SetEntData( client, m_iAccount, mon );
		EmitSoundToClient( client, CLOCK_DEVIC );
		
		g_ClockDeviceTime[client] = CreateTimer( 1.0, Timer_SetClockProp, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		PrintToChat( client, "\x01\x0B\x05Super armor \x01\x0B\x01Activated" );
	}
	else
	{
		if ( mon < COST_CD )
		{
			PrintToChat( client, "\x01\x0B\x05You don't have enought \x01\x0B\x01Money" );
		}
		else if ( g_ClockDeviceTime[client] != INVALID_HANDLE )
		{
			PrintToChat( client, "\x01\x0B\x05You still in \x01\x0B\x01Super Clocking \x01\x0B\x05mode" );
		}
		else if ( g_SuperSpeedTime[client] != INVALID_HANDLE )
		{
			PrintToChat( client, "\x01\x0B\x05Try again after \x01\x0B\x01Super Speed \x01\x0B\x05cool down" );
		}
		else if ( !IsPlayerAlive( client ) )
		{
			PrintToChat( client, "\x01\x0B\x05You must alive to use \x01\x0B\x01Clock Device" );
		}
		EmitSoundToClient( client, INVALID );
	}
}

DisplayMain( client )
{
	new Handle:menu = CreateMenu( Menu_Action );
	SetMenuTitle( menu, "Money Available %d", GetEntData( client, m_iAccount));
	AddMenuItem( menu, "1", "Buy Ammo ---------- Free" );
	AddMenuItem( menu, "2", "Buy Health ---------- 600" );
	AddMenuItem( menu, "3", "Buy Super Health -- 1200" );
	AddMenuItem( menu, "4", "Buy Super Armor --- 1200" );
	AddMenuItem( menu, "5", "Buy Super Speed --- 1200" );
	AddMenuItem( menu, "6", "Buy Clocking Device 1200" );
	AddMenuItem( menu, "7", "Misc" );
	//SetMenuExitBackButton( menu, true );
	DisplayMenu( menu, client, 60 );
}

DisplayMisc( client )
{
	new Handle:menu = CreateMenu( Menu_Action_Mis );
	SetMenuTitle( menu, "Misclinus %d", GetEntData( client, m_iAccount));
	AddMenuItem( menu, "1", "Buy Flash Bang" );
	AddMenuItem( menu, "2", "Buy Grenade" );
	AddMenuItem( menu, "3", "Buy Smoke Grenade" );
	SetMenuExitBackButton( menu, true );
	DisplayMenu( menu, client, 60 );
}

BuyGranede( client, type )
{
	new graned;
	new mon = GetEntData( client, m_iAccount);
	if ( mon >= COST_GR && IsPlayerAlive( client ))
	{
		switch ( type ) {
			case 1: { graned = CreateEntityByName( "weapon_flashbang" )		;}
			case 2: { graned = CreateEntityByName( "weapon_hegrenade" )		;}
			case 3: { graned = CreateEntityByName( "weapon_smokegrenade" )	;}
		}
		if ( graned != -1 )
		{
			mon -= COST_GR;
			
			decl Float:Pos[3];
			GetEntPropVector( client, Prop_Send, "m_vecOrigin", Pos );
		
			Pos[2] += 10.0;
		
			DispatchSpawn( graned );
			TeleportEntity( graned, Pos, NULL_VECTOR, NULL_VECTOR );
			EmitSoundToClient( client, AMMO );
			SetEntData( client, m_iAccount, mon );
		}
	}
	else
	{
		if ( mon < COST_GR )
		{
			PrintToChat( client, "\x01\x0B\x05You don't have enought \x01\x0B\x01Money" );
		}
		else if ( !IsPlayerAlive( client ) )
		{
			PrintToChat( client, "\x01\x0B\x05You must alive to buy \x01\x0B\x01Grenade" );
		}
	}
}

public Action:Timer_KillPrecache(Handle:timer, any:OB)
{
	if ( IsValidEntity( OB ))
	{
		AcceptEntityInput( OB, "kill" );
	}
}

public Action:Timer_AddHealth(Handle:timer, any:client)
{
	g_AddHealth[client] -= 1;
	
	if ( g_AddHealth[client] >= 0 && IsValidClient( client ))
	{
		SetEntityHealth( client, ( GetClientHealth( client ) + 1 ));
	}
	else
	{
		if ( IsValidClient( client ))
		{
			PrintToChat( client, "\x01\x0B\x05Add HP completed." );
		}
		if ( g_TimerAddHP[client] != INVALID_HANDLE )
		{
			KillTimer( g_TimerAddHP[client] );
			g_TimerAddHP[client] = INVALID_HANDLE;
		}
		g_AddHealth[client] = 0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_TweakCvar(Handle:timer, any:client)
{
	SetConVarInt( FindConVar( "mp_friendlyfire" ),					0);
	SetConVarInt( FindConVar( "mp_roundtime" ),						5);
	SetConVarInt( FindConVar( "mp_autoteambalance" ),				0);
	SetConVarInt( FindConVar( "mp_buytime" ),						99999999999999999999);
	SetConVarInt( FindConVar( "mp_maxrounds" ),						0);
	SetConVarInt( FindConVar( "bot_join_after_player" ),			0);
	SetConVarInt( FindConVar( "mp_ignore_round_win_conditions" ),	0);
	/*
	SetConVarInt( FindConVar( "bot_allow_grenades" ),				1);
	SetConVarInt( FindConVar( "bot_allow_pistols" ),				1);
	SetConVarInt( FindConVar( "bot_allow_sub_machine_guns" ),		1);
	SetConVarInt( FindConVar( "bot_allow_shotguns" ),				1);
	SetConVarInt( FindConVar( "bot_allow_rifles" ),					1);
	SetConVarInt( FindConVar( "bot_allow_snipers" ),				1);
	SetConVarInt( FindConVar( "bot_allow_machine_guns" ),			1);
	*/
	
	return Plugin_Stop;
}

public CVARChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if ( GetConVarInt( g_RoleCombate ) == 0 )
	{
		AbortAction();
		SetConVarInt( FindConVar( "mp_ignore_round_win_conditions" ), 0);
	}
	else
	{
		RestartAction();
		SetConVarInt( FindConVar( "mp_ignore_round_win_conditions" ), 1);
	}
}

public EVENT_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_RoleCombate ) == 0 ) return;

	RemoveFunctionZone();
	g_EvaLife		= INVALID_HANDLE;
	g_TimerLookUp	= INVALID_HANDLE;
	
	for ( new i = 1; i <= MaxClients; i++)
	{
		g_CountDown[i] = 0;
		g_TimerRespawn[i] = INVALID_HANDLE;
	}

	if ( g_EvaLife != INVALID_HANDLE )
	{
		KillTimer( g_EvaLife );
	}
	g_EvaLife = INVALID_HANDLE;
	
	if ( g_KirbyLife != INVALID_HANDLE )
	{
		KillTimer( g_KirbyLife );
	}
	g_KirbyLife = INVALID_HANDLE;
	
	if ( g_MaxLife != INVALID_HANDLE )
	{
		KillTimer( g_MaxLife );
	}
	g_MaxLife = INVALID_HANDLE;

	if ( !g_WinItemRemoved && g_TimerLookUp == INVALID_HANDLE )
	{
		g_LookUpExpired = 0;
		g_TimerLookUp = CreateTimer( 0.6, Timer_RemoveMissionItem, _,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
	if ( !g_BotAdded )
	{
		CreateTimer( 1.0, Timer_AddBot, _, TIMER_FLAG_NO_MAPCHANGE );
	}
	
	if ( g_WarmUp < 3 )
	{
		PrintCenterTextAll( "++ Warm Up Round ++" );
	}
	else if ( g_WarmUp == 3 )
	{
		PrintCenterTextAll( "++ Round Start ++" );
		SetTeamScore( TEAM_T, 0 );
		SetTeamScore( TEAM_CT, 0 );
		
		for (new i = 1; i <= MaxClients; i++ )
		{
			if ( IsClientConnected( i ) && IsClientInGame( i ))
			{
				SetClientScore( i, 0 );
			}
		}
	}
	else
	{
		PrintCenterTextAll( "++ New Role Combat Begun ++" );
	}
	g_TimerServerMSG = CreateTimer( 240.0, Timer_ServerMSG, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
}

public EVENT_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_RoleCombate ) == 0 ) return;
	new client = GetClientOfUserId( GetEventInt( event, "userid" ));
	
	if ( IsValidClient( client ))
	{
		g_ClientBeamSP[client]		= -1;
		g_ModelSet[client]			= -1;
		g_PredKillSnd[client][0]	= 0;
		g_PredKillSnd[client][1]	= 0;
		g_FunSound[client]			= 0;
		g_TerrorID[client][0]		= 0;
		g_TerrorID[client][1]		= 0;
		g_TerrorID[client][2]		= 0;
		g_TimerPredKillSnd[client]	= INVALID_HANDLE;
		g_SuperSpeedTime[client]	= INVALID_HANDLE;
		g_TerrorLife[client]		= INVALID_HANDLE;
		
		SetEntityGravity( client, 1.0 );
		SetEntityRenderMode( client, RENDER_TRANSCOLOR );
		SetEntityRenderColor( client, 255, 255, 255, 255 );
		
		if ( g_iAccount[client] > 0 )
		{
			if ( g_iAccount[client] > 16000 )
			{
				g_iAccount[client] = 16000;
			}
			SetEntData( client, m_iAccount, g_iAccount[client] );
			g_iAccount[client] = 0;
		}
		
		new chance = GetConVarInt( g_PredatorChance );
		if ( chance > 100 )	chance = 100;
		if ( chance < 0 )	chance = 0;

		if (( GetRandomInt( 0, 100 ) <= chance ) && GetClientTeam( client ) == TEAM_T && IsCanSpawn() && g_WarmUp > 2 )
		{
			g_SpecialTerrorCount ++;
			g_iAccount[client] = GetEntData( client, m_iAccount );
			SetEntData( client, m_iAccount, 0 );
			
			switch( GetRandomInt( 1, 3 ))
			{
				case 1:
				{
					CreateTimer( 0.2, Timer_PredatorTransform, client );
				}
				case 2:
				{
					CreateTimer( 0.2, Timer_AlienTransform, client );
				}
				case 3:
				{
					CreateTimer( 0.2, Timer_HuskTransform, client );
				}
			}
		}
		else
		{
			if ( GetConVarInt( g_tStartMoney ) > 0 && IsValid_T( client ) && IsFakeClient( client ))
			{
				SetEntData( client, m_iAccount, GetConVarInt( g_tStartMoney ));
			}
			if ( GetConVarInt( g_cStartMoney ) > 0 && IsValid_CT( client )  && IsFakeClient( client ))
			{
				SetEntData( client, m_iAccount, GetConVarInt( g_cStartMoney ));
			}
		}
		if ( IsValid_CT( client ) && g_WarmUp > 3 )
		{
			if ( GetConVarInt( g_StartUpGun ) > 0 )
			{
				CreateTimer( 0.5, Timer_CheckNobGun, client );
			}
			if ( g_LastHealth[client] > 100 )
			{
				SetEntityHealth( client, g_LastHealth[client] );
				g_LastHealth[client] = 0;
			}
		}
	}
}

public Action:EVENT_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim		= GetClientOfUserId( GetEventInt( event, "userid" ));
	new attacker	= GetClientOfUserId(GetEventInt(event, "attacker"));
	new hitgroup	= GetEventInt(event, "hitgroup");
	new d_Health	= GetEventInt(event, "dmg_health");	// damage done to health
	new r_Health	= GetEventInt(event, "health");		// remaining health points
	//new d_Armor	= GetEventInt(event, "dmg_armor");	// damage done to armor
	//new r_Armor	= GetEventInt(event, "armor");		// remaining armor points
	
	if ( !IsValidClient( victim ) || !IsValidClient( attacker )) return Plugin_Continue;
	
	new HH;
	new String:sndHurt[64];
	
	if ( g_TerrorID[attacker][0] > 0 && IsPlayerAlive( victim ) && GetClientTeam( attacker ) != GetClientTeam( victim ))
	{
		IgniteEntity( victim, 1.0, false );
	}
	if ( g_TerrorID[attacker][1] > 0 && IsPlayerAlive( victim ) && GetClientTeam( attacker ) != GetClientTeam( victim ))
	{
		new Float:vec[3]; 
		vec[0] = GetRandomFloat( -30.0, 30.0 ); 
		vec[1] = GetRandomFloat( -30.0, 30.0 ); 
		vec[2] = GetRandomFloat( -5.0, 5.0 ); 
		SetEntPropVector( victim, Prop_Send, "m_vecPunchAngle", vec ); 
	}
	
	if (( g_PropCount[victim] > 0 ) && ( g_ClockDeviceTime[victim] != INVALID_HANDLE ))
	{
		switch( GetRandomInt( 1, 3 )){
			case 1: { sndHurt = KEVLAR_1 ;}
			case 2: { sndHurt = KEVLAR_2 ;}
			case 3: { sndHurt = KEVLAR_3 ;}
		}
		EmitSoundToClient( victim, sndHurt );
	}
	
	if ( g_TerrorID[victim][0] > 0 )
	{
		SetupSpark( victim, 1 );
		
		SetEntProp( victim, Prop_Send, "m_ArmorValue", 100 );
		SetEntProp( victim, Prop_Send, "m_bHasHelmet", 1 );

		switch( GetRandomInt( 1, 3 )){
			case 1: { sndHurt = PREDATOR_HURT_1 ;}
			case 2: { sndHurt = PREDATOR_HURT_2 ;}
			case 3: { sndHurt = PREDATOR_HURT_3 ;}
		}
		EmitSoundToAll( sndHurt, victim, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
		
		new String:attWeapon[128];
		GetEventString( event, "weapon", attWeapon, sizeof( attWeapon ));
		if ( StrEqual( attWeapon, "m249", false ))
		{
			if ( GetEntProp( victim, Prop_Data, "m_iHealth") > 20 )
			{
				HH = RoundToCeil( d_Health * 0.7 );
				SetEntProp( victim, Prop_Data, "m_iHealth", ( r_Health + HH ));
				return Plugin_Changed;
			}
		}
	}

	if ( g_TerrorID[victim][1] > 0 )
	{
		SetupSpark( victim, 3 );
		
		SetEntProp( victim, Prop_Send, "m_ArmorValue", 100 );
		SetEntProp( victim, Prop_Send, "m_bHasHelmet", 1 );
		
		switch( GetRandomInt( 1, 3 ) ){
			case 1: { sndHurt = PREDATOR_HURT_1 ;}
			case 2: { sndHurt = PREDATOR_HURT_2 ;}
			case 3: { sndHurt = PREDATOR_HURT_3 ;}
		}
		EmitSoundToAll( sndHurt, victim, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
		
		if ( hitgroup == 1 )
		{
			SetEntProp( victim, Prop_Data, "m_iHealth", ( r_Health + d_Health ));
			if ( GetEntProp( victim, Prop_Data, "m_iHealth") > 100 )
			{
				SetEntProp( victim, Prop_Data, "m_iHealth", 100 );
			}
		}
		if ( GetEntProp( victim, Prop_Data, "m_iHealth") > 20 && hitgroup != 1 )
		{
			HH = RoundToCeil( d_Health * 0.5 );
			SetEntProp( victim, Prop_Data, "m_iHealth", ( r_Health + HH ));
		}
		return Plugin_Changed;
	}
	
	if ( g_TerrorID[victim][2] > 0 )
	{
		SetupSpark( victim, 2 );
		
		SetEntProp( victim, Prop_Send, "m_ArmorValue", 100 );
		SetEntProp( victim, Prop_Send, "m_bHasHelmet", 1 );

		switch( GetRandomInt( 1, 3 )){
			case 1: { sndHurt = PREDATOR_HURT_1 ;}
			case 2: { sndHurt = PREDATOR_HURT_2 ;}
			case 3: { sndHurt = PREDATOR_HURT_3 ;}
		}
		EmitSoundToAll( sndHurt, victim, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
		
		new String:attWeapon1[64];
		GetEventString( event, "weapon", attWeapon1, sizeof( attWeapon1 ));
		if ( StrEqual( attWeapon1, "awp", false ) || StrEqual( attWeapon1, "sg550", false ) || StrEqual( attWeapon1, "g3sg1", false ))
		{
			if ( GetEntProp( victim, Prop_Data, "m_iHealth") > 20 )
			{
				HH = RoundToCeil( d_Health * 0.7 );
				SetEntProp( victim, Prop_Data, "m_iHealth", ( r_Health + HH ));
				return Plugin_Changed;
			}
		}
	}
	
	if ( g_TerrorID[attacker][1] > 0 && ( GetClientTeam( attacker ) != GetClientTeam( victim )))
	{
		HH = RoundToCeil( d_Health * 0.5 );
		SetEntProp( victim, Prop_Data, "m_iHealth", ( r_Health - HH ));
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public EVENT_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_RoleCombate ) == 0 ) return;
	
	if ( GetEventInt( event, "reason" ) != 15 )
	{
		g_WarmUp += 1;
	}
	
	g_SpecialTerrorCount = 0;
	g_WinItemRemoved = false;
	AbortAction();
	
	if ( g_WarmUp < 3 )
	{
		SetConVarInt( FindConVar( "mp_roundtime" ),	5);
	}
	else if ( g_WarmUp == 3 )
	{
		SetConVarInt( FindConVar( "mp_roundtime" ),	0);
		SetConVarInt( FindConVar( "mp_ignore_round_win_conditions" ),	1);
		
		for (new i = 1; i <= MaxClients; i++ )
		{
			if ( IsClientConnected( i ) && IsClientInGame( i ) && !IsFakeClient( i ) && GetClientTeam( i ) != TEAM_S )
			{
				g_iAccount[i] = 800;
			}
		}
	}
	else
	{
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValid_T( i ) || IsValid_CT( i ))
			{
				if (( g_TerrorID[i][0] > 0 || g_TerrorID[i][2] > 0 ) && g_TerrorID[i][1] == 0 )
				{
					g_iAccount[i] = g_iAccount[i] + GetEntData( i, m_iAccount);
				}
				else
				{
					if ( !IsFakeClient( i ))
					{
						g_iAccount[i] = GetEntData( i, m_iAccount);
					}
				}
			}
			if ( IsValid_T( i ) && IsPlayerAlive( i ) && ( g_TerrorID[i][0] > 0 || g_TerrorID[i][1] > 0 || g_TerrorID[i][2] > 0 ))
			{
				ResetTerrorStat( i );
			}
			if ( IsValid_CT( i ) && IsPlayerAlive( i ))
			{
				if ( GetClientHealth( i ) > 100 )
				{
					g_LastHealth[i] = GetClientHealth( i );
				}
				ResetCTStat( i );
			}
		}
	}
}

public EVENT_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_RoleCombate ) == 0 ) return;
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ));
	
	if ( g_TerrorID[client][0] == client || g_TerrorID[client][1] == client || g_TerrorID[client][2] == client )
	{
		g_TerrorID[client][0]	= 0;
		g_TerrorID[client][1]	= 0;
		g_TerrorID[client][2]	= 0;
		g_iAccount[client]		= 0;
		
		if ( g_TimerRespawn[client] != INVALID_HANDLE )
		{
			KillTimer( g_TimerRespawn[client] );
			g_TimerRespawn[client] = INVALID_HANDLE;
		}
	}
}

public EVENT_ItemPickUp(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_RoleCombate ) == 0 ) return;
	new client = GetClientOfUserId( GetEventInt( event, "userid" ));
	
	if ( g_TerrorID[client][0] == client )
	{
		CreateTimer( 0.2, Timer_PredatorGear, client );
	}
	else if ( g_TerrorID[client][2] == client )
	{
		CreateTimer( 0.2, Timer_HuskGear, client );
	}
	else
	{
		CreateTimer( 0.2, Timer_RegisterItem, client );
	}
}

public EVENT_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_RoleCombate ) == 0 ) return;
	new victim			= GetClientOfUserId( GetEventInt( event, "userid"));
	new attacker		= GetClientOfUserId( GetEventInt( event, "attacker"));
	new bool:headShot	= GetEventBool( event, "headshot");
	new dominate		= GetEventInt( event, "dominated");
	new revenge			= GetEventInt( event, "revenge");
	
	if ( g_TerrorID[victim][0] == victim || g_TerrorID[victim][1] == victim || g_TerrorID[victim][2] == victim )
	{
		new Account = g_iAccount[victim] + GetEntData( victim, m_iAccount);
		if ( Account > 16000 )
		{
			Account = 16000;
		}
		SetEntData( victim, m_iAccount, Account);
		g_iAccount[victim] = 0;
		g_SpecialTerrorCount --;
		
		if ( g_TerrorID[victim][0] == victim )
		{
			HumanDeadResault( victim );
			KillerBonus( attacker );
			if ( IsValid_CT( attacker ) && !IsFakeClient( attacker ))
			{
				PrintToChat( attacker, "\x01\x0B\x05You killed Predator \x01\x0B\x01%N ", victim );
			}
		}
		else if ( g_TerrorID[victim][1] == victim )
		{
			HumanDeadResault( victim );
			KillerBonus( attacker );
			if ( IsValid_CT( attacker ) && !IsFakeClient( attacker ))
			{
				PrintToChat( attacker, "\x01\x0B\x05You killed Alien \x01\x0B\x01%N ", victim );
			}
		}
		else if ( g_TerrorID[victim][2] == victim )
		{
			KillerBonus( attacker );
			SetUpExplosion( victim );
			if ( IsValid_CT( attacker ) && !IsFakeClient( attacker ))
			{
				PrintToChat( attacker, "\x01\x0B\x05You killed Husk \x01\x0B\x01%N ", victim );
			}
		}
		g_TerrorID[victim][0] = 0;
		g_TerrorID[victim][1] = 0;
		g_TerrorID[victim][2] = 0;
	}
	else
	{
		HumanDeadResault( victim );
	}
	
	if ( g_WarmUp > 2 )
	{
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidClient( i ) && GetClientTeam( i ) == 2 && !IsFakeClient( i ) && GetConVarInt( g_AllCT ) == 1 )
			{
				if ( Get_CTerrorisCount_Human() < GetTeamClientCount( 3 ))
				{
					ForcePlayerSuicide( i );
					SetEntProp( i, Prop_Send, "m_iTeamNum", 3 );
				}
				else
				{
					ForcePlayerSuicide( i );
					SetEntProp( i, Prop_Send, "m_iTeamNum", 1 );
				}
			}
			
			if (( IsValid_T( i ) || IsValid_CT( i )) && !IsPlayerAlive( i ) && g_TimerRespawn[i] == INVALID_HANDLE )
			{
				if ( !IsFakeClient( i ) && g_SpawnBtn[i] ) continue;
			
				g_CountDown[i]		= GetConVarInt( g_RespawnDelay );
				g_TimerRespawn[i]	= CreateTimer( 1.0, Timer_Respawn, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			
				if ( !IsFakeClient( i ))
				{
					PrintHintText( i, "++ You will be respawn in %d ++", g_CountDown[i]);
				}
			}
		}
		if (( g_TerrorID[attacker][0] == attacker || g_TerrorID[attacker][1] == attacker || g_TerrorID[attacker][2] == attacker ) && !IsFakeClient( victim ))
		{
			EmitSoundToClient( victim, PLAYER_SLAYED );
		}
		CreateTimer( 0.2, Timer_CheckOneSideWin );
	}
	
	SetEntPropFloat( victim, Prop_Data, "m_flLaggedMovementValue", 1.0);
	
	if (( IsValid_T( attacker ) || IsValid_CT( attacker )) && !IsFakeClient ( attacker ))
	{
		g_PredKillSnd[attacker][0]++;
		g_PredKillSnd[attacker][1]++;
		g_FunSound[attacker] += 1;
		
		if ( headShot )
		{
			PlayKillingSound( attacker, 1 );
		}
		else if ( dominate )
		{
			PlayKillingSound( attacker, 2 );
		}
		else if ( revenge )
		{
			PlayKillingSound( attacker, 3 );
		}
		
		if ( GetClientTeam( victim ) == GetClientTeam( attacker ))
		{
			PlayKillingSound( attacker, 4 );
		}
		
		if ( g_TimerPredKillSnd[attacker]	!= INVALID_HANDLE )
		{
			KillTimer( g_TimerPredKillSnd[attacker] );
			g_TimerPredKillSnd[attacker] = INVALID_HANDLE;
		}
		
		if ( g_FunSound[attacker] == 4 )
		{
			CreateTimer( 1.5, Timer_EmitFunSound, attacker );
		}
		g_TimerPredKillSnd[attacker] = CreateTimer( 3.0, Timer_EmitSound, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (( buttons & IN_USE ) && g_SpawnBtn[client] )
	{
		CS_RespawnPlayer( client );
		g_SpawnBtn[client] = false;
	}
}

public Action:BuyZone( client )
{
	SetEntProp( client, Prop_Send, "m_bInBuyZone", 1 );
}

public Action:Timer_EmitFunSound(Handle:timer, any:client)
{
	if ( IsValidClient( client ) && !IsFakeClient( client ))
	{
		new String:SDN[64];
		switch( GetRandomInt( 1, 2 ))
		{
			case 1: { SDN = FUN_1	;}
			case 2: { SDN = FUN_2	;}
		}
		StopAllSound( client );
		EmitSoundToClient( client, SDN );
		g_FunSound[client] = 0;
	}
}

public Action:Timer_EmitSound(Handle:timer, any:client)
{
	if ( IsValidClient( client ) && !IsFakeClient( client ))
	{
		if ( g_PredKillSnd[client][0] == 1 )
		{
			EmitSoundToClient( client, FIRSTBLD );
		}
		if ( g_PredKillSnd[client][1] > 1 && g_PredKillSnd[client][1] < 6 )
		{
			new String:SND[32];
			switch( g_PredKillSnd[client][1] )
			{
				case 2: { SND = DOUBLEKL	;}
				case 3: { SND = TRIPLEKL	;}
				case 4: { SND = MONSTEKL	;}
				case 5: { SND = ULTRAKL		;}
			}
			StopAllSound( client );
			EmitSoundToClient( client, SND );
		}
		else if ( g_PredKillSnd[client][1] >= 6 )
		{
			EmitSoundToClient( client, GODLIKE );
		}
		g_PredKillSnd[client][1] = 0;
	}
	
	if ( g_TimerPredKillSnd[client]	!= INVALID_HANDLE )
	{
		KillTimer( g_TimerPredKillSnd[client] );
	}
	g_TimerPredKillSnd[client] = INVALID_HANDLE;
	
	return Plugin_Stop;
}

public Action:Timer_SetSpeedProp(Handle:timer, any:client)
{
	g_PropCount[client] --;
	
	if ( IsValidClient( client ) && g_PropCount[client] > 0 )
	{
		if ( g_ModelSet[client] == -1 )
		{
			g_ModelSet[client] = GetPlayerModel( client );
			SetEntityModel( client, CLOUD_MDL );
			SetAlphaMode( client, 255, 200 );
			SetAlphaMode( WeaponSlot[client][0], 255, 200 );
			SetAlphaMode( WeaponSlot[client][1], 255, 200 );
			SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", 2.0 );
			EmitSoundToAll( TRANSFORM, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
			SetEntityGravity( client, 0.5 );
		}
		
		CountDown( client, g_PropCount[client] );
		KillBeamSpirit( client );
		SetUpBeam( client, "Blue", 1.5, 20.0, 255 );
		PrintHintText( client, "++ Super Speed last in %d ++", g_PropCount[client] );
	}
	else
	{
		g_PropCount[client] = 0;
		
		if ( IsValidClient( client ))
		{
			if ( g_ModelSet[client] != -1 )
			{
				SetEntityModel( client, CT_Models[ g_ModelSet[client] ] );
			}
			SetAlphaMode( client, 255, 255 );
			SetAlphaMode( WeaponSlot[client][0], 255, 255 );
			SetAlphaMode( WeaponSlot[client][1], 255, 255 );
			
			SetEntityGravity( client, 1.0 );
			EmitSoundToClient( client, TIME_OUT );
			SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", 1.0 );
		}
		g_ModelSet[client] = -1;
		KillBeamSpirit( client );
		PrintHintText( client, "-- Super Speed deactivated --" );

		if ( g_SuperSpeedTime[client] != INVALID_HANDLE )
		{
			KillTimer( g_SuperSpeedTime[client] );
			g_SuperSpeedTime[client] = INVALID_HANDLE;
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_SetClockProp(Handle:timer, any:client)
{
	g_PropCount[client] --;
	
	if ( IsValidClient( client ) && g_PropCount[client] > 0 )
	{
		if ( g_ModelSet[client] == -1 )
		{
			g_ModelSet[client] = GetPlayerModel( client );
			SetAlphaMode( WeaponSlot[client][0], 255, 200 );
			SetAlphaMode( WeaponSlot[client][1], 255, 200 );
			SetEntProp( client, Prop_Data, "m_takedamage", 0, 1 );
			EmitSoundToAll( TRANSFORM, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
		}
		
		switch( GetRandomInt( 1, 4 ))
		{
			case 1:	{ SetEntityModel( client, PREDATOR_MDL ); }
			case 2:	{ SetEntityModel( client, HUSK_MDL ); }
			case 3:	{ SetEntityModel( client, TESLA_MDL ); }
			case 4:	{ SetEntityModel( client, CLOUD_MDL ); }
		}
		
		CountDown( client, g_PropCount[client] );
		SetEntityRenderMode( client, RENDER_TRANSCOLOR );
		SetEntityRenderColor( client, 255, 0, 0, 200 );
		
		PrintHintText( client, "++ Clock Device last in %d ++", g_PropCount[client] );
	}
	else
	{
		g_PropCount[client] = 0;
		
		if ( IsValidClient( client ))
		{
			if ( g_ModelSet[client] != -1 )
			{
				SetEntityModel( client, CT_Models[ g_ModelSet[client] ] );
			}			
			SetAlphaMode( client, 255, 255 );
			SetAlphaMode( WeaponSlot[client][0], 255, 255 );
			SetAlphaMode( WeaponSlot[client][1], 255, 255 );
			EmitSoundToClient( client, TIME_OUT );
		}
		g_ModelSet[client] = -1;
		SetEntProp( client, Prop_Data, "m_takedamage", 2, 1);
		PrintHintText( client, "-- Clock Device deactivated --" );

		if ( g_ClockDeviceTime[client] != INVALID_HANDLE )
		{
			KillTimer( g_ClockDeviceTime[client] );
			g_ClockDeviceTime[client] = INVALID_HANDLE;
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_Respawn(Handle:timer, any:client)
{
	g_CountDown[client] --;
	
	if (( IsValid_T( client ) || IsValid_CT( client )) && !IsPlayerAlive( client ) && ( g_CountDown[client] > 0 ))
	{
		if ( !IsFakeClient( client ))
		{
			PrintHintText( client, "++ You will be respawn in %d ++", g_CountDown[client]);
		}
	}
	else
	{
		if (( IsValid_T( client ) || IsValid_CT( client )) && !IsPlayerAlive( client ))
		{
			g_CountDown[client] = 0;
			if ( IsFakeClient( client ))
			{
				CS_RespawnPlayer( client );
			}
			else
			{
				g_SpawnBtn[client] = true;
				PrintHintText( client, "-- press USE (E) button to respawn --" );
			}
		}
		if ( g_TimerRespawn[client] != INVALID_HANDLE )
		{
			KillTimer( g_TimerRespawn[client] );
			g_TimerRespawn[client] = INVALID_HANDLE;
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_ServerMSG(Handle:timer)
{
	PrintCenterTextAll( "++ Welcome To Role Combat Server ++" );
	PrintToChatAll( "\x01\x0B\x05Type \x01\x0B\x01!cs_buy \x01\x0B\x05to open buy menu!!" );
}

public Action:Timer_PredatorTransform(Handle:timer, any:client)
{
	if ( IsValid_T( client ) && IsPlayerAlive( client ))
	{
		g_TerrorID[client][0] = client;
		g_TerrorID[client][1] = 0;
		g_TerrorID[client][2] = 0;
	
		if ( g_ModelSet[client] == -1 )
		{
			g_ModelSet[client] = GetPlayerModel( client );
		}
	
		SetEntityModel( client, PREDATOR_MDL );
		SetEntityHealth( client, GetConVarInt( g_PredatorHP ));
		SetEntProp( client, Prop_Send, "m_ArmorValue", 100 );
		SetEntProp( client, Prop_Send, "m_bHasHelmet", 1 );
	
		SetEntityGravity( client, 0.7 );
		SetAlphaMode( client, 255, 150 );
		PredatorGear( client, 150 );
		SetSpeedBoost( client );
	
		g_TerrorLife[client] = CreateTimer( 1.0, Timer_PredatorLife, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
		
		PrintToChatAll( "\x01\x0B\x01%N \x01\x0B\x05spawn as \x01\x0B\x01Predator.", client );
	}
}

public Action:Timer_PredatorLife(Handle:timer, any:client)
{
	if ( IsValidClient( client ))
	{
		KillBeamSpirit( client );
		SetUpBeam( client, "White", 0.7, 25.0, 50 );
		
		new dIndex;
		decl String:ammoPL[32];
		if ( WeaponSlot[client][0] != -1 )
		{
			GetEdictClassname( WeaponSlot[client][0] , ammoPL, sizeof( ammoPL ));
			new iAmmoOffset = FindDataMapOffs( client, "m_iAmmo" );	
			dIndex = GetPrimaryAmmoIndex( ammoPL );
			if ( dIndex != -1 )
			{
				SetEntData( client, ( iAmmoOffset + i_PrimaryData[dIndex][0] ), i_PrimaryData[dIndex][1] );
			}
		}
		
		if ( WeaponSlot[client][1] != -1 )
		{
			GetEdictClassname( WeaponSlot[client][1] , ammoPL, sizeof( ammoPL ));
			new iAmmoOffset = FindDataMapOffs( client, "m_iAmmo" );	
			dIndex = GetSecondaryAmmoIndex( ammoPL );
			if ( dIndex != -1 )
			{
				SetEntData( client, ( iAmmoOffset + i_SecondaryData[dIndex][0] ), i_SecondaryData[dIndex][1] );
			}
		}
	}
	else
	{
		KillBeamSpirit( client );
		
		if ( g_TerrorLife[client] != INVALID_HANDLE )
		{
			KillTimer( g_TerrorLife[client] );
			g_TerrorLife[client] = INVALID_HANDLE;
		}
		if ( g_MaxLife == INVALID_HANDLE )
		{
			DropBonusItem_Max( client );
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_AlienTransform(Handle:timer, any:client)
{
	if ( IsValid_T( client ) && IsPlayerAlive( client ))
	{
		g_TerrorID[client][0] = 0;
		g_TerrorID[client][1] = client;
		g_TerrorID[client][2] = 0;
	
		if ( g_ModelSet[client] == -1 )
		{
			g_ModelSet[client] = GetPlayerModel( client );
		}
		SetEntityModel( client, TESLA_MDL );
		SetEntityGravity( client, 0.9 );
		SetEntityHealth( client, GetConVarInt( g_AlienHP ));
		SetEntProp( client, Prop_Send, "m_ArmorValue", 100 );
		SetEntProp( client, Prop_Send, "m_bHasHelmet", 1 );
	
		SetEntData( client, m_iAccount, g_iAccount[client] );
	
		AlienGear( client, 255 );
	
		g_TerrorLife[client] = CreateTimer( 1.0, Timer_AlienLife, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	
		PrintToChatAll( "\x01\x0B\x01%N \x01\x0B\x05spawn as \x01\x0B\x01Alien.", client );
	}
}

public Action:Timer_AlienLife(Handle:timer, any:client)
{
	if ( IsValidClient( client ))
	{
		KillBeamSpirit( client );
		SetUpBeam( client, "White", 0.7, 25.0, 70 );
	}
	else
	{
		KillBeamSpirit( client );
		
		if ( g_TerrorLife[client] != INVALID_HANDLE )
		{
			KillTimer( g_TerrorLife[client] );
			g_TerrorLife[client] = INVALID_HANDLE;
		}
		
		if ( g_EvaLife == INVALID_HANDLE )
		{
			DropBonusItem_Eva( client );
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_HuskTransform(Handle:timer, any:client)
{
	if ( IsValid_T( client ) && IsPlayerAlive( client ))
	{
		g_TerrorID[client][0] = 0;
		g_TerrorID[client][1] = 0;
		g_TerrorID[client][2] = client;
	
		if ( g_ModelSet[client] == -1 )
		{
			g_ModelSet[client] = GetPlayerModel( client );
		}
	
		SetEntityModel( client, HUSK_MDL );
		SetEntityHealth( client, GetConVarInt( g_HuskHP ));
		SetEntProp( client, Prop_Send, "m_ArmorValue", 100 );
		SetEntProp( client, Prop_Send, "m_bHasHelmet", 1 );
	
		SetEntityGravity( client, 0.7 );
		SetAlphaMode( client, 255, 200 );
		HuskGear( client, 200 );
		SetSpeedBoost( client );
	
		g_TerrorLife[client] = CreateTimer( 1.0, Timer_HuskLife, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
		
		PrintToChatAll( "\x01\x0B\x01%N \x01\x0B\x05spawn as \x01\x0B\x01Husk.", client );
	}
}

public Action:Timer_HuskLife(Handle:timer, any:client)
{
	if ( IsValidClient( client ))
	{
		KillBeamSpirit( client );
		SetUpBeam( client, "White", 0.7, 25.0, 50 );
	}
	else
	{
		KillBeamSpirit( client );
		
		if ( g_TerrorLife[client] != INVALID_HANDLE )
		{
			KillTimer( g_TerrorLife[client] );
			g_TerrorLife[client] = INVALID_HANDLE;
		}
		
		if ( g_KirbyLife == INVALID_HANDLE )
		{
			DropBonusItem_Kirby( client );
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_RemoveMissionItem(Handle:timer)
{
	g_LookUpExpired ++;
	new count = GetEntityCount();
	for ( new i = 0; i <= count; i++ )
	{
		if ( IsValidEntity( i ))
		{
			decl String:EntName[128];
			GetEntityClassname( i, EntName, sizeof( EntName ));
			if ( StrEqual( EntName, "hostage_entity", false ))
			{
				g_WinItemRemoved = true;
				AcceptEntityInput( i, "kill" );
			}
			if ( StrEqual( EntName, "weapon_c4", false ))
			{
				g_WinItemRemoved = true;
				SetEntDataEnt2( i, m_hOwnerEntity, -1);
				AcceptEntityInput( i, "kill" );
				break;
			}
		}
	}
	
	if ( g_LookUpExpired >= 20 || g_WinItemRemoved )
	{
		if ( g_TimerLookUp != INVALID_HANDLE )
		{
			KillTimer( g_TimerLookUp );
			g_TimerLookUp = INVALID_HANDLE;
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_RegisterItem(Handle:timer, any:client)
{
	ClearGarbage();
	
	if (( IsValid_T( client ) || IsValid_CT( client )) && IsPlayerAlive( client ))
	{
		decl String:ammoP1[32];
		new iAmmoOffset;
		new dataIndex;
		
		new slot0				= GetPlayerWeaponSlot( client, 0);
		new slot1				= GetPlayerWeaponSlot( client, 1);
		WeaponSlot[client][2]	= GetPlayerWeaponSlot( client, 2);
		WeaponSlot[client][3]	= GetPlayerWeaponSlot( client, 3);
		if ( slot0 != -1 )
		{
			if ( slot0 != WeaponSlot[client][0] )
			{
				SetAlphaMode( WeaponSlot[client][0], 255, 255 );
			}
			
			WeaponSlot[client][0] = slot0;
			
			if ( g_SuperSpeedTime[client] != INVALID_HANDLE || g_ClockDeviceTime[client] != INVALID_HANDLE )
			{
				SetAlphaMode( WeaponSlot[client][0], 255, 200 );
			}
			GetEdictClassname( WeaponSlot[client][0] , ammoP1, sizeof( ammoP1 ));
			iAmmoOffset = FindDataMapOffs( client, "m_iAmmo" );
			dataIndex = GetPrimaryAmmoIndex( ammoP1 );
			if ( dataIndex != -1 )
			{
				SetEntData( client, ( iAmmoOffset + i_PrimaryData[dataIndex][0] ), i_PrimaryData[dataIndex][1] );
			}
		}
		if ( slot1 != -1 )
		{
			if ( slot1 != WeaponSlot[client][1] )
			{
				SetAlphaMode( WeaponSlot[client][1], 255, 255 );
			}
			
			WeaponSlot[client][1] = slot1;
			
			if ( g_SuperSpeedTime[client] != INVALID_HANDLE || g_ClockDeviceTime[client] != INVALID_HANDLE )
			{
				SetAlphaMode( WeaponSlot[client][1], 255, 200 );
			}
			GetEdictClassname( WeaponSlot[client][1] , ammoP1, sizeof( ammoP1 ));
			iAmmoOffset = FindDataMapOffs( client, "m_iAmmo" );
			dataIndex = GetSecondaryAmmoIndex( ammoP1 );
			if ( dataIndex != -1 )
			{
				SetEntData( client, ( iAmmoOffset + i_SecondaryData[dataIndex][0] ), i_SecondaryData[dataIndex][1] );
			}
		}
	}
}

public Action:Timer_AddBot(Handle:timer, any:client)
{
	new T = GetConVarInt( g_TeamPlay_T );
	new CT = GetConVarInt( g_TeamPlay_CT );
	if ( T > CT )
	{
		SetConVarInt( FindConVar( "mp_limitteams" ),	T);
	}
	else
	{
		SetConVarInt( FindConVar( "mp_limitteams" ),	CT);
	}
	
	new player = 0;
	for ( new i = 1; i <= MaxClients; i++)
	{
		if ( IsValid_T( i ) || IsValid_CT( i ))
		{
			player ++;
		}
	}
	if ( player == 0 )
	{
		if ( T > 0 )
		{
			for ( new i = 1; i <= T; i++)
			{
				ServerCommand("bot_add_t");
			}
		}
		if ( CT > 0 )
		{
			for ( new i = 1; i <= CT; i++)
			{
				ServerCommand("bot_add_ct");
			}
		}
		g_BotAdded = true;
	}
}

public Action:Timer_CheckOneSideWin(Handle:timer)
{
	new Terror = 0;
	new CTerro = 0;
	for ( new i = 1; i <= MaxClients; i++)
	{
		if ( IsClientConnected( i ) && IsClientInGame( i ) && IsPlayerAlive( i ))
		{
			if ( GetClientTeam( i ) == TEAM_T ) Terror++;
			if ( GetClientTeam( i ) == TEAM_CT ) CTerro++;
		}
	}
	if ( Terror == 0 )
	{
		Add_TeamScoreWin( TEAM_CT );
		CS_TerminateRound( 3.0, CSRoundEnd_CTWin );
	}
	if ( CTerro == 0 )
	{
		Add_TeamScoreWin( TEAM_T );
		CS_TerminateRound( 3.0, CSRoundEnd_TerroristWin );
	}
}

public Action:Timer_PredatorGear(Handle:timer, any:client)
{
	if ( IsValid_T( client ) && IsPlayerAlive( client ))
	{
		PredatorGear( client, 150 );
	}
}

public Action:Timer_HuskGear(Handle:timer, any:client)
{
	if ( IsValid_T( client ) && IsPlayerAlive( client ))
	{
		HuskGear( client, 200 );
	}
}

public Action:Timer_MaxLifeSpawn(Handle:timer, any:index)
{
	if ( IsValidEntity( index ))
	{
		decl Float:maxPos[3];
		decl Float:maxAng[3];
		decl Float:pPos2[3];
		new Float:dis = 0.0;

		GetEntPropVector( index, Prop_Data, "m_angRotation", maxAng );
		GetEntPropVector( index, Prop_Send, "m_vecOrigin", maxPos );
	
		maxAng[1] += 6.0;
	
		TeleportEntity( index, NULL_VECTOR, maxAng, NULL_VECTOR);
	
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidClient( i ) && GetClientTeam( i ) == TEAM_CT )
			{
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", pPos2 );
				dis = GetVectorDistance( maxPos, pPos2 );
				if ( dis < 50.0 )
				{
					new r = GetRandomInt( 1, 10 );
					if ( r < 7 )
					{
						r = GetRandomInt( 4, 17 );
						new wep = CreateEntityByName( PrimaryNames[ r ] );
						if ( wep != -1 )
						{
							DispatchSpawn( wep );
							TeleportEntity( wep, maxPos, NULL_VECTOR, NULL_VECTOR );
							PrintToChat( i, "\x01\x0B\x05You reviced %s from \x01\x0B\x01Max", PrimaryNames[ r ] );
						}
					}
					else
					{
						new money = GetEntData( i, m_iAccount) + 1200;
						if ( money > 16000 )
						{
							money = 16000;
						}
						SetEntData( i, m_iAccount, money );
						PrintToChat( i, "\x01\x0B\x05You reviced Extra Money from \x01\x0B\x01Max" );
					}
					EmitSoundToClient( i, BONUS );
					AcceptEntityInput( index, "kill" );
					break;
				}
			}
		}
	}
	else
	{
		if ( g_MaxLife != INVALID_HANDLE )
		{
			KillTimer( g_MaxLife );
			g_MaxLife = INVALID_HANDLE;
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_EvaLifeSpawn(Handle:timer, any:index)
{
	if ( IsValidEntity( index ))
	{
		decl Float:evePos[3];
		decl Float:eveAng[3];
		decl Float:pPos[3];
		new Float:dis = 0.0;

		GetEntPropVector( index, Prop_Data, "m_angRotation", eveAng );
		GetEntPropVector( index, Prop_Send, "m_vecOrigin", evePos );
	
		eveAng[1] += 6.0;
	
		TeleportEntity( index, NULL_VECTOR, eveAng, NULL_VECTOR);
	
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidClient( i ) && GetClientTeam( i ) == TEAM_CT )
			{
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", pPos );
				dis = GetVectorDistance( evePos, pPos );
				if ( dis < 50.0 )
				{
					switch( GetRandomInt( 1, 2 ))
					{	
						case 1:
						{
							new h = GetEntProp( i, Prop_Data, "m_iHealth") + 50;
							if ( h > 200 )
							{
								h = 200;
							}
							SetEntProp( i, Prop_Data, "m_iHealth", h );
							PrintToChat( i, "\x01\x0B\x05You reviced extra health from \x01\x0B\x01Eva" );
						}
						case 2:
						{
							SetEntProp( i, Prop_Send, "m_ArmorValue", 125 );
							SetEntProp( i, Prop_Send, "m_bHasHelmet", 1 );
							PrintToChat( i, "\x01\x0B\x05You reviced Armor from \x01\x0B\x01Eva" );
						}
					}
					EmitSoundToClient( i, BONUS );
					AcceptEntityInput( index, "kill" );
					break;
				}
			}
		}
	}
	else
	{
		if ( g_EvaLife != INVALID_HANDLE )
		{
			KillTimer( g_EvaLife );
			g_EvaLife = INVALID_HANDLE;
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_KirbyLifeSpawn(Handle:timer, any:index)
{
	if ( IsValidEntity( index ))
	{
		decl Float:kirPos[3];
		decl Float:kirAng[3];
		decl Float:pPos1[3];
		new Float:dis = 0.0;

		GetEntPropVector( index, Prop_Data, "m_angRotation", kirAng );
		GetEntPropVector( index, Prop_Send, "m_vecOrigin", kirPos );
	
		kirAng[1] += 6.0;
	
		TeleportEntity( index, NULL_VECTOR, kirAng, NULL_VECTOR);
	
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidClient( i ) && GetClientTeam( i ) == TEAM_CT )
			{
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", pPos1 );
				dis = GetVectorDistance( kirPos, pPos1 );
				if ( dis < 50.0 )
				{
					ResetCTStat( i );
					switch( GetRandomInt( 1, 2 ))
					{	
						case 1:
						{
							g_PropCount[ i ] = 11;
							g_SuperSpeedTime[ i ] = CreateTimer( 1.0, Timer_SetSpeedProp,  i , TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							PrintToChat( i, "\x01\x0B\x05You reviced Super Speed from \x01\x0B\x01Kirby" );
						}
						case 2:
						{
							g_PropCount[ i ] = 11;
							g_ClockDeviceTime[ i ] = CreateTimer( 1.0, Timer_SetClockProp,  i , TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							PrintToChat( i, "\x01\x0B\x05You reviced Clocking Device from \x01\x0B\x01Kirby" );
						}
					}
					EmitSoundToClient( i, BONUS );
					AcceptEntityInput( index, "kill" );
					break;
				}
			}
		}
	}
	else
	{
		if ( g_KirbyLife != INVALID_HANDLE )
		{
			KillTimer( g_KirbyLife );
			g_KirbyLife = INVALID_HANDLE;
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_CheckNobGun(Handle:timer, any:client)
{
	if ( IsValidClient( client ) && GetEntData( client, m_iAccount) < GetConVarInt( g_StartUpGun ))
	{
		if ( GetPlayerWeaponSlot( client, 0 ) == -1 )
		{
			WeaponSlot[client][0] = GiveWeapon( client, PrimaryNames[ GetRandomInt( 0, 3 ) ], 0 );
		}
	}
}

GiveWeapon( client, const String:wName[], slot )
{
	new wep			= -1;
	new dataIndex	= -1;
	
	if ( IsValidClient( client ))
	{
		decl Float:noB[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", noB );
	
		wep = CreateEntityByName( wName );
		if ( wep != -1 )
		{
			SetEntDataEnt2( wep, m_hOwnerEntity, client );
			DispatchSpawn( wep );
			TeleportEntity( wep, noB, NULL_VECTOR, NULL_VECTOR );
			EquipPlayerWeapon( client, wep );
			SetEntPropEnt( client, Prop_Send, "m_hActiveWeapon", wep );
		
			if ( slot < 2 )
			{
				decl String:ammoP[32];
				GetEdictClassname( wep , ammoP, sizeof( ammoP ));
				new iAmmoOffset = FindDataMapOffs( client, "m_iAmmo" );
				
				switch( slot )
				{
					case 0:
					{
						dataIndex = GetPrimaryAmmoIndex( ammoP );
						if ( dataIndex != -1 )
						{
							SetEntData( client, ( iAmmoOffset + i_PrimaryData[dataIndex][0] ), i_PrimaryData[dataIndex][1] );
						}
					}
					case 1:
					{
						dataIndex = GetSecondaryAmmoIndex( ammoP );
						if ( dataIndex != -1 )
						{
							SetEntData( client, ( iAmmoOffset + i_SecondaryData[dataIndex][0] ), i_SecondaryData[dataIndex][1] );
						}
					}
				}
			}
		}
		EmitSoundToClient( client, AMMO );
	}
	return wep;
}

DestroyWeapon( client, slot )
{
	if ( IsValidClient( client ))
	{
		decl Float:desPos[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", desPos );
	
		desPos[2] += 5000.0;
	
		new des = GetPlayerWeaponSlot( client, slot );
		if ( des != -1 ) 
		{
			SetEntDataEnt2( des, m_hOwnerEntity, -1 );
			TeleportEntity( des, desPos, NULL_VECTOR, NULL_VECTOR );
			AcceptEntityInput( des, "kill" );
		}
	}
}

AlienGear( client, alpha )
{
	if ( IsValidClient( client ))
	{
		WeaponSlot[client][0] = GiveWeapon( client, "weapon_m4a1", 0 );
	
		DestroyWeapon( client, 1 );

		WeaponSlot[client][1] = GiveWeapon( client, "weapon_deagle", 1 );
	
		EquipPlayerWeapon( client, WeaponSlot[client][0] );
		SetEntPropEnt( client, Prop_Send, "m_hActiveWeapon", WeaponSlot[client][0] );
		SetAlphaMode( WeaponSlot[client][0], 255, alpha );
		SetAlphaMode( WeaponSlot[client][1], 255, alpha );
	}
}

PredatorGear( client, alpha )
{
	if ( IsValidClient( client ))
	{
		new laswep = GetPlayerWeaponSlot( client, 0 );
		
		if ( laswep != -1 )
		{
			if ( laswep != WeaponSlot[client][0] && WeaponSlot[client][0] != -1 && IsValidEntity( WeaponSlot[client][0] ))
			{
				AcceptEntityInput( WeaponSlot[client][0], "kill" );
			}
			DestroyWeapon( client, 0 );
		}
		
		new rn = GetRandomInt( 0, 3 );
		WeaponSlot[client][0] = GiveWeapon( client, PrimaryNames[ rn ], 0 );
		
		DestroyWeapon( client, 1 );
	
		WeaponSlot[client][1] = GiveWeapon( client, "weapon_deagle", 1 );
		
		SetAlphaMode( WeaponSlot[client][0], 255, alpha );
		SetAlphaMode( WeaponSlot[client][1], 255, alpha );
	}
}

HuskGear( client, alpha )
{
	if ( IsValidClient( client ))
	{
		for ( new i = 0; i < 5; i++ )
		{
			DestroyWeapon( client, i );
		}
	
		WeaponSlot[client][2] = GiveWeapon( client, "weapon_knife", 2 );
	
		SetAlphaMode( WeaponSlot[client][2], 255, alpha );
	}
}

SetUpExplosion( client )
{
	decl Float:vecOrigin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vecOrigin);

	vecOrigin[2] -= 30.0;
	
	TE_SetupSmoke( vecOrigin, g_FireSprite, 50.0, 5 );
	TE_SendToAll();
	
	TE_SetupExplosion( vecOrigin, g_FireSprite, 5.0, 2, 1, 50, 50 );
	TE_SendToAll();
	
	EmitAmbientSound( EXPLODE, vecOrigin, client, SNDLEVEL_NORMAL );
	
	SetAlphaMode( WeaponSlot[client][2], 255, 255 );
}

DropBonusItem_Eva( client )
{
	decl Float:sPos1[3];
	GetEntPropVector( client, Prop_Send, "m_vecOrigin", sPos1 );
	sPos1[2] -= 40.0;
	new ent = CreateEntityByName( "prop_dynamic" );
	if ( ent != -1 )
	{
		DispatchKeyValue( ent, "model", STAR_1_MDL );
		//SetEntPropFloat( ent, Prop_Send, "m_flModelScale", 0.8 );
		DispatchSpawn( ent );
		SetEntProp( ent, Prop_Send, "m_CollisionGroup", 1 ); 
		TeleportEntity( ent, sPos1, NULL_VECTOR, NULL_VECTOR);
		g_EvaLife = CreateTimer( 0.05, Timer_EvaLifeSpawn, ent, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
}

DropBonusItem_Kirby( client )
{
	decl Float:sPos2[3];
	GetEntPropVector( client, Prop_Send, "m_vecOrigin", sPos2 );
	sPos2[2] -= 40.0;
	new ent = CreateEntityByName( "prop_dynamic" );
	if ( ent != -1 )
	{
		DispatchKeyValue( ent, "model", STAR_2_MDL );
		//SetEntPropFloat( ent, Prop_Send, "m_flModelScale", 0.5 );
		DispatchSpawn( ent );
		SetEntProp( ent, Prop_Send, "m_CollisionGroup", 1 ); 
		TeleportEntity( ent, sPos2, NULL_VECTOR, NULL_VECTOR);
		g_KirbyLife = CreateTimer( 0.05, Timer_KirbyLifeSpawn, ent, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
}

DropBonusItem_Max( client )
{
	decl Float:sPos3[3];
	GetEntPropVector( client, Prop_Send, "m_vecOrigin", sPos3 );
	sPos3[2] -= 40.0;
	new ent = CreateEntityByName( "prop_dynamic" );
	if ( ent != -1 )
	{
		DispatchKeyValue( ent, "model", MUSHROOM_MDL );
		//SetEntPropFloat( ent, Prop_Send, "m_flModelScale", 0.3 );
		DispatchSpawn( ent );
		SetEntProp( ent, Prop_Send, "m_CollisionGroup", 1 ); 
		TeleportEntity( ent, sPos3, NULL_VECTOR, NULL_VECTOR);
		g_MaxLife = CreateTimer( 0.05, Timer_MaxLifeSpawn, ent, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
}

HumanDeadResault( client )
{
	new knife = GetPlayerWeaponSlot( client, 2 );
	if ( knife != -1 )
	{
		SetEntPropEnt( client, Prop_Send, "m_hActiveWeapon", knife );
		SetAlphaMode( knife, 255, 255 );
	}
	
	decl Float:dedPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", dedPos);
	dedPos[2] += 5000.0;
	if ( WeaponSlot[client][0] != -1 && IsValidEntity( WeaponSlot[client][0] ))
	{
		SetEntDataEnt2( WeaponSlot[client][0], m_hOwnerEntity, -1);
		TeleportEntity( WeaponSlot[client][0], dedPos, NULL_VECTOR, NULL_VECTOR );
		AcceptEntityInput( WeaponSlot[client][0], "kill" );
		WeaponSlot[client][0] = -1;
	}
	if ( WeaponSlot[client][1] != -1 && IsValidEntity( WeaponSlot[client][1] ))
	{
		SetEntDataEnt2( WeaponSlot[client][1], m_hOwnerEntity, -1);
		TeleportEntity( WeaponSlot[client][1], dedPos, NULL_VECTOR, NULL_VECTOR );
		AcceptEntityInput( WeaponSlot[client][1], "kill" );
		WeaponSlot[client][1] = -1;
	}
}

KillerBonus( client )
{
	if ( IsValid_CT( client ))
	{
		new money = GetEntData( client, m_iAccount) + 600;
		if ( money > 16000 )
		{
			money = 16000;
		}
		SetEntData( client, m_iAccount, money );
	}
}

ResetTerrorStat( client )
{
	if ( IsValidClient( client ))
	{
		new rand;

		if ( g_TerrorID[client][0] > 0 )
		{
			if ( WeaponSlot[client][0] != -1 )
			{
				SetAlphaMode( WeaponSlot[client][0], 255, 255 );
			}
			if ( WeaponSlot[client][1] != -1 )
			{
				SetAlphaMode( WeaponSlot[client][1], 255, 255 );
			}
	
			if ( g_ModelSet[client] != -1 )
			{
				SetEntityModel( client, T_Models[ g_ModelSet[client] ] );
			}
			else
			{
				rand = GetRandomInt( 0, 3 );
				SetEntityModel( client, T_Models[rand] );
			}
		
			SetAlphaMode( client, 255, 255 );
			SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
	
		if ( g_TerrorID[client][1] > 0 )
		{
			if ( g_ModelSet[client] != -1 )
			{
				SetEntityModel( client, T_Models[ g_ModelSet[client] ] );
			}
			else
			{
				rand = GetRandomInt( 0, 3 );
				SetEntityModel( client, T_Models[rand] );
			}
		}
	
		if ( g_TerrorID[client][2] > 0 )
		{
			if ( g_ModelSet[client] != -1 )
			{
				SetEntityModel( client, T_Models[ g_ModelSet[client] ] );
			}
			else
			{
				rand = GetRandomInt( 0, 3 );
				SetEntityModel( client, T_Models[rand] );
			}
			if ( WeaponSlot[client][2] != -1 )
			{
				SetAlphaMode( WeaponSlot[client][2], 255, 255 );
			}
			
			WeaponSlot[client][0] = GiveWeapon( client, PrimaryNames[ GetRandomInt( 4, 17 ) ], 0 );
			WeaponSlot[client][1] = GiveWeapon( client, SecondaryNames[ GetRandomInt( 0, 3 ) ], 1 );
			
			SetAlphaMode( client, 255, 255 );
			SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
	
		g_TerrorID[client][0] = 0;
		g_TerrorID[client][1] = 0;
		g_TerrorID[client][2] = 0;
	}
}

ResetCTStat( client )
{
	if ( IsValidClient( client ))
	{
		if ( g_SuperSpeedTime[client] != INVALID_HANDLE )
		{
			KillTimer( g_SuperSpeedTime[client] );
			g_SuperSpeedTime[client] = INVALID_HANDLE;
		}
		if ( g_ClockDeviceTime[client] != INVALID_HANDLE )
		{
			KillTimer( g_ClockDeviceTime[client] );
			g_ClockDeviceTime[client] = INVALID_HANDLE;
		}
		if ( g_ModelSet[client] != -1 )
		{
			SetEntityModel( client, CT_Models[ g_ModelSet[client] ] );
			g_ModelSet[client] = -1;
		}
		SetEntityGravity( client, 1.0 );
		SetAlphaMode( client, 255, 255 );
		SetAlphaMode( WeaponSlot[client][0], 255, 255 );
		SetAlphaMode( WeaponSlot[client][1], 255, 255 );
		SetEntProp( client, Prop_Data, "m_takedamage", 2, 1 );
		SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", 1.0 );
	}
}


AbortAction()
{
	for ( new i = 1; i <= MaxClients; i++)
	{
		g_CountDown[i]		= 0;
		g_PropCount[i]		= 0;
		g_SpawnBtn[i]		= false;
		g_ModelSet[i]		= -1;
		g_PredKillSnd[i][0]	= 0;
		g_PredKillSnd[i][1]	= 0;
		
		KillBeamSpirit( i );
		
		if ( g_TimerRespawn[i] != INVALID_HANDLE )
		{
			KillTimer( g_TimerRespawn[i] );
			g_TimerRespawn[i] = INVALID_HANDLE;
			
			if ( !IsFakeClient( i ))
			{
				PrintHintText( i, "");
			}
		}
		if ( g_SuperSpeedTime[i] != INVALID_HANDLE )
		{
			KillTimer( g_SuperSpeedTime[i] );
			g_SuperSpeedTime[i] = INVALID_HANDLE;
		}
		if ( g_ClockDeviceTime[i] != INVALID_HANDLE )
		{
			KillTimer( g_ClockDeviceTime[i] );
			g_ClockDeviceTime[i] = INVALID_HANDLE;
		}
		if ( g_TimerAddHP[i] != INVALID_HANDLE )
		{
			KillTimer( g_TimerAddHP[i] );
			g_TimerAddHP[i] = INVALID_HANDLE;
		}
		if ( g_TimerPredKillSnd[i]	!= INVALID_HANDLE )
		{
			KillTimer( g_TimerPredKillSnd[i] );
			g_TimerPredKillSnd[i]	= INVALID_HANDLE;
		}
		if ( g_TerrorLife[i] != INVALID_HANDLE )
		{
			KillTimer( g_TerrorLife[i] );
			g_TerrorLife[i] = INVALID_HANDLE;
		}
	}
	if ( g_TimerServerMSG != INVALID_HANDLE )
	{
		KillTimer( g_TimerServerMSG );
		g_TimerServerMSG = INVALID_HANDLE;
	}
	if ( g_TimerLookUp != INVALID_HANDLE )
	{
		KillTimer( g_TimerLookUp );
		g_TimerLookUp = INVALID_HANDLE;
	}
}

RestartAction()
{
	if ( g_TimerServerMSG == INVALID_HANDLE )
	{
		g_TimerServerMSG = CreateTimer( 300.0, Timer_ServerMSG, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
	if ( g_TimerLookUp == INVALID_HANDLE )
	{
		g_TimerLookUp = CreateTimer( 0.6, Timer_RemoveMissionItem, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
	
	CreateTimer( 1.0, Timer_AddBot, _, TIMER_FLAG_NO_MAPCHANGE );
}

GetPlayerModel( client )
{
	new model = -1;
	new String:Model[128];
	
	if ( IsValid_CT( client ))
	{
		GetClientModel( client, Model , sizeof( Model ));
		for ( new i = 0; i < 4; i++ )
		{
			if ( StrEqual( Model, CT_Models[i], false ))
			{
				model = i;
				break;
			}
		}
	}
	if ( IsValid_T( client ))
	{
		GetClientModel( client, Model , sizeof( Model ));
		for ( new i = 0; i < 4; i++ )
		{
			if ( StrEqual( Model, T_Models[i], false ))
			{
				model = i;
				break;
			}
		}
	}
	return model;
}

GetPrimaryAmmoIndex( const String:weapon[] )
{
	for ( new i = 0; i < PRIMARY; i++ )
	{
		if ( StrEqual( weapon, PrimaryNames[i] ))
		{
			return i;
		}
	}
	return -1;
}

GetSecondaryAmmoIndex( const String:weapon[] )
{
	for ( new i = 0; i < SECONDARY; i++ )
	{
		if ( StrEqual( weapon, SecondaryNames[i] ))
		{
			return i;
		}
	}
	return -1;
}

SetSpeedBoost( client )
{
	if ( IsValidClient( client ))
	{
		g_Boost = ( GetConVarFloat( g_PredatorBoost ) / 100.0 ) + 1.0;
		if ( g_Boost <= 0.0 ) g_Boost = 1.0;
		if ( g_Boost >= 2.0 ) g_Boost = 2.0;
		SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", g_Boost );
	}
}

RemoveFunctionZone()
{
	new entCount = GetMaxEntities();
	decl String:entName[64];
	
	for ( new i = 0; i < entCount; i++ )
	{
		if ( !IsValidEntity( i )) continue;
		
		GetEdictClassname(i, entName, 63);
		/*
		if ( StrEqual( entName, "func_buyzone", false ))
		{
			AcceptEntityInput( i, "kill" );
		}
		*/
		if ( StrEqual( entName, "func_bombzone", false ) || StrEqual( entName, "func_bomb_target", false ) || StrEqual( entName, "func_hostage_rescue", false ))
		{
			AcceptEntityInput( i, "kill" );
		}
		if ( StrEqual( entName, "prop_physics_multiplayer", false ))
		{
			AcceptEntityInput( i, "kill" );
		}
		if ( StrEqual( entName, "prop_physics", false ))
		{
			AcceptEntityInput( i, "kill" );
		}
	}
}

ClearGarbage()
{
	new entCount = GetMaxEntities();
	decl String:wepName[64];
	
	for ( new i = 0; i < entCount; i++ )
	{
		if ( IsValidEntity( i ))
		{
			GetEdictClassname( i, wepName, sizeof( wepName ));
			if ( StrEqual( wepName, "weapon_usp", false ) && GetEntDataEnt2( i, m_hOwnerEntity) == -1 )
			{
				AcceptEntityInput( i, "kill" );
			}
			if ( StrEqual( wepName, "weapon_glock", false ) && GetEntDataEnt2( i, m_hOwnerEntity) == -1 )
			{
				AcceptEntityInput( i, "kill" );
			}
			if ( StrEqual( wepName, "weapon_knife", false ) && GetEntDataEnt2( i, m_hOwnerEntity) == -1 )
			{
				AcceptEntityInput( i, "kill" );
			}
		}
	}
}

PlayKillingSound( client, type )
{
	if ( type == 1 )
	{
		decl String:HH[32];
		switch( GetRandomInt( 1, 3 )) {
			case 1: { HH = HEADSHOT		;}
			case 2: { HH = HOLLYSHT		;}
			case 3: { HH = HEADHUNT		;}
		}
		StopAllSound( client );
		EmitSoundToClient( client, HH );
	}
	if ( type == 2 )
	{
		decl String:HH2[32];
		switch( GetRandomInt( 1, 3 )) {
			case 1: { HH2 = DOMINATE	;}
			case 2: { HH2 = COMBHOW		;}
			case 3: { HH2 = HATTRIC		;}
		}
		StopAllSound( client );
		EmitSoundToClient( client, HH2 );
	}
	if ( type == 3 )
	{
		decl String:HH3[32];
		switch( GetRandomInt( 1, 3 )) {
			case 1: { HH3 = LUDICROU	;}
			case 2: { HH3 = RAMPAGE		;}
			case 3: { HH3 = WICKEDSIK	;}
		}			
		StopAllSound( client );
		EmitSoundToClient( client, HH3 );
	}
	if ( type == 4 )
	{
		StopAllSound( client );
		EmitSoundToClient( client, TEAM_KILLER );
	}
}

StopAllSound( client )
{
	StopSound( client, SNDCHAN_AUTO, FIRSTBLD );
	StopSound( client, SNDCHAN_AUTO, DOUBLEKL );
	StopSound( client, SNDCHAN_AUTO, TRIPLEKL );
	StopSound( client, SNDCHAN_AUTO, MONSTEKL );
	StopSound( client, SNDCHAN_AUTO, ULTRAKL );
	StopSound( client, SNDCHAN_AUTO, GODLIKE );
	StopSound( client, SNDCHAN_AUTO, LUDICROU );
	StopSound( client, SNDCHAN_AUTO, RAMPAGE );
	StopSound( client, SNDCHAN_AUTO, WICKEDSIK );
	StopSound( client, SNDCHAN_AUTO, DOMINATE );
	StopSound( client, SNDCHAN_AUTO, COMBHOW );
	StopSound( client, SNDCHAN_AUTO, HATTRIC );
	StopSound( client, SNDCHAN_AUTO, HEADSHOT );
	StopSound( client, SNDCHAN_AUTO, HOLLYSHT );
	StopSound( client, SNDCHAN_AUTO, HEADHUNT );
	StopSound( client, SNDCHAN_AUTO, FUN_1 );
	StopSound( client, SNDCHAN_AUTO, FUN_2 );
	StopSound( client, SNDCHAN_AUTO, TEAM_KILLER );
}

SetUpBeam( client, const String:color[], Float:Life, Float:width, Alpha )
{
	new Color[4];
	Color[0] = 0;
	Color[1] = 0;
	Color[2] = 0;
	Color[3] = Alpha;
	if ( StrEqual( color, "Red", false ))
	{
		Color[0] = 255;
	}
	else if ( StrEqual( color, "Green", false ))
	{
		Color[1] = 255;
	}
	else if ( StrEqual( color, "Blue", false ))
	{
		Color[2] = 255;
	}
	else if ( StrEqual( color, "White", false ))
	{
		Color[0] = 255;
		Color[1] = 255;
		Color[2] = 255;
	}
	
	// code from Bacardi.
	new ent = CreateEntityByName("prop_dynamic");
	if( ent == -1 )
	{
		PrintToServer( "Create entity for beam parent failed!!!" );
		return;
	}

	DispatchKeyValue( ent, "model", BEAMOBJECT );
	DispatchKeyValue( ent, "skin", "0");
	DispatchKeyValue( ent, "spawnflags", "0");
	DispatchSpawn( ent );
	SetEntPropFloat( ent, Prop_Send, "m_flModelScale", 0.5 );
	SetAlphaMode( ent, 0, 0 );
	
	new Float:origin[3];
	GetClientAbsOrigin( client, origin );
	origin[2] += 50.0;
	TeleportEntity( ent, origin, NULL_VECTOR, NULL_VECTOR );
	
	SetVariantString( "!activator" );
	AcceptEntityInput( ent, "SetParent", client );

	SetVariantString( "OnUser1 !self,SetParentAttachmentMaintainOffset,forward,0.1,-1" );
	AcceptEntityInput( ent, "AddOutput" );
	AcceptEntityInput( ent, "FireUser1" );
	// end of code
	
	new masterColor[4];
	masterColor[0] = 255;
	masterColor[1] = 0;
	masterColor[2] = 0;
	masterColor[3] = Color[3];
	TE_SetupBeamFollow( ent , g_BeamSprite,	0, Life, 5.0, 5.0, 3, masterColor);
	TE_SendToAll();
	
	TE_SetupBeamFollow( ent , g_BeamSprite,	0, Life, width, 5.0, 3, Color);
	TE_SendToAll();
	
	g_ClientBeamSP[client] = ent;
}

KillBeamSpirit( client )
{
	if ( g_ClientBeamSP[client] != -1 && IsValidEntity( g_ClientBeamSP[client] ))
	{
		AcceptEntityInput( g_ClientBeamSP[client], "kill" );
	}
	g_ClientBeamSP[client] = -1;
}

SetupSpark( client, cool )
{
	new colour[4];
	colour[0] = 0;
	colour[1] = 0;
	colour[2] = 0;
	colour[3] = 50;
	
	switch( cool ) {
		case 1: {
			 // green
			colour[1] = 255;
		}
		case 2: {
			// light blue
			colour[0] = 128;
			colour[1] = 255;
			colour[2] = 255;
		}
		case 3: {
			 // light purple
			colour[0] = 255;
			colour[1] = 128;
			colour[2] = 255;
		}
	}
	
	decl Float:vecOrigin[3];
	for ( new i = 1; i <= 5; i++ )
	{
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", vecOrigin);
		vecOrigin[0] += GetRandomFloat( -30.0, 30.0 );
		vecOrigin[1] += GetRandomFloat( -30.0, 30.0 );
		vecOrigin[2] += GetRandomFloat( 10.0, 80.0 );
		TE_SetupBloodSprite( vecOrigin, NULL_VECTOR, colour, GetRandomInt( 5, 50 ), g_FireSprite, g_FireSprite );
		TE_SendToAll();
	}
}

CountDown( client, digit )
{
	switch( digit ) {
		case 10: { EmitSoundToClient( client, C4_10 )	;}
		case 9: { EmitSoundToClient( client, C4_9 )		;}
		case 8: { EmitSoundToClient( client, C4_8 )		;}
		case 7: { EmitSoundToClient( client, C4_7 )		;}
		case 6: { EmitSoundToClient( client, C4_6 )		;}
		case 5: { EmitSoundToClient( client, C4_5 )		;}
		case 4: { EmitSoundToClient( client, C4_4 )		;}
		case 3: { EmitSoundToClient( client, C4_3 )		;}
		case 2: { EmitSoundToClient( client, C4_2 )		;}
		case 1: { EmitSoundToClient( client, C4_1 )		;}
	}
}

bool:IsCanSpawn()
{
	g_MaxPredator = RoundToCeil( GetConVarFloat( g_PredatorNum ) * float( Get_TerrorisCount() ) / 100.0 );
	if ( g_MaxPredator < 1 ) return false;
	if ( g_SpecialTerrorCount > g_MaxPredator ) return false;
	return true;
}

stock SetClientScore( index, value )
{
	SetEntProp( index, Prop_Data, "m_iFrags", value );
	SetEntProp( index, Prop_Data, "m_iDeaths", value );
}

stock Get_TerrorisCount()
{
	new count = 0;
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsValid_T( i )) count++;
	}
	return count;
}

stock Get_CTerrorisCount_Human()
{
	new count = 0;
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsValid_CT( i ) && !IsFakeClient( i )) count++;
	}
	return count;
}

stock CheatCommand( client, const String:command[], const String:item[] )
{
	new userflags = GetUserFlagBits( client );
	new cmdflags = GetCommandFlags( command );
	SetUserFlagBits( client, ADMFLAG_ROOT);
	SetCommandFlags( command, cmdflags & ~FCVAR_CHEAT);
	FakeClientCommand( client,"%s %s", command, item );
	SetCommandFlags( command, cmdflags);
	SetUserFlagBits( client, userflags);
}

stock SetAlphaMode( index, color, alpha )
{
	if ( IsValidEntity ( index ))
	{
		SetEntityRenderMode(  index, RENDER_TRANSCOLOR );
		SetEntityRenderColor(  index, color, color, color, alpha );
	}
}

stock Add_TeamScoreWin( team )
{
	SetTeamScore( team, ( GetTeamScore( team ) + 1 ));
}

stock bool:IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( GetClientTeam( client ) == 1 ) return false;
	if ( !IsPlayerAlive( client )) return false;
	return true;
}

stock bool:IsValid_T( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( GetClientTeam( client ) != TEAM_T ) return false;
	return true;
}

stock bool:IsValid_CT( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( GetClientTeam( client ) != TEAM_CT ) return false;
	return true;
}
