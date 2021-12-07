#define CVAR_FLAGS FCVAR_PLUGIN
#define MAX_PLAYERS 24
#define MAXLENGTH 250
#include <sourcemod>
#include <sdktools>
#define MAXLENGTHSECOND 250
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3
#define ZOMBIECLASS_JOCKEY	5
#define INCAP	         1
#define INCAP_RIDE		 4
#define INCAP_EDGEGRAB	 6
#define NOT_JOCKIED		 8
#define TICKS 10
#define STATE_NONE 0
#define STATE_SELFHELP 1
#define STATE_OK 2
#define STATE_FAILED 3
#define PLUGIN_VERSION "1.0.7a"
#define DEBUG 0//TO TEST small parts of the program
#define ZOMBIECLASS_BOOMER	2
#define MODEL_V_PIPEBOMB "models/v_models/v_pipebomb.mdl"
#define MODEL_V_MOLOTOV "models/v_models/v_molotov.mdl"
#define MODEL_V_VOMITJAR "models/v_models/v_bile_flask.mdl"
#define MODEL_V_PISTOL_1 "models/v_models/v_pistol.mdl"
#define MODEL_V_PISTOL_2 "models/v_models/v_pistola.mdl"
#define MODEL_V_DUALPISTOL_1 "models/v_models/v_dualpistols.mdl"
#define MODEL_V_DUALPISTOL_2 "models/v_models/v_dual_pistola.mdl"
#define MODEL_V_MAGNUM "models/v_models/v_desert_eagle.mdl"
#define MODEL_GASCAN "models/props_junk/gascan001a.mdl"
#define MODEL_PROPANE "models/props_junk/propanecanister001a.mdl"
#define MODEL_W_PIPEBOMB "models/w_models/weapons/w_eq_pipebomb.mdl"
#define MODEL_W_MOLOTOV "models/w_models/weapons/w_eq_molotov.mdl"
#define MODEL_W_VOMITJAR "models/w_models/weapons/w_eq_bile_flask.mdl"
#define SOUND_PIPEBOMB "weapons/hegrenade/beep.wav"
#define SOUND_VOMITJAR ")weapons/ceda_jar/ceda_jar_explode.wav"
#define SOUND_MOLOTOV "weapons/molotov/fire_ignite_2.wav"
#define SOUND_PISTOL "weapons/pistol/gunfire/pistol_fire.wav"
#define SOUND_DUAL_PISTOL ")weapons/pistol/gunfire/pistol_dual_fire.wav"
#define SOUND_MAGNUM ")weapons/magnum/gunfire/magnum_shoot.wav"
#define BOUNCE_TIME 10
#define TEAM_SURVIVOR 2
#define PARTICLE_DEATH	"gas_explosion_main"
#define EXPLODE 	1
#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"
#define UNLOCK 0
#define LOCK 1

new yesVote=0;
new noVote=0;
new Attacker[MAXPLAYERS+1];
new SafetyLock;
new IncapType[MAXPLAYERS+1];
new Handle:l4d_allow_grenade = INVALID_HANDLE;
new g_burning_timeleft[MAXPLAYERS + 1];
new Handle: g_molotov_timer[MAXPLAYERS + 1];
new Handle: g_burning_countdown[MAXPLAYERS + 1];
new Handle:g_Fire_Timers[MAX_PLAYERS+1];
new g_got_burnt[MAXPLAYERS + 1] = 0;
new Handle: L4d2_Fire_slowdown_duration;
new Handle:L4d2_how_often_adr_1st_player;
new Handle:L4d2_how_often_adr_2nd_player;
new Handle:L4d2_how_often_adr_3rd_player;
new Handle:L4d2_how_often_adr_4th_player;

new Handle: L4d2_how_often_grenade;
new g_biled_timeleft[MAXPLAYERS + 1];
new Handle: g_bile_timer[MAXPLAYERS + 1];
new Handle: g_biled_countdown[MAXPLAYERS + 1];
new Handle:g_bile_Timers[MAX_PLAYERS+1];
new g_got_biled[MAXPLAYERS + 1] = 0;
new UserMsg:g_FadeUserMsgId; // UserMessageId for Fade.
new Handle:h_killgrenade=INVALID_HANDLE;
new Handle:h_positions=INVALID_HANDLE;
new Handle: Gamemode_jockey_racing;
new Handle: L4d2_Jockey_racing_broadcast;
new Handle: L4d2_drug_boost_duration;
new Handle:L4d2_jockey_slowdown_enable;
new Handle: L4d2_drug_boost_on;
new Handle: WelcomeTimers[MAXPLAYERS + 1];
new Handle: g_powerups_timer[MAXPLAYERS + 1];
new Handle: g_powerups_countdown[MAXPLAYERS + 1];
new String:NotSet[] = "-1 -1 -1";
new String:Red[] = "255 0 0";
new String:Green[] = "0 255 0";
new String:Black[] = "0 0 0";
new String:Yellow[] = "255 242 0";
new g_usedhealth[MAXPLAYERS + 1] = 0;
new g_powerups_timeleft[MAXPLAYERS + 1];
new Handle:l4d_selfhelp_incap = INVALID_HANDLE;
new Handle:l4d_selfhelp_delay = INVALID_HANDLE;
new Handle:l4d_selfhelp_hintdelay = INVALID_HANDLE;
new Handle:l4d_selfhelp_duration = INVALID_HANDLE;
new Handle:l4d_selfhelp_ride = INVALID_HANDLE;
new Handle:l4d_kill_bot_survivors = INVALID_HANDLE;
new Handle:l4d_selfhelp_edgegrab = INVALID_HANDLE;
new Handle:Ellis = INVALID_HANDLE;
new Handle:Coach = INVALID_HANDLE;
new Handle:rochelle = INVALID_HANDLE;
new Handle:Nick = INVALID_HANDLE;
new Handle:Render = INVALID_HANDLE;
new Handle:Allowed = INVALID_HANDLE;
new finishId[8]; //ids of people who reached safe room
new place; //number of survivors that made it to the saferoom
new award[8]; //award scores
new clientId[8]; //steam ids of clients
new score[8]; //keep track of clients current scores
new stillRacing; //number of players who have not made it to the safe room and have not been incapacitated
new mapNum; //the number that points to the correct array of saferoom position coords.
//keep track of how many seconds till racing starts.
new Handle:h_Final_time=INVALID_HANDLE;
new race_timer = -30;//30 default
new minutes_counter = 0;
//When a player gets to a checkpoint (start checkpoints included) their position must be within these constraints so we know they are at the end of the level.
new safeRoomArea[26][6];
new secondsToGo = 30;
new Player_count = 0;
new Player_count_two = 0;
new inc = 0;
new secondsToGo_two = 0;
static LagMovement = 0;



new Handle:L4d2_how_kill_adr_1st_player=INVALID_HANDLE;
new Handle:L4d2_how_kill_adr_2nd_player=INVALID_HANDLE;
new Handle:L4d2_how_kill_adr_3rd_player=INVALID_HANDLE;
new Handle:L4d2_how_kill_adr_4th_player=INVALID_HANDLE;
new Float:I_Safehouse[3];
new Handle:h_gatekill=INVALID_HANDLE;
new Handle:h_SFtrigger=INVALID_HANDLE;
new Handle:h_botkilltimer=INVALID_HANDLE;
new Handle:h_killadrenaline=INVALID_HANDLE;
new Handle:h_countdown = INVALID_HANDLE;
new String:SoundNotice[MAXLENGTHSECOND] = "level/puck_fail.wav";
new String:SoundNotices[MAXLENGTHSECOND] = "items/suitchargeok1.wav";
new Handle:g_Timers[MAX_PLAYERS+1];
new g_Say[MAX_PLAYERS+1];
new HelpState[MAXPLAYERS+1];
new HelpOhterState[MAXPLAYERS+1];
new Handle:Timers[MAXPLAYERS+1];
new Float:HelpStartTime[MAXPLAYERS+1];



//safeRoomArea[0] = {1800,2000,4450,4750,1150,1300};  

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

