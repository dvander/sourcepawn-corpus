#include <sourcemod>
#include <sdktools>

#define VERSION "1.5"
#pragma semicolon 1

new TeamSpec;
new TeamUna;
new bool:NoTeams = false;

new Handle:SpawnProtectionEnabled;
new Handle:SpawnProtectionTime;
new Handle:SpawnProtectionNotify;
new Handle:SpawnProtectionColor;

new RenderOffs;

enum FX
{
	FxNone = 0,
	FxPulseFast,
	FxPulseSlowWide,
	FxPulseFastWide,
	FxFadeSlow,
	FxFadeFast,
	FxSolidSlow,
	FxSolidFast,
	FxStrobeSlow,
	FxStrobeFast,
	FxStrobeFaster,
	FxFlickerSlow,
	FxFlickerFast,
	FxNoDissipation,
	FxDistort,               // Distort/scale/translate flicker
	FxHologram,              // kRenderFxDistort + distance fade
	FxExplode,               // Scale up really big!
	FxGlowShell,             // Glowing Shell
	FxClampMinScale,         // Keep this sprite from getting very small (SPRITES only!)
	FxEnvRain,               // for environmental rendermode, make rain
	FxEnvSnow,               //  "        "            "    , make snow
	FxSpotlight,     
	FxRagdoll,
	FxPulseFastWider,
};

enum Render
{
	Normal = 0, 		// src
	TransColor, 		// c*a+dest*(1-a)
	TransTexture,		// src*a+dest*(1-a)
	Glow,				// src*a+dest -- No Z buffer checks -- Fixed size in screen space
	TransAlpha,			// src*srca+dest*(1-srca)
	TransAdd,			// src*a+dest
	Environmental,		// not drawn, used for environmental effects
	TransAddFrameBlend,	// use a fractional frame value to blend between animation frames
	TransAlphaAdd,		// src + dest*(1-a)
	WorldGlow,			// Same as kRenderGlow but not fixed size in screen space
	None,				// Don't render.
};

public Plugin:myinfo = 
{
	name = "Spawn Protection",
	author = "Fredd",
	description = "Adds spawn protection",
	version = VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("spawnprotection_version", VERSION, "Spawn Protection Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	SpawnProtectionEnabled		= CreateConVar("sp_on", "1");
	SpawnProtectionTime			= CreateConVar("sp_time", "5");
	SpawnProtectionNotify		= CreateConVar("sp_notify", "1");
	SpawnProtectionColor		= CreateConVar("sp_color", "0 255 0 120");
	
	AutoExecConfig(true, "spawn_protection");
	
	RenderOffs					= FindSendPropOffs("CBasePlayer", "m_clrRender");
	
	decl String:ModName[21];
	GetGameFolderName(ModName, sizeof(ModName));
	
	if(StrEqual(ModName, "cstrike", false) || StrEqual(ModName, "dod", false) || StrEqual(ModName, "tf", false))
	{
		TeamSpec = 1;
		TeamUna = 0;
		NoTeams = false;
		
	} else if(StrEqual(ModName, "Insurgency", false))
	{
		TeamSpec = 3;
		TeamUna = 0;
		NoTeams = false;
	}
	else if(StrEqual(ModName, "hl2mp", false))
	{
		NoTeams = true;
	} else
	{
		SetFailState("%s is an unsupported mod", ModName);
	}
	HookEvent("player_spawn", OnPlayerSpawn);
}public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(SpawnProtectionEnabled) == 1)
	{
		new client 	= GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetClientTeam(client) != 3)
			return Plugin_Continue;

		new Team 	= GetClientTeam(client);
		
		if(NoTeams == false)
		{
			if(Team == TeamSpec || Team == TeamUna)
				return Plugin_Continue;
		}
		if(!IsPlayerAlive(client))
			return Plugin_Continue;
		
		decl String:SzColor[32];
		decl String:Colors[4][4];
		new Float:Time = float(GetConVarInt(SpawnProtectionTime));
		
		GetConVarString(SpawnProtectionColor, SzColor, sizeof(SzColor));
		ExplodeString(SzColor, " ", Colors, 4, 4);
			
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		set_rendering(client, FX:FxDistort, StringToInt(Colors[0]),StringToInt(Colors[1]),StringToInt(Colors[2]), Render:RENDER_TRANSADD, StringToInt(Colors[3]));
		CreateTimer(Time, RemoveProtection, client);
		if(GetConVarInt(SpawnProtectionNotify) > 0)
			PrintToChat(client, "\x04[SpawnProtection] \x01you will be spawn protected for \x04%i \x01seconds", RoundToNearest(Time)); 
	}
	return Plugin_Continue;
}
public Action:RemoveProtection(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		set_rendering(client);
		if(GetConVarInt(SpawnProtectionNotify) > 0)
			PrintToChat(client, "\x04[SpawnProtection] \x01spawn protection is now off..");
	}
}
stock set_rendering(index, FX:fx=FxNone, r=255, g=255, b=255, Render:render=Normal, amount=255)
{
	SetEntProp(index, Prop_Send, "m_nRenderFX", _:fx, 1);
	SetEntProp(index, Prop_Send, "m_nRenderMode", _:render, 1);	
	SetEntData(index, RenderOffs, r, 1, true);
	SetEntData(index, RenderOffs + 1, g, 1, true);
	SetEntData(index, RenderOffs + 2, b, 1, true);
	SetEntData(index, RenderOffs + 3, amount, 1, true);	
}