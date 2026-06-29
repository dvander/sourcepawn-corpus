/* [TF2] Team System, By TheUnderTaker */

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>

#pragma tabsize 0

public Plugin:myinfo = 
{
	name = "[TF2] Team System",
	author = "TheUnderTaker",
	description = "Team System for TF2, It can choose blue by different ways, Also can lock/Unlock teams!", // I recommend you to use in Jailbreak or Minigames in servers!
	version = "1.1",
	url = "http://steamcommunity.com/id/theundertaker007/"
}

new randomnumber;
new randomguessnumber;
new lastnumber;

int g_answer;
int player;
int seconds;

bool:LastOn = false;

char g_math[8];

Handle:teamtolock = INVALID_HANDLE;
Handle ticking;

public OnPluginStart()
{
	// Commands:
	
	RegAdminCmd("sm_random", Command_Random, ADMFLAG_GENERIC, "You write /random in chat, It choose random player and move him to blue team!");
	RegAdminCmd("sm_randomblue", Command_Random, ADMFLAG_GENERIC, "You write /random in chat, It choose random player and move him to blue team!")
	RegAdminCmd("sm_first", Command_first, ADMFLAG_GENERIC, "You write /first in chat, It throws on /msay message a random number and the first write the correct number move to blue team!");
	RegAdminCmd("sm_firstwrite", Command_first, ADMFLAG_GENERIC, "You write /first in chat, It throws on /msay message a random number and the first write the correct number move to blue team!");
	RegAdminCmd("sm_math", Command_Math, ADMFLAG_GENERIC, "Like /first, But throws a random math question, the first answer correctly move to blue!");
	RegAdminCmd("sm_mathquestion", Command_Math, ADMFLAG_GENERIC, "Like /first, But throws a random math question, the first answer correctly move to blue!");
	RegAdminCmd("sm_guess", Command_Guess, ADMFLAG_GENERIC, "Like first, Who guess the correct number (Range 1-20) move to blue team!");
	RegAdminCmd("sm_guessnumber", Command_Guess, ADMFLAG_GENERIC, "Like first, Who guess the correct number (Range 1-20) move to blue team!");
	RegAdminCmd("sm_last", Command_Last, ADMFLAG_GENERIC);
	RegAdminCmd("sm_lock", Command_lock, ADMFLAG_GENERIC); // Lock teams, !lockteam <team>
	RegAdminCmd("sm_unlock", Command_Unlock, ADMFLAG_GENERIC); // Unlock all teams.
	
	// Command Listeners:
	
	AddCommandListener(MathSay, "say");
	AddCommandListener(MathSay, "say_team");
	AddCommandListener(OnSay, "say");
	AddCommandListener(OnSay, "say_team");
	AddCommandListener(OnguessSay, "say");
	AddCommandListener(OnguessSay, "say_team");
	AddCommandListener(OnLastSay, "say");
	AddCommandListener(OnLastSay, "say_team");
	
	// Find ConVar
	
	teamtolock = FindConVar("mp_humans_must_join_team");
}

public OnMapStart()
{
	LastOn = false;
}

// Team Filters:

enum GetRandomPlayerFilter
{
 GetRandomPlayerFilter_All,
 GetRandomPlayerFilter_BlueRed,
 GetRandomPlayerFilter_Blue,
 GetRandomPlayerFilter_Red
}

// Lock
public Action:Command_lock(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[Team System] Usage: sm_lock <team>");
		return Plugin_Handled;
	}
	new String:arg[64]; // Making the first argument
	GetCmdArg(1, arg, sizeof(arg)); // Getting the first argument
	if (StrEqual(arg, "red") || StrEqual(arg, "Red")) // If equal to "Red" or "red" it will lock red team
	{
		SetConVarString(teamtolock, "blue"); // Locking red team
		PrintToChatAll("%N: Locked red team!", client); // Says it to all players.
		PrintToChat(client, "You just locked red team!"); // Says it to client.
		LogAction(client, -1, "%N: Locked red team!", client); // Print message to logs
	}
	if (StrEqual(arg, "blue") || StrEqual(arg, "Blue")) // If equal to "Blue" or "blue" it will lock blue team
	{
		SetConVarString(teamtolock, "red"); // Locking blue team
		PrintToChatAll("%N: Locked blue team!", client); // Says it to all players
		PrintToChat(client, "You just locked blue team!"); // Says it to client
		LogAction(client, -1, "%N: Locked blue team", client); // Print message to logs
	}
	if (!StrEqual(arg, "red") && !StrEqual(arg, "blue") && !StrEqual(arg, "Red") && !StrEqual(arg, "Blue")) // If not equal to "Red"/"red"/"blue"/"Blue" It will say to client that he entered invalid team.
	{
		PrintToChat(client, "Please enter valid team!(red, blue, Red, Blue)"); // Says to client that the team he entered = INVALID!
	}
	return Plugin_Handled;
}

