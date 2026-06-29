/******************************************************
* 				L4D2: Last Boss v3.0
*					Author: ztar
* 			Web: http://ztar.blog7.fc2.com/
*******************************************************/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

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
#define MESSAGE_SPAWN	"\x03[EL ULTIMO JEFE] \x04\x01¡¡¡PELIGRO!!! MUTACION ESPECIAL DEL TANK \x05 ¡¡¡PREPARATE!!! \x01【\x03 JEFE FINAL DE 8 FASES \x01】"
#define MESSAGE_SPAWN2	"\x03[EL ULTIMO JEFE] \x04PRIMERA \x01FASE \x05INFECTADO ESPECIAL \x01| \x04VELOCIDA: \x05 VARIADA"
#define MESSAGE_SECOND	"\x03[EL ULTIMO JEFE] \x04SEGUNDA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03GIGANTE DE ACERO\x01】"
#define MESSAGE_THIRD	"\x03[EL ULTIMO JEFE] \x04TERCERA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03SUPER PODER\x01】"
#define MESSAGE_FOURTH	"\x03[EL ULTIMO JEFE] \x04CUARTA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03VISION OSCURA\x01】"
#define MESSAGE_FIFTH	"\x03[EL ULTIMO JEFE] \x04QUINTA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03INMOVILIDAD\x01】"
#define MESSAGE_SIXTH	"\x03[EL ULTIMO JEFE] \x04SEXTA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03GOLPE EXPLOSIVO\x01】"
#define MESSAGE_SEVENTH	"\x03[EL ULTIMO JEFE] \x04SEPTIMA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03GOLPE CONGELANTE\x01】"
#define MESSAGE_EIGHTH	"\x03[EL ULTIMO JEFE] \x04ULTIMA \x01FASE  \x03TRANSFORMACION \x05TANK \x04==> \x01【\x03ESCUDO DE FUEGO\x01】"

/* Parameter */
Handle sm_lastboss_enable				= INVALID_HANDLE;
Handle sm_lastboss_enable_announce		= INVALID_HANDLE;
Handle sm_lastboss_enable_steel			= INVALID_HANDLE;
Handle sm_lastboss_enable_bomb			= INVALID_HANDLE;
Handle sm_lastboss_enable_stealth		= INVALID_HANDLE;
Handle sm_lastboss_enable_gravity		= INVALID_HANDLE;
Handle sm_lastboss_enable_burn			= INVALID_HANDLE;
Handle sm_lastboss_enable_jump			= INVALID_HANDLE;
Handle sm_lastboss_enable_quake			= INVALID_HANDLE;
Handle sm_lastboss_enable_comet			= INVALID_HANDLE;
Handle sm_lastboss_enable_dread			= INVALID_HANDLE;
Handle sm_lastboss_enable_lazy			= INVALID_HANDLE;
Handle sm_lastboss_enable_rabies		= INVALID_HANDLE;
Handle sm_lastboss_enable_freeze		= INVALID_HANDLE;
Handle sm_lastboss_enable_gush			= INVALID_HANDLE;
Handle sm_lastboss_enable_abyss			= INVALID_HANDLE;
Handle sm_lastboss_enable_warp			= INVALID_HANDLE;

Handle sm_lastboss_health_max	 		= INVALID_HANDLE;
Handle sm_lastboss_health_second 		= INVALID_HANDLE;
Handle sm_lastboss_health_third	 		= INVALID_HANDLE;
Handle sm_lastboss_health_fourth	 	= INVALID_HANDLE;
Handle sm_lastboss_health_fifth	 		= INVALID_HANDLE;
Handle sm_lastboss_health_sixth	 		= INVALID_HANDLE;
Handle sm_lastboss_health_seventh	 	= INVALID_HANDLE;
Handle sm_lastboss_health_eighth	 	= INVALID_HANDLE;

Handle sm_lastboss_color_first 	 		= INVALID_HANDLE;
Handle sm_lastboss_color_second	 		= INVALID_HANDLE;
Handle sm_lastboss_color_third 	 		= INVALID_HANDLE;
Handle sm_lastboss_color_fourth			= INVALID_HANDLE;
Handle sm_lastboss_color_fifth			= INVALID_HANDLE;
Handle sm_lastboss_color_sixth			= INVALID_HANDLE;
Handle sm_lastboss_color_seventh		= INVALID_HANDLE;
Handle sm_lastboss_color_eighth			= INVALID_HANDLE;

Handle sm_lastboss_force_first 	 		= INVALID_HANDLE;
Handle sm_lastboss_force_second			= INVALID_HANDLE;
Handle sm_lastboss_force_third 			= INVALID_HANDLE;
Handle sm_lastboss_force_fourth			= INVALID_HANDLE;
Handle sm_lastboss_force_fifth			= INVALID_HANDLE;
Handle sm_lastboss_force_sixth			= INVALID_HANDLE;
Handle sm_lastboss_force_seventh		= INVALID_HANDLE;
Handle sm_lastboss_force_eighth			= INVALID_HANDLE;

Handle sm_lastboss_speed_first 	 		= INVALID_HANDLE;
Handle sm_lastboss_speed_second	 		= INVALID_HANDLE;
Handle sm_lastboss_speed_third 	 		= INVALID_HANDLE;
Handle sm_lastboss_speed_fourth	 		= INVALID_HANDLE;
Handle sm_lastboss_speed_fifth	 		= INVALID_HANDLE;
Handle sm_lastboss_speed_sixth	 		= INVALID_HANDLE;
Handle sm_lastboss_speed_seventh	 	= INVALID_HANDLE;
Handle sm_lastboss_speed_eighth	 		= INVALID_HANDLE;

