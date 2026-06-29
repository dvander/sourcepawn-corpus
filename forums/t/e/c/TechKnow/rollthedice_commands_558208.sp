/* 
* File: rollthedice.sp
* Author: SumGuy14 (Aka SoccerDude)
* Description: Players type "rollthedice" or "rtd" to either receive an award, or be punished
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define COLOR_DEFAULT 0x01
#define COLOR_GREEN 0x04

#define MAX_TIMERS 8

#define TIMER_TIMELEFT 0
#define TIMER_GODMODE 1
#define TIMER_ALPHA 2
#define TIMER_SPEED 3
#define TIMER_SLAPDISEASE 4
#define TIMER_GRAVITY 5
#define TIMER_JETPACK 6
#define TIMER_TIMEBOMB 7

new Handle:gTimers[MAXPLAYERS+1][MAX_TIMERS]; // Array to store timer handles

// TimeLeft array
new gTimeLeft[MAXPLAYERS+1];
new String:gTimeLeftText[MAXPLAYERS+1][64];
new String:gTimeLeftEndText[MAXPLAYERS+1][64];
new bool:gTimeLeftToServer[MAXPLAYERS+1];

// GodMode array
new gGodMode[MAXPLAYERS+1];

// Alpha array
new gAlpha[MAXPLAYERS+1];

// Speed array
new Float:gSpeed[MAXPLAYERS+1];

// SlapDisease array
new gSlapDisease[MAXPLAYERS+1];

// Gravity array
new Float:gGravity[MAXPLAYERS+1];

// Jetpack array
new gJetpack[MAXPLAYERS+1];

// TimeBomb arrays
new Float:gTimeBombRadius[MAXPLAYERS+1];

new MoneyOffset;
new ColorOffset;
new RenderModeOffset;
new SpeedOffset;
new BaseVelocityOffset;
new MoveTypeOffset;
new LifeStateOffset;

new Handle:hGameConf;
new Handle:hRemoveItems;

public Plugin:myinfo = 
{
  name = "RollTheDice:Commands",
  author = "SumGuy14 (Aka Soccerdude)",
  description = "Creates console commands for RollTheDice to use as actions",
  version = "1.1.0",
  url = "http://sourcemod.net/"
};

enum RTDTimers
{
  All, /** All sub commands */
  TimeLeft, /** The timer that tracks how much time they have left of a prize */
  GodMode, /** GodMode sub command */
  Alpha, /** Alpha sub command */
  Speed, /** Speed sub command */
  SlapDisease, /** SlapDisease sub command */
  Gravity, /** Gravity sub command */
  Jetpack, /** Jetpack sub command */
  TimeBomb, /** TimeBomb sub command */
};

public OnPluginStart()
{
  // Create main reward/punishment command
  RegAdminCmd("rtd",Cmd_RTD,ADMFLAG_GENERIC,"rtd <subcommand> <player> [parameters]");
  
  // Hook events
  HookEvent("player_spawn",PlayerSpawnEvent);
  HookEvent("player_death",PlayerDeathEvent);
  
  LoadTranslationFile();
  FindOffsets(); // Find offsets
  FindVirtualFunctions(); // Find vfunc offsets
}

public OnConfigsExecuted()
{
  // Precache sounds
  PrecacheSound("ambient/explosions/explode_7.wav");
}

public LoadTranslationFile()
{
  if(FileExists("addons/sourcemod/translations/rollthedice.phrases.txt"))
    LoadTranslations("rollthedice.phrases");
}

