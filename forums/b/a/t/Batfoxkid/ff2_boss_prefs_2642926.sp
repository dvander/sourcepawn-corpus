#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <clientprefs>
#include <tf2_stocks>
#include <freak_fortress_2>

public SortQueueDesc( x[], y[], array[][], Handle:data)
{
    if (x[1] > y[1]) 
        return -1;
    else if (x[1] < y[1]) 
        return 1;    
    return 0;
}

#pragma newdecls required

#define FF2BOSSPREFS_VERSION "1.05"

char Incoming[MAXPLAYERS+1][64];
char cIncoming[MAXPLAYERS+1][64];
bool IsBossSelected[MAXPLAYERS+1];
int nextBoss = -1;
float RemindAt;
float FindNextBossAt;
float ShowBossPanelAt[MAXPLAYERS+1];
#define INACTIVE 100000000.0

enum BossToggle
{
	FF2Bosses_Undefined = -1,
	FF2Bosses_On = 1,
	FF2Bosses_Off = 2,
}

BossToggle BossSetting[MAXPLAYERS+1];
Handle FF2ToggleCookie = null;
Handle FF2QueuePointsCookie = null;
int clientQueuePoints[MAXPLAYERS+1];
int clientQueue[MAXPLAYERS+1][2];
int clientPoints[MAXPLAYERS+1];
int clientIdx[MAXPLAYERS+1];

ConVar cvarToggleEnabled;
ConVar cvarBossSelectionEnabled;
ConVar cvarBossTogglePopupDelay;
ConVar cvarRestoreCompanionQueuePoints;
ConVar cvarBossShowDesc;

public Plugin myinfo = {
	name = "Freak Fortress 2: Boss Preferences",
	description = "Allows players select their bosses or disable being a boss",
	author = "SHADoW NiNE TR3S (Base code from RainBolt Dash, Powerlord and frog)",
	version = FF2BOSSPREFS_VERSION,
};