new const String:g_VoiceMolotovNick[4][] =
{
	"grenade03",
	"grenade04",
	"grenade06",
	"grenade08"
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

new const String:g_VoiceMolotovRochelle[3][] =
{
	"grenade03",
	"grenade04",
	"grenade06"
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

new const String:g_VoiceMolotovCoach[3][] =
{
	"grenade02",
	"grenade04",
	"grenade05"
}

new const String:g_VoiceVomitjarCoach[3][] =
{
	"boomerjar09",
	"boomerjar10",
	"boomerjar11"
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

new const String:g_VoiceMolotovEllis[4][] =
{
	"grenade05",
	"grenade06",
	"grenade08",
	"grenade10"
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




enum GRENADE_TYPE
{
	NONE,
	PIPEBOMB,
	MOLOTOV,
	VOMITJAR
}

enum GAME_MOD
{
	LEFT4DEAD,//TO REMOVE, not done yet due to it causing a few problems
	LEFT4DEAD2
}

new g_ActiveWeaponOffset, g_PipebombModel, g_MolotovModel, g_VomitjarModel, GRENADE_TYPE:g_PlayerIncapacitated[MAXPLAYERS+1], 
Float:g_PlayerGameTime[MAXPLAYERS+1], GAME_MOD:g_Mod, g_ThrewGrenade[MAXPLAYERS+1], 
g_PipebombBounce[MAXPLAYERS+1], bool:g_b_InAction[MAXPLAYERS+1], Handle:g_h_GrenadeTimer[MAXPLAYERS+1], bool:g_b_AllowThrow[MAXPLAYERS+1],bool:g_boomed[MAXPLAYERS+1], 
Handle:g_t_PipeTicks, Handle:h_CvarMessageType,
g_PistolModel, g_DualPistolModel, g_MagnumModel, Handle:g_t_GrenadeOwner

public Plugin:myinfo = 
{
	name = "L4D2_Jockey_racing",
	author = "Fleep",
	description = "This plugin has been created to facilitate players to race in teams with jockeys",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1250293#post1250293"
}

public OnPluginStart()
{
	
	decl String:stGame[32];
	GetGameFolderName(stGame, 32);
	if (!StrEqual(stGame, "left4dead2", false)) SetFailState("Left 4 Dead 2 only, No jockeys no mod.")
	CreateTimer(0.5,kill_infected, _, TIMER_REPEAT);//stops the director and any infected from spawning
	CreateTimer(0.5,Remove_melee, _, TIMER_REPEAT);//Removes all melee weapons (they kill jockeys :/)
	CreateTimer(2.0, Spawn_em, _, TIMER_REPEAT)
	CreateTimer(40.0, StartVote, _, TIMER_REPEAT)	
	CreateConVar("sm_Jockey_racing_version", PLUGIN_VERSION,"Jockey racing plugin version.", FCVAR_REPLICATED|FCVAR_NOTIFY);
	Gamemode_jockey_racing = CreateConVar("Gamemode_jockey_racing","1", "Is Jockey racing on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	l4d_selfhelp_incap = CreateConVar("l4d_selfhelp_incap", "1", "When someone gets incapd they can pick themselves up(usefull for players who have god off,future releases) , 0:disable, 1:Enable", FCVAR_PLUGIN);
	L4d2_drug_boost_on = CreateConVar("L4d2_drug_boost_on","1", "Allow survivor to become faster with adrenaline", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	L4d2_jockey_slowdown_enable = CreateConVar("L4d2_jockey_slowdown_enable","1","Should jockeys and humans be slower on their own after the race starts, recommended due to alot of teamless runners",FCVAR_PLUGIN, true, 0.0, true, 1.0);
	l4d_selfhelp_duration = CreateConVar("L4d2_selfhelp_duration", "2.0", "How fast does the adrenaline bar fill (in seconds)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	L4d2_drug_boost_duration = CreateConVar("L4d2_drug_boost_duration","12","Amount of time that the adrenaline boost will last",FCVAR_PLUGIN, true, 1.0);
	L4d2_Jockey_racing_broadcast = CreateConVar("L4d2_Jockey_racing_broadcast","1","Tell players about Jockey racing when they join? ",FCVAR_PLUGIN, true, 0.0, true, 1.0);
	l4d_selfhelp_ride = CreateConVar("L4d2_selfhelp_ride", "1", " Allow player to take adrenaline with a jockey on them , 0:disable, 1:adren,pills, 2:medkit, 3:both ", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	l4d_selfhelp_edgegrab = CreateConVar("L4d2_selfhelp_edgegrab", "1", "When someone hangs off the edge they can take pick themselves back up, 0:Disable, 1:Enable  ", FCVAR_PLUGIN);
	l4d_selfhelp_hintdelay = CreateConVar("L4d2_selfhelp_hintdelay", "3.0", "Number of seconds before player gets told about the adrenaline boost", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 10.0);
	l4d_selfhelp_delay = CreateConVar("L4d2_selfhelp_delay", "1.0", "Number of seconds before a player CAN use the adrenaline", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	l4d_kill_bot_survivors = CreateConVar("l4d_kill_bot_survivors","0","Kill any Human bots after 60 seconds of racestart(recommend for less than 8 players on versus) ",FCVAR_PLUGIN, true, 0.0, true, 1.0);
	h_CvarMessageType = CreateConVar("l4d_incapped_message_type", "2", "How is player told that he can throw bile & molotovs (0 - disable, 1 - chat, 2 - hint)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0)
	L4d2_Fire_slowdown_duration = CreateConVar("L4d2_Fire_slowdown_duration","8","When a player gets biled or molotoved, how many seconds does it take for them to RECOVER",FCVAR_PLUGIN, true, 1.0);
	L4d2_how_often_adr_1st_player = CreateConVar("L4d2_how_often_adr_1st_player","60","How often does the 1st player in a race get adrenaline to use?seconds CAN'T be lower than below value(61 to disable)",FCVAR_PLUGIN, true, 1.0);
	L4d2_how_often_adr_2nd_player = CreateConVar("L4d2_how_often_adr_2nd_player","45","How often does the 2nd player in a race get adrenaline to use?seconds CAN'T be lower than below value(61 to disable)",FCVAR_PLUGIN, true, 1.0);
	L4d2_how_often_adr_3rd_player = CreateConVar("L4d2_how_often_adr_3rd_player","30","How often does the 3rd player in a race get adrenaline to use?seconds CAN'T be lower than below value(61 to disable)",FCVAR_PLUGIN, true, 1.0);
	L4d2_how_often_adr_4th_player = CreateConVar("L4d2_how_often_adr_4th_player","20","How often does the 4th player in a race get adrenaline to use?(seconds)(61 to disable)",FCVAR_PLUGIN, true, 1.0);
	L4d2_how_often_grenade = CreateConVar("L4d2_how_often_grenade","30","How often do players get molos and vomitjars to use?(seconds)",FCVAR_PLUGIN, true, 1.0);
	l4d_allow_grenade = CreateConVar("l4d_allow_grenade", "1", " Allow player to throw bile & molotovs at each other with a jockey on them , 0:disable, 1:enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	Ellis = CreateConVar("sm_l4d_painter_ellis", Yellow,"RGB Value for ellis. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.( from gamemann's script)these values are NOT RECOMMENDED TO MODIFY unless you know what you are doing :)", FCVAR_NOTIFY);
	Coach = CreateConVar("sm_l4d_painter_coach", Black,"RGB Value for coach. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	rochelle = CreateConVar("sm_l4d_painter_rochelle", Red,"RGB Value for bill. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Nick = CreateConVar("sm_l4d_painter_nick", Green,"RGB Value for nick. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Render = CreateConVar("sm_l4d_painter_render_mode","0","Render mode of colored people.", 0, true, 0.0, true, 1.0);
	Allowed = CreateConVar("sm_l4d_painter_enabled","1","Enables painting zombies.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//Run cfg
	AutoExecConfig(true, "sm_jockey_racing")
	RegAdminCmd("jocki", jockeyspawn,ADMFLAG_GENERIC);//for testing purposes
	RegAdminCmd("molo", give_molo,ADMFLAG_GENERIC);//for testing purposes
	RegAdminCmd("bile", Give_bile,ADMFLAG_GENERIC);//for testing purposes
	RegAdminCmd("tank", tankspawn,ADMFLAG_GENERIC);//for testing purposes
	RegAdminCmd("raceon", racemode,ADMFLAG_GENERIC);
	RegAdminCmd("defib", defibrilator,ADMFLAG_GENERIC);//Incase someone dies
	RegConsoleCmd("mod", Hints);//re-displays server rules
	RegConsoleCmd("start", votestart); //allows players to check scores by typing '!scores' or '/scores' in the chat
	RegConsoleCmd("scores", chatCMD); //allows players to check scores by typing '!scores' or '/scores' in the chat
	RegAdminCmd("resetscore", resetScore, ADMFLAG_RCON, "Resetting the score.");
	RegAdminCmd("boom", boomerspawn,ADMFLAG_GENERIC);//for testing purposes
	
	HookEvent("player_use", Event_Player_Use);
	HookEvent("revive_success", EventReviveSuccess)
	HookEvent("revive_begin", EventReviveBegin)
	HookEvent("revive_end", EventReviveEnd)
	HookEvent("player_death", EventPlayerDeath)
	HookEvent("grenade_bounce", EventGrenadeBounce)
	HookEvent("player_team", EventPlayerTeam)
	HookEvent("pounce_stopped", EventAllowThrow)
	HookEvent("tongue_release", EventAllowThrow)
	HookEvent("round_end", Event_RoundEnd);
	
	HookEvent("player_spawn", Event_Player_Spawn); //Player spawned
	HookEvent("player_ledge_grab", player_ledge_grab);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("jockey_ride", jockey_ride);
	HookEvent("jockey_ride_end", jockey_ride_end);
	HookEvent("finale_vehicle_leaving", Event_FinaleOver); //give final scores
	HookEvent("player_entered_checkpoint", Event_PlayerWin); //give the player a score.
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("charger_pummel_end", EventAllowThrow)
	HookEvent("defibrillator_used", EventAllowThrow)
	
	//SCORING SYSTEM
	
	//assign score values. 0 is first place, 1 is second, etc...
	award[0] = 10;
	award[1] = 10;
	award[2] = 8;
	award[3] = 8;
	award[4] = 6;
	award[5] = 6;
	award[6] = 4;
	award[7] = 4;
	
	for(new i=0;i<8;i++) {
		score[i]=0;
		clientId[i]=0;
	}
	
	//When a player gets to a checkpoint (start checkpoints included) their position must be within these constraints so we know they are at the end of the level.
	//all finalies use the finale_vehicle_leaving event to give scores... not any area or saferoom.
	safeRoomArea[0] = {1800,2000,4450,4750,1150,1300};      //c1m1
	safeRoomArea[1] = {-7650,-7250,-4770,-4550,350,500};    //c1m2
	safeRoomArea[2] = {-2200,-1900,-4700,-4450,500,650};    //c1m3
	safeRoomArea[3] = {0,0,0,0,0,0};                        //c1m4 doesnt use a check point
	safeRoomArea[4] = {-1050,-800,-2700,-2350,-1150,-900};  //c2m1
	safeRoomArea[5] = {-4500,-4300,-5600,-5300,-150,50};    //c2m2
	safeRoomArea[6] = {-5200,-4950,1400,1900,-100,100};     //c2m3
	safeRoomArea[7] = {-850,-650,2250,2500,-300,-100};      //c2m4
	safeRoomArea[8] = {0,0,0,0,0,0};                        //c2m5 doesnt use a check point
	safeRoomArea[9] = {-2670,-2650,600,850,0,150};          //c3m1
	safeRoomArea[10] = {7300,7800,-1000,-650,50,250};       //c3m2
	safeRoomArea[11] = {4850,5100,-4000,-3700,300,450};     //c3m3
	safeRoomArea[12] = {1300,2000,4400,5000,-200,600};      //c3m4 swamp's boat area just incase.
	safeRoomArea[13] = {3700,4200,-1600,-1300,150,350};     //c4m1
	safeRoomArea[14] = {-1900,-1500,-13800,-13400,50,250};  //c4m2
	safeRoomArea[15] = {3800,4000,-2200,-1800,50,250};      //c4m3
	safeRoomArea[16] = {-3000,-2700,7700,8100,50,250};      //c4m4
	safeRoomArea[17] = {-7500,-7000,7400,8000,50,400};      //c4m5 hard rain's boat area just incase
	safeRoomArea[18] = {-4000,-3600,-1400,-900,-500,-200};  //c5m1
	safeRoomArea[19] = {-9800,-9400,-8400,-7800,-300,-100}; //c5m2
	safeRoomArea[20] = {7100,7600,-9600,-9300,50,250};      //c5m3
	safeRoomArea[21] = {1300,1600,-3600,-3200,0,200};       //c5m4
	safeRoomArea[22] = {7300,7500,3550,3900,100,300};       //c5m5 I was thinking about making the bridge a race too.
	safeRoomArea[23] = {-4100,-3700,1200,1600,650,850};     //c6m1
	safeRoomArea[24] = {11000,11400,4700,5200,-700,-500};   //c6m2
	safeRoomArea[25] = {0,0,0,0,0,0};                       //c6m3 never was able to get the car's coords
	g_FadeUserMsgId = GetUserMessageId("Fade");
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon")
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");	
	g_t_PipeTicks = CreateTrie()
	g_t_GrenadeOwner = CreateTrie() 	
}
public MenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Hints(client, args)
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		new Handle:menu = CreateMenu(MenuHandler1);
		SetMenuTitle(menu, "WELCOME to this JOCKEY RACING SERVER here are a few simple hints.?");
		
		AddMenuItem(menu, "hint 1", "\nDon't kill the jockeys, you're a TEAM.");
		AddMenuItem(menu, "hint 2", "\nWhen riding a survivor press SPACE TO JUMP");
		AddMenuItem(menu, "hint 3", "\nWhen a jockey is on you HOLD USE(E) for an ADRENALINE BOOST");
		AddMenuItem(menu, "hint 4", "\nWhen a jockey is on you use MOUSE1 to THORW a MOLOTOV OR BILE JAR at OTHER TEAMS");
		AddMenuItem(menu, "hint 5", "\nIf you see a LADDER RIGHT CLICK(melee) to JUMP off the survivor");
		AddMenuItem(menu, "hint 6", "\nType !scores (in chat) for a list of everyones score ");
		AddMenuItem(menu, "hint 7", "\nIf you are unsure about something just ask.");
		
		
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, client, 25);
		
	}
	return Plugin_Handled;
}



public OnClientPutInServer(client)
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		g_Say[client] = 3;
		CreateTimer(10.0, show_rules, client);	//sends a list of hints to whoever joins 
		
		g_usedhealth[client] = 0;
		if (GetConVarInt(L4d2_drug_boost_on)==0)
		{
			
			g_usedhealth[client] = 1;
			
			
		}
		
		if (client && !IsFakeClient(client))
		{
			WelcomeTimers[client] = CreateTimer(35.0, Timer_Notify, client)
		}
		
		if (IsFakeClient(client))
			return
		
		g_PlayerIncapacitated[client] = NONE
		g_b_InAction[client] = false
		g_b_AllowThrow[client] = false
		g_PlayerGameTime[client] = 0.0
		g_ThrewGrenade[client] = 0
		g_PipebombBounce[client] = 0
	}
}



public ControlDoor(Entity, Operation)
{
	if(Operation == LOCK)
	{
		/* Close and lock */
		AcceptEntityInput(Entity, "Close");
		AcceptEntityInput(Entity, "Lock");
		AcceptEntityInput(Entity, "ForceClosed");
		SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", LOCK);
	}
	else if(Operation == UNLOCK)
	{
		/* Unlock and open */
		SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
		AcceptEntityInput(Entity, "Unlock");
		AcceptEntityInput(Entity, "ForceClosed");
		AcceptEntityInput(Entity, "Open");
	}
}

public GetGrenadeOnIncap(i_Client)
{
	decl i_Grenade, String:s_ModelName[64]
	
	if(IncapType[i_Client]!= INCAP_RIDE)
	{
		g_b_AllowThrow[i_Client] = false//replaced c if it makes a dif
		
	}
	
	
	else
	{
		g_b_AllowThrow[i_Client] = true
		
		i_Grenade = GetPlayerWeaponSlot(i_Client, 2)
		
		if (IsValidEntity(i_Grenade))
		{
			GetEntPropString(i_Grenade, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName))
			
			if (StrEqual(s_ModelName, MODEL_V_PIPEBOMB))
				g_PlayerIncapacitated[i_Client] = PIPEBOMB
			else if (StrEqual(s_ModelName, MODEL_V_MOLOTOV))
				g_PlayerIncapacitated[i_Client] = MOLOTOV
			else if (StrEqual(s_ModelName, MODEL_V_VOMITJAR))
				g_PlayerIncapacitated[i_Client] = VOMITJAR
		}
	}
	return i_Grenade
}










































public Action:EventGrenadeBounce(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client, i_Ent
	
	i_UserID = GetEventInt(h_Event, "userid")
	i_Client = GetClientOfUserId(i_UserID)
	i_Ent = g_ThrewGrenade[i_Client]
	
	if (!IsValidEdict(i_Ent) || !i_Ent)
		return Plugin_Handled
	
	decl Float:f_Speed[3], String:s_ClassName[32]
	
	GetEdictClassname(i_Ent, s_ClassName, sizeof(s_ClassName))
	GetEntPropVector(i_Ent, Prop_Send, "m_vecVelocity", f_Speed)
	
	if (StrEqual(s_ClassName, "pipe_bomb_projectile"))
		g_PipebombBounce[i_Client]++
	
	if (g_PipebombBounce[i_Client] >= 2)
	{
		f_Speed[0] /= 1.3
		f_Speed[1] /= 1.3
		f_Speed[2] /= 1.3
	}
	else if (!g_PipebombBounce[i_Client])
	{
		f_Speed[0] /= 3.0
		f_Speed[1] /= 3.0
		f_Speed[2] /= 3.0
	}
	
	TeleportEntity(i_Ent, NULL_VECTOR, NULL_VECTOR, f_Speed)
	
	return Plugin_Continue
}

public Action:EventPlayerDeath(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client
	
	i_UserID = GetEventInt(h_Event, "userid")
	i_Client = GetClientOfUserId(i_UserID)
	
	if (i_Client >= 1 && i_Client <= MaxClients)
		if (GetClientTeam(i_Client) == TEAM_SURVIVOR)
			g_PlayerIncapacitated[i_Client] = NONE
	}


public Action: show_rules(Handle:timer, any:client)
{
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuTitle(menu, "WELCOME to this JOCKEY RACING SERVER here are a few simple hints.?");
	
	AddMenuItem(menu, "hint 1", "\nDon't kill the jockeys, you're a TEAM.");
	AddMenuItem(menu, "hint 2", "\nWhen riding a survivor press SPACE TO JUMP");
	AddMenuItem(menu, "hint 3", "\nWhen a jockey is on you HOLD USE(E) for an ADRENALINE BOOST");
	AddMenuItem(menu, "hint 4", "\nWhen a jockey is on you use MOUSE1 to THORW a MOLOTOV OR BILE JAR at OTHER TEAMS");
	AddMenuItem(menu, "hint 5", "\nIf you see a LADDER RIGHT CLICK(melee) to JUMP off the survivor");
	AddMenuItem(menu, "hint 6", "\nType !scores (in chat) for a list of everyones score ");
	AddMenuItem(menu, "hint 7", "\nIf you are unsure about something just ask.");
	
	
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 25);
	
	return Plugin_Handled;
	
}

public OnClientDisconnect(client)
{	if (GetConVarInt(Gamemode_jockey_racing))
	{
		if(g_Timers[client] != INVALID_HANDLE)
		{
			KillTimer(g_Timers[client]);
			g_Timers[client] = INVALID_HANDLE;
		}	
		if (g_usedhealth[client] == 1)
		{
			KillTimer(g_powerups_countdown[client])
			KillTimer(g_powerups_timer[client])
		}
		g_usedhealth[client] = 0;
		
		
		if(g_Fire_Timers[client] != INVALID_HANDLE)
		{
			KillTimer(g_Fire_Timers[client]);
			g_Fire_Timers[client] = INVALID_HANDLE;
		}	
		if (g_got_burnt[client] == 1)
		{
			KillTimer(g_burning_countdown[client])
			KillTimer(g_molotov_timer[client])
		}
		
		if(g_bile_Timers[client] != INVALID_HANDLE)
		{
			KillTimer(g_bile_Timers[client]);
			g_bile_Timers[client] = INVALID_HANDLE;
		}	
		if (g_got_biled[client] == 1)
		{
			KillTimer(g_biled_countdown[client])
			KillTimer(g_bile_timer[client])
		}
		g_got_biled[client] = 0;
		g_got_burnt[client] = 0;
	}
}



public Action:Check_players_positions(Handle:Timer, any:Client) //nightmare :-(, decides who gets the adrenaline
{
	if (secondsToGo <1)
	{
	new String:mapName[40];
	GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
	new String:charArr[5][5];
	ExplodeString(mapName, "_", charArr, 5, 5);
	new String:mapAbbriv[5];
	strcopy(mapAbbriv, 5, charArr[0]);
	
	if(strcmp(mapAbbriv, "c1m1") == 0)
	{
		
	}
	
	else if(strcmp(mapAbbriv, "c1m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m3") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m4") == 0){
		
	}
	else if(strcmp(mapAbbriv, "c2m1") == 0){	
		I_Safehouse[0] = -972.243103; 
		I_Safehouse[1] = -2466.048584;
		I_Safehouse[2] = -1083.968750;
		
		
	}else if(strcmp(mapAbbriv, "c2m2") == 0){		
		
		
		I_Safehouse[0] = -4325.750977; 
		I_Safehouse[1] = -5506.424805;
		I_Safehouse[2] = -63.968750;
		
	}else if(strcmp(mapAbbriv, "c2m3") == 0){
		
		I_Safehouse[0] = -4998.220703; 
		I_Safehouse[1] = 1655.154541;
		I_Safehouse[2] = 4.031250;	
		
	}else if(strcmp(mapAbbriv, "c2m4") == 0){
		
		I_Safehouse[0] = -2320.031250; 
		I_Safehouse[1] = 1583.968750;
		I_Safehouse[2] = -255.968750;
		
	}else if(strcmp(mapAbbriv, "c2m5") == 0){
		
	}else if(strcmp(mapAbbriv, "c3m1") == 0){
		
		I_Safehouse[0] = -2617.833740; 
		I_Safehouse[1] = 210.031250;
		I_Safehouse[2] = 56.031250;
		
	}else if(strcmp(mapAbbriv, "c3m2") == 0){
		
		I_Safehouse[0] = 7461.206055; 
		I_Safehouse[1] = -1072.968750;
		I_Safehouse[2] = 136.031250;
		
		
	}else if(strcmp(mapAbbriv, "c3m3") == 0){
		
		I_Safehouse[0] = 5211.968750; 
		I_Safehouse[1] = -3681.031250;
		I_Safehouse[2] = 350.761261;	
		
	}else if(strcmp(mapAbbriv, "c3m4") == 0){
		
		I_Safehouse[0] = 1667.572510; 
		I_Safehouse[1] = 2028.218750;
		I_Safehouse[2] = 123.556023;
		
		
	}else if(strcmp(mapAbbriv, "c4m1") == 0){
		
		I_Safehouse[0] = 4256.008301; 
		I_Safehouse[1] = -1439.968750;
		I_Safehouse[2] = 102.906593;
		
	}else if(strcmp(mapAbbriv, "c4m2") == 0){
		
		I_Safehouse[0] = -1886.968750; 
		I_Safehouse[1] = -13775.684570;
		I_Safehouse[2] = 130.281250;
		
	}else if(strcmp(mapAbbriv, "c4m3") == 0){
		
		I_Safehouse[0] = 3505.031250; 
		I_Safehouse[1] = -1585.031250;
		I_Safehouse[2] = 232.281250;
		
	}else if(strcmp(mapAbbriv, "c4m4") == 0){
		
		I_Safehouse[0] = -3415.968750; 
		I_Safehouse[1] = 8079.015137;
		I_Safehouse[2] = 148.689941;
		
	}else if(strcmp(mapAbbriv, "c4m5") == 0){
		
		I_Safehouse[0] = -7155.699707; 
		I_Safehouse[1] = 7721.269531;
		I_Safehouse[2] = 142.031250;
		
	}else if(strcmp(mapAbbriv, "c5m1") == 0){
		
		I_Safehouse[0] = -3774.100342; 
		I_Safehouse[1] = -1224.571533;
		I_Safehouse[2] = -343.968750;	
		
	}else if(strcmp(mapAbbriv, "c5m2") == 0){
		
		I_Safehouse[0] = -9855.968750; 
		I_Safehouse[1] = -8175.968750;
		I_Safehouse[2] = -220.767731;	
		
	}else if(strcmp(mapAbbriv, "c5m3") == 0){
		
		I_Safehouse[0] = 7344.529785; 
		I_Safehouse[1] = -9648.046875;
		I_Safehouse[2] = 104.031250;	
		
	}else if(strcmp(mapAbbriv, "c5m4") == 0){
		
		I_Safehouse[0] = 1615.968750; 
		I_Safehouse[1] = -3703.968750;
		I_Safehouse[2] = 99.226280;	
		
		
	}else if(strcmp(mapAbbriv, "c5m5") == 0){
		
		I_Safehouse[0] = 9867.460938; 
		I_Safehouse[1] = 3299.714355;
		I_Safehouse[2] = 438.534576;		
		
	}else if(strcmp(mapAbbriv, "c6m1") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m3") == 0){
		
	}
	
	
	
	decl Float:TargetOrigin[3], Float:Distance;
	new clientIds[5];
	new distances[MAXPLAYERS + 1];
	new k;
	new l;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		GetClientOfUserId(i);
		if(IsClientInGame(i)) //&& !IsFakeClient(i) 
		{	
			clientIds[k] = i;
			k++;
			
			GetClientAbsOrigin(i, TargetOrigin);	
			Distance = GetVectorDistance(TargetOrigin, I_Safehouse)
			l++;
			distances[l] = Distance;
		}
		
	}
	
	decl players[MAXPLAYERS][2], i 
	new playercount 
	
	for(i = 1; i <= MaxClients; i++) 
	{ 
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==2) //&& !IsFakeClient(i)  re-add after testing
		{ 
			players[playercount][0] = i 
			players[playercount++][1] = distances[i] 
		} 
	} 
	
	SortCustom2D(players,playercount,SortPlayerPoints) 
	
	for(i = 0; i < playercount; i++) 
	{	
		
		//PrintToChatAll("i is = to %N ",i) 	
		
		//PrintToChatAll("Rank #%d: %N with %f distance",i+1,players[i][0],players[i][1]) //TELLS YOUR WHERE EACH PLAYER IS AT EG 1st, 2nd
		
		
		if(inc==0)
		{
			
				if (secondsToGo_two <GetConVarInt(L4d2_how_often_adr_4th_player)+1 && secondsToGo_two >GetConVarInt(L4d2_how_often_adr_4th_player)-1 )
				{	
				if (GetConVarInt(L4d2_how_often_adr_4th_player) >60)
				{
				inc=1;
				}
				else
				{
				//This is 4th player!!
				adrenaline(players[i][0]);
				
				if(L4d2_how_kill_adr_4th_player != INVALID_HANDLE)
				{
				KillTimer(L4d2_how_kill_adr_4th_player);
				L4d2_how_kill_adr_4th_player = INVALID_HANDLE;
				//PrintToChatAll("timer 1 killed")
				}
				L4d2_how_kill_adr_4th_player=CreateTimer(GetConVarInt(L4d2_how_often_adr_4th_player)* 1.0, give_adren, players[i][0], TIMER_REPEAT)
				
				inc=1;
				//PrintToChatAll("20 seconds for adren secondstogo_two 20 %N ",players[i][0]) 
				}
			}
		}
		
		if(inc==1)
		{
			
			if (secondsToGo_two <GetConVarInt(L4d2_how_often_adr_3rd_player)+1 && secondsToGo_two >GetConVarInt(L4d2_how_often_adr_3rd_player)-1 )
			{	
				
				if (GetConVarInt(L4d2_how_often_adr_3rd_player) >60)
				{
				inc=2;
				}
				else
				{
				i++;
				//This is 3rd player!! 
				adrenaline(players[i][0]);
				//PrintToChatAll("30 seconds for adren secondstogo_two 30 %N ",players[i][0]) 
				
				if(L4d2_how_kill_adr_3rd_player != INVALID_HANDLE)
				{
				KillTimer(L4d2_how_kill_adr_3rd_player);
				L4d2_how_kill_adr_3rd_player = INVALID_HANDLE;
				//PrintToChatAll("timer 2 killed") 
				}
				L4d2_how_kill_adr_3rd_player=CreateTimer(GetConVarInt(L4d2_how_often_adr_3rd_player)* 1.0, give_adren_two, players[i][0], TIMER_REPEAT)
				inc=2;
				}
			}
		}
		
		if(inc==2)
		{
			if (secondsToGo_two <GetConVarInt(L4d2_how_often_adr_2nd_player)+1 && secondsToGo_two >GetConVarInt(L4d2_how_often_adr_2nd_player)-1 )
			{	
			
				if (GetConVarInt(L4d2_how_often_adr_2nd_player) >60)
				{
				inc=3;
				}
				else
				{
				i++;
				i++;
				
				//PrintToChatAll("45 seconds for %N ",players[i][0]) 
				//This is 2nd player!!	
				adrenaline(players[i][0]);
				if(L4d2_how_kill_adr_2nd_player != INVALID_HANDLE)
				{
				KillTimer(L4d2_how_kill_adr_2nd_player);
				L4d2_how_kill_adr_2nd_player = INVALID_HANDLE;
				//PrintToChatAll("timer 3 killed")
				}
				L4d2_how_kill_adr_2nd_player=CreateTimer(GetConVarInt(L4d2_how_often_adr_2nd_player)* 1.0, give_adren_three, players[i][0], TIMER_REPEAT)
				inc=3;
				}
			}
		}
		
		
		
		if(inc==3)
		{
			
			if (secondsToGo_two <GetConVarInt(L4d2_how_often_adr_1st_player)+1 && secondsToGo_two >GetConVarInt(L4d2_how_often_adr_1st_player)-1 )
			{	

				if (GetConVarInt(L4d2_how_often_adr_1st_player) >60)
				{
				inc=0;
				secondsToGo_two =0;
				}
				else
				{
				i++;
				i++;
				i++;
				secondsToGo_two =0;
				
				//PrintToChatAll("60 seconds for %N ",players[i][0]) 
				//This is 1st player!!
				adrenaline(players[i][0]);
				
				if(L4d2_how_kill_adr_1st_player != INVALID_HANDLE)
				{
				KillTimer(L4d2_how_kill_adr_1st_player);
				L4d2_how_kill_adr_1st_player = INVALID_HANDLE;
				//PrintToChatAll("timer 4 killed")
				}
				L4d2_how_kill_adr_1st_player=CreateTimer(GetConVarInt(L4d2_how_often_adr_1st_player)* 1.0, give_adren_four, players[i][0], TIMER_REPEAT)
				inc=0;
				}
			}
		}

	}
	
	secondsToGo_two ++;
	//PrintHintTextToAll("countdown %i ", secondsToGo_two);
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

public Action:Spawn_em(Handle:timer)
{
if(secondsToGo >1)
		{	
	for (new i=1 ; i<=MaxClients ; i++)
	{
	
	if(IsClientInGame(i) && GetClientTeam(i)==3 && !IsPlayerAlive(i) && !IsFakeClient(i))
	{
		CheatCommands (i, "z_spawn", "jockey auto");
		return;
	}
	}
	}
}


public Action:votestart(client, args)
{
if(secondsToGo<30) return;
DoVoteMenu()

}

public Action:check_votes(Handle:timer)
{
	if(yesVote>noVote)
	{
		ServerCommand("raceon");
		PrintHintTextToAll("Vote Passed!")
		PrintToChatAll("\x04Race \x04starting in \x0330 seconds")
	}
	if(yesVote<noVote)
	{
		PrintHintTextToAll("Vote failed!")
		//PrintHintTextToAll("Voted YES:%i and NO:%i",yesVote, noVote)
		PrintToChatAll("\x04Menu returning within \x0330 seconds")
		
	}
	if(yesVote==noVote)
	{
		PrintHintTextToAll("Vote failed!")
		PrintToChatAll("\x04Equal votes repeat in \x0330 seconds")
		
	}

}

public Action:StartVote(Handle:timer)
{
	if(secondsToGo<30) return;
	yesVote=0;
	noVote=0;
	DoVoteMenu()
	CreateTimer(20.0, check_votes);
}

DoVoteMenu()
{
	if(secondsToGo<30) return;
	if (IsVoteInProgress())
	{
		return;
	}
	
	new Handle:menu = CreateMenu(Handle_VoteMenu)
	SetMenuTitle(menu, "Are you ready to begin the JOCKEY RACE?")
	AddMenuItem(menu, "yes", "Yes")
	AddMenuItem(menu, "no", "No, team isn't full yet")
	SetMenuExitButton(menu, false)
	VoteMenuToAll(menu, 20);
	for(new i=1;i<=MaxClients;i++)
	{
	if(IsClientInGame(i) && GetClientTeam(i)==3)
	{
	PrintHintText(i, "<------------VOTE");
	}
	}
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		CloseHandle(menu);
	} else if (action == MenuAction_VoteEnd) {
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
			yesVote++;
		}
		
		if (param1 == 1)
		{
			noVote++;
		}
	}
}

public Action:Remove_melee(Handle:timer)
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{	
		new EntCount = GetEntityCount();
		new String:EdictName[128];	
		
		
		for (new i = 0; i <= EntCount; i++)
		{
			if (IsValidEntity(i))
			{
				GetEdictClassname(i, EdictName, sizeof(EdictName));
				
				if (StrContains(EdictName, "weapon_chainsaw", false) != -1||
				StrContains(EdictName, "weapon_melee_spawn", false) != -1)
				{	
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
		}
	}
}	



public Action:kill_infected(Handle:timer)
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{	
		SetConVarInt(FindConVar("z_health"), 1);
		SetConVarInt(FindConVar("z_speed"), 0);
		SetConVarInt(FindConVar("sv_alltalk"), 1);
		SetConVarInt(FindConVar("z_walk_speed"), 0);
		SetConVarInt(FindConVar("god"), 1);
		SetConVarInt(FindConVar("director_no_mobs"), 1);
		SetConVarInt(FindConVar("director_no_bosses"), 1);
		SetConVarInt(FindConVar("director_no_specials"), 1);
		SetConVarInt(FindConVar("z_common_limit"), 0);
		SetConVarInt(FindConVar("z_mega_mob_size"), 1);	
		SetConVarInt(FindConVar("versus_tank_chance_intro"), 0);
		SetConVarInt(FindConVar("versus_tank_chance_finale"), 0);
		SetConVarInt(FindConVar("versus_tank_chance"), 0);
		SetConVarInt(FindConVar("director_tank_lottery_entry_time"), 5000);//ensures no1 gets tank
		SetConVarInt(FindConVar("director_tank_lottery_selection_time"), 5000);//ensures no1 gets tank
		SetConVarInt(FindConVar("z_burning_lifetime"), 5000);
		SetConVarFloat(FindConVar("z_leap_interval_post_ride"), 0.8);
		SetConVarInt(FindConVar("sb_all_bot_team"), 1);
		SetConVarFloat(FindConVar("z_jockey_control_min"), 0.5);//GIVES players = control
		SetConVarFloat(FindConVar("z_jockey_control_max"), 0.5);//GIVES players = control also return sb_stop
		SetConVarInt(FindConVar("sb_stop"), 1);//return to 1 after vector madness	
		SetConVarInt(FindConVar("z_jockey_health"), 50000);	
		
		
		
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
					
					else if(StrContains(ModelName, "jockey.mdl", true) != -1)
					
					{
						
					}

					else if(StrContains(ModelName, "hulk.mdl", true) != -1 ||
					StrContains(ModelName, "spitter.mdl", true) != -1 ||
					StrContains(ModelName, "smoker.mdl", true) != -1  ||
					StrContains(ModelName, "hunter.mdl", true) != -1  ||
					StrContains(ModelName, "boomer.mdl", true) != -1 ||
					StrContains(ModelName, "boomette.mdl", true) != -1 ||
					StrContains(ModelName, "charger.mdl", true) != -1)
					{
						if(IsFakeClient(i))
						{
							ForcePlayerSuicide(i);
						}
					}
					
					else
					{
						RemoveEdict(i);
					}
					
				}
				

			}
		}
		
	}
}
public Action:Timer_Notify(Handle:Timer, any:client)
{
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		if (GetConVarInt(L4d2_Jockey_racing_broadcast))
		{
			
			
			if (GetConVarInt(L4d2_drug_boost_on))
			{
				
				
				PrintToChat(client, "\x01\x03-------------------------------------------------");
				PrintToChat(client, "\x01\x03WELCOME, \x04THIS IS A \x03JOCKEY RACING \x04SERVER!");
				PrintToChat(client, "\x01\x04-------------------------------------------------");
				PrintToChat(client, "\x01\x03Type \x04!mod if you \x03don't know \x04what's going on!");
				
				PrintHintText(client, "WELCOME TO JOCKEY RACING!\nType !mod(in chat) if you don't know what's going on!");
				
				
				//PrintHintText(client, "In this server, using the Adrenaline (or Pills) will turn sprint mode on");
				
				
			}
		}
	}
	return Plugin_Stop
}














public Action:Event_Player_Use(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	
	
	//	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Entity = GetEventInt(event, "targetid");
	
	if(IsValidEntity(Entity) && (SafetyLock == UNLOCK))
	{
		new String:entname[MAXLENGTH];
		if(GetEdictClassname(Entity, entname, sizeof(entname)))
		{
			/* Saferoom door */
			if(StrEqual(entname, "prop_door_rotating_checkpoint"))
			{	
				if (secondsToGo<1)
				{
					if (Player_count == Player_count_two)
					{
						SafetyLock = UNLOCK;
						ControlDoor(Entity, UNLOCK);
						//PrintToChatAll("if occurred all players are should be in the saferoom?");
					}
					else
					{
						AcceptEntityInput(Entity, "Lock");//stops players from closing the door on each other during race
						SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", LOCK);
						//PrintToChatAll("ELSE occurred door should be locked");
					}
				}
			}
		}
	}
	
}




public Action:resetScore(client,args)
{
	for(new i=0;i<8;i++) {
		score[i]=0;
		clientId[i]=0;
	}
	PrintToChatAll("[Jockey RaceMod] Scores reset");
	return Plugin_Handled;
}

public Action:chatCMD(client,args)
{
	if(GetConVarInt(Gamemode_jockey_racing) > 0)
	{
		reportScores(client);
	}
	else {
		PrintToChatAll("[Jockey RaceMod] ##(de)BUG## Gamemode_jockey_racing <= 0!");
	}
	return Plugin_Handled;
}

public Action:Event_PlayerWin(Handle:event, const String:name[], bool:dontBroadcast) //give the player a score.
{
	if(GetConVarInt(Gamemode_jockey_racing) > 0)
	{
		new playerId = GetEventInt(event, "userid");
		new player = GetClientOfUserId(playerId);
		
		if(player != 0) //if the player is not an npc
		{
			if(IsClientInGame(player) && GetClientTeam(player) != 0) //someone in team reached the finish line
			{
				new String:steamid[64]
				GetClientAuthString(player, steamid, 64);
				if (strcmp(steamid,"BOT") != 0) {
					new vec[3];
					GetClientAbsOrigin(player, Float:vec);
					new posX = RoundToCeil(Float:vec[0]);
					new posY = RoundToCeil(Float:vec[1]);
					new posZ = RoundToCeil(Float:vec[2]);
					//make sure that this event was called when the survivor made it to the safe room at the end of the level, because start safe rooms call this event too.
					if(posX > safeRoomArea[mapNum][0] && posX < safeRoomArea[mapNum][1] && posY > safeRoomArea[mapNum][2] && posY < safeRoomArea[mapNum][3] && posZ > safeRoomArea[mapNum][4] && posZ < safeRoomArea[mapNum][5])
					{
						#if DEBUG
						PrintToChatAll("[Jockey RaceMod] A player has won.");
						#endif	
						
						//check if player entered safe room for the first time.
						new awardPoints = true;
						for(new i=0; i<8; i++)
						{
							if(finishId[i] == GetClientSerial(player))
							{
								awardPoints = false;
								
								#if	DEBUG
								PrintToChatAll("[Jockey RaceMod] player's team has already finished.");
								#endif	
							}
						}
						
						//award points...
						if(awardPoints)
						{
							new pointsToAdd = award[place];
							new totalPoints;
							new String:plName[40];
							GetClientName(player, plName, sizeof(plName)); 
							
							//find the right player and give them points.
							for(new i=0; i<8; i++)
							{
								if(GetClientSerial(player) == clientId[i])
								{
									totalPoints = score[i]+pointsToAdd;
									score[i] = totalPoints;
									i=10;
								}
								else if ( i == 7 ) {
									for(new k=0;k<8;k++) {
										if (GetClientFromSerial(clientId[k]) == 0) { //If something goes wrong it has to be this if.
											totalPoints = pointsToAdd;
											score[k] = totalPoints;
											clientId[k] = GetClientSerial(player);
											k=10;
										}
									}
									i=10;
								}
							}
							finishId[place] = GetClientSerial(player); //record down that player has finished.
							
							
							
							
							if (place == 1 || place == 0) 
							{
								
								
								if (minutes_counter<1)
								{	
									PrintToChatAll("\x04%N finished \x031st \x04in \x03%i seconds \x04and earned \x03%i points. \x04Total points: \x03%i",player,race_timer, pointsToAdd, totalPoints);
									PrintHintText(player, "Your TEAM WON");	
									Player_count_two++;
									CreateTimer(3.0, Kill_remaining_jockey, player);
									check_count();
								}
								else
								{
									PrintToChatAll("\x04%N finished \x031st \x04in \x03 %i minute(s) \x04and\x03 %i second(s) \x04and earned \x03%i points. \x04Total points: \x03%i",player,minutes_counter,race_timer, pointsToAdd, totalPoints);
									PrintHintText(player, "Your TEAM WON");
									Player_count_two++;
									CreateTimer(3.0, Kill_remaining_jockey, player);	
									check_count();
								}	
							}
							
							else if(place == 3 || place == 2) 
							{
								
								if (minutes_counter<1){
									PrintHintText(player, "Your TEAM GOT 2ND PLACE");
									PrintToChatAll( "\x04%N finished \x032nd \x04and earned \x03%i points. \x04Total points: \x03%i",player, pointsToAdd, totalPoints);
									Player_count_two++;
									CreateTimer(3.0, Kill_remaining_jockey, player);
									check_count();
								}
								else
								{
									PrintToChatAll("\x04%N finished \x032nd \x04in \x03 %i minute(s) \x04and\x03 %i second(s) \x04and earned \x03%i points. \x04Total points: \x03%i",player,minutes_counter,race_timer, pointsToAdd, totalPoints);
									PrintHintText(player, "Your TEAM GOT 2ND PLACE");
									Player_count_two++;
									CreateTimer(3.0, Kill_remaining_jockey, player);
									check_count();
								}
								
								
							} 
							else if(place == 5 || place == 4) 
							{
								
								if (minutes_counter<1)
								{
									PrintHintText(player, "Your TEAM GOT 3RD PLACE");
									PrintToChatAll( "\x04%N finished \x033rd \x04and earned \x03%i points. \x04Total points: \x03%i",player, pointsToAdd, totalPoints);
									Player_count_two++;
									CreateTimer(3.0, Kill_remaining_jockey, player);
									check_count();
								}
								else
								{
									PrintToChatAll("\x04%N finished \x033rd \x04in \x03 %i minute(s) \x04and\x03 %i second(s) \x04and earned \x03%i points. \x04Total points: \x03%i",player,minutes_counter,race_timer, pointsToAdd, totalPoints);
									PrintHintText(player, "Your TEAM GOT 3RD PLACE");	
									Player_count_two++;
									CreateTimer(3.0, Kill_remaining_jockey, player);
									check_count();
								}
								
								
							}
							else if(place	== 7 || place == 6) 
							{
								
								if (minutes_counter<1)
								{
									PrintHintText(player, "Your TEAM GOT 4TH PLACE");
									PrintToChatAll( "\x04%N finished \x03last \x04and earned \x03%i points. \x04Total points: \x03%i",player, pointsToAdd, totalPoints);
									Player_count_two++;
									CreateTimer(3.0, Kill_remaining_jockey	);
									check_count();
								}
								
								else
								{
									PrintToChatAll("\x04%N finished \x03last \x04in \x03 %i minute(s) \x04and\x03 %i second(s) \x04and earned \x03%i points. \x04Total points: \x03%i",player,minutes_counter,race_timer, pointsToAdd, totalPoints);
									PrintHintText(player, "Your TEAM GOT 4TH PLACE");	
									Player_count_two++;
									CreateTimer(3.0, Kill_remaining_jockey	);	
									check_count();
								}
								
							}
							
							
							place++;
							stillRacing--;
							if(stillRacing < 1)
							{
								reportScores(0);	
							}
						}
					}
				}
			}
		}
		#if DEBUG
		PrintToChatAll("[Jockey RaceMod] Event_PlayerWin id: %i", player);
		#endif	
	}
	
	return Plugin_Continue;
}


check_count()
{
	if (Player_count==Player_count_two)
	{
		
		//PrintToChatAll("contition met USE is now enabled");
	}
	else
	PrintToChatAll("use still disabled, not all players have entered the saferoom");
	
}

public Action:Kill_remaining_jockey(Handle:timer, any:player)
{
	
	// We check if player is in game
	if (IsClientInGame(player) && (GetClientTeam(player)==3))
	{
		ForcePlayerSuicide(player);
	}
	
}

public Action:reportScores(const client) //report the scores in order. if client is not 0 then a player asked to have it printed to them
{
	if(client == 0) {
		//PrintToChatAll("[Jockey RaceMod] End of round has been reached.");
	}
	//PrintToChatAll("[Jockey RaceMod] ##DEBUG## Sorting"); 
	
	//initiate buble sort
	new sort = 1;
	new temp1;
	new temp2;
	while(sort==1){
		sort = 0;
		for(new i=0; i<7; i++){
			if(score[i] < score[i+1]){
				temp1 = score[i];
				temp2 = clientId[i];
				score[i] = score[i+1];
				clientId[i] = clientId[i+1];
				score[i+1] = temp1;
				clientId[i+1] = temp2;
				sort = 1;
			}
		}
	}	
	//PrintToChatAll("[Jockey RaceMod] ##DEBUG## Sorted"); 
	new String:cName[40];
	
	
	//make sure the clientid matches the same person's score and name.
	new k=1;
	for(new i=0; k<=7 && i<8; i++) //show list of max 7 players, excluding the last one, or just go thru all players..
	{	
		//PrintToChatAll("[Jockey RaceMod] ##DEBUG## %i in list", i); 
		if(GetClientFromSerial(clientId[i])!=0 && IsClientInGame(GetClientFromSerial(clientId[i])))
		{
			//PrintToChatAll("[Jockey RaceMod] ##DEBUG## found a playa, getting naem, %i", i); 
			
			GetClientName(GetClientFromSerial(clientId[i]), cName, sizeof(cName));
			if(k == 1){
				PrintToChatAll("\x031st \x04place: \x03%s \x04with \x03%i points.", cName, score[i]);
			}else if(k == 2){
				PrintToChatAll("\x032nd \x04place: \x03%s \x04with \x03%i points.", cName, score[i]);
			}else if(k == 3){
				PrintToChatAll("\x033rd \x04place: \x03%s \x04with \x03%i points.", cName, score[i]);
			}else if(k >= 4){
				PrintToChatAll("\x03%ith \x04place: \x03%s \x04with \x03%i points.", k, cName, score[i]);
			}
			k++;
		}
	}
}

public Action:warn_players(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i)!=1)
		{
			PrintToChat(i,"\x03Welcome to the \x04Finale, only \x03ONE TEAM is allowed in \x04the rescue vehicle");
		}
		
		
	}
	
}

