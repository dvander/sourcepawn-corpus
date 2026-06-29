/********************************************************************************************
* Plugin	: l4d_profile_checker
* Version	: 1.2
* Game	    : Left4Dead & Left4Dead 2
* Author	: Sheleu
* Testers	: Myself and Aquarius (Ja-Forces)

* Version 1.0 (29.10.10)
*		-  Initial release
* Version 1.1 (01.11.10)
*		-  Changed message to player who kicked
*		-  Changed config
* Version 1.1a (02.11.10)
*		-  Fixed bug with searching HoursPlayed2Wk in profile
* Version 1.1b (07.11.10)
* 		-  Fixed error with call function "GetClientName" when client is not connected
* Version 1.1c (07.11.10)
* 		-  Remove recheck client
* Version 1.2 (22.11.10)
* 		-  Fixed error with kick when long receive profile
* 		-  Added whitelist
*********************************************************************************************/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <socket>

#define PLUGIN_TAG	        "[l4d_profile_checker]"
#define PLUGIN_VERSION      "1.2"
#define MAX_CRITERIONS      8
#define MAX_LEN_STRING      128
#define MAX_LEN_BUFFER      7168

#define DEBUG 1

static const String: listCriterionsNames[][] = {"steamID","visibilityState","avatarIcon","vacBanned","steamRating","hoursPlayed2Wk","hoursPlayed","hoursOnRecord"};
static const String: listCriterionsDescription[][] =
{
	"VisibilityState:\nCheck the profile for visibility. Available values are: '&' or '|'; 1 (for friends state and public) 2 (public) \"\" (not checked)",
	"AvatarIcon:\nChecking profile on the presence of avatar. 1 (check) 2 (check, if not positive kick) \"\" (not checked)",
	"VacBanned:\nCheck the profile of ban by VAC. 1 (check) 2 (check, if not positive kick) \"\" (not checked)",
	"SteamRating:\nCheck the profile of steam's rating. Available values are: '&' or '|'; numerical value, \"\" (not checked)",
	"HoursPlayed2Wk:\nCheck the game for 2 weeks. Available values are: '&' or '|'; numerical value, \"\" (not checked)",
	"HoursPlayed:\nChecking for number of hours in this game. Available values are: '&' or '|'; numerical value, \"\" (not checked)",
	"HoursOnRecord:\nCheck the total number of hours in this game. Available values are: '&' or '|'; numerical value, \"\" (not checked)"	
};
static const String: listCriterionsValue[][] = {"|1","1","1","|5","|30","|25","&250"};
static const String: listCriterionsRealValue[][] = {"f&[empty]","","/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb.jpg","<",">",">",">",">"};

new Handle: WhiteList = INVALID_HANDLE; // Version 1.2
new Handle: g_hCvarWhiteList; // Version 1.2
new Handle: g_hCvarCriterionsValues[MAX_CRITERIONS-1];
new String: sCriterionsNames[MAX_CRITERIONS][MAX_LEN_STRING];
new String: sCriterionsValues[MAX_CRITERIONS][MAX_LEN_STRING];
new String: ClientsID[MAXPLAYERS + 1][MAX_LEN_STRING]; // Version 1.1c
new String: sBase[] = "76561197960265728";
new String: g_Filename[PLATFORM_MAX_PATH]; // Version 1.2
new bool: L4D2Version;
new bool: KickedClient;

public Plugin: myinfo = 
{
	name = "l4d_profile_checker",
	author = "Sheleu",
	description = "Kicked players who failed steam's profile checker",
	version = PLUGIN_VERSION
};

public OnPluginStart()
{	
	KickedClient = false;
	RegConsoleCmd("sm_profile_checker", sm_checkProfile, "Profile Checker", FCVAR_PLUGIN); // Version 1.2
	RegAdminCmd("sm_profile_whitelist_add", sm_checkProfileWhitelistAdd, ADMFLAG_ROOT, "Add in white list"); // Version 1.2 
	RegAdminCmd("sm_profile_whitelist_del", sm_checkProfileWhitelistDel, ADMFLAG_ROOT, "Delete from white list"); // Version 1.2
	CreateCriterions();
	ChangeCriterions();
	AutoExecConfig(true, "l4d_profile_checker");
	HookEvent("finale_win", Event_FinaleWin); // Version 1.1c
	ReadWhiteList(); // Version 1.2
}

