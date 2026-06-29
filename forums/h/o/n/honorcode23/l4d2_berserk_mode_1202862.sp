//Includes
#include <sourcemod>
#include <sdktools>

//Definitions
#define SOUND1 "ui/pickup_secret01.wav"
#define SOUND2 "ui/pickup_misc42.wav"
#define BERSERKSOUND "music/tank/onebadtank"
#define ENDSOUND "music/the_end/kalin"
#define SOUND_FREEZE "ui/pickup_guitarriff10.wav"
#define SOUND_DUMB "music/gallery_music.mp3"
#define GETVERSION "1.5.3d"

//Source - SourceMod Wiki, User messages tutorial!
#define		FFADE_IN            0x0001        // Just here so we don't pass 0 into the function
#define		FFADE_OUT           0x0002        // Fade out (not in)
#define		FFADE_MODULATE      0x0004        // Modulate (don't blend)
#define		FFADE_STAYOUT       0x0008        // ignores the duration, stays faded out until new ScreenFade message received
#define		FFADE_PURGE         0x0010        // Purges all other fades, replacing them with this one

//-------------------------------------------------------------------------
//							Strings and Cvars
//------------------------------------------------------------------------

//global strings
new hasberserker_[MAXPLAYERS+1] = 0;
new enablezerk[MAXPLAYERS+1] = 0;
new team[MAXPLAYERS+1];
new isincaped_[MAXPLAYERS+1] = 0;
new zombieclass[MAXPLAYERS+1] = 0;
new hasicebullets[MAXPLAYERS+1] = ;
new hasdumbberserker_[MAXPLAYERS+1] = 0;
new icebullets[MAXPLAYERS+1] = 0;


//survivor strings
new killcount[MAXPLAYERS+1];
new killcount2[MAXPLAYERS+1];
new friendlycount[MAXPLAYERS+1];

//Infected Strings
new dmgcount[MAXPLAYERS+1];
new doingpounce[MAXPLAYERS+1] = 0;
new doingchoke[MAXPLAYERS+1] = 0;
new doingride[MAXPLAYERS+1] = 0;

//Global Cvars
new Handle:CvarGoal = INVALID_HANDLE;
new Handle:CvarDuration = INVALID_HANDLE;

//Survivor Cvars
new Handle:CvarMusic = INVALID_HANDLE;
new Handle:CvarTakeH = INVALID_HANDLE;
new Handle:CvarGoalH = INVALID_HANDLE;
new Handle:CvarAmountH = INVALID_HANDLE;
new Handle:CvarSpecialH = INVALID_HANDLE;
new Handle:CvarAmountSH = INVALID_HANDLE;
new Handle:CvarGiveShot = INVALID_HANDLE;
new Handle:CvarGiveBullet = INVALID_HANDLE;
new Handle:CvarGiveFBullet = INVALID_HANDLE;
new Handle:CvarDebug = INVALID_HANDLE;
new Handle:CvarBindKey = INVALID_HANDLE;
new Handle:CvarIncapInmu = INVALID_HANDLE;
new Handle:CvarAtackInmu = 	INVALID_HANDLE;
new Handle:CvarDDamage = INVALID_HANDLE;
new Handle:CvarInfected = INVALID_HANDLE;
new Handle:CvarSurvivor = INVALID_HANDLE;
new Handle:CvarInfGoal = INVALID_HANDLE;
new Handle:CvarMode = INVALID_HANDLE;
new Handle:CvarTime = INVALID_HANDLE;
new Handle:CvarADamage = INVALID_HANDLE;
new Handle:CvarDHealth = INVALID_HANDLE;
new Handle:CvarAHealth = INVALID_HANDLE;
new Handle:CvarExTank = INVALID_HANDLE;
new Handle:CvarShove = INVALID_HANDLE;
new Handle:CvarAnimation = INVALID_HANDLE;
new Handle:CvarIFBullet = INVALID_HANDLE;
new Handle:CvarMelee = INVALID_HANDLE;
new Handle:CvarKey = INVALID_HANDLE;
new Handle:CvarGodEnable = INVALID_HANDLE;
new Handle:CvarGodTime = INVALID_HANDLE;
new Handle:CvarAutomatic = INVALID_HANDLE;
new Handle:CvarLaser = INVALID_HANDLE;
new Handle:CvarCColor = INVALID_HANDLE;
new Handle:CvarColor = INVALID_HANDLE;
new Handle:CvarBulletOnly = INVALID_HANDLE;
//new Handle:CvarIceBullets = INVALID_HANDLE;
//new Handle:CvarIIceBullets = INVALID_HANDLE;
//new Handle:CvarLethalBite = INVALID_HANDLE;
//new Handle:CvarABerserk = INVALID_HANDLE;
//new Handle:CvarABerserkDur = INVALID_HANDLE;
//new Handle:CvarABerserkBlind = INVALID_HANDLE;
//new Handle:CvarABerserkSpeed = INVALID_HANDLE;
//new Handle:CvarABerserkBlock = INVALID_HANDLE;
//new Handle:CvarABerserkRemove = INVALID_HANDLE;
//new Handle:CvarABerserkRecycle = INVALID_HANDLE;

//DEBUG
new Handle:StrictDebug = INVALID_HANDLE;

//Offsets
static LagMovement = 0;
static ShovePenalty = 0;
static AdrenalineUsed = 0;
static TempHealth = 0;
static TempHealthTime = 0;
//static OldAmmoSize = 0;
//static NewAmmoSize = 0;

//Plugin Info
public Plugin:myinfo = 
{
	name = "Berserker Mode",
	author = "honorcode23",
	description = "Enters on Berserker Mode after x amount of killed infected",
	version = "GETVERSION",
	url = "http://forums.alliedmods.net/showthread.php?t=127518"
}

