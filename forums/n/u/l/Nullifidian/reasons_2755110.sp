public void loadReasons() {
	if(gReasons != null) {
		gReasons.Clear();
		delete gReasons;
	}
	
	char fFile[86];
	BuildPath(Path_SM, fFile, sizeof(fFile), "configs/gvreasons.txt");

	if(FileExists(fFile))
	{
		File oFile = OpenFile(fFile,"r");
		if(oFile == null) {
			SetFailState("I can't open file: addons/sourcemod/configs/gvreasons.txt");
		}
		if(FileSize(fFile) < 5) {
			SetFailState("Please, fill this file: addons/sourcemod/configs/gvreasons.txt");
		}

		char buff[REASON_LEN];
		int oLines = 1;
		gReasons = new ArrayList(REASON_LEN, 0);
		while(!IsEndOfFile(oFile))
		{
			if(!ReadFileLine(oFile,buff,REASON_LEN)) {
				//SetFailState("I can't read file: addons/sourcemod/configs/gvreasons.txt");
				continue;
			}
			TrimString(buff);
			if(strlen(buff) > 1)
			{
				#if defined PLUGIN_DEBUG
					LogMessage("Push reason: %s", buff);
				#endif
				int index = gReasons.PushString(buff);
				LOGS_ENABLED {
					LogToFile(LogFilePath, "Reason loaded : %s (index : %d)", buff, index);
					PrintToServer("[GameVoting] Reason loaded : %s (index : %d)", buff, index);
				}
				oLines++;
			}
			else
			{
				LOGS_ENABLED {
					// LogError("[GameVoting] Can't add reason: %s, because its smaller than 1 letters. (LINE: %d)", buff, oLines);
					LogToFile(LogFilePath, "[Error] Can't add reason: %s, because its smaller than 1 letters. (LINE: %d)", buff, oLines);
				}
			}
		}
		oFile.Close();
	}
	else {
		SetFailState("Please, create file in directory: addons/sourcemod/configs/gvreasons.txt, with reasons on one line!");
	}
}


public void DisplayReasons(int client) {
	Menu mReasons = CreateMenu(MenuHandler_Reason);
	SetMenuTitle(mReasons, "[GameVoting] Reason");
	int sSize = ((gReasons.Length)-1);
	char buff[REASON_LEN];
	char buff2[18];
	for(int i = 0; i <= sSize; i++) {
		gReasons.GetString(i, buff, sizeof(buff));
		IntToString(i, buff2, sizeof(buff2));
		mReasons.AddItem(buff2, buff, ITEMDRAW_DEFAULT);
		// LOGS_ENABLED {
		// 	PrintToServer("Display menu reason: %s - %s ", buff2, buff);
		// }
	}
	DisplayMenu(mReasons, client, 0);
}


public int MenuHandler_Reason(Menu menu, MenuAction action, int client, int item) {
	if(action == MenuAction_End) {
		CloseHandle(menu);
	}
	else if(action == MenuAction_Select) 
	{
		char item1[11];
		GetMenuItem(menu, item, item1, sizeof(item1));
		g_VoteChoise[client].voteban_reason = StringToInt(item1); // reason from array
		LOGS_ENABLED {
			char reason[64];
			if(g_VoteChoise[client].voteban_reason > -1) {
				gReasons.GetString(g_VoteChoise[client].voteban_reason, reason, sizeof(reason));
			}
			PrintToServer("Player %N choised reason : %s - #%i - #%i",  client, reason, g_VoteChoise[client].voteban_reason, StringToInt(item1));
			LogToFile(LogFilePath, "Player %N choised reason : %s - #%i - #%i",  client, reason, g_VoteChoise[client].voteban_reason, StringToInt(item1));
		}
		// Handle StartVote Enable/Disable
		if(CONVAR_START_VOTE_ENABLE.IntValue > 0) {
			ShowMenu(client, VOTE_BAN, true);
		}
		else {
			ShowMenu(client, VOTE_BAN, false);
		}
	}
}


public int HasReason(int target) {
	char auth[32];
	player_steam(target, auth, sizeof(auth));
	for(int i =0 ; i <= MAXPLAYERS; i ++) {
		/*Find steamid in array*/
		/*VAR_IVOTEBAN g_VoteChoise[i].vbSteam*/
		if(StrEqual(VAR_IVOTEBAN,auth,true)) {
			if(g_VoteChoise[i].voteban_reason > 0) {
				return g_VoteChoise[i].voteban_reason;
			}
		}
	}
		
	return -1;
}