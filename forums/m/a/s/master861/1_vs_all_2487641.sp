#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <smlib>
#include emitsoundany.inc

#define HIDE_RADAR_CSGO 1<<12
#define IN_FORWARD	  (1 << 3)
#define IN_BACK	  (1 << 4)
#define IN_MOVELEFT	 (1 << 9)
#define IN_MOVERIGHT		(1 << 10)
#define PLUGIN_VERSION "1.0.9"
new String:skyname[32];
new String:lightlevel[2];

new g_iAccount;
new weaponslot1;
new weaponslot2;
new weaponslotc4;
new BossPlayer;
new CheckRealPlayers;
new initialBossHealth;
new currentHealth;
new OldPlayerSelected;
new LastCT;
new BossAlive;
new g_GameMod;
new g_SubGameMod;
new GLOW_ENTITY;

new Float:g_fBossGravity[MAXPLAYERS + 1];
new MoveType:gMT_MoveTypeBoss[MAXPLAYERS + 1];

new bool:g_isDemap = false;
new bool:RageStart = false;
new Handle:g_hGameEnable = INVALID_HANDLE;
new bool:g_bGameEnable;
new Handle:g_hSkybox = INVALID_HANDLE;
new bool:g_bSkybox;

new Handle:g_hNV = INVALID_HANDLE;
new bool:g_bNV;

new Handle:g_hPredaEnable = INVALID_HANDLE;
new bool: g_bPredaEnable;
new Handle:g_hBatEnable = INVALID_HANDLE;
new bool:g_bBatEnable;
new Handle:g_hDukeEnable = INVALID_HANDLE;
new bool:g_bDukeEnable;
new Handle:g_hInvNoMove = INVALID_HANDLE;
new bool:g_bInvNoMove;

new Handle:g_hCvarFovTer;
new Handle:g_hEnergyPreda;
new Handle:g_hEnergyBat;
new Handle:g_hEnergyDuke;
new Handle:TimerShowHealth = INVALID_HANDLE;
new Handle:TimerC4Give = INVALID_HANDLE;

new bool:g_bPredator = false;
new bool:g_bBatMan = false;
new bool:g_bDuke = false;
new bool:g_bLastCT = false;

public Plugin:myinfo = {
	name = "1 vs all",
	author = "-GoV-TonyBaretta",
	description = "1 vs all",
	version = PLUGIN_VERSION,
	url = "http://www.wantedgov.it"
};
public OnMapStart()
{
	
	SetLightStyle(0,lightlevel);
	PrecacheSoundAny("buttons/light_power_on_switch_01.wav");
	PrecacheSoundAny("buttons/combine_button_locked.wav");
	PrecacheSoundAny("ambient/tones/elev4.wav");
	PrecacheSoundAny("music/1_vs_all/batsong.mp3");
	PrecacheModel("models/player/mapeadores/morell/predator/predator.mdl");
	PrecacheModel("models/player/mapeadores/morell/batman/batmanfix.mdl");
	PrecacheModel("models/player/kuristaja/duke/duke.mdl");
	decl String:file[256];
	BuildPath(Path_SM, file, 255, "configs/1_vs_all_dl.ini");
	new Handle:fileh = OpenFile(file, "r");
	if (fileh != INVALID_HANDLE)
	{
		decl String:buffer[256];
		decl String:buffer_full[PLATFORM_MAX_PATH];

		while(ReadFileLine(fileh, buffer, sizeof(buffer)))
		{
			TrimString(buffer);
			if ( (StrContains(buffer, "//") == -1) && (!StrEqual(buffer, "")) )
			{
				PrintToServer("Reading downloads line :: %s", buffer);
				Format(buffer_full, sizeof(buffer_full), "%s", buffer);
				if (FileExists(buffer_full))
				{
					PrintToServer("Precaching %s", buffer);
					PrecacheDecal(buffer, true);
					AddFileToDownloadsTable(buffer_full);
				}
			}
		}
	}
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if (strncmp(mapname, "de_", 3) == 0)
	{
		g_isDemap = true;
	}
} 
public OnPluginStart()
{
	CreateConVar("csgo_1vsall_version", PLUGIN_VERSION, "Current 1 vs all version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_spawn", Player_Spawn, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", PlayerDeath); //When player suicide
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_Drop, "drop");
	AddCommandListener(Command_Rage, "+lookatweapon");
	AddCommandListener(Command_Rage, "-lookatweapon");
	AddCommandListener(Command_Use, "+use");
	AddCommandListener(Command_Use, "-use");
	RegAdminCmd("sm_1vsall_start", Command_AdminStart, ADMFLAG_ROOT, "Enable mod by admin command");
	HookEvent("item_pickup", OnItemPickUp, EventHookMode_Pre);
	g_hGameEnable = CreateConVar("1vsall_enable", "1", "Enable / Disable Plugin");
	g_bGameEnable = GetConVarBool(g_hGameEnable);
	g_hPredaEnable = CreateConVar("predator_enable", "1", "Enable Predator if set 1");
	g_bPredaEnable = GetConVarBool(g_hPredaEnable);
	g_hBatEnable = CreateConVar("batman_enable", "1", "Enable batman if set 1");
	g_bBatEnable = GetConVarBool(g_hBatEnable);
	g_hDukeEnable = CreateConVar("dukenukem_enable", "1", "Enable dukenukem if set 1");
	g_bDukeEnable = GetConVarBool(g_hDukeEnable );
	g_hCvarFovTer = CreateConVar("1vsall_Fov", "110", "Set fov distance for terror");
	g_hEnergyPreda = CreateConVar("predator_health", "100", "Predator Health, set here how much health give to Boss for EACH CLIENT ");
	g_hEnergyBat = CreateConVar("batman_health", "90", "BatMan Health, set here how much health give to Boss for EACH CLIENT ");
	g_hEnergyDuke = CreateConVar("dukenukem_health", "140", "DukeNukem Health, set here how much health give to Boss for EACH CLIENT ");
	g_hSkybox = CreateConVar("1vsall_skybox_lights", "0", "Set Customskybox and lights if change need restart the server");
	g_bSkybox = GetConVarBool(g_hSkybox);
	g_hInvNoMove = CreateConVar("full_inv_no_move", "0", "When Boss  don't  moving become invisible , 1 for enable");
	g_bInvNoMove = GetConVarBool(g_hInvNoMove);
	if(g_bGameEnable){
		SetConVarInt(FindConVar("mp_autoteambalance"), 0);
		SetConVarInt(FindConVar("sv_disable_immunity_alpha"), 1);
		SetConVarInt(FindConVar("mp_limitteams"), 0);
		g_hNV = CreateConVar("1vsall_nightvision", "1", "Set Nightvision for terror");
		SetConVarInt(FindConVar("mp_warmuptime"), 15);
		g_bNV = GetConVarBool(g_hNV);
	}
	if(!g_bGameEnable){
		SetConVarInt(FindConVar("mp_autoteambalance"), 1);
		SetConVarInt(FindConVar("mp_limitteams"), 1);
		SetConVarInt(FindConVar("sv_disable_immunity_alpha"), 0);
		g_hNV = CreateConVar("1vsall_nightvision", "0", "Set Nightvision for terror");
		g_bNV = GetConVarBool(g_hNV);
	}
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if(g_bSkybox){
		LoadKV();
		ServerCommand("sv_skyname %s",skyname);
	}
	AutoExecConfig(true, "1_vs_all_config");
}
public LoadKV()
{
	new Handle:kv = CreateKeyValues("LigheStyle");
	if (!FileToKeyValues(kv,"cfg/sourcemod/lightstyle.txt"))
	{
		return;
	}
	if (KvJumpToKey(kv, "Settings"))
	{
		KvGetString(kv,"lightlevel",lightlevel, sizeof(lightlevel));
		KvGetString(kv,"skyname",skyname, sizeof(skyname));
		KvGoBack(kv);
	}
	
	CloseHandle(kv);	
}
public Action:OnPlayerRunCmd(client, &buttons, &Impulse, Float:Vel[3], Float:Angles[3], &Weapon)
{
	new iButtons = GetClientButtons(client);
	if (client <= 0) return Plugin_Handled;
	if ((iButtons & IN_MOVELEFT) || (iButtons & IN_MOVERIGHT) || (iButtons & IN_FORWARD) || (iButtons & IN_BACK) || (iButtons & IN_ATTACK) || (iButtons & IN_ATTACK2)) {
		if(((GetClientTeam(client) == CS_TEAM_T) && (client == BossPlayer)) || (IsFakeClient(client) && (GetClientTeam(client) == CS_TEAM_T)) && (client == BossPlayer)){
			SetEntProp(client, Prop_Data, "m_nButtons", iButtons);
			CreateTimer(0.0, PredaVisible, client);
		}
	}
	else
	if(!g_bLastCT  && (client == BossPlayer) && ((GetEntityFlags(client) & FL_ONGROUND) ) && (g_bInvNoMove) ){
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 0);
	}
	if(g_bLastCT){
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	return Plugin_Continue
}
public OnClientPutInServer(client) {
	if(g_bGameEnable){
		CreateTimer(15.0, Welcome, client);
	}
}

