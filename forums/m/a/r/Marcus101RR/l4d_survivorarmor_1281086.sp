#pragma semicolon 1 

#include <sourcemod> 
#include <sdktools> 
#include <sdktools_functions>

#define PLUGIN_VERSION "1.5.0"

#define HEALTH_UPGRADE_COST 		200
#define ARMOR_UPGRADE_COST		100
#define HEALTH_COST			500
#define ARMOR_COST			250

new Handle:L4DFirstAidKit 		= INVALID_HANDLE;
new Handle:L4DPainPills 		= INVALID_HANDLE;
new Handle:iMHealthMultiplier 		= INVALID_HANDLE;
new Handle:iMArmorMultiplier 		= INVALID_HANDLE;
new Handle:iMArmorFactor 		= INVALID_HANDLE;
new Handle:iCashProbability		= INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "[L4D(2)] Health & Armor System",
    author = "Marcus101RR",
    description = "Survivor Team can increase Health and Armor.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=136299"
}

new iMHealth[MAXPLAYERS + 1];
new iMArmor[MAXPLAYERS + 1];
new m_iArmor[MAXPLAYERS + 1];
new iCash[MAXPLAYERS + 1];
new bool:b_ShowArmor[MAXPLAYERS + 1];

new String:SavePath[256];

public OnPluginStart()
{
	/* Build Save Path */
	BuildPath(Path_SM, SavePath, 255, "data/HealthArmorData.txt");

	CreateConVar("sm_healtharmorsystem_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	iMHealthMultiplier = CreateConVar("survivor_max_health_multiplier", "10", "Maximum Multiplier of Health by 5.", FCVAR_PLUGIN, true, 1.00, true, 32.00);
	iMArmorMultiplier = CreateConVar("survivor_max_armor_multiplier", "10", "Maximum Multiplier of Armor by 5.", FCVAR_PLUGIN, true, 1.00, true, 32.00);
	iMArmorFactor = CreateConVar("survivor_max_armor_factor", "2", "Maximum Factor of Armor.", FCVAR_PLUGIN, true, 1.00, true, 4.00);
	iCashProbability = CreateConVar("survivor_cash_probability", "0.25", "The probability of an cash from infected.", FCVAR_PLUGIN, true, 0.00, true, 1.00);

	L4DFirstAidKit = FindConVar("first_aid_kit_max_heal");
	L4DPainPills = FindConVar("pain_pills_health_threshold");

	RegConsoleCmd("sm_buy", ActivateBuyMenu, "Check various stats on survivor.");

	RegAdminCmd("sm_givecash", CommandGiveCash, ADMFLAG_CHEATS, "Give player specified cash with an amount.");

	HookConVarChange(iMHealthMultiplier, ConVarChange);

	HookEvent("player_first_spawn", event_PlayerSpawn);
	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("player_transitioned", event_SetStatus);
	HookEvent("survivor_rescued", event_Rescued);
	HookEvent("bot_player_replace", event_PlayerReplaced, EventHookMode_Post);
	HookEvent("player_bot_replace", event_BotReplaced, EventHookMode_Post);
	HookEvent("player_team", event_PlayerTeamSwitch);
	HookEvent("player_left_start_area", event_LeftStart);
	HookEvent("heal_success", event_HealSuccess);
	HookEvent("player_hurt", event_PlayerHurt);
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("infected_death", event_InfectedDeath);

	AutoExecConfig(true, "l4d_healtharmorsystem");
}

public Action:CommandGiveCash(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage:sm_givecash <#userid|name> <amount>");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[32];
	GetCmdArg(1, arg, sizeof(arg));
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new targetclient;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			iCash[targetclient] += StringToInt(arg2);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(L4DFirstAidKit, 100+GetConVarInt(iMHealthMultiplier)*5);
	SetConVarInt(L4DPainPills, 100+GetConVarInt(iMHealthMultiplier)*5);
}

public OnClientPutInServer(client)
{
	ClientSaveToFileLoad(client);
	ClientCommand(client, "bind f3 sm_buy");
}

public OnClientDisconnect(client)
{
	ClientSaveToFileSave(client);
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client > 0 && GetClientTeam(client) == 2)
	{	
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100 + iMHealth[client] * 5, 4, true);
		SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), m_iArmor[client], 4, true);
	}
}

