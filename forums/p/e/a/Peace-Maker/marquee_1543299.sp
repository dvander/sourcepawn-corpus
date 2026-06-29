/**
 * Marquee. Lets you run text through the panel.
 * 
 * Based on the eventscript runningline by sega74rus
 * http://addons.eventscripts.com/addons/view/runningline
 * 
 * Credits for the alphabet entirely to him.
 * 
 * by Peace-Maker
 * visit http://www.wcfan.de/
 */
#pragma semicolon 1
#include <sourcemod>
#include <marquee>

#define PLUGIN_VERSION "1.0"

#define LINE_WIDTH 30
#define LINE_EMPTY "▁"
#define LINE_FILLED "█"

new Handle:g_hAlphabet;
new Handle:g_hCharLength;
new String:g_sText[MAXPLAYERS+1][512];
new g_iPosition[MAXPLAYERS+1] = {-1,...};
new g_iMessageLength[MAXPLAYERS+1] = {-1,...};
new Handle:g_hWriteMarquee[MAXPLAYERS+1] = {INVALID_HANDLE,...};

new Handle:g_hOnStartMarquee;

public Plugin:myinfo = 
{
	name = "Marquee",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Let's you run text through the menu",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_marquee_version", PLUGIN_VERSION, "Marquee version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	LoadTranslations("common.phrases");
	
	g_hOnStartMarquee = CreateGlobalForward("Marquee_OnStart", ET_Event, Param_Cell, Param_String);
	
	g_hAlphabet = CreateTrie();
	g_hCharLength = CreateTrie();
	PopulateAlphabet();
	
	RegAdminCmd("sm_marquee", Cmd_Marquee, ADMFLAG_CHAT, "Sends a marquee text panel to the target. Usage: sm_marquee <#userid|steamid|name> TEXT");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("Marquee_Start", Native_Marquee_Start);
	CreateNative("Marquee_StartOne", Native_Marquee_StartOne);
	CreateNative("Marquee_StartAll", Native_Marquee_StartAll);
	CreateNative("Marquee_Stop", Native_Marquee_Stop);
	CreateNative("Marquee_IsRunning", Native_Marquee_IsRunning);
	
	return APLRes_Success;
}

public OnClientDisconnect(client)
{
	Marquee_Stop(client);
}

public Action:Cmd_Marquee(client, args)
{
	if(GetCmdArgs() < 2)
	{
		ReplyToCommand(client, "Usage: sm_marquee <#userid|steamid|name> TEXT");
		return Plugin_Handled;
	}
	
	decl String:sBuffer[512];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			sBuffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	GetCmdArg(2, sBuffer, sizeof(sBuffer));
	
	Marquee_Start(target_list, target_count, sBuffer, true);
	
	if (tn_is_ml)
	{
		LogAction(client, -1, "%L triggered sm_marquee for %T (text %s)", client, target_name, LANG_SERVER, sBuffer);
	}
	else
	{
		LogAction(client, -1, "%L triggered sm_marquee for %s (text %s)", client, target_name, sBuffer);
	}
	
	return Plugin_Handled;
}

