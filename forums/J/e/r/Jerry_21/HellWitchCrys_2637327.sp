/*##########################
#Big Thanks for TimoCop    #
#for Helping me with silly #
#mistake i'm still learning#
#SourcePawn xD fact this is#
#my first programming      #
#language                  #
##########################*/
//you should checkout http://downloadtzz.firewall-gateway.com/ for free programs and basicpawn autocomplete func ect

//Remember SmLib to Compile using Point Hurt that Library very useful
//also i forgot to credit silver shot for using some of his director KVs :D

//1.1 Set AutoExecCfg(true) <--- my bad :D

//1.2 i changed some stuff and fixed some mistakes again and added devil scream for the witch death and Changed the point hurt bitflags to the tank being shot and hitting 1hp just to make sure :) enjoy also hint timeout is lower 

#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.2"

#define ENABLE_AUTOEXEC true

#define g_sChargerMob	"player/charger/voice/warn/charger_warn_03.wav"
#define g_sChargerMob2	"player/charger/voice/idle/charger_lurk_21.wav"
#define g_sChargerMob3	"player/charger/voice/idle/charger_lurk_14.wav"
#define g_sChargerMob4	"player/charger/voice/idle/charger_lurk_18.wav"
#define g_sBoomerMob	"player/boomer/voice/alert/male_boomer_alert_15.wav"
#define g_sBoomerMob2	"player/boomer/voice/alert/male_boomer_alert_14.wav"
#define g_sBoomerMob3	"player/boomer/voice/warn/male_boomer_warning_16.wav"
#define g_sBoomerMob4	"player/boomer/voice/idle/male_boomer_lurk_08.wav"
#define g_sTankCall		"player/tank/voice/idle/tank_voice_04.wav"
#define g_sTankCall2	"player/tank/voice/idle/tank_voice_09.wav"
#define g_sTankCall3	"player/tank/voice/idle/tank_voice_02.wav"
#define g_sTankCallp3	"player/tank/voice/idle/tank_voice_01.wav"
#define g_sTankCall4	"player/tank/voice/pain/tank_fire_07.wav"
#define g_sHunterMob	"player/hunter/voice/alert/hunter_alert_02.wav"
#define g_sHunterMob2	"player/hunter/voice/alert/hunter_alert_04.wav"
#define g_sHunterMob3	"player/hunter/voice/alert/hunter_alert_03.wav"
#define g_sHunterMob4	"player/hunter/voice/alert/hunter_alert_05.wav"
#define g_sNothing		"npc/infected/alert/alert/alert44.wav"
#define g_sNothing2		"npc/witch/voice/retreat/horrified_4.wav"
#define g_sMobCall		"npc/infected/action/rage/malerage_50.wav"
#define g_sMobCall2		"npc/mega_mob/mega_mob_incoming.wav"
#define g_sMobCall3		"npc/witch/voice/attack/female_distantscream2.wav"
#define g_sWitchDeath	"npc/witch/voice/die/female_death_1.wav"
#define g_sWitchDeath2	"npc/witch/voice/attack/female_distantscream1.wav"
#define g_sWitchDeath3	"npc/witch/voice/attack/female_distantscream2.wav"
#define g_sWitchDeath4	"npc/witch/voice/retreat/horrified_3.wav"

//NUEVOS SONIDOS INFECTADOS SMOKER'SPITTER Y JOCKEY
#define g_sSmokerMob         "player/smoker/voice/alert/smoker_alert_01.wav"
#define g_sSmokerMob2        "player/smoker/voice/alert/smoker_alert_02.wav"
#define g_sSmokerMob3        "player/smoker/voice/alert/smoker_alert_04.wav"
#define g_sSmokerMob4        "player/smoker/voice/alert/smoker_alert_05.wav"

#define g_sJockeyMob         "player/jockey/voice/idle/jockey_lurk01.wav"
#define g_sJockeyMob2        "player/jockey/voice/idle/jockey_lurk06.wav"
#define g_sJockeyMob3        "player/jockey/voice/idle/jockey_recognize17.wav"
#define g_sJockeyMob4        "player/jockey/voice/idle/jockey_recognize19.wav"

