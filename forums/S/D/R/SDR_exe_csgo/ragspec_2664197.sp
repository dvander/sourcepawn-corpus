#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.3"

new Handle:g_resettime
new String:g_AttachName[64] = "facemask"
new String:g_ModelName[128] = "models/Effects/teleporttrail.mdl"

public Plugin:myinfo = {
	name = "Ragdoll death spec",
	author = "BlackOps7799 & KOROVKA",
	description = "When you die your view is set to your ragdolls eyes!",
	version = VERSION,
	url = ""
}

public OnPluginStart()
{	
	g_resettime = CreateConVar("sm_ragspec_reset_time", "4")
	
	HookEvent( "player_death", Player_Died, EventHookMode_Post )
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

public Player_Died( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) )
	
	new ragdoll = -1;
	
	decl String:buffer[16];
		
	for (new i = MaxClients, max_ent = GetMaxEntities(); i < max_ent; i++)
	{
		if(IsValidEntity(i) && GetEdictClassname(i, buffer, 16) && strcmp(buffer, "prop_ragdoll", true) == 0)	
		{
			if(GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client) 
			{
				ragdoll = i;
				break;
			}
		}
	}
	
	if(ragdoll == -1)
		ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	if ( ragdoll <= MaxClients || !IsValidEntity(ragdoll) )
		return
	
	new Float:Position[3] = {0.0, 0.0, 0.0}
	new HeadEnt = SpawnModelAndAttach(client, ragdoll, g_ModelName, g_AttachName, Position)
	
	if ( HeadEnt != -1 )
	{
		SetClientViewEntity( client, HeadEnt )
		
		new Float:resettime = GetConVarFloat( g_resettime );
		if ( resettime > 0.0 )
			CreateTimer( resettime, ResetDeathView, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE )
	}
}

public Action:ResetDeathView( Handle:timer, any:client )
{
	if (( client = GetClientOfUserId( client ) ) == 0 || IsPlayerAlive( client ) )
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

	SetEntityRenderMode(Entity, RENDER_NONE)

	return Entity
}  