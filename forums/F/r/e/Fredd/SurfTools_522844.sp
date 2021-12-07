#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

new Handle:Enabled;
new Handle:RespawnEnabled;
new Handle:RespawnTime;
new Handle:NoBlock;
new Handle:SpawnProtection;
new Handle:SpawnWeapon;
new Handle:BhopPush;
new Handle:BhopHeight;
new Handle:SurfCvars; 

new VelOff_0;
new VelOff_1;
new BaseVelOff;
new CollOff;

new bool:EventsHooked;

public Plugin:myinfo = 
{
	name = "Surf Tools",
	author = "Fredd",
	description = "Adds Fun to Surf Servers",
	version = "1.6",
	url = "www.sourcemod.net"
}
public OnMapStart(){
	decl String:MapName[32];
	GetCurrentMap(MapName, sizeof(MapName));
	
	if(StrContains(MapName, "surf") != -1)
	{
		SetConVarInt(Enabled, 1);
		LogMessage("[SurfTools] SurfTools is Enabled");
		new SCvars = GetConVarInt(SurfCvars);
		
		if(SCvars == 1)
		{
			LogMessage("[SurfTools] Changing server cvars for 1337 surfing...");
			ServerCommand("sv_airaccelerate 999");
		} else
		{
			LogMessage("[SurfTools] Server cvars have not been changed for good surfing...set 'st_surfcvars' to 1 and reload the map for cvars to be changed"); 
		}
	} else 
	{
		SetConVarInt(Enabled, 0);
		LogMessage("[SurfTools] SurfTools is disbaled: Not a valid surf map");
	}	
}

