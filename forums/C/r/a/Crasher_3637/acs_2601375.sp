#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <l4d2_mission_manager>

#define PLUGIN_VERSION	"v1.9.0"

//Define the wait time after round before changing to the next map in each game mode
#define WAIT_TIME_BEFORE_SWITCH_COOP			5.0
#define WAIT_TIME_BEFORE_SWITCH_VERSUS			5.0
#define WAIT_TIME_BEFORE_SWITCH_SCAVENGE		9.0
#define WAIT_TIME_BEFORE_SWITCH_SURVIVAL		5.0

//Define Game Modes
#define GAMEMODE_UNKNOWN	LMM_GAMEMODE_UNKNOWN
#define GAMEMODE_COOP 		LMM_GAMEMODE_COOP
#define GAMEMODE_VERSUS 	LMM_GAMEMODE_VERSUS
#define GAMEMODE_SCAVENGE 	LMM_GAMEMODE_SCAVENGE
#define GAMEMODE_SURVIVAL 	LMM_GAMEMODE_SURVIVAL

#define DISPLAY_MODE_DISABLED	0
#define DISPLAY_MODE_HINT		1
#define DISPLAY_MODE_CHAT		2
#define DISPLAY_MODE_MENU		3

#define SOUND_NEW_VOTE_START	"ui/Beep_SynthTone01.wav"
#define SOUND_NEW_VOTE_WINNER	"ui/alert_clink.wav"


//Global Variables
LMM_GAMEMODE g_iGameMode;			//Integer to store the gamemode
int g_iRoundEndCounter;				//Round end event counter for versus
int g_iCoopFinaleFailureCount;		//Number of times the Survivors have lost the current finale
bool g_bFinaleWon;				//Indicates whether a finale has be beaten or not

//Voting Variables					
bool g_bClientShownVoteAd[MAXPLAYERS + 1];				//If the client has seen the ad already
bool g_bClientVoted[MAXPLAYERS + 1];					//If the client has voted on a map
int g_iWinningMapVotes;									//Winning map/campaign's number of votes
// For Coop/Versus: missionIndex of the winning campaign
// For Scavenge/Survival: uniqueID of the winning map
int g_iClientVote[MAXPLAYERS + 1];						//The value of the clients vote
int g_iWinningMapIndex;									//Winning map/campaign's index

//Console Variables (CVars)
ConVar g_hCVar_VotingEnabled;			//Tells if the voting system is on	
ConVar g_hCVar_VoteWinnerSoundEnabled;	//Sound plays when vote winner changes
ConVar g_hCVar_VotingAdMode;			//The way to advertise the voting system
ConVar g_hCVar_VotingAdDelayTime;		//Time to wait before showing advertising			
ConVar g_hCVar_NextMapAdMode;			//The way to advertise the next map 
ConVar g_hCVar_NextMapAdInterval;		//Interval for ACS next map advertisement
ConVar g_hCVar_MaxFinaleFailures;		//Amount of times Survivors can fail before ACS switches in coop
ConVar g_hCVar_ChMapBroadcastInterval;	//The interval for advertising "!chmap"

Handle g_hTimer_Broadcast;

/*=========================================================
#########       Mission Cycle Data Storage        #########
=========================================================*/
#define LEN_CFG_LINE 256
#define LEN_CFG_SEGMENT 128
#define CHAR_CYCLE_SEPARATOR "// 3-rd maps(Do not delete/modify this line!)"

ArrayList g_hInt_MapIndexes[COUNT_LMM_GAMEMODE];
int g_int_CyclingCount[COUNT_LMM_GAMEMODE];

void ACS_InitLists() {
	for (int gamemode=0; gamemode<COUNT_LMM_GAMEMODE; gamemode++) {
		g_hInt_MapIndexes[gamemode] = new ArrayList(1);
		g_int_CyclingCount[gamemode] = 0;
	}
}

void ACS_FreeLists() {
	for (int gamemode=0; gamemode<COUNT_LMM_GAMEMODE; gamemode++) {
		delete g_hInt_MapIndexes[gamemode];
	}
}

ArrayList ACS_GetMissionIndexList(LMM_GAMEMODE gamemode) {
	return g_hInt_MapIndexes[view_as<int>(gamemode)];
}

void ACS_SetCyclingCount(LMM_GAMEMODE gamemode, int count) {
	g_int_CyclingCount[view_as<int>(gamemode)] = count;
}

// Used by the ACS
int ACS_GetCycledMissionCount(LMM_GAMEMODE gamemode) {
	return g_int_CyclingCount[view_as<int>(gamemode)];
}

int ACS_GetMissionCount(LMM_GAMEMODE gamemode){
	return ACS_GetMissionIndexList(gamemode).Length;
}


int ACS_GetMissionIndex(LMM_GAMEMODE gamemode, int cycleIndex) {
	ArrayList missionIndexList = ACS_GetMissionIndexList(gamemode);
	if (missionIndexList == null) {
		return -1;
	}
	
	return missionIndexList.Get(cycleIndex);
}

int ACS_GetFirstMapName(LMM_GAMEMODE gamemode, int cycleIndex, char[] mapname, int length){
	return LMM_GetMapName(gamemode, ACS_GetMissionIndex(gamemode, cycleIndex), 0, mapname, length);
}

int ACS_GetLastMapName(LMM_GAMEMODE gamemode, int cycleIndex, char[] mapname, int length){
	int iMission = ACS_GetMissionIndex(gamemode, cycleIndex);
	int mapCount = LMM_GetNumberOfMaps(gamemode, iMission);
	return LMM_GetMapName(gamemode, iMission, mapCount-1, mapname, length);
}

bool ACS_GetLocalizedMissionName(LMM_GAMEMODE gamemode, int cycleIndex, int client, char[] localizedName, int length) {
	ArrayList missionIndexList = ACS_GetMissionIndexList(gamemode);
	if (missionIndexList == null)
		return false;
	
	int missionIndex = missionIndexList.Get(cycleIndex);
	return LMM_GetMissionLocalizedName(gamemode, missionIndex, localizedName, length, client) > 0;
}

/*====================================================
#########       Mission Cycle Parsing        #########
====================================================*/
bool HasMissionCycleFile(LMM_GAMEMODE gamemode) {
	char path[PLATFORM_MAX_PATH];
	switch (gamemode) {
		case LMM_GAMEMODE_COOP: {
			BuildPath(Path_SM, path, sizeof(path), "configs/missioncycle.coop.txt");
		}
		case LMM_GAMEMODE_VERSUS: {
			BuildPath(Path_SM, path, sizeof(path), "configs/missioncycle.versus.txt");
		}
		case LMM_GAMEMODE_SCAVENGE: {
			BuildPath(Path_SM, path, sizeof(path), "configs/missioncycle.scavenge.txt");
		}
		case LMM_GAMEMODE_SURVIVAL: {
			BuildPath(Path_SM, path, sizeof(path), "configs/missioncycle.survival.txt");
		}
		default: {
			return false;
		}
	}
	
	return FileExists(path);
}

File OpenMissionCycleFile(LMM_GAMEMODE gamemode, const char[] mode) {
	char path[PLATFORM_MAX_PATH];
	switch (gamemode) {
		case LMM_GAMEMODE_COOP: {
			BuildPath(Path_SM, path, sizeof(path), "configs/missioncycle.coop.txt");
		}
		case LMM_GAMEMODE_VERSUS: {
			BuildPath(Path_SM, path, sizeof(path), "configs/missioncycle.versus.txt");
		}
		case LMM_GAMEMODE_SCAVENGE: {
			BuildPath(Path_SM, path, sizeof(path), "configs/missioncycle.scavenge.txt");
		}
		case LMM_GAMEMODE_SURVIVAL: {
			BuildPath(Path_SM, path, sizeof(path), "configs/missioncycle.survival.txt");
		}
		default: {
			return null;
		}
	}
	
	return OpenFile(path, mode);
}

