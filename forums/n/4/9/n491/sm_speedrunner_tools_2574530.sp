//SourcePawn

/*			Changelog
*	28/01/2018 Version 1.3 – Global changes; updated to v1.3!
*	11/02/2018 Version 1.3.1 – ??
*	30/04/2018 Version 1.3.2 – ??
*	09/05/2018 Version 1.3.5 – Replaced commands to ConVars; added "st_edgebug" and "st_edgebug_height" ConVars.
*	24/05/2018 Version 1.3.6 – Added ConVar "st_disableledgehang".
*	26/07/2018 Version 1.3.7 – ??
*	21/08/2018 Version 1.4.8 – Added RequestFrame() for idle + takeover script; added "debug_inventory" command.
*	31/08/2018 Version 1.4.9 – Added ConVar "st_idle_anytime" and changed idle method.
*	07/09/2018 Version 1.4.11 – Changed ST_PlayerReplace() method; replaced to PrintToConsoleAll() since 1.9 SM build released.
*	22/11/2018 Version 1.4.12 – Added in "debug_inventory" info about weapon upgrade.
*	01/03/2019 Version 1.4.13 – Changed "st_disableledgehang" ConVar - round restart no longer required.
*	26/03/2019 Version 1.4.14 – Some changes in syntax.
*	02/07/2019 Version 1.4.15 – Added "st_idle" and "st_idletake" ConVar.
*	27/09/2019 Version 1.4.16 – Added "st_idlereplace" ConVar for convenient work in VScript without frame requests;
*							added Func_AnyTake() in "round_start" event as well.
*	28/04/2020 Version 1.4.17 – Changed "debug_inventory" command: added position prediction to the next map for convenience;
*							added "Summary" paragraph, that includes map name, current difficulty and all Survivor team players.
*							Fixed ST_Idle method: removed "incapacitated" condition (why it was there before for so long time??).
*							Some changes in syntax.
*	09/12/2022 Version 1.4.18 – Fast reload feature has been adapted under the new MR update (v1.4.14), due to incorrect IDLE record.
*	17/01/2023 Version 1.4.19 – Added hook OnEntityCreated and OnEntityDestroyed for VScript.
*	21/08/2023 Version 1.4.20 – Added in "debug_inventory" info about player's angles.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VER "1.4.20"
#define MAXCLIENTS 32
#define OFFSET_RIFLE 12
#define OFFSET_SMG 20
#define OFFSET_SHOTGUN 28
#define OFFSET_AUTOSHOTGUN 32
#define OFFSET_HUNTING_SNIPER 36
#define OFFSET_MILITARY_SNIPER 40
#define OFFSET_GRENADE_LAUNCHER 68
#define UPGRFL_INCENDIARY 	(1 << 0)
#define UPGRFL_EXPLOSIVE 		(1 << 1)
#define UPGRFL_LASER 			(1 << 2)

new Handle:g_ConVar_FastReload;
new Handle:g_ConVar_FastBW;
new Handle:g_ConVar_TankBoost;
new Handle:g_ConVar_Edgebug;
new Handle:g_ConVar_Edgebug_Height;
new Handle:g_ConVar_DLH;
new Handle:g_ConVar_IdleAnytime;
new Handle:g_ConVar_Idle;
new Handle:g_ConVar_IdleTake;
new Handle:g_ConVar_IdleReplace;
new Handle:g_ConVar_AllowHooks;

new bool:g_bIsRestarting;
new g_iOwner[MAXCLIENTS + 1];
new g_iBot[MAXCLIENTS + 1];
new Handle:g_hSetHumanSpec;
new Handle:g_hTakeOverBot;
new Handle:g_hGoAwayFromKeyboard;
new Handle:g_hTable;
new Handle:g_hTrie;
new String:g_ExpectedDifficulty[16];

public Plugin:myinfo =
{
	name = "Speedrunner Tools",
	author = "noa1mbot",
	description = "Used to embed functionality in the Scripted Maps mode of the Speedrunner Tools addon.",
	version = PLUGIN_VER,
	url = "http://steamcommunity.com/sharedfiles/filedetails/?id=510955402"
}

//========================================================================================================================
//Speedrunner Tools
//========================================================================================================================

public OnPluginStart()
{
	CreateConVar("st_version", PLUGIN_VER, "Current version of Speedrunner Tools.", FCVAR_NOTIFY | FCVAR_SPONLY);
	g_ConVar_FastReload = CreateConVar("st_fastreload", "0", "Toggle fast weapon reload.", FCVAR_NOTIFY);
	g_ConVar_FastBW = CreateConVar("st_fastbw", "1", "Quick preparing to b&w.", FCVAR_NOTIFY);
	g_ConVar_TankBoost = CreateConVar("st_tankboost", "1", "Toggle tank boost.", FCVAR_NOTIFY);
	g_ConVar_Edgebug = CreateConVar("st_edgebug", "0", "Allow auto-edgebugs on the server.", FCVAR_NOTIFY);
	g_ConVar_Edgebug_Height = CreateConVar("st_edgebug_height", "680.0", "Specify the height of edgebug.", FCVAR_NOTIFY);
	g_ConVar_DLH = CreateConVar("st_disableledgehang", "1", "Disable ledge hang on the server.", FCVAR_NOTIFY);
	g_ConVar_IdleAnytime = CreateConVar("st_idle_anytime", "0", "Allow idle even if no human players in game.", FCVAR_NOTIFY);
	g_ConVar_Idle = CreateConVar("st_idle", "0", "The same like \"go_away_from_keyboard\", but without delay.");
	g_ConVar_IdleTake = CreateConVar("st_idletake", "0", "The same like \"sb_takecontrol\".");
	g_ConVar_IdleReplace = CreateConVar("st_idlereplace", "0 0", "Replace players by indexes.");
	g_ConVar_AllowHooks = CreateConVar("st_allow_sdkhooks", "0", "Allow sending of SDKHooks data to the VScript.");
	
	RegConsoleCmd("sm_setammo", Cmd_SetAmmo);
	RegConsoleCmd("sm_ccmd", Cmd_ClientCommand);
	RegConsoleCmd("sm_restart", Cmd_SpeedrunRestart);
	RegConsoleCmd("sm_fake", Cmd_FakeClientControl);
	RegConsoleCmd("sm_name", Cmd_SetClientName);
	RegConsoleCmd("sm_idle", Cmd_Idle);
	RegConsoleCmd("sm_take", Cmd_Take);
	RegConsoleCmd("sm_replace", Cmd_PlayerReplace);
	RegConsoleCmd("noclip", Cmd_NoclipCustom);
	RegConsoleCmd("debug_inventory", Cmd_DebugInventory);
	
	HookEvent("player_bot_replace", OnGameEvent);
	HookEvent("revive_success", OnGameEvent);
	HookEvent("weapon_reload", OnGameEvent);
	HookEvent("player_spawn", OnGameEvent);
	HookEvent("player_hurt", OnGameEvent);
	HookEvent("round_start", OnGameEvent, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnGameEvent, EventHookMode_PostNoCopy);
	HookConVarChange(g_ConVar_DLH, ConVarChanged);
	HookConVarChange(g_ConVar_Idle, ConVarChanged);
	HookConVarChange(g_ConVar_IdleTake, ConVarChanged);
	HookConVarChange(g_ConVar_IdleReplace, ConVarChanged);
	HookUserMessage(GetUserMessageId("VoteStart"), VoteHook);
	HookUserMessage(GetUserMessageId("VoteFail"), VoteHook);
	HookEvent("difficulty_changed", Event_DifficultyChanged, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);
	
	decl String:sFilePath[64];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/st_signs.txt");
	if (FileExists(sFilePath))
	{
		new Handle:hConfig = LoadGameConfigFile("st_signs");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		g_hSetHumanSpec = EndPrepSDKCall();
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "TakeOverBot");
		g_hTakeOverBot = EndPrepSDKCall();
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "GoAwayFromKeyboard");
		g_hGoAwayFromKeyboard = EndPrepSDKCall();
		CloseHandle(hConfig);
	}
	
	g_hTable = CreateKeyValues("ST_PlayerInv");
	KvJumpToKey(g_hTable, "WeaponAmmoOfs", true);
	KvSetNum(g_hTable, "weapon_autoshotgun", OFFSET_AUTOSHOTGUN);
	KvSetNum(g_hTable, "weapon_shotgun_spas", OFFSET_AUTOSHOTGUN);
	KvSetNum(g_hTable, "weapon_grenade_launcher", OFFSET_GRENADE_LAUNCHER);
	KvSetNum(g_hTable, "weapon_hunting_rifle", OFFSET_HUNTING_SNIPER);
	KvSetNum(g_hTable, "weapon_sniper_military", OFFSET_MILITARY_SNIPER);
	KvSetNum(g_hTable, "weapon_rifle", OFFSET_RIFLE);
	KvSetNum(g_hTable, "weapon_rifle_ak47", OFFSET_RIFLE);
	KvSetNum(g_hTable, "weapon_rifle_desert", OFFSET_RIFLE);
	KvSetNum(g_hTable, "weapon_pumpshotgun", OFFSET_SHOTGUN);
	KvSetNum(g_hTable, "weapon_shotgun_chrome", OFFSET_SHOTGUN);
	KvSetNum(g_hTable, "weapon_smg", OFFSET_SMG);
	KvSetNum(g_hTable, "weapon_smg_silenced", OFFSET_SMG);
	KvRewind(g_hTable);
	KvJumpToKey(g_hTable, "SurvChar", true);
	KvSetString(g_hTable, "Nick", "models/survivors/survivor_gambler.mdl");
	KvSetString(g_hTable, "Coach", "models/survivors/survivor_coach.mdl");
	KvSetString(g_hTable, "Rochelle", "models/survivors/survivor_producer.mdl");
	KvSetString(g_hTable, "Ellis", "models/survivors/survivor_mechanic.mdl");
	KvSetString(g_hTable, "Bill", "models/survivors/survivor_namvet.mdl");
	KvSetString(g_hTable, "Louis", "models/survivors/survivor_manager.mdl");
	KvSetString(g_hTable, "Zoey", "models/survivors/survivor_teenangst.mdl");
	KvSetString(g_hTable, "Francis", "models/survivors/survivor_biker.mdl");
	KvRewind(g_hTable);
	KvJumpToKey(g_hTable, "WeaponMeleeName", true);
	KvSetString(g_hTable, "baseball_bat", "models/weapons/melee/v_bat.mdl");
	KvSetString(g_hTable, "cricket_bat", "models/weapons/melee/v_cricket_bat.mdl");
	KvSetString(g_hTable, "crowbar", "models/weapons/melee/v_crowbar.mdl");
	KvSetString(g_hTable, "electric_guitar", "models/weapons/melee/v_electric_guitar.mdl");
	KvSetString(g_hTable, "fireaxe", "models/weapons/melee/v_fireaxe.mdl");
	KvSetString(g_hTable, "frying_pan", "models/weapons/melee/v_frying_pan.mdl");
	KvSetString(g_hTable, "golfclub", "models/weapons/melee/v_golfclub.mdl");
	KvSetString(g_hTable, "katana", "models/weapons/melee/v_katana.mdl");
	KvSetString(g_hTable, "machete", "models/weapons/melee/v_machete.mdl");
	KvSetString(g_hTable, "tonfa", "models/weapons/melee/v_tonfa.mdl");
	KvRewind(g_hTable);
	
	g_hTrie = CreateTrie();
	SetTrieArray(g_hTrie, "c1m1_hotel", 				{2136.000, 4472.000, 1248.000,		2504.000, 5128.000, 512.000}, 6);
	SetTrieArray(g_hTrie, "c1m2_streets", 			{-7456.000, -4688.000, 448.000,	6758.820, -1426.180, 88.000}, 6);
	SetTrieArray(g_hTrie, "c1m3_mall", 				{-2048.000, -4576.000, 592.002,	-2048.000, -4576.000, 592.002}, 6);
	SetTrieArray(g_hTrie, "c2m1_highway", 			{-880.000, -2592.000, -1028.000,	1653.000, 2786.000, 60.000}, 6);
	SetTrieArray(g_hTrie, "c2m2_fairgrounds", 		{-4864.000, -5504.000, 0.000,		4080.000, 2048.000, 0.000}, 6);
	SetTrieArray(g_hTrie, "c2m3_coaster", 			{-5248.000, 1664.000, 72.000,		3120.000, 3584.000, -120.000}, 6);
	SetTrieArray(g_hTrie, "c2m4_barns", 				{-896.000, 2240.000, -176.000,		-896.000, 2240.000, -176.000}, 6);
	SetTrieArray(g_hTrie, "c3m1_plankcountry", 		{-2672.000, 400.000, 116.000,		-8176.000, 7472.000, 72.000}, 6);
	SetTrieArray(g_hTrie, "c3m2_swamp", 			{7523.000, -960.000, 192.000,		-5789.000, 2112.000, 192.000}, 6);
	SetTrieArray(g_hTrie, "c3m3_shantytown", 		{5008.000, -3776.000, 366.809,		-5104.000, -1664.000, -81.191}, 6);
	SetTrieArray(g_hTrie, "c4m1_milltown_a", 		{4032.000, -1600.000, 296.250,		3776.000, -1728.000, 296.500}, 6);
	SetTrieArray(g_hTrie, "c4m2_sugarmill_a", 		{-1773.400, -13698.300, 138.250,	-1773.400, -13698.300, 138.000}, 6);
	SetTrieArray(g_hTrie, "c4m3_sugarmill_b", 		{3776.000, -1728.000, 296.250,		4032.000, -1600.000, 296.250}, 6);
	SetTrieArray(g_hTrie, "c4m4_milltown_b", 		{4032.000, -1600.000, 296.250,		4032.000, -1600.000, 296.250}, 6);
	SetTrieArray(g_hTrie, "c5m1_waterfront", 			{-3904.000, -1264.000, -288.000,	-3904.000, -1264.000, -288.000}, 6);
	SetTrieArray(g_hTrie, "c5m2_park", 				{-9856.000, -8032.000, -208.000,	6272.000, 8352.000, 48.000}, 6);
	SetTrieArray(g_hTrie, "c5m3_cemetery", 			{7240.000, -9664.000, 113.000,		-3296.000, 4792.000, 77.000}, 6);
	SetTrieArray(g_hTrie, "c5m4_quarter", 			{1520.000, -3608.000, 128.000,		-11984.000, 5760.000, 192.000}, 6);
	SetTrieArray(g_hTrie, "c6m1_riverbank", 			{-3960.950, 1376.150, 744.000,		3239.050, -1231.850, -280.000}, 6);
	SetTrieArray(g_hTrie, "c6m2_bedlam", 			{11272.000, 5056.000, -568.000,	-2392.000, -464.000, -192.000}, 6);
	SetTrieArray(g_hTrie, "c7m1_docks", 			{1871.690, 2437.110, 184.000,		10703.700, 2437.110, 184.000}, 6);
	SetTrieArray(g_hTrie, "c7m2_barge", 			{-11080.300, 3123.700, 184.000,	1175.680, 3243.700, 176.000}, 6);
	SetTrieArray(g_hTrie, "c8m1_apartment", 			{2948.000, 3084.000, -219.023,		2948.000, 3084.000, 36.977}, 6);
	SetTrieArray(g_hTrie, "c8m2_subway", 			{10832.000, 4736.000, 41.000,		10832.000, 4736.000, 41.000}, 6);
	SetTrieArray(g_hTrie, "c8m3_sewers", 			{12469.500, 12559.000, 25.000,		12469.500, 12559.000, 25.000}, 6);
	SetTrieArray(g_hTrie, "c8m4_interior", 			{11555.400, 14884.600, 5545.000,	5539.400, 8356.600, 5545.000}, 6);
	SetTrieArray(g_hTrie, "c9m1_alleys", 			{281.000, -1356.000, -156.000,		280.000, -1292.000, -156.000}, 6);
	SetTrieArray(g_hTrie, "c10m1_caves", 			{-10912.000, -4962.410, 370.000,	-11200.000, -8994.410, -510.000}, 6);
	SetTrieArray(g_hTrie, "c10m2_drainage", 			{-8211.000, -5502.000, -23.000,		-8212.000, -5502.000, -17.000}, 6);
	SetTrieArray(g_hTrie, "c10m3_ranchhouse", 		{-2640.000, -128.000, 168.000,		-3152.000, -128.000, 168.000}, 6);
	SetTrieArray(g_hTrie, "c10m4_mainstreet", 		{1240.000, -5440.000, -15.000,		1960.000, 4576.000, -23.000}, 6);
	SetTrieArray(g_hTrie, "c11m1_greenhouse", 		{5264.000, 2800.000, 68.000,		5264.000, 2800.000, 68.000}, 6);
	SetTrieArray(g_hTrie, "c11m2_offices", 			{7960.000, 6216.000, 41.000,		-5368.000, -3016.000, 41.000}, 6);
	SetTrieArray(g_hTrie, "c11m3_garage", 			{-414.598, 3561.070, 320.000,		-414.598, 3561.070, 320.000}, 6);
	SetTrieArray(g_hTrie, "c11m4_terminal", 			{3441.120, 4525.300, 161.000,		-6558.880, 12025.300, 161.000}, 6);
	SetTrieArray(g_hTrie, "c12m1_hilltop", 			{-6527.000, -6768.000, 357.281,	-6527.000, -6768.000, 357.281}, 6);
	SetTrieArray(g_hTrie, "c12m2_traintunnel", 		{-970.000, -10378.000, -58.719,		-970.000, -10378.000, -58.719}, 6);
	SetTrieArray(g_hTrie, "c12m3_bridge", 			{7724.610, -11362.000, 449.000,	7724.610, -11362.000, 449.000}, 6);
	SetTrieArray(g_hTrie, "c12m4_barn", 			{10442.000, -354.553, -5.000,		10442.000, -354.553, -5.000}, 6);
	SetTrieArray(g_hTrie, "c13m1_alpinecreek", 		{1125.000, -966.000, 360.000,		8629.000, 7338.000, 504.000}, 6);
	SetTrieArray(g_hTrie, "c13m2_southpinestream", 	{326.000, 8807.000, -397.000,		-4338.000, -5157.000, 104.000}, 6);
	SetTrieArray(g_hTrie, "c13m3_memorialbridge", 	{6314.500, -6065.600, 402.000,		-3616.000, -9356.000, 376.000}, 6);
}

public ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_ConVar_DLH == convar)
	{
		decl String:sName[32]; sName = GetConVarBool(convar) ? "DisableLedgeHang" : "EnableLedgeHang";
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				AcceptEntityInput(i, sName);
			}
		}
	}
	else if (g_ConVar_Idle == convar)
	{
		if (StrEqual(newValue, "0")) return;
		ST_Idle(StringToInt(newValue));
		SetConVarInt(convar, 0);
	}
	else if (g_ConVar_IdleTake == convar)
	{
		if (StrEqual(newValue, "0")) return;
		ST_Idle(StringToInt(newValue), true);
		SetConVarInt(convar, 0);
	}
	else if (g_ConVar_IdleReplace == convar)
	{
		if (StrEqual(newValue, "0 0")) return;
		decl String:sValue[2][4];
		ExplodeString(newValue, " ", sValue, 2, 4);
		ST_PlayerReplace(StringToInt(sValue[0]), StringToInt(sValue[1]));
		SetConVarString(convar, "0 0");
	}
}

public OnGameEvent(Event event, const char[] name, bool dontBroadcast)
{
	if (StrEqual(name, "player_spawn"))
	{
		if (GetConVarBool(g_ConVar_DLH))
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			if (GetClientTeam(client) == 2)
			{
				AcceptEntityInput(client, "DisableLedgeHang");
			}
		}
	}
	else if (StrEqual(name, "player_bot_replace"))
	{
		g_iOwner[GetClientOfUserId(GetEventInt(event, "bot"))] = GetClientOfUserId(GetEventInt(event, "player"));
		g_iBot[GetClientOfUserId(GetEventInt(event, "player"))] = GetClientOfUserId(GetEventInt(event, "bot"));
	}
	else if (StrEqual(name, "round_start"))
	{
		g_bIsRestarting = false;
		Func_AnyTake();
	}
	else if (StrEqual(name, "round_end"))
	{
		g_bIsRestarting = true;
		Func_AnyTake();
	}
	else if (g_bIsRestarting)
	{
		return;
	}
	else if (StrEqual(name, "player_hurt"))
	{
		if (GetConVarBool(g_ConVar_TankBoost))
		{
			new entity = GetClientOfUserId(GetEventInt(event, "attacker"));
			if (HasEntProp(entity, Prop_Send, "m_zombieClass") && GetEntProp(entity, Prop_Send, "m_zombieClass") == 8)
			{
				DataPack data = CreateDataPack();
				data.WriteCell(GetClientOfUserId(GetEventInt(event, "userid")));
				RequestFrame(RF_Idle, data);
			}
		}
	}
	else if (StrEqual(name, "weapon_reload"))
	{
		if (GetConVarBool(g_ConVar_FastReload))
		{
			decl String:sEntName[64];
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			GetClientWeapon(client, sEntName, sizeof(sEntName));
			if (!StrEqual(sEntName, "weapon_chainsaw") && StrContains(sEntName, "shotgun") == -1 && StrContains(sEntName, "pistol") == -1)
			{
				DataPack data = CreateDataPack();
				data.WriteCell(client);
				data.WriteString(sEntName);
				RequestFrame(RF_Idle, data);
			}
		}
	}
	else if (StrEqual(name, "revive_success"))
	{
		if (GetConVarBool(g_ConVar_FastBW))
		{
			if (!GetEventBool(event, "ledge_hang"))
			{
				new client = GetClientOfUserId(GetEventInt(event, "subject"));
				if (GetClientOfUserId(GetEventInt(event, "userid")) != client)
				{
					DataPack data = CreateDataPack();
					data.WriteCell(client);
					RequestFrame(RF_Idle, data);
				}
			}
		}
	}
}

public RF_Idle(DataPack data)
{
	data.Reset();
	new client = data.ReadCell();
	decl Float:fOrigin[3]; GetClientAbsOrigin(client, fOrigin);
	ST_Idle(client);
	TeleportEntity(client, fOrigin, NULL_VECTOR, NULL_VECTOR);	//fix origin beforehand in case the auto-IDLEs will be disabled (for MR)
	RequestFrame(RF_Take, data);
}

public RF_Take(DataPack data)
{
	data.Reset();
	ST_Idle(data.ReadCell(), true);
	if (data.IsReadable(9))
	{
		RequestFrame(RF_Switch, data);
		return;
	}
	delete data;
}

public RF_Switch(DataPack data)
{
	data.Reset();
	new client = data.ReadCell();
	if (IsPlayer(client))
	{
		decl String:sEntName[64];
		data.ReadString(sEntName, sizeof(sEntName));
		FakeClientCommand(client, "use %s", sEntName);
	}
	delete data;
}

public Action:OnPlayerRunCmd(int client)
{
	if (GetConVarBool(g_ConVar_Edgebug))
	{
		if (GetEntityMoveType(client) == MOVETYPE_WALK)
		{
			if (!(GetEntityFlags(client) & FL_ONGROUND))
			{
				static float fPlayerVel[MAXCLIENTS + 1];
				new Float:fVelocity = GetEntPropFloat(client, Prop_Data, "m_flFallVelocity");
				if (fVelocity == fPlayerVel[client] && fVelocity > GetConVarFloat(g_ConVar_Edgebug_Height))
				{
					ST_Idle(client);
					FakeClientCommandEx(client, "sm_take");
				}
				fPlayerVel[client] = fVelocity;
			}
		}
	}
	return Plugin_Continue;
}

public Func_AnyTake()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 1)
		{
			SDKCall(g_hTakeOverBot, i);
		}
	}
}

public OnEntityCreated(int entity, const char[] classname)
{
	if (GetConVarBool(g_ConVar_AllowHooks))
	{
		decl String:sCode[128];
		Format(sCode, sizeof(sCode), "if (\"OnEntityCreated\" in getroottable()) OnEntityCreated(self, \"%s\")", classname);
		SetVariantString(sCode);
		AcceptEntityInput(entity, "RunScriptCode");
	}
}

public OnEntityDestroyed(int entity)
{
	if (GetConVarBool(g_ConVar_AllowHooks))
	{
		SetVariantString("if (\"OnEntityDestroyed\" in getroottable()) OnEntityDestroyed(self)");
		AcceptEntityInput(entity, "RunScriptCode");
	}
}

//========================================================================================================================
//Cmds
//========================================================================================================================

public Action:Cmd_SetAmmo(client, args)
{
	if (args > 2 && args <= 5)
	{
		decl String:sArg[4];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		if (IsPlayer(client))
		{
			GetCmdArg(2, sArg, sizeof(sArg));
			new iSlot = StringToInt(sArg);
			if (iSlot == 0 || iSlot == 1)
			{
				new entity = GetPlayerWeaponSlot(client, iSlot);
				if (IsValidEntity(entity))
				{
					decl String:sEntName[64];
					GetEntityClassname(entity, sEntName, sizeof(sEntName));
					if (StrEqual(sEntName, "weapon_melee"))
					{
						PrintToChatAll("[SETAMMO] Cannot change ammo for \"%s\".", sEntName);
						return Plugin_Handled;
					}
					GetCmdArg(3, sArg, sizeof(sArg));
					SetEntProp(entity, Prop_Send, "m_iClip1", StringToInt(sArg));
					if (args > 3 && iSlot == 0)
					{
						GetCmdArg(4, sArg, sizeof(sArg));
						decl String:sKeyValue[64];
						new bool:bValue;
						KvRewind(g_hTable);
						KvJumpToKey(g_hTable, "WeaponAmmoOfs");
						KvGotoFirstSubKey(g_hTable, false);
						do
						{
							KvGetSectionName(g_hTable, sKeyValue, sizeof(sKeyValue));
							if (StrEqual(sEntName, sKeyValue))
							{
								bValue = true;
								SetEntData(client, FindDataMapInfo(client, "m_iAmmo") + KvGetNum(g_hTable, NULL_STRING), StringToInt(sArg));
								break;
							}
						}
						while (KvGotoNextKey(g_hTable, false));
						if (!bValue)
						{
							PrintToChatAll("[SETAMMO] Weapon \"%s\" is not in offset table.", sEntName);
							return Plugin_Handled;
						}
						if (args > 4)
						{
							GetCmdArg(5, sArg, sizeof(sArg));
							new iUpgrade = StringToInt(sArg);
							if (iUpgrade > 0 && GetEntProp(entity, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") > 0)
							{
								SetEntProp(entity, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", iUpgrade);
							}
							else PrintToChatAll("[SETAMMO] Not found upgrade ammo in clip.");
						}
					}
				}
				else PrintToChatAll("[SETAMMO] Weapon not found.");
			}
			else PrintToChatAll("[SETAMMO] Invalid slot specified.");
		}
		else PrintToChatAll("[SETAMMO] Client %d is invalid.", client);
	}
	else PrintToChatAll("[SETAMMO] Wrong number of arguments.");
	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_ClientCommand(client, args)
{
	if (args == 2)
	{
		decl String:sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		if (IsPlayer(client))
		{
			GetCmdArg(2, sArg, sizeof(sArg));
			FakeClientCommand(client, sArg);
		}
	}
	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_SpeedrunRestart(client, args)
{
	if (client == 0) client = 1;
	if (IsClientInGame(client))
	{
		SetVariantString("SpeedrunRestart()");
		AcceptEntityInput(client, "RunScriptCode");
	}
	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_FakeClientControl(client, args)
{
	if (args == 0)
	{
		decl String:sArg[4];
		client = CreateFakeClient("");
		Format(sArg, sizeof(sArg), "%d", client);
		SetClientName(client, sArg);
		ChangeClientTeam(client, 2);
		return Plugin_Handled;
	}
	decl String:sArg[16];
	GetCmdArg(1, sArg, sizeof(sArg));
	if (StringToInt(sArg) != 0)
	{
		client = CreateFakeClient("");
		ChangeClientTeam(client, StringToInt(sArg));
		Format(sArg, sizeof(sArg), "%d", client);
		SetClientName(client, sArg);
	}
	else if (StrEqual(sArg, "kill"))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i))
			{
				KickClient(i);
			}
		}
	}
	else if (StrEqual(sArg, "idle"))
	{
		if (client > 0 && (client = GetClientAimTarget(client)) != -1)
		{
			if (!IsPlayerABot(client)) ST_Idle(client);
			else ST_Idle(g_iOwner[client], true);
		}
	}
	else if (StrEqual(sArg, "take"))
	{
		Func_AnyTake();
	}
	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_SetClientName(client, args)
{
	if (args == 2)
	{
		decl String:sArg[MAX_NAME_LENGTH];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		if (IsPlayer(client))
		{
			GetCmdArg(2, sArg, sizeof(sArg));
			SetClientName(client, sArg);
		}
	}
	else if (client > 0)
	{
		decl String:sArg[MAX_NAME_LENGTH];
		GetCmdArg(1, sArg, sizeof(sArg));
		SetClientName(client, sArg);
	}
	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_Idle(client, args)
{
	if (args == 1)
	{
		decl String:sArg[4];
		GetCmdArg(1, sArg, sizeof(sArg));
		ST_Idle(StringToInt(sArg));
	}
	else ST_Idle(client);
	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_Take(client, args)
{
	if (args == 1)
	{
		decl String:sArg[4];
		GetCmdArg(1, sArg, sizeof(sArg));
		ST_Idle(StringToInt(sArg), true);
	}
	else ST_Idle(client, true);
	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_PlayerReplace(client, args)
{
	if (args == 2)
	{
		decl String:sArg[2][4];
		GetCmdArg(1, sArg[0], 4);
		GetCmdArg(2, sArg[1], 4);
		ST_PlayerReplace(StringToInt(sArg[0]), StringToInt(sArg[1]));
	}
 	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_NoclipCustom(client, args)
{
	if (client > 0 && IsPlayerAlive(client))
	{
		if (GetEntityMoveType(client) == MOVETYPE_NOCLIP)
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
		else
		{
			SetEntityMoveType(client, MOVETYPE_NOCLIP);
		}
	}
 	return Plugin_Handled;
}

//============================================================
//============================================================

public Action:Cmd_DebugInventory(client, args)
{
	decl String:sEntName[64], String:sPlayerInv[64], String:sKeyValue[64], String:sUpgrade[64], Float:fOrigin[6], String:sMapName[32], Float:vecAng[3];
	new Float:fHealthTemp, entity, iUpgrade, iUpgradeFlag, bool:bAtLeastOne, iRevived;
	new String:sWeaponList[][] =
	{
		"weapon_propanetank",
		"weapon_gascan",
		"weapon_oxygentank",
		"weapon_gnome",
		"weapon_fireworkcrate",
		"weapon_cola_bottles"
	};
	GetCurrentMap(sMapName, sizeof(sMapName));
	GetConVarString(FindConVar("z_difficulty"), sEntName, sizeof(sEntName));
	new bool:bPredictOrigin = GetTrieArray(g_hTrie, sMapName, fOrigin, sizeof(fOrigin));
	for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i) && GetClientTeam(i) == 2) iRevived++;
	PrintToConsoleAll("===================== Summary ======================");
	PrintToConsoleAll("Map       : %s\nDifficulty: %s%s\nPlayers   : %d", sMapName, sEntName, g_ExpectedDifficulty, iRevived);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			if (!bAtLeastOne)
			{
				PrintToConsoleAll("================= Player Inventory =================");
				bAtLeastOne = true;
			}
			GetClientModel(i, sEntName, sizeof(sEntName));
			KvRewind(g_hTable);
			KvJumpToKey(g_hTable, "SurvChar");
			KvGotoFirstSubKey(g_hTable, false);
			do
			{
				KvGetString(g_hTable, NULL_STRING, sKeyValue, sizeof(sKeyValue));
				if (StrEqual(sEntName, sKeyValue))
				{
					KvGetSectionName(g_hTable, sKeyValue, sizeof(sKeyValue));
					PrintToConsoleAll("Survivor  : %s (%N)", sKeyValue, i);
					break;
				}
			}
			while (KvGotoNextKey(g_hTable, false));
			if (!GetEntProp(i, Prop_Send, "m_isIncapacitated")) PrintToConsoleAll("Health    : %d", GetClientHealth(i));
			else PrintToConsoleAll("Health    : Incapacitated");
			if ((fHealthTemp = GetHealthBuffer(i)) > 0) PrintToConsoleAll("HealthTemp: %.03f", fHealthTemp);
			if ((iRevived = GetEntProp(i, Prop_Send, "m_currentReviveCount")) > 0) PrintToConsoleAll("Revived   : %d", iRevived);
			for (new d; d < 5; d++)
			{
				entity = GetPlayerWeaponSlot(i, d);
				if (IsValidEntity(entity))
				{
					GetEntityClassname(entity, sEntName, sizeof(sEntName));
					Format(sPlayerInv, sizeof(sPlayerInv), "slot%d     : %s", d + 1, sEntName);
					if (d == 0)
					{
						if ((iUpgradeFlag = GetEntProp(entity, Prop_Send, "m_upgradeBitVec")) > 0)
						{
							sUpgrade = "Upgrade   :";
							if (iUpgradeFlag & UPGRFL_INCENDIARY) Format(sUpgrade, sizeof(sUpgrade), "%s INCENDIARY_AMMO", sUpgrade);
							else if (iUpgradeFlag & UPGRFL_EXPLOSIVE) Format(sUpgrade, sizeof(sUpgrade), "%s EXPLOSIVE_AMMO", sUpgrade);
							if (iUpgradeFlag & UPGRFL_LASER) Format(sUpgrade, sizeof(sUpgrade), "%s LASER_SIGHT", sUpgrade);
							PrintToConsoleAll(sUpgrade);
						}
						Format(sPlayerInv, sizeof(sPlayerInv), "%s (%d", sPlayerInv, GetEntProp(entity, Prop_Send, "m_iClip1"));
						KvRewind(g_hTable);
						KvJumpToKey(g_hTable, "WeaponAmmoOfs");
						KvGotoFirstSubKey(g_hTable, false);
						do
						{
							KvGetSectionName(g_hTable, sKeyValue, sizeof(sKeyValue));
							if (StrEqual(sEntName, sKeyValue))
							{
								Format(sPlayerInv, sizeof(sPlayerInv), "%s/%d", sPlayerInv, GetEntData(i, FindDataMapInfo(i, "m_iAmmo") + KvGetNum(g_hTable, NULL_STRING)));
								break;
							}
						}
						while (KvGotoNextKey(g_hTable, false));
						if ((iUpgrade = GetEntProp(entity, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded")) > 0)
						{
							Format(sPlayerInv, sizeof(sPlayerInv), "%s/%d", sPlayerInv, iUpgrade);
						}
						Format(sPlayerInv, sizeof(sPlayerInv), "%s)", sPlayerInv);
					}
					else if (d == 1)
					{
						if (StrEqual(sEntName, "weapon_melee"))
						{
							GetEntPropString(entity, Prop_Data, "m_ModelName", sEntName, sizeof(sEntName));
							KvRewind(g_hTable);
							KvJumpToKey(g_hTable, "WeaponMeleeName");
							KvGotoFirstSubKey(g_hTable, false);
							do
							{
								KvGetString(g_hTable, NULL_STRING, sKeyValue, sizeof(sKeyValue));
								if (StrEqual(sEntName, sKeyValue))
								{
									KvGetSectionName(g_hTable, sKeyValue, sizeof(sKeyValue));
									Format(sPlayerInv, sizeof(sPlayerInv), "%s (%s)", sPlayerInv, sKeyValue);
									break;
								}
							}
							while (KvGotoNextKey(g_hTable, false));
						}
						else Format(sPlayerInv, sizeof(sPlayerInv), "%s (%d)", sPlayerInv, GetEntProp(entity, Prop_Send, "m_iClip1"));
					}
					PrintToConsoleAll(sPlayerInv);
				}
			}
			GetClientWeapon(i, sEntName, sizeof(sEntName));
			for (new d; d < 6; d++)
			{
				if (StrEqual(sEntName, sWeaponList[d]))
				{
					PrintToConsoleAll("Extra     : %s", sEntName);
					break;
				}
			}
			if (bPredictOrigin)
			{
				decl Float:vecPos[2][3], Float:fPlayerPos[3];
				vecPos[0][0] = fOrigin[0]; vecPos[0][1] = fOrigin[1]; vecPos[0][2] = fOrigin[2];
				vecPos[1][0] = fOrigin[3]; vecPos[1][1] = fOrigin[4]; vecPos[1][2] = fOrigin[5];
				GetClientAbsOrigin(i, fPlayerPos);
				SubtractVectors(fPlayerPos, vecPos[0], fPlayerPos);
				AddVectors(fPlayerPos, vecPos[1], fPlayerPos);
				if (StrEqual(sMapName, "c13m3_memorialbridge")) 	// weird, "info_landmark" rotated for this map
				{
					float fOrigin_Z = fPlayerPos[2];
					GetClientAbsOrigin(i, fPlayerPos);
					MakeVectorFromPoints(fPlayerPos, vecPos[0], fPlayerPos);
					AddVectors(fPlayerPos, vecPos[1], fPlayerPos);
					fPlayerPos[2] = fOrigin_Z;
				}
				PrintToConsoleAll("Origin    : Vector(%.03f, %.03f, %.03f)", fPlayerPos[0], fPlayerPos[1], fPlayerPos[2]);
			}
			GetClientAbsAngles(i, vecAng);
			PrintToConsoleAll("Angles    : Vector(0, %.03f, 0)", vecAng[1]);
			PrintToConsoleAll("----------------------------------------------------");
		}
	}
	if (!bAtLeastOne) PrintToConsoleAll("----------------------------------------------------");
	return Plugin_Handled;
}

public Action:VoteHook(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (msg_id == GetUserMessageId("VoteStart"))
	{
		decl String:sName[32];
		BfReadString(msg, sName, sizeof(sName));
		if (StrContains(sName, "#L4D_vote_change_difficulty") != -1)
		{
			BfReadString(msg, sName, sizeof(sName));
			ReplaceString(sName, sizeof(sName), "#L4D_Difficulty", "");
			Format(g_ExpectedDifficulty, sizeof(g_ExpectedDifficulty), " (%s)", sName);
		}
	}
	if (msg_id == GetUserMessageId("VoteFail")) g_ExpectedDifficulty[0] = 0;
}

public Event_DifficultyChanged(Event event, const char[] name, bool dontBroadcast) g_ExpectedDifficulty[0] = 0;
public Event_MapTransition(Event event, const char[] name, bool dontBroadcast) ServerCommand("debug_inventory");
public OnMapStart() g_ExpectedDifficulty[0] = 0;

//========================================================================================================================
//Tools ScMp
//========================================================================================================================

stock bool:ST_Idle(client, bool:bType = false)
{
	if (IsPlayer(client) && !IsPlayerABot(client))
	{
		if (bType)
		{
			if (GetClientTeam(client) == 1)
			{
				SDKCall(g_hTakeOverBot, client);
				return true;
			}
		}
		else
		{
			if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
			{
				if (GetConVarBool(g_ConVar_IdleAnytime))
				{
					SDKCall(g_hGoAwayFromKeyboard, client);
					PrintToChatAll("[ST_Idle] %N is now idle.", client);
					return true;
				}
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsPlayerABot(i) && IsPlayerAlive(i) && client != i && GetClientTeam(i) == 2)
					{
						SDKCall(g_hGoAwayFromKeyboard, client);
						PrintToChatAll("%N is now idle.", client);
						return true;
					}
				}
			}
		}
	}
	return false;
}

//============================================================
//============================================================

stock bool:ST_PlayerReplace(client, target)
{
	if (!IsPlayer(client) || GetClientTeam(client) == 3 || IsPlayerABot(client)) return false;
	if (!IsPlayer(target) || GetClientTeam(target) == 3 || IsPlayerABot(target)) return false;
	decl String:sName[2][MAX_NAME_LENGTH];
	GetClientName(client, sName[0], MAX_NAME_LENGTH);
	GetClientName(target, sName[1], MAX_NAME_LENGTH);
	HookUserMessage(GetUserMessageId("SayText2"), MsgHook, true);
	SetClientName(target, "");
	SetClientName(client, sName[1]);
	SetClientName(target, sName[0]);
	UnhookUserMessage(GetUserMessageId("SayText2"), MsgHook, true);
	new clientKills = GetEntProp(client, Prop_Send, "m_checkpointZombieKills");
	new targetKills = GetEntProp(target, Prop_Send, "m_checkpointZombieKills");
	SetEntProp(client, Prop_Send, "m_checkpointZombieKills", targetKills);
	SetEntProp(target, Prop_Send, "m_checkpointZombieKills", clientKills);
	SDKCall(g_hTakeOverBot, client);
	SDKCall(g_hTakeOverBot, target);
	new clientTeam = GetClientTeam(client), targetTeam = GetClientTeam(target);
	if (clientTeam == 2) ChangeClientTeam(client, 1);
	if (targetTeam == 2) ChangeClientTeam(target, 1);
	if (clientTeam == 2)
	{
		SDKCall(g_hSetHumanSpec, g_iBot[client], target);
		SDKCall(g_hTakeOverBot, target);
	}
	if (targetTeam == 2)
	{
		SDKCall(g_hSetHumanSpec, g_iBot[target], client);
		SDKCall(g_hTakeOverBot, client);
	}
	return true;
}

public Action:MsgHook(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	decl String:sName[64];
	BfReadString(msg, sName, sizeof(sName));
	BfReadString(msg, sName, sizeof(sName));
	if (StrEqual(sName, "#Cstrike_Name_Change"))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

//============================================================
//============================================================

stock bool:IsPlayer(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

//============================================================
//============================================================

stock bool:IsPlayerABot(client)
{
	if (GetEntityFlags(client) & FL_FAKECLIENT)
	{
		return true;
	}
	return false;
}

//============================================================
//============================================================

stock Float:GetHealthBuffer(client)
{
	new Float:fHealthTemp = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime"))*GetConVarFloat(FindConVar("pain_pills_decay_rate")));
	return fHealthTemp > 0.0 ? fHealthTemp : 0.0;
}