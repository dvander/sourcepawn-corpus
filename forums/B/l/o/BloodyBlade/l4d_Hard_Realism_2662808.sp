#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.5"
#define WORLDINDEX 0
#undef REQUIRE_PLUGIN

int FogControllerIndex;

ConVar cvarEnabled;
ConVar cvarSkybox;

Handle WelcomeTimers[MAXPLAYERS+1];
ConVar cvarFogDensity;
ConVar cvarFogStartDist;
ConVar cvarFogEndDist;
ConVar cvarFogColor;
ConVar cvarFogZPlane;
ConVar cvarBrightness;

ConVar Enable;
ConVar Modes;

ConVar MLGlow;
ConVar IgnoringColorblindSet;
int glowhook = 1;

ConVar GlowItemFarRed1;
ConVar GlowItemFarGreen1;
ConVar GlowItemFarBlue1;
ConVar GlowItemFarRed2;
ConVar GlowItemFarGreen2;
ConVar GlowItemFarBlue2;
	
ConVar GlowGhostInfectedRed1;
ConVar GlowGhostInfectedGreen1;
ConVar GlowGhostInfectedBlue1;
ConVar GlowGhostInfectedRed2;
ConVar GlowGhostInfectedGreen2;
ConVar GlowGhostInfectedBlue2;
	
ConVar GlowItemRed1;
ConVar GlowItemGreen1;
ConVar GlowItemBlue1;
ConVar  GlowItemRed2;
ConVar  GlowItemGreen2;
ConVar  GlowItemBlue2;
	
ConVar GlowSurvivorHurtRed1;
ConVar GlowSurvivorHurtGreen1;
ConVar GlowSurvivorHurtBlue1;
ConVar GlowSurvivorHurtRed2;
ConVar GlowSurvivorHurtGreen2;
ConVar GlowSurvivorHurtBlue2;
	
ConVar GlowSurvivorVomitRed1;
ConVar GlowSurvivorVomitGreen1;
ConVar GlowSurvivorVomitBlue1;
ConVar GlowSurvivorVomitRed2;
ConVar GlowSurvivorVomitGreen2;
ConVar GlowSurvivorVomitBlue2;
		
ConVar GlowInfectedRed1;
ConVar GlowInfectedGreen1;
ConVar GlowInfectedBlue1;
ConVar GlowInfectedRed2;
ConVar GlowInfectedGreen2;
ConVar GlowInfectedBlue2;
	
ConVar GlowSurvivorRed2;
ConVar GlowSurvivorGreen2;
ConVar GlowSurvivorBlue2;

/********************************************************/
/*****************  	VERSION 1.5   *******************/
/********************************************************/
				
ConVar GlowAbilityBlue1;
ConVar GlowAbilityGreen1;
ConVar GlowAbilityRed1;
ConVar GlowAbilityBlue2;
ConVar GlowAbilityGreen2;
ConVar GlowAbilityRed2;

ConVar GlowInfectedVomitBlue1;
ConVar GlowInfectedVomitGreen1;
ConVar GlowInfectedVomitRed1;
ConVar GlowInfectedVomitBlue2;
ConVar GlowInfectedVomitGreen2;
ConVar GlowInfectedVomitRed2;
		
ConVar GlowSurvivorHealthHighBlue1;
ConVar GlowSurvivorHealthHighGreen1;
ConVar GlowSurvivorHealthHighRed1;
ConVar GlowSurvivorHealthHighBlue2;
ConVar GlowSurvivorHealthHighGreen2;
ConVar GlowSurvivorHealthHighRed2;

ConVar GlowSurvivorHealthMedBlue1;
ConVar GlowSurvivorHealthMedGreen1;
ConVar GlowSurvivorHealthMedRed1;
ConVar GlowSurvivorHealthMedBlue2;
ConVar GlowSurvivorHealthMedGreen2;
ConVar GlowSurvivorHealthMedRed2;

ConVar GlowSurvivorHealthLowBlue1;
ConVar GlowSurvivorHealthLowGreen1;
ConVar GlowSurvivorHealthLowRed1;
ConVar GlowSurvivorHealthLowBlue2;
ConVar GlowSurvivorHealthLowGreen2;
ConVar GlowSurvivorHealthLowRed2;

ConVar GlowThirdstrikeItemBlue1;
ConVar GlowThirdstrikeItemGreen1;
ConVar GlowThirdstrikeItemRed1;
ConVar GlowThirdstrikeItemBlue2;
ConVar GlowThirdstrikeItemGreen2;
ConVar GlowThirdstrikeItemRed2;

