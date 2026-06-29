#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <clientprefs>
#include <cstrike>
#include <emitsoundany>
#include <abnersound>
#pragma semicolon 1

#define MAX_EDICTS				2048
#define MAX_SOUNDS				1024
#define PLUGIN_VERSION			"4.0.10"
#define m_flNextSecondaryAttack FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack")
#pragma newdecls required

int				 g_S = 0, g_N = 0;

int				 trid = 0;
int				 ctid = 0;
float			 teleloc[3];
int				 seconds = 0;

Handle			 g_hDuel;
Handle			 g_hSound;
ConVar			 g_hSoundPath;
Handle			 g_DuelCookie;
Handle			 g_SoundsCookie;
Handle			 g_hPlayType;
Handle			 g_hStop;
Handle			 g_hTP;
Handle			 g_hRefuseSound;
Handle			 g_hFightTime;
Handle			 g_hIammo;
Handle			 g_hTimeDuel = INVALID_HANDLE;
Handle 			 g_IgnoreBots;
Handle			 g_DuelBeacon;
Handle			 g_DuelMsg;
Handle			 g_WinnerCash;
Handle			 g_hDuelArma;
Handle			 g_Health;

bool			 NoScopeEnabled = false;
bool			 DuelStarted	= false;
bool			 CSGO;
bool			 g_BombPlanted = false;

ArrayList		 sounds;
ArrayList		 ctItens;
ArrayList		 trItens;

// Beacon Stuff
int				 g_BeaconSerial[MAXPLAYERS + 1] = { 0, ... };
int				 g_BeamSprite					= -1;
int				 g_HaloSprite					= -1;
char			 g_BlipSound[PLATFORM_MAX_PATH];
int				 g_Serial_Gen	 = 0;

// Basic color arrays for temp entities
int				 redColor[4]	 = { 255, 75, 75, 255 };
int				 greenColor[4]	 = { 75, 255, 75, 255 };
int				 blueColor[4]	 = { 75, 75, 255, 255 };
int				 greyColor[4]	 = { 128, 128, 128, 255 };

char			 csgoWeapons[][] = {
	"weapon_awp", "weapon_ak47", "weapon_aug", "weapon_bizon", "weapon_deagle", "weapon_decoy", "weapon_elite", "weapon_famas", "weapon_fiveseven", "weapon_flashbang",
	"weapon_g3sg1", "weapon_galilar", "weapon_glock", "weapon_hegrenade", "weapon_hkp2000", "weapon_incgrenade", "weapon_knife", "weapon_m249", "weapon_m4a1",
	"weapon_mac10", "weapon_mag7", "weapon_molotov", "weapon_mp7", "weapon_mp9", "weapon_negev", "weapon_nova", "weapon_p250", "weapon_p90", "weapon_sawedoff",
	"weapon_scar20", "weapon_sg556", "weapon_smokegrenade", "weapon_ssg08", "weapon_taser", "weapon_tec9", "weapon_ump45", "weapon_xm1014"
};

bool IsCSGOWeapon(char[] weapon)
{
	for (int i = 0; i < sizeof(csgoWeapons); i++)
	{
		if (StrEqual(weapon, csgoWeapons[i]))
			return true;
	}
	return false;
}

public Plugin myinfo =
{
	name		= "[CSS/CS:GO] AbNeR Duel",
	author		= "abnerfs",
	description = "Duel and NoScope in 1v1",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/abnerfs/abner_duel"


}

