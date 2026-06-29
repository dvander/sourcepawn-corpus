#define PLUGIN_VERSION "1.5"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <colors>

/*////////////////////////
	= Chat debug, Tag =
*////////////////////////
#define debug 0
#if debug
int CurrentTankHP;
#endif
#define TAG  	  "[debug]"
#define FC  	  "{green}[{blue}TankFightClub{green}]{default}"
#define CVAR_FLAGS FCVAR_NOTIFY
/*////////////////////////
		= ConVar =
*////////////////////////
static ConVar g_enable, g_info, g_zombie, g_extra, g_timer, g_support, g_ko, g_bs, g_health;
static ConVar g_health1, g_health2, g_health3, g_health4, g_health5, g_health6, g_health7;
static ConVar g_round1, g_round2, g_round3, g_round4, g_round5, g_round6, g_round7;
static ConVar zombie, bosses, specials, mobs, ST,STF, STI, ST1, ST2, ST3, g_heal;
static ConVar tank_burn_duration, tank_burn_duration_hard, tank_burn_duration_expert, z_difficulty;
bool g_bCvarEnable, g_bCvarExtra, g_bCvarZombie, g_bCvarSupport, g_bCvarHeal, g_bCvarKo;
int g_CvarInfo, g_CvarTimer, g_CvarBS, g_CvarHealth;
int g_CvarHealth1, g_CvarHealth2, g_CvarHealth3, g_CvarHealth4, g_CvarHealth5, g_CvarHealth6, g_CvarHealth7;
int g_CvarRound1, g_CvarRound2, g_CvarRound3, g_CvarRound4, g_CvarRound5, g_CvarRound6, g_CvarRound7;
int n, m, TankALL, TankLive, TankCount, TankRound;
static float TankBurnIndex;
Handle MsgTimer = null, TankFightClubTimer = null;

bool club = false, //access to TankFightClub.
     block = false,	//blocks PanicEvent if already been started
     block2 = false, //blocks OnClientPost.. if already been started.
     block3 = false, //blocks OnClientPost.. and PanicEvent if game is started.
     block4 = false, //blocks OnClientPost.. when UnhookEvent.
     block5 = false, //blocks re-HookEvent, re-UnhookEvent.
     KOblock = false, //block counter
     KOblock2 = false,
     L4D2 = true;
/*////////////////////////
		= Sound =
*////////////////////////
#define SOUND_CLOCK "level/countdown.wav"
#define SOUND_FIGHT "level/scoreregular.wav"
#define SOUND_TANK "ui/littlereward.wav"

public Plugin myinfo =
{
	name = "[L4D & L4D2] Tank Fight Club: Expanded Edition",
	author = "raziEiL [disawar1]",
	description = "Welcome to the Tank Fight Club. Kill Them All!",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
    EngineVersion test = GetEngineVersion();
    if( test == Engine_Left4Dead )
    {
    	L4D2 = false;
    }
    else if( test == Engine_Left4Dead2 )
    {
    	L4D2 = true;
    }
    else
    {
    	strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
    	return APLRes_SilentFailure;
    }
    
    return APLRes_Success; 
}

