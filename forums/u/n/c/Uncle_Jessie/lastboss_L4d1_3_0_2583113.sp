/******************************************************
* 				L4D2: Last Boss v3.0
*					Author: ztar
* 			Web: http://ztar.blog7.fc2.com/
*******************************************************/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "3.0"
#define DEBUG 0

#define ON			1
#define OFF			0

#define FORMONE		1
#define FORMTWO		2
#define FORMTHREE	3
#define FORMFOUR	4
#define FORMFIVE	5
#define FORMSIX	    6
#define FORMSEVEN	7
#define FORMEIGHT	8
#define DEAD		-1

#define SURVIVOR	2
#define CLASS_TANK	5 //ENTIDAD DEL TANK PARA L4D1
#define MOLOTOV 	0
#define EXPLODE 	1
#define ENTITY_GASCAN	"models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"
#define ENTITY_TIRE		"models/props_vehicles/tire001c_car.mdl"

/* Sound */
#define SOUND_EXPLODE	"animation/APC_Idle_Loop.wav"
#define SOUND_SPAWN		"music/zombat/GatesOfHell.wav"
#define SOUND_BCLAW		"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SOUND_GCLAW		"plats/churchbell_end.wav"
#define SOUND_DCLAW		"ambient/Random_Amb_SFX/Dist_Pistol_02.wav"
#define SOUND_QUAKE		"player/tank/hit/pound_victim_2.wav"
#define SOUND_STEEL		"physics/metal/metal_solid_impact_hard5.wav"
#define SOUND_DEAD		"npc/infected/action/die/male/death_42.wav"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define SOUND_DEFROST	"physics/glass/glass_sheet_break1.wav"
#define SOUND_LAZY		"npc/infected/action/rage/female/rage_68.wav"
#define SOUND_QUICK		"ambient/water/distant_drip2.wav"
#define SOUND_ROAR	    "player/tank/voice/pain/Tank_Pain_03.wav"
#define SOUND_RABIES	"player/pz/voice/attack/zombiedog_attack2.wav"
#define SOUND_BOMBARD	"animation/van_inside_hit_wall.wav"
#define SOUND_CHANGE	"items/suitchargeok1.wav"
#define SOUND_HOWL		"player/tank/voice/pain/tank_fire_06.wav"
#define SOUND_WARP		"ambient/energy/zap9.wav"

/* Particle */
#define PARTICLE_SPAWN	"electrical_arc_01_system"
#define PARTICLE_DEATH	"gas_explosion_main"
#define PARTICLE_FOURTH	"apc_wheel_smoke1"
#define PARTICLE_EIGHTH	"aircraft_destroy_fastFireTrail"
#define PARTICLE_WARP	"water_splash"

/* Message */
#define MESSAGE_SPAWN	"\x03[EL ULTIMO JEFE] \x04\x01¡¡¡PELIGRO!!! MUTACION ESPECIAL DEL TANK \x05 ¡¡¡PREPARATE!!!\x01【\x03 JEFE FINAL DE 8 FASES \x01】"
#define MESSAGE_SPAWN2	"\x03[EL ULTIMO JEFE] \x04PRIMERA \x01FASE \x05INFECTADO ESPECIAL \x01| \x04VELOCIDA: \x05 VARIADA"
#define MESSAGE_SECOND	"\x03[EL ULTIMO JEFE] \x04SEGUNDA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03GIGANTE DE ACERO\x01】"
#define MESSAGE_THIRD	"\x03[EL ULTIMO JEFE] \x04TERCERA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03SUPER PODER\x01】"
#define MESSAGE_FOURTH	"\x03[EL ULTIMO JEFE] \x04CUARTA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03VISION OSCURA\x01】"
#define MESSAGE_FIFTH	"\x03[EL ULTIMO JEFE] \x04QUINTA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03INMOVILIDAD\x01】"
#define MESSAGE_SIXTH	"\x03[EL ULTIMO JEFE] \x04SEXTA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03GOLPE EXPLOSIVO\x01】"
#define MESSAGE_SEVENTH	"\x03[EL ULTIMO JEFE] \x04SEPTIMA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03GOLPE CONGELANTE\x01】"
#define MESSAGE_EIGHTH	"\x03[EL ULTIMO JEFE] \x04ULTIMA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03ESCUDO DE FUEGO\x01】"

/* Parameter */
new Handle:sm_lastboss_enable				= INVALID_HANDLE;
new Handle:sm_lastboss_enable_announce		= INVALID_HANDLE;
new Handle:sm_lastboss_enable_steel			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_bomb			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_stealth		= INVALID_HANDLE;
new Handle:sm_lastboss_enable_gravity		= INVALID_HANDLE;
new Handle:sm_lastboss_enable_burn			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_jump			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_quake			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_comet			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_dread			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_lazy			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_rabies		= INVALID_HANDLE;
new Handle:sm_lastboss_enable_freeze		= INVALID_HANDLE;
new Handle:sm_lastboss_enable_gush			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_abyss			= INVALID_HANDLE;
new Handle:sm_lastboss_enable_warp			= INVALID_HANDLE;

new Handle:sm_lastboss_health_max	 		= INVALID_HANDLE;
new Handle:sm_lastboss_health_second 		= INVALID_HANDLE;
new Handle:sm_lastboss_health_third	 		= INVALID_HANDLE;
new Handle:sm_lastboss_health_fourth	 	= INVALID_HANDLE;
new Handle:sm_lastboss_health_fifth	 		= INVALID_HANDLE;
new Handle:sm_lastboss_health_sixth	 		= INVALID_HANDLE;
new Handle:sm_lastboss_health_seventh	 	= INVALID_HANDLE;
new Handle:sm_lastboss_health_eighth	 	= INVALID_HANDLE;

new Handle:sm_lastboss_color_first 	 		= INVALID_HANDLE;
new Handle:sm_lastboss_color_second	 		= INVALID_HANDLE;
new Handle:sm_lastboss_color_third 	 		= INVALID_HANDLE;
new Handle:sm_lastboss_color_fourth			= INVALID_HANDLE;
new Handle:sm_lastboss_color_fifth			= INVALID_HANDLE;
new Handle:sm_lastboss_color_sixth			= INVALID_HANDLE;
new Handle:sm_lastboss_color_seventh		= INVALID_HANDLE;
new Handle:sm_lastboss_color_eighth			= INVALID_HANDLE;

new Handle:sm_lastboss_force_first 	 		= INVALID_HANDLE;
new Handle:sm_lastboss_force_second			= INVALID_HANDLE;
new Handle:sm_lastboss_force_third 			= INVALID_HANDLE;
new Handle:sm_lastboss_force_fourth			= INVALID_HANDLE;
new Handle:sm_lastboss_force_fifth			= INVALID_HANDLE;
new Handle:sm_lastboss_force_sixth			= INVALID_HANDLE;
new Handle:sm_lastboss_force_seventh		= INVALID_HANDLE;
new Handle:sm_lastboss_force_eighth			= INVALID_HANDLE;

new Handle:sm_lastboss_speed_first 	 		= INVALID_HANDLE;
new Handle:sm_lastboss_speed_second	 		= INVALID_HANDLE;
new Handle:sm_lastboss_speed_third 	 		= INVALID_HANDLE;
new Handle:sm_lastboss_speed_fourth	 		= INVALID_HANDLE;
new Handle:sm_lastboss_speed_fifth	 		= INVALID_HANDLE;
new Handle:sm_lastboss_speed_sixth	 		= INVALID_HANDLE;
new Handle:sm_lastboss_speed_seventh	 	= INVALID_HANDLE;
new Handle:sm_lastboss_speed_eighth	 		= INVALID_HANDLE;

