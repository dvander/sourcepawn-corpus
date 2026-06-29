#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:g_trie;
new Handle:g_curSection;
new g_model;

public OnPluginStart()
{
	CreateConVar("niftytools_version", PLUGIN_VERSION, "Nifty Tools Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_logo", Command_Logo);
	
	g_model = PrecacheModel("sprites/lgtning.vmt");
	
	g_trie = CreateTrie();
	
	new Handle:parser = SMC_CreateParser();
	
	SMC_SetReaders(parser, NewSection, KeyValue, EndSection);
	
	decl String:configPath[256];
	BuildPath(Path_SM, configPath, sizeof(configPath), "configs/logos.cfg");
	
	if (!FileExists(configPath))
	{
		LogError("Unable to locate exec config file, no maps loaded.");
			
		return;		
	}
	
	new line;
	new SMCError:err = SMC_ParseFile(parser, configPath, line);
	if (err != SMCError_Okay)
	{
		decl String:error[256];
		SMC_GetErrorString(err, error, sizeof(error));
		LogError("Could not parse file (line %d, file \"%s\"):", line, configPath);
		LogError("Parser encountered error: %s", error);
	}
	
	CloseHandle(parser);
	
	return;
}

public Action:Command_Logo(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This cannot be executed from server console");
		return Plugin_Handled;	
	}
	
	decl String:arg[50];
	GetCmdArg(1, arg, sizeof(arg));
	
	new Handle:array;
	
	if (!GetTrieValue(g_trie, arg, any:array))
	{
		ReplyToCommand(client, "Logo not Found");
		return Plugin_Handled;			
	}
	
	new size = GetArraySize(array);
	
	new Float:coords[10];
	new Float:start[3];
	new Float:end[3];
	
	new Float:loc[3];
	GetClientAbsOrigin(client, loc);
	loc[2] += 100;
	
	new colour[4];
	
	for (new i=0; i<size; i++)
	{
		GetArrayArray(array, i, any:coords);
		
		start[0] = coords[0] + loc[0];
		start[1] = coords[1] + loc[1];
		start[2] = coords[2] + loc[2];
		end[0] = coords[3] + loc[0];
		end[1] = coords[4] + loc[1];
		end[2] = coords[5] + loc[2];
		
		colour[0] = RoundToNearest(coords[6]);
		colour[1] = RoundToNearest(coords[7]);
		colour[2] = RoundToNearest(coords[8]);
		colour[3] = RoundToNearest(coords[9]);
		
		//DRAW THE LINE ALREADY !!
		
		TE_SetupBeamPoints(start, end, g_model, 0, 0, 0, 20.0, 2.0, 2.0, 0, 0.0, colour, 0);
		TE_SendToAll();
	}
		
	return Plugin_Handled;
}

public SMCResult:NewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
	new Handle:array = CreateArray(10);
	if (!SetTrieValue(g_trie, name, array))
	{
		SetFailState("Duplicate Names in config file");
		return SMCParse_HaltFail;	
	}
	
	g_curSection = array;
	
	return SMCParse_Continue;
}

public SMCResult:KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	decl Float:intcoords[10];
	
	if (IsCharAlpha(key[0]))
	{
		new Handle:array;
		
		if (!GetTrieValue(g_trie, key, any:array))
		{
			SetFailState("Template not found or letters in co-ordinate section");
			return SMCParse_HaltFail;			
		}
		
		decl String:offsets[3][10];
		new Float:intoffsets[3];
		
		if (ExplodeString(value, " ", offsets, 3, 10) != 3)
    	{
			SetFailState("Invalid offsets");
			return SMCParse_HaltFail;
    	}
  
		for (new i=0; i<3; i++)
		{
			intoffsets[i] = StringToFloat(offsets[i]);	
		}

		// Copy all of array into g_curSection
		new size = GetArraySize(array);
		
		for (new i=0; i<size; i++)
		{
			GetArrayArray(array, i, any:intcoords);
			
			intcoords[0] += intoffsets[0];
			intcoords[1] += intoffsets[1];
			intcoords[2] += intoffsets[2];
			intcoords[3] += intoffsets[0];
			intcoords[4] += intoffsets[1];
			intcoords[5] += intoffsets[2];
			
			PushArrayArray(g_curSection, any:intcoords);
		}
		
		return SMCParse_Continue;
	}
	
	decl String:coords[6][10];
	decl String:colours[4][10];
	
	if (ExplodeString(key, " ", coords, 6, 10) != 6)
    {
		SetFailState("Invalid number of co-ordinates");
		return SMCParse_HaltFail;
    }
    
	if (ExplodeString(value, " ", colours, 4, 10) != 4)
    {
		SetFailState("Invalid number of colours");
		return SMCParse_HaltFail;
	}
	
	new i;

	for (i=0; i<6; i++)
	{
		intcoords[i] = StringToFloat(coords[i]);   
	}
	
	intcoords[6] = StringToFloat(colours[0]);
	intcoords[7] = StringToFloat(colours[1]);
	intcoords[8] = StringToFloat(colours[2]);
	intcoords[9] = StringToFloat(colours[3]);
	
	PushArrayArray(g_curSection, any:intcoords);

	return SMCParse_Continue;
}

public SMCResult:EndSection(Handle:smc)
{
	g_curSection = INVALID_HANDLE;
}