#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <tf2itemsinfo>


#define PLUGIN_NAME         "Unusual"
#define PLUGIN_AUTHOR       "Erreur 500"
#define PLUGIN_DESCRIPTION	"Add Unusuals effects on your weapons"
#define PLUGIN_VERSION      "2.12"
#define PLUGIN_CONTACT      "erreur500@hotmail.fr"
#define EFFECTSFILE			"unusual_list.cfg"
#define PERMISSIONFILE		"unusual_permissions.cfg"
#define DATAFILE			"unusual_effects.txt"
#define WEBSITE 			"http://bit.ly/1aYK7zo"


new Quality[MAXPLAYERS+1];
new ClientItems[MAXPLAYERS+1];
new EntitiesID[MAXPLAYERS+1];

new String:ClientSteamID[MAXPLAYERS+1][60];
new String:ClassName[MAXPLAYERS+1][64];

new String:UnusualEffect[PLATFORM_MAX_PATH];
new String:EffectsList[PLATFORM_MAX_PATH];
new String:PermissionsFile[PLATFORM_MAX_PATH];

new bool:FirstControl[MAXPLAYERS+1] = {false, ...};

new Permission[22] 					= {0, ...};
new FlagsList[21] 					= {ADMFLAG_RESERVATION, ADMFLAG_GENERIC, ADMFLAG_KICK, ADMFLAG_BAN, ADMFLAG_UNBAN, ADMFLAG_SLAY, ADMFLAG_CHANGEMAP, ADMFLAG_CONVARS, ADMFLAG_CONFIG, ADMFLAG_CHAT, ADMFLAG_VOTE, ADMFLAG_PASSWORD, ADMFLAG_RCON, ADMFLAG_CHEATS, ADMFLAG_CUSTOM1, ADMFLAG_CUSTOM2, ADMFLAG_CUSTOM3, ADMFLAG_CUSTOM4, ADMFLAG_CUSTOM5, ADMFLAG_CUSTOM6, ADMFLAG_ROOT};

new Handle:c_Control				= INVALID_HANDLE;




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
	c_Control	= CreateConVar("unusual_controlmod", 	"0", "0 = no control, 1 = event spawn, 2 = event inventory");	
		
	
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Pre);
	HookEvent("post_inventory_application", EventPlayerInventory, EventHookMode_Post);
	
	RegConsoleCmd("unusual", OpenMenu, "Get unusual effect on your weapons");
	RegAdminCmd("unusual_control", ControlPlayer, ADMFLAG_GENERIC);
	RegAdminCmd("unusual_permissions", reloadPermissions, ADMFLAG_GENERIC);
	
	LoadTranslations("unusual.phrases"); 
	AutoExecConfig(true, "unsual_configs");
	BuildPath(Path_SM, EffectsList, sizeof(EffectsList), "configs/%s", EFFECTSFILE);
	BuildPath(Path_SM, UnusualEffect,sizeof(UnusualEffect),"configs/%s", DATAFILE);
	BuildPath(Path_SM, PermissionsFile,sizeof(PermissionsFile),"configs/%s", PERMISSIONFILE);
}

public OnMapStart() 
{
	if(LoadPermissions())
		LogMessage("Unusual effects permissions loaded !");
	else
		LogMessage("Error while charging permissions !");
}

//--------------------------------------------------------------------------------------
//							Control
//--------------------------------------------------------------------------------------

stock bool:IsValidClient(iClient)
{
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	return IsClientInGame(iClient);
}

public Action:OpenMenu(iClient, Args)
{	
	FirstMenu(iClient);
}

public Action:ControlPlayer(iClient, Args)
{	
	for(new i=1; i<MaxClients; i++)
		if(IsClientInGame(i))
			Updating(i);
	
	if(IsValidClient(iClient))
		PrintToChat(iClient,"All Players have been controlled !");
	else
		LogMessage("All Players have been controlled !");
}

public Action:reloadPermissions(iClient, Args)
{
	if(LoadPermissions())
	{
		if(IsValidClient(iClient))
			PrintToChat(iClient,"Unusual effects permissions reloaded !");
		else
			LogMessage("Unusual effects permissions reloaded !");
	}
	else
	{
		if(IsValidClient(iClient))
			PrintToChat(iClient,"Error while recharging permissions !");
		else
			LogMessage("Error while recharging permissions !");
	}
}