// Unlock
public Action:Command_Unlock(client, args)
{
	SetConVarString(teamtolock, "any"); // Open all teams
	PrintToChatAll("%N: Unlocked teams!", client); // Print to all who unlocked teams.
	PrintToChat(client, "You just unlocked teams!"); // Print to client that he unlocked.
	LogAction(client, -1, "%N: Unlocked teams!", client); // Print message to logs
	return Plugin_Handled;
}

// Action for command random
public Action:Command_Random(client, args)
{
	player = GetRandomPlayer(GetRandomPlayerFilter_Red);
	
	GetRandomPlayer(GetRandomPlayerFilter_Red); // Get random player from team Red
	
	TF2_ChangeClientTeam(player, TFTeam_Blue); // Move the random player to team Blue
}

// Action for command first
public Action:Command_first(int client,int args)
{
 randomnumber = GetRandomInt(1, 9999); // Throws number 1-9999
 ServerCommand("sm_msay The first one type [%d] will move to blue!", randomnumber); // Show the random number on MSAY message.
 PrintToChatAll("The first one write [%d] will swap to blue!", randomnumber); // Print the random number to chat.
 
 return Plugin_Handled;
}

// Action for command guess
public Action Command_Guess(int client, int args)
{
	randomguessnumber = GetRandomInt(1, 20) // Throws a random number 1-20
	ServerCommand("sm_msay The first one guess the right number [Range 1-20] will move to blue!."); // Show the random number on MSAY message
	PrintToChatAll("The first one guess the right number [Range 1-20] will move to blue!.") // Print to chat the random number.
}

// Action for command math
public Action Command_Math(int client, int args)
{
 g_answer = GetRandomMath(g_math, sizeof(g_math)); // Get answer from GetRandomMath
 ServerCommand("sm_msay The first answer this math question [%s] will move to blue!", g_math); // Shows the random math question on MSAY Message
 PrintToChatAll("The first answer this math question [%s] will move to blue!", g_math); // Print the math question to chat.
 PrintToChat(client, "The answer of math: %d", g_answer); // Tells to the admin the math answer (who typed the command /math)
 
 return Plugin_Handled;
}

public Action:Command_Last(client, args)
{
	lastnumber = GetRandomInt(99999, 999999);
	ServerCommand("sm_msay The last write [%d] will move to blue!", lastnumber); // Shows the random math question on MSAY Message
	PrintToChatAll("The last write [%d] will move to blue!", lastnumber); // Print the math question to chat.
	CreateTimer(6.0, PerformLast);
    
	seconds = 5;

    if(ticking != INVALID_HANDLE)
    {
        KillTimer(ticking);
        ticking = INVALID_HANDLE;
    }
    
    ticking = CreateTimer(1.0, CountDown, _, TIMER_REPEAT);
    
	return Plugin_Handled;
}

// GetRandomMath - Math Generator:
stock int GetRandomMath(char[] math, int maxlength)
{
 int a, b, c, d;
 do {
  do
   a = GetRandomInt(-99, 99);
  while(a == 0);
  do
   b = GetRandomInt(-99, 99);
  while(b == 0);
  c = GetRandomInt(0, 1);
  if (c)
   d = a + b;
  else
   d = a * b;
 } while (d > 99 || d < 1);
 
 if (c)
  if (a < 0)
   FormatEx(math, maxlength, "%d%d", b, a);
  else
   FormatEx(math, maxlength, "%d%s%d", a, (b > 0) ? "+" : "", b);
 else
  FormatEx(math, maxlength, "%d*%d", a, b);
 
 return d;
}

