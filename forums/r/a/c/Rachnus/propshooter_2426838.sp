#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma newdecls required

EngineVersion g_Game;



public Plugin myinfo = 
{
	name = "test",
	author = PLUGIN_AUTHOR,
	description = "test",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
};
ConVar g_cvPropLifeSpan;
ConVar g_cvMaxProps;
ConVar g_cvAdminOnly;


bool bOn[MAXPLAYERS + 1];
char propPath[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
int propCounter[MAXPLAYERS + 1];
int rgba[MAXPLAYERS + 1][4];

char defaultProp[255];

public void OnPluginStart()
{
	for(int client = 1; client <= MaxClients; client++) 
	{
		if(IsClientInGame(client)) 
		{
			SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
	}
	
	KeyValues kv = new KeyValues("Colors");
	
	if(!kv.ImportFromFile("addons/sourcemod/configs/propshooter_colors.txt"))
		SetFailState("Could not open addons/sourcemod/configs/propshooter_colors.txt");

	char buffer1[10];
	char buffer2[10];
	char buffer3[10];
	
	kv.JumpToKey("Default", false);	
	kv.GetString("red", buffer1, sizeof(buffer1));
	kv.GetString("green", buffer2, sizeof(buffer2));
	kv.GetString("blue", buffer3, sizeof(buffer3));
	

	
	delete kv;
	
	for (int i = 0; i < MAXPLAYERS;i++)
	{
		rgba[i][0] = StringToInt(buffer1);
		rgba[i][1] = StringToInt(buffer2);
		rgba[i][2] = StringToInt(buffer3);
		rgba[i][3] = 255;
		propCounter[i] = 0;
	}
	
	
	KeyValues kv1 = new KeyValues("Props");
	
	if(!kv1.ImportFromFile("addons/sourcemod/configs/propshooter_paths.txt"))
		SetFailState("Could not open addons/sourcemod/configs/propshooter_paths.txt");

		
	kv1.JumpToKey("Default", false);	
	kv1.GetString("path", defaultProp, sizeof(defaultProp));
		
	delete kv1;
	
	g_cvPropLifeSpan = CreateConVar("propshooter_proplifespan", "3", "Sets the prop's lifespan", FCVAR_NOTIFY, true, 0.0, true, 30.0);
	g_cvMaxProps = CreateConVar("propshooter_maxprops", "50", "Sets the maximum amount of props to be spawned on the map at the same time", FCVAR_NOTIFY, true, 0.0, true, 500.0);
	g_cvAdminOnly = CreateConVar("propshooter_adminonly", "1", "Sets wether or not players can use this plugin (Without access to server settings)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	RegConsoleCmd("sm_propshooter", Prop_Menu, "Opens up propshooter menu");
	RegConsoleCmd("sm_ps", Prop_Menu, "Opens up propshooter menu");
	
	HookEvent("weapon_fire", Event_Fire);

}

//Main menu
public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		delete menu;
		
		if(StrEqual(info, "activeno", false))
		{
			
			if(g_cvAdminOnly.IntValue == 1)
			{
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
				{
					bOn[param1] = true;
					Menu menu1 = new Menu(MenuHandler1);
			
					menu1.SetTitle("Propshooter");
					if(!bOn[param1])
						menu1.AddItem("activeno", "Active: No");
					else
						menu1.AddItem("activeyes", "Active: Yes");
						
					menu1.AddItem("props", "Props");
					menu1.AddItem("properties", "Properties");
					menu1.AddItem("delete", "Delete my props");
					if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
						menu1.AddItem("admin", "Server settings");
						
					menu1.ExitButton = true;
					menu1.Display(param1, 20);
				}
			}
			else
			{
				bOn[param1] = true;
				Menu menu1 = new Menu(MenuHandler1);
		
				menu1.SetTitle("Propshooter");
				if(!bOn[param1])
					menu1.AddItem("activeno", "Active: No");
				else
					menu1.AddItem("activeyes", "Active: Yes");
					
				menu1.AddItem("props", "Props");
				menu1.AddItem("properties", "Properties");
				menu1.AddItem("delete", "Delete my props");
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
					menu1.AddItem("admin", "Server settings");
					
				menu1.ExitButton = true;
				menu1.Display(param1, 20);
				
			}
		}
		else if(StrEqual(info, "activeyes", false))
		{
			bOn[param1] = false;
			if(g_cvAdminOnly.IntValue == 1)
			{
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
				{
					Menu menu1 = new Menu(MenuHandler1);
			
					menu1.SetTitle("Propshooter");
					if(!bOn[param1])
						menu1.AddItem("activeno", "Active: No");
					else
						menu1.AddItem("activeyes", "Active: Yes");
						
					menu1.AddItem("props", "Props");
					menu1.AddItem("properties", "Properties");
					menu1.AddItem("delete", "Delete my props");
					if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
						menu1.AddItem("admin", "Server settings");
						
					menu1.ExitButton = true;
					menu1.Display(param1, 20);
				}
			}
			else
			{

				Menu menu1 = new Menu(MenuHandler1);
		
				menu1.SetTitle("Propshooter");
				if(!bOn[param1])
					menu1.AddItem("activeno", "Active: No");
				else
					menu1.AddItem("activeyes", "Active: Yes");
					
				menu1.AddItem("props", "Props");
				menu1.AddItem("properties", "Properties");
				menu1.AddItem("delete", "Delete my props");
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
					menu1.AddItem("admin", "Server settings");
					
				menu1.ExitButton = true;
				menu1.Display(param1, 20);
				
			}
		}
		else if(StrEqual(info, "props", false))
		{
			Menu menu1 = new Menu(MenuHandler2);
			
			menu1.SetTitle("Props");
			
			KeyValues kv = new KeyValues("Props");
			if(!kv.ImportFromFile("addons/sourcemod/configs/propshooter_paths.txt"))
				SetFailState("Could not open addons/sourcemod/configs/propshooter_paths.txt");
		

			
			
			char buffer[255];
			
			kv.GotoFirstSubKey(false);
			
			do
			{
				kv.GetString("name", buffer, sizeof(buffer));
				menu1.AddItem(buffer, buffer);
				
				
			} while (kv.GotoNextKey());
			
			delete kv;
			
			menu1.ExitBackButton = true;
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
		}
		else if(StrEqual(info, "properties", false))
		{
			Menu menu1 = new Menu(MenuHandler3);
			
			menu1.SetTitle("Properties");
			
			menu1.AddItem("color", "Set prop color");
			menu1.AddItem("alpha", "Set prop alpha");
			
			menu1.ExitBackButton = true;
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
			
		}
		else if (StrEqual(info, "delete", false))
		{
			propCounter[param1] = 0;
			
			int index = -1;
			
			while((index = FindEntityByClassname(index, "prop_physics")) != -1)
			{
			 	if(IsValidEntity(index))
			 	{
			 		char propsteamID[50];
			 		char steamID[50];
			 		GetEntPropString(index, Prop_Data, "m_iName", propsteamID, sizeof(propsteamID));
			 		GetClientAuthId(param1, AuthId_SteamID64, steamID, sizeof(steamID), true);
			 		
			 		if (StrContains(propsteamID, steamID) != -1)
			 		{
			 			AcceptEntityInput(index, "Kill");
			 		}
			 	}
			}
			if(g_cvAdminOnly.IntValue == 1)
			{
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
				{
				Menu menu1 = new Menu(MenuHandler1);
		
				menu1.SetTitle("Propshooter");
				if(!bOn[param1])
					menu1.AddItem("activeno", "Active: No");
				else
					menu1.AddItem("activeyes", "Active: Yes");
					
				menu1.AddItem("props", "Props");
				menu1.AddItem("properties", "Properties");
				menu1.AddItem("delete", "Delete my props");
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
					menu1.AddItem("admin", "Server settings");
					
				menu1.ExitButton = true;
				menu1.Display(param1, 20);
				}
			}
			else
			{
				Menu menu1 = new Menu(MenuHandler1);
		
				menu1.SetTitle("Propshooter");
				if(!bOn[param1])
					menu1.AddItem("activeno", "Active: No");
				else
					menu1.AddItem("activeyes", "Active: Yes");
					
				menu1.AddItem("props", "Props");
				menu1.AddItem("properties", "Properties");
				menu1.AddItem("delete", "Delete my props");
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
					menu1.AddItem("admin", "Server settings");
					
				menu1.ExitButton = true;
				menu1.Display(param1, 20);
			
			}
		}		
		else if(StrEqual(info, "admin", false))
		{
				Menu menu1 = new Menu(MenuHandler4);
				menu1.SetTitle("Server settings");
				
				if(g_cvAdminOnly.IntValue == 1)
					menu1.AddItem("adminonly", "Admin only: Yes");
				else
					menu1.AddItem("adminonly", "Admin only: No");
					
				menu1.AddItem("lifespan", "Prop lifespan");
				menu1.AddItem("maxprops", "Max props");
				menu1.AddItem("deleteall", "Delete all props");
				
				
				
				menu1.ExitBackButton = true;
				menu1.ExitButton = true;
				menu1.Display(param1, 20);
		}
	}
}

//Props menu
public int MenuHandler2(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		delete menu;
		KeyValues kv = new KeyValues("Props");
		if (!kv.ImportFromFile("addons/sourcemod/configs/propshooter_paths.txt"))
			SetFailState("Could not open addons/sourcemod/configs/propshooter_paths.txt");
		
		kv.JumpToKey(info, false);
		
		char buffer[255];
		
		kv.GetString("path", buffer, sizeof(buffer));
		propPath[param1] = buffer;
			
		delete kv;
		

		if(g_cvAdminOnly.IntValue == 1)
		{
			if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
			{
				Menu menu1 = new Menu(MenuHandler1);
		
				menu1.SetTitle("Propshooter");
				if(!bOn[param1])
					menu1.AddItem("activeno", "Active: No");
				else
					menu1.AddItem("activeyes", "Active: Yes");
					
				menu1.AddItem("props", "Props");
				menu1.AddItem("properties", "Properties");
				menu1.AddItem("delete", "Delete my props");
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
					menu1.AddItem("admin", "Server settings");
					
				menu1.ExitButton = true;
				menu1.Display(param1, 20);
			}
		}
		else
		{
			Menu menu1 = new Menu(MenuHandler1);
	
			menu1.SetTitle("Propshooter");
			if(!bOn[param1])
				menu1.AddItem("activeno", "Active: No");
			else
				menu1.AddItem("activeyes", "Active: Yes");
				
			menu1.AddItem("props", "Props");
			menu1.AddItem("properties", "Properties");
			menu1.AddItem("delete", "Delete my props");
			if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
				menu1.AddItem("admin", "Server settings");
				
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
			
		}
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		delete menu;
		if(g_cvAdminOnly.IntValue == 1)
		{
			if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
			{
				Menu menu1 = new Menu(MenuHandler1);
		
				menu1.SetTitle("Propshooter");
				if(!bOn[param1])
					menu1.AddItem("activeno", "Active: No");
				else
					menu1.AddItem("activeyes", "Active: Yes");
					
				menu1.AddItem("props", "Props");
				menu1.AddItem("properties", "Properties");
				menu1.AddItem("delete", "Delete my props");
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
					menu1.AddItem("admin", "Server settings");
					
				menu1.ExitButton = true;
				menu1.Display(param1, 20);
			}
		}
		else
		{
			Menu menu1 = new Menu(MenuHandler1);
	
			menu1.SetTitle("Propshooter");
			if(!bOn[param1])
				menu1.AddItem("activeno", "Active: No");
			else
				menu1.AddItem("activeyes", "Active: Yes");
				
			menu1.AddItem("props", "Props");
			menu1.AddItem("properties", "Properties");
			menu1.AddItem("delete", "Delete my props");
			if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
				menu1.AddItem("admin", "Server settings");
				
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
			
		}
	}
}

