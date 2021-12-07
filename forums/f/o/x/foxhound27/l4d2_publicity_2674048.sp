#include <sourcemod>
#include <colors>

//NOTE this is my first plugin at sourcepawn!

ConVar TIME;
Handle FILE = INVALID_HANDLE;
Handle TIMER = INVALID_HANDLE;


public Plugin myinfo = {
 name = "[L4D2] Chat Publicity",
 author = "Foxhound27",
 description = "Displays colored publicity as chat message",
 version = "1.0",
 url = " ><> "
};



public void OnPluginStart() {
 char PATH[24];
 GetGameFolderName(PATH, sizeof(PATH));
 if (!StrEqual(PATH, "left4dead2", false)) SetFailState("Sorry my plugin was made for L4D2");
 else 

 TIME = CreateConVar("l4d2_publicity_time", "120", "How long must wait to display each publicity (default 2 min = 120 seconds)");
 TIME.AddChangeHook(OnCvarChange);
 FILE = CreateKeyValues("publicity");

 char FilePath[256];
 BuildPath(Path_SM, FilePath, sizeof(FilePath), "data/l4d2_publicity.txt");
 FileToKeyValues(FILE, FilePath);

}


public void OnCvarChange(ConVar convar, char[] oldValue, char[] newValue)
{
    if (convar == TIME)
    {
    	KillTimer(TIMER);
        TIMER = CreateTimer(1.0 * GetConVarInt(TIME), DisplayPublicity,_, TIMER_REPEAT);
    }
}



public void OnMapStart(){


TIMER = CreateTimer(1.0 * GetConVarInt(TIME), DisplayPublicity,_, TIMER_REPEAT);

}

public void OnMapEnd(){

KillTimer(TIMER);

}


void GoToNextKeyOrStartOver()
{
    if (!KvGotoNextKey(FILE))
    {
        KvRewind(FILE);
        KvGotoFirstSubKey(FILE);
    }
}


public Action DisplayPublicity(Handle timer) {

 char publicity[256];
 KvGetString(FILE, "msg", publicity, sizeof(publicity));
 CPrintToChatAll(publicity);
 GoToNextKeyOrStartOver();
 
}