/*////////////////////////
	= PLUGIN START! =
*////////////////////////
public void OnPluginStart()
{
	CreateConVar("tank_fight_club_version", PLUGIN_VERSION, "Tank Fight Club: Expanded Edition plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);

	g_enable = CreateConVar("tank_club_enable", "1", "Plugin: 0 - Disable, 1 - Enable", CVAR_FLAGS);
	g_info = CreateConVar("tank_club_info", "1", "Show info message: 0 - Disable, 1 - Type I, 2 - Type II, 3 - Type III", CVAR_FLAGS);
	g_zombie = CreateConVar("tank_club_zombie", "1", "Blocks Boss and zombie spawns: 0 - Disable, 1 - Enable", CVAR_FLAGS);
	g_extra = CreateConVar("tank_club_extra", "1", "Extra 5, 6, 7 rounds: 0 - Disable, 1 - Enable", CVAR_FLAGS);
	g_timer = CreateConVar("tank_club_timer", "60", "Delay before game starts in sec", CVAR_FLAGS);
	g_support = CreateConVar("tank_club_st", "0", "Supports SuperTanks plugin.  Tanks will be spawned at 3 and 6 rounds: 0 - Disable, 1 - Enable", CVAR_FLAGS);
	g_ko = CreateConVar("tank_club_ko", "1", "Forced to slay all the tanks when the next round begins: 0 - Disable, 1 - Enable", CVAR_FLAGS);
	g_bs = CreateConVar("tank_club_bs", "2", "Auto-balance feature. Tanks count will depend on player number and this convar. [Max Tanks = Player numbers - Convar Value]", CVAR_FLAGS);
	g_health = CreateConVar("tank_club_hp_zero", "2000", "Default Tank health.", CVAR_FLAGS);
	g_health1 = CreateConVar("tank_club_hp_one", "4000", "Tank health in 1st round.", CVAR_FLAGS);
	g_health2 = CreateConVar("tank_club_hp_two", "6000", "Tank health in 2 round.", CVAR_FLAGS);
	g_health3 = CreateConVar("tank_club_hp_three", "8000", "Tank health in 3 round.", CVAR_FLAGS);
	g_health4 = CreateConVar("tank_club_hp_four", "10000", "Tank health in 4 round.", CVAR_FLAGS);
	g_health5 = CreateConVar("tank_club_hp_five", "15000", "Tank health in 5 round.", CVAR_FLAGS);
	g_health6 = CreateConVar("tank_club_hp_six", "22000", "Tank health in 6 round.", CVAR_FLAGS);
	g_health7 = CreateConVar("tank_club_hp_seven", "30000", "Tank health in 7 round.", CVAR_FLAGS);
	g_round1 = CreateConVar("tank_club_count_zero", "1", "Tanks in the zero round.", CVAR_FLAGS);
	g_round2 = CreateConVar("tank_club_count_one", "2", "Tanks in the 1st round.", CVAR_FLAGS);
	g_round3 = CreateConVar("tank_club_count_two", "3", "Tanks in the 2 round.", CVAR_FLAGS);
	g_round4 = CreateConVar("tank_club_count_three", "4", "Tanks in the 3 round.", CVAR_FLAGS);
	g_round5 = CreateConVar("tank_club_count_four", "5", "Tanks in the 4 round.", CVAR_FLAGS);
	g_round6 = CreateConVar("tank_club_count_five", "6", "Tanks in the 5 round.", CVAR_FLAGS);
	g_round7 = CreateConVar("tank_club_count_six", "7", "Tanks in the 6 round.", CVAR_FLAGS);
	g_heal = CreateConVar("tank_club_heal", "0", "Heal Survivors each round: 0 - Disable, 1 - Enable", CVAR_FLAGS);

	g_enable.AddChangeHook(OnPluginEnable);
	g_info.AddChangeHook(OnCVarChange);
	g_zombie.AddChangeHook(OnDirectorEnable);
	g_extra.AddChangeHook(OnCVarChange);
	g_timer.AddChangeHook(OnCVarChange);
	g_support.AddChangeHook(OnExpandedEditionEnable);
	g_ko.AddChangeHook(OnCVarChange);
	g_bs.AddChangeHook(OnCVarChange);
	g_health.AddChangeHook(OnCVarChange);
	g_health1.AddChangeHook(OnCVarChange);
	g_health2.AddChangeHook(OnCVarChange);
	g_health3.AddChangeHook(OnCVarChange);
	g_health4.AddChangeHook(OnCVarChange);
	g_health5.AddChangeHook(OnCVarChange);
	g_health6.AddChangeHook(OnCVarChange);
	g_health7.AddChangeHook(OnCVarChange);
	g_round1.AddChangeHook(OnCVarChange);
	g_round2.AddChangeHook(OnCVarChange);
	g_round3.AddChangeHook(OnCVarChange);
	g_round4.AddChangeHook(OnCVarChange);
	g_round5.AddChangeHook(OnCVarChange);
	g_round6.AddChangeHook(OnCVarChange);
	g_round7.AddChangeHook(OnCVarChange);
	g_heal.AddChangeHook(OnCVarChange);

	AutoExecConfig(true, "l4d2_TankFightClub");

	RegConsoleCmd("sm_fc", CmdCount, "Tank Fight Club info");
	RegConsoleCmd("sm_fightclub", CmdCount, "Tank Fight Club info");
	RegConsoleCmd("sm_tankclub", CmdCount, "Tank Fight Club info");
	RegAdminCmd("sm_ko", CmdSlay, ADMFLAG_KICK, "K.O - Slay all Tanks");
	RegAdminCmd("sm_knockout", CmdSlay, ADMFLAG_KICK, "K.O - Slay all Tanks");

	zombie = FindConVar("z_common_limit");
	bosses = FindConVar("director_no_bosses");
	specials = FindConVar("director_no_specials");
	mobs = FindConVar("director_no_mobs");
	z_difficulty = FindConVar("z_difficulty");
	tank_burn_duration = FindConVar("tank_burn_duration");
	tank_burn_duration_hard = FindConVar("tank_burn_duration_hard");
	tank_burn_duration_expert = FindConVar("tank_burn_duration_expert");
	Director();
}

public void OnPluginEnd()
{
	ResetConVar(zombie);
	ResetConVar(bosses);
	ResetConVar(specials);
	ResetConVar(mobs);
}

public void OnMapStart()
{
	if (block4 == false)
	{
		block2 = false;
		block3 = false;
		PrecacheSound(SOUND_CLOCK, true);
		PrecacheSound(SOUND_FIGHT, true);
		PrecacheSound(SOUND_TANK, true);
		ExpandedEditionEnable();
	}
	else
	{
		#if debug
		PrintToServer("%s OnMapStart Blocked! Plugin [Tank Fight Club: Expanded edition] Disable", TAG);
		#endif
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (block4 == false)
	{
		CreateTimer(20.0, Welcome, GetClientUserId(client));

		if (block2 == false && block3 == false)
		{
			#if debug
			CPrintToChatAll("%s OnClientPostAdminCheck is NOT Blocked!", TAG);
			#endif

			block2 = true;
			ResetValues();
		}
		else
		{
			#if debug
			CPrintToChatAll("%s OnClientPostAdminCheck is Blocked!", TAG);
			#endif
		}
	}
	else
	{
		#if debug
		CPrintToChatAll("%s OnClientPostAdminCheck is Blocked! Plugin Disable", TAG);
		#endif
	}
}
/*////////////////////////
		= Event =
*////////////////////////
void RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_CvarInfo == 1 || g_CvarInfo == 2 || g_CvarInfo == 3)
	{
		CPrintToChatAll("%s haha Tanks beat you? {olive}Table{default} of Fighting is:\n Tanks Today: {green}%d{default}\n Tanks Killed: {blue}%d{default}\n Last Round was: {olive}%d{default}\n ------", FC, TankALL, TankCount, n);
	}
	ResetValues();
}