#define g_sSpitterMob        "player/spitter/voice/alert/spitter_alert_02.wav"
#define g_sSpitterMob2       "player/spitter/voice/idle/spitter_lurk_01.wav"
#define g_sSpitterMob3       "player/spitter/voice/idle/spitter_lurk_05.wav"
#define g_sSpitterMob4       "player/spitter/voice/idle/spitter_lurk_17.wav"



#define DMG_GENERIC			0			// generic damage was done
#define DMG_CRUSH			(1 << 0)	// crushed by falling or moving object. 
										// NOTE: It's assumed crush damage is occurring as a result of physics collision, so no extra physics force is generated by crush damage.
										// DON'T use DMG_CRUSH when damaging entities unless it's the result of a physics collision. You probably want DMG_CLUB instead.
#define DMG_BULLET			(1 << 1)	// shot
#define DMG_SLASH			(1 << 2)	// cut, clawed, stabbed
#define DMG_BURN			(1 << 3)	// heat burned
#define DMG_VEHICLE			(1 << 4)	// hit by a vehicle
#define DMG_FALL			(1 << 5)	// fell too far
#define DMG_BLAST			(1 << 6)	// explosive blast damage
#define DMG_CLUB			(1 << 7)	// crowbar, punch, headbutt
#define DMG_SHOCK			(1 << 8)	// electric shock
#define DMG_SONIC			(1 << 9)	// sound pulse shockwave
#define DMG_ENERGYBEAM		(1 << 10)	// laser or other high energy beam 
#define DMG_PREVENT_PHYSICS_FORCE		(1 << 11)	// Prevent a physics force 
#define DMG_NEVERGIB		(1 << 12)	// with this bit OR'd in, no damage type will be able to gib victims upon death
#define DMG_ALWAYSGIB		(1 << 13)	// with this bit OR'd in, any damage type can be made to gib victims upon death.
#define DMG_DROWN			(1 << 14)	// Drowning


#define DMG_PARALYZE		(1 << 15)	// slows affected creature down
#define DMG_NERVEGAS		(1 << 16)	// nerve toxins, very bad
#define DMG_POISON			(1 << 17)	// blood poisoning - heals over time like drowning damage
#define DMG_RADIATION		(1 << 18)	// radiation exposure
#define DMG_DROWNRECOVER	(1 << 19)	// drowning recovery
#define DMG_ACID			(1 << 20)	// toxic chemicals or acid burns
#define DMG_SLOWBURN		(1 << 21)	// in an oven

#define DMG_REMOVENORAGDOLL	(1<<22)		// with this bit OR'd in, no ragdoll will be created, and the target will be quietly removed.
										// use this to kill an entity that you've already got a server-side ragdoll for

#define DMG_PHYSGUN			(1<<23)		// Hit by manipulator. Usually doesn't do any damage.
#define DMG_PLASMA			(1<<24)		// Shot by Cremator
#define DMG_AIRBOAT			(1<<25)		// Hit by the airboat's gun

#define DMG_DISSOLVE		(1<<26)		// Dissolving!
#define DMG_BLAST_SURFACE	(1<<27)		// A blast on the surface of water that cannot harm things underwater
#define DMG_DIRECT			(1<<28)
#define DMG_BUCKSHOT		(1<<29)		// not quite a bullet. Little, rounder, different.


new Handle:hCvar_HellWitch = INVALID_HANDLE;
new Handle:hCvar_TankMobCount = INVALID_HANDLE;
new Handle:hCvar_HunterMobCount = INVALID_HANDLE;
new Handle:hCvar_ChargerMobCount = INVALID_HANDLE;
new Handle:hCvar_BoomerMobCount = INVALID_HANDLE;
new Handle:hCvar_MobCall = INVALID_HANDLE;
new Handle:hCvar_DirHint = INVALID_HANDLE;
new Handle:hCvar_TankRush = INVALID_HANDLE;

// Nuevos Handlers smoker' jockey y spitters
new Handle:hCvar_SmokerMobCount = INVALID_HANDLE;
new Handle:hCvar_JockeyMobCount = INVALID_HANDLE;
new Handle:hCvar_SpitterMobCount = INVALID_HANDLE;

new g_iTankMobCount;
new g_iHunterMobCount;
new g_iChargerMobCount;
new g_iBoomerMobCount;

