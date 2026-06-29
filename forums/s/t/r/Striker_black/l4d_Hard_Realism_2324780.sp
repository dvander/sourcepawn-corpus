#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.5"
#define WORLDINDEX 0
#undef REQUIRE_PLUGIN

new FogControllerIndex;

new Handle:cvarEnabled;
new Handle:cvarSkybox;

new Handle:WelcomeTimers[MAXPLAYERS+1];
new Handle:cvarFogDensity;
new Handle:cvarFogStartDist;
new Handle:cvarFogEndDist;
new Handle:cvarFogColor;
new Handle:cvarFogZPlane;
new Handle:cvarBrightness;

new Handle:Enable;
new Handle:Modes;

new Handle:MLGlow=INVALID_HANDLE;
new Handle:IgnoringColorblindSet=INVALID_HANDLE;
new glowhook = 1;

new Handle: GlowItemFarRed1=INVALID_HANDLE;
new Handle: GlowItemFarGreen1=INVALID_HANDLE;
new Handle: GlowItemFarBlue1=INVALID_HANDLE;
new Handle: GlowItemFarRed2=INVALID_HANDLE;
new Handle: GlowItemFarGreen2=INVALID_HANDLE;
new Handle: GlowItemFarBlue2=INVALID_HANDLE;
	
new Handle: GlowGhostInfectedRed1=INVALID_HANDLE;
new Handle: GlowGhostInfectedGreen1=INVALID_HANDLE;
new Handle: GlowGhostInfectedBlue1=INVALID_HANDLE;
new Handle: GlowGhostInfectedRed2=INVALID_HANDLE;
new Handle: GlowGhostInfectedGreen2=INVALID_HANDLE;
new Handle: GlowGhostInfectedBlue2=INVALID_HANDLE;
	
new Handle: GlowItemRed1=INVALID_HANDLE;
new Handle: GlowItemGreen1=INVALID_HANDLE;
new Handle: GlowItemBlue1=INVALID_HANDLE;
new Handle: GlowItemRed2=INVALID_HANDLE;
new Handle: GlowItemGreen2=INVALID_HANDLE;
new Handle: GlowItemBlue2=INVALID_HANDLE;
	
new Handle: GlowSurvivorHurtRed1=INVALID_HANDLE;
new Handle: GlowSurvivorHurtGreen1=INVALID_HANDLE;
new Handle: GlowSurvivorHurtBlue1=INVALID_HANDLE;
new Handle: GlowSurvivorHurtRed2=INVALID_HANDLE;
new Handle: GlowSurvivorHurtGreen2=INVALID_HANDLE;
new Handle: GlowSurvivorHurtBlue2=INVALID_HANDLE;
	
new Handle: GlowSurvivorVomitRed1=INVALID_HANDLE;
new Handle: GlowSurvivorVomitGreen1=INVALID_HANDLE;
new Handle: GlowSurvivorVomitBlue1=INVALID_HANDLE;
new Handle: GlowSurvivorVomitRed2=INVALID_HANDLE;
new Handle: GlowSurvivorVomitGreen2=INVALID_HANDLE;
new Handle: GlowSurvivorVomitBlue2=INVALID_HANDLE;
		
new Handle: GlowInfectedRed1=INVALID_HANDLE;
new Handle: GlowInfectedGreen1=INVALID_HANDLE;
new Handle: GlowInfectedBlue1=INVALID_HANDLE;
new Handle: GlowInfectedRed2=INVALID_HANDLE;
new Handle: GlowInfectedGreen2=INVALID_HANDLE;
new Handle: GlowInfectedBlue2=INVALID_HANDLE;
	
new Handle: GlowSurvivorRed2=INVALID_HANDLE;
new Handle: GlowSurvivorGreen2=INVALID_HANDLE;
new Handle: GlowSurvivorBlue2=INVALID_HANDLE;

/********************************************************/
/*****************  	VERSION 1.5   *******************/
/********************************************************/
				
new Handle: GlowAbilityBlue1=INVALID_HANDLE;
new Handle: GlowAbilityGreen1=INVALID_HANDLE;
new Handle: GlowAbilityRed1=INVALID_HANDLE;
new Handle: GlowAbilityBlue2=INVALID_HANDLE;
new Handle: GlowAbilityGreen2=INVALID_HANDLE;
new Handle: GlowAbilityRed2=INVALID_HANDLE;
				
new Handle: GlowInfectedVomitBlue1=INVALID_HANDLE;
new Handle: GlowInfectedVomitGreen1=INVALID_HANDLE;
new Handle: GlowInfectedVomitRed1=INVALID_HANDLE;
new Handle: GlowInfectedVomitBlue2=INVALID_HANDLE;
new Handle: GlowInfectedVomitGreen2=INVALID_HANDLE;
new Handle: GlowInfectedVomitRed2=INVALID_HANDLE;
				
new Handle: GlowSurvivorHealthHighBlue1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthHighGreen1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthHighRed1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthHighBlue2=INVALID_HANDLE;
new Handle: GlowSurvivorHealthHighGreen2=INVALID_HANDLE;
new Handle: GlowSurvivorHealthHighRed2=INVALID_HANDLE;

new Handle: GlowSurvivorHealthMedBlue1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthMedGreen1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthMedRed1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthMedBlue2=INVALID_HANDLE;
new Handle: GlowSurvivorHealthMedGreen2=INVALID_HANDLE;
new Handle: GlowSurvivorHealthMedRed2=INVALID_HANDLE;

new Handle: GlowSurvivorHealthLowBlue1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthLowGreen1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthLowRed1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthLowBlue2=INVALID_HANDLE;
new Handle: GlowSurvivorHealthLowGreen2=INVALID_HANDLE;
new Handle: GlowSurvivorHealthLowRed2=INVALID_HANDLE;

