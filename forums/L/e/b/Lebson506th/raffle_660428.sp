/* Donate
* Author: Soccerdude
* Description: Players donate any amount of money they have and at the end of the round a winner is picked to receive the donated cash
*/
#include <sourcemod>

#pragma semicolon 1

// Define maxplayers
#define MAX_PLAYERS 64
 
// Define number of rounds to play before picking winner
#define PLAY_ROUNDS 3
 
// Make array to store data
new raffleAmount[MAX_PLAYERS+1];
 
// Colors
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04 // DOD = Red
 
// Define global variables
new bool:raffleActive=false;
new rounds=0;
new potamount=0;

// Define how many options there are in the menu
#define DONATEMENU_OPTIONS 10

// Create array for menu options
new donateOptions[DONATEMENU_OPTIONS]={500,1000,2000,3000,5000,7500,10000,12000,14000,16000};
 
// Offsets
 
new MoneyOffset;
 
public Plugin:myinfo = 
{
  name = "Raffle",
  author = "Soccerdude",
  description = "Players donate money to a pot that will be raffled off later",
  version = "1.0.1",
  url = "http://sourcemod.net/"
};

public OnPluginStart()
{
  // Hook Events
  HookEvent("round_start",RoundStartEvent);
  // Hook text
  RegConsoleCmd("say",SayCommand);
  RegConsoleCmd("say_team",SayCommand);
  PrintToServer("[Raffle] Loaded");
  // Find money offset
  MoneyOffset=FindSendPropOffs("CCSPlayer","m_iAccount");
  if(MoneyOffset==-1)
    SetFailState("Failed to find CCSPlayer::m_iAccount offset");
}
 
// Events

public OnClientPutInServer(index)
{
  raffleAmount[index]=0;
}

public OnClientDisconnect(index)
{
  raffleAmount[index]=0;
}
 
public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
  if(raffleActive)
  {
    rounds+=1;
    if(rounds>=PLAY_ROUNDS)
    {
      // Pick a winner
      decl String:winnername[64];
      new index;
      new odds;
      new pass=0;
      while(pass!=1)
      {
        index=GetPossibleWinner();
        odds=GetOddsOfLosing(index);
        pass=GetRandomInt(1,odds);
      }
      // Get winner's name
      GetClientName(index,winnername,63);
      PrintToChatAll("%c[Raffle] %cThe winner of the %c$%d %cpot is... %c%s%c!",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,potamount,COLOR_DEFAULT,COLOR_GREEN,winnername,COLOR_DEFAULT);
      // Give winner money
      new playermoney=GetEntData(index,MoneyOffset,4);
      playermoney+=potamount;
      if(playermoney>16000) playermoney=16000;
      SetEntData(index,MoneyOffset,playermoney,4,true);
      // Make pot inactive
      raffleActive=false;
      // Reset rounds
      rounds=0;
      // Empty pot
      potamount=0;
      // Clear player data
      new maxplayers=GetMaxClients();
      for(new c=1;c<=maxplayers;c++)
        raffleAmount[c]=0;
    }
    else
    {
      // Broadcast menu to players who haven't donated
      new maxplayers=GetMaxClients();
      for(new index=1;index<=maxplayers;index++)
      {
        if(raffleAmount[index]==0)
          DonateMenu(index);
      }
      PrintToChatAll("%c[Raffle] Raffle Mode %cis active, please make your donations now %c[Pot Size: $%c%d%c] %c- %c[Rounds Played: %c%d/%d%c]%c",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,potamount,COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,rounds,PLAY_ROUNDS,COLOR_GREEN,COLOR_DEFAULT);
    }
  }
  else
  {
    // 5 second delay to announce donate
    CreateTimer(5.0,Announce);
  }
}
 