Handle sm_lastboss_weight_second		= INVALID_HANDLE;
Handle sm_lastboss_stealth_fourth 		= INVALID_HANDLE;
Handle sm_lastboss_jumpinterval_eighth	= INVALID_HANDLE;
Handle sm_lastboss_jumpheight_eighth	= INVALID_HANDLE;
Handle sm_lastboss_gravityinterval 		= INVALID_HANDLE;
Handle sm_lastboss_quake_radius 		= INVALID_HANDLE;
Handle sm_lastboss_quake_force	 		= INVALID_HANDLE;
Handle sm_lastboss_dreadinterval 		= INVALID_HANDLE;
Handle sm_lastboss_dreadrate	 		= INVALID_HANDLE;
Handle sm_lastboss_freezetime 	 	 	= INVALID_HANDLE;
Handle sm_lastboss_freezeinterval 	 	= INVALID_HANDLE;
Handle sm_lastboss_lazytime	 	 	 	= INVALID_HANDLE;
Handle sm_lastboss_lazyspeed 	 	 	= INVALID_HANDLE;
Handle sm_lastboss_rabiestime 	 	    = INVALID_HANDLE;
Handle sm_lastboss_bombradius	 	 	= INVALID_HANDLE;
Handle sm_lastboss_bombdamage 	 	 	= INVALID_HANDLE;
Handle sm_lastboss_bombardforce  	 	= INVALID_HANDLE;
Handle sm_lastboss_eighth_c5m5_bridge	= INVALID_HANDLE;
Handle sm_lastboss_warp_interval		= INVALID_HANDLE;

/* Timer Handle */
Handle TimerUpdate = INVALID_HANDLE;

// UserMessageId for Fade.
UserMsg g_FadeUserMsgId;