//Properties menu
public int MenuHandler3(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		delete menu;
		if(StrEqual(info, "color", false))
		{
			Menu menu1 = new Menu(MenuHandler7);
			
			menu1.SetTitle("Set Color");
			
			KeyValues kv = new KeyValues("Colors");
			if(!kv.ImportFromFile("addons/sourcemod/configs/propshooter_colors.txt"))
				SetFailState("Could not open addons/sourcemod/configs/propshooter_colors.txt");
		
	
			char buffer[255];
			
			kv.GotoFirstSubKey(false);
			
			do
			{
				kv.GetString("name", buffer, sizeof(buffer));
				menu1.AddItem(buffer, buffer);
				
			} while (kv.GotoNextKey());
			
			delete kv;
			
			
			menu1.ExitBackButton = true;
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
		}
		else if(StrEqual(info, "alpha", false))
		{
			Menu menu1 = new Menu(MenuHandler8);
			
			menu1.SetTitle("Set Alpha");
			menu1.AddItem("default", "Default (255)");
			menu1.AddItem("200", "200");
			menu1.AddItem("150", "150");
			menu1.AddItem("100", "100");
			menu1.AddItem("50", "50");
			
			menu1.ExitBackButton = true;
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
		}
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		delete menu;
		if(g_cvAdminOnly.IntValue == 1)
		{
			if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
			{
				Menu menu1 = new Menu(MenuHandler1);
		
				menu1.SetTitle("Propshooter");
				if(!bOn[param1])
					menu1.AddItem("activeno", "Active: No");
				else
					menu1.AddItem("activeyes", "Active: Yes");
					
				menu1.AddItem("props", "Props");
				menu1.AddItem("properties", "Properties");
				menu1.AddItem("delete", "Delete my props");
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
					menu1.AddItem("admin", "Server settings");
					
				menu1.ExitButton = true;
				menu1.Display(param1, 20);
			}
		}
		else
		{
			Menu menu1 = new Menu(MenuHandler1);
	
			menu1.SetTitle("Propshooter");
			if(!bOn[param1])
				menu1.AddItem("activeno", "Active: No");
			else
				menu1.AddItem("activeyes", "Active: Yes");
				
			menu1.AddItem("props", "Props");
			menu1.AddItem("properties", "Properties");
			menu1.AddItem("delete", "Delete my props");
			if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
				menu1.AddItem("admin", "Server settings");
				
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
		
		}
	}
}