public event_SetStatus(Handle:event, const String:name[], bool:dontBroadcast) 
{	
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(client > 0 && GetClientTeam(client) == 2)
	{
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100 + iMHealth[client] * 5, 4, true);
		SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), m_iArmor[client], 4, true);
	}
}

public event_Rescued(Handle:event, const String:name[], bool:dontBroadcast) 
{	
	new client = GetClientOfUserId(GetEventInt(event,"victim"));
	if(client > 0 && GetClientTeam(client) == 2)
	{
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100 + iMHealth[client] * 5, 4, true);
		SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), m_iArmor[client], 4, true);
	}
}

public event_PlayerReplaced(Handle:event, const String:name[], bool:dontBroadcast) 
{	
	new client = GetClientOfUserId(GetEventInt(event,"player"));
	if(client > 0 && GetClientTeam(client) == 2)
	{
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100 + iMHealth[client] * 5, 4, true);
		SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), m_iArmor[client], 4, true);
	}
}

public event_BotReplaced(Handle:event, const String:name[], bool:dontBroadcast) 
{		
	new client = GetClientOfUserId(GetEventInt(event,"bot"));

	if(client > 0 && GetClientTeam(client) == 2)
	{
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100 + iMHealth[client] * 5, 4, true);
		SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), m_iArmor[client], 4, true);
	}
}

public event_LeftStart(Handle:event, const String:name[], bool:dontBroadcast) 
{	
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(client > 0 && GetClientTeam(client) == 2)
	{
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100 + iMHealth[client] * 5, 4, true);
		SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), m_iArmor[client], 4, true);
	}
}

public event_PlayerTeamSwitch(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && GetClientTeam(client) == 2)
	{
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100 + iMHealth[client] * 5, 4, true);
		SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), m_iArmor[client], 4, true);
	}
}

public Action:ActivateBuyMenu(client, args)
{
	BuyMenu(client);
}

public BuyMenu(client)
{
	new iMaxHealth = GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4);
	new iHealth = GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4);
	new iMaxArmor = iMArmor[client] * GetConVarInt(iMArmorFactor) * 5;
	new iArmor = GetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 4);

	PrintToChat(client, "\x05Health: \x01%i/%i\n\x05Armor: \x01%i/%i\n\x05Cash: \x01$%i", iHealth, iMaxHealth, iArmor/GetConVarInt(iMArmorFactor), iMaxArmor/GetConVarInt(iMArmorFactor), iCash[client]);

	if(GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		new Handle:BuyMenuPanel = CreatePanel();

		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "\x05Health: \x01%i/%i\n\x05Armor: \x01%i/%i\n\x05Cash: \x01$%i", iHealth, iMaxHealth, iArmor/GetConVarInt(iMArmorFactor), iMaxArmor/GetConVarInt(iMArmorFactor), iCash[client]);
		SetPanelTitle(BuyMenuPanel, buffer);

		new String:text[64];
		Format(text, sizeof(text), "Purchase Health & Armor");
		DrawPanelText(BuyMenuPanel, text);
		
		DrawPanelItem(BuyMenuPanel, "Purchase");
		DrawPanelItem(BuyMenuPanel, "Status Toggle");
		DrawPanelItem(BuyMenuPanel, "Close");
		
		SendPanelToClient(BuyMenuPanel, client, BuyMenuHandler, 30);
		CloseHandle(BuyMenuPanel);
	}
	else
	{
		PrintToChat(client, "\x01[\x03ERROR\x01] You must be Alive, or Menu is Disabled.");
	}    
}

public BuyMenuHandler(Handle:BuyMenuPanel, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			CharacterMenu(client);
		}
		if(param2 == 2)
		{
			if(b_ShowArmor[client] == false)
			{
				b_ShowArmor[client] = true;
				PrintToChat(client, "\x04Status Display \x01is now \x05On.");
			}
			else
			{
				b_ShowArmor[client] = false;
				PrintToChat(client, "\x04Status Display \x01is now \x05Off.");
			}
		}

	}
	else if(action == MenuAction_Cancel)
	{
		// Nothing
	}
}

