/************************************************************************
*************************************************************************
Simple Chat Processor
Description:
		Process chat and allows other plugins to manipulate chat.
		
		* Added support for CS:GO
*************************************************************************
*************************************************************************
This file is part of Simple Plugins project.

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id: simple-chatprocessor.sp 187 2011-09-21 15:44:31Z antithasys $
$Author: antithasys $
$Revision: 187 $
$Date: 2011-09-21 10:44:31 -0500 (Wed, 21 Sep 2011) $
$LastChangedBy: antithasys $
$LastChangedDate: 2011-09-21 10:44:31 -0500 (Wed, 21 Sep 2011) $
$URL: https://sm-simple-plugins.googlecode.com/svn/trunk/Simple%20Chat%20Processor/addons/sourcemod/scripting/simple-chatprocessor.sp $
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/

#include <sourcemod>

#define PLUGIN_VERSION				"1.0.2"
#define SENDER_WORLD					0
#define MAXLENGTH_INPUT			128 	// Inclues \0 and is the size of the chat input box.
#define MAXLENGTH_NAME				64		// This is backwords math to get compability.  Sourcemod has it set at 32, but there is room for more.
#define MAXLENGTH_MESSAGE		256		// This is based upon the SDK and the length of the entire message, including tags, name, : etc.

#define CHATFLAGS_INVALID		0
#define CHATFLAGS_ALL				(1<<0)
#define CHATFLAGS_TEAM				(1<<1)
#define CHATFLAGS_SPEC				(1<<2)
#define CHATFLAGS_DEAD				(1<<3)

#define ADDSTRING(%1) SetTrieValue(g_hChatFormats, %1, 1)

enum eMods
{
	GameType_Unknown,
	GameType_AOC,
	GameType_CSS,
	GameType_CSGO,
	GameType_DOD,
	GameType_FF,
	GameType_HIDDEN,
	GameType_HL2DM,
	GameType_INS,
	GameType_L4D,
	GameType_L4D2,
	GameType_NEO,
	GameType_SGTLS,
	GameType_TF,
	GameType_DM,
	GameType_ZPS
};

new eMods:g_CurrentMod;
new String:g_sGameName[eMods][32] = {		"Unknown",
																							"Age of Chivalry",
																							"Counter Strike",
																							"CS Global Offensive",
																							"Day Of Defeat",
																							"Fortress Forever",
																							"Hidden: Source",
																							"Half Life 2: Deathmatch",
																							"Insurgency",
																							"Left 4 Dead",
																							"Left 4 Dead 2",
																							"Neotokyo",
																							"Stargate TLS",
																							"Team Fortress 2",
																							"Dark Messiah",
																							"Zombie Panic: Source"
};

new Handle:g_hChatFormats = INVALID_HANDLE;
new Handle:g_fwdOnChatMessage;

new g_CurrentChatType = CHATFLAGS_INVALID;

public Plugin:myinfo =
{
	name = "Simple Chat Processor",
	author = "Simple Plugins",
	description = "Process chat and allows other plugins to manipulate chat.",
	version = PLUGIN_VERSION,
	url = "http://www.simple-plugins.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("GetMessageFlags", Native_GetMessageFlags);
	RegPluginLibrary("scp");
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sc_core_version", PLUGIN_VERSION, "Simple Chat Processor", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	/**
	Get mod type and load the correct translation file
	*/
	g_CurrentMod = GetCurrentMod();
	g_hChatFormats = CreateTrie();
	LogMessage("[SCP] Recognized mod [%s].", g_sGameName[g_CurrentMod]);
	decl String:sGameDir[32];
	decl String:sTranslationFile[PLATFORM_MAX_PATH];
	decl String:sTranslationLocation[PLATFORM_MAX_PATH];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	Format(sTranslationFile, sizeof(sTranslationFile), "scp.%s.phrases", sGameDir);
	BuildPath(Path_SM, sTranslationLocation, sizeof(sTranslationLocation), "translations/%s.txt", sTranslationFile);
	if (FileExists(sTranslationLocation))
	{
		LogMessage("[SCP] Loading translation file [%s].", sTranslationFile);
		LoadTranslations(sTranslationFile);
		if (!GetChatFormats(sTranslationLocation))
		{
			LogError("[SCP] Could not parse the translation file");
			SetFailState("Could not parse the translation file");
		}
	}
	else
	{
		LogError("[SCP] Translation file is not present");
		SetFailState("Translation file is not present");
	}

	/**
	Hook the usermessage or error out if the mod doesn't support saytext2
	*/
	new UserMsg:umSayText2 = GetUserMessageId("SayText2");
	if (umSayText2 != INVALID_MESSAGE_ID)
	{
		HookUserMessage(umSayText2, OnSayText2, true);
	}
	else
	{
		LogError("[SCP] This mod appears not to support SayText2.  Plugin disabled.");
		SetFailState("Error hooking usermessage saytext2");	
	}
	
	/**
	Create the global forward for other plugins
	*/
	g_fwdOnChatMessage = CreateGlobalForward("OnChatMessage", ET_Hook, Param_CellByRef, Param_Cell, Param_String, Param_String);
}

