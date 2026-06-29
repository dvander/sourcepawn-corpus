//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.4"

new g_killCount[MAXPLAYERS+1];

new Handle:bt_enable;
new Handle:bt_enableweapontracers;
new Handle:bt_timescale;
new Handle:bt_trans;
new Handle:bt_fsound;
new Handle:bt_kills;

new slowdown = 0;
new focussound = 2;
new transition = false;
new Float:timescale = 0.50;

new Handle:Cheats = INVALID_HANDLE;

new Handle:bt_enableweapon_pistol;
new Handle:bt_enableweapon_smg1;
new Handle:bt_enableweapon_ar2;
new Handle:bt_enableweapon_shotgun;
new Handle:bt_enableweapon_s357;
new Handle:bt_enableweapon_crossbow;

new Handle:bt_enableweapon_bt_pistol;
new Handle:bt_enableweapon_bt_smg1;
new Handle:bt_enableweapon_bt_ar2;
new Handle:bt_enableweapon_bt_shotgun;
new Handle:bt_enableweapon_bt_s357;
new Handle:bt_enableweapon_bt_crossbow;


new Handle:g_CvarTeam2Red = INVALID_HANDLE;
new Handle:g_CvarTeam2Blue = INVALID_HANDLE;
new Handle:g_CvarTeam2Green = INVALID_HANDLE;
new Handle:g_CvarTeam3Red = INVALID_HANDLE;
new Handle:g_CvarTeam3Blue = INVALID_HANDLE;
new Handle:g_CvarTeam3Green = INVALID_HANDLE;
new Handle:g_CvarNoTeamRed = INVALID_HANDLE;
new Handle:g_CvarNoTeamBlue = INVALID_HANDLE;
new Handle:g_CvarNoTeamGreen = INVALID_HANDLE;

new Handle:g_CvarTrans = INVALID_HANDLE;

new g_BeamSprite;

new Handle:g_CvarPistolLife = INVALID_HANDLE;
new Handle:g_CvarPistolWidth = INVALID_HANDLE;

new Handle:g_CvarSmg1Life = INVALID_HANDLE;
new Handle:g_CvarSmg1Width = INVALID_HANDLE;

new Handle:g_CvarAr2Life = INVALID_HANDLE;
new Handle:g_CvarAr2Width = INVALID_HANDLE;

new Handle:g_CvarShotgunLife = INVALID_HANDLE;
new Handle:g_CvarShotgunWidth = INVALID_HANDLE;

new Handle:g_CvarS357Life = INVALID_HANDLE;
new Handle:g_CvarS357Width = INVALID_HANDLE;

new Handle:g_CvarCrossbowLife = INVALID_HANDLE;
new Handle:g_CvarCrossbowWidth = INVALID_HANDLE;


public Plugin:myinfo = 

{
	name = "SM Bullet Time Hl2dm",
	author = "Andi67",
	description = "Creates a slow-motion effect on events in bullet time / matrix style",
	version = PLUGIN_VERSION,
	url = "http://www.dodsourceplugins.net/"
};