void PopulateDefaultMissionCycle(LMM_GAMEMODE gamemode, File missionCycleFile) {
	switch (gamemode) {
		case LMM_GAMEMODE_COOP, LMM_GAMEMODE_VERSUS: {
			missionCycleFile.WriteLine("L4D2C1");
			missionCycleFile.WriteLine("L4D2C2");
			missionCycleFile.WriteLine("L4D2C3");
			missionCycleFile.WriteLine("L4D2C4");
			missionCycleFile.WriteLine("L4D2C5");
			missionCycleFile.WriteLine("L4D2C6");
			missionCycleFile.WriteLine("L4D2C7");
			missionCycleFile.WriteLine("L4D2C8");
			missionCycleFile.WriteLine("L4D2C9");
			missionCycleFile.WriteLine("L4D2C10");
			missionCycleFile.WriteLine("L4D2C11");
			missionCycleFile.WriteLine("L4D2C12");
			missionCycleFile.WriteLine("L4D2C13");
		}
		case LMM_GAMEMODE_SCAVENGE: {
			missionCycleFile.WriteLine("L4D2C1");
			missionCycleFile.WriteLine("L4D2C2");
			missionCycleFile.WriteLine("L4D2C3");
			missionCycleFile.WriteLine("L4D2C4");
			missionCycleFile.WriteLine("L4D2C5");
			missionCycleFile.WriteLine("L4D2C6");
			missionCycleFile.WriteLine("L4D2C7");
			missionCycleFile.WriteLine("L4D2C8");
			missionCycleFile.WriteLine("L4D2C10");
			missionCycleFile.WriteLine("L4D2C11");
			missionCycleFile.WriteLine("L4D2C12");
		}
		case LMM_GAMEMODE_SURVIVAL: {
			missionCycleFile.WriteLine("L4D2C1");
			missionCycleFile.WriteLine("L4D2C2");
			missionCycleFile.WriteLine("L4D2C3");
			missionCycleFile.WriteLine("L4D2C4");
			missionCycleFile.WriteLine("L4D2C5");
			missionCycleFile.WriteLine("L4D2C6");
			missionCycleFile.WriteLine("L4D2C7");
			missionCycleFile.WriteLine("L4D2C8");
		}
	}
}

void LoadMissionList(LMM_GAMEMODE gamemode) {
	ArrayList missionIndexList = ACS_GetMissionIndexList(gamemode);

	char buffer[LEN_CFG_LINE];
	char buffer_split[3][LEN_CFG_SEGMENT];
	File missionCycleFile;
	char missionName[LEN_MISSION_NAME];
	char gamemodeName[LEN_GAMEMODE_NAME];
	LMM_GamemodeToString(gamemode, gamemodeName, sizeof(gamemodeName));
	
	// Create default mission cycle file if not existed yet
	if (!HasMissionCycleFile(gamemode)){
		missionCycleFile = OpenMissionCycleFile(gamemode, "w+");
		missionCycleFile.WriteLine("// Do not delete this line! format: <Mission Name(see txt files in missions.cache folder)>");
		PopulateDefaultMissionCycle(gamemode, missionCycleFile);
		missionCycleFile.WriteLine(CHAR_CYCLE_SEPARATOR);
		delete missionCycleFile;
	}
	
	missionCycleFile = OpenMissionCycleFile(gamemode, "r");
	missionCycleFile.ReadLine(buffer, sizeof(buffer));
	while(!missionCycleFile.EndOfFile() && missionCycleFile.ReadLine(buffer, sizeof(buffer))) {
		ReplaceString(buffer, sizeof(buffer), "\n", "");
		TrimString(buffer);
		if (StrContains(buffer, "//") == 0) {
			if (StrContains(buffer, CHAR_CYCLE_SEPARATOR) == 0) {
				ACS_SetCyclingCount(gamemode, missionIndexList.Length);
			}

			// Ignore comments
		} else {
			int numOfStrings = ExplodeString(buffer, ",", buffer_split, LEN_CFG_LINE, LEN_CFG_SEGMENT);
			TrimString(buffer_split[0]);	// Mission name
			if (numOfStrings > 1) {
				// For future use
			}
			
			int iMission = LMM_FindMissionIndexByName(gamemode, buffer_split[0]);
			if (iMission >= 0) {	// The mission is valid
				missionIndexList.Push(iMission);
			} else {
				LogError("Mission \"%s\" (Gamemode: %s) is not in the mission cache or no longer exists!\n", buffer_split[0], gamemodeName);
			}
		}
	}
	delete missionCycleFile;
	
	// Missions in missionIndexList are in the cyclic order and all valid
	// But l4d2_mission_manager may have some new missions
	// Then append new missions to the end of mission cycle and store the new mission cycle!
	missionCycleFile = OpenMissionCycleFile(gamemode, "a");
	for (int iMission=0; iMission<LMM_GetNumberOfMissions(gamemode); iMission++) {
		if (missionIndexList.FindValue(iMission) < 0) {
			// Found a new mission
			LMM_GetMissionName(gamemode, iMission, missionName, sizeof(missionName));
			LogMessage("Found new %s mission \"%s\" !", gamemodeName, missionName);
			missionCycleFile.WriteLine(missionName);
		}
	}
	
	delete missionCycleFile;
	// Mission list is complete and finalized
}

void DumpMissionInfo(int client, LMM_GAMEMODE gamemode) {
	char gamemodeName[LEN_GAMEMODE_NAME];
	LMM_GamemodeToString(gamemode, gamemodeName, sizeof(gamemodeName));

	ArrayList missionIndexList = ACS_GetMissionIndexList(gamemode);
	int missionCount = ACS_GetMissionCount(gamemode);
	
	char missionName[LEN_MISSION_NAME];
	char firstMap[LEN_MAP_FILENAME];
	char lastMap[LEN_MAP_FILENAME];
	char localizedName[LEN_MISSION_NAME];

	ReplyToCommand(client, "Gamemode = %s (%d missions, %d in cycle)", gamemodeName, missionCount, ACS_GetCycledMissionCount(gamemode));

	for (int cycleIndex=0; cycleIndex<missionCount; cycleIndex++) {
		int iMission = missionIndexList.Get(cycleIndex);
		int mapCount = LMM_GetNumberOfMaps(gamemode, iMission);
		LMM_GetMissionName(gamemode, iMission, missionName, sizeof(missionName));
		ACS_GetFirstMapName(gamemode, cycleIndex, firstMap, sizeof(firstMap));
		ACS_GetLastMapName(gamemode, cycleIndex, lastMap, sizeof(lastMap));
		if (ACS_GetLocalizedMissionName(gamemode, cycleIndex, client, localizedName, sizeof(localizedName))) {
			ReplyToCommand(client, "%d.%s (%s) = %s -> %s (%d maps)", cycleIndex+1 , localizedName, missionName, firstMap, lastMap, mapCount);
		} else {
			ReplyToCommand(client, "%d.%s <Missing localization> = %s -> %s (%d maps)", cycleIndex+1, missionName, firstMap, lastMap, mapCount);
		}
	}
	ReplyToCommand(client, "-------------------");
}

/*===========================================
#########       Menu Systems        #########
===========================================*/
#define MMC_ITEM_LEN_INFO 16
#define MMC_ITEM_LEN_NAME 16
#define MMC_ITEM_IDONTCARE_TEXT "I dont care"
#define MMC_ITEM_ALLMAPS_TEXT "All maps"
#define MMC_ITEM_MISSION_TEXT "Mission"
#define MMC_ITEM_MAP_TEXT "Map"
bool ShowMissionChooser(int iClient, bool isMap, bool isVote) {
	if(iClient < 1 || IsClientInGame(iClient) == false || IsFakeClient(iClient) == true)
		return false;
	
	//Create the menu
	Menu chooser = CreateMenu(MissionChooserMenuHandler, MenuAction_Select | MenuAction_DisplayItem | MenuAction_End);
		
	if (isMap) {
		chooser.SetTitle("%T", "Choose a Map", iClient);
		if (isVote) {
			chooser.AddItem(MMC_ITEM_IDONTCARE_TEXT, "N/A");
		}
		chooser.AddItem(MMC_ITEM_ALLMAPS_TEXT, "N/A");
	} else {
		chooser.SetTitle("%T", "Choose a Mission", iClient);
		if (isVote) {
			chooser.AddItem(MMC_ITEM_IDONTCARE_TEXT, "N/A");
		}
	}
	
	char menuName[20];
	for(int cycleIndex = 0; cycleIndex < ACS_GetMissionCount(g_iGameMode); cycleIndex++) {
		IntToString(cycleIndex, menuName, sizeof(menuName));
		chooser.AddItem(MMC_ITEM_MISSION_TEXT, menuName);
	}
	
	//Add an exit button
	chooser.ExitButton = true;
	
	//And finally, show the menu to the client
	chooser.Display(iClient, MENU_TIME_FOREVER);
		
	return true;	
}