public Action:OnSayText2(UserMsg:msg_id, Handle:bf, const clients[], numClients, bool:reliable, bool:init)
{
	/**
	Get the sender of the usermessage and bug out if it is not a player
	*/
	new cpSender = BfReadByte(bf);
	if (cpSender == SENDER_WORLD)
	{
		return Plugin_Continue;
	}
	
	/**
	Get the chat bool.  This determines if sent to console as well as chat
	*/
	new bool:bChat = bool:BfReadByte(bf);
	
	/**
	Make sure we have a default translation string for the message
	This also determines the message type...
	*/
	decl String:cpTranslationName[32];
	decl buffer;
	BfReadString(bf, cpTranslationName, sizeof(cpTranslationName));
	if (!GetTrieValue(g_hChatFormats, cpTranslationName, buffer))
	{
		return Plugin_Continue;
	}
	else
	{
		if (StrContains(cpTranslationName, "all", false) != -1)
		{
			g_CurrentChatType = g_CurrentChatType | CHATFLAGS_ALL;
		}
		if (StrContains(cpTranslationName, "team", false) != -1
		|| 	StrContains(cpTranslationName, "survivor", false) != -1 
		||	StrContains(cpTranslationName, "infected", false) != -1
		||	StrContains(cpTranslationName, "Cstrike_Chat_CT", false) != -1 
		||	StrContains(cpTranslationName, "Cstrike_Chat_T", false) != -1)
		{
			g_CurrentChatType = g_CurrentChatType | CHATFLAGS_TEAM;
		}
		if (StrContains(cpTranslationName, "spec", false) != -1)
		{
			g_CurrentChatType = g_CurrentChatType | CHATFLAGS_SPEC;
		}
		if (StrContains(cpTranslationName, "dead", false) != -1)
		{
			g_CurrentChatType = g_CurrentChatType | CHATFLAGS_DEAD;
		}
	}
	
	/**
	Get the senders name
	*/
	decl String:cpSender_Name[MAXLENGTH_NAME];
	if (BfGetNumBytesLeft(bf))
	{
		BfReadString(bf, cpSender_Name, sizeof(cpSender_Name));
	}
	
	/**
	Get the message
	*/
	decl String:cpMessage[MAXLENGTH_INPUT];
	if (BfGetNumBytesLeft(bf))
	{
		BfReadString(bf, cpMessage, sizeof(cpMessage));
	}
	
	/**
	Store the clients in an array so the call can manipulate it.
	*/
	new Handle:cpRecipients = CreateArray(1, 1);
	for (new i = 0; i < numClients; i++)
	{
		PushArrayCell(cpRecipients, clients[i]);
	}
	
	/**
	Because the message could be changed but not the name
	we need to compare the original name to the returned name.
	We do this because we may have to add the team color code to the name,
	where as the message doesn't get a color code by default.
	*/
	decl String:sOriginalName[MAXLENGTH_NAME];
	strcopy(sOriginalName, sizeof(sOriginalName), cpSender_Name);
	
	/**
	Start the forward for other plugins
	*/
	new Action:fResult;
	Call_StartForward(g_fwdOnChatMessage);
	Call_PushCellRef(cpSender);
	Call_PushCell(cpRecipients);
	Call_PushStringEx(cpSender_Name, sizeof(cpSender_Name), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(cpMessage, sizeof(cpMessage), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	new fError = Call_Finish(fResult);
	
	g_CurrentChatType = CHATFLAGS_INVALID;
	
	if (fError != SP_ERROR_NONE)
	{
		ThrowNativeError(fError, "Forward failed");
		CloseHandle(cpRecipients);
		return Plugin_Continue;
	}
	else if (fResult == Plugin_Continue)
	{
		CloseHandle(cpRecipients);
		return Plugin_Continue;
	}
	else if (fResult == Plugin_Stop)
	{
		CloseHandle(cpRecipients);
		return Plugin_Handled;
	}
	
	/**
	This is the check for a name change.  If it has not changed we add the team color code
	*/
	if (StrEqual(sOriginalName, cpSender_Name))
	{
		Format(cpSender_Name, sizeof(cpSender_Name), "\x03%s", cpSender_Name);
	}
	
	/**
	Create a timer to print the message on the next gameframe
	*/
	new Handle:cpPack = CreateDataPack();
	new numRecipients = GetArraySize(cpRecipients);
	
	WritePackCell(cpPack, cpSender);

	for (new i = 0; i < numRecipients; i++)
	{
		new x = GetArrayCell(cpRecipients, i);
		if (!IsValidClient(x))
		{
			numRecipients--;
			RemoveFromArray(cpRecipients, i);
		}
	}
	
	WritePackCell(cpPack, numRecipients);
	
	for (new i = 0; i < numRecipients; i++)
	{
		new x = GetArrayCell(cpRecipients, i);
		WritePackCell(cpPack, x);
	}
		
	WritePackCell(cpPack, bChat);
	WritePackString(cpPack, cpTranslationName);
	WritePackString(cpPack, cpSender_Name);
	WritePackString(cpPack, cpMessage);	
	CreateTimer(0.001, ResendMessage, cpPack, TIMER_FLAG_NO_MAPCHANGE);
	
	CloseHandle(cpRecipients);
	
	/**
	Stop the original message
	*/
	return Plugin_Handled;
}

public Action:ResendMessage(Handle:timer, any:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new numClients = ReadPackCell(pack);
	new clients[numClients];

	for (new i = 0; i < numClients; i++)
	{
		clients[i] = ReadPackCell(pack);
	}
	
	new bool:bChat = bool:ReadPackCell(pack);
	decl String:sChatType[32];
	decl String:sSenderName[MAXLENGTH_NAME];
	decl String:sMessage[MAXLENGTH_INPUT];
	ReadPackString(pack, sChatType, sizeof(sChatType));
	ReadPackString(pack, sSenderName, sizeof(sSenderName));
	ReadPackString(pack, sMessage, sizeof(sMessage));
	
	decl String:sTranslation[MAXLENGTH_MESSAGE];
	Format(sTranslation, sizeof(sTranslation), "%t", sChatType, sSenderName, sMessage);
	
	new Handle:bf = StartMessage("SayText2", clients, numClients, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWriteByte(bf, client);
	BfWriteByte(bf, bChat);
	BfWriteString(bf, sTranslation);
	EndMessage();
	
	CloseHandle(pack);
	return Plugin_Stop;
}

public Native_GetMessageFlags(Handle:plugin, numParams)
{
	return g_CurrentChatType;
}

stock bool:IsValidClient(client, bool:nobots = true) 
{  
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client))) 
	{  
			return false;  
	}  
	return IsClientInGame(client);  
}