public Action:checkPlayerPos(Handle:timer, any:client)
{
	if(GetConVarInt(Gamemode_jockey_racing) > 0)
	{
		for(new player=1; player<=MaxClients; player++) //find everyone's client id.
		{
			if(IsClientInGame(player) && GetClientTeam(player) != 0) //a survivor reached the finish line
			{
				new vec[3];
				GetClientAbsOrigin(player, Float:vec);
				new posX = RoundToCeil(Float:vec[0]);
				new posY = RoundToCeil(Float:vec[1]);
				new posZ = RoundToCeil(Float:vec[2]);
				//make sure that this event was called when the survivor made it to the safe room at the end of the level, because start safe rooms call this event too.
				if(posX > safeRoomArea[mapNum][0] && posX < safeRoomArea[mapNum][1] && posY > safeRoomArea[mapNum][2] && posY < safeRoomArea[mapNum][3] && posZ > safeRoomArea[mapNum][4] && posZ < safeRoomArea[mapNum][5])
				{
					#if DEBUG
					PrintToChatAll("[Jockey RaceMod] A player has won.");
					#endif	
					
					//check if player entered safe room for the first time.
					new awardPoints = true;
					for(new i=0; i<8; i++)
					{
						if(finishId[i] == GetClientSerial(player))
						{
							awardPoints = false;
							
							#if	DEBUG
							PrintToChatAll("[Jockey RaceMod] player has already finished.");
							#endif	
						}
					}
					
					//award points...
					if(awardPoints)
					{
						new pointsToAdd = award[place];
						new totalPoints;
						new String:plName[40];
						GetClientName(player, plName, sizeof(plName)); 
						
						//find the right player and give them points.
						for(new i=0; i<8; i++)
						{
							if(clientId[i] == GetClientSerial(player))
							{
								totalPoints = score[i]+pointsToAdd;
								score[i] = totalPoints;
							}	
						}
						finishId[place] = GetClientSerial(player); //record down that player has finished.
						
						if (minutes_counter<1)
						{
							
							PrintToChatAll("\x04%N finished \x031st \x04in \x03%i seconds \x04and earned \x03%i points. \x04Total points: \x03%i",player,race_timer, pointsToAdd, totalPoints);
							PrintHintText(player, "Your TEAM WON");
						}
						else
						{
							
							PrintToChatAll("\x04%N finished \x031st \x04in \x03 %i minute(s) \x04and\x03 %i second(s) \x04and earned \x03%i points. \x04Total points: \x03%i",player,minutes_counter,race_timer, pointsToAdd, totalPoints);
							PrintHintText(player, "Your TEAM WON");
						}
						
						
						place++;
						stillRacing--;
						if(stillRacing < 1)
						{
							reportScores(0);	
						}
						//CreateTimer(1.0, Killall_except_winners, plName);  // to be finished!!!!!
					}
				}
			}
		}
	}
	if(mapNum == 22){
		return Plugin_Continue;
	}else{
		return Plugin_Stop;
	}
}

public Action:Event_FinaleOver(Handle:event, const String:name[], bool:dontBroadcast) //the finale round is over, award survivors final points and report the winners.
{
	if(GetConVarInt(Gamemode_jockey_racing) > 0)
	{
		
		reportScores(0);
	}
	
	return Plugin_Continue;	
}

stock paint_humans(client)
{
	
	//PrintToChatAll("human SPRAYING STARTED");
	
	new clientIds[5];
	
	new k=0;
	
	for(new i=1; i<=MaxClients; i++)
	{
		//client = GetClientOfUserId(i);
		
		
		
		if(IsClientInGame(i))
		{
			if(GetClientTeam(i) == 2){  //is client on survivors team
				
				clientIds[k] = i;
				
				k++;
				
				//PrintToChatAll("cycling through players====>%N",k);
				
				
			}
		}
		
		
	}
	
	
	teleport_humans(clientIds[0]);//grEEN HUMAN
	
	teleport_humans_two(clientIds[1]);//RED HUMAN 
	
	teleport_humans_three(clientIds[2]);//YELLOW HUMAN
	
	teleport_humans_four(clientIds[3]);//BLACK HUMAN
	
	
	
	CreateTimer(1.0, spray_four_human, clientIds[0])//GREEN//MADE TIMERS A ONE OFF INSTEAD OF REPEAT NO REASON NOT TO
	
	CreateTimer(1.0, spray_three_human, clientIds[1])//RED 
	
	CreateTimer(1.0, spray_one_human, clientIds[2])//YELLOW
	
	CreateTimer(1.0, spray_two_human, clientIds[3])//BLACK
	
	
	PrintToChat(clientIds[0],"\x01\x03YOU ARE ON THE GREEN \x04TEAM, \x03RACE WITH YOUR JOCKEY TO THE \x04SAFEHOUSE!");
	
	PrintToChat(clientIds[1],"\x01\x03YOU ARE ON THE RED \x04TEAM, \x03RACE WITH YOUR JOCKEY TO THE \x04SAFEHOUSE!");
	
	PrintToChat(clientIds[2],"\x01\x03YOU ARE ON THE YELLOW \x04TEAM, \x03RACE WITH YOUR JOCKEY TO THE \x04SAFEHOUSE!");
	
	PrintToChat(clientIds[3],"\x01\x03YOU ARE ON THE BLACK \x04TEAM, \x03RACE WITH YOUR JOCKEY TO THE \x04SAFEHOUSE!");
	
	
	
}