public OnPluginStart()
{
	//Left 4 dead 2 only
	decl String:game[256];
	GetGameFolderName(game, sizeof(game));
	if (!StrEqual(game, "left4dead2", false))
	{
		SetFailState("Berserker Mode supports Left 4 dead 2 only!");
	}
	
	//-------------------------------------------------------------------------
	//						Config ConVars and commands
	//------------------------------------------------------------------------
	
	//Debug purposes (This CVARS should never be enabled on public servers, anoying chat spamming will be enabled)
	StrictDebug = CreateConVar("l4d2_berserk_mode_strict_debug", "0", "Debug Everything.[ENABLE IF YOU ARE GOING TO TEST PLUGIN FUNCTIONALITY]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	//Global
	CreateConVar("l4d2_berserk_mode_version", GETVERSION, "Version of Berserker Mode Plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CvarMode = CreateConVar("l4d2_berserk_mode_count", "1", "How should the kill or damage count work?(0 = Timed, 1 = Not timed)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarTime = CreateConVar("l4d2_berserk_mode_time", "30.0", "How much time must pass between kills or attacks to reset count?", FCVAR_PLUGIN);
	CvarDuration = CreateConVar("l4d2_berserk_mode_duration", "30.0", "Amount of time to berserk", FCVAR_PLUGIN);
	CvarAutomatic = CreateConVar("l4d2_berserk_mode_auto", "0", "Should the Berserk Mode toggle on by itself? (Automatic?)", FCVAR_PLUGIN, true, 0.0, true, 1.0); 
	CvarMusic = CreateConVar("l4d2_berserk_mode_play_music", "1", "Should the plugin play music when the players are under Berserker Mode?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarSurvivor = CreateConVar("l4d2_berserk_mode_survivor", "1", "Enable Berserker On survivors?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarInfected = CreateConVar("l4d2_berserk_mode_infected", "1", "Enable Berserker On infected?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarDebug = CreateConVar("l4d2_berserk_mode_debug", "0", "Debug information", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarCColor = CreateConVar("l4d2_berserk_mode_change_color", "1", "Should the plugin change a special color on players with berserker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarColor = CreateConVar("l4d2_berserk_mode_color", "1", "What color should the players have on berserker? (1 = RED, 2 = BLUE, 3 = GREEN, 4 = BLACK, 5 = TRANSPARENT)", FCVAR_PLUGIN, true, 1.0, true, 5.0);
	CvarKey = CreateConVar("l4d2_berserk_mode_binding_key", "b", "Which Key should the plugin bind for berserker? Default is B key", FCVAR_PLUGIN);
	
	//Survivor Options
	CvarGoal = CreateConVar("l4d2_berserk_mode_goal", "45", "Amount of killed infected to berserk", FCVAR_PLUGIN);
	CvarMelee = CreateConVar("l4d2_berserk_mode_melee_only", "0", "Only Melee kills are valid kills? 0 = Disable, 1 = Enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarBulletOnly = CreateConVar("l4d2_berserk_mode_bullet_only", "0", "Only Bullet based kills are valid kills? (Explosives and melee excluded) 0 Disable, 1 = Enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarTakeH = CreateConVar("l4d2_berserk_mode_health", "1", "While in berserker mode, should the player get health after X amount of infected killed?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarGoalH = CreateConVar("l4d2_berserk_mode_health_goal", "20", "Amount of infected killed on berserker to get health", FCVAR_PLUGIN);
	CvarAmountH = CreateConVar("l4d2_berserk_mode_health_amount", "3", "Amount of health given when a certain ammount of infected is killed on berserker", FCVAR_PLUGIN);
	CvarSpecialH = CreateConVar("l4d2_berserk_mode_health_special", "1", "Instant health On Special Infected Kill under Berserker Mode?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarAmountSH = CreateConVar("l4d2_berserk_mode_health_amount_special", "2", "Amount of health given when an special infected is killed on berserker mode", FCVAR_PLUGIN);
	CvarGiveShot = CreateConVar("l4d2_berserk_mode_give_shot_mode", "1", "Should the plugin give adrenaline, or add its effects by itself? 0 = Disable, 1 = Give Shot, 2 = Effects", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	CvarGiveBullet = CreateConVar("l4d2_berserk_mode_refill_weapon", "1", "Should the plugin refill players weapon on berserker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarGiveFBullet = CreateConVar("l4d2_berserk_mode_give_fire_bullets", "1", "Should the plugin give fire bullets to the player on berserker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarBindKey = CreateConVar("l4d2_berserk_mode_bind_key", "1", "Should the plugin Bind the B key for berserker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarIncapInmu = CreateConVar("l4d2_berserk_mode_incap_inmu", "1", "Should the plugin give inmunity if the player gets incapacitated on berserker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarShove = CreateConVar("l4d2_berserk_mode_shove_penalty", "1", "Disable shoving penalty during berserker? (Will not affect other plugins with this function)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarAnimation = CreateConVar("l4d2_berserk_mode_animation_type", "3", "What kind of animation should we use for berserker? 0 = None, 1 = Fire, 2 = Adrenaline style 3 = Both (May cause low performance)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	CvarIFBullet = CreateConVar("l4d2_berserk_mode_infinite_fire_bullets", "1", "Should the fire bullets be infinite?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarGodEnable = CreateConVar("l4d2_berserk_mode_god_mode", "0", "Should we give god mode to survivors during Berserker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarGodTime = CreateConVar("l4d2_berserk_mode_god_mode_time", "3.0", "How long should the God Mode last?", FCVAR_PLUGIN);
	CvarLaser = CreateConVar("l4d2_berserk_mode_give_laser", "0", "Should the plugin give a laser on berserker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	//Infected Options
	CvarInfGoal = CreateConVar("l4d2_berserk_mode_infected_goal", "75", "Number of times an infected attacks a survivor to berserk", FCVAR_PLUGIN);
	CvarDDamage = CreateConVar("l4d2_berserk_mode_extra_damage", "1", "Should the plugin give extra damage for infected on berserker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarAtackInmu = CreateConVar("l4d2_berserk_mode_atack_inmu", "1", "Hunters, Smokers and Jockeys, can't be killed during their special ability, they must be shoved(On Berserker)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarADamage = CreateConVar("l4d2_berserk_mode_extra_damage_amount", "0.5", "Multiplier for extra infected damage (1.0 = Double)", FCVAR_PLUGIN);
	CvarDHealth = CreateConVar("l4d2_berserk_mode_extra_health", "1", "Should the plugin give extra health for infected on berserker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarAHealth = CreateConVar("l4d2_berserk_mode_extra_health_amount", "2.0", "Multiplier for extra infected health (2.0 = Double)", FCVAR_PLUGIN);
	CvarExTank = CreateConVar("l4d2_berserk_mode_exclude_tank", "1", "Disable Berserker if the infected is a Tank?(Exclude = 1, Dont Exclude = 0)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	//Commands
	RegConsoleCmd("sm_berserker", CmdBerserker, "Toggle Berserker if it is enabled");
	RegConsoleCmd("sm_killcount", CmdKillCount, "Get Debug Zombie Count");
	
	//These are development related and will be deleted in the future
	RegAdminCmd("sm_forcezerk", CmdForceZerk, ADMFLAG_SLAY, "Forces berserk on yourself");
	RegAdminCmd("sm_forcegod", CmdForceGod, ADMFLAG_SLAY, "For test of some godmode properties");
	RegAdminCmd("sm_forcegod0", CmdForceGodOff, ADMFLAG_SLAY, "Disables forced god");
	RegAdminCmd("sm_forcezerkon", CmdForceZerkOn, ADMFLAG_SLAY, "Forces berserker on someone else");
	RegAdminCmd("sm_zerkon", CmdEnableZerk, ADMFLAG_SLAY, "Enables Berserker On You");
	RegAdminCmd("sm_forceazerk", CmdForceAntiZerk, ADMFLAG_SLAY, "Forces anti-berserker on yourself");
	RegAdminCmd("sm_debugreport", CmdDebugReport, ADMFLAG_SLAY, "Debug report");
	//RegAdminCmd("sm_ragecount", CmdRageCount, ADMFLAG_SLAY, "Prints current rage 'o meter and rage points");
	//RegAdminCmd("sm_forceadren", CmdForceAdren, ADMFLAG_SLAY, "Adrenaline!");
	//RegAdminCmd("sm_forceadren0", CmdForceAdrenOff, ADMFLAG_SLAY, "Adrenaline!");
	
	//Create Config File
	AutoExecConfig(true, "l4d2_berserk_mode");
	
	//Translations
	LoadTranslations("common.phrases");
	LoadTranslations("l4d2_berserk_mode.phrases");
}

public OnMapStart()
{
	RunBerserkCount()
	
	//Precache Sounds
	PrecacheSound(SOUND1);
	PrecacheSound(SOUND2);
	PrecacheSound(BERSERKSOUND);
	PrecacheSound("player/survivor/voice/mechanic/battlecry01.wav");
	PrecacheSound("player/survivor/voice/producer/battlecry02.wav");
	PrecacheSound("player/survivor/voice/coach/battlecry09.wav");
	PrecacheSound("player/survivor/voice/gambler/battlecry04.wav");
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToServer("[PLUGIN]Sounds have been precached");
	}
	// Plugin handled
	return Plugin_Handled;
}

public OnGameFrame()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(i==0 || !IsClientInGame(i))
		{
			return;
		}
		team[i] = GetClientTeam(i)
		if(team[i] == 2 && IsPlayerAlive(i) && IsClientInGame(i) && hasberserker_[i] == 1 && GetConVarInt(CvarShove) == 1)
		{
			if(GetClientButtons(i) & IN_ATTACK2)
			{
				SetEntData(i, ShovePenalty, 0, 4);
				if(GetConVarInt(StrictDebug) == 1)
				{
					PrintToConsole(i, "[PLUGIN]Shove fatige disabled");
				}
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if(client == 0)
	{
		return;
	}
	if(GetConVarInt(CvarBindKey) == 1)
	{
		decl String:bind[2]
		GetConVarString(CvarKey, bind, sizeof(bind))
		ClientCommand(client, "bind %s sm_berserker", bind);
		if(GetConVarInt(StrictDebug) == 1)
		{
			PrintToConsole(client, "[PLUGIN]Your [%s] key will now activate berserker", bind);
		}
	}
}

public OnMapEnd()
{
	UnhookEvent("infected_death", InfectedKilled);
	UnhookEvent("player_death", OnPlayerDeath);
	for(new i=1; i<=MaxClients; i++)
	{
		killcount[i] = 0
		killcount2[i] = 0
		dmgcount[i] = 0
		hasberserker_[i]= 0
		enablezerk[i] = 0
		doingride[i] = 0
		doingpounce[i] = 0
		doingchoke[i] = 0
		isincaped_[i] = 0
	}
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToServer("[PLUGIN]Counts and controls have been resetted");
	}

}

public OnRoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		killcount[i] = 0
		killcount2[i] = 0
		dmgcount[i] = 0
		hasberserker_[i]= 0
		enablezerk[i] = 0
		doingride[i] = 0
		doingpounce[i] = 0
		doingchoke[i] = 0
		isincaped_[i] = 0
	}
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToServer("[PLUGIN]Counts and controls have been resetted");
	}
}

public Action:CmdForceZerk(client, args)
{
	if(client == 0)
	{
		return;
	}
	PlayerHasBerserker(client)
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToServer("[PLUGIN]%s forced berserker on himself", client);
		PrintToChat(client, "[PLUGIN]You forced berserker on yourself!");
	}
}

public Action:CmdForceAntiZerk(client, args)
{
	if(client == 0)
	{
		return;
	}
	PlayerIsDumb(client)
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToServer("[PLUGIN]%s forced anti-berserker on himself", client);
		PrintToChat(client, "[PLUGIN]You forced anti-berserker on yourself!");
	}
}

public Action:CmdForceZerkOn(client, args)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			PlayerHasBerserker(i)
		}
	}
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToServer("[PLUGIN]%s forced berserker on all players", client);
		PrintToChatAll("[PLUGIN]An admin forced berserker on everybody!");
	}
}

public Action:CmdForceGod(client, args)
{
	if(client == 0)
	{
		return;
	}
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToServer("[PLUGIN]%s forced god mode on himself", client);
		PrintToChat(client, "[PLUGIN]You forced berserker on yourself");
	}
}

public Action:CmdEnableZerk(client, args)
{
	enablezerk[client] = 1;
	if(GetConVarInt(CvarDebug) == 1)
	{
		PrintToChat(client, "%t", "ZerkReady", LANG_SERVER);
	}
	PrintHintText(client, "%t", "CenterZerkReady", LANG_SERVER);
	PrintToChat(client, "%t", "ZerkReadyChat", LANG_SERVER);
	new Handle:pack = CreateDataPack();
	
	WritePackCell(pack, client);
	WritePackString(pack, "Berserker is ready!");
	WritePackString(pack, "sm_berserker");
	CreateTimer(0.1, DisplayHint, pack);
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToServer("[PLUGIN]%s force berserker to be ready on himself", client);
		PrintToChat(client, "[PLUGIN]You forced berserker to be ready on yourself");
	}
}

public Action:CmdForceGodOff(client, args)
{
	if(client == 0)
	{
		return;
	}
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToServer("[PLUGIN]%s retrieved god mode from himself", client);
		PrintToChat(client, "[PLUGIN]You retrieved god mode from yourself");
	}
}

public Action:CmdDebugReport(client, args)
{
	if(GetConVarInt(StrictDebug) == 1)
	{
		decl String:weapon[256]; 
		decl String:godmode[30];
		new entity = GetEntDataEnt2(client, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
		if(GetEntProp(client, Prop_Data, "m_takedamage") == 2)
		{
			Format(godmode, sizeof(godmode), "Disabled");
		}
		if(GetEntProp(client, Prop_Data, "m_takedamage") == 0)
		{
			Format(godmode, sizeof(godmode), "Enabled");
		}
		GetEntityNetClass(entity, weapon, sizeof(weapon));
		PrintToChat(client, "***************************************************************");
		PrintToChat(client, "***************************************************************");
		PrintToChat(client, "\x03Debug report begin");
		PrintToChat(client, "\x03Yellow = Game related ||| White = Plugin related");
		PrintToChat(client, "***************************************************************");
		PrintToChat(client, "***************************************************************");
		PrintToChat(client, "Kill Count: %i", killcount[client]);
		PrintToChat(client, "Damage Count: %i", dmgcount[client]);
		PrintToChat(client, "Berserker Running: %i", hasberserker_[client]);
		PrintToChat(client, "Berserker Enabled: %i", enablezerk[client]);
		PrintToChat(client, "\x04Team: %i", team[client]);
		PrintToChat(client, "\x04Client Index: %i", client);
		PrintToChat(client, "\x04Speed: %f", LagMovement);
		PrintToChat(client, "\x04Adrenaline is: Unknown");
		PrintToChat(client, "\x04God Mode: %s", godmode);
		PrintToChat(client, "\x04Weapon : %s", weapon);
		PrintToChat(client, "***************************************************************");
		PrintToChat(client, "***************************************************************");
		PrintToChat(client, "\x03Debug report end");
		PrintToChat(client, "***************************************************************");
		PrintToChat(client, "***************************************************************");
	}
}
public Action:CmdKillCount(client, args)
{
	if(client == 0)
	{
		return;
	}
	if(GetConVarInt(CvarDebug) == 1)
	{
		PrintToChat(client, "Zombies Count: %i", killcount[client]);
		PrintToChat(client, "Damage Count: %i", dmgcount[client]);
		if(GetConVarInt(StrictDebug) == 1)
		{
			decl String:weapon[256]
			new entity = GetEntDataEnt2(client, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
			GetEntityNetClass(entity, weapon, sizeof(weapon));
			PrintToChat(client, "\x03 Weapon : %s", weapon);
		}
	}
}

public Action:CmdBerserker(client, args)
{
	zombieclass[client] = GetEntProp(client, Prop_Send, "m_zombieClass");
	if(GetConVarInt(CvarExTank) == 1 && zombieclass[client] == 8)
	{
		//PrintToChat(client, "Unable to use zerk on tanks");
		return;
		if(GetConVarInt(StrictDebug) == 1)
		{
			PrintToServer("[PLUGIN]%s tried to use berserker, but failed", client);
			PrintToChat(client, "[PLUGIN]You failed to begin berserker. REASON: Tanks disabled");
		}
	}
	if(client == 0)
	{
		return;
	}
	if(hasberserker_[client] == 0 && enablezerk[client] == 1)
	{
		PlayerHasBerserker(client);
		if(GetConVarInt(StrictDebug) == 1)
		{
			PrintToServer("[PLUGIN]%s began berserker mode by command", client);
			PrintToChat(client, "[PLUGIN]You began berserker mode by command");
		}
	}
	else
	{
		PrintToChat(client, "%t", "ZerkCharging", LANG_SERVER);
		return;
		if(GetConVarInt(StrictDebug) == 1)
		{
			PrintToServer("[PLUGIN]%s tried to use berserker, but failed", client);
			PrintToChat(client, "[PLUGIN]You failed to begin berserker. REASON: Goal not reached");
		}
	}
}

//Start Berserk Stats
public RunBerserkCount()
{
	HookEvent("round_end", OnRoundEnd);
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToServer("[PLUGIN] Hooked global events");
	}
	if(GetConVarInt(CvarInfected) == 1)
	{
		HookEvent("jockey_ride", OnJockeyRideStart);
		HookEvent("lunge_pounce", OnHunterPounceStart);
		HookEvent("choke_start", OnSmokerChokeStart);
		HookEvent("jockey_ride_end", OnJockeyRideEnd);
		HookEvent("pounce_stopped", OnHunterPounceEnd);
		HookEvent("choke_start", OnSmokerChokeEnd);
		HookEvent("player_hurt", SurvivorHurt);
		HookEvent("player_shoved", OnShoved);
		if(GetConVarInt(StrictDebug) == 1)
		{
			PrintToServer("[PLUGIN] Hooked Infected events");
		}
	}
	if(GetConVarInt(CvarSurvivor) == 1)
	{
		HookEvent("infected_death", InfectedKilled);
		HookEvent("player_death", OnPlayerDeath);
		HookEvent("player_incapacitated", OnPlayerIncap);
		HookEvent("weapon_reload", OnReload);
		if(GetConVarInt(StrictDebug) == 1)
		{
			PrintToServer("[PLUGIN] Hooked Survivor events");
		}
	}
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	ShovePenalty = FindSendPropInfo("CTerrorPlayer", "m_iShovePenalty");
	TempHealth = FindSendPropInfo("CTerrorPlayer", "m_healthBuffer");
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToServer("[PLUGIN] Got needed offsets and properties");
	}
}

//Infected count based on damage dealt
public Action:SurvivorHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new survivor = GetClientOfUserId(GetEventInt(event, "userid"));
	new damage = GetEventInt(event, "dmg_health");
	if(attacker == 0)
	{
		return;
	}
	team[attacker] = GetClientTeam(attacker);
	team[survivor] = GetClientTeam(survivor);
	if((team[attacker] == 3) && (team[survivor] == 2))
	{
		if((attacker > 0) && (!IsFakeClient(attacker)) && (hasberserker_[attacker] == 0) && (enablezerk[attacker] == 0) && (IsClientInGame(attacker)))
		{
			dmgcount[attacker] += 1;
			if(GetConVarInt(StrictDebug) == 1)
			{
				PrintToChat(attacker, "[PLUGIN] Damage count raised");
			}
			if(GetConVarInt(CvarMode) == 0)
			{
				if(dmgcount[attacker] <= 1)
				{
					CreateTimer(GetConVarFloat(CvarTime), ResetKillCount, attacker);
				}
			}
			
			if(dmgcount[attacker] >= GetConVarInt(CvarInfGoal))
			{
				dmgcount[attacker] = 0;
				enablezerk[attacker] = 1;
				PrintHintText(attacker, "%t", "CenterZerkReady", LANG_SERVER);
				PrintToChat(attacker, "%t", "ZerkReadyChat", LANG_SERVER);
				if(GetConVarInt(CvarDebug) == 1)
				{
					PrintToChat(attacker, "%t", "ZerkReady", LANG_SERVER);
				}
				if(GetConVarInt(StrictDebug) == 1)
				{
					PrintToChat(attacker, "[PLUGIN] Goal reached, enabling berserker");
				}
			}
		}
		if((attacker > 0) && (!IsFakeClient(attacker)) && (hasberserker_[attacker] == 1) && (enablezerk[attacker] == 0) && (IsClientInGame(attacker)))
		{
			new health = GetClientHealth(survivor);
			new Float:dmgbonus = GetConVarFloat(CvarADamage);
			new Float:total = health-(damage*dmgbonus);
			new inttotal = RoundToNearest(total);
			if(GetConVarInt(StrictDebug) == 1)
			{
				PrintToChat(attacker, "[INFECTED] Original target health: %i", health+damage);
				PrintToChat(attacker, "[INFECTED] Original damage dealt: %i", damage);
				PrintToChat(attacker, "[INFECTED] New damage dealt: %i", RoundToNearest(damage+damage*dmgbonus));
				PrintToChat(attacker, "[INFECTED] Final target health: %i", RoundToNearest(total));
			}
			if(GetConVarInt(CvarDDamage) == 1)
			{
				if(inttotal <= 0 && GetEntProp(survivor, Prop_Send, "m_isIncapacitated") == 0)
				{
					SetEntProp(survivor, Prop_Send, "m_isIncapacitated", 1);
					SetEntityHealth(survivor, 300);
					if(GetConVarInt(StrictDebug) == 1)
					{
						PrintToChat(attacker, "[INFECTED] Final health was below 0, incapacitating");
					}
				}
				else if(inttotal <= 0 && GetEntProp(survivor, Prop_Send, "m_isIncapacitated") == 1)
				{
					SetEntityHealth(survivor, 0);
					if(GetConVarInt(StrictDebug) == 1)
					{
						PrintToChat(attacker, "[INFECTED] Final health was below 0 and was already incapacitated, killing");
					}
				}
				else
				{
					SetEntityHealth(survivor, inttotal);
				}
			}
		}
	}
}

/*Special infected abilities during Berserker*/
//Jockey ride start
public Action:OnJockeyRideStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToChatAll("[\x03[Event] Jockey ride started");
	}
	if(GetConVarInt(CvarAtackInmu) == 0)
	{
		return;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client == 0)
	{
		return;
	}
	team[client] = GetClientTeam(client)
	doingride[client] = 1
	if(team[client] == 3 && !IsFakeClient(client) && IsClientInGame(client))
	{
		if(hasberserker_[client] == 1)
		{
			if(!GetEntProp(client, Prop_Data, "m_takedamage") == 0)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				CreateTimer(1.0, CheckInfectedZerk, client, TIMER_REPEAT);
				if(GetConVarInt(CvarDebug) == 1)
				{
					LogAction(0, -1, "%t", "IncapInmuLOG", client, LANG_SERVER);
					PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "IncapInmu", LANG_SERVER);
				}
			}
		}
	}
}

