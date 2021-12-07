#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#define PLUGIN_VERSION "1.2.6.1"
#define TICKS 3
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
new ZOMBIECLASS_TANK=5;

new upgradekillcount[MAXPLAYERS+1];
new totalkillcount[MAXPLAYERS+1];

new bullet_tripmine[MAXPLAYERS+1];
new bullet_interaction[MAXPLAYERS+1];
new bullet_smg[MAXPLAYERS+1];
new bullet_rifle[MAXPLAYERS+1];
new bullet_hunting_rifle[MAXPLAYERS+1];
new bullet_shotgun[MAXPLAYERS+1];
new bullet_tnt[MAXPLAYERS+1];
new bullet_flame[MAXPLAYERS+1];
new bool:bd[MAXPLAYERS+1];
new control[MAXPLAYERS+1];
new Float:bullettime[MAXPLAYERS+1];


new GrenadeLauncher[MAXPLAYERS+1];
 
new Handle:tnt_plant_timer[MAXPLAYERS+1];
new Handle:tnt_defuse_timer[MAXPLAYERS+1];
new tnt_planted[MAXPLAYERS+1];
new Float:tnt_pos[MAXPLAYERS+1][3];
new Float:tnt_optick[MAXPLAYERS+1];

new Handle:tripmine_timer[MAXPLAYERS+1];
new Float:tripmine_pos[MAXPLAYERS+1][6];
new tripmine_planted[MAXPLAYERS+1];
new Float:tripmine_time[MAXPLAYERS+1];

new Handle:msgTimer = INVALID_HANDLE;

new Handle:w_killcountsetting ;
new Handle:w_killcountforSI ;
new Handle:w_killshow ;

new Handle:w_enable_tripmine ;
new Handle:w_enable_interaction ;
new Handle:w_enable_smg ;
new Handle:w_enable_rifle ;
new Handle:w_enable_hunting_rifle ;
new Handle:w_enable_shotgun ;
new Handle:w_enable_tnt ;
new Handle:w_enable_flame ;

 
new Handle:w_radius_smg;
new Handle:w_radius_rifle;
new Handle:w_radius_hunting_rifle 
new Handle:w_radius_shotgun ;
new Handle:w_radius_tripmine;
new Handle:w_radius_tnt ;
 
new Handle:w_explode_smg ;
new Handle:w_explode_rifle;
new Handle:w_explode_hunting_rifle ;
new Handle:w_explode_shotgun ;
new Handle:w_explode_tnt ;
new Handle:w_explode_tripmine;

new Handle:w_pushforce_mode ;
new Handle:w_pushforce_vlimit ;
new Handle:w_pushforce_factor ;
new Handle:w_pushforce_tankfactor ;
new Handle:w_pushforce_survivorfactor ;


 
new Handle:w_pushforce_smg;
new Handle:w_pushforce_rifle;
new Handle:w_pushforce_hunting_rifle 
new Handle:w_pushforce_shotgun ;
new Handle:w_pushforce_tnt ;
new Handle:w_pushforce_tripmine ;
 
new Handle:w_damage_smg ;
new Handle:w_damage_rifle ;
new Handle:w_damage_hunting_rifle 
new Handle:w_damage_shotgun ;
new Handle:w_damage_tnt ;
new Handle:w_damage_tripmine ;

new Handle:w_delay ;
new Handle:w_delay2 ;
new Handle:w_offset ;
 
new Handle:w_flame_radius ;
new Handle:w_flame_distance ;
new Handle:w_flame_damage ;
new Handle:w_flame_damage2 ;
new Handle:w_flame_life ;
new Handle:w_flame_fire ;
 
new Handle:w_tank_clow ;
new Handle:w_tank_throw ;

new Handle:w_laugch_force ;
new Handle:w_tripmine_duration ;
new Handle:w_tripmine_length ;
new Handle:w_msgtime ;

new Handle:w_start_point;

new Handle:w_shot_laser ;
new Handle:w_shot_laser_offset ;

new Handle:w_shot_laser_red ;
new Handle:w_shot_laser_green ;
new Handle:w_shot_laser_blue ;

new Handle:w_shot_laser_alpha;
new Handle:w_shot_laser_life ;
new Handle:w_shot_laser_width ;
new Handle:w_shot_laser_width2 ;

new Handle:w_key_flame;
new Handle:w_key_grab;
new Handle:w_key_tntstart;
new Handle:w_key_tntplant;
new Handle:w_key_tripmine; 

 

new Handle:w_tnt_time ;
new Handle:w_tnt_time2 ;

new Handle:gTimer; 

new ThrowEntity[MAXPLAYERS+1]; 
new Float:ThrowState[MAXPLAYERS+1]; 
new Handle:FlameHandle[MAXPLAYERS+1]; 
new Handle:ZBHandle[MAXPLAYERS+1]; 
new Float:ZBPos[MAXPLAYERS+1][3]; 
new ZBTick[MAXPLAYERS+1] ; 
 

 
new Handle:w_grab_speed = INVALID_HANDLE;
new Handle:w_grab_mindistance = INVALID_HANDLE; 
new Handle:w_grab_groundmode = INVALID_HANDLE;
new Handle:w_grab_energetime = INVALID_HANDLE;
new Handle:w_grab_throwspeed = INVALID_HANDLE;
new Handle:w_grab_maxdistance = INVALID_HANDLE;
new Handle:w_autobind = INVALID_HANDLE;
new Handle:w_versus = INVALID_HANDLE;
 
new g_iVelocity;
new GameMode; 
new bool:L4D2Version=false;

#define SOUND_BLIP		"UI/Beep07.wav"
#define SOUND_BLIP2		"buttons/blip2.wav"
#define SOUND_GRAB		"UI/helpful_event_1.wav"
#define SOUND_FLAME		"weapons/molotov/fire_loop_1.wav"
#define SOUND_BOOM		"weapons/explode3.wav"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define SOUND_PIPEBOMB  "weapons/hegrenade/beep.wav"

 
new g_BeamSprite;
new g_HaloSprite;

 
new redColor[4]		= {255, 75, 75, 255};
new greyColor[4]	= {128, 128, 128, 255};


public Plugin:myinfo = 
{
	name = "Special Weapon",
	author = "Pan Xiaohai",
	description = "Special Weapon",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart()
{
	CreateConVar("l4d_weapon_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	

	w_killcountsetting= CreateConVar("l4d_weapon_killcountsetting", "30", "How much Infected a Player has to shoot to win a special weapon.", FCVAR_PLUGIN); 	
	w_killcountforSI= CreateConVar("l4d_weapon_killcountforSI", "3", "How many Common Infected = a Special Infected", FCVAR_PLUGIN); 	
	w_start_point = CreateConVar("l4d_weapon_start_point", "2", "start point for every special weapon", FCVAR_PLUGIN);	
	w_killshow= CreateConVar("l4d_weapon_killshow", "2", "show msg when get special weapon, 0:diable, 1, chat, 2, chat all, 3, Hint box ", FCVAR_PLUGIN); 		
	
	w_enable_tripmine = CreateConVar("l4d_weapon_enable_tripmine", "1", "tripmine , 0:disable, 1:enable", FCVAR_PLUGIN); 	
	w_enable_interaction = CreateConVar("l4d_weapon_enable_interaction", "1", "interaction", FCVAR_PLUGIN);
	w_enable_smg = CreateConVar("l4d_weapon_enable_smg", "1", "smg", FCVAR_PLUGIN);
	w_enable_rifle = CreateConVar("l4d_weapon_enable_rifle", "1", "rifle", FCVAR_PLUGIN);
	w_enable_hunting_rifle = CreateConVar("l4d_weapon_enable_hunting_rifle", "1", "hunting_rifle", FCVAR_PLUGIN);
	w_enable_shotgun = CreateConVar("l4d_weapon_enable_shotgun", "1", "shotgun", FCVAR_PLUGIN);
	w_enable_tnt = CreateConVar("l4d_weapon_enable_tnt", "1", "TNT", FCVAR_PLUGIN);
	w_enable_flame = CreateConVar("l4d_weapon_enable_flame", "1", "flame", FCVAR_PLUGIN);

	w_tnt_time = CreateConVar("l4d_weapon_tnt_time", "5", "tnt plant time", FCVAR_PLUGIN);
	w_tnt_time2 = CreateConVar("l4d_weapon_tnt_time2", "3", "tnt defuse time", FCVAR_PLUGIN);

 	w_radius_smg = CreateConVar("l4d_weapon_radius_smg", "200", "damage radius for smg", FCVAR_PLUGIN);
	w_radius_rifle = CreateConVar("l4d_weapon_radius_rifle", "280", "damage radius for rifle", FCVAR_PLUGIN);
	w_radius_hunting_rifle = CreateConVar("l4d_weapon_radius_hunting_rifle", "340", "damage radius for huntting rifle", FCVAR_PLUGIN);
	w_radius_shotgun = CreateConVar("l4d_weapon_radius_shotgun", "250", "damage radius for smg shotgun", FCVAR_PLUGIN);
	w_radius_tnt = CreateConVar("l4d_weapon_radius_tnt", "450", "damage radius for smg", FCVAR_PLUGIN);
	w_radius_tripmine = CreateConVar("l4d_weapon_radius_tripmine", "100", "damage radius for tripmine", FCVAR_PLUGIN);
	
 	w_explode_smg = CreateConVar("l4d_weapon_explode_smg", "0", "weather explode for smg", FCVAR_PLUGIN);
	w_explode_rifle = CreateConVar("l4d_weapon_explode_rifle", "1", "weather explode for rifle", FCVAR_PLUGIN);
	w_explode_hunting_rifle = CreateConVar("l4d_weapon_explode_hunting_rifle", "1", "weather explode for hunting_rifle", FCVAR_PLUGIN);
	w_explode_shotgun = CreateConVar("l4d_weapon_explode_shotgun", "1", "weather explode for shotgun", FCVAR_PLUGIN);
	w_explode_tnt = CreateConVar("l4d_weapon_explode_tnt", "1", "weather explode for TNT", FCVAR_PLUGIN);
	w_explode_tripmine = CreateConVar("l4d_weapon_explode_tripmine", "3", "0: nothing, 1: explode , 2: show paticle, 3:show spark, 4:disovle;  for tripmine", FCVAR_PLUGIN);
	
 	w_pushforce_smg = CreateConVar("l4d_weapon_pushforce_smg", "600", "pushforce for smg", FCVAR_PLUGIN);
	w_pushforce_rifle = CreateConVar("l4d_weapon_pushforce_rifle", "1200", "pushforce for rifle", FCVAR_PLUGIN);
	w_pushforce_hunting_rifle = CreateConVar("l4d_weapon_pushforce_hunting_rifle", "1400", "pushforce for hunting_rifle", FCVAR_PLUGIN);
	w_pushforce_shotgun = CreateConVar("l4d_weapon_pushforce_shotgun", "1200", "pushforce for shotgun", FCVAR_PLUGIN);
	w_pushforce_tnt = CreateConVar("l4d_weapon_pushforce_tnt", "1800", "pushforce for TNT", FCVAR_PLUGIN);
	w_pushforce_tripmine = CreateConVar("l4d_weapon_pushforce_tripmine", "800", "pushforce for tripmine", FCVAR_PLUGIN);
	
	w_pushforce_mode = CreateConVar("l4d_weapon_pushforce_mode", "3", "pushforce mode 0:disable, 1:mode one, 2:mode two, 3: both", FCVAR_PLUGIN);
	w_pushforce_vlimit = CreateConVar("l4d_weapon_pushforce_vlimit", "200", "voilicity limit", FCVAR_PLUGIN);
	w_pushforce_factor = CreateConVar("l4d_weapon_pushforce_factor", "0.8", "pushforce factor", FCVAR_PLUGIN);
	w_pushforce_tankfactor = CreateConVar("l4d_weapon_pushforce_tankfactor", "0.15", "pushforce factor for Tank", FCVAR_PLUGIN);
	w_pushforce_survivorfactor = CreateConVar("l4d_weapon_pushforce_survivorfactor", "0.4", "pushforce factor for Survivors", FCVAR_PLUGIN);

 	w_damage_smg = CreateConVar("l4d_weapon_damage_smg", "500", "damage for smg", FCVAR_PLUGIN);
	w_damage_rifle = CreateConVar("l4d_weapon_damage_rifle", "800", "damage for rifle", FCVAR_PLUGIN);
	w_damage_hunting_rifle = CreateConVar("l4d_weapon_damage_hunting_rifle", "1000", "damage for hunting_rifle", FCVAR_PLUGIN);
	w_damage_shotgun = CreateConVar("l4d_weapon_damage_shotgun", "500", "damage for shotgun", FCVAR_PLUGIN);
	w_damage_tnt = CreateConVar("l4d_weapon_damage_tnt", "1000", "damage for TNT", FCVAR_PLUGIN);
	w_damage_tripmine = CreateConVar("l4d_weapon_damage_tripmine", "400", "damage for tripmine", FCVAR_PLUGIN);
	
 
	w_flame_radius = CreateConVar("l4d_weapon_flame_radius", "50", "flame radius", FCVAR_PLUGIN);
	w_flame_distance = CreateConVar("l4d_weapon_flame_distance", "600", "flame length", FCVAR_PLUGIN);
	w_flame_damage = CreateConVar("l4d_weapon_flame_damage", "10", "flame damage per 0.1 second", FCVAR_PLUGIN);
	w_flame_damage2 = CreateConVar("l4d_weapon_flame_damage2", "20", "flame damage per 0.1 second", FCVAR_PLUGIN);
	w_flame_life = CreateConVar("l4d_weapon_flame_life", "5", "flame time", FCVAR_PLUGIN);
	w_flame_fire = CreateConVar("l4d_weapon_flame_fire", "1", "0:cold air, 1:flame", FCVAR_PLUGIN);
	
 
	w_delay = CreateConVar("l4d_weapon_delay", "1.0", "grenade explode delay", FCVAR_PLUGIN);
	w_delay2 = CreateConVar("l4d_weapon_delay2", "0.01", "laser gun explode delay", FCVAR_PLUGIN);
	w_offset = CreateConVar("l4d_weapon_offset", "25", "laser gun explode distance offeset", FCVAR_PLUGIN);

	w_laugch_force = CreateConVar("l4d_weapon_laugch_force", "1200.0", "grenade laugch force", FCVAR_PLUGIN);

	w_tripmine_duration = CreateConVar("l4d_weapon_tripmine_duration", "120.0", "tripmine exist time", FCVAR_PLUGIN);
	w_tripmine_length = CreateConVar("l4d_weapon_tripmine_length", "800.0", "tripmine length", FCVAR_PLUGIN);
	
	
 	w_msgtime = CreateConVar("l4d_weapon_msgtime", "40", "message time", FCVAR_PLUGIN);
 
	w_shot_laser = CreateConVar("l4d_weapon_shot_laser", "1", "laser gun tracker , 0 :disable , 1: enable ", FCVAR_NOTIFY);
	w_shot_laser_offset = CreateConVar("l4d_weapon_shot_laser_offset", "36", " tracker offeset", FCVAR_NOTIFY);

	w_shot_laser_red = CreateConVar("l4d_weapon_shot_laser_red", "200", "laser_red");
	w_shot_laser_green = CreateConVar("l4d_weapon_shot_laser_green", "0", "laser_green");
	w_shot_laser_blue = CreateConVar("l4d_weapon_shot_laser_blue", "0", "laser_blue");

	w_shot_laser_alpha = CreateConVar("l4d_weapon_shot_laser_alpha", "230", "laser_alpha");
	w_shot_laser_life = CreateConVar("l4d_weapon_shot_laser_life", "0.75", "laser_life");
	w_shot_laser_width = CreateConVar("l4d_weapon_shot_laser_width", "10.0", "laser_width");
	w_shot_laser_width2 = CreateConVar("l4d_weapon_shot_laser_width2", "4.0", "laser_width in l4d2");
 
	w_grab_speed = CreateConVar("l4d_weapon_grab_speed", "10.0", "grab speed");
	w_grab_mindistance = CreateConVar("l4d_weapon_grab_mindistance", "64.0", "min distance");
 	w_grab_groundmode = CreateConVar("l4d_weapon_grab_groundmode", "0", "on grounde mode");
	w_grab_energetime = CreateConVar("l4d_weapon_grab_energetime", "10.0", "grab energe");
	w_grab_throwspeed = CreateConVar("l4d_weapon_grab_throwspeed", "1000.0", "throw speed");
	w_grab_maxdistance = CreateConVar("l4d_weapon_grab_maxdistance", "800.0", "grab max distance");
 
	w_tank_clow = CreateConVar("l4d_weapon_tank_clow", "5", "tank's clow cause grenade");
	w_tank_throw = CreateConVar("l4d_weapon_tank_throw", "10", "tank's throw cause grenade");

	w_autobind = CreateConVar("l4d_weapon_autobind", "0", "0: say:!bind to bind or unbind keys , 1: auto bind when player put in server");
	w_versus = CreateConVar("l4d_weapon_versus", "0", "0: disable for versus, 1:enable for versus");
	
	w_key_flame = CreateConVar("l4d_weapon_key_flame", "z", "bind key for flamethrower");
	w_key_grab = CreateConVar("l4d_weapon_key_grab", "x", "bind key for special interaction");
	w_key_tntstart = CreateConVar("l4d_weapon_key_tntstart", "t", "bind key for tntstart");
	w_key_tntplant = CreateConVar("l4d_weapon_key_tntplant", "b", "bind key for tntplant");
	w_key_tripmine = CreateConVar("l4d_weapon_key_tripmine", "v", "bind key for tripmine");	

	AutoExecConfig(true, "l4d_weapon_en_v26");
 
	GameCheck();
	
	//if(GameMode==2 && GetConVarInt(l4d_weapon_versus)==0)return;
	g_iVelocity = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	HookEvent("bullet_impact", bullet_impact);
	HookEvent("weapon_fire", weapon_fire);
	HookEvent("ability_use", ability_use);

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("infected_death", Event_InfectedDeath);	
	
	HookEvent("player_spawn",PlayerSpawn);
	HookEvent("player_first_spawn", player_first_spawn);
	
	HookEvent("grenade_bounce", grenade_bounce);

	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundStart);
	HookEvent("finale_win", RoundStart);
	HookEvent("mission_lost", RoundStart);
	HookEvent("map_transition", RoundStart);
	
	HookEvent("player_connect_full", PlayerConnectFull);
 
 	RegConsoleCmd("sm_bullet", sm_bullet);
 
	RegConsoleCmd("sm_tntplant", sm_plant);
 	RegConsoleCmd("sm_tntstart", sm_start);

	RegAdminCmd("sm_addbullet",sm_addbullet,ADMFLAG_KICK, "sm_addbullet");
	RegAdminCmd("sm_resetbullet",sm_resetbullet,ADMFLAG_KICK, "sm_resetbullet");

	RegConsoleCmd("sm_grab", sm_grab);
	RegConsoleCmd("sm_flame", sm_flame);
	
	RegConsoleCmd("sm_tripmine", sm_tripmine);
	
	RegConsoleCmd("sm_selfkill", selfkill);
	RegConsoleCmd("sm_bind", sm_bind);

	return;
 
}
GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}
	
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		ZOMBIECLASS_TANK=8;
		L4D2Version=true;
	}	
	else
	{
		ZOMBIECLASS_TANK=5;
		L4D2Version=false;
	}
}
public OnMapStart()
{
	InitPrecache();
 	gTimer = CreateTimer(0.1, UpdateObjects, INVALID_HANDLE, TIMER_REPEAT);
	msgTimer=CreateTimer(GetConVarFloat(w_msgtime), Msg, 0, TIMER_REPEAT);

}
public OnMapEnd()
{
 	CloseHandle(gTimer);
	CloseHandle(msgTimer);
}
public OnConfigsExecuted()
{
	InitPrecache();
}
 
