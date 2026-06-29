/*
Copyright (C) 2012 Kevin "Delachambre" Ferreira (kevin.dumont71@gmail.com)
Ce plugin est soumis aux conditions d'assiduité et au respect
de chaque utilisateurs l'utilisant.Toutes infractions a ce système se 
verra puni par l'auteur du plugin d'une durée permanente.
*/
static String:KVPath[PLATFORM_MAX_PATH];
#pragma semicolon 1

// INCLUDES
#include <sdktools>
#include <cstrike>
#include <smlib>
#include <sdkhooks>
#include <sourcemod>
#include <roleplay>

// DEFINES
#define PLUGIN_VERSION	"2.0.0"
#define AUTHOR "Ultimate Phoenix Qc" 
#define DESCRIPTION "Mod Roleplay pour CS:S"
#define NAME "Roleplay CITY"
#define SOUND_TAZER 	"ambient/machines/zap1.wav"
#define FORUM 	"\x04[rpqc.webs.com] \x01"
#define LOGO	"\x03[RP] \x01"
#define TEAM	"RP"
#define TAZER_COLORBLUE 	{75,75,255,255}
#define MAX_PLAYERS 64

// NEW BOOL
new bool:g_bIsMapLoaded = false;
new bool:g_booljail[MAXPLAYERS+1] = false;
new bool:g_boolreturn[MAXPLAYERS+1] = false;
new bool:g_IsTazed[MAXPLAYERS+1] = false;
new bool:drogue[MAXPLAYERS+1] = false;
new bool:g_boolexta[MAXPLAYERS+1] = false;
new bool:g_boollsd[MAXPLAYERS+1] = false;
new bool:g_boolcoke[MAXPLAYERS+1] = false;
new bool:g_boolhero[MAXPLAYERS+1] = false;
new bool:g_crochetageon[MAXPLAYERS+1] = false;
new bool:g_booldead[MAXPLAYERS+1] = false;
new bool:reboot = false;
new bool:g_chirurgie[MAXPLAYERS+1] = false;
new bool:grab[MAXPLAYERS+1] = false;
new bool:OnKit[MAXPLAYERS+1] = false;
new bool:g_InUse[MAXPLAYERS+1];
new bool:HasKillCible[MAXPLAYERS+1] = false;
new bool:oncontrat[MAXPLAYERS+1] = false;
new bool:g_appart[MAXPLAYERS+1] = false;

// NEW FLOAT 
new Float:g_Count[MAXPLAYERS+1] = 0.0;

// NEW STRING 
new String:g_gamedesc[64];
new String:RealZone[999];
new String:jobname[999];
new String:rankname[999];

