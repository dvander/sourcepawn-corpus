
#define DEBUG

#define PLUGIN_NAME           "[TF2] Voice Packs"
#define PLUGIN_AUTHOR         "Spookmaster"
#define PLUGIN_DESCRIPTION    "Allows users to set voice packs for themselves."
#define PLUGIN_VERSION        "1.0"
#define PLUGIN_URL            ""


public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <morecolors>
#include <tf2_stocks>

#pragma semicolon 1

Handle cookie_ScoutPack;
Handle cookie_SoldierPack;
Handle cookie_PyroPack;
Handle cookie_DemoPack;
Handle cookie_HeavyPack;
Handle cookie_EngiePack;
Handle cookie_MedicPack;
Handle cookie_SniperPack;
Handle cookie_SpyPack;

int scoutPack[MAXPLAYERS+1] = {0, ...};
int soldierPack[MAXPLAYERS+1] = {0, ...};
int pyroPack[MAXPLAYERS+1] = {0, ...};
int demoPack[MAXPLAYERS+1] = {0, ...};
int heavyPack[MAXPLAYERS+1] = {0, ...};
int engiePack[MAXPLAYERS+1] = {0, ...};
int medicPack[MAXPLAYERS+1] = {0, ...};
int sniperPack[MAXPLAYERS+1] = {0, ...};
int spyPack[MAXPLAYERS+1] = {0, ...};

KeyValues config = null;

Menu voicePacks_ClassMenu = null;
Menu voicePacks_ScoutMenu = null;
Menu voicePacks_SoldierMenu = null;
Menu voicePacks_PyroMenu = null;
Menu voicePacks_DemoMenu = null;
Menu voicePacks_HeavyMenu = null;
Menu voicePacks_EngieMenu = null;
Menu voicePacks_MedicMenu = null;
Menu voicePacks_SniperMenu = null;
Menu voicePacks_SpyMenu = null;
Menu voicePacks_InfoScreen[MAXPLAYERS+1] = {null, ...};

int temp_ClassNum[MAXPLAYERS+1] = {0, ...};
int temp_Key[MAXPLAYERS+1] = {0, ...};

//To-Do: Auto-add to download tables

public void OnPluginStart()
{
	RegAdminCmd("voicepack", showMenu, ADMFLAG_GENERIC, "Allows users to equip voice packs to various classes.");
	RegAdminCmd("voicepacks", showMenu, ADMFLAG_GENERIC, "Allows users to equip voice packs to various classes.");
	RegAdminCmd("customvoice", showMenu, ADMFLAG_GENERIC, "Allows users to equip voice packs to various classes.");
	
	cookie_ScoutPack = RegClientCookie("scoutPack", "Client's current Scout voice pack, if equipped.", CookieAccess_Private);
	cookie_SoldierPack = RegClientCookie("soldierPack", "Client's current Soldier voice pack, if equipped.", CookieAccess_Private);
	cookie_PyroPack = RegClientCookie("pyroPack", "Client's current Pyro voice pack, if equipped.", CookieAccess_Private);
	cookie_DemoPack = RegClientCookie("demoPack", "Client's current Demoman voice pack, if equipped.", CookieAccess_Private);
	cookie_HeavyPack = RegClientCookie("heavyPack", "Client's current Heavy voice pack, if equipped.", CookieAccess_Private);
	cookie_EngiePack = RegClientCookie("engiePack", "Client's current Engineer voice pack, if equipped.", CookieAccess_Private);
	cookie_MedicPack = RegClientCookie("medicPack", "Client's current Medic voice pack, if equipped.", CookieAccess_Private);
	cookie_SniperPack = RegClientCookie("sniperPack", "Client's current Sniper voice pack, if equipped.", CookieAccess_Private);
	cookie_SpyPack = RegClientCookie("spyPack", "Client's current Spy voice pack, if equipped.", CookieAccess_Private);
	
	AddNormalSoundHook(view_as<NormalSHook>(NormalSoundHook));
	
	for (new i = MaxClients; i > 0; --i)
    {
        if (!AreClientCookiesCached(i))
        {
            continue;
        }
        
        OnClientCookiesCached(i);
    }
}