new Handle:sm_lastboss_weight_second		= INVALID_HANDLE;
new Handle:sm_lastboss_stealth_fourth 		= INVALID_HANDLE;
new Handle:sm_lastboss_jumpinterval_eighth	= INVALID_HANDLE;
new Handle:sm_lastboss_jumpheight_eighth	= INVALID_HANDLE;
new Handle:sm_lastboss_gravityinterval 		= INVALID_HANDLE;
new Handle:sm_lastboss_quake_radius 		= INVALID_HANDLE;
new Handle:sm_lastboss_quake_force	 		= INVALID_HANDLE;
new Handle:sm_lastboss_dreadinterval 		= INVALID_HANDLE;
new Handle:sm_lastboss_dreadrate	 		= INVALID_HANDLE;
new Handle:sm_lastboss_freezetime 	 	 	= INVALID_HANDLE;
new Handle:sm_lastboss_freezeinterval 	 	= INVALID_HANDLE;
new Handle:sm_lastboss_lazytime	 	 	 	= INVALID_HANDLE;
new Handle:sm_lastboss_lazyspeed 	 	 	= INVALID_HANDLE;
new Handle:sm_lastboss_rabiestime 	 	    = INVALID_HANDLE;
new Handle:sm_lastboss_bombradius	 	 	= INVALID_HANDLE;
new Handle:sm_lastboss_bombdamage 	 	 	= INVALID_HANDLE;
new Handle:sm_lastboss_bombardforce  	 	= INVALID_HANDLE;
new Handle:sm_lastboss_eighth_c5m5_bridge	= INVALID_HANDLE;
new Handle:sm_lastboss_warp_interval		= INVALID_HANDLE;

/* Timer Handle */
new Handle:TimerUpdate = INVALID_HANDLE;

// UserMessageId for Fade.
new UserMsg:g_FadeUserMsgId;

