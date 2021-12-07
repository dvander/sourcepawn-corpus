/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.	If not, see <http://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <sdktools>
#include "gamemodes.inc"

#define	MaxCvars 96
#define plugin_version "0.7.1"

//This is the enum and array we use to store the values we want to change in game
enum CvarInfo // enum for array values
{
	Handle:CvarHandle = INVALID_HANDLE,	//The Cvar we are changing
	bool:Dynamic,		//How the change is applied, 1 = dynamic (defaults to this) scales in line with score difference), 0 = static (apply flat change when score difference condition met)
	DifferenceNeeded,	//Difference needed for static change to be applied
	Default,			//Default value of the cvar
	MaxWin,				//Maximum value the cvar can change by when the winning team is survivors
	MaxLose,			//Maximum value the cvar can change by when the losing team is survivors
	CurrentWin,			//Current change when the winning team is survivors (MaxWin*change multiplier)
	CurrentLose,		//Current change when the losing team is survivors (MaxLose*change multiplier)
	WinBoundry,			//The largest change possible for this invidiual instance when the winning team is survivors - if you have multiple instances of a cvar, they are all invidiual to eachother
	LoseBoundry,		//The largest change possible for this invidiual instance when the losing team is survivors - if you have multiple instances of a cvar, they are all invidiual to eachother
	ShowToPlayers,		//Should we print this value to chat. 0 = never print, 1 = print in !agd, 2 = print as part of round start information, 3 = print to both.
	bool:IsTankCvar,	//Tank HP is generally the cvar * multiplier, so make a note of any tank cvars so we can change the printout to be correct later on
}
static CvarArray[MaxCvars][CvarInfo];	//array for cvars and associated values
new String:PrintNames[MaxCvars][32]; 	//Printable names for values, eg, for z_health, you can use Common health
new NumOfCvars = 0; 					//Number of cvars read from keyvalues file

//Game mode information
new Handle:h_AllowedGameModes = INVALID_HANDLE;		//Handle to allowed game modes cvar, which gets split into the below array
new String:s_AllowedGameModes[32][16];				
new NumAllowedGameModes = 0;						//How many allowed game modes are there
new Handle:h_SurvivalSecondWeighting = INVALID_HANDLE;//Handle for how many points every 1 second in survival is worth
new Float:SurvivalSecondWeighting = 1.0;		

//score system
new Handle:h_MaxScoreDiff = INVALID_HANDLE; 		//Handle for cvar l4d2_vshc_scoredifference (when this score differnce is reached, the handicap will be 100%)
new MaxScoreDiff = 0;
new Handle:h_HandicapLimit = INVALID_HANDLE;		//Handle for l4d2_vshc_limit (handicap multiplier limit)
new Float:HandicapLimit = 1.0;		
new ScoreSystem = 0;								//What type of score system to use 0 = map completion scoring (coop, realism), 1 = versus point scoring, 2 = scavenge gascan scoring, 3 = survival timer scoring
new Float:CurrentHandicap = 0.0; 					//The multiplier to apply to the cvar changes, becomes a fraction of campaign score difference, and the max score difference to consider
new TeamPlayingSurvivors = 0; 						//Used to store logical team currently playign survivors, A = 1, B = 2, can be set to 0 to indicate a tie
new Handle:h_CoopRealismMapPoints = INVALID_HANDLE;	//Handle for l4d2_vshc_CoopRealismMapPoints (how many points each map is worth in coop/realism game modes/mutations
new CoopRealismMapPoints;
new CoopRealismMapsDone = 0;						//How many maps have been done so far in the campaign?
new TeamAScore = 0;									//Used to store campaign score for versus (not affected by current map score)
new TeamBScore = 0;
new Handle:h_GasCanWeighting = INVALID_HANDLE;		//Handle to gas can points value cvar for scavenge
new GasCanWeighting = 0;							
new Float:TeamATime = 0.0;							//Round times (for survival) get wiped at the start of every new round, so we need to track them manually.
new Float:TeamBTime = 0.0;
new scoredifference = 0;							//Holds the difference between team scores, always positive.

//sdkcall
new Handle:gConfRaw = INVALID_HANDLE;				//Handle for loading director pointer for sdkcalls
new Address:g_pDirector = Address:0;				//Address to store the director pointer
new Handle:h_L4D_GetTeamScore = INVALID_HANDLE;		//Handle for L4D_GetTeamScore command

//misc globals
new bool:IsEnabled = false;				//Is the handicapper enabled for this game mode
new bool:IsActive = false;				//Is the handicapper actually running (not a tied up game)
new bool:b_HandicapsApplied = false; 	//Detects if modifiers have been applied
new bool:RoundStartPrintDone = false; //Avoid multiple print outs to chat
new Float:TankHealthMultiplier = 1.0;	//Multiplier for tank health printout.
new String:CurrentMapName[32] = "";				//What is the name of the current map
new String:NextMapName[32] = "";				//Used to store the name of the next map for coop/realism map based handicapping
new bool:b_RoundEnd = false; 			//Used to work around multiple round end calls
new RoundsDone = 0;						//How many rounds have been done
new Handle:h_DisplayPanel = INVALID_HANDLE;			//Handle for panel to display all values in
new Handle:h_MutationsTrie = INVALID_HANDLE;	//Handle to the mutations trie
new Handle:h_CvarShowToPlayers = INVALID_HANDLE;	//Handle for what to allow players to access
new CvarShowToPlayers = 0;							



