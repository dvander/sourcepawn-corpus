/*
* File: rollthedice.sp
* Author: SumGuy14 (Aka SoccerDude)
* Description: Players type "rollthedice" to either receive an award, or be punished
*/

#include <sourcemod>
#include <shvector>

#pragma semicolon 1

#define COLOR_DEFAULT 0x01
#define COLOR_LIGHTGREEN 0x03
#define COLOR_GREEN 0x04

#define MAX_TRIGGERS 32

new Handle:vecActions;

#define VECTOR_ACTIONS_NAME 0
#define VECTOR_ACTIONS_ENABLE 1
#define VECTOR_ACTIONS_CMD 2
#define VECTOR_ACTIONS_DELAY 3

new Handle:cvarWait; // CVar to control the default wait time for an action

new bRoundStarted;

new String:gChatTriggers[MAX_TRIGGERS][64]; // Array to store rollthedice triggers

new gTimeLeft[MAXPLAYERS+1]; // Array to store how long the user has to wait until they can roll again
new Handle:gTimer[MAXPLAYERS+1]; // Array to store the timer handle

new LifeStateOffset;

public Plugin:myinfo = 
{
  name = "Roll The Dice",
  author = "SumGuy14 (Aka Soccerdude)",
  description = "When RollTheDice is activated, the player who activated it will receive an award or be punished",
  version = "1.1.0",
  url = "http://sourcemod.net/"
};

public OnPluginStart()
{
  PrintToServer("----------------|   RollTheDice Loading   |----------------");
  RegConsoleCmd("say",SayCommand);
  RegConsoleCmd("say_team",SayCommand);
  // Hook events
  HookEvent("player_spawn",PlayerSpawnEvent);
  HookEvent("round_end",RoundEndEvent);
  HookEvent("round_freeze_end",RoundFreezeEndEvent);
  InitActionsVector();
  FindOffsets();
  LoadTranslationFile(); // Load translations file
  TriggersToArray(); // Transfer triggers to array for easier checking
  
  // Make cvars
  cvarWait=CreateConVar("rtd_wait","10","This cvar controls the default time the player has to wait after activating rollthedice");
  
  AutoExecConfig(); // Auto-generate a config file
  
  // Make a public cvar that holds version info
  CreateConVar("rollthedice_version","1.1.0","<Dice Dealer> Current version of this plugin",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED| FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
  PrintToServer("----------------|   RollTheDice Loaded    |----------------");
}

public OnConfigsExecuted()
{
  TriggersToArray();
  ActionsToVector();
}

public OnMapStart()
{
  ClearActionsVector();
}

public FindOffsets()
{
  LifeStateOffset=FindSendPropOffs("CAI_BaseNPC","m_lifeState");
  if(LifeStateOffset==-1)
    SetFailState("<Dice Dealer> Failed to find the LifeState offset, aborting");
}

public LoadTranslationFile()
{
  if(FileExists("addons/sourcemod/translations/rollthedice.phrases.txt"))
    LoadTranslations("rollthedice.phrases");
  else
    SetFailState("<Dice Dealer> Failed to load \"translations/rollthedice.phrases.txt\", aborting");
}

public TriggersToArray()
{
  // Empty out the array
  for(new x=0;x<MAX_TRIGGERS;x++)
    gChatTriggers[x]="";
  // Loop through all lines and add phrase to array
  new String:path[PLATFORM_MAX_PATH],String:line[64];
  BuildPath(Path_SM,path,sizeof(path),"configs/rollthedice/triggers.txt");
  new Handle:file=OpenFile(path,"r");
  if(file==INVALID_HANDLE)
    SetFailState("<Dice Dealer> Error: Failed to load \"configs/rollthedice/triggers.txt\", aborting");
  new index=0;
  while(index<MAX_TRIGGERS)
  {
    if(!IsEndOfFile(file)&&ReadFileLine(file,line,sizeof(line)))
    {
      if(StrContains(line,";")==-1)
      {
        TrimString(line);
        gChatTriggers[index]=line;
        index++;
      }
    }
    else
      break;
  }
  CloseHandle(file);
  return true;
}

public InitActionsVector()
{
  // Create vector
  vecActions=SHVectorCreate(TYPE_CELL);
  if(vecActions==INVALID_HANDLE)
    SetFailState("<Dice Dealer> Failed to create vector to store action information");
}

public ActionsToVector()
{
  // Add actions to vector
  new String:path[PLATFORM_MAX_PATH],String:line[128],String:info[16],String:value[128];
  BuildPath(Path_SM,path,sizeof(path),"configs/rollthedice/actions.ini");
  new Handle:fileActions=OpenFile(path,"r");
  if(fileActions==INVALID_HANDLE)
    SetFailState("<Dice Dealer> Error: Failed to load \"configs/rollthedice/actions.ini\", aborting");
  new actionid=-1;
  while(!IsEndOfFile(fileActions)&&ReadFileLine(fileActions,line,sizeof(line)))
  {
    if(StrContains(line,"//")==-1&&StrContains(line,";")==-1)
    {
      if(StrContains(line,"[")>-1&&StrContains(line,"]")>-1)
      {
        if(actionid>=0)
          VerifyAction(actionid);
        TrimString(line);
        ReplaceString(line,sizeof(line),"[","");
        ReplaceString(line,sizeof(line),"]","");
        actionid=InsertActionIntoVector(line);
      }
      else if(StrContains(line,"=")>-1)
      {
        new breakpoint=SplitString(line,"=",info,sizeof(info));
        strcopy(value,sizeof(value),line[breakpoint+1]);
        TrimString(info);
        TrimString(value);
        if(StrEqual(info,"enable"))
        {
          if(StringToInt(value))
            EnableAction(actionid,true);
          else
            EnableAction(actionid,false);
        }
        else if(StrEqual(info,"cmd"))
          SetActionCmd(actionid,value);
        else if(StrEqual(info,"delay"))
          SetActionDelay(actionid,value);
        else
        {
          decl String:name[32];
          GetActionName(actionid,name,sizeof(name));
          PrintToServer("<Dice Dealer> Invalid setting specified \"%s\" for action \"%s\"",info,name);
        }
      }
    }
  }
  VerifyAction(actionid);
  CloseHandle(fileActions);
}

public ClearActionsVector()
{
  // Clear all the vectors contained in this vector, then clear this vector
  new size=SHVectorSize_Cell(vecActions);
  for(new x=0;x<size;x++)
  {
    new Handle:vecAction=SHVectorAt_Cell(vecActions,x);
    SHVectorFree_Cell(vecAction);
  }
  SHVectorClear_Cell(vecActions);
}

public InsertActionIntoVector(String:action[])
{
  new Handle:vecAction=SHVectorCreate(TYPE_STRING);
  SHVectorInsert_String(vecAction,ITER_BACK,action);
  SHVectorInsert_String(vecAction,ITER_BACK,"");
  SHVectorInsert_String(vecAction,ITER_BACK,"");
  SHVectorInsert_String(vecAction,ITER_BACK,"");
  SHVectorInsert_Cell(vecActions,ITER_BACK,vecAction);
  return SHVectorSize_Cell(vecActions)-1;
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
  new index=GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index
  if(IsValidHandle(gTimer[index]))
    CloseHandle(gTimer[index]);
  gTimeLeft[index]=0;
}

public RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
  bRoundStarted=false;
}

public RoundFreezeEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
  bRoundStarted=true;
}

public Action:SayCommand(index,argc)
{
  decl String:args[192],String:command[192];
  GetCmdArgString(args,192);
  GetLiteralString(args,command,192);
  new bool:match=false;
  for(new x=0;x<MAX_TRIGGERS&&!match;x++)
  {
    if(gChatTriggers[x][0]&&StrEqual(command,gChatTriggers[x]))
      match=true;
  }
  if(match)
  {
    if(index==0)
    {
      PrintToServer("<Dice Dealer> Only players can use rollthedice");
      return Plugin_Handled;
    }
    if(bRoundStarted)
    {
      if(IsClientAlive(index))
      {
        if(gTimeLeft[index]==0)
          RollTheDice(index);
        else
        {
          DealerMessage(index,"Gambled recently",index,gTimeLeft[index]); // Tell client how much more time they have to wait
          return Plugin_Handled;
        }
      }
      else
      {
        DealerMessage(index,"Can not gamble when dead",index); // Print error to client
        return Plugin_Handled;
      }
    }
    else
    {
      DealerMessage(index,"Can not gamble when round is over",index); // Print error to client
      return Plugin_Handled;
    }
  }
  return Plugin_Continue;
}

public RollTheDice(client)
{
  // Pick random action id
  new actionid=-1;
  while(!IsActionEnabled(actionid))
    actionid=GetRandomInt(0,SHVectorSize_Cell(vecActions)-1);
    
  // Message the client
  decl String:name[32];
  GetActionName(actionid,name,sizeof(name)); // Get the name of the action
  DealerMessage(client,name,client); // Print text to client
  
  // Execute command
  decl String:cmd[128],String:sUserId[4];
  GetActionCmd(actionid,cmd,sizeof(cmd));
  new userid=GetClientUserId(client);
  Format(sUserId,sizeof(sUserId),"#%d",userid);
  ReplaceString(cmd,sizeof(cmd),"<user>",sUserId);
  ServerCommand(cmd);
  
  // Start timer to allow rolling again
  gTimeLeft[client]=GetActionDelay(actionid);
  gTimer[client]=CreateTimer(1.0,CountDown,client,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE); // Store handle to array
}

public Action:CountDown(Handle:timer,any:index)
{
  gTimeLeft[index]--;
  if(gTimeLeft[index]<=0)
  {
    CloseHandle(timer);
    gTimeLeft[index]=0;
    gTimer[index]=INVALID_HANDLE;
  }
}