public OnClientCookiesCached(client)
{
    char scoutVal[16];
    GetClientCookie(client, cookie_ScoutPack, scoutVal, sizeof(scoutVal));
    scoutPack[client] = (scoutVal[0] != '\0' && StringToInt(scoutVal));
    
    char soldierVal[16];
    GetClientCookie(client, cookie_SoldierPack, soldierVal, sizeof(soldierVal));
    soldierPack[client] = (soldierVal[0] != '\0' && StringToInt(soldierVal));
    
    char pyroVal[16];
    GetClientCookie(client, cookie_PyroPack, pyroVal, sizeof(pyroVal));
    pyroPack[client] = (pyroVal[0] != '\0' && StringToInt(pyroVal));
    
    char demoVal[16];
    GetClientCookie(client, cookie_DemoPack, demoVal, sizeof(demoVal));
    demoPack[client] = (demoVal[0] != '\0' && StringToInt(demoVal));
    
    char heavyVal[16];
    GetClientCookie(client, cookie_HeavyPack, heavyVal, sizeof(heavyVal));
    heavyPack[client] = (heavyVal[0] != '\0' && StringToInt(heavyVal));
    
    char engieVal[16];
    GetClientCookie(client, cookie_EngiePack, engieVal, sizeof(engieVal));
    engiePack[client] = (engieVal[0] != '\0' && StringToInt(engieVal));
    
    char medicVal[16];
    GetClientCookie(client, cookie_MedicPack, medicVal, sizeof(medicVal));
    medicPack[client] = (medicVal[0] != '\0' && StringToInt(medicVal));
    
    char sniperVal[16];
    GetClientCookie(client, cookie_SniperPack, sniperVal, sizeof(sniperVal));
    sniperPack[client] = (sniperVal[0] != '\0' && StringToInt(sniperVal));
    
    char spyVal[16];
    GetClientCookie(client, cookie_SpyPack, spyVal, sizeof(spyVal));
    spyPack[client] = (spyVal[0] != '\0' && StringToInt(spyVal));
}

public void OnMapStart()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/voicepacks_content.cfg");
	
	if (!FileExists(path))
	{
		SetFailState("[Voice Packs] Unable to locate config (%s).", path);
	}
	
	if (config != null)
	{
		delete config;
	}
	
	config = new KeyValues("");
	
	if(config == null)
	{
		SetFailState("[Voice Packs] Failed to create KeyValues.");
	}
	
	config.ImportFromFile(path);
	
	voicePacks_ClassMenu = BuildMenu(0);
	voicePacks_ScoutMenu = BuildMenu(1);
	voicePacks_SoldierMenu = BuildMenu(2);
	voicePacks_PyroMenu = BuildMenu(3);
	voicePacks_DemoMenu = BuildMenu(4);
	voicePacks_HeavyMenu = BuildMenu(5);
	voicePacks_EngieMenu = BuildMenu(6);
	voicePacks_MedicMenu = BuildMenu(7);
	voicePacks_SniperMenu = BuildMenu(8);
	voicePacks_SpyMenu = BuildMenu(9);
}

