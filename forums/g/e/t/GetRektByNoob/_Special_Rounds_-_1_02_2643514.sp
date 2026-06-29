#pragma semicolon 1

//	#define DEBUG

#define PREFIX " \x05 [Special Rounds]\x01"
#define PLUGIN_AUTHOR "GetRektByNoob"
#define PLUGIN_VERSION "1.02"

#include <sourcemod>
#include <sdktools>
//	#include <cstrike>
#include <sdkhooks>

#pragma newdecls required

// Saves All The Active Modes, Saved By Strings.
ArrayList al_ModesNames;

// KeyValues
char kv_Settings[PLATFORM_MAX_PATH];

// The Mode Is Currenly Active, Saved By Strings.
char c_ActiveMode[32];

char c_ModesNames[][] = {
	"HeadShot Only",
	"Random HP",
	"Knifes Only",
	"Shotguns Only",
	"Rifles Only",
	"Pistols Only",
	"SMGs Only",
	"Space Round"};

// Weapons & IDs
char cw_ShotGuns[][32] = {
	"weapon_nova",
	"weapon_sawedoff",
	"weapon_xm1014",
	"weapon_mag7"
};

int id_ShotGuns[] =  {
	35,
	29,
	25,
	27
};

char cw_Rifles[][32] = {
	"weapon_m4a1",
	"weapon_m4a1_silencer",
	"weapon_ak47",
	"weapon_famas",
	"weapon_galilar",
	"weapon_sg556", "weapon_aug"
};

int id_Rifles[] =  {
	16,
	60,
	7,
	10,
	13,
	39,
	8
};

char cw_Pistols[][32] = {
	"weapon_usp_silencer",
	"weapon_deagle",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_glock",
	"weapon_hkp2000",
	"weapon_p250",
	"weapon_tec9",
	"weapon_cz75a",
	"weapon_revolver"
};

int id_Pistols[] =  {
	61,
	1,
	2,
	3,
	4,
	32,
	36,
	30,
	63,
	64
};

char cw_SMGs[][32] = {
	"weapon_mp5sd",
	"weapon_mp7",
	"weapon_bizon",
	"weapon_mac10",
	"weapon_mp9",
	"weapon_p90",
	"weapon_ump45"
};

int id_SMGs[] =  {
	23,
	33,
	26,
	17,
	34,
	19,
	24
};

// saves the weapon choosen from the list , use for all weapons rounds.
char c_CurrentWeapon[32];
char info[32];
// Forced Mode For Next Round.
char ForcedMode[32];

bool Forced = false;

// useless
int style = 0;
// Keeps the weapon index in the array
int WeaponIndex;
// Enable / Disable Plugin
ConVar cv_Chance;
// Set Chance for special round
ConVar cv_Enable;
// set gravity
ConVar cv_Gravity;
// For "Random HP" day
ConVar cv_MaxHealth;
// For "Random HP" day
ConVar cv_MinHealth;
// Toggle knifes only with or without zeus
ConVar cv_KnifeWithZeus;
ConVar cv_HeadShot;
ConVar cv_InfiniteAmmo;

Menu Settings;
Menu Info;
Menu Force;

public Plugin myinfo = {
	name = "[Special Rounds]",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198805764302/"
};

