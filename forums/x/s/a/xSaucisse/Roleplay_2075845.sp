#include <sdktools>
#include <cstrike>
#include <smlib>
#include <sdkhooks>
#include <sourcemod>

#pragma semicolon 1

#define LOGO	"\x04[FeetG-RP] \x01"
#define PLUGIN_VERSION	"1.1.1"
#define TEAM	"FeetG"
#define FORUM 	"http://feetg.css.vg"
#define SOUND_TAZER 	"ambient/machines/zap1.wav"
#define MAX_PLAYERS 64
#define URL_FORUM "http://feetg.css.vg"
#define URL_SITE "http://feetg.css.vg/sourcebans/"
#define URL_LOCAGAME "http://feetg.css.vg"
#define URL_OPTION "http://feetg.css.vg/sourcebans/"
#define URL_RCT "http://feetg.css.vg"

new Handle:db_rp;
new Handle:Select;
new Handle:Insert;
new Handle:Timers;
new Handle:pub;

#define TAZER_COLORORANGE 	{255,128,0,255}
#define TAZER_COLORRED 	{255,75,75,255}
#define TAZER_COLORGREEN 	{75,255,75,255}
#define TAZER_COLORGRAY 	{128,128,128,255}
#define TAZER_COLORBLUE 	{75,75,255,255}

new redColor[4]		= {255, 75, 75, 255 };
new greenColor[4]	= {75, 255, 75, 255 };
new blueColor[4]		= {75,75,255,255};
new orangeColor[4]	= {255,128,0,255};

new bool:g_IsTazed[MAXPLAYERS+1] = false;
new bool:g_crochetageon[MAXPLAYERS+1] = false;
new bool:drogue[MAXPLAYERS+1] = false;
new bool:g_InUse[MAXPLAYERS+1];
new bool:grab[MAXPLAYERS+1] = false;
new bool:g_booldead[MAXPLAYERS+1] = false;
new bool:g_booljail[MAXPLAYERS+1] = false;
new bool:g_boolreturn[MAXPLAYERS+1] = false;
new bool:g_boolexta[MAXPLAYERS+1] = false;
new bool:g_boollsd[MAXPLAYERS+1] = false;
new bool:g_boolcoke[MAXPLAYERS+1] = false;
new bool:g_boolhero[MAXPLAYERS+1] = false;
new g_CountDead[MAXPLAYERS+1] = 0;

new Handle:TimerHud[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_deadtimer[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:g_jailtimer[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:g_croche[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:g_jailreturn[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:g_TazerTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:gTimer;
new Handle:heroo[MAXPLAYERS+1];
new Handle:extasiie[MAXPLAYERS+1];
new Handle:lssd[MAXPLAYERS+1];
new Handle:cokk[MAXPLAYERS+1];
new Handle:cvSpeed = INVALID_HANDLE;
new Handle:cvDistance = INVALID_HANDLE; 
new Handle:cvSound = INVALID_HANDLE;
new Handle:countm4time;
new Handle:countdeagletime;
new Handle:countm3time;
new Handle:countusptime;

new bool:connection;
new bool:g_bIsMapLoaded = false;

new String:gSound[256];
new String:g_gamedesc[64];

new gObj[MAXPLAYERS+1];
new Float:g_Count[MAXPLAYERS+1] = 0.0;
new g_jailtime[MAXPLAYERS+1] = 0;
new g_crochcount[MAXPLAYERS+1] = 0;
new TransactionWith[MAXPLAYERS+1] = 0;
new g_IsInJail[MAXPLAYERS+1] = 0;
new g_crochetage[MAXPLAYERS+1];
new g_vol[MAXPLAYERS+1];
new g_invisible[MAXPLAYERS+1] = 0;

new g_countheure1 = 0;
new g_countheure2 = 0;
new g_countminute1 = 0;
new g_countminute2 = 0;

new countm4 = 0;
new countdeagle = 0;
new countm3 = 0;
new countusp = 0;

new money[MAXPLAYERS+1];
new bank[MAXPLAYERS+1];
new jobid[MAXPLAYERS+1];
new kitcrochetage[MAXPLAYERS+1];
new h[MAXPLAYERS+1];
new l[MAXPLAYERS+1];
new p[MAXPLAYERS+1];
new z[MAXPLAYERS+1];
new m[MAXPLAYERS+1];
new g_tazer[MAXPLAYERS+1];
new rib[MAXPLAYERS+1];
new Entiter[MAXPLAYERS+1];
new ak47[MAXPLAYERS+1];
new awp[MAXPLAYERS+1];
new m249[MAXPLAYERS+1];
new scout[MAXPLAYERS+1];
new sg550[MAXPLAYERS+1];
new sg552[MAXPLAYERS+1];
new ump[MAXPLAYERS+1];
new tmp[MAXPLAYERS+1];
new mp5[MAXPLAYERS+1];
new deagle[MAXPLAYERS+1];
new usp[MAXPLAYERS+1];
new glock[MAXPLAYERS+1];
new xm1014[MAXPLAYERS+1];
new m3[MAXPLAYERS+1];
new m4a1[MAXPLAYERS+1];
new aug[MAXPLAYERS+1];
new galil[MAXPLAYERS+1];
new mac10[MAXPLAYERS+1];
new famas[MAXPLAYERS+1];
new p90[MAXPLAYERS+1];
new elite[MAXPLAYERS+1];
new ticket10[MAXPLAYERS+1];
new ticket100[MAXPLAYERS+1];
new ticket1000[MAXPLAYERS+1];
new levelcut[MAXPLAYERS+1];
new cartouche[MAXPLAYERS+1];
new permislourd[MAXPLAYERS+1];
new permisleger[MAXPLAYERS+1];
new cb[MAXPLAYERS+1];
new props1[MAXPLAYERS+1];
new props2[MAXPLAYERS+1];
new heroine[MAXPLAYERS+1];
new exta[MAXPLAYERS+1];
new lsd[MAXPLAYERS+1];
new coke[MAXPLAYERS+1];

new capital[MAXPLAYERS+1];
new serveur;

new g_succesheadshot[MAXPLAYERS+1];
new g_headshot[MAXPLAYERS+1];
new g_succesporte20[MAXPLAYERS+1];
new g_succesporte50[MAXPLAYERS+1];
new g_succesporte100[MAXPLAYERS+1];
new g_porte[MAXPLAYERS+1];

new g_modelLaser, g_modelHalo, g_LightingSprite, g_BeamSprite;

new M4FBI;
new DEAGLEFBI;
new M3COMICO;
new USPCOMICO;

public Plugin:myinfo =
{
    name = "FeetG-RP",
    description = "Roleplay",
    author = "Tom 'Gapgapgap' R.",
    version = PLUGIN_VERSION,
    url = FORUM
};

public OnPluginStart()
{
	connectdb();
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_team", OnPlayerTeam, EventHookMode_Pre);
	
	RegConsoleCmd("sm_ent", Command_Ent);
	RegConsoleCmd("sm_lock", Cmd_Lock);
	RegConsoleCmd("sm_unlock", Cmd_Unlock);
	RegConsoleCmd("sm_civil", Command_Civil);
	RegConsoleCmd("sm_give", Command_Cash);
	RegConsoleCmd("sm_jail", Command_Jail);
	RegConsoleCmd("sm_taser", Command_tazer);
	RegConsoleCmd("sm_vis", Command_Vis);
	RegConsoleCmd("sm_jobmenu", Command_Jobmenu);
	RegConsoleCmd("sm_money", Command_Money);
	RegConsoleCmd("sm_infos", Command_Infos);
	RegConsoleCmd("sm_item", Command_Item);
	RegConsoleCmd("sm_demission", Command_Demission);
	RegConsoleCmd("sm_engager", Command_Engager);
	RegConsoleCmd("sm_recruter", Command_Engager);
	RegConsoleCmd("sm_recrute", Command_Engager);
	RegConsoleCmd("sm_+force", Command_Grab);
	RegConsoleCmd("sm_enquete", Command_Enquete);
	RegConsoleCmd("sm_del", Command_Rw);
	RegConsoleCmd("sm_virer", Command_Virer);
	RegConsoleCmd("sm_licencier", Command_Virer);
	RegConsoleCmd("sm_exclure", Command_Virer);
	RegConsoleCmd("sm_vendre", Command_Vente); 
	RegConsoleCmd("sm_vol", Command_Vol);
	RegConsoleCmd("sm_rp", Command_Roleplay);
	RegConsoleCmd("sm_perquisition", Command_Perqui);
	RegConsoleCmd("sm_perqui", Command_Perqui);
	RegConsoleCmd("sm_armurerie", Command_Armurie);
	RegConsoleCmd("sm_armu", Command_Armurie);
	RegConsoleCmd("sm_changename", Command_Changename);
	RegConsoleCmd("sm_out", Command_Out);
	RegConsoleCmd("sm_jaillist", Command_Jaillist);
	
	AddCommandListener(OnSay, "say");
	AddCommandListener(OnSayTeam, "say_team");
	AddCommandListener(Block, "kill");
	AddCommandListener(Block, "explode");
	AddCommandListener(Command_JoinTeam, "jointeam");
	
	cvSpeed = CreateConVar("sm_grabber_speed", "10.0");
	cvDistance = CreateConVar("sm_grabber_distance", "80.0");
	cvSound = CreateConVar("sm_grabber_sound", "weapons/physcannon/hold_loop.wav", "sound du grab");
	
	Format(g_gamedesc, sizeof(g_gamedesc), "Clan-Family RolePlay");
	
	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
}

public OnMapStart()
{
	new Handle:mp_startmoney = INVALID_HANDLE;
	mp_startmoney = FindConVar("mp_startmoney");

	if(mp_startmoney != INVALID_HANDLE)
	{
		SetConVarBounds(mp_startmoney, ConVarBound_Lower, false);
	}
	
	SetConVarInt(FindConVar("ammo_flashbang_max"), 3, false, false);
	SetConVarInt(FindConVar("ammo_hegrenade_max"), 5, false, false);
	SetConVarInt(FindConVar("ammo_smokegrenade_max"), 3, false, false);
	
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
	
	PrecacheModel("models/player/pil/re1/wesker/wesker_pil.mdl", true);
	PrecacheModel("models/player/rocknrolla/ct_urban.mdl", true);
	PrecacheModel("models/player/ics/ct_gign_fbi/ct_gign.mdl", true);
	PrecacheModel("models/player/natalya/police/chp_male_jacket.mdl", true);
	PrecacheModel("models/player/elis/po/police.mdl", true);
	PrecacheModel("models/player/slow/vin_diesel/slow.mdl", true);
	PrecacheModel("models/player/slow/niko_bellic/slow.mdl", true);
	PrecacheModel("models/player/slow/50cent/slow.mdl", true);
	PrecacheModel("models/player/slow/jamis/kingpin/slow_v2.mdl", true);
	
	g_modelLaser = PrecacheModel("sprites/laser.vmt");
	g_modelHalo = PrecacheModel("materials/sprites/halo01.vmt");
	g_LightingSprite = PrecacheModel("sprites/l[CSS-RP]gtning.vmt");
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	
	startheure();
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
	
	PrintToServer("[FeetG-RP] : Le plugin Roleplay a bien démarré.");
	
	new i;
	for (i=0; i<MAX_PLAYERS; i++)
	{
		gObj[i]=-1;
	}
	gTimer = CreateTimer(0.1, UpdateObjects, INVALID_HANDLE, TIMER_REPEAT);
	
	GetConVarString(cvSound, gSound, sizeof(gSound));
	PrecacheSound(gSound, true);
	
	g_bIsMapLoaded = true;
	
	pub = CreateTimer(90.0, Timer_Pub, _, TIMER_REPEAT);
	
	GetCapital();
}

public OnMapEnd()
{
	CloseHandle(db_rp);
	CloseHandle(gTimer);
	KillTimer(Timers);
	KillTimer(pub);
	
	UnhookEvent("player_death", OnPlayerDeath);
	UnhookEvent("player_spawn", OnPlayerSpawn);
	
	g_bIsMapLoaded = false;
	
	DBSaveCapital();
}

public OnClientPutInServer(client)
{
	if(client && !IsFakeClient(client)) 
	{
		gObj[client] = -1;
	}
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	ClientCommand(client, "cl_radaralpha 0");
	
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
	
	if (g_IsTazed[client] == true)			
	{
		g_IsTazed[client] = false;
	}
	
	gObj[client] = -1;
	
	StopSound(client, SNDCHAN_AUTO, gSound);
	
	return Plugin_Continue;
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
	gObj[client] = -1;
	
	StopSound(client, SNDCHAN_AUTO, gSound);
	
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
				
				if (jobid[client] == 1)
				{
					CS_SwitchTeam(client, 3);
					SetEntityHealth(client, 500);
					CS_SetClientClanTag(client, "C. Police -");
					SetEntityModel(client, "models/player/pil/re1/wesker/wesker_pil.mdl");
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
					SetEntityModel(client, "models/player/rocknrolla/ct_urban.mdl");
				} 
				else if (jobid[client] == 3)
				{
					CS_SwitchTeam(client, 3);
					CS_SetClientClanTag(client, "Agent du FBI -");
					SetEntityHealth(client, 300);
					SetEntityModel(client, "models/player/ics/ct_gign_fbi/ct_gign.mdl");
				} 
				else if (jobid[client] == 4)
				{
					CS_SwitchTeam(client, 3);
					CS_SetClientClanTag(client, "Policier -");
					SetEntityHealth(client, 200);
					SetEntityModel(client, "models/player/natalya/police/chp_male_jacket.mdl");
				} 
				else if (jobid[client] == 5)
				{
					CS_SwitchTeam(client, 3);
					CS_SetClientClanTag(client, "Gardien -");
					SetEntityHealth(client, 150);
					SetEntityModel(client, "models/player/elis/po/police.mdl");
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
				
				if (GetClientTeam(client) == 2)
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
				
				ChooseKiller(client);
				
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
				KillTimer(g_deadtimer[client]);
				g_booldead[client] = false;
			}
		}
	}
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
				EmitSoundToClient(i, "roleplay_sm/salaire.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
		}
		
		new randomcapital = GetRandomInt(1, 800);
		
		if (capital[serveur] > 0)
		{
			capital[serveur] = capital[serveur]  -  randomcapital;
		}
		else
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && ((jobid[i] == 6) || (jobid[i] == 9) || (jobid[i] == 12) || (jobid[i] == 15) || (jobid[i] == 18) || (jobid[i] == 21) || (jobid[i] == 24) || (jobid[i] == 27)))
				{
					PrintToChat(i, "%s : Vous n'avez pas assez d'argent pour payé les impôts s'élevant à %d$.", LOGO, randomcapital);
				}
			}
		}
		
		DBSaveCapital();
	}
}

public startheure()
{
	Timers = CreateTimer(1.0, Timer_Horloge, _, TIMER_REPEAT);
}