public int MissionChooserMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_End) {
		delete menu;
		return 0;
	}
	
	char menuInfo[MMC_ITEM_LEN_INFO];
	char menuName[MMC_ITEM_LEN_NAME];
	char localizedName[LEN_LOCALIZED_NAME];
	
	// Change the map to the selected item.
	if(action == MenuAction_Select)	{
		if (item < 0) { // Not a valid map option
			return 0;
		}

		// Find out the current menu mode
		menu.GetItem(0, menuInfo, sizeof(menuInfo));
		if (StrEqual(menuInfo, MMC_ITEM_IDONTCARE_TEXT, false)) {
			// Voting mode
			if (item == 0) {
				// "I dont care" is selected
				VoteMenuHandler(client, true, -1, -1);
				//PrintToServer("\"I dont care\" is selected");
				return 0;
			} else {
				// Other vote mode menu items
				menu.GetItem(1, menuInfo, sizeof(menuInfo));
				if (StrEqual(menuInfo, MMC_ITEM_ALLMAPS_TEXT, false)) {
					// Voting for a map
					if (item == 1) {
						// "All map" is selected, prepare map list for all missions
						ShowMapChooser(client, true, -1);
					} else {
						// A mission is selected, prepare a map list for the selected mission
						menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
						int cycleIndex = StringToInt(menuName);
						ShowMapChooser(client, true, cycleIndex);	
					}
				} else {
					// Voting for a mission
					menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
					int cycleIndex = StringToInt(menuName);
					int missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
					VoteMenuHandler(client, false, missionIndex, -1);
					
					//ACS_GetLocalizedMissionName(g_iGameMode, cycleIndex, client, localizedName, sizeof(localizedName));
					//PrintToServer("ACS: a mission \"%s\" is chosen", localizedName);					
				}
			}
		} else {
			// Chmap mode
			if (StrEqual(menuInfo, MMC_ITEM_ALLMAPS_TEXT, false)) {
				if (item == 0) {
					// "All map" is selected, prepare map list for all missions
					ShowMapChooser(client, false, -1);
				} else {
					// A mission is selected, prepare a map list for the selected mission
					menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
					int cycleIndex = StringToInt(menuName);
					ShowMapChooser(client, false, cycleIndex);
				}
				// Browse map list
			} else {
				if (IsVoteInProgress()) {
					ReplyToCommand(client, "\x03[ACS]\x04 %t", "Vote in Progress");
					return 0;
				}
			
				// A mission is chosen
				menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
				int cycleIndex = StringToInt(menuName);
				ShowChmapVoteToAll(ACS_GetMissionIndex(g_iGameMode, cycleIndex), -1);
			}
		}
		
	} else if (action == MenuAction_DisplayItem) {
		menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
		if (StrEqual(menuInfo, MMC_ITEM_MISSION_TEXT, false)) {
			int cycleIndex = StringToInt(menuName);
			// Localize mission name
			ACS_GetLocalizedMissionName(g_iGameMode, cycleIndex, client, localizedName, sizeof(localizedName));		
		} else {
			// Localize other menu items
			Format(localizedName, sizeof(localizedName), "%T", menuInfo, client);
		}
		RedrawMenuItem(localizedName);
	}
	
	return 0;
}

bool ShowMapChooser(int iClient, bool isVote, int cycleIndex) {
	if(iClient < 1 || IsClientInGame(iClient) == false || IsFakeClient(iClient) == true)
		return false;
	
	int flags = isVote ? 1 : 0;
	char menuInfo[MMC_ITEM_LEN_INFO];
	IntToString(flags, menuInfo, sizeof(menuInfo));	// Use menu info to store the status of isVote
	
	//Create the menu
	Menu chooser = CreateMenu(MapChooserMenuHandler, MenuAction_Select | MenuAction_DisplayItem | MenuAction_End | MenuAction_Cancel);
	chooser.SetTitle("%T", "Choose a Map", iClient);
	
	char menuName[MMC_ITEM_LEN_NAME];
	if (cycleIndex < 0) {
		// Show all maps at once
		for (cycleIndex = 0; cycleIndex<ACS_GetMissionCount(g_iGameMode); cycleIndex++) {
			int missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
			for (int mapIndex=0; mapIndex<LMM_GetNumberOfMaps(g_iGameMode, missionIndex); mapIndex++) {
				Format(menuName, sizeof(menuName), "%d,%d", missionIndex, mapIndex);
				chooser.AddItem(menuInfo, menuName);
			}			
		}
	} else {
		int missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
		for (int mapIndex=0; mapIndex<LMM_GetNumberOfMaps(g_iGameMode, missionIndex); mapIndex++) {
			Format(menuName, sizeof(menuName), "%d,%d", missionIndex, mapIndex);
			chooser.AddItem(menuInfo, menuName);
		}
	}
	
	//Add an exitBack button
	chooser.ExitBackButton = true;
	
	//And finally, show the menu to the client
	chooser.Display(iClient, MENU_TIME_FOREVER);
	
	//Play a sound to indicate that the user can vote on a map
	EmitSoundToClient(iClient, SOUND_NEW_VOTE_START);
	
	return true;	
}

public int MapChooserMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_End) {
		delete menu;
		return 0;
	}
	
	char menuInfo[MMC_ITEM_LEN_INFO];
	char menuName[MMC_ITEM_LEN_NAME];
	char localizedName[LEN_LOCALIZED_NAME];

	char buffer_split[3][MMC_ITEM_LEN_NAME];
	
	if (action == MenuAction_Cancel) {
		if (item == MenuCancel_ExitBack) {
			// Open main menu
			menu.GetItem(0, menuInfo, sizeof(menuInfo));
			ShowMissionChooser(client, true, StrEqual(menuInfo, "1", false));
		}
	} else if (action == MenuAction_DisplayItem) {
		menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
		ExplodeString(menuName, ",", buffer_split, 3, MMC_ITEM_LEN_NAME);
		int missionIndex = StringToInt(buffer_split[0]);
		int mapIndex = StringToInt(buffer_split[1]);
		LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
		RedrawMenuItem(localizedName);
	} else if (action == MenuAction_Select)	{
		if (item < 0) { // Not a valid map option
			return 0;
		}
		
		if (IsVoteInProgress()) {
			ReplyToCommand(client, "\x03[ACS]\x04 %t", "Vote in Progress");
			return 0;
		}
		
		menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
		ExplodeString(menuName, ",", buffer_split, 3, MMC_ITEM_LEN_NAME);
		int missionIndex = StringToInt(buffer_split[0]);
		int mapIndex = StringToInt(buffer_split[1]);	

		if (StrEqual(menuInfo, "1", false)) {
			// Vote mode
			VoteMenuHandler(client, false, missionIndex, mapIndex);
		} else {
			// Chmap mode
			ShowChmapVoteToAll(missionIndex, mapIndex);
		}
	}
	return 0;
}

bool ShowChmapVoteToAll(int missionIndex, int mapIndex) {
	Menu menuVote = CreateMenu(ChampVoteHandler, MENU_ACTIONS_ALL);
	
	menuVote.SetTitle("To be translated");
	char menuInfo[MMC_ITEM_LEN_INFO];
	IntToString(missionIndex, menuInfo, sizeof(menuInfo));
	menuVote.AddItem(menuInfo, "Yes");
	IntToString(mapIndex, menuInfo, sizeof(menuInfo));	
	menuVote.AddItem(menuInfo, "No");
	menuVote.ExitButton = false;
	menuVote.DisplayVoteToAll(MENU_TIME_FOREVER);
}