public Action:give_adren(Handle:timer, any:client)
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		if(secondsToGo <1)
		{
		adrenaline(client);
		}
		
	}
}

public Action:give_adren_two(Handle:timer, any:client)
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{	
		if(secondsToGo <1)
			{
			adrenaline(client);
			}
		
	}
}

public Action:give_adren_three(Handle:timer, any:client)
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{

			adrenaline(client);
			

	}
}

public Action:give_adren_four(Handle:timer, any:client)
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{

			adrenaline(client);
			//PrintToChatAll("give_adren_four running")
			
	}
}

public Action:give_grenade(Handle:timer)
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		if(	GetConVarInt(l4d_allow_grenade)>0)
		{
			if(secondsToGo <1)
			{
				grenade();
				CreateTimer(GetConVarInt(L4d2_how_often_grenade) - 2.0, remove_grenade )
			}
			
		}
	}
}
public grenade()
{
	if(	GetConVarInt(l4d_allow_grenade)>0)
	{
		new flags = GetCommandFlags("give");	
		SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
		
		for (new i = 1; i <= MaxClients; i++)
		{
			
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				if(IncapType[i]== INCAP_RIDE)
				{
					new b= GetRandomInt(1,2)
					if (b ==1)
					{
						FakeClientCommand(i, "give molotov");//change back to molotov
						PrintToChat(i, "\x01\x04 You have a \x03MOLOTOV aim UP and\x04(MOUSE1)\x03 to throw it at \x03other teams");
					}	
					if (b ==2)
					{
						FakeClientCommand(i, "give vomitjar");
						PrintToChat(i, "\x01\x04 You have \x03BOOMER BILE aim UP and\x04(MOUSE1)\x03 to throw it at \x03other teams");
					}
					
					if (GetGrenadeOnIncap(i) > 0)
					{
						switch (GetConVarInt(h_CvarMessageType))
						{
							case 1: PrintToChat(i, "\x03Press Mouse1(shoot) to throw a grenade at other teams")
							case 2: PrintHintText(i, "Press Mouse1(shoot) to throw a grenade at other teams")
						}
					}
				}	
			}	
		}
		
		SetCommandFlags("give", flags|FCVAR_CHEAT);	
	}
	
}



public adrenaline(client)
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{
	
		new flags = GetCommandFlags("give");	
		SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
		
		//if(IncapType[client]== INCAP_RIDE)
		//{
		
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			FakeClientCommand(client, "give adrenaline");
			CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, client);	
			
			PrintHintText(client, "\x04 You have adrenaline HOLD E (USE) or (CTRL) to INJECT it with the JOCKEY");
			
		}
	//	}
		
		SetCommandFlags("give", flags|FCVAR_CHEAT);
	}
		
	
}

public Action:remove_adren(Handle:timer, any:client)//reduce adrenaline spam on the floors
{	
	decl String:weapon[32];
	new Adrens=GetPlayerWeaponSlot(client, 4);
	
	if(Adrens !=-1)
	{
		GetEdictClassname(Adrens, weapon, 32);
		if(StrEqual(weapon, "weapon_adrenaline"))
		{
			AcceptEntityInput(Adrens, "Kill");
		}
	}
	
	
}


/* ***************************************************************************/
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(GetConVarInt(Gamemode_jockey_racing))
	{
		secondsToGo = 30;
		new EntCount = GetEntityCount();
		new String:EdictName[128];
		for (new i = 0; i <= EntCount; i++)
		{
			if (IsValidEntity(i))
			{
				GetEdictClassname(i, EdictName, sizeof(EdictName));
				
				if (StrContains(EdictName, "func_button", false) != -1)
				{
					AcceptEntityInput(i, "Press"); //Push ALL buttons in chapter:) 
					continue;
				}
				
				
				if (StrContains(EdictName, "prop_door_rotating_checkpoint", false) != -1)
				{
					AcceptEntityInput(i, "Open"); //uncomment and fix
					AcceptEntityInput(i, "Lock");//stops players from closing the door on each other during race
					SetEntProp(i, Prop_Data, "m_hasUnlockSequence", LOCK);
					continue;
				}
				
				else if (StrContains(EdictName, "prop_door_rotating", false) != -1)
				{
					AcceptEntityInput(i, "Kill"); //remove all non safehouse doors
				}
				
			}    
		}
		
		new String:mapName[40];
		GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
		
		
		
		//single out the 4 characters of the mapname
		new String:charArr[5][5];
		ExplodeString(mapName, "_", charArr, 5, 5);
		new String:mapAbbriv[5];
		strcopy(mapAbbriv, 5, charArr[0]);
		
		
		
		if(strcmp(mapAbbriv, "c1m1") == 0){
			
			mapNum = 0;	
		}else if(strcmp(mapAbbriv, "c1m2") == 0){
			mapNum = 1;	
		}else if(strcmp(mapAbbriv, "c1m3") == 0){
			mapNum = 2;	
		}else if(strcmp(mapAbbriv, "c1m4") == 0){
			mapNum = 3;	
		}else if(strcmp(mapAbbriv, "c2m1") == 0){
			
			mapNum = 4;	
		}else if(strcmp(mapAbbriv, "c2m2") == 0){
			mapNum = 5;	
		}else if(strcmp(mapAbbriv, "c2m3") == 0){
			mapNum = 6;	
		}else if(strcmp(mapAbbriv, "c2m4") == 0){
			mapNum = 7;	
		}else if(strcmp(mapAbbriv, "c2m5") == 0){
			mapNum = 8;	
			
		}else if(strcmp(mapAbbriv, "c3m1") == 0){
			
			mapNum = 9;	
		}else if(strcmp(mapAbbriv, "c3m2") == 0){
			mapNum = 10;	
		}else if(strcmp(mapAbbriv, "c3m3") == 0){
			mapNum = 11;	
		}else if(strcmp(mapAbbriv, "c3m4") == 0){
			mapNum = 12;
			
		}else if(strcmp(mapAbbriv, "c4m1") == 0){
			
			mapNum = 13;	
		}else if(strcmp(mapAbbriv, "c4m2") == 0){
			mapNum = 14;	
		}else if(strcmp(mapAbbriv, "c4m3") == 0){
			mapNum = 15;	
		}else if(strcmp(mapAbbriv, "c4m4") == 0){
			mapNum = 16;	
		}else if(strcmp(mapAbbriv, "c4m5") == 0){
			mapNum = 17;
			
		}else if(strcmp(mapAbbriv, "c5m1") == 0){
			
			mapNum = 18;	
		}else if(strcmp(mapAbbriv, "c5m2") == 0){
			mapNum = 19;	
		}else if(strcmp(mapAbbriv, "c5m3") == 0){
			mapNum = 20;	
		}else if(strcmp(mapAbbriv, "c5m4") == 0){
			mapNum = 21;	
		}else if(strcmp(mapAbbriv, "c5m5") == 0){
			mapNum = 22;
			
			CreateTimer(0.5, checkPlayerPos, _, TIMER_REPEAT); //bridge race
		}else if(strcmp(mapAbbriv, "c6m1") == 0){
			
			mapNum = 23;	
		}else if(strcmp(mapAbbriv, "c6m2") == 0){
			mapNum = 24;	
		}else if(strcmp(mapAbbriv, "c6m3") == 0){
			mapNum = 25;
			
		}
		
		//set vars
		for(new i=0; i<8; i++){
			finishId[i] = 0;
		}
		stillRacing = 8;
		place = 0;
		
		
		
		KillTimer(h_Final_time);
		h_Final_time = INVALID_HANDLE;	
		reset();
	}
	
	
	
	
	
	
}

public Action:tankspawn(client,args)
{
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		new flags = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "z_spawn tank");
		SetCommandFlags("z_spawn", flags);
		return;
	}
}

public Action:jockeyspawn(client,args)//used for testing of adrenaline
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		new flags = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "z_spawn jockey");
		SetCommandFlags("z_spawn", flags);
		return;
	}
}

public Action:defibrilator(client,args)
{
	CreateTimer(1.0, Bile_effect, client)
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	FakeClientCommand(client, "give defibrillator");   
	SetCommandFlags("give", flags|FCVAR_CHEAT);        
}

public Action:spray_one_human(Handle:timer, any:client)
{
	
	if (GetClientTeam(client)==TEAM_SURVIVORS)
	{
		if(IsPlayerAlive(client))
		{
			//PrintToChat(client,"You have been painted YELLOW");
			Paint_human_one(client);
		}
		
	}

	
}

public Action:spray_two_human(Handle:timer, any:client)
{
	
	if (GetClientTeam(client)==TEAM_SURVIVORS)
	{
		if(IsPlayerAlive(client))
		{
			//PrintToChat(client,"You have been painted BLACK");
			
			Paint_human_two(client);
			
			
		}
		
	}
	
}

public Action:spray_three_human(Handle:timer, any:client)
{
	
	if (GetClientTeam(client)==TEAM_SURVIVORS)
	{
		if(IsPlayerAlive(client))
		{
			//PrintToChat(client,"You have been painted RED");
			
			Paint_human_three(client);
			
			
		}
		
	}
	
}

public Action:spray_four_human(Handle:timer, any:client)
{
	
	if (GetClientTeam(client)==TEAM_SURVIVORS)
	{
		if(IsPlayerAlive(client))
		{
			//PrintToChat(client,"You have been painted GREEN");
			
			Paint_human_four(client);
			
			
		}
		
	}
	
}


public Action:spray_one(Handle:timer, any:client)
{

	if (GetClientTeam(client)==TEAM_INFECTED)
	{
		if(IsPlayerAlive(client))
		{
			//PrintToChat(client,"You have been painted GREEN");
			
			Paint_one(client);
			
		}
	}
	
}

public Action:spray_two(Handle:timer, any:client)
{
	
	if (GetClientTeam(client)==TEAM_INFECTED)
	{
		
		if(IsPlayerAlive(client))
		{
			//PrintToChat(client,"You have been painted GREEN");
			Paint_two(client);
			
		}
		
	}
	
}

public Action:spray_three(Handle:timer, any:client)
{
	
	if (GetClientTeam(client)==TEAM_INFECTED)
	{
		if(IsPlayerAlive(client))
		{
			//PrintToChat(client,"You have been painted BLACK");
			Paint_three(client);
			
		}
		
	}
	
}

public Action:spray_four(Handle:timer, any:client)
{
	
	if (GetClientTeam(client)==TEAM_INFECTED)
	{
		if(IsPlayerAlive(client))
		{
			//PrintToChat(client,"You have been painted YELLOW");
			Paint_four(client);
			
		}
		
	}
	
}


public Action:OnPlayerRunCmd(i_Client, &i_Buttons, &i_Impulse, Float:f_Velocity[3], Float:f_Angles[3], &i_Weapon)
{
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		
		
		if (!IsClientConnected(i_Client)) return Plugin_Continue;
		if (!IsClientInGame(i_Client)) return Plugin_Continue;
		if (!IsPlayerAlive(i_Client)) return Plugin_Continue;
		
		
		if (secondsToGo >1 )
		{	
			
			if(i_Buttons & IN_ATTACK2) 
			{
				i_Buttons = i_Buttons & ~IN_ATTACK2;
			}
			
			if(i_Buttons & IN_ATTACK)
			{
				i_Buttons = i_Buttons & ~IN_ATTACK;
			}
			
			if(i_Buttons & IN_JUMP)
			{
				i_Buttons = i_Buttons & ~IN_JUMP;
			}
		}
		
		
		if(	GetConVarInt(l4d_allow_grenade)>0)
		{
			if (GetClientTeam (i_Client)!= 2) return Plugin_Continue;
			
			if(IncapType[i_Client]== INCAP_RIDE)
			{
				
				if (IsFakeClient(i_Client))
					return Plugin_Continue
				
				if (!g_b_AllowThrow[i_Client])
					return Plugin_Continue
				
				if(	GetConVarInt(l4d_allow_grenade)>0)
				{
					
					if (g_b_InAction[i_Client] && (i_Buttons & IN_ATTACK))
					{
						CreateTimer(0.5, freeze, i_Client);
						
						//SetEntDataFloat(i_Client, LagMovement, 0.4, true);
						
						decl i_Viewmodel
						
						i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
						g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 7) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 5)
						
						i_Buttons &= ~IN_FORWARD
						
						return Plugin_Continue
					}
					else if (g_b_InAction[i_Client])
					{
						g_b_InAction[i_Client] = false
						decl i_Viewmodel, i_Grenade
						
						i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
						
						SetEntPropFloat(i_Viewmodel, Prop_Send, "m_flLayerStartTime", GetGameTime())
						
						PlayScene(i_Client)
						
						switch (g_PlayerIncapacitated[i_Client])
						{
							case PIPEBOMB: ThrowPipebomb(i_Client)
							case MOLOTOV: ThrowMolotov(i_Client)
							case VOMITJAR: ThrowVomitjar(i_Client)
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
						case MOLOTOV: i_GrenadeType = g_MolotovModel
						case VOMITJAR: i_GrenadeType = g_VomitjarModel
					}
					
					//if (i_GrenadeType && !(i_Buttons & IN_FORWARD))//IMPORTANT
					if (i_GrenadeType )
					{
						decl i_Viewmodel, i_Model
						
						i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
						i_Model = GetEntProp(i_Viewmodel, Prop_Send, "m_nModelIndex")
						
						if (i_Model == i_GrenadeType)
							g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 3) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 1)
						
						if (i_Buttons & IN_ATTACK)
						{	
							SetEntProp(i_Viewmodel, Prop_Send, "m_nModelIndex", i_GrenadeType, 2)
							g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 3) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 1)
							g_PlayerGameTime[i_Client] = GetGameTime()
							
							if (i_Model != i_GrenadeType)
								return Plugin_Continue
							
							g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 7) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 5)
							SetEntPropFloat(i_Viewmodel, Prop_Send, "m_flLayerStartTime", GetGameTime())
							i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
							
							if (i_Weapon != -1)
								SetEntPropFloat(i_Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 100.0)
							
							g_b_InAction[i_Client] = true
							
							decl String:s_Sound[64]
							if (g_Mod == LEFT4DEAD)
							{
								FormatEx(s_Sound, sizeof(s_Sound), "^%s", SOUND_PISTOL)
								StopSound(i_Client, SNDCHAN_WEAPON, s_Sound)
							}
							else if (g_Mod == LEFT4DEAD2)
							{
								FormatEx(s_Sound, sizeof(s_Sound), ")%s", SOUND_PISTOL)
								StopSound(i_Client, SNDCHAN_WEAPON, s_Sound)
								StopSound(i_Client, SNDCHAN_WEAPON, SOUND_DUAL_PISTOL)
								StopSound(i_Client, SNDCHAN_WEAPON, SOUND_MAGNUM)
							}
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
								g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 3) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 1)
								g_PlayerGameTime[i_Client] = GetGameTime()
							}
							else
							{
								SetPlayerWeaponModel(i_Client, i_Weapon)
								g_PlayerGameTime[i_Client] = GetGameTime()
							}
						}
						
						
						
						else if (i_Buttons & IN_RELOAD)
						{
							if (i_Model == i_GrenadeType)
								i_Buttons &= ~IN_RELOAD
						}
						
					}	
				}
				
			}
		}
	}
	return Plugin_Continue
	
}

public Sub_IsPlayerGhost(any:Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isGhost"))
		return true;
	else
	return false;
}


public Action:freeze(Handle:timer, any:i_Client)
{
	SetEntDataFloat(i_Client, LagMovement, 1.0, true);
}

public Action:ReturnPistolDelay(Handle:h_Timer, any:i_Client)
{
	decl i_Viewmodel, i_Weapon
	
	if (!i_Client && !IsClientInGame(i_Client))
		return Plugin_Handled
	
	i_Viewmodel = GetEntPropEnt(i_Client, Prop_Send, "m_hViewModel")
	i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
	g_Mod == LEFT4DEAD ? SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 15) : SetEntProp(i_Viewmodel, Prop_Send, "m_nLayerSequence", 2)
	if (i_Weapon != -1)
		SetPlayerWeaponModel(i_Client, i_Weapon)
	SetEntPropFloat(i_Viewmodel, Prop_Send, "m_flLayerStartTime", GetGameTime())
	
	return Plugin_Continue
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

public PlayScene(i_Client)
{
	decl i_Ent, String:s_Model[128], String:s_SceneFile[32], i_Random
	
	GetEntPropString(i_Client, Prop_Data, "m_ModelName", s_Model, sizeof(s_Model))
	
	
	if (g_Mod == LEFT4DEAD2)
	{
		if (StrContains(s_Model, "gambler") != -1)
		{
			switch (g_PlayerIncapacitated[i_Client])
			{
				case PIPEBOMB:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoicePipebombNick)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/gambler/%s.vcd", g_VoicePipebombNick[i_Random])
				}
				case MOLOTOV:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceMolotovNick)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/gambler/%s.vcd", g_VoiceMolotovNick[i_Random])
				}
				case VOMITJAR:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceVomitjarNick)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/gambler/%s.vcd", g_VoiceVomitjarNick[i_Random])
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
				case MOLOTOV:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceMolotovCoach)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/coach/%s.vcd", g_VoiceMolotovCoach[i_Random])
				}
				case VOMITJAR:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceVomitjarCoach)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/coach/%s.vcd", g_VoiceVomitjarCoach[i_Random])
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
				case MOLOTOV:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceMolotovEllis)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/mechanic/%s.vcd", g_VoiceMolotovEllis[i_Random])
				}
				case VOMITJAR:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceVomitjarEllis)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/mechanic/%s.vcd", g_VoiceVomitjarEllis[i_Random])
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
				case MOLOTOV:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceMolotovRochelle)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/producer/%s.vcd", g_VoiceMolotovRochelle[i_Random])
				}
				case VOMITJAR:
				{
					i_Random = GetRandomInt(0, sizeof(g_VoiceVomitjarRochelle)-1)
					FormatEx(s_SceneFile, sizeof(s_SceneFile), "scenes/producer/%s.vcd", g_VoiceVomitjarRochelle[i_Random])
				}
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


stock GetRandomAngles(Float:f_Angles[3])
{
	f_Angles[0] = GetRandomFloat(-180.0, 180.0)
	f_Angles[1] = GetRandomFloat(-180.0, 180.0)
	f_Angles[2] = GetRandomFloat(-180.0, 180.0)
}


public Action:DeleteEntity(Handle:h_Timer, any:i_Ent)
{
	if (IsValidEntity(i_Ent))
		RemoveEdict(i_Ent)
}


public Action:Kill_survivor_bots(Handle:timer, any:client)
{
	if (GetConVarInt(l4d_kill_bot_survivors))
	{
		for (new i=1; i<=MaxClients; i++)
		{
			// We check if player is in game
			if (!IsClientInGame(i)) continue;
			
			// Check if client is infected ...
			if (GetClientTeam(i)==2 && IsFakeClient(i))
			{
				
				ForcePlayerSuicide(i);
				
			}
		}
	}
}


public Action:Count_players(Handle:timer, any:client)
{
	for (new i=1; i<=MaxClients; i++)
	{
		
		if (IsClientInGame(i) && GetClientTeam(i)!=1 && !IsFakeClient(i)) 
		{
			Player_count++;
		}	
		
	}
}



public Action:tele_jockey(Handle:timer, any:client)
{
	FREEZE_JOCKEYS(client);
	
}

public Action:Countdown(Handle:timer, any:client)
{
	
	
	//add freezing option
	secondsToGo --;
	PrintHintTextToAll("Race going live in %i ", secondsToGo);
	
	
	if (secondsToGo <=3 && secondsToGo >=0 )
	{
		
		for (new i = 1; i <= MaxClients; i++)
		{
			EmitSoundToAll(SoundNotice,i);
		}
		
		if (secondsToGo <1 )
		{
			
			h_positions=CreateTimer(1.0,Check_players_positions, _, TIMER_REPEAT);
			secondsToGo_two=0;
			h_killgrenade=CreateTimer(GetConVarInt(L4d2_how_often_grenade) * 1.0, give_grenade, _, TIMER_REPEAT)
			h_botkilltimer=CreateTimer(1.0, botkill, _, TIMER_REPEAT)//TO UNCOMMENT
			
			CreateTimer(60.0, Kill_survivor_bots)
			CreateTimer(20.0, Darnival5);//for trigger of dark carnival
			CreateTimer(5.0, hardrain5);//for trigger of HR5
			CreateTimer(20.0, swampfever4);//longer time because of the distance to the finale
			
			
			
			
			PrintToChatAll("\x01\x03GO!\x01\x04GO!\x01\x03GO!!");
			PrintHintTextToAll("GO!GO!GO!!");
			//make sure it works for every1 
			//secondsToGo = 30;
			KillTimer(h_countdown);
			h_countdown = INVALID_HANDLE;
			for (new i = 1; i <= MaxClients; i++)
			{
				
				if (IsClientInGame(i) && GetClientTeam(i)!= 1) SetEntDataFloat(i, LagMovement, 0.5, true);
				EmitSoundToAll(SoundNotices,i);
				
			}
		}
		
	}
	
}