public Native_Marquee_Start(Handle:plugin, numParams)
{
	new numClients = GetNativeCell(2);
	new clients[numClients];
	GetNativeArray(1, clients, numClients);
	new iLength;
	GetNativeStringLength(3, iLength);
	new String:sBuffer[iLength+1];
	GetNativeString(3, sBuffer, iLength+1);
	
	new bool:bIntercept = bool:GetNativeCell(4);
	
	// Put the message uppercase
	new String:sMessage[512], String:sChar[6];
	new iMessageLength = 0, iCharLength;
	new iStrLen = strlen(sBuffer);
	new iBytes;
	for(new i=0;i<iStrLen;i++)
	{
		iBytes = GetCharBytes(sBuffer[i]);
		// Get one char at the current position. utf-8 save
		for(new c=0;c<iBytes;c++)
		{
			sChar[c] = sBuffer[i+c];
			if(iBytes == 1)
				sChar[c+1] = 0;
		}
		Format(sMessage, sizeof(sMessage), "%s%s", sMessage, sChar);
		
		if(iBytes == 1)
		{
			sMessage[i] = CharToUpper(sMessage[i]);
			sChar[0] = CharToUpper(sChar[0]);
		}
		
		// The trie doesn't seem to like umlauts
		ReplaceString(sMessage, sizeof(sMessage), "ä", "Ä", false);
		ReplaceString(sMessage, sizeof(sMessage), "ö", "Ö", false);
		ReplaceString(sMessage, sizeof(sMessage), "ü", "Ü", false);
		ReplaceString(sChar, sizeof(sChar), "ä", "Ä", false);
		ReplaceString(sChar, sizeof(sChar), "ö", "Ö", false);
		ReplaceString(sChar, sizeof(sChar), "ü", "Ü", false);
		
		// This char isn't in our alphabet.
		if(!GetTrieValue(g_hCharLength, sChar, iCharLength))
		{
			ReplaceString(sMessage, sizeof(sMessage), sChar, " ", false);
			GetTrieValue(g_hCharLength, " ", iCharLength);
		}
		iMessageLength += iCharLength;
		
		// Skip the other rubbish bytes
		if(IsCharMB(sBuffer[i]))
			i += iBytes-1;
	}
	
	// Create a panel and put the default size of "empty" characters in it
	new Handle:hPanel = CreatePanel();
	new String:sEmptyPanel[256];
	for(new i=0;i<=LINE_WIDTH;i++)
	{
		Format(sEmptyPanel, sizeof(sEmptyPanel), "%s%s", sEmptyPanel, LINE_EMPTY);
	}
	for(new i=0;i<=4;i++)
		DrawPanelText(hPanel, sEmptyPanel);
	
	// Send the panel
	new Action:result;
	for (new i = 0; i < numClients; i++)
	{
		if(!bIntercept && Marquee_IsRunning(clients[i]))
			continue;
		
		Call_StartForward(g_hOnStartMarquee);
		Call_PushCell(clients[i]);
		Call_PushString(sMessage);
		Call_Finish(_:result);
		
		if(result >= Plugin_Handled)
			continue;
		
		if(g_hWriteMarquee[clients[i]] != INVALID_HANDLE)
		{
			KillTimer(g_hWriteMarquee[clients[i]]);
			g_hWriteMarquee[clients[i]] = INVALID_HANDLE;
		}
		g_iPosition[clients[i]] = 0;
		g_iMessageLength[clients[i]] = iMessageLength;
		Format(g_sText[clients[i]], sizeof(g_sText[]), "%s", sMessage);
		
		g_hWriteMarquee[clients[i]] = CreateTimer(0.1, Timer_DrawMarquee, GetClientUserId(clients[i]), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		SendPanelToClient(hPanel, clients[i], Panel_DoNothing, 1);
		
		
	}
	CloseHandle(hPanel);
	
	return true;
}

public Native_Marquee_StartOne(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not ingame", client);
	}
	
	new iLength;
	GetNativeStringLength(3, iLength);
	new String:sMessage[iLength+1];
	GetNativeString(2, sMessage, iLength+1);
	new bool:bIntercept = bool:GetNativeCell(3);
	
	if(!bIntercept && Marquee_IsRunning(client))
		return false;
	
	new clients[1];
	clients[0] = client;
	return Marquee_Start(clients, 1, sMessage, bIntercept);
}

public Native_Marquee_StartAll(Handle:plugin, numParams)
{
	new iLength;
	GetNativeStringLength(3, iLength);
	new String:sMessage[iLength+1];
	GetNativeString(1, sMessage, iLength+1);
	new bool:bIntercept = bool:GetNativeCell(2);
	
	new clients[MaxClients];
	new total;
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
		{
			if(!bIntercept && Marquee_IsRunning(i))
				continue;
			
			clients[total++] = i;
		}
	}
	
	return Marquee_Start(clients, total, sMessage, bIntercept);
}

public Native_Marquee_Stop(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	
	if(g_hWriteMarquee[client] != INVALID_HANDLE)
	{
		KillTimer(g_hWriteMarquee[client]);
		g_hWriteMarquee[client] = INVALID_HANDLE;
	}
	
	g_iPosition[client] = -1;
	g_iMessageLength[client] = -1;
	Format(g_sText[client], sizeof(g_sText[]), "");
	
	return true;
}

public Native_Marquee_IsRunning(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not ingame", client);
	}
	
	return (g_iPosition[client] != -1);
}