public int ChampVoteHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Display) {
		// Localize title
		char localizedName[LEN_LOCALIZED_NAME];
		char menuInfo[MMC_ITEM_LEN_INFO];
		menu.GetItem(0, menuInfo, sizeof(menuInfo));
		int missionIndex = StringToInt(menuInfo);
		menu.GetItem(1, menuInfo, sizeof(menuInfo));
		int mapIndex = StringToInt(menuInfo);

		if (mapIndex < 0) {
			LMM_GetMissionLocalizedName(g_iGameMode, missionIndex, localizedName, sizeof(localizedName), param1);
		} else {
			LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), param1);
		}
		
	 	char buffer[255];
		Format(buffer, sizeof(buffer), "%T", "Change Map To", param1, localizedName);
		Panel panel = view_as<Panel>(param2);
		panel.SetTitle(buffer);
	} else if (action == MenuAction_DisplayItem) {
		char menuName[MMC_ITEM_LEN_NAME];
		char buffer[MMC_ITEM_LEN_NAME];
		menu.GetItem(param2, "", 0, _, menuName, sizeof(menuName));
		Format(buffer, sizeof(buffer), "%T", menuName, param1);	// param1 = clientIndex
	 	RedrawMenuItem(buffer);
	} else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes) {
		PrintToChatAll("\x03[ACS]\x04 %t", "No Votes Cast");
	} else if (action == MenuAction_VoteEnd) {
		// param1: The chosen item, param2: vote result
		float percent, limit;
		int votes, totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		
		if (param1 == 1) {
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = float(votes) / float(totalVotes);
		
		ConVar limitConVar = FindConVar("sm_vote_map");
		if (limitConVar == null) {
			limit = 0.6;
		} else {
			limit = limitConVar.FloatValue;
		}
		
		// A multi-argument vote is "always successful", but have to check if its a Yes/No vote.
		if (param1 == 1) {
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("\x03[ACS]\x04 %t", "Vote Failed", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		} else {
			PrintToChatAll("\x03[ACS]\x04 %t", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);
			
			char menuInfo[MMC_ITEM_LEN_INFO];
			menu.GetItem(0, menuInfo, sizeof(menuInfo));
			int missionIndex = StringToInt(menuInfo);
			menu.GetItem(1, menuInfo, sizeof(menuInfo));
			int mapIndex = StringToInt(menuInfo);

			char colorizedName[LEN_MISSION_NAME];
			char localizedName[LEN_MISSION_NAME];
			char mapName[LEN_MAP_FILENAME];
			if (mapIndex < 0) {
				// Vote for mission, switch to its first map
				LMM_GetMapName(g_iGameMode, missionIndex, 0, mapName, sizeof(mapName));
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client)) {
						LMM_GetMissionLocalizedName(g_iGameMode, missionIndex, localizedName, sizeof(localizedName), client);
						Format(colorizedName, sizeof(colorizedName), "\x04%s\x01", localizedName);
						PrintToChat(client,"\x03[ACS]\x01 %t\x01", "Mission is now winning the vote", colorizedName);
					}
				}			
			} else {
				// Vote for a map, switch to that map
				LMM_GetMapName(g_iGameMode, missionIndex, mapIndex, mapName, sizeof(mapName));
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client)) {
						LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
						Format(colorizedName, sizeof(colorizedName), "\x04%s\x01", localizedName);
						PrintToChat(client,"\x03[ACS]\x01 %t", "Map is now winning the vote", colorizedName);
					}
				}
			}
			
			Format(colorizedName, sizeof(colorizedName), "\x04%s\x01", mapName);
			PrintToChatAll("\x03[ACS]\x01 %t", "Changing map", colorizedName);
			CreateChangeMapTimer(mapName);
		}
	} else if (action == MenuAction_End) {
		delete menu;
	}
	
	return 0;
}

void CreateChangeMapTimer(const char[] mapName) {
	float delay = 5.0;
	switch (g_iGameMode) {
		case LMM_GAMEMODE_COOP: {delay=WAIT_TIME_BEFORE_SWITCH_COOP;}
		case LMM_GAMEMODE_VERSUS: {delay=WAIT_TIME_BEFORE_SWITCH_VERSUS;}
		case LMM_GAMEMODE_SCAVENGE: {delay=WAIT_TIME_BEFORE_SWITCH_SCAVENGE;}
		case LMM_GAMEMODE_SURVIVAL: {delay=WAIT_TIME_BEFORE_SWITCH_SURVIVAL;}
	}
	
	DataPack dp;
	CreateDataTimer(delay, Timer_ChangeMap, dp);
	dp.WriteString(mapName);
}

public Action Timer_ChangeMap(Handle timer, DataPack dp) {
	char mapName[LEN_MAP_FILENAME];
	
	dp.Reset();
	dp.ReadString(mapName, sizeof(mapName));
	
	ForceChangeLevel(mapName, "sm_votemap Result");
	
	return Plugin_Stop;
}

public void OnAllPluginsLoaded() {
	if (!LibraryExists("l4d2_mission_manager")) {
		SetFailState("l4d2_mission_manager was not found.");
	}
	
	ACS_InitLists();
	LoadMissionList(LMM_GAMEMODE_COOP);
	LoadMissionList(LMM_GAMEMODE_VERSUS);
	LoadMissionList(LMM_GAMEMODE_SCAVENGE);
	LoadMissionList(LMM_GAMEMODE_SURVIVAL);
	
	DumpMissionInfo(0, LMM_GAMEMODE_COOP);
	DumpMissionInfo(0, LMM_GAMEMODE_VERSUS);
	DumpMissionInfo(0, LMM_GAMEMODE_SCAVENGE);
	DumpMissionInfo(0, LMM_GAMEMODE_SURVIVAL);
}

public void OnPluginEnd() {
	ACS_FreeLists();
}

/*======================================================================================
#####################             P L U G I N   I N F O             ####################
======================================================================================*/

public Plugin myinfo = {
	name = "Automatic Campaign Switcher (ACS)",
	author = "Rikka0w0, Chris Pringle",
	description = "Automatically switches to the next campaign when the previous campaign is over",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=308708"
}

/*======================================================================================
#################             O N   P L U G I N   S T A R T            #################
======================================================================================*/

public void OnPluginStart() {
	LoadTranslations("acs.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("basevotes.phrases");
	
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false)) {
		SetFailState("Use this in Left 4 Dead or Left 4 Dead 2 only.");
	}
	
	//Create custom console variables
	CreateConVar("acs_version", PLUGIN_VERSION, "Version of Automatic Campaign Switcher (ACS) on this server", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCVar_VotingEnabled = CreateConVar("acs_voting_system_enabled", "1", "Enables players to vote for the next map or campaign [0 = DISABLED, 1 = ENABLED]", _, true, 0.0, true, 1.0);
	g_hCVar_VoteWinnerSoundEnabled = CreateConVar("acs_voting_sound_enabled", "1", "Determines if a sound plays when a new map is winning the vote [0 = DISABLED, 1 = ENABLED]", _, true, 0.0, true, 1.0);
	g_hCVar_VotingAdMode = CreateConVar("acs_voting_ad_mode", "3", "Sets how to advertise voting at the start of the map [0 = DISABLED, 1 = HINT TEXT, 2 = CHAT TEXT, 3 = OPEN VOTE MENU]\n * Note: This is only displayed once during a finale or scavenge map *", _, true, 0.0, true, 3.0);
	g_hCVar_VotingAdDelayTime = CreateConVar("acs_voting_ad_delay_time", "10.0", "Time, in seconds, to wait after survivors leave the start area to advertise voting as defined in acs_voting_ad_mode\n * Note: If the server is up, changing this in the .cfg file takes two map changes before the change takes place *", _, true, 0.1, false);
	g_hCVar_NextMapAdMode = CreateConVar("acs_next_map_ad_mode", "2", "Sets how the next campaign/map is advertised during a finale or scavenge map [0 = DISABLED, 1 = HINT TEXT, 2 = CHAT TEXT]", _, true, 0.0, true, 2.0);
	g_hCVar_NextMapAdInterval = CreateConVar("acs_next_map_ad_interval", "60.0", "The time, in seconds, between advertisements for the next campaign/map on finales and scavenge maps", _, true, 60.0, false);
	g_hCVar_MaxFinaleFailures = CreateConVar("acs_max_coop_finale_failures", "0", "The amount of times the survivors can fail a finale in Coop before it switches to the next campaign [0 = INFINITE FAILURES]", _, true, 0.0, false);
	g_hCVar_ChMapBroadcastInterval =  CreateConVar("acs_chmap_broadcast_interval", "180.0", "controls the frequency of the \"!chmap\" advertisement, in second.");	
	
	//Hook console variable changes
	HookConVarChange(g_hCVar_VotingEnabled, CVarChange_Voting);
	HookConVarChange(g_hCVar_VoteWinnerSoundEnabled, CVarChange_NewVoteWinnerSound);
	HookConVarChange(g_hCVar_VotingAdMode, CVarChange_VotingAdMode);
	HookConVarChange(g_hCVar_VotingAdDelayTime, CVarChange_VotingAdDelayTime);
	HookConVarChange(g_hCVar_NextMapAdMode, CVarChange_NewMapAdMode);
	HookConVarChange(g_hCVar_NextMapAdInterval, CVarChange_NewMapAdInterval);
	HookConVarChange(g_hCVar_MaxFinaleFailures, CVarChange_MaxFinaleFailures);
	HookConVarChange(g_hCVar_ChMapBroadcastInterval, CVarChange_ChMapBroadcast);
	
	AutoExecConfig(true, "acs");
	
	//Hook the game events
	//HookEvent("round_start", Event_RoundStart);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinaleWin);
	HookEvent("scavenge_match_finished", Event_ScavengeMapFinished);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	//Register custom console commands
	RegConsoleCmd("mapvote", MapVote);
	RegConsoleCmd("mapvotes", DisplayCurrentVotes);
	RegConsoleCmd("sm_chmap", Command_ChangeMapVote);
	RegConsoleCmd("sm_chmap2", Command_ChangeMapVote2);
	//RegConsoleCmd("sm_acs_maps", Command_MapList);
}

