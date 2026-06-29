/*
Plugin Anti Respawn Killing version 1.0
Thanks to Fredd for his plugin SpawnProtection.
*/

#include <sourcemod>
#include <sdktools>

#define VERSION "1.0"
#pragma semicolon 1

new Handle:g_cvars_Enabled;
new Handle:g_cvars_Time;
new Handle:g_cvars_Notify;
new Handle:g_cvars_Color_Red;
new Handle:g_cvars_Color_Blu;
new Handle:g_cvars_DoA;

new bool:g_DoA = true;

new RenderOffs;

new clientProtected[MAXPLAYERS+1];

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
	name = "Anti resp-killing for TF2",
	author = "kroleg",
	description = "Protecting players on spawn",
	version = VERSION,
	url = "http://tf2.kz"
}

public OnPluginStart()
{
	CreateConVar("sm_ark_version", VERSION, "TF2 Anti resp-killing version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cvars_Enabled	= CreateConVar("sm_ark_enabled", "0", "Enable/Disable Spawn Protection", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvars_Time		= CreateConVar("sm_ark_time", "5","Length of Time to protect", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_cvars_Notify	= CreateConVar("sm_ark_notify", "0","Enable/Disable showing hint message when protection ends",FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvars_Color_Red	= CreateConVar("sm_ark_color_red", "255 0 0 200", "Color of RED players", FCVAR_PLUGIN);
	g_cvars_Color_Blu	= CreateConVar("sm_ark_color_blu", "0 0 255 200", "Color of BLU players", FCVAR_PLUGIN);
	g_cvars_DoA 		= CreateConVar("sm_ark_doa", "1", "If non zero then disable protection when player trying to attack somebody",FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_DoA = 	GetConVarBool(g_cvars_DoA);

	RenderOffs	= FindSendPropOffs("CBasePlayer", "m_clrRender");
	if (g_cvars_Enabled) {
		HookEvent("player_spawn", OnPlayerSpawn);
	}
	HookConVarChange(g_cvars_Enabled, ConVarChange_Enable);
	HookConVarChange(g_cvars_DoA, ConVarChange_DoA);
}
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_cvars_Enabled) == 1)
	{
		new client 	= GetClientOfUserId(GetEventInt(event, "userid"));
		new Team 	= GetClientTeam(client);
		
		decl String:SzColor[32];
				
		switch (Team) {
			case 3: GetConVarString(g_cvars_Color_Blu, SzColor, sizeof(SzColor));
			case 2: GetConVarString(g_cvars_Color_Red, SzColor, sizeof(SzColor));
			default: return Plugin_Continue;
		}

		if(!IsPlayerAlive(client))
			return Plugin_Continue;
			
		decl String:Colors[4][4];	
		ExplodeString(SzColor, " ", Colors, 4, 4);		
			
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		clientProtected[client] = true;
		set_rendering(client, FX:FxDistort, StringToInt(Colors[0]),StringToInt(Colors[1]),StringToInt(Colors[2]), Render:RENDER_TRANSADD, StringToInt(Colors[3]));
		
		new Float:Time = float(GetConVarInt(g_cvars_Time));
		CreateTimer(Time, RemoveProtection, client);
	}
	return Plugin_Continue;
}

//using it instead of @player_shoot, which don't working in tf2
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (clientProtected[client] && g_DoA) DisableProtection(client);
	return Plugin_Continue;
}

public Action:RemoveProtection(Handle:timer, any:client)
{
	if (clientProtected[client]) DisableProtection(client);
}

//Removes protection from player
DisableProtection(any: client)
{	
	if(IsClientInGame(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		clientProtected[client] = false;
		set_rendering(client);
		if(GetConVarInt(g_cvars_Notify) > 0)
			PrintHintText(client, "Spawn Protection Disabled");
	}
	
}

//Enable/disable hooking @player_spawn when plugin is turned off
public ConVarChange_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(oldValue,newValue)) return;
	if (StringToInt(newValue)==1)
	{
		HookEvent("player_spawn", OnPlayerSpawn);
	}else{
		UnhookEvent("player_spawn", OnPlayerSpawn);
	}
}

//Enable/disable DoA
public ConVarChange_DoA(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(oldValue,newValue)) return;
	if (StringToInt(newValue)==1)
	{
		g_DoA = true;
	}else{
		g_DoA = false;
	}
	
}

//don't now exactly what is it :D
stock set_rendering(index, FX:fx=FxNone, r=255, g=255, b=255, Render:render=Normal, amount=255)
{
	SetEntProp(index, Prop_Send, "m_nRenderFX", _:fx, 1);
	SetEntProp(index, Prop_Send, "m_nRenderMode", _:render, 1);	
	SetEntData(index, RenderOffs, r, 1, true);
	SetEntData(index, RenderOffs + 1, g, 1, true);
	SetEntData(index, RenderOffs + 2, b, 1, true);
	SetEntData(index, RenderOffs + 3, amount, 1, true);	
}