public Action:Command_AdminStart(client, args){
	g_bGameEnable = GetConVarBool(g_hGameEnable);
	if(!g_bGameEnable){
		SetConVarBool(g_hGameEnable,true);
		g_bGameEnable = GetConVarBool(g_hGameEnable);
		CS_TerminateRound(2.0, CSRoundEnd_Draw);
		SetConVarInt(FindConVar("sv_disable_immunity_alpha"), 1);
		Client_PrintToChatAll(false,"CSGO 1 VS ALL MOD IS ON");
		return Plugin_Handled;
	}
	else
	SetConVarBool(g_hGameEnable,false);
	g_bGameEnable = GetConVarBool(g_hGameEnable);
	CS_TerminateRound(2.0, CSRoundEnd_Draw);
	SetConVarInt(FindConVar("sv_disable_immunity_alpha"), 0);
	Client_PrintToChatAll(false,"CSGO 1 VS ALL MOD IS OFF");
	return Plugin_Handled;
}
// EVENTS
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	g_bGameEnable = GetConVarBool(g_hGameEnable);
	if(!g_bGameEnable){
		SetConVarInt(FindConVar("mp_autoteambalance"), 1);
		SetConVarInt(FindConVar("mp_limitteams"), 1);
		SetConVarInt(FindConVar("sv_disable_immunity_alpha"), 0);
		SetConVarBool(g_hNV,false);
		g_bNV = GetConVarBool(g_hNV);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (i <= 0) return Plugin_Handled;
			if((IsValidClient(i)) && (GetClientTeam(i) != 1)){
				SetEntityGravity(i, 1.0);
				SetEntProp(i, Prop_Send, "m_bNightVisionOn", 0);
				SetEntProp(i, Prop_Send, "m_iDefaultFOV", 90);
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				SetClientOverlay(i, "");
			}
		}
		BossPlayer = 0;
		return Plugin_Handled;
	}
	else
	if(g_bGameEnable){
		SetConVarInt(FindConVar("mp_autoteambalance"), 0);
		SetConVarInt(FindConVar("mp_limitteams"), 0);
		SetConVarInt(FindConVar("sv_disable_immunity_alpha"), 1);
		SetConVarInt(FindConVar("mp_warmuptime"), 10);
		SetConVarBool(g_hNV,true);
		g_bNV = GetConVarBool(g_hNV);
	}
	g_bDukeEnable = GetConVarBool(g_hDukeEnable);
	g_bBatEnable = GetConVarBool(g_hBatEnable);
	g_bPredaEnable = GetConVarBool(g_hPredaEnable);
	g_bInvNoMove = GetConVarBool(g_hInvNoMove);
	g_bPredator = false;
	g_bBatMan = false;
	g_bDuke = false;
	RageStart = false;
	g_bLastCT = false;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (client <= 0) return Plugin_Handled;
		if((IsValidClient(client)) && (GetClientTeam(client) != 1) && (GetClientTeam(client) == CS_TEAM_T) && (client != BossPlayer)){
			CS_SwitchTeam(client, CS_TEAM_CT);
			CS_RespawnPlayer(client);
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, 255, 255, 255, 255); 
		}
	}
	new iEnt = -1;
	while((iEnt = FindEntityByClassname(iEnt, "weapon_c4")) != -1) //Find c4
	{
		AcceptEntityInput(iEnt,"kill"); //Destroy the entity
	}
	decl String:ClientName[50];
	BossPlayer = GetRandomPlayer();
	if (BossPlayer <= 0) return Plugin_Handled;
	else
		while(BossPlayer == OldPlayerSelected)
		{
			BossPlayer = GetRandomPlayer();
		}
	GetClientName(BossPlayer,ClientName,sizeof(ClientName));
	CS_SwitchTeam(BossPlayer, CS_TEAM_T);
	TelePlayerBoss(BossPlayer);
	CS_RespawnPlayer(BossPlayer);

	g_GameMod = GetRandomInt(1,3);
	if(g_GameMod <= 0)return Plugin_Handled;
	if(g_GameMod == 1){
		if(!g_bPredaEnable){
			g_GameMod = GetRandomInt(2,3);
		}
		else
		g_bPredator = true;
		CreatePredator();
	}
	if(g_GameMod == 2){ 
		if(!g_bBatEnable){
			g_SubGameMod = GetRandomInt(1,2);
			if((g_SubGameMod == 1) && (g_bPredaEnable)){
				g_GameMod = 1;
				g_bPredator = true;
				CreatePredator();
			}
			else
			g_SubGameMod = GetRandomInt(2,2);
			if((g_SubGameMod == 2) && (g_bDukeEnable)){
				g_GameMod = 3;
				g_bDuke = true;
				CreateDukeNukem();
			}
			else
			g_SubGameMod = 1;			
			
		}
		else
		g_bBatMan = true;
		CreateBatMan();
	}
	if(g_GameMod == 3){
		if(!g_bDukeEnable){
			g_GameMod = GetRandomInt(1,2);
		}
		else	
		g_bDuke = true;
		CreateDukeNukem();
	}
	if(IsValidClient(BossPlayer)){
		SDKHook(BossPlayer, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(BossPlayer, SDKHook_WeaponCanUse, OnWeaponCanUseBoss);
		SDKHook(BossPlayer, SDKHook_WeaponDrop, OnWeaponCanUseBoss);
	}
	if(g_isDemap && g_bGameEnable){
		CreateTimer(10.0, C4CheckStart);
		TimerC4Give = CreateTimer(60.0, C4GiveCheck, BossPlayer);
	}
	return Plugin_Continue;
}
public Action:CreatePredator(){
	if(g_bPredator){
		decl String:ClientName[50];
		GetClientName(BossPlayer,ClientName,sizeof(ClientName));
		CS_SwitchTeam(BossPlayer, CS_TEAM_T);
		CS_RespawnPlayer(BossPlayer);
		SetEntData(BossPlayer, g_iAccount, 0 );
		SetEntPropFloat(BossPlayer, Prop_Send, "m_flLaggedMovementValue", 1.6);
		SetEntityGravity(BossPlayer, 0.5);
		SetEntityModel(BossPlayer, "models/player/mapeadores/morell/predator/predator.mdl");
		SetEntityHealth(BossPlayer, (100 + GetClientCount(true)* GetConVarInt(g_hEnergyPreda)));
		initialBossHealth = GetEntProp(BossPlayer, Prop_Send, "m_iHealth");
		if ((weaponslot1 = GetPlayerWeaponSlot(BossPlayer, 0)) != -1){
			RemovePlayerItem(BossPlayer, weaponslot1);
			GivePlayerItem(BossPlayer, "weapon_awp");
			SetEntData(BossPlayer, (( FindDataMapOffs(BossPlayer, "m_iAmmo" )) + 24 ), 150);
		}
		if ((weaponslot2 = GetPlayerWeaponSlot(BossPlayer, 1)) != -1){
			RemovePlayerItem(BossPlayer, weaponslot2);
			GivePlayerItem(BossPlayer, "weapon_deagle");
			SetEntData(BossPlayer, (( FindDataMapOffs(BossPlayer, "m_iAmmo" )) + 4 ), 150);
		}
		Client_PrintToChat(BossPlayer,false, "\x04[SM]\x03 Predator Weapons are AWP + Deagle + Flash + Smoke.");
		GivePlayerItem(BossPlayer, "weapon_smokegrenade");
		GivePlayerItem(BossPlayer, "weapon_flashbang");
		Client_PrintToChatAll(false,"\x04[SM]\x03 Predator is %s", ClientName);
		if(g_bNV){
			SetEntProp(BossPlayer, Prop_Send, "m_bNightVisionOn", 1);
		}
		SetEntProp(BossPlayer, Prop_Send, "m_iDefaultFOV", GetConVarInt(g_hCvarFovTer));
		TimerShowHealth = CreateTimer(0.0, ShowHealth, _, TIMER_REPEAT);
	}
}
public Action:CreateBatMan(){
	if(g_bBatMan){
		decl String:ClientName[50];
		GetClientName(BossPlayer,ClientName,sizeof(ClientName));
		CS_SwitchTeam(BossPlayer, CS_TEAM_T);
		CS_RespawnPlayer(BossPlayer);
		SetEntData(BossPlayer, g_iAccount, 0 );
		SetEntPropFloat(BossPlayer, Prop_Send, "m_flLaggedMovementValue", 1.7); 
		SetEntityGravity(BossPlayer, 0.3);
		SetEntityModel(BossPlayer, "models/player/mapeadores/morell/batman/batmanfix.mdl");
		SetEntityHealth(BossPlayer, (100 + GetClientCount(true)* GetConVarInt(g_hEnergyBat)));
		initialBossHealth = GetEntProp(BossPlayer, Prop_Send, "m_iHealth");
		if ((weaponslot1 = GetPlayerWeaponSlot(BossPlayer, 0)) != -1){
			RemovePlayerItem(BossPlayer, weaponslot1);
		}
		if ((weaponslot2 = GetPlayerWeaponSlot(BossPlayer, 1)) != -1){
			RemovePlayerItem(BossPlayer, weaponslot2);
		}
		Client_PrintToChat(BossPlayer,false, "\x04[SM]\x03 Batman Weapons are knife + Flash + Smoke.");
		GivePlayerItem(BossPlayer, "weapon_smokegrenade");
		GivePlayerItem(BossPlayer, "weapon_flashbang");
		ClientCommand(BossPlayer, "slot3");
		Client_PrintToChatAll(false,"\x04[SM]\x03 Batman is %s", ClientName);
		if(g_bNV){
			SetEntProp(BossPlayer, Prop_Send, "m_bNightVisionOn", 1);
		}
		SetEntProp(BossPlayer, Prop_Send, "m_iDefaultFOV", GetConVarInt(g_hCvarFovTer));
		TimerShowHealth = CreateTimer(0.0, ShowHealth, _, TIMER_REPEAT);
	}
}
public Action:CreateDukeNukem(){
	if(g_bDuke){
		decl String:ClientName[50];
		GetClientName(BossPlayer,ClientName,sizeof(ClientName));
		CS_SwitchTeam(BossPlayer, CS_TEAM_T);
		CS_RespawnPlayer(BossPlayer);
		SetEntData(BossPlayer, g_iAccount, 0 );
		SetEntPropFloat(BossPlayer, Prop_Send, "m_flLaggedMovementValue", 1.2); 
		SetEntityGravity(BossPlayer, 0.5);
		SetEntityModel(BossPlayer, "models/player/kuristaja/duke/duke.mdl");
		SetEntityHealth(BossPlayer, (100 + GetClientCount(true)* GetConVarInt(g_hEnergyDuke)));
		initialBossHealth = GetEntProp(BossPlayer, Prop_Send, "m_iHealth");
		if ((weaponslot1 = GetPlayerWeaponSlot(BossPlayer, 0)) != -1){
			RemovePlayerItem(BossPlayer, weaponslot1);
			GivePlayerItem(BossPlayer, "weapon_scar20");
		}
		if ((weaponslot2 = GetPlayerWeaponSlot(BossPlayer, 1)) != -1){
			RemovePlayerItem(BossPlayer, weaponslot2);
			GivePlayerItem(BossPlayer, "weapon_elite");
		}
		PrintToChat(BossPlayer, "\x04[SM]\x03 DukeNukem Weapons are Scar20+ DualBeretta + Flash + Smoke.");
		GivePlayerItem(BossPlayer, "weapon_smokegrenade");
		GivePlayerItem(BossPlayer, "weapon_flashbang");
		Client_PrintToChatAll(false,"\x04[SM]\x03 DukeNukem is %s", ClientName);
		if(g_bNV){
			SetEntProp(BossPlayer, Prop_Send, "m_bNightVisionOn", 1);
		}
		SetEntProp(BossPlayer, Prop_Send, "m_iDefaultFOV", GetConVarInt(g_hCvarFovTer));
		TimerShowHealth = CreateTimer(0.0, ShowHealth, _, TIMER_REPEAT);
	}
}
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	if(!g_bGameEnable)return Plugin_Handled;
	for (new client = 1; client <= MaxClients; client++){
		if(IsValidClient(client) && (GetClientTeam(client) == CS_TEAM_T) && (client == BossPlayer)){
			CreateTimer(2.0, EndRoundPlayerSelected, client);
		}
		if(IsValidClient(client) && (GetClientTeam(client) == CS_TEAM_T)){
			if((weaponslot1 = GetPlayerWeaponSlot(client, 0)) != -1){
				RemovePlayerItem(client, weaponslot1);
			}
			if ((weaponslot2 = GetPlayerWeaponSlot(client, 1)) != -1){
				RemovePlayerItem(client, weaponslot2);
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 255, 255, 255, 255); 
				SetClientOverlay(client, "");
			}
			if(IsValidClient(client) && (GetClientTeam(client) == CS_TEAM_CT)&& (client != BossPlayer)){
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 255, 255, 255, 255); 
				SetClientOverlay(client, "");
			}
		}
	}
	g_bLastCT = false;
	g_bPredator = false;
	g_bBatMan = false;
	g_bDuke = false;
	ClearTimer(TimerC4Give);
	//KillTimer(TimerShowHealth);
	return Plugin_Continue;		
}
public void OnClientDisconnect(client)
{
	if(!g_bGameEnable)return;
	else
	if(client == BossPlayer)
	{
		CS_TerminateRound(2.0, CSRoundEnd_Draw);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SetClientOverlay(client, "");
		BossAlive = GetPlayerSelectedCount();
		if(BossAlive <= 0){
			CS_TerminateRound(1.0, CSRoundEnd_Draw);
		}
	}
}
public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(!g_bGameEnable)return false;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0) return false;
	if((IsValidClient(client) && GetClientTeam(client) == CS_TEAM_T) && (client != BossPlayer)){
		CS_SwitchTeam(client, CS_TEAM_CT);
		//ForcePlayerSuicide(client);
		TelePlayerNotBoss(client);
		CS_RespawnPlayer(client);
		SetEntityGravity(client, 1.0);
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
		if ((weaponslot1 = GetPlayerWeaponSlot(client, 0)) != -1){
			RemovePlayerItem(client, weaponslot1);
		}
		if ((weaponslot2 = GetPlayerWeaponSlot(client, 1)) != -1){
			RemovePlayerItem(client, weaponslot2);
		}
		GivePlayerItem(client, "weapon_m4a1");
		GivePlayerItem(client, "weapon_deagle");
		SetEntData(client, g_iAccount, 16000 );
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		if ((weaponslotc4 = GetPlayerWeaponSlot(client, 4)) != -1){
			RemovePlayerItem(client, weaponslotc4);
		}
	}	
	CreateTimer(0.0, RemoveRadar, client);
	if((IsValidClient(client) && GetClientTeam(client) == CS_TEAM_CT) && (client != BossPlayer)){
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		if ((weaponslot1 = GetPlayerWeaponSlot(client, 0)) != -1){
			RemovePlayerItem(client, weaponslot1);
		}
		if ((weaponslot2 = GetPlayerWeaponSlot(client, 1)) != -1){
			RemovePlayerItem(client, weaponslot2);
		}
		GivePlayerItem(client, "weapon_m4a1");
		GivePlayerItem(client, "weapon_deagle");
		SetEntData(client, g_iAccount, 16000 );
		SetEntityGravity(client, 1.0);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255); 
	}
	return true;
}
public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bGameEnable)return false;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0) return false;
	if (BossPlayer <= 0) return false;
	if(IsValidClient(client) && (GetClientTeam(client) == CS_TEAM_T) && (client == BossPlayer)){
		KillTimer(TimerShowHealth);
		SDKUnhook(BossPlayer, SDKHook_WeaponCanUse, OnWeaponCanUseBoss);
		SDKUnhook(BossPlayer, SDKHook_WeaponDrop, OnWeaponCanUseBoss);
		CreateTimer(2.0, EndRoundPlayerSelected, client);
	}
	BossAlive = GetPlayerSelectedCount();
	if(BossAlive <= 0) return false;
	if(BossAlive >= 1){
		LastCT = GetPlayerCount();
	}
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUseBoss);
	SDKUnhook(client, SDKHook_WeaponDrop, OnWeaponCanUseBoss);
	if(LastCT <= 0) return false;
	if(LastCT == 1){
		RageStart = false;
		g_bLastCT = true;
		decl String:LastCTName[50];
		decl String:PlayerSName[50];
		if(IsValidClient(client) && (GetClientTeam(client) == CS_TEAM_T) && (client == BossPlayer)){
			GetClientName(BossPlayer,PlayerSName,sizeof(PlayerSName));
		}
		for (new i = 1; i <= MaxClients; i++){
			if ((IsValidClient(i) && IsPlayerAlive(i) && (GetClientTeam(i) == CS_TEAM_CT)) || (IsValidClient(i) && IsFakeClient(i) && IsPlayerAlive(i) && (GetClientTeam(i) == CS_TEAM_CT))){
				if(g_bPredator){
					if ((weaponslot1 = GetPlayerWeaponSlot(i, 0)) != -1){
						RemovePlayerItem(i, weaponslot1);
						GivePlayerItem(i, "weapon_awp");
					}
					if ((weaponslot2 = GetPlayerWeaponSlot(i, 1)) != -1){
						RemovePlayerItem(i, weaponslot2);
						GivePlayerItem(i, "weapon_deagle");
					}
					SetEntData(i, (( FindDataMapOffs(i, "m_iAmmo" )) + 24 ), 150);
					SetEntData(i, (( FindDataMapOffs(i, "m_iAmmo" )) + 4 ), 150);
					Client_PrintToChat(i,false, "\x04[SM]\x03 %s Weapons are AWP + Deagle + Flash + Smoke.", LastCTName);
					GivePlayerItem(i, "weapon_smokegrenade");
					GivePlayerItem(i, "weapon_flashbang");
					SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 1.6);
					SetEntityGravity(i, 0.5);
				}
				if(g_bBatMan){
					if ((weaponslot1 = GetPlayerWeaponSlot(i, 0)) != -1){
						RemovePlayerItem(i, weaponslot1);
					}
					if ((weaponslot2 = GetPlayerWeaponSlot(i, 1)) != -1){
						RemovePlayerItem(i, weaponslot2);
					}
					Client_PrintToChat(i,false, "\x04[SM]\x03 %s Weapons are Knife + Flash + Smoke.", LastCTName);
					GivePlayerItem(i, "weapon_smokegrenade");
					GivePlayerItem(i, "weapon_flashbang");
					SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 1.7);
					SetEntityGravity(i, 0.3);
					ClientCommand(i, "slot3");
				}
				if(g_bDuke){
					if ((weaponslot1 = GetPlayerWeaponSlot(i, 0)) != -1){
						RemovePlayerItem(i, GetPlayerWeaponSlot(i, 0));
						GivePlayerItem(i, "weapon_scar20");
						SetEntData(i, (( FindDataMapOffs(i, "m_iAmmo" )) + 24 ), 150);
					}
					if ((weaponslot1 = GetPlayerWeaponSlot(i, 1)) != -1){
						RemovePlayerItem(i, GetPlayerWeaponSlot(i, 1));
						GivePlayerItem(i, "weapon_elite");
						SetEntData(i, (( FindDataMapOffs(i, "m_iAmmo" )) + 4 ), 150);
					}
					Client_PrintToChat(i,false, "\x04[SM]\x03 %s Weapons are Scar20 + DualBeretta + Flash + Smoke.", LastCTName);
					GivePlayerItem(i, "weapon_smokegrenade");
					GivePlayerItem(i, "weapon_flashbang");
					SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 1.2);
					SetEntityGravity(i, 0.5);
				}
				GetClientName(BossPlayer,PlayerSName,sizeof(PlayerSName));
				GetClientName(i,LastCTName,sizeof(LastCTName));
				Client_PrintToChatAll(false,"\x04[SM]\x03 Showdown \x05 %s \x03VS \x05 %s.", PlayerSName, LastCTName);
				SetClientOverlay(i, "1_vs_all/showdown");
				SetClientOverlay(BossPlayer, "1_vs_all/showdown");
				SetEntityHealth(BossPlayer, 100);
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(BossPlayer, 255, 255, 255, 255);
				SetEntityRenderMode(BossPlayer, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, 255, 255, 255, 255);				
				SetEntityHealth(i, 100);
				EmitSoundToAllAny("ambient/tones/elev4.wav");
				CreateTimer(3.0, RemoveOverlay, i);
				CreateTimer(3.0, RemoveOverlay, BossPlayer);
				if(g_bNV){
					SetEntProp(i, Prop_Send, "m_bNightVisionOn", 1);
				}
				SetEntProp(i, Prop_Send, "m_iDefaultFOV", GetConVarInt(g_hCvarFovTer));
				SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUseBoss);
				SDKHook(i, SDKHook_WeaponDrop, OnWeaponCanUseBoss);
			}
		}
		return true;
	}
	else
	return LastCT;
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype){
	if (BossPlayer <= 0) return Plugin_Handled;
	currentHealth = GetEntProp(BossPlayer, Prop_Send, "m_iHealth");
	if((currentHealth <= (initialBossHealth / 2)) && (victim == BossPlayer) && (!g_bLastCT)){
		RageStart = true;
		SetClientOverlay(victim, "1_vs_all/rage_1");
	}
	return Plugin_Continue;
}