#define KILL_EXPLODE1 "weapons/hegrenade/explode3.wav"
new g_sprite;

 InitPrecache()
{
	/* Precache model */
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
	PrecacheModel("models/props_junk/gascan001a.mdl", true);
	 
	PrecacheParticle("gas_explosion_pump");
	PrecacheParticle("gas_explosion_main");
	PrecacheParticle("weapon_pipebomb");
	PrecacheParticle("chopper_spotlight");
	PrecacheSound(KILL_EXPLODE1, true);
	PrecacheSound(SOUND_PIPEBOMB, true) ;

	PrecacheSound(SOUND_BLIP, true);
	PrecacheSound(SOUND_GRAB, true);
	PrecacheSound(SOUND_FLAME, true);
	PrecacheSound(SOUND_BOOM, true);
	PrecacheSound(SOUND_FREEZE, true);

 	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
		g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
		g_HaloSprite = PrecacheModel("materials/dev/halo_add_to_screen.vmt");		
		PrecacheModel("models/w_models/weapons/w_HE_grenade.mdl", true);	
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
		g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
		g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");	
		PrecacheModel("models/w_models/weapons/w_eq_molotov.mdl", true);	
	}

 
	ResetAllState();
	
}
 public OnClientPutInServer(client)
 {
	if(client && !IsFakeClient(client))
	{
		ResetClientState(client);
	}
}
ResetClientState(client)
{
	ThrowState[client]=0.0;
	ThrowEntity[client] = -1;
	FlameHandle[client]=INVALID_HANDLE;
	ZBHandle[client]=INVALID_HANDLE;
	tnt_planted[client]=0;
	tripmine_planted[client]=0;
	RemoveControl(client);
	SetBullet(client, GetConVarInt(w_start_point));
	
}
ResetAllState()
{
	for (new x = 0; x < MAXPLAYERS+1; x++)
	{
		ResetClientState(x);
	}
}

new msgp=0;

public Action:Msg(Handle:timer, any:data)
{
	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Continue; 
	if(msgp>5)msgp=0;
	if(msgp==0)PrintToChatAll("\x03Special Weapon, use it with caution, \x04!bind \x03to bind keys");
	if(msgp==1)PrintToChatAll("\x03Holding \x04USE\x03 key when fire will get into \x04special weapon mode, \x03say:\x04!bullet \x03to show information");
	if(msgp==2)
	{
		decl String:key1[10];
		GetConVarString(w_key_tntplant, key1, 10);
		decl String:key2[10];
		GetConVarString(w_key_tntstart, key2, 10);
		PrintToChatAll("\x03Press \x04[%s] \x03to plant or defuse TNT,\x04[%s] \x03to detonate TNT", key1, key2);
	}
	if(msgp==3)
	{
		decl String:key1[10];
		GetConVarString(w_key_grab, key1, 10);
		decl String:key2[10];
		GetConVarString(w_key_flame, key2, 10);		
		PrintToChatAll("\x03Press \x04[%s] \x03to special interaction,\x04[%s] \x03to flamethrower", key1, key2);
	}
	if(msgp==4)
	{
		decl String:key1[10];
		GetConVarString(w_key_tripmine, key1, 10);
			
		PrintToChatAll("\x03Press \x04[%s] \x03to plant or defuse tripmine", key1);
	}
 	if(msgp==5)PrintToChatAll("\x03say:\x04!selfkill \x03to suicide");
	msgp++;
 	return Plugin_Continue;
}

public Action:sm_bullet(userid, args)
{
	if (userid == 0 || GetClientTeam(userid) != 2 || !IsPlayerAlive(userid))
		return Plugin_Handled;
 
	new pistol=0;
	new point=0;
 	point=GetConVarInt(w_enable_interaction);
	if(point>0)pistol=bullet_interaction[userid];

	new tripmine=0;
 	point=GetConVarInt(w_enable_tripmine);
	if(point>0)tripmine=bullet_tripmine[userid];
	
	new msg=0;
 	point=GetConVarInt(w_enable_smg); 
	if(point>0)msg=bullet_smg[userid];
	
	new shotgun=0;
 	point=GetConVarInt(w_enable_shotgun);
	if(point>0)shotgun=bullet_shotgun[userid];
	
	new rifle=0;
 	point=GetConVarInt(w_enable_rifle);
	if(point>0)rifle=bullet_rifle[userid];				
	
	new hunting_rifle=0;
 	point=GetConVarInt(w_enable_hunting_rifle);
	if(point>0)hunting_rifle=bullet_hunting_rifle[userid];
	
	new tnt=0;
 	point=GetConVarInt(w_enable_tnt);
	if(point>0)tnt=bullet_tnt[userid];

	new flame=0;
 	point=GetConVarInt(w_enable_flame);
	if(point>0)flame=bullet_flame[userid];

 	decl String:palyerName[64];
	GetClientName(userid, palyerName, sizeof(palyerName));
	PrintToChat(userid, "\x04%s\x03 :\x03interaction:\x04%d,\x03tripmine:\x04%d,\x03TNT:\x04%d, \x03flame:\x04%d,\x03laser gun for smg:\x04%d,\x03laser gun for rifle:\x04%d,\x03laser gun for sniper rifle:\x04%d,\x03generade:\x04%d",
	palyerName, pistol, tripmine,  tnt, flame,
	msg, rifle, hunting_rifle, shotgun);
	return Plugin_Handled;
} 
 
SetBullet(x, v)
{
	bullet_interaction[x]=v;
	bullet_smg[x]=v;
	bullet_rifle[x]=v;
	bullet_hunting_rifle[x]=v;
	bullet_shotgun[x]=v;
	bullet_tnt[x]=v;
	bullet_flame[x]=v;
	bullet_tripmine[x]=v;
}
AddBullet(x, v)
{
	bullet_interaction[x]+=v;
	bullet_smg[x]+=v;
	bullet_rifle[x]+=v;
	bullet_hunting_rifle[x]+=v;
	bullet_shotgun[x]+=v;
	bullet_tnt[x]+=v;
	bullet_flame[x]+=v;
	bullet_tripmine[x]+=v;
}
UpGrade(x, kill)
{
 	upgradekillcount[x]+=kill;
	totalkillcount[x]+=kill;
	new v=upgradekillcount[x]/GetConVarInt(w_killcountsetting);
	upgradekillcount[x]=upgradekillcount[x]%GetConVarInt(w_killcountsetting);
	
	if ((totalkillcount[x] % 15) == 0) PrintCenterText(x, "Infected killed: %d", totalkillcount[x]);
	
	//PrintToChatAll("%N kill %d, %d", x, totalkillcount[x], upgradekillcount[x]);
	if(v>0)
	{
		decl String:ammotype[64];
		new luck = GetRandomInt(1,6);  
		new p=0;
		switch(luck)
		{
			case 1:
			{
				ammotype = "TNT";
				bullet_tnt[x]+=v;
				p=bullet_tnt[x];
			}
			
			case 2:
			{
				ammotype = "Flamethrower";
				bullet_flame[x]+=v;
				p=bullet_flame[x];
			}
			
			case 3:
			{
				ammotype = "Tripmine";
				bullet_tripmine[x]+=v;
				p=bullet_tripmine[x];
			}

			case 4:
			{
				ammotype = "Grab";
				bullet_interaction[x]+=v;
				p=bullet_interaction[x];
			}
			case 5:
			{
				ammotype = "Laser gun";
				bullet_smg[x]+=v;
				bullet_rifle[x]+=v;
				bullet_hunting_rifle[x]+=v;
				p=bullet_smg[x];
				p+=bullet_rifle[x];
				p+=bullet_hunting_rifle[x];
			}
			case 6:
			{
				ammotype = "Generade";
				bullet_shotgun[x]+=v;
				p=bullet_shotgun[x];
			}
		}
		new s=GetConVarInt(w_killshow);
		if(s==1)PrintToChat(x, "\x03 you won special weapon:\x04 %s   ( %d )!", ammotype, p);
		if(s==2)PrintToChatAll("\x04%N\x03 won special weapon:\x04 %s   ( %d )!",x, ammotype, p);
		if(s==3)PrintHintText(x, "you won special weapon: %s   ( %d )!", ammotype, p);
	}
}
public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllState();
	return Plugin_Continue;
}
public Action:player_first_spawn(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
 	new userid = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (userid == 0 ) 
	{
 		return Plugin_Continue;
	}
	ResetClientState(userid);
	return Plugin_Continue;
}
 public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));

	ResetClientState(client);
	return Plugin_Continue;
}
public Action:Event_InfectedDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Continue;	
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if (attacker<=0) 
	{
 		return Plugin_Continue;
	}
	if(IsClientInGame(attacker) )
	{
		if(GetClientTeam(attacker) == 2)
		{
			UpGrade(attacker, 1);
		}
	}
 
	return Plugin_Continue;
}
public Action:Event_PlayerDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Continue;	
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
 	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if (victim <= 0 || attacker<=0) 
	{
 		return Plugin_Continue;
	}
	ThrowState[victim]=0.0;
	ThrowEntity[victim] = -1;
	RemoveControl(victim);
	if(IsClientInGame(attacker) )
	{
		if(GetClientTeam(attacker) == 2)
		{
			if(IsClientInGame(victim))
			{
				if( GetClientTeam(victim) == 3 )
				{
					new bool:headshot=GetEventBool(hEvent, "headshot");
					if(headshot)
					{
						UpGrade(attacker, GetConVarInt(w_killcountforSI)*3);
					}
					else
					{
						UpGrade(attacker, GetConVarInt(w_killcountforSI));
					}
				}
			}
		}
	}
	if(IsClientInGame(victim) && GetClientTeam(victim)==2)
	{
		SetBullet(victim, GetConVarInt(w_start_point));
	}
	return Plugin_Continue;
}