bool:LoadPermissions()
{
	new Handle: kv;
	kv = CreateKeyValues("Unusual_permissions");
	if(!FileToKeyValues(kv, PermissionsFile))
	{
		LogError("Can't open %s file",PERMISSIONFILE);
		CloseHandle(kv);
		return false;
	}

	KvGotoFirstSubKey(kv, true);
	Permission[0]  = KvGetNum(kv, "0", 0);
	Permission[1]  = KvGetNum(kv, "a", 0);
	Permission[2]  = KvGetNum(kv, "b", 0);
	Permission[3]  = KvGetNum(kv, "c", 0);
	Permission[4]  = KvGetNum(kv, "d", 0);
	Permission[5]  = KvGetNum(kv, "e", 0);
	Permission[6]  = KvGetNum(kv, "f", 0);
	Permission[7]  = KvGetNum(kv, "g", 0);
	Permission[8]  = KvGetNum(kv, "h", 0);
	Permission[9]  = KvGetNum(kv, "i", 0);
	Permission[10] = KvGetNum(kv, "j", 0);
	Permission[11] = KvGetNum(kv, "k", 0);
	Permission[12] = KvGetNum(kv, "l", 0);
	Permission[13] = KvGetNum(kv, "m", 0);
	Permission[14] = KvGetNum(kv, "n", 0);
	Permission[15] = KvGetNum(kv, "o", 0);
	Permission[16] = KvGetNum(kv, "p", 0);
	Permission[17] = KvGetNum(kv, "q", 0);
	Permission[18] = KvGetNum(kv, "r", 0);
	Permission[19] = KvGetNum(kv, "s", 0);
	Permission[20] = KvGetNum(kv, "t", 0);
	Permission[21] = KvGetNum(kv, "z", 0);
	CloseHandle(kv);
	return true;
}

bool:isAuthorized(Handle:kv, iClient, bool:Strict)
{
	new Count;
	new Limit = GetLimit(GetUserFlagBits(iClient));
	
	KvRewind(kv);
	if(Limit == -1)
		return true;
		
	if(!KvJumpToKey(kv, ClientSteamID[iClient], false))
	{
		Count = 0;
	}
	else
	{
		if(!KvGotoFirstSubKey(kv, true))
		{
			LogError("Invalid file : %s",DATAFILE);
			return false;
		}
		Count++;
			
		while(KvGotoNextKey(kv, true))
			Count++;

	}
	
	if(Strict && Count < Limit)
		return true;
	else if(!Strict && Count <= Limit)
		return true;
	else
		return false;
}

GetLimit(flags)
{
	new Limit 	= 0;
	new i 		= 0;
	
	if(flags == 0)
		return Limit;
		
	do
	{
		if( (flags & FlagsList[i]) && ((Limit < Permission[i+1]) || (Permission[i+1] == -1)) )
			Limit = Permission[i+1];
		i++;
	}while(Limit != -1 && i<21)
	return Limit;
}

//--------------------------------------------------------------------------------------
//							Update Effects
//--------------------------------------------------------------------------------------


public Action:EventPlayerSpawn(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(GetConVarInt(c_Control) == 1 || !FirstControl[iClient])
	{
		if (IsValidClient(iClient))
			Updating(iClient);
			
		if(!FirstControl[iClient])
			FirstControl[iClient] = true;
	}
	return Plugin_Continue;
}

public Action:EventPlayerInventory(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient)) return Plugin_Continue;
	if (!IsPlayerAlive(iClient)) return Plugin_Continue;
	
	if(GetConVarInt(c_Control) == 2)
		Updating(iClient);
		
	AddEffects(iClient);
	return Plugin_Continue;
}