public Action Command_ChangeMapVote(int iClient, int args) {
	ShowMissionChooser(iClient, (g_iGameMode == GAMEMODE_SCAVENGE || g_iGameMode == GAMEMODE_SURVIVAL), false);
	
	//Play a sound to indicate that the user can vote on a map
	EmitSoundToClient(iClient, SOUND_NEW_VOTE_START);
}

public Action Command_ChangeMapVote2(int iClient, int args) {
	ShowMissionChooser(iClient, true, false);

	//Play a sound to indicate that the user can vote on a map
	EmitSoundToClient(iClient, SOUND_NEW_VOTE_START);	
}

public void OnConfigsExecuted() {
	MakeChMapBroadcastTimer();
}

void MakeChMapBroadcastTimer() {
	if (g_hTimer_Broadcast != null) {
		KillTimer(g_hTimer_Broadcast);
		g_hTimer_Broadcast = null;
	}

	if(g_hCVar_ChMapBroadcastInterval.FloatValue > 0)
		g_hTimer_Broadcast = CreateTimer(g_hCVar_ChMapBroadcastInterval.FloatValue, Timer_WelcomeMessage, INVALID_HANDLE, TIMER_REPEAT);
}

public Action Timer_WelcomeMessage(Handle timer, any param) {
	PrintToChatAll("\x03[ACS]\x01 %t", "Change map advertise", "\x04!chmap\x01");
}

/*======================================================================================
##########           C V A R   C A L L B A C K   F U N C T I O N S           ###########
======================================================================================*/
public void CVarChange_ChMapBroadcast(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	MakeChMapBroadcastTimer();
}

//Callback function for the cvar for voting system
public void CVarChange_Voting(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	if (StringToInt(strNewValue) == 1) {
		PrintToServer("[ACS] ConVar changed: Voting System ENABLED");
		PrintToChatAll("[ACS] ConVar changed: Voting System ENABLED");
	} else {
		PrintToServer("[ACS] ConVar changed: Voting System DISABLED");
		PrintToChatAll("[ACS] ConVar changed: Voting System DISABLED");
	}
}

//Callback function for enabling or disabling the new vote winner sound
public void CVarChange_NewVoteWinnerSound(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	if (StringToInt(strNewValue) == 1) {
		PrintToServer("[ACS] ConVar changed: New vote winner sound ENABLED");
		PrintToChatAll("[ACS] ConVar changed: New vote winner sound ENABLED");
	} else {
		PrintToServer("[ACS] ConVar changed: New vote winner sound DISABLED");
		PrintToChatAll("[ACS] ConVar changed: New vote winner sound DISABLED");
	}
}

//Callback function for how the voting system is advertised to the players at the beginning of the round
public void CVarChange_VotingAdMode(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	switch(StringToInt(strNewValue)) {
		case 0:	{
			PrintToServer("[ACS] ConVar changed: Voting display mode: DISABLED");
			PrintToChatAll("[ACS] ConVar changed: Voting display mode: DISABLED");
		}
		case 1:	{
			PrintToServer("[ACS] ConVar changed: Voting display mode: HINT TEXT");
			PrintToChatAll("[ACS] ConVar changed: Voting display mode: HINT TEXT");
		}
		case 2:	{
			PrintToServer("[ACS] ConVar changed: Voting display mode: CHAT TEXT");
			PrintToChatAll("[ACS] ConVar changed: Voting display mode: CHAT TEXT");
		}
		case 3:	{
			PrintToServer("[ACS] ConVar changed: Voting display mode: OPEN VOTE MENU");
			PrintToChatAll("[ACS] ConVar changed: Voting display mode: OPEN VOTE MENU");
		}
	}
}

//Callback function for the cvar for voting display delay time
public void CVarChange_VotingAdDelayTime(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//Get the new value
	float fDelayTime = StringToFloat(strNewValue);
	
	//If the value was changed, then set it and display a message to the server and players
	if (fDelayTime > 0.1)
	{
		PrintToServer("[ACS] ConVar changed: Voting advertisement delay time changed to %f", fDelayTime);
		PrintToChatAll("[ACS] ConVar changed: Voting advertisement delay time changed to %f", fDelayTime);
	}
	else
	{
		PrintToServer("[ACS] ConVar changed: Voting advertisement delay time changed to 0.1");
		PrintToChatAll("[ACS] ConVar changed: Voting advertisement delay time changed to 0.1");
	}
}

//Callback function for how ACS and the next map is advertised to the players during a finale
public void CVarChange_NewMapAdMode(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	switch(StringToInt(strNewValue)) {
		case 0:	{
			PrintToServer("[ACS] ConVar changed: Next map advertisement display mode: DISABLED");
			PrintToChatAll("[ACS] ConVar changed: Next map advertisement display mode: DISABLED");
		}
		case 1:	{
			PrintToServer("[ACS] ConVar changed: Next map advertisement display mode: HINT TEXT");
			PrintToChatAll("[ACS] ConVar changed: Next map advertisement display mode: HINT TEXT");
		}
		case 2:	{
			PrintToServer("[ACS] ConVar changed: Next map advertisement display mode: CHAT TEXT");
			PrintToChatAll("[ACS] ConVar changed: Next map advertisement display mode: CHAT TEXT");
		}
	}
}

//Callback function for the interval that controls the timer that advertises ACS and the next map
public void CVarChange_NewMapAdInterval(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//Get the new value
	float fDelayTime = StringToFloat(strNewValue);
	
	//If the value was changed, then set it and display a message to the server and players
	if (fDelayTime > 60.0) {
		PrintToServer("[ACS] ConVar changed: Next map advertisement interval changed to %f", fDelayTime);
		PrintToChatAll("[ACS] ConVar changed: Next map advertisement interval changed to %f", fDelayTime);
	} else {
		PrintToServer("[ACS] ConVar changed: Next map advertisement interval changed to 60.0");
		PrintToChatAll("[ACS] ConVar changed: Next map advertisement interval changed to 60.0");
	}
}

//Callback function for the amount of times the survivors can fail a coop finale map before ACS switches
public void CVarChange_MaxFinaleFailures(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//Get the new value
	int iMaxFailures = StringToInt(strNewValue);
	
	//If the value was changed, then set it and display a message to the server and players
	if (iMaxFailures > 0) {
		PrintToServer("[ACS] ConVar changed: Max Coop finale failures changed to %f", iMaxFailures);
		PrintToChatAll("[ACS] ConVar changed: Max Coop finale failures changed to %f", iMaxFailures);
	} else {
		PrintToServer("[ACS] ConVar changed: Max Coop finale failures changed to 0");
		PrintToChatAll("[ACS] ConVar changed: Max Coop finale failures changed to 0");
	}
}
/*======================================================================================
#################                     E V E N T S                      #################
======================================================================================*/

