#pragma semicolon 1

// Includes
#include <sourcemod>
#include <sdktools>
#include <tf2attributes>
#include <tf2>
#include <tf2_stocks>

// Defines
#define CMVM_VERSION "1.2"
#define MAX_ATTRIBS 1000

// Plugin Info
public Plugin:myinfo =
{
	name = "[TF2-MVM]Chaos MVM",
	author = "X Kirby",
	description = "Opens MVM to more upgrade customization!",
	version = CMVM_VERSION,
	url = "n/a",
}

// CVars
new Handle:cvar_ShopFile;
new Handle:cvar_StationFile;
new Handle:cvar_UseStations;

// Handles
new Handle:cmvm_version;
//new Handle:cmvm_SetValue;
//new Handle:cmvm_GetValue;
new Handle:kv = INVALID_HANDLE;
new Handle:StatsClass = INVALID_HANDLE;
new Handle:StatsWeapon = INVALID_HANDLE;
new Handle:StatsCustom = INVALID_HANDLE;
//new Handle:StatsBought = INVALID_HANDLE;

// Variables
new AddToCheckpoint = true;
new RoundCount = 0;
new PlayerInMenu = -1;
new BackstepCreds[MAXPLAYERS+1] = 0;
new BackstepSpent[MAXPLAYERS+1] = 0;
new Checkpoint[MAXPLAYERS+1] = 0;
new SpentCheckpoint[MAXPLAYERS+1] = 0;
new SpentCreds[MAXPLAYERS+1] = 0;
new Slot[MAXPLAYERS+1] = 0;
new String:path[512];
//new Float:VAL[MAXPLAYERS+1];

// On Plugin Start
public OnPluginStart()
{
	// Global Forwards
	//cmvm_SetValue = CreateGlobalForward("SetAttribValue", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell);
	//cmvm_GetValue = CreateGlobalForward("GetAttribValue", ET_Single, Param_Cell, Param_Cell, Param_String);
	
	// Cvars
	cmvm_version = CreateConVar("cmvm_version", "1.0", "Version Variable. Don't Change.");
	cvar_UseStations = CreateConVar("cmvm_usestations", "0", "Disable to use Custom Upgrades, Enable to use Standard MVM Upgrade Stations.");
	cvar_ShopFile = CreateConVar("cmvm_upgradefile", "configs/sm_chaosmvm_upgrades.txt", "The configuration file for the Upgrades Shop.");
	cvar_StationFile = CreateConVar("cmvm_stationfile", "sm_chaosmvm_station", "The configuration file for the Upgrade Stations.");
	
	// Commands
	RegAdminCmd("sm_parseshop", Command_ParseShop, ADMFLAG_ROOT);
	RegAdminCmd("sm_resetall", Command_ResetAll, ADMFLAG_ROOT);
	//RegAdminCmd("sm_loadstats", Command_LoadStats, ADMFLAG_ROOT);
	//RegAdminCmd("sm_savestats", Command_SaveStats, ADMFLAG_ROOT);
	RegConsoleCmd("sm_upgrade", Command_UpgradeShop);
	RegConsoleCmd("sm_buy", Command_UpgradeShop);
	RegConsoleCmd("sm_reset", Command_ResetStats);
	
	// Event Hooks
	HookEvent("player_changeclass", Event_ChangeClassTeam);
	HookEvent("player_team", Event_ChangeClassTeam);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("mvm_begin_wave", Event_WaveBegin);
	HookEvent("mvm_wave_complete", Event_WaveComplete);
	HookEvent("mvm_pickup_currency", Event_CurrencyChange);
	HookEvent("mvm_reset_stats", Event_ResetStats);
	HookEvent("mvm_creditbonus_wave", Event_CreditBonus);
	
	// Arrays
	StatsClass = CreateArray(2048, MAX_ATTRIBS);
	StatsWeapon = CreateArray(2048, MAX_ATTRIBS);
	StatsCustom = CreateArray(2048, MAX_ATTRIBS);
	//StatsBought = CreateArray(MAX_ATTRIBS*3, MAXPLAYERS+1);
	
	// Run Defaults
	ParseStats();
	LoadStationStats();
	for(new i=0; i<MAXPLAYERS; i++)
	{
		Checkpoint[i] = 0;
		SpentCheckpoint[i] = 0;
		SpentCreds[i] = 0;
		BackstepCreds[i] = 0;
		//for(new j=0; j<MAX_ATTRIBS*3; j++)
		//{
		//	SetArrayCell(StatsBought, i, 0, j);
		//}
	}
	
	// Version Set
	SetConVarString(cmvm_version, CMVM_VERSION);
}

// Native Creation
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("CMVM_SetAttribValue", Native_SetValue);
	CreateNative("CMVM_GetAttribValue", Native_GetValue);
	return APLRes_Success;
}

// On Map Start
public OnMapStart()
{
	new e = -1;
	for(new i=0; i<MAXPLAYERS; i++)
	{
		Checkpoint[i] = 0;
		//for(new j=0; j<MAX_ATTRIBS*3; j++)
		//{
		//	SetArrayCell(StatsBought, i, 0, j);
		//}
	}
	
	if(!GetConVarBool(cvar_UseStations))
	{
		while((e = FindEntityByClassname(e, "func_upgradestation")) != -1)
		{
			AcceptEntityInput(e, "Disable");
		}
	}
	
	ParseStats();
	LoadStationStats();
}

// On Client Put In Server
public OnClientPutInServer(client)
{
	Checkpoint[client] = 0;
	SpentCheckpoint[client] = 0;
	SpentCreds[client] = 0;
	BackstepCreds[client] = 0;
	//for(new j=0; j<MAX_ATTRIBS*3; j++)
	//{
	//	SetArrayCell(StatsBought, client, 0, j);
	//}
}

// Set Effect Value
public SetValue(client, Handle:plugin, String:effectname[128], any:val)
{
	Call_StartFunction(plugin, GetFunctionByName(plugin, "SetAttribValue"));
	Call_PushCell(client);
	Call_PushCell(plugin);
	Call_PushString(effectname);
	Call_PushCell(val);
	Call_Finish();
}

// Grab Effect By Name
public any:GetValue(client, Handle:plugin, String:effectname[128])
{
	new any:value;		
	Call_StartFunction(plugin, GetFunctionByName(plugin, "GetAttribValue"));
	Call_PushCell(client);
	Call_PushCell(plugin);
	Call_PushString(effectname);
	Call_Finish(_:value);
	return any:value;
}

