#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define ALERT_SOUND "ui/system_message_alert.wav"
#define WEIGHTED_MAPVOTES_VERSION "1.0.0.2"

public Plugin:myinfo=
{
	name="VIP Mapvotes",
	author="El Diablo",
	description="Allows VIPs or anyone to vote for map.",
	version=WEIGHTED_MAPVOTES_VERSION,
	url="http://war3evo.info/"
};

/*
 * To Do:
 *
 * Add Translation Compatibilities
 *
 * Implement the rest of the CreateConVars
 *
 *
*/

// default 600 = 10 mintues.   Use the vip_mapvotes_voting_allowed_time Cvar to change this in minutes.
new TimeLeftOnMapBeforePlayerCanVote = 600;

new String:MapWinningName[32];

new Handle:g_hAdminFlags = INVALID_HANDLE;
new Handle:g_hAdminFlagsPoints = INVALID_HANDLE;

new Handle:g_hNamesBeginWith = INVALID_HANDLE;
new Handle:g_hNamesBeginWithPoints = INVALID_HANDLE;

new Handle:g_hNamesContain = INVALID_HANDLE;
new Handle:g_hNamesContainPoints = INVALID_HANDLE;

new Handle:g_hMapNames = INVALID_HANDLE;
new Handle:g_hMapNamesPoints = INVALID_HANDLE;

new Handle:g_hCanTriggerMapVotesFlags = INVALID_HANDLE;

new Handle:g_hMapVotingCommands = INVALID_HANDLE;

new Handle:h_LogsEnabledCvar = INVALID_HANDLE;
new Handle:h_VIP_voting_allowed_time_Cvar = INVALID_HANDLE;
new Handle:h_VIP_Map_Vote_Timer_Warning_Cvar = INVALID_HANDLE;
new Handle:h_VIP_Map_Timelimit_Cvar = INVALID_HANDLE;
new Handle:h_VIPFlagsCvar = INVALID_HANDLE;

new Handle:h_vip_matvote_location;

//new Handle:h_PrintTallyDetail;

// Must pick 5 maps for players to choose from, otherwise map voting is null.
new VIPMapStarter=-1;
new VIPMapCount=0;
new VIPChoosenMapsPicked[5];

new VOTES[MAXPLAYERS+1];

new Handle:hudText = INVALID_HANDLE;
new Handle:VoteTimer = INVALID_HANDLE;
new timeRemaining;

new MapVoteTimerWarning=0;

/*
 * Can be found also at:
 * https://wiki.alliedmods.net/Adding_Admins_%28SourceMod%29
 *
	Name 		Flag 	Purpose
	reservation a 		Reserved slot access.
	generic 	b 		Generic admin; required for admins.
	kick 		c		Kick other players.
	ban 		d		Ban other players.
	unban 		e		Remove bans.
	slay 		f		Slay/harm other players.
	changemap	g 		Change the map or major gameplay features.
	cvar 		h		Change most cvars.
	config 		i		Execute config files.
	chat 		j		Special chat privileges.
	vote 		k		Start or create votes.
	password	l 		Set a password on the server.
	rcon 		m		Use RCON commands.
	cheats 		n		Change sv_cheats or use cheating commands.
	root 		z		Magically enables all flags and ignores immunity values.
	custom1 	o 		Custom Group 1.
	custom2 	p 		Custom Group 2.
	custom3 	q 		Custom Group 3.
	custom4 	r 		Custom Group 4.
	custom5 	s 		Custom Group 5.
	custom6 	t 		Custom Group 6.
*/

