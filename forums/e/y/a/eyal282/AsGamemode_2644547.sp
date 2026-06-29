// Notes: this game mode is dependant on the cvar that right now will kill any disconnecting player.

// To do: make sure as_enabled 0 actually disables all plugin content.

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

#define DUMP_WEAPON_DEF_PATH "data/AsGamemode"

#define MIN_FLOAT -2147483647.0
#define MAX_FLOAT 2147483647.0

#define HUD_PRINTTALK			3
#define HUD_PRINTCENTER		4 

#define FPERM_ULTIMATE (FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC|FPERM_G_READ|FPERM_G_WRITE|FPERM_G_EXEC|FPERM_O_READ|FPERM_O_WRITE|FPERM_O_EXEC)

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <autoexecconfig>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

enum enWeaponData 
{
	String:enWepData_Classname[64],
	enWepData_DefIndex
}
new const String:PLUGIN_VERSION[] = "2.0";

new CurrentVIP;

new bool:RoundEnded = false;

new bool:RoundStarted = false;

new moneyRef = -1;
new Debt[MAXPLAYERS+1];

new bool:isLateLoaded = false;
new ReloadPluginNR = 0;

new Handle:hcv_Enabled = INVALID_HANDLE;
new Handle:hcv_VIPAmmo = INVALID_HANDLE;
new Handle:hcv_VIPHealth = INVALID_HANDLE;
new Handle:hcv_VIPArmor = INVALID_HANDLE;
new Handle:hcv_VIPHelmet = INVALID_HANDLE;
new Handle:hcv_VIPAvoidBots = INVALID_HANDLE;
new Handle:hcv_VIPBlockSwitchTeam = INVALID_HANDLE;

new Handle:hcv_AnnounceSettings = INVALID_HANDLE;
new Handle:hcv_AnnounceSettingsDelay = INVALID_HANDLE;

new Handle:hcv_CTItemsProhibited = INVALID_HANDLE;
new Handle:hcv_TItemsProhibited = INVALID_HANDLE;

new Handle:hcv_CashPlayerKillVIP = INVALID_HANDLE;
new Handle:hcv_CashTeamKillVIP = INVALID_HANDLE;
new Handle:hcv_CashTeamRescueVIP = INVALID_HANDLE;
new Handle:hcv_ScorePlayerKillVIP = INVALID_HANDLE;
new Handle:hcv_ScorePlayerRescueVIP = INVALID_HANDLE;

new Handle:hcv_RoundRestartDelay = INVALID_HANDLE;
//new UserMsg:FadeUserMsgId;

new const String:CTModel[] = "models/player/custom_player/legacy/ctm_swat.mdl";
new const String:TModel[] = "models/player/custom_player/legacy/tm_professional.mdl";
new const String:VIPModel[] = "models/player/custom_player/legacy/ctm_gign.mdl";

new const String:CTGloves[] = "models/weapons/ct_arms_swat.mdl";
new const String:TGloves[] = "models/weapons/t_arms_professional.mdl";
new const String:VIPGloves[] = "models/weapons/ct_arms_gign.mdl";

new Handle:hCookie_VIPPrio = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[CS:GO] Assassination Game Mode ( as_mapname )",
	author = "Eyal282", // Thanks for psychonic for helping me fix crashes
	description = "One CT is VIP with higher durability and usp. If the VIP dies, CT loses the round.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2644547"
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("bot_takeover", Event_BotTakeover, EventHookMode_Post);
	HookEvent("player_use", Event_PlayerUse, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	
	HookConVarChange(FindConVar("mp_restartgame"), hcvChange_RestartGame);
	AddCommandListener(Listener_JoinTeam, "jointeam");
	
	#if defined _autoexecconfig_included
	
	AutoExecConfig_SetFile("AsGamemode");
	
	#endif
	
	hcv_Enabled = UC_CreateConVar("as_enabled", "1", "Set to 1 to enable the plugin, 0 otherwise");
	hcv_VIPAmmo = UC_CreateConVar("as_vip_ammo", "12", "Amount of reserve ammunition the VIP has for his pistol");
	hcv_VIPHealth = UC_CreateConVar("as_vip_health", "200", "Amount of health the VIP spawns with");
	hcv_VIPArmor = UC_CreateConVar("as_vip_armor", "200", "Amount of armor the VIP spawns with");
	hcv_VIPHelmet = UC_CreateConVar("as_vip_helmet", "1", "Should a VIP be given a helmet?");
	hcv_VIPAvoidBots = UC_CreateConVar("as_vip_avoid_bots", "1", "Avoid setting bots as VIP if there are humans to do the job. If all humans set priority to 0, a bot will be selected to be VIP.");
	hcv_VIPBlockSwitchTeam = UC_CreateConVar("as_vip_block_switch_team", "1", "Block the VIP from changing teams, ruining the whole round in the process");

	hcv_CTItemsProhibited = UC_CreateConVar("as_ct_items_prohibited", "9,40,55", "CT cannot buy these weapons ( item defintion index ) from buy menu, but can steal them from dead players");
	hcv_TItemsProhibited = UC_CreateConVar("as_t_items_prohibited", "1,11,14,17,19,25,26,27,28,29,33,34,35,39,63,64", "T cannot buy these weapons ( item defintion index ) from buy menu, but can steal them from dead players");	
	
	hcv_AnnounceSettings = UC_CreateConVar("as_announce_settings", "1", "Announce the ability to set your VIP priority");
	hcv_AnnounceSettingsDelay = UC_CreateConVar("as_announce_settings_delay", "139", "How often in seconds to announce about the ability to set your VIP Priority");
	
	hcv_CashPlayerKillVIP = UC_CreateConVar("cash_player_kill_vip", "1500", "Amount of cash a terrorist earns from killing the VIP");
	hcv_CashTeamKillVIP = UC_CreateConVar("cash_team_kill_vip", "3000", "Amount of cash all terrorists earn from killing the VIP");
	hcv_CashTeamRescueVIP = UC_CreateConVar("cash_team_rescue_vip", "3000", "Amount of cash all CT earn from rescuing the VIP");
	
	hcv_ScorePlayerKillVIP = UC_CreateConVar("score_player_kill_vip", "3", "Amount of score a player gets for killing the VIP");
	hcv_ScorePlayerRescueVIP = UC_CreateConVar("score_player_rescue_vip", "3", "Amount of score a VIP gets for being rescued");
	
	hcv_RoundRestartDelay = FindConVar("mp_round_restart_delay");
	
	//FadeUserMsgId = GetUserMessageId("Fade");
	
	hCookie_VIPPrio = RegClientCookie("as_vip_priority", "Measures how much you wanna be VIP compared to others, up to 10", CookieAccess_Public);

	SetCookieMenuItem(VIPPriorityCookieMenu_Handler, 0, "VIP Priority");
	
	RegAdminCmd("sm_dump_weapondef", Command_DumpWeaponDef, ADMFLAG_CONVARS, "Dumps all weapon definition indexes into a file and your console");
	
	RegAdminCmd("sm_as_reload", Command_AsReload, ADMFLAG_RCON, "Schedules to reload the plugin in the end of next round without interrupting gameplay. Do not use with mp_round_restart_delay equal to 0 ");
	
	#if defined _autoexecconfig_included
	
	AutoExecConfig_ExecuteFile();

	AutoExecConfig_CleanFile();
	
	#endif
	
	ReloadPluginNR = 0;
	
}

