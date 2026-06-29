/* Reverse Cash Flow by databomb
   datal30mb@users.sourceforge.net
   Original Compile Date: 06.05.09
   
   This plugin revamps the cash flow system. A lot of times the winners keep on winning
   and get better guns which enable them to win more - this created a downward spiral
   for the losing team. Servers will give you 16k cash all the time to fix this. This plugin
   tries to balance the cash flow system out and make the winners work harder to keep winning.
   It tries to reverse the concepts of the current cash flow system and simplify them a
   little as well. All the variables involved are modifable via the console so you can fine-tune
   the numbers to further balance gameplay.
   
   Current System:
   The losing team gets 1,400 plus 500 for each consecutive loss up to a maximum of 2,900.
   If the bomb was planted the terrorists get an additional 800 added to their total.
   On DE maps, Ts and CTs both get 3,250 for winning UNLESS the bomb exploded, then Ts get 3,500
   On CS maps, the Ts and CTs get 3,000 base +150 for each hostage that is untouched/touched and alive/dead
   
   This Plugin: 
   The losing team is awarded a generous amount of money
   The losing team will get less money if the winners manage to complete their objective (rescue hostages, bomb, etc.)
   The winning team will get less money for each consecutive win
   
*/

#include <sourcemod>

// #ifndef directive not working, re-define then...
#define NULL 0
#define TRUE 1
#define FALSE 0
#define CT_TEAM 3
#define T_TEAM 2
#define INVALID_TEAM 5

new Handle:H_Enabled = INVALID_HANDLE;
new Handle:H_LoserMoney = INVALID_HANDLE;
new Handle:H_WinnerBase = INVALID_HANDLE;
new Handle:H_WinnerPenalty = INVALID_HANDLE;
new Handle:H_ObjectiveMoney = INVALID_HANDLE;
new Handle:H_StartMoney = INVALID_HANDLE;

new g_CashEntLoc = 1;

new PlayerCash[MAXPLAYERS + 1];
new CashToWinners = 0;
new CashToLosers = 0;
new LastRoundWinningTeam = INVALID_TEAM;

public Plugin:myinfo = 
{
	name = "Reverse Cash Flow",
	author = "databomb",
	description = "Reverses the cash flow system to give winners less as they do better.",
	version = "1.0.3",
	url = "vintagejailbreak.org"
}

