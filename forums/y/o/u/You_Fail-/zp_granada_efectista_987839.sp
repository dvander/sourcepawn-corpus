/*
	Special Effects /// By You Fail///
		
		This Will Give Grenade Explosions And Bullet Impacts Cool Fx
		
		Avalailable Effects:
		
		1. Sparks
		2. Glow Effect
		3. Energy Splash
		
*/

#include <sourcemod>
#include <sdktools>

#define VERSION "0.2"

new Handle:gSwitch;
new Handle:HeNade;
new Handle:Smoke;
new Handle:Flash;
new Handle:Slug;
new Float:Origin[3];
new Glow;

public Plugin:myinfo = 
{
	name = "Special Effects",
	author = "You Fail",
	description = "Gives Special Effects ",
	version = VERSION,
	url = "www.sourcemod.net"
};

// set cvars and hook nade detonation events

public OnMapStart()
{
	Glow = PrecacheModel("sprites/blueglow1.vmt");
}

public OnPluginStart()
{
	gSwitch = CreateConVar("nade_fx_on","1","1 tuns the plugin on 0 is off",FCVAR_NOTIFY);
	HeNade = CreateConVar("he_nade_fx","1","Sets The Mode Of The HE Fx",FCVAR_NOTIFY);
	Smoke = CreateConVar("sg_nade_fx","1","sets The Mode Of The Smoke Nade",FCVAR_NOTIFY);
	Flash = CreateConVar("fb_nade_fx","1","sets the mode of the flash bang",FCVAR_NOTIFY);
	Slug = CreateConVar("slug_fx","1","sets the mode of the slug fx",FCVAR_NOTIFY);
	
	HookEvent("hegrenade_detonate",HeExplode);
	HookEvent("flashbang_detonate",FbExplode);
	HookEvent("smokegrenade_detonate",SgExplode);
	HookEvent("bullet_impact",SlugImpact);
}

//  catch the x,y,and z of the he nade and do effects based on convar

public HeExplode(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetConVarInt(gSwitch))
	{
		Origin[0] = GetEventFloat(event,"x");
		Origin[1] = GetEventFloat(event,"y");
		Origin[2] = GetEventFloat(event,"z");
	
		if(GetConVarInt(HeNade)== 1)
		{
			TE_SetupSparks(Origin,Origin,255,1);
			TE_SendToAll();
		}else if( GetConVarInt(HeNade)== 2)
		{
			TE_SetupGlowSprite(Origin,Glow,1.0,1.0,20);
			TE_SendToAll();
		}else if (GetConVarInt(HeNade)== 3)
		{
			TE_SetupEnergySplash(Origin,Origin,false);
			TE_SendToAll();
		}
	}
}

// catch x,y,z of the flashbang nade and do effects based on convar

public FbExplode(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetConVarInt(gSwitch))
	{
		Origin[0] = GetEventFloat(event,"x");
		Origin[1] = GetEventFloat(event,"y");
		Origin[2] = GetEventFloat(event,"z");
	
		if(GetConVarInt(Flash)== 1)
		{
			TE_SetupSparks(Origin,Origin,255,1);
			TE_SendToAll();
		}else if( GetConVarInt(Flash)== 2)
		{
			TE_SetupGlowSprite(Origin,Glow,1.0,1.0,20);
			TE_SendToAll();
		}else if (GetConVarInt(Flash)== 3)
		{
			TE_SetupEnergySplash(Origin,Origin,false);
			TE_SendToAll();
		}
	}
}

// catch x,y,z of the smoke nade and do effects based on cvar

public SgExplode(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetConVarInt(gSwitch))
	{
		Origin[0] = GetEventFloat(event,"x");
		Origin[1] = GetEventFloat(event,"y");
		Origin[2] = GetEventFloat(event,"z");
	
		if(GetConVarInt(Smoke)== 1)
		{
			TE_SetupSparks(Origin,Origin,255,1);
			TE_SendToAll();
		}else if( GetConVarInt(Smoke)== 2)
		{
			TE_SetupGlowSprite(Origin,Glow,1.0,1.0,20);
			TE_SendToAll();
		}else if (GetConVarInt(Smoke)== 3)
		{
			TE_SetupEnergySplash(Origin,Origin,false);
			TE_SendToAll();
		}
	}
}

// catch x,y,z of the bullet impact and do effects based on cvar

public SlugImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetConVarInt(gSwitch))
	{
		Origin[0] = GetEventFloat(event,"x");
		Origin[1] = GetEventFloat(event,"y");
		Origin[2] = GetEventFloat(event,"z");
	
		if(GetConVarInt(Slug)== 1)
		{
			TE_SetupSparks(Origin,Origin,255,1);
			TE_SendToAll();
		}else if( GetConVarInt(Slug)== 2)
		{
			TE_SetupGlowSprite(Origin,Glow,1.0,1.0,20);
			TE_SendToAll();
		}else if (GetConVarInt(Slug)== 3)
		{
			TE_SetupEnergySplash(Origin,Origin,false);
			TE_SendToAll();
		}
	}
}