// Set Custom Attrib Value
public Native_SetValue(Handle:plugin, numParams)
{
	new client, Handle:effect, String:effectname[128], value;
	client = GetNativeCell(1);
	effect = Handle:GetNativeCell(2);
	GetNativeString(1, effectname, sizeof(effectname));
	value = GetNativeCell(3);
	
	Call_StartFunction(effect, GetFunctionByName(effect, "SetAttribValue"));
	Call_PushCell(client);
	Call_PushCell(effect);
	Call_PushString(effectname);
	Call_PushCell(value);
	Call_Finish();
}

// Get Custom Attrib Value
public Native_GetValue(Handle:plugin, numParams)
{
	new client, Handle:effect, value;
	new String:effname[128];
	client = GetNativeCell(1);
	effect = Handle:GetNativeCell(2);
	GetNativeString(1, effname, sizeof(effname));

	Call_StartFunction(effect, GetFunctionByName(effect, "GetAttribValue"));
	Call_PushCell(client);
	Call_PushCell(effect);
	Call_PushString(effname);
	Call_Finish(_:value);
	
	return _:value;
}

// Round Restart Event
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Upgrade Station Setup
	new e = -1;
	if(!GetConVarBool(cvar_UseStations))
	{
		while((e = FindEntityByClassname(e, "func_upgradestation")) != -1)
		{
			AcceptEntityInput(e, "Disable");
		}
		
		// Round Check
		AddToCheckpoint = true;
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsValidEntity(i))
			{
				/*
				if(RoundCount > 0)
				{
					LoadStats(i);
					if(BackstepCreds[i] >= 0)
					{
						SetEntProp(i, Prop_Send, "m_nCurrency", BackstepCreds[i]);
						SpentCreds[i] = BackstepSpent[i];
					}
					else
					{
						SetEntProp(i, Prop_Send, "m_nCurrency", Checkpoint[i]);
						SpentCreds[i] = SpentCheckpoint[i];
					}
				}
				*/
				if(RoundCount >= 0)
				{
					Checkpoint[i] = GetEntProp(i, Prop_Send, "m_nCurrency");
					SpentCheckpoint[i] = 0;
					SpentCreds[i] = 0;
					ResetPlayer(i);
				}
			}
		}
		PrintToServer("[CMVM] Game State Refreshed.");
	}
	else
	{
		while((e = FindEntityByClassname(e, "func_upgradestation")) != -1)
		{
			AcceptEntityInput(e, "Enable");
		}
	}
	RoundCount = 0;
}

// Wave Begin Event
public Event_WaveBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundCount++;
	if(!GetConVarBool(cvar_UseStations))
	{
		AddToCheckpoint = false;
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				BackstepCreds[i] = GetEntProp(i, Prop_Send, "m_nCurrency");
				BackstepSpent[i] = SpentCreds[i];
			}
		}
		PrintToServer("[CMVM] Wave Starting.");
	}
}

// Wave Completed Event
public Event_WaveComplete(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(cvar_UseStations))
	{
		AddToCheckpoint = true;
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				//SaveStats(i);
				BackstepCreds[i] = -1;
				BackstepSpent[i] = -1;
				Checkpoint[i] = GetEntProp(i, Prop_Send, "m_nCurrency");
				SpentCheckpoint[i] = SpentCreds[i];
				//SpentCreds[i] = 0;
			}
		}
		PrintToServer("[CMVM] Game State Stored.");
	}
}

// Currency Change Event
public Event_CurrencyChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(AddToCheckpoint && !GetConVarBool(cvar_UseStations))
			{
				//SaveStats(i);
				BackstepCreds[i] = -1;
				BackstepSpent[i] = -1;
				Checkpoint[i] += GetEventInt(event, "currency");
				SpentCheckpoint[i] = SpentCreds[i];
				//SpentCreds[i] = 0;
			}
		}
	}
}

// Bonus Credits Event
public Event_CreditBonus(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && !GetConVarBool(cvar_UseStations))
		{
			//SaveStats(i);
			Checkpoint[i] = GetEntProp(i, Prop_Send, "m_nCurrency");
			SpentCheckpoint[i] = SpentCreds[i];
		}
	}
}

// Reset Stats
public Event_ResetStats(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!GetConVarBool(cvar_UseStations))
	{
		if(client >= 1 && client <= MaxClients)
		{
			SetEntProp(client, Prop_Send, "m_nCurrency", GetEntProp(client, Prop_Send, "m_nCurrency") + SpentCreds[client]);
			SpentCreds[client] = 0;
			SpentCheckpoint[client] = 0;
			Checkpoint[client] = 0;
			ResetPlayer(client);
			PrintToConsole(client, "[CMVM]Reset Stats and refunded Credits.");
		}
	}
}

// Change Class/Team Event
public Event_ChangeClassTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!GetConVarBool(cvar_UseStations))
	{
		SetEntProp(client, Prop_Send, "m_nCurrency", GetEntProp(client, Prop_Send, "m_nCurrency") + SpentCreds[client]);
		SpentCreds[client] = 0;
		SpentCheckpoint[client] = 0;
		Checkpoint[client] = 0;
		ResetPlayer(client);
		PrintToConsole(client, "[CMVM]Reset Stats and refunded Credits.");
	}
}

// Command: Open Upgrade Shop
public Action:Command_UpgradeShop(client, args)
{
	if(!GetConVarBool(cvar_UseStations))
	{
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				CreateShopPanel(client);
			}
		}
	}
	
	return Plugin_Handled;
}

// Command: Reset User Stats
public Action:Command_ResetStats(client, args)
{
	if(!GetConVarBool(cvar_UseStations))
	{
		SetEntProp(client, Prop_Send, "m_nCurrency", GetEntProp(client, Prop_Send, "m_nCurrency") + SpentCreds[client]);
		SpentCreds[client] = 0;
		SpentCheckpoint[client] = 0;
		Checkpoint[client] = 0;
		ResetPlayer(client);
		PrintToConsole(client, "[CMVM]Reset Stats and refunded Credits.");
	}
	return Plugin_Handled;
}

// Command: Reset All Player's Stats
public Action:Command_ResetAll(client, args)
{
	if(!GetConVarBool(cvar_UseStations))
	{
		ResetAllPlayers();
		PrintToConsoleAll("[CMVM]All Players Reset and Refunded.");
	}
	return Plugin_Handled;
}

// Admin Command: Parse Shop Lists
public Action:Command_ParseShop(client, args)
{
	ParseStats();
	LoadStationStats();
	return Plugin_Handled;
}

