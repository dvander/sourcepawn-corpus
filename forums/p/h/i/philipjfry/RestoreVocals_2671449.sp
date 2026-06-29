/***************************************************************************************************************************************************
----------------------------------------------------------------------------------------------------------
	Based on L4D2 melee grunts by DeathChaos25 - https://forums.alliedmods.net/showthread.php?p=2271844
----------------------------------------------------------------------------------------------------------	
	About:
	
	This plugin requires sceneprocessor to work https://forums.alliedmods.net/showthread.php?p=2147410
	
	Restores almost all laugh/thanks/yes/no/hurrah vocals found in the game files that valve didnt implement / left out and adds other battlecrys grunts..
	Utilizes sceneprocessor's OnVocalizeCommand native to hook radial use.
	
	Tank Killed
	Makes the killer of a tank vocalize taunt lines.
	
	Picking up items
	Vocalizes when survivors (coach) picks up a sniper or pistols.
	
	Melee Grunts
	Vocalizes when a survivor swings his melee weapon.
	
	On vocalize cmd
	Vocalizes 'unused' survivor sounds laughs etc when using the radialmenu.
----------------------------------------------------------------------------------------------------------
	
***************************************************************************************************************************************************/
#define PLUGIN_VERSION		"1.0.0"

#include <sourcemod>
#include <sdktools>
#include <sceneprocessor>

#pragma	semicolon	1
#pragma newdecls required

#define	DEBUG			0

ConVar g_hVocalChance;
ConVar g_hTankTauntChance;
ConVar g_hMeleeGruntChance;

#define TEAM_SURVIVOR		2

#define MAX_NICK_THANKS			3
#define MAX_COACH_THANKS			4
#define MAX_TAUNTS_COACH			14
#define MAX_COACH_HURRAH			19
#define MAX_COACH_LAUGHS			16
#define MAX_TAUNTS_NICK			17
#define MAX_NICK_LAUGHS			11
#define MAX_NICK_HURRAH			11
#define MAX_TAUNTS_ELLIS			3
#define MAX_ELLIS_LAUGHS			5
#define MAX_BILL_LAUGHS			11
#define MAX_LOUIS_LAUGHS			16
#define MAX_FRANCIS_LAUGHS		10
#define MAX_ZOEY_LAUGHS			15
#define MAX_TAKESNIPER_COACH		3
#define MAX_TAKEPISTOL_COACH		3
#define MAX_MELEESWING_COACH		14
#define MAX_MELEESWING_ELLIS		7
#define MAX_COACH_YES				4

#define COACH_MDL		"models/survivors/survivor_coach.mdl"
#define NICK_MDL		"models/survivors/survivor_gambler.mdl"
#define ELLIS_MDL		"models/survivors/survivor_mechanic.mdl"
#define FRANCIS_MDL	"models/survivors/survivor_biker.mdl"
#define BILL_MDL		"models/survivors/survivor_namvet.mdl"
#define ZOEY_MDL		"models/survivors/survivor_teenangst.mdl"
#define LOUIS_MDL		"models/survivors/survivor_manager.mdl"

char s_SoundsPathNickThanks[MAX_NICK_THANKS][] =
{
	"player/survivor/voice/gambler/dlc1_c6m3_finalel4d1items01.wav",
	"player/survivor/voice/gambler/dlc1_c6m3_finalel4d1items06.wav",
	"player/survivor/voice/gambler/dlc1_c6m3_finalel4d1items07.wav"
};

char s_SoundsPathCoachThanks[MAX_COACH_THANKS][] =
{
	"player/survivor/voice/coach/dlc1_c6m3_finalel4d1items07.wav",
	"player/survivor/voice/coach/dlc1_c6m3_finalel4d1items01.wav",
	"player/survivor/voice/coach/dlc1_c6m3_finalel4d1items02.wav",
	"player/survivor/voice/coach/thanks08.wav"
};

char s_SoundsPathCoach[MAX_TAUNTS_COACH][] =
{
	"player/survivor/voice/coach/battlecry01.wav",
	"player/survivor/voice/coach/battlecry02.wav",
	"player/survivor/voice/coach/battlecry03.wav",
	"player/survivor/voice/coach/battlecry04.wav",
	"player/survivor/voice/coach/battlecry05.wav",
	"player/survivor/voice/coach/battlecry06.wav",
	"player/survivor/voice/coach/battlecry07.wav",
	"player/survivor/voice/coach/battlecry08.wav",
	"player/survivor/voice/coach/battlecry09.wav",
	"player/survivor/voice/coach/worldsigns37.wav",
	"player/survivor/voice/coach/worldsigns34.wav",
	"player/survivor/voice/coach/worldsigns10.wav",
	"player/survivor/voice/coach/worldsigns08.wav",
	"player/survivor/voice/coach/dlc1_community04.wav"
};