public OnPluginStart()
{
	CreateConVar("vip_mapvotes_version", WEIGHTED_MAPVOTES_VERSION, "VIP Mapvotes", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hudText = CreateHudSynchronizer();
	if(hudText == INVALID_HANDLE) {
		LogMessage("HUD text is not supported on this mod. The persistant timer will not display.");
	} else {
		LogMessage("HUD text is supported on this mod. The persistant timer will display.");
	}

	// Haven't tested sm_cancelvoting yet, but went ahead and implemented it anyhow.
	RegAdminCmd("sm_cancelvoting", CancelMapVoting, ADMFLAG_ROOT, "Cancel Map Vote");
	RegAdminCmd("sm_init", Command_init, ADMFLAG_ROOT, "Initialize Map Vote command after cancel");

	RegAdminCmd("sm_reloadconfig", Command_ReloadConfiguration, ADMFLAG_ROOT, "Reloads vip_mapvotes.ini");

	RegConsoleCmd("say",MapVoteTrigger_SayCommand);
	RegConsoleCmd("say_team",MapVoteTrigger_SayCommand);

	RegConsoleCmd("sm_revote", Command_ReVote);

	g_hCanTriggerMapVotesFlags = CreateArray(32);

	g_hAdminFlags = CreateArray(1);
	g_hAdminFlagsPoints = CreateArray(1);

	g_hNamesBeginWith = CreateArray(16);
	g_hNamesBeginWithPoints = CreateArray(1);

	g_hNamesContain = CreateArray(16);
	g_hNamesContainPoints = CreateArray(1);

	g_hMapNames = CreateArray(32);
	g_hMapNamesPoints = CreateArray(1);

	g_hMapVotingCommands = CreateArray(16);

	// Do not remove, as I plan to add the adjustable features:

	h_LogsEnabledCvar=CreateConVar("vip_mapvotes_logs","1","Keep logs of everything. (default 1 = on)");
	//VIPFlagsCvar=CreateConVar("vip_mapvotes_time_start","1300","The votes can be done between start and end values");
	//VIPFlagsCvar=CreateConVar("vip_mapvotes_time_end","2200","The votes can be done between start and end values");
	h_VIP_voting_allowed_time_Cvar=CreateConVar("vip_mapvotes_voting_allowed_time","10","The amount of minutes left on map when !mapvote can be triggered. (0 = disabled) (default 10)");
	h_VIP_Map_Vote_Timer_Warning_Cvar=CreateConVar("vip_mapvotes_vote_timer_warning","2","The number of warnings that will let a vip know they can place a map vote (0 = disabled) (default 2)");
	h_VIP_Map_Timelimit_Cvar=CreateConVar("vip_mapvotes_map_timelimit","20","The Number of minutes to set a map for when the map is changed to the map voted by VIP MAPVOTES. (0 = disabled) (default 20)");
	//VIPFlagsCvar=CreateConVar("vip_mapvotes_votes_to_chat","0","Votes will be sent to chat for everyone to see.  Default 0 (off)");
	//VIPFlagsCvar=CreateConVar("vip_mapvotes_admin_can_drop_maps","z","Flags required to drop maps from being voted on.");
	h_VIPFlagsCvar=CreateConVar("vip_mapvotes_admin_can_see_vote_progress","c","Flags or Flag that is required to see voting progress. (default c)\nIf you want anyone to see it, use: anyone");

	h_vip_matvote_location=CreateConVar("vip_matvote_location","configs/vip_mapvotes.ini","default:\nconfigs/vip_mapvotes.ini\nOn our server the location ends up being:\ntf2/tf/addons/sourcemod/configs/vip_mapvotes.ini");

	//h_PrintTallyDetail=CreateConVar("vip_print_tally_detail","0","To allow everyone to see how the votes are tallied\n0 enabled / 1 disabled");

	// TO DO.. create a reload command for ParseFile();
	init();
	ParseFile();

	CreateTimer(60.0, CheckMapTime, INVALID_HANDLE, TIMER_REPEAT);
}

VipMapVotesIncludeClientNameLogs(client, const String:reason[]="", any:...)
{
	decl String:LogThis[2048];
	VFormat(LogThis, sizeof(LogThis), reason, 2);

	if(ValidPlayer(client))
	{
		new String:sClientName[128];
		GetClientName(client,sClientName,sizeof(sClientName));
		Format(LogThis, sizeof(LogThis), "%s %s", sClientName, LogThis);
	}

	VipMapVoteLogs(LogThis);
}

VipMapVoteLogs(const String:reason[]="", any:...)
{
	if(!GetConVarBool(h_LogsEnabledCvar))
	{
		return;
	}
	new String:szFile[256];

	decl String:LogThis[2048];
	VFormat(LogThis, sizeof(LogThis), reason, 2);

	Format(LogThis, sizeof(LogThis), "[VIPMAPVOTES] %s", LogThis);

	BuildPath(Path_SM, szFile, sizeof(szFile), "logs/vip_mapvotes.log");
	LogToFile(szFile, LogThis);
}

init()
{
	for(new x = 0; x < 5; x++)
	{
		VIPChoosenMapsPicked[x]=-999;
	}
	VIPMapCount=0;
	timeRemaining=30;
	for(new i=0;i<MAXPLAYERS+1;i++)
	{
		VOTES[i]=-1;
	}
}

public Action:CheckMapTime(Handle:timer)
{
	if(MapVoteTimerWarning>=GetConVarInt(h_VIP_Map_Vote_Timer_Warning_Cvar) || VIPMapStarter!=-1)
	{
		return Plugin_Continue;
	}
	new MapTimeLeft;
	GetMapTimeLeft(MapTimeLeft);

	new VIP_voting_allowed_time = GetConVarInt(h_VIP_voting_allowed_time_Cvar);

	if(VIP_voting_allowed_time<=0)
	{
		return Plugin_Continue;
	}

	TimeLeftOnMapBeforePlayerCanVote = VIP_voting_allowed_time*60;

	decl String:TmpStr[16];

	if(MapTimeLeft<=TimeLeftOnMapBeforePlayerCanVote && MapVoteTimerWarning<GetConVarInt(h_VIP_Map_Vote_Timer_Warning_Cvar))
	{
		MapVoteTimerWarning++;

		for(new client=1;client<=MaxClients;client++)
		{
			if(ValidPlayer(client) && !IsFakeClient(client))
			{
				new HasAccess=HasFlagsAccess(client,g_hCanTriggerMapVotesFlags);
				if(HasAccess!=-1)
				{
					for(new i = 0; i < GetArraySize(g_hMapVotingCommands); i++)
					{
						GetArrayString(g_hMapVotingCommands, i, TmpStr, sizeof(TmpStr));
						PrintToChat(client,"You can now use the map voting chat command: %s",TmpStr);
					}
					EmitSoundToClient(client,ALERT_SOUND);
				}
			}
		}
	}
	return Plugin_Continue;
}

public OnMapStart()
{
	VIPMapStarter=-1;
	MapVoteTimerWarning=0;
	new String:CurrentMapIs[32];
	GetCurrentMap(CurrentMapIs, sizeof(CurrentMapIs));
	if(strcmp(CurrentMapIs, MapWinningName) == 0)
	{
		if(GetConVarInt(h_VIP_Map_Timelimit_Cvar)>0)
		{
			ServerCommand("mp_timelimit %d",GetConVarInt(h_VIP_Map_Timelimit_Cvar));
		}
		strcopy(MapWinningName, sizeof(MapWinningName), "");
	}
}

public Action:Command_ReloadConfiguration(client, args)
{
	if(ValidPlayer(client))
	{
	}
}

public Action:Command_init(client, args)
{
	if(ValidPlayer(client))
	{
		init();
		VIPMapStarter=-1;
		MapVoteTimerWarning=0;
		strcopy(MapWinningName, sizeof(MapWinningName), "");
		PrintToChat(client,"Init is now done.");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_ReVote(client, args)
{
	if(VoteTimer!=INVALID_HANDLE)
	{
		if(ValidPlayer(client))
		{
			ShowMaps(client,false);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:CancelMapVoting(client,args)
{
	VoteTimer = INVALID_HANDLE;
	init();
}
bool:CanSeeVoteProgress(client)
{
	new String:requiredflagstr[32];
	GetConVarString(h_VIPFlagsCvar, requiredflagstr, sizeof(requiredflagstr));

	if(StrEqual(requiredflagstr,"anyone")) return true;

	new flag = ReadFlagString(requiredflagstr);

	new flags = GetUserFlagBits(client);
	//DP("flags %d",flags);
	if (flags & (flag | ADMFLAG_ROOT)) //ADMFLAG_ROOT is "z"
	{
		return true;
	}

	return false;
}

/**
 * Checks to see if a client has all of the specified admin flags
 *
 * @param client        Player's index.
 * @param flagString    String of flags to check for.
 * @return                True on admin having all flags, false otherwise.
 *
 * by bl4nk
 * https://forums.alliedmods.net/showthread.php?t=98947
 */
stock bool:CheckAdminFlagsByString(client, const String:flagString[])
{
	new AdminId:admin = GetUserAdmin(client);
	if (admin != INVALID_ADMIN_ID)
	{
		new count, found, flags = ReadFlagString(flagString);
		for (new i = 0; i <= 20; i++)
		{
			if (flags & (1<<i))
			{
				count++;

				if (GetAdminFlag(admin, AdminFlag:i))
				{
					found++;
				}
			}
		}

		if (count == found)
		{
			return true;
		}
	}

	return false;
}

HandleStringContains(Handle:handleString, String:SearchString[32])
{
	decl String:TmpStr[32];
	for(new i = 0; i < GetArraySize(handleString); i++)
	{
		GetArrayString(handleString, i, TmpStr, sizeof(TmpStr));
		if(StrEqual(TmpStr,SearchString)) return i;
	}
	return -1;

}

HasFlagsAccess(client, Handle:handleString)
{
	decl String:TmpStr[32];
	for(new i = 0; i < GetArraySize(handleString); i++)
	{
		GetArrayString(handleString, i, TmpStr, sizeof(TmpStr));
		if(StrEqual("anyone",TmpStr)) return i;
		if(CheckAdminFlagsByString(client,TmpStr)) return i;
	}
	return -1;

}

StartTimer()
{
	VoteTimer = CreateTimer(1.0, DoVoteTimer, INVALID_HANDLE, TIMER_REPEAT);
}

stock DP(const String:szMessage[], any:...)
{

	decl String:szBuffer[1000];

	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);
	PrintToChatAll("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);

}

stock AStrToLower(String:buffer[])
{
	new len = strlen(buffer);
	for(new i = 0; i < len; i++)
	{
		buffer[i] = CharToLower(buffer[i]);
	}
}

bool:KvGetYesOrNo(Handle:kv, const String:key[], bool:curdefault)
{
	decl String:value[12];
	KvGetString(kv, key, value, sizeof(value), curdefault ? "yes" : "no");
	return (strcmp(value, "yes") == 0);
}

bool:ValidPlayer(client)
{
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

public Action:MapVoteTrigger_SayCommand(client,args)
{
	if(!ValidPlayer(client))
	{
		return Plugin_Handled;
	}

	// replytocommand does not work here for some reason,
	// so i'm using PrintToChat !!

	decl String:arg1[32], String:TmpStr[32];
	GetCmdArg(1,arg1,sizeof(arg1));

	//DP("GetCmdArg:%s",arg1);

	if(StrContains(arg1,"dumpcommands")==0)
	{
		for(new i = 0; i < GetArraySize(g_hMapVotingCommands); i++)
		{
			GetArrayString(g_hMapVotingCommands, i, TmpStr, sizeof(TmpStr));
			VipMapVoteLogs("g_hMapVotingCommands = %s",TmpStr);
		}

		PrintToChat(client, "Dumpped commands into log file.");
		return Plugin_Handled;
	}

	if(HandleStringContains(g_hMapVotingCommands, arg1)>-1)
	{
		if(GetClientOfUserId(VIPMapStarter)!=client && VIPMapStarter!=-1)
		{
			PrintToChat(client, "Another player has already set a map.  Try again next map.");
			return Plugin_Handled;
		}

		if(VoteTimer!=INVALID_HANDLE)
		{
			PrintToChat(client, "Voting is in progress. Try again later.");
			return Plugin_Handled;
		}

		new HasAccess=HasFlagsAccess(client,g_hCanTriggerMapVotesFlags);
		if(HasAccess==-1)
		{
			PrintToChat(client, "You do not have access to this feature.");
			return Plugin_Handled;
		}
		//else
		//{
			//new String:sTmpStr[128];
			//GetArrayString(g_hCanTriggerMapVotesFlags, HasAccess, sTmpStr, sizeof(sTmpStr));
			//DP("g_hCanTriggerMapVotesFlags %s",sTmpStr);
		//}

		new CurrentMapTimeLeft;
		GetMapTimeLeft(CurrentMapTimeLeft);
		//DP("TimeLeft on Map %d",CurrentMapTimeLeft);

		if(CurrentMapTimeLeft>TimeLeftOnMapBeforePlayerCanVote)
		{
			//new days=RoundToFloor(TimeLeftOnMapBeforePlayerCanVote/86400.0);
			//new hours=RoundToFloor((TimeLeftOnMapBeforePlayerCanVote % 86400 )/3600.0) ;
			new minutes=RoundToFloor((TimeLeftOnMapBeforePlayerCanVote % 86400 % 3600) / 60.0);
			new seconds=TimeLeftOnMapBeforePlayerCanVote % 86400 % 3600 % 60;

			PrintToChat(client, "You must wait until the map time is less than %d minutes and %d seconds.",minutes,seconds,TimeLeftOnMapBeforePlayerCanVote);

			new days=RoundToFloor(CurrentMapTimeLeft/86400.0);
			new hours=RoundToFloor((CurrentMapTimeLeft % 86400 )/3600.0) ;
			minutes=RoundToFloor((CurrentMapTimeLeft % 86400 % 3600) / 60.0);
			seconds=CurrentMapTimeLeft % 86400 % 3600 % 60;

			PrintToChat(client,"Current time left on map is: %d days, %d hours, %d minutes, and %d seconds",days,hours,minutes,seconds);
			return Plugin_Handled;
		}


		VIPMapStarter=GetClientUserId(client);
		VipMapVotesIncludeClientNameLogs(client," started a vipmapvote command.");
		init();
		ShowMaps(client,true);
	}
	return Plugin_Continue;
}

AddStringNumber(Handle:handleString, const String:key[], Handle:handlePoints, iPoints)
{
	new String:TmpStr[32];
	for(new i = 0; i < GetArraySize(handleString); i++)
	{

		GetArrayString(handleString, i, TmpStr, sizeof(TmpStr));
		// If duplicate, overwrite
		if(strcmp(TmpStr, key) == 0)
		{
			SetArrayCell(handlePoints, i, iPoints);
			return i;
		}
	}
	PushArrayString(handleString, key);
	PushArrayCell(handlePoints, iPoints);
	//DP("String: %s Number: %d",key,iPoints);

	return -1;
}

AddStringOnly(Handle:handleString, const String:key[])
{
	new String:TmpStr[32];
	for(new i = 0; i < GetArraySize(handleString); i++)
	{

		GetArrayString(handleString, i, TmpStr, sizeof(TmpStr));
		// If duplicate, return
		if(strcmp(TmpStr, key) == 0)
		{
			return i;
		}
	}
	new String:sTmpStr[32];
	strcopy(sTmpStr, sizeof(sTmpStr), key);
	TrimString(sTmpStr);
	AStrToLower(sTmpStr);

	PushArrayString(handleString, sTmpStr);
	//DP("String: %s",key);

	return -1;
}

bool:ParseFile()
{
	decl String:path[1024],String:vip_map_file_path[1024];

	GetConVarString(h_vip_matvote_location, vip_map_file_path, sizeof(vip_map_file_path));

	BuildPath(Path_SM,path,sizeof(path),vip_map_file_path);

	/* Return true if an update was available. */
	new Handle:kv = CreateKeyValues("AwesomeSettings");

	if (!FileToKeyValues(kv, path))
	{
		CloseHandle(kv);
		return false;
	}

	ClearArray(g_hCanTriggerMapVotesFlags);
	ClearArray(g_hMapVotingCommands);
	ClearArray(g_hAdminFlags);
	ClearArray(g_hAdminFlagsPoints);
	ClearArray(g_hNamesBeginWith);
	ClearArray(g_hNamesBeginWithPoints);
	ClearArray(g_hNamesContain);
	ClearArray(g_hNamesContainPoints);
	ClearArray(g_hMapNames);
	ClearArray(g_hMapNamesPoints);

	new String:sBuffer[32];

	if (KvJumpToKey(kv, "CanTriggerMapVote"))
	{
		// Import Admin Flags that can trigger map votes
		if (KvGotoFirstSubKey(kv, false))
		{
			do
			{
				KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
				// if yes
				if(KvGetYesOrNo(kv, NULL_STRING,false))
				{
					AddStringOnly(g_hCanTriggerMapVotesFlags, sBuffer);
				}
			} while (KvGotoNextKey(kv, false));
			KvGoBack(kv);
		}

		KvGoBack(kv);
	}
	//DP("g_sCanTriggerMapVotesFlags %s",g_sCanTriggerMapVotesFlags);

	if (KvJumpToKey(kv, "MapVotingCommands"))
	{
		// Import Admin Flags that can trigger map votes
		if (KvGotoFirstSubKey(kv, false))
		{
			do
			{
				KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
				// if yes
				if(KvGetYesOrNo(kv, NULL_STRING,false))
				{
					AddStringOnly(g_hMapVotingCommands, sBuffer);
				}
			} while (KvGotoNextKey(kv, false));
			KvGoBack(kv);
		}

		KvGoBack(kv);
	}

	if (KvJumpToKey(kv, "AdminFlags"))
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			do
			{
				KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
				new iPoints = KvGetNum(kv, NULL_STRING, 0);
				AddStringNumber(g_hAdminFlags,sBuffer,g_hAdminFlagsPoints,iPoints);

			} while (KvGotoNextKey(kv, false));
			KvGoBack(kv);
		}

		KvGoBack(kv);
	}

	if (KvJumpToKey(kv, "NamesBeginWith"))
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			do
			{
				KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
				new iPoints = KvGetNum(kv, NULL_STRING, 0);
				AddStringNumber(g_hNamesBeginWith,sBuffer,g_hNamesBeginWithPoints,iPoints);

			} while (KvGotoNextKey(kv, false));
			KvGoBack(kv);
		}

		KvGoBack(kv);
	}

	if (KvJumpToKey(kv, "NamesContain"))
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			do
			{
				KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
				new iPoints = KvGetNum(kv, NULL_STRING, 0);
				AddStringNumber(g_hNamesContain,sBuffer,g_hNamesContainPoints,iPoints);

			} while (KvGotoNextKey(kv, false));
			KvGoBack(kv);
		}

		KvGoBack(kv);
	}

	if (KvJumpToKey(kv, "MapPool"))
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			do
			{
				KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
				new iPoints = KvGetNum(kv, NULL_STRING, 0);
				AddStringNumber(g_hMapNames,sBuffer,g_hMapNamesPoints,iPoints);

			} while (KvGotoNextKey(kv, false));
			KvGoBack(kv);
		}

		KvGoBack(kv);
	}

	CloseHandle(kv);

	return true;
}

