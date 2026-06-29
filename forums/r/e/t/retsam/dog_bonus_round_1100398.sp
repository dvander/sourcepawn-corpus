//
// SourceMod Script
//
// Developed by <eVa>Dog (Custom version (1.12) by: retsam)
// June 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// For Day of Defeat Source only
// This plugin changes losing teams into random objects
// at Round End, to help them escape from the enemy
//
// CHANGELOG:
// See SourceMod forums for changelog

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.12"
#define MAXMODELS 26

#define INVIS					{255,255,255,0}
#define NORMAL					{255,255,255,255}

new Handle:Cvar_AdminFlag = INVALID_HANDLE;
new Handle:Cvar_AdminOnly = INVALID_HANDLE;
new Handle:Cvar_ThirdTriggers = INVALID_HANDLE;
new Handle:Cvar_ThirdPerson = INVALID_HANDLE;
new Handle:Cvar_Enabled = INVALID_HANDLE;
new Handle:Cvar_HitRemoveProp = INVALID_HANDLE;
new Handle:Cvar_ForceThird = INVALID_HANDLE;

new g_adminonlyCvar;
new g_thirdpersonCvar;
new g_hitremovePropCvar;
new g_forcethirdCvar;
new g_AxisModel;
new g_AlliedModel;
new g_InThirdperson[MAXPLAYERS+1] = { 0, ... };
new g_IsAProp[MAXPLAYERS+1] = { 0, ... };

new bool:bIsPlayerAdmin[MAXPLAYERS + 1] = {false, ...};
new bool:IsEnabled = true;
new bool:BonusRound = false;

new String:g_sCharAdminFlag[32];

//Create the bonus round models
new String: g_modelname[][] = {
	"models/props_foliage/shrub_01a.mdl",
	"models/props_foliage/flower_barrel.mdl",
	"models/props_foliage/potted_plant2.mdl",
	"models/props_crates/static_crate_64.mdl",
	"models/props_crates/woodbarrel001.mdl",
	"models/props_italian/wagon.mdl",
	"models/props_furniture/bathtub1.mdl",
	"models/props_fortifications/sandbags_corner1.mdl",
	"models/props_urban/phonepole1.mdl",
	"models/props_urban/patio_table2.mdl",
	"models/props_furniture/piano.mdl",
	"models/props_furniture/bathtub1.mdl",
	"models/props_foliage/hedge_small.mdl",
	"models/props_urban/light_streetlight.mdl",
	"models/props_combine/breenchair.mdl",
	"models/props_furniture/chairantique.mdl",
	"models/props_misc/claypot02.mdl",
	"models/props_crates/tnt_crate1.mdl",
	"models/props_foliage/shrub_small.mdl",
	"models/props_fortifications/hedgehog_small1.mdl",
	"models/props_foliage/rock_riverbed02c.mdl",
	"models/props_furniture/dresser1.mdl",
	"models/props_urban/bench_wood.mdl",
	"models/props_italian/anzio_market_table1.mdl",
	"models/props_italian/anzio_fountain.mdl",
	"models/props_fortifications/sandbags_line2_tall.mdl"
};

new String:g_modeltext[][] = {
	"Shrub",
	"Flower barrel",
	"Potted flowers",
	"Crate",
	"Wooden barrel",
	"Wagon",
	"Bathtub",
	"Sandbags curved",
	"Phone pole",
	"Patio table set",
	"Piano",
	"Bathtub",
	"Small hedge",
	"Street lamp",
	"Office chair",
	"Chair",
	"Clay Pot",
	"Tnt crate",
	"Small shrub",
	"Hedgehog",
	"Group of rocks",
	"Dresser",
	"Bench",
	"Market table",
	"Fountain",
	"Sandbags straight"
};

new g_modelindex[MAXMODELS + 1];

