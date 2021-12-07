#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <clientprefs>

#define PLUGIN_VERSION "1.1"
new String:g_hClientColor[MAXPLAYERS+1][32];
new Handle:g_hCoookieClientColor = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Greentexter",
	author = "Rowedahelicon, Multicolor and preferences mod by YoNer",
	description = "My First Plugin - Allows users to do Greentexting",
	version = "1.1yc",
	url = "http://www.rowedahelicon.com"
};


public OnPluginStart()
{
	RegConsoleCmd("sm_g", greenText);	
	RegConsoleCmd("sm_green", greenText);	
	RegConsoleCmd("sm_l", greenText);	
	RegConsoleCmd("sm_lenny", greenText);	
	RegConsoleCmd("sm_gweb", greenWeb);	
	RegConsoleCmd("sm_gcon", greenCon);	
	RegConsoleCmd("sm_gdefault", greenDefault);	
	RegConsoleCmd("sm_greset", greenReset);	
	
	g_hCoookieClientColor = RegClientCookie("GTColor", "This stores the default color user by the GreenText plugin", CookieAccess_Public);
	
	CreateConVar("greentext_version", PLUGIN_VERSION, "Plugin Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	

	DBLoadColors();

}

public DBLoadColors()
{
	//Loads colors for all current clients
	new clientCount = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			if (AreClientCookiesCached(i))
			{
			GetClientCookie(i, g_hCoookieClientColor, g_hClientColor[i], 32);
			}
			clientCount++;
		}
			
	}
	
}
		


public OnClientConnected(client)
{
	//Loads colors for newly connected clients
	GetClientCookie(client, g_hCoookieClientColor, g_hClientColor[client], 32);

}


public OnClientCookiesCached(client)
{
	//Loads colors when client cookies are cached
    GetClientCookie(client, g_hCoookieClientColor, g_hClientColor[client], 32);
	
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
	if(args < 1) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] use: sm_g <text> or sm_green <text> ");
		ReplyToCommand(client, "[SM] {color} to change the font color ( I.E.: This text is in {red}red )");
		ReplyToCommand(client, "[SM] sm_gweb to see the available color list on your MOTD window");
		ReplyToCommand(client, "[SM] sm_gcon to see it on your console");
		ReplyToCommand(client, "[SM] sm_gdefault to set a default color");
		ReplyToCommand(client, "[SM] sm_greset to reset default color to green");
		return Plugin_Handled;
	}
	
	//Set a buffer for the color to be used in chat print
	new String:printcolor[32];
	Format(printcolor, 32, "%s",g_hClientColor[client]);
	ReplaceString(printcolor, 32, "{", "", false);
	ReplaceString(printcolor, 32, "}", "", false);
	//if default color set for client is invalid, use green instead
	if (!CColorExists(printcolor))
	{
		Format(printcolor, 32, "{green}");
	}
	else
	{
		Format(printcolor, 32, "{%s}", printcolor);
	}
	
	//get full command string , remove command. This lets you not use quotes around text 
	new String:argsize[11];
	GetCmdArg(0, argsize, sizeof(argsize));
	new String:Message[512+11];
	GetCmdArgString(Message, sizeof(Message));
	ReplaceStringEx(Message,sizeof(Message),argsize,"", -1, -1, false);
	
	//check which command was used, if lennny, then add lenny godammit 
	if (StrEqual(argsize,"sm_l") || StrEqual(argsize, "sm_lenny"))
	{
			CPrintToChatAllEx(client, "{teamcolor}%N | ( ͡° ͜ʖ ͡°) | %s> %s", client, printcolor, Message);
	}
	else
	{
			CPrintToChatAllEx(client, "{teamcolor}%N: %s> %s", client, printcolor, Message);
	}


	return Plugin_Handled;

}
public Action:greenWeb(client, args)
{
	//displays the color list from the original morecolors website on the MOTD box
if(!IsValidClient(client))
return Plugin_Handled;

ShowMOTDPanel(client, "Greentext Colors", "https://www.doctormckay.com/morecolors.php",MOTDPANEL_TYPE_URL);

return Plugin_Handled;

}   
public Action:greenDefault(client, args)
{
	
if(!IsValidClient(client))
return Plugin_Handled;
new argcount;
argcount = GetCmdArgs();

if (argcount < 1)
{	
	ReplyToCommand(client, "Usage: sm_gdefault {color}");
	ReplyToCommand(client, "Use sm_gweb to see the available color list on your MOTD window");
	ReplyToCommand(client, "Use sm_gcon to see it on your console");
	return Plugin_Handled;
}
//get the color name selected strip invalid characters (ccolorexists function needs only the color name)) 
new String:argcolor[32];
GetCmdArgString(argcolor, 32);

ReplaceString(argcolor, 32, "\"", "", false);
ReplaceString(argcolor, 32, "{", "", false);
ReplaceString(argcolor, 32, "}", "", false);


if (!CColorExists(argcolor))
{
	ReplyToCommand(client, "Color does not exist");
	ReplyToCommand(client, "Use sm_gweb to see the available color list on your MOTD window");
	ReplyToCommand(client, "Use sm_gcon to see it on your console");
	return Plugin_Handled;
} 

//since color is valid, set the clients default color and store the cookie
Format(g_hClientColor[client], 32, "{%s}", argcolor);


SetClientCookie(client,  g_hCoookieClientColor, g_hClientColor[client]);

ReplyToCommand(client, "Your default GreenText color has been set to %s", g_hClientColor[client]);
return Plugin_Handled;

}   
public Action:greenReset(client, args)
{
if(!IsValidClient(client))
return Plugin_Handled;
//simply reset the clients default color to green
Format(g_hClientColor[client], 32, "{green}");
SetClientCookie(client, g_hCoookieClientColor, g_hClientColor[client]);

ReplyToCommand(client, "GreenText reset to default {green} color");


return Plugin_Handled;

}   
   