EveryoneStartVoting()
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client))
		{
			ShowMaps(client,false);
		}
	}
}


ShowMaps(client,bool:VotingMapChooseStarter)
{
	new Handle:MapMenu;
	if(VotingMapChooseStarter)
	{
		MapMenu=CreateMenu(MapSelected);
	}
	else
	{
		MapMenu=CreateMenu(ShowSingleVoteMapSelected);
	}
	SetMenuExitButton(MapMenu,true);
	if(VotingMapChooseStarter)
	{
		SetMenuTitle(MapMenu,"Choose a Map:",client);
	}
	else
	{
		SetMenuTitle(MapMenu,"Vote for a Map:",client);
	}
	decl String:MapNameStr[32];
	decl String:numstr[4];

	new bool:found=false;

	if(VotingMapChooseStarter==false)
	{
		AddMenuItem(MapMenu,"-10","Random",ITEMDRAW_DEFAULT);
	}

	for(new i = 0; i < GetArraySize(g_hMapNames); i++)
	{
		GetArrayString(g_hMapNames, i, MapNameStr, sizeof(MapNameStr));
		// Keep IntToString
		IntToString(i,numstr,sizeof(numstr));
		found=false;
		for(new x = 0; x < 5; x++)
		{
			if(VIPChoosenMapsPicked[x]==i)
			{
				found=true;
				break;
			}
		}

		if(VotingMapChooseStarter==true)
		{
			if(found==false)
			{
				AddMenuItem(MapMenu,numstr,MapNameStr,ITEMDRAW_DEFAULT);
			}
			else
			{
				AddMenuItem(MapMenu,numstr,MapNameStr,ITEMDRAW_DISABLED);
			}
		}
		else if(VotingMapChooseStarter==false && found==true)
		{
			// display to voters
			AddMenuItem(MapMenu,numstr,MapNameStr,ITEMDRAW_DEFAULT);
		}

		//PrintToChat(client,"%d %s",i,MapNameStr);
	}

	if(VotingMapChooseStarter==false)
	{
		AddMenuItem(MapMenu,"-20","No Vote",ITEMDRAW_DEFAULT);
	}

	if(VotingMapChooseStarter)
	{
		DisplayMenu(MapMenu,client,MENU_TIME_FOREVER);
	}
	else
	{
		DisplayMenu(MapMenu,client,60);
	}
}

