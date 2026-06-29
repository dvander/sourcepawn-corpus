//// Credits to DeathChaos25 for the fakezoey, This provided the framework for adawong
#pragma semicolon 1
#include <sourcemod>
#include <sceneprocessor>
#include <sdktools>

#pragma newdecls required

#define DEBUG true

#define PLUGIN_VERSION "0.2.1"

#define FLOAT_(%1) view_as<float>(%1)
#define INT_(%1) view_as<int>(%1)
#define BOOL_(%1) view_as<bool>(%1)

public Plugin myinfo =  
{
	name = "Arcade_talker", 
	author = "", 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
}

//max survivors add proper data in data section below, we could parse this all from keyvalue files.
#define MAX_SURVIVORS 4

char g_ModelPaths[MAX_SURVIVORS][] = 
{
	"models/survivors/survivor_yusuke.mdl",
	"models/survivors/survivor_sara.mdl",
	"models/survivors/survivor_haruka.mdl",
	"models/survivors/survivor_blake.mdl",
};

char g_TalkerPaths[MAX_SURVIVORS][] = 
{
	"data/yusuke.cfg",
	"data/sara.cfg",
	"data/haruka2.cfg",
	"data/blake.cfg",
};

char g_ArcadeNames[MAX_SURVIVORS][32] = 
{
	"Yusuke",
	"Sara",
	"Haruka",
	"Blake",
};

enum ArcadeSurvivorType
{
	ArcadeSurvivorType_None = -1,
	ArcadeSurvivorType_Yusuke,
	ArcadeSurvivorType_Sara,
	ArcadeSurvivorType_Haruka,
	ArcadeSurvivorType_Blake,
	ArcadeSurvivorType_MaxSize,
}

//end of data

ArcadeSurvivorType g_ModelIndexs[MAX_SURVIVORS];
StringMap g_ArcadeTalker[MAX_SURVIVORS];

enum struct ArcadeSurvivors
{
	int EntIndex; // has to be here makes it simple
	
	ArcadeSurvivorType GetArcadeSurvivor()
	{
		if(GetClientTeam(this.EntIndex) != 2 || GetEntProp(this.EntIndex, Prop_Send, "m_survivorCharacter") != 8)
			return ArcadeSurvivorType_None;
		
		int ModexIndex = GetEntProp(this.EntIndex, Prop_Send, "m_nModelIndex", 2);
		for(int i = 0; i < MAX_SURVIVORS; i++)
		{
			if(g_ModelIndexs[i] == view_as<ArcadeSurvivorType>(ModexIndex)) //viewas because i know better than the compiler, in precache be return -1 if model is not precached due to being missing, this avoids if survivor has model index of 0 and does spooky stuff
			{
				return view_as<ArcadeSurvivorType>(i);
			}
		}
		return ArcadeSurvivorType_None;
	}
	char GetArcadeSurvivorName(char name[32])// arrays are referenced by default
	{
		int ModexIndex = GetEntProp(this.EntIndex, Prop_Send, "m_nModelIndex", 2); // get's survivor name from g_ArcadeNames using model index nothing uses it but maybe usefull in future.
		for(int i; i < MAX_SURVIVORS; i++)
		{
			if(g_ModelIndexs[i] == view_as<ArcadeSurvivorType>(ModexIndex))
			{
				name = g_ArcadeNames[i];
				return;
			}
		}
		name[0] = '\0'; //return empty string 
	}
	bool GetArcadeSceneReplace(ArcadeSurvivorType type, char scene[PLATFORM_MAX_PATH]) //find replacement scene
	{
		static char sSceneTemp[PLATFORM_MAX_PATH];
		sSceneTemp = scene;
		return g_ArcadeTalker[type].GetString(sSceneTemp, scene, sizeof(scene)); //return false if no hash matches or no replacement, copies stored string if hash matches to scene array.
	}
}

ArcadeSurvivors g_ArcadePlayers[MAXPLAYERS+1];

bool bL4D1Campaign;

void PrecacheSurvivors()
{
	for(int i; i < MAX_SURVIVORS; i++)
	{
		int index = PrecacheModel(g_ModelPaths[i], true);
		INT_(g_ModelIndexs[i]) = (index == 0 ? -1 : index); //precaches model and converts string to index, less full string checking makes enum easier, this also returns -1 if model is not found for failsafe.
	}
}

public void OnPluginStart()
{
	RegAdminCmd("sm_arcade_repase_taker", ReParseTalkerLines, ADMFLAG_ROOT); //cake?
	ParseTalkerLines(); // cream cake

	for(int i; i <= MAXPLAYERS; i++)
		g_ArcadePlayers[i].EntIndex = i; //EntIndex = client index, just easier so i can use this.EntIndex in functions that require entindexs just a trick to make life easier
}

public Action ReParseTalkerLines(int client, int args)
{
	for(int i; i < MAX_SURVIVORS; i++)
		delete g_ArcadeTalker[i]; //delete current Trie's and repase
	
	ParseTalkerLines();
}