new Float:ToxinAngle[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

/* Grobal */
new alpharate;
new visibility;
new bossflag = OFF;
new lastflag = OFF;
new idBoss = DEAD;
new form_prev = DEAD;
new force_default;
new g_iVelocity	= -1;
new wavecount;
new Float:ftlPos[3];
new bool:g_l4d1 = false;
new freeze[MAXPLAYERS+1];
new bool:isSlowed[MAXPLAYERS+1] = false;
static laggedMovementOffset = 0;
new Rabies[MAXPLAYERS+1];
new Toxin[MAXPLAYERS+1];
new Float:trsPos[MAXPLAYERS+1][3];

public Plugin:myinfo = 
{
	name = "[L4D2] LAST BOSS",
	author = "ztar & IxAvnoMonvAxI",
	description = "Special Tank spawns during finale.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

/******************************************************
*	When plugin started
*******************************************************/
public OnPluginStart()
{
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	g_l4d1 = false;
	if(StrEqual(game, "left4dead"))
		g_l4d1 = true;
	
	/* Enable/Disable */
	sm_lastboss_enable		    = CreateConVar("sm_lastboss_enable", "1", "특수 탱크의 출현 여부는? (0: 출현 안 함 | 1: 구조 요청 후 | 2: 항상 | 3: 2단계 탱크만)", FCVAR_NOTIFY);
	sm_lastboss_enable_announce	= CreateConVar("sm_lastboss_enable_announce", "1", "안내 문구를 표시할 것인가? (0: 표시 안 함 | 1: 표시함)", FCVAR_NOTIFY);
	sm_lastboss_enable_steel	= CreateConVar("sm_lastboss_enable_steel", "1",	"강철 피부의 사용 여부는? (0: 사용 안 함 | 1: 사용함)", FCVAR_NOTIFY);
	sm_lastboss_enable_bomb	    = CreateConVar("sm_lastboss_enable_bomb", "1", "폭발 주먹의 사용 여부는? (0: 사용 안 함 | 1: 사용함)", FCVAR_NOTIFY);
	sm_lastboss_enable_stealth	= CreateConVar("sm_lastboss_enable_stealth", "1", "탱크가 서서히 투명해지고 화염 공격의 영향도 받지 않는가? (0: 사용 안 함 | 1: 사용함)", FCVAR_NOTIFY);
	sm_lastboss_enable_gravity	= CreateConVar("sm_lastboss_enable_gravity", "1", "타격한 생존자의 중력을 몇 초간 줄일 것인가? (0: 사용 안 함 | 1: 사용함)", FCVAR_NOTIFY);
	sm_lastboss_enable_burn		= CreateConVar("sm_lastboss_enable_burn", "1", "생존자를 타격하면 일시적으로 체력이 회복되는가? (0: 회복되지 않음 | 1: 회복됨)", FCVAR_NOTIFY);
	sm_lastboss_enable_quake	= CreateConVar("sm_lastboss_enable_quake", "1",	"무력화 상태인 생존자도 날려보낼 수 있는가? (0: 불가능함 | 1: 가능함)", FCVAR_NOTIFY);
	sm_lastboss_enable_jump		= CreateConVar("sm_lastboss_enable_jump", "1", "탱크가 빈번히 도약하는가? (0: 도약하지 않음 | 1: 도약함)", FCVAR_NOTIFY);
	sm_lastboss_enable_comet	= CreateConVar("sm_lastboss_enable_comet", "1", "탱크가 던진 바위가 생존자를 맞추면 폭발하는가? (0: 폭발하지 않음 | 1: 폭발함)", FCVAR_NOTIFY);
	sm_lastboss_enable_dread	= CreateConVar("sm_lastboss_enable_dread", "1", "공격한 생존자의 시야를 몇 초간 가릴 것인가? (0: 가리지 않음 | 1: 가림)", FCVAR_NOTIFY);
	sm_lastboss_enable_lazy	    = CreateConVar("sm_lastboss_enable_lazy", "1", "공격을 받은 생존자의 이동 속도가 느려지는가? (0: 사용 안 함 | 1: 사용함)", FCVAR_NOTIFY);
	sm_lastboss_enable_rabies	= CreateConVar("sm_lastboss_enable_rabies", "1", "공격을 받은 생존자의 체력이 감소하는가? (0: 사용 안 함 | 1: 사용함)", FCVAR_NOTIFY);
	sm_lastboss_enable_freeze	= CreateConVar("sm_lastboss_enable_freeze", "1", "공격을 받은 생존자는 결빙하는가? (0: 사용 안 함 | 1: 사용함)", FCVAR_NOTIFY);	
	sm_lastboss_enable_gush		= CreateConVar("sm_lastboss_enable_gush", "1", "화염 공격 (Lethal Weapon)의 사용 여부는? (0: 사용 안 함 | 1: 사용함)", FCVAR_NOTIFY);
	sm_lastboss_enable_abyss	= CreateConVar("sm_lastboss_enable_abyss", "1", "포효하여 감염자의 급증하는 여부는? (0: 사용 안 함 | 1: 8단 변신만 | 2: 모든 변신)", FCVAR_NOTIFY);
	sm_lastboss_enable_warp		= CreateConVar("sm_lastboss_enable_warp", "1", "순간 이동의 사용 여부는? (0: 사용 안 함 | 1: 사용함)", FCVAR_NOTIFY);

	/* Health */
	sm_lastboss_health_max	  = CreateConVar("sm_lastboss_health_max", "62000", "기본 탱크의 체력은?", FCVAR_NOTIFY);
	sm_lastboss_health_second = CreateConVar("sm_lastboss_health_second","54000", "2단 변신 때의 탱크의 체력은?", FCVAR_NOTIFY);
	sm_lastboss_health_third  = CreateConVar("sm_lastboss_health_third", "46000", "3단 변신 때의 탱크의 체력은?", FCVAR_NOTIFY);
	sm_lastboss_health_fourth = CreateConVar("sm_lastboss_health_fourth", "38000", "4단 변신 때의 탱크의 체력은?", FCVAR_NOTIFY);
	sm_lastboss_health_fifth  = CreateConVar("sm_lastboss_health_fifth", "32000", "5단 변신 때의 탱크의 체력은?", FCVAR_NOTIFY);
	sm_lastboss_health_sixth  = CreateConVar("sm_lastboss_health_sixth", "24000", "6단 변신 때의 탱크의 체력은?", FCVAR_NOTIFY);
	sm_lastboss_health_seventh = CreateConVar("sm_lastboss_health_seventh", "16000", "7단 변신 때의 탱크의 체력은?", FCVAR_NOTIFY);
	sm_lastboss_health_eighth  = CreateConVar("sm_lastboss_health_eighth", "8000", "8단 변신 때의 탱크의 체력은?", FCVAR_NOTIFY);

	/* Color */
	sm_lastboss_color_first	  = CreateConVar("sm_lastboss_color_first", "255 255 80", "기본 탱크의 색감은? (노란색)", FCVAR_NOTIFY);
	sm_lastboss_color_second  = CreateConVar("sm_lastboss_color_second", "80 255 80", "2단 변신 탱크의 색감은? (연두색)", FCVAR_NOTIFY);
	sm_lastboss_color_third	  = CreateConVar("sm_lastboss_color_third", "153 153 255", "3단 변신 탱크의 색감은? (옅은 파란색)", FCVAR_NOTIFY);
	sm_lastboss_color_fourth  = CreateConVar("sm_lastboss_color_fourth", "80 80 255", "4단 변신 탱크의 색감은? (보라색 → 서서히 투명해짐)", FCVAR_NOTIFY);
	sm_lastboss_color_fifth	  = CreateConVar("sm_lastboss_color_fifth", "200 150 200", "5단 변신 탱크의 색감은? (짙은 분홍색)", FCVAR_NOTIFY);
	sm_lastboss_color_sixth	  = CreateConVar("sm_lastboss_color_sixth", "176 48 96", "6단 변신 탱크의 색감은? (적갈색)", FCVAR_NOTIFY);	
	sm_lastboss_color_seventh = CreateConVar("sm_lastboss_color_seventh", "0 128 255", "7단 변신 탱크의 색감은? (파란색)", FCVAR_NOTIFY);
	sm_lastboss_color_eighth  = CreateConVar("sm_lastboss_color_eighth", "255 80 80", "8단 변신 탱크의 색감은? (빨간색)", FCVAR_NOTIFY);

	/* Force */
	sm_lastboss_force_first	  = CreateConVar("sm_lastboss_force_first", "1000", "기본 탱크의 위력은?", FCVAR_NOTIFY);
	sm_lastboss_force_second  = CreateConVar("sm_lastboss_force_second", "1500", "2단 변신 탱크의 위력은?", FCVAR_NOTIFY);
	sm_lastboss_force_third	  = CreateConVar("sm_lastboss_force_third", "1100", "3단 변신 탱크의 위력은?", FCVAR_NOTIFY);
	sm_lastboss_force_fourth  = CreateConVar("sm_lastboss_force_fourth", "800", "4단 변신 탱크의 위력은?", FCVAR_NOTIFY);
	sm_lastboss_force_fifth	  = CreateConVar("sm_lastboss_force_fifth", "2000", "5단 변신 탱크의 위력은?", FCVAR_NOTIFY);
	sm_lastboss_force_sixth	  = CreateConVar("sm_lastboss_force_sixth", "1600", "6단 변신 탱크의 위력은?", FCVAR_NOTIFY);
	sm_lastboss_force_seventh = CreateConVar("sm_lastboss_force_seventh", "1300", "7단 변신 탱크의 위력은?", FCVAR_NOTIFY);
	sm_lastboss_force_eighth  = CreateConVar("sm_lastboss_force_eighth", "1800", "8단 변신 탱크의 위력은?", FCVAR_NOTIFY);
	
	/* Speed */
	sm_lastboss_speed_first	  = CreateConVar("sm_lastboss_speed_first", "0.9", "기본 탱크의 추가 이동 속도는?", FCVAR_NOTIFY);
	sm_lastboss_speed_second  = CreateConVar("sm_lastboss_speed_second", "0.9", "2단 변신 탱크의 추가 이동 속도는?", FCVAR_NOTIFY);
	sm_lastboss_speed_third	  = CreateConVar("sm_lastboss_speed_third", "0.9", "3단 변신 탱크의 추가 이동 속도는?", FCVAR_NOTIFY);
	sm_lastboss_speed_fourth  = CreateConVar("sm_lastboss_speed_fourth", "0.9", "4단 변신 탱크의 추가 이동 속도는?", FCVAR_NOTIFY);
	sm_lastboss_speed_fifth	  = CreateConVar("sm_lastboss_speed_fifth", "0.9", "5단 변신 탱크의 추가 이동 속도는?", FCVAR_NOTIFY);
	sm_lastboss_speed_sixth	  = CreateConVar("sm_lastboss_speed_sixth", "0.9", "6단 변신 탱크의 추가 이동 속도는?", FCVAR_NOTIFY);
	sm_lastboss_speed_seventh = CreateConVar("sm_lastboss_speed_seventh", "0.9", "7단 변신 탱크의 추가 이동 속도는?", FCVAR_NOTIFY);
	sm_lastboss_speed_eighth  = CreateConVar("sm_lastboss_speed_eighth", "1.1", "8단 변신 탱크의 추가 이동 속도는?", FCVAR_NOTIFY);
	
	/* Skill */
	sm_lastboss_weight_second		= CreateConVar("sm_lastboss_weight_second", "8.0", "탱크가 생존자의 중력을 줄이는 공격의 지속 시간은?", FCVAR_NOTIFY);
	sm_lastboss_stealth_fourth		= CreateConVar("sm_lastboss_stealth_fourth", "10.0", "탱크가 투명해지는 간격은?", FCVAR_NOTIFY);
	sm_lastboss_jumpinterval_eighth  = CreateConVar("sm_lastboss_jumpinterval_eighth", "1.0", "탱크가 도약하는 간격은?", FCVAR_NOTIFY);
	sm_lastboss_jumpheight_eighth  	= CreateConVar("sm_lastboss_jumpheight_eighth", "300.0", "탱크의 도약 높이는?", FCVAR_NOTIFY);
	sm_lastboss_gravityinterval		= CreateConVar("sm_lastboss_gravityinterval", "6.0", "탱크가 중력을 줄이는 공격의 간격은?", FCVAR_NOTIFY);
	sm_lastboss_quake_radius		= CreateConVar("sm_lastboss_quake_radius", "600.0", "탱크가 무력화된 생존자도 날릴 때의 거리는?", FCVAR_NOTIFY);
	sm_lastboss_quake_force			= CreateConVar("sm_lastboss_quake_force", "350.0", "무력화된 생존자도 날릴 때의 위력은?", FCVAR_NOTIFY);
	sm_lastboss_dreadinterval		= CreateConVar("sm_lastboss_dreadinterval", "8.0", "탱크가 생존자의 시야를 가리는 공격의 간격은?", FCVAR_NOTIFY);
	sm_lastboss_dreadrate			= CreateConVar("sm_lastboss_dreadrate", "235", "생존자의 시야를 가리는 속도는?", FCVAR_NOTIFY);
	sm_lastboss_freezetime		    = CreateConVar("sm_lastboss_freezetime", "10", "생존자가 결빙되는 시간은?", FCVAR_NOTIFY);
	sm_lastboss_freezeinterval	    = CreateConVar("sm_lastboss_freezeinterval", "6.0", "생존자를 결빙시키는 공격의 지연 시간은?", FCVAR_NOTIFY);
	sm_lastboss_lazytime			= CreateConVar("sm_lastboss_lazytime", "10.0", "생존자의 이동 속도가 감속되는 지속 시간은?", FCVAR_NOTIFY);
	sm_lastboss_lazyspeed		    = CreateConVar("sm_lastboss_lazyspeed", "0.3", "생존자의 감속되는 이동 속도는?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar("sm_lastboss_rabiesdamage", "10", "생존자의 체력이 감소하는 수치는?", FCVAR_NOTIFY);
	CreateConVar("sm_lastboss_lavadamage", "50", "생존자의 체력이 감소하는 수치는?", FCVAR_NOTIFY);
	sm_lastboss_rabiestime		    = CreateConVar("sm_lastboss_rabiestime", "10", "생존자의 체력이 감소하는 지속 시간은?", FCVAR_NOTIFY);
	sm_lastboss_bombradius			= CreateConVar("sm_lastboss_bombradius", "250", "탱크의 폭발하는 공격의 적용 범위는?", FCVAR_NOTIFY);
	sm_lastboss_bombdamage		    = CreateConVar("sm_lastboss_bombdamage", "300", "탱크의 폭발하는 공격의 위력은?", FCVAR_NOTIFY);
	sm_lastboss_bombardforce	    = CreateConVar("sm_lastboss_bombardforce", "600.0", "탱크의 폭발하는 공격으로 밀려나는 위력은?", FCVAR_NOTIFY);
	sm_lastboss_eighth_c5m5_bridge	= CreateConVar("sm_lastboss_eigth_c5m5_bridge", "0", "교구 마지막 구간이 시작되면, 8단 변신 탱크가 출현하는가? (0: 출현하지 않음 | 1: 출현함)", FCVAR_NOTIFY);
	sm_lastboss_warp_interval		= CreateConVar("sm_lastboss_warp_interval", "35.0", "탱크가 순간 이동하는 간격은?", FCVAR_NOTIFY);
	
	/* Event hook */
	HookEvent("round_start", Event_Round_Start);
	HookEvent("finale_start", Event_Finale_Start);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_incapacitated", Event_Player_Hurt);
	HookEvent("round_end", Event_RoundEnd);

	if(!g_l4d1)
		HookEvent("finale_bridge_lowering", Event_Finale_Start);

	AutoExecConfig(true, "l4d_lastboss 3.0");

	g_FadeUserMsgId = GetUserMessageId("Fade");	

	force_default = GetConVarInt(FindConVar("z_tank_throw_force"));
	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	
	if((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
		LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
}

/******************************************************
*	Initial functions
*******************************************************/
InitPrecache()
{
	/* Precache models */
	PrecacheModel(ENTITY_PROPANE, true);
	PrecacheModel(ENTITY_GASCAN, true);
	PrecacheModel(ENTITY_TIRE, true);
	
	/* Precache sounds */
	PrecacheSound(SOUND_EXPLODE, true);
	PrecacheSound(SOUND_SPAWN, true);
	PrecacheSound(SOUND_BCLAW, true);
	PrecacheSound(SOUND_GCLAW, true);
	PrecacheSound(SOUND_DCLAW, true);
	PrecacheSound(SOUND_QUAKE, true);
	PrecacheSound(SOUND_STEEL, true);
	PrecacheSound(SOUND_DEAD, true);
	PrecacheSound(SOUND_FREEZE, true);
	PrecacheSound(SOUND_DEFROST, true);
	PrecacheSound(SOUND_LAZY, true);
	PrecacheSound(SOUND_QUICK, true);
	PrecacheSound(SOUND_RABIES, true);
	PrecacheSound(SOUND_BOMBARD, true);
	PrecacheSound(SOUND_CHANGE, true);
	PrecacheSound(SOUND_HOWL, true);
	PrecacheSound(SOUND_WARP, true);
	
	/* Precache particles */
	PrecacheParticle(PARTICLE_SPAWN);
	PrecacheParticle(PARTICLE_DEATH);
	PrecacheParticle(PARTICLE_FOURTH);
	PrecacheParticle(PARTICLE_EIGHTH);
	PrecacheParticle(PARTICLE_WARP);
}

InitData()
{
	/* Reset flags */
	bossflag = OFF;
	lastflag = OFF;
	idBoss = DEAD;
	form_prev = DEAD;
	wavecount = 0;
	SetConVarInt(FindConVar("z_tank_throw_force"), force_default, true, true);
	CreateTimer(5.0, ChangeCVarDelay);
}

public OnMapStart()
{
	InitPrecache();
	InitData();
}

public OnMapEnd()
{
	InitData();
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	InitData();
}

public Action:ChangeCVarDelay(Handle:timer) 
{
	SetConVarInt(FindConVar("z_tank_burning_lifetime"), 15000);
	SetConVarInt(FindConVar("tank_burn_duration_expert"), 15000);
	SetConVarInt(FindConVar("tank_burn_duration_hard"), 15000);
	SetConVarInt(FindConVar("tank_burn_duration_normal"), 15000);
	SetConVarInt(FindConVar("tank_burn_duration_vs"), 15000);
	SetConVarInt(FindConVar("tank_stuck_time_suicide"), 500);
	
	//PrintToChatAll("Cvars changed");
}

public Action:Event_Finale_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	bossflag = ON;
	lastflag = OFF;
	
	/* Exception handling for some map */
	decl String:CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if(StrEqual(CurrentMap, "c1m4_atrium") || StrEqual(CurrentMap, "c2m5_concert") || StrEqual(CurrentMap, "c3m4_plantation") || StrEqual(CurrentMap, "c4m5_milltown_escape") || StrEqual(CurrentMap, "c5m5_bridge")
	|| StrEqual(CurrentMap, "c6m3_port") || StrEqual(CurrentMap, "c7m3_port") || StrEqual(CurrentMap, "c8m5_rooftop") || StrEqual(CurrentMap, "c13m4_cutthroatcreek"))
		wavecount = 2;
	else
		wavecount = 1;
}

/******************************************************
*	Event when Tank has spawned or dead
*******************************************************/
public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	/* Exception handling for some map */
	if(StrEqual(CurrentMap, "c1m4_atrium") || StrEqual(CurrentMap, "c2m5_concert") || StrEqual(CurrentMap, "c3m4_plantation") || StrEqual(CurrentMap, "c4m5_milltown_escape") || StrEqual(CurrentMap, "c5m5_bridge")
	|| StrEqual(CurrentMap, "c6m3_port") || StrEqual(CurrentMap, "c7m3_port") || StrEqual(CurrentMap, "c8m5_rooftop") || StrEqual(CurrentMap, "c13m4_cutthroatcreek"))
		bossflag = ON;
	
	/* Already exists? */
	if(idBoss != DEAD)
		return;
	
	/* Second Tank only? */
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
		return;
	
	/* Finale only */
	if( (bossflag && GetConVarInt(sm_lastboss_enable) == 1) || (GetConVarInt(sm_lastboss_enable) == 2) || (bossflag && GetConVarInt(sm_lastboss_enable) == 3))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(IsValidEntity(client) && IsClientInGame(client))
		{
			/* Get boss ID and set timer */
			CreateTimer(0.3, SetTankHealth, client);
			if(TimerUpdate != INVALID_HANDLE)
			{
				CloseHandle(TimerUpdate);
				TimerUpdate = INVALID_HANDLE;
			}
			TimerUpdate = CreateTimer(1.0, TankUpdate, _, TIMER_REPEAT);
			
			for(new j = 1; j <= MaxClients; j++)
			{
				if(IsClientInGame(j) && !IsFakeClient(j))
				{
					EmitSoundToClient(j, SOUND_SPAWN);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_announce))
			{
				PrintToChatAll(MESSAGE_SPAWN);
				PrintToChatAll(MESSAGE_SPAWN2);
			}
		}
	}
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client <= 0 || client > GetMaxClients())
		return;
	if(!IsValidEntity(client) || !IsClientInGame(client))
		return;
	if(GetEntProp(client, Prop_Send, "m_zombieClass") != CLASS_TANK)
		return;
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
	{
		wavecount++;
		return;
	}

	if((bossflag && GetConVarInt(sm_lastboss_enable) == 1) || (GetConVarInt(sm_lastboss_enable) == 2) || (bossflag && GetConVarInt(sm_lastboss_enable) == 3))
	{
		/* Explode and burn when died */
		if(idBoss)
		{
			decl Float:Pos[3];
			GetClientAbsOrigin(idBoss, Pos);
			EmitSoundToAll(SOUND_EXPLODE, idBoss);
			ShowParticle(Pos, PARTICLE_DEATH, 5.0);
			LittleFlower(Pos, MOLOTOV);
			LittleFlower(Pos, EXPLODE);
			idBoss = DEAD;
			form_prev = DEAD;
		}
	}
	
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
	{
		decl String:model[128];
            	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, ENTITY_TIRE))
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			
			if (owner != client) 
			{
				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			}
			
			AcceptEntityInput(entity, "Kill");
		}
	}
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			isSlowed[i] = false;
			SetEntityGravity(i, 1.0);
			Rabies[i] = 0;
			Toxin[i] = 0;
		}
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			isSlowed[i] = false;
			SetEntityGravity(i, 1.0);
			Rabies[i] = 0;
			Toxin[i] = 0;
		}
	}
}

