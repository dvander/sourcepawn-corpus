#include <sourcemod>
#include <sdktools>
#include tf2_stocks
#pragma semicolon 1

new Handle:g_huntsman_allowed = INVALID_HANDLE;
new Handle:g_alwaysdecap = INVALID_HANDLE;
new Handle:g_decapswitch = INVALID_HANDLE;

static DecapTypes[1] = {1}; //for future additions
static DecapTypeCount = 1; //for future additions

public Plugin:myinfo =
{

	name = "Team Headless 2",
	author = "eee (credit to PinkFaerie)",
	description = "Decapitations",
	version = "1.0",
	url = "Ants"
}


public OnPluginStart()
{
	CreateConVar("tf2_decap_ver", "1.0", "[TF2DECAP] Info: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_alwaysdecap = CreateConVar("tf2decap_decap_always", "0", "[TF2DECAP] Decap no matter what (default 0)", FCVAR_PLUGIN);
	g_decapswitch = CreateConVar("tf2decap_decapitations", "1", "[TF2DECAP] Allow this plugin to roll some heads.", FCVAR_PLUGIN);
	g_huntsman_allowed = CreateConVar("tf2decap_decap_huntsman", "1", "[TF2DECAP] Allows Huntsman to decapitate.", FCVAR_PLUGIN);
	HookEvent("player_death", EventDeath, EventHookMode_Pre);
}

public EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	new candecap = GetConVarInt(g_decapswitch);
	if (!candecap) return;
	// Most of this really isn't mine, just the checks and the decapitation part (changed from m_bGib prop).

	decl Client, Attacker;
	decl Float:ClientOrigin[3];

	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	GetClientAbsOrigin(Client, ClientOrigin);

	if(Attacker != 0 && Attacker != Client)
	{
		if(IsClientInGame(Client) && IsClientInGame(Attacker))
		{

			new ck = GetEventInt(Event, "customkill");
			new hc = GetEventInt(Event, "weaponid"); // huntsman check
			
			new huntsvar = GetConVarInt(g_huntsman_allowed);
			new ak = GetConVarInt(g_alwaysdecap);
			
			
			if ((hc == 60) && (!huntsvar) && !ak) return;
			for(new X = 0; X < DecapTypeCount; X++)
			{

				if(ck == DecapTypes[X] || (ak == 1))
				{
	
					decl Ent;

					new vteam = GetClientTeam(Client);
					new vclass = int:TF2_GetPlayerClass(Client);

					Ent = CreateEntityByName("tf_ragdoll");
 
					//(thank you so much, Pinkfairie)
					SetEntPropVector(Ent, Prop_Send, "m_vecRagdollOrigin", ClientOrigin); 
					SetEntProp(Ent, Prop_Send, "m_iPlayerIndex", Client); 
					// instead of gibbing, let's decapitate them.
					SetEntProp(Ent, Prop_Send, "m_iDamageCustom", 20); //This is a decapitation customkill, applied to ragdoll.
					SetEntProp(Ent, Prop_Send, "m_iTeam", vteam); //make sure the team
					SetEntProp(Ent, Prop_Send, "m_iClass", vclass); //and the class are correct or else the ragdoll is odd.
 
					DispatchSpawn(Ent);

					//Remove Body:
					CreateTimer(0.1, RemoveBody, Client);
					CreateTimer(15.0, RemoveGibs, Ent);
				}
			}
		}
	}
}

public Action:RemoveBody(Handle:Timer, any:Client)
{

	decl BodyRagdoll;

	BodyRagdoll = GetEntPropEnt(Client, Prop_Send, "m_hRagdoll");

	if(IsValidEdict(BodyRagdoll)) RemoveEdict(BodyRagdoll);
}

public Action:RemoveGibs(Handle:Timer, any:Ent)
{

	if(IsValidEntity(Ent))
	{

		decl String:Classname[64];

		GetEdictClassname(Ent, Classname, sizeof(Classname));

		if(StrEqual(Classname, "tf_ragdoll", false))
		{

			RemoveEdict(Ent);
		}
	}
}