public OnPluginStart() 
{
	CreateConVar("sm_bullettime_hl2dm_version", PLUGIN_VERSION, "SM Bullet Time Hl2dm Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	bt_enable = CreateConVar("bt_enable", "1", "Enables/Disables Bullet Time.", FCVAR_PLUGIN);
	bt_enableweapontracers = CreateConVar("bt_enableweapontracers", "1", "Enables/Disables Bullet Time Tracers.", FCVAR_PLUGIN);
	bt_kills = CreateConVar("bt_kills", "4", "Kills for enabling BT on Smg1,Crossbow,Ar2,Shotgun,Pistol,357.", FCVAR_PLUGIN);	

	bt_enableweapon_pistol = CreateConVar("bt_enableweapon_pistol", "1", "Enables Tracers for Pistol.", FCVAR_PLUGIN);
	bt_enableweapon_smg1 = CreateConVar("bt_enableweapon_smg1", "1", "Enables Tracers for Smg1.", FCVAR_PLUGIN);
	bt_enableweapon_ar2 = CreateConVar("bt_enableweapon_ar2", "1", "Enables Tracers for Ar2.", FCVAR_PLUGIN);
	bt_enableweapon_shotgun = CreateConVar("bt_enableweapon_shotgun", "1", "Enables Tracers for Shotgun.", FCVAR_PLUGIN);
	bt_enableweapon_s357 = CreateConVar("bt_enableweapon_357", "1", "Enables Tracers for 357.", FCVAR_PLUGIN);
	bt_enableweapon_crossbow = CreateConVar("bt_enableweapon_crossbow", "1", "Enables Tracers for Crossbow.", FCVAR_PLUGIN);
	
	bt_enableweapon_bt_pistol = CreateConVar("bt_enableweapon_bt_pistol", "1", "Enables Bullet Time for Pistol.", FCVAR_PLUGIN);
	bt_enableweapon_bt_smg1 = CreateConVar("bt_enableweapon_bt_smg1", "1", "Enables Bullet Time for Smg1.", FCVAR_PLUGIN);
	bt_enableweapon_bt_ar2 = CreateConVar("bt_enableweapon_bt_ar2", "1", "Enables Bullet Time for Ar2.", FCVAR_PLUGIN);
	bt_enableweapon_bt_shotgun = CreateConVar("bt_enableweapon_bt_shotgun", "1", "Enables Bullet Time for Shotgun.", FCVAR_PLUGIN);
	bt_enableweapon_bt_s357 = CreateConVar("bt_enableweapon_bt_357", "1", "Enables Bullet Time for 357.", FCVAR_PLUGIN);
	bt_enableweapon_bt_crossbow = CreateConVar("bt_enableweapon_bt_crossbow", "1", "Enables Bullet Time for Crossbow.", FCVAR_PLUGIN);	

	
	bt_trans = CreateConVar("bt_transition", "1", "Transitions the timescales if on. If not, timescales are set directly.", FCVAR_PLUGIN);
	bt_timescale = CreateConVar("bt_timescale", "0.50", "Slowdown timescale.", FCVAR_PLUGIN);
	bt_fsound = CreateConVar("bt_fsound", "2", "Plays a sound for the focus of bullet time. If 2 it replaces the default sound rather than playing simultaneously.", FCVAR_PLUGIN);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("player_spawn", EventPlayerSpawn);	
	HookConVarChange(bt_trans, OnConVarChanged_Trans);
	timescale = GetConVarFloat(bt_timescale);
	transition = GetConVarBool(bt_trans);
	focussound = GetConVarBool(bt_fsound);
	Cheats = FindConVar("sv_cheats");
	
	g_CvarPistolLife = CreateConVar("bt_laser_PistolLife", "0.2", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarPistolWidth = CreateConVar("bt_laser_PistolWidth", "2.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarSmg1Life = CreateConVar("bt_laser_Smg1Life", "0.2", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarSmg1Width = CreateConVar("bt_laser_Smg1Width", "2.0", "Width of the Beam",FCVAR_PLUGIN);	
	g_CvarAr2Life = CreateConVar("bt_laser_Ar2Life", "0.2", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarAr2Width = CreateConVar("bt_laser_Ar2Width", "2.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarShotgunLife = CreateConVar("bt_laser_ShotgunLife", "0.2", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarShotgunWidth = CreateConVar("bt_laser_ShotgunWidth", "2.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarS357Life = CreateConVar("bt_laser_357Life", "0.2", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarS357Width = CreateConVar("bt_laser_357Width", "2.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarCrossbowLife = CreateConVar("bt_laser_CrossbowLife", "0.2", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarCrossbowWidth = CreateConVar("bt_laser_CrossbowWidth", "2.0", "Width of the Beam",FCVAR_PLUGIN);
	
	g_CvarTeam2Red = CreateConVar("bt_laser_team2_red", "25", "Amount OF Red In The Beam of Team2", FCVAR_NOTIFY);
	g_CvarTeam2Green = CreateConVar("bt_laser_team2_green", "25", "Amount Of Green In The Beam of Team2", FCVAR_NOTIFY);
	g_CvarTeam2Blue = CreateConVar("bt_laser_team2_blue", "200", "Amount OF Blue In The Beam of Team2", FCVAR_NOTIFY);
	g_CvarTeam3Red = CreateConVar("bt_laser_team3_red", "200", "Amount OF Red In The Beam of Team3", FCVAR_NOTIFY);
	g_CvarTeam3Green = CreateConVar("bt_laser_team3_green", "25", "Amount Of Green In The Beam of Team3", FCVAR_NOTIFY);
	g_CvarTeam3Blue = CreateConVar("bt_laser_team3_blue", "25", "Amount OF Blue In The Beam of Team3", FCVAR_NOTIFY);
	g_CvarNoTeamRed = CreateConVar("bt_laser_noteam_red", "150", "Amount OF Red In The Beam when DM not TDM", FCVAR_NOTIFY);
	g_CvarNoTeamGreen = CreateConVar("bt_laser_noteam_green", "80", "Amount Of Green In The Beam when DM not TDM", FCVAR_NOTIFY);
	g_CvarNoTeamBlue = CreateConVar("bt_laser_noteam_blue", "130", "Amount OF Blue In The Beam when DM not TDM", FCVAR_NOTIFY);	
	g_CvarTrans = CreateConVar("bt_laser_alpha", "150", "Amount OF Transparency In Beam", FCVAR_NOTIFY);	
	
	AutoExecConfig(true,"sm_bullettime_hl2dm", "sm_bullettime_hl2dm");	
}

public OnConfigsExecuted() 
{
    AddFileToDownloadsTable("materials/imgay/slowdown1.vmt");
    AddFileToDownloadsTable("materials/imgay/slowdown2.vmt");
    AddFileToDownloadsTable("materials/imgay/slowdown3.vmt");
    AddFileToDownloadsTable("materials/imgay/slowdown1.vtf");
    AddFileToDownloadsTable("materials/imgay/slowdown2.vtf");
    AddFileToDownloadsTable("materials/imgay/slowdown3.vtf");
}

public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/effects/gunshiptracer.vmt");	
	
	PrecacheSound("mb_bullettime/enter.mp3", true);
	PrecacheSound("mb_bullettime/exit.mp3", true);
	AddFileToDownloadsTable("sound/mb_bullettime/enter.mp3");
	AddFileToDownloadsTable("sound/mb_bullettime/exit.mp3");	
	
	CheatConVarSetup()
} 

ActivateSlow(activator) 
{
    if (slowdown > 0 || !GetConVarBool(bt_enable))
        return;
    slowdown = 55;
    for(new i = 1; i <= MaxClients; i++) 
	{
        if(IsValidClient(i) && !IsFakeClient(i)) 
		{
            ClientCommand(i,"r_screenoverlay imgay/slowdown1");
            if (i != activator) 
			{
                EmitSoundToClient(i, "mb_bullettime/enter.mp3");
            }
        }
    }
    timescale = GetConVarFloat(bt_timescale);
    ServerCommand("host_timescale %f", timescale);
}

public OnGameFrame() 
{
	if (transition && slowdown <= 10 && slowdown > 1)
	{
		timescale = GetConVarFloat(bt_timescale);
		new Float:difscale = 1.0 - timescale;
		new Float:tempscale = 1.0 - difscale * slowdown *0.1;
		ServerCommand("host_timescale %f", tempscale);
	}
	
	if (slowdown == 30)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				EmitSoundToClient(i, "mb_bullettime/exit.mp3");
			}
		}   
	}	

	if (slowdown == 5)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				ClientCommand(i,"r_screenoverlay imgay/slowdown2");
			}
		}   
	}
    
	if (slowdown == 3)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i))
			{
				ClientCommand(i,"r_screenoverlay imgay/slowdown3");
			}
		}   
	}
	if (slowdown == 1)
	{
		slowdown = slowdown - 1;
		ServerCommand("host_timescale 1.0")
		SetConVarInt(Cheats, 0, true, true)
		for(new i = 1; i <= MaxClients; i++) 
		{
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				ClientCommand(i,"r_screenoverlay \"\"")
			}
		}
	}
	if (slowdown > 1)
	{
		slowdown = slowdown - 1;
	}
}