public OnPluginEnd() // Version 1.2
{
	ClearArray(WhiteList);
}

public APLRes: AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains(GameName, "left4dead", false) == -1)
		return APLRes_Failure; 	
	if (StrEqual(GameName, "left4dead2", false))
		L4D2Version = true;
	else L4D2Version = false;
	return APLRes_Success; 
}

public Action: Event_FinaleWin(Handle:event, const String:name[], bool:dontBroadcast) // Version 1.1c
{
	for (new i = 0; i <= MAXPLAYERS; i++)
		Format(ClientsID[i], MAX_LEN_STRING, " ");
}

public ConVarCriterions(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ChangeCriterions();
}

public ConVarWhiteList(Handle:convar, const String:oldValue[], const String:newValue[]) // Version 1.2
{
	ClearArray(WhiteList);
	ReadWhiteList();
}

public Action: sm_checkProfile(client, args)
{
	if(args == 0)
	{
		PrintToChat(client, "Proper Usage (console): sm_profile_checker <steamid, playername>");
		PrintToChat(client, "Proper Usage (chat): !profile_checker <steamid, playername>");		
		return Plugin_Handled;
	}
	decl String: arg[MAX_LEN_STRING], String: argID[MAX_LEN_STRING*2];
	GetCmdArgString(arg, MAX_LEN_STRING);	
	returnSteamID(client, arg, argID);	
	KickedClient = false;
	SaveXMLProfile(client, argID);		
	return Plugin_Handled;
}

public Action: sm_checkProfileWhitelistAdd(client, args) // Version 1.2
{
	if (GetConVarInt(g_hCvarWhiteList) > 0)
	{		
		if(args == 0)
		{		
			PrintToChat(client, "Proper Usage (console): sm_profile_whitelist_add <steamID, communityID, playerName>");
			PrintToChat(client, "Proper Usage (chat): !profile_whitelist_add <steamID, communityID, playerName>");	
			return Plugin_Handled;
		}
		new String: arg[MAX_LEN_STRING], String: addID[MAX_LEN_STRING*2], String: sAddFriendID[sizeof(sBase)];	
		GetCmdArgString(arg, MAX_LEN_STRING);
		if ((strlen(arg) == strlen(sBase)) && (StrContains(arg, "765611", false) == 0))
			Format(sAddFriendID, sizeof(sBase), "%s", arg);
		else
		{			
			returnSteamID(client, arg, addID);	
			GetFriendID(addID, sAddFriendID);
		}
		AddToWhiteList(sAddFriendID);		
	}
	return Plugin_Handled;
}

public Action: sm_checkProfileWhitelistDel(client, args) // Version 1.2
{
	if (GetConVarInt(g_hCvarWhiteList) > 0)
	{		
		if(args == 0)
		{		
			PrintToChat(client, "Proper Usage (console): sm_profile_whitelist_del <steamID, communityID, playerName>");
			PrintToChat(client, "Proper Usage (chat): !profile_whitelist_del <steamID, communityID, playerName>");	
			return Plugin_Handled;
		}
		new String: arg[MAX_LEN_STRING], String: delID[MAX_LEN_STRING*2], String: sDelFriendID[sizeof(sBase)];	
		GetCmdArgString(arg, MAX_LEN_STRING);	
		if ((strlen(arg) == strlen(sBase)) && (StrContains(arg, "765611", false) == 0))
			Format(sDelFriendID, sizeof(sBase), "%s", arg);
		else
		{			
			returnSteamID(client, arg, delID);	
			GetFriendID(delID, sDelFriendID);
		}
		DelFromWhiteList(sDelFriendID);
	}
	return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
	new String: checkID[MAX_LEN_STRING];	
	if (!IsFakeClient(client))
	{		
		GetClientAuthString(client, checkID, MAX_LEN_STRING);		
		if (!StrEqual(ClientsID[client], checkID)) // Version 1.1c
		{
			Format(ClientsID[client], MAX_LEN_STRING, "%s", checkID); // Version 1.1c
			KickedClient = true;		
			SaveXMLProfile(client, checkID);
		}
	}
}