public void OnMapStart() {	
	//Set the game mode
	g_iGameMode = LMM_GetCurrentGameMode();
	
	//Precache sounds
	PrecacheSound(SOUND_NEW_VOTE_START);
	PrecacheSound(SOUND_NEW_VOTE_WINNER);
	
	
	//Display advertising for the next campaign or map
	if(g_hCVar_NextMapAdMode.IntValue != DISPLAY_MODE_DISABLED)
		CreateTimer(g_hCVar_NextMapAdInterval.FloatValue, Timer_AdvertiseNextMap, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_iRoundEndCounter = 0;			//Reset the round end counter on every map start
	g_iCoopFinaleFailureCount = 0;	//Reset the amount of Survivor failures
	g_bFinaleWon = false;			//Reset the finale won variable
	ResetAllVotes();				//Reset every player's vote
}

//Event fired when the Survivors leave the start area
public Action Event_PlayerLeftStartArea(Handle hEvent, const char[] strName, bool bDontBroadcast) {	
	if(g_hCVar_VotingEnabled.BoolValue == true && OnFinaleOrScavengeMap() == true)
		CreateTimer(g_hCVar_VotingAdDelayTime.FloatValue, Timer_DisplayVoteAdToAll, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

//Event fired when the Round Ends
public Action Event_RoundEnd(Handle hEvent, const char[] strName, bool bDontBroadcast) {
	// PrintToChatAll("\x03[ACS]\x04 Event_RoundEnd");
	//Check to see if on a finale map, if so change to the next campaign after two rounds
	if(g_iGameMode == GAMEMODE_VERSUS && OnFinaleOrScavengeMap() == true) {
		g_iRoundEndCounter++;
		
		if(g_iRoundEndCounter >= 4)	//This event must be fired on the fourth time Round End occurs.
			CheckMapForChange();	//This is because it fires twice during each round end for
									//some strange reason, and versus has two rounds in it.
	}
	//If in Coop and on a finale, check to see if the surviors have lost the max amount of times
	else if(g_iGameMode == GAMEMODE_COOP && OnFinaleOrScavengeMap() == true &&
			g_hCVar_MaxFinaleFailures.IntValue > 0 && g_bFinaleWon == false &&
			++g_iCoopFinaleFailureCount >= g_hCVar_MaxFinaleFailures.IntValue)
	{
		CheckMapForChange();
	}
	
	return Plugin_Continue;
}

//Event fired when a finale is won
public Action Event_FinaleWin(Handle hEvent, const char[] strName, bool bDontBroadcast) {
	// PrintToChatAll("\x03[ACS]\x04 Event_FinaleWin");
	g_bFinaleWon = true;	//This is used so that the finale does not switch twice if this event
							//happens to land on a max failure count as well as this
	
	//Change to the next campaign
	if(g_iGameMode == GAMEMODE_COOP)
		CheckMapForChange();
	
	return Plugin_Continue;
}

//Event fired when a map is finished for scavenge
public Action Event_ScavengeMapFinished(Handle hEvent, const char[] strName, bool bDontBroadcast) {
	//Change to the next Scavenge map
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		ChangeScavengeMap();
	
	return Plugin_Continue;
}

//Event fired when a player disconnects from the server
public Action Event_PlayerDisconnect(Handle hEvent, const char[] strName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient	< 1)
		return Plugin_Continue;
	
	//Reset the client's votes
	g_bClientVoted[iClient] = false;
	g_iClientVote[iClient] = -1;
	
	//Check to see if there is a new vote winner
	SetTheCurrentVoteWinner();
	
	return Plugin_Continue;
}


/*======================================================================================
#################             A C S   C H A N G E   M A P              #################
======================================================================================*/

//Check to see if the current map is a finale, and if so, switch to the next campaign
void CheckMapForChange() {
	char strCurrentMap[LEN_MAP_FILENAME];
	GetCurrentMap(strCurrentMap,sizeof(strCurrentMap));					//Get the current map from the game

	char colorizedname[LEN_LOCALIZED_NAME];
	char mapName[LEN_MAP_FILENAME];
	char localizedName[LEN_LOCALIZED_NAME];
	for(int cycleIndex = 0; cycleIndex < ACS_GetMissionCount(g_iGameMode); cycleIndex++)	{
		ACS_GetLastMapName(g_iGameMode, cycleIndex, mapName, sizeof(mapName));
		if(StrEqual(strCurrentMap, mapName, false)) {
			for (int client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client)) {
					ACS_GetLocalizedMissionName(g_iGameMode, cycleIndex, client, localizedName, sizeof(localizedName));
					Format(colorizedname, sizeof(colorizedname), "\x04%s\x05", localizedName);
					PrintToChat(client, "\x03[ACS]\x05 %t", "Campaign finished", colorizedname);
				}
			}
			
			//Check to see if someone voted for a campaign, if so, then change to the winning campaign
			if(g_hCVar_VotingEnabled.BoolValue && g_iWinningMapVotes > 0 && g_iWinningMapIndex >= 0) {
				// Get the name of the next first map
				LMM_GetMapName(g_iGameMode, g_iWinningMapIndex, 0, mapName, sizeof(mapName));
				if(IsMapValid(mapName)) {
					for (int client = 1; client <= MaxClients; client++) {
						if (IsClientInGame(client)) {
							LMM_GetMissionLocalizedName(g_iGameMode, g_iWinningMapIndex, localizedName, sizeof(localizedName), client);
							Format(colorizedname, sizeof(colorizedname), "\x04%s\x05", localizedName);
							PrintToChat(client, "\x03[ACS]\x05 %t", "Switching to the vote winner", colorizedname);
						}
					}
					
					CreateChangeMapTimer(mapName);
					
					return;
				}
				else
					LogError("Error: %s is an invalid map name, attempting normal map rotation.", mapName);
			}
			
			//If no map was chosen in the vote, then go with the automatic map rotation
			
			if(cycleIndex >= ACS_GetCycledMissionCount(g_iGameMode) - 1)	//Check to see if it reaches/exceed the end of official map list
				cycleIndex = 0;					//If so, start the array over by setting to -1 + 1 = 0
			else
				cycleIndex++;
				
			ACS_GetFirstMapName(g_iGameMode, cycleIndex, mapName, sizeof(mapName));
			if(IsMapValid(mapName)) {
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client)) {
						ACS_GetLocalizedMissionName(g_iGameMode, cycleIndex, client, localizedName, sizeof(localizedName));
						Format(colorizedname, sizeof(colorizedname), "\x04%s\x05", localizedName);
						PrintToChat(client, "\x03[ACS]\x05 %t", "Switching campaign to", colorizedname);
					}
				}
				
				CreateChangeMapTimer(mapName);
			}
			else
				LogError("Error: %s is an invalid map name, unable to switch map.", mapName);
			
			return;
		}
	}
}

//Change to the next scavenge map
void ChangeScavengeMap() {
	char mapName[LEN_MAP_FILENAME];
	char colorizedname[LEN_LOCALIZED_NAME];
	char localizedName[LEN_LOCALIZED_NAME];
	int cycleCount = ACS_GetMissionCount(g_iGameMode);

	//Check to see if someone voted for a map, if so, then change to the winning map
	if(g_hCVar_VotingEnabled.BoolValue && g_iWinningMapVotes > 0 && g_iWinningMapIndex >= 0) {
		int missionIndex;
		int mapIndex = LMM_DecodeMapUniqueID(g_iGameMode, missionIndex, g_iWinningMapIndex);
		LMM_GetMapName(g_iGameMode, missionIndex, mapIndex, mapName, sizeof(mapName));
		if(IsMapValid(mapName)) {
			for (int client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client)) {
					LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
					Format(colorizedname, sizeof(colorizedname), "\x04%s\x05", localizedName);
					PrintToChat(client, "\x03[ACS]\x05 %t", "Switching to the vote winner", colorizedname);
				}
			}
			
			CreateChangeMapTimer(mapName);
			
			return;
		}
		else
			LogError("Error: %s is an invalid map name, attempting normal map rotation.", mapName);
	}
	
	//If no map was chosen in the vote, then go with the automatic map rotation
	
	char strCurrentMap[LEN_MAP_FILENAME];
	GetCurrentMap(strCurrentMap, sizeof(strCurrentMap));	//Get the current map from the game
	
	//Go through all maps and to find which map index it is on, and then switch to the next map
	for(int cycleIndex = 0; cycleIndex < cycleCount; cycleIndex++)	{
		int missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
		int mapCount = LMM_GetNumberOfMaps(g_iGameMode, missionIndex);
		for (int mapIndex = 0; mapIndex<mapCount; mapIndex++) {
			LMM_GetMapName(g_iGameMode, missionIndex, mapIndex, mapName, sizeof(mapName));

			if(StrEqual(strCurrentMap, mapName, false)) {
				// Check to see if its the end of the array
				// If so, start the array over
				if (mapIndex == mapCount - 1) {	// Last map of a mission
					mapIndex = 0;	// Switch to the first map of the next mission
							
					if (cycleIndex == ACS_GetCycledMissionCount(g_iGameMode) - 1) {	// End of mission cycle
						cycleIndex = 0;
					} else {
						cycleIndex++;
					}
					// Find out the new cycleIndex
					missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
				} else {
					mapIndex++;		// Move to next map
				}
				
				LMM_GetMapName(g_iGameMode, missionIndex, mapIndex, mapName, sizeof(mapName));
				//Make sure the map is valid before changing and displaying the message
				if(IsMapValid(mapName)) {
					for (int client = 1; client <= MaxClients; client++) {
						if (IsClientInGame(client)) {
							LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
							Format(colorizedname, sizeof(colorizedname), "\x04%s\x05", localizedName);
							PrintToChat(client, "\x03[ACS]\x05 %t", "Switching map to", colorizedname);
						}
					}	

					CreateChangeMapTimer(mapName);
				}
				else
					LogError("Error: %s is an invalid map name, unable to switch map.", mapName);
				
				return;
			}
		}
	}
}

/*======================================================================================
#################            A C S   A D V E R T I S I N G             #################
======================================================================================*/