public void
	OnPluginStart()
{
	/*																		CVARS																														*/
	CreateConVar("abner_duel_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY | FCVAR_REPLICATED);
	g_hDuelArma	   = CreateConVar("duel_weapon", "weapon_awp;weapon_knife", "Weapons used in 1v1 duel");
	g_hDuel		   = CreateConVar("duel_1x1", "1", "0 - Disabled, 1 - Vote, 2 - Force duel ");
	g_hSound	   = CreateConVar("duel_music", "1", "Enable/Disable 1x1 Music");

	g_hSoundPath   = CreateConVar("duel_music_path", "misc/noscope", "Duel Sounds Path");
	g_hPlayType	   = CreateConVar("duel_music_play_type", "1", "1 - Random, 2- Play in queue");
	g_hStop		   = CreateConVar("duel_stop_map_music", "0", "Stop map musics ");
	g_hRefuseSound = CreateConVar("duel_refuse_sound", "misc/th_chicken.mp3", "Refuse sound path.");

	g_hTP		   = CreateConVar("duel_teleport", "1", "Teleport players in 1x1.");
	g_hFightTime   = CreateConVar("duel_fight_time", "30", "Max duel time in second, 0 to disable");
	g_hIammo	   = CreateConVar("duel_iammo", "1", "Infinity Ammo in Duel");
	g_IgnoreBots                                        = CreateConVar("duel_ignore_bots", "1", "Dont't start the duel with alive bots");

	g_DuelBeacon   = CreateConVar("duel_beacon", "1", "Enable/Disable player beacon in Duel");

	g_DuelMsg	   = CreateConVar("duel_join_msg", "1", "Enable/Disable join message.");

	g_WinnerCash   = CreateConVar("duel_winner_extracash", "2000", "Give extra cash to the winner!");
	g_Health	   = CreateConVar("duel_health", "100", "Health that players will have in duel, 0 - Doesn't change current health");

	/*                                                                      ClientPrefs	    																				*/
	g_DuelCookie   = RegClientCookie("AbNeR Duel Settings", "", CookieAccess_Private);
	g_SoundsCookie = RegClientCookie("abner_duel_sounds", "", CookieAccess_Private);

	SetCookieMenuItem(DuelCookieHandler, 0, "AbNeR Duel");
	RegConsoleCmd("abnerduel", DuelMenu);
	RegConsoleCmd("duel", DuelMenu);

	AutoExecConfig(true, "abner_duel");
	LoadTranslations("common.phrases");
	LoadTranslations("abner_duel.phrases");

	RegAdminCmd("sm_noscope", CommandSemMira, ADMFLAG_SLAY);
	RegAdminCmd("duel_refresh", CommandLoad, ADMFLAG_SLAY);

	HookEvent("player_death", PlayerDeath);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("bomb_planted", Event_BombPlanted);

	CSGO   = GetEngineVersion() == Engine_CSGO;

	sounds = new ArrayList(512);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			OnClientPutInServer(i);
	}
}

bool isNoScopeWeapon(char[] weapon)
{
	if (StrEqual(weapon, "weapon_scout")
		|| StrEqual(weapon, "weapon_g3sg1")
		|| StrEqual(weapon, "weapon_ssg08")
		|| StrEqual(weapon, "weapon_aug")
		|| StrEqual(weapon, "weapon_sg556")
		|| StrEqual(weapon, "weapon_awp")
		|| StrEqual(weapon, "weapon_scar20"))
		return true;
	return false;
}

public void OnClientPutInServer(int client)
{
	if (GetConVarInt(g_DuelMsg) == 1)
		CreateTimer(3.0, msg, client);

	SDKHook(client, SDKHook_PreThink, PreThink);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

public Action msg(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		CPrintToChat(client, "{green}%t\x01%t", "prefix", "command");
	}
	return Plugin_Continue;
}

public Action PreThink(int client)
{
	if (IsPlayerAlive(client))
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (!IsValidEdict(weapon))
			return Plugin_Continue;

		char item[64];
		GetEdictClassname(weapon, item, sizeof(item));
		if (DuelStarted && !StrEqual(item, "weapon_knife") && GetConVarInt(g_hIammo) == 1)	  // Infinity Ammo
		{
			int clip1Offset = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
			SetEntData(weapon, clip1Offset, 200, 4, true);
		}
		if (NoScopeEnabled && isNoScopeWeapon(item))
		{
			SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 9999.9);	 // Disable Scope
		}
	}
	return Plugin_Continue;
}

public void DuelCookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	DuelMenu(client, 0);
}