//Server settings menu (admin menu)
public int MenuHandler4(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		delete menu;

		if(StrEqual(info, "lifespan", false))
		{
			Menu menu1 = new Menu(MenuHandler5);
			menu1.SetTitle("Prop lifespan (Seconds)");
			menu1.AddItem("0", "Until deleted/disconnected");
			menu1.AddItem("1", "1");
			menu1.AddItem("2", "2");
			menu1.AddItem("3", "3");
			menu1.AddItem("4", "5");
			menu1.AddItem("5", "10");
			menu1.AddItem("6", "15");
			menu1.AddItem("7", "30");
			
			menu1.ExitBackButton = true;
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
		}
		else if(StrEqual(info, "maxprops", false))
		{
			
			Menu menu1 = new Menu(MenuHandler6);
			menu1.SetTitle("Max props");
			menu1.AddItem("0", "0");
			menu1.AddItem("1", "1");
			menu1.AddItem("2", "5");
			menu1.AddItem("3", "10");
			menu1.AddItem("4", "20");
			menu1.AddItem("5", "50");
			menu1.AddItem("6", "100");
			menu1.AddItem("7", "200");
			menu1.AddItem("8", "300");
			menu1.AddItem("9", "400");
			
			menu1.ExitBackButton = true;
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
		}
		else if (StrEqual(info, "deleteall", false))
		{
			for (int i = 0; i < MAXPLAYERS;i++)
			 	propCounter[i] = 0;
			 		
			int index = -1;
			while((index = FindEntityByClassname(index, "prop_physics")) != -1)
			{
			 	if(IsValidEntity(index))
			 	{
			 		AcceptEntityInput(index, "Kill");	
			 	}
			}
			
			Menu menu1 = new Menu(MenuHandler4);
			menu1.SetTitle("Server settings");
			
			if(g_cvAdminOnly.IntValue == 1)
				menu1.AddItem("adminonly", "Admin only: Yes");
			else
				menu1.AddItem("adminonly", "Admin only: No");
			menu1.AddItem("lifespan", "Prop lifespan");
			menu1.AddItem("maxprops", "Max props");
			menu1.AddItem("deleteall", "Delete all props");
			
			menu1.ExitBackButton = true;
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
			
		}
		else if(StrEqual(info, "adminonly", false))
		{
			if(g_cvAdminOnly.IntValue == 1)
				g_cvAdminOnly.IntValue = 0;
			else
			{
				g_cvAdminOnly.IntValue = 1;
				for (int i = 0; i < MAXPLAYERS;i++)
				bOn[i] = false;
			}
			
			Menu menu1 = new Menu(MenuHandler4);
			menu1.SetTitle("Server settings");
			
			if(g_cvAdminOnly.IntValue == 1)
				menu1.AddItem("adminonly", "Admin only: Yes");
			else
				menu1.AddItem("adminonly", "Admin only: No");
			menu1.AddItem("lifespan", "Prop lifespan");
			menu1.AddItem("maxprops", "Max props");
			menu1.AddItem("deleteall", "Delete all props");
			
			menu1.ExitBackButton = true;
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
		}
		
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		delete menu;
		
		if(g_cvAdminOnly.IntValue == 1)
		{
			if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
			{
				Menu menu1 = new Menu(MenuHandler1);
		
				menu1.SetTitle("Propshooter");
				if(!bOn[param1])
					menu1.AddItem("activeno", "Active: No");
				else
					menu1.AddItem("activeyes", "Active: Yes");
					
				menu1.AddItem("props", "Props");
				menu1.AddItem("properties", "Properties");
				menu1.AddItem("delete", "Delete my props");
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
					menu1.AddItem("admin", "Server settings");
					
				menu1.ExitButton = true;
				menu1.Display(param1, 20);
			}
		}
		else
		{
			Menu menu1 = new Menu(MenuHandler1);
	
			menu1.SetTitle("Propshooter");
			if(!bOn[param1])
				menu1.AddItem("activeno", "Active: No");
			else
				menu1.AddItem("activeyes", "Active: Yes");
				
			menu1.AddItem("props", "Props");
			menu1.AddItem("properties", "Properties");
			menu1.AddItem("delete", "Delete my props");
			if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
				menu1.AddItem("admin", "Server settings");
				
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
		
		}
	}
}