public OnClientDisconnect(client)
{
	CheckVIPAbandon(client);
	Debt[client] = 0;
}

public Action:Event_PlayerTeam(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client == 0)
		return;
	
	Debt[client] = 0;
	
	if(GetEventBool(hEvent, "silent"))
		return;
		
	CheckVIPAbandon(client);
}

public hcvChange_RestartGame(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToInt(newValue) != 0)
	{
		for(new i=0;i <= MAXPLAYERS;i++)
			Debt[i] = 0;
	}
}
public CheckVIPAbandon(client)
{
	if(CurrentVIP != client)
		return;
	
	OnVIPKilled(CurrentVIP, GetRandomPlayer(CS_TEAM_T));
}
public APLRes:AskPluginLoad2(Handle:myself, bool:bLate, String:Error[], ErrorLength)
{
	isLateLoaded = bLate;
}

public Action:Command_AsReload(client, args)
{
	ReloadPluginNR = GetClientUserId(client);
	
	PrintToChat(client, "The VIP Gamemode plugin will reload at round end.");
	return Plugin_Handled;
}
public Action:Command_DumpWeaponDef(client, args)
{
	new String:DumpPath[256];
	BuildPath(Path_SM, DumpPath, sizeof(DumpPath), DUMP_WEAPON_DEF_PATH);
	
	CreateDirectory(DumpPath, FPERM_ULTIMATE);
	
	SetFilePermissions(DumpPath, FPERM_ULTIMATE); // Actually allow us to enter.
	
	Format(DumpPath, sizeof(DumpPath), "%s/WeaponDefIndex.txt", DumpPath);
	
	DeleteFile(DumpPath);
	
	new Handle:hFile = OpenFile(DumpPath, "a+");
	
	new bool:DumpToFile = true;
	if(hFile == INVALID_HANDLE)
		DumpToFile = false;

	new String:Message[256];
	FormatEx(Message, sizeof(Message), "Weapon Classname || Weapon Definition Index\n");
	
	if(DumpToFile)
		WriteFileLine(hFile, Message);
		
	PrintToConsole(client, Message);
	
	new Handle:SortArray = CreateArray(enWeaponData);
	
	new WeaponData[enWeaponData];
	for(new CSWeaponID:i=CSWeapon_NONE;i < CSWeapon_MAX_WEAPONS_NO_KNIFES;i++)
	{
		if(!CS_IsValidWeaponID(i))
			continue;
		
		WeaponData[enWepData_DefIndex] = CS_WeaponIDToItemDefIndex(i);
		CS_WeaponIDToAlias(i, WeaponData[enWepData_Classname], 64);
		
		PushArrayArray(SortArray, WeaponData, enWeaponData);
	}
	
	SortADTArrayCustom(SortArray, SortFunc_WeaponDefIndex);
	
	new ArraySize = GetArraySize(SortArray);
	for(new i=0;i < ArraySize;i++)
	{
		GetArrayArray(SortArray, i, WeaponData, enWeaponData);
		FormatEx(Message, sizeof(Message), "weapon_%s || %i", WeaponData[enWepData_Classname], WeaponData[enWepData_DefIndex]);
		
		PrintToConsole(client, Message);
		
		if(DumpToFile)
			WriteFileLine(hFile, Message);
	}
	CloseHandle(hFile);
	CloseHandle(SortArray);
	
	if(DumpToFile)
		ReplyToCommand(client, "Successfully dumped to your console and addons/data/AsGamemode/WeaponDefIndex.txt");
		
	else
	{
		ReplyToCommand(client, "ERROR: DUMPING DEFINITION INDEXES INTO THE FILE FAILED!");
		ReplyToCommand(client, "Successfully dumped to your console.");
	}
	
	return Plugin_Handled;
}

/* * @return			-1 if first should go before second
 *						0 if first is equal to second
 *						1 if first should go after second
 */
public SortFunc_WeaponDefIndex(index1, index2, Handle:array, Handle:hndl)
{
	new WeaponDataIndex1[enWeaponData];
	new WeaponDataIndex2[enWeaponData];
	GetArrayArray(array, index1, WeaponDataIndex1, enWeaponData);
	GetArrayArray(array, index2, WeaponDataIndex2, enWeaponData);
	
	if(WeaponDataIndex1[enWepData_DefIndex] > WeaponDataIndex2[enWepData_DefIndex])
		return 1;
		
	else if(WeaponDataIndex1[enWepData_DefIndex] < WeaponDataIndex2[enWepData_DefIndex])
		return -1;
		
	return 0;
}
public VIPPriorityCookieMenu_Handler(client, CookieMenuAction:action, info, String:buffer[], maxlen)
{
	ShowVIPPriorityMenu(client);
} 