//Pounce Start
public Action:OnHunterPounceStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToChatAll("[\x03[Event] Hunter Pounce started");
	}
	if(GetConVarInt(CvarAtackInmu) == 0)
	{
		return;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client == 0)
	{
		return;
	}
	team[client] = GetClientTeam(client)
	doingpounce[client] = 1
	if(team[client] == 3 && !IsFakeClient(client) && IsClientInGame(client))
	{
		if(hasberserker_[client] == 1)
		{
			if(!GetEntProp(client, Prop_Data, "m_takedamage") == 0)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				CreateTimer(1.0, CheckInfectedZerk, client, TIMER_REPEAT);
				if(GetConVarInt(CvarDebug) == 1)
				{
					LogAction(0, -1, "%t", "IncapInmuLOG", client, LANG_SERVER);
					PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "IncapInmu", LANG_SERVER);
				}
			}
		}
	}
}

//Cancel god mode if players get shoved
public Action:OnShoved(Handle:event, String:event_name[], bool:dontBroadcast)
{
	
	if(GetConVarInt(CvarAtackInmu) == 0)
	{
		return;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client == 0)
	{
		return;
	}
	team[client] = GetClientTeam(client)
	if(team[client] == 3)
	{
		if(GetConVarInt(StrictDebug) == 1)
		{
			PrintToChatAll("[\x03[Event] Infected got shoved");
		}
		doingride[client] = 0
		doingpounce[client] = 0
		doingchoke[client] = 0
	}
}