public void OnPluginStart() {
	// Settings
	al_ModesNames = new ArrayList(ByteCountToCells(32));

	// Info Menu
	Settings = new Menu(SettingsHandler);
	Info = new Menu(InfoHandler);
	Info.SetTitle("Special Round Info");
	Info.AddItem("", "General", style);

	for (int i = 0; i < sizeof(c_ModesNames); i++) {
		Info.AddItem("", c_ModesNames[i], style);
	}

	// Force Menu
	Force = new Menu(ForceHandler);
	Force.SetTitle("Special Round Force");
	for (int i = 0; i < sizeof(c_ModesNames); i++) {
		Force.AddItem("", c_ModesNames[i], style);
	}

	Force.AddItem("", "Cancel", style);

	// Events
	HookEvent("round_start", RoundStart);
	HookEvent("weapon_fire", WeaponFire);
	HookEvent("item_pickup", PickUp, EventHookMode_Pre);

	// Custom Convars
	cv_Enable = CreateConVar("sr_enable", "1", "1 = Enable / 0 = Disable The Plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	cv_Chance = CreateConVar("sr_chance", "25", "The Chance Of Activating Speciall Round", FCVAR_NONE, true, 0.0, true, 100.0);
	cv_MaxHealth = CreateConVar("sr_max_hp", "200", "Set the max amout of health can be in Random HP", FCVAR_NONE, true, 10.0, true, 500.0);
	cv_MinHealth = CreateConVar("sr_min_hp", "50", "Set the min amout of health can be in Random HP", FCVAR_NONE, true, 10.0, true, 500.0);
	cv_Gravity = CreateConVar("sr_Gravity", "0.5", "Set the gravity in the space day (1 = default)", FCVAR_NONE, true, 0.0, true, 1.0);
	cv_KnifeWithZeus = CreateConVar("sr_wZeus", "0", "If the Knife only mode can also have zeus.", FCVAR_NONE, true, 0.0, true, 1.0);

	cv_Enable.AddChangeHook(ConVarChange_Enable);

	// defualt Convars
	// For "HeadShot Only".
	cv_HeadShot = FindConVar("mp_damage_headshot_only");
	// For only one weapon Modes.
	cv_InfiniteAmmo = FindConVar("sv_infinite_ammo");

	// Commands
	RegConsoleCmd("sm_srinfo", Command_InfoMenu, "Opens info menu");
	RegConsoleCmd("sm_srmode", Command_Mode, "Says if there is a special round or no");
	RegConsoleCmd("sm_srversion", Command_Version, "Gives the plugin version");
	RegAdminCmd("sm_srset", Command_SetttingsMenu, ADMFLAG_GENERIC, "Settings Command [✗ = Disabled] | [✓ = Enabled]");
	RegAdminCmd("sm_srforce", Command_ForceSR, ADMFLAG_GENERIC, "Force special round.");
	RegAdminCmd("sm_srsave", Command_ForceSave, ADMFLAG_GENERIC, "Force the plugin to save it current settings.");
	RegAdminCmd("sm_srload", Command_ForceLoad, ADMFLAG_GENERIC, "Force the plugin to save it current settings.");
	
	/*
	// Check Commands
	RegConsoleCmd("sm_pistol", Check_Pistol, "Give Pistol");
	RegConsoleCmd("sm_rifle", Check_Rifle, "Give Rifle");
	RegConsoleCmd("sm_grenade", Check_Grenade, "Give Grenade");
	RegConsoleCmd("sm_test", Check_Test, "");
	*/
	
	// Key Values
	SetupSettingsFile();
}

////////////////////////////////////////////////////////
// 	                   Events                         //
////////////////////////////////////////////////////////

public void WeaponFire(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	char wepName[32];
	event.GetString("weapon", wepName, sizeof(wepName));

	if (cv_Enable.IntValue == 1 && cv_KnifeWithZeus.IntValue && StrEqual(wepName, "weapon_taser", false)) {
		CreateTimer(0.5, GiveZeus, client, TIMER_HNDL_CLOSE);
	}
}


public Action PickUp(Event event, const char[] name, bool dontBroadcast) {
    int wepID = event.GetInt("defindex", -1);
 
    if (cv_Enable.IntValue == 0 || StrEqual(c_ActiveMode,"", false) || StrEqual(c_ActiveMode,"HeadShot Only", false) || StrEqual(c_ActiveMode,"Random HP", false)) {
        return Plugin_Handled;
    }
    else if (wepID == 42 || wepID == 41) {
        return Plugin_Continue;
    }
 
	else 
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		int PriWep, SecWep;

		if (StrEqual(c_ActiveMode ,"Knifes Only", false)) {
			ClearPlayer(client , 2);
			if (GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon") == -1) {
				FakeClientCommand(client, "use weapon_knife");
			}
		}
		
		else if (StrEqual(c_ActiveMode, "Space Round", false) && wepID != 40) {
			ClearPlayer(client , 0);
			PriWep = GetPlayerWeaponSlot(client, 0);
			if (PriWep != -1 && GetEntProp(PriWep, Prop_Send , "m_iItemDefinitionIndex") != 40) {
				RemovePlayerItem(client, PriWep);
				GivePlayerItem(client, "weapon_ssg08");
			}
		}
		
		else if (StrEqual(c_ActiveMode ,"Shotguns Only", false)) {
			ClearPlayer(client , 0);
			PriWep = GetPlayerWeaponSlot(client, 0);
			if (PriWep != -1 && GetEntProp(PriWep, Prop_Send , "m_iItemDefinitionIndex") != id_ShotGuns[WeaponIndex]) {
				RemovePlayerItem(client, PriWep);
				GivePlayerItem(client, cw_ShotGuns[WeaponIndex]);
			}
		}
		
		else if (StrEqual(c_ActiveMode ,"Pistols Only", false)) {
			ClearPlayer(client , 1);
			SecWep = GetPlayerWeaponSlot(client, 1);
			if (SecWep != -1 && GetEntProp(SecWep, Prop_Send , "m_iItemDefinitionIndex") != id_Pistols[WeaponIndex]) {
				RemovePlayerItem(client, SecWep);
				GivePlayerItem(client, cw_Pistols[WeaponIndex]);
			}
		}
		
		else if (StrEqual(c_ActiveMode ,"Rifles Only", false)) {
			ClearPlayer(client , 0);
			PriWep = GetPlayerWeaponSlot(client, 0);
			if (PriWep != -1 && GetEntProp(PriWep, Prop_Send , "m_iItemDefinitionIndex") != id_Rifles[WeaponIndex]) {
				RemovePlayerItem(client, PriWep);
				GivePlayerItem(client, cw_Rifles[WeaponIndex]);
			}
		}
		
		else if (StrEqual(c_ActiveMode ,"SMGs Only", false)) {
			ClearPlayer(client , 0);
			PriWep = GetPlayerWeaponSlot(client, 0);
			if (PriWep != -1 && GetEntProp(PriWep, Prop_Send , "m_iItemDefinitionIndex") != id_SMGs[WeaponIndex]) {
				RemovePlayerItem(client, PriWep);
				GivePlayerItem(client, cw_SMGs[WeaponIndex]);
			}
		}
	}

    return Plugin_Continue;
}