public PlayerConnectFull(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(w_versus)==0)return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetConVarInt(w_autobind)>0)bind (client, true);
	RemoveControl(client);

}
public OnClientDisconnect(client)
{
	if(GameMode==2 && GetConVarInt(w_versus)==0)return;
	if(GetConVarInt(w_autobind)>0 || bd[client])bind(client, false);
	RemoveControl(client);
 }
public Action:sm_bind(client, args)
{
	if(client>0)
	{
		if(bd[client])
		{
			PrintHintText(client, "unbind key successfully");
		}
		else
		{
			PrintHintText(client, "bind key for special weapon successfully");
		}
		bd[client]=!bd[client];
		bind(client, bd[client]);
	}
}

bind(client,bool:b)
{

	if(b)
	{
		
		decl String:key[10];	
		GetConVarString(w_key_tntplant, key, 10);
		ClientCommand(client, "bind %s \"say /tntplant\"", key);
		GetConVarString(w_key_tntstart, key, 10);
		ClientCommand(client, "bind %s \"say /tntstart\"", key);
		GetConVarString(w_key_grab, key, 10);
		ClientCommand(client, "bind %s \"say /grab\"", key);
		GetConVarString(w_key_flame, key, 10);
		ClientCommand(client, "bind %s \"say /flame\"", key);
		GetConVarString(w_key_tripmine, key, 10);
		ClientCommand(client, "bind %s \"say /tripmine\"", key);
		/*
		decl String:key[10];	
		GetConVarString(w_key_tntplant, key, 10);
		ClientCommand(client, "bind %s \"sm_tntplant\"", key);
		GetConVarString(w_key_tntstart, key, 10);
		ClientCommand(client, "bind %s \"sm_tntstart\"", key);
		GetConVarString(w_key_grab, key, 10);
		ClientCommand(client, "bind %s \"sm_grab\"", key);
		GetConVarString(w_key_flame, key, 10);
		ClientCommand(client, "bind %s \"sm_flame\"", key);
		GetConVarString(w_key_tripmine, key, 10);
		ClientCommand(client, "bind %s \"sm_tripmine\"", key);
		*/
		
		
		
	}
	else
	{
		ClientCommand(client, "bind b \"\"");
		ClientCommand(client, "bind v \"\"");
		ClientCommand(client, "bind t \"impulse 201\"");
		ClientCommand(client, "bind x \"+mouse_menu QA\"");
		ClientCommand(client, "bind z \"+mouse_menu Orders\"");
	}
}
public Action:sm_tripmine(client, args)
{
 	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Handled;
	if (!IsValidAliveClient(client) )
		return Plugin_Handled;
	if(GetClientTeam(client)!=2)return Plugin_Handled;
	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:pos[3];

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

 	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitLive);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
	}
	CloseHandle(trace)
	
	decl Float:v1[3];
	decl Float:v2[3];
	 
	SubtractVectors(vOrigin, pos, v1);
	NormalizeVector(v1, v2);
	
	ScaleVector(v2, GetConVarFloat(w_offset)*2.0);

	AddVectors(pos, v2, v1); 

	if(tripmine_planted[client]==0)
	{
		if(bullet_tripmine[client]-1<0 || GetConVarInt(w_enable_tripmine)==0)
		{
			PrintHintText(client, "need more tripmine");
			return Plugin_Handled;
		}

		tripmine_pos[client][0]=v1[0];
		tripmine_pos[client][1]=v1[1];
		tripmine_pos[client][2]=v1[2];
 
		tripmine_planted[client]=1;
 		tripmine_timer[client]=CreateTimer(0.1, TripminePlantTimer, client, TIMER_REPEAT);
		EmitAmbientSound(SOUND_BLIP, v1, client, SNDLEVEL_RAIDSIREN);	
		
	
	}
	else if (tripmine_planted[client]==1)
	{
	
		decl Float:v3[3];
	
		tripmine_pos[client][3]=v1[0];
		tripmine_pos[client][4]=v1[1];
		tripmine_pos[client][5]=v1[2];
	
		v3[0]=tripmine_pos[client][0];
		v3[1]=tripmine_pos[client][1];
		v3[2]=tripmine_pos[client][2];
	

		TR_TraceRayFilter(v3, v1, MASK_SOLID, RayType_EndPoint, TraceRayDontHitLive, client);
		if (TR_DidHit(INVALID_HANDLE))
		{
			TR_GetEndPosition(pos, INVALID_HANDLE);
			
			SubtractVectors(v3, pos, v1);
			NormalizeVector(v1, v2);
			
			ScaleVector(v2, GetConVarFloat(w_offset)*2.0);

			AddVectors(pos, v2, pos); 
			
		}
		else
		{
			pos[0]=v1[0];	
			pos[1]=v1[1];	
			pos[2]=v1[2];
		}
		
		tripmine_pos[client][3]=pos[0];
		tripmine_pos[client][4]=pos[1];
		tripmine_pos[client][5]=pos[2];
	
		
		new Float:distance = GetVectorDistance(v3, pos);

		if(distance>GetConVarFloat(w_tripmine_length) || distance<100.0)
		{
			KillTimer(tripmine_timer[client]);
			tripmine_timer[client]=INVALID_HANDLE;
			tripmine_planted[client]=0;
			PrintHintText(client, "can not exceed tripmine' length limit");
		}
		else
		{
			KillTimer(tripmine_timer[client]);
			tripmine_timer[client]=INVALID_HANDLE;
			EmitAmbientSound(SOUND_BLIP, v1, client, SNDLEVEL_RAIDSIREN);	
			tripmine_time[client]=GetEngineTime();		
			tripmine_planted[client]=2;
			bullet_tripmine[client]-=1;
			PrintHintText(client, "tripmine plante successfully");
		}
		
	}
	else if (tripmine_planted[client]==2)
	{
		
		decl Float:v3[3];
		
		v2[0]=tripmine_pos[client][0];
		v2[1]=tripmine_pos[client][1];
		v2[2]=tripmine_pos[client][2];	

		v3[0]=tripmine_pos[client][3];
		v3[1]=tripmine_pos[client][4];
		v3[2]=tripmine_pos[client][5];	

		new Float:distance1 = GetVectorDistance(v1, v2);
		new Float:distance2 = GetVectorDistance(v1, v3);
		if(distance1<250.0 || distance2<250.0)
		{
			tripmine_planted[client]=0;
			PrintHintText(client, "tripmine defuse successfully");
		}
		else
		{		
			PrintHintText(client, "you are too far from tripmine");
		}
		
		return Plugin_Handled;
		
	}
	
	return Plugin_Handled;
} 

public Action:TripminePlantTimer(Handle:timer, any:client)
{
	if (!IsValidAliveClient(client))
	{
		tripmine_planted[client]=0;
		tripmine_timer[client]=INVALID_HANDLE;
 		return Plugin_Stop;
	}
	 
	if (tripmine_planted[client]==1 )
	{

		decl Float:vAngles[3]
		decl Float:vOrigin[3]
		decl Float:pos[3]

		GetClientEyePosition(client,vOrigin)
		GetClientEyeAngles(client, vAngles)

 		new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitLive)

		if(TR_DidHit(trace))
		{
			TR_GetEndPosition(pos, trace)
		}
		CloseHandle(trace)
		
		decl Float:v1[3];
		decl Float:v2[3];
		decl Float:v3[3];
		
		SubtractVectors(vOrigin, pos, v1);
		NormalizeVector(v1, v2);
		
		ScaleVector(v2, GetConVarFloat(w_offset)*2.0);

		AddVectors(pos, v2, v1); 

		v3[0]=tripmine_pos[client][0];
		v3[1]=tripmine_pos[client][1];
		v3[2]=tripmine_pos[client][2];
		
		
		TR_TraceRayFilter(v3, v1, MASK_SOLID, RayType_EndPoint, TraceRayDontHitLive, client);
		if (TR_DidHit(INVALID_HANDLE))
		{
			TR_GetEndPosition(pos, INVALID_HANDLE);	
			
			SubtractVectors(v3, pos, v1);
			NormalizeVector(v1, v2);
			
			ScaleVector(v2, GetConVarFloat(w_offset)*2.0);

			AddVectors(pos, v2, pos);			
		}
		else
		{
			pos[0]=v1[0];	
			pos[1]=v1[1];	
			pos[2]=v1[2];
		}
		
		tripmine_pos[client][3]=pos[0];
		tripmine_pos[client][4]=pos[1];
		tripmine_pos[client][5]=pos[2];
		
		decl color[4];
		color[0] = GetConVarInt( w_shot_laser_red ); 
		color[1] = GetConVarInt( w_shot_laser_green );
		color[2] = GetConVarInt( w_shot_laser_blue );
		color[3] = GetConVarInt( w_shot_laser_alpha );
		
		new Float:life=0.1;
		
		new Float:width;
		if(L4D2Version)width = GetConVarFloat( w_shot_laser_width2 );
		else width = GetConVarFloat( w_shot_laser_width );
		
		TE_SetupBeamPoints(v3, pos, g_sprite, 0, 0, 0, life, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
		
		//PrintCenterText(client, "tripmine");
		
		if(GetVectorDistance(v3, pos)>GetConVarFloat(w_tripmine_length)*2.0)
		{
		
			tripmine_planted[client]=0;
			tripmine_timer[client]=INVALID_HANDLE;
			return Plugin_Stop;
		}
	
		return Plugin_Continue;
	}
	else
	{
		tripmine_timer[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}

}


public Action:sm_plant(client, args)
{
 	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Handled;
	if (!IsValidAliveClient(client) )
		return Plugin_Handled;
	if(GetClientTeam(client)!=2)return Plugin_Handled;
	if(tnt_planted[client]==0)
	{

		if(bullet_tnt[client]-1<0 || GetConVarInt(w_enable_tnt)==0)
		{
			PrintHintText(client, "need more TNT");
			return Plugin_Handled;
		}
		if (tnt_plant_timer[client] == INVALID_HANDLE)
		{
			
			tnt_optick[client]=0.0;

			decl Float:vAngles[3]
			decl Float:vOrigin[3]
			decl Float:pos[3]

			GetClientEyePosition(client,vOrigin)
			GetClientEyeAngles(client, vAngles)

 			new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitLive)

			if(TR_DidHit(trace))
			{
				TR_GetEndPosition(pos, trace)
			}
			CloseHandle(trace)
			
			decl Float:v1[3];
			decl Float:v2[3];
			 
			SubtractVectors(vOrigin, pos, v1);
			NormalizeVector(v1, v2);
		 
			ScaleVector(v2, GetConVarFloat(w_offset));

			AddVectors(pos, v2, v1); 

			tnt_pos[client][0]=v1[0];
			tnt_pos[client][1]=v1[1];
			tnt_pos[client][2]=v1[2];
 
 			tnt_plant_timer[client]=CreateTimer(1.0/TICKS, PlantTimer, client, TIMER_REPEAT);
		}
		else
		{
			tnt_optick[client]=0.0;
			KillTimer(tnt_plant_timer[client]);
			tnt_plant_timer[client] = INVALID_HANDLE;
			PrintHintText(client, "plant TNT interrupted");
		}
	}
	else
	{
		if (tnt_defuse_timer[client] == INVALID_HANDLE)
		{
			tnt_optick[client]=0.0;
			tnt_defuse_timer[client]=CreateTimer(1.0/TICKS, DefuseTimer, client, TIMER_REPEAT);
		}
		else
		{
			tnt_optick[client]=0.0;
			KillTimer(tnt_defuse_timer[client]);
			tnt_defuse_timer[client] = INVALID_HANDLE;
			PrintHintText(client, "defuse TNT interrupted");
		}
		
	}

	return Plugin_Handled;
}
 