public void OnPluginStart()
{
	int version[3];
	FF2_GetFF2Version(version);
	if(version[0]==1 && (version[1]<10 || (version[1]==10 && version[2]<6)))
	{
		SetFailState("This version of FF2 Boss Preferences requires at least FF2 v1.10.6!");
	}
	LogMessage("Freak Fortress 2: Boss Preferences v%s Loading", FF2BOSSPREFS_VERSION);
	
	// Reset these values to the far future
	RemindAt=FindNextBossAt=INACTIVE;
	for(int client=1;client<=MaxClients;client++)
	{
		if(!IsValidClient(client))
			continue;
		ShowBossPanelAt[client]=INACTIVE;
	}
	
	// ConVars to make
	CreateConVar("ff2_bossprefs_version", FF2BOSSPREFS_VERSION, "Freak Fortress 2: Boss Preferences Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarBossTogglePopupDelay = CreateConVar("ff2_bossprefs_toggle_delay", "45.0", "Delay between joining the server and asking the player for their preference, if it is not set.");	
	cvarToggleEnabled = CreateConVar("ff2_bossprefs_enable_toggle", "1", "Allow players to toggle being selected as a boss on/off? 0: Disable, 1: Enable", _, true, 0.0, true, 1.0);
	cvarBossSelectionEnabled = CreateConVar("ff2_bossprefs_enable_boss_selection", "1", "Allow players to select their own boss? 0: Disable, 1: Enable", _, true, 0.0, true, 1.0);
	cvarRestoreCompanionQueuePoints = CreateConVar("ff2_bossprefs_restore_companion_queuepoints", "0", "1: Restore queue points for companions of a boss, 0: Don't restore queue points for companions of a boss", _, true, 0.0, true, 1.0);
	cvarBossShowDesc = CreateConVar("ff2_bossprefs_description", "1", "Allow players to see boss description before confirming their selection? 0: Disable, 1: Enable", _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "plugin.ff2_bossprefs");

	FF2ToggleCookie = RegClientCookie("ff2_bossprefs_bosstoggle", "FF2 Boss Toggle Cookie", CookieAccess_Public);		
	FF2QueuePointsCookie = RegClientCookie("ff2_bossprefs_cookies", "FF2 Queue Points Cookies", CookieAccess_Protected);		
	for(int i = 0; i < MAXPLAYERS; i++)
	{
		BossSetting[i] = FF2Bosses_Undefined;
		clientQueuePoints[i] = 0;
	}
	
	// Event Hooks
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("arena_win_panel", Event_RoundEnd);

	// Commands
	RegConsoleCmd("ff2toggle", ToggleMenu, "Allows players to enable/disable being in the boss queue");
	RegConsoleCmd("ff2_toggle", ToggleMenu,"Allows players to enable/disable being in the boss queue");
	RegConsoleCmd("haletoggle", ToggleMenu,"Allows players to enable/disable being in the boss queue");
	RegConsoleCmd("hale_toggle", ToggleMenu,"Allows players to enable/disable being in the boss queue");
	RegConsoleCmd("ff2_boss", BossSelectMenu, "Allows players to select their boss");
	RegConsoleCmd("ff2boss", BossSelectMenu, "Allows players to select their boss");
	RegConsoleCmd("hale_boss", BossSelectMenu, "Allows players to select their boss");
	RegConsoleCmd("haleboss", BossSelectMenu, "Allows players to select their boss");
	
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("ff2bossprefs.phrases");
}

public void OnClientDisconnect(int client)
{
	clientQueuePoints[client]=0;
	BossSetting[client] = FF2Bosses_Undefined;
	if(client==nextBoss)
	{
		ShowBossPanelAt[client]=INACTIVE;
	}
	
	IsBossSelected[client]=false;
	strcopy(Incoming[client], sizeof(Incoming[]), "");
}

public void OnClientCookiesCached(int client)
{
	if(!cvarToggleEnabled.BoolValue)
		return;
		
	char sEnabled[2];
	GetClientCookie(client, FF2ToggleCookie, sEnabled, sizeof(sEnabled));
	BossToggle FF2BossSetting = view_as<BossToggle>(StringToInt(sEnabled));
	
	if(!CheckCommandAccess(client, "ff2_toggle", 0, true))
	{
		BossSetting[client] = FF2Bosses_Undefined;
	}
	
	if(FF2Bosses_On > FF2BossSetting || FF2Bosses_Off < FF2BossSetting)
	{
		BossSetting[client] = FF2Bosses_Undefined;
		Handle clientPack = CreateDataPack();
		WritePackCell(clientPack, client);
		CreateTimer(cvarBossTogglePopupDelay.FloatValue, BossMenuTimer, clientPack);
	}
	else
	{
		BossSetting[client] = FF2BossSetting;
		if(BossSetting[client] == FF2Bosses_Off)
		{
			GetClientCookie(client, FF2QueuePointsCookie, sEnabled, sizeof(sEnabled));
			clientQueuePoints[client]=StringToInt(sEnabled);
		}
	}
	
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2_IsFF2Enabled())
	{
		return;
	}
	
	if(cvarBossSelectionEnabled.BoolValue)
	{
		FindNextBossAt=GetEngineTime()+0.5;
	}
	
	if(cvarToggleEnabled.BoolValue)
	{
		for(int client=1;client<=MaxClients;client++)
		{
			clientQueue[client][0] = client;
			clientQueue[client][1] = FF2_GetQueuePoints(client);
		}
	
		SortCustom2D(clientQueue, sizeof(clientQueue), SortQueueDesc);
	
		for(int client=1;client<=MaxClients;client++)
		{
			clientIdx[client] = clientQueue[client][0];
			clientPoints[client] = clientQueue[client][1];
		}	
	
		for(int client=1;client<=MaxClients;client++)
		{	
			if(!IsValidClient(client))
				continue;
				
			if(!CheckCommandAccess(client, "ff2_toggle", 0, true))
				continue;
				
			switch(BossSetting[client])
			{
				case FF2Bosses_On:
				{
					int index=-1;
					for(int player=1;player<MAXPLAYERS+1;player++)
					{
						if(clientIdx[player]==client)
						{
							index=player;
							break;
						}
					}
					if(index>0)
						CPrintToChat(client, "{olive}[FF2]{default} %t", "toggle_enabled_points", index, clientPoints[index]);
					else
				   		CPrintToChat(client, "{olive}[FF2]{default} %t", "toggle_enabled");
				}
				
				case FF2Bosses_Undefined:
				{
					char nick[64];
					GetClientName(client, nick, sizeof(nick));
					Handle clientPack = CreateDataPack();
					WritePackCell(clientPack, client);
					CreateTimer(cvarBossTogglePopupDelay.FloatValue, BossMenuTimer, clientPack);	
				}
				
				case FF2Bosses_Off:
				{
					if(FF2_GetQueuePoints(client)>=0)
					{
						FF2_SetQueuePoints(client,-15);
					}
					char nick[64]; 
					GetClientName(client, nick, sizeof(nick));
					CPrintToChat(client, "{olive}[FF2]{default} %t", "toggle_disabled");
					
				}
			}
		}
		RemindAt=GetEngineTime()+5.0;
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int client=0;client<=MaxClients;client++)
	{	
		if(!IsValidClient(client))
			continue;
		
		if(BossSetting[client]!=FF2Bosses_Off)
		{
			if(cvarRestoreCompanionQueuePoints.BoolValue)
			{
				if(FF2_GetBossIndex(client)==-1) // save queue points in case they become a companion boss
				{
					clientQueuePoints[client]=FF2_GetQueuePoints(client);
				}
				else if(FF2_GetBossIndex(client)>0) // restores queue points
				{
					FF2_SetQueuePoints(client, clientQueuePoints[client]);
				}
			}
		}	
		else
		{
			if(FF2_GetQueuePoints(client)>=0)
			{
				FF2_SetQueuePoints(client,-15);
			}
			char nick[64]; 
			GetClientName(client, nick, sizeof(nick));
		}
	}
}