public void ClearPlayer(int client , int Mode) {
	/*
	Modes :
	0 - WithOut Primary Weapon.
	1 - WithOut Secondry Weapon.
	2 - WithOut Knife Slot.
	*/

	int wpnIndex = -1;

	for (int slot = 0; slot < 5; slot++) {
		while (slot != Mode &&(wpnIndex = GetPlayerWeaponSlot(client, slot)) != -1) {
			RemovePlayerItem(client, wpnIndex);
		}
	}
	
	if(Mode != 2)
		GivePlayerItem(client, "weapon_knife");
}

public void RoundStart(Event event, const char[] name, bool dontBroadcast) {
	if (cv_Enable.IntValue == 1) {
		ResetSettings();
		
		if(Forced) {
			c_ActiveMode = ForcedMode;
			Forced = false;
			SetUpSpeciallRound();
		}
		
		else {
			if(al_ModesNames.Length == 0) {
				for (int i = 1; i <= MaxClients; i++)
					if(IsClientInGame(i) && CheckCommandAccess(i, "admins", ADMFLAG_GENERIC, true))
						PrintToChat(i, "%s \x07Error : \x01There isn't any enabled modes. use \x07/srset \x01to enable some.", PREFIX);
			}
			
			else {
				int i_Chance = cv_Chance.IntValue;
				int i_RndChanceNum = GetRandomInt(0, 100);
				
				if(i_RndChanceNum <= i_Chance) {
					al_ModesNames.GetString(GetRandomInt(0, al_ModesNames.Length - 1), c_ActiveMode, sizeof(c_ActiveMode));
					SetUpSpeciallRound();
				}
			}
		}
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]) {
	/* Check if its special round if not continue
	if yes check if the damage is by grenade if yes
	stop it , if no check if they are using the correct gun
	if no stop it if yes continue*/
	
	if (cv_Enable.IntValue == 0 || StrEqual(c_ActiveMode,"", false) || StrEqual(c_ActiveMode,"Random HP", false)) {
		return Plugin_Continue;
	}
	// 8 = Molotor | 64 = HE Grenade | 128 Grenade Impact
	if (damagetype & (8|64|128)) {
		return Plugin_Handled;
	}

	if (IsValidEntity(weapon)) {
		int wepID = GetEntProp(weapon, Prop_Send , "m_iItemDefinitionIndex");

		if (StrEqual(c_ActiveMode ,"HeadShot Only", false)) {
			if (CheckKnife(wepID , false)) {
				return Plugin_Handled;
			}
		}
		
		else if (StrEqual(c_ActiveMode ,"Knifes Only", false)) {
			if (cv_KnifeWithZeus.IntValue == 1) {
				if (!CheckKnife(wepID , true)) {
					return Plugin_Handled;
				}
			} else {
				if (!CheckKnife(wepID , false)) {
					return Plugin_Handled;
				}
			}
		}
		
		else if (StrEqual(c_ActiveMode, "Space Round", false)) {
			if (!CheckWeapon(wepID, 40)) {
				return Plugin_Handled;
			}
		}
		
		else if (StrEqual(c_ActiveMode ,"Shotguns Only", false)) {
			if (!CheckWeapon(wepID, id_ShotGuns[WeaponIndex])) {
				return Plugin_Handled;
			}
		}
		
		else if (StrEqual(c_ActiveMode ,"Pistols Only", false)) {
			if (!CheckWeapon(wepID, id_Pistols[WeaponIndex])) {
				return Plugin_Handled;
			}
		}
		
		else if (StrEqual(c_ActiveMode ,"Rifles Only", false)) {
			if (!CheckWeapon(wepID, id_Rifles[WeaponIndex])) {
				return Plugin_Handled;
			}
		}
		
		else if (StrEqual(c_ActiveMode ,"SMGs Only", false)) {
			if (!CheckWeapon(wepID , id_SMGs[WeaponIndex])) {
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

////////////////////////////////////////////////////////
//                   Commands                         //
////////////////////////////////////////////////////////

public Action Command_SetttingsMenu(int client , int args) {
	if(!IsClientInGame(client) && 0 < client && client <= MaxClients)
		return Plugin_Handled;
	
	SetupSettingsFileMenu();
	Settings.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_InfoMenu(int client , int args) {
	if(!IsClientInGame(client) && 0 < client && client <= MaxClients)
		return Plugin_Handled;
		
	Info.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_ForceSR(int client, int args) {
	if(!IsClientInGame(client) && 0 < client && client <= MaxClients)
		return Plugin_Handled;
	
	if (cv_Enable.IntValue == 1) {
		Force.Display(client, MENU_TIME_FOREVER);
	}
	else {
		PrintToChat(client, "%s The plugin is currenly \x07disabled\x01.", PREFIX);
	}

	return Plugin_Handled;
}

public Action Command_Mode(int client, int args) {
	if(!IsClientInGame(client) && 0 < client && client <= MaxClients)
		return Plugin_Handled;
	
	if (StrEqual(c_ActiveMode, "", false)) {
		PrintToChat(client, "%s There is no \x07Special Round \x01at this moment.", PREFIX);
	}
	else {
		PrintToChat(client, "%s The current mode that is active is \x07%s \x01.", PREFIX, c_ActiveMode);
	}

	return Plugin_Handled;
}

public Action Command_ForceSave(int client, int args) {
	if(IsClientInGame(client) && 0 < client && client <= MaxClients)
		PrintToChat(client, "%s The plugin settings has been \x06successfully \x01saved.", PREFIX);
	else 
		PrintToServer("The plugin settings has been successfully saved.");
		
	SaveSettings();
	return Plugin_Handled;
}

public Action Command_Version(int client, int args) {
	PrintToChat(client, "%s Plugin Version : \x07%s\x01, Made By \x07%s\x01.", PREFIX, PLUGIN_VERSION, PLUGIN_AUTHOR);
	return Plugin_Handled;
}

public Action Command_ForceLoad(int client , int args) {
	if(IsClientInGame(client) && 0 < client && client <= MaxClients)
		PrintToChat(client, "%s The plugin settings has been \x06successfully \x01loaded.", PREFIX);
	else 
		PrintToServer("The plugin settings has been successfully loaded.");
		
	LoadSettings();
	return Plugin_Handled;
}

/*
// Debug Commands
public Action Check_Pistol(int client, int args) { GivePlayerItem(client, "weapon_glock"); }
public Action Check_Rifle(int client, int args) { GivePlayerItem(client, "weapon_ak47"); } 
public Action Check_Grenade(int client, int args) { GivePlayerItem(client, "weapon_hegrenade"); }
public Action Check_Test(int client, int args){
	PrintToChat(client, "Currect : %s | Forced : %s | ArrayLength : %d", c_ActiveMode, ForcedMode, al_ModesNames.Length);
	if(Forced)
		PrintToChat(client, "Mode Is Forced!");
	else
		PrintToChat(client, "Mode Is Not Forced!");
}
*/

////////////////////////////////////////////////////////
//                   Handlers                         //
////////////////////////////////////////////////////////

public Action GiveZeus(Handle timer, int client) {
	GivePlayerItem(client, "weapon_taser");
}

public int SettingsHandler(Menu menu, MenuAction action , int param1 , int param2) {
	if (action == MenuAction_Select) {
		char PosName[32];
		menu.GetItem(param2, info, sizeof(info), style, PosName, sizeof(PosName));

		if (StrEqual(info,"1", false)) {
			al_ModesNames.Erase(al_ModesNames.FindString(c_ModesNames[param2]));
		}
		else {
			al_ModesNames.PushString(c_ModesNames[param2]);
		}

		SetupSettingsFileMenu();
		menu.Display(param1, MENU_TIME_FOREVER);
	}
}

public int InfoHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		Messages(param1, param2);
	}
}

public int ForceHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		menu.GetItem(param2, info, sizeof(info), style, ForcedMode, sizeof(ForcedMode));
		char Name[MAX_NAME_LENGTH];
		GetClientName(param1, Name, sizeof(Name));

		if (StrEqual(ForcedMode, "Cancel", false)) {
			Forced = false;
			PrintToChatAll("%s \x07%s \x01has \x07Canceled \x01the special round for next round.", PREFIX, Name);
		}
		else {
			Forced = true;
			PrintToChatAll("%s \x07%s \x01has started a \x07%s \x01for next round.", PREFIX , Name, ForcedMode);
		}
	}
}

Action TextOnScreen(Handle timer, int client) {
	if (!IsClientInGame(client)) {
		return Plugin_Stop;
	}

	SetHudTextParams(-1.0, 0.18, 10.0, 15, 25, 250, 255);
	ShowHudText(client, 1, "Special Round Has Started!");
	SetHudTextParams(-1.0, 0.21, 10.0, 15, 25, 250, 255);
	ShowHudText(client, 6, "Mode : %s", c_ActiveMode);
	return Plugin_Stop;
}

////////////////////////////////////////////////////////
//                  Functions                         //
////////////////////////////////////////////////////////

public bool CheckKnife(int wepID, bool isZeus){
	if(isZeus){
		if(CheckWeapon(wepID, 42) || CheckWeapon(wepID, 41) || CheckWeapon(wepID, 31) || wepID >= 500 && wepID <= 523)
			return true;
		return false;
	} else {
		if(CheckWeapon(wepID, 42) || CheckWeapon(wepID, 41) || wepID >= 500 && wepID <= 523)
			return true;
		return false;
	}
}

public void ConVarChange_Enable(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (StringToInt(oldValue) == 1 && StringToInt(newValue) == 0) {
		ServerCommand("mp_restartgame 1");
		ResetSettings();
	}
}

public void SetupSettingsFileMenu() {
	/* Remove all item from menu
	then check all the modes in the arraylist
	if the mode is found in the array list
	then the mode is active otherwise
	its not*/

	Settings.SetTitle("Special Rounds Settings");
	Settings.RemoveAllItems();

	for (int i = 0; i < sizeof(c_ModesNames); i++) {
		char X[32], Check[32];

		Format(X, sizeof(X), "[✗] %s", c_ModesNames[i]);
		Format(Check, sizeof(Check),"[✓] %s", c_ModesNames[i]);

		if (al_ModesNames.FindString(c_ModesNames[i]) != -1) {
			Settings.AddItem("1", Check);
		}
		else {
			Settings.AddItem("0", X);
		}
	}
}

public bool CheckWeapon(int wepID, int CurrentWepID) {
	return wepID == CurrentWepID;
}

public void SetUpSpeciallRound() {
	// Text on screen
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client)) {
			CreateTimer(0.1, TextOnScreen, client);
		}
	}

	// Message in chat
	PrintToChatAll(" \x08========================");
	PrintToChatAll("   \x07Special Round \x01has started. ");
	PrintToChatAll("   \x01Round Mode : \x07%s\x01.", c_ActiveMode);
	PrintToChatAll("   Use \x07/srinfo \x01for more info. ");
	PrintToChatAll(" \x08========================");

	// Setup the special round correctly;
	if (StrEqual(c_ActiveMode,"HeadShot Only", false)) {
		cv_HeadShot.SetInt(1);
		return;
	}
	if (StrEqual(c_ActiveMode,"Random HP", false)) {
		int NewHealth;

		if (cv_MaxHealth.IntValue < cv_MinHealth.IntValue) {
			NewHealth = GetRandomInt(50, 200);
			PrintToServer("Error : The value of the convar cv_MaxHealth is lower than the convar cv_MinHealth!");
			LogError("Error : The value of the convar cv_MaxHealth is lower than the convar cv_MinHealth!");
		}
		else {
			NewHealth = GetRandomInt(cv_MinHealth.IntValue, cv_MaxHealth.IntValue);
		}

		for (int client = 1; client <= MaxClients; client++) {
			if (ClientValidAndAlive(client)) {
				SetEntityHealth(client, NewHealth);
			}
		}

		return;
	}
	if (StrEqual(c_ActiveMode, "Space Round", false)) {
		c_CurrentWeapon = "weapon_ssg08";

		for (int client = 1; client <= MaxClients; client++) {
			if (ClientValidAndAlive(client)) {
				SetEntityGravity(client, cv_Gravity.FloatValue);
			}
		}
	}
	else if (StrEqual(c_ActiveMode, "Knifes Only", false)) {
		c_CurrentWeapon = "weapon_knife";
	}
	else if (StrEqual(c_ActiveMode, "Shotguns Only", false)) {
		WeaponIndex = GetRandomInt(0, sizeof(cw_ShotGuns) - 1);
		c_CurrentWeapon = cw_ShotGuns[WeaponIndex];
	}
	else if (StrEqual(c_ActiveMode, "Rifles Only", false)) {
		WeaponIndex = GetRandomInt(0, sizeof(cw_Rifles) - 1);
		c_CurrentWeapon = cw_Rifles[WeaponIndex];
	}
	else if (StrEqual(c_ActiveMode, "Pistols Only", false)) {
		WeaponIndex = GetRandomInt(0, sizeof(cw_Pistols) - 1);
		c_CurrentWeapon = cw_Pistols[WeaponIndex];
	}
	else if (StrEqual(c_ActiveMode, "SMGs Only", false)) {
		WeaponIndex = GetRandomInt(0, sizeof(cw_SMGs) - 1);
		c_CurrentWeapon = cw_SMGs[WeaponIndex];
	}

	ResetPlayers();
	GiveWeapon();
}