Updating(iClient)
{
	new Handle: kv;
	kv = CreateKeyValues("Unusual_effects");
	if(!FileToKeyValues(kv, UnusualEffect))
	{
		LogError("Can't open %s file",DATAFILE);
		CloseHandle(kv);
		return;
	}
	
	LogMessage("Controle en cours !!");
		
	if(isAuthorized(kv, iClient, false))
		return;
	
	CPrintToChat(iClient, "%t","Sent6");
	DeleteDatas(kv, iClient);
	
	KvRewind(kv);
	if(!KeyValuesToFile(kv, UnusualEffect))
		LogError("Can't save %s file modifications",DATAFILE);
	CloseHandle(kv);
}

DeleteDatas(Handle:kv, iClient)
{
	new String:PlayerInfo[60];
	
	KvRewind(kv);
	GetClientAuthString(iClient, PlayerInfo, sizeof(PlayerInfo));
	
	if(!KvJumpToKey(kv, PlayerInfo))
	{
		CloseHandle(kv);
		return;
	}
		
	new String:section[7];
	while(KvGotoFirstSubKey(kv, true))
	{
		KvGetSectionName(kv, section, sizeof(section)); 
		KvGoBack(kv);
		KvDeleteKey(kv, section);
	}
	return;
}

AddEffects(iClient)
{
	new Handle: kv;
	new TFClassType:Class = TF2_GetPlayerClass(iClient);
	new String:PlayerInfo[60];	
	new String:strSection[7];
	new String:ItemClass[32];
	new Float:fltEffect;
	new ItemID, WeapID;
	new ItemQuality;
	new Effect;
	new i;
	new Slot, SlotMax;
		
	kv = CreateKeyValues("Unusual_effects");
	if(!FileToKeyValues(kv, UnusualEffect))
	{
		LogError("Can't open %s file",DATAFILE);
		CloseHandle(kv);
		return;
	}
	GetClientAuthString(iClient, PlayerInfo, sizeof(PlayerInfo));
	if(!KvJumpToKey(kv, PlayerInfo, false))
	{
		CloseHandle(kv);
		return;
	}
	
	if(!KvGotoFirstSubKey(kv, true))
	{
			LogMessage("Invalid file : %s",DATAFILE);
			CloseHandle(kv);
			return;
	}
	do
	{
		i 		=  0;
		Slot 	= -1;
		KvGetSectionName(kv, strSection, sizeof(strSection));
		ItemID = StringToInt(strSection);
		if(TF2II_IsItemUsedByClass(ItemID, TFClassType:Class))
		{
			KvGetString(kv, "classname", ItemClass, sizeof(ItemClass), "-1");
			if(StrEqual(ItemClass,"-1"))
			{
				LogMessage("Invalid ClassName for %s weapon %s",PlayerInfo, strSection);
				CloseHandle(kv);
				return;
			}
			ItemQuality = KvGetNum(kv, "quality", -1);
			if(ItemQuality == -1)
			{
				LogMessage("Invalid quality for %s weapon %s",PlayerInfo, strSection);
				CloseHandle(kv);
				return;
			}
			Effect = KvGetNum(kv, "effect", -1);
			if(Effect == -1)
			{
				LogMessage("Invalid effect for %s weapon %s",PlayerInfo, strSection);
				CloseHandle(kv);
				return;
			}
			fltEffect = Effect * 1.0;
			
			
			if(Class == TFClassType:8)
				SlotMax = 4;
			else if(Class == TFClassType:9)
				SlotMax = 5;
			else
				SlotMax = 2;
				
			do
			{
				WeapID = GetEntProp(GetPlayerWeaponSlot(iClient, i), Prop_Send, "m_iItemDefinitionIndex");
				if(WeapID == ItemID)
					Slot = i;
				i++;
			}while(i <= SlotMax && Slot == -1)
			
			if(Slot != -1)
				GiveEffect(iClient, ItemClass, ItemID, ItemQuality, fltEffect, Slot);
		}
		
	}while(KvGotoNextKey(kv, true));
	CloseHandle(kv);
}