public Action:SetTankHealth(Handle:timer, any:client)
{
	/* Set health and ID after spawning */
	idBoss = client;
	decl String:CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss))
	{
		/* In some map, Form is from the beginning to fourth */
		if(lastflag || (StrEqual(CurrentMap, "c5m5_bridge") && GetConVarInt(sm_lastboss_eighth_c5m5_bridge)))
			SetEntityHealth(idBoss, GetConVarInt(sm_lastboss_health_eighth));
		else
			SetEntityHealth(idBoss, GetConVarInt(sm_lastboss_health_max));
	}
}

/******************************************************
*	Special skills when attacking
*******************************************************/
public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if(!IsValidEntity(idBoss) || !IsClientInGame(idBoss) || idBoss == DEAD)
		return;
	
	/* Second Tank only? */
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
		return;
	
	/* Special ability */
	if( (bossflag && GetConVarInt(sm_lastboss_enable) == 1) || (GetConVarInt(sm_lastboss_enable) == 2) || (bossflag && GetConVarInt(sm_lastboss_enable) == 3))
	{
		if(StrEqual(weapon, "tank_claw") && attacker == idBoss)
		{
			if(GetConVarInt(sm_lastboss_enable_quake))
			{
				/* Skill:Earth Quake (If target is incapped) */
				SkillEarthQuake(target);
			}
			if(GetConVarInt(sm_lastboss_enable_gravity))
			{
				if(form_prev == FORMTWO)
				{
					/* Skill:Gravity Claw (Second form only) */
					SkillGravityClaw(target);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_bomb))
			{
				if(form_prev == FORMTHREE)
				{
					/* Skill:Bomb Claw (Third form only) */
					SkillBombClaw(target);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_dread))
			{
				if(form_prev == FORMFOUR)
				{
					/* Skill:Dread Claw (Fourth form only) */
					SkillDreadClaw(target);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_lazy))
			{
				if(form_prev == FORMFIVE)
				{
					/* Skill:Lazy Claw (Fifth form only) */
					SkillLazyClaw(target);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_rabies))
			{
				if(form_prev == FORMSIX)
				{
					/* Skill:Rabies Claw (Sixth form only) */
					SkillRabiesClaw(target);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_freeze))
			{
				if(form_prev == FORMSEVEN)
				{
					/* Skill:Freeze Claw (Seventh form only) */
					SkillFreezeClaw(target);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_burn))
			{
				if(form_prev == FORMEIGHT)
				{
					/* Skill:Burning Claw (Eighth form only) */
					SkillBurnClaw(target);
				}
			}
		}
		if(StrEqual(weapon, "tank_rock") && attacker == idBoss)
		{
			if(GetConVarInt(sm_lastboss_enable_comet))
			{
				if(form_prev == FORMEIGHT)
				{
					/* Skill:Comet Strike (Eighth form only) */
					SkillCometStrike(target, MOLOTOV);
				}
				else
				{
					/* Skill:Blast Rock (First-Seven form) */
					SkillCometStrike(target, EXPLODE);
				}
			}
		}
		if(StrEqual(weapon, "melee") && target == idBoss)
		{
			if(GetConVarInt(sm_lastboss_enable_steel))
			{
				if(form_prev == FORMTWO)
				{
					/* Skill:Steel Skin (Second form only) */
					EmitSoundToClient(attacker, SOUND_STEEL);
					SetEntityHealth(idBoss, (GetEventInt(event,"dmg_health") + GetEventInt(event,"health")));
				}
			}
			if(form_prev == FORMFOUR)
			{
				new random = GetRandomInt(1,4);
				if (random == 1)
				{
					ForceWeaponDrop(attacker);
					EmitSoundToClient(attacker, SOUND_DEAD);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_gush))
			{
				if(form_prev == FORMEIGHT)
				{
					/* Skill:Flame Gush (Eighth form only) */
					SkillFlameGush(attacker);
				}
			}
		}
	}
}