public Action BossMenuTimer(Handle timer, any clientpack)
{
	int clientId;
	ResetPack(clientpack);
	clientId = ReadPackCell(clientpack);
	CloseHandle(clientpack);
	if(BossSetting[clientId] == FF2Bosses_Undefined && CheckCommandAccess(clientId, "ff2_toggle", 0, true))
	{
		ToggleMenu(clientId, 0);
	}
}

public Action ToggleMenu(int client, int args)
{
	if(!FF2_IsFF2Enabled() || !cvarToggleEnabled.BoolValue)
		return Plugin_Continue;
		
	if(!IsValidClient(client))
	{
		if(!client)
		{
			ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		}
		return Plugin_Handled;
	}
		
	if(!CheckCommandAccess(client, "ff2_toggle", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}

	CPrintToChat(client, "{olive}[FF2]{default} %t", "set_preference");
	
	char sEnabled[2];
	GetClientCookie(client, FF2ToggleCookie, sEnabled, sizeof(sEnabled));
	BossSetting[client] = view_as<BossToggle>(StringToInt(sEnabled));	
		
	Menu togglemenu = new Menu(MenuHandler_BossToggle);
	togglemenu.SetTitle("%t\n%t", "toggle_menu_title", (BossSetting[client]==FF2Bosses_Off ? "ff2boss_disabled" : "ff2boss_enabled"));
		
	char menuoption[128];
	Format(menuoption,sizeof(menuoption),"%t","toggle_on_menu_option");
	togglemenu.AddItem("toggle_on", menuoption);
	Format(menuoption,sizeof(menuoption),"%t","toggle_off_menu_option");
	togglemenu.AddItem("toggle_off", menuoption);
	togglemenu.ExitBackButton = true;
	togglemenu.Display(client,20);
	return Plugin_Handled;
}

public int MenuHandler_BossToggle(Handle menu, MenuAction action, int param1, int param2) 
{
	if(action == MenuAction_Select)	
	{
		char sEnabled[2];
		int choice = param2 + 1;
		int CQP = FF2_GetQueuePoints(param1);
		BossSetting[param1] = view_as<BossToggle>(choice);
		IntToString(choice, sEnabled, sizeof(sEnabled));

		SetClientCookie(param1, FF2ToggleCookie, sEnabled);
		
		if(1 == choice)
		{
			if(CQP<0)
			{
				FF2_SetQueuePoints(param1, clientQueuePoints[param1]);
			}
			CPrintToChat(param1, "{olive}[FF2]{default} %t", "toggle_enabled");
		}
		else if(2 == choice)
		{
		
			if(CQP>0)
			{
				clientQueuePoints[param1]=CQP;
				IntToString(CQP, sEnabled, sizeof(sEnabled));
				SetClientCookie(param1, FF2QueuePointsCookie, sEnabled);
			}
			if(FF2_GetQueuePoints(param1)>=0)
			{
				FF2_SetQueuePoints(param1, -15);
			}
			CPrintToChat(param1, "{olive}[FF2]{default} %t", "toggle_disabled");
		}
	} 
	else if(action == MenuAction_End)
	{
	   delete menu;
	}
}

public void OnGameFrame()
{
	FF2Boss_Tick(GetEngineTime());
}

public void FF2Boss_Tick(float gameTime)
{
	if(gameTime>=RemindAt)
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "toggle_command");	
		RemindAt=INACTIVE;
	}
	
	if(gameTime>=FindNextBossAt)
	{
		int NextInLine=1;
		int MaxQueuePts=FF2_GetQueuePoints(1);
		int points;
		for(int client=2;client<=MaxClients;client++)
		{
			if (FF2_GetBossIndex(client)==-1)
			{
				points = FF2_GetQueuePoints(client);
				if (points>MaxQueuePts)
				{
					NextInLine=client;
					MaxQueuePts=points;
				}
			}
		}
		
		if(CheckCommandAccess(NextInLine, "ff2_boss", 0, true) && !IsBossSelected[NextInLine])
		{
			ShowBossPanelAt[NextInLine]=GetEngineTime()+9.0;
		}
		FindNextBossAt=INACTIVE;
	}
	
	for(int client=1;client<=MaxClients;client++)
	{
		if(client<=0 || client>MaxClients || !IsClientInGame(client))
			continue;
		if(gameTime >= ShowBossPanelAt[client])
		{
			if(IsVoteInProgress())
			{
				ShowBossPanelAt[client]=GetEngineTime()+5.0;
				return;
			}
			BossSelectMenu(client,0);
			ShowBossPanelAt[client]=INACTIVE;
			return;
		}
	}
}

