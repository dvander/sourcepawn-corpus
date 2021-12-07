#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
//#include <colors> // v2

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D1 & L4D2] Animated chat christmas tree",
	author = "Dragokas",
	description = "Displays color animated christmas tree in the chat on finale win",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/groups/Bloody_Witch"
}

char g_color[4][] = {
	"\x01", 
	"\x03", 
	"\x04",
	"\x05"
};

int iRepeat;

public void OnPluginStart()
{
	CreateConVar("l4d_xmas_animchat_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	RegConsoleCmd("sm_animchat", CmdXMAS, "Display / Hide the animated christmas tree in the chat instantly");
	
	RegConsoleCmd("say", Cmd_Delay);
	RegConsoleCmd("say_team", Cmd_Delay);
	
	HookEventEx("finale_escape_start",		Event_EscapeStart,		EventHookMode_PostNoCopy);
}

public void Event_EscapeStart(Event event, const char[] name, bool dontBroadcast)
{
	CmdXMAS(0, 0);
}

public Action CmdXMAS(int client, int args)
{
	const int NUM_PRESETS = 2;
	static int iNext = -1;
	iRepeat ^= 1;
	
	if (iRepeat)
	{
		++iNext;
		
		if (iNext >= NUM_PRESETS)
		{
			iNext = 0;
		}
		
		switch (iNext) {
			case 0: CreateTimer(0.5, Timer_XMAS_1, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			case 1: CreateTimer(0.5, Timer_XMAS_2, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else {
		PrintToChatAll("Animation is disabled.");
	}
	return Plugin_Handled;
}

public Action Cmd_Delay(int client, int args) // Delays animation for some time whenever somebody wants to speaking in the chat
{
	if( iRepeat )
	{
		iRepeat = 0;
		CreateTimer(3.0, Timer_XMAS_Delayed, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public void OnMapEnd()
{
	iRepeat = 0;
}

Action Timer_XMAS_Delayed(Handle timer)
{
	CmdXMAS(0, 0);
}

Action Timer_XMAS_1(Handle timer)
{
	if( iRepeat == 0 )
		return Plugin_Stop;

	const int LINE_MAX = 6;
	char s[192];
	int sc;
	
	static int dir = -1;
	static int iLine = 0;
	
	iLine += dir;
	
	if( iLine > LINE_MAX )
	{
		iLine = LINE_MAX - 1;
		dir *= -1;
	}
	if( iLine < 0 )
	{
		iLine = 1;
		dir *= -1;
	}
	
	char head[][64] =
	{
		"\n\n\n"...
		"\x04─────────☆",
		"───────✷▄█▄✷",
		"──────✷▄▄██▄▄✷",
		"──────✷▄███▄▄✷",
		"─────✷▄▄█████▄▄✷",
		"────✷▄▄███████▄▄✷",
		"───✷▄▄█████████▄▄✷",
		"────────\x04▓▓▓────────"
	};
	
	for( int i = 0; i < sizeof(head); i++ )
	{
		Format(head[i], sizeof(head[]), "\x01%s", head[i]);
		ReplaceString(head[i], sizeof(head[]), "─", "   ");
	}

	sc = 2; // GetRandomInt(3, 4);
	
	/*
	if (GetRandomInt(0, 1) == 0)
		sc = 2;
	else
		sc = 1;
	*/

	for( int i = 0; i < sizeof(head); i++ )
	{
		s = head[i];
		
		if( i == 0 && iLine == 0 ) {
			ReplaceString(s, sizeof(s), "☆", "★");
		}
		else if( i == iLine ) {
			ReplaceString(s, sizeof(s), "✷", "c✷\x05");
			ReplaceString(s, sizeof(s), "c", g_color[sc]);
		}
		else {
			ReplaceString(s, sizeof(s), "✷", "\x03✷\x05");
		}
		
		PrintToChatAll(s);
		//SayTextAll(s);
	}
	
	return iRepeat ? Plugin_Continue : Plugin_Stop;
}

Action Timer_XMAS_2(Handle timer)
{
	if( iRepeat == 0 )
		return Plugin_Stop;

	const int MAX_LEN = 64;

	int i, gc, sc;
	static bool bInit;
	static char s[MAX_LEN];
	
	static char head[3][MAX_LEN] =
	{
		"\n\n\n"...
		"\x01__________ \x05╔╗ ╔╗ ╔╗ ╔╗\x01_________",
		"\x01__________ \x05╔╝ ║║ ╔╝ ╔╝\x01_________",
		"\x01__________ \x05╚═ ╚╝ ╚═ ╚═\x01_________"
	};
	
	static char body[4][MAX_LEN] =
	{
		"\x01__☆___________*___________☆_",
		"\x01______☆______*o*______☆_____",
		"\x01_☆__________*o*o*_________☆_",
		"\x01_____☆_____*o*o*o*_____☆____",
		//"\x01______________|.|_____________"
	};
	
	if( !bInit )
	{
		bInit = true;
		for( i = 0; i < sizeof(body); i++ )
		{
			ReplaceString(body[i], sizeof(body[]), "*", "g*\x01");
			ReplaceString(body[i], sizeof(body[]), "☆", "s☆\x01");
		}
	}
	
	for( i = 0; i < sizeof(head); i++ )
	{
		if (iRepeat)
		{
			//PrintToChatAll(head[i]);
			SayTextAll(head[i]);
		}
	}
	
	// girland color
	//gc = GetRandomInt(1, sizeof(g_color) - 1);
	gc = GetRandomInt(1, 3);
	//gc = 4;
	
	for( i = 0; i < sizeof(body); i++ )
	{
		// star color
		//sc = GetRandomInt(0, sizeof(g_color) - 1);
		sc = GetRandomInt(0, 3);
		
		strcopy(s, sizeof(s), body[i]);
		ReplaceString(s, sizeof(s), "g", g_color[gc]);
		ReplaceString(s, sizeof(s), "s", g_color[sc]);
		
		/*
		if (GetRandomInt(0, 1) == 0)
			ReplaceString(s, sizeof(s), "☆", "{red}★");
		*/
		
		if( iRepeat )
		{
			SayTextAll(s);
			//PrintToChatAll(s);
		}
	}
	
	return iRepeat ? Plugin_Continue : Plugin_Stop;
}

void SayTextAll(const char[] format, any ...)
{
	char sMessage[250];
	VFormat(sMessage, sizeof(sMessage), format, 2);

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			SayText(i, i, sMessage);
		}
	}
}

void SayText(int client, int author, const char[] format, any ...)
{
	char sMessage[250];
	VFormat(sMessage, sizeof(sMessage), format, 4);

	Handle hBuffer = StartMessageOne("SayText2", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, sMessage);
	EndMessage();
} 