GiveEffect(iClient, String:ItemClass[], ItemID, ItemQuality, Float:Effect, Slot)
{
	new flags = OVERRIDE_ATTRIBUTES;
	new Handle:hItem = TF2Items_CreateItem(flags);

	flags |= OVERRIDE_CLASSNAME;
	TF2Items_SetClassname(hItem, ItemClass);
	
	flags |= OVERRIDE_ITEM_DEF;
	TF2Items_SetItemIndex(hItem, ItemID);
	TF2Items_SetLevel(hItem, 100);
	TF2Items_SetNumAttributes(hItem, 1);
	TF2Items_SetAttribute(hItem, 0, 134, Effect);
	TF2Items_SetQuality(hItem, ItemQuality);
	
	flags |= PRESERVE_ATTRIBUTES;
	TF2Items_SetFlags(hItem, flags);	

	TF2_RemoveWeaponSlot(iClient, Slot);

	new entity = TF2Items_GiveNamedItem(iClient, hItem);
	CloseHandle(hItem);
	
	if (IsValidEntity(entity))
		EquipPlayerWeapon(iClient, entity);
		
	return;
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if (hItem == INVALID_HANDLE)
		return Plugin_Continue;
		
	CreateTimer(0.1, TimerEffect, client);
	return Plugin_Changed;
}

public Action:TimerEffect(Handle:timer, any:client)
{
	AddEffects(client);
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
		AddMenuItem(Menu1, "2", "Show effects");
		
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
				QualityMenu(iClient);
			else
				CPrintToChat(iClient, "%t","Sent2");
		else if(args == 1)
			DeleteWeapPanel(iClient);
		else if(args == 2)
		{
			FirstMenu(iClient);
			ShowMOTDPanel(iClient, "Unusual effects", WEBSITE, MOTDPANEL_TYPE_URL );
		}
	}
}

//--------------------------------------------------------------------------------------
//							Remove Effect
//--------------------------------------------------------------------------------------

DeleteWeapPanel(iClient)
{
	new Handle: kv;
	kv = CreateKeyValues("Unusual_effects");
	new String:section[7];
	new String:ItemsName[64];
	new Handle:YourItemsMenu = CreateMenu(YourItemsMenuAnswer);
		
	SetMenuTitle(YourItemsMenu, "What items ?");
	FileToKeyValues(kv, UnusualEffect);
		
	if(!KvJumpToKey(kv, ClientSteamID[iClient], false))
	{
		CPrintToChat(iClient, "%t","Sent3");
		CloseHandle(kv);
		return;
	}
		
	if(!KvGotoFirstSubKey(kv, true))
	{
		LogError("Invalid file : %s",DATAFILE);
		CloseHandle(kv);
		return;
	}
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
	CloseHandle(kv);
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
		new Handle: kv;
		kv = CreateKeyValues("Unusual_effects");
		
		if(!FileToKeyValues(kv, UnusualEffect))
		{
			LogError("Can't open %s",DATAFILE);
			CloseHandle(kv);
			return;
		}
		
		KvJumpToKey(kv, ClientSteamID[iClient], true);
		GetMenuItem(menu, args, WeapID, sizeof(WeapID));
			
		if(KvDeleteKey(kv, WeapID))
		{
			KvRewind(kv);
			if(!KeyValuesToFile(kv, UnusualEffect))
				LogError("Can't save %s modifications",DATAFILE);
			CloseHandle(kv);
			CPrintToChat(iClient, "%t", "Sent4");
			AddEffects(iClient);
			DeleteWeapPanel(iClient);
		}
		else
		{
			CPrintToChat(iClient, "%t","Sent5");
			CloseHandle(kv);
		}
	}	
}

//--------------------------------------------------------------------------------------
//							Quality + Effect
//--------------------------------------------------------------------------------------