public SkillEarthQuake(target)
{
	decl Float:Pos[3], Float:tPos[3];
	
	if(IsPlayerIncapped(target))
	{
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(i == idBoss)
				continue;
			if(!IsClientInGame(i) || GetClientTeam(i) != 2)
				continue;
			
			GetClientAbsOrigin(idBoss, Pos);
			GetClientAbsOrigin(i, tPos);
			if(GetVectorDistance(tPos, Pos) < GetConVarFloat(sm_lastboss_quake_radius))
			{
				EmitSoundToClient(i, SOUND_QUAKE);
				ScreenShake(i, 60.0);
				Smash(idBoss, i, GetConVarFloat(sm_lastboss_quake_force), 1.0, 1.5);
			}
		}
	}
}

public SkillDreadClaw(target)
{
	visibility = GetConVarInt(sm_lastboss_dreadrate);
	CreateTimer(GetConVarFloat(sm_lastboss_dreadinterval), DreadTimer, target);
	EmitSoundToAll(SOUND_DCLAW, target);
	ScreenFade(target, 0, 0, 0, visibility, 0, 0);
}

public SkillGravityClaw(target)
{
	SetEntityGravity(target, 0.3);
	CreateTimer(GetConVarFloat(sm_lastboss_gravityinterval), GravityTimer, target);
	EmitSoundToAll(SOUND_GCLAW, target);
	ScreenFade(target, 0, 0, 100, 80, 4000, 1);
	ScreenShake(target, 30.0);
}

public SkillFreezeClaw(target)
{
	FreezePlayer(target, GetConVarFloat(sm_lastboss_freezetime));
	CreateTimer(GetConVarFloat(sm_lastboss_freezeinterval), FreezeTimer, target);
}

public SkillLazyClaw(target)
{
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(i == idBoss)
			continue;
		if(!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
		if(GetEntProp(i, Prop_Send, "m_zombieClass") != 8)
		{
			LazyPlayer(target);
		}
	}
}