float ToxinAngle[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

/* Grobal */
int alpharate;
int visibility;
int bossflag = OFF;
int lastflag = OFF;
int idBoss = DEAD;
int form_prev = DEAD;
int force_default;
int g_iVelocity	= -1;
int wavecount;
float ftlPos[3];
int freeze[MAXPLAYERS+1];
bool isSlowed[MAXPLAYERS+1] = false;
static int laggedMovementOffset = 0;
int Rabies[MAXPLAYERS+1];
int Toxin[MAXPLAYERS+1];
float trsPos[MAXPLAYERS+1][3];

static bool bL4D2;

public Plugin myinfo = 
{
	name 		= "[L4D2] LAST BOSS",
	author 		= "Ztar & IxAvnoMonvAxI, Edited By Ernecio (Satanael)",
	description = "Special Tank spawns during finale.",
	version 	= PLUGIN_VERSION,
	url 		= "http://ztar.blog7.fc2.com/"
}

/**
 * Called on pre plugin start.
 *
 * @param myself        Handle to the plugin.
 * @param late          Whether or not the plugin was loaded "late" (after map load).
 * @param error         Error message buffer in case load failed.
 * @param err_max       Maximum number of characters for error message buffer.
 * @return              APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "This Plugin \"Last Boss\" only runs in the \"Left 4 Dead 1/2\" Games!.");
		return APLRes_SilentFailure;
	}
	
	bL4D2 = (engine == Engine_Left4Dead2);
	return APLRes_Success;
}

/******************************************************
*	When plugin started
*******************************************************/
public void OnPluginStart()
{	
	/* Enable/Disable */
	sm_lastboss_enable		    = CreateConVar("sm_lastboss_enable", 			"2", 	"Activar/Desactivar 0 = Plugin Inactivo. 1 = Activo solo en finales. 2 = Siempre activo. 3 = Crea Lass Boss solo en finales y en la segunda ronda", FCVAR_NOTIFY);
	sm_lastboss_enable_announce	= CreateConVar("sm_lastboss_enable_announce", 	"1", 	"Activar/Desactivar Anuncios en el chat. 0 = Anuncios Inactivos. 1 = Anuncios Activos.", FCVAR_NOTIFY);
	sm_lastboss_enable_steel	= CreateConVar("sm_lastboss_enable_steel", 		"1",	"Activar/Desactivar Habilidad De Blindaje. 0 = Blindaje Inactivo. 1 = Blindaje Activo.", FCVAR_NOTIFY);
	sm_lastboss_enable_bomb	    = CreateConVar("sm_lastboss_enable_bomb", 		"1", 	"Activar/Desactivar Habilidad De Puño Explosivo. 0 = Puño Explosivo Inactivo. 1 = Puño Explosivo Activo.", FCVAR_NOTIFY);
	sm_lastboss_enable_stealth	= CreateConVar("sm_lastboss_enable_stealth", 	"1", 	"Activar/Desactivar Habilidad De Transparencia Lenta Y Inmunidad Al Fuego. 0 = Inactivo. 1 = Activo", FCVAR_NOTIFY);
	sm_lastboss_enable_gravity	= CreateConVar("sm_lastboss_enable_gravity", 	"1", 	"Activar/Desactivar Habilidad De Gravedad En El Objetivo(Enemigo). 0 Gravedad Inactiva. 1 = Gravedad Activa.", FCVAR_NOTIFY);
	sm_lastboss_enable_burn		= CreateConVar("sm_lastboss_enable_burn", 		"1", 	"Activar/Desactivar Habilidad De Fuego. 0 = Habilidad De Fuego Inactiva. 1 = Habilidad De Fuego Activa.", FCVAR_NOTIFY);
	sm_lastboss_enable_quake	= CreateConVar("sm_lastboss_enable_quake", 		"1",	"Activar/Desactivar Habilidad De Temblor. 0 = Temblor Inactivo. 1 = Temblor Activo ", FCVAR_NOTIFY);
	sm_lastboss_enable_jump		= CreateConVar("sm_lastboss_enable_jump", 		"1", 	"Activar/Desactivar Habilidad De Saltos. 0 = Saltos Inactivos. 1 = Saltos Activos.", FCVAR_NOTIFY);
	sm_lastboss_enable_comet	= CreateConVar("sm_lastboss_enable_comet", 		"1", 	"Activar/Desactivar Habilidad De Rocas Explosivas. 0 = Rocas Explosivas Inactivas. 1 = Rocas Explosivas Activas.", FCVAR_NOTIFY);
	sm_lastboss_enable_dread	= CreateConVar("sm_lastboss_enable_dread", 		"1", 	"Activar/Desactivar Habilidad De Enseguesimiento Al Objetivo(Enemigo). 0 = Enseguesimiento Inactivo. 1 = Enseguesimiento Activo.", FCVAR_NOTIFY);
	sm_lastboss_enable_lazy	    = CreateConVar("sm_lastboss_enable_lazy", 		"1", 	"Activar/Desactivar Habilidad De Ralentización Al Objetivo(Enemigo). 0 = Ralentización Inactiva. 1 = Ralentización Activa.", FCVAR_NOTIFY);
	sm_lastboss_enable_rabies	= CreateConVar("sm_lastboss_enable_rabies", 	"1", 	"Activar/Desactivar Habilidad De Infectar Al Objetivo Y Disminuir Su Vida. 0 = Infección Inactiva. 1 = Infección Activa.", FCVAR_NOTIFY);
	sm_lastboss_enable_freeze	= CreateConVar("sm_lastboss_enable_freeze", 	"1", 	"Activar/Desactivar Habilidad De Congelar Al Objetivo(Enemigo). 0 = Congelación Inactiva. 1 = Congelación Activa.", FCVAR_NOTIFY);	
	sm_lastboss_enable_gush		= CreateConVar("sm_lastboss_enable_gush", 		"1", 	"Activar Desactivar Habilidad De Lethal Weapon. 0 = Inactivo. 1 = Atcivo", FCVAR_NOTIFY);
	sm_lastboss_enable_abyss	= CreateConVar("sm_lastboss_enable_abyss", 		"1", 	"Activar/Desactivar Habilidad De Crear Eventos De Pánico. 0 = Evento De Pánico Inactivo. 1 = Evento De Pánico Activo En La Octava Transfomación. 2 = Activo En Todas Las Trasfomaciones.", FCVAR_NOTIFY);
	sm_lastboss_enable_warp		= CreateConVar("sm_lastboss_enable_warp", 		"1", 	"Activar/Desactivar Habilidad De Teletransportación. 0 = Teletransportación Inactiva. 1 = Teletransportación Activa.", FCVAR_NOTIFY);

	/* Health */
	sm_lastboss_health_max	  = CreateConVar("sm_lastboss_health_max", 			"62000", 	"HP Del Tank En Su Primera Forma.", FCVAR_NOTIFY);
	sm_lastboss_health_second = CreateConVar("sm_lastboss_health_second", 		"54000", 	"HP Del Tank En Su Segunda Forma.", FCVAR_NOTIFY);
	sm_lastboss_health_third  = CreateConVar("sm_lastboss_health_third", 		"46000", 	"HP Del Tank En Su Tercera Forma.", FCVAR_NOTIFY);
	sm_lastboss_health_fourth = CreateConVar("sm_lastboss_health_fourth", 		"38000", 	"HP Del Tank En Su Cuarta Forma.", FCVAR_NOTIFY);
	sm_lastboss_health_fifth  = CreateConVar("sm_lastboss_health_fifth", 		"32000", 	"HP Del Tank En Su Quinta Forma.", FCVAR_NOTIFY);
	sm_lastboss_health_sixth  = CreateConVar("sm_lastboss_health_sixth", 		"24000", 	"HP Del Tank En Su Sexta Forma.", FCVAR_NOTIFY);
	sm_lastboss_health_seventh = CreateConVar("sm_lastboss_health_seventh", 	"16000", 	"HP Del Tank En Su Septima Forma.", FCVAR_NOTIFY);
	sm_lastboss_health_eighth  = CreateConVar("sm_lastboss_health_eighth", 		"8000", 	"HP Del Tank En Su Octava Forma.", FCVAR_NOTIFY);

	/* Color */
	sm_lastboss_color_first	  = CreateConVar("sm_lastboss_color_first", 	"255 255 80", 	"Color Del Tank En Su Primera Forma (Amarillo Por Defecto).", FCVAR_NOTIFY);
	sm_lastboss_color_second  = CreateConVar("sm_lastboss_color_second", 	"80 255 80", 	"Color Del Tank En Su Tercera Forma (Verde Lima Por Defecto).", FCVAR_NOTIFY);
	sm_lastboss_color_third	  = CreateConVar("sm_lastboss_color_third", 	"153 153 255", 	"Color Del Tank En Su Tercera Forma (Azul Claro Por Defecto).", FCVAR_NOTIFY);
	sm_lastboss_color_fourth  = CreateConVar("sm_lastboss_color_fourth", 	"80 80 255", 	"Color Del Tank En Su Cuarta Forma (Purpura → Gradualmente Se Vuelve Transparente Por Defecto).", FCVAR_NOTIFY);
	sm_lastboss_color_fifth	  = CreateConVar("sm_lastboss_color_fifth", 	"200 150 200", 	"Color Del Tank En Su Quinta Forma (Rosa Oscuro Por Defecto).", FCVAR_NOTIFY);
	sm_lastboss_color_sixth	  = CreateConVar("sm_lastboss_color_sixth", 	"176 48 96", 	"Color Del Tank En Su Sexta Forma (Rojizo Por Defecto).", FCVAR_NOTIFY);	
	sm_lastboss_color_seventh = CreateConVar("sm_lastboss_color_seventh", 	"0 128 255", 	"Color Del Tank En Su Septima Forma (Azul Por Defecto).", FCVAR_NOTIFY);
	sm_lastboss_color_eighth  = CreateConVar("sm_lastboss_color_eighth", 	"255 80 80", 	"Color Del Tank En Su Octava Forma (Rojo Por Defeto).", FCVAR_NOTIFY);

	/* Force */
	sm_lastboss_force_first	  = CreateConVar("sm_lastboss_force_first", 	"1000", 	"Fuerza Del Tank En Su Primera Forma.", FCVAR_NOTIFY);
	sm_lastboss_force_second  = CreateConVar("sm_lastboss_force_second", 	"1500", 	"Fuerza Del Tank En Su Segunda Forma.", FCVAR_NOTIFY);
	sm_lastboss_force_third	  = CreateConVar("sm_lastboss_force_third", 	"1100", 	"Fuerza Del Tank En Su Tercera Forma.", FCVAR_NOTIFY);
	sm_lastboss_force_fourth  = CreateConVar("sm_lastboss_force_fourth", 	"800", 		"Fuerza Del Tank En Su Cuarta Forma.", FCVAR_NOTIFY);
	sm_lastboss_force_fifth	  = CreateConVar("sm_lastboss_force_fifth", 	"2000", 	"Fuerza Del Tank En Su Quinta Form.", FCVAR_NOTIFY);
	sm_lastboss_force_sixth	  = CreateConVar("sm_lastboss_force_sixth", 	"1600", 	"Fuerza Del Tank En Su Sexta Forma.", FCVAR_NOTIFY);
	sm_lastboss_force_seventh = CreateConVar("sm_lastboss_force_seventh", 	"1300", 	"Fuerza Del Tank En Su Septima Forma.", FCVAR_NOTIFY);
	sm_lastboss_force_eighth  = CreateConVar("sm_lastboss_force_eighth", 	"1800", 	"Fuerza Del Tank En Su Octava Forma.", FCVAR_NOTIFY);
	
	/* Speed */
	sm_lastboss_speed_first	  = CreateConVar("sm_lastboss_speed_first", 	"0.9", 		"Velocidad Del Tank En Su Primera Forma.", FCVAR_NOTIFY);
	sm_lastboss_speed_second  = CreateConVar("sm_lastboss_speed_second", 	"0.9", 		"Velocidad Del Tank En Su Segunda Forma.", FCVAR_NOTIFY);
	sm_lastboss_speed_third	  = CreateConVar("sm_lastboss_speed_third", 	"0.9", 		"Velocidad Del Tank En Su Tercera Forma.", FCVAR_NOTIFY);
	sm_lastboss_speed_fourth  = CreateConVar("sm_lastboss_speed_fourth", 	"0.9", 		"Velocidad Del Tank En Su Cuarta Forma.", FCVAR_NOTIFY);
	sm_lastboss_speed_fifth	  = CreateConVar("sm_lastboss_speed_fifth", 	"0.9", 		"Velocidad Del Tank En Su Quinta Forma.", FCVAR_NOTIFY);
	sm_lastboss_speed_sixth	  = CreateConVar("sm_lastboss_speed_sixth", 	"0.9", 		"Velocidad Del Tank En Su Sexta Forma.", FCVAR_NOTIFY);
	sm_lastboss_speed_seventh = CreateConVar("sm_lastboss_speed_seventh", 	"0.9", 		"Velocidad Del Tank En Su Septima Forma.", FCVAR_NOTIFY);
	sm_lastboss_speed_eighth  = CreateConVar("sm_lastboss_speed_eighth", 	"1.1", 		"Velocidad Del Tank En Su Octava Forma.", FCVAR_NOTIFY);
	
	/* Skill */
	sm_lastboss_weight_second		= CreateConVar("sm_lastboss_weight_second", 		"8.0", 		"Duración De Gravedad Baja Al Objetivo(Enemigo).", FCVAR_NOTIFY);
	sm_lastboss_stealth_fourth		= CreateConVar("sm_lastboss_stealth_fourth", 		"10.0", 	"Intervalo De La Transparencia Del Tank.", FCVAR_NOTIFY);
	sm_lastboss_jumpinterval_eighth  = CreateConVar("sm_lastboss_jumpinterval_eighth", 	"1.0", 		"Intervalo De Saltos Del Tank.", FCVAR_NOTIFY);
	sm_lastboss_jumpheight_eighth  	= CreateConVar("sm_lastboss_jumpheight_eighth", 	"300.0", 	"Altura Maxima De Salto Del Tank.", FCVAR_NOTIFY);
	sm_lastboss_gravityinterval		= CreateConVar("sm_lastboss_gravityinterval", 		"6.0", 		"Intervalo De Ataque Con Reducción De Gravedad Al Objetivo (Enemigo).", FCVAR_NOTIFY);
	sm_lastboss_quake_radius		= CreateConVar("sm_lastboss_quake_radius", 			"600.0", 	"Distancia Maxima De Alcanse De Los Temblores Y Arrojar A Los Objetivos Incapasitados.", FCVAR_NOTIFY);
	sm_lastboss_quake_force			= CreateConVar("sm_lastboss_quake_force", 			"350.0", 	"Distancia Maxima A La Que Pueden Ser Lanzados Los Objetivos Incapasitados (Enemigos).", FCVAR_NOTIFY);
	sm_lastboss_dreadinterval		= CreateConVar("sm_lastboss_dreadinterval", 		"8.0", 		"Intervalo De Enseguesimiento A Los Objetivos(Enemigos).", FCVAR_NOTIFY);
	sm_lastboss_dreadrate			= CreateConVar("sm_lastboss_dreadrate", 			"235", 		"Color De La Visión Del Objetivo Enseguesido (Enemigo).", FCVAR_NOTIFY);
	sm_lastboss_freezetime		    = CreateConVar("sm_lastboss_freezetime", 			"10", 		"Duración De Congelación Al Objetivo.", FCVAR_NOTIFY);
	sm_lastboss_freezeinterval	    = CreateConVar("sm_lastboss_freezeinterval", 		"6.0", 		"Intervalo De Congelación Al Objetivo (Enemigo).", FCVAR_NOTIFY);
	sm_lastboss_lazytime			= CreateConVar("sm_lastboss_lazytime", 				"10.0", 	"Intervalo De Ralentización Al Objetivo (Enemigo).", FCVAR_NOTIFY);
	sm_lastboss_lazyspeed		    = CreateConVar("sm_lastboss_lazyspeed", 			"0.3", 		"Velocidad Del Objetivo Relentizado (Enemigo).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar(								   "sm_lastboss_rabiesdamage", 			"10", 		"Intervalo De Daños Causados Por La Infección Al Objetivo (Enemigo).", FCVAR_NOTIFY);
	CreateConVar(								   "sm_lastboss_lavadamage", 			"50", 		"Cantidad Maxima De Daño Inflinjida Al Objetivo Por Parte Del Tank En Su Octava Forma.", FCVAR_NOTIFY);
	sm_lastboss_rabiestime		    = CreateConVar("sm_lastboss_rabiestime", 			"10", 		"Tiempo Maximo De Infección Al Objetivo.", FCVAR_NOTIFY);
	sm_lastboss_bombradius			= CreateConVar("sm_lastboss_bombradius", 			"250", 		"Alcanse Maximo De Daño Por Parte De Las Rocas Explosivas.", FCVAR_NOTIFY);
	sm_lastboss_bombdamage		    = CreateConVar("sm_lastboss_bombdamage", 			"300", 		"Alcanse Maximo De Daño Por El Tank Cuando Arroja Una Roca Explosiva.", FCVAR_NOTIFY);
	sm_lastboss_bombardforce	    = CreateConVar("sm_lastboss_bombardforce", 			"600.0", 	"Fuerza De Poder Del Tank Con Ataque De Roca Explisiva.", FCVAR_NOTIFY);
	sm_lastboss_eighth_c5m5_bridge	= CreateConVar("sm_lastboss_eigth_c5m5_bridge", 	"0", 		"Activar/Desactivar Last Boss Al Comienzo Del Útimo Capitulo De La Parroquia. 0 = Inactivo. 1 = Activo", FCVAR_NOTIFY);
	sm_lastboss_warp_interval		= CreateConVar("sm_lastboss_warp_interval", 		"35.0", 	"Intervalo De Frecuencia De Teletransportación Del Tank.", FCVAR_NOTIFY);
	
	/* Event hook */
	HookEvent("round_start", Event_Round_Start);
	HookEvent("finale_start", Event_Finale_Start);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_incapacitated", Event_Player_Hurt);
	HookEvent("round_end", Event_RoundEnd);
	if ( bL4D2 ) HookEvent("finale_bridge_lowering", Event_Finale_Start);

	AutoExecConfig(true, "l4d_lastboss 3.0");

	g_FadeUserMsgId = GetUserMessageId("Fade");	

	force_default = GetConVarInt( FindConVar( "z_tank_throw_force" ) );
	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	
	if((g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]")) == -1)
		LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
}

/******************************************************
*	Initial functions
*******************************************************/
void InitPrecache()
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

void InitData()
{
	/* Reset flags */
	bossflag = OFF;
	lastflag = OFF;
	idBoss = DEAD;
	form_prev = DEAD;
	wavecount = 0;
	FindConVar("z_tank_throw_force").IntValue = force_default;
}

public void OnMapStart()
{
	InitPrecache();
	InitData();
}

public void OnMapEnd()
{
	InitData();
}

public void Event_Round_Start(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	InitData();
}

public void Event_Finale_Start(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	bossflag = ON;
	lastflag = OFF;
	
	/* Exception handling for some map */
	static char CurrentMap[64];
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
public void Event_Tank_Spawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	static char CurrentMap[64];
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
		int client = GetClientOfUserId(hEvent.GetInt( "userid" ) );
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
			
			for(int j = 1; j <= MaxClients; j++)
				if(IsClientInGame(j) && !IsFakeClient(j))
					EmitSoundToClient(j, SOUND_SPAWN);
				
			if(GetConVarInt(sm_lastboss_enable_announce))
			{
				PrintToChatAll(MESSAGE_SPAWN);
				PrintToChatAll(MESSAGE_SPAWN2);
			}
		}
	}
}

public void Event_Player_Death(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt( "userid" ) );
	
	if ( client <= 0 || client > MaxClients )
		return;
	if ( !IsValidEntity( client ) || !IsClientInGame( client ) )
		return;
	if ( !IsTank( client ) )
		return;
	if ( wavecount < 2 && GetConVarInt( sm_lastboss_enable ) == 3 )
	{
		wavecount++;
		return;
	}

	if((bossflag && GetConVarInt(sm_lastboss_enable) == 1) || (GetConVarInt(sm_lastboss_enable) == 2) || (bossflag && GetConVarInt(sm_lastboss_enable) == 3))
	{
		/* Explode and burn when died */
		if(idBoss)
		{
			float Pos[3];
			GetClientAbsOrigin(idBoss, Pos);
			EmitSoundToAll(SOUND_EXPLODE, idBoss);
			ShowParticle(Pos, PARTICLE_DEATH, 5.0);
			LittleFlower(Pos, MOLOTOV);
			LittleFlower(Pos, EXPLODE);
			idBoss = DEAD;
			form_prev = DEAD;
		}
	}
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
	{
		char model[128];
		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, ENTITY_TIRE))
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			
			if (owner != client) 
				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			
			AcceptEntityInput(entity, "Kill");
		}
	}
	
	for (int i=1; i<=MaxClients; i++)
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

