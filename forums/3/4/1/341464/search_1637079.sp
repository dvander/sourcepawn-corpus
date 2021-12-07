/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
public Plugin:myinfo = 
{
	name = "In-Game Search",
	author = "341464",
	description = "Search on Websites In-Game",
	version = "1.02",
	url = "341464.webs.com"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_google",Command_google,"Search with Google");
	RegConsoleCmd("sm_youtube",Command_youtube,"Search on YouTube");
	RegConsoleCmd("sm_bing",Command_bing,"Search on Bing");
	
}

public Action:Command_google(client,args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_google <keyword>");
	return Plugin_Handled;
		
	}
	new String:google[256] = "www.google.com/#hl=en-us&site=&aq=f&aqi=g10&fp=5994226c06c8803d&q="
	decl String:szKeyword[128] = "";
	GetCmdArg (1, szKeyword, sizeof (szKeyword));
	StrCat(google,256,szKeyword);
	ShowMOTDPanel(client, "Google Search", google,MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}
public Action:Command_youtube(client,args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_youtube <keyword>");
	return Plugin_Handled;
	}
	new String:YouTube[256] = "www.youtube.com/results?search_query="
	decl String:szKeyword[128] = "";
	GetCmdArg (1, szKeyword, sizeof (szKeyword));
	StrCat(YouTube,256,szKeyword);
	ShowMOTDPanel(client, "YouTube Search", YouTube,MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}
public Action:Command_bing(client,args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_bing <keyword>");
	return Plugin_Handled;
	}
	new String:bing[256] = "www.bing.com/search?go=&qs=n&sk=&form=QBLH&filt=all"
	decl String:szKeyword[128] = "";
	GetCmdArg (1, szKeyword, sizeof (szKeyword));
	StrCat(bing,256,szKeyword);
	ShowMOTDPanel(client, "Bing Search", bing,MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}