new Handle: GlowThirdstrikeItemBlue1=INVALID_HANDLE;
new Handle: GlowThirdstrikeItemGreen1=INVALID_HANDLE;
new Handle: GlowThirdstrikeItemRed1=INVALID_HANDLE;
new Handle: GlowThirdstrikeItemBlue2=INVALID_HANDLE;
new Handle: GlowThirdstrikeItemGreen2=INVALID_HANDLE;
new Handle: GlowThirdstrikeItemRed2=INVALID_HANDLE;

/********************************************************/
/***************** 		  INFO 		  *******************/
/********************************************************/
public Plugin:myinfo = 
{
	name = "Hard Realism",
	author = "Striker Black and ThrillKill",
	description = "Hard Co-op, Extreme Co-op",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?p=2324780"
}

public OnPluginStart()
{
	CreateConVar("l4d2_hudhider_version", PLUGIN_VERSION, "Version Hud", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	Enable = CreateConVar("l4d_hudhider_enable", "1", "Habilitar Hud?", FCVAR_PLUGIN);
	Modes = CreateConVar("l4d_hudhider_modes", "versus,coop,survival", "Modalidades de Juego", FCVAR_PLUGIN);
	
	CreateConVar("ml_version", PLUGIN_VERSION, "[L4D] Version Glow", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	MLGlow = CreateConVar("ml_glow_mode", "1", "Glow Mode (0 - default, 1 - Q1 glow, 2 - D1 glow, 3 - Resplandor de configuración personalizada)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	IgnoringColorblindSet = CreateConVar("ml_glow_colorblindset_ignoring", "1", "Colores están cambiando, incluso si el cliente está configurado para daltónicos? (0 - No, 1 - Yes)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	CreateConVar("sm_envtools_version", PLUGIN_VERSION, "SM Environmental Tools Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_envtools_enable", "1.0", "Alternar Skybox Cambio en tiempo real", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarSkybox = CreateConVar("sm_envtools_skybox", "docks_hdr", "Alternar Skybox Cambio en tiempo real", FCVAR_PLUGIN);
	//cvarSkybox = CreateConVar("sm_envtools_skybox", "docks_hdr", "Alternar Skybox Cambio en tiempo real", FCVAR_PLUGIN);

	cvarFogDensity = CreateConVar("sm_envtools_fogdensity", "0.6", "Alternar la densidad de los efectos de niebla", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarFogStartDist = CreateConVar("sm_envtools_fogstart", "0", "Alternar ¿A qué distancia se inicia la niebla?", FCVAR_PLUGIN, true, 0.0, true, 8000.0);
	cvarFogEndDist = CreateConVar("sm_envtools_fogend", "500", "Cambiar a qué distancia de la niebla está en su apogeo", FCVAR_PLUGIN, true, 0.0, true, 8000.0);
	cvarFogColor = CreateConVar("sm_envtools_fogcolor", "50 50 50", "Modificar el color de la niebla", FCVAR_PLUGIN);
	cvarFogZPlane = CreateConVar("sm_envtools_zplane", "4000", "Cambie el plano Z recorte", FCVAR_PLUGIN, true, 0.0, true, 8000.0);
	cvarBrightness = CreateConVar("sm_envtools_brightness", "a", "Cambia el brillo del mundo (a-z)", FCVAR_PLUGIN);
	
	RegAdminCmd("sm_envtools_update", Command_Update, ADMFLAG_KICK, "Updates all lighting and fog convar settings");
	
	HookConVarChange(cvarFogColor, ConvarChange_FogColor);

	/********************************************************/
	/*****************        Glow        *******************/
	/********************************************************/
	GlowItemFarRed1 = CreateConVar("ml_glow_item_far_r_one", "0.3", "El color rojo de los artículos en un resplandor distancia (Primer stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemFarGreen1 = CreateConVar("ml_glow_item_far_g_one", "0.4", "El color verde de los artículos en un resplandor distancia (Primer stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemFarBlue1 = CreateConVar("ml_glow_item_far_b_one", "1.0", "El color azul de los artículos en un resplandor distancia (Primer stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemFarRed2 = CreateConVar("ml_glow_item_far_r_two", "0.3", "El color rojo de los artículos en un resplandor distancia (Sefunda stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemFarGreen2 = CreateConVar("ml_glow_item_far_g_two", "0.4", "El color verde de los artículos en un resplandor distancia (Segunda stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemFarBlue2 = CreateConVar("ml_glow_item_far_b_two", "1.0", "El color azul de los artículos en un resplandor distancia (Segunda stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	GlowGhostInfectedRed1 = CreateConVar("ml_glow_ghost_infected_r_one", "0.3", "El color rojo del resplandor fantasma infectada (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowGhostInfectedGreen1 = CreateConVar("ml_glow_ghost_infected_g_one", "0.4", "El color verde del resplandor fantasma infectada (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowGhostInfectedBlue1 = CreateConVar("ml_glow_ghost_infected_b_one", "1.0", "El color azul del resplandor fantasma infectada (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowGhostInfectedRed2 = CreateConVar("ml_glow_ghost_infected_r_two", "0.3", "El color rojo del resplandor fantasma infectada (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowGhostInfectedGreen2 = CreateConVar("ml_glow_ghost_infected_g_two", "0.4", "El color verde del resplandor fantasma infectada (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowGhostInfectedBlue2 = CreateConVar("ml_glow_ghost_infected_b_two", "1.0", "El color azul del resplandor fantasma infectada (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	GlowItemRed1 = CreateConVar("ml_glow_item_r_one", "0.7", "El color rojo de artículos de cerca (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemGreen1 = CreateConVar("ml_glow_item_g_one", "0.7", "El color verde de artículos de cerca glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemBlue1 = CreateConVar("ml_glow_item_b_one", "1.0", "El color azul de artículos de cerca (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemRed2 = CreateConVar("ml_glow_item_r_two", "0.7", "El color rojo de artículos de cerca (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemGreen2 = CreateConVar("ml_glow_item_g_two", "0.7", "El color verde de artículos de cerca (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowItemBlue2 = CreateConVar("ml_glow_item_b_two", "1.0", "El color azul de artículos de cerca (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	GlowSurvivorHurtRed1 = CreateConVar("ml_glow_survivor_hurt_r_one", "1.0", "El color rojo de sobreviviente compañero de equipo resplandor cuando incapacitado (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHurtGreen1 = CreateConVar("ml_glow_survivor_hurt_g_one", "0.4", "El color verde de sobreviviente compañero de equipo resplandor cuando incapacitado (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHurtBlue1 = CreateConVar("ml_glow_survivor_hurt_b_one", "0.0", "El color azul de sobreviviente compañero de equipo resplandor cuando incapacitado (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHurtRed2 = CreateConVar("ml_glow_survivor_hurt_r_two", "1.0", "El color rojo de sobreviviente compañero de equipo resplandor cuando incapacitado (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHurtGreen2 = CreateConVar("ml_glow_survivor_hurt_g_two", "0.4", "El color verde de sobreviviente compañero de equipo resplandor cuando incapacitado (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHurtBlue2 = CreateConVar("ml_glow_survivor_hurt_b_two", "0.0", "El color azul de sobreviviente compañero de equipo resplandor cuando incapacitado (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	GlowSurvivorVomitRed1 = CreateConVar("ml_glow_survivor_vomit_r_one", "1.0", "De color rojo los sobrevivientes ver el resplandor víctima de TI (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorVomitGreen1 = CreateConVar("ml_glow_survivor_vomit_g_one", "0.4", "De verde rojo los sobrevivientes ver el resplandor víctima de TI (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorVomitBlue1 = CreateConVar("ml_glow_survivor_vomit_b_one", "0.0", "De color azul los sobrevivientes ver el resplandor víctima de TI (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorVomitRed2 = CreateConVar("ml_glow_survivor_vomit_r_two", "1.0", "De color rojo los sobrevivientes ver el resplandor víctima de TI (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorVomitGreen2 = CreateConVar("ml_glow_survivor_vomit_g_two", "0.4", "De verde rojo los sobrevivientes ver el resplandor víctima de TI (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorVomitBlue2 = CreateConVar("ml_glow_survivor_vomit_b_two", "0.0", "De color rojo los sobrevivientes ver el resplandor víctima de TI (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
			
	GlowInfectedRed1 = CreateConVar("ml_glow_infected_r_one", "0.3", "El color rojo del resplandor infectada (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedGreen1 = CreateConVar("ml_glow_infected_g_one", "0.4", "El color verde del resplandor infectada (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedBlue1 = CreateConVar("ml_glow_infected_b_one", "1.0", "El color azul del resplandor infectada (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedRed2 = CreateConVar("ml_glow_infected_r_two", "0.3", "Red color of infected glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedGreen2 = CreateConVar("ml_glow_infected_g_two", "0.4", "Green color of infected glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedBlue2 = CreateConVar("ml_glow_infected_b_two", "1.0", "Blue color of infected glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
	/********************************************************/
	/*****************   Version 1.5      *******************/
	/********************************************************/
	GlowAbilityRed1 = CreateConVar("ml_glow_ability_r_one", "1.0", "El color rojo de la capacidad resplandor (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);			
	GlowAbilityGreen1 = CreateConVar("ml_glow_ability_g_one", "0.0", "El color verde de la capacidad resplandor (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowAbilityBlue1 = CreateConVar("ml_glow_ability_b_one", "0.0", "El color azul de la capacidad resplandor (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowAbilityRed2 = CreateConVar("ml_glow_ability_r_two", "1.0", "El color rojo de la capacidad resplandor (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);			
	GlowAbilityGreen2 = CreateConVar("ml_glow_ability_g_two", "0.0", "El color verde de la capacidad resplandor (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowAbilityBlue2 = CreateConVar("ml_glow_ability_b_two", "0.0", "El color azul de la capacidad resplandor (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
	GlowInfectedVomitRed1 = CreateConVar("ml_glow_infected_vomit_r_one", "0.79", "Red los PZs ver el resplandor víctima de TI (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);	
	GlowInfectedVomitGreen1 = CreateConVar("ml_glow_infected_vomit_g_one", "0.07", "Green los PZs ver el resplandor víctima de TI (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedVomitBlue1 = CreateConVar("ml_glow_infected_vomit_b_one", "0.72", "Blue los PZs ver el resplandor víctima de TI (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedVomitRed2 = CreateConVar("ml_glow_infected_vomit_r_two", "0.79", "Red los PZs ver el resplandor víctima de TI (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedVomitGreen2 = CreateConVar("ml_glow_infected_vomit_g_two", "0.07", "Green los PZs ver el resplandor víctima de TI (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowInfectedVomitBlue2 = CreateConVar("ml_glow_infected_vomit_b_two", "0.72", "Blue los PZs ver el resplandor víctima de TI (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	GlowSurvivorHealthHighRed1 = CreateConVar("ml_glow_survivor_health_high_r_one", "0.039", "De color rojo los Infectados ver sobrevivientes cuando su salud es alta (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighGreen1 = CreateConVar("ml_glow_survivor_health_high_g_one", "0.69", "De color verde los Infectados ver sobrevivientes cuando su salud es alta (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighBlue1 = CreateConVar("ml_glow_survivor_health_high_b_one", "0.196", "De color azul los Infectados ver sobrevivientes cuando su salud es alta (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighRed2 = CreateConVar("ml_glow_survivor_health_high_r_two", "0.039", "De color rojo los Infectados ver sobrevivientes cuando su salud es alta (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighGreen2 = CreateConVar("ml_glow_survivor_health_high_g_two", "0.69", "De color verde los Infectados ver sobrevivientes cuando su salud es alta (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighBlue2 = CreateConVar("ml_glow_survivor_health_high_b_two", "0.196", "De color azul los Infectados ver sobrevivientes cuando su salud es alta (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	GlowSurvivorHealthMedRed1 = CreateConVar("ml_glow_survivor_health_med_r_one", "0.59", "De color rojo los Infectados ver sobrevivientes cuando su salud es medio (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedGreen1 = CreateConVar("ml_glow_survivor_health_med_g_one", "0.4", "De color verde los Infectados ver sobrevivientes cuando su salud es medio (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedBlue1 = CreateConVar("ml_glow_survivor_health_med_b_one", "0.032", "De color azul los Infectados ver sobrevivientes cuando su salud es medio (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedRed2 = CreateConVar("ml_glow_survivor_health_med_r_two", "0.59", "De color rojo los Infectados ver sobrevivientes cuando su salud es medio (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedGreen2 = CreateConVar("ml_glow_survivor_health_med_g_two", "0.4", "De color verde los Infectados ver sobrevivientes cuando su salud es medio (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedBlue2 = CreateConVar("ml_glow_survivor_health_med_b_two", "0.032", "De color azul los Infectados ver sobrevivientes cuando su salud es medio (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
	GlowSurvivorHealthLowRed1 = CreateConVar("ml_glow_survivor_health_low_r_one", "0.63", "De color rojo los Infectados ver sobrevivientes cuando su salud es bajo (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowGreen1 = CreateConVar("ml_glow_survivor_health_low_g_one", "0.098", "De color verde los Infectados ver sobrevivientes cuando su salud es bajo (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowBlue1 = CreateConVar("ml_glow_survivor_health_low_b_one", "0.098", "De color azul los Infectados ver sobrevivientes cuando su salud es bajo (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowRed2 = CreateConVar("ml_glow_survivor_health_low_r_two", "0.63", "De color rojo los Infectados ver sobrevivientes cuando su salud es bajo (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowGreen2 = CreateConVar("ml_glow_survivor_health_low_g_two", "0.098", "De color verde los Infectados ver sobrevivientes cuando su salud es bajo (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowBlue2 = CreateConVar("ml_glow_survivor_health_low_b_two", "0.098", "De color azul los Infectados ver sobrevivientes cuando su salud es bajo (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	GlowThirdstrikeItemRed1 = CreateConVar("ml_glow_thirdstrike_item_r_one", "1.0", "El color rojo de sobreviviente compañero resplandor (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowThirdstrikeItemGreen1 = CreateConVar("ml_glow_thirdstrike_item_g_one", "0.0", "El color verde de las partidas en modo blanco y negro (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowThirdstrikeItemBlue1 = CreateConVar("ml_glow_thirdstrike_item_b_one", "0.0", "El color azul de las partidas en modo blanco y negro (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowThirdstrikeItemRed2 = CreateConVar("ml_glow_thirdstrike_item_r_two", "1.0", "El color rojo de sobreviviente compañero resplandor (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowThirdstrikeItemGreen2 = CreateConVar("ml_glow_thirdstrike_item_g_two", "0.0", "El color verde de las partidas en modo blanco y negro (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	GlowThirdstrikeItemBlue2 = CreateConVar("ml_glow_thirdstrike_item_b_two", "0.0", "El color azul de las partidas en modo blanco y negro (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);	
				
	HookConVarChange(MLGlow, CvarChanged);
		
}

stock bool:IsAllowedGameMode()
{
	decl String:gamemode[24], String:gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(Modes, gamemodeactive, sizeof(gamemodeactive));
	return (StrContains(gamemodeactive, gamemode) != -1);
}	

public OnMapStart()
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
		decl String:szLightStyle[6];
		GetConVarString(cvarBrightness, szLightStyle, sizeof(szLightStyle));
		SetLightStyle(0, szLightStyle);
	}
}
public OnClientAuthorized(client)
{
	if(IsAllowedGameMode() && GetConVarInt(Enable) == 1 && !IsFakeClient(client))
	{
		CreateTimer(5.0, Enforce, client, TIMER_REPEAT);
	}	
}

public Action:Enforce(Handle:Timer, any:client)
{
	if(IsClientInGame(client) && GetClientTeam(client) == 2 && GetConVarInt(Enable) == 1 && IsAllowedGameMode() && IsValidEntity(client))
		SetEntProp(client, Prop_Send, "m_iHideHUD", 64);
	if(IsClientInGame(client) && GetClientTeam(client) == 3)
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	if(IsClientInGame(client) && GetClientTeam(client) == 1)
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);	
}
public OnClientPutInServer(client) 
{
	DisableGlows(client);
	WelcomeTimers[client] = CreateTimer(18.0, WelcomePlayer, client);
}

DisableGlows(client) 
{
	ClientCommand(client, "cl_glow_survivor_r 0");
	ClientCommand(client, "cl_glow_survivor_g 0");
	ClientCommand(client, "cl_glow_survivor_b 0");
	ClientCommand(client, "cl_glow_survivor_hurt_r 0");
	ClientCommand(client, "cl_glow_survivor_hurt_g 0");
	ClientCommand(client, "cl_glow_survivor_hurt_b 0");
	ClientCommand(client, "cl_glow_survivor_vomit_r 0");
	ClientCommand(client, "cl_glow_survivor_vomit_g 0");
	ClientCommand(client, "cl_glow_survivor_vomit_b 0");
	ClientCommand(client, "cl_glow_item_r 0");
	ClientCommand(client, "cl_glow_item_b 0");
	ClientCommand(client, "cl_glow_item_g 0");
	ClientCommand(client, "cl_glow_item_far_r 0");
	ClientCommand(client, "cl_glow_item_far_b 0");
	ClientCommand(client, "cl_glow_item_far_g 0");
	ClientCommand(client, "cl_glow_thirdstrike_item_r 0");
	ClientCommand(client, "cl_glow_thirdstrike_item_b 0");
	ClientCommand(client, "cl_glow_thirdstrike_item_g 0");
	ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r 0");
	ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b 0");
	ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g 0");
	ClientCommand(client, "cl_glow_ability_r 0");
	ClientCommand(client, "cl_glow_ability_g 0");
	ClientCommand(client, "cl_glow_ability_b 0");
	ClientCommand(client, "cl_glow_ability_colorblind_r 0");
	ClientCommand(client, "cl_glow_ability_colorblind_g 0");
	ClientCommand(client, "cl_glow_ability_colorblind_b 0");
}

public OnClientDisconnect(client)
{
	if (WelcomeTimers[client] != INVALID_HANDLE)
	{
		KillTimer(WelcomeTimers[client]);
		WelcomeTimers[client] = INVALID_HANDLE;
	}
}

public Action:WelcomePlayer(Handle:timer, any:client)
{
	decl String:name[128];
	GetClientName(client, name, sizeof(name));
	PrintToChat(client, "\x04Welcome, \x03%s!", name);
	PrintToChat(client, "\x01Hard Server \x04- \x01Realism Mod\x04!");
	WelcomeTimers[client] = INVALID_HANDLE;
}

public OnClientPostAdminCheck(client)
{
	if(glowhook != 0)
	{
		if(IsClientConnected(client))
		{
			TimerStart(client);
		}
	}
}
	
public OnConfigExecuted()
{
	glowhook = GetConVarInt(MLGlow);
}
	
public CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	glowhook = GetConVarInt(MLGlow);
	if (glowhook !=0)
	{
		for(new i=1; i<=MaxClients;i++)
		{
			TimerStart(i);
		}
	}
}
	
public Action:Glow1(Handle:timer, any:client)  
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
			ClientCommand(client, "cl_glow_item_far_b 0.50");
			ClientCommand(client, "cl_glow_item_far_g 0.0");
			ClientCommand(client, "cl_glow_item_far_r 0.0");
				
			//El color del resplandor fantasma infectada
			ClientCommand(client, "cl_glow_ghost_infected_b 1.0");
			ClientCommand(client, "cl_glow_ghost_infected_g 0.4");
			ClientCommand(client, "cl_glow_ghost_infected_r 0.3");
				
			//Resplandor de artículos de cerca
			ClientCommand(client, "cl_glow_item_b 2.0");
			ClientCommand(client, "cl_glow_item_g 0.0");
			ClientCommand(client, "cl_glow_item_r 0.0");
				
			//El color de sobreviviente compañero de equipo resplandor cuando incapacitado
			ClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_r 3.0");
				
			//Colorea los sobrevivientes ver el resplandor víctima de TI
			ClientCommand(client, "cl_glow_survivor_vomit_b 0.0");
			ClientCommand(client, "cl_glow_survivor_vomit_g 0.5");
			ClientCommand(client, "cl_glow_survivor_vomit_r 2.0");
				
			//El color de resplandor infectada
			ClientCommand(client, "cl_glow_infected_b 1.0");
			ClientCommand(client, "cl_glow_infected_g 0.4");
			ClientCommand(client, "cl_glow_infected_r 0.3");
								
			/********************************************************/
			/*****************                    *******************/
			/********************************************************/
							
			//Color de la capacidad de brillo
			ClientCommand(client, "cl_glow_ability_b 10.0");
			ClientCommand(client, "cl_glow_ability_g 10.0");
			ClientCommand(client, "cl_glow_ability_r 10.0");
			
			//Color de la capacidad de brillo para las personas con daltónico
			ClientCommand(client, "cl_glow_ability_colorblind_b 1.0");
			ClientCommand(client, "cl_glow_ability_colorblind_g 1.0");
			ClientCommand(client, "cl_glow_ability_colorblind_r 0.3");
				
			//Carolorea el PZs ver el resplandor víctima de TI
			ClientCommand(client, "cl_glow_infected_vomit_b 0.72");
			ClientCommand(client, "cl_glow_infected_vomit_g 0.07");
			ClientCommand(client, "cl_glow_infected_vomit_r 0.79");
				
			//Color los Infectados ver Sobrevivientes cuando su salud es alta
			ClientCommand(client, "cl_glow_survivor_health_high_b 0.196");
			ClientCommand(client, "cl_glow_survivor_health_high_g 0.69");
			ClientCommand(client, "cl_glow_survivor_health_high_r 0.039");
			//Color los Infectados ver Sobrevivientes cuando su salud es alto para las personas con daltónico
			ClientCommand(client, "cl_glow_survivor_health_high_colorblind_b 0.392");
			ClientCommand(client, "cl_glow_survivor_health_high_colorblind_g 0.694");
			ClientCommand(client, "cl_glow_survivor_health_high_colorblind_r 0.047");

			//Color los Infectados ver Sobrevivientes cuando su salud es medio
			ClientCommand(client, "cl_glow_survivor_health_med_b 0.032");
			ClientCommand(client, "cl_glow_survivor_health_med_g 0.4");
			ClientCommand(client, "cl_glow_survivor_health_med_r 0.59");
			//Color los Infectados ver Sobrevivientes cuando su salud es medio para las personas con daltónico
			ClientCommand(client, "cl_glow_survivor_health_med_colorblind_b 0.098");
			ClientCommand(client, "cl_glow_survivor_health_med_colorblind_g 0.573");
			ClientCommand(client, "cl_glow_survivor_health_med_colorblind_r 0.694");

			//Color los Infectados ver Sobrevivientes cuando su salud es bajo
			ClientCommand(client, "cl_glow_survivor_health_low_b 0.098");
			ClientCommand(client, "cl_glow_survivor_health_low_g 0.098");
			ClientCommand(client, "cl_glow_survivor_health_low_r 0.63");
			//Color los Infectados ver Sobrevivientes cuando su salud es baja para las personas con daltónico
			ClientCommand(client, "cl_glow_survivor_health_low_colorblind_b 0.807");
			ClientCommand(client, "cl_glow_survivor_health_low_colorblind_g 0.807");
			ClientCommand(client, "cl_glow_survivor_health_low_colorblind_r 0.047");

			//Resplandor de elementos en el modo de "blanco y negro"
			ClientCommand(client, "cl_glow_thirdstrike_item_b 1.0");
			ClientCommand(client, "cl_glow_thirdstrike_item_g 0.0");
			ClientCommand(client, "cl_glow_thirdstrike_item_r 0.0");
			//Resplandor de elementos en el modo de "blanco y negro" para las personas con daltonismo
			ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b 1.0");
			ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g 1.0");
			ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r 0.3");
				
			return Plugin_Stop;
		}
				
		case 1:
		{
			ClientCommand(client, "cl_glow_item_far_r 0.0");
			ClientCommand(client, "cl_glow_item_far_g 0.0");
			ClientCommand(client, "cl_glow_item_far_b 0.79");
				
			ClientCommand(client, "cl_glow_ghost_infected_r 0.35");
			ClientCommand(client, "cl_glow_ghost_infected_g 0.35");
			ClientCommand(client, "cl_glow_ghost_infected_b 0.35");
				
			ClientCommand(client, "cl_glow_item_r 0.0");
			ClientCommand(client, "cl_glow_item_g 0.0");
			ClientCommand(client, "cl_glow_item_b 2.0");
				
			ClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_r 3.0");
				
			ClientCommand(client, "cl_glow_survivor_vomit_b 0.72");
			ClientCommand(client, "cl_glow_survivor_vomit_g 0.7");
			ClientCommand(client, "cl_glow_survivor_vomit_r 0.79");
				
			ClientCommand(client, "cl_glow_infected_b 1.0");
			ClientCommand(client, "cl_glow_infected_g 0.5");
			ClientCommand(client, "cl_glow_infected_r 0.0");
		}	
				
		case 2:
		{
			ClientCommand(client, "cl_glow_item_far_r 0.0");
			ClientCommand(client, "cl_glow_item_far_b 0.79");
			ClientCommand(client, "cl_glow_item_far_g 0.0");
				
			ClientCommand(client, "cl_glow_ghost_infected_r 0.35");
			ClientCommand(client, "cl_glow_ghost_infected_g 0.35");
			ClientCommand(client, "cl_glow_ghost_infected_b 0.35");
				
			ClientCommand(client, "cl_glow_item_r 0.0");
			ClientCommand(client, "cl_glow_item_b 2.0");
			ClientCommand(client, "cl_glow_item_g 0.0");
				
			ClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_r 3.0");	
				
			ClientCommand(client, "cl_glow_survivor_vomit_b 0.72");
			ClientCommand(client, "cl_glow_survivor_vomit_g 0.7");
			ClientCommand(client, "cl_glow_survivor_vomit_r 0.79");
				
			ClientCommand(client, "cl_glow_infected_b 1.0");
			ClientCommand(client, "cl_glow_infected_g 0.5");
			ClientCommand(client, "cl_glow_infected_r 0.0");
		}
			
		case 3:
		{
			ClientCommand(client, "cl_glow_item_far_b %f",  GetConVarFloat(GlowItemFarBlue1));
			ClientCommand(client, "cl_glow_item_far_g %f",  GetConVarFloat(GlowItemFarGreen1));
			ClientCommand(client, "cl_glow_item_far_r %f",  GetConVarFloat(GlowItemFarRed1));
				
			ClientCommand(client, "cl_glow_ghost_infected_b %f",  GetConVarFloat(GlowGhostInfectedBlue1));
			ClientCommand(client, "cl_glow_ghost_infected_g %f",  GetConVarFloat(GlowGhostInfectedGreen1));
			ClientCommand(client, "cl_glow_ghost_infected_r %f",  GetConVarFloat(GlowGhostInfectedRed1));
				
			ClientCommand(client, "cl_glow_item_b %f",  GetConVarFloat(GlowItemBlue1));
			ClientCommand(client, "cl_glow_item_g %f",  GetConVarFloat(GlowItemGreen1));
			ClientCommand(client, "cl_glow_item_r %f",  GetConVarFloat(GlowItemRed1));
				
			ClientCommand(client, "cl_glow_survivor_hurt_b %f",  GetConVarFloat(GlowSurvivorHurtBlue1));		
			ClientCommand(client, "cl_glow_survivor_hurt_g %f",  GetConVarFloat(GlowSurvivorHurtGreen1));
			ClientCommand(client, "cl_glow_survivor_hurt_r %f",  GetConVarFloat(GlowSurvivorHurtRed1));
				
			ClientCommand(client, "cl_glow_survivor_vomit_b %f",  GetConVarFloat(GlowSurvivorVomitBlue1));	
			ClientCommand(client, "cl_glow_survivor_vomit_g %f",  GetConVarFloat(GlowSurvivorVomitGreen1));
			ClientCommand(client, "cl_glow_survivor_vomit_r %f",  GetConVarFloat(GlowSurvivorVomitRed1));
				
			ClientCommand(client, "cl_glow_infected_b %f",  GetConVarFloat(GlowInfectedBlue1));	
			ClientCommand(client, "cl_glow_infected_g %f",  GetConVarFloat(GlowInfectedGreen1));
			ClientCommand(client, "cl_glow_infected_r %f",  GetConVarFloat(GlowInfectedRed1));
				
			/********************************************************/
			/*****************  			      *******************/
			/********************************************************/
				
			ClientCommand(client, "cl_glow_ability_b %f",  GetConVarFloat(GlowAbilityBlue1));
			ClientCommand(client, "cl_glow_ability_g %f",  GetConVarFloat(GlowAbilityGreen1));
			ClientCommand(client, "cl_glow_ability_r %f",  GetConVarFloat(GlowAbilityRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_ability_colorblind_b %f",  GetConVarFloat(GlowAbilityBlue1));
				ClientCommand(client, "cl_glow_ability_colorblind_g %f",  GetConVarFloat(GlowAbilityGreen1));
				ClientCommand(client, "cl_glow_ability_colorblind_r %f",  GetConVarFloat(GlowAbilityRed1));
			}
				
			ClientCommand(client, "cl_glow_infected_vomit_b %f",  GetConVarFloat(GlowInfectedVomitBlue1));
			ClientCommand(client, "cl_glow_infected_vomit_g %f",  GetConVarFloat(GlowInfectedVomitGreen1));
			ClientCommand(client, "cl_glow_infected_vomit_r %f",  GetConVarFloat(GlowInfectedVomitRed1));
				
			ClientCommand(client, "cl_glow_survivor_health_high_b %f",  GetConVarFloat(GlowSurvivorHealthHighBlue1));
			ClientCommand(client, "cl_glow_survivor_health_high_g %f",  GetConVarFloat(GlowSurvivorHealthHighGreen1));
			ClientCommand(client, "cl_glow_survivor_health_high_r %f",  GetConVarFloat(GlowSurvivorHealthHighRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthHighBlue1));
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthHighGreen1));
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthHighRed1));
			}
				
			ClientCommand(client, "cl_glow_survivor_health_med_b %f",  GetConVarFloat(GlowSurvivorHealthMedBlue1));
			ClientCommand(client, "cl_glow_survivor_health_med_g %f",  GetConVarFloat(GlowSurvivorHealthMedGreen1));
			ClientCommand(client, "cl_glow_survivor_health_med_r %f",  GetConVarFloat(GlowSurvivorHealthMedRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthMedBlue1));
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthMedGreen1));
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthMedRed1));
			}
				
			ClientCommand(client, "cl_glow_survivor_health_low_b %f",  GetConVarFloat(GlowSurvivorHealthLowBlue1));
			ClientCommand(client, "cl_glow_survivor_health_low_g %f",  GetConVarFloat(GlowSurvivorHealthLowGreen1));
			ClientCommand(client, "cl_glow_survivor_health_low_r %f",  GetConVarFloat(GlowSurvivorHealthLowRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthLowBlue1));
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthLowGreen1));
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthLowRed1));
			}
				
			ClientCommand(client, "cl_glow_thirdstrike_item_b %f",  GetConVarFloat(GlowThirdstrikeItemBlue1));
			ClientCommand(client, "cl_glow_thirdstrike_item_g %f",  GetConVarFloat(GlowThirdstrikeItemGreen1));
			ClientCommand(client, "cl_glow_thirdstrike_item_r %f",  GetConVarFloat(GlowThirdstrikeItemRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b %f",  GetConVarFloat(GlowThirdstrikeItemBlue1));
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g %f",  GetConVarFloat(GlowThirdstrikeItemGreen1));
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r %f",  GetConVarFloat(GlowThirdstrikeItemRed1));
			}
		}
	}
	return Plugin_Continue;
}
	
public Action:Glow2(Handle:timer, any:client)  
{
	if(!IsClientConnected(client) && !IsClientInGame(client))
	{
		return Plugin_Stop;
	}
		
	switch (glowhook)
		{
		case 1:
		{
			ClientCommand(client, "cl_glow_item_far_r 0.0");
				
			ClientCommand(client, "cl_glow_ghost_infected_r 0.7");
			ClientCommand(client, "cl_glow_ghost_infected_g 0.7");
			ClientCommand(client, "cl_glow_ghost_infected_b 0.7");
				
			ClientCommand(client, "cl_glow_item_r 0.0");
			ClientCommand(client, "cl_glow_item_g 0.0");
				
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
		}
			
		case 2:
		{
			ClientCommand(client, "cl_glow_item_far_r 0.45");
				
			ClientCommand(client, "cl_glow_ghost_infected_r 0.7");
			ClientCommand(client, "cl_glow_ghost_infected_g 0.7");
			ClientCommand(client, "cl_glow_ghost_infected_b 0.7");
				
			ClientCommand(client, "cl_glow_item_g 1.0");
			ClientCommand(client, "cl_glow_item_r 1.0");
				
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
		}
			
		case 3:
		{
			ClientCommand(client, "cl_glow_item_far_b %f",  GetConVarFloat(GlowItemFarBlue2));
			ClientCommand(client, "cl_glow_item_far_g %f",  GetConVarFloat(GlowItemFarGreen2));
			ClientCommand(client, "cl_glow_item_far_r %f",  GetConVarFloat(GlowItemFarRed2));
				
			ClientCommand(client, "cl_glow_ghost_infected_b %f",  GetConVarFloat(GlowGhostInfectedBlue2));
			ClientCommand(client, "cl_glow_ghost_infected_g %f",  GetConVarFloat(GlowGhostInfectedGreen2));
			ClientCommand(client, "cl_glow_ghost_infected_r %f",  GetConVarFloat(GlowGhostInfectedRed2));
				
			ClientCommand(client, "cl_glow_item_b %f",  GetConVarFloat(GlowItemBlue2));
			ClientCommand(client, "cl_glow_item_g %f",  GetConVarFloat(GlowItemGreen2));
			ClientCommand(client, "cl_glow_item_r %f",  GetConVarFloat(GlowItemRed2));
				
			ClientCommand(client, "cl_glow_survivor_hurt_b %f",  GetConVarFloat(GlowSurvivorHurtBlue2));		
			ClientCommand(client, "cl_glow_survivor_hurt_g %f",  GetConVarFloat(GlowSurvivorHurtGreen2));
			ClientCommand(client, "cl_glow_survivor_hurt_r %f",  GetConVarFloat(GlowSurvivorHurtRed2));
				
			ClientCommand(client, "cl_glow_survivor_vomit_b %f",  GetConVarFloat(GlowSurvivorVomitBlue2));	
			ClientCommand(client, "cl_glow_survivor_vomit_g %f",  GetConVarFloat(GlowSurvivorVomitGreen2));
			ClientCommand(client, "cl_glow_survivor_vomit_r %f",  GetConVarFloat(GlowSurvivorVomitRed2));
				
			ClientCommand(client, "cl_glow_infected_b %f",  GetConVarFloat(GlowInfectedBlue2));	
			ClientCommand(client, "cl_glow_infected_g %f",  GetConVarFloat(GlowInfectedGreen2));
			ClientCommand(client, "cl_glow_infected_r %f",  GetConVarFloat(GlowInfectedRed2));
				
			ClientCommand(client, "cl_glow_survivor_b %f",  GetConVarFloat(GlowSurvivorBlue2));	
			ClientCommand(client, "cl_glow_survivor_g %f",  GetConVarFloat(GlowSurvivorGreen2));
			ClientCommand(client, "cl_glow_survivor_r %f",  GetConVarFloat(GlowSurvivorRed2));
				
			/********************************************************/
			/***************** 					  *******************/
			/********************************************************/
				
			ClientCommand(client, "cl_glow_ability_b %f",  GetConVarFloat(GlowAbilityBlue2));
			ClientCommand(client, "cl_glow_ability_g %f",  GetConVarFloat(GlowAbilityGreen2));
			ClientCommand(client, "cl_glow_ability_r %f",  GetConVarFloat(GlowAbilityRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_ability_colorblind_b %f",  GetConVarFloat(GlowAbilityBlue2));
				ClientCommand(client, "cl_glow_ability_colorblind_g %f",  GetConVarFloat(GlowAbilityGreen2));
				ClientCommand(client, "cl_glow_ability_colorblind_r %f",  GetConVarFloat(GlowAbilityRed2));
			}
				
			ClientCommand(client, "cl_glow_infected_vomit_b %f",  GetConVarFloat(GlowInfectedVomitBlue2));
			ClientCommand(client, "cl_glow_infected_vomit_g %f",  GetConVarFloat(GlowInfectedVomitGreen2));
			ClientCommand(client, "cl_glow_infected_vomit_r %f",  GetConVarFloat(GlowInfectedVomitRed2));
				
			ClientCommand(client, "cl_glow_survivor_health_high_b %f",  GetConVarFloat(GlowSurvivorHealthHighBlue2));
			ClientCommand(client, "cl_glow_survivor_health_high_g %f",  GetConVarFloat(GlowSurvivorHealthHighGreen2));
			ClientCommand(client, "cl_glow_survivor_health_high_r %f",  GetConVarFloat(GlowSurvivorHealthHighRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthHighBlue2));
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthHighGreen2));
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthHighRed2));
			}
				
			ClientCommand(client, "cl_glow_survivor_health_med_b %f",  GetConVarFloat(GlowSurvivorHealthMedBlue2));
			ClientCommand(client, "cl_glow_survivor_health_med_g %f",  GetConVarFloat(GlowSurvivorHealthMedGreen2));
			ClientCommand(client, "cl_glow_survivor_health_med_r %f",  GetConVarFloat(GlowSurvivorHealthMedRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthMedBlue2));
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthMedGreen2));
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthMedRed2));
			}
				
			ClientCommand(client, "cl_glow_survivor_health_low_b %f",  GetConVarFloat(GlowSurvivorHealthLowBlue2));
			ClientCommand(client, "cl_glow_survivor_health_low_g %f",  GetConVarFloat(GlowSurvivorHealthLowGreen2));
			ClientCommand(client, "cl_glow_survivor_health_low_r %f",  GetConVarFloat(GlowSurvivorHealthLowRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthLowBlue2));
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthLowGreen2));
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthLowRed2));
			}
				
			ClientCommand(client, "cl_glow_thirdstrike_item_b %f",  GetConVarFloat(GlowThirdstrikeItemBlue2));
			ClientCommand(client, "cl_glow_thirdstrike_item_g %f",  GetConVarFloat(GlowThirdstrikeItemGreen2));
			ClientCommand(client, "cl_glow_thirdstrike_item_r %f",  GetConVarFloat(GlowThirdstrikeItemRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b %f",  GetConVarFloat(GlowThirdstrikeItemBlue2));
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g %f",  GetConVarFloat(GlowThirdstrikeItemGreen2));
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r %f",  GetConVarFloat(GlowThirdstrikeItemRed2));
			}
		}
	}
	return Plugin_Continue;
}
	
public Action:TimerStart(client)
{	
	CreateTimer(1.0, Glow1, client, TIMER_REPEAT);
	CreateTimer(2.0, Glow2, client, TIMER_REPEAT);
}

//Timed Message
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)

{
	CreateTimer(10.0, Timer_Advertise, client);

	return true;
}

public Action:Timer_Advertise(Handle:timer, any:client)

{
	if(IsClientInGame(client))
	PrintToChat(client, "\x01Hard Realism Coop!");	
	else if (IsClientConnected(client))
	CreateTimer(10.0, Timer_Advertise, client);
}

public ChangeSkyboxTexture()
{
	if(GetConVarBool(cvarEnabled))
	{
		decl String:newskybox[32];
		GetConVarString(cvarSkybox, newskybox, sizeof(newskybox));

		if(strcmp(newskybox, "", false)!=0)
		{
			PrintToServer("[ET] Changing the Skybox to %s", newskybox);
			DispatchKeyValue(WORLDINDEX, "skyname", newskybox);
		}
	}
}

public Action:Command_Update(client, args)
{
	ChangeFogSettings();
}

public ChangeFogSettings()
{
	new Float:FogDensity = GetConVarFloat(cvarFogDensity);
	new FogStartDist = GetConVarInt(cvarFogStartDist);
	new FogEndDist = GetConVarInt(cvarFogEndDist);
	new FogZPlane = GetConVarInt(cvarFogZPlane);

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

public ConvarChange_FogColor(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ChangeFogColors();
}

public ChangeFogColors()
{
	decl String:FogColor[32];
	GetConVarString(cvarFogColor, FogColor, sizeof(FogColor));

	SetVariantString(FogColor);
	AcceptEntityInput(FogControllerIndex, "SetColor");

	SetVariantString(FogColor);
	AcceptEntityInput(FogControllerIndex, "SetColorSecondary");
}

	//Section below controls player infected glow, not survivors
	/*
	ClientCommand(client, "cl_glow_survivor_health_high_r 0");
	ClientCommand(client, "cl_glow_survivor_health_high_g 0");
	ClientCommand(client, "cl_glow_survivor_health_high_b 0");
	ClientCommand(client, "cl_glow_survivor_health_med_r 0");
	ClientCommand(client, "cl_glow_survivor_health_med_g 0");
	ClientCommand(client, "cl_glow_survivor_health_med_b 0");
	ClientCommand(client, "cl_glow_survivor_health_low_r 0");
	ClientCommand(client, "cl_glow_survivor_health_low_g 0");
	ClientCommand(client, "cl_glow_survivor_health_low_b 0");
	*/