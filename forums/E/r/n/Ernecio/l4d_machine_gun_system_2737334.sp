/* ==========================================================================================================================================

													Registro De Cambios
												
	[07/04/2020] Versión 1.0.9
	- Secciones de código que nunca se usan en el plugin removidas.
	- Variable de comprobación de juego cambiada de valor entero a valor booleano.
	- Correción de m_useActionTarget ya que no existe en L4D1.
	- Sporte completo para L4D1, ya que solo se podía usar un solo modelo de ametralladora.
	- Correción de entradas CMD para la selección de tipos de ametralladora por medio del chat.
	- Optimización de código.
	
	[07/04/2020] Versión 2.0
	- Nuevo método que permite el uso de munición incendiaría y explosiva para L4D1/2.
	- Correción de limite de ametralladoras por usuario y limite máximo total.
	- Estado de contador por usuario corregido.
	- Nuevo método de permisos de administrador en la creción de nuevas ametralladoras.
	- Correción de permisos de administrador para eliminar una ametralladora.
	- Secciones de código en vieja sintaxis traducidas a SM 1.10
	
	[07/04/2020] Versión 2.1
	- Nuevo método de mostrado y atado de partículas que corrige el bloqueo de servidor/juego por exeso de partículas no eliminadas.
	- Nuevo stock para PrecacheParticle.
	- Nuevo método para la aparición de partículas de bala mientras esta en el aire.
	  Permite este nuevo método la aparición de partículas de bala en el aire para ambos L4D1/2
	  
	- Nuevo método de ConVars con valores minimos y máximos desde debtro de la función, permitiendo retirar comprobadores externos.
	- Nuava descripcion en cada ConVar.
	
	[07/04/2020] Versión 3.0 Mejora Importante
	- Agregadas nuevas ametralladoras capaces de disparar rayos eléctricos, rayos láser y llamaradas.
	- Nueva reestructuración del código.
	  Implica nuevos stocks de código y nuevos métodos para la funciónn correcta de las ametralladoras especiales (tesla, laser, llama).
	  
	- Nuevo método de deteción de enemigos incapacitados o en llamas (Zombies comunes), para que las ametralladoras cambien de objetivo.
	- Ametralladora tipo Tesla capas de desintegrar infectados comunes.
	- Variables ConVar con almacenamiento interno para evitar hacer llamdos de la variable enxternamente a cada uso que se le de.
	- Métodos de cálculo de deño por distancia y tipos daños por distancia agregados.
	
	[07/28/2020] Versión 3.1
	- Nueva ametralladora con la capasidad de congelación basado en distancia y probabilidad en disparo.
	- Nuevo método de brillo(Glow), permite establecer colores acorde al tipo de ametralladora.
	
	[08/032020] Versión 3.2
	- Nuevo método de impresión de mensajes en el chat, este método permite el uso de colores especiales tales como rojo y azul.
	- Traducciones agregadas, soporte de idiomas actual: español/íngles.
	- Nuevo método de instructor que permite uso de colores personalizados y mayor rango de iconos, solo en Left 4 Dead 2
	
	[08/29/2020] Versión 3.3
	- Bloqueo de uso de las ametralladoras que han sido creadas por medio de este Plugin, mediante un empujón.
	- Nuevo método de comprobación de enemigos, permite detectar enemigo incapasitado y estado fantasma.
	- Efecto de árco eléctrico entre un usuario y ametralladora.
	- Optimizaciones en el código original.
	- Asignaturas nuevas.
	
	[09/06/2020] Versión 3.4
	- Corrección de dueño de ametralladora del tipo congelación debido a que no tenía array de clientes.
	- Nuevo efecto de explosión cuando una ametralladora se a roto o es removida, y su Convar correspondiente al daño.
	
	[01/29/2021] Versión 3.5
	- Corrección de texturas sin cargar en efectos de explosión para L4D1, debido a que anteriormente no tenia errores.
	- Fuego añadido a la destrucción de una ametralladora del tipo fuego, esto como efecto del combustible derramado del lanza llamas.
	
	[01/30/2021] Versión 3.6
	- Corrección de ángulos en ametralladoras básicas cuando están en uso, esto permite alinear el cañón y punto de mira correctamente.
	
	[02/09/2021] Versión 3.7
	- Corrección de estado inactivo en las ametralladoras ya que al quedar en este estado se autodestruían.
	- Salud para las ametralladoras agregada, ahora al resibir daño pueden destruirse en base a su salud.
	
	[02/14/2021] Versión 3.8
	- Agregada función de daños y efectos en la destrucción de ametralladoras tipo tesla, nauseabundo y congelante.
	  Esto únicamente aplica en jugadores validos, las entidades como zombies y witches son afectados por la explosión básica.
	  La función de derrame de bilis de boomer solo está disponible para supervivientes en L4D1, en L4D2 esta diponible para el tank.
	  
	[02/15/2021] Versión 3.9
	- Nueva stock para el muestreo de balas L4D_TE_Create_Particle tomado del los stocks de Lux.
	
	[02/16/2021] Versión 4.0
	- Soporte para conteo de munición que se utiliza cuando una ametralladora está en uso por un usuario.
	  Cuando la munición se ha terminado la ametralladora expulsará al usuario y solo se podrá usar de nuevo sí es recargada.
	  
	- Textos restantes agregados a traducciones Español/Inglés.
	- Corrección de compilado con SM 1.11
	
	[02/17/2021]
	- Corrección de bucle de sonido infinito al destruirse una ametralladora en funcionamiento tipo fuego.
	- Corrección de efectos en ametralladora tipo fuego.
	
	[02/18/2021] Versión 4.1
	- Agregados comprobadores para algunos eventos que faltaban para entidades y clientes validos.
	
	[02/22/2021] Versión 4.2
	- Nuevo Convar que permite elegir el tiempo en el que se soltará una ametralladora.
	- Soporte para detección de uso de botones de larga duración en Left 4 Dead 1.
	  Esto para generadores y algunos botones creados por Plugins.
	
												Notas Hasta La Versión Actual 4.2
												
*	La munición especial solo puede ser utilizada en modo automático, un usario solo puede usar munición normal, aun falta prueba en L4D2.
*	En L4D1 al tratar de utilizar una ametralladora que sea inaccesible se pueden arrojar advertencias en consola, no afecta al server/juego.	
*	Las ametralladoras pueden atascarse en caso de tener contacto con un objeto sólido, sólo reubicandola se desatascará.
*	Las ametralladoras que no son especiales no siempre se podrán utilizar aunque no estén disparando.
*	En L4D1 las ametralladoras tipo nauseabundo solo pueden disparar bilis de boomer a supervivientes, en L4D2 superviviente y tanks.
*	Plugin sin probar con mas de 10 ametralladora a la ves, podría bloquear el server/juego sí se utilizan muchas a la mismo tiempo.
*	Aun requiere prueba con los plugins [L4D/L4D2]Lux's Model Changer, [L4D & L4D2] Dissolve Infected.
*	El sonido de percusión sigue activo en una ametralladora del tipo fuego Gatling, para la ametralladora Cal 50 no sucede esto.
*	Los árcos eléctricos de la ametralladora tipo Tesla pueden desaparecer por un tiempo, pero no afecta a la ametralladora.
*	Plugin únicamente probado en Windows y SourceMod 1.10 en Left 4 Dead 1, SourceMod 1.11 Left 4 Dead 2.
*	Sí es reiniciado el plugin por admin y hay alguien usando una ametralladora quedará atascado sin poder moverse.

	*- Este Plugin aun continua en desarrollo por lo que podría haber algún bug no mencionado antes pero en general funciona sin problemas -*

															^^Créditos^^
															
	- Panxiaohai por su plugin [L4D & L4D2] Intelligent Machine Gun y su idea original.
	  https://forums.alliedmods.net/showthread.php?t=164543
	
	- Silvers por sus stocks de código en [L4D & L4D2] Prototype Grenades.
	- Marttt por sus stocks de código en sus plugins.
	- Lux por su stock L4D_TE_Create_Particle.
	
	- Ah todos ellos gracias por sus stocks de codigo y plugins!
	(Eh usado otras referencias de código de los foros de SourceMod, créditos para sus autores)
	
   ========================================================================================================================================== */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

#define PLUGIN_VERSION "4.2" // Versión Del Plugin

/************************************************************************************************************************/
#define TEAM_SPECTATOR               1 		// Equipo De Espectadores
#define TEAM_SURVIVOR                2 		// Equipo De Supervivientes
#define TEAM_INFECTED                3 		// Equipo De Infectados

#define SMOKER 	1
#define BOOMER 	2
#define HUNTER 	3
#define SPITTER 4
#define JOCKEY 	5
#define CHARGER 6
#define TANK 	7

#define MAX_MESSAGE_LENGTH           250 	// Cantidad De Carateres Para CustomPrintToChat

#define EXTENDED_COLOR_TAG_NONE      0 		// Sin Indice De Color
#define EXTENDED_COLOR_TAG_TEAM      1 		// Indice De Color Del Jugador
#define EXTENDED_COLOR_TAG_BLUE      2 		// Indice De Color Azul
#define EXTENDED_COLOR_TAG_RED       3 		// Indice De Color Rojo
#define EXTENDED_COLOR_TAG_WHITE     4 		// Indice De Color Blanco
/************************************************************************************************************************/
#define State_None 	0
#define State_Scan 	1
#define State_Sleep 2
#define State_Carry 3
/************************************************************************************************************************/
#define PARTICLE_MUZZLE_FLASH			"weapon_muzzle_flash_autoshotgun" 		// Explosión De Percución De Bala
#define PARTICLE_WEAPON_TRACER_GATLING	"weapon_tracers" 						// Partícula De Bala
#define PARTICLE_WEAPON_TRACER_50CAL	"weapon_tracers_50cal" 					// Partícula De Bala Calibre 50

#define PARTICLE_FIRE1			"fire_jet_01_flame" 							// Flama Pequeña De Molotov
#define PARTICLE_FIRE2			"fire_small_02" 								// Evita Errores De Late Precache
#define PARTICLE_FIRE3			"weapon_molotov_thrown" 						// Flama Jigante
#define PARTICLE_EMBERS			"barrel_fly_embers" 							// Chispas De Fuego Distrubuidas.

#define PARTICLE_TES1			"electrical_arc_01" 							// Árco Eléctrico De Baja Intensidad
#define PARTICLE_TES2			"electrical_arc_01_system" 						// Árco Eléctrico De Gran Intensidad
#define PARTICLE_TES3			"st_elmos_fire" 								// Bola De Plásma

#define PARTICLE_SMOKE			"smoke_medium_01" 								// Humo Naranja Con Terminación Oscura
#define PARTICLE_WATER 			"weapon_pipebomb_water_splash" 					// Salpicaduras De Agua

#define PARTICLE_VOMIT			"boomer_vomit" 									// Vomito De Boomer

#define PARTICLE_BLOOD			"blood_impact_red_01" 							// Salpicadura De Sangre

#define PARTICLE_GAS_EXPLOTION 				"gas_explosion_pump" 				// Explosión De Tanque De Gas Propano
#define PARTICLE_MOLOTOV_EXPLOTION 			"molotov_explosion" 				// Explosión De Bomba Molotov
#define PARTICLE_MOLOTOV_EXPLOTION_BRANCH 	"molotov_explosion_child_burst" 	// Explosión De Bomba Molotov Con Ramificaciones

#define SOUND_FIRE_L4D1			"ambient/Spacial_Loops/CarFire_Loop.wav" 		// Sonido De Llamarada
#define SOUND_FIRE_L4D2			"ambient/fire/interior_fire02_stereo.wav" 		// Sonido De Llamarada Estática

#define SOUND_IMPACT_FLESH		"physics/flesh/flesh_impact_bullet1.wav" 		// Impacto De Bala Sobre Carne
#define SOUND_IMPACT_CONCRETE	"physics/concrete/concrete_impact_bullet1.wav" 	// Impacto De Bala Sobre Concreto
#define SOUND_SHOOT_50CAL		"weapons/50cal/50cal_shoot.wav" 				// Disparo De Ametralladora Calibre 50

#define SOUND_EXPLODE3			"weapons/hegrenade/explode3.wav" 				// Sonidos De Efectos De Explosión
#define SOUND_EXPLODE4			"weapons/hegrenade/explode4.wav"
#define SOUND_EXPLODE5			"weapons/hegrenade/explode5.wav"

#define SOUND_FREEZER			"physics/glass/glass_impact_bullet4.wav" 		// Sonido De Congelamiento

#define MODEL_PIPEBOMB 			"models/w_models/weapons/w_eq_pipebomb.mdl"
#define MODEL_MINIGUN_GATLING 	"models/w_models/weapons/w_minigun.mdl" 		// Módelo De Ametralladora Gatling
#define MODEL_MINIGUN_50CAL 	"models/w_models/weapons/50cal.mdl" 			// Módelo De Ametralladora Calibre 50

#define MODEL_CRATE				"models/props_junk/explosive_box001.mdl" 		// Módelo De Caja De Fuegos Artificiales
#define MODEL_GASCAN			"models/props_junk/gascan001a.mdl" 				// Módelo De Lata De Gasolina Rojo, Left 4 Dead 1/2

#define MODEL_ANOMALY_LASER_L4D1 	"materials/sprites/physbeam.vmt" 			// Módelo De Láser Especial, Tipo Árco Eléctrico, Left 4 Dead 1
#define MODEL_ANOMALY_LASER_L4D2 	"materials/sprites/laserbeam.vmt" 			// Módelo De Láser Especial, Tipo Árco Eléctrico, Left 4 Dead 2

#define MODEL_MUZZLEFLASH 			"sprites/muzzleflash4.vmt" 					// Módelo De Texturas De Explosión
/************************************************************************************************************************/
#define EnemyArraySize 300

#define DMG_HEADSHOT (1 << 31) 	// Operador Con Desplazamiento A lA Izquierda, Cantidad Real -2147483648

#define MAX_ALLOWED		32 		// Cantidad Máxima Permitida De Ametralladoras.
#define MAX_EACHPLAYER 	5 		// Cantidad Máxima Permitida De Ametralladoras Por Cada Jugador.
#define MAX_ENTITIES 	2048 	// Cantidad Máxima De Entidades

#define NULL 0 			// Valor nulo para multiples usos.

#define MACHINE_MINI  1 // Indice De Modelo Para La Ametralladora Gatling
#define MACHINE_50CAL 2 // Indice De Modelo Para La Ametralladora Cal 50

#define TYPE_FLAME 	1 	// Tipo Especial, Llamarada
#define TYPE_LASER 	2 	// Tipo Especial, Láser
#define TYPE_TESLA 	3 	// Tipo Especial, Tesla
#define TYPE_FREEZE 4   // Tipo Especial, Congelante
#define TYPE_NAUSEATING 5 // Tipo Especial, Nauseabundo

#define TRANSLATION_FILENAME 	"l4d_machine_gun_system.phrases" // Traducciones 

#define PI_NUM 3.14159 // Número PI

/****************************************************/
#undef REQUIRE_PLUGIN
#tryinclude <LMCCore>
#define REQUIRE_PLUGIN

#if !defined _LMCCore_included
	native int LMC_GetEntityOverlayModel(int iEntity);
#endif

static bool	bLMC_Available;
/****************************************************/

int MachineCount = 0;

static bool bLeft4DeadTwo;
static bool bMapStarted;
static bool bFinalEvent;
//static bool bCanDissolve;
int LaserModelIndex;

int	iParticleTracer_Gatling; 	// Indice De Partícula De Bala Gatling
int	iParticleTracer_50Cal; 		// Indice De Partícula De Bala Cal 50

int InfectedsArray[EnemyArraySize];
int InfectedCount;

int MachineGunCounterUser[MAXPLAYERS+1];
int MachineGunTypes[MAX_ENTITIES];
int MachineGunSpawned[MAX_ALLOWED];
int FreezingMachineGunOwner[MAXPLAYERS+1][MAX_EACHPLAYER];
int FreezingMachineGunCount[MAXPLAYERS+1][MAX_EACHPLAYER];

bool bSpecialBulletsAllowed[MAX_ENTITIES];

bool BurnedEntity[MAX_ENTITIES];

bool bAllowSound[MAX_ENTITIES];

bool FreezedPlayer[MAXPLAYERS+1]; // Array de jugadores congelados.
bool VomitedPlayer[MAXPLAYERS+1]; // Array de jugadores vomitados.

float ScanTime = 0.0;
int GunType[MAXPLAYERS+1];

int GunState[MAXPLAYERS+1];
int Gun[MAXPLAYERS+1];
int GunOwner[MAXPLAYERS+1];
int GunUser[MAXPLAYERS+1];
int GunEnemy[MAXPLAYERS+1];
int GunTeam[MAXPLAYERS+1];
int GunAmmo[MAXPLAYERS+1];
int AmmoIndicator[MAXPLAYERS+1];

int GunCarrier[MAXPLAYERS+1];
float GunCarrierOrigin[MAXPLAYERS+1][3];
float GunCarrierAngle[MAXPLAYERS+1][3];

float GunFireStopTime[MAXPLAYERS+1];
float GunLastCarryTime[MAXPLAYERS+1];

float GunFireTime[MAXPLAYERS+1];
float GunFireTotolTime[MAXPLAYERS+1];
int GunScanIndex[MAXPLAYERS+1];
float GunHealth[MAXPLAYERS+1];

bool Broken[MAXPLAYERS+1];
int LastButton[MAXPLAYERS+1];
float PressTime[MAXPLAYERS+1];
float LastTime[MAXPLAYERS+1];

float MachineGunerTime[MAXPLAYERS+1];
float Machine_RateTime[MAXPLAYERS+1];

int ShowMsg[MAXPLAYERS+1];

static bool bFlameAllowed;
static bool bLaserAllowed;
static bool bTeslaAllowed;
static bool bFreezeAllowed;
static bool bNauseatingAllowed;

static const char sArraySoundsZap[][] =
{
	"ambient/energy/zap1.wav",
	"ambient/energy/zap2.wav",
	"ambient/energy/zap3.wav",
	"ambient/energy/zap5.wav",
	"ambient/energy/zap6.wav",
	"ambient/energy/zap7.wav",
	"ambient/energy/zap8.wav",
	"ambient/energy/zap9.wav"
};

static const float RechargeTimers[2] =
{
	15.0, 55.0
};

//enum () // Incompatible con SM 1.11 al compilar.
enum
{
	INDEX_FREEZE = 0,
	INDEX_NAUSEATING
}

static const char sPluginTag[] = "'Gold'['Green'M-G-S'Gold']'Default'";

public Plugin myinfo =
{
	name 		= "[L4D1 AND L4D2] Machine Gun System", 							// Sistema De Ametralladoras
	author 		= "Ernecio",
	description = "Create machine guns of different types with automatic control.", // Crea ametralladoras de diferentes tipos con control automático.
	version 	= PLUGIN_VERSION,
	url 		= "https://steamcommunity.com/profiles/76561198404709570/"
}

/**
 * Called on pre plugin start.
 *
 * @param hMyself        Handle to the plugin.
 * @param bLate          Whether or not the plugin was loaded "late" (after map load).
 * @param sError         Error message buffer in case load failed.
 * @param Error_Max      Maximum number of characters for error message buffer.
 * @return               APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2( Handle hMyself, bool bLate, char[] sError, int Error_Max )
{
	EngineVersion Engine = GetEngineVersion();
	if( Engine != Engine_Left4Dead && Engine != Engine_Left4Dead2 )
	{
		strcopy( sError, Error_Max, "This Plugin \"Machine Gun System\" Only Runs In The \"Left 4 Dead 1/2\" Games!" );
		return APLRes_SilentFailure;
	}
	
	MarkNativeAsOptional("LMC_GetEntityOverlayModel"); // LMC
	
	bLeft4DeadTwo = ( Engine == Engine_Left4Dead2 );
//	bCanDissolve = bLate;
	return APLRes_Success;
}
/******************************************************/
public void OnAllPluginsLoaded()
{
	bLMC_Available = LibraryExists("LMCEDeathHandler");
}

public void OnLibraryAdded(const char[] sName)
{
	if( StrEqual( sName, "LMCEDeathHandler" ) )
		bLMC_Available = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if( StrEqual( sName, "LMCEDeathHandler" ) )
		bLMC_Available = false;
}
/******************************************************/
static ConVar hCvar_MPGameMode;
static ConVar hCvar_Machine_Enabled;
static ConVar hCvar_Machine_FinaleOnly;

static ConVar hCvar_Machine_GameModesOn;
static ConVar hCvar_Machine_GameModesOff;
static ConVar hCvar_Machine_GameModesToggle;
static ConVar hCvar_Machine_MapsOn;
static ConVar hCvar_Machine_MapsOff;

static ConVar hCvar_MachineDamageToInfected;
static ConVar hCvar_MachineDamageToSurvivor;
static ConVar hCvar_MachineMaxAllowed;
static ConVar hCvar_MachineRange;
static ConVar hCvar_MachineOverHeat;

static ConVar hCvar_MachineRequiredAccessLevel;
static ConVar hCvar_MachineBasicAdminOnly;
static ConVar hCvar_MachineSpecialAdminOnly;
static ConVar hCvar_MachineSpecialAllowed;

static ConVar hCvar_MachineUsageMessage;
static ConVar hCvar_MachineAmmoCount;
static ConVar hCvar_MachineAmmoType;
static ConVar hCvar_MachineAmmoReload;
static ConVar hCvar_MachineAllowCarry;
static ConVar hCvar_MachineAllowUse;
static ConVar hCvar_MachineSleepTime;
static ConVar hCvar_MachineFireRate;
static ConVar hCvar_MachineHealth;

static ConVar hCvar_MachineBetrayChance;
static ConVar hCvar_MachineLimit;

static ConVar hCvar_MachineEnableExplosion;

static ConVar hCvar_MachineDroppingTime;

static Handle SDKDissolveCreate = INVALID_HANDLE; // Handler SDK Functions/Controlador De Funciones SDK.
static Handle SDKVomitOnPlayer = INVALID_HANDLE;
//static Handle SDKShoveSurvivor = INVALID_HANDLE;
static Handle SDKStaggerClient = INVALID_HANDLE;

static float fCvar_MachineDamageToInfected;
static float fCvar_MachineDamageToSurvivor;
static float fCvar_MachineFireRate;
static float fCvar_MachineOverHeat;
static float fCvar_MachineRange;
static float fCvar_MachineSleepTime;
static float fCvar_MachineHealth;
static float fCvar_MachineDroppingTime;

static int iCvar_MachineMaxAllowed;
static int iCvar_MachineUsageMessage;
static int iCvar_MachineAmmoCount;
static int iCvar_MachineAmmoType;
static int iCvar_MachineAllowCarry;
static int iCvar_MachineBetrayChance;
static int iCvar_MachineLimit;
static int iCvar_MachineEnableExplosion;

static bool bCvar_Machine_Enabled;
static bool bCvar_MachineAmmoReload;
static bool bCvar_Machine_FinaleOnly;
static bool bCvar_MachineAllowUse;

static char sCvar_MachineRequiredAccessLevel[128];
static char sCvar_MachineBasicAdminOnly[128];
static char sCvar_MachineSpecialAdminOnly[128];
static char sCvar_MachineSpecialAllowed[MAX_MESSAGE_LENGTH];
/**********************************/
static int iCvar_GameModesToggle;
static int iCvar_CurrentMode;

static char sCvar_MPGameMode[16];
static char sCvar_GameModesOn[256];
static char sCvar_GameModesOff[256];

