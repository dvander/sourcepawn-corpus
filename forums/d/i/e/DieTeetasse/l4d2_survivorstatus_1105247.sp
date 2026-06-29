#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

/*
possible colors:
 - white		\x01
 - orange		\x04
 - lightgreen	\x03
 - olive		\x05
*/

#define COLOR_ADRENALINE "\x01"
#define COLOR_BILE "\x05"
#define COLOR_DEFIB "\x04"
#define COLOR_MEDKIT "\x04"
#define COLOR_MOLOTOV "\x05"
#define COLOR_PILLS "\x01"
#define COLOR_PIPE "\x05"

#define COLOR_NAME "\x04"
#define COLOR_HEALTH "\x03"

#define SYMBOL_ADRENALINE "ADR"
#define SYMBOL_BILE "BIL"
#define SYMBOL_DEFIB "DEF"
#define SYMBOL_MEDKIT "MED"
#define SYMBOL_MOLOTOV "MOL"
#define SYMBOL_PILLS "PIL"
#define SYMBOL_PIPE "PIP"

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define DEFAULT_ENABLED true
#define PLUGIN_VERSION "1.0.0"
#define TEAM_SURVIVOR 2
#define UPDATE_INTERVAL 3.0

//plugin info
//#######################
public Plugin:myinfo =
{
	name = "Survivor status",
	author = "Die Teetasse",
	description = "Shows survivor status (health, items)",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1105247"
};

//global definitions
//#######################
new bool:ClientHUD[MAXPLAYERS+1];
new bool:HUDEnabled;
new String:SurvivorNames[4][16] = {"Nick", "Rochelle", "Coach", "Ellis"};

//plugin start
//#######################
public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("teamsay", Command_Say);

	HookEvent("round_end", Round_End_Event);
}

//say commands
//#######################
public Action:Command_Say(client, args)
{
	if (args < 1)
	{
		return Plugin_Continue;
	}
	
	decl String:text[15];
	GetCmdArg(1, text, sizeof(text));
	
	if (StrContains(text, "!hud") == 0)
	{
		ToggleHUD(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

ToggleHUD(client)
{
	if (ClientHUD[client] == true) ClientHUD[client] = false;
	else ClientHUD[client] = true;
}

//round end event
//#######################
public Action:Round_End_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	HUDEnabled = false;
}

//map start
//#######################
public OnMapStart()
{
	//enable hud
	HUDEnabled = true;
	
	//set hud for everybody to default value
	for (new i = 0; i < MAXPLAYERS+1; i++) ClientHUD[i] = DEFAULT_ENABLED;
	
	//activate display timer
	CreateTimer(UPDATE_INTERVAL, HUD_Timer, INVALID_HANDLE, TIMER_REPEAT);
}

//timer
//#######################
public Action:HUD_Timer(Handle:timer)
{
	if (!HUDEnabled) return Plugin_Stop;
	
	ShowHUD();
	return Plugin_Continue;
}

//show hud
//#######################
ShowHUD()
{
	//new Handle:HUDPanel = CreatePanel();
	decl String:TempString[256];
	decl String:TempStringCat[128];
	new SurvivorCount = 0;
	
	for (new i = 1; i < MaxClients+1; i++)
	{
		//ingame?
		if (!IsClientInGame(i)) continue;	
		//survivor?
		if (GetClientTeam(i) != TEAM_SURVIVOR) continue;
		
		//bot?
		if (IsFakeClient(i)) Format(TempString, sizeof(TempString), "%s%N: ", COLOR_NAME, i);
		else
		{
			new Character = GetEntProp(i, Prop_Send, "m_survivorCharacter");
			Format(TempString, sizeof(TempString), "%s%N (%s): ", COLOR_NAME, i, SurvivorNames[Character]);
		}
		
		//alive?
		if (IsPlayerAlive(i)) Format(TempStringCat, sizeof(TempStringCat), "%s %s %s %s", ClientHealth(i), ClientItem(i, 3), ClientItem(i, 4), ClientItem(i, 2));			
		else Format(TempStringCat, sizeof(TempStringCat), "%sDEAD", COLOR_HEALTH);
		
		StrCat(TempString, sizeof(TempString), TempStringCat);	
		PrintToChatAllIfEnabled(TempString);
		
		SurvivorCount++;
	}

	if (SurvivorCount < 8) for (new i = SurvivorCount; i < 8; i++) PrintToChatAllIfEnabled(" ");
}

PrintToChatAllIfEnabled(String:TempString[])
{
	for (new i = 1; i < MaxClients+1; i++)
	{
		//ingame?
		if (!IsClientInGame(i)) continue;	
		//bot?
		if (IsFakeClient(i)) continue;
		//enabled?
		if (!ClientHUD[i]) continue;
		
		PrintToChat(i, TempString);
	}
}

//return health string
//#######################
String:ClientHealth(client)
{
	new Health = GetClientHealth(client);
	new TempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	if (TempHealth < 0) TempHealth = 0;
	
	decl String:TempString[16];
	Format(TempString, sizeof(TempString), "%s%d/%d", COLOR_HEALTH, Health, TempHealth);
	return TempString;
}

//return item string
//#######################
String:ClientItem(client, slot)
{
	new String:TempString[32] = "";

	//get slot item
	decl String:WeaponClass[64];
	if (GetPlayerWeaponSlot(client, slot) > 0) GetEdictClassname(GetPlayerWeaponSlot(client, slot), WeaponClass, sizeof(WeaponClass));
	else return TempString;	
	
	switch(slot)
	{
		case 2:
			if (StrEqual("weapon_molotov", WeaponClass)) Format(TempString, sizeof(TempString), "%s%s", COLOR_MOLOTOV, SYMBOL_MOLOTOV);
			else if (StrEqual("weapon_pipe_bomb", WeaponClass)) Format(TempString, sizeof(TempString), "%s%s", COLOR_PIPE, SYMBOL_PIPE);
			else if (StrEqual("weapon_vomitjar", WeaponClass)) Format(TempString, sizeof(TempString), "%s%s", COLOR_BILE, SYMBOL_BILE);
		case 3:
			if (StrEqual("weapon_first_aid_kit", WeaponClass)) Format(TempString, sizeof(TempString), "%s%s", COLOR_MEDKIT, SYMBOL_MEDKIT);
			else if (StrEqual("weapon_defibrillator", WeaponClass)) Format(TempString, sizeof(TempString), "%s%s", COLOR_DEFIB, SYMBOL_DEFIB);
		case 4:
			if (StrEqual("weapon_pain_pills", WeaponClass)) Format(TempString, sizeof(TempString), "%s%s", COLOR_PILLS, SYMBOL_PILLS);
			else if (StrEqual("weapon_adrenaline", WeaponClass)) Format(TempString, sizeof(TempString), "%s%s", COLOR_ADRENALINE, SYMBOL_ADRENALINE);
	}
	
	return TempString;
}