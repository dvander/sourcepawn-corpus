#include <sourcemod>
#include <sdktools>

new FogControllerIndex;
new Handle:cvarEnabled;
new Handle:cvarSkybox;
new Handle:WelcomeTimers[65];
new Handle:cvarFogDensity;
new Handle:cvarFogStartDist;
new Handle:cvarFogEndDist;
new Handle:cvarFogColor;
new Handle:cvarFogZPlane;
new Handle:cvarBrightness;
new Handle:Enable;
new Handle:Modes;
new Handle:MLGlow;
new Handle:IgnoringColorblindSet;
new glowhook = 1;
new Handle:GlowItemFarRed1;
new Handle:GlowItemFarGreen1;
new Handle:GlowItemFarBlue1;
new Handle:GlowItemFarRed2;
new Handle:GlowItemFarGreen2;
new Handle:GlowItemFarBlue2;
new Handle:GlowGhostInfectedRed1;
new Handle:GlowGhostInfectedGreen1;
new Handle:GlowGhostInfectedBlue1;
new Handle:GlowGhostInfectedRed2;
new Handle:GlowGhostInfectedGreen2;
new Handle:GlowGhostInfectedBlue2;
new Handle:GlowItemRed1;
new Handle:GlowItemGreen1;
new Handle:GlowItemBlue1;
new Handle:GlowItemRed2;
new Handle:GlowItemGreen2;
new Handle:GlowItemBlue2;
new Handle:GlowSurvivorHurtRed1;
new Handle:GlowSurvivorHurtGreen1;
new Handle:GlowSurvivorHurtBlue1;
new Handle:GlowSurvivorHurtRed2;
new Handle:GlowSurvivorHurtGreen2;
new Handle:GlowSurvivorHurtBlue2;
new Handle:GlowSurvivorVomitRed1;
new Handle:GlowSurvivorVomitGreen1;
new Handle:GlowSurvivorVomitBlue1;
new Handle:GlowSurvivorVomitRed2;
new Handle:GlowSurvivorVomitGreen2;
new Handle:GlowSurvivorVomitBlue2;
new Handle:GlowInfectedRed1;
new Handle:GlowInfectedGreen1;
new Handle:GlowInfectedBlue1;
new Handle:GlowInfectedRed2;
new Handle:GlowInfectedGreen2;
new Handle:GlowInfectedBlue2;
new Handle:GlowSurvivorRed2;
new Handle:GlowSurvivorGreen2;
new Handle:GlowSurvivorBlue2;
new Handle:GlowAbilityBlue1;
new Handle:GlowAbilityGreen1;
new Handle:GlowAbilityRed1;
new Handle:GlowAbilityBlue2;
new Handle:GlowAbilityGreen2;
new Handle:GlowAbilityRed2;
new Handle:GlowInfectedVomitBlue1;
new Handle:GlowInfectedVomitGreen1;
new Handle:GlowInfectedVomitRed1;
new Handle:GlowInfectedVomitBlue2;
new Handle:GlowInfectedVomitGreen2;
new Handle:GlowInfectedVomitRed2;
new Handle:GlowSurvivorHealthHighBlue1;
new Handle:GlowSurvivorHealthHighGreen1;
new Handle:GlowSurvivorHealthHighRed1;
new Handle:GlowSurvivorHealthHighBlue2;
new Handle:GlowSurvivorHealthHighGreen2;
new Handle:GlowSurvivorHealthHighRed2;
new Handle:GlowSurvivorHealthMedBlue1;
new Handle:GlowSurvivorHealthMedGreen1;
new Handle:GlowSurvivorHealthMedRed1;
new Handle:GlowSurvivorHealthMedBlue2;
new Handle:GlowSurvivorHealthMedGreen2;
new Handle:GlowSurvivorHealthMedRed2;
new Handle:GlowSurvivorHealthLowBlue1;
new Handle:GlowSurvivorHealthLowGreen1;
new Handle:GlowSurvivorHealthLowRed1;
new Handle:GlowSurvivorHealthLowBlue2;
new Handle:GlowSurvivorHealthLowGreen2;
new Handle:GlowSurvivorHealthLowRed2;
new Handle:GlowThirdstrikeItemBlue1;
new Handle:GlowThirdstrikeItemGreen1;
new Handle:GlowThirdstrikeItemRed1;
new Handle:GlowThirdstrikeItemBlue2;
new Handle:GlowThirdstrikeItemGreen2;
new Handle:GlowThirdstrikeItemRed2;