static char sCurrentMap[256];
static char sCvar_MapsOn[256];
static char sCvar_MapsOff[256];
/**********************************/
void LoadPluginTranslations()
{
	LoadTranslations("common.phrases"); // SourceMod Native (Add native SourceMod translations to the menu).
	
	static char sPath[PLATFORM_MAX_PATH];
	BuildPath( Path_SM, sPath, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME );
	if( FileExists( sPath ) )
		LoadTranslations( TRANSLATION_FILENAME );
	else
		SetFailState( "Catastrophic failure, translations file not found, file required in \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME );
}

public void OnPluginStart()
{	
	// SDKCalls
	StartPrepSDKCall(SDKCall_Static);
	
	if(!PrepSDKCall_SetSignature( SDKLibrary_Server, bLeft4DeadTwo ? "\x55\x8B\xEC\x8B\x45\x18\x81\xEC\xC0\x00\x00\x00" : "\x8B\x44\x24\x14\x81\xEC\x94\x00\x00\x00", bLeft4DeadTwo ? 12 : 10 ) ) // Cargar En Windows
		PrepSDKCall_SetSignature( SDKLibrary_Server, "@_ZN15CEntityDissolve6CreateEP11CBaseEntityPKcfiPb", 0 ); // Cargar En Linux

	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKDissolveCreate = EndPrepSDKCall();
	if( SDKDissolveCreate == null )
		SetFailState("Could not prep the \"CEntityDissolve_Create\" function.");
	
	// VomitOnPlayer
	StartPrepSDKCall(SDKCall_Player);
	
	if(!PrepSDKCall_SetSignature( SDKLibrary_Server, bLeft4DeadTwo ? "\x55\x8B\xEC\x83\xEC\x2A\x53\x56\x57\x8B\xF1\xE8\x2A\x2A\x2A\x2A\x84\xC0\x74\x2A\x8B\x06\x8B\x90" : "\x83\x2A\x2A\x53\x55\x56\x57\x8B\x2A\xE8\x2A\x2A\x2A\x2A\x84", bLeft4DeadTwo ? 24 : 15 ) )
		PrepSDKCall_SetSignature( SDKLibrary_Server, bLeft4DeadTwo ? "@_ZN13CTerrorPlayer13OnVomitedUponEPS_b" : "@_ZN13CTerrorPlayer13OnVomitedUponEPS_bb", 0 );
	
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	SDKVomitOnPlayer = EndPrepSDKCall();
	if( SDKVomitOnPlayer == null )
		SetFailState("Could not prep the CTerrorPlayer_OnVomitedUpon function.");
	
	// ShoveSurvivor
/*	StartPrepSDKCall(SDKCall_Player);
	
	if(!PrepSDKCall_SetSignature( SDKLibrary_Server, bLeft4DeadTwo ? "\x55\x8B\xEC\x81\xEC\x2A\x2A\x2A\x2A\xA1\x2A\x2A\x2A\x2A\x33\xC5\x89\x45\xFC\x53\x8B\x5D\x08\x56\x57\x8B\x7D\x0C\x8B\xF1" : "\x81\xEC\x2A\x2A\x2A\x2A\x56\x8B\xF1\xE8\x2A\x2A\x2A\x2A\x84\xC0\x0F\x2A\x2A\x2A\x2A\x2A\x8B\x8C\x2A\x2A\x2A\x2A\x2A\x85\xC9\x74", bLeft4DeadTwo ? 30 : 32 ) ) // Cargar En Windows
		PrepSDKCall_SetSignature( SDKLibrary_Server, "@_ZN13CTerrorPlayer18OnShovedBySurvivorEPS_RK6Vector", 0 ); // Cargar En Linux
	
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	SDKShoveSurvivor = EndPrepSDKCall();
	if( SDKShoveSurvivor == null )
		PrintToServer("Unable to find the 'CTerrorPlayer::OnShovedBySurvivor' signature.");
*/	
	// Stagger
	StartPrepSDKCall(SDKCall_Player);
	
	if(!PrepSDKCall_SetSignature( SDKLibrary_Server, bLeft4DeadTwo ? "\x2A\x2A\x2A\x2A\x2A\x2A\x83\x2A\x2A\x83\x2A\x2A\x55\x8B\x2A\x2A\x89\x2A\x2A\x2A\x8B\x2A\x83\x2A\x2A\x56\x57\x8B\x2A\xE8\x2A\x2A\x2A\x2A\x84\x2A\x0F\x85\x2A\x2A\x2A\x2A\x8B\x2A\x8B" : "\x83\x2A\x2A\x2A\x8B\x2A\xE8\x2A\x2A\x2A\x2A\x84\x2A\x0F\x85\x2A\x2A\x2A\x2A\x8B\x2A\x8B", bLeft4DeadTwo ? 45 : 22 ) ) // Cargar En Windows
		PrepSDKCall_SetSignature( SDKLibrary_Server, "@_ZN13CTerrorPlayer11OnStaggeredEP11CBaseEntityPK6Vector", 0 ); // Cargar En Linux
	
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	SDKStaggerClient = EndPrepSDKCall();
	if( SDKStaggerClient == null )
		SetFailState("Could not prep the 'CTerrorPlayer::OnStaggered' function.");
	
	LoadPluginTranslations();
	
	hCvar_MPGameMode 				= FindConVar("mp_gamemode");
	hCvar_Machine_Enabled 			= CreateConVar("l4d_machine_enable", 				"1", 		"Enables/Disables the plugin. 0 = Plugin OFF, 1 = Plugin ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_Machine_FinaleOnly 		= CreateConVar("l4d_machine_finale_only", 			"0", 		"Enables/Disables the use of machine guns only in final events.\n0 = Finals OFF.\n1 = Finals ON", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	hCvar_Machine_GameModesOn 		= CreateConVar("l4d_machine_gamemodes_on",  		"",   		"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", FCVAR_NOTIFY );
	hCvar_Machine_GameModesOff 		= CreateConVar("l4d_machine_gamemodes_off", 		"",   		"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", FCVAR_NOTIFY );
	hCvar_Machine_GameModesToggle 	= CreateConVar("l4d_machine_gamemodes_toggle", 		"0", 		"Turn on the plugin in these game modes.\n0 = All, 1 = Coop, 2 = Survival, 4 = Versus, 8 = Scavenge.\nAdd numbers together.", FCVAR_NOTIFY, true, 0.0, true, 15.0 );
	hCvar_Machine_MapsOn 			= CreateConVar("l4d_machine_maps_on", 				"", 		"Allow the plugin being loaded on these maps, separate by commas (no spaces). Empty = all.\nExample: \"l4d_hospital01_apartment,c1m1_hotel\"", FCVAR_NOTIFY);
	hCvar_Machine_MapsOff 			= CreateConVar("l4d_machine_maps_off", 				"", 		"Prevent the plugin being loaded on these maps, separate by commas (no spaces). Empty = none.\nExample: \"l4d_hospital01_apartment,c1m1_hotel\"", FCVAR_NOTIFY);
	
	
	hCvar_MachineDamageToInfected 	= CreateConVar("l4d_machine_damage_to_infected", 	"50", 		"Sets the amount of damage to the infected.", FCVAR_NOTIFY, true, 0.0, true, 100.0 );
	hCvar_MachineDamageToSurvivor 	= CreateConVar("l4d_machine_damage_to_survivor", 	"50", 		"Sets the amount of damage to survivors.", FCVAR_NOTIFY, true, 0.0, true, 100.0 );
	hCvar_MachineMaxAllowed 		= CreateConVar("l4d_machine_max_allowed", 			"10", 		"Sets the max number of machine guns allowed.", FCVAR_NOTIFY, true, 1.0, true, float( MAX_ALLOWED ) );
	hCvar_MachineRange 				= CreateConVar("l4d_machine_range", 				"1000", 	"Sets the max range of enemy detection by machine guns.", FCVAR_NOTIFY, true, 250.00, true, 3000.00);
	hCvar_MachineOverHeat 			= CreateConVar("l4d_machine_overheat", 				"10.0", 	"Sets the Machine Overheat according to the shooting speed, time in seconds.", FCVAR_NOTIFY, true, 5.00, true, 30.00);
	
	hCvar_MachineRequiredAccessLevel = CreateConVar("l4d_machine_required_acces_level", "", 		"Sets global access to machine guns by admin flags.\nEmpty = Allowed for everyone.", FCVAR_NOTIFY);
	hCvar_MachineBasicAdminOnly 	= CreateConVar("l4d_machine_basic_adminonly", 		"", 		"Sets access to basic machine guns by admin flags.\n0 = Allowed for everyone.", FCVAR_NOTIFY);
	hCvar_MachineSpecialAdminOnly 	= CreateConVar("l4d_machine_special_adminonly", 	"", 		"Sets access to special machine guns by admin flags.\n0 = Allowed for everyone.", FCVAR_NOTIFY);
	hCvar_MachineSpecialAllowed 	= CreateConVar("l4d_machine_special_allowed", 		"Flame,Laser,Tesla,Freeze,Nauseating", "Sets what special machine guns will be allowed", FCVAR_NOTIFY);
	
	hCvar_MachineUsageMessage 		= CreateConVar("l4d_machine_usage_message", 		"1", 		"Sets the number of times it shows usage information.\n0 = Doesn't Shows Information.", FCVAR_NOTIFY, true, 0.0, true, 5.0);
	hCvar_MachineAmmoCount 			= CreateConVar("l4d_machine_ammo_count", 			"2000", 	"Sets the amount of ammo for each machine gun", FCVAR_NOTIFY, true, 100.0, true, 10000.0);
	hCvar_MachineAmmoType 			= CreateConVar("l4d_machine_ammo_type", 			"0", 		"Sets ammunition type.\n0 = Normal Ammo.\n1 = Incendiary Ammo.\n2 = Explosive Ammo.", FCVAR_NOTIFY, true, 0.0, true, 2.0 );
	hCvar_MachineAmmoReload 		= CreateConVar("l4d_machine_ammo_reload", 			"1", 		"Enabless/Disabless reloading of machine guns.\n0 = Reload Disable.\n1 Reload Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	hCvar_MachineAllowCarry 		= CreateConVar("l4d_machine_allow_carry", 			"2", 		"Enabless/Disabless, Sets who can carry the machine guns.\n0 = Disable carry\n1 = Every One.\n2 = Only Creator.", FCVAR_NOTIFY, true, 0.0, true, 2.0 );
	hCvar_MachineAllowUse 			= CreateConVar("l4d_machine_allow_use", 			"1", 		"Enabless/Disabless manual use of machine guns, only applies to basic machine guns.\n0 = Use Disabled.\n1 = Use Enabled.", FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	hCvar_MachineSleepTime 			= CreateConVar("l4d_machine_sleep_time", 			"300.0", 	"Sets the max waiting time(seconds) to remain inactive a machine gun when there are no enemies in it's range.", FCVAR_NOTIFY, true, 60.00, true, 600.00);
	hCvar_MachineFireRate 			= CreateConVar("l4d_machine_fire_rate", 			"5", 		"Sest rate of fire, amount shots per soncod.", FCVAR_NOTIFY, true, 5.0, true, 30.0);
 	hCvar_MachineHealth 			= CreateConVar("l4d_machine_health", 				"700", 		"Sets the amount of health for each machine gun.", FCVAR_NOTIFY, true, 50.0, true, 1000.0);
	
 	hCvar_MachineBetrayChance 		= CreateConVar("l4d_machine_betray_chance", 		"0", 		"Sets the probability of being betrayed by machine guns", FCVAR_NOTIFY, true, 0.0, true, 100.0 );
	hCvar_MachineLimit 				= CreateConVar("l4d_machine_limit", 				"4", 		"Sets machine gun limit for each user.", FCVAR_NOTIFY, true, 1.0, true, float( MAX_EACHPLAYER ));
	
	hCvar_MachineEnableExplosion 	= CreateConVar("l4d_machine_enable_explosion", 		"10", 		"Sets the maximum amount of damage the explosion can cause when a machine gun has been removed/destroyed.\n0 = Explosion Disabled.", FCVAR_NOTIFY, true, 0.0, true, 100.0 );
	hCvar_MachineDroppingTime 		= CreateConVar("l4d_machine_dropping_time", 		"0.5", 		"Sets the time a machine gun will be dropped.", FCVAR_NOTIFY, true, 0.5, true, 3.0 );
//	hCvar_ = CreateConVar("l4d_machine_", "1", "", FCVAR_NOTIFY, true, 0.0, true, 1.0 );

 	AutoExecConfig( true, "l4d_machine_gun_system" );
	
	hCvar_MPGameMode.AddChangeHook( ConVarChange );
	hCvar_Machine_Enabled.AddChangeHook( ConVarChange );
	hCvar_Machine_FinaleOnly.AddChangeHook( ConVarChange );
	hCvar_Machine_GameModesOn.AddChangeHook( ConVarChange );
	hCvar_Machine_GameModesOff.AddChangeHook( ConVarChange );
	hCvar_Machine_GameModesToggle.AddChangeHook( ConVarChange );
	hCvar_Machine_MapsOn.AddChangeHook( ConVarChange );
	hCvar_Machine_MapsOff.AddChangeHook( ConVarChange );
	
	hCvar_MachineDamageToInfected.AddChangeHook( ConVarChange );
	hCvar_MachineDamageToSurvivor.AddChangeHook( ConVarChange );
	hCvar_MachineMaxAllowed.AddChangeHook( ConVarChange );
	hCvar_MachineRange.AddChangeHook( ConVarChange );
	hCvar_MachineOverHeat.AddChangeHook( ConVarChange );
	
	hCvar_MachineRequiredAccessLevel.AddChangeHook( ConVarChange );
	hCvar_MachineBasicAdminOnly.AddChangeHook( ConVarChange );
	hCvar_MachineSpecialAdminOnly.AddChangeHook( ConVarChange );
	hCvar_MachineSpecialAllowed.AddChangeHook( ConVarChange );
	
	hCvar_MachineUsageMessage.AddChangeHook( ConVarChange );
	hCvar_MachineAmmoCount.AddChangeHook( ConVarChange );
	hCvar_MachineAmmoType.AddChangeHook( ConVarChange );
	hCvar_MachineAmmoReload.AddChangeHook( ConVarChange );
	hCvar_MachineAllowCarry.AddChangeHook( ConVarChange );
	hCvar_MachineAllowUse.AddChangeHook( ConVarChange );
	hCvar_MachineSleepTime.AddChangeHook( ConVarChange );
	hCvar_MachineFireRate.AddChangeHook( ConVarChange );
	hCvar_MachineHealth.AddChangeHook( ConVarChange );
	hCvar_MachineBetrayChance.AddChangeHook( ConVarChange );
	hCvar_MachineLimit.AddChangeHook( ConVarChange );
	
	hCvar_MachineEnableExplosion.AddChangeHook( ConVarChange );
	hCvar_MachineDroppingTime.AddChangeHook( ConVarChange );

	HookEvent("player_bot_replace", Event_BotReplace, EventHookMode_Pre );
	HookEvent("witch_harasser_set", Event_WitchHarasserSet );
	HookEvent("entity_shoved", Event_EntityShoved );
	HookEvent("player_use", Event_PlayerUses );
	
//	HookEvent("bullet_impact", Event_BulletImpact);
//	HookEvent("weapon_fire", Event_WeaponFire);

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_PostNoCopy );
	HookEvent("zombie_ignited", Event_ZombieIgnited );
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	HookEvent("player_now_it", Event_IsIt, EventHookMode_Pre);
	HookEvent("player_incapacitated", Event_PlayerIncapacited, EventHookMode_Pre );

	HookEvent("round_start", Event_StartEnd, EventHookMode_PostNoCopy );
	HookEvent("round_end", Event_StartEnd, EventHookMode_PostNoCopy );
	HookEvent("finale_win", Event_StartEnd, EventHookMode_Pre );
	HookEvent("mission_lost", Event_StartEnd, EventHookMode_PostNoCopy );
	HookEvent("map_transition", Event_StartEnd, EventHookMode_Pre );
//	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	
	HookEvent("finale_start", Event_FinaleStarted, EventHookMode_Pre );
//	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving, EventHookMode_PostNoCopy );
//	HookEvent("finale_vehicle_incoming", Event_FinaleVehicleInComing, EventHookMode_PostNoCopy); // L4D2

	RegConsoleCmd( "sm_machine", CMD_SpawnMachine, "Creates a machine gun in front of the player." );
	RegConsoleCmd( "sm_removemachine", CMD_RemoveMachine, "Removes the machine gun in the crosshairs." );
	RegConsoleCmd( "sm_machinemenu", CMD_MainMenu, "Open the machine gus menu (only in-game)");
	
	RegAdminCmd( "sm_resetmachine", Cmd_ResetMachine, ADMFLAG_ROOT, "reloads the settings and remove all the spawned machine guns." );
	
	ResetAllState();
	GetConVar();
}

public void ConVarChange( ConVar hConVar, const char[] sOldValue, const char[] sNewValue )
{
	GetConVar();
}

void GetConVar()
{
	GetCurrentMap( sCurrentMap, sizeof( sCurrentMap ) );
	
	hCvar_MPGameMode.GetString( sCvar_MPGameMode, sizeof( sCvar_MPGameMode ) );
	TrimString( sCvar_MPGameMode );
	
	bCvar_Machine_Enabled = hCvar_Machine_Enabled.BoolValue;
	bCvar_Machine_FinaleOnly = hCvar_Machine_FinaleOnly.BoolValue;
	iCvar_GameModesToggle = hCvar_Machine_GameModesToggle.IntValue;
/**/	
	fCvar_MachineDamageToInfected = hCvar_MachineDamageToInfected.FloatValue;
	fCvar_MachineDamageToSurvivor = hCvar_MachineDamageToSurvivor.FloatValue;
	fCvar_MachineOverHeat = hCvar_MachineOverHeat.FloatValue;
 	fCvar_MachineRange = hCvar_MachineRange.FloatValue;
	fCvar_MachineSleepTime = hCvar_MachineSleepTime.FloatValue;
	fCvar_MachineFireRate = hCvar_MachineFireRate.FloatValue;
	fCvar_MachineHealth = hCvar_MachineHealth.FloatValue;
	fCvar_MachineDroppingTime = hCvar_MachineDroppingTime.FloatValue;
	
	iCvar_MachineMaxAllowed = hCvar_MachineMaxAllowed.IntValue;
	iCvar_MachineUsageMessage = hCvar_MachineUsageMessage.IntValue;
	iCvar_MachineAmmoCount = hCvar_MachineAmmoCount.IntValue;
	iCvar_MachineAmmoType = hCvar_MachineAmmoType.IntValue;
	iCvar_MachineAllowCarry = hCvar_MachineAllowCarry.IntValue;
	iCvar_MachineBetrayChance = hCvar_MachineBetrayChance.IntValue;
	iCvar_MachineLimit = hCvar_MachineLimit.IntValue;
	iCvar_MachineEnableExplosion = hCvar_MachineEnableExplosion.IntValue;
	
	bCvar_MachineAmmoReload = hCvar_MachineAmmoReload.BoolValue;
	bCvar_MachineAllowUse = hCvar_MachineAllowUse.BoolValue;
/**/	
	hCvar_Machine_GameModesOn.GetString( sCvar_GameModesOn, sizeof( sCvar_GameModesOn ) );
	ReplaceString( sCvar_GameModesOn, sizeof( sCvar_GameModesOn ), " ", "", false ); 	// Remove spaces in any section of the string.
	
	hCvar_Machine_GameModesOff.GetString( sCvar_GameModesOff, sizeof( sCvar_GameModesOff ) );
	ReplaceString( sCvar_GameModesOff, sizeof( sCvar_GameModesOff ), " ", "", false );
	
	hCvar_Machine_MapsOn.GetString( sCvar_MapsOn, sizeof( sCvar_MapsOn ) );
	ReplaceString( sCvar_MapsOn, sizeof( sCvar_MapsOn ), " ", "", false );
	
	hCvar_Machine_MapsOff.GetString( sCvar_MapsOff, sizeof( sCvar_MapsOff ) );
	ReplaceString( sCvar_MapsOff, sizeof( sCvar_MapsOff ), " ", "", false );
/**/	
	hCvar_MachineRequiredAccessLevel.GetString( sCvar_MachineRequiredAccessLevel, sizeof sCvar_MachineRequiredAccessLevel );
	ReplaceString( sCvar_MachineRequiredAccessLevel, sizeof sCvar_MachineRequiredAccessLevel, " ", "", false );
	
	hCvar_MachineBasicAdminOnly.GetString( sCvar_MachineBasicAdminOnly, sizeof sCvar_MachineBasicAdminOnly );
	ReplaceString( sCvar_MachineBasicAdminOnly, sizeof sCvar_MachineBasicAdminOnly, " ", "", false );
	
	hCvar_MachineSpecialAdminOnly.GetString( sCvar_MachineSpecialAdminOnly, sizeof sCvar_MachineSpecialAdminOnly );
	ReplaceString( sCvar_MachineSpecialAdminOnly, sizeof sCvar_MachineSpecialAdminOnly, " ", "", false );
	
	hCvar_MachineSpecialAllowed.GetString( sCvar_MachineSpecialAllowed, sizeof sCvar_MachineSpecialAllowed );
	TrimString( sCvar_MachineSpecialAllowed );
//	ReplaceString( sCvar_MachineSpecialAllowed, sizeof sCvar_MachineSpecialAllowed, " ", "", false );
	
	if( StrContains( sCvar_MachineSpecialAllowed, "Flame" ) >= 0 ) 
		bFlameAllowed = true;
	else 
		bFlameAllowed = false;
	
	if( StrContains( sCvar_MachineSpecialAllowed, "Laser" ) >= 0 ) 
		bLaserAllowed = true;
	else 
		bLaserAllowed = false;
	
	if( StrContains( sCvar_MachineSpecialAllowed, "Tesla" ) >= 0 ) 
		bTeslaAllowed = true;
	else 
		bTeslaAllowed = false;
	
	if( StrContains( sCvar_MachineSpecialAllowed, "Freeze" ) >= 0 ) 
		bFreezeAllowed = true;
	else 
		bFreezeAllowed = false;
	
	if( StrContains( sCvar_MachineSpecialAllowed, "Nauseating" ) >= 0 ) 
		bNauseatingAllowed = true;
	else 
		bNauseatingAllowed = false;
	
	fCvar_MachineFireRate = 1.0 / fCvar_MachineFireRate;
}

/**
 * @note Check if the current game mode is allowed and based on this it returns a boolean value.
 *
 * @return           True if game mode is valid, false otherwise.
 */
bool IsAllowedGameMode()
{
	if( hCvar_MPGameMode == null )
		return false;
	
	if( iCvar_GameModesToggle != 0 )
	{
		if( bMapStarted == false )
			return false;

		iCvar_CurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) 	// Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); 		// Because multiple plugins creating at once, avoid too many duplicate ents in the same frame.
		}

		if( iCvar_CurrentMode == 0 )
			return false;

		if( !(iCvar_GameModesToggle & iCvar_CurrentMode) )
			return false;
	}
	
	char sGameMode[256], sGameModes[256];
	Format(sGameMode, sizeof(sGameMode), ",%s,", sCvar_MPGameMode);
	
	strcopy(sGameModes, sizeof(sCvar_GameModesOn), sCvar_GameModesOn);
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}
	
	strcopy(sGameModes, sizeof(sCvar_GameModesOff), sCvar_GameModesOff);
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

/**
 * @note Sets the running game mode int value.
 *
 * @param sOutput        Output.
 * @param iCaller        Caller.
 * @param iActivator     Activator.
 * @param fDelay         Delay.
 * @noreturn
 */
public void OnGamemode(const char[] sOutput, int iCaller, int iActivator, float fDelay)
{
	if( strcmp(sOutput, "OnCoop") == 0 )
		iCvar_CurrentMode = 1;
	else if( strcmp(sOutput, "OnSurvival") == 0 )
		iCvar_CurrentMode = 2;
	else if( strcmp(sOutput, "OnVersus") == 0 )
		iCvar_CurrentMode = 4;
	else if( strcmp(sOutput, "OnScavenge") == 0 )
		iCvar_CurrentMode = 8;
}

/**
 * @note Validates if the current game mode is valid to run the plugin.
 *
 * @return           True if game mode is valid, false otherwise.
 */
bool IsAllowedMap()
{
	char sMap[256], sMaps[256];
	Format(sMap, sizeof(sMap), ",%s,", sCurrentMap);
	
	strcopy( sMaps, sizeof( sMaps ), sCvar_MapsOn );
	if( !StrEqual( sMaps, "", false ) )
	{
		Format( sMaps, sizeof( sMaps ), ",%s,", sMaps );
		if( StrContains( sMaps, sMap, false ) == -1 )
			return false;
	}
	
	strcopy( sMaps, sizeof( sMaps ), sCvar_MapsOff );
	if( !StrEqual( sMaps, "", false ) )
	{
		Format( sMaps, sizeof( sMaps ), ",%s,", sMaps );
		if( StrContains(sMaps, sMap, false) != -1 )
			return false;
	}
	
	return true;
}

void ResetAllState()
{
	MachineCount = 0;
	ScanTime = 0.0;
	InfectedCount = 0;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		GunState[i] = State_None;
		ShowMsg[i] = 0;
		GunOwner[i] = 0;
		GunCarrier[i] = 0; 
		Gun[i] = 0;
		MachineGunCounterUser[i] = 0;
		FreezedPlayer[i] = false;
		VomitedPlayer[i] = false;
		MachineGunerTime[i] = 0.0;
		Machine_RateTime[i] = 0.0;
		
		for(int iArrayNum = 0; iArrayNum < MAX_EACHPLAYER; iArrayNum ++) // Igualar a cero indice de ametralladoras congelantes.
		{
			FreezingMachineGunOwner[i][iArrayNum] = 0;
			FreezingMachineGunCount[i][iArrayNum] = -1;
		}
	}
	
	for(int i = 0; i < MAX_ALLOWED; i++ )
	{
		int entity = MachineGunSpawned[i];
		if( IsValidEntRef( entity ) )
			AcceptEntityInput( entity, "Kill" );
	}
	
//	AddNormalSoundHook( view_as<NormalSHook>( OnNormalSoundPlay ));	
	GetConVar();
}