public Action:Announce(Handle:timer)
{
  PrintToChatAll("%c[Raffle] %cType %cdonate [cash/all] %cin chat to donate cash to the pot that will be raffled off later",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
}
 
public Action:SayCommand(index,argc)
{
  if(argc>0)
  {
    // Declare string arrays
    decl String:command[8];
    decl String:amount[7];
    decl String:args[192];
    decl String:litstring[192];
    GetCmdArgString(args,191);
    GetLiteralString(args,litstring,192);
    amount="";
    StrToken(litstring,1,command,7);
    if(StrEqual(command,"donate",false))
    {
      if(index==0)
        PrintToServer("You can't donate.");
      else
      {
        StrToken(litstring,2,amount,7);
        // Check if they typed "donate" or "donate <something>"
        if(!StrEqual(amount,"",false))
        {
          if(StrEqual(amount,"all",false))
            ReplaceString(amount,32,"all","16000");
          // Convert to an integer
          new cash=StringToInt(amount);
          new pass=Donate(index,cash);
          if(!pass)
            return Plugin_Handled;
        }
        else
          DonateMenu(index);
      }
    }
  }
  return Plugin_Continue;
}

public Donate(client,money)
{
  if(money>0)
  {
    // Check player's money
    new playermoney=GetEntData(client,MoneyOffset,4);
    if(playermoney>0)
    {
      if(money>playermoney)
        money=playermoney;
      // Get player's name
      decl String:name[64];
      GetClientName(client,name,63);
      // Add to pot
      potamount+=money;
      // Take from player
      playermoney-=money;
      SetEntData(client,MoneyOffset,playermoney,4,true);
      // Announce donation
      PrintToChatAll("%c[Raffle] %c%s has donated %c$%d %cto the raffle %c[Pot Size: $%c%d%c]%c",COLOR_GREEN,COLOR_DEFAULT,name,COLOR_GREEN,money,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,potamount,COLOR_GREEN,COLOR_DEFAULT);
      // Add to player's total amount donated
      raffleAmount[client]+=money;
      // Activate donation pot
      if(!raffleActive)
      {
        new donaters=0;
        new maxplayers=GetMaxClients();
        for(new index=1;index<=maxplayers;index++)
        {
          if(raffleAmount[index]>0)
            donaters+=1;
        }
        if(donaters>=2)
        {
          // Broadcast menu
          for(new index=1;index<=maxplayers;index++)
          {
            if(raffleAmount[index]==0)
              DonateMenu(index);
          }
          PrintToChatAll("%c[Raffle] %cThe %craffle %chas been activated, please make your donations",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
          raffleActive=true;
        }
      }
      return 1;
    }
    else
    {
      PrintToChat(client,"%c[Raffle] %cYou don't have any money!",COLOR_GREEN,COLOR_DEFAULT);
      return 0;
    }
  }
  else
  {
    PrintToChat(client,"%c[Raffle] %cSyntax: %cdonate [cash/all]%c",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
    return 0;
  }
}

public GetOddsOfLosing(client)
{
  return RoundToNearest(100.0-100.0*(float(raffleAmount[client])/float(potamount)));
}
 
public GetPossibleWinner()
{
  // Choose the winner
  new client=0;
  new maxclients=GetMaxClients();
  while(!raffleAmount[client])
    client=GetRandomInt(1,maxclients);
  return client;
}

public DonateMenu(client)
{
  decl String:disp_buffer[128];
  decl String:string_buffer[128];
  new Handle:menu=CreateMenu(DonateHandler);
  SetMenuTitle(menu,"Please make a donation:\n ");
  for(new option=0;option<DONATEMENU_OPTIONS;option++)
  {
    Format(disp_buffer,127,"$%d",donateOptions[option]);
    IntToString(donateOptions[option],string_buffer,127);
    AddMenuItem(menu,string_buffer,disp_buffer);
  }
  DisplayMenu(menu,client,20);
}

public DonateHandler(Handle:menu,MenuAction:action,client,slot)
{
	if(action==MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu,slot,info,31);
		new icash=StringToInt(info);
		Donate(client,icash);
	}
	if(action==MenuAction_End)
		CloseHandle(menu);
}

stock StrToken(const String:inputstr[],tokennum,String:outputstr[],maxlen)
{
  new String:buf[32];
  new cur_idx;
  new idx;
  new curind;
  idx=BreakString(inputstr,buf,maxlen);
  if(tokennum==1)
  {
    strcopy(outputstr,maxlen,buf);
    return;
  }
  curind=1;
  while (idx!=-1)
  {
    cur_idx+=idx;
    idx=BreakString(inputstr[cur_idx],buf,maxlen);
    curind++;
    if(tokennum==curind)
    {
      strcopy(outputstr,maxlen,buf);
      break;
    }
  }
}
 
stock GetLiteralString(const String:cmd[],String:buffer[],maxlength)
{
  strcopy(buffer,strlen(cmd)+1,cmd);
  ReplaceString(buffer,maxlength,"\"","");
}