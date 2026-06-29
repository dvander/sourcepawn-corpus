// ---- Preprocessor -----------------------------------------------------------
#pragma semicolon 1 

// ---- Includes ---------------------------------------------------------------
#include <sourcemod>
#include <morecolors>
#include <tf2_stocks>
#include <tf2items>
#include <steamtools>
#include <clientprefs>

// ---- Defines ----------------------------------------------------------------
#define DR_VERSION "0.1.5"
#define PLAYERCOND_SPYCLOAK (1<<4)
#define RUNNER_SPEED 300.0
#define DEATH_SPEED 400.0
#define MELEE_NUMBER 10
new melee_vec[] =  {264 ,423 ,474, 880, 939, 954, 1013, 1071, 1123, 1127};
// Frying Pan, Saxxy, The Conscientious Objector, The Freedom Staff, The Bat Outta Hell, The Memory Maker, The Ham Shank, Gold Frying Pan, The Necro Smasher, The Crossing Guard
#define DBD_UNDEF -1 //DBD = Don't Be Death
#define DBD_OFF 1
#define DBD_ON 2
#define DBD_THISMAP 3 // The cookie will never have this value
#define TIME_TO_ASK 30.0 //Delay between asking the client its preferences and it's connection/join.

// ---- Variables --------------------------------------------------------------
new bool:g_isDRmap = false;
new g_lastdeath = -1;
new g_timesplayed_asdeath[MAXPLAYERS+1];
new bool:g_onPreparation = false;
new g_dontBeDeath[MAXPLAYERS+1] = {DBD_UNDEF,...};

// ---- Handles ----------------------------------------------------------------
new Handle:g_DRCookie = INVALID_HANDLE;

// ---- Plugin's CVars Management ----------------------------------------------
new g_Enabled;
new g_Outlines;
new g_MeleeOnly;
new g_MeleeType;

new Handle:dr_Enabled;
new Handle:dr_Outlines;
new Handle:dr_MeleeOnly;
new Handle:dr_MeleeType;

// ---- Server's CVars Management ----------------------------------------------
new Handle:dr_queue;
new Handle:dr_unbalance;
new Handle:dr_autobalance;
new Handle:dr_firstblood;
new Handle:dr_scrambleauto;
new Handle:dr_airdash;
new Handle:dr_push;

new dr_queue_def = 0;
new dr_unbalance_def = 0;
new dr_autobalance_def = 0;
new dr_firstblood_def = 0;
new dr_scrambleauto_def = 0;
new dr_airdash_def = 0;
new dr_push_def = 0;

// ---- Plugin's Information ---------------------------------------------------
public Plugin:myinfo =
{
	name = "[TF2] Deathrun Redux",
	author = "Classic",
	description	= "Deathrun plugin for TF2",
	version = DR_VERSION,
	url = "http://www.clangs.com.ar"
};