// NEW HANDLE
new Handle:Timers;
new Handle:gTimer;
new Handle:GiveKit;
new Handle:g_jailreturn[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:g_jailtimer[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:TimerHud[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TimerAppart[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_TazerTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_croche[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:g_deadtimer[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:heroo[MAXPLAYERS+1];
new Handle:extasiie[MAXPLAYERS+1];
new Handle:lssd[MAXPLAYERS+1];
new Handle:cokk[MAXPLAYERS+1];
new Handle:countm4time;
new Handle:countdeagletime;
new Handle:countm3time;
new Handle:countusptime;
new Handle:Contrat[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:pub;

// NEW INDEX
new g_modelLaser, g_modelHalo, g_LightingSprite, g_BeamSprite;
new g_countheure1 = 0;
new g_countheure2 = 0;
new g_countminute1 = 0;
new g_countminute2 = 0;
new M4FBI;
new DEAGLEFBI;
new M3COMICO;
new USPCOMICO;
new countm4 = 0;
new countdeagle = 0;
new countm3 = 0;
new countusp = 0;
new redColor[4]		= {255, 75, 75, 255 };
new greenColor[4]	= {75, 255, 75, 255 };
new RebootTimer;



// NEW VARIABLES
new jobid[MAXPLAYERS+1] = 0;
new rankid[MAXPLAYERS+1] = 0;
new bank[MAXPLAYERS+1] = 0;
new kitcrochetage[MAXPLAYERS+1] = 0;
new capital[MAXPLAYERS+1] = 0;
new g_IsInJail[MAXPLAYERS+1] = 0;
new money[MAXPLAYERS+1] = 0;
new g_jailtime[MAXPLAYERS+1] = 0;
new salaire[MAXPLAYERS+1] = 0;
new rib[MAXPLAYERS+1] = 0;
new ak47[MAXPLAYERS+1] = 0;
new awp[MAXPLAYERS+1] = 0;
new m249[MAXPLAYERS+1] = 0;
new scout[MAXPLAYERS+1] = 0;
new sg550[MAXPLAYERS+1] = 0;
new sg552[MAXPLAYERS+1] = 0;
new ump[MAXPLAYERS+1] = 0;
new tmp[MAXPLAYERS+1] = 0;
new mp5[MAXPLAYERS+1] = 0;
new deagle[MAXPLAYERS+1] = 0;
new usp[MAXPLAYERS+1] = 0;
new glock[MAXPLAYERS+1] = 0;
new xm1014[MAXPLAYERS+1] = 0;
new m3[MAXPLAYERS+1] = 0;
new m4a1[MAXPLAYERS+1] = 0;
new aug[MAXPLAYERS+1] = 0;
new galil[MAXPLAYERS+1] = 0;
new mac10[MAXPLAYERS+1] = 0;
new famas[MAXPLAYERS+1] = 0;
new p90[MAXPLAYERS+1] = 0;
new elite[MAXPLAYERS+1] = 0;
new ticket10[MAXPLAYERS+1] = 0;
new ticket100[MAXPLAYERS+1] = 0;
new ticket1000[MAXPLAYERS+1] = 0;
new levelcut[MAXPLAYERS+1] = 0;
new cartouche[MAXPLAYERS+1] = 0;
new permislourd[MAXPLAYERS+1] = 0;
new permisleger[MAXPLAYERS+1] = 0;
new cb[MAXPLAYERS+1] = 0;
new props1[MAXPLAYERS+1] = 0;
new props2[MAXPLAYERS+1] = 0;
new heroine[MAXPLAYERS+1] = 0;
new exta[MAXPLAYERS+1] = 0;
new lsd[MAXPLAYERS+1] = 0;
new coke[MAXPLAYERS+1] = 0;
new pack[MAXPLAYERS+1] = 0;
new kevlar[MAXPLAYERS+1] = 0;
new g_succesheadshot[MAXPLAYERS+1] = 0;
new g_headshot[MAXPLAYERS+1] = 0;
new g_succesporte20[MAXPLAYERS+1] = 0;
new g_succesporte50[MAXPLAYERS+1] = 0;
new g_succesporte100[MAXPLAYERS+1] = 0;
new g_porte[MAXPLAYERS+1] = 0;
new price[MAXPLAYERS+1] = 0;
new responsable[MAXPLAYERS+1] = 0;
new jail[MAXPLAYERS+1] = 0;
new g_invisible[MAXPLAYERS+1] = 0;
new p[MAXPLAYERS+1] = 0;
new g_tazer[MAXPLAYERS+1] = 0;
new Entiter[MAXPLAYERS+1] = 0;
new g_crochetage[MAXPLAYERS+1] = 0;
new g_CountDead[MAXPLAYERS+1] = 0;
new l[MAXPLAYERS+1] = 0;
new z[MAXPLAYERS+1] = 0;
new banned[MAXPLAYERS+1] = 0;
new banni[MAXPLAYERS+1] = 0;
new TransactionWith[MAXPLAYERS+1] = 0;
new gObj[MAXPLAYERS+1] = 0;
new m[MAXPLAYERS+1] = 0;
new g_vol[MAXPLAYERS+1] = 0;
new cible[MAXPLAYERS+1] = 0;
new acheteur[MAXPLAYERS+1] = 0;
new salarychoose[MAXPLAYERS+1] = 0;
new maison[MAXPLAYERS+1] = 0;
new maisontime[MAXPLAYERS+1] = 0;

public Plugin:myinfo =
{
    name = NAME,
    description = DESCRIPTION,
    author = AUTHOR,
    version = PLUGIN_VERSION,
    url = FORUM
};

public OnPluginStart()
{
	CreateDirectory("addons/sourcemod/data/roleplay", 3);
	BuildPath(Path_SM, KVPath, sizeof(KVPath), "data/roleplay/player.txt");
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_team", OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath);
	
	PrecacheModel("models/player/leb/t_leet.mdl", true);
	PrecacheModel("models/player/notdelite/desert_sas/ct_sas.mdl", true);
	PrecacheModel("models/player/ics/ct_gign_fbi/ct_gign.mdl", true);
	PrecacheModel("models/player/natalya/police/chp_male_jacket.mdl", true);
	PrecacheModel("models/player/elis/po/police.mdl", true);
	PrecacheModel("models/player/slow/vin_diesel/slow.mdl", true);
	PrecacheModel("models/player/slow/niko_bellic/slow.mdl", true);
	PrecacheModel("models/player/slow/50cent/slow.mdl", true);

	// Commandes joueurs
	RegConsoleCmd("sm_ent", Command_Ent);
	RegConsoleCmd("sm_entity", Command_Entity);
	RegConsoleCmd("sm_lock", Cmd_Lock);
	RegConsoleCmd("sm_unlock", Cmd_Unlock);
	RegConsoleCmd("sm_civil", Command_Civil);
	RegConsoleCmd("sm_give", Command_Cash);
	RegConsoleCmd("sm_jail", Command_Jail);
	RegConsoleCmd("sm_jaillist", Command_Jaillist);
	RegConsoleCmd("sm_vis", Command_Vis);
	RegConsoleCmd("sm_jobmenu", Command_Jobmenu);
	RegConsoleCmd("sm_money", Command_Money);
	RegConsoleCmd("sm_infos", Command_Infos);
	RegConsoleCmd("sm_tazer", Command_tazer);
	RegConsoleCmd("sm_item", Command_Item);
	RegConsoleCmd("sm_demission", Command_Demission);
	RegConsoleCmd("sm_engager", Command_Engager);
	RegConsoleCmd("sm_recruter", Command_Engager);
	RegConsoleCmd("sm_recrute", Command_Engager);
	RegConsoleCmd("sm_enquete", Command_Enquete);
	RegConsoleCmd("sm_del", Command_Rw);
	RegConsoleCmd("sm_rp", Command_Roleplay);
	RegConsoleCmd("sm_perquisition", Command_Perqui);
	RegConsoleCmd("sm_perqui", Command_Perqui);
	RegConsoleCmd("sm_armurerie", Command_Armurie);
	RegConsoleCmd("sm_armu", Command_Armurie);
	RegConsoleCmd("sm_changename", Command_Changename);
	RegConsoleCmd("sm_out", Command_Out);
	RegConsoleCmd("sm_reboot", Command_ShutdownServer);
	RegConsoleCmd("sm_vendre", Command_Vente); 
	RegConsoleCmd("sm_+force", Command_Grab);
	RegConsoleCmd("sm_virer", Command_Virer);
	RegConsoleCmd("sm_licencier", Command_Virer);
	RegConsoleCmd("sm_exclure", Command_Virer);
	RegConsoleCmd("sm_vol", Command_Vol);
	RegConsoleCmd("sm_infoscut", Command_Infoscut);
	RegConsoleCmd("sm_contrat", Command_Contrat);
	RegConsoleCmd("sm_salaire", Command_Salaire);
	RegConsoleCmd("sm_pay", Command_Salaire);
	RegConsoleCmd("sm_paie", Command_Salaire);
	RegConsoleCmd("sm_time", Command_Time);
	RegConsoleCmd("sm_forum", Command_Forum);
	
	// Description Override
	Format(g_gamedesc, sizeof(g_gamedesc), "Roleplay QUEBEC");
	
	// Commandes Bloquées
	RegConsoleCmd("jointeam", Block_CMD);
	RegConsoleCmd("explode", Block_CMD);
	RegConsoleCmd("kill", Block_CMD);
	RegConsoleCmd("coverme", Block_CMD);
	RegConsoleCmd("takepoint", Block_CMD);
	RegConsoleCmd("holdpos", Block_CMD);
	RegConsoleCmd("regroup", Block_CMD);
	RegConsoleCmd("followme", Block_CMD);
	RegConsoleCmd("takingfire", Block_CMD);
	RegConsoleCmd("go", Block_CMD);
	RegConsoleCmd("fallback", Block_CMD);
	RegConsoleCmd("sticktog", Block_CMD);
	RegConsoleCmd("getinpos", Block_CMD);
	RegConsoleCmd("stormfront", Block_CMD);
	RegConsoleCmd("report", Block_CMD);
	RegConsoleCmd("roger", Block_CMD);
	RegConsoleCmd("enemyspot", Block_CMD);
	RegConsoleCmd("needbackup", Block_CMD);
	RegConsoleCmd("sectorclear", Block_CMD);
	RegConsoleCmd("inposition", Block_CMD);
	RegConsoleCmd("reportingin", Block_CMD);
	RegConsoleCmd("getout", Block_CMD);
	RegConsoleCmd("negative", Block_CMD);
	RegConsoleCmd("enemydown", Block_CMD);
	
	// Commandes restreintes
	AddCommandListener(OnSay, "say");
	AddCommandListener(OnSayTeam, "say_team");
	
	// Hook texte
	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
}

// LICENCE

public SaveInfosClient(client)
{
	new Handle:DBase = CreateKeyValues("PlayerInfos");
	FileToKeyValues(DBase, KVPath);
	new String:SID[32];
	GetClientAuthString(client, SID, sizeof(SID));
	if(KvJumpToKey(DBase, SID, true))
	{
	KvSetNum(DBase, "jobid", jobid[client]);
	KvSetNum(DBase, "cash", money[client]);
	KvSetNum(DBase, "bank", bank[client]);
	KvSetNum(DBase, "kit", kitcrochetage[client]);
	KvSetNum(DBase, "capital", capital[client]);
	KvSetNum(DBase, "jail", g_IsInJail[client]);
	KvSetNum(DBase, "jailtime", g_jailtime[client]);
	KvSetNum(DBase, "salaire", salaire[client]);
	KvSetNum(DBase, "rib", rib[client]);
	KvSetNum(DBase, "ak47", ak47[client]);
	KvSetNum(DBase, "awp", awp[client]);
	KvSetNum(DBase, "m249", m249[client]);
	KvSetNum(DBase, "scout", scout[client]);
	KvSetNum(DBase, "sg550", sg550[client]);
	KvSetNum(DBase, "sg552", sg552[client]);
	KvSetNum(DBase, "ump", ump[client]);
	KvSetNum(DBase, "tmp", tmp[client]);
	KvSetNum(DBase, "mp5", mp5[client]);
	KvSetNum(DBase, "deagle", deagle[client]);
	KvSetNum(DBase, "usp", usp[client]);
	KvSetNum(DBase, "glock", glock[client]);
	KvSetNum(DBase, "xm1014", xm1014[client]);
	KvSetNum(DBase, "m3", m3[client]);
	KvSetNum(DBase, "m4a1", m4a1[client]);
	KvSetNum(DBase, "aug", aug[client]);
	KvSetNum(DBase, "galil", galil[client]);
	KvSetNum(DBase, "mac10", mac10[client]);
	KvSetNum(DBase, "famas", famas[client]);
	KvSetNum(DBase, "p90", p90[client]);
	KvSetNum(DBase, "elite", elite[client]);
	KvSetNum(DBase, "ticket10", ticket10[client]);
	KvSetNum(DBase, "ticket100", ticket100[client]);
	KvSetNum(DBase, "ticket1000", ticket1000[client]);
	KvSetNum(DBase, "levelcut", levelcut[client]);
	KvSetNum(DBase, "cartouche", cartouche[client]);
	KvSetNum(DBase, "permislourd", permislourd[client]);
	KvSetNum(DBase, "permisleger", permisleger[client]);
	KvSetNum(DBase, "cb", cb[client]);
	KvSetNum(DBase, "prop1", props1[client]);
	KvSetNum(DBase, "prop2", props2[client]);
	KvSetNum(DBase, "heroine", heroine[client]);
	KvSetNum(DBase, "exta", exta[client]);
	KvSetNum(DBase, "lsd", lsd[client]);
	KvSetNum(DBase, "coke", coke[client]);
	KvSetNum(DBase, "pack", pack[client]);
	KvSetNum(DBase, "kevlar", kevlar[client]);
	KvSetNum(DBase, "maison", maison[client]);
	KvSetNum(DBase, "maisontime", maisontime[client]);
	KvRewind(DBase);
	KeyValuesToFile(DBase, KVPath);
	CloseHandle(DBase);
	}
}

public GetInfosClient(client)
{
	new Handle:DBase = CreateKeyValues("PlayerInfos");
	FileToKeyValues(DBase, KVPath);
	new String:SID[32];
	GetClientAuthString(client, SID, sizeof(SID));
	if(KvJumpToKey(DBase, SID, true))
	{
		new a1;
		new a2;
		new a3;
		new a4;
		new a5;
		new a6;
		new a7;
		new a8;
		new a9;
		new a10;
		new a11;
		new a12;
		new a13;
		new a14;
		new a15;
		new a16;
		new a17;
		new a18;
		new a19;
		new a20;
		new a21;
		new a22;
		new a23;
		new a24;
		new a25;
		new a26;
		new a27;
		new a28;
		new a29;
		new a30;
		new a31;
		new a32;
		new a33;
		new a34;
		new a35;
		new a36;
		new a37;
		new a38;
		new a39;
		new a40;
		new a41;
		new a42;
		new a43;
		new a44;
		new a45;
		new a46;
		new a47;
		new a48;
		a1 = KvGetNum(DBase, "jobid", 0);
		a2 = KvGetNum(DBase, "cash", 0);
		a3 = KvGetNum(DBase, "bank", 16000);
		a4 = KvGetNum(DBase, "kit", 0);
		a5 = KvGetNum(DBase, "capital", 0);
		a6 = KvGetNum(DBase, "jail", 0);
		a7 = KvGetNum(DBase, "jailtime", 0);
		a8 = KvGetNum(DBase, "salaire", 50);
		a9 = KvGetNum(DBase, "rib", 0);
		a10 = KvGetNum(DBase, "ak47", 0);
		a11 = KvGetNum(DBase, "awp", 0);
		a12 = KvGetNum(DBase, "m249", 0);
		a13 = KvGetNum(DBase, "scout", 0);
		a14 = KvGetNum(DBase, "sg550", 0);
		a15 = KvGetNum(DBase, "sg552", 0);
		a16 = KvGetNum(DBase, "ump", 0);
		a17 = KvGetNum(DBase, "tmp", 0);
		a18 = KvGetNum(DBase, "mp5", 0);
		a19 = KvGetNum(DBase, "deagle", 0);
		a20 = KvGetNum(DBase, "usp", 0);
		a21 = KvGetNum(DBase, "glock", 0);
		a22 = KvGetNum(DBase, "xm1014", 0);
		a23 = KvGetNum(DBase, "m3", 0);
		a24 = KvGetNum(DBase, "m4a1", 0);
		a25 = KvGetNum(DBase, "aug", 0);
		a26 = KvGetNum(DBase, "galil", 0);
		a27 = KvGetNum(DBase, "mac10", 0);
		a28 = KvGetNum(DBase, "famas", 0);
		a29 = KvGetNum(DBase, "p90", 0);
		a30 = KvGetNum(DBase, "elite", 0);
		a31 = KvGetNum(DBase, "ticket10", 0);
		a32 = KvGetNum(DBase, "ticket100", 0);
		a33 = KvGetNum(DBase, "ticket1000", 0);
		a34 = KvGetNum(DBase, "levelcut", 0);
		a35 = KvGetNum(DBase, "cartouche", 0);
		a36 = KvGetNum(DBase, "permislourd", 0);
		a37 = KvGetNum(DBase, "permisleger", 0);
		a38 = KvGetNum(DBase, "cb", 0);
		a39 = KvGetNum(DBase, "prop1", 0);
		a40 = KvGetNum(DBase, "prop2", 0);
		a41 = KvGetNum(DBase, "heroine", 0);
		a42 = KvGetNum(DBase, "exta", 0);
		a43 = KvGetNum(DBase, "lsd", 0);
		a44 = KvGetNum(DBase, "coke", 0);
		a45 = KvGetNum(DBase, "pack", 0);
		a46 = KvGetNum(DBase, "kevlar", 0);
		a47 = KvGetNum(DBase, "maison", 0);
		a48 = KvGetNum(DBase, "maisontime", 0);
		KvRewind(DBase);
		KeyValuesToFile(DBase, KVPath);
		CloseHandle(DBase);
		jobid[client] = a1;
		money[client] = a2;
		bank[client] = a3;
		kitcrochetage[client] = a4;
		capital[client] = a5;
		g_IsInJail[client] = a6 ;
		g_jailtime[client] = a7;
		salaire[client] = a8;
		rib[client] = a9;
		ak47[client] = a10;
		awp[client] = a11;
		m249[client] = a12;
		scout[client] = a13;
		sg550[client] = a14;
		sg552[client] = a15;
		ump[client] = a16;
		tmp[client] = a17;
		mp5[client] = a18;
		deagle[client] = a19;
		usp[client] = a20;
		glock[client] = a21;
		xm1014[client] = a22;
		m3[client] = a23;
		m4a1[client] = a24;
		aug[client] = a25;
		galil[client] = a26;
		mac10[client] = a27;
		famas[client] = a28;
		p90[client] = a29;
		elite[client] = a30;
		ticket10[client] = a31;
		ticket100[client] = a32;
		ticket1000[client] = a33;
		levelcut[client] = a34;
		cartouche[client] = a35;
		permislourd[client] = a36;
		permisleger[client] = a37;
		cb[client] = a38;
		props1[client] = a39;
		props2[client] = a40;
		heroine[client] = a41;
		exta[client] = a42;
		lsd[client] = a43;
		coke[client] = a44;
		pack[client] = a45;
		kevlar[client] = a46;
		maison[client] = a47;
		maisontime[client] = a48; 
	}
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	if (g_bIsMapLoaded)
	{
		strcopy(gameDesc, sizeof(gameDesc), g_gamedesc);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public OnMapStart()
{
	
	// Force Argent de départ a 0
	new Handle:mp_startmoney = INVALID_HANDLE;
	mp_startmoney = FindConVar("mp_startmoney");

	if(mp_startmoney != INVALID_HANDLE)
	{
		SetConVarBounds(mp_startmoney, ConVarBound_Lower, false);
	}
	
	// DL & PRECACHE des sons
	AddFileToDownloadsTable("sound/roleplay_sm/noteam.wav");
	AddFileToDownloadsTable("sound/roleplay_sm/salaire.wav");
	AddFileToDownloadsTable("sound/roleplay_sm/success.wav");
	AddFileToDownloadsTable("sound/roleplay_sm/telephone.mp3");
	
	PrecacheSound("doors/latchunlocked1.wav", true);
	PrecacheSound("doors/default_locked.wav", true);
	PrecacheSound("roleplay_sm/noteam.wav", true);
	PrecacheSound("roleplay_sm/salaire.wav", true);
	PrecacheSound("roleplay_sm/success.wav", true);
	PrecacheSound("roleplay_sm/telephone.mp3", true);
	PrecacheSound(SOUND_TAZER, true);
	
	// PRECACHE MODELS
	PrecacheModel("models/player/leb/t_leet.mdl", true);
	PrecacheModel("models/player/notdelite/desert_sas/ct_sas.mdl", true);
	PrecacheModel("models/player/ics/ct_gign_fbi/ct_gign.mdl", true);
	PrecacheModel("models/player/natalya/police/chp_male_jacket.mdl", true);
	PrecacheModel("models/player/elis/po/police.mdl", true);
	PrecacheModel("models/player/slow/vin_diesel/slow.mdl", true);
	PrecacheModel("models/player/slow/niko_bellic/slow.mdl", true);
	PrecacheModel("models/player/slow/50cent/slow.mdl", true);
	PrecacheModel("models/player/slow/jamis/kingpin/slow_v2.mdl", true);
	g_modelLaser = PrecacheModel("sprites/laser.vmt");
	g_modelHalo = PrecacheModel("materials/sprites/halo01.vmt");
	g_LightingSprite = PrecacheModel("sprites/lgtning.vmt");
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	
	// HORLOGE
	startheure();
	
	// KILL LOGIC
	KillLogic();
	
	// CONFIRMATION
	PrintToServer("[RP] : Le plugin Roleplay a bien démarré.");
	
	g_bIsMapLoaded = true;
	
	gTimer = CreateTimer(0.1, UpdateObjects, INVALID_HANDLE, TIMER_REPEAT);
	
	new i;
	for (i=0; i<MAX_PLAYERS; i++)
	{
		gObj[i]=-1;
	}
	
	pub = CreateTimer(90.0, Timer_Pub, _, TIMER_REPEAT);
	
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[],  err_max)
{
	PrintToServer("[RP] Chargement des natives...");
	CreateNative("GetClientBank", NativeGetClientBank);
	CreateNative("SetClientBank", NativeSetClientBank);
	CreateNative("SetClientMoney", NativeSetClientMoney);
	PrintToServer("[RP] Natives chargées.");
	return APLRes_Success;
}

public OnMapEnd()
{
	CloseHandle(gTimer);
	KillTimer(Timers);
	KillTimer(pub);
	
	
	g_bIsMapLoaded = false;
}


public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Lock doors
	LockingDoor();
	PrintToChatAll("%s : Les Portes du serveurs ont été fermées a clef.", LOGO);
	
	// KILL LOGIC AUTO OVISCITY R 03
	KillLogic();
	
	// LUMIERE
	SetLightStyle(0, "b");
	
	// Creation des armes
	//M4FBI = Weapon_Create("weapon_m4a1", NULL_VECTOR, NULL_VECTOR);

	
	new entlight1 = CreateEntityByName("light_dynamic");  
	
	if (entlight1 != -1)    
	{     
		DispatchKeyValue(entlight1, "_light", "250 250 200");  
		DispatchKeyValue(entlight1, "brightness", "8");  
		DispatchKeyValueFloat(entlight1, "spotlight_radius", 40.0);  
		DispatchKeyValueFloat(entlight1, "distance", 1000.0);  
		DispatchKeyValue(entlight1, "style", "0");   

		DispatchSpawn(entlight1);  
		new Float:origin[3] = {-4229.787598, 468.945862, 51.416504}; 
		TeleportEntity(entlight1, origin, NULL_VECTOR, NULL_VECTOR); 
    }
	
	new entlight2 = CreateEntityByName("light_dynamic");  
	
	if (entlight2 != -1)    
	{     
		DispatchKeyValue(entlight2, "_light", "250 250 200");  
		DispatchKeyValue(entlight2, "brightness", "8");  
		DispatchKeyValueFloat(entlight2, "spotlight_radius", 40.0);  
		DispatchKeyValueFloat(entlight2, "distance", 1000.0);  
		DispatchKeyValue(entlight2, "style", "0");   

		DispatchSpawn(entlight2);  
		new Float:origin[3] = {-4144.549805, 1909.200195, 51.640842}; 
		TeleportEntity(entlight2, origin, NULL_VECTOR, NULL_VECTOR); 
    }
	
	new entlight3 = CreateEntityByName("light_dynamic");  
	
	if (entlight3 != -1)    
	{     
		DispatchKeyValue(entlight3, "_light", "250 250 200");  
		DispatchKeyValue(entlight3, "brightness", "8");  
		DispatchKeyValueFloat(entlight3, "spotlight_radius", 40.0);  
		DispatchKeyValueFloat(entlight3, "distance", 1000.0);  
		DispatchKeyValue(entlight3, "style", "0");   

		DispatchSpawn(entlight3);  
		new Float:origin[3] = {-2269.420410, -1821.203003, 52.496376}; 
		TeleportEntity(entlight3, origin, NULL_VECTOR, NULL_VECTOR); 
    }
	
	new entlight4 = CreateEntityByName("light_dynamic");  
	
	if (entlight4 != -1)    
	{     
		DispatchKeyValue(entlight4, "_light", "250 250 200");  
		DispatchKeyValue(entlight4, "brightness", "8");  
		DispatchKeyValueFloat(entlight4, "spotlight_radius", 40.0);  
		DispatchKeyValueFloat(entlight4, "distance", 1000.0);  
		DispatchKeyValue(entlight4, "style", "0");   

		DispatchSpawn(entlight4);  
		new Float:origin[3] = {-1863.861328, 453.116211, 52.351307}; 
		TeleportEntity(entlight4, origin, NULL_VECTOR, NULL_VECTOR); 
    }
	
	new entlight5 = CreateEntityByName("light_dynamic");  
	
	if (entlight5 != -1)    
	{     
		DispatchKeyValue(entlight5, "_light", "250 250 200");  
		DispatchKeyValue(entlight5, "brightness", "8");  
		DispatchKeyValueFloat(entlight5, "spotlight_radius", 40.0);  
		DispatchKeyValueFloat(entlight5, "distance", 1000.0);  
		DispatchKeyValue(entlight5, "style", "0");   

		DispatchSpawn(entlight5);  
		new Float:origin[3] = {-44.804050, 1086.238159, -240.781601}; 
		TeleportEntity(entlight5, origin, NULL_VECTOR, NULL_VECTOR); 
    }
	
	new entlight6 = CreateEntityByName("light_dynamic");  
	
	if (entlight6 != -1)    
	{     
		DispatchKeyValue(entlight6, "_light", "250 250 200");  
		DispatchKeyValue(entlight6, "brightness", "8");  
		DispatchKeyValueFloat(entlight6, "spotlight_radius", 40.0);  
		DispatchKeyValueFloat(entlight6, "distance", 1000.0);  
		DispatchKeyValue(entlight6, "style", "0");   

		DispatchSpawn(entlight6);  
		new Float:origin[3] = {743.595947, 707.039429, -229.413116}; 
		TeleportEntity(entlight6, origin, NULL_VECTOR, NULL_VECTOR); 
    }
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:headshot = GetEventBool(event, "headshot");
	
	if (killer > 0)
	{
		if (IsClientInGame(killer))
		{
			if (killer != client)
			{
				if ((GetClientTeam(killer) == 2) && (GetClientTeam(client) == 3))
				{
					money[killer] = GetEntData(killer, MoneyOffset, 4);
					money[killer] -= 300;
					SetEntData(killer, MoneyOffset, money[killer], 4, true);
					Client_SetScore(killer, 0);
					Client_SetDeaths(client, 0);
				}
				else if ((GetClientTeam(killer) == 3) && (GetClientTeam(client) == 2))
				{
					money[killer] = GetEntData(killer, MoneyOffset, 4);
					money[killer] -= 300;
					SetEntData(killer, MoneyOffset, money[killer], 4, true);
					Client_SetScore(killer, 0);
					Client_SetDeaths(client, 0);
				}
				else if ((GetClientTeam(killer) == 2) && (GetClientTeam(client) == 2))
				{
					money[killer] = GetEntData(killer, MoneyOffset, 4);
					money[killer] += 3300;
					SetEntData(killer, MoneyOffset, money[killer], 4, true);
					Client_SetScore(killer, 0);
					Client_SetDeaths(client, 0);
				}
				else if ((GetClientTeam(killer) == 3) && (GetClientTeam(client) == 3))
				{
					money[killer] = GetEntData(killer, MoneyOffset, 4);
					money[killer] += 3300;
					SetEntData(killer, MoneyOffset, money[killer], 4, true);
					Client_SetScore(killer, 0);
					Client_SetDeaths(client, 0);
				}
				DestroyLevel(killer);
				
				if (oncontrat[killer])
				{
					HasKillCible[killer] = true;
				}
			}
			
			if (headshot == true) 
			{ 
				g_headshot[killer]++; 
					
				if (g_headshot[killer] == 30)
				{
					PrintToChatAll("%s : Le joueur %N a remporté le succès \x03Headshot attitude \x01.", LOGO, killer);
					EmitSoundToClient(killer, "roleplay_sm/success.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
					g_succesheadshot[killer] = 1;
				}
			} 
		}
	}
	
	gObj[client] = -1;
	
	if (g_IsTazed[client] == true)
	{
		g_IsTazed[client] = false;
		KillTazer(client);
	}
	
	if (money[client] < 0)
	{
		money[client] = 0;
	}
	
	if (bank[client] < 0)
	{
		bank[client] = 0;
	}
	
	if (!IsPlayerAlive(client))
	{
		g_CountDead[client] = 12;
		g_deadtimer[client] = CreateTimer(1.0, Timer_Dead, client, TIMER_REPEAT);
	}
	
	if (g_boolexta[client])
	{
		g_boolexta[client] = false;
	}
	
	if (g_boollsd[client])
	{
		g_boollsd[client] = false;
	}
	
	if (g_boolcoke[client])
	{
		g_boolcoke[client] = false;
	}
	
	if (g_boolhero[client])
	{
		g_boolhero[client] = false;
	}
	
	if (g_chirurgie[client])
	{
		g_chirurgie[client] = false;
	}
}

public Action:Timer_Dead(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (!IsPlayerAlive(client))
		{
			g_CountDead[client] -= 1;
			PrintCenterText(client, "Respawn dans : %i secondes", g_CountDead[client]);
			g_booldead[client] = true;
			
			if (g_CountDead[client] == 0)
			{
				CS_RespawnPlayer(client);
				disarm(client);
				GivePlayerItem(client, "weapon_knife");
				PrintToChat(client, "%s : Vous avez été respawn.", LOGO);
				ClientCommand(client, "r_screenoverlay 0");
				
				if (jobid[client] == 1)
				{
					CS_SwitchTeam(client, 3);
					SetEntityHealth(client, 500);
					CS_SetClientClanTag(client, "C. Police -");
				}
				else if (jobid[client] == 0)
				{
					CS_SwitchTeam(client, 2);
					SetEntityHealth(client, 100);
					CS_SetClientClanTag(client, "Sans emploi -");
				} 
				else if (jobid[client] == 2)
				{
					CS_SwitchTeam(client, 3);
					CS_SetClientClanTag(client, "Agent CIA -");
					SetEntityHealth(client, 400);
				} 
				else if (jobid[client] == 3)
				{
					CS_SwitchTeam(client, 3);
					CS_SetClientClanTag(client, "Agent du FBI -");
					SetEntityHealth(client, 300);
				} 
				else if (jobid[client] == 4)
				{
					CS_SwitchTeam(client, 3);
					CS_SetClientClanTag(client, "Policier -");
					SetEntityHealth(client, 200);
				} 
				else if (jobid[client] == 5)
				{
					CS_SwitchTeam(client, 3);
					CS_SetClientClanTag(client, "Gardien -");
					SetEntityHealth(client, 150);
				} 
				else if (jobid[client] == 6)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "C. Mafia -");
				} 
				else if (jobid[client] == 7)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "Mafieux -");
				} 
				else if (jobid[client] == 8)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "A. Mafieux -");
				} 
				else if (jobid[client] == 9)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "C. Dealer -");
				} 
				else if (jobid[client] == 10)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "Dealer -");
				} 
				else if (jobid[client] == 11)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "A. Dealer -");
				} 
				else if (jobid[client] == 12)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "C. Coach -");
				} 
				else if (jobid[client] == 13)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "Coach -");
				} 
				else if (jobid[client] == 14)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "A. Coach -");
				} 
				else if (jobid[client] == 15)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "C. Ebay -");
				} 
				else if (jobid[client] == 16)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "V. Ebay -");
				} 
				else if (jobid[client] == 17)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "A.V. Ebay -");
				} 
				else if (jobid[client] == 18)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "C. Armurie -");
				} 
				else if (jobid[client] == 19)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "Armurier -");
				} 
				else if (jobid[client] == 20)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "A. Armurier -");
				} 
				else if (jobid[client] == 21)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "C. Loto -");
				} 
				else if (jobid[client] == 22)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "V. de Ticket -");
				} 
				else if (jobid[client] == 23)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "A.V. de Ticket -");
				} 
				else if (jobid[client] == 24)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "C. Banquier -");
				} 
				else if (jobid[client] == 25)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "Banquier -");
				} 
				else if (jobid[client] == 26)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "A. Banquier -");
				} 
				else if (jobid[client] == 27)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "C. Hôpital -");
				} 
				else if (jobid[client] == 28)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "Médecin -");
				} 
				else if (jobid[client] == 29)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "Infirmier -");
				} 
				else if (jobid[client] == 30)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "Chirurgien -");
				} 
				else if (jobid[client] == 31)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "C. Artificier -");
				} 
				else if (jobid[client] == 32)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "Artificier -");
				} 
				else if (jobid[client] == 33)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "A. Artificier -");
				} 
				else if (jobid[client] == 34)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "C. Tueur -");
				} 
				else if (jobid[client] == 35)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "Tueur d'élite -");
				} 
				else if (jobid[client] == 36)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "Tueur novice -");
				} 
				else if (jobid[client] == 37)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "C. Hôtel -");
				} 
				else if (jobid[client] == 38)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "Hôtelier -");
				} 
				else if (jobid[client] == 39)
				{
					CS_SwitchTeam(client, 2);
					CS_SetClientClanTag(client, "A. Hôtelier -");
				} 
				
				chooseskin(client);
				
				if (g_jailtime[client] > 0)
				{
					switch (GetRandomInt(1, 4))
					{
						case 1:
						{
							TeleportEntity(client, Float:{ -984701973, -1001996089, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
						}
								
						case 2:
						{
							TeleportEntity(client, Float:{ -985977571, -1013839247, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
						}
								
						case 3:
						{
							TeleportEntity(client, Float:{ -985179530, -1014029130, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
						}
				
						case 4:
						{
							TeleportEntity(client, Float:{ -984701973, -1001996089, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
						}
					}
					SetClientListeningFlags(client, VOICE_MUTED);
				}
				else
				{
					switch (GetRandomInt(1, 5))
					{
						case 1:
						{
							TeleportEntity(client, Float:{ -5171.555664, 622.322266, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
						}
						
						case 2:
						{
							TeleportEntity(client, Float:{ -2980.488770, 895.414673, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
						}
						
						case 3:
						{
							TeleportEntity(client, Float:{ -4419.909668, -12.021674, -447.906189 }, NULL_VECTOR, NULL_VECTOR);
						}
						
						case 4:
						{
							TeleportEntity(client, Float:{ -3572.241455, -1830.482544, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
						}
						
						case 5:
						{
							TeleportEntity(client, Float:{ -1708.746582, -1202.248779, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
						}
					}
				}
				KillTimer(g_deadtimer[client]);
				g_booldead[client] = false;
			}
		}
	}
}

public Action:OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    return Plugin_Handled;
}

public Action:OnPlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    return Plugin_Handled;
}

public Action:OnClientPreAdminCheck(client)
{
	CreateTimer(1.0, Timer_Choose, client);
	CreateTimer(5.0, Timer_Tag, client);
	TimerHud[client] = CreateTimer(0.7, HudTimer, client, TIMER_REPEAT);
	
	if (maisontime[client] > 0)
	{
		TimerAppart[client] = CreateTimer(1.0, Timer_Appart, client, TIMER_REPEAT);
		g_appart[client] = true;
	}
	
	gObj[client] = -1;
	
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
	
	responsable[client] = 0;
	price[client] = 0;
	jail[client] = 0;
	TransactionWith[client] = 0;
	cible[client] = 0;
	acheteur[client] = 0;
	oncontrat[client] = false;
	OnKit[client] = false;
}

public OnClientSettingsChanged(client)
{
    change_tag(client);
}

public OnClientPutInServer(client)
{
	if(client && !IsFakeClient(client)) 
	{
	GetInfosClient(client);
	if(g_jailtime[client] > 1)
	{
	TeleportEntity(client, Float:{ -984701973, -1001996089, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
	}
		g_boolexta[client] = false;
		g_boolhero[client] = false;
		g_boollsd[client] = false;
		g_boolcoke[client] = false;
		g_chirurgie[client] = false;
	}
}

public startheure()
{
	Timers = CreateTimer(1.0, Timer_Horloge, _, TIMER_REPEAT);
}

public Action:Timer_Horloge(Handle:timer, any:client)
{
	g_countminute2 += 1;
	
	if (g_countminute2 >= 10)
	{
		g_countminute2 = 0;
		g_countminute1 = g_countminute1 + 1;
		
		if ((g_countminute1 >= 6) && (g_countminute2 >= 0))
		{
			g_countminute1 = 0;
			g_countheure2 = g_countheure2 + 1;
			
			if (g_countheure2 >= 10)
			{
				g_countheure2 = 0;
				g_countheure1 = g_countheure1 + 1;
			}
		}
	}
	if ((g_countheure1 >= 2) && (g_countheure2 >= 4))
	{
		g_countheure1 = 0;
		g_countheure2 = 0;

		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1)
			{
				GiveSalaire(i);
				capital[rankid[i]] = capital[rankid[i]]  -  salaire[i];
				EmitSoundToClient(i, "roleplay_sm/salaire.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				
			}
		}
	}
	if (g_countheure1 == 0 && g_countheure2 == 8 && g_countminute1 == 0 && g_countminute2 == 0)
	{
		SetLightStyle(0, "l");
		PrintToChatAll("%s : Le jour viens de se lever.", LOGO);
		
		new maxent = GetMaxEntities(), String:szClass[65];
	
		for (new i = MaxClients; i <= maxent; i++)
		{
			if(IsValidEdict(i) && IsValidEntity(i))
			{
				GetEdictClassname(i, szClass, sizeof(szClass));
				if(StrEqual("light_dynamic", szClass))
				{
					RemoveEdict(i);
				}
			}
		}
	}
	if (g_countheure1 == 1 && g_countheure2 == 9 && g_countminute1 == 0 && g_countminute2 == 0)
	{
		SetLightStyle(0, "b");
		PrintToChatAll("%s : La nuit viens de tomber.", LOGO);
		
		new entlight1 = CreateEntityByName("light_dynamic");  
	
		if (entlight1 != -1)    
		{     
			DispatchKeyValue(entlight1, "_light", "250 250 200");  
			DispatchKeyValue(entlight1, "brightness", "8");  
			DispatchKeyValueFloat(entlight1, "spotlight_radius", 40.0);  
			DispatchKeyValueFloat(entlight1, "distance", 1000.0);  
			DispatchKeyValue(entlight1, "style", "0");   

			DispatchSpawn(entlight1);  
			new Float:origin[3] = {-4229.787598, 468.945862, 51.416504}; 
			TeleportEntity(entlight1, origin, NULL_VECTOR, NULL_VECTOR); 
		}
		
		new entlight2 = CreateEntityByName("light_dynamic");  
		
		if (entlight2 != -1)    
		{     
			DispatchKeyValue(entlight2, "_light", "250 250 200");  
			DispatchKeyValue(entlight2, "brightness", "8");  
			DispatchKeyValueFloat(entlight2, "spotlight_radius", 40.0);  
			DispatchKeyValueFloat(entlight2, "distance", 1000.0);  
			DispatchKeyValue(entlight2, "style", "0");   

			DispatchSpawn(entlight2);  
			new Float:origin[3] = {-4144.549805, 1909.200195, 51.640842}; 
			TeleportEntity(entlight2, origin, NULL_VECTOR, NULL_VECTOR); 
		}
		
		new entlight3 = CreateEntityByName("light_dynamic");  
		
		if (entlight3 != -1)    
		{     
			DispatchKeyValue(entlight3, "_light", "250 250 200");  
			DispatchKeyValue(entlight3, "brightness", "8");  
			DispatchKeyValueFloat(entlight3, "spotlight_radius", 40.0);  
			DispatchKeyValueFloat(entlight3, "distance", 1000.0);  
			DispatchKeyValue(entlight3, "style", "0");   

			DispatchSpawn(entlight3);  
			new Float:origin[3] = {-2269.420410, -1821.203003, 52.496376}; 
			TeleportEntity(entlight3, origin, NULL_VECTOR, NULL_VECTOR); 
		}
		
		new entlight4 = CreateEntityByName("light_dynamic");  
		
		if (entlight4 != -1)    
		{     
			DispatchKeyValue(entlight4, "_light", "250 250 200");  
			DispatchKeyValue(entlight4, "brightness", "8");  
			DispatchKeyValueFloat(entlight4, "spotlight_radius", 40.0);  
			DispatchKeyValueFloat(entlight4, "distance", 1000.0);  
			DispatchKeyValue(entlight4, "style", "0");   

			DispatchSpawn(entlight4);  
			new Float:origin[3] = {-1863.861328, 453.116211, 52.351307}; 
			TeleportEntity(entlight4, origin, NULL_VECTOR, NULL_VECTOR); 
		}
		
		new entlight5 = CreateEntityByName("light_dynamic");  
	
		if (entlight5 != -1)    
		{     
			DispatchKeyValue(entlight5, "_light", "250 250 200");  
			DispatchKeyValue(entlight5, "brightness", "8");  
			DispatchKeyValueFloat(entlight5, "spotlight_radius", 40.0);  
			DispatchKeyValueFloat(entlight5, "distance", 1000.0);  
			DispatchKeyValue(entlight5, "style", "0");   

			DispatchSpawn(entlight5);  
			new Float:origin[3] = {-44.804050, 1086.238159, -240.781601}; 
			TeleportEntity(entlight5, origin, NULL_VECTOR, NULL_VECTOR); 
		}
		
		new entlight6 = CreateEntityByName("light_dynamic");  
		
		if (entlight6 != -1)    
		{     
			DispatchKeyValue(entlight6, "_light", "250 250 200");  
			DispatchKeyValue(entlight6, "brightness", "8");  
			DispatchKeyValueFloat(entlight6, "spotlight_radius", 40.0);  
			DispatchKeyValueFloat(entlight6, "distance", 1000.0);  
			DispatchKeyValue(entlight6, "style", "0");   

			DispatchSpawn(entlight6);  
			new Float:origin[3] = {743.595947, 707.039429, -229.413116}; 
			TeleportEntity(entlight6, origin, NULL_VECTOR, NULL_VECTOR); 
		}
	}
}

public GiveSalaire(client)
{
	if (IsPlayerAlive(client))
	{
		if (g_IsInJail[client] == 0)
		{
			AddCash(client, salaire[client]);
		}
		else
		{
			PrintToChat(client, "%s : Vous êtes en jail, vous n'avez pas votre salaire.", LOGO);
		}
	}
	else
	{
		PrintToChat(client, "%s : Vous devez être vivant pour avoir votre salaire.", LOGO);
	}
}

AddCash(client, montant)
{
	new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	new current = money[client] + montant;
	
	PrintToChat(client, "%s : Vous avez reçu votre paie de %d$", LOGO, montant);

	SetEntData(client, MoneyOffset, current, 4, true);
}

AdCash(client, montant)
{
	new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	new current = money[client] + montant;

	SetEntData(client, MoneyOffset, current, 4, true);
}

public Action:Block_CMD(client, Args)
{
    return Plugin_Handled;
}

stock LockingDoor()
{
	LockingEntity("func_door_rotating");
	LockingEntity("prop_door_rotating");
	LockingEntity("func_door");
}

stock LockingEntity(const String:ClassName[])
{
    new entity = -1;
    while ((entity = FindEntityByClassname(entity, ClassName)) != INVALID_ENT_REFERENCE)
    {
        if(IsValidEdict(entity) && IsValidEntity(entity))
        {
            SetEntProp(entity, Prop_Data, "m_bLocked", 1, 1);
        }
    }
}

public Action:OnSay(client, const String:command[], args)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			if (!IsFakeClient(client))
			{
				if (!IsPlayerAlive(client))
				{
					PrintToChat(client, "%s : Vous devez être en vie pour parler.", LOGO);
					return Plugin_Handled;
				}
				
				if (g_IsInJail[client] > 0)
				{
					PrintToChat(client, "%s : Vous ne pouvez pas parlé en jail.", LOGO);
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnSayTeam(client, const String:command[], args)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client))
		{
			if (IsPlayerAlive(client))
			{
				decl String:text[128];

				GetCmdArg(1, text, sizeof(text));
				
				PrintToChatAll("%s : (LOCAL) %N : %s", LOGO, client, text);
			
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Tag(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		change_tag(client);
	}
}

// Change tag

public change_tag(client)
{
	if (IsClientInGame(client))
	{
		if (jobid[client] == 1)
		{
			CS_SetClientClanTag(client, "C. Police -");
		}
		else if (jobid[client] == 0)
		{
			CS_SetClientClanTag(client, "Sans emploi -");
		} 
		else if (jobid[client] == 2)
		{
			CS_SetClientClanTag(client, "Agent CIA -");
		} 
		else if (jobid[client] == 3)
		{
			CS_SetClientClanTag(client, "Agent du FBI -");
		} 
		else if (jobid[client] == 4)
		{
			CS_SetClientClanTag(client, "Policier -");
		} 
		else if (jobid[client] == 5)
		{
			CS_SetClientClanTag(client, "Gardien -");
		}
		else if (jobid[client] == 6)
		{
			CS_SetClientClanTag(client, "C. Mafia -");
		}
		else if (jobid[client] == 7)
		{
			CS_SetClientClanTag(client, "Mafieux -");
		}
		else if (jobid[client] == 8)
		{
			CS_SetClientClanTag(client, "A. Mafieux -");
		}
		else if (jobid[client] == 9)
		{
			CS_SetClientClanTag(client, "C. Dealer -");
		}
		else if (jobid[client] == 10)
		{
			CS_SetClientClanTag(client, "Dealer -");
		}
		else if (jobid[client] == 11)
		{
			CS_SetClientClanTag(client, "A. Dealer -");
		}
		else if (jobid[client] == 12)
		{
			CS_SetClientClanTag(client, "C. Coach -");
		}
		else if (jobid[client] == 13)
		{
			CS_SetClientClanTag(client, "Coach -");
		}
		else if (jobid[client] == 14)
		{
			CS_SetClientClanTag(client, "A. Coach -");
		}
		else if (jobid[client] == 15)
		{
			CS_SetClientClanTag(client, "C. Ebay -");
		}
		else if (jobid[client] == 16)
		{
			CS_SetClientClanTag(client, "V. Ebay -");
		}
		else if (jobid[client] == 17)
		{
			CS_SetClientClanTag(client, "A.V. Ebay -");
		}
		else if (jobid[client] == 18)
		{
			CS_SetClientClanTag(client, "C. Armurie -");
		}
		else if (jobid[client] == 19)
		{
			CS_SetClientClanTag(client, "Armurier -");
		}
		else if (jobid[client] == 20)
		{
			CS_SetClientClanTag(client, "A. Armurier -");
		}
		else if (jobid[client] == 21)
		{
			CS_SetClientClanTag(client, "C. Loto -");
		}
		else if (jobid[client] == 22)
		{
			CS_SetClientClanTag(client, "V. de Ticket -");
		}
		else if (jobid[client] == 23)
		{
			CS_SetClientClanTag(client, "A.V. de Ticket -");
		}
		else if (jobid[client] == 24)
		{
			CS_SetClientClanTag(client, "C. Banquier -");
		}
		else if (jobid[client] == 25)
		{
			CS_SetClientClanTag(client, "Banquier -");
		}
		else if (jobid[client] == 26)
		{
			CS_SetClientClanTag(client, "A. Banquier -");
		}
		else if (jobid[client] == 27)
		{
			CS_SetClientClanTag(client, "C. Hôpital -");
		}
		else if (jobid[client] == 28)
		{
			CS_SetClientClanTag(client, "Médecin -");
		}
		else if (jobid[client] == 29)
		{
			CS_SetClientClanTag(client, "Infirmier -");
		}
		else if (jobid[client] == 30)
		{
			CS_SetClientClanTag(client, "Chirurgien -");
		}
		else if (jobid[client] == 31)
		{
			CS_SetClientClanTag(client, "C. Artificier -");
		}
		else if (jobid[client] == 32)
		{
			CS_SetClientClanTag(client, "Artificier -");
		}
		else if (jobid[client] == 33)
		{
			CS_SetClientClanTag(client, "A. Artificier -");
		}
		else if (jobid[client] == 34)
		{
			CS_SetClientClanTag(client, "C. Tueur -");
		}
		else if (jobid[client] == 35)
		{
			CS_SetClientClanTag(client, "Tueur d'élite -");
		}
		else if (jobid[client] == 36)
		{
			CS_SetClientClanTag(client, "Tueur novice -");
		}
		else if (jobid[client] == 37)
		{
			CS_SetClientClanTag(client, "C. Hôtelier -");
		}
		else if (jobid[client] == 38)
		{
			CS_SetClientClanTag(client, "Hôtelier -");
		}
		else if (jobid[client] == 39)
		{
			CS_SetClientClanTag(client, "A. Hôtelier -");
		}
	}
}

// Change skin

public chooseskin(client)
{
	if (jobid[client] > 5 || jobid[client] == 0)
	{
		switch (GetRandomInt(1, 3))
		{
			case 1:
			{
				SetEntityModel(client, "models/player/slow/vin_diesel/slow.mdl");
			}
			
			case 2:
			{
				SetEntityModel(client, "models/player/slow/niko_bellic/slow.mdl");
			}
			
			case 3:
			{
				SetEntityModel(client, "models/player/slow/50cent/slow.mdl");
			}
		}
	}
	else if (jobid[client] == 1)
	{
		SetEntityModel(client, "models/player/leb/t_leet.mdl");
	}
	else if (jobid[client] == 2)
	{
		SetEntityModel(client, "models/player/notdelite/desert_sas/ct_sas.mdl");
	}
	else if (jobid[client] == 3)
	{
		SetEntityModel(client, "models/player/ics/ct_gign_fbi/ct_gign.mdl");
	}
	else if (jobid[client] == 4)
	{
		SetEntityModel(client, "models/player/natalya/police/chp_male_jacket.mdl");
	}
	else if (jobid[client] == 5)
	{
		SetEntityModel(client, "models/player/elis/po/police.mdl");
	}
}

public Action:Timer_Choose(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{

		
		// Récupération du capital par la même occasion au lieu de crée un second timer.
		
		
		ClientCommand(client, "r_screenoverlay 0");
		
		new Handle:menu = CreateMenu(Connect_Menu);
		SetMenuTitle(menu, "Bienvenue sur le Roleplay Magnetik");
		
		if (jobid[client] == 1)
		{
			CS_SwitchTeam(client, 3);
			CS_RespawnPlayer(client);
			SetEntityHealth(client, 500);
			
			rankid[client] = 1;
			
			AddMenuItem(menu, "job", "Votre job est : Chef d'état.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 0)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			SetEntityHealth(client, 100);
			
			rankid[client] = 0;
			
			AddMenuItem(menu, "job", "Votre job est : Sans-Emploi.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 2)
		{
			CS_SwitchTeam(client, 3);
			CS_RespawnPlayer(client);
			SetEntityHealth(client, 400);
			
			rankid[client] = 1;
			
			AddMenuItem(menu, "job", "Votre job est : Agent CIA.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 3)
		{
			CS_SwitchTeam(client, 3);
			CS_RespawnPlayer(client);
			SetEntityHealth(client, 300);
			
			rankid[client] = 1;
			
			AddMenuItem(menu, "job", "Votre job est : Agent du FBI.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 4)
		{
			CS_SwitchTeam(client, 3);
			CS_RespawnPlayer(client);
			SetEntityHealth(client, 200);
			
			rankid[client] = 1;
			
			AddMenuItem(menu, "job", "Votre job est : Policier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 5)
		{
			CS_SwitchTeam(client, 3);
			CS_RespawnPlayer(client);
			SetEntityHealth(client, 150);
			
			rankid[client] = 1;
			
			AddMenuItem(menu, "job", "Votre job est : Gardien.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 6)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 2;
			
			AddMenuItem(menu, "job", "Votre job est : Chef Mafia.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 7)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 2;
			
			AddMenuItem(menu, "job", "Votre job est : Mafieux.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 8)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 2;
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Mafieux.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 9)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 3;
			
			AddMenuItem(menu, "job", "Votre job est : ChefDealer.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 10)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 3;
			
			AddMenuItem(menu, "job", "Votre job est : Dealer.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 11)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 3;
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Dealer", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 12)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 4;
			
			AddMenuItem(menu, "job", "Votre job est : Chef Coach.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 13)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 4;
			
			AddMenuItem(menu, "job", "Votre job est : Coach.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 14)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 4;
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Coach.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 15)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 5;
			
			AddMenuItem(menu, "job", "Votre job est : Chef Ebay.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 16)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 5;
			
			AddMenuItem(menu, "job", "Votre job est : Vendeur Ebay.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 17)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 5;
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Vendeur Ebay.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 18)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 6;
			
			AddMenuItem(menu, "job", "Votre job est : Chef Armurie.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 19)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 6;
			
			AddMenuItem(menu, "job", "Votre job est : Armurier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 20)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 6;
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Armurier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 21)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 7;
			
			AddMenuItem(menu, "job", "Votre job est : Chef Loto.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 22)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 7;
			
			AddMenuItem(menu, "job", "Votre job est : Vendeur de Ticket.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 23)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 7;
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Vendeur de Ticket.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 24)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 8;
			
			AddMenuItem(menu, "job", "Votre job est : Chef Banquier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 25)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 8;
			
			AddMenuItem(menu, "job", "Votre job est : Banquier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 26)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 8;
			
			AddMenuItem(menu, "job", "Votre job est : banquier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 27)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 9;
			
			AddMenuItem(menu, "job", "Votre job est : Chef Hôpital.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 28)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 9;
			
			AddMenuItem(menu, "job", "Votre job est : Médecin.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 29)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 9;
			
			AddMenuItem(menu, "job", "Votre job est : Infirmier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 30)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 9;
			
			AddMenuItem(menu, "job", "Votre job est : Chirurgien.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 31)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 10;
			
			AddMenuItem(menu, "job", "Votre job est : Chef Artificier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 32)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 10;
			
			AddMenuItem(menu, "job", "Votre job est : Artificier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 33)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 10;
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Artificier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 34)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 11;
			
			AddMenuItem(menu, "job", "Votre job est : Chef Tueur.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 35)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 11;
			
			AddMenuItem(menu, "job", "Votre job est : Tueur d'élite.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 36)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 11;
			
			AddMenuItem(menu, "job", "Votre job est : Tueur novice.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 37)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 12;
			
			AddMenuItem(menu, "job", "Votre job est : Chef Hôtelier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 38)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 12;
			
			AddMenuItem(menu, "job", "Votre job est : Hôtelier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 39)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			
			rankid[client] = 12;
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Hôtelier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		
		// Met le skin
		chooseskin(client);
		
		// Choisis le tag
		change_tag(client);
		
		// donne qu'un cut
		disarm(client);
		GivePlayerItem(client, "weapon_knife");
		
		// Si le joueurs a du temps de jail
		if (g_jailtime[client] == 0)
		{
			g_IsInJail[client] = 0;
			
			switch (GetRandomInt(1, 5))
			{
				case 1:
				{
					TeleportEntity(client, Float:{ -5171.555664, 622.322266, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
				}
				
				case 2:
				{
					TeleportEntity(client, Float:{ -2980.488770, 895.414673, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
				}
				
				case 3:
				{
					TeleportEntity(client, Float:{ -4419.909668, -12.021674, -447.906189 }, NULL_VECTOR, NULL_VECTOR);
				}
				
				case 4:
				{
					TeleportEntity(client, Float:{ -3572.241455, -1830.482544, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
				}
				
				case 5:
				{
					TeleportEntity(client, Float:{ -1708.746582, -1202.248779, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
		else
		{
			switch (GetRandomInt(1, 4))
			{
				case 1:
				{
					TeleportEntity(client, Float:{ -984701973, -1001996089, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
				}
						
				case 2:
				{
					TeleportEntity(client, Float:{ -985977571, -1013839247, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
				}
						
				case 3:
				{
					TeleportEntity(client, Float:{ -985179530, -1014029130, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
				}
		
				case 4:
				{
					TeleportEntity(client, Float:{ -984701973, -1001996089, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
				}
			}
			SetClientListeningFlags(client, VOICE_MUTED);
			g_jailreturn[client] = CreateTimer(1.0, Jail_Return, client, TIMER_REPEAT);
			
			g_boolreturn[client] = true;
		}
		
		PrintToChat(client, "%s : Bienvenue sur le Roleplay %s.", LOGO, TEAM);
		PrintToChat(client, "%s : Veuillez rapporter les bug sur notre forum : %s", LOGO, FORUM);
	}
}

public Connect_Menu(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// HUD INFOS

public Action:HudTimer(Handle:timer, any:client)
{
	new Handle:hBuffer = StartMessageOne("KeyHintText", client);
	
	new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	money[client] = GetEntData(client, MoneyOffset, 4);
	
	GetZone(client);
	GetJobName(client);
	GetRankName(client);
	
	if(!IsClientInGame(client))
    {
        CloseHandle(TimerHud[client]);
        return Plugin_Stop;
    }
	
	if (hBuffer == INVALID_HANDLE)
	{
		PrintToChat(client, "INVALID_HANDLE");
	}
	else
	{
		new String:tmptext[9999];
		{
			if (g_IsInJail[client] == 0)
			{
				Format(tmptext, sizeof(tmptext), "Argent : %i$\nBanque : %i$\nMétier : %s\nEntreprise : %s\nSalaire : %i$\nCapital : %i$\nHorloge : %i%i:%i%i\nZone : %s\n", money[client], bank[client], jobname, rankname, salaire[client], capital[rankid[client]], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone);
			}
			else
			{
				Format(tmptext, sizeof(tmptext), "Argent : %i$\nBanque : %i$\nMétier : %s\nEntreprise : %s\nCapital : %i$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de Jail : %i\n", money[client], bank[client], jobname, rankname, capital[rankid[client]], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
			}
			BfWriteByte(hBuffer, 1); 
			BfWriteString(hBuffer, tmptext); 
			EndMessage();
		}
	}
	
	new aim = GetClientAimTarget(client, true);
	
	if (aim != -1)
	{
		new health = GetClientHealth(aim);
		GetJobName(aim);
		
		PrintHintText(client, "%N | [HP:%i]\nJob: %s", aim, health, jobname);
		StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
	}
	return Plugin_Continue;
}

public GetZone(client)
{
	if (IsClientInGame(client))
	{
		if (IsInDistribEbay(client))
		{
			Format(RealZone, sizeof(RealZone), "Distributeur Ebay");
		}
		else if (IsInDistribLoto(client))
		{
			Format(RealZone, sizeof(RealZone), "Distributeur Atlantic");
		}
		else if (IsInDistribMafia(client))
		{
			Format(RealZone, sizeof(RealZone), "Distributeur Mafia");
		}
		else if (IsInDistribBanque(client))
		{
			Format(RealZone, sizeof(RealZone), "Distributeur Banque");
		}
		else if (IsInPlace(client))
		{
			Format(RealZone, sizeof(RealZone), "Place Marchande");
		}
		else if (IsInComico(client))
		{
			Format(RealZone, sizeof(RealZone), "Commissariat");
		}
		else if (IsInFbi(client))
		{
			Format(RealZone, sizeof(RealZone), "F.B.I");
		}
		else if (IsInArmu(client))
		{
			Format(RealZone, sizeof(RealZone), "Armurerie");
		}
		else if (IsInHosto(client))
		{
			Format(RealZone, sizeof(RealZone), "Hôpital");
		}
		else if (IsInDealer(client))
		{
			Format(RealZone, sizeof(RealZone), "Planque des Dealers");
		}
		else if (IsInMafia(client) && !IsInSalle(client))
		{
			Format(RealZone, sizeof(RealZone), "Planque Mafia");
		}
		else if (IsInMafia(client) && IsInSalle(client))
		{
			Format(RealZone, sizeof(RealZone), "Salle d'opération");
		}
		else if (IsInLoto(client))
		{
			Format(RealZone, sizeof(RealZone), "Loto");
		}
		else if (IsInBank(client))
		{
			Format(RealZone, sizeof(RealZone), "Banque d'oviscity");
		}
		else if (IsInEbay(client))
		{
			Format(RealZone, sizeof(RealZone), "Ebay");
		}
		else if (IsInCoach(client))
		{
			Format(RealZone, sizeof(RealZone), "Planque Coach");
		}
		else if (IsInEleven(client))
		{
			Format(RealZone, sizeof(RealZone), "Planque des Artificier");
		}
		else if (IsInTueur(client))
		{
			Format(RealZone, sizeof(RealZone), "Planque des Tueurs");
		}
		else if (IsInHotel(client) && !IsInA1(client) && !IsInA2(client) && !IsInA3(client) && !IsInA4(client) && !IsInA5(client) && !IsInA6(client) && !IsInA7(client) && !IsInA8(client) && !IsInA9(client) && !IsInA10(client))
		{
			Format(RealZone, sizeof(RealZone), "Hôtel");
		}
		else if (IsInHotel(client) && IsInA1(client))
		{
			Format(RealZone, sizeof(RealZone), "Appartement n°1");
		}
		else if (IsInHotel(client) && IsInA2(client))
		{
			Format(RealZone, sizeof(RealZone), "Appartement n°2");
		}
		else if (IsInHotel(client) && IsInA3(client))
		{
			Format(RealZone, sizeof(RealZone), "Appartement n°3");
		}
		else if (IsInHotel(client) && IsInA4(client))
		{
			Format(RealZone, sizeof(RealZone), "Appartement n°4");
		}
		else if (IsInHotel(client) && IsInA5(client))
		{
			Format(RealZone, sizeof(RealZone), "Appartement n°5");
		}
		else if (IsInHotel(client) && IsInA6(client))
		{
			Format(RealZone, sizeof(RealZone), "Appartement n°6");
		}
		else if (IsInHotel(client) && IsInA7(client))
		{
			Format(RealZone, sizeof(RealZone), "Appartement n°7");
		}
		else if (IsInHotel(client) && IsInA8(client))
		{
			Format(RealZone, sizeof(RealZone), "Appartement n°8");
		}
		else if (IsInHotel(client) && IsInA9(client))
		{
			Format(RealZone, sizeof(RealZone), "Appartement n°9");
		}
		else if (IsInHotel(client) && IsInA10(client))
		{
			Format(RealZone, sizeof(RealZone), "Appartement n°10");
		}
		else
		{
			Format(RealZone, sizeof(RealZone), "Extérieur");
		}
	}
}

public GetJobName(client)
{
	if (IsClientInGame(client))
	{
		if (jobid[client] == 1)
		{
			Format(jobname, sizeof(jobname), "Chef d'état");
		}
		else if (jobid[client] == 2)
		{
			Format(jobname, sizeof(jobname), "Agent C.I.A");
		}
		else if (jobid[client] == 3)
		{
			Format(jobname, sizeof(jobname), "Agent F.B.I");
		}
		else if (jobid[client] == 4)
		{
			Format(jobname, sizeof(jobname), "Policier");
		}
		else if (jobid[client] == 5)
		{
			Format(jobname, sizeof(jobname), "Gardien");
		}
		else if (jobid[client] == 6)
		{
			Format(jobname, sizeof(jobname), "Chef Mafia");
		}
		else if (jobid[client] == 7)
		{
			Format(jobname, sizeof(jobname), "Mafieux");
		}
		else if (jobid[client] == 8)
		{
			Format(jobname, sizeof(jobname), "Apprenti Mafieux");
		}
		else if (jobid[client] == 9)
		{
			Format(jobname, sizeof(jobname), "Chef Dealer");
		}
		else if (jobid[client] == 10)
		{
			Format(jobname, sizeof(jobname), "Dealer");
		}
		else if (jobid[client] == 11)
		{
			Format(jobname, sizeof(jobname), "Apprenti Dealer");
		}
		else if (jobid[client] == 12)
		{
			Format(jobname, sizeof(jobname), "Chef Coach");
		}
		else if (jobid[client] == 13)
		{
			Format(jobname, sizeof(jobname), "Coach");
		}
		else if (jobid[client] == 14)
		{
			Format(jobname, sizeof(jobname), "Apprenti Coach");
		}
		else if (jobid[client] == 15)
		{
			Format(jobname, sizeof(jobname), "Chef Ebay");
		}
		else if (jobid[client] == 16)
		{
			Format(jobname, sizeof(jobname), "Vendeur Ebay");
		}
		else if (jobid[client] == 17)
		{
			Format(jobname, sizeof(jobname), "Apprenti Vendeur Ebay");
		}
		else if (jobid[client] == 18)
		{
			Format(jobname, sizeof(jobname), "Chef Armurerie");
		}
		else if (jobid[client] == 19)
		{
			Format(jobname, sizeof(jobname), "Armurier");
		}
		else if (jobid[client] == 20)
		{
			Format(jobname, sizeof(jobname), "Apprenti Armurier");
		}
		else if (jobid[client] == 21)
		{
			Format(jobname, sizeof(jobname), "Chef Loto");
		}
		else if (jobid[client] == 22)
		{
			Format(jobname, sizeof(jobname), "Vendeur de Tickets");
		}
		else if (jobid[client] == 23)
		{
			Format(jobname, sizeof(jobname), "Apprenti Vendeur de Tickets");
		}
		else if (jobid[client] == 24)
		{
			Format(jobname, sizeof(jobname), "Chef Banquier");
		}
		else if (jobid[client] == 25)
		{
			Format(jobname, sizeof(jobname), "Banquier");
		}
		else if (jobid[client] == 26)
		{
			Format(jobname, sizeof(jobname), "Apprenti Banquier");
		}
		else if (jobid[client] == 27)
		{
			Format(jobname, sizeof(jobname), "Chef Hôpital");
		}
		else if (jobid[client] == 28)
		{
			Format(jobname, sizeof(jobname), "Médecin");
		}
		else if (jobid[client] == 29)
		{
			Format(jobname, sizeof(jobname), "Infirmier");
		}
		else if (jobid[client] == 30)
		{
			Format(jobname, sizeof(jobname), "Chirurgien");
		}
		else if (jobid[client] == 31)
		{
			Format(jobname, sizeof(jobname), "Chef Artificer");
		}
		else if (jobid[client] == 32)
		{
			Format(jobname, sizeof(jobname), "Artificier");
		}
		else if (jobid[client] == 33)
		{
			Format(jobname, sizeof(jobname), "Apprenti Artificer");
		}
		else if (jobid[client] == 34)
		{
			Format(jobname, sizeof(jobname), "Chef Tueurs");
		}
		else if (jobid[client] == 35)
		{
			Format(jobname, sizeof(jobname), "Tueur d'élite");
		}
		else if (jobid[client] == 36)
		{
			Format(jobname, sizeof(jobname), "Tueur novice");
		}
		else if (jobid[client] == 37)
		{
			Format(jobname, sizeof(jobname), "Chef Hôtelier");
		}
		else if (jobid[client] == 38)
		{
			Format(jobname, sizeof(jobname), "Hôtelier");
		}
		else if (jobid[client] == 39)
		{
			Format(jobname, sizeof(jobname), "Apprenti Hôtelier");
		}
		else if (jobid[client] == 0)
		{
			Format(jobname, sizeof(jobname), "Sans-Emploi");
		}
	}
}

public GetRankName(client)
{
	if (IsClientInGame(client))
	{
		if (rankid[client] == 1)
		{
			Format(rankname, sizeof(rankname), "Gouvernement");
		}
		else if (rankid[client] == 2)
		{
			Format(rankname, sizeof(rankname), "Mafia d'Oviscity");
		}
		else if (rankid[client] == 3)
		{
			Format(rankname, sizeof(rankname), "Dealer d'Oviscity");
		}
		else if (rankid[client] == 4)
		{
			Format(rankname, sizeof(rankname), "Coach d'Oviscity");
		}
		else if (rankid[client] == 5)
		{
			Format(rankname, sizeof(rankname), "Ebay d'Oviscity");
		}
		else if (rankid[client] == 6)
		{
			Format(rankname, sizeof(rankname), "Armurerie d'Oviscity");
		}
		else if (rankid[client] == 7)
		{
			Format(rankname, sizeof(rankname), "Loto d'Oviscity");
		}
		else if (rankid[client] == 8)
		{
			Format(rankname, sizeof(rankname), "Banque d'Oviscity");
		}
		else if (rankid[client] == 9)
		{
			Format(rankname, sizeof(rankname), "Hôpital d'Oviscity");
		}
		else if (rankid[client] == 10)
		{
			Format(rankname, sizeof(rankname), "Artificier d'Oviscity");
		}
		else if (rankid[client] == 11)
		{
			Format(rankname, sizeof(rankname), "Tueurs d'Oviscity");
		}
		else if (rankid[client] == 12)
		{
			Format(rankname, sizeof(rankname), "Hôtellerie d'Oviscity");
		}
		else if (rankid[client] == 0)
		{
			Format(rankname, sizeof(rankname), "Aucune");
		}
	}
}

// Désarmement

public disarm(player)
{
	new wepIdx;
	for (new f = 0; f < 6; f++)
		if (f < 6 && (wepIdx = GetPlayerWeaponSlot(player, f)) != -1)  
			RemovePlayerItem(player, wepIdx);
}

// Check Zones

IsInDistribEbay(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -5200.437500 && v[0] <= -5154.461914 && v[1] >= -385.967743 && v[1] <= -340.276306 && v[2] >= -520.858734 && v[2] <= -424.847900)
		return true;
	else
		return false;
}

IsInDistribBanque(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -2104.441650 && v[0] <= -2064.562988 && v[1] >= -2010.453003 && v[1] <= -1964.552002 && v[2] >= -394.567719 && v[2] <= -300.981750)
		return true;
	else
		return false;
}

IsInDistribMafia(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= 1945.3  && v[0] <= 1996.6 && v[1] >= 1450.589844 && v[1] <= 1550.112793 && v[2] >= -413.972412 && v[2] <= -270.277496)
		return true;
	else
		return false;
}

IsInDistribLoto(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -2980.0 && v[0] <= -2950.2  && v[1] >= 2120.6 && v[1] <= 2200.1 && v[2] >= -450.3 && v[2] <= -268.8)
		return true;
	else
		return false;
}

IsInPlace(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -5202.0 && v[0] <= -4303.8 && v[1] >= -464.6 && v[1] <= 447.9 && v[2] >= -518.2 && v[2] <= -62.5)
		return true;
	else
		return false;
}

IsInComico(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -3552.0 && v[0] <= -2548.2 && v[1] >= -1152.0 && v[1] <= -223.9 && v[2] >= -500.9 && v[2] <= 120.0)
		return true;

	else if (v[0] >= -3553.4 && v[0] <= -3096.0 && v[1] >= -243.9 && v[1] <= 201.0 && v[2] >= -500.0 && v[2] <= -200.0)
		return true;

	else
		return false;
}

IsInFbi(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -2863.9 && v[0] <= -2296.0 && v[1] >= -2489.9 && v[1] <= -2086.0 && v[2] >= -400.9 && v[2] <= -150.9)
		return true;
	else
		return false;
}

IsInArmu(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -5183.9 && v[0] <= -4470.0 && v[1] >= 1242.1 && v[1] <= 1703.9 && v[2] >= -400.0 && v[2] <= -200.0)
		return true;
	else
		return false;
}

IsInLoto(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -3255.9 && v[0] <= -2954.0 && v[1] >= 2050.0 && v[1] <= 2744.0 && v[2] >= -450.9 && v[2] <= 100.4)
		return true;
	else
		return false;
}

IsInBank(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -2050.0 && v[0] <= -1574.0 && v[1] >= -2975.9 && v[1] <= -1890.0 && v[2] >= -400.0 && v[2] <= -150.0)
		return true;
	else
		return false;
}

IsInMafia(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= 695.0 && v[0] <= 1700.0 && v[1] >= 1875.0 && v[1] <= 2832.0 && v[2] >= -390.0 && v[2] <= -20.0)
		return true;
	else
		return false;
}

IsInSalle(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= 1488.0 && v[0] <= 1687.9 && v[1] >= 2592.0 && v[1] <= 2831.7 && v[2] >= -428.6 && v[2] <= -268.0)
		return true;
	else
		return false;
}

IsInDealer(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -847.0 && v[0] <= -420.0 && v[1] >= 3660.0 && v[1] <= 4110.0 && v[2] >= -520.0 && v[2] <= -100.0)
		return true;
		
	if (v[0] >= -1153.9 && v[0] <= -680.0 && v[1] >= 2700.0 && v[1] <= 3743.9 && v[2] >= -530.9 && v[2] <= -250.9)
		return true;
	
	else
		return false;
}

IsInHosto(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -1771.5 && v[0] <= -400.3 && v[1] >= 525.0 && v[1] <= 1310.0 && v[2] >= -400.0 && v[2] <= 280.0)
		return true;
	else
		return false;
}

IsInEbay(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -4672.0 && v[0] <= -4440.0 && v[1] >= -752.0 && v[1] <= -460.0 && v[2] >= -550.0 && v[2] <= -200.0)
		return true;
	else
		return false;
}

IsInCoach(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= 1130.0 && v[0] <= 1936.0 && v[1] >= 355.0 && v[1] <= 1180.0 && v[2] >= -400.0 && v[2] <= -20.0)
		return true;
	else
		return false;
}

IsInEleven(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -3503.968750 && v[0] <= -3030.031250 && v[1] >= 712.031250 && v[1] <= 1231.735596 && v[2] >= -426.962463 && v[2] <= -269.653412)
		return true;
	else
		return false;
}

IsInTueur(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= 450.0 && v[0] <= 879.9 && v[1] >= -1350.9 && v[1] <= -435.8 && v[2] >= -393.9 && v[2] <= -200.6)
		return true;
	else
		return false;
}

IsInHotel(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -2022.9 && v[0] <= -1413.0 && v[1] >= -1013.0 && v[1] <= -343.4 && v[2] >= -389.5 && v[2] <= 440.1)
		return true;
	else
		return false;
}

IsInA1(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -1587.6 && v[0] <= -1413.0 && v[1] >= -663.9 && v[1] <= -380.0 && v[2] >= -220.9 && v[2] <= -80.0)
		return true;
	else
		return false;
}

IsInA2(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -2022.9 && v[0] <= -1818.2 && v[1] >= -663.9 && v[1] <= -380.0 && v[2] >= -220.9 && v[2] <= -80.0)
		return true;
	else
		return false;
}

IsInA3(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -2022.9 && v[0] <= -1820.0 && v[1] >= -987.9 && v[1] <= -700.6 && v[2] >= -220.9 && v[2] <= -80.0)
		return true;
	else
		return false;
}

IsInA4(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -1587.6 && v[0] <= -1413.0 && v[1] >= -987.9 && v[1] <= -700.6 && v[2] >= -220.9 && v[2] <= -80.1)
		return true;
	else
		return false;
}

IsInA5(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -1587.6 && v[0] <= -1413.0 && v[1] >= -663.9 && v[1] <= -380.0 && v[2] >= -70.0 && v[2] <= 85.0)
		return true;
	else
		return false;
}

IsInA6(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -1587.6 && v[0] <= -1413.0 && v[1] >= -987.9 && v[1] <= -700.6 && v[2] >= -70.0 && v[2] <= 85.0)
		return true;
	else
		return false;
}

IsInA7(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -2022.9 && v[0] <= -1820.0 && v[1] >= -987.9 && v[1] <= -700.6 && v[2] >= -70.0 && v[2] <= 85.0)
		return true;
	else
		return false;
}

IsInA8(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -2022.9 && v[0] <= -1820.0 && v[1] >= -663.9 && v[1] <= -380.0 && v[2] >= -70.0 && v[2] <= 85.0)
		return true;
	else
		return false;
}

IsInA9(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -2022.9 && v[0] <= -1820.0 && v[1] >= -987.9 && v[1] <= -380.0 && v[2] >= 100.5 && v[2] <= 268.5)
		return true;
	else
		return false;
}

IsInA10(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -1587.6 && v[0] <= -1413.0 && v[1] >= -987.9 && v[1] <= -380.0 && v[2] >= 100.5 && v[2] <= 268.5)
		return true;
	else
		return false;
}

// Dès que le joueur déco 

public OnClientDisconnect(client)
{
	SaveInfosClient(client);
	if (IsClientInGame(client))
	{
		if (g_jailtime[client] < 0)
		{
			g_jailtime[client] = 0;
		}
		
		if (levelcut[client] < 0)
		{
			levelcut[client] = 0;
		}
		
		if (g_IsTazed[client])
		{
			g_IsTazed[client] = false;
		}
		
		if (g_chirurgie[client])
		{
			g_chirurgie[client] = false;
		}
		if (g_boolexta[client])
		{
			g_boolexta[client] = false;
			drogue[client] = false;
		}
	
		if (g_boollsd[client])
		{
			g_boollsd[client] = false;
			drogue[client] = false;
		}
		
		if (g_boolcoke[client])
		{
			g_boolcoke[client] = false;
			drogue[client] = false;
		}
		
		if (g_boolhero[client])
		{
			g_boolhero[client] = false;
			drogue[client] = false;
		}
		
		if (g_appart[client])
		{
			KillTimer(TimerAppart[client]);
		}
		
		KillTazer(client);
		
		SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
		
		responsable[client] = 0;
		price[client] = 0;
		jail[client] = 0;
		TransactionWith[client] = 0;
		cible[client] = 0;
		acheteur[client] = 0;
		
		oncontrat[client] = false;
		HasKillCible[client] = false;
		

		
		SaveInfosClient(client);
		
		banned[client] = 0;
		banni[client] = 0;
		maison[client] = 0;
		maisontime[client] = 0;
		
		gObj[client] = -1;
		
		fTrashTimer(client);
		
		if (OnKit[client])
		{
			OnKit[client] = false;
			CloseHandle(GiveKit);
		}
	}
	SaveInfosClient(client);
}

fTrashTimer(client)
{
	if(TimerHud[client] != INVALID_HANDLE)
	{
		KillTimer(TimerHud[client]);
		TimerHud[client] = INVALID_HANDLE;
	}
	if (g_boolreturn[client])
	{
		KillTimer(g_jailreturn[client]);
		g_boolreturn[client] =  false;
	}
	if (g_booljail[client])
	{
		KillTimer(g_jailtimer[client]);
		g_booljail[client] =  false;
	}
	if (oncontrat[client])
	{
		KillTimer(Contrat[client]);
	}
	if (g_booldead[client])
	{
		KillTimer(g_deadtimer[client]);
		g_booldead[client] =  false;
	}
	if (g_crochetageon[client])
	{
		KillTimer(g_croche[client]);
		g_crochetageon[client] = false;
	}
	if (g_boolexta[client])
	{
		KillTimer(extasiie[client]);
	}
	if (g_boollsd[client])
	{
		KillTimer(lssd[client]);
	}
	if (g_boolcoke[client])
	{
		KillTimer(cokk[client]);
	}
	if (g_boolhero[client])
	{
		KillTimer(heroo[client]);
	}
}

// Sauvegardes System


// COMMANDES JOUEURS

public Action:Command_Ent(client, args)
{
	decl Ent;
	Ent = GetClientAimTarget(client, false);

	if (IsPlayerAlive(client))
	{
		if (GetUserFlagBits(client) > 0)
		{
			PrintToChat(client, "%s : Entité <=> %d.", LOGO, Ent);
			return Plugin_Handled;
		}
		else
		{
			PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
		}
	}
	else
	{
		PrintToChat(client, "%s : Vous devez être en vie pour utilisé cette commande.", LOGO);
	}
	return Plugin_Continue;
}

public Action:Cmd_Lock(client, args)
{
	decl Ent;
	decl String:Door[255];

	Ent = GetClientAimTarget(client, false);
	
	if (IsPlayerAlive(client))
	{
		new String:SteamId[32];
		GetClientAuthString(client, SteamId, sizeof(SteamId));
		
		if ((jobid[client] == 1) || (jobid[client] == 2) || (jobid[client] == 3) && maison[client] == 0)
		{
			if (Ent != -1)
			{
				GetEdictClassname(Ent, Door, sizeof(Door));
				
				if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
				{
					if (Entity_IsLocked(Ent))
					{
						PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
					}
					else
					{
						PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
						PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
						Entity_Lock(Ent);
						EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
					}
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if ((jobid[client] == 4) || (jobid[client] == 5))
		{
			if (Ent != -1)
			{
				if (IsInComico(Ent))
				{
					GetEdictClassname(Ent, Door, sizeof(Door));
					
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if ((jobid[client] == 6) || (jobid[client] == 7) || jobid[client] == 8)
		{
			if (Ent != -1)
			{
				if (IsInMafia(Ent))
				{
					GetEdictClassname(Ent, Door, sizeof(Door));
					
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if ((jobid[client] == 9) || (jobid[client] == 10) || jobid[client] == 11)
		{
			if (Ent != -1)
			{
				if (IsInDealer(Ent))
				{
					GetEdictClassname(Ent, Door, sizeof(Door));
					
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if ((jobid[client] == 12) || (jobid[client] == 13) || jobid[client] == 14)
		{
			if (Ent != -1)
			{
				if (IsInCoach(Ent))
				{
					GetEdictClassname(Ent, Door, sizeof(Door));
					
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if ((jobid[client] == 15) || (jobid[client] == 16) || jobid[client] == 17)
		{
			if (Ent != -1)
			{
				if (IsInEbay(Ent))
				{
					GetEdictClassname(Ent, Door, sizeof(Door));
					
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if ((jobid[client] == 18) || (jobid[client] == 19) || jobid[client] == 20)
		{
			if (Ent != -1)
			{
				if (IsInArmu(Ent))
				{
					GetEdictClassname(Ent, Door, sizeof(Door));
					
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if ((jobid[client] == 21) || (jobid[client] == 22) || jobid[client] == 23)
		{
			if (Ent != -1)
			{
				if (IsInLoto(Ent))
				{
					GetEdictClassname(Ent, Door, sizeof(Door));
					
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if ((jobid[client] == 24) || (jobid[client] == 25) || jobid[client] == 26)
		{
			if (Ent != -1)
			{
				if (IsInBank(Ent))
				{
					GetEdictClassname(Ent, Door, sizeof(Door));
					
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if ((jobid[client] == 27) || (jobid[client] == 28) || jobid[client] == 29 || jobid[client] == 30)
		{
			if (Ent != -1)
			{
				if (IsInHosto(Ent))
				{
					GetEdictClassname(Ent, Door, sizeof(Door));
					
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if ((jobid[client] == 31) || (jobid[client] == 32) || (jobid[client] == 33))
		{
			if (Ent != -1)
			{
				if (IsInEleven(Ent))
				{
					GetEdictClassname(Ent, Door, sizeof(Door));
					
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if ((jobid[client] == 34) || (jobid[client] == 35) || (jobid[client] == 36))
		{
			if (Ent != -1)
			{
				if (IsInTueur(Ent))
				{
					GetEdictClassname(Ent, Door, sizeof(Door));
					
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if ((jobid[client] == 37) || (jobid[client] == 38) || (jobid[client] == 39))
		{
			if (Ent != -1)
			{
				if (IsInHotel(Ent) && !IsInA1(Ent) && !IsInA2(Ent) && !IsInA3(Ent) && !IsInA4(Ent) && !IsInA5(Ent) && !IsInA6(Ent) && !IsInA7(Ent) && !IsInA8(Ent) && !IsInA9(Ent) && !IsInA10(Ent))
				{
					GetEdictClassname(Ent, Door, sizeof(Door));
					
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if (jobid[client] == 0)
		{
			if (Ent != -1)
			{
				GetEdictClassname(Ent, Door, sizeof(Door));
		
				if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if (maison[client] == 1)
		{
			if (Ent != -1)
			{
				GetEdictClassname(Ent, Door, sizeof(Door));
				
				if (IsInA1(Ent))
				{
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if (maison[client] == 2)
		{
			if (Ent != -1)
			{
				GetEdictClassname(Ent, Door, sizeof(Door));
				
				if (IsInA2(Ent))
				{
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if (maison[client] == 3)
		{
			if (Ent != -1)
			{
				GetEdictClassname(Ent, Door, sizeof(Door));
				
				if (IsInA3(Ent))
				{
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if (maison[client] == 4)
		{
			if (Ent != -1)
			{
				GetEdictClassname(Ent, Door, sizeof(Door));
				
				if (IsInA4(Ent))
				{
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if (maison[client] == 5)
		{
			if (Ent != -1)
			{
				GetEdictClassname(Ent, Door, sizeof(Door));
				
				if (IsInA5(Ent))
				{
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if (maison[client] == 6)
		{
			if (Ent != -1)
			{
				GetEdictClassname(Ent, Door, sizeof(Door));
				
				if (IsInA6(Ent))
				{
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if (maison[client] == 7)
		{
			if (Ent != -1)
			{
				GetEdictClassname(Ent, Door, sizeof(Door));
				
				if (IsInA7(Ent))
				{
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if (maison[client] == 8)
		{
			if (Ent != -1)
			{
				GetEdictClassname(Ent, Door, sizeof(Door));
				
				if (IsInA8(Ent))
				{
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if (maison[client] == 9)
		{
			if (Ent != -1)
			{
				GetEdictClassname(Ent, Door, sizeof(Door));
				
				if (IsInA9(Ent))
				{
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
		else if (maison[client] == 10)
		{
			if (Ent != -1)
			{
				GetEdictClassname(Ent, Door, sizeof(Door));
				
				if (IsInA10(Ent))
				{
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						if (Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà fermée a clef.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez fermé la porte a clef.", LOGO);
							PrintToConsole(client, "%s : La porte %d est maintenant fermée a clef.", LOGO, Ent);
							Entity_Lock(Ent);
							EmitSoundToAll("doors/default_locked.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:Cmd_Unlock(client, args)
{
	decl Ent;
	decl String:Doors[255];
	
	Ent = GetClientAimTarget(client, false);
	
	if (IsPlayerAlive(client))
	{
		new String:SteamId[32];
		GetClientAuthString(client, SteamId, sizeof(SteamId));
		
		if (Ent != -1)
		{
			if ((jobid[client] == 1) || (jobid[client] == 2) || (jobid[client] == 3) && maison[client] == 0)
			{
				if (Ent != -1)
				{
					GetEdictClassname(Ent, Doors, sizeof(Doors));
					
					if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
					{
						if (!Entity_IsLocked(Ent))
						{
							PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
							Entity_UnLock(Ent);
							EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if ((jobid[client] == 4) || (jobid[client] == 5))
			{
				if (IsInComico(Ent))
				{
					if (Ent != -1)
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if ((jobid[client] == 6) || (jobid[client] == 7) || (jobid[client] == 8))
			{
				if (IsInMafia(Ent))
				{
					if (Ent != -1)
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if ((jobid[client] == 9) || (jobid[client] == 10) || (jobid[client] == 11))
			{
				if (IsInDealer(Ent))
				{
					if (Ent != -1)
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if ((jobid[client] == 12) || (jobid[client] == 13) || (jobid[client] == 14))
			{
				if (IsInCoach(Ent))
				{
					if (Ent != -1)
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if ((jobid[client] == 15) || (jobid[client] == 16) || (jobid[client] == 17))
			{
				if (IsInEbay(Ent))
				{
					if (Ent != -1)
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if ((jobid[client] == 18) || (jobid[client] == 19) || (jobid[client] == 20))
			{
				if (IsInArmu(Ent))
				{
					if (Ent != -1)
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if ((jobid[client] == 21) || (jobid[client] == 22) || (jobid[client] == 23))
			{
				if (IsInLoto(Ent))
				{
					if (Ent != -1)
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if ((jobid[client] == 24) || (jobid[client] == 25) || (jobid[client] == 26))
			{
				if (IsInBank(Ent))
				{
					if (Ent != -1)
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if ((jobid[client] == 27) || (jobid[client] == 28) || (jobid[client] == 29) || (jobid[client] == 30))
			{
				if (IsInHosto(Ent))
				{
					if (Ent != -1)
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if ((jobid[client] == 31) || (jobid[client] == 32) || (jobid[client] == 33))
			{
				if (IsInEleven(Ent))
				{
					if (Ent != -1)
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if ((jobid[client] == 34) || (jobid[client] == 35) || (jobid[client] == 36))
			{
				if (IsInTueur(Ent))
				{
					if (Ent != -1)
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if ((jobid[client] == 37) || (jobid[client] == 38) || (jobid[client] == 39))
			{
				if (IsInHotel(Ent) && !IsInA1(Ent) && !IsInA2(Ent) && !IsInA3(Ent) && !IsInA4(Ent) && !IsInA5(Ent) && !IsInA6(Ent) && !IsInA7(Ent) && !IsInA8(Ent) && !IsInA9(Ent) && !IsInA10(Ent))
				{
					if (Ent != -1)
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if (jobid[client] == 0)
			{
				if (Ent != -1)
				{
					GetEdictClassname(Ent, Doors, sizeof(Doors));
			
					if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
					{
						PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if (maison[client] == 1)
			{
				if (Ent != -1)
				{
					if (IsInA1(Ent))
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if (maison[client] == 2)
			{
				if (Ent != -1)
				{
					if (IsInA2(Ent))
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if (maison[client] == 3)
			{
				if (Ent != -1)
				{
					if (IsInA3(Ent))
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if (maison[client] == 4)
			{
				if (Ent != -1)
				{
					if (IsInA4(Ent))
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if (maison[client] == 5)
			{
				if (Ent != -1)
				{
					if (IsInA5(Ent))
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if (maison[client] == 6)
			{
				if (Ent != -1)
				{
					if (IsInA6(Ent))
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if (maison[client] == 7)
			{
				if (Ent != -1)
				{
					if (IsInA7(Ent))
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if (maison[client] == 8)
			{
				if (Ent != -1)
				{
					if (IsInA8(Ent))
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if (maison[client] == 9)
			{
				if (Ent != -1)
				{
					if (IsInA9(Ent))
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
				}
				return Plugin_Handled;
			}
			else if (maison[client] == 10)
			{
				if (Ent != -1)
				{
					if (IsInA10(Ent))
					{
						GetEdictClassname(Ent, Doors, sizeof(Doors));
						
						if (StrEqual(Doors, "func_door_rotating") || StrEqual(Doors, "prop_door_rotating") || StrEqual(Doors, "func_door"))
						{
							if (!Entity_IsLocked(Ent))
							{
								PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez ouvert la porte.", LOGO);
								Entity_UnLock(Ent);
								EmitSoundToAll("doors/latchunlocked1.wav", Ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas les clef de cette porte.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
				}
				return Plugin_Handled;
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous devez visé une porte.", LOGO);
		}
	}
	return Plugin_Continue;
}

public Action:Command_Civil(client, args)
{
	if (jobid[client] == 1)
	{
		if (GetClientTeam(client) == 3)
		{
			CS_SwitchTeam(client, 2);
			CS_SetClientClanTag(client, "Sans emploi -");
			PrintToChat(client, "%s : Vous êtes désormais en civil.", LOGO);
			SetEntityModel(client, "models/player/slow/50cent/slow.mdl");
		}
		else
		{
			CS_SwitchTeam(client, 3);
			CS_SetClientClanTag(client, "C. Police -");
			PrintToChat(client, "%s : Vous êtes désormais en flic.", LOGO);
			SetEntityModel(client, "models/player/leb/t_leet.mdl");
		}
	}
	else if (jobid[client] == 2)
	{
		if (GetClientTeam(client) == 3)
		{
			CS_SwitchTeam(client, 2);
			CS_SetClientClanTag(client, "Sans emploi -");
			PrintToChat(client, "%s : Vous êtes désormais en civil.", LOGO);
			SetEntityModel(client, "models/player/slow/50cent/slow.mdl");
		}
		else
		{
			CS_SwitchTeam(client, 3);
			CS_SetClientClanTag(client, "Agent CIA -");
			PrintToChat(client, "%s : Vous êtes désormais en flic.", LOGO);
			SetEntityModel(client, "models/player/notdelite/desert_sas/ct_sas.mdl");
		}
	}
	else if (jobid[client] == 3)
	{
		if (GetClientTeam(client) == 3)
		{
			CS_SwitchTeam(client, 2);
			CS_SetClientClanTag(client, "Sans emploi -");
			PrintToChat(client, "%s : Vous êtes désormais en civil.", LOGO);
			SetEntityModel(client, "models/player/slow/50cent/slow.mdl");
		}
		else
		{
			CS_SwitchTeam(client, 3);
			CS_SetClientClanTag(client, "Agent du FBI -");
			PrintToChat(client, "%s : Vous êtes désormais en flic.", LOGO);
			SetEntityModel(client, "models/player/ics/ct_gign_fbi/ct_gign.mdl");
		}
	}
	else
	{
		PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
	}
}

public Action:Command_Cash(client, args)
{
 	if (!IsPlayerAlive(client))
 	{
		PrintToChat(client, "%s : Vous ne pouvez pas utiliser cette commande quand vous êtes mort.", LOGO);
		return Plugin_Handled;
	}			
	
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (args <= 0)
	{
		PrintToChat(client, "%s : Usage: sm_give 'amount'", LOGO);
		return Plugin_Handled;
	}
	
	if (IsPlayerAlive(client))
	{
		if (g_IsInJail[client] == 0)
		{
			new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
			money[client] = GetEntData(client, MoneyOffset, 4);

			new debit_amt = StringToInt(arg1, 10);
			if (debit_amt < 0)
			{
				PrintToChat(client, "%s : Vous ne pouvez pas donné une somme négative.", LOGO);
				return Plugin_Handled;
			}
			if (debit_amt > money[client])
			{
				PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				return Plugin_Handled;
			}

			decl Ent;
			decl String:ClassName[255];
			
			Ent = GetClientAimTarget(client, false);
		
			if(Ent != -1)
			{
				GetEdictClassname(Ent, ClassName, 255);
				
				new total_cash = (money[Ent] + debit_amt);
				if (total_cash > 65535)
				{
					new difference = (total_cash - 65535);
					debit_amt -= difference;
				}
				money[Ent] += debit_amt;
				SetEntData(Ent, MoneyOffset, money[Ent], 4, true);
		
				money[client] -= debit_amt;
				SetEntData(client, MoneyOffset, money[client], 4, true);
		
				PrintToChat(client, "%s : Tu as donné %i$ à %N.", LOGO, debit_amt, Ent);
				PrintToChat(Ent, "%s : Tu as reçu %i$ par %N.", LOGO, debit_amt, client);

				return Plugin_Handled;
			}
			else 
			{
				PrintToChat(client, "%s : Tu dois regarder un joueur.", LOGO);
			}
		}
		else 
		{
			PrintToChat(client, "%s : Vous ne pouvez pas donné de l'argent en jail", LOGO);
		}
	}
	else
	{
		PrintToChat(client, "%s : Vous devez être en vie.", LOGO);
	}
	return Plugin_Continue;
}

public Action:Command_Jail(client, args)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client))
		{
			if (IsPlayerAlive(client))
			{
				if (GetClientTeam(client) == 3)
				{
					jail[client] = GetClientAimTarget(client, true);
					
					if(jail[client] != -1)
					{
						if (g_invisible[client] == 0)
						{
							if (jail[client] < 1 || jail[client] > MaxClients) 
							{
								PrintToChat(client, "%s : Vous devez visé un joueurs", LOGO);
								return Plugin_Handled; 
							}
							
							new Float:entorigin[3], Float:clientent[3];
							GetEntPropVector(jail[client], Prop_Send, "m_vecOrigin", entorigin);
							GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
							new Float:distance = GetVectorDistance(entorigin, clientent);
							
							if (GetClientTeam(jail[client]) == 2)
							{
								if (distance <= 1000)
								{
									switch (GetRandomInt(1, 4))
									{
										case 1:
										{
											TeleportEntity(jail[client], Float:{ -984701973, -1001996089, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
										}
								
										case 2:
										{
											TeleportEntity(jail[client], Float:{ -985977571, -1013839247, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
										}
									
										case 3:
										{
											TeleportEntity(jail[client], Float:{ -985179530, -1014029130, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
										}
									
										case 4:
										{
											TeleportEntity(jail[client], Float:{ -984701973, -1001996089, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
										}
									}
									
									PrintToChat(client, "%s : Tu as emprisonné le joueurs : %N", LOGO, jail[client]);
									PrintToChat(jail[client], "%s  : Tu as été emprisonné par : %N", LOGO, client);
									
									disarm(jail[client]);
									GivePlayerItem(jail[client], "weapon_knife");
									SetClientListeningFlags(jail[client], VOICE_MUTED);
									
									g_IsInJail[jail[client]] = 1;
									
									gObj[jail[client]] = -1;
									grab[jail[client]] = false;
									
									new Handle:menu = CreateMenu(Menu_Jail);
									SetMenuTitle(menu, "Choisis la peine pour %N :", jail[client]);
									AddMenuItem(menu, "meurtrep", "Meurtre sur Policier.");
									AddMenuItem(menu, "meurtrec", "Meurtre sur Civil.");
									AddMenuItem(menu, "tentative", "Tentative de Meurtre.");
									AddMenuItem(menu, "crochetage", "Crochetage.");
									AddMenuItem(menu, "vol", "Vol.");
									AddMenuItem(menu, "nuisances", "Nuisances sonores");
									AddMenuItem(menu, "insultes", "Insultes.");
									AddMenuItem(menu, "permis", "Possession d'armes illégales.");
									AddMenuItem(menu, "intrusion", "Intrusion.");
									AddMenuItem(menu, "tir", "Tir dans la rue.");
									AddMenuItem(menu, "obstruction", "Obstruction envers les forces de l'ordres");
									AddMenuItem(menu, "evasion", "Tentative d'évasion");
									AddMenuItem(menu, "liberation", "Libéré le joueurs");
									DisplayMenu(menu, client, MENU_TIME_FOREVER);
									
									if (g_booljail[jail[client]])
									{
										KillTimer(g_jailtimer[jail[client]]);
									}
									if (g_boolreturn[jail[client]])
									{
										KillTimer(g_jailreturn[jail[client]]);
									}
								}
								else
								{
									PrintToChat(client, "%s : Vous êtes trop loin pour mettre en jail.", LOGO);
								}
							}
							else
							{
								PrintToChat(client, "%s : Vous ne pouvez pas jail un policier.", LOGO);
							}
						}
						else
						{
							PrintToChat(client, "%s : Vous devez être visible pour jail.", LOGO);
						}
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : vous devez être en vie pour emprisonné un joueurs.", LOGO);
			}
		}
	}
	return Plugin_Continue;
}

public Menu_Jail(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		if (jail[client] > 0 && jail[client] <= MaxClients)
		{
			if (IsClientInGame(jail[client]))
			{
				if (jail[client] != -1 && IsPlayerAlive(jail[client]))
				{
					new String:info[64];
					GetMenuItem(menu, param2, info, sizeof(info));
					
					if (StrEqual(info, "meurtrep"))
					{
						SetupJail(client, jail[client], 480, 1000);
						PrintToChat(jail[client], "%s : Vous avez été emprisonné pour meurtre sur policier.", LOGO);
					}
					else if (StrEqual(info, "meurtrec"))
					{
						SetupJail(client, jail[client], 360, 800);
						PrintToChat(jail[client], "%s : Vous avez été emprisonné pour meurtre sur civil.", LOGO);
					}
					else if (StrEqual(info, "tentative"))
					{
						SetupJail(client, jail[client], 300, 500);
						PrintToChat(jail[client], "%s : Vous avez été emprisonné pour tentative de meurtre.", LOGO);
					}
					else if (StrEqual(info, "crochetage"))
					{
						SetupJail(client, jail[client], 180, 200);
						PrintToChat(jail[client], "%s : Vous avez été emprisonné pour crochetage.", LOGO);
					}
					else if (StrEqual(info, "vol"))
					{
						SetupJail(client, jail[client], 180, 200);
						PrintToChat(jail[client], "%s : Vous avez été emprisonné pour vol.", LOGO);
					}
					else if (StrEqual(info, "nuisances"))
					{
						SetupJail(client, jail[client], 240, 500);
						PrintToChat(jail[client], "%s : Vous avez été emprisonné pour nuisances sonores.", LOGO);
					}
					else if (StrEqual(info, "insultes"))
					{
						SetupJail(client, jail[client], 240, 600);
						PrintToChat(jail[client], "%s : Vous avez été emprisonné pour insultes.", LOGO);
					}
					else if (StrEqual(info, "permis"))
					{
						SetupJail(client, jail[client], 300, 600);
						PrintToChat(jail[client], "%s : Vous avez été emprisonné pour possession d'armes illégales.", LOGO);
					}
					else if (StrEqual(info, "intrusion"))
					{
						SetupJail(client, jail[client], 180, 200);
						PrintToChat(jail[client], "%s : Vous avez été emprisonné pour intrusion.", LOGO);
					}
					else if (StrEqual(info, "tir"))
					{
						SetupJail(client, jail[client], 180, 250);
						PrintToChat(jail[client], "%s : Vous avez été emprisonné pour tir dans la rue.", LOGO);
					}
					else if (StrEqual(info, "obstruction"))
					{
						SetupJail(client, jail[client], 120, 250);
						PrintToChat(jail[client], "%s : Vous avez été emprisonné pour obstruction envers la police.", LOGO);
					}
					else if (StrEqual(info, "evasion"))
					{
						SetupJail(client, jail[client], 200, 400);
						PrintToChat(jail[client], "%s : Vous avez été emprisonné pour Tentative d'évasion.", LOGO);
					}
					else if (StrEqual(info, "liberation"))
					{
						SetupJail(client, jail[client], 10, 0);
						PrintToChat(jail[client], "%s : Vous allez être libéré", LOGO);
					}
				}
			}
		}
	}
}

public SetupJail(policier, detenu, temps, amende)
{
	if (IsClientInGame(detenu))
	{
		if (IsClientInGame(policier))
		{
			g_jailtime[detenu] = temps;
			
			g_booljail[detenu] = true;
			
			price[detenu] = amende;
			responsable[detenu] = policier;
			
			new Handle:menu = CreateMenu(Caution_Menu);
			SetMenuTitle(menu, "Voulez-vous payé votre caution de %i$ ?", amende);
			AddMenuItem(menu, "oui", "Oui je veux.");
			AddMenuItem(menu, "non", "Non merci.");
			DisplayMenu(menu, detenu, MENU_TIME_FOREVER);
			
			g_jailtimer[detenu] =  CreateTimer(1.0, Jail_Raison, detenu, TIMER_REPEAT);
		}
	}
}

public Caution_Menu(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		if (client > 0 && client <= MaxClients)
		{
			if (StrEqual(info, "oui"))
			{
				if (money[client] >= price[client])
				{
					if (price[client] > 0)
					{
						PrintToChat(responsable[client], "%s : Le joueur %N a payé sa caution de %i", LOGO, client, price[client]);
						PrintToChat(client, "%s : Vous avez payé votre caution de %i.", LOGO, price[client]); 
						
						money[client] = money[client] - price[client];
						AdCash(responsable[client], price[client] / 2);
						capital[rankid[responsable[client]]] = capital[rankid[responsable[client]]] + price[client] / 2;
						
						g_jailtime[client] = g_jailtime[client] / 2;
						
						SetEntData(client, MoneyOffset, money[client], 4, true);
					}
					else
					{
						PrintToChat(client, "%s : Vous ne pouvez pas payé votre caution, vous allez être libéré.", LOGO);
					}
				}
				else
				{
					if (cb[client] == 1)
					{
						if (bank[client] >= price[client])
						{
							if (price[client] > 0)
							{
								PrintToChat(responsable[client], "%s : Le joueur %N a payé sa caution de %i", LOGO, client, price[client]);
								PrintToChat(client, "%s : Vous avez payé votre caution de %i.", LOGO, price[client]); 
								
								money[client] = money[client] - price[client];
								AdCash(responsable[client], price[client] / 2);
								capital[rankid[responsable[client]]] = capital[rankid[responsable[client]]] + price[client] / 2;
								
								g_jailtime[client] = g_jailtime[client] / 2;
							}
							else
							{
								PrintToChat(client, "%s : Vous ne pouvez pas payé votre caution, vous allez être libéré.", LOGO);
							}
						}
						else
						{
							PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
							PrintToChat(responsable[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(responsable[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
			}
			else if (StrEqual(info, "non"))
			{
				PrintToChat(responsable[client], "%s : Le joueur %N a refusé de payé sa caution de %i.", LOGO, client, price[client]);
				PrintToChat(client, "%s : Vous avez refusé de payé votre caution de %i.", LOGO, price[client]);
			}
		}
	}
}

public Action:Jail_Raison(Handle:timer, any:client)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client))
		{
			if (g_jailtime[client] > 0)
			{
				g_jailtime[client] -= 1;
			
				if (g_jailtime[client] == 0)
				{
					KillTimer(g_jailtimer[client]);
					
					PrintToChat(client, "%s : Vous avez été libéré de prison.", LOGO);
					
					SetClientListeningFlags(client, VOICE_NORMAL);
					
					switch (GetRandomInt(1, 5))
					{
						case 1:
						{
							TeleportEntity(client, Float:{ -5171.555664, 622.322266, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
						}
				
						case 2:
						{
							TeleportEntity(client, Float:{ -2980.488770, 895.414673, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
						}
				
						case 3:
						{
							TeleportEntity(client, Float:{ -4419.909668, -12.021674, -447.906189 }, NULL_VECTOR, NULL_VECTOR);
						}
				
						case 4:
						{
							TeleportEntity(client, Float:{ -3572.241455, -1830.482544, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
						}
				
						case 5:
						{
							TeleportEntity(client, Float:{ -1708.746582, -1202.248779, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
						}
					}
					
					g_IsInJail[client] = 0;
					g_jailtime[client] = 0;
					price[client] = 0;
					responsable[client] = 0;
					
					g_booljail[client] = false;
				}
			}
		}
	}
}

public Action:Jail_Return(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (g_jailtime[client] > 0)
		{
			g_jailtime[client] -= 1;
			
			if (g_jailtime[client] == 0)
			{
				g_IsInJail[client] = 0;
				g_jailtime[client] = 0;
				price[client] = 0;
				responsable[client] = 0;
				
				PrintToChat(client, "%s : Vous avez été libéré de prison.", LOGO);
				
				switch (GetRandomInt(1, 5))
				{
					case 1:
					{
						TeleportEntity(client, Float:{ -5171.555664, 622.322266, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
					}
			
					case 2:
					{
						TeleportEntity(client, Float:{ -2980.488770, 895.414673, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
					}
			
					case 3:
					{
						TeleportEntity(client, Float:{ -4419.909668, -12.021674, -447.906189 }, NULL_VECTOR, NULL_VECTOR);
					}
			
					case 4:
					{
						TeleportEntity(client, Float:{ -3572.241455, -1830.482544, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
					}
			
					case 5:
					{
						TeleportEntity(client, Float:{ -1708.746582, -1202.248779, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
					}
				}
				KillTimer(g_jailreturn[client]);
				
				g_boolreturn[client] = false;
			}
		}
	}
}

public Action:Command_Jaillist(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if (GetClientTeam(client) == 3)
			{
				ShowPrisonner(client);
				
				return Plugin_Handled;
			}
			else
			{
				PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous devez être en vie.", LOGO);
		}
	}
	return Plugin_Continue;
}

ShowPrisonner(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Prisonnier);
		SetMenuTitle(menu, "Liste des prisonniers");
		SetMenuExitButton(menu, true);
        
		AddPrisonniers(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddPrisonniers(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && g_jailtime[i] > 0)
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s => %i", name, g_jailtime[i]);
	
			AddMenuItem(menu, user_id, display, ITEMDRAW_DISABLED);
		}
	}
}

public Menu_Prisonnier(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Command_Vis(client, args)
{
	if ((jobid[client] == 1) || (jobid[client] == 2))
	{
		if (IsPlayerAlive(client))
		{
			if (g_invisible[client] == 1)
			{
				SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
				PrintToChat(client, "%s : Vous êtes désormais visible.", LOGO);
				g_invisible[client] = 0;
			}
			else
			{
				SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
				PrintToChat(client, "%s : Vous êtes désormais invisible.", LOGO);
				g_invisible[client] = 1;
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous devez être en vie pour utilisé cette commande.", LOGO);
		}
	}
	else
	{
		PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
	}
	return Plugin_Continue;
} 

public Action:Hook_SetTransmit(entity, client) 
{ 
	if (entity != client)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue; 
}

// JOBMENU

public Action:Command_Jobmenu(client, args)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		LoopPlayers(client);
	}
	else
	{
		PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
	}
}

LoopPlayers(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(MenuHandler_LoopPlayers);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		Addplayers(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public Addplayers(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if(IsClientInGame(i))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
            
			GetClientName(i, name, sizeof(name));
            
			Format(display, sizeof(display), "%s (%s)", name, user_id);
            
			AddMenuItem(menu, user_id, display);
		}
	}
}

public MenuHandler_LoopPlayers(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64], String:SteamId[32];
        
		GetMenuItem(menu, param2, info, sizeof(info));
        
		new UserID = StringToInt(info);
		p[client] = GetClientOfUserId(UserID);
		
		GetClientAuthString(client, SteamId, sizeof(SteamId));
		
		new Handle:menuc = CreateMenu(jobmenu);
		SetMenuTitle(menuc, "Choisis le job de : %N (%d) :", p[client], UserID);
		AddMenuItem(menuc, "1", "Chef police");
		AddMenuItem(menuc, "2", "Agent de la CIA");
		AddMenuItem(menuc, "3", "Agent du FBI");
		AddMenuItem(menuc, "4", "Agent de police");
		AddMenuItem(menuc, "5", "Gardien");
		AddMenuItem(menuc, "6", "Chef mafia");
		AddMenuItem(menuc, "7", "Mafieux");
		AddMenuItem(menuc, "8", "Apprenti Mafieux");
		AddMenuItem(menuc, "15", "Chef Ebay");
		AddMenuItem(menuc, "16", "Vendeur Ebay");
		AddMenuItem(menuc, "17", "Apprenti V Ebay");
		AddMenuItem(menuc, "18", "Chef de l'armurie");
		AddMenuItem(menuc, "19", "Armurier");
		AddMenuItem(menuc, "20", "Apprenti Armurier");
		AddMenuItem(menuc, "12", "Chef des Coach");
		AddMenuItem(menuc, "13", "Coach");
		AddMenuItem(menuc, "14", "Apprenti Coach");
		AddMenuItem(menuc, "0", "Sans emploi");
		AddMenuItem(menuc, "21", "Chef Loto");
		AddMenuItem(menuc, "22", "Vendeur de Ticket");
		AddMenuItem(menuc, "23", "Apprenti Vendeur de Ticket");
		AddMenuItem(menuc, "9", "Chef Dealer");
		AddMenuItem(menuc, "10", "Dealer");
		AddMenuItem(menuc, "11", "Apprenti Dealer");
		AddMenuItem(menuc, "24", "Chef Banquier");
		AddMenuItem(menuc, "25", "Banquier");
		AddMenuItem(menuc, "26", "Apprenti Banquier");
		AddMenuItem(menuc, "27", "Chef Hôpital");
		AddMenuItem(menuc, "28", "Médecin");
		AddMenuItem(menuc, "29", "Infirmier");
		AddMenuItem(menuc, "30", "Chirurgien");
		AddMenuItem(menuc, "31", "Chef Artificier");
		AddMenuItem(menuc, "32", "Artificier");
		AddMenuItem(menuc, "33", "Apprenti Artificier");
		AddMenuItem(menuc, "34", "Chef Tueur");
		AddMenuItem(menuc, "35", "Tueur d'élite");
		AddMenuItem(menuc, "36", "Tueur novice");
		AddMenuItem(menuc, "37", "Chef Hôtelier");
		AddMenuItem(menuc, "38", "Hôtelier");
		AddMenuItem(menuc, "39", "Apprenti Hôtelier");
		DisplayMenu(menuc, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public jobmenu(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		jobid[p[client]] = StringToInt(info);
		chooseskin(p[client]);
		
		if (StrEqual(info, "2"))
		{
			CS_SetClientClanTag(p[client], "Agent CIA -");
			
			rankid[p[client]] = 1;
			
			if (GetClientTeam(p[client]) == 2)
			{
				CS_SwitchTeam(p[client], 3);
				SetEntityModel(p[client], "models/player/ct_gign.mdl");
			}
		}
		else if (StrEqual(info, "1"))
		{
			CS_SetClientClanTag(p[client], "C. police -");
			
			rankid[p[client]] = 1;
			
			if (GetClientTeam(p[client]) == 2)
			{
				CS_SwitchTeam(p[client], 3);
				SetEntityModel(p[client], "models/player/ct_gign.mdl");
			}
		}
		else if (StrEqual(info, "3"))
		{
			CS_SetClientClanTag(p[client], "Agent du FBI -");
			
			rankid[p[client]] = 1;
			
			if (GetClientTeam(p[client]) == 2)
			{
				CS_SwitchTeam(p[client], 3);
				SetEntityModel(p[client], "models/player/ct_gign.mdl");
			}
		}
		else if (StrEqual(info, "4"))
		{
			CS_SetClientClanTag(p[client], "Policier -");
			
			rankid[p[client]] = 1;
			
			if (GetClientTeam(p[client]) == 2)
			{
				CS_SwitchTeam(p[client], 3);
				SetEntityModel(p[client], "models/player/ct_gign.mdl");
			}
		}
		else if (StrEqual(info, "5"))
		{
			CS_SetClientClanTag(p[client], "Gardien -");
			
			rankid[p[client]] = 1;
			
			if (GetClientTeam(p[client]) == 2)
			{
				CS_SwitchTeam(p[client], 3);
				SetEntityModel(p[client], "models/player/ct_gign.mdl");
			}
		}
		else if (StrEqual(info, "6"))
		{
			CS_SetClientClanTag(p[client], "C. Mafia -");
			
			rankid[p[client]] = 2;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "7"))
		{
			CS_SetClientClanTag(p[client], "Mafieux -");
			
			rankid[p[client]] = 2;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "8"))
		{
			CS_SetClientClanTag(p[client], "A. Mafieux -");
			
			rankid[p[client]] = 2;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "21"))
		{
			CS_SetClientClanTag(p[client], "C. Loto -");
			
			rankid[p[client]] = 7;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "22"))
		{
			CS_SetClientClanTag(p[client], "V. Ticket -");
			
			rankid[p[client]] = 7;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "31"))
		{
			CS_SetClientClanTag(p[client], "C. Artificier -");
			
			rankid[p[client]] = 10;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "32"))
		{
			CS_SetClientClanTag(p[client], "Artificier -");
			
			rankid[p[client]] = 10;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "33"))
		{
			CS_SetClientClanTag(p[client], "A. Artificier -");
			
			rankid[p[client]] = 10;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "23"))
		{
			CS_SetClientClanTag(p[client], "A.V. Ticket -");
			
			rankid[p[client]] = 7;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "18"))
		{
			CS_SetClientClanTag(p[client], "C. Armurie -");
			
			rankid[p[client]] = 6;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "19"))
		{
			CS_SetClientClanTag(p[client], "Armurier -");
			
			rankid[p[client]] = 6;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "20"))
		{
			CS_SetClientClanTag(p[client], "A. Armurier -");
			
			rankid[p[client]] = 6;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "15"))
		{
			CS_SetClientClanTag(p[client], "C. Ebay -");
			
			rankid[p[client]] = 5;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "16"))
		{
			CS_SetClientClanTag(p[client], "V. Ebay -");
			
			rankid[p[client]] = 5;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "17"))
		{
			CS_SetClientClanTag(p[client], "A.V. Ebay -");
			
			rankid[p[client]] = 5;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "0"))
		{
			CS_SetClientClanTag(p[client], "Sans emploi -");
			
			rankid[p[client]] = 0;
			salaire[p[client]] = 50;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "12"))
		{
			CS_SetClientClanTag(p[client], "C. Coach -");
			
			rankid[p[client]] = 4;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "13"))
		{
			CS_SetClientClanTag(p[client], "Coach -");
			
			rankid[p[client]] = 4;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "14"))
		{
			CS_SetClientClanTag(p[client], "A. Coach -");
			
			rankid[p[client]] = 4;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "9"))
		{
			CS_SetClientClanTag(p[client], "C. Dealer -");
			
			rankid[p[client]] = 3;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "10"))
		{
			CS_SetClientClanTag(p[client], "Dealer -");
			
			rankid[p[client]] = 3;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "11"))
		{
			CS_SetClientClanTag(p[client], "A. Dealer -");
			
			rankid[p[client]] = 3;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "24"))
		{
			CS_SetClientClanTag(p[client], "C. Banquier -");
			
			rankid[p[client]] = 8;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "25"))
		{
			CS_SetClientClanTag(p[client], "Banquier -");
			
			rankid[p[client]] = 8;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "26"))
		{
			CS_SetClientClanTag(p[client], "A. Banquier -");
			
			rankid[p[client]] = 8;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "27"))
		{
			CS_SetClientClanTag(p[client], "C. Hôpital -");
			
			rankid[p[client]] = 9;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "28"))
		{
			CS_SetClientClanTag(p[client], "Médecin -");
			
			rankid[p[client]] = 9;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "29"))
		{
			CS_SetClientClanTag(p[client], "Infirmier -");
			
			rankid[p[client]] = 9;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "30"))
		{
			CS_SetClientClanTag(p[client], "Chirurgien -");
			
			rankid[p[client]] = 9;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "34"))
		{
			CS_SetClientClanTag(p[client], "C. Tueur -");
			
			rankid[p[client]] = 11;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "35"))
		{
			CS_SetClientClanTag(p[client], "Tueur d'élite -");
			
			rankid[p[client]] = 11;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "36"))
		{
			CS_SetClientClanTag(p[client], "Tueur Novice -");
			
			rankid[p[client]] = 11;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "37"))
		{
			CS_SetClientClanTag(p[client], "C. Hôtelier -");
			
			rankid[p[client]] = 12;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "38"))
		{
			CS_SetClientClanTag(p[client], "Hôtelier -");
			
			rankid[p[client]] = 12;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "39"))
		{
			CS_SetClientClanTag(p[client], "Apprenti Hôtelier -");
			
			rankid[p[client]] = 12;
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// GIVE MONEY

public Action:Command_Money(client, args)
{
	if (jobid[client] == 1)
	{
		seekplayers(client);
	}
	else
	{
		PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
	}
	return Plugin_Continue;
}

seekplayers(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(menu_money);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		ajoutplayers(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public ajoutplayers(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
            
			GetClientName(i, name, sizeof(name));
            
			Format(display, sizeof(display), "%s (%s)", name, user_id);
            
			AddMenuItem(menu, user_id, display);
		}
	}
}

public menu_money(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
        
		new UserID = StringToInt(info);
		p[client] = GetClientOfUserId(UserID);
		
		new Handle:menuc = CreateMenu(menu_givemoney);
		SetMenuTitle(menuc, "Choisis le montant : %N (%d) :", p[client], UserID);
		AddMenuItem(menuc, "1", "1000");
		AddMenuItem(menuc, "2", "10000");
		AddMenuItem(menuc, "3", "100000");
		AddMenuItem(menuc, "4", "1000000");
		DisplayMenu(menuc, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public menu_givemoney(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "1"))
		{
			bank[p[client]] = bank[p[client]] + 1000;
			PrintToChat(p[client], "%s : Vous avez reçu 1000$ en banque par %N", LOGO, client);
			PrintToChat(client, "%s : Vous avez donné 1000$ à %N", LOGO, p[client]);
		}
		else if (StrEqual(info, "2"))
		{
			bank[p[client]] = bank[p[client]] + 10000;
			PrintToChat(p[client], "%s : Vous avez reçu 10000$ en banque par %N", LOGO, client);
			PrintToChat(client, "%s : Vous avez donné 10000$ à %N", LOGO, p[client]);
		}
		else if (StrEqual(info, "3"))
		{
			bank[p[client]] = bank[p[client]] + 100000;
			PrintToChat(p[client], "%s : Vous avez reçu 100000$ en banque par %N", LOGO, client);
			PrintToChat(client, "%s : Vous avez donné 100000$ à %N", LOGO, p[client]);
		}
		else if (StrEqual(info, "4"))
		{
			bank[p[client]] = bank[p[client]] + 1000000;
			PrintToChat(p[client], "%s : Vous avez reçu 1000000$ en banque par %N", LOGO, client);
			PrintToChat(client, "%s : Vous avez donné 1000000$ à %N", LOGO, p[client]);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// COMMANDES INFORMATIONS

public Action:Command_Infos(client, args)
{
	if (IsPlayerAlive(client))
	{
		new Handle:panel = CreatePanel();
		SetPanelTitle(panel, "Roleplay City :");
		new String:forum[60], String:version[60];
		Format(version, sizeof(version), "Infos Roleplay City : %s", PLUGIN_VERSION);
		Format(forum, sizeof(forum), "Forum : %s", FORUM),
		DrawPanelText(panel, forum);
		DrawPanelText(panel, "Codeur : Ultimatum Phoenix Qc");
		DrawPanelText(panel, "Recrutement : [ON]");
		DrawPanelText(panel, version);
 
		SendPanelToClient(panel, client, infos, 50);
	}
}

public infos(Handle:panel, MenuAction:action, client, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(panel);
	}
}

// TAZER

public Action:Command_tazer(client, args)
{
	if (GetClientTeam(client) == 3)
	{
		new i = GetClientAimTarget(client, true);

		if (!IsValidEdict(i) || g_IsTazed[i] == true || GetClientTeam(i) == 3 || !IsPlayerAlive(i) || !IsPlayerAlive(client))	
			return Plugin_Handled;
		
		new Float:entorigin[3], Float:clientent[3];
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", entorigin);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
		new Float:distance = GetVectorDistance(entorigin, clientent);
			
		if (distance <= 800)
		{
			g_IsTazed[i] = true;
			decl String:player_name[65], String:gardien_name[65];
			GetClientName(i, player_name, sizeof(player_name));
			GetClientName(client, gardien_name, sizeof(gardien_name));
			g_Count[i] = 10.0;
			g_tazer[client]--;
			
			EmitSoundToAll(SOUND_TAZER, client, _, _, _, 1.0);
			clientent[2] += 45;
			entorigin[2] += 45;
		
			TE_SetupBeamPoints(clientent, entorigin, g_LightingSprite, 0, 1, 0, 1.0, 20.0, 0.0, 2, 5.0, TAZER_COLORBLUE, 3);
	
			TE_SendToAll();

			SetEntityMoveType(i, MOVETYPE_NONE);
			g_TazerTimer[i] = CreateTimer(1.0, DoTazer, i, TIMER_REPEAT);
		}
		else
		{
			PrintToChat(client, "%s : Vous êtes trop loin pour tazer.", LOGO);
		}
	}
	else
	{
		PrintToChat(client, "%s : Vous n'avez pas accès à cette commande", LOGO);
	}
	return Plugin_Continue;
}

public Action:DoTazer(Handle:timer, any:client)
{
	if (g_IsTazed[client] == true && IsClientInGame(client) && IsPlayerAlive(client))
	{
		g_Count[client] -= 1.0;
		if (g_Count[client] >= 0.0)
		{
			new Float:entorigin[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", entorigin);
			
			for(new ii=1; ii<8; ii++) 
			{
				entorigin[2]+= (ii*9);
				
				TE_SetupBeamRingPoint(entorigin, 45.0, 45.1, g_modelLaser, g_modelHalo, 0, 1, 0.1, 8.0, 1.0, TAZER_COLORBLUE, 1, 0);
				
				TE_SendToAll();

				entorigin[2]-= (ii*9);
			}
		}
		else
		{
			g_IsTazed[client] = false;
			g_Count[client] = 0.0;
			
			SetEntityMoveType(client, MOVETYPE_WALK);
			
			KillTazer(client);
		}
	}
}

public KillTazer(client)
{
	if (g_TazerTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_TazerTimer[client]);
		g_TazerTimer[client] = INVALID_HANDLE;
	}
}

// COMMANDE ITEM

public Action:Command_Item(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if (g_IsInJail[client] == 0)
			{
				new Handle:menu = CreateMenu(Menu_Item);
				SetMenuTitle(menu, "Voici ce que contient ton sac :");
				if (kitcrochetage[client] > 0)
				{
					new String:kit[64];
					Format(kit, sizeof(kit), "Kit de crochetage(Quantité : %d)", kitcrochetage[client]);
					AddMenuItem(menu, "Kit", kit);
				}
				if (awp[client] > 0)
				{
					new String:awpp[64];
					Format(awpp, sizeof(awpp), "AWP(Quantité : %d)", awp[client]);
					AddMenuItem(menu, "awp", awpp);
				}
				if (m249[client] > 0)
				{
					new String:batteuse[64];
					Format(batteuse, sizeof(batteuse), "M249(Quantité : %d)", m249[client]);
					AddMenuItem(menu, "m249", batteuse);
				}
				if (ak47[client] > 0)
				{
					new String:ak[64];
					Format(ak, sizeof(ak), "AK47(Quantité : %d)", ak47[client]);
					AddMenuItem(menu, "ak47", ak);
				}
				if (m4a1[client] > 0)
				{
					new String:m4[64];
					Format(m4, sizeof(m4), "M4A1(Quantité : %d)", m4a1[client]);
					AddMenuItem(menu, "m4a1", m4);
				}
				if (sg550[client] > 0)
				{
					new String:sg5500[64];
					Format(sg5500, sizeof(sg5500), "SG550(Quantité : %d)", sg550[client]);
					AddMenuItem(menu, "sg550", sg5500);
				}
				if (sg552[client] > 0)
				{
					new String:sg5520[64];
					Format(sg5520, sizeof(sg5520), "SG552(Quantité : %d)", sg552[client]);
					AddMenuItem(menu, "sg552", sg5520);
				}
				if (aug[client] > 0)
				{
					new String:augg[64];
					Format(augg, sizeof(augg), "AUG(Quantité : %d)", aug[client]);
					AddMenuItem(menu, "aug", augg);
				}
				if (galil[client] > 0)
				{
					new String:galile[64];
					Format(galile, sizeof(galile), "GALIL(Quantité : %d)", galil[client]);
					AddMenuItem(menu, "galil", galile);
				}
				if (famas[client] > 0)
				{
					new String:famass[64];
					Format(famass, sizeof(famass), "FAMAS(Quantité : %d)", famas[client]);
					AddMenuItem(menu, "famas", famass);
				}
				if (scout[client] > 0)
				{
					new String:scoutt[64];
					Format(scoutt, sizeof(scoutt), "SCOUT(Quantité : %d)", scout[client]);
					AddMenuItem(menu, "scout", scoutt);
				}
				if (mp5[client] > 0)
				{
					new String:mp55[64];
					Format(mp55, sizeof(mp55), "MP5(Quantité : %d)", mp5[client]);
					AddMenuItem(menu, "mp5", mp55);
				}
				if (tmp[client] > 0)
				{
					new String:tmpp[64];
					Format(tmpp, sizeof(tmpp), "TMP(Quantité : %d)", tmp[client]);
					AddMenuItem(menu, "tmp", tmpp);
				}
				if (ump[client] > 0)
				{
					new String:umpp[64];
					Format(umpp, sizeof(umpp), "UMP(Quantité : %d)", ump[client]);
					AddMenuItem(menu, "ump", umpp);
				}
				if (p90[client] > 0)
				{
					new String:p900[64];
					Format(p900, sizeof(p900), "P90(Quantité : %d)", p90[client]);
					AddMenuItem(menu, "p90", p900);
				}
				if (mac10[client] > 0)
				{
					new String:mac100[64];
					Format(mac100, sizeof(mac100), "MAC10(Quantité : %d)", mac10[client]);
					AddMenuItem(menu, "mac10", mac100);
				}
				if (m3[client] > 0)
				{
					new String:m33[64];
					Format(m33, sizeof(m33), "M3(Quantité : %d)", m3[client]);
					AddMenuItem(menu, "m3", m33);
				}
				if (xm1014[client] > 0)
				{
					new String:xm[64];
					Format(xm, sizeof(xm), "XM1014(Quantité : %d)", xm1014[client]);
					AddMenuItem(menu, "xm1014", xm);
				}
				if (deagle[client] > 0)
				{
					new String:deag[64];
					Format(deag, sizeof(deag), "DEAGLE(Quantité : %d)", deagle[client]);
					AddMenuItem(menu, "deagle", deag);
				}
				if (usp[client] > 0)
				{
					new String:uspp[64];
					Format(uspp, sizeof(uspp), "USP(Quantité : %d)", usp[client]);
					AddMenuItem(menu, "usp", uspp);
				}
				if (glock[client] > 0)
				{
					new String:gloc[64];
					Format(gloc, sizeof(gloc), "GLOCK(Quantité : %d)", glock[client]);
					AddMenuItem(menu, "glock", gloc);
				}
				if (elite[client] > 0)
				{
					new String:elit[64];
					Format(elit, sizeof(elit), "ELITE(Quantité : %d)", elite[client]);
					AddMenuItem(menu, "elite", elit);
				}
				if (ticket10[client] > 0)
				{
					new String:ticket10000[64];
					Format(ticket10000, sizeof(ticket10000), "Ticket 10$(Quantité : %d)", ticket10[client]);
					AddMenuItem(menu, "tic10", ticket10000);
				}
				if (ticket100[client] > 0)
				{
					new String:ticket100000[64];
					Format(ticket100000, sizeof(ticket100000), "Ticket 100$(Quantité : %d)", ticket100[client]);
					AddMenuItem(menu, "tic100", ticket100000);
				}
				if (ticket1000[client] > 0)
				{
					new String:ticket1000000[64];
					Format(ticket1000000, sizeof(ticket1000000), "Ticket 1000$(Quantité : %d)", ticket1000[client]);
					AddMenuItem(menu, "tic1000", ticket1000000);
				}
				if (cartouche[client] > 0)
				{
					new String:kar[64];
					Format(kar, sizeof(kar), "Cartouche(Quantité : %d)", cartouche[client]);
					AddMenuItem(menu, "cartouche", kar);
				}
				if (props1[client] > 0)
				{
					new String:props11[64];
					Format(props11, sizeof(props11), "PROPS1(Quantité : %d)", props1[client]);
					AddMenuItem(menu, "props1", props11);
				}
				if (props2[client] > 0)
				{
					new String:props22[64];
					Format(props22, sizeof(props22), "PROPS2(Quantité : %d)", props2[client]);
					AddMenuItem(menu, "props2", props22);
				}
				if (heroine[client] > 0)
				{
					new String:hero[64];
					Format(hero, sizeof(hero), "HEROINE(Quantité : %d)", heroine[client]);
					AddMenuItem(menu, "heroine", hero);
				}
				if (exta[client] > 0)
				{
					new String:ext[64];
					Format(ext, sizeof(ext), "EXTASIE(Quantité : %d)", exta[client]);
					AddMenuItem(menu, "exta", ext);
				}
				if (lsd[client] > 0)
				{
					new String:ls[64];
					Format(ls, sizeof(ls), "LSD(Quantité : %d)", lsd[client]);
					AddMenuItem(menu, "lsd", ls);
				}
				if (coke[client] > 0)
				{
					new String:cok[64];
					Format(cok, sizeof(cok), "COKE(Quantité : %d)", coke[client]);
					AddMenuItem(menu, "coke", cok);
				}
				if (pack[client] > 0)
				{
					new String:pak[64];
					Format(pak, sizeof(pak), "PROJECTILES(Quantité : %d)", pack[client]);
					AddMenuItem(menu, "pack", pak);
				}
				if (kevlar[client] > 0)
				{
					new String:kev[64];
					Format(kev, sizeof(kev), "KEVLAR(Quantité : %d)", kevlar[client]);
					AddMenuItem(menu, "kevlar", kev);
				}
				DisplayMenu(menu, client, MENU_TIME_FOREVER);
			}
			else
			{
				PrintToChat(client, "%s : Vous ne pouvez pas ouvrir votre sac en jail.", LOGO);
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous devez être en vie pour ouvrir votre sac.", LOGO);
		}
	}
	return Plugin_Continue;
}

public Menu_Item(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{
			new String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if (StrEqual(info, "Kit"))
			{
				if ((jobid[client] == 6) || (jobid[client] == 7) || (jobid[client] == 8))
				{	
					if (!g_crochetageon[client])
					{
						new String:Door[255];
			
						Entiter[client] = GetClientAimTarget(client, false);
						
						if (Entiter[client] != -1)
						{
							GetEdictClassname(Entiter[client], Door, sizeof(Door));
							
							if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
							{
								if (Entity_IsLocked(Entiter[client]))
								{
									new timestamp;
									timestamp = GetTime();
						
									if ((timestamp - g_crochetage[client]) < 20)
									{
										PrintToChat(client, "%s : Vous devez attendre %i secondes avant de pouvoir crocheté une porte.", LOGO, (20 - (timestamp - g_crochetage[client])) );
									}
									else
									{
										new Float:entorigin[3], Float:clientent[3];
										GetEntPropVector(Entiter[client], Prop_Send, "m_vecOrigin", entorigin);
										GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
										new Float:distance = GetVectorDistance(entorigin, clientent);
										new Float:vec[3];
										GetClientAbsOrigin(client, vec);
										vec[2] += 10;
								

										if (distance > 80)
										{
											PrintToChat(client, "%s : Vous êtes trop loin pour crocheter cette porte.", LOGO);
										}
										else
										{
											g_crochetage[client] = GetTime();
											
											// DIFFUSE BARRE
											SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime()); 
											SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 8);
											
											// TIMER DIFFUSE
											g_croche[client] = CreateTimer(8.0, TimerCrochetage, client, TIMER_REPEAT);
											
											// FREEZE
											SetEntityRenderColor(client, 255, 0, 0, 0);
											SetEntityMoveType(client, MOVETYPE_NONE);
											
											// BALISE
											TE_SetupBeamRingPoint(vec, 50.0, 70.0, g_BeamSprite, g_modelHalo, 0, 15, 0.6, 15.0, 0.0, redColor, 10, 0);
											TE_SendToAll();
											
											
											PrintToChat(client, "%s : Vous crochetez la porte.", LOGO);
											PrintToChat(client, "%s : Vous avez utilisé un kit de crochetage.", LOGO);
											
											
											kitcrochetage[client] = kitcrochetage[client] - 1;
											
											g_crochetageon[client] = true;
										}
									}
								}
								else
								{
									PrintToChat(client, "%s : La porte est déjà ouverte.", LOGO);
								}
							}
							else
							{
								PrintToChat(client, "%s : Veuillez visé une porte.", LOGO);
							}
						}
						else
						{
							PrintToChat(client, "%s : Veuillez visé une porte.", LOGO);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous êtes déjà en train de crocheté.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez être mafieux pour utilisé cet objet.", LOGO);
				}
			}
			else if (StrEqual(info, "awp"))
			{
				GivePlayerItem(client, "weapon_awp");
				
				PrintToChat(client, "%s : Vous avez utilisé une AWP.", LOGO);
				
				awp[client] = awp[client] - 1;
			}
			else if (StrEqual(info, "scout"))
			{
				GivePlayerItem(client, "weapon_scout");
				
				PrintToChat(client, "%s : Vous avez utilisé un SCOUT.", LOGO);
				
				scout[client] = scout[client] - 1;
			}
			else if (StrEqual(info, "m249"))
			{
				GivePlayerItem(client, "weapon_m249");
				
				PrintToChat(client, "%s : Vous avez utilisé une M249.", LOGO);
				
				m249[client] = m249[client] - 1;
			}
			else if (StrEqual(info, "ak47"))
			{
				GivePlayerItem(client, "weapon_ak47");
				
				PrintToChat(client, "%s : Vous avez utilisé un AK47.", LOGO);
				
				ak47[client] = ak47[client] - 1;
			}
			else if (StrEqual(info, "m4a1"))
			{
				GivePlayerItem(client, "weapon_m4a1");
				
				PrintToChat(client, "%s : Vous avez utilisé une M4A1", LOGO);
				
				m4a1[client] = m4a1[client] - 1;
			}
			else if (StrEqual(info, "sg550"))
			{
				GivePlayerItem(client, "weapon_sg550");
				
				PrintToChat(client, "%s : Vous avez utilisé un SG550", LOGO);
				
				sg550[client] = sg550[client] - 1;
			}
			else if (StrEqual(info, "sg552"))
			{
				GivePlayerItem(client, "weapon_sg552");
				
				PrintToChat(client, "%s : Vous avez utilisé un SG552", LOGO);
				
				sg552[client] = sg552[client] - 1;
			}
			else if (StrEqual(info, "aug"))
			{
				GivePlayerItem(client, "weapon_aug");
				
				PrintToChat(client, "%s : Vous avez utilisé un AUG", LOGO);
				
				aug[client] = aug[client] - 1;
			}
			else if (StrEqual(info, "galil"))
			{
				GivePlayerItem(client, "weapon_galil");
				
				PrintToChat(client, "%s : Vous avez utilisé un GALIL", LOGO);
				
				galil[client] = galil[client] - 1;
			}
			else if (StrEqual(info, "famas"))
			{
				GivePlayerItem(client, "weapon_famas");
				
				PrintToChat(client, "%s : Vous avez utilisé un FAMAS", LOGO);
				
				famas[client] = famas[client] - 1;
			}
			else if (StrEqual(info, "mp5"))
			{
				GivePlayerItem(client, "weapon_mp5navy");
				
				PrintToChat(client, "%s : Vous avez utilisé une MP5", LOGO);
				
				mp5[client] = mp5[client] - 1;
			}
			else if (StrEqual(info, "mac10"))
			{
				GivePlayerItem(client, "weapon_mac10");
				
				PrintToChat(client, "%s : Vous avez utilisé un MAC10", LOGO);
				
				mac10[client] = mac10[client] - 1;
			}
			else if (StrEqual(info, "tmp"))
			{
				GivePlayerItem(client, "weapon_tmp");
				
				PrintToChat(client, "%s : Vous avez utilisé un TMP", LOGO);
				
				tmp[client] = tmp[client] - 1;
			}
			else if (StrEqual(info, "ump"))
			{
				GivePlayerItem(client, "weapon_ump45");
				
				PrintToChat(client, "%s : Vous avez utilisé un UMP45", LOGO);
				
				ump[client] = ump[client] - 1;
			}
			else if (StrEqual(info, "p90"))
			{
				GivePlayerItem(client, "weapon_p90");
				
				PrintToChat(client, "%s : Vous avez utilisé une P90", LOGO);
				
				p90[client] = p90[client] - 1;
			}
			else if (StrEqual(info, "m3"))
			{
				GivePlayerItem(client, "weapon_m3");
				
				PrintToChat(client, "%s : Vous avez utilisé un M3", LOGO);
				
				m3[client] = m3[client] - 1;
			}
			else if (StrEqual(info, "xm1014"))
			{
				GivePlayerItem(client, "weapon_xm1014");
				
				PrintToChat(client, "%s : Vous avez utilisé un XM1014", LOGO);
				
				xm1014[client] = xm1014[client] - 1;
			}
			else if (StrEqual(info, "deagle"))
			{
				GivePlayerItem(client, "weapon_deagle");
				
				PrintToChat(client, "%s : Vous avez utilisé un DEAGLE", LOGO);
				
				deagle[client] = deagle[client] - 1;
			}
			else if (StrEqual(info, "usp"))
			{
				GivePlayerItem(client, "weapon_usp");
				
				PrintToChat(client, "%s : Vous avez utilisé un USP", LOGO);
				
				usp[client] = usp[client] - 1;
			}
			else if (StrEqual(info, "glock"))
			{
				GivePlayerItem(client, "weapon_glock");
				
				PrintToChat(client, "%s : Vous avez utilisé une GLOCK", LOGO);
				
				glock[client] = glock[client] - 1;
			}
			else if (StrEqual(info, "elite"))
			{
				GivePlayerItem(client, "weapon_elite");
				
				PrintToChat(client, "%s : Vous avez utilisé des ELITES", LOGO);
				
				elite[client] = elite[client] - 1;
			}
			else if (StrEqual(info, "pack"))
			{
				GivePlayerItem(client, "weapon_flashbang");
				GivePlayerItem(client, "weapon_hegrenade");
				GivePlayerItem(client, "weapon_smokegrenade");
				
				PrintToChat(client, "%s : Vous avez utilisé des PROJECTILES", LOGO);
				
				pack[client] = pack[client] - 1;
			}
			else if (StrEqual(info, "kevlar"))
			{
				SetEntProp(client, Prop_Data, "m_ArmorValue", 100);
				
				PrintToChat(client, "%s : Vous avez utilisé un KEVLAR", LOGO);
				
				kevlar[client] = kevlar[client] - 1;
			}
			else if (StrEqual(info, "tic10"))
			{
				PrintToChat(client, "%s : Vous avez utilisé un ticket de 10$", LOGO);
				
				switch (GetRandomInt(1, 10))
				{
					case 1:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 2:
					{		
						AdCash(client, 30);
						
						PrintToChat(client, "%s : Vous avez gagné 30$.", LOGO);
					}
					
					case 3:
					{
						AdCash(client, 5);
						
						PrintToChat(client, "%s : Vous avez gagné 5$.", LOGO);
					}
					
					case 4:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 5:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 6:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 7:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 8:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 9:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 10:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
				}
				ticket10[client] -= 1;
			}
			else if (StrEqual(info, "tic100"))
			{
				PrintToChat(client, "%s : Vous avez utilisé un ticket de 100$", LOGO);
				
				switch (GetRandomInt(1, 10))
				{
					case 1:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 2:
					{		
						AdCash(client, 300);
						
						PrintToChat(client, "%s : Vous avez gagné 300$.", LOGO);
					}
					
					case 3:
					{
						AdCash(client, 70);
						
						PrintToChat(client, "%s : Vous avez gagné 70$.", LOGO);
					}
					
					case 4:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 5:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 6:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 7:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 8:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 9:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 10:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
				}
				ticket100[client] -= 1;
			}
			else if (StrEqual(info, "tic1000"))
			{
				PrintToChat(client, "%s : Vous avez utilisé un ticket de 1000$", LOGO);
				
				switch (GetRandomInt(1, 10))
				{
					case 1:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 2:
					{		
						AdCash(client, 3000);
						
						PrintToChat(client, "%s : Vous avez gagné 3000$.", LOGO);
					}
					
					case 3:
					{
						AdCash(client, 700);
						
						PrintToChat(client, "%s : Vous avez gagné 700$.", LOGO);
					}
					
					case 4:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 5:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 6:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 7:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 8:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 9:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
					
					case 10:
					{
						PrintToChat(client, "%s : Vous n'avez rien gagné.", LOGO);
					}
				}
				ticket1000[client] -= 1;
			}
			else if (StrEqual(info, "cartouche"))
			{
				decl String:WeaponName[32];
				Client_GetActiveWeaponName(client, WeaponName, sizeof(WeaponName));
				
				new weapon = Client_GetActiveWeapon(client);
				
				RemoveEdict(weapon);
				
				GivePlayerItem(client, WeaponName);
				
				PrintToChat(client, "%s : Vous avez utilisé une CARTOUCHE.", LOGO);
				
				cartouche[client] = cartouche[client] - 1;
			}
			else if (StrEqual(info, "heroine"))
			{
				if (!drogue[client])
				{
					SetEntityHealth(client, 500);
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);
					
					PrintToChat(client, "%s : Vous avez utilisé de l'héroine.", LOGO);
					
					heroine[client] = heroine[client] - 1;
					
					drogue[client] = true;
					
					heroo[client] = CreateTimer(60.0, Timer_Hero, client);
					g_boolhero[client] = true;
					
					ClientCommand(client, "r_screenoverlay effects/com_shield002a.vmt");
				}
				else
				{
					PrintToChat(client, "%s : Vous êtes déjà en train d'utilisé une drogue.", LOGO);
				}
			}
			else if (StrEqual(info, "coke"))
			{
				if (!drogue[client])
				{
					SetEntityHealth(client, 300);
					SetEntityGravity(client, 0.5);
					
					PrintToChat(client, "%s : Vous avez utilisé de la coke.", LOGO);
					
					coke[client] = coke[client] - 1;
					
					drogue[client] = true;
					
					cokk[client] = CreateTimer(60.0, Timer_Coke, client);
					g_boolcoke[client] = true;
					
					ClientCommand(client, "r_screenoverlay debug/yuv.vmt");
				}
				else
				{
					PrintToChat(client, "%s : Vous êtes déjà en train d'utilisé une drogue.", LOGO);
				}
			}
			else if (StrEqual(info, "lsd"))
			{
				if (!drogue[client])
				{
					SetEntityHealth(client, 200);
					SetEntityGravity(client, 0.5);
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.2);
					
					PrintToChat(client, "%s : Vous avez utilisé du LSD.", LOGO);
					
					lsd[client] = lsd[client] - 1;
					
					drogue[client] = true;
					
					lssd[client] = CreateTimer(60.0, Timer_Lsd, client);
					g_boollsd[client] = true;
					
					ClientCommand(client, "r_screenoverlay models/effects/portalfunnel_sheet.vmt");
				}
				else
				{
					PrintToChat(client, "%s : Vous êtes déjà en train d'utilisé une drogue.", LOGO);
				}
			}
			else if (StrEqual(info, "exta"))
			{
				if (!drogue[client])
				{
					SetEntityHealth(client, 150);
					SetEntityGravity(client, 0.5);
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.2);
					
					PrintToChat(client, "%s : Vous avez utilisé de l' extasie.", LOGO);
					
					exta[client] = exta[client] - 1;
					
					drogue[client] = true;
					
					extasiie[client] = CreateTimer(60.0, Timer_Exta, client);
					g_boolexta[client] = true;
					
					ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
				}
				else
				{
					PrintToChat(client, "%s : Vous êtes déjà en train d'utilisé une drogue.", LOGO);
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:TimerCrochetage(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			new String:Door[255];
				
			GetEdictClassname(Entiter[client], Door, sizeof(Door));
				
			switch (GetRandomInt(1, 2))
			{
				case 1:
				{
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						PrintToChat(client, "%s : Vous avez crocheter la porte avec succès.", LOGO);
						Entity_UnLock(Entiter[client]);
						AcceptEntityInput(Entiter[client], "Toggle", client, client);
						SetEntityMoveType(client, MOVETYPE_WALK);
						SetEntityRenderColor(client, 255, 255, 255, 255);
				
						g_porte[client] += 1;
				
						g_crochetageon[client] = false;
				
						if (g_porte[client] == 20)
						{
							PrintToChatAll("%s : Le joueur \x03%N\x01 a remporté le succès \x03Crocheteur du dimanche\x01.", LOGO, client);
							EmitSoundToClient(client, "roleplay_sm/success.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
							g_succesporte20[client] = 1;
								
							if (g_porte[client] == 50)
							{
								PrintToChatAll("%s : Le joueur \x03%N\x01 a remporté le succès \x03Crocheteur expérimenté \x01.", LOGO, client);
								EmitSoundToClient(client, "roleplay_sm/success.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								g_succesporte50[client] = 1;
									
								if (g_porte[client] == 100)
								{
									PrintToChatAll("%s : Le joueur \x03%N\x01 a remporté le succès \x03Crocheteur professionnel \x01.", LOGO, client);
									EmitSoundToClient(client, "roleplay_sm/success.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
									g_succesporte100[client] = 1;
								}
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé la porte, réessayez !", LOGO);
					}
				}
			
				case 2:
				{
					if (StrEqual(Door, "func_door_rotating") || StrEqual(Door, "prop_door_rotating") || StrEqual(Door, "func_door"))
					{
						PrintToChat(client, "%s : Vous avez échoué le crochetage.", LOGO);
						SetEntityMoveType(client, MOVETYPE_WALK);
						SetEntityRenderColor(client, 255, 255, 255, 255);
					
						g_crochetageon[client] = false;
					}
				}
			}
			
			// STOP DIFFUSE BARRE
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime()); 
			SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
				
			KillTimer(g_croche[client]);
		}
	}
}

public Action:Timer_Hero(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			drogue[client] = false;
			
			PrintToChat(client, "%s : Votre drogue ne fait plus d'effet.", LOGO);
			
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			
			g_boolhero[client] = false;
			
			ClientCommand(client, "r_screenoverlay 0");
		}
	}
}

public Action:Timer_Coke(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			drogue[client] = false;
			
			PrintToChat(client, "%s : Votre drogue ne fait plus d'effet.", LOGO);
			
			SetEntityGravity(client, 1.0);
			
			g_boolcoke[client] = false;
			
			ClientCommand(client, "r_screenoverlay 0");
		}
	}
}

public Action:Timer_Lsd(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			drogue[client] = false;
			
			PrintToChat(client, "%s : Votre drogue ne fait plus d'effet.", LOGO);
			
			SetEntityGravity(client, 1.0);
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			
			g_boollsd[client] = false;
			
			ClientCommand(client, "r_screenoverlay 0");
		}
	}
}

public Action:Timer_Exta(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			drogue[client] = false;
			
			PrintToChat(client, "%s : Votre drogue ne fait plus d'effet.", LOGO);
			
			SetEntityGravity(client, 1.0);
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			
			g_boolexta[client] = false;
			
			ClientCommand(client, "r_screenoverlay 0");
		}
	}
}

// COMMANDE DEMISSION

public Action:Command_Demission(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if (jobid[client] > 0)
			{
				new Handle:menu = CreateMenu(Menu_Demission);
				SetMenuTitle(menu, "Veux tu démissioner ?");
				AddMenuItem(menu, "oui", "Oui je veux.");
				AddMenuItem(menu, "non", "Non je me suis trompé.");
				DisplayMenu(menu, client, MENU_TIME_FOREVER);
			}
			else
			{
				PrintToChat(client, "%s : Vous n'avez pas de job.", LOGO);
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous devez être vivant pour cette commande.", LOGO);
		}
	}
}

public Menu_Demission(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 0;
			rankid[client] = 0;
			salaire[client] = 50;
			PrintToChat(client, "%s : Vous avez quitté votre travail.", LOGO);
			
			if (GetClientTeam(client) == 3)
			{
				CS_SwitchTeam(client, 2);
				SetEntityModel(client, "models/player/t_guerilla.mdl");
			}
			CS_SetClientClanTag(client, "Sans emploi -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// LEVEL CUT -1

public DestroyLevel(client)
{
	if (IsClientInGame(client))
	{
		new String:sWeaponName[64];
		GetClientWeapon(client, sWeaponName, sizeof(sWeaponName));
		
		if (StrEqual(sWeaponName, "weapon_knife"))
		{
			if (levelcut[client] > 0)
			{
				levelcut[client] = levelcut[client] - 1;
			}
		}
	}
}

// ENGAGER

public Action:Command_Engager(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if ((jobid[client] == 6) || (jobid[client] == 9) || (jobid[client] == 12) || (jobid[client] == 15) || (jobid[client] == 18) || (jobid[client] == 21) || (jobid[client] == 24) || (jobid[client] == 27) || (jobid[client] == 31) || (jobid[client] == 34) || (jobid[client] == 37))
			{
				ShowClients(client);
			}
			else
			{
				PrintToChat(client, "%s : Vous devez être chef.", LOGO);
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous devez être vivant.", LOGO);
		}
	}
}

ShowClients(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(MenuHandler_PlayerList);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		AddAlivePlayersToMenu(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddAlivePlayersToMenu(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if(IsClientInGame(i) && IsPlayerAlive(i) && jobid[i] == 0)
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
            
			GetClientName(i, name, sizeof(name));
            
			Format(display, sizeof(display), "%s (%s)", name, user_id);
            
			AddMenuItem(menu, user_id, display);
		}
	}
}

public MenuHandler_PlayerList(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
        
		new UserID = StringToInt(info);
		l[client] = GetClientOfUserId(UserID);
        
		if (jobid[client] == 6)
		{
			new Handle:menua = CreateMenu(MenuHandler_Mafia);
			SetMenuTitle(menua, "Choisis le job :");
			AddMenuItem(menua, "7", "Mafieux");
			AddMenuItem(menua, "8", "Apprenti Mafieux");
			DisplayMenu(menua, client, MENU_TIME_FOREVER);
		}
		else if (jobid[client] == 9)
		{
			new Handle:menua = CreateMenu(MenuHandler_Deal);
			SetMenuTitle(menua, "Choisis le job :");
			AddMenuItem(menua, "10", "Dealer");
			AddMenuItem(menua, "11", "Apprenti Dealer");
			DisplayMenu(menua, client, MENU_TIME_FOREVER);
		}
		else if (jobid[client] == 12)
		{
			new Handle:menua = CreateMenu(MenuHandler_Coach);
			SetMenuTitle(menua, "Choisis le job :");
			AddMenuItem(menua, "13", "Coach");
			AddMenuItem(menua, "14", "Apprenti Coach");
			DisplayMenu(menua, client, MENU_TIME_FOREVER);
		}
		else if (jobid[client] == 15)
		{
			new Handle:menua = CreateMenu(MenuHandler_Ebay);
			SetMenuTitle(menua, "Choisis le job :");
			AddMenuItem(menua, "16", "Vendeur Ebay");
			AddMenuItem(menua, "17", "Apprenti Vendeur Ebay");
			DisplayMenu(menua, client, MENU_TIME_FOREVER);
		}
		else if (jobid[client] == 18)
		{
			new Handle:menua = CreateMenu(MenuHandler_Armurie);
			SetMenuTitle(menua, "Choisis le job :");
			AddMenuItem(menua, "19", "Armurier");
			AddMenuItem(menua, "20", "Apprenti Armurier");
			DisplayMenu(menua, client, MENU_TIME_FOREVER);
		}
		else if (jobid[client] == 21)
		{
			new Handle:menua = CreateMenu(MenuHandler_Loto);
			SetMenuTitle(menua, "Choisis le job :");
			AddMenuItem(menua, "22", "Vendeur de Tickets");
			AddMenuItem(menua, "23", "Apprenti Vendeur de Tickets");
			DisplayMenu(menua, client, MENU_TIME_FOREVER);
		}
		else if (jobid[client] == 24)
		{
			new Handle:menua = CreateMenu(MenuHandler_Bank);
			SetMenuTitle(menua, "Choisis le job :");
			AddMenuItem(menua, "25", "Banquier");
			AddMenuItem(menua, "26", "Apprenti Banquier");
			DisplayMenu(menua, client, MENU_TIME_FOREVER);
		}
		else if (jobid[client] == 27)
		{
			new Handle:menua = CreateMenu(MenuHandler_Hosto);
			SetMenuTitle(menua, "Choisis le job :");
			AddMenuItem(menua, "28", "Médecin");
			AddMenuItem(menua, "29", "Infirmier");
			AddMenuItem(menua, "30", "Chirurgien");
			DisplayMenu(menua, client, MENU_TIME_FOREVER);
		}
		else if (jobid[client] == 31)
		{
			new Handle:menua = CreateMenu(MenuHandler_Artifice);
			SetMenuTitle(menua, "Choisis le job :");
			AddMenuItem(menua, "32", "Artificier");
			AddMenuItem(menua, "33", "Apprenti Artificier");
			DisplayMenu(menua, client, MENU_TIME_FOREVER);
		}
		else if (jobid[client] == 34)
		{
			new Handle:menua = CreateMenu(MenuHandler_Tueur);
			SetMenuTitle(menua, "Choisis le job :");
			AddMenuItem(menua, "35", "Tueur d'élite");
			AddMenuItem(menua, "36", "Tueur novice");
			DisplayMenu(menua, client, MENU_TIME_FOREVER);
		}
		else if (jobid[client] == 37)
		{
			new Handle:menua = CreateMenu(MenuHandler_Hotel);
			SetMenuTitle(menua, "Choisis le job :");
			AddMenuItem(menua, "38", "Hôtelier");
			AddMenuItem(menua, "39", "Apprenti Hôtelier");
			DisplayMenu(menua, client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Mafia(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "7"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Mafieux);
			SetMenuTitle(menu1, "Veux-tu devenir Mafieux ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "8"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_AMafieux);
			SetMenuTitle(menu1, "Veux-tu devenir Apprenti Mafieux ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Tueur(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "35"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Elite);
			SetMenuTitle(menu1, "Veux-tu devenir Tueur d'élite ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "36"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Novice);
			SetMenuTitle(menu1, "Veux-tu devenir Tueur novice ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Elite(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client]= 35;
			rankid[client] = 11;
			CS_SetClientClanTag(client, "Tueur d'élite -");

		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Novice(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client]= 36;
			rankid[client] = 11;
			CS_SetClientClanTag(client, "Tueur novice -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Hosto(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "28"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Medecin);
			SetMenuTitle(menu1, "Veux-tu devenir Médecin ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "29"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Infirmier);
			SetMenuTitle(menu1, "Veux-tu devenir Infirmier ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "30"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Chirurgien);
			SetMenuTitle(menu1, "Veux-tu devenir Chirurgien ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Hotel(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "38"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Hotelier);
			SetMenuTitle(menu1, "Veux-tu devenir Hôtelier ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "39"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_AHotelier);
			SetMenuTitle(menu1, "Veux-tu devenir Apprenti Hôtelier ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Hotelier(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client]= 38;
			rankid[client] = 12;
			CS_SetClientClanTag(client, "Artificier -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_AHotelier(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client]= 39;
			rankid[client] = 12;
			CS_SetClientClanTag(client, "A. Artificier -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Artifice(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "32"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Artificier);
			SetMenuTitle(menu1, "Veux-tu devenir Artificier ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "33"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Aartificier);
			SetMenuTitle(menu1, "Veux-tu devenir Apprenti Artificier ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Artificier(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client]= 32;
			rankid[client] = 10;
			
			capital[client] = capital[rankid[client]];
			CS_SetClientClanTag(client, "Artificier -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Aartificier(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client]= 33;
			rankid[client] = 10;
			
			capital[client] = capital[rankid[client]];
			CS_SetClientClanTag(client, "A. Artificier -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Bank(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "25"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Banquier);
			SetMenuTitle(menu1, "Veux-tu devenir Banquier ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "26"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_ABanquier);
			SetMenuTitle(menu1, "Veux-tu devenir Apprenti Banquier ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Banquier(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client]= 25;
			rankid[client] = 8;
			CS_SetClientClanTag(client, "Banquier -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_ABanquier(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 26;
			rankid[client] = 8;
			
			
			CS_SetClientClanTag(client, "A. Banquier -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Mafieux(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 7;
			rankid[client] = 2;
			
			
			CS_SetClientClanTag(client, "Mafieux -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_AMafieux(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 8;
			rankid[client] = 2;
			
			
			CS_SetClientClanTag(client, "A. Mafieux -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Medecin(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 28;
			rankid[client] = 9;
			
			
			CS_SetClientClanTag(client, "Médecin -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Infirmier(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 29;
			rankid[client] = 9;
			
			
			CS_SetClientClanTag(client, "Infirmier -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Chirurgien(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 30;
			rankid[client] = 9;
			
			
			CS_SetClientClanTag(client, "Chirurgien -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Deal(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "10"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Dealer);
			SetMenuTitle(menu1, "Veux-tu devenir Dealer ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "11"))
		{
			new Handle:menu2 = CreateMenu(MenuHandler_ADealer);
			SetMenuTitle(menu2, "Veux-tu devenir Apprenti Dealer ?");
			AddMenuItem(menu2, "oui", "Oui je veux");
			AddMenuItem(menu2, "non", "Non merci");
			DisplayMenu(menu2, l[client], MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Dealer(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 10;
			rankid[client] = 3;
			
			
			CS_SetClientClanTag(client, "Dealer -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_ADealer(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 11;
			rankid[client] = 3;
			
			
			CS_SetClientClanTag(client, "A. Dealer -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Coach(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "13"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Coachh);
			SetMenuTitle(menu1, "Veux-tu devenir Coach ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "14"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_ACoach);
			SetMenuTitle(menu1, "Veux-tu devenir Apprenti Coach ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Coachh(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 13;
			rankid[client] = 4;
			
			
			CS_SetClientClanTag(client, "Coach -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_ACoach(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 14;
			rankid[client] = 4;
			
			
			CS_SetClientClanTag(client, "A. Coach -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Ebay(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "16"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_VEbay);
			SetMenuTitle(menu1, "Veux-tu devenir Vendeur Ebay ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "17"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_AVEbay);
			SetMenuTitle(menu1, "Veux-tu devenir Apprenti Vendeur Ebay ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_VEbay(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 16;
			rankid[client] = 5;
			
			
			CS_SetClientClanTag(client, "V. Ebay -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_AVEbay(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 17;
			rankid[client] = 5;
			
			
			CS_SetClientClanTag(client, "A.V. Ebay -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Armurie(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "19"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_Armurier);
			SetMenuTitle(menu1, "Veux-tu devenir Armurier ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "20"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_AArmurier);
			SetMenuTitle(menu1, "Veux-tu devenir Apprenti Armurier ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Armurier(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 19;
			rankid[client] = 6;
			
			
			CS_SetClientClanTag(client, "Armurier -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_AArmurier(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 20;
			rankid[client] = 6;
			
			
			CS_SetClientClanTag(client, "A. Armurier -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_Loto(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "22"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_VTicket);
			SetMenuTitle(menu1, "Veux-tu devenir Vendeur de Tickets ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "23"))
		{
			new Handle:menu1 = CreateMenu(MenuHandler_AVTicket);
			SetMenuTitle(menu1, "Veux-tu devenir Apprenti Vendeur de Tickets ?");
			AddMenuItem(menu1, "oui", "Oui je veux");
			AddMenuItem(menu1, "non", "Non merci");
			DisplayMenu(menu1, l[client], MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_VTicket(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 22;
			rankid[client] = 7;
			
			
			CS_SetClientClanTag(client, "V. Tickets -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_AVTicket(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "oui"))
		{
			jobid[client] = 23;
			rankid[client] = 7;
			
			
			CS_SetClientClanTag(client, "A.V. Tickets -");
		}
		else if (StrEqual(info, "non"))
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// ENQUETE

public Action:Command_Enquete(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if (GetClientTeam(client) == 3)
			{
				z[client] = GetClientAimTarget(client, true);
				
				if (z[client] != -1)
				{
					new String:edictname[128];
						
					new String:SteamId[32];
					GetClientAuthString(z[client], SteamId, sizeof(SteamId));
						
					new life = GetClientHealth(z[client]);
					
					GetEdictClassname(z[client], edictname, 128);
						
					if(StrEqual(edictname, "player"))
					{
						if (IsPlayerAlive(z[client]))
						{
							PrintToChat(client, "%s : Pseudo : %N	||	Steam ID : %s", LOGO, z[client], SteamId);
							PrintToChat(client, "%s : Level CUT : %i	||	HP : %d", LOGO, levelcut[z[client]], life);
							PrintToChat(client, "%s : Permis Lourd : %s	||	Permis Leger : %s", LOGO, (permislourd[z[client]] > 0 ? "Oui" : "Non"), (permisleger[z[client]] > 0 ? "Oui" : "Non"));
							PrintToChat(client, "%s : JailTime : %i", LOGO, g_jailtime[z[client]]);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé un joueurs.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé un joueurs.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous devez être vivant.", LOGO);
		}
	}
}

// RW

public Action:Command_Rw(client, args)
{
	if (IsPlayerAlive(client))
	{
		if (GetClientTeam(client) == 3)
		{	
			new Ent;
			Ent = GetClientAimTarget(client, false);

			if (Ent != -1)
			{
				new String:Classname[32];
				GetEdictClassname(Ent, Classname, sizeof(Classname));

				if (StrContains(Classname, "weapon_", false) != -1)
				{
					RemoveEdict(Ent);
					PrintToChat(client, "%s : Vous avez supprimé l'arme au sol.", LOGO);
				}
				else
				{
					PrintToChat(client, "%s : Ce n'est pas une arme.", LOGO);
				}
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
		}
	}
}

// INFOS COMMANDES

public Action:Command_Roleplay(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			new Handle:menua = CreateMenu(Menu_Rp); 
			SetMenuTitle(menua, "Commandes du Roleplay :", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "virer", "/virer => Viré un joueur", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "engager", "/engager => Engager un joueur", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "vendre", "/vendre => Vendre un item", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "infos", "/infos => Informations sur le Plugin", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "unlock", "/unlock => Déverrouillé une porte", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "lock", "/lock => Verrouillé une porte", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "civil", "/civil => Se mettre en civil", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "jail", "/jail => Mettre en jail un joueur", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "give", "/give => Donné de l'argent a un joueur", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "tazer", "/taser => Tazé un joueur", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "vol", "/vol => Volé un joueur", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "demission", "/demission => Démissioné de son travail", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "enquete", "/enquete => Faire une enquête", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "+force", "/+force => Porté un joueur", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "del", "/del => Supprime l'arme au sol visée", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "vis", "/vis => Devenir invisible", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "jobmenu", "/jobmenu => Donné un job a un joueur", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "money", "/money => Donné de l'argent a un joueur", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "item", "/item => Ouvrir son inventaire", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "perqui", "/perquisition => Faire une perquisition", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "armu", "/armurerie => Ouvrir l'armurerie.", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "changename", "/changename => changé de pseudo.", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "out", "/out => Expulsé de chez vous.", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "jaillist", "/jaillist => Affiche les joueurs en jail.", ITEMDRAW_DISABLED); 
			AddMenuItem(menua, "infoscut", "/infoscut => Affiche les informations level cut.", ITEMDRAW_DISABLED);
			AddMenuItem(menua, "salaire", "/salaire => Modifier le salaire.", ITEMDRAW_DISABLED);
			DisplayMenu(menua, client, MENU_TIME_FOREVER);
			
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Menu_Rp(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_End) 
	{ 
		CloseHandle(menu);
	} 
}

// PERQUISITIONS

public Action:Command_Perqui(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if (GetClientTeam(client) == 3)
			{
				PrintToChatAll("%s : Perquisition de la \x04Police ! \x03Pas de résistance !", LOGO);
				PrintToChatAll("%s : \x04%N \x03dirige la perquisition !", LOGO, client);
			}
			else
			{
				PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous devez être en vie.", LOGO);
		}
	}
}

// ARMURERIE

public Action:Command_Armurie(client, args)
{
	if (IsPlayerAlive(client))
	{
		if (GetClientTeam(client) == 3)
		{
			decl String:player_name[65];
			GetClientName(client, player_name, sizeof(player_name));
		
			new String:SteamId[32];
			GetClientAuthString(client, SteamId, sizeof(SteamId));
		
			new Handle:menu = CreateMenu(armu);
			SetMenuTitle(menu, "Choisis ton arme : %s (%s) :", player_name, SteamId);
			if (jobid[client] == 1)
			{
				AddMenuItem(menu, "awp", "AWP");
				AddMenuItem(menu, "batteuse", "M249");
				AddMenuItem(menu, "m4", "M4A1");
				AddMenuItem(menu, "ak", "AK47");
				AddMenuItem(menu, "aug", "AUG");
				AddMenuItem(menu, "scout", "SCOUT");
				AddMenuItem(menu, "mp5", "MP5");
				AddMenuItem(menu, "p90", "P90");
				AddMenuItem(menu, "ump45", "UMP45");
				AddMenuItem(menu, "tmp", "TMP");
				AddMenuItem(menu, "mac10", "MAC10");
				AddMenuItem(menu, "m3", "M3");
				AddMenuItem(menu, "xm1014", "XM1014");
				AddMenuItem(menu, "galil", "GALIL");
				AddMenuItem(menu, "famas", "FAMAS");
				AddMenuItem(menu, "deagle", "DEAGLE");
				AddMenuItem(menu, "glock", "GLOCK");
				AddMenuItem(menu, "usp", "USP");
				AddMenuItem(menu, "flash", "FLASH");
				AddMenuItem(menu, "grenade", "HE");
			}
			else if (jobid[client] == 2)
			{
				AddMenuItem(menu, "m4", "M4A1");
				AddMenuItem(menu, "ak", "AK47");
				AddMenuItem(menu, "aug", "AUG");
				AddMenuItem(menu, "scout", "SCOUT");
				AddMenuItem(menu, "mp5", "MP5");
				AddMenuItem(menu, "p90", "P90");
				AddMenuItem(menu, "ump45", "UMP45");
				AddMenuItem(menu, "tmp", "TMP");
				AddMenuItem(menu, "mac10", "MAC10");
				AddMenuItem(menu, "m3", "M3");
				AddMenuItem(menu, "xm1014", "XM1014");
				AddMenuItem(menu, "galil", "GALIL");
				AddMenuItem(menu, "famas", "FAMAS");
				AddMenuItem(menu, "deagle", "DEAGLE");
				AddMenuItem(menu, "glock", "GLOCK");
				AddMenuItem(menu, "usp", "USP");
				AddMenuItem(menu, "flash", "FLASH");
				AddMenuItem(menu, "grenade", "HE");
			}
			else if (jobid[client] == 3)
			{
				AddMenuItem(menu, "scout", "SCOUT");
				AddMenuItem(menu, "mp5", "MP5");
				AddMenuItem(menu, "p90", "P90");
				AddMenuItem(menu, "ump45", "UMP45");
				AddMenuItem(menu, "tmp", "TMP");
				AddMenuItem(menu, "mac10", "MAC10");
				AddMenuItem(menu, "m3", "M3");
				AddMenuItem(menu, "xm1014", "XM1014");
				AddMenuItem(menu, "galil", "GALIL");
				AddMenuItem(menu, "famas", "FAMAS");
				AddMenuItem(menu, "deagle", "DEAGLE");
				AddMenuItem(menu, "glock", "GLOCK");
				AddMenuItem(menu, "usp", "USP");
				AddMenuItem(menu, "flash", "FLASH");
				AddMenuItem(menu, "grenade", "HE");
			}
			else if (jobid[client] == 4)
			{
				AddMenuItem(menu, "tmp", "TMP");
				AddMenuItem(menu, "mac10", "MAC10");
				AddMenuItem(menu, "m3", "M3");
				AddMenuItem(menu, "xm1014", "XM1014");
				AddMenuItem(menu, "galil", "GALIL");
				AddMenuItem(menu, "famas", "FAMAS");
				AddMenuItem(menu, "deagle", "DEAGLE");
				AddMenuItem(menu, "glock", "GLOCK");
				AddMenuItem(menu, "usp", "USP");
				AddMenuItem(menu, "flash", "FLASH");
				AddMenuItem(menu, "grenade", "HE");
			}
			else if (jobid[client] == 5)
			{
				AddMenuItem(menu, "xm1014", "XM1014");
				AddMenuItem(menu, "galil", "GALIL");
				AddMenuItem(menu, "famas", "FAMAS");
				AddMenuItem(menu, "deagle", "DEAGLE");
				AddMenuItem(menu, "glock", "GLOCK");
				AddMenuItem(menu, "usp", "USP");
				AddMenuItem(menu, "flash", "FLASH");
				AddMenuItem(menu, "grenade", "HE");
			}
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		else
		{
			PrintToChat(client, "[RP] : Vous n'avez pas accès a cette commande.");
		}
	}
	else
	{
		PrintToChat(client, "[RP] : Vous devez être en vie pour utilisé cette commande.");
	}
}

public armu(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "awp"))
		{
			GivePlayerItem(client, "weapon_awp");
		}
		else if (StrEqual(info, "batteuse"))
		{
			GivePlayerItem(client, "weapon_m249");
		}
		else if (StrEqual(info, "m4"))
		{
			GivePlayerItem(client, "weapon_m4a1");
		}
		else if (StrEqual(info, "ak"))
		{
			GivePlayerItem(client, "weapon_ak47");
		}
		else if (StrEqual(info, "aug"))
		{
			GivePlayerItem(client, "weapon_aug");
		}
		else if (StrEqual(info, "scout"))
		{
			GivePlayerItem(client, "weapon_scout");
		}
		else if (StrEqual(info, "mp5"))
		{
			GivePlayerItem(client, "weapon_mp5navy");
		}
		else if (StrEqual(info, "p90"))
		{
			GivePlayerItem(client, "weapon_p90");
		}
		else if (StrEqual(info, "ump45"))
		{
			GivePlayerItem(client, "weapon_ump45");
		}
		else if (StrEqual(info, "tmp"))
		{
			GivePlayerItem(client, "weapon_tmp");
		}
		else if (StrEqual(info, "mac10"))
		{
			GivePlayerItem(client, "weapon_mac10");
		}
		else if (StrEqual(info, "m3"))
		{
			GivePlayerItem(client, "weapon_m3");
		}
		else if (StrEqual(info, "xm1014"))
		{
			GivePlayerItem(client, "weapon_xm1014");
		}
		else if (StrEqual(info, "galil"))
		{
			GivePlayerItem(client, "weapon_galil");
		}
		else if (StrEqual(info, "famas"))
		{
			GivePlayerItem(client, "weapon_famas");
		}
		else if (StrEqual(info, "deagle"))
		{
			GivePlayerItem(client, "weapon_deagle");
		}
		else if (StrEqual(info, "glock"))
		{
			GivePlayerItem(client, "weapon_glock");
		}
		else if (StrEqual(info, "usp"))
		{
			GivePlayerItem(client, "weapon_usp");
		}
		else if (StrEqual(info, "flash"))
		{
			GivePlayerItem(client, "weapon_flashbang");
		}
		else if (StrEqual(info, "grenade"))
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// CHANGENAME

public Action:Command_Changename(client, args)
{
	if (IsClientInGame(client))
	{
		if (jobid[client] == 1)
		{
			if (args < 1)
			{
				ReplyToCommand(client, "[RP] Usage: sm_changename <pseudo>");
				return Plugin_Handled;	
			}
			
			decl String:arg2[32];

			GetCmdArg(1, arg2, sizeof(arg2));
			
			CS_SetClientName(client, arg2, true);
		}
		else
		{
			PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
		}
	}
	return Plugin_Continue;
}

stock CS_SetClientName(client, const String:name[], bool:silent=false)
{
    decl String:oldname[MAX_NAME_LENGTH];
    GetClientName(client, oldname, sizeof(oldname));

    SetClientInfo(client, "name", name);
    SetEntPropString(client, Prop_Data, "m_szNetname", name);

    new Handle:event = CreateEvent("player_changename");

    if (event != INVALID_HANDLE)
    {
        SetEventInt(event, "userid", GetClientUserId(client));
        SetEventString(event, "oldname", oldname);
        SetEventString(event, "newname", name);
        FireEvent(event);
    }

    if (silent)
        return;
    
    new Handle:msg = StartMessageAll("SayText2");

    if (msg != INVALID_HANDLE)
    {
        BfWriteByte(msg, client);
        BfWriteByte(msg, true);
        BfWriteString(msg, "Cstrike_Name_Change");
        BfWriteString(msg, oldname);
        BfWriteString(msg, name);
        EndMessage();
    }
}

// OUT

public Action:Command_Out(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			new expulser = GetClientAimTarget(client, true);
			
			if (expulser != -1)
			{
				if (GetClientTeam(client) == 3)
				{
					if (IsInComico(client) || IsInFbi(client))
					{
						if (IsInComico(expulser) || IsInFbi(expulser))
						{
							PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, expulser);
							PrintToChat(expulser, "%s : Vous avez été expulsé par %N", LOGO, client);
							
							TeleportEntity(expulser, Float:{ -2919.616943, -1194.716064, -319.906189 }, NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, expulser);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
					}
				}
				else if (jobid[client] == 6 || jobid[client] == 7 || jobid[client] == 8)
				{
					if (IsInMafia(client))
					{
						if (IsInMafia(expulser))
						{
							PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, expulser);
							PrintToChat(expulser, "%s : Vous avez été expulsé par %N", LOGO, client);
							
							TeleportEntity(expulser, Float:{ 1131.213745, 1758.343384, -296.737701 }, NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, expulser);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
					}
				}
				else if (jobid[client] == 9 || jobid[client] == 10 || jobid[client] == 11)
				{
					if (IsInDealer(client))
					{
						if (IsInDealer(expulser))
						{
							PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, expulser);
							PrintToChat(expulser, "%s : Vous avez été expulsé par %N", LOGO, client);
							
							TeleportEntity(expulser, Float:{ -369.048096, 4084.632324, -317.956207 }, NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, expulser);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
					}
				}
				else if (jobid[client] == 12 || jobid[client] == 13 || jobid[client] == 14)
				{
					if (IsInCoach(client))
					{
						if (IsInCoach(expulser))
						{
							PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, expulser);
							PrintToChat(expulser, "%s : Vous avez été expulsé par %N", LOGO, client);
							
							TeleportEntity(expulser, Float:{ 1569.410278, 1396.601929, -262.049408 }, NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, expulser);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
					}
				}
				else if (jobid[client] == 15 || jobid[client] == 16 || jobid[client] == 17)
				{
					if (IsInEbay(client))
					{
						if (IsInEbay(expulser))
						{
							PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, expulser);
							PrintToChat(expulser, "%s : Vous avez été expulsé par %N", LOGO, client);
								
							TeleportEntity(expulser, Float:{ -4579.320801, -340.465393, -429.112518 }, NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, expulser);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
					}
				}
				else if (jobid[client] == 18 || jobid[client] == 19 || jobid[client] == 20)
				{
					if (IsInArmu(client))
					{
						if (IsInArmu(expulser))
						{
							PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, expulser);
							PrintToChat(expulser, "%s : Vous avez été expulsé par %N", LOGO, client);
					
							TeleportEntity(expulser, Float:{ -4438.507813, 1459.403442, -307.249817 }, NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, expulser);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
					}
				}
				else if (jobid[client] == 21 || jobid[client] == 22 || jobid[client] == 23)
				{
					if (IsInLoto(client))
					{
						if (IsInLoto(expulser))
						{
							PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, expulser);
							PrintToChat(expulser, "%s : Vous avez été expulsé par %N", LOGO, client);
						
							TeleportEntity(expulser, Float:{ -2763.123047, 1912.618530, -276.659943 }, NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, expulser);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
					}
				}
				else if (jobid[client] == 24 || jobid[client] == 25 || jobid[client] == 26)
				{
					if (IsInBank(client))
					{
						if (IsInBank(expulser))
						{
							PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, expulser);
							PrintToChat(expulser, "%s : Vous avez été expulsé par %N", LOGO, client);
						
							TeleportEntity(expulser, Float:{ -2132.015137, -1843.170898, -285.753479 }, NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, expulser);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
					}
				}
				else if (jobid[client] == 27 || jobid[client] == 28 || jobid[client] == 29 || jobid[client] == 30)
				{
					if (IsInHosto(client))
					{
						if (IsInHosto(expulser))
						{
							PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, expulser);
							PrintToChat(expulser, "%s : Vous avez été expulsé par %N", LOGO, client);
						
							TeleportEntity(expulser, Float:{ -1574.697876, 663.927917, -297.171783 }, NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, expulser);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
					}
				}
				else if (jobid[client] == 31 || jobid[client] == 32 || jobid[client] == 33)
				{
					if (IsInEleven(client))
					{
						if (IsInEleven(expulser))
						{
							PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, expulser);
							PrintToChat(expulser, "%s : Vous avez été expulsé par %N", LOGO, client);
						
							TeleportEntity(expulser, Float:{ -2862.270996, 1284.940063, -264.463928 }, NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, expulser);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
					}
				}
				else if (jobid[client] == 34 || jobid[client] == 35 || jobid[client] == 36)
				{
					if (IsInTueur(client))
					{
						if (IsInTueur(expulser))
						{
							PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, expulser);
							PrintToChat(expulser, "%s : Vous avez été expulsé par %N", LOGO, client);
						
							TeleportEntity(expulser, Float:{ 252.876648, -200.697433, -268.583435 }, NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, expulser);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
					}
				}
				else if (jobid[client] == 37 || jobid[client] == 38 || jobid[client] == 39)
				{
					if (IsInHotel(client))
					{
						if (IsInHotel(expulser))
						{
							PrintToChat(client, "%s : Vous avez expulsé %N.", LOGO, expulser);
							PrintToChat(expulser, "%s : Vous avez été expulsé par %N", LOGO, client);
						
							TeleportEntity(expulser, Float:{ 252.876648, -200.697433, -268.583435 }, NULL_VECTOR, NULL_VECTOR);
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N n'est pas dans votre planque.", LOGO, expulser);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'êtes pas dans votre planque.", LOGO);
					}
				}
				else if (jobid[client] == 0)
				{
					PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé un joueurs.", LOGO);
			}
		}
	}
}

// SM REBOOT

public Action:Command_ShutdownServer(client, args)
{
	if (jobid[client] == 1)
	{
		if (!reboot)
		{
			PrintToChatAll("%s :  Redémarrage du serveur dans 20 secondes.", LOGO);
			
			RebootTimer = 20;
			
			new i = 1;
			while (i < MaxClients)
			{
				if (IsClientConnected(i)) 
				{
					
					i++;
				}
				i++;
			}
			
			CreateTimer(1.0, ShutdownServer, _, TIMER_REPEAT);
			
			reboot = true;
		}
		else
		{
			PrintToChat(client, "%s : le serveur est déjà en reboot.", LOGO);
		}
	}
	else
	{
		PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
	}
	
	return Plugin_Continue;
}

public Action:ShutdownServer(Handle:timer)
{
	RebootTimer -= 1;

	PrintToChatAll("%s : Redémarrage du serveur dans %i secondes.", LOGO, RebootTimer);
	
	if (RebootTimer == 0)
	{
		RebootTimer = 0;
	
		PrintToChatAll("%s : Redémarrage en cours...", LOGO);
	
		ServerCommand("sm_plugins unload Roleplay");
		ServerCommand("exit");
	}
}

// SAVE COMMAND

public Action:Command_Save(client, args)
{
	if (jobid[client] == 1)
	{
		PrintToChatAll("%s :  Sauvegarde du serveur en cours...", LOGO);
		
		new i = 1;
		while (i < MaxClients)
		{
			if (IsClientConnected(i)) 
			{
				
				i++;
			}
			i++;
		}
	}
	else
	{
		PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
	}
	
	return Plugin_Continue;
}

// BANKICK

public Action:Command_Bankick(client, args)
{
	if (IsClientInGame(client))
	{
		new String:SteamId[32];

		GetClientAuthString(client, SteamId, sizeof(SteamId));
		
		if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		{
			ChercheJoueurs(client);
			return Plugin_Handled;
		}
		else
		{
			PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

ChercheJoueurs(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Bankick);
		SetMenuTitle(menu, "Choisis le joueur :");
		SetMenuExitButton(menu, true);
        
		Addmenu(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public Addmenu(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_Bankick(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		banni[client] = GetClientOfUserId(UserID);
		


	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// SYSTEME DE VENTE

public Action:Command_Vente(client, args) 
{ 
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client)) 
		{ 
			if (g_IsInJail[client] == 0)
			{
				new BuyerIndex = GetClientAimTarget(client, true); 
				
				if (BuyerIndex != -1)
				{
					if(BuyerIndex < 1 || BuyerIndex > MaxClients) 
					{ 
						PrintToChat(client, "%s : Tu dois visé un joueurs.", LOGO);
						return Plugin_Handled; 
					}
				
					TransactionWith[client] = BuyerIndex;
					TransactionWith[BuyerIndex] = client;
					
					new Handle:menu = CreateMenu(Menu_Vente); 
					SetMenuTitle(menu, "Choisis l'item a vendre :"); 
					if ((jobid[client] == 9) || (jobid[client] == 10) || (jobid[client] == 11))
					{
						AddMenuItem(menu, "lsd", "LSD 300$");
						AddMenuItem(menu, "exta", "EXTASY 400$");
						AddMenuItem(menu, "coke", "COKE 500$");
						AddMenuItem(menu, "heroine", "HEROINE 700$");
					}
					else if ((jobid[client] == 12) || (jobid[client] == 13) || (jobid[client] == 14))
					{
						AddMenuItem(menu, "level", "levels cut au maximum 1000$");
					}
					else if ((jobid[client] == 15) || (jobid[client] == 16) || (jobid[client] == 17))
					{
						AddMenuItem(menu, "props1", "CANAPE 1500$");
						AddMenuItem(menu, "props2", "TABLE 1000$");
					}
					else if ((jobid[client] == 18) || (jobid[client] == 19) || (jobid[client] == 20))
					{
						AddMenuItem(menu, "awp", "AWP 2500$");
						AddMenuItem(menu, "m249", "M249 1500$");
						AddMenuItem(menu, "ak47", "AK47 1500$");
						AddMenuItem(menu, "m4a1", "M4A1 1500$");
						AddMenuItem(menu, "sg550", "SG550 1300$");
						AddMenuItem(menu, "sg552", "SG552 1300$");
						AddMenuItem(menu, "galil", "GALIL 1200$");
						AddMenuItem(menu, "aug", "AUG 1000$");
						AddMenuItem(menu, "famas", "FAMAS 900$");
						AddMenuItem(menu, "scout", "SCOUT 700$");
						AddMenuItem(menu, "m3", "M3 700$");
						AddMenuItem(menu, "xm1014", "XM1014 700$");
						AddMenuItem(menu, "mp5", "MP5 600$");
						AddMenuItem(menu, "p90", "P90 600$");
						AddMenuItem(menu, "elite", "ELITES 450$");
						AddMenuItem(menu, "tmp", "TMP 500$");
						AddMenuItem(menu, "ump", "UMP 500$");
						AddMenuItem(menu, "mac10", "MAC10 400$");
						AddMenuItem(menu, "deagle", "DEAGLE 300$");
						AddMenuItem(menu, "glock", "GLOCK 100$");
						AddMenuItem(menu, "usp", "USP 100$");
						AddMenuItem(menu, "kartouche", "CARTOUCHE 150$");
						if (permisleger[BuyerIndex] == 0)
						{
							AddMenuItem(menu, "permis1", "Permis Leger 1000$");
						}
						if (permislourd[BuyerIndex] == 0)
						{
							AddMenuItem(menu, "permis2", "Permis Lourd 2000$");
						}
					}
					else if ((jobid[client] == 21) || (jobid[client] == 22) || (jobid[client] == 23))
					{
						AddMenuItem(menu, "ticketdix", "Ticket 10$");
						AddMenuItem(menu, "ticketcent", "Ticket 100$");
						AddMenuItem(menu, "ticketmille", "Ticket 1000$");
					}
					else if ((jobid[client] == 24) || (jobid[client] == 25) || (jobid[client] == 26))
					{
						if (rib[BuyerIndex] == 0)
						{
							AddMenuItem(menu, "rib", "RIB 1500$");
						}
						if (cb[BuyerIndex] == 0)
						{
							AddMenuItem(menu, "cb", "CB 1500$");
						}
					}
					else if ((jobid[client] == 27) || (jobid[client] == 28) || (jobid[client] == 29))
					{
						AddMenuItem(menu, "partiel", "Soin Partiel 100$");
						AddMenuItem(menu, "complet", "Soin Complet 300$");
					}
					else if (jobid[client] == 30)
					{
						AddMenuItem(menu, "tete", "Chirurgie du cerveau 1000$");
						AddMenuItem(menu, "coeur", "Chirurgie du coeur 800$");
						AddMenuItem(menu, "bras", "Chirurgie des bras 600$");
						AddMenuItem(menu, "jambe", "Chirurgie des jambes 400$");
					}
					else if ((jobid[client] == 31) || (jobid[client] == 32) || (jobid[client] == 33))
					{
						AddMenuItem(menu, "grenade", "Pack de grenade 1000$");
						AddMenuItem(menu, "kevlar", "Kevlar 600$");
					}
					else if (jobid[client] == 0)
					{
						PrintToChat(client, "%s : Vous n'avez pas de travail.", LOGO);
					}
					DisplayMenu(menu, client, MENU_TIME_FOREVER);
				}
			}
			else 
			{
				PrintToChat(client, "%s : Vous ne pouvez pas vendre en jail.", LOGO);
			}
		} 
		else 
		{
			PrintToChat(client, "%s : Vous devez être en vie.", LOGO);
		}
	}
	return Plugin_Continue;
} 

public Menu_Vente(Handle:menu, MenuAction:action, client, param2) 
{ 
    if (action == MenuAction_Select) 
    { 
        new buyer = TransactionWith[client]; 

        new String:info[32]; 
        GetMenuItem(menu, param2, info, sizeof(info)); 
         
        if (StrEqual(info, "usp")) 
        { 
            new Handle:menua = CreateMenu(Vente_Usp); 
            SetMenuTitle(menua, "Voulez-vous acheté un USP à 100$?"); 
            AddMenuItem(menua, "oui", "Oui je veux"); 
            AddMenuItem(menua, "non", "Non merci"); 
            DisplayMenu(menua, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "level"))
        { 
            new Handle:menub = CreateMenu(Vente_Level); 
            SetMenuTitle(menub, "Voulez-vous acheté des levels cut (100) à 1000$?"); 
            AddMenuItem(menub, "oui", "Oui je veux"); 
            AddMenuItem(menub, "non", "Non merci"); 
            DisplayMenu(menub, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "glock")) 
        { 
            new Handle:menuc = CreateMenu(Vente_Glock); 
            SetMenuTitle(menuc, "Voulez-vous acheté un glock à 100$?"); 
            AddMenuItem(menuc, "oui", "Oui je veux"); 
            AddMenuItem(menuc, "non", "Non merci"); 
            DisplayMenu(menuc, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "deagle")) 
        { 
            new Handle:menud = CreateMenu(Vente_Deagle); 
            SetMenuTitle(menud, "Voulez-vous acheté un Deagle à 300$?"); 
            AddMenuItem(menud, "oui", "Oui je veux"); 
            AddMenuItem(menud, "non", "Non merci"); 
            DisplayMenu(menud, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "kartouche")) 
        { 
            new Handle:menue = CreateMenu(Vente_Cartouche); 
            SetMenuTitle(menue, "Voulez-vous acheté  à 100$?"); 
            AddMenuItem(menue, "oui", "Oui je veux"); 
            AddMenuItem(menue, "non", "Non merci"); 
            DisplayMenu(menue, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "mac10")) 
        { 
            new Handle:menuf = CreateMenu(Vente_Mac10); 
            SetMenuTitle(menuf, "Voulez-vous acheté un Mac10 à 400$?"); 
            AddMenuItem(menuf, "oui", "Oui je veux"); 
            AddMenuItem(menuf, "non", "Non merci"); 
            DisplayMenu(menuf, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "ump")) 
        { 
            new Handle:menug = CreateMenu(Vente_Ump); 
            SetMenuTitle(menug, "Voulez-vous acheté un Ump à 500$?"); 
            AddMenuItem(menug, "oui", "Oui je veux"); 
            AddMenuItem(menug, "non", "Non merci"); 
            DisplayMenu(menug, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "tmp")) 
        { 
            new Handle:menuh = CreateMenu(Vente_Tmp); 
            SetMenuTitle(menuh, "Voulez-vous acheté un Tmp à 500$?"); 
            AddMenuItem(menuh, "oui", "Oui je veux"); 
            AddMenuItem(menuh, "non", "Non merci"); 
            DisplayMenu(menuh, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "elite")) 
        { 
            new Handle:menui = CreateMenu(Vente_Elite); 
            SetMenuTitle(menui, "Voulez-vous acheté des élites à 450$?"); 
            AddMenuItem(menui, "oui", "Oui je veux"); 
            AddMenuItem(menui, "non", "Non merci"); 
            DisplayMenu(menui, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "p90")) 
        { 
            new Handle:menuj = CreateMenu(Vente_P90); 
            SetMenuTitle(menuj, "Voulez-vous acheté un P90 à 600$?"); 
            AddMenuItem(menuj, "oui", "Oui je veux"); 
            AddMenuItem(menuj, "non", "Non merci"); 
            DisplayMenu(menuj, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "mp5")) 
        { 
            new Handle:menuk = CreateMenu(Vente_Mp5); 
            SetMenuTitle(menuk, "Voulez-vous acheté un Mp5 à 600$?"); 
            AddMenuItem(menuk, "oui", "Oui je veux"); 
            AddMenuItem(menuk, "non", "Non merci"); 
            DisplayMenu(menuk, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "xm1014")) 
        { 
            new Handle:menul = CreateMenu(Vente_Xm1014); 
            SetMenuTitle(menul, "Voulez-vous acheté un Xm1014 à 700$?"); 
            AddMenuItem(menul, "oui", "Oui je veux"); 
            AddMenuItem(menul, "non", "Non merci"); 
            DisplayMenu(menul, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "m3")) 
        { 
            new Handle:menum = CreateMenu(Vente_M3); 
            SetMenuTitle(menum, "Voulez-vous acheté un M3 à 700$?"); 
            AddMenuItem(menum, "oui", "Oui je veux"); 
            AddMenuItem(menum, "non", "Non merci"); 
            DisplayMenu(menum, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "scout")) 
        { 
            new Handle:menun = CreateMenu(Vente_Scout); 
            SetMenuTitle(menun, "Voulez-vous acheté Scout à 700$?"); 
            AddMenuItem(menun, "oui", "Oui je veux"); 
            AddMenuItem(menun, "non", "Non merci"); 
            DisplayMenu(menun, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "famas")) 
        { 
            new Handle:menuo = CreateMenu(Vente_Famas); 
            SetMenuTitle(menuo, "Voulez-vous acheté un Famas à 900$?"); 
            AddMenuItem(menuo, "oui", "Oui je veux"); 
            AddMenuItem(menuo, "non", "Non merci"); 
            DisplayMenu(menuo, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "aug")) 
        { 
            new Handle:menup = CreateMenu(Vente_Aug); 
            SetMenuTitle(menup, "Voulez-vous acheté un Aug à 1000$?"); 
            AddMenuItem(menup, "oui", "Oui je veux"); 
            AddMenuItem(menup, "non", "Non merci"); 
            DisplayMenu(menup, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "galil")) 
        { 
            new Handle:menuq = CreateMenu(Vente_Galil); 
            SetMenuTitle(menuq, "Voulez-vous acheté un Galil à 1200$?"); 
            AddMenuItem(menuq, "oui", "Oui je veux"); 
            AddMenuItem(menuq, "non", "Non merci"); 
            DisplayMenu(menuq, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "sg550")) 
        { 
            new Handle:menur = CreateMenu(Vente_Sg550); 
            SetMenuTitle(menur, "Voulez-vous acheté un Sg550 à 1300$?"); 
            AddMenuItem(menur, "oui", "Oui je veux"); 
            AddMenuItem(menur, "non", "Non merci"); 
            DisplayMenu(menur, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "sg552")) 
        { 
            new Handle:menus = CreateMenu(Vente_Sg552); 
            SetMenuTitle(menus, "Voulez-vous acheté un Sg552 à 1300$?"); 
            AddMenuItem(menus, "oui", "Oui je veux"); 
            AddMenuItem(menus, "non", "Non merci"); 
            DisplayMenu(menus, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "m4a1")) 
        { 
            new Handle:menut = CreateMenu(Vente_M4a1); 
            SetMenuTitle(menut, "Voulez-vous acheté un M4a1 à 1500$?"); 
            AddMenuItem(menut, "oui", "Oui je veux"); 
            AddMenuItem(menut, "non", "Non merci"); 
            DisplayMenu(menut, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "ak47")) 
        { 
            new Handle:menuu = CreateMenu(Vente_Ak47); 
            SetMenuTitle(menuu, "Voulez-vous acheté un Ak47 à 1500$?"); 
            AddMenuItem(menuu, "oui", "Oui je veux"); 
            AddMenuItem(menuu, "non", "Non merci"); 
            DisplayMenu(menuu, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "m249")) 
        { 
            new Handle:menuv = CreateMenu(Vente_M249); 
            SetMenuTitle(menuv, "Voulez-vous acheté un M249 à 1500$?"); 
            AddMenuItem(menuv, "oui", "Oui je veux"); 
            AddMenuItem(menuv, "non", "Non merci"); 
            DisplayMenu(menuv, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "awp")) 
        { 
            new Handle:menuw = CreateMenu(Vente_Awp); 
            SetMenuTitle(menuw, "Voulez-vous acheté un Awp à 2500$?"); 
            AddMenuItem(menuw, "oui", "Oui je veux"); 
            AddMenuItem(menuw, "non", "Non merci"); 
            DisplayMenu(menuw, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "ticketdix")) 
        { 
            new Handle:menuabc = CreateMenu(Vente_Ticket10); 
            SetMenuTitle(menuabc, "Voulez-vous acheté un ticket à 10$?"); 
            AddMenuItem(menuabc, "oui", "Oui je veux"); 
            AddMenuItem(menuabc, "non", "Non merci"); 
            DisplayMenu(menuabc, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "ticketcent")) 
        { 
            new Handle:menuabcd = CreateMenu(Vente_Ticket100); 
            SetMenuTitle(menuabcd, "Voulez-vous acheté un ticket à 100$?"); 
            AddMenuItem(menuabcd, "oui", "Oui je veux"); 
            AddMenuItem(menuabcd, "non", "Non merci"); 
            DisplayMenu(menuabcd, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "ticketmille")) 
        { 
            new Handle:menuabcde = CreateMenu(Vente_Ticket1000); 
            SetMenuTitle(menuabcde, "Voulez-vous acheté un ticket à 1000$?"); 
            AddMenuItem(menuabcde, "oui", "Oui je veux"); 
            AddMenuItem(menuabcde, "non", "Non merci"); 
            DisplayMenu(menuabcde, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "props1")) 
        { 
            new Handle:menuab = CreateMenu(Vente_Usp); 
            SetMenuTitle(menuab, "Voulez-vous un Canapé à 1500$?"); 
            AddMenuItem(menuab, "oui", "Oui je veux"); 
            AddMenuItem(menuab, "non", "Non merci"); 
            DisplayMenu(menuab, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "props2")) 
        { 
            new Handle:menuac = CreateMenu(Vente_Usp); 
            SetMenuTitle(menuac, "Voulez-vous acheté une Table à 1000$?"); 
            AddMenuItem(menuac, "oui", "Oui je veux"); 
            AddMenuItem(menuac, "non", "Non merci"); 
            DisplayMenu(menuac, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "lsd")) 
        { 
            new Handle:menuaf = CreateMenu(Vente_Lsd); 
            SetMenuTitle(menuaf, "Voulez-vous acheté du Lsd à 300$?"); 
            AddMenuItem(menuaf, "oui", "Oui je veux"); 
            AddMenuItem(menuaf, "non", "Non merci"); 
            DisplayMenu(menuaf, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "exta")) 
        { 
            new Handle:menuag = CreateMenu(Vente_Exta); 
            SetMenuTitle(menuag, "Voulez-vous acheté de l'Extasie à 400$?"); 
            AddMenuItem(menuag, "oui", "Oui je veux"); 
            AddMenuItem(menuag, "non", "Non merci"); 
            DisplayMenu(menuag, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "coke")) 
        { 
            new Handle:menuah = CreateMenu(Vente_Coke); 
            SetMenuTitle(menuah, "Voulez-vous acheté de la Coke à 500$?"); 
            AddMenuItem(menuah, "oui", "Oui je veux"); 
            AddMenuItem(menuah, "non", "Non merci"); 
            DisplayMenu(menuah, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "heroine")) 
        { 
            new Handle:menuai = CreateMenu(Vente_Heroine); 
            SetMenuTitle(menuai, "Voulez-vous acheté une Héroine à 700$?"); 
            AddMenuItem(menuai, "oui", "Oui je veux"); 
            AddMenuItem(menuai, "non", "Non merci"); 
            DisplayMenu(menuai, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "rib")) 
        { 
            new Handle:menuah = CreateMenu(Vente_Rib); 
            SetMenuTitle(menuah, "Voulez-vous acheté un Rib à 1500$?"); 
            AddMenuItem(menuah, "oui", "Oui je veux"); 
            AddMenuItem(menuah, "non", "Non merci"); 
            DisplayMenu(menuah, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "cb")) 
        { 
            new Handle:menuai = CreateMenu(Vente_Cb); 
            SetMenuTitle(menuai, "Voulez-vous acheté une Carte Bleue à 1500$?"); 
            AddMenuItem(menuai, "oui", "Oui je veux"); 
            AddMenuItem(menuai, "non", "Non merci"); 
            DisplayMenu(menuai, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "permis1")) 
        { 
            new Handle:menuah = CreateMenu(Vente_Permis1); 
            SetMenuTitle(menuah, "Voulez-vous acheté un Permis leger à 1000$?"); 
            AddMenuItem(menuah, "oui", "Oui je veux"); 
            AddMenuItem(menuah, "non", "Non merci"); 
            DisplayMenu(menuah, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "permis2")) 
        { 
            new Handle:menuai = CreateMenu(Vente_Permis2); 
            SetMenuTitle(menuai, "Voulez-vous acheté un Permis lourd à 2000$?"); 
            AddMenuItem(menuai, "oui", "Oui je veux"); 
            AddMenuItem(menuai, "non", "Non merci"); 
            DisplayMenu(menuai, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "partiel")) 
        { 
            new Handle:menuai = CreateMenu(Vente_Partiel); 
            SetMenuTitle(menuai, "Voulez-vous acheté un Soin partiel à 100$?"); 
            AddMenuItem(menuai, "oui", "Oui je veux"); 
            AddMenuItem(menuai, "non", "Non merci"); 
            DisplayMenu(menuai, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "complet")) 
        { 
            new Handle:menuai = CreateMenu(Vente_Complet); 
            SetMenuTitle(menuai, "Voulez-vous acheté un Soin complet à 300$?"); 
            AddMenuItem(menuai, "oui", "Oui je veux"); 
            AddMenuItem(menuai, "non", "Non merci"); 
            DisplayMenu(menuai, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "tete")) 
        { 
            new Handle:menuai = CreateMenu(Vente_Tete); 
            SetMenuTitle(menuai, "Voulez-vous acheté une Chirurgie de la tête à 1000$?"); 
            AddMenuItem(menuai, "oui", "Oui je veux"); 
            AddMenuItem(menuai, "non", "Non merci"); 
            DisplayMenu(menuai, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "coeur")) 
        { 
            new Handle:menuai = CreateMenu(Vente_Coeur); 
            SetMenuTitle(menuai, "Voulez-vous acheté une Chirurgie coeur à 800$?"); 
            AddMenuItem(menuai, "oui", "Oui je veux"); 
            AddMenuItem(menuai, "non", "Non merci"); 
            DisplayMenu(menuai, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "bras")) 
        { 
            new Handle:menuai = CreateMenu(Vente_Bras); 
            SetMenuTitle(menuai, "Voulez-vous acheté une Chirurgie des bras à 600$?"); 
            AddMenuItem(menuai, "oui", "Oui je veux"); 
            AddMenuItem(menuai, "non", "Non merci"); 
            DisplayMenu(menuai, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "jambe")) 
        { 
            new Handle:menuai = CreateMenu(Vente_Jambe); 
            SetMenuTitle(menuai, "Voulez-vous acheté une Chirurgie des jambes à 400$?"); 
            AddMenuItem(menuai, "oui", "Oui je veux"); 
            AddMenuItem(menuai, "non", "Non merci"); 
            DisplayMenu(menuai, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "grenade")) 
        { 
            new Handle:menuai = CreateMenu(Vente_Grenade); 
            SetMenuTitle(menuai, "Voulez-vous acheté un Pack de grenade 1000$?"); 
            AddMenuItem(menuai, "oui", "Oui je veux"); 
            AddMenuItem(menuai, "non", "Non merci"); 
            DisplayMenu(menuai, buyer, MENU_TIME_FOREVER);
        } 
		else if (StrEqual(info, "kevlar")) 
        { 
            new Handle:menuai = CreateMenu(Vente_Kevlar); 
            SetMenuTitle(menuai, "Voulez-vous acheté un Gilet pare-balle à 600$?"); 
            AddMenuItem(menuai, "oui", "Oui je veux"); 
            AddMenuItem(menuai, "non", "Non merci"); 
            DisplayMenu(menuai, buyer, MENU_TIME_FOREVER);
        } 
    } 
    else if (action == MenuAction_End) 
    { 
		CloseHandle(menu); 
    } 
} 

public Vente_Grenade(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 

		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1000)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1000;
				AdCash(TransactionWith[client], 500);
				pack[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1000)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1000;
						AdCash(TransactionWith[client], 500);
						pack[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Kevlar(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 600)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 600;
				AdCash(TransactionWith[client], 300);
				kevlar[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 300;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 600)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 600;
						AdCash(TransactionWith[client], 300);
						kevlar[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Partiel(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 

		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		new health;
		
		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 100)
			{
				health = GetClientHealth(client);
				
				if (GetClientTeam(client) == 2)
				{
					if (health < 100)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						money[client] = money[client] - 100;
						AdCash(TransactionWith[client], 100);
						
						SetEntityHealth(client, health + 50);
						
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 50;
						
						SetEntData(client, MoneyOffset, money[client], 4, true);
					}
					else
					{
						PrintToChat(client, "%s : Vous avez déjà votre vie.", LOGO);
					}
				}
				else if (GetClientTeam(client) == 3)
				{
					if (health < 500)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						money[client] = money[client] - 100;
						AdCash(TransactionWith[client], 100);
						
						SetEntityHealth(client, health + 50);
						
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 50;
						
						SetEntData(client, MoneyOffset, money[client], 4, true);
					}
					else
					{
						PrintToChat(client, "%s : Vous avez déjà votre vie.", LOGO);
					}
				}
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 100)
					{
						health = GetClientHealth(client);
				
						if (GetClientTeam(client) == 2)
						{
							if (health < 100)
							{
								PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
								PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
								money[client] = money[client] - 100;
								AdCash(TransactionWith[client], 100);
								
								SetEntityHealth(client, health + 50);
								
								capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 50;
								
								SetEntData(client, MoneyOffset, money[client], 4, true);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez déjà votre vie.", LOGO);
							}
						}
						else if (GetClientTeam(client) == 3)
						{
							if (health < 500)
							{
								PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
								PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
								money[client] = money[client] - 100;
								AdCash(TransactionWith[client], 100);
								
								SetEntityHealth(client, health + 50);
								
								capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 50;
								
								SetEntData(client, MoneyOffset, money[client], 4, true);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez déjà votre vie.", LOGO);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Complet(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 

		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new health;

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 300)
			{
				health = GetClientHealth(client);
				
				if (GetClientTeam(client) == 2)
				{
					if (health < 100)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						money[client] = money[client] - 300;
						AdCash(TransactionWith[client], 300);
						
						SetEntityHealth(client, health + 100);
						
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 150;
						
						SetEntData(client, MoneyOffset, money[client], 4, true);
					}
					else
					{
						PrintToChat(client, "%s : Vous avez déjà votre vie.", LOGO);
					}
				}
				else if (GetClientTeam(client) == 3)
				{
					if (health < 500)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						money[client] = money[client] - 300;
						AdCash(TransactionWith[client], 300);
						
						SetEntityHealth(client, health + 100);
						
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 150;
						
						SetEntData(client, MoneyOffset, money[client], 4, true);
					}
					else
					{
						PrintToChat(client, "%s : Vous avez déjà votre vie.", LOGO);
					}
				}
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 100)
					{
						health = GetClientHealth(client);
				
						if (GetClientTeam(client) == 2)
						{
							if (health < 100)
							{
								PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
								PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
								money[client] = money[client] - 300;
								AdCash(TransactionWith[client], 300);
								
								SetEntityHealth(client, health + 100);
								
								capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 150;
								
								SetEntData(client, MoneyOffset, money[client], 4, true);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez déjà votre vie.", LOGO);
							}
						}
						else if (GetClientTeam(client) == 3)
						{
							if (health < 500)
							{
								PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
								PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
								money[client] = money[client] - 300;
								AdCash(TransactionWith[client], 300);
								
								SetEntityHealth(client, health + 100);
								
								capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 150;
								
								SetEntData(client, MoneyOffset, money[client], 4, true);
							}
							else
							{
								PrintToChat(client, "%s : Vous avez déjà votre vie.", LOGO);
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Tete(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 

		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1000)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1000;
				AdCash(TransactionWith[client], 500);
		
				SetEntityGravity(client, 0.5);
				
				ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
				
				if (!g_chirurgie[client])
				{
					CreateTimer(10.0, StopEffect, client);
				}
				
				g_chirurgie[client] = true;
		
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
		
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1000)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						money[client] = money[client] - 1000;
						AdCash(TransactionWith[client], 500);
			
						SetEntityGravity(client, 0.5);
						
						ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
						
						g_chirurgie[client] = true;
						
						if (!g_chirurgie[client])
						{
							CreateTimer(10.0, StopEffect, client);
						}
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
				
						SetEntData(client, MoneyOffset, money[client], 4, true);
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Coeur(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 

		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new health;

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 800)
			{
				health = GetClientHealth(client);
			
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 800;
				AdCash(TransactionWith[client], 400);
		
				SetEntityHealth(client, health + 300);
				
				g_chirurgie[client] = true;
				
				ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
				
				if (!g_chirurgie[client])
				{
					CreateTimer(10.0, StopEffect, client);
				}
		
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 400;
		
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 800)
					{
						health = GetClientHealth(client);

						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						money[client] = money[client] - 800;
						AdCash(TransactionWith[client], 400);
			
						SetEntityHealth(client, health + 300);
						
						ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
						
						g_chirurgie[client] = true;
						
						if (!g_chirurgie[client])
						{
							CreateTimer(10.0, StopEffect, client);
						}
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 400;
				
						SetEntData(client, MoneyOffset, money[client], 4, true);
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Bras(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 

		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 600)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 600;
				AdCash(TransactionWith[client], 300);
		
				SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
				
				g_chirurgie[client] = true;
				
				ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
				
				if (!g_chirurgie[client])
				{
					CreateTimer(10.0, StopEffect, client);
				}
		
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 300;
		
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 600)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						money[client] = money[client] - 600;
						AdCash(TransactionWith[client], 300);
			
						SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
						
						g_chirurgie[client] = true;
						
						ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
						
						if (!g_chirurgie[client])
						{
							CreateTimer(10.0, StopEffect, client);
						}
						
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 300;
				
						SetEntData(client, MoneyOffset, money[client], 4, true);
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Jambe(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 

		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 400)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 400;
				AdCash(TransactionWith[client], 200);
		
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.6);
				
				g_chirurgie[client] = true;
		
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 200;
				
				ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
				
				if (!g_chirurgie[client])
				{
					CreateTimer(10.0, StopEffect, client);
				}
		
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 400)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						money[client] = money[client] - 400;
						AdCash(TransactionWith[client], 200);
			
						SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.6);
						
						ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
						
						g_chirurgie[client] = true;
						
						if (!g_chirurgie[client])
						{
							CreateTimer(10.0, StopEffect, client);
						}
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 200;
				
						SetEntData(client, MoneyOffset, money[client], 4, true);
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Usp(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 100)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 100;
				AdCash(TransactionWith[client], 100);
				usp[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 50;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 100)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 100;
						AdCash(TransactionWith[client], 100);
						usp[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 50;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Glock(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 100)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 100;
				AdCash(TransactionWith[client], 100);
				glock[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 50;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 100)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 100;
						AdCash(TransactionWith[client], 100);
						glock[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 50;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	}
} 

public Vente_Level(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1000)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1000;
				AdCash(TransactionWith[client], 1000);
				levelcut[client] = 100;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1000)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1000;
						AdCash(TransactionWith[client], 1000);
						levelcut[client] = 100;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Deagle(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 300)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 300;
				AdCash(TransactionWith[client], 300);
				deagle[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 150;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 300)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 300;
						AdCash(TransactionWith[client], 300);
						deagle[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 150;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Cartouche(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 100)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 100;
				AdCash(TransactionWith[client], 100);
				cartouche[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 50;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 100)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 100;
						AdCash(TransactionWith[client], 100);
						cartouche[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 50;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Mac10(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 400)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 400;
				AdCash(TransactionWith[client], 400);
				mac10[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 200;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 400)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 400;
						AdCash(TransactionWith[client], 400);
						mac10[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 200;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu);  
	} 
} 

public Vente_Ump(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 500)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 500;
				AdCash(TransactionWith[client], 500);
				ump[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 250;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 500)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 500;
						AdCash(TransactionWith[client], 500);
						ump[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 250;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Tmp(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 500)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 500;
				AdCash(TransactionWith[client], 500);
				tmp[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 250;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 500)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 500;
						AdCash(TransactionWith[client], 500);
						tmp[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 250;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Elite(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 450)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 450;
				AdCash(TransactionWith[client], 450);
				elite[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 225;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 450)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 450;
						AdCash(TransactionWith[client], 450);
						elite[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 225;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}  
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_P90(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 600)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 600;
				AdCash(TransactionWith[client], 600);
				p90[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 300;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 600)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 600;
						AdCash(TransactionWith[client], 600);
						p90[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 300;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Mp5(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 600)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 600;
				AdCash(TransactionWith[client], 600);
				mp5[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 300;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 600)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 600;
						AdCash(TransactionWith[client], 600);
						mp5[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 300;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Xm1014(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 700)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 700;
				AdCash(TransactionWith[client], 700);
				xm1014[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 350;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 700)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 700;
						AdCash(TransactionWith[client], 700);
						xm1014[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 350;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}  
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_M3(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 700)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 700;
				AdCash(TransactionWith[client], 700);
				m3[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 350;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 700)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 700;
						AdCash(TransactionWith[client], 700);
						m3[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 350;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Scout(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 700)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 700;
				AdCash(TransactionWith[client], 700);
				scout[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 350;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 700)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 700;
						AdCash(TransactionWith[client], 700);
						scout[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 350;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu);  
	} 
} 

public Vente_Aug(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1000)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1000;
				AdCash(TransactionWith[client], 1000);
				aug[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1000)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1000;
						AdCash(TransactionWith[client], 1000);
						aug[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Famas(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 900)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 900;
				AdCash(TransactionWith[client], 900);
				famas[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 450;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 900)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 900;
						AdCash(TransactionWith[client], 900);
						famas[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 450;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Galil(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1200)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1200;
				AdCash(TransactionWith[client], 1200);
				galil[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 600;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1200)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1200;
						AdCash(TransactionWith[client], 1200);
						galil[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 600;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Sg550(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1300)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1300;
				AdCash(TransactionWith[client], 1300);
				sg550[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 650;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1300)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1300;
						AdCash(TransactionWith[client], 1300);
						sg550[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 650;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Sg552(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1300)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1300;
				AdCash(TransactionWith[client], 1300);
				sg552[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 650;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1300)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1300;
						AdCash(TransactionWith[client], 1300);
						sg552[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 650;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_M4a1(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1500)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1500;
				AdCash(TransactionWith[client], 1500);
				m4a1[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 750;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1500)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1500;
						AdCash(TransactionWith[client], 1500);
						m4a1[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 750;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Ak47(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1500)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1500;
				AdCash(TransactionWith[client], 1500);
				ak47[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 750;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1500)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1500;
						AdCash(TransactionWith[client], 1500);
						ak47[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 750;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_M249(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1500)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1500;
				AdCash(TransactionWith[client], 1500);
				m249[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 750;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1500)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1500;
						AdCash(TransactionWith[client], 1500);
						m249[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 750;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Awp(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 2500)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 2500;
				AdCash(TransactionWith[client], 2500);
				awp[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 1250;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 2500)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 2500;
						AdCash(TransactionWith[client], 2500);
						awp[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 1250;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Permis1(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1000)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1000;
				AdCash(TransactionWith[client], 500);
				permisleger[client] = 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1000)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1000;
						AdCash(TransactionWith[client], 500);
						permisleger[client] = 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Permis2(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 2000)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 2000;
				AdCash(TransactionWith[client], 1000);
				permislourd[client] = 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 1000;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 2000)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 2000;
						AdCash(TransactionWith[client], 1000);
						permislourd[client] = 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 1000;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Ticket10(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 10)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 10;
				AdCash(TransactionWith[client], 10);
				ticket10[client] = ticket10[client] + 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 10;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 10)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 10;
						AdCash(TransactionWith[client], 10);
						ticket10[client] = ticket10[client] + 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 10;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Ticket100(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 100)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 100;
				AdCash(TransactionWith[client], 50);
				ticket100[client] = ticket100[client] + 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 50;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 100)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 100;
						AdCash(TransactionWith[client], 50);
						ticket100[client] = ticket100[client] + 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 50;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Ticket1000(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1000)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1000;
				AdCash(TransactionWith[client], 1000);
				ticket1000[client] = ticket1000[client] + 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 1000;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1000)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1000;
						AdCash(TransactionWith[client], 500);
						ticket1000[client] = ticket1000[client] + 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu);  
	} 
} 

public Vente_Props1(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1500)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1500;
				AdCash(TransactionWith[client], 1500);
				props1[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 750;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1500)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1500;
						AdCash(TransactionWith[client], 1500);
						props1[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 750;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Props2(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1000)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1000;
				AdCash(TransactionWith[client], 1000);
				props2[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1000)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 1000;
						AdCash(TransactionWith[client], 1000);
						props2[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 500;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Lsd(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 300)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 300;
				AdCash(TransactionWith[client], 150);
				lsd[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 150;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 300)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 300;
						AdCash(TransactionWith[client], 150);
						lsd[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 150;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Exta(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 400)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 400;
				AdCash(TransactionWith[client], 200);
				exta[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 200;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 400)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 400;
						AdCash(TransactionWith[client], 200);
						exta[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 200;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Coke(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 500)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 500;
				AdCash(TransactionWith[client], 250);
				coke[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 250;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 500)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 500;
						AdCash(TransactionWith[client], 250);
						coke[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 250;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Heroine(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 700)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 700;
				AdCash(TransactionWith[client], 350);
				heroine[client] += 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 350;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 700)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						bank[client] = bank[client] - 700;
						AdCash(TransactionWith[client], 350);
						heroine[client] += 1;
				
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 350;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Rib(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (bank[client] >= 1500)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				bank[client] = bank[client] - 1500;
				AdCash(TransactionWith[client], 750);
				rib[client] = 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 750;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Vente_Cb(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 
			
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (StrEqual(info, "oui")) 
		{ 
			if (bank[client] >= 1500)
			{
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				bank[client] = bank[client] - 1500;
				AdCash(TransactionWith[client], 750);
				cb[client] = 1;
				
				capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 750;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO); 
			}
			
		} 
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	} 
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	} 
} 

public Action:StopEffect(Handle:timer, any:client)
{
	ClientCommand(client, "r_screenoverlay 0");
	PrintToChat(client, "%s : Votre effet de chirurgie est terminé.", LOGO);
	
	g_chirurgie[client] = false;
}

// GRAB CODE

public Action:Command_Grab(client, args)
{ 
	if (!IsPlayerAlive(client) || !IsClientInGame(client) || (client < 0) || (client > MaxClients))
		return Plugin_Handled;
		
	if (g_IsInJail[client] == 0)
	{
		if (grab[client])
		{
			gObj[client] = -1;
			grab[client] = false;
			return Plugin_Handled;
		}
	  
		new ent = TraceToEntity(client);
	  
		new String:edictname[128];
		GetEdictClassname(ent, edictname, 128);
		
		if (gObj[client] == ent)
		{
			if (grab[client])
			{
				gObj[client] = -1;
				grab[client] = false;
			}
			else
			{
				PrintToChat(client, "%s : Vous portez aucun objet | personne.", LOGO);
			}
			return Plugin_Handled;
		}
		else
		{
			if (!grab[client])
			{
				if (StrEqual(edictname, "prop_physics"))
				{
					gObj[client] = ent;
					grab[client] = true;
				}
				else if(StrEqual(edictname, "player"))
				{
					if ((GetClientTeam(client) == 3) || jobid[client] == 6 || jobid[client] == 9 || jobid[client] == 12 || jobid[client] == 15 || jobid[client] == 18 || jobid[client] == 21 || jobid[client] == 24 || jobid[client] == 27 || jobid[client] == 31 || jobid[client] == 34 || jobid[client] == 37)
					{
						if (GetClientTeam(ent) == 3 && GetClientTeam(client) == 2)
						{
							PrintToChat(client, "%s : Vous ne pouvez pas porté un policier", LOGO);
							return Plugin_Handled;
						}
						else
						{
							if (jobid[client] == 6)
							{
								if (IsInMafia(client))
								{
									if (IsInMafia(ent))
									{
										gObj[client] = ent;
										grab[client] = true;
									}
									else
									{
										PrintToChat(client, "%s : le joueur ciblé est pas dans votre planque.", LOGO);
									}
								}
								else
								{
									PrintToChat(client, "%s : Vous pouvez porté un joueur que dans votre planque.", LOGO);
								}
							}
							else if (jobid[client] == 9)
							{
								if (IsInDealer(client))
								{
									if (IsInDealer(ent))
									{
										gObj[client] = ent;
										grab[client] = true;
									}
									else
									{
										PrintToChat(client, "%s : le joueur ciblé est pas dans votre planque.", LOGO);
									}
								}
								else
								{
									PrintToChat(client, "%s : Vous pouvez porté un joueur que dans votre planque.", LOGO);
								}
							}
							else if (jobid[client] == 12)
							{
								if (IsInCoach(client))
								{
									if (IsInCoach(ent))
									{
										gObj[client] = ent;
										grab[client] = true;
									}
									else
									{
										PrintToChat(client, "%s : le joueur ciblé est pas dans votre planque.", LOGO);
									}
								}
								else
								{
									PrintToChat(client, "%s : Vous pouvez porté un joueur que dans votre planque.", LOGO);
								}
							}
							else if (jobid[client] == 15)
							{
								if (IsInEbay(client))
								{
									if (IsInEbay(ent))
									{
										gObj[client] = ent;
										grab[client] = true;
									}
									else
									{
										PrintToChat(client, "%s : le joueur ciblé est pas dans votre planque.", LOGO);
									}
								}
								else
								{
									PrintToChat(client, "%s : Vous pouvez porté un joueur que dans votre planque.", LOGO);
								}
							}
							else if (jobid[client] == 18)
							{
								if (IsInArmu(client))
								{
									if (IsInArmu(ent))
									{
										gObj[client] = ent;
										grab[client] = true;
									}
									else
									{
										PrintToChat(client, "%s : le joueur ciblé est pas dans votre planque.", LOGO);
									}
								}
								else
								{
									PrintToChat(client, "%s : Vous pouvez porté un joueur que dans votre planque.", LOGO);
								}
							}
							else if (jobid[client] == 21)
							{
								if (IsInLoto(client))
								{
									if (IsInLoto(ent))
									{
										gObj[client] = ent;
										grab[client] = true;
									}
									else
									{
										PrintToChat(client, "%s : le joueur ciblé est pas dans votre planque.", LOGO);
									}
								}
								else
								{
									PrintToChat(client, "%s : Vous pouvez porté un joueur que dans votre planque.", LOGO);
								}
							}
							else if (jobid[client] == 24)
							{
								if (IsInBank(client))
								{
									if (IsInBank(ent))
									{
										gObj[client] = ent;
										grab[client] = true;
									}
									else
									{
										PrintToChat(client, "%s : le joueur ciblé est pas dans votre planque.", LOGO);
									}
								}
								else
								{
									PrintToChat(client, "%s : Vous pouvez porté un joueur que dans votre planque.", LOGO);
								}
							}
							else if (jobid[client] == 27)
							{
								if (IsInHosto(client))
								{
									if (IsInHosto(ent))
									{
										gObj[client] = ent;
										grab[client] = true;
									}
									else
									{
										PrintToChat(client, "%s : le joueur ciblé est pas dans votre planque.", LOGO);
									}
								}
								else
								{
									PrintToChat(client, "%s : Vous pouvez porté un joueur que dans votre planque.", LOGO);
								}
							}
							else if (jobid[client] == 31)
							{
								if (IsInEleven(client))
								{
									if (IsInEleven(ent))
									{
										gObj[client] = ent;
										grab[client] = true;
									}
									else
									{
										PrintToChat(client, "%s : le joueur ciblé est pas dans votre planque.", LOGO);
									}
								}
								else
								{
									PrintToChat(client, "%s : Vous pouvez porté un joueur que dans votre planque.", LOGO);
								}
							}
							else if (jobid[client] == 34)
							{
								if (IsInTueur(client))
								{
									if (IsInTueur(ent))
									{
										gObj[client] = ent;
										grab[client] = true;
									}
									else
									{
										PrintToChat(client, "%s : le joueur ciblé est pas dans votre planque.", LOGO);
									}
								}
								else
								{
									PrintToChat(client, "%s : Vous pouvez porté un joueur que dans votre planque.", LOGO);
								}
							}
							else if (jobid[client] == 37)
							{
								if (IsInHotel(client))
								{
									if (IsInHotel(ent))
									{
										gObj[client] = ent;
										grab[client] = true;
									}
									else
									{
										PrintToChat(client, "%s : le joueur ciblé est pas dans votre planque.", LOGO);
									}
								}
								else
								{
									PrintToChat(client, "%s : Vous pouvez porté un joueur que dans votre planque.", LOGO);
								}
							}
							else if (GetClientTeam(client) == 3)
							{
								gObj[client] = ent;
								grab[client] = true;
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous ne pouvez pas porté un joueurs.", LOGO);
					}
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous portez déjà quelque chose.", LOGO);
			}
		}
	}
	else
	{
		PrintToChat(client, "%s : Vous ne pouvez pas porté en jail.", LOGO);
	}
	return Plugin_Handled;
}

public Action:UpdateObjects(Handle:timer)
{
	new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];
	new Float:viewang[3];
	new i;
	for (i=0; i<MAX_PLAYERS; i++)
	{
		if (gObj[i]>0)
		{
			if (IsValidEdict(gObj[i]) && IsValidEntity(gObj[i]))
			{
				GetClientEyeAngles(i, viewang);
				GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
				GetClientEyePosition(i, vecPos);
				
				vecPos[0]+=vecDir[0]*100;
				vecPos[1]+=vecDir[1]*100;
				vecPos[2]+=vecDir[2]*100;
				
				GetEntPropVector(gObj[i], Prop_Send, "m_vecOrigin", vecDir);
				
				SubtractVectors(vecPos, vecDir, vecVel);
				ScaleVector(vecVel, 10.0);
				
				TeleportEntity(gObj[i], NULL_VECTOR, NULL_VECTOR, vecVel);
			}
			else
			{
				gObj[i]=-1;
			}
		}
	}
	return Plugin_Continue;
}

public TraceToEntity(client)
{
	new Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);
	
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	
	if (TR_DidHit(INVALID_HANDLE))
	{
		new TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
		return TRIndex;
	}
	return -1;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data)
	{
		return false;
	}
	return true;
}

// VIRER

public Action:Command_Virer(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if ((jobid[client] == 6))
			{
				Showmafia(client);
			}
			else if (jobid[client] == 9)
			{
				ShowDealer(client);
			}
			else if (jobid[client] == 12)
			{
				ShowCoach(client);
			}
			else if (jobid[client] == 15)
			{
				ShowEbay(client);
			}
			else if (jobid[client] == 18)
			{
				ShowArmurie(client);
			}
			else if (jobid[client] == 21)
			{
				ShowLoto(client);
			}
			else if (jobid[client] == 24)
			{
				ShowBank(client);
			}
			else if (jobid[client] == 27)
			{
				ShowHosto(client);
			}
			else if (jobid[client] == 31)
			{
				ShowArti(client);
			}
			else if (jobid[client] == 34)
			{
				ShowTueur(client);
			}
			else if (jobid[client] == 37)
			{
				ShowHotel(client);
			}
			else
			{
				PrintToChat(client, "%s : Vous devez être chef.", LOGO);
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous devez être vivant.", LOGO);
		}
	}
}

ShowTueur(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Tueur);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		AddTueur(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddTueur(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && (jobid[i] == 35) || (jobid[i] == 36))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_Tueur(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		m[client] = GetClientOfUserId(UserID);
		
		jobid[m[client]] = 0;
		rankid[m[client]] = 0;
		salaire[m[client]] = 50;
		CS_SetClientClanTag(m[client], "Sans emploi -");
		PrintToChat(m[client], "%s : Vous avez été viré de votre job.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowHotel(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Hotel);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		AddHotel(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddHotel(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && (jobid[i] == 38) || (jobid[i] == 39))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_Hotel(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		m[client] = GetClientOfUserId(UserID);
		
		jobid[m[client]] = 0;
		rankid[m[client]] = 0;
		salaire[m[client]] = 50;
		
		CS_SetClientClanTag(m[client], "Sans emploi -");
		PrintToChat(m[client], "%s : Vous avez été viré de votre job.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowArti(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Arti);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		AddArti(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddArti(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && (jobid[i] == 32) || (jobid[i] == 33))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_Arti(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		m[client] = GetClientOfUserId(UserID);
		
		jobid[m[client]] = 0;
		rankid[m[client]] = 0;
		salaire[m[client]] = 50;
		
		CS_SetClientClanTag(m[client], "Sans emploi -");
		PrintToChat(m[client], "%s : Vous avez été viré de votre job.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

Showmafia(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Mafia);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		AddEmployers(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddEmployers(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && (jobid[i] == 7) || (jobid[i] == 8))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_Mafia(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		m[client] = GetClientOfUserId(UserID);
		
		jobid[m[client]] = 0;
		rankid[m[client]] = 0;
		salaire[m[client]] = 50;
		
		CS_SetClientClanTag(m[client], "Sans emploi -");
		PrintToChat(m[client], "%s : Vous avez été viré de votre job.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowHosto(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Hopital);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		Addtoubi(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public Addtoubi(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && (jobid[i] == 28) || (jobid[i] == 29) || (jobid[i] == 30))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_Hopital(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		m[client] = GetClientOfUserId(UserID);
		
		jobid[m[client]] = 0;
		rankid[m[client]] = 0;
		salaire[m[client]] = 50;
		
		CS_SetClientClanTag(m[client], "Sans emploi -");
		PrintToChat(m[client], "%s : Vous avez été viré de votre job.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowBank(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Banque);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		AddBank(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddBank(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && (jobid[i] == 25) || (jobid[i] == 26))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_Banque(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		m[client] = GetClientOfUserId(UserID);
		
		jobid[m[client]] = 0;
		rankid[m[client]] = 0;
		salaire[m[client]] = 50;
		
		CS_SetClientClanTag(m[client], "Sans emploi -");
		PrintToChat(m[client], "%s : Vous avez été viré de votre job.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowDealer(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Deal);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		AddDealer(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddDealer(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && (jobid[i] == 10) || (jobid[i] == 11))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_Deal(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		m[client] = GetClientOfUserId(UserID);
		
		jobid[m[client]] = 0;
		rankid[m[client]] = 0;
		salaire[m[client]] = 50;
		
		CS_SetClientClanTag(m[client], "Sans emploi -");
		PrintToChat(m[client], "%s : Vous avez été viré de votre job.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowCoach(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Coach);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		AddCoach(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddCoach(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && (jobid[i] == 13) || (jobid[i] == 14))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_Coach(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		m[client] = GetClientOfUserId(UserID);
		
		jobid[m[client]] = 0;
		rankid[m[client]] = 0;
		salaire[m[client]] = 50;
		
		CS_SetClientClanTag(m[client], "Sans emploi -");
		PrintToChat(m[client], "%s : Vous avez été viré de votre job.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowEbay(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Ebay);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		AddEbay(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddEbay(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && (jobid[i] == 16) || (jobid[i] == 17))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_Ebay(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		m[client] = GetClientOfUserId(UserID);
		
		jobid[m[client]] = 0;
		rankid[m[client]] = 0;
		salaire[m[client]] = 50;
		
		CS_SetClientClanTag(m[client], "Sans emploi -");
		PrintToChat(m[client], "%s : Vous avez été viré de votre job.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowArmurie(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Armu);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		AddArmurier(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddArmurier(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && (jobid[i] == 19) || (jobid[i] == 20))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_Armu(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		m[client] = GetClientOfUserId(UserID);
		
		jobid[m[client]] = 0;
		rankid[m[client]] = 0;
		salaire[m[client]] = 50;
		
		CS_SetClientClanTag(m[client], "Sans emploi -");
		PrintToChat(m[client], "%s : Vous avez été viré de votre job.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowLoto(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_Lotoo);
		SetMenuTitle(menu, "Choisis le joueurs :");
		SetMenuExitButton(menu, true);
        
		AddLoto(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddLoto(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && (jobid[i] == 22) || (jobid[i] == 23))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_Lotoo(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		m[client] = GetClientOfUserId(UserID);
		
		jobid[m[client]] = 0;
		rankid[m[client]] = 0;
		salaire[m[client]] = 50;
		
		CS_SetClientClanTag(m[client], "Sans emploi -");
		PrintToChat(m[client], "%s : Vous avez été viré de votre job.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// SM VOL

public Action:Command_Vol(client, args)
{
	if (IsPlayerAlive(client))
	{
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		if ((jobid[client] == 6) || (jobid[client] == 7) || (jobid[client] == 8))
		{
			if (g_IsInJail[client] == 0)
			{
				new i = GetClientAimTarget(client, true);
				new String:ClassName[255];
				ClassName[0] = '\0';
				
				new timestamp;
				timestamp = GetTime();
				
				if (i != -1)
				{
					GetEdictClassname(i, ClassName, 255);
					if(StrEqual(ClassName, "player"))
					{
						new vol_somme = GetRandomInt(1, 200);
					
						new Float:entorigin[3];
						GetEntPropVector(client, Prop_Send, "m_vecOrigin", entorigin);
					
						if (vol_somme > money[i])
						{
							PrintToChat(client, "%s : Le joueurs n'a pas d'argent sur lui.", LOGO);
						}
						else
						{
							new Float:origin[3], Float:clientent[3];
							GetEntPropVector(i, Prop_Send, "m_vecOrigin", origin);
							GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
							new Float:distance = GetVectorDistance(origin, clientent);
							new Float:vec[3];
							GetClientAbsOrigin(client, vec);
							vec[2] += 10;
							
							if ((timestamp - g_vol[client]) < 30)
							{
								PrintToChat(client, "%s : Vous devez attendre %i secondes avant de pouvoir volé.", LOGO, (30 - (timestamp - g_vol[client])) );
							}
							else
							{
								if (distance > 80)
								{
									PrintToChat(client, "%s : Vous êtes trop loin pour volé cette personne.", LOGO);
								}
								else
								{
									g_vol[client] = GetTime();
									
									PrintToChat(client, "%s : Vous avez volé %i$.", LOGO, vol_somme);
									
									TE_SetupBeamRingPoint(vec, 5.0, 180.0, g_BeamSprite, g_modelHalo, 0, 15, 0.6, 15.0, 0.0, greenColor, 10, 0);
									TE_SendToAll();
									
									PrintToChat(i, "%s : Vous avez perdu %i$ suite a un vol.", LOGO, vol_somme);
									
									money[i] = money[i] - vol_somme;
									money[client] = money[client] + vol_somme;
									
									capital[rankid[client]] = capital[rankid[client]] + vol_somme;
			
									SetEntData(client, MoneyOffset, money[client], 4, true);
									SetEntData(i, MoneyOffset, money[i], 4, true);
								}
							}
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez visé un joueurs.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé un joueurs.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous ne pouvez pas volé en jail.", LOGO);
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
		}
	}
	else
	{
		PrintToChat(client, "%s : Vous devez être en vie pour utilisé cette commande.", LOGO);
	}
	return Plugin_Continue;
}

public Action:OnWeaponEquip(client, weapon) 
{ 
    if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if (weapon == M4FBI)
			{
				countm4 = 10;
				countm4time = CreateTimer(1.0, Timer_M4fbi, _, TIMER_REPEAT);
			}
			
			if (weapon == DEAGLEFBI)
			{
				countdeagle = 10;
				countdeagletime = CreateTimer(1.0, Timer_deaglefbi, _, TIMER_REPEAT);
			}
			
			if (weapon == M3COMICO)
			{
				countm3 = 10;
				countm3time = CreateTimer(1.0, Timer_m3comico, _, TIMER_REPEAT);
			}
			
			if (weapon == USPCOMICO)
			{
				countusp = 10;
				countusptime = CreateTimer(1.0, Timer_uspcomico, _, TIMER_REPEAT);
			}
		}
	}
}

public Action:Timer_M4fbi(Handle:timer)
{
	countm4 -= 1;
	
	if (countm4 == 0)
	{
		KillTimer(countm4time);
		
		M4FBI = Weapon_Create("weapon_m4a1", NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(M4FBI, Float:{ -2950.105957, -2177.716064, -162.888840 }, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:Timer_deaglefbi(Handle:timer)
{
	countdeagle -= 1;
	
	if (countdeagle == 0)
	{
		KillTimer(countdeagletime);
		
		DEAGLEFBI = Weapon_Create("weapon_deagle", NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(DEAGLEFBI, Float:{ -2998.571045, -2174.289063, -162.888840 }, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:Timer_m3comico(Handle:timer)
{
	countm3 -= 1;
	
	if (countm3 == 0)
	{
		KillTimer(countm3time);
		
		M3COMICO = Weapon_Create("weapon_m3", NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(M3COMICO, Float:{ -2825.039551, -795.935791, -283.906189 }, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:Timer_uspcomico(Handle:timer)
{
	countusp -= 1;
	
	if (countusp == 0)
	{
		KillTimer(countusptime);
		
		USPCOMICO = Weapon_Create("weapon_usp", NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(USPCOMICO, Float:{ -2709.249512, -795.999817, -283.906189 }, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:OnTakeDamagePre(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (attacker > 0 && attacker <= MaxClients && victim > 0 && victim <= MaxClients)
	{
		if (IsPlayerAlive(attacker) && IsPlayerAlive(victim))
		{
			new String:sWeaponName[64];
			
			GetClientWeapon(attacker, sWeaponName, sizeof(sWeaponName));
			
			if (g_IsTazed[attacker] || IsInComico(attacker) || IsInFbi(attacker) || IsInHosto(attacker))
			{
				damage *= 0.0;
				return Plugin_Changed;
			}
			
			if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
			{
				if (!StrEqual(sWeaponName, "weapon_knife"))
				{
					damage *= 0.25;
					return Plugin_Changed;
				}
				else if (StrEqual(sWeaponName, "weapon_knife"))
				{
					if (levelcut[attacker] <= 0)
					{
						damage *= 0.0;
						return Plugin_Changed;
					}
				}
			}
			else if (GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2)
			{
				if (!StrEqual(sWeaponName, "weapon_knife"))
				{
					damage *= 0.25;
					return Plugin_Changed;
				}
				else if (StrEqual(sWeaponName, "weapon_knife"))
				{
					if (levelcut[attacker] <= 0)
					{
						damage *= 0.0;
						return Plugin_Changed;
					}
				}
			}
			else if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 2)
			{
				if (!StrEqual(sWeaponName, "weapon_knife"))
				{
					damage *= 0.75;
					return Plugin_Changed;
				}
				else if (StrEqual(sWeaponName, "weapon_knife"))
				{
					if (levelcut[attacker] <= 0)
					{
						damage *= 0.0;
						return Plugin_Changed;
					}
				}
			}
			else if (GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 3)
			{
				if (!StrEqual(sWeaponName, "weapon_knife"))
				{
					damage *= 0.75;
					return Plugin_Changed;
				}
				else if (StrEqual(sWeaponName, "weapon_knife"))
				{
					if (levelcut[attacker] <= 0)
					{
						damage *= 0.0;
						return Plugin_Changed;
					}
				}
			}
		}
	}
	
	if ((damagetype & DMG_FALL) == DMG_FALL)
    {
        return Plugin_Handled;
    }
	
	return Plugin_Continue;
}

// ON PLAYER RUN CMD

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (IsPlayerAlive(client))
	{
		if (!g_InUse[client] && buttons & IN_USE)
		{
			g_InUse[client] = true;
			
			if (IsInDistribMafia(client) || IsInDistribLoto(client) || IsInDistribBanque(client) || IsInDistribEbay(client))
			{
				if (rib[client] > 0)
				{
					new Handle:menu = CreateMenu(Menu_Bank);
					SetMenuTitle(menu, "Banque d'Oviscity :");
					AddMenuItem(menu, "Deposit", "Déposer de l'argent");
					AddMenuItem(menu, "Retired", "Retirer de l'argent");
					if (jobid[client] == 1 || jobid[client] == 6 || jobid[client] == 9 || jobid[client] == 12 || jobid[client] == 15 || jobid[client] == 18 || jobid[client] == 21 || jobid[client] == 24 || jobid[client] == 27 || jobid[client] == 31 || jobid[client] == 34 || jobid[client] == 37)
					{
						AddMenuItem(menu, "Capital", "Déposer dans le capital");
					}
					DisplayMenu(menu, client, MENU_TIME_FOREVER);
				}
				else
				{
					PrintToChat(client, "%s : Vous devez posséder un RIB.", LOGO);
				}
			}
			
			new Ent;
			new String:Door[255];
		
			Ent = GetClientAimTarget(client, false);
			
			if (Ent != -1)
			{
				GetEntityClassname(Ent, Door, sizeof(Door));
				
				if (StrEqual(Door, "func_door"))
				{
					if (!Entity_IsLocked(Ent))
					{
						AcceptEntityInput(Ent, "Toggle", client, client);
					}
					else
					{
						PrintToChat(client, "%s : La porte est fermée a clef.", LOGO);
					}
				}
				
				if (StrEqual(Door, "func_door_rotating"))
				{
					if (Entity_IsLocked(Ent))
					{
						PrintToChat(client, "%s : La porte est fermée a clef.", LOGO);
					}
				}
				
				if (StrEqual(Door, "prop_door_rotating"))
				{
					if (Entity_IsLocked(Ent))
					{
						PrintToChat(client, "%s : La porte est fermée a clef.", LOGO);
					}
				}
			}
			
			if (IsInSalle(client))
			{
				if ((jobid[client] == 6) || (jobid[client] == 7)  || (jobid[client] == 8))
				{
					if (!OnKit[client])
					{
						if (kitcrochetage[client] < 20)
						{
							GiveKit = CreateTimer(15.0, Timer_Kit, client);
							
							// DIFFUSE BARRE
							SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime()); 
							SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 15);
							
							OnKit[client] = true;
							
							SetEntityRenderColor(client, 255, 0, 0, 0);
							SetEntityMoveType(client, MOVETYPE_NONE);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez le maximum de kit de crochetage(%i)", LOGO, kitcrochetage[client]);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous êtes déjà en cours de fabrication.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez être mafieux.", LOGO);
				}
			}
		}
		else if(g_InUse[client] && !(buttons & IN_USE))
		{
			g_InUse[client] = false;
		}
	}
	return Plugin_Continue;
}

// BANQUE SYSTEM

public Menu_Bank(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		if (StrEqual(info, "Deposit"))
		{
			if (rib[client] == 1)
			{
				money[client] = GetEntData(client, MoneyOffset, 4);
				
				if (money[client] <= 0)
				{
					PrintToChat(client, "%s : Vous n'avez pas d'argent a déposé.", LOGO);		
				}
				
				new Handle:menub = CreateMenu(deposit_menu);
				SetMenuTitle(menub, "Choisis la somme :");
				
				if (money[client] >= 10)
				{
					AddMenuItem(menub, "10", "10$");
				}
				if (money[client] >= 50)
				{
					AddMenuItem(menub, "50", "50$");
				}
				if (money[client] >= 100)
				{
					AddMenuItem(menub, "100", "100$");
				}
				if (money[client] >= 200)
				{
					AddMenuItem(menub, "200", "200$");
				}
				if (money[client] >= 500)
				{
					AddMenuItem(menub, "500", "500$");
				}
				if (money[client] >= 1000)
				{
					AddMenuItem(menub, "1000", "1000$");
				}
				if (money[client] >= 2000)
				{
					AddMenuItem(menub, "2000", "2000$");
				}
				if (money[client] >= 5000)
				{
					AddMenuItem(menub, "5000", "5000$");
				}
				if (money[client] >= 1)
				{
					AddMenuItem(menub, "all", "all");
				}
				DisplayMenu(menub, client, MENU_TIME_FOREVER);
			}
			else
			{
				PrintToChat(client, "%s : Vous devez posséder un RIB.", LOGO);
			}
		}
		else if (StrEqual(info, "Retired"))
		{
			if (bank[client] <= 0)
			{
				PrintToChat(client, "%s : Tu n'as pas d'argent à retirer.", LOGO);			
			}
			
			
			if (money[client] >= 60000)
			{
				PrintToChat(client, "%s : Tu ne peut pas avoir plus d'argent sur toi.", LOGO);	
			}
			else
			{
				if (rib[client] == 1)
				{
					new Handle:menuba = CreateMenu(retired_menu);
					SetMenuTitle(menuba, "Choisis la somme :");
					
					if (bank[client] >= 5)
					{
						AddMenuItem(menuba, "5", "5$");
					}
					if (bank[client] >= 10)
					{
						AddMenuItem(menuba, "10", "10$");
					}
					if (bank[client] >= 50)
					{
						AddMenuItem(menuba, "50", "50$");
					}
					if (bank[client] >= 100)
					{
						AddMenuItem(menuba, "100", "100$");
					}
					if (bank[client] >= 200)
					{
						AddMenuItem(menuba, "200", "200$");
					}
					if (bank[client] >= 500)
					{
						AddMenuItem(menuba, "500", "500$");
					}
					if (bank[client] >= 1000)
					{
						AddMenuItem(menuba, "1000", "1000$");
					}
					if (bank[client] >= 2000)
					{
						AddMenuItem(menuba, "2000", "2000$");
					}
					if (bank[client] >= 5000)
					{
						AddMenuItem(menuba, "5000", "5000$");
					}
					if (bank[client] >= 10000)
					{
						AddMenuItem(menuba, "10000", "10000$");
					}
					DisplayMenu(menuba, client, MENU_TIME_FOREVER);
				}
				else
				{
					PrintToChat(client, "%s : Vous devez posséder un RIB.", LOGO);
				}
			}
		}
		else if (StrEqual(info, "Capital"))
		{
			if (rib[client] == 1)
			{
				money[client] = GetEntData(client, MoneyOffset, 4);
				
				if (money[client] <= 0)
				{
					PrintToChat(client, "%s : Vous n'avez pas d'argent a déposé.", LOGO);		
				}
				
				new Handle:menuc = CreateMenu(capital_menu);
				SetMenuTitle(menuc, "Choisis la somme :");
				
				if (money[client] >= 10)
				{
					AddMenuItem(menuc, "10", "10$");
				}
				if (money[client] >= 50)
				{
					AddMenuItem(menuc, "50", "50$");
				}
				if (money[client] >= 100)
				{
					AddMenuItem(menuc, "100", "100$");
				}
				if (money[client] >= 200)
				{
					AddMenuItem(menuc, "200", "200$");
				}
				if (money[client] >= 500)
				{
					AddMenuItem(menuc, "500", "500$");
				}
				if (money[client] >= 1000)
				{
					AddMenuItem(menuc, "1000", "1000$");
				}
				if (money[client] >= 2000)
				{
					AddMenuItem(menuc, "2000", "2000$");
				}
				if (money[client] >= 5000)
				{
					AddMenuItem(menuc, "5000", "5000$");
				}
				if (money[client] >= 1)
				{
					AddMenuItem(menuc, "all", "all");
				}
				DisplayMenu(menuc, client, MENU_TIME_FOREVER);
			}
			else
			{
				PrintToChat(client, "%s : Vous devez posséder un RIB.", LOGO);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public deposit_menu(Handle:menub, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menub, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		money[client] = GetEntData(client, MoneyOffset, 4);
		
		new deposit_somme = StringToInt(info, 10);
		
		if (deposit_somme < 0)
		{
			PrintToChat(client, "%s : Vous ne pouvez pas déposé une somme négative.", LOGO);
		}
		
		if (StrEqual(info, "all"))
		{
			PrintToChat(client, "%s : Vous avez déposé tout votre argent.", LOGO);
			
			bank[client] = money[client] + bank[client];
			money[client] = 0;
	
			SetEntData(client, MoneyOffset, money[client], 4, true);
		}
		
		else if (money[client] >= deposit_somme)
		{
			bank[client] += deposit_somme;
			money[client] -= deposit_somme;
			
			PrintToChat(client, "%s : Vous avez déposé %i$.", LOGO, deposit_somme);
			
			SetEntData(client, MoneyOffset, money[client], 4, true);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menub);
	}
}

public retired_menu(Handle:menuba, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menuba, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new String:SteamId[32];
		GetClientAuthString(client, SteamId, sizeof(SteamId));
		
		new difference = (65535 - money[client]);
	
		new retired_somme = StringToInt(info, 10);
		
		if (retired_somme > bank[client])
		{
			PrintToChat(client, "%s : Vous n'avez pas assez d'argent pour cette transaction.", LOGO);	
		}
		
		new final_cash = (money[client] + retired_somme);
		
		if (final_cash <= 65535)
		{
			bank[client] -= retired_somme;
			money[client] = final_cash;
			
			SetEntData(client, MoneyOffset, final_cash, 4, true);
			
			PrintToChat(client, "%s : Tu as retiré %i$.", LOGO, retired_somme);
		}
		
		if (final_cash > 65535)
		{
			bank[client] -= difference;
			
			SetEntData(client, MoneyOffset, money[client], 4, true);	
			PrintToChat(client, "%s : Tu as retiré %i$.", LOGO, difference);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuba);
	}
}

public capital_menu(Handle:menub, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menub, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		money[client] = GetEntData(client, MoneyOffset, 4);
		
		new deposit_somme = StringToInt(info, 10);
		
		if (deposit_somme < 0)
		{
			PrintToChat(client, "%s : Vous ne pouvez pas déposé une somme négative.", LOGO);
		}
		
		if (StrEqual(info, "all"))
		{
			PrintToChat(client, "%s : Vous avez déposé tout votre argent.", LOGO);
			
			capital[rankid[client]] = capital[rankid[client]] + money[client];
			money[client] = 0;
	
			SetEntData(client, MoneyOffset, money[client], 4, true);
		}
		
		else if (money[client] >= deposit_somme)
		{
			capital[rankid[client]] += deposit_somme;
			money[client] -= deposit_somme;
			
			PrintToChat(client, "%s : Vous avez déposé %i$.", LOGO, deposit_somme);
			
			SetEntData(client, MoneyOffset, money[client], 4, true);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menub);
	}
}

// SYSTEM KIT

public Action:Timer_Kit(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		new kit = kitcrochetage[client] + 1;

		kitcrochetage[client] = kit;

		PrintToChat(client, "%s : Vous avez pris un kit de crochetage [%i/20].", LOGO, kitcrochetage[client]);
		
		OnKit[client] = false;
		
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime()); 
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0); 
		
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

// INFOS CUT

public Action:Command_Infoscut(client, args)
{
	if (IsClientInGame(client))
	{
		PrintToChat(client, "%s : Vous disposez de %i level%s cut.", LOGO, levelcut[client], (levelcut[client] > 0 ? "s" : ""));
	}
}

// CONTRAT SYSTEM

public Action:Command_Contrat(client, Args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if (jobid[client] == 34 || jobid[client] == 35 || jobid[client] == 36)
			{
				acheteur[client] = GetClientAimTarget(client, true);
				TransactionWith[acheteur[client]] = client;
				TransactionWith[client] = acheteur[client];
				
				if (acheteur[client] != -1)
				{
					if (!oncontrat[client])
					{
						if (IsPlayerAlive(acheteur[client]))
						{
							if (!oncontrat[acheteur[client]])
							{
								CheckTueur(client);
							}
							else
							{
								PrintToChat(client, "%s : Le joueur %N est déjà en contrat.", LOGO, TransactionWith[client]);
							}
						}
						else
						{
							PrintToChat(client, "%s : Le joueur %N est mort.", LOGO, TransactionWith[client]);
						}
					}
					else
					{
							PrintToChat(client, "%s : Vous êtes déjà en contrat.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous devez visé un joueur.", LOGO);
				}
			}
			else
			{
				PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous devez être en vie.", LOGO);
		}
	}
}

CheckTueur(client)
{
	if(client > 0 && client <= MaxClients && !IsFakeClient(client))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
        
		new Handle:menu = CreateMenu(Menu_CheckTueur);
		SetMenuTitle(menu, "Choisis le joueur :");
		SetMenuExitButton(menu, true);
        
		AddCible(menu);
        
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AddCible(Handle:menu)
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+15];
    
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
				
			GetClientName(i, name, sizeof(name));
				
			Format(display, sizeof(display), "%s (%s)", name, user_id);
				
			AddMenuItem(menu, user_id, display);
		}
	}
}

public Menu_CheckTueur(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
        
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		cible[client] = GetClientOfUserId(UserID);
		
		new Handle:menub = CreateMenu(Menu_CibleChoose);
		SetMenuTitle(menub, "Voulez vous un contrat sur %N à 800$ ?", cible[client]);
		AddMenuItem(menub, "oui", "Oui je veux.");
		AddMenuItem(menub, "non", "Non merci !");
		DisplayMenu(menub, acheteur[client], MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_CibleChoose(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 800)
			{
				if (cible[TransactionWith[client]] != TransactionWith[client])
				{
					if (cible[TransactionWith[client]] != client)
					{
						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						
						money[client] = money[client] - 800;
						AdCash(TransactionWith[client], 400);
						
						capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 400;
						
						Contrat[TransactionWith[client]] = CreateTimer(1.0, UpdateContrat, client, TIMER_REPEAT);
						
						GiveItem(TransactionWith[client]);
						
						SetEntData(client, MoneyOffset, money[client], 4, true);
					}
					else
					{
						PrintToChat(client, "%s : Vous ne pouvez pas choisir vous même.", LOGO);
					}
				}
				else
				{
					PrintToChat(TransactionWith[client], "%s : Vous ne pouvez pas choisir vous même.", LOGO);
				}
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 800)
					{
						if (cible[TransactionWith[client]] != TransactionWith[client])
						{
							if (cible[TransactionWith[client]] != client)
							{
								PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
								PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
								
								bank[client] = bank[client] - 800;
								AdCash(TransactionWith[client], 400);
						
								capital[rankid[TransactionWith[client]]] = capital[rankid[TransactionWith[client]]] + 400;
								
								Contrat[TransactionWith[client]] = CreateTimer(1.0, UpdateContrat, TransactionWith[client], TIMER_REPEAT);
								
								GiveItem(TransactionWith[client]);
							}
							else
							{
								PrintToChat(client, "%s : Vous ne pouvez pas choisir vous même.", LOGO);
							}
						}
						else
						{
							PrintToChat(TransactionWith[client], "%s : Vous ne pouvez pas choisir vous même.", LOGO);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(TransactionWith[client], "%s : Le joueurs n'a pas assez d'argent.", LOGO);
				}
			}
			
		}
		else if (StrEqual(info, "non")) 
		{ 
			PrintToChat(TransactionWith[client], "%s : Le client %N a refusé.", LOGO, client); 
		} 
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:UpdateContrat(Handle:timer, any:client)
{
	if (IsClientConnected(client))
	{
		if (IsClientConnected(cible[client]))
		{
			if (g_jailtime[client] == 0)
			{
				if (IsPlayerAlive(client))
				{
					oncontrat[client] = true;
					oncontrat[cible[client]] = true;
		
					new Float:tueur_vec[3];
					new Float:cible_vec[3];
					GetClientAbsOrigin(client, tueur_vec);
					GetClientAbsOrigin(cible[client], cible_vec);
				
					tueur_vec[2] += 45;
					cible_vec[2] += 45;
					
					TE_SetupBeamPoints(tueur_vec, cible_vec, g_BeamSprite, g_modelHalo, 0, 1, 1.0, 10.0, 10.0, 1, 10.0, redColor, 50);
					TE_SendToClient(client);
					
					if (HasKillCible[client])
					{
						fincontrat(client);
								
						PrintToChat(client, "%s : Vous avez réussi votre contrat sur %N.", LOGO, cible[client]);
						PrintToChat(TransactionWith[client], "%s : %N a réussi son contrat sur %N", LOGO, client, cible[client]);
					}
				}
				else
				{
					fincontrat(client);
					
					PrintToChat(client, "%s : Vous avez tué durant votre contrat, contrat échoué.", LOGO);
					PrintToChat(TransactionWith[client], "%s : %N a échoué son contrat sur %N", LOGO, client, cible[client]);
				}
			}
			else
			{
				fincontrat(client);
				
				PrintToChat(client, "%s : Vous avez été attraper par la Police, contrat échoué.", LOGO);
				PrintToChat(TransactionWith[client], "%s : %N a échoué son contrat sur %N", LOGO, client, cible[client]);
			}
		}
		else
		{
			fincontrat(client);
			
			PrintToChat(client, "%s : Votre cible c'est déconnectée, contrat échoué.", LOGO);
			PrintToChat(TransactionWith[client], "%s : %N a échoué son contrat sur %N", LOGO, client, cible[client]);
		}
	}
}

public fincontrat(client)
{
	if (IsClientInGame(client))
	{
		if (Contrat[client] != INVALID_HANDLE)
		{
			KillTimer(Contrat[client]);
			Contrat[client] = INVALID_HANDLE;
		}
		
		oncontrat[client] = false;
		oncontrat[cible[client]] = false;
		HasKillCible[client] = false;
		
		disarm(client);
		GivePlayerItem(client, "weapon_knife");
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntityGravity(client, 1.0);
	}
}

public GiveItem(client)
{
	new Handle:menub = CreateMenu(Menu_Weapon);
	SetMenuTitle(menub, "Choisissez votre bonus");
	AddMenuItem(menub, "1", "Deagle + vie");
	AddMenuItem(menub, "2", "Deagle + vitesse");
	AddMenuItem(menub, "3", "Deagle + gravité");
	DisplayMenu(menub, client, MENU_TIME_FOREVER);
}

public Menu_Weapon(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "1"))
		{
			GivePlayerItem(client, "weapon_deagle");
			SetEntityHealth(client, 300);
		}
		else if (StrEqual(info, "2"))
		{
			GivePlayerItem(client, "weapon_deagle");
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);
		}
		else if (StrEqual(info, "3"))
		{
			GivePlayerItem(client, "weapon_deagle");
			SetEntityGravity(client, 0.5);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// HOOK MESSAGES

public Action:TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
    decl String:msg[256];
    BfReadString(bf, msg, sizeof(msg), false);

    if(StrContains(msg, "damage", false) != -1 || StrContains(msg, "-------", false) != -1)
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
} 

// NATIVES

public NativeGetClientBank(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return bank[client];
}

public NativeSetClientBank(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new amount = GetNativeCell(2);
	bank[client] = amount;
	return;
}

public NativeSetClientMoney(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new amount = GetNativeCell(2);
	money[client] = amount;
	return;
}

// SALAIRES

public Action:Command_Salaire(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			BuildSalaireMenu(client);
		}
	}
}

Handle:BuildSalaireMenu(client)
{
	new Handle:menub = CreateMenu(Menu_Salaire);
	SetMenuTitle(menub, "Modifier le salaire de :");
	
	if (jobid[client] == 1)
	{
		AddMenuItem(menub, "1", "Chef d'état");
		AddMenuItem(menub, "2", "Agent CIA");
		AddMenuItem(menub, "3", "Agent FBI");
		AddMenuItem(menub, "4", "Policier");
		AddMenuItem(menub, "5", "Gardien");
	}
	else if (jobid[client] == 6)
	{
		AddMenuItem(menub, "6", "Chef Mafia");
		AddMenuItem(menub, "7", "Mafieux");
		AddMenuItem(menub, "8", "Apprenti Mafieux");
	}
	else if (jobid[client] == 9)
	{
		AddMenuItem(menub, "9", "Chef Dealer");
		AddMenuItem(menub, "10", "Dealer");
		AddMenuItem(menub, "11", "Apprenti Dealer");
	}
	else if (jobid[client] == 12)
	{
		AddMenuItem(menub, "12", "Chef Coach");
		AddMenuItem(menub, "13", "Coach");
		AddMenuItem(menub, "14", "Apprenti Coach");
	}
	else if (jobid[client] == 15)
	{
		AddMenuItem(menub, "15", "Chef Ebay");
		AddMenuItem(menub, "16", "Vendeur Ebay");
		AddMenuItem(menub, "17", "Apprenti Vendeur Ebay");
	}
	else if (jobid[client] == 18)
	{
		AddMenuItem(menub, "18", "Chef Armurerie");
		AddMenuItem(menub, "19", "Armurier");
		AddMenuItem(menub, "20", "Apprenti Armurier");
	}
	else if (jobid[client] == 21)
	{
		AddMenuItem(menub, "21", "Chef Loto");
		AddMenuItem(menub, "22", "Vendeur de Tickets");
		AddMenuItem(menub, "23", "Apprenti Vendeur de Tickets");
	}
	else if (jobid[client] == 24)
	{
		AddMenuItem(menub, "24", "Chef Banquier");
		AddMenuItem(menub, "25", "Banquier");
		AddMenuItem(menub, "26", "Apprenti Banquier");
	}
	else if (jobid[client] == 27)
	{
		AddMenuItem(menub, "27", "Chef Hôpital");
		AddMenuItem(menub, "28", "Médecin");
		AddMenuItem(menub, "29", "Infirmier");
		AddMenuItem(menub, "30", "Chirurgien");
	}
	else if (jobid[client] == 31)
	{
		AddMenuItem(menub, "31", "Chef Artificier");
		AddMenuItem(menub, "32", "Artificier");
		AddMenuItem(menub, "33", "Apprenti Artificer");
	}
	else if (jobid[client] == 34)
	{
		AddMenuItem(menub, "34", "Chef Tueurs");
		AddMenuItem(menub, "35", "Tueur d'élite");
		AddMenuItem(menub, "36", "Tueur novice");
	}
	else if (jobid[client] == 37)
	{
		AddMenuItem(menub, "37", "Chef Hôtelier");
		AddMenuItem(menub, "38", "Hôtelier");
		AddMenuItem(menub, "39", "Apprenti Hôtelier");
	}
	else
	{
		PrintToChat(client, "%s : Vous devez être chef.", LOGO);
	}
	DisplayMenu(menub, client, MENU_TIME_FOREVER);
}

public Menu_Salaire(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		salarychoose[client] = StringToInt(info);
		
		new Handle:menuc = CreateMenu(Menu_Choice);
		SetMenuTitle(menuc, "Nouveau salaire :");
		AddMenuItem(menuc, "500", "500$");
		AddMenuItem(menuc, "400", "400$");
		AddMenuItem(menuc, "300", "300$");
		AddMenuItem(menuc, "200", "200$");
		AddMenuItem(menuc, "100", "100$");
		AddMenuItem(menuc, "50", "50$");
		AddMenuItem(menuc, "0", "0$");
		DisplayMenu(menuc, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_Choice(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		new salaryfinal = StringToInt(info);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && (jobid[i] == salarychoose[client]))
			{
				salaire[i] = salaryfinal;
			}
		}
		salarychoose[client] = 0;
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Timer_Pub(Handle:timer)
{
	switch (GetRandomInt(1, 7))
	{
		case 1:
		{
			PrintToChatAll("%s : Bienvenue sur le Roleplay Quebec.", LOGO);
		}
		
		case 2:
		{
			PrintToChatAll("%s : Le serveur est en bêta test.", LOGO);
		}
		
		case 3:
		{
			PrintToChatAll("%s : Roleplay QUEBEC [RCT ON]", LOGO);
		}
		
		case 4:
		{
			PrintToChatAll("%s : rpqc.webs.com.", LOGO);
		}
		
		case 5:
		{
			PrintToChatAll("%s : Veuillez rapporté les bugs sur le Forum.", LOGO);
		}
		
		case 6:
		{
			PrintToChatAll("%s : Tapez !rp pour voir les commandes.",  LOGO);
		}
		
		case 7:
		{
			PrintToChatAll("%s : Le Roleplay est codé par \x04Ultimate Phoenix Qc \x01.",  LOGO);
		}
	}

}

// APPARTEMENTS

public Action:Timer_Appart(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (maisontime[client] > 0)
		{
			maisontime[client] -= 1;
			
			if (maisontime[client] == 0)
			{
				PrintToChat(client, "%s : La location de votre appartement a expirée (Appartement N°%i).", LOGO, maison[client]);
				maison[client] = 0;
				maisontime[client] = 0;
				g_appart[client] = false;
				
				KillTimer(TimerAppart[client]);
			}
		}
	}
}

public Action:Command_Time(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			PrintToChat(client, "%s : Il vous reste %i secondes de location de votre appartement n°%i", LOGO, maisontime[client], maison[client]);
		}
	}
}

// COMMANDES FORUM

public Action:Command_Forum(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			PrintToChat(client, "%s : URL du Forum :\x03 %s", LOGO, FORUM);
			return Plugin_Handled;
		}
		else
		{
			PrintToChat(client, "%s : Vous devez être en vie.", LOGO);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

// KILL LOGIC

public KillLogic()
{
	new maxent = GetMaxEntities(), String:szClass[65];
	
	for (new i = MaxClients; i <= maxent; i++)
	{
        if(IsValidEdict(i) && IsValidEntity(i))
        {
			GetEdictClassname(i, szClass, sizeof(szClass));
			if(StrEqual("logic_auto", szClass) || StrEqual("trigger_hurt", szClass))
			{
				RemoveEdict(i);
			}
		}
	}
}

// COMMANDE NAME

public Action:Command_Entity(client, args)
{
	decl Ent;
	Ent = GetClientAimTarget(client, false);
	
	if (Ent != -1)
	{
		new String:classname[200];
		
		Entity_GetName(Ent, classname, sizeof(classname));

		if (IsPlayerAlive(client))
		{
			if (GetUserFlagBits(client) > 0)
			{
				PrintToChat(client, "%s : Name Entity <=> %s.", LOGO, classname);
				return Plugin_Handled;
			}
			else
			{
				PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
			}
		}
		else
		{
			PrintToChat(client, "%s : Vous devez être en vie pour utilisé cette commande.", LOGO);
		}
	}
	else
	{
		PrintToChat(client, "%s : Vous devez visé une entité.", LOGO);
	}
	return Plugin_Continue;
}