public Action:OnItemPickUp(Handle:hEvent, const String:szName[], bool:bDontBroadcast){
	if(!g_bGameEnable)return Plugin_Handled;
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (iClient <= 0) return Plugin_Handled;
	if(g_bBatMan){
		if(IsValidClient(iClient) && (GetClientTeam(iClient) == CS_TEAM_T) && (iClient == BossPlayer)){
			if ((weaponslot1 = GetPlayerWeaponSlot(iClient, 0)) != -1){
				RemovePlayerItem(iClient, weaponslot1);
			}
			if ((weaponslot2 = GetPlayerWeaponSlot(iClient, 1)) != -1){
				RemovePlayerItem(iClient, weaponslot2);
			}
			ClientCommand(iClient, "slot3");
		}
		if(IsValidClient(iClient) && (GetClientTeam(iClient) == CS_TEAM_CT) && (g_bLastCT)){
			if ((weaponslot1 = GetPlayerWeaponSlot(iClient, 0)) != -1){
				RemovePlayerItem(iClient, weaponslot1);
			}
			if ((weaponslot2 = GetPlayerWeaponSlot(iClient, 1)) != -1){
				RemovePlayerItem(iClient, weaponslot2);
			}
			ClientCommand(iClient, "slot3");
		}
	}
	if(g_bPredator){
		if(IsValidClient(iClient) && (GetClientTeam(iClient) == CS_TEAM_T) && (iClient == BossPlayer)){
			if ((weaponslot1 = GetPlayerWeaponSlot(iClient, 0)) != -1){
				return Plugin_Handled;
			}
			if ((weaponslot2 = GetPlayerWeaponSlot(iClient, 1)) != -1){
				return Plugin_Handled;
			}
		}
		if(IsValidClient(iClient) && (GetClientTeam(iClient) == CS_TEAM_CT) && (g_bLastCT)){
			if ((weaponslot1 = GetPlayerWeaponSlot(iClient, 0)) != -1){
				return Plugin_Handled;
			}
			if ((weaponslot2 = GetPlayerWeaponSlot(iClient, 1)) != -1){
				return Plugin_Handled;
			}
		}
	}
	if(g_bDuke){
		if(IsValidClient(iClient) && (GetClientTeam(iClient) == CS_TEAM_T) && (iClient == BossPlayer)){
			if ((weaponslot1 = GetPlayerWeaponSlot(iClient, 0)) != -1){
				return Plugin_Handled;
			}
			if ((weaponslot2 = GetPlayerWeaponSlot(iClient, 1)) != -1){
				return Plugin_Handled;
			}
		}
		if(IsValidClient(iClient) && (GetClientTeam(iClient) == CS_TEAM_CT) && (g_bLastCT)){
			if ((weaponslot1 = GetPlayerWeaponSlot(iClient, 0)) != -1){
				return Plugin_Handled;
			}
			if ((weaponslot2 = GetPlayerWeaponSlot(iClient, 1)) != -1){
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}
public OnGameFrame()
{
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			new MoveType:MT_MoveType = GetEntityMoveType(i), Float:fGravity = GetEntityGravity(i);
			if(MT_MoveType == MOVETYPE_LADDER)
			{
				if(fGravity != 0.0)
				{
					g_fBossGravity[i] = fGravity;
				}
			}
			else
			{
				if(gMT_MoveTypeBoss[i] == MOVETYPE_LADDER)
				{
					SetEntityGravity(i, g_fBossGravity[i]);
				}
				g_fBossGravity[i] = fGravity;
			}
			gMT_MoveTypeBoss[i] = MT_MoveType;
		}
		else
		{
			if(IsValidClient(i) && (GetClientTeam(i) == CS_TEAM_T) && (i == BossPlayer)){
				g_fBossGravity[i] = 0.5;
				if(g_bBatMan){
					g_fBossGravity[i] = 0.3;
				}
				gMT_MoveTypeBoss[i] = MOVETYPE_WALK;
			}
		}
	}
}
//TIMERS
public Action:EndRoundPlayerSelected(Handle:timer, any:client){
	if (client <= 0) return Plugin_Handled;
	if(IsValidClient(client) && (client != BossPlayer)){
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255); 
	}
	if(IsValidClient(client) && (GetClientTeam(client) == CS_TEAM_T) && (client == BossPlayer)){
		CheckRealPlayers = GetPlayerCountRealPlayers();
		if(CheckRealPlayers >= 2){
			OldPlayerSelected = BossPlayer;
		}
		CS_SwitchTeam(client, CS_TEAM_CT);
		SetEntityGravity(client, 1.0);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);  
		SetEntData(client, g_iAccount, 16000 );
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		if ((weaponslot1 = GetPlayerWeaponSlot(client, 0)) != -1){
			RemovePlayerItem(client, weaponslot1);
		}
		if ((weaponslot2 = GetPlayerWeaponSlot(client, 1)) != -1){
			RemovePlayerItem(client, weaponslot2);
		}
		GivePlayerItem(client, "weapon_m4a1");
		GivePlayerItem(client, "weapon_deagle");
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SetClientOverlay(client, "");
	}
	return Plugin_Handled;
}
public Action:ShowHealth(Handle:timer, any:client){
	for(new i = 1; i <= MaxClients; i++)
	{
		if((IsValidClient(i)) && (IsPlayerAlive(i)) && (GetClientTeam(i) == CS_TEAM_CT) && g_bGameEnable){
			if(IsValidClient(BossPlayer) && IsPlayerAlive(BossPlayer)){
				currentHealth = GetEntProp(BossPlayer, Prop_Send, "m_iHealth");
				Client_PrintHintText(i, "Boss Health: \"%d\"", currentHealth);
			}
		}
	}
	return Plugin_Continue;
}
public Action:C4GiveCheck(Handle:timer, any:client){
	if((IsValidClient(client)) && g_bGameEnable){
		if ((weaponslotc4 = GetPlayerWeaponSlot(client, 4)) != -1){
			RemovePlayerItem(client, weaponslotc4);
			GivePlayerItem(client, "weapon_c4");
		}
		else
		GivePlayerItem(client, "weapon_c4");
	}
	TimerC4Give = INVALID_HANDLE;
	return Plugin_Handled;
}
public Action:Welcome(Handle:timer, any:client){
	if(!IsValidClient(client)) return Plugin_Handled;
	Client_PrintToChat(client,false, "\x02 CSGO 1 VS ALL \x06 %s \x01by \x05 -GoV-TonyBaretta", PLUGIN_VERSION);
	return Plugin_Handled;
}
public Action:C4CheckStart(Handle:timer){
	for (new i = 1; i <= MaxClients; i++)
	{
		if((IsValidClient(i)) && g_bGameEnable){
			if ((weaponslotc4 = GetPlayerWeaponSlot(i, 4)) != -1){
				RemovePlayerItem(i, weaponslotc4);
			}
		}
	}
	BossAlive = GetPlayerSelectedCount();
	if(BossAlive <= 0){
		for (new i = 1; i <= MaxClients; i++)
		{
			if((IsValidClient(i)) && g_bGameEnable){
				CreateTimer(0.0, EndRoundPlayerSelected, i);
			}
		}
		CS_TerminateRound(1.0, CSRoundEnd_Draw);
	}
	return Plugin_Handled;
}
public Action:PredaInvisible(Handle:timer, any:client){
	if((!IsValidClient(client)) || (client != BossPlayer) || (GetClientTeam(client) != CS_TEAM_T) || g_bLastCT) return Plugin_Handled;
	else
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 50); 
	return Plugin_Handled;
}
public Action:PredaVisible(Handle:timer, any:client){
	if((!IsValidClient(client)) || (client != BossPlayer) || (GetClientTeam(client) != CS_TEAM_T)) return Plugin_Handled;
	else
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	CreateTimer(0.1, PredaInvisible, client);

	return Plugin_Handled;
}
public Action:RemoveRadar(Handle:timer, any:client) 
{
	if((IsValidClient(client)) && (client != BossPlayer)){	  
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
	} 
}
public Action:RemoveOverlay(Handle:timer, any:client) 
{
	if(IsValidClient(client)){	  
		SetClientOverlay(client, "");
	} 
}
public Action:Slow(Handle:timer, any:i) 
{
	if((g_bLastCT) && (IsValidClient(i)) && (i != BossPlayer)){
		SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 1.6);
		EmitSoundToAllAny("buttons/combine_button_locked.wav");	
		SetClientOverlay(i, "");
	}
	if((IsValidClient(i)) && (i != BossPlayer)){
		SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 1.0);
		SetClientOverlay(i, "");
		EmitSoundToAllAny("buttons/combine_button_locked.wav");
	}
}
public Action:BatOverlayKill(Handle:timer, any:i) 
{
	if((g_bLastCT) && (IsValidClient(i)) && (i != BossPlayer)){
		EmitSoundToAllAny("buttons/combine_button_locked.wav");	
		SetClientOverlay(i, "");
	}
	if((IsValidClient(i)) && (i != BossPlayer)){
		SetClientOverlay(i, "");
		EmitSoundToAllAny("buttons/combine_button_locked.wav");
	}
}
public Action:DukeEndRage(Handle:timer, any:i) 
{
	if((g_bLastCT) && (IsValidClient(i))){
		EmitSoundToAllAny("buttons/combine_button_locked.wav");
		SetClientOverlay(i, "");
	}
	if((IsValidClient(i)) && (i != BossPlayer)) {
		SetClientOverlay(i, "");
		EmitSoundToAllAny("buttons/combine_button_locked.wav");
	}
	if(IsValidEntity(GLOW_ENTITY)){
		AcceptEntityInput(GLOW_ENTITY, "kill");
	}
}
public Action:RemoveDukeGod(Handle:timer, any:client) 
{
	if((IsValidClient(client)) && (client == BossPlayer)){
		if ((weaponslot1 = GetPlayerWeaponSlot(client, 0)) != -1){ 
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
			GivePlayerItem(client, "weapon_scar20");
			SetEntData(client, (( FindDataMapOffs(client, "m_iAmmo" )) + 24 ), 150);
		}
		if ((weaponslot1 = GetPlayerWeaponSlot(client, 1)) != -1){ 
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
			GivePlayerItem(client, "weapon_elite");
			SetEntData(client, (( FindDataMapOffs(client, "m_iAmmo" )) + 4 ), 150);
		}
		SetClientOverlay(client, "");
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	} 
}
//COMMANDS
public Action:Command_Drop(client, const String:sCommand[], iArgs)
{
	if((IsValidClient(client)) && (client == BossPlayer) || (g_bLastCT)) return Plugin_Handled;
	else
	return Plugin_Continue;
}
public Action:Command_Use(client, const String:sCommand[], iArgs)
{
	if((IsValidClient(client)) && (client == BossPlayer)){
		return Plugin_Handled;
	}
	if(g_bLastCT){
		return Plugin_Handled;
	}
	else
	return Plugin_Continue;
}
public Action:Command_Buy(client, const String:sCommand[], iArgs)
{
	if((IsValidClient(client)) && (client == BossPlayer) || (g_bLastCT))return Plugin_Handled;
	else
	return Plugin_Continue;
}
public Action:Command_Rage(client, const String:sCommand[], iArgs)
{
	if((IsValidClient(client)) && (IsPlayerAlive(client)) && (client == BossPlayer) && RageStart && (!g_bLastCT)){
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SetClientOverlay(client, "");
		if(g_bPredator){
			for (new i = 1; i <= MaxClients; i++){
				if((IsValidClient(i)) && (i != BossPlayer)){	
					SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 0.2);
					ClientCommand(i, "slot3");
					SetClientOverlay(i, "1_vs_all/rage_victim");
					EmitSoundToAllAny("buttons/light_power_on_switch_01.wav");
					Client_PrintToChatAll(false,"SLOWED");
					RageStart = false;
					CreateTimer(5.0, Slow, i);
				}
			}
		}
		if(g_bBatMan){
		for (new i = 1; i <= MaxClients; i++){
				if((IsValidClient(i)) && (i != BossPlayer)){	
					ClientCommand(i, "slot3");
					SetClientOverlay(i, "1_vs_all/rage_bat_victim");
					EmitSoundToAllAny("1_vs_all/batsong.mp3");
					Client_PrintToChatAll(false,"BatMAn");
					RageStart = false;
					CreateTimer(5.0, BatOverlayKill, i);
				}
			}
		}
		if(g_bDuke){
			if((IsValidClient(client)) && (client == BossPlayer)){	
				ClientCommand(client, "slot1");
				if ((weaponslot1 = GetPlayerWeaponSlot(client, 0)) != -1){
					RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
					GivePlayerItem(client, "weapon_m249");
				}
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				SetClientOverlay(client, "1_vs_all/rage_duke_attack");
				CreateLight(client);
				CreateTimer(5.0, RemoveDukeGod, client);
				EmitSoundToAllAny("1_vs_all/duke.mp3");
				Client_PrintToChatAll(false,"Duke");
			}
			for (new i = 1; i <= MaxClients; i++){
				if((IsValidClient(i)) && (i != BossPlayer)){
					SetClientOverlay(i, "1_vs_all/rage_duke_victim");
					CreateTimer(5.0, DukeEndRage, i);
					RageStart = false;
				}
			}
		}
	}
	return Plugin_Continue;
}