public ShowVIPPriorityMenu(client)
{
	new Handle:hMenu = CreateMenu(VIPPriorityMenu_Handler);
	
	new String:TempFormat[64];
	Format(TempFormat, sizeof(TempFormat), "VIP Priority: %i", GetClientVIPPriority(client));
	AddMenuItem(hMenu, "", TempFormat);

	SetMenuExitBackButton(hMenu, true);
	SetMenuExitButton(hMenu, true);
	
	SetMenuTitle(hMenu, "Set your VIP Priority.\nHigher values means you wanna be VIP more often.\nSetting to zero will exempt you from VIP");
	DisplayMenu(hMenu, client, 30);
}


public VIPPriorityMenu_Handler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	else if(item == MenuCancel_ExitBack)
	{
		ShowCookieMenu(client);
	}
	else if(action == MenuAction_Select)
	{
		if(item == 0)
		{
			new priority = GetClientVIPPriority(client);
			if(priority < 0 || priority >= 10)
				SetClientVIPPriority(client, 0);
			
			else
				SetClientVIPPriority(client, priority + 1);
		}
		
		ShowVIPPriorityMenu(client);
	}
	return 0;
}


public OnMapStart()
{		
	for(new i=0;i <= MAXPLAYERS;i++)
		Debt[i] = 0;
		
	ReloadPluginNR = 0;
	new bool:MapStart = !isLateLoaded
	PrecacheModel(CTModel, MapStart);
	PrecacheModel(TModel, MapStart);
	PrecacheModel(VIPModel, MapStart);
	
	PrecacheModel(CTGloves, MapStart);
	PrecacheModel(TGloves, MapStart);
	PrecacheModel(VIPGloves, MapStart);
	
	CreateTimer(GetConVarFloat(hcv_AnnounceSettingsDelay), Timer_AnnounceSettings, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_AnnounceSettings(Handle:hTimer)
{
	if(GetConVarInt(hcv_AnnounceSettings))
		PrintToChatAll("You can set how often to be\x03 VIP\x01 in\x04 !settings\x01 under\x03 \"VIP Priority\"")

	
	CreateTimer(GetConVarFloat(hcv_AnnounceSettingsDelay), Timer_AnnounceSettings, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:CS_OnCSWeaponDrop(client, weapon)
{
	if(!GetConVarBool(hcv_Enabled))
		return Plugin_Continue;
		
	else if(client != CurrentVIP)
		return Plugin_Continue;
		
	new String:Classname[64];
	GetEdictClassname(weapon, Classname, sizeof(Classname));
	
	if(StrEqual(Classname, "weapon_knife") || StrEqual(Classname, "weapon_usp_silencer") || StrEqual(Classname, "weapon_hkp2000"))
		return Plugin_Handled;
		
	return Plugin_Continue;
}

public Action:Listener_JoinTeam(client, const String:command[], argc)
{
	if(!GetConVarBool(hcv_Enabled))
		return Plugin_Continue;
		
	else if(!GetConVarBool(hcv_VIPBlockSwitchTeam))
		return Plugin_Continue;
		
	else if(client != CurrentVIP)
		return Plugin_Continue;
		
	else if(RoundEnded)
		return Plugin_Continue;
	
	UC_PrintCenterText(CurrentVIP, "#Cannot_Switch_From_VIP");
	return Plugin_Handled;
}

public Action:CS_OnBuyCommand(client, const String:Classname[])
{
	if(!GetConVarBool(hcv_Enabled))
		return Plugin_Continue;
		
	new String:Alias[64];
	FormatEx(Alias, sizeof(Alias), Classname);
	ReplaceStringEx(Alias, sizeof(Alias), "weapon_", "");
	
	new CSWeaponID:WeaponID = CS_AliasToWeaponID(Alias);
	
	new defIndex = CS_WeaponIDToItemDefIndex(WeaponID);
	
	new String:ProhibitedItems[128];
	
	new Team = GetClientTeam(client);
	if(Team == CS_TEAM_CT)
		GetConVarString(hcv_CTItemsProhibited, ProhibitedItems, sizeof(ProhibitedItems));
	
	else if(Team == CS_TEAM_T)
		GetConVarString(hcv_TItemsProhibited, ProhibitedItems, sizeof(ProhibitedItems));
	
	else
		return Plugin_Continue;
		
	if(strlen(ProhibitedItems) == 0)
		return Plugin_Continue;
		
	new String:ItemsList[32][11];
	
	new count = ExplodeString(ProhibitedItems, ",", ItemsList, sizeof(ItemsList), sizeof(ItemsList[]));
	
	for(new i=0;i < count;i++)
	{
		if(StringToInt(ItemsList[i]) == defIndex)
		{
			ClientCommand(client, "play buttons/button10.wav");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
		
}

public Action:Event_PlayerUse(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new entity = GetEventInt(hEvent, "entity");
	
	if(HasEntProp(entity, Prop_Send, "m_flGrabSuccessTime"))
		CreateTimer(0.4, Timer_StopRescue, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_StopRescue(Handle:hTimer, Ref)
{
	new entity = EntRefToEntIndex(Ref);
	
	if(entity == INVALID_ENT_REFERENCE)
		return;
		
	SetEntPropFloat(entity, Prop_Send, "m_flGrabSuccessTime", MAX_FLOAT);
}

public Action:Event_BotTakeover(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hcv_Enabled))
		return;
		
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new bot = GetClientOfUserId(GetEventInt(hEvent, "botid"));
	
	if(bot == CurrentVIP && GetClientTeam(client) == CS_TEAM_CT && !RoundEnded)
	{
		SDKUnhook(bot, SDKHook_WeaponEquipPost, BlockVIPRoundEndAttack);
		SDKUnhook(bot, SDKHook_WeaponSwitchPost, BlockVIPRoundEndAttack);
		SDKUnhook(bot, SDKHook_WeaponSwitchPost, BlockVIPNormalWeapons);	
		
		CurrentVIP = client;
		
		SDKHook(CurrentVIP, SDKHook_WeaponSwitchPost, BlockVIPNormalWeapons);
	
		UC_PrintCenterText(CurrentVIP, "#Hint_you_are_the_vip");
	
		SetEntityModel(CurrentVIP, VIPModel);
		
		SetEntPropString(CurrentVIP, Prop_Send, "m_szArmsModel", VIPGloves);  
		
		SetEntityMaxHealth(CurrentVIP, GetConVarInt(hcv_VIPHealth));
	}	
}
public Action:Event_PlayerDeath(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hcv_Enabled))
		return;
		
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	
	if(client == CurrentVIP)
	{	
		if(!RoundEnded)
		{	
			if(attacker == 0 || GetClientTeam(attacker) != CS_TEAM_T)
				attacker = GetRandomPlayer(CS_TEAM_T);
			
			OnVIPKilled(CurrentVIP, attacker);
		}
		else
		{
			CurrentVIP = 0;
		}	
	}
}

public OnVIPKilled(VIP, attacker)
{
	new Handle:hEvent = CreateEvent("vip_killed", true);
	
	if(hEvent != INVALID_HANDLE)
	{
		SetEventInt(hEvent, "userid", GetClientUserId(CurrentVIP));
		
		
		if(attacker > 0)
			SetEventInt(hEvent, "attacker", GetClientUserId(attacker));
			
		else	
			SetEventInt(hEvent, "attacker", 0);
		
		FireEvent(hEvent);
	}
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		UC_PrintCenterText(i, "#SFUI_Notice_VIP_Assassinated");
	}
				
	new String:sParams[64];

	new Handle:bf;
	if(attacker > 0)
	{
		GivePlayerScore(attacker, GetConVarInt(hcv_ScorePlayerKillVIP));
		GiveClientMoney(attacker, GetConVarInt(hcv_CashPlayerKillVIP));
		RefreshClientMoney(attacker);
		
		if(!IsFakeClient(attacker))
		{
			SetGlobalTransTarget(attacker);
			
			FormatCashAward(GetConVarInt(hcv_CashPlayerKillVIP), sParams, sizeof(sParams));
			
			bf = StartMessageOne("TextMsg", attacker, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
			
			PbSetInt(bf, "msg_dst", HUD_PRINTTALK); 
			PbAddString(bf, "params", "#Player_Cash_Award_Killed_VIP"); 
			PbAddString(bf, "params", sParams); 
			PbAddString(bf, "params", ""); 
			PbAddString(bf, "params", ""); 
			PbAddString(bf, "params", ""); 
			
			EndMessage();
		}
	}
	
	new bool:AnyAlive = false;
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(GetClientTeam(i) != CS_TEAM_CT)
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
			
		AnyAlive = true;
			
	}
	
	if(AnyAlive)
	{
		ForceTeamWin(CS_TEAM_T);
		
		AwardTeamMoney(CS_TEAM_T);
	}
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hcv_Enabled))
		return;
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	SDKUnhook(client, SDKHook_WeaponEquipPost, BlockVIPRoundEndAttack);
	SDKUnhook(client, SDKHook_WeaponSwitchPost, BlockVIPRoundEndAttack);
	SDKUnhook(client, SDKHook_WeaponSwitchPost, BlockVIPNormalWeapons);	
	
	CreateTimer(0.2, SetModelAndResetWeapon, GetClientUserId(client));
	
	SetClientThirdPerson(client, false);
}

public Action:SetModelAndResetWeapon(Handle:hTimer, UserId)
{
	if(!GetConVarBool(hcv_Enabled))
		return;
		
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
		
	else if(!IsPlayerAlive(client))
		return;
	
	if(CurrentVIP == client)
	{
		SetEntityModel(client, VIPModel);
	
		SetEntPropString(client, Prop_Send, "m_szArmsModel", VIPGloves);  
	}
	else if(GetClientTeam(client) == CS_TEAM_CT)
	{
		SetEntityModel(client, CTModel);
		SetEntPropString(client, Prop_Send, "m_szArmsModel", CTGloves);  
	}
	else
	{
		SetEntityModel(client, TModel);
		SetEntPropString(client, Prop_Send, "m_szArmsModel", TGloves);  
	}
	
	if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == -1)
	{
		for(new i=0;i <= 5;i++)
		{
			new weapon = GetPlayerWeaponSlot(client, i);
			
			if(weapon != -1)
			{
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
				break;
			}
		}
	}
	
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
}