/* OnPluginStart()
**
** When the plugin is loaded.
** -------------------------------------------------------------------------- */
public OnPluginStart()
{
	//Cvars
	CreateConVar("sm_dr_version", DR_VERSION, "Death Run Redux Version.", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	dr_Enabled = CreateConVar("sm_dr_enabled",	"1", "Enables / Disables the Death Run Redux plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	dr_Outlines = CreateConVar("sm_dr_outlines",	"1", "Enables / Disables ability to players from runners team be seen throught walls by outline", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	dr_MeleeOnly = CreateConVar("sm_dr_melee_only",	"1", "Enables / Disables the exclusive use of melee weapons",FCVAR_PLUGIN, true, 0.0, true, 1.0);
	dr_MeleeType = CreateConVar("sm_dr_melee_type",	"1", "Type of melee restriction. 0: No restriction. 1: Gives default weapon to player's class.\n2: Gives all-class weapons. Only works if sm_dr_melee_only is in 1.",FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	//Defaults variables values
	g_Enabled = GetConVarInt(dr_Enabled);
	g_Outlines = GetConVarInt(dr_Outlines);
	g_MeleeOnly = GetConVarInt(dr_MeleeOnly);
	g_MeleeType = GetConVarInt(dr_MeleeType);
	
	//Server's Cvars
	dr_queue = FindConVar("tf_arena_use_queue");
	dr_unbalance = FindConVar("mp_teams_unbalance_limit");
	dr_autobalance = FindConVar("mp_autoteambalance");
	dr_firstblood = FindConVar("tf_arena_first_blood");
	dr_scrambleauto = FindConVar("mp_scrambleteams_auto");
	dr_airdash = FindConVar("tf_scout_air_dash_count");
	dr_push = FindConVar("tf_avoidteammates_pushaway");
	
	//Cvars's hook
	HookConVarChange(dr_Enabled, OnCVarChange);
	HookConVarChange(dr_Outlines, OnCVarChange);
	HookConVarChange(dr_MeleeOnly, OnCVarChange);
	HookConVarChange(dr_MeleeType, OnCVarChange);

	//Hooks
	HookEvent("teamplay_round_start", OnPrepartionStart);
	HookEvent("arena_round_start", OnRoundStart); 
	HookEvent("post_inventory_application", OnPlayerInventory);
	HookEvent("player_spawn", OnPlayerSpawn);
	
	AddCommandListener(Command_Block,"build");
	AddCommandListener(Command_Block,"kill");
	AddCommandListener(Command_Block,"explode");
	
	AutoExecConfig(true, "plugin.deathrun_redux");
	
	//Preferences
	g_DRCookie = RegClientCookie("DR_dontBeDeath", "Does the client want to be the Deaht?", CookieAccess_Private);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!AreClientCookiesCached(i))
			continue;
		OnClientCookiesCached(i);
	}
	RegConsoleCmd( "drtoggle",  BeDeathMenu);
}

/* OnPluginEnd()
**
** When the plugin is unloaded. Here we reset all the cvars to their normal value.
** -------------------------------------------------------------------------- */
public OnPluginEnd()
{
	ResetCvars();
}

/* OnCVarChange()
**
** We edit the global variables values when their corresponding cvar changes.
** -------------------------------------------------------------------------- */
public OnCVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == dr_Enabled) 
		g_Enabled = GetConVarInt(dr_Enabled);
	else if(convar == dr_Outlines) 
		g_Outlines = GetConVarInt(dr_Outlines);
	else if(convar == dr_MeleeOnly) 
		g_MeleeOnly = GetConVarInt(dr_MeleeOnly);
	else if(convar == dr_MeleeType) 
		g_MeleeType = GetConVarInt(dr_MeleeType);
}

/* OnMapStart()
**
** Here we reset every global variable, and we check if the current map is a deathrun map.
** If it is a dr map, we get the cvars def. values and the we set up our own values.
** -------------------------------------------------------------------------- */
public OnMapStart()
{
	g_lastdeath = -1;
	for(new i = 1; i <= MaxClients; i++)
			g_timesplayed_asdeath[i]=-1;
			
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if (g_Enabled && (strncmp(mapname, "dr_", 3, false) == 0 || (strncmp(mapname, "deathrun_", 9, false) == 0) || (strncmp(mapname, "vsh_dr", 6, false) == 0) || (strncmp(mapname, "vsh_deathrun", 6, false) == 0)))
	{
		LogMessage("Deathrun map detected. Enabling Deathrun Gamemode.");
		g_isDRmap = true;
		Steam_SetGameDescription("DeathRun Redux");
		AddServerTag("deathrun");
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!AreClientCookiesCached(i))
				continue;
			OnClientCookiesCached(i);
		}
	}
 	else
	{
		LogMessage("Current map is not a deathrun map. Disabling Deathrun Gamemode.");
		g_isDRmap = false;
		Steam_SetGameDescription("Team Fortress");	
		RemoveServerTag("deathrun");
	}
}

