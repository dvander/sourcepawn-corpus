#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <multicolors>
#define PLUGIN_VERSION "1.1"

#pragma tabsize 0

public Plugin myinfo = 
{
	name = "Weapon Menu",
	author = "Shitler",
	description = "Buy menu for AK,M4A1,Deagle,AWP.",
	version = PLUGIN_VERSION,
	url = "www.alliedmods.net"
}

Handle cvar_M4 = INVALID_HANDLE;
Handle cvar_AK = INVALID_HANDLE;
Handle cvar_Deagle = INVALID_HANDLE;
Handle cvar_Awp = INVALID_HANDLE;
new g_Bought[MAXPLAYERS + 1];

public OnPluginStart() 
{
        CreateConVar("sm_wm_version", PLUGIN_VERSION, "Version of the Plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		cvar_AK = CreateConVar("sm_wm_ak", "2500", "Price of AK47");
		cvar_M4 = CreateConVar("sm_wm_m4", "2500", "Price of M4A1");
        cvar_Deagle = CreateConVar("sm_wm_deagle", "600", "Price of Deagle");
        cvar_Awp = CreateConVar("sm_wm_awp", "4750", "Price of AWP");
		RegConsoleCmd("sm_buy", Menu_Options);
		
		HookEvent("player_spawn", Event_PlayerSpawn);
		HookEvent("player_death", Event_Death);
}


public Event_Death(Handle:Death_Event, const String:Death_Name[], bool:Death_Broadcast)
{    
    new client = GetClientOfUserId(GetEventInt(Death_Event, "userid"));
	CancelClientMenu(client, false, INVALID_HANDLE);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CancelClientMenu(client, false, INVALID_HANDLE);
    g_Bought[client] = 0;
}

DeductMoney(client, amount) {
    
	new clientMoney = GetEntProp(client, Prop_Send, "m_iAccount"); 
	
	if (clientMoney >= amount) {
        clientMoney -= amount; 
		SetEntProp(client, Prop_Send, "m_iAccount", clientMoney); 
		g_Bought[client] = 1;
	}
}

public Action Menu_Options(int client, int args)
{		

		if(!IsPlayerAlive(client)) {
			CPrintToChat(client, "{orange}[Gun Shop] {yellow} You need to be {orange}alive {yellow}to buy!");
			return Plugin_Handled;
		}
		
		if(g_Bought[client] == 1) {
			CPrintToChat(client, "{orange}[Gun Shop] {yellow} You have reached your round limit!");
			return Plugin_Handled;
		}
			
        new Handle:wpMenu = CreateMenu(Weapon_Purchase);
		SetMenuTitle(wpMenu, "%s", "Gun Shop");
		
		new clientMoney = GetEntProp(client, Prop_Send, "m_iAccount");
		new String:TempFormat[30];
		new String:all_Weapons[][] = { "M4A1", "AK47", "Deagle", "AWP" };
		new all_Prices[4];
		all_Prices[0] = GetConVarInt(cvar_AK);
		all_Prices[1] = GetConVarInt(cvar_M4);
		all_Prices[2] = GetConVarInt(cvar_Deagle);
		all_Prices[3] = GetConVarInt(cvar_Awp);
		new dif;
		
		
		for (new i = 0; i < sizeof(all_Weapons); i++) {
		// If Weapon was already bought
		if (g_Bought[client] == 1) {
			Format(TempFormat, sizeof(TempFormat), "%s - Limit Reached", all_Weapons[i]);
			AddMenuItem(wpMenu, "", TempFormat, ITEMDRAW_DISABLED );
		}
	
		//If Weapon wasn't bought
		else if(g_Bought[client] == 0) {
			//But nigga doesn't have nuff dough
			 if (clientMoney < all_Prices[i]) {
				dif =  all_Prices[i] - clientMoney;
				Format(TempFormat, sizeof(TempFormat), "%s - $%i more needed", all_Weapons[i], dif);
				AddMenuItem(wpMenu, "", TempFormat, ITEMDRAW_DISABLED );	
			} 
			else {
			//Has nuff dough
				Format(TempFormat, sizeof(TempFormat), "%s - $%i", all_Weapons[i], all_Prices[i]);
				AddMenuItem(wpMenu, "", TempFormat);
				}
			}
		}
		
        DisplayMenu(wpMenu, client, MENU_TIME_FOREVER);
		return Plugin_Continue;
}
 
public Weapon_Purchase(Handle wpMenu, MenuAction action, client, weapon)
{
    if(action == MenuAction_End)
        CloseHandle(wpMenu);
       
    else if(action == MenuAction_Select)
    {
		int price;
		int Prim = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		int Sec = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		
        switch(weapon)
        {
            case 0:
            {	
				price = GetConVarInt(cvar_AK);
				DeductMoney(client,price);
				if(Prim != -1) {
					CS_DropWeapon(client, Prim, false, true);
				}
				
				GivePlayerItem(client, "weapon_ak47");
            }
            case 1:
            {
				price = GetConVarInt(cvar_M4);
				DeductMoney(client,price);
				if(Prim != -1) {
					CS_DropWeapon(client, Prim, false, true);
				}
				
				GivePlayerItem(client, "weapon_m4a1");
            }
			case 2:
			{
				price = GetConVarInt(cvar_Deagle);
				DeductMoney(client,price);
				if(Sec != -1) {
					CS_DropWeapon(client, Sec, false, true);
				}
				
				GivePlayerItem(client, "weapon_deagle");
			}
			case 3:
			{
				price = GetConVarInt(cvar_Awp);
				DeductMoney(client,price);
				if(Prim != -1) {
					CS_DropWeapon(client, Prim, false, true);
				}
				
				GivePlayerItem(client, "weapon_awp");
			}
        }
    }
}