#pragma semicolon 1
#include <sdktools>
#include <tf2>
#include <tf2attributes>

#define PLUGIN_VERSION "1.0.4a"
public Plugin:myinfo = 
{
	name = "[TF2] G-Fortress",
	author = "Cheddar",
	version = PLUGIN_VERSION
}

//CONVARS
new Handle:hMode = INVALID_HANDLE;
new Handle:hOffset = INVALID_HANDLE;
new Handle:hSize = INVALID_HANDLE;
new Handle:hManageSpeed = INVALID_HANDLE;
new Handle:hManageJump = INVALID_HANDLE;
new Handle:hManageResize = INVALID_HANDLE;
new Handle:hManageUse = INVALID_HANDLE;
new Handle:hManageSpawns = INVALID_HANDLE;
new g_iRunCase;
new g_iTeamSpawnCount;
new g_iPlayerSpawnCount;
new g_iPlayerSpawnID[250];
new bool:g_bRunning;

public OnPluginStart() 
{	
	//Implementing Handles for GFortress Cvars
	hMode = CreateConVar("gfortress_mode", "2", "Set G-Fortress Mode; 0 - Force Disabled, 1 - Force Enabled, 2 - Automatic");
	hManageSpeed = CreateConVar("gfortress_manage_speed", "1", "Enable or disable managing speed; 0 - disabled, 1 - enabled");
	hManageJump = CreateConVar("gfortress_manage_jump", "1", "Enable or disable managing jump; 0 - disabled, 1 - enabled");	
	hManageResize = CreateConVar("gfortress_manage_resize", "1", "Enable or disable managing resize; 0 - disabled, 1 - enabled");
	hManageUse = CreateConVar("gfortress_manage_use", "1", "Enable/Disable and Set Activation Mode for Use Handling; 0 - Disabled, 1 - +Use on Attack1, 2 - +Use on Call for Medic");
	hManageSpawns = CreateConVar("gfortress_manage_spawns", "1", "Enable or disable managing spawns; 0 - disabled, 1 - enabled");
	hOffset = CreateConVar("gfortress_zoffset", "0.25", "Controls the Offset on the Z axis for spawning"); 
	hSize = CreateConVar("gfortress_size", "0.83", "Controls the Size/Speed/Jumpheight for spawning");	
	
	HookEvent("teamplay_round_start", teamplay_round_start, EventHookMode_Pre);
	AddCommandListener(cdVoiceMenu, "voicemenu");
}

public OnAllPluginsLoaded() //After all other plugins have loaded, then we make a hook (to override all other resize on spawn plugins)
{
	HookEvent("player_spawn", OnPlayerSpawn);
}

public OnConfigsExecuted()//After ALL cfgs have loaded :: This is where GFortress scans your map and detects what (if anything) needs to be done
{	
	if(GetConVarInt(hMode) == 0) //IF Force Disabled
	{
		PrintToServer("[G-Fortress] Mode: Force Disabled");
		PrintToServer("[G-Fortress] Run State: --NOT RUNNING--");
		g_bRunning = false;
	}
	else
	{		
		ScanMap(); //Scan the map		
		FigureCase(); //Find Case based on scan
		PrintResults();
	}
}

public Action:teamplay_round_start(Handle:event,const String:name[],bool:dontBroadcast) // This is where we swap spawns (If we can't find any TF2 Spawns)
{
	if(g_bRunning && GetConVarInt(hManageSpawns) == 1) 
	{	
		if(g_iRunCase==1)
		{SwapSpawnsSingle();RespawnClients();}
		if(g_iRunCase==2)
		{SwapSpawnsMulti();RespawnClients();}
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons) //This is my crude way of allowing players to interact with +Use Objects. I'd like to evolve this section.
{ 
	if(g_bRunning && GetConVarInt(hManageUse) == 1)
	{		
		// Check if the player is primary attacking (+attack) 
		if (buttons & IN_ATTACK)
		{ 
			// If so, add the button to use (+use)
			buttons |= IN_USE;	
		} 
		return Plugin_Changed; 	
	}
	return Plugin_Continue;
} 

public Action:cdVoiceMenu(iClient, const String:sCommand[], iArgc) //Contribution by Chdata thanks!
{
    if(g_bRunning && GetConVarInt(hManageUse) == 2)
	{
		if (iArgc < 2)
		{
			return Plugin_Handled;
		}
		decl String:sCmd1[3], String:sCmd2[3];    
		GetCmdArg(1, sCmd1, sizeof(sCmd1));
		GetCmdArg(2, sCmd2, sizeof(sCmd2));    
		// Capture call for medic commands (represented by "voicemenu 0 0")
		if (sCmd1[0] == '0' && sCmd2[0] == '0')
		{
			new ent;
			ent=GetViewedEntity(iClient);
			if(ent!=0)
			AcceptEntityInput(ent, "Use", iClient, iClient, 0);
		}
	}
    return Plugin_Continue;
}

public OnClientPostAdminCheck(client) // When player joins
{
	if(g_bRunning)
	{
		if(GetConVarInt(hManageSpeed)==1)
		{AlterSpeed(client, 1);}		
		if(GetConVarInt(hManageJump)==1)
		{AlterJump(client, 1);}
	}
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bRunning && GetConVarInt(hManageResize) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new Float:fScale = GetConVarFloat(hSize);
		ResizeAndUpdateHitBox(client,fScale);
	}
}