public void ResetSettings() {
	c_CurrentWeapon = "";
	c_ActiveMode = "";
	
	GameRules_SetProp("m_bTCantBuy", false, _, _, true);
	GameRules_SetProp("m_bCTCantBuy", false, _, _, true);
	cv_InfiniteAmmo.SetInt(0, true, false);
	cv_HeadShot.SetInt(0);

	if (StrEqual(c_ActiveMode, "Space Round", false)) {
		for (int client = 1; client <= MaxClients; client++) {
			if (ClientValidAndAlive(client)) {
				SetEntityGravity(client, 1.0);
			}
		}
	}
}

public bool ClientValidAndAlive(int client) {
	return IsClientInGame(client) && IsPlayerAlive(client);
}

public void ResetPlayers() {
	cv_InfiniteAmmo.SetInt(2, true, false);

	GameRules_SetProp("m_bTCantBuy", true, _, _, true);
	GameRules_SetProp("m_bCTCantBuy", true, _, _, true);

	for (int client = 1; client <= MaxClients; client++) {
		if (!ClientValidAndAlive(client)) {continue;
		}

		// Clear Inventory.
		for (int slot = 0; slot < 5; slot++)  {
			int wpnIndex = -1;
			while ((wpnIndex = GetPlayerWeaponSlot(client, slot)) != -1) {RemovePlayerItem(client, wpnIndex);
			}
		}

		// Remove Armor.
		SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);
	}
}

