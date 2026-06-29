#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <admin>
#include <morecolors>
#include <tf2items>
#include <itemsgame>

#define PLUGIN_NAME         "Particle Effects"
#define PLUGIN_AUTHOR       "Erreur 500 (Modified by Mr. Man"
#define PLUGIN_DESCRIPTION	"Add particle effect on items"
#define PLUGIN_VERSION      "1.01"
#define PLUGIN_CONTACT      "erreur500@hotmail.fr"

new ItemsID[100];
new Quality[MAXPLAYERS+1];
new Menu[MAXPLAYERS+1];
new ClientItems[MAXPLAYERS+1];
new ClassSelected[MAXPLAYERS+1];

new String:ClientSteamID[MAXPLAYERS+1][60];
new String:Tf2Items[128];

static String:ClassNames[TFClassType][] = {"ANY", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer"};

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
	CreateConVar("particle_version", PLUGIN_VERSION, "Unusual version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_Immunity	= CreateConVar("particle_immunity", "0", "a or b or o or p or q or r or s or t or z for flag needed, 0 = disabled flag needed");
	RegConsoleCmd("particle", CheckAdmin, "Apply particle effects on weapons");
	
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
			CPrintToChat(iClient, "{Purple}[Particles] {default} You don't have access to this command.");
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
			CPrintToChat(iClient, "{Purple}[Particles] {default} You don't have access to this command.");
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
		SetMenuTitle(Menu1, "Particle Attachment Menu");
		AddMenuItem(Menu1, "0", "Attach to Equipped Weapons");
		AddMenuItem(Menu1, "1", "Clear Effect");
		
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
				CPrintToChat(iClient, "{Purple}[Particles] {default} You must be on either a team to use this feature.");
		else if(args == 1)
			DeleteWeapPanel(iClient);
	}
}

//--------------------------------------------------------------------------------------
//							Equipped Weapons
//--------------------------------------------------------------------------------------

AddEquipedWeapPanel(iClient)
{
	new Handle:WeapMenu;
	new SlotMax;
	new Weap;
	decl String:WeapName[64];
	decl String:strWeap[5];

	WeapMenu = CreateMenu(WeapMenu1);

	
	SetMenuTitle(WeapMenu, "Select Weapon");
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
			ItemsGameInfo(Weap, "name", WeapName, sizeof(WeapName));
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
//							All Weapons
//--------------------------------------------------------------------------------------

public ChooseSlotMenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		new String:strSlot[32];
		new String:strRtrnSlt[32];
		new String:strReturn[128];
		
		GetMenuItem(menu, args, strSlot, sizeof(strSlot));
		
		new Handle:AllweapMenu = CreateMenu(AllweapMenuAnswer);
		SetMenuTitle(AllweapMenu, "Select Weapon");
		
		new String:ClassParametre[60];
		new j = 0;
		Format(ClassParametre, sizeof(ClassParametre), "used_by_classes => %s",ClassNames[ClassSelected[iClient]]);
		new Handle:hArray = ItemsGameSearch(ClassParametre, ITEMSGAME_RETURN_INDEX);
		for (new i = 0; i < GetArraySize(hArray); i++)
		{  
			ItemsGameInfo(GetArrayCell(hArray, i), "slot", strRtrnSlt, sizeof(strRtrnSlt));
			if(StrEqual (strSlot, strRtrnSlt))
			{
				ItemsID[j] = GetArrayCell(hArray, i);
				ItemsGameInfo(ItemsID[j], "name", strReturn, sizeof(strReturn));
				AddMenuItem(AllweapMenu, "i", strReturn);
				j++;
			}
		}
		CloseHandle(hArray);

		SetMenuExitButton(AllweapMenu, true);
		DisplayMenu(AllweapMenu, iClient, MENU_TIME_FOREVER);
	}	
}

public AllweapMenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		ClientItems[iClient] = ItemsID[args];
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
		
	SetMenuTitle(YourItemsMenu, "What Item?");
	FileToKeyValues(kv, Tf2Items);
		
	if(!KvJumpToKey(kv, ClientSteamID[iClient], false))
	{
		CPrintToChat(iClient, "{Purple}[Particles] {default} All applied particles removed.");
		return;
	}
		
	KvGotoFirstSubKey(kv, true);
	KvGetSectionName(kv, section, sizeof(section));
	new SectionID = StringToInt(section); 
	ItemsGameInfo(SectionID, "name", ItemsName, sizeof(ItemsName));
	AddMenuItem(YourItemsMenu, section, ItemsName);
			
	while(KvGotoNextKey(kv, true))
	{	
		KvGetSectionName(kv, section, sizeof(section)); 
		SectionID = StringToInt(section); 
		ItemsGameInfo(SectionID, "name", ItemsName, sizeof(ItemsName));
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
			ServerCommand("sm plugins reload TF2_tf2items.smx");
			CPrintToChat(iClient, "{purple}[Particles] {default} Particle effect removed. Switch to another class then back to original class to see changes.");
			DeleteWeapPanel(iClient);
		}
		else
		{
			CPrintToChat(iClient, "{purple}[Particles] {default} Cannot find entry.");
		}
	}	
}