Menu BuildMenu(int mode)
{
	if (config == null)
	{
		return null;
	}
	
	config.Rewind();
	
	Menu menu;
	int numPacks = 0;
	char KV_PackName[32] = "";
	char ClassName[32] = "";
	bool failed = false;
	
	if (mode != 0)
	{
		menu = new Menu (subMenu_Handler);
		menu.AddItem("return", "Go Back");
	}
	else
	{
		menu = new Menu(mainMenu_Handler);
	}
	
	switch(mode)
	{
		case 0:
		{
			menu.AddItem("Scout", "Scout");
			menu.AddItem("Soldier", "Soldier");
			menu.AddItem("Pyro", "Pyro");
			menu.AddItem("Demoman", "Demoman");
			menu.AddItem("Heavy", "Heavy");
			menu.AddItem("Engineer", "Engineer");
			menu.AddItem("Medic", "Medic");
			menu.AddItem("Sniper", "Sniper");
			menu.AddItem("Spy", "Spy");
			menu.SetTitle("Choose a class to set a voice pack:");
			return menu;
		}
		case 1:
		{
			KV_PackName = "scout_packs";
			ClassName = "Scout";
		}
		case 2:
		{
			KV_PackName = "soldier_packs";
			ClassName = "Soldier";
		}
		case 3:
		{
			KV_PackName = "pyro_packs";
			ClassName = "Pyro";
		}
		case 4:
		{
			KV_PackName = "demoman_packs";
			ClassName = "Demoman";
		}
		case 5:
		{
			KV_PackName = "heavy_packs";
			ClassName = "Heavy";
		}
		case 6:
		{
			KV_PackName = "engineer_packs";
			ClassName = "Engineer";
		}
		case 7:
		{
			KV_PackName = "medic_packs";
			ClassName = "Medic";
		}
		case 8:
		{
			KV_PackName = "sniper_packs";
			ClassName = "Sniper";
		}
		case 9:
		{
			KV_PackName = "spy_packs";
			ClassName = "Spy";
		}
		default:
		{
			LogError("[Voice Packs] Invalid mode (%i) passed to BuildMenu. Must be between 0 and 9.", mode);
			return null;
		}
	}
	
	if (config.JumpToKey(KV_PackName))
	{
		char secName[256];
		config.GetSectionName(secName, sizeof(secName));
		if (config.GotoFirstSubKey())
		{
			do
			{
				char packName[256];
				config.GetString("pack_name", packName, sizeof(packName), "null_value");
				if (!StrEqual(packName, "null_value", true))
				{
					menu.AddItem("pack", packName);
					numPacks++;
				}
			} while((config.GotoNextKey()));
		}
		else //If we fail to go to the first sub key, tell the user we have no packs.
		{
			failed = true;
		}
	}
	
	if (numPacks <= 0)
	{
		failed = true;
	}
	
	if (failed)
	{
		menu.SetTitle("There currently aren't any voice packs available for %s.", ClassName);
	}
	else
	{
		menu.SetTitle("Choose a voice pack for your %s:", ClassName);
	}
	
	return menu;
}

public int mainMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int choice = param2 + 1;
		temp_ClassNum[param1] = choice;
		
		switch (choice)
		{
			case 1:
			{
				if (voicePacks_ScoutMenu == null)
				{
					return;
				}
				voicePacks_ScoutMenu.Display(param1, MENU_TIME_FOREVER);
			}
			case 2:
			{
				if (voicePacks_SoldierMenu == null)
				{
					return;
				}
				voicePacks_SoldierMenu.Display(param1, MENU_TIME_FOREVER);
			}
			case 3:
			{
				if (voicePacks_PyroMenu == null)
				{
					return;
				}
				voicePacks_PyroMenu.Display(param1, MENU_TIME_FOREVER);
			}
			case 4:
			{
				if (voicePacks_DemoMenu == null)
				{
					return;
				}
				voicePacks_DemoMenu.Display(param1, MENU_TIME_FOREVER);
			}
			case 5:
			{
				if (voicePacks_HeavyMenu == null)
				{
					return;
				}
				voicePacks_HeavyMenu.Display(param1, MENU_TIME_FOREVER);
			}
			case 6:
			{
				if (voicePacks_EngieMenu == null)
				{
					return;
				}
				voicePacks_EngieMenu.Display(param1, MENU_TIME_FOREVER);
			}
			case 7:
			{
				if (voicePacks_MedicMenu == null)
				{
					return;
				}
				voicePacks_MedicMenu.Display(param1, MENU_TIME_FOREVER);
			}
			case 8:
			{
				if (voicePacks_SniperMenu == null)
				{
					return;
				}
				voicePacks_SniperMenu.Display(param1, MENU_TIME_FOREVER);
			}
			case 9:
			{
				if (voicePacks_SpyMenu == null)
				{
					return;
				}
				voicePacks_SpyMenu.Display(param1, MENU_TIME_FOREVER);
			}
		}
	}
}