public void OnMapStart()
{
	PrecacheModel( MODEL_PIPEBOMB, true );
	PrecacheModel( MODEL_MINIGUN_GATLING, true );
	PrecacheModel( MODEL_MINIGUN_50CAL, true );
	
	PrecacheModel( bLeft4DeadTwo ? MODEL_ANOMALY_LASER_L4D2 : MODEL_ANOMALY_LASER_L4D1, true );
	
	PrecacheModel( MODEL_CRATE, true );
	PrecacheModel( MODEL_GASCAN, true );
	
	PrecacheModel( MODEL_MUZZLEFLASH, true );

	PrecacheSound( SOUND_SHOOT_50CAL, true );
	PrecacheSound( SOUND_IMPACT_FLESH, true );
	PrecacheSound( SOUND_IMPACT_CONCRETE, true );
	
	PrecacheSound( SOUND_EXPLODE3, true );
	PrecacheSound( SOUND_EXPLODE4, true );
	PrecacheSound( SOUND_EXPLODE5, true );
	
	PrecacheSound( SOUND_FREEZER, true );
	
	PrecacheSound( bLeft4DeadTwo ? SOUND_FIRE_L4D2 : SOUND_FIRE_L4D1, true );
	
	for( int i = 0; i < sizeof sArraySoundsZap; i ++ )
		PrecacheSound( sArraySoundsZap[i], true );
	
	PrecacheParticle( PARTICLE_FIRE1 );
	PrecacheParticle( PARTICLE_FIRE2 );
	PrecacheParticle( PARTICLE_FIRE3 );
	PrecacheParticle( PARTICLE_EMBERS);
	
	PrecacheParticle( PARTICLE_TES1 );
	PrecacheParticle( PARTICLE_TES2 );
	PrecacheParticle( PARTICLE_TES3 );
	
//	PrecacheParticle( PARTICLE_SMOKE );
	PrecacheParticle( PARTICLE_WATER );
	
	PrecacheParticle( PARTICLE_VOMIT );
	
	PrecacheParticle( PARTICLE_MUZZLE_FLASH );
	
	PrecacheParticle( PARTICLE_WEAPON_TRACER_GATLING );
	PrecacheParticle( PARTICLE_WEAPON_TRACER_50CAL );
	PrecacheParticle( PARTICLE_BLOOD );
	
	PrecacheParticle( PARTICLE_GAS_EXPLOTION );
//	PrecacheParticle( PARTICLE_MOLOTOV_EXPLOTION );
//	PrecacheParticle( PARTICLE_MOLOTOV_EXPLOTION_BRANCH );
	
	LaserModelIndex = PrecacheModel( bLeft4DeadTwo ? "materials/sprites/laserbeam.vmt" : "materials/sprites/laser.vmt" );
	
	iParticleTracer_50Cal = PrecacheParticle( PARTICLE_WEAPON_TRACER_50CAL );
	iParticleTracer_Gatling = PrecacheParticle( PARTICLE_WEAPON_TRACER_GATLING );
	
	bMapStarted = true;
}

public void OnMapEnd()
{
	bMapStarted = false;
}

public void Event_StartEnd( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	ResetAllState();
	
	bFinalEvent = false;
}

public void Event_FinaleStarted( Event hEvent, const char[] sName, bool bDontBroadcast )
{	
	bFinalEvent = true;
}

public Action Event_EntityShoved( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	if( !IsAllowedPlugin() ) 
		return Plugin_Continue;
	
	if( iCvar_MachineAllowCarry == 0 )
		return Plugin_Continue;
	
	int attacker  = GetClientOfUserId( hEvent.GetInt( "attacker" ) );
	if( attacker > 0 && IsClientInGame( attacker ) && GetClientTeam( attacker ) == TEAM_SURVIVOR )
	{
		if( GetClientButtons( attacker ) & IN_DUCK )
		{
			int iEntity = GetMinigun( attacker );
			if( iEntity > 0 )
			{
				StartCarry( attacker, iEntity );
			}
		}
	}
	
	return Plugin_Continue;
}


public Action Event_PlayerUses( Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if( !IsAllowedPlugin() ) 
		return Plugin_Continue;
	
	if( !bCvar_MachineAmmoReload ) 
		return Plugin_Continue;
	
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	int entity = hEvent.GetInt( "targetid" );
	
	if( entity <= NULL || IsValidEdict( entity ) != true || IsValidEntity( entity ) != true || IsValidClient( client ) != true )
		return Plugin_Continue;
	
	char sClassName[64];
	GetEdictClassname( entity, sClassName, sizeof( sClassName ) );
	
	if( StrContains( sClassName, "ammo" ) >= 0 )
	{
		int Index = FindCarryIndex(client);
		if( Index >= 0 )
		{
			PrintHintText( client, "%t", "Reloaded Machine Gun" );
			GunAmmo[Index] = iCvar_MachineAmmoCount;
		}
	}
	
	return Plugin_Continue;
}

public void Event_BotReplace( Event Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
/*	if( !IsAllowedPlugin() ) 
		return;
*/	
	int client = GetClientOfUserId( Spawn_Event.GetInt( "player" ) );
	int bot = GetClientOfUserId( Spawn_Event.GetInt( "bot" ) );
	
	StopClientCarry( client );
	StopClientCarry( bot );
}

public void Event_WitchHarasserSet( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	if( !IsAllowedPlugin() ) 
		return;
	
	int iWitch =  hEvent.GetInt( "witchid" );
	
	if( iWitch <= NULL || IsValidEdict( iWitch ) != true || IsValidEntity( iWitch ) != true )
		return;
	
	InfectedsArray[0] = iWitch;
	for( int i = 0; i < MachineCount; i ++ )
	{
		GunEnemy[i] = iWitch;
		GunScanIndex[i] = 0;
	}
}

/* ====================================================================================================
									En La Creación De Entidades
   ==================================================================================================== */
public void OnEntityCreated( int entity, const char[] sClassname )
{
	if( strcmp( sClassname, "infected" ) == 0 )
		BurnedEntity[entity] = false;
}

public void Event_ZombieIgnited( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int common = hEvent.GetInt( "entityid" );
	if( common )
		BurnedEntity[common] = true;
}

public void Event_PlayerSpawn( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	if( IsValidClient( client ) )
		VomitedPlayer[client] = false;
}

public void Event_PlayerIncapacited( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	if( IsValidClient( client ) && VomitedPlayer[client] == true )
		CustomPrintToChatAll( "%s %t", sPluginTag, "Is Incapacitated", client );
}

public void Event_Death( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	if( IsValidClient( client ) && VomitedPlayer[client] == true )
		CustomPrintToChatAll( "%s %t", sPluginTag, "Is Dead", client );
}

public void Event_IsIt( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int userid = hEvent.GetInt( "userid" );
	int client = GetClientOfUserId( userid );
	if( IsValidClient( client ) && VomitedPlayer[client] == true )
		CustomPrintToChatAll( "%s %t", sPluginTag, "Vomited Player", client );
}

public void OnEntityDestroyed( int entity )
{
	if( entity  == INVALID_ENT_REFERENCE || !IsValidEntity( entity ) )
		return;
	
	if( IsMiniGun( entity ))
		if( MachineGunTypes[entity] == TYPE_FLAME )
			for( int i = 1; i <= 10; i ++ )
				if( IsValidEntity( entity ))
					StopSound( entity, SNDCHAN_AUTO, bLeft4DeadTwo ? SOUND_FIRE_L4D2 : SOUND_FIRE_L4D1 );
//			AddNormalSoundHook( view_as<NormalSHook>( OnNormalSoundPlay ));
}
/*
public Action OnNormalSoundPlay( int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed )
{
	if( StrEqual( sample, bLeft4DeadTwo ? SOUND_FIRE_L4D2 : SOUND_FIRE_L4D1, true ))
	{
		numClients = 0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}*/

/***********************************************************************************************************************************************/
public Action Cmd_ResetMachine( int client, int args )
{
	ResetAllState();
	CustomPrintToChat( client, "%s %t", sPluginTag, "Plugin Restarted" );
	
	return Plugin_Handled;
}

int GetMinigun( int client )
{
	int iEntity = GetClientAimTarget( client, false );
	if( iEntity > 0 )
	{
		static char sClassName[64];
		GetEdictClassname( iEntity, sClassName, sizeof( sClassName ) );
		if( StrEqual( sClassName, "prop_minigun") || StrEqual( sClassName, "prop_minigun_l4d1" ) || StrEqual( sClassName, "prop_mounted_machine_gun" ) )
			return iEntity;
		else
			iEntity = 0;
	}
	
	return iEntity;
}

public Action CMD_SpawnMachine( int client, int args )
{
	if( IsAllowedPlugin() && IsClientPlaying( client ) )
	{		
		if( !AllowAccess( client, sCvar_MachineRequiredAccessLevel ) )
		{
			CustomPrintToChat( client, "%s %t", sPluginTag, "No Access" );
			return Plugin_Handled;
		}
		
		if( MachineGunCounterUser[client] >= iCvar_MachineLimit )
		{
			CustomPrintToChat( client, "%s %t", sPluginTag, "Machine Gun Limit", iCvar_MachineLimit );
			return Plugin_Handled;
		}
		
		char sArg[25];
		GetCmdArgString( sArg, sizeof( sArg ) );
		
		if( args == 1 )
		{
			if( !AllowAccess( client, sCvar_MachineBasicAdminOnly ) )
			{
				CustomPrintToChat( client, "%s %t", sPluginTag, "No Access" );
				return Plugin_Handled;
			}
			
			if( StrEqual( sArg, "1" ) ) 
			{
				CreateMachine( client, MACHINE_MINI, NULL );
			}
			else if( StrEqual( sArg, "2" ) )
			{
				CreateMachine( client, MACHINE_50CAL, NULL );
			}
		}
		else if( args == 2 )
		{
			if( !AllowAccess( client, sCvar_MachineSpecialAdminOnly ) )
			{
				CustomPrintToChat( client, "%s %t", sPluginTag, "No Access" );
				return Plugin_Handled;
			}
			
			if( StrEqual( sArg, "1 flame" ) && bFlameAllowed ) 
			{
				CreateMachine( client, MACHINE_MINI, TYPE_FLAME );
			}
			else if( StrEqual( sArg, "1 laser" ) && bLaserAllowed ) 
			{
				CreateMachine( client, MACHINE_MINI, TYPE_LASER );
			}
			else if( StrEqual( sArg, "1 tesla" ) && bTeslaAllowed ) 
			{
				CreateMachine( client, MACHINE_MINI, TYPE_TESLA );
			}
			else if( StrEqual( sArg, "1 freeze" ) && bFreezeAllowed ) 
			{
				CreateMachine( client, MACHINE_MINI, TYPE_FREEZE );
			}
			else if( StrEqual( sArg, "1 nauseating" ) && bNauseatingAllowed )
			{
				CreateMachine( client, MACHINE_MINI, TYPE_NAUSEATING );
			}
			else if( StrEqual( sArg, "2 flame" ) && bFlameAllowed )
			{
				CreateMachine( client, MACHINE_50CAL, TYPE_FLAME );
			}
			else if( StrEqual( sArg, "2 laser" ) && bLaserAllowed ) 
			{
				CreateMachine( client, MACHINE_50CAL, TYPE_LASER );
			}
			else if( StrEqual( sArg, "2 tesla" ) && bTeslaAllowed ) 
			{
				CreateMachine( client, MACHINE_50CAL, TYPE_TESLA );
			}
			else if( StrEqual( sArg, "2 freeze" ) && bFreezeAllowed ) 
			{
				CreateMachine( client, MACHINE_50CAL, TYPE_FREEZE );
			}
			else if( StrEqual( sArg, "2 nauseating" ) && bNauseatingAllowed )
			{
				CreateMachine( client, MACHINE_50CAL, TYPE_NAUSEATING );
			}
			else if((StrContains( sArg, "1 " ) >= 0 || StrContains( sArg, "2 " ) >= 0 ) && ( !bFlameAllowed || !bLaserAllowed || !bTeslaAllowed || !bFreezeAllowed || !bNauseatingAllowed ))
			{
				CustomPrintToChat( client, "%s %t", sPluginTag, "Machine Gun Not Allowed" );
			}
			else if( AllowAccess( client, sCvar_MachineBasicAdminOnly ) )
			{
				CreateMachine( client, GetRandomInt( MACHINE_MINI, MACHINE_50CAL ), NULL );
			}
		}
		else if( AllowAccess( client, sCvar_MachineBasicAdminOnly ) )
		{
			CreateMachine( client, GetRandomInt( MACHINE_MINI, MACHINE_50CAL ), NULL );
		}
	}
	
	return Plugin_Handled;
}

bool AllowAccess( int client, const char[] sAccessSettings )
{
	int iUserFlags = GetUserFlagBits( client );
	int iSetupFlags = ReadFlagString( sAccessSettings );
	
	if( StrEqual( sAccessSettings, "0" ) ) return true;
	else if( strlen( sAccessSettings ) == 0 ) return true;
	else if( iUserFlags >= iSetupFlags || IsClientAdmin( client, ADMFLAG_ROOT ) ) return true;
	
	return false;
}

void PrintUserSelection( int client, const int iMachineGunModel, const int iSpecialType = NULL ) // Stock que permite hacer uso entre el menú y la selección del chat.
{
	static char sMachineGunModel[32];
	static char sSpecialType[32];
	
	if( iMachineGunModel == MACHINE_MINI )
		Format( sMachineGunModel, sizeof sMachineGunModel, "'Gold'%T", "Model Gatling", client );
	else 
		Format( sMachineGunModel, sizeof sMachineGunModel, "'Gold'%T", "Model 50 Cal", client );
	
	if( iSpecialType == TYPE_FLAME )
		Format( sSpecialType, sizeof sSpecialType, "'Red'%T", "Fire Type", client );
	else if( iSpecialType == TYPE_LASER )
		Format( sSpecialType, sizeof sSpecialType, "'Gold'%T", "Type Laser", client );
	else if( iSpecialType == TYPE_TESLA )
		Format( sSpecialType, sizeof sSpecialType, "'Blue'%T", "Type Tesla", client );
	else if( iSpecialType == TYPE_FREEZE )
		Format( sSpecialType, sizeof sSpecialType, "'Blue'%T", "Type Freeze", client );
	else if( iSpecialType == TYPE_NAUSEATING )
		Format( sSpecialType, sizeof sSpecialType, "'Green'%T", "Type Nauseating", client );
	
	if( iSpecialType )
		CustomPrintToChat( client, "%s %t", sPluginTag, "Special Type", sMachineGunModel, sSpecialType );
	else
		CustomPrintToChat( client, "%s %t", sPluginTag, "Common Type", sMachineGunModel );
}
/****************************************************************************************************************************************/
public Action CMD_MainMenu( int client, int args )
{
	if( IsAllowedPlugin() && args == 0 )
	{
		if( IsClientPlaying( client ) )
		{	
			if( !AllowAccess( client, sCvar_MachineRequiredAccessLevel ) )
			{
				CustomPrintToChat( client, "%s %t", sPluginTag, "No Access" );
				return Plugin_Handled;
			}
			
			if( MachineGunCounterUser[client] < iCvar_MachineLimit )
			{
				BuildMachineGunsMainMenu( client );
			}
			else if( MachineGunCounterUser[client] >= iCvar_MachineLimit )
			{
				CustomPrintToChat( client, "%s %t", sPluginTag, "Machine Gun Limit", iCvar_MachineLimit ); 
			}
		}
	}
	
	return Plugin_Handled;
}

void BuildMachineGunsMainMenu( int client )
{
	if( !AllowAccess( client, sCvar_MachineBasicAdminOnly ) && !AllowAccess( client, sCvar_MachineSpecialAdminOnly ) )
	{
		SendPanelToClient( ShowEmptinessPanel( client ), client, PanelHandler, 15 );
		return;
	}

	static char sBasicMchineGuns[128];
	static char sAdvancedMachineGuns[128];
	static char sTittle[128];
	
	Menu hMenu = new Menu( MenuHandler );
	hMenu.ExitBackButton = false;
	hMenu.ExitButton = true;
	
	Format( sBasicMchineGuns, sizeof sBasicMchineGuns, "%T", "Basic Menu", client );
	if( AllowAccess( client, sCvar_MachineBasicAdminOnly ) )
		hMenu.AddItem( "BasicMachineGuns", sBasicMchineGuns );
	
	Format( sAdvancedMachineGuns, sizeof sAdvancedMachineGuns, "%T", "Advanced Menu", client );
	if( AllowAccess( client, sCvar_MachineSpecialAdminOnly ) )
		hMenu.AddItem( "AdvancedMachineGuns", sAdvancedMachineGuns );
	
	Format( sTittle, sizeof sTittle, "%T", "Main Menu Title", client );
	hMenu.SetTitle( sTittle );
	hMenu.Display( client, MENU_TIME_FOREVER );
}

public Handle ShowEmptinessPanel( int client ) // Menú de informasión acerca de no acceso.
{
	static char sTittle[128];
	Format( sTittle, sizeof sTittle, "%T", "Main Menu Title", client );
	
	Panel hPanel = new Panel();
	hPanel.SetTitle( sTittle );
	
	hPanel.DrawText( "<---------------------------------->" );
	hPanel.DrawText( "  No Machine Guns Available" );
	hPanel.DrawText( "<---------------------------------->" );
	hPanel.DrawText( " " ); // Salto de línea simple.
	hPanel.DrawItem( "Exit" );
	
	return hPanel;
}

public int PanelHandler( Handle hPanel, MenuAction hAction, int iParam1, int iParam2 ) // Aciones del menú de no acceso.
{
	if( hAction == MenuAction_Select )
	{
		if( iParam2 == 1 )
		{
			delete hPanel;
		}
	}
	else if( hAction == MenuAction_End )
	{
		delete hPanel;
	}
}

public int MenuHandler( Menu hMenu, MenuAction hAction, int Param1, int Param2 )
{
	switch( hAction )
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
/*		case MenuAction_Cancel:
		{
			if( Param2 == MenuCancel_ExitBack )
			{
				BuildMachineGunsMainMenu( Param1 );
			}
		} */
		case MenuAction_Select:
		{			
			static char sInfo[56];
			hMenu.GetItem( Param2, sInfo, sizeof( sInfo ) );
			
			if( StrEqual( sInfo, "BasicMachineGuns" ) )
			{
				BuildBasicMachineGunsMenu( Param1 );
			}
			else if( StrEqual( sInfo, "AdvancedMachineGuns" ) )
			{
				BuildAdvancedMachineGunsMenu( Param1 );
			}
		}
	}
}

void BuildBasicMachineGunsMenu( int client )
{
	static char sGatlingMachineGun[128];
	static char sCal50MachineGun[128];
	static char sTitle[128];
	
	Menu hMenu = new Menu( MenuHandler_BasicMachineGuns );

	Format( sGatlingMachineGun, sizeof sGatlingMachineGun, "%T", "Gatling Basic Machine Gun", client );
	hMenu.AddItem( "GatlingMachineGun", sGatlingMachineGun );
	
	Format( sCal50MachineGun, sizeof sCal50MachineGun, "%T", "50 Cal Basic Machine Gun", client );
	hMenu.AddItem( "Cal50MachineGun", sCal50MachineGun );
	
	Format( sTitle, sizeof sTitle, "%T", "Secondary Menu Basic Machine Guns", client );
	hMenu.SetTitle( sTitle );
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	
	hMenu.Display( client, MENU_TIME_FOREVER );
}

public int MenuHandler_BasicMachineGuns( Menu hMenu, MenuAction hAction, int Param1, int Param2 )
{
	switch( hAction )
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
		case MenuAction_Cancel:
		{
			if( Param2 == MenuCancel_ExitBack )
			{
				BuildMachineGunsMainMenu( Param1 );
			}
		}
		case MenuAction_Select:
		{
			static char sInfo[56];
			hMenu.GetItem( Param2, sInfo, sizeof( sInfo ) );
			
			if( StrEqual( sInfo, "GatlingMachineGun", false ) )
			{
				CreateMachine( Param1, MACHINE_MINI, NULL );
			}
			else if( StrEqual( sInfo, "Cal50MachineGun", false ) )
			{
				CreateMachine( Param1, MACHINE_50CAL, NULL );
			}
		}
	}
}

void BuildAdvancedMachineGunsMenu( int client )
{
	static char sTitle[128];
	static char sBuffer[128];
	
	Menu hMenu = new Menu( MenuHandler_AdvancedMachineGuns );
	
	Format( sBuffer, sizeof sBuffer, "%T", "Gatling Fire-Type", client );
	if( bFlameAllowed )
		hMenu.AddItem( "GATLING_FIRE", sBuffer );
	
	Format( sBuffer, sizeof sBuffer, "%T", "Gatling Laser-Type", client );
	if( bLaserAllowed )
		hMenu.AddItem( "GATLING_LASER", sBuffer );
	
	Format( sBuffer, sizeof sBuffer, "%T", "Gatling Tesla-Type", client );
	if( bTeslaAllowed )
		hMenu.AddItem( "GATLING_TESLA", sBuffer );
	
	Format( sBuffer, sizeof sBuffer, "%T", "Gatling Freeze-Type", client );
	if( bFreezeAllowed )
		hMenu.AddItem( "GATLING_FREEZE", sBuffer );
	
	Format( sBuffer, sizeof sBuffer, "%T", "Gatling Nauseating-Type", client );
	if( bNauseatingAllowed )
		hMenu.AddItem( "GATLING_NAUSEATING", sBuffer );
	
	Format( sBuffer, sizeof sBuffer, "%T", "50 Cal Fire-Type", client );
	if( bFlameAllowed )
		hMenu.AddItem( "50CAL_FIRE", sBuffer );
	
	Format( sBuffer, sizeof sBuffer, "%T", "50 Cal Laser-Type", client );
	if( bLaserAllowed )
		hMenu.AddItem( "50CAL_LASER", sBuffer );
	
	Format( sBuffer, sizeof sBuffer, "%T", "50 Cal Tesla-Type", client );
	if( bTeslaAllowed )
		hMenu.AddItem( "50CAL_TESLA", sBuffer );
	
	Format( sBuffer, sizeof sBuffer, "%T", "50 Cal Freeze-Type", client );
	if( bFreezeAllowed )
		hMenu.AddItem( "50CAL_FREEZE", sBuffer );
	
	Format( sBuffer, sizeof sBuffer, "%T", "Cal 50 Nauseating-Type", client );
	if( bNauseatingAllowed )
		hMenu.AddItem( "50CAL_NAUSEATING", sBuffer );
	
	Format( sTitle, sizeof sTitle, "%T", "Secondary Menu Advanced Machine Gun", client );
	hMenu.SetTitle( sTitle );
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	
	hMenu.Display( client, MENU_TIME_FOREVER );
}