public FindOffsets()
{
  MoneyOffset=FindSendPropOffs("CCSPlayer", "m_iAccount");
  if(MoneyOffset==-1)
    SetFailState("[RollTheDice:Commands] Error: Failed to find the Money offset, aborting");
  ColorOffset=FindSendPropOffs("CAI_BaseNPC","m_clrRender");
  if(ColorOffset==-1)
    SetFailState("[RollTheDice:Commands] Error: Failed to find the Color offset, aborting");
  RenderModeOffset=FindSendPropOffs("CBaseAnimating","m_nRenderMode");
  if(RenderModeOffset==-1)
    SetFailState("[RollTheDice:Commands] Error: Failed to find the RenderMode offset, aborting");
  SpeedOffset=FindSendPropOffs("CBasePlayer","m_flLaggedMovementValue");
  if(SpeedOffset==-1)
    SetFailState("[RollTheDice:Commands] Error: Failed to find the Speed offset, aborting");
  BaseVelocityOffset=FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
  if(BaseVelocityOffset==-1)
    SetFailState("[RollTheDice:Commands] Error: Failed to find the BaseVelocity offset, aborting");
  MoveTypeOffset=FindSendPropOffs("CAI_BaseNPC","movetype");
  if(MoveTypeOffset==-1)
    SetFailState("[RollTheDice:Commands] Error: Failed to find the MoveType offset, aborting");
  LifeStateOffset=FindSendPropOffs("CAI_BaseNPC","m_lifeState");
  if(LifeStateOffset==-1)
    SetFailState("[RollTheDice:Commands] Error: Failed to find the LifeState offset, aborting");
}

public FindVirtualFunctions()
{
  hGameConf=LoadGameConfigFile("plugin.rollthedice");
  
  StartPrepSDKCall(SDKCall_Player);
  PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"RemoveAllItems");
  PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
  hRemoveItems=EndPrepSDKCall();
}

public OnClientPutInServer(client)
{
  ResetPlayerInfo(client);
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
  new index=GetClientOfUserId(GetEventInt(event,"userid")); // Get the users index
  
  StopTimer(index,All); // Stop all timers
  
  ReturnToDefault(index,All); // Return the client to default status (if anything was changed)
  FindDefaultValue(index,All); // Store the defaults for the client
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
  StopTimer(GetClientOfUserId(GetEventInt(event,"userid")),All);
}

public Action:Cmd_RTD(client,argc)
{
  if(argc>0)
  {
    // Retrieve supplied arguments
    decl String:arg1[16],String:arg2[16],String:arg3[16],String:arg4[16];
    GetCmdArg(1,arg1,sizeof(arg1));
    GetCmdArg(2,arg2,sizeof(arg2));
    GetCmdArg(3,arg3,sizeof(arg3));
    GetCmdArg(4,arg4,sizeof(arg4));
    new clients[MAXPLAYERS];
    new total=FindMatchingPlayers(arg2,clients);
    if(!total)
      ReplyToCommand(client,"[RTD] Error: No targets found");
    for(new x=0;x<total;x++)
    {
      if(!IsClientAlive(clients[x]))
      {
        ReplyToCommand(client,"[RTD] Error: Player must be alive");
        return Plugin_Handled;
      }
      if(StrEqual(arg1,"godmode"))
        GodModeTimed(clients[x],StringToFloat(arg3));
      else if(StrEqual(arg1,"slay"))
        SlayCmd(clients[x]);
      else if(StrEqual(arg1,"health"))
        HealthCmd(clients[x],arg3,StringToInt(arg4));
      else if(StrEqual(arg1,"cash"))
        CashCmd(clients[x],arg3,StringToInt(arg4));
      else if(StrEqual(arg1,"alpha"))
        AlphaTimed(clients[x],StringToInt(arg3),StringToFloat(arg4));
      else if(StrEqual(arg1,"disarm"))
        DisarmCmd(clients[x]);
      else if(StrEqual(arg1,"burn"))
        BurnCmd(clients[x],StringToFloat(arg3));
      else if(StrEqual(arg1,"speed"))
        SpeedTimed(clients[x],StringToFloat(arg3),StringToFloat(arg4));
      else if(StrEqual(arg1,"slapdisease"))
        SlapDiseaseTimed(clients[x],StringToFloat(arg3),StringToInt(arg4));
      else if(StrEqual(arg1,"gravity"))
        GravityTimed(clients[x],StringToFloat(arg3),StringToFloat(arg4));
      else if(StrEqual(arg1,"jetpack"))
        JetpackTimed(clients[x],StringToFloat(arg3));
      else if(StrEqual(arg1,"timebomb"))
        TimeBombTimed(clients[x],StringToFloat(arg3),StringToFloat(arg4));
      else
      {
        ReplyToCommand(client,"[RTD] Error: Invalid subcommand, current valid subcommands are:\n - godmode <userid> <time>\n - health <userid> <operator> <health>\n - cash <userid> <operator> <cash>\n - alpha <userid> <alpha> <time>\n - disarm <userid>\n - speed <userid> <speed> <time>\n - slapdisease <userid> <duration> <slaps>\n - gravity <userid> <gravity multiplier> <time>\n - jetpack <userid> <time>\n - timebomb <userid> <time>");
        return Plugin_Handled;
      }
    }
  }
  else
    ReplyToCommand(client,"[RTD] Error: No subcommand provided, current valid subcommands are:\n - godmode <userid> <time>\n - health <userid> <operator> <health>\n - cash <userid> <operator> <cash>\n - alpha <userid> <alpha> <time>\n - disarm <userid>\n - speed <userid> <speed> <time>\n - slapdisease <userid> <duration> <slaps>\n - gravity <userid> <gravity multiplier> <time>\n - jetpack <userid> <time>\n - timebomb <userid> <time>");
  return Plugin_Handled;
}