public Action Timer_AdvertiseNextMap(Handle timer, any param) {
	//If next map advertising is enabled, display the text and start the timer again
	if(g_hCVar_NextMapAdMode.IntValue != DISPLAY_MODE_DISABLED)	{
		DisplayNextMapToAll();
		CreateTimer(g_hCVar_NextMapAdInterval.FloatValue, Timer_AdvertiseNextMap, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

// Display nothing if not on the last map
void DisplayNextMapToAll() {
	char localizedName[LEN_MISSION_NAME];
	char colorizedName[LEN_MISSION_NAME];
	
	//If there is a winner to the vote display the winner if not display the next map in rotation
	if(g_iWinningMapIndex >= 0) {
		if(g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_HINT) {	
			//Display the map that is currently winning the vote to all the players using hint text
			if(g_iGameMode == GAMEMODE_SCAVENGE) {
				int missionIndex;
				int mapIndex = LMM_DecodeMapUniqueID(g_iGameMode, missionIndex, g_iWinningMapIndex);
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client)) {
						LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
						PrintHintText(client, "%t", "The next map is currently", localizedName);
					}
				}
			} else {
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client)) {
						LMM_GetMissionLocalizedName(g_iGameMode, g_iWinningMapIndex, localizedName, sizeof(localizedName), client);
						PrintHintText(client, "%t", "The next campaign is currently", localizedName);
					}
				}
			}
		} else if(g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_CHAT)	{
			//Display the map that is currently winning the vote to all the players using chat text
			if(g_iGameMode == GAMEMODE_SCAVENGE) {
				int missionIndex;
				int mapIndex = LMM_DecodeMapUniqueID(g_iGameMode, missionIndex, g_iWinningMapIndex);
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client)) {
						LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
						Format(colorizedName, sizeof(colorizedName), "\x04%s\x05", localizedName);
						PrintToChat(client, "\x03[ACS]\x05 %t", "The next map is currently", colorizedName);
					}
				}
			} else {
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client)) {
						LMM_GetMissionLocalizedName(g_iGameMode, g_iWinningMapIndex, localizedName, sizeof(localizedName), client);
						Format(colorizedName, sizeof(colorizedName), "\x04%s\x05", localizedName);
						PrintToChat(client, "\x03[ACS]\x05 %t", "The next campaign is currently", colorizedName);
					}
				}
			}
		}
	} else {
		char mapName[LEN_MAP_FILENAME];
		char strCurrentMap[LEN_MAP_FILENAME];
		GetCurrentMap(strCurrentMap, sizeof(strCurrentMap));	//Get the filename of the current map from the game
		int cycleCount = ACS_GetMissionCount(g_iGameMode);
		
		if(g_iGameMode == GAMEMODE_SCAVENGE) {
			//Go through all maps and to find which map index it is on, and then switch to the next map
			for(int cycleIndex = 0; cycleIndex < cycleCount; cycleIndex++)	{
				int missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
				int mapCount = LMM_GetNumberOfMaps(g_iGameMode, missionIndex);
				for (int mapIndex = 0; mapIndex<mapCount; mapIndex++) {
					LMM_GetMapName(g_iGameMode, missionIndex, mapIndex, mapName, sizeof(mapName));
					
					if(StrEqual(strCurrentMap, mapName, false)) {
						if (mapIndex == mapCount - 1) {	// Last map of a mission
							mapIndex = 0;	// Switch to the first map of the next mission
							
							if (cycleIndex == ACS_GetCycledMissionCount(g_iGameMode) - 1) {	// End of mission cycle
								cycleIndex = 0;
							} else {
								cycleIndex++;
							}
							// Find out the new cycleIndex
							missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
						} else {
							mapIndex++;		// Move to next map
						}
						
						// Display the result to everyone
						for (int client = 1; client <= MaxClients; client++) {
							if (IsClientInGame(client)) {
								LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
								
								//Display the next map in the rotation in the appropriate way
								if(g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_HINT)
									PrintHintText(client, "%t", "The next map is currently", localizedName);
								else if(g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_CHAT) {
									Format(colorizedName, sizeof(colorizedName), "\x04%s\x05", localizedName);
									PrintToChat(client, "\x03[ACS]\x05 %t", "The next map is currently", colorizedName);
								}
							}
						}
						
						return;
					}
				}
			}
		} else {
			// Coop or Versus
			//Go through all maps and to find which map index it is on, and then switch to the next map
			for(int cycleIndex = 0; cycleIndex < cycleCount; cycleIndex++)	{
				ACS_GetLastMapName(g_iGameMode, cycleIndex, mapName, sizeof(mapName));
				if(StrEqual(strCurrentMap, mapName, false)) {
					if (cycleIndex == ACS_GetCycledMissionCount(g_iGameMode) - 1) {	//Check to see if its the end of the array
						cycleIndex = 0;					//If so, start the array over by setting to -1 + 1 = 0
					} else {
						cycleIndex ++;
					}
					
					//Display the next map in the rotation in the appropriate way
					for (int client = 1; client <= MaxClients; client++) {
						if (IsClientInGame(client)) {
							ACS_GetLocalizedMissionName(g_iGameMode, cycleIndex, client, localizedName, sizeof(localizedName));
							
							if(g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_HINT)
								PrintHintText(client, "%t", "The next campaign is currently", localizedName);
							else if(g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_CHAT) {
								Format(colorizedName, sizeof(colorizedName), "\x04%s\x05", localizedName);
								PrintToChat(client, "\x03[ACS]\x05 %t", "The next campaign is currently", colorizedName);
							}
						}
					}
					return;
				}
			}
		}
		
		// LogError("ACS was unable to locate the current map (%s) in the map cycle!", strCurrentMap);
	}
}

/*======================================================================================
#################              V O T I N G   S Y S T E M               #################
======================================================================================*/

/*======================================================================================
################             P L A Y E R   C O M M A N D S              ################
======================================================================================*/

//Command that a player can use to vote/revote for a map/campaign
public Action MapVote(int iClient, int args) {
	if(!g_hCVar_VotingEnabled.BoolValue) {
		ReplyToCommand(iClient, "\x03[ACS]\x01 %t", "Voting is disable");
		return;
	}
	
	if(!OnFinaleOrScavengeMap()) {
		PrintToChat(iClient, "\x03[ACS]\x01 %t", "Voting is not available");
		return;
	}
	
	//Open the vote menu for the client if they arent using the server console
	if(iClient < 1)
		PrintToServer("You cannot vote for a map from the server console, use the in-game chat");
	else
		VoteMenuDraw(iClient);
}

//Command that a player can use to see the total votes for all maps/campaigns
public Action DisplayCurrentVotes(int iClient, int args) {
	char localizedName[LEN_MISSION_NAME];
	char colorizedName[LEN_MISSION_NAME];
	if(!g_hCVar_VotingEnabled.BoolValue) {
		ReplyToCommand(iClient, "\x03[ACS]\x01 %t", "Voting is disable");
		return;
	}
	
	if(!OnFinaleOrScavengeMap()) {
		PrintToChat(iClient, "\x03[ACS]\x01 %t", "Voting is not available");
		return;
	}
			
	//Display to the client the current winning map
	if(g_iWinningMapIndex >= 0) {
		//Show message to all the players of the new vote winner
		if(g_iGameMode == GAMEMODE_SCAVENGE) {
			int missionIndex;
			int mapIndex = LMM_DecodeMapUniqueID(g_iGameMode, missionIndex, g_iWinningMapIndex);
			LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), iClient);
			Format(colorizedName, sizeof(colorizedName), "\x04%s\x05", localizedName);
			ReplyToCommand(iClient,"\x03[ACS]\x05 %t", "Map is now winning the vote", colorizedName);	
		} else {
			LMM_GetMissionLocalizedName(g_iGameMode, g_iWinningMapIndex, localizedName, sizeof(localizedName), iClient);
			Format(colorizedName, sizeof(colorizedName), "\x04%s\x05", localizedName);
			ReplyToCommand(iClient,"\x03[ACS]\x05 %t", "Mission is now winning the vote", colorizedName);
		}
	} else {
		ReplyToCommand(iClient, "\x03[ACS]\x01 %t", "No one has voted yet");	
	}


	int iNumberOfOptions;

	//Get the total number of options for the current game mode
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		iNumberOfOptions = LMM_GetMapUniqueIDCount(g_iGameMode);
	else
		iNumberOfOptions = LMM_GetNumberOfMissions(g_iGameMode);
		
	//Loop through all maps and display the ones that have votes
	int[] iMapVotes = new int[iNumberOfOptions];
	
	for(int iOption = 0; iOption < iNumberOfOptions; iOption++)	{
		iMapVotes[iOption] = 0;
		
		//Tally votes for the current map
		for(int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			if(g_iClientVote[iPlayer] == iOption)
				iMapVotes[iOption]++;
		
		//Display this particular map and its amount of votes it has to the client
		if(iMapVotes[iOption] > 0)	{
			if(g_iGameMode == GAMEMODE_SCAVENGE) {
				int missionIndex;
				int mapIndex = LMM_DecodeMapUniqueID(g_iGameMode, missionIndex, iOption);
				LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), iClient);
				ReplyToCommand(iClient, "\x04          %s: \x05%d %t", localizedName, iMapVotes[iOption], "Votes");
			} else {
				LMM_GetMissionLocalizedName(g_iGameMode, iOption, localizedName, sizeof(localizedName), iClient);
				ReplyToCommand(iClient, "\x04          %s: \x05%d %t", localizedName, iMapVotes[iOption], "Votes");
			}
				
		}
	}
}

