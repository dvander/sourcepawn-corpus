#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

new Handle:g_DefaultAlpha = INVALID_HANDLE;
new Handle:g_EnableHETails = INVALID_HANDLE;
new Handle:g_EnableFlashTails = INVALID_HANDLE;
new Handle:g_EnableSmokeTails = INVALID_HANDLE;
new Handle:g_EnableDecoyTails = INVALID_HANDLE;
new Handle:g_EnableMolotovTails = INVALID_HANDLE;
new Handle:g_EnableIncTails = INVALID_HANDLE;
new Handle:g_HEColor = INVALID_HANDLE;
new Handle:g_FlashColor = INVALID_HANDLE;
new Handle:g_SmokeColor = INVALID_HANDLE;
new Handle:g_DecoyColor = INVALID_HANDLE;
new Handle:g_MolotovColor = INVALID_HANDLE;
new Handle:g_IncColor = INVALID_HANDLE;
new Handle:g_TailTime = INVALID_HANDLE;
new Handle:g_TailFadeTime = INVALID_HANDLE;
new Handle:g_TailWidth = INVALID_HANDLE;

new g_iBeamSprite;

new TempColorArray[] = {0, 0, 0, 0}; //temp array since you can't return arrays

//Ugly list of colors since I couldn't get Enum Arrays to work
new g_ColorAqua[] 	= {0,255,255};
new g_ColorBlack[]	= {0,0,0};
new g_ColorBlue[] 	= {0,0,255};
new g_ColorFuschia[] 	= {255,0,255};
new g_ColorGray[] 	= {128,128,128};
new g_ColorGreen[] 	= {0,128,0};
new g_ColorLime[] 	= {0,255,0};
new g_ColorMaroon[] 	= {128,0,0};
new g_ColorNavy[] 	= {0,0,128};
new g_ColorRed[] 		= {255,0,0};
new g_ColorWhite[] 	= {255,255,255};
new g_ColorYellow[]	= {255,255,0};
new g_ColorSilver[]	= {192,192,192};
new g_ColorTeal[]		= {0,128,128};
new g_ColorPurple[]	= {128,0,128};
new g_ColorOlive[]	= {128,128,0};
new g_ColorOrange[]	= {255,153,0};
//end colors

public Plugin:myinfo =
{
	name = "Nade Tails",
	author = "InternetBully, H3Bus",
	version = "2.1",
	description = "Adds tails to projectiles",
	url = ""
};