stock FREEZE_JOCKEYS(client)		
{
	
	//PrintToChatAll("FREEZE JOCKEYS STARTED");
	
	
	new clientIds[5];
	
	new k=0;
	
	for (new i=1; i<=MaxClients; i++)
	{
		
		GetClientOfUserId(i);
		
		
		if(IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3 && IsFakeClient(i)==false)
			//if(GetClientTeam(i) == 3) FOR TELEPORT TESTING PURPOSES
			
			{  
				
				clientIds[k] = i;
				
				k++;
				
				//PrintToChatAll("cycling through players====>%N",k);
				
				
			}
		}
		
		
	}
	
	CreateTimer(5.5, spray_one, clientIds[0])//GREEN
	
	CreateTimer(5.5, spray_two, clientIds[1])//RED
	
	CreateTimer(5.5, spray_three, clientIds[2])//yellow
	
	CreateTimer(5.5, spray_four, clientIds[3])//black
	
	paint_humans(client);
	
	
	teleport_jockeys_four(clientIds[0]);//GREEN JOCKEY
	
	teleport_jockeys_three(clientIds[1]);//RED JOCKEY
	
	teleport_jockeys_two(clientIds[2]);//Yellow JOCKEY 
	
	teleport_jockeys(clientIds[3]);//BLACK JOCKEY
	
	
	
	
	
	
	
	PrintToChat(clientIds[0],"\x01\x03YOU ARE ON THE GREEN \x04TEAM, \x03RACE WITH YOUR SURVIVOR TO THE \x04SAFEHOUSE!");
	
	PrintToChat(clientIds[1],"\x01\x03YOU ARE ON THE RED \x04TEAM, \x03RACE WITH YOUR SURVIVOR TO THE \x04SAFEHOUSE!");
	
	PrintToChat(clientIds[2],"\x01\x03YOU ARE ON THE YELLOW \x04TEAM, \x03RACE WITH YOUR SURVIVOR TO THE \x04SAFEHOUSE!");
	
	PrintToChat(clientIds[3],"\x01\x03YOU ARE ON THE BLACK \x04TEAM, \x03RACE WITH YOUR SURVIVOR TO THE \x04SAFEHOUSE!");
	
}	



stock teleport_jockeys(client)
{
	new String:mapName[40];
	GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
	if (IsClientInGame(client) && GetClientTeam(client)==3)
	{
		SetEntDataFloat(client, LagMovement, 0.0, true);
	}
	
	//single out the 4 characters of the mapname
	new String:charArr[5][5];
	ExplodeString(mapName, "_", charArr, 5, 5);
	new String:mapAbbriv[5];
	strcopy(mapAbbriv, 5, charArr[0]);
	
	if(strcmp(mapAbbriv, "c1m1") == 0)
	{
		
	}
	
	else if(strcmp(mapAbbriv, "c1m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m3") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m4") == 0){
		
	}
	else if(strcmp(mapAbbriv, "c2m1") == 0){
		
		new Float:Teleport_Exit[3] = {10336.959961, 8018.081055, -523.340088}
		
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m2") == 0){		
		new Float:Teleport_Exit[3] = {2259.997314, 2334.230469, -1.967974}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m3") == 0){
		new Float:Teleport_Exit[3] = {4407.666016, 2142.611084, -63.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c2m4") == 0){
		new Float:Teleport_Exit[3] = {2743.102539, 3479.490723, -191.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m5") == 0){
	
		new Float:Teleport_Exit[3] = {-1612.232178, 2231.866455, -255.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m1") == 0){
		new Float:Teleport_Exit[3] = {-12231.570313, 10311.872070, 170.229065}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m2") == 0){
		new Float:Teleport_Exit[3] = {-8234.561523, 6999.284668, -21.984964}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m3") == 0){
		new Float:Teleport_Exit[3] = {-5820.541992, 1613.392090, 128.031250}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m4") == 0){
		new Float:Teleport_Exit[3] = {-4681.456543, -1783.407227, -95.625748}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m1") == 0){
		new Float:Teleport_Exit[3] = {-5782.540039, 7794.088379, 104.031250}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c4m2") == 0){
		new Float:Teleport_Exit[3] = {3195.806152, -2136.314209, 114.849220}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m3") == 0){
		new Float:Teleport_Exit[3] = {-619.534973, -13018.483398, 114.393555}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m4") == 0){
		new Float:Teleport_Exit[3] = {4108.845215, -728.334045, 256.031250}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m5") == 0){
		new Float:Teleport_Exit[3] = {-3817.077148, 7262.739746, 115.086273}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m1") == 0){
		new Float:Teleport_Exit[3] = {269.958130, 190.766617, -367.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m2") == 0){
		new Float:Teleport_Exit[3] = {-3723.924072, -2055.801270, -375.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m3") == 0){
		new Float:Teleport_Exit[3] = {5594.642090, 8272.786133, 69.602005}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m4") == 0){
		new Float:Teleport_Exit[3] = {-3550.952881, 4618.600586, 68.031250}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m5") == 0){
		new Float:Teleport_Exit[3] = {-11378.128906, 6165.431641, 456.031250}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c6m1") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m3") == 0){
		
	}
	
}

stock teleport_jockeys_two(client)
{
	new String:mapName[40];
	GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
	
	if (IsClientInGame(client) && GetClientTeam(client)==3)
	{
		SetEntDataFloat(client, LagMovement, 0.0, true);
	}
	
	//single out the 4 characters of the mapname
	new String:charArr[5][5];
	ExplodeString(mapName, "_", charArr, 5, 5);
	new String:mapAbbriv[5];
	strcopy(mapAbbriv, 5, charArr[0]);
	
	if(strcmp(mapAbbriv, "c1m1") == 0)
	{
		
	}
	
	else if(strcmp(mapAbbriv, "c1m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m3") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m4") == 0){
		
	}
	else if(strcmp(mapAbbriv, "c2m1") == 0){
		
		new Float:Teleport_Exit_2[3] = {10334.566406, 7926.126953, -525.160461}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m2") == 0){		
		new Float:Teleport_Exit_2[3] = {1954.747437, 2299.010498, 5.514156}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m3") == 0){
		new Float:Teleport_Exit_2[3] = {4418.174805, 2081.112305, -63.968750}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c2m4") == 0){
		new Float:Teleport_Exit_2[3] = {2655.973145, 3468.739502, -191.968750}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c2m5") == 0){
		
		new Float:Teleport_Exit_2[3] = {-1606.699463, 2133.315918, -255.968750}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);				
		
	}else if(strcmp(mapAbbriv, "c3m1") == 0){
		new Float:Teleport_Exit_2[3] = {-12119.079102, 10307.469727, 172.694580}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m2") == 0){
		new Float:Teleport_Exit_2[3] = {-8166.484375, 7009.069336, -31.968750}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m3") == 0){
		new Float:Teleport_Exit_2[3] = {-5633.584473, 1700.008057, 171.508545}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c3m4") == 0){
		new Float:Teleport_Exit_2[3] = {-4685.065918, -1641.639648, -94.750877}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c4m1") == 0){
		new Float:Teleport_Exit_2[3] = {-5727.519531, 7880.334473, 102.488892}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m2") == 0){
		new Float:Teleport_Exit_2[3] = {3285.340576, -2139.129883, 118.242188}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m3") == 0){
		new Float:Teleport_Exit_2[3] = {-745.795959, -13021.848633, 112.226608}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m4") == 0){
		new Float:Teleport_Exit_2[3] = {4015.354248, -727.156677, 256.031250}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m5") == 0){
		new Float:Teleport_Exit_2[3] = {-3825.087646, 7178.656250, 115.114868}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m1") == 0){
		new Float:Teleport_Exit[3] = {247.940979, 115.374023, -375.969147}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m2") == 0){
		new Float:Teleport_Exit[3] = {-3708.410400, -2129.031982, -375.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);		
		
	}else if(strcmp(mapAbbriv, "c5m3") == 0){
		new Float:Teleport_Exit[3] = {5676.252930, 8253.113281, 50.690155}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);			
		
	}else if(strcmp(mapAbbriv, "c5m4") == 0){
		new Float:Teleport_Exit[3] = {-3461.415039, 4618.285156, 65.009064}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);			
		
	}else if(strcmp(mapAbbriv, "c5m5") == 0){
		new Float:Teleport_Exit[3] = {-11383.467773, 6243.675293, 456.031250}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);			 
		
		
		
	}else if(strcmp(mapAbbriv, "c6m1") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m3") == 0){
		
	}
	
}

stock teleport_jockeys_three(client)
{
	
	new String:mapName[40];
	GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
	
	if (IsClientInGame(client) && GetClientTeam(client)==3)
	{
		SetEntDataFloat(client, LagMovement, 0.0, true);
	}
	
	//single out the 4 characters of the mapname
	new String:charArr[5][5];
	ExplodeString(mapName, "_", charArr, 5, 5);
	new String:mapAbbriv[5];
	strcopy(mapAbbriv, 5, charArr[0]);
	
	
	if(strcmp(mapAbbriv, "c1m1") == 0)
	{
		
	}
	
	else if(strcmp(mapAbbriv, "c1m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m3") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m4") == 0){
		
	}
	else if(strcmp(mapAbbriv, "c2m1") == 0){
		
		new Float:Teleport_Exit[3] = {10339.481445, 7851.393555, -525.203491}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m2") == 0){		
		new Float:Teleport_Exit[3] = {2055.563721, 2325.559082, 2.429688}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
		//PrintToChatAll("c2m2 detected");
	}else if(strcmp(mapAbbriv, "c2m3") == 0){
		
		new Float:Teleport_Exit[3] = {4418.571777, 2015.329102, -63.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 
		
	}else if(strcmp(mapAbbriv, "c2m4") == 0){
		new Float:Teleport_Exit[3] = {2581.303223, 3471.185791, -191.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 
		
	}else if(strcmp(mapAbbriv, "c2m5") == 0){
	
		new Float:Teleport_Exit[3] = {-1611.850220, 2021.177856, -255.966827}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 		
		
		
	}else if(strcmp(mapAbbriv, "c3m1") == 0){
		new Float:Teleport_Exit[3] = {-12034.700195, 10304.165039, 172.076599}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 
		
	}else if(strcmp(mapAbbriv, "c3m2") == 0){
		new Float:Teleport_Exit[3] = {-8087.896484, 7011.968750, -31.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 
		
	}else if(strcmp(mapAbbriv, "c3m3") == 0){
		new Float:Teleport_Exit[3] = {-5467.226074, 1679.464966, 128.031250}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 
		
	}else if(strcmp(mapAbbriv, "c3m4") == 0){
		new Float:Teleport_Exit[3] = {-4689.767578, -1553.369629, -88.614838}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 
		
	}else if(strcmp(mapAbbriv, "c4m1") == 0){
		new Float:Teleport_Exit[3] = {-5709.399414, 7956.581543, 103.369965}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 
		
	}else if(strcmp(mapAbbriv, "c4m2") == 0){
		new Float:Teleport_Exit[3] = {3358.813965, -2132.769287, 113.987526}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 
		
	}else if(strcmp(mapAbbriv, "c4m3") == 0){
		new Float:Teleport_Exit[3] = {-857.250610, -13006.136719, 115.581787}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 
		
	}else if(strcmp(mapAbbriv, "c4m4") == 0){
		new Float:Teleport_Exit[3] = {3935.952881, -726.156067, 256.031250}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 
		
	}else if(strcmp(mapAbbriv, "c4m5") == 0){
		new Float:Teleport_Exit[3] = {-3835.447754, 7067.504395, 111.846581}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 
		
		
	}else if(strcmp(mapAbbriv, "c5m1") == 0){
		new Float:Teleport_Exit[3] = {234.732300, 60.014820, -375.969177}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR); 			
		
	}else if(strcmp(mapAbbriv, "c5m2") == 0){
		new Float:Teleport_Exit[3] = {-3707.351318, -2199.427979, -375.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);			
		
	}else if(strcmp(mapAbbriv, "c5m3") == 0){
		new Float:Teleport_Exit[3] = {5760.129395, 8243.300781, 32.759285}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);			
		
	}else if(strcmp(mapAbbriv, "c5m4") == 0){
		new Float:Teleport_Exit[3] = {-3289.552490, 4622.702148, 65.664993}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);			
		
	}else if(strcmp(mapAbbriv, "c5m5") == 0){
		new Float:Teleport_Exit[3] = {-11382.300781, 6321.315430, 456.031250}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);			 
		
		
		
	}else if(strcmp(mapAbbriv, "c6m1") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m3") == 0){
		
	}
	
	
}


stock teleport_jockeys_four(client)
{
	
	new String:mapName[40];
	GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
	
	
	if (IsClientInGame(client) && GetClientTeam(client)==3)
	{
		SetEntDataFloat(client, LagMovement, 0.0, true);
	}
	
	
	
	//single out the 4 characters of the mapname
	new String:charArr[5][5];
	ExplodeString(mapName, "_", charArr, 5, 5);
	new String:mapAbbriv[5];
	strcopy(mapAbbriv, 5, charArr[0]);
	
	
	if(strcmp(mapAbbriv, "c1m1") == 0)
	{
		
	}
	
	else if(strcmp(mapAbbriv, "c1m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m3") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m4") == 0){
		
	}
	else if(strcmp(mapAbbriv, "c2m1") == 0){
		
		//PrintToChatAll("c2m1 detected");
		new Float:Teleport_Exit[3] = {10343.922852, 7763.696777, -525.606995}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c2m2") == 0){		
		new Float:Teleport_Exit[3] = {2165.758545, 2330.654541, -1.144768}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m3") == 0){
		new Float:Teleport_Exit[3] = {4416.759766, 1951.176147, -63.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c2m4") == 0){
		new Float:Teleport_Exit[3] = {2508.517822, 3472.073975, -191.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c2m5") == 0){
		
		new Float:Teleport_Exit[3] = {-1611.850220, 2021.177856, -255.966827}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);		
		
	}else if(strcmp(mapAbbriv, "c3m1") == 0){
		new Float:Teleport_Exit[3] = {-11948.354492, 10309.462891, 169.710907}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m2") == 0){
		new Float:Teleport_Exit[3] = {-8000.040039, 7021.780273, -31.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m3") == 0){
		new Float:Teleport_Exit[3] = {-5344.625977, 1691.499512, 128.031250}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m4") == 0){
		new Float:Teleport_Exit[3] = {-4697.173828, -1452.810913, -79.980904}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m1") == 0){
		new Float:Teleport_Exit[3] = {-5772.075684, 8099.292969, 98.297546}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m2") == 0){
		new Float:Teleport_Exit[3] = {3455.968750, -2131.548828, 105.937462}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m3") == 0){
		new Float:Teleport_Exit[3] = {-986.444214, -13005.063477, 113.945374}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m4") == 0){
		new Float:Teleport_Exit[3] = {3841.037842, -725.694031, 256.031250}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m5") == 0){
		new Float:Teleport_Exit[3] = {-3825.087646, 7178.656250, 115.114868}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c5m1") == 0){
		new Float:Teleport_Exit[3] = {213.489685, -9.154189, -375.969177}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);			
		
	}else if(strcmp(mapAbbriv, "c5m2") == 0){
		new Float:Teleport_Exit[3] = {-3706.182617, -2284.152588, -375.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);			
		
	}else if(strcmp(mapAbbriv, "c5m3") == 0){
		new Float:Teleport_Exit[3] = {5834.658203, 8234.274414, 26.587471}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);			
		
	}else if(strcmp(mapAbbriv, "c5m4") == 0){
		new Float:Teleport_Exit[3] = {-3203.199219, 4619.472656, 65.331894}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);			
		
	}else if(strcmp(mapAbbriv, "c5m5") == 0){
		new Float:Teleport_Exit[3] = {-11381.067383, 6403.065918, 456.031250}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);			 
		
		
		
	}else if(strcmp(mapAbbriv, "c6m1") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m3") == 0){
		
	}
	
	
}














stock teleport_humans(client)//yellow
{
	new String:mapName[40];
	GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		
		if (IsClientInGame(i) && GetClientTeam(i)!=1) SetEntDataFloat(i, LagMovement, 0.0, true);
	}
	
	//single out the 4 characters of the mapname
	new String:charArr[5][5];
	ExplodeString(mapName, "_", charArr, 5, 5);
	new String:mapAbbriv[5];
	strcopy(mapAbbriv, 5, charArr[0]);
	
	
	if(strcmp(mapAbbriv, "c1m1") == 0)
	{
		
	}
	
	else if(strcmp(mapAbbriv, "c1m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m3") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m4") == 0){
		
	}
	else if(strcmp(mapAbbriv, "c2m1") == 0){
		
		new Float:Teleport_Exit[3] = {10292.295898, 7762.672363, -523.593262}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m2") == 0){		
		
		new Float:Teleport_Exit[3] = {2168.074463, 2265.750488, -0.606899}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m3") == 0){
		new Float:Teleport_Exit[3] = {4368.683594, 1953.098511, -63.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c2m4") == 0){
		new Float:Teleport_Exit[3] = {2510.996338, 3434.312744, -191.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c2m5") == 0){
		new Float:Teleport_Exit[3] = {-1674.460815, 2012.111206, -255.969711}	
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m1") == 0){
		new Float:Teleport_Exit[3] = {-11947.439453, 10255.759766, 168.038437}	
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m2") == 0){
		new Float:Teleport_Exit[3] = {-7999.707520, 6988.207520, -31.968750}	
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
	}else if(strcmp(mapAbbriv, "c3m3") == 0){
		new Float:Teleport_Exit[3] = {-5345.007324, 1650.522827, 128.031250}	
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m4") == 0){
		new Float:Teleport_Exit[3] = {-4640.905762, -1447.704956, -74.354202}	
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m1") == 0){
		new Float:Teleport_Exit[3] = {-5676.814453, 8058.628906, 102.564819}	
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m2") == 0){
		new Float:Teleport_Exit[3] = {3455.968750, -2196.505615, 106.647926}	
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
	}else if(strcmp(mapAbbriv, "c4m3") == 0){
		new Float:Teleport_Exit[3] = {-989.542053, -12960.624023, 118.020393}	
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
	}else if(strcmp(mapAbbriv, "c4m4") == 0){
		new Float:Teleport_Exit[3] = {3841.597656, -672.177734, 256.031250}	
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m5") == 0){
		new Float:Teleport_Exit[3] = {-3892.511719, 6975.087402, 113.332474}	
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m1") == 0){
		new Float:Teleport_Exit[3] = {180.192337, 2.383988, -375.969208}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
		
		
	}else if(strcmp(mapAbbriv, "c5m2") == 0){
		new Float:Teleport_Exit[3] = {-3738.213867, -2286.469482, -375.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m3") == 0){
		new Float:Teleport_Exit[3] = {5831.908203, 8197.560547, 25.332142}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m4") == 0){
		new Float:Teleport_Exit[3] = {-3205.031250, 4587.437012, 65.174728}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m5") == 0){
		new Float:Teleport_Exit[3] = {-11349.036133, 6401.639160, 456.031250} 
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c6m1") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m3") == 0){
		
	}
	
}

stock teleport_humans_two(client)//black
{
	new String:mapName[40];
	GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
	
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	for (new i = 1; i <= MaxClients; i++)
	{
		
		if (IsClientInGame(i) && GetClientTeam(i)!=1) SetEntDataFloat(i, LagMovement, 0.0, true);
		
	}
	
	//single out the 4 characters of the mapname
	new String:charArr[5][5];
	ExplodeString(mapName, "_", charArr, 5, 5);
	new String:mapAbbriv[5];
	strcopy(mapAbbriv, 5, charArr[0]);
	
	
	if(strcmp(mapAbbriv, "c1m1") == 0)
	{
		
	}
	
	else if(strcmp(mapAbbriv, "c1m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m3") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m4") == 0){
		
	}
	else if(strcmp(mapAbbriv, "c2m1") == 0){
		
		new Float:Teleport_Exit_2[3] = {10288.698242, 7847.174805, -523.209351}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m2") == 0){		
		new Float:Teleport_Exit_2[3] = {2058.016846, 2264.137939, 3.376073}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m3") == 0){
		new Float:Teleport_Exit[3] = {4366.312012, 2017.249512, -63.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c2m4") == 0){
		new Float:Teleport_Exit_2[3] = {2581.343994, 3433.647461, -191.968750}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);		
		
	}else if(strcmp(mapAbbriv, "c2m5") == 0){
		new Float:Teleport_Exit_2[3] = {-1673.001099, 2072.142822, -255.968750}	
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c3m1") == 0){
		new Float:Teleport_Exit_2[3] = {-12028.010742, 10262.001953, 170.849258}	
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
	}else if(strcmp(mapAbbriv, "c3m2") == 0){
		new Float:Teleport_Exit_2[3] = {-8078.625488, 6978.592773, -31.968750}	
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
	}else if(strcmp(mapAbbriv, "c3m3") == 0){
		new Float:Teleport_Exit_2[3] = {-5461.855469, 1647.367310, 128.031250}	
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m4") == 0){
		new Float:Teleport_Exit_2[3] = {-4633.899902, -1547.825928, -91.106468}	
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c4m1") == 0){
		new Float:Teleport_Exit_2[3] = {-5709.399414, 7956.581543, 103.369965}	
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m2") == 0){
		new Float:Teleport_Exit_2[3] = {3357.087158, -2184.449463, 114.514198}	
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m3") == 0){
		new Float:Teleport_Exit_2[3] = {-859.123840, -12970.509766, 119.930817}	
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m4") == 0){
		new Float:Teleport_Exit_2[3] = {3930.842529, -681.765991, 256.031250}	
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m5") == 0){
		new Float:Teleport_Exit_2[3] = {-3888.091064, 7083.648438, 115.320152}	
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m1") == 0){
		new Float:Teleport_Exit[3] = {199.468460, 71.876213, -375.969147}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);	
		
	}else if(strcmp(mapAbbriv, "c5m2") == 0){
		new Float:Teleport_Exit_2[3] = {-3741.144287, -2200.073975, -375.968750}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
	}else if(strcmp(mapAbbriv, "c5m3") == 0){
		new Float:Teleport_Exit_2[3] = {5752.053711, 8210.726563, 34.604321}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
	}else if(strcmp(mapAbbriv, "c5m4") == 0){
		new Float:Teleport_Exit_2[3] = {-3289.539307, 4582.826660, 64.955002}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m5") == 0){
		new Float:Teleport_Exit_2[3] = {-11348.231445, 6325.270020, 456.031250}
		TeleportEntity(client, Teleport_Exit_2, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c6m1") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m3") == 0){
		
	}
	
}

