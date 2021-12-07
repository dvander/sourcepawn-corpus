#include <sourcemod>
//ы#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#tryinclude <updater>
#pragma newdecls required
#define REQUIRE_PLUGIN

#define MENU_ACTION_OFFSET -3

#define KV_ROOT_NAME "server_rules"

#define MENU_ITEM_DELETE_RULE 6

#define MENU_SELECT_SOUND	"buttons/button14.wav"
#define MENU_EXIT_SOUND	"buttons/combine_button7.wav"

#define UPDATE_URL    "https://raw.githubusercontent.com/eyal282/AlliedmodsUpdater/master/AdvancedRules/updatefile.txt"

#define PLUGIN_VERSION "2.2"

#define MAX_RULES 30
#define DESC_LENGTH 1024

bool DisplayRules[MAXPLAYERS+1];

char ClientRuleName[MAXPLAYERS+1][64];
char ClientRuleDesc[MAXPLAYERS+1][DESC_LENGTH]
char LastRulesItem[MAXPLAYERS+1]; // first item on the page with rules last seen
int ClientPanelPage[MAXPLAYERS+1];
int ClientViewItem[MAXPLAYERS+1]; //item currently viewing

int ClientConfirmDeleteRuleItem[MAXPLAYERS+1], ClientConfirmDeleteRuleUnixTime[MAXPLAYERS+1];

Handle hCookie_LastAccept = INVALID_HANDLE;

int RulesLastEdit = 0; // This is the latest updated rule out of all.
int LastConfigsExecuted = 0; // This is to protect from double deleting resulting in the wrong rule being deleted.

char RulesPath[512];

enum struct enRules
{
	char enRuleName[64];
	char enRuleDesc[DESC_LENGTH];
	int enRuleLastEdit;
}

ArrayList Array_Rules;

ConVar hcv_ForceShowRules = null;

public Plugin myinfo = 
{
	name = "Advanced Rules Menu",
	author = "Eyal282",
	description = "A highly efficient rules menu that prioritizes maximum convenience.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/"
};

native bool AdvancedRules_ShouldClientReadRules(int client);

/**
* @param client 			client index to test if he has some rules to read.
* @return					true if client did not read and accept all rules, false if he did.

*/

native void AdvancedRules_ShowRulesToClient(int client, int item = 0);

/**
* @param client 			client index to test if he has some rules to read.
* @param item 				item from which the rules menu will be displayed from.

* @return					true on success, false on failure and will throw an error.

*/

public APLRes AskPluginLoad2(Handle myself, bool bLate, char[] error, int errorLen)
{
	CreateNative("AdvancedRules_ShouldClientReadRules", Native_ShouldClientReadRules);
	CreateNative("AdvancedRules_ShowRulesToClient", Native_ShowRulesToClient);
}

public any Native_ShouldClientReadRules(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	
	if(!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Invalid client index or client not in-game");
		
		return false;
	}
	else if(!AreClientCookiesCached(client))
		return false;
	
	return RulesLastEdit > GetClientLastAcceptRules(client);
}

public any Native_ShowRulesToClient(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	
	if(!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Invalid client index or client not in-game");
		
		return false;
	}
	
	ClientViewItem[client] = GetNativeCell(2);
	ShowRulesMenu(client);
	
	return true;
}

