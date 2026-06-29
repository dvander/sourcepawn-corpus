#include <sourcemod>
#include <cstrike>
#include <sdktools>
#define PLUGIN_VERSION "1.0"

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

public OnPluginStart() 
{
        CreateConVar("sm_wm_version", PLUGIN_VERSION, "Version of the Plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		cvar_AK = CreateConVar("sm_wm_ak", "2500", "Price of AK47");
		cvar_M4 = CreateConVar("sm_wm_m4", "2500", "Price of M4A1");
        cvar_Deagle = CreateConVar("sm_wm_deagle", "600", "Price of Deagle");
        cvar_Awp = CreateConVar("sm_wm_awp", "4750", "Price of AWP");
		RegConsoleCmd("sm_buy", Menu_Options);
}

DeductMoney(client, amount) {
    
	new clientMoney = GetEntProp(client, Prop_Send, "m_iAccount"); 
	
	if (clientMoney >= amount) {
        clientMoney -= amount; 
		SetEntProp(client, Prop_Send, "m_iAccount", clientMoney); 
	}
}


public Action Menu_Options(int client, int args)
{		
		new clientMoney = GetEntProp(client, Prop_Send, "m_iAccount");
		
        new Handle:wpMenu = CreateMenu(Weapon_Purchase);
        
		SetMenuTitle(wpMenu, "%s", "Gun Shop");
		
		if (GetConVarInt(cvar_AK) <= clientMoney)
			{AddMenuItem(wpMenu, "", "AK47");} 
			else {AddMenuItem(wpMenu, "", "AK47", ITEMDRAW_DISABLED);}
			
		if (GetConVarInt(cvar_M4) <= clientMoney)
			{AddMenuItem(wpMenu, "", "M4A1");} 
			else {AddMenuItem(wpMenu, "", "M4A1", ITEMDRAW_DISABLED);}
			
		if (GetConVarInt(cvar_Deagle) <= clientMoney)
			{AddMenuItem(wpMenu, "", "DEAGLE");} 
			else {AddMenuItem(wpMenu, "", "DEAGLE", ITEMDRAW_DISABLED);}
			
		if (GetConVarInt(cvar_Awp) <= clientMoney)
			{AddMenuItem(wpMenu, "", "AWP");} 
			else {AddMenuItem(wpMenu, "", "AWP", ITEMDRAW_DISABLED);}
		

        DisplayMenu(wpMenu, client, MENU_TIME_FOREVER);
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