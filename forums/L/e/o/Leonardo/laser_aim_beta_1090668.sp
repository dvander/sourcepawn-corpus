/*
laser_aim.sp

Name:
	Laser Aim

Description:
	Creates A Beam For every times when player holds in arms a Snipers Rifle
	
Versions:
	0.1 Первый релиз
	0.2 Лазеры показываются только у живых
	0.3 лазеры показываться только у владельцев снайперских винтовок
	1.0 Public release
	1.1 Added zoom cheking, Fixed laser's start position, Removed timer
	1.2 Added dot on target
	1.3beta Duck/stand hooking
*/

#include <sourcemod>
#include <sdktools>
#include <hooker>

#define VERSION "1.3beta" 

new Handle:g_CvarEnable = INVALID_HANDLE;

new g_sprite;
new g_glow;

new m_iFOV;

new Handle:g_CvarRed = INVALID_HANDLE;
new Handle:g_CvarBlue = INVALID_HANDLE;
new Handle:g_CvarGreen = INVALID_HANDLE;

new Handle:g_CvarTrans = INVALID_HANDLE;
new Handle:g_CvarLife = INVALID_HANDLE;
new Handle:g_CvarWidth = INVALID_HANDLE;

new a_playerDuck[MAXPLAYERS+1] = {};

public OnMapStart()
{
	g_sprite = PrecacheModel("materials/sprites/laser.vmt");
	g_glow = PrecacheModel("sprites/redglow1.vmt");
}

public Plugin:myinfo =
{
	name = "Laser Aim",
	author = "Leonardo",
	description = "Creates A Beam For every times when player holds in arms a Snipers Rifle",
	version = VERSION,
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	g_CvarEnable = CreateConVar("sm_laser_aim_on", "1", "1 turns the plugin on 0 is off", FCVAR_NOTIFY);

	g_CvarRed = CreateConVar("sm_laser_aim_red", "200", "Amount OF Red In The Beam");
	g_CvarGreen = CreateConVar("sm_laser_aim_green", "0", "Amount Of Green In The Beam");
	g_CvarBlue = CreateConVar("sm_laser_aim_blue", "0", "Amount OF Blue In The Beams");

	g_CvarTrans = CreateConVar("sm_laser_aim_alpha", "150", "Amount OF Transparency In Beam");
	g_CvarLife = CreateConVar("sm_laser_aim_life", "0.1", "Life of the Beam");
	g_CvarWidth = CreateConVar("sm_laser_aim_width", "1.0", "Width of the Beam");

	m_iFOV = FindSendPropOffs("CBasePlayer","m_iFOV");
	
	RegisterHook(HK_PlayerDuck, OnPlayerDuck, false);
}

public OnGameFrame()
{
	for (new i=1; i<=MaxClients; i++)
	{
		//new client = GetClientOfUserId(i);
		if(IsClientInGame(i) && IsClientConnected(i))
		{
			new i_playerTeam = GetClientTeam(i);
			
			new String:s_playerWeapon[32];
			GetClientWeapon(i, s_playerWeapon, sizeof(s_playerWeapon));
			
			new i_playerFOV;
			i_playerFOV = GetEntData(i, m_iFOV);
				
			if(GetConVarBool(g_CvarEnable) && (i_playerTeam > 1) && IsPlayerAlive(i) && ((i_playerFOV==15) || (i_playerFOV==40) || (i_playerFOV==10)) && (StrEqual("weapon_awp", s_playerWeapon) || StrEqual("weapon_scout", s_playerWeapon) || StrEqual("weapon_sg550", s_playerWeapon) || StrEqual("weapon_g3sg1", s_playerWeapon)))
			{
				CreateBeam(i);
			}
		}
	}
}

public OnClientPutInServer(client)
{
    HookEntity(HKE_CCSPlayer, client);
}
public OnClientDisconnect(client)
{
    UnHookPlayer(HKE_CCSPlayer, client);
}

public Action:OnPlayerDuck(client)
{
	a_playerDuck[client]=1;
	return Plugin_Continue;
}

public Action:CreateBeam(any:client)
{
	new Float:f_playerViewOrigin[3];
	GetClientAbsOrigin(client, f_playerViewOrigin);
	if(a_playerDuck[client]==1)
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

	new Float:width;
	width = GetConVarFloat( g_CvarWidth );
	
	TE_SetupBeamPoints( f_newPlayerViewOrigin, f_playerViewDestination, g_sprite, 0, 0, 0, life, width, width, 1, 0.0, color, 0);
	TE_SendToAll();
	
	TE_SetupGlowSprite( f_playerViewDestination, g_glow, life, (width/10), (255-color[3]));
	TE_SendToAll();
	
	a_playerDuck[client]=0;
	
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

stock str_piece(input[], output[][], outputsize, piecelen, token = '|')
{
	new i = -1, pieces, len = -1 ;

	while ( input[++i] != 0 )
	{
		if ( input[i] != token )
		{
			if ( ++len < piecelen )
				output[pieces][len] = input[i] ;
		}
		else
		{
			output[pieces++][++len] = 0 ;
			len = -1 ;
			
			if ( pieces == outputsize )
				return pieces ;
		}
	}
	return pieces + 1;
}