char s_SoundsPathCoachHurrah[MAX_COACH_HURRAH][] =
{
	"player/survivor/voice/coach/positivenoise01.wav",
	"player/survivor/voice/coach/positivenoise02.wav",
	"player/survivor/voice/coach/positivenoise04.wav",
	"player/survivor/voice/coach/positivenoise05.wav",
	"player/survivor/voice/coach/positivenoise06.wav",
	"player/survivor/voice/coach/positivenoise07.wav",
	"player/survivor/voice/coach/positivenoise09.wav",
	"player/survivor/voice/coach/worldc4m303.wav",
	"player/survivor/voice/coach/worldc4m208.wav",
	"player/survivor/voice/coach/worldc4m110.wav",
	"player/survivor/voice/coach/worldc1m2b27.wav",
	"player/survivor/voice/coach/hurrah22.wav",
	"player/survivor/voice/coach/worldc2m5b67.wav",
	"player/survivor/voice/coach/worldc2m5b94.wav",
	"player/survivor/voice/coach/worldc2m5b88.wav",
	"player/survivor/voice/coach/worldc2m2b05.wav",
	"player/survivor/voice/coach/worldc2m2b06.wav",
	"player/survivor/voice/coach/worldc3m4b07.wav",
	"player/survivor/voice/coach/dlc1_c6m3_finalecinematic03.wav"
};

char s_SoundsPathCoachLaughs[MAX_COACH_LAUGHS][] =
{
	"player/survivor/voice/coach/laughter02.wav",
	"player/survivor/voice/coach/laughter03.wav",
	"player/survivor/voice/coach/laughter05.wav",
	"player/survivor/voice/coach/laughter09.wav",
	"player/survivor/voice/coach/laughter08.wav",
	"player/survivor/voice/coach/laughter10.wav",
	"player/survivor/voice/coach/laughter11.wav",
	"player/survivor/voice/coach/laughter06.wav",
	"player/survivor/voice/coach/laughter12.wav",
	"player/survivor/voice/coach/laughter15.wav",
	"player/survivor/voice/coach/laughter18.wav",
	"player/survivor/voice/coach/laughter19.wav",
	"player/survivor/voice/coach/laughter17.wav",
	"player/survivor/voice/coach/laughter23.wav",
	"player/survivor/voice/coach/laughter20.wav",
	"player/survivor/voice/coach/laughter21.wav"
};

char s_SoundsPathNick[MAX_TAUNTS_NICK][] =
{
	"player/survivor/voice/gambler/positivenoise04.wav",
	"player/survivor/voice/gambler/positivenoise05.wav",
	"player/survivor/voice/gambler/positivenoise06.wav",
	"player/survivor/voice/gambler/positivenoise08.wav",
	"player/survivor/voice/gambler/positivenoise07.wav",
	"player/survivor/voice/gambler/positivenoise09.wav",
	"player/survivor/voice/gambler/positivenoise10.wav",
	"player/survivor/voice/gambler/positivenoise11.wav",
	"player/survivor/voice/gambler/positivenoise12.wav",
	"player/survivor/voice/gambler/positivenoise13.wav",
	"player/survivor/voice/gambler/positivenoise02.wav",
	"player/survivor/voice/gambler/positivenoise03.wav",
	"player/survivor/voice/gambler/battlecry02.wav",
	"player/survivor/voice/gambler/battlecry04.wav",
	"player/survivor/voice/gambler/battlecry03.wav",
	"player/survivor/voice/gambler/dlc1_c6m1_weddingwitchdead11.wav",
	"player/survivor/voice/gambler/dlc1_c6m1_weddingwitchdead02.wav"
};

char s_SoundsPathNickLaughs[MAX_NICK_LAUGHS][] =
{
	"player/survivor/voice/gambler/laughter02.wav",
	"player/survivor/voice/gambler/laughter04.wav",
	"player/survivor/voice/gambler/laughter05.wav",
	"player/survivor/voice/gambler/laughter06.wav",
	"player/survivor/voice/gambler/laughter07.wav",
	"player/survivor/voice/gambler/laughter08.wav",
	"player/survivor/voice/gambler/laughter09.wav",
	"player/survivor/voice/gambler/laughter10.wav",
	"player/survivor/voice/gambler/laughter11.wav",
	"player/survivor/voice/gambler/laughter12.wav",
	"player/survivor/voice/gambler/laughter13.wav"
};

