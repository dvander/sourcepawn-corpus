/* Telemetry
* Author: STREETFIGHTER 2
* Description: Shows player velocity, acceleration, distance, average speed as well as max speed and max acceleration
* Some Code Ripped From: Bailopan, Soccerdude, ]SoD[ Frostbyte, Nican132, and more
* Notes: Commented lines with code can be uncommented and used to emitsound on a player when they exceed a certain speed.
*/

#pragma semicolon 1

#include <sourcemod>

// This include is only needed if you want to play a sound when the player reaches a certain speed
//#include <sdktools>

#define PLUGIN_VERSION "1.1"

new VelocityOffset_0;
new VelocityOffset_1;
new VelocityOffset_2;

new previous_velocity[MAXPLAYERS + 1] = 0;
new distance[MAXPLAYERS + 1] = 0;
new data_points[MAXPLAYERS+1]=0;

new best_speed[MAXPLAYERS + 1]=0;
new best_accel[MAXPLAYERS + 1]=0;

new Handle:speedtimer;
new Handle:senabled;
new Handle:pollrate;
new Handle:factor;
new Handle:advert;
new Handle:announce;
new Handle:allowspecs;
new Handle:units;

//These are used if you want to play a sound when the player reaches a certain speed
//new Handle:leetspeed;
//new hit_leet_speed[MAXPLAYERS + 1] = 0;

public Plugin:myinfo = 
{
     name = "Telemetry",
     author = "STREETFIGHTER 2",
     description = "Shows player velocity, acceleration and distance",
     version = PLUGIN_VERSION,
     url = "http://sourcemod.net/"
};

public OnPluginStart()
{
    //Set offsets now so we don't need to constantly recalculate them
    VelocityOffset_0=FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    if(VelocityOffset_0==-1)
        SetFailState("[Telemetry] Error: Failed to find Velocity[0] offset, aborting");
    VelocityOffset_1=FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
    if(VelocityOffset_1==-1)
        SetFailState("[Telemetry] Error: Failed to find Velocity[1] offset, aborting");
    VelocityOffset_2=FindSendPropOffs("CBasePlayer","m_vecVelocity[2]");
    if(VelocityOffset_2==-1)
        SetFailState("[Telemetry] Error: Failed to find Velocity[2] offset, aborting");

    //Create cvars
    CreateConVar("sm_telemetry_version", PLUGIN_VERSION, "Telemetry plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    senabled=CreateConVar("sm_telemetry_enabled","1","Enable or disable client telemetry",FCVAR_PLUGIN, true, 0.0, true, 1.0);
    pollrate=CreateConVar("sm_telemetry_pollrate","0.4","Time in seconds between player velocity pollings",FCVAR_PLUGIN, true, 0.1);
    factor=CreateConVar("sm_telemetry_factor","37","Divisor which converts Source units of speed to MPH [Units/factor]",FCVAR_PLUGIN, true, 1.0, false);
    announce=CreateConVar("sm_telemetry_announce","2","2: sends speedstats info to all, 1: sends speedstats info only to client, 0: disable",FCVAR_PLUGIN, true, 0.0, true, 2.0);
    allowspecs=CreateConVar("sm_telemetry_allowspecs","1","1: allows spectator telemetry, 0: disables spectator telemetry",FCVAR_PLUGIN, true, 0.0, true, 1.0);
    units=CreateConVar("sm_telemetry_units","2","2: velocity and distance in standard, 1: all units metric, 0: show both standard and metric",FCVAR_PLUGIN, true, 0.0, true, 2.0);

    //Used only for advertising Telemetry plugin (remove it if you don't like adverts)
    advert=CreateConVar("sm_telemetry_advert","1","Enables (1) or disbables (0) advertising Telemetry plugin",FCVAR_PLUGIN, true, 0.0, true, 1.0);
    HookEvent("player_activate",activating);

    //This is only needed if you want to play a sound when the player reaches a certain speed
    //leetspeed=CreateConVar("sm_telemetry_leetspeed","110","Speed (in MPH) which triggers an emitsound",FCVAR_PLUGIN, true, 1.0, false);

    HookConVarChange(pollrate, TimerChanged);
    HookConVarChange(senabled, TimerChanged);   
    
    RegConsoleCmd("say", Command_Say);
    
    CreateTimers();
}

stock CreateTimers() {    
    if(speedtimer != INVALID_HANDLE) {
        KillTimer( speedtimer );
        speedtimer = INVALID_HANDLE;
    }
    if (GetConVarInt(senabled))
    {
        speedtimer = CreateTimer(GetConVarFloat(pollrate),ShowSpeedo,0, TIMER_REPEAT);
    }
}

public TimerChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
    CreateTimers();
}

