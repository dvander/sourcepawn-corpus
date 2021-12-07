#pragma semicolon 1
//#pragma dynamic 100000

#include <sourcemod>
#include <sdktools>
#include <store>
#include <EasyJSON>
//#include <smartdm>
#include <tf2_stocks>

enum Skin
{
	String:SkinName[STORE_MAX_NAME_LENGTH],
	String:SkinModelPath[PLATFORM_MAX_PATH],
	SkinTeams[5],
	TFClassType:SkinClass
}

new myFilesCount = 23; // 1 less than comments below
new String:myFiles[][] =
{
	"models/player/pb/femsniper/", //1
	"models/player/female_scout/",  //2

	"models/jailbreak/medic/", // 3
	"models/jailbreak/demo/", // 4
	"models/jailbreak/spy/", // 5
	"models/jailbreak/scout/", // 6
	"models/jailbreak/sniper/", // 7
	"models/jailbreak/soldier/", // 8
	"models/jailbreak/engie/", // 9
	"models/jailbreak/heavy/", // 10
	"models/jailbreak/pyro/", // 11

	"materials/models/jailbreak/medic/", // 12
	"materials/models/jailbreak/demo/", // 13
	"materials/models/jailbreak/spy/", // 14
	"materials/models/jailbreak/scout/", // 15
	"materials/models/jailbreak/sniper/", // 16
	"materials/models/jailbreak/soldier/", // 17
	"materials/models/jailbreak/engie/", // 18
	"materials/models/jailbreak/heavy/", // 19
	"materials/models/jailbreak/pyro/", // 20

	"models/custom/player/miku/", // 21
	"materials/models/player/female_scout/", // 22
	"materials/models/maxxy/female_sniper/", // 23

	"materials/models/custom/player/hatsunemiku/" //24
};
/*
LogDownloads(String:LogThis[])
{
		new String:szFile[256];
		BuildPath(Path_SM, szFile, sizeof(szFile), "logs/skins_download.log");
		LogToFile(szFile, LogThis);
}*/

new g_skins[1024][Skin];
new g_skinCount = 0;

new Handle:g_skinNameIndex;

new String:g_game[32];

public Plugin:myinfo =
{
    name        = "[Store] Skins",
    author      = "alongub",
    description = "Skins component for [Store]",
    version     = STORE_VERSION,
    url         = "https://github.com/alongubkin/store"
};

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
	LoadTranslations("store.phrases");

	HookEvent("player_spawn", Event_PlayerSpawn);
	Store_RegisterItemType("skin", OnEquip, LoadItem);
	GetGameFolderName(g_game, sizeof(g_game));
}

/**
 * Map is starting
 */
public OnMapStart()
{
	Download_Files();

	/*
	for (new skin = 0; skin < g_skinCount; skin++)
	{
		if (strcmp(g_skins[skin][SkinModelPath], "") != 0 && (FileExists(g_skins[skin][SkinModelPath]) || FileExists(g_skins[skin][SkinModelPath], true)))
		{
			PrecacheModel(g_skins[skin][SkinModelPath]);
			Downloader_AddFileToDownloadsTable(g_skins[skin][SkinModelPath]);
		}
	}*/
}

Download_Files()
{
	for(new x=0;x<myFilesCount;x++)
	{
		Directory_AddFileToDownloadsTable(myFiles[x]);
	}
}


Directory_AddFileToDownloadsTable(String:custom_path[])
{
	//decl String:path2[PLATFORM_MAX_PATH];

	new String:path[1024];
	new FileType:type;

	new Handle:dir = OpenDirectory(custom_path);
	if (dir == INVALID_HANDLE)
	{
		return;
	}
	new String:ThePath[1024];

	while (ReadDirEntry(dir, path, sizeof(path), type))
	{
		if (type == FileType_File)
		{
			Format(ThePath, sizeof(ThePath), "%s%s",custom_path,path);

			if(StrContains(path,".mdl") != -1)
			{
				//LogDownloads("PrecacheModel:");
				PrecacheModel(ThePath,true);
			}

			AddFileToDownloadsTable(ThePath);
			//PrintToServer("[STORE-SKINS] Downloads table: %s",ThePath);
			//LogDownloads(ThePath);
		}
	}

	CloseHandle(dir);
}