ScanMap()
{
	//Resetting Counters
	g_iTeamSpawnCount=0;
	g_iPlayerSpawnCount=0;
	
	new ent = -1;	
	while((ent = FindEntityByClassname(ent, "info_player_teamspawn")) != -1)
	{
		g_iTeamSpawnCount++;
		return; //If it found a teamspawn then return
	}
	ent = -1;
	while((ent = FindEntityByClassname(ent, "info_player_start")) != -1)
	{
		g_iPlayerSpawnID[g_iPlayerSpawnCount]=ent;		
		g_iPlayerSpawnCount++;
	}
}

PrintResults()
{
	char buffer[512];
	
	//Printing Mode
	switch(GetConVarInt(hMode))
	{
		case 1:{PrintToServer("[G-Fortress] Mode: Force Enabled");}
		case 2:{PrintToServer("[G-Fortress] Mode: Automatic");}
	}
	
	//Printing Scan Results
	if(g_iTeamSpawnCount==0)
	PrintToServer("[G-Fortress] Scan: Found no TF2 Spawns");
	else if(g_iTeamSpawnCount>0)
	PrintToServer("[G-Fortress] Scan: Found at least one TF2 Spawn");
	Format(buffer, sizeof(buffer), "[G-Fortress] Scan: Found %i G-Mod Spawns", g_iPlayerSpawnCount);
	PrintToServer(buffer);
	
	//Printing Case
	Format(buffer, sizeof(buffer), "[G-Fortress] Case: %i", g_iRunCase);
	PrintToServer(buffer);
}

FigureCase()
{
	if(GetConVarInt(hMode) == 1 && g_iPlayerSpawnCount == 0) //No G-Mod Spawn (FORCE ENABLED)
	g_iRunCase=3;
	else if(GetConVarInt(hMode) == 1 && g_iPlayerSpawnCount == 1) //Single G-Mod Spawn (FORCE ENABLED)
	g_iRunCase=1;
	else if(GetConVarInt(hMode) == 1 && g_iPlayerSpawnCount > 1) //Multi G-Mod Spawn (FORCE ENABLED)
	g_iRunCase=2;	
	else if(GetConVarInt(hMode) == 2 && g_iTeamSpawnCount == 0 && g_iPlayerSpawnCount == 1) //No TF2 Spawn && Single G-Mod Spawn (AUTO)
	g_iRunCase=1;
	else if(GetConVarInt(hMode) == 2 && g_iTeamSpawnCount == 0 && g_iPlayerSpawnCount > 1) //No TF2 Spawn && Multi G-Mod Spawn (AUTO) 
	g_iRunCase=2;
	else if(GetConVarInt(hMode) == 2 && g_iTeamSpawnCount > 0 || g_iPlayerSpawnCount == 0) //Yes TF2 Spawn OR No G-Mod Spawn (AUTO)
	g_iRunCase=0;		
	
	if(g_iRunCase==0)
	g_bRunning=false;
	else
	g_bRunning=true;	
}

SwapSpawnsSingle()
{
	new Float:origin[3];
	new Float:angles[3];
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "info_player_start")) != -1)
	{
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", origin);
		GetEntPropVector(ent, Prop_Data, "m_angRotation", angles);
		origin[2]+=GetConVarFloat(hOffset);
		CreateSpawn(origin,angles,TFTeam_Unassigned);
	}
}

SwapSpawnsMulti()
{
	new Float:origin[3];
	new Float:angles[3];
	new ent = -1;
	new TFTeam:redblu = TFTeam_Blue;
	new redblualt = 1;
	while((ent = FindEntityByClassname(ent, "info_player_start")) != -1)
	{
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", origin);
		GetEntPropVector(ent, Prop_Data, "m_angRotation", angles);
		origin[2]+=GetConVarFloat(hOffset);		
			
		CreateSpawn(origin,angles,redblu);	
		
		//Toggle redblu	
		if(redblualt==1)
		{redblu=TFTeam_Red; redblualt=0;}
		else
		{redblu=TFTeam_Blue; redblualt=1;}
	}
}

CreateSpawn(Float:origin[3], Float:angles[3], TFTeam:redblu)
{
	decl tf2spawn;	
	tf2spawn = CreateEntityByName("info_player_teamspawn");
	DispatchKeyValueVector(tf2spawn, "origin", origin);
	DispatchKeyValueVector(tf2spawn, "angles", angles);
	DispatchSpawn(tf2spawn);
	SetEntProp(tf2spawn, Prop_Send, "m_iTeamNum", redblu);
}

RespawnClients()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i))
		{
			TF2_RespawnPlayer(i);
		}
	}  
}

ResizeAndUpdateHitBox(client,Float:fScale) //Thank you https://forums.alliedmods.net/showthread.php?t=250048
{		
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", fScale);	
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };	
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];
	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;
	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}

int GetViewedEntity(client)
{
	new Float:startpos[3];
	new Float:angles[3];
	new Float:endpos[3];
	new Float:distance;
	new ent;
	
	GetClientEyePosition(client,startpos);
	GetClientEyeAngles(client,angles);		
	TR_TraceRayFilter(startpos, angles, MASK_SHOT, RayType_Infinite, SimpleFilter, client);
	TR_GetEndPosition(endpos);	
	distance=GetVectorDistance(startpos,endpos,false);	
	if(distance<150)
	ent = TR_GetEntityIndex();	
	return ent;
}

public bool:SimpleFilter(entity, mask, any:data)
{
	if (!entity || !IsValidEntity(entity))
	return false;
	
	return entity > MaxClients;
}

public Action AlterSpeed(client, args)
{
	TF2Attrib_SetByName(client, "major move speed bonus", GetConVarFloat(hSize));	
}

public Action AlterJump(client, args)
{
	TF2Attrib_SetByName(client, "major increased jump height", GetConVarFloat(hSize));
}