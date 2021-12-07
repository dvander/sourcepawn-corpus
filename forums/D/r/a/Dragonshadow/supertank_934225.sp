//Force Semicolon at function end
#pragma semicolon 1
//Including sourcemod and sdktools 
//('cause I'm cool like that)
#include <sourcemod>
#include <sdktools>
//Defining cvar flags and plugin version
#define FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.2"
//omigod cvar handles
new Handle:supertank = INVALID_HANDLE;
new Handle:hpadd = INVALID_HANDLE;
new Handle:hpmulti = INVALID_HANDLE;
new Handle:hptype = INVALID_HANDLE;
new Handle:announce = INVALID_HANDLE;
new Handle:hardmode = INVALID_HANDLE;
new Handle:countdead = INVALID_HANDLE;
//This will hold the new tank hp
new tankhealth;
//This will tell the plugin if the tank is alive or not
new tanklive=0;
//Containers for the handle hooks, because
//I don't like getconvaretc in
//functions unless its the only option
new Float:hpaddhook;
new hptypehook;
new Float:hpmultihook;
new enablehook;
new announcehook;
new hardmodehook;
new countdeadhook;
//Plugin info, duh
public Plugin:myinfo =
{
    name        = "SuperTank",
    author      = "Dragonshadow",
    description = "Increases Tank HP Based On Survivor Count",
    version     = PLUGIN_VERSION,
    url         = "www.snigsclan.com"
};
//Plugin is starting, do this stuff
public OnPluginStart()
{
    //Convars ahoy!
    CreateConVar("l4d_st_version", PLUGIN_VERSION, "SuperTank Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    supertank = CreateConVar("l4d_st_enable","1","Enable SuperTank | 1 = on, 0 = off", FLAGS,true,0.0,true,1.0);
    announce = CreateConVar("l4d_st_announce","1","Announce Increased Tank HP on Tank Spawn | 1 = on, 0 = off", FLAGS,true,0.0,true,1.0);
    hardmode = CreateConVar("l4d_st_hardmode","0","Increase Tank HP with Default Survivor Count (4) | 1 = on, 0 = off", FLAGS,true,0.0,true,1.0);
    countdead = CreateConVar("l4d_st_countdead","0","Count Dead Survivors In HP Calculation? | 1 = on, 0 = off", FLAGS,true,0.0,true,1.0);
    hpadd = CreateConVar("l4d_st_aamount","1250.0","HP To Add Per Extra Survivor | 2000.0 Will Add 2000 HP Per Extra Survivor", FLAGS,true,0.0,false);
    hpmulti = CreateConVar("l4d_st_mamount","0.10","HP Multiplier | .10 Gains a Tenth of Normal HP (1200) Per Extra Survivor)", FLAGS,true,0.01,true,10.00);
    hptype = CreateConVar("l4d_st_hptype","1","Add = 1 | Multiply = 2", FLAGS,true,1.0,true,2.0);
    //Hook the tank spawn and death events
    HookEvent("tank_spawn", tankspawn);
    HookEvent("tank_killed", tankdeath);
    //Hook the convars to our containers
    HookConVarChange(supertank, OnCvarChanged);
    HookConVarChange(announce, OnCvarChanged);
    HookConVarChange(hardmode, OnCvarChanged);
    HookConVarChange(hpadd, OnCvarChanged);
    HookConVarChange(hpmulti, OnCvarChanged);
    HookConVarChange(hptype, OnCvarChanged);
    //Write a config file with all the cvars in it
    AutoExecConfig(true, "supertank");
}
//Fill the hooks with inf0z when configs are executed
public OnConfigsExecuted() 
{
    //container = getconvaretc(convartograb);
    hpaddhook = GetConVarFloat(hpadd);
    hpmultihook = GetConVarFloat(hpmulti);
    hptypehook = GetConVarInt(hptype);
    enablehook = GetConVarInt(supertank);
    announcehook = GetConVarInt(announce);
    hardmodehook = GetConVarInt(hardmode);
    countdeadhook = GetConVarInt(countdead);
} 
//Re-fill the hooks with inf0z if any of the cvar values change
public OnCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
    //container = getconvaretc(convartograb);
    hpaddhook = GetConVarFloat(hpadd);
    hpmultihook = GetConVarFloat(hpmulti);
    hptypehook = GetConVarInt(hptype);
    enablehook = GetConVarInt(supertank);
    announcehook = GetConVarInt(announce);
    hardmodehook = GetConVarInt(hardmode);
    countdeadhook = GetConVarInt(countdead);
} 

public tankspawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Are we enabled? If not then don't do anything
    if(enablehook)
    {
        //Oh hey we're enabled! 
        for (new i=1; i<=MaxClients; i++)
        {
            //Is this client connect
            if (IsClientConnected(i))
            {
                //Yep, now are they ingame?
                if (IsClientInGame(i))
                {
                    //Are the clients on infected?
                    if (GetClientTeam(i) == 3)
                    {
                        //Are they alive?
                        if (IsPlayerAlive(i))
                        {
                            //Yup, now check the class
//                            new zombieclass = GetEntProp(i, Prop_Send, "m_zombieClass");
                            //Is it the tank?
//                            if (zombieclass == 5)
                            if (GetEntProp(i, Prop_Send, "m_zombieClass") == 5)                            
                            {
                                //Yep, grab the userid from the event
                                new client = GetClientOfUserId(GetEventInt(event, "userid"));
                                //Is there already a tank alive?
                                switch(tanklive)
                                {
                                case 0:
                                    {
                                        //Nope no tank yet, gotta calculate his new hp!
                                        CreateTimer(0.1, SetTankHP, client);
                                    }
                                case 1:
                                    {
                                        //Theres already a tank in play, health has already been calc'd
                                        //So just set the hp
                                        SetEntProp(client,Prop_Send,"m_iMaxHealth",tankhealth);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
public tankdeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    //A Tank just died, check if any are still alive
    //LOOP TIEM LOL
    for (new i=1; i<=MaxClients; i++)
    {        
        //Is this client connect
        if (IsClientConnected(i))
        {
            //Yep, now are they ingame?
            if (IsClientInGame(i))
            {
                //Are the clients on infected?
                if (GetClientTeam(i) == 3)
                {
                    //Yup, now check the class
 //                   new zombieclass = GetEntProp(i, Prop_Send, "m_zombieClass");
                    //Is it the a tank?
 //                   if (zombieclass == 5)
                    if (GetEntProp(i, Prop_Send, "m_zombieClass") == 5)
                    {
                        //Yes, are they alive?
                        if (IsPlayerAlive(i))
                        {
                            //Yep, still alive
                            tanklive = 1;
                        }
                        else if (!IsPlayerAlive(i))
                        {
                            //Nope, they're all dead
                            tanklive = 0;
                        }
                    }
                }
            }
        }
    }
}

public Action:SetTankHP(Handle:timer, any:client) // this delay is necassary or it fails.
{
    //Checking if we're enabled again
    if (enablehook)
    {
        //This will hold the survivor count
        new Float:survivors;
        //Ooooh, is hardmode on?
        switch(hardmodehook)
        {
        case 0:
            {
                //No its not, deduct 4 from whatever survivor count you get
                //You're only counting extras
                if(countdeadhook)
                {
                    survivors=(float(AliveTeamPlayers(2))-4.0);
                }
                else
                {
                    survivors=(float(TeamPlayers(2))-4.0);
                }
            }
        case 1:
            {
                //You're in for a world of hurt, count all survivors
                //Including the original 4
                if(countdeadhook)
                {
                    survivors=(float(AliveTeamPlayers(2)));
                }
                else
                {
                    survivors=(float(TeamPlayers(2)));
                }
            }
        }
        //Are the amount of survivors greater than 0?
        if(RoundFloat(survivors)>0)
        {
            //They are! Continue on!
            //What kind of hp addition are you using?
            switch(hptypehook)
            {
            case 1:
                {
                    //Straight addition! Plain and simple.
                    //Fill the container with the current tank health 
                    //+ the cvar amount times the amount of survivors
                    //if you have 6 survivors without hardmode with an amount of 2000.0:
                    //New health = 6000+(2000*2) == 7200
                    tankhealth = RoundFloat((GetEntProp(client,Prop_Send,"m_iHealth")+(hpaddhook*survivors)));
                }
            case 2:
                {
                    //Multiplication... Baww
                    //Fill the container with the cvar amount
                    //times the survivor count plus 1.0 times the current tank health
                    //if you have 6 survivors without hardmode with an amount of .10:
                    //New health = 6000*[1.0+(.10*2)] == 7200
                    tankhealth = RoundFloat((GetEntProp(client,Prop_Send,"m_iHealth")*(1.0+(hpmultihook*survivors))));
                }
            }
            //Is the newly calculated health is higher than the cap?
            if(tankhealth>65535)
            {
                //Guess so, set it to the cap 
                //(Why is it the cap you ask? I can't remember)
                tankhealth=65535;
            }
            //should we tell the world what
            //our tank's new health is?
            if (announcehook) 
            {
                //Yes, Atleast let them know how hard they're going to die
                PrintToChatAll("New Tank HP: %d (Default: %d)",tankhealth,GetEntProp(client,Prop_Send,"m_iHealth"));
            }
            //Calculations all done! Set his health and maximum health 
            //(To make it show on the hud iirc) to the value of the container
            SetEntProp(client,Prop_Send,"m_iHealth",tankhealth);
            SetEntProp(client,Prop_Send,"m_iMaxHealth",tankhealth);
            //Tell the plugin a tank is alive
            tanklive = 1;
        }
    }
    return;
}

public TeamPlayers(any:team)
{
    //make a container to hold the teamcount
    new int=0;
    for (new i=1; i<=MaxClients; i++)
    {
        //i is lessthan or equal to the maxclients in the game
        //loop through all the clients
        //Are they connected?
        if (!IsClientConnected(i))
        {
            //Yep, now are they ingame?
            if (!IsClientInGame(i))    
            {
                //Yep, now are they on the team you specified?
                if (GetClientTeam(i) != team) 
                {
                    //Lol nope
                    continue;
                }
                else
                {
                    //Yep, increment int
                    int++;
                }
                continue;
            }
            continue;
        }
    }
    //tell whatever called you the value of int
    return int;
}

public AliveTeamPlayers(any:team)
{
    //make a container to hold the teamcount
    new int=0;
    for (new i=1; i<=MaxClients; i++)
    {
        //i is lessthan or equal to the maxclients in the game
        //loop through all the clients
        //Are they connected?
        if (!IsClientConnected(i))
        {
            //Yep, now are they ingame?
            if (!IsClientInGame(i))    
            {
                //Are They Alive?
                if (IsPlayerAlive(i))
                {
                    //Yep, now are they on the team you specified?
                    if (GetClientTeam(i) != team) 
                    {
                        //Lol nope
                        continue;
                    }
                    else
                    {
                        //Yep, increment int
                        int++;
                    }
                    continue;
                }
                continue;
            }
            continue;
        }
    }
    //tell whatever called you the value of int
    return int;
}