/* ---DEBUG COMMANDS, LEAVE ALONE---
// Admin Command: Save User Stats
public Action:Command_SaveStats(client, args)
{
	if(!GetConVarBool(cvar_UseStations))
	{
		SaveStats(client);
		PrintToConsole(client, "[CMVM]Attempted to Save Stats.");
	}
	return Plugin_Handled;
}

// Admin Command: Load User Stats
public Action:Command_LoadStats(client, args)
{
	if(!GetConVarBool(cvar_UseStations))
	{
		LoadStats(client);
		PrintToConsole(client, "[CMVM]Attempted to Load Stats.");
	}
	return Plugin_Handled;
}
*/

public CreateShopPanel(client)
{
	if(IsPlayerAlive(client))
	{
		new Handle:panel = CreatePanel();
		SetPanelTitle(panel, "Upgrade Shop");
		DrawPanelItem(panel, "Primary");
		DrawPanelItem(panel, "Secondary");
		DrawPanelItem(panel, "Melee");
		DrawPanelItem(panel, "PDA/Sapper");
		DrawPanelItem(panel, "Watch");
		DrawPanelItem(panel, "Player");
		DrawPanelItem(panel, "Canteen");
		DrawPanelItem(panel, "Custom");
		DrawPanelItem(panel, "Exit");
		SendPanelToClient(panel, client, Panel_SlotSelect, MENU_TIME_FOREVER);
		CloseHandle(panel);
	}
}

// Panel: Slot Selection
public Panel_SlotSelect(Handle:menu, MenuAction:action, p1, p2)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(p1))
		{
			Slot[p1] = 0;
			p2--;
			PlayerInMenu = p1;
			switch(p2)
			{
				case 0, 1, 2, 3, 4:
				{
					Slot[p1] = GetPlayerWeaponSlot(p1, p2);
					if(Slot[p1] <= -1)
					{
						Slot[p1] = MaxClients+1;
						switch(p2)
						{
							case 0:
							{
								while((Slot[p1] = FindEntityByClassname(Slot[p1], "tf_wearable")) != -1)
								{
									new idx = GetEntProp(Slot[p1], Prop_Send, "m_iItemDefinitionIndex");
									if((idx == 405 || idx == 608) && GetEntPropEnt(Slot[p1], Prop_Send, "m_hOwnerEntity") == p1 && !GetEntProp(Slot[p1], Prop_Send, "m_bDisguiseWearable"))
										{break;}
								}
							}
							case 1:
							{
								while((Slot[p1] = FindEntityByClassname(Slot[p1], "tf_wearable")) != -1)
								{
									new idx = GetEntProp(Slot[p1], Prop_Send, "m_iItemDefinitionIndex");
									if((idx == 133 || idx == 444 || idx == 57 || idx == 231 || idx == 642) && GetEntPropEnt(Slot[p1], Prop_Send, "m_hOwnerEntity") == p1 && !GetEntProp(Slot[p1], Prop_Send, "m_bDisguiseWearable"))
										{break;}
								}
								
								if(Slot[p1] == -1)
								{
									while((Slot[p1] = FindEntityByClassname(Slot[p1], "tf_wearable_demoshield")) != -1)
									{
										new idx = GetEntProp(Slot[p1], Prop_Send, "m_iItemDefinitionIndex");
										if((idx == 131 || idx == 406 || idx == 1099) && GetEntPropEnt(Slot[p1], Prop_Send, "m_hOwnerEntity") == p1 && !GetEntProp(Slot[p1], Prop_Send, "m_bDisguiseWearable"))
											{break;}
									}
								}
							}
							
							default:
							{
								Slot[p1] = -1;
							}
						}
					}
				}
				
				case 5:
					{Slot[p1] = -1;}
				
				case 6:
				{
					while((Slot[p1] = FindEntityByClassname(Slot[p1], "tf_powerup_bottle")) != -1)
					{
						new idx = GetEntProp(Slot[p1], Prop_Send, "m_iItemDefinitionIndex");
						if((idx == 489 || idx == 30015 || idx == 1163 || idx == 30535) && GetEntPropEnt(Slot[p1], Prop_Send, "m_hOwnerEntity") == p1 && !GetEntProp(Slot[p1], Prop_Send, "m_bDisguiseWearable"))
							{break;}
					}
					
					if(Slot[p1] == -1)
					{
						Slot[p1] = -3;
					}
				}
				
				case 7:
					{Slot[p1] = -2;}
				
				case 8:
					{Slot[p1] = -3;}
			}
			
			new Handle:M = INVALID_HANDLE;
			M = BuildUpgradeMenu();
			if(Slot[p1] != -3 && M != INVALID_HANDLE)
			{
				DisplayMenu(M, p1, MENU_TIME_FOREVER);
			}
		}
	}
}

// Handle: Build Upgrade Menu
Handle:BuildUpgradeMenu()
{
	// Open the Upgrades File
	new Handle:menu = INVALID_HANDLE;
	menu = CreateMenu(Menu_UpgradeShop);
	
	// Set Player
	new p1 = PlayerInMenu;
	PlayerInMenu = -1;
	
	// Find the Slot Type
	new Type = 0, bool:Match = false;
	if(Slot[p1] == -1)
		{Type = 0;}
	if(Slot[p1] > 0)
		{Type = 1;}
	if(Slot[p1] == -2)
		{Type = 2;}
	
	// Find Attribute Values
	for(new i=0; i<MAX_ATTRIBS; i++)
	{
		new String:FullBuffer[2048], String:Buffers[5][512], String:SubBuffers[4][128], String:Value[5][512];
		Match = false;
		
		switch(Type)
		{
			case 0:{GetArrayString(StatsClass, i, FullBuffer, sizeof(FullBuffer));}
			case 1:{GetArrayString(StatsWeapon, i, FullBuffer, sizeof(FullBuffer));}
			case 2:{GetArrayString(StatsCustom, i, FullBuffer, sizeof(FullBuffer));}
		}
		ExplodeString(FullBuffer, "|", Buffers, 5, 512, false);
		
		for(new j=0; j<5; j++)
		{
			ExplodeString(Buffers[j], ">", SubBuffers, 4, 128, false);
			switch(Type)
			{
				// Class Upgrade
				case 0:
				{
					new TFClassType:Class = TF2_GetPlayerClass(p1);
					if(TF2_GetClass(SubBuffers[0]) == Class)
					{
						Match = true;
						strcopy(Value[j], 512, SubBuffers[3]);
					}
				}
				
				// Weapon Upgrade
				case 1:
				{
					new String:WeaponList[100][8], String:SlotID[8];
					IntToString(GetEntProp(Slot[p1], Prop_Send, "m_iItemDefinitionIndex"), SlotID, sizeof(SlotID));
					ExplodeString(SubBuffers[0], " ; ", WeaponList, 100, 8, false);
					for(new k=0; k<100; k++)
					{
						if(StrEqual(WeaponList[k], SlotID))
						{
							Match = true;
							strcopy(Value[j], 512, SubBuffers[3]);
							break;
						}
					}
				}
				
				// Custom Upgrade
				case 2:
				{
					if(StrEqual(SubBuffers[0], "custom"))
					{
						Match = true;
						strcopy(Value[j], 512, SubBuffers[3]);
					}
				}
			}
		}
		
		new String:NAME[1024];
		if(Match)
		{
			NAME = AddMenuAttrib(p1, SubBuffers[1], StringToInt(Value[1]), StringToFloat(Value[2]), StringToInt(Value[3]), StringToFloat(Value[4]), Value[0], Slot[p1]);
			if(!StrEqual(NAME, "<Empty>"))
			{
				AddMenuItem(menu, SubBuffers[1], NAME);
			}
		}
	}
	
	SetMenuTitle(menu, "Upgrade Select");
	return menu;
}