char s_SoundsPathNickHurrahs[MAX_NICK_HURRAH][] =
{
	"player/survivor/voice/gambler/worldc4m102.wav",
	"player/survivor/voice/gambler/worldc4m103.wav",
	"player/survivor/voice/gambler/worldc4m104.wav",
	"player/survivor/voice/gambler/worldc4m105.wav",
	"player/survivor/voice/gambler/hurrah07.wav",
	"player/survivor/voice/gambler/hurrah08.wav",
	"player/survivor/voice/gambler/hurrah09.wav",
	"player/survivor/voice/gambler/hurrah10.wav",
	"player/survivor/voice/gambler/hurrah11.wav",
	"player/survivor/voice/gambler/worldc2m5b42.wav",
	"player/survivor/voice/gambler/worldc2m2b12.wav"
};

char s_SoundsPathEllis[MAX_TAUNTS_ELLIS][] =
{
	"player/survivor/voice/mechanic/battlecry01.wav",
	"player/survivor/voice/mechanic/hurrah21.wav",
	"player/survivor/voice/mechanic/killconfirmationellisr07.wav"
};

char s_SoundsPathEllisLaughs[MAX_ELLIS_LAUGHS][] =
{
	"player/survivor/voice/mechanic/laughter01.wav",
	"player/survivor/voice/mechanic/laughter02.wav",
	"player/survivor/voice/mechanic/laughter03.wav",
	"player/survivor/voice/mechanic/laughter07.wav",
	"player/survivor/voice/mechanic/laughter09.wav"
};

char s_SoundsPathBillLaughs[MAX_BILL_LAUGHS][] =
{
	"player/survivor/voice/namvet/laughter01.wav",
	"player/survivor/voice/namvet/laughter02.wav",
	"player/survivor/voice/namvet/laughter05.wav",
	"player/survivor/voice/namvet/laughter06.wav",
	"player/survivor/voice/namvet/laughter07.wav",
	"player/survivor/voice/namvet/laughter08.wav",
	"player/survivor/voice/namvet/laughter09.wav",
	"player/survivor/voice/namvet/laughter10.wav",
	"player/survivor/voice/namvet/laughter12.wav",
	"player/survivor/voice/namvet/laughter13.wav",
	"player/survivor/voice/namvet/laughter14.wav"
};

char s_SoundsPathLouisLaughs[MAX_LOUIS_LAUGHS][] =
{
	"player/survivor/voice/manager/laughter01.wav",
	"player/survivor/voice/manager/laughter02.wav",
	"player/survivor/voice/manager/laughter03.wav",
	"player/survivor/voice/manager/laughter05.wav",
	"player/survivor/voice/manager/laughter06.wav",
	"player/survivor/voice/manager/laughter07.wav",
	"player/survivor/voice/manager/laughter08.wav",
	"player/survivor/voice/manager/laughter09.wav",
	"player/survivor/voice/manager/laughter10.wav",
	"player/survivor/voice/manager/laughter11.wav",
	"player/survivor/voice/manager/laughter12.wav",
	"player/survivor/voice/manager/laughter14.wav",
	"player/survivor/voice/manager/laughter15.wav",
	"player/survivor/voice/manager/laughter16.wav",
	"player/survivor/voice/manager/laughter18.wav",
	"player/survivor/voice/manager/laughter19.wav"
};

char s_SoundsPathFrancisLaughs[MAX_FRANCIS_LAUGHS][] =
{
	"player/survivor/voice/biker/laughter01.wav",
	"player/survivor/voice/biker/laughter02.wav",
	"player/survivor/voice/biker/laughter03.wav",
	"player/survivor/voice/biker/laughter05.wav",
	"player/survivor/voice/biker/laughter06.wav",
	"player/survivor/voice/biker/laughter07.wav",
	"player/survivor/voice/biker/laughter08.wav",
	"player/survivor/voice/biker/laughter09.wav",
	"player/survivor/voice/biker/laughter10.wav",
	"player/survivor/voice/biker/laughter11.wav"
};