public Action DuelMenu(int client, int args)
{
	char   text[60];
	int	   cookievalue = GetIntCookie(client, g_DuelCookie);
	Handle g_DuelMenu  = CreateMenu(DuelMenuHandler);
	SetMenuTitle(g_DuelMenu, "AbNeR Duel Settings");
	switch (cookievalue)
	{
		case 0:
		{
			Format(text, sizeof(text), "%t", "Always Accept");
			AddMenuItem(g_DuelMenu, text, text);
			Format(text, sizeof(text), "%t", "Always Refuse");
			AddMenuItem(g_DuelMenu, text, text);
			Format(text, sizeof(text), "%t %t", "None", "Marked");
			AddMenuItem(g_DuelMenu, text, text);
		}
		case 1:
		{
			Format(text, sizeof(text), "%t %t", "Always Accept", "Marked");
			AddMenuItem(g_DuelMenu, text, text);
			Format(text, sizeof(text), "%t", "Always Refuse");
			AddMenuItem(g_DuelMenu, text, text);
			Format(text, sizeof(text), "%t", "None");
			AddMenuItem(g_DuelMenu, text, text);
		}
		case 2:
		{
			Format(text, sizeof(text), "%t", "Always Accept");
			AddMenuItem(g_DuelMenu, text, text);
			Format(text, sizeof(text), "%t %t", "Always Refuse", "Marked");
			AddMenuItem(g_DuelMenu, text, text);
			Format(text, sizeof(text), "%t", "None");
			AddMenuItem(g_DuelMenu, text, text);
		}
	}

	cookievalue = GetIntCookie(client, g_SoundsCookie);

	if (cookievalue == 0)
	{
		Format(text, sizeof(text), "%t", "Sounds Enabled");
	}
	else if (cookievalue == 1)
	{
		Format(text, sizeof(text), "%t", "Sounds Disabled");
	}
	AddMenuItem(g_DuelMenu, text, text);
	SetMenuExitBackButton(g_DuelMenu, true);
	SetMenuExitButton(g_DuelMenu, true);
	DisplayMenu(g_DuelMenu, client, 30);
	return Plugin_Continue;
}

public int DuelMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (param2 == MenuCancel_ExitBack)
	{
		ShowCookieMenu(param1);
	}
	else if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
				SetClientCookie(param1, g_DuelCookie, "1");

			case 1:
				SetClientCookie(param1, g_DuelCookie, "2");

			case 2:
				SetClientCookie(param1, g_DuelCookie, "0");

			case 3:
			{
				int cookievalue = GetIntCookie(param1, g_SoundsCookie);
				if (cookievalue == 0) SetClientCookie(param1, g_SoundsCookie, "1");
				else if (cookievalue == 1) SetClientCookie(param1, g_SoundsCookie, "0");
			}
		}
		DuelMenu(param1, 0);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public void OnClientDisconnect(int client)
{
	if (DuelStarted && (client == trid || client == ctid))
		FinishDuel();
}

public void OnMapStart()
{
	RefreshSounds(0);
	char soundpath[PLATFORM_MAX_PATH];
	GetConVarString(g_hRefuseSound, soundpath, sizeof(soundpath));
	if (!StrEqual(soundpath, ""))
	{
		char download[PLATFORM_MAX_PATH];
		Format(download, sizeof(download), "sound/%s", soundpath);
		AddFileToDownloadsTable(download);
		PrecacheSoundAny(soundpath);
	}

	// Beacon Stuff
	Handle gameConfig = LoadGameConfigFile("funcommands.games");
	if (gameConfig == null)
	{
		SetFailState("Unable to load game config funcommands.games");
		return;
	}

	if (GameConfGetKeyValue(gameConfig, "SoundBlip", g_BlipSound, sizeof(g_BlipSound)) && g_BlipSound[0])
	{
		PrecacheSoundAny(g_BlipSound, true);
	}

	char buffer[PLATFORM_MAX_PATH];
	if (GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
	{
		g_BeamSprite = PrecacheModel(buffer);
	}
	if (GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
	{
		g_HaloSprite = PrecacheModel(buffer);
	}

	delete gameConfig;
}

void RefreshSounds(int client)
{
	int size = LoadSounds(sounds, g_hSoundPath);
	if (size > 0)
		CReplyToCommand(client, "{green}%t{default}Loaded %d sounds.", "prefix", size);
	else
		CReplyToCommand(client, "{green}%t{default}INVALID SOUND PATH", "prefix");
}

public void PlaySoundAll(char[] szSound)
{
	if (StrEqual(szSound, ""))
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetIntCookie(i, g_SoundsCookie) == 0)
		{
			PlaySoundClient(i, szSound, 1.0);
		}
	}
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_BombPlanted = false;
	KillAllBeacons();
	ctid = 0, trid = 0;
	NoScopeEnabled = false;
	DuelStarted	   = false;

	if (g_hTimeDuel != INVALID_HANDLE)
	{
		KillTimer(g_hTimeDuel);
		g_hTimeDuel = INVALID_HANDLE;
	}

	if (GetConVarInt(g_hStop) == 1)
	{
		MapSounds();
	}
}