// When player that said the true number from "first"
public Action:OnSay(client, const String:command[], args)
{
 if (randomnumber && TF2_GetClientTeam(client) == TFTeam_Red) {
  new String:text[4096], String:buffer[16];
  GetCmdArgString(text, 4096);
  StripQuotes(text);
  IntToString(randomnumber, buffer, sizeof(buffer));
  if (StrEqual(text, buffer)) {
   TF2_ChangeClientTeam(client, TFTeam_Blue);
   randomnumber = 0;
   PrintToChatAll("%N Won! and moved to blue team.", client);
   
  }
 }
}

// When player that said the true math answer from "math"
public Action MathSay(int client, const char[] command, int args)
{
 if (g_answer != 0 && TF2_GetClientTeam(client) == TFTeam_Red) {
  char text[4096], buffer[8];
  GetCmdArgString(text, sizeof(text));
  StripQuotes(text);
  IntToString(g_answer, buffer, sizeof(buffer));
  if (StrEqual(text, buffer)) {
   TF2_ChangeClientTeam(client, TFTeam_Blue);
   PrintToChatAll("%N first solve the math right and moved to Blue! The answer was %d!", client, g_answer);
   g_answer = 0; // Math answer for tell the admin
   FormatEx(g_math, sizeof(g_math), ""); // Math answer
  }
 }
 
 return Plugin_Continue;
}

// When player guessed the true number 1-20 from "guess"
public Action:OnguessSay(client, const String:command[], args)
{
 if (randomguessnumber && TF2_GetClientTeam(client) == TFTeam_Red) {
  new String:text[4096], String:buffer[16];
  GetCmdArgString(text, 4096);
  StripQuotes(text);
  IntToString(randomguessnumber, buffer, sizeof(buffer));
  if (StrEqual(text, buffer)) {
   TF2_ChangeClientTeam(client, TFTeam_Blue);
   PrintToChatAll("%N Won! and moved to blue team.", client);   
  }
 }
}

/** stock int GetRandomPlayer();
Return random player, if no players in game return -1. */


stock int GetRandomPlayer(GetRandomPlayerFilter filter = GetRandomPlayerFilter_All)
{
 int players[MAXPLAYERS+1], counter;
 for (int i = 1; i <= MaxClients; i++)
  if (IsClientInGame(i))
   switch (filter) {
    case GetRandomPlayerFilter_All: players[counter++] = i;
    case GetRandomPlayerFilter_BlueRed:
     if (TF2_GetClientTeam(i) == TFTeam_Red || TF2_GetClientTeam(i) == TFTeam_Blue)
      players[counter++] = i;
    case GetRandomPlayerFilter_Blue:
     if (TF2_GetClientTeam(i) == TFTeam_Blue)
      players[counter++] = i;
    case GetRandomPlayerFilter_Red:
     if (TF2_GetClientTeam(i) == TFTeam_Red)
      players[counter++] = i;
   }

 if (!counter)
  return -1;

 return players[GetRandomInt(0, counter-1)];
}

public Action:PerformLast(Handle:timer)
{
	LastOn = true;
}

// When player says last the true number.
public Action:OnLastSay(client, const String:command[], args)
{
 if (lastnumber && TF2_GetClientTeam(client) == TFTeam_Red && LastOn == true) {
  new String:text[4096], String:buffer[16];
  GetCmdArgString(text, 4096);
  StripQuotes(text);
  IntToString(lastnumber, buffer, sizeof(buffer));
  if (StrEqual(text, buffer)) {
   TF2_ChangeClientTeam(client, TFTeam_Blue);
   lastnumber = 0;
   PrintToChatAll("%N Won! and moved to blue team.", client);
   LastOn = false;
  }
 }
}

public Action CountDown(Handle timer)
{
	SetHudTextParams(-1.0, 0.26, 7.0, 0, 255, 0, 150);
	ShowHudTextAll(0, "%d", seconds);
	seconds--;
	
	if(seconds == 0 && ticking == INVALID_HANDLE)
    {
        KillTimer(ticking);
        LastOn = false;
        ticking = INVALID_HANDLE;
        return Plugin_Stop;
    }
    
    if(!seconds)
    {
    	return Plugin_Stop;
    }
	
    return Plugin_Continue;
}

void ShowHudTextAll(int channel, const char[] message, any ...) 
{ 
    char buffer[256]; 
    VFormat(buffer, sizeof(buffer), message, 3); 
    for (int i = 1; i <= MaxClients; i++) 
        if (IsClientInGame(i)) 
            ShowHudText(i, channel, buffer); 
}

/* Enjoy! */