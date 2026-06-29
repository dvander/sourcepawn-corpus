#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

#define CHEER	"/ambient_mp3/bumper_car_cheer3.mp3"
#define CACHING "/mvm/mvm_bought_upgrade.wav"

ConVar g_iAmountJoinServer;
ConVar g_iAmountRoundStart;
ConVar g_iAmountPerKill;
ConVar g_iAmountPerAssist;
ConVar g_iAmountPerCapture;
ConVar g_iAmountPerRoundWin;
ConVar g_iAmountPerRoundLoss;
int playercash[MAXPLAYERS+1];


public Plugin myinfo = 
{
	name = "[TF2] MvM Rewards",
	author = "PC Gamer, with help from Bacardi",
	description = "Give credits to kill assisters and point capturers",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_showcash", Command_ShowCash, ADMFLAG_SLAY, "Shows cash amounts of selected target/targets.");
	RegAdminCmd("sm_setcash", Command_SetCash, ADMFLAG_SLAY, "Sets cash of selected target/targets.");
	RegAdminCmd("sm_addcash", Command_AddCash, ADMFLAG_SLAY, "Adds cash of selected target/targets.");
	RegAdminCmd("sm_removecash", Command_RemoveCash, ADMFLAG_SLAY, "Removes cash of selected target/targets.");
	RegAdminCmd("sm_wipeall", Command_wipeall, ADMFLAG_SLAY, "Remove all Upgrades from Target.");
	RegConsoleCmd("sm_refund", Command_Refund);
	
	HookEvent("teamplay_point_captured", teamplay_point_captured);
	HookEvent("teamplay_flag_event", teamplay_flag_event);	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundWin);
	AddCommandListener(Listener_JoinTeam, "jointeam");

	g_iAmountJoinServer = CreateConVar("sm_mvm_cash_joinserver_amount", "200", "Amount to give players joining the map", FCVAR_NOTIFY, true, 0.0);
	g_iAmountRoundStart = CreateConVar("sm_mvm_cash_roundstart_amount", "200", "Amount to give players at round start", FCVAR_NOTIFY, true, 0.0);
	g_iAmountPerKill = CreateConVar("sm_mvm_cash_kill_amount", "60", "Amount to give players for each kill", FCVAR_NOTIFY, true, 0.0);
	g_iAmountPerAssist = CreateConVar("sm_mvm_cash_assist_amount", "50", "Amount to give players for each assist", FCVAR_NOTIFY, true, 0.0);
	g_iAmountPerCapture = CreateConVar("sm_mvm_cash_capture_amount", "100", "Amount to give players who actually captured the objective", FCVAR_NOTIFY, true, 0.0);
	g_iAmountPerRoundWin = CreateConVar("sm_mvm_cash_roundwin_amount", "300", "Amount to give team players for winning the round", FCVAR_NOTIFY, true, 0.0);
	g_iAmountPerRoundLoss = CreateConVar("sm_mvm_cash_roundloss_amount", "200", "Amount to give team players losing the round", FCVAR_NOTIFY, true, 0.0);
}

public void OnMapStart()
{
	PrecacheSound(CHEER);
	PrecacheSound(CACHING);	
}

public void OnClientPostAdminCheck(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		AddCash(client, GetConVarInt(g_iAmountJoinServer));
		PrintToServer("MvMRewards: Gave %N %i credits for Joining Server", client, GetConVarInt(g_iAmountJoinServer));
		PrintToChat(client, "MvMRewards: Gave %N %i credits for Joining Server", client, GetConVarInt(g_iAmountJoinServer));		
	}
}

public void OnRoundStart(Event event, const char[] strName, bool bDontBroadcast)
{
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i))
		{
			AddCash(i, GetConVarInt(g_iAmountRoundStart));
		}
	}
	EmitSoundToAll(CACHING);
	PrintToServer("MvMRewards: Gave %i credits to everyone for Round Start", GetConVarInt(g_iAmountRoundStart));
	PrintToChatAll("MvMRewards: Gave %i credits to everyone for Round Start", GetConVarInt(g_iAmountRoundStart));
}