public int VoteMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
				VoteYes(param1);

			case 1:
				VoteNo(param1);
		}
	}
	return 0;
}

public void ShowMenuAll()
{
	g_S = 0, g_N = 0;

	char text[200];

	Menu menu = CreateMenu(VoteMenuHandler);
	menu.SetTitle("%t", "Duel Ask");

	Format(text, sizeof(text), "%t", "Yes");
	menu.AddItem("Yes", text);

	Format(text, sizeof(text), "%t", "No");
	menu.AddItem("No", text);

	menu.ExitBackButton = false;
	menu.ExitButton		= false;

	ShowMenu(menu, ctid);
	ShowMenu(menu, trid);
}

void ShowMenu(Menu menu, int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return;

	if (IsFakeClient(client))
	{
		VoteYes(client);
		return;
	}

	int cookie = GetIntCookie(client, g_DuelCookie);
	switch (cookie)
	{
		case 0:
			menu.Display(client, MENU_TIME_FOREVER);
		case 1:
			VoteYes(client);
		case 2:
			VoteNo(client);
	}
}

public void VoteYes(int client)
{
	if (ctid != client && trid != client)
		return;

	char nome[MAX_TARGET_LENGTH];
	GetClientName(client, nome, sizeof(nome));
	g_S++;

	if (GetClientTeam(client) == 2)
	{
		CPrintToChatAll("{green}%t\x01%t", "prefix", "Duel Accepted Red", nome);
	}
	else if (GetClientTeam(client) == 3)
	{
		CPrintToChatAll("{green}%t\x01%t", "prefix", "Duel Accepted Blue", nome);
	}
	check_votes();
}

public void VoteNo(int client)
{
	if (ctid != client && trid != client)
		return;

	char nome[MAX_TARGET_LENGTH];
	GetClientName(client, nome, sizeof(nome));
	g_N++;

	int team = GetClientTeam(client);
	switch (team)
	{
		case 2:
		{
			CPrintToChatAll("{green}%t\x01%t", "prefix", "Duel Refused Red", nome);
		}
		case 3:
		{
			CPrintToChatAll("{green}%t\x01%t", "prefix", "Duel Refused Blue", nome);
		}
	}

	char soundpath[PLATFORM_MAX_PATH];
	GetConVarString(g_hRefuseSound, soundpath, sizeof(soundpath));
	PlaySoundAll(soundpath);
	check_votes();
}

public void check_votes()
{
	if (g_S == 2)
	{
		StartDuel();
	}
	else if (g_N >= 1)
		CPrintToChatAll("{green}%t\x01%t", "prefix", "Duel Canceled");
}

public Action CommandLoad(int client, int args)
{
	RefreshSounds(0);
	return Plugin_Handled;
}

stock bool CheckWeapon(int entity)
{
	if (!IsValidEdict(entity))
		return false;

	char weapons[5000];
	GetConVarString(g_hDuelArma, weapons, sizeof(weapons));

	char sWeapon[32];
	GetEdictClassname(entity, sWeapon, sizeof(sWeapon));

	if (StrContains(weapons, sWeapon, false) > -1)
	{
		return true;
	}

	return false;
}

