#include <sourcemod>
#include <sdktools>

Handle g_adtArray;
Handle NickChangeTimers[MAXPLAYERS+1];
char RandomNicks[MAXPLAYERS+1][32];
char OriginalNicks[MAXPLAYERS+1][32];

public Plugin:myinfo =
{
    name = "Random Name Changer",
    author = "timtam95",
    description = "Random Name Changer",
    version = "1.0.0.1",
    url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
    g_adtArray = CreateArray(64);

    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy); 
    HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);

}

public Action ChangeNick(Handle timer, any nick)
{
  if (IsClientInGame(nick)) SetClientName(nick, RandomNicks[nick])
  NickChangeTimers[nick] = null;
}


public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{ 

    char path[PLATFORM_MAX_PATH];
    char line[128];

    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "names.txt");
    Handle fileHandle = OpenFile(path, "r");

    while(!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, line, sizeof(line)))
    {
      TrimString(line);
      if (line[0] != EOS) PushArrayString(g_adtArray, line);
    }

    CloseHandle(fileHandle);

    char randomnick[32];
    char originalnick[32];

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            originalnick[0] = EOS;
            randomnick[0] = EOS;
            GetClientName(i, originalnick, sizeof(originalnick));
            strcopy(OriginalNicks[i], 32, originalnick);

            if (GetArraySize(g_adtArray) == 0) break;
            int n = GetRandomInt(0, GetArraySize(g_adtArray) - 1);
            GetArrayString(g_adtArray, n, randomnick, 32);
            strcopy(RandomNicks[i], 32, randomnick);
            NickChangeTimers[i] = CreateTimer(35.0, ChangeNick, i);
            RemoveFromArray(g_adtArray, n);


        }
    }  

    ClearArray(g_adtArray);

}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{ 

  for (new i = 1; i <= MaxClients; i++)
  {
    if (IsClientInGame(i))
    {
      SetClientName(i, OriginalNicks[i]);
    }

  }  

}


 