char s_SoundsPathZoeyLaughs[MAX_ZOEY_LAUGHS][] =
{
	"player/survivor/voice/teengirl/laughter01.wav",
	"player/survivor/voice/teengirl/laughter03.wav",
	"player/survivor/voice/teengirl/laughter04.wav",
	"player/survivor/voice/teengirl/laughter05.wav",
	"player/survivor/voice/teengirl/laughter07.wav",
	"player/survivor/voice/teengirl/laughter08.wav",
	"player/survivor/voice/teengirl/laughter09.wav",
	"player/survivor/voice/teengirl/laughter10.wav",
	"player/survivor/voice/teengirl/laughter12.wav",
	"player/survivor/voice/teengirl/laughter13.wav",
	"player/survivor/voice/teengirl/laughter15.wav",
	"player/survivor/voice/teengirl/laughter16.wav",
	"player/survivor/voice/teengirl/laughter17.wav",
	"player/survivor/voice/teengirl/laughter19.wav",
	"player/survivor/voice/teengirl/laughter20.wav"
};

char s_SoundsPathCoachPickUpSniper[MAX_TAKESNIPER_COACH][] =
{
	"player/survivor/voice/coach/takesniper01.wav",
	"player/survivor/voice/coach/takesniper02.wav",
	"player/survivor/voice/coach/takesniper03.wav"
};

char s_SoundsPathCoachPickUpPistols[MAX_TAKEPISTOL_COACH][] =
{
	"player/survivor/voice/coach/takepistol01.wav",
	"player/survivor/voice/coach/takepistol02.wav",
	"player/survivor/voice/coach/takepistol03.wav"
};

char s_SoundsCoachMeleeSwing[MAX_MELEESWING_COACH][] =
{
	"player/survivor/voice/coach/meleeswing05.wav", 
	"player/survivor/voice/coach/meleeswing08.wav", 
	"player/survivor/voice/coach/meleeswing09.wav", 
	"player/survivor/voice/coach/meleeswing10.wav", 
	"player/survivor/voice/coach/meleeswing11.wav", 
	"player/survivor/voice/coach/meleeswing12.wav", 
	"player/survivor/voice/coach/meleeswing13.wav", 
	"player/survivor/voice/coach/meleeswing14.wav", 
	"player/survivor/voice/coach/meleeswing15.wav", 
	"player/survivor/voice/coach/meleeswing16.wav", 
	"player/survivor/voice/coach/meleeswing17.wav", 
	"player/survivor/voice/coach/meleeswing18.wav", 
	"player/survivor/voice/coach/meleeswing19.wav",
	"player/survivor/voice/coach/meleeswing20.wav"
};

char s_SoundsEllisMeleeSwing[MAX_MELEESWING_ELLIS][] =
{
	"player/survivor/voice/mechanic/meleeswing01.wav",
	"player/survivor/voice/mechanic/meleeswing02.wav",
	"player/survivor/voice/mechanic/meleeswing03.wav",
	"player/survivor/voice/mechanic/meleeswing04.wav",
	"player/survivor/voice/mechanic/meleeswing05.wav",
	"player/survivor/voice/mechanic/meleeswing06.wav",
	"player/survivor/voice/mechanic/meleeswing07.wav"
};

char s_SoundsPathYesCoach[MAX_COACH_YES][] =
{
	"player/survivor/voice/coach/yes09.wav",
	"player/survivor/voice/coach/yes11.wav",
	"player/survivor/voice/coach/worldsigns41.wav",
	"player/survivor/voice/coach/worldsigns24.wav"
};

public Plugin myinfo =
{
	name = "Vocalization Restore",
	author = "Gravity",
	description = "Restores all laugh/taunt files (some left unused) for survivors to vocalize aka spam.",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	HookEvent("tank_killed", Event_TankKilled);
	HookEvent("item_pickup", Event_ItemPickup);
	HookEvent("weapon_fire", Event_WeaponFire);
	
	CreateConVar("restorevocals_version", PLUGIN_VERSION, "Version of the plugin.");
	g_hMeleeGruntChance 	= CreateConVar("restorevocals_meleegrunt_chance", "20", "Chance out of 100 that survivors vocalize melee grunts.", FCVAR_NOTIFY, true, 1.0, true, 100.0);
	g_hVocalChance 		= CreateConVar("restorevocals_vocalize_chance", "60", "Chance out of 100 that a survivor can vocalize unused lines.", FCVAR_NOTIFY, true, 1.0, true, 100.0);
	g_hTankTauntChance	= CreateConVar("restorevocals_tanktaunt_chance", "30", "Chance out of 100 that the survivors vocalize tank kill taunts.", FCVAR_NOTIFY, true, 1.0, true, 1.0);
	
	AutoExecConfig(true, "RestoreVocals");
}