public Action:sm_start(client, args)
{
	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Handled;
	if (!IsValidAliveClient(client))
	{
		return Plugin_Handled;
	}
	if (GetClientTeam(client)!=2)
	{
		return Plugin_Handled;
	}
	if(tnt_planted[client]==0)
	{
		PrintHintText(client, "you have not plant TNT yet");
	}
	else
	{
 		tnt_planted[client]=0;
	
		decl Float:pos[3];
 
		pos[0]=tnt_pos[client][0];
		pos[1]=tnt_pos[client][1];
		pos[2]=tnt_pos[client][2];

		new explode=GetConVarInt(w_explode_tnt);
		new ent1=0;
		new ent2=0;
		new ent3=0;
		if(explode==1)
		{
			ent1=CreateEntityByName("prop_physics"); 
			SetEntPropEnt(ent1, Prop_Data, "m_hOwnerEntity", client)	;	
			DispatchKeyValue(ent1, "model", "models/props_junk/propanecanister001a.mdl"); 
			DispatchSpawn(ent1); 
			TeleportEntity(ent1, pos, NULL_VECTOR, NULL_VECTOR);
			ActivateEntity(ent1);
			SetEntityRenderMode(ent1, RenderMode:3);
			SetEntityRenderColor(ent1, 0, 0, 0, 0);
			AcceptEntityInput(ent1, "Ignite", client, client);

			ent2=CreateEntityByName("prop_physics"); 
			SetEntPropEnt(ent2, Prop_Data, "m_hOwnerEntity", client)	;	
			DispatchKeyValue(ent2, "model", "models/props_junk/propanecanister001a.mdl"); 
			DispatchSpawn(ent2); 
			TeleportEntity(ent2, pos, NULL_VECTOR, NULL_VECTOR);
			ActivateEntity(ent2);
			SetEntityRenderMode(ent2, RenderMode:3);
			SetEntityRenderColor(ent2, 0, 0, 0, 0);
			AcceptEntityInput(ent2, "Ignite", client, client);

			//ent3=CreateEntityByName("prop_physics"); 
			//SetEntPropEnt(ent3, Prop_Data, "m_hOwnerEntity", client)	;	
			//DispatchKeyValue(ent3, "model", "models/props_junk/propanecanister001a.mdl"); 
			//DispatchSpawn(ent3); 
			//TeleportEntity(ent3, pos, NULL_VECTOR, NULL_VECTOR);
			//ActivateEntity(ent3);
			//SetEntityRenderMode(ent3, RenderMode:3);
			//SetEntityRenderColor(ent3, 0, 0, 0, 0);
			//AcceptEntityInput(ent3, "Ignite", client, client);
		}
		new Handle:h=CreateDataPack();

		WritePackCell(h, client);
		WritePackCell(h, ent1);
		WritePackCell(h, ent2);
		WritePackCell(h, ent3);
		WritePackCell(h, explode);

		WritePackFloat(h, pos[0]);
		WritePackFloat(h, pos[1]);
		WritePackFloat(h, pos[2]);
		
		WritePackFloat(h, GetConVarFloat(w_damage_tnt));
		WritePackFloat(h, GetConVarFloat(w_radius_tnt));
		WritePackFloat(h, GetConVarFloat(w_pushforce_tnt));

		CreateTimer(GetConVarFloat(w_delay2), ExplodeTnT, h);
		CreateTimer(1.0, OneLaught, client);
	}

	return Plugin_Handled;
}
public Action:OneLaught(Handle:timer, any:target)
{
	ClientCommand(target, "vocalize PlayerLaugh");
 	PrintToChatAll("\x04%N \x03 Detonated TNT", target);
}
public Action:PlantTimer(Handle:timer, any:client)
{
	if (!IsValidAliveClient(client))
	{
		tnt_optick[client]=0.0;
		tnt_planted[client]=0;
		tnt_plant_timer[client]=INVALID_HANDLE;
 		return Plugin_Stop;
	}
	 
	if (tnt_planted[client]==1 )
	{
		tnt_optick[client]=0.0;
		tnt_plant_timer[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	//if ((buttons & IN_DUCK) || (buttons & IN_USE)) 
	
	{
		tnt_optick[client]=tnt_optick[client]+1.0/TICKS;
		ShowBar(client, "Plant TNT", tnt_optick[client], GetConVarFloat(w_tnt_time));
 

 		decl Float:pos[3]
		pos[0]=tnt_pos[client][0];
		pos[1]=tnt_pos[client][1];
		pos[2]=tnt_pos[client][2];
		EmitAmbientSound(SOUND_BLIP, pos, client, SNDLEVEL_RAIDSIREN);	
		
		new Float:width;
		if(L4D2Version)width = GetConVarFloat( w_shot_laser_width2 );
		else width = GetConVarFloat( w_shot_laser_width );
	
 		TE_SetupBeamRingPoint(pos, 10.0, 20.0, g_BeamSprite, g_HaloSprite, 0, 10, 1.0/TICKS, width, 0.5, redColor, 10, 0);
		TE_SendToAll();

 		if(tnt_optick[client]>GetConVarFloat(w_tnt_time))
		{
			tnt_planted[client]=1;
			tnt_optick[client]=0.0;
			tnt_plant_timer[client]=INVALID_HANDLE;
			bullet_tnt[client]-=1;

			CreateTimer(2.0, TnTShowTimer, client, TIMER_REPEAT);
	 
			TE_SetupBeamRingPoint(pos, 10.0, 200.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, width, 0.5, greyColor, 10, 0);
			decl String:key[10];
			GetConVarString(w_key_tntstart, key, 10);
			PrintHintText(client, "Plant TNT over,Press [%s] to detonate", key);
 			return Plugin_Stop;
 		}
	
	}
 	 
	return Plugin_Continue;
}
public Action:DefuseTimer(Handle:timer, any:client)
{
	if (!IsValidAliveClient(client))
	{
		tnt_planted[client]=0;
		tnt_optick[client]=0.0;
		tnt_defuse_timer[client]=INVALID_HANDLE;
 		return Plugin_Stop;
	}


 	if (tnt_planted[client]==0 )
	{
		tnt_optick[client]=0.0;
		tnt_defuse_timer[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}
 	//if ((buttons & IN_DUCK) || (buttons & IN_USE)) 
	{
		decl Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;

		decl Float:tpos[3];
		tpos[0]=tnt_pos[client][0];
		tpos[1]=tnt_pos[client][1];
		tpos[2]=tnt_pos[client][2] ;

		decl Float:vAngles[3]
		decl Float:vOrigin[3]
		decl Float:pos[3]

		GetClientEyePosition(client,vOrigin)
		GetClientEyeAngles(client, vAngles)

 		new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitLive)

		if(TR_DidHit(trace))
		{
			TR_GetEndPosition(pos, trace)
		}
		CloseHandle(trace)
		 
		new Float:distance = GetVectorDistance(tpos, pos);

		if(distance<250.0)
		{
			tnt_optick[client]=tnt_optick[client]+1.0/TICKS;
			ShowBar(client, "Defuse TNT", tnt_optick[client], GetConVarFloat(w_tnt_time2));
			new Float:width;
			if(L4D2Version)width = GetConVarFloat( w_shot_laser_width2 );
			else width = GetConVarFloat( w_shot_laser_width );
			TE_SetupBeamRingPoint(tpos, 10.0, 20.0, g_BeamSprite, g_HaloSprite, 0, 10, 1.0/TICKS, width, 0.5, redColor, 10, 0);
			TE_SendToAll();
			EmitAmbientSound(SOUND_BLIP2, tpos, SOUND_FROM_WORLD, SNDLEVEL_RAIDSIREN);	
 			if(tnt_optick[client]>GetConVarFloat(w_tnt_time2))
			{
				tnt_planted[client]=0;
				tnt_optick[client]=0.0;
				tnt_defuse_timer[client]=INVALID_HANDLE;
				bullet_tnt[client]+=1;
	 
				PrintHintText(client, "Defuse TNT");
 				return Plugin_Stop;
 			}
		}
		else
		{
			tnt_optick[client]=0.0;
			tnt_defuse_timer[client]=INVALID_HANDLE;
			PrintHintText(client, "you are too far from TNT");
 			return Plugin_Stop;
		}
	}
 	 
	return Plugin_Continue;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}

public bool:TraceRayDontHitLive(entity, mask, any:data)
{
	if( entity <= MaxClients)
	{
		return false;
	}
	if(entity == data) 
	{
		return false; 
	}
	decl String:edictname[128];
	GetEdictClassname(entity, edictname, 128);
	if(StrContains(edictname, "infected")>=0)
	{
		return false;
	}
	return true;
}

 
public Action:TnTShowTimer(Handle:timer, any:client)
{
	if (!IsValidAliveClient(client))
	{
		tnt_planted[client]=0;
 		return Plugin_Stop;
	}
	 
	if (tnt_planted[client]==0 )
	{
		return Plugin_Stop;
	}

	decl Float:vec[3];
 
	vec[0]=tnt_pos[client][0];
	vec[1]=tnt_pos[client][1];
	vec[2]=tnt_pos[client][2];
 
 	new Float:width;
	if(L4D2Version)width = GetConVarFloat( w_shot_laser_width2 );
	else width = GetConVarFloat( w_shot_laser_width );
 
	TE_SetupBeamRingPoint(vec, 10.0, 200.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, width, 0.5, greyColor, 10, 0);
	TE_SendToAll();
 	return Plugin_Continue;
}
 
public Action:sm_addbullet(client, args)
{
	for (new x = 0; x < MAXPLAYERS+1; x++)
	{
		AddBullet(x, 1);
	}
 	return Plugin_Handled;
}public Action:sm_resetbullet(client, args)
{
	for (new x = 0; x < MAXPLAYERS+1; x++)
	{
		SetBullet(x, GetConVarInt(w_start_point));
 	}

 	return Plugin_Handled;
}


public Action:weapon_fire(Handle:event, const String:name[], bool:dontBroadcast)
{
 
	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Continue;
 	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	//if(!IsValidAliveClient(userid)  )	return Plugin_Continue;
	 
	if(GetClientTeam(userid)==3)
	{
		new class = GetEntProp(userid, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_TANK)
		{
			new r=GetRandomInt(0,100);
			if(r<GetConVarInt(w_tank_clow))
			{
				 Fire1(userid, 500.0, 3.0,true);
			}
			else if(r<GetConVarInt(w_tank_clow)*2)
			{
 
			}
		}	
		return Plugin_Continue;
	}
	if(!IsFakeClient(userid) )
	{
		if(GetClientButtons(userid) & IN_USE)
		{
			new bool:pointleft=true;
			 
			if( bullet_shotgun[userid]-1<0 || GetConVarInt(w_enable_shotgun)==0)
			{
				pointleft=false;
			}

			decl String:item[65];
			GetEventString(event, "weapon", item, 65);
			
			//PrintToChatAll("w2 %s", item);
			
			if( StrContains(item, "shotgun")>=0 ||  StrContains(item, "launcher")>=0)
			{
				new Float:time=GetEngineTime();
				new bool:ok=true;
				if( (time-bullettime[userid])<1.0)
				{
					ok=false;
				}
				else
				{
					bullettime[userid]=time;
				}
				if(!ok) 
				{
					return Plugin_Continue;
				}

				if(pointleft)
				{

					new Float:force=GetConVarFloat(w_laugch_force);
					new Float:delay=GetConVarFloat(w_delay);
					force=1050.0;
					Fire1(userid, force,delay, true);
	 					
					bullet_shotgun[userid]-=1;
					PrintHintText(userid, "grenade remain: %d", bullet_shotgun[userid]);
			
				}
			 
				else
				{
					PrintHintText(userid, "not enough grenade");
				}				
				 
			}
		}
	}
 	return Plugin_Continue;

}

public Action:bullet_impact(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Continue; 	
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
 	if(GetClientTeam(userid)!=2 || IsFakeClient(userid))
	{
		return Plugin_Continue;
	}


	//PrintToChatAll("%f, %f", bullettime[userid], time);	
	if(GetClientButtons(userid) & IN_USE)
	{
	
		new Float:time=0.0;
		time=GetEngineTime();			
		new bool:ok=true;
		if(time<=bullettime[userid])
		{
			bullettime[userid]=time;
			ok=false;
		}

		if((time-bullettime[userid])<1.0)
		{
			ok=false;
		}
		if(!ok) 
		{
			return Plugin_Continue;
		}
		bullettime[userid]=time;
		
	}
	else
	{
		return Plugin_Continue;
	}

	new bool:rifle=false;

	new Float:damage=0.0;
	new Float:radius=0.0;
	new Float:pushforce=0.0;
	new explode=0;

	new bool:count=true;
	new bool:pointleft=true;

	decl String:weapon[32];
	GetClientWeapon(userid, weapon, 32);
	//PrintToChatAll("w1 %s", weapon);
	new bool:hunting_rifle=false;
	if(StrEqual(weapon, "weapon_hunting_rifle") || StrContains(weapon, "sniper")>=0 || StrContains(weapon, "magnum")>=0 )
	{
		hunting_rifle=true;
		 
		damage=GetConVarFloat(w_damage_hunting_rifle);
		radius=GetConVarFloat(w_radius_hunting_rifle);
		pushforce=GetConVarFloat(w_pushforce_hunting_rifle);
 		explode=GetConVarInt(w_explode_hunting_rifle);
		if(bullet_hunting_rifle[userid]-1<0 || GetConVarInt(w_enable_hunting_rifle)==0)
		{
			pointleft=false;
		}
		count=false;
	} 
	if(count && StrContains(weapon, "weapon_rifle")>=0)
	{
		rifle=true;
		
		damage=GetConVarFloat(w_damage_rifle);
		radius=GetConVarFloat(w_radius_rifle);
		pushforce=GetConVarFloat(w_pushforce_rifle);
 		explode=GetConVarInt(w_explode_rifle);
		if(bullet_rifle[userid]-1<0 || GetConVarInt(w_enable_rifle)==0)
		{
			pointleft=false;
		}
		count=false;
 	}
	
	new bool:smg=false;
	if(count &&   StrContains(weapon, "smg")>=0 )
	{
		smg=true;
		damage=GetConVarFloat(w_damage_smg);
		radius=GetConVarFloat(w_radius_smg);
		pushforce=GetConVarFloat(w_pushforce_smg);
 		explode=GetConVarInt(w_explode_smg);
		if(bullet_smg[userid]-1<0 || GetConVarInt(w_enable_smg)==0)
		{
			pointleft=false;
		}
		count=false;
	}
	
 	if(hunting_rifle || rifle || smg)
	{
		new Float:x=GetEventFloat(event, "x");
		new Float:y=GetEventFloat(event, "y");
		new Float:z=GetEventFloat(event, "z");
		
		decl Float:pos[3];
		pos[0]=x;
		pos[1]=y;
		pos[2]=z;
 
		decl Float:playerpos[3];
		GetClientEyePosition(userid, playerpos);

		new Float:dd = GetVectorDistance(playerpos, pos);
		if(dd<radius)
		{
			PrintHintText(userid, "too close, can not fire");
			return Plugin_Continue;
		}
		
		decl Float:v1[3];
		decl Float:v2[3];
		decl Float:v3[3];

		SubtractVectors(playerpos, pos, v1);
		NormalizeVector(v1, v2);
		v3[0]=v2[0];
		v3[1]=v2[1];
		v3[2]=v2[2];

		ScaleVector(v2, GetConVarFloat(w_offset));
		AddVectors(pos, v2, v1); // v1 explode taget
		if(pointleft)
		{
			new ent1 = 0;
			new ent2 = 0;
			new ent3 = 0;
			
			//decl String:tName[128];

			if(explode!=0)
			{ 
				ent1=CreateEntityByName("prop_physics"); 
				SetEntPropEnt(ent1, Prop_Data, "m_hOwnerEntity", userid)	;			
				DispatchKeyValue(ent1, "model", "models/props_junk/propanecanister001a.mdl"); 
				DispatchSpawn(ent1); 
				TeleportEntity(ent1, v1, NULL_VECTOR, NULL_VECTOR);
				ActivateEntity(ent1);
				SetEntityRenderMode(ent1, RenderMode:3);
				SetEntityRenderColor(ent1, 0, 0, 0, 0);
				AcceptEntityInput(ent1, "Ignite", userid, userid);
				if(hunting_rifle || rifle)
				{
					ent2=CreateEntityByName("prop_physics"); 
					SetEntPropEnt(ent2, Prop_Data, "m_hOwnerEntity", userid)	;			
					DispatchKeyValue(ent2, "model", "models/props_junk/propanecanister001a.mdl"); 
					DispatchSpawn(ent2); 
					TeleportEntity(ent2, v1, NULL_VECTOR, NULL_VECTOR);
					ActivateEntity(ent2);
					SetEntityRenderMode(ent2, RenderMode:3);
					SetEntityRenderColor(ent2, 0, 0, 0, 0);
					AcceptEntityInput(ent2, "Ignite", userid, userid);

				}
			}
 
 			if(GetConVarInt(w_shot_laser))
			{

				decl Float:dpos[3];
				dpos[0]=x;
				dpos[1]=y;
				dpos[2]=z;
		
				ScaleVector(v3, GetConVarFloat(w_shot_laser_offset));
				SubtractVectors(playerpos, v3, pos);
	 
				decl color[4];
				color[0] = GetConVarInt( w_shot_laser_red ); 
				color[1] = GetConVarInt( w_shot_laser_green );
				color[2] = GetConVarInt( w_shot_laser_blue );
				color[3] = GetConVarInt( w_shot_laser_alpha );
				
				new Float:life;
				life = GetConVarFloat( w_shot_laser_life );

				new Float:width;
				if(L4D2Version)width = GetConVarFloat( w_shot_laser_width2 );
				else width = GetConVarFloat( w_shot_laser_width );
				
				TE_SetupBeamPoints(pos, dpos, g_sprite, 0, 0, 0, life, width, width, 1, 0.0, color, 0);
				TE_SendToAll();
			}
	 

			new Handle:h=CreateDataPack();
			WritePackCell(h, userid);
			WritePackCell(h, ent1);
			WritePackCell(h, ent2);
			WritePackCell(h, ent3);
			WritePackCell(h, 0);
			WritePackCell(h, explode);
			WritePackCell(h, 0);

			WritePackFloat(h, v1[0]);
			WritePackFloat(h, v1[1]);
			WritePackFloat(h, v1[2]);

			
			WritePackFloat(h, damage);
			WritePackFloat(h, radius);
			WritePackFloat(h, pushforce);

			CreateTimer(GetConVarFloat(w_delay2), Explode2, h);
		 
			new remain=0;
			if(smg)
			{
				bullet_smg[userid]-=1;
				remain=bullet_smg[userid];
				 
			}
			else if(rifle)
			{
				bullet_rifle[userid]-=1;
				remain=bullet_rifle[userid];
			 			
			}
			else if(hunting_rifle)
			{
				bullet_hunting_rifle[userid]-=1;
				remain=bullet_hunting_rifle[userid];
			}
 			
			PrintHintText(userid, "laser gun remain: %d", remain);
		}
		else
		{
			PrintHintText(userid, "not enough laser gun");
 		}
 
	}

 	return Plugin_Continue;
}
 
 

public Action:grenade_bounce(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(h_Event, "userid"));
	//PrintToChatAll("bounce %N", userid);
	
	if(GrenadeLauncher[userid] > 0 && IsValidEntity(GrenadeLauncher[userid]))
	{
		//PrintToChatAll("bounce ok");
		new Float:pos[3];	
		GetEntPropVector(GrenadeLauncher[userid], Prop_Send, "m_vecOrigin", pos);		

		new ent1=0;
		if(true)
		{
			ent1=CreateEntityByName("prop_physics"); 
			SetEntPropEnt(ent1, Prop_Data, "m_hOwnerEntity", userid)	;			
			DispatchKeyValue(ent1, "model", "models/props_junk/propanecanister001a.mdl"); 
			DispatchSpawn(ent1); 
			TeleportEntity(ent1, pos, NULL_VECTOR, NULL_VECTOR);
			ActivateEntity(ent1);
			//AcceptEntityInput(ent1, "Ignite", -1, -1);
		}
		
		new Handle:h=CreateDataPack();		
		WritePackCell(h, userid);
		WritePackCell(h, GrenadeLauncher[userid]);
		WritePackCell(h, ent1);
		WritePackCell(h, 0);
		
		GrenadeLauncher[userid]=0;
	
		WritePackFloat(h, pos[0]);
		WritePackFloat(h, pos[1]);
		WritePackFloat(h, pos[2]);

		new Float:damage=GetConVarFloat(w_damage_shotgun);
		new Float:radius=GetConVarFloat(w_radius_shotgun);
		new Float:pushforce=GetConVarFloat(w_pushforce_shotgun);		
		WritePackFloat(h, damage);
		WritePackFloat(h, radius);
		WritePackFloat(h, pushforce);
		
		ExplodeG(INVALID_HANDLE, h);
		
	}
	
}

Fire1(userid, Float:force, Float:delay, bool:chase=false)
{
	decl Float:pos[3];
	decl Float:angles[3];
	decl Float:velocity[3];
	GetClientEyePosition(userid, pos);
	 
	GetClientEyeAngles(userid, angles);
	GetEntDataVector(userid, g_iVelocity, velocity);
	
	angles[0]-=5.0;
	
	velocity[0] = force * Cosine(DegToRad(angles[1])) * Cosine(DegToRad(angles[0]));
	velocity[1] = force * Sine(DegToRad(angles[1])) * Cosine(DegToRad(angles[0]));
	velocity[2] = force * Sine(DegToRad(angles[0])) * -1.0;

	//new Float:force=GetConVarFloat(w_laugch_force);

	GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(velocity, velocity);
	ScaleVector(velocity, force);
	
	{
		new Float:B=-3.1415926/2.0;
		decl Float:vec[3];
		decl Float:vec2[3];
		GetAngleVectors(angles,vec, NULL_VECTOR, NULL_VECTOR);
		GetAngleVectors(angles,vec2, NULL_VECTOR, NULL_VECTOR);
		new Float:x0=vec[0];
		new Float:y0=vec[1];
		new Float:x1=x0*Cosine(B)-y0*Sine(B);
		new Float:y1=x0*Sine(B)+y0*Cosine(B);
		vec[0]=x1;
		vec[1]=y1;
		vec[2]=0.0;
		NormalizeVector(vec,vec);
		NormalizeVector(vec2,vec2);
		ScaleVector(vec, 8.0);
		ScaleVector(vec2, 20.0);
		AddVectors(pos, vec, pos);
		//AddVectors(pos, vec2, pos);
	}

	//pos[0]+=velocity[0]*0.1;
	//pos[1]+=velocity[1]*0.1;
	//pos[2]+=velocity[2]*0.1;

	new ent = 0;
	new chaseent=0;
	new explode=1;

 	if(!L4D2Version) 
	{
		ent=CreateEntityByName("molotov_projectile");  
		DispatchKeyValue(ent, "model", "models/w_models/weapons/w_eq_molotov.mdl");  
	}
	else
	{
		ent=CreateEntityByName("grenade_launcher_projectile");
		DispatchKeyValue(ent, "model", "models/w_models/weapons/w_HE_grenade.mdl");  
	}
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", userid)	;			

	DispatchSpawn(ent);  
	TeleportEntity(ent, pos, NULL_VECTOR, velocity);
	ActivateEntity(ent);
	if(!L4D2Version)
	{
		SetEntityRenderMode(ent, RenderMode:3);
		SetEntityRenderColor(ent, 0, 0, 0, 0);
	}
	//AcceptEntityInput(ent, "Ignite", userid, userid);
	SetEntityGravity(ent, 0.4);
 
	if(GrenadeLauncher[userid] > 0 && IsValidEntity(GrenadeLauncher[userid]))
	{
		RemoveEdict(GrenadeLauncher[userid]);
	}
	GrenadeLauncher[userid]=ent;
	return;
}


public Action:TankFire1(Handle:timer, any:userid)
{
	if(!IsValidAliveClient(userid))	return;
	Fire1(userid, 800.0, 2.5,true);
}
public Action:TankFire2(Handle:timer, any:userid)
{
	if(!IsValidAliveClient(userid))	return;
	Fire1(userid, 500.0, 2.0,true);
}
public Action:ability_use(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Continue; 	
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidAliveClient(userid))	return Plugin_Continue;
	if(GetClientTeam(userid)==3)
	{
		new class = GetEntProp(userid, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_TANK)
		{
			if(GetRandomInt(0,100)<GetConVarInt(w_tank_throw))
			{
				 CreateTimer(2.1 , TankFire1, userid);
				 
			}
		}	
		return Plugin_Continue;
	}
 	return Plugin_Continue;
}