public OnPluginStart()
{

	g_DefaultAlpha		= CreateConVar("sm_tails_defaultalpha", "255", "Default alpha for trails (0 is invisible, 255 is solid).", FCVAR_PLUGIN, true, 0.0, true, 255.0);

	//Projectiles to put tails on
	g_EnableHETails		= CreateConVar("sm_tails_hegrenade", "1", "Enables Nade Tails on HE Grenades (0/1).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_EnableFlashTails	= CreateConVar("sm_tails_flashbang", "1", "Enables Nade Tails on Flashbangs (0/1).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_EnableSmokeTails	= CreateConVar("sm_tails_smoke", "1", "Enables Nade Tails on Smoke Grenades (0/1).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_EnableDecoyTails	= CreateConVar("sm_tails_decoy", "1", "Enables Nade Tails on Decoy Grenades (0/1).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_EnableMolotovTails	= CreateConVar("sm_tails_molotov", "1", "Enables Nade Tails on Molotovs (0/1).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_EnableIncTails		= CreateConVar("sm_tails_incendiary", "1", "Enables Nade Tails on Incendiary Grenades (0/1).", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	//TE_SetupBeamFollow CVARs -- Colors
	g_HEColor				= CreateConVar("sm_tails_hecolor", "red", "Tail color on HE Grenades. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	g_FlashColor			= CreateConVar("sm_tails_flashcolor", "blue", "Tail color on Flashbangs. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	g_SmokeColor			= CreateConVar("sm_tails_smokecolor", "green", "Tail color on Smoke Grenades. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	g_DecoyColor			= CreateConVar("sm_tails_decoycolor", "yellow", "Tail color on Decoy Grenades. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20,147 225\"");
	g_MolotovColor		= CreateConVar("sm_tails_molotovcolor", "orange", "Tail color on Molotovs. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	g_IncColor				= CreateConVar("sm_tails_inccolor", "orange", "Tail color on Incendiary Grenades. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");

	//size and time
	g_TailTime 			= CreateConVar("sm_tails_tailtime", "5.0", "Time the tail stays visible.", FCVAR_PLUGIN, true, 0.0, true, 25.0);
	g_TailFadeTime		= CreateConVar("sm_tails_tailfadetime", "1", "Time for tail to fade over.", FCVAR_PLUGIN);
	g_TailWidth			= CreateConVar("sm_tails_tailwidth", "1.0", "Width of the tail.", FCVAR_PLUGIN);


}

public OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

GetSetColor(Handle:hColorCvar)
{
	decl String:sCvar[32];
	GetConVarString(hColorCvar, sCvar, sizeof(sCvar));

	if(StrContains(sCvar, "aqua", false) != -1)
	{
		TempColorArray[0] = g_ColorAqua[0];
		TempColorArray[1] = g_ColorAqua[1];
		TempColorArray[2] = g_ColorAqua[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "black", false) != -1)
	{
		TempColorArray[0] = g_ColorBlack[0];
		TempColorArray[1] = g_ColorBlack[1];
		TempColorArray[2] = g_ColorBlack[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "blue", false) != -1)
	{
		TempColorArray[0] = g_ColorBlue[0];
		TempColorArray[1] = g_ColorBlue[1];
		TempColorArray[2] = g_ColorBlue[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "fuschia", false) != -1)
	{
		TempColorArray[0] = g_ColorFuschia[0];
		TempColorArray[1] = g_ColorFuschia[1];
		TempColorArray[2] = g_ColorFuschia[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "gray", false) != -1)
	{
		TempColorArray[0] = g_ColorGray[0];
		TempColorArray[1] = g_ColorGray[1];
		TempColorArray[2] = g_ColorGray[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "green", false) != -1)
	{
		TempColorArray[0] = g_ColorGreen[0];
		TempColorArray[1] = g_ColorGreen[1];
		TempColorArray[2] = g_ColorGreen[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "lime", false) != -1)
	{
		TempColorArray[0] = g_ColorLime[0];
		TempColorArray[1] = g_ColorLime[1];
		TempColorArray[2] = g_ColorLime[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "maroon", false) != -1)
	{
		TempColorArray[0] = g_ColorMaroon[0];
		TempColorArray[1] = g_ColorMaroon[1];
		TempColorArray[2] = g_ColorMaroon[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "navy", false) != -1)
	{
		TempColorArray[0] = g_ColorNavy[0];
		TempColorArray[1] = g_ColorNavy[1];
		TempColorArray[2] = g_ColorNavy[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "red", false) != -1)
	{
		TempColorArray[0] = g_ColorRed[0];
		TempColorArray[1] = g_ColorRed[1];
		TempColorArray[2] = g_ColorRed[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "white", false) != -1)
	{
		TempColorArray[0] = g_ColorWhite[0];
		TempColorArray[1] = g_ColorWhite[1];
		TempColorArray[2] = g_ColorWhite[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "yellow", false) != -1)
	{
		TempColorArray[0] = g_ColorYellow[0];
		TempColorArray[1] = g_ColorYellow[1];
		TempColorArray[2] = g_ColorYellow[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "silver", false) != -1)
	{
		TempColorArray[0] = g_ColorSilver[0];
		TempColorArray[1] = g_ColorSilver[1];
		TempColorArray[2] = g_ColorSilver[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "teal", false) != -1)
	{
		TempColorArray[0] = g_ColorTeal[0];
		TempColorArray[1] = g_ColorTeal[1];
		TempColorArray[2] = g_ColorTeal[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "purple", false) != -1)
	{
		TempColorArray[0] = g_ColorPurple[0];
		TempColorArray[1] = g_ColorPurple[1];
		TempColorArray[2] = g_ColorPurple[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "olive", false) != -1)
	{
		TempColorArray[0] = g_ColorOlive[0];
		TempColorArray[1] = g_ColorOlive[1];
		TempColorArray[2] = g_ColorOlive[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "orange", false) != -1)
	{
		TempColorArray[0] = g_ColorOrange[0];
		TempColorArray[1] = g_ColorOrange[1];
		TempColorArray[2] = g_ColorOrange[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "random", false) != -1)
	{
		TempColorArray[0] = GetRandomInt(0,255);
		TempColorArray[1] = GetRandomInt(0,255);
		TempColorArray[2] = GetRandomInt(0,255);
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, " ") != -1) //this is a manually entered color
	{
		new String:sTemp[4][6];
		ExplodeString(sCvar, " ", sTemp, sizeof(sTemp), sizeof(sTemp[]));
		TempColorArray[0] = StringToInt(sTemp[0]);
		TempColorArray[1] = StringToInt(sTemp[1]);
		TempColorArray[2] = StringToInt(sTemp[2]);
		PrintToChatAll("%s", sTemp[3]);
		if(StrEqual(sTemp[3], ""))
			TempColorArray[3] = 225;
		else
			TempColorArray[3] = StringToInt(sTemp[3]);
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if( IsValidEntity(entity)) SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned); //don't draw tails if we disable the plugin while people have tails enabled
}

public OnEntitySpawned(entity)
{
	if(!IsValidEdict(entity))
		return;

	decl String:class_name[32];
	GetEdictClassname(entity, class_name, 32);

	if(StrContains(class_name, "projectile") != -1 && IsValidEntity(entity) )
	{
		if(StrContains(class_name, "hegrenade") != -1 && GetConVarBool(g_EnableHETails))
			GetSetColor(g_HEColor);
		else if(StrContains(class_name, "flashbang") != -1 && GetConVarBool(g_EnableFlashTails))
			GetSetColor(g_FlashColor);
		else if(StrContains(class_name, "smoke") != -1 && GetConVarBool(g_EnableSmokeTails))
			GetSetColor(g_SmokeColor);
		else if(StrContains(class_name, "decoy") != -1 && GetConVarBool(g_EnableDecoyTails))
			GetSetColor(g_DecoyColor);
		else if(StrContains(class_name, "molotov") != -1 && GetConVarBool(g_EnableMolotovTails))
			GetSetColor(g_MolotovColor);
		else if(StrContains(class_name, "incgrenade") != -1 && GetConVarBool(g_EnableIncTails))
			GetSetColor(g_IncColor);
		TE_SetupBeamFollow(entity, g_iBeamSprite, 0, GetConVarFloat(g_TailTime), GetConVarFloat(g_TailWidth), GetConVarFloat(g_TailWidth), GetConVarInt(g_TailFadeTime), TempColorArray);
		TE_SendToAll();
	}
}
