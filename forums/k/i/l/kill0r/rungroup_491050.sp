/**
 * rungroup.sp
 *
 * Version: see Plugin:myinfo
 */

/**
Changelog:
0.2.1.19
 - added the ability to automatically restore the teamfile if it's missing
0.2.0.18
 - added 'me' as alias of 'self'
 - added 'lookat' and the alias 'picker' for the player you are looking at
 - fixed bug where plugin was loading only one team from rungroup.games.txt caused by this bugfix http://svn.alliedmods.net/viewvc.cgi?view=rev&root=sourcemod&revision=1008 ^^
 - moved rungroup.games.txt to addons/sourcemod/gamedata/rungroup.games.txt
 - added tf to rungroup.games.txt
*/

/*
sm_rungroup <targets> <cmd[ params with #id or #steam or #name]*>
targets:
 - teamX - allgemein teamnummer, z.B. falls unbekannter mod
 - userid of a client
 - admin - clients that have only the reservationflag are not admins
 - all, bot, human, alive, dead, self, me, notadmin
 - [modspecific] - see addons/sourcemod/gamedata/rungroup.games.txt
    CS:S: unas, spec, ct, t
 - picker target looking at
 - lookat same as picker


operators:
+ clients from a and clients from b
- clients from a without clients of b
= clients that are in group a and b

Examples:
Targets all:
	sm_rungroup all sm_kick ##id
All except yourself:
	sm_rungroup all-self sm_kick ##id
All dead cts, but not bots or admins:
	sm_rungroup ct=dead-bot-admin sm_kick ##id
Specteam and players with userid 3 and 5
	sm_rungroup spec+3+5 sm_kick ##id

Test:
	sm_rungroup all sm_rcon say #id #steam #name

alias rr "sm plugins unload 16;sm plugins load rungroup"
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define TEAMFILE "addons/sourcemod/gamedata/rungroup.games.txt"

public Plugin:myinfo = 
{
	name = "Rungroup",
	author = "kill0r",
	description = "Run cmds for a group of clients.",
	version = "0.2.1.19",
	url = "http://forums.alliedmods.net/showthread.php?t=56625"
};

public OnPluginStart() {
	RegAdminCmd("sm_rungroup", Command_Rungroup, ADMFLAG_GENERIC, "sm_rungroup <targets> <cmd with #id or #steam or #name>");
	RestoreDefaultTeamfileIfMissing();
	LoadUserTeams();
}

public OnPluginEnd() {
	
}

#define MAXUSERTEAMS 8
#define MAXTNL 10
new userTeamCount = 0;
new String:userTeamNames[MAXUSERTEAMS][MAXTNL];
new userTeamNumbers[MAXUSERTEAMS];
new String:helpText[MAXUSERTEAMS*(MAXTNL+1)] = "";

stock _strtolower(String:str[]) {
	new len = strlen(str);
	for (new i=0; i<len; i++)
		str[i] = CharToLower(str[i]);
}
stock ReplaceStringSW(String:buffer[],const String:src[]) {
	new pos = -1;
	new sLen = strlen(src);
	while ((pos=StrContains(buffer[pos+1],src,false))>=0) {
		for (new i=0; i<sLen; i++) {
			buffer[pos+i] = src[i];
		}
	}
}


stock RestoreDefaultTeamfileIfMissing() {
	if (FileExists(TEAMFILE))
		return;
	new Handle:tf = OpenFile(TEAMFILE, "wb");
	if (tf==INVALID_HANDLE) {
		LogMessage("* Warning: Can't restore '%s'",TEAMFILE);
		return;
	}
	WriteFileString(tf, "// Version: 2008-03-02\n\"Games\"\n{\n	// README:\n	//\n	// use the modname if it doesn't has a version within.\n	// use the foldername if it has multiple versions or names.\n\n	\"cstrike\"\n	//\"Counter-Strike: Source\"\n	{\n		\"unas\"	\"0\"\n		\"spec\"	\"1\"\n		\"t\"	\"2\"\n		\"ct\"	\"3\"\n	}\n\n	", false);
	WriteFileString(tf, "// \"Day of Defeat\"\n	// \"Day of Defeat: Source\"\n	\"dod\"\n	{\n		\"unas\"	\"0\"\n		\"spec\"	\"1\"\n		\"a\"	\"2\"\n		\"x\"	\"3\"\n	}\n\n	// \"SourceForts v1.9.2\"\n	\"sourceforts\"\n	{\n		\"unas\"	\"0\"\n		\"spec\"	\"1\"\n		\"b\"	\"2\"	// blue\n		\"r\"	\"3\"	// red\n	}\n\n	\"tf\"\n	{\n		\"unas\"	\"0\"\n		\"spec\"  \"1\"\n		\"red\"   \"2\"\n		\"blue\"  \"3\"\n	}\n	\n	", false);
	WriteFileString(tf, "// \"Half-Life 2 Deathmatch\"\n	// \"Deathmatch\"\n	\"hl2mp\"\n	{\n		\"a\"	\"0\"\n		\"spec\"	\"1\"\n	}\n\n\n	\"Team Deathmatch\"\n	{\n		\"unas\"	\"0\"\n		\"spec\"	\"1\"\n		\"c\"	\"2\"	// combine\n		\"r\"	\"3\"	// revel\n	}\n\n	\"Half-Life 2 CTF\"\n	{\n		\"spec\"	\"1\"\n		\"c\"	\"2\"	// combine\n		\"r\"	\"3\"	// revel\n	}\n\n	", false);
	WriteFileString(tf, "\"Hidden : Source B2B\"\n	{\n		\"a\"	\"0\"\n		\"spec\"	\"1\"\n	}\n	\"Hidden : Source B4\"\n	{\n		\"spec\"	\"1\"\n		\"p\"	\"2\"	// punks\n		\"c\"	\"3\"	// corps\n	}\n\n	\"Empires\"\n	{\n		\"spec\"	\"1\"\n		\"nf\"	\"2\"	// northern_faction\n		\"be\"	\"3\"	// brenodi_empire\n	}\n	\"Empires v1.05 Beta\"\n	{\n		\"spec\"	\"1\"\n		\"nf\"	\"2\"	// northern_faction\n		\"be\"	\"3\"	// brenodi_empire\n	}\n}\n", false);
	CloseHandle(tf);
}

/**
 * Load user teams.
 */