/*======================================================================================
###############                   V O T E   M E N U                       ##############
======================================================================================*/

//Timer to show the menu to the players if they have not voted yet
public Action Timer_DisplayVoteAdToAll(Handle hTimer, any iData) {
	if(!g_hCVar_VotingEnabled.BoolValue || !OnFinaleOrScavengeMap())
		return Plugin_Stop;
	
	for(int iClient = 1;iClient <= MaxClients; iClient++) {
		if(
			!g_bClientShownVoteAd[iClient] && !g_bClientVoted[iClient] &&
			IsClientInGame(iClient) && !IsFakeClient(iClient)
		){
			switch(g_hCVar_VotingAdMode.IntValue) {
				case DISPLAY_MODE_MENU: VoteMenuDraw(iClient);
				case DISPLAY_MODE_HINT: PrintHintText(iClient, "%t", "Map vote advertise", "!mapvote", "!mapvotes");
				case DISPLAY_MODE_CHAT: PrintToChat(iClient, "\x03[ACS]\x05 %t", "Map vote advertise", "\x04!mapvote\x05", "\x04!mapvotes\x05");
			}
			
			g_bClientShownVoteAd[iClient] = true;
		}
	}
	
	return Plugin_Stop;
}

//Draw the menu for voting
public void VoteMenuDraw(int iClient) {
	if(iClient < 1 || IsClientInGame(iClient) == false || IsFakeClient(iClient) == true)
		return;
	
	//Populate the menu with the maps in rotation for the corresponding game mode
	if(g_iGameMode == GAMEMODE_SCAVENGE) {
		ShowMissionChooser(iClient, true, true);	// Choose maps
	} else {
		ShowMissionChooser(iClient, false, true);	// Choose missions
	}
	
	//Play a sound to indicate that the user can vote on a map
	EmitSoundToClient(iClient, SOUND_NEW_VOTE_START);
}

//Handle the menu selection the client chose for voting
public int VoteMenuHandler(int iClient, bool dontCare, int missionIndex, int mapIndex) {
	g_bClientVoted[iClient] = true;
	
	//Set the players current vote
	if(dontCare) {
		g_iClientVote[iClient] = -1;
	} else {
		if(g_iGameMode == GAMEMODE_SCAVENGE || g_iGameMode == GAMEMODE_SURVIVAL) {
			g_iClientVote[iClient] = LMM_GetMapUniqueID(g_iGameMode, missionIndex, mapIndex);
		} else {
			g_iClientVote[iClient] = missionIndex;
		}
	}
			
	//Check to see if theres a new winner to the vote
	SetTheCurrentVoteWinner();
		
	//Display the appropriate message to the voter
	char localizedName[LEN_MISSION_NAME];
	if(dontCare) {
		PrintHintText(iClient, "%t", "You did not vote", "!mapvote");
	} else if(g_iGameMode == GAMEMODE_SCAVENGE) {
		LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), iClient);
		PrintHintText(iClient, "%t", "You voted for", localizedName, "!mapvote", "!mapvotes");
	} else {
		LMM_GetMissionLocalizedName(g_iGameMode, missionIndex, localizedName, sizeof(localizedName), iClient);
		PrintHintText(iClient, "%t", "You voted for", localizedName, "!mapvote", "!mapvotes");
	}
}

/*======================================================================================
#########       M I S C E L L A N E O U S   V O T E   F U N C T I O N S        #########
======================================================================================*/

//Resets all the votes for every player
void ResetAllVotes() {
	for(int iClient = 1; iClient <= MaxClients; iClient++) {
		g_bClientVoted[iClient] = false;
		g_iClientVote[iClient] = -1;
		
		//Reset so that the player can see the advertisement
		g_bClientShownVoteAd[iClient] = false;
	}
	
	//Reset the winning map to NULL
	g_iWinningMapIndex = -1;
	g_iWinningMapVotes = 0;
}

//Tally up all the votes and set the current winner
void SetTheCurrentVoteWinner() {
	int iNumberOfOptions;
	
	//Store the current winnder to see if there is a change
	int iOldWinningMapIndex = g_iWinningMapIndex;
	
	//Get the total number of options for the current game mode
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		iNumberOfOptions = LMM_GetMapUniqueIDCount(g_iGameMode);
	else
		iNumberOfOptions = LMM_GetNumberOfMissions(g_iGameMode);
	
	//Loop through all options and get the highest voted option	
	int[] iMapVotes = new int[iNumberOfOptions];
	int iCurrentlyWinningMapVoteCounts = 0;
	bool bSomeoneHasVoted = false;
	
	for(int iOption = 0; iOption < iNumberOfOptions; iOption++) {
		iMapVotes[iOption] = 0;
		
		//Tally votes for the current option
		for(int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			if(g_iClientVote[iPlayer] == iOption)
				iMapVotes[iOption]++;
		
		//Check if there is at least one vote, if so set the bSomeoneHasVoted to true
		if(!bSomeoneHasVoted && iMapVotes[iOption] > 0)
			bSomeoneHasVoted = true;
		
		//Check if the current option has more votes than the currently highest voted option
		if(iMapVotes[iOption] > iCurrentlyWinningMapVoteCounts) {
			iCurrentlyWinningMapVoteCounts = iMapVotes[iOption];
			
			g_iWinningMapIndex = iOption;
			g_iWinningMapVotes = iMapVotes[iOption];
		}
	}
	
	//If no one has voted, reset the winning option index and votes
	//This is only for if someone votes then their vote is removed
	if(!bSomeoneHasVoted) {
		g_iWinningMapIndex = -1;
		g_iWinningMapVotes = 0;
	}
	
	//If the vote winner has changed then display the new winner to all the players
	if(g_iWinningMapIndex > -1 && iOldWinningMapIndex != g_iWinningMapIndex) {
		//Send sound notification to all players
		if(g_hCVar_VoteWinnerSoundEnabled.BoolValue)
			for(int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
				if(IsClientInGame(iPlayer) && !IsFakeClient(iPlayer))
					EmitSoundToClient(iPlayer, SOUND_NEW_VOTE_WINNER);
		
		char localizedName[LEN_MISSION_NAME];
		char colorizedName[LEN_MISSION_NAME];
		//Show message to all the players of the new vote winner
		if(g_iGameMode == GAMEMODE_SCAVENGE) {
			int missionIndex;
			int mapIndex = LMM_DecodeMapUniqueID(g_iGameMode, missionIndex, g_iWinningMapIndex);
			
			for (int client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client)) {
					LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
					Format(colorizedName, sizeof(colorizedName), "\x04%s\x05", localizedName);
					PrintToChat(client,"\x03[ACS]\x05 %t\x05", "Map is now winning the vote", colorizedName);
				}
			}
		} else {
			for (int client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client)) {
					LMM_GetMissionLocalizedName(g_iGameMode, g_iWinningMapIndex, localizedName, sizeof(localizedName), client);
					Format(colorizedName, sizeof(colorizedName), "\x04%s\x05", localizedName);
					PrintToChat(client,"\x03[ACS]\x05 %t\x05", "Mission is now winning the vote", colorizedName);
				}
			}
		}
	}
}

//Check if the current map is the last in the campaign if not in the Scavenge game mode
bool OnFinaleOrScavengeMap() {
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		return true;
	
	if(g_iGameMode == GAMEMODE_SURVIVAL)
		return false;
	
	// Coop or Versus
	
	char strCurrentMap[LEN_MAP_FILENAME];
	GetCurrentMap(strCurrentMap, sizeof(strCurrentMap));			//Get the current map from the game
	
	char lastMap[LEN_MAP_FILENAME];
	//Run through all the maps, if the current map is a last campaign map, return true
	for(int cycleIndex = 0; cycleIndex < ACS_GetMissionCount(g_iGameMode); cycleIndex++) {
		ACS_GetLastMapName(g_iGameMode, cycleIndex, lastMap, sizeof(lastMap));
		if(StrEqual(strCurrentMap, lastMap, false))
			return true;
	}
	
	return false;
}