public void OnRoundWin(Event event, const char[] name, bool dontBroadcast)
{
	int WinningTeam = GetEventInt(event, "team");
	
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i))
		{	
			if (GetClientTeam(i) == WinningTeam)
			{
				AddCash(i, GetConVarInt(g_iAmountPerRoundWin));
				EmitSoundToClient(i, CHEER);
				PrintToChat(i, "MvMRewards: Gave %N %i credits for winning the round", i, GetConVarInt(g_iAmountPerRoundWin));
			}
			else
			{
				AddCash(i, GetConVarInt(g_iAmountPerRoundLoss));
				PrintToChat(i, "MvMRewards: Gave %N %i credits for losing the round", i, GetConVarInt(g_iAmountPerRoundLoss));
			}
		}
	}
	PrintToServer("MvMRewards: Gave %i credits to winning team %i", GetConVarInt(g_iAmountPerRoundWin), WinningTeam);
	PrintToServer("MvMRewards: Gave %i credits to losing team", GetConVarInt(g_iAmountPerRoundLoss));
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attack = GetClientOfUserId(GetEventInt(event, "attacker"));
	int assist = GetClientOfUserId(GetEventInt(event, "assister"));
	
	if (IsValidClient(client) && !IsFakeClient(attack) && attack != client)
	{
		int iCash_Killer = GetEntProp(attack, Prop_Send, "m_nCurrency");
		int NewCash = iCash_Killer + GetConVarInt(g_iAmountPerKill);
		SetEntProp(attack, Prop_Send, "m_nCurrency", NewCash);
	}
	if (IsValidClient(assist) && IsValidClient(client) && !IsFakeClient(assist) && assist != client && IsValidClient(assist) && IsValidClient(attack))
	{
		int iCash_Assister = GetEntProp(assist, Prop_Send, "m_nCurrency");
		int NewCash = iCash_Assister + GetConVarInt(g_iAmountPerAssist);		
		SetEntProp(assist, Prop_Send, "m_nCurrency", NewCash);
	}
	
	return Plugin_Continue;
}

public void teamplay_point_captured(Event event, char[] name, bool dontBroadcast)
{
	char cappers[32];        // example, event output "cappers" string: \x01\x02\x03
	int client_index;

	char message[200];

	event.GetString("cappers", cappers, sizeof(cappers));

	int cappers_count = strlen(cappers);
	int[] cappers_array = new int[cappers_count]; // store client indexs
	
	for(int x = 0; x < cappers_count; x++)
	{
		client_index = view_as<int>(cappers[x]);

		Format(message, sizeof(message), "%s, %N", message, client_index);
		cappers_array[x] = client_index;
	}

	PrintToServer("%s captured control point", message[2]);
	
	for(int y = 0; y < cappers_count; y++)
	{
		if(IsValidClient(cappers_array[y]) && !IsFakeClient(cappers_array[y]))
		{
			PrintToServer("%N is a Human who capped a control point", cappers_array[y]);

			SetCash(cappers_array[y], GetCash(cappers_array[y]) + GetConVarInt(g_iAmountPerCapture));
			TF2_AddCondition(cappers_array[y], TFCond_TeleportedGlow, 5.0);
			PrintToChat(cappers_array[y], "Enjoy a Bonus for capping the control point");
			PrintToServer("Gave Capture Bonuses of %i to %N", GetConVarInt(g_iAmountPerCapture), cappers_array[y]);
			EmitSoundToClient(cappers_array[y], CHEER);	
		}		
	}
}

public void teamplay_flag_event(Event event, char[] name, bool dontBroadcast)
{
	if (GetEventInt(event, "eventtype") == 2)
	{
		int carrier = GetEventInt(event, "player");
		if(carrier > 0 && IsValidClient(carrier) && !IsFakeClient(carrier))
		{
			PrintToServer("%N is a Human who captured the Flag", carrier);

			SetCash(carrier, GetCash(carrier) + GetConVarInt(g_iAmountPerCapture));
			TF2_AddCondition(carrier, TFCond_TeleportedGlow, 5.0);
			PrintToChat(carrier, "Enjoy a Bonus for capturing the flag");
			PrintToServer("Gave Flag Capture Bonus of %i to %N", GetConVarInt(g_iAmountPerCapture), carrier);
			EmitSoundToClient(carrier, CHEER);	
		}
	}
}

