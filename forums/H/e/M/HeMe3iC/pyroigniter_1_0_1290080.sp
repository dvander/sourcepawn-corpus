#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define defrad 256

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "Pyro Igniter",
	author = "HeMe3iC",
	description = "Makes pyro ignite enemies near him, when killed",
	version = PLUGIN_VERSION,
};
new g_ExplosionSprite;
new Handle:cvarIgRadius;
new Handle:cvarFF;
new g_IgRadius;
new Bool:g_FF;
public OnPluginStart()
{
	cvarIgRadius = CreateConVar("pi_radius","256","Sets ignition radius",_,true,1.00,true,1024.00);
	cvarFF = CreateConVar("pi_ff","0","Will dying pyro ignite teammates?",_,true,0.00,true,1.00);
	g_IgRadius=GetConVarInt(cvarIgRadius);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookConVarChange(cvarIgRadius, CvarChange);
	HookConVarChange(cvarFF, CvarChange);

	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound( "ambient/explosions/explode_8.wav", true);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar==cvarIgRadius)
	{
		g_IgRadius=StringToInt(newValue);
		//PrintToChatAll("\x03Pyro Igniter Radius changed to %i",g_IgRadius);
	}
	if(convar==cvarFF)
	{	
		if(StringToInt(newValue)==0)
		{
			g_FF=Bool:false;
			//PrintToChatAll("\x05Pyro Igniter FF disabled");
		}
		if(StringToInt(newValue)!=0)
		{
			g_FF=Bool:true;
			//PrintToChatAll("\x04Pyro Igniter FF enabled");
		}
	}
}


public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new dieclient=GetClientOfUserId(GetEventInt(event, "userid"));
	new diekiller=GetClientOfUserId(GetEventInt(event, "attacker"));
	new dieweaponENT=GetEntPropEnt(diekiller, Prop_Send, "m_hActiveWeapon");
	new Float:diepos[3];
	GetEntPropVector(dieclient, Prop_Send, "m_vecOrigin", diepos);
	new dieclass=int:TF2_GetPlayerClass(dieclient);	
	new dieteam=GetClientTeam(dieclient);
	new bool:validweapons;
		
	if(dieweaponENT >= 0)
	{
		new dieweaponind=GetEntProp(dieweaponENT, Prop_Send, "m_iItemDefinitionIndex"); 
		if (dieweaponind != 0 && dieweaponind != 1 && dieweaponind != 2 && dieweaponind != 3 && dieweaponind != 4 && dieweaponind != 5 && dieweaponind != 6 && dieweaponind != 8 && dieweaponind != 17 && dieweaponind != 36 && dieweaponind != 37 && dieweaponind != 38 && dieweaponind != 39 && dieweaponind != 43 && dieweaponind != 44 && dieweaponind != 46 && dieweaponind != 128 && dieweaponind != 132 && dieweaponind != 142 && dieweaponind != 153 && dieweaponind != 154 && dieweaponind != 155 && dieweaponind != 171 && dieweaponind != 172) 
		{
			validweapons=true;
		}	
	}
	
	if (dieclass==7 && validweapons )
	{
		PyroExplode(diepos);
		for (new client=1;client<=MaxClients;client++)
		{
			if (IsValidEdict(client) && IsClientInGame(client) && IsPlayerAlive(client)) 
			{
				new Float:pos[3];
				new team=GetClientTeam(client);
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				new Float:dist=GetVectorDistance(diepos, pos);
				new bool:trace=TraceTargetIndex(dieclient, client, diepos, pos);
				new bool:cond=TF2_HasCond(client,5);
				if (g_FF)
				{
					team=9001;
				}
				if(dist<g_IgRadius && client!=dieclient && dieteam!=team && trace && cond==false)
				{
					TF2_IgnitePlayer(client, dieclient);
				}
			}
		}
	}
}
/////////////////////////////////////////////////
///////////////END OF MAIN PART//////////////////
////////////////////////////////////////////////

public PyroExplode(Float:vec1[3])
{
	EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 0, 750); // 600
	TE_SendToAll();
}
public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}



 stock bool:TraceTargetIndex(client, target, Float:clientLoc[3], Float:targetLoc[3])
{
	targetLoc[2] += 50.0;
	TR_TraceRayFilter(clientLoc, targetLoc, MASK_SOLID_BRUSHONLY,RayType_EndPoint, TraceRayDontHitSelf,client);
	return (!TR_DidHit() || TR_GetEntityIndex() == target);
}
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{        
	return (entity != data);
}

stock bool:TF2_HasCond(client,i)
{
    new pcond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
    return pcond >= 0 ? ((pcond & (1 << i)) != 0) : false;
}