stock teleport_humans_three(client)//red
{
	new String:mapName[40];
	GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
	
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	for (new i = 1; i <= MaxClients; i++)
	{
		
		if (IsClientInGame(i) && GetClientTeam(i)!=1) SetEntDataFloat(i, LagMovement, 0.0, true);
		
	}
	
	//single out the 4 characters of the mapname
	new String:charArr[5][5];
	ExplodeString(mapName, "_", charArr, 5, 5);
	new String:mapAbbriv[5];
	strcopy(mapAbbriv, 5, charArr[0]);
	
	
	if(strcmp(mapAbbriv, "c1m1") == 0)
	{
		
	}
	
	else if(strcmp(mapAbbriv, "c1m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m3") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m4") == 0){
		
	}
	else if(strcmp(mapAbbriv, "c2m1") == 0){
		
		new Float:Teleport_Exit_3[3] = {10277.141602, 7928.829102, -522.937195}
		
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m2") == 0){		
		new Float:Teleport_Exit_3[3] = {1952.966797, 2260.495850, 7.156837}
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m3") == 0){
		new Float:Teleport_Exit_3[3] = {4364.937500, 2079.852295, -63.968750}
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c2m4") == 0){
		new Float:Teleport_Exit_3[3] = {2653.883057, 3433.291016, -191.968750}
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);		
		
	}else if(strcmp(mapAbbriv, "c2m5") == 0){
		new Float:Teleport_Exit_3[3] = {-1672.137085, 2139.275146, -255.968781}		
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);	
		
	}else if(strcmp(mapAbbriv, "c3m1") == 0){
		new Float:Teleport_Exit_3[3] = {-12117.407227, 10270.209961, 171.753082}		
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
	}else if(strcmp(mapAbbriv, "c3m2") == 0){
		new Float:Teleport_Exit_3[3] = {-8158.716797, 6970.881348, -31.968750}		
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
	}else if(strcmp(mapAbbriv, "c3m3") == 0){
		new Float:Teleport_Exit_3[3] = {-5626.797363, 1637.465210, 190.364319}		
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m4") == 0){
		new Float:Teleport_Exit_3[3] = {-4631.695801, -1636.118896, -95.163162}		
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m1") == 0){
		new Float:Teleport_Exit_3[3] = {-5727.519531, 7880.334473, 102.488892}		
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m2") == 0){
		new Float:Teleport_Exit_3[3] = {3281.128174, -2179.055176, 116.308304}		
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m3") == 0){
		new Float:Teleport_Exit_3[3] = {-741.340576, -12967.972656, 121.031250}		
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m4") == 0){
		new Float:Teleport_Exit_3[3] = {4010.670410, -686.849365, 256.031250}		
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m5") == 0){
		new Float:Teleport_Exit_3[3] = {-3884.237061, 7182.972656, 115.155937}		
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m1") == 0){
		new Float:Teleport_Exit[3] = {215.909729, 124.998192, -375.969055}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m2") == 0){
		new Float:Teleport_Exit_3[3] = {-3740.787842, -2127.496094, -375.968750}
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m3") == 0){
		new Float:Teleport_Exit_3[3] = {5671.349121, 8221.083008, 52.229378}
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
	}else if(strcmp(mapAbbriv, "c5m4") == 0){
		new Float:Teleport_Exit_3[3] = {-3456.654785, 4586.063477, 65.021881}
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
	}else if(strcmp(mapAbbriv, "c5m5") == 0){
		new Float:Teleport_Exit_3[3] = {-11335.325195, 6244.269531, 458.637268}
		TeleportEntity(client, Teleport_Exit_3, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c6m1") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m3") == 0){
		
	}
	
}

stock teleport_humans_four(client)//green
{
	new String:mapName[40];
	GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
	
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	for (new i = 1; i <= MaxClients; i++)
	{
		
		if (IsClientInGame(i) && GetClientTeam(i)!=1) SetEntDataFloat(i, LagMovement, 0.0, true);
		
	}
	
	//single out the 4 characters of the mapname
	new String:charArr[5][5];
	ExplodeString(mapName, "_", charArr, 5, 5);
	new String:mapAbbriv[5];
	strcopy(mapAbbriv, 5, charArr[0]);
	
	
	if(strcmp(mapAbbriv, "c1m1") == 0)
	{
		
	}
	
	else if(strcmp(mapAbbriv, "c1m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m3") == 0){
		
	}else if(strcmp(mapAbbriv, "c1m4") == 0){
		
	}
	else if(strcmp(mapAbbriv, "c2m1") == 0){
		
		new Float:Teleport_Exit_4[3] = {10277.695313, 8016.110840, -521.244385}
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m2") == 0){		
		new Float:Teleport_Exit_4[3] = {2260.375000, 2266.485596, -0.583533}
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c2m3") == 0){
		new Float:Teleport_Exit[3] = {4362.155273, 2138.547363, -63.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c2m4") == 0){
		new Float:Teleport_Exit_4[3] = {2740.859619, 3435.865723, -191.968750}
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);		
		
	}else if(strcmp(mapAbbriv, "c2m5") == 0){
		new Float:Teleport_Exit_4[3] = {-1671.129517, 2225.541504, -255.968750}			
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);			
		
	}else if(strcmp(mapAbbriv, "c3m1") == 0){
		new Float:Teleport_Exit_4[3] = {-12231.551758, 10275.428711, 169.383301}			
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m2") == 0){
		new Float:Teleport_Exit_4[3] = {-8233.066406, 6967.243164, -23.474924}			
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);
	}else if(strcmp(mapAbbriv, "c3m3") == 0){
		new Float:Teleport_Exit_4[3] = {-5816.193359, 1550.981079, 128.031250}			
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c3m4") == 0){
		new Float:Teleport_Exit_4[3] = {-4619.956055, -1773.311157, -93.209343}			
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m1") == 0){
		new Float:Teleport_Exit_4[3] = {-5750.508789, 7793.581543, 104.031250}			
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m2") == 0){
		new Float:Teleport_Exit_4[3] = {3192.289307, -2170.456299, 113.951447}			
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m3") == 0){
		new Float:Teleport_Exit_4[3] = {-625.697937, -12976.617188, 120.935196}			
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m4") == 0){
		new Float:Teleport_Exit_4[3] = {4108.958984, -691.719604, 256.031250}			
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c4m5") == 0){
		new Float:Teleport_Exit_4[3] = {-3879.437744, 7279.131836, 114.694550}			
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c5m1") == 0){
		new Float:Teleport_Exit[3] = {237.926895, 196.665604, -367.968750}
		TeleportEntity(client, Teleport_Exit, NULL_VECTOR, NULL_VECTOR);
		
	}else if(strcmp(mapAbbriv, "c5m2") == 0){
		new Float:Teleport_Exit_4[3] = {-3756.457764, -2055.162109, -375.968750}
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);	
	}else if(strcmp(mapAbbriv, "c5m3") == 0){
		new Float:Teleport_Exit_4[3] = {5591.214355, 8240.755859, 70.484642}
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);	
	}else if(strcmp(mapAbbriv, "c5m4") == 0){
		new Float:Teleport_Exit_4[3] = {-3549.090088, 4586.378906, 68.031250}
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);	
		
	}else if(strcmp(mapAbbriv, "c5m5") == 0){
		new Float:Teleport_Exit_4[3] = {-11326.250977, 6149.544922, 460.031250}
		TeleportEntity(client, Teleport_Exit_4, NULL_VECTOR, NULL_VECTOR);
		
		
	}else if(strcmp(mapAbbriv, "c6m1") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m2") == 0){
		
	}else if(strcmp(mapAbbriv, "c6m3") == 0){
		
	}
	
}

public Action:racemode(client,args)
{
	
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		
		if (h_killgrenade != INVALID_HANDLE)
		{
			KillTimer(h_killgrenade);
			h_killgrenade = INVALID_HANDLE;
		}
		
		Grenade();	
		CreateTimer(1.0, Detect_burn, _, TIMER_REPEAT);
		
		
		if (h_Final_time != INVALID_HANDLE)
		{
			KillTimer(h_Final_time);
			h_Final_time = INVALID_HANDLE;	
		}
		
		h_Final_time=CreateTimer(1.0, Final_time, _,TIMER_REPEAT)
		minutes_counter=0;	
		race_timer = -30;
		
		if (h_countdown != INVALID_HANDLE)
		{
			
			KillTimer(h_countdown);
			h_countdown = INVALID_HANDLE;
			
		}
		
		if (h_positions != INVALID_HANDLE)
		{
			KillTimer(h_positions);
			h_positions = INVALID_HANDLE;
		}
		
		
		if (h_botkilltimer != INVALID_HANDLE)
		{
			
			KillTimer(h_botkilltimer);
			h_botkilltimer = INVALID_HANDLE;
		}
		
		
		if (h_killadrenaline != INVALID_HANDLE)
		{
			
			KillTimer(h_killadrenaline);
			h_killadrenaline = INVALID_HANDLE;
		}
		
		secondsToGo=30;
		Player_count=0;
		Player_count_two=0;
		

		h_countdown = CreateTimer(1.0, Countdown, client, TIMER_REPEAT)
		CreateTimer(4.0, Count_players)
		CreateTimer(7.0, tele_jockey, client)//RETURN TO 7 SECONDS
		CreateTimer(10.0, parish5);//for trigger of the parish 5
		
		
	}
}

public Action:swampfever4(Handle:Timer) 
{
if(mapNum==12)
	{
h_SFtrigger=CreateTimer(1.0, start_SFfinale, _, TIMER_REPEAT)
	}
}

public Action:start_SFfinale(Handle:Timer) 
{
new Float:Gate_position[3] = {1652.245361, 425.325256, 224.031250}
decl Float:f_EntOrigin[3]
for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i)==2)
		{
			
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", f_EntOrigin)
			GetClientAbsOrigin(i, f_EntOrigin);
			//GetClientAbsOrigin(i, Gate_position);
			
			if (GetVectorDistance(Gate_position, f_EntOrigin) <= 800.0)//if any player is within 800 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
			{
			//PrintToChatAll("WITHIN 800 OF LOCATION TIMER STARTED");
			CreateTimer(15.0, trigger_radioSF);//for trigger of swamp fever radio
			
			if (h_SFtrigger != INVALID_HANDLE)
			{
			KillTimer(h_SFtrigger);
			h_SFtrigger = INVALID_HANDLE;
			}
			
			}
			
		}

	}

}

public Action:trigger_radioSF(Handle:Timer) 
{
	PrintToChatAll("\x01\x03 Swamp Fever Finale \x04STARTED");


	for(new i = 1; i <= MaxClients; i++) 
	{ 
		if (IsClientInGame(i) && GetClientTeam(i)==2)
		{ 
		UnflagAndExecuteCommand(i, "ent_fire", "trigger_finale", "");	
		}
		
		
	}	
	
	
}

public Action:hardrain5(Handle:Timer) 
{
if(mapNum==17)
	{
CreateTimer(1.0, start_HRfinale)
	}
}

stock UnflagAndExecuteCommand(client, String:command[], String:parameter1[]="", String:parameter2[]="")
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2)
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}


public Action:start_HRfinale(Handle:Timer) 
{
	PrintToChatAll("\x01\x03Hard Rain Finale \x04STARTED");
	//new Float:Teleport_c2m5Lights[3] = {-2279.026855, 2091.391846, 128.031250}

	for(new i = 1; i <= MaxClients; i++) 
	{ 
		if (IsClientInGame(i) && GetClientTeam(i)==2)
		{ 
		UnflagAndExecuteCommand(i, "ent_fire", "trigger_finale", "");	
		}
		
		
	}

}

public Action:parish5(Handle:Timer) 
{
if(mapNum==22)
	{
CreateTimer(1.0, check_bridge)
	}
}

public Action:check_bridge(Handle:Timer) 
{
	PrintToChatAll("\x01\x03The Parish Finale \x04STARTED");
	//new Float:Teleport_c2m5Lights[3] = {-2279.026855, 2091.391846, 128.031250}

	for(new i = 1; i <= MaxClients; i++) 
	{ 
		if (IsClientInGame(i) && GetClientTeam(i)==2)
		{ 
		UnflagAndExecuteCommand(i, "ent_fire", "trigger_finale", "");	
		}
		
		
	}

}

public Action:Darnival5(Handle:Timer) 
{
if(mapNum==8)
	{
h_gatekill=CreateTimer(1.0, check_gate, _, TIMER_REPEAT)
	}
}

public Action:check_gate(Handle:Timer) 
{
new Float:Gate_position[3] = {-3492.075684, 3021.180420, -253.775879}
decl Float:f_EntOrigin[3]
for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i)==2)
		{
			
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", f_EntOrigin)
			GetClientAbsOrigin(i, f_EntOrigin);
			//GetClientAbsOrigin(i, Gate_position);
			
			if (GetVectorDistance(Gate_position, f_EntOrigin) <= 300.0)//if any player is within 300 units? of the gate on c2m5 a timer will start to begin the finale and close that gate
			{
			//PrintToChatAll("WITHIN 300 OF LOCATION TIMER STARTED");
			CreateTimer(15.0, lights);//for trigger of dark carnival
			
			if (h_gatekill != INVALID_HANDLE)
			{
			KillTimer(h_gatekill);
			h_gatekill = INVALID_HANDLE;
			}
			
			}
			
		}

	}

}
public Action:lights(Handle:Timer) 
{
	PrintToChatAll("\x01\x03Finale \x04STARTED");
	//new Float:Teleport_c2m5Lights[3] = {-2279.026855, 2091.391846, 128.031250}

	for(new i = 1; i <= MaxClients; i++) 
	{ 
		if (IsClientInGame(i) && GetClientTeam(i)==2)
		{ 
		UnflagAndExecuteCommand(i, "ent_fire", "trigger_finale", "");	
		}
		
		
	}
	

	
}



public Grenade()
{	
	
	CreateTimer(38.0, remove_grenade)
}

public Action:remove_grenade(Handle:timer)//reducwa adrenaline spam on the floors
{
	new entcount = GetEntityCount();
	
	decl String:ModelName[128];
	for (new i=1;i<=entcount;i++)
	{
		if(IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", ModelName, 128);
			
			if(StrContains(ModelName, "v_models", true) != -1)
			{
				if(StrContains(ModelName, "v_bile_flask.mdl", true) != -1||
				StrContains(ModelName, "v_molotov.mdl", true) != -1 )	
				{
					AcceptEntityInput(i, "Kill");
				}
			}
		}
	}
}

public Action:Final_time(Handle:timer)
{
	race_timer++;
	//PrintToChatAll("%i seconds ",race_timer);
	//PrintHintTextToAll("%i minutes ",minutes_counter);
	
	if (race_timer>59 && race_timer<61 )
	{
		minutes_counter++;
		race_timer=race_timer-60;
		//PrintToChatAll("MINUTES DETECTED");
	}	
	
}

public Action:Detect_burn(Handle:timer)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(GetClientTeam(i) == 2 && !IsFakeClient(i))  //is client on survivors team
			{
				if (IsPlayerBurning(i))
				{
					Burn_effect(i);
				}
			}
			
		}
		
	}	
}


Burn_effect(client)
{
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	if (client == 0)
	{
		return;
	}
	else
	{
		
		//We need to reset the timer in case the client decides to
		//use a second adrenaline while the first one is still active
		
		if (g_got_burnt[client] == 1)
		{
			
			KillTimer(g_molotov_timer[client])
			KillTimer(g_burning_countdown[client])
			g_got_burnt[client] = 0;
			
		}
		
		CreateTimer(0.1, Timer_got_burnt, client, TIMER_FLAG_NO_MAPCHANGE);
		g_burning_countdown[client] = CreateTimer(1.0, Timer_fire_Countdown, client, TIMER_REPEAT);
		g_molotov_timer[client] = CreateTimer(GetConVarInt(L4d2_Fire_slowdown_duration) * 1.0, Timer_Endfire, client, TIMER_FLAG_NO_MAPCHANGE);
		
	}
	
}



public Action:Bile_effect(Handle:timer, any:client)
{
	
	if(GetClientTeam(client) == 2 && IsPlayerAlive(client ))  //is client on survivors team
	{
		
		SetEntDataFloat(client, LagMovement, 1.0, true);
		PrintToChatAll("\x03%N \x4WAS \x03BILED",client);
		
		
		//We need to reset the timer in case the client decides to
		//use a second adrenaline while the first one is still active
		
		if (g_got_biled[client] == 1)
		{
			
			KillTimer(g_bile_timer[client])
			KillTimer(g_biled_countdown[client])
			g_got_biled[client] = 0;
			SetEntDataFloat(client, LagMovement, 1.0, true);
		}
		
		g_boomed[client]=true
		CreateTimer(0.1, Timer_got_biled, client, TIMER_FLAG_NO_MAPCHANGE);
		g_biled_countdown[client] = CreateTimer(1.0, Timer_bile_Countdown, client, TIMER_REPEAT);
		g_bile_timer[client] = CreateTimer(GetConVarInt(L4d2_Fire_slowdown_duration) * 1.0, Timer_EndBile, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	
	
}	

public Action:Timer_EndBile(Handle:Timer, any:client)
{		
	//PrintToChatAll("Timer_Endfire STARTED?");	
	//PrintToChat(client, "\x04[SM] \x01Returning to normal...");
	g_got_biled[client] = 0
	g_boomed[client]=false
	
}

public Action:Timer_got_biled(Handle:Timer, any:client)
{
	
	
	
	g_biled_timeleft[client] = GetConVarInt(L4d2_Fire_slowdown_duration);
	g_biled_timeleft[client] -= 1;
	g_got_biled[client] = 1
	
	
}

public Action:Timer_fire_Countdown(Handle:timer, any:client)
{
	
	if(g_burning_timeleft[client] == 0) //Powerups ran out
	{
		SetEntDataFloat(client, LagMovement, 1.0, true);
		PrintHintText(client,"Returning to normal...");
		g_burning_timeleft[client] = GetConVarInt(L4d2_Fire_slowdown_duration);//change 
		return Plugin_Stop;
	}
	else //Countdown progress
	{
		SetEntDataFloat(client, LagMovement, 0.2, true);
		PrintHintText(client,"Recovering from fire: %d", g_burning_timeleft[client]);
		g_burning_timeleft[client] -= 1;
		return Plugin_Continue;
	}
}

public Action:Timer_bile_Countdown(Handle:timer, any:client)
{
	
	if(g_biled_timeleft[client] == 0) //Powerups ran out
	{
		//Remove the hud
		
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
		PrintHintText(client,"Returning to normal...");
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		g_biled_timeleft[client] = GetConVarInt(L4d2_Fire_slowdown_duration);//change 
		g_boomed[client]=false
		return Plugin_Stop;
	}
	else //Countdown progress
	{		
		//Along with bile the code below makes the user almost fully blind
		// Fades
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
		
		PrintHintText(client,"Recovering from bile: %d", g_biled_timeleft[client]);
		g_biled_timeleft[client] -= 1;
		
		
		
		
		
		return Plugin_Continue;
	}
}





public Action:Timer_Endfire(Handle:Timer, any:client)
{		
	//PrintToChatAll("Timer_Endfire STARTED?");	
	//PrintToChat(client, "\x04[SM] \x01Returning to normal...");
	g_got_burnt[client] = 0
	
}

public Action:Timer_got_burnt(Handle:Timer, any:client)
{
	//PrintToChatAll("TIMER USED HEALTH STARTED?");	
	
	PrintHintText(client, "Fire slowdown left: %d", GetConVarInt(L4d2_Fire_slowdown_duration));
	g_burning_timeleft[client] = GetConVarInt(L4d2_Fire_slowdown_duration);
	g_burning_timeleft[client] -= 1;
	g_got_burnt[client] = 1
	
	
}


public Action:Killall_except_winners(Handle:timer, any:client)//to COMPLETE
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			
		}
	
	}
	
}