void NewTank(Event event, const char[] name, bool dontBroadcast)
{
	#if debug
	CPrintToChatAll("%s New Tank", TAG);
	#endif

	if (TankLive <= 6) //fixed bug *
		TankLive++;
	else
		CPrintToChatAll("%s WARNING! Reached the Maximum Tanks limit!", FC);

	int tank = GetClientOfUserId(event.GetInt("userid"));
	switch (n)
	{
		case 0:
		{
			if (TankRound == g_CvarRound1)
			{
				SetTahkHealth(tank, g_CvarHealth1);
				#if debug
				CurrentTankHP = g_CvarHealth1;
				#endif
			}
			else
			{
			    SetTahkHealth(tank, g_CvarHealth);
			    #if debug
			    CurrentTankHP = g_CvarHealth;
			    #endif
			}
		}
		case 1:
		{
			if (TankRound == g_CvarRound2)
			{
				SetTahkHealth(tank, g_CvarHealth2);
				#if debug
				CurrentTankHP = g_CvarHealth2;
				#endif
			}
		}
		case 2:
		{
			if (TankRound == g_CvarRound3)
			{
				SetTahkHealth(tank, g_CvarHealth3);
				#if debug
				CurrentTankHP = g_CvarHealth3;
				#endif
			}
		}
		case 3:
		{
			if (TankRound == g_CvarRound4)
			{
				SetTahkHealth(tank, g_CvarHealth4);
				#if debug
				CurrentTankHP = g_CvarHealth4;
				#endif
			}
		}
		case 4:
		{
			//Extra
			if (TankRound == g_CvarRound5 && g_bCvarExtra)
			{
				SetTahkHealth(tank, g_CvarHealth5);
				#if debug
				CurrentTankHP = g_CvarHealth5;
				#endif
			}
		}
		case 5:
		{
			if (TankRound == g_CvarRound6 && g_bCvarExtra)
			{
				SetTahkHealth(tank, g_CvarHealth6);
				#if debug
				CurrentTankHP = g_CvarHealth6;
				#endif
			}
		}
		case 6:
		{
			if (TankRound == g_CvarRound7 && g_bCvarExtra)
			{
				SetTahkHealth(tank, g_CvarHealth7);
				#if debug
				CurrentTankHP = g_CvarHealth7;
				#endif
			}
		}
	}
	#if debug
	CPrintToChatAll("%s Tank is spawn, TankHp = {green}%d{default}, TankLive =  {green}%d", TAG, CurrentTankHP, TankLive);
	#endif
}

void TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (TankLive >= 1) //fixed bug *
		TankLive--;

	if (KOblock == false)
	{
		TankALL++;
		TankRound++;
		TankCount++;
		Info();

		switch (n)
		{
			case 0:
			{
				if (TankRound == g_CvarRound1)
				{
					KO();
					PrintHintTextToAll("Round 1");
					TankRound = 0;
					n = 1;
					EmitSoundToAll(SOUND_FIGHT);
				}
			}
			case 1:
			{
				if (TankRound == g_CvarRound2)
				{
					KO();
					PrintHintTextToAll("Round 2");
					TankRound = 0;
					n = 2;
					EmitSoundToAll(SOUND_FIGHT);
				}
			}
			case 2:
			{
				if (TankRound == g_CvarRound3)
				{
					KO();
					TankRound = 0;
					n = 3;
					EmitSoundToAll(SOUND_FIGHT);
					if (!g_bCvarSupport){
						PrintHintTextToAll("Round 3");
					}
					//===Ext Ed===
					if (g_bCvarSupport)
					{
						PrintHintTextToAll("Round 3 SuperTanks");
						ST.SetInt(1);
						STI.SetInt(1);
					}
				}
			}
			case 3:
			{
				if (TankRound == g_CvarRound4)
				{
					KO();
					PrintHintTextToAll("Round 4");
					TankRound = 0;
					n = 4;
					EmitSoundToAll(SOUND_FIGHT);
					if (g_bCvarSupport)
					{
						ST.SetInt(0);
						STI.SetInt(0);
					}
				}
			}
			case 4:
			{
			    //Extra
				if (TankRound == g_CvarRound5 && g_bCvarExtra)
				{
					KO();
					PrintHintTextToAll("Extra Round 5");
					TankRound = 0;
					n = 5;
					EmitSoundToAll(SOUND_FIGHT);
				}
			}
			case 5:
			{
				if (TankRound == g_CvarRound6 && g_bCvarExtra)
				{
					KO();
					TankRound = 0;
					n = 6;
					EmitSoundToAll(SOUND_FIGHT);
					if (!g_bCvarSupport)
					{
						PrintHintTextToAll("Extra Round 6");
					}
					//===Ext Ed===
					if (g_bCvarSupport)
					{
						PrintHintTextToAll("Extra Round 6 SuperTanks");
						ST.SetInt(1);
						STI.SetInt(1);
					}
				}
			}
			case 6:
			{
				if (TankRound == g_CvarRound7 && g_bCvarExtra)
				{
					KO();
					PrintHintTextToAll("Extra Round 7");
					TankRound = 0;
					n = 7;
					EmitSoundToAll(SOUND_FIGHT);
					if (g_bCvarSupport)
					{
						ST.SetInt(0);
						STI.SetInt(0);
					}
				}
			}
		}
	}
	#if debug
	CPrintToChatAll("%s Tank is Die, TankHp = {green}%d{default}, TankLive =  {green}%d", TAG, CurrentTankHP, TankLive);
	#endif
}

void PanicEvent(Event event, const char[] name, bool dontBroadcast)
{
	if (block == false && block3 == false)
	{
		#if debug
		CPrintToChatAll("%s Panic Event before time up!", TAG);
		#endif

		club = true;
		block = true;
		Triger();
	}
	else 
	{
		#if debug
		CPrintToChatAll("%s Panic Event is Blocked!", TAG);
		#endif
		return;
	}
}

/*////////////////////////
		= Timer =
*////////////////////////
Action PrintMsg(Handle timer)
{
	int l = g_CvarTimer - m;
	if(l <= 0)
	{
		club = true;
		Triger();
		return Plugin_Stop;
	}
	else 
	{
		CPrintToChatAll("Game Starts in {green}%d{default} sec.", l);
		EmitSoundToAll(SOUND_CLOCK);
		m += 15;
		return Plugin_Continue;
	}
}

