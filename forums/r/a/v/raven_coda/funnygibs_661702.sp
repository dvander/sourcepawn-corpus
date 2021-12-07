#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0.1"


public Plugin:myinfo = {
	name = "Funny Gibs",
	author = "Raven Coda",
	description = "Show funny gibs",
	version = PLUGIN_VERSION,
	url = "http://www.tf2clue.com/"
};

static String:GibName[19][45] = 
{
	"models/player/gibs/gibs_balloon.mdl",
	"models/player/gibs/gibs_bolt.mdl",
	"models/player/gibs/gibs_boot.mdl",
	"models/player/gibs/gibs_burger.mdl",
	"models/player/gibs/gibs_can.mdl",
	"models/player/gibs/gibs_clock.mdl",
	"models/player/gibs/gibs_duck.mdl",
	"models/player/gibs/gibs_fish.mdl",
	"models/player/gibs/gibs_gear1.mdl",
	"models/player/gibs/gibs_gear2.mdl",
	"models/player/gibs/gibs_gear3.mdl",
	"models/player/gibs/gibs_gear4.mdl",
	"models/player/gibs/gibs_gear5.mdl",
	"models/player/gibs/gibs_hubcap.mdl",
	"models/player/gibs/gibs_licenseplate.mdl",
	"models/player/gibs/gibs_spring1.mdl",
	"models/player/gibs/gibs_spring2.mdl",
	"models/player/gibs/gibs_teeth.mdl",
	"models/player/gibs/gibs_tire.mdl"
};

new moff;

public OnPluginStart() 
{ 
  moff = FindSendPropOffs("CBaseEntity", "m_clrRender");
  if (moff == -1)
     SetFailState("Could not find \"m_clrRender\" moff");

	
  // events
  HookEvent("player_death",PlayerDeath);
  
  // convars 
  SetConVarBool(FindConVar("tf_playergib"),false);
  CreateConVar("funnygibs_version", PLUGIN_VERSION, "Funny_GIbs", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
}

public OnMapStart()
{
	for (new i=0; i<19; i++)
		{PrecacheModel(GibName[i], true);}
}



public OnEventShutdown()
{
	UnhookEvent("player_death",PlayerDeath);
}



public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl client, attacker;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new String:weaponName[32];
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	if ( ((StrContains(weaponName, "sentrygun", false)>-1) && Lvl3Sentry(attacker)) ||
		(StrContains(weaponName, "pipe", false)>-1)	||
		(StrContains(weaponName, "rocket", false)>-1) ||
		(StrContains(weaponName, "deflect", false)>-1))
	{
		CreateTimer(0.1, RemoveRagdoll, client);
		ReplaceGibs(client, attacker, 10);
	}

	return Plugin_Continue;
}

public Action:RemoveRagdoll(Handle:Timer, any:client)
{
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll>0)
	  {
		SetEntPropEnt(client, Prop_Send, "m_hRagdoll", -1);
		RemoveEdict(ragdoll);	
	  }
	else
	  {
		LogError("Could not find ragdoll");
	  }
}


public Lvl3Sentry(any:client)
{
	new entity=-1;
	while ((entity = FindEntityByClassname(entity, "obj_sentrygun")) != -1)
		if (GetEntDataEnt2(entity, FindSendPropInfo("CBaseObject", "m_hBuilder")) == client)
			return (GetEntProp(entity, Prop_Send, "m_iUpgradeLevel") ==3);
	return false;
}

stock Action:ReplaceGibs(any:client, any:attacker, count =1)
{
  if (!IsValidEntity(client))
  {
    LogError("Could not find Client");  
    return;
  }
  
  //Shuffle
  new ord[19];
  for (new j=0; j<19 ;j++)
	ord[j]=j;
  for (new j=0; j<17; j++)
  {
	new n = GetRandomInt(j, 18);
	new t=ord[j];
	ord[j]=ord[n];
	ord[n]=t;
  }
  decl Float:pos[3];
  GetClientAbsOrigin(client, pos);
  ShowParticle(pos, "blood_trail_red_01_goop", 5.0);
  
  for(new i = 0; i < count; i++)
  {
	 new gib =  CreateEntityByName("prop_physics");
	 decl CollisionOffset;
	 DispatchKeyValue(gib, "model", GibName[ord[i]]);
	 if (DispatchSpawn(gib))
	 {
		 CollisionOffset = GetEntSendPropOffs(gib, "m_CollisionGroup");
		 if(IsValidEntity(gib)) SetEntData(gib, CollisionOffset, 1, 1, true);
		 new Float:vel[3];
		 vel[0]=GetRandomFloat(-300.0, 300.0);
		 vel[1]= GetRandomFloat(-300.0, 300.0);
		 vel[2] = GetRandomFloat(100.0, 300.0);
		 TeleportEntity(gib, pos, NULL_VECTOR, vel);
		 AttachParticle(gib, "lowV_oildroplets", 2.0);
		 CreateTimer(15.0, RemoveGib, gib);
	 }
	 else
	 {
		LogError("Could not create gib");
	 }
   }
	

}  

//Remove Gib:
public Action:RemoveGib(Handle:Timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		CreateTimer(0.1, fadeout, ent, TIMER_REPEAT);
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	}
}

public Action:fadeout(Handle:Timer, any:ent)
{
    if (!IsValidEntity(ent))
    {
        KillTimer(Timer);
        return;
    }

    new alpha = GetEntData(ent, moff + 3, 1);
    if (alpha - 25 <= 0)
    {
        RemoveEdict(ent);
        KillTimer(Timer);
    }
    else
    {
        SetEntData(ent, moff + 3, alpha - 25, 1, true);
    }
}  



public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, particle);
    }
    else
    {
        LogError("ShowParticle: could not create info_particle_system");
    }    
}



AttachParticle(ent, String:particleType[], Float:time)
{
	decl String:tName[64];
	new particle = CreateEntityByName("info_particle_system");
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