/**
 * Called when a new API library is loaded.
 */
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "store-inventory"))
	{
		Store_RegisterItemType("skin", OnEquip, LoadItem);
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsClientInGame(client))
		return Plugin_Continue;

	if (IsFakeClient(client))
		return Plugin_Continue;

	CreateTimer(1.0, Timer_Spawn, GetClientSerial(client));

	return Plugin_Continue;
}

public Action:Timer_Spawn(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);

	if (client == 0)
		return Plugin_Continue;

	Store_GetEquippedItemsByType(GetSteamAccountID(client), "skin", Store_GetClientLoadout(client), OnGetPlayerSkin, serial);

	return Plugin_Continue;
}

public Store_OnClientLoadoutChanged(client)
{
	Store_GetEquippedItemsByType(GetSteamAccountID(client), "skin", Store_GetClientLoadout(client), OnGetPlayerSkin, GetClientSerial(client));
}

public OnGetPlayerSkin(ids[], count, any:serial)
{
	new client = GetClientFromSerial(serial);

	if (client == 0)
		return;

	if (!IsClientInGame(client))
		return;

	if (!IsPlayerAlive(client))
		return;

	new team = GetClientTeam(client);
	for (new index = 0; index < count; index++)
	{
		decl String:itemName[STORE_MAX_NAME_LENGTH];
		Store_GetItemName(ids[index], itemName, sizeof(itemName));

		//PrintToChatAll("ids %s",itemName);

		new skin = -1;
		if (!GetTrieValue(g_skinNameIndex, itemName, skin))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			continue;
		}

		new bool:teamAllowed = false;
		for (new teamIndex = 0; teamIndex < 5; teamIndex++)
		{
			if (g_skins[skin][SkinTeams][teamIndex] == team)
			{
				teamAllowed = true;
				break;
			}
		}

		new TFClassType:tPlayerClass=TFClassType:g_skins[skin][SkinClass];

		if(tPlayerClass!=TFClass_Unknown)
		{
			new TFClassType:tTMP_PlayerClass=TF2_GetPlayerClass(client);
			if(tTMP_PlayerClass!=tPlayerClass)
			{
				PrintToChat(client,"You can not wear this item with this class.");
				continue;
			}
		}

		if (!teamAllowed)
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "You can't wear this item");
			continue;
		}

		if (StrEqual(g_game, "tf"))
		{
			SetVariantString(g_skins[skin][SkinModelPath]);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		}
		else
		{
			SetEntityModel(client, g_skins[skin][SkinModelPath]);
		}
	}
}

public Store_OnReloadItems()
{
	if (g_skinNameIndex != INVALID_HANDLE)
		CloseHandle(g_skinNameIndex);

	g_skinNameIndex = CreateTrie();
	g_skinCount = 0;
}

public LoadItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_skins[g_skinCount][SkinName], STORE_MAX_NAME_LENGTH, itemName);

	SetTrieValue(g_skinNameIndex, g_skins[g_skinCount][SkinName], g_skinCount);

	new Handle:json = DecodeJSON(attrs);
	JSONGetString(json, "model", g_skins[g_skinCount][SkinModelPath], PLATFORM_MAX_PATH);

