#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <sdkhooks>

const int TEAM_NONE = 0, TEAM_SPECTATOR = 1, TEAM_SURVIVOR = 2, TEAM_INFECTED = 3;
const int PREZ_COLOR_NOCOLOR = 0, PREZ_COLOR_FULLHEALTH = 1, PREZ_COLOR_MEDHEALTH = 2, PREZ_COLOR_LOWHEALTH = 3, PREZ_COLOR_BOOMED = 4;
const int WEP_SLOT_PRIMARY = 0, WEP_SLOT_MELEE = 1, WEP_SLOT_GRENADE = 2, WEP_SLOT_HEALTH = 3;

#define PLUGIN_VERSION "1.0.4"

#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

public Plugin myinfo =
{
	name        = "L4D2 -=BwA=- Protect The President",
	author      = "-=BwA=- jester",
	description = "Protect the teammate deemed 'The Prez' as when they are hit, you all are",
	version     = PLUGIN_VERSION,
	url         = ""
};

//int dfltGlow = 0, dfltColor = 0, dfltRange = 0, dfltFlash = 0;
ConVar prez_SkinColor_FullHealth, prez_SkinColor_MedHealth, prez_SkinColor_LowHealth, prez_GlowColor_FullHealth;
ConVar prez_GlowColor_MedHealth, prez_GlowColor_LowHealth, prez_GlowColor_Boomed;
int thePrez = 0, skinRed[4], skinGreen[4], skinBlue[4], glowColor[5], movementOffset = -1, deathTicks = 0, lockedDoor = 0;
ConVar teamDmgRatio, normalDmgRatio, prezSpeedRatio, prezHealthRatio, prezCanHeal;
ConVar prezDefibTime, prezSelectionType, prezAllowMagnum, prezAllowAllItems, prezDeathBlockDoor;
bool prezRevived = false, prezBoomed = false, prevPrez[MAXPLAYERS + 1], enabled = true;
Handle hTopMenu = null;