public Action:ExplodeTripmine(Float:pos[3])
{

	new explode = GetConVarInt(w_explode_tripmine);
	new Float:damage=GetConVarFloat(w_damage_tripmine);
	new Float:radius=GetConVarFloat(w_radius_tripmine);
	new Float:force=GetConVarFloat(w_pushforce_tripmine);
	 
 	 
	if(explode==1 )
	{
		new ent=CreateEntityByName("prop_physics"); // Create explosion env_physexplosion env_explosion
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", -1)	;			
		DispatchKeyValue(ent, "model", "models/props_junk/propanecanister001a.mdl"); // force float
		DispatchSpawn(ent); // Spawn descriped explosion
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(ent);
		SetEntityRenderMode(ent, RenderMode:3);
		SetEntityRenderColor(ent, 0, 0, 0, 0);
		AcceptEntityInput(ent, "Ignite", -1, -1);
 		AcceptEntityInput(ent, "break", -1);
		RemoveEdict(ent);
	}
	else if(explode==2 )
	{
		ShowParticle(pos, "gas_explosion_pump", 0.2);	
	}
	else if(explode==3)
	{
		decl Float:vec[3];
		vec[0]=GetRandomFloat(-1.0, 1.0);
		vec[1]=GetRandomFloat(-1.0, 1.0);
		vec[2]=GetRandomFloat(-1.0, 1.0);
		//TE_SetupSparks(pos,vec,255, 5);
		TE_SetupSparks(pos,vec,1, 3);
		TE_SendToAll();
	}
 	
 	new pointHurt = CreateEntityByName("point_hurt");   
	
 	DispatchKeyValueFloat(pointHurt, "Damage", damage);        
	DispatchKeyValueFloat(pointHurt, "DamageRadius", radius);     
 	DispatchKeyValue(pointHurt, "DamageDelay", "0.0");   
	if(explode==4)
	{
		DispatchKeyValue(pointHurt, "DamageType", "64"); 
	}
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(pointHurt, "Hurt", -1);    
	CreateTimer(0.1, DeletePointHurt, pointHurt); 
 
	new pushmode=GetConVarInt(w_pushforce_mode);

	if(pushmode==1 || pushmode==3)
	{
		new push = CreateEntityByName("point_push");         
  		DispatchKeyValueFloat (push, "magnitude", force);                     
		DispatchKeyValueFloat (push, "radius", radius*1.0);                     
  		SetVariantString("spawnflags 24");                     
		AcceptEntityInput(push, "AddOutput");
 		DispatchSpawn(push);   
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
 		AcceptEntityInput(push, "Enable", -1, -1);
		CreateTimer(0.5, DeletePushForce, push);
	}
	if(pushmode==2 || pushmode==3)
	{
		PushAway(pos, force, radius);
	}
 
	return;
}
public Action:Explode2(Handle:timer, Handle:h)
{
	ResetPack(h);
 	new userid=ReadPackCell(h);
	new ent1=ReadPackCell(h);
	new ent2=ReadPackCell(h);
	new ent3=ReadPackCell(h);
	new chaseent=ReadPackCell(h);
	new explode = ReadPackCell(h);
	new shotgun = ReadPackCell(h);
	decl Float:pos[3];
	pos[0]=ReadPackFloat(h);
	pos[1]=ReadPackFloat(h);
	pos[2]=ReadPackFloat(h);
	new Float:damage=ReadPackFloat(h);
	new Float:radius=ReadPackFloat(h);
	new Float:force=ReadPackFloat(h);
	CloseHandle(h);
	
 	if(ent1>0 && IsValidEntity(ent1))
	{
		decl Float:pos1[3];
		GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", pos1)
		if(shotgun==1)
		{
			pos[0]=pos1[0];
			pos[1]=pos1[1];
			pos[2]=pos1[2];
		}
			
		if(explode==1)
		{
 			AcceptEntityInput(ent1, "break", userid);
			RemoveEdict(ent1);
 			if(ent2>0 && IsValidEntity(ent2))
			{
				AcceptEntityInput(ent2, "break",  userid);
				RemoveEdict(ent2);
			}
 			if(ent3>0 && IsValidEntity(ent3))
			{
				AcceptEntityInput(ent3, "break",  userid);
				RemoveEdict(ent3);
			}
		
		}
		else
		{
 			AcceptEntityInput(ent1, "kill", userid);
			RemoveEdict(ent1);
 			if(ent2>0 && IsValidEntity(ent2))
			{
				AcceptEntityInput(ent2, "kill",  userid);
				RemoveEdict(ent2);
			}
 			if(ent3>0 && IsValidEntity(ent3))
			{
				AcceptEntityInput(ent3, "kill",  userid);
				RemoveEdict(ent3);
			}
		}
		if(chaseent!=0)
		{
			DeleteEntity(chaseent, "info_goal_infected_chase");
 		}
	}
	//if(explode==0)
	{
		ShowParticle(pos, "gas_explosion_pump", 3.0);	
	}
 	new pointHurt = CreateEntityByName("point_hurt");   
 	
 	DispatchKeyValueFloat(pointHurt, "Damage", damage);        
	DispatchKeyValueFloat(pointHurt, "DamageRadius", radius);     
 	DispatchKeyValue(pointHurt, "DamageDelay", "0.0");   
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(pointHurt, "Hurt", userid);    
	CreateTimer(0.1, DeletePointHurt, pointHurt); 
 
	new pushmode=GetConVarInt(w_pushforce_mode);

	if(pushmode==1 || pushmode==3)
	{
		new push = CreateEntityByName("point_push");         
  		DispatchKeyValueFloat (push, "magnitude", force);                     
		DispatchKeyValueFloat (push, "radius", radius*1.0);                     
  		SetVariantString("spawnflags 24");                     
		AcceptEntityInput(push, "AddOutput");
 		DispatchSpawn(push);   
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
 		AcceptEntityInput(push, "Enable", userid, userid);
		CreateTimer(0.5, DeletePushForce, push);
	}
	if(pushmode==2 || pushmode==3)
	{
		PushAway(pos, force, radius);
	}
 
	return;
}
 