public GodModeTimed(client,Float:time)
{
  if(!IsActionActiveForClient(client,GodMode))
    FindDefaultValue(client,GodMode);
  StopTimer(client,GodMode); // Stop timer if player already has godmode
  GodModeCmd(client,false);
  gTimers[client][TIMER_GODMODE]=CreateTimer(time,GodMode_Done,client);
  
  // Start countdown with certain phrase
  decl String:countdowntext[64],String:countdownendtext[64];
  GetCountDownPhrase(GodMode,countdowntext,sizeof(countdowntext),countdownendtext,sizeof(countdownendtext),"");
  TimeLeftStart(client,time,1.0,countdowntext,countdownendtext,false);
}

public Action:GodMode_Done(Handle:timer,any:index)
{
  if(IsClientInGame(index))
    ReturnToDefault(index,GodMode);
  StopTimer(index,GodMode);
}

public AlphaTimed(client,alpha,Float:time)
{
  if(!IsActionActiveForClient(client,Alpha))
    FindDefaultValue(client,Alpha);
  StopTimer(client,Alpha); // Stop timer if player already has alpha
  AlphaCmd(client,alpha);
  gTimers[client][TIMER_ALPHA]=CreateTimer(time,Alpha_Done,client);
  
  // Start countdown with certain phrase
  decl String:countdowntext[64],String:countdownendtext[64];
  GetCountDownPhrase(Alpha,countdowntext,sizeof(countdowntext),countdownendtext,sizeof(countdownendtext),"");
  TimeLeftStart(client,time,1.0,countdowntext,countdownendtext,false);
}

public Action:Alpha_Done(Handle:timer,any:index)
{
  if(IsClientInGame(index))
    ReturnToDefault(index,Alpha);
  StopTimer(index,Alpha);
}

public SpeedTimed(client,Float:speed,Float:time)
{
  if(!IsActionActiveForClient(client,Speed))
    FindDefaultValue(client,Speed);
  StopTimer(client,Alpha); // Stop timer if player already has speed
  SpeedCmd(client,speed);
  gTimers[client][TIMER_SPEED]=CreateTimer(time,Speed_Done,client);
  
  // Start countdown with certain phrase
  decl String:countdowntext[64],String:countdownendtext[64];
  GetCountDownPhrase(Speed,countdowntext,sizeof(countdowntext),countdownendtext,sizeof(countdownendtext),"");
  TimeLeftStart(client,time,1.0,countdowntext,countdownendtext,false);
}

public Action:Speed_Done(Handle:timer,any:index)
{
  if(IsClientInGame(index))
    ReturnToDefault(index,Speed);
  StopTimer(index,Speed);
}

public SlapDiseaseTimed(client,Float:duration,slapcount)
{
  StopTimer(client,SlapDisease); // Stop timer if player already has the slap disease
  gSlapDisease[client]=slapcount;
  gTimers[client][TIMER_SLAPDISEASE]=CreateTimer(duration,SlapDisease_Slap,client,TIMER_REPEAT);
  
  // Start countdown with certain phrase
  decl String:countdowntext[64],String:countdownendtext[64];
  GetCountDownPhrase(SlapDisease,countdowntext,sizeof(countdowntext),countdownendtext,sizeof(countdownendtext),"");
  TimeLeftStart(client,float(slapcount),duration,countdowntext,countdownendtext,false);
}

