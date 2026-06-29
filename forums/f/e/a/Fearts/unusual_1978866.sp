#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <tf2itemsinfo>


#define PLUGIN_NAME         "Unusual"
#define PLUGIN_AUTHOR       "Erreur 500"
#define PLUGIN_DESCRIPTION	"Add Unusuals effects on your weapons"
#define PLUGIN_VERSION      "2.01"
#define PLUGIN_CONTACT      "erreur500@hotmail.fr"


new Quality[MAXPLAYERS+1];
new Menu[MAXPLAYERS+1];
new ClientItems[MAXPLAYERS+1];

new String:ClientSteamID[MAXPLAYERS+1][60];
new String:Tf2Items[128];

new Handle: kv;
new Handle:c_Immunity = INVALID_HANDLE;





public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

public OnPluginStart()
{	
	CreateConVar("unusual_version", PLUGIN_VERSION, "Unusual version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_Immunity	= CreateConVar("unusual_immunity", "r", "Need Flag ? a or b or o or p or q or r or s or t or z, 0 = disabled flag needed");
	RegConsoleCmd("unusual", CheckAdmin, "Get unusual effect on your weapons");
	
	LoadTranslations("unusual.phrases");
	
	BuildPath(Path_SM,Tf2Items,sizeof(Tf2Items),"configs/tf2items.weapons.txt");
}

//--------------------------------------------------------------------------------------
//							Securities
//--------------------------------------------------------------------------------------

stock bool:IsValidClient(iClient)
{
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	return IsClientInGame(iClient);
}

public Action:CheckAdmin(iClient, Args)
{	
	decl String:FlagNeeded[2];
	GetConVarString(c_Immunity, FlagNeeded, sizeof(FlagNeeded)); 
	if(StrEqual(FlagNeeded, "0"))
	{
		FirstMenu(iClient);
	}
	else
	{
		new flags = GetUserFlagBits(iClient);
		if(flags == 0)
		{
			CPrintToChat(iClient, "%t","Sent1");
			return;
		}
		else if((flags & ADMFLAG_ROOT) && StrEqual(FlagNeeded, "z"))
			FirstMenu(iClient);
		else if((flags & ADMFLAG_RESERVATION) && StrEqual(FlagNeeded, "a"))
			FirstMenu(iClient);
		else if((flags & ADMFLAG_GENERIC) && StrEqual(FlagNeeded, "b"))
			FirstMenu(iClient);
		else if((flags & ADMFLAG_CUSTOM1) && StrEqual(FlagNeeded, "o"))
			FirstMenu(iClient);
		else if((flags & ADMFLAG_CUSTOM2) && StrEqual(FlagNeeded, "p"))
			FirstMenu(iClient);
		else if((flags & ADMFLAG_CUSTOM3) && StrEqual(FlagNeeded, "q"))
			FirstMenu(iClient);
		else if((flags & ADMFLAG_CUSTOM4) && StrEqual(FlagNeeded, "r"))
			FirstMenu(iClient);
		else if((flags & ADMFLAG_CUSTOM5) && StrEqual(FlagNeeded, "s"))
			FirstMenu(iClient);
		else if((flags & ADMFLAG_CUSTOM6) && StrEqual(FlagNeeded, "t"))
			FirstMenu(iClient);
		else
		{
			CPrintToChat(iClient, "%t","Sent1");
			return;
		}
	}
}

//--------------------------------------------------------------------------------------
//							Menu selection
//--------------------------------------------------------------------------------------
	
FirstMenu(iClient)
{	
	if(IsValidClient(iClient))
	{
		new String:PlayerInfo[60];
		new Handle:Menu1 = CreateMenu(Menu1_1);
		SetMenuTitle(Menu1, "What do you want ?");
		AddMenuItem(Menu1, "0", "Add/modify new weapons");
		AddMenuItem(Menu1, "1", "Delete effects");
		
		GetClientAuthString(iClient, PlayerInfo, sizeof(PlayerInfo));
		strcopy(ClientSteamID[iClient], 60, PlayerInfo);
		
		SetMenuExitButton(Menu1, true);
		DisplayMenu(Menu1, iClient, MENU_TIME_FOREVER);
	}
}

public Menu1_1(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		if(args == 0)
			if(GetClientTeam(iClient) == 2 || GetClientTeam(iClient) == 3)
				AddEquipedWeapPanel(iClient);
			else
				CPrintToChat(iClient, "%t","Sent2");
		else if(args == 1)
		{
			Menu[iClient] = 1;
			DeleteWeapPanel(iClient);
		}
	}
}