public void OnClientPutInServer(int client)
{
	IsBossSelected[client]=false;
	strcopy(Incoming[client], sizeof(Incoming[]), "");
}

public Action BossSelectMenu(int client, int args)
{
	if(!FF2_IsFF2Enabled() || !cvarBossSelectionEnabled.BoolValue)
		return Plugin_Continue;
		
	if(!IsValidClient(client))
	{
		if(!client)
		{
			ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		}
		return Plugin_Handled;
	}
	
	if(!CheckCommandAccess(client, "ff2_boss", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	
	char spclName[64];
	Handle BossKV;
	
	if(args)
	{
		char bossName[64];
		GetCmdArgString(bossName, sizeof(bossName));
		for(int config; (BossKV=FF2_GetSpecialKV(config,true)); config++)
		{
			if(KvGetNum(BossKV, "blocked", 0)) continue;
			if(KvGetNum(BossKV, "hidden", 0)) continue;
			KvGetString(BossKV, "name", spclName, sizeof(spclName));

			if(StrContains(bossName, spclName, false)!=-1)
			{
				IsBossSelected[client]=true;
				strcopy(Incoming[client], sizeof(Incoming[]), spclName);
				CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2boss_bossselected", spclName);
				return Plugin_Handled;
			}
			
			KvGetString(BossKV, "filename", spclName, sizeof(spclName));
			if(StrContains(bossName, spclName, false)!=-1)
			{
				IsBossSelected[client]=true;
				KvGetString(BossKV, "name", spclName, sizeof(spclName));
				strcopy(Incoming[client], sizeof(Incoming[]), spclName);
				CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2boss_bossselected", spclName);
				return Plugin_Handled;
			}	
		}
		CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2boss_bossnotfound");
		return Plugin_Handled;
	}	
	
	Menu bossselectmenu = new Menu(MenuHandler_BossSelection);
	bossselectmenu.SetTitle("%t\n%t\n%t","ff2boss_title", (BossSetting[client]==FF2Bosses_Off ? "ff2boss_disabled" : "ff2boss_enabled"), "ff2boss_current_selection", Incoming[client][0]=='\0' ? "None" : Incoming[client]);
	
	char s[256];
	Format(s, sizeof(s), "%t", "ff2boss_random_option");
	bossselectmenu.AddItem("Random Boss", s);
	if(cvarToggleEnabled.BoolValue && CheckCommandAccess(client, "ff2_toggle", 0, true))
	{
		Format(s, sizeof(s), "%t", BossSetting[client]==FF2Bosses_Off ? "toggle_on_menu_option" : "toggle_off_menu_option");
		bossselectmenu.AddItem("Boss Toggle", s);
	}
	
	for(int config; (BossKV=FF2_GetSpecialKV(config,true)); config++)
	{
		if(KvGetNum(BossKV, "blocked", 0)) continue;
		if(KvGetNum(BossKV, "hidden", 0)) continue;
		KvGetString(BossKV, "name", spclName, 64);
		bossselectmenu.AddItem(spclName, spclName);
	}
	bossselectmenu.ExitBackButton = true;
	bossselectmenu.Display(client,20);
	return Plugin_Handled;
}

public int MenuHandler_BossSelection(Handle menu, MenuAction action, int param1, int param2)
{ 
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:
				{
					IsBossSelected[param1]=true;
					Incoming[param1] = "";
					CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2boss_randomboss", Incoming[param1]);
				}
				case 1:
				{
					if(cvarToggleEnabled.BoolValue && CheckCommandAccess(param1, "ff2_toggle", 0, true))
						ToggleMenu(param1, 0);
					else
					{
						IsBossSelected[param1]=true;
						GetMenuItem(menu, param2, Incoming[param1], sizeof(Incoming[]));
						CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2boss_bossselected", Incoming[param1]);
					}
				}
				default:
				{
					if(!GetConVarBool(cvarBossShowDesc))
					{
						IsBossSelected[param1]=true;
						GetMenuItem(menu, param2, Incoming[param1], sizeof(Incoming[]));
						CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2boss_bossselected", Incoming[param1]);
					}
					else
					{
						GetMenuItem(menu, param2, cIncoming[param1], sizeof(cIncoming[]));
						ConfirmBoss(param1);
					}
				}
			}
		}
	}
}