/* OnMapEnd()
**
** Here we reset the server's cvars to their default values.
** -------------------------------------------------------------------------- */
public OnMapEnd()
{
	ResetCvars();
	for (new i = 1; i <= MaxClients; i++)
	{
		g_dontBeDeath[i] = DBD_UNDEF;
	}
}

/* OnClientPutInServer()
**
** We set on zero the time played as death when the client enters the server.
** -------------------------------------------------------------------------- */
public OnClientPutInServer(client)
{
	g_timesplayed_asdeath[client] = 0;
}

/* OnClientDisconnect()
**
** We set as minus one the time played as death when the client leaves.
** When searching for a Death we ignore every client with the -1 value.
** We also set as undef the preference value
** -------------------------------------------------------------------------- */
public OnClientDisconnect(client)
{
	g_timesplayed_asdeath[client] =-1;
	g_dontBeDeath[client] = DBD_UNDEF;
}

/* OnClientCookiesCached()
**
** We look if the client have a saved value
** -------------------------------------------------------------------------- */
public OnClientCookiesCached(client)
{
	decl String:sValue[8];
	GetClientCookie(client, g_DRCookie, sValue, sizeof(sValue));
	new nValue = StringToInt(sValue);

	if( nValue != DBD_OFF && nValue != DBD_ON) //If cookie is not valid we ask for a preference.
		CreateTimer(TIME_TO_ASK, AskMenuTimer, client);
	else //client has a valid cookie
		g_dontBeDeath[client] = nValue;
}

public Action:AskMenuTimer(Handle:timer, any:client)
{
	BeDeathMenu(client,0);
}

public Action:BeDeathMenu(client,args)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return Plugin_Handled;
	}
	new Handle:menu = CreateMenu(BeDeathMenuHandler);
	SetMenuTitle(menu, "Be the Death toggle");
	AddMenuItem(menu, "0", "Select me as Death");
	AddMenuItem(menu, "1", "Don't select me as Death");
	AddMenuItem(menu, "2", "Don't be Death in this map");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
	
	return Plugin_Handled;
}

public BeDeathMenuHandler(Handle:menu, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Select)
	{
		if (buttonnum == 0)
		{
			g_dontBeDeath[client] = DBD_OFF;
			decl String:sPref[2];
			IntToString(DBD_OFF, sPref, sizeof(sPref));
			SetClientCookie(client, g_DRCookie, sPref);
			CPrintToChat(client,"{black}[DR]{DEFAULT} You can be selected as Death.");
		}
		else if (buttonnum == 1)
		{
			g_dontBeDeath[client] = DBD_ON;
			decl String:sPref[2];
			IntToString(DBD_ON, sPref, sizeof(sPref));
			SetClientCookie(client, g_DRCookie, sPref);
			CPrintToChat(client,"{black}[DR]{DEFAULT} You can't be selected as Death.");
		}
		else if (buttonnum == 2)
		{
			g_dontBeDeath[client] = DBD_THISMAP;
			CPrintToChat(client,"{black}[DR]{DEFAULT} You can't be selected as Death for this map.");
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/* OnPrepartionStart()
**
** We setup the cvars again, balance the teams and we freeze the players.
** -------------------------------------------------------------------------- */
public Action:OnPrepartionStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_Enabled && g_isDRmap)
	{
		g_onPreparation = true;
		
		//We force the cvars values needed every round (to override if any cvar was changed).
		SetupCvars();
		
		//We move the players to the corresponding team.
		BalanceTeams();
		
		//Players shouldn't move until the round starts
		for(new i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i) && IsPlayerAlive(i))
				SetEntityMoveType(i, MOVETYPE_NONE);	

	}
}

/* OnRoundStart()
**
** We unfreeze every player.
** -------------------------------------------------------------------------- */
public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_Enabled && g_isDRmap)
	{
		for(new i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i) && IsPlayerAlive(i))
					SetEntityMoveType(i, MOVETYPE_WALK);
		g_onPreparation = false;
	}
}

