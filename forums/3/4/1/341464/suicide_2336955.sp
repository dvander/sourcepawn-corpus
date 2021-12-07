#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <morecolors>
#define PLUGIN_VERSION "1.04"

// new spamFilter[MAXPLAYERS+1];

ConVar g_deathAnnounce;
ConVar g_deathRagdoll;
ConVar g_deathRagdollEx;
ConVar g_ragdollBurn;
ConVar g_ragdollCloak;
ConVar g_ragdollElectrocute;
ConVar g_ragdollGold;
ConVar g_ragdollIce;
ConVar g_ragdollAsh;

public Plugin myinfo =
{
	name = "Suicide Events",
	author = "Still",
	description = "Add some fun in suiciding?",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

// public OnClientDisconnect_Post(client)
// {
//     spamFilter[client] = 0;
// }

// public OnClientPutInServer(client)
// {
//     spamFilter[client] = 0;
// }

public void OnPluginStart()
{
    TF2only();
	RegConsoleCmd("sm_suicide", Command_Kill, "Suicide, what a cruel world, eh?");
    RegConsoleCmd("sm_killme", Command_Kill, "Suicide, what a cruel world, eh?");
    RegConsoleCmd("kill", Command_Kill, "Suicide, what a cruel world, eh?");
    RegConsoleCmd("sm_explodeme", Command_Explode, "Explode into pieces?");
	RegConsoleCmd("explode", Command_Explode, "Explode into pieces?");
    g_deathAnnounce = CreateConVar("sm_suicide_announce", "0", "Should the plugin announce suicide events?", _, true, _, true, 1.0);
    g_deathRagdoll = CreateConVar("sm_death_ragdoll", "1", "Should the ragdoll be changed?", _, true, _ , true, 1.0);
    g_deathRagdollEx = CreateConVar("sm_death_ragdoll_exaggerate", "1", "Should the ragdoll exaggerate?", _, true, _ , true, 1.0);
    g_ragdollBurn = CreateConVar("sm_death_ragdoll_burn", "1", "Should the ragdoll burn?", _, true, _ , true, 1.0);
    g_ragdollCloak =  CreateConVar("sm_death_ragdoll_cloak", "0", "Should the ragdoll be cloaked?", _, true, _ , true, 1.0);
    g_ragdollElectrocute = CreateConVar("sm_death_ragdoll_shock", "1", "Should the ragdoll be electrocuted?", _, true, _ , true, 1.0);
    g_ragdollGold = CreateConVar("sm_death_ragdoll_gold", "0", "Should the ragdoll be golden?", _, true, _ , true, 1.0);
    g_ragdollIce = CreateConVar("sm_death_ragdoll_ice", "0", "Should the ragdoll be frozen?", _, true, _ , true, 1.0);
    g_ragdollAsh = CreateConVar("sm_death_ragdoll_ash", "0", "Should the ragdoll become ash?", _, true, _ , true, 1.0);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    if (IsValidClient(client) && IsValidClient(attacker))
    {
        if (GetConVarInt(g_deathAnnounce) && attacker == client)
        {
            Announce_Suicide(client, true);
        }
        if (CheckCommandAccess(client, "ragdoll_fx", ADMFLAG_GENERIC) || CheckCommandAccess(attacker, "ragdoll_fx", ADMFLAG_GENERIC) )
        {
            if (GetConVarInt(g_deathRagdoll))
            {
                CreateTimer(0.0, RemoveBody, client);

                new vteam = GetClientTeam(client);
                new vclass = TF2_GetPlayerClass(client);
                decl Ent;
                Ent = CreateEntityByName("tf_ragdoll");
                
                if (GetConVarInt(g_deathRagdollEx))
                {
                    new Float:Vel[3];
                    Vel[0] = -180000.552734;
                    Vel[1] = -18000.552734;
                    Vel[2] = 800000.552734;
                    
                    SetEntPropVector(Ent, Prop_Send, "m_vecRagdollVelocity", Vel);
                    SetEntPropVector(Ent, Prop_Send, "m_vecForce", Vel);
                }

                decl Float:ClientOrigin[3];
                
                SetEntPropVector(Ent, Prop_Send, "m_vecRagdollOrigin", ClientOrigin); 
                SetEntProp(Ent, Prop_Send, "m_iPlayerIndex", client);
                SetEntProp(Ent, Prop_Send, "m_iTeam", vteam);
                SetEntProp(Ent, Prop_Send, "m_iClass", vclass);
                if (GetConVarInt(g_ragdollBurn)) {SetEntProp(Ent, Prop_Send, "m_bBurning", 1);}
                if (GetConVarInt(g_ragdollCloak)) {SetEntProp(Ent, Prop_Send, "m_bCloaked", 1);}
                if (GetConVarInt(g_ragdollElectrocute)) {SetEntProp(Ent, Prop_Send, "m_bElectrocuted", 1);}
                if (GetConVarInt(g_ragdollAsh)) {SetEntProp(Ent, Prop_Send, "m_bBecomeAsh", 1);}
                if (GetConVarInt(g_ragdollIce)) {SetEntProp(Ent, Prop_Send, "m_bIceRagdoll", 1);}
                if (GetConVarInt(g_ragdollGold)) {SetEntProp(Ent, Prop_Send, "m_bGoldRagdoll", 1);}
                SetEntProp(Ent, Prop_Send, "m_nForceBone", 1);

                DispatchSpawn(Ent);
                
                CreateTimer(5.0, RemoveRagdoll, Ent);

                //decl String:deathsound[64] = "custom\\ded";
                //new randomint = GetRandomInt(0, 2);
                //switch (randomint)
                //{
                //    case 0:
                //        Format(deathsound, sizeof(deathsound), "%s.mp3", deathsound);
                //    default:
                //        Format(deathsound, sizeof(deathsound), "%s%i.mp3" , deathsound, randomint);
                //}
                //for (new i = 1; i <= MaxClients; i++)
                //{
                //    ClientCommand(i, "playgamesound %s", deathsound);
                //    decl String:clientname[64];
                //    GetClientName(i, clientname, sizeof(clientname));
                //    PrintToServer("Played %s on %s.", deathsound, clientname);
                //}
            }
        }
    }
    return Plugin_Continue;
}
stock Announce_Suicide(client, bool:kill=true)
{
    decl String:clientname[64];
    GetClientName(client, clientname, sizeof(clientname));
    if (kill)
    {
        CPrintToChatAll("[{indianred}Suicide{default}] Oh no! {lightskyblue}%s{default} just killed himself!", clientname);
    }
    else //what if the kill was not kill (kek)
    {
        CPrintToChatAll("[{indianred}Suicide{default}] {lightskyblue}%s{default} just exploded! RIP.", clientname);
    }
}
public Action:Command_Explode(client, args)
{
    if (client == 0){PrintToServer("[SM] Sorry, Mom. This command doesn't work in server console."); return Plugin_Handled;}
    if (IsValidClient(client) && IsPlayerAlive(client))
    {
        //if (spamFilter[client]){CReplyToCommand(client, "[{indianred}Suicide{default}] You are spamming this command! Stop!" , any:...)}
        //FakeClientCommandEx(client, "explode");

        CreateTimer(0.0, RemoveBody, client);
        decl Ent;
        Ent = CreateEntityByName("tf_ragdoll");
        decl Float:ClientOrigin[3];
        SetEntPropVector(Ent, Prop_Send, "m_vecRagdollOrigin", ClientOrigin)
        SetEntProp(Ent, Prop_Send, "m_iPlayerIndex", client)
        if (GetConVarInt(g_deathRagdollEx))
        {
            new Float:Vel[3];
            Vel[0] = -180000.552734;
            Vel[1] = -18000.552734;
            Vel[2] = 800000.552734;
            
            SetEntPropVector(Ent, Prop_Send, "m_vecRagdollVelocity", Vel);
            SetEntPropVector(Ent, Prop_Send, "m_vecForce", Vel);
        }
        else
        { 
            SetEntPropVector(Ent, Prop_Send, "m_vecForce", NULL_VECTOR)
            SetEntPropVector(Ent, Prop_Send, "m_vecRagdollVelocity", NULL_VECTOR)
        }
        SetEntProp(Ent, Prop_Send, "m_bGib", 1)

        DispatchSpawn(Ent);
        CreateTimer(5.0, RemoveRagdoll, Ent);

        if (GetConVarInt(g_deathAnnounce)){Announce_Suicide(client, false);}
        //spamFilter[client] = 1;
        //CreateTimer(10.0, SpamPrevention, client);

        if (CheckCommandAccess(client, "explode_fx", ADMFLAG_GENERIC))
        {
            AttachParticle(client,"cinefx_goldrush" , 6);
            EmitSoundToAll("items/cart_explode.wav", _, _, _, _, 0.25);
        }
    }
    return Plugin_Handled;
}
public Action:Command_Kill(client, args)
{
    if (client == 0){PrintToServer("[SM] Sorry, Mom. This command doesn't work in server console."); return Plugin_Handled;}
	if (IsValidClient(client) && IsPlayerAlive(client))
    {
        ForcePlayerSuicide(client);
        // spamFilter[client] = 1;
        // CreateTimer(10.0, SpamPrevention, client);
    }
    return Plugin_Handled;
}
stock IsValidClient(client, bool:replaycheck = true)
{
    if(client <= 0 || client > MaxClients)
    {
        return false;
    }
    if(!IsClientInGame(client))
    {
        return false;
    }
    if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
    {
        return false;
    }
    if(replaycheck)
    {
        if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
    }
    return true;
} 

// public Action:SpamPrevention(Handle:Timer, any:Client)
// {
//     if (IsValidClient(Client) && spamFilter[Client])
//     {
//         spamFilter[Client] = 0;
//     }
// }
public Action:RemoveBody(Handle:Timer, any:Client)
{
    decl BodyRagdoll;
    BodyRagdoll = GetEntPropEnt(Client, Prop_Send, "m_hRagdoll");
    
    if(IsValidEdict(BodyRagdoll))
    {
        AcceptEntityInput(BodyRagdoll, "kill");
    }
}

public Action:RemoveRagdoll(Handle:Timer, any:Ent)
{
    if(IsValidEntity(Ent))
    {
        decl String:Classname[64];
        GetEdictClassname(Ent, Classname, sizeof(Classname));
        if(StrEqual(Classname, "tf_ragdoll", false))
        {
            AcceptEntityInput(Ent, "kill");
        }
    }
}
stock AttachParticle(ent, String:particleType[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");

    decl String:tName[32];

    if (IsValidEdict(particle))
    {
        new Float:pos[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
        DispatchKeyValue(particle, "targetname", "tf2particle");
        DispatchKeyValue(particle, "parentname", tName);
        DispatchKeyValue(particle, "effect_name", particleType);
        DispatchSpawn(particle);
        SetVariantString(tName);
        AcceptEntityInput(particle, "SetParent", particle, particle, 0);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, particle);
    }
    else
    {
        LogError("AttachParticle: could not create info_particle_system");
    }
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[64];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
        else
        {
            LogError("DeleteParticles: not removing entity - not a particle '%s'", classname);
        }
    }
}
TF2only()
{
    decl String:Game[10];
    GetGameFolderName(Game, sizeof(Game));
    if(!StrEqual(Game, "tf"))
    {
        SetFailState("[SM] Please remove this plugin, it only works for Team Fortress 2.");
    }
}