public Action ConfirmBoss(int client)
{
	char spclName[64], language[20], text[512];
	GetLanguageInfo(GetClientLanguage(client), language, 8, text, 8);
	Format(language, sizeof(language), "description_%s", language);
	Handle BossKV;
	
	for(int config; (BossKV=FF2_GetSpecialKV(config,true)); config++)
	{
		KvGetString(BossKV, "name", spclName, sizeof(spclName));
		if(StrContains(spclName, cIncoming[client], false)!=-1)
		{
			KvRewind(BossKV);
			KvGetString(BossKV, language, text, sizeof(text));
			if(!text[0])
			{
				KvGetString(BossKV, "description_en", text, sizeof(text));  //Default to English if their language isn't available
				if(!text[0])
				{
					Format(text, sizeof(text), "%T", "ff2boss_nodesc", client);
				}
			}
			ReplaceString(text, sizeof(text), "\\n", "\n");
		}
	}

	Handle dMenu = CreateMenu(ConfirmBossH);
	SetMenuTitle(dMenu, text);

	Format(text, sizeof(text), "%T", "ff2boss_confirm", client, cIncoming[client]);
	AddMenuItem(dMenu, text, text);

	Format(text, sizeof(text), "%T", "ff2boss_cancel", client);
	AddMenuItem(dMenu, text, text);

	SetMenuExitButton(dMenu, false);
	DisplayMenu(dMenu, client, 20);
	return Plugin_Handled;
}

public int ConfirmBossH(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0: 
				{
					IsBossSelected[param1]=true;
					GetMenuItem(menu, param2, Incoming[param1], sizeof(Incoming[]));
					CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2boss_bossselected", Incoming[param1]);
				}
				default:
				{
					BossSelectMenu(param1, 0);
				}
			}
		}
	}
	return;
}

public Action FF2_OnSpecialSelected(int boss, int &SpecialNum, char[] SpecialName, bool preset)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(preset)
	{
		if(!boss && !StrEqual(Incoming[client], ""))
		{
			CPrintToChat(client, "{olive}[FF2]{default] %t", "ff2boss_selection_adminoverride");
		}
		return Plugin_Continue;
	}

	if(!boss && !StrEqual(Incoming[client], ""))
	{
		IsBossSelected[client]=false;
		strcopy(SpecialName, sizeof(Incoming[]), Incoming[client]);
		Incoming[client] = "";
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client, bool checkifAlive=false, bool replayCheck=false)
{
	if (client <= 0 || client > MaxClients) return false;
	if(checkifAlive) return IsClientInGame(client) && IsPlayerAlive(client);
	if(replayCheck) return IsClientInGame(client) && (IsClientSourceTV(client) || IsClientReplay(client));
	return IsClientInGame(client);
}