public OnSocketConnected(Handle: hSocket, any: hPack) // Version 1.2
{
	decl String: requestStr[MAX_LEN_STRING], String: sLink[MAX_LEN_STRING];
	SetPackPosition(hPack, 16);
	new Handle: hLink = Handle:ReadPackCell(hPack);	
	ResetPack(hLink);
	ReadPackString(hLink, sLink, sizeof(sLink));
	#if DEBUG
	LogMessage("%s #DEBUG: link %s", PLUGIN_TAG, sLink);
	#endif	
	Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", sLink, "steamcommunity.com");
	SocketSend(hSocket, requestStr);
}

public OnSocketReceive(Handle: hSocket, String: receiveData[], const dataSize, any: hPack) 
{
	decl String: bf0[MAX_LEN_BUFFER], String: bf[MAX_LEN_BUFFER];
	SetPackPosition(hPack, 8);	
	new Handle: hData = Handle:ReadPackCell(hPack);			
	ResetPack(hData);
	if (IsPackReadable(hData, 1))
	{		
		ReadPackString(hData, bf0, sizeof(bf0));
		ResetPack(hData);
		Format(bf, sizeof(bf), "%s%s", bf0, receiveData);	
		WritePackString(hData, bf);
	}
	else WritePackString(hData, receiveData);
}

public OnSocketDisconnected(Handle: hSocket, any: hPack) 
{
	CloseHandle(hSocket);
	ResetPack(hPack);
	new client = ReadPackCell(hPack);
	new Handle: hData = Handle:ReadPackCell(hPack);
	ResetPack(hData);
	new idCheck;
	if ((idCheck = CheckProfile(hData, client)) > MAX_CRITERIONS)
	{
		#if DEBUG
		if (KickedClient) LogMessage("%s #DEBUG: client %i is authenticated!", PLUGIN_TAG, client);
		#endif					
		if (!KickedClient) PrintToChat(client, "Access granted!");
	}
	else if (idCheck > -1)
	{
		#if DEBUG			
		LogMessage("%s #DEBUG: client %i: idReasonKick = %i", PLUGIN_TAG, client, idCheck);
		#endif
		ActionIfNoob(KickedClient, client, idCheck);	
	}	
	else 
	{
		#if DEBUG
		if (KickedClient) LogMessage("%s #DEBUG: ERROR %i READ FILE: client %i", PLUGIN_TAG, idCheck, client);
		#endif			
		if (!KickedClient) PrintToChat(client, "Error %i", idCheck);
	}	
	CloseHandle(hData);
	CloseHandle(hPack);
}

public OnSocketError(Handle: hSocket, const errorType, const errorNum, any: hPack) 
{
	ResetPack(hPack); // Version 1.1c
	new client = ReadPackCell(hPack); // Version 1.1c
	Format(ClientsID[client], MAX_LEN_STRING, " "); // Version 1.1c
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(hPack);	
	CloseHandle(hSocket);
}

CreateCriterions() // Version 1.1
{
	new String: sNameConVar[MAX_LEN_STRING];
	for (new i = 0; i < (MAX_CRITERIONS-1); i++)
	{
		Format(sNameConVar, MAX_LEN_STRING, "l4d_profile_checker_%s", listCriterionsNames[i+1]);
		g_hCvarCriterionsValues[i] = CreateConVar(sNameConVar, listCriterionsValue[i], listCriterionsDescription[i], FCVAR_PLUGIN|FCVAR_SPONLY);
		HookConVarChange(g_hCvarCriterionsValues[i], ConVarCriterions);
	}	
	g_hCvarWhiteList = CreateConVar("l4d_profile_checker_whiteList", "1", "WhiteList:\nList of players, which profile isn't checked. 1 - use white list, 0 - not use white list", FCVAR_PLUGIN|FCVAR_SPONLY); // Version 1.2	
	HookConVarChange(g_hCvarWhiteList, ConVarWhiteList); // Version 1.2
}