public void OnPluginStart()
{
	char ModName[64];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName, "left4dead2", false)) SetFailState("Use this in Left 4 Dead (2) only.");

	CreateConVar("l4d2_bwa_protectheprez_version", PLUGIN_VERSION, "L4D2 BwA Protect the Prez Version", CVAR_FLAGS|FCVAR_DONTRECORD);
	
	teamDmgRatio = CreateConVar("l4d2_bwa_ptp_team_dmg_ratio", "0.5", "Percentage of damage to president that team members take. [min = 0.0(0%)|max = 5.0(500%)]", CVAR_FLAGS, true, 0.10, true, 5.0);
	normalDmgRatio = CreateConVar("l4d2_bwa_ptp_normal_dmg_ratio", "1.0", "Percentage of normal damage to apply to all players. [min = .10(10%)|max = 5.0(500%)]", CVAR_FLAGS, true, 0.10, true, 5.0);
	prezHealthRatio = CreateConVar("l4d2_bwa_ptp_prez_health_ratio", "1.5", "Health Multiplier for President [min = .50(50% health)|max = 5.0(500% health)]", CVAR_FLAGS, true, 0.10, true, 5.0);
	prezSpeedRatio = CreateConVar("l4d2_bwa_ptp_prez_speed_ratio", "1.2", "Percentage of normal movement speed to give to the president. [min = .5(50%)|max = 2.0(200%)]", CVAR_FLAGS, true, 0.50, true, 2.0);
	prezCanHeal = CreateConVar("l4d2_bwa_ptp_prez_allow_heal", "0", "Allow the Prez to carry a health pack and heal himself. [0 = Off|1 = On]", CVAR_FLAGS, true, 0.0, true, 1.0);
	prezDefibTime = CreateConVar("l4d2_bwa_ptp_prez_defib_time", "30", "Number of seconds you have to defib the President when he dies before you all die. [min = 0|max = 300(5 mins)]", CVAR_FLAGS, true, 0.0, true, 300.0);
	prezSelectionType = CreateConVar("l4d2_bwa_ptp_prez_selection_type", "2", "Type of selection process for President. [Random = 1|Random excluding previous = 2]", CVAR_FLAGS, true, 1.0, true, 2.0);
	prezAllowMagnum = CreateConVar("l4d2_bwa_ptp_prez_allow_magnum", "0", "Allow/Give the Prez a magnum. [0 = No|1 = Yes]", CVAR_FLAGS, true, 0.0, true, 1.0);
	prezAllowAllItems = CreateConVar("l4d2_bwa_ptp_prez_allow_all_items", "0", "Allow use all items. [0 = No|1 = Yes]", CVAR_FLAGS, true, 0.0, true, 1.0);
	prezDeathBlockDoor = CreateConVar("l4d2_bwa_ptp_prez_death_block_door", "1", "Lock the safe door if the President is dead. [0 = No|1 = Yes]", CVAR_FLAGS, true, 0.0, true, 1.0);
	
	prez_SkinColor_FullHealth = CreateConVar("l4d2_bwa_ptp_prez_SkinColor_FullHealth", "10,200,200", "<Red>,<Green>,<Blue> (0-255)");
	prez_SkinColor_MedHealth = CreateConVar("l4d2_bwa_ptp_prez_SkinColor_MedHealth", "180,100,20", "<Red>,<Green>,<Blue> (0-255)");
	prez_SkinColor_LowHealth = CreateConVar("l4d2_bwa_ptp_prez_SkinColor_LowHealth", "220,20,20", "<Red>,<Green>,<Blue> (0-255)");

	prez_GlowColor_FullHealth = CreateConVar("l4d2_bwa_ptp_prez_GlowColor_FullHealth", "0,255,255", "<Red> <Green> <Blue> (0-255)");
	prez_GlowColor_MedHealth = CreateConVar("l4d2_bwa_ptp_prez_GlowColor_MedHealth", "255,128,0", "<Red> <Green> <Blue> (0-255)");
	prez_GlowColor_LowHealth = CreateConVar("l4d2_bwa_ptp_prez_GlowColor_LowHealth", "80,0,200", "<Red> <Green> <Blue> (0-255)");
	prez_GlowColor_Boomed = CreateConVar("l4d2_bwa_ptp_prez_GlowColor_Boomed", "255,0,255", "<Red> <Green> <Blue> (0-255)");

	RegAdminCmd("sm_selectprez", Command_SelectPrez, ADMFLAG_GENERIC, "usage: sm_selectprez <clientid>");	
	RegAdminCmd("sm_enablevip", Command_Enable, ADMFLAG_GENERIC, "usage: sm_enablevip");	
	RegAdminCmd("sm_disablevip", Command_Disable, ADMFLAG_GENERIC, "usage: sm_disablevip");	
			
	RegConsoleCmd("lock", Command_Lock);
	RegConsoleCmd("unlock", Command_Unlock);
	
	movementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	
	AutoExecConfig(true, "l4d2_bwa_protect_the_prez");
	
	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(hTopMenu);
	}
	
	Enable();
}

