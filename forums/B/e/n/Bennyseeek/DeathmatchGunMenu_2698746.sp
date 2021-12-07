#pragma semicolon 1
#pragma newdecls required

#define DEBUG
#define PLUGIN_AUTHOR "Benny"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>


public Plugin myinfo = 
{
	name = "BennysGunMenu",
	author = PLUGIN_AUTHOR,
	description = "My first gun menu plugin. Enjoy. (credits to Dyny for helping me out)",
	version = PLUGIN_VERSION,
	url = "www.twitch.tv/bennyseeek"
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_deathmatch", Command_Deathmatch, "OpenMenu"); 
    HookEvent("round_start", Event_RoundStart);
    PrintHintTextToAll("<font color='#8B0000'>DeathMatch Plugin made by</font> Benny!");
    
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    for (int i = 1; i < MAXPLAYERS; i++) {
        if (IsClientInGame(i) && IsPlayerAlive(i)) {
            ClientCommand(i, "sm_deathmatch %i", i);
        }
    }
} 

public Action Command_Deathmatch(int client, int args) 
{
	Menu menu = new Menu(Menu_bennyhodeathmatchmenu);
	char Title2[200];
	Format(Title2, sizeof(Title2), "Choose your primary weapon\n ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓");
	menu.SetTitle(Title2);
	menu.AddItem("0", "Secondary guns");
	menu.AddItem("1", "AK-47");
	menu.AddItem("2", "M4A4");
	menu.AddItem("3", "M4A1-S");
	menu.AddItem("4", "AWP");
	menu.AddItem("5", "AUG");
	menu.AddItem("6", "Famas");
	menu.AddItem("7", "UMP-45");
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}


public int Menu_bennyhodeathmatchmenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action) {
		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));

			
			if(StrEqual(item, "1")){
				int iWeapon = GetPlayerWeaponSlot(param1, CS_SLOT_PRIMARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(param1, "weapon_ak47");
				CPrintToChat(param1, "{DARKRED}[DM]: {default}Following gun has been given to you {green}ak-47");
				ClientCommand(param1, "sm_deathmatch");
			}
			
			else if (StrEqual(item, "2")){
				int iWeapon = GetPlayerWeaponSlot(param1, CS_SLOT_PRIMARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(param1, "weapon_m4a1");
				CPrintToChat(param1, "{DARKRED}[DM]: {default}Following gun has been given to you {green}M4A4");
				ClientCommand(param1, "sm_deathmatch");
			}
			
			else if (StrEqual(item, "3")){
				int iWeapon = GetPlayerWeaponSlot(param1, CS_SLOT_PRIMARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(param1, "weapon_m4a1_silencer");
				CPrintToChat(param1, "{DARKRED}[DM]: {default}Following gun has been given to you {green}M4A1-S");
				ClientCommand(param1, "sm_deathmatch");
			}
			
			else if (StrEqual(item, "4")){
				int iWeapon = GetPlayerWeaponSlot(param1, CS_SLOT_PRIMARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(param1, "weapon_awp");
				CPrintToChat(param1, "{DARKRED}[DM]: {default}Following gun has been given to you {green}AWP");
				ClientCommand(param1, "sm_deathmatch");
			}
			
			else if (StrEqual(item, "5")){
				int iWeapon = GetPlayerWeaponSlot(param1, CS_SLOT_PRIMARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(param1, "weapon_aug");
				CPrintToChat(param1, "{DARKRED}[DM]: {default}Following gun has been given to you {green}AUG");
				ClientCommand(param1, "sm_deathmatch");
			}
			
			else if (StrEqual(item, "6")){
				int iWeapon = GetPlayerWeaponSlot(param1, CS_SLOT_PRIMARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(param1, "weapon_famas");
				CPrintToChat(param1, "{DARKRED}[DM]: {default}Following gun has been given to you {green}Famas");
				ClientCommand(param1, "sm_deathmatch");
			}
			
			else if (StrEqual(item, "7")){
				int iWeapon = GetPlayerWeaponSlot(param1, CS_SLOT_PRIMARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(param1, "weapon_ump45");
				CPrintToChat(param1, "{DARKRED}[DM]: {default}Following gun has been given to you {green}UMP-45");
				ClientCommand(param1, "sm_deathmatch");
			}
			
			else if (StrEqual(item, "0")){
				Menu_Sec(param1);
			}

			else if(action == MenuAction_End) {
			delete menu;
			}
}
}
}

void Menu_Sec(int client)
{
	Menu menu = new Menu(Menu_Callback_Sec);
	char Title[200];
	Format(Title, sizeof(Title), "Choose your secondary weapon\n ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓");
	menu.SetTitle(Title);
	menu.AddItem("1", "USP-S");
	menu.AddItem("2", "Glock-18");
	menu.AddItem("3", "Desert Eagle");
	menu.AddItem("4", "CZ-75 auto");
	menu.AddItem("5", "P2000");
	menu.AddItem("6", "Tec-9");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Callback_Sec(Menu menu, MenuAction action, int iClient, int iInfo)
{
	switch(action) {
		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(iInfo, item, sizeof(item));
			
			if (StrEqual(item, "1")){
				int iWeapon = GetPlayerWeaponSlot(iClient, CS_SLOT_SECONDARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(iClient, "weapon_usp_silencer");
				CPrintToChat(iClient, "{DARKRED}[DM]: {default}Following gun has been given to you {green}USP-S");
				ClientCommand(iClient, "sm_deathmatch");
			}
			else if (StrEqual(item, "2")){
				int iWeapon = GetPlayerWeaponSlot(iClient, CS_SLOT_SECONDARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(iClient, "weapon_glock");
				CPrintToChat(iClient, "{DARKRED}[DM]: {default}Following gun has been given to you {green}Glock-18");
				ClientCommand(iClient, "sm_deathmatch");
			}
			
			else if (StrEqual(item, "3")){
				int iWeapon = GetPlayerWeaponSlot(iClient, CS_SLOT_SECONDARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(iClient, "weapon_deagle");
				CPrintToChat(iClient, "{DARKRED}[DM]: {default}Following gun has been given to you {green}Desert Eagle");
				ClientCommand(iClient, "sm_deathmatch");
			}
			
			else if (StrEqual(item, "4")){
				int iWeapon = GetPlayerWeaponSlot(iClient, CS_SLOT_SECONDARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(iClient, "weapon_cz75a");
				CPrintToChat(iClient, "{DARKRED}[DM]: {default}Following gun has been given to you {green}CZ-75 auto");
				ClientCommand(iClient, "sm_deathmatch");
			}
			
			else if (StrEqual(item, "5")){
				int iWeapon = GetPlayerWeaponSlot(iClient, CS_SLOT_SECONDARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(iClient, "weapon_hkp2000");
				CPrintToChat(iClient, "{DARKRED}[DM]: {default}Following gun has been given to you {green}P2000");
				ClientCommand(iClient, "sm_deathmatch");
			}
			
			else if (StrEqual(item, "6")){
				int iWeapon = GetPlayerWeaponSlot(iClient, CS_SLOT_SECONDARY);
				if(iWeapon != -1) 
				if (IsValidEntity(iWeapon))AcceptEntityInput(iWeapon, "kill");
				GivePlayerItem(iClient, "weapon_tec9");
				CPrintToChat(iClient, "{DARKRED}[DM]: {default}Following gun has been given to you {green}Tec-9");
				ClientCommand(iClient, "sm_deathmatch");
			}
			
			else if (action == MenuAction_End){
			delete menu;
			}
}
}

}