public int MenuHandler_AdvancedMachineGuns( Menu hMenu, MenuAction hAction, int Param1, int Param2 )
{
	switch( hAction )
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
		case MenuAction_Cancel:
		{
			if( Param2 == MenuCancel_ExitBack )
			{
				BuildMachineGunsMainMenu( Param1 );
			}
		}
		case MenuAction_Select:
		{
			static char sInfo[56];
			hMenu.GetItem( Param2, sInfo, sizeof( sInfo ) );
			
			if( StrEqual( sInfo, "GATLING_FIRE", false ) )
			{				
				CreateMachine( Param1, MACHINE_MINI, TYPE_FLAME );
			}
			else if( StrEqual( sInfo, "GATLING_LASER", false ) )
			{	
				CreateMachine( Param1, MACHINE_MINI, TYPE_LASER );
			}
			else if( StrEqual( sInfo, "GATLING_TESLA", false ) )
			{
				CreateMachine( Param1, MACHINE_MINI, TYPE_TESLA );
			}
			else if( StrEqual( sInfo, "GATLING_FREEZE", false ) )
			{
				CreateMachine( Param1, MACHINE_MINI, TYPE_FREEZE );
			}
			else if( StrEqual( sInfo, "GATLING_NAUSEATING", false ) )
			{
				CreateMachine( Param1, MACHINE_MINI, TYPE_NAUSEATING );
			}
			else if( StrEqual( sInfo, "50CAL_FIRE", false ) )
			{
				CreateMachine( Param1, MACHINE_50CAL, TYPE_FLAME );
			}
			else if( StrEqual( sInfo, "50CAL_LASER", false ) )
			{
				CreateMachine( Param1, MACHINE_50CAL, TYPE_LASER );
			}
			else if( StrEqual( sInfo, "50CAL_TESLA", false ) )
			{
				CreateMachine( Param1, MACHINE_50CAL, TYPE_TESLA );
			}
			else if( StrEqual( sInfo, "50CAL_FREEZE", false ) )
			{
				CreateMachine( Param1, MACHINE_50CAL, TYPE_FREEZE );
			}
			else if( StrEqual( sInfo, "50CAL_NAUSEATING", false ) )
			{
				CreateMachine( Param1, MACHINE_50CAL, TYPE_NAUSEATING );
			}
		}
	}
}
/****************************************************************************************************************************************/
public Action CMD_RemoveMachine( int client, int args )
{
	if( client > 0 && IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		int iEntity = GetMinigun(client);
		int iIndex = FindGunIndex(iEntity);
		if( iIndex < 0 )
			return Plugin_Handled;
		
		int owner = GunOwner[iIndex];
		if( owner == client )
		{
			RemoveMachine( iIndex, client );
		}
		else if( IsClientAdmin( client, ADMFLAG_GENERIC ) )
		{
			RemoveMachine( iIndex, owner );
			CustomPrintToChat( client, "%s %t", sPluginTag, "Admin Removed Entity", owner );
		}
		else if( owner > 0 && IsClientInGame( owner ) && IsPlayerAlive( owner ) )
		{
			PrintHintText( client, "%t", "Without Access Entity", owner );
		}
	}
	
	return Plugin_Handled;
}

public Action ShowInfo( Handle hTimer, DataPack hPack )
{	
	hPack.Reset( false );
	int client = GetClientOfUserId( hPack.ReadCell() );
	int iEntity = EntRefToEntIndex( hPack.ReadCell() );
	CloseHandle( hPack );
	
	if( !IsValidClient( client ) || !IsValidEntity( iEntity ) )
		return;
	
	if( bLeft4DeadTwo ) 
		DisplayHint( client, iEntity );
	else
		CustomPrintToChat(client, "%s %t", sPluginTag, "Use Instructor" );
}

void DisplayHint( int client, int entity )
{	
	ClientCommand( client, "gameinstructor_enable 1");
	
	DataPack hPack = new DataPack();
	hPack.WriteCell( GetClientUserId( client ) );
	hPack.WriteCell( EntIndexToEntRef( entity ) );
	
	CreateTimer( 1.0, DelayDisplayHint, hPack, TIMER_FLAG_NO_MAPCHANGE ); // Temporizador necesario, de lo contrario no aparece el instructor.
}

public Action DelayDisplayHint( Handle hTimer, DataPack hPack )
{
	hPack.Reset( false );
	int client = GetClientOfUserId( hPack.ReadCell() );
	int iEntity = EntRefToEntIndex( hPack.ReadCell() );
	CloseHandle( hPack );
	
	char sMessage[256];
	Format( sMessage, sizeof sMessage, "%T", "Use Instructor", client );
//	Format( sMessage, sizeof sMessage, "Pʀᴇsɪᴏɴᴀ 'Cᴛʀʟ + Eᴍᴘᴜᴊᴀʀ' Pᴀʀᴀ Lʟᴇᴠᴀʀ Lᴀ Aᴍᴇᴛʀᴀʟʟᴀᴅᴏʀᴀ" ); // Solo para prueba.
	RemoveColorCodes( sMessage, sizeof sMessage );
	DisplayInstructorHint( client, sMessage, "icon_interact", GetColorIndex( GetMachineGunColor( iEntity ) ) );
}

int GetMachineGunColor( int entity ) // En SM 1.10 Se puede poner un valor de retorno directo sin un bloque de momería, pero en SM 1.9 genera errores de código inaccesible.
{
	int iColorIndex;
	
	switch( MachineGunTypes[entity] )
	{
		case TYPE_FLAME: iColorIndex = 5;
		case TYPE_LASER: iColorIndex = 1;
		case TYPE_TESLA: iColorIndex = 11;
		case TYPE_FREEZE: iColorIndex = 3;
		case TYPE_NAUSEATING: iColorIndex = 10;
		default: iColorIndex = 2;
	}
	
	return iColorIndex;
}

public void DisplayInstructorHint( int client, char sMessage[256], const char[] sHintIcon, const char[] sColor )
{ 
	char sTargetName[32];
	
	int iEntity = CreateEntityByName( "env_instructor_hint" );
	if( iEntity == -1 )
	{
		LogError( "Failed to create 'env_instructor_hint' entity" );
		return;
	}
	
	FormatEx(sTargetName, sizeof sTargetName, "hint%d", client);
	ReplaceString(sMessage, sizeof sMessage, "\n", " ");
	
	DispatchKeyValue(client, "targetname", sTargetName);
	DispatchKeyValue(iEntity, "hint_target", sTargetName);
	DispatchKeyValue(iEntity, "hint_timeout", "5");
	DispatchKeyValue(iEntity, "hint_range", "0.01");
	DispatchKeyValue(iEntity, "hint_color", sColor);
	DispatchKeyValue(iEntity, "hint_icon_onscreen", sHintIcon);
	DispatchKeyValue(iEntity, "hint_caption", sMessage);
//	DispatchKeyValue(iEntity, "hint_binding", "+attack2");
	DispatchSpawn(iEntity);
	AcceptEntityInput(iEntity, "ShowHint");
	
	DataPack hPack = new DataPack();
	hPack.WriteCell( GetClientUserId( client ) );
	hPack.WriteCell( EntIndexToEntRef( iEntity ) );
	
	CreateTimer( 5.0, RemoveInstructorHint, hPack, TIMER_FLAG_NO_MAPCHANGE );
}

public Action RemoveInstructorHint( Handle hTimer, DataPack hPack )
{	
	hPack.Reset( false );
	int client = GetClientOfUserId( hPack.ReadCell() );
	int iEntity = EntRefToEntIndex( hPack.ReadCell() );
	CloseHandle( hPack );
	
	if( !IsClientPlaying( client ) )
		return;

	if( IsValidEntity( iEntity ) )
		RemoveEdict( iEntity );
	
	ClientCommand( client, "gameinstructor_enable 0" );
	DispatchKeyValue( client, "targetname", "" );
}

stock int PrecacheParticle( const char[] sEffectName )
{
	static int iTable = INVALID_STRING_TABLE;

	if( iTable == INVALID_STRING_TABLE )
		iTable = FindStringTable("ParticleEffectNames");

	int iIndex = FindStringIndex( iTable, sEffectName );
	if( iIndex == INVALID_STRING_INDEX )
	{
		bool bSave = LockStringTables( false );
		AddToStringTable( iTable, sEffectName );
		LockStringTables( bSave );
		iIndex = FindStringIndex( iTable, sEffectName );
	}

	return iIndex;
}
/****************************************************************************************************************************************/
void DealDamage( int victim, int attacker = 0, int iTeam, int iSpecialType = NULL, const float vStartingPos[3], const float vEndPos[3] )
{
	float fDamageIndex = iTeam == 2 ? fCvar_MachineDamageToInfected : fCvar_MachineDamageToSurvivor;
	float fDamage = fDamageIndex;
	
	int DMG_TYPE = DMG_GENERIC;
	int DMG_EXPLOSIVETYPE = DMG_BULLET;
	
	int DMG_EXPLOSIVE = (DMG_HEADSHOT - DMG_PLASMA - DMG_PHYSGUN - DMG_BLAST - DMG_BULLET) * -1; 	// Bala Explosiva, Solo En Left 4 Dead 2
	int DMG_INCENDIARY = (DMG_HEADSHOT - DMG_PLASMA - DMG_BURN - DMG_BULLET) * -1; 					// Bala Incendiaria, Solo En Left 4 Dead 2
	
//	if( IsTank( victim ) && !bLeft4DeadTwo )
	if( IsValidInfected( victim ) == TANK && !bLeft4DeadTwo )
		DMG_EXPLOSIVETYPE = DMG_BULLET; 
	else
		DMG_EXPLOSIVETYPE = bLeft4DeadTwo ? DMG_EXPLOSIVE : DMG_BLAST; 
	
	if( iCvar_MachineAmmoType == 0 ) 		DMG_TYPE = DMG_BULLET;
	else if( iCvar_MachineAmmoType == 1 ) 	DMG_TYPE = bLeft4DeadTwo ? DMG_INCENDIARY : DMG_BURN; 	// Munición Incendiaria.
	else if( iCvar_MachineAmmoType == 2 ) 	DMG_TYPE = DMG_EXPLOSIVETYPE; 							// Munición Explosiva.
	
//	if( iSpecialType == TYPE_FLAME ) 		DMG_TYPE = DMG_BURN;
	if( iSpecialType == TYPE_LASER ) 		DMG_TYPE = IsInfected( victim ) ? DMG_BLAST : DMG_ENERGYBEAM; // Láser o haz de alta energía.
	else if( iSpecialType == TYPE_TESLA ) 	DMG_TYPE = IsInfected( victim ) ? DMG_BURN : DMG_PLASMA;
	else if( iSpecialType == TYPE_FREEZE ) 	DMG_TYPE = DMG_SONIC;
	else if( iSpecialType == TYPE_FLAME )
	{
		fDamage = GetDamageDistance( vStartingPos, vEndPos, fDamageIndex ); // Multiplica el daño basado en la distancia.
		DMG_TYPE = GetDistanceDamageType( vStartingPos, vEndPos ); 			// Regresa varios tipos de daño basado en la distancia.
	}
	
	if( fDamage < 1.0 )
		fDamage = 1.0;
		
	HurtTarget( attacker, fDamage, DMG_TYPE, victim );
	
	if( iSpecialType == TYPE_TESLA && IsInfected( victim ) )
		CreateTimer( 0.2, DissolveCommonDelay, EntIndexToEntRef( victim ), TIMER_FLAG_NO_MAPCHANGE );
}

float GetDamageDistance( const float vStartingPos[3], const float vEndPos[3], const float fDamage )
{
	float vDis = GetVectorDistance( vStartingPos, vEndPos );
	
	if( vDis <= 50.0 )
		return fDamage * 5;
	else if( vDis <= 100.0 )
		return fDamage * 4;
	else if( vDis <= 150.0 )
		return fDamage * 3;
	else if( vDis <= 200.0 )
		return fDamage * 2;
	else if( vDis <= 250.0 )
		return fDamage;
	
	return fDamage;
}

int GetDistanceDamageType( const float vStartingPos[3], const float vEndPos[3] )
{
	float vDis = GetVectorDistance( vStartingPos, vEndPos );
	int DMG_TYPE = DMG_BULLET;
	
	if( vDis <= 130.0 )
		return DMG_BURN;
	else if( vDis <= 200.0 )
		return DMG_RADIATION;
	else if( vDis <= 250.0 )
		return DMG_NERVEGAS;
	
	return DMG_TYPE;
}

stock void HurtTarget( int attacker, float fDamage, int DMG_TYPE = DMG_GENERIC, int victim )
{
	if( victim > 0 )
	{
/*		char sDamage[16];
		char sDMG_TYPE[16];
		FloatToString( fDamage, sDamage, sizeof( sDamage ) );
		IntToString( DMG_TYPE, sDMG_TYPE, sizeof( sDMG_TYPE ) );
		
		int PointHurt = CreateEntityByName( "point_hurt" );
		if( PointHurt )
		{
			DispatchKeyValue( victim, "targetname", "hurtme" );
			DispatchKeyValue( PointHurt, "DamageTarget", "hurtme" );
			DispatchKeyValue( PointHurt, "Damage", sDamage );
			DispatchKeyValue( PointHurt, "DamageType", sDMG_TYPE );
			DispatchKeyValue( PointHurt, "classname", "weapon_rifle" );
			DispatchSpawn( PointHurt );
			AcceptEntityInput( PointHurt, "Hurt", attacker > 0 ? attacker : -1 );
			DispatchKeyValue( PointHurt, "classname", "point_hurt" );
			DispatchKeyValue( victim, "targetname", "donthurtme" );
			RemoveEdict( PointHurt );
		}
*/		
		int inflictor = attacker;
		SDKHooks_TakeDamage( victim, inflictor < 0 ? 0 : inflictor, attacker <= 0 ? -1 : attacker, fDamage, DMG_TYPE ); // Funsión nativa de Sourcemod, funciona igual que las lineas anteriores.
	} 																													// Pero cuanta con una respuesta mas rápida.
}
/****************************************************************************************************************************************/
void ScanEnemys()
{
	if( IsWitch( InfectedsArray[0] ))
		InfectedCount = 1;
	else 
		InfectedCount = 0;

	for(int i = 1; i <= MaxClients; i ++ )
		if( IsClientInGame( i ) && IsPlayerAlive( i ))
			InfectedsArray[InfectedCount++] = i;
	
	int entity = -1;
	while(( entity = FindEntityByClassname( entity, "infected" )) != -1 && InfectedCount < EnemyArraySize - 1 )
		InfectedsArray[InfectedCount++] = entity;
}
/****************************************************************************************************************************************/
stock bool IsValidClient( int client )
{
	return client > 0 && client <= MaxClients && IsClientInGame( client ) && !IsClientInKickQueue( client );
}

stock bool IsClientValidAdmin( int client )
{	
	if( !IsClientConnected( client ) || !IsClientInGame( client ) || !IsValidClient( client ) || IsFakeClient( client ) )
		return false;
	
	return true;
}

stock bool IsClientAdmin( int client, int AdminFlags )
{
	if( !IsClientValidAdmin( client ) )
		return false;
	
	return CheckCommandAccess( client, "sm_admin", AdminFlags, true );
}

stock bool IsClientPlaying( int client )
{	
	if( IsValidClient( client ) && IsClientConnected( client ) && IsPlayerAlive( client ) && GetClientTeam( client ) > TEAM_SPECTATOR )
		return true;
	
	return false;
}

stock bool IsInfected( int infected )
{
	if( IsValidEdict( infected ) && IsValidEntity( infected ) )
	{
		static char sClassName[32];
		GetEdictClassname( infected, sClassName, sizeof( sClassName ) );
		if( StrEqual( sClassName, "infected" ) )
			return true;
	}
	
	return false;
}

stock bool IsWitch( int witch )
{
	if( IsValidEdict( witch ) && IsValidEntity( witch ) )
	{
		static char sClassName[32];
		GetEdictClassname( witch, sClassName, sizeof( sClassName ) );
		if( StrEqual( sClassName, "witch" ) )
			return true;
	}
	
	return false;
}

/**
 * Validates if the current client is valid to run the plugin.
 *
 * @param client		The client index.
 * @return              False if the client is not the Tank, true otherwise.
 */
stock int IsValidInfected( int client )
{
	if( client > 0 && client <= MaxClients && IsClientInGame( client ) && GetClientTeam( client ) == TEAM_INFECTED )
	{
		int ZombieClass = GetEntProp( client, Prop_Send, "m_zombieClass" );
	
		if( ZombieClass == SMOKER ) 							return SMOKER; 	// Smoker
		else if( ZombieClass == BOOMER ) 						return BOOMER; 	// Boomer
		else if( ZombieClass == HUNTER ) 						return HUNTER; 	// Hunter
		else if( ZombieClass == SPITTER && bLeft4DeadTwo ) 		return SPITTER; // Spitter
		else if( ZombieClass == JOCKEY && bLeft4DeadTwo ) 		return JOCKEY; 	// Jockey
		else if( ZombieClass == CHARGER && bLeft4DeadTwo ) 		return CHARGER; // Charger
		else if( ZombieClass == ( bLeft4DeadTwo ? 8 : 5 )) 		return TANK; 	// Tank
	}
	
	return NULL;
}

/**
 * @note Validates if the current client is valid to run the plugin.
 *
 * @param client		The client index.
 * @return              False if the client is not the Tank, true otherwise.
 *//*
stock bool IsTank( int client )
{
	if( client > 0 && client <= MaxClients && IsClientInGame( client ) && GetClientTeam( client ) == TEAM_INFECTED )
		if( GetEntProp( client, Prop_Send, "m_zombieClass" ) == ( bLeft4DeadTwo ? 8 : 5 ) )
			return true;
	
	return false;
}
*/
stock bool IsPlayerGhost( int client )
{
	if( GetEntProp( client, Prop_Send, "m_isGhost", 1 ) ) 
		return true;
	
	return false;
}

stock bool IsPlayerIncapacitated( int client )
{
	if( GetEntProp( client, Prop_Send, "m_isIncapacitated", 1 ) ) 
		return true;
	
	return false;
}

stock bool IsValidEntRef( int entity )
{
	if( entity && EntRefToEntIndex( entity ) != INVALID_ENT_REFERENCE )
		return true;
	
	return false;
}

bool IsAllowedPlugin()
{
	if( !bCvar_Machine_Enabled || !IsAllowedGameMode() || !IsAllowedMap() || !IsFinale() ) 
		return false;
	
	return true;
}

bool IsFinale()
{
	if( !bCvar_Machine_FinaleOnly || ( bCvar_Machine_FinaleOnly && bFinalEvent ) )
		return true;
	
	return false;
}
/****************************************************************************************************************************************/
void CreateMachine( int client, int iMachineGunModel, int iSpecialType = NULL )
{
	if( !IsClientPlaying( client ) )
	{
		CustomPrintToChat( client, "%s %t", sPluginTag, "Out Of The Game" );
		return;
	}
	
	if( MachineCount >= iCvar_MachineMaxAllowed )
	{
		CustomPrintToChat( client, "%s %t", sPluginTag, "Too Many Machine Guns", MachineCount, iCvar_MachineMaxAllowed );
		return;
	}

	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		if(!(GetEntityFlags( client ) & FL_ONGROUND ) )
			return;
		
		Gun[MachineCount] = SpawnMiniGun( client, MachineCount, iMachineGunModel, iSpecialType );
		int iEntity = Gun[MachineCount];
		
		PrintUserSelection( client, iMachineGunModel, iSpecialType ); // Imprime en el chat información acerca de la ametralladora creada.
/**********************************************************************************************************************************************************/		
		if( MachineGunTypes[iEntity] == TYPE_FREEZE )
		{			
			for(int iArrayNum = 0; iArrayNum < MAX_EACHPLAYER; iArrayNum ++) // Busca una una matríz negativa para escribir sobre ella el indice de conteo.
			{
				if( FreezingMachineGunCount[client][iArrayNum] == -1 )
				{
					SetDataArray( client, iEntity, iArrayNum );
					break;
				}
				else if( FreezingMachineGunCount[client][iArrayNum] == -1 )
				{	
					SetDataArray( client, iEntity, iArrayNum );
					break;
				}
				else if( FreezingMachineGunCount[client][iArrayNum] == -1 )
				{
					SetDataArray( client, iEntity, iArrayNum );
					break;
				}
				else if( FreezingMachineGunCount[client][iArrayNum] == -1 )
				{	
					SetDataArray( client, iEntity, iArrayNum );
					break;
				}
				else if( FreezingMachineGunCount[client][iArrayNum] == -1 )
				{
					SetDataArray( client, iEntity, iArrayNum );
					break;
				}
			}
		}
/**********************************************************************************************************************************************************/			
		GunState[MachineCount] = State_Scan;
		LastTime[MachineCount] = GetEngineTime();
		Broken[MachineCount] = false;

		GunScanIndex[MachineCount] = 0;
		GunEnemy[MachineCount] = 0;
		GunFireTime[MachineCount] = 0.0;
		GunFireStopTime[MachineCount] = 0.0;
		GunFireTotolTime[MachineCount] = 0.0;
		GunOwner[MachineCount] = client;
		GunUser[MachineCount] = client;
		GunCarrier[MachineCount] = 0;
		GunTeam[MachineCount] = 2;
		AmmoIndicator[MachineCount] = 0;
		GunLastCarryTime[MachineCount] = GetEngineTime();
		
		GunAmmo[MachineCount] = iCvar_MachineAmmoCount;
		GunHealth[MachineCount] = fCvar_MachineHealth;
		
		SDKUnhook( Gun[MachineCount], SDKHook_Think,  PreThinkGun );
		SDKHook( Gun[MachineCount], SDKHook_Think,  PreThinkGun );

		MachineGunCounterUser[client] ++;
		if( MachineCount == 0 )
			ScanEnemys();

		if( ShowMsg[client] < iCvar_MachineUsageMessage )
		{
			ShowMsg[client]++;
			
			DataPack hPack = new DataPack();
			hPack.WriteCell( GetClientUserId( client ) );
			hPack.WriteCell( EntIndexToEntRef( iEntity ) );
			
			CreateTimer( 1.0, ShowInfo, hPack, TIMER_FLAG_NO_MAPCHANGE );
		}

		MachineCount++;

		SDKUnhook( iEntity, SDKHook_OnTakeDamagePost, OnTakeDamagePost );
		SDKHook( iEntity, SDKHook_OnTakeDamagePost, OnTakeDamagePost );
		
		SDKUnhook( iEntity, SDKHook_Use, OnEntityUse );
		SDKHook( iEntity, SDKHook_Use, OnEntityUse );
		
//		SDKUnhook( iEntity, SDKHook_UsePost, OnEntityPostUse );
//		SDKHook( iEntity, SDKHook_UsePost, OnEntityPostUse );
	}
}

void SetDataArray( int client, int iEntity, int iArrayNum )
{
	FreezingMachineGunOwner[client][iArrayNum] = EntIndexToEntRef( iEntity );
	FreezingMachineGunCount[client][iArrayNum] = iArrayNum;
}

void RemoveMachine( int index, int client )
{
	if( GunState[index] == State_None )
		return;
	
	GunState[index] = State_None;
	SDKUnhook( Gun[index], SDKHook_Think,  PreThinkGun );
	SDKUnhook( Gun[index], SDKHook_OnTakeDamagePost, OnTakeDamagePost );
	
	if( Gun[index] > 0 && IsValidEdict( Gun[index]) && IsValidEntity(Gun[index] ) )
	{
		if( MachineGunTypes[Gun[index]] == TYPE_FREEZE )
		{
			if( IsValidClient( client ) )
			{
				for(int iArrayNum = 0; iArrayNum < MAX_EACHPLAYER; iArrayNum ++)
				{
					if( IsValidEntRef( FreezingMachineGunOwner[client][iArrayNum] ) )
					{
						if( EntRefToEntIndex( FreezingMachineGunOwner[client][iArrayNum] ) == Gun[index] )
						{
							switch( iArrayNum )
							{
								case 0: FreezingMachineGunCount[client][iArrayNum] = -1;
								case 1: FreezingMachineGunCount[client][iArrayNum] = -1;
								case 2: FreezingMachineGunCount[client][iArrayNum] = -1;
								case 3: FreezingMachineGunCount[client][iArrayNum] = -1;
								case 4: FreezingMachineGunCount[client][iArrayNum] = -1;
							}
							
							break;
						}
					}
				}
			}
		}
		
		ExplodeMachine( Gun[index] );
		AcceptEntityInput( ( Gun[index] ), "Kill" ); // Eliminar la entidad de ametralladora
	}
	
	Gun[index] = 0;
	
	if( MachineCount > 1 )
	{
		Gun[index] = Gun[MachineCount - 1];
		GunState[index] = GunState[MachineCount - 1];
		LastTime[index] = LastTime[MachineCount - 1];
		Broken[index] = Broken[MachineCount - 1];
		GunScanIndex[index] = GunScanIndex[MachineCount - 1];
		GunEnemy[index] = GunEnemy[MachineCount - 1];
		GunFireTime[index] = GunFireTime[MachineCount - 1];
		GunFireStopTime[index] = GunFireStopTime[MachineCount - 1];
		GunFireTotolTime[index] = GunFireTotolTime[MachineCount - 1];
		GunOwner[index] = GunOwner[MachineCount - 1];
		GunUser[index] = GunUser[MachineCount - 1];
		GunCarrier[index] = GunCarrier[MachineCount - 1];
		GunLastCarryTime[index] = GunLastCarryTime[MachineCount - 1];
		GunAmmo[index] = GunAmmo[MachineCount - 1];
		AmmoIndicator[index] = AmmoIndicator[MachineCount - 1];
		GunHealth[index]  = GunHealth[MachineCount - 1];
		GunTeam[index] = GunTeam[MachineCount - 1];
		GunType[index] = GunType[MachineCount - 1];
	}
	
	MachineCount --; 						// Contador global de ametralladoras.

	if( MachineCount < 0 ) 
		MachineCount = 0;
	
	if( !client )
		return;
	
	MachineGunCounterUser[client] --; 		// Contador global por usuario de ametralladoras.
	
	if( MachineGunCounterUser[client] < 0 )
		MachineGunCounterUser[client] = 0;
}

