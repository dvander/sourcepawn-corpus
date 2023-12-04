#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define MAX_CATEGORIES 12
#define MAX_ITEMS_PER_CATEGORY 48
#define MAX_ITEM_NAME_LENGTH 32
#define MAX_CATEGORY_NAME_LENGTH 16

#define CONFIG "data/l4d2_give_random.cfg"

public Plugin myinfo =
{
	name = "[L4D2] Give Random Items",
	author = "BHaType",
	version = "1.0"
}

enum struct Category
{
	char name[MAX_CATEGORY_NAME_LENGTH];
	ArrayList items;
	bool init;

	void Init(const char[] name)
	{
		if (this.init)
			return;
	
		strcopy(this.name, sizeof Category::name, name);
		this.items = new ArrayList(ByteCountToCells(MAX_ITEM_NAME_LENGTH));
		this.init = true;
	}

	void Reset()
	{
		if (!this.init)
			return;

		this.init = false;
		delete this.items; 
	}
}

Category g_Categories[MAX_CATEGORIES];
Category g_CategoryDefault;
ArrayList g_hShortcuts;
int g_iCategoriesCount, g_iSectionLevel;
bool g_bDefault;

public void OnPluginStart()
{
	g_hShortcuts = new ArrayList(ByteCountToCells(MAX_ITEM_NAME_LENGTH));

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof path, "%s", CONFIG);

	if (!ParseConfig(path))
		SetFailState("Failed to parse config %s", CONFIG);

	RegAdminCmd("sm_randomitem_dump", sm_randomitem_dump, ADMFLAG_ROOT);
	RegAdminCmd("sm_randomitem_reload", sm_randomitem_reload, ADMFLAG_ROOT);
	RegAdminCmd("sm_randomitem", sm_randomitem, ADMFLAG_CHEATS);
}

public Action sm_randomitem_dump(int client, int args)
{
	char name[MAX_ITEM_NAME_LENGTH];
	ArrayList items;
	int size;

	if (g_iCategoriesCount > 0)
	{
		ReplyToCommand(client, "Dumping %i categories", g_iCategoriesCount);
		for(int i; i < g_iCategoriesCount; i++)
		{
			items = g_Categories[i].items;
			size = items.Length;

			ReplyToCommand(client, "%s category has %i items:", g_Categories[i].name, size);
			for(int j; j < size; j++)
			{
				items.GetString(j, name, sizeof name);
				ReplyToCommand(client, "%i. %s", j + 1, name);
			}
		}
	}

	items = g_CategoryDefault.items;
	size = items.Length;

	ReplyToCommand(client, "Dumping default category");
	ReplyToCommand(client, "Default category has %i items:", size);
	for(int j; j < size; j++)
	{
		items.GetString(j, name, sizeof name);
		ReplyToCommand(client, "%i. %s", j + 1, name);
	}

	return Plugin_Handled;
}

public Action sm_randomitem_reload(int client, int args)
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof path, "%s", CONFIG);
	ParseConfig(path);
	return Plugin_Handled;
}