stock LoadUserTeams() {
	new String:fullName[60];
	GetGameDescription(fullName,sizeof(fullName));
	new String:folderName[30];
	GetGameFolderName(folderName,sizeof(folderName));
	
	new Handle:kv = CreateKeyValues("Games");
	FileToKeyValues(kv, TEAMFILE );
	// Kv-stuff is case-insensitive
	if (!KvJumpToKey(kv, fullName) && !KvJumpToKey(kv, folderName)) {
		LogMessage("* Warning: Teamfile not found '%s'",TEAMFILE);
		return;
	}

	if (!KvGotoFirstSubKey(kv,false)) {
		return;
	}

	do {
		KvGetSectionName(kv, userTeamNames[userTeamCount++], MAXTNL);
		//LogMessage("userTeamCount = %d",userTeamCount);
	} while (KvGotoNextKey(kv,false));
	
	KvGoBack(kv);
	for (new i=0; i<userTeamCount; i++) {
		userTeamNumbers[i] = KvGetNum(kv,userTeamNames[i],0);
		_strtolower(userTeamNames[i]);
		//LogMessage("%s = %d",userTeamNames[i],userTeamNumbers[i]);
	}
	ImplodeStrings(userTeamNames,userTeamCount,", ",helpText,MAXUSERTEAMS*(MAXTNL+1));
}



enum ClientGroups {
	CG_NONE, 
	CG_ALL, CG_TEAM,
	CG_HUMAN, CG_BOT,
	CG_ALIVE, CG_DEAD,
	CG_SELF, CG_USERID,
	CG_ADMIN, CG_NOTADMIN,
	CG_LOOKAT,
}
/**
 * 
 */