public OnPluginStart()
{   
   // Store cash entity offset location
   g_CashEntLoc = FindSendPropOffs("CCSPlayer", "m_iAccount");
   if ((g_CashEntLoc == NULL) || (g_CashEntLoc == -1))
   {
      // quit for error. might occur if loaded for non cs:s game...
      return Plugin_Handled;
   }
   
   // Register console variables
   CreateConVar("sm_cashflow_version", "1.0", "Reverse Cash Flow Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
   H_Enabled = CreateConVar("sm_cashflow", "1", "Enables the reverse cash flow system", FCVAR_PLUGIN);
   H_LoserMoney = CreateConVar("sm_cashflow_loser", "3500", "Money given to losing team", FCVAR_PLUGIN, TRUE, 0.0, TRUE, 16000.00);
   H_WinnerBase = CreateConVar("sm_cashflow_winner_base", "3250", "Base money given to losing team after first win", FCVAR_PLUGIN, TRUE, 0.0, TRUE, 16000.00);
   H_WinnerPenalty = CreateConVar("sm_cashflow_winner_penalty", "750", "Money subtracted from base for each consecutive win", FCVAR_PLUGIN, TRUE, 0.0, TRUE, 5333.00); // rounded from 16000/penalties (3)
   H_ObjectiveMoney = CreateConVar("sm_cashflow_objective_penalty", "800", "Money subtracted from losers if objective was completed", FCVAR_PLUGIN, TRUE, 0.0, TRUE, 16000.00);

   // Auto generates a config file, plugin_cashflow.cfg, with default values
   AutoExecConfig(true, "plugin_cashflow");
   
   // Look for changes to act on
   HookConVarChange(H_Enabled, ConVarChange_Enabled);
   
   HookEvent("round_end",Event_RoundEnded,EventHookMode_Post);
   HookEvent("round_start",Event_RoundStarted,EventHookMode_Post);
	
	H_StartMoney = FindConVar("mp_startmoney");
      
} // end OnPluginStart

public ConVarChange_Enabled(Handle:cvar, const String:oldVal[], const String:newVal[])
{
   if (StringToInt(newVal) != TRUE)
   {
      // Unhook events
      UnhookEvent("round_end",Event_RoundEnded,EventHookMode_Post);
      UnhookEvent("round_start",Event_RoundStarted,EventHookMode_Post);
      // Unhook convar changes EXCEPT this one
   } 
   else if (StringToInt(oldVal) != StringToInt(newVal)) // Don't waste time "re"hooking
   {
      HookEvent("round_end",Event_RoundEnded,EventHookMode_Post);
      HookEvent("round_start",Event_RoundStarted,EventHookMode_Post);
   }
} // end ConVarChange_Enabled

public Event_RoundEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
   static ConsecutiveWins = 1;
  
   new EndingMethod = GetEventInt(event, "reason");
   new WinningTeam = GetEventInt(event, "winner");

   
   // Check for consecutive wins
   if (WinningTeam == LastRoundWinningTeam)
   {
      ConsecutiveWins++;
   }
   else
   {
      ConsecutiveWins = 1;
   }
   // If round was a draw or game is commencing, don't assign a winner yet!
   if ((EndingMethod == 9) || (EndingMethod == 15))
   {
      LastRoundWinningTeam = INVALID_TEAM;
   }
   else
   {
      LastRoundWinningTeam = WinningTeam;
   }
   
   // Put cash values in an array for use in a few seconds
   for (new idx = 1; idx <= MaxClients; idx++)
   {
      if (IsClientInGame(idx))
      {
			if (LastRoundWinningTeam == INVALID_TEAM)
			{
				PlayerCash[idx] = GetConVarInt(H_StartMoney);
			}
			else
			{
				PlayerCash[idx] = GetEntData(idx, g_CashEntLoc);
			}
      }
      else
      {
         // in case someone joins between rounds.
         PlayerCash[idx] = GetConVarInt(H_StartMoney);
      }
   }

   // Determine Losers Cash
   // Was objective completed? (bomb exploded, VIP escaped, Ts escaped, hostage(s) rescued)
   if ((EndingMethod == 0) || (EndingMethod == 1) || (EndingMethod == 3) || (EndingMethod == 10))
   {
      CashToLosers = GetConVarInt(H_LoserMoney) - GetConVarInt(H_ObjectiveMoney);
   } 
   else
   {
      CashToLosers = GetConVarInt(H_LoserMoney);
   }
   // Determine Winners Cash
   switch (ConsecutiveWins)
   {
      case 1:
      {
         CashToWinners = GetConVarInt(H_WinnerBase);
      }
      case 2:
      {
         CashToWinners = GetConVarInt(H_WinnerBase) - GetConVarInt(H_WinnerPenalty);
      }
      case 3:
      {
         CashToWinners = GetConVarInt(H_WinnerBase) - 2*GetConVarInt(H_WinnerPenalty);
      }
      default:
      {
         CashToWinners = GetConVarInt(H_WinnerBase) - 3*GetConVarInt(H_WinnerPenalty);
      }
   } // end switch
   
   return Plugin_Handled;
   
} // end Event_RoundEnded

public Event_RoundStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
   new IndividualCash = 0;
   
   // Adjust cash flows (we don't care what the game did, we're using round_end as reference)
   for (new idx = 1; idx <= GetMaxClients(); idx++)
   {
      // Check to see if client is connected and that we actually had a winner last round!
      if (IsClientInGame(idx) && (LastRoundWinningTeam != INVALID_TEAM))
      {
         IndividualCash = 0;
         
         // Check for winning team
         new clientTeam = GetClientTeam(idx);
         if (clientTeam == LastRoundWinningTeam)
         {
            IndividualCash = PlayerCash[idx] + CashToWinners;
         }
         // if they're not in spectator team
         else if (clientTeam > 1)
         {
            IndividualCash = PlayerCash[idx] + CashToLosers;
         }
         // Bound check the cash before we set it
         if (IndividualCash > 16000)
         {
            IndividualCash = 16000;
         }
         if (IndividualCash < 0)
         {
            IndividualCash = 0;
         }
         
         // Finally..
         SetEntData(idx, g_CashEntLoc, IndividualCash);
      }
   }

   return Plugin_Handled;
} // end Event_RoundStarted
