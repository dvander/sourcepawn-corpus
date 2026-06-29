#define PLUGIN_VERSION  "1.0"
#define PLUGIN_NAME     "c6m1 c6m3 Character Fix"
#define PLUGIN_PREFIX	"c6m1_c6m3_character_fix"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

char map[64], id[64], value[256];
int key_id;
EntityLumpEntry entry;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=348949"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
}

public void OnMapInit()
{
    GetCurrentMap(map, sizeof(map));
    if(strcmp(map, "c6m1_riverbank") != 0)
    {
		for(int i = 0; i < EntityLump.Length(); i++)
		{
			entry = EntityLump.Get(i);
			key_id = entry.FindKey("hammerid");
			if(key_id != -1)
			{
				entry.Get(key_id, .valbuf = id, .vallen = sizeof(id));
				if(strcmp(id, "1094437") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "1094404") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "1094505") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "765976") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "1093539") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "1094461") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "1094444") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "1094406") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "1093526") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "5531") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "20447") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "24103") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "41665") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "41667") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "41669") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "50231") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "74946") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "93463") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "177701") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "181411") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "181415") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "187883") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "225925") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "236946") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "256944") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "256946") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "256950") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "290873") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "290936") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "291028") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "291030") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "291041") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "569014") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "569031") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "570099") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
			}
			delete entry;
		}
	}
    else if(strcmp(map, "c6m3_port") != 0)
    { 
		for(int i = 0; i < EntityLump.Length(); i++)
		{
			entry = EntityLump.Get(i);
			key_id = entry.FindKey("hammerid");
			if(key_id != -1)
			{
				entry.Get(key_id, .valbuf = id, .vallen = sizeof(id));
				if(strcmp(id, "8411") == 0)
				{
					int key_OnCoop = -1;
					while((key_OnCoop = entry.GetNextKey("OnCoop", value, sizeof(value), key_OnCoop)) != -1)
					{
						if(strcmp(value, "relay_coop_setupTrigger0-1") == 0)
						{
							entry.Erase(key_OnCoop);
							entry.Insert(key_OnCoop, "OnCoop", "relay_vs_setupTrigger0-1");
						}
					}
				}
				else if(strcmp(id, "258835") == 0)
				{
					int key_OnTrigger = -1;
					while((key_OnTrigger = entry.GetNextKey("OnTrigger", value, sizeof(value), key_OnTrigger)) != -1)
					{
						if(strcmp(value, "!zoeyReleaseFromSurvivorPositionzoey_start0-1") == 0)
						{
							entry.Erase(key_OnTrigger--);
						}
						else if(strcmp(value, "!louisReleaseFromSurvivorPositionlouis_start0-1") == 0)
						{
							entry.Erase(key_OnTrigger--);
						}
						else if(strcmp(value, "!francisReleaseFromSurvivorPositionfrancis_start0-1") == 0)
						{
							entry.Erase(key_OnTrigger--);
						}
						else if(strcmp(value, "l4d1_script_relayCancelPending0-1") == 0)
						{
							entry.Erase(key_OnTrigger--);
						}
						else if(strcmp(value, "l4d1_elevator_triggerEnable0-1") == 0)
						{
							entry.Erase(key_OnTrigger--);
						}
					}
				}
				else if(strcmp(id, "1240041") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "1240055") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
				else if(strcmp(id, "1240073") == 0)
				{
					EntityLump.Erase(i--);
					continue;
				}
			}
			delete entry;
		}
	}
}