//--------------------------------------------------------------------------------------
//							Equiped weapons
//--------------------------------------------------------------------------------------

AddEquipedWeapPanel(iClient)
{
	new Handle:WeapMenu;
	new SlotMax;
	new Weap;
	decl String:WeapName[64];
	decl String:strWeap[5];

	WeapMenu = CreateMenu(WeapMenu1);

	SetMenuTitle(WeapMenu, "Select your weapon");
	new TFClassType:Class = TF2_GetPlayerClass(iClient);
	if(Class == TFClassType:8)
		SlotMax = 4;
	else if(Class == TFClassType:9)
		SlotMax = 5;
	else
		SlotMax = 2;
		
	for(new i = 0; i <= SlotMax ; i++)
	{
		Weap = GetPlayerWeaponSlot(iClient, i)
		if(Weap != -1)
		{
			Weap = GetEntProp(Weap, Prop_Send, "m_iItemDefinitionIndex");
			TF2II_GetItemName(Weap, WeapName, sizeof(WeapName)); 
			IntToString(Weap, strWeap, sizeof(strWeap));
			AddMenuItem(WeapMenu, strWeap, WeapName);
		}
	}
	SetMenuExitButton(WeapMenu, true);
	DisplayMenu(WeapMenu, iClient, MENU_TIME_FOREVER);
}

public WeapMenu1(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:strWeapID[5];
		GetMenuItem(menu, args, strWeapID, sizeof(strWeapID));
		ClientItems[iClient] = StringToInt(strWeapID); 
		Menu[iClient] = 0;
		QualityMenu(iClient);
	}	
}

//--------------------------------------------------------------------------------------
//							Remove Effect
//--------------------------------------------------------------------------------------

DeleteWeapPanel(iClient)
{
	kv = CreateKeyValues("custom_weapons_v3");
	new String:section[7];
	new String:ItemsName[64];
	new Handle:YourItemsMenu = CreateMenu(YourItemsMenuAnswer);
		
	SetMenuTitle(YourItemsMenu, "What items ?");
	FileToKeyValues(kv, Tf2Items);
		
	if(!KvJumpToKey(kv, ClientSteamID[iClient], false))
	{
		CPrintToChat(iClient, "%t","Sent3");
		return;
	}
		
	KvGotoFirstSubKey(kv, true);
	KvGetSectionName(kv, section, sizeof(section));
	new SectionID = StringToInt(section); 
	TF2II_GetItemName(SectionID, ItemsName, sizeof(ItemsName));
	AddMenuItem(YourItemsMenu, section, ItemsName);
			
	while(KvGotoNextKey(kv, true))
	{	
		KvGetSectionName(kv, section, sizeof(section)); 
		SectionID = StringToInt(section); 
		TF2II_GetItemName(SectionID, ItemsName, sizeof(ItemsName));
		AddMenuItem(YourItemsMenu, section, ItemsName);
	}
	SetMenuExitButton(YourItemsMenu, true);
	DisplayMenu(YourItemsMenu, iClient, MENU_TIME_FOREVER);
}

public YourItemsMenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		new String:WeapID[7];
		kv = CreateKeyValues("custom_weapons_v3");
		
		FileToKeyValues(kv, Tf2Items);
		
		KvJumpToKey(kv, ClientSteamID[iClient], true);
		GetMenuItem(menu, args, WeapID, sizeof(WeapID));
			
		if(KvDeleteKey(kv, WeapID))
		{
			KvRewind(kv);
			KeyValuesToFile(kv, Tf2Items);
			CloseHandle(kv);
			ServerCommand("sm plugins reload tf2items_manager.smx");
			CPrintToChat(iClient, "%t", "Sent4");
			DeleteWeapPanel(iClient);
		}
		else
		{
			CPrintToChat(iClient, "%t","Sent5");
		}
	}	
}

//--------------------------------------------------------------------------------------
//							Quality + Effect
//--------------------------------------------------------------------------------------

QualityMenu(iClient)
{
	new Handle:Qltymenu = CreateMenu(QltymenuAnswer);
	SetMenuTitle(Qltymenu, "Select quality :");
	
	AddMenuItem(Qltymenu, "0", "Normal");
	AddMenuItem(Qltymenu, "1", "Vintage");
	AddMenuItem(Qltymenu, "2", "Unique");
	AddMenuItem(Qltymenu, "3", "Community");
	AddMenuItem(Qltymenu, "4", "Selfmade");
	AddMenuItem(Qltymenu, "5", "Strange");
	AddMenuItem(Qltymenu, "6", "Haunted");
	
	SetMenuExitButton(Qltymenu, true);
	DisplayMenu(Qltymenu, iClient, MENU_TIME_FOREVER);
}

public QltymenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		Quality[iClient] = args;
		PanelEffect(iClient);
	}
}

PanelEffect(iClient)
{
	new Handle:UnusualMenu = CreateMenu(UnusualMenuAnswer);
	SetMenuTitle(UnusualMenu, "Select Unusual effect :");

	AddMenuItem(UnusualMenu, "6", "Green Confetti");
	AddMenuItem(UnusualMenu, "7", "Confetti Purple");
	AddMenuItem(UnusualMenu, "8", "Haunted Ghosts");
	AddMenuItem(UnusualMenu, "9", "Green Energy");
	AddMenuItem(UnusualMenu, "10", "Purple Energy");
	AddMenuItem(UnusualMenu, "11", "Circling TF Logo ");
	AddMenuItem(UnusualMenu, "12", "Massed Flies");
	AddMenuItem(UnusualMenu, "13", "Burning Flames");
	AddMenuItem(UnusualMenu, "14", "Scorching Flames");
	AddMenuItem(UnusualMenu, "15", "Searing Plasma");
	AddMenuItem(UnusualMenu, "16", "Vivid Plasma");
	AddMenuItem(UnusualMenu, "17", "Sunbeams");
	AddMenuItem(UnusualMenu, "18", "Circling Peace Sign");
	AddMenuItem(UnusualMenu, "19", "Circling Heart");
	AddMenuItem(UnusualMenu, "29", "Stormy Storm");
	AddMenuItem(UnusualMenu, "30", "Blizzardy Storm");
	AddMenuItem(UnusualMenu, "31", "Nuts n' Bolts");
	AddMenuItem(UnusualMenu, "32", "Orbiting Planets");
	AddMenuItem(UnusualMenu, "33", "Orbiting Fire ");
	AddMenuItem(UnusualMenu, "34", "Bubbling");
	AddMenuItem(UnusualMenu, "35", "Smoking");
	AddMenuItem(UnusualMenu, "36", "Steaming");
	AddMenuItem(UnusualMenu, "37", "Flaming Lantern");
	AddMenuItem(UnusualMenu, "38", "Cloudy Moon");
	AddMenuItem(UnusualMenu, "39", "Cauldron Bubbles");
	AddMenuItem(UnusualMenu, "40", "Eerie Orbiting Fire");
	AddMenuItem(UnusualMenu, "43", "Knifestorm");
	AddMenuItem(UnusualMenu, "44", "Misty Skull");
	AddMenuItem(UnusualMenu, "45", "Harvest Moon");
	AddMenuItem(UnusualMenu, "46", "It's A Secret To Everybody");
	AddMenuItem(UnusualMenu, "47", "Stormy 13th Hour");
	AddMenuItem(UnusualMenu, "55", "Aces High Blue");
	AddMenuItem(UnusualMenu, "59", "Aces High Red");
	AddMenuItem(UnusualMenu, "56", "Kill-a-Watt");
	AddMenuItem(UnusualMenu, "57", "Terror-Watt");
	AddMenuItem(UnusualMenu, "58", "Cloud 9");
	AddMenuItem(UnusualMenu, "60", "Dead Presidents");
	AddMenuItem(UnusualMenu, "61", "Miami Nights");
	AddMenuItem(UnusualMenu, "62", "Disco Beat Down");
	AddMenuItem(UnusualMenu, "47", "Stormy 13th Hour");
	AddMenuItem(UnusualMenu, "63", "Phosphorous");
	AddMenuItem(UnusualMenu, "64", "Sulphurous");
	AddMenuItem(UnusualMenu, "65", "Memory Leak");
	AddMenuItem(UnusualMenu, "66", "Overclocked");
	AddMenuItem(UnusualMenu, "67", "Electrostatic");
	AddMenuItem(UnusualMenu, "68", "Power Surge");
	AddMenuItem(UnusualMenu, "69", "Anti-Freeze");
	AddMenuItem(UnusualMenu, "72", "Roboactive");
	AddMenuItem(UnusualMenu, "70", "Time Warp");
	AddMenuItem(UnusualMenu, "71", "Green Black Hole");
	AddMenuItem(UnusualMenu, "1", "Burning Red");
	AddMenuItem(UnusualMenu, "2", "Flyingbits");
	AddMenuItem(UnusualMenu, "3", "Nemesis Burst");
	AddMenuItem(UnusualMenu, "4", "Community Sparkle");
	AddMenuItem(UnusualMenu, "20", "Stamps");
	AddMenuItem(UnusualMenu, "28", "Pipe Smoke");

	SetMenuExitButton(UnusualMenu, true);
	DisplayMenu(UnusualMenu, iClient, MENU_TIME_FOREVER);
}

public UnusualMenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		new String:Effect[3];
		new String:Unusual[10];
		new String:strName[5];
		new String:strQuality[3];
		
		
		GetMenuItem(menu, args, Effect, sizeof(Effect));
		kv = CreateKeyValues("custom_weapons_v3");
		
		FileToKeyValues(kv, Tf2Items);
		
		KvJumpToKey(kv, ClientSteamID[iClient], true);
		
		Format(strName, sizeof(strName), "%d",ClientItems[iClient]);
		
		if(!KvJumpToKey(kv, strName, false))
		{
			KvJumpToKey(kv, strName, true);
			KvSetString(kv, "level", "100"); 
			Format(strQuality, sizeof(strQuality), "%d",Quality[iClient]);
			KvSetString(kv, "quality", strQuality); 
			KvSetString(kv, "preserve-attributes", "1");
			Format(Unusual, sizeof(Unusual), "134 ; %s",Effect);
			KvSetString(kv, "1", Unusual);
		}
		else
		{
			Format(strQuality, sizeof(strQuality), "%d",Quality[iClient]);
			KvSetString(kv, "quality", strQuality);
			Format(Unusual, sizeof(Unusual), "134 ; %s",Effect);
			KvSetString(kv, "1", Unusual);
		}
		KvRewind(kv);
		KeyValuesToFile(kv, Tf2Items);
		CloseHandle(kv);
		
		ServerCommand("sm plugins reload tf2items_manager.smx"); 
		CPrintToChat(iClient, "%t", "Sent6");
		
		if(Menu[iClient] == 0)
			AddEquipedWeapPanel(iClient);
		else if(Menu[iClient] == 1)
			DeleteWeapPanel(iClient);
	}	
}