public void OnPluginStart()
{
	BuildPath(Path_SM, RulesPath, sizeof(RulesPath), "configs/Rules.cfg");
	
	Array_Rules = new ArrayList(sizeof(enRules));
	
	RegConsoleCmd("sm_rules", Command_Rules, "Display the server rules");
	RegAdminCmd("sm_statusrules", Command_StatusRules, ADMFLAG_GENERIC, "Display the list of players and their last date of accepting the rules.");
	RegAdminCmd("sm_showrules", Command_StatusRules, ADMFLAG_GENERIC, "Display the list of players and their last date of accepting the rules.");
	RegAdminCmd("sm_managerules", Command_ManageRules, ADMFLAG_ROOT, "Manage the server rules");
	
	RegAdminCmd("sm_addrule_name", Command_AddRule_Name, ADMFLAG_ROOT, "Name of new rule to add");
	RegAdminCmd("sm_addrule_desc", Command_AddRule_Desc, ADMFLAG_ROOT, "Description of new rule to add");
	
	CreateConVar("advanced_rules_version", PLUGIN_VERSION, "", FCVAR_NOTIFY);
	hcv_ForceShowRules = CreateConVar("advanced_rules_force_show", "-1", "If a player didn't accept the rules or if they were updated, show rules menu in x seconds after connect, -1 to disable.");
	hCookie_LastAccept = RegClientCookie("AdvancedRules_LastAcceptRules", "The last time you have accepted the rules, unix timestamp.", CookieAccess_Public);
	
	LoadTranslations("advancedrules.phrases"); 

	OnMapStart();
	
	#if defined _updater_included
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
	
}