public SkillRabiesClaw(target)
{
	Rabies[target] = (GetConVarInt(sm_lastboss_rabiestime));
	CreateTimer(1.0, RabiesTimer, target);
	Toxin[target] = (GetConVarInt(sm_lastboss_rabiestime));
	CreateTimer(1.0, Toxin_Timer, target);
	EmitSoundToAll(SOUND_ROAR, target);
}

public SkillBombClaw(target)
{
	decl Float:Pos[3];

	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
		GetClientAbsOrigin(i, Pos);
		if(GetVectorDistance(Pos, trsPos[target]) < GetConVarFloat(sm_lastboss_bombradius))
		{
			DamageEffect(i, GetConVarFloat(sm_lastboss_bombdamage));
		}
	}
	EmitSoundToAll(SOUND_BOMBARD, target);
	ScreenShake(target, 100.0);

	/* Explode */
	LittleFlower(Pos, EXPLODE);

	/* Push away */
	PushAway(target, GetConVarFloat(sm_lastboss_bombardforce), GetConVarFloat(sm_lastboss_bombradius), 0.5);
}

public SkillBurnClaw(target)
{
	EmitSoundToAll(SOUND_BCLAW, target);
	ScreenFade(target, 200, 0, 0, 150, 80, 1);
	ScreenShake(target, 50.0);
}

public SkillCometStrike(target, type)
{
	decl Float:pos[3];
	GetClientAbsOrigin(target, pos);

	if(type == MOLOTOV)
	{
		LittleFlower(pos, EXPLODE);
		LittleFlower(pos, MOLOTOV);
	}
	else if(type == EXPLODE)
	{
		LittleFlower(pos, EXPLODE);
	}
}

public SkillFlameGush(target)
{
	decl Float:pos[3];

	SkillBurnClaw(target);
	LavaDamage(target);
	GetClientAbsOrigin(idBoss, pos);
	LittleFlower(pos, MOLOTOV);
}

public SkillCallOfAbyss()
{
	/* Stop moving and prevent all damage for a while */
	SetEntityMoveType(idBoss, MOVETYPE_NONE);
	SetEntProp(idBoss, Prop_Data, "m_takedamage", 0, 1);
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(!IsValidEntity(i) || !IsClientInGame(i) || GetClientTeam(i) != SURVIVOR)
			continue;
		EmitSoundToClient(i, SOUND_HOWL);
		ScreenShake(i, 20.0);
	}
	/* Panic event */
	if((form_prev == FORMEIGHT && GetConVarInt(sm_lastboss_enable_abyss) == 1) || GetConVarInt(sm_lastboss_enable_abyss) == 2)
	{
		TriggerPanicEvent();
	}
	
	/* After 5sec, change form and start moving */
	CreateTimer(5.0, HowlTimer);
}

/******************************************************
*	Check Tank condition and update status
*******************************************************/
public Action:TankUpdate(Handle:timer)
{
	if(!IsValidEntity(idBoss) || !IsClientInGame(idBoss) || idBoss == DEAD)
		return;
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
		return;
	new health = GetClientHealth(idBoss);
	
	/* First form */
	if(health > GetConVarInt(sm_lastboss_health_second))
	{
		if(form_prev != FORMONE)
			SetPrameter(FORMONE);
	}
	/* Second form */
	else if(GetConVarInt(sm_lastboss_health_second) >= health && health > GetConVarInt(sm_lastboss_health_third))
	{
		if(form_prev != FORMTWO)
			SetPrameter(FORMTWO);
	}
	/* Third form */
	else if(GetConVarInt(sm_lastboss_health_third) >= health && health > GetConVarInt(sm_lastboss_health_fourth))
	{
		if(form_prev != FORMTHREE)
			SetPrameter(FORMTHREE);
	}
	/* Fourth form */
	else if(GetConVarInt(sm_lastboss_health_fourth) >= health && health > GetConVarInt(sm_lastboss_health_fifth))
	{
		/* Can't burn */
		ExtinguishEntity(idBoss);
		if(form_prev != FORMFOUR)
			SetPrameter(FORMFOUR);
	}
	/* Fifth form */
	else if(GetConVarInt(sm_lastboss_health_fifth) >= health && health > GetConVarInt(sm_lastboss_health_sixth))
	{
		if(form_prev != FORMFIVE)
			SetPrameter(FORMFIVE);
	}
	/* Sixth form */
	else if(GetConVarInt(sm_lastboss_health_sixth) >= health && health > GetConVarInt(sm_lastboss_health_seventh))
	{
		if(form_prev != FORMSIX)
			SetPrameter(FORMSIX);
	}
	/* Seventh form */
	else if(GetConVarInt(sm_lastboss_health_seventh) >= health && health > GetConVarInt(sm_lastboss_health_eighth))
	{
		if(form_prev != FORMSEVEN)
			SetPrameter(FORMSEVEN);
	}	
	/* Eighth form */
	else if(GetConVarInt(sm_lastboss_health_eighth) >= health && health > 0)
	{
		if(form_prev != FORMEIGHT)
			SetPrameter(FORMEIGHT);
	}
}