public GetActionName(actionid,String:name[],maxlen)
{
  if(actionid>-1)
  {
    new Handle:vecAction=SHVectorAt_Cell(vecActions,actionid);
    SHVectorAt_String(vecAction,VECTOR_ACTIONS_NAME,name,maxlen);
  }
}

public EnableAction(actionid,bool:enable)
{
  if(actionid>-1)
  {
    new Handle:vecAction=SHVectorAt_Cell(vecActions,actionid);
    if(enable)
      SHVectorSetAt_String(vecAction,VECTOR_ACTIONS_ENABLE,"1");
    else
      SHVectorSetAt_String(vecAction,VECTOR_ACTIONS_ENABLE,"0");
  }
}

public bool:IsActionEnabled(actionid)
{
  if(actionid>-1)
  {
    decl String:enable[4];
    new Handle:vecAction=SHVectorAt_Cell(vecActions,actionid);
    SHVectorAt_String(vecAction,VECTOR_ACTIONS_ENABLE,enable,sizeof(enable));
    return bool:StringToInt(enable);
  }
  return false;
}

public SetActionCmd(actionid,String:cmd[])
{
  if(actionid>-1)
  {
    new Handle:vecAction=SHVectorAt_Cell(vecActions,actionid);
    SHVectorSetAt_String(vecAction,VECTOR_ACTIONS_CMD,cmd);
  }
}

public GetActionCmd(actionid,String:cmd[],maxlen)
{
  if(actionid>-1)
  {
    new Handle:vecAction=SHVectorAt_Cell(vecActions,actionid);
    SHVectorAt_String(vecAction,VECTOR_ACTIONS_CMD,cmd,maxlen);
  }
}

public SetActionDelay(actionid,String:delay[])
{
  if(actionid>-1)
  {
    new Handle:vecAction=SHVectorAt_Cell(vecActions,actionid);
    SHVectorSetAt_String(vecAction,VECTOR_ACTIONS_DELAY,delay);
  }
}

public GetActionDelay(actionid)
{
  if(actionid>-1)
  {
    decl String:delay[16];
    new Handle:vecAction=SHVectorAt_Cell(vecActions,actionid);
    SHVectorAt_String(vecAction,VECTOR_ACTIONS_DELAY,delay,sizeof(delay));
    if(StrEqual(delay,"default"))
      return GetConVarInt(cvarWait);
    return StringToInt(delay);
  }
  return 0;
}

public VerifyAction(actionid)
{
  if(actionid<SHVectorSize_Cell(vecActions))
  {
    new Handle:vecAction=SHVectorAt_Cell(vecActions,actionid);
    decl String:name[32],String:enable[4],String:cmd[4],String:delay[4];
    
    SHVectorAt_String(vecAction,VECTOR_ACTIONS_NAME,name,sizeof(name));
    SHVectorAt_String(vecAction,VECTOR_ACTIONS_ENABLE,enable,sizeof(enable));
    SHVectorAt_String(vecAction,VECTOR_ACTIONS_CMD,cmd,sizeof(cmd));
    SHVectorAt_String(vecAction,VECTOR_ACTIONS_DELAY,delay,sizeof(delay));
  
    if(!enable[0])
      PrintToServer("<Dice Dealer> WARNING: Missing \"enable\" information for action \"%s\", open \"configs/rollthedice/actions.ini\" to edit",name);
    if(!cmd[0])
      PrintToServer("<Dice Dealer> WARNING: Missing \"cmd\" information for action \"%s\", open \"configs/rollthedice/actions.ini\" to edit",name);
    if(!delay[0])
      PrintToServer("<Dice Dealer> WARNING: Missing \"delay\" information for action \"%s\", open \"configs/rollthedice/actions.ini\" to edit",name);
    if(enable[0]&&cmd[0]&&delay[0])
      if(IsActionEnabled(actionid))
        PrintToServer("<Dice Dealer> Successfully loaded action \"%s\"",name);
      else
        PrintToServer("<Dice Dealer> Successfully loaded action \"%s\" (disabled)",name);
    else
    {
      SHVectorErase_String(vecActions,actionid);
      PrintToServer("<Dice Dealer> Failed to load action \"%s\"",name);
    }
  }
}

public IsClientAlive(client)
{
  return bool:!GetEntData(client,LifeStateOffset,1);
}

stock DealerMessage(client,any:...)
{
  if(client)
  {
    decl String:translation[192],String:buffer[192];
    VFormat(buffer,sizeof(buffer),"%T",2);
    Format(translation,sizeof(translation),"%c<%t> %c%s",COLOR_GREEN,"Dice Dealer",COLOR_DEFAULT,buffer);
    ReplaceString(translation,sizeof(translation),"#default","\x01");
    ReplaceString(translation,sizeof(translation),"#lightgreen","\x03");
    ReplaceString(translation,sizeof(translation),"#green","\x04");
    PrintToChat(client,translation);
  }
}

stock GetLiteralString(const String:cmd[],String:buffer[],maxlength)
{
  strcopy(buffer,strlen(cmd)+1,cmd);
  ReplaceString(buffer,maxlength,"\"","");
  TrimString(buffer);
}