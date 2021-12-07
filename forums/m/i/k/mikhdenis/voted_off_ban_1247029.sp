#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo =
{
   name = "Ban voted off player",
   author = "D1maxa",
   description = "banning player that been voted off",
   version = "1.2",
   url = "http://hl2.msk.su/"
};

new String:steamid[32]="";
new bool:ok;
new Handle:banDuration;
new yesVotes,noVotes;

public OnPluginStart()
{
   banDuration = CreateConVar("sm_autoban_time","5","autoban time in minutes. Use 0 for permanent");
   HookEvent("vote_started",Event_VoteStarted);   
   HookEvent("vote_cast_yes",Event_VoteYes);
   HookEvent("vote_cast_no",Event_VoteNo);
}

public Event_VoteStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
   new String:issue[64];   
   ok=false;
   GetEventString(event,"issue",issue,sizeof(issue));         
   if(StrEqual(issue,"#L4D_vote_kick_player",false))
   {
      new String:param[64];
      new String:pname[MAX_NAME_LENGTH];
      GetEventString(event,"param1",param,sizeof(param));
      for(new i=1;i<=MaxClients;i++)
      {
         if(IsClientConnected(i) && !IsFakeClient(i) && GetClientName(i,pname,sizeof(pname)))
         {
            if(StrEqual(pname,param,false) && GetClientAuthString(i,steamid,sizeof(steamid)))
            {
               ok=true;   
               yesVotes=0;
               noVotes=0;
               CreateTimer(30.0,checkVote);               
            }
         }         
      }      
   }
}

public Event_VoteYes(Handle:event, const String:name[], bool:dontBroadcast)
{
   if(ok) yesVotes++;
}

public Event_VoteNo(Handle:event, const String:name[], bool:dontBroadcast)
{
   if(ok) noVotes++;
}

public Action:checkVote(Handle:timer)
{
   if(yesVotes>noVotes)
   {
      LogMessage("Server bans voted off player, yes:%i,no:%i",yesVotes,noVotes);
      ServerCommand("banid %d %s kick",GetConVarInt(banDuration),steamid);
   }
}