int SpawnMiniGun( int client, int index, int iMachineGunModel, int iSpecialType = NULL )
{
	int iCountIndex = -1;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( !IsValidEntRef( MachineGunSpawned[i] ) )
		{
			iCountIndex = i;
			break;
		}
	}

	if( iCountIndex == -1 ) 
		return 0;
	
	static float VecOrigin[3];
	static float VecAngles[3];
	static float VecDirection[3];
	
	static int iEntity = -1;
	
	if( iMachineGunModel == MACHINE_MINI )
	{
		iEntity = CreateEntityByName( bLeft4DeadTwo ? "prop_minigun_l4d1" : "prop_minigun" );
		SetEntityModel( iEntity, MODEL_MINIGUN_GATLING );
		GunType[index] = MACHINE_MINI;
	}
	else if( iMachineGunModel == MACHINE_50CAL )
	{
		iEntity = CreateEntityByName( bLeft4DeadTwo ? "prop_minigun" : "prop_mounted_machine_gun" );
		SetEntityModel( iEntity, MODEL_MINIGUN_50CAL );
		GunType[index] = MACHINE_50CAL;
	}
	
	MachineGunTypes[iEntity] = NULL; // Evita algún posible error entre ametralladoras normales y especiales.
	bAllowSound[iEntity] = false;
	
	if( iSpecialType == TYPE_FLAME )
	{
		MachineGunTypes[iEntity] = TYPE_FLAME;
		AttachFlashHider( iEntity, PARTICLE_FIRE3 );
		bAllowSound[iEntity] = true;
	}
	else if( iSpecialType == TYPE_LASER )
	{
		MachineGunTypes[iEntity] = TYPE_LASER;
	}
	else if( iSpecialType == TYPE_TESLA )
	{
		MachineGunTypes[iEntity] = TYPE_TESLA;
		AttachFlashHider( iEntity, PARTICLE_TES2, bLeft4DeadTwo ? 0.2 : 0.5, true );
		CreateLight( iEntity, "0 0 255 255" ); // Color Azul
		bAllowSound[iEntity] = true;
	}
	else if( iSpecialType == TYPE_FREEZE )
	{
		MachineGunTypes[iEntity] = TYPE_FREEZE;
		bSpecialBulletsAllowed[iEntity] = false;
		
		CreateTimer( 4.0, Timer_Freeze, EntIndexToEntRef( iEntity ), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
		CreateTimer( RechargeTimers[INDEX_FREEZE], Freeze_Recharge_Timer, EntIndexToEntRef( iEntity ), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
	else if( iSpecialType == TYPE_NAUSEATING )
	{
		MachineGunTypes[iEntity] = TYPE_NAUSEATING;
		bSpecialBulletsAllowed[iEntity] = false;
		
		CreateTimer( RechargeTimers[INDEX_NAUSEATING], Vomit_Recharge_Timer, EntIndexToEntRef( iEntity ), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
	
	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	
	VecOrigin[0] += VecDirection[0] * 45;
	VecOrigin[1] += VecDirection[1] * 45;
	VecOrigin[2] += VecDirection[2];
	
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	
	DispatchKeyValueVector(iEntity, "Origin", VecOrigin);
	DispatchKeyValueVector(iEntity, "Angles", VecAngles);
	
	TeleportEntity(iEntity, VecOrigin, VecAngles, NULL_VECTOR); // Las dos lineas de arriba hacen la misma función.
	
	if( iSpecialType == TYPE_FLAME )
		DisplayParticle( iEntity, PARTICLE_EMBERS, VecOrigin, VecAngles, 0.5 );
	
	MachineGunSpawned[iCountIndex] = EntIndexToEntRef( iEntity );
	
	DispatchKeyValueFloat(iEntity, "MaxPitch",  45.00); // Funciones innecesarias en caso de que la ametralladora sea inaccesible.
	DispatchKeyValueFloat(iEntity, "MinPitch", -45.00);
	DispatchKeyValueFloat(iEntity, "MaxYaw", 90.00);
	DispatchSpawn(iEntity);

	SetEntProp( iEntity, Prop_Send, "m_iTeamNum", 2 );
	
//	SetEntProp( iEntity, Prop_Data, "m_CollisionGroup", 2 );
	StartGlowing( iEntity, TEAM_SURVIVOR );

	return iEntity;
}

stock void AttachFlashHider( int minigun, const char[] sParticleName, float fRefire = 0.0, bool bRepetitiveParticle = false )
{
	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", sParticleName);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	SetVariantString("!activator");
	AcceptEntityInput(particle, "SetParent", minigun);
	SetVariantString("muzzle_flash");
	AcceptEntityInput(particle, "SetParentAttachment");
//	MachineGunSpawned[index][INDEX_PARTICLE] = EntIndexToEntRef(particle);

	if( !bRepetitiveParticle ) return;
	
	// Refire
//	float fRefire = 0.5; // Intensidad de los árcos eléctricos.
	static char sTemp[64];
	Format(sTemp, sizeof(sTemp), "OnUser1 !self:Stop::%f:-1", fRefire - 0.05);
	SetVariantString(sTemp);
	AcceptEntityInput(particle, "AddOutput");
	Format(sTemp, sizeof(sTemp), "OnUser1 !self:FireUser2::%f:-1", fRefire);
	SetVariantString(sTemp);
	AcceptEntityInput(particle, "AddOutput");
	AcceptEntityInput(particle, "FireUser1");
	
	SetVariantString("OnUser2 !self:Start::0:-1");
	AcceptEntityInput(particle, "AddOutput");
	SetVariantString("OnUser2 !self:FireUser1::0:-1");
	AcceptEntityInput(particle, "AddOutput");
}

stock void CreateEffects( int index )
{
//	int minigun = MachineGunSpawned[index][INDEX_ENTITY];
	int particle = CreateEntityByName("info_particle_system");
//	MachineGunSpawned[index][INDEX_EFFECTS] = EntIndexToEntRef(particle);
	DispatchKeyValue(particle, "effect_name", PARTICLE_FIRE1);
	AcceptEntityInput(particle, "start");
	SetVariantString("!activator");
	AcceptEntityInput(particle, "SetParent", index); // minigun
	SetVariantString("muzzle_flash");
	AcceptEntityInput(particle, "SetParentAttachment");
	TeleportEntity(particle, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }), NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);

//	EmitSoundToAll( bLeft4DeadTwo ? SOUND_FIRE_L4D2 : SOUND_FIRE_L4D1, particle, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	EmitSoundToAll( bLeft4DeadTwo ? SOUND_FIRE_L4D2 : SOUND_FIRE_L4D1, index, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0 );
	
	DataPack hPack = new DataPack();
	hPack.WriteCell( EntIndexToEntRef( particle ));
	hPack.WriteCell( EntIndexToEntRef( index ));
	
	CreateTimer( 0.8, TimerDeleteEffetcs, hPack, TIMER_FLAG_NO_MAPCHANGE );
}

stock void CreateLight( int client, const char[] sColor = "255 30 0 255", const int TypeFlameLight = NULL, const bool bDelete = false )
{
	int entity = CreateEntityByName("light_dynamic");
	DispatchKeyValue(entity, "_light", sColor );
	DispatchKeyValue(entity, "brightness", "1");
	DispatchKeyValueFloat(entity, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(entity, "distance", 25.0);
	DispatchKeyValue(entity, "style", "6");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");
	
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);
	
	SetVariantString("muzzle_flash");
	AcceptEntityInput(entity, "SetParentAttachment");
	
	if( TypeFlameLight == 2 )
	{
		SetVariantString("OnUser1 !self:Distance:50:0.1:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser1 !self:Distance:80:0.2:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser1 !self:Distance:125:0.3:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser1 !self:Distance:180:0.4:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
	else
	{
		SetVariantString("OnUser1 !self:Distance:100:0.1:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser1 !self:Distance:180:0.2:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
	
	TeleportEntity(entity, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }), NULL_VECTOR);
	
	if( bDelete )
		InputKill( entity, 0.8 );
}

void InputKill( int entity, float time )
{
	static char sTemp[40];
	Format( sTemp, sizeof sTemp, "OnUser4 !self:Kill::%f:-1", time );
	SetVariantString( sTemp );
	AcceptEntityInput( entity, "AddOutput" );
	AcceptEntityInput( entity, "FireUser4" );
}

public Action TimerDeleteEffetcs( Handle hTimer, DataPack hPack )
{	
	hPack.Reset( false );
	int particle = EntRefToEntIndex( hPack.ReadCell() );
	int index = EntRefToEntIndex( hPack.ReadCell() );
	CloseHandle( hPack );
	
	if( IsValidEntity( particle ))
		AcceptEntityInput( particle, "Kill" );
		
	if( IsValidEntity( index ))
		StopSound( index, SNDCHAN_AUTO, bLeft4DeadTwo ? SOUND_FIRE_L4D2 : SOUND_FIRE_L4D1 );	
}

stock void CreateLaser( float vPos[3], float vTargetPosition[3] )
{
	float fLaserLife = 0.38;  							// Duración.
	float fLaserWidth = bLeft4DeadTwo ? 1.0 : 4.0; 		// Anchura.
	int iLaserColor[4];
	iLaserColor = view_as<int>({ 255, 0, 0, 255 }); 	// Rojo
//	iLaserColor = view_as<int>({ 100, 0, 150, 255 }); 	// Morado
	
	TE_SetupBeamPoints( vPos, vTargetPosition, LaserModelIndex, 0, 0, 0, fLaserLife, fLaserWidth, fLaserWidth, 1, 0.0, iLaserColor, 0 );
	TE_SendToAll();
}

stock void CreateBeam( const char[] sStartName, const char[] sEndName, const float vStart[3], const float vEnd[3], int client, const char[] sNoiseAmplitude = "50", const char[] sRenderColor, const float fTimeDuration = 0.5 ) // Crea un árco eléctrico.
{
	int iBeam_Entity = CreateEntityByName("env_beam");
	int iStartPoint_Entity = CreateEntityByName("env_beam");
	int iEndPoint_Entity = CreateEntityByName("env_beam");
	
	TeleportEntity(iStartPoint_Entity, vStart, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(iEndPoint_Entity, vEnd, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(iStartPoint_Entity, "targetname", sStartName);
	DispatchKeyValue(iEndPoint_Entity, "targetname", sEndName);
	
	DispatchSpawn(iStartPoint_Entity);
	DispatchSpawn(iEndPoint_Entity);
	
	SetEntityModel( iBeam_Entity, bLeft4DeadTwo ? MODEL_ANOMALY_LASER_L4D2 : MODEL_ANOMALY_LASER_L4D1 );
	
	static char sClient[128];
	IntToString(client, sClient, sizeof sClient );
	
	SetRandomSeed(GetRandomInt( 1 , 999 ));
	
//	char sRenderColor[32];
//	Format( sRenderColor, sizeof sRenderColor, "%d %d %d", GetRandomInt( 0 , 255 ), GetRandomInt( 0 , 255 ), GetRandomInt( 0 , 255 ) );
	DispatchKeyValue(iBeam_Entity, "rendercolor", sRenderColor);
	
	SetRandomSeed(GetRandomInt( 1 , 999 ));
	char sBoltWidth[32];
	FloatToString( bLeft4DeadTwo ? GetRandomFloat( 0.5, 1.0 ) : GetRandomFloat( 2.0, 5.0 ), sBoltWidth, sizeof sBoltWidth ); // Anchura
	DispatchKeyValue(iBeam_Entity, "BoltWidth", sBoltWidth);
	
	char sLife[32];
	FloatToString( fTimeDuration, sLife, sizeof sLife ); // Duración
	
	DispatchKeyValue(iBeam_Entity, "targetname", sClient);
	DispatchKeyValue(iBeam_Entity, "texture", bLeft4DeadTwo ? MODEL_ANOMALY_LASER_L4D2 : MODEL_ANOMALY_LASER_L4D1 );
	DispatchKeyValue(iBeam_Entity, "TouchType", "4");
//	DispatchKeyValue(iBeam_Entity, "life", "2.5");
	DispatchKeyValue(iBeam_Entity, "life", sLife);
	DispatchKeyValue(iBeam_Entity, "StrikeTime", "0.1");
	DispatchKeyValue(iBeam_Entity, "renderamt", "255");
	DispatchKeyValue(iBeam_Entity, "HDRColorScale", "10.0");
	DispatchKeyValue(iBeam_Entity, "decalname", "redglowfade"); //"Bigshot" "redglowfade"
	DispatchKeyValue(iBeam_Entity, "TextureScroll", "5");
	DispatchKeyValue(iBeam_Entity, "LightningStart", sStartName);
	DispatchKeyValue(iBeam_Entity, "LightningEnd", sEndName);
	
	DispatchKeyValue(iBeam_Entity, "ClipStyle", "1");
	DispatchKeyValue(iBeam_Entity, "NoiseAmplitude", sNoiseAmplitude);
//	DispatchKeyValue(iBeam_Entity, "damage", "500");
//	DispatchKeyValue(iBeam_Entity, "Radius", "256");
//	DispatchKeyValue(iBeam_Entity, "framerate", "50");
//	DispatchKeyValue(iBeam_Entity, "framestart", "1");
	DispatchKeyValue(iBeam_Entity, "spawnflags", "4");
	
	DispatchSpawn(iBeam_Entity);
	ActivateEntity(iBeam_Entity);
	AcceptEntityInput(iBeam_Entity, "StrikeOnce");
	
	char sTargetName[32];
	Format( sTargetName, sizeof sTargetName, "Beam_%d", client);
	DispatchKeyValue(client, "targetname", sTargetName);
	SetVariantString(sTargetName);
	AcceptEntityInput(iEndPoint_Entity, "SetParent");
/*	
	InputKill( iBeam_Entity, fTimeDuration );
	InputKill( iStartPoint_Entity, fTimeDuration );
	InputKill( iEndPoint_Entity, fTimeDuration );
*/	
	CreateTimer( fTimeDuration, KillEntity, EntIndexToEntRef( iBeam_Entity ), TIMER_FLAG_NO_MAPCHANGE );
	CreateTimer( fTimeDuration, KillEntity, EntIndexToEntRef( iStartPoint_Entity ), TIMER_FLAG_NO_MAPCHANGE );
	CreateTimer( fTimeDuration, KillEntity, EntIndexToEntRef( iEndPoint_Entity ), TIMER_FLAG_NO_MAPCHANGE );
}

public Action KillEntity( Handle hTimer, any EntityID )
{
	int entity = EntRefToEntIndex( EntityID );
	if( !IsValidEntity( entity ) ) 
		return;
	
	AcceptEntityInput(entity, "Kill"); 
}

stock void CreateElectricArc( float vPos[3], float vEndPos[3] )
{	
 	char sTemp[32];
	int iTarget = NULL;
	int iType = GetRandomInt( 0, 1 );
	
	iTarget = CreateEntityByName( bLeft4DeadTwo ? "info_particle_target" : "info_particle_system" );
	
	Format( sTemp, sizeof sTemp, "cptarget%d", iTarget );
	DispatchKeyValue( iTarget, "targetname", sTemp );
	TeleportEntity( iTarget, vEndPos, NULL_VECTOR, NULL_VECTOR );
	ActivateEntity( iTarget );

	int particle = CreateEntityByName("info_particle_system");
	
	DispatchKeyValue( particle, "effect_name", iType == 0 ? PARTICLE_TES1 : PARTICLE_TES3 );
	DispatchKeyValue(particle, "cpoint1", sTemp);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	TeleportEntity(particle, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(particle, "start");
	
	InputKill( iTarget, 1.0 ); 	// Duración del objetivo falso.
	InputKill( particle, 0.8 ); // Duración de la partícula.
	
	PlaySound( particle, sArraySoundsZap[GetRandomInt( 0, sizeof( sArraySoundsZap ) - 1 )]); // Repodruce el sonido en la posición de la ametralladora.
}

void PlaySound( int entity, const char[] sound, int level = SNDLEVEL_NORMAL )
{
	EmitSoundToAll( sound, entity, level == SNDLEVEL_RAIDSIREN ? SNDCHAN_ITEM : SNDCHAN_AUTO, level );
}
/*
// Esta función no tiene errores y hace lo mismo que la función L4D_TE_Create_Particle.
// Pero la función L4D_TE_Create_Particle tiene un efecto visual un poco mejor y usa un solo indice de entidad.

stock void ShowTrack( int iMachineGunModel, float vPos[3], float vEndPos[3] )
{	
 	char sTemp[32];
	int iTarget = NULL;
	
	iTarget = CreateEntityByName( bLeft4DeadTwo ? "info_particle_target" : "info_particle_system" );
	
	Format( sTemp, sizeof sTemp, "cptarget%d", iTarget );
	DispatchKeyValue( iTarget, "targetname", sTemp );
	TeleportEntity( iTarget, vEndPos, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity( iTarget );

	int iParticle = CreateEntityByName("info_particle_system");
	
	DispatchKeyValue( iParticle, "effect_name", iMachineGunModel == 1 ? PARTICLE_WEAPON_TRACER_GATLING : PARTICLE_WEAPON_TRACER_50CAL );
	DispatchKeyValue( iParticle, "cpoint1", sTemp);
	DispatchSpawn( iParticle );
	ActivateEntity( iParticle );
	TeleportEntity( iParticle, vPos, NULL_VECTOR, NULL_VECTOR );
	AcceptEntityInput( iParticle, "start" );
	
	InputKill( iTarget, 0.2 );
	InputKill( iParticle, 0.1 );
}*/

/**
 *	iParticleIndex = "ParticleString" index location in String table "ParticleEffectNames"
 *	iEntIndex = entity index usually used for attachpoints
 *	fDelay = delay for TE_SendToAll
 *	SendToAll = if send to all false call send to clients your self
 *	sParticleName =  particle name only used if iParticleIndex -1 it will find the index for you
 *	iAttachmentIndex =  attachpoint index there is no way to get this currently with sm, gotta decompile the model :p
 *	ParticleAngles =  angles usually effects particles that have no gravity
 *	iFlags = 1 required for attachpoints as well as damage type ^^
 *	iDamageType = saw it being used in impact effect dispatch and attachpoints need to be set to use (maybe)
 *	fMagnitude = no idea saw being used with pipebomb blast (needs testing)
 *	fScale = guess its particle scale but most dont scale (needs testing)
**/
stock bool L4D_TE_Create_Particle( float fParticleStartPos[3] = {0.0, 0.0, 0.0},
								float fParticleEndPos[3] = {0.0, 0.0, 0.0},
								int iParticleIndex = -1,
								int iEntIndex = 0,
								float fDelay = 0.0,
								bool SendToAll = true,
								char sParticleName[64] = "",
								int iAttachmentIndex = 0,
								float fParticleAngles[3] = {0.0, 0.0, 0.0},
								int iFlags = 0,
								int iDamageType = 0,
								float fMagnitude = 0.0,
								float fScale = 1.0,
								float fRadius = 0.0 )
{
	TE_Start("EffectDispatch");
	TE_WriteFloat(bLeft4DeadTwo ? "m_vOrigin.x" : "m_vStart[0]", fParticleStartPos[0]);
	TE_WriteFloat(bLeft4DeadTwo ? "m_vOrigin.y"	: "m_vStart[1]", fParticleStartPos[1]);
	TE_WriteFloat(bLeft4DeadTwo ? "m_vOrigin.z"	: "m_vStart[2]", fParticleStartPos[2]);
	TE_WriteFloat(bLeft4DeadTwo ? "m_vStart.x" : "m_vOrigin[0]", fParticleEndPos[0]); // End point usually for bulletparticles or ropes
	TE_WriteFloat(bLeft4DeadTwo ? "m_vStart.y" : "m_vOrigin[1]", fParticleEndPos[1]);
	TE_WriteFloat(bLeft4DeadTwo ? "m_vStart.z" : "m_vOrigin[2]", fParticleEndPos[2]);

	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ParticleEffect");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ParticleEffect indexes");
	}

	TE_WriteNum("m_iEffectName", iEffectIndex);

	if(iParticleIndex < 0)
	{
		static int iParticleStringIndex = INVALID_STRING_INDEX;
		iParticleStringIndex = __FindStringIndex2(iEffectIndex, sParticleName);
		if(iParticleStringIndex == INVALID_STRING_INDEX)
			return false;

		TE_WriteNum("m_nHitBox", iParticleStringIndex);
	}
	else
		TE_WriteNum("m_nHitBox", iParticleIndex);

	TE_WriteNum("entindex", iEntIndex);
	TE_WriteNum("m_nAttachmentIndex", iAttachmentIndex);

	TE_WriteVector("m_vAngles", fParticleAngles);

	TE_WriteNum("m_fFlags", iFlags);
	TE_WriteFloat("m_flMagnitude", fMagnitude);// saw this being used in pipebomb needs testing what it does probs shaking screen?
	TE_WriteFloat("m_flScale", fScale);
	TE_WriteFloat("m_flRadius", fRadius);// saw this being used in pipebomb needs testing what it does probs shaking screen?
	TE_WriteNum("m_nDamageType", iDamageType);// this shit is required dunno why for attachpoint emitting valve probs named it wrong

	if(SendToAll)
		TE_SendToAll(fDelay);

	return true;
}

// Credit Smlib https://github.com/bcserv/smlib
/**
 * Rewrite of FindStringIndex, because in my tests
 * FindStringIndex failed to work correctly.
 * Searches for the index of a given string in a string table.
 *
 * @param tableidx		A string table index.
 * @param str			String to find.
 * @return				String index if found, INVALID_STRING_INDEX otherwise.
 **/
stock int __FindStringIndex2(int tableidx, const char[] str)
{
	static char buf[1024];

	int numStrings = GetStringTableNumStrings(tableidx);
	for (int i=0; i < numStrings; i++) {
		ReadStringTable(tableidx, i, buf, sizeof(buf));

		if (StrEqual(buf, str)) {
			return i;
		}
	}

	return INVALID_STRING_INDEX;
}

stock void CreateSparks( float vTargetPosition[3] )
{
	float vDirection[3];
	vDirection[0] = GetRandomFloat( -1.0, 1.0 );
	vDirection[1] = GetRandomFloat( -1.0, 1.0 );
	vDirection[2] = GetRandomFloat( -1.0, 1.0 );
	
	TE_SetupSparks( vTargetPosition, vDirection, 1, 3 );
	TE_SendToAll();
	
	EmitSoundToAll( SOUND_IMPACT_CONCRETE, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vTargetPosition, NULL_VECTOR, true, 0.0 );
}

stock int DisplayParticle( int target, const char[] sParticle, const float vPos[3], const float vAng[3], float fRefire = 0.0, bool bDelete = false )
{
	int entity = CreateEntityByName("info_particle_system");
	if( entity == -1)
	{
		LogError("Failed to create 'info_particle_system'");
		return 0;
	}

	DispatchKeyValue(entity, "effect_name", sParticle);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "start");
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

	// Refire
	if( fRefire )
	{
		static char sTemp[64];
		Format(sTemp, sizeof sTemp, "OnUser1 !self:Stop::%f:-1", fRefire - 0.05);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof sTemp, "OnUser1 !self:FireUser2::%f:-1", fRefire);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");

		SetVariantString("OnUser2 !self:Start::0:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser2 !self:FireUser1::0:-1");
		AcceptEntityInput(entity, "AddOutput");
	}

	// Attach
	if( target )
	{
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);
	}
	
	if( bDelete )
		InputKill( entity, 0.1 ); // Si la condición es verdadera elimina las partículas para evitar bloqueos en el servidor/juego.
	
	return entity;
}

void MakeEnvSteam(int target, const float vPos[3], const float vAng[3], const char[] sColor)
{
	int entity = CreateEntityByName("env_steam");
	if( entity == -1 )
	{
		LogError("Failed to create 'env_steam'");
		return;
	}

	static char sTemp[32];
	Format(sTemp, sizeof sTemp, "silv_steam_%d", target);
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(entity, "SpawnFlags", "1");
	DispatchKeyValue(entity, "rendercolor", sColor);
	DispatchKeyValue(entity, "SpreadSpeed", "10");
	DispatchKeyValue(entity, "Speed", "100");
	DispatchKeyValue(entity, "StartSize", "5");
	DispatchKeyValue(entity, "EndSize", "10");
	DispatchKeyValue(entity, "Rate", "50");
	DispatchKeyValue(entity, "JetLength", "100");
	DispatchKeyValue(entity, "renderamt", "150");
	DispatchKeyValue(entity, "InitialState", "1");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

	// Attach
	if( target )
	{
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);
	}
	
	InputKill( entity, 1.2 );
}

/**
 * @note Freeze controller and check.
 * 
 * @param hTimer 		Handle for the timer
 * @param index			Entity Index
 */
public Action Timer_Freeze( Handle hTimer, any EntityID )
{
	int entity = EntRefToEntIndex( EntityID );
	if( !IsValidEntity( entity ) )
		return Plugin_Stop;
	
	FreezeTargets( entity );
	
	return Plugin_Continue;
}

public void FreezeTargets( int entity )
{	
//	Pos/Ang De La Entidad.
	static float vPos[3];
	static float vAng[3];
	
	GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", vPos );
	GetEntPropVector( entity, Prop_Data, "m_angAbsRotation", vAng );
	
	vPos[2] += 2.0;
	DisplayParticle( entity, PARTICLE_WATER, vPos, vAng );
	vPos[2] -= 2.0;
	
// 	Sound
//	PlaySound( entity, SOUND_EFFECTS );
	
// 	Congelar Objetivos.
	float vEnd[3];
	for( int i = 1; i <= MaxClients; i++ ) // Sólo clientes validos, no entidades como zombies o witches.
	{
		if( IsClientInGame( i ) && IsPlayerAlive( i ) /*&& GetClientTeam( i ) == TEAM_SURVIVOR*/ )
		{
			if( IsValidArrayEntity( i, entity ) )
				continue;
			
			GetClientAbsOrigin( i, vEnd );
			if( GetVectorDistance( vPos, vEnd ) <= 250.0 ) // Radio
			{
				if( GetEntProp( i, Prop_Send, "m_fFlags" ) & FL_ONGROUND ) // Comprueba si el objetivo está en el piso.
				{
					if( FreezedPlayer[i] == false )
					{
						CreateTimer( 1.0, TimerDefreeze, GetClientUserId( i ), TIMER_FLAG_NO_MAPCHANGE );
						
						PlaySound( i, SOUND_FREEZER );
						
						if( GetEntProp( i, Prop_Send, "m_clrRender" ) == -1 )
						{
							SetEntityRenderColor( i, 0, 128, 255, 192 );
						}
					}

					if( GetEntityMoveType( i ) != MOVETYPE_NONE )
						SetEntityMoveType( i, MOVETYPE_NONE ); // En caso de que el jugador tenga movimiento será congelado.
					
					FreezedPlayer[i] = true; 
				}
			}
		}
	}
}

bool IsValidArrayEntity( int i, int entity )
{	
	for(int iArrayNum = 0; iArrayNum < MAX_EACHPLAYER; iArrayNum ++ )
		if( IsValidEntRef( FreezingMachineGunOwner[i][iArrayNum] ) )
			if( EntRefToEntIndex( FreezingMachineGunOwner[i][iArrayNum] ) == entity )
				return true;
	
	return false;
}

/**
 * @note Freeze controller and check.
 * 
 * @param hTimer 		Handle for the timer
 * @param index			Entity Index
 */
public Action Freeze_Recharge_Timer( Handle hTimer, any EntityID )
{
	int entity = EntRefToEntIndex( EntityID );
	if( !IsValidEntity( entity ) )
		return Plugin_Stop;
	
	bSpecialBulletsAllowed[entity] = true;
	
	return Plugin_Continue;
}

void Freeze( int i )
{
	if( IsValidClient( i ) && IsClientInGame( i ) && IsPlayerAlive( i ) )
	{
		if( FreezedPlayer[i] == false )
		{
			CreateTimer( 4.0, TimerDefreeze, GetClientUserId( i ), TIMER_FLAG_NO_MAPCHANGE );
			
			PlaySound( i, SOUND_FREEZER );
			
			if( GetEntProp( i, Prop_Send, "m_clrRender" ) == -1 )
				SetEntityRenderColor( i, 0, 128, 255, 192 );
			
			if( GetEntityMoveType( i ) != MOVETYPE_NONE )
				SetEntityMoveType( i, MOVETYPE_NONE ); // En caso de que el jugador tenga movimiento será congelado.
			
			CustomPrintToChatAll( "%s %t", sPluginTag, "Target Reached", i );
		}
		
		FreezedPlayer[i] = true; 
	}
}

public Action TimerDefreeze( Handle hTimer, any client )
{
	if((client = GetClientOfUserId( client ) ) && IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
//		if( FreezedPlayer[client] == false )
//			return Plugin_Stop;
		
//		PlaySound( client, SOUND_FREEZER );

		if( GetEntProp(client, Prop_Send, "m_clrRender") == -1056997376 ) // Our render color
			SetEntityRenderColor(client, 255, 255, 255, 255);

		SetEntityMoveType(client, MOVETYPE_WALK);
		FreezedPlayer[client] = false; 
	}
	
	return Plugin_Stop;
}

/**
 * @note Freeze controller and check.
 * 
 * @param hTimer 		Handle for the timer
 * @param index			Entity Index
 */
public Action Vomit_Recharge_Timer( Handle hTimer, any EntityID )
{
	int entity = EntRefToEntIndex( EntityID );
	if( !IsValidEntity( entity ) )
		return Plugin_Stop;
	
	bSpecialBulletsAllowed[entity] = true;
	
	return Plugin_Continue;
}

void VomitTarget( int victim, int attacker )
{
//	if( IsValidClient( victim ) && IsValidClient( attacker ) && ( IsTank( victim ) && bLeft4DeadTwo || GetClientTeam( victim ) == TEAM_SURVIVOR ) ) // Tank en Left 4 Dead 2 o superviviente para ambos juegos.
	if( IsValidClient( victim ) && IsValidClient( attacker ) && ( IsValidInfected( victim ) == TANK && bLeft4DeadTwo || GetClientTeam( victim ) == TEAM_SURVIVOR ) )
	{
		SDKCall( SDKVomitOnPlayer, victim, attacker, true );	
		VomitedPlayer[victim] = true;
	}
}
/*************************************************************************************************************************************/
void DissolveCommon( int target )
{
	// Sound
	PlaySound( target, sArraySoundsZap[GetRandomInt( 0, sizeof sArraySoundsZap -1 )] );
	
	if( GetEntProp( target, Prop_Data, "m_iHealth" ) > 0 )
		return;

	// Dissolve
	int iOverlayModel = -1;
	if( bLMC_Available )
		iOverlayModel = LMC_GetEntityOverlayModel(target);

	if( target <= MaxClients )
	{
		int clone = AttachFakeRagdoll(target);
		if( clone > 0 )
		{
			SetEntityRenderMode(clone, RENDER_NONE); // Hide and dissolve clone - method to show more particles
			DissolveTarget( clone, GetEntProp(target, Prop_Send, "m_zombieClass") == 2 ? 0 : target); // Exclude boomer to producer gibs
		}
	} 
	else 
	{
		SetEntityRenderFx(target, RENDERFX_FADE_FAST);
		if( iOverlayModel < 1 )
			DissolveTarget( target);
		else
			DissolveTarget( target, iOverlayModel);
	}
}

void DissolveTarget( int target, int iOverlayModel = 0 )
{
	// CreateEntityByName "env_entity_dissolver" has broken particles, this way works 100% of the time
	float time = GetRandomFloat(0.2, 0.7);

	int dissolver = SDKCall(SDKDissolveCreate, iOverlayModel ? iOverlayModel : target, "", GetGameTime() + time, 2, false);
	if( dissolver > MaxClients && IsValidEntity(dissolver) )
	{
		if( target > MaxClients )
		{	
			// Prevent common infected from crashing the server when taking damage from the dissolver.
			SDKHook(target, SDKHook_OnTakeDamage, OnCommonDamage);

			// Kill common infected if they fail to die from the dissolver.
			InputKill(target, time + 0.5);
		}

		SetEntPropFloat(dissolver, Prop_Send, "m_flFadeOutStart", 0.0); // Fixes broken particles

		int fader = CreateEntityByName("func_ragdoll_fader");
		if( fader != -1 )
		{
			static float vec[3];
			GetEntPropVector(target, Prop_Data, "m_vecOrigin", vec);
			TeleportEntity(fader, vec, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(fader);

			SetEntPropVector(fader, Prop_Send, "m_vecMaxs", view_as<float>({ 50.0, 50.0, 50.0 }));
			SetEntPropVector(fader, Prop_Send, "m_vecMins", view_as<float>({ -50.0, -50.0, -50.0 }));
			SetEntProp(fader, Prop_Send, "m_nSolidType", 2);

			InputKill(fader, 0.1);
		}
	}
}

int AttachFakeRagdoll(int target)
{
	int entity = CreateEntityByName("prop_dynamic_ornament");
	if( entity != -1 )
	{
		static char sModel[64];
		GetEntPropString(target, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		DispatchKeyValue(entity, "model", sModel);
		DispatchSpawn(entity);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetAttached", target);
	}

	return entity;
}

public Action OnCommonDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	damage = 0.0;
	return Plugin_Handled;
}

public Action DissolveCommonDelay( Handle hTimer, any TargetID ) // Temporizador necesario, de lo contrario bloqueará el servidor/juego.
{
	int target = EntRefToEntIndex( TargetID );
	if( IsValidEntity( target ) )
		DissolveCommon( target );
}
/*************************************************************************************************************************************/
/*
void ShoveClient( int victim ) // Empuja al objetivo, pero sin reacción de sonido.
{
	static float vDir[3]; 
	
	GetClientAbsAngles( victim, vDir );
	GetAngleVectors( vDir, vDir, NULL_VECTOR, NULL_VECTOR );
	NormalizeVector( vDir, vDir );
	ScaleVector( vDir, -1.0 );
	
	SDKCall( SDKShoveSurvivor, victim, victim, vDir );
}
*/
void StaggerClient( int userid, const float vPos[3] ) // Empuja al objetivo con reacción de sonido, solo en Left 4 Dead 1.
{
	if( bLeft4DeadTwo )
	{
		// Credit to Timocop on VScript function
		static int iScriptLogic = INVALID_ENT_REFERENCE;
		if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
		{
			iScriptLogic = EntIndexToEntRef( CreateEntityByName( "logic_script" ) );
			if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity( iScriptLogic ) )
				LogError("Could not create 'logic_script");

			DispatchSpawn(iScriptLogic);
		}

		static char sBuffer[96];
		Format(sBuffer, sizeof(sBuffer), "GetPlayerFromUserID(%d).Stagger(Vector(%d,%d,%d))", userid, RoundFloat(vPos[0]), RoundFloat(vPos[1]), RoundFloat(vPos[2]));
		SetVariantString(sBuffer);
		AcceptEntityInput(iScriptLogic, "RunScriptCode");
		AcceptEntityInput(iScriptLogic, "Kill");
	} 
	else 
	{
		userid = GetClientOfUserId( userid );
		SDKCall( SDKStaggerClient, userid, userid, vPos ); // Stagger: SDKCall method
	}
}

stock void ExplodeMachine( int entity )
{
	if( iCvar_MachineEnableExplosion < 1 )
		return;
	
	static float vPos[3];
	static float vAng[3];
	
//	GetEntPropVector( entity, Prop_Send, "m_vecOrigin", vPos );
	GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", vPos );	
	GetEntPropVector( entity, Prop_Data, "m_angAbsRotation", vAng );
	vPos[2] += 22.0; // 45.0 Es la altura tope.
	
	CreateExplosion( vPos, vAng, RoundFloat( iCvar_MachineEnableExplosion * 1.4 ), 250, 828 ); // 6146
	
	if( MachineGunTypes[entity] == TYPE_FLAME )
		CreateFires( entity, /*client,*/ bLeft4DeadTwo ? GetRandomBool() : true );
	else if( MachineGunTypes[entity] > NULL )
		CreateEffectsDamage( entity );
		
}

stock bool GetRandomBool()
{	
	if( GetRandomInt( 0, 1 ) == 1 )
		return true;
	
	return false;
}

stock int CreateExplosion( const float vPos[3], const float vAng[3], int iDamage = 0, int iRadius = 500, int iFlags = 0 )
{
	int iExplosion = CreateEntityByName( "env_explosion" );
	int iPhysExplosion = CreateEntityByName( "env_physexplosion" );
	int iExplosion_Effect = CreateEntityByName( "info_particle_system" ); // Crea un efecto adicional de explosión, ya que la entidad de explosión no genera un efecto visual suficiente.
	
	if( iExplosion == -1 || iExplosion_Effect == -1 || iPhysExplosion == -1 )
		return -1;
/**/	
	TeleportEntity( iExplosion_Effect, vPos, NULL_VECTOR, NULL_VECTOR );
	DispatchKeyValue( iExplosion_Effect, "effect_name", PARTICLE_GAS_EXPLOTION );
	DispatchKeyValue( iExplosion_Effect, "targetname", "particle" );
	DispatchSpawn( iExplosion_Effect );
	ActivateEntity( iExplosion_Effect );
	AcceptEntityInput( iExplosion_Effect, "start" );
	InputKill( iExplosion_Effect, 3.0 );
/**/	
/*	SetEntProp( iExplosion, Prop_Data, "m_iMagnitude", iDamage ); // Funciona correctamente para L4D2, pero tiene errores de texturas en L4D1 (antes funcionó bien en ambos juegos).
	SetEntProp( iExplosion, Prop_Data, "m_iRadiusOverride", iRadius );
	SetEntProp( iExplosion, Prop_Data, "m_spawnflags", iFlags );
	
	TeleportEntity( iExplosion, vPos, NULL_VECTOR, NULL_VECTOR );
	DispatchSpawn( iExplosion );
	ActivateEntity( iExplosion );
	AcceptEntityInput( iExplosion, "Explode" );		
//	AcceptEntityInput( iExplosion, "Kill" ); */
	
	char sRadius[16];
	char sDamage[16];
	char sSFlags[16];
	IntToString( iRadius, sRadius, sizeof sRadius );
	IntToString( iDamage, sDamage, sizeof sDamage );
	IntToString( iFlags, sSFlags, sizeof sSFlags );
	
	DispatchKeyValue( iExplosion, "fireballsprite", MODEL_MUZZLEFLASH );
	DispatchKeyValue( iExplosion, "iMagnitude", sDamage );
	DispatchKeyValue( iExplosion, "iRadiusOverride", sRadius );
	DispatchKeyValue( iExplosion, "spawnflags", sSFlags );
	DispatchSpawn( iExplosion );
	TeleportEntity( iExplosion, vPos, NULL_VECTOR, NULL_VECTOR );
	AcceptEntityInput( iExplosion, "Explode" );
	
	DispatchKeyValue( iPhysExplosion, "radius", "250" );
	DispatchKeyValue( iPhysExplosion, "magnitude", sDamage ); // Poder de explosión
	DispatchSpawn( iPhysExplosion);
	TeleportEntity( iPhysExplosion, vPos, NULL_VECTOR, NULL_VECTOR );
	AcceptEntityInput( iPhysExplosion, "Explode" );
	InputKill( iPhysExplosion, 0.3 );
	
	switch( GetRandomInt( 1, 3 ) ) // Efecto aleatorio de sonido.
	{
		case 1: PlaySound( iExplosion, SOUND_EXPLODE3 );
		case 2: PlaySound( iExplosion, SOUND_EXPLODE4 );
		case 3: PlaySound( iExplosion, SOUND_EXPLODE5 );
	}
	
	float vEnd[3];
	float fRadius = float( iRadius );
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( !IsClientPlaying( i ) )
			continue;
		
		GetClientAbsOrigin( i, vEnd );
		if( GetVectorDistance( vPos, vEnd ) <= fRadius)  // Radio
			StaggerClient( GetClientUserId( i ), vPos ); // Empujar a los clientes que están dentro del perímetro.
	}
	
//	InputKill( iExplosion, 0.3 );
	return iExplosion;
}