/* TF2Items_OnGiveNamedItem_Post()
**
** Here we check for the demoshield and the sapper.
** -------------------------------------------------------------------------- */
public TF2Items_OnGiveNamedItem_Post(client, String:classname[], index, level, quality, ent)
{
	if(g_isDRmap && g_Enabled)
	{
		//tf_weapon_builder tf_wearable_demoshield
		if(StrEqual(classname,"tf_weapon_builder", false) || StrEqual(classname,"tf_wearable_demoshield", false))
			CreateTimer(0.1, Timer_RemoveWep, EntIndexToEntRef(ent));  
	}
}

/* Timer_RemoveWep()
**
** We kill the demoshield/sapper
** -------------------------------------------------------------------------- */
public Action:Timer_RemoveWep(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if( IsValidEntity(ent) && ent > MaxClients)
		AcceptEntityInput(ent, "Kill");
}  

/* OnPlayerInventory()
**
** Here we strip players weapons (if we have to).
** Also we give special melee weapons (again, if we have to).
** -------------------------------------------------------------------------- */
public Action:OnPlayerInventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_Enabled && g_isDRmap)
	{
		if(g_MeleeOnly)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Grenade);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Building);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_PDA);
			
			//We kill the demomen's shield on this preparation.
			/*new ent = -1;
			while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1)
			{
				AcceptEntityInput(ent, "kill");
			}*/
			if(g_MeleeType != 0)
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				new Handle:hItem = TF2Items_CreateItem(FORCE_GENERATION | OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);
				
				if(g_MeleeType == 1)
				{
					//Here we give the default melee to every class
					new TFClassType:iClass = TF2_GetPlayerClass(client);
					switch(iClass)
					{
						case TFClass_Scout:{
							TF2Items_SetClassname(hItem, "tf_weapon_bat");
							TF2Items_SetItemIndex(hItem, 190);
							}
						case TFClass_Sniper:{
							TF2Items_SetClassname(hItem, "tf_weapon_club");
							TF2Items_SetItemIndex(hItem, 193);
							}
						case TFClass_Soldier:{
							TF2Items_SetClassname(hItem, "tf_weapon_shovel");
							TF2Items_SetItemIndex(hItem, 196);
							}
						case TFClass_DemoMan:{
							TF2Items_SetClassname(hItem, "tf_weapon_bottle");
							TF2Items_SetItemIndex(hItem, 191);
							}
						case TFClass_Medic:{
							TF2Items_SetClassname(hItem, "tf_weapon_bonesaw");
							TF2Items_SetItemIndex(hItem, 198);
							}
						case TFClass_Heavy:{
							TF2Items_SetClassname(hItem, "tf_weapon_fists");
							TF2Items_SetItemIndex(hItem, 195);
							}
						case TFClass_Pyro:{
							TF2Items_SetClassname(hItem, "tf_weapon_fireaxe");
							TF2Items_SetItemIndex(hItem, 192);
							}
						case TFClass_Spy:{
							TF2Items_SetClassname(hItem, "tf_weapon_knife");
							TF2Items_SetItemIndex(hItem, 194);
							}
						case TFClass_Engineer:{
							TF2Items_SetClassname(hItem, "tf_weapon_wrench");
							TF2Items_SetItemIndex(hItem, 197);
							}
					}
				}
				else if(g_MeleeType == 2)
				{
					//Here we give a random all-class wep to the client
					TF2Items_SetClassname(hItem, "tf_weapon_club");
					TF2Items_SetItemIndex(hItem, melee_vec[GetRandomInt(0, MELEE_NUMBER-1)]);
				}				
				TF2Items_SetLevel(hItem, 69);
				TF2Items_SetQuality(hItem, 6);
				TF2Items_SetAttribute(hItem, 0, 150, 1.0); //Turn to gold on kill
				TF2Items_SetAttribute(hItem, 1, 542, 1.0); //Override Item Style
				TF2Items_SetAttribute(hItem, 2, 2027, 1.0); //Is Australium Item
				TF2Items_SetAttribute(hItem, 3, 2022, 1.0); //Loot Rarity
				TF2Items_SetNumAttributes(hItem, 4);
				
				new iWeapon = TF2Items_GiveNamedItem(client, hItem);
				CloseHandle(hItem);
				EquipPlayerWeapon(client, iWeapon);
				TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
			}
		}
	}
}