public OnConVarChanged_Trans(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	transition = GetConVarBool(bt_trans);
}

public OnClientPostAdminCheck(client)
{
	g_killCount[client] = 0;	
}

public EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	
	if(IsValidClient(client))
	{	
		g_killCount[client] = 0;
	}
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	// "userid"        "short"         // user ID who was hurt
	// "attacker"      "short"         // user ID who attacked
	// "weapon"        "string"        // weapon name attacker used
	// "health"        "byte"          // health remaining
	// "damage"        "byte"          // how much damage in this attack
	// "hitgroup"      "byte"          // what hitgroup was hit	
	
	if (!GetConVarBool(bt_enable))
		return;
//	new g_damage = GetEventInt(event, "health");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	g_killCount[attacker]++;	
	new curCount = g_killCount[attacker];
   
	new bool:go = false;
	new activator = -1;
	
	if(IsValidClient(attacker))
	{
		decl String:sWeapon[64];
		GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
	
		if (StrEqual("weapon_crowbar",sWeapon) || StrEqual("weapon_frag",sWeapon))
		{		
			go = true;
		}	
		
		focussound = GetConVarBool(bt_fsound);
		if (go == true && focussound >= 1) 
		{
			if(IsValidClient(attacker) && !IsFakeClient(attacker)) 
			{
				EmitSoundToClient(attacker, "mb_bullettime/enter.mp3");
				if (focussound >= 2) activator = attacker;
			}
			ActivateSlow(activator);
			SetConVarInt(Cheats, 1, true, true);
		}
		
		if(curCount == GetConVarInt(bt_kills) && IsValidClient(attacker))
		{
			if(GetConVarInt(bt_enableweapon_bt_pistol))
			{
				EmitSoundToClient(attacker, "mb_bullettime/enter.mp3");	
				ActivateSlow(activator);
				SetConVarInt(Cheats, 1, true, true);
			}
		}
		if(curCount == GetConVarInt(bt_kills) && IsValidClient(attacker))
		{
			if(GetConVarInt(bt_enableweapon_bt_smg1))
			{
				EmitSoundToClient(attacker, "mb_bullettime/enter.mp3");	
				ActivateSlow(activator);
				SetConVarInt(Cheats, 1, true, true);
			}
		}
		if(curCount == GetConVarInt(bt_kills) && IsValidClient(attacker))
		{
			if(GetConVarInt(bt_enableweapon_bt_ar2))
			{
				EmitSoundToClient(attacker, "mb_bullettime/enter.mp3");	
				ActivateSlow(activator);
				SetConVarInt(Cheats, 1, true, true);
			}
		}
		if(curCount == GetConVarInt(bt_kills) && IsValidClient(attacker))
		{
			if(GetConVarInt(bt_enableweapon_bt_shotgun))
			{
				EmitSoundToClient(attacker, "mb_bullettime/enter.mp3");	
				ActivateSlow(activator);
				SetConVarInt(Cheats, 1, true, true);
			}
		}
		if(curCount == GetConVarInt(bt_kills) && IsValidClient(attacker))
		{
			if(GetConVarInt(bt_enableweapon_bt_s357))
			{
				EmitSoundToClient(attacker, "mb_bullettime/enter.mp3");	
				ActivateSlow(activator);
				SetConVarInt(Cheats, 1, true, true);
			}
		}
		if(curCount == GetConVarInt(bt_kills) && IsValidClient(attacker))
		{
			if(GetConVarInt(bt_enableweapon_bt_crossbow))
			{
				EmitSoundToClient(attacker, "mb_bullettime/enter.mp3");	
				ActivateSlow(activator);
				SetConVarInt(Cheats, 1, true, true);
			}
		}		
	}
}