ChangeCriterions() // Version 1.1
{
	new num = 1;
	new String: sConVar[MAX_LEN_STRING], String: sValue[MAX_LEN_STRING];
	//steamID
	Format(sCriterionsNames[0], MAX_LEN_STRING, "%s", listCriterionsNames[0]);
	Format(sCriterionsValues[0], MAX_LEN_STRING, "%s", listCriterionsRealValue[0]);
	//visibilityState
	ReadValueCriterion(listCriterionsNames[1], sConVar, sCriterionsNames[num]);
	if (strlen(sConVar) > 1)
	{
		Format(sValue, 3, ">%s", sConVar[0]);
		Format(sCriterionsValues[num], MAX_LEN_STRING, "%s%i", sValue, StringToInt(sConVar[1]));
		num++;
	}
	//avatarIcon
	ReadValueCriterion(listCriterionsNames[2], sConVar, sCriterionsNames[num]);	
	if (ChangeValue1AND2(listCriterionsRealValue[2], sConVar, sCriterionsValues[num], "f|%s", "f&%s")) num++;
	//vacBanned
	ReadValueCriterion(listCriterionsNames[3], sConVar, sCriterionsNames[num]);	
	if (ChangeValue1AND2(listCriterionsRealValue[3], sConVar, sCriterionsValues[num], "%s|1", "%s&1")) num++;
	//vacBanned, steamRating, hoursPlayed2Wk, hoursPlayed, hoursOnRecord
	for (new i = 4; i < MAX_CRITERIONS; i++)
	{
		ReadValueCriterion(listCriterionsNames[i], sConVar, sCriterionsNames[num]);
		if (strlen(sConVar) > 1)
		{			
			Format(sValue, MAX_LEN_STRING, "%s%s", listCriterionsRealValue[i], sConVar);						
			Format(sCriterionsValues[num], MAX_LEN_STRING, "%s", sValue);
			num++;
		}
	}
}

ReadWhiteList() // Version 1.2
{
	if (GetConVarInt(g_hCvarWhiteList) > 0)
	{
		WhiteList = CreateArray(MAX_LEN_STRING, 0);		
		BuildPath(Path_SM, g_Filename, sizeof(g_Filename), "configs/l4d_profile_checker_whitelist.txt");
		new Handle:file = OpenFile(g_Filename, "rt");
		if (file == INVALID_HANDLE)
		{		
			LogError("Could not open whitelist for read!");
			return;
		}
		while (!IsEndOfFile(file))
		{
			decl String: bfReadLine[sizeof(sBase)];
			if (!ReadFileLine(file, bfReadLine, sizeof(bfReadLine))) 
				break;
			if (bfReadLine[0] == '\0') 
				break;
			if (strlen(bfReadLine) == strlen(sBase))
			{
				PushArrayString(WhiteList, bfReadLine);						
				#if DEBUG
				LogMessage("%s #DEBUG: %s in white list", PLUGIN_TAG, bfReadLine);
				#endif
			}
		}
		#if DEBUG
		LogMessage("%s #DEBUG: size of white list = %i", PLUGIN_TAG, GetArraySize(WhiteList));
		#endif
		CloseHandle(file);
	}
}

ReadValueCriterion(String: sNameConVar[], String: sConVar[], String: sNameCriterion[])
{
	new String: sValue[MAX_LEN_STRING];
	Format(sValue, MAX_LEN_STRING, "l4d_profile_checker_%s", sNameConVar);
	GetConVarString(FindConVar(sValue), sConVar, MAX_LEN_STRING);
	Format(sNameCriterion, MAX_LEN_STRING, "%s", sNameConVar);
}

stock bool: ChangeValue1AND2(String: sNameRealValue[], String: sConVar[], String: sValueCriterion[], String: str1[], String: str2[])
{
	if (sConVar[0] == '1') 
	{				
		Format(sValueCriterion, MAX_LEN_STRING, str1, sNameRealValue, sConVar);
		return true;
	}
	else if (sConVar[0] == '2') 
	{				
		Format(sValueCriterion, MAX_LEN_STRING, str2, sNameRealValue, sConVar);		
		return true;
	}
	return false;
}

