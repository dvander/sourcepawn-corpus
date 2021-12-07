#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_NAME "[TF2] Strange Sawblades and Strange Trains"
#define PLUGIN_VERSION "1.0.0a"
#define PLUGIN_AUTHOR "Theray070696"
#define PLUGIN_DESCRIPTION "Counts kills from saw blades and trains."
#define PLUGIN_URL ""

public Plugin:myinfo = {
	name 			= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESCRIPTION,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_URL
};

enum StrangeRanks
{
	RANK_0,
	RANK_1,
	RANK_2,
	RANK_3,
	RANK_4,
	RANK_5,
	RANK_6,
	RANK_7,
	RANK_8,
	RANK_9,
	RANK_10,
	RANK_11,
	RANK_12,
	RANK_13,
	RANK_14,
	RANK_15,
	RANK_16,
	RANK_17,
	RANK_18,
	RANK_19,
	RANK_20
};

stock const String:StrangeRankNames[StrangeRanks][] = 
{
	"Strange",
	"Unremarkable",
	"Scarcely Lethal",
	"Mildly Menacing",
	"Somewhat Threatening",
	"Uncharitable",
	"Notably Dangerous",
	"Sufficiently Lethal",
	"Truly Feared",
	"Spectacularly Lethal",
	"Gore-Spattered",
	"Wicked Nasty",
	"Positively Inhumane",
	"Totally Ordinary",
	"Face-Melting",
	"Rage-Inducing",
	"Server-Clearing",
	"Epic",
	"Legendary",
	"Australian",
	"Hale's Own"
};

enum TrainSaw
{
	SAWBLADE,
	TRAIN
};

new sawKills = 0;
new StrangeRanks:sawRank = RANK_0;

new trainKills = 0;
new StrangeRanks:trainRank = RANK_0;

new bool:shouldSave = true;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:gameFolder[8];
	GetGameFolderName(gameFolder, sizeof(gameFolder));

	if(StrContains(gameFolder, "tf") < 0)
	{
		strcopy(error, err_max, "This plugin can only run on Team Fortress 2.");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_strange_train_saw_version", PLUGIN_VERSION, "Don't touch this!", FCVAR_NOTIFY);
	
	HookEvent("player_death", Event_Death);
	HookEvent("teamplay_round_win", Event_Round_End);
	
	LoadFromFile();
	CheckRank(TRAIN);
	CheckRank(SAWBLADE);
}

public OnPluginEnd()
{
	SaveToFile();
}

public OnMapStart()
{
	LoadFromFile();
	CheckRank(TRAIN);
	CheckRank(SAWBLADE);
}

public OnMapEnd()
{
	SaveToFile();
}

// EVENTS

public Event_Round_End(Handle:event, const String:strName[], bool:bDontBroadcast)
{
	if(shouldSave)
	{
		SaveToFile();
		shouldSave = false;
	} else
	{
		shouldSave = true;
	}
}

public Event_Death(Handle:event, const String:strName[], bool:bDontBroadcast)
{
	new damageBits = GetEventInt(event, "damagebits");
	
	if(damageBits == 65536) // Saw blades
	{
		sawKills++;
		new StrangeRanks:oldRank = sawRank;
		CheckRank(SAWBLADE);
		if(oldRank != sawRank)
		{
			PrintRankUp(SAWBLADE, oldRank);
		}
		PrintStrangeCount(SAWBLADE);
	} else if(damageBits == 16) // Train
	{
		trainKills++;
  		new StrangeRanks:oldRank = trainRank;
		CheckRank(TRAIN);
		if(oldRank != trainRank)
		{
			PrintRankUp(TRAIN, oldRank);
		}
		PrintStrangeCount(TRAIN);
	}
}

// STOCKS

