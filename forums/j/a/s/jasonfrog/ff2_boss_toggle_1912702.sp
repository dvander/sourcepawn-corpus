#include <sourcemod>
#include <freak_fortress_2>
#include <clientprefs.inc>
#include <morecolors>

#define VERSION "1.0.1"

#define TOGGLE_UNDEF -1
#define TOGGLE_ON  1
#define TOGGLE_OFF 2

new Handle:g_ff2bossCookie= INVALID_HANDLE;
new g_ClientCookies[MAXPLAYERS+1];
new g_ClientPoints[MAXPLAYERS+1];
new g_ClientIDs[MAXPLAYERS+1];
new g_ClientQueue[MAXPLAYERS+1][2];
new Handle:g_hCvarPreferenceQuestionDelay = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Freak Fortress 2: Boss Toggle",
	description = "Allows players to toggle being selected as a Boss",
	author = "frog",
	version = VERSION
};

public OnPluginStart()
{
	CreateConVar("ff2_boss_toggle_version", VERSION, "Freak Fortress 2: Boss Toggle Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvarPreferenceQuestionDelay = CreateConVar("ff2_boss_toggle_delay", "45.0", "Delay between joining the server and asking the player for their preference, if it is not set.");	
	AutoExecConfig(true, "plugin.ff2_boss_toggle")

	g_ff2bossCookie = RegClientCookie("ff2_boss_toggle", "Players FF2 Boss Toggle", CookieAccess_Public);		
	RegConsoleCmd("ff2toggle", BossMenu);
	
	for(new i = 0; i < MAXPLAYERS; i++)
	{
		g_ClientCookies[i] = TOGGLE_UNDEF;
	}
	
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	LoadTranslations("ff2_boss_toggle.phrases");
}

public OnClientDisconnect(client)
{
	g_ClientCookies[client] = TOGGLE_UNDEF;
}

public OnClientCookiesCached(client)
{
	decl String:sEnabled[2];
	GetClientCookie(client, g_ff2bossCookie, sEnabled, sizeof(sEnabled));
	new enabled = StringToInt(sEnabled);
	
	if( 1 > enabled || 2 < enabled)
	{
		g_ClientCookies[client] = TOGGLE_UNDEF;
		new Handle:clientPack = CreateDataPack();
		WritePackCell(clientPack, client);
		CreateTimer(GetConVarFloat(g_hCvarPreferenceQuestionDelay), BossMenuTimer, clientPack);
	}
	else
	{
		g_ClientCookies[client] = enabled;
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client=1;client<=MaxClients;client++)
	{
		g_ClientQueue[client][0] = client;
		g_ClientQueue[client][1] = FF2_GetQueuePoints(client);
	}
	
	SortCustom2D(g_ClientQueue, sizeof(g_ClientQueue), SortQueueDesc);
	
	for(new client=1;client<=MaxClients;client++)
	{
		g_ClientIDs[client] = g_ClientQueue[client][0];
		g_ClientPoints[client] = g_ClientQueue[client][1];
	}	
	
	for(new client=0;client<=MaxClients;client++)
	{	if (client>0 && IsValidEntity(client) && IsClientConnected(client))
		{
			if (g_ClientCookies[client] == TOGGLE_ON)
			{
			    	new index = -1;
				for (new i = 1; i < MAXPLAYERS+1; i++)
				{
					if (g_ClientIDs[i] == client)
					{
						index = i;
						break;
					}
				}	
			       	if (index > 0)
			    	{
    					CPrintToChat(client, "{olive}[FF2]{default} %t", "toggle_enabled_points", index, g_ClientPoints[index]);
    				} else {
    					CPrintToChat(client, "{olive}[FF2]{default} %t", "toggle_enabled");
    				}
			}
			else if (g_ClientCookies[client] == TOGGLE_OFF)
			{
				FF2_SetQueuePoints(client,-10);
    				decl String:nick[64]; 
    				GetClientName(client, nick, sizeof(nick));
				CPrintToChat(client, "{olive}[FF2]{default} %t", "toggle_disabled");
			}
			else if (g_ClientCookies[client] == TOGGLE_UNDEF || g_ClientCookies[client] == 0)
			{
			    	decl String:nick[64]; 
			    	GetClientName(client, nick, sizeof(nick));
				new Handle:clientPack = CreateDataPack();
				WritePackCell(clientPack, client);
				CreateTimer(GetConVarFloat(g_hCvarPreferenceQuestionDelay), BossMenuTimer, clientPack);			
			}
		}
	}
	CreateTimer(5.0, CommandRemind);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client=0;client<=MaxClients;client++)
	{	if (client>0 && IsValidEntity(client) && IsClientConnected(client))
		{
			 if (g_ClientCookies[client] == TOGGLE_OFF)
			{
				FF2_SetQueuePoints(client,-10);
    				decl String:nick[64]; 
    				GetClientName(client, nick, sizeof(nick));
			}
		}
	}
}

public Action:CommandRemind(Handle:timer)
{
	CPrintToChatAll("{olive}[FF2]{default} %t", "toggle_command");
}

public Action:BossMenuTimer(Handle:timer, any:clientpack)
{
	decl clientId;
	ResetPack(clientpack);
	clientId = ReadPackCell(clientpack);
	CloseHandle(clientpack);
	if (g_ClientCookies[clientId] == TOGGLE_UNDEF)
	{
		BossMenu(clientId, 0);
	}
}

public Action:BossMenu(client, args)
{
	if (IsValidClient(client))
	{
		CPrintToChat(client, "{olive}[FF2]{default} %t", "set_preference");
	
		decl String:sEnabled[2];
		GetClientCookie(client, g_ff2bossCookie, sEnabled, sizeof(sEnabled));
		g_ClientCookies[client] = StringToInt(sEnabled);	
		
		new Handle:menu = CreateMenu(MenuHandlerBoss);
		SetMenuTitle(menu, "%t", "toggle_menu_title");
		
		new String:menuoption[128];
		Format(menuoption,sizeof(menuoption),"%t","toggle_on_menu_option");
		AddMenuItem(menu, "Boss Toggle", menuoption);
		Format(menuoption,sizeof(menuoption),"%t","toggle_off_menu_option");
		AddMenuItem(menu, "Boss Toggle", menuoption);
	
		SetMenuExitButton(menu, true);
	
		DisplayMenu(menu, client, 20);
	}
	return Plugin_Handled;
}

public MenuHandlerBoss(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)	
	{
		decl String:sEnabled[2];
		new choice = param2 + 1;

		g_ClientCookies[param1] = choice;
		IntToString(choice, sEnabled, sizeof(sEnabled));

		SetClientCookie(param1, g_ff2bossCookie, sEnabled);
		
		if(1 == choice)
		{
			CPrintToChat(param1, "{olive}[FF2]{default} %t", "toggle_enabled");
		}
		else if(2 == choice)
		{
			CPrintToChat(param1, "{olive}[FF2]{default} %t", "toggle_disabled");
		}
	} 
	else if(action == MenuAction_End)
	{
	   CloseHandle(menu);
	}
}

public SortQueueDesc(x[], y[], array[][], Handle:data)
{
    if (x[1] > y[1]) 
        return -1;
    else if (x[1] < y[1]) 
        return 1;    
    return 0;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}