GetFriendID(String: sID[], String: sFriendID[])
{
	if(StrEqual(sID, "ID_LAN"))
	{
		sFriendID[0]='\0';
		return;
	}	
	new i0, i1, i2, iSum; 
	decl String: toks[3][16], String: sSum[3] = "0", String: s0[2] = "0", String: s1[2] = "0", String: s2[2] = "0";
	ExplodeString(sID, ":", toks, 3, 16);
	IntToString(StringToInt(toks[2]) * 2, toks[2], 16);	
	new iNum = strlen(sBase) - 1;
	new iDelta = iNum - strlen(toks[2]) + 1;		
	i0 = StringToInt(toks[1]);	
	while (iNum >= 0)
	{
		s0[0] = sBase[iNum];		
		i1 = StringToInt(s0);
		if (iNum >= iDelta)
		{
			s0[0] = toks[2][iNum - iDelta];			
			i2 = StringToInt(s0);
		}
		else i2 = 0;
		iSum = i0 + i1 + i2;
		IntToString(iSum, sSum, 3);
		if (iSum > 9)
		{
			s1[0] = sSum[1];			
			s2[0] = sSum[0];			
			i0 = StringToInt(s2);
		}
		else
		{
			s1[0] = sSum[0];			
			i0 = 0;
		}
		sFriendID[iNum] = s1[0];
		iNum--;
	}
	sFriendID[sizeof(sBase)-1]='\0';
	#if DEBUG
	LogMessage("%s #DEBUG: sFriendID %s", PLUGIN_TAG, sFriendID);
	#endif
}

SaveXMLProfile(client, String: arg[]) // Version 1.2
{	
	decl String: link[MAX_LEN_STRING*2], String: sID64[sizeof(sBase)];
	GetFriendID(arg, sID64);
	#if DEBUG	
	LogMessage("%s #DEBUG: begin search in whitelist %s", PLUGIN_TAG, sID64);
	#endif
	if (GetConVarInt(g_hCvarWhiteList) == 0 || FindStringInArray(WhiteList, sID64) == -1)
	{
		Format(link, sizeof(link), "profiles/%s/?xml=1", sID64);
		#if DEBUG
		LogMessage("%s #DEBUG: link %s", PLUGIN_TAG, link);		
		#endif	
		new Handle: hSocket = SocketCreate(SOCKET_TCP, OnSocketError);
		new Handle: hPack = CreateDataPack();
		new Handle: hData = CreateDataPack();
		new Handle: hLink = CreateDataPack();
		WritePackString(hLink, link);
		WritePackCell(hPack, client);
		WritePackCell(hPack, _:hData);
		WritePackCell(hPack, _:hLink);
		SocketSetArg(hSocket, hPack);	
		SocketConnect(hSocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "steamcommunity.com", 80);
	}
	else 
	{
		if (KickedClient)
		{
			#if DEBUG
			new String: _name[MAX_LEN_STRING*2];
			GetClientName(client, _name, MAX_LEN_STRING*2);			
			LogMessage("%s #DEBUG: %s (%s) is in white list", PLUGIN_TAG, sID64, _name);
			#endif
		}
		else PrintToChat(client, "%s is in white list!", sID64);
	}
}

stock CheckProfile(Handle: hData, client)
{
	decl String: bfLine[MAX_LEN_BUFFER];	
	new numCriterion = 0, countTrue = 0, pos, countNull = 0;	
	if (hData == INVALID_HANDLE)
	{
		#if DEBUG
		LogMessage("%s #DEBUG: could not read profile", PLUGIN_TAG);
		#endif
		return -1;
	}
	ReadPackString(hData, bfLine, sizeof(bfLine));
	if ((pos = StrContains(bfLine, "<Profile>", false)) >= 0)
	{
		pos += 9;				
		while (numCriterion < sizeof(sCriterionsValues) && strlen(sCriterionsNames[numCriterion]) > 0)
		{					
			switch (isCorrect(bfLine[pos], sCriterionsNames[numCriterion], sCriterionsValues[numCriterion], pos))
			{
				case -1: return numCriterion;				
				case 1:  countTrue++;
				case 2:  countNull++;
			}
			numCriterion++;
		}
		#if DEBUG
		if (countNull == 0) countNull++;
		LogMessage("%s #DEBUG: countTrue=%i, countNull=%i, sizeof(sCriterionsNames)=%i", PLUGIN_TAG, countTrue, countNull, numCriterion);
		#endif
		if (countTrue < (numCriterion - countNull))
		{			
			#if DEBUG
			LogMessage("%s #DEBUG: client %i is not authenticated", PLUGIN_TAG, client);				
			#endif			
			return MAX_CRITERIONS;
		}		
	}
	return MAX_CRITERIONS + 1;
}

