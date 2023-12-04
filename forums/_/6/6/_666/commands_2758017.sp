public void checkcommands(int client, char[] string) {
	VALID_PLAYER {
		#if defined PLUGIN_DEBUG_MODE
			PrintToChatAll("checkcommands : %s", string);
		#endif
	
		if(string[0] == '!' && string[1] == 'v' && string[2] == 'o' && string[3] == 't' && string[4] == 'e') {
			CheckCommand(client, string, "!");
		}
		
		else if(string[0] == '/' && string[1] == 'v' && string[2] == 'o' && string[3] == 't' && string[4] == 'e') {
			CheckCommand(client, string, "/");
		}
		
		else if(string[0] == 'v' && string[1] == 'o' && string[2] == 't' && string[3] == 'e') {
			CheckCommand(client, string, "");
		}
	}
}

public Action OnClientCommands(int client, char[] command, int argc) 
{
	char text[32]; 
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	checkcommands(client,text);
	return Plugin_Continue;
}

// Check commands
public void CheckCommand(int client, const char[] args, const char[] pref) {
	
	char command[24];
	strcopy(command, sizeof(command), args);
	TrimString(command);
	
	#if defined PLUGIN_DEBUG_MODE
		PrintToChatAll("CheckCommand : %s", command);
	#endif

	if(strlen(pref) > 0) {
		ReplaceString(command, sizeof(command), pref, "", true);
	}
	
	if(CONVAR_ENABLED.IntValue < 1) {
		return;
	}

	if(!StrEqual(command, BAN_COMMAND, false)
	 && !StrEqual(command, KICK_COMMAND, false)
	 && !StrEqual(command, MUTE_COMMAND, false)) {
		return;
	}

	if(CountPlayers_withoutImmunity() < CONVAR_MIN_PLAYERS.IntValue) {
		//PrintToChat(client, "[GameVoting] Minimum players for voting - %d.", CONVAR_MIN_PLAYERS.IntValue);
		PrintToChat(client, "\x04[GameVoting]\x01 %t", "gv_min_players", CONVAR_MIN_PLAYERS.IntValue);
		return;
	}
	
	if(CONVAR_AUTODISABLE.IntValue > 0) {
		if(adminsonserver()) {
			return;
		}
	}
	
	if(StrEqual(command, BAN_COMMAND, false)) {
		if(CONVAR_BAN_ENABLE.IntValue < 1) {
			return;
		}
	
		DisplayReasons(client);
		//ShowMenu(client,VOTE_BAN,false);
		return;
	}
	
	if(StrEqual(command, KICK_COMMAND, false)) {
		if(CONVAR_KICK_ENABLE.IntValue < 1) {
			return;
		}
	
		ShowMenu(client,VOTE_KICK,false);
		return;
	}
	
	if(StrEqual(command, MUTE_COMMAND, false)) {
		if(CONVAR_MUTE_ENABLE.IntValue < 1) {
			return;
		}
	
		ShowMenu(client,VOTE_MUTE,false);
		return;
	}
	
	/*if(StrEqual(command, SILENCE_COMMAND, false)) {
		if(CONVAR_SILENCE_ENABLE.IntValue < 1) {
			return;
		}
	
		ShowMenu(client,VOTE_SILENCE);
		return;
	}*/
}