public void OnConfigsExecuted()
{
	// 0 is PREZ_COLOR_NOCOLOR
	skinRed[0] = 255;
	skinGreen[0] = 255;
	skinBlue[0] = 255;

	char colors[3][4], color[32] = { "255,255,255" };

	prez_SkinColor_FullHealth.GetString(color, sizeof(color));

	ExplodeString(color, ",", colors, 3, 4);
	
	skinRed[PREZ_COLOR_FULLHEALTH] = StringToInt(colors[0]);
	skinGreen[PREZ_COLOR_FULLHEALTH] = StringToInt(colors[1]);
	skinBlue[PREZ_COLOR_FULLHEALTH] = StringToInt(colors[2]);
	
	prez_SkinColor_MedHealth.GetString(color, sizeof(color));
	
	ExplodeString(color, ",", colors, 3, 4);
	
	skinRed[PREZ_COLOR_MEDHEALTH] = StringToInt(colors[0]);
	skinGreen[PREZ_COLOR_MEDHEALTH] = StringToInt(colors[1]);
	skinBlue[PREZ_COLOR_MEDHEALTH] = StringToInt(colors[2]);
	
	prez_SkinColor_LowHealth.GetString(color, sizeof(color));
		
	ExplodeString(color, ",", colors, 3, 4);
	
	skinRed[PREZ_COLOR_LOWHEALTH] = StringToInt(colors[0]);
	skinGreen[PREZ_COLOR_LOWHEALTH] = StringToInt(colors[1]);
	skinBlue[PREZ_COLOR_LOWHEALTH] = StringToInt(colors[2]);
	
	// 0 is PREZ_COLOR_NOCOLOR		
	glowColor[0] = 0;

	prez_GlowColor_FullHealth.GetString(color, sizeof(color));
	ExplodeString(color, ",", colors, 3, 4);
	glowColor[PREZ_COLOR_FULLHEALTH] = RGB_TO_INT(StringToInt(colors[0]), StringToInt(colors[1]), StringToInt(colors[2]));

	prez_GlowColor_MedHealth.GetString(color, sizeof(color));
	ExplodeString(color, ",", colors, 3, 4);
	glowColor[PREZ_COLOR_MEDHEALTH] = RGB_TO_INT(StringToInt(colors[0]), StringToInt(colors[1]), StringToInt(colors[2]));

	prez_GlowColor_LowHealth.GetString(color, sizeof(color));
	ExplodeString(color, ",", colors, 3, 4);
	glowColor[PREZ_COLOR_LOWHEALTH] = RGB_TO_INT(StringToInt(colors[0]), StringToInt(colors[1]), StringToInt(colors[2]));

	prez_GlowColor_Boomed.GetString(color, sizeof(color));
	ExplodeString(color, ",", colors, 3, 4);
	glowColor[PREZ_COLOR_BOOMED] = RGB_TO_INT(StringToInt(colors[0]), StringToInt(colors[1]), StringToInt(colors[2]));
}

stock int RGB_TO_INT(int red, int green, int blue)
{
	return (blue * 65536) + (green * 256) + red;
}

public void OnAdminMenuReady(Handle topmenu)
{	
	if (topmenu == hTopMenu) return;
		
	hTopMenu = topmenu;

	// Create a new Category on the admin menu	
	TopMenuObject vip_menu = AddToTopMenu(hTopMenu, "BwAProtectThePrezMenu", TopMenuObject_Category, Admin_TopPrezMenu, INVALID_TOPMENUOBJECT);

	// Add items to the category
	if (vip_menu != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu, "bwaselecttheprez", TopMenuObject_Item, Admin_SelectThePrez, vip_menu, "", ADMFLAG_GENERIC);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu")) hTopMenu = null;
}

// Format very top level admin menu entry
public void Admin_TopPrezMenu(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayTitle, TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "-=BwA=- Protect The President");
		}
	}
}

// Handle the "Select a Prez" top menu item
public void Admin_SelectThePrez(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
			
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "Select a President");
		}
		case TopMenuAction_SelectOption:
		{
			Admin_ChooseThePrezMenu(param);	
		}			
	}
}

// Show the menu to select a player to be the Prez
void Admin_ChooseThePrezMenu(int client)
{		
	char title[100];
	
	Format(title, sizeof(title), "Select a President");
	
	Menu menu = CreateMenu(Admin_MnuHdlr_ChooseThePrez);	
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	char name[MAX_NAME_LENGTH];
	char mnuinfo[8];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidSurvivor(i, false))
		{
			IntToString(i, mnuinfo, 8); 
			Format(name, sizeof(name),  "%N", i); 
			AddMenuItem(menu, mnuinfo, name); 
		}	
	}
		
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

// Select a player to be the Prez
public int Admin_MnuHdlr_ChooseThePrez(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu != null)
			{
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			int target = StringToInt(info);
			if (target == 0)
			{
				PrintToChat(param1, "[SM]", "Player no longer available");
			}
			else
			{
				if (IsValidSurvivor(target, false) && ( target != thePrez))
				{
					RemoveThePrez();
					SetThePrez(target);
				}				
			}
		}	
	}
}

public Action Command_Enable(int client, int args)
{	
	if (!enabled)
	{
		enabled = true;
		Enable();
	}	
}

public Action Command_Disable(int client, int args)
{
	if (enabled)
	{
		enabled = false;
		Disable();
	}
}

