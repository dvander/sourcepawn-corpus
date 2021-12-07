#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"

/*CVARS*/
//sm_quick_three
//sm_quick_six
//sm_mega_souce
//sm_winners
//sm_lotto_rules

/*commands*/
//quick3
//quick6
//lottomenu

public Plugin:myinfo = 
{
	name = "Souce Lotto",
	author = "Troll711",
	description = "Souce Lotto",
	version = PLUGIN_VERSION,
	url = "http://simplesoucemodz.com"
}
/*HaNdL3s*/
//quick three handle
new Handle:g_pick3 = INVALID_HANDLE;
//quick 6 handle
new Handle:g_pick6 = INVALID_HANDLE;
//mega souce lotto handle
new Handle:g_megasouce = INVALID_HANDLE;
//lotto rules handle
new Handle:g_lottorules = INVALID_HANDLE;
//lotto winners handle
new Handle:g_winners = INVALID_HANDLE;
//welcome message handle
new Handle:g_cvarWelcome = INVALID_HANDLE;

public OnPluginStart()
{
	//shows quick 3 numbers
	RegConsoleCmd("quick3", QuickThree);
	//shows quick 6 numbers
	RegConsoleCmd("quick6", QuickSix);
	//displays lotto menu
	RegConsoleCmd("lottomenu", LottoShow);
	//convar to set link to quick 3 lotto
	g_pick3 = CreateConVar("sm_quick_three", "http://simplesoucemodz.com", "href link to quick 3 page");
	//convar link to quick 6 page
	g_pick6 = CreateConVar("sm_quick_six","http://simplesoucemodz.com","link to quick 6 page");
	//convar to link to mega souce page
	g_megasouce = CreateConVar("sm_mega_souce","http://simplesoucemodz.com","Link to mega souce page");
	//lotto rules
	g_lottorules = CreateConVar("sm_lotto_rules", "http://simplesoucemodz.com","link to lotto rules");
	//convar to link lotto winners
	g_winners = CreateConVar("sm_winners", "http://simplesoucemodz.com","link to souce lotto winners");
	//displays welcome message to connecting players
	g_cvarWelcome = CreateConVar("ssr_welcome_enabled", "1", "Show welcome message to newly connected users.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	//plugin version
	CreateConVar("sm_sl_verion", PLUGIN_VERSION, "Souce_Lotto_Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public Action:QuickThree(client,args)
{
	decl String:href[255];
	GetConVarString(g_pick3, href, sizeof(href));
	ShowMOTDPanel(client, "Souce Lotto: Quick 3", href, MOTDPANEL_TYPE_URL);
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		ReplyToCommand(client, "[Souce Lotto] Thanks For Playing Quick 3");
	}
	return Plugin_Continue;
}
public Action:QuickSix(client,args)
{
	new String:temp_cvar[128];
	GetConVarString(g_pick6,temp_cvar, sizeof(temp_cvar));
	ShowMOTDPanel(client, "Souce Lotto: Quick 6", temp_cvar, MOTDPANEL_TYPE_URL);
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		ReplyToCommand(client, "[Souce Lotto] Thanks For Playing Quick 6");
	}
	return Plugin_Continue;
}

public Action:LottoShow(client,args)
{
	LottoMenu(client);
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
		PrintToChat(client, "\x01[Souce Lotto] Play Now And Win BIG!! Type \x04!lottomenu\x01 To Start Playing!");
}

public Action:LottoMenu(clientId) {
	new Handle:menu = CreateMenu(LottoMenuHandler);
	//radio menu title
	SetMenuTitle(menu, "Lotto Menu Options");
	//option 1 - quick 3 lotto
	AddMenuItem(menu, "option1", "Quick 3 Lotto");
	//option 2 - quick 6 lotto
	AddMenuItem(menu, "option2", "Quick 6 Lotto");
	//option 3 - mega souce lotto
	AddMenuItem(menu, "option3", "Mega Souce Lotto");
	//option 4 - shows souce lotto rules
	AddMenuItem(menu, "option4", "Lotto Rules");
	//option 5 - shows souce lotto winners
	AddMenuItem(menu, "option5", "Lotto Winners");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public LottoMenuHandler(Handle:menu, MenuAction:action, client, itemNum) {
	if ( action == MenuAction_Select ) {
		new String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		//menu item 1 (quick 3 lotto)
		if ( strcmp(info,"option1") == 0 ) {
			//quick 3 lotto number display motd
			decl String:href[255];
			GetConVarString(g_pick3, href, sizeof(href));
			ShowMOTDPanel(client, "Souce Lotto: Quick 3", href, MOTDPANEL_TYPE_URL);
			if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			{
				//displays message to clients after selecting option 1.
				ReplyToCommand(client, "\x04[Souce Lotto] Thanks For Playing Quick 3");
			}
			
		}
		//menu item 2 (quick 6 lotto)
		else if ( strcmp(info,"option2") == 0 ) {
			//shows off motd panel for quick 6
			new String:temp_cvar[128];
			GetConVarString(g_pick6,temp_cvar, sizeof(temp_cvar));
			ShowMOTDPanel(client, "Souce Lotto: Quick 6", temp_cvar, MOTDPANEL_TYPE_URL);
			if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			{
				//displays message to client after selecting option
				ReplyToCommand(client, "\x04[Souce Lotto] Thanks For Playing Quick 6");
			}
			
		}
		//menu item 3 (mega souce lotto)
		else if ( strcmp(info,"option3") == 0 ) {
			//shows off motd panel for mega souce lotto
			new String:temp_cvar[128];
			GetConVarString(g_megasouce,temp_cvar, sizeof(temp_cvar));
			ShowMOTDPanel(client, "Souce Lotto: MEGA SOUCE!", temp_cvar, MOTDPANEL_TYPE_URL);
			if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			{
				//displays message to client after selecting option
				ReplyToCommand(client, "\x04[Souce Lotto] Thanks For Playing MEGA SOUCE!");
			}	
		}
		//menu item 4 (lotto rules)
		else if ( strcmp(info,"option4") == 0 ) {
			
			//shows lotto rules
			new String:temp_cvar[128];
			GetConVarString(g_lottorules,temp_cvar, sizeof(temp_cvar));
			ShowMOTDPanel(client, "Souce Lotto: Rules", temp_cvar, MOTDPANEL_TYPE_URL);
			if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			{
				//displays message to client after selecting option
				ReplyToCommand(client, "\x04[Souce Lotto] You Are Now Viewing Lotto Rules");
			}	
			
		}
		//menu item 5 (last 10 songs played)
		else if ( strcmp(info,"option5") == 0 ) {
			
			//shows radio status (link to shoutcast radio station)
			new String:temp_cvar[128];
			GetConVarString(g_winners,temp_cvar, sizeof(temp_cvar));
			ShowMOTDPanel(client, "Souce Lotto: WINNERS!", temp_cvar, MOTDPANEL_TYPE_URL);
			if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			{
				//displays message to client after selecting option
				ReplyToCommand(client, "\x04[Souce Lotto] You Are Now Viewing All Souce Lotto Winners From This Server");
			}		
		}
	}
	else if ( action == MenuAction_End )
		CloseHandle(menu);
}