Action SpawnTank(Handle timer)
{
	int client = GetRandomClient();
	if (client)
	{
		if (TankLive <= 1)
		{
			int human = 0;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2)
				{
					human++;
					if (TankLive < human - g_CvarBS)
					{
						CheatCommand(client, L4D2 ? "z_spawn_old" : "z_spawn", "tank auto");
					}
				}
			}
		}
		return Plugin_Continue;
	}
	else
	{
		#if debug
		CPrintToChatAll("%s `SpawnTank` return client BOT, clent not on Game!", TAG);
		#endif
		return Plugin_Stop;
	}
}

Action Welcome(Handle timer, any client)
{
	client = GetClientOfUserId(client);
	if (client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		CPrintToChat(client, "%s {olive}%N{default} Welcome to TFC by {olive}raziEiL [disawar1]{default}\nType {olive}!fc{default} in chat to see the results of fights.", FC, client);
	}
	return Plugin_Stop;
}

void Triger()
{
	if (MsgTimer != null)
	{
		delete MsgTimer;
		#if debug
		CPrintToChatAll("%s Kill timer", TAG);
		#endif
	}
	if (TankFightClubTimer != null)
	{
		delete TankFightClubTimer;
		#if debug
		CPrintToChatAll("%s Kill timer spawntank", TAG);
		#endif
	}
	if (club == true)
	{
		TankFightClub();
	}
}

/*////////////////////////
	= Tank Fight Club =
*////////////////////////
void TankFightClub()
{
	block3 = true;
	CPrintToChatAll("{green}Game Started!");
	PrintHintTextToAll("Fight!");
	EmitSoundToAll(SOUND_FIGHT);
	CheatCommand(GetRandomClient(), "director_force_panic_event");
	TankFightClubTimer = CreateTimer(5.0, SpawnTank, _, TIMER_REPEAT);
}

/*////////////////////////
   = Expanded Edition =
*////////////////////////
void ExpandedEditionEnable()
{
	g_bCvarSupport = g_support.BoolValue;
	if (g_bCvarSupport && g_bCvarEnable)
	{
		ExpandedEdition(true);
	}
}

void ExpandedEdition(bool status)
{
	if( ST == null ) ST = FindConVar("st_on");
	if( STF == null ) STF = FindConVar("st_finale_only");
	if( STI == null ) STI = FindConVar("st_display_health");
	if( ST1 == null ) ST1 = FindConVar("st_wave1_tanks");
	if( ST2 == null ) ST2 = FindConVar("st_wave2_tanks");
	if( ST3 == null ) ST3 = FindConVar("st_wave3_tanks");

	if (status)
	{
		ST.SetInt(0);
		STF.SetInt(0);
		STI.SetInt(0);
		ST1.SetInt(0);
		ST2.SetInt(0);
		ST3.SetInt(0);
	}
}

void KO()
{
	if (g_bCvarHeal)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				HealingTouch(i);
			}
		}
	}

	if (g_bCvarKo  && KOblock2 == false && TankLive != 0)
	{
		KOblock = true;

		for(int i = 1; i <= MaxClients; i++)
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && IsPlayerTank(i) )
			{
				ForcePlayerSuicide(i);
			}
		}

		KOblock = false;
	}
}

/*////////////////////////
		= Cmd =
*////////////////////////
Action CmdCount(int client, int agrs)
{
	CPrintToChat(client, "%s Round: {olive}%d{default}, Tanks Killed: {blue}%d{default}, TankOnMap: {green}%d", FC, n, TankCount, TankLive);
	return Plugin_Handled;
}

Action CmdSlay(int client, int agrs)
{
	CPrintToChat(client, "%s {blue}Trying to kill Tanks...", FC);
	if (KOblock == false){

		if (TankLive != 0)
		{
			KOblock2 = true;
			CPrintToChat(client, "%s {olive}Successfully! -%d", FC, TankLive);

			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && IsPlayerTank(i) )
				{
					ForcePlayerSuicide(i);
				}
			}
			KOblock2 = false;
		}
		else
		{
			CPrintToChat(client, "%s {blue}Can't, no target!", FC);
		}
	}
	if (KOblock == true){

		CPrintToChat(client, "%s {blue}Can't, try again later...", FC);
	}
	return Plugin_Handled;
}

bool IsPlayerTank(int i)
{
	return GetEntProp(i, Prop_Send, "m_zombieClass") == (L4D2 ? 8 : 5);
}

