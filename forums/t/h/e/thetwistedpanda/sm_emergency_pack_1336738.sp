#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_PREFIX "\x04Pack: \x03"

//Formula: (((kills / deaths) * HEALTH_FACTOR) * (kills - deaths))
#define HEALTH_FACTOR 100

//The maximum amount of health a player can achieve by purchasing pack health
#define HEALT_MAX 100

enum Emergency_Pack 
{
	bool:Has_Display = false,
	bool:Has_Speed = false,
	bool:Has_Gravity = false,
	Grenade_Count = 0,
	Smoke_Count = 0,
	Flash_Count = 0
}
new g_eData[MAXPLAYERS + 1][Emergency_Pack];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hRequired = INVALID_HANDLE;
new Handle:g_hAuto = INVALID_HANDLE;
new Handle:g_hHealth = INVALID_HANDLE;
new Handle:g_hHealthCost = INVALID_HANDLE;
new Handle:g_hSpeed = INVALID_HANDLE;
new Handle:g_hSpeedCost = INVALID_HANDLE;
new Handle:g_hGravity = INVALID_HANDLE;
new Handle:g_hGravityCost = INVALID_HANDLE;
new Handle:g_hGrenade = INVALID_HANDLE;
new Handle:g_hGrenadeCost = INVALID_HANDLE;
new Handle:g_hSmoke = INVALID_HANDLE;
new Handle:g_hSmokeCost = INVALID_HANDLE;
new Handle:g_hFlash = INVALID_HANDLE;
new Handle:g_hFlashCost = INVALID_HANDLE;
new Handle:g_hCookie = INVALID_HANDLE;

new g_iAccount, g_iInput[7], g_iCount;
new bool:g_bIsRoundEnd, bool:g_bEnabled, bool:g_bHealth, bool:g_bSpeed, bool:g_bGravity, bool:g_bSmoke, bool:g_bGrenade, bool:g_bFlash, bool:g_bAuto;
new g_iRequired, g_iHealth, g_iHealthCost, g_iSpeedCost, g_iGravityCost, g_iSmoke, g_iSmokeCost, g_iGrenade, g_iGrenadeCost, g_iFlash, g_iFlashCost;
new Float:g_fSpeed, Float:g_fGravity;

public Plugin:myinfo =
{
	name = "Emergency Pack",
	author = "Twisted|Panda",
	description = "An emergency buy scirpt that allows users to purchase a few items that may turn the tide of battle.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
}