public Action:Event_RoundEnd(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	RoundEnded = true;
	RoundStarted = false;
	
	if(ReloadPluginNR != 0)
	{
		new bool:AnyDebts = false;
		
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
				
			else if(GetClientTeam(i) <= CS_TEAM_SPECTATOR) // Spectators and unassigned.
				continue;
				
			if(Debt[i] > 0)
			{
				AnyDebts = true;
				break;
			}
		}
		new client = GetClientOfUserId(ReloadPluginNR);
		
		if(client != 0)
		{
			if(AnyDebts)
			{
				PrintToChat(client, "Couldn't reload the plugin this round end due to valve bug related to taking over bots");
				PrintToChat(client, "Wait until next round and try to hope nobody takes over bots.");
				return;
			}
			PrintToChat(client, "VIP Gamemode Plugin successfully reloaded!");
		}
		
		new moneyEntity = EntRefToEntIndex(moneyRef);
		
		if(moneyEntity != INVALID_ENT_REFERENCE)
			AcceptEntityInput(moneyEntity, "Kill");
			
		ReloadPluginNR = 0;
		UC_ReloadPlugin(INVALID_HANDLE);
	}
}

public Action:Event_RoundStart(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	UnhookEntityOutput("func_hostage_rescue", "OnStartTouch", OnTouchVIP);
	HookEntityOutput("func_hostage_rescue", "OnStartTouch", OnTouchVIP);
	RoundEnded = false;
	RoundStarted = true;
	CurrentVIP = 0;
	
	if(!GetConVarBool(hcv_Enabled))
		return;
		
	new bool:SkipBots = false, bool:AllowZeroPriority = false;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		if(Debt[i] > 0)
		{				
			GiveClientMoney(i, Debt[i]);
			
			Debt[i] = 0;
		}
			
		else if(GetClientTeam(i) != CS_TEAM_CT)
			continue;
			
		if(GetClientVIPPriority(i) > 0)
			AllowZeroPriority = true;
	}	
	
	if(GetConVarBool(hcv_VIPAvoidBots))
	{
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
			
			else if(GetClientTeam(i) != CS_TEAM_CT)
				continue;
				
			new priority = GetClientVIPPriority(i);
			if(!IsFakeClient(i) && priority > 0 && AllowZeroPriority)
				SkipBots = true;
		}
	}
	new players[(MAXPLAYERS)*10+1], num; // multiplied by 10 for the 10 priority values.
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(GetClientTeam(i) != CS_TEAM_CT)
			continue;
		
		else if(SkipBots && IsFakeClient(i))
			continue;
		
		new priority = GetClientVIPPriority(i);
		
		if(!AllowZeroPriority)
			priority = 1;
		
		if(priority > 0)
		{
			for(new dummy_value=0;dummy_value < priority;dummy_value++)
			{
				players[num] = i;
				num++;
			}
		}
	}
	
	if(num == 0)
		return;
		
	CurrentVIP = players[GetRandomInt(0, num-1)];
	
	if(CurrentVIP == 0)
		return;
	
	SDKHook(CurrentVIP, SDKHook_WeaponSwitchPost, BlockVIPNormalWeapons);
	
	PrintToChatAll(" \x01The current\x03 VIP\x01 is\x04 %N\x01! CT must rescue him and T must kill him.", CurrentVIP);
	PrintToChatAll(" \x01CT must lead the\x03 VIP\x01 to the\x03 rescue zone\x01 to win the round, T will win if VIP dies.");
	
	UC_PrintCenterText(CurrentVIP, "#Hint_you_are_the_vip");
	
	SetVIPItems(CurrentVIP);
	
	CreateTimer(0.2, SetModelAndResetWeapon, GetClientUserId(CurrentVIP), TIMER_FLAG_NO_MAPCHANGE);
}