public Action:SlapDisease_Slap(Handle:timer,any:index)
{
  // Slap player
  new randhp=GetRandomInt(1,5);
  SlapPlayer(index,randhp);
  
  // Greenish fade
  new red=GetRandomInt(0,50);
  new green=GetRandomInt(200,255);
  new blue=GetRandomInt(0,50);
  new alpha=GetRandomInt(150,255);
  new color[4];
  color[0]=red;
  color[1]=green;
  color[2]=blue;
  color[3]=alpha;
  FadeCmd(index,1,200,50,color);
  gSlapDisease[index]--;
  if(gSlapDisease[index]<=0)
    StopTimer(index,SlapDisease);
}

public GravityTimed(client,Float:gravity,Float:time)
{
  if(!IsActionActiveForClient(client,Gravity))
    FindDefaultValue(client,Gravity);
  StopTimer(client,Gravity); // Stop timer if player already has speed
  GravityCmd(client,gravity);
  gTimers[client][TIMER_GRAVITY]=CreateTimer(time,Gravity_Done,client);
  
  // Start countdown with certain phrase
  decl String:countdowntext[64],String:countdownendtext[64];
  GetCountDownPhrase(Gravity,countdowntext,sizeof(countdowntext),countdownendtext,sizeof(countdownendtext),"");
  TimeLeftStart(client,time,1.0,countdowntext,countdownendtext,false);
}

public Action:Gravity_Done(Handle:timer,any:index)
{
  if(IsClientInGame(index))
    ReturnToDefault(index,Gravity);
  StopTimer(index,Gravity);
}

public JetpackTimed(client,Float:time)
{
  if(!IsActionActiveForClient(client,Jetpack))
    FindDefaultValue(client,Jetpack);
  StopTimer(client,Jetpack); // Stop timer if player already has speed
  MoveTypeCmd(client,4);
  gTimers[client][TIMER_JETPACK]=CreateTimer(time,Jetpack_Done,client);
  
  // Start countdown with certain phrase
  decl String:countdowntext[64],String:countdownendtext[64];
  GetCountDownPhrase(Jetpack,countdowntext,sizeof(countdowntext),countdownendtext,sizeof(countdownendtext),"");
  TimeLeftStart(client,time,1.0,countdowntext,countdownendtext,false);
}

public Action:Jetpack_Done(Handle:timer,any:index)
{
  if(IsClientInGame(index))
    ReturnToDefault(index,Jetpack);
  StopTimer(index,Jetpack);
}

public TimeBombTimed(client,Float:time,Float:radius)
{
  StopTimer(client,TimeBomb); // Stop timer if player is already a timebomb
  gTimers[client][TIMER_TIMEBOMB]=CreateTimer(time,TimeBomb_Done,client);
  gTimeBombRadius[client]=radius;
  
  // Get player's name
  decl String:name[32];
  GetClientName(client,name,sizeof(name));
  
  // Tell server player is a timebomb
  new maxplayers=GetMaxClients();
  for(new x=1;x<=maxplayers;x++)
    if(IsClientInGame(x))
      PrintToChat(x,"%c<%t> %c%t",COLOR_GREEN,"Dice Dealer",COLOR_DEFAULT,"timebomb_all",name);
  
  // Start countdown with certain phrase
  decl String:countdowntext[64],String:countdownendtext[64];
  GetCountDownPhrase(TimeBomb,countdowntext,sizeof(countdowntext),countdownendtext,sizeof(countdownendtext),name);
  TimeLeftStart(client,time,1.0,countdowntext,countdownendtext,false);
}

public Action:TimeBomb_Done(Handle:timer,any:index)
{
  if(IsClientInGame(index),IsClientAlive(index))
  {
    // Find the client's current position
    new Float:clientloc[3],Float:victimloc[3];
    GetClientAbsOrigin(index,clientloc);
    // Play sound
    EmitSoundToAll("ambient/explosions/explode_7.wav",SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,clientloc,NULL_VECTOR,true,0.0);
    new maxplayers=GetMaxClients();
    for(new x=1;x<=maxplayers;x++)
    {
      if(IsClientInGame(x)&&IsClientAlive(x))
      {
        GetClientAbsOrigin(x,victimloc);
        if(GetDistanceBetween(clientloc,victimloc)<=gTimeBombRadius[index])
          ForcePlayerSuicide(x);
      }
    }
    StopTimer(index,TimeBomb);
  }
}

