

#include <sourcemod>
#include <sdktools> 




new g_BeamSprite;
new g_HaloSprite;
new Handle:g_hWheelTimer;
new Handle:g_hWheelTime;
new Handle:g_hEffectDuration;
int WheelState = 0;
new redColor[4]	= {200, 25, 25, 255};

//plugin info
public Plugin:myinfo = 
{
	name = "[TF2]Wheel of Doom spawner",
	author = "kgbproject(Tetragromaton)",
	description = "Spawn/Spin/Remove wheel of doom",
	version = "1.3",
	url = "sourcemod.com"
}

public OnPluginStart()
{
	CreateConVar("wod_spawner_version", "1.3", "Spawn wheel of doom version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hWheelTime = CreateConVar("wod_time", "30.0", "Timer after that wheels will spin");
	g_hEffectDuration = CreateConVar("wod_duration", "8.0", "Timer after that wheels will spin");
	RegAdminCmd("sm_spawnwheel", Command_SpawnWheel, ADMFLAG_ROOT);	
	RegAdminCmd("sm_spinwheel", Command_SpinWheel, ADMFLAG_ROOT);
	RegAdminCmd("sm_deletewheel", Command_DeleteWheel, ADMFLAG_ROOT);
}
public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");	
	WheelState = 0;
}

public Action:Command_SpawnWheel(Client, args)
{
	if(WheelState == 0)
	{
	decl Drum;
	new Float:AbsAngles[3], Float:ClientOrigin[3], Float:Origin[3], Float:pos[3], Float:beampos[3], Float:FurnitureOrigin[3], Float:EyeAngles[3];
	decl String:Name[255], String:SteamId[255];
	
	GetClientAbsOrigin(Client, ClientOrigin);
	GetClientEyeAngles(Client, EyeAngles);
	GetClientAbsAngles(Client, AbsAngles);
	
	
	
	GetCollisionPoint(Client, pos);
	
	FurnitureOrigin[0] = pos[0];
	FurnitureOrigin[1] = pos[1];
	FurnitureOrigin[2] = (pos[2] + 15);
	
	beampos[0] = pos[0];
	beampos[1] = pos[1];
	beampos[2] = (FurnitureOrigin[2] + 20);
	
	//Spawn Drum:
	Drum = CreateEntityByName("wheel_of_doom");
	TeleportEntity(Drum, FurnitureOrigin, AbsAngles, NULL_VECTOR);

	new String:duration[35];
	Format(duration, sizeof(duration), "%i", GetConVarInt(g_hEffectDuration));
	new Float:lol;
	lol = GetConVarFloat(g_hWheelTime);
	DispatchKeyValue(Drum, "targetname", "wod_wheel");
	DispatchKeyValue(Drum, "has_spiral", "1");
	DispatchKeyValue(Drum, "effect_duration",duration);
	DispatchSpawn(Drum);
	ActivateEntity(Drum);
	AcceptEntityInput(Drum, "Spin");
	WheelState = 1;//spawned already.
	g_hWheelTimer = CreateTimer(lol, AutoSpin, Drum,TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE|TIMER_HNDL_CLOSE); //timer to automatically spin wheel !!!
	//Log
	GetClientAuthString(Client, SteamId, 255);
	GetClientName(Client, Name, 255);
	LogAction(Client, Client, "Client %s <%s> spawned an wheel of doom !", SteamId, Name);
	PrintToServer("Client %s <%s> spawned an wheel of doom !", SteamId, Name);
	
	//Send BeamRingPoint:
	GetEntPropVector(Drum, Prop_Data, "m_vecOrigin", Origin);
	TE_SetupBeamRingPoint(FurnitureOrigin, 10.0, 150.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 20, 0);
	TE_SendToAll();
	} else PrintToChat(Client, "Wheel already spawned. Use !deletewheel to spawn new.");
	return Plugin_Handled;
}
public Action:AutoSpin(Handle Timer, any:drum)
{
	//PrintToChatAll("debug wheels spinned !");
	new entCount = GetEntityCount(); 
	for(new  i = 0; i != entCount; i++ )  {
		if(IsValidEntity(i)) {
			decl String:strName[32];
			GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName)); 
			if(StrEqual(strName, "wod_wheel"))
			{
				AcceptEntityInput(drum, "Spin");	
			}
		}
	}
// PrintToChatAll("Rolling the Wheel of Doom !");
}

public Action:Command_SpinWheel(client, args)
{
	new entCount = GetEntityCount(); 
	for(new  i = 0; i != entCount; i++ )  {
		if(IsValidEntity(i)) {
			decl String:strName[32];
			GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName)); 
			if(StrEqual(strName, "wod_wheel"))
			{
				AcceptEntityInput(i, "Spin");
			}
		}
	}
 //PrintToChat(client, "Spinning wheel of doom :)");
}

public Action:Command_DeleteWheel(client, args)
{
	WheelState = 0;//no wheels at the moment
	new entCount = GetEntityCount(); 
	for(new  i = 0; i != entCount; i++ )  {
		if(IsValidEntity(i)) {
			decl String:strName[32];
			GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName)); 
			if(StrEqual(strName, "wod_wheel"))
			{
				AcceptEntityInput(i, "kill");
				CloseHandle(g_hWheelTimer);
			}
		}
	}
	return Plugin_Stop;
}


stock GetCollisionPoint(client, Float:pos[3])
{
	decl Float:vOrigin[3], Float:vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		
		return;
	}
	
	CloseHandle(trace);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients;
}