stock void CreateFires( int target, /*int client,*/ bool bGascan )
{
	int entity = CreateEntityByName("prop_physics");
	if( entity != -1 )
	{
		SetEntityModel( entity, bGascan ? MODEL_GASCAN : MODEL_CRATE );
//		SetEntityModel( entity, MODEL_GASCAN );
		
		static float vPos[3];
		GetEntPropVector( target, Prop_Data, "m_vecOrigin", vPos );
		vPos[2] += 10.0;
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(entity);

		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
//		SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client  );
		SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 0, 0, 0, 0);
		AcceptEntityInput(entity, "Break");
	}
}

stock void CreateEffectsDamage( int entity )
{
	static float vPos[3];
//	static float vAng[3];
	
	GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", vPos );
//	GetEntPropVector( entity, Prop_Data, "m_angAbsRotation", vAng );
	
	float vEnd[3];
	for( int i = 1; i <= MaxClients; i++ ) // Sólo clientes validos, no entidades como zombies o witches.
	{
		if( IsClientInGame( i ) && IsPlayerAlive( i ) )
		{	
			GetClientAbsOrigin( i, vEnd );
			if( GetVectorDistance( vPos, vEnd ) <= 250.0 ) // Radio
			{				
				GetEntPropVector( i, Prop_Data, "m_vecOrigin", vEnd);
				vPos[2] += 50.0;
				vEnd[2] += 50.0;
				if( IsVisibleTo( vPos, vEnd ))
				{
/*					MakeVectorFromPoints(vPos, vEnd, vEnd);
					NormalizeVector(vEnd, vEnd);
					ScaleVector(vEnd, 400.0);
					vEnd[2] = 300.0;
					TeleportEntity( i, NULL_VECTOR, NULL_VECTOR, vEnd);
*/					
					switch( MachineGunTypes[entity] )
					{
						case TYPE_TESLA: 
						{
							CreateElectricArc( vPos, vEnd );
							HurtTarget( NULL, GetClientTeam( i ) == TEAM_SURVIVOR ? 35.0 : 350.0, DMG_PLASMA, i );
						}
						case TYPE_FREEZE: Freeze( i );
						case TYPE_NAUSEATING: 
						{	
							int index = FindGunIndex( entity );
							if( index != -1 )
							{
								int client = GunUser[index];
								if( client > NULL )
								{
									VomitTarget( i, client );
								}
							}
						}
//						default : CustomPrintToChatAll( "%s 'Red'Error 'Default'Search In Array Failed'Gold'!", sPluginTag ); // Sin Traducciones
					}
				}
			}
		}
	}
}

// ====================================================================================================
//					STOCKS - TRACERAY
// ====================================================================================================
stock bool IsVisibleTo(float position[3], float targetposition[3])
{
	static float vAngles[3], vLookAt[3];
	position[2] += 50.0;

	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace

	// execute Trace
	static Handle trace;
	trace = TR_TraceRayFilterEx(position, vAngles, MASK_ALL, RayType_Infinite, _TraceFilter);

	static bool isVisible;
	isVisible = false;

	if( TR_DidHit(trace) )
	{
		static float vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint

		if( GetVectorDistance(position, vStart) + 25.0 >= GetVectorDistance(position, targetposition) )
			isVisible = true; // if trace ray length plus tolerance equal or bigger absolute distance, you hit the target
	}
	else
		isVisible = false;

	position[2] -= 50.0;
	delete trace;
	return isVisible;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	if( !entity || !IsValidEntity(entity) ) // dont let WORLD, or invalid ents be hit
		return false;

	// Don't hit triggers
	static char classname[12];
	GetEdictClassname(entity, classname, sizeof classname);
	if( strncmp(classname, "trigger_", 8) == 0 ) return false;

	return true;
}

/*************************************************************************************************************************************/
stock void StartGlowing( int entity, int TeamIndex )
{
	if( !entity || !bLeft4DeadTwo ) 
		return;
	
	static char sColor[16];
	
	switch( MachineGunTypes[entity] )
	{
		case TYPE_FLAME: sColor = GetColorIndex( 5 );
		case TYPE_LASER: sColor = GetColorIndex( 1 );
		case TYPE_TESLA: sColor = GetColorIndex( 11 );
		case TYPE_FREEZE: sColor = GetColorIndex( 3 );
		case TYPE_NAUSEATING: sColor = GetColorIndex( 10 );
		default: sColor = GetColorIndex( 2 );
	}
	
	if( TeamIndex == 3 )
		sColor = GetColorIndex( 12 ); // Color De Ametralladora Traidora.
	
	static int iColor;
	iColor = GetColor( sColor );
	
	SetEntProp( entity, Prop_Send, "m_iGlowType", 3 ); // 2 = Brillo visible solo si el objeto es visible, 3 = Brillo visible a traves de objetos.
	SetEntProp( entity, Prop_Send, "m_bFlashing", 1 );
	SetEntProp( entity, Prop_Send, "m_nGlowRange", 10000 );
	SetEntProp( entity, Prop_Send, "m_nGlowRangeMin", 90 );
	SetEntProp( entity, Prop_Send, "m_glowColorOverride", iColor );
//	AcceptEntityInput( entity, "StartGlowing" );
}

stock void StopGlowing( int entity )
{
	if( !entity || !bLeft4DeadTwo )
		return;
	
	SetEntProp( entity, Prop_Send, "m_iGlowType", 3 );
	SetEntProp( entity, Prop_Send, "m_bFlashing", 0 );
	SetEntProp( entity, Prop_Send, "m_nGlowRange",0 );
	SetEntProp( entity, Prop_Send, "m_glowColorOverride", 1 ); // Brillo azul por defecto
}

stock char[] GetColorIndex( int iColorType )
{
	static char sColor[16];
	switch( iColorType )
	{
		case 1: Format( sColor, sizeof sColor, "255 0 0 255" ); 	// Red
		case 2: Format( sColor, sizeof sColor, "0 255 0 255" ); 	// Green
		case 3: Format( sColor, sizeof sColor, "0 0 255 255" ); 	// Blue
		case 4: Format( sColor, sizeof sColor, "100 0 150 255" ); 	// Purple
		case 5: Format( sColor, sizeof sColor, "255 155 0 255" ); 	// Orange
		case 6: Format( sColor, sizeof sColor, "255 255 0 255" ); 	// Yellow
		case 7: Format( sColor, sizeof sColor, "-1 -1 -1 255" ); 	// White
		case 8: Format( sColor, sizeof sColor, "255 0 150 255" ); 	// Pink
		case 9: Format( sColor, sizeof sColor, "0 255 255 255" ); 	// Cyan
		case 10:Format( sColor, sizeof sColor, "128 255 0 255" ); 	// Lime
		case 11:Format( sColor, sizeof sColor, "0 128 128 255" ); 	// Teal
		case 12:Format( sColor, sizeof sColor, "50 50 50 255" ); 	// Grey
	}
	
	return sColor;
}

stock int GetColor( char[] sTemp ) // Convierte una cadena de texto en un valor entero.
{
	char sColors[4][4];
	ExplodeString(sTemp, " ", sColors, sizeof sColors, sizeof sColors[]);

	int iColor;
	iColor = StringToInt(sColors[0]);
	iColor += 256 * StringToInt(sColors[1]);
	iColor += 65536 * StringToInt(sColors[2]);
	return iColor;
}

