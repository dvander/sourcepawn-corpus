#include <sourcemod>
#include <sdktools>
#include "SHSource/SHSource_Interface.inc"
new heroID; // SHSource hero ID
new m_BombEnt[MAXPLAYERS+1]; // the bomb model
new m_PlantCount[MAXPLAYERS+1]; // the times they have used bombs this life
new bool:m_WaitingToPlant[MAXPLAYERS+1]; // if they are waiting to plant
new Handle:cvarMaxPlants,Handle:cvarMagnitude; // convars
new bool:m_AllowPlant;
new Float:m_DestLoc[MAXPLAYERS+1][3]; // allows better planting

public OnSHPluginReady()
{
    heroID=SH_CreateHero("Clone Bomber","clonebomber","Drop bombs that look like real players. And then, blow them up on key down.","15","1");
    HookEvent("player_death",PlayerDeathEvent); // blow up bomb if there is one out
    HookEvent("player_spawn",PlayerSpawnEvent); // allow them to do X bombs again
    HookEvent("round_end",RoundEndEvent); // blow up ALL bombs, disallow planting
    HookEvent("round_freeze_end",RoundStartedEvent); // allow planting
    cvarMaxPlants=CreateConVar("cloneb_maxplants","1");
    cvarMagnitude=CreateConVar("cloneb_magnitude","280");
}

public OnSHPrecache()
{
    PrecacheSound("weapons/hegrenade/explode3.wav");
}

public OnSHPlayerAuthed(client)
{
    m_BombEnt[client]=0; // null it
    m_WaitingToPlant[client]=false;
    m_PlantCount[client]=0;
}

public OnClientDisconnect(client)
{
    if(m_BombEnt[client])
        SH_RemoveEntity(m_BombEnt[client]);
    m_BombEnt[client]=0;
    m_WaitingToPlant[client]=false;
    m_PlantCount[client]=0;
}

public OnPowerCommand(client,hero,bool:pressed)
{
    if(pressed&&hero==heroID&&SH_GetHasHero(client,heroID)&&m_AllowPlant)
    {
        // we ONLY care about +power_bomber, also check if they have us
        if(SH_IsAlive(client))
        {
            if(m_BombEnt[client])
                BombExplode(client);
            else
            {
                if(m_PlantCount[client]<GetConVarInt(cvarMaxPlants)&&!m_WaitingToPlant[client])
                {
                    BombPlant(client);
                    m_PlantCount[client]+=1;
                }
            }
        }
    }
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client=GetClientOfUserId(GetEventInt(event,"userid"));
    if(client>0)
    {
        if(m_BombEnt[client])
        {
            SH_RemoveEntity(m_BombEnt[client]);
            m_BombEnt[client]=0;
        }
        m_WaitingToPlant[client]=false;
    }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client=GetClientOfUserId(GetEventInt(event,"userid"));
    if(client>0)
        m_PlantCount[client]=0;
}

public RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new x=1;x<=GetMaxClients();x++)
    {
        if(m_BombEnt[x])
            SH_RemoveEntity(m_BombEnt[x]);
        m_BombEnt[x]=0;
    }
    m_AllowPlant=false;
}

public RoundStartedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    m_AllowPlant=true;
}

BombExplode(client)
{
    // the bomb for the client provided needs to blow up
    if(m_BombEnt[client])
    {
        // that would be bad if we blew up the 0 entity, considering it is world...
        new ent=m_BombEnt[client];
        new Float:origin[3];
        SH_GetOrigin(ent,origin);
        new Float:angle[3]={1.0,1.0,1.0}; // no idea?
        new mag=GetConVarInt(cvarMagnitude);
        new radius=500;
        new Float:exp_force=1300.0;
        SH_CreateExplosion(origin,angle,client,mag,radius,0,exp_force,client);
        EmitSoundToAll("weapons/hegrenade/explode3.wav",client);
        SH_RemoveEntity(ent); // remove the model
        m_BombEnt[client]=0; // null out
    }
}

BombPlant(client)
{
    if(!m_BombEnt[client])
    {
        // make sure we aren't creating 2 bombs
        new Float:vel[3];
        SH_GetVelocity(client,vel);
        vel[2]+=500.0;
        SH_SetVelocity(client,vel);
        SH_GetOrigin(client,m_DestLoc[client]);
        m_WaitingToPlant[client]=true;
        CreateTimer(0.2,DoPlant,client);
    }
}

public Action:DoPlant(Handle:timer,any:client)
{
    m_WaitingToPlant[client]=false;
    if(SH_GetHasHero(client,heroID)&&!m_BombEnt[client]&&SH_IsAlive(client))
    {
	  new String:pmodels[30];
	  GetClientModel(client, pmodels, 30);
        new ent=SH_CreateEntity("prop_physics");
        SH_SetModel(ent,pmodels);
        SH_SetOrigin(ent,m_DestLoc[client]);
        SH_SpawnEntity(ent);
        m_BombEnt[client]=ent;
    }
}