QualityMenu(iClient)
{
	new Handle: kv;
	kv = CreateKeyValues("Unusual_effects");
	if(!FileToKeyValues(kv, UnusualEffect))
	{
		LogError("Can't open %s file",DATAFILE);
		CloseHandle(kv);
		return;
	}
	if(!isAuthorized(kv, iClient, true))
	{
		CPrintToChat(iClient, "%t", "Sent7");
		return;
	}
	CloseHandle(kv);
	EntitiesID[iClient]		= GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
	if(EntitiesID[iClient] < 0)
		return;
	ClientItems[iClient]	= GetEntProp(EntitiesID[iClient], Prop_Send, "m_iItemDefinitionIndex");
	GetEdictClassname(EntitiesID[iClient], ClassName[iClient], 64);
	
	decl String:Title[64];
	decl String:WeapName[64];
	new Handle:Qltymenu = CreateMenu(QltymenuAnswer);
	
	TF2II_GetItemName(ClientItems[iClient], WeapName, sizeof(WeapName)); 
	Format(Title, sizeof(Title), "Select effect: %s",WeapName);
	SetMenuTitle(Qltymenu, Title);
	
	AddMenuItem(Qltymenu, "0", "Normal");
	AddMenuItem(Qltymenu, "3", "Vintage");
	AddMenuItem(Qltymenu, "6", "Unique");
	AddMenuItem(Qltymenu, "7", "Community");
	AddMenuItem(Qltymenu, "9", "Selfmade");
	AddMenuItem(Qltymenu, "11", "Strange");
	AddMenuItem(Qltymenu, "13", "Haunted");
	
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
	new String:EffectID[8];
	new String:EffectName[128];
	new String:Line[255];
	new Len = 0, NameLen = 0, IDLen = 0;
	new i,j,data,count = 0;

	new Handle:UnusualMenu = CreateMenu(UnusualMenuAnswer);
	SetMenuTitle(UnusualMenu, "Select Unusual effect :");
	AddMenuItem(UnusualMenu, "0", "Show effects");
	
	new Handle:file = OpenFile(EffectsList, "rt");
	if (file == INVALID_HANDLE)
	{
		LogError("[UNUSUAL] Could not open file %s", EFFECTSFILE);
		CloseHandle(file);
		return;
	}

	while (!IsEndOfFile(file))
	{
		count++;
		ReadFileLine(file, Line, sizeof(Line));
		Len = strlen(Line);
		data = 0;
		TrimString(Line);
		if(Line[0] == '"')
		{
			for (i=0; i<Len; i++)
			{
				if (Line[i] == '"')
				{
					i++;
					data++;
					j = i;
					while(Line[j] != '"' && j < Len)
					{
						if(data == 1)
						{
							EffectName[j-i] = Line[j];
							NameLen = j-i;
						}
						else
						{
							EffectID[j-i] = Line[j];
							IDLen = j-i;
						}
						j++;
					}
					i = j;
				}	
			} 
		}
		if(data != 0 && j <= Len)
			AddMenuItem(UnusualMenu, EffectID, EffectName);
		else if(Line[0] != '*' && Line[0] != '/')
			LogError("[UNUSUAL] %s can't read line : %i ",EFFECTSFILE, count);
			
		for(i = 0; i <= NameLen; i++)
			EffectName[i] = '\0';
		for(i = 0; i <= IDLen; i++)
			EffectID[i] = '\0';
	}
	CloseHandle(file);

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
		if(args == 0)
		{
			PanelEffect(iClient);
			ShowMOTDPanel(iClient, "Unusual effects", WEBSITE, MOTDPANEL_TYPE_URL );
		}
		
		new String:Effect[3];
		new String:strName[5];
		new String:strQuality[3];
		new Handle: kv;
		
		GetMenuItem(menu, args, Effect, sizeof(Effect));
		kv = CreateKeyValues("Unusual_effects");
		if(!FileToKeyValues(kv, UnusualEffect))
		{
			LogError("Can't open %s file",DATAFILE);
			CloseHandle(kv);
			return;
		}
		KvJumpToKey(kv, ClientSteamID[iClient], true);
		
		Format(strName, sizeof(strName), "%d",ClientItems[iClient]);
		
		KvJumpToKey(kv, strName, true);
		Format(strQuality, sizeof(strQuality), "%d",Quality[iClient]);
		KvSetString(kv, "classname", ClassName[iClient]);
		KvSetString(kv, "quality", strQuality); 
		KvSetString(kv, "effect", Effect);
		KvRewind(kv);
		if(!KeyValuesToFile(kv, UnusualEffect))
			LogError("Can't save %s file modifications",DATAFILE);
		CloseHandle(kv);

		CPrintToChat(iClient, "%t", "Sent8");
		AddEffects(iClient);
		FirstMenu(iClient); 
	}	
}