public TimeLeftStart(client,Float:time,Float:duration,const String:text[],const String:endtext[],bool:toserver)
{
  StopTimer(client,TimeLeft);
  gTimeLeft[client]=RoundToNearest(time);
  strcopy(gTimeLeftText[client],sizeof(gTimeLeftText[]),text);
  strcopy(gTimeLeftEndText[client],sizeof(gTimeLeftEndText[]),endtext);
  gTimers[client][TIMER_TIMELEFT]=CreateTimer(duration,TimeLeft_Display,client,TIMER_REPEAT);
  gTimeLeftToServer[client]=toserver;
  PrintTimeLeft(client);
}

public PrintTimeLeft(client)
{
  if(gTimeLeft[client]>0)
  {
    if(gTimeLeftToServer[client])
      PrintCenterTextAll("%s: %d",gTimeLeftText[client],gTimeLeft[client]);
    else
      PrintCenterText(client,"%s: %d",gTimeLeftText[client],gTimeLeft[client]);
  }
  else if(gTimeLeft[client]==0)
  {
    if(gTimeLeftToServer[client])
      PrintCenterTextAll("%s",gTimeLeftEndText[client]);
    else
      PrintCenterText(client,"%s",gTimeLeftEndText[client]);
  }
}

public Action:TimeLeft_Display(Handle:timer,any:index)
{
  gTimeLeft[index]--;
  if(gTimeLeft[index]<0)
    StopTimer(index,TimeLeft);
  else
    PrintTimeLeft(index);
}

GodModeCmd(client,bool:normal)
{
  if(normal)
    SetEntProp(client,Prop_Data,"m_takedamage",2,1); // Take godmode
  else
    SetEntProp(client,Prop_Data,"m_takedamage",0,1); // Give godmode
}

SlayCmd(client)
{
  if(client&&IsClientAlive(client))
    ForcePlayerSuicide(client);
}

HealthCmd(client,const String:operation[],amount)
{
  if(client&&IsClientAlive(client))
  {
    new newhp=GetClientHealth(client);
    if(StrEqual(operation,"="))
      newhp=amount;
    else if(StrEqual(operation,"+"))
      newhp+=amount;
    else if(StrEqual(operation,"-"))
      newhp-=amount;
    if(newhp<1)
      ForcePlayerSuicide(client);
    else
      SetEntProp(client,Prop_Send,"m_iHealth",newhp,4);
  }
}

CashCmd(client,const String:operation[],amount)
{
  if(client&&IsClientAlive(client))
  {
    new cash=GetClientHealth(client);
    if(StrEqual(operation,"="))
      cash=amount;
    else if(StrEqual(operation,"+"))
      cash+=amount;
    else if(StrEqual(operation,"-"))
      cash-=amount;
    if(amount<0) amount=0;
    if(amount>16000) amount=16000;
    SetEntData(client,MoneyOffset,amount,4,true);
  }
}

AlphaCmd(client,alpha)
{
  if(alpha>-1)
  {
    if(alpha>255) alpha=255;
    SetEntData(client,ColorOffset+3,alpha,1,true);
    SetEntData(client,RenderModeOffset,3,1,true);
  }
}

DisarmCmd(client)
{
  SDKCall(hRemoveItems,client,false);
  GivePlayerItem(client,"weapon_knife");
}

BurnCmd(client,Float:time)
{
  IgniteEntity(client,time);
}

SpeedCmd(client,Float:speed)
{
  if(speed>-1.0)
    SetEntDataFloat(client,SpeedOffset,speed,true);
}

GravityCmd(client,Float:gravity)
{
  if(gravity>-1.0)
    SetEntPropFloat(client,Prop_Data,"m_flGravity",gravity);
}

MoveTypeCmd(client,type)
{
  SetEntData(client,MoveTypeOffset,type,1,true);
}

FadeCmd(client,type,time,duration,const color[4])
{
  if(client)
  {
    new Handle:hBf=StartMessageOne("Fade",client);
    if(hBf!=INVALID_HANDLE)
    {
      BfWriteShort(hBf,duration);
      BfWriteShort(hBf,time);
      BfWriteShort(hBf,type);
      BfWriteByte(hBf,color[0]);
      BfWriteByte(hBf,color[1]);
      BfWriteByte(hBf,color[2]);
      BfWriteByte(hBf,color[3]);
      EndMessage();
    }
  }
}