int PutMiniGun(int iEntity, float VecOrigin[3], float VecAngles[3])
{
	float VecDirection[3];

	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	
	VecOrigin[0] += VecDirection[0] * 45;
	VecOrigin[1] += VecDirection[1] * 45;
	VecOrigin[2] += VecDirection[2];
	
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	
	DispatchKeyValueVector(iEntity, "Origin", VecOrigin);
	DispatchKeyValueVector(iEntity, "Angles", VecAngles);
	
//	TeleportEntity(iEntity, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	StopGlowing( iEntity );
	
	return iEntity;
}

int FindGunIndex( int iEntity )
{
	int index = -1;
	for(int i = 0; i < MachineCount; i++)
	{
		if(Gun[i] == iEntity)
		{
			index = i;
			break;
		}
	}
	return index;
}

int FindCarryIndex( int client )
{
	int index = -1;
	for(int i = 0; i < MachineCount; i++)
	{
		if( GunCarrier[i] == client )
		{
			index = i;
			break;
		}
	}
	
	return index;
}

void StartCarry(int client, int iEntity)
{
	if( FindCarryIndex(client) >= 0 ) 
		return;
	
	int index = FindGunIndex(iEntity);
	if( index >= 0 )
	{
		if( GunCarrier[index] > 0 ) 
			return;

		if( iCvar_MachineAllowCarry == 2 )
		{
			int owner = GunOwner[index];
			if( owner > 0 && IsClientInGame( owner ) && IsPlayerAlive( owner ) )
			{
				if( owner != client )
				{
					PrintHintText( client, "%t", "Can't Pick Up", owner );
					return;
				}
			}
			else
			{
				GunOwner[index] = client;
			}
		}
		
		GunCarrier[index] = client;
		SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 2);
		SetEntProp(iEntity, Prop_Send, "m_firing", 0);
		
		AttachEntity(client, iEntity, "medkit", view_as<float>({ -5.0, 20.0, 0.0 }), view_as<float>({ 0.0, 0.0, 90.0 }) );
		
		LastButton[index] = 0;
		PressTime[index] = 0.0;
		GunState[index] = State_Carry;
		GunUser[index] = client;
		GunLastCarryTime[index] = GetEngineTime();
		GunHealth[index] = fCvar_MachineHealth;

		SDKUnhook(Gun[index], SDKHook_OnTakeDamagePost, OnTakeDamagePost);

		GunTeam[index] = 2;
		
		StartGlowing( Gun[index], TEAM_SURVIVOR );
		if( GunAmmo[index] > 0 )
		{
			PrintHintText( client, "%t", "Ammo Status", GunAmmo[index] );
		}
		else
		{
			PrintHintText( client, "%t", "Reload Machine Gun" );
		}
	}
}

void AttachEntity( int iOwner, int iEntity, const char[] sPositon = "medkit", const float vPos[3] = NULL_VECTOR, const float vAng[3] = NULL_VECTOR )
{
	char sName[60];
	Format( sName, sizeof( sName ), "target%d", iOwner );
	DispatchKeyValue( iOwner, "targetname", sName );
	DispatchKeyValue( iEntity, "parentname", sName );
	
	SetVariantString( sName );
	AcceptEntityInput( iEntity, "SetParent", iEntity, iEntity, 0 );
	if( strlen( sPositon ) != 0 )
	{
		SetVariantString( sPositon );
		AcceptEntityInput( iEntity, "SetParentAttachment" );
	}
	
	TeleportEntity( iEntity, vPos, vAng, NULL_VECTOR );
}

int StopClientCarry( int client )
{
	if( !client ) 
		return;
	
	int index = FindCarryIndex(client);
	if( index >= 0 )
		StopCarry( index );
	
	return;
}

void StopCarry( int index )
{
	if( GunCarrier[index] > 0 )
	{
		GunCarrier[index] = 0;
		AcceptEntityInput(Gun[index], "ClearParent");
		PutMiniGun(Gun[index], GunCarrierOrigin[index], GunCarrierAngle[index]);
		SetEntProp(Gun[index], Prop_Send, "m_CollisionGroup", 0);

		GunLastCarryTime[index] = GetEngineTime();
		GunState[index] = State_Scan;
		Broken[index] = false;
		GunEnemy[index] = 0;
		GunScanIndex[index] = 0;
		GunFireTotolTime[index] = 0.0;
		GunTeam[index] = 2;
		SDKHook(Gun[index], SDKHook_OnTakeDamagePost, OnTakeDamagePost);
		
		StartGlowing( Gun[index], TEAM_SURVIVOR );
	}
}

void Carrying( int index, float intervual )
{
	int client = GunCarrier[index];
	int Button = GetClientButtons( client );
	
	GetClientAbsOrigin( client, GunCarrierOrigin[index]);
	GetClientEyeAngles( client, GunCarrierAngle[index] );
	
	if( Button & IN_USE )
	{
		if(GetEntPropEnt( client, Prop_Send, "m_reviveTarget" ) != -1 
		|| GetEntPropEnt( client, Prop_Send, "m_hUseEntity" ) > NULL 
		|| (bLeft4DeadTwo != true && GetEntProp( client, Prop_Send, "m_iProgressBarDuration" ) > NULL )
		|| (bLeft4DeadTwo == true && GetEntPropEnt( client, Prop_Send, "m_useActionTarget" ) != -1 ))
//		|| (bLeft4DeadTwo == true && GetEntPropFloat( client, Prop_Send, "m_flProgressBarDuration" ) > 0.0 ))
		{
//			PressTime[client] = GetEngineTime();
			PressTime[client] = 0.0;
//			PrintHintText( client, "Now you can't drop your machine gun" ); // Solo para pruebas
			return;
		}
		
		PressTime[index] += intervual;
		
		if( PressTime[index] > fCvar_MachineDroppingTime ) // Tiempo en el cual se soltará la ametralladora, por defecto 0.5
			if( GetEntityFlags( client ) & FL_ONGROUND ) 
				StopCarry(index);
	}
	else
	{
		PressTime[index] = 0.0;
	}
	
	LastButton[index] = client;
}

/**************************************************************************************************************************************/
void SetStatusHealth( int index, float damage, int attacker, bool bBroken = false )
{
	GunHealth[index] -= damage;
	
	if( GunHealth[index] <= 0.0 || bBroken == true )
	{
		GunHealth[index] = 0.0;
		Broken[index] = true;
		
		if( IsValidInfected( attacker ) == TANK || IsValidInfected( attacker ) == CHARGER )
			CustomPrintToChatAll( "%s %t", sPluginTag, "Entity Destroyed By Special Infected", attacker );
	}
}

public Action PreThinkGun( int iEntity )
{
	int index = FindGunIndex( iEntity );
	if( index != -1 )
	{
		float time = GetEngineTime();
		float intervual = time - LastTime[index];
		LastTime[index] = time;

		if( GunState[index] == State_Scan || GunState[index] == State_Sleep )
		{
			ScanAndShotEnmey(index, time, intervual);
		}
		else if(GunState[index] == State_Carry)
		{
			int carrier = GunCarrier[index];
			if( IsClientInGame( carrier ) && IsPlayerAlive( carrier ) && !IsFakeClient( carrier ) )
			{
				Carrying( index, intervual );
			}
			else
			{
				StopCarry( index );
			}
		}		
//		PushUser( index );
	}
}

public void OnTakeDamagePost( int victim, int attacker, int inflictor, float damage, int damagetype )
{
	int index = FindGunIndex(victim);
	if( GunState[index] == State_Carry ) 
		return;
	
	if( damage <= 0.0 ) 
		return;
	
	if( index >= 0 )
	{
		bool bBetrayToInfected = false;
		bool bBetrayToSurvivor = false;
		bool bPrint = false;
		bool bWakeup = false;
		bool bAttackerIsPlayer = false;
		
		if( attacker > 0 && attacker <= MaxClients )
		{
			if( IsClientInGame( attacker ) )
			{
				if( GetClientTeam( attacker ) == TEAM_SURVIVOR && damagetype == DMG_CLUB )
				{
					if( GunTeam[index] == 3 )
					{
						bBetrayToInfected = false;
						bBetrayToSurvivor = true;
					}
				}
				else if( GunTeam[index] == 2 )
				{
					bBetrayToInfected = true;
				}
				
				if( damagetype == DMG_CLUB ) 
					bWakeup = true;
				
				bAttackerIsPlayer = true;
				if( GetClientTeam( attacker ) == TEAM_INFECTED )
					bWakeup = true;
				
				bPrint = true;
				
/************************************************************************/			
				if( GetClientTeam( attacker ) == TEAM_SURVIVOR && damagetype & DMG_BULLET ) // Daño por arma de fuego.
				{
					SetStatusHealth( index, damage, attacker );
				}
				else if( GetClientTeam( attacker ) == TEAM_SURVIVOR && IsMeleeAttack( attacker ) ) // Daño con melee.
				{
					SetStatusHealth( index, float( GetActiveMelee( attacker ) ), attacker );
				}
				else if( GetClientTeam( attacker ) == TEAM_INFECTED ) // Daño por infectado especial.
				{
					if( damagetype == DMG_CLUB && IsValidInfected( attacker ) == TANK ) // Incluye roca y puño.
					{
						SetStatusHealth( index, damage, attacker, true );
					}
					else if( damagetype == DMG_CLUB && IsValidInfected( attacker ) == CHARGER )
					{
						SetStatusHealth( index, 200.0, attacker );
					}
					else 
					{
						SetStatusHealth( index, damage, attacker );
					}
				}
				else if( GetClientTeam( attacker ) == TEAM_SURVIVOR )
				{
					SetStatusHealth( index, damage, attacker );
				}
/************************************************************************/	
			}
			else 
				bPrint = false;
		}
		else
		{
			if( GunTeam[index] == 2 )
				bBetrayToInfected = true;
			
			bWakeup = true;
		}
		
		if( bBetrayToInfected && GetRandomInt( 1, 100 ) <= iCvar_MachineBetrayChance )
		{
			PrintHintTextToAll( "%t", "Machine Gun Betrays Survivors" );
			GunLastCarryTime[index] = GetEngineTime();
//			GunState[index] = State_Scan;
			Broken[index] = false;
			GunEnemy[index] = 0;
			GunScanIndex[index] = 0;
			GunFireTotolTime[index] = 0.0;
			GunTeam[index] = 3;
			GunHealth[index] = fCvar_MachineHealth;
			
			if( bAttackerIsPlayer ) 
				GunUser[index] = attacker;
			
			bPrint = false;
			
			StartGlowing( Gun[index], GunTeam[index] );
		}
		
		if( bBetrayToSurvivor )
		{
			PrintHintTextToAll( "%t", "Machine Gun Betrays Infected" );
			GunLastCarryTime[index] = GetEngineTime();
//			GunState[index] = State_Scan;
			Broken[index] = false;
			GunEnemy[index] = 0;
			GunScanIndex[index] = 0;
			GunFireTotolTime[index] = 0.0;
			GunTeam[index] = 2;
			GunHealth[index] = fCvar_MachineHealth;
			
			if( bAttackerIsPlayer ) 
				GunUser[index] = attacker;
			
			bPrint = false;
			
			StartGlowing( Gun[index], GunTeam[index] );
		}
		
 		if( bWakeup && GunState[index] == State_Sleep )
		{
			PrintHintTextToAll( "%t", "Machine Gun Active State" );
			GunLastCarryTime[index] = GetEngineTime();
			GunState[index] = State_Scan;
			Broken[index] = false;
			GunEnemy[index] = 0;
			GunScanIndex[index] = 0;
			GunFireTotolTime[index] = 0.0;
			GunHealth[index] = fCvar_MachineHealth;
			
			if( bAttackerIsPlayer ) 
				GunUser[index] = attacker;
			
			bPrint = false;
			bWakeup = true;
			
			StartGlowing( Gun[index], GunTeam[index] );
		}
		else 
			bWakeup = false;
		
		float oldHealth = GunHealth[index];
		
		if(!bBetrayToInfected && !bBetrayToSurvivor && !bWakeup )
			GunHealth[index] -= damage;
		
		if( GunHealth[index] <= 0.0 )
		{
			GunHealth[index] = 0.0;
			GunState[index] = State_Sleep;
			float vAng[3];
			GetEntPropVector(Gun[index], Prop_Send, "m_angRotation", vAng);
			vAng[0] =- 45.0;
			DispatchKeyValueVector(Gun[index], "Angles", vAng);
			SetEntProp(Gun[index], Prop_Send, "m_firing", 0);
			
			if( GunUser[index] > 0 && IsClientInGame( GunUser[index] ) && oldHealth > 0.0 )
				PrintHintText( GunUser[index], "%t", "Damaged Machine Gun" );
			
			StartGlowing( Gun[index], GunTeam[index] );
		}
		
		if( bPrint )
			PrintHintText( attacker, "%t", "Machine Gun Power", RoundFloat( GunHealth[index] ), RoundFloat( fCvar_MachineHealth ) );
	}
}

//public Action OnEntityPostUse( int weapon, int client, int caller, UseType hType, float fValue )
public Action OnEntityUse( int weapon, int client )
{	
	if( !IsClientPlaying( client ) )
		return Plugin_Continue;
	
	int iReferenceEntity = EntIndexToEntRef( weapon );
	int iIndexEntity = FindGunIndex( weapon );
	if( iIndexEntity >= 0 )
	{
		if( GunUser[iIndexEntity] != client && GunState[iIndexEntity] == State_Carry ) 	// Comprobación de dueño de ametralladora, si la condición no se cumple continua, de lo contrario retorna.
		{
//			CustomPrintToChat( client, "%s You can't use this machine gun while its owner is carrying it!", sPluginTag );
			CreatePushTimer( client, iReferenceEntity );
			return Plugin_Continue;
		}
		else if( GunUser[iIndexEntity] == client && GunState[iIndexEntity] == State_Carry )
			return Plugin_Continue;
	}
	
	if( bCvar_MachineAllowUse && !MachineGunTypes[weapon] )
	{
		if( iIndexEntity != -1 )
		{
			if( GunState[iIndexEntity] == State_Sleep )
			{	
				CreatePushTimer( client, iReferenceEntity );	
				return Plugin_Continue;
			}
			
			if( GetClientButtons( client ) & IN_ATTACK )
			{				
				if( Machine_RateTime[client] + 0.3 < GetEngineTime() )
				{
					Machine_RateTime[client] = GetEngineTime();
					GunAmmo[iIndexEntity] --;
					PrintHintText( client, "%t", "Ammunition Status", GunAmmo[iIndexEntity] );
					
					if( GunAmmo[iIndexEntity] == NULL )
						CustomPrintToChat( client, "%s %t", sPluginTag, "Finished Ammunition" );
				}
				
				if( GunAmmo[iIndexEntity] < NULL )
					GunAmmo[iIndexEntity] = NULL;	
			}
			
			if( GunAmmo[iIndexEntity] <= NULL )
			{
				CreatePushTimer( client, iReferenceEntity );	
				return Plugin_Continue;
			}
		}
		return Plugin_Continue;
	}
	
	CreatePushTimer( client, iReferenceEntity );
	
	return Plugin_Continue;
}

void CreatePushTimer( int client, int entity )
{
	if( GetEntPropEnt( client, Prop_Send, "m_hUseEntity" ) ) // Regresa la ID de la entidad que se esta usando, también si el cliente esta usando un objeto.
	{
		if( MachineGunerTime[client] + 1.0 < GetEngineTime() )
		{
			MachineGunerTime[client] = GetEngineTime();
			SetEntProp( client, Prop_Data, "m_nButtons", IN_BACK ); // Forzado de uso de bóton W(Atrás), es necesario de lo contrario el cliente no suela la ametralladora.
			
			CustomPrintToChat( client, "%s %t", sPluginTag, "Inaccessible Entity" );
			
			DataPack hPack = new DataPack();
			hPack.WriteCell( GetClientUserId( client ) );
			hPack.WriteCell( entity );
			
			CreateTimer( 0.1, UserPushTimer, hPack, TIMER_FLAG_NO_MAPCHANGE ); // Ayuda a prevenir errores en consola, aunque pueden persistir.
		}
	}
}

public Action UserPushTimer( Handle hTimer, DataPack hPack )
{	
	hPack.Reset( false );
	int client = GetClientOfUserId( hPack.ReadCell() );
	int iEntity = EntRefToEntIndex( hPack.ReadCell() );
	CloseHandle( hPack );
	
	if( !IsClientPlaying( client ) || !IsValidEntity( iEntity ) )
		return;
	
	SetEntProp( client, Prop_Data, "m_nButtons", IN_BACK );
//	SetEntPropEnt( client, Prop_Send, "m_usingMinigun", 0 ); 		// No esencial.
//	SetEntPropEnt( client, Prop_Send, "m_usingMountedWeapon", 0 ); 	// No necesario.
//	SetEntPropEnt( client, Prop_Send, "m_hUseEntity", -1 ); 		// No necesario.

	static float vPos[3];
	GetEntPropVector( iEntity, Prop_Data, "m_vecAbsOrigin", vPos );
	StaggerClient( GetClientUserId( client ), vPos );
//	ShoveClient( client );
	
	DataPack hPackEffects = new DataPack();
	hPackEffects.WriteCell( GetClientUserId( client ) );
	hPackEffects.WriteCell( EntIndexToEntRef( iEntity ) );
	
	CreateTimer( 1.5, ShowEnergyEffects, hPackEffects, TIMER_FLAG_NO_MAPCHANGE );
}

public Action ShowEnergyEffects( Handle hTimer, DataPack hPack )
{	
	hPack.Reset( false );
	int client = GetClientOfUserId( hPack.ReadCell() );
	int iEntity = EntRefToEntIndex( hPack.ReadCell() );
	CloseHandle( hPack );
	
	if( !IsClientPlaying( client ) || !IsValidEntity( iEntity ) )
		return;
	
	static float vMachinePosition[3];
	static float vTargetPosition[3];
	
	GetEntPropVector( iEntity, Prop_Data, "m_vecAbsOrigin", vMachinePosition );
	vMachinePosition[2] += 45.0;
	
	GetEntPropVector( client, Prop_Data, "m_vecAbsOrigin", vTargetPosition );
	vTargetPosition[2] += GetRandomFloat( 10.0, 55.0 );
	
	static char sColor[16];
	
	switch( MachineGunTypes[iEntity] )
	{
		case TYPE_FLAME: sColor = GetColorIndex( 5 );
		case TYPE_LASER: sColor = GetColorIndex( 1 );
		case TYPE_TESLA: sColor = GetColorIndex( 11 );
		case TYPE_FREEZE: sColor = GetColorIndex( 3 );
		case TYPE_NAUSEATING: sColor = GetColorIndex( 10 );
		default: sColor = GetColorIndex( 2 );
	}
	
	CreateBeam( "LaserBeam0", "LaserBeam_end0", vMachinePosition, vTargetPosition, client, "50", sColor, 0.3 );
}
/*
void PushUser( int index ) // Método funcional, pero es de respuesta mas lenta.
{
	int iReferenceEntity = Gun[index];
	int iUsingEntity = INVALID_ENT_REFERENCE;
	
	if( iReferenceEntity > 0 && IsValidEdict( iReferenceEntity ) && IsValidEntity( iReferenceEntity ) ) 
	{
		for(int i = 1; i <= MAXPLAYERS; i ++ )
		{	
			if( !IsClientPlaying( i ) ) 
				continue;
		
			iUsingEntity = GetEntPropEnt(i, Prop_Send, "m_hUseEntity");
			if( !IsValidEntity( iUsingEntity ) || !IsValidEdict( iUsingEntity ) )
				continue;
			
			if( iReferenceEntity == iUsingEntity )				
				CreatePushTimer( client, EntIndexToEntRef( iReferenceEntity ) );
		}
	}
}
*/
void ScanAndShotEnmey( int index, float time, float intervual )
{
	bool bExistingEntity = false;
	int iEntity = Gun[index];
	if( iEntity > 0 && IsValidEdict( iEntity ) && IsValidEntity( iEntity ) ) 
		bExistingEntity = true;

	int client = GunUser[index];
	if( !IsValidClient( client ) )
		client = 0;	
/***********************************************************/
	int iUsingEntity;
	bool bBlockAutoFire = false;
	
	for(int i = 1; i <= MAXPLAYERS; i ++ )
	{	
		if( !IsClientPlaying( i ) ) 
			continue;
		
		iUsingEntity = GetEntPropEnt( i, Prop_Send, "m_hUseEntity" );
		if( !IsValidEntity( iUsingEntity ) || !IsValidEdict( iUsingEntity ) )
			continue;
		
		if( iEntity == iUsingEntity )
			bBlockAutoFire = true;
	}
	
	if( bBlockAutoFire )
		return;
/***********************************************************/
	if( bExistingEntity == false || Broken[index] )
	{
		if( IsValidClient( client ) )
		{
			PrintHintText( client, "%t", "Broken Machine Gun" );
			CustomPrintToChatAll( "%s %t", sPluginTag, "Owner's Machine Gun", client );
		}
		
		RemoveMachine( index, client );	
		return;
	}

//	Broken[index] = true;

	if( GunState[index] == State_Sleep )
	{
		SetEntProp( iEntity, Prop_Send, "m_firing", 0 );
		Broken[index] = false;
		return;
	}
	
	if( time - ScanTime > 1.0 )
	{
		ScanTime = time;
		ScanEnemys();
	}

	static float vPos[3];
	static float vAng[3];
	static float vTargetPosition[3];
	static float vTemp[3];
	static float vShotAngle[3];
	static float vDir[3];

	GetEntPropVector( iEntity, Prop_Send, "m_vecOrigin", vPos );
	GetEntPropVector( iEntity, Prop_Send, "m_angRotation", vAng );

	if( GunLastCarryTime[index] + fCvar_MachineSleepTime < time )
	{
		GunState[index] = State_Sleep;
		vAng[0] =- 45.0;
		DispatchKeyValueVector( iEntity, "Angles", vAng );
		SetEntProp( iEntity, Prop_Send, "m_firing", 0 );
		
		if( IsValidClient( client ) )
			CustomPrintToChatAll( "%s %t", sPluginTag, "Machine Gun Inactive State", client );
		
		return;
	}
	
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR );
	NormalizeVector(vDir, vDir);
	CopyVector(vDir, vTemp);
	
	if( GunType[index] == MACHINE_MINI ) 		// Ametralladora Gatling.
		ScaleVector( vTemp, 20.0 );
	else if( GunType[index] == MACHINE_50CAL ) 	// Ametralladora Calibre 50.
		ScaleVector( vTemp, 50.0 );
	
	AddVectors(vPos, vTemp ,vPos);
	GetAngleVectors(vAng, NULL_VECTOR, NULL_VECTOR, vTemp );
	NormalizeVector(vTemp, vTemp);
	ScaleVector(vTemp, 43.0);

	AddVectors(vPos, vTemp ,vPos);

	int newenemy = GunEnemy[index];
	if( IsVilidEenmey( newenemy, GunTeam[index] ) )
		newenemy = IsEnemyVisible( iEntity, newenemy, vPos, vTargetPosition, vShotAngle, GunTeam[index] );
	else 
		newenemy = 0;

	if( InfectedCount > 0 && newenemy == 0 )
	{
		if( GunScanIndex[index] >= InfectedCount)
			GunScanIndex[index] = 0;
		
		GunEnemy[index] = InfectedsArray[GunScanIndex[index]];
		GunScanIndex[index]++;
		newenemy = 0;
	}
	
	if( newenemy == 0 )
	{
		SetEntProp( iEntity, Prop_Send, "m_firing", 0 );
		Broken[index] = false;
		return;
	}

	float vTargetDir[3];
	float vNewMachineAngle[3];
	
	if( newenemy > 0 )
	{
		SubtractVectors(vTargetPosition, vPos, vTargetDir);
	}
	else
	{
		CopyVector( vDir, vTargetDir );
		vTargetDir[2] = 0.0;
	}
	
	NormalizeVector(vTargetDir, vTargetDir);

	float vTargetAng[3];
	GetVectorAngles(vTargetDir, vTargetAng);
	float diff0 = AngleDiff( vTargetAng[0], vAng[0]);
	float diff1 = AngleDiff( vTargetAng[1], vAng[1]);

	float turn0 = 45.0 * Sign( diff0 ) * intervual;
	float turn1 = 180.0 * Sign(diff1 ) * intervual;
	
	if( FloatAbs( turn0 ) >= FloatAbs( diff0 ) )
		turn0 = diff0;
	
	if( FloatAbs( turn1 ) >= FloatAbs( diff1 ) )
		turn1 = diff1;

	vNewMachineAngle[0] = vAng[0] + turn0;
	vNewMachineAngle[1] = vAng[1] + turn1;

	vNewMachineAngle[2] = 0.0;

	DispatchKeyValueVector( iEntity, "Angles", vNewMachineAngle );
	int overheated = GetEntProp( iEntity, Prop_Send, "m_overheated" );

	GetAngleVectors(vNewMachineAngle, vDir, NULL_VECTOR, NULL_VECTOR);
	
	if( overheated == 0 )
	{
		if( newenemy > 0 && FloatAbs( diff1 ) < 40.0 )
		{
			if( time >= GunFireTime[index] && GunAmmo[index] > 0 )
			{
				GunFireTime[index] = time + fCvar_MachineFireRate;
				Shot( client, index, iEntity, GunTeam[index], vPos, vNewMachineAngle );
				GunAmmo[index]--;
				AmmoIndicator[index]++;
				
				if( AmmoIndicator[index] >= iCvar_MachineAmmoCount / 20.0 )
				{
					AmmoIndicator[index] = 0;
					if( IsValidClient( client ) ) 
						CustomPrintToChat( client, "%s %t", sPluginTag, "Current Ammo", GunAmmo[index], RoundFloat( GunAmmo[index] * 100.0 / iCvar_MachineAmmoCount ) );
//						PrintCenterText( client, "AMMUNITION STATUS[%d/%d%%]", GunAmmo[index], RoundFloat( GunAmmo[index] * 100.0 / iCvar_MachineAmmoCount ) );
				}
				
				if( GunAmmo[index] == 0 )
					if( IsValidClient( client ) ) 
						PrintHintText( client, "%t", "Without Ammunition" );
				
				GunFireStopTime[index] = time + 0.05;
				GunLastCarryTime[index] = time;
			}
		}
	}
	
	float heat = GetEntPropFloat(iEntity, Prop_Send, "m_heat");

	if( time < GunFireStopTime[index])
	{
		GunFireTotolTime[index] += intervual;
		heat = GunFireTotolTime[index] / fCvar_MachineOverHeat;
		if( heat > 1.0 ) 
			heat = 1.0;
		SetEntProp(iEntity, Prop_Send, "m_firing", 1);
		SetEntPropFloat(iEntity, Prop_Send, "m_heat", heat);
	}
	else
	{
		SetEntProp(iEntity, Prop_Send, "m_firing", 0);
		heat = heat - intervual / 4.0;
		if( heat < 0.0 )
		{
			heat = 0.0;
			SetEntProp(iEntity, Prop_Send, "m_overheated", 0);
			SetEntPropFloat(iEntity, Prop_Send, "m_heat", 0.0 );
		}
		else 
			SetEntPropFloat(iEntity, Prop_Send, "m_heat", heat );
		
		GunFireTotolTime[index] = fCvar_MachineOverHeat * heat;
	}
	
	Broken[index] = false;
}