/*******************************
	Precache the sounds
*******************************/

public void OnMapStart()
{
	for( int i = 0; i < MAX_TAUNTS_COACH; i++ )
	{
		PrefetchSound(s_SoundsPathCoach[i]);
		PrecacheSound(s_SoundsPathCoach[i], true);
	}
	
	for( int i = 0; i < MAX_TAUNTS_NICK; i++ )
	{
		PrefetchSound(s_SoundsPathNick[i]);
		PrecacheSound(s_SoundsPathNick[i], true);
	}
	
	for( int i = 0; i < MAX_TAUNTS_ELLIS; i++ )
	{
		PrefetchSound(s_SoundsPathEllis[i]);
		PrecacheSound(s_SoundsPathEllis[i], true);
	}
	
	for( int i = 0; i < MAX_COACH_LAUGHS; i++ )
	{
		PrefetchSound(s_SoundsPathCoachLaughs[i]);
		PrecacheSound(s_SoundsPathCoachLaughs[i], true);
	}
	
	for( int i = 0; i < MAX_NICK_LAUGHS; i++ )
	{
		PrefetchSound(s_SoundsPathNickLaughs[i]);
		PrecacheSound(s_SoundsPathNickLaughs[i], true);
	}
	
	for( int i = 0; i < MAX_BILL_LAUGHS; i++ )
	{
		PrefetchSound(s_SoundsPathBillLaughs[i]);
		PrecacheSound(s_SoundsPathBillLaughs[i], true);
	}
	
	for( int i = 0; i < MAX_COACH_HURRAH; i++ )
	{
		PrefetchSound(s_SoundsPathCoachHurrah[i]);
		PrecacheSound(s_SoundsPathCoachHurrah[i], true);
	}
	
	for( int i = 0; i < MAX_ELLIS_LAUGHS; i++ )
	{
		PrefetchSound(s_SoundsPathEllisLaughs[i]);
		PrecacheSound(s_SoundsPathEllisLaughs[i], true);
	}
	
	for( int i = 0; i < MAX_LOUIS_LAUGHS; i++ )
	{
		PrefetchSound(s_SoundsPathLouisLaughs[i]);
		PrecacheSound(s_SoundsPathLouisLaughs[i], true);
	}
	
	for( int i = 0; i < MAX_ZOEY_LAUGHS; i++ )
	{
		PrefetchSound(s_SoundsPathZoeyLaughs[i]);
		PrecacheSound(s_SoundsPathZoeyLaughs[i], true);
	}
	
	for( int i = 0; i < MAX_FRANCIS_LAUGHS; i++ )
	{
		PrefetchSound(s_SoundsPathFrancisLaughs[i]);
		PrecacheSound(s_SoundsPathFrancisLaughs[i], true);
	}
	
	for( int i = 0; i < MAX_NICK_HURRAH; i++ )
	{
		PrefetchSound(s_SoundsPathNickHurrahs[i]);
		PrecacheSound(s_SoundsPathNickHurrahs[i], true);
	}
	
	for( int i = 0; i < MAX_TAKESNIPER_COACH; i++ )
	{
		PrefetchSound(s_SoundsPathCoachPickUpSniper[i]);
		PrecacheSound(s_SoundsPathCoachPickUpSniper[i], true);
	}
	
	for( int i = 0; i < MAX_TAKEPISTOL_COACH; i++ )
	{
		PrefetchSound(s_SoundsPathCoachPickUpPistols[i]);
		PrecacheSound(s_SoundsPathCoachPickUpPistols[i], true);
	}
	
	for( int i = 0; i < MAX_MELEESWING_COACH; i++ )
	{
		PrefetchSound(s_SoundsCoachMeleeSwing[i]);
		PrecacheSound(s_SoundsCoachMeleeSwing[i], true);
	}
	
	for( int i = 0; i < MAX_MELEESWING_ELLIS; i++ )
	{
		PrefetchSound(s_SoundsEllisMeleeSwing[i]);
		PrecacheSound(s_SoundsEllisMeleeSwing[i], true);
	}
	
	for( int i = 0; i < MAX_COACH_THANKS; i++ )
	{
		PrefetchSound(s_SoundsPathCoachThanks[i]);
		PrecacheSound(s_SoundsPathCoachThanks[i], true);
	}
	
	for( int i = 0; i < MAX_NICK_THANKS; i++ )
	{
		PrefetchSound(s_SoundsPathNickThanks[i]);
		PrecacheSound(s_SoundsPathNickThanks[i], true);
	}
	
	for( int i = 0; i < MAX_COACH_YES; i++ )
	{
		PrefetchSound(s_SoundsPathYesCoach[i]);
		PrecacheSound(s_SoundsPathYesCoach[i], true);
	}
}