stock isCorrect(String: bf[], String: sCriterion[], String: sStandart[], num)
{
	if (!StrEqual(sCriterion, "hoursOnRecord", false) && !StrEqual(sCriterion, "hoursPlayed", false)) // Version 1.1a
		return isCorrectValue(bf, sCriterion, sStandart, num);
	else
	{		
		new String: bfPart[MAX_LEN_BUFFER], String: _sStandart[MAX_LEN_STRING], pos = 0;
		if (StrContains(bf, "<visibilityState>3", false) > -1)
		{
			if ((pos = StrContains(bf, "<mostPlayedGames>", false)) > -1)
			{
				new String: _sCriterion[] = "gameName";			
				Format(bfPart, MAX_LEN_BUFFER, "%s", bf[pos]);			
				while ((pos = numStrContains(bfPart, false, "mostPlayedGame", "<%s>")) > -1)
				{
					Format(bfPart, MAX_LEN_BUFFER, "%s", bfPart[pos]);					
					if (!L4D2Version) 
						Format(_sStandart, MAX_LEN_STRING, "t|[Left 4 Dead]");
					else Format(_sStandart, MAX_LEN_STRING, "t|[Left 4 Dead 2]");				
					if (isCorrectValue(bfPart, _sCriterion, _sStandart, num) == 1)											
						return isCorrectValue(bfPart, sCriterion, sStandart, num);
				}				
			}
			return 0; // isn't correct
		}
		return 2; // this criterion not found
	}
}	

stock isCorrectValue(String: bf[], String: sCriterion[], String: sStandart[], num0)
{
	decl String: sValue[MAX_LEN_STRING];
	new num = 0;
	if ((num = numStrContains(bf, false, sCriterion, "<%s>")) > -1 && (num0 = numStrContains(bf, true, sCriterion, "</%s>")) > num)
	{
		Format(sValue, num0 - num, "%s", bf[num + 1]);		
		if (isCorrectReadValue(sCriterion, sStandart, sValue))
		{
			#if DEBUG
			LogMessage("%s #DEBUG: is correct", PLUGIN_TAG);
			#endif				
			return 1;
		}
		else if (sStandart[1] == '&')
		{
			#if DEBUG
			LogMessage("%s #DEBUG: kick now", PLUGIN_TAG);
			#endif				
			return -1;
		}
		else
		{
			#if DEBUG
			LogMessage("%s #DEBUG: isn't correct", PLUGIN_TAG);
			#endif				
			return 0;
		}
	}
	#if DEBUG
	LogMessage("%s #DEBUG: this criterion not found", PLUGIN_TAG);
	#endif
	return 2;
}

stock bool: isCorrectReadValue(String: sCriterion[], String: sStandart[], String: sValue[])
{
	new String: sValueForCheck[strlen(sStandart)];
	Format(sValueForCheck, strlen(sStandart), "%s", sStandart[2]);
	#if DEBUG
	LogMessage("%s #DEBUG: sValue = %s, sValueForCheck = %s, sStandart = %s", PLUGIN_TAG, sValue, sValueForCheck, sStandart);
	#endif
	switch (sStandart[0])
	{
		case '>': // numeric, >
			if (StringToFloat(sValue) > StringToFloat(sValueForCheck))
				return true;
		case '<': // numeric, <
			if (StringToFloat(sValue) < StringToFloat(sValueForCheck))
				return true;
		case '!': // numeric, !=
			if (StringToFloat(sValue) != StringToFloat(sValueForCheck))
				return true;
		case '=': // numeric, ==
			if (StringToFloat(sValue) == StringToFloat(sValueForCheck))
				return true;
		case 't': // string, equal
			if (!StrEqual(sValueForCheck, "[empty]", false))
			{
				if (StrContains(sValue, sValueForCheck, false) > -1)
					return true;
			}
			else if (strlen(sValue) == 0 || StrContains(sValue, "<![CDATA[]]>", false) == 0)
				return true;
		default: // string, not equal ('f')
		{
			if (!StrEqual(sValueForCheck, "[empty]", false))
			{				
				if (StrContains(sValue, sValueForCheck, false) == -1)
					return true;
			}
			else if (strlen(sValue) != 0 && StrContains(sValue, "<![CDATA[]]>", false) != 0)			
				return true;
		}
	}
	return false;
}

stock numStrContains(const String: sTextBuffer[], bool: isBeginContains, const String: sTextSearch[], const String: sFormat[])
{
	new pos;
	decl String: sSearch[MAX_LEN_STRING];
	Format(sSearch, MAX_LEN_STRING, sFormat, sTextSearch);
	pos = StrContains(sTextBuffer, sSearch, false);
	if (!isBeginContains && pos > -1)		
		return (pos + strlen(sSearch) - 1);
	return pos;	
}