stock bool:IsValidClient(iClient)
{
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

public CheatConVarSetup()
{
	new flags = GetConVarFlags(Cheats) 
	flags &= ~FCVAR_NOTIFY
	SetConVarFlags(Cheats, flags)
	if(GetConVarInt(Cheats) == 1)
	{
		SetConVarInt(Cheats, 0, true, true)
	}
}

public FireBulletsHook(client, shots, String:weaponname[])
{
	if( GetConVarInt(bt_enableweapontracers) )
	{
		new buttons = GetClientButtons(client);	
		
		if ((buttons & IN_ATTACK))
		{				
			new Float:PistolLife;
			PistolLife = GetConVarFloat( g_CvarPistolLife );
			new Float:PistolWidth;
			PistolWidth = GetConVarFloat( g_CvarPistolWidth );		
		
			new Float:Smg1Life;
			Smg1Life = GetConVarFloat( g_CvarSmg1Life );
			new Float:Smg1Width;
			Smg1Width = GetConVarFloat( g_CvarSmg1Width );		
		
			new Float:Ar2Life;
			Ar2Life = GetConVarFloat( g_CvarAr2Life );
			new Float:Ar2Width;
			Ar2Width = GetConVarFloat( g_CvarAr2Width );
	
			new Float:ShotgunLife;
			ShotgunLife = GetConVarFloat( g_CvarShotgunLife );
			new Float:ShotgunWidth;
			ShotgunWidth = GetConVarFloat( g_CvarShotgunWidth );
	
			new Float:S357Life;
			S357Life = GetConVarFloat( g_CvarS357Life );
			new Float:S357Width;
			S357Width= GetConVarFloat( g_CvarS357Width );

			new Float:CrossbowLife;
			CrossbowLife = GetConVarFloat( g_CvarCrossbowLife );
			new Float:CrossbowWidth;
			CrossbowWidth= GetConVarFloat( g_CvarCrossbowWidth );		
	
			decl Float:vecOrigin[3], Float:vecAng[3], Float:vecPos[3];
			GetClientEyePosition(client, vecOrigin);
			GetClientEyeAngles(client, vecAng);
			
			new Handle:trace = TR_TraceRayFilterEx(vecOrigin, vecAng, MASK_SHOT_HULL, RayType_Infinite, TraceEntityFilterPlayer);		
	
			new String:sWeapon[32];
			GetClientWeapon(client,sWeapon, sizeof(sWeapon));			
	
			if( GetConVarInt(bt_enableweapon_pistol))
			{				
				if(StrEqual ("weapon_pistol" , sWeapon))
				{					
					if(TR_DidHit(trace))
					{
						TR_GetEndPosition(vecPos, trace);
						
						CloseHandle(trace);
						
						new color[4];
						if(GetClientTeam(client) == 2)
						{
							color[0] = GetConVarInt( g_CvarTeam2Red ); 
							color[1] = GetConVarInt( g_CvarTeam2Green );
							color[2] = GetConVarInt( g_CvarTeam2Blue );
						}
						else if(GetClientTeam(client) == 3)
						{
							color[0] = GetConVarInt( g_CvarTeam3Red ); 
							color[1] = GetConVarInt( g_CvarTeam3Green );
							color[2] = GetConVarInt( g_CvarTeam3Blue );
						}
						else if(GetClientTeam(client) == 0)
						{
							color[0] = GetConVarInt( g_CvarNoTeamRed ); 
							color[1] = GetConVarInt( g_CvarNoTeamGreen );
							color[2] = GetConVarInt( g_CvarNoTeamBlue );
						}								
						color[3] = GetConVarInt( g_CvarTrans );	
						
						vecOrigin[0] += 20;
						vecOrigin[1] += 0;
						vecOrigin[2] -= 1;	
		
						TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite, 0, 0, 0, PistolLife, PistolWidth, PistolWidth, 1, 0.0, color, 0);
						TE_SendToAll();
					}
				}
			}
			
			if( GetConVarInt(bt_enableweapon_smg1))
			{			
				if(StrEqual ("weapon_smg1" , sWeapon))
				{
					if(TR_DidHit(trace))
					{				
						TR_GetEndPosition(vecPos, trace);
						
						CloseHandle(trace);
						

						new color[4];
						if(GetClientTeam(client) == 2)
						{
							color[0] = GetConVarInt( g_CvarTeam2Red ); 
							color[1] = GetConVarInt( g_CvarTeam2Green );
							color[2] = GetConVarInt( g_CvarTeam2Blue );
						}
						else if(GetClientTeam(client) == 3)
						{
							color[0] = GetConVarInt( g_CvarTeam3Red ); 
							color[1] = GetConVarInt( g_CvarTeam3Green );
							color[2] = GetConVarInt( g_CvarTeam3Blue );
						}
						else if(GetClientTeam(client) == 0)
						{
							color[0] = GetConVarInt( g_CvarNoTeamRed ); 
							color[1] = GetConVarInt( g_CvarNoTeamGreen );
							color[2] = GetConVarInt( g_CvarNoTeamBlue );
						}								
						color[3] = GetConVarInt( g_CvarTrans );
						
						vecOrigin[0] += 20;
						vecOrigin[1] += 0;
						vecOrigin[2] -= 1;	
		
						TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite, 0, 0, 0, Smg1Life, Smg1Width, Smg1Width, 1, 0.0, color, 0);
						TE_SendToAll();
					}					
				}
			}

			if( GetConVarInt(bt_enableweapon_ar2))
			{			
				if(StrEqual ("weapon_ar2" , sWeapon))
				{
					if(TR_DidHit(trace))
					{				
						TR_GetEndPosition(vecPos, trace);
						
						CloseHandle(trace);
						
						new color[4];
						if(GetClientTeam(client) == 2)
						{
							color[0] = GetConVarInt( g_CvarTeam2Red ); 
							color[1] = GetConVarInt( g_CvarTeam2Green );
							color[2] = GetConVarInt( g_CvarTeam2Blue );
						}
						else if(GetClientTeam(client) == 3)
						{
							color[0] = GetConVarInt( g_CvarTeam3Red ); 
							color[1] = GetConVarInt( g_CvarTeam3Green );
							color[2] = GetConVarInt( g_CvarTeam3Blue );
						}
						else if(GetClientTeam(client) == 0)
						{
							color[0] = GetConVarInt( g_CvarNoTeamRed ); 
							color[1] = GetConVarInt( g_CvarNoTeamGreen );
							color[2] = GetConVarInt( g_CvarNoTeamBlue );
						}								
						color[3] = GetConVarInt( g_CvarTrans );	
						
						vecOrigin[0] += 20;
						vecOrigin[1] += 0;
						vecOrigin[2] -= 1;					
		
						TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite, 0, 0, 0, Ar2Life, Ar2Width, Ar2Width, 1, 0.0, color, 0);
						TE_SendToAll();
					}					
				}
			}
			
			if( GetConVarInt(bt_enableweapon_shotgun))
			{			
				if(StrEqual ("weapon_shotgun" , sWeapon))
				{
					if(TR_DidHit(trace))
					{					
						TR_GetEndPosition(vecPos, trace);
						
						CloseHandle(trace);
						
						new color[4];
						if(GetClientTeam(client) == 2)
						{
							color[0] = GetConVarInt( g_CvarTeam2Red ); 
							color[1] = GetConVarInt( g_CvarTeam2Green );
							color[2] = GetConVarInt( g_CvarTeam2Blue );
						}
						else if(GetClientTeam(client) == 3)
						{
							color[0] = GetConVarInt( g_CvarTeam3Red ); 
							color[1] = GetConVarInt( g_CvarTeam3Green );
							color[2] = GetConVarInt( g_CvarTeam3Blue );
						}
						else if(GetClientTeam(client) == 0)
						{
							color[0] = GetConVarInt( g_CvarNoTeamRed ); 
							color[1] = GetConVarInt( g_CvarNoTeamGreen );
							color[2] = GetConVarInt( g_CvarNoTeamBlue );
						}								
						color[3] = GetConVarInt( g_CvarTrans );	
						
						vecOrigin[0] += 20;
						vecOrigin[1] += 0;
						vecOrigin[2] -= 1;						
		
						TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite, 0, 0, 0, ShotgunLife, ShotgunWidth, ShotgunWidth, 1, 0.0, color, 0);
						TE_SendToAll();
					}					
				}
			}
			
			if( GetConVarInt(bt_enableweapon_s357))
			{		
				if(StrEqual ("weapon_357" , sWeapon))
				{
					if(TR_DidHit(trace))
					{				
						TR_GetEndPosition(vecPos, trace);
						
						CloseHandle(trace);					

						new color[4];
						if(GetClientTeam(client) == 2)
						{
							color[0] = GetConVarInt( g_CvarTeam2Red ); 
							color[1] = GetConVarInt( g_CvarTeam2Green );
							color[2] = GetConVarInt( g_CvarTeam2Blue );
						}
						else if(GetClientTeam(client) == 3)
						{
							color[0] = GetConVarInt( g_CvarTeam3Red ); 
							color[1] = GetConVarInt( g_CvarTeam3Green );
							color[2] = GetConVarInt( g_CvarTeam3Blue );
						}
						else if(GetClientTeam(client) == 0)
						{
							color[0] = GetConVarInt( g_CvarNoTeamRed ); 
							color[1] = GetConVarInt( g_CvarNoTeamGreen );
							color[2] = GetConVarInt( g_CvarNoTeamBlue );
						}								
						color[3] = GetConVarInt( g_CvarTrans );	
						
						vecOrigin[0] += 20;
						vecOrigin[1] += 0;
						vecOrigin[2] -= 1;						
		
						TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite, 0, 0, 0, S357Life, S357Width, S357Width, 1, 0.0, color, 0);
						TE_SendToAll();
					}					
				}
			}
			
			if( GetConVarInt(bt_enableweapon_crossbow))
			{				
				if(StrEqual ("weapon_crossbow" , sWeapon))
				{
					if(TR_DidHit(trace))
					{					
						TR_GetEndPosition(vecPos, trace);
						
						CloseHandle(trace);				
						
						new color[4];
						if(GetClientTeam(client) == 2)
						{
							color[0] = GetConVarInt( g_CvarTeam2Red ); 
							color[1] = GetConVarInt( g_CvarTeam2Green );
							color[2] = GetConVarInt( g_CvarTeam2Blue );
						}
						else if(GetClientTeam(client) == 3)
						{
							color[0] = GetConVarInt( g_CvarTeam3Red ); 
							color[1] = GetConVarInt( g_CvarTeam3Green );
							color[2] = GetConVarInt( g_CvarTeam3Blue );
						}
						else if(GetClientTeam(client) == 0)
						{
							color[0] = GetConVarInt( g_CvarNoTeamRed ); 
							color[1] = GetConVarInt( g_CvarNoTeamGreen );
							color[2] = GetConVarInt( g_CvarNoTeamBlue );
						}								
						color[3] = GetConVarInt( g_CvarTrans );	
						
						vecOrigin[0] += 20;
						vecOrigin[1] += 0;
						vecOrigin[2] -= 1;						
		
						TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite, 0, 0, 0, CrossbowLife, CrossbowWidth, CrossbowWidth, 1, 0.0, color, 0);
						TE_SendToAll();
					}					
				}
			}
		}
	}
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_FireBulletsPost, FireBulletsHook);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:client) 
{
	return entity>MaxClients;
}