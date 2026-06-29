// vim: ts=8 syntax=cpp
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME	"Rename Bots"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_DESC	"Rename bots by TeamNum"
#define PLUGIN_AUTHOR	"JeremiahK (RedDeathOfMe)"
#define PLUGIN_URL	"https://forums.alliedmods.net/member.php?u=347772"
#define CFG_FILE_PATH	"addons/sourcemod/configs/rename_bots.cfg"

#define MAXLEN_PLAYERNAME	32
#define MAXLEN_PLAYERCLASS	64

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

/**************** named indexes for botnames_data int arrays *****************/
enum
{
	BotNames_Data_TeamNum,	// TeamNum for botname list
	BotNames_Data_Head,	// index of team's first botname
	BotNames_Data_Tail,	// index of team's last botname
	BotNames_Data_Next,	// index of team's next botname to be used

	BotNames_Data_Size
}

/***************************** Console Variables *****************************/
ConVar cvar_prefix;		// string: prefix for all bot names
ConVar cvar_suffix;		// string: suffix for all bot names
ConVar cvar_enabled;		// bool: is the plugin enabled?

/******************************* Global Arrays *******************************/
ArrayList botnames_data;	// int arrays: data for each team
ArrayList botnames_list;	// strings: all possible bot names

/******************************* Plugin Hooks ********************************/
public void OnPluginStart()
/***
  *	Create console variables, allocate arrays, hook events, process config.
 ***/
{
	cvar_prefix = CreateConVar(
		"rename_bots_prefix",
		"BOT ",
		"str: prefix for all bot names"
	);
	cvar_suffix = CreateConVar(
		"rename_bots_suffix",
		"",
		"str: suffix for all bot names"
	);
	cvar_enabled = CreateConVar(
		"rename_bots_enabled",
		"1",
		"str: suffix for all bot names",
		0, true, 0.0, true, 1.0
	);

	botnames_data = new ArrayList(ByteCountToCells(BotNames_Data_Size * 4));
	botnames_list = new ArrayList(ByteCountToCells(MAXLEN_PLAYERNAME));

	HookEvent("player_pick_squad", Event_PlayerPickSquad_Post, EventHookMode_Post);

	ProcessConfig();
}

public void OnPluginEnd()
/***
  *	Free arrays.
 ***/
{
	delete botnames_data;
	delete botnames_list;
}

/******************************** Event Hooks ********************************/
public Action Event_PlayerPickSquad_Post(Event event, const char[] event_name, bool dont_broadcast)
/***
  *	When a bot joins a team, rename it.
 ***/
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client < 1 || !IsClientInGame(client) || !IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	RenameBot(client);
	return Plugin_Continue;
}

/***************************** Program Functions *****************************/
void RenameBot(const int client)
/***
  *	Give client random name matching its team, with prefix and suffix.
 ***/
{
	if (!cvar_enabled.BoolValue)
	{
		return;
	}

	int team = GetClientTeam(client);

	char prefix[MAXLEN_PLAYERNAME];
	char name[MAXLEN_PLAYERNAME];
	char suffix[MAXLEN_PLAYERNAME];

	cvar_prefix.GetString(prefix, sizeof(prefix));
	cvar_suffix.GetString(suffix, sizeof(suffix));

	// loop through all teams we have botnames for
	for (int i = 0; i < botnames_data.Length; i++)
	{
		// get this team's botname data
		int data[BotNames_Data_Size];
		botnames_data.GetArray(i, data);

		// if this team matches client's...
		if (data[BotNames_Data_TeamNum] == team)
		{
			// get next available botname from this team
			botnames_list.GetString(data[BotNames_Data_Next], name, sizeof(name));

			// inc index to setup next botname
			data[BotNames_Data_Next]++;

			// if we have used all botnames for this team...
			if (data[BotNames_Data_Next] > data[BotNames_Data_Tail])
			{
				// reset next botname to the first one, reshuffle
				data[BotNames_Data_Next] = data[BotNames_Data_Head];
				ShuffleBotNames();
			}

			// save changes to data array
			botnames_data.SetArray(i, data);
			break;
		}
	}

	char new_name[MAXLEN_PLAYERNAME];
	StrCat(new_name, sizeof(new_name), prefix);
	StrCat(new_name, sizeof(new_name), name);
	StrCat(new_name, sizeof(new_name), suffix);

	SetClientInfo(client, "name", new_name);
}

void ProcessConfig()
/***
  *	Process plugin config file.
  *	Push a new data array to `botname_data` for each team,
  *	and push a new string to `botname_list` for each botname.
 ***/
{
	KeyValues kv = new KeyValues("rename_bots");

	if (!kv.ImportFromFile(CFG_FILE_PATH))
	{
		PrintToServer("ERROR: rename_bots config file not found.");
		delete kv;
		return;
	}

	if (!kv.JumpToKey("TeamNum"))
	{
		PrintToServer("ERROR: `TeamNum` key not found.");
		delete kv;
		return;
	}

	botnames_data.Clear();
	botnames_list.Clear();

	kv.GotoFirstSubKey(false);
	do
	{
		char team[4];
		kv.GetSectionName(team, sizeof(team));

		int data[BotNames_Data_Size];
		data[BotNames_Data_TeamNum] = StringToInt(team);
		data[BotNames_Data_Head] = botnames_list.Length;
		data[BotNames_Data_Next] = botnames_list.Length;

		kv.GotoFirstSubKey(false);
		do
		{
			if (kv.GetDataType(NULL_STRING) != KvData_None)
			{
				char key[16];
				char val[MAXLEN_PLAYERNAME];

				kv.GetSectionName(key, sizeof(key));
				kv.GetString(NULL_STRING, val, sizeof(val));

				if (StrEqual(key, "bot_name"))
				{
					botnames_list.PushString(val);
				}
			}
		} while (kv.GotoNextKey(false));
		kv.GoBack();

		data[BotNames_Data_Tail] = botnames_list.Length - 1;
		botnames_data.PushArray(data);
	} while (kv.GotoNextKey(false));

	ShuffleBotNames();
}

void ShuffleBotNames()
/***
  *	Shuffle each team's list of botnames.
 ***/
{
	for (int i = 0; i < botnames_data.Length; i++)
	{
		int data[BotNames_Data_Size];
		botnames_data.GetArray(i, data);

		for (int j = data[BotNames_Data_Head]; j < data[BotNames_Data_Tail]; j++)
		{
			int swap = GetRandomInt(j, data[BotNames_Data_Tail]);
			botnames_list.SwapAt(j, swap);
		}
	}
}