public Action:ShowSpeedo(Handle:timer,any:useless)
{
    //array index var(s) that prevent re-indexing (results in better performance)
    new previousvelocityc;

    for(new client = 1; client<= MaxClients; client++) {    
        if ((IsClientInGame(client) && !IsFakeClient(client)) && (IsPlayerAlive(client) || GetConVarInt(allowspecs)))
        {
            //prevent re-indexing arrays (which are used more than twice)
            previousvelocityc=previous_velocity[client];

            //absolute velocity in miles per hour (MPH)
            new Float:x=GetEntDataFloat(client,VelocityOffset_0);
            new Float:y=GetEntDataFloat(client,VelocityOffset_1);
            new Float:z=GetEntDataFloat(client,VelocityOffset_2);
            new resultant=RoundFloat(SquareRoot(Pow(x,2.0)+Pow(y,2.0)+Pow(z,2.0)));
            resultant=resultant/GetConVarInt(factor);
            
            //instantaneous acceleration in gravitys [9.8m/s/s] (G)
            new Float:interval = GetConVarFloat(pollrate);
            new Float:acceleration=((5280.0/3600.0)*(resultant-previousvelocityc))/interval;
            acceleration=acceleration/32.15;

            //distance traveled in miles (M) (stored in feet to prevent needing a global float array)
            new dist_inc=RoundFloat((interval/3600.0)*(5280.0*(resultant+previousvelocityc)/2.0));
            distance[client]+=dist_inc;

            //current velocity becomes previous velocity
            previous_velocity[client]=resultant;

            //Ignore idle data when computing average speed
            if (resultant>0)
            {
                data_points[client]+=1;
            }

            //Send it to the client
            switch (GetConVarInt(units))
            {
                case 2:
                {
                    PrintHintText(client, "%3d MPH\n%4.2f G\nAVG: %1.1f MPH", resultant, acceleration, (3600*distance[client]/5280.0)/(data_points[client]*interval));
                }
                case 1:
                {
                    PrintHintText(client, "%1.0f KPH\n%4.2f G\nAVG: %1.1f KPH", resultant*1.6, acceleration, (3600*distance[client]/3280.0)/(data_points[client]*interval));
                }
                case 0:  //This case takes a performance hit because arrays are re-indexed
                {
                    PrintHintText(client, "%3d MPH (%1.0f KPH)\n%4.2f G\nAVG: %1.1f MPH (%1.1f KPH)", resultant, resultant*1.6, acceleration, (3600*distance[client]/5280.0)/(data_points[client]*interval), (3600*distance[client]/3280.0)/(data_points[client]*interval));
                }
            }

            //update stats
            if (best_accel[client] < (RoundFloat(acceleration*100)))
            {
                best_accel[client] = (RoundFloat(acceleration*100)); //multiply by 100 to allow 2 decimal precision and still store it as an Integer
            }
            if (best_speed[client] < resultant)
            {
                best_speed[client] = resultant;
            }

            /* Play a sound if they're exceeding a certain speed    
            if ((resultant >= GetConVarInt(leetspeed)) && (!hit_leet_speed[client]))
            {
                hit_leet_speed[client]=1;
                EmitSoundToAll("misc/mfweee.mp3", client);
                CreateTimer(10.0,RevertLeetSpeed,client);
            }
            */
        }
    }
    return Plugin_Continue;
}