public void Event_RoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	for (int i=1; i<=MaxClients; i++)
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

public Action SetTankHealth(Handle hTimer, any client)
{
	/* Set health and ID after spawning */
	idBoss = client;
	static char CurrentMap[64];
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
public void Event_Player_Hurt(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int attacker = GetClientOfUserId(hEvent.GetInt( "attacker" ) );
	int target = GetClientOfUserId(hEvent.GetInt( "userid" ) );
	
	static char weapon[64];
	GetEventString(hEvent, "weapon", weapon, sizeof(weapon));
	
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
					SetEntityHealth( idBoss, (GetEventInt( hEvent, "dmg_health" ) + GetEventInt( hEvent, "health" ) ) );
				}
			}
			if(form_prev == FORMFOUR)
			{
				int random = GetRandomInt(1,4);
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

public void SkillEarthQuake(int target)
{
	float Pos[3], tPos[3];
	
	if(IsPlayerIncapped(target))
	{
		for(int i = 1; i <= MaxClients; i++)
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

public void SkillDreadClaw(int target)
{
	visibility = GetConVarInt(sm_lastboss_dreadrate);
	CreateTimer(GetConVarFloat(sm_lastboss_dreadinterval), DreadTimer, target);
	EmitSoundToAll(SOUND_DCLAW, target);
	ScreenFade(target, 0, 0, 0, visibility, 0, 0);
}

public void SkillGravityClaw(int target)
{
	SetEntityGravity(target, 0.3);
	CreateTimer(GetConVarFloat(sm_lastboss_gravityinterval), GravityTimer, target);
	EmitSoundToAll(SOUND_GCLAW, target);
	ScreenFade(target, 0, 0, 100, 80, 4000, 1);
	ScreenShake(target, 30.0);
}

public void SkillFreezeClaw(int target)
{
	FreezePlayer(target, GetConVarFloat(sm_lastboss_freezetime));
	CreateTimer(GetConVarFloat(sm_lastboss_freezeinterval), FreezeTimer, target);
}

public void SkillLazyClaw(int target)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i == idBoss)
			continue;
		if(!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
		
		if ( !IsTank( i ) )
			LazyPlayer( target );
	}
}

public void SkillRabiesClaw(int target)
{
	Rabies[target] = (GetConVarInt(sm_lastboss_rabiestime));
	CreateTimer(1.0, RabiesTimer, target);
	Toxin[target] = (GetConVarInt(sm_lastboss_rabiestime));
	CreateTimer(1.0, Toxin_Timer, target);
	EmitSoundToAll(SOUND_ROAR, target);
}

public void SkillBombClaw(int target)
{
	static float Pos[3];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
		GetClientAbsOrigin(i, Pos);
		if(GetVectorDistance(Pos, trsPos[target]) < GetConVarFloat(sm_lastboss_bombradius))
			DamageEffect(i, GetConVarFloat(sm_lastboss_bombdamage));
	}
	EmitSoundToAll(SOUND_BOMBARD, target);
	ScreenShake(target, 100.0);

	/* Explode */
	LittleFlower(Pos, EXPLODE);

	/* Push away */
	PushAway(target, GetConVarFloat(sm_lastboss_bombardforce), GetConVarFloat(sm_lastboss_bombradius), 0.5);
}

