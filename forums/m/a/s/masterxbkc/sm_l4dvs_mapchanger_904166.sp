#pragma semicolon 1
#include <sourcemod>
#define Version "0.1"
new Handle:Allowed = INVALID_HANDLE;
new RoundEndCounter = 0;
new MaxPlayers = 0;
new String:Map[64];

public Plugin:myinfo = 
{
    name = "L4D Auto Map Changer",
    author = "Dionys",
    description = "Force changelevel when mission end (For Farm VS and Hospital VS).",
    version = Version,
    url = "skiner@inbox.ru"
};

public OnPluginStart()
{
    decl String:ModName[50];
    GetGameFolderName(ModName, sizeof(ModName));
    if(!StrEqual(ModName, "left4dead", false))
        SetFailState("Use this for Left 4 Dead only.");
    HookEvent("round_end", Event_RoundEnd);
    Allowed = CreateConVar("sm_l4dvs_mapchangeforce", "1", "Enables Force changelevel when mission end.");
    AutoExecConfig(true, "sm_l4dvs_mapchanger");
}

public OnMapStart()
{
    RoundEndCounter = 0;
    MaxPlayers = GetMaxClients();
    GetCurrentMap(Map, sizeof(Map));
}

stock ChangeMap(String:NextMap[])
{
    for(new player=1; player<=MaxPlayers; player++)
    {
        if(IsClientInGame(player) && IsFakeClient(player))
            KickClient(player);
    }
    ServerCommand("changelevel %s", NextMap);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    RoundEndCounter += 1; //What if admin enables at last second?
    if(GetConVarInt(Allowed) && RoundEndCounter >= 4)
    {
        if(StrEqual(Map, "l4d_vs_farm01_hilltop"))
            ChangeMap("l4d_vs_hospital01_apartment");
        else if(StrEqual(Map, "l4d_vs_hospital05_rooftop"))
            ChangeMap("l4d_vs_airport01_greenhouse");
        else if(StrEqual(Map, "l4d_vs_airport05_runway"))
            ChangeMap("l4d_vs_smalltown01_caves");
        else if(StrEqual(Map, "l4d_vs_smalltown05_houseboat"))
            ChangeMap("l4d_vs_farm05_cornfield");
    }
}