/* ========================================================================== */
/*                                                                            */
/*   rules.sp                                                               */
/*   (c) 2009 haN                                                          */
/*                                                                            */
/*   Rules Plugin                                                              */
/*                                                                            */
/* ========================================================================== */

/////////////////////////////////////////////////////////
///////////////  INCLUDES
/////////////////////////////////////////////////////////

#pragma semicolon 1

#include <sourcemod>

#include <sdktools>

#undef REQUIRE_PLUGIN

#include <adminmenu>


#define VERSION "ALPHA 1"

/////////////////////////////////////////////////////////
///////////////  PLUGIN INFO
/////////////////////////////////////////////////////////

public Plugin:myinfo = 
{
    name = "Rules Plugin",
    author = "haN",
    description = "A detailed Rules plugin",
    version = VERSION,
    url = "www.teamsas.nl"
};

/////////////////////////////////////////////////////////
///////////////  ESSENTIAL FUNCTIONS
/////////////////////////////////////////////////////////

public OnPluginStart()
{
    RegConsoleCmd("sm_commands", RulesMenu);
    RegAdminCmd("sm_showrules", ShowRules, ADMFLAG_GENERIC);
}

/////////////////////////////////////////////////////////
///////////////  ON CLIENT CONNECTING TO SERVER SEND RULES
/////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////
///////////////  CMD HANDLERs
/////////////////////////////////////////////////////////

public Action:RulesMenu(client, args)
{
    CreateRulesMenu(client);
}

public Action:ShowRules(client, args)
{
    new Handle:PlayersMenu = CreateMenu(ShowRulesHandler);
    SetMenuTitle(PlayersMenu, "Send Rules To Player");
    SetMenuExitButton(PlayersMenu, true);
    AddTargetsToMenu2(PlayersMenu, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
    DisplayMenu(PlayersMenu, client, 15);
}

/////////////////////////////////////////////////////////
///////////////  MENUs / MENUs HANDLERs
/////////////////////////////////////////////////////////

public Action:CreateRulesMenu(client)
{
    new Handle:RulesMenu = CreateMenu(RulesMenuHandler);
    SetMenuTitle(RulesMenu, "Available Commands");
    
    new Handle:kv = CreateKeyValues("Rules");
    FileToKeyValues(kv, "addons/sourcemod/configs/commands.cfg");
    
	  if (!KvGotoFirstSubKey(kv))
	  {
		    return Plugin_Continue;
	  }
	  decl String:RuleNumber[64];
	  decl String:RuleName[255];
	  
	  do
	  {
    	  KvGetSectionName(kv, RuleNumber, sizeof(RuleNumber));    
        KvGetString(kv, "name", RuleName, sizeof(RuleName));
        AddMenuItem(RulesMenu, RuleNumber, RuleName);    
    } while (KvGotoNextKey(kv));
    CloseHandle(kv);  
    DisplayMenu(RulesMenu, client, 15);
    return Plugin_Handled;  
}

public HandlerBackToMenu(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        CreateRulesMenu(param1);
    }
    else if (action == MenuAction_Cancel)
	  {
		    PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	  }

    else if (action == MenuAction_End)
	  {
		    CloseHandle(menu);
	  }
}


public RulesMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        new Handle:DescriptionPanel = CreatePanel();       
        new Handle:kv = CreateKeyValues("Rules");
        FileToKeyValues(kv, "addons/sourcemod/configs/commands.cfg");
        
        if (!KvGotoFirstSubKey(kv))
	      {
		        return Plugin_Continue;
	      }
        
        decl String:buffer[255];
        decl String:choice[255];
        GetMenuItem(menu, param2, choice, sizeof(choice));     
        
        do
        {   
            KvGetSectionName(kv, buffer, sizeof(buffer));
            if (StrEqual(buffer, choice))
            {
                decl String:ruleName[255];
                decl String:ruleDescription[255];
                KvGetString(kv, "name", ruleName, sizeof(ruleName));
                KvGetString(kv, "description", ruleDescription, sizeof(ruleDescription));
                decl String:Rule[255];
                decl String:Desc[255];
                Format(Rule, sizeof(Rule), "%s", ruleName);
                Format(Desc, sizeof(Desc), "%s", ruleDescription);
                SetPanelTitle(DescriptionPanel, Rule);
                DrawPanelText(DescriptionPanel, " ");
                DrawPanelText(DescriptionPanel, Desc);
                DrawPanelText(DescriptionPanel, " ");
                DrawPanelItem(DescriptionPanel, "Back");
                SendPanelToClient(DescriptionPanel, param1, HandlerBackToMenu, 15);

            }
        } while (KvGotoNextKey(kv));
        CloseHandle(kv);           
    }
    else if (action == MenuAction_Cancel)
	  {
		    PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	  }

    else if (action == MenuAction_End)
	  {
		    CloseHandle(menu);
	  }

    return Plugin_Handled; 
}

public ShowRulesHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:UserId[64];
        GetMenuItem(menu, param2, UserId, sizeof(UserId));
        new i_UserId = StringToInt(UserId);
        new client = GetClientOfUserId(i_UserId);
        CreateRulesMenu(client);
    }

    else if (action == MenuAction_Cancel)
	  {
		    PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	  }

    else if (action == MenuAction_End)
	  {
		    CloseHandle(menu);
	  }

    return Plugin_Handled; 
    
}