public OnPluginStart()
{
	CreateConVar("l4d2_hudhider_version", "1.0.0", "Version Hud", 401664, false, 0.0, false, 0.0);
	Enable = CreateConVar("l4d_hudhider_enable", "1", "Habilitar Hud?", 262144, false, 0.0, false, 0.0);
	Modes = CreateConVar("l4d_hudhider_modes", "versus,coop,survival", "Modalidades de Juego", 262144, false, 0.0, false, 0.0);
	CreateConVar("ml_version", "1.0.0", "[L4D] Version Glow", 401728, false, 0.0, false, 0.0);
	MLGlow = CreateConVar("ml_glow_mode", "1", "Glow Mode (0 - default, 1 - Q1 glow, 2 - D1 glow, 3 - Resplandor de configuracion personalizada)", 262400, true, 0.0, true, 3.0);
	IgnoringColorblindSet = CreateConVar("ml_glow_colorblindset_ignoring", "1", "Colores estan cambiando, incluso si el cliente esta configurado para daltonicos? (0 - No, 1 - Yes)", 262400, true, 0.0, true, 1.0);
	CreateConVar("sm_envtools_version", "1.0.0", "SM Environmental Tools Version", 270656, false, 0.0, false, 0.0);
	cvarEnabled = CreateConVar("sm_envtools_enable", "1.0", "Alternar Skybox Cambio en tiempo real", 262144, true, 0.0, true, 1.0);
	cvarSkybox = CreateConVar("sm_envtools_skybox", "sky_day01_09_hdr", "Alternar Skybox Cambio en tiempo real", 262144, false, 0.0, false, 0.0);
	cvarFogDensity = CreateConVar("sm_envtools_fogdensity", "0.6", "Alternar la densidad de los efectos de niebla", 262144, true, 0.0, true, 1.0);
	cvarFogStartDist = CreateConVar("sm_envtools_fogstart", "0", "Alternar A que distancia se inicia la niebla?", 262144, true, 0.0, true, 8000.0);
	cvarFogEndDist = CreateConVar("sm_envtools_fogend", "500", "Cambiar a que distancia de la niebla esta en su apogeo", 262144, true, 0.0, true, 8000.0);
	cvarFogColor = CreateConVar("sm_envtools_fogcolor", "50 50 50", "Modificar el color de la niebla", 262144, false, 0.0, false, 0.0);
	cvarFogZPlane = CreateConVar("sm_envtools_zplane", "4000", "Cambie el plano Z recorte", 262144, true, 0.0, true, 8000.0);
	cvarBrightness = CreateConVar("sm_envtools_brightness", "a", "Cambia el brillo del mundo (a-z)", 262144, false, 0.0, false, 0.0);
	RegAdminCmd("sm_envtools_update", Command_Update, 4, "Updates all lighting and fog convar settings", "", 0);
	HookConVarChange(cvarFogColor, ConvarChange_FogColor);
	GlowItemFarRed1 = CreateConVar("ml_glow_item_far_r_one", "0.3", "El color rojo de los articulos en un resplandor distancia (Primer stage)", 262400, true, 0.0, true, 1.0);
	GlowItemFarGreen1 = CreateConVar("ml_glow_item_far_g_one", "0.4", "El color verde de los articulos en un resplandor distancia (Primer stage)", 262400, true, 0.0, true, 1.0);
	GlowItemFarBlue1 = CreateConVar("ml_glow_item_far_b_one", "1.0", "El color azul de los articulos en un resplandor distancia (Primer stage)", 262400, true, 0.0, true, 1.0);
	GlowItemFarRed2 = CreateConVar("ml_glow_item_far_r_two", "0.3", "El color rojo de los articulos en un resplandor distancia (Sefunda stage)", 262400, true, 0.0, true, 1.0);
	GlowItemFarGreen2 = CreateConVar("ml_glow_item_far_g_two", "0.4", "El color verde de los articulos en un resplandor distancia (Segunda stage)", 262400, true, 0.0, true, 1.0);
	GlowItemFarBlue2 = CreateConVar("ml_glow_item_far_b_two", "1.0", "El color azul de los articulos en un resplandor distancia (Segunda stage)", 262400, true, 0.0, true, 1.0);
	GlowGhostInfectedRed1 = CreateConVar("ml_glow_ghost_infected_r_one", "0.3", "El color rojo del resplandor fantasma infectada (First stage)", 262400, true, 0.0, true, 1.0);
	GlowGhostInfectedGreen1 = CreateConVar("ml_glow_ghost_infected_g_one", "0.4", "El color verde del resplandor fantasma infectada (First stage)", 262400, true, 0.0, true, 1.0);
	GlowGhostInfectedBlue1 = CreateConVar("ml_glow_ghost_infected_b_one", "1.0", "El color azul del resplandor fantasma infectada (First stage)", 262400, true, 0.0, true, 1.0);
	GlowGhostInfectedRed2 = CreateConVar("ml_glow_ghost_infected_r_two", "0.3", "El color rojo del resplandor fantasma infectada (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowGhostInfectedGreen2 = CreateConVar("ml_glow_ghost_infected_g_two", "0.4", "El color verde del resplandor fantasma infectada (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowGhostInfectedBlue2 = CreateConVar("ml_glow_ghost_infected_b_two", "1.0", "El color azul del resplandor fantasma infectada (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowItemRed1 = CreateConVar("ml_glow_item_r_one", "0.7", "El color rojo de articulos de cerca (First stage)", 262400, true, 0.0, true, 1.0);
	GlowItemGreen1 = CreateConVar("ml_glow_item_g_one", "0.7", "El color verde de articulos de cerca glow (First stage)", 262400, true, 0.0, true, 1.0);
	GlowItemBlue1 = CreateConVar("ml_glow_item_b_one", "1.0", "El color azul de articulos de cerca (First stage)", 262400, true, 0.0, true, 1.0);
	GlowItemRed2 = CreateConVar("ml_glow_item_r_two", "0.7", "El color rojo de articulos de cerca (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowItemGreen2 = CreateConVar("ml_glow_item_g_two", "0.7", "El color verde de articulos de cerca (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowItemBlue2 = CreateConVar("ml_glow_item_b_two", "1.0", "El color azul de articulos de cerca (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHurtRed1 = CreateConVar("ml_glow_survivor_hurt_r_one", "1.0", "El color rojo de sobreviviente companero de equipo resplandor cuando incapacitado (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHurtGreen1 = CreateConVar("ml_glow_survivor_hurt_g_one", "0.4", "El color verde de sobreviviente companero de equipo resplandor cuando incapacitado (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHurtBlue1 = CreateConVar("ml_glow_survivor_hurt_b_one", "0.0", "El color azul de sobreviviente companero de equipo resplandor cuando incapacitado (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHurtRed2 = CreateConVar("ml_glow_survivor_hurt_r_two", "1.0", "El color rojo de sobreviviente companero de equipo resplandor cuando incapacitado (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHurtGreen2 = CreateConVar("ml_glow_survivor_hurt_g_two", "0.4", "El color verde de sobreviviente companero de equipo resplandor cuando incapacitado (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHurtBlue2 = CreateConVar("ml_glow_survivor_hurt_b_two", "0.0", "El color azul de sobreviviente companero de equipo resplandor cuando incapacitado (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorVomitRed1 = CreateConVar("ml_glow_survivor_vomit_r_one", "1.0", "De color rojo los sobrevivientes ver el resplandor victima de TI (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorVomitGreen1 = CreateConVar("ml_glow_survivor_vomit_g_one", "0.4", "De verde rojo los sobrevivientes ver el resplandor victima de TI (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorVomitBlue1 = CreateConVar("ml_glow_survivor_vomit_b_one", "0.0", "De color azul los sobrevivientes ver el resplandor victima de TI (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorVomitRed2 = CreateConVar("ml_glow_survivor_vomit_r_two", "1.0", "De color rojo los sobrevivientes ver el resplandor victima de TI (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorVomitGreen2 = CreateConVar("ml_glow_survivor_vomit_g_two", "0.4", "De verde rojo los sobrevivientes ver el resplandor victima de TI (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorVomitBlue2 = CreateConVar("ml_glow_survivor_vomit_b_two", "0.0", "De color rojo los sobrevivientes ver el resplandor victima de TI (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowInfectedRed1 = CreateConVar("ml_glow_infected_r_one", "0.3", "El color rojo del resplandor infectada (First stage)", 262400, true, 0.0, true, 1.0);
	GlowInfectedGreen1 = CreateConVar("ml_glow_infected_g_one", "0.4", "El color verde del resplandor infectada (First stage)", 262400, true, 0.0, true, 1.0);
	GlowInfectedBlue1 = CreateConVar("ml_glow_infected_b_one", "1.0", "El color azul del resplandor infectada (First stage)", 262400, true, 0.0, true, 1.0);
	GlowInfectedRed2 = CreateConVar("ml_glow_infected_r_two", "0.3", "Red color of infected glow (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowInfectedGreen2 = CreateConVar("ml_glow_infected_g_two", "0.4", "Green color of infected glow (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowInfectedBlue2 = CreateConVar("ml_glow_infected_b_two", "1.0", "Blue color of infected glow (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowAbilityRed1 = CreateConVar("ml_glow_ability_r_one", "1.0", "El color rojo de la capacidad resplandor (First stage)", 262400, true, 0.0, true, 1.0);
	GlowAbilityGreen1 = CreateConVar("ml_glow_ability_g_one", "0.0", "El color verde de la capacidad resplandor (First stage)", 262400, true, 0.0, true, 1.0);
	GlowAbilityBlue1 = CreateConVar("ml_glow_ability_b_one", "0.0", "El color azul de la capacidad resplandor (First stage)", 262400, true, 0.0, true, 1.0);
	GlowAbilityRed2 = CreateConVar("ml_glow_ability_r_two", "1.0", "El color rojo de la capacidad resplandor (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowAbilityGreen2 = CreateConVar("ml_glow_ability_g_two", "0.0", "El color verde de la capacidad resplandor (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowAbilityBlue2 = CreateConVar("ml_glow_ability_b_two", "0.0", "El color azul de la capacidad resplandor (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowInfectedVomitRed1 = CreateConVar("ml_glow_infected_vomit_r_one", "0.79", "Red los PZs ver el resplandor victima de TI (First stage)", 262400, true, 0.0, true, 1.0);
	GlowInfectedVomitGreen1 = CreateConVar("ml_glow_infected_vomit_g_one", "0.07", "Green los PZs ver el resplandor victima de TI (First stage)", 262400, true, 0.0, true, 1.0);
	GlowInfectedVomitBlue1 = CreateConVar("ml_glow_infected_vomit_b_one", "0.72", "Blue los PZs ver el resplandor victima de TI (First stage)", 262400, true, 0.0, true, 1.0);
	GlowInfectedVomitRed2 = CreateConVar("ml_glow_infected_vomit_r_two", "0.79", "Red los PZs ver el resplandor victima de TI (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowInfectedVomitGreen2 = CreateConVar("ml_glow_infected_vomit_g_two", "0.07", "Green los PZs ver el resplandor victima de TI (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowInfectedVomitBlue2 = CreateConVar("ml_glow_infected_vomit_b_two", "0.72", "Blue los PZs ver el resplandor victima de TI (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighRed1 = CreateConVar("ml_glow_survivor_health_high_r_one", "0.039", "De color rojo los Infectados ver sobrevivientes cuando su salud es alta (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighGreen1 = CreateConVar("ml_glow_survivor_health_high_g_one", "0.69", "De color verde los Infectados ver sobrevivientes cuando su salud es alta (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighBlue1 = CreateConVar("ml_glow_survivor_health_high_b_one", "0.196", "De color azul los Infectados ver sobrevivientes cuando su salud es alta (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighRed2 = CreateConVar("ml_glow_survivor_health_high_r_two", "0.039", "De color rojo los Infectados ver sobrevivientes cuando su salud es alta (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighGreen2 = CreateConVar("ml_glow_survivor_health_high_g_two", "0.69", "De color verde los Infectados ver sobrevivientes cuando su salud es alta (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthHighBlue2 = CreateConVar("ml_glow_survivor_health_high_b_two", "0.196", "De color azul los Infectados ver sobrevivientes cuando su salud es alta (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedRed1 = CreateConVar("ml_glow_survivor_health_med_r_one", "0.59", "De color rojo los Infectados ver sobrevivientes cuando su salud es medio (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedGreen1 = CreateConVar("ml_glow_survivor_health_med_g_one", "0.4", "De color verde los Infectados ver sobrevivientes cuando su salud es medio (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedBlue1 = CreateConVar("ml_glow_survivor_health_med_b_one", "0.032", "De color azul los Infectados ver sobrevivientes cuando su salud es medio (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedRed2 = CreateConVar("ml_glow_survivor_health_med_r_two", "0.59", "De color rojo los Infectados ver sobrevivientes cuando su salud es medio (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedGreen2 = CreateConVar("ml_glow_survivor_health_med_g_two", "0.4", "De color verde los Infectados ver sobrevivientes cuando su salud es medio (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthMedBlue2 = CreateConVar("ml_glow_survivor_health_med_b_two", "0.032", "De color azul los Infectados ver sobrevivientes cuando su salud es medio (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowRed1 = CreateConVar("ml_glow_survivor_health_low_r_one", "0.63", "De color rojo los Infectados ver sobrevivientes cuando su salud es bajo (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowGreen1 = CreateConVar("ml_glow_survivor_health_low_g_one", "0.098", "De color verde los Infectados ver sobrevivientes cuando su salud es bajo (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowBlue1 = CreateConVar("ml_glow_survivor_health_low_b_one", "0.098", "De color azul los Infectados ver sobrevivientes cuando su salud es bajo (First stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowRed2 = CreateConVar("ml_glow_survivor_health_low_r_two", "0.63", "De color rojo los Infectados ver sobrevivientes cuando su salud es bajo (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowGreen2 = CreateConVar("ml_glow_survivor_health_low_g_two", "0.098", "De color verde los Infectados ver sobrevivientes cuando su salud es bajo (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowSurvivorHealthLowBlue2 = CreateConVar("ml_glow_survivor_health_low_b_two", "0.098", "De color azul los Infectados ver sobrevivientes cuando su salud es bajo (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowThirdstrikeItemRed1 = CreateConVar("ml_glow_thirdstrike_item_r_one", "1.0", "El color rojo de sobreviviente companero resplandor (First stage)", 262400, true, 0.0, true, 1.0);
	GlowThirdstrikeItemGreen1 = CreateConVar("ml_glow_thirdstrike_item_g_one", "0.0", "El color verde de las partidas en modo blanco y negro (First stage)", 262400, true, 0.0, true, 1.0);
	GlowThirdstrikeItemBlue1 = CreateConVar("ml_glow_thirdstrike_item_b_one", "0.0", "El color azul de las partidas en modo blanco y negro (First stage)", 262400, true, 0.0, true, 1.0);
	GlowThirdstrikeItemRed2 = CreateConVar("ml_glow_thirdstrike_item_r_two", "1.0", "El color rojo de sobreviviente companero resplandor (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowThirdstrikeItemGreen2 = CreateConVar("ml_glow_thirdstrike_item_g_two", "0.0", "El color verde de las partidas en modo blanco y negro (Second stage)", 262400, true, 0.0, true, 1.0);
	GlowThirdstrikeItemBlue2 = CreateConVar("ml_glow_thirdstrike_item_b_two", "0.0", "El color azul de las partidas en modo blanco y negro (Second stage)", 262400, true, 0.0, true, 1.0);
	HookConVarChange(MLGlow, CvarChanged);
	AutoExecConfig(true, "realista_striker");
}

bool IsAllowedGameMode()
{
	decl String:gamemode[24];
	decl String:gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, 24);
	GetConVarString(Modes, gamemodeactive, 64);
	return StrContains(gamemodeactive, gamemode, true) != -1;
}
public void OnMapStart()
{
	decl String:name[64];
	new Handle:hostname = FindConVar("hostname");
	GetConVarString(hostname, name, 64);

	FogControllerIndex = FindEntityByClassname(-1, "env_fog_controller");
	if (FogControllerIndex == -1)
	{
		PrintToServer("[ET] No Fog Controller Exists. This Entity is either unsupported by this Game, or this Level Does not Include it.");
	}
	if (GetConVarBool(cvarEnabled))
	{
		ChangeSkyboxTexture();
		ChangeFogSettings();
		ChangeFogColors();
		decl String:szLightStyle[8];
		GetConVarString(cvarBrightness, szLightStyle, 6);
		SetLightStyle(0, szLightStyle);
	}
}

public void OnClientAuthorized(client)
{
	if (IsAllowedGameMode() && GetConVarInt(Enable) == 1 && !IsFakeClient(client))
	{
		CreateTimer(5.0, Enforce, client, 1);
	}
}

public Action Enforce(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && GetConVarInt(Enable) == 1 && IsAllowedGameMode() && IsValidEntity(client))
	{
		SetEntProp(client, PropType:0, "m_iHideHUD", any:64, 4);
	}
	if (IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		SetEntProp(client, PropType:0, "m_iHideHUD", any:0, 4);
	}
	if (IsClientInGame(client) && GetClientTeam(client) == 1)
	{
		SetEntProp(client, PropType:0, "m_iHideHUD", any:0, 4);
	}
}

public void OnClientPutInServer(client)
{
	DisableGlows(client);
	WelcomeTimers[client] = CreateTimer(18.0, WelcomePlayer, client, 0);
}


void DisableGlows(client)
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

public void OnClientDisconnect(client)
{
	if (WelcomeTimers[client])
	{
		KillTimer(WelcomeTimers[client], false);
		WelcomeTimers[client] = null;
	}
}

public Action WelcomePlayer(Handle:timer, any:client)
{
	WelcomeTimers[client] = null;
	
	decl String:name[128];
	GetClientName(client, name, 128);
	PrintToChat(client, "\x04Welcome, \x03%s!", name);
	PrintToChat(client, "\x01Hard Server \x04- \x01Realism Mod\x04!");
	PrintToChat(client, "\x01Visita \x04legacy-server.com \x01para mas informacion.");
}

public void OnClientPostAdminCheck(client)
{
	if (glowhook)
	{
		if (IsClientConnected(client))
		{
			TimerStart(client);
		}
	}
}

public void OnConfigExecuted()
{
	glowhook = GetConVarInt(MLGlow);
}

public void CvarChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	glowhook = GetConVarInt(MLGlow);
	if (glowhook)
	{
		new i = 1;
		while (i <= MaxClients)
		{
			TimerStart(i);
			i++;
		}
	}
}

public Action Glow1(Handle:timer, any:client)
{
	if (!IsClientConnected(client) && !IsClientInGame(client))
	{
		return Action:4;
	}
	switch (glowhook)
	{
		case 0:
		{
			ClientCommand(client, "cl_glow_item_far_b 0.50");
			ClientCommand(client, "cl_glow_item_far_g 0.0");
			ClientCommand(client, "cl_glow_item_far_r 0.0");
			ClientCommand(client, "cl_glow_ghost_infected_b 1.0");
			ClientCommand(client, "cl_glow_ghost_infected_g 0.4");
			ClientCommand(client, "cl_glow_ghost_infected_r 0.3");
			ClientCommand(client, "cl_glow_item_b 2.0");
			ClientCommand(client, "cl_glow_item_g 0.0");
			ClientCommand(client, "cl_glow_item_r 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_r 3.0");
			ClientCommand(client, "cl_glow_survivor_vomit_b 0.0");
			ClientCommand(client, "cl_glow_survivor_vomit_g 0.5");
			ClientCommand(client, "cl_glow_survivor_vomit_r 2.0");
			ClientCommand(client, "cl_glow_infected_b 1.0");
			ClientCommand(client, "cl_glow_infected_g 0.4");
			ClientCommand(client, "cl_glow_infected_r 0.3");
			ClientCommand(client, "cl_glow_ability_b 10.0");
			ClientCommand(client, "cl_glow_ability_g 10.0");
			ClientCommand(client, "cl_glow_ability_r 10.0");
			ClientCommand(client, "cl_glow_ability_colorblind_b 1.0");
			ClientCommand(client, "cl_glow_ability_colorblind_g 1.0");
			ClientCommand(client, "cl_glow_ability_colorblind_r 0.3");
			ClientCommand(client, "cl_glow_infected_vomit_b 0.72");
			ClientCommand(client, "cl_glow_infected_vomit_g 0.07");
			ClientCommand(client, "cl_glow_infected_vomit_r 0.79");
			ClientCommand(client, "cl_glow_survivor_health_high_b 0.196");
			ClientCommand(client, "cl_glow_survivor_health_high_g 0.69");
			ClientCommand(client, "cl_glow_survivor_health_high_r 0.039");
			ClientCommand(client, "cl_glow_survivor_health_high_colorblind_b 0.392");
			ClientCommand(client, "cl_glow_survivor_health_high_colorblind_g 0.694");
			ClientCommand(client, "cl_glow_survivor_health_high_colorblind_r 0.047");
			ClientCommand(client, "cl_glow_survivor_health_med_b 0.032");
			ClientCommand(client, "cl_glow_survivor_health_med_g 0.4");
			ClientCommand(client, "cl_glow_survivor_health_med_r 0.59");
			ClientCommand(client, "cl_glow_survivor_health_med_colorblind_b 0.098");
			ClientCommand(client, "cl_glow_survivor_health_med_colorblind_g 0.573");
			ClientCommand(client, "cl_glow_survivor_health_med_colorblind_r 0.694");
			ClientCommand(client, "cl_glow_survivor_health_low_b 0.098");
			ClientCommand(client, "cl_glow_survivor_health_low_g 0.098");
			ClientCommand(client, "cl_glow_survivor_health_low_r 0.63");
			ClientCommand(client, "cl_glow_survivor_health_low_colorblind_b 0.807");
			ClientCommand(client, "cl_glow_survivor_health_low_colorblind_g 0.807");
			ClientCommand(client, "cl_glow_survivor_health_low_colorblind_r 0.047");
			ClientCommand(client, "cl_glow_thirdstrike_item_b 1.0");
			ClientCommand(client, "cl_glow_thirdstrike_item_g 0.0");
			ClientCommand(client, "cl_glow_thirdstrike_item_r 0.0");
			ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b 1.0");
			ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g 1.0");
			ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r 0.3");
			return Action:4;
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
			ClientCommand(client, "cl_glow_item_far_b %f", GetConVarFloat(GlowItemFarBlue1));
			ClientCommand(client, "cl_glow_item_far_g %f", GetConVarFloat(GlowItemFarGreen1));
			ClientCommand(client, "cl_glow_item_far_r %f", GetConVarFloat(GlowItemFarRed1));
			ClientCommand(client, "cl_glow_ghost_infected_b %f", GetConVarFloat(GlowGhostInfectedBlue1));
			ClientCommand(client, "cl_glow_ghost_infected_g %f", GetConVarFloat(GlowGhostInfectedGreen1));
			ClientCommand(client, "cl_glow_ghost_infected_r %f", GetConVarFloat(GlowGhostInfectedRed1));
			ClientCommand(client, "cl_glow_item_b %f", GetConVarFloat(GlowItemBlue1));
			ClientCommand(client, "cl_glow_item_g %f", GetConVarFloat(GlowItemGreen1));
			ClientCommand(client, "cl_glow_item_r %f", GetConVarFloat(GlowItemRed1));
			ClientCommand(client, "cl_glow_survivor_hurt_b %f", GetConVarFloat(GlowSurvivorHurtBlue1));
			ClientCommand(client, "cl_glow_survivor_hurt_g %f", GetConVarFloat(GlowSurvivorHurtGreen1));
			ClientCommand(client, "cl_glow_survivor_hurt_r %f", GetConVarFloat(GlowSurvivorHurtRed1));
			ClientCommand(client, "cl_glow_survivor_vomit_b %f", GetConVarFloat(GlowSurvivorVomitBlue1));
			ClientCommand(client, "cl_glow_survivor_vomit_g %f", GetConVarFloat(GlowSurvivorVomitGreen1));
			ClientCommand(client, "cl_glow_survivor_vomit_r %f", GetConVarFloat(GlowSurvivorVomitRed1));
			ClientCommand(client, "cl_glow_infected_b %f", GetConVarFloat(GlowInfectedBlue1));
			ClientCommand(client, "cl_glow_infected_g %f", GetConVarFloat(GlowInfectedGreen1));
			ClientCommand(client, "cl_glow_infected_r %f", GetConVarFloat(GlowInfectedRed1));
			ClientCommand(client, "cl_glow_ability_b %f", GetConVarFloat(GlowAbilityBlue1));
			ClientCommand(client, "cl_glow_ability_g %f", GetConVarFloat(GlowAbilityGreen1));
			ClientCommand(client, "cl_glow_ability_r %f", GetConVarFloat(GlowAbilityRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_ability_colorblind_b %f", GetConVarFloat(GlowAbilityBlue1));
				ClientCommand(client, "cl_glow_ability_colorblind_g %f", GetConVarFloat(GlowAbilityGreen1));
				ClientCommand(client, "cl_glow_ability_colorblind_r %f", GetConVarFloat(GlowAbilityRed1));
			}
			ClientCommand(client, "cl_glow_infected_vomit_b %f", GetConVarFloat(GlowInfectedVomitBlue1));
			ClientCommand(client, "cl_glow_infected_vomit_g %f", GetConVarFloat(GlowInfectedVomitGreen1));
			ClientCommand(client, "cl_glow_infected_vomit_r %f", GetConVarFloat(GlowInfectedVomitRed1));
			ClientCommand(client, "cl_glow_survivor_health_high_b %f", GetConVarFloat(GlowSurvivorHealthHighBlue1));
			ClientCommand(client, "cl_glow_survivor_health_high_g %f", GetConVarFloat(GlowSurvivorHealthHighGreen1));
			ClientCommand(client, "cl_glow_survivor_health_high_r %f", GetConVarFloat(GlowSurvivorHealthHighRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_b %f", GetConVarFloat(GlowSurvivorHealthHighBlue1));
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_g %f", GetConVarFloat(GlowSurvivorHealthHighGreen1));
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_r %f", GetConVarFloat(GlowSurvivorHealthHighRed1));
			}
			ClientCommand(client, "cl_glow_survivor_health_med_b %f", GetConVarFloat(GlowSurvivorHealthMedBlue1));
			ClientCommand(client, "cl_glow_survivor_health_med_g %f", GetConVarFloat(GlowSurvivorHealthMedGreen1));
			ClientCommand(client, "cl_glow_survivor_health_med_r %f", GetConVarFloat(GlowSurvivorHealthMedRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_b %f", GetConVarFloat(GlowSurvivorHealthMedBlue1));
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_g %f", GetConVarFloat(GlowSurvivorHealthMedGreen1));
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_r %f", GetConVarFloat(GlowSurvivorHealthMedRed1));
			}
			ClientCommand(client, "cl_glow_survivor_health_low_b %f", GetConVarFloat(GlowSurvivorHealthLowBlue1));
			ClientCommand(client, "cl_glow_survivor_health_low_g %f", GetConVarFloat(GlowSurvivorHealthLowGreen1));
			ClientCommand(client, "cl_glow_survivor_health_low_r %f", GetConVarFloat(GlowSurvivorHealthLowRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_b %f", GetConVarFloat(GlowSurvivorHealthLowBlue1));
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_g %f", GetConVarFloat(GlowSurvivorHealthLowGreen1));
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_r %f", GetConVarFloat(GlowSurvivorHealthLowRed1));
			}
			ClientCommand(client, "cl_glow_thirdstrike_item_b %f", GetConVarFloat(GlowThirdstrikeItemBlue1));
			ClientCommand(client, "cl_glow_thirdstrike_item_g %f", GetConVarFloat(GlowThirdstrikeItemGreen1));
			ClientCommand(client, "cl_glow_thirdstrike_item_r %f", GetConVarFloat(GlowThirdstrikeItemRed1));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b %f", GetConVarFloat(GlowThirdstrikeItemBlue1));
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g %f", GetConVarFloat(GlowThirdstrikeItemGreen1));
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r %f", GetConVarFloat(GlowThirdstrikeItemRed1));
			}
		}
		default:
		{
		}
	}
	return Action:0;
}

public Action Glow2(Handle:timer, any:client)
{
	if (!IsClientConnected(client) && !IsClientInGame(client))
	{
		return Action:4;
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
			ClientCommand(client, "cl_glow_item_far_b %f", GetConVarFloat(GlowItemFarBlue2));
			ClientCommand(client, "cl_glow_item_far_g %f", GetConVarFloat(GlowItemFarGreen2));
			ClientCommand(client, "cl_glow_item_far_r %f", GetConVarFloat(GlowItemFarRed2));
			ClientCommand(client, "cl_glow_ghost_infected_b %f", GetConVarFloat(GlowGhostInfectedBlue2));
			ClientCommand(client, "cl_glow_ghost_infected_g %f", GetConVarFloat(GlowGhostInfectedGreen2));
			ClientCommand(client, "cl_glow_ghost_infected_r %f", GetConVarFloat(GlowGhostInfectedRed2));
			ClientCommand(client, "cl_glow_item_b %f", GetConVarFloat(GlowItemBlue2));
			ClientCommand(client, "cl_glow_item_g %f", GetConVarFloat(GlowItemGreen2));
			ClientCommand(client, "cl_glow_item_r %f", GetConVarFloat(GlowItemRed2));
			ClientCommand(client, "cl_glow_survivor_hurt_b %f", GetConVarFloat(GlowSurvivorHurtBlue2));
			ClientCommand(client, "cl_glow_survivor_hurt_g %f", GetConVarFloat(GlowSurvivorHurtGreen2));
			ClientCommand(client, "cl_glow_survivor_hurt_r %f", GetConVarFloat(GlowSurvivorHurtRed2));
			ClientCommand(client, "cl_glow_survivor_vomit_b %f", GetConVarFloat(GlowSurvivorVomitBlue2));
			ClientCommand(client, "cl_glow_survivor_vomit_g %f", GetConVarFloat(GlowSurvivorVomitGreen2));
			ClientCommand(client, "cl_glow_survivor_vomit_r %f", GetConVarFloat(GlowSurvivorVomitRed2));
			ClientCommand(client, "cl_glow_infected_b %f", GetConVarFloat(GlowInfectedBlue2));
			ClientCommand(client, "cl_glow_infected_g %f", GetConVarFloat(GlowInfectedGreen2));
			ClientCommand(client, "cl_glow_infected_r %f", GetConVarFloat(GlowInfectedRed2));
			ClientCommand(client, "cl_glow_survivor_b %f", GetConVarFloat(GlowSurvivorBlue2));
			ClientCommand(client, "cl_glow_survivor_g %f", GetConVarFloat(GlowSurvivorGreen2));
			ClientCommand(client, "cl_glow_survivor_r %f", GetConVarFloat(GlowSurvivorRed2));
			ClientCommand(client, "cl_glow_ability_b %f", GetConVarFloat(GlowAbilityBlue2));
			ClientCommand(client, "cl_glow_ability_g %f", GetConVarFloat(GlowAbilityGreen2));
			ClientCommand(client, "cl_glow_ability_r %f", GetConVarFloat(GlowAbilityRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_ability_colorblind_b %f", GetConVarFloat(GlowAbilityBlue2));
				ClientCommand(client, "cl_glow_ability_colorblind_g %f", GetConVarFloat(GlowAbilityGreen2));
				ClientCommand(client, "cl_glow_ability_colorblind_r %f", GetConVarFloat(GlowAbilityRed2));
			}
			ClientCommand(client, "cl_glow_infected_vomit_b %f", GetConVarFloat(GlowInfectedVomitBlue2));
			ClientCommand(client, "cl_glow_infected_vomit_g %f", GetConVarFloat(GlowInfectedVomitGreen2));
			ClientCommand(client, "cl_glow_infected_vomit_r %f", GetConVarFloat(GlowInfectedVomitRed2));
			ClientCommand(client, "cl_glow_survivor_health_high_b %f", GetConVarFloat(GlowSurvivorHealthHighBlue2));
			ClientCommand(client, "cl_glow_survivor_health_high_g %f", GetConVarFloat(GlowSurvivorHealthHighGreen2));
			ClientCommand(client, "cl_glow_survivor_health_high_r %f", GetConVarFloat(GlowSurvivorHealthHighRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_b %f", GetConVarFloat(GlowSurvivorHealthHighBlue2));
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_g %f", GetConVarFloat(GlowSurvivorHealthHighGreen2));
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_r %f", GetConVarFloat(GlowSurvivorHealthHighRed2));
			}
			ClientCommand(client, "cl_glow_survivor_health_med_b %f", GetConVarFloat(GlowSurvivorHealthMedBlue2));
			ClientCommand(client, "cl_glow_survivor_health_med_g %f", GetConVarFloat(GlowSurvivorHealthMedGreen2));
			ClientCommand(client, "cl_glow_survivor_health_med_r %f", GetConVarFloat(GlowSurvivorHealthMedRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_b %f", GetConVarFloat(GlowSurvivorHealthMedBlue2));
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_g %f", GetConVarFloat(GlowSurvivorHealthMedGreen2));
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_r %f", GetConVarFloat(GlowSurvivorHealthMedRed2));
			}
			ClientCommand(client, "cl_glow_survivor_health_low_b %f", GetConVarFloat(GlowSurvivorHealthLowBlue2));
			ClientCommand(client, "cl_glow_survivor_health_low_g %f", GetConVarFloat(GlowSurvivorHealthLowGreen2));
			ClientCommand(client, "cl_glow_survivor_health_low_r %f", GetConVarFloat(GlowSurvivorHealthLowRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_b %f", GetConVarFloat(GlowSurvivorHealthLowBlue2));
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_g %f", GetConVarFloat(GlowSurvivorHealthLowGreen2));
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_r %f", GetConVarFloat(GlowSurvivorHealthLowRed2));
			}
			ClientCommand(client, "cl_glow_thirdstrike_item_b %f", GetConVarFloat(GlowThirdstrikeItemBlue2));
			ClientCommand(client, "cl_glow_thirdstrike_item_g %f", GetConVarFloat(GlowThirdstrikeItemGreen2));
			ClientCommand(client, "cl_glow_thirdstrike_item_r %f", GetConVarFloat(GlowThirdstrikeItemRed2));
			if (GetConVarInt(IgnoringColorblindSet) == 1)
			{
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b %f", GetConVarFloat(GlowThirdstrikeItemBlue2));
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g %f", GetConVarFloat(GlowThirdstrikeItemGreen2));
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r %f", GetConVarFloat(GlowThirdstrikeItemRed2));
			}
		}
		default:
		{
		}
	}
	return Action:0;
}

public Action:TimerStart(client)
{
	CreateTimer(1.0, Glow1, client, 1);
	CreateTimer(2.0, Glow2, client, 1);
}

public bool OnClientConnect(client, String:rejectmsg[], maxlen)
{
	CreateTimer(10.0, Timer_Advertise, client, 0);
	return true;
}

public Action:Timer_Advertise(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		CPrintToChat(client, "{default}Hard Realism Coop {green}by {blue}XStriker★BlacK {green}!");
	}
	else
	{
		if (IsClientConnected(client))
		{
			CreateTimer(10.0, Timer_Advertise, client, 0);
		}
	}
}

public ChangeSkyboxTexture()
{
	if (GetConVarBool(cvarEnabled))
	{
		decl String:newskybox[32];
		GetConVarString(cvarSkybox, newskybox, 32);
		if (strcmp(newskybox, "", false))
		{
			PrintToServer("[ET] Changing the Skybox to %s", newskybox);
			DispatchKeyValue(0, "skyname", newskybox);
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
	if (FogControllerIndex != -1)
	{
		DispatchKeyValueFloat(FogControllerIndex, "fogmaxdensity", FogDensity);
		SetVariantInt(FogStartDist);
		AcceptEntityInput(FogControllerIndex, "SetStartDist", -1, -1, 0);
		SetVariantInt(FogEndDist);
		AcceptEntityInput(FogControllerIndex, "SetEndDist", -1, -1, 0);
		SetVariantInt(FogZPlane);
		AcceptEntityInput(FogControllerIndex, "SetFarZ", -1, -1, 0);
	}
}

public ConvarChange_FogColor(Handle:convar, String:oldValue[], String:newValue[])
{
	ChangeFogColors();
}

public ChangeFogColors()
{
	decl String:FogColor[32];
	GetConVarString(cvarFogColor, FogColor, 32);
	SetVariantString(FogColor);
	AcceptEntityInput(FogControllerIndex, "SetColor", -1, -1, 0);
	SetVariantString(FogColor);
	AcceptEntityInput(FogControllerIndex, "SetColorSecondary", -1, -1, 0);
}


// *********************************************************************************
// METHODS FOR COLORS
// *********************************************************************************

#define MAX_MESSAGE_LENGTH 250
#define MAX_COLORS 6

#define SERVER_INDEX 0
#define NO_INDEX -1
#define NO_PLAYER -2

enum Colors
{
 	Color_Default = 0,
	Color_Green,
	Color_Lightgreen,
	Color_Red,
	Color_Blue,
	Color_Olive
}

/* Colors' properties */
new String:CTag[][] = {"{default}", "{green}", "{lightgreen}", "{red}", "{blue}", "{olive}"};
new String:CTagCode[][] = {"\x01", "\x04", "\x03", "\x03", "\x03", "\x05"};
new bool:CTagReqSayText2[] = {false, false, true, true, true, false};
new bool:CEventIsHooked = false;
new bool:CSkipList[MAXPLAYERS+1] = {false,...};

/* Game default profile */
new bool:CProfile_Colors[] = {true, true, false, false, false, false};
new CProfile_TeamIndex[] = {NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX};
new bool:CProfile_SayText2 = false;

stock CPrintToChat(client, const String:szMessage[], any:...)
{
	if (client <= 0 || client > MaxClients)
		ThrowError("Invalid client index %d", client);
	
	if (!IsClientInGame(client))
		ThrowError("Client %d is not in game", client);
	
	decl String:szBuffer[MAX_MESSAGE_LENGTH];
	decl String:szCMessage[MAX_MESSAGE_LENGTH];
	SetGlobalTransTarget(client);
	Format(szBuffer, sizeof(szBuffer), "\x01%s", szMessage);
	VFormat(szCMessage, sizeof(szCMessage), szBuffer, 3);
	
	new index = CFormat(szCMessage, sizeof(szCMessage));
	if (index == NO_INDEX)
	{
		PrintToChat(client, szCMessage);
	}
	else
	{
		CSayText2(client, index, szCMessage);
	}
}


stock CFormat(String:szMessage[], maxlength, author=NO_INDEX)
{
	/* Hook event for auto profile setup on map start */
	if (!CEventIsHooked)
	{
		CSetupProfile();
		HookEvent("server_spawn", CEvent_MapStart, EventHookMode_PostNoCopy);
		CEventIsHooked = true;
	}
	
	new iRandomPlayer = NO_INDEX;
	
	/* If author was specified replace {teamcolor} tag */
	if (author != NO_INDEX)
	{
		if (CProfile_SayText2)
		{
			ReplaceString(szMessage, maxlength, "{teamcolor}", "\x03");
			iRandomPlayer = author;
		}
		/* If saytext2 is not supported by game replace {teamcolor} with green tag  */
		else
		{
			ReplaceString(szMessage, maxlength, "{teamcolor}", CTagCode[Color_Green]);
		}
	}
	else
	{
		ReplaceString(szMessage, maxlength, "{teamcolor}", "");
	}
	
	/* For other color tags we need a loop */
	for (new i = 0; i < MAX_COLORS; i++)
	{
		/* If tag not found - skip */
		if (StrContains(szMessage, CTag[i]) == -1)
		{
			continue;
		}
		/* If tag is not supported by game replace it with green tag */
		else if (!CProfile_Colors[i])
		{
			ReplaceString(szMessage, maxlength, CTag[i], CTagCode[Color_Green]);
		}
		/* If tag doesn't need saytext2 simply replace */
		else if (!CTagReqSayText2[i])
		{
			ReplaceString(szMessage, maxlength, CTag[i], CTagCode[i]);
		}
		/* Tag needs saytext2 */
		else
		{
			/* If saytext2 is not supported by game replace tag with green tag */
			if (!CProfile_SayText2)
			{
				ReplaceString(szMessage, maxlength, CTag[i], CTagCode[Color_Green]);
			}
			/* Game supports saytext2 */
			else 
			{
				/* If random player for tag wasn't specified replace tag and find player */
				if (iRandomPlayer == NO_INDEX)
				{
					/* Searching for valid client for tag */
					iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i]);
					
					/* If player not found replace tag with green color tag */
					if (iRandomPlayer == NO_PLAYER)
					{
						ReplaceString(szMessage, maxlength, CTag[i], CTagCode[Color_Green]);
					}
					/* If player was found simply replace */
					else
					{
						ReplaceString(szMessage, maxlength, CTag[i], CTagCode[i]);
					}
					
				}
				/* If found another team color tag throw error */
				else
				{
					//ReplaceString(szMessage, maxlength, CTag[i], "");
					ThrowError("Using two team colors in one message is not allowed");
				}
			}
			
		}
	}
	
	return iRandomPlayer;
}

stock CSayText2(client, author, const String:szMessage[])
{
	new Handle:hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, szMessage);
	EndMessage();
}

stock CSetupProfile()
{
	decl String:szGameName[30];
	GetGameFolderName(szGameName, sizeof(szGameName));
	
	if (StrEqual(szGameName, "cstrike", false))
	{
		CProfile_Colors[Color_Lightgreen] = true;
		CProfile_Colors[Color_Red] = true;
		CProfile_Colors[Color_Blue] = true;
		CProfile_Colors[Color_Olive] = true;
		CProfile_TeamIndex[Color_Lightgreen] = SERVER_INDEX;
		CProfile_TeamIndex[Color_Red] = 2;
		CProfile_TeamIndex[Color_Blue] = 3;
		CProfile_SayText2 = true;
	}
	else if (StrEqual(szGameName, "tf", false))
	{
		CProfile_Colors[Color_Lightgreen] = true;
		CProfile_Colors[Color_Red] = true;
		CProfile_Colors[Color_Blue] = true;
		CProfile_Colors[Color_Olive] = true;		
		CProfile_TeamIndex[Color_Lightgreen] = SERVER_INDEX;
		CProfile_TeamIndex[Color_Red] = 2;
		CProfile_TeamIndex[Color_Blue] = 3;
		CProfile_SayText2 = true;
	}
	else if (StrEqual(szGameName, "left4dead", false) || StrEqual(szGameName, "left4dead2", false))
	{
		CProfile_Colors[Color_Lightgreen] = true;
		CProfile_Colors[Color_Red] = true;
		CProfile_Colors[Color_Blue] = true;
		CProfile_Colors[Color_Olive] = true;		
		CProfile_TeamIndex[Color_Lightgreen] = SERVER_INDEX;
		CProfile_TeamIndex[Color_Red] = 3;
		CProfile_TeamIndex[Color_Blue] = 2;
		CProfile_SayText2 = true;
	}
	else if (StrEqual(szGameName, "hl2mp", false))
	{
		/* hl2mp profile is based on mp_teamplay convar */
		if (GetConVarBool(FindConVar("mp_teamplay")))
		{
			CProfile_Colors[Color_Red] = true;
			CProfile_Colors[Color_Blue] = true;
			CProfile_Colors[Color_Olive] = true;
			CProfile_TeamIndex[Color_Red] = 3;
			CProfile_TeamIndex[Color_Blue] = 2;
			CProfile_SayText2 = true;
		}
		else
		{
			CProfile_SayText2 = false;
			CProfile_Colors[Color_Olive] = true;
		}
	}
	else if (StrEqual(szGameName, "dod", false))
	{
		CProfile_Colors[Color_Olive] = true;
		CProfile_SayText2 = false;
	}
	/* Profile for other games */
	else
	{
		if (GetUserMessageId("SayText2") == INVALID_MESSAGE_ID)
		{
			CProfile_SayText2 = false;
		}
		else
		{
			CProfile_Colors[Color_Red] = true;
			CProfile_Colors[Color_Blue] = true;
			CProfile_TeamIndex[Color_Red] = 2;
			CProfile_TeamIndex[Color_Blue] = 3;
			CProfile_SayText2 = true;
		}
	}
}

public Action:CEvent_MapStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CSetupProfile();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		CSkipList[i] = false;
	}
}

stock CFindRandomPlayerByTeam(color_team)
{
	if (color_team == SERVER_INDEX)
	{
		return 0;
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == color_team)
			{
				return i;
			}
		}	
	}

	return NO_PLAYER;
}
