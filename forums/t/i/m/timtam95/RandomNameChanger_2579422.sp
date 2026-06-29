#include <sourcemod>
#include <sdktools>

new Handle:g_adtArray;

public Plugin:myinfo =
{
    name = "Random Name Changer",
    author = "timtam95",
    description = "Random Name Changer",
    version = "1.0.0.0",
    url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
    g_adtArray = CreateArray(64);

    //for CSGO
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy); 

    //for TF2
    //HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy); 

}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{ 

    decl String:path[PLATFORM_MAX_PATH], String:line[128];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "names.txt");
    new Handle:fileHandle = OpenFile(path, "r");

    while(!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, line, sizeof(line)))
    {
      TrimString(line);
      if (line[0] != EOS) PushArrayString(g_adtArray, line);
    }


    CloseHandle(fileHandle);

    new String:buffer[32];

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            if (GetArraySize(g_adtArray) == 0) break;
            int n = GetRandomInt(0, GetArraySize(g_adtArray) - 1);
            GetArrayString(g_adtArray, n, buffer, 32);
            SetClientName(i, buffer);
            RemoveFromArray(g_adtArray, n);
        }
    }  

    ClearArray(g_adtArray);

}


 