public connectdb()
{
	new String:error[255];
	
	if(SQL_CheckConfig("roleplay"))
	{
		db_rp = SQL_Connect("roleplay", true, error, sizeof(error));
	}
	
	if(db_rp == INVALID_HANDLE)
	{
		PrintToChatAll("%s : Impossible de se connecter a la database : %s", LOGO, error);
		connection = false;
	}
	else
	{
		PrintToChatAll("%s : Connexion a la database réussite.", LOGO);
		connection = true;
	}
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	LockingDoor();
	UnlockDoor();
	PrintToChatAll("%s : Les Portes du serveurs ont été fermées a clef.", LOGO);
	
	M4FBI = Weapon_Create("weapon_m4a1", NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(M4FBI, Float:{ -2976.642334, -2168.735596, -161.844177 }, NULL_VECTOR, NULL_VECTOR);
	
	DEAGLEFBI = Weapon_Create("weapon_deagle", NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(DEAGLEFBI, Float:{ -2998.571045, -2174.289063, -162.888840 }, NULL_VECTOR, NULL_VECTOR);
	
	M3COMICO = Weapon_Create("weapon_m3", NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(M3COMICO, Float:{ -2825.039551, -795.935791, -283.906189 }, NULL_VECTOR, NULL_VECTOR);
	
	USPCOMICO = Weapon_Create("weapon_usp", NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(USPCOMICO, Float:{ -2709.249512, -795.999817, -283.906189 }, NULL_VECTOR, NULL_VECTOR);
}

stock LockingDoor()
{
	LockingEntity("func_door_rotating");
	LockingEntity("prop_door_rotating");
	LockingEntity("func_door");
}  

stock UnlockDoor()
{
	UnlockingEntity("func_door_rotating");
	UnlockingEntity("prop_door_rotating");
	UnlockingEntity("func_door");
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

stock UnlockingEntity(const String:ClassName[])
{
    new entity = -1;
    while ((entity = FindEntityByClassname(entity, ClassName)) != INVALID_ENT_REFERENCE)
    {
        if(IsValidEdict(entity) && IsValidEntity(entity) && IsInLoto(entity))
        {
            SetEntProp(entity, Prop_Data, "m_bLocked", 0, 1);
        }
    }
}

public OnClientSettingsChanged(client)
{
    change_tag(client);
}

public Action:OnClientPreAdminCheck(client)
{
	new String:SteamId[32];
	
	if (IsClientInGame(client))
	{
		GetClientAuthString(client, SteamId, sizeof(SteamId));
	}

	GetInfos(client);
	GetItem(client);
	GetSucces(client);

	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
	
	CreateTimer(1.0, Timer_Choose, client);
	CreateTimer(5.0, Timer_Tag, client);
	TimerHud[client] = CreateTimer(0.5, HudTimer, client, TIMER_REPEAT);
	
	if (StrEqual(SteamId, "STEAM_0:0:27345284"))
	{
		PrintToChatAll("%s : Le leader \x04%N \x01viens de se connecter.", LOGO, client);
	}
	if (StrEqual(SteamId, "STEAM_0:0:57442405"))
	{
		PrintToChatAll("%s : L' administrateur \x04%N \x01viens de se connecter.", LOGO, client);
	}
}	

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
	}
}

public Action:Timer_Tag(Handle:timer, any:client)
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
	}
}

public Action:Timer_Choose(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		GetInfos(client);
		
		g_booldead[client] = false;
		
		ClientCommand(client, "cl_radaralpha 0");
		
		new Handle:menu = CreateMenu(Connect_Menu);
		SetMenuTitle(menu, "Bienvenue sur le Roleplay %N", client);
		
		if (jobid[client] == 1)
		{
			CS_SwitchTeam(client, 3);
			CS_RespawnPlayer(client);
			SetEntityHealth(client, 500);
			CS_SetClientClanTag(client, "C. Police -");
			SetEntityModel(client, "models/player/pil/re1/wesker/wesker_pil.mdl");
			
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
			CS_SetClientClanTag(client, "Sans emploi -");
			
			AddMenuItem(menu, "job", "Votre job est : Sans-Emploi.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 2)
		{
			CS_SwitchTeam(client, 3);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "Agent CIA -");
			SetEntityHealth(client, 400);
			SetEntityModel(client, "models/player/rocknrolla/ct_urban.mdl");
			
			AddMenuItem(menu, "job", "Votre job est : Agent CIA.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 3)
		{
			CS_SwitchTeam(client, 3);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "Agent du FBI -");
			SetEntityHealth(client, 300);
			SetEntityModel(client, "models/player/ics/ct_gign_fbi/ct_gign.mdl");
			
			AddMenuItem(menu, "job", "Votre job est : Agent du FBI.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 4)
		{
			CS_SwitchTeam(client, 3);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "Policier -");
			SetEntityHealth(client, 200);
			SetEntityModel(client, "models/player/natalya/police/chp_male_jacket.mdl");
			
			AddMenuItem(menu, "job", "Votre job est : Policier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 5)
		{
			CS_SwitchTeam(client, 3);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "Gardien -");
			SetEntityHealth(client, 150);
			SetEntityModel(client, "models/player/elis/po/police.mdl");
			
			AddMenuItem(menu, "job", "Votre job est : Gardien.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 6)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "C. Mafia -");
			
			AddMenuItem(menu, "job", "Votre job est : Chef Mafia.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 7)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "Mafieux -");
			
			AddMenuItem(menu, "job", "Votre job est : Mafieux.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 8)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "A. Mafieux -");
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Mafieux.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 9)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "C. Dealer -");
			
			AddMenuItem(menu, "job", "Votre job est : ChefDealer.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 10)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "Dealer -");
			
			AddMenuItem(menu, "job", "Votre job est : Dealer.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 11)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "A. Dealer -");
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Dealer", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 12)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "C. Coach -");
			
			AddMenuItem(menu, "job", "Votre job est : Chef Coach.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 13)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "Coach -");
			
			AddMenuItem(menu, "job", "Votre job est : Coach.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 14)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "A. Coach -");
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Coach.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 15)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "C. Ebay -");
			
			AddMenuItem(menu, "job", "Votre job est : Chef Ebay.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 16)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "V. Ebay -");
			
			AddMenuItem(menu, "job", "Votre job est : Vendeur Ebay.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 17)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "A.V. Ebay -");
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Vendeur Ebay.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 18)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "C. Armurie -");
			
			AddMenuItem(menu, "job", "Votre job est : Chef Armurie.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 19)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "Armurier -");
			
			AddMenuItem(menu, "job", "Votre job est : Armurier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 20)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "A. Armurier -");
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Armurier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 21)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "C. Loto -");
			
			AddMenuItem(menu, "job", "Votre job est : Chef Loto.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 22)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "V. de Ticket -");
			
			AddMenuItem(menu, "job", "Votre job est : Vendeur de Ticket.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 23)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "A.V. de Ticket -");
			
			AddMenuItem(menu, "job", "Votre job est : Apprenti Vendeur de Ticket.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 24)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "C. Banquier -");
			
			AddMenuItem(menu, "job", "Votre job est : Chef Banquier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 25)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "Banquier -");
			
			AddMenuItem(menu, "job", "Votre job est : Banquier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 26)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "A.Banquier -");
			
			AddMenuItem(menu, "job", "Votre job est : banquier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 27)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "C. Hôpital -");
			
			AddMenuItem(menu, "job", "Votre job est : Chef Hôpital.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 28)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "Médecin -");
			
			AddMenuItem(menu, "job", "Votre job est : Médecin.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		} 
		else if (jobid[client] == 29)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "Infirmier -");
			
			AddMenuItem(menu, "job", "Votre job est : Infirmier.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		else if (jobid[client] == 30)
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
			CS_SetClientClanTag(client, "Chirurgien -");
			
			AddMenuItem(menu, "job", "Votre job est : Chirurgien.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Tapez !rp pour voir les commandes.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Veuillez ne pas faire d'abus.", ITEMDRAW_DISABLED); 
			AddMenuItem(menu, "job", "Votre salaire est à 00h00.", ITEMDRAW_DISABLED);
		}
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		
		chooseskin(client);
		
		disarm(client);
		
		GivePlayerItem(client, "weapon_knife");
		
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
		}
		PrintToChat(client, "%s : Bienvenue sur le Roleplay %s.", LOGO, TEAM);
		PrintToChat(client, "%s : Veuillez rapporter les bug sur notre forum : %s", LOGO, FORUM);
	}
}

public GetInfos(client)
{
	if (IsClientInGame(client))
	{
		new String:SteamId[32], String:Player_name[64];
		GetClientAuthString(client, SteamId, sizeof(SteamId));
		GetClientName(client, Player_name, sizeof(Player_name));
		
		new bool:already = false;
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

		if (connection)
		{
			new String:select[999];
			Format(select, sizeof(select),"SELECT cash, bank, jobid, jailtime, isinjail, permislourd, permisleger, cb, rib FROM `Roleplay_Players` WHERE steam_id = '%s'", SteamId);
			Select = SQL_Query(db_rp, select);
			
			if (Select == INVALID_HANDLE)
			{
				new String:error[255];
				SQL_GetError(db_rp, error, sizeof(error));
				PrintToServer("Failed to query (error: %s)", error);
				already = false;
			}
			else
			{
				if (SQL_FetchRow(Select))
				{
					money[client] = SQL_FetchInt(Select, 0);
					bank[client] = SQL_FetchInt(Select, 1);
					jobid[client] = SQL_FetchInt(Select, 2);
					g_jailtime[client] = SQL_FetchInt(Select, 3);
					g_IsInJail[client] = SQL_FetchInt(Select, 4);
					permislourd[client] = SQL_FetchInt(Select, 5);
					permisleger[client] = SQL_FetchInt(Select, 6);
					cb[client] = SQL_FetchInt(Select, 7);
					rib[client] = SQL_FetchInt(Select, 8);
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					already = true;
				
					if (money[client] < 0)
					{
						money[client] = 0;
					}
					if (bank[client] < 0)
					{
						bank[client] = 0;
					}
					if (g_jailtime[client] < 0)
					{
						g_jailtime[client] = 0;
					}
					CloseHandle(Select);
				}
			}
			
			if (!already)
			{
				new String:insert[999];
				Format(insert, sizeof(insert),"INSERT INTO Roleplay_Players VALUES ('%s', '%s', 0, 10000, 0, 0, 0, 0, 0, 0, 0)", SteamId, Player_name);
				Insert = SQL_Query(db_rp, insert);
				CloseHandle(Insert);
				
				PrintToChatAll("%s : Un nouveau joueurs a rejoins la population.", LOGO);
				PrintToChatAll("%s : Bienvenue à \x04%s \x01.", LOGO, Player_name);
	
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
		}
	}
}

public GetSucces(client)
{
	if (IsClientInGame(client))
	{
		new String:SteamId[32], String:Player_name[64];
		GetClientAuthString(client, SteamId, sizeof(SteamId));
		GetClientName(client, Player_name, sizeof(Player_name));
		
		new bool:already = false;

		if (connection)
		{
			new String:select[999];
			Format(select, sizeof(select),"SELECT headshot, countheadshot, porte20, porte50, porte100, countporte FROM `Roleplay_Succes` WHERE steam_id = '%s'", SteamId);
			Select = SQL_Query(db_rp, select);
			
			if (Select == INVALID_HANDLE)
			{
				new String:error[255];
				SQL_GetError(db_rp, error, sizeof(error));
				PrintToServer("Failed to query (error: %s)", error);
				already = false;
			}
			else
			{
				if (SQL_FetchRow(Select))
				{
					g_succesheadshot[client] = SQL_FetchInt(Select, 0);
					g_headshot[client] = SQL_FetchInt(Select, 1);
					g_succesporte20[client] = SQL_FetchInt(Select, 2);
					g_succesporte50[client] = SQL_FetchInt(Select, 3);
					g_succesporte100[client] = SQL_FetchInt(Select, 4);
					g_porte[client] = SQL_FetchInt(Select, 5);
					
					already = true;
				
					if (money[client] < 0)
					{
						money[client] = 0;
					}
					if (bank[client] < 0)
					{
						bank[client] = 0;
					}
					CloseHandle(Select);
				}
			}
			
			if (!already)
			{
				new String:insert[999];
				Format(insert, sizeof(insert),"INSERT INTO Roleplay_Succes VALUES ('%s', '%s', 0, 0, 0, 0, 0, 0)", SteamId, Player_name);
				Insert = SQL_Query(db_rp, insert);
				CloseHandle(Insert);
			}
		}
	}
}

public GetCapital()
{
	if (g_bIsMapLoaded)
	{
		new bool:already = false;

		if (connection)
		{
			new String:select[999];
			Format(select, sizeof(select),"SELECT capital FROM `Roleplay_Job` WHERE id = '1'");
			Select = SQL_Query(db_rp, select);
			
			if (Select == INVALID_HANDLE)
			{
				new String:error[255];
				SQL_GetError(db_rp, error, sizeof(error));
				PrintToServer("Failed to query (error: %s)", error);
				already = false;
			}
			else
			{
				if (SQL_FetchRow(Select))
				{
					capital[serveur] = SQL_FetchInt(Select, 0);
					
					already = true;
	
					CloseHandle(Select);
				}
			}
			
			if (!already)
			{
				new String:insert[999];
				Format(insert, sizeof(insert),"INSERT INTO Roleplay_Job VALUES ('1', 1000000)");
				Insert = SQL_Query(db_rp, insert);
				CloseHandle(Insert);
			}
		}
	}
}

public GetItem(client)
{
	if (IsClientInGame(client))
	{
		new String:SteamId[32], String:Player_name[64];
		GetClientAuthString(client, SteamId, sizeof(SteamId));
		GetClientName(client, Player_name, sizeof(Player_name));
		
		new bool:ok = false;

		if (connection)
		{
			new String:select[999];
			Format(select, sizeof(select),"SELECT kitcrochetage, ak47, awp, m249, scout, sg550, sg552, ump, tmp, mp5, deagle, usp, glock, xm1014, m3, m4a1, aug, galil, mac10, famas, p90, elite, ticket10, ticket100, ticket1000, levelcut, cartouche, props1, props2, heroine, exta, lsd, coke FROM `Roleplay_item` WHERE steam_id = '%s'", SteamId);
			Select = SQL_Query(db_rp, select);
			
			if (Select == INVALID_HANDLE)
			{
				new String:error[255];
				SQL_GetError(db_rp, error, sizeof(error));
				PrintToServer("Failed to query (error: %s)", error);
				ok = false;
			}
			else
			{
				if (SQL_FetchRow(Select))
				{
					kitcrochetage[client] = SQL_FetchInt(Select, 0);
					ak47[client] = SQL_FetchInt(Select, 1);
					awp[client] = SQL_FetchInt(Select, 2);
					m249[client] = SQL_FetchInt(Select, 3);
					scout[client] = SQL_FetchInt(Select, 4);
					sg550[client] = SQL_FetchInt(Select, 5);
					sg552[client] = SQL_FetchInt(Select, 6);
					ump[client] = SQL_FetchInt(Select, 7);
					tmp[client] = SQL_FetchInt(Select, 8);
					mp5[client] = SQL_FetchInt(Select, 9);
					deagle[client] = SQL_FetchInt(Select, 10);
					usp[client] = SQL_FetchInt(Select, 11);
					glock[client] = SQL_FetchInt(Select, 12);
					xm1014[client] = SQL_FetchInt(Select, 13);
					m3[client] = SQL_FetchInt(Select, 14);
					m4a1[client] = SQL_FetchInt(Select, 15);
					aug[client] = SQL_FetchInt(Select, 16);
					galil[client] = SQL_FetchInt(Select, 17);
					mac10[client] = SQL_FetchInt(Select, 18);
					famas[client] = SQL_FetchInt(Select, 19);
					p90[client] = SQL_FetchInt(Select, 20);
					elite[client] = SQL_FetchInt(Select, 21);
					ticket10[client] = SQL_FetchInt(Select, 22);
					ticket100[client] = SQL_FetchInt(Select, 23);
					ticket1000[client] = SQL_FetchInt(Select, 24);
					levelcut[client] = SQL_FetchInt(Select, 25);
					cartouche[client] = SQL_FetchInt(Select, 26);
					props1[client] = SQL_FetchInt(Select, 27);
					props2[client] = SQL_FetchInt(Select, 28);
					heroine[client] = SQL_FetchInt(Select, 29);
					exta[client] = SQL_FetchInt(Select, 30);
					lsd[client] = SQL_FetchInt(Select, 31);
					coke[client] = SQL_FetchInt(Select, 32);
					
					ok = true;
					
					CloseHandle(Select);
				}
			}
			
			if (!ok)
			{
				new String:insert[999];
				Format(insert, sizeof(insert),"INSERT INTO Roleplay_item VALUES ('%s', '%s', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)", SteamId, Player_name);
				Insert = SQL_Query(db_rp, insert);
				CloseHandle(Insert);
			}
		}
	}
}

public Menu_Bank(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "Deposit"))
		{
			if (rib[client] == 1)
			{
				new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
				money[client] = GetEntData(client, MoneyOffset, 4);
				
				if (money[client] <= 0)
				{
					PrintToChat(client, "%s : Vous n'avez pas d'argent a déposé.", LOGO);		
				}
				
				new Handle:menub = CreateMenu(deposit_menu);
				SetMenuTitle(menu, "Choisis la somme :");
				
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
					SetMenuTitle(menu, "Choisis la somme :");
					
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

public disarm(player)
{
	new wepIdx;
	for (new f = 0; f < 6; f++)
		if (f < 6 && (wepIdx = GetPlayerWeaponSlot(player, f)) != -1)  
			RemovePlayerItem(player, wepIdx);
}

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
		
		if ((Ent == 1276) || (Ent == 1275))
		{
			if (Ent != -1)
			{
				if (StrEqual(SteamId, "STEAM_0:0:27345284") || jobid [client] == 1 || jobid [client] == 2 || jobid [client] == 3)
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
			return Plugin_Continue;
		}
		
		if ((jobid[client] == 1) || (jobid[client] == 2) || (jobid[client] == 3))
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
		
		if ((Ent == 1276) || (Ent == 1275))
		{
			if (StrEqual(SteamId, "STEAM_0:0:27345284") || jobid [client] == 1 || jobid [client] == 2 || jobid [client] == 3)
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
							PrintToChat(client, "%s : Bienvenue chez toi \x03%N.", LOGO, client);
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
			return Plugin_Continue;
		}
		
		if ((jobid[client] == 1) || (jobid[client] == 2) || (jobid[client] == 3))
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
	}
	return Plugin_Continue;
}

public Action:HudTimer(Handle:timer, any:client)
{
	new Handle:hBuffer = StartMessageOne("KeyHintText", client);
	
	new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	money[client] = GetEntData(client, MoneyOffset, 4);
	
	new String:RealZone[999];
	
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
	else if (IsInMafia(client))
	{
		Format(RealZone, sizeof(RealZone), "Planque Mafia");
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
	else if (IsInJail1(client))
	{
		Format(RealZone, sizeof(RealZone), "Cellule n° 1");
	}
	else if (IsInJail2(client))
	{
		Format(RealZone, sizeof(RealZone), "Cellule n° 2");
	}
	else if (IsInJail3(client))
	{
		Format(RealZone, sizeof(RealZone), "Cellule n° 3");
	}
	else if (IsInJail4(client))
	{
		Format(RealZone, sizeof(RealZone), "Cellule n° 4");
	}
	else
	{
		Format(RealZone, sizeof(RealZone), "Extérieur");
	}
	
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
				if (jobid[client] == 1)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef d'état\nEntreprise : Etat d'oviscity\nSalaire : 500$\nCapitale : %i$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], capital[serveur], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 0)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Sans-Emploi\nEntreprise : Aucune\nSalaire : 50$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 2)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Agent CIA\nEntreprise : Etat d'oviscity\nSalaire : 400$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 3)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Agent du FBI\nEntreprise : Etat d'oviscity\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 4)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Policier\nEntreprise : Etat d'oviscity\nSalaire : 200$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 5)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Gardien\nEntreprise : Etat d'oviscity\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 6)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Mafia\nEntreprise : Mafia d'oviscity\nSalaire : 500$\nCapitale : %i$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], capital[serveur], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 7)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Mafieux\nEntreprise : Mafia d'oviscity\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 8)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Mafieux\nEntreprise : Mafia d'oviscity\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 9)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Dealer\nEntreprise : Dealer d'oviscity\nSalaire : 500$\nCapitale : %i$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], capital[serveur], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 10)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Dealer\nEntreprise : Dealer d'oviscity\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 11)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Dealer\nEntreprise : Dealer d'oviscity\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 12)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Coach\nEntreprise : Coach d'oviscity\nSalaire : 500$\nCapitale : %i$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], capital[serveur], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 13)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Coach\nEntreprise : Coach d'oviscity\nSalaire : 300$\nHorloge : %i%i:%i%i\nLevel cut : %i\nZone : %s\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 14)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Coach\nEntreprise : Coach d'oviscity\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 15)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Ebay\nEntreprise : Ebay d'oviscity\nSalaire : 500$\nCapitale : %i$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], capital[serveur], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 16)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Vendeur Ebay\nEntreprise : Ebay d'oviscity\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 17)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Vendeur Ebay\nEntreprise : Ebay d'oviscity\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 18)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Armurie\nEntreprise : Armurie d'oviscity\nSalaire : 500$\nCapitale : %i$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], capital[serveur], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 19)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Armurier\nEntreprise : Armurie d'oviscity\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 20)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Armurier\nEntreprise : Armurie d'oviscity\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 21)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Loto\nEntreprise : Loto d'oviscity\nSalaire : 500$\nCapitale : %i$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], capital[serveur], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 22)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Vendeur de Tickets\nEntreprise : Loto d'oviscity\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 23)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Vendeur de Tickets\nEntreprise : Loto d'oviscity\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 24)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Banquier\nEntreprise : Banque d'oviscity\nSalaire : 500$\nCapitale : %i$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], capital[serveur], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 25)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Banquier\nEntreprise : Banque d'oviscity\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 26)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Banquier\nEntreprise : Banque d'oviscity\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 27)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Hôpital\nEntreprise : Hôpital d'oviscity\nSalaire : 500$\nCapitale : %i$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], capital[serveur], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 28)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Médecin\nEntreprise : Hôpital d'oviscity\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 29)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Infirmier\nEntreprise : Hôpital d'oviscity\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
				else if (jobid[client] == 30)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chirurgien\nEntreprise : Hôpital d'oviscity\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nLevel cut : %i\nPermis Lourd : %s\nPermis Léger : %s\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, levelcut[client], (permislourd[client] > 0 ? "Oui" : "Non"), (permisleger[client] > 0 ? "Oui" : "Non"));
				}
			}
			else
			{
				if (jobid[client] == 1)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef d'état\nSalaire : 500$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 0)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Sans-Emploi\nSalaire : 50$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 2)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Agent CIA\nSalaire : 400$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 3)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Agent du FBI\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 4)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Policier\nSalaire : 200$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 5)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Gardien\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 6)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Mafia\nSalaire : 500$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 7)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Mafieux\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 8)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Mafieux\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 9)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Dealer\nSalaire : 500$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 10)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Dealer\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 11)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Dealer\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 12)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Coach\nSalaire : 500$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 13)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Coach\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 14)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Coach\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 15)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Ebay\nSalaire : 500$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 16)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Vendeur Ebay\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 17)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Vendeur Ebay\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 18)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Armurie\nSalaire : 500$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 19)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Armurier\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 20)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Armurier\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 21)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Loto\nSalaire : 500$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 22)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Vendeur de Tickets\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 23)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Vendeur de Tickets\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 24)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Banquier\nSalaire : 500$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 25)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Banquier\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 26)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Apprenti Banquier\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 27)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chef Hôpital\nSalaire : 500$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 28)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Médecin\nSalaire : 300$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 29)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Infirmier\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
				else if (jobid[client] == 30)
				{
					Format(tmptext, sizeof(tmptext), "Argent : %i$\nEn banque : %i$\nMétier : Chirurgien\nSalaire : 100$\nHorloge : %i%i:%i%i\nZone : %s\nTemps de jail : %is\n", money[client], bank[client], g_countheure1, g_countheure2, g_countminute1, g_countminute2, RealZone, g_jailtime[client]);
				}
			}
			BfWriteByte(hBuffer, 1); 
			BfWriteString(hBuffer, tmptext); 
			EndMessage();
		}
	}
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
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

		DBSaveItem(client);
		DBSave(client);
		DBSaveSucces(client);
		
		fTrashTimer(client);
		
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
		SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		KillTazer(client);
		
		gObj[client] = -1;
	}
}