/** Helpers */

public bool:IsClientAlive(client)
{
  return bool:!GetEntData(client,LifeStateOffset,1);
}

public Float:GetDistanceBetween(Float:startvec[3],Float:endvec[3])
{
  return SquareRoot((startvec[0]-endvec[0])*(startvec[0]-endvec[0])+(startvec[1]-endvec[1])*(startvec[1]-endvec[1])+(startvec[2]-endvec[2])*(startvec[2]-endvec[2]));
}

/** Timer actions handling */

public FindDefaultValue(client,RTDTimers:action)
{
  new bool:override;
  if(action==All)
    override=true;
  if(action==GodMode||override)
    gGodMode[client]=GetEntProp(client,Prop_Data,"m_takedamage");
  if(action==Alpha||override)
    gAlpha[client]=GetEntData(client,ColorOffset+3,1);
  if(action==Speed||override)
    gSpeed[client]=GetEntDataFloat(client,SpeedOffset);
  if(action==Gravity||override)
    gGravity[client]=GetEntPropFloat(client,Prop_Data,"m_flGravity");
  if(action==Jetpack||override)
    gJetpack[client]=GetEntData(client,MoveTypeOffset,1);
}

public ReturnToDefault(client,RTDTimers:action)
{
  new bool:override=false;
  if(action==All)
    override=true;
  if(action==GodMode||override&&gGodMode[client]>-1)
    GodModeCmd(client,bool:gGodMode[client]);
  if(action==Alpha||override&&gAlpha[client]>-1)
    AlphaCmd(client,gAlpha[client]);
  if(action==Speed||override&&gSpeed[client]>-1)
    SpeedCmd(client,gSpeed[client]);
  if(action==Gravity||override&&gGravity[client]>-1)
    GravityCmd(client,gGravity[client]);
  if(action==Jetpack||override&&gJetpack[client]>-1)
    MoveTypeCmd(client,gJetpack[client]);
}

public bool:IsActionActiveForClient(client,RTDTimers:action)
{
  if(action==GodMode)
  {
    if(IsValidHandle(gTimers[client][TIMER_GODMODE]))
      return true;
  }
  else if(action==Alpha)
  {
    if(IsValidHandle(gTimers[client][TIMER_ALPHA]))
      return true;
  }
  else if(action==Speed)
  {
    if(IsValidHandle(gTimers[client][TIMER_SPEED]))
      return true;
  }
  else if(action==SlapDisease)
  {
    if(IsValidHandle(gTimers[client][TIMER_SLAPDISEASE]))
      return true;
  }
  else if(action==Gravity)
  {
    if(IsValidHandle(gTimers[client][TIMER_GRAVITY]))
      return true;
  }
  else if(action==Jetpack)
  {
    if(IsValidHandle(gTimers[client][TIMER_JETPACK]))
      return true;
  }
  else if(action==TimeBomb)
  {
    if(IsValidHandle(gTimers[client][TIMER_TIMEBOMB]))
      return true;
  }
  return false;
}

public StopTimer(client,RTDTimers:action)
{
  if(action==All)
  {
    for(new x=0;x<MAX_TIMERS;x++)
      if(IsValidHandle(gTimers[client][x]))
        CloseHandle(gTimers[client][x]);
  }
  else if(action==TimeLeft)
  {
    if(IsValidHandle(gTimers[client][TIMER_TIMELEFT]))
      CloseHandle(gTimers[client][TIMER_TIMELEFT]);
  }
  else if(action==GodMode)
  {
    if(IsValidHandle(gTimers[client][TIMER_GODMODE]))
      CloseHandle(gTimers[client][TIMER_GODMODE]);
  }
  else if(action==Alpha)
  {
    if(IsValidHandle(gTimers[client][TIMER_ALPHA]))
      CloseHandle(gTimers[client][TIMER_ALPHA]);
  }
  else if(action==Speed)
  {
    if(IsValidHandle(gTimers[client][TIMER_SPEED]))
      CloseHandle(gTimers[client][TIMER_SPEED]);
  }
  else if(action==SlapDisease)
  {
    if(IsValidHandle(gTimers[client][TIMER_SLAPDISEASE]))
      CloseHandle(gTimers[client][TIMER_SLAPDISEASE]);
  }
  else if(action==Gravity)
  {
    if(IsValidHandle(gTimers[client][TIMER_GRAVITY]))
      CloseHandle(gTimers[client][TIMER_GRAVITY]);
  }
  else if(action==Jetpack)
  {
    if(IsValidHandle(gTimers[client][TIMER_JETPACK]))
      CloseHandle(gTimers[client][TIMER_JETPACK]);
  }
  else if(action==TimeBomb)
  {
    if(IsValidHandle(gTimers[client][TIMER_TIMEBOMB]))
      CloseHandle(gTimers[client][TIMER_TIMEBOMB]);
  }
}