stock CheckRank(TrainSaw:thing)
{
	if(thing == SAWBLADE)
	{
		if(sawKills >= 0 && sawKills < 10)
		{
			sawRank = RANK_0;
		} else if(sawKills >= 10 && sawKills < 25)
		{
			sawRank = RANK_1;
		} else if(sawKills >= 25 && sawKills < 45)
		{
			sawRank = RANK_2;
		} else if(sawKills >= 45 && sawKills < 70)
		{
			sawRank = RANK_3;
		} else if(sawKills >= 70 && sawKills < 100)
		{
			sawRank = RANK_4;
		} else if(sawKills >= 100 && sawKills < 135)
		{
			sawRank = RANK_5;
		} else if(sawKills >= 135 && sawKills < 175)
		{
			sawRank = RANK_6;
		} else if(sawKills >= 175 && sawKills < 225)
		{
			sawRank = RANK_7;
		} else if(sawKills >= 225 && sawKills < 275)
		{
			sawRank = RANK_8;
		} else if(sawKills >= 275 && sawKills < 350)
		{
			sawRank = RANK_9;
		} else if(sawKills >= 350 && sawKills < 500)
		{
			sawRank = RANK_10;
		} else if(sawKills >= 500 && sawKills < 750)
		{
			sawRank = RANK_11;
		} else if(sawKills >= 750 && sawKills < 999)
		{
			sawRank = RANK_12;
		} else if(sawKills == 999)
		{
			sawRank = RANK_13;
		} else if(sawKills >= 1000 && sawKills < 1500)
		{
			sawRank = RANK_14;
		} else if(sawKills >= 1500 && sawKills < 2500)
		{
			sawRank = RANK_15;
		} else if(sawKills >= 2500 && sawKills < 5000)
		{
			sawRank = RANK_16;
		} else if(sawKills >= 5000 && sawKills < 7500)
		{
			sawRank = RANK_17;
		} else if(sawKills >= 7500 && sawKills < 7616)
		{
			sawRank = RANK_18;
		} else if(sawKills >= 7616 && sawKills < 8500)
		{
			sawRank = RANK_19;
		} else if(sawKills >= 8500)
		{
			sawRank = RANK_20;
		}
	} else if(thing == TRAIN)
	{
		if(trainKills >= 0 && trainKills < 10)
		{
			trainRank = RANK_0;
		} else if(trainKills >= 10 && trainKills < 25)
		{
			trainRank = RANK_1;
		} else if(trainKills >= 25 && trainKills < 45)
		{
			trainRank = RANK_2;
		} else if(trainKills >= 45 && trainKills < 70)
		{
			trainRank = RANK_3;
		} else if(trainKills >= 70 && trainKills < 100)
		{
			trainRank = RANK_4;
		} else if(trainKills >= 100 && trainKills < 135)
		{
			trainRank = RANK_5;
		} else if(trainKills >= 135 && trainKills < 175)
		{
			trainRank = RANK_6;
		} else if(trainKills >= 175 && trainKills < 225)
		{
			trainRank = RANK_7;
		} else if(trainKills >= 225 && trainKills < 275)
		{
			trainRank = RANK_8;
		} else if(trainKills >= 275 && trainKills < 350)
		{
			trainRank = RANK_9;
		} else if(trainKills >= 350 && trainKills < 500)
		{
			trainRank = RANK_10;
		} else if(trainKills >= 500 && trainKills < 750)
		{
			trainRank = RANK_11;
		} else if(trainKills >= 750 && trainKills < 999)
		{
			trainRank = RANK_12;
		} else if(trainKills == 999)
		{
			trainRank = RANK_13;
		} else if(trainKills >= 1000 && trainKills < 1500)
		{
			trainRank = RANK_14;
		} else if(trainKills >= 1500 && trainKills < 2500)
		{
			trainRank = RANK_15;
		} else if(trainKills >= 2500 && trainKills < 5000)
		{
			trainRank = RANK_16;
		} else if(trainKills >= 5000 && trainKills < 7500)
		{
			trainRank = RANK_17;
		} else if(trainKills >= 7500 && trainKills < 7616)
		{
			trainRank = RANK_18;
		} else if(trainKills >= 7616 && trainKills < 8500)
		{
			trainRank = RANK_19;
		} else if(trainKills >= 8500)
		{
			trainRank = RANK_20;
		}
	}
}

stock PrintRankUp(TrainSaw:thing, StrangeRanks:oldRank)
{
	if(thing == SAWBLADE)
	{
		PrintToChatAll("\x07CF6A32%s Sawblade\x01 has ranked up to \x07CF6A32%s\x01!", StrangeRankNames[oldRank], StrangeRankNames[sawRank]);
	} else if(thing == TRAIN)
	{
		PrintToChatAll("\x07CF6A32%s Train\x01 has ranked up to \x07CF6A32%s\x01!", StrangeRankNames[oldRank], StrangeRankNames[trainRank]);
	}
}

stock PrintStrangeCount(TrainSaw:thing)
{
	if(thing == SAWBLADE)
	{
		if(sawKills == 1)
		{
			PrintToChatAll("\x07CF6A32%s Sawblade\x01: %d kill", StrangeRankNames[sawRank], sawKills);
		} else
		{
			PrintToChatAll("\x07CF6A32%s Sawblade\x01: %d kills", StrangeRankNames[sawRank], sawKills);
		}
	} else if(thing == TRAIN)
	{
		if(trainKills == 1)
		{
			PrintToChatAll("\x07CF6A32%s Train\x01: %d kill", StrangeRankNames[trainRank], trainKills);
		} else
		{
			PrintToChatAll("\x07CF6A32%s Train\x01: %d kills", StrangeRankNames[trainRank], trainKills);
		}
	}
}

stock LoadFromFile()
{
	new String:Root[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Root, sizeof(Root), "configs");
	new Handle:file = CreateKeyValues("Strange Train and Saw");
	new String:FileName[PLATFORM_MAX_PATH];
	
	Format(FileName, sizeof(FileName), "%s/strange_train_saw.txt", Root);
	
	if(FileToKeyValues(file, FileName))
	{
		KvJumpToKey(file, "sawbladeKills");
		sawKills = KvGetNum(file, "count");
		KvRewind(file);
		KvJumpToKey(file, "trainKills");
		trainKills = KvGetNum(file, "count");
		KvRewind(file);
		CloseHandle(file);
	}
}

stock SaveToFile()
{
	if(sawKills < 1 && trainKills < 1) return; // Don't bother saving when there is nothing that needs saving
	
	new String:Root[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Root, sizeof(Root), "configs");
	new String:FileName[PLATFORM_MAX_PATH];
	
	Format(FileName, sizeof(FileName), "%s/strange_train_saw.txt", Root);
	
	new Handle:kv = CreateKeyValues("Strange Train and Saw");
	
	KvJumpToKey(kv, "sawbladeKills", true);
	KvSetNum(kv, "count", sawKills);
	KvRewind(kv);
	
	KvJumpToKey(kv, "trainKills", true);
	KvSetNum(kv, "count", trainKills);
	KvRewind(kv);
	
	KeyValuesToFile(kv, FileName);
	CloseHandle(kv);
}