public void GiveWeapon() {
	for (int i = 1; i <= MaxClients; i++) {
		if (ClientValidAndAlive(i)) {
			GivePlayerItem(i, c_CurrentWeapon);

			if (!StrEqual(c_CurrentWeapon, "weapon_knife", false)) {
				GivePlayerItem(i, "weapon_knife");
			}

			else if (cv_KnifeWithZeus.IntValue == 1) {
				GivePlayerItem(i, "weapon_taser");
			}
		}
	}
}

public void Messages(int client, int MessageIndex) {
	switch(MessageIndex) {
		case 0: {
			PrintToChat(client," \x08========================");
			PrintToChat(client," \x07Special Day \x01is a random");
			PrintToChat(client," event that can start randomly");
			PrintToChat(client, " at the begining of a new round.");
			PrintToChat(client," \x08========================");
		}
		case 1: {
			PrintToChat(client," \x08========================");
			PrintToChat(client," \x07HeadShot Only \x01its");
			PrintToChat(client," a round where the only way to kill");
			PrintToChat(client, " someone is by headshotting him.");
			PrintToChat(client," \x08========================");
		}
		case 2: {
			PrintToChat(client," \x08=============================");
			PrintToChat(client," \x07Random HP \x01everyone's");
			PrintToChat(client," health get set to random number.");
			PrintToChat(client," \x07Everyone gets the amount of heath!");
			PrintToChat(client," \x08=============================");
		}
		case 3: {
			PrintToChat(client," \x08=============================");
			PrintToChat(client," \x07Knifes Only \x01its a round");
			PrintToChat(client," where the only weapon there is");
			PrintToChat(client," is a knife.");
			PrintToChat(client," \x08=============================");
		}
		case 4: {
			PrintToChat(client, " \x08=============================");
			PrintToChat(client," \x07Shotguns Only \x01its a around");
			PrintToChat(client," everyone gets random shotgut.");
			PrintToChat(client," \x07Everyone gets the same shotgun!");
			PrintToChat(client," \x08=============================");
		}
		case 5: {
			PrintToChat(client," \x08=============================");
			PrintToChat(client," \x07Rifles Only \x01its a round");
			PrintToChat(client," everyone gets random rifle.");
			PrintToChat(client," \x07Everyone gets the same rifle!");
			PrintToChat(client, " \x08=============================");
		}
		case 6: {
			PrintToChat(client," \x08=============================");
			PrintToChat(client," \x07Pistols Only \x01is a round");
			PrintToChat(client," everyone gets random pistol.");
			PrintToChat(client," \x07Everyone gets the same pistol!");
			PrintToChat(client," \x08=============================");
		}
		case 8: {
			PrintToChat(client, " \x08=============================");
			PrintToChat(client, " \x07Space Round \x01its a round where");
			PrintToChat(client, " everyone's gets set to low gravity");
			PrintToChat(client, " and ssg08, as weapon.");
			PrintToChat(client, " \x08=============================");
		}
		default:  {
			PrintToChat(client, " \x02Error.");
		}
	}
}