void Enable()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_hurt", Player_Hurt);
	HookEvent("player_death", Player_Death);
	HookEvent("defibrillator_used", Shock_Success);
	HookEvent("player_now_it", Event_PlayerBoomed);
	HookEvent("player_no_longer_it", Event_PlayerNoLongerBoomed);
	HookEvent("player_team", Event_PlayerTeam);	
}

void Disable()
{
	UnhookEvent("round_start", Event_RoundStart);
	UnhookEvent("round_end", Event_RoundEnd);
	UnhookEvent("player_hurt", Player_Hurt);		
	UnhookEvent("player_death", Player_Death);
	UnhookEvent("defibrillator_used", Shock_Success);
	UnhookEvent("player_now_it", Event_PlayerBoomed);
	UnhookEvent("player_no_longer_it", Event_PlayerNoLongerBoomed);
	UnhookEvent("player_team", Event_PlayerTeam);
}

public void Event_RoundStart(Event event, char[] event_name, bool dontBroadcast)
{
	thePrez = 0;
	prezBoomed = false;
		
	CreateTimer(1.0, TimerLeftSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);	
}

public Action TimerLeftSafeRoom(Handle timer)
{
	if (LeftStartArea()) 
	{ 
		int prez = RandomCandidate((prezSelectionType.IntValue == 2), false);	
		if (prez == -1)
		{
			PrintToChatAll("Unable to get random survivor. \x05Protect The Prez\x01 is disabled");
			return;
		}
					
		SetThePrez(prez);
	}
	else
	{
		CreateTimer(1.0, TimerLeftSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock bool LeftStartArea()
{
	int maxents = GetMaxEntities();
	for (int i = MaxClients + 1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				if (GetEntProp(i, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
				{
					return true;
				}
			}
		}
	}
	return false;
}

void SetThePrez(int client)
{	
	ResetAll();
		
	prevPrez[client] = true;
	thePrez = client;
	SetClientColors(thePrez, GetClientHealth(thePrez));
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	StripWeapons(thePrez);
	if (!prezCanHeal.BoolValue) RemoveItemFromSlot(thePrez, WEP_SLOT_HEALTH);
	GiveHandgun(client, prezAllowMagnum.BoolValue); 
	SetEntDataFloat(thePrez, movementOffset, prezSpeedRatio.FloatValue, true);
	
	PrintHintTextToAll("The President \x05%N\x01 has been selected to serve. \n Survivors must protect him, his damage is their damage.", thePrez);		
}

public void Event_PlayerBoomed(Event event, char[] event_name, bool dontBroadcast)
{
	if (thePrez == 0) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == thePrez)
	{
		prezBoomed = true;
		SetClientColors(thePrez, GetClientHealth(thePrez));
	}
}

public void Event_PlayerNoLongerBoomed(Event event, char[] event_name, bool dontBroadcast)
{
	if ((thePrez == 0) || (!prezBoomed))
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == thePrez)
	{
		prezBoomed = false;
		SetClientColors(thePrez, GetClientHealth(thePrez));
	}
}

public void OnClientDisconnect(int client)
{
	if (client == thePrez)
	{ 
		ChangeThePrez(); 
	}
}

public void Event_PlayerTeam(Event event, char[] event_name, bool dontBroadcast) {

	if (thePrez == 0) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == thePrez)
	{
		if (event.GetBool("disconnect") || (GetClientTeam(client) != TEAM_SURVIVOR))
		{
			ChangeThePrez();
		}			
	}
}

void RemoveThePrez()
{		
	if (thePrez == 0) return;
	
	if (IsValidSurvivor(thePrez, false)) 
	{ 
		SetSkinColor(thePrez, PREZ_COLOR_NOCOLOR);
		SetGlowColor(thePrez, PREZ_COLOR_NOCOLOR);
		SetEntDataFloat(thePrez, movementOffset, 1.0 , true);
	}
	
	thePrez = 0;
}

void ResetAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidSurvivor(i, false)) 
		{
			SetSkinColor(i, PREZ_COLOR_NOCOLOR);
			SetGlowColor(i, PREZ_COLOR_NOCOLOR);
			SetEntDataFloat(i, movementOffset, 1.0 , true);
		}
	}
}
/*
void GetGlowDefaults(int client)
{
	dfltGlow = GetEntProp(client, Prop_Send, "m_iGlowType");
	dfltColor = GetEntProp(client, Prop_Send, "m_glowColorOverride");
	dfltRange = GetEntProp(client, Prop_Send, "m_nGlowRange");
	dfltFlash = GetEntProp(client, Prop_Send, "m_bFlashing");

	PrintToChatAll("Glow = %d, Color = %d, Range = %d, Flash = %d", dfltGlow, dfltColor, dfltRange, dfltFlash);			
}
*/
void SetGlowDefaults(int client)
{
	SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
	SetEntProp(client, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(client, Prop_Send, "m_bFlashing", 0);	
}

void ChangeThePrez()
{
	RemoveThePrez();
				
	int prez = RandomCandidate((prezSelectionType.IntValue == 2), false);
	if (prez == -1)
	{
		thePrez = 0;
		PrintToChatAll("Unable to get random survivor. \x05Protect The Prez\x01 is disabled");
	}
	else
	{
		SetThePrez(prez);
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{	
	prezRevived = true;
	prezBoomed = false;
	
	RemoveThePrez();
	
	ResetAll();	
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if (client != thePrez) return Plugin_Continue;

	char wepclassname[32];
	GetEdictClassname(weapon, wepclassname, sizeof(wepclassname));

	//PrintToChatAll("Picked up %s", 	wepclassname);
	if (prezAllowAllItems.BoolValue) return Plugin_Continue;
	else
	{
		if (StrEqual("weapon_pistol", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_pistol_magnum", wepclassname, false))
		{
			if(prezAllowMagnum.BoolValue) return Plugin_Continue;
		}
		else if (StrEqual("weapon_first_aid_kit", wepclassname, false))
		{
			if (prezCanHeal.BoolValue) return Plugin_Continue;
		}
		else if (StrEqual("weapon_pipe_bomb", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_molotov", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_vomitjar", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_pain_pills", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_adrenaline", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_defibrillator", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_gascan", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_propanetank", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_oxygentank", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_fireworkcrate", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_upgradepack_explosive", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_upgradepack_incendiary", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_gnome", wepclassname, false))
		{
			return Plugin_Continue;
		}
		else if (StrEqual("weapon_cola_bottles", wepclassname, false))
		{
			return Plugin_Continue;
		}
	}
	return Plugin_Handled;
}

void StripWeapons(int client)
{
	RemoveItemFromSlot(client, WEP_SLOT_PRIMARY);
	RemoveItemFromSlot(client, WEP_SLOT_MELEE);	
	if (!prezCanHeal.BoolValue)  RemoveItemFromSlot(client, WEP_SLOT_HEALTH);
}

stock void RemoveItemFromSlot(int client, int slot)
{
	int ent = GetPlayerWeaponSlot(client, slot);
	if( ent != -1 )
	{
		RemovePlayerItem(client, ent);
		//AcceptEntityInput(ent, "kill");
		//RemoveEdict(ent);
	}
}

void GiveHandgun(int client, bool giveMagnum)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	if (giveMagnum)
	{
		FakeClientCommand(client, "give pistol_magnum");
	}
	else
	{
		FakeClientCommand(client, "give pistol");
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public Action Command_SelectPrez(int client, int args)
{
	char arg1[4];
	GetCmdArg(1, arg1, 4);
	int prez = StringToInt(arg1);
	if (IsValidSurvivor(prez, false) && ( prez != thePrez))
	{
		RemoveThePrez();
		SetThePrez(prez);
	}
	return Plugin_Handled;
}

void SetClientColors(int client, int health)
{
	if (IsIncapped(client) || IsHangingFromLedge(client))
	{
		SetSkinColor(client, PREZ_COLOR_LOWHEALTH);
		SetGlowColor(client, PREZ_COLOR_LOWHEALTH);
		return;
	}
		
	if (health < 25) 
	{
		SetSkinColor(client, PREZ_COLOR_LOWHEALTH);
		SetGlowColor(client, PREZ_COLOR_LOWHEALTH);	
	}
	else if (health < 40)
	{
		SetSkinColor(client, PREZ_COLOR_MEDHEALTH);
		SetGlowColor(client, PREZ_COLOR_MEDHEALTH);	
	}
	else
	{	
		SetSkinColor(client, PREZ_COLOR_FULLHEALTH);
		SetGlowColor(client, PREZ_COLOR_FULLHEALTH);	
	}
}

void SetSkinColor(int client, int prezcolor)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, skinRed[prezcolor], skinGreen[prezcolor], skinBlue[prezcolor], 255);		
}

void SetGlowColor(int client, int prezcolor)
{	
	if (prezcolor == PREZ_COLOR_NOCOLOR)
	{
		SetGlowDefaults(client);
		return;
	}
		
	int gcolor = prezBoomed ? glowColor[PREZ_COLOR_BOOMED] : glowColor[prezcolor] ;
			
	SetEntProp(client, Prop_Send, "m_iGlowType", 3);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", gcolor);
	SetEntProp(client, Prop_Send, "m_nGlowRange", 2048);
	SetEntProp(client, Prop_Send, "m_bFlashing", 1);
		
}

public Action Player_Hurt(Event event, char[] event_name, bool dontBroadcast) {

	int userid = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(userid, true)) return;
	
	// Don't forward or modify damage for incapped players
	if (IsIncapped(userid) || IsHangingFromLedge(userid)) 
	{ 
		if (thePrez == userid) SetClientColors(thePrez, GetClientHealth(thePrez));
		return; 
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	// If damage is friendly fire, leave it alone
	if (IsValidSurvivor(attacker, true)) 
	{ 
		if (thePrez == userid) SetClientColors(thePrez, GetClientHealth(thePrez));
		return; 
	}
	
	int dmg = event.GetInt("dmg_health");
	int health = event.GetInt("health");
	// Get the healthe before damage
	int totalhealth = ((health + dmg) > 100) ? 100 : (health + dmg);
	
	// The Prez was hurt, hurt everyone
	if (thePrez == userid) 
	{ 
		int team_dmg = RoundToCeil(float(dmg) * teamDmgRatio.FloatValue);
		DamageTeam(team_dmg, thePrez); 
		int prezdmg = RoundToCeil(float(dmg) / prezHealthRatio.FloatValue);		
		int preztotal = ((totalhealth - prezdmg) < 1) ? 1 : (totalhealth - prezdmg);
		SetEntityHealth(userid, preztotal);
		SetClientColors(thePrez, preztotal);	
	}
	else
	{	
		int nrmldmg = RoundToCeil(float(dmg) * normalDmgRatio.FloatValue);				
		int total = ((totalhealth - nrmldmg) < 1) ? 1 : (totalhealth - nrmldmg);	
		SetEntityHealth(userid, total);
	}
}	

void DamageTeam(int damage, int exception)
{
	if (damage == 0) return;
	
	int health = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidSurvivor(i, true) && (exception != i))
		{
			if (!IsIncapped(i) && !IsHangingFromLedge(i))
			{
				health = GetSurvivorPermanentHealth(i);
				int total = ((health - damage) < 1) ? 1 : (health - damage);								
				SetEntityHealth(i, total);
			}
		}
	}
}

public Action Shock_Success(Event event, const char[] name, bool dontBroadcast)
{
	int revived = GetClientOfUserId(event.GetInt("subject"));
	if (IsValidSurvivor(revived, false) && (revived == thePrez))
	{
		prezRevived = true;
		PrintToChatAll("The President has been saved. Yay you!");
	}
}

public Action Player_Death(Event event, char[] event_name, bool dontBroadcast)
{
	int deadman = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidSurvivor(deadman, false) && (deadman == thePrez))
	{
		if(prezDeathBlockDoor.BoolValue)
		{
			OpenAndLockDoor();
		}
		prezRevived = false;
		deathTicks = prezDefibTime.IntValue;
		PrintToChatAll("The President has been killed. You have %i seconds to defibrillate him", deathTicks);
		CreateTimer(0.1, PrezDeathTimer, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action PrezDeathTimer(Handle timer)
{	
	if (prezRevived) 
	{
		if(prezDeathBlockDoor.BoolValue)
		{
			UnlockDoor(lockedDoor);
		}
		return Plugin_Stop; 
	}
	
	if (deathTicks > 15)
	{
		PrintToChatAll("The President will be irrevocably dead in %i seconds", deathTicks);
		deathTicks -= 5;
		CreateTimer(5.0, PrezDeathTimer, 0, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}
	else if (deathTicks > 0)
	{   
		// Don't need to announce 13, 12, etc...
		if (deathTicks <= 10) PrintToChatAll("The President will be irrevocably dead in %i seconds", deathTicks);
		deathTicks--;
		CreateTimer(1.0, PrezDeathTimer, 0, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}
	else
	{
		KillSurvivors(thePrez);
		return Plugin_Stop;
	}
}

stock void KillSurvivors(int exclude)
{	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == exclude) continue;

		if(IsClientInGame(i) && IsClientConnected(i) && (GetClientTeam(i) == TEAM_SURVIVOR))
		{
			ForcePlayerSuicide(i);
		}	
	}
}

stock int GetSurvivorPermanentHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");	
}

stock bool IsIncapped(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1);
}

stock bool IsHangingFromLedge(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 1);
}

stock bool IsValidSurvivor(int client, bool allowbots)
{
	if ((client < 1) || (client > MaxClients))
		return false;
	if (!IsClientInGame(client) || !IsClientConnected(client))
		return false;
	if (GetClientTeam(client) != TEAM_SURVIVOR) return false;
	if (IsFakeClient(client) && !allowbots) return false;
	return true;
}

// Get the first survivor (player or bot, doesn't matter)
stock int RandomCandidate(bool excludeprev, bool allowbots)
{
	int numSurvs = GetSurvivorCount() - GetPrevPrezCount();
	// If no new ones left, reset
	if (numSurvs <= 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidSurvivor(i, allowbots) && ( GetClientTeam(i) == TEAM_SURVIVOR))
			{
				prevPrez[i] = false;
			}
		}
		numSurvs = GetSurvivorCount();
	}
	
	int rndsurv = CreateRandomInt(1, numSurvs);
	int curr = 1;
	for (int i = 1; i <= MaxClients; i++)
	{
		// If they have already been prez, skip them if indicated
		if (excludeprev && prevPrez[i]) continue;

		if (IsValidSurvivor(i, allowbots))
		{	
			if (curr == rndsurv) return i;
			curr++;
		}
	}

	return -1;
}