public Action:Command_Say(userid, args)
{
    if (!userid || !GetConVarInt(senabled))
        return Plugin_Continue;
    
    decl String:text[192];        // from rockthevote.sp
    if (!GetCmdArgString(text, sizeof(text)))
        return Plugin_Continue;
    
    new startidx = 0;
    
    // Strip quotes from argument
    if (text[strlen(text)-1] == '"')
    {
        text[strlen(text)-1] = '\0';
        startidx = 1;
    }
    
    if (strcmp(text[startidx], "speedreset", false) == 0)
    {
        previous_velocity[userid] = 0;
        distance[userid] = 0;
        best_speed[userid] = 0;
        best_accel[userid] = 0;
        data_points[userid] = 0;
        PrintToChat(userid, "\x01[\x04Telemetry\x01] Reset successful!");
    }
    
    new announcing=GetConVarInt(announce);
    if ((strcmp(text[startidx], "speedstats", false) == 0) && (announcing>0))
    {
        if (announcing==1)
        {
            switch (GetConVarInt(units))
            {
                case 2:
                {
                    PrintToChat(userid, "\x01You reached \x04%d MPH\x01, \x04%0.2f Gs\x01 and traveled \x04%0.2f miles\x01!", best_speed[userid], best_accel[userid]/100.0, distance[userid]/5280.0);
                }
                case 1:
                {
                    PrintToChat(userid, "\x01You reached \x04%1.0f KPH\x01, \x04%0.2f Gs\x01 and traveled \x04%0.2f km\x01!", best_speed[userid]*1.6, best_accel[userid]/100.0, distance[userid]/3280.0);
                }
                case 0:
                {
                    PrintToChat(userid, "\x01You reached \x04%d MPH\x01 (\x04%1.0f KPH\x01), \x04%0.2f Gs\x01 and traveled \x04%0.2f miles\x01 (\x04%0.2f km\x01)!", best_speed[userid], best_speed[userid]*1.6, best_accel[userid]/100.0, distance[userid]/5280.0, distance[userid]/3280.0);
                }
            }
        }
        else
        {
            decl String:pname[64];
            decl String:ctext[256];
            GetClientName(userid, pname, sizeof(pname));
            switch (GetConVarInt(units))
            {
                case 2:
                {
                    Format(ctext, sizeof(ctext),"\x01Player \x03%s\x01 reached \x04%d MPH\x01, \x04%0.2f Gs\x01 and traveled \x04%0.2f miles\x01!", pname, best_speed[userid], best_accel[userid]/100.0, distance[userid]/5280.0);
                }
                case 1:
                {
                    Format(ctext, sizeof(ctext),"\x01Player \x03%s\x01 reached \x04%1.0f KPH\x01, \x04%0.2f Gs\x01 and traveled \x04%0.2f km\x01!", pname, best_speed[userid]*1.6, best_accel[userid]/100.0, distance[userid]/3280.0);
                }
                case 0:
                {
                    Format(ctext, sizeof(ctext),"\x01Player \x03%s\x01 reached \x04%d MPH\x01 (\x04%1.0f KPH\x01), \x04%0.2f Gs\x01 and traveled \x04%0.2f miles\x01 (\x04%0.2f km\x01)!", pname, best_speed[userid], best_speed[userid]*1.6, best_accel[userid]/100.0, distance[userid]/5280.0, distance[userid]/3280.0);
                }
            }
            ColoredToAll(userid, ctext);
        }
    }
    
    return Plugin_Continue;
}

public Action:Emote(Handle:timer,any:client)
{
    if (!client || !IsClientInGame(client))
    {
        return Plugin_Stop;
    }
    
    if (GetConVarInt(announce)==0)
    {
        PrintToChat(client, "\x01[\x04Telemetry\x01] Type '\x03speedreset\x01' to reset your data'");
    }
    else
    {
        PrintToChat(client, "\x01[\x04Telemetry\x01] Type '\x03speedstats\x01' for extra speed statistics and '\x03speedreset\x01' to reset your data'");
    }

    return Plugin_Stop;
}

public Action:activating(Handle:event,String:name[], bool:dontBroadcast)
{
    if (GetConVarInt(advert) && GetConVarInt(senabled))
    {
        new client = GetClientOfUserId(GetEventInt(event,"userid"));  
        CreateTimer(30.0,Emote,client);
    }
    return Plugin_Continue;
}

public OnEventShutdown()
{
    UnhookEvent("player_activate",activating);
}

public OnClientDisconnect(client)
{
    previous_velocity[client] =0;
    distance[client]=0;
    best_speed[client]=0;
    best_accel[client]=0;
    data_points[client]=0;
    //This is only needed if you want to play a sound when the player exceeds a certain speed
    //hit_leet_speed[client] = 0;
}

ColoredToAll(client, const String:message[])
{
    new maxclients = GetMaxClients();
    for(new i = 1; i <= maxclients; i++)
    {
        if(IsClientInGame(i) && !IsFakeClient(i))
        {
            SayText2(i, client, message);
        }
    }
}

// CREDITS TO DJTSUNAMI FOR THIS
public SayText2(to, from, const String:message[])
{
    new Handle:hBf = StartMessageOne("SayText2", to);
    
    BfWriteByte(hBf, from);
    BfWriteByte(hBf, true);
    BfWriteString(hBf, message);
    
    EndMessage();
}

/* This part is only needed if you want to play a sound when the player reaches a certain speed
public OnMapStart(){
    InitPrecache();    
}

InitPrecache(){
    AddFileToDownloadsTable("sound/misc/mfweee.mp3");
    PrecacheSound("misc/mfweee.mp3", true);    PrefetchSound("misc/mfweee.mp3");
}

public Action:RevertLeetSpeed(Handle:timer,any:client)
{
    hit_leet_speed[client]=0;
    return Plugin_Stop;
}
*/