public SetPrameter(form_next)
{
	new force;
	new Float:speed;
	decl String:color[32];
	
	form_prev = form_next;
	
	if(form_next != FORMONE)
	{
		if(GetConVarInt(sm_lastboss_enable_abyss))
		{
			/* Skill:Call of Abyss (Howl and Trigger panic event) */
			SkillCallOfAbyss();
		}
		
		/* Skill:Reflesh (Extinguish if fired) */
		ExtinguishEntity(idBoss);
		
		/* Show effect when form has changed */
		AttachParticle(idBoss, PARTICLE_SPAWN);
		for(new j = 1; j <= GetMaxClients(); j++)
		{
			if(!IsClientInGame(j) || GetClientTeam(j) != 2)
				continue;
			EmitSoundToClient(j, SOUND_CHANGE);
			ScreenFade(j, 200, 200, 255, 255, 100, 1);
		}
	}
	
	/* Setup status of each form */
	if(form_next == FORMONE)
	{
		force = GetConVarInt(sm_lastboss_force_first);
		speed = GetConVarFloat(sm_lastboss_speed_first);
		GetConVarString(sm_lastboss_color_first, color, sizeof(color));
		
		/* Skill:Fatal Mirror (Teleport near the survivor) */
		if(GetConVarInt(sm_lastboss_enable_warp))
		{
			CreateTimer(3.0, GetSurvivorPosition, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lastboss_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}
	else if(form_next == FORMTWO)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll(MESSAGE_SECOND);
		force = GetConVarInt(sm_lastboss_force_second);
		speed = GetConVarFloat(sm_lastboss_speed_second);
		GetConVarString(sm_lastboss_color_second, color, sizeof(color));
		
		/* Weight increases */
		SetEntityGravity(idBoss, GetConVarFloat(sm_lastboss_weight_second));
	}
	else if(form_next == FORMTHREE)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll(MESSAGE_THIRD);
		force = GetConVarInt(sm_lastboss_force_third);
		speed = GetConVarFloat(sm_lastboss_speed_third);
		GetConVarString(sm_lastboss_color_third, color, sizeof(color));
	}
	else if(form_next == FORMFOUR)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll(MESSAGE_FOURTH);
		force = GetConVarInt(sm_lastboss_force_fourth);
		speed = GetConVarFloat(sm_lastboss_speed_fourth);
		GetConVarString(sm_lastboss_color_fourth, color, sizeof(color));
		SetEntityGravity(idBoss, 1.0);
		
		/* Attach particle */
		CreateTimer(0.8, ParticleTimer, _, TIMER_REPEAT);
		
		/* Skill:Stealth Skin */
		if(GetConVarInt(sm_lastboss_enable_stealth))
			CreateTimer(GetConVarFloat(sm_lastboss_stealth_fourth), StealthTimer);
	}
	else if(form_next == FORMFIVE)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll(MESSAGE_FIFTH);
		force = GetConVarInt(sm_lastboss_force_fifth);
		speed = GetConVarFloat(sm_lastboss_speed_fifth);
		GetConVarString(sm_lastboss_color_fifth, color, sizeof(color));
	}
	else if(form_next == FORMSIX)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll(MESSAGE_SIXTH);
		force = GetConVarInt(sm_lastboss_force_sixth);
		speed = GetConVarFloat(sm_lastboss_speed_sixth);
		GetConVarString(sm_lastboss_color_sixth, color, sizeof(color));
	}
	else if(form_next == FORMSEVEN)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll(MESSAGE_SEVENTH);
		force = GetConVarInt(sm_lastboss_force_seventh);
		speed = GetConVarFloat(sm_lastboss_speed_seventh);
		GetConVarString(sm_lastboss_color_seventh, color, sizeof(color));
	}
	else if(form_next == FORMEIGHT)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll(MESSAGE_EIGHTH);
		SetEntityRenderMode(idBoss, RENDER_TRANSCOLOR);
		SetEntityRenderColor(idBoss, _, _, _, 255);
		
		force = GetConVarInt(sm_lastboss_force_eighth);
		speed = GetConVarFloat(sm_lastboss_speed_eighth);
		GetConVarString(sm_lastboss_color_eighth, color, sizeof(color));
		SetEntityGravity(idBoss, 1.0);
		
		/* Ignite */
		IgniteEntity(idBoss, 9999.9);
		
		/* Skill:Mad Spring */
		if(GetConVarInt(sm_lastboss_enable_jump))
			CreateTimer(GetConVarFloat(sm_lastboss_jumpinterval_eighth), JumpingTimer, _, TIMER_REPEAT);
			
		new Float:Origin[3], Float:Angles[3];
		GetEntPropVector(idBoss, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(idBoss, Prop_Send, "m_angRotation", Angles);
		Angles[0] += 90.0;
		new ent[3];
		for (new count=1; count<=2; count++)
		{
			ent[count] = CreateEntityByName("prop_dynamic_override");
			if (IsValidEntity(ent[count]))
			{
				decl String:tName[64];
				Format(tName, sizeof(tName), "Tank%d", idBoss);
				DispatchKeyValue(idBoss, "targetname", tName);
				GetEntPropString(idBoss, Prop_Data, "m_iName", tName, sizeof(tName));

				DispatchKeyValue(ent[count], "model", ENTITY_TIRE);
				DispatchKeyValue(ent[count], "targetname", "TireEntity");
				DispatchKeyValue(ent[count], "parentname", tName);
				GetConVarString(sm_lastboss_color_eighth, color, sizeof(color));
				DispatchKeyValue(ent[count], "rendercolor", color);
				DispatchKeyValueVector(ent[count], "origin", Origin);
				DispatchKeyValueVector(ent[count], "angles", Angles);
				DispatchSpawn(ent[count]);
				SetVariantString(tName);
				AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count]);
				switch(count)
				{
					case 1:SetVariantString("rfoot");
					case 2:SetVariantString("lfoot");
				}
				AcceptEntityInput(ent[count], "SetParentAttachment");
				AcceptEntityInput(ent[count], "Enable");
				AcceptEntityInput(ent[count], "DisableCollision");
				SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", idBoss);
				TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	
	/* Set force */
	SetConVarInt(FindConVar("z_tank_throw_force"), force, true, true);
	
	/* Set speed */
	SetEntPropFloat(idBoss, Prop_Send, "m_flLaggedMovementValue", speed);
	
	/* Set color */
	SetEntityRenderMode(idBoss, RenderMode:0);
	DispatchKeyValue(idBoss, "rendercolor", color);
}

/******************************************************
*	Timer functions
*******************************************************/
public Action:ParticleTimer(Handle:timer)
{
	if(form_prev == FORMFOUR)
		AttachParticle(idBoss, PARTICLE_FOURTH);
	else if(form_prev == FORMEIGHT)
		AttachParticle(idBoss, PARTICLE_EIGHTH);
	else
		KillTimer(timer);
}

public Action:GravityTimer(Handle:timer, any:target)
{
	SetEntityGravity(target, 1.0);
}

public Action:JumpingTimer(Handle:timer)
{
	if(form_prev == FORMEIGHT && IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
		AddVelocity(idBoss, GetConVarFloat(sm_lastboss_jumpheight_eighth));
	else
		KillTimer(timer);
}

public Action:StealthTimer(Handle:timer)
{
	if(form_prev == FORMFOUR && idBoss)
	{
		alpharate = 255;
		Remove(idBoss);
	}
}

public Action:DreadTimer(Handle:timer, any:target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		visibility -= 8;
		if(visibility < 0)  visibility = 0;
		ScreenFade(target, 0, 0, 0, visibility, 0, 1);
		if(visibility <= 0)
		{
			visibility = 0;
			KillTimer(timer);
		}
	}
}

public Action:FreezeTimer(Handle:timer, any:target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		EmitSoundToAll(SOUND_DEFROST, target);
		SetEntityMoveType(target, MOVETYPE_WALK);
		SetEntityRenderColor(target, 255, 255, 255, 255);
		ScreenFade(target, 0, 0, 0, 0, 0, 1);
		freeze[target] = OFF;
	}
}

public Action:RabiesTimer(Handle:timer, any:target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		if(Rabies[target] <= 0)
		{
			KillTimer(timer);
			return;
		}

		RabiesDamage(target);

		if(Rabies[target] > 0)
		{
			CreateTimer(1.0, RabiesTimer, target);
			Rabies[target] -= 1;
		}
	}
	EmitSoundToAll(SOUND_RABIES, target);
}

KillToxin(target)
{
	new Float:pos[3];
	GetClientAbsOrigin(target, pos);
	new Float:angs[3];
	GetClientEyeAngles(target, angs);

	angs[2] = 0.0;

	TeleportEntity(target, pos, angs, NULL_VECTOR);

	new clients[2];
	clients[0] = target;

	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();
}

public Action:Toxin_Timer(Handle:timer, any:target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		if(Toxin[target] <= 0)
		{
			KillTimer(timer);
			return Plugin_Handled;
		}
		
		KillToxin(target);
		
		if(Toxin[target] > 0)
		{
			CreateTimer(1.0, Toxin_Timer, target);
			Toxin[target] -= 1;
		}
		
		new Float:pos[3];
		GetClientAbsOrigin(target, pos);
		
		new Float:angs[3];
		GetClientEyeAngles(target, angs);
		
		angs[2] = ToxinAngle[GetRandomInt(0,100) % 20];
		
		TeleportEntity(target, pos, angs, NULL_VECTOR);
		
		new clients[2];
		clients[0] = target;
		
		new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
		BfWriteShort(message, 255);
		BfWriteShort(message, 255);
		BfWriteShort(message, (0x0002));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, 128);
		
		EndMessage();
	}
	
	return Plugin_Handled;
}

public Action:HowlTimer(Handle:timer)
{
	if(idBoss)
	{
		SetEntityMoveType(idBoss, MOVETYPE_WALK);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 2, 1);
	}
}

public Action:WarpTimer(Handle:timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		decl Float:pos[3];
		
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != SURVIVOR)
				continue;
			EmitSoundToClient(i, SOUND_WARP);
		}
		GetClientAbsOrigin(idBoss, pos);
		ShowParticle(pos, PARTICLE_WARP, 2.0);
		TeleportEntity(idBoss, ftlPos, NULL_VECTOR, NULL_VECTOR);
		ShowParticle(ftlPos, PARTICLE_WARP, 2.0);
		SetEntityMoveType(idBoss, MOVETYPE_WALK);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 2, 1);
	}
	else
	{
		KillTimer(timer);
	}
}