////////////////////////////////////////////////////////
//               KeyValues - Settings                 //
////////////////////////////////////////////////////////

public void SetupSettingsFile() {
	CreateDirectory("/addons/sourcemod/data/SpecialRounds", 3);
	BuildPath(Path_SM, kv_Settings, sizeof(kv_Settings), "data/SpecialRounds/Settings.txt");
}

public void OnConfigsExecuted() {
	LoadSettings();
}

public void LoadSettings() {
	// lower than 2 means "false"
	int isGood = 0;

	KeyValues db_Settings = new KeyValues("Settings");
	db_Settings.ImportFromFile(kv_Settings);

	if(db_Settings.JumpToKey("Active Modes", true)) {
		for (int i = 0; i < sizeof(c_ModesNames); i++) {
			int isActive = db_Settings.GetNum(c_ModesNames[i], 1);

			if (isActive == 1) {
				al_ModesNames.PushString(c_ModesNames[i]);
			}
		}

		//SetupSettingsFileMenu();
		isGood++;
		db_Settings.Rewind();
	}

	if (db_Settings.JumpToKey("Custom Convars", true)) {
		cv_Enable.SetInt(db_Settings.GetNum("enable", cv_Enable.IntValue), true, false);
		cv_Chance.SetInt(db_Settings.GetNum("Chance", cv_Chance.IntValue), true, false);
		cv_MaxHealth.SetInt(db_Settings.GetNum("RandomHp Max", cv_MaxHealth.IntValue), true, false);
		cv_MinHealth.SetInt(db_Settings.GetNum("RandomHp Min", cv_MinHealth.IntValue), true, false);
		cv_Gravity.SetFloat(db_Settings.GetFloat("Gravity", cv_Gravity.FloatValue), true, false);
		cv_KnifeWithZeus.SetInt(db_Settings.GetNum("Knifes With Zeus", cv_KnifeWithZeus.IntValue), true, false);

		isGood++;
		db_Settings.Rewind();
	}

	if (isGood != 2) {
		PrintToServer("Error : There was a problem with loading the settting.");
		LogError("Error : There was a problem with loading the settting.");
	}

	db_Settings.ExportToFile(kv_Settings);
	delete db_Settings;
}