public Action:botkill(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) 
		{
			if (GetClientTeam(i) == TEAM_INFECTED &&(IsFakeClient(i)))
			{
				ForcePlayerSuicide(i);
			}
		}
	}
}




stock IsPlayerTank(client)//to remove 
{
	decl String:playermodel[96];
	GetClientModel(client, playermodel, sizeof(playermodel));
	return (StrContains(playermodel, "hulk", false) > -1);
}

public jockey_ride (Handle:event, const String:name[], bool:dontBroadcast)
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!victim) return;
		if (!attacker) return;
		Attacker[victim] = attacker;
		
		IncapType[victim]=INCAP_RIDE;
		
		if(	GetConVarInt(l4d_selfhelp_ride)>0)
		{
			CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);	
			CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim); 
			
		}
		
		if (GetConVarInt(L4d2_jockey_slowdown_enable))
		{
			
			CreateTimer(0.3, FastHuman, victim);
			
		}
	}
}

public jockey_ride_end (Handle:event, const String:name[], bool:dontBroadcast)
{	
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));//mine
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!victim) return;
		if (!attacker) return;
		if (!GetConVarInt(L4d2_jockey_slowdown_enable))
		{
			if(Attacker[victim] ==attacker)
			{
				Attacker[victim] = 0;
			}
			{
				CreateTimer(0.1, SlowJockey, attacker);  
				CreateTimer(0.1, SlowHuman, victim);  
				
			}
		}
		IncapType[victim]=NOT_JOCKIED
		PrintHintText(victim,"Running without your jockey will make you much slower!"); 
	}
}



public Event_Incap (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		IncapType[victim]=INCAP;
		if(GetConVarInt(l4d_selfhelp_incap)>0)
		{
			CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);	
			CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim); 
		}
	}
}

public Action:player_ledge_grab(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (GetConVarInt(Gamemode_jockey_racing))
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		IncapType[victim]=INCAP_EDGEGRAB;
		if(GetConVarInt(l4d_selfhelp_edgegrab)>0)
		{
			CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);	
			CreateTimer(2.0, ledge_advertise, victim); 
		}
	}
}

public Action:WatchPlayer(Handle:timer, any:client)
{
	if (!client) return;
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	if (!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]==0 )return;
	
	if(Timers[client]!=INVALID_HANDLE)return;
	HelpOhterState[client]=HelpState[client]=STATE_NONE;
	
	Timers[client]=CreateTimer(1.0/TICKS, PlayerTimer, client, TIMER_REPEAT);
}
public Action:AdvertisePills(Handle:timer, any:client)
{
	
	//PrintToChatAll("is this THE JOCKEY?---> %N",a); 
	if (!client) return;
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	
	if(CanSelfHelp(client))
	{
		PrintToChat(client, "\x01\x03Press \x04  USE(E)\x03 or \x04(CTRL)\x03 to take ADRENALINE");
		PrintHintText(client, "\x01\x03Press \x04\x03 (E) or (CTRL) to take ADRENALINE");
	}
	
}

public Action:ledge_advertise(Handle:timer, any:client)
{
	
	//PrintToChatAll("is this THE JOCKEY?---> %N",a); 
	if (!client) return;
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	
	if(CanSelfHelp(client))
	{
		PrintToChat(client, "\x01\x03HOLD \x04  CROUCH(CTRL)\x03 to pick yourself UP");
		PrintHintText(client, "\x01\x03HOLD \x04  CROUCH(CTRL)\x03 to pick yourself UP");
	}
	
}


bool:CanSelfHelp(client)
{
	new bool:pills=HavePills(client);
	new bool:kid=HaveKid(client);
	new bool:adrenalines=HaveAdrenaline(client);
	new bool:ok=false;
	new self;
	
	if(IncapType[client]==INCAP)
	{
		self=GetConVarInt( l4d_selfhelp_incap);
		if(self==1)ok=true;
		else ok=false;
		
	}
	
	if(IncapType[client]== INCAP_EDGEGRAB)
	{
		self=GetConVarInt( l4d_selfhelp_edgegrab);
		if(self==1)ok=true;
		else ok=false;
		
	}
	
	else if(IncapType[client]== INCAP_RIDE)
	{
		self=GetConVarInt( l4d_selfhelp_ride);
		if((self==1 || self==3) && (pills || adrenalines))ok=true;
		else if ((self==2 || self==3) && kid)ok=true;
	}
	
	return ok;
}

SelfHelpUseSlot(client)
{
	new pills = GetPlayerWeaponSlot(client, 4);
	new kid=GetPlayerWeaponSlot(client, 3);
	new solt=-1;
	new self;
	
	if(IncapType[client]== INCAP)
	{
		self=GetConVarInt( l4d_selfhelp_incap);
		if (self==1) solt=3;
	}
	
	if(IncapType[client]== INCAP_EDGEGRAB)
	{
		self=GetConVarInt( l4d_selfhelp_edgegrab);
		if (self==1) solt=3;
	}
	
	else if(IncapType[client]== INCAP_RIDE)
	{
		self=GetConVarInt( l4d_selfhelp_ride);
		if((self==1 || self==3) && pills!=-1)solt=4;
		else if ((self==2 || self==3) && kid)solt=3;
	}
	
	return solt;
}

