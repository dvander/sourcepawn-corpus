// UnicodeNameFilter.sp

/*
	UnicodeNameFilter

	Copyright (c) 2014  El Diablo <www.war3evo.info>

	Antihack is free software: you may copy, redistribute
	and/or modify it under the terms of the GNU General Public License as
	published by the Free Software Foundation, either version 3 of the
	License, or (at your option) any later version.

	This file is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// Much of this code was pulled from Anti-Hack from my github:
// https://github.com/War3Evo/Anti-Hack

// removed .. people like their names
//#assert GGAMEMODE == -1


// new console command:
// namelockid
// prevents players from changing their name while in your server
// Usage:  namelockid < userid > < 0 | 1 >



#include <sdktools_functions>

new Handle:g_hEnabledLogs;
new Handle:g_hEnabledSkipFilterChecking;
new Handle:g_hEnabledTimerChecking;
new Handle:g_hEnabledPreventNameCopying;
new Handle:g_hEnabledUseridPrefix;
new Handle:g_hNonUseridPrefix;
new Handle:g_hLockNameAfterFiltering;
new Handle:g_hTellPlayersOfAnyChanges;

new g_iEnabledLogs=1;
new bool:g_bEnabledSkipFilterChecking=false;
new bool:g_bEnabledTimerChecking=true;
new bool:g_bEnabledPreventNameCopying=false;
new bool:g_bEnabledUseridPrefix=true;
new String:g_sNonUseridPrefix[32]={"(1)"};
new bool:g_bLockNameAfterFiltering=true;
new bool:g_bTellPlayersOfAnyChanges=true;

public Plugin:myinfo =
{
	name = "UnicodeNameFilter",
	author = "El Diablo",
	description = "Filters players names whom have unicode characters in their name.",
	version = "1.2",
	url = "https://github.com/War3Evo, admin@war3evo.info"
}

public OnPluginStart()
{
	CreateConVar("unicodenamefilter_version","1.2 by El Diablo","UnicodeNameFilter version.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	LoadTranslations("UnicodeNameFilter.phrases.txt");

	new UserMsg:umOnDebugP = GetUserMessageId("SayText2");
	if (umOnDebugP != INVALID_MESSAGE_ID)
	{
		HookUserMessage(umOnDebugP, OnDebugP, true);
	}
	else
	{
		LogError("[SCP] This mod appears not to support SayText2.  Plugin disabled.");
		SetFailState("Error hooking usermessage saytext2");
	}

	HookEvent("player_changename", Event_player_changename, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	g_hEnabledLogs=					CreateConVar("unf_enable_logs","1","1 - Always Enable, 0 - Disable,\n2 - Do not log those whom skip filter checking.\nLogging of the name changes.");
	g_hEnabledTimerChecking=		CreateConVar("unf_timer_checking","1","1 - Enable / 0 - Disable");
	g_hEnabledSkipFilterChecking=	CreateConVar("unf_skipfilter_checking","0","1 - Enable / 0 - Disable\nCommandAccess unf_skipfilter is checked to see if that player can skip the name filtering.\nDefault Admin flag is ADMFLAG_RESERVATION.");
	g_hEnabledPreventNameCopying=	CreateConVar("unf_enable_prevent_name_copying","0","1 - Enable / 0 - Disable\nEnable Experimental prevent name copying/duplicates.");
	g_hEnabledUseridPrefix=			CreateConVar("unf_enable_userid_prefix","1","1 - Enable / 0 - Disable\nEnable using userid as a name if has a duplicate name of someone else.");
	g_hNonUseridPrefix=				CreateConVar("unf_enable_prefix","(1)","If unf_enable_userid_prefix is disabled, then duplicate names will be prefixed with this.");
	g_hLockNameAfterFiltering=		CreateConVar("unf_lock_name_after_filtering","1","1 - Enable / 0 - Disable\nLocks a players name after the filtering changes it.");
	g_hTellPlayersOfAnyChanges=		CreateConVar("unf_tell_players_of_any_changes","1","1 - Enable / 0 - Disable\nIf enabled, will tell players when it makes changes to their name.");

	HookConVarChange(g_hEnabledLogs,									convar_changed);
	HookConVarChange(g_hEnabledSkipFilterChecking,						convar_changed);
	HookConVarChange(g_hEnabledTimerChecking,							convar_changed);
	HookConVarChange(g_hEnabledPreventNameCopying,						convar_changed);
	HookConVarChange(g_hEnabledUseridPrefix,							convar_changed);
	HookConVarChange(g_hNonUseridPrefix,								convar_changed);
	HookConVarChange(g_hLockNameAfterFiltering,							convar_changed);
	HookConVarChange(g_hTellPlayersOfAnyChanges,							convar_changed);
}

public convar_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_hEnabledLogs)
		g_iEnabledLogs 				 = StringToInt(newValue);
	else if(convar == g_hEnabledSkipFilterChecking)
		g_bEnabledSkipFilterChecking = bool:StringToInt(newValue);
	else if(convar == g_hEnabledTimerChecking)
		g_bEnabledTimerChecking = bool:StringToInt(newValue);
	else if(convar == g_hEnabledPreventNameCopying)
		g_bEnabledPreventNameCopying = bool:StringToInt(newValue);
	else if(convar == g_hEnabledUseridPrefix)
		g_bEnabledUseridPrefix = bool:StringToInt(newValue);
	else if(convar == g_hNonUseridPrefix)
		strcopy(g_sNonUseridPrefix,sizeof(g_sNonUseridPrefix),newValue);
	else if(convar == g_hLockNameAfterFiltering)
		g_bLockNameAfterFiltering = bool:StringToInt(newValue);
	else if(convar == g_hTellPlayersOfAnyChanges)
		g_bTellPlayersOfAnyChanges = bool:StringToInt(newValue);
}

public OnMapStart()
{
	CreateTimer(5.0,TimerChecking,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

stock LockName(client,bool:lock)
{
	ServerCommand("namelockid %d %d", GetClientUserId(client), lock ? 1 : 0);
}

stock UnicodeNameFilterLog(const String:reason[]="", any:...)
{
	if(g_iEnabledLogs<=0) return 0;
	new String:szFile[256];

	decl String:LogThis[2048];
	VFormat(LogThis, sizeof(LogThis), reason, 2);

	decl String:date[32];
	FormatTime(date, sizeof(date), "%m_%d_%y");

	BuildPath(Path_SM, szFile, sizeof(szFile), "logs/UnicodeNameFilter_%s.log", date);
	LogToFile(szFile, LogThis);
	return 1;
}

// Added extremefilter and RemoveWhiteSpace for a future update.
stock FilterSentence(String:message[],bool:extremefilter=false,bool:RemoveWhiteSpace=false)
{
	new charMax = strlen(message);
	new charIndex;
	new copyPos = 0;

	new String:strippedString[192];

	for (charIndex = 0; charIndex < charMax; charIndex++)
	{
		// Reach end of string. Break.
		if (message[copyPos] == 0) {
			strippedString[copyPos] = 0;
			break;
		}

		if (GetCharBytes(message[charIndex])>1)
		{
			continue;
		}

		if(RemoveWhiteSpace && IsCharSpace(message[charIndex]))
		{
			continue;
		}

		if(extremefilter && IsAlphaNumeric(message[charIndex]))
		{
			strippedString[copyPos] = message[charIndex];
			copyPos++;
			continue;
		}

		// Found a normal character. Copy.
		if (!extremefilter && IsNormalCharacter(message[charIndex])) {
			strippedString[copyPos] = message[charIndex];
			copyPos++;
			continue;
		}
	}

	// Copy back to passing parameter.
	strcopy(message, 192, strippedString);
}

stock bool:IsAlphaNumeric(characterNum) {
	return ((characterNum >= 48 && characterNum <=57)
		||  (characterNum >= 65 && characterNum <=90)
		||  (characterNum >= 97 && characterNum <=122));
}

stock bool:IsNormalCharacter(characterNum) {
	return (characterNum > 31 && characterNum < 127);
}

stock bool:ValidPlayer(client)
{
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

stock bool:HasDuplicateName(client,userid,Handle:event,bool:IsChangeName=false)
{
	decl String:sClientName[127],String:sTestName[127],String:sNonFilteredClientName[127];

	if(!IsChangeName)
	{
		GetClientName(client,sClientName,sizeof(sClientName));
	}
	else
	{
		GetEventString(event, "newname", sClientName, 126);
	}

	strcopy(sNonFilteredClientName,sizeof(sNonFilteredClientName),sClientName);

	FilterSentence(sClientName,false,false);

	new foundit=false;

	new i;

	for(i = 1; i <= MaxClients; i++)
	{
		if(client!=i && ValidPlayer(i))
		{
			GetClientName(i,sTestName,sizeof(sTestName));
			FilterSentence(sTestName,false,false);

			if(StrEqual(sClientName,sTestName,false))
			{
				foundit=true;
				break;
			}
		}
	}

	if(foundit)
	{
		decl String:sNameBuffer[127];
		if(g_bEnabledUseridPrefix)
		{
			Format(sNameBuffer,sizeof(sNameBuffer),"UserID#%d",userid);
		}
		else
		{
			Format(sNameBuffer,sizeof(sNameBuffer),"%s%s",g_sNonUseridPrefix,sNonFilteredClientName);
		}
		if(g_bTellPlayersOfAnyChanges)
		{
			PrintToChat(client, "%t", "DuplicateNameFound",sNameBuffer);
		}

		new Handle:h_namechange = FindConVar("sv_namechange_cooldown_seconds");
		if(h_namechange!=INVALID_HANDLE)
		{
			SetConVarInt(h_namechange, 0);
		}
		CloseHandle(h_namechange);
		LockName(client,false);

		SetClientInfo(client, "name", sNameBuffer);

		CreateTimer(1.0,RestoreNameChangingCoolDown,_);
		if(g_bLockNameAfterFiltering)
		{
			CreateTimer(1.0,LockClientName,GetClientUserId(client));
		}

		// the userid's in the logs is to show it is not the same person
		UnicodeNameFilterLog("[%d] Client Name %s / Client Filtered Name %s = [%d] Test Filtered Name %s / Client New Name %s",userid,sNonFilteredClientName,sClientName,GetClientUserId(i),sTestName,sNameBuffer);
		return true;
	}
	return false;
}

stock bool:FitlerName(client,userid,Handle:event,bool:IsChangeName=false)
{
	decl String:sTestName1[127], String:CurrentName[127];

	if(!IsChangeName)
	{
		GetClientName(client,CurrentName,sizeof(CurrentName));
	}
	else
	{
		GetEventString(event, "newname", CurrentName, 126);
	}

	strcopy(sTestName1,sizeof(sTestName1),CurrentName);

	FilterSentence(sTestName1);

	if(!StrEqual(sTestName1,CurrentName,false))
	{
		// Steam allows a minimum of 2 characters for a name.
		if(strlen(sTestName1)>=2)
		{
			if(g_bTellPlayersOfAnyChanges)
			{
				PrintToChat(client, "%t", "FilteredYourName", sTestName1);
			}

			new Handle:h_namechange = FindConVar("sv_namechange_cooldown_seconds");
			if(h_namechange!=INVALID_HANDLE)
			{
				SetConVarInt(h_namechange, 0);
			}
			CloseHandle(h_namechange);
			LockName(client,false);

			SetClientInfo(client, "name", sTestName1);

			CreateTimer(1.0,RestoreNameChangingCoolDown,_);
			if(g_bLockNameAfterFiltering)
			{
				CreateTimer(1.0,LockClientName,GetClientUserId(client));
			}

			// temporaryly not broadcasting, may use in future.
			//SetEventBroadcast(event, true);

			UnicodeNameFilterLog("[%d] Client Name %s / Client Filtered Name %s / Client New Name %s",userid,CurrentName,sTestName1,sTestName1);
		}
		else
		{
			new String:sNameBuffer[127];

			Format(sNameBuffer,sizeof(sNameBuffer),"UserID#%d",userid);
			if(g_bTellPlayersOfAnyChanges)
			{
				PrintToChat(client, "%t", "CouldNotFindASCII");
			}
			LockName(client,false);

			SetClientInfo(client, "name", sNameBuffer);

			if(g_bLockNameAfterFiltering)
			{
				CreateTimer(1.0,LockClientName,GetClientUserId(client));
			}
			// temporaryly not broadcasting, may use in future.
			//SetEventBroadcast(event, true);

			UnicodeNameFilterLog("[%d] Client Name %s / Client Filtered Name %s / Client New Name %s",userid,CurrentName,sTestName1,sNameBuffer);
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	if(ValidPlayer(client) && !IsFakeClient(client))
	{
		if(g_bEnabledSkipFilterChecking && CheckCommandAccess(client, "unf_skipfilter", ADMFLAG_RESERVATION))
		{
			if(g_iEnabledLogs==1)
			{
				decl String:sClientName[127];
				GetClientName(client,sClientName,sizeof(sClientName));
				UnicodeNameFilterLog("Skipped Filter - %s",sClientName);
			}
			return;
		}

		if(g_bEnabledPreventNameCopying==true)
		{
			if(HasDuplicateName(client,userid,event,false)==false)
			{
				FitlerName(client,userid,event,false);
			}
		}
		else
		{
			FitlerName(client,userid,event,false);
		}
	}
}

public Action:Event_player_changename(Handle:event,  const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	if(ValidPlayer(client) && !IsFakeClient(client))
	{
		if(g_bEnabledSkipFilterChecking && CheckCommandAccess(client, "unf_skipfilter", ADMFLAG_RESERVATION))
		{
			if(g_iEnabledLogs==1)
			{
				decl String:sClientName[127];
				GetClientName(client,sClientName,sizeof(sClientName));
				UnicodeNameFilterLog("Skipped Filter - %s",sClientName);
			}
			return Plugin_Continue;
		}

		if(g_bEnabledPreventNameCopying==true)
		{
			if(HasDuplicateName(client,userid,event,true)==false)
			{
				FitlerName(client,userid,event,true);
			}
		}
		else
		{
			FitlerName(client,userid,event,true);
		}
	}
	return Plugin_Continue;
}

// Stop all Name change chat
public Action:OnDebugP(UserMsg:msg_id, Handle:hBitBuffer, const clients[], numClients, bool:reliable, bool:init)
{
	// Skip the first two bytes
	BfReadByte(hBitBuffer);
	BfReadByte(hBitBuffer);

	// Read the message
	decl String:strMessage[1024];
	BfReadString(hBitBuffer, strMessage, sizeof(strMessage));

	// If the message equals to the string we want to filter, skip.
	if (StrEqual(strMessage, "#TF_Name_Change")) return Plugin_Handled;

	// Done.
	return Plugin_Continue;
}

public Action:LockClientName( Handle:timer, any:userid )
{
	LockName(GetClientOfUserId(userid),true);
}

public Action:RestoreNameChangingCoolDown( Handle:timer, any:data )
{
	new Handle:h_namechange = FindConVar("sv_namechange_cooldown_seconds");
	if(h_namechange!=INVALID_HANDLE)
	{
		SetConVarInt(h_namechange, 20);
	}
	CloseHandle(h_namechange);
}

/* ***************************	TimerChecking *************************************/

public Action:TimerChecking(Handle:timer)
{
	if(!g_bEnabledTimerChecking)
		return Plugin_Continue;

	new userid = 0;

	new Handle:event = INVALID_HANDLE;

	for(new i;i<=MaxClients;i++)
	{
		if(ValidPlayer(i) && !IsFakeClient(i))
		{
			userid = GetClientOfUserId(i);
			if(g_bEnabledPreventNameCopying==true)
			{
				if(HasDuplicateName(i,userid,event,false)==false)
				{
					FitlerName(i,userid,event,false);
				}
			}
			else
			{
				FitlerName(i,userid,event,false);
			}
		}
	}
	if(event != INVALID_HANDLE)
	{
		CloseHandle(event);
	}
	return Plugin_Continue;
}