//STOCKS
stock bool:IsValidClient(iClient) {
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	if (!IsClientConnected(iClient)) return false;
	return IsClientInGame(iClient);
}
stock GetRandomPlayer()
{
	new iNumPlayers;
	decl iPlayers[MaxClients];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) > 1)
			{
				iPlayers[iNumPlayers++] = i;
			}
		}
	}
	if (iNumPlayers == 0)
	{
		return -1;
	}
	return iPlayers[GetRandomInt(0, iNumPlayers - 1)];
}
stock CreateLight(client) {
	new Float:clientposition[3];
	GetClientAbsOrigin(client, clientposition);
	clientposition[2] += 40.0;

	GLOW_ENTITY = CreateEntityByName("env_glow");

	SetEntProp(GLOW_ENTITY, Prop_Data, "m_nBrightness", 70, 4);

	DispatchKeyValue(GLOW_ENTITY, "model", "sprites/ledglow.vmt");

	DispatchKeyValue(GLOW_ENTITY, "rendermode", "3");
	DispatchKeyValue(GLOW_ENTITY, "renderfx", "14");
	DispatchKeyValue(GLOW_ENTITY, "scale", "5.0");
	DispatchKeyValue(GLOW_ENTITY, "renderamt", "255");
	DispatchKeyValue(GLOW_ENTITY, "rendercolor", "255 255 255 255");
	DispatchSpawn(GLOW_ENTITY);
	AcceptEntityInput(GLOW_ENTITY, "ShowSprite");
	TeleportEntity(GLOW_ENTITY, clientposition, NULL_VECTOR, NULL_VECTOR);

	new String:target[20];
	FormatEx(target, sizeof(target), "glowclient_%d", client);
	DispatchKeyValue(client, "targetname", target);
	SetVariantString(target);
	AcceptEntityInput(GLOW_ENTITY, "SetParent");
	AcceptEntityInput(GLOW_ENTITY, "TurnOn");
}
GetPlayerCount()
{
	new players;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && (GetClientTeam(i) == CS_TEAM_CT))
			players++;
	}
	return players;
}
GetPlayerCountRealPlayers()
{
	new players;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && !IsFakeClient(i)  && (GetClientTeam(i) == CS_TEAM_CT))
			players++;
	}
	return players;
}
GetPlayerSelectedCount()
{
	new players;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && (GetClientTeam(i) == CS_TEAM_T))
			players++;
	}
	return players;
} 
SetClientOverlay(client, String:strOverlay[])
{
	if(IsValidClient(client)){
		new iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
		SetCommandFlags("r_screenoverlay", iFlags);	
		ClientCommand(client, "r_screenoverlay \"%s\"", strOverlay);
	}
}
stock ClearTimer(&Handle:Timer)
{
	if (Timer != INVALID_HANDLE)
	{
		CloseHandle(Timer);
		Timer = INVALID_HANDLE;
	}
}
public Action:Command_JoinTeam(client, const String:command[], argc)
{
	if(!argc || !client || !IsClientInGame(client))
		return Plugin_Continue;

	if(IsValidClient(client) && IsPlayerAlive(client) && (client == BossPlayer) && (GetClientTeam(client) == CS_TEAM_T)){
		Client_PrintToChat(BossPlayer,false, "YOU CAN'T CHANGE TEAM");
		return Plugin_Handled;
	}
/* 	if(IsValidClient(client) && IsPlayerAlive(client) && (client != BossPlayer) && (GetClientTeam(client) <= 1)){
		if((IsValidClient(client) && GetClientTeam(client) == CS_TEAM_T) && (client != BossPlayer)){
			CS_SwitchTeam(client, CS_TEAM_CT);
			//ForcePlayerSuicide(client);
			TelePlayerNotBoss(client);
			CS_RespawnPlayer(client);
			SetEntityGravity(client, 1.0);
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
			SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
			if ((weaponslot1 = GetPlayerWeaponSlot(client, 0)) != -1){
				RemovePlayerItem(client, weaponslot1);
			}
			if ((weaponslot2 = GetPlayerWeaponSlot(client, 1)) != -1){
				RemovePlayerItem(client, weaponslot2);
			}
			GivePlayerItem(client, "weapon_m4a1");
			GivePlayerItem(client, "weapon_deagle");
			SetEntData(client, g_iAccount, 16000 );
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			if ((weaponslotc4 = GetPlayerWeaponSlot(client, 4)) != -1){
				RemovePlayerItem(client, weaponslotc4);
			}
		}	
		PrintToChat(client, "YOU CAN'T CHANGE TEAM");
		return Plugin_Handled;
	} */
	if(IsValidClient(client) && IsPlayerAlive(client) && (client != BossPlayer) && (GetClientTeam(client) == CS_TEAM_CT)){
		Client_PrintToChat(client,false, "YOU CAN'T CHANGE TEAM");
		return Plugin_Handled;
	}

	return Plugin_Continue;
} 
public Action:OnWeaponCanUseBoss(client, weapon)  
{  
	new iButtons = GetClientButtons(client);
	if(iButtons & IN_USE){
		if( (GetClientTeam(client) == CS_TEAM_T) || (GetClientTeam(client) == CS_TEAM_CT && g_bLastCT)) 
		{  
			return Plugin_Handled;	
		}
	}
	return Plugin_Continue;	 
}
TelePlayerBoss(client)
{	

	new entity = -1;
	new Float:Pos[3];
	while ((entity = FindEntityByClassname(entity, "info_player_terrorist")) != INVALID_ENT_REFERENCE){
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);
		}
	TeleportEntity(client, Pos, NULL_VECTOR, NULL_VECTOR);
}
TelePlayerNotBoss(client)
{	

	new entity = -1;
	new Float:CtPos[3];
	while ((entity = FindEntityByClassname(entity, "info_player_counterterrorist")) != INVALID_ENT_REFERENCE){
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", CtPos);
		}
	TeleportEntity(client, CtPos, NULL_VECTOR, NULL_VECTOR);
}