/***************************
	Events
***************************/

//make killer of a tank vocalize a random taunt
// TODO: add l4d1 survivor lines possibly
public Action Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	int killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if( !IsSurvivor(killer) )
	{
		return Plugin_Continue;
	}
	
	// This survivor is already vocalizing
	if( IsActorBusy(killer) )
	{
		return Plugin_Continue;
	}
	
	int vChance = GetRandomInt(1, 100);
	if( vChance > GetConVarInt(g_hTankTauntChance) )
	{
		return Plugin_Continue;
	}
	
	char sModel[42];
	GetClientModel(killer, sModel, sizeof(sModel));
	
	if ( StrEqual(sModel, COACH_MDL) )
	{
		int iRandom = GetRandomInt(0, MAX_TAUNTS_COACH - 1);
		EmitSoundToAll(s_SoundsPathCoach[iRandom], killer, SNDCHAN_VOICE);
	}
	else if ( StrEqual(sModel, NICK_MDL) )
	{
		int iRandom = GetRandomInt(0, MAX_TAUNTS_NICK - 1);
		EmitSoundToAll(s_SoundsPathNick[iRandom], killer, SNDCHAN_VOICE);
	}
	else if ( StrEqual(sModel, ELLIS_MDL) )
	{
		int iRandom = GetRandomInt(0, MAX_TAUNTS_ELLIS - 1);
		EmitSoundToAll(s_SoundsPathEllis[iRandom], killer, SNDCHAN_VOICE);
	}
	
	return Plugin_Continue;
}

//make survivors vocalize melee swings
public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if( !IsSurvivor(client) )
	{
		return Plugin_Continue;
	}
	
	// This survivor is already vocalizing
	if( IsActorBusy(client) )
	{
		return Plugin_Continue;
	}
	
	// continue with the original action allow vocalization.
	int vChance = GetRandomInt(1, 100);
	if( vChance > GetConVarInt(g_hMeleeGruntChance) )
	{
		return Plugin_Continue;
	}
	
	char sWeapon[42];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	
	if ( StrEqual(sWeapon, "melee") )
	{	
		char sModel[42];
		GetClientModel(client, sModel, sizeof(sModel));
		
		if ( StrEqual(sModel, COACH_MDL) )
		{
			int iRandom = GetRandomInt(0, MAX_MELEESWING_COACH - 1);
			EmitSoundToAll(s_SoundsCoachMeleeSwing[iRandom], client, SNDCHAN_VOICE);
		}
		else if ( StrEqual(sModel, ELLIS_MDL) )
		{
			int iRandom = GetRandomInt(0, MAX_MELEESWING_ELLIS - 1);
			EmitSoundToAll(s_SoundsEllisMeleeSwing[iRandom], client, SNDCHAN_VOICE);
		}
	}
	
	return Plugin_Continue;
}

public Action Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if( !IsSurvivor(client) )
	{
		return Plugin_Continue;
	}
	
	// This survivor is already vocalizing
	if( IsActorBusy(client) )
	{
		return Plugin_Continue;
	}
	
	// continue with the original action allow vocalization.
	int vChance = GetRandomInt(1, 100);
	if( vChance > GetConVarInt(g_hVocalChance) )
	{
		return Plugin_Continue;
	}
	
	char sWeapon[42];
	GetEventString(event, "item", sWeapon, sizeof(sWeapon));
	
	char sModel[42];
	GetClientModel(client, sModel, sizeof(sModel));
	
	if( StrEqual(sWeapon, "sniper_military") )
	{
		if ( StrEqual(sModel, COACH_MDL) )
		{
			int iRandom = GetRandomInt(0, MAX_TAKESNIPER_COACH - 1);
			EmitSoundToAll(s_SoundsPathCoachPickUpSniper[iRandom], client, SNDCHAN_VOICE);
		}
	}
	
	else if( StrEqual(sWeapon, "pistol") )
	{
		if ( StrEqual(sModel, COACH_MDL) )
		{
			int iRandom = GetRandomInt(0, MAX_TAKEPISTOL_COACH - 1);
			EmitSoundToAll(s_SoundsPathCoachPickUpPistols[iRandom], client, SNDCHAN_VOICE);
		}
	}
	
	return Plugin_Continue;
}