fTrashTimer(client)
{
	if(TimerHud[client] != INVALID_HANDLE)
	{
		KillTimer(TimerHud[client]);
		TimerHud[client] = INVALID_HANDLE;
	}
	if (g_booldead[client])
	{
		KillTimer(g_deadtimer[client]);
		g_booldead[client] =  false;
	}
	if (g_booljail[client])
	{
		KillTimer(g_jailtimer[client]);
		g_booljail[client] =  false;
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
	if (g_boolreturn[client])
	{
		KillTimer(g_jailreturn[client]);
		g_boolreturn[client] =  false;
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

public DBSave(client)
{
	new String:SteamId[32], String:query[256];
	GetClientAuthString(client, SteamId, sizeof(SteamId));

	Format(query, sizeof(query), "UPDATE Roleplay_Players SET cash = %i, bank = %i, jobid = %i, jailtime = %i, isinjail = %i, permislourd = %i, permisleger = %i, cb = %i, rib = %i WHERE steam_id = '%s'", money[client], bank[client], jobid[client], g_jailtime[client], g_IsInJail[client], permislourd[client], permisleger[client], cb[client], rib[client], SteamId);				
	SQL_FastQuery(db_rp, query);
	
	PrintToServer("Le joueur %N a été sauvegardé.", client);
}

public DBSaveSucces(client)
{
	new String:SteamId[32], String:query[256];
	GetClientAuthString(client, SteamId, sizeof(SteamId));

	Format(query, sizeof(query), "UPDATE Roleplay_Succes SET headshot = %i, countheadshot = %i, porte20 = %i, porte50 = %i, porte100 = %i, countporte = %i WHERE steam_id = '%s'", g_succesheadshot[client], g_headshot[client], g_succesporte20[client], g_succesporte50[client], g_succesporte100[client], g_porte[client], SteamId);				
	SQL_FastQuery(db_rp, query);
	
	PrintToServer("Les succès du joueur %N ont été sauvegardé.", client);
}

public DBSaveItem(client)
{
	new String:SteamID[32], String:queryy[999];
	GetClientAuthString(client, SteamID, sizeof(SteamID));

	Format(queryy, sizeof(queryy), "UPDATE Roleplay_item SET kitcrochetage = %i, ak47 = %i, awp = %i, m249 = %i, scout = %i, sg550 = %i, sg552 = %i, ump = %i, tmp = %i, mp5 = %i, deagle = %i, usp = %i, glock = %i, xm1014 = %i, m3 = %i, m4a1 = %i, aug = %i, galil = %i, mac10 = %i, famas = %i, p90 = %i, elite = %i, ticket10 = %i, ticket100 = %i, ticket100 = %i, levelcut = %i, cartouche = %i, props1 = %i, props2 = %i, heroine = %i, exta = %i, lsd = %i, coke = %i WHERE steam_id = '%s'", kitcrochetage[client], ak47[client], awp[client], m249[client], scout[client], sg550[client], sg552[client], ump[client], tmp[client], mp5[client], deagle[client], usp[client], glock[client], xm1014[client], m3[client], m4a1[client], aug[client], galil[client], mac10[client], famas[client], p90[client], elite[client], ticket10[client], ticket100[client], ticket1000[client], levelcut[client], cartouche[client], props1[client], props2[client], heroine[client], exta[client], lsd[client], coke[client], SteamID);				
	SQL_FastQuery(db_rp, queryy);
	
	PrintToServer("Les items du joueur %N ont été sauvegardé.", client);
}

public DBSaveCapital()
{
	new String:query[256];
	Format(query, sizeof(query), "UPDATE Roleplay_Job SET capital = %i WHERE id = '1'", capital[serveur]);				
	SQL_FastQuery(db_rp, query);
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
			SetEntityHealth(client, 100);
		}
		else
		{
			CS_SwitchTeam(client, 3);
			CS_SetClientClanTag(client, "C. Police -");
			PrintToChat(client, "%s : Vous êtes désormais en flic.", LOGO);
			SetEntityModel(client, "models/player/pil/re1/wesker/wesker_pil.mdl");
			SetEntityHealth(client, 500);
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
			SetEntityHealth(client, 100);
		}
		else
		{
			CS_SwitchTeam(client, 3);
			CS_SetClientClanTag(client, "Agent CIA -");
			PrintToChat(client, "%s : Vous êtes désormais en flic.", LOGO);
			SetEntityModel(client, "models/player/rocknrolla/ct_urban.mdl");
			SetEntityHealth(client, 400);
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
			SetEntityHealth(client, 100);
		}
		else
		{
			CS_SwitchTeam(client, 3);
			CS_SetClientClanTag(client, "Agent du FBI -");
			PrintToChat(client, "%s : Vous êtes désormais en flic.", LOGO);
			SetEntityModel(client, "models/player/ics/ct_gign_fbi/ct_gign.mdl");
			SetEntityHealth(client, 300);
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
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if (GetClientTeam(client) == 3)
			{
				h[client] = GetClientAimTarget(client, true);
				
				if(h[client] != -1)
				{
					if (g_invisible[client] == 0)
					{
						TransactionWith[client] = h[client];
						TransactionWith[h[client]] = client;
						
						if (h[client] < 1 || h[client] > MaxClients) 
						{
							PrintToChat(client, "%s : Vous devez visé un joueurs", LOGO);
							return Plugin_Handled; 
						}
						
						new Float:entorigin[3], Float:clientent[3];
						GetEntPropVector(h[client], Prop_Send, "m_vecOrigin", entorigin);
						GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
						new Float:distance = GetVectorDistance(entorigin, clientent);
						
						if (GetClientTeam(h[client]) == 2)
						{
							if (distance <= 1000)
							{
								switch (GetRandomInt(1, 4))
								{
									case 1:
									{
										TeleportEntity(h[client], Float:{ -984701973, -1001996089, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
									}
											
									case 2:
									{
										TeleportEntity(h[client], Float:{ -985977571, -1013839247, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
									}
										
									case 3:
									{
										TeleportEntity(h[client], Float:{ -985179530, -1014029130, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
									}
										
									case 4:
									{
										TeleportEntity(h[client], Float:{ -984701973, -1001996089, -1008796672 }, NULL_VECTOR, NULL_VECTOR);
									}
								}
								
								PrintToChat(client, "%s : Tu as emprisonné le joueurs : %N", LOGO, h[client]);
								PrintToChat(h[client], "%s  : Tu as été emprisonné par : %N", LOGO, client);
								
								disarm(h[client]);
								GivePlayerItem(h[client], "weapon_knife");
								SetClientListeningFlags(h[client], VOICE_MUTED);
								
								gObj[h[client]] = -1;
								grab[h[client]] = false;
								StopSound(h[client], SNDCHAN_AUTO, gSound);
								
								g_IsInJail[h[client]] = 1;
								
								new Handle:menu = CreateMenu(Menu_Jail);
								SetMenuTitle(menu, "Choisis la peine pour %N :", h[client]);
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
								
								if (g_booljail[h[client]])
								{
									KillTimer(g_jailtimer[h[client]]);
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
	return Plugin_Continue;
}

public Menu_Jail(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		if (IsClientInGame(h[client]))
		{
			if (h[client] != -1 && IsPlayerAlive(h[client]))
			{
				new String:info[64];
				GetMenuItem(menu, param2, info, sizeof(info));
				
				if (StrEqual(info, "meurtrep"))
				{
					PrintToChat(h[client], "%s : Vous avez été emprisonné pour meurtre sur policier.", LOGO);
					PrintToChat(client, "%s : La peine a bien été mise.", LOGO);
						
					new Handle:menua = CreateMenu(Caution_Mp);
					SetMenuTitle(menua, "Voulez-vous payé votre caution de 1000$ ?");
					AddMenuItem(menua, "oui", "Oui je veux.");
					AddMenuItem(menua, "non", "Non merci.");
					DisplayMenu(menua, h[client], MENU_TIME_FOREVER);
						
					g_jailtime[h[client]] = 480;
				}
				else if (StrEqual(info, "meurtrec"))
				{
					PrintToChat(h[client], "%s : Vous avez été emprisonné pour meurtre sur civil.", LOGO);
					PrintToChat(client, "%s : La peine a bien été mise.", LOGO);
					
					new Handle:menuc = CreateMenu(Caution_Mc);
					SetMenuTitle(menuc, "Voulez-vous payé votre caution de 800$ ?");
					AddMenuItem(menuc, "oui", "Oui je veux.");
					AddMenuItem(menuc, "non", "Non merci.");
					DisplayMenu(menuc, h[client], MENU_TIME_FOREVER);
					
					g_jailtime[h[client]] = 360;
				}
				else if (StrEqual(info, "tentative"))
				{
					PrintToChat(h[client], "%s : Vous avez été emprisonné pour tentative de meurtre.", LOGO);
					PrintToChat(client, "%s : La peine a bien été mise.", LOGO);
					
					new Handle:menub = CreateMenu(Caution_Tentative);
					SetMenuTitle(menub, "Voulez-vous payé votre caution de 500$ ?");
					AddMenuItem(menub, "oui", "Oui je veux.");
					AddMenuItem(menub, "non", "Non merci.");
					DisplayMenu(menub, h[client], MENU_TIME_FOREVER);
					
					g_jailtime[h[client]] = 300;
				}
				else if (StrEqual(info, "crochetage"))
				{
					PrintToChat(h[client], "%s : Vous avez été emprisonné pour crochetage.", LOGO);
					PrintToChat(client, "%s : La peine a bien été mise.", LOGO);
					
					new Handle:menud = CreateMenu(Caution_Crochetage);
					SetMenuTitle(menud, "Voulez-vous payé votre caution de 200$ ?");
					AddMenuItem(menud, "oui", "Oui je veux.");
					AddMenuItem(menud, "non", "Non merci.");
					DisplayMenu(menud, h[client], MENU_TIME_FOREVER);
					
					g_jailtime[h[client]] = 180;
				}
				else if (StrEqual(info, "vol"))
				{
					PrintToChat(h[client], "%s : Vous avez été emprisonné pour vol.", LOGO);
					PrintToChat(client, "%s : La peine a bien été mise.", LOGO);
					
					new Handle:menue = CreateMenu(Caution_Vol);
					SetMenuTitle(menue, "Voulez-vous payé votre caution de 200$ ?");
					AddMenuItem(menue, "oui", "Oui je veux.");
					AddMenuItem(menue, "non", "Non merci.");
					DisplayMenu(menue, h[client], MENU_TIME_FOREVER);
					
					g_jailtime[h[client]] = 180;
				}
				else if (StrEqual(info, "nuisances"))
				{
					PrintToChat(h[client], "%s : Vous avez été emprisonné pour nuisances sonores.", LOGO);
					PrintToChat(client, "%s : La peine a bien été mise.", LOGO);
					
					new Handle:menuf = CreateMenu(Caution_Nuisance);
					SetMenuTitle(menuf, "Voulez-vous payé votre caution de 500$ ?");
					AddMenuItem(menuf, "oui", "Oui je veux.");
					AddMenuItem(menuf, "non", "Non merci.");
					DisplayMenu(menuf, h[client], MENU_TIME_FOREVER);
					
					g_jailtime[h[client]] = 240;
				}
				else if (StrEqual(info, "insultes"))
				{
					PrintToChat(h[client], "%s : Vous avez été emprisonné pour insultes.", LOGO);
					PrintToChat(client, "%s : La peine a bien été mise.", LOGO);
					
					new Handle:menug = CreateMenu(Caution_Insulte);
					SetMenuTitle(menug, "Voulez-vous payé votre caution de 600$ ?");
					AddMenuItem(menug, "oui", "Oui je veux.");
					AddMenuItem(menug, "non", "Non merci.");
					DisplayMenu(menug, h[client], MENU_TIME_FOREVER);
					
					g_jailtime[h[client]] = 240;
				}
				else if (StrEqual(info, "permis"))
				{
					PrintToChat(h[client], "%s : Vous avez été emprisonné pour possession d'armes illégales.", LOGO);
					PrintToChat(client, "%s : La peine a bien été mise.", LOGO);
					
					new Handle:menuh = CreateMenu(Caution_Permis);
					SetMenuTitle(menuh, "Voulez-vous payé votre caution de 600$ ?");
					AddMenuItem(menuh, "oui", "Oui je veux.");
					AddMenuItem(menuh, "non", "Non merci.");
					DisplayMenu(menuh, h[client], MENU_TIME_FOREVER);
					
					g_jailtime[h[client]] = 300;
				}
				else if (StrEqual(info, "intrusion"))
				{
					PrintToChat(h[client], "%s : Vous avez été emprisonné pour intrusion.", LOGO);
					PrintToChat(client, "%s : La peine a bien été mise.", LOGO);
					
					new Handle:menui = CreateMenu(Caution_Intrusion);
					SetMenuTitle(menui, "Voulez-vous payé votre caution de 200$ ?");
					AddMenuItem(menui, "oui", "Oui je veux.");
					AddMenuItem(menui, "non", "Non merci.");
					DisplayMenu(menui, h[client], MENU_TIME_FOREVER);
					
					g_jailtime[h[client]] = 180;
				}
				else if (StrEqual(info, "tir"))
				{
					PrintToChat(h[client], "%s : Vous avez été emprisonné pour tir dans la rue.", LOGO);
					PrintToChat(client, "%s : La peine a bien été mise.", LOGO);
					
					new Handle:menuj = CreateMenu(Caution_Tir);
					SetMenuTitle(menuj, "Voulez-vous payé votre caution de 250$ ?");
					AddMenuItem(menuj, "oui", "Oui je veux.");
					AddMenuItem(menuj, "non", "Non merci.");
					DisplayMenu(menuj, h[client], MENU_TIME_FOREVER);
					
					g_jailtime[h[client]] = 180;
				}
				else if (StrEqual(info, "obstruction"))
				{
					PrintToChat(h[client], "%s : Vous avez été emprisonné pour obstruction envers la police.", LOGO);
					PrintToChat(client, "%s : La peine a bien été mise.", LOGO);
					
					new Handle:menuk = CreateMenu(Caution_Obstruction);
					SetMenuTitle(menuk, "Voulez-vous payé votre caution de 250$ ?");
					AddMenuItem(menuk, "oui", "Oui je veux.");
					AddMenuItem(menuk, "non", "Non merci.");
					DisplayMenu(menuk, h[client], MENU_TIME_FOREVER);
					
					g_jailtime[h[client]] = 120;
				}
				else if (StrEqual(info, "evasion"))
				{
					PrintToChat(h[client], "%s : Vous avez été emprisonné pour Tentative d'évasion.", LOGO);
					PrintToChat(client, "%s : La peine a bien été mise.", LOGO);
					
					new Handle:menuk = CreateMenu(Caution_Evasion);
					SetMenuTitle(menuk, "Voulez-vous payé votre caution de 400$ ?");
					AddMenuItem(menuk, "oui", "Oui je veux.");
					AddMenuItem(menuk, "non", "Non merci.");
					DisplayMenu(menuk, h[client], MENU_TIME_FOREVER);
					
					g_jailtime[h[client]] = 200;
				}
				else if (StrEqual(info, "liberation"))
				{
					g_jailtime[h[client]] = 10;
				}
				CreateTimer(1.0, Timer_Setjail, h[client]);
			}
		}
	}
}

public Action:Timer_Setjail(Handle:timer, any:client)
{
	g_booljail[client] = true;

	g_jailtimer[client] =  CreateTimer(1.0, Jail_Raison, client, TIMER_REPEAT);
}

public Caution_Mp(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new policier = TransactionWith[client]; 
		
		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 1000)
			{
				PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
				PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
				money[client] = money[client] - 1000;
				AdCash(policier, 500);
				
				capital[serveur] = capital[serveur] + 500;
				
				g_jailtime[client] = 240;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1000)
					{
						PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
						PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
						bank[client] = bank[client] - 1000;
						AdCash(policier, 500);
				
						capital[serveur] = capital[serveur] + 500;
				
						g_jailtime[client] = 240;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						
						g_jailtime[client] = 480;
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					
					g_jailtime[client] = 480;
				}
			}
		}
		else if (StrEqual(info, "non"))
		{
			PrintToChat(policier, "%s : Le joueur %N a refusé de payé sa caution.", LOGO, client);
			PrintToChat(client, "%s : Vous avez refusé de payé votre caution.", LOGO);
			
			g_jailtime[client] = 480;
		}
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	}
}

public Caution_Mc(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new policier = TransactionWith[client]; 

		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 800)
			{
				PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
				PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
				money[client] = money[client] - 800;
				AdCash(policier, 400);
				
				capital[serveur] = capital[serveur] + 400;
				
				g_jailtime[client] = 180;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 800)
					{
						PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
						PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
						bank[client] = bank[client] - 800;
						AdCash(policier, 400);
				
						capital[serveur] = capital[serveur] + 400;
				
						g_jailtime[client] = 180;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						
						g_jailtime[client] = 360;
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					
					g_jailtime[client] = 360;
				}
			}
		}
		else if (StrEqual(info, "non"))
		{
			PrintToChat(policier, "%s : Le joueur %N a refusé de payé sa caution.", LOGO, client);
			PrintToChat(client, "%s : Vous avez refusé de payé votre caution.", LOGO);
			
			g_jailtime[client] = 360;
		}
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	}
}

public Caution_Tentative(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new policier = TransactionWith[client]; 

		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 500)
			{
				PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
				PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
				money[client] = money[client] - 500;
				AdCash(policier, 250);
				
				capital[serveur] = capital[serveur] + 250;
				
				g_jailtime[client] = 150;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 500)
					{
						PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
						PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
						bank[client] = bank[client] - 500;
						AdCash(policier, 250);
				
						capital[serveur] = capital[serveur] + 250;
				
						g_jailtime[client] = 150;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						
						g_jailtime[client] = 300;
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					
					g_jailtime[client] = 300;
				}
			}
		}
		else if (StrEqual(info, "non"))
		{
			PrintToChat(policier, "%s : Le joueur %N a refusé de payé sa caution.", LOGO, client);
			PrintToChat(client, "%s : Vous avez refusé de payé votre caution.", LOGO);
			
			g_jailtime[client] = 300;
		}
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	}
}

public Caution_Crochetage(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new policier = TransactionWith[client]; 

		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 200)
			{
				PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
				PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
				money[client] = money[client] - 200;
				AdCash(policier, 100);
				
				capital[serveur] = capital[serveur] + 100;
				
				g_jailtime[client] = 90;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 200)
					{
						PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
						PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
						bank[client] = bank[client] - 200;
						AdCash(policier, 100);
				
						capital[serveur] = capital[serveur] + 100;
				
						g_jailtime[client] = 90;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						
						g_jailtime[client] = 180;
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					
					g_jailtime[client] = 180;
				}
			}
		}
		else if (StrEqual(info, "non"))
		{
			PrintToChat(policier, "%s : Le joueur %N a refusé de payé sa caution.", LOGO, client);
			PrintToChat(client, "%s : Vous avez refusé de payé votre caution.", LOGO);
			
			g_jailtime[client] = 180;
		}
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	}
}