/*
	if (strcmp(g_skins[g_skinCount][SkinModelPath], "") != 0 &&
		(FileExists(g_skins[g_skinCount][SkinModelPath]) || FileExists(g_skins[g_skinCount][SkinModelPath], true)))
	{
		PrintToChatAll("File Exists %s",g_skins[g_skinCount][SkinModelPath]);
		PrecacheModel(g_skins[g_skinCount][SkinModelPath]);
		Downloader_AddFileToDownloadsTable(g_skins[g_skinCount][SkinModelPath]);
	}
	else
	{
		PrintToChatAll("File NOT Exists %s",g_skins[g_skinCount][SkinModelPath]);
	}*/

	new Handle:teams = INVALID_HANDLE;
	if (JSONGetArray(json, "teams", teams) && teams != INVALID_HANDLE)
	{
		for (new i = 0; i < GetArraySize(teams); i++)
		{
			if (!JSONGetArrayInteger(teams, i, g_skins[g_skinCount][SkinTeams][i]))
			{
				g_skins[g_skinCount][SkinTeams][i] = 0;
			}
			//PrintToChatAll("SkinTeams %d",g_skins[g_skinCount][SkinTeams][i]);
		}
	}

/*
enum TFClassType
{
	TFClass_Unknown = 0,
	TFClass_Scout,
	TFClass_Sniper,
	TFClass_Soldier,
	TFClass_DemoMan,
	TFClass_Medic,
	TFClass_Heavy,
	TFClass_Pyro,
	TFClass_Spy,
	TFClass_Engineer
};*/
	decl String:sTmpClassStrings[16];

	JSONGetString(json, "class", sTmpClassStrings, sizeof(sTmpClassStrings));

	//if(JSONGetString(json, "class", sTmpClassStrings, sizeof(sTmpClassStrings)))
	//{
		//PrintToChatAll("Found Class!");
	//}

	//PrintToChatAll("Loading class %s | %s", g_skins[g_skinCount][SkinModelPath], sTmpClassStrings);

	if(StrEqual(sTmpClassStrings,"scout"))
	{
		//PrintToChatAll("scout");
		g_skins[g_skinCount][SkinClass]=TFClass_Scout;
	}
	else if(StrEqual(sTmpClassStrings,"sniper"))
	{
		//PrintToChatAll("sniper");
		g_skins[g_skinCount][SkinClass]=TFClass_Sniper;
	}
	else if(StrEqual(sTmpClassStrings,"soldier"))
	{
		//PrintToChatAll("soldier");
		g_skins[g_skinCount][SkinClass]=TFClass_Soldier;
	}
	else if(StrEqual(sTmpClassStrings,"demo"))
	{
		//PrintToChatAll("demo");
		g_skins[g_skinCount][SkinClass]=TFClass_DemoMan;
	}
	else if(StrEqual(sTmpClassStrings,"medic"))
	{
		//PrintToChatAll("medic");
		g_skins[g_skinCount][SkinClass]=TFClass_Medic;
	}
	else if(StrEqual(sTmpClassStrings,"heavy"))
	{
		//PrintToChatAll("heavy");
		g_skins[g_skinCount][SkinClass]=TFClass_Heavy;
	}
	else if(StrEqual(sTmpClassStrings,"pyro"))
	{
		//PrintToChatAll("scout");
		g_skins[g_skinCount][SkinClass]=TFClass_Pyro;
	}
	else if(StrEqual(sTmpClassStrings,"spy"))
	{
		//PrintToChatAll("spy");
		g_skins[g_skinCount][SkinClass]=TFClass_Spy;
	}
	else if(StrEqual(sTmpClassStrings,"engineer"))
	{
		//PrintToChatAll("engineer");
		g_skins[g_skinCount][SkinClass]=TFClass_Engineer;
	}
	else
	{
		//PrintToChatAll("unknown");
		g_skins[g_skinCount][SkinClass]=TFClass_Unknown;
	}


	// always make this last!
	g_skinCount++;

	DestroyJSON(json);
}

public Store_ItemUseAction:OnEquip(client, itemId, bool:equipped)
{
	if (equipped)
		return Store_UnequipItem;

	PrintToChat(client, "%s%t", STORE_PREFIX, "Equipped item apply next spawn");
	return Store_EquipItem;
}