public MapSelected(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		decl String:SelectionInfo[4];
		decl String:SelectionDispText[256];
		new SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		new itemnum=StringToInt(SelectionInfo);

		if(VIPMapCount<4) // 0 thru 4 = 5
		{
			VIPChoosenMapsPicked[VIPMapCount]=itemnum;
			VIPMapCount++;
			PrintToChat(client,"You have %d maps left to pick.",5-VIPMapCount);
			ShowMaps(client,true);
			return;
		}

		VIPChoosenMapsPicked[VIPMapCount]=itemnum;

		StartTimer();

		//PrintToChat(client,"Everyone Vote Now");
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

GetMapVoteName(iNum,String:ReturnStr[32])
{
	//new String:sTmpStr3[32];
	if(iNum<0 || iNum>4)
		return;

	new TheMagicNumber=VIPChoosenMapsPicked[iNum];
	GetArrayString(g_hMapNames, TheMagicNumber, ReturnStr, sizeof(ReturnStr));
}

public ShowSingleVoteMapSelected(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		decl String:SelectionInfo[4];
		decl String:SelectionDispText[256];
		new SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		new itemnum=StringToInt(SelectionInfo);

		if(itemnum==-20) // no vote
		{
			VOTES[client]=-1;
			PrintToChat(client,"You Picked No Vote.");
		}
		else if(itemnum==-10) // random
		{
			new RandNumBer=VIPChoosenMapsPicked[GetRandomInt(0,4)];
			VOTES[client]=RandNumBer;
			new String:sTmpStr[32];
			GetMapVoteName(RandNumBer,sTmpStr);
			PrintToChat(client,"You Random Picked %s",sTmpStr);
		}
		else
		{
			VOTES[client]=itemnum;
			new String:sTmpStr[32];
			GetMapVoteName(itemnum,sTmpStr);
			PrintToChat(client,"You Picked %s",sTmpStr);
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

TallyMapVotes(changeNum)
{
	new Votes=0;

	new iNum=VIPChoosenMapsPicked[changeNum];

	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i) && !IsFakeClient(i) && VOTES[i]==iNum)
		{
			Votes++;
			Votes+=TallyMapVotesBonus(iNum);
			//DP("client %d vote %d",i,Votes);
			Votes+=TallyAdminFlagsVoteBonus(i);
			//DP("client %d vote %d",i,Votes);
			Votes+=TallyNamesBeginWith(i);
			//DP("client %d vote %d",i,Votes);
		}
	}
	return Votes;
}