public Action:PlayerTimer(Handle:timer, any:client)
{
	new Float:time=GetEngineTime();
	
	if (client==0 )
	{
		HelpOhterState[client]=HelpState[client]=STATE_NONE;
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	if(!IsClientInGame(client) || !IsPlayerAlive(client)  ) 
	{
		HelpOhterState[client]=HelpState[client]=STATE_NONE;
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if( !IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]==0)
	{
		
		HelpOhterState[client]=HelpState[client]=STATE_NONE;
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if(!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]!=0)
	{
		if (!IsClientInGame(Attacker[client]) || !IsPlayerAlive(Attacker[client]))
		{
			HelpOhterState[client]=HelpState[client]=STATE_NONE;
			Timers[client]=INVALID_HANDLE;
			Attacker[client]=0; 
			return Plugin_Stop;
		}
		
	}
	if(HelpState[client]==STATE_OK )
	{
		HelpOhterState[client]=HelpState[client]=STATE_NONE;
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	new buttons = GetClientButtons(client);
	
	new haveone=0;
	new PillSlot = GetPlayerWeaponSlot(client, 4);  
	new KidSlot=GetPlayerWeaponSlot(client, 3);
	
	if (PillSlot != -1)  
	{
		haveone++;
	}
	if(KidSlot !=4)
	{
		haveone++;
		
	}
	
	if(haveone>0)
	{
		if(IncapType[client]== INCAP_RIDE ||IncapType[client]== INCAP_EDGEGRAB || IncapType[client]== INCAP)
		{
			if((buttons & IN_DUCK) ||  (buttons & IN_USE)) 
			{
				if(CanSelfHelp(client))
				{
					
					
					if(HelpState[client]==STATE_NONE)
					{
						HelpStartTime[client]=time;
						SetupProgressBar(client, GetConVarFloat(l4d_selfhelp_duration));
						//PrintHintText(client, "Getting yourself up");
					}
					
					
					
					
					
					HelpState[client]=STATE_SELFHELP;
					//PrintToChatAll("%f  %f", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration));
					if( time-HelpStartTime[client]>GetConVarFloat(l4d_selfhelp_duration))
					{
						if(HelpState[client]!=STATE_OK)
						{
							SelfHelp(client);
							KillProgressBar(client);
						}
						
					}					
				}	
			}
			else if(HelpState[client]==STATE_SELFHELP)
			{
				KillProgressBar(client);
				HelpState[client]=STATE_NONE;
			}
		}
		else
		{
			if(HelpState[client]==STATE_SELFHELP)
			{
				KillProgressBar(client);
				
				
				HelpState[client]=STATE_NONE;
			}
			
		}
		
	}
	
	
	if ((buttons & IN_DUCK)) 
	{	
		new bool:pickup=false;
		new Float:dis=100.0;
		new ent = -1;
		if (PillSlot == -1)  
		{
			decl Float:targetVector1[3];
			decl Float:targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			ent=-1;
			while ((ent = FindEntityByClassname(ent,  "weapon_pain_pills" )) != -1)
			{
				if (IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					if(GetVectorDistance(targetVector1  , targetVector2)<dis)
					{
						
						CheatCommands(client, "give", "pain_pills");
						RemoveEdict(ent);
						pickup=true;
						PrintHintText(client,"Found pills");
						
						break;
					}
				}
			}
			if(!pickup)
			{
				ent = -1;
				while ((ent = FindEntityByClassname(ent,  "weapon_adrenaline" )) != -1)
				{
					if (IsValidEntity(ent))
					{
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
						if(GetVectorDistance(targetVector1  , targetVector2)<dis)
						{
							
							CheatCommands(client, "give", "adrenaline");
							RemoveEdict(ent);
							pickup=true;
							PrintHintText(client,"Found adrenaline");
							
							break;
						}
					}
				}
				
			}
		}
		if (KidSlot == -1 && !pickup)  
		{
			decl Float:targetVector1[3];
			decl Float:targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			ent = -1;
			while ((ent = FindEntityByClassname(ent,  "weapon_first_aid_kit" )) != -1)
			{
				if (IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					if(GetVectorDistance(targetVector1  , targetVector2)<dis)
					{
						
						CheatCommands(client, "give", "first_aid_kit");
						RemoveEdict(ent);
						pickup=true;
						//PrintHintText(client,"you find medkit");
						break;
					}
				}
			}
		}
		if (GetPlayerWeaponSlot(client, 1)==-1 && !pickup)  
		{
			decl Float:targetVector1[3];
			decl Float:targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			ent = -1;
			while ((ent = FindEntityByClassname(ent,  "weapon_pistol" )) != -1)
			{
				if (IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					if(GetVectorDistance(targetVector1  , targetVector2)<dis)
					{
						CheatCommands(client, "give", "pistol");
						RemoveEdict(ent);
						pickup=true;
						PrintHintText(client,"you find pistol");
						break;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

SelfHelp(client)
{
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client) )
	{
		return;
	} 
	if( !IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]==0) 
	{
		return;
	} 
	new bool:pills=HavePills(client);
	
	new bool:adrenaline2=HaveAdrenaline(client);
	new slot=SelfHelpUseSlot(client);
	if(slot!=-1)
	{
		new weaponslot=GetPlayerWeaponSlot(client, slot);
		if(slot ==4)
		{
			
			RemovePlayerItem(client, weaponslot);
			
			ReviveClientWithPills(client);
			
			
			HelpState[client]=STATE_OK;
			
			if(adrenaline2)	PrintToChatAll("\x04%N took \x03ADRENALINE!", client);  
			if(pills)	PrintToChatAll("\x04%N\x03 took \x03PILLS!", client); 	
			//EmitSoundToClient(client, "player/items/pain_pills/pills_use_1.wav"); // add some sound
			
		}
		else if(slot==3)
		{
			
			//RemovePlayerItem(client, weaponslot);
			
			ReviveClientWithKid(client);
			
			HelpState[client]=STATE_OK;
			PrintToChatAll("\x04%N\x03 got brought back up!", client); 
			
			//EmitSoundToClient(client, "player/items/pain_pills/pills_use_1.wav"); // add some sound
		}
		
	}
	else 
	{
		PrintHintText(client, "help self failed");
		HelpState[client]=STATE_FAILED;
	}
}


ReviveClientWithKid(client)
{
	
	
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	SetUserFlagBits(client, userflags);
	
	
	
	//new Handle:revivehealth = FindConVar("pain_pills_health_value"); 
	//new temphpoffset = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	//SetEntDataFloat(client, temphpoffset, GetConVarFloat(revivehealth), true);
	//SetEntityHealth(client, 1);
}
ReviveClientWithPills(client)
{
	
	
	
	CheatCommands(client, "give", "health");
	new Handle:revivehealth = FindConVar("pain_pills_health_value");  
	CreateTimer(0.1, SetHP1, client);  
	new temphpoffset = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	SetEntDataFloat(client, temphpoffset, GetConVarFloat(revivehealth), true);
	
	LagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	
	
	if (client == 0)
	{
		return;
	}
	else
	{
		if (GetConVarInt(L4d2_drug_boost_on))
		{
			if (IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				//We need to reset the timer in case the client decides to
				//use a second adrenaline while the first one is still active
				if (g_usedhealth[client] == 1)
				{
					KillTimer(g_powerups_timer[client])
					KillTimer(g_powerups_countdown[client])
					g_usedhealth[client] = 0;
					SetEntDataFloat(client, LagMovement, 1.0, true);
				}
				CreateTimer(0.1, Timer_UsedHealth, client, TIMER_FLAG_NO_MAPCHANGE);
				g_powerups_countdown[client] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
				g_powerups_timer[client] = CreateTimer(GetConVarInt(L4d2_drug_boost_duration) * 1.0, Timer_EndPower, client, TIMER_FLAG_NO_MAPCHANGE);
				
			}
		}
	}
	
	
}



public Action:SetHP1(Handle:timer, any:client)
{
	SetEntityHealth(client, 99);
}


bool:HaveKid(client)
{
	decl String:weapon[32];
	new KidSlot=GetPlayerWeaponSlot(client, 3);
	
	if(KidSlot !=-1)
	{
		GetEdictClassname(KidSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_first_aid_kit"))
		{
			return true;
		}
	}
	return false;
}
bool:HavePills(client)
{
	decl String:weapon[32];
	new KidSlot=GetPlayerWeaponSlot(client, 4);
	
	if(KidSlot !=-1)
	{
		GetEdictClassname(KidSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_pain_pills"))
		{
			return true;
		}
	}
	return false;
}


bool:HaveAdrenaline(client)
{
	decl String:weapon[32];
	new KidSlot=GetPlayerWeaponSlot(client, 4);
	
	if(KidSlot !=-1)
	{
		GetEdictClassname(KidSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_adrenaline"))
		{
			return true;
		}
	}
	return false;
	
}

stock CheatCommands(client, String:command[], String:arguments[] = "")
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
	
}


bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
bool:IsPlayerGrapEdge(client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))return true;
	return false;
}
reset()
{
	for (new x = 0; x < MAXPLAYERS+1; x++)
	{
		HelpState[x]=0;
		Attacker[x]=0;
		if(Timers[x]!=INVALID_HANDLE)
		{
			KillTimer(Timers[x]);
		}
		Timers[x]=INVALID_HANDLE;
	}
}

stock SetupProgressBar(client, Float:time)
{
	//KillProgressBar(client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", client);
	
}

stock KillProgressBar(client)
{
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	//SetEntityMoveType(client, MOVETYPE_WALK);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", 0);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", 0);
}
/*
public Action:sm_ht(client, args)
{
new o=GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
new t=GetEntPropEnt(client, Prop_Send, "m_reviveTarget");
if(o > 0 && t >0)	PrintToChatAll("onwer %N, target %N", o, t);
else PrintToChatAll("onwer %d, target %d", o, t);
}
*/




public Action:give_molo(client,args)//used for testing of molo
{	
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	
	
	FakeClientCommand(client, "give molotov");
	
	
	
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	
}

public Action:Give_bile(client,args)//used for testing of abile
{	
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	
	
	FakeClientCommand(client, "give vomitjar");
	
	
	
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	
}



public Action:Timer_UsedHealth(Handle:Timer, any:client)
{
	if (GetConVarInt(L4d2_drug_boost_on))
	{
		//PrintToChat(client, "\x04[SM] \x01Drug sprint Time!");
		PrintHintText(client, "Drug sprint Time left: %d", GetConVarInt(L4d2_drug_boost_duration));
		g_powerups_timeleft[client] = GetConVarInt(L4d2_drug_boost_duration);
		g_powerups_timeleft[client] -= 1;
		g_usedhealth[client] = 1
		
	}
}

public Action:Timer_EndPower(Handle:Timer, any:client)
{
	if (GetConVarInt(L4d2_drug_boost_on))
	{
		//PrintToChat(client, "\x04[SM] \x01Returning to normal...");
		g_usedhealth[client] = 0
		
	}
}

public Action:Timer_Countdown(Handle:timer, any:client)
{
	if(g_powerups_timeleft[client] == 0) //Powerups ran out
	{
		SetEntDataFloat(client, LagMovement, 1.0, true);
		PrintHintText(client,"Returning to normal...");
		g_powerups_timeleft[client] = GetConVarInt(L4d2_drug_boost_duration);
		return Plugin_Stop;
	}
	else //Countdown progress
	{
		SetEntDataFloat(client, LagMovement, 1.5, true);
		PrintHintText(client,"Drug sprint Time left: %d", g_powerups_timeleft[client]);
		g_powerups_timeleft[client] -= 1;
		return Plugin_Continue;
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Timer_RoundEnd);
	
	if (h_positions != INVALID_HANDLE)
		{
			KillTimer(h_positions);
			h_positions = INVALID_HANDLE;
		}
		
	for (new i = 1; i <= MaxClients; i++)
		if (g_h_GrenadeTimer[i] != INVALID_HANDLE)
	{
		KillTimer(g_h_GrenadeTimer[i])
		g_h_GrenadeTimer[i] = INVALID_HANDLE
	}
}


bool:IsPlayerBurning(i)
{
	if(GetEntProp(i, Prop_Data, "m_fFlags") & FL_ONFIRE) return true;
	else return false;
}

public Action:EventPlayerTeam(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	if (!GetEventBool(h_Event, "isbot"))
	{
		decl i_UserID, i_Client
		
		i_UserID = GetEventInt(h_Event, "userid")
		i_Client = GetClientOfUserId(i_UserID)
		
		if (GetEventInt(h_Event, "team") == TEAM_SURVIVOR)
			CreateTimer(0.1, DelayCheckPlayer, i_Client)
	}
}

public Action:boomerspawn(client,args)//used for testing of adrenaline
{	
	CheatCommands (client, "z_spawn", "boomer");
}


public Action:EventReviveBegin(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client, i_Weapon
	
	i_UserID = GetEventInt(h_Event, "subject")
	i_Client = GetClientOfUserId(i_UserID)
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled
	
	i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
	g_b_InAction[i_Client] = false
	
	if (i_Weapon != -1)
	{
		SetPlayerWeaponModel(i_Client, i_Weapon)
		SetEntPropFloat(i_Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime())
	}
	
	g_b_AllowThrow[i_Client] = false
	
	return Plugin_Continue
}

public Action:EventReviveEnd(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client
	
	i_UserID = GetEventInt(h_Event, "subject")
	i_Client = GetClientOfUserId(i_UserID)
	
	g_b_AllowThrow[i_Client] = true
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
		DispatchKeyValue(i_Ent, "model", MODEL_GASCAN)
		DispatchSpawn(i_Ent)
		TeleportEntity(i_Ent, f_Origin, NULL_VECTOR, NULL_VECTOR)
		SetEntityMoveType(i_Ent, MOVETYPE_VPHYSICS)
		AcceptEntityInput(i_Ent, "Break")
		
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
		f_CvarDuration = 30.0
		RemoveEdict(i_Ent)
		
		
		DisplayParticle(f_Origin, "vomit_jar", f_CvarDuration)
		i_InfoEnt = CreateEntityByName("info_goal_infected_chase")
		DispatchKeyValueVector(i_InfoEnt, "origin", f_Origin)
		DispatchSpawn(i_InfoEnt)
		AcceptEntityInput(i_InfoEnt, "Enable")
		CreateTimer(f_CvarDuration, DeleteEntity, i_InfoEnt)
		
		
		
		i_MaxEntities = GetMaxEntities()
		for (new i = 1; i <= i_MaxEntities; i++)
		{
			if (IsValidEdict(i) && IsValidEntity(i))
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName))
				
				if (StrContains(s_ModelName, "infected") || StrContains(s_ModelName, "survivors") != -1)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", f_EntOrigin)
					
					if (GetVectorDistance(f_Origin, f_EntOrigin) <= 150.0)
					{
						
						
						
						decl Float:f_Position[3], Float:f_Speed[3], Float:f_Angles[3]
						GetClientEyePosition(i, f_Position)
						GetClientEyeAngles(i, f_Angles)
						GetAngleVectors(f_Angles, f_Speed, NULL_VECTOR, NULL_VECTOR)
						
						SetEntProp(i, Prop_Send, "m_iGlowType", 3)
						SetEntProp(i, Prop_Send, "m_glowColorOverride", -4713783)
						CreateTimer(GetConVarFloat(L4d2_Fire_slowdown_duration), DisableGlow, i)
						CreateTimer(1.0, Bile_effect, i)//Inflict players with bile consequences
						
						GetRandomAngles(f_Angles)
						
						
						if (IsClientInGame(i) && GetClientTeam(i)==2 && IsPlayerAlive(i))
						{
							SetEntDataFloat(i, LagMovement, 0.3, true);
							
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

public Action:DisableGlow(Handle:h_Timer, any:i_Ent)
{
	decl String:s_ModelName[64]
	
	if (!IsValidEdict(i_Ent) || !IsValidEntity(i_Ent))
		return Plugin_Handled
	
	GetEntPropString(i_Ent, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName))
	
	if (StrContains(s_ModelName, "infected") || StrContains(s_ModelName, "survivors") != -1)
	{
		SetEntProp(i_Ent, Prop_Send, "m_iGlowType", 0)
		SetEntProp(i_Ent, Prop_Send, "m_glowColorOverride", 0)
	}
	
	return Plugin_Continue
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
	
	//CheatCommands (i_Client, "z_spawn", "boomer");
	
	//TeleportEntity(i_Ent, f_Position, f_Angles, f_Speed)
	
	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	SetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	g_h_GrenadeTimer[i_Client] = CreateTimer(0.1, VomitjarThink, i_Ent, TIMER_REPEAT)
}


public ThrowPipebomb(i_Client)
{
	decl i_Ent, Float:f_Position[3], Float:f_Angles[3], Float:f_Speed[3], String:s_Ent[4], String:s_TargetName[32],
	Float:f_CvarSpeed
	
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
	f_CvarSpeed = 1000.0
	
	f_Speed[0] *= f_CvarSpeed
	f_Speed[1] *= f_CvarSpeed
	f_Speed[2] *= f_CvarSpeed
	
	GetRandomAngles(f_Angles)
	TeleportEntity(i_Ent, f_Position, f_Angles, f_Speed)
	AttachParticle(i_Ent, "weapon_pipebomb_blinking_light", f_Position)
	AttachParticle(i_Ent, "weapon_pipebomb_fuse", f_Position)
	AttachInfected(i_Ent, f_Position)
	
	IntToString(i_Ent, s_Ent, sizeof(s_Ent))
	SetTrieValue(g_t_PipeTicks, s_Ent, 0)
	SetTrieValue(g_t_GrenadeOwner, s_Ent, i_Client)
	
	g_h_GrenadeTimer[i_Client] = CreateTimer(0.1, PipebombThink, i_Ent, TIMER_REPEAT)
}

public Action:PipebombThink(Handle:h_Timer, any:i_Ent)
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
			g_PipebombBounce[i_Client] = 0
			RemoveFromTrie(g_t_PipeTicks, s_Ent)
			RemoveFromTrie(g_t_GrenadeOwner, s_Ent)
		}
		
		return Plugin_Handled
	}
	
	decl i_Count, Float:f_Angles[3], Float:f_Origin[3], Float:f_Units, Float:f_CvarDuration
	
	GetTrieValue(g_t_PipeTicks, s_Ent, i_Count)
	GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin)
	f_CvarDuration = 6.0 * 10
	
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

public Action:EventAllowThrow(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client
	
	if (GetEventInt(h_Event, "victim"))
		i_UserID = GetEventInt(h_Event, "victim")
	else if (GetEventInt(h_Event, "subject"))
		i_UserID = GetEventInt(h_Event, "subject")
	
	i_Client = GetClientOfUserId(i_UserID)
	
	//if (g_PlayerIncapacitated[i_Client])
	
	if(IncapType[i_Client]!= INCAP_RIDE)
	{
		g_b_AllowThrow[i_Client] = false	
	}	
	else
	{
		g_b_AllowThrow[i_Client] = true
	}
}

public Action:EventReviveSuccess(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client, i_Weapon
	
	i_UserID = GetEventInt(h_Event, "subject")
	i_Client = GetClientOfUserId(i_UserID)
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled
	
	i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset)
	
	if (i_Weapon != -1)
		SetPlayerWeaponModel(i_Client, i_Weapon)
	
	g_PlayerIncapacitated[i_Client] = NONE
	//g_b_AllowThrow[i_Client] = false
	
	return Plugin_Continue
}

public SetPlayerWeaponModel(i_Client, i_Weapon)
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

public Action:DelayCheckPlayer(Handle:h_Timer, any:victim)
{
	if (victim < 0 || !IsClientInGame(victim))
		return Plugin_Continue
	
	
	if	(GetGrenadeOnIncap(victim) > 0 && (IncapType[victim]== INCAP_RIDE) )
	{
		
		g_b_AllowThrow[victim] = true
		
	}
	else
	{
		g_b_AllowThrow[victim] = false
	}
	
	return Plugin_Continue
}

public Action:Timer_RoundEnd(Handle:Timer, any:client)
{
	if (GetConVarInt(L4d2_drug_boost_on))
	{
		if (g_usedhealth[client] == 1)
		{
			KillTimer(g_powerups_countdown[client])
			KillTimer(g_powerups_timer[client])
			//PrintToChat(client, "\x04[SM] \x01Returning to normal...");
			PrintHintText(client, "Returning to normal...");
			g_usedhealth[client] = 0
		}
		
		if (g_got_burnt[client] == 1)
		{
			KillTimer(g_burning_countdown[client])
			KillTimer(g_molotov_timer[client])
			//PrintToChat(client, "\x04[SM] \x01Returning to normal...");
			PrintHintText(client, "Returning to normal...");
			g_got_burnt[client] = 0
		}
		
		if (g_got_biled[client] == 1)
		{
			KillTimer(g_biled_countdown[client])
			KillTimer(g_bile_timer[client])
			//PrintToChat(client, "\x04[SM] \x01Returning to normal...");
			PrintHintText(client, "Returning to normal...");
			g_got_biled[client] = 0
		}
		
	}
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

public OnMapStart()
{
	g_PipebombModel = PrecacheModel(MODEL_V_PIPEBOMB, true)
	g_MolotovModel = PrecacheModel(MODEL_V_MOLOTOV, true)
	
	if (!IsModelPrecached(MODEL_PROPANE))
		PrecacheModel(MODEL_PROPANE, true)
	if (!IsModelPrecached(MODEL_GASCAN))
		PrecacheModel(MODEL_GASCAN, true)
	if (!IsModelPrecached(MODEL_W_PIPEBOMB))
		PrecacheModel(MODEL_W_PIPEBOMB, true)
	if (!IsModelPrecached(MODEL_W_MOLOTOV))
		PrecacheModel(MODEL_W_MOLOTOV, true)
	
	if (!IsSoundPrecached(SOUND_PIPEBOMB))
		PrecacheSound(SOUND_PIPEBOMB, true)
	if (!IsSoundPrecached(SOUND_MOLOTOV))
		PrecacheSound(SOUND_MOLOTOV, true)
	
	
	//PrecacheParticle(PARTICLE_DEATH);
	g_PistolModel = PrecacheModel(MODEL_V_PISTOL_2, true)
	g_DualPistolModel = PrecacheModel(MODEL_V_DUALPISTOL_2, true)
	g_MagnumModel = PrecacheModel(MODEL_V_MAGNUM, true)
	g_VomitjarModel = PrecacheModel(MODEL_V_VOMITJAR, true)
	
	if (!IsModelPrecached(MODEL_W_VOMITJAR))
		PrecacheModel(MODEL_W_VOMITJAR, true)
	
	if (!IsSoundPrecached(SOUND_VOMITJAR))
		PrecacheSound(SOUND_VOMITJAR, true)
}

public OnMapEnd()
{
	CreateTimer(10.0, MapEndCheck);
}

public Action:MapEndCheck(Handle:timer, any:client)
{
	//Paint(client);
	return Plugin_Handled;
}

public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		//new client = GetClientOfUserId(GetEventInt(event, "userid"));
		//Paint(client);
	}
}

stock Paint_human_one(client)//YELLOW
{
	if(IsClientInGame(client))
	{
		decl String:Model[150], String:Color[50];
		
		GetClientModel(client, Model, sizeof(Model));
		
		
		if(StrContains(Model, "mechanic", false) > -1)//Since you'll spawn only once as survivor
			GetConVarString(Ellis, Color, sizeof(Color));
		
		else if(StrContains(Model, "coach", false) > -1)
			GetConVarString(Ellis, Color, sizeof(Color));
		
		else if(StrContains(Model, "producer", false) > -1)
			GetConVarString(Ellis, Color, sizeof(Color));
		
		else if(StrContains(Model, "gambler", false) > -1)
			GetConVarString(Ellis, Color, sizeof(Color));
		
		//else if(StrContains(Model, "jockey", false) > -1)
		
		//GetConVarString(rochelle, Color, sizeof(Color));
		
		else
		{
			LogMessage("Unknown Model: %s is invalid", Model); //Logs the Model for future improvements
			return;//The witch can be colored now!
		}
		if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
		{
			SetEntityRenderMode(client, RenderMode:GetConVarInt(Render));
			DispatchKeyValue(client, "rendercolor", Color);
		}
	}
}

stock Paint_human_two(client)//BLACK
{
	if(IsClientInGame(client))
	{
		decl String:Model[150], String:Color[50];
		
		GetClientModel(client, Model, sizeof(Model));
		
		if(StrContains(Model, "mechanic", false) > -1)//Since you'll spawn only once as survivor
			GetConVarString(Coach, Color, sizeof(Color));
		
		else if(StrContains(Model, "coach", false) > -1)
			GetConVarString(Coach, Color, sizeof(Color));
		
		else if(StrContains(Model, "producer", false) > -1)
			GetConVarString(Coach, Color, sizeof(Color));
		
		else if(StrContains(Model, "gambler", false) > -1)
			GetConVarString(Coach, Color, sizeof(Color));
		
		//else if(StrContains(Coach, "jockey", false) > -1)
		
		//GetConVarString(Coach, Color, sizeof(Color));
		
		else
		{
			LogMessage("Unknown Model: %s is invalid", Model); //Logs the Model for future improvements
			return;//The witch can be colored now!
		}
		if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
		{
			SetEntityRenderMode(client, RenderMode:GetConVarInt(Render));
			DispatchKeyValue(client, "rendercolor", Color);
		}
	}
}

stock Paint_human_three(client)//RED
{
	if(IsClientInGame(client))
	{
		decl String:Model[150], String:Color[50];
		
		GetClientModel(client, Model, sizeof(Model));
		
		if(StrContains(Model, "mechanic", false) > -1)//Since you'll spawn only once as survivor
			GetConVarString(rochelle, Color, sizeof(Color));
		
		else if(StrContains(Model, "coach", false) > -1)
			GetConVarString(rochelle, Color, sizeof(Color));
		
		else if(StrContains(Model, "producer", false) > -1)
			GetConVarString(rochelle, Color, sizeof(Color));
		
		else if(StrContains(Model, "gambler", false) > -1)
			GetConVarString(rochelle, Color, sizeof(Color));
		
		//else if(StrContains(Model, "jockey", false) > -1)
		
		//GetConVarString(rochelle, Color, sizeof(Color));
		
		else
		{
			LogMessage("Unknown Model: %s is invalid", Model); //Logs the Model for future improvements
			return;//The witch can be colored now!
		}
		if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
		{
			SetEntityRenderMode(client, RenderMode:GetConVarInt(Render));
			DispatchKeyValue(client, "rendercolor", Color);
		}
	}
}

stock Paint_human_four(client)//GREEN
{
	if(IsClientInGame(client))
	{
		decl String:Model[150], String:Color[50];
		
		GetClientModel(client, Model, sizeof(Model));
		
		if(StrContains(Model, "mechanic", false) > -1)//Since you'll spawn only once as survivor
			GetConVarString(Nick, Color, sizeof(Color));
		
		else if(StrContains(Model, "coach", false) > -1)
			GetConVarString(Nick, Color, sizeof(Color));
		
		else if(StrContains(Model, "producer", false) > -1)
			GetConVarString(Nick, Color, sizeof(Color));
		
		else if(StrContains(Model, "gambler", false) > -1)
			GetConVarString(Nick, Color, sizeof(Color));
		
		//else if(StrContains(Model, "jockey", false) > -1)
		
		//GetConVarString(rochelle, Color, sizeof(Color));
		
		else
		{
			LogMessage("Unknown Model: %s is invalid", Model); //Logs the Model for future improvements
			return;//The witch can be colored now!
		}
		if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
		{
			SetEntityRenderMode(client, RenderMode:GetConVarInt(Render));
			DispatchKeyValue(client, "rendercolor", Color);
		}
	}
}

stock Paint(client)
{
	if(IsClientInGame(client))
	{
		decl String:Model[150], String:Color[50];
		
		GetClientModel(client, Model, sizeof(Model));
		
		if(StrContains(Model, "mechanic", false) > -1)//Since you'll spawn only once as survivor
			GetConVarString(Ellis, Color, sizeof(Color));
		
		else if(StrContains(Model, "coach", false) > -1)
			GetConVarString(Coach, Color, sizeof(Color));
		
		else if(StrContains(Model, "producer", false) > -1)
			GetConVarString(rochelle, Color, sizeof(Color));
		
		else if(StrContains(Model, "gambler", false) > -1)
			GetConVarString(Nick, Color, sizeof(Color));
		
		//else if(StrContains(Model, "jockey", false) > -1)
		
		//GetConVarString(rochelle, Color, sizeof(Color));
		
		else
		{
			LogMessage("Unknown Model: %s is invalid", Model); //Logs the Model for future improvements
			return;//The witch can be colored now!
		}
		if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
		{
			SetEntityRenderMode(client, RenderMode:GetConVarInt(Render));
			DispatchKeyValue(client, "rendercolor", Color);
		}
	}
}


stock Paint_one(client)
{
	if(IsClientInGame(client))
	{
		decl String:Model[150], String:Color[50];
		
		GetClientModel(client, Model, sizeof(Model));
		//PrintToChatAll("%N has been be painted RED",client);
		
		//if(StrContains(Model, "mechanic", false) > -1)//Since you'll spawn only once as survivor
		GetConVarString(Ellis, Color, sizeof(Color));
		
		//else if(StrContains(Model, "coach", false) > -1)
		GetConVarString(Coach, Color, sizeof(Color));
		
		//else if(StrContains(Model, "producer", false) > -1)
		GetConVarString(rochelle, Color, sizeof(Color));
		
		//else if(StrContains(Model, "gambler", false) > -1)
		GetConVarString(Nick, Color, sizeof(Color));
		
		if(StrContains(Model, "jockey", false) > -1)
			
		GetConVarString(Nick, Color, sizeof(Color));
		//
		
		
		else
		{
			LogMessage("Unknown Model: %s is invalid", Model); //Logs the Model for future improvements
			return;//The witch can be colored now!
		}
		if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
		{
			SetEntityRenderMode(client, RenderMode:GetConVarInt(Render));
			DispatchKeyValue(client, "rendercolor", Color);
		}
	}
}



stock Paint_two(client)
{
	if(IsClientInGame(client))
	{
		decl String:Model[150], String:Color[50];
		
		GetClientModel(client, Model, sizeof(Model));
		//PrintToChatAll("%N has been be painted GREEN",client);
		//if(StrContains(Model, "mechanic", false) > -1)//Since you'll spawn only once as survivor
		//	GetConVarString(Ellis, Color, sizeof(Color));
		
		//else if(StrContains(Model, "coach", false) > -1)
		//	GetConVarString(Coach, Color, sizeof(Color));
		
		//else if(StrContains(Model, "producer", false) > -1)
		//	GetConVarString(rochelle, Color, sizeof(Color));
		
		//else if(StrContains(Model, "gambler", false) > -1)
		//	GetConVarString(Nick, Color, sizeof(Color));
		
		if(StrContains(Model, "jockey", false) > -1)
			
		GetConVarString(rochelle, Color, sizeof(Color));
		
		else
		{
			LogMessage("Unknown Model: %s is invalid", Model); //Logs the Model for future improvements
			return;//The witch can be colored now!
		}
		if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
		{
			SetEntityRenderMode(client, RenderMode:GetConVarInt(Render));
			DispatchKeyValue(client, "rendercolor", Color);
		}
	}
}


stock Paint_three(client)
{
	if(IsClientInGame(client))
	{
		decl String:Model[150], String:Color[50];
		
		GetClientModel(client, Model, sizeof(Model));
		//PrintToChatAll("%N has been be painted BLACK",client);
		//if(StrContains(Model, "mechanic", false) > -1)//Since you'll spawn only once as survivor
		//	GetConVarString(Ellis, Color, sizeof(Color));
		
		//else if(StrContains(Model, "coach", false) > -1)
		//	GetConVarString(Coach, Color, sizeof(Color));
		
		//else if(StrContains(Model, "producer", false) > -1)
		//	GetConVarString(rochelle, Color, sizeof(Color));
		
		//else if(StrContains(Model, "gambler", false) > -1)
		//	GetConVarString(Nick, Color, sizeof(Color));
		
		if(StrContains(Model, "jockey", false) > -1)
			
		GetConVarString(Ellis, Color, sizeof(Color));
		
		else
		{
			LogMessage("Unknown Model: %s is invalid", Model); //Logs the Model for future improvements
			return;//The witch can be colored now!
		}
		if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
		{
			SetEntityRenderMode(client, RenderMode:GetConVarInt(Render));
			DispatchKeyValue(client, "rendercolor", Color);
		}
	}
}


stock Paint_four(client)
{
	if(IsClientInGame(client))
	{
		decl String:Model[150], String:Color[50];
		
		GetClientModel(client, Model, sizeof(Model));
		//PrintToChatAll("%N has been be painted YELLOW",client);
		//if(StrContains(Model, "mechanic", false) > -1)//Since you'll spawn only once as survivor
		//	GetConVarString(Ellis, Color, sizeof(Color));
		
		//else if(StrContains(Model, "coach", false) > -1)
		//	GetConVarString(Coach, Color, sizeof(Color));
		
		//else if(StrContains(Model, "producer", false) > -1)
		//	GetConVarString(rochelle, Color, sizeof(Color));
		
		//else if(StrContains(Model, "gambler", false) > -1)
		//	GetConVarString(Nick, Color, sizeof(Color));
		
		if(StrContains(Model, "jockey", false) > -1)
			
		GetConVarString(Coach, Color, sizeof(Color));
		
		else
		{
			LogMessage("Unknown Model: %s is invalid", Model); //Logs the Model for future improvements
			return;//The witch can be colored now!
		}
		if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
		{
			SetEntityRenderMode(client, RenderMode:GetConVarInt(Render));
			DispatchKeyValue(client, "rendercolor", Color);
		}
	}
}

public Action:SlowJockey(Handle:timer, any:attacker)
{
	SetEntDataFloat(attacker, LagMovement, 0.5, true);
}


public Action:SlowHuman(Handle:timer, any:victim)
{
	SetEntDataFloat(victim, LagMovement, 0.5, true);
}

public Action:FastHuman(Handle:timer, any:victim)
{
	SetEntDataFloat(victim, LagMovement, 1.0, true);
}