public Action sm_randomitem(int client, int args)
{
	if ( args <= 1 )
	{
		ReplyToCommand(client, "Usage: sm_randomitem <#userid|name> <item:category>");
		return Plugin_Handled;
	}

	char arg1[32], item[MAX_ITEM_NAME_LENGTH], target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	GetCmdArg(1, arg1, sizeof arg1);
	GetCmdArg(2, item, sizeof item);

	if( (target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int target;
	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];
		
		if (!GiveClientItem(target, item))
		{
			ReplyToCommand(client, "Failed to give item %s", item);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Handled;
}

bool GiveClientItem(int client, const char[] item)
{
	char szItem[MAX_ITEM_NAME_LENGTH];
	int category = -1;
	bool pass;

	for(int i; i < g_iCategoriesCount; i++)
	{
		if (strcmp(g_Categories[i].name, item) == 0)
		{
			category = i;
			break;
		}
	}

	if (category != -1)
	{
		ArrayList items = g_Categories[category].items;

		if (items.Length == 0)
		{
			LogError("%s category has no items", g_Categories[category].name);
			return false;
		}

		items.GetString(GetRandomInt(0, items.Length - 1), szItem, MAX_ITEM_NAME_LENGTH);
		pass = true;
	}
	else
	{
		char szShortcut[MAX_ITEM_NAME_LENGTH];
		int size = g_CategoryDefault.items.Length;

		for(int i; i < size; i++)
		{
			g_CategoryDefault.items.GetString(i, szItem, sizeof szItem);
			g_hShortcuts.GetString(i, szShortcut, sizeof szShortcut);

			if( strcmp(szItem, item) == 0 || strcmp(szShortcut, item) == 0 )
			{
				pass = true;
				break;
			}
		}
	}

	if (!pass)
		return false;
	
	pass = GivePlayerItem(client, szItem) != -1;

	if (!pass)
	{
		int melee = SpawnMeleeWeapon(szItem);

		if (melee != -1)
		{
			EquipPlayerWeapon(client, melee);
			pass = true;
		}
	}

	if (!pass)
	{
		LogError("Failed to give %s to %N", szItem, client);
	}

	return pass;
}

int SpawnMeleeWeapon( const char[] name )
{	
	static const char szMeleeNames[][] =
	{
		"baseball_bat",
		"cricket_bat",
		"crowbar",
		"electric_guitar",
		"fireaxe",
		"frying_pan",
		"golfclub",
		"katana",
		"machete",
		"tonfa",
		"knife",
		"shovel",
		"pitchfork"
	};
	
	int index = -1;
	
	for (int i; i < sizeof szMeleeNames; i++)
	{
		if ( StrContains(name, szMeleeNames[i]) != -1 )
		{
			index = i;
			break;
		}
	}
	
	if ( index == -1 )
	{
		return false;
	}
	
	int weapon = CreateEntityByName("weapon_melee");
	DispatchKeyValue(weapon, "melee_script_name", szMeleeNames[index]);
	DispatchSpawn(weapon);
	
	char szModel[PLATFORM_MAX_PATH];
	GetEntPropString(weapon, Prop_Data, "m_ModelName", szModel, sizeof szModel); 
	
	if ( StrContains( szModel, "hunter", false ) != -1 )
	{
		AcceptEntityInput(weapon, "kill");
		weapon = -1;
	}	

	return weapon;
}

void ResetCategories()
{
	for(int i; i < g_iCategoriesCount; i++)
	{
		g_Categories[i].Reset();
	}

	g_CategoryDefault.Reset();
	g_iCategoriesCount = 0;
}

bool ParseConfig( const char[] path )
{
	if ( !FileExists(path) )
	{
		LogError("Failed to load config... File doesn't exist");
		return false;
	}
		
	ResetCategories();
	
	SMCParser parser = new SMCParser();
	char error[128]; 
	int line = 0, col = 0;
		
	parser.OnEnterSection = Config_NewSection;
	parser.OnLeaveSection = Config_EndSection;
	parser.OnKeyValue = Config_KeyValue;
		
	SMCError result = SMC_ParseFile(parser, path, line, col);
	delete parser;
		
	if ( result != SMCError_Okay )
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, path);
		return false;
	}
		
	return ( result == SMCError_Okay );
}

public SMCResult Config_NewSection( Handle parser, const char[] section, bool quotes )
{
	g_iSectionLevel++;
	
	if (g_iSectionLevel == 1)
		return SMCParse_Continue;

	if (g_iCategoriesCount == MAX_CATEGORIES)
	{
		LogError("Too many categories, increase MAX_CATEGORIES...");
		return SMCParse_Halt;
	}

	if (strcmp(section, "default") == 0)
	{
		g_bDefault = true;
		g_CategoryDefault.Init(section);
	}
	else
	{
		int i = g_iCategoriesCount;
		g_Categories[i].Init(section);
	}

	return SMCParse_Continue;
}

public SMCResult Config_KeyValue( Handle parser, char[] key, char[] value, bool key_quotes, bool value_quotes )
{
	ArrayList items;

	if (!g_bDefault)
	{
		int i = g_iCategoriesCount;
		items = g_Categories[i].items;
	}
	else
	{
		items = g_CategoryDefault.items;
		g_hShortcuts.PushString(key);
	}

	items.PushString(value);
	return SMCParse_Continue;
}

public SMCResult Config_EndSection( Handle parser )
{
	if (g_iSectionLevel-- == 1)
		return SMCParse_Continue;

	if (g_bDefault)
	{
		g_bDefault = false;
		return SMCParse_Continue;
	}

	g_iCategoriesCount++;
	return SMCParse_Continue;
}