/* OnPlayerSpawn()
**
** Here we enable the glow (if we need to), we set the spy cloak and we move the death player.
** -------------------------------------------------------------------------- */
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_Enabled && g_isDRmap)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetClientTeam(client) == 2)
		{
			if(g_Outlines)
			{
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
			}
		}
		new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
		
		if (cond & PLAYERCOND_SPYCLOAK)
		{
			SetEntProp(client, Prop_Send, "m_nPlayerCond", cond | ~PLAYERCOND_SPYCLOAK);
		}
		
		if(GetClientTeam(client) == 3 && client != g_lastdeath)
		{
			ChangeClientTeam(client, 2);
			CreateTimer(0.2, RespawnRebalanced,  GetClientUserId(client));
		}
		
		if(g_onPreparation)
			SetEntityMoveType(client, MOVETYPE_NONE);	
		
	}
}


/* BalanceTeams()
**
** Moves players to their new team in this round.
** -------------------------------------------------------------------------- */
stock BalanceTeams()
{
	if(GetClientCount(true) > 1)
	{
		new new_death = GetRandomValid();
		if(new_death == -1)
		{
			CPrintToChatAll("{black}[DR]{DEFAULT} Couldn't found a valid Death.");
			return;
		}
		g_lastdeath  = new_death;
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsClientConnected(i))
			{
				if(i == new_death)
				{
					if(GetClientTeam(i) != 3)
					ChangeClientTeam(i, 3);
					
					new TFClassType:iClass = TF2_GetPlayerClass(i);
					if (iClass == TFClass_Unknown)
					{
						TF2_SetPlayerClass(i, TFClass_Scout, false, true);
					}
				}
				else if(GetClientTeam(i) != 2 )
				{
					ChangeClientTeam(i, 2);
				}
				CreateTimer(0.2, RespawnRebalanced,  GetClientUserId(i));
			}
		}
		if(!IsClientConnected(new_death) || !IsClientInGame(new_death)) 
		{
			CPrintToChatAll("{black}[DR]{DEFAULT} Death isn't in game.");
			return;
		}
		
		CPrintToChatAll("{black}[DR]{gold}%N {DEFAULT}is the Death", new_death);
		g_timesplayed_asdeath[g_lastdeath]++;

	}
	else
	{
		CPrintToChatAll("{black}[DR]{DEFAULT} This game-mode requires at least two people to start");
	}
}

/* GetRandomValid()
**
** Gets a random player that didn't play as death recently.
** -------------------------------------------------------------------------- */
public GetRandomValid()
{
	new possiblePlayers[MAXPLAYERS+1];
	new possibleNumber = 0;
	
	new min = GetMinTimesPlayed(false);
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i))
			continue;
		if(g_timesplayed_asdeath[i] != min)
			continue;
		if(g_dontBeDeath[i] == DBD_ON || g_dontBeDeath[i] == DBD_THISMAP)
			continue;
		
		possiblePlayers[possibleNumber] = i;
		possibleNumber++;
		
	}
	
	//If there are zero people available we ignore the preferences.
	if(possibleNumber == 0)
	{
		min = GetMinTimesPlayed(true);
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i))
				continue;
			if(g_timesplayed_asdeath[i] != min)
				continue;			
			possiblePlayers[possibleNumber] = i;
			possibleNumber++;
		}
		if(possibleNumber == 0)
			return -1;
	}
	
	return possiblePlayers[ GetRandomInt(0,possibleNumber-1)];

}