//Choke Start
public Action:OnSmokerChokeStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToChatAll("[\x03[Event] Smoker choke started");
	}
	if(GetConVarInt(CvarAtackInmu) == 0)
	{
		return;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client == 0)
	{
		return;
	}
	team[client] = GetClientTeam(client)
	doingchoke[client] = 1
	if(team[client] == 3 && !IsFakeClient(client) && IsClientInGame(client))
	{
		if(hasberserker_[client] == 1)
		{
			if(!GetEntProp(client, Prop_Data, "m_takedamage") == 0)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				CreateTimer(1.0, CheckInfectedZerk, client, TIMER_REPEAT);
				if(GetConVarInt(CvarDebug) == 1)
				{
					LogAction(0, -1, "%t", "IncapInmuLOG", client, LANG_SERVER);
					PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "IncapInmu", LANG_SERVER);
				}
			}
		}
	}
}

//Jockey Ride Over
public Action:OnJockeyRideEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToChatAll("[\x03[Event] Jockey ride is now over");
	}
	if(GetConVarInt(CvarAtackInmu) == 0)
	{
		return;
	}
	for(new i=1; i<=MaxClients; i++)
	{
		if(i==0)
		{
			return;
		}
		if(team[i] == 3)
		{
			doingride[i] = 0;
		}
	}
}