//Lifespan
public int MenuHandler5(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		delete menu;

		if(StrEqual(info, "0", false))
		{
			g_cvPropLifeSpan.FloatValue = 0.0;
		}
		else if(StrEqual(info, "1", false))
		{
			g_cvPropLifeSpan.FloatValue = 1.0;
		}
		else if(StrEqual(info, "2", false))
		{
			g_cvPropLifeSpan.FloatValue = 2.0;
		}
		else if(StrEqual(info, "3", false))
		{
			g_cvPropLifeSpan.FloatValue = 3.0;
		}
		else if(StrEqual(info, "4", false))
		{
			g_cvPropLifeSpan.FloatValue = 5.0;
		}
		else if(StrEqual(info, "5", false))
		{
			g_cvPropLifeSpan.FloatValue = 10.0;
		}
		else if(StrEqual(info, "6", false))
		{
			g_cvPropLifeSpan.FloatValue = 15.0;
		}
		else if(StrEqual(info, "7", false))
		{
			g_cvPropLifeSpan.FloatValue = 30.0;
		}
		
		Menu menu1 = new Menu(MenuHandler4);
		menu1.SetTitle("Server settings");
		
		if(g_cvAdminOnly.IntValue == 1)
			menu1.AddItem("adminonly", "Admin only: Yes");
		else
			menu1.AddItem("adminonly", "Admin only: No");
		menu1.AddItem("lifespan", "Prop lifespan");
		menu1.AddItem("maxprops", "Max props");
		menu1.AddItem("deleteall", "Delete all props");
		
		menu1.ExitBackButton = true;
		menu1.ExitButton = true;
		menu1.Display(param1, 20);
		
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		delete menu;
		Menu menu1 = new Menu(MenuHandler4);
		menu1.SetTitle("Server settings");
		
		menu1.AddItem("lifespan", "Prop lifespan");
		menu1.AddItem("maxprops", "Max props");
		menu1.AddItem("deleteall", "Delete all props");
		
		menu1.ExitBackButton = true;
		menu1.ExitButton = true;
		menu1.Display(param1, 20);
	}
}