stock GetClientsOfGroup(client,ClientGroups:group,teamidOrUserid=0,clients[],size) {
	if (size<1)
		return;
	
	new maxClients = GetMaxClients();
	new j = 0;
	
	// No fall-through => no switch-case!!
	switch (group) {
		case CG_ALL: {
			for (new i = 1; i <= maxClients && j<size; i++) {
				if (!IsClientInGame(i))
					continue;
				clients[j++] = i;
			}
		}
		case CG_TEAM: {
			for (new i = 1; i <= maxClients && j<size; i++) {
				if (!IsClientInGame(i) || GetClientTeam(i)!=teamidOrUserid)
					continue;
				clients[j++] = i;
			}
		}
		case CG_HUMAN: {
			for (new i = 1; i <= maxClients && j<size; i++) {
				if (!IsClientInGame(i) || IsFakeClient(i))
					continue;
				clients[j++] = i;
			}
		}
		case CG_BOT: {
			for (new i = 1; i <= maxClients && j<size; i++) {
				if (!IsClientInGame(i) || !IsFakeClient(i))
					continue;
				clients[j++] = i;
			}
		}
		case CG_ALIVE: {
			for (new i = 1; i <= maxClients && j<size; i++) {
				if (!IsClientInGame(i) || GetEntData(i,FindDataMapOffs(client,"m_lifeState"),1) )
					continue;
				clients[j++] = i;
			}
		}
		case CG_DEAD: {
			for (new i = 1; i <= maxClients && j<size; i++) {
				if (!IsClientInGame(i) || !GetEntData(i,FindDataMapOffs(client,"m_lifeState"),1) )
					continue;
				clients[j++] = i;
			}
		}
		case CG_SELF: {
			clients[j++] = client;
		}
		case CG_USERID: {
			clients[j] = GetClientOfUserId(teamidOrUserid);
			if (clients[j])
				j++;
		}
		case CG_ADMIN: {
			for (new i = 1; i <= maxClients && j<size; i++) { // ADMFLAG_GENERIC doens't work?!?! :-/
				if (!IsClientInGame(i) || !GetUserFlagBits(i) || GetUserFlagBits(i)==ADMFLAG_RESERVATION)
					continue;
				clients[j++] = i;
			}
		}
		case CG_NOTADMIN: {
			for (new i = 1; i <= maxClients && j<size; i++) {
				if (!IsClientInGame(i) || (GetUserFlagBits(i) && GetUserFlagBits(i)^ADMFLAG_RESERVATION))
					continue;
				clients[j++] = i;
			}
		}
		case CG_LOOKAT: {
			if (client>0) {
				clients[j] = GetClientAimTarget(client, true);
				if (clients[j]>=0)
					j++;
			}
		}
	}
	
	// term. the rest
	for (;j<size;j++) {
		clients[j] = 0;
	}
}