//Hunter Pounce Over
public Action:OnHunterPounceEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToChatAll("[\x03[Event] Hunter Pounce is now over");
	}
	if(GetConVarInt(CvarAtackInmu) == 0)
	{
		return;
	}
	for(new i=1; i<=MaxClients; i++)
	{
		if(i==0)
		{
			return;
		}
		if(team[i] == 3)
		{
			doingpounce[i] = 0;
		}
	}
}

//Smoker Choke Over
public Action:OnSmokerChokeEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GetConVarInt(StrictDebug) == 1)
	{
		PrintToChatAll("[\x03[Event] Smoker Choke is now over");
	}
	if(GetConVarInt(CvarAtackInmu) == 0)
	{
		return;
	}
	for(new i=1; i<=MaxClients; i++)
	{
		if(i==0)
		{
			return;
		}
		if(team[i] == 3)
		{
			doingchoke[i] = 0;
		}
	}
}
//God mode during incap
public Action:OnPlayerIncap(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0)
	{
		team[client] = GetClientTeam(client)
	}
	if(team[client] == 2)
	{
		if(hasberserker_[client] == 1 && GetConVarInt(CvarIncapInmu))
		{
			if(!GetEntProp(client, Prop_Data, "m_takedamage") == 0)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				CreateTimer(1.0, CheckZerk, client, TIMER_REPEAT);
				if(GetConVarInt(CvarDebug) == 1)
				{
					LogAction(0, -1, "%t", "IncapInmuLOG", client, LANG_SERVER);
					PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "IncapInmu", LANG_SERVER);
				}
			}
		}
	}
}

//On Weapon Reload
public Action:OnReload(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0)
	{
		team[client] = GetClientTeam(client)
	}
	
	if(GetConVarInt(CvarIFBullet) == 1 && hasberserker_[client] == 1 && client > 0 && !IsFakeClient(client) && !GetEntProp(client, Prop_Send, "m_isIncapacitated") && team[client] == 2 && IsClientInGame(client))
	{
		CheatCommand(client, "upgrade_add", "incendiary_ammo");
	}
}

//On Player death or Special infected killed
public Action:OnPlayerDeath (Handle:event, String:event_name[], bool:dontBroadcast)
{
	//Get Needed Data
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new zombie = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client == 0)
	{
		return;
	}
	team[client] = GetClientTeam(client);
	if(zombie != 0)
	{
		team[zombie] = GetClientTeam(zombie);
	}

	//Give Health On Special Infected Killed
	if(team[client] == 2 && team[zombie] == 3)
	{
		if(GetConVarInt(CvarSpecialH) == 1)
		{
			if(hasberserker_[client] == 1)
			{
				new health = (GetClientHealth(client))
				if( health > 0 && health < 100)
				{
					new total = health + GetConVarInt(CvarAmountSH)
					if(total > 100)
					{
						total = 100
					}
					SetEntityHealth(client, total);
					if(GetConVarInt(CvarDebug) == 1)
					{
						LogAction(0, -1, "%t", "GaveYouHealthLOG", total, client, LANG_SERVER);
						PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "GaveYouHealth", total, LANG_SERVER);
					}
				}
			}
		}
	}
	else
	{
		return;
	}
}