// Menu: Upgrade Shop
public Menu_UpgradeShop(Handle:menu, MenuAction:action, p1, p2)
{
	if(p1 > 0 && p1 <= MAXPLAYERS)
	{
		if(action == MenuAction_Select)
		{
			// Redisplay Menu
			PlayerInMenu = p1;
		
			// Find the Slot Type
			new Type = 0, String:info[128];
			if(Slot[p1] == -1)
				{Type = 0;}
			if(Slot[p1] > 0)
				{Type = 1;}
			if(Slot[p1] == -2)
				{Type = 2;}
			
			// Copy down the Attribute
			GetMenuItem(menu, p2, info, sizeof(info));
			
			new String:FullBuffer[2048], String:Buffers[5][2048], String:SubBuffers[4][512], String:Value[5][128];
			
			// Find Attribute Values
			for(new i=0; i<MAX_ATTRIBS; i++)
			{
				switch(Type)
				{
					case 0:{GetArrayString(StatsClass, i, FullBuffer, sizeof(FullBuffer));}
					case 1:{GetArrayString(StatsWeapon, i, FullBuffer, sizeof(FullBuffer));}
					case 2:{GetArrayString(StatsCustom, i, FullBuffer, sizeof(FullBuffer));}
				}
				ExplodeString(FullBuffer, "|", Buffers, 5, 2048, false);
				
				for(new j=0; j<5; j++)
				{
					ExplodeString(Buffers[j], ">", SubBuffers, 4, 512, false);
					switch(Type)
					{
						// Class Upgrade
						case 0:
						{
							new TFClassType:Class = TF2_GetPlayerClass(p1);
							if(TF2_GetClass(SubBuffers[0]) == Class && StrEqual(SubBuffers[1], info))
							{
								strcopy(Value[j], 128, SubBuffers[3]);
							}
						}
						
						// Weapon Upgrade
						case 1:
						{
							new String:WeaponList[512][8], String:SlotID[8];
							IntToString(GetEntProp(Slot[p1], Prop_Send, "m_iItemDefinitionIndex"), SlotID, sizeof(SlotID));
							ExplodeString(SubBuffers[0], " ; ", WeaponList, 512, 8, false);
							for(new k=0; k<512; k++)
							{
								if(StrEqual(WeaponList[k], SlotID) && StrEqual(SubBuffers[1], info))
								{
									strcopy(Value[j], 128, SubBuffers[3]);
								}
							}
						}
						
						// Custom Upgrade
						case 2:
						{
							if(StrEqual(SubBuffers[0], "custom") && StrEqual(SubBuffers[1], info))
							{
								strcopy(Value[j], 128, SubBuffers[3]);
							}
						}
					}
				}
			}
			
			new Cost, Float:UpValue, UpLimit, Float:Start, Ent, Address:A, Float:AttribAmount;
			Cost = StringToInt(Value[1]);
			UpValue = StringToFloat(Value[2]);
			UpLimit = StringToInt(Value[3]);
			Start = StringToFloat(Value[4]);
			
			if(Slot[p1] < 0)
				{Ent = p1;}
			else
				{Ent = Slot[p1];}
			
			// Attribute Check
			if(Slot[p1] >= -1)
			{
				A = TF2Attrib_GetByName(Ent, info);
				if(A == Address_Null)
				{
					TF2Attrib_SetByName(Ent, info, Start);
					A = TF2Attrib_GetByName(Ent, info);
				}
				
				AttribAmount = TF2Attrib_GetValue(A);
				
				new String:weaponclass[128];
				GetEntityClassname(Ent, weaponclass, sizeof(weaponclass));
				if(StrEqual(weaponclass, "tf_powerup_bottle"))
				{
					A = TF2Attrib_GetByName(Ent, info);
					AttribAmount = TF2Attrib_GetValue(A);
					if(GetEntProp(Ent, Prop_Send, "m_usNumCharges") < AttribAmount && (StrEqual(info, "building instant upgrade") || StrEqual(info, "critboost") ||
					StrEqual(info, "ubercharge") || StrEqual(info, "refill_ammo") || StrEqual(info, "recall")))
					{
						AttribAmount = float(GetEntProp(Ent, Prop_Send, "m_usNumCharges"));
					}
				}
			}
			else
			{
				new Float:val = 0.0, String:s[128], Handle:p, Handle:iter = GetPluginIterator();
				while(MorePlugins(iter))
				{
					p = ReadPlugin(iter);
					GetPluginFilename(p, s, sizeof(s));
					ReplaceString(s, sizeof(s), "disabled\\", "");
					ReplaceString(s, sizeof(s), ".smx", "");
					if(StrContains(info, s, false) > -1)
					{
						val = Float:GetValue(p1, p, info);
						break;
					}
				}
				CloseHandle(iter);
				
				AttribAmount = val;
			}
			
			// Attribute Counter
			new Count = 0, Float:l = Start;
			if(UpValue > 0.0)
			{
				for(l = Start; l < AttribAmount; l += FloatAbs(UpValue))
					{Count++;}
			}
			else if(UpValue < 0.0)
			{
				for(l = Start; l > AttribAmount; l -= FloatAbs(UpValue))
				{
					{Count++;}
				}
			}
			
			// Purchase Check
			if(Count >= UpLimit)
			{
				PrintToConsole(p1, "[CMVM]That Upgrade is already maxed out!");
			}
			else if(Cost > GetEntProp(p1, Prop_Send, "m_nCurrency"))
			{
				PrintToConsole(p1, "[CMVM]Not enough Credits.");
			}
			else if(AttribAmount + UpValue != Start)
			{
				if(IsPlayerAlive(p1))
				{
					new Creds = GetEntProp(p1, Prop_Send, "m_nCurrency");
					Creds -= Cost;
					Count++;
					
					if(Slot[p1] >= -1)
					{
						new String:weaponclass[128];
						GetEntityClassname(Ent, weaponclass, sizeof(weaponclass));
						if(StrEqual(weaponclass, "tf_powerup_bottle") && (StrEqual(info, "building instant upgrade") || StrEqual(info, "critboost") ||
						StrEqual(info, "ubercharge") || StrEqual(info, "refill_ammo") || StrEqual(info, "recall")))
						{
							//TF2Attrib_SetByName(Ent, "ubercharge", 0.0);
							//TF2Attrib_SetByName(Ent, "critboost", 0.0);
							//TF2Attrib_SetByName(Ent, "recall", 0.0);
							//TF2Attrib_SetByName(Ent, "refill_ammo", 0.0);
							//TF2Attrib_SetByName(Ent, "building instant upgrade", 0.0);
							
							TF2Attrib_RemoveByName(Ent, "ubercharge");
							TF2Attrib_RemoveByName(Ent, "critboost");
							TF2Attrib_RemoveByName(Ent, "recall");
							TF2Attrib_RemoveByName(Ent, "refill_ammo");
							TF2Attrib_RemoveByName(Ent, "building instant upgrade");
							SetEntProp(Ent, Prop_Send, "m_usNumCharges", RoundToFloor(AttribAmount + UpValue));
						}
						TF2Attrib_SetByName(Ent, info, AttribAmount + UpValue);
					}
					else
					{
						new Float:v = AttribAmount + UpValue;
						
						new String:s[128], Handle:p, Handle:iter = GetPluginIterator();
						while(MorePlugins(iter))
						{
							p = ReadPlugin(iter);
							GetPluginFilename(p, s, sizeof(s));
							ReplaceString(s, sizeof(s), "disabled\\", "");
							ReplaceString(s, sizeof(s), ".smx", "");
							if(StrContains(info, s, false) > -1)
							{
								SetValue(p1, p, info, any:v);
								break;
							}
						}
						CloseHandle(iter);
					}
					
					SetEntProp(p1, Prop_Send, "m_nCurrency", Creds);
					SpentCreds[p1] += Cost;
					PrintToConsole(p1, "[CMVM]%s purchased! (Level %i/%i)", Value[0], Count, UpLimit);
				}
			}
			
			DisplayMenu(BuildUpgradeMenu(), p1, MENU_TIME_FOREVER);
		}
		if(action == MenuAction_Cancel)
		{
			CreateTimer(0.1, t_RedisplayShop, p1);
		}
	}
}

