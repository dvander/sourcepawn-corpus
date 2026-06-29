#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME     "Third Person"
#define PLUGIN_VERSION  "1.0.8"

#define DELAY   0.250       // Delay is set in seconds
#define PREFIX  "\x01[SM]"  // For colored chat

#define COLOR_DEFAULT   0x01
#define COLOR_GREEN     0x04

#define CMD_MENU        "view"

#define CMD_TP_SHORT    "tp"
#define CMD_TP_LONG     "thirdperson"

#define CMD_FP_SHORT    "fp"
#define CMD_FP_LONG     "firstperson"

new Handle:g_Cvar_Default = INVALID_HANDLE;
new Handle:g_Cvar_CanChange = INVALID_HANDLE;
new Handle:g_Cvar_Notice = INVALID_HANDLE;
new Handle:g_Cvar_NoticeDelay = INVALID_HANDLE;

new bool:g_bInThirdPersonView[MAXPLAYERS + 1];

public Plugin:myinfo =
{
  name = PLUGIN_NAME,
  author = "Victor Korobkovsky <vitkorob@gmail.com>",
  description = "Toggles the view to thirdperson and back",
  version = PLUGIN_VERSION,
  url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
  LoadTranslations("common.phrases");
  LoadTranslations("core.phrases");
  LoadTranslations("thirdperson.phrases");
  
  CreateConVar("sm_tp_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN | FCVAR_NOTIFY);
  
  g_Cvar_Default = CreateConVar("sm_tp_default", "0", "Set default view (0 firstperson, 1 thirdperson, def. 0)", 0, true, 0.0, true, 1.0);
  g_Cvar_CanChange = CreateConVar("sm_tp_can_change", "1", "Can clients change their view? (0 no, 1 yes, def. 1)", FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0);
  g_Cvar_Notice = CreateConVar("sm_tp_notice", "1", "Enable or disable notification about plugin (0 disable, 1 enable, def. 1)", 0, true, 0.0, true, 1.0);
  g_Cvar_NoticeDelay = CreateConVar("sm_tp_notice_delay", "5.0", "Delay the appearance of the notification after round start (in seconds)", 0, true, 0.0, true, 90.0);
  
  RegConsoleCmd("say", Command_Say);
  RegConsoleCmd("say_team", Command_Say);
  
  RegConsoleCmd("sm_firstperson", Command_FirstPerson);
  RegConsoleCmd("sm_thirdperson", Command_ThirdPerson);
  
  HookEvent("player_class", PlayerSpawn);
  HookEvent("player_spawn", PlayerSpawn);
  
  HookEvent("teamplay_round_start", RoundStart);
  
  AutoExecConfig(true, "thirdperson");
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
  new userid = GetEventInt(event, "userid");
  new client = GetClientOfUserId(userid);
  
  CreateTimer(DELAY, ThirdPersonOnSpawn, client);
}

public Action:ThirdPersonOnSpawn(Handle:timer, any:client)
{
  if (IsClientInGame(client) && g_bInThirdPersonView[client] && IsPlayerAlive(client))
  {
    SetThirdPersonView(client);
  }
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
  if (GetConVarBool(g_Cvar_Notice))
  {
    CreateTimer(GetConVarFloat(g_Cvar_NoticeDelay), ShowNotice);
  }
  
  for (new i = 1; i <= MaxClients; i++)
  {
    CreateTimer(DELAY, ThirdPersonOnSpawn, i);
  }
}

public Action:ShowNotice(Handle:timer)
{
  PrintToChatAll("%s %t", PREFIX, "Plugin Notice", COLOR_GREEN, COLOR_DEFAULT, COLOR_GREEN, COLOR_DEFAULT, COLOR_GREEN, COLOR_DEFAULT);
}

public OnClientConnected(client)
{
  g_bInThirdPersonView[client] = GetConVarBool(g_Cvar_Default);
}

public Action:Command_FirstPerson(client, args)
{
  if (client == 0)
  {
    ReplyToCommand(client, "%s %t", PREFIX, "Command is in-game only");
    return Plugin_Handled;
  }
  
  FirstPersonRequest(client);
  
  return Plugin_Handled;
}

public Action:Command_ThirdPerson(client, args)
{
  if (client == 0)
  {
    ReplyToCommand(client, "%s %t", PREFIX, "Command is in-game only");
    return Plugin_Handled;
  }
  
  ThirdPersonRequest(client);
  
  return Plugin_Handled;
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
  switch (action)
  {
    case MenuAction_Display:
    {
      decl String:buffer[192];
      Format(buffer, sizeof(buffer), "%T", "Select View", param1);
      
      new Handle:panel = Handle:param2;
      SetPanelTitle(panel, buffer);
    }
    
    case MenuAction_DisplayItem:
    {
      decl String:info[32];
      GetMenuItem(menu, param2, info, sizeof(info));
      
      decl String:buffer[192];
      
      if (strcmp(info, CMD_FP_SHORT, false) == 0)
      {
        Format(buffer, sizeof(buffer), "%T", "First Person", param1);
        return RedrawMenuItem(buffer);
      }
      else if (strcmp(info, CMD_TP_SHORT, false) == 0)
      {
        Format(buffer, sizeof(buffer), "%T", "Third Person", param1);
        return RedrawMenuItem(buffer);
      }
    }
    
    case MenuAction_Select:
    {
      decl String:info[32];
      GetMenuItem(menu, param2, info, sizeof(info));
	  
      if (strcmp(info, CMD_FP_SHORT, false) == 0)
      {
        FirstPersonRequest(param1);
      }
      else if (strcmp(info, CMD_TP_SHORT, false) == 0)
      {
        ThirdPersonRequest(param1);
      }
    }
    
    case MenuAction_End:
    {
      CloseHandle(menu);
    }
  }
  
  return 0;
}

public Action:Command_Say(client, args)
{
  if (client == 0)
  {
    return Plugin_Continue;
  }
  
  decl String:text[192];
  
  if (!GetCmdArgString(text, sizeof(text)))
  {
    return Plugin_Continue;
  }
  
  new startidx = 0;
  
  if (text[strlen(text) - 1] == '"')
  {
    text[strlen(text) - 1] = '\0';
    startidx = 1;
  }
  
  new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
  
  if (strcmp(text[startidx], CMD_TP_SHORT, false) == 0 || strcmp(text[startidx], CMD_TP_LONG, false) == 0)
  {
    ThirdPersonRequest(client);
  }
  else if (strcmp(text[startidx], CMD_FP_SHORT, false) == 0 || strcmp(text[startidx], CMD_FP_LONG, false) == 0)
  {
    FirstPersonRequest(client);
  }
  else if (strcmp(text[startidx], CMD_MENU, false) == 0)
  {
    new Handle:menu = CreateMenu(MenuHandler, MENU_ACTIONS_ALL);
    SetMenuTitle(menu, "Select view");
    
    AddMenuItem(menu, CMD_FP_SHORT, "First person");
    AddMenuItem(menu, CMD_TP_SHORT, "Third person");
    
    SetMenuExitButton(menu, false);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
  }
  
  SetCmdReplySource(old);
  
  return Plugin_Continue;
}

SetThirdPersonView(client)
{
  g_bInThirdPersonView[client] = true;
  
  SetVariantInt(1);
  AcceptEntityInput(client, "SetForcedTauntCam");
}

SetFirstPersonView(client)
{
  g_bInThirdPersonView[client] = false;
  
  SetVariantInt(0);
  AcceptEntityInput(client, "SetForcedTauntCam");
}

ThirdPersonRequest(client)
{
  if (!GetConVarBool(g_Cvar_CanChange))
  {
    ReplyToCommand(client, "%s %t", PREFIX, "No Access");
    return;
  }
  
  if (g_bInThirdPersonView[client])
  {
    ReplyToCommand(client, "%s %t", PREFIX, "Thirdperson Already Enabled");
  }
  else
  {
    SetThirdPersonView(client);
    ReplyToCommand(client, "%s %t", PREFIX, "Thirdperson Enabled");
  }
}

FirstPersonRequest(client)
{
  if (!GetConVarBool(g_Cvar_CanChange))
  {
    ReplyToCommand(client, "%s %t", PREFIX, "No Access");
    return;
  }
  
  if (!g_bInThirdPersonView[client])
  {
    ReplyToCommand(client, "%s %t", PREFIX, "Firstperson Already Enabled");
  }
  else
  {
    SetFirstPersonView(client);
    ReplyToCommand(client, "%s %t", PREFIX, "Firstperson Enabled");
  }
}