public int subMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
		{
			voicePacks_ClassMenu.Display(param1, MENU_TIME_FOREVER);
			return;
		}
		
		if (config == null)
		{
			return;
		}
		
		config.Rewind();
		
		char KV_PackName[32] = "";
		char ClassName[32] = "";
		
		switch (temp_ClassNum[param1])
		{
			case 1:
			{
				KV_PackName = "scout_packs";
				ClassName = "Scout";
			}
			case 2:
			{
				KV_PackName = "soldier_packs";
				ClassName = "Soldier";
			}
			case 3:
			{
				KV_PackName = "pyro_packs";
				ClassName = "Pyro";
			}
			case 4:
			{
				KV_PackName = "demoman_packs";
				ClassName = "Demoman";
			}
			case 5:
			{
				KV_PackName = "heavy_packs";
				ClassName = "Heavy";
			}
			case 6:
			{
				KV_PackName = "engineer_packs";
				ClassName = "Engineer";
			}
			case 7:
			{
				KV_PackName = "medic_packs";
				ClassName = "Medic";
			}
			case 8:
			{
				KV_PackName = "sniper_packs";
				ClassName = "Sniper";
			}
			case 9:
			{
				KV_PackName = "spy_packs";
				ClassName = "Spy";
			}
			default:
			{
				return;
			}
		}
		
		if (!config.JumpToKey(KV_PackName))
		{
			return;
		}
		
		int choice = param2;
		temp_Key[param1] = choice;
		char iName[16];
		IntToString(choice, iName, sizeof(iName));
		
		if (config.GotoFirstSubKey())
		{
			voicePacks_InfoScreen[param1] = new Menu(preview_Handler);
			char secName[16];
			
			char name[256];
			char path[256];
			char example[256];
			char creator[256];
			char contributor[256];
			
			do
			{
				config.GetSectionName(secName, sizeof(secName));
				
				if (StrEqual(iName, secName))
				{
					config.GetString("pack_name", name, sizeof(name), "null_value");
					config.GetString("pack_path", path, sizeof(path), "null_value");
					config.GetString("pack_example", example, sizeof(example), "null_value");
					config.GetString("pack_creator", creator, sizeof(creator), "null_value");
					config.GetString("pack_contributor", contributor, sizeof(contributor), "null_value");
					
					char text[255] = "";
					
					if (!StrEqual(name, "null_value"))
					{
						Format(text, sizeof(text), "Sound Pack: %s\n", name);
					}
					else
					{
						Format(text, sizeof(text), "Sound Pack: Unidentified, please inform server owner.\n");
					}
					if (!StrEqual(creator, "null_value"))
					{
						char thing[255];
						Format(thing, sizeof(thing), "Creator: %s\n", creator);
						StrCat(text, sizeof(text), thing);
					}
					if (!StrEqual(contributor, "null_value"))
					{
						char thing[255];
						Format(thing, sizeof(thing), "Contributed By: %s\n", contributor);
						StrCat(text, sizeof(text), thing);
					}
					
					if (StrEqual(path, "null_value"))
					{
						LogError("[Voice Packs] Missing sound path for pack %s in %s.", secName, KV_PackName);
						return;
					}
					
					voicePacks_InfoScreen[param1].SetTitle(text);
				}
			} while (config.GotoNextKey());
			
			voicePacks_InfoScreen[param1].AddItem("confirmation", "Toggle");
			voicePacks_InfoScreen[param1].AddItem("cancel", "Cancel");
			voicePacks_InfoScreen[param1].AddItem("back", "Go Back");
			
			if (!StrEqual(example, "null_value"))
			{
				char filePath[PLATFORM_MAX_PATH];
				Format(filePath, sizeof(filePath), "sound/%s%s", path, example);
				if (FileExists(filePath))
				{
					voicePacks_InfoScreen[param1].AddItem("preview", "Play a Preview");
				}
			}
			
			voicePacks_InfoScreen[param1].Display(param1, MENU_TIME_FOREVER);
		}
	}
}

