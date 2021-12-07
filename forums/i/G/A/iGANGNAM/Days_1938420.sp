#include <sourcemod>

public OnPluginStart() 
{
decl String:Day[100];
FormatTime(Day, sizeof(Day), "%A", GetTime());

if (StrEqual(Day, "Monday")) 
     ServerCommand("bot_join_team T");
else if  (StrEqual(Day, "Tuesday")) 
     ServerCommand("bot_join_team CT");
else if  (StrEqual(Day, "Wednesday")) 
     ServerCommand("bot_join_team T");
else if  (StrEqual(Day, "Thursday")) 
     ServerCommand("bot_join_team CT");
else if  (StrEqual(Day, "Friday")) 
     ServerCommand("bot_join_team T");
else if  (StrEqual(Day, "Saturday")) 
     ServerCommand("bot_join_team CT");
else if  (StrEqual(Day, "Sunday")) 
     ServerCommand("bot_join_team T");
}