public Plugin:myinfo = 
{
	name = "Dog's Prop Bonus Round",
	author = "<eVa>Dog (edited by: retsam)",
	description = "The losing team turn into different models to hide during the bonus round!",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CheckGame();

	CreateConVar("dog_bonus_round", PLUGIN_VERSION, "Version of dog_bonus_round", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_Enabled = CreateConVar("sm_propbonus_enabled", "1", "Enable/Disable prop bounus round plugin.");
	Cvar_AdminOnly = CreateConVar("sm_propbonus_adminonly", "0", "Enable plugin for admins only? (1/0 = yes/no)");
	Cvar_AdminFlag = CreateConVar("sm_propbonus_flag", "b", "Admin flag to use if adminonly is enabled (only one).  Must be a in char format.");
	Cvar_ThirdPerson = CreateConVar("sm_propbonus_allowtriggers", "1", "Allow player controlled thirdperson triggers for prop players?(1/0 = yes/no)");
	Cvar_HitRemoveProp = CreateConVar("sm_propbonus_removeproponhit", "0", "Remove player prop once they take damage?(1/0 = yes/no)");
	Cvar_ForceThird = CreateConVar("sm_propbonus_forcethird", "0", "Force thirdperson on prop players during bonus round?(1/0 = yes/no)");
	Cvar_ThirdTriggers = CreateConVar("sm_propbonus_triggers", "thirdperson,third", "SM command triggers for thirdperson - Separated by commas. Each will have the !third, /third, sm_third associated with it.");

	HookEvent("dod_round_start", Hook_RoundStart);
	HookEvent("dod_round_win", Hook_RoundWin);
	HookEvent("player_death", Hook_Playerdeath, EventHookMode_Post);
	HookEvent("player_hurt", Hook_PlayerHurt, EventHookMode_Pre);
	
	HookConVarChange(Cvar_Enabled, Cvars_Changed);
	HookConVarChange(Cvar_ThirdPerson, Cvars_Changed);
	HookConVarChange(Cvar_HitRemoveProp, Cvars_Changed);
	HookConVarChange(Cvar_ForceThird, Cvars_Changed);
	HookConVarChange(Cvar_AdminOnly, Cvars_Changed);
	
	CreateThirdpersonCommands();

	AutoExecConfig(true, "plugin.propbonusround");
}

public OnClientPostAdminCheck(client)
{
	if(IsValidAdmin(client, g_sCharAdminFlag))
	{
		bIsPlayerAdmin[client] = true;
	}
	else
	{
		bIsPlayerAdmin[client] = false;
	}

	g_InThirdperson[client] = 0;
	g_IsAProp[client] = 0;
}

public OnConfigsExecuted()
{
	BonusRound = false;

	IsEnabled = GetConVarBool(Cvar_Enabled);
	GetConVarString(Cvar_AdminFlag, g_sCharAdminFlag, sizeof(g_sCharAdminFlag));

	g_thirdpersonCvar = GetConVarInt(Cvar_ThirdPerson);
	g_hitremovePropCvar = GetConVarInt(Cvar_HitRemoveProp);
	g_forcethirdCvar = GetConVarInt(Cvar_ForceThird);
	g_adminonlyCvar = GetConVarInt(Cvar_AdminOnly);
}

public OnMapStart()
{
	for (new x = 0; x < MAXMODELS; x++)
	{
		g_modelindex[x] = PrecacheModel(g_modelname[x], true);
		PrintToServer("Cached: %s with number %i", g_modelname[x], g_modelindex[x]);
	}
	
	g_AxisModel = PrecacheModel("models/player/german_support.mdl", true);
	g_AlliedModel = PrecacheModel("models/player/american_support.mdl", true);
}

public OnClientDisconnect(client)
{
	g_InThirdperson[client] = 0;
	g_IsAProp[client] = 0;
}

public Action:Hook_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new x = 1; x <= MaxClients; x++)
	{
		if(!IsClientConnected(x) || !IsClientInGame(x))
		{
			continue;
		}
		
		if(g_IsAProp[x] == 1)
		{
			ColorizeWeapons(x, NORMAL);
			g_IsAProp[x] = 0;
			
			if(g_InThirdperson[x] == 1)
			SwitchView(x);
		}
	}
	
	BonusRound = false;
}