public void SkillBurnClaw(int target)
{
	EmitSoundToAll(SOUND_BCLAW, target);
	ScreenFade(target, 200, 0, 0, 150, 80, 1);
	ScreenShake(target, 50.0);
}

public void SkillCometStrike(int target, int type)
{
	static float pos[3];
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

public void SkillFlameGush(int target)
{
	float pos[3];

	SkillBurnClaw(target);
	LavaDamage(target);
	GetClientAbsOrigin(idBoss, pos);
	LittleFlower(pos, MOLOTOV);
}

public void SkillCallOfAbyss()
{
	/* Stop moving and prevent all damage for a while */
	SetEntityMoveType(idBoss, MOVETYPE_NONE);
	SetEntProp(idBoss, Prop_Data, "m_takedamage", 0, 1);
	
	for(int i = 1; i <= MaxClients; i++)
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
public Action TankUpdate(Handle hTimer)
{
	if(!IsValidEntity(idBoss) || !IsClientInGame(idBoss) || idBoss == DEAD)
		return;
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
		return;
	int health = GetClientHealth(idBoss);
	
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

public void SetPrameter(int form_next)
{
	int force;
	float speed;
	static char color[32];
	
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
		for(int j = 1; j <= MaxClients; j++)
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
			
		float Origin[3], Angles[3];
		GetEntPropVector(idBoss, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(idBoss, Prop_Send, "m_angRotation", Angles);
		Angles[0] += 90.0;
		int ent[3];
		for (int count = 1; count <= 2; count ++)
		{
			ent[count] = CreateEntityByName("prop_dynamic_override");
			if (IsValidEntity(ent[count]))
			{
				char tName[64];
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
	FindConVar("z_tank_throw_force").IntValue = force;
	
	/* Set speed */
	SetEntPropFloat(idBoss, Prop_Send, "m_flLaggedMovementValue", speed);
	
	/* Set color */
	SetEntityRenderMode( idBoss, view_as<RenderMode>( 0 ) );
	DispatchKeyValue( idBoss, "rendercolor", color );
}

/******************************************************
*	Timer functions
*******************************************************/
public Action ParticleTimer(Handle hTimer)
{
	if(form_prev == FORMFOUR)
		AttachParticle(idBoss, PARTICLE_FOURTH);
	else if(form_prev == FORMEIGHT)
		AttachParticle(idBoss, PARTICLE_EIGHTH);
	else
		KillTimer(hTimer);
}

public Action GravityTimer(Handle hTimer, any target)
{
	SetEntityGravity(target, 1.0);
}

public Action JumpingTimer(Handle hTimer)
{
	if(form_prev == FORMEIGHT && IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
		AddVelocity(idBoss, GetConVarFloat(sm_lastboss_jumpheight_eighth));
	else
		KillTimer(hTimer);
}

public Action StealthTimer(Handle hTimer)
{
	if(form_prev == FORMFOUR && idBoss)
	{
		alpharate = 255;
		Remove(idBoss);
	}
}

public Action DreadTimer(Handle hTimer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		visibility -= 8;
		if(visibility < 0)  visibility = 0;
		ScreenFade(target, 0, 0, 0, visibility, 0, 1);
		if(visibility <= 0)
		{
			visibility = 0;
			KillTimer(hTimer);
		}
	}
}

public Action FreezeTimer(Handle hTimer, any target)
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

public Action RabiesTimer(Handle hTimer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		if(Rabies[target] <= 0)
		{
			KillTimer(hTimer);
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

void KillToxin(int target)
{
	float pos[3];
	GetClientAbsOrigin(target, pos);
	float angs[3];
	GetClientEyeAngles(target, angs);

	angs[2] = 0.0;

	TeleportEntity(target, pos, angs, NULL_VECTOR);

	int clients[2];
	clients[0] = target;

	Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();
}

public Action Toxin_Timer(Handle hTimer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		if(Toxin[target] <= 0)
		{
			KillTimer(hTimer);
			return Plugin_Handled;
		}
		
		KillToxin(target);
		
		if(Toxin[target] > 0)
		{
			CreateTimer(1.0, Toxin_Timer, target);
			Toxin[target] -= 1;
		}
		
		float pos[3];
		GetClientAbsOrigin(target, pos);
		
		float angs[3];
		GetClientEyeAngles(target, angs);
		
		angs[2] = ToxinAngle[GetRandomInt(0,100) % 20];
		
		TeleportEntity(target, pos, angs, NULL_VECTOR);
		
		int clients[2];
		clients[0] = target;
		
		Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
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

public Action HowlTimer(Handle hTimer)
{
	if(idBoss)
	{
		SetEntityMoveType(idBoss, MOVETYPE_WALK);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 2, 1);
	}
}

public Action WarpTimer(Handle hTimer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		float pos[3];
		
		for(int i = 1; i <= MaxClients; i++)
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
		KillTimer(hTimer);
	}
}

public Action GetSurvivorPosition(Handle hTimer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != DEAD)
	{
		int count = 0;
		int idAlive[MAXPLAYERS+1];
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != SURVIVOR)
				continue;
			idAlive[count] = i;
			count++;
		}
		if(count == 0) return;
		int clientNum = GetRandomInt(0, count-1);
		GetClientAbsOrigin(idAlive[clientNum], ftlPos);
	}
	else
	{
		KillTimer(hTimer);
	}
}

public Action FatalMirror(Handle hTimer)
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
		KillTimer(hTimer);
	}
}

/******************************************************
*	Gimmick functions
*******************************************************/
public Action Remove(int ent)
{
	if(IsValidEntity(ent))
	{
		CreateTimer(0.1, fadeout, ent, TIMER_REPEAT);
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	}
}

public Action fadeout(Handle hTimer, any ent)
{
	if(!IsValidEntity(ent) || form_prev != FORMFOUR)
	{
		KillTimer(hTimer);
		return;
	}
	alpharate -= 2;
	if (alpharate < 0)  alpharate = 0;
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 80, 80, 255, alpharate);
	if(alpharate <= 0)
	{
		KillTimer(hTimer);
	}
}

public void AddVelocity(int client, float zSpeed)
{
	if(g_iVelocity == -1) return;
	
	float vecVelocity[3];
	GetEntDataVector(client, g_iVelocity, vecVelocity);
	vecVelocity[2] += zSpeed;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

public void LittleFlower(float pos[3], int type)
{
	/* Cause fire(type=0) or explosion(type=1) */
	int entity = CreateEntityByName("prop_physics");
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

public void Smash(int client, int target, float power, float powHor, float powVec)
{
	/* Blow off target */
	static float HeadingVector[3];
	static float AimVector[3];
	GetClientEyeAngles(client, HeadingVector);
	
	AimVector[0] = Cosine( DegToRad( HeadingVector[1] ) ) * ( power * powHor );
	AimVector[1] = Sine( DegToRad( HeadingVector[1] ) ) * ( power * powHor );
	
	static float current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	static float resulting[3];
	resulting[0] = current[0] + AimVector[0];
	resulting[1] = current[1] + AimVector[1];
	resulting[2] = power * powVec;
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

public int ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
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

public void ScreenShake(int target, float intensity)
{
	Handle msg;
	msg = StartMessageOne("Shake", target);
	
	BfWriteByte(msg, 0);
 	BfWriteFloat(msg, intensity);
 	BfWriteFloat(msg, 10.0);
 	BfWriteFloat(msg, 3.0);
	EndMessage();
}

public void TriggerPanicEvent()
{
	int flager = GetAnyClient();
	if(flager == -1)  return;
	int flag = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flag & ~FCVAR_CHEAT);
	FakeClientCommand(flager, "director_force_panic_event");
}

public void FreezePlayer(int target, float time)
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

public void LazyPlayer(int target)
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

public Action Quick(Handle hTimer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target))
	{
		SetEntDataFloat(target, laggedMovementOffset, 1.0, true);
		isSlowed[target] = false;
		SetEntityRenderColor(target, 255, 255, 255, 255);
		EmitSoundToAll(SOUND_QUICK, target);
	}
}

stock void RabiesDamage(int target)
{
	char dmg_str[16];
	char dmg_type_str[16];
	IntToString((1 << 17),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("sm_lastboss_rabiesdamage"), dmg_str, sizeof(dmg_str));
	int pointHurt = CreateEntityByName("point_hurt");
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

stock void LavaDamage(int target)
{
	char dmg_lava[16];
	char dmg_type_lava[16];
	IntToString((1 << 17),dmg_lava,sizeof(dmg_type_lava));
	GetConVarString(FindConVar("sm_lastboss_lavadamage"), dmg_lava, sizeof(dmg_lava));
	int pointHurt = CreateEntityByName("point_hurt");
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

stock void DamageEffect(int target, float damage)
{
	char tName[20];
	Format(tName, 20, "target%d", target);
	int pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(target, "targetname", tName);
	DispatchKeyValueFloat(pointHurt, "Damage", damage);
	DispatchKeyValue(pointHurt, "DamageTarget", tName);
	DispatchKeyValue(pointHurt, "DamageType", "65536");
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt");
	AcceptEntityInput(pointHurt, "Kill");
}

stock void ForceWeaponDrop(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 1);
	SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
}

public void PushAway(int target, float force, float radius, float duration)
{
	int push = CreateEntityByName("point_push");
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
public void ShowParticle(float pos[3], char[] particlename, float time)
{
	/* Show particle effect you like */
	int particle = CreateEntityByName("info_particle_system");
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

public void AttachParticle(int ent, char[] particleType)
{
	static char tName[64];
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		float pos[3];
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

public Action DeleteParticles(Handle hTimer, any particle)
{
	/* Delete particle */
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
			RemoveEdict(particle);
	}
}

public Action PrecacheParticle(char[] particlename)
{
	/* Precache particle */
	int particle = CreateEntityByName("info_particle_system");
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

public Action DeletePushForce(Handle hTimer, any ent)
{
	if (ent> 0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		static char classname[64];
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
bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		return true;
	else
		return false;
}

int GetAnyClient()
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsValidEntity(i) && IsClientInGame(i))
			return i;
		
	return -1;
}

public bool IsValidClient(int client)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(client))
		return false;
	
	return true;
}

/**
 * Validates if the current client is valid to run the plugin.
 *
 * @param client		The client index.
 * @return              False if the client is not the Tank, true otherwise.
 */
stock bool IsTank( int client )
{
	if( client > 0 && client <= MaxClients && IsClientInGame( client ) && GetClientTeam( client ) == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == ( bL4D2 ? 8 : 5 ) )
			return true;
	}
	return false;
}

/******************************************************
*	The End
*******************************************************/