// Function: Load Station Stats
LoadStationStats()
{
	new String:F[512], edict;
	GetConVarString(cvar_StationFile, F, sizeof(F));
	Format(F, sizeof(F), "scripts/items/%s.txt", F);
	
	edict = -1;
	while((edict = FindEntityByClassname(edict, "tf_gamerules")) != -1)
	{
		SetVariantString(F);
		AcceptEntityInput(edict, "SetCustomUpgradesFile");
	}
	
	PrecacheGeneric(F, true);
	AddFileToDownloadsTable(F);
}

// Function: Parse Stats
ParseStats()
{
	if(kv != INVALID_HANDLE)
	{
		CloseHandle(kv);
		kv = INVALID_HANDLE;
	}
	kv = CreateKeyValues("chaosmvm_upgrades");

	new String:F[512], pos[3] = 0;
	GetConVarString(cvar_ShopFile, F, sizeof(F));
	BuildPath(Path_SM, path, sizeof(path), F);
	
	if(FileToKeyValues(kv, path))
	{
		new String:ClassName[2048], String:UpgradeName[128], String:MenuName[128];
		KvGotoFirstSubKey(kv);
		do
		{
			KvGetSectionName(kv, ClassName, sizeof(ClassName));
			
			KvGotoFirstSubKey(kv);
			do
			{
				KvGetSectionName(kv, UpgradeName, sizeof(UpgradeName));
				
				new String:Sections[5][2048], String:Final[2048], Cost, Float:StatChange, UpLimit, Float:Start;
				KvGetString(kv, "menuname", MenuName, sizeof(MenuName), "Upgrade");
				Cost = KvGetNum(kv, "cost", 0);
				StatChange = KvGetFloat(kv, "upgrade", 0.0);
				UpLimit = KvGetNum(kv, "max", 0);
				Start = KvGetFloat(kv, "start", 0.0);
				
				Format(Sections[0], 2048, "%s>%s>%s>%s", ClassName, UpgradeName, "menuname", MenuName);
				Format(Sections[1], 2048, "%s>%s>%s>%i", ClassName, UpgradeName, "cost", Cost);
				Format(Sections[2], 2048, "%s>%s>%s>%f", ClassName, UpgradeName, "upgrade", StatChange);
				Format(Sections[3], 2048, "%s>%s>%s>%i", ClassName, UpgradeName, "max", UpLimit);
				Format(Sections[4], 2048, "%s>%s>%s>%f", ClassName, UpgradeName, "start", Start);
				ImplodeStrings(Sections, 5, "|", Final, sizeof(Final));
				
				if(TF2_GetClass(ClassName) != TFClass_Unknown)
				{
					SetArrayString(StatsClass, pos[0], Final);
					pos[0]++;
				}
				
				else if(StrEqual(ClassName, "custom"))
				{
					SetArrayString(StatsCustom, pos[1], Final);
					pos[1]++;
				}
				
				else
				{
					SetArrayString(StatsWeapon, pos[2], Final);
					pos[2]++;
				}
			} while (KvGotoNextKey(kv));
			
			KvGoBack(kv);
			
		} while (KvGotoNextKey(kv));
	}
}