TallyNamesBeginWith(client)
{
	decl String:TmpStr[32],String:NameTmpStr[32];

	GetClientName(client,NameTmpStr,sizeof(NameTmpStr));

	for(new i = 0; i < GetArraySize(g_hNamesBeginWith); i++)
	{
		GetArrayString(g_hNamesBeginWith, i, TmpStr, sizeof(TmpStr));
		if(StrContains(NameTmpStr,TmpStr)==0) return GetArrayCell(g_hNamesBeginWithPoints, i);
	}
	return 0;
}

TallyMapVotesBonus(iNum)
{
	//new TheMagicNumber=VIPChoosenMapsPicked[iNum];
	return GetArrayCell(g_hMapNamesPoints, iNum);
}

TallyAdminFlagsVoteBonus(client)
{
	new iFlags=HasFlagsAccess(client, g_hAdminFlags);
	if(iFlags>-1)
	{
		return GetArrayCell(g_hAdminFlagsPoints, iFlags);
	}
	return 0;
}

public Action:TallyVotesTimer(Handle:timer)
{
	TallyVotes();
	return Plugin_Stop;
}

public Action:DoVoteTimer(Handle:timer)
{
	timeRemaining--;
	if(timeRemaining <= -1)
	{
		CreateTimer(1.0, TallyVotesTimer, INVALID_HANDLE);
		if(VoteTimer!=INVALID_HANDLE)
		{
			VoteTimer = INVALID_HANDLE;
		}
		return Plugin_Stop;
	}
	if(timeRemaining / 30 <= 1)
	{
		if(hudText != INVALID_HANDLE)
		{
			new String:Map0[32],String:Map1[32],String:Map2[32],String:Map3[32],String:Map4[32];
			GetMapVoteName(0,Map0);
			GetMapVoteName(1,Map1);
			GetMapVoteName(2,Map2);
			GetMapVoteName(3,Map3);
			GetMapVoteName(4,Map4);
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!ValidPlayer(i) || IsFakeClient(i))
				{
					continue;
				}
				PrintHintText(i,"...Map Voting in progress...");
				if(!CanSeeVoteProgress(i))
				{
					//DP("can not see vote progress");
					continue;
				}
				SetHudTextParams(-1.0, -1.0, 1.0, 0, 255, 0, 255);
				ShowSyncHudText(i, hudText, "Voting Point System | Time Remaining: %i:%02i\n %s (%d)\n %s (%d)\n %s (%d)\n %s (%d)\n %s (%d)", timeRemaining / 60, timeRemaining % 60,
				Map0,TallyMapVotes(0),
				Map1,TallyMapVotes(1),
				Map2,TallyMapVotes(2),
				Map3,TallyMapVotes(3),
				Map4,TallyMapVotes(4));
			}
		}
		if(timeRemaining % 60 == 29)
		{
			EmitSoundToAll(ALERT_SOUND);
			EveryoneStartVoting();
			//for(new i = 0; i <= MaxClients; i++)
			//{
				//if(ValidPlayer(i) && !IsFakeClient(i))
				//{
					//PlayersVoteMenu(i);
				//}
			//}
		}
		if(timeRemaining % 60 == 20)
		{
			PrintHintTextToAll("You now have %02i seconds.\nYou can redo your vote by typing !revote", timeRemaining % 60);
			//EmitSoundToAll(ALERT_SOUND);
		}
		if(timeRemaining % 60 == 10)
		{
			PrintHintTextToAll("You now have %02i seconds.\nYou can redo your vote by typing !revote", timeRemaining % 60);
			//EmitSoundToAll(ALERT_SOUND);
		}
		if(timeRemaining % 60 == 5)
		{
			PrintHintTextToAll("You now have %02i seconds.\nYou can redo your vote by typing !revote", timeRemaining % 60);
			//EmitSoundToAll(ALERT_SOUND);
		}
	}
	return Plugin_Continue;
}

