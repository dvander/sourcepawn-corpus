/**
 * glow.sp
 * Allows players or admins to set glow colors.
 *
 * FX stocks by pRed
 */

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "2.0"

public Plugin:myinfo = 
{
	name = "Glow",
	author = "ferret",
	description = "Set players to glow!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new String:g_ColorNames[12][32] = {"Red", "Green", "Blue", "Yellow", "Purple", "Cyan", "Orange", "Pink", "Olive", "Lime", "Violet", "Lightblue"};
new g_Colors[12][3] = {{255,0,0},{0,255,0},{0,0,255},{255,255,0},{255,0,255},{0,255,255},{255,128,0},{255,0,128},{128,255,0},{0,255,128},{128,0,255},{0,128,255}};

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

new FX:g_Effect = FX:FxGlowShell;
new Render:g_Render = Render:Glow;

new Handle:g_Cvar_Glow = INVALID_HANDLE;
new Handle:g_Cvar_GlowSelf = INVALID_HANDLE;
new Handle:g_Cvar_GlowAd = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.glow");	

	CreateConVar("sm_glow_version", PLUGIN_VERSION, "Glow Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_glowset", Command_SmGlow, ADMFLAG_CUSTOM1, "sm_glow <player> <color> - Sets player to glow color.");
	RegAdminCmd("sm_glowcolors", Command_SmGlowColors, ADMFLAG_CUSTOM1, "sm_glowcolors - Lists out the glow colors.");
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("team_say", Command_Say);
	
	g_Cvar_Glow = CreateConVar("sm_glow", "1", "Enable glow functions! Default on.", 0, true, 0.0, true, 1.0); 
	g_Cvar_GlowSelf = CreateConVar("sm_glow_self", "1", "Allow players to set their own glows! Default on.", 0, true, 0.0, true, 1.0);
	g_Cvar_GlowAd = CreateConVar("sm_glow_ad", "1", "Advertise glow command to players, if they can use. Default on.", 0, true, 0.0, true, 1.0);
	
	HookConVarChange(g_Cvar_Glow, ConVarChange_SmGlow);
}

public ConVarChange_SmGlow(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StringToInt(newValue))
	{
		new MaxClients = GetMaxClients();
		for(new i = 0; i < MaxClients; i++)
		{
			if(IsClientConnected(i) && IsClientInGame(i))
				set_rendering(i);		
		}
	}
}

public Action:Command_SmGlow(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_glow <player> <color>");
		return Plugin_Handled;	
	}
	
	if (!GetConVarBool(g_Cvar_Glow))
	{
		ReplyToCommand(client, "[SM] %t", "Glow Disabled");
		return Plugin_Handled;
	}
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	
	new String:target[64], String:colorStr[16];

	new len = BreakString(text, target, sizeof(target));
	BreakString(text[len], colorStr, sizeof(colorStr));
	
	new clients[2];
	new numClients = SearchForClients(target, clients, 2);
	
	if (numClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (numClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, clients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	new color = FindColor(colorStr);
	
	if (color == -1 && strcmp(colorStr, "none", false) != 0)
	{
		ReplyToCommand(client, "[SM] %t", "Invalid Color");
		return Plugin_Handled;
	}
	
	new String:name[64];
	GetClientName(clients[0], name, sizeof(name));	
	
	if (color == -1)
	{
		set_rendering(clients[0]);
		ShowActivity(clients[0], "%t", "Removed Player Color", name);
		LogMessage("Chat: %L triggered sm_glowset to %L (set glow as none)", client, clients[0]);
	}
	else
	{
		set_rendering(clients[0], g_Effect, g_Colors[color][0], g_Colors[color][1], g_Colors[color][2], g_Render, 250);
		ShowActivity(client, "%t", "Set Player Color", name, g_ColorNames[color]);
		LogMessage("Chat: %L triggered sm_glowset to %L (set glow as %s)", client, clients[0], g_ColorNames[color]);
	}

	return Plugin_Handled;	
}

public Action:Command_SmGlowColors(client, args)
{
	if (!GetConVarBool(g_Cvar_Glow))
	{
		ReplyToCommand(client, "[SM] %t", "Glow Disabled");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "[SM] %T: None, White, Red, Green, Blue, Yellow, Purple, Cyan", "Color List");
	ReplyToCommand(client, "[SM] %T: Orange, Pink, Olive, Lime, Violet, and Lightblue", "Color List");	
	
	return Plugin_Handled;	
}
	
public Action:Command_Say(client, args)
{
	if (!GetConVarBool(g_Cvar_Glow))
		return Plugin_Continue;
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	text[strlen(text)-1] = '\0';
	
	new String:parts[5][16];
  	ExplodeString(text[1], " ", parts, 5, 16);

 	if (strcmp(parts[0], "glow", false) != 0)
		return Plugin_Continue;
		
	if (!GetConVarBool(g_Cvar_GlowSelf))
		return Plugin_Continue;
		
	new color = FindColor(parts[1]);
		
	if (color == -1 && strcmp(parts[1], "none", false) != 0 && strcmp(parts[1], "colors", false) != 0)
	{
		PrintToChat(client, "[SM] %t", "Invalid Color");
		return Plugin_Continue;
	}
	
	if (color == -1)
	{
		if(strcmp(parts[1], "none", false) == 0)
			set_rendering(client);
		else
		{
			PrintToChat(client, "[SM] %t: None, White, Red, Green, Blue, Yellow, Purple, Cyan", "Color List");
			PrintToChat(client, "[SM] %t: Orange, Pink, Olive, Lime, Violet, and Lightblue", "Color List");
		}
	}
	else
		set_rendering(client, g_Effect, g_Colors[color][0], g_Colors[color][1], g_Colors[color][2], g_Render, 250);	

	return Plugin_Continue;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if (!GetConVarBool(g_Cvar_Glow))
		return true;	
	
	if (GetConVarBool(g_Cvar_GlowSelf) && GetConVarBool(g_Cvar_GlowAd))
		CreateTimer(15.0, Timer_Advertise, client);
	
	return true;
}

public Action:Timer_Advertise(Handle:timer, any:client)
{
	if (IsClientInGame(client))
		PrintToChat(client, "[SM] %t", "Advertise Glow");
	else if (IsClientConnected(client))
		CreateTimer(15.0, Timer_Advertise, client);
}

FindColor(String:color[])
{
	for (new i = 0; i < 12; i++)
	{
		if(strcmp(color, g_ColorNames[i], false) == 0)
			return i;
	}
	
	return -1;
}

stock set_rendering(index, FX:fx=FxNone, r=255, g=255, b=255, Render:render=Normal, amount=255)
{
	SetEntProp(index, Prop_Send, "m_nRenderFX", _:fx, 1);
	SetEntProp(index, Prop_Send, "m_nRenderMode", _:render, 1);

	new offset = GetEntSendPropOffs(index, "m_clrRender");
	
	SetEntData(index, offset, r, 1, true);
	SetEntData(index, offset + 1, g, 1, true);
	SetEntData(index, offset + 2, b, 1, true);
	SetEntData(index, offset + 3, amount, 1, true);
}