public Caution_Vol(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new policier = TransactionWith[client]; 

		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 200)
			{
				PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
				PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
				money[client] = money[client] - 200;
				AdCash(policier, 100);
				
				capital[serveur] = capital[serveur] + 100;
				
				g_jailtime[client] = 90;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 200)
					{
						PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
						PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
						bank[client] = bank[client] - 200;
						AdCash(policier, 100);
				
						capital[serveur] = capital[serveur] + 100;
				
						g_jailtime[client] = 90;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						
						g_jailtime[client] = 180;
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					
					g_jailtime[client] = 180;
				}
			}
		}
		else if (StrEqual(info, "non"))
		{
			PrintToChat(policier, "%s : Le joueur %N a refusé de payé sa caution.", LOGO, client);
			PrintToChat(client, "%s : Vous avez refusé de payé votre caution.", LOGO);
			
			g_jailtime[client] = 180;
		}
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	}
}

public Caution_Nuisance(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new policier = TransactionWith[client]; 
		
		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 500)
			{
				PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
				PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
				money[client] = money[client] - 500;
				AdCash(policier, 250);
				
				capital[serveur] = capital[serveur] + 250;
				
				g_jailtime[client] = 120;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 500)
					{
						PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
						PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
						bank[client] = bank[client] - 500;
						AdCash(policier, 250);
				
						capital[serveur] = capital[serveur] + 250;
				
						g_jailtime[client] = 120;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						
						g_jailtime[client] = 240;
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					
					g_jailtime[client] = 240;
				}
			}
		}
		else if (StrEqual(info, "non"))
		{
			PrintToChat(policier, "%s : Le joueur %N a refusé de payé sa caution.", LOGO, client);
			PrintToChat(client, "%s : Vous avez refusé de payé votre caution.", LOGO);
			
			g_jailtime[client] = 240;
		}
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	}
}