public Action:Timer_DrawMarquee(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	decl String:sLine1[15], String:sLine2[15], String:sLine3[15], String:sLine4[15], String:sLine5[15];
	new String:sTotalLine1[256], String:sTotalLine2[256], String:sTotalLine3[256], String:sTotalLine4[256], String:sTotalLine5[256];
	new Handle:hPanel = CreatePanel();
	
	// Fill with whitespace before
	if(g_iPosition[client] < LINE_WIDTH)
	{
		for(new i=0;i<=LINE_WIDTH-g_iPosition[client];i++)
		{
			Format(sTotalLine1, sizeof(sTotalLine1), "%s%s", sTotalLine1, LINE_EMPTY);
			Format(sTotalLine2, sizeof(sTotalLine2), "%s%s", sTotalLine2, LINE_EMPTY);
			Format(sTotalLine3, sizeof(sTotalLine3), "%s%s", sTotalLine3, LINE_EMPTY);
			Format(sTotalLine4, sizeof(sTotalLine4), "%s%s", sTotalLine4, LINE_EMPTY);
			Format(sTotalLine5, sizeof(sTotalLine5), "%s%s", sTotalLine5, LINE_EMPTY);
		}
	}
	
	// Check which char to start to display and which to stop
	decl String:sChar[3];
	new iCharLength, iMessageLength;
	new iStartChar = -1, iBytes;
	new Handle:hLine;
	new iStrLen = strlen(g_sText[client]);
	for(new i=0;i<iStrLen;i++)
	{
		iBytes = GetCharBytes(g_sText[client][i]);
		for(new c=0;c<iBytes;c++)
		{
			sChar[c] = g_sText[client][i+c];
			if(iBytes == 1)
				sChar[c+1] = 0;
		}
		
		GetTrieValue(g_hCharLength, sChar, iCharLength);
		iMessageLength += iCharLength;
		
		// This is the first char to display
		if(iStartChar == -1 && iMessageLength+LINE_WIDTH >= g_iPosition[client])
		{
			// Save the current position
			iStartChar = iMessageLength-iCharLength;
			
			// Get the l33t font of the current char
			GetTrieValue(g_hAlphabet, sChar, hLine);
			GetArrayString(hLine, 0, sLine1, sizeof(sLine1));
			GetArrayString(hLine, 1, sLine2, sizeof(sLine2));
			GetArrayString(hLine, 2, sLine3, sizeof(sLine3));
			GetArrayString(hLine, 3, sLine4, sizeof(sLine4));
			GetArrayString(hLine, 4, sLine5, sizeof(sLine5));
			
			// How many chars to show?
			// Left side?
			// Start hiding the char, if it's moving out of the screen on the left side
			if(g_iPosition[client] > LINE_WIDTH)
			{
				Format(sTotalLine1, sizeof(sTotalLine1), "%s", sLine1[iCharLength-iMessageLength-LINE_WIDTH+g_iPosition[client]-1]);
				Format(sTotalLine2, sizeof(sTotalLine2), "%s", sLine2[iCharLength-iMessageLength-LINE_WIDTH+g_iPosition[client]-1]);
				Format(sTotalLine3, sizeof(sTotalLine3), "%s", sLine3[iCharLength-iMessageLength-LINE_WIDTH+g_iPosition[client]-1]);
				Format(sTotalLine4, sizeof(sTotalLine4), "%s", sLine4[iCharLength-iMessageLength-LINE_WIDTH+g_iPosition[client]-1]);
				Format(sTotalLine5, sizeof(sTotalLine5), "%s", sLine5[iCharLength-iMessageLength-LINE_WIDTH+g_iPosition[client]-1]);
			}
			// First time showing this one
			// Start showing part of the char, when moving in from the right
			else if(g_iPosition[client] < iMessageLength)
			{
				sLine1[iMessageLength-iCharLength+g_iPosition[client]] = 0;
				sLine2[iMessageLength-iCharLength+g_iPosition[client]] = 0;
				sLine3[iMessageLength-iCharLength+g_iPosition[client]] = 0;
				sLine4[iMessageLength-iCharLength+g_iPosition[client]] = 0;
				sLine5[iMessageLength-iCharLength+g_iPosition[client]] = 0;
				Format(sTotalLine1, sizeof(sTotalLine1), "%s%s", sTotalLine1, sLine1);
				Format(sTotalLine2, sizeof(sTotalLine2), "%s%s", sTotalLine2, sLine2);
				Format(sTotalLine3, sizeof(sTotalLine3), "%s%s", sTotalLine3, sLine3);
				Format(sTotalLine4, sizeof(sTotalLine4), "%s%s", sTotalLine4, sLine4);
				Format(sTotalLine5, sizeof(sTotalLine5), "%s%s", sTotalLine5, sLine5);
			}
			// Just show it completely
			// This happens during the starting, where the first char hasn't reached the right side yet, so he's just fully there.
			else
			{
				Format(sTotalLine1, sizeof(sTotalLine1), "%s%s", sTotalLine1, sLine1);
				Format(sTotalLine2, sizeof(sTotalLine2), "%s%s", sTotalLine2, sLine2);
				Format(sTotalLine3, sizeof(sTotalLine3), "%s%s", sTotalLine3, sLine3);
				Format(sTotalLine4, sizeof(sTotalLine4), "%s%s", sTotalLine4, sLine4);
				Format(sTotalLine5, sizeof(sTotalLine5), "%s%s", sTotalLine5, sLine5);
			}
		}
		// We already reached and handled the first char to draw. Handle the rest now
		else if(iStartChar != -1)
		{
			// Get the l33t font of the current char
			GetTrieValue(g_hAlphabet, sChar, hLine);
			GetArrayString(hLine, 0, sLine1, sizeof(sLine1));
			GetArrayString(hLine, 1, sLine2, sizeof(sLine2));
			GetArrayString(hLine, 2, sLine3, sizeof(sLine3));
			GetArrayString(hLine, 3, sLine4, sizeof(sLine4));
			GetArrayString(hLine, 4, sLine5, sizeof(sLine5));
			
			// This char isn't fully visible yet.
			// It's currently comming from the right
			if(g_iPosition[client] < iMessageLength)
			{
				sLine1[g_iPosition[client]-iMessageLength+iCharLength] = 0;
				sLine2[g_iPosition[client]-iMessageLength+iCharLength] = 0;
				sLine3[g_iPosition[client]-iMessageLength+iCharLength] = 0;
				sLine4[g_iPosition[client]-iMessageLength+iCharLength] = 0;
				sLine5[g_iPosition[client]-iMessageLength+iCharLength] = 0;
				
				Format(sTotalLine1, sizeof(sTotalLine1), "%s%s", sTotalLine1, sLine1);
				Format(sTotalLine2, sizeof(sTotalLine2), "%s%s", sTotalLine2, sLine2);
				Format(sTotalLine3, sizeof(sTotalLine3), "%s%s", sTotalLine3, sLine3);
				Format(sTotalLine4, sizeof(sTotalLine4), "%s%s", sTotalLine4, sLine4);
				Format(sTotalLine5, sizeof(sTotalLine5), "%s%s", sTotalLine5, sLine5);
			}
			// This is only a fully visible char somewhere in the message.
			else
			{
				Format(sTotalLine1, sizeof(sTotalLine1), "%s%s", sTotalLine1, sLine1);
				Format(sTotalLine2, sizeof(sTotalLine2), "%s%s", sTotalLine2, sLine2);
				Format(sTotalLine3, sizeof(sTotalLine3), "%s%s", sTotalLine3, sLine3);
				Format(sTotalLine4, sizeof(sTotalLine4), "%s%s", sTotalLine4, sLine4);
				Format(sTotalLine5, sizeof(sTotalLine5), "%s%s", sTotalLine5, sLine5);
			}
		}
		
		if(iStartChar != -1 && iMessageLength >= g_iPosition[client])
		{
			break;
		}
		
		if(IsCharMB(g_sText[client][i]))
			i += iBytes-1;
	}
	
	// Add whitespace to the end of the message to keep the LINE_WIDTH
	if(g_iPosition[client] > g_iMessageLength[client])
	{
		new iLimit;
		// Reduce the filled space, when the message has disappeared!
		if(g_iPosition[client] < g_iMessageLength[client]+LINE_WIDTH)
			iLimit = g_iPosition[client]-g_iMessageLength[client];
		else
			iLimit = g_iMessageLength[client]+LINE_WIDTH*2-g_iPosition[client];
		
		for(new i=0;i<=iLimit;i++)
		{
			Format(sTotalLine1, sizeof(sTotalLine1), "%s%s", sTotalLine1, LINE_EMPTY);
			Format(sTotalLine2, sizeof(sTotalLine2), "%s%s", sTotalLine2, LINE_EMPTY);
			Format(sTotalLine3, sizeof(sTotalLine3), "%s%s", sTotalLine3, LINE_EMPTY);
			Format(sTotalLine4, sizeof(sTotalLine4), "%s%s", sTotalLine4, LINE_EMPTY);
			Format(sTotalLine5, sizeof(sTotalLine5), "%s%s", sTotalLine5, LINE_EMPTY);
		}
	}
	
	// Replace the readable characters with the full width utf-8 ones
	ReplaceString(sTotalLine1, sizeof(sTotalLine1), "=", LINE_FILLED, false);
	ReplaceString(sTotalLine2, sizeof(sTotalLine2), "=", LINE_FILLED, false);
	ReplaceString(sTotalLine3, sizeof(sTotalLine3), "=", LINE_FILLED, false);
	ReplaceString(sTotalLine4, sizeof(sTotalLine4), "=", LINE_FILLED, false);
	ReplaceString(sTotalLine5, sizeof(sTotalLine5), "=", LINE_FILLED, false);
	ReplaceString(sTotalLine1, sizeof(sTotalLine1), "0", LINE_EMPTY, false);
	ReplaceString(sTotalLine2, sizeof(sTotalLine2), "0", LINE_EMPTY, false);
	ReplaceString(sTotalLine3, sizeof(sTotalLine3), "0", LINE_EMPTY, false);
	ReplaceString(sTotalLine4, sizeof(sTotalLine4), "0", LINE_EMPTY, false);
	ReplaceString(sTotalLine5, sizeof(sTotalLine5), "0", LINE_EMPTY, false);
	
	DrawPanelText(hPanel, sTotalLine1);
	DrawPanelText(hPanel, sTotalLine2);
	DrawPanelText(hPanel, sTotalLine3);
	DrawPanelText(hPanel, sTotalLine4);
	DrawPanelText(hPanel, sTotalLine5);
	
	SendPanelToClient(hPanel, client, Panel_DoNothing, 1);
	CloseHandle(hPanel);
	
	// Move to the next column
	g_iPosition[client]++;
	
	// We're done here, stop the timer etc
	if(g_iPosition[client] > g_iMessageLength[client]+LINE_WIDTH*2+1)
	{
		Marquee_Stop(client);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Panel_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	
}

PopulateAlphabet()
{
	new Handle:hLines;

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00==0");
	PushArrayString(hLines, "0=0=0");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=0=0");
	PushArrayString(hLines, "0=0=0");
	SetTrieValue(g_hAlphabet, "A", hLines);
	SetTrieValue(g_hCharLength, "A", 5);
	
	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0==000");
	PushArrayString(hLines, "0=0=00");
	PushArrayString(hLines, "0====0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0===00");
	SetTrieValue(g_hAlphabet, "B", hLines);
	SetTrieValue(g_hCharLength, "B", 6);
	
	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=000");
	PushArrayString(hLines, "0=000");
	PushArrayString(hLines, "0=000");
	PushArrayString(hLines, "0===0");
	SetTrieValue(g_hAlphabet, "C", hLines);
	SetTrieValue(g_hCharLength, "C", 5);
	
	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===00");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0===00");
	SetTrieValue(g_hAlphabet, "D", hLines);
	SetTrieValue(g_hCharLength, "D", 6);
	
	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=000");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=000");
	PushArrayString(hLines, "0===0");
	SetTrieValue(g_hAlphabet, "E", hLines);
	SetTrieValue(g_hCharLength, "E", 5);
	
	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=000");
	PushArrayString(hLines, "0==00");
	PushArrayString(hLines, "0=000");
	PushArrayString(hLines, "0=000");
	SetTrieValue(g_hAlphabet, "F", hLines);
	SetTrieValue(g_hCharLength, "F", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00==00");
	PushArrayString(hLines, "0=0000");
	PushArrayString(hLines, "0=0==0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "00==00");
	SetTrieValue(g_hAlphabet, "G", hLines);
	SetTrieValue(g_hCharLength, "G", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0====0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	SetTrieValue(g_hAlphabet, "H", hLines);
	SetTrieValue(g_hCharLength, "H", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "0===0");
	SetTrieValue(g_hAlphabet, "I", hLines);
	SetTrieValue(g_hCharLength, "I", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00===0");
	PushArrayString(hLines, "000=00");
	PushArrayString(hLines, "000=00");
	PushArrayString(hLines, "0=0=00");
	PushArrayString(hLines, "00==00");
	SetTrieValue(g_hAlphabet, "J", hLines);
	SetTrieValue(g_hCharLength, "J", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=0=00");
	PushArrayString(hLines, "0==000");
	PushArrayString(hLines, "0=0=00");
	PushArrayString(hLines, "0=00=0");
	SetTrieValue(g_hAlphabet, "K", hLines);
	SetTrieValue(g_hCharLength, "K", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=0000");
	PushArrayString(hLines, "0=0000");
	PushArrayString(hLines, "0=0000");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0====0");
	SetTrieValue(g_hAlphabet, "L", hLines);
	SetTrieValue(g_hCharLength, "L", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=000=0");
	PushArrayString(hLines, "0==0==0");
	PushArrayString(hLines, "0=0=0=0");
	PushArrayString(hLines, "0=000=0");
	PushArrayString(hLines, "0=000=0");
	SetTrieValue(g_hAlphabet, "M", hLines);
	SetTrieValue(g_hCharLength, "M", 7);
	
	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=000=0");
	PushArrayString(hLines, "0==00=0");
	PushArrayString(hLines, "0=0=0=0");
	PushArrayString(hLines, "0=00==0");
	PushArrayString(hLines, "0=000=0");
	SetTrieValue(g_hAlphabet, "N", hLines);
	SetTrieValue(g_hCharLength, "N", 7);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00==00");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "00==00");
	SetTrieValue(g_hAlphabet, "O", hLines);
	SetTrieValue(g_hCharLength, "O", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=0=0");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=000");
	PushArrayString(hLines, "0=000");
	SetTrieValue(g_hAlphabet, "P", hLines);
	SetTrieValue(g_hCharLength, "P", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00==000");
	PushArrayString(hLines, "0=00=00");
	PushArrayString(hLines, "0=00=00");
	PushArrayString(hLines, "0=0==00");
	PushArrayString(hLines, "00====0");
	SetTrieValue(g_hAlphabet, "Q", hLines);
	SetTrieValue(g_hCharLength, "Q", 7);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===00");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0===00");
	PushArrayString(hLines, "0=0=00");
	PushArrayString(hLines, "0=00=0");
	SetTrieValue(g_hAlphabet, "R", hLines);
	SetTrieValue(g_hCharLength, "R", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00==00");
	PushArrayString(hLines, "0=0000");
	PushArrayString(hLines, "0====0");
	PushArrayString(hLines, "0000=0");
	PushArrayString(hLines, "0===00");
	SetTrieValue(g_hAlphabet, "S", hLines);
	SetTrieValue(g_hCharLength, "S", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=====0");
	PushArrayString(hLines, "000=000");
	PushArrayString(hLines, "000=000");
	PushArrayString(hLines, "000=000");
	PushArrayString(hLines, "000=000");
	SetTrieValue(g_hAlphabet, "T", hLines);
	SetTrieValue(g_hCharLength, "T", 7);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "00===0");
	SetTrieValue(g_hAlphabet, "U", hLines);
	SetTrieValue(g_hCharLength, "U", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=000=0");
	PushArrayString(hLines, "0=000=0");
	PushArrayString(hLines, "0=000=0");
	PushArrayString(hLines, "00=0=00");
	PushArrayString(hLines, "000=000");
	SetTrieValue(g_hAlphabet, "V", hLines);
	SetTrieValue(g_hCharLength, "V", 7);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=00000=0");
	PushArrayString(hLines, "0=00000=0");
	PushArrayString(hLines, "0=00000=0");
	PushArrayString(hLines, "00=0=0=00");
	PushArrayString(hLines, "000=0=000");
	SetTrieValue(g_hAlphabet, "W", hLines);
	SetTrieValue(g_hCharLength, "W", 9);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=000=0");
	PushArrayString(hLines, "00=0=00");
	PushArrayString(hLines, "000=000");
	PushArrayString(hLines, "00=0=00");
	PushArrayString(hLines, "0=000=0");
	SetTrieValue(g_hAlphabet, "X", hLines);
	SetTrieValue(g_hCharLength, "X", 7);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "=000=0");
	PushArrayString(hLines, "=000=0");
	PushArrayString(hLines, "0=0=00");
	PushArrayString(hLines, "00=000");
	PushArrayString(hLines, "00=000");
	SetTrieValue(g_hAlphabet, "Y", hLines);
	SetTrieValue(g_hCharLength, "Y", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=====0");
	PushArrayString(hLines, "0000=00");
	PushArrayString(hLines, "000=000");
	PushArrayString(hLines, "00=0000");
	PushArrayString(hLines, "0=====0");
	SetTrieValue(g_hAlphabet, "Z", hLines);
	SetTrieValue(g_hCharLength, "Z", 7);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=0=0");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "0=0=0");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=0=0");
	SetTrieValue(g_hAlphabet, "Ä", hLines);
	SetTrieValue(g_hCharLength, "Ä", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "00==00");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "00==00");
	SetTrieValue(g_hAlphabet, "Ö", hLines);
	SetTrieValue(g_hCharLength, "Ö", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "000000");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "00===0");
	SetTrieValue(g_hAlphabet, "Ü", hLines);
	SetTrieValue(g_hCharLength, "Ü", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00000");
	PushArrayString(hLines, "00000");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "00000");
	PushArrayString(hLines, "00000");
	SetTrieValue(g_hAlphabet, "-", hLines);
	SetTrieValue(g_hCharLength, "-", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00000");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "00000");
	SetTrieValue(g_hAlphabet, "+", hLines);
	SetTrieValue(g_hCharLength, "+", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "0=0");
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "0=0");
	PushArrayString(hLines, "000");
	SetTrieValue(g_hAlphabet, ":", hLines);
	SetTrieValue(g_hCharLength, ":", 3);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "0=0");
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "0=0");
	PushArrayString(hLines, "0=0");
	SetTrieValue(g_hAlphabet, ";", hLines);
	SetTrieValue(g_hCharLength, ";", 3);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=0");
	PushArrayString(hLines, "0=0");
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "000");
	SetTrieValue(g_hAlphabet, "'", hLines);
	SetTrieValue(g_hCharLength, "'", 3);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0==0");
	PushArrayString(hLines, "0==0");
	PushArrayString(hLines, "0000");
	PushArrayString(hLines, "0000");
	PushArrayString(hLines, "0000");
	SetTrieValue(g_hAlphabet, "\"", hLines);
	SetTrieValue(g_hCharLength, "\"", 4);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00=0");
	PushArrayString(hLines, "0=00");
	PushArrayString(hLines, "0=00");
	PushArrayString(hLines, "0=00");
	PushArrayString(hLines, "00=0");
	SetTrieValue(g_hAlphabet, "(", hLines);
	SetTrieValue(g_hCharLength, "(", 4);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=00");
	PushArrayString(hLines, "00=0");
	PushArrayString(hLines, "00=0");
	PushArrayString(hLines, "00=0");
	PushArrayString(hLines, "0=00");
	SetTrieValue(g_hAlphabet, ")", hLines);
	SetTrieValue(g_hCharLength, ")", 4);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0==0");
	PushArrayString(hLines, "0=00");
	PushArrayString(hLines, "0=00");
	PushArrayString(hLines, "0=00");
	PushArrayString(hLines, "0==0");
	SetTrieValue(g_hAlphabet, "[", hLines);
	SetTrieValue(g_hCharLength, "[", 4);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0==0");
	PushArrayString(hLines, "00=0");
	PushArrayString(hLines, "00=0");
	PushArrayString(hLines, "00=0");
	PushArrayString(hLines, "0==0");
	SetTrieValue(g_hAlphabet, "]", hLines);
	SetTrieValue(g_hCharLength, "]", 4);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0==0");
	PushArrayString(hLines, "0=00");
	PushArrayString(hLines, "==00");
	PushArrayString(hLines, "0=00");
	PushArrayString(hLines, "0==0");
	SetTrieValue(g_hAlphabet, "{", hLines);
	SetTrieValue(g_hCharLength, "{", 4);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0==00");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "00==0");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "0==00");
	SetTrieValue(g_hAlphabet, "}", hLines);
	SetTrieValue(g_hCharLength, "}", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00000");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "00000");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "00000");
	SetTrieValue(g_hAlphabet, "=", hLines);
	SetTrieValue(g_hCharLength, "=", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00000");
	PushArrayString(hLines, "000=0");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "0=000");
	PushArrayString(hLines, "00000");
	SetTrieValue(g_hAlphabet, "/", hLines);
	SetTrieValue(g_hCharLength, "/", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00000");
	PushArrayString(hLines, "0=000");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "000=0");
	PushArrayString(hLines, "00000");
	SetTrieValue(g_hAlphabet, "\\", hLines);
	SetTrieValue(g_hCharLength, "\\", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00==00");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "000=00");
	PushArrayString(hLines, "00=000");
	PushArrayString(hLines, "00=000");
	SetTrieValue(g_hAlphabet, "?", hLines);
	SetTrieValue(g_hCharLength, "?", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "00000");
	PushArrayString(hLines, "00=00");
	SetTrieValue(g_hAlphabet, "!", hLines);
	SetTrieValue(g_hCharLength, "!", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "0==00");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "0===0");
	SetTrieValue(g_hAlphabet, "1", hLines);
	SetTrieValue(g_hCharLength, "1", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00==00");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "000=00");
	PushArrayString(hLines, "00=000");
	PushArrayString(hLines, "0====0");
	SetTrieValue(g_hAlphabet, "2", hLines);
	SetTrieValue(g_hCharLength, "2", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "000=0");
	PushArrayString(hLines, "00==0");
	PushArrayString(hLines, "000=0");
	PushArrayString(hLines, "0===0");
	SetTrieValue(g_hAlphabet, "3", hLines);
	SetTrieValue(g_hCharLength, "3", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0=0=0");
	PushArrayString(hLines, "0=0=0");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "000=0");
	PushArrayString(hLines, "000=0");
	SetTrieValue(g_hAlphabet, "4", hLines);
	SetTrieValue(g_hCharLength, "4", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=000");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "000=0");
	PushArrayString(hLines, "0===0");
	SetTrieValue(g_hAlphabet, "5", hLines);
	SetTrieValue(g_hCharLength, "5", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=000");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=0=0");
	PushArrayString(hLines, "0===0");
	SetTrieValue(g_hAlphabet, "6", hLines);
	SetTrieValue(g_hCharLength, "6", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "000=0");
	PushArrayString(hLines, "000=0");
	PushArrayString(hLines, "00=00");
	PushArrayString(hLines, "00=00");
	SetTrieValue(g_hAlphabet, "7", hLines);
	SetTrieValue(g_hCharLength, "7", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=0=0");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=0=0");
	PushArrayString(hLines, "0===0");
	SetTrieValue(g_hAlphabet, "8", hLines);
	SetTrieValue(g_hCharLength, "8", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "0=0=0");
	PushArrayString(hLines, "0===0");
	PushArrayString(hLines, "000=0");
	PushArrayString(hLines, "0===0");
	SetTrieValue(g_hAlphabet, "9", hLines);
	SetTrieValue(g_hCharLength, "9", 5);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "00==00");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "0=00=0");
	PushArrayString(hLines, "00==00");
	SetTrieValue(g_hAlphabet, "0", hLines);
	SetTrieValue(g_hCharLength, "0", 6);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "0=0");
	SetTrieValue(g_hAlphabet, ".", hLines);
	SetTrieValue(g_hCharLength, ".", 3);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "000");
	PushArrayString(hLines, "0=0");
	PushArrayString(hLines, "0=0");
	SetTrieValue(g_hAlphabet, ",", hLines);
	SetTrieValue(g_hCharLength, ",", 3);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0000");
	PushArrayString(hLines, "0==0");
	PushArrayString(hLines, "0==0");
	PushArrayString(hLines, "0000");
	PushArrayString(hLines, "0000");
	SetTrieValue(g_hAlphabet, "*", hLines);
	SetTrieValue(g_hCharLength, "*", 4);

	hLines = CreateArray(ByteCountToCells(15));
	PushArrayString(hLines, "0000");
	PushArrayString(hLines, "0000");
	PushArrayString(hLines, "0000");
	PushArrayString(hLines, "0000");
	PushArrayString(hLines, "0000");
	SetTrieValue(g_hAlphabet, " ", hLines);
	SetTrieValue(g_hCharLength, " ", 4);
}