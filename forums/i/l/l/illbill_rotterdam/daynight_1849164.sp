#include <sourcemod> 

public Plugin:myinfo =  
{ 
    name = "day and night", 
    author = "Tramp", 
    description = "Day and night mapcycle", 
    version = "1.0", 
    url = "sourcemod.pl" 
} 

public OnPluginStart() 
{ 
    MapCycle(); 
} 

public OnMapStart() 
{     
    MapCycle(); 
} 

public MapCycle() 
{ 

    new String:x[4];      
    FormatTime(x,sizeof(x),"%H",GetTime()); 
    new time; 
    time = StringToInt(x); 
     
    if ( time >= 20 || time <= 12 ) 
    { 
        //Load night MC between 20 and 12 
        ServerCommand("mapcyclefile nightmapcycle.txt"); 
        //PrintToChatAll("We are playing night MC"); 
    } 
    else 
    { 
        //Load day MC 
        ServerCommand("mapcyclefile mapcycle.txt"); 
        //PrintToChatAll("We are playing day MC"); 
    } 
     
}  