//Maxprops
public int MenuHandler6(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		delete menu;
		
		if(StrEqual(info, "0", false))
		{
			g_cvMaxProps.IntValue = 0;
		}
		else if(StrEqual(info, "1", false))
		{
			g_cvMaxProps.IntValue = 1;
		}
		else if(StrEqual(info, "2", false))
		{
			g_cvMaxProps.IntValue = 5;
		}
		else if(StrEqual(info, "3", false))
		{
			g_cvMaxProps.IntValue = 10;
		}
		else if(StrEqual(info, "4", false))
		{
			g_cvMaxProps.IntValue = 20;
		}
		else if(StrEqual(info, "5", false))
		{
			g_cvMaxProps.IntValue = 50;
		}
		else if(StrEqual(info, "6", false))
		{
			g_cvMaxProps.IntValue = 100;
		}
		else if(StrEqual(info, "7", false))
		{
			g_cvMaxProps.IntValue = 200;
		}
		else if(StrEqual(info, "8", false))
		{
			g_cvMaxProps.IntValue = 300;
		}
		else if(StrEqual(info, "9", false))
		{
			g_cvMaxProps.IntValue = 400;
		}
		
		Menu menu1 = new Menu(MenuHandler4);
		menu1.SetTitle("Server settings");
		
		if(g_cvAdminOnly.IntValue == 1)
			menu1.AddItem("adminonly", "Admin only: Yes");
		else
			menu1.AddItem("adminonly", "Admin only: No");
		menu1.AddItem("lifespan", "Prop lifespan");
		menu1.AddItem("maxprops", "Max props");
		menu1.AddItem("deleteall", "Delete all props");
		
		menu1.ExitBackButton = true;
		menu1.ExitButton = true;
		menu1.Display(param1, 20);
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		delete menu;
		Menu menu1 = new Menu(MenuHandler4);
		menu1.SetTitle("Server settings");
		
		menu1.AddItem("lifespan", "Prop lifespan");
		menu1.AddItem("maxprops", "Max props");
		menu1.AddItem("deleteall", "Delete all props");
		
		menu1.ExitBackButton = true;
		menu1.ExitButton = true;
		menu1.Display(param1, 20);
	}
}