/***************************************************************************************************
	On Vocalize Command - When the client is going to vocalize.
	
	Need to delay the EmitSoundToAll function a bit (100ms) after we cancel the current scene.
****************************************************************************************************/

public Action OnVocalizeCommand(int client, const char[] vocalize, int initiator)
{
	if (client != initiator)
	{
		return Plugin_Continue;
	}
	
	if( !IsSurvivor(client) )
	{
		return Plugin_Continue;
	}
	
	char searchVocalize[MAX_VOCALIZE_LENGTH];
	strcopy(searchVocalize, MAX_VOCALIZE_LENGTH, vocalize);
	int searchVocalizeLen = strlen(searchVocalize);
	for (int i = 1; i < searchVocalizeLen; i++)
	{
		if ( IsCharMB(searchVocalize[i]) )
		{
			return Plugin_Continue;
		}
	}
	
	// continue with the original action allow vocalization.
	int vChance = GetRandomInt(1, 100);
	if( vChance > GetConVarInt(g_hVocalChance) )
	{
		return Plugin_Continue;
	}
	
	#if DEBUG
	PrintToChat(client, "OnVocalizeCommand");
	#endif
	
	//	Laughter
	if( StrEqual(searchVocalize, "PlayerLaugh") )
	{
		// Cancel the vocalization beforehand so we can actually play our unused line
		if( IsActorBusy(client) )
		{
			CancelScene(client);
			return Plugin_Stop;
		}
		
		#if DEBUG
		PrintToChat(client, "OnVocalizeCommand - PlayerLaugh");
		#endif
		
		CreateTimer(0.1, Timer_PlayerLaugh, client);
	}
	
	// Taunt
	else if( StrEqual(searchVocalize, "PlayerTaunt") )
	{
		// Cancel the vocalization beforehand so we can actually play our unused line
		if( IsActorBusy(client) )
		{
			CancelScene(client);
			return Plugin_Stop;
		}
		
		CreateTimer(0.1, Timer_PlayerTaunt, client);
	}
	
	// Hurrah
	else if( StrEqual(searchVocalize, "PlayerHurrah") )
	{
		// Cancel the vocalization beforehand so we can actually play our unused line
		if( IsActorBusy(client) )
		{
			CancelScene(client);
			return Plugin_Stop;
		}
		
		CreateTimer(0.1, Timer_PlayerHurrah, client);
	}
	
	// Thanks
	else if( StrEqual(searchVocalize, "PlayerThanks") )
	{
		// Cancel the vocalization beforehand so we can actually play our unused line
		if( IsActorBusy(client) )
		{
			CancelScene(client);
			return Plugin_Stop;
		}
		
		CreateTimer(0.1, Timer_PlayerThanks, client);
	}
	
	// Yes
	else if( StrEqual(searchVocalize, "PlayerYes") )
	{
		// Cancel the vocalization beforehand so we can actually play our unused line
		if( IsActorBusy(client) )
		{
			CancelScene(client);
			return Plugin_Stop;
		}
		
		CreateTimer(0.1, Timer_PlayerYes, client);
	}
	
	return Plugin_Continue;
}

bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR);
}