public OnPluginStart()
{
	CreateConVar("st_version", "1.6", "Surf tools Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	Enabled  			=    	CreateConVar("st_enabled", 		"1", 				"0 = Plugin Disabled, 1 = Plugin Enabled");
	RespawnEnabled		=	CreateConVar("st_respawn",	"1",		"enabled/disable respawn");
	RespawnTime 		=    	CreateConVar("st_respawntime", 	"5", 				"Ammount of time to respawn after a user dies");
	NoBlock  			=    	CreateConVar("st_noblock", 		"1", 				"Toggles on and off no blocking");
	SpawnProtection 	=   	CreateConVar("st_sptime", 		"5", 				"Sets the amount of seconds user's will be protected from getting killed on their respawn");
	SpawnWeapon   		=  		CreateConVar("st_spawnweapon", 	"weapon_scout", 	"sets wether the client should get a scout on respawn or not");
	BhopPush    		=   	CreateConVar("st_bhoppush",		"1.0",				"The forward push when you jump");
	BhopHeight  		=		CreateConVar("st_bhopheight",	"1.0",				"The upward push when you jump");
	SurfCvars			=		CreateConVar("st_surfcvars", 	"1", 				"1 = Enabled surf cvars, 0 disable them(def = 1)");
	
	VelOff_0    		=   	FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	VelOff_1    		=   	FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	BaseVelOff			= 		FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	
	CollOff 			= 		FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	
	EventsHooked = true;
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	
	
	HookConVarChange(Enabled, OnConVarChange);
	
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_jump",PlayerJump);
	
	
	CreateTimer(60.0, PrintMsg, _, TIMER_REPEAT);
}
public Action:PrintMsg(Handle:timer)
{
	if(GetConVarInt(Enabled) == 1)
		PrintToChatAll("\x04[SurfTools]\x01This server is running \x04SurfTools\x01, to respawn type \x04/respawn\x01 or \x04respawn");
}
public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new value = !!StringToInt(newValue);
	if (value == 0)
	{
		if (EventsHooked == true)
		{
			EventsHooked = false;
			
			UnhookEvent("player_death", PlayerDeath);
			UnhookEvent("player_spawn", PlayerSpawn);
			UnhookEvent("player_jump",PlayerJump);			
		}
	}
	else
	{
		EventsHooked = true;
		
		HookEvent("player_death", PlayerDeath);
		HookEvent("player_spawn", PlayerSpawn);
		HookEvent("player_jump",PlayerJump);	
	}
}
public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(RespawnEnabled) == 0)
		return Plugin_Continue;
		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RespawnClient(client);
	
	return Plugin_Continue;
}
public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Team = GetClientTeam(client);
	
	if(IsPlayerAlive(client) && (Team == 2 || Team == 3))
	{
		decl String:WpnName[33];
		GetConVarString(SpawnWeapon, WpnName, sizeof(WpnName));
		
		SpawnProtctClient(client);
		GivePlayerItem(client, "weapon_knife");
		
		if(GetConVarInt(NoBlock) == 1)
			SetEntData(client, CollOff, 2, 4, true);

		if(StrContains(WpnName, "weapon_") != -1)
			GivePlayerItem(client, WpnName);
		else
			LogError("st_spawnweapon is not set to a valid weapon name..");
	
		RemoveModels();
	}
	return Plugin_Continue;
}
public PlayerJump(Handle:event,const String:name[],bool:dontBroadcast)
{
	new index   =  GetClientOfUserId(GetEventInt(event,"userid"));
	new Float:finalvec[3];
	
	finalvec[0] =    GetEntDataFloat(index,VelOff_0)*GetConVarFloat(BhopPush)/2.0;
	finalvec[1] =    GetEntDataFloat(index,VelOff_1)*GetConVarFloat(BhopPush)/2.0;
	finalvec[2] =    GetConVarFloat(BhopHeight)*50.0;
	
	SetEntDataVector(index,BaseVelOff,finalvec,true);
}
public Action:Command_Say(client, args)
{
	if(GetConVarInt(RespawnEnabled) == 0)
		return Plugin_Continue;
		
	if(GetConVarInt(Enabled) == 1)
	{   
		decl String:text[192];
		GetCmdArgString(text, sizeof(text));
		
		new startidx = 0;
		if (text[0] == '"')
		{
			startidx = 1;
			
			new len = strlen(text);
			if (text[len-1] == '"')
			{
				text[len-1] = '\0';
			}
		}
		if(StrEqual(text[startidx], "/respawn") || StrEqual(text[startidx], "respawn"))
			RespawnClient(client);
	}
	return Plugin_Continue;
}
stock RespawnClient(client)
{
	new Team = GetClientTeam(client);
	
	if(Team == 0 || Team == 1)
	{
		PrintToChat(client, "\x04[SurfTools]\x01You must be on a team first");
		return;
	}
	if(IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04[SurfTools]\x01You must be dead");
		return;
	}   
	new Float:Timer = float(GetConVarInt(RespawnTime));
	
	PrintToChat(client, "\x04[SurfTools]\x01You will be respawned in \x04%i \x01seconds", RoundToNearest(Timer));
	CreateTimer(Timer, Respawn, client);
	
	return;
}
stock SpawnProtctClient(client)
{
	new Float:Timer = float(GetConVarInt(SpawnProtection));
	
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	PrintToChat(client, "\x04[SurfTools] \x01you will be spawn protected for \x04%i \x01seconds", RoundToNearest(Timer));
	CreateTimer(Timer, RemoveSpawnProtection, client);
	
	return;
}
public Action:RemoveSpawnProtection(Handle:Timer, any:client)
{
	if(!IsClientInGame(client))
		return;
	
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	PrintToChat(client, "\x04[SurfTools] \x01spawn protection is now off..");
	
	return;
}
public Action:Respawn(Handle:Timer, any:client)
{
	if(!IsClientInGame(client) || IsPlayerAlive(client))
		return;
	
	new Team = GetClientTeam(client);
	if(Team == 0 || Team == 1)
		return;
	
	CS_RespawnPlayer(client);
	
	return;
}
stock RemoveModels()
{
	new start = GetMaxClients();
	
	for(new i = start+1; i <= GetMaxEntities(); i++)
	{
		if(IsValidEntity(i))
		{
			new String:EntModel[128];
			GetEntPropString(i, Prop_Data, "m_ModelName", EntModel, sizeof(EntModel));
			
			if ((StrContains(EntModel, "models/weapons/w_knife.mdl") != -1) ||
				(StrContains(EntModel, "models/weapons/w_knife_t.mdl") != -1) ||
			(StrContains(EntModel, "models/weapons/w_knife_ct.mdl") != -1))
			
			RemoveEdict(i);
		}
	}
}
