#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define SEDUCEME_LENGTH 1.5 // Length of the Seduce Me soundbite, not sure how long it is
#define MAX_FILE_LEN 100 // File path restriction
#define COOLDOWN 2.0 // Cooldown period between between phrases, so to avoid spam

new Handle:CooldownTimers[MAXPLAYERS+1] = INVALID_HANDLE;
new bool:isMedic[MAXPLAYERS+1] = false;
new g_Radius = 50; // Radius that is adequate for the 'later' response
new String:soundPath[] = "later_plugin/LetsGoPracticeMedicine.wav"; // I put it in the \download\sound\ folder on the server

public OnMapStart()
{
    decl String:filename[MAX_FILE_LEN];
    
    // Precaching the sound
    PrecacheSound(soundPath, true);
    
    // Adding it to the download table
    Format(filename, MAX_FILE_LEN, "sound/%s", soundPath);
    AddFileToDownloadsTable(filename);
}

public OnPluginStart()
{
    AddCommandListener(MedicCall, "voicemenu"); // Listening to MEDIC! command
    HookEvent("player_changeclass", Event_ChangeClass);
}

public Action:MedicCall(client, String:command[], args)
{
    decl String:buffer[2];
    
    GetCmdArg(1, buffer, sizeof(buffer));
    if (StringToInt(buffer) == 0)
    {
        GetCmdArg(2, buffer, sizeof(buffer));
        if (StringToInt(buffer) == 0)
            CheckConditions(client); // Checking other conditions when called for Medic
    }

    return Plugin_Continue;
}

public CheckConditions(client)
{    
    if ( (TF2_GetPlayerClass(client) == TFClass_Spy) && (!TF2_IsPlayerInCondition(client, TFCond_Disguised)) ) // Spy called for Medic and is not currently disguised
    {
        new Float:pos_Spy[3], Float:pos_Med[3];
        for (new i = 1; i < MAXPLAYERS; i++) // Scan for any Medics, friendly or not
        {
            if (isMedic[i] && IsPlayerAlive(i) && IsPlayerAlive(client) && (CooldownTimers[i] == INVALID_HANDLE) )
            {
                GetClientEyePosition(client, pos_Spy);
                GetClientEyePosition(client, pos_Med);
                
                if (GetVectorDistance(pos_Spy, pos_Med, false) <= g_Radius) // Medic is in the radius, play the sound
                {
                    CreateTimer(SEDUCEME_LENGTH, Play_Later, i);
                    CooldownTimers[i] = CreateTimer(SEDUCEME_LENGTH + COOLDOWN, RefreshCooldown, i); // Creating a cooldown timer to prevent spam
                    break;
                }
            }
        }
    }
}

public Event_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new class = GetEventInt(event, "class");
    
    if (class == 5) // Player changed to Medic
    {
        isMedic[client] = true;
    }
    else // Player not a medic anymore
    {
        if (isMedic[client])
            isMedic[client] = false;
    }
}

public Action:Play_Later(Handle:timer, any:client)
{
    if (IsPlayerAlive(client) && isMedic[client])
    {
        new Float:pos[3], Float:ang[3];
        GetClientEyePosition(client, pos);
        GetClientEyeAngles(client, ang);
        EmitSoundToAll(soundPath, client, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos, ang, true, 0.0);
    }
}

public Action:RefreshCooldown(Handle:timer, any:i)
{
    CooldownTimers[i] = INVALID_HANDLE;
}