public GetCountDownPhrase(RTDTimers:action,String:text[],textmaxlen,String:endtext[],endtextmaxlen,const String:str[])
{
  if(action==GodMode)
  {
    Format(text,textmaxlen,"%T","godmode_countdown",LANG_SERVER);
    Format(endtext,endtextmaxlen,"%T","godmode_done",LANG_SERVER);
  }
  else if(action==Alpha)
  {
    Format(text,textmaxlen,"%T","invisibility_countdown",LANG_SERVER);
    Format(endtext,endtextmaxlen,"%T","invisibility_done",LANG_SERVER);
  }
  else if(action==Speed)
  {
    Format(text,textmaxlen,"%T","speed_countdown",LANG_SERVER);
    Format(endtext,endtextmaxlen,"%T","speed_done",LANG_SERVER);
  }
  else if(action==SlapDisease)
  {
    Format(text,textmaxlen,"%T","slapdisease_countdown",LANG_SERVER);
    Format(endtext,endtextmaxlen,"%T","slapdisease_done",LANG_SERVER);
  }
  else if(action==Gravity)
  {
    Format(text,textmaxlen,"%T","gravity_countdown",LANG_SERVER);
    Format(endtext,endtextmaxlen,"%T","gravity_done",LANG_SERVER);
  }
  else if(action==Jetpack)
  {
    Format(text,textmaxlen,"%T","jetpack_countdown",LANG_SERVER);
    Format(endtext,endtextmaxlen,"%T","jetpack_done",LANG_SERVER);
  }
  else if(action==TimeBomb)
  {
    Format(text,textmaxlen,"%T","timebomb_countdown",LANG_SERVER,str);
    Format(endtext,endtextmaxlen,"%T","timebomb_done",LANG_SERVER);
  }
}

public ResetPlayerInfo(client)
{
  gGodMode[client]=-1;
  gAlpha[client]=-1;
  gSpeed[client]=-1.0;
  gGravity[client]=-1.0;
}

/** Partial Name Parser */

public FindMatchingPlayers(const String:matchstr[],clients[])
{
  new count=0;
  new maxplayers=GetMaxClients();
  if(StrEqual(matchstr,"#all",false))
  {
    for(new x=1;x<=maxplayers;x++)
    {
      if(IsClientInGame(x))
      {
        clients[count]=x;
        count++;
      }
    }
  }
  else if(StrEqual(matchstr,"#t",false))
  {
    for(new x=1;x<=maxplayers;x++)
    {
      if(IsClientInGame(x)&&GetClientTeam(x)==2)
      {
        clients[count]=x;
        count++;
      }
    }
  }
  else if(StrEqual(matchstr,"#ct",false))
  {
    for(new x=1;x<=maxplayers;x++)
    {
      if(IsClientInGame(x)&&GetClientTeam(x)==3)
      {
        clients[count]=x;
        count++;
      }
    }
  }
  else if(matchstr[0]=='#')
  {
    new userid=StringToInt(matchstr[1]);
    if(userid)
    {
      new index=GetClientOfUserId(userid);
      if(index)
      {
        if(IsClientInGame(index))
        {
          clients[count]=index;
          count++;
        }
      }
    }
  }
  else
  {
    for(new x=1;x<=maxplayers;x++)
    {
      if(IsClientInGame(x))
      {
        decl String:name[64];
        GetClientName(x,name,64);
        if(StrContains(name,matchstr,false)!=-1)
        {
          clients[count]=x;
          count++;
        }
      }
    }
  }
  return count;
}