//Properties colors
public int MenuHandler7(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		delete menu;
		
		KeyValues kv = new KeyValues("Colors");
		if (!kv.ImportFromFile("addons/sourcemod/configs/propshooter_colors.txt"))
			SetFailState("Could not open addons/sourcemod/configs/propshooter_colors.txt");
		
		kv.JumpToKey(info, false);
		
		char buffer[255];
		
		kv.GetString("red", buffer, sizeof(buffer));
		rgba[param1][0] = StringToInt(buffer);
		kv.GetString("green", buffer, sizeof(buffer));
		rgba[param1][1] = StringToInt(buffer);
		kv.GetString("blue", buffer, sizeof(buffer));
		rgba[param1][2] = StringToInt(buffer);
		delete kv;
		
		if(g_cvAdminOnly.IntValue == 1)
		{
			if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
			{
				Menu menu1 = new Menu(MenuHandler1);
		
				menu1.SetTitle("Propshooter");
				if(!bOn[param1])
					menu1.AddItem("activeno", "Active: No");
				else
					menu1.AddItem("activeyes", "Active: Yes");
					
				menu1.AddItem("props", "Props");
				menu1.AddItem("properties", "Properties");
				menu1.AddItem("delete", "Delete my props");
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
					menu1.AddItem("admin", "Server settings");
					
				menu1.ExitButton = true;
				menu1.Display(param1, 20);
			}
		}
		else
		{
			Menu menu1 = new Menu(MenuHandler1);
	
			menu1.SetTitle("Propshooter");
			if(!bOn[param1])
				menu1.AddItem("activeno", "Active: No");
			else
				menu1.AddItem("activeyes", "Active: Yes");
				
			menu1.AddItem("props", "Props");
			menu1.AddItem("properties", "Properties");
			menu1.AddItem("delete", "Delete my props");
			if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
				menu1.AddItem("admin", "Server settings");
				
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
		
		}
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		delete menu;
		
		Menu menu1 = new Menu(MenuHandler3);
		
		menu1.SetTitle("Properties");
		
		menu1.AddItem("color", "Set prop color");
		menu1.AddItem("alpha", "Set prop alpha");
		
		menu1.ExitBackButton = true;
		menu1.ExitButton = true;
		menu1.Display(param1, 20);
	}
}

