//Includes
#include <sourcemod>
#include <sdktools>

//Definitions
#define SOUND1 "ui/pickup_secret01.wav"
#define SOUND2 "ui/pickup_misc42.wav"
#define BERSERKSOUND "music/tank/onebadtank"
#define ENDSOUND "music/the_end/kalin"
#define SOUND_FREEZE "ui/pickup_guitarriff10.wav"

//Strings and Cvars
new killcount[MAXPLAYERS+1];
new killcount2[MAXPLAYERS+1];
new hasberserker_[MAXPLAYERS+1] = 0;
new enablezerk[MAXPLAYERS+1] = 0;
new team[MAXPLAYERS+1]
new isincaped_[MAXPLAYERS+1] = 0;

new Handle:CvarGoal = INVALID_HANDLE;
new Handle:CvarDuration = INVALID_HANDLE;
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

static LagMovement = 0;

//Plugin Info
public Plugin:myinfo = 
{
	name = "Berserker Mode",
	author = "honorcode23",
	description = "Enters on Berserker Mode after x amount of killed infected",
	version = "1.0",
	url = "none"
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
	
	//Cvars
	CvarGoal = CreateConVar("l4d2_berserk_mode_goal", "100", "Amount of killed infected to berserk", FCVAR_PLUGIN);
	CvarDuration = CreateConVar("l4d2_berserk_mode_duration", "30.0", "Amount of time to berserk. 0 = Disabled", FCVAR_PLUGIN);
	CvarMusic = CreateConVar("l4d2_berserk_mode_play_music", "1", "Should the plugin play music when the players are under Berserker Mode?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarTakeH = CreateConVar("l4d2_berserk_mode_health", "1", "While in berserker mode, should the player get health after X amount of infected killed?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarGoalH = CreateConVar("l4d2_berserk_mode_health_goal", "20", "Amount of infected killed on berserker to get health", FCVAR_PLUGIN);
	CvarAmountH = CreateConVar("l4d2_berserk_mode_health_amount", "3", "Amount of health given when a certain ammount of infected is killed on berserker", FCVAR_PLUGIN);
	CvarSpecialH = CreateConVar("l4d2_berserk_mode_health_special", "1", "Instant health On Special Infected Kill under Berserker Mode?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarAmountSH = CreateConVar("l4d2_berserk_mode_health_amount_special", "2", "Amount of health given when an special infected is killed on berserker mode", FCVAR_PLUGIN);
	CvarGiveShot = CreateConVar("l4d2_berserk_mode_play_music", "1", "Should the plugin play music when the players are under Berserker Mode?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarGiveBullet = CreateConVar("l4d2_berserk_mode_refill_weapon", "1", "Should the plugin refills player weapon on berserker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarGiveFBullet = CreateConVar("l4d2_berserk_mode_give_fire_bullets", "1", "Should the plugin give fire bullets to the player on berserker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarBindKey = CreateConVar("l4d2_berserk_mode_bind_key", "1", "Should the plugin Bind the B key for berserker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CvarDebug = CreateConVar("l4d2_berserk_mode_debug", "0", "Debug information", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	//Commands
	RegConsoleCmd("sm_berserker", CmdBerserker, "Toggle Berserker if it is enabled");
	RegConsoleCmd("sm_killcount", CmdKillCount, "Get Debug Zombie Count");
	
	//Create Config File
	AutoExecConfig(true, "l4d2_berserk_mode");
	
	//Translations
	LoadTranslations("common.phrases");
	LoadTranslations("l4d2_berserk_mode.phrases");
}

public OnMapStart()
{
	//Get Game mode (Plugin will work on coop, realism or last gnome on earth only)
	decl String:gamemode[50]
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if(StrEqual(gamemode, "coop") || StrEqual(gamemode, "realism") || StrEqual(gamemode, "mutation9"))
	{
		RunBerserkCount()
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "GameMode", LANG_SERVER);
		}
	}
	else
	{
		return Plugin_Handled;
	}
/*  Precache Sounds  */
	PrecacheSound(SOUND1);
	PrecacheSound(SOUND2);
	PrecacheSound(BERSERKSOUND);
	PrecacheSound("player/survivor/voice/mechanic/battlecry01.wav");
	PrecacheSound("player/survivor/voice/producer/battlecry02.wav");
	PrecacheSound("player/survivor/voice/coach/battlecry09.wav");
	PrecacheSound("player/survivor/voice/gambler/battlecry04.wav");
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	if(GetConVarInt(CvarBindKey) == 1)
	{
		ClientCommand(client, "bind b sm_berserker");
	}
}

public OnMapEnd()
{
	UnhookEvent("infected_death", InfectedKilled);
	UnhookEvent("player_death", OnPlayerDeath);
}

public Action:CmdKillCount(client, args)
{
	if(GetConVarInt(CvarDebug) == 1)
	{
		PrintToChat(client, "Zombies Count: %i", killcount[client]);
	}
}

public Action:CmdBerserker(client, args)
{
	if(hasberserker_[client] == 0 && enablezerk[client] == 1)
	{
		PlayerHasBerserker(client);
	}
	else
	{
		return;
	}
}

//Start Berserk Stats
public RunBerserkCount()
{
	HookEvent("infected_death", InfectedKilled);
	HookEvent("player_death", OnPlayerDeath);
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
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
						LogAction(0, -1, "%t", total, client, LANG_SERVER);
						PrintToChat(client, "[DEBUG] %t", total, LANG_SERVER);
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
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
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
						LogAction(0, -1, "%t", total, client, LANG_SERVER);
						PrintToChat(client, "[DEBUG] %t", total, LANG_SERVER);
					}
				}
			}
		}
	}
	
	//Kill Count
	if((client > 0) && (!IsFakeClient(client)) && (hasberserker_[client] == 0) && (enablezerk[client] == 0) && (!GetEntProp(client, Prop_Send, "m_isIncapacitated")))
	{
		killcount[client]+= 1;
		if(killcount[client] >= GetConVarInt(CvarGoal))
		{
			killcount[client] = 0;
			enablezerk[client] = 1;
			if(GetConVarInt(CvarDebug) == 1)
			{
				PrintToChat(client, "%T", "ZerkReady", LANG_SERVER);
			}
			PrintHintText(client, "%t", "CenterZerkReady", LANG_SERVER);
		}
	}
}