public void OnClientConnected(int client)
{
	DisplayRules[client] = false;
}
public void OnClientPostAdminCheck(int client)
{
	if(!AreClientCookiesCached(client)) {
		DisplayRules[client] = true;
	}
	else
	{
		if(RulesLastEdit > GetClientLastAcceptRules(client))
		{
			if(hcv_ForceShowRules.FloatValue > 0) {
				CreateTimer(hcv_ForceShowRules.FloatValue, Timer_DisplayRulesToClient, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			// After 3 seconds if it's set to -1 tell him about viewing the rules.
			CreateTimer(hcv_ForceShowRules.FloatValue + 4.0, Timer_DisplayInfoToClient, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else  // client accepted rules. Just to remind him how to read rules if he want to
			CreateTimer(hcv_ForceShowRules.FloatValue + 4.0, Timer_DisplayReadToClient, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_DisplayRulesToClient(Handle hTimer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if(client == 0 || !IsClientConnected(client) || IsFakeClient(client))
		return Plugin_Continue;
		
	ShowRulesMenu(client);
	
//	PrintToChat(client, "\x01 %t", "Read Rules");
//	PrintToChat(client, "\x01 %t", "Consequences");
	
	return Plugin_Continue;
}

public Action Timer_DisplayInfoToClient(Handle hTimer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return Plugin_Continue;
		
	PrintToChat(client, " \x04!rules\x01 %t", "Confirm");
	
	return Plugin_Continue;
}
public Action Timer_DisplayReadToClient(Handle hTimer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return Plugin_Continue;
		
	PrintToChat(client, " \x04!rules\x01 %t", "Read");
	
	return Plugin_Continue;
}

public void OnClientCookiesCached(int client)
{
	if(DisplayRules[client]) // Post Admin check and cookies weren't cached yet.
	{
		if(RulesLastEdit > GetClientLastAcceptRules(client) && hcv_ForceShowRules.FloatValue > 0)
			CreateTimer(hcv_ForceShowRules.FloatValue, Timer_DisplayRulesToClient, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(hcv_ForceShowRules.FloatValue + 4.0, Timer_DisplayReadToClient, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		DisplayRules[client] = false;
	}
}

public void OnClientDisconnect(int client)
{
	DisplayRules[client] = false;
}

#if defined _updater_included
public void Updater_OnPluginUpdated()
{
	ReloadPlugin(INVALID_HANDLE);
}
#endif
public void OnLibraryAdded(const char[] name)
{
	#if defined _updater_included
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

void OnMapStart()
{
	PrecacheSound(MENU_SELECT_SOUND);
	PrecacheSound(MENU_EXIT_SOUND);
}

public void OnConfigsExecuted()
{
	AutoExecConfig(true, "advancedrules"); //to have a chance to store cvar in the config
	LoadConfigFile();
}

bool LoadConfigFile()
{
	Array_Rules.Clear();
	Handle keyValues = CreateKeyValues(KV_ROOT_NAME);
	
	if(!FileToKeyValues(keyValues, RulesPath))
	{
		CreateEmptyKvFile(RulesPath);
		return false;
	}	

	if(!KvGotoFirstSubKey(keyValues))
		return false;
	
	enRules RuleArray;
	
	int UnixTime = GetTime();
	
	int SectionIndex = 1;
	char SectionName[11];

//	LogMessage("Size: %i", sizeof(enRules));

	do
	{
		IntToString(SectionIndex, SectionName, sizeof(SectionName));
		KvSetSectionName(keyValues, SectionName);
		KvGetString(keyValues, "name", RuleArray.enRuleName, sizeof(RuleArray.enRuleName));
//		LogMessage("Name: %s", RuleArray.enRuleName);
		KvGetString(keyValues, "description", RuleArray.enRuleDesc, sizeof(RuleArray.enRuleDesc));
//		LogMessage("Desc: %s", RuleArray.enRuleDesc);
		
		ReplaceString(RuleArray.enRuleName, sizeof(RuleArray.enRuleName), "//q", "\"");
		ReplaceString(RuleArray.enRuleDesc, sizeof(RuleArray.enRuleDesc), "//q", "\"");
		
		RuleArray.enRuleLastEdit = KvGetNum(keyValues, "last_edit", UnixTime);
		
		KvSetNum(keyValues, "last_edit", RuleArray.enRuleLastEdit); // This is to update rules without a timestamp with the current one.
		
		if(RulesLastEdit < RuleArray.enRuleLastEdit)
			RulesLastEdit = RuleArray.enRuleLastEdit;
			
		PushArrayArray(Array_Rules, RuleArray, sizeof(RuleArray));
		
		SectionIndex++;
	}
	while(KvGotoNextKey(keyValues));
	
	KvRewind(keyValues);
	KeyValuesToFile(keyValues, RulesPath);
	
	CloseHandle(keyValues);
	
	LastConfigsExecuted = GetTime();
	
	return true;
}

public Action Command_Rules(int client, int args)
{
	ClientViewItem[client] = 0;
	LastRulesItem[client] = 1;
	ShowRulesMenu(client);
	
	return Plugin_Handled;
}

void ShowRulesMenu(int client)
{
	Menu hMenu = new Menu(MenuHandler_Rules);
	
	enRules RuleArray;
	
	int ArraySize = GetArraySize(Array_Rules);
	char TempFormat[65];
	
	int LastAcceptRules = GetClientLastAcceptRules(client);
	
	for(int i = 0; i < ArraySize; i++)
	{
		GetArrayArray(Array_Rules, i, RuleArray, sizeof(enRules));
		
		Format(TempFormat, sizeof(TempFormat), "%s%s", RuleArray.enRuleName, LastAcceptRules < RuleArray.enRuleLastEdit ? "*" : "");
		hMenu.AddItem("", TempFormat);
	}
	
	char text[256];
	Format(text, sizeof(text), "%t", "ACCEPT THE RULES")
	hMenu.AddItem("accept", text);
	Format(text, sizeof(text), "%t", "Choose rule to read");
	hMenu.SetTitle(text);
	
	hMenu.DisplayAt(client, LastRulesItem[client]-1, MENU_TIME_FOREVER);
}


int MenuHandler_Rules(Menu hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		delete hMenu;
	
	else if(action == MenuAction_Select)
	{
		char Info[8];
		hMenu.GetItem(item, Info, sizeof(Info));
		
		if(StrEqual(Info, "accept"))	
		{
			SetClientLastAcceptRules(client, GetTime());
			PrintToChat(client, "%t", "Success");
		}
		else
		{
			LastRulesItem[client] = GetMenuSelectionPosition();
			ClientPanelPage[client] = 0; // show the rule from the first page
			ClientViewItem[client] = item;
			ShowClientRule(client, item);
		}
	}
}

void ShowClientRule(int client, int item)
{
	Panel hPanel = new Panel(GetMenuStyleHandle(MenuStyle_Radio));
	
	enRules RuleArray;
	GetArrayArray(Array_Rules, item, RuleArray, sizeof(enRules));

	int rulesOnPage = 4;

	char RuleDescLines[MAX_RULES][DESC_LENGTH];
	int lines = ExplodeString(RuleArray.enRuleDesc, "/n", RuleDescLines, sizeof(RuleDescLines), sizeof(RuleDescLines[]));
//	LogMessage("Number of lines: %i", lines);
	int pagesCount  = (lines - 1)/rulesOnPage + 1;
	if (pagesCount == 1) rulesOnPage++; //we skip the line with number of pages
	
//	LogMessage("Number of pages: %i", pagesCount);
	if ( ClientPanelPage[client] < 0 ) ClientPanelPage[client] = pagesCount - 1;
    if ( ClientPanelPage[client] >= pagesCount ) ClientPanelPage[client] = 0;
//    LogMessage("Client on page: %i", ClientPanelPage[client]+1);
    int startRule = ClientPanelPage[client] * rulesOnPage + 1;
    int endRule = (lines - (ClientPanelPage[client] +1) * rulesOnPage) > 0 ? startRule + rulesOnPage - 1 : lines;
//    LogMessage("Start rule No: %i", startRule);
//    LogMessage("End rule No: %i", endRule);
    char text[256];
	Format(text, sizeof(text), "%s%s", RuleArray.enRuleName, GetClientLastAcceptRules(client) < RuleArray.enRuleLastEdit ? "*" : "");
	hPanel.SetTitle(text, false);
    if (pagesCount > 1)
	{
	    Format(text, sizeof(text), "%t", "RulesPanel: Page", ClientPanelPage[client] + 1, pagesCount);
	    hPanel.DrawText(text);
    }
    hPanel.DrawItem("", ITEMDRAW_SPACER);

	for(int i = startRule; i <= endRule; i++)
	{		
//		LogMessage("Line No %i: %s", i, RuleDescLines[i-1]);
		hPanel.DrawText(RuleDescLines[i-1]);
	}
	hPanel.DrawItem("", ITEMDRAW_SPACER);
	if (pagesCount > 1)
	{
		hPanel.CurrentKey = 7;
		Format(text, sizeof(text), "%t", "Back");
		hPanel.DrawItem(text,ITEMDRAW_CONTROL);
		Format(text, sizeof(text), "%t", "Next");
		hPanel.DrawItem(text,ITEMDRAW_CONTROL);
	}
	
	Format(text, sizeof(text), "%t", "Exit");
	hPanel.CurrentKey = 9;
	hPanel.DrawItem(text,ITEMDRAW_CONTROL);
	
	hPanel.Send(client, PanelHandler_ShowRule, MENU_TIME_FOREVER);
//	delete hPanel;
	hPanel.Close();
}

int PanelHandler_ShowRule(Menu hPanel, MenuAction action, int client, int item)
{		
	if(action == MenuAction_Select)
    {
        switch(item)
        {
            case 7:
            {
                --ClientPanelPage[client];
                ShowClientRule(client, ClientViewItem[client]);
                EmitSoundToClient(client, MENU_SELECT_SOUND);
            }
            case 8:
            {
                ++ClientPanelPage[client];
                ShowClientRule(client, ClientViewItem[client]);
                EmitSoundToClient(client, MENU_SELECT_SOUND);
            }
            case 9:
            {
                ShowRulesMenu(client);
				EmitSoundToClient(client, MENU_EXIT_SOUND);
            }
        }
    }
}


public Action Command_StatusRules(int client, int args)
{
	ShowStatusRules(client, 0);
	
	return Plugin_Handled;
}

void ShowStatusRules (int client, int item)
{
	Menu hMenu = new Menu(MenuHandler_StatusRules);
	
	char TempFormat[128];
	
	char sUserId[11]; 
	char Time[32];
	
	for(int i=1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(IsFakeClient(i))
			continue;
			
		
		IntToString(GetClientUserId(i), sUserId, sizeof(sUserId));
		
		int LastAcceptRules = GetClientLastAcceptRules(i);
		if(LastAcceptRules <= 0)
			Format(Time, sizeof(Time), "%t", "Never");
		
		else	
			FormatTime(Time, sizeof(Time), "%d-%m-%Y", LastAcceptRules);
			
		Format(TempFormat, sizeof(TempFormat), "%N [%s] [%t]", i, Time, LastAcceptRules < RulesLastEdit ? "Yes" : "No");
		hMenu.AddItem(sUserId, TempFormat);
	}
		Format(TempFormat, sizeof(TempFormat), "%t", "Choose player");
	hMenu.SetTitle(TempFormat);
	
	DisplayMenuAtItem(hMenu, client, item, MENU_TIME_FOREVER);
}

int MenuHandler_StatusRules(Menu hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		hMenu.Close();
	
	else if(action == MenuAction_Select)
	{
		char sUserId[11];
		hMenu.GetItem(item, sUserId, sizeof(sUserId));
		
		int target = GetClientOfUserId(StringToInt(sUserId));
		
		if(target == 0)
		{
			PrintToChat(client, "%t", "Not Connected");
			return;
		}
		
		Command_Rules(target, 0);
		PrintToChat(target, " \x01Admin \x03%N\x01 %t", client, "Force");
		
		ShowStatusRules(client, GetMenuSelectionPosition());
	}
}

public Action Command_ManageRules(int client, int args)
{
	Menu hMenu = new Menu(MenuHandler_ManageRules);

	char text[256];
	
	Format(text, sizeof(text), "%t", "Add a rule");
	hMenu.AddItem("", text);
	Format(text, sizeof(text), "%t", "Delete a rule");
	hMenu.AddItem("", text);
	Format(text, sizeof(text), "%t", "Rearrange rules");
	hMenu.AddItem("", text);
	//AddMenuItem(hMenu, "", "Rearrange all rules");
	
	hMenu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

int MenuHandler_ManageRules(Menu hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{
		switch(item)
		{
			case 0:
			{
				if(ClientRuleName[client][0] == EOS)
					PrintToChat(client, "%t", "Add rule name");
					
				else if(ClientRuleDesc[client][0] == EOS)
					PrintToChat(client, "%t", "Add rule description");
					
				else
				{
					AddNewRule(ClientRuleName[client], ClientRuleDesc[client]);
					
					ClientRuleName[client][0] = EOS;
					ClientRuleDesc[client][0] = EOS;
					
					PrintToChat(client, "%t", "Rule added");
				}	
				
				Command_ManageRules(client, 0);
			}
			case 1:
			{
				Command_DeleteRules(client, 0);
			}
			case 2:
			{
				Command_MoveRule(client, 0);
			}
		}
	}
}

public Action Command_AddRule_Name(int client, int args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "%t", "SM rule usage");
		return Plugin_Handled;
	}
	
	GetCmdArgString(ClientRuleName[client], sizeof(ClientRuleName[]));
	
	ReplaceString(ClientRuleName[client], sizeof(ClientRuleName[]), "\"", "//q");
	ReplaceString(ClientRuleDesc[client], sizeof(ClientRuleDesc[]), "\"", "//q");
	
	PrintToChat(client, "%t %s", "Success set rule name", ClientRuleName[client]);
	
	Command_ManageRules(client, 0);
	
	return Plugin_Handled;
}

public Action Command_AddRule_Desc(int client, int args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "%t", "SM description usage");
		return Plugin_Handled;
	}
	
	GetCmdArgString(ClientRuleDesc[client], sizeof(ClientRuleDesc[]));
	
	ReplaceString(ClientRuleDesc[client], sizeof(ClientRuleDesc[]), "\"", "//q");
	ReplaceString(ClientRuleDesc[client], sizeof(ClientRuleDesc[]), "\\", "");
	
	PrintToChat(client, "%t %s", "Success set rule description", ClientRuleDesc[client]);
	Command_ManageRules(client, 0);
	
	return Plugin_Handled;
}

public Action Command_DeleteRules(int client, int args)
{
	Menu hMenu = new Menu(MenuHandler_DeleteRules);
	
	enRules RuleArray;
	
	int ArraySize = GetArraySize(Array_Rules);
	
	char sUnixTime[11];
	IntToString(GetTime(), sUnixTime, sizeof(sUnixTime)); // Safety so if two admins edit rules the later will fail.
	for(int i=0; i < ArraySize; i++)
	{
		GetArrayArray(Array_Rules, i, RuleArray, sizeof(enRules));

		hMenu.AddItem(sUnixTime, RuleArray.enRuleName);
	}
	
	char text[8];
	Format(text, sizeof(text), "%t", "Delete rule");
	hMenu.SetTitle(text);
	
	hMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

int MenuHandler_DeleteRules(Menu hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		hMenu.Close();
	
	else if(action == MenuAction_Select)
	{	
		char sUnixTime[11];
		hMenu.GetItem(item, sUnixTime, sizeof(sUnixTime));
		ConfirmDeleteRule(client, item, StringToInt(sUnixTime));
	}
}

public void ConfirmDeleteRule(int client, int item, int UnixTime)
{		
	if(UnixTime < LastConfigsExecuted)
	{
		PrintToChat(client, "%t", "Couldnt Delete");
		return;
	}
	
	ClientConfirmDeleteRuleItem[client] = item;
	ClientConfirmDeleteRuleUnixTime[client] = UnixTime;
	
	Handle hPanel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
	
	enRules RuleArray;
	GetArrayArray(Array_Rules, item, RuleArray, sizeof(enRules));
	
	char RuleDescLines[MAX_RULES][DESC_LENGTH];
	
	int lines = ExplodeString(RuleArray.enRuleDesc, "/n", RuleDescLines, sizeof(RuleDescLines), sizeof(RuleDescLines[]));
	
	for(int i=0; i < lines; i++)
		DrawPanelText(hPanel, RuleDescLines[i]);
	
	char text[128];

	SetPanelCurrentKey(hPanel, 6);
	Format(text, sizeof(text), "%t", "DELETE");
	DrawPanelItem(hPanel, text);
	
	SetPanelCurrentKey(hPanel, 9); // There will not be a back button because 7 is close to 6.
	Format(text, sizeof(text), "%t", "Exit");
	DrawPanelItem(hPanel, text);
	
	SetPanelKeys(hPanel, (1<<5)|(1<<8));
	
	char Time[32];
	FormatTime(Time, sizeof(Time), "%d-%m-%Y", RuleArray.enRuleLastEdit);
	char PanelTitle[65];
	Format(PanelTitle, sizeof(PanelTitle), "%s\n%t %s", RuleArray.enRuleName, "Last Edited", Time);
	SetPanelTitle(hPanel, PanelTitle, false);
	
	SendPanelToClient(hPanel, client, PanelHandler_ConfirmDeleteRule, MENU_TIME_FOREVER);
	
	CloseHandle(hPanel);
}

int PanelHandler_ConfirmDeleteRule(Handle hPanel, MenuAction action, int client, int item)
{		
	if(action == MenuAction_Select)
	{
		if(item == MENU_ITEM_DELETE_RULE)
		{
			if(ClientConfirmDeleteRuleUnixTime[client] < LastConfigsExecuted)
			{
				PrintToChat(client, "%t", "Couldnt Delete");
				return;
			}
			
			if(DeleteExistingRule(ClientConfirmDeleteRuleItem[client]+1))
				PrintToChat(client, "%t", "Successfully deleted");

			else
				PrintToChat(client, "%t", "Could not delete");
		}
	}
}		

public Action Command_MoveRule(int client, int args)
{
	int ArraySize = GetArraySize(Array_Rules);
	
	if(ArraySize < 2)
	{
		PrintToChat(client, "%t", "More than one");
		return Plugin_Handled;
	}
	
	Menu hMenu = new Menu(MenuHandler_MoveRule);
	
	char text[128];
	Format(text, sizeof(text), "%t", "Choose to move")

	hMenu.SetTitle(text);
	
	enRules RuleArray;
	
	char sUnixTime[11];
	IntToString(GetTime(), sUnixTime, sizeof(sUnixTime)); // Safety so if two admins edit rules the later will fail.
	
	for(int i=0; i < ArraySize; i++)
	{
		GetArrayArray(Array_Rules, i, RuleArray, sizeof(enRules));

		hMenu.AddItem(sUnixTime, RuleArray.enRuleName);
	}
	
	hMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

int MenuHandler_MoveRule(Menu hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		hMenu.Close();
	
	else if(action == MenuAction_Select)
	{	
		char sUnixTime[11];
		hMenu.GetItem(item, sUnixTime, sizeof(sUnixTime));
		
		if(StringToInt(sUnixTime) < LastConfigsExecuted)
		{
			PrintToChat(client, "%t", "Couldnt Move");
			return;
		}
		MoveRuleReference(client, item, sUnixTime);
	}
}

public void MoveRuleReference(int client, int item, char sUnixTime[11])
{
	Menu hMenu = new Menu(MenuHandler_MoveRuleReference);
	
	enRules RuleArray;
	
	int ArraySize = GetArraySize(Array_Rules);

	char Info[25];
	Format(Info, sizeof(Info), "\"%s\" \"%i\"", sUnixTime, item);

	for(int i=0; i < ArraySize; i++)
	{
		if(item == i)
			continue;
			
		GetArrayArray(Array_Rules, i, RuleArray, sizeof(enRules));

		hMenu.AddItem(Info, RuleArray.enRuleName);
	}
	
	char text[128];
	Format(text, sizeof(text), "%t", "Choose to put before")
	hMenu.SetTitle(text);
	
	hMenu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_MoveRuleReference(Menu hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		hMenu.Close();
	
	else if(action == MenuAction_Select)
	{	
		char sUnixTime[11];
		char sRuleIndex[11]; 
		char Info[25];
		hMenu.GetItem(item, Info, sizeof(Info));

		int len = BreakString(Info, sUnixTime, sizeof(sUnixTime));
		
		Format(sRuleIndex, sizeof(sRuleIndex), Info[len]);
		
		StripQuotes(sUnixTime);
		StripQuotes(sRuleIndex);
		
		if(StringToInt(sUnixTime) < LastConfigsExecuted)
		{
			PrintToChat(client, "%t", "Couldnt Move");
			return;
		}
		
		int RuleItem = StringToInt(sRuleIndex);
		
		enRules RuleArray[2];
		
		if(item >= RuleItem)
			item++;
		
		GetArrayArray(Array_Rules, RuleItem, RuleArray[0], sizeof(enRules));
		GetArrayArray(Array_Rules, item, RuleArray[1], sizeof(enRules));

		if(MoveRuleToPosition(item, RuleItem))
			PrintToChat(client, "%t", "Successfully moved");

		else
			PrintToChat(client, "%t", "Could not move");
	}
}

stock bool MoveRuleToPosition(int RuleOldItem, int RuleNewItem)
{
	
	if(!LoadConfigFile())
		return false;

	enRules RuleArray;
	if(!MoveArrayItem(Array_Rules, RuleOldItem, RuleNewItem))
		return false;
	
	Handle keyValues = CreateKeyValues("server_rules");
	
	int ArraySize = GetArraySize(Array_Rules);
	
	char sRuleIndex[11];
	
	for(int i=0; i < ArraySize; i++)
	{
		IntToString(i+1, sRuleIndex, sizeof(sRuleIndex));
		KvJumpToKey(keyValues, sRuleIndex, true);
		GetArrayArray(Array_Rules, i, RuleArray, sizeof(enRules));
		
		ReplaceString(RuleArray.enRuleName, sizeof(RuleArray.enRuleName), "\"", "//q");
		ReplaceString(RuleArray.enRuleDesc, sizeof(RuleArray.enRuleDesc), "\"", "//q");
		
		KvSetString(keyValues, "name", RuleArray.enRuleName);
		KvSetString(keyValues, "description", RuleArray.enRuleDesc);
		KvSetNum(keyValues, "last_edit", RuleArray.enRuleLastEdit);
		
		KvRewind(keyValues);
	}
	
	KvRewind(keyValues);
	KeyValuesToFile(keyValues, RulesPath);
	
	CloseHandle(keyValues);
	
	LoadConfigFile();
	
	return true;
}

stock void AddNewRule(const char[] RuleName, const char[] RuleDesc)
{
	Handle keyValues = CreateKeyValues(KV_ROOT_NAME);
	
	if(!FileToKeyValues(keyValues, RulesPath))
	{
		CreateEmptyKvFile(RulesPath);
		
		if(!FileToKeyValues(keyValues, RulesPath))
			SetFailState("Something that should never happen has happened.");
	}	
	
	char SectionName[11];
	if(!KvGotoFirstSubKey(keyValues))
		SectionName = "1"

	else
	{	
		do
		{
			KvGetSectionName(keyValues, SectionName, sizeof(SectionName));
		}
		while(KvGotoNextKey(keyValues))
		
		int iSectionName = StringToInt(SectionName);
		
		IntToString(iSectionName + 1, SectionName, sizeof(SectionName));
		
		KvGoBack(keyValues);
	}
	KvJumpToKey(keyValues, SectionName, true);
	
	KvSetString(keyValues, "name", RuleName);
	KvSetString(keyValues, "description", RuleDesc);
	KvSetNum(keyValues, "last_edit", GetTime());
	KvRewind(keyValues);
	KeyValuesToFile(keyValues, RulesPath);
	CloseHandle(keyValues);
	
	LoadConfigFile();
}

stock bool DeleteExistingRule(int SectionIndex)
{
	Handle keyValues = CreateKeyValues(KV_ROOT_NAME);
	
	if(!FileToKeyValues(keyValues, RulesPath))
	{
		CloseHandle(keyValues);
		return false;
	}
	else if(!KvGotoFirstSubKey(keyValues))
	{
		CloseHandle(keyValues);
		return false;
	}
	bool Deleted;
	char SectionName[11];
	
	do
	{
		KvGetSectionName(keyValues, SectionName, sizeof(SectionName));
		
		if(StringToInt(SectionName) == SectionIndex)
		{
			Deleted = true;
			KvDeleteThis(keyValues);
			break;
		}
	}
	while(KvGotoNextKey(keyValues))
	
	KvRewind(keyValues);
	KeyValuesToFile(keyValues, RulesPath);
	CloseHandle(keyValues);
	
	LoadConfigFile();
	
	return Deleted;
}

stock void CreateEmptyKvFile(const char[] Path)
{
	Handle keyValues = CreateKeyValues(KV_ROOT_NAME);
	
	KvRewind(keyValues);
	KeyValuesToFile(keyValues, Path);
	
	CloseHandle(keyValues);
}

stock int GetClientLastAcceptRules(int client)
{
	char sValue[11];
	GetClientCookie(client, hCookie_LastAccept, sValue, sizeof(sValue));
	
	return StringToInt(sValue);
}

stock void SetClientLastAcceptRules(int client, int timestamp)
{
	char sValue[11];
	IntToString(timestamp, sValue, sizeof(sValue));
	SetClientCookie(client, hCookie_LastAccept, sValue);
}

/**
 * Moves an item in an array before the new item.
 *
 *
 * @param Array				ADT Array Handle
 * @param OldItem			The old item to move from
 * @param NewItem			The item to before which the old item will move to.
 * @return					true on success, false if OldItem == NewItem.
 */
stock bool MoveArrayItem(Handle Array, int OldItem, int NewItem)
{
	if(NewItem == OldItem)
		return false;
	
	if(OldItem > NewItem)
	{
		for(int i=NewItem; i < OldItem-1; i++)
			SwapArrayItems(Array, i, i+1);
	}
	else
	{
		for(int i=NewItem; i > OldItem; i--)
			SwapArrayItems(Array, i, i-1);
	}
	
	return true;
}