public BlockVIPNormalWeapons(VIP, weapon)
{
	if(!GetConVarBool(hcv_Enabled))
	{
		SDKUnhook(VIP, SDKHook_WeaponSwitchPost, BlockVIPNormalWeapons);
		return;
	}	
	else if(CurrentVIP != VIP)
	{
		SDKUnhook(VIP, SDKHook_WeaponSwitchPost, BlockVIPNormalWeapons);
		return;
	}
	else if(!RoundStarted)
		return;
	
	new String:Classname[64];
	GetEdictClassname(weapon, Classname, sizeof(Classname));
	
	// hkp2000 is P2000
	if(!StrEqual(Classname, "weapon_usp_silencer") && !StrEqual(Classname, "weapon_hkp2000") && !StrEqual(Classname, "weapon_knife") && !StrEqual(Classname, "weapon_healthshot"))
		CS_DropWeapon(VIP, weapon, true, true);
}
public OnTouchVIP(const String:output[], zone, Toucher, Float:delay)
{
	if(!GetConVarBool(hcv_Enabled))
	{
		UnhookEntityOutput("func_hostage_rescue", "OnStartTouch", OnTouchVIP);
		return;
	}
	else if(CurrentVIP == 0 || RoundEnded)
	{
		UnhookEntityOutput("func_hostage_rescue", "OnStartTouch", OnTouchVIP);
		return;
	}
	else if(!IsPlayer(Toucher) || CurrentVIP != Toucher)
		return;
		
	else if(!IsPlayerAlive(Toucher))
	{
		SDKUnhook(Toucher, SDKHook_WeaponSwitchPost, BlockVIPRoundEndAttack);
		SDKUnhook(Toucher, SDKHook_WeaponEquipPost, BlockVIPRoundEndAttack);
		UnhookEntityOutput("func_hostage_rescue", "OnStartTouch", OnTouchVIP);
		return;
	}
	
	new Handle:hEvent = CreateEvent("vip_escaped", true);
	
	if(hEvent != INVALID_HANDLE)
	{
		SetEventInt(hEvent, "userid", GetClientUserId(CurrentVIP));
		
		FireEvent(hEvent);
	}
	
	UnhookEntityOutput("func_hostage_rescue", "OnStartTouch", OnTouchVIP);
	
	SetClientArmor(CurrentVIP, 100);
	
	AwardTeamMoney(CS_TEAM_CT);
	
	SetEntityMoveType(CurrentVIP, MOVETYPE_NONE);
	
	TeleportToGround(CurrentVIP, -75.0);

	SetClientGodmode(CurrentVIP, true);
	
	// Stop velocity to block permanent footstep sound.
	
	SDKHook(CurrentVIP, SDKHook_WeaponSwitchPost, BlockVIPRoundEndAttack);
	SDKHook(CurrentVIP, SDKHook_WeaponEquipPost, BlockVIPRoundEndAttack);
	
	new ActiveWeapon = GetEntPropEnt(CurrentVIP, Prop_Send, "m_hActiveWeapon");
	new Float:NextAttack = GetGameTime() + GetConVarFloat(hcv_RoundRestartDelay);
	
	if(ActiveWeapon != -1)
	{
		SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", NextAttack);
		SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", NextAttack);
	}
	
	GivePlayerScore(CurrentVIP, GetConVarInt(hcv_ScorePlayerRescueVIP));
	
	ForceTeamWin(CS_TEAM_CT);
	
	SDKHook(CurrentVIP, SDKHook_SetTransmit, MakeVIPInvisible);	
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(IsFakeClient(i))
			continue;
			
		UC_PrintCenterText(i, "#SFUI_Notice_VIP_Escaped");
	}
}