//On common infected killed
public Action:InfectedKilled (Handle:event, String:event_name[], bool:dontBroadcast)
{
	//Filters and information needed to raise kill count
	
	decl String:isworld[256];
	decl String:weapon[256];
	
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new entity = GetEventInt(event, "weapon_id");
	if(!IsValidEntity(entity))
	{
		return;
	}
	GetEntityNetClass(entity, isworld, sizeof(isworld));
	new entity2 = GetEntDataEnt2(client, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
	if(!IsValidEntity(entity2))
	{
		return;
	}
	GetEntityNetClass(entity2, weapon, sizeof(weapon));
	
	if(isincaped_[client] == 1)
	{
		return;
	}
	//Give Health On Berserker
	if(hasberserker_[client] == 1)
	{
		if(GetConVarInt(CvarTakeH) == 1)
		{
			killcount2[client]+= 1;
			if(killcount2[client] >= GetConVarInt(CvarGoalH))
			{
				killcount2[client] = 0
				new health = (GetClientHealth(client))
				if( health > 0 && health < 100)
				{
					new total = health + GetConVarInt(CvarAmountH)
					if(total > 100)
					{
						total = 100
					}
					SetEntityHealth(client, total);
					if(GetConVarInt(CvarDebug) == 1)
					{
						LogAction(0, -1, "%t", "GaveYouHealthLOG", total, client, LANG_SERVER);
						PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "GaveYouHealth", total, LANG_SERVER);
					}
				}
			}
		}
	}
	
	//Kill Count
	if(client != 0)
	{
		team[client] = GetClientTeam(client)
	}
	if((client > 0) && (!IsFakeClient(client)) && (hasberserker_[client] == 0) && (enablezerk[client] == 0) && (!GetEntProp(client, Prop_Send, "m_isIncapacitated")) && team[client] == 2 && IsClientInGame(client))
	{
		//Only melee kills are valid
		if(GetConVarInt(CvarMelee) == 1 && GetConVarInt(CvarBulletOnly) == 0)
		{
			//Was the damage caused by "world" ? (Molotov, pipe bomb)
			if(StrEqual(weapon, "CWorld"))
			{
				//Yes? then do nothing
				return;
			}
			//Is the weapon a valid melee weapon net class?
			if(StrEqual(weapon, "CTerrorMeleeWeapon") || StrEqual(weapon, "CChainsaw"))
			{
				killcount[client] +=1;
			}
			//No? then do nothing
			else
			{
				return;
			}
		}
		
		//Only bullet based kills are valid(Rifles, pistols, snipers, shotguns, etc)
		if(GetConVarInt(CvarMelee) == 0 && GetConVarInt(CvarBulletOnly) == 1)
		{
			//Was the damage caused by "world" ? (Molotov, pipe bomb)
			if(StrEqual(weapon, "CWorld"))
			{
				//Yes? then do nothing
				return;
			}
			
			//Is the weapon a valid melee weapon net class?
			if(IsValidBulletBased(weapon))
			{
				killcount[client] +=1;
			}
			//No? then do nothing
			else
			{
				return;
			}
		}
		//Everything excepting world damage is valid
		if(GetConVarInt(CvarMelee) == 1 && GetConVarInt(CvarBulletOnly) == 1)
		{
			//Was the damage caused by "world" ? (Molotov, pipe bomb)
			if(StrEqual(weapon, "CWorld"))
			{
				//Yes? then do nothing
				return;
			}
			//No? Continue
			killcount[client] +=1;
		}
		
		//Anything is valid
		if(GetConVarInt(CvarMelee) == 0 && GetConVarInt(CvarBulletOnly) == 0)
		{
			killcount[client] +=1;
		}
		if(GetConVarInt(CvarMode) == 0)
		{
			if(killcount[client] <= 1)
			{
				CreateTimer(GetConVarFloat(CvarTime), ResetKillCount, client);
			}
		}
		if(killcount[client] >= GetConVarInt(CvarGoal))
		{
			if(GetConVarInt(CvarAutomatic) == 1)
			{
				killcount[client] = 0;
				enablezerk[client] = 1;
				PlayerHasBerserker(client);
			}
			
			if(GetConVarInt(CvarAutomatic) == 0)
			{
				killcount[client] = 0;
				enablezerk[client] = 1;
				if(GetConVarInt(CvarDebug) == 1)
				{
					PrintToChat(client, "%t", "ZerkReady", LANG_SERVER);
				}
				PrintHintText(client, "%t", "CenterZerkReady", LANG_SERVER);
				PrintToChat(client, "%t", "ZerkReadyChat", LANG_SERVER);
				new Handle:pack = CreateDataPack();
				
				WritePackCell(pack, client);
				WritePackString(pack, "Berserker is ready!");
				WritePackString(pack, "sm_berserker");
				CreateTimer(0.1, DisplayHint, pack);
			}
		}
	}
}