public Action:ExplodeTnT(Handle:timer, Handle:h)
{
	ResetPack(h);
 	new userid=ReadPackCell(h);
	new ent1=ReadPackCell(h);
	new ent2=ReadPackCell(h);
	new ent3=ReadPackCell(h);
	new explode = ReadPackCell(h);
	decl Float:pos[3];
	pos[0]=ReadPackFloat(h);
	pos[1]=ReadPackFloat(h);
	pos[2]=ReadPackFloat(h);
	new Float:damage=ReadPackFloat(h);
	new Float:radius=ReadPackFloat(h);
	new Float:force=ReadPackFloat(h);
	CloseHandle(h);
	
 	if(ent1>0 && IsValidEntity(ent1))
	{
		decl Float:pos1[3];
		GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", pos1)
		pos[0]=pos1[0];
		pos[1]=pos1[1];
		pos[2]=pos1[2];
			
		if(explode==1)
		{
 			AcceptEntityInput(ent1, "break", userid);
			RemoveEdict(ent1);
 			if(ent2>0 && IsValidEntity(ent2))
			{
				AcceptEntityInput(ent2, "break",  userid);
				RemoveEdict(ent2);
			}
 			if(ent3>0 && IsValidEntity(ent3))
			{
				AcceptEntityInput(ent3, "break",  userid);
				RemoveEdict(ent3);
			}
		
		}
		else
		{
 			AcceptEntityInput(ent1, "kill", userid);
			RemoveEdict(ent1);
 			if(ent2>0 && IsValidEntity(ent2))
			{
				AcceptEntityInput(ent2, "kill",  userid);
				RemoveEdict(ent2);
			}
 			if(ent3>0 && IsValidEntity(ent3))
			{
				AcceptEntityInput(ent3, "kill",  userid);
				RemoveEdict(ent3);
			}
 		}
	}
	if(explode==0){}
	ShowParticle(pos, "gas_explosion_main", 1.0);	
 	new pointHurt = CreateEntityByName("point_hurt");   
 	DispatchKeyValueFloat(pointHurt, "Damage", damage);        
	DispatchKeyValueFloat(pointHurt, "DamageRadius", radius);     
 	DispatchKeyValue(pointHurt, "DamageDelay", "0.0");     
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(pointHurt, "Hurt", userid);    
	CreateTimer(0.1, DeletePointHurt, pointHurt); 

 
	new pushmode=GetConVarInt(w_pushforce_mode);

	if(pushmode==1 || pushmode==3)
	{
		new push = CreateEntityByName("point_push");         
  		DispatchKeyValueFloat (push, "magnitude", force);                     
		DispatchKeyValueFloat (push, "radius", radius*1.0);                     
  		SetVariantString("spawnflags 24");                             
		AcceptEntityInput(push, "AddOutput");
 		DispatchSpawn(push);   
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
 		AcceptEntityInput(push, "Enable", userid, userid);
		CreateTimer(0.5, DeletePushForce, push);
	}
	if(pushmode==2 || pushmode==3)
	{
		PushAway(pos, force, radius);
	}
	return;
}  

 
public Action:ExplodeG(Handle:timer, Handle:h)
{
	ResetPack(h);
 	new userid=ReadPackCell(h);
	new ent1=ReadPackCell(h);
	new ent2=ReadPackCell(h);
	new ent3=ReadPackCell(h);

	decl Float:pos[3];
	pos[0]=ReadPackFloat(h);
	pos[1]=ReadPackFloat(h);
	pos[2]=ReadPackFloat(h);
	new Float:damage=ReadPackFloat(h);
	new Float:radius=ReadPackFloat(h);
	new Float:force=ReadPackFloat(h);
	CloseHandle(h);
	
 	if(ent1>0 && IsValidEntity(ent1))
	{
		decl Float:pos1[3];

 		AcceptEntityInput(ent1, "break", userid);
		RemoveEdict(ent1);
 		if(ent2>0 && IsValidEntity(ent2))
		{
			AcceptEntityInput(ent2, "break",  userid);
			RemoveEdict(ent2);
		}
 		if(ent3>0 && IsValidEntity(ent3))
		{
			AcceptEntityInput(ent3, "break",  userid);
			RemoveEdict(ent3);
		}

	}
	 
	ShowParticle(pos, "gas_explosion_pump", 3.0);	
	 
 	new pointHurt = CreateEntityByName("point_hurt");   
 	
 	DispatchKeyValueFloat(pointHurt, "Damage", damage);        
	DispatchKeyValueFloat(pointHurt, "DamageRadius", radius);     
 	DispatchKeyValue(pointHurt, "DamageDelay", "0.0");   
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(pointHurt, "Hurt", userid);    
	CreateTimer(0.1, DeletePointHurt, pointHurt); 
  
	new pushmode=GetConVarInt(w_pushforce_mode);

	if(pushmode==1 || pushmode==3)
	{
		new push = CreateEntityByName("point_push");         
  		DispatchKeyValueFloat (push, "magnitude", force);                     
		DispatchKeyValueFloat (push, "radius", radius*1.0);                     
  		SetVariantString("spawnflags 24");                     
		AcceptEntityInput(push, "AddOutput");
 		DispatchSpawn(push);   
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
 		AcceptEntityInput(push, "Enable", userid, userid);
		CreateTimer(0.5, DeletePushForce, push);
	}
	if(pushmode==2 || pushmode==3)
	{
		PushAway(pos, force, radius);
	}
 
	return;
} 

PushAway( Float:pos[3], Float:force, Float:radius)
{
	pos[2]-=100;
	new Float:limit=GetConVarFloat(w_pushforce_vlimit);
	new Float:normalfactor=GetConVarFloat(w_pushforce_factor);
	new Float:tankfactor=GetConVarFloat(w_pushforce_tankfactor);
	new Float:survivorfactor=GetConVarFloat(w_pushforce_survivorfactor);
	new Float:factor;
	new Float:r;


	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (IsPlayerAlive(target))
			{
					decl Float:targetVector[3]
					GetClientEyePosition(target, targetVector)
													
					new Float:distance = GetVectorDistance(targetVector, pos);

					if(GetClientTeam(target)==2)
					{
						factor=survivorfactor;
						r=radius*0.8;
 					}
					else if(GetClientTeam(target)==3)
					{
 						new class = GetEntProp(target, Prop_Send, "m_zombieClass");
						if(class==5)
						{
							factor=tankfactor;
							r=radius*1.0;
						}
						else
						{
							factor=normalfactor;
							r=radius*1.3;
						}
					}
							
					if (distance < r )
					{
						decl Float:vector[3];
					
						MakeVectorFromPoints(pos, targetVector, vector);
								
						NormalizeVector(vector, vector);
						ScaleVector(vector, force);
						if(vector[2]<0.0)vector[2]=10.0;

						vector[0]*=factor;
						vector[1]*=factor;
						vector[2]*=factor;

						vector[0]*=factor;
						vector[1]*=factor;
						vector[2]*=factor;
						if(vector[0]>limit)
						{
							vector[0]=limit;
						}
						if(vector[1]>limit)
						{
							vector[1]=limit;
						}
						if(vector[2]>limit)
						{
							vector[2]=limit;
						}

						if(vector[0]<-limit)
						{
							vector[0]=-limit;
						}
						if(vector[1]<-limit)
						{
							vector[1]=-limit;
						}
						if(vector[2]<-limit)
						{
							vector[2]=-limit;
						}
 						TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vector);				
				 
 					}
			 
			}
		}
	}

}
public DeleteEntity(any:ent, String:name[])
{
	 if (IsValidEntity(ent))
	 {
		 decl String:classname[64];
		 GetEdictClassname(ent, classname, sizeof(classname));
		 if (StrEqual(classname, name, false))
		 {
			AcceptEntityInput(ent, "Kill"); 
			RemoveEdict(ent);
		 }
	 }
}
 
public Action:DeletePushForce(Handle:timer, any:ent)
{
	 if (IsValidEntity(ent))
	 {
		 decl String:classname[64];
		 GetEdictClassname(ent, classname, sizeof(classname));
		 if (StrEqual(classname, "point_push", false))
				{
 					AcceptEntityInput(ent, "Disable");
					AcceptEntityInput(ent, "Kill"); 
					RemoveEdict(ent);
				}
	 }
}
public Action:DeletePointHurt(Handle:timer, any:ent)
{
	 if (IsValidEntity(ent))
	 {
		 decl String:classname[64];
		 GetEdictClassname(ent, classname, sizeof(classname));
		 if (StrEqual(classname, "point_hurt", false))
				{
					AcceptEntityInput(ent, "Kill"); 
					RemoveEdict(ent);
				}
		 }

}
public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
 new particle = CreateEntityByName("info_particle_system");
 if (IsValidEdict(particle))
 {
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
 } 
}
public ShowParticle2(Float:pos[3], Float:angle[3], String:particlename[], Float:time)
{
 new particle = CreateEntityByName("info_particle_system");
 if (IsValidEdict(particle))
 {
		TeleportEntity(particle, pos, angle, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
 } 
}
public PrecacheParticle(String:particlename[])
{
 new particle = CreateEntityByName("info_particle_system");
 if (IsValidEdict(particle))
 {
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle);
 } 
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	 if (IsValidEntity(particle))
	 {
		 decl String:classname[64];
		 GetEdictClassname(particle, classname, sizeof(classname));
		 if (StrEqual(classname, "info_particle_system", false))
			{
				AcceptEntityInput(particle, "stop");
				AcceptEntityInput(particle, "kill");
				RemoveEdict(particle);
			}
	 }
}

new String:Gauge1[2] = "-";
 
new String:Gauge3[2] = "#";

ShowBar(client, String:msg[], Float:pos, Float:max)
{
	new i=0;
	decl String:ChargeBar[100];
	Format(ChargeBar, sizeof(ChargeBar), "");
	new Float:GaugeNum = pos/max*100.0;
	if(GaugeNum > 100.0)
		GaugeNum = 100.0;
	if(GaugeNum<0.0)
		GaugeNum = 0.0;
	 
	for(i=0; i<100; i++)
		ChargeBar[i] = Gauge1[0];
	new p=RoundFloat( GaugeNum);
	 
	if(p>=0 && p<100)ChargeBar[p] = Gauge3[0];

	PrintCenterText(client, "%s %3.0f %\n<< %s >>", msg, GaugeNum, ChargeBar);
	//else PrintCenterText(client, " ");
}
ShowBar2(client, String:msg[], Float:pos, Float:max)	
{
	new i=0;
	decl String:ChargeBar[100];
	Format(ChargeBar, sizeof(ChargeBar), "");
	new Float:GaugeNum = pos/max*100.0;
	if(GaugeNum > 100.0)
		GaugeNum = 100.0;
	if(GaugeNum<0.0)
		GaugeNum = 0.0;
	 
	for(i=0; i<100; i++)
		ChargeBar[i] = Gauge1[0];
	new p=RoundFloat( GaugeNum);
	 
	if(p>=0 && p<100)ChargeBar[p] = Gauge3[0];
	
	PrintCenterText(client, "%s %3.0f %\n<< %s >>", msg, 1.0-GaugeNum, ChargeBar);
}

public Action:sm_grab(client, args)
{ 
	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Continue;
	if(!IsValidAliveClient(client))	return Plugin_Continue;
	 
	if(GetClientTeam(client)!=2)return Plugin_Continue;
	if(ThrowEntity[client]>0) 
		{
			Throw(client);	
			return Plugin_Continue;
		}
		
 

 
 	new bool:pointleft=true;
	if(bullet_interaction[client]-1<0 || GetConVarInt(w_enable_interaction)==0)
	{
		pointleft=false;
	}
 
	{
	 
		if(pointleft )
		{
			new ent = TraceToEntity(client);
			if (ent==-1)
			{
				PrintHintText(client, "grabed nothing ");
				return Plugin_Handled;
			}
			if (ent==-2)
			{
				PrintHintText(client, "grabed nothing ");
				return Plugin_Handled;
			}
			if (ent==-3)
			{
				PrintHintText(client, "grabed nothing ");
				return Plugin_Handled;
			}
			
			decl String:edictname[128];
			GetEdictClassname(ent, edictname, 128);
			{
				new j;
				for (j=1; j<=MAXPLAYERS; j++)
				{
					if (ThrowEntity[j]==ent)
					{
 						ThrowEntity[j]=-1;
 						ThrowState[j]=0.0;
 					}
				}
				ThrowEntity[client] = ent;
				ThrowState[client] = GetConVarFloat(w_grab_energetime) + GetEngineTime();
 

				if(IsValidAliveClient(ThrowEntity[client]) && GetClientTeam(ThrowEntity[client])==2 && !IsPlayerIncapped(ThrowEntity[client]) && !IsPlayerIncapped( client ))
				{
					new propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
					new count = GetEntData(client, propincapcounter, 1);
					if(count==0)
					{
						 PrintToChatAll("\x03Blood transfusion between \x04%N \x03and \x04%N", client, ThrowEntity[client]);
					}
				}
				if(IsValidAliveClient(ThrowEntity[client]) && GetClientTeam(ThrowEntity[client])==3 && control[ThrowEntity[client]]==0)
				{
					//bullet_interaction[client]-=point;
					AddControl(ThrowEntity[client]);
				}
				 
				if (GetConVarInt(w_grab_groundmode)!=1)
				{
					EmitSoundToAll(SOUND_GRAB, client); 
				}
				
				bullet_interaction[client]-=1;
				
				PrintHintText(client, "grabed something , energe ramain: %d", bullet_interaction[client]);
			}
		}
		else
		{
			PrintHintText(client, "not enough energe fo grab");
		}
	}
 	return Plugin_Handled;
}

 
 