public Action:greenCon(client, args)
{
if(!IsValidClient(client))
return Plugin_Handled;
//printout all valid colors to console
ReplyToCommand(client, "[SM] See console for a list of available colors. ");

PrintToConsole(client, "%s", "-----------------------------------------------");
PrintToConsole(client, "%s", "-----------------------------------------------");
PrintToConsole(client, "%s", "------------GREENTEXT COLORS LIST--------------");
PrintToConsole(client, "%s", "-----------------------------------------------");
PrintToConsole(client, "%s", "-----------------------------------------------");
PrintToConsole(client, "%s", "{aliceblue}");
PrintToConsole(client, "%s", "{allies}");
PrintToConsole(client, "%s", "{ancient}");
PrintToConsole(client, "%s", "{antiquewhite}");
PrintToConsole(client, "%s", "{aqua}");
PrintToConsole(client, "%s", "{aquamarine}");
PrintToConsole(client, "%s", "{arcana}");
PrintToConsole(client, "%s", "{axis}");
PrintToConsole(client, "%s", "{azure}");
PrintToConsole(client, "%s", "{beige}");
PrintToConsole(client, "%s", "{bisque}");
PrintToConsole(client, "%s", "{black}");
PrintToConsole(client, "%s", "{blanchedalmond}");
PrintToConsole(client, "%s", "{blue}");
PrintToConsole(client, "%s", "{blueviolet}");
PrintToConsole(client, "%s", "{brown}");
PrintToConsole(client, "%s", "{burlywood}");
PrintToConsole(client, "%s", "{cadetblue}");
PrintToConsole(client, "%s", "{chartreuse}");
PrintToConsole(client, "%s", "{chocolate}");
PrintToConsole(client, "%s", "{collectors}");
PrintToConsole(client, "%s", "{common}");
PrintToConsole(client, "%s", "{community}");
PrintToConsole(client, "%s", "{coral}");
PrintToConsole(client, "%s", "{cornflowerblue}");
PrintToConsole(client, "%s", "{cornsilk}");
PrintToConsole(client, "%s", "{corrupted}");
PrintToConsole(client, "%s", "{crimson}");
PrintToConsole(client, "%s", "{cyan}");
PrintToConsole(client, "%s", "{darkblue}");
PrintToConsole(client, "%s", "{darkcyan}");
PrintToConsole(client, "%s", "{darkgoldenrod}");
PrintToConsole(client, "%s", "{darkgray}");
PrintToConsole(client, "%s", "{darkgrey}");
PrintToConsole(client, "%s", "{darkgreen}");
PrintToConsole(client, "%s", "{darkkhaki}");
PrintToConsole(client, "%s", "{darkmagenta}");
PrintToConsole(client, "%s", "{darkolivegreen}");
PrintToConsole(client, "%s", "{darkorange}");
PrintToConsole(client, "%s", "{darkorchid}");
PrintToConsole(client, "%s", "{darkred}");
PrintToConsole(client, "%s", "{darksalmon}");
PrintToConsole(client, "%s", "{darkseagreen}");
PrintToConsole(client, "%s", "{darkslateblue}");
PrintToConsole(client, "%s", "{darkslategray}");
PrintToConsole(client, "%s", "{darkslategrey}");
PrintToConsole(client, "%s", "{darkturquoise}");
PrintToConsole(client, "%s", "{darkviolet}");
PrintToConsole(client, "%s", "{deeppink}");
PrintToConsole(client, "%s", "{deepskyblue}");
PrintToConsole(client, "%s", "{dimgray}");
PrintToConsole(client, "%s", "{dimgrey}");
PrintToConsole(client, "%s", "{dodgerblue}");
PrintToConsole(client, "%s", "{exalted}");
PrintToConsole(client, "%s", "{firebrick}");
PrintToConsole(client, "%s", "{floralwhite}");
PrintToConsole(client, "%s", "{forestgreen}");
PrintToConsole(client, "%s", "{frozen}");
PrintToConsole(client, "%s", "{fuchsia}");
PrintToConsole(client, "%s", "{fullblue}");
PrintToConsole(client, "%s", "{fullred}");
PrintToConsole(client, "%s", "{gainsboro}");
PrintToConsole(client, "%s", "{genuine}");
PrintToConsole(client, "%s", "{ghostwhite}");
PrintToConsole(client, "%s", "{gold}");
PrintToConsole(client, "%s", "{goldenrod}");
PrintToConsole(client, "%s", "{gray}");
PrintToConsole(client, "%s", "{grey}");
PrintToConsole(client, "%s", "{green}");
PrintToConsole(client, "%s", "{greenyellow}");
PrintToConsole(client, "%s", "{haunted}");
PrintToConsole(client, "%s", "{honeydew}");
PrintToConsole(client, "%s", "{hotpink}");
PrintToConsole(client, "%s", "{immortal}");
PrintToConsole(client, "%s", "{indianred}");
PrintToConsole(client, "%s", "{indigo}");
PrintToConsole(client, "%s", "{ivory}");
PrintToConsole(client, "%s", "{khaki}");
PrintToConsole(client, "%s", "{lavender}");
PrintToConsole(client, "%s", "{lavenderblush}");
PrintToConsole(client, "%s", "{lawngreen}");
PrintToConsole(client, "%s", "{legendary}");
PrintToConsole(client, "%s", "{lemonchiffon}");
PrintToConsole(client, "%s", "{lightblue}");
PrintToConsole(client, "%s", "{lightcoral}");
PrintToConsole(client, "%s", "{lightcyan}");
PrintToConsole(client, "%s", "{lightgoldenrodyellow}");
PrintToConsole(client, "%s", "{lightgray}");
PrintToConsole(client, "%s", "{lightgrey}");
PrintToConsole(client, "%s", "{lightgreen}");
PrintToConsole(client, "%s", "{lightpink}");
PrintToConsole(client, "%s", "{lightsalmon}");
PrintToConsole(client, "%s", "{lightseagreen}");
PrintToConsole(client, "%s", "{lightskyblue}");
PrintToConsole(client, "%s", "{lightslategray}");
PrintToConsole(client, "%s", "{lightslategrey}");
PrintToConsole(client, "%s", "{lightsteelblue}");
PrintToConsole(client, "%s", "{lightyellow}");
PrintToConsole(client, "%s", "{lime}");
PrintToConsole(client, "%s", "{limegreen}");
PrintToConsole(client, "%s", "{linen}");
PrintToConsole(client, "%s", "{magenta}");
PrintToConsole(client, "%s", "{maroon}");
PrintToConsole(client, "%s", "{mediumaquamarine}");
PrintToConsole(client, "%s", "{mediumblue}");
PrintToConsole(client, "%s", "{mediumorchid}");
PrintToConsole(client, "%s", "{mediumpurple}");
PrintToConsole(client, "%s", "{mediumseagreen}");
PrintToConsole(client, "%s", "{mediumslateblue}");
PrintToConsole(client, "%s", "{mediumspringgreen}");
PrintToConsole(client, "%s", "{mediumturquoise}");
PrintToConsole(client, "%s", "{mediumvioletred}");
PrintToConsole(client, "%s", "{midnightblue}");
PrintToConsole(client, "%s", "{mintcream}");
PrintToConsole(client, "%s", "{mistyrose}");
PrintToConsole(client, "%s", "{moccasin}");
PrintToConsole(client, "%s", "{mythical}");
PrintToConsole(client, "%s", "{navajowhite}");
PrintToConsole(client, "%s", "{navy}");
PrintToConsole(client, "%s", "{normal}");
PrintToConsole(client, "%s", "{oldlace}");
PrintToConsole(client, "%s", "{olive}");
PrintToConsole(client, "%s", "{olivedrab}");
PrintToConsole(client, "%s", "{orange}");
PrintToConsole(client, "%s", "{orangered}");
PrintToConsole(client, "%s", "{orchid}");
PrintToConsole(client, "%s", "{palegoldenrod}");
PrintToConsole(client, "%s", "{palegreen}");
PrintToConsole(client, "%s", "{paleturquoise}");
PrintToConsole(client, "%s", "{palevioletred}");
PrintToConsole(client, "%s", "{papayawhip}");
PrintToConsole(client, "%s", "{peachpuff}");
PrintToConsole(client, "%s", "{peru}");
PrintToConsole(client, "%s", "{pink}");
PrintToConsole(client, "%s", "{plum}");
PrintToConsole(client, "%s", "{powderblue}");
PrintToConsole(client, "%s", "{purple}");
PrintToConsole(client, "%s", "{rare}");
PrintToConsole(client, "%s", "{red}");
PrintToConsole(client, "%s", "{rosybrown}");
PrintToConsole(client, "%s", "{royalblue}");
PrintToConsole(client, "%s", "{saddlebrown}");
PrintToConsole(client, "%s", "{salmon}");
PrintToConsole(client, "%s", "{sandybrown}");
PrintToConsole(client, "%s", "{seagreen}");
PrintToConsole(client, "%s", "{seashell}");
PrintToConsole(client, "%s", "{selfmade}");
PrintToConsole(client, "%s", "{sienna}");
PrintToConsole(client, "%s", "{silver}");
PrintToConsole(client, "%s", "{skyblue}"); 
PrintToConsole(client, "%s", "{slateblue}");
PrintToConsole(client, "%s", "{slategray}");
PrintToConsole(client, "%s", "{slategrey}");
PrintToConsole(client, "%s", "{snow}");
PrintToConsole(client, "%s", "{springgreen}");
PrintToConsole(client, "%s", "{steelblue}");
PrintToConsole(client, "%s", "{strange}");
PrintToConsole(client, "%s", "{tan}");
PrintToConsole(client, "%s", "{teal}");
PrintToConsole(client, "%s", "{thistle}");
PrintToConsole(client, "%s", "{tomato}");
PrintToConsole(client, "%s", "{turquoise}");
PrintToConsole(client, "%s", "{uncommon}");
PrintToConsole(client, "%s", "{unique}");
PrintToConsole(client, "%s", "{unusual}");
PrintToConsole(client, "%s", "{valve}");
PrintToConsole(client, "%s", "{vintage}");
PrintToConsole(client, "%s", "{violet}");
PrintToConsole(client, "%s", "{wheat}");
PrintToConsole(client, "%s", "{white}");
PrintToConsole(client, "%s", "{whitesmoke}");
PrintToConsole(client, "%s", "{yellow}");
PrintToConsole(client, "%s", "{yellowgreen}");
PrintToConsole(client, "%s", "-----------------------------------------------");
PrintToConsole(client, "%s", "-----------------------------------------------");
PrintToConsole(client, "%s", "-----------------------------------------------");
PrintToConsole(client, "%s", "-----------------------------------------------");
PrintToConsole(client, "%s", "-----------------------------------------------");

return Plugin_Handled;

}   