public Action:MakeVIPInvisible(VIP, viewer)
{
	if(CurrentVIP != VIP)
	{
		SDKUnhook(VIP, SDKHook_SetTransmit, MakeVIPInvisible);
		return Plugin_Continue;
	}	
	else if(!RoundEnded)
	{
		SDKUnhook(VIP, SDKHook_SetTransmit, MakeVIPInvisible);
		return Plugin_Continue;
	}
	else if(!IsPlayerAlive(VIP))
	{
		SDKUnhook(VIP, SDKHook_WeaponSwitchPost, BlockVIPRoundEndAttack);
		SDKUnhook(VIP, SDKHook_WeaponEquipPost, BlockVIPRoundEndAttack);
		SDKUnhook(VIP, SDKHook_SetTransmit, MakeVIPInvisible);
		return Plugin_Continue;
	}	
	return Plugin_Handled;
}
public Action:BlockVIPRoundEndAttack(VIP, weapon)
{
	if(!GetConVarBool(hcv_Enabled) || CurrentVIP == 0 || CurrentVIP != VIP)
	{
		SDKUnhook(VIP, SDKHook_WeaponSwitchPost, BlockVIPRoundEndAttack);
		SDKUnhook(VIP, SDKHook_WeaponEquipPost, BlockVIPRoundEndAttack);
		return Plugin_Continue;
	}
	else if(!RoundEnded)
	{
		SDKUnhook(VIP, SDKHook_WeaponSwitchPost, BlockVIPRoundEndAttack);
		SDKUnhook(VIP, SDKHook_WeaponEquipPost, BlockVIPRoundEndAttack);
		return Plugin_Continue;
	}
	else if(!IsPlayerAlive(VIP))
	{
		SDKUnhook(VIP, SDKHook_WeaponSwitchPost, BlockVIPRoundEndAttack);
		SDKUnhook(VIP, SDKHook_WeaponEquipPost, BlockVIPRoundEndAttack);
		return Plugin_Continue;
	}
	
	new ActiveWeapon = GetEntPropEnt(CurrentVIP, Prop_Send, "m_hActiveWeapon");
	new Float:NextAttack = GetGameTime() + GetConVarFloat(hcv_RoundRestartDelay);
	
	if(ActiveWeapon != -1)
	{
		SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", NextAttack);
		SetEntPropFloat(ActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", NextAttack);
	}
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", NextAttack);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", NextAttack);
	
	return Plugin_Continue;
}
stock SetVIPItems(client)
{
	if(!GetConVarBool(hcv_Enabled))
		return;	
		
	ThrowPlayerWeapons(client);
	GivePlayerItem(client, "weapon_knife");
	new weapon = GivePlayerItem(client, "weapon_usp_silencer");
	
	GivePlayerItem(client, "weapon_healthshot");
	
	SetClientAmmo(client, weapon, GetConVarInt(hcv_VIPAmmo));
	
	SetEntityHealth(client, GetConVarInt(hcv_VIPHealth));
	SetEntityMaxHealth(client, GetConVarInt(hcv_VIPHealth));
	
	SetClientArmor(client, GetConVarInt(hcv_VIPArmor));
	SetClientHelmet(client, GetConVarBool(hcv_VIPHelmet));
}

stock SetClientArmor(client, amount)
{		
	SetEntProp(client, Prop_Send, "m_ArmorValue", amount);
}

stock SetClientHelmet(client, bool:helmet)
{
	SetEntProp(client, Prop_Send, "m_bHasHelmet", helmet);
}

stock SetEntityMaxHealth(entity, maxhealth)
{
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", maxhealth);
}

stock ThrowPlayerWeapons(client)
{
	new String:Classname[64];

	for(new i=0;i <= 5;i++)
	{
		new weapon = GetPlayerWeaponSlot(client, i);
		
		if(weapon != -1)
		{	
			GetEdictClassname(weapon, Classname, sizeof(Classname));
			
			if(StrEqual(Classname, "weapon_knife") || StrEqual(Classname, "weapon_usp_silencer") || StrEqual(Classname, "weapon_hkp2000"))
				RemovePlayerItem(client, weapon);
				
			else
				CS_DropWeapon(client, weapon, false, true);
				
			i--; // This is to strip all nades, and zeus & knife
		}
	}
}


stock UC_StripPlayerWeapons(client)
{
	for(new i=0;i <= 5;i++)
	{
		new weapon = GetPlayerWeaponSlot(client, i);
		
		if(weapon != -1)
		{
			RemovePlayerItem(client, weapon);
			i--; // This is to strip all nades, and zeus & knife
		}
	}
}


stock SetClientAmmo(client, weapon, ammo)
{
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo); //set reserve to 0
}

stock SetClientGodmode(client, bool:godmode)
{
	if(godmode)
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		
	else
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
}

stock CreateBlackscreen(client, Float:Duration)
{
	if(IsFakeClient(client))
		return;
		
	new iDuration = RoundToCeil(Duration)*1000; // duration and hold_time are milliseconds.
	
	new clients[1];
	clients[0] = client;
	new Handle:message = StartMessage("Fade", clients, 1);
	
	PbSetInt(message, "duration", 0);
	PbSetInt(message, "hold_time", iDuration);
	PbSetInt(message, "flags", (0x0002 | 0x0010)); // Fade out ( whatever that means ) | purge all other fades, making this the only fade that matters.
	PbSetColor(message, "clr", {0, 0, 0, 255});
	
	EndMessage();
}