/********************************************************/
/***************** 		  INFO 		  *******************/
/********************************************************/
public Plugin myinfo = 
{
	name = "Hard Realism",
	author = "Striker Black and ThrillKill",
	description = "Hard Co-op, Extreme Co-op",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?p=2324780"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_hudhider_version", PLUGIN_VERSION, "Version Hud", FCVAR_NONE|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	Enable = CreateConVar("l4d_hudhider_enable", "1", "Habilitar Hud?", FCVAR_NONE);
	Modes = CreateConVar("l4d_hudhider_modes", "versus,coop,survival", "Modalidades de Juego", FCVAR_NONE);
	
	CreateConVar("ml_version", PLUGIN_VERSION, "[L4D] Version Glow", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	MLGlow = CreateConVar("ml_glow_mode", "1", "Glow Mode (0 - default, 1 - Q1 glow, 2 - D1 glow, 3 - Resplandor de configuración personalizada)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	IgnoringColorblindSet = CreateConVar("ml_glow_colorblindset_ignoring", "1", "Colores están cambiando, incluso si el cliente está configurado para daltónicos? (0 - No, 1 - Yes)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	CreateConVar("sm_envtools_version", PLUGIN_VERSION, "SM Environmental Tools Version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_envtools_enable", "1.0", "Alternar Skybox Cambio en tiempo real", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarSkybox = CreateConVar("sm_envtools_skybox", "docks_hdr", "Alternar Skybox Cambio en tiempo real", FCVAR_NONE);
	//cvarSkybox = CreateConVar("sm_envtools_skybox", "docks_hdr", "Alternar Skybox Cambio en tiempo real", FCVAR_PLUGIN);

	cvarFogDensity = CreateConVar("sm_envtools_fogdensity", "0.6", "Alternar la densidad de los efectos de niebla", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarFogStartDist = CreateConVar("sm_envtools_fogstart", "0.0", "Alternar ¿A qué distancia se inicia la niebla?", FCVAR_NONE, true, 0.0, true, 8000.0);
	cvarFogEndDist = CreateConVar("sm_envtools_fogend", "500.0", "Cambiar a qué distancia de la niebla está en su apogeo", FCVAR_NONE, true, 0.0, true, 8000.0);
	cvarFogColor = CreateConVar("sm_envtools_fogcolor", "50 50 50", "Modificar el color de la niebla", FCVAR_NONE);
	cvarFogZPlane = CreateConVar("sm_envtools_zplane", "4000.0", "Cambie el plano Z recorte", FCVAR_NONE, true, 0.0, true, 8000.0);
	cvarBrightness = CreateConVar("sm_envtools_brightness", "a", "Cambia el brillo del mundo (a-z)", FCVAR_NONE);
	
	RegAdminCmd("sm_envtools_update", Command_Update, ADMFLAG_KICK, "Updates all lighting and fog convar settings");
	
	HookConVarChange(cvarFogColor, ConvarChange_FogColor);

	/********************************************************/
	/*****************        Glow        *******************/
	/********************************************************/
	GlowItemFarRed1 = CreateConVar("ml_glow_item_far_r_one", "0.3", "El color rojo de los artículos en un resplandor distancia (Primer stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemFarGreen1 = CreateConVar("ml_glow_item_far_g_one", "0.4", "El color verde de los artículos en un resplandor distancia (Primer stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemFarBlue1 = CreateConVar("ml_glow_item_far_b_one", "1.0", "El color azul de los artículos en un resplandor distancia (Primer stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemFarRed2 = CreateConVar("ml_glow_item_far_r_two", "0.3", "El color rojo de los artículos en un resplandor distancia (Sefunda stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemFarGreen2 = CreateConVar("ml_glow_item_far_g_two", "0.4", "El color verde de los artículos en un resplandor distancia (Segunda stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemFarBlue2 = CreateConVar("ml_glow_item_far_b_two", "1.0", "El color azul de los artículos en un resplandor distancia (Segunda stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	GlowGhostInfectedRed1 = CreateConVar("ml_glow_ghost_infected_r_one", "0.3", "El color rojo del resplandor fantasma infectada (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowGhostInfectedGreen1 = CreateConVar("ml_glow_ghost_infected_g_one", "0.4", "El color verde del resplandor fantasma infectada (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowGhostInfectedBlue1 = CreateConVar("ml_glow_ghost_infected_b_one", "1.0", "El color azul del resplandor fantasma infectada (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowGhostInfectedRed2 = CreateConVar("ml_glow_ghost_infected_r_two", "0.3", "El color rojo del resplandor fantasma infectada (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowGhostInfectedGreen2 = CreateConVar("ml_glow_ghost_infected_g_two", "0.4", "El color verde del resplandor fantasma infectada (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowGhostInfectedBlue2 = CreateConVar("ml_glow_ghost_infected_b_two", "1.0", "El color azul del resplandor fantasma infectada (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	GlowItemRed1 = CreateConVar("ml_glow_item_r_one", "0.7", "El color rojo de artículos de cerca (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemGreen1 = CreateConVar("ml_glow_item_g_one", "0.7", "El color verde de artículos de cerca glow (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemBlue1 = CreateConVar("ml_glow_item_b_one", "1.0", "El color azul de artículos de cerca (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemRed2 = CreateConVar("ml_glow_item_r_two", "0.7", "El color rojo de artículos de cerca (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemGreen2 = CreateConVar("ml_glow_item_g_two", "0.7", "El color verde de artículos de cerca (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemBlue2 = CreateConVar("ml_glow_item_b_two", "1.0", "El color azul de artículos de cerca (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	GlowSurvivorHurtRed1 = CreateConVar("ml_glow_survivor_hurt_r_one", "1.0", "El color rojo de sobreviviente compañero de equipo resplandor cuando incapacitado (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHurtGreen1 = CreateConVar("ml_glow_survivor_hurt_g_one", "0.4", "El color verde de sobreviviente compañero de equipo resplandor cuando incapacitado (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHurtBlue1 = CreateConVar("ml_glow_survivor_hurt_b_one", "0.0", "El color azul de sobreviviente compañero de equipo resplandor cuando incapacitado (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHurtRed2 = CreateConVar("ml_glow_survivor_hurt_r_two", "1.0", "El color rojo de sobreviviente compañero de equipo resplandor cuando incapacitado (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHurtGreen2 = CreateConVar("ml_glow_survivor_hurt_g_two", "0.4", "El color verde de sobreviviente compañero de equipo resplandor cuando incapacitado (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHurtBlue2 = CreateConVar("ml_glow_survivor_hurt_b_two", "0.0", "El color azul de sobreviviente compañero de equipo resplandor cuando incapacitado (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	GlowSurvivorVomitRed1 = CreateConVar("ml_glow_survivor_vomit_r_one", "1.0", "De color rojo los sobrevivientes ver el resplandor víctima de TI (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorVomitGreen1 = CreateConVar("ml_glow_survivor_vomit_g_one", "0.4", "De verde rojo los sobrevivientes ver el resplandor víctima de TI (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorVomitBlue1 = CreateConVar("ml_glow_survivor_vomit_b_one", "0.0", "De color azul los sobrevivientes ver el resplandor víctima de TI (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorVomitRed2 = CreateConVar("ml_glow_survivor_vomit_r_two", "1.0", "De color rojo los sobrevivientes ver el resplandor víctima de TI (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorVomitGreen2 = CreateConVar("ml_glow_survivor_vomit_g_two", "0.4", "De verde rojo los sobrevivientes ver el resplandor víctima de TI (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorVomitBlue2 = CreateConVar("ml_glow_survivor_vomit_b_two", "0.0", "De color rojo los sobrevivientes ver el resplandor víctima de TI (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
			
	GlowInfectedRed1 = CreateConVar("ml_glow_infected_r_one", "0.3", "El color rojo del resplandor infectada (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedGreen1 = CreateConVar("ml_glow_infected_g_one", "0.4", "El color verde del resplandor infectada (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedBlue1 = CreateConVar("ml_glow_infected_b_one", "1.0", "El color azul del resplandor infectada (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedRed2 = CreateConVar("ml_glow_infected_r_two", "0.3", "Red color of infected glow (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedGreen2 = CreateConVar("ml_glow_infected_g_two", "0.4", "Green color of infected glow (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedBlue2 = CreateConVar("ml_glow_infected_b_two", "1.0", "Blue color of infected glow (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
	/********************************************************/
	/*****************   Version 1.5      *******************/
	/********************************************************/
	GlowAbilityRed1 = CreateConVar("ml_glow_ability_r_one", "1.0", "El color rojo de la capacidad resplandor (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);			
	GlowAbilityGreen1 = CreateConVar("ml_glow_ability_g_one", "0.0", "El color verde de la capacidad resplandor (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowAbilityBlue1 = CreateConVar("ml_glow_ability_b_one", "0.0", "El color azul de la capacidad resplandor (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowAbilityRed2 = CreateConVar("ml_glow_ability_r_two", "1.0", "El color rojo de la capacidad resplandor (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);			
	GlowAbilityGreen2 = CreateConVar("ml_glow_ability_g_two", "0.0", "El color verde de la capacidad resplandor (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowAbilityBlue2 = CreateConVar("ml_glow_ability_b_two", "0.0", "El color azul de la capacidad resplandor (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
	GlowInfectedVomitRed1 = CreateConVar("ml_glow_infected_vomit_r_one", "0.79", "Red los PZs ver el resplandor víctima de TI (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);	
	GlowInfectedVomitGreen1 = CreateConVar("ml_glow_infected_vomit_g_one", "0.07", "Green los PZs ver el resplandor víctima de TI (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedVomitBlue1 = CreateConVar("ml_glow_infected_vomit_b_one", "0.72", "Blue los PZs ver el resplandor víctima de TI (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedVomitRed2 = CreateConVar("ml_glow_infected_vomit_r_two", "0.79", "Red los PZs ver el resplandor víctima de TI (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedVomitGreen2 = CreateConVar("ml_glow_infected_vomit_g_two", "0.07", "Green los PZs ver el resplandor víctima de TI (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedVomitBlue2 = CreateConVar("ml_glow_infected_vomit_b_two", "0.72", "Blue los PZs ver el resplandor víctima de TI (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	GlowSurvivorHealthHighRed1 = CreateConVar("ml_glow_survivor_health_high_r_one", "0.039", "De color rojo los Infectados ver sobrevivientes cuando su salud es alta (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighGreen1 = CreateConVar("ml_glow_survivor_health_high_g_one", "0.69", "De color verde los Infectados ver sobrevivientes cuando su salud es alta (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighBlue1 = CreateConVar("ml_glow_survivor_health_high_b_one", "0.196", "De color azul los Infectados ver sobrevivientes cuando su salud es alta (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighRed2 = CreateConVar("ml_glow_survivor_health_high_r_two", "0.039", "De color rojo los Infectados ver sobrevivientes cuando su salud es alta (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighGreen2 = CreateConVar("ml_glow_survivor_health_high_g_two", "0.69", "De color verde los Infectados ver sobrevivientes cuando su salud es alta (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighBlue2 = CreateConVar("ml_glow_survivor_health_high_b_two", "0.196", "De color azul los Infectados ver sobrevivientes cuando su salud es alta (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	GlowSurvivorHealthMedRed1 = CreateConVar("ml_glow_survivor_health_med_r_one", "0.59", "De color rojo los Infectados ver sobrevivientes cuando su salud es medio (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedGreen1 = CreateConVar("ml_glow_survivor_health_med_g_one", "0.4", "De color verde los Infectados ver sobrevivientes cuando su salud es medio (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedBlue1 = CreateConVar("ml_glow_survivor_health_med_b_one", "0.032", "De color azul los Infectados ver sobrevivientes cuando su salud es medio (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedRed2 = CreateConVar("ml_glow_survivor_health_med_r_two", "0.59", "De color rojo los Infectados ver sobrevivientes cuando su salud es medio (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedGreen2 = CreateConVar("ml_glow_survivor_health_med_g_two", "0.4", "De color verde los Infectados ver sobrevivientes cuando su salud es medio (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedBlue2 = CreateConVar("ml_glow_survivor_health_med_b_two", "0.032", "De color azul los Infectados ver sobrevivientes cuando su salud es medio (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
	GlowSurvivorHealthLowRed1 = CreateConVar("ml_glow_survivor_health_low_r_one", "0.63", "De color rojo los Infectados ver sobrevivientes cuando su salud es bajo (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowGreen1 = CreateConVar("ml_glow_survivor_health_low_g_one", "0.098", "De color verde los Infectados ver sobrevivientes cuando su salud es bajo (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowBlue1 = CreateConVar("ml_glow_survivor_health_low_b_one", "0.098", "De color azul los Infectados ver sobrevivientes cuando su salud es bajo (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowRed2 = CreateConVar("ml_glow_survivor_health_low_r_two", "0.63", "De color rojo los Infectados ver sobrevivientes cuando su salud es bajo (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowGreen2 = CreateConVar("ml_glow_survivor_health_low_g_two", "0.098", "De color verde los Infectados ver sobrevivientes cuando su salud es bajo (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowBlue2 = CreateConVar("ml_glow_survivor_health_low_b_two", "0.098", "De color azul los Infectados ver sobrevivientes cuando su salud es bajo (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	GlowThirdstrikeItemRed1 = CreateConVar("ml_glow_thirdstrike_item_r_one", "1.0", "El color rojo de sobreviviente compañero resplandor (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowThirdstrikeItemGreen1 = CreateConVar("ml_glow_thirdstrike_item_g_one", "0.0", "El color verde de las partidas en modo blanco y negro (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowThirdstrikeItemBlue1 = CreateConVar("ml_glow_thirdstrike_item_b_one", "0.0", "El color azul de las partidas en modo blanco y negro (First stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowThirdstrikeItemRed2 = CreateConVar("ml_glow_thirdstrike_item_r_two", "1.0", "El color rojo de sobreviviente compañero resplandor (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowThirdstrikeItemGreen2 = CreateConVar("ml_glow_thirdstrike_item_g_two", "0.0", "El color verde de las partidas en modo blanco y negro (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowThirdstrikeItemBlue2 = CreateConVar("ml_glow_thirdstrike_item_b_two", "0.0", "El color azul de las partidas en modo blanco y negro (Second stage)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.0, true, 1.0);	
				
	HookConVarChange(MLGlow, CvarChanged);
}

stock bool IsAllowedGameMode()
{
	char gamemode[24], gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(Modes, gamemodeactive, sizeof(gamemodeactive));
	return (StrContains(gamemodeactive, gamemode) != -1);
}	

public void OnMapStart()
{	
	FogControllerIndex = FindEntityByClassname(-1, "env_fog_controller");
	
	if(FogControllerIndex == -1)
	{
		PrintToServer("[ET] No Fog Controller Exists. This Entity is either unsupported by this Game, or this Level Does not Include it.");
	}
	
	if(GetConVarBool(cvarEnabled))
	{
		ChangeSkyboxTexture();
		ChangeFogSettings();
		ChangeFogColors();
		char szLightStyle[6];
		GetConVarString(cvarBrightness, szLightStyle, sizeof(szLightStyle));
		SetLightStyle(0, szLightStyle);
	}
}

public void OnClientAuthorized(int client)
{
	if(IsAllowedGameMode() && GetConVarInt(Enable) == 1 && !IsFakeClient(client))
	{
		CreateTimer(5.0, Enforce, client, TIMER_REPEAT);
	}	
}

public Action Enforce(Handle Timer, any client)
{
	if(IsClientInGame(client) && GetClientTeam(client) == 2 && GetConVarInt(Enable) == 1 && IsAllowedGameMode() && IsValidEntity(client))
		SetEntProp(client, Prop_Send, "m_iHideHUD", 64);
	if(IsClientInGame(client) && GetClientTeam(client) == 3)
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	if(IsClientInGame(client) && GetClientTeam(client) == 1)
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);	
}

public void OnClientPutInServer(int client) 
{
	DisableGlows(client);
	WelcomeTimers[client] = CreateTimer(18.0, WelcomePlayer, client);
}

void DisableGlows(int client) 
{
	FakeClientCommand(client, "cl_glow_survivor_r 0");
	FakeClientCommand(client, "cl_glow_survivor_g 0");
	FakeClientCommand(client, "cl_glow_survivor_b 0");
	FakeClientCommand(client, "cl_glow_survivor_hurt_r 0");
	FakeClientCommand(client, "cl_glow_survivor_hurt_g 0");
	FakeClientCommand(client, "cl_glow_survivor_hurt_b 0");
	FakeClientCommand(client, "cl_glow_survivor_vomit_r 0");
	FakeClientCommand(client, "cl_glow_survivor_vomit_g 0");
	FakeClientCommand(client, "cl_glow_survivor_vomit_b 0");
	FakeClientCommand(client, "cl_glow_item_r 0");
	FakeClientCommand(client, "cl_glow_item_b 0");
	FakeClientCommand(client, "cl_glow_item_g 0");
	FakeClientCommand(client, "cl_glow_item_far_r 0");
	FakeClientCommand(client, "cl_glow_item_far_b 0");
	FakeClientCommand(client, "cl_glow_item_far_g 0");
	FakeClientCommand(client, "cl_glow_thirdstrike_item_r 0");
	FakeClientCommand(client, "cl_glow_thirdstrike_item_b 0");
	FakeClientCommand(client, "cl_glow_thirdstrike_item_g 0");
	FakeClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r 0");
	FakeClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b 0");
	FakeClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g 0");
	FakeClientCommand(client, "cl_glow_ability_r 0");
	FakeClientCommand(client, "cl_glow_ability_g 0");
	FakeClientCommand(client, "cl_glow_ability_b 0");
	FakeClientCommand(client, "cl_glow_ability_colorblind_r 0");
	FakeClientCommand(client, "cl_glow_ability_colorblind_g 0");
	FakeClientCommand(client, "cl_glow_ability_colorblind_b 0");
}

public void OnClientDisconnect(int client)
{
	if (WelcomeTimers[client] != INVALID_HANDLE)
	{
		KillTimer(WelcomeTimers[client]);
		WelcomeTimers[client] = INVALID_HANDLE;
	}
}

public Action WelcomePlayer(Handle timer, any client)
{
	char name[128];
	GetClientName(client, name, sizeof(name));
	PrintToChat(client, "\x04Welcome, \x03%s!", name);
	PrintToChat(client, "\x01Hard Server \x04- \x01Realism Mod\x04!");
	WelcomeTimers[client] = INVALID_HANDLE;
}

public void OnClientPostAdminCheck(int client)
{
	if(glowhook != 0)
	{
		if(IsClientConnected(client))
		{
			TimerStart(client);
		}
	}
}
	
public void OnConfigExecuted()
{
	glowhook = GetConVarInt(MLGlow);
}
	
public void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	glowhook = GetConVarInt(MLGlow);
	if (glowhook !=0)
	{
		for(int i = 1; i<=MaxClients;i++)
		{
			TimerStart(i);
		}
	}
}
	
public Action Glow1(Handle timer, any client)  
{
	if(!IsClientConnected(client) && !IsClientInGame(client))
	{
		return Plugin_Stop;
	}
		
	switch (glowhook)
	{
		case 0:
		{
			//Resplandor de objetos desde la distancia
			FakeClientCommand(client, "cl_glow_item_far_b 0.50");
			FakeClientCommand(client, "cl_glow_item_far_g 0.0");
			FakeClientCommand(client, "cl_glow_item_far_r 0.0");
				
			//El color del resplandor fantasma infectada
			FakeClientCommand(client, "cl_glow_ghost_infected_b 1.0");
			FakeClientCommand(client, "cl_glow_ghost_infected_g 0.4");
			FakeClientCommand(client, "cl_glow_ghost_infected_r 0.3");
				
			//Resplandor de artículos de cerca
			FakeClientCommand(client, "cl_glow_item_b 2.0");
			FakeClientCommand(client, "cl_glow_item_g 0.0");
			FakeClientCommand(client, "cl_glow_item_r 0.0");
				
			//El color de sobreviviente compañero de equipo resplandor cuando incapacitado
			FakeClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
			FakeClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
			FakeClientCommand(client, "cl_glow_survivor_hurt_r 3.0");
				
			//Colorea los sobrevivientes ver el resplandor víctima de TI
			FakeClientCommand(client, "cl_glow_survivor_vomit_b 0.0");
			FakeClientCommand(client, "cl_glow_survivor_vomit_g 0.5");
			FakeClientCommand(client, "cl_glow_survivor_vomit_r 2.0");
				
			//El color de resplandor infectada
			FakeClientCommand(client, "cl_glow_infected_b 1.0");
			FakeClientCommand(client, "cl_glow_infected_g 0.4");
			FakeClientCommand(client, "cl_glow_infected_r 0.3");
								
			/********************************************************/
			/*****************                    *******************/
			/********************************************************/
							
			//Color de la capacidad de brillo
			FakeClientCommand(client, "cl_glow_ability_b 10.0");
			FakeClientCommand(client, "cl_glow_ability_g 10.0");
			FakeClientCommand(client, "cl_glow_ability_r 10.0");
			
			//Color de la capacidad de brillo para las personas con daltónico
			FakeClientCommand(client, "cl_glow_ability_colorblind_b 1.0");
			FakeClientCommand(client, "cl_glow_ability_colorblind_g 1.0");
			FakeClientCommand(client, "cl_glow_ability_colorblind_r 0.3");
				
			//Carolorea el PZs ver el resplandor víctima de TI
			FakeClientCommand(client, "cl_glow_infected_vomit_b 0.72");
			FakeClientCommand(client, "cl_glow_infected_vomit_g 0.07");
			FakeClientCommand(client, "cl_glow_infected_vomit_r 0.79");
				
			//Color los Infectados ver Sobrevivientes cuando su salud es alta
			FakeClientCommand(client, "cl_glow_survivor_health_high_b 0.196");
			FakeClientCommand(client, "cl_glow_survivor_health_high_g 0.69");
			FakeClientCommand(client, "cl_glow_survivor_health_high_r 0.039");
			//Color los Infectados ver Sobrevivientes cuando su salud es alto para las personas con daltónico
			FakeClientCommand(client, "cl_glow_survivor_health_high_colorblind_b 0.392");
			FakeClientCommand(client, "cl_glow_survivor_health_high_colorblind_g 0.694");
			FakeClientCommand(client, "cl_glow_survivor_health_high_colorblind_r 0.047");

			//Color los Infectados ver Sobrevivientes cuando su salud es medio
			FakeClientCommand(client, "cl_glow_survivor_health_med_b 0.032");
			FakeClientCommand(client, "cl_glow_survivor_health_med_g 0.4");
			FakeClientCommand(client, "cl_glow_survivor_health_med_r 0.59");
			//Color los Infectados ver Sobrevivientes cuando su salud es medio para las personas con daltónico
			FakeClientCommand(client, "cl_glow_survivor_health_med_colorblind_b 0.098");
			FakeClientCommand(client, "cl_glow_survivor_health_med_colorblind_g 0.573");
			FakeClientCommand(client, "cl_glow_survivor_health_med_colorblind_r 0.694");

			//Color los Infectados ver Sobrevivientes cuando su salud es bajo
			FakeClientCommand(client, "cl_glow_survivor_health_low_b 0.098");
			FakeClientCommand(client, "cl_glow_survivor_health_low_g 0.098");
			FakeClientCommand(client, "cl_glow_survivor_health_low_r 0.63");
			//Color los Infectados ver Sobrevivientes cuando su salud es baja para las personas con daltónico
			FakeClientCommand(client, "cl_glow_survivor_health_low_colorblind_b 0.807");
			FakeClientCommand(client, "cl_glow_survivor_health_low_colorblind_g 0.807");
			FakeClientCommand(client, "cl_glow_survivor_health_low_colorblind_r 0.047");

			//Resplandor de elementos en el modo de "blanco y negro"
			FakeClientCommand(client, "cl_glow_thirdstrike_item_b 1.0");
			FakeClientCommand(client, "cl_glow_thirdstrike_item_g 0.0");
			FakeClientCommand(client, "cl_glow_thirdstrike_item_r 0.0");
			//Resplandor de elementos en el modo de "blanco y negro" para las personas con daltonismo
			FakeClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b 1.0");
			FakeClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g 1.0");
			FakeClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r 0.3");
				
			return Plugin_Stop;
		}	
		case 1:
		{
			FakeClientCommand(client, "cl_glow_item_far_r 0.0");
			FakeClientCommand(client, "cl_glow_item_far_g 0.0");
			FakeClientCommand(client, "cl_glow_item_far_b 0.79");
				
			FakeClientCommand(client, "cl_glow_ghost_infected_r 0.35");
			FakeClientCommand(client, "cl_glow_ghost_infected_g 0.35");
			FakeClientCommand(client, "cl_glow_ghost_infected_b 0.35");
				
			FakeClientCommand(client, "cl_glow_item_r 0.0");
			FakeClientCommand(client, "cl_glow_item_g 0.0");
			FakeClientCommand(client, "cl_glow_item_b 2.0");
				
			FakeClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
			FakeClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
			FakeClientCommand(client, "cl_glow_survivor_hurt_r 3.0");
				
			FakeClientCommand(client, "cl_glow_survivor_vomit_b 0.72");
			FakeClientCommand(client, "cl_glow_survivor_vomit_g 0.7");
			FakeClientCommand(client, "cl_glow_survivor_vomit_r 0.79");
				
			FakeClientCommand(client, "cl_glow_infected_b 1.0");
			FakeClientCommand(client, "cl_glow_infected_g 0.5");
			FakeClientCommand(client, "cl_glow_infected_r 0.0");
		}	
		case 2:
		{
			FakeClientCommand(client, "cl_glow_item_far_r 0.0");
			FakeClientCommand(client, "cl_glow_item_far_b 0.79");
			FakeClientCommand(client, "cl_glow_item_far_g 0.0");
				
			FakeClientCommand(client, "cl_glow_ghost_infected_r 0.35");
			FakeClientCommand(client, "cl_glow_ghost_infected_g 0.35");
			FakeClientCommand(client, "cl_glow_ghost_infected_b 0.35");
				
			FakeClientCommand(client, "cl_glow_item_r 0.0");
			FakeClientCommand(client, "cl_glow_item_b 2.0");
			FakeClientCommand(client, "cl_glow_item_g 0.0");
				
			FakeClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
			FakeClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
			FakeClientCommand(client, "cl_glow_survivor_hurt_r 3.0");	
				
			FakeClientCommand(client, "cl_glow_survivor_vomit_b 0.72");
			FakeClientCommand(client, "cl_glow_survivor_vomit_g 0.7");
			FakeClientCommand(client, "cl_glow_survivor_vomit_r 0.79");
				
			FakeClientCommand(client, "cl_glow_infected_b 1.0");
			FakeClientCommand(client, "cl_glow_infected_g 0.5");
			FakeClientCommand(client, "cl_glow_infected_r 0.0");
		}
		case 3:
		{
			FakeClientCommand(client, "cl_glow_item_far_b %f",  GetConVarFloat(GlowItemFarBlue1));
			FakeClientCommand(client, "cl_glow_item_far_g %f",  GetConVarFloat(GlowItemFarGreen1));
			FakeClientCommand(client, "cl_glow_item_far_r %f",  GetConVarFloat(GlowItemFarRed1));
				
			FakeClientCommand(client, "cl_glow_ghost_infected_b %f",  GetConVarFloat(GlowGhostInfectedBlue1));
			FakeClientCommand(client, "cl_glow_ghost_infected_g %f",  GetConVarFloat(GlowGhostInfectedGreen1));
			FakeClientCommand(client, "cl_glow_ghost_infected_r %f",  GetConVarFloat(GlowGhostInfectedRed1));
				
			FakeClientCommand(client, "cl_glow_item_b %f",  GetConVarFloat(GlowItemBlue1));
			FakeClientCommand(client, "cl_glow_item_g %f",  GetConVarFloat(GlowItemGreen1));
			FakeClientCommand(client, "cl_glow_item_r %f",  GetConVarFloat(GlowItemRed1));
				
			FakeClientCommand(client, "cl_glow_survivor_hurt_b %f",  GetConVarFloat(GlowSurvivorHurtBlue1));		
			FakeClientCommand(client, "cl_glow_survivor_hurt_g %f",  GetConVarFloat(GlowSurvivorHurtGreen1));
			FakeClientCommand(client, "cl_glow_survivor_hurt_r %f",  GetConVarFloat(GlowSurvivorHurtRed1));
				
			FakeClientCommand(client, "cl_glow_survivor_vomit_b %f",  GetConVarFloat(GlowSurvivorVomitBlue1));	
			FakeClientCommand(client, "cl_glow_survivor_vomit_g %f",  GetConVarFloat(GlowSurvivorVomitGreen1));
			FakeClientCommand(client, "cl_glow_survivor_vomit_r %f",  GetConVarFloat(GlowSurvivorVomitRed1));
				
			FakeClientCommand(client, "cl_glow_infected_b %f",  GetConVarFloat(GlowInfectedBlue1));	
			FakeClientCommand(client, "cl_glow_infected_g %f",  GetConVarFloat(GlowInfectedGreen1));
			FakeClientCommand(client, "cl_glow_infected_r %f",  GetConVarFloat(GlowInfectedRed1));
				
			/********************************************************/
			/*****************  			      *******************/
			/********************************************************/
				
			FakeClientCommand(client, "cl_glow_ability_b %f",  GetConVarFloat(GlowAbilityBlue1));
			FakeClientCommand(client, "cl_glow_ability_g %f",  GetConVarFloat(GlowAbilityGreen1));
			FakeClientCommand(client, "cl_glow_ability_r %f",  GetConVarFloat(GlowAbilityRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				FakeClientCommand(client, "cl_glow_ability_colorblind_b %f",  GetConVarFloat(GlowAbilityBlue1));
				FakeClientCommand(client, "cl_glow_ability_colorblind_g %f",  GetConVarFloat(GlowAbilityGreen1));
				FakeClientCommand(client, "cl_glow_ability_colorblind_r %f",  GetConVarFloat(GlowAbilityRed1));
			}
				
			FakeClientCommand(client, "cl_glow_infected_vomit_b %f",  GetConVarFloat(GlowInfectedVomitBlue1));
			FakeClientCommand(client, "cl_glow_infected_vomit_g %f",  GetConVarFloat(GlowInfectedVomitGreen1));
			FakeClientCommand(client, "cl_glow_infected_vomit_r %f",  GetConVarFloat(GlowInfectedVomitRed1));
				
			FakeClientCommand(client, "cl_glow_survivor_health_high_b %f",  GetConVarFloat(GlowSurvivorHealthHighBlue1));
			FakeClientCommand(client, "cl_glow_survivor_health_high_g %f",  GetConVarFloat(GlowSurvivorHealthHighGreen1));
			FakeClientCommand(client, "cl_glow_survivor_health_high_r %f",  GetConVarFloat(GlowSurvivorHealthHighRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				FakeClientCommand(client, "cl_glow_survivor_health_high_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthHighBlue1));
				FakeClientCommand(client, "cl_glow_survivor_health_high_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthHighGreen1));
				FakeClientCommand(client, "cl_glow_survivor_health_high_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthHighRed1));
			}
				
			FakeClientCommand(client, "cl_glow_survivor_health_med_b %f",  GetConVarFloat(GlowSurvivorHealthMedBlue1));
			FakeClientCommand(client, "cl_glow_survivor_health_med_g %f",  GetConVarFloat(GlowSurvivorHealthMedGreen1));
			FakeClientCommand(client, "cl_glow_survivor_health_med_r %f",  GetConVarFloat(GlowSurvivorHealthMedRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				FakeClientCommand(client, "cl_glow_survivor_health_med_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthMedBlue1));
				FakeClientCommand(client, "cl_glow_survivor_health_med_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthMedGreen1));
				FakeClientCommand(client, "cl_glow_survivor_health_med_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthMedRed1));
			}
				
			FakeClientCommand(client, "cl_glow_survivor_health_low_b %f",  GetConVarFloat(GlowSurvivorHealthLowBlue1));
			FakeClientCommand(client, "cl_glow_survivor_health_low_g %f",  GetConVarFloat(GlowSurvivorHealthLowGreen1));
			FakeClientCommand(client, "cl_glow_survivor_health_low_r %f",  GetConVarFloat(GlowSurvivorHealthLowRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				FakeClientCommand(client, "cl_glow_survivor_health_low_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthLowBlue1));
				FakeClientCommand(client, "cl_glow_survivor_health_low_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthLowGreen1));
				FakeClientCommand(client, "cl_glow_survivor_health_low_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthLowRed1));
			}
				
			FakeClientCommand(client, "cl_glow_thirdstrike_item_b %f",  GetConVarFloat(GlowThirdstrikeItemBlue1));
			FakeClientCommand(client, "cl_glow_thirdstrike_item_g %f",  GetConVarFloat(GlowThirdstrikeItemGreen1));
			FakeClientCommand(client, "cl_glow_thirdstrike_item_r %f",  GetConVarFloat(GlowThirdstrikeItemRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				FakeClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b %f",  GetConVarFloat(GlowThirdstrikeItemBlue1));
				FakeClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g %f",  GetConVarFloat(GlowThirdstrikeItemGreen1));
				FakeClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r %f",  GetConVarFloat(GlowThirdstrikeItemRed1));
			}
		}
	}
	return Plugin_Continue;
}
	
public Action Glow2(Handle timer, any client)  
{
	if(!IsClientConnected(client) && !IsClientInGame(client))
	{
		return Plugin_Stop;
	}
		
	switch (glowhook)
	{
		case 1:
		{
			FakeClientCommand(client, "cl_glow_item_far_r 0.0");
				
			FakeClientCommand(client, "cl_glow_ghost_infected_r 0.7");
			FakeClientCommand(client, "cl_glow_ghost_infected_g 0.7");
			FakeClientCommand(client, "cl_glow_ghost_infected_b 0.7");
				
			FakeClientCommand(client, "cl_glow_item_r 0.0");
			FakeClientCommand(client, "cl_glow_item_g 0.0");
				
			FakeClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
		}	
		case 2:
		{
			FakeClientCommand(client, "cl_glow_item_far_r 0.45");
				
			FakeClientCommand(client, "cl_glow_ghost_infected_r 0.7");
			FakeClientCommand(client, "cl_glow_ghost_infected_g 0.7");
			FakeClientCommand(client, "cl_glow_ghost_infected_b 0.7");
				
			FakeClientCommand(client, "cl_glow_item_g 1.0");
			FakeClientCommand(client, "cl_glow_item_r 1.0");
				
			FakeClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
		}
		case 3:
		{
			FakeClientCommand(client, "cl_glow_item_far_b %f",  GetConVarFloat(GlowItemFarBlue2));
			FakeClientCommand(client, "cl_glow_item_far_g %f",  GetConVarFloat(GlowItemFarGreen2));
			FakeClientCommand(client, "cl_glow_item_far_r %f",  GetConVarFloat(GlowItemFarRed2));
				
			FakeClientCommand(client, "cl_glow_ghost_infected_b %f",  GetConVarFloat(GlowGhostInfectedBlue2));
			FakeClientCommand(client, "cl_glow_ghost_infected_g %f",  GetConVarFloat(GlowGhostInfectedGreen2));
			FakeClientCommand(client, "cl_glow_ghost_infected_r %f",  GetConVarFloat(GlowGhostInfectedRed2));
				
			FakeClientCommand(client, "cl_glow_item_b %f",  GetConVarFloat(GlowItemBlue2));
			FakeClientCommand(client, "cl_glow_item_g %f",  GetConVarFloat(GlowItemGreen2));
			FakeClientCommand(client, "cl_glow_item_r %f",  GetConVarFloat(GlowItemRed2));
				
			FakeClientCommand(client, "cl_glow_survivor_hurt_b %f",  GetConVarFloat(GlowSurvivorHurtBlue2));		
			FakeClientCommand(client, "cl_glow_survivor_hurt_g %f",  GetConVarFloat(GlowSurvivorHurtGreen2));
			FakeClientCommand(client, "cl_glow_survivor_hurt_r %f",  GetConVarFloat(GlowSurvivorHurtRed2));
				
			FakeClientCommand(client, "cl_glow_survivor_vomit_b %f",  GetConVarFloat(GlowSurvivorVomitBlue2));	
			FakeClientCommand(client, "cl_glow_survivor_vomit_g %f",  GetConVarFloat(GlowSurvivorVomitGreen2));
			FakeClientCommand(client, "cl_glow_survivor_vomit_r %f",  GetConVarFloat(GlowSurvivorVomitRed2));
				
			FakeClientCommand(client, "cl_glow_infected_b %f",  GetConVarFloat(GlowInfectedBlue2));	
			FakeClientCommand(client, "cl_glow_infected_g %f",  GetConVarFloat(GlowInfectedGreen2));
			FakeClientCommand(client, "cl_glow_infected_r %f",  GetConVarFloat(GlowInfectedRed2));
				
			FakeClientCommand(client, "cl_glow_survivor_b %f",  GetConVarFloat(GlowSurvivorBlue2));	
			FakeClientCommand(client, "cl_glow_survivor_g %f",  GetConVarFloat(GlowSurvivorGreen2));
			FakeClientCommand(client, "cl_glow_survivor_r %f",  GetConVarFloat(GlowSurvivorRed2));
				
			/********************************************************/
			/***************** 					  *******************/
			/********************************************************/
				
			FakeClientCommand(client, "cl_glow_ability_b %f",  GetConVarFloat(GlowAbilityBlue2));
			FakeClientCommand(client, "cl_glow_ability_g %f",  GetConVarFloat(GlowAbilityGreen2));
			FakeClientCommand(client, "cl_glow_ability_r %f",  GetConVarFloat(GlowAbilityRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				FakeClientCommand(client, "cl_glow_ability_colorblind_b %f",  GetConVarFloat(GlowAbilityBlue2));
				FakeClientCommand(client, "cl_glow_ability_colorblind_g %f",  GetConVarFloat(GlowAbilityGreen2));
				FakeClientCommand(client, "cl_glow_ability_colorblind_r %f",  GetConVarFloat(GlowAbilityRed2));
			}
				
			FakeClientCommand(client, "cl_glow_infected_vomit_b %f",  GetConVarFloat(GlowInfectedVomitBlue2));
			FakeClientCommand(client, "cl_glow_infected_vomit_g %f",  GetConVarFloat(GlowInfectedVomitGreen2));
			FakeClientCommand(client, "cl_glow_infected_vomit_r %f",  GetConVarFloat(GlowInfectedVomitRed2));
				
			FakeClientCommand(client, "cl_glow_survivor_health_high_b %f",  GetConVarFloat(GlowSurvivorHealthHighBlue2));
			FakeClientCommand(client, "cl_glow_survivor_health_high_g %f",  GetConVarFloat(GlowSurvivorHealthHighGreen2));
			FakeClientCommand(client, "cl_glow_survivor_health_high_r %f",  GetConVarFloat(GlowSurvivorHealthHighRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				FakeClientCommand(client, "cl_glow_survivor_health_high_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthHighBlue2));
				FakeClientCommand(client, "cl_glow_survivor_health_high_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthHighGreen2));
				FakeClientCommand(client, "cl_glow_survivor_health_high_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthHighRed2));
			}
				
			FakeClientCommand(client, "cl_glow_survivor_health_med_b %f",  GetConVarFloat(GlowSurvivorHealthMedBlue2));
			FakeClientCommand(client, "cl_glow_survivor_health_med_g %f",  GetConVarFloat(GlowSurvivorHealthMedGreen2));
			FakeClientCommand(client, "cl_glow_survivor_health_med_r %f",  GetConVarFloat(GlowSurvivorHealthMedRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				FakeClientCommand(client, "cl_glow_survivor_health_med_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthMedBlue2));
				FakeClientCommand(client, "cl_glow_survivor_health_med_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthMedGreen2));
				FakeClientCommand(client, "cl_glow_survivor_health_med_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthMedRed2));
			}
				
			FakeClientCommand(client, "cl_glow_survivor_health_low_b %f",  GetConVarFloat(GlowSurvivorHealthLowBlue2));
			FakeClientCommand(client, "cl_glow_survivor_health_low_g %f",  GetConVarFloat(GlowSurvivorHealthLowGreen2));
			FakeClientCommand(client, "cl_glow_survivor_health_low_r %f",  GetConVarFloat(GlowSurvivorHealthLowRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				FakeClientCommand(client, "cl_glow_survivor_health_low_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthLowBlue2));
				FakeClientCommand(client, "cl_glow_survivor_health_low_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthLowGreen2));
				FakeClientCommand(client, "cl_glow_survivor_health_low_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthLowRed2));
			}
				
			FakeClientCommand(client, "cl_glow_thirdstrike_item_b %f",  GetConVarFloat(GlowThirdstrikeItemBlue2));
			FakeClientCommand(client, "cl_glow_thirdstrike_item_g %f",  GetConVarFloat(GlowThirdstrikeItemGreen2));
			FakeClientCommand(client, "cl_glow_thirdstrike_item_r %f",  GetConVarFloat(GlowThirdstrikeItemRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				FakeClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b %f",  GetConVarFloat(GlowThirdstrikeItemBlue2));
				FakeClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g %f",  GetConVarFloat(GlowThirdstrikeItemGreen2));
				FakeClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r %f",  GetConVarFloat(GlowThirdstrikeItemRed2));
			}
		}
	}
	return Plugin_Continue;
}
	
public Action TimerStart(int client)
{	
	CreateTimer(1.0, Glow1, client, TIMER_REPEAT);
	CreateTimer(2.0, Glow2, client, TIMER_REPEAT);
}

//Timed Message
public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	CreateTimer(10.0, Timer_Advertise, client);

	return true;
}

public Action Timer_Advertise(Handle timer, any client)
{
	if(IsClientInGame(client))
	PrintToChat(client, "\x01Hard Realism Coop!");	
	else if (IsClientConnected(client))
	CreateTimer(10.0, Timer_Advertise, client);
}

public void ChangeSkyboxTexture()
{
	if(GetConVarBool(cvarEnabled))
	{
		char newskybox[32];
		GetConVarString(cvarSkybox, newskybox, sizeof(newskybox));

		if(strcmp(newskybox, "", false)!=0)
		{
			PrintToServer("[ET] Changing the Skybox to %s", newskybox);
			DispatchKeyValue(WORLDINDEX, "skyname", newskybox);
		}
	}
}

public Action Command_Update(int client, int args)
{
	ChangeFogSettings();
}

public void ChangeFogSettings()
{
	float FogDensity = GetConVarFloat(cvarFogDensity);
	int FogStartDist = GetConVarInt(cvarFogStartDist);
	int FogEndDist = GetConVarInt(cvarFogEndDist);
	int FogZPlane = GetConVarInt(cvarFogZPlane);

	if(FogControllerIndex != -1)
	{
		DispatchKeyValueFloat(FogControllerIndex, "fogmaxdensity", FogDensity);

		SetVariantInt(FogStartDist);
		AcceptEntityInput(FogControllerIndex, "SetStartDist");
		
		SetVariantInt(FogEndDist);
		AcceptEntityInput(FogControllerIndex, "SetEndDist");
		
		SetVariantInt(FogZPlane);
		AcceptEntityInput(FogControllerIndex, "SetFarZ");
	}
}

public void ConvarChange_FogColor(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ChangeFogColors();
}

public void ChangeFogColors()
{
	char FogColor[32];
	GetConVarString(cvarFogColor, FogColor, sizeof(FogColor));

	SetVariantString(FogColor);
	AcceptEntityInput(FogControllerIndex, "SetColor");

	SetVariantString(FogColor);
	AcceptEntityInput(FogControllerIndex, "SetColorSecondary");
}

	//Section below controls player infected glow, not survivors
	/*
	FakeClientCommand(client, "cl_glow_survivor_health_high_r 0");
	FakeClientCommand(client, "cl_glow_survivor_health_high_g 0");
	FakeClientCommand(client, "cl_glow_survivor_health_high_b 0");
	FakeClientCommand(client, "cl_glow_survivor_health_med_r 0");
	FakeClientCommand(client, "cl_glow_survivor_health_med_g 0");
	FakeClientCommand(client, "cl_glow_survivor_health_med_b 0");
	FakeClientCommand(client, "cl_glow_survivor_health_low_r 0");
	FakeClientCommand(client, "cl_glow_survivor_health_low_g 0");
	FakeClientCommand(client, "cl_glow_survivor_health_low_b 0");
	*/