/*////////////////////////
		= Message =
*////////////////////////
void Info()
{
	if (g_CvarInfo == 0) return;

	EmitSoundToAll(SOUND_TANK);

	if (g_CvarInfo == 1 || g_CvarInfo == 3)
	{
		int i = g_CvarRound1 - TankCount;
		int a = g_CvarRound2 + g_CvarRound1;
		int b = a + g_CvarRound3;
		int c = b + g_CvarRound4;
		int d = c + g_CvarRound5;
		int e = d +	g_CvarRound6;
		int f = e +	g_CvarRound7;
		int a1 = a - TankCount;
		int b2 = b - TankCount;
		int c3 = c - TankCount;
		int d4 = d - TankCount;
		int e5 = e - TankCount;
		int f6 = f - TankCount;

		switch (n)
		{
			case 0:
			{
				if (g_CvarInfo == 3)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound1);
				}
				else
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", i);
				}
			}
			case 1:
			{
				if (g_CvarInfo == 3)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound2);
				}
				else
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", a1);
				}
			}
			case 2:
			{
				if (g_CvarInfo == 3)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound3);
				}
				else
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", b2);
				}
			}
			case 3:
			{
				if (g_CvarInfo == 3)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound4);
				}
				else
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", c3);
				}
			}
			//
			case 4:
			{
				if (g_CvarInfo == 3 && g_bCvarExtra)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound5);
				}
				if (g_CvarInfo == 3 && !g_bCvarExtra)
				{
					CPrintToChatAll("{olive}Total Tanks: {default}%d", TankRound);
				}
				if (g_CvarInfo == 1 && g_bCvarExtra)
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", d4);
				}
				if (g_CvarInfo == 1 && !g_bCvarExtra)
				{
					CPrintToChatAll("{olive}Total Tanks: {default}%d", TankRound);
				}
			}
			case 5:
			{
				if (g_CvarInfo == 3 && g_bCvarExtra)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound6);
				}
				else
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", e5);
				}
			}
			case 6:
			{
				if (g_CvarInfo == 3 && g_bCvarExtra)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound7);
				}
				else
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", f6);
				}
			}
			case 7:
			{
				CPrintToChatAll("{olive}Total Tanks: {default}%d", TankRound);
			}
		}
	}
	if (g_CvarInfo == 2){
			CPrintToChatAll("{green}Tanks Killed: {default}%d", TankCount);
	}
}

/*////////////////////////
		= GetConVar =
*////////////////////////
void OnExpandedEditionEnable(ConVar convar_hndl, const char[] oldValue, const char[] newValue)
{
	ExpandedEditionEnable();
}

void OnPluginEnable(ConVar convar_hndl, const char[] oldValue, const char[] newValue)
{
	Plugin();
}

void OnDirectorEnable(ConVar convar_hndl, const char[] oldValue, const char[] newValue)
{
	Director();
}

void OnCVarChange(ConVar convar_hndl, const char[] oldValue, const char[] newValue)
{
	GetCVars();
}

public void OnConfigsExecuted()
{
	GetCVars();
	Plugin();
	Director();
	ExpandedEditionEnable();
}

void GetCVars()
{
	g_CvarInfo = g_info.IntValue;
	g_CvarHealth = g_health.IntValue;
	g_CvarTimer = g_timer.IntValue;
	g_bCvarExtra = g_extra.BoolValue;
	g_bCvarKo = g_ko.BoolValue;
	g_CvarBS = g_bs.IntValue;
	g_CvarHealth1 = g_health1.IntValue;
	g_CvarHealth2 = g_health2.IntValue;
	g_CvarHealth3 = g_health3.IntValue;
	g_CvarHealth4 = g_health4.IntValue;
	g_CvarHealth5 = g_health5.IntValue;
	g_CvarHealth6 = g_health6.IntValue;
	g_CvarHealth7 = g_health7.IntValue;
	g_CvarRound1 = g_round1.IntValue;
	g_CvarRound2 = g_round2.IntValue;
	g_CvarRound3 = g_round3.IntValue;
	g_CvarRound4 = g_round4.IntValue;
	g_CvarRound5 = g_round5.IntValue;
	g_CvarRound6 = g_round6.IntValue;
	g_CvarRound7 = g_round7.IntValue;
	g_bCvarHeal = g_heal.BoolValue;
	g_bCvarZombie = g_zombie.BoolValue;
}