public Action:GetSurvivorPosition(Handle:timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		new count = 0;
		new idAlive[MAXPLAYERS+1];
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != SURVIVOR)
				continue;
			idAlive[count] = i;
			count++;
		}
		if(count == 0) return;
		new clientNum = GetRandomInt(0, count-1);
		GetClientAbsOrigin(idAlive[clientNum], ftlPos);
	}
	else
	{
		KillTimer(timer);
	}
}

public Action:FatalMirror(Handle:timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		/* Stop moving and prevent all damage for a while */
		SetEntityMoveType(idBoss, MOVETYPE_NONE);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 0, 1);
		
		/* Teleport to position that survivor exsited 2sec ago */
		CreateTimer(1.5, WarpTimer);
	}
	else
	{
		KillTimer(timer);
	}
}

/******************************************************
*	Gimmick functions
*******************************************************/
public Action:Remove(ent)
{
	if(IsValidEntity(ent))
	{
		CreateTimer(0.1, fadeout, ent, TIMER_REPEAT);
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	}
}

public Action:fadeout(Handle:Timer, any:ent)
{
	if(!IsValidEntity(ent) || form_prev != FORMFOUR)
	{
		KillTimer(Timer);
		return;
	}
	alpharate -= 2;
	if (alpharate < 0)  alpharate = 0;
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 80, 80, 255, alpharate);
	if(alpharate <= 0)
	{
		KillTimer(Timer);
	}
}

public AddVelocity(client, Float:zSpeed)
{
	if(g_iVelocity == -1) return;
	
	new Float:vecVelocity[3];
	GetEntDataVector(client, g_iVelocity, vecVelocity);
	vecVelocity[2] += zSpeed;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

public LittleFlower(Float:pos[3], type)
{
	/* Cause fire(type=0) or explosion(type=1) */
	new entity = CreateEntityByName("prop_physics");
	if (IsValidEntity(entity))
	{
		pos[2] += 10.0;
		if (type == 0)
			/* fire */
			DispatchKeyValue(entity, "model", ENTITY_GASCAN);
		else
			/* explode */
			DispatchKeyValue(entity, "model", ENTITY_PROPANE);
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}
}

public Smash(client, target, Float:power, Float:powHor, Float:powVec)
{
	/* Blow off target */
	decl Float:HeadingVector[3], Float:AimVector[3];
	GetClientEyeAngles(client, HeadingVector);
	
	AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])) ,power * powHor);
	AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])) ,power * powHor);
	
	decl Float:current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	decl Float:resulting[3];
	resulting[0] = FloatAdd(current[0], AimVector[0]);	
	resulting[1] = FloatAdd(current[1], AimVector[1]);
	resulting[2] = power * powVec;
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

public ScreenFade(target, red, green, blue, alpha, duration, type)
{
	new Handle:msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
		BfWriteShort(msg, (0x0002 | 0x0008));
	else
		BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

public ScreenShake(target, Float:intensity)
{
	new Handle:msg;
	msg = StartMessageOne("Shake", target);
	
	BfWriteByte(msg, 0);
 	BfWriteFloat(msg, intensity);
 	BfWriteFloat(msg, 10.0);
 	BfWriteFloat(msg, 3.0);
	EndMessage();
}

public TriggerPanicEvent()
{
	new flager = GetAnyClient();
	if(flager == -1)  return;
	new flag = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flag & ~FCVAR_CHEAT);
	FakeClientCommand(flager, "director_force_panic_event");
}

public FreezePlayer(target, Float:time)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		SetEntityMoveType(target, MOVETYPE_NONE);
		SetEntityRenderColor(target, 0, 128, 255, 135);
		EmitSoundToAll(SOUND_FREEZE, target);
		freeze[target] = ON;
		CreateTimer(time, FreezeTimer, target);
	}
}

public LazyPlayer(target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2 && !isSlowed[target])
	{
		isSlowed[target] = true;
		CreateTimer(GetConVarFloat(sm_lastboss_lazytime), Quick, target);
		SetEntDataFloat(target, laggedMovementOffset, GetConVarFloat(sm_lastboss_lazyspeed), true);
		SetEntityRenderColor(target, 255, 255, 255, 135);
		EmitSoundToAll(SOUND_LAZY, target);
	}
}

public Action:Quick(Handle:timer, any:target)
{
	if (IsValidClient(target) && GetClientTeam(target))
	{
		SetEntDataFloat(target, laggedMovementOffset, 1.0, true);
		isSlowed[target] = false;
		SetEntityRenderColor(target, 255, 255, 255, 255);
		EmitSoundToAll(SOUND_QUICK, target);
	}
}

stock RabiesDamage(target)
{
	new String:dmg_str[16];
	new String:dmg_type_str[16];
	IntToString((1 << 17),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("sm_lastboss_rabiesdamage"), dmg_str, sizeof(dmg_str));
	new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(target,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchKeyValue(pointHurt,"classname","point_hurt");
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt",-1,(target>0)?target:-1);
	DispatchKeyValue(target,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}

stock LavaDamage(target)
{
	new String:dmg_lava[16];
	new String:dmg_type_lava[16];
	IntToString((1 << 17),dmg_lava,sizeof(dmg_type_lava));
	GetConVarString(FindConVar("sm_lastboss_lavadamage"), dmg_lava, sizeof(dmg_lava));
	new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(target,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_lava);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_lava);
	DispatchKeyValue(pointHurt,"classname","point_hurt");
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt",-1,(target>0)?target:-1);
	DispatchKeyValue(target,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}

stock DamageEffect(target, Float:damage)
{
	decl String:tName[20];
	Format(tName, 20, "target%d", target);
	new pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(target, "targetname", tName);
	DispatchKeyValueFloat(pointHurt, "Damage", damage);
	DispatchKeyValue(pointHurt, "DamageTarget", tName);
	DispatchKeyValue(pointHurt, "DamageType", "65536");
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt");
	AcceptEntityInput(pointHurt, "Kill");
}

stock ForceWeaponDrop(client)
{
	new weapon = GetPlayerWeaponSlot(client, 1);
	SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
}

public PushAway(target, Float:force, Float:radius, Float:duration)
{
	new push = CreateEntityByName("point_push");
	DispatchKeyValueFloat (push, "magnitude", force);
	DispatchKeyValueFloat (push, "radius", radius);
	SetVariantString("spawnflags 24");
	AcceptEntityInput(push, "AddOutput");
	DispatchSpawn(push);
	TeleportEntity(push, trsPos[target], NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(push, "Enable", -1, -1);
	CreateTimer(duration, DeletePushForce, push);
}

/******************************************************
*	Particle control functions
*******************************************************/
public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	/* Show particle effect you like */
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

public AttachParticle(ent, String:particleType[])
{
	decl String:tName[64];
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	/* Delete particle */
	if (IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
			RemoveEdict(particle);
	}
}

public PrecacheParticle(String:particlename[])
{
	/* Precache particle */
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

public Action:DeletePushForce(Handle:timer, any:ent)
{
	if (ent> 0 && IsValidEntity(ent) && IsValidEdict(ent))
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

/******************************************************
*	Other functions
*******************************************************/
bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		return true;
	else
		return false;
}

GetAnyClient()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidEntity(i) && IsClientInGame(i))
			return i;
	}
	return -1;
}

public IsValidClient(client)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(client))
	{
		return false;
	}
	
	return true;
}

/******************************************************
*	EOF
*******************************************************/