public Action OnWeaponEquip(int client, int weapon)
{
	if (!DuelStarted)
		return Plugin_Continue;

	if (CheckWeapon(weapon))
		return Plugin_Continue;

	return Plugin_Handled;
}

public Action CommandSemMira(int client, int args)
{
	if (NoScopeEnabled)
	{
		NoScopeEnabled = false;
		CPrintToChatAll("{green}%t\x01%t", "prefix", "Scope On");
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i))
			{
				for (int j = 0; j < 5; j++)
				{
					int weapon = GetPlayerWeaponSlot(i, j);
					if (weapon == -1)
					{
						continue;
					}
					char item[128];
					GetEdictClassname(weapon, item, sizeof(item));
					if (isNoScopeWeapon(item))
					{
						SetEntDataFloat(weapon, m_flNextSecondaryAttack, 0.0);
					}
				}
			}
		}
		return Plugin_Handled;
	}
	else
	{
		NoScopeEnabled = true;
		CPrintToChatAll("{green}%t\x01%t", "prefix", "Scope Off");
		return Plugin_Handled;
	}
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, CheckDuel, client);
	return Plugin_Continue;
}

public Action CheckDuel(Handle time, any client)
{
	if (DuelStarted && IsValidClient(client))
		ForcePlayerSuicide(client);
	return Plugin_Continue;
}

public Action PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if (DuelStarted || g_BombPlanted)
		return Plugin_Continue;

	if (CSGO && GameRules_GetProp("m_bWarmupPeriod") == 1)
		return Plugin_Continue;

	if (trs_vivos() == 1 && cts_vivos() == 1)
	{
		SetIDs();

		if (GetConVarInt(g_hDuel) == 1)
		{
			ShowMenuAll();
		}
		else if (GetConVarInt(g_hDuel) == 2)
		{
			StartDuel();
		}
	}
	return Plugin_Continue;
}

void FinishDuel()
{
	KillAllBeacons();

	int	 extra	 = GetConVarInt(g_WinnerCash);
	bool trAlive = IsValidClient(trid) && IsPlayerAlive(trid);
	bool ctAlive = IsValidClient(ctid) && IsPlayerAlive(ctid);

	int	 winner	 = 0;

	if (trAlive && !ctAlive)
	{
		winner = trid;
	}
	else if (ctAlive && !trAlive) {
		winner = ctid;
	}

	if (winner > 0)
	{
		DropWeapons(winner, null);
		if (ctAlive)
			ReturnWeapons(winner, ctItens);
		else if (trAlive)
			ReturnWeapons(winner, trItens);

		if (extra > 0)
		{
			int money = GetEntProp(ctid, Prop_Send, "m_iAccount");
			SetEntProp(ctid, Prop_Send, "m_iAccount", money + extra);
		}
	}

	DuelStarted	   = false;
	NoScopeEnabled = false;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (DuelStarted)
		FinishDuel();

	ctid = 0, trid = 0;
	NoScopeEnabled = false;
	DuelStarted	   = false;

	if (g_hTimeDuel != INVALID_HANDLE)
	{
		KillTimer(g_hTimeDuel);
		g_hTimeDuel = INVALID_HANDLE;
	}
	return Plugin_Continue;
}

public Action Event_BombPlanted(Handle event, const char[] name, bool dontBroadcast)
{
	g_BombPlanted = true;
	return Plugin_Continue;
}

void SetIDs()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			if (GetClientTeam(i) == 2)
			{
				trid = i;
			}
			else if (GetClientTeam(i) == 3)
			{
				ctid = i;
			}
		}
	}
}

void SetDuelStartPlayer(int client)
{
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
}