public CharacterMenu(client)
{
	if(GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{

		new Handle:menu = CreateMenu(CharacterMenuHandler);
		if(iCash[client] >= HEALTH_UPGRADE_COST)
		{
			AddMenuItem(menu, "option1", "Health ($200)");
		}
		if(iCash[client] >= ARMOR_UPGRADE_COST)
		{
			AddMenuItem(menu, "option2", "Armor ($100)");
		}
		if(iCash[client] >= HEALTH_COST)
		{
			AddMenuItem(menu, "option3", "Health +25 ($500)");
		}
		if(iCash[client] >= ARMOR_COST)
		{
			AddMenuItem(menu, "option4", "Armor +25 ($250)");
		}
		SetMenuTitle(menu, "Cash: %d", iCash[client]);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintToChat(client, "\x01[\x03ERROR\x01] You must be Alive, or Menu is Disabled.");
	}
}

public CharacterMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				BuyMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "option1", false))
			{
				if(iMHealth[client] < GetConVarInt(iMHealthMultiplier))
				{			
					iCash[client] -= HEALTH_UPGRADE_COST;
					iMHealth[client] = iMHealth[client] + 1;
					SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100 + iMHealth[client] * 5, 4, true);
					new iMaxHealth = GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4);
					new iHealth = GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4);
					PrintToChat(client, "\x05Health Upgraded: \x01%i/%i", iHealth, iMaxHealth);
					CharacterMenu(client);
				}
				else
				{
					PrintToChat(client, "\x01You have the \x05Maximum Health\x01.");
				}
			}
			else if(StrEqual(item1, "option2", false))
			{
				if(iMArmor[client] < GetConVarInt(iMArmorMultiplier))
				{			
					iCash[client] -= ARMOR_UPGRADE_COST;
					iMArmor[client] = iMArmor[client] + 1;
					new iMaxArmor = iMArmor[client] * GetConVarInt(iMArmorFactor) * 5;
					new iArmor = GetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 4);
					PrintToChat(client, "\x05Armor Upgraded: \x01%i/%i", iArmor/GetConVarInt(iMArmorFactor), iMaxArmor/GetConVarInt(iMArmorFactor));
					CharacterMenu(client);
				}
				else
				{
					PrintToChat(client, "\x01You have the \x05Maximum Armor\x01.");
				}
			}
			else if(StrEqual(item1, "option3", false))
			{
				new iMaxHealth = GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4);
				new iHealth = GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4);
				new iHealthDif = iMaxHealth - iHealth;
				if(iHealthDif >= 25)
				{
					iCash[client] -= HEALTH_COST;						
					SetEntData(client, FindDataMapOffs(client, "m_iHealth"), GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4) + 25, 4, true);
					PrintToChat(client, "\x05+25 Health Restored");
					CharacterMenu(client);
				}
				else
				{
					PrintToChat(client, "\x01You have the \x05Maximum Health\x01.");
				}
			}
			else if(StrEqual(item1, "option4", false))
			{
				new iMaxArmor = iMArmor[client] * GetConVarInt(iMArmorFactor) * 5;
				new iArmor = GetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 4);
				new iArmorDif = iMaxArmor - iArmor;
				if(iArmorDif >= 25)
				{
					iCash[client] -= ARMOR_COST;						
					SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), GetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 4) + 50, 4, true);
					PrintToChat(client, "\x05+25 Armor Restored");
					CharacterMenu(client);
				}
				else
				{
					PrintToChat(client, "\x01You have the \x05Maximum Armor\x01.");
				}
			}
		}
	}
}

public event_PlayerHurt(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) == 2)
	{
		m_iArmor[client] = GetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 4);
		if(b_ShowArmor[client] == true)
		{
			new iMaxHealth = GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4);
			new iHealth = GetEntData(client, FindDataMapOffs(client, "m_iHealth"), 4);
			new iMaxArmor = iMArmor[client] * GetConVarInt(iMArmorFactor) * 5;
			new iArmor = GetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 4);

			PrintHintText(client, "\x05Health: %i/%i\nArmor: %i/%i", iHealth, iMaxHealth, iArmor/GetConVarInt(iMArmorFactor), iMaxArmor/GetConVarInt(iMArmorFactor));
		}
	}
}