//Toggle Berserker
public Action:PlayerHasBerserker(client)
{
	//Survivors
	team[client] = GetClientTeam(client)
	if((team[client] == 2) && (IsClientInGame(client)) && (!GetEntProp(client, Prop_Send, "m_isIncapacitated")) && (IsPlayerAlive(client)))
	{
		PrintToChat(client, "%t", "ZerkOn", LANG_SERVER);
		hasberserker_[client] = 1
		enablezerk[client] = 0
		new Float:vec[3];
		if(GetConVarInt(CvarGiveShot) == 1)
		{
			CheatCommand(client, "give", "adrenaline");
			if(GetConVarInt(CvarDebug) == 1)
			{
				LogAction(0, -1, "%t", "GiveAdrenalineLOG", client, LANG_SERVER);
				PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "GiveAdrenaline", LANG_SERVER);
			}
			if(GetConVarInt(CvarGiveShot) == 2)
			{
				new health = GetClientHealth(client);
				new total = health+25
				if(total >= 100)
				{
					SetEntityHealth(client, 100);
				}
				if(total < 100)
				{
					SetEntityHealth(client, total);
				}
			}
		}
		if((GetConVarInt(CvarAnimation) == 2 || GetConVarInt(CvarAnimation) == 3))
		{
			SetEntProp(client, Prop_Send, "m_bAdrenalineActive", 1);
			CreateTimer(2.0, AdrenTimer, client, TIMER_REPEAT);
		}
		if(GetConVarInt(CvarGiveBullet) == 1)
		{
			CheatCommand(client, "give",  "ammo");
			if(GetConVarInt(CvarDebug) == 1)
			{
				LogAction(0, -1, "%t", "RefillWeaponLOG", client, LANG_SERVER);
				PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "RefillWeapon", LANG_SERVER);
			}		
		}
		if(GetConVarInt(CvarGiveFBullet) == 1)
		{
			CheatCommand(client, "upgrade_add", "incendiary_ammo");
			if(GetConVarInt(CvarDebug) == 1)
			{
				LogAction(0, -1, "%t", "IncendiaryAmmoLOG", client, LANG_SERVER);
				PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "IncendiaryAmmo", LANG_SERVER);
			}
		}
		EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_GUNFIRE);
		
		if(GetConVarInt(CvarCColor) == 1)
		{
			if(GetConVarInt(CvarColor) == 1) //RED
			{
				SetEntityRenderColor(client, 189, 9, 13, 235);
			}
			if(GetConVarInt(CvarColor) == 2) //BLUE
			{
				SetEntityRenderColor(client, 34, 22, 173, 235);
			}
			if(GetConVarInt(CvarColor) == 3) //GREEN
			{
				SetEntityRenderColor(client, 34, 120, 24, 235);
			}
			if(GetConVarInt(CvarColor) == 4) //BLACK
			{
				SetEntityRenderColor(client, 0, 0, 0, 235);
			}
			if(GetConVarInt(CvarColor) == 5) //INVISIBLE
			{
				SetEntityRenderColor(client, 255, 255, 255, 0);
			}
		}
		
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "SetColorLOG", client, LANG_SERVER);
			PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "SetColor", LANG_SERVER);
		}
		
		ClientCommand(client, "play %s", SOUND1);
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "FirstSoundPlayedLOG", client, LANG_SERVER);
			PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "FirstSoundPlayed", LANG_SERVER);
		}
		
		if(GetConVarInt(CvarMusic) == 1)
		{
			CreateTimer(1.2, SoundTimer, client);
		}
		//God Mode for 3.0 seconds
		if(!GetEntProp(client, Prop_Data, "m_takedamage") == 0)
		{
			if(GetConVarInt(CvarGodEnable) == 1)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				CreateTimer(GetConVarFloat(CvarGodTime), NoDamageTimer, client);
			}
		}
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "InmunityFirstStartLOG", client, LANG_SERVER);
			PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "InmunityFirstStart", LANG_SERVER);
		}
		
		//Increased Speed
		SetEntDataFloat(client, LagMovement, 1.2, true);
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "ChangedSpeedLOG", client, LANG_SERVER);
			PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "ChangedSpeed", LANG_SERVER);
		}
		if(GetConVarInt(CvarAnimation) == 1 || GetConVarInt(CvarAnimation) == 3)
		{
			IgniteEntity(client, GetConVarFloat(CvarDuration));
		}
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "FireEffectLOG", client, LANG_SERVER);
			PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "FireEffect", LANG_SERVER);
		}
		if(GetConVarInt(CvarLaser) == 1)
		{
			CheatCommand(client, "upgrade_add", "laser_sight");
			CreateTimer(GetConVarFloat(CvarDuration), LaserOff, client);
		}
		CreateTimer(GetConVarFloat(CvarDuration), BerserkEnd, client);
	}
	
	//Infected
	else if((team[client] == 3) && (IsClientInGame(client)) && (!GetEntProp(client, Prop_Send, "m_isIncapacitated")) && (IsPlayerAlive(client)))
	{
		//Announces that berserker is ON
		PrintToChat(client, "%t", "ZerkOn", LANG_SERVER);
		
		//Controls, declarations, variables, etc
		hasberserker_[client] = 1
		enablezerk[client] = 0
		new Float:vec[3];
		
		//Sound that will be heard by everyone, from the player casting berserker
		EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_GUNFIRE);
		
		//Sets red color for the player
		SetEntityRenderColor(client, 189, 9, 13, 235);
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "SetColorLOG", client, LANG_SERVER);
			PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "SetColor", LANG_SERVER);
		}
		
		//Starts berserker music, if enabled on the config file
		ClientCommand(client, "play %s", SOUND1);
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "FirstSoundPlayedLOG", client, LANG_SERVER);
			PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "FirstSoundPlayed", LANG_SERVER);
		}
		
		if(GetConVarInt(CvarMusic) == 1)
		{
			CreateTimer(1.2, SoundTimer, client);
		}
		
		//[DISABLED] Attempt to give temporal health, which failed. This function is useless, but wasn't deleted for other reasons
		//Extra infected health
		if(GetConVarInt(CvarDHealth) == 1)
		{
			new health = GetClientHealth(client);
			new Float:dmgbonus = GetConVarFloat(CvarAHealth);
			new total = health*dmgbonus;
			new inttotal = RoundToNearest(total);
			SetEntityHealth(client, inttotal);
		}
		
		//Increases Speed
		SetEntDataFloat(client, LagMovement, 1.2, true);
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "ChangedSpeedLOG", client, LANG_SERVER);
			PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "ChangedSpeed", LANG_SERVER);
		}
		
		//Create timer to disable berserker later
		CreateTimer(GetConVarFloat(CvarDuration), BerserkEnd, client);
	}
}

//Play Music On Berserker
public Action:SoundTimer(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsValidEntity(client)) return;
	
	//Starts music
	ClientCommand(client, "play %s", BERSERKSOUND);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "MusicStartLOG", client, LANG_SERVER);
		PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "MusicStart", LANG_SERVER);
	}
	
	//Creates timer to disable the music later
	CreateTimer(GetConVarFloat(CvarDuration), STOPSOUND, client);
}

//Stops Music
public Action:STOPSOUND(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsValidEntity(client)) return;
	
	//To avoid disable errors on music, apply the command multiple times
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", ENDSOUND);
	
	//Set default color
	SetEntityRenderColor(client, 255, 255, 255, 255);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "StopMusicLOG", client, LANG_SERVER);
		PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "StopMusic", LANG_SERVER);
	}
	ClientCommand(client, "play %s", ENDSOUND);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "DefaultColorLOG", client, LANG_SERVER);
		PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "DefaultColor", LANG_SERVER);
	}
}

//Remove God Mode
public Action:NoDamageTimer(Handle:timer, any:client)
{
	//Retrieves temporal god mode
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
}

//Remove laser
public Action:LaserOff(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsValidEntity(client)) return;
	
	//Retrieves the laser
	CheatCommand(client, "upgrade_remove", "laser_sight");
}

//Ends Berserker
public Action:BerserkEnd(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsValidEntity(client)) return;
	//Sets speed to default (Normal)
	SetEntDataFloat(client, LagMovement, 1.0, true);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "NormalSpeedLOG", client, LANG_SERVER);
		PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "NormalSpeed", LANG_SERVER);
	}
	
	//Stop music and announce that the berserker is over
	PrintToChat(client, "%t", "ZerkOff", LANG_SERVER);
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", SOUND2);
	
	//Set berserker control to 0 (OFF)
	hasberserker_[client] = 0;
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "DebugZerkOffLOG", client, LANG_SERVER);
		PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "DebugZerkOff", LANG_SERVER);
	}
	
}

//Timers and checkers for god mode and other functions

//Timer - Survivor Incapacitation god mode checker
public Action:CheckZerk(Handle:timer, any:client)
{
	//Is the player under berserker mode? If no, retrieve god mode
	if(hasberserker_[client] == 0)
	{		
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "IncapInmuStopLOG", client, LANG_SERVER);
			PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "IncapInmuStop", LANG_SERVER);
		}
		return Plugin_Stop
	}
	
	//If yes, continue checking
	return Plugin_Continue
}