Throw(client)
{
	if(!IsValidAliveClient(client))
	{
		ThrowEntity[client]=-1;
		ThrowState[client]=0.0;
		return;
	}
	if(ThrowEntity[client]<0)return ;
 	if(IsValidEdict(ThrowEntity[client]) )
	{
	
 		new Float:ThrowStatespeed =0.0;
		if(IsValidAliveClient(ThrowEntity[client]))
		{
			if(GetClientTeam(ThrowEntity[client])==2)
			{
				ThrowStatespeed=GetConVarFloat(w_grab_throwspeed)*0.6;
			}
			else
			{
				ThrowStatespeed=GetConVarFloat(w_grab_throwspeed);
			}
		}
		else
		{
			ThrowStatespeed=GetConVarFloat(w_grab_throwspeed);
		}
		 
		decl Float:start[3];
		GetClientEyePosition(client, start);
		decl Float:angle[3];
		decl Float:speed[3];
		GetClientEyeAngles(client, angle);
		GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
		speed[0]*=ThrowStatespeed; speed[1]*=ThrowStatespeed; speed[2]*=ThrowStatespeed;
		
		TeleportEntity(ThrowEntity[client], NULL_VECTOR, NULL_VECTOR, speed);
		EmitSoundToAll(SOUND_GRAB, client);
		ThrowState[client]=0.0;
		ThrowEntity[client]=-1;
	}
 	return ;
}
stock DamageEffect(target, String:demage[])
{
	decl String:N[20];
	Format(N, 20, "target%d", target);	
	new pointHurt = CreateEntityByName("point_hurt");			
	DispatchKeyValue(target, "targetname", N);			
	DispatchKeyValue(pointHurt, "Damage", demage);				
	DispatchKeyValue(pointHurt, "DamageTarget", N);
	DispatchKeyValue(pointHurt, "DamageType", "65536");			
	DispatchSpawn(pointHurt);									
	AcceptEntityInput(pointHurt, "Hurt"); 					
	AcceptEntityInput(pointHurt, "Kill"); 						
	//DispatchKeyValue(target, "targetname",	"cake");		
}
AddHealth(client, add)
{
	if(add<=0)
	{
		decl String:arg1[10];
		Format(arg1, sizeof(arg1), "%i", -add);
		DamageEffect(client, arg1);
	}
	else
	{
		new hardhp = GetClientHealth(client) + 0; 
		SetEntityHealth(client, hardhp + add);
	}
	return;
}

public Action:UpdateObjects(Handle:timer)
{
	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Continue;
	decl Float:vecDir[3], Float:vecPos[3], Float:vecVel[3]; 
	decl Float:viewang[3]; 
 	new Float:speed = GetConVarFloat(w_grab_speed);
	new Float:distance = GetConVarFloat(w_grab_mindistance);
	new groundmode = GetConVarInt(w_grab_groundmode);
	new Float:ThrowStatetime = GetConVarFloat(w_grab_energetime);
	new Float:time = GetEngineTime();
 
	new flame1;
	new flame2;
	new Float:flametime;

 	decl Float:Angles[3];
	decl Float:Origin[3];
	decl Float:AnglesVec[3];
 	decl Float:StartPoint[3];
	decl Float:EndPoint[3];
 	decl Float:pos[3];	

	
 	new Float:flamedistance = GetConVarFloat(w_flame_distance);
 	new Float:flameradius = GetConVarFloat(w_flame_radius);
 	new Float:flamedamage = GetConVarFloat(w_flame_damage);
 	new Float:flamedamage2 = GetConVarFloat(w_flame_damage2);
 	new Float:flamelife = GetConVarFloat(w_flame_life);
	for (new client=0; client<=MaxClients; client++)
	{
		new bool:notplayer=false;
		if(!IsValidAliveClient(client))
		{
			notplayer=true;
		}
		if(tripmine_planted[client]==2)
		{
			 
			if(notplayer)
			{
				tripmine_planted[client]=0;
			}
			else if(time-tripmine_time[client]>GetConVarFloat(w_tripmine_duration))
			{
				tripmine_planted[client]=0;
			}
			else
			{
				StartPoint[0]=tripmine_pos[client][0];
				StartPoint[1]=tripmine_pos[client][1];
				StartPoint[2]=tripmine_pos[client][2];
				
				EndPoint[0]=tripmine_pos[client][3];
				EndPoint[1]=tripmine_pos[client][4];
				EndPoint[2]=tripmine_pos[client][5];
				
				decl color[4];
				color[0] = GetConVarInt( w_shot_laser_red ); 
				color[1] = GetConVarInt( w_shot_laser_green );
				color[2] = GetConVarInt( w_shot_laser_blue );
				color[3] = GetConVarInt( w_shot_laser_alpha );
				
				new Float:life=0.08;
				
				new Float:width;
				if(L4D2Version)width = GetConVarFloat( w_shot_laser_width2 )/6.0;
				else width = GetConVarFloat( w_shot_laser_width )/6.0;

				
				TR_TraceRayFilter(StartPoint, EndPoint, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelf, 0);
	
				if (TR_DidHit(INVALID_HANDLE))
				{
					TR_GetEndPosition(pos, INVALID_HANDLE);
					ExplodeTripmine(pos);
					TE_SetupBeamPoints(StartPoint,  EndPoint, g_sprite, 0, 0, 0, life, width*4.0, width*4.0, 1, 0.0, color, 0);
					TE_SendToAll();
					
				}
				else
				{
					TE_SetupBeamPoints(StartPoint,  EndPoint, g_sprite, 0, 0, 0, life, width, width, 1, 0.0, color, 0);
					TE_SendToAll();
				}

		
			}
		}
		if (ThrowEntity[client]>0)
		{
			if(notplayer)
			{	ThrowEntity[client]=-1;
				ThrowState[client]=0.0;
			}
 			else if (IsValidEdict(ThrowEntity[client]) )
			{
				if(ThrowState[client]>time)
				{
					ShowBar2(client, "Energe left", ThrowState[client]-time, ThrowStatetime);
 					 
					GetEntPropVector(ThrowEntity[client], Prop_Send, "m_vecOrigin", vecDir);
				 
					GetClientEyeAngles(client, viewang);
					GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
					if (groundmode==1)
					{
						GetClientAbsOrigin(client, vecPos);
					}
					else
					{
						GetClientEyePosition(client, vecPos);
					}
				 
					vecPos[0]+=vecDir[0]*distance;
					vecPos[1]+=vecDir[1]*distance;
					if (groundmode!=1)
					{
						vecPos[2]+=vecDir[2]*distance; 
					}
					GetEntPropVector(ThrowEntity[client], Prop_Send, "m_vecOrigin", vecDir);
					
					SubtractVectors(vecPos, vecDir, vecVel);
					
					ScaleVector(vecVel, speed);
					if (groundmode==1)
					{
						vecVel[2]=0.0;
					}
					TeleportEntity(ThrowEntity[client], NULL_VECTOR, NULL_VECTOR, vecVel);		

					if(IsValidAliveClient(ThrowEntity[client]) && GetClientTeam(ThrowEntity[client])==2 && !IsPlayerIncapped(ThrowEntity[client]) && !IsPlayerIncapped( client ))
					{
						new propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
						new count = GetEntData(client, propincapcounter, 1);
						if(count==0)
						{
							 AddHealth(ThrowEntity[client], 1);
							 DamageEffect(client, "1");
						}
					}
				}
				else
				{
					ThrowEntity[client]=-1;
					ThrowState[client]=0.0;
 				}
 			}
			else
			{
				ThrowEntity[client]=-1;
				ThrowState[client]=0.0;
			}
			
		}
 
		if(FlameHandle[client]!=INVALID_HANDLE)
		{
			new	Handle:h=FlameHandle[client];
			ResetPack(h);
 			flame1=ReadPackCell(h);
			flame2=ReadPackCell(h);
			flametime=ReadPackFloat(h);
			new fire=ReadPackCell(h);
			
			if(notplayer)
			{
				CloseHandle(h);
				KillFlame(flame1, flame2);
				FlameHandle[client]=INVALID_HANDLE;
				StopSound(client, SNDCHAN_AUTO, SOUND_FLAME);
				continue;

			}
			if(flametime<time)
			{
				CloseHandle(h);
				KillFlame(flame1, flame2);
				FlameHandle[client]=INVALID_HANDLE;
				StopSound(client, SNDCHAN_AUTO, SOUND_FLAME);
				continue;
			}
 		
			GetClientEyePosition(client, Origin);
 			GetClientEyeAngles(client, Angles);

	 
			GetAngleVectors(Angles, AnglesVec, NULL_VECTOR, NULL_VECTOR);
			
			StartPoint[0] = Origin[0] + (AnglesVec[0]*36.0);
			StartPoint[1] = Origin[1] + (AnglesVec[1]*36.0);
			StartPoint[2] = Origin[2] + (AnglesVec[2]*36.0);

			EndPoint[0] = Origin[0] + (AnglesVec[0]*flamedistance);
			EndPoint[1] = Origin[1] + (AnglesVec[1]*flamedistance);
			EndPoint[2] = Origin[2] + (AnglesVec[2]*flamedistance);
									
			new Handle:trace = TR_TraceRayFilterEx(Origin, EndPoint, MASK_SOLID, RayType_EndPoint, TraceRayDontHitLive, client);
			if(TR_DidHit(trace))
			{							
				TR_GetEndPosition(pos, trace);
				EndPoint[0]=pos[0];
				EndPoint[1]=pos[1];
				EndPoint[2]=pos[2];
			}
			CloseHandle(trace);

			new Float:dis=GetVectorDistance(StartPoint, EndPoint);
			new Float:dradius=flameradius;
			new Float:k=flameradius;
			do
			{
				pos[0] = StartPoint[0] + (AnglesVec[0]*k);
				pos[1] = StartPoint[1] + (AnglesVec[1]*k);
				pos[2] = StartPoint[2] + (AnglesVec[2]*k);
				k+=flameradius;
 
				new pointHurt = CreateEntityByName("point_hurt"); 
				DispatchKeyValueFloat(pointHurt, "DamageRadius", dradius); 
				if(fire==1)
				{
					DispatchKeyValueFloat(pointHurt, "Damage", flamedamage); 
					DispatchKeyValue(pointHurt, "DamageType", "8"); 
				}
				else
				{
					DispatchKeyValueFloat(pointHurt, "Damage", flamedamage2); 
					DispatchKeyValue(pointHurt, "DamageType", "64"); 
				}
				DispatchKeyValue(pointHurt, "DamageDelay", "0.0"); 
				DispatchSpawn(pointHurt);
				TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR); 
				AcceptEntityInput(pointHurt, "Hurt", client); 
				AcceptEntityInput(pointHurt, "Kill"); 
				dradius+=10.0;
			}while(k<=dis );

			if(dis>=flameradius)
			{
				new pointHurt = CreateEntityByName("point_hurt"); 
				SetEntPropEnt(pointHurt, Prop_Data, "m_hOwnerEntity", client)	;

 				DispatchKeyValueFloat(pointHurt, "DamageRadius", flameradius); 
				if(fire==1)
				{
					DispatchKeyValueFloat(pointHurt, "Damage", flamedamage); 
					DispatchKeyValue(pointHurt, "DamageType", "8"); 
				}
				else
				{
					DispatchKeyValueFloat(pointHurt, "Damage", flamedamage2); 
					DispatchKeyValue(pointHurt, "DamageType", "64"); 
				}

				DispatchKeyValue(pointHurt, "DamageDelay", "0.0"); 
				DispatchSpawn(pointHurt);
				TeleportEntity(pointHurt, EndPoint, NULL_VECTOR, NULL_VECTOR); 
				AcceptEntityInput(pointHurt, "Hurt", client); 
				AcceptEntityInput(pointHurt, "Kill"); 
			}
 			ShowBar2(client, "fuel left", flametime-time, flamelife);
 
		}
	}
	return Plugin_Continue;
}