returnSteamID(_client, String: _arg[], String: _ID[])
{	
	if (StrContains(_arg, "STEAM_", true) > -1)
		Format(_ID, MAX_LEN_STRING*2, "%s", _arg);
	else
	{
		new Targ = -1;
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[1], bool:tn_is_ml;		
		if (ProcessTargetString(_arg, _client, target_list, 1, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI, target_name, sizeof(target_name), tn_is_ml) > 0) 
			Targ = target_list[0];
		if (Targ > 0)
			GetClientAuthString(Targ, _ID, MAX_LEN_STRING*2);		
	}
	if (strlen(_ID) == 0) 
		PrintToChat(_client, "The parameter is incorrect");
	#if DEBUG
	LogMessage("%s #DEBUG: SteamID %s, arg %s", PLUGIN_TAG, _ID, _arg);
	#endif
}

ActionIfNoob(bool: KickPlayer, Player, idReasonKick) // Version 1.1, Version 1.1b
{
	if (KickPlayer)
	{		
		if (IsClientConnected(Player))
		{
			Format(ClientsID[Player], MAX_LEN_STRING, " "); // Version 1.1c
			new String: _name[MAX_LEN_STRING*2];
			GetClientName(Player, _name, MAX_LEN_STRING*2);			
			for (new i = 1; i < GetMaxClients(); i++) 
				if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) 
					if (i != Player) 						
						PrintToChat(i, "%s kicked by steam's profile checker", _name);
			new String: sMsg[MAX_LEN_STRING*2];						
			sMsg = "Your profile isn't authenticated by server!";
			if (idReasonKick < MAX_CRITERIONS)
			{
				if (StrEqual(sCriterionsNames[idReasonKick], "steamID", false))
					sMsg = "Your profile isn't authenticated by server, because must create!";
				else if (StrEqual(sCriterionsNames[idReasonKick], "visibilityState", false))
					sMsg = "Your profile isn't authenticated by server. Make PUBLIC and try again!";
			}
			#if DEBUG
			new String: _ID[MAX_LEN_STRING*2];
			GetClientAuthString(Player, _ID, MAX_LEN_STRING*2);
			LogMessage("%s #DEBUG: %s (%s): kicked with message \"%s\"", PLUGIN_TAG, _name, _ID, sMsg);
			#endif
			KickClient(Player, "%s", sMsg);
		}
		else
		{
			#if DEBUG			
			LogMessage("%s #DEBUG: client %i disconnected before kick", PLUGIN_TAG, Player);
			#endif
		}
	}
	else PrintToChat(Player, "Access denied!");
}

WriteWhiteList()
{
	new Handle:file = OpenFile(g_Filename, "wt");
	if (file == INVALID_HANDLE)
	{		
		LogError("Could not open whitelist for write!");
		return;
	}		
	decl String: bfWriteLine[sizeof(sBase)];
	new sizeWhiteList = GetArraySize(WhiteList);		
	for (new i = 0; i < sizeWhiteList; i++)
	{			
		GetArrayString(WhiteList, i, bfWriteLine, sizeof(sBase));
		WriteFileLine(file, bfWriteLine);				
	}
	CloseHandle(file);
}

AddToWhiteList(String: sAddID[]) // Version 1.2
{
	if (FindStringInArray(WhiteList, sAddID) == -1)
	{		
		PushArrayString(WhiteList, sAddID);
		#if DEBUG
		LogMessage("%s #DEBUG: added in white list %s", PLUGIN_TAG, sAddID);
		LogMessage("%s #DEBUG: size of white list = %i", PLUGIN_TAG, GetArraySize(WhiteList));
		#endif
		WriteWhiteList();
	}
}

DelFromWhiteList(String: sDelID[]) // Version 1.2
{
	new idDel;
	if ((idDel = FindStringInArray(WhiteList, sDelID)) > -1)
	{		
		RemoveFromArray(WhiteList, idDel);
		#if DEBUG		
		LogMessage("%s #DEBUG: deleted from white list: %s", PLUGIN_TAG, sDelID);
		LogMessage("%s #DEBUG: size of white list = %i", PLUGIN_TAG, GetArraySize(WhiteList));
		#endif
		WriteWhiteList();
	}
}