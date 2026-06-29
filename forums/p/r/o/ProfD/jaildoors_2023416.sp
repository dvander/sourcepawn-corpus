#include <sourcemod> 
#include <sdktools> 


public Plugin:myinfo =
{
	name = "JailDoors",
	author = "Prof-D. & Bibihotz",
	description = "It open JailDoors in X time.",
	version = "1.0",
	url = ""
};

new jbDoor;
new iEnt;
new Ientmap;
new DoorRotatingLock;
new DoorRotatingUnlock;
new const String:EntityList[][] = { "func_door", "func_movinglinear" };
new const String:BreakList[] = { "func_button" };
new const String:DoorRotatingList[] = { "func_door_rotating" };


public OnPluginStart()
{
    HookEvent("round_start", OnRoundStart);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	jbDoor = 28;
	CreateTimer(1.0, AutojaildoorOpen, _, TIMER_REPEAT);
}

public Action:AutojaildoorOpen(Handle:timer)
{
    new String:CurrentMap[256];
    GetCurrentMap(CurrentMap, 256);
    if(jbDoor == -1)
    {
        if(StrEqual(CurrentMap, "jb_minecraft_z_v3f", true))
        {
        for(new i = 0; i < sizeof(DoorRotatingList); i++)
        while((DoorRotatingUnlock = FindEntityByClassname(DoorRotatingUnlock, DoorRotatingList[i])) != -1)
            AcceptEntityInput(DoorRotatingUnlock, "unlock");
        }
        return Plugin_Stop; // timer end
    }

    if(jbDoor == 0) // not have [client] 
	{
        EmitSoundToAll("ambient/misc/brass_bell_d.wav");
        if(StrEqual(CurrentMap, "jb_minecraft_z_v3f", true))
        {
            for(new i = 0; i < sizeof(DoorRotatingList); i++)
            while((DoorRotatingLock = FindEntityByClassname(DoorRotatingLock, DoorRotatingList[i])) != -1)
                AcceptEntityInput(DoorRotatingLock, "lock");
            for(new i = 0; i < sizeof(BreakList); i++)
            while((Ientmap = FindEntityByClassname(Ientmap, BreakList[i])) != -1)
            {
                AcceptEntityInput(Ientmap, "press");
            }
        }
        else
        {
        for(new i = 0; i < sizeof(EntityList); i++)
            while((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
            {
                AcceptEntityInput(iEnt, "Open");
            }
        }
    }
    jbDoor -= 1;
    new maxclients = GetMaxClients();
    for(new client = 1; client <= maxclients; client++) 
    if(jbDoor > 0 && IsClientInGame(client) && !IsFakeClient(client))
    {
        PrintHintText(client, "[The cells should open] in: %i", jbDoor);
        PrintCenterText(client, "[The cells should open] in: %i", jbDoor);
    }
    else if(jbDoor == 0)
    {
        PrintHintText(client, "The cells have open!");
        PrintCenterText(client, "The cells have open!");
    }
    return Plugin_Continue;
}




public Action:OnOpenCommand(client, args)
{
    for(new i = 0; i < sizeof(EntityList); i++)
        while((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
            AcceptEntityInput(iEnt, "Open");

    return Plugin_Handled;
}

public Action:OnCloseCommand(client, args)
{
    for(new i = 0; i < sizeof(EntityList); i++)
        while((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
            AcceptEntityInput(iEnt, "Close");

    return Plugin_Handled;
}