public Caution_Insulte(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new policier = TransactionWith[client]; 

		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 600)
			{
				PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
				PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
				money[client] = money[client] - 600;
				AdCash(policier, 300);
				
				capital[serveur] = capital[serveur] + 300;
				
				g_jailtime[client] = 120;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 600)
					{
						PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
						PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
						bank[client] = bank[client] - 600;
						AdCash(policier, 300);
				
						capital[serveur] = capital[serveur] + 300;
				
						g_jailtime[client] = 120;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						
						g_jailtime[client] = 240;
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					
					g_jailtime[client] = 240;
				}
			}
		}
		else if (StrEqual(info, "non"))
		{
			PrintToChat(policier, "%s : Le joueur %N a refusé de payé sa caution.", LOGO, client);
			PrintToChat(client, "%s : Vous avez refusé de payé votre caution.", LOGO);
			
			g_jailtime[client] = 240;
		}
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	}
}

public Caution_Permis(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new policier = TransactionWith[client]; 

		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 600)
			{
				PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
				PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
				money[client] = money[client] - 600;
				AdCash(policier, 300);
				
				capital[serveur] = capital[serveur] + 300;
				
				g_jailtime[client] = 150;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 600)
					{
						PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
						PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
						bank[client] = bank[client] - 600;
						AdCash(policier, 300);
				
						capital[serveur] = capital[serveur] + 300;
				
						g_jailtime[client] = 150;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						
						g_jailtime[client] = 300;
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					
					g_jailtime[client] = 300;
				}
			}
		}
		else if (StrEqual(info, "non"))
		{
			PrintToChat(policier, "%s : Le joueur %N a refusé de payé sa caution.", LOGO, client);
			PrintToChat(client, "%s : Vous avez refusé de payé votre caution.", LOGO);
			
			g_jailtime[client] = 300;
		}
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	}
}

public Caution_Intrusion(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new policier = TransactionWith[client]; 

		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 200)
			{
				PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
				PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
				money[client] = money[client] - 200;
				AdCash(policier, 100);
				
				capital[serveur] = capital[serveur] + 100;
				
				g_jailtime[client] = 90;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 200)
					{
						PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
						PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
						bank[client] = bank[client] - 200;
						AdCash(policier, 100);
				
						capital[serveur] = capital[serveur] + 100;
				
						g_jailtime[client] = 90;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						
						g_jailtime[client] = 180;
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					
					g_jailtime[client] = 180;
				}
			}
		}
		else if (StrEqual(info, "non"))
		{
			PrintToChat(policier, "%s : Le joueur %N a refusé de payé sa caution.", LOGO, client);
			PrintToChat(client, "%s : Vous avez refusé de payé votre caution.", LOGO);
			
			g_jailtime[client] = 180;
		}
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu); 
	}
}

public Caution_Tir(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new policier = TransactionWith[client]; 

		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 250)
			{
				PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
				PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
				money[client] = money[client] - 250;
				AdCash(policier, 125);
				
				capital[serveur] = capital[serveur] + 125;
				
				g_jailtime[client] = 90;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 250)
					{
						PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
						PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
						bank[client] = bank[client] - 250;
						AdCash(policier, 125);
				
						capital[serveur] = capital[serveur] + 125;
				
						g_jailtime[client] = 90;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						
						g_jailtime[client] = 180;
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					
					g_jailtime[client] = 180;
				}
			}
		}
		else if (StrEqual(info, "non"))
		{
			PrintToChat(policier, "%s : Le joueur %N a refusé de payé sa caution.", LOGO, client);
			PrintToChat(client, "%s : Vous avez refusé de payé votre caution.", LOGO);
			
			g_jailtime[client] = 180;
		}
	}
	else if (action == MenuAction_End) 
	{ 
		CloseHandle(menu);
	}
}

public Caution_Obstruction(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new policier = TransactionWith[client]; 
		
		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 250)
			{
				PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
				PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
				money[client] = money[client] - 250;
				AdCash(policier, 125);
				
				capital[serveur] = capital[serveur] + 125;
				
				g_jailtime[client] = 60;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 250)
					{
						PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
						PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
						bank[client] = bank[client] - 250;
						AdCash(policier, 125);
				
						capital[serveur] = capital[serveur] + 125;
				
						g_jailtime[client] = 60;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						
						g_jailtime[client] = 120;
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					
					g_jailtime[client] = 120;
				}
			}
		}
		else if (StrEqual(info, "non"))
		{
			PrintToChat(policier, "%s : Le joueur %N a refusé de payé sa caution.", LOGO, client);
			PrintToChat(client, "%s : Vous avez refusé de payé votre caution.", LOGO);
			
			g_jailtime[client] = 120;
		}
	}
	else if (action == MenuAction_End)
	{ 
		CloseHandle(menu);
	}
}