//--------------------------------------------------------------------------------------
//							Quality + Effect
//--------------------------------------------------------------------------------------

QualityMenu(iClient)
{
	new Handle:Qltymenu = CreateMenu(QltymenuAnswer);
	SetMenuTitle(Qltymenu, "Select Item Quality");
	
	AddMenuItem(Qltymenu, "0", "Normal");
	AddMenuItem(Qltymenu, "1", "Genuine");
	AddMenuItem(Qltymenu, "2", "Rarity 2");
	AddMenuItem(Qltymenu, "3", "Vintage");
	AddMenuItem(Qltymenu, "4", "Orange");
	AddMenuItem(Qltymenu, "5", "Unusual");
	AddMenuItem(Qltymenu, "6", "Unique");
	AddMenuItem(Qltymenu, "7", "Community-Made");
	AddMenuItem(Qltymenu, "8", "Valve");
	AddMenuItem(Qltymenu, "9", "Self-Made");
	AddMenuItem(Qltymenu, "10", "Customized");
	AddMenuItem(Qltymenu, "11", "Strange");
	AddMenuItem(Qltymenu, "12", "Completed");
	AddMenuItem(Qltymenu, "13", "Haunted");
	AddMenuItem(Qltymenu, "14", "Tobor A");
	
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
	SetMenuTitle(UnusualMenu, "Select Particle Effect");

	AddMenuItem(UnusualMenu, "1", "Particle 1 (Red)");
	AddMenuItem(UnusualMenu, "2", "Flying Bits");
	AddMenuItem(UnusualMenu, "3", "Nemesis Burst");
	AddMenuItem(UnusualMenu, "4", "Community Sparkle");
	AddMenuItem(UnusualMenu, "5", "Holy Glow");
	AddMenuItem(UnusualMenu, "6", "Green Confetti");
	AddMenuItem(UnusualMenu, "7", "Purple Confetti");
	AddMenuItem(UnusualMenu, "8", "Haunted Ghost");
	AddMenuItem(UnusualMenu, "9", "Green Energy Plasma");
	AddMenuItem(UnusualMenu, "10", "Purple Energy Plasma");
	AddMenuItem(UnusualMenu, "11", "Circling TF Logo");
	AddMenuItem(UnusualMenu, "12", "Massed Flies");
	AddMenuItem(UnusualMenu, "13", "Burning Flame (Red)");
	AddMenuItem(UnusualMenu, "14", "Burning Flame (Green)");
	AddMenuItem(UnusualMenu, "15", "Searing Plasma");
	AddMenuItem(UnusualMenu, "16", "Vivid Plasma");
	AddMenuItem(UnusualMenu, "17", "Sunbeams");
	AddMenuItem(UnusualMenu, "18", "Circling Peace Sign");
	AddMenuItem(UnusualMenu, "19", "Circling Heart");
	AddMenuItem(UnusualMenu, "20", "Stamp Pin");
	AddMenuItem(UnusualMenu, "28", "Pipe Smoke");
	AddMenuItem(UnusualMenu, "29", "Stormy Storm");
	AddMenuItem(UnusualMenu, "30", "Blizzardy Storm");
	AddMenuItem(UnusualMenu, "31", "Nuts and Bolts");
	AddMenuItem(UnusualMenu, "32", "Orbiting Planets");
	AddMenuItem(UnusualMenu, "33", "Orbiting Fire");
	AddMenuItem(UnusualMenu, "34", "Bubbling");
	AddMenuItem(UnusualMenu, "35", "Smoking");
	AddMenuItem(UnusualMenu, "36", "Steaming");
	AddMenuItem(UnusualMenu, "37", "Orbiting Flaming Lantern");
	AddMenuItem(UnusualMenu, "38", "Cloudy Moon");
	AddMenuItem(UnusualMenu, "39", "Cauldron Bubbles");
	AddMenuItem(UnusualMenu, "40", "Orbiting Eerie Fire");
	AddMenuItem(UnusualMenu, "43", "Knifestorm");
	AddMenuItem(UnusualMenu, "44", "Misty Skull");
	AddMenuItem(UnusualMenu, "45", "Harvest Moon");
	AddMenuItem(UnusualMenu, "46", "It's a Secret to Everybody");
	AddMenuItem(UnusualMenu, "47", "Stormy 13th Hour");

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
		
		ServerCommand("sm plugins reload TF2_tf2items.smx"); 
		CPrintToChat(iClient, "{Purple}[Particles] {default} Particle applied. Switch to another class then back to original class to see changes.");
	}	
}