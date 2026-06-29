#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.3"

new Handle:g_resettime
new String:g_AttachName[64] = "forward"
new String:g_ModelName[128] = "models/Effects/teleporttrail.mdl"

public Plugin:myinfo = {
	name = "Ragdoll death spec",
	author = "BlackOps7799",
	description = "When you die your view is set to your ragdolls eyes!",
	version = VERSION,
	url = ""
}

public OnPluginStart()
{	
	CreateConVar( "sm_ragspec_version", VERSION, "Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY )
	g_resettime = CreateConVar("sm_ragspec_reset_time", "4")
	
	HookEvent( "player_death", Player_Died )
	HookEvent( "player_spawn", Event_Spawn )
	
	decl String:Mod[25]
	GetGameFolderName( Mod, sizeof(Mod) )
	
	if( StrEqual( Mod, "dod" ) )
		g_AttachName = "head"
	else if( StrEqual( Mod, "tf" ) )
		g_AttachName = "head"
	else if( StrEqual( Mod, "cstrike" ) )
		g_AttachName = "forward"
		//anim_attachment_head
	else if( StrEqual( Mod, "hl2mp" ) )
		g_AttachName = "eyes"
	else if( StrEqual( Mod, "left4dead" ) )
	{
		g_AttachName = "eyes"
		g_ModelName = "models/gibs/glass_shard03.mdl"
	}
	
	PrecacheModel( g_ModelName, true )
}

public Event_Spawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client 	= GetClientOfUserId(GetEventInt(event, "userid"));
	SetClientViewEntity( client, client );
}

public Action:Player_Died( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client
	client = GetClientOfUserId( GetEventInt( event, "userid" ) )
	
	new ragdoll = GetEntPropEnt( client, Prop_Send, "m_hRagdoll" )
	if ( ragdoll == -1 )
	{
		PrintToServer("[RAG-SPEC] Could not get ragdoll for player!")
		return Plugin_Continue
	}
	
	new Float:Position[3] = {0.0, 0.0, 0.0}
	new HeadEnt = SpawnModelAndAttach(client, ragdoll, g_ModelName, g_AttachName, Position)
	
	if ( HeadEnt == -1 )
	{
		return Plugin_Continue
	}
	else
	{
		SetClientViewEntity( client, HeadEnt )
		
		if ( GetConVarFloat( g_resettime ) > 0.0 )
			CreateTimer( GetConVarFloat( g_resettime ), ResetDeathView, client )
		
		return Plugin_Continue
	}
}

public Action:ResetDeathView( Handle:timer, any:client )
{
	if ( !IsValidEntity( client ) || IsPlayerAlive( client ) )
		return
	
	SetClientViewEntity( client, client )
}

SpawnModelAndAttach(client, ent, String:StrModel[], String:StrAttachment[], Float:Offset[3])
{
	PrecacheModel( StrModel, true )

	new String:StrName[64]; Format(StrName, sizeof(StrName), "ent%i", ent)
	DispatchKeyValue(ent, "targetname", StrName)
	
	new Entity = CreateEntityByName("prop_dynamic")
	if ( Entity == -1 )
	{
		PrintToServer("[RAG-SPEC] Failed to create prop_dynamic!")
		return -1
	}
	
	new String:StrEntityName[64]; Format(StrEntityName, sizeof(StrEntityName), "eye_ent%i", Entity)
	
	DispatchKeyValue(Entity, "targetname", StrEntityName)
	DispatchKeyValue(Entity, "parentname", StrName)
	DispatchKeyValue(Entity, "model",      StrModel)
	DispatchKeyValue(Entity, "solid",      "0")
	SetEntityModel(Entity, StrModel)
	DispatchSpawn(Entity)

	new Float:Position[3]; GetClientAbsOrigin(client, Position)
	Position[0] += Offset[0]
	Position[1] += Offset[1]
	Position[2] += Offset[2]
	TeleportEntity(Entity, Position, NULL_VECTOR, NULL_VECTOR)

	SetVariantString(StrName)
	AcceptEntityInput(Entity, "SetParent", Entity, Entity, 0)

	if (StrEqual(StrAttachment, "") == false)
	{
		SetVariantString(StrAttachment)
		AcceptEntityInput(Entity, "SetParentAttachment", Entity, Entity, 0)
	}

	//AcceptEntityInput(Entity, "TurnOn")
	
	SetEntityRenderMode(Entity, RENDER_NONE) //Invisible

	if ( IsValidEntity(Entity) )
		return Entity
	else
		return -1
}  