public Action:sm_flame(client, args)
{ 
	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Continue; 
	if(!IsValidAliveClient(client)) return Plugin_Continue;
	if(GetClientTeam(client)!=2)
	{
		return Plugin_Continue;
	}
	if(FlameHandle[client]!=INVALID_HANDLE)
	{
		new	Handle:h=FlameHandle[client];
		ResetPack(h);
 		new flame1=ReadPackCell(h);
		new flame2=ReadPackCell(h);
		CloseHandle(h);
		KillFlame(flame1, flame2);
		FlameHandle[client]=INVALID_HANDLE;
		StopSound(client, SNDCHAN_AUTO, SOUND_FLAME);
		return Plugin_Continue;
	}

 	new bool:pointleft=true;
 
	new bool:weaponok=false;
 
	if(bullet_flame[client]-1<0 || GetConVarInt(w_enable_flame)==0)
	{
		pointleft=false;
	}
	decl String:weapon[32];
	GetClientWeapon(client, weapon, 32);
 	if( StrContains(weapon, "shot")>=0 || StrContains(weapon, "rifle")>=0 || StrContains(weapon, "smg")>=0 || StrContains(weapon, "magnum")>=0 || StrContains(weapon, "sniper")>=0 || StrContains(weapon, "launcher")>=0)
	{
 		weaponok=true;
	}
	if(weaponok )
	{
		if(pointleft )
		{
 
 			decl Float:vAngles[3];
			decl Float:vOrigin[3];
			decl Float:aOrigin[3];
			 
			decl Float:AnglesVec[3];
			 
			 					
			decl String:tName[128];
		 
			
			GetClientEyePosition(client, vOrigin);
			GetClientAbsOrigin(client, aOrigin);
			GetClientEyeAngles(client, vAngles);
			
			GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);
		 
			Format(tName, sizeof(tName), "target%d", client);
			DispatchKeyValue(client, "targetname", tName);
			
		 
			decl String:tempstring[128];
			decl String:flame_name[128];
			Format(flame_name, sizeof(flame_name), "Flame%i", client);
			new flame = CreateEntityByName("env_steam");
			DispatchKeyValue(flame,"targetname", flame_name);
			DispatchKeyValue(flame, "parentname", tName);
			DispatchKeyValue(flame,"SpawnFlags", "1");
			DispatchKeyValue(flame,"Type", "0");
		 
			DispatchKeyValue(flame,"InitialState", "1");
			DispatchKeyValue(flame,"Spreadspeed", "10");
			DispatchKeyValue(flame,"Speed", "1000");
			DispatchKeyValue(flame,"Startsize", "4");
			DispatchKeyValue(flame,"EndSize", "140");
			DispatchKeyValue(flame,"Rate", "15");
			DispatchKeyValue(flame,"RenderColor", "16 85 160");
			
			GetConVarString(w_flame_distance, tempstring, 128);
			DispatchKeyValue(flame,"JetLength", tempstring);

 
			DispatchKeyValue(flame,"RenderAmt", "180");
			DispatchSpawn(flame);
			TeleportEntity(flame, vOrigin, AnglesVec, NULL_VECTOR);
			SetVariantString(tName);
			AcceptEntityInput(flame, "SetParent", flame, flame, 0);
			SetVariantString("forward");
			AcceptEntityInput(flame, "SetParentAttachment", flame, flame, 0);
			AcceptEntityInput(flame, "TurnOn");
			
			decl String:flame_name2[128];
			Format(flame_name2, sizeof(flame_name2), "Flame2%i", client);
			new flame2 = CreateEntityByName("env_steam");
			DispatchKeyValue(flame2,"targetname", flame_name2);
			DispatchKeyValue(flame2, "parentname", tName);
			DispatchKeyValue(flame2,"SpawnFlags", "1");
			if(L4D2Version)			DispatchKeyValue(flame2,"Type", "0");
			else DispatchKeyValue(flame2,"Type", "1");
			DispatchKeyValue(flame2,"InitialState", "1");
			DispatchKeyValue(flame2,"Spreadspeed", "10");
			DispatchKeyValue(flame2,"Speed", "500");
			DispatchKeyValue(flame2,"Startsize", "7");
			DispatchKeyValue(flame2,"EndSize", "100");
			DispatchKeyValue(flame2,"Rate", "20");
			GetConVarString(w_flame_distance, tempstring, 128 );
			DispatchKeyValue(flame2,"JetLength", tempstring);

	 
			DispatchSpawn(flame2);
			TeleportEntity(flame2, vOrigin, AnglesVec, NULL_VECTOR);
			SetVariantString(tName);
			AcceptEntityInput(flame2, "SetParent", flame2, flame2, 0);
			SetVariantString("forward");
			AcceptEntityInput(flame2, "SetParentAttachment", flame2, flame2, 0);
			AcceptEntityInput(flame2, "TurnOn");

			EmitSoundToAll(SOUND_FLAME, client);
 
 			new Float:time = GetConVarFloat(w_flame_life)+ GetEngineTime();
			new Handle:flamedata = CreateDataPack();
 			WritePackCell(flamedata, flame);
			WritePackCell(flamedata, flame2);
			WritePackFloat(flamedata, time);
			WritePackCell(flamedata, GetConVarInt(w_flame_fire));
 			FlameHandle[client]=flamedata;
 			 
			bullet_flame[client]-=1;
			PrintHintText(client, "fuel remain: %d", bullet_flame[client]);
	 
		}
		else
		{
			PrintHintText(client, "not enough fuel");
		}
	}
	else
	{
		PrintHintText(client, "use it with primary weapon");
	}
	return Plugin_Handled;
}
AddControl(client)
{ 
	if(GameMode==2 && GetConVarInt(w_versus)==0)return ;
	if(!IsValidAliveClient(client)) return ;
	if(GetClientTeam(client)!=3)
	{
		return ;
	}
	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:aOrigin[3];
	decl Float:AnglesVec[3];
 			
 
	GetClientEyePosition(client, vOrigin);
	GetClientAbsOrigin(client, aOrigin);
	GetClientEyeAngles(client, vAngles);
 	GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);

	decl String:tName[128];
	Format(tName, sizeof(tName), "target%d", client);
	DispatchKeyValue(client, "targetname", tName);
	 
	decl String:chase_name[128];
	Format(chase_name, sizeof(chase_name), "infected_chase%i", client);
	new chase = CreateEntityByName("info_goal_infected_chase");
	DispatchKeyValue(chase,"targetname", chase_name);
	DispatchKeyValue(chase, "parentname", tName);
 
 	DispatchSpawn(chase);
	TeleportEntity(chase, vOrigin, AnglesVec, NULL_VECTOR);
	SetVariantString(tName);
	AcceptEntityInput(chase, "SetParent", chase, chase, 0);
	SetVariantString("forward");
	AcceptEntityInput(chase, "Enable");

	AttachParticle(chase, "weapon_pipebomb_blinking_light", vOrigin);
	control[client]=chase;
	CreateTimer(50.0, DelControl, client);
	return ;
}
RemoveControl(client)
{
	if(control[client]!=0)
	{
		DeleteEntity(control[client], "info_goal_infected_chase");
	}
	control[client]=0;
}
public Action:DelControl(Handle:h_Timer, any:client)
{
	RemoveControl(client);
	return Plugin_Continue;
}

public Action:selfkill(client, args)
{ 
	if(GameMode==2 && GetConVarInt(w_versus)==0)return Plugin_Handled;
	if(!IsValidAliveClient(client)) return Plugin_Continue;
	if(GetClientTeam(client)!=2)
	{
		return Plugin_Continue;
	}
	if(ZBHandle[client]!=INVALID_HANDLE)
	{
		return Plugin_Continue;
	}

	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:aOrigin[3];
	decl Float:AnglesVec[3];
 			
 
	GetClientEyePosition(client, vOrigin);
	GetClientAbsOrigin(client, aOrigin);
	GetClientEyeAngles(client, vAngles);
 	GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);

	decl String:tName[128];
	Format(tName, sizeof(tName), "target%i", client);
	DispatchKeyValue(client, "targetname", tName);
	 
	decl String:chase_name[128];
	Format(chase_name, sizeof(chase_name), "infected_chase%i", client);
	new chase = CreateEntityByName("info_goal_infected_chase");
	DispatchKeyValue(chase,"targetname", chase_name);
	DispatchKeyValue(chase, "parentname", tName);
 
 	DispatchSpawn(chase);
	TeleportEntity(chase, vOrigin, AnglesVec, NULL_VECTOR);
	SetVariantString(tName);
	AcceptEntityInput(chase, "SetParent", chase, chase, 0);
	SetVariantString("forward");
	AcceptEntityInput(chase, "Enable");

	AttachParticle(chase, "weapon_pipebomb_blinking_light", vOrigin)

	new Handle:zbdata = CreateDataPack();
	WritePackCell(zbdata, chase);
 
	ZBHandle[client]=zbdata;
	ZBTick[client]=0;
	CreateTimer(0.10, ZBTimer, client, TIMER_REPEAT);
	CreateTimer(20.0, DelZB, chase, TIMER_REPEAT);

	PrintHintText(client, "suicide...");
	PrintToChatAll("\x04%N \x03start suicide bomb", client);
 	return Plugin_Handled;
}
public Action:DelZB(Handle:h_Timer, any:chase)
{
	DeleteEntity(chase, "info_goal_infected_chase");
	return Plugin_Continue;
}
public Action:ZBTimer(Handle:h_Timer, any:client)
{
	decl Float:f_Origin[3];
	if(ZBHandle[client]==INVALID_HANDLE) return Plugin_Stop;
	if(IsValidAliveClient(client))
	{
		GetClientEyePosition(client, f_Origin); 
		ZBPos[client][0]=f_Origin[0];
		ZBPos[client][1]=f_Origin[1];
		ZBPos[client][2]=f_Origin[2];
	}
	else
	{
		f_Origin[0]=ZBPos[client][0];
		f_Origin[1]=ZBPos[client][1];
		f_Origin[2]=ZBPos[client][2];
	}
	switch (ZBTick[client])
	{
		case 0,10,20,30,35,40,45,50,54,58,62,65,68,71,74,76,78,80,82,84,86,88,90:
			EmitSoundToAll(SOUND_PIPEBOMB, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, f_Origin, NULL_VECTOR, false, 0.0)
	}
	
	if (ZBTick[client] > 90)
		EmitSoundToAll(SOUND_PIPEBOMB, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, f_Origin, NULL_VECTOR, false, 0.0)
	if(ZBTick[client]>100)
	{
		ResetPack(ZBHandle[client]);
 		new chase=ReadPackCell(ZBHandle[client]);
		DeleteEntity(chase, "info_goal_infected_chase");
		CloseHandle(ZBHandle[client]);
		ZBHandle[client]=INVALID_HANDLE;

		decl Float:pos[3];
 
		pos[0]=ZBPos[client][0];
		pos[1]=ZBPos[client][1];
		pos[2]=ZBPos[client][2];

		new explode=GetConVarInt(w_explode_tnt);
		new ent1=0;
		new ent2=0;
		new ent3=0;
		if(explode==1)
		{
			ent1=CreateEntityByName("prop_physics"); 
			SetEntPropEnt(ent1, Prop_Data, "m_hOwnerEntity", client)	;	
			DispatchKeyValue(ent1, "model", "models/props_junk/propanecanister001a.mdl"); 
			DispatchSpawn(ent1); 
			TeleportEntity(ent1, pos, NULL_VECTOR, NULL_VECTOR);
			ActivateEntity(ent1);
			SetEntityRenderMode(ent1, RenderMode:3);
			SetEntityRenderColor(ent1, 0, 0, 0, 0);
			AcceptEntityInput(ent1, "Ignite", client, client);

			ent2=CreateEntityByName("prop_physics"); 
			SetEntPropEnt(ent2, Prop_Data, "m_hOwnerEntity", client)	;	
			DispatchKeyValue(ent2, "model", "models/props_junk/propanecanister001a.mdl"); 
			DispatchSpawn(ent2); 
			TeleportEntity(ent2, pos, NULL_VECTOR, NULL_VECTOR);
			ActivateEntity(ent2);
			SetEntityRenderMode(ent2, RenderMode:3);
			SetEntityRenderColor(ent2, 0, 0, 0, 0);
			AcceptEntityInput(ent2, "Ignite", client, client);

			//ent3=CreateEntityByName("prop_physics"); 
			//SetEntPropEnt(ent3, Prop_Data, "m_hOwnerEntity", client)	;	
			//DispatchKeyValue(ent3, "model", "models/props_junk/propanecanister001a.mdl"); 
			//DispatchSpawn(ent3); 
			//TeleportEntity(ent3, pos, NULL_VECTOR, NULL_VECTOR);
			//ActivateEntity(ent3);
			//SetEntityRenderMode(ent3, RenderMode:3);
			//SetEntityRenderColor(ent3, 0, 0, 0, 0);
			//AcceptEntityInput(ent3, "Ignite", client, client);
		}
		new Handle:h=CreateDataPack();

		WritePackCell(h, client);
		WritePackCell(h, ent1);
		WritePackCell(h, ent2);
		WritePackCell(h, ent3);
		WritePackCell(h, explode);

		WritePackFloat(h, pos[0]);
		WritePackFloat(h, pos[1]);
		WritePackFloat(h, pos[2]);
		
		WritePackFloat(h, GetConVarFloat(w_damage_tnt));
		WritePackFloat(h, GetConVarFloat(w_radius_tnt));
		WritePackFloat(h, GetConVarFloat(w_pushforce_tnt));

		CreateTimer(GetConVarFloat(w_delay2), ExplodeTnT, h);
		CreateTimer(GetConVarFloat(w_delay2)+0.5, KillPlayer, client);

		return Plugin_Stop;
	}
	ZBTick[client]++;
 	return Plugin_Continue;
}
public Action:KillPlayer(Handle:timer, any:client)
{
	if(IsValidAliveClient(client))
	{
		DamageEffect(client, "1000");
	}
}
public AttachParticle(i_Ent, String:s_Effect[], Float:f_Origin[3])
{
	decl i_Particle, String:s_TargetName[32]
	
	i_Particle = CreateEntityByName("info_particle_system")
	
	if (IsValidEdict(i_Particle))
	{
	 
		f_Origin[2] -= 7.5;
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

KillFlame(ent1, ent2)
{
 
	decl String:classname[256];
	if (IsValidEntity(ent1))
	{
		AcceptEntityInput(ent1, "TurnOff");
		GetEdictClassname(ent1, classname, sizeof(classname));
		if (StrEqual(classname, "env_steam", false))
		{
			RemoveEdict(ent1);
		}
		
	}
	
	if (IsValidEntity(ent2))
	{
		AcceptEntityInput(ent2, "TurnOff");
		GetEdictClassname(ent2, classname, sizeof(classname));
		if (StrEqual(classname, "env_steam", false))
		 {
			RemoveEdict(ent2);
		 }
	}
}



public TraceToEntity(client)
{
	decl Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos); 
	GetClientEyeAngles(client, vecClientEyeAng); 

	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	
	if (TR_DidHit(INVALID_HANDLE))
	{
		new TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
		
		decl Float:pos[3];
		GetEntPropVector(TRIndex, Prop_Send, "m_vecOrigin", pos);
		decl String:edictname[128];
		GetEdictClassname(TRIndex, edictname, 128);
		if(StrContains(edictname, "infected")>=0)
		{
			return -1;
		}
		if (GetVectorDistance(vecClientEyePos, pos)>GetConVarFloat(w_grab_maxdistance))
		{
			return -2;
		}
		
		if(IsValidAliveClient(TRIndex))
		{
 			if(IsPlayerTank(TRIndex))
			{
				return -3;
			}
			if(GetClientTeam(TRIndex)==2)
			{
				if(GetVectorDistance(vecClientEyePos, pos)>600.0)
				{
					return -2;
				}
			}
		}
		return TRIndex;
	}
	return -1;
}
bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

stock bool:IsValidAliveClient(client)
{
 if (client <= 0) return false;
 else if (client > MaxClients) return false;
 else if(!IsClientInGame(client))return false;
 else if (!IsPlayerAlive(client)) return false;
	else return true;
}
bool:IsPlayerTank (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		return true;
	return false;
}