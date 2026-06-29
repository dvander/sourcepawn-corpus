#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.1"

new bool:_bColored[MAXPLAYERS+1];
new String:_sColor[MAXPLAYERS+1][64];

public Plugin:myinfo =
{
	name = "Colorized Chat",
	author = "EasSidezz - Edited by Marcus",
	description = "Provides custom colors for a player's chat.",
	version = PLUGIN_VERSION,
	url = "http://www.Sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("colortext_version", PLUGIN_VERSION, "The version of this plugin the server is running.", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);	

	RegAdminCmd("sm_color", Command_Color, 0);
	
	AddCommandListener(HookPlayerChat, "say");
}

public OnClientPutInServer(client)
{
	if (IsValidClient(client))
	{
		_bColored[client] = false;
		_sColor[client] = "";
	}
}

public Action:Command_Color(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_color <color|off>");
		return Plugin_Handled;
	}
	
	decl String:sArg[64];
	GetCmdArg(1, sArg, sizeof(sArg));
	
	if (StrEqual(sArg, "green", false))
	{
		_sColor[client] = "\x073EFF3E";
		PrintToChat2(client, "\x01[\x04Notice\x01] You have set your chat color to \x073EFF3Egreen\x01.");
		
	} else if (StrEqual(sArg, "red", false))
	{
		_sColor[client] = "\x07FF4040";
		PrintToChat2(client, "\x01[\x04Notice\x01] You have set your chat color to \x07FF4040red\x01.");
	} else if (StrEqual(sArg, "blue", false))
	{
		_sColor[client] = "\x0799CCFF";
		PrintToChat2(client, "\x01[\x04Notice\x01] You have set your chat color to \x0799CCFFblue\x01.");
	} else if (StrEqual(sArg, "black", false))
	{
		_sColor[client] = "\x07000000";
		PrintToChat2(client, "\x01[\x04Notice\x01] You have set your chat color to \x07000000black\x01.");
	} else if (StrEqual(sArg, "orange", false))
	{
		_sColor[client] = "\x07FFA500";
		PrintToChat2(client, "\x01[\x04Notice\x01] You have set your chat color to \x07FFA500orange\x01.");
	} else if (StrEqual(sArg, "olive", false))
	{
		_sColor[client] = "\x079EC34F";
		PrintToChat2(client, "\x01[\x04Notice\x01] You have set your chat color to \x079EC34Folive\x01.");
	} else if (StrEqual(sArg, "brown", false))
	{
		_sColor[client] = "\x07A52A2A";
		PrintToChat2(client, "\x01[\x04Notice\x01] You have set your chat color to \x07A52A2Abrown\x01.");
	} else if (StrEqual(sArg, "gray", false))
	{
		_sColor[client] = "\x07CCCCCC";
		PrintToChat2(client, "\x01[\x04Notice\x01] You have set your chat color to \x07CCCCCCgray\x01.");
	} else if (StrEqual(sArg, "pink", false))
	{
		_sColor[client] = "\x07FF69B4";
		PrintToChat2(client, "\x01[\x04Notice\x01] You have set your chat color to \x07FF69B4prink\x01.");
	} else if (StrEqual(sArg, "off", false))
	{
		_sColor[client] = "";
		PrintToChat2(client, "\x01[\x04Notice\x01] You have turned you chat color off.");
	}
	
	_bColored[client] = true;
	
	if (StrEqual(_sColor[client], ""))
	{
		_bColored[client] = false;
	}
	
	return Plugin_Handled;
}

public Action:HookPlayerChat(client, const String:command[], args)
{
	decl String:sText[256];
	
	sText[0] = '\0';
	GetCmdArg(1, sText, sizeof(sText));
	
	if (IsValidClient(client) && _bColored[client])
	{
		if (sText[0] != '/' && sText[0] != '!')
		{
			StripQuotes(sText);
			PrintToChatAll2("\x01%N: %s%s", client, _sColor[client], sText);
			PrintToServer("%N: %s", client, sText); // Prints to console, withoutit, if you are looking you won't see the colored chat.
		}
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

stock bool:IsValidClient(client) 
{
    if ((1 <= client <= MaxClients) && IsClientInGame(client)) 
        return true; 
     
    return false; 
}

public PrintToChat2(client, const String:format[], any:...)
{
	decl String:buffer[256];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	
	new Handle:bf = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWriteByte(bf, -1);
	BfWriteByte(bf, true);
	BfWriteString(bf, buffer);
	EndMessage();
}

public PrintToChatAll2(const String:format[], any:...)
{
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	new Handle:bf = StartMessageAll("SayText2", USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWriteByte(bf, -1);
	BfWriteByte(bf, true);
	BfWriteString(bf, buffer);
	EndMessage();
}