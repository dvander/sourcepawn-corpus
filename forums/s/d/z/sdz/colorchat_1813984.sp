#include <sourcemod>
#include <sdktools>
#include <morecolors>
#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Colored Chat Texts",
	author = "EasSidezz",
	description = "Colored Text Chatting",
	version = "1.0",
	url = "http://www.Sourcemod.net"
};

public OnPluginStart()
{
	
	RegConsoleCmd("sm_green", greenText);	
	RegConsoleCmd("sm_red", redText);
	RegConsoleCmd("sm_blue", blueText);
	RegConsoleCmd("sm_black", blackText);
	RegConsoleCmd("sm_orange", orangeText);
	RegConsoleCmd("sm_olive", oliveText);
	RegConsoleCmd("sm_brown", brownText);
	RegConsoleCmd("sm_gray", grayText);
	RegConsoleCmd("sm_pink", pinkText);
	CreateConVar("colortext_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);	
}

public IsValidClient( client ) 
{ 
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
		return false; 
	
	return true; 
}

public Action:greenText(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	if(args < 1) 
	{
		ReplyToCommand(client, "[SM] use: sm_green <text>");
		return Plugin_Handled;
	}
	
	decl String:CleanText[192];
	GetCmdArg(1, CleanText,sizeof(CleanText));
	StripQuotes(CleanText);
	
	CPrintToChatAllEx(client, "{default}%N: {green}%s", client,CleanText);
	
	return Plugin_Handled;
	
}
public Action:blackText(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] use: sm_black <text>");
		return Plugin_Handled;
	}
	
	decl String:CleanText[192];
	GetCmdArg(1, CleanText,sizeof(CleanText));
	StripQuotes(CleanText);
	
	CPrintToChatAllEx(client, "{default}%N: {black}%s", client,CleanText);
	
	return Plugin_Handled;
}
public Action:redText(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] use: sm_red <text>");
		return Plugin_Handled;
	}
	
	decl String:CleanText[192];
	GetCmdArg(1, CleanText,sizeof(CleanText));
	StripQuotes(CleanText);
	
	CPrintToChatAllEx(client, "{default}%N: {red}%s", client,CleanText);
	
	return Plugin_Handled;
}
public Action:brownText(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] use: sm_brown <text>");
		return Plugin_Handled;
	}
	
	decl String:CleanText[192];
	GetCmdArg(1, CleanText,sizeof(CleanText));
	StripQuotes(CleanText);
	
	CPrintToChatAllEx(client, "{default}%N: {brown}%s", client,CleanText);
	
	return Plugin_Handled;
}
public Action:blueText(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] use: sm_blue <text>");
		return Plugin_Handled;
	}
	
	decl String:CleanText[192];
	GetCmdArg(1, CleanText,sizeof(CleanText));
	StripQuotes(CleanText);
	
	CPrintToChatAllEx(client, "{default}%N: {blue}%s", client,CleanText);
	
	return Plugin_Handled;
}
public Action:oliveText(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	if(args < 1) 
	{
		ReplyToCommand(client, "[SM] use: sm_olive <text>");
		return Plugin_Handled;
	}
	
	decl String:CleanText[192];
	GetCmdArg(1, CleanText,sizeof(CleanText));
	StripQuotes(CleanText);
	
	CPrintToChatAllEx(client, "{default}%N: {olive}%s", client,CleanText);
	
	return Plugin_Handled;
}
public Action:orangeText(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	if(args < 1) 
	{
		ReplyToCommand(client, "[SM] use: sm_orange <text>");
		return Plugin_Handled;
	}
	
	decl String:CleanText[192];
	GetCmdArg(1, CleanText,sizeof(CleanText));
	StripQuotes(CleanText);
	
	CPrintToChatAllEx(client, "{default}%N: {orange}%s", client,CleanText);
	
	return Plugin_Handled;
}
public Action:grayText(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	if(args < 1) 
	{
		ReplyToCommand(client, "[SM] use: sm_gray <text>");
		return Plugin_Handled;
	}
	
	decl String:CleanText[192];
	GetCmdArg(1, CleanText,sizeof(CleanText));
	StripQuotes(CleanText);
	
	CPrintToChatAllEx(client, "{default}%N: {gray}%s", client,CleanText);
	
	return Plugin_Handled;
}
public Action:pinkText(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	if(args < 1) 
	{
		ReplyToCommand(client, "[SM] use: sm_pink <text>");
		return Plugin_Handled;
	}
	
	decl String:CleanText[192];
	GetCmdArg(1, CleanText,sizeof(CleanText));
	StripQuotes(CleanText);
	
	CPrintToChatAllEx(client, "{default}%N: {hotpink}%s", client,CleanText);
	
	return Plugin_Handled;
}