public OnPluginStart()
{
	CreateConVar("sm_emergencypack_version", PLUGIN_VERSION, "Emergency Pack Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_emergencypack_enabled", "1", "Enables/disables all features of this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hRequired = CreateConVar("sm_emergencypack_required", "30", "The maximum amount of Health playrs can have in order to access this menu. (0 = Always)", FCVAR_NONE, true, 0.0);
	g_hAuto = CreateConVar("sm_emergencypack_auto", "0", "If enabled, players will have the option of enabling/disabling the menu's auto toggle feature.", FCVAR_NONE, true, 0.0, true, 1.0);

	g_hHealth = CreateConVar("sm_emergencypack_health", "30", "The amount of Health players may purchase from this plugin. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	g_hHealthCost = CreateConVar("sm_emergencypack_health_cost", "0", "The amount that sm_emergencypack_health health costs. (-1.0 = Dynamic)", FCVAR_NONE, true, -1.0);
	g_hSpeed = CreateConVar("sm_emergencypack_speed", "0", "The amount of Speed players may purchase from this plugin. (0 = Disabled, 1.0 = Double Speed)", FCVAR_NONE, true, 0.0);
	g_hSpeedCost = CreateConVar("sm_emergencypack_speed_cost", "0", "The amount that sm_emergencypack_speed increased speed costs.", FCVAR_NONE, true, 0.0);
	g_hGravity = CreateConVar("sm_emergencypack_gravity", "0", "The amount of Gravity players may purchase from this plugin. (0 = Disabled, 0.5 = Half Gravity)", FCVAR_NONE, true, 0.0, true, 0.9);
	g_hGravityCost = CreateConVar("sm_emergencypack_gravity_cost", "0", "The amount that sm_emergencypack_gravity increased gravity costs.", FCVAR_NONE, true, 0.0);
	g_hGrenade = CreateConVar("sm_emergencypack_grenade", "3", "The maximum amount of HE Grenades players may purchase from this plugin. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	g_hGrenadeCost = CreateConVar("sm_emergencypack_grenade_cost", "2500", "The amount each HE Grenade will cost via this plugin.", FCVAR_NONE, true, 0.0);
	g_hSmoke = CreateConVar("sm_emergencypack_smoke", "0", "The maximum amount of Smoke Grenades players may purchase from this plugin. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	g_hSmokeCost = CreateConVar("sm_emergencypack_smoke_cost", "2000", "The amount each Smoke Grenade will cost via this plugin.", FCVAR_NONE, true, 0.0);
	g_hFlash = CreateConVar("sm_emergencypack_flash", "1", "The maximum amount of Flashbangs players may purchase from this plugin. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	g_hFlashCost = CreateConVar("sm_emergencypack_flash_cost", "3000", "The amount each Flashbang will cost via this plugin.", FCVAR_NONE, true, 0.0);
	AutoExecConfig(true, "sm_emergencypack");

	HookConVarChange(g_hEnabled, Action_OnSettingsChange);
	HookConVarChange(g_hRequired, Action_OnSettingsChange);
	HookConVarChange(g_hAuto, Action_OnSettingsChange);
	HookConVarChange(g_hHealth, Action_OnSettingsChange);
	HookConVarChange(g_hHealthCost, Action_OnSettingsChange);
	HookConVarChange(g_hSpeed, Action_OnSettingsChange);
	HookConVarChange(g_hSpeedCost, Action_OnSettingsChange);
	HookConVarChange(g_hGravity, Action_OnSettingsChange);
	HookConVarChange(g_hGravityCost, Action_OnSettingsChange);
	HookConVarChange(g_hGrenade, Action_OnSettingsChange);
	HookConVarChange(g_hGrenadeCost, Action_OnSettingsChange);
	HookConVarChange(g_hSmoke, Action_OnSettingsChange);
	HookConVarChange(g_hSmokeCost, Action_OnSettingsChange);
	HookConVarChange(g_hFlash, Action_OnSettingsChange);
	HookConVarChange(g_hFlashCost, Action_OnSettingsChange);

	RegConsoleCmd("sm_pack", Command_Pack);
	RegConsoleCmd("sm_epack", Command_Pack);
	HookEvent("player_hurt", Event_OnPlayerHurt);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_end", Event_OnRoundEnd);

	g_hCookie = RegClientCookie("Emergency Pack", "Emergency Pack", CookieAccess_Protected);
	SetCookieMenuItem(Menu_Status, 0, "Emergency Pack");
	
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if(g_iAccount == -1)
		SetFailState("Whoops, you ain't running this on CS:S dawg! Can't find that \"m_iAccount\" offeset thing.");
}

public OnMapStart()
{
	Void_SetDefaults();
}
	
public OnClientConnected(client)
{
	if(g_bEnabled)
	{
		if(g_bAuto)
		{
			g_eData[client][Has_Display] = false;
			CreateTimer(0.0, Timer_Check, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_eData[client][Has_Speed] = false;
		g_eData[client][Has_Gravity] = false;
	}
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bIsRoundEnd = false;
	}
	
	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bIsRoundEnd = true;
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		if(g_bAuto && g_eData[client][Has_Display])
		{
			new health = GetClientOfUserId(GetEventInt(event, "health"));
			if(!g_hRequired && health <= g_iRequired)
				if(!GetClientMenu(client))
					CreateCookieMenu(client);
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		if(g_bGrenade)
			g_eData[client][Grenade_Count] = g_iGrenade;

		if(g_bSmoke)
			g_eData[client][Smoke_Count] = g_iSmoke;

		if(g_bFlash)
			g_eData[client][Flash_Count] = g_iFlash;

		if(g_bGravity)
			SetEntityGravity(client, 1.0);

		if(g_bSpeed)
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;
			
		if(g_bGravity)
			g_eData[client][Has_Gravity] = false;

		if(g_bSpeed)
			g_eData[client][Has_Speed] = false;
	}
	
	return Plugin_Continue;
}

public Action:Command_Pack(client, args)
{
	if(!g_bEnabled)
		PrintToChat(client, "%sThis feature is currently disabled!", PLUGIN_PREFIX);
	else if(client && IsClientInGame(client))
	{
		if(GetClientTeam(client) <= CS_TEAM_SPECTATOR)
			PrintToChat(client, "%sYou cannot use this feature while in spectate!", PLUGIN_PREFIX);
		else if(!IsPlayerAlive(client))
			PrintToChat(client, "%sYou cannot use this feature while dead!", PLUGIN_PREFIX);
		else if(g_bIsRoundEnd)
			PrintToChat(client, "%sYou cannot use this feature until the next round!", PLUGIN_PREFIX);
		else if(g_iRequired && GetClientHealth(client) > g_iRequired)
			PrintToChat(client, "%sYou cannot use the emergency pack if your health is above %d!", PLUGIN_PREFIX, g_iRequired);
		else
			CreateCookieMenu(client);
	}
	
	return Plugin_Handled;
}

public Action:Timer_Check(Handle:timer, any:client)
{
	if(client)
	{
		if(AreClientCookiesCached(client))
			CreateTimer(0.0, Timer_Process, client, TIMER_FLAG_NO_MAPCHANGE);
		else if(IsClientInGame(client))
			CreateTimer(5.0, Timer_Check, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:Timer_Process(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		decl String:g_sCookie[5] = "";

		GetClientCookie(client, g_hCookie, g_sCookie, sizeof(g_sCookie));
		if(StrEqual(g_sCookie, "On"))
			g_eData[client][Has_Display] = true;
	}

	return Plugin_Continue;
}

public Menu_Status(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "Emergency Pack");
		case CookieMenuAction_SelectOption:
		{
			if(!g_bEnabled)
				PrintToChat(client, "%sThis feature is currently disabled", PLUGIN_PREFIX);
			else if(IsClientInGame(client))
			{
				if(GetClientTeam(client) <= CS_TEAM_SPECTATOR)
					PrintToChat(client, "%sYou cannot use this feature while in spectate!", PLUGIN_PREFIX);
				else if(!IsPlayerAlive(client))
					PrintToChat(client, "%sYou cannot use this feature while you're dead!", PLUGIN_PREFIX);
				else if(g_bIsRoundEnd)
					PrintToChat(client, "%sYou cannot use this feature until the next round!", PLUGIN_PREFIX);
				else if(g_iRequired && GetClientHealth(client) > g_iRequired)
					PrintToChat(client, "%sYou cannot use the emergency pack if your health is above %d!", PLUGIN_PREFIX, g_iRequired);
				else
					CreateCookieMenu(client);
			}
		}
	}
}

stock CreateCookieMenu(client)
{
	new Handle:g_hMenu = CreateMenu(Menu_StatusDisplay);
	decl String:g_sText[64], String:g_sTemp[256];

	Format(g_sText, sizeof(g_sText), "Emergency Pack\n=--=--=");
	SetMenuTitle(g_hMenu, g_sText);

	if(g_bHealth)
	{
		new g_iTemp;
		if(g_iHealthCost == -1)
		{
			new g_iKills = GetClientFrags(client), g_iDeaths = GetClientDeaths(client);
			new g_iScore = g_iKills - g_iDeaths;
			if(g_iKills <= 0)
				g_iKills = 1;
			if(g_iDeaths <= 0)
				g_iDeaths = 1;
			if(g_iScore <= 0)
				g_iScore = 1;

			g_iTemp = ((g_iKills / g_iDeaths) * HEALTH_FACTOR) * g_iScore;
		}
		else
			g_iTemp = g_iHealthCost;

		Format(g_sTemp, sizeof(g_sTemp), "%d Health, $%d", g_iHealth, g_iTemp);
		if(GetClientHealth(client) >= HEALT_MAX)
			AddMenuItem(g_hMenu, "Emergency_Pack", g_sTemp, ITEMDRAW_DISABLED);
		else
			AddMenuItem(g_hMenu, "Emergency_Pack", g_sTemp);
	}

	if(g_bSpeed)
	{
		Format(g_sTemp, sizeof(g_sTemp), "%.1fx Speed, $%d", g_fSpeed, g_iSpeedCost);
		if(g_eData[client][Has_Speed])
			AddMenuItem(g_hMenu, "Emergency_Pack", g_sTemp, ITEMDRAW_DISABLED);
		else
			AddMenuItem(g_hMenu, "Emergency_Pack", g_sTemp);
	}

	if(g_bGravity)
	{
		Format(g_sTemp, sizeof(g_sTemp), "%.1fx Gravity, $%d", g_fGravity, g_iGravityCost);
		if(g_eData[client][Has_Gravity])
			AddMenuItem(g_hMenu, "Emergency_Pack", g_sTemp, ITEMDRAW_DISABLED);
		else
			AddMenuItem(g_hMenu, "Emergency_Pack", g_sTemp);
	}

	if(g_bGrenade)
	{
		Format(g_sTemp, sizeof(g_sTemp), "%d/%d Grenades, $%d", g_eData[client][Grenade_Count], g_iGrenade, g_iGrenadeCost);
		if(g_eData[client][Grenade_Count] > 0)
			AddMenuItem(g_hMenu, "Emergency_Pack", g_sTemp);
		else
			AddMenuItem(g_hMenu, "Emergency_Pack", g_sTemp, ITEMDRAW_DISABLED);
	}

	if(g_bSmoke)
	{
		Format(g_sTemp, sizeof(g_sTemp), "%d/%d Smoke Grenades, $%d", g_eData[client][Smoke_Count], g_iSmoke, g_iSmokeCost);
		if(g_eData[client][Smoke_Count] > 0)
			AddMenuItem(g_hMenu, "Emergency_Pack", g_sTemp);
		else
			AddMenuItem(g_hMenu, "Emergency_Pack", g_sTemp, ITEMDRAW_DISABLED);
	}

	if(g_bFlash)
	{
		Format(g_sTemp, sizeof(g_sTemp), "%d/%d Flashbangs, $%d", g_eData[client][Flash_Count], g_iFlash, g_iFlashCost);
		if(g_eData[client][Flash_Count] > 0)
			AddMenuItem(g_hMenu, "Emergency_Pack", g_sTemp);
		else
			AddMenuItem(g_hMenu, "Emergency_Pack", g_sTemp, ITEMDRAW_DISABLED);
	}

	if(g_bAuto && g_iRequired)
	{
		if(g_eData[client][Has_Display])
			AddMenuItem(g_hMenu, "Emergency_Pack", "Disable Automatic Toggle");
		else
			AddMenuItem(g_hMenu, "Emergency_Pack", "Enable Automatic Toggle");
	}

	SetMenuExitBackButton(g_hMenu, true);
	SetMenuExitButton(g_hMenu, true);
	DisplayMenu(g_hMenu, client, 15);
}

public Menu_StatusDisplay(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if(param2 != -1)
			{
				if(param2 == g_iInput[0])
				{//Health
					new g_iTemp, g_iCash = GetEntData(param1, g_iAccount);
					if(g_iHealthCost == -1)
					{
						new g_iKills = GetClientFrags(param1), g_iDeaths = GetClientDeaths(param1);
						new g_iScore = g_iKills - g_iDeaths;
						if(g_iKills <= 0)
							g_iKills = 1;
						if(g_iDeaths <= 0)
							g_iDeaths = 1;
						if(g_iScore <= 0)
							g_iScore = 1;

						g_iTemp = ((g_iKills / g_iDeaths) * HEALTH_FACTOR) * g_iScore;
					}
					else
						g_iTemp = g_iHealthCost;

					if(g_iCash > g_iTemp)
					{
						SetEntityHealth(param1, (GetClientHealth(param1) + g_iHealth));
						PrintToChat(param1, "%sYou purchased %d %s health from the pack for $%d!", PLUGIN_PREFIX, g_iHealth, g_iRequired ? "emergency" : "extra", g_iTemp);
						
						SetEntData(param1, g_iAccount, (g_iCash - g_iTemp));
					}
					else
						PrintToChat(param1, "%sYou do not have enough cash to purchase an %s health boost from the pack!", PLUGIN_PREFIX, g_iRequired ? "emergency" : "extra");
				}
				else if(param2 == g_iInput[1])
				{//Speed
					new g_iCash = GetEntData(param1, g_iAccount);
					if(g_iCash > g_iSpeedCost)
					{
						SetEntPropFloat(param1, Prop_Data, "m_flLaggedMovementValue", g_fSpeed);
						PrintToChat(param1, "%sYou purchased %.1fx %s speed from the pack for $%d!", PLUGIN_PREFIX, g_fSpeed, g_iRequired ? "emergency" : "extra", g_iSpeedCost);
						
						SetEntData(param1, g_iAccount, (g_iCash - g_iSpeedCost));
					}
					else
						PrintToChat(param1, "%sYou do not have enough cash to purchase %a speed boost from the pack!", PLUGIN_PREFIX, g_iRequired ? "an emergency" : "a");
				}
				else if(param2 == g_iInput[2])
				{//Gravity
					new g_iCash = GetEntData(param1, g_iAccount);
					if(g_iCash > g_iGravityCost)
					{
						SetEntityGravity(param1, g_fGravity);
						PrintToChat(param1, "%sYou purchased %.1fx %s gravity from the pack for $%d!", PLUGIN_PREFIX, g_fGravity, g_iRequired ? "emergency" : "extra", g_iGravityCost);
						
						SetEntData(param1, g_iAccount, (g_iCash - g_iGravityCost));
					}
					else
						PrintToChat(param1, "%sYou do not have enough cash to purchase %s gravity boost from the pack!", PLUGIN_PREFIX, g_iRequired ? "an emergency" : "a");
				}
				else if(param2 == g_iInput[3])
				{//Grenade
					new g_iCash = GetEntData(param1, g_iAccount);
					if(g_iCash > g_iGrenadeCost)
					{
						g_eData[param1][Grenade_Count]--;
						GivePlayerItem(param1, "weapon_hegrenade");

						PrintToChat(param1, "%sYou purchased %s grenade from the pack for $%d!", PLUGIN_PREFIX, g_iRequired ? "an emergency" : "a", g_iGrenadeCost);
						SetEntData(param1, g_iAccount, (g_iCash - g_iGrenadeCost));
					}
					else
						PrintToChat(param1, "%sYou do not have enough cash to purchase %s grenade from the pack!", PLUGIN_PREFIX, g_iRequired ? "an emergency" : "a");
				}
				else if(param2 == g_iInput[4])
				{//Smoke
					new g_iCash = GetEntData(param1, g_iAccount);
					if(g_iCash > g_iSmokeCost)
					{
						g_eData[param1][Smoke_Count]--;
						GivePlayerItem(param1, "weapon_smokegrenade");
						
						PrintToChat(param1, "%sYou purchased %s smoke grenade from the pack for $%d!", PLUGIN_PREFIX, g_iRequired ? "an emergency" : "a", g_iSmokeCost);
						SetEntData(param1, g_iAccount, (g_iCash - g_iSmokeCost));
					}
					else
						PrintToChat(param1, "%sYou do not have enough cash to purchase %s smoke grenade from the pack!", PLUGIN_PREFIX, g_iRequired ? "an emergency" : "a");
				}
				else if(param2 == g_iInput[5])
				{//Flash
					new g_iCash = GetEntData(param1, g_iAccount);
					if(g_iCash > g_iFlashCost)
					{
						g_eData[param1][Flash_Count]--;
						GivePlayerItem(param1, "weapon_flashbang");
						
						PrintToChat(param1, "%sYou purchased %s flashbang from the pack for $%d!", PLUGIN_PREFIX, g_iRequired ? "an emergency" : "a", g_iFlashCost);
						SetEntData(param1, g_iAccount, (g_iCash - g_iFlashCost));
					}
					else
						PrintToChat(param1, "%sYou do not have enough cash to purchase %s flashbang from the pack!", PLUGIN_PREFIX, g_iRequired ? "an emergency" : "a");
				}
				else if(param2 == g_iInput[6] && g_iRequired)
				{//Auto
					if(g_eData[param1][Has_Display])
					{
						SetClientCookie(param1, g_hCookie, "Off");
						g_eData[param1][Has_Display] = false;
						
						PrintToChat(param1, "%sThe pack menu will no longer automatically appear!", PLUGIN_PREFIX);
					}
					else
					{
						SetClientCookie(param1, g_hCookie, "On");
						g_eData[param1][Has_Display] = true;
						
						PrintToChat(param1, "%sThe pack menu will automatically appear should you fall below %d health!", PLUGIN_PREFIX, g_iRequired);
					}
				}
			}
		}
		case MenuAction_Cancel: 
		{
			switch (param2) 
			{
				case MenuCancel_ExitBack:
					ShowCookieMenu(param1);
			}
		}
		case MenuAction_End:
			CloseHandle(menu);
	}
}

void:Void_SetDefaults()
{
	new g_iTemp;

	g_iTemp = GetConVarInt(g_hEnabled);
	if(g_iTemp)
		g_bEnabled = true;
	else
		g_bEnabled = false;

	g_iRequired = GetConVarInt(g_hRequired);

	g_iTemp = GetConVarInt(g_hAuto);
	if(g_iTemp)
		g_bAuto = true;
	else
		g_bAuto = false;

	g_iHealth = GetConVarInt(g_hHealth);
	g_iHealthCost = GetConVarInt(g_hHealthCost);
	if(g_iHealth)
		g_bHealth = true;
	else
		g_bHealth = false;

	g_fSpeed = GetConVarFloat(g_hSpeed);
	g_iSpeedCost = GetConVarInt(g_hSpeedCost);
	if(g_fSpeed)
	{
		g_bSpeed = true;
		g_fSpeed += 1.0;
	}
	else
		g_bSpeed = false;

	new Float:g_fTemp = GetConVarFloat(g_hGravity);
	g_iGravityCost = GetConVarInt(g_hGravityCost);
	if(g_fTemp)
	{
		g_bGravity = true;
		g_fGravity = 1.0 - g_fTemp;
	}
	else
		g_bGravity = false;

	g_iGrenade = GetConVarInt(g_hGrenade);
	g_iGrenadeCost = GetConVarInt(g_hGrenadeCost);
	if(g_iGrenade)
		g_bGrenade = true;
	else
		g_bGrenade = false;

	g_iSmoke = GetConVarInt(g_hSmoke);
	g_iSmokeCost = GetConVarInt(g_hSmokeCost);
	if(g_iSmoke)
		g_bSmoke = true;
	else
		g_bSmoke = false;

	g_iFlash = GetConVarInt(g_hFlash);
	g_iFlashCost = GetConVarInt(g_hFlashCost);
	if(g_iFlash)
		g_bFlash = true;
	else
		g_bFlash = false;
		
	Void_SetInput();
}

void:Void_SetInput()
{
	g_iCount = 0;
	for(new i = 0; i <= 6; i++)
		g_iInput[i] = -1;

	if(g_bHealth)
	{
		g_iInput[0] = g_iCount;
		g_iCount++;
	}

	if(g_bSpeed)
	{
		g_iInput[1] = g_iCount;
		g_iCount++;
	}

	if(g_bGravity)
	{
		g_iInput[2] = g_iCount;
		g_iCount++;
	}

	if(g_bGrenade)
	{
		g_iInput[3] = g_iCount;
		g_iCount++;
	}

	if(g_bSmoke)
	{
		g_iInput[4] = g_iCount;
		g_iCount++;
	}

	if(g_bFlash)
	{
		g_iInput[5] = g_iCount;
		g_iCount++;
	}
	
	if(g_bAuto)
	{
		g_iInput[6] = g_iCount;
		g_iCount++;
	}
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	new g_iTemp;
	if(cvar == g_hEnabled)
	{
		g_iTemp = StringToInt(newvalue);
		if(g_iTemp)
			g_bEnabled = true;
		else
			g_bEnabled = false;
	}
	else if(cvar == g_hRequired)
		g_iRequired = StringToInt(newvalue);
	else if(cvar == g_hAuto)
	{
		g_iTemp = StringToInt(newvalue);
		if(g_iTemp)
			g_bAuto = true;
		else
			g_bAuto = false;
	}
	else if(cvar == g_hHealth)
	{
		g_iHealth = StringToInt(newvalue);
		if(g_iHealth)
			g_bHealth = true;
		else
			g_bHealth = false;
		
		Void_SetInput();
	}
	else if(cvar == g_hHealthCost)
		g_iHealthCost = StringToInt(newvalue);
	else if(cvar == g_hSpeed)
	{
		g_fSpeed = StringToFloat(newvalue);
		if(g_fSpeed)
		{
			g_bSpeed = true;
			g_fSpeed += 1.0;
		}
		else
			g_bSpeed = false;
		
		Void_SetInput();
	}
	else if(cvar == g_hSpeedCost)
		g_iSpeedCost = StringToInt(newvalue);
	else if(cvar == g_hGravity)
	{
		new Float:g_fTemp = StringToFloat(newvalue);
		if(g_fTemp)
		{
			g_bGravity = true;
			g_fGravity = 1.0 - g_fTemp;
		}
		else
			g_bGravity = false;
		
		Void_SetInput();
	}
	else if(cvar == g_hGravityCost)
		g_iGravityCost = StringToInt(newvalue);
	else if(cvar == g_hGrenade)
	{
		g_iGrenade = StringToInt(newvalue);
		if(g_iGrenade)
			g_bGrenade = true;
		else
			g_bGrenade = false;
		
		Void_SetInput();
	}
	else if(cvar == g_hGrenadeCost)
		g_iGrenadeCost = StringToInt(newvalue);
	else if(cvar == g_hSmoke)
	{
		g_iSmoke = StringToInt(newvalue);
		if(g_iSmoke)
			g_bSmoke = true;
		else
			g_bSmoke = false;
		
		Void_SetInput();
	}
	else if(cvar == g_hSmokeCost)
		g_iSmokeCost = StringToInt(newvalue);
	else if(cvar == g_hFlash)
	{
		g_iFlash = StringToInt(newvalue);
		if(g_iFlash)
			g_bFlash = true;
		else
			g_bFlash = false;
		
		Void_SetInput();
	}
	else if(cvar == g_hFlashCost)
		g_iFlashCost = StringToInt(newvalue);
}