// Function: Add Menu Attribute
String:AddMenuAttrib(client, String:Upgrade[128], Cost, Float:UpValue, UpLimit, Float:Start, String:Details[512], SlotID)
{
	new E = -1, Address:A, Float:AttribAmount = 0.0;
	if(SlotID < 0)
		{E = client;}
	else
		{E = SlotID;}
	
	// Attribute Check
	if(SlotID >= -1)
	{
		A = TF2Attrib_GetByName(E, Upgrade);
		if(A == Address_Null)
		{
			TF2Attrib_SetByName(E, Upgrade, Start);
			A = TF2Attrib_GetByName(E, Upgrade);
			if(A == Address_Null)
			{
				new String:ERROR[1024] = "<Empty>";
				return ERROR;
			}
		}
		
		AttribAmount = TF2Attrib_GetValue(A);
		
		if(AttribAmount == Start)
			{TF2Attrib_RemoveByName(E, Upgrade);}
	}
	else
	{
		new String:u[128];
		strcopy(u, 128, Upgrade);
		
		new String:s[128], Handle:p, Handle:iter = GetPluginIterator();
		while(MorePlugins(iter))
		{
			p = ReadPlugin(iter);
			GetPluginFilename(p, s, sizeof(s));
			ReplaceString(s, sizeof(s), "disabled\\", "");
			ReplaceString(s, sizeof(s), ".smx", "");
			if(StrContains(u, s, false) > -1)
			{
				AttribAmount = Float:GetValue(client, p, u);
				break;
			}
		}
		CloseHandle(iter);
	}
	
	// Attribute Counter
	new Count = 0, Float:i = 0.0;
	if(UpValue > 0.0)
	{
		for(i = Start; i < AttribAmount; i += UpValue)
			{Count++;}
	}
	else if(UpValue < 0.0)
	{
		for(i = Start; i > AttribAmount; i -= FloatAbs(UpValue))
		{
			{Count++;}
		}
	}
	
	if(UpValue == 0.0)
	{
		new String:ERROR[1024] = "<Empty>";
		return ERROR;
	}
	
	// Returns the Menu Label for the Upgrade
	new String:MenuLabel[1024];
	Format(MenuLabel, sizeof(MenuLabel), "[%i/%i]%s ($%i)", Count, UpLimit, Details, Cost);
	return MenuLabel;
}

// Function: Reset All Player Stats
ResetAllPlayers()
{
	// Reset Stats
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SetEntProp(i, Prop_Send, "m_nCurrency", GetEntProp(i, Prop_Send, "m_nCurrency") + SpentCreds[i]);
			SpentCreds[i] = 0;
			ResetPlayer(i);
		}
	}
}