public Action Listener_JoinTeam(int client, const char[] command, int args)
{
	if(!IsValidClient(client) && !IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	playercash[client] = GetCash(client);
	PrintToServer("MvMRewards: Player %N is changing teams. Saving %i credits", client, playercash[client]);

	CreateTimer(5.0, FixCash, client);
	
	return Plugin_Continue;
}

Action FixCash(Handle timer, any client)
{
	if(!IsValidClient(client) && !IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	SetCash(client, playercash[client]);
	PrintToServer("MvMRewards: Player %N is changed teams. Giving %i credits", client, playercash[client]);

	return Plugin_Handled;
}

public Action Command_SetCash(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setcash \"target\" \"amount\"");
		return Plugin_Handled;
	}
	
	char strCash[32];
	int iCash;
	GetCmdArg(2, strCash, sizeof(strCash));
	iCash = StringToInt(strCash);

	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{ 
		SetCash(target_list[i], iCash);
	}
	return Plugin_Handled;
}

public Action Command_AddCash(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addcash \"target\" \"amount\"");
		return Plugin_Handled;
	}
	
	char strCash[32];
	int iCash;
	GetCmdArg(2, strCash, sizeof(strCash));
	iCash = StringToInt(strCash);

	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_CONNECTED|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{ 
		SetCash(target_list[i], GetCash(target_list[i])+iCash);
	}
	return Plugin_Handled;
}

public Action Command_RemoveCash(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removecash \"target\" \"amount\"");
		return Plugin_Handled;
	}

	char strCash[32];
	int iCash;
	GetCmdArg(2, strCash, sizeof(strCash));
	iCash = StringToInt(strCash);

	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_CONNECTED|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{ 
		SetCash(target_list[i], GetCash(target_list[i])-iCash);
	}
	return Plugin_Handled;
}

public Action Command_ShowCash(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{ 
		PrintToChatAll("%N has %d",target_list[i], GetCash(target_list[i]));
		PrintToServer("%N has %d",target_list[i], GetCash(target_list[i]));		
	}
	return Plugin_Handled;
}

void SetCash(int client, int iAmount)
{
	if(iAmount < 0) iAmount = 0;
	SetEntProp(client, Prop_Send, "m_nCurrency", iAmount);
}

void AddCash(int client, int iAmount)
{
	if(iAmount < 0) iAmount = 0;
	SetCash(client, GetCash(client)+iAmount);
}

int GetCash(int client)
{
	return GetEntProp(client, Prop_Send, "m_nCurrency");
}

Action Command_Refund(int client, int args)
{
	KeyValues respec = new KeyValues("MVM_Respec");
	
	int inUpgradeZone = GetEntProp(client, Prop_Send, "m_bInUpgradeZone");

	if (!inUpgradeZone)
	{
		SetEntProp(client, Prop_Send, "m_bInUpgradeZone", 1);
	}

	FakeClientCommandKeyValues(client, respec);

	if (!inUpgradeZone)
	{
		SetEntProp(client, Prop_Send, "m_bInUpgradeZone", 0);
	}

	delete respec;

	PrintToChat(client, "Your upgrades removed and your money was refunded");

	return Plugin_Handled;
}

public Action Command_wipeall(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		KeyValues respec = new KeyValues("MVM_Respec");
		
		int inUpgradeZone = GetEntProp(target_list[i], Prop_Send, "m_bInUpgradeZone");

		if (!inUpgradeZone)
		{
			SetEntProp(target_list[i], Prop_Send, "m_bInUpgradeZone", 1);

			FakeClientCommandKeyValues(target_list[i], respec);
		}
		
		if (!inUpgradeZone)
		{
			SetEntProp(target_list[i], Prop_Send, "m_bInUpgradeZone", 0);
		}
		delete respec;

		TF2Attrib_RemoveAll(target_list[i]);
		int Weapon = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon))
		{
			TF2Attrib_RemoveAll(Weapon);
		}
		int Weapon2 = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
		}
		int Weapon3 = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);
		}
		int Weapon4 = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_PDA);
		if(IsValidEntity(Weapon4))
		{
			TF2Attrib_RemoveAll(Weapon4);
		}
		WipeCanteen(target_list[i]);

		SetEntProp(target_list[i], Prop_Send, "m_iHealth", 125, 1);			
		TF2_RegeneratePlayer(target_list[i]);		
		LogAction(client, target_list[i], "\"%L\" removed all upgrades on \"%L\"", client, target_list[i]);
	}
	ReplyToCommand(client, "Removed all upgrades on target(s)");
	
	return Plugin_Handled;
}

stock void WipeCanteen(int client)
{
	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2Attrib_RemoveAll(wearable);
			}
		}
	}
}

bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients || !IsClientConnected(client))
	{
		return false;
	}
	return (IsClientInGame(client));
}