int GetPrevPrezCount()
{	
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidSurvivor(i, false))
		{
			if (prevPrez[i] && GetClientTeam(i) == TEAM_SURVIVOR)
			{
				count++;
			}
		}
	}
	return count;
}

stock int GetSurvivorCount()
{			
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{	
		if (IsValidSurvivor(i, false)) count++;
	}
	return count;
}

stock int CreateRandomInt(int min, int max)
{
	SetRandomSeed(RoundFloat(GetEngineTime() * 1000.0 * float(max)));
	return GetRandomInt(min, max);	
}

public Action Command_Lock(int client, int args)
{
	OpenAndLockDoor();
}

public Action Command_Unlock(int client, int args)
{
	UnlockDoor(lockedDoor);
}

// Do this upon the Prez's incap/death
void OpenAndLockDoor()
{
	int ent = -1;
	// Finishing safe room door does not have an unlock sequence by default
	while ((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1)
	{
		if (GetEntProp(ent, Prop_Data, "m_hasUnlockSequence") == 0)
		{
			lockedDoor = ent;
			AcceptEntityInput(lockedDoor, "Open");
			AcceptEntityInput(lockedDoor, "Lock");
			SetEntProp(lockedDoor, Prop_Data, "m_hasUnlockSequence", 1);
			break;
		}
	}
}

void UnlockDoor(int door)
{
	if (door > 0)
	{
		SetEntProp(door, Prop_Data, "m_hasUnlockSequence", 0);
		AcceptEntityInput(door, "Unlock");
	}
}