public Plugin:myinfo =
{
	name = "L4D2_Versus_Handicap",
	author = "Sneaky Green Guy (SGG)",
	description = "Changes server cvars at map start according to overall campaign scores in versus",
	version = plugin_version,
	url = "http://forums.alliedmods.net/showthread.php?t=180621"
}
 
public OnPluginStart()
{
	//Set up commands
	RegConsoleCmd("sm_agd", agd_cmd);
	RegAdminCmd("sm_agd_cvars_reload", ReloadKeyValues_cmd,ADMFLAG_GENERIC, "Reload the cvar keyvalues file");
	RegAdminCmd("sm_agd_trie_reload", ReloadTrie_cmd, ADMFLAG_GENERIC, "Reload the supported mutations file.");

	//Setup all plugin cvars and their handles
	h_MaxScoreDiff = CreateConVar("l4d2_vshc_scoredifference", "500", "The score difference to consider, when the score is this far apart, the multiplier will be 1.0", FCVAR_PLUGIN,true,0.0);
	h_HandicapLimit = CreateConVar("l4d2_vshc_limit", "1.0", "what multiplier the handicap limiter maxes out at", FCVAR_PLUGIN,true,0.0);
	h_CvarShowToPlayers = CreateConVar("l4d2_vshc_showtoplayers", "3", "Enable/disable round start chat and sm_agd command, 1 = agd command only, 2 = start chat only, 3 = both", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	h_AllowedGameModes = CreateConVar("l4d2_vshc_allowedgamemodes", "versus,mutation12,mutation13,mutation15,community6,scavenge", "Game modes that the plugin will run on, versus and scavenge vairants supported", FCVAR_PLUGIN);
	h_GasCanWeighting = CreateConVar("l4d2_vshc_gascanpoints", "40", "How many points each gascan is worth in scavenge to the director", FCVAR_PLUGIN, true, 0.0);
	h_SurvivalSecondWeighting = CreateConVar("l4d2_vshc_survivalsecondspoints", "1.0", "How many points each second in Sirvival is worth to the director", FCVAR_PLUGIN, true, 0.0);
	h_CoopRealismMapPoints = CreateConVar("l4d2_vshc_CoopRealismMapPoints", "75", "How many points each map is worth in Coop/Realism to the director", FCVAR_PLUGIN, true, 0.0);
	AutoExecConfig(true,"l4d2_versus_handicap");
	
	//Capture all plugin cvar values
	UpdateAllowedGameModes()
	MaxScoreDiff = GetConVarInt(h_MaxScoreDiff);
	HandicapLimit = GetConVarFloat(h_HandicapLimit);
	GasCanWeighting = GetConVarInt(h_GasCanWeighting);
	SurvivalSecondWeighting = GetConVarFloat(h_SurvivalSecondWeighting);
	CoopRealismMapPoints = GetConVarInt(h_CoopRealismMapPoints);
	CvarShowToPlayers = GetConVarInt(h_CvarShowToPlayers);
	
	//Capture any future change to plugin cvars
	HookConVarChange(h_MaxScoreDiff, ConVarChanged);
	HookConVarChange(h_HandicapLimit, ConVarChanged);
	HookConVarChange(h_AllowedGameModes, ConVarChanged);
	HookConVarChange(h_GasCanWeighting, ConVarChanged);
	HookConVarChange(h_SurvivalSecondWeighting, ConVarChanged);
	HookConVarChange(h_CoopRealismMapPoints, ConVarChanged);
	HookConVarChange(h_CvarShowToPlayers, ConVarChanged);
	
	//Hook needed game events and cvar changes
	HookConVarChange(FindConVar("mp_gamemode"), GameModeChanged);
	HookConVarChange(FindConVar("mp_gamemode"), TankHealthMultiplierChanged);
	HookConVarChange(FindConVar("z_difficulty"), TankHealthMultiplierChanged);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", EventHook:LeftStartAreaEvent, EventHookMode_PostNoCopy);
	HookEvent("player_left_checkpoint", EventHook:Event_PlayerLeftCheckpoint, EventHookMode_PostNoCopy);

	//Read config files and get SDK calls setup, if any of these return false, then log an error
	if (!ReloadKeyValues()){ LogError("Errors with addons/sourcemod/configs/kv_l4d2_versus_handicap.cfg"); }
	if (!PrepAllSDKCalls())	{ LogError("Errors with addons/sourcemod/gamedata/l4d2_versus_handicap_gamedata.txt"); }	
	if (!ReloadMutationsList()) { LogError("Errors loading addons/sourcemod/data/l4d2_mutations_list.txt"); }
	
	//Plguin version cvar
	CreateConVar("l4d2_vshc_version", plugin_version, "Left 4 Dead 2 versus handicap version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_DONTRECORD);
}

public ConVarChanged(Handle:cvar, const String:oldValue[], const String:newValue[]) 
{
	MaxScoreDiff = GetConVarInt(h_MaxScoreDiff);
	HandicapLimit = GetConVarFloat(h_HandicapLimit);
	GasCanWeighting = GetConVarInt(h_GasCanWeighting);
	SurvivalSecondWeighting = GetConVarFloat(h_SurvivalSecondWeighting);	
	CoopRealismMapPoints = GetConVarInt(h_CoopRealismMapPoints);	
	CvarShowToPlayers = GetConVarInt(h_CvarShowToPlayers);
	decl String:temp[255]
	GetConVarName(h_AllowedGameModes,temp,sizeof(temp));
	if (StrEqual(temp,"l4d2_vshc_allowedgamemodes", false)) // only run the allowed game modes array rebuild on that one cvar change
	{
		UpdateAllowedGameModes()
	}
}

UpdateAllowedGameModes()
{
	decl String:temp[511];
	GetConVarString(h_AllowedGameModes, temp, sizeof(temp));
	NumAllowedGameModes = ExplodeString(temp,",",s_AllowedGameModes,sizeof(s_AllowedGameModes), sizeof(s_AllowedGameModes[]), false);
}

public TankHealthMultiplierChanged(Handle:cvar, const String:oldValue[], const String:newValue[]) 
{
	ScoreSystem = DetectScoreSystem();
	if(ScoreSystem == 0)
	{
		if (StrEqual(newValue, "easy", false))
		{
			TankHealthMultiplier = 0.75;
		}
		else if (StrEqual(newValue, "normal", false))
		{
			TankHealthMultiplier = 1.0;
		}
		else if (StrEqual(newValue, "hard", false))
		{
			TankHealthMultiplier = 1.5;
		}
		else if (StrEqual(newValue, "impossible", false))
		{
			TankHealthMultiplier = 2.0;
		}
	}
	else
	{
		TankHealthMultiplier = 1.5;
	}
}

public GameModeChanged(Handle:cvar, const String:oldValue[], const String:newValue[]) 
{
	if (!StrEqual(oldValue,newValue,false)) //making sure game modes have changed
	{
		TeamAScore = 0;
		TeamBScore = 0;
		CoopRealismMapsDone = 0;
	}
}
public Action:ReloadKeyValues_cmd(client, args)
{
	if (!ReloadKeyValues()) // if it returns false, errors occured
	{
		if (client == 0){ PrintToServer("Errors with addons/sourcemod/configs/kv_l4d2_versus_handicap.cfg"); }
		else { PrintToChat(client,"Errors with addons/sourcemod/configs/kv_l4d2_versus_handicap.cfg"); }
		LogError("Errors with addons/sourcemod/configs/kv_l4d2_versus_handicap.cfg");
	}
	else
	{
		if (client == 0){ PrintToServer("Keyvalues file reloaded sucessfully"); }
		else { PrintToChat(client,"Keyvalues file reloaded sucessfully"); }
	}
}

public Action:ReloadTrie_cmd(client, args)
{
	if (!ReloadMutationsList()) //if it returns false, means there was an error
	{
		if (client == 0){ PrintToServer("Errors loading addons/sourcemod/data/l4d2_mutations_list.txt"); }
		else { PrintToChat(client,"Errors loading addons/sourcemod/data/l4d2_mutations_list.txt"); }	
		LogError("Errors loading addons/sourcemod/data/l4d2_mutations_list.txt");
	}
	else
	{
		if (client == 0){ PrintToServer("Mutations file reloaded sucessfully"); }
		else { PrintToChat(client,"Mutations file reloaded sucessfully"); }
	}
}

bool:ReloadKeyValues()
{
	new bool:NoErrors=true;
	decl String:HandicapConfigFile[PLATFORM_MAX_PATH]	= "", String:buffer[32], String:success[32] = "none";
	new Handle:keyValueHolder = INVALID_HANDLE;	
	BuildPath(Path_SM, HandicapConfigFile, sizeof(HandicapConfigFile), "configs/kv_l4d2_versus_handicap.cfg");
	if(!FileExists(HandicapConfigFile)) { SetFailState("kv_l4d2_versus_handicap.cfg not present!"); }
	if (keyValueHolder != INVALID_HANDLE) { CloseHandle(keyValueHolder); }
	keyValueHolder = CreateKeyValues("kv_l4d2_Versus_Handicap");
	FileToKeyValues(keyValueHolder, HandicapConfigFile);
	KvRewind(keyValueHolder);
	NumOfCvars = 0;	
	if (KvGotoFirstSubKey(keyValueHolder))
	{
		do
		{
			KvGetSectionName(keyValueHolder, buffer, sizeof(buffer));
			PrintNames[NumOfCvars] = buffer;
			KvGetString(keyValueHolder, "KV_CvarHandle", buffer, sizeof(buffer), "");
			if (StrEqual(buffer,"z_tank_health", false)) { CvarArray[NumOfCvars][IsTankCvar] = true;}
			else { CvarArray[NumOfCvars][IsTankCvar] = false;}
			CvarArray[NumOfCvars][CvarHandle] = FindConVar(buffer);
			
			//error checking/finding for file
			if (CvarArray[NumOfCvars][CvarHandle] == INVALID_HANDLE)
			{
				LogError("Cvar %s doesn't exist! Last sucessful value was %s", buffer, success);
				NoErrors = false;
			}
			else { KvGetSectionName(keyValueHolder, success, sizeof(success));}
			KvGetString(keyValueHolder, "KV_MaxWin", buffer, sizeof(buffer), "0");
			CvarArray[NumOfCvars][MaxWin] = StringToInt(buffer); 
			KvGetString(keyValueHolder, "KV_MaxLose", buffer, sizeof(buffer), "0");
			CvarArray[NumOfCvars][MaxLose] = StringToInt(buffer);
			KvGetString(keyValueHolder, "KV_ShowToPlayers", buffer, sizeof(buffer), "0"); // Print this value to players, and if so, how?
			CvarArray[NumOfCvars][ShowToPlayers] = StringToInt(buffer);
			KvGetString(keyValueHolder, "KV_DynamicBuff", buffer, sizeof(buffer), "true");
			if (StrEqual(buffer, "true", false)) //If it is not a dynamic buff, it is static, so read the difference needed cvar
			{
				CvarArray[NumOfCvars][Dynamic] = true;
				KvGetString(keyValueHolder, "KV_WinBoundry", buffer, sizeof(buffer), "0"); // Maximum change regardless of handicap %
				CvarArray[NumOfCvars][WinBoundry] = StringToInt(buffer);
				KvGetString(keyValueHolder, "KV_LoseBoundry", buffer, sizeof(buffer), "0"); // Maximum change regardless of handicap %
				CvarArray[NumOfCvars][LoseBoundry] = StringToInt(buffer);

			}
			else if (StrEqual(buffer, "false", false))
			{
				CvarArray[NumOfCvars][Dynamic] = false;
				KvGetString(keyValueHolder, "KV_DifferenceNeeded", buffer, sizeof(buffer), "-1"); // Print this value to players?
				CvarArray[NumOfCvars][DifferenceNeeded] = StringToInt(buffer);
			}
			NumOfCvars++;
		}
		while (KvGotoNextKey(keyValueHolder));
	}
	else
	{
		SetFailState("kv_l4d2_Versus_Handicap.cfg could not be read correctly.");
		NoErrors = false;
	}
	return NoErrors;
}

bool:ReloadMutationsList()
{
	new bool:NoErrors = true;
	//Clear any existing Trie
	if(h_MutationsTrie != INVALID_HANDLE) 
	CloseHandle(h_MutationsTrie);
	h_MutationsTrie = CreateTrie();
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/l4d2_mutations_list.cfg");
	if( FileExists(sPath) )
	{
		new Handle:h_File = OpenFile(sPath, "r");
		new String:temp[64], String:mutationinfo[2][32];
		new i = 0, scoretype = -1;
		if( h_File != INVALID_HANDLE )
		{
			while(!IsEndOfFile(h_File) && ReadFileLine(h_File, temp, sizeof(temp)))
			{
				ExplodeString(temp, ",", mutationinfo, sizeof(mutationinfo), sizeof(mutationinfo[]), false); //Get the values seperated
				TrimString(mutationinfo[1]);
				i++;
				if (StrEqual(mutationinfo[1], "coop", false))
				{
					scoretype = 0;
				}
				else if (StrEqual(mutationinfo[1], "realism", false))
				{
					scoretype = 0;
				}
				else if (StrEqual(mutationinfo[1], "versus", false))
				{
					scoretype = 1;
				}
				else if (StrEqual(mutationinfo[1], "scavenge", false))
				{
					scoretype = 2;
				}
				else if (StrEqual(mutationinfo[1], "survival", false))
				{
					scoretype = 3;
				}
				else
				{
					LogError("Mutation %s has invalid base game mode of %s (line %i)", mutationinfo[0], mutationinfo[1], i);
					NoErrors = false;
					scoretype = -1;
				}
				SetTrieValue(h_MutationsTrie, mutationinfo[0], scoretype);
			}
		}
		CloseHandle(h_File);
	}
	else//file does not exist
	{
		LogError("Error file data/l4d2_mutations_list.txt does not exist.");
		NoErrors = false;
	}
	return NoErrors;
}

bool:PrepAllSDKCalls()
{
	new bool:NoErrors = true;
	gConfRaw = LoadGameConfigFile("L4D2_Versus_Handicap_gamedata");
	if(gConfRaw == INVALID_HANDLE)
	{
		LogError("Could not load gamedata/L4D2_Versus_Handicap_gamedata.txt"); 
		NoErrors = false;
	}
	g_pDirector = GameConfGetAddress(gConfRaw, "CDirector");
	if(g_pDirector == Address_Null)
	{
		LogError("Could not load the Director pointer");
		NoErrors = false;
	}
	StartPrepSDKCall(SDKCall_GameRules);
	if (!PrepSDKCall_SetFromConf(gConfRaw, SDKConf_Signature, "GetTeamScore")) 
	{
		LogError("Could not load the GetTeamScore signature")
		NoErrors = false;
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	h_L4D_GetTeamScore = EndPrepSDKCall();
	return NoErrors;
}

public OnMapStart()
{
	IsEnabled = false;
	ScoreSystem = DetectScoreSystem()
	if (EnabledGameMode() && ScoreSystem != -1)
	{
		IsEnabled = true;
		RoundsDone = 0;
		b_RoundEnd = false;
		TeamPlayingSurvivors = 0;
		RoundStartPrintDone = false;
		switch (ScoreSystem) //Only for multi map gametypes, single map gametypes are done later, after points have been accumulated
		{
			case 0: //coop/realism score system
			{
				CreateTimer(4.0, CoopRealismMapStartDelay) // 4 second delay to avoid conflicts with anything else changing cvars at map start
			}
			case 1: //versus score system
			{
				CreateTimer(4.0, VersusMapStartDelay)
			}
		}
	}
}

public Action:CoopRealismMapStartDelay(Handle:timer)
{
	//Is this the next map?
	GetCurrentMap(CurrentMapName,sizeof(CurrentMapName));
	if (StrEqual(CurrentMapName, NextMapName, false))
	{
		CoopRealismMapsDone++;
	}
	else
	{
		CoopRealismMapsDone = 0; //unexpected new map, reset counter
	}
	new ent_InfoChangelevel = FindEntityByClassname(0,"info_changelevel");
	if (ent_InfoChangelevel == -1) //no  change level means no next map, happens on finale
	{
		NextMapName = "";
	}
	else
	{
		if (IsValidEntity(ent_InfoChangelevel) && IsValidEdict(ent_InfoChangelevel))
		{
			new offset = FindDataMapOffs(ent_InfoChangelevel, "m_mapName");
			GetEntDataString(ent_InfoChangelevel, offset, NextMapName, sizeof(NextMapName));
		}
	}
	UpdateScores()
	if (TeamAScore > 0)
	{
		if (b_HandicapsApplied) { RemoveHandicaps(); }
		TeamPlayingSurvivors = 1;
		CalculateHandicaps();
		AttemptApplyHandicaps();
	}
	else
	{
		TeamPlayingSurvivors = 0;
	}
	
}

public Action:VersusMapStartDelay(Handle:timer)
{
	UpdateScores()
	TeamPlayingSurvivors = FindSurvivorsVSMode()
	if (TeamPlayingSurvivors != 0)
	{
		CalculateHandicaps()
		AttemptApplyHandicaps()
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (b_RoundEnd) { b_RoundEnd = false; }
}

public LeftStartAreaEvent()
{
	if(!RoundStartPrintDone)
	{
		RoundStartPrintDone = true;
		PrintAGDToChat()
	}
}

public Event_PlayerLeftCheckpoint()
{
	if(!RoundStartPrintDone)
	{
		RoundStartPrintDone = true;
		CreateTimer(10.0, PrintAGDToChatOnTimer)
	}
}
public Action:PrintAGDToChatOnTimer(Handle:timer)
{
	PrintAGDToChat()
}

PrintAGDToChat()
{
	if (b_HandicapsApplied && CvarShowToPlayers >= 2)
	{
		new i = 0;
		decl String:buffer[255] = "\x01", String:add[64], String:ConVarName[32];
		do
		{
			if (CvarArray[i][ShowToPlayers] == 2 || CvarArray[i][ShowToPlayers] == 3)
			{
				GetConVarName(CvarArray[i][CvarHandle], ConVarName, sizeof(ConVarName));
				if (CvarArray[i][Dynamic] == true)
				{
					if (CvarArray[i][IsTankCvar])
					{
						Format(add, sizeof(add), "%s: [\x04%i\x01] ", PrintNames[i], RoundToNearest(GetConVarInt(CvarArray[i][CvarHandle]) * TankHealthMultiplier));
					}
					else
					{
						Format(add, sizeof(add), "%s: [\x04%i\x01] ", PrintNames[i], GetConVarInt(CvarArray[i][CvarHandle]));
					}
					StrCat(buffer,sizeof(buffer), add);
				}
				else if (scoredifference > CvarArray[i][DifferenceNeeded] || (scoredifference > MaxScoreDiff && CvarArray[i][DifferenceNeeded] == -1))
				{
					if (CvarArray[i][IsTankCvar])
					{
						Format(add, sizeof(add), "%s: [\x04%i\x01] ", PrintNames[i], RoundToNearest(GetConVarInt(CvarArray[i][CvarHandle]) * TankHealthMultiplier));
					}
					else
					{
						Format(add, sizeof(add), "%s: [\x04%i\x01.]", PrintNames[i], GetConVarInt(CvarArray[i][CvarHandle]));
					}
					StrCat(buffer,sizeof(buffer), add);
				}
			}
			i++;
		}
		while (i < NumOfCvars)
		
		new Float:changepercent = CurrentHandicap * 100;
		PrintToChatAll("\x01Aggressive Director at \x04%.1f%%\x01. Type !agd for details.", changepercent);
		if (StrEqual(buffer, "\x01", false) == false) { PrintToChatAll("%s", buffer); }
	}
	else if (b_HandicapsApplied  && CvarShowToPlayers == 1)
	{
		PrintToChatAll("Use the !agd command to view agressgive director changes");
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!b_RoundEnd) // Only runs if this is the first round end event called, and modifiers have been previously applied
	{
		b_RoundEnd = true;
		RoundStartPrintDone = false;
		RoundsDone++;
		if (ScoreSystem == 1 && b_HandicapsApplied) // versus score system swapping, but only if handicaps are in use
		{
			RemoveHandicaps();
			TeamPlayingSurvivors = TeamSwap();
			AttemptApplyHandicaps();
		}
		else if (ScoreSystem == 2)
		{
			if(IsEvenRoundEnd(RoundsDone))
			{
				if (b_HandicapsApplied)
				{
					RemoveHandicaps();
				}
				UpdateScores();
				TeamPlayingSurvivors = FindSurvivorsScavengeMode();
				CalculateHandicaps();
				AttemptApplyHandicaps();
			}
			else if (b_HandicapsApplied) //2nd round of a set of two starting, teams will swap, but only do something if handicaps are running
			{
				RemoveHandicaps();
				TeamPlayingSurvivors = TeamSwap()
				AttemptApplyHandicaps();
			}

		}
		else if (ScoreSystem == 3)
		{
			if (IsEvenRoundEnd(RoundsDone)) //even round ended,team A will go survivors
			{
				TeamPlayingSurvivors = 1;
				TeamBTime = GameRules_GetPropFloat("m_flRoundDuration", 1);
				UpdateScores()
				if (b_HandicapsApplied) //Remove handicaps before recalculating them, otherwise we will get already handicapped values as new defaults
				{
					RemoveHandicaps();
				}
				CalculateHandicaps();
				AttemptApplyHandicaps();
			}
			else //Odd round ended, Team B Will go Survivors
			{
				TeamPlayingSurvivors = 2;
				TeamATime = GameRules_GetPropFloat("m_flRoundDuration", 0); //Store the current round time, it will get wiped on next round start
				if (b_HandicapsApplied) //If handicaps are not applied for the first round of a set of two, don't bother for the second round
				{
					RemoveHandicaps();
					AttemptApplyHandicaps();
				}
			}
		}
	}
	
}

public OnMapEnd()
{
	if (b_HandicapsApplied == true) ( RemoveHandicaps() )
}

public DisplayPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public Action:agd_cmd(client, args)
{
	if ((CvarShowToPlayers == 1 || CvarShowToPlayers == 3) && IsEnabled)
	{
		if (b_HandicapsApplied == true && client !=0 && IsActive)
		{
			if(h_DisplayPanel != INVALID_HANDLE) { CloseHandle(h_DisplayPanel); }
			h_DisplayPanel = CreatePanel();
			
			decl String:buffer[255];
			new Float:changepercent = CurrentHandicap * 100;
			Format(buffer, sizeof(buffer), "Agressive Director at %.1f%%", changepercent)
			DrawPanelText(h_DisplayPanel, buffer);
			DrawPanelText(h_DisplayPanel, "-------------------------------");
			new i = 0;
			do
			{
				if (CvarArray[i][ShowToPlayers] == 1 || CvarArray[i][ShowToPlayers] == 3)
				{
					if (CvarArray[i][Dynamic] == true)
					{
						if (CvarArray[i][IsTankCvar])
						{
							Format(buffer, sizeof(buffer), "%s: %i", PrintNames[i], RoundToNearest(GetConVarInt(CvarArray[i][CvarHandle]) * TankHealthMultiplier));
						}
						else
						{
							Format(buffer, sizeof(buffer), "%s: %i", PrintNames[i], GetConVarInt(CvarArray[i][CvarHandle]));
						}
						DrawPanelText(h_DisplayPanel, buffer);
					}
					else if (scoredifference > CvarArray[i][DifferenceNeeded] || (scoredifference > MaxScoreDiff && CvarArray[i][DifferenceNeeded] == -1))
					{
						if (CvarArray[i][IsTankCvar])
						{
							Format(buffer, sizeof(buffer), "%s: %i", PrintNames[i], RoundToNearest(GetConVarInt(CvarArray[i][CvarHandle]) * TankHealthMultiplier));
						}
						else
						{
							Format(buffer, sizeof(buffer), "%s: %i", PrintNames[i], GetConVarInt(CvarArray[i][CvarHandle]));
						}
						DrawPanelText(h_DisplayPanel, buffer);
					}
				}
				i++;
			}
			while (i < NumOfCvars)
			DrawPanelText(h_DisplayPanel, "-------------------------------");
			DrawPanelText (h_DisplayPanel,"Press a weapon slot key to close");
			SendPanelToClient (h_DisplayPanel, client, DisplayPanelHandler, 10);
		}
		else if(b_HandicapsApplied == false && client !=0 && IsActive)
		{
			PrintToChat(client, "Aggressive Director not currently active.");
		}
		else if (b_HandicapsApplied == true && CvarShowToPlayers >= 1 && IsActive)
		{
			PrintToServer("Current Aggressive director information:");
			new i = 0;
			do
			{
				if (CvarArray[i][ShowToPlayers] == 1 || CvarArray[i][ShowToPlayers] == 3)
				{
					if (CvarArray[i][Dynamic] == true)
					{
						PrintToServer("%s: %i", PrintNames[i], GetConVarInt(CvarArray[i][CvarHandle]));
					}
					else if (scoredifference > CvarArray[i][DifferenceNeeded] || (scoredifference > MaxScoreDiff && CvarArray[i][DifferenceNeeded] == -1))
					{
						PrintToServer("%s: %i", PrintNames[i], GetConVarInt(CvarArray[i][CvarHandle]));
					}
				}
				i++;
			}
			while (i < NumOfCvars)
		}
		else if(CvarShowToPlayers >= 1)
		{
			PrintToServer("Aggressive Director not currently active.");
		}
	}
	else if (CvarShowToPlayers != 2)
	{
		if (client == 0)
		{
			PrintToServer("Aggressive Director disabled");
		}
		else
		{
			PrintToChat(client,"Aggressive Director disabled");
		}
	}
}

//What type of score system to use 0 = coop random, 1 = versus point scoring, 2 = scavenge gascan scoring, 3 = survival timer scoring
UpdateScores()
{
	switch (ScoreSystem)
	{
		case -1: //Unknown game mode, no scoring system, eventually this should redirect to configurable game mode info.
		{
			TeamAScore = 0;
			TeamBScore = 0;
		}
		case 0:
		{
			CoopOrRealismScoring(); 
		}
		case 1:
		{
			VersusScoring();
		}
		case 2:
		{
			ScavengeScoring();
		}
		case 3:
		{
			SurvivalScoring();
		}
	}
	if (TeamAScore != TeamBScore)
	{
		IsActive = true;
	}
	else
	{
		IsActive = false;
	}
}

CoopOrRealismScoring() // Co op has no score system, so just add a random handicap that can go either way to spice things up a little.
{
	TeamAScore = CoopRealismMapsDone * CoopRealismMapPoints; //10% of the handicapper per sucessful map
	TeamBScore = 0;
}

VersusScoring() // Get current campaign scores
{
	TeamAScore = SDKCall(h_L4D_GetTeamScore, 1, true);
	TeamBScore = SDKCall(h_L4D_GetTeamScore, 2, true);
}

ScavengeScoring() // Get all scavenge round scores to avoid any issues with previous values changing
{
	new ScavengeScoresArray[2][5];
	ScavengeScoresArray[0][0] = GameRules_GetProp("m_iScavengeTeamScore", 4, 0);
	ScavengeScoresArray[1][0] = GameRules_GetProp("m_iScavengeTeamScore", 4, 1);
	ScavengeScoresArray[0][1] = GameRules_GetProp("m_iScavengeTeamScore", 4, 2);
	ScavengeScoresArray[1][1] = GameRules_GetProp("m_iScavengeTeamScore", 4, 3);
	ScavengeScoresArray[0][2] = GameRules_GetProp("m_iScavengeTeamScore", 4, 4);
	ScavengeScoresArray[1][2] = GameRules_GetProp("m_iScavengeTeamScore", 4, 5);
	ScavengeScoresArray[0][3] = GameRules_GetProp("m_iScavengeTeamScore", 4, 6);
	ScavengeScoresArray[1][3] = GameRules_GetProp("m_iScavengeTeamScore", 4, 7);
	ScavengeScoresArray[0][4] = GameRules_GetProp("m_iScavengeTeamScore", 4, 8);
	ScavengeScoresArray[1][4] = GameRules_GetProp("m_iScavengeTeamScore", 4, 9);
	TeamAScore = (ScavengeScoresArray[0][0] + ScavengeScoresArray[0][1] + ScavengeScoresArray[0][2] + ScavengeScoresArray[0][3] + ScavengeScoresArray[0][4]) * GasCanWeighting;
	TeamBScore = (ScavengeScoresArray[1][0] + ScavengeScoresArray[1][1] + ScavengeScoresArray[1][2] + ScavengeScoresArray[1][3] + ScavengeScoresArray[1][4]) * GasCanWeighting;
}

SurvivalScoring() // Get the round timers of both teams, use that with the weighted value to determine the score difference in points
{
	new Float:TimeDifference = TeamATime - TeamBTime
	if (TimeDifference < 0.0) //team b winning
	{
		TeamAScore = 0;
		TimeDifference = TimeDifference * -1.0;
		TeamBScore = RoundToNearest (TimeDifference * SurvivalSecondWeighting);
	}
	else if (TimeDifference > 0.0) //team a winning
	{
		TeamBScore = 0;
		TeamBScore = RoundToNearest (TimeDifference * SurvivalSecondWeighting);
	}
	else // Teams are tied
	{
		TeamAScore = 0;
		TeamBScore = 0;
	}
}

FindSurvivorsVSMode() //If teams are tied, it doesn't matter, so just return 0 (disabled)
{
	new bool:teamsflipped = L4D2_AreTeamsFlipped();
	if (TeamAScore == TeamBScore) // Are teams tied?
	{
		return 0; // Teams are tied, so just return 0
	}
	else if(teamsflipped == false)
	{
		return 1; // If teams are not flipped, then team A is survivors
	}
	else
	{
		return 2 // If teams have been flipped, then team B is survivors
	}
}

FindSurvivorsScavengeMode() // Get the last two rounds (the set that just ended) of gas can numbers to find out who won (they go infected first next round)
{
	new TeamACans = GameRules_GetProp("m_iScavengeTeamScore", 4, RoundsDone - 2);
	new TeamBCans = GameRules_GetProp("m_iScavengeTeamScore", 4, RoundsDone - 1);
	if (TeamACans > TeamBCans) 
	{
		return 2;// Team B lost, they go survivors first next set
	}
	else if (TeamACans < TeamBCans)
	{
		return 1;// Team A lost, they go survivors first next set
	}
	else //only other possible option for integers is to match, so look at the timers, longest timer wins
	{
		new Float:TeamATimer = GameRules_GetPropFloat("m_flRoundDuration", 0)
		new Float:TeamBTimer = GameRules_GetPropFloat("m_flRoundDuration", 1)
		if (TeamATimer > TeamBTimer) //Team B lost, they go survivors first next set
		{
			return 2;
		}
		else if (TeamATimer < TeamBTimer) // Team A lost, they go survivors first
		{
			return 1;
		}
		else //Teams are really truly tied, order of play will be Identical to previous set, so swap them
		{
			return TeamSwap()
		}
	}
}

TeamSwap()
{
	if (TeamPlayingSurvivors == 1)
	{
		return 2;
	}
	else if (TeamPlayingSurvivors == 2)
	{
		return 1;
	}
	return 0;
}

CalculateHandicaps()
{
	new i = 0, temp1, temp2;
	CurrentHandicap = 0.0
	scoredifference = TeamAScore - TeamBScore; //calculate score difference for handicap multiplier
	if (scoredifference < 0)
	{
		scoredifference = scoredifference * -1;
	}
	CurrentHandicap = FloatDiv(float(scoredifference), float(MaxScoreDiff));
	if (CurrentHandicap > HandicapLimit)
	{
		CurrentHandicap = HandicapLimit;
	}
	do // Store default values, and calculare changes
	{ 
		CvarArray[i][Default] = GetConVarInt(CvarArray[i][CvarHandle]);
		if (CvarArray[i][Dynamic] == true) // Only run these calculations for dynamic buffs
		{
			CvarArray[i][CurrentWin] = RoundToNearest(float(CvarArray[i][MaxWin]) * CurrentHandicap)
			if (CvarArray[i][WinBoundry] != 0)
			{
				temp1 = CvarArray[i][CurrentWin];
				temp2 = CvarArray[i][WinBoundry];
				if (temp1 < 0) { temp1 = temp1 * -1; }
				if (temp2 < 0){ temp2 = temp2 * -1; }
				if (temp1 > temp2) { CvarArray[i][CurrentWin] = CvarArray[i][WinBoundry]; }
			}
			CvarArray[i][CurrentLose] = RoundToNearest(float(CvarArray[i][MaxLose]) * CurrentHandicap)
			if (CvarArray[i][LoseBoundry] != 0)
			{
				temp1 = CvarArray[i][CurrentLose];
				temp2 = CvarArray[i][LoseBoundry];
				if (temp1 < 0) { temp1 = temp1 * -1; }
				if (temp2 < 0){ temp2 = temp2 * -1; }
				if (temp1 > temp2) { CvarArray[i][CurrentLose] = CvarArray[i][LoseBoundry]; }
			}
		}
		i++;
	}
	while (i < NumOfCvars)
}

AttemptApplyHandicaps() // Compare scores and current team playing survivors to ensure correct handicap applied to first team
{
	if (TeamAScore > TeamBScore && TeamPlayingSurvivors == 2 || TeamAScore < TeamBScore && TeamPlayingSurvivors == 1)
	{
		LosingTeamIsSurvivor()
	}
	else if (TeamAScore > TeamBScore && TeamPlayingSurvivors == 1 || TeamAScore < TeamBScore && TeamPlayingSurvivors == 2)
	{
		WinningTeamIsSurvivor()
	}
	//If neither of the above is true, then teams are tied, do nothing
}

WinningTeamIsSurvivor()
{
	new i = 0;
	do
	{
		if (CvarArray[i][Dynamic] == true)
		{
			SetConVarInt(CvarArray[i][CvarHandle], GetConVarInt(CvarArray[i][CvarHandle]) + CvarArray[i][CurrentWin]);
		}
		else if (scoredifference >= CvarArray[i][DifferenceNeeded]  || (scoredifference > MaxScoreDiff && CvarArray[i][DifferenceNeeded] == -1)) // is a static buff, so all or nothing
		{
			SetConVarInt(CvarArray[i][CvarHandle], GetConVarInt(CvarArray[i][CvarHandle]) + CvarArray[i][MaxWin]);
		}
		i++;
	}
	while (i < NumOfCvars);
	b_HandicapsApplied = true;
}

LosingTeamIsSurvivor()
{
	new i = 0;
	do
	{
		if (CvarArray[i][Dynamic] == true)
		{
			SetConVarInt(CvarArray[i][CvarHandle], GetConVarInt(CvarArray[i][CvarHandle]) + CvarArray[i][CurrentLose]);
		}
		else if (scoredifference >= CvarArray[i][DifferenceNeeded]  || (scoredifference > MaxScoreDiff && CvarArray[i][DifferenceNeeded] == -1))
		{
			SetConVarInt(CvarArray[i][CvarHandle], GetConVarInt(CvarArray[i][CvarHandle]) + CvarArray[i][MaxLose]);
		}
		i++;
	}
	while (i < NumOfCvars);
	b_HandicapsApplied = true;
}

RemoveHandicaps() // Remove all of the changes, set them back to their default values.
{
	new i = 0;
	do
	{
		SetConVarInt(CvarArray[i][CvarHandle],CvarArray[i][Default]);
		i++;
	}
	while (i < NumOfCvars);
	b_HandicapsApplied = false;
	
}

bool:L4D2_AreTeamsFlipped()
{
	new teamsflipped = GameRules_GetProp("m_bAreTeamsFlipped");
	if (teamsflipped == 1)
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool:EnabledGameMode()
{
	decl String:s_GameMode[32];
	GetConVarString(FindConVar("mp_gamemode"),s_GameMode,sizeof(s_GameMode));
	new i = 0;
	do
	{
		if (StrEqual(s_AllowedGameModes[i], s_GameMode, false))
		{
			return true;
		}
		i++;
	}
	while (i < NumAllowedGameModes);
	return false;
}

DetectScoreSystem()
{
	decl String:s_GameMode[32];
	GetConVarString(FindConVar("mp_gamemode"),s_GameMode,sizeof(s_GameMode));
	new L4D2GameMode:i = FindBaseGameMode(s_GameMode);
	switch (i)
	{
		case -1:  { return ExtraMutationLookup(s_GameMode); }// quick lookup failed, perform lookup of bigger list of mutations
		case 0: { return 0; }//coop scoring
		case 1: { return 0; }//realism, same as coop scoring
		case 2: { return 3; }//survival scoring
		case 3: { return 1; }//versus scoring
		case 4: { return 2; }//scavenge scoring
	}
	return -1; //Unknwon game mode, return -1, which means disabled
}

ExtraMutationLookup(String:s_GameMode[32])
{
	new scoretype = -1;
	if (GetTrieValue(h_MutationsTrie, s_GameMode, scoretype)) { return scoretype; }// If it is in the list, respond with score system to use
	return -1 //value not found, unsupported game mode
}

bool:IsEvenRoundEnd(num)
{
    return (num & 1) == 0;
}

public OnPluginEnd()
{
	if (b_HandicapsApplied == true)
	{
		RemoveHandicaps();
	}
}