public Action:Command_Rungroup(client, args) {
	if (args<2) {
		ReplyToCommand(client, "[SM] Usage: sm_rungroup <targets> <cmd with #id or #steam or #name>");
		ReplyToCommand(client, "\ttargets: all, teamX, bot, human, alive, dead, admin, notadmin, self, me, picker, lookat, userid, %s",helpText);
		ReplyToCommand(client, "\toperators: merge: +, diff: -, intersect: =");
		ReplyToCommand(client, "\te.g.: sm_rungroup all-self sm_kick ##id");
		return Plugin_Handled;
	}

	new String:strGroups[128];
	GetCmdArg(1, strGroups, sizeof(strGroups));
	//LogMessage("Arg1: %s",strGroups);
	
	// Helpstring (copy of strGroups, but '\0' instead of '+' or '-'
	new len = strlen(strGroups);
	new String:termGroups[len+1];
	strcopy(termGroups, len+1, strGroups);
	for (new i=0; i<len; i++) {
		if (termGroups[i]=='+' || termGroups[i]=='-' || termGroups[i]=='=') {
			termGroups[i] = 0;
		}
	}
	
	new maxClients = GetMaxClients();
	new clientList[maxClients];
	new tmpList[maxClients];
	new ClientGroups:grpenum = ClientGroups:CG_NONE;
	new number = 0;
	new op = '+'; // add the first tmpList to clientList
	
	new bool:getNext = true;
	new startPos = 0, endPos = 0;

	while (getNext) {
		//LogMessage("a, s:%d, e:%d",startPos,endPos);
		endPos = GetGroupEnum(termGroups[startPos],grpenum,number)+startPos;
		//LogMessage("grpenum: %d, number: %d",grpenum,number);
		
		GetClientsOfGroup(client,grpenum,number,tmpList,maxClients);
		// Cancel if group identifier not found, e.g. sm_rungroup all-admn kick ##id would kick all if this would not be canceled.
		if (grpenum==ClientGroups:CG_NONE) {
			ReplyToCommand(client, "Unknown target '%s'",termGroups[startPos]);
			return Plugin_Handled;
		}
		
		if (op=='+')
			ArraysetPlus(clientList,maxClients,tmpList,maxClients);
		else if (op=='-')
			ArraysetMinus(clientList,maxClients,tmpList,maxClients);
		else if (op=='=')
			ArraysetIntersect(clientList,maxClients,tmpList,maxClients);
		
		if (endPos<(len-1)) { // ignore operator @strend
			startPos = endPos+1; // skip operator
			// Get next op
			if (strGroups[endPos]=='+')
				op = '+';
			else if (strGroups[endPos]=='-')
				op = '-';
			else if (strGroups[endPos]=='=')
				op = '=';
			else
				op = 0;
			//LogMessage("Op: %c",op);
		} else {
			getNext = false;
		}
	}
	
	new String:restarg[256];
	GetCmdArgString(restarg, sizeof(restarg));
	TrimString(restarg);
	new skip = strlen(strGroups)+1;
	if (restarg[0]=='"') {
		skip+=2;
	}
	skip += TrimQuotes(restarg[skip]);
	//ReplyToCommand(client,"DEBUG: %s",restarg[skip]);
	
	new bool:checkId;
	if ((checkId=(StrContains(restarg,"#id",false)>=0))==true)
		ReplaceStringSW(restarg,"#id");
	new bool:checkSteam;
	if ((checkSteam=(StrContains(restarg,"#steam",false)>=0))==true)
		ReplaceStringSW(restarg,"#steam");
	new bool:checkName;
	if ((checkName=(StrContains(restarg,"#name",false)>=0))==true)
		ReplaceStringSW(restarg,"#name");
	
	new String:userId[10];
	new String:userSteam[20];
	new String:userName[30];
	
	new String:rc[sizeof(restarg)];
	for (new i=0; i<maxClients; i++) {
		if (clientList[i]==0 || !IsClientInGame(clientList[i]))
			continue;

		strcopy(rc,256,restarg[skip]);
		if (checkId) {
			IntToString(GetClientUserId(clientList[i]),userId, sizeof(userId));
			ReplaceString(rc,sizeof(restarg)-skip,"#id",userId);
		}
		if (checkSteam && GetClientAuthString(clientList[i], userSteam, sizeof(userSteam))) {
			ReplaceString(rc,sizeof(restarg)-skip,"#steam",userSteam);
		}
		if (checkName && GetClientName(clientList[i], userName, sizeof(userName))) {
			ReplaceString(rc,sizeof(restarg)-skip,"#name",userName);
		}
		//ReplyToCommand(client,"DEBUG,cmd: %s",rc);
		if (client) {
			FakeClientCommand(client,rc);
		} else {
			ServerCommand(rc);
		}
	}
	
	return Plugin_Handled;
}


stock CheckForUserTeam(String:group[],&ClientGroups:grpenum,&number) {
	for (new i=0; i<userTeamCount; i++) {
		if (StrEqual(group,userTeamNames[i],false)) {
			number = userTeamNumbers[i];
			grpenum = ClientGroups:CG_TEAM;
			return;
		}
	}
}
/**
 * @param grpenum return grpenum
 * @param number return number if teamid or userid
 * @return next endpos.
 */