// Function: Reset Player Stats
ResetPlayer(client)
{
	if(IsClientInGame(client))
	{
		Slot[client] = MaxClients+1;
		while((Slot[client] = FindEntityByClassname(Slot[client], "tf_wearable")) != -1)
		{
			new idx = GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex");
			if((idx == 405 || idx == 608 || idx == 133 || idx == 444 || idx == 57 || idx == 231 || idx == 642) && GetEntPropEnt(Slot[client], Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(Slot[client], Prop_Send, "m_bDisguiseWearable"))
				{TF2Attrib_RemoveAll(Slot[client]);}
		}
		
		while((Slot[client] = FindEntityByClassname(Slot[client], "tf_wearable_demoshield")) != -1)
		{
			new idx = GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex");
			if((idx == 131 || idx == 406 || idx == 1099) && GetEntPropEnt(Slot[client], Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(Slot[client], Prop_Send, "m_bDisguiseWearable"))
				{TF2Attrib_RemoveAll(Slot[client]);}
		}
		
		while((Slot[client] = FindEntityByClassname(Slot[client], "tf_powerup_bottle")) != -1)
		{
			new idx = GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex");
			if((idx == 489 || idx == 1163 || idx == 30015 || idx == 30535) && GetEntPropEnt(Slot[client], Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(Slot[client], Prop_Send, "m_bDisguiseWearable"))
				{
					TF2Attrib_RemoveAll(Slot[client]);
					TF2Attrib_SetByName(Slot[client], "powerup charges", 0.0);
					TF2Attrib_SetByName(Slot[client], "powerup max charges", 3.0);
					TF2Attrib_SetByName(Slot[client], "powerup duration", 5.0);
					SetEntProp(Slot[client], Prop_Send, "m_usNumCharges", 0);
				}
		}
		
		TF2Attrib_RemoveAll(client);
		TF2_RemoveAllWeapons(client);
		ResetCustom(client);
		if(IsPlayerAlive(client))
		{
			TF2_RespawnPlayer(client);
		}
	}
}

// Function: Reset Custom Stats
ResetCustom(client)
{
	new String:FullBuffer[2048], String:Buffers[5][2048], String:SubBuffers[4][512], String:Value[5][256];
	new String:info[128];
	for(new i = 0; i < MAX_ATTRIBS; i++)
	{
		GetArrayString(StatsCustom, i, FullBuffer, sizeof(FullBuffer));
		ExplodeString(FullBuffer, "|", Buffers, 5, 2048, false);
		for(new j=0; j<5; j++)
		{
			ExplodeString(Buffers[j], ">", SubBuffers, 4, 512, false);
			if(StrEqual(SubBuffers[0], "custom"))
			{
				strcopy(info, sizeof(info), SubBuffers[1]);
				strcopy(Value[j], 256, SubBuffers[3]);
			}
			else
			{
				info = "";
			}
		}
		
		if(strlen(info) > 0)
		{
			new Float:val = 0.0;
			StringToFloatEx(Value[4], val);
			
			new String:s[128], Handle:p, Handle:iter = GetPluginIterator();
			while(MorePlugins(iter))
			{
				p = ReadPlugin(iter);
				GetPluginFilename(p, s, sizeof(s));
				ReplaceString(s, sizeof(s), "disabled\\", "");
				ReplaceString(s, sizeof(s), ".smx", "");
				if(StrContains(info, s, false) > -1)
				{
					SetValue(client, p, info, any:val);
					break;
				}
			}
			CloseHandle(iter);
		}
	}
}

// Function: Save Stats
/*
SaveStats(client)
{
	if(IsClientInGame(client))
	{
		if(!IsFakeClient(client))
		{
			new String:FullBuffer[2048], String:Buffers[5][2048], String:SubBuffers[4][512], String:Value[5][128], String:WeaponList[256][8];
			new TFClassType:Class = TF2_GetPlayerClass(client), String:info[256], Address:A;
			for(new i=0; i<MAX_ATTRIBS; i++)
			{
				for(new j=0; j<3; j++)
				{
					info = "";
					switch(j)
					{
						case 0:{GetArrayString(StatsClass, i, FullBuffer, sizeof(FullBuffer));}
						case 1:{GetArrayString(StatsWeapon, i, FullBuffer, sizeof(FullBuffer));}
						case 2:{GetArrayString(StatsCustom, i, FullBuffer, sizeof(FullBuffer));}
					}
					ExplodeString(FullBuffer, "|", Buffers, 5, 2048, false);
					for(new k=0; k<5; k++)
					{
						new WepFound = false;
						ExplodeString(Buffers[k], ">", SubBuffers, 4, 512, false);
						switch(j)
						{
							case 0:
							{
								if(Class == TF2_GetClass(SubBuffers[0]))
								{
									strcopy(info, sizeof(info), SubBuffers[1]);
									strcopy(Value[k], 128, SubBuffers[3]);
									continue;
								}
							}
							
							case 1:
							{
								for(new l=0; l<=6; l++)
								{
									Slot[client] = -1;
									if(l < 5)
									{
										Slot[client] = GetPlayerWeaponSlot(client, l);
										if(Slot[client] <= -1)
										{
											switch(l)
											{
												case 0:
												{
													while((Slot[client] = FindEntityByClassname(Slot[client], "tf_wearable")) != -1)
													{
														new idx = GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex");
														if((idx == 405 || idx == 608) && GetEntPropEnt(Slot[client], Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(Slot[client], Prop_Send, "m_bDisguiseWearable"))
															{break;}
													}
												}
												
												case 1:
												{
													while((Slot[client] = FindEntityByClassname(Slot[client], "tf_wearable")) != -1)
													{
														new idx = GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex");
														if((idx == 405 || idx == 608 || idx == 57 || idx == 231 || idx == 642) && GetEntPropEnt(Slot[client], Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(Slot[client], Prop_Send, "m_bDisguiseWearable"))
															{break;}
													}
													
													if(Slot[client] == -1)
													{
														while((Slot[client] = FindEntityByClassname(Slot[client], "tf_wearable_demoshield")) != -1)
														{
															new idx = GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex");
															if((idx == 131 || idx == 406 || idx == 1099) && GetEntPropEnt(Slot[client], Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(Slot[client], Prop_Send, "m_bDisguiseWearable"))
																{break;}
														}
													}
												}
											}
										}
										
										if(IsValidEntity(Slot[client]))
										{
											new String:SlotID[8];
											IntToString(GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex"), SlotID, sizeof(SlotID));
											ExplodeString(SubBuffers[0], " ; ", WeaponList, 256, 8, false);
											for(new m=0; m<256; m++)
											{
												if(StrEqual(WeaponList[m], SlotID))
												{
													strcopy(info, sizeof(info), SubBuffers[1]);
													strcopy(Value[k], 512, SubBuffers[3]);
													WepFound = true;
													break;
												}
											}
										}
									}
									else
									{
										if(Slot[client] == -1)
										{
											while((Slot[client] = FindEntityByClassname(Slot[client], "tf_powerup_bottle")) != -1)
											{
												new idx = GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex");
												if((idx == 489 || idx == 1163 || idx == 30015 || idx == 30535) && GetEntPropEnt(Slot[client], Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(Slot[client], Prop_Send, "m_bDisguiseWearable"))
													{break;}
											}
											
											if(IsValidEntity(Slot[client]))
											{
												new String:SlotID[8];
												IntToString(GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex"), SlotID, sizeof(SlotID));
												ExplodeString(SubBuffers[0], " ; ", WeaponList, 256, 8, false);
												for(new m=0; m<256; m++)
												{
													if(StrEqual(WeaponList[m], SlotID))
													{
														strcopy(info, sizeof(info), SubBuffers[1]);
														strcopy(Value[k], 512, SubBuffers[3]);
														WepFound = true;
														break;
													}
												}
											}
										}
									}
									if(WepFound){break;}
								}
								if(WepFound){continue;}
							}
							
							case 2:
							{
								if(StrEqual(SubBuffers[1], "custom"))
								{
									strcopy(info, sizeof(info), SubBuffers[1]);
									strcopy(Value[k], 512, SubBuffers[3]);
									continue;
								}
							}
						}
					}
					
					if(strlen(info) > 0)
					{
						new Float:Start, Ent, Count, Float:UpValue;
						Count = 0;
						UpValue = StringToFloat(Value[2]);
						Start = StringToFloat(Value[4]);
						switch(j)
						{
							case 0:{Ent = client;}
							case 1:{Ent = Slot[client];}
						}
						if(j < 2)
						{
							A = TF2Attrib_GetByName(Ent, info);
							if(A == Address_Null)
							{
								TF2Attrib_SetByName(Ent, info, Start);
								A = TF2Attrib_GetByName(Ent, info);
							}
							new Float:v = TF2Attrib_GetValue(A);
							
							if(v != Start)
							{
								if(UpValue > 0.0)
								{
									for(new Float:x = Start; x < v; x += FloatAbs(UpValue))
										{Count++;}
								}
								else if(UpValue < 0.0)
								{
									for(new Float:x = Start; x > v; x -= FloatAbs(UpValue))
										{Count++;}
								}
							}
							else
								{TF2Attrib_RemoveByName(Ent, info);}
						}
						else
						{
							new Float:v = Float:GetCustomValue(client, info);
							if(v != Start)
							{
								if(UpValue > 0.0)
								{
									for(new Float:x = Start; x < v; x += FloatAbs(UpValue))
										{Count++;}
								}
								else if(UpValue < 0.0)
								{
									for(new Float:x = Start; x > v; x -= FloatAbs(UpValue))
									{
										{Count++;}
									}
								}
							}
						}
						SetArrayCell(StatsBought, client, Count, i + (MAX_ATTRIBS*j));
					}
				}
			}
		}
	}
}

// Function: Load Stats
LoadStats(client)
{
	if(IsClientInGame(client))
	{
		if(!IsFakeClient(client))
		{
			new String:FullBuffer[2048], String:Buffers[5][2048], String:SubBuffers[4][512], String:Value[5][128];
			new TFClassType:Class = TF2_GetPlayerClass(client), String:info[256];
			for(new i=0; i<MAX_ATTRIBS; i++)
			{
				for(new j=0; j<3; j++)
				{
					info = "";
					switch(j)
					{
						case 0:{GetArrayString(StatsClass, i, FullBuffer, sizeof(FullBuffer));}
						case 1:{GetArrayString(StatsWeapon, i, FullBuffer, sizeof(FullBuffer));}
						case 2:{GetArrayString(StatsCustom, i, FullBuffer, sizeof(FullBuffer));}
					}
					ExplodeString(FullBuffer, "|", Buffers, 5, 2048, false);
					for(new k=0; k<5; k++)
					{
						new WepFound = false;
						ExplodeString(Buffers[k], ">", SubBuffers, 4, 512, false);
						switch(j)
						{
							case 0:
							{
								if(Class == TF2_GetClass(SubBuffers[0]))
								{
									strcopy(info, sizeof(info), SubBuffers[1]);
									strcopy(Value[k], 128, SubBuffers[3]);
									continue;
								}
							}
							
							case 1:
							{
								for(new l=0; l<=5; l++)
								{
									Slot[client] = -1;
									if(l < 5)
									{
										Slot[client] = GetPlayerWeaponSlot(client, l);
										if(Slot[client] < 0)
										{
											switch(l)
											{
												case 0:
												{
													while((Slot[client] = FindEntityByClassname(Slot[client], "tf_wearable")) != -1)
													{
														new idx = GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex");
														if((idx == 405 || idx == 608) && GetEntPropEnt(Slot[client], Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(Slot[client], Prop_Send, "m_bDisguiseWearable"))
															{break;}
													}
												}
												
												case 1:
												{
													while((Slot[client] = FindEntityByClassname(Slot[client], "tf_wearable")) != -1)
													{
														new idx = GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex");
														if((idx == 405 || idx == 608 || idx == 57 || idx == 231 || idx == 642) && GetEntPropEnt(Slot[client], Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(Slot[client], Prop_Send, "m_bDisguiseWearable"))
															{break;}
													}
													
													if(Slot[client] == -1)
													{
														while((Slot[client] = FindEntityByClassname(Slot[client], "tf_wearable_demoshield")) != -1)
														{
															new idx = GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex");
															if((idx == 131 || idx == 406 || idx == 1099) && GetEntPropEnt(Slot[client], Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(Slot[client], Prop_Send, "m_bDisguiseWearable"))
																{break;}
														}
													}
												}
											}
										}
										
										if(IsValidEntity(Slot[client]))
										{
											new String:WeaponList[512][8], String:SlotID[8];
											IntToString(GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex"), SlotID, sizeof(SlotID));
											ExplodeString(SubBuffers[0], " ; ", WeaponList, 512, 8, false);
											for(new m=0; m<256; m++)
											{
												if(StrEqual(WeaponList[m], SlotID))
												{
													strcopy(info, sizeof(info), SubBuffers[1]);
													strcopy(Value[k], 512, SubBuffers[3]);
													WepFound = true;
													break;
												}
											}
										}
									}
									else
									{
										if(Slot[client] == -1)
										{
											while((Slot[client] = FindEntityByClassname(Slot[client], "tf_powerup_bottle")) != -1)
											{
												new idx = GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex");
												if((idx == 489 || idx == 1163 || idx == 30015 || idx == 30535) && GetEntPropEnt(Slot[client], Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(Slot[client], Prop_Send, "m_bDisguiseWearable"))
													{break;}
											}
											
											if(IsValidEntity(Slot[client]))
											{
												new String:WList[256][8], String:SlotID[8];
												IntToString(GetEntProp(Slot[client], Prop_Send, "m_iItemDefinitionIndex"), SlotID, sizeof(SlotID));
												ExplodeString(SubBuffers[0], " ; ", WList, 256, 8, false);
												for(new m=0; m<256; m++)
												{
													if(StrEqual(WList[m], SlotID))
													{
														strcopy(info, sizeof(info), SubBuffers[1]);
														strcopy(Value[k], 512, SubBuffers[3]);
														WepFound = true;
														break;
													}
												}
											}
										}
									}
									if(WepFound){break;}
								}
								if(WepFound){continue;}
							}
							
							case 2:
							{
								if(StrEqual(SubBuffers[1], "custom"))
								{
									strcopy(info, sizeof(info), SubBuffers[1]);
									strcopy(Value[k], 512, SubBuffers[3]);
									continue;
								}
							}
						}
					}
					
					if(strlen(info) > 0)
					{
						new Float:Start, Ent, Count = 0, Float:UpValue = StringToFloat(Value[2]);
						Start = StringToFloat(Value[4]);
						Count = GetArrayCell(StatsBought, client, i + (MAX_ATTRIBS*j));
						switch(j)
						{
							case 0,2:{Ent = client;}
							case 1:{Ent = Slot[client];}
						}
						
						if(Ent == -1)
						{
							continue;
						}
						
						if(j < 2)
						{
							new String:NAME[128];
							GetEntityClassname(Ent, NAME, sizeof(NAME));
							
							if(StrEqual(NAME, "tf_powerup_bottle") && (StrEqual(info, "building instant upgrade") || StrEqual(info, "critboost") ||
							StrEqual(info, "ubercharge") || StrEqual(info, "refill_ammo") || StrEqual(info, "recall")))
							{
								TF2Attrib_RemoveByName(Ent, "ubercharge");
								TF2Attrib_RemoveByName(Ent, "critboost");
								TF2Attrib_RemoveByName(Ent, "recall");
								TF2Attrib_RemoveByName(Ent, "refill_ammo");
								TF2Attrib_RemoveByName(Ent, "building instant upgrade");
								SetEntProp(Ent, Prop_Send, "m_usNumCharges", RoundToFloor(Start + (UpValue * float(Count))));
							}
							
							if(Count != 0)
							{
								TF2Attrib_SetByName(Ent, info, Start + (UpValue * float(Count)));
							}
							else
							{
								TF2Attrib_RemoveByName(Ent, info);
							}
						}
						else
						{
							new Float:v = Start + (UpValue * float(Count));
							SetCustomValue(client, info, any:v);
						}
					}
				}
			}
		}
	}
}
*/

// Timer: Redisplay Menu
public Action:t_RedisplayMenu(Handle:timer, any:client)
{
	if(IsPlayerAlive(client))
	{
		new Handle:M = INVALID_HANDLE;
		M = CreateMenu(Menu_UpgradeShop);
		DisplayMenu(M, client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}

// Timer: Redisplay Menu
public Action:t_RedisplayShop(Handle:timer, any:client)
{
	if(IsPlayerAlive(client))
	{
		CreateShopPanel(client);
	}
	
	return Plugin_Handled;
}