stock bool:GetChatFormats(const String:file[])
{
	new Handle:hParser = SMC_CreateParser();
	new String:error[128];
	new line = 0;
	new col = 0;

	SMC_SetReaders(hParser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(hParser, Config_End);
	new SMCError:result = SMC_ParseFile(hParser, file, line, col);
	CloseHandle(hParser);

	if (result != SMCError_Okay) 
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}
	
	return (result == SMCError_Okay);
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) 
{
	if (StrEqual(section, "Phrases"))
	{
		return SMCParse_Continue;
	}
	ADDSTRING(section);
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser) 
{
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) 
{
	//nothing
}

stock eMods:GetCurrentMod()
{
	new String:sGameType[64];
	GetGameFolderName(sGameType, sizeof(sGameType));
	
	if (StrEqual(sGameType, "aoc", false))
	{
		return GameType_AOC;
	}
	if (StrEqual(sGameType, "cstrike", false))
	{
		return GameType_CSS;
	}
	if (StrEqual(sGameType, "csgo", false))
	{
		return GameType_CSGO;
	}
	if (StrEqual(sGameType, "dod", false))
	{
		return GameType_DOD;
	}
	if (StrEqual(sGameType, "ff", false))
	{
		return GameType_FF;
	}
	if (StrEqual(sGameType, "hidden", false))
	{
		return GameType_HIDDEN;
	}
	if (StrEqual(sGameType, "hl2mp", false))
	{
		return GameType_FF;
	}
	if (StrEqual(sGameType, "insurgency", false) || StrEqual(sGameType, "ins", false))
	{
		return GameType_INS;
	}
	if (StrEqual(sGameType, "left4dead", false) || StrEqual(sGameType, "l4d", false))
	{
		return GameType_L4D;
	}
	if (StrEqual(sGameType, "left4dead2", false) || StrEqual(sGameType, "l4d2", false))
	{
		return GameType_L4D2;
	}
	if (StrEqual(sGameType, "nts", false))
	{
		return GameType_NEO;
	}
	if (StrEqual(sGameType, "sgtls", false))
	{
		return GameType_SGTLS;
	}
	if (StrEqual(sGameType, "tf", false))
	{
		return GameType_TF;
	}
	if (StrEqual(sGameType, "zps", false))
	{
		return GameType_ZPS;
	}
	if (StrEqual(sGameType, "mmdarkmessiah", false))
	{
		return GameType_DM;
	}
	LogMessage("Unknown Game Folder: %s", sGameType);
	return GameType_Unknown;
}