//Toggle Berserker
public Action:PlayerHasBerserker(client)
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
			PrintToChat(client, "[DEBUG] %t", "GiveAdrenaline", LANG_SERVER);
		}
	}
	if(GetConVarInt(CvarGiveBullet) == 1)
	{
		CheatCommand(client, "give",  "ammo");
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "RefillWeaponLOG", client, LANG_SERVER);
			PrintToChat(client, "[DEBUG] %t", "RefillWeapon", LANG_SERVER);
		}		
	}
	if(GetConVarInt(CvarGiveFBullet) == 1)
	{
		CheatCommand(client, "upgrade_add", "incendiary_ammo");
		if(GetConVarInt(CvarDebug) == 1)
		{
			LogAction(0, -1, "%t", "IncendiaryAmmoLOG", client, LANG_SERVER);
			PrintToChat(client, "[DEBUG] %t", "IncendiaryAmmo", LANG_SERVER);
		}
	}
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
	
	SetEntityRenderColor(client, 189, 9, 13, 235);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "SetColorLOG", client, LANG_SERVER);
		PrintToChat(client, "[DEBUG] %t", "SetColor", LANG_SERVER);
	}
	
	ClientCommand(client, "play %s", SOUND1);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "FirstSoundPlayedLOG", client, LANG_SERVER);
		PrintToChat(client, "[DEBUG] %t", "FirstSoundPlayed", LANG_SERVER);
	}
	
	if(GetConVarInt(CvarMusic) == 1)
	{
		CreateTimer(1.2, SoundTimer, client);
	}
	//God Mode for 3.0 seconds
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "InmunityFirstStartLOG", client, LANG_SERVER);
		PrintToChat(client, "[DEBUG] %t", "InmunityFirstStart", LANG_SERVER);
	}
	
	//Increased Speed
	SetEntDataFloat(client, LagMovement, 1.2, true);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "ChangedSpeedLOG", client, LANG_SERVER);
		PrintToChat(client, "[DEBUG] %t", "ChangedSpeed", LANG_SERVER);
	}
	
	//DoubleHealth
	IgniteEntity(client, 2.0);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "FireEffectLOG", client, LANG_SERVER);
		PrintToChat(client, "[DEBUG] %t", "FireEffect", LANG_SERVER);
	}
	CreateTimer(3.0, NoDamageTimer, client);
	CreateTimer(GetConVarFloat(CvarDuration), BerserkEnd, client);
	
	
}

//Play Music On Berserker
public Action:SoundTimer(Handle:timer, any:client)
{
	ClientCommand(client, "play %s", BERSERKSOUND);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "MusicStartLOG", client, LANG_SERVER);
		PrintToChat(client, "[DEBUG] %t", "MusicStart", LANG_SERVER);
	}
	CreateTimer(GetConVarFloat(CvarDuration), STOPSOUND, client);
}

//Stops Music
public Action:STOPSOUND(Handle:timer, any:client)
{
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", ENDSOUND);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "StopMusicLOG", client, LANG_SERVER);
		PrintToChat(client, "[DEBUG] %t", "StopMusic", LANG_SERVER);
	}
	ClientCommand(client, "play %s", ENDSOUND);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "DefaultColorLOG", client, LANG_SERVER);
		PrintToChat(client, "[DEBUG] %t", "DefaultColor", LANG_SERVER);
	}
}
public Action:NoDamageTimer(Handle:timer, any:client)
{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
}

//End Berserker
public Action:BerserkEnd(Handle:timer, any:client)
{
	SetEntDataFloat(client, LagMovement, 1.0, true);
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "NormalSpeedLOG", client, LANG_SERVER);
		PrintToChat(client, "[DEBUG] %t", "NormalSpeed", LANG_SERVER);
	}
	PrintToChat(client, "%t", "ZerkOff", LANG_SERVER);
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", ENDSOUND);
	ClientCommand(client, "play %s", SOUND2);
	hasberserker_[client] = 0
	if(GetConVarInt(CvarDebug) == 1)
	{
		LogAction(0, -1, "%t", "DebugZerkOffLOG", client, LANG_SERVER);
		PrintToChat(client, "[DEBUG] %t", "DebugZerkOff", LANG_SERVER);
	}
	
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((buttons & IN_ZOOM) && enablezerk[client] == 1)
	{
		PlayerHasBerserker(client)
	}
}

CheatCommand(client, const String:command [], const String:arguments [])
{
	if (!client) return;
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags (command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata)
}