TallyVotes()
{
	if(hudText != INVALID_HANDLE)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(ValidPlayer(i) && !IsFakeClient(i))
			{
				SetHudTextParams(-1.0, -1.0, 2.0, 255, 0, 0, 255);
				ShowSyncHudText(i, hudText, "Tallying Votes");
			}
		}
	}

	EmitSoundToAll(ALERT_SOUND);

	new iNumber[5];

	// Could possibly use a for statement to do below...
	// just haven't checked it completely yet.
	//for(new x = 0; x < 5; x++)
	//{
		//iNumber[x]=TallyMapVotes(x);
	//}
	iNumber[0]=TallyMapVotes(0);
	iNumber[1]=TallyMapVotes(1);
	iNumber[2]=TallyMapVotes(2);
	iNumber[3]=TallyMapVotes(3);
	iNumber[4]=TallyMapVotes(4);

	SortIntegers(iNumber, 5,Sort_Descending);

	new HighestNumber = iNumber[0];

	//Find Map
	for(new x = 0; x < 5; x++)
	{
		if(TallyMapVotes(x)==HighestNumber)
		{
			// CHANGE MAP TO #X
			GetMapVoteName(x,MapWinningName);
			break;
		}
	}
	if(hudText != INVALID_HANDLE)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(ValidPlayer(i) && !IsFakeClient(i))
			{
				SetHudTextParams(-1.0, -1.0, 5.0, 255, 0, 0, 255);
				ShowSyncHudText(i, hudText, "Nextmap set to %s",MapWinningName);
			}
		}
	}
	SetNextMap(MapWinningName);
	PrintToChatAll("Nextmap set to %s",MapWinningName);
	VipMapVoteLogs("Nextmap set to %s",MapWinningName);

	// Future Support:

	//CreateTimer(5.0, DoMapChange, 0);
}

//public Action:DoMapChange(Handle:Timer, any:Particle)
//{
	// To Do:  Future support of allowing the option to change maps immediately instead
	// of waiting for the end of a map time.

	//new String:sStringName[32],String:sReason[32];
	//GetClientName(GetClientOfUserId(VIPMapStarter),sStringName,sizeof(sStringName));
	//Format(sReason, sizeof(sReason), "Votemap by %s",sStringName);
	//ForceChangeLevel(MapWinningName, sReason);
//}