public Action Timer_PlayerLaugh(Handle timer, any client)
{
	if(client && IsClientInGame(client))
	{
		char sModel[42];
		GetClientModel(client, sModel, sizeof(sModel));
		
		if ( StrEqual(sModel, COACH_MDL) )
		{
			int iRandom = GetRandomInt(0, MAX_COACH_LAUGHS - 1);
			EmitSoundToAll(s_SoundsPathCoachLaughs[iRandom], client, SNDCHAN_VOICE);
		}
		else if ( StrEqual(sModel, NICK_MDL ) )
		{
			int iRandom = GetRandomInt(0, MAX_NICK_LAUGHS - 1);
			EmitSoundToAll(s_SoundsPathNickLaughs[iRandom], client, SNDCHAN_VOICE);
		}
		else if ( StrEqual(sModel, ELLIS_MDL ) )
		{
			int iRandom = GetRandomInt(0, MAX_ELLIS_LAUGHS - 1);
			EmitSoundToAll(s_SoundsPathEllisLaughs[iRandom], client, SNDCHAN_VOICE);
		}
		else if ( StrEqual(sModel, BILL_MDL ) )
		{
			int iRandom = GetRandomInt(0, MAX_BILL_LAUGHS - 1);
			EmitSoundToAll(s_SoundsPathBillLaughs[iRandom], client, SNDCHAN_VOICE);
		}
		else if ( StrEqual(sModel, FRANCIS_MDL ) )
		{
			int iRandom = GetRandomInt(0, MAX_FRANCIS_LAUGHS - 1);
			EmitSoundToAll(s_SoundsPathFrancisLaughs[iRandom], client, SNDCHAN_VOICE);
		}
		else if ( StrEqual(sModel, LOUIS_MDL ) )
		{
			int iRandom = GetRandomInt(0, MAX_LOUIS_LAUGHS - 1);
			EmitSoundToAll(s_SoundsPathLouisLaughs[iRandom], client, SNDCHAN_VOICE);
		}
		else if ( StrEqual(sModel, ZOEY_MDL ) )
		{
			int iRandom = GetRandomInt(0, MAX_ZOEY_LAUGHS - 1);
			EmitSoundToAll(s_SoundsPathZoeyLaughs[iRandom], client, SNDCHAN_VOICE);
		}
	}
}

public Action Timer_PlayerTaunt(Handle timer, any client)
{
	if(client && IsClientInGame(client))
	{
		char sModel[42];
		GetClientModel(client, sModel, sizeof(sModel));
		
		if ( StrEqual(sModel, COACH_MDL) )
		{
			int iRandom = GetRandomInt(0, MAX_TAUNTS_COACH - 1);
			EmitSoundToAll(s_SoundsPathCoach[iRandom], client, SNDCHAN_VOICE);
		}
		else if ( StrEqual(sModel, NICK_MDL ) )
		{
			int iRandom = GetRandomInt(0, MAX_TAUNTS_NICK - 1);
			EmitSoundToAll(s_SoundsPathNick[iRandom], client, SNDCHAN_VOICE);
		}
		else if ( StrEqual(sModel, ELLIS_MDL ) )
		{
			int iRandom = GetRandomInt(0, MAX_TAUNTS_ELLIS - 1);
			EmitSoundToAll(s_SoundsPathEllis[iRandom], client, SNDCHAN_VOICE);
		}
	}
}

public Action Timer_PlayerHurrah(Handle timer, any client)
{
	if(client && IsClientInGame(client))
	{
		char sModel[42];
		GetClientModel(client, sModel, sizeof(sModel));
		
		if ( StrEqual(sModel, COACH_MDL) )
		{
			int iRandom = GetRandomInt(0, MAX_COACH_HURRAH - 1);
			EmitSoundToAll(s_SoundsPathCoachHurrah[iRandom], client, SNDCHAN_VOICE);
		}
		else if ( StrEqual(sModel, NICK_MDL ) )
		{
			int iRandom = GetRandomInt(0, MAX_NICK_HURRAH - 1);
			EmitSoundToAll(s_SoundsPathNickHurrahs[iRandom], client, SNDCHAN_VOICE);
		}
	}
}

public Action Timer_PlayerThanks(Handle timer, any client)
{
	if(client && IsClientInGame(client))
	{
		char sModel[42];
		GetClientModel(client, sModel, sizeof(sModel));
		
		if ( StrEqual(sModel, COACH_MDL) )
		{
			int iRandom = GetRandomInt(0, MAX_COACH_THANKS - 1);
			EmitSoundToAll(s_SoundsPathCoachThanks[iRandom], client, SNDCHAN_VOICE);
		}
		else if ( StrEqual(sModel, NICK_MDL ) )
		{
			int iRandom = GetRandomInt(0, MAX_NICK_THANKS - 1);
			EmitSoundToAll(s_SoundsPathNickThanks[iRandom], client, SNDCHAN_VOICE);
		}
	}
}

public Action Timer_PlayerYes(Handle timer, any client)
{
	if(client && IsClientInGame(client))
	{
		char sModel[42];
		GetClientModel(client, sModel, sizeof(sModel));
		
		if ( StrEqual(sModel, COACH_MDL) )
		{
			int iRandom = GetRandomInt(0, MAX_COACH_YES - 1);
			EmitSoundToAll(s_SoundsPathYesCoach[iRandom], client, SNDCHAN_VOICE);
		}
	}
}