//Properties alpha
public int MenuHandler8(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		delete menu;
		
		if(StrEqual(info, "default", false))
		{
			rgba[param1][3] = 255;
		}
		if(StrEqual(info, "200", false))
		{
			rgba[param1][3] = 200;
		}
		else if(StrEqual(info, "150"))
		{
			rgba[param1][3] = 150;
		}
		else if(StrEqual(info, "100", false))
		{
			rgba[param1][3] = 100;
		}
		else if(StrEqual(info, "50", false))
		{
			rgba[param1][3] = 50;
		}
		if(g_cvAdminOnly.IntValue == 1)
		{
			if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
			{
				Menu menu1 = new Menu(MenuHandler1);
		
				menu1.SetTitle("Propshooter");
				if(!bOn[param1])
					menu1.AddItem("activeno", "Active: No");
				else
					menu1.AddItem("activeyes", "Active: Yes");
					
				menu1.AddItem("props", "Props");
				menu1.AddItem("properties", "Properties");
				menu1.AddItem("delete", "Delete my props");
				if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
					menu1.AddItem("admin", "Server settings");
					
				menu1.ExitButton = true;
				menu1.Display(param1, 20);
			}
		}
		else
		{
			Menu menu1 = new Menu(MenuHandler1);
	
			menu1.SetTitle("Propshooter");
			if(!bOn[param1])
				menu1.AddItem("activeno", "Active: No");
			else
				menu1.AddItem("activeyes", "Active: Yes");
				
			menu1.AddItem("props", "Props");
			menu1.AddItem("properties", "Properties");
			menu1.AddItem("delete", "Delete my props");
			if (CheckCommandAccess(param1, "", ADMFLAG_GENERIC, true))
				menu1.AddItem("admin", "Server settings");
				
			menu1.ExitButton = true;
			menu1.Display(param1, 20);
		}
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		delete menu;
		
		Menu menu1 = new Menu(MenuHandler3);
		
		menu1.SetTitle("Properties");
		
		menu1.AddItem("color", "Set prop color");
		menu1.AddItem("alpha", "Set prop alpha");
		
		menu1.ExitBackButton = true;
		menu1.ExitButton = true;
		menu1.Display(param1, 20);
	}
}

public Action Prop_Menu(int client, int args)
{
	if(g_cvAdminOnly.IntValue == 1)
	{
		if (CheckCommandAccess(client, "", ADMFLAG_GENERIC, true))
		{
			Menu menu = new Menu(MenuHandler1);
			
			menu.SetTitle("Propshooter");
			if(!bOn[client])
				menu.AddItem("activeno", "Active: No");
			else
				menu.AddItem("activeyes", "Active: Yes");
			
			menu.AddItem("props", "Props");
			menu.AddItem("properties", "Properties");
			menu.AddItem("delete", "Delete my props");
			if (CheckCommandAccess(client, "", ADMFLAG_GENERIC, true))
				menu.AddItem("admin", "Server settings");
			
			
			menu.ExitButton = true;
			menu.Display(client, 20);
		}
		else
		{
			PrintToChat(client, "[SM] You do not have access to this command");
		}
	}
	else
	{
		Menu menu = new Menu(MenuHandler1);
		
		menu.SetTitle("Propshooter");
		if(!bOn[client])
			menu.AddItem("activeno", "Active: No");
		else
			menu.AddItem("activeyes", "Active: Yes");
		
		menu.AddItem("props", "Props");
		menu.AddItem("properties", "Properties");
		menu.AddItem("delete", "Delete my props");
		if (CheckCommandAccess(client, "", ADMFLAG_GENERIC, true))
			menu.AddItem("admin", "Server settings");
		
		
		menu.ExitButton = true;
		menu.Display(client, 20);
	
	}
	
	return Plugin_Handled;
}