public int preview_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char className[16];
		char KVClassName[32];
		char packName[256] = "null_value";
		char exStr[256] = "null_value";
		char pathStr[256] = "null_value";
		switch (temp_ClassNum[param1])
		{
			case 1:
			{
				className = "Scout";
				KVClassName = "scout_packs";
			}
			case 2:
			{
				className = "Soldier";
				KVClassName = "soldier_packs";
			}
			case 3:
			{
				className = "Pyro";
				KVClassName = "pyro_packs";
			}
			case 4:
			{
				className = "Demoman";
				KVClassName = "demoman_packs";
			}
			case 5:
			{
				className = "Heavy";
				KVClassName = "heavy_packs";
			}
			case 6:
			{
				className = "Engineer";
				KVClassName = "engineer_packs";
			}
			case 7:
			{
				className = "Medic";
				KVClassName = "medic_packs";
			}
			case 8:
			{
				className = "Sniper";
				KVClassName = "sniper_packs";
			}
			case 9:
			{
				className = "Spy";
				KVClassName = "spy_packs";
			}
		}
		if (config == null)
		{
			return;
		}
		config.Rewind();
		if (config.JumpToKey(KVClassName))
		{
			char iName[16];
			IntToString(temp_Key[param1], iName, sizeof(iName));
			char secName[256];
			if (config.GotoFirstSubKey())
			{
				do
				{
					config.GetSectionName(secName, sizeof(secName));
					if (StrEqual(iName, secName))
					{
						config.GetString("pack_name", packName, sizeof(packName), "null_value");
						config.GetString("pack_example", exStr, sizeof(exStr), "null_value");
						config.GetString("pack_path", pathStr, sizeof(pathStr), "null_value");
					}
				} while((config.GotoNextKey()));
			}
		}
		
		switch (param2) //Case 1 is skipped, since it simply closes the menu and does nothing else.
		{
			case 0: //Equip/Unequip
			{
				if (!AreClientCookiesCached(param1))
				{
					CPrintToChat(param1, "{teal}[Voice Packs] {default}The server has not yet cached your cookies; please wait and try again.");
					voicePacks_InfoScreen[param1].Display(param1, MENU_TIME_FOREVER);
				}
				if (StrEqual(packName, "null_value"))
				{
					packName = "Your voice pack";
				}
				
				char voicePackStr[16];
				IntToString(temp_Key[param1], voicePackStr, sizeof(voicePackStr));
				//char cookieStr[16];
				
				switch(temp_ClassNum[param1]) //This is probably the worst way I could have done this, but at least it works. 
				{
					case 1:
					{
						if (scoutPack[param1] == temp_Key[param1])
						{
							SetClientCookie(param1, cookie_ScoutPack, "0");
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now disabled on %s.", packName, className);
						}
						else
						{
							SetClientCookie(param1, cookie_ScoutPack, voicePackStr);
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now enabled on %s.", packName, className);
						}
					}
					case 2:
					{
						if (soldierPack[param1] == temp_Key[param1])
						{
							SetClientCookie(param1, cookie_SoldierPack, "0");
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now disabled on %s.", packName, className);
						}
						else
						{
							SetClientCookie(param1, cookie_SoldierPack, voicePackStr);
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now enabled on %s.", packName, className);
						}
					}
					case 3:
					{
						if (pyroPack[param1] == temp_Key[param1])
						{
							SetClientCookie(param1, cookie_PyroPack, "0");
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now disabled on %s.", packName, className);
						}
						else
						{
							SetClientCookie(param1, cookie_PyroPack, voicePackStr);
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now enabled on %s.", packName, className);
						}
					}
					case 4:
					{
						if (demoPack[param1] == temp_Key[param1])
						{
							SetClientCookie(param1, cookie_DemoPack, "0");
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now disabled on %s.", packName, className);
						}
						else
						{
							SetClientCookie(param1, cookie_DemoPack, voicePackStr);
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now enabled on %s.", packName, className);
						}
					}
					case 5:
					{
						if (heavyPack[param1] == temp_Key[param1])
						{
							SetClientCookie(param1, cookie_HeavyPack, "0");
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now disabled on %s.", packName, className);
						}
						else
						{
							SetClientCookie(param1, cookie_HeavyPack, voicePackStr);
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now enabled on %s.", packName, className);
						}
					}
					case 6:
					{
						if (engiePack[param1] == temp_Key[param1])
						{
							SetClientCookie(param1, cookie_EngiePack, "0");
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now disabled on %s.", packName, className);
						}
						else
						{
							SetClientCookie(param1, cookie_EngiePack, voicePackStr);
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now enabled on %s.", packName, className);
						}
					}
					case 7:
					{
						if (medicPack[param1] == temp_Key[param1])
						{
							SetClientCookie(param1, cookie_MedicPack, "0");
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now disabled on %s.", packName, className);
						}
						else
						{
							SetClientCookie(param1, cookie_MedicPack, voicePackStr);
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now enabled on %s.", packName, className);
						}
					}
					case 8:
					{
						if (sniperPack[param1] == temp_Key[param1])
						{
							SetClientCookie(param1, cookie_SniperPack, "0");
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now disabled on %s.", packName, className);
						}
						else
						{
							SetClientCookie(param1, cookie_SniperPack, voicePackStr);
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now enabled on %s.", packName, className);
						}
					}
					case 9:
					{
						if (spyPack[param1] == temp_Key[param1])
						{
							SetClientCookie(param1, cookie_SpyPack, "0");
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now disabled on %s.", packName, className);
						}
						else
						{
							SetClientCookie(param1, cookie_SpyPack, voicePackStr);
							CPrintToChat(param1, "{teal}[Voice Packs] {default}%s is now enabled on %s.", packName, className);
						}
					}
				}
				OnClientCookiesCached(param1);
			}
			case 2: //Go Back
			{
				switch (temp_ClassNum[param1])
				{
					case 1:
					{
						voicePacks_ScoutMenu.Display(param1, MENU_TIME_FOREVER);
					}
					case 2:
					{
						voicePacks_SoldierMenu.Display(param1, MENU_TIME_FOREVER);
					}
					case 3:
					{
						voicePacks_PyroMenu.Display(param1, MENU_TIME_FOREVER);
					}
					case 4:
					{
						voicePacks_DemoMenu.Display(param1, MENU_TIME_FOREVER);
					}
					case 5:
					{
						voicePacks_HeavyMenu.Display(param1, MENU_TIME_FOREVER);
					}
					case 6:
					{
						voicePacks_EngieMenu.Display(param1, MENU_TIME_FOREVER);
					}
					case 7:
					{
						voicePacks_MedicMenu.Display(param1, MENU_TIME_FOREVER);
					}
					case 8:
					{
						voicePacks_SniperMenu.Display(param1, MENU_TIME_FOREVER);
					}
					case 9:
					{
						voicePacks_SpyMenu.Display(param1, MENU_TIME_FOREVER);
					}
				}
				temp_Key[param1] = 0;
				return;
			}
			case 3: //Play a Preview
			{
				char thing[256];
				Format(thing, sizeof(thing), "%s%s", pathStr, exStr);
				PrecacheSound(thing);
				EmitSoundToClient(param1, thing);
				voicePacks_InfoScreen[param1].Display(param1, MENU_TIME_FOREVER);
				return;
			}
		}
		
		temp_ClassNum[param1] = 0;
		temp_Key[param1] = 0;
	}
}

