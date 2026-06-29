#include <sourcemod>
#include <sdktools>

#define VERSION "1.4" 

new Handle:g_CvarEnable = INVALID_HANDLE;
new Handle:g_CvarAll = INVALID_HANDLE;

new g_glow;

new Handle:g_CvarRed = INVALID_HANDLE;
new Handle:g_CvarBlue = INVALID_HANDLE;
new Handle:g_CvarGreen = INVALID_HANDLE;

new Handle:g_CvarTrans = INVALID_HANDLE;
new Handle:g_CvarLife = INVALID_HANDLE;
new Handle:g_CvarDotWidth = INVALID_HANDLE;

public OnMapStart()
{
	g_glow = PrecacheModel("sprites/purpleglow1.vmt");
	AddFileToDownloadsTable( "materials/sprites/purpleglow1.vmt" );
}

public Plugin:myinfo =
{
	name = "[NMRiH] Laser Aim",
	author = "Leonardo (adapting by Grey83)",
	description = "Creates a laser dot every time a firearm in the hands of the player",
	version = VERSION,
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_laser_aim", VERSION, "Laser Aim  plugin's version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY);
	g_CvarEnable = CreateConVar("sm_laser_aim_on", "1", "1 turns the plugin on, 0 is off", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0 );
	g_CvarAll = CreateConVar("sm_laser_aim2all", "1", "The player can see: 1- all dots, 0 - only their own dot", FCVAR_NOTIFY, true, 0.0, true, 1.0 );

	g_CvarRed = CreateConVar("sm_laser_aim_red", "200", "Amount of Red in the dot", FCVAR_NONE, true, 0.0, true, 255.0 );
	g_CvarGreen = CreateConVar("sm_laser_aim_green", "0", "Amount of Green in the dot", FCVAR_NONE, true, 0.0, true, 255.0 );
	g_CvarBlue = CreateConVar("sm_laser_aim_blue", "0", "Amount of Blue in the dot", FCVAR_NONE, true, 0.0, true, 255.0 );
	g_CvarTrans = CreateConVar("sm_laser_aim_alpha", "31", "Amount of Transparency in dot", FCVAR_NONE, true, 0.0, true, 255.0 );
	
	g_CvarLife = CreateConVar("sm_laser_aim_life", "0.075", "Life of the dot", FCVAR_NONE, true, 0.01, true, 1.0 );
	g_CvarDotWidth = CreateConVar("sm_laser_aim_dot_width", "0.25", "Width of the Dot", FCVAR_NONE);
	
	AutoExecConfig(true, "plugin.nmrih_laser_aim");
}

public OnGameFrame()
{
	for (new i=1; i<=MaxClients; i++)
	{
		//new client = GetClientOfUserId(i);
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			
			new String:s_playerWeapon[32];
			GetClientWeapon(i, s_playerWeapon, sizeof(s_playerWeapon));
				
			if(GetConVarBool(g_CvarEnable))
				if(StrEqual("fa_500a", s_playerWeapon) || StrEqual("fa_870", s_playerWeapon) || StrEqual("fa_1022", s_playerWeapon) || StrEqual("fa_1911", s_playerWeapon) || StrEqual("fa_cz858", s_playerWeapon) || StrEqual("fa_fnfal", s_playerWeapon) || StrEqual("fa_glock17", s_playerWeapon) || StrEqual("fa_jae700", s_playerWeapon) || StrEqual("fa_m16a4", s_playerWeapon) || StrEqual("fa_m92fs", s_playerWeapon) || StrEqual("fa_mac10", s_playerWeapon) || StrEqual("fa_mkiii", s_playerWeapon) || StrEqual("fa_mp5a3", s_playerWeapon) || StrEqual("fa_sako85", s_playerWeapon) || StrEqual("fa_sks", s_playerWeapon) || StrEqual("fa_superx3", s_playerWeapon) || StrEqual("fa_sv10", s_playerWeapon) || StrEqual("fa_sw686", s_playerWeapon) || StrEqual("fa_winchester1892", s_playerWeapon) || StrEqual("tool_flare_gun", s_playerWeapon))
						CreateBeam(i);
		}
	}
}

public Action:CreateBeam(any:client)
{
	new Float:f_playerViewOrigin[3];
	GetClientAbsOrigin(client, f_playerViewOrigin);
	if(GetClientButtons(client) & IN_DUCK)
		f_playerViewOrigin[2] += 40;
	else
		f_playerViewOrigin[2] += 60;

	new Float:f_playerViewDestination[3];		
	GetPlayerEye(client, f_playerViewDestination);

	new Float:distance = GetVectorDistance( f_playerViewOrigin, f_playerViewDestination );

	new Float:percentage = 0.4 / ( distance / 100 );

	new Float:f_newPlayerViewOrigin[3];
	f_newPlayerViewOrigin[0] = f_playerViewOrigin[0] + ( ( f_playerViewDestination[0] - f_playerViewOrigin[0] ) * percentage );
	f_newPlayerViewOrigin[1] = f_playerViewOrigin[1] + ( ( f_playerViewDestination[1] - f_playerViewOrigin[1] ) * percentage ) - 0.08;
	f_newPlayerViewOrigin[2] = f_playerViewOrigin[2] + ( ( f_playerViewDestination[2] - f_playerViewOrigin[2] ) * percentage );

	new color[4];
	color[0] = GetConVarInt( g_CvarRed ); 
	color[1] = GetConVarInt( g_CvarGreen );
	color[2] = GetConVarInt( g_CvarBlue );
	color[3] = GetConVarInt( g_CvarTrans );
	
	new Float:life;
	life = GetConVarFloat( g_CvarLife );

	new Float:dotWidth;
	dotWidth = GetConVarFloat( g_CvarDotWidth );
	
	TE_SetupGlowSprite( f_playerViewDestination, g_glow, life, dotWidth, color[3] );
	if(GetConVarBool(g_CvarAll))
	{
		TE_SendToAll();
	}
	else
	{
		TE_SendToClient(client);
	}
	
	return Plugin_Continue;
}

bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
    return entity > GetMaxClients();
}