void ParseTalkerLines()
{
	for(int i; i < MAX_SURVIVORS; i++)
	{
		g_ArcadeTalker[i] = CreateTrie(); //creates hashmap legacy name is `CreateTrie` but still  gotta create it for each survivor
		char sPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sPath, sizeof(sPath), "%s", g_TalkerPaths[i]);
		if(!FileExists(sPath))
		{
			LogError("[%s] Error: Cannot read the talker lines \"%s\"", g_ArcadeNames[i], sPath);
			continue;
		}
		// Get scenes from config
		Handle hFile = CreateKeyValues("scenes");
		if(!FileToKeyValues(hFile, sPath))
		{
			LogError("[%s] Error: Failed to get talker scenes from %s",  g_ArcadeNames[i], sPath);
			delete hFile;
			continue;
		}
	// Check the character to get scene info from
		if(!KvJumpToKey(hFile, g_ArcadeNames[i]))
		{
			LogError("[%s] Error: Failed to get talker character from %s", g_ArcadeNames[i], sPath);
			delete hFile;
			continue;
		}
	// Retrieve how many scenes for this character
		int iMaxscenes = KvGetNum(hFile, "max_scenes", 0);
		if (iMaxscenes == 0)
		{
			LogError("[%s] Error: Failed to get talker max_scenes from %s", g_ArcadeNames[i], sPath);
			delete hFile;
			continue;
		}
	// Get the scene replacement info
		char sTemp[32];
		char sScene[PLATFORM_MAX_PATH];
		char sReplacement[PLATFORM_MAX_PATH];
		
		for(int x = 1; x <= iMaxscenes; x++)
		{
			//we could maybe remove the MAXSCENE keyvale sometime don't really matter
			IntToString(x, sTemp, sizeof(sTemp));
			if(!KvJumpToKey(hFile, sTemp))
			{
				delete hFile;
				break;
			}
			
			KvGetString(hFile, "scene", sScene, sizeof(sScene));
			KvGetString(hFile, "replace", sReplacement, sizeof(sReplacement));
			
			#if DEBUG
			PrintToServer("[%s] \"%s\" -> \"%s\"", g_ArcadeNames[i], sScene, sReplacement);
			#endif
			
			g_ArcadeTalker[i].SetString(sScene, sReplacement); //gets the scene key and repacement and converts the scene to a hash and stores the replacement as a string to copy.
			KvGoBack(hFile);
		}
		delete hFile;
	}
}

public void OnMapStart()
{
	PrecacheSurvivors();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead 2 Only!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}


/////////////////////////////////
/////Survivor Set Related Stuff//
/////////////////////////////////

public Action L4D_OnGetSurvivorSet(int &retVal)
{
    //if (retVal == 1 && !bL4D1Campaign)
	if (retVal == 1)
    {
		//PrintToChatAll("Set 1");
        bL4D1Campaign = true;
    }
    //else if (bL4D1Campaign && retVal == 2)
	else if (retVal == 2)
    {
		//PrintToChatAll("Set 2");
        bL4D1Campaign = false;
    }
	return Plugin_Continue;
}

public Action L4D_OnFastGetSurvivorSet(int &retVal)
{
    //if (retVal == 1 && !bL4D1Campaign)
	if (retVal == 1)
    {
		//PrintToChatAll("Set 1");
        bL4D1Campaign = true;
    }
    //else if (bL4D1Campaign && retVal == 2)
	else if (retVal == 2)
    {
		//PrintToChatAll("Set 2");
        bL4D1Campaign = false;
    }
	return Plugin_Continue;
}

public void OnSceneStageChanged(int scene, SceneStages stage)
{
	if (bL4D1Campaign)
	{	
		return;
	}

	if (!bL4D1Campaign)
	{
		if (stage != SceneStage_Started || GetSceneInitiator(scene) == SCENE_INITIATOR_PLUGIN) // Do not capture scenes spawned by the plugin, to prevent a loop
		{
			return;
		}
		
		int actor = GetActorFromScene(scene);
		if(!IsSurvivor(actor))
			return;
		
		ArcadeSurvivorType type = g_ArcadePlayers[actor].GetArcadeSurvivor(); //Gets survivor type see `ArcadeSurvivorType` enum  types by using entity index.
		if(type != ArcadeSurvivorType_None)
		{
			
			static char sceneFile[MAX_SCENEFILE_LENGTH];
			GetSceneFile(scene, sceneFile, sizeof(sceneFile));
			CancelScene(scene);
			
			#if DEBUG
			char debugPringScene[MAX_SCENEFILE_LENGTH];
			debugPringScene = sceneFile;
			#endif
			
			// if no scene hash is found or no replacement string for hash do nothing.
			if(!g_ArcadePlayers[actor].GetArcadeSceneReplace(type, sceneFile))
			{
				#if DEBUG
				PrintToChatAll("%N failed to speak scene", actor);
				PrintToChatAll("%s", debugPringScene);
				PrintToChatAll("replacement %s", sceneFile);
				#endif
				return;
			}
			
			//forgot why i did this
			//for(new x = 1; x <= 2; x++)
			//PerformSceneEx(actor, "", sSavedScene);
			
			PerformSceneEx(actor, "", sceneFile); //yay we found replacement scene lets play it :3
	
		}
		switch (stage)
		{
			case SceneStage_Started:
			{
				int client = GetActorFromScene(scene);
				if(IsSurvivor(client))
					return;
					
				char vocalize[MAX_VOCALIZE_LENGTH];
				if(GetSceneVocalize(scene, vocalize, sizeof(vocalize)) == 0)
					return;
				
				if(!StrEqual(vocalize, "smartlook", false))
					return;
				
				int target = GetClientAimTarget(client, true);
				if(!IsSurvivor(target))
					return;
				//Gets survivor type see `ArcadeSurvivorType` enum  types by using entity index.
				if (g_ArcadePlayers[target].GetArcadeSurvivor() != ArcadeSurvivorType_None)// i don't get it :c
					return;
			}
		}
	}
}

bool IsSurvivor(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
		return false;
	return true;
}