/* GetMinTimesPlayed()
**
** Get the minimum "times played", if ignorePref is true, we ignore the don't be death preference
** -------------------------------------------------------------------------- */
GetMinTimesPlayed(bool:ignorePref)
{
	new min = -1;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i) || g_timesplayed_asdeath[i] == -1) 
			continue;
		if(i == g_lastdeath) 
			continue;
		if(!ignorePref)
			if(g_dontBeDeath[i] == DBD_ON || g_dontBeDeath[i] == DBD_THISMAP)
				continue;
		if(min == -1)
			min = g_timesplayed_asdeath[i];
		else
			if(min > g_timesplayed_asdeath[i])
				min = g_timesplayed_asdeath[i];
		
	}
	return min;

}

/* OnGameFrame()
**
** We set the player max speed on every frame, and also we set the spy's cloak on empty.
** -------------------------------------------------------------------------- */
public OnGameFrame()
{
	if(g_Enabled && g_isDRmap)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(GetClientTeam(i) == 2 )
				{
					SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", RUNNER_SPEED);
				}
				else if(GetClientTeam(i) == 3)
				{
					SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", DEATH_SPEED);
				}
				if(TF2_GetPlayerClass(i) == TFClass_Spy)
				{
					SetCloak(i, 1.0);
				}
			}
		}
	}
}

/* TF2_SwitchtoSlot()
**
** Changes the client's slot to the desired one.
** -------------------------------------------------------------------------- */
stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

/* SetCloak()
**
** Function used to set the spy's cloak meter.
** -------------------------------------------------------------------------- */
stock SetCloak(client, Float:value)
{
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", value);
}

/* RespawnRebalanced()
**
** Timer used to spawn a client if he/she is in game and if it isn't alive.
** -------------------------------------------------------------------------- */
public Action:RespawnRebalanced(Handle:timer, any:data)
{
	new client = GetClientOfUserId(data);
	if(IsClientInGame(client))
	{
		if(!IsPlayerAlive(client))
		{
			TF2_RespawnPlayer(client);
		}
	}
}

/* OnConfigsExecuted()
**
** Here we get the default values of the CVars that the plugin is going to modify.
** -------------------------------------------------------------------------- */
public OnConfigsExecuted()
{
	if(g_Enabled)
	{
		dr_queue_def= GetConVarInt(dr_queue);
		dr_unbalance_def = GetConVarInt(dr_unbalance);
		dr_autobalance_def = GetConVarInt(dr_autobalance);
		dr_firstblood_def = GetConVarInt(dr_firstblood);
		dr_scrambleauto_def = GetConVarInt(dr_scrambleauto);
		dr_airdash_def = GetConVarInt(dr_airdash);
		dr_push_def = GetConVarInt(dr_push);
	}
}

/* SetupCvars()
**
** Modify several values of the CVars that the plugin needs to work properly.
** -------------------------------------------------------------------------- */
public SetupCvars()
{
	SetConVarInt(dr_queue, 0);
	SetConVarInt(dr_unbalance, 0);
	SetConVarInt(dr_autobalance, 0);
	SetConVarInt(dr_firstblood, 0);
	SetConVarInt(dr_scrambleauto, 0);
	SetConVarInt(dr_airdash, 0);
	SetConVarInt(dr_push, 0);
}

/* ResetCvars()
**
** Reset the values of the CVars that the plugin used to their default values.
** -------------------------------------------------------------------------- */
public ResetCvars()
{
	SetConVarInt(dr_queue, dr_queue_def);
	SetConVarInt(dr_unbalance, dr_unbalance_def);
	SetConVarInt(dr_autobalance, dr_autobalance_def);
	SetConVarInt(dr_firstblood, dr_firstblood_def);
	SetConVarInt(dr_scrambleauto, dr_scrambleauto_def);
	SetConVarInt(dr_airdash, dr_airdash_def);
	SetConVarInt(dr_push, dr_push_def);
}

/* Command_Block()
**
** Blocks a command
** -------------------------------------------------------------------------- */
public Action:Command_Block(client, const String:command[], argc)
{
	if(g_isDRmap && g_Enabled)
		return Plugin_Stop;
	return Plugin_Continue;
}