public Action Event_Fire(Event event, const char[] name, bool dontBroadcast)
{
	
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	char steamID[50];
	GetClientAuthId(client, AuthId_SteamID64, steamID, sizeof(steamID), true);
	
	
	if(bOn[client])
	{
		if(g_cvAdminOnly.IntValue == 1)
		{
			if (CheckCommandAccess(client, "", ADMFLAG_GENERIC, true))
			{
				if(propCounter[client] < g_cvMaxProps.IntValue)
				{
					float propStart[3];
					float propAngle[3];
					float propVecs[3];
					
					
					
					
					
					GetClientEyePosition(client, propStart);
					GetClientEyeAngles(client, propAngle);
					GetAngleVectors(propAngle, propVecs, NULL_VECTOR, NULL_VECTOR);
					
					
					ScaleVector(propVecs, 5000.0);
					
					int prop = CreateEntityByName("prop_physics");
					
					
					
					if(StrEqual(propPath[client], "", false))
						DispatchKeyValue(prop, "model", defaultProp);
					else
						DispatchKeyValue(prop, "model", propPath[client]);
						
					SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
					SetEntityRenderColor(prop, rgba[client][0], rgba[client][1], rgba[client][2], rgba[client][3]);
					
		
					DispatchKeyValue(prop, "targetname", steamID);
					SetEntPropEnt(prop, Prop_Send, "m_hOwnerEntity", client);
					
					
					
					DispatchKeyValueVector(prop, "origin", propStart);
					DispatchSpawn(prop);
					propCounter[client]++;
					
					SetEntProp(prop, Prop_Data, "m_takedamage", 0);
		
					
			
					TeleportEntity(prop, propStart, NULL_VECTOR,  propVecs);
					

					
					
					if(g_cvPropLifeSpan.FloatValue > 0)
					{
						DataPack pack;
						CreateDataTimer(g_cvPropLifeSpan.FloatValue, Destroy_Prop, pack);
							
						pack.WriteCell(client);
						pack.WriteCell(prop);
					}
				}
				else
				{
					PrintToChat(client, "You have reached the maximum amount of props! (%i)", g_cvMaxProps.IntValue);
				}
			}
		}
		else
		{
			if(propCounter[client] < g_cvMaxProps.IntValue)
			{
				float propStart[3];
				float propAngle[3];
				float propVecs[3];
				
			
				
				GetClientEyePosition(client, propStart);
				GetClientEyeAngles(client, propAngle);
				GetAngleVectors(propAngle, propVecs, NULL_VECTOR, NULL_VECTOR);
				
				
				ScaleVector(propVecs, 5000.0);
				
				int prop = CreateEntityByName("prop_physics");
				
				
				
				if(StrEqual(propPath[client], "", false))
					DispatchKeyValue(prop, "model", defaultProp);
				else
					DispatchKeyValue(prop, "model", propPath[client]);
					
				SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
				SetEntityRenderColor(prop, rgba[client][0], rgba[client][1], rgba[client][2], rgba[client][3]);
				
	
				DispatchKeyValue(prop, "targetname", steamID);
				SetEntPropEnt(prop, Prop_Send, "m_hOwnerEntity", client);
				
				
				
				DispatchKeyValueVector(prop, "origin", propStart);
				DispatchSpawn(prop);
				propCounter[client]++;
				
				SetEntProp(prop, Prop_Data, "m_takedamage", 0);
	
				TeleportEntity(prop, propStart, NULL_VECTOR,  propVecs);
			
	
				if(g_cvPropLifeSpan.FloatValue > 0)
				{
					DataPack pack;
					CreateDataTimer(g_cvPropLifeSpan.FloatValue, Destroy_Prop, pack);
						
					pack.WriteCell(client);
					pack.WriteCell(prop);
				}
			}
			else
			{
				PrintToChat(client, "You have reached the maximum amount of props! (%i)", g_cvMaxProps.IntValue);
			}
		}	
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	
	if(attacker > 0 && attacker <= MaxClients)
	{
		if(bOn[attacker])
			damage = 0.0;
	
	}
	return Plugin_Changed;
}

public Action Destroy_Prop(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int client = pack.ReadCell();
	int prop = pack.ReadCell();
		
	if(IsValidEntity(prop))
	{
		if(AcceptEntityInput(prop, "Kill"))
			propCounter[client]--;
	}	
	return Plugin_Handled;

}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	bOn[client] = false;
	propPath[client] = "";
	
	int index = -1;
	
	rgba[client][0] = 255;
	rgba[client][1] = 255;
	rgba[client][2] = 255;
	rgba[client][3] = 255;

	
	while((index = FindEntityByClassname(index, "prop_physics")) != -1)
	{
		if(IsValidEntity(index))
		{
			 char propsteamID[50];
			 char steamID[50];
			 GetEntPropString(index, Prop_Data, "m_iName", propsteamID, sizeof(propsteamID));
			 GetClientAuthId(client, AuthId_SteamID64, steamID, sizeof(steamID), true);
			 		
			 if (StrContains(propsteamID, steamID))
			 {
			 		AcceptEntityInput(index, "Kill");
			 }
		}
	}
	propCounter[client] = 0;
}