public Action NormalSoundHook(int clients[64],int &numClients,char strSound[PLATFORM_MAX_PATH],int &entity,int &channel,float &volume,int &level,int &pitch,int &flags)
{
	if (StrContains(strSound, "vo", false) == -1 || !IsValidClient(entity))
	{
		return Plugin_Continue;
	}
	
	switch(TF2_GetPlayerClass(entity))
	{
		case TFClass_Scout:
		{
			if (scoutPack[entity] <= 0)
			{
				return Plugin_Continue;
			}
			int startPoint = StrContains(strSound, "taunt_scout_", false);
			if (startPoint == -1)
			{
				startPoint = StrContains(strSound, "scout_", false);
			}
			if (startPoint != -1)
			{
				char path[PLATFORM_MAX_PATH];
				Format(path, sizeof(path), "%s%s", getPath(entity, 1), strSound[startPoint]);
				CStrToLower(path);
				char existence_Checker[PLATFORM_MAX_PATH];
				Format(existence_Checker, sizeof(existence_Checker), "sound/%s", path);
				if (FileExists(existence_Checker))
				{
					PrecacheSound(path);
					strcopy(strSound, sizeof(strSound), path);
					return Plugin_Changed;
				}
				else
				{
					return Plugin_Continue;
				}
			}
		}
		case TFClass_Soldier:
		{
			if (soldierPack[entity] <= 0)
			{
				return Plugin_Continue;
			}
			int startPoint = StrContains(strSound, "taunt_soldier_", false);
			if (startPoint == -1)
			{
				startPoint = StrContains(strSound, "soldier_", false);
			}
			if (startPoint != -1)
			{
				char path[PLATFORM_MAX_PATH];
				Format(path, sizeof(path), "%s%s", getPath(entity, 2), strSound[startPoint]);
				CStrToLower(path);
				char existence_Checker[PLATFORM_MAX_PATH];
				Format(existence_Checker, sizeof(existence_Checker), "sound/%s", path);
				if (FileExists(existence_Checker))
				{
					PrecacheSound(path);
					strcopy(strSound, sizeof(strSound), path);
					return Plugin_Changed;
				}
				else
				{
					return Plugin_Continue;
				}
			}
		}
		case TFClass_Pyro:
		{
			if (pyroPack[entity] <= 0)
			{
				return Plugin_Continue;
			}
			int startPoint = StrContains(strSound, "taunt_pyro_", false);
			if (startPoint == -1)
			{
				startPoint = StrContains(strSound, "pyro_", false);
			}
			if (startPoint != -1)
			{
				char path[PLATFORM_MAX_PATH];
				Format(path, sizeof(path), "%s%s", getPath(entity, 3), strSound[startPoint]);
				CStrToLower(path);
				char existence_Checker[PLATFORM_MAX_PATH];
				Format(existence_Checker, sizeof(existence_Checker), "sound/%s", path);
				if (FileExists(existence_Checker))
				{
					PrecacheSound(path);
					strcopy(strSound, sizeof(strSound), path);
					return Plugin_Changed;
				}
				else
				{
					return Plugin_Continue;
				}
			}
		}
		case TFClass_DemoMan:
		{
			if (demoPack[entity] <= 0)
			{
				return Plugin_Continue;
			}
			int startPoint = StrContains(strSound, "taunt_demoman_", false);
			if (startPoint == -1)
			{
				startPoint = StrContains(strSound, "demoman_", false);
			}
			if (startPoint != -1)
			{
				char path[PLATFORM_MAX_PATH];
				Format(path, sizeof(path), "%s%s", getPath(entity, 4), strSound[startPoint]);
				CStrToLower(path);
				char existence_Checker[PLATFORM_MAX_PATH];
				Format(existence_Checker, sizeof(existence_Checker), "sound/%s", path);
				if (FileExists(existence_Checker))
				{
					PrecacheSound(path);
					strcopy(strSound, sizeof(strSound), path);
					return Plugin_Changed;
				}
				else
				{
					return Plugin_Continue;
				}
			}
		}
		case TFClass_Heavy:
		{
			if (heavyPack[entity] <= 0)
			{
				return Plugin_Continue;
			}
			int startPoint = StrContains(strSound, "taunt_heavy_", false);
			if (startPoint == -1)
			{
				startPoint = StrContains(strSound, "heavy_", false);
			}
			if (startPoint != -1)
			{
				char path[PLATFORM_MAX_PATH];
				Format(path, sizeof(path), "%s%s", getPath(entity, 5), strSound[startPoint]);
				CStrToLower(path);
				char existence_Checker[PLATFORM_MAX_PATH];
				Format(existence_Checker, sizeof(existence_Checker), "sound/%s", path);
				if (FileExists(existence_Checker))
				{
					PrecacheSound(path);
					strcopy(strSound, sizeof(strSound), path);
					return Plugin_Changed;
				}
				else
				{
					return Plugin_Continue;
				}
			}
		}
		case TFClass_Engineer:
		{
			if (engiePack[entity] <= 0)
			{
				return Plugin_Continue;
			}
			int startPoint = StrContains(strSound, "taunt_engineer_", false);
			if (startPoint == -1)
			{
				startPoint = StrContains(strSound, "engineer_", false);
			}
			if (startPoint == -1)
			{
				startPoint = StrContains(strSound, "eng_", false);
			}
			if (startPoint != -1)
			{
				char path[PLATFORM_MAX_PATH];
				Format(path, sizeof(path), "%s%s", getPath(entity, 6), strSound[startPoint]);
				CStrToLower(path);
				char existence_Checker[PLATFORM_MAX_PATH];
				Format(existence_Checker, sizeof(existence_Checker), "sound/%s", path);
				if (FileExists(existence_Checker))
				{
					PrecacheSound(path);
					strcopy(strSound, sizeof(strSound), path);
					return Plugin_Changed;
				}
				else
				{
					return Plugin_Continue;
				}
			}
		}
		case TFClass_Medic:
		{
			if (medicPack[entity] <= 0)
			{
				return Plugin_Continue;
			}
			int startPoint = StrContains(strSound, "taunt_medic_", false);
			if (startPoint == -1)
			{
				startPoint = StrContains(strSound, "medic_", false);
			}
			if (startPoint != -1)
			{
				char path[PLATFORM_MAX_PATH];
				Format(path, sizeof(path), "%s%s", getPath(entity, 7), strSound[startPoint]);
				CStrToLower(path);
				char existence_Checker[PLATFORM_MAX_PATH];
				Format(existence_Checker, sizeof(existence_Checker), "sound/%s", path);
				if (FileExists(existence_Checker))
				{
					PrecacheSound(path);
					strcopy(strSound, sizeof(strSound), path);
					return Plugin_Changed;
				}
				else
				{
					return Plugin_Continue;
				}
			}
		}
		case TFClass_Sniper:
		{
			if (sniperPack[entity] <= 0)
			{
				return Plugin_Continue;
			}
			int startPoint = StrContains(strSound, "taunt_sniper_", false);
			if (startPoint == -1)
			{
				startPoint = StrContains(strSound, "sniper_", false);
			}
			if (startPoint != -1)
			{
				char path[PLATFORM_MAX_PATH];
				Format(path, sizeof(path), "%s%s", getPath(entity, 8), strSound[startPoint]);
				CStrToLower(path);
				char existence_Checker[PLATFORM_MAX_PATH];
				Format(existence_Checker, sizeof(existence_Checker), "sound/%s", path);
				if (FileExists(existence_Checker))
				{
					PrecacheSound(path);
					strcopy(strSound, sizeof(strSound), path);
					return Plugin_Changed;
				}
				else
				{
					return Plugin_Continue;
				}
			}
		}
		case TFClass_Spy:
		{
			if (spyPack[entity] <= 0)
			{
				return Plugin_Continue;
			}
			int startPoint = StrContains(strSound, "taunt_spy_", false);
			if (startPoint == -1)
			{
				startPoint = StrContains(strSound, "spy_", false);
			}
			if (startPoint != -1)
			{
				char path[PLATFORM_MAX_PATH];
				Format(path, sizeof(path), "%s%s", getPath(entity, 9), strSound[startPoint]);
				CStrToLower(path);
				char existence_Checker[PLATFORM_MAX_PATH];
				Format(existence_Checker, sizeof(existence_Checker), "sound/%s", path);
				if (FileExists(existence_Checker))
				{
					PrecacheSound(path);
					strcopy(strSound, sizeof(strSound), path);
					return Plugin_Changed;
				}
				else
				{
					return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action showMenu(int client, int args)
{
	if (IsValidClient(client))
	{
		if (voicePacks_ClassMenu == null)
		{
			LogError("[Voice Packs] The main menu failed to build.");
			return Plugin_Handled;
		}
		voicePacks_ClassMenu.Display(client, MENU_TIME_FOREVER); 
	}
	return Plugin_Handled;
}

stock char getPath(int client, int class)
{
	char pathStr[128] = "";
	char KVClassName[16] = "null_value";
	char cookieValue[16];
	
	if (config == null)
	{
		return pathStr;
	}
	config.Rewind();
	
	if (IsValidClient(client))
	{
		switch(class)
		{
			case 1:
			{
				GetClientCookie(client, cookie_ScoutPack, cookieValue, sizeof(cookieValue));
				KVClassName = "scout_packs";
			}
			case 2:
			{
				GetClientCookie(client, cookie_SoldierPack, cookieValue, sizeof(cookieValue));
				KVClassName = "soldier_packs";
			}
			case 3:
			{
				GetClientCookie(client, cookie_PyroPack, cookieValue, sizeof(cookieValue));
				KVClassName = "pyro_packs";
			}
			case 4:
			{
				GetClientCookie(client, cookie_DemoPack, cookieValue, sizeof(cookieValue));
				KVClassName = "demoman_packs";
			}
			case 5:
			{
				GetClientCookie(client, cookie_HeavyPack, cookieValue, sizeof(cookieValue));
				KVClassName = "heavy_packs";
			}
			case 6:
			{
				GetClientCookie(client, cookie_EngiePack, cookieValue, sizeof(cookieValue));
				KVClassName = "engineer_packs";
			}
			case 7:
			{
				GetClientCookie(client, cookie_MedicPack, cookieValue, sizeof(cookieValue));
				KVClassName = "medic_packs";
			}
			case 8:
			{
				GetClientCookie(client, cookie_SniperPack, cookieValue, sizeof(cookieValue));
				KVClassName = "sniper_packs";
			}
			case 9:
			{
				GetClientCookie(client, cookie_SpyPack, cookieValue, sizeof(cookieValue));
				KVClassName = "spy_packs";
			}
		}
	}
	
	if (config.JumpToKey(KVClassName))
	{
		char secName[256];
		if (config.GotoFirstSubKey())
		{
			do
			{
				config.GetSectionName(secName, sizeof(secName));
				if (StrEqual(cookieValue, secName))
				{
					config.GetString("pack_path", pathStr, sizeof(pathStr), "null_value");
					return pathStr;
				}
			} while((config.GotoNextKey()));
		}
	}
	
	return pathStr;
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}
	if(!IsClientInGame(client))
	{
		return false;
	}
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}
	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}