public Action:Hook_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!BonusRound || !g_hitremovePropCvar)
	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client <= 0)
	return Plugin_Continue;

	if(g_IsAProp[client] != 1)
	return Plugin_Continue;

	new team = GetClientTeam(client);
	new offset = FindSendPropOffs("CBaseEntity", "m_nModelIndex");

	if(team == 2)
	{
		SetEntData(client, offset, g_AlliedModel, 4, true);
	}
	else
	{
		SetEntData(client, offset, g_AxisModel, 4, true);
	}
	ColorizeWeapons(client, NORMAL);
	g_IsAProp[client] = 0;
	SetEntityRenderColor(client, 255, 255, 255, 255);

	if(g_InThirdperson[client] == 1)
	{
		SwitchView(client);
	}

	return Plugin_Continue;
}

public Action:Hook_Playerdeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!BonusRound)
	return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client <= 0)
	return Plugin_Continue;

	if(g_IsAProp[client] == 1)
	{
		ColorizeWeapons(client, NORMAL);
		g_IsAProp[client] = 0;
		
		if(g_InThirdperson[client] == 1)
		g_InThirdperson[client] = 0;
	}

	return Plugin_Continue;
}

public Action:Hook_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	BonusRound = true;

	new winnerTeam = GetEventInt(event, "team");
	new choice;
	new offset;
	//new slot;
	//new weaponslot;
	
	for (new x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x) || !IsPlayerAlive(x))
		{
			continue;
		}
		
		if(GetClientTeam(x) == winnerTeam)
		{
			continue;
		}
		
		if((g_adminonlyCvar && !bIsPlayerAdmin[x]))
		{
			continue;
		}
		
		/*
	for(slot = 0; slot < 5; slot++)
	{
	weaponslot = GetPlayerWeaponSlot(x, slot);
	if(weaponslot != -1)
	{
		RemovePlayerItem(x, weaponslot);
	}
	}
	*/
		
		g_IsAProp[x] = 1;
		ColorizeWeapons(x, INVIS);	
		choice = GetRandomInt(0, MAXMODELS - 1);
		
		offset = FindSendPropOffs("CBaseEntity", "m_nModelIndex");
		SetEntData(x, offset, g_modelindex[choice], 4, true);
		SetEntityRenderColor(x, 255, 255, 255, 255);
		
		PrintCenterText(x, "You are a %s!", g_modeltext[choice]);
		if(g_thirdpersonCvar == 1)
		{
			PrintToChat(x,"\x01You are disguised as a \x04%s\x01  - Type \x04!third\x01/\x04!thirdperson \x01to toggle thirdperson view!", g_modeltext[choice]);
		}
		else
		{
			PrintToChat(x,"\x01You are disguised as a \x04%s\x01 Go hide!", g_modeltext[choice]);
		}
		
		if(g_forcethirdCvar == 1)
		{
			SwitchView(x);
		}
	}
}

