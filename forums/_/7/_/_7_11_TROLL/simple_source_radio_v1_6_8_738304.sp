#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.6.8"

/*CVARS*/
//sm_radio_href - link to radio on motd panel (stats radio)
//sm_radio_href_2 - link to radio off motd panel (stop radio)
//sm_last10_href - shows last 10 songs played (shows current last 10 songs)
//sm_radio_status_href - link to shout cast status (shows current dj,song,listeners)
//ssr_welcome_enabled - 1 (on) 0 (off) - shows welcome message to connecting clients
//sm_ssr_version - version number

/*commands*/
//!listen - starts radio
//!stopmusic - stop radio
//!radiomenu - allows you to do the above commands and more. include listening,turning 
//radio off,no thanks,radio stats and more.

/*Cr3d!ts*/
//whos your daddy!?!? - helped fix menu erros

/*TODO*/
//make admin command to display radio menu to all
//what ever else i think of..

public Plugin:myinfo = 
{
	name = "Simple Source Radio",
	author = "{7~11} Troll",
	description = "Simple Source Radio",
	version = PLUGIN_VERSION,
	url = "www.711clan.net"
}
/*HaNdL3s*/
//radio off handle
new Handle:g_radioOn = INVALID_HANDLE;
//radio off handle
new Handle:g_radioOff = INVALID_HANDLE;
//radio status handle
new Handle:g_radiostatus = INVALID_HANDLE;
//last 10 songs handle
new Handle:g_last10 = INVALID_HANDLE;
//welcome message handle
new Handle:g_cvarWelcome = INVALID_HANDLE;

