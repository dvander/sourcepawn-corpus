#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <ToggleEffects>
#define VERSION "1.2"

new g_Hat[MAXPLAYERS+1];
new bool:g_bToggleEffects = false;
new Handle:g_hLookupAttachment = INVALID_HANDLE;
new Handle:CvarEnable;

public Plugin:myinfo = 
{
	name = "Christmas Hat",
	author = "Xilver266 Steam: donchopo",
	description = "Put a Christmas hat to players at spawn",
	version = VERSION,
	url = "servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
	AutoExecConfig(true, "christmas_hat");
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	CreateConVar("sm_christmas_hat_version", VERSION, "Christmas Hat", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	new Handle:hGameConf = LoadGameConfigFile("hats.gamedata");
	g_bToggleEffects = LibraryExists("ToggleEffects");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "LookupAttachment");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hLookupAttachment = EndPrepSDKCall();
	CvarEnable = CreateConVar("sm_christmas_hat_enable", "1", "Enable Christmas hats. 0 -No | 1 -Yes", _, true, 0.0, true, 1.0);
}

public OnMapStart()
{
	AddFileToDownloadsTable("materials/models/santahat/furballs.vmt");
	AddFileToDownloadsTable("materials/models/santahat/santahat.vmt");
	AddFileToDownloadsTable("materials/models/santahat/santahat.vtf");
	AddFileToDownloadsTable("models/santahat/santahat.mdl");
	AddFileToDownloadsTable("models/santahat/santahat.phy");
	AddFileToDownloadsTable("models/santahat/santahat.vvd");
	AddFileToDownloadsTable("models/santahat/santahat.sw.vtx");
	AddFileToDownloadsTable("models/santahat/santahat.dx80.vtx");
	AddFileToDownloadsTable("models/santahat/santahat.dx90.vtx");
	PrecacheModel("models/santahat/santahat.mdl");
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	RemoveHat(client);
	CreateTimer(0.0, TimerCreateHats, client);
	
	return Plugin_Continue;
}

public Action:TimerCreateHats(Handle:timer, any:client)
{
	if (GetConVarBool(CvarEnable))
		CreateHat(client);
		
	return Plugin_Stop;
}

CreateHat(client)
{	
	if(!LookupAttachment(client, "forward"))
		return;
		
	if(GetClientTeam(client) == 1)
		return;

	new Float:or[3];
	new Float:ang[3];
	new Float:fForward[3];
	new Float:fRight[3];
	new Float:fUp[3];
	GetClientAbsOrigin(client,or);
	GetClientAbsAngles(client,ang);
	
	ang[0] += 0.0;
	ang[1] += 0.0;
	ang[2] += 0.0;

	new Float:fOffset[3];
	fOffset[0] = 0.0;
	fOffset[1] = -1.0;
	fOffset[2] = 6.0;

	GetAngleVectors(ang, fForward, fRight, fUp);

	or[0] += fRight[0]*fOffset[0]+fForward[0]*fOffset[1]+fUp[0]*fOffset[2];
	or[1] += fRight[1]*fOffset[0]+fForward[1]*fOffset[1]+fUp[1]*fOffset[2];
	or[2] += fRight[2]*fOffset[0]+fForward[2]*fOffset[1]+fUp[2]*fOffset[2];
	
	new ent = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(ent, "model", "models/santahat/santahat.mdl");
	DispatchKeyValue(ent, "spawnflags", "4");
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	DispatchSpawn(ent);	
	AcceptEntityInput(ent, "TurnOn", ent, ent, 0);
	
	g_Hat[client] = ent;
	
	SDKHook(ent, SDKHook_SetTransmit, ShouldHide);

	TeleportEntity(ent, or, ang, NULL_VECTOR); 
	
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent, 0);
	
	SetVariantString("forward");
	AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RemoveHat(client);
}

public OnClientDisconnect(client)
{
	RemoveHat(client);
}

public Action:ShouldHide(ent, client)
{
	if(g_bToggleEffects)
		if(!ShowClientEffects(client))
			return Plugin_Handled;
			
	if(ent == g_Hat[client])
		return Plugin_Handled;
			
	if(IsClientInGame(client))
		if(GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 && GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")>=0)
			if(ent == g_Hat[GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")])
				return Plugin_Handled;
	
	return Plugin_Continue;
}

stock LookupAttachment(client, String:point[])
{
    if(g_hLookupAttachment==INVALID_HANDLE) return 0;
    if( client<=0 || !IsClientInGame(client) ) return 0;
    return SDKCall(g_hLookupAttachment, client, point);
}

public RemoveHat(client)
{
	if (g_Hat[client] != 0 && IsValidEdict(g_Hat[client]))
	{
		AcceptEntityInput(g_Hat[client], "Kill");
		SDKUnhook(g_Hat[client], SDKHook_SetTransmit, ShouldHide);
		g_Hat[client] = 0;
	}
}