public void SaveSettings() {
	int isGood = 0;

	KeyValues db_Settings = new KeyValues("Settings");
	db_Settings.ImportFromFile(kv_Settings);

	if (db_Settings.JumpToKey("Active Modes", true)) {
		for (int i = 0; i < sizeof(c_ModesNames); i++) {
			if (al_ModesNames.FindString(c_ModesNames[i]) != -1) {
				db_Settings.SetNum(c_ModesNames[i], 1);
			}

			else {
				db_Settings.SetNum(c_ModesNames[i], 0);
			}
		}

		isGood++;
		db_Settings.Rewind();
	}

	if (db_Settings.JumpToKey("Custom Convars", true)) {
		db_Settings.SetNum("enable", cv_Enable.IntValue);
		db_Settings.SetNum("Chance", cv_Chance.IntValue);
		db_Settings.SetNum("RandomHp Max", cv_MaxHealth.IntValue);
		db_Settings.SetNum("RandomHp Min", cv_MinHealth.IntValue);
		db_Settings.SetFloat("Gravity", cv_Gravity.FloatValue);
		db_Settings.SetNum("Knifes With Zeus", cv_KnifeWithZeus.IntValue);

		isGood++;
		db_Settings.Rewind();
	}

	if (isGood != 2) {
		PrintToServer("Error : There was a problem with saving the settting to a file.");
		LogError("Error : There was a problem with saving the settting to a file.");
	}

	db_Settings.ExportToFile(kv_Settings);
	delete db_Settings;
}

public void OnPluginEnd() {
	SaveSettings();
}

/*
	Check if the saving / loading data is working.
	
	SAVE :
	sm_cvar sr_enable 0;
	sm_cvar sr_min_hp 30;
	sm_cvar sr_max_hp 250;
	sm_cvar sr_wzeus 1;
	sm_cvar sr_chance 30;
	sm_cvar sr_gravity 0.4
	
	LOAD :
	sm_cvar sr_enable;
	sm_cvar sr_min_hp;
	sm_cvar sr_max_hp;
	sm_cvar sr_wzeus ;
	sm_cvar sr_chance;
	sm_cvar sr_gravity
*/