int IsEnemyVisible( int iEntity, int iNewTarget, float vStartingPos[3], float vEndPos[3], float vAng[3], int iTeam )
{
	if( iNewTarget <= 0 ) 
		return 0;

	GetEntPropVector( iNewTarget, Prop_Send, "m_vecOrigin", vEndPos );
	vEndPos[2] += 35.0;

	SubtractVectors( vEndPos, vStartingPos, vAng );
	GetVectorAngles( vAng, vAng );
	Handle hTrace = TR_TraceRayFilterEx( vStartingPos, vAng, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, iEntity );
	
	if( iTeam == 2 ) 
		iTeam = 3;
	else 
		iTeam = 2;
	
	int target = 0;
	float vDistance = fCvar_MachineRange;
	
	if( MachineGunTypes[iEntity] == TYPE_FLAME )
		vDistance = 250.0;

	if( TR_DidHit( hTrace ) )
	{
		TR_GetEndPosition( vEndPos, hTrace );
		target = TR_GetEntityIndex( hTrace );
		
//		if( GetVectorDistance( vStartingPos, vEndPos ) > fCvar_MachineRange ) 
		if( GetVectorDistance( vStartingPos, vEndPos ) > vDistance ) 
			target = 0;
	}
	else
	{
		target = iNewTarget;
	}
	
	delete hTrace;
	
	if( target > 0 )
	{
		if( target <= MaxClients )
		{
			if( IsClientInGame( target ) && IsPlayerAlive( target ) && GetClientTeam( target ) == iTeam )
				return target;
			else 
				return 0;
		}
		else if( iTeam == 3 )
		{
			if( IsInfected( target ) || IsWitch( target ) )
				return target;
			else 
				return 0;
		}
	}
	
	return target;
}

void Shot( int client, int index, int iEntity, int iTeam, float vMachinePosition[3], float vShotAngle[3] )
{
	float vTemp[3];
	float vAng[3];
	GetAngleVectors( vShotAngle, vTemp, NULL_VECTOR, NULL_VECTOR );
	NormalizeVector( vTemp, vTemp );

	float vACC = 0.020;
	vTemp[0] += GetRandomFloat( -1.0, 1.0 ) * vACC;
	vTemp[1] += GetRandomFloat( -1.0, 1.0 ) * vACC;
	vTemp[2] += GetRandomFloat( -1.0, 1.0 ) * vACC;
	GetVectorAngles( vTemp, vAng );

	Handle hTrace = TR_TraceRayFilterEx( vMachinePosition, vAng, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, iEntity );
	int enemy = 0;

	if( TR_DidHit( hTrace ) )
	{
		float vTargetPosition[3];
		TR_GetEndPosition( vTargetPosition, hTrace );
		enemy = TR_GetEntityIndex( hTrace );

		bool bBlood = false;
		if( enemy > 0 )
		{	
			if( enemy >= 1 && enemy <= MaxClients )
			{
				if( GetClientTeam( enemy ) == iTeam )
					enemy = 0;
				
				bBlood = true;
			}
			else if( IsInfected( enemy ) || IsWitch( enemy ) ) 
			{
				if( iTeam == 3 )
					enemy = 0;
			}
			else 
			{
				enemy = 0;
			}
		}
		
		if( enemy > 0 )
		{
			if( client > 0 && IsPlayerAlive( client ) )
				client = client + 0;
			else 
				client = 0;
			
			DealDamage( enemy, client, iTeam, MachineGunTypes[iEntity], vMachinePosition, vTargetPosition ); // Infringir Daño
			
			float vAngParticle[3];
			GetAngleVectors( vAng, vAngParticle, NULL_VECTOR, NULL_VECTOR );
			ScaleVector( vAngParticle, -1.0);
			GetVectorAngles( vAngParticle, vAngParticle );
			
			if( bBlood && MachineGunTypes[iEntity] != TYPE_FLAME )
				DisplayParticle( enemy, PARTICLE_BLOOD, vTargetPosition, vAngParticle, 0.0, true );
				
			if( MachineGunTypes[iEntity] != TYPE_FLAME )
				EmitSoundToAll( SOUND_IMPACT_FLESH, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vTargetPosition, NULL_VECTOR, true, 0.0 );
		
/****************************************************************************************************************************/		
			if( MachineGunTypes[iEntity] == TYPE_FLAME )
			{
				CreateEffects( iEntity );
				CreateLight( iEntity, "255 30 0 255", 2, true ); // Color Naranja
			}
			else if( MachineGunTypes[iEntity] == TYPE_LASER )
			{
				CreateLaser( vMachinePosition, vTargetPosition );
//				CreateBeam( "LaserBeam0", "LaserBeam_end0", vMachinePosition, vTargetPosition, client, "50", "0 255 0 255", 0.1 ); // Color Rojo, Test.
				CreateSparks( vTargetPosition );
			}
			else if( MachineGunTypes[iEntity] == TYPE_TESLA )
			{	
				CreateElectricArc( vMachinePosition, vTargetPosition );
			}
			else if( MachineGunTypes[iEntity] == TYPE_FREEZE )
			{
				MakeEnvSteam( iEntity, vMachinePosition, vAng, "-1 -1 -1 255" ); // Color Blanco
				
				if( bSpecialBulletsAllowed[iEntity] == true )
				{
					Freeze( enemy );
					bSpecialBulletsAllowed[iEntity] = false;
				}
			}
			else if( MachineGunTypes[iEntity] == TYPE_NAUSEATING )
			{
				if( bSpecialBulletsAllowed[iEntity] == true )
				{
					vMachinePosition[2] += 5.0;
					DisplayParticle( iEntity, PARTICLE_VOMIT, vMachinePosition, vAng, 0.0, true );
					vMachinePosition[2] -= 5.0;
					
					VomitTarget( enemy, client );
					bSpecialBulletsAllowed[iEntity] = false;
				}
			}
		}
		else if( !MachineGunTypes[iEntity] || MachineGunTypes[iEntity] == TYPE_LASER )
		{
			if( MachineGunTypes[iEntity] == TYPE_LASER )
				CreateLaser( vMachinePosition, vTargetPosition );
				
			CreateSparks( vTargetPosition );
		}
/****************************************************************************************************************************/
		
		if( !MachineGunTypes[iEntity] || MachineGunTypes[iEntity] == TYPE_LASER || (MachineGunTypes[iEntity] == TYPE_NAUSEATING && bSpecialBulletsAllowed[iEntity] == false) )
			DisplayParticle( iEntity, PARTICLE_MUZZLE_FLASH, vMachinePosition, vAng, 0.0, true ); 	// Explosión De Percusión
		
		if( !MachineGunTypes[iEntity] || (MachineGunTypes[iEntity] == TYPE_NAUSEATING && bSpecialBulletsAllowed[iEntity] == false) )
			L4D_TE_Create_Particle( bLeft4DeadTwo ? vMachinePosition : vTargetPosition, bLeft4DeadTwo ? vTargetPosition : vMachinePosition, GunType[index] == 1 ? iParticleTracer_Gatling : iParticleTracer_50Cal );
//			ShowTrack( GunType[index], vMachinePosition, vTargetPosition ); 						// Partícula De Bala.
		
		if( GunType[index] == MACHINE_50CAL && bAllowSound[iEntity] == false ) 
			EmitSoundToAll( SOUND_SHOOT_50CAL, 0, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vMachinePosition, NULL_VECTOR, true, 0.0 );
/****************************************************************************************************************************/			
	}
	
	delete hTrace;
}

public bool TraceRayDontHitSelf( int entity, int mask, any data )
{
	if( entity == data )
		return false;
	
	return true;
}

stock void CopyVector( const float vSource[3], float vTarget[3] )
{
	vTarget[0] = vSource[0];
	vTarget[1] = vSource[1];
	vTarget[2] = vSource[2];
}

float AngleDiff( float a, float b )
{
	float d = 0.0;
	if( a >= b )
	{
		d = a - b;
		if( d >= 180.0 ) 
			d = d - 360.0;
	}
	else
	{
		d = a - b;
		if( d <= -180.0 )
			d = 360 + d;
	}
	
	return d;
}

float Sign( float vAng )
{
	if( vAng == 0.0 ) 
		return 0.0;
	else if( vAng > 0.0 ) 
		return 1.0;
	else 
		return -1.0;
}

bool IsVilidEenmey( int enemy, int iTeam )
{
	bool bIndex = false;
	if( enemy <= 0 ) 
		return bIndex;
	
	if( iTeam == 2) 
		iTeam = 3;
	else 
		iTeam = 2;
	
	if( IsValidClient( enemy ) )
	{
		if( !IsPlayerGhost( enemy ) && !IsPlayerIncapacitated( enemy ) && IsPlayerAlive( enemy ) && GetClientTeam( enemy ) == iTeam )
			bIndex = true;
	}
	else if( iTeam == 3 && IsValidEntity( enemy ) && IsValidEdict( enemy ) )
	{
		if( IsInfected( enemy ) )
		{
			bIndex = true;
			if( BurnedEntity[enemy] == true )
				bIndex = false;
		}
		else if( IsWitch( enemy ) )
			bIndex = true;
	}
	
	return bIndex;
}

/********************************************************************************************************************************************************/
int GetActiveMelee( int client )
{
	static char sClassName[64]; 
	GetClientWeapon( client, sClassName, sizeof( sClassName ) );
	
	if( StrEqual( sClassName, "weapon_melee" ) )
		return GetMeleeWeaponDamage( GetPlayerWeaponSlot( client, 1 ) );
	else if( StrEqual( sClassName, "weapon_chainsaw" ) ) // Motosierra
		return 50;

	return NULL;
}

int GetMeleeWeaponDamage( int entity ) // Por defecto las armas cuerpo a cuerpo cuasan 175 de daño, con esta función se controla dicho daño ya que es muy alto para algunas armas.
{	
	if( entity > 0 && IsValidEdict( entity ) && IsValidEntity( entity ) )
	{		
		static char sClassName[64];
		GetEdictClassname( entity, sClassName, sizeof( sClassName ) );
		
		if( StrEqual( sClassName, "weapon_melee" ) )
		{
			static char sModel[128];
			GetEntPropString( entity, Prop_Data, "m_ModelName", sModel, sizeof( sModel ) );
			
			if( StrContains( sModel, "fireaxe" ) >= 0 ) 			return 100; // Hacha Contra Incendios
			else if( StrContains( sModel, "v_bat" ) >= 0 ) 			return 50; // Bat De Madera
			else if( StrContains( sModel, "crowbar" ) >= 0 ) 		return 35; // Palanca
			else if( StrContains( sModel, "electric_guitar" ) >=0 ) return 35; // Guitarra Eléctrica
			else if( StrContains( sModel, "cricket_bat" ) >= 0 ) 	return 50; // Bate De Cricket 
			else if( StrContains( sModel, "frying_pan" ) >= 0 ) 	return 15; // Sartén
			else if( StrContains( sModel, "golfclub" ) >= 0 ) 		return 35; // Palo De Golf
			else if( StrContains( sModel, "machete" ) >= 0 ) 		return 50; // Machete
			else if( StrContains( sModel, "katana" ) >= 0 ) 		return 50; // Espada Katana
			else if( StrContains( sModel, "tonfa" ) >= 0 ) 			return 15; // Macana
			else if( StrContains( sModel, "riotshield" ) >= 0 ) 	return 15; // Escudo Antimotines
			else if( StrContains( sModel, "knife" ) >= 0 ) 			return 25; // Cuchillo
			else if( StrContains( sModel, "v_shovel" ) >= 0 ) 		return 45; // Pala
			else if( StrContains( sModel, "v_pitchfork" ) >= 0 ) 	return 40; // Horca
		}
	}
	
	return NULL;
}

stock bool IsMeleeAttack( int client )
{
	if( GetClientTeam( client ) != TEAM_SURVIVOR )
		return false;
		
	static char sClassName[32];
	GetClientWeapon( client, sClassName, sizeof( sClassName ) );
	if( StrEqual( sClassName, "weapon_melee" ) || StrEqual( sClassName, "weapon_chainsaw" ) )
		return true;
	
	return false;
}

/********************************************************************************************************************************************************/
stock bool IsMiniGun( int entity )
{
	if( entity > 0 )
	{
		static char sClassName[64];
		GetEdictClassname( entity, sClassName, sizeof sClassName );
		if( StrEqual( sClassName, "prop_minigun" ) || StrEqual( sClassName, "prop_minigun_l4d1" ) || StrEqual( sClassName, "prop_mounted_machine_gun" ) )
		{
			return true;
		}
	}
	
	return false;
}

public Action OnPlayerRunCmd( int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon )
{	
	if( IsFakeClient( client ))
		return Plugin_Continue; 

	int iUsingEntity = 0;
	
	iUsingEntity = GetEntPropEnt( client, Prop_Send, "m_hUseEntity" );
	bool bEntityIsMachine  = IsMiniGun( iUsingEntity );
	bool bIsSpawnedMachine = false;
	
	if( !bEntityIsMachine )
		return Plugin_Continue;
	
	for(int i = 0; i < MAX_ALLOWED; i++ )
	{
		int entity = MachineGunSpawned[i];
		if( IsValidEntRef( entity ) )
			if( EntRefToEntIndex( entity ) == iUsingEntity )
				bIsSpawnedMachine = true;
	}
	
	if( bIsSpawnedMachine != true )
		return Plugin_Continue;
	
	static float vEyeAngles[3];
	static float vGunAngles[3]; 
	
	GetClientEyeAngles( client, vEyeAngles );
 	GetEntPropVector( iUsingEntity, Prop_Send, "m_angRotation", vGunAngles );
	
	vEyeAngles[0] = 0.0;
	vGunAngles[0] = 0.0;
	
	float vAngle = GetAngle( vEyeAngles, vGunAngles ) * 180.0 / PI_NUM;
	
	if( vAngle > 89.0 )
		TeleportEntity( iUsingEntity, NULL_VECTOR, vEyeAngles, NULL_VECTOR );
		
	return Plugin_Continue;
}

stock float GetAngle( float vAngX[3], float vAngY[3] )
{
	static float vAngA[3];
	static float vAngB[3];
	
	GetAngleVectors( vAngX, vAngA, NULL_VECTOR, NULL_VECTOR );
	GetAngleVectors( vAngY, vAngB, NULL_VECTOR, NULL_VECTOR );
	
	return ArcCosine( GetVectorDotProduct( vAngA, vAngB ) / ( GetVectorLength( vAngA ) * GetVectorLength( vAngB )));
}
/********************************************************************************************************************************************************/
/**
 * @note Prints a message to all clients in the chat area.
 * @note Provides custom color support.
 *
 * @param client		Client index.
 * @param sMessage 		Message (formatting rules)
 * @param ... 			Variable number of format parameters.
 * @return 				No return
 */
stock void CustomPrintToChatAll( const char[] sMessage, any ... )
{
	static char sBuffer[MAX_MESSAGE_LENGTH];
	
	for(int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame( i ) && !IsFakeClient( i ) )
		{
			SetGlobalTransTarget( i );
			VFormat( sBuffer, sizeof( sBuffer ), sMessage, 2 );
			CustomPrintToChat( i, sBuffer );
		}
	}
}

/**
 * @note Prints a message to a specific client in the chat area.
 * @note Provides custom color support.
 *
 * @param client 		Client index.
 * @param sMessage 		Message (formatting rules).
 * @param ... 			Variable number of format parameters.
 * @return 				No return.
 * 
 * On error/Errors:   If the client is not connected an error will be thrown.
 */
stock void CustomPrintToChat( int client, const char[] sBuffer, any ... )
{
	if( client <= 0 || client > MaxClients )
		ThrowError( "Invalid client index %d", client );
	
	if( !IsClientInGame( client ) )
		ThrowError( "Client %d is not in game", client );
	
	static char sMessage[MAX_MESSAGE_LENGTH];
	static char sTemp[MAX_MESSAGE_LENGTH];
	int iExtendedColorTag;
	
	SetGlobalTransTarget( client );
	
	Format( sTemp, sizeof sTemp, "\x01%s", sBuffer ); 	// Agrega color blanco al texto.
	VFormat( sMessage, sizeof sMessage, sTemp, 3 ); 	// Reorganiza el texto cuando se estan usando sumas de cadenas de texto.
	
	ReplaceColorTags( sMessage, sizeof sMessage );
	if( iExtendedColorTag == EXTENDED_COLOR_TAG_NONE )
		iExtendedColorTag = ReplaceExtendedColorTags( sMessage, sizeof sMessage );
	else
		ReplaceExtendedColorTags( sMessage, sizeof sMessage );
	
	switch( iExtendedColorTag )
	{
		case EXTENDED_COLOR_TAG_TEAM:  SayText2(client, client,  sMessage);
		case EXTENDED_COLOR_TAG_BLUE:  SayText2(client, FindRandomPlayerByTeam( TEAM_SURVIVOR ), sMessage);
		case EXTENDED_COLOR_TAG_RED:   SayText2(client, FindRandomPlayerByTeam( TEAM_INFECTED ), sMessage);
		case EXTENDED_COLOR_TAG_WHITE: SayText2(client, -1, sMessage);
		default: PrintToChat(client, sMessage); //EXTENDED_COLOR_TAG_NONE
	}
}

/**
 * @note Replaces tag colors with color codes from a text.
 *
 * @param sText          Text.
 * @param iMaxLength     Max text length.
 * @return 				 No return.
 */
stock void ReplaceColorTags( char[] sText, int iMaxLength)
{
	ReplaceString( sText, iMaxLength, "'Default'", "\x01" );
	ReplaceString( sText, iMaxLength, "'Lightyellow'", "\x01" );
	ReplaceString( sText, iMaxLength, "'Gold'", "\x04" );
	ReplaceString( sText, iMaxLength, "'Green'", "\x05" );
	ReplaceString( sText, iMaxLength, "'Lightgreen'", "\x03" );
}

/**
 * @note Replaces label colors with text color coding and returns team color index.
 *
 * @param sText          String Text.
 * @param iMaxLength     Max text length.
 * @return 				 Team color index.
 */ 
stock int ReplaceExtendedColorTags( char[] sText, int iMaxLength )
{
	int iTeamCount;
	int iBlueCount;
	int iRedCount;
	int iWhiteCount;
	
	iTeamCount = ReplaceString( sText, iMaxLength, "'Team'", "\x03" );
	iBlueCount = ReplaceString( sText, iMaxLength, "'Blue'", "\x03" );
	iRedCount = ReplaceString( sText, iMaxLength, "'Red'", "\x03" );
	iWhiteCount = ReplaceString( sText, iMaxLength, "'White'", "\x03" );
	
	if( iTeamCount > 0 )
		return EXTENDED_COLOR_TAG_TEAM;
	
	if( iBlueCount > 0 )
		return EXTENDED_COLOR_TAG_BLUE;
	
	if( iRedCount > 0 )
		return EXTENDED_COLOR_TAG_RED;
	
	if( iWhiteCount > 0 )
		return EXTENDED_COLOR_TAG_WHITE;
	
	return EXTENDED_COLOR_TAG_NONE;
}

/**
 * @note Sends a SayText2 usermessage to a client.
 *
 * @param client 		Client index.
 * @param maxlength 	Author index.
 * @param sMessage 		Message.
 * @param ... 			Variable number of format parameters.
 * @return 				No return.
 */
stock void SayText2(int client, int author, const char[] sFormat, any ...)
{
	char sMessage[MAX_MESSAGE_LENGTH];
	VFormat(sMessage, sizeof(sMessage), sFormat, 4);
	
	Handle hBuffer = StartMessageOne("SayText2", client);	
	BfWrite Bf = UserMessageToBfWrite( hBuffer );
	
	Bf.WriteByte( author );
	Bf.WriteByte( true );
	Bf.WriteString( sMessage );
	EndMessage();
}

/**
 * @note Searches for a random player on a team to return their team color.
 *
 * @param color_team  Client team.
 * @return			  Client index or zero if no player found.
 */
stock int FindRandomPlayerByTeam(int color_team)
{
	if( color_team <= 1 || color_team >= 4 )
		return 0;
	
	for(int client = 1; client <= MaxClients; client ++ )
		if( IsClientInGame( client ) && GetClientTeam( client ) == color_team )
			return client;
	
	return 0;
}

/**
 * Removes color codes from a text.
 *
 * @param sText          String Text.
 * @param iMaxLength     Max text length.
 * @noreturn
 */
stock void RemoveColorCodes( char[] sText, int iMaxLength )
{
	ReplaceString( sText, iMaxLength, "\x01", "", false ); // Default/Light Yellow
	ReplaceString( sText, iMaxLength, "\x03", "", false ); // Light Green
	ReplaceString( sText, iMaxLength, "\x04", "", false ); // Gold
	ReplaceString( sText, iMaxLength, "\x05", "", false ); // Green
	
	ReplaceString( sText, iMaxLength, "'Default'", "" );
	ReplaceString( sText, iMaxLength, "'Lightyellow'", "" );
	ReplaceString( sText, iMaxLength, "'Gold'", "" );
	ReplaceString( sText, iMaxLength, "'Green'", "" );
	ReplaceString( sText, iMaxLength, "'Lightgreen'", "" );
	
	ReplaceString( sText, iMaxLength, "'Team'", "" );
	ReplaceString( sText, iMaxLength, "'Blue'", "" );
	ReplaceString( sText, iMaxLength, "'Red'", "" );
	ReplaceString( sText, iMaxLength, "'White'", "" );
}