public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:VictimName[64];
	GetClientName(victim, VictimName, sizeof(VictimName));
	GetEventString(event, "victimname", VictimName, sizeof(VictimName));

	if(StrEqual(VictimName, "Smoker", false))
	{
		new CASH_SMOKER = GetRandomInt(GetConVarInt(FindConVar("z_gas_health")) / 10, GetConVarInt(FindConVar("z_gas_health")) / 5);
		iCash[client] += CASH_SMOKER;
		if(b_ShowArmor[client] == true)
		{
			PrintToChat(client, "\x01You picked up \x05$%d\x01.", CASH_SMOKER);
		}
	}
	else if(StrEqual(VictimName, "Boomer", false))
	{
		new CASH_BOOMER = GetRandomInt(GetConVarInt(FindConVar("z_exploding_health")) / 10, GetConVarInt(FindConVar("z_exploding_health")) / 5);
		iCash[client] += CASH_BOOMER;
		if(b_ShowArmor[client] == true)
		{
			PrintToChat(client, "\x01You picked up \x05$%d\x01.", CASH_BOOMER);
		}
	}
	else if(StrEqual(VictimName, "Hunter", false))
	{
		new CASH_HUNTER = GetRandomInt(GetConVarInt(FindConVar("z_hunter_health")) / 10, GetConVarInt(FindConVar("z_hunter_health")) / 5);
		iCash[client] += CASH_HUNTER;
		if(b_ShowArmor[client] == true)
		{
			PrintToChat(client, "\x01You picked up \x05$%d\x01.", CASH_HUNTER);
		}
	}
	else if(StrEqual(VictimName, "Witch", false))
	{
		new CASH_WITCH = GetRandomInt(GetConVarInt(FindConVar("z_witch_health")) / 10, GetConVarInt(FindConVar("z_tank_health")) / 5);
		iCash[client] += CASH_WITCH;
		if(b_ShowArmor[client] == true)
		{
			PrintToChat(client, "\x01Earned \x05$%i\x01.", CASH_WITCH);
		}
	}
	else if(StrEqual(VictimName, "Tank", false))
	{
		
		new CASH_TANK = GetRandomInt(GetConVarInt(FindConVar("z_tank_health")) / 10, GetConVarInt(FindConVar("z_tank_health")) / 5);
		iCash[client] += CASH_TANK;
		if(b_ShowArmor[client] == true)
		{
			PrintToChat(client, "\x01Earned \x05$%i\x01.", CASH_TANK);
		}
	}
}

public Action:event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new GetCashProbability = GetRandomInt(1, 100);

	if(GetCashProbability < GetConVarFloat(iCashProbability) * 100)
	{
		new CashValue = GetRandomInt(1, 10);
		iCash[client] += CashValue;
		if(b_ShowArmor[client] == true)
		{
			PrintToChat(client, "\x01Earned \x05$%i\x01.", CashValue);
		}
	}
}

public event_HealSuccess(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));

	m_iArmor[client] = iMArmor[client] * GetConVarInt(iMArmorFactor) * 5;
	SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), m_iArmor[client], 4, true);
}

/* Save To File */
ClientSaveToFileSave(targetid)
{
	decl Handle:kv;
	decl String:cName[MAX_NAME_LENGTH];
	kv = CreateKeyValues("HealthArmorData");
	FileToKeyValues(kv, SavePath);

	GetClientAuthString(targetid, cName, sizeof(cName));

	KvJumpToKey(kv, cName, true);
	KvSetNum(kv, "Max Health", iMHealth[targetid]);
	KvSetNum(kv, "Max Armor", iMArmor[targetid]);
	KvSetNum(kv, "Cash", iCash[targetid]);
	KvRewind(kv);
	KeyValuesToFile(kv, SavePath);
	CloseHandle(kv);
}

/* Load Save From File */
ClientSaveToFileLoad(targetid)
{
	decl Handle:kv;
	decl String:cName[MAX_NAME_LENGTH];
	kv = CreateKeyValues("Battle-RPG Save");
	FileToKeyValues(kv, SavePath);

	GetClientAuthString(targetid, cName, sizeof(cName));

	KvJumpToKey(kv, cName, true);
	iMHealth[targetid] = KvGetNum(kv, "Max Health", 0);
	iMArmor[targetid] = KvGetNum(kv, "Max Armor", 0);
	iCash[targetid] = KvGetNum(kv, "Cash", 0);
	CloseHandle(kv);
}

stock GetAnyValidClient()
{ 
    for (new target = 1; target <= MaxClients; target++) 
    { 
        if (IsClientInGame(target)) return target; 
    } 
    return -1; 
}

stock CheatCommand(client, String:command[], String:argument1[], String:argument2[])
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}