public Caution_Evasion(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new policier = TransactionWith[client]; 
		
		if (StrEqual(info, "oui"))
		{
			if (money[client] >= 400)
			{
				PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
				PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
				money[client] = money[client] - 400;
				AdCash(policier, 200);
				
				capital[serveur] = capital[serveur] + 200;
				
				g_jailtime[client] = 100;
				
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 400)
					{
						PrintToChat(policier, "%s : Le joueur %N a payé sa caution.", LOGO, client); 
						PrintToChat(client, "%s : Vous avez payé votre caution.", LOGO); 
				
						bank[client] = bank[client] - 400;
						AdCash(policier, 200);
				
						capital[serveur] = capital[serveur] + 200;
				
						g_jailtime[client] = 100;
					}
					else
					{
						PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
						PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
						
						g_jailtime[client] = 200;
					}
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
					PrintToChat(policier, "%s : Le joueurs n'a pas assez d'argent.", LOGO);
					
					g_jailtime[client] = 200;
				}
			}
		}
		else if (StrEqual(info, "non"))
		{
			PrintToChat(policier, "%s : Le joueur %N a refusé de payé sa caution.", LOGO, client);
			PrintToChat(client, "%s : Vous avez refusé de payé votre caution.", LOGO);
			
			g_jailtime[client] = 200;
		}
	}
	else if (action == MenuAction_End)
	{ 
		CloseHandle(menu);
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
			
			g_boolreturn[client] = true;
			
			if (g_jailtime[client] == 0)
			{
				g_IsInJail[client] = 0;
				g_jailtime[client] = 0;
				
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
			
		if (distance <= 10000)
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
		
			new randomcolor = GetRandomInt(1, 5);
					
			if (randomcolor == 1)
			{
				TE_SetupBeamPoints(clientent, entorigin, g_LightingSprite, 0, 1, 0, 1.0, 20.0, 0.0, 2, 5.0, TAZER_COLORORANGE, 3);
	
				TE_SendToAll();
			}
			else if (randomcolor == 2)
			{
				TE_SetupBeamPoints(clientent, entorigin, g_LightingSprite, 0, 1, 0, 1.0, 20.0, 0.0, 2, 5.0, TAZER_COLORRED, 3);
						
				TE_SendToAll();
			}
			else if (randomcolor == 3)
			{
				TE_SetupBeamPoints(clientent, entorigin, g_LightingSprite, 0, 1, 0, 1.0, 20.0, 0.0, 2, 5.0, TAZER_COLORGREEN, 3);
	
				TE_SendToAll();
			}
			else if (randomcolor == 4)
			{
				TE_SetupBeamPoints(clientent, entorigin, g_LightingSprite, 0, 1, 0, 1.0, 20.0, 0.0, 2, 5.0, TAZER_COLORGRAY, 3);
	
				TE_SendToAll();
			}
			else if (randomcolor == 5)
			{
				TE_SetupBeamPoints(clientent, entorigin, g_LightingSprite, 0, 1, 0, 1.0, 20.0, 0.0, 2, 5.0, TAZER_COLORBLUE, 3);
	
				TE_SendToAll();
			}
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
				
				new random = GetRandomInt(1, 5);
				
				if (random == 1)
				{
					TE_SetupBeamRingPoint(entorigin, 45.0, 45.1, g_modelLaser, g_modelHalo, 0, 1, 0.1, 8.0, 1.0, TAZER_COLORORANGE, 1, 0);
				
					TE_SendToAll();
				}
				else if (random == 2)
				{
					TE_SetupBeamRingPoint(entorigin, 45.0, 45.1, g_modelLaser, g_modelHalo, 0, 1, 0.1, 8.0, 1.0, TAZER_COLORBLUE, 1, 0);
				
					TE_SendToAll();
				}
				else if (random == 3)
				{
					TE_SetupBeamRingPoint(entorigin, 45.0, 45.1, g_modelLaser, g_modelHalo, 0, 1, 0.1, 8.0, 1.0, TAZER_COLORGREEN, 1, 0);
				
					TE_SendToAll();
				}
				else if (random == 4)
				{
					TE_SetupBeamRingPoint(entorigin, 45.0, 45.1, g_modelLaser, g_modelHalo, 0, 1, 0.1, 8.0, 1.0, TAZER_COLORRED, 1, 0);
				
					TE_SendToAll();
				}
				else if (random == 5)
				{
					TE_SetupBeamRingPoint(entorigin, 45.0, 45.1, g_modelLaser, g_modelHalo, 0, 1, 0.1, 8.0, 1.0, TAZER_COLORGRAY, 1, 0);
				
					TE_SendToAll();
				}
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

public Action:Command_Vis(client, args)
{
	if ((jobid[client] == 1) || (jobid[client] == 2))
	{
		if (IsPlayerAlive(client))
		{
			if (GetEntityRenderMode(client) == RENDER_NONE)
			{
				Move_Visible(client);
				PrintToChat(client, "%s : Vous êtes désormais visible.", LOGO);
				g_invisible[client] = 0;
			}
			else
			{
				Move_Invisible(client);
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

public Move_Invisible(client)
{
	SetEntityRenderMode(client, RENDER_NONE);
	SetEntityRenderColor(client, 0, 0, 0, 0);
	
	new weaponid;
	
	for (new i = 0; i < 6; i++)
	{
		if (i < 6 && (weaponid = GetPlayerWeaponSlot(client, i)) != -1) 
		{
			SetEntityRenderMode(weaponid, RENDER_NONE);
			SetEntityRenderColor(weaponid, 0, 0, 0, 0);
		}
	}
}

public Move_Visible(client)
{
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	
	new weaponid;
	
	for (new i = 0; i < 6; i++)
	{
		if (i < 6 && (weaponid = GetPlayerWeaponSlot(client, i)) != -1) 
		{
			SetEntityRenderMode(weaponid, RENDER_NORMAL);
			SetEntityRenderColor(weaponid, 255, 255, 255, 255);
		}
	}
}

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

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (IsPlayerAlive(client))
	{
		if (!g_InUse[client] && buttons & IN_USE)
		{
			g_InUse[client] = true;
			
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
				
				if (IsInDistribMafia(Ent) || IsInDistribLoto(Ent) || IsInDistribBanque(Ent) || IsInDistribEbay(Ent))
				{
					new Float:origin[3], Float:clientent[3];
					GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
					new Float:distance = GetVectorDistance(origin, clientent);
					new Float:vec[3];
					GetClientAbsOrigin(client, vec);
					vec[2] += 10;
					
					if (distance <= 80)
					{
						if (rib[client] > 0)
						{
							new Handle:menu = CreateMenu(Menu_Bank);
							SetMenuTitle(menu, "Banque Oviscity :");
							AddMenuItem(menu, "Deposit", "Déposer de l'argent");
							AddMenuItem(menu, "Retired", "Retirer de l'argent");
							DisplayMenu(menu, client, MENU_TIME_FOREVER);
						}
						else
						{
							PrintToChat(client, "%s : Vous devez posséder un RIB.", LOGO);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous êtes trop loin de la banque.", LOGO);
					}
				}
				
				if (IsInMafia(Ent))
				{
					if ((jobid[client] == 6) || (jobid[client] == 7)  || (jobid[client] == 8))
					{
						if (kitcrochetage[client] < 20)
						{
							new kit = kitcrochetage[client] + 1;
							
							kitcrochetage[client] = kit;
							
							PrintToChat(client, "%s : Vous avez pris un kit de crochetage [%i/20].", LOGO, kitcrochetage[client]);
						}
						else
						{
							PrintToChat(client, "%s : Vous avez le maximum de kit de crochetage(%i)", LOGO, kitcrochetage[client]);
						}
					}
					else
					{
						PrintToChat(client, "%s : Vous devez être mafieux.", LOGO);
					}
				}
				
				if (IsInArmu(Ent))
				{
					new Float:origin[3], Float:clientent[3];
					GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
					new Float:distance = GetVectorDistance(origin, clientent);
					new Float:vec[3];
					GetClientAbsOrigin(client, vec);
					vec[2] += 10;
					
					if (distance <= 300)
					{
						new Handle:menu = CreateMenu(Menu_Armurie);
						SetMenuTitle(menu, "Armurie de oviscity :");
						AddMenuItem(menu, "awp", "AWP 4000$");
						AddMenuItem(menu, "m249", "M249 3000$");
						AddMenuItem(menu, "ak47", "AK47 2000$");
						AddMenuItem(menu, "m4a1", "M4A1 2000$");
						AddMenuItem(menu, "sg550", "SG550 1500$");
						AddMenuItem(menu, "sg552", "SG552 1500$");
						AddMenuItem(menu, "galil", "GALIL 1300$");
						AddMenuItem(menu, "aug", "AUG 1100$");
						AddMenuItem(menu, "famas", "FAMAS 1000$");
						AddMenuItem(menu, "scout", "SCOUT 800$");
						AddMenuItem(menu, "m3", "M3 800$");
						AddMenuItem(menu, "xm1014", "XM1014 800$");
						AddMenuItem(menu, "mp5", "MP5 700$");
						AddMenuItem(menu, "p90", "P90 700$");
						AddMenuItem(menu, "elite", "ELITES 650$");
						AddMenuItem(menu, "tmp", "TMP 600$");
						AddMenuItem(menu, "ump", "UMP 600$");
						AddMenuItem(menu, "mac10", "MAC10 500$");
						AddMenuItem(menu, "deagle", "DEAGLE 400$");
						AddMenuItem(menu, "usp", "USP 200$");
						AddMenuItem(menu, "glock", "GLOCK 200$");
						AddMenuItem(menu, "kartouche", "CARTOUCHE 150$");
						DisplayMenu(menu, client, MENU_TIME_FOREVER);
					}
					else
					{
						PrintToChat(client, "%s : vous êtes trop loin du PNJ.", LOGO);
					}
				}
				
				if (Ent == 1317)
				{
					new Float:origin[3], Float:clientent[3];
					GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
					new Float:distance = GetVectorDistance(origin, clientent);
					new Float:vec[3];
					GetClientAbsOrigin(client, vec);
					vec[2] += 10;
					
					if (distance <= 300)
					{
						new Handle:menu = CreateMenu(Menu_Serveur);
						SetMenuTitle(menu, "Agence de tourisme d'oviscity :");
						AddMenuItem(menu, "forum", "Forum FeetG");
						AddMenuItem(menu, "site", "Site FeetG");
						AddMenuItem(menu, "locagame", "FeetG-Sourcebans");
						AddMenuItem(menu, "option", "Option Roleplay FeetGG");
						AddMenuItem(menu, "rct", "Recrutements jobs");
						DisplayMenu(menu, client, MENU_TIME_FOREVER);
					}
					else
					{
						PrintToChat(client, "%s : vous êtes trop loin du PNJ.", LOGO);
					}
				}
				
				if (IsInLoto(Ent))
				{
					new Float:origin[3], Float:clientent[3];
					GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
					new Float:distance = GetVectorDistance(origin, clientent);
					new Float:vec[3];
					GetClientAbsOrigin(client, vec);
					vec[2] += 10;
					
					if (distance <= 200)
					{
						new Handle:menu = CreateMenu(Menu_Loto);
						SetMenuTitle(menu, "Loto de oviscity :");
						AddMenuItem(menu, "ticket10", "Ticket a gratté 10$");
						AddMenuItem(menu, "ticket100", "Ticket a gratté 100$");
						AddMenuItem(menu, "ticket1000", "Ticket a gratté 1000$");
						DisplayMenu(menu, client, MENU_TIME_FOREVER);
					}
					else
					{
						PrintToChat(client, "%s : vous êtes trop loin du PNJ.", LOGO);
					}
				}
				
				if (IsInHosto(Ent))
				{
					new Float:origin[3], Float:clientent[3];
					GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
					new Float:distance = GetVectorDistance(origin, clientent);
					new Float:vec[3];
					GetClientAbsOrigin(client, vec);
					vec[2] += 10;
					
					if (distance <= 300)
					{
						new Handle:menu = CreateMenu(Menu_Hosto);
						SetMenuTitle(menu, "Hôpital de oviscity :");
						AddMenuItem(menu, "partiel", "Soin Partiel 200$");
						AddMenuItem(menu, "complet", "Soin Complet 400$");
						DisplayMenu(menu, client, MENU_TIME_FOREVER);
					}
					else
					{
						PrintToChat(client, "%s : vous êtes trop loin du PNJ.", LOGO);
					}
				}
				
				if (IsInEbay(Ent))
				{
					new Float:origin[3], Float:clientent[3];
					GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", origin);
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
					new Float:distance = GetVectorDistance(origin, clientent);
					new Float:vec[3];
					GetClientAbsOrigin(client, vec);
					vec[2] += 10;
					
					if (distance <= 400)
					{
						new Handle:menu = CreateMenu(Menu_Dealer);
						SetMenuTitle(menu, "Dealer de oviscity :");
						AddMenuItem(menu, "heroine", "Heroine 900$");
						AddMenuItem(menu, "exta", "Extasie 600$");
						AddMenuItem(menu, "lsd", "Lsd 500$");
						AddMenuItem(menu, "coke", "Coke 700$");
						DisplayMenu(menu, client, MENU_TIME_FOREVER);
					}
					else
					{
						PrintToChat(client, "%s : vous êtes trop loin du PNJ.", LOGO);
					}
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

public Menu_Serveur(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "forum"))
		{
			ShowMOTDPanel(client, "Forum FeetG" , URL_FORUM , MOTDPANEL_TYPE_URL);
		}
		else if (StrEqual(info, "site"))
		{
			ShowMOTDPanel( client, "Site FeetG" , URL_SITE , MOTDPANEL_TYPE_URL);
		}
		else if (StrEqual(info, "locagame"))
		{
			ShowMOTDPanel(client, "FeetG-Sourcebans" , URL_LOCAGAME , MOTDPANEL_TYPE_URL);
		}
		else if (StrEqual(info, "option"))
		{
			ShowMOTDPanel(client, "Option Roleplay FeetG", URL_OPTION, MOTDPANEL_TYPE_URL);
		}
		else if (StrEqual(info, "rct"))
		{
			ShowMOTDPanel(client, "Recrutements Jobs", URL_RCT, MOTDPANEL_TYPE_URL);
		}
	}
}

public GiveSalaire(client)
{
	if (IsPlayerAlive(client))
	{
		if (g_IsInJail[client] == 0)
		{
			if (jobid[client] == 1)
			{
				AddCash(client, 500);
			}
			else if (jobid[client] == 2)
			{
				AddCash(client, 400);
			}
			else if (jobid[client] == 3)
			{
				AddCash(client, 300);
			}
			else if (jobid[client] == 4)
			{
				AddCash(client, 200);
			}
			else if (jobid[client] == 5)
			{
				AddCash(client, 100);
			}
			else if (jobid[client] == 6)
			{
				AddCash(client, 500);
			}
			else if (jobid[client] == 7)
			{
				AddCash(client, 300);
			}
			else if (jobid[client] == 8)
			{
				AddCash(client, 100);
			}
			else if (jobid[client] == 9)
			{
				AddCash(client, 500);
			}
			else if (jobid[client] == 10)
			{
				AddCash(client, 300);
			}
			else if (jobid[client] == 11)
			{
				AddCash(client, 100);
			}
			else if (jobid[client] == 12)
			{
				AddCash(client, 500);
			}
			else if (jobid[client] == 13)
			{
				AddCash(client, 300);
			}
			else if (jobid[client] == 14)
			{
				AddCash(client, 100);
			}
			else if (jobid[client] == 15)
			{
				AddCash(client, 500);
			}
			else if (jobid[client] == 16)
			{
				AddCash(client, 300);
			}
			else if (jobid[client] == 17)
			{
				AddCash(client, 100);
			}
			else if (jobid[client] == 18)
			{
				AddCash(client, 500);
			}
			else if (jobid[client] == 19)
			{
				AddCash(client, 300);
			}
			else if (jobid[client] == 20)
			{
				AddCash(client, 100);
			}
			else if (jobid[client] == 21)
			{
				AddCash(client, 500);
			}
			else if (jobid[client] == 22)
			{
				AddCash(client, 300);
			}
			else if (jobid[client] == 23)
			{
				AddCash(client, 100);
			}
			else if (jobid[client] == 24)
			{
				AddCash(client, 500);
			}
			else if (jobid[client] == 25)
			{
				AddCash(client, 300);
			}
			else if (jobid[client] == 26)
			{
				AddCash(client, 100);
			}
			else if (jobid[client] == 27)
			{
				AddCash(client, 500);
			}
			else if (jobid[client] == 28)
			{
				AddCash(client, 300);
			}
			else if (jobid[client] == 29)
			{
				AddCash(client, 100);
			}
			else if (jobid[client] == 30)
			{
				AddCash(client, 100);
			}
			else if (jobid[client] == 0)
			{
				AddCash(client, 50);
			}
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

public jobmenu(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		jobid[p[client]] = StringToInt(info);
		
		if (StrEqual(info, "2"))
		{
			CS_SetClientClanTag(p[client], "Agent CIA -");
			
			if (GetClientTeam(p[client]) == 2)
			{
				CS_SwitchTeam(p[client], 3);
				SetEntityModel(p[client], "models/player/ct_gign.mdl");
			}
		}
		else if (StrEqual(info, "1"))
		{
			CS_SetClientClanTag(p[client], "C. police -");
			
			if (GetClientTeam(p[client]) == 2)
			{
				CS_SwitchTeam(p[client], 3);
				SetEntityModel(p[client], "models/player/ct_gign.mdl");
			}
		}
		else if (StrEqual(info, "3"))
		{
			CS_SetClientClanTag(p[client], "Agent du FBI -");
			
			if (GetClientTeam(p[client]) == 2)
			{
				CS_SwitchTeam(p[client], 3);
				SetEntityModel(p[client], "models/player/ct_gign.mdl");
			}
		}
		else if (StrEqual(info, "4"))
		{
			CS_SetClientClanTag(p[client], "Policier -");
			
			if (GetClientTeam(p[client]) == 2)
			{
				CS_SwitchTeam(p[client], 3);
				SetEntityModel(p[client], "models/player/ct_gign.mdl");
			}
		}
		else if (StrEqual(info, "5"))
		{
			CS_SetClientClanTag(p[client], "Gardien -");
			
			if (GetClientTeam(p[client]) == 2)
			{
				CS_SwitchTeam(p[client], 3);
				SetEntityModel(p[client], "models/player/ct_gign.mdl");
			}
		}
		else if (StrEqual(info, "6"))
		{
			CS_SetClientClanTag(p[client], "C. Mafia -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "7"))
		{
			CS_SetClientClanTag(p[client], "Mafieux -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "8"))
		{
			CS_SetClientClanTag(p[client], "A. Mafieux -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "21"))
		{
			CS_SetClientClanTag(p[client], "C. Loto -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "22"))
		{
			CS_SetClientClanTag(p[client], "V. Ticket -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "23"))
		{
			CS_SetClientClanTag(p[client], "A.V. Ticket -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "18"))
		{
			CS_SetClientClanTag(p[client], "C. Armurie -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "19"))
		{
			CS_SetClientClanTag(p[client], "Armurier -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "20"))
		{
			CS_SetClientClanTag(p[client], "A. Armurier -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "15"))
		{
			CS_SetClientClanTag(p[client], "C. Ebay -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "16"))
		{
			CS_SetClientClanTag(p[client], "V. Ebay -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "17"))
		{
			CS_SetClientClanTag(p[client], "A.V. Ebay -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "0"))
		{
			CS_SetClientClanTag(p[client], "Sans emploi -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "12"))
		{
			CS_SetClientClanTag(p[client], "C. Coach -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "13"))
		{
			CS_SetClientClanTag(p[client], "Coach -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "14"))
		{
			CS_SetClientClanTag(p[client], "A. Coach -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "9"))
		{
			CS_SetClientClanTag(p[client], "C. Dealer -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "10"))
		{
			CS_SetClientClanTag(p[client], "Dealer -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "11"))
		{
			CS_SetClientClanTag(p[client], "A. Dealer -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "24"))
		{
			CS_SetClientClanTag(p[client], "C. Banquier -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "25"))
		{
			CS_SetClientClanTag(p[client], "Banquier -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "26"))
		{
			CS_SetClientClanTag(p[client], "A. Banquier -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "27"))
		{
			CS_SetClientClanTag(p[client], "C. Hôpital -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "28"))
		{
			CS_SetClientClanTag(p[client], "Médecin -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "29"))
		{
			CS_SetClientClanTag(p[client], "Infirmier -");
			
			if (GetClientTeam(p[client]) == 3)
			{
				CS_SwitchTeam(p[client], 2);
				SetEntityModel(p[client], "models/player/t_guerilla.mdl");
			}
		}
		else if (StrEqual(info, "30"))
		{
			CS_SetClientClanTag(p[client], "Chirurgien -");
			
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

public Action:OnSay(client, const String:command[], args)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client))
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
				
				for (new i = 1; i <= MaxClients; i++)
				{
					new Float:entorigin[3], Float:clientent[3];
					
					if (i != -1)
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entorigin);
						GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientent);
						new Float:distance = GetVectorDistance(entorigin, clientent);
						new Float:vec[3];
						GetClientAbsOrigin(client, vec);
						vec[2] += 10;
						
						if(IsClientInGame(i) && IsPlayerAlive(i))
						{
							if (distance < 500)
							{
								PrintToChat(i, "%s : (LOCAL) %N : %s", LOGO, client, text);
							
								return Plugin_Handled;
							}
							else
							{
								PrintToChat(client, "%s : (LOCAL) %N : %s", LOGO, client, text);
							
								return Plugin_Handled;
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Block(client, const String:command[], argc)
{
	PrintToConsole(client, "[CSS-RP] : Cette commande est désactivé.");
	return Plugin_Handled;
}

public Action:OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    return Plugin_Handled;
}

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

public Action:Command_Infos(client, args)
{
	if (IsPlayerAlive(client))
	{
		new Handle:panel = CreatePanel();
		SetPanelTitle(panel, "FeetG Roleplay:");
		DrawPanelText(panel, "Forum : http://feetg.css.vg");
		DrawPanelText(panel, "Leader : Gapgapgap (FR)");
		DrawPanelText(panel, "Administrateur : Lignar");
		DrawPanelText(panel, "Codeur : Gapgapgap (FR)");
		DrawPanelText(panel, "Sourcebans : http://feetg.css.vg/sourcebans");
		DrawPanelText(panel, "Recrutement : [ON]");
		DrawPanelText(panel, "Infos Plugin RolePlay : 1.1.1");
 
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

public Connect_Menu(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

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
					Format(kit, sizeof(kit), "Kit de crochetage[%d]", kitcrochetage[client]);
					AddMenuItem(menu, "Kit", kit);
				}
				if (awp[client] > 0)
				{
					new String:awpp[64];
					Format(awpp, sizeof(awpp), "AWP[%d]", awp[client]);
					AddMenuItem(menu, "awp", awpp);
				}
				if (m249[client] > 0)
				{
					new String:batteuse[64];
					Format(batteuse, sizeof(batteuse), "M249[%d]", m249[client]);
					AddMenuItem(menu, "m249", batteuse);
				}
				if (ak47[client] > 0)
				{
					new String:ak[64];
					Format(ak, sizeof(ak), "AK47[%d]", ak47[client]);
					AddMenuItem(menu, "ak47", ak);
				}
				if (m4a1[client] > 0)
				{
					new String:m4[64];
					Format(m4, sizeof(m4), "M4A1[%d]", m4a1[client]);
					AddMenuItem(menu, "m4a1", m4);
				}
				if (sg550[client] > 0)
				{
					new String:sg5500[64];
					Format(sg5500, sizeof(sg5500), "SG550[%d]", sg550[client]);
					AddMenuItem(menu, "sg550", sg5500);
				}
				if (sg552[client] > 0)
				{
					new String:sg5520[64];
					Format(sg5520, sizeof(sg5520), "SG552[%d]", sg552[client]);
					AddMenuItem(menu, "sg552", sg5520);
				}
				if (aug[client] > 0)
				{
					new String:augg[64];
					Format(augg, sizeof(augg), "AUG[%d]", aug[client]);
					AddMenuItem(menu, "aug", augg);
				}
				if (galil[client] > 0)
				{
					new String:galile[64];
					Format(galile, sizeof(galile), "GALIL[%d]", galil[client]);
					AddMenuItem(menu, "galil", galile);
				}
				if (famas[client] > 0)
				{
					new String:famass[64];
					Format(famass, sizeof(famass), "FAMAS[%d]", famas[client]);
					AddMenuItem(menu, "famas", famass);
				}
				if (scout[client] > 0)
				{
					new String:scoutt[64];
					Format(scoutt, sizeof(scoutt), "SCOUT[%d]", scout[client]);
					AddMenuItem(menu, "scout", scoutt);
				}
				if (mp5[client] > 0)
				{
					new String:mp55[64];
					Format(mp55, sizeof(mp55), "MP5[%d]", mp5[client]);
					AddMenuItem(menu, "mp5", mp55);
				}
				if (tmp[client] > 0)
				{
					new String:tmpp[64];
					Format(tmpp, sizeof(tmpp), "TMP[%d]", tmp[client]);
					AddMenuItem(menu, "tmp", tmpp);
				}
				if (ump[client] > 0)
				{
					new String:umpp[64];
					Format(umpp, sizeof(umpp), "UMP[%d]", ump[client]);
					AddMenuItem(menu, "ump", umpp);
				}
				if (p90[client] > 0)
				{
					new String:p900[64];
					Format(p900, sizeof(p900), "P90[%d]", p90[client]);
					AddMenuItem(menu, "p90", p900);
				}
				if (mac10[client] > 0)
				{
					new String:mac100[64];
					Format(mac100, sizeof(mac100), "MAC10[%d]", mac10[client]);
					AddMenuItem(menu, "mac10", mac100);
				}
				if (m3[client] > 0)
				{
					new String:m33[64];
					Format(m33, sizeof(m33), "M3[%d]", m3[client]);
					AddMenuItem(menu, "m3", m33);
				}
				if (xm1014[client] > 0)
				{
					new String:xm[64];
					Format(xm, sizeof(xm), "XM1014[%d]", xm1014[client]);
					AddMenuItem(menu, "xm1014", xm);
				}
				if (deagle[client] > 0)
				{
					new String:deag[64];
					Format(deag, sizeof(deag), "DEAGLE[%d]", deagle[client]);
					AddMenuItem(menu, "deagle", deag);
				}
				if (usp[client] > 0)
				{
					new String:uspp[64];
					Format(uspp, sizeof(uspp), "USP[%d]", usp[client]);
					AddMenuItem(menu, "usp", uspp);
				}
				if (glock[client] > 0)
				{
					new String:gloc[64];
					Format(gloc, sizeof(gloc), "GLOCK[%d]", glock[client]);
					AddMenuItem(menu, "glock", gloc);
				}
				if (elite[client] > 0)
				{
					new String:elit[64];
					Format(elit, sizeof(elit), "ELITE[%d]", elite[client]);
					AddMenuItem(menu, "elite", elit);
				}
				if (ticket10[client] > 0)
				{
					new String:ticket10000[64];
					Format(ticket10000, sizeof(ticket10000), "Ticket 10$[%d]", ticket10[client]);
					AddMenuItem(menu, "tic10", ticket10000);
				}
				if (ticket100[client] > 0)
				{
					new String:ticket100000[64];
					Format(ticket100000, sizeof(ticket100000), "Ticket 100$[%d]", ticket100[client]);
					AddMenuItem(menu, "tic100", ticket100000);
				}
				if (ticket1000[client] > 0)
				{
					new String:ticket1000000[64];
					Format(ticket1000000, sizeof(ticket1000000), "Ticket 1000$[%d]", ticket1000[client]);
					AddMenuItem(menu, "tic1000", ticket1000000);
				}
				if (cartouche[client] > 0)
				{
					new String:kar[64];
					Format(kar, sizeof(kar), "Cartouche[%d]", cartouche[client]);
					AddMenuItem(menu, "cartouche", kar);
				}
				if (props1[client] > 0)
				{
					new String:props11[64];
					Format(props11, sizeof(props11), "PROPS1[%d]", props1[client]);
					AddMenuItem(menu, "props1", props11);
				}
				if (props2[client] > 0)
				{
					new String:props22[64];
					Format(props22, sizeof(props22), "PROPS2[%d]", props2[client]);
					AddMenuItem(menu, "props2", props22);
				}
				if (heroine[client] > 0)
				{
					new String:hero[64];
					Format(hero, sizeof(hero), "HEROINE[%d]", heroine[client]);
					AddMenuItem(menu, "heroine", hero);
				}
				if (exta[client] > 0)
				{
					new String:ext[64];
					Format(ext, sizeof(ext), "EXTASIE[%d]", exta[client]);
					AddMenuItem(menu, "exta", ext);
				}
				if (lsd[client] > 0)
				{
					new String:ls[64];
					Format(ls, sizeof(ls), "LSD[%d]", lsd[client]);
					AddMenuItem(menu, "lsd", ls);
				}
				if (coke[client] > 0)
				{
					new String:cok[64];
					Format(cok, sizeof(cok), "COKE[%d]", coke[client]);
					AddMenuItem(menu, "coke", cok);
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
											
											g_crochcount[client] = 8;
											g_croche[client] = CreateTimer(1.0, TimerCrochetage, client, TIMER_REPEAT);
											SetEntityRenderColor(client, 255, 0, 0, 0);
											SetEntityMoveType(client, MOVETYPE_NONE);
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
				if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1)
				{
					new weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
					Client_EquipWeapon(client, weapon, true);
					Client_SetWeaponPlayerAmmoEx(client, weapon, 90, -1);
				}
				else if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1)
				{
					new weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
					Client_EquipWeapon(client, weapon, true);
					Client_SetWeaponPlayerAmmoEx(client, weapon, 90, -1);
				}
				
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
				}
				else
				{
					PrintToChat(client, "%s : Vous êtes déjà en train d'utilisé une drogue.", LOGO);
				}
			}
		}
		else if (action == MenuAction_End)
		{
			CloseHandle(menu);
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
		}
	}
}
	
public Action:TimerCrochetage(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			g_crochcount[client] -= 1;
			
			if (g_crochcount[client] == 0)
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
								PrintToChatAll("%s : Le joueur %N a remporté le succès \x03Crocheteur du dimanche \x01.", LOGO, client);
								EmitSoundToClient(client, "roleplay_sm/success.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								g_succesporte20[client] = 1;
								
								if (g_porte[client] == 50)
								{
									PrintToChatAll("%s : Le joueur %N a remporté le succès \x03Crocheteur expérimenté \x01.", LOGO, client);
									EmitSoundToClient(client, "roleplay_sm/success.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
									g_succesporte50[client] = 1;
									
									if (g_porte[client] == 100)
									{
										PrintToChatAll("%s : Le joueur %N a remporté le succès \x03Crocheteur professionnel \x01.", LOGO, client);
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
				KillTimer(g_croche[client]);
			}
		}
	}
}

public Menu_Armurie(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{
			if (StrEqual(info, "awp"))
			{
				if (money[client] >= 4000)
				{
					awp[client] = awp[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté une AWP.", LOGO);
					
					new moneyafter = money[client] - 4000;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 2000;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "m249"))
			{
				if (money[client] >= 3000)
				{
					m249[client] = m249[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté une M249.", LOGO);
					
					new moneyafter = money[client] - 3000;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 1500;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "ak47"))
			{
				if (money[client] >= 2000)
				{
					ak47[client] = ak47[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté une AK47.", LOGO);
					
					new moneyafter = money[client] - 2000;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 1000;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "m4a1"))
			{
				if (money[client] >= 2000)
				{
					m4a1[client] = m4a1[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté une M4.", LOGO);
					
					new moneyafter = money[client] - 2000;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 1000;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "sg550"))
			{
				if (money[client] >= 1500)
				{
					sg550[client] = sg550[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un SG550.", LOGO);
					
					new moneyafter = money[client] - 1500;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 750;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "sg552"))
			{
				if (money[client] >= 1500)
				{
					sg552[client] = sg552[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un SG552.", LOGO);
					
					new moneyafter = money[client] - 1500;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 750;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "galil"))
			{
				if (money[client] >= 1300)
				{
					galil[client] = galil[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un GALIL.", LOGO);
					
					new moneyafter = money[client] - 1300;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 650;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "aug"))
			{
				if (money[client] >= 1100)
				{
					aug[client] = aug[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un AUG.", LOGO);
					
					new moneyafter = money[client] - 1100;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 550;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "famas"))
			{
				if (money[client] >= 1000)
				{
					famas[client] = famas[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un FAMAS.", LOGO);
					
					new moneyafter = money[client] - 1000;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 500;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "scout"))
			{
				if (money[client] >= 800)
				{
					scout[client] = scout[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un SCOUT.", LOGO);
					
					new moneyafter = money[client] - 800;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 400;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "mp5"))
			{
				if (money[client] >= 700)
				{
					mp5[client] = mp5[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté une MP5.", LOGO);
					
					new moneyafter = money[client] - 700;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 350;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "p90"))
			{
				if (money[client] >= 700)
				{
					p90[client] = p90[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté une P90.", LOGO);
					
					new moneyafter = money[client] - 700;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 350;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "tmp"))
			{
				if (money[client] >= 600)
				{
					tmp[client] = tmp[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un TMP.", LOGO);
					
					new moneyafter = money[client] - 600;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 300;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "ump"))
			{
				if (money[client] >= 600)
				{
					ump[client] = ump[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un UMP.", LOGO);
					
					new moneyafter = money[client] - 600;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 300;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "mac10"))
			{
				if (money[client] >= 500)
				{
					mac10[client] = mac10[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un MAC10.", LOGO);
					
					new moneyafter = money[client] - 500;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 250;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "deagle"))
			{
				if (money[client] >= 400)
				{
					deagle[client] = deagle[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un DEAGLE.", LOGO);
					
					new moneyafter = money[client] - 400;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 200;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "usp"))
			{
				if (money[client] >= 200)
				{
					usp[client] = usp[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un USP.", LOGO);
					
					new moneyafter = money[client] - 200;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 100;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "glock"))
			{
				if (money[client] >= 200)
				{
					glock[client] = glock[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un GLOCK.", LOGO);
					
					new moneyafter = money[client] - 200;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 100;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "elite"))
			{
				if (money[client] >= 650)
				{
					elite[client] = elite[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté des ELITES.", LOGO);
					
					new moneyafter = money[client] - 650;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 300;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "m3"))
			{
				if (money[client] >= 800)
				{
					m3[client] = m3[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un M3.", LOGO);
					
					new moneyafter = money[client] - 800;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 400;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "xm1014"))
			{
				if (money[client] >= 800)
				{
					xm1014[client] = xm1014[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté un XM1014.", LOGO);
					
					new moneyafter = money[client] - 500;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 400;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "kartouche"))
			{
				if (money[client] >= 150)
				{
					cartouche[client] = cartouche[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté une CARTOUCHE.", LOGO);
					
					new moneyafter = money[client] - 150;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 100;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_Dealer(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{
			if (StrEqual(info, "heroine"))
			{
				if (money[client] >= 900)
				{
					heroine[client] = heroine[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté une HEROINE.", LOGO);
					
					new moneyafter = money[client] - 900;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 450;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "exta"))
			{
				if (money[client] >= 600)
				{
					exta[client] = exta[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté une EXTASIE.", LOGO);
					
					new moneyafter = money[client] - 600;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 300;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "lsd"))
			{
				if (money[client] >= 500)
				{
					lsd[client] = lsd[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté une LSD.", LOGO);
					
					new moneyafter = money[client] - 500;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 250;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
			else if (StrEqual(info, "coke"))
			{
				if (money[client] >= 700)
				{
					coke[client] = coke[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté une COKE.", LOGO);
					
					new moneyafter = money[client] - 700;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 350;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_Hosto(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{
			new health;
			
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			vec[2] += 10;
			
			if (StrEqual(info, "partiel"))
			{
				if (money[client] >= 200)
				{
					health = GetClientHealth(client);
					
					if (GetClientTeam(client) == 2)
					{
						if (health < 100)
						{
							PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
							money[client] = money[client] - 200;
							
							SetEntityHealth(client, health + 50);
							
							capital[serveur] = capital[serveur] + 100;
							
							SetEntData(client, MoneyOffset, money[client], 4, true);
							
							TE_SetupBeamRingPoint(vec, 20.0, 100.0, g_BeamSprite, g_modelHalo, 0, 15, 0.6, 15.0, 0.0, blueColor, 10, 0);
							TE_SendToAll();
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
							PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
							money[client] = money[client] - 200;
							
							SetEntityHealth(client, health + 50);
							
							capital[serveur] = capital[serveur] + 100;
							
							SetEntData(client, MoneyOffset, money[client], 4, true);
							
							TE_SetupBeamRingPoint(vec, 20.0, 100.0, g_BeamSprite, g_modelHalo, 0, 15, 0.6, 15.0, 0.0, blueColor, 10, 0);
							TE_SendToAll();
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
				}
			}
			else if (StrEqual(info, "complet"))
			{
				if (money[client] >= 400)
				{
					health = GetClientHealth(client);
					
					if (GetClientTeam(client) == 2)
					{
						if (health < 100)
						{
							PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
							money[client] = money[client] - 400;
							
							SetEntityHealth(client, health + 100);
							
							capital[serveur] = capital[serveur] + 200;
							
							SetEntData(client, MoneyOffset, money[client], 4, true);
							
							TE_SetupBeamRingPoint(vec, 20.0, 100.0, g_BeamSprite, g_modelHalo, 0, 15, 0.6, 15.0, 0.0, orangeColor, 10, 0);
							TE_SendToAll();
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
							PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
							money[client] = money[client] - 400;
							
							SetEntityHealth(client, health + 100);
							
							capital[serveur] = capital[serveur] + 200;
							
							SetEntData(client, MoneyOffset, money[client], 4, true);
							
							TE_SetupBeamRingPoint(vec, 20.0, 100.0, g_BeamSprite, g_modelHalo, 0, 15, 0.6, 15.0, 0.0, orangeColor, 10, 0);
							TE_SendToAll();
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
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_Loto(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{
			if (StrEqual(info, "ticket10"))
			{
				new Handle:menua = CreateMenu(Ticket_10);
				SetMenuTitle(menua, "Ticket de 10$ :");
				AddMenuItem(menua, "11", "Ticket x1");
				DisplayMenu(menua, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "ticket100"))
			{
				new Handle:menub = CreateMenu(Ticket_100);
				SetMenuTitle(menub, "Ticket de 100$ :");
				AddMenuItem(menub, "10", "Ticket x1");
				DisplayMenu(menub, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "ticket1000"))
			{
				new Handle:menuc = CreateMenu(Ticket_1000);
				SetMenuTitle(menuc, "Ticket de 1000$ :");
				AddMenuItem(menuc, "1", "Ticket x1");
				DisplayMenu(menuc, client, MENU_TIME_FOREVER);
				
				PrintToChat(client, "%s : Vous pouvez acheté maximum 10 tickets de 1000$", LOGO);
			}
		}
	}
}

public Ticket_10(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{
			if (StrEqual(info, "11"))
			{
				if (money[client] >= 10)
				{
					ticket10[client] = ticket10[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté 1 ticket de 10$.", LOGO);
					
					new moneyafter = money[client] - 10;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 5;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
		}
	}
}

public Ticket_100(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{
			if (StrEqual(info, "10"))
			{
				if (money[client] >= 100)
				{
					ticket100[client] = ticket100[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté 1 ticket de 100$.", LOGO);
					
					new moneyafter = money[client] - 100;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 50;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
		}
	}
}

public Ticket_1000(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{
			if (StrEqual(info, "1"))
			{
				if (money[client] >= 1000)
				{
					ticket1000[client] = ticket1000[client] + 1;
					
					PrintToChat(client, "%s : Vous avez acheté 1 ticket de 1000$.", LOGO);
					
					new moneyafter = money[client] - 1000;
					
					money[client] = moneyafter;
					
					SetEntData(client, MoneyOffset, money[client], 4, true);
					
					capital[serveur] = capital[serveur] + 500;
				}
				else
				{
					PrintToChat(client, "%s : Vous n'avez pas assez d'argent.", LOGO);
				}
			}
		}
	}
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
		new String:sWeaponName[64];
		
		GetClientWeapon(attacker, sWeaponName, sizeof(sWeaponName));
		
		if (StrEqual(sWeaponName, "weapon_knife"))
		{
			if ((levelcut[attacker] <= 0) && victim > 1 && victim < MaxClients)
			{
				damage *= 0.0;
				return Plugin_Changed;
			}
		}
		
		if (g_IsTazed[attacker])
		{
			damage *= 0.0;
			return Plugin_Changed;
		}
		
		if (IsInComico(attacker) || IsInFbi(attacker) || IsInHosto(attacker))
		{
			damage *= 0.0;
			return Plugin_Changed;
		}
		
		if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
		{
			damage *= 0.25;
			return Plugin_Changed;
		}
	}
	
	if ((damagetype & DMG_FALL) == DMG_FALL || (damagetype & DMG_BLAST) == DMG_BLAST)
    {
        return Plugin_Handled;
    }
	return Plugin_Continue;
}

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

public Action:Command_Engager(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if ((jobid[client] == 6) || (jobid[client] == 9) || (jobid[client] == 12) || (jobid[client] == 15) || (jobid[client] == 18) || (jobid[client] == 21) || (jobid[client] == 24) || (jobid[client] == 27))
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

public Action:Command_Grab(client, args)
{ 
	if (!IsPlayerAlive(client) || !IsClientInGame(client) || (client < 0) || (client > MaxClients))
		return Plugin_Handled;
		
	if (g_IsInJail[client] == 0)
	{
		if (grab[client])
		{
			StopSound(client, SNDCHAN_AUTO, gSound);
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
				StopSound(client, SNDCHAN_AUTO, gSound);
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
					EmitSoundToAll(gSound, client);
					grab[client] = true;
				}
				else if(StrEqual(edictname, "player"))
				{
					if ((GetClientTeam(client) == 3) || jobid[client] == 6 || jobid[client] == 9 || jobid[client] == 12 || jobid[client] == 15 || jobid[client] == 18 || jobid[client] == 21 || jobid[client] == 24 || jobid[client] == 27)
					{
						if ((GetClientTeam(ent) == 3))
						{
							PrintToChat(client, "%s : Vous ne pouvez pas porté un policier", LOGO);
							return Plugin_Handled;
						}
						else
						{
							gObj[client] = ent;
							EmitSoundToAll(gSound, client);
							grab[client] = true;
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
	new Float:speed = GetConVarFloat(cvSpeed);
	new Float:distance = GetConVarFloat(cvDistance);
	for (i=0; i<MAX_PLAYERS; i++)
	{
		if (gObj[i]>0)
		{
			if (IsValidEdict(gObj[i]) && IsValidEntity(gObj[i]))
			{
				GetClientEyeAngles(i, viewang);
				GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
				GetClientEyePosition(i, vecPos);
				
				vecPos[0]+=vecDir[0]*distance;
				vecPos[1]+=vecDir[1]*distance;
				vecPos[2]+=vecDir[2]*distance;
				
				GetEntPropVector(gObj[i], Prop_Send, "m_vecOrigin", vecDir);
				
				SubtractVectors(vecPos, vecDir, vecVel);
				ScaleVector(vecVel, speed);
				
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
		DisplayMenu(menuc, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

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
		CS_SetClientClanTag(m[client], "Sans emploi -");
		PrintToChat(m[client], "%s : Vous avez été viré de votre job.", LOGO);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

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
						AddMenuItem(menu, "chirurgie", "Chirurgie 1000$");
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
		else if (StrEqual(info, "chirurgie")) 
        { 
            new Handle:menuai = CreateMenu(Vente_Chirurgie); 
            SetMenuTitle(menuai, "Voulez-vous acheté une Chirurgie à 1000$?"); 
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
						
						capital[serveur] = capital[serveur] + 50;
						
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
						
						capital[serveur] = capital[serveur] + 50;
						
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
								
								capital[serveur] = capital[serveur] + 50;
								
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
								
								capital[serveur] = capital[serveur] + 50;
								
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
						
						capital[serveur] = capital[serveur] + 150;
						
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
						
						capital[serveur] = capital[serveur] + 150;
						
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
								
								capital[serveur] = capital[serveur] + 150;
								
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
								
								capital[serveur] = capital[serveur] + 150;
								
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

public Vente_Chirurgie(Handle:menu, MenuAction:action, client, param2) 
{ 
	if (action == MenuAction_Select) 
	{ 
		new String:info[32]; 
		GetMenuItem(menu, param2, info, sizeof(info)); 

		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		new health;

		if (StrEqual(info, "oui")) 
		{ 
			if (money[client] >= 1000)
			{
				health = GetClientHealth(client);
			
				PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
				PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
				money[client] = money[client] - 1000;
				AdCash(TransactionWith[client], 500);
		
				SetEntityHealth(client, health + 150);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.4);
		
				capital[serveur] = capital[serveur] + 500;
		
				SetEntData(client, MoneyOffset, money[client], 4, true);
			}
			else
			{
				if (cb[client] == 1)
				{
					if (bank[client] >= 1000)
					{
						health = GetClientHealth(client);

						PrintToChat(TransactionWith[client], "%s : Le client %N a accepter.", LOGO, client); 
						PrintToChat(client, "%s : Achat réalisé avec succès.", LOGO); 
						money[client] = money[client] - 1000;
						AdCash(TransactionWith[client], 500);
			
						SetEntityHealth(client, health + 150);
						SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.4);
				
						capital[serveur] = capital[serveur] + 500;
				
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
				
				capital[serveur] = capital[serveur] + 50;
				
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
				
						capital[serveur] = capital[serveur] + 50;
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
				
				capital[serveur] = capital[serveur] + 50;
				
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
				
						capital[serveur] = capital[serveur] + 50;
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
				
				capital[serveur] = capital[serveur] + 500;
				
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
				
						capital[serveur] = capital[serveur] + 500;
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
				
				capital[serveur] = capital[serveur] + 150;
				
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
				
						capital[serveur] = capital[serveur] + 150;
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
				
				capital[serveur] = capital[serveur] + 50;
				
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
				
						capital[serveur] = capital[serveur] + 50;
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
				
				capital[serveur] = capital[serveur] + 200;
				
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
				
						capital[serveur] = capital[serveur] + 200;
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
				
				capital[serveur] = capital[serveur] + 250;
				
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
				
						capital[serveur] = capital[serveur] + 250;
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
				
				capital[serveur] = capital[serveur] + 250;
				
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
				
						capital[serveur] = capital[serveur] + 250;
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
				
				capital[serveur] = capital[serveur] + 225;
				
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
				
						capital[serveur] = capital[serveur] + 225;
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
				
				capital[serveur] = capital[serveur] + 300;
				
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
				
						capital[serveur] = capital[serveur] + 300;
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
				
				capital[serveur] = capital[serveur] + 300;
				
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
				
						capital[serveur] = capital[serveur] + 300;
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
				
				capital[serveur] = capital[serveur] + 350;
				
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
				
						capital[serveur] = capital[serveur] + 350;
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
				
				capital[serveur] = capital[serveur] + 350;
				
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
				
						capital[serveur] = capital[serveur] + 350;
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
				
				capital[serveur] = capital[serveur] + 350;
				
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
				
						capital[serveur] = capital[serveur] + 350;
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
				
				capital[serveur] = capital[serveur] + 500;
				
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
				
						capital[serveur] = capital[serveur] + 500;
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
				
				capital[serveur] = capital[serveur] + 450;
				
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
				
						capital[serveur] = capital[serveur] + 450;
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
				
				capital[serveur] = capital[serveur] + 600;
				
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
				
						capital[serveur] = capital[serveur] + 600;
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
				
				capital[serveur] = capital[serveur] + 650;
				
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
				
						capital[serveur] = capital[serveur] + 650;
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
				
				capital[serveur] = capital[serveur] + 650;
				
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
				
						capital[serveur] = capital[serveur] + 650;
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
				
				capital[serveur] = capital[serveur] + 750;
				
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
				
						capital[serveur] = capital[serveur] + 750;
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
				
				capital[serveur] = capital[serveur] + 750;
				
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
				
						capital[serveur] = capital[serveur] + 750;
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
				
				capital[serveur] = capital[serveur] + 750;
				
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
				
						capital[serveur] = capital[serveur] + 750;
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
				
				capital[serveur] = capital[serveur] + 1250;
				
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
				
						capital[serveur] = capital[serveur] + 1250;
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
				
				capital[serveur] = capital[serveur] + 500;
				
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
				
						capital[serveur] = capital[serveur] + 500;
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
				
				capital[serveur] = capital[serveur] + 1000;
				
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
				
						capital[serveur] = capital[serveur] + 1000;
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
				
				capital[serveur] = capital[serveur] + 10;
				
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
				
						capital[serveur] = capital[serveur] + 10;
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
				
				capital[serveur] = capital[serveur] + 50;
				
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
				
						capital[serveur] = capital[serveur] + 50;
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
				
				capital[serveur] = capital[serveur] + 1000;
				
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
				
						capital[serveur] = capital[serveur] + 500;
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
				
				capital[serveur] = capital[serveur] + 750;
				
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
				
						capital[serveur] = capital[serveur] + 750;
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
				
				capital[serveur] = capital[serveur] + 500;
				
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
				
						capital[serveur] = capital[serveur] + 500;
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
				
				capital[serveur] = capital[serveur] + 150;
				
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
				
						capital[serveur] = capital[serveur] + 150;
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
				
				capital[serveur] = capital[serveur] + 200;
				
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
				
						capital[serveur] = capital[serveur] + 200;
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
				
				capital[serveur] = capital[serveur] + 250;
				
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
				
						capital[serveur] = capital[serveur] + 250;
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
				
				capital[serveur] = capital[serveur] + 350;
				
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
				
						capital[serveur] = capital[serveur] + 350;
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
				
				capital[serveur] = capital[serveur] + 750;
				
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
				
				capital[serveur] = capital[serveur] + 750;
				
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
						new vol_somme = GetRandomInt(1, 300);
					
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
									
									capital[serveur] = capital[serveur] + 500;
			
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

public Action:Timer_Pub(Handle:timer)
{
	switch (GetRandomInt(1, 7))
	{
		case 1:
		{
			PrintToChatAll("%s : Bienvenue sur le Roleplay FeetG", LOGO);
		}
		
		case 2:
		{
			PrintToChatAll("%s : Sourcebans http://feetg.css.vg .", LOGO);
		}
		
		case 3:
		{
			PrintToChatAll("%s : Pour avoir un boulot contactez Gapgapgap (FR)", LOGO);
		}
		
		case 4:
		{
			PrintToChatAll("%s : feetg.css.vg", LOGO);
		}
		
		case 5:
		{
			PrintToChatAll("%s : Veuillez rapporté les bugs sur le Forum.", LOGO);
		}
		
		case 6:
		{
			PrintToChatAll("%s : Tapez \x04!rp \x01pour voir les commandes.",  LOGO);
		}
		
		case 7:
		{
			PrintToChatAll("%s : Le Roleplay est codé par \x04Gapgapgap \x01.",  LOGO);
		}
	}
}

public Action:Command_JoinTeam(client, const String:command[], args)
{
	UTIL_TeamMenu(client);
	EmitSoundToClient(client, "roleplay_sm/noteam.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	return Plugin_Handled;
}

UTIL_TeamMenu(client)
{
	new clients[1];
	new Handle:bf;
	clients[0] = client;
	
	bf = StartMessage("VGUIMenu", clients, 1);
	BfWriteString(bf, "team");
	BfWriteByte(bf, 1);
	BfWriteByte(bf, 0);
	EndMessage();
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

public chooseskin(client)
{
	new String:SteamId[32];
	GetClientAuthString(client, SteamId, sizeof(SteamId));
	
	if (GetClientTeam(client) == 2)
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
	
	if (StrEqual(SteamId, "STEAM_0:0:34437348"))
	{
		SetEntityModel(client, "models/player/slow/jamis/kingpin/slow_v2.mdl");
		PrintToChatAll("%s : Et voilà, \x03Killer_One \x01tu es re-habillé comme un prince :)", LOGO);
	}
}

public ChooseKiller(client)
{
	new String:SteamId[32];
	GetClientAuthString(client, SteamId, sizeof(SteamId));
	
	if (StrEqual(SteamId, "STEAM_0:0:34437348"))
	{
		SetEntityModel(client, "models/player/slow/jamis/kingpin/slow_v2.mdl");
	}
}

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
			else if (jobid[client] == 37)
			{
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
			PrintToChat(client, "[CSS-RP] : Vous n'avez pas accès a cette commande.");
		}
	}
	else
	{
		PrintToChat(client, "[CSS-RP] : Vous devez être en vie pour utilisé cette commande.");
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

public Action:Command_Changename(client, args)
{
	if (IsClientInGame(client))
	{
		if (jobid[client] == 1)
		{
			if (args < 1)
			{
				ReplyToCommand(client, "[CSS-RP] Usage: sm_changename <pseudo>");
				return Plugin_Handled;	
			}
			
			decl String:arg2[30];

			GetCmdArg(1, arg2, sizeof(arg2));
			
			new pseudo = StringToInt(arg2);
			
			new String:newpseudo[200];
			
			Format(newpseudo, sizeof(newpseudo), "%s", pseudo);
			
			CS_SetClientName(client, newpseudo, true);
		}
		else
		{
			PrintToChat(client, "%s : Vous n'avez pas accès a cette commande.", LOGO);
		}
	}
	return Plugin_Continue;
}

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
							
							TeleportEntity(expulser, Float:{ 1816.820313, 1385.121826, -298.241486 }, NULL_VECTOR, NULL_VECTOR);
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
			}
			else
			{
				PrintToChat(client, "%s : Vous devez visé un joueurs.", LOGO);
			}
		}
	}
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
	
	if (v[0] >= -1771.5 && v[0] <= -120.3 && v[1] >= 525.0 && v[1] <= 1755.0 && v[2] >= -400.0 && v[2] <= 280.0)
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

IsInJail1(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -3144.847900 && v[0] <= -2944.745117 && v[1] >= -845.150391 && v[1] <= -616.575134 && v[2] >= -449.392273 && v[2] <= -308.677460)
		return true;
	else
		return false;
}

IsInJail2(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -3345.045410 && v[0] <= -3149.856201 && v[1] >= -843.335632 && v[1] <= -615.353943 && v[2] >= -457.157227 && v[2] <= -258.310425)
		return true;
	else
		return false;
}

IsInJail3(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -3148.372314 && v[0] <= -3148.372314 && v[1] >= -473.338715 && v[1] <= -243.239105 && v[2] >= -455.986115 && v[2] <= -258.782745)
		return true;
	else
		return false;
}

IsInJail4(client)
{
	new Float:v[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", v);
	
	if (v[0] >= -3150.566162 && v[0] <= -2941.353271 && v[1] >= -473.454865 && v[1] <= -240.106384 && v[2] >= -447.795685 && v[2] <= -258.256409)
		return true;
	else
		return false;
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