/*////////////////////////
	= Enable\Disable =
*////////////////////////
void Director()
{
	if (g_bCvarZombie)
	{
		DirectorEnable(true);
	}
	else
	{
		DirectorEnable(false);
	}
}

void DirectorEnable(bool status)
{
	if (status)
	{
		bosses.SetInt(1);
		specials.SetInt(1);
		mobs.SetInt(1);
		zombie.SetInt(0);
	}
	else
	{
		bosses.SetInt(0);
		specials.SetInt(0);
		mobs.SetInt(0);
		ResetConVar(zombie);
	}
}

void Plugin()
{
	g_bCvarEnable = g_enable.BoolValue;
	if (block5 == false && g_bCvarEnable)
	{
		#if debug
		CPrintToChatAll("%s HookEvent", TAG);
		#endif

		ExpandedEditionEnable();// SuperBoss
		HookEvent("tank_killed", TankKilled);
		HookEvent("round_start", RoundStart);
		HookEvent("create_panic_event", PanicEvent);
		HookEvent("tank_spawn", NewTank);
		block4 = false;
		block5 = true;
	}
	else if (block5 == true && !g_bCvarEnable){

		#if debug
		CPrintToChatAll("%s UnhookEvent", TAG);
		#endif

		Triger();// kill timer
		UnhookEvent("tank_killed", TankKilled);
		UnhookEvent("round_start", RoundStart);
		UnhookEvent("create_panic_event", PanicEvent);
		UnhookEvent("tank_spawn", NewTank);
		block4 = true;
		block5 = false;
	}
}

void ResetValues()
{
	//reset
	TankLive = 0;
	TankCount = 0;
	TankRound = 0;
	n = 0;
	m = 0;
	club = false;
	block = false;
	block3 = false;
	//kill timer
	Triger();
	//start timer
	MsgTimer = CreateTimer(15.0, PrintMsg, _, TIMER_REPEAT);
	Director();
	ExpandedEditionEnable();

	#if debug
	CPrintToChatAll("%s Restart_Round: TankHp = {green}%d{default}, TankCount = {green}%d{default}, TankRound = {green}%d{default}, TankLive = {green}%d", TAG, CurrentTankHP, TankCount, TankRound, TankLive);
	#endif
}

void SetTahkHealth(int tank, int health)
{
	tank = GetClientOfUserId(tank);
	if(tank && IsClientInGame(tank))
	{
		SetEntProp(tank, Prop_Data, "m_iMaxHealth", health);
		SetEntProp(tank, Prop_Data, "m_iHealth", health);

		static char sBuffer[64], sGameDifficulty[16];
		z_difficulty.GetString( sBuffer, sizeof(sBuffer));

		if (StrEqual(sBuffer, "Easy", false)) TankBurnIndex = 0.011666;
		else if (L4D2 ? StrEqual(sBuffer, "Hard", false) : StrEqual(sBuffer, "Advanced", false)) TankBurnIndex = 0.013333;
		else if (L4D2 ? StrEqual(sBuffer, "Impossible", false) : StrEqual(sBuffer, "Expert", false)) TankBurnIndex = 0.014166;
		else TankBurnIndex = 0.0125;

		float TankBurnTime = float(health) * TankBurnIndex;
		int TankBurnHP = RoundToCeil( TankBurnTime );
		if (StrEqual(sGameDifficulty, "Easy", false)) tank_burn_duration.IntValue = TankBurnHP;
		else if (StrEqual(sGameDifficulty, "Normal", false)) tank_burn_duration.IntValue = TankBurnHP;
		else if (L4D2 ? StrEqual(sGameDifficulty, "Hard", false) : StrEqual(sGameDifficulty, "Advanced", false)) tank_burn_duration_hard.IntValue = TankBurnHP;
		else if (L4D2 ? StrEqual(sGameDifficulty, "Impossible", false) : StrEqual(sGameDifficulty, "Expert", false)) tank_burn_duration_expert.IntValue = TankBurnHP;
	}
}

/*=========================
	= CheatCommand code =
==========================*/
void CheatCommand(int client, const char[] command, const char[] arguments = "")
{
	if (client)
	{
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}

void HealingTouch(int client)
{
	CheatCommand(client, "give", "health");
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
	SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
	SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
}

int GetRandomClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			return i;
		}
	}
	return 0;
}