public void StartDuel()
{
	NoScopeEnabled = true;
	DuelStarted	   = true;

	SetDuelStartPlayer(ctid);
	SetDuelStartPlayer(trid);

	if (GetConVarInt(g_hSound) == 1)
	{
		if (GetConVarInt(g_hStop) == 1)
			StopMapMusic();

		char szSound[128];
		bool random	 = GetConVarInt(g_hPlayType) == 1;
		bool success = GetSound(sounds, g_hSoundPath, random, szSound, sizeof(szSound));

		if (success)
		{
			PlaySoundAll(szSound);
		}
	}

	if (GetConVarInt(g_hTP) == 1)
	{
		CreateTimer(0.1, TeleportPlayers);
	}

	if (GetConVarInt(g_DuelBeacon) == 1)
	{
		CreateBeacon(ctid);
		CreateBeacon(trid);
	}
	DeleteAllWeapons();

	ctItens = new ArrayList();
	trItens = new ArrayList();

	DropWeapons(ctid, ctItens);
	DropWeapons(trid, trItens);

	CreateTimer(3.0, SetDuelConditions);
	CPrintToChatAll("{green}%t{default}%t", "prefix", "Start Duel");
}

void SetDuelPlayer(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return;

	int Health = GetConVarInt(g_Health);
	if (Health > 0)
		SetEntProp(client, Prop_Send, "m_iHealth", Health, 1);

	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
}

public Action SetDuelConditions(Handle timer)
{
	if (DuelStarted && IsValidClient(ctid) && IsValidClient(trid))
	{
		char DuelWeapon[255];
		GetConVarString(g_hDuelArma, DuelWeapon, sizeof(DuelWeapon));

		char arrWeapons[10][255];
		int	 count = ExplodeString(DuelWeapon, ";", arrWeapons, sizeof(arrWeapons), sizeof(arrWeapons[]));

		for (int i = 0; i < count; i++)
		{
			GiveItem(ctid, arrWeapons[i]);
			GiveItem(trid, arrWeapons[i]);
		}

		SetDuelPlayer(trid);
		SetDuelPlayer(ctid);

		char fighttime[32];
		GetConVarString(g_hFightTime, fighttime, sizeof(fighttime));
		if (!StrEqual(fighttime, ""))
		{
			seconds = StringToInt(fighttime);
			if (seconds > 0)
				g_hTimeDuel = CreateTimer(1.0, cmsg, _, TIMER_REPEAT);
		}
	}
	return Plugin_Continue;
}

public void DeleteAllWeapons()
{
	for (int i = 1; i < GetMaxEntities(); i++)
	{
		if (IsValidEdict(i))
		{
			char strName[64];
			GetEdictClassname(i, strName, sizeof(strName));
			if (StrContains(strName, "weapon_", false) == -1 && StrContains(strName, "item_", false) == -1)
				continue;

			int client = GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity");
			if (client == ctid || client == trid)
			{
				continue;
			}

			RemoveEdict(i);
		}
	}
}

public void DropWeapons(int client, ArrayList arr)
{
	for (int i = 0; i < 5; i++)
	{
		int weapon = GetPlayerWeaponSlot(client, i);
		while (weapon != -1)
		{
			RemovePlayerItem(client, weapon);
			if (arr != null)
				arr.Push(EntIndexToEntRef(weapon));
			else
				RemoveEdict(weapon);

			weapon = GetPlayerWeaponSlot(client, i);
		}
	}
}

public void ReturnWeapons(int client, ArrayList arr)
{
	for (int i = 0; i < arr.Length; i++)
	{
		int		 weapon = arr.Get(i);

		DataPack pack	= new DataPack();
		pack.WriteCell(client);
		pack.WriteCell(weapon);
		CreateTimer(0.1, wTime, pack);
	}
}

public Action wTime(Handle time, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int weapon = EntRefToEntIndex(pack.ReadCell());
	if (IsValidClient(client) && IsPlayerAlive(client) && IsValidEdict(weapon))
	{
		EquipPlayerWeapon(client, weapon);
	}
	return Plugin_Continue;
}

int GiveItem(int client, char[] weapon, int index = 0)
{
	if (CSGO && !IsCSGOWeapon(weapon))
		return -1;

	int entity = GivePlayerItem(client, weapon);
	if (CSGO && index > 0)
	{
		SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
		CS_DropWeapon(client, entity, false);
		EquipPlayerWeapon(client, entity);
	}
	return entity;
}