stock GetGroupEnum(String:group[],&ClientGroups:grpenum,&number) {
	grpenum = ClientGroups:CG_NONE;
	new tmp = 0;
	if (StrEqual(group,"all",false))			// ALL
		grpenum = ClientGroups:CG_ALL;
	else if (StrEqual(group,"human",false))		// HUMAN
		grpenum = ClientGroups:CG_HUMAN;
	else if (StrEqual(group,"bot",false))		// BOT
		grpenum = ClientGroups:CG_BOT;
	else if (StrEqual(group,"alive",false))		// ALIVE
		grpenum = ClientGroups:CG_ALIVE;
	else if (StrEqual(group,"dead",false))		// DEAD
		grpenum = ClientGroups:CG_DEAD;
	else if (StrEqual(group,"admin",false))		// ADMIN
		grpenum = ClientGroups:CG_ADMIN;
	else if (StrEqual(group,"notadmin",false))	// NOTADMIN
		grpenum = ClientGroups:CG_NOTADMIN;
	else if (StrEqual(group,"self",false) || StrEqual(group,"me",false))		// SELF, ME
		grpenum = ClientGroups:CG_SELF;
	else if (StrEqual(group,"lookat",false) || StrEqual(group,"picker",false))	// LOOKAT, PICKER
		grpenum = ClientGroups:CG_LOOKAT;
	else if ((tmp=StringToInt(group))>0) {		// USERID
		number = tmp;
		grpenum = ClientGroups:CG_USERID;
	}
	// teamid, if there is min. one char after "team"
	else if ((tmp=StrContains(group,"team",false))==0 && group[4]!=0) {	// TEAM: ID
		if (group[4]=='0') {
			number = 0;
			grpenum = ClientGroups:CG_TEAM;
		} else if ((tmp = StringToInt(group[4]))>0) {
			number = tmp;
			grpenum = ClientGroups:CG_TEAM;
		}
	}
	CheckForUserTeam(group,grpenum,number);		// Mod specific teams, unas, spec, ct, t etc.

	return strlen(group);
}

/**
 * @return -1 if not found.
 */
stock ArrayPos(number,list[],size) {
	for (new i=0; i<size; i++) {
		if (list[i]==number)
			return i;
	}
	return -1;
}

/**
 * merge
 */
stock ArraysetPlus(left[],lsize,right[],rsize) {
	new found;
	for (new r = 0; r<rsize; r++) {
		if (right[r]==0)
			continue;
		
		found = ArrayPos(right[r],left,lsize);
		// already in the set:
		if (found>=0)
			continue;
		
		found = ArrayPos(0,left,lsize);
		// if left is full
		if (found<0)
			return;
		
		left[found] = right[r];
	}
}
/**
 * diff
 */
stock ArraysetMinus(left[],lsize,right[],rsize) {
	new found;
	for (new r = 0; r<rsize; r++) {
		if (right[r]==0)
			continue;

		found = ArrayPos(right[r],left,lsize);
		// not in the set:
		if (found<0)
			continue;
		
		left[found] = 0;
	}
}
/**
 * intersect
 */
stock ArraysetIntersect(left[],lsize,right[],rsize) {
	new found;
	for (new l = 0; l<lsize; l++) {
		if (left[l]==0)
			continue;
		
		found = ArrayPos(left[l],right,rsize);
		
		if (found>=0)
			continue;
		
		// not found => 0
		left[l] = 0;
	}
}

/**
 * Removes quotes if the string is in quotes.
 *
 * @param text	The string to Trim.
 * @return		Startindex (0 if it was'n quotet else 1).
 */
stock TrimQuotes(String:text[]) {
	new startidx = 0;
	if (text[0] == '"') {
		new len = strlen(text);
		if (text[len-1] == '"') {
			startidx = 1;
			text[len-1] = '\0';
		}
	}
	return startidx;
}