public Action:Command_Thirdperson(client, args)
{
	if(!IsEnabled || client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
	return Plugin_Handled;
	
	if(g_thirdpersonCvar != 1)
	{
		PrintToConsole(client, "[SM] Sorry, this command has been disabled.");
		return Plugin_Handled;
	}

	if(BonusRound)
	{
		if(g_IsAProp[client] == 1)
		{
			SwitchView(client);
		}
		else
		{
			ReplyToCommand(client, "[SM] You must be a PROP on the losing team to use thirdperson.");
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Thirdperson may only be used during bonus round.");
	}
	
	return Plugin_Handled;
}

stock SwitchView(client)
{
	if(client)
	{
		if(IsPlayerAlive(client))
		{
			if(g_InThirdperson[client] == 0)
			{
				g_InThirdperson[client] = 1;
				SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
				SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
				SetEntProp(client, Prop_Send, "m_iFOV", 120);			
			}
			else
			{
				g_InThirdperson[client] = 0;
				SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
				SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
				SetEntProp(client, Prop_Send, "m_iFOV", 90);			
			}
		}
	}
}

public ColorizeWeapons(client, color[4])
{
	//new maxents = GetMaxEntities();

	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	

	for(new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		
		if(weapon > -1)
		{
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, color[0], color[1],color[2], color[3]);
		}
	}
	
	return;
}

CheckGame()
{
	new String:strGame[10];
	GetGameFolderName(strGame, sizeof(strGame));

	if(StrEqual(strGame, "dod"))
	{
		LogMessage("Version %s loaded...", PLUGIN_VERSION);
	}
	else
	{
		SetFailState("[propbonusround] Detected game other than DOD:S. Plugin is disabled.");
	}
}

//Credit for the below stock goes to Antithasys!
stock CreateThirdpersonCommands()
{
	new String:sBuffer[128], String:sTriggerCommands[18][128];
	GetConVarString(Cvar_ThirdTriggers, sBuffer, sizeof(sBuffer));
	ExplodeString(sBuffer, ",", sTriggerCommands, sizeof(sTriggerCommands), sizeof(sTriggerCommands[]));
	for (new x = 0; x < sizeof(sTriggerCommands); x++)
	{
		if(IsStringBlank(sTriggerCommands[x]))
		{
			continue;
		}
		new String:sCommand[128];
		Format(sCommand, sizeof(sCommand), "sm_%s", sTriggerCommands[x]);
		RegConsoleCmd(sCommand, Command_Thirdperson, "Command(s) used to enable thirdperson view");
	}
}

//Credit for the below stock goes to Antithasys!
stock bool:IsStringBlank(const String:input[])
{
	new len = strlen(input);
	for (new i=0; i<len; i++)
	{
		if (!IsCharSpace(input[i]))
		{
			return false;
		}
	}
	return true;
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	if (!IsClientConnected(client))
	return false;
	new ibFlags = ReadFlagString(flags);
	if ((GetUserFlagBits(client) & ibFlags) == ibFlags) {
		return true;
	}
	if (GetUserFlagBits(client) & ADMFLAG_ROOT) {
		return true;
	}
	return false;
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_Enabled)
	{
		if(StringToInt(newValue) == 0)
		{
			IsEnabled = false;
			UnhookEvent("dod_round_start", Hook_RoundStart);
			UnhookEvent("dod_round_win", Hook_RoundWin);
			UnhookEvent("player_death", Hook_Playerdeath, EventHookMode_Post);
			UnhookEvent("player_hurt", Hook_PlayerHurt, EventHookMode_Pre);
			for(new x = 1; x <= MaxClients; x++)
			{
				if(IsClientInGame(x) && IsPlayerAlive(x))
				{
					if(g_IsAProp[x] == 1)
					{
						ColorizeWeapons(x, NORMAL);
						g_IsAProp[x] = 0;
					}
					if(g_InThirdperson[x] == 1)
					{
						SwitchView(x);
					}
				}
			}
		}
		else
		{
			IsEnabled = true;
			HookEvent("dod_round_start", Hook_RoundStart);
			HookEvent("dod_round_win", Hook_RoundWin);
			HookEvent("player_death", Hook_Playerdeath, EventHookMode_Post);
			HookEvent("player_hurt", Hook_PlayerHurt, EventHookMode_Pre);
		}
	}
	else if(convar == Cvar_ThirdPerson)
	{
		g_thirdpersonCvar = StringToInt(newValue);
	}
	else if(convar == Cvar_HitRemoveProp)
	{
		g_hitremovePropCvar = StringToInt(newValue);
	}
	else if(convar == Cvar_ForceThird)
	{
		g_forcethirdCvar = StringToInt(newValue);
	}
	else if(convar == Cvar_AdminOnly)
	{
		g_adminonlyCvar = StringToInt(newValue);
	}
}