// https://forums.alliedmods.net/showpost.php?p=2325048&postcount=8
// Print a Valve translation phrase to a group of players 
// Adapted from util.h's UTIL_PrintToClientFilter 
stock UC_PrintCenterText(client, const String:msg_name[], const String:param1[]="", const String:param2[]="", const String:param3[]="", const String:param4[]="")
{ 
	new UserMessageType:MessageType = GetUserMessageType();
		
	SetGlobalTransTarget(client);
		
	new Handle:bf = StartMessageOne("TextMsg", client, USERMSG_RELIABLE); 
		 
	if (MessageType == UM_Protobuf) 
	{ 
		PbSetInt(bf, "msg_dst", HUD_PRINTCENTER); 
		PbAddString(bf, "params", msg_name); 
			
		PbAddString(bf, "params", param1); 
		PbAddString(bf, "params", param2); 
		PbAddString(bf, "params", param3); 
		PbAddString(bf, "params", param4); 
	} 
	else 
	{ 
		BfWriteByte(bf, HUD_PRINTCENTER); 
		BfWriteString(bf, msg_name); 
		
		BfWriteString(bf, param1); 
		BfWriteString(bf, param2); 
		BfWriteString(bf, param3); 
		BfWriteString(bf, param4); 
	}
	 
	EndMessage(); 
}  


stock GetClientVIPPriority(client)
{
	new String:strVIPPriority[50];
	GetClientCookie(client, hCookie_VIPPrio, strVIPPriority, sizeof(strVIPPriority));
	
	if(strVIPPriority[0] == EOS)
		return 1;
		
	new value = StringToInt(strVIPPriority);
	
	if(value < 0 || value > 10)
	{
		SetClientVIPPriority(client, 0);
		return 0;
	}
	return value;
}

stock SetClientVIPPriority(client, value)
{
	new String:strVIPPriority[50];
	
	IntToString(value, strVIPPriority, sizeof(strVIPPriority));
	SetClientCookie(client, hCookie_VIPPrio, strVIPPriority);
	
	return value;
}

/**
 * Gives client an amount of money
 *
 * @param client		Client Index.
 * @param money			Amount of money to give to the Client.
 
 * @noreturn.
 */
stock bool:GiveClientMoney(client, money)
{
	// Because Valve, please fix
	if((GetEntProp(client, Prop_Send, "m_bIsControllingBot") && GetEntProp(client, Prop_Send, "m_iControlledBotEntIndex") != -1 && !IsFakeClient(client)) || (IsFakeClient(client) && GetFakeClientController(client) != 0))
	{
		Debt[client] += money;
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_iAccount", GetClientMoney(client) + money);
	}
}

/**
 * Forces a money refresh on a certain number of clients. Please limit to once per function / frame / 0.1 seconds or whatever.
 *
 * @param clients		Array holding the client indexes.
 * @param numClients	Number of clients inside the array
 
 * @return				true if money was successfully refreshed, false if failed to refresh. If this is used in CS:S or any other game, will always return false.
 
 */
stock bool:RefreshMoney(clients[], numClients)
{	
	new moneyEntity = EntRefToEntIndex(moneyRef);
	
	if(moneyEntity == -1)
	{
		moneyEntity = CreateEntityByName("game_money");
		
		if(moneyEntity == -1)
			return false;
			
		DispatchKeyValue(moneyEntity, "Award Text", "");
		
		DispatchSpawn(moneyEntity);
		
		moneyRef = EntIndexToEntRef(moneyEntity);
	}
	
	AcceptEntityInput(moneyEntity, "SetMoneyAmount 0");

	
	for(new i=0;i < numClients;i++)
		AcceptEntityInput(moneyEntity, "AddMoneyPlayer", clients[i]);
	
	return true;
}

/**
 * Forces a money refresh on a certain number on a client. Never use this twice or more in a row, instead go to the function RefreshMoney to refresh as many players as you like at once.
 *
 * @param client		Client index to refresh money.
 
 * @return				true if money was successfully refreshed, false if failed to refresh. If this is used in CS:S or any other game, will always return false.
 
 */
stock bool:RefreshClientMoney(client)
{	
	new clients[1];
	clients[0] = client;
	
	return RefreshMoney(clients, 1);
}

/**
 * Forces a money refresh on all clients.
 
 * @return				true if money was successfully refreshed, false if failed to refresh. If this is used in CS:S or any other game, will always return false.
 
 */
 
stock bool:RefreshAllClientsMoney()
{	
	new clients[MAXPLAYERS+1], num;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		clients[num] = i;
		num++
	}
	
	return RefreshMoney(clients, num);
}

stock GetClientMoney(client)
{
	return GetEntProp(client, Prop_Send, "m_iAccount");
}

// Puts the value of the first parameter of cash award in a string, in the way Counter-Strike Global-Offensive does it by default.
stock FormatCashAward(value, String:buffer[], length)
{	
	if(value > 0)
		Format(buffer, length, "+$%i", value);
		
	else if(value < 0)
		Format(buffer, length, "-$%i", value);
		
	else
		Format(buffer, length, "0");
}

stock GetRandomPlayer(Team, bool:aliveFirst = true)
{
	new clients[MAXPLAYERS+1], num;
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(GetClientTeam(i) != Team)
			continue;
			
		else if(!IsPlayerAlive(i) && aliveFirst)
			continue;
			
		clients[num] = i;
		num++;
	}
	
	if(num > 0)
		return clients[GetRandomInt(0, num-1)];

	num = 0;
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(GetClientTeam(i) != Team)
			continue;
			
		clients[num] = i;
		num++;
	}
	
	if(num > 0)
		return clients[GetRandomInt(0, num-1)];
		
	return 0;
}

#if defined _autoexecconfig_included

stock ConVar:UC_CreateConVar(const String:name[], const String:defaultValue[], const String:description[]="", flags=0, bool:hasMin=false, Float:min=0.0, bool:hasMax=false, Float:max=0.0)
{
	return AutoExecConfig_CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
}

#else

stock ConVar:UC_CreateConVar(const String:name[], const String:defaultValue[], const String:description[]="", flags=0, bool:hasMin=false, Float:min=0.0, bool:hasMax=false, Float:max=0.0)
{
	return CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
}
 
#endif

stock ForceTeamWin(Team, bool:WaitFrame=true)
{
	RoundEnded = true;
	
	if(WaitFrame)
		RequestFrame(Frame_ForceTeamWin, Team);
		
	else
		Frame_ForceTeamWin(Team);
}