public OnPluginStart()
{
	//turns radio on
	RegConsoleCmd("listen", RadioOn);
	//turns off radio
	RegConsoleCmd("stopmusic", RadioOff);
	//displays radio menu with listening options
	RegConsoleCmd("radiomenu", RadioShow);
	//convar to set link to on motd panel (radio on)
	g_radioOn = CreateConVar("sm_radio_href", "www.radio.711clan.net", "href link to clans internet radio or favorite winamp station");
	//convar link to off motd panel (radio off)
	g_radioOff = CreateConVar("sm_radio_href_2","www.google.com","Link to radio off panel");
	//convar to link to shoutcast status
	g_radiostatus = CreateConVar("sm_radio_status_href","www.radio.711clan.net","Link to shoutcast stats");
	//convar to link to shoutcast last 10 songs.
	g_last10 = CreateConVar("sm_last10_href", "http://38.96.148.24:9588/played.html","link to last 10 songs");
	//displays welcome message to connecting players
	g_cvarWelcome = CreateConVar("ssr_welcome_enabled", "1", "Show welcome message to newly connected users.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	//plugin version
	CreateConVar("sm_ssr_version", PLUGIN_VERSION, "Simple_Source_Radio_Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public Action:RadioOn(client,args)
{
	decl String:href[255];
	GetConVarString(g_radioOn, href, sizeof(href));
	ShowMOTDPanel(client, "Simple Source Radio: On", href, MOTDPANEL_TYPE_URL);
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		ReplyToCommand(client, "[SSR] You Are Now Listening To Simple_Source_Radio");
	}
	return Plugin_Continue;
}
public Action:RadioOff(client,args)
{
	new String:temp_cvar[128];
	GetConVarString(g_radioOff,temp_cvar, sizeof(temp_cvar));
	ShowMOTDPanel(client, "Simple Source Radio: Off", temp_cvar, MOTDPANEL_TYPE_URL);
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		ReplyToCommand(client, "[SSR] Thanks For Listening");
	}
	return Plugin_Continue;
}

public Action:RadioShow(client,args)
{
	RadioMenu(client);
}

//when client joins server
public OnClientPutInServer(client) {
	if (GetConVarBool(g_cvarWelcome))
		//30 seconds after client joins server
		CreateTimer(30.0, Timer_WelcomeMessage, client);
}

public Action:Timer_WelcomeMessage(Handle:timer, any:client) {
	if (GetConVarBool(g_cvarWelcome) && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		//shows clent welcome message
		PrintToChat(client, "\x01[SSR] To Listen To The Radio Type \x04!listen\x01 To Stop The Radio Type \x04!stopmusic");
}

public Action:RadioMenu(clientId) {
	new Handle:menu = CreateMenu(RadioMenuHandler);
	//radio menu title
	SetMenuTitle(menu, "Radio Options");
	//option 1 - starts radio
	AddMenuItem(menu, "option1", "Tune In");
	//option 2 - closes menu & displays no thank you message
	AddMenuItem(menu, "option2", "No Thanks");
	//option 3 - turns radio off
	AddMenuItem(menu, "option3", "Radio Off");
	//option 4 - shows current radio status,dj,song,listeners
	AddMenuItem(menu, "option4", "Radio Status");
	//option 5 - shows last 10 songs played
	AddMenuItem(menu, "option5", "Last 10 Songs");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public RadioMenuHandler(Handle:menu, MenuAction:action, client, itemNum) {
	if ( action == MenuAction_Select ) {
		new String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		//menu item 1 (start radio function)
		if ( strcmp(info,"option1") == 0 ) {
			//shows and starts simple_source_radio when player chooses option 1
			decl String:href[255];
			GetConVarString(g_radioOn, href, sizeof(href));
			ShowMOTDPanel(client, "Simple Source Radio: On", href, MOTDPANEL_TYPE_URL);
			if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			{
				//displays message to clients after selecting option 1.
				ReplyToCommand(client, "\x01[SSR] You Are Now Listening To \x04Simple_Source_Radio");
			}
			
		}
		//menu item 2 (no thank you option)
		else if ( strcmp(info,"option2") == 0 ) {
			
			//displays message to clients after selecting option 1.
			ReplyToCommand(client, "\x01[SSR] You Have Chosen Not To Listen, If You Wish To Later On Type \x04!listen");
			
		}
		//menu item 3 (radio off)
		else if ( strcmp(info,"option3") == 0 ) {
			//shows off motd panel and turns radio off if your listening
			new String:temp_cvar[128];
			GetConVarString(g_radioOff,temp_cvar, sizeof(temp_cvar));
			ShowMOTDPanel(client, "Simple Source Radio: Off", temp_cvar, MOTDPANEL_TYPE_URL);
			if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			{
				//displays message to client after selecting option
				ReplyToCommand(client, "\x04[SSR] Thanks For Listening");
			}	
		}
		//menu item 4 (radio status)
		else if ( strcmp(info,"option4") == 0 ) {
			
			//shows radio status (link to shoutcast radio station)
			new String:temp_cvar[128];
			GetConVarString(g_radiostatus,temp_cvar, sizeof(temp_cvar));
			ShowMOTDPanel(client, "Simple Source Radio: Radio Status", temp_cvar, MOTDPANEL_TYPE_URL);
			if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			{
				//displays message to client after selecting option
				ReplyToCommand(client, "\x01[SSR] You Are Now Viewing \x04Radio Station Status Page");
			}	
			
		}
		//menu item 5 (last 10 songs played)
		else if ( strcmp(info,"option5") == 0 ) {
			
			//shows radio status (link to shoutcast radio station)
			new String:temp_cvar[128];
			GetConVarString(g_last10,temp_cvar, sizeof(temp_cvar));
			ShowMOTDPanel(client, "Simple Source Radio: Last 10 Songs", temp_cvar, MOTDPANEL_TYPE_URL);
			if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			{
				//displays message to client after selecting option
				ReplyToCommand(client, "\x01[SSR] You Are Now Viewing \x04The Last 10 Played Songs");
			}		
		}
	}
	else if ( action == MenuAction_End )
		CloseHandle(menu);
}