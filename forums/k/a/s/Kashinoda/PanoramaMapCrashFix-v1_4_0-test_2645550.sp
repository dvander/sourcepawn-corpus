#include <sourcemod> 

#pragma semicolon 1
#pragma tabsize 0
#pragma newdecls required

public Plugin myinfo =
{
    name = "",
    author = "Kashinoda",
    description = "",
    version = "1",
    url = "http://alliedmods.net/"
};

public void OnPluginStart() 
{ 
   AddCommandListener(MapChange, "changelevel");
   AddCommandListener(MapChange, "map");
       
} 

/* ==============================================
*/

public Action MapChange (int client, const char[] cmd, int argc)
{
    LogMessage("Map changing, sending 'retry' to clients"); 

      for (int i = 1; i <= MaxClients; i++) 
        {
          if (IsClientConnected(i) && !IsFakeClient(i))
              {                 
                 ClientCommand(i, "retry"); 
                 LogMessage("Sending retry to %N", i); 
              } 
        }     
}