public Action cmsg(Handle timer, any client)
{
	if (g_hTimeDuel == INVALID_HANDLE)
		return Plugin_Handled;

	if (seconds > 0)
	{
		PrintCenterTextAll("%d %t", seconds, "Fight Time");
		seconds--;
	}
	else
	{
		KillTimer(g_hTimeDuel);
		g_hTimeDuel = INVALID_HANDLE;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i))
			{
				ForcePlayerSuicide(i);
			}
		}
		CPrintToChatAll("{green}%t\x01%t", "prefix", "Duel Canceled");
	}
	return Plugin_Continue;
}

public Action TeleportPlayers(Handle timer, any client)
{
	if (DuelStarted && IsValidClient(ctid) && IsPlayerAlive(ctid) && IsValidClient(trid) && IsPlayerAlive(trid))
	{
		float ctvec[3];
		float tvec[3];
		float distance[1];
		GetClientAbsOrigin(ctid, ctvec);
		GetClientAbsOrigin(trid, tvec);
		distance[0] = GetVectorDistance(ctvec, tvec, true);
		if (distance[0] >= 600000.0)
		{
			teleloc = ctvec;
			CreateTimer(1.0, DoTp);
		}
	}
	return Plugin_Continue;
}

public Action DoTp(Handle timer)
{
	if (DuelStarted && IsValidClient(trid) && IsPlayerAlive(trid))
	{
		TeleportEntity(trid, teleloc, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Continue;
}

public int trs_vivos()
{
	if(GetConVarInt(g_IgnoreBots) == 0)
	{
		int g_TRs = 0;
		for (int  i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				g_TRs++;
			}
		}
		return g_TRs;
	}
	else
	{
		int g_TRs, g_Bots;
		g_TRs = 0;
		g_Bots = 0;
		for (int  i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				IsFakeClient(i) ? g_Bots++ : g_TRs++;
			}
		}
		if(g_TRs == 1 && g_Bots > 0)
			return g_TRs + g_Bots;
		return g_TRs;
	}
}

public int cts_vivos()
{
	if(GetConVarInt(g_IgnoreBots) == 0)
	{
		int g_CTs = 0;
		for (int  i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
			{
				g_CTs++;
			}
		}
		return g_CTs;
	}
	else
	{
		int g_CTs, g_Bots;
		g_CTs = 0;
		g_Bots = 0;
		for (int  i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
			{
				IsFakeClient(i) ? g_Bots++ : g_CTs++;
			}
		}
		if(g_CTs == 1 && g_Bots > 0)
			return g_CTs + g_Bots;
		return g_CTs;
	}
}

int GetIntCookie(int client, Handle handle)
{
	char sCookieValue[11];
	GetClientCookie(client, handle, sCookieValue, sizeof(sCookieValue));
	return StringToInt(sCookieValue);
}

void CreateBeacon(int client)
{
	g_BeaconSerial[client] = ++g_Serial_Gen;
	CreateTimer(1.0, Timer_Beacon, client | (g_Serial_Gen << 7), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void KillBeacon(int client)
{
	g_BeaconSerial[client] = 0;

	if (IsValidClient(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

void KillAllBeacons()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		KillBeacon(i);
	}
}

public Action Timer_Beacon(Handle timer, any value)
{
	int client = value & 0x7f;
	int serial = value >> 7;

	if (!IsValidClient(client)
		|| !IsPlayerAlive(client)
		|| g_BeaconSerial[client] != serial)
	{
		KillBeacon(client);
		return Plugin_Stop;
	}

	int	  team = GetClientTeam(client);

	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	if (g_BeamSprite > -1 && g_HaloSprite > -1)
	{
		TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
		TE_SendToAll();

		if (team == 2)
		{
			TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
		}
		else if (team == 3)
		{
			TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);
		}
		else
		{
			TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, greenColor, 10, 0);
		}

		TE_SendToAll();
	}

	if (g_BlipSound[0])
	{
		GetClientEyePosition(client, vec);
		EmitAmbientSound(g_BlipSound, vec, client, SNDLEVEL_RAIDSIREN);
	}

	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