public Frame_ForceTeamWin(Team)
{
		
	new RoundEndEntity = CreateEntityByName("game_round_end");
	
	DispatchSpawn(RoundEndEntity);
	
	if(Team == CS_TEAM_CT)
	{	
		SetVariantFloat(GetConVarFloat(hcv_RoundRestartDelay));
		AcceptEntityInput(RoundEndEntity, "EndRound_CounterTerroristsWin");

	}
	else if(Team == CS_TEAM_T)
	{	
		SetVariantFloat(GetConVarFloat(hcv_RoundRestartDelay));
		AcceptEntityInput(RoundEndEntity, "EndRound_TerroristsWin");
	}
	
	AcceptEntityInput(RoundEndEntity, "Kill");
}

stock bool:AwardTeamMoney(Team)
{
	if(Team == CS_TEAM_T)
	{
		new clients[MAXPLAYERS+1], num;
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
				
			else if(GetClientTeam(i) != CS_TEAM_T)
				continue;
			
			GiveClientMoney(i, GetConVarInt(hcv_CashTeamKillVIP));
			
			if(IsFakeClient(i))
				continue;
				
			clients[num] = i;
			num++;
		}
		
		RefreshAllClientsMoney();
		
		new String:sParams[64];
		FormatCashAward(GetConVarInt(hcv_CashTeamKillVIP), sParams, sizeof(sParams));
		
		if(num > 0)
		{
			new Handle:bf = StartMessage("TextMsg", clients, num, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
			
			PbSetInt(bf, "msg_dst", HUD_PRINTTALK); 
			
			PbAddString(bf, "params", "#Team_Cash_Award_T_VIP_Killed"); 
			PbAddString(bf, "params", sParams); 
			PbAddString(bf, "params", ""); 
			PbAddString(bf, "params", "");
			PbAddString(bf, "params", ""); 
			
			EndMessage();
		}
	}
	else if(Team == CS_TEAM_CT)
	{
		new clients[MAXPLAYERS+1], num;
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
				
			else if(GetClientTeam(i) != CS_TEAM_CT)
				continue;
				
			GiveClientMoney(i, GetConVarInt(hcv_CashTeamRescueVIP));
			
			if(IsFakeClient(i))
				continue;
				
			clients[num] = i;
			num++;
		}
		
		RefreshAllClientsMoney();

		
		new String:sParams[64];
		FormatCashAward(GetConVarInt(hcv_CashTeamRescueVIP), sParams, sizeof(sParams));

		if(num > 0)
		{
			new Handle:bf = StartMessage("TextMsg", clients, num, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
			
			PbSetInt(bf, "msg_dst", HUD_PRINTTALK); 
			
			PbAddString(bf, "params", "#Team_Cash_Award_CT_VIP_Escaped"); 
			PbAddString(bf, "params", sParams); 
			PbAddString(bf, "params", ""); 
			PbAddString(bf, "params", ""); 
			PbAddString(bf, "params", ""); 
			
			EndMessage();
		}	
	}
}

stock GivePlayerScore(client, amount)
{	
	/*
	CS_SetClientContributionScore(client, CS_GetClientContributionScore(client) + amount);
	
	new Handle:hEvent = CreateEvent("player_stats_updated");
	
	SetEventBool(hEvent, "forceupload", false);
	FireEvent(hEvent);
	*/
}

stock bool:UC_IsNullVector(const Float:Vector[3])
{
	return (Vector[0] == NULL_VECTOR[0] && Vector[0] == NULL_VECTOR[1] && Vector[2] == NULL_VECTOR[2]);
}

stock TeleportToGround(client, Float:HeightOffset = 0.0) // Height offset is for the result.
{
	new Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3], Float:vecFakeOrigin[3];
    
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
    
	GetClientAbsOrigin(client, vecOrigin);
	vecFakeOrigin = vecOrigin;
	
	TR_TraceRayFilter(vecFakeOrigin, Float:{90.0, 0.0, 0.0}, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitPlayers);
    
	if(!TR_DidHit())
		return false;
		
	TR_TraceHullFilter(vecOrigin, vecFakeOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceRayDontHitPlayers);
	
	TR_GetEndPosition(vecOrigin);

		
	if(TR_PointOutsideWorld(vecOrigin))
		return false;

	vecOrigin[2] += HeightOffset;
	
	TeleportEntity(client, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityFlags(client, GetEntityFlags(client) & ~FL_ONGROUND);
	
	return true;
}


stock bool:IsPlayerStuck(client, const Float:Origin[3] = NULL_VECTOR, Float:HeightOffset = 0.0)
{
	new Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];
	
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
    
	if(UC_IsNullVector(Origin))
		GetClientAbsOrigin(client, vecOrigin);
		
	else
	{
		vecOrigin = Origin;
		vecOrigin[2] += HeightOffset;
    }
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceRayDontHitPlayers);
	return TR_DidHit();
}

public bool:TraceRayDontHitPlayers(entityhit, mask) 
{
    return (entityhit>MaxClients || entityhit == 0);
}

stock bool:IsPlayer(index)
{
	if(index >= 1 && index <= MaxClients)
		return true;
		
	return false;
}

stock bool:SetClientThirdPerson(client, bool:thirdperson)
{
	new Handle:convar = FindConVar("sv_allow_thirdperson");
	
	SetConVarBool(convar, true);
	
	if(thirdperson)
		ClientCommand(client, "thirdperson");
	
	else
		ClientCommand(client, "firstperson");
		
	SetConVarBool(convar, false);
}

stock UC_ReloadPlugin(Handle:plugin)
{
	new String:PlFilename[128];
	GetPluginFilename(plugin, PlFilename, sizeof(PlFilename));
	
	ServerCommand("sm plugins reload %s", PlFilename);
}

stock GetFakeClientController(client)
{
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
			
		else if(!GetEntProp(i, Prop_Send, "m_bIsControllingBot"))
			continue;
		
		if(GetEntProp(i, Prop_Send, "m_iControlledBotEntIndex") == client)
			return i;
	}
	
	return 0;
}