/*

Frag Limit for TF2
by Deetr and Hicks
http://justwrenches.com
Adds a frag limit which will end the round when reached
Created 2014-3-13
Updated 2014-3-14
Version 1.1

*/

//Imports
#include <sourcemod>
#include <sdktools>

//Number of frags to end round
new Handle:fragLimit;

//Plugin info
public Plugin:myinfo =
{
    name = "Frag Limit",
    author = "Deetr & Hicks",
    description = "End round if player has given number of kills.",
    version = "1.1",
    url = "http://justwrenches.com"
};

//On plugin start
public OnPluginStart() {
    //Set maximum frags
    fragLimit = CreateConVar("maxFrags",
            "50",
            "Sets a frag limit",
            FCVAR_NOTIFY,
            true,
            1.0,
            false);
    //Create sm_roundend command which ends round
    RegAdminCmd("sm_roundend", ForceRoundEnd, ADMFLAG_CHANGEMAP);
    //Hook into player death event
    HookEvent("player_death", Event_PlayerDeath);
    //Create sm_maxfrags which sets max frags before round switch
    RegAdminCmd("sm_fraglimit", SetMaxFrags, ADMFLAG_CHANGEMAP, "Sets the maximum number of frags before the round ends.");
}

//Handles player deaths
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    //ID of the attacker in Event_PlayerDeath
    new attackerId = GetEventInt(event, "attacker");
    //Client of attackerId
    new client = GetClientOfUserId(attackerId);
    //Number of kills attacker has
    new kills = GetClientFrags(client);

    //When a player reaches frag limit
    if( kills >= GetConVarInt(fragLimit) - 1) {
        //Create a buffer for the name 
        new String:nameBuffer[MAX_NAME_LENGTH];
        //Get the name of the client of the attacker
        GetClientName(client, nameBuffer, MAX_NAME_LENGTH);
        //End the round with the team of the attacker winning
        ServerCommand( "sm_roundend %i", GetClientTeam(client));
        //Tell the server that the frag limit was reached
        PrintToServer("Frag limit reached by %s.", nameBuffer);
        PrintToChatAll("Frag limit reached by %s.", nameBuffer);
    }
}

//Ends the round with team of client winning
public Action:ForceRoundEnd(client, winningTeam)
{
    //entIndex stores the index of an entity
    new entIndex = -1;
    //Find the index of entity game_round_win
    entIndex = FindEntityByClassname(entIndex, "game_round_win");

    //entIndex will be < 0 if game_round_win doesn't exist
    if (entIndex < 0)
    {
        //So we create game_round_win if it doesn't already exist
        entIndex = CreateEntityByName("game_round_win");
        //Check if the entity is valid
        if (IsValidEntity(entIndex))
        {
            //Spawn the entity in map
            DispatchSpawn(entIndex); 
        } 
            
        else
        {
            //If it doesn't exist the game will go to timelimit assuming mp_timelimit != 0
            ReplyToCommand(client, "Unable to find or create game_round_win entity. Round will not end.");
            return Plugin_Handled;
        }
    }

    //Buffer for which team wins 
    decl String:buffer[3];
    //Get argument of command in buffer
    GetCmdArg(1, buffer, sizeof(buffer));
    //Set winning team
    SetVariantInt(StringToInt(buffer));
    //Set the team for the round win
    AcceptEntityInput(entIndex, "SetTeam");
    //End the round
    AcceptEntityInput(entIndex, "RoundWin");

    CreateTimer(5.0, ForceMapChange);
}

//Sets max frags
public Action:SetMaxFrags(client, frags){
    //Buffer for which team wins
    decl String:buffer[10];
    //Get argument of command in buffer
    GetCmdArg(1, buffer, sizeof(buffer));
    //Integer for storing max number of frags
    new newFragLimit = StringToInt(buffer);
 
    if(newFragLimit > 0){
        SetConVarInt(fragLimit, newFragLimit, true, true);
    }
    else{
        ReplyToCommand(client, "Invalid frag limit.");
        return Plugin_Handled;
    }
 
    return Plugin_Handled;
}

//Forces map change
public Action:ForceMapChange(Handle:timer)
{
    new String:newmap[65];
    GetNextMap(newmap, sizeof(newmap));
    ForceChangeLevel(newmap, "Frag limit reached.");
    return Plugin_Handled;
}