//Timer - Infected god mode checker (Will check if the berserker is disabled to remove godmode
public Action:CheckInfectedZerk(Handle:timer, any:client)
{
	//Is the player under berserker mode AND is using his special ability? If No, remove god mode
	if((hasberserker_[client] == 0) || ((doingride[client] == 0) && (doingpounce[client] == 0) && (doingchoke[client] == 0)))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "IncapInmuStopLOG", client, LANG_SERVER);
			PrintToChat(client, "\x04[ZERK DEBUG] \x01 %t", "IncapInmuStop", LANG_SERVER);
		}
		return Plugin_Stop
	}
	
	//If yes, continue checking
	return Plugin_Continue
}

//Timer - Adrenaline effect
public Action:AdrenTimer(Handle:timer, any:client)
{
	//Is the player the console? If yes, do nothing
	if(client == 0)
	{
		return Plugin_Handled;
	}
	
	//Is the player a valid entity? If no, do nothing
	if(!IsValidEntity(client))
	{
		return Plugin_Handled;
	}
	
	//Is the player under berserker mode? If not, stop adrenaline effect
	if(hasberserker_[client] == 0)
	{
		SetEntProp(client, Prop_Send, "m_bAdrenalineActive", 0);
		return Plugin_Handled;
	}
	
	//If yes, continue displaying the effect
	if(team[client] == 2 && IsPlayerAlive(client) && IsClientInGame(client) && hasberserker_[client] == 1 && (GetConVarInt(CvarAnimation) == 2 || GetConVarInt(CvarAnimation) == 3))
	{
		SetEntProp(client, Prop_Send, "m_bAdrenalineActive", 1);
	}
	return Plugin_Continue
}

//Timer - Will reset the kill count in case the goal isnt reached in time
public Action:ResetKillCount(Handle:timer, any:client)
{
	killcount[client] = 0;
}

//Timer - Will reset the damage count in case the goal isnt reached in time
public Action:ResetDamageCount(Handle:timer, any:attacker)
{
	dmgcount[attacker] = 0;
}

//Zoom button used (Default)
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((buttons & IN_ZOOM) && enablezerk[client] == 1 && (!GetEntProp(client, Prop_Send, "m_isIncapacitated")))
	{
		zombieclass[client] = GetEntProp(client, Prop_Send, "m_zombieClass");
		if(GetConVarInt(CvarExTank) == 1 && zombieclass[client] == 8)
		{
			//PrintToChat(client, "Unable to use zerk on tanks");
			return;
		}
		PlayerHasBerserker(client)
	}
}

//Toggle Anti-Berserker
public Action:PlayerIsDumb(client)
{	
	//Is the player a survivor? If yes, continue...
	team[client] = GetClientTeam(client)
	if((team[client] == 2) && (IsClientInGame(client)) && (!GetEntProp(client, Prop_Send, "m_isIncapacitated")) && (IsPlayerAlive(client)))
	{
		//Blinds player
		PerformFade(client, 30, {0, 0, 0, 190});
		
		//Removes laser sight upgrade		
		CheatCommand(client, "upgrade_remove", "laser_sight");
		
		//Reset berserker counts
		killcount[client] = 0;
		dmgcount[client] = 0;
		killcount2[client] = 0;
		
		//Reduces Speed
		SetEntDataFloat(client, LagMovement, 0.6, true);
		
		//Play anti-berserker music
		ClientCommand(client, "play %s", SOUND_DUMB);
		
		//Default timers
		CreateTimer(30.0, STOPSOUND, client);
		CreateTimer(30.0, NORMALSPEED, client);
	}
}

public Action:NORMALSPEED(Handle:timer, any:client)
{
	//Speed gets back to normal
	SetEntDataFloat(client, LagMovement, 1.0, true);
	
	//Blindness is over
	PerformFade(client, 30, {0, 0, 0, 0})
}
		
//Displaying the instructor Hint
public Action:DisplayHint(Handle:timer, Handle:pack)
{
	decl String: msg[256], String: bind[16], String: msgphrase[256];
	ResetPack(pack);
	new client = GetClientOfUserId(ReadPackCell(pack));
	ReadPackString(pack, msg, sizeof(msg));
	ReadPackString(pack, bind, sizeof(bind));
	CloseHandle(pack);
	
	decl HintEntity, String:name[32];
	HintEntity = CreateEntityByName("env_instructor_hint");
	FormatEx(name, sizeof(name), "TRIH%d", client);
	DispatchKeyValue(client, "targetname", name);
	DispatchKeyValue(HintEntity, "hint_target", name);
	
	DispatchKeyValue(HintEntity, "hint_range", "0.01");
	DispatchKeyValue(HintEntity, "hint_color", "255 255 255");
	DispatchKeyValue(HintEntity, "hint_caption", msgphrase);
	DispatchKeyValue(HintEntity, "hint_icon_onscreen", "use_binding");
	DispatchKeyValue(HintEntity, "hint_binding", bind);
	DispatchKeyValue(HintEntity, "hint_timeout", "6.0");
	if(client == 0)
	{
		return;
	}
	ClientCommand(client, "gameinstructor_enable 1");
	DispatchSpawn(HintEntity);
	AcceptEntityInput(HintEntity, "ShowHint");
	CreateTimer(6.0, DisableInstructor, client);
}

//Disable instructor
public Action:DisableInstructor(Handle:timer, any:client)
{
	ClientCommand(client, "gameinstructor_enable 0");
}

//Using commands that need sv_cheats 1 on them.
CheatCommand(client, const String:command [], const String:arguments [])
{
	if (!client) return;
	if (!IsClientInGame(client)) return;
	if (!IsValidEntity(client)) return;
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags (command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata)
}

//Is valid bullet based?
stock bool:IsValidBulletBased(String:weapon[])
{
	if(StrEqual(weapon, "CAutoShotgun") || StrEqual(weapon, "CSniperRifle") || StrEqual(weapon, "CPistol") || StrEqual(weapon, "CMagnumPistol") || StrEqual(weapon, "CAssaultRifle") || StrEqual(weapon, "CRifle_Desert") || StrEqual(weapon, "CSubMachinegun") || StrEqual(weapon, "CSNG_Silenced") || StrEqual(weapon, "CSniper_Military") || StrEqual(weapon, "CRifle_AK47") || StrEqual(weapon, "CRifle_SG552") || StrEqual(weapon, "CShotgun_Chrome") || StrEqual(weapon, "CShotgun_SPAS") || StrEqual(weapon, "CPumpShotgun") || StrEqual(weapon, "CSMG_MP5") || StrEqual(weapon, "CSniper_AWP") || StrEqual(weapon, "CSniper_Scout"))
	{
		return true;
	}
	else
	{
		return false;
	}
}

//Perform blindness
PerformFade(client, duration, const color[4]) 
{
	new Handle:hFadeClient=StartMessageOne("Fade",client)
	BfWriteShort(hFadeClient,duration)	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration
	BfWriteShort(hFadeClient,0)		// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration until reset (fade & hold)
	BfWriteShort(hFadeClient,FFADE_STAYOUT|FFADE_PURGE) // fade type (in / out)
	BfWriteByte(hFadeClient,color[0])	// fade red
	BfWriteByte(hFadeClient,color[1])	// fade green
	BfWriteByte(hFadeClient,color[2])	// fade blue
	BfWriteByte(hFadeClient,color[3])	// fade alpha
	EndMessage()
}