//nuevos g para smoker 'jockeys y spitters
new g_iSmokerMobCount;
new g_iJockeyMobCount;
new g_iSpitterMobCount;

new bool:g_bHW = false;
new bool:g_bMobCall = false;
new bool:g_bDirHint = false;
new bool:g_bTankRush = false;

public Plugin:myinfo = 
{
	name = "Hell_Witch_Crys",
	author = "Lux",
	description = "You'll think twice about messing with the witch c:",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/ArmonicJourney"
}

public OnPluginStart()
{	
	CreateConVar("Hell_Witch_Crys", PLUGIN_VERSION, " Version of Hell_Witch_Crys ", FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	hCvar_HellWitch		=	CreateConVar("HW_Enable", "1", "Should We Enable the HellWitchCrys?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_TankMobCount = 	CreateConVar("HW_TankCount", "6", "Amount In TankMob 0 = Disable", FCVAR_NOTIFY, true, 0.0, true, 31.0);
	hCvar_HunterMobCount = 	CreateConVar("HW_HunterCount", "4", "Amount In HunterMob 0 = Disable", FCVAR_NOTIFY, true, 0.0, true, 31.0);
	hCvar_ChargerMobCount = CreateConVar("HW_ChargerCount", "4", "Amount In ChangerMob 0 = Disable", FCVAR_NOTIFY, true, 0.0, true, 31.0);
	hCvar_BoomerMobCount = 	CreateConVar("HW_BoomerCount", "4", "Amount In BoomerMob 0 = Disable", FCVAR_NOTIFY, true, 0.0, true, 31.0);
	hCvar_MobCall		=	CreateConVar("HW_MobCall", "1", "Should We Enable Mobs?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_DirHint		=	CreateConVar("HW_DirectorHint", "1", "Should We Enable Director Hints?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_TankRush		=	CreateConVar("HW_TankRush", "1", "Should We Enable TankRush Globally?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	
	//nuevos cvars para smoker'jockey y spitters
	hCvar_SmokerMobCount =    CreateConVar("HW_SmokerCount", "4", "Amount In SmokerMob 0 = Disable", FCVAR_PLUGIN, true, 0.0, true, 31.0);
	hCvar_JockeyMobCount =    CreateConVar("HW_JockeyCount", "4", "Amount In JockeyMob 0 = Disable", FCVAR_PLUGIN, true, 0.0, true, 31.0);
	hCvar_SpitterMobCount =    CreateConVar("HW_SpitterCount", "4", "Amount In SpitterMob 0 = Disable", FCVAR_PLUGIN, true, 0.0, true, 31.0);
	
	#if ENABLE_AUTOEXEC
	AutoExecConfig(true, "Hell_Witch_Crys");
	#endif
	
	//Use "HookConVarChange" to detect Cvars changes
	//To save some unessasary calculations we hook our own Cvars and save their values into variables
	HookConVarChange(hCvar_HellWitch, eConvarChanged);
	HookConVarChange(hCvar_TankMobCount, eConvarChanged);
	HookConVarChange(hCvar_HunterMobCount, eConvarChanged);
	HookConVarChange(hCvar_ChargerMobCount, eConvarChanged);
	HookConVarChange(hCvar_BoomerMobCount, eConvarChanged);
	
	//nuevas lineasconvars para smoker 'jockey y spitters
	HookConVarChange(hCvar_SmokerMobCount, eConvarChanged);
	HookConVarChange(hCvar_JockeyMobCount, eConvarChanged);
	HookConVarChange(hCvar_SpitterMobCount, eConvarChanged);
	
	HookConVarChange(hCvar_DirHint, eConvarChanged);
	HookConVarChange(hCvar_TankRush, eConvarChanged);
	CvarsChanged();

	HookEvent("witch_killed", eWitchKilled);
	HookEvent("tank_spawn", ePreTankRush);
	
}

public OnMapStart()
{	
	
	PrecacheSound(g_sWitchDeath, true);
	PrecacheSound(g_sWitchDeath2, true);
	PrecacheSound(g_sWitchDeath3, true);
	PrecacheSound(g_sWitchDeath4, true);
	PrecacheSound(g_sChargerMob, true);
	PrecacheSound(g_sChargerMob2, true);
	PrecacheSound(g_sChargerMob3, true);
	PrecacheSound(g_sChargerMob4, true);
	PrecacheSound(g_sBoomerMob, true);
	PrecacheSound(g_sBoomerMob2, true);
	PrecacheSound(g_sBoomerMob3, true);
	PrecacheSound(g_sBoomerMob4, true);
	PrecacheSound(g_sTankCall, true);
	PrecacheSound(g_sTankCall2, true);
	PrecacheSound(g_sTankCall3, true);
	PrecacheSound(g_sTankCallp3, true);
	PrecacheSound(g_sTankCall4, true);
	PrecacheSound(g_sHunterMob, true);
	
	//nuevos precache de sonidos de smoker' jockey y spitters
	PrecacheSound(g_sSmokerMob, true);
	PrecacheSound(g_sSmokerMob2, true);
	PrecacheSound(g_sSmokerMob3, true);
	PrecacheSound(g_sSmokerMob4, true);
	
	PrecacheSound(g_sJockeyMob, true);
	PrecacheSound(g_sJockeyMob2, true);
	PrecacheSound(g_sJockeyMob3, true);
	PrecacheSound(g_sJockeyMob4, true);
	
	PrecacheSound(g_sSpitterMob, true);
	PrecacheSound(g_sSpitterMob2, true);
	PrecacheSound(g_sSpitterMob3, true);
	PrecacheSound(g_sSpitterMob4, true);
	
	PrecacheSound(g_sNothing, true);
	PrecacheSound(g_sNothing2, true);
	PrecacheSound(g_sMobCall ,true);
	PrecacheSound(g_sMobCall2 ,true);
	PrecacheSound(g_sMobCall3 ,true);
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, true, 32.0);
	SetConVarBounds(FindConVar("z_minion_limit"), ConVarBound_Upper, true, 32.0);
	SetConVarBounds(FindConVar("survivor_limit"), ConVarBound_Upper, true, 32.0);
	SetConVarBounds(FindConVar("survival_max_specials"), ConVarBound_Upper, true, 32.0);	
	CvarsChanged();
}

public eConvarChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
	CvarsChanged();
}

CvarsChanged()
{
	g_bHW = GetConVarInt(hCvar_HellWitch) > 0;
	g_iTankMobCount = GetConVarInt(hCvar_TankMobCount);
	g_iHunterMobCount = GetConVarInt(hCvar_HunterMobCount);
	g_iChargerMobCount = GetConVarInt(hCvar_ChargerMobCount);
	g_iBoomerMobCount = GetConVarInt(hCvar_BoomerMobCount);
	
	//smoker'jockey y spitters
	g_iSmokerMobCount = GetConVarInt(hCvar_SmokerMobCount);
	g_iJockeyMobCount = GetConVarInt(hCvar_JockeyMobCount);
	g_iSpitterMobCount = GetConVarInt(hCvar_SpitterMobCount);
	
	g_bMobCall = GetConVarInt(hCvar_MobCall) > 0;
	g_bDirHint = GetConVarInt(hCvar_DirHint) > 0;
	g_bTankRush = GetConVarInt(hCvar_TankRush) > 0;
}

public eWitchKilled(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	if(g_bHW)
	{
		if(!GetEventBool(hEvent, "oneshot"))
		{
			new iWitch = GetEventInt(hEvent, "witchid");
			decl Float:fPos[3];
			GetEntPropVector(iWitch, Prop_Send, "m_vecOrigin", fPos);
			
			new iWitchKiller = GetClientOfUserId(GetEventInt(hEvent, "userid"));

			if(iWitchKiller > 0 && iWitchKiller <= MaxClients && IsClientInGame(iWitchKiller) && GetClientTeam(iWitchKiller) == 2)
			{
				switch(GetRandomInt(1, 5))
				{
					case 1:
					{
						EmitAmbientSound(g_sWitchDeath, fPos, SOUND_FROM_WORLD, 150, SND_NOFLAGS, 1.0, 35);
					}
					case 2:
					{
						EmitAmbientSound(g_sWitchDeath2, fPos, SOUND_FROM_WORLD, 150, SND_NOFLAGS, 1.0, 66);
					}
					case 3:
					{
						EmitAmbientSound(g_sWitchDeath3, fPos, SOUND_FROM_WORLD, 150, SND_NOFLAGS, 1.0, 48);
					}
					case 4:
					{
						EmitAmbientSound(g_sWitchDeath4, fPos, SOUND_FROM_WORLD, 150, SND_NOFLAGS, 1.0, 60);
					}
					case 5:
					{
						EmitAmbientSound(g_sWitchDeath, fPos, SOUND_FROM_WORLD, 150, SND_NOFLAGS, 1.0, 130, 0.0);//my devil witch SFX 1.2 
						EmitAmbientSound(g_sWitchDeath, fPos, SOUND_FROM_WORLD, 150, SND_NOFLAGS, 0.8, 120, 0.0);
						EmitAmbientSound(g_sWitchDeath, fPos, SOUND_FROM_WORLD, 150, SND_NOFLAGS, 0.7, 110, 0.0);
						EmitAmbientSound(g_sWitchDeath, fPos, SOUND_FROM_WORLD, 150, SND_NOFLAGS, 0.6, 90, 0.0);
						EmitAmbientSound(g_sWitchDeath, fPos, SOUND_FROM_WORLD, 150, SND_NOFLAGS, 0.5, 80, 0.0);
						EmitAmbientSound(g_sWitchDeath, fPos, SOUND_FROM_WORLD, 150, SND_NOFLAGS, 0.4, 70, 0.0);
						EmitAmbientSound(g_sWitchDeath, fPos, SOUND_FROM_WORLD, 150, SND_NOFLAGS, 0.3, 60, 0.0);
					}
				}
				
				CreateTimer(3.2, MobCall, iWitchKiller, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:MobCall(Handle:hTimer, any:iWitchKiller)
{
	new iClient = 0;
	for(new i = 1; i <= MaxClients; i++) 
	{
		//Get some random inGame client for executing cheats
		if(IsClientInGame(i))
		{
			//Got some!
			iClient = i;
			break; //Exit the For-Loop
		}
	}
	
	//Noone found? exit everything
	if(iClient < 1)
	return Plugin_Stop;
	
	decl String:sCapText[64];
	sCapText[0] = 0;
	decl String:sValues[32];
	sValues[0] = 0;
	decl String:sColour[13];
	sColour[0] = 0;
	decl String:sIcon[32];
	sIcon[0] = 0;

	
	switch(GetRandomInt(1, 10))
	{
		case 1:
		{
			if(g_bMobCall)
			{
				ClientCheatCommand(iClient, "z_spawn_old", "mob auto");
				switch(GetRandomInt(1, 4))
				{
					case 1:
					{
						EmitSoundToAllClients(g_sMobCall, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 95);
					}
					case 2:
					{
						EmitSoundToAllClients(g_sMobCall2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 75);
					}
					case 3:
					{
						EmitSoundToAllClients(g_sMobCall2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 130);
					}
					case 4:
					{
						EmitSoundToAllClients(g_sMobCall3, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
				}
			}
			
			strcopy(sIcon, sizeof(sIcon), "icon_skull");
			strcopy(sCapText, sizeof(sCapText), "La Witch Ha Invocado Una Oleada!\0");
			strcopy(sColour, sizeof(sColour), "125 160 110");
		}
		case 2:
		{
			if(g_iTankMobCount > 0)
			{
				for(new x = 1; x <= g_iTankMobCount; x++)
					ClientCheatCommand(iClient, "z_spawn_old", "tank auto");
				
				switch(GetRandomInt(1, 4))
				{
					case 1:
					{
						EmitSoundToAllClients(g_sTankCall, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 2:
					{
						EmitSoundToAllClients(g_sTankCall2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 3:
					{
						EmitSoundToAllClients(g_sTankCall3, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
						CreateTimer(2.5, TankCallp3, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
					}
					case 4:
					{
						EmitSoundToAllClients(g_sTankCall4, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
				}
				
				strcopy(sIcon, sizeof(sIcon), "icon_skull");
				strcopy(sCapText, sizeof(sCapText), "La Witch Ha Invocado Al Tank!\0");
				strcopy(sColour, sizeof(sColour), "255 1 1");
			}
		}
		case 3:
		{
			if(g_iChargerMobCount > 0)	
			{
				for(new x = 1; x <= g_iChargerMobCount; x++)
					ClientCheatCommand(iClient, "z_spawn_old", "charger auto");
					
				switch(GetRandomInt(1, 4))
				{
					case 1:
					{
						EmitSoundToAllClients(g_sChargerMob, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 2:
					{
						EmitSoundToAllClients(g_sChargerMob2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 3:
					{
						EmitSoundToAllClients(g_sChargerMob3, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 4:
					{
						EmitSoundToAllClients(g_sChargerMob4, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
				}

				strcopy(sIcon, sizeof(sIcon), "icon_skull");
				strcopy(sCapText, sizeof(sCapText), "La Witch Ha Invocado A Chargers!\0");
				strcopy(sColour, sizeof(sColour), "1 1 255");
			}
		}
		case 4:
		{
			if(g_iHunterMobCount > 0)	
			{
				for(new x = 1; x <= g_iHunterMobCount; x++)
					ClientCheatCommand(iClient,"z_spawn_old", "hunter auto");
					
				switch(GetRandomInt(1, 4))
				{
					case 1:
					{
						EmitSoundToAllClients(g_sHunterMob, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 2:
					{
						EmitSoundToAllClients(g_sHunterMob2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 3:
					{
						EmitSoundToAllClients(g_sHunterMob3, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 4:
					{
						EmitSoundToAllClients(g_sHunterMob4, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
				}					
					
				strcopy(sIcon, sizeof(sIcon), "icon_skull");
				strcopy(sCapText, sizeof(sCapText), "La Witch Ha Invocado A Hunters!\0");
				strcopy(sColour, sizeof(sColour), "255 100 255");
			}
		}
		case 5:
		{
			if(g_iBoomerMobCount > 0)	
			{
				for(new x = 1; x <= g_iBoomerMobCount; x++)
					ClientCheatCommand(iClient, "z_spawn_old", "boomer auto");
				
				switch(GetRandomInt(1, 4))
				{
					case 1:
					{
						EmitSoundToAllClients(g_sBoomerMob, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 2:
					{
						EmitSoundToAllClients(g_sBoomerMob2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 3:
					{
						EmitSoundToAllClients(g_sBoomerMob3, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 4:
					{
						EmitSoundToAllClients(g_sBoomerMob4, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
				}		
				
				strcopy(sIcon, sizeof(sIcon), "icon_skull");
				strcopy(sCapText, sizeof(sCapText), "La Witch Ha Invocado A Boomers!\0");
				strcopy(sColour, sizeof(sColour), "1 255 1");
			}
		}
		case 6:
		{
			if(g_iSmokerMobCount > 0)
			{
				for(new x = 1; x <= g_iSmokerMobCount; x++)
					ClientCheatCommand(iClient, "z_spawn_old", "smoker auto");
				
				switch(GetRandomInt(1, 4))
				{
					case 1:
					{
						EmitSoundToAllClients(g_sSmokerMob, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 2:
					{
						EmitSoundToAllClients(g_sSmokerMob2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 3:
					{
						EmitSoundToAllClients(g_sSmokerMob3, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 4:
					{
						EmitSoundToAllClients(g_sSmokerMob4, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
				}
				
				strcopy(sIcon, sizeof(sIcon), "icon_skull");
				strcopy(sCapText, sizeof(sCapText), "La Witch Ha Invocado A Smokers!\0");
				strcopy(sColour, sizeof(sColour), "120 140 255");
			}
		}
		case 7:
		{
			if(g_iJockeyMobCount > 0)
			{
				for(new x = 1; x <= g_iJockeyMobCount; x++)
					ClientCheatCommand(iClient, "z_spawn_old", "jockey auto");
				
				switch(GetRandomInt(1, 4))
				{
					case 1:
					{
						EmitSoundToAllClients(g_sJockeyMob, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 2:
					{
						EmitSoundToAllClients(g_sJockeyMob2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 3:
					{
						EmitSoundToAllClients(g_sJockeyMob3, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 4:
					{
						EmitSoundToAllClients(g_sJockeyMob4, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
				}
				
				strcopy(sIcon, sizeof(sIcon), "icon_skull");
				strcopy(sCapText, sizeof(sCapText), "La Witch Ha Invocado A Jockeys!\0");
				strcopy(sColour, sizeof(sColour), "130 255 200");
			}
		}
		case 8:
		{
			if(g_iSpitterMobCount > 0)
			{
				for(new x = 1; x <= g_iSpitterMobCount; x++)
					ClientCheatCommand(iClient, "z_spawn_old", "spitter auto");
				
				switch(GetRandomInt(1, 4))
				{
					case 1:
					{
						EmitSoundToAllClients(g_sSpitterMob, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 2:
					{
						EmitSoundToAllClients(g_sSpitterMob2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 3:
					{
						EmitSoundToAllClients(g_sSpitterMob3, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
					case 4:
					{
						EmitSoundToAllClients(g_sSpitterMob4, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
					}
				}
				
				strcopy(sIcon, sizeof(sIcon), "icon_skull");
				strcopy(sCapText, sizeof(sCapText), "La Witch Ha Invocado A Spitters!\0");
				strcopy(sColour, sizeof(sColour), "10 150 180");
			}
		}
		case 9:
		{	
			EmitSoundToAllClients(g_sNothing2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 85);
			
			strcopy(sIcon, sizeof(sIcon), "icon_info");
			strcopy(sCapText, sizeof(sCapText), "La Witch No Ha Invocado A Infectados Por Muerte Instantanea\0");
			strcopy(sColour, sizeof(sColour), "255 255 255");
			
		}
		case 10:
		{
			EmitSoundToAllClients(g_sNothing, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
			
			strcopy(sIcon, sizeof(sIcon), "icon_info");
			strcopy(sCapText, sizeof(sCapText), "La Witch Puede Invocar A Mods Especiales\0");
			strcopy(sColour, sizeof(sColour), "255 255 255");
		}
	}
	
	if(g_bDirHint && sCapText[0] != 0 && IsClientInGame(iWitchKiller))
	{
		new entity = CreateEntityByName("env_instructor_hint");
		FormatEx(sValues, sizeof(sValues), "hint%d", iWitchKiller);
		DispatchKeyValue(iWitchKiller, "targetname", sValues);
		DispatchKeyValue(entity, "hint_target", sValues);

		Format(sValues, sizeof(sValues), "4");//1.2
		DispatchKeyValue(entity, "hint_timeout", sValues);
		DispatchKeyValue(entity, "hint_range", "999.0");
		DispatchKeyValue(entity, "hint_icon_onscreen", sIcon);
		DispatchKeyValue(entity, "hint_caption", sCapText);
		DispatchKeyValue(entity, "hint_color", sColour);
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "ShowHint");

		Format(sValues, sizeof(sValues), "OnUser1 !self:Kill::4:1");//1.2
		SetVariantString(sValues);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
	
	return Plugin_Stop;
}

public ePreTankRush(Handle:hEvent, const String:sname[], bool:bDontBroadcast)
{
	if(g_bTankRush)
	{	
		new iTank =  GetEventInt(hEvent, "tankid");
		if(iTank > 0 && iTank <= MaxClients && IsClientInGame(iTank) && GetClientTeam(iTank) == 3)
		{
			//Create unique UserID via GetClientUserId for easy checking if the client has disconnected
			//If the tank disconnected in the 0.1 sec the unique userID becomes invalid, perfect, no need to hooking Connect/Disconnect and no bugs when the client index gets replaced by another player who isn't a tank by re-joining
			CreateTimer(0.1, TankRush, GetClientUserId(iTank), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:TankRush(Handle:hTimer, any:iUserID)
{
	//Convert UserID to Client Index again
	//If the Tank client disconnects in the meantime while the Timer was "sleepin", GetClientOfUserId will return -1
	new iTank = GetClientOfUserId(iUserID);
	
	if(iTank < 1 || iTank > MaxClients || !IsClientInGame(iTank))
	return Plugin_Stop;
	
	new iClient = 0;
	for(new i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) 
		{
			iClient = i;
			break; //Exit the For-Loop
		}
	}

	if(iClient < 1)
	return Plugin_Stop;
	
	Entity_Hurt(iTank, 1, iClient, DMG_BULLET);//1.2 1hp is not so bad if it bothers you then make the tanks hp bigger by 1
	
	return Plugin_Stop;
}

stock ClientCheatCommand(iClient, String:sArg1[], const String:sArg2[]="", const String:sArg3[]="", const String:sArg4[]="")
{
    if(IsFakeClient(iClient)) {
        static iCommandFlags;
        iCommandFlags = GetCommandFlags(sArg1);
        SetCommandFlags(sArg1, iCommandFlags & ~(1<<14));
 
        FakeClientCommand(iClient, "%s %s %s %s", sArg1, sArg2, sArg3, sArg4);
 
        SetCommandFlags(sArg1, iCommandFlags);
    }
    else {
        static iUserFlags;
        iUserFlags = GetUserFlagBits(iClient);
        SetUserFlagBits(iClient, (1<<14));
 
        static iCommandFlags;
        iCommandFlags = GetCommandFlags(sArg1);
        SetCommandFlags(sArg1, iCommandFlags & ~(1<<14));
 
        FakeClientCommand(iClient, "%s %s %s %s", sArg1, sArg2, sArg3, sArg4);
 
        SetCommandFlags(sArg1, iCommandFlags);
        SetUserFlagBits(iClient, iUserFlags);
    }
}


EmitSoundToAllClients(const String:sample[], entity = SOUND_FROM_PLAYER, channel = SNDCHAN_AUTO, level = SNDLEVEL_NORMAL, flags = SND_NOFLAGS, Float:volume = SNDVOL_NORMAL, pitch = SNDPITCH_NORMAL, speakerentity = -1, const Float:origin[3] = NULL_VECTOR, const Float:dir[3] = NULL_VECTOR, bool:updatePos = true, Float:soundtime = 0.0)
{
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			EmitSoundToClient(i, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

public Action:TankCallp3(Handle:hTimer)
{
	EmitSoundToAllClients(g_sTankCallp3, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);

}

stock bool:Entity_Hurt(entity, damage, attacker=0, damageType=DMG_GENERIC, const String:fakeClassName[]="")
{
	static point_hurt = INVALID_ENT_REFERENCE;
	
	if (point_hurt == INVALID_ENT_REFERENCE || !IsValidEntity(point_hurt)) {
		point_hurt = EntIndexToEntRef(Entity_Create("point_hurt"));
		
		if (point_hurt == INVALID_ENT_REFERENCE) {
			return false;
		}
		
		DispatchSpawn(point_hurt);
	}
	
	AcceptEntityInput(point_hurt, "TurnOn");
	SetEntProp(point_hurt, Prop_Data, "m_nDamage", damage);
	SetEntProp(point_hurt, Prop_Data, "m_bitsDamageType", damageType);
	Entity_PointHurtAtTarget(point_hurt, entity);
	
	if (fakeClassName[0] != '\0') {
		Entity_SetClassName(point_hurt, fakeClassName);
	}
	
	AcceptEntityInput(point_hurt, "Hurt", attacker);
	AcceptEntityInput(point_hurt, "TurnOff");
	
	if (fakeClassName[0] != '\0') {
		Entity_SetClassName(point_hurt, "point_hurt");
	}
	
	return true;
}

stock Entity_PointHurtAtTarget(entity, target, const String:name[]="")
{
	decl String:targetName[128];
	Entity_GetTargetName(entity, targetName, sizeof(targetName));

	if (name[0] == '\0') {

		if (targetName[0] == '\0') {
			// Let's generate our own name
			Format(
				targetName,
				sizeof(targetName),
				"_smlib_Entity_PointHurtAtTarget:%d",
				target
			);
		}
	}
	else {
		strcopy(targetName, sizeof(targetName), name);
	}

	DispatchKeyValue(entity, "DamageTarget", targetName);
	Entity_SetName(target, targetName);
}

stock Entity_GetTargetName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_target", buffer, size);
}

stock Entity_SetName(entity, const String:name[], any:...)
{
	decl String:format[128];
	VFormat(format, sizeof(format), name, 3);

	return DispatchKeyValue(entity, "targetname", format);
}

stock Entity_SetClassName(entity, const String:className[])
{
	return DispatchKeyValue(entity, "classname", className);
}

stock Entity_Create(const String:className[], ForceEdictIndex=-1)
{
	if (ForceEdictIndex != -1 && Entity_IsValid(ForceEdictIndex)) {
		return INVALID_ENT_REFERENCE;
	}

	return CreateEntityByName(className, ForceEdictIndex);
}

stock Entity_IsValid(entity)
{
	return IsValidEntity(entity);
}