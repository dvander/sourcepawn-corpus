#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>


#define PLUGIN_NAME		 	"PortalMod Cube"
#define PLUGIN_AUTHOR	   	"Erreur 500"
#define PLUGIN_DESCRIPTION	"Add Portal companion cube in TF2"
#define PLUGIN_VERSION	  	"1.0.0"
#define PLUGIN_CONTACT	  	"erreur500@hotmail.fr"

#define CUBE				"models/companion_cube/companion_cube.mdl"

new ClientCube[MAXPLAYERS+1] 	= {-1, ...};
new FlagImmunity 				= -1;

new Handle:cvarEnabled			= INVALID_HANDLE;
new Handle:cvarFlag				= INVALID_HANDLE;

public Plugin:myinfo =
{
	name		= PLUGIN_NAME,
	author	  	= PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version	 	= PLUGIN_VERSION,
	url		 	= PLUGIN_CONTACT
};

public OnPluginStart()
{
	CreateConVar("portalcube_version", PLUGIN_VERSION, "portalmod cube version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarEnabled  	= CreateConVar("portalcube_enable", 	"1", 	"Enable or disable portalmod_cube ?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarFlag	  	= CreateConVar("portalcube_flag", 		"-1", 	"Flag allow to receive the portalgun (else -1)", FCVAR_PLUGIN);
	
	RegConsoleCmd("portalcube", OpenPortalCubeMenu, "Drop Portal Cube");
	
	HookEvent("player_team", EventPlayerTeamPost, EventHookMode_Post);
	
	HookConVarChange(cvarFlag, CallBackCVarFlag);
}

public OnPluginEnd()
{
	for(new i=0; i<MaxClients; i++)
		if(!IsValidClient(i))
			RemovePortalCube(i);
}

public OnMapStart()
{	
	if(!GetConVarBool(cvarEnabled))
	{
		return;
	}
	
	decl String:Patch[64];
	for(new i=0; i<15; i++)
	{
		Format(Patch, sizeof(Patch), "materials/models/companion_cube/skin%i.vmt", i);
		AddFileToDownloadsTable(Patch);
		Format(Patch, sizeof(Patch), "materials/models/companion_cube/skin%i.vtf", i);
		AddFileToDownloadsTable(Patch);
	}


	AddFileToDownloadsTable("models/companion_cube/companion_cube.dx80.vtx");
	AddFileToDownloadsTable("models/companion_cube/companion_cube.dx90.vtx");
	AddFileToDownloadsTable("models/companion_cube/companion_cube.sw.vtx");
	AddFileToDownloadsTable("models/companion_cube/companion_cube.vvd");
	AddFileToDownloadsTable("models/companion_cube/companion_cube.mdl");
	
	PrecacheModel(CUBE);
}

public OnClientDisconnect(client)
{
	if(!GetConVarBool(cvarEnabled))
		return;
		
	if(!IsValidClient(client))
		return;
		
	RemovePortalCube(client);
}

public Action:EventPlayerTeamPost(Handle:hEvent, const String:strName[], bool:bHidden)
{
	if(!GetConVarBool(cvarEnabled))
		return Plugin_Continue;
		
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new Team = GetEventInt(hEvent, "team");
	
	if(!IsValidClient(client))
		return Plugin_Continue;
		
	if(Team < 2 || Team > 3 )
		RemovePortalCube(client);
		
	return Plugin_Continue;	
}

public CallBackCVarFlag(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	for(new i=0; i<MaxClients; i++)
		if(IsValidClient(i))
			if(GetUserFlagBits(i) & FlagImmunity)
				RemovePortalCube(i);
	
	GetImmunityFlag(newVal);
}

GetImmunityFlag(const String:Value[])
{
	new FlagsList[21]	= {ADMFLAG_RESERVATION, ADMFLAG_GENERIC, ADMFLAG_KICK, ADMFLAG_BAN, ADMFLAG_UNBAN, ADMFLAG_SLAY, ADMFLAG_CHANGEMAP, ADMFLAG_CONVARS, ADMFLAG_CONFIG, ADMFLAG_CHAT, ADMFLAG_VOTE, ADMFLAG_PASSWORD, ADMFLAG_RCON, ADMFLAG_CHEATS, ADMFLAG_CUSTOM1, ADMFLAG_CUSTOM2, ADMFLAG_CUSTOM3, ADMFLAG_CUSTOM4, ADMFLAG_CUSTOM5, ADMFLAG_CUSTOM6, ADMFLAG_ROOT};
	new String:FlagsLetter[21][2] = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "z"};
	for(new i=0; i<21; i++)
	{
		if(StrEqual(Value, FlagsLetter[i]))
		{
			FlagImmunity = FlagsList[i];
			return;
		}
	}
	
	FlagImmunity = -1;
}

CanReceiveCube(client)
{
	new flags = GetUserFlagBits(client);
	if(flags & ADMFLAG_GENERIC || flags & ADMFLAG_ROOT)
		return true;
		
	if(FlagImmunity == -1)
		return true;
	
	if(flags & FlagImmunity)
		return true;
			
	return false;
}

public Action:OpenPortalCubeMenu(client, Args)
{	
	if(!GetConVarBool(cvarEnabled)) return;
	if(!IsValidClient(client)) return;
	if(!CanReceiveCube(client)) 
	{
		PrintToChat(client, "[PM_Cube] You are not allowed to use this command!");
		return;
	}
	
	
	new Handle:CubeMenu = CreateMenu(Menu_ans);
	
	if(EntRefToEntIndex(ClientCube[client]) != -1)
	{
		SetMenuTitle(CubeMenu, "What do you want to do?");
		AddMenuItem(CubeMenu, "0", "I lost my beautiful cube!");
		AddMenuItem(CubeMenu, "1", "I love it so much ... but remove it!");
	}
	else
	{
		SetMenuTitle(CubeMenu, "Which cube do you want?");
		AddMenuItem(CubeMenu, "0", "Skin: Blue");
		AddMenuItem(CubeMenu, "1", "Skin: Companion");
		AddMenuItem(CubeMenu, "2", "Skin: Yellow");
		AddMenuItem(CubeMenu, "3", "Skin: Burned Blue");
		AddMenuItem(CubeMenu, "4", "Skin: Yellow Companion");
		AddMenuItem(CubeMenu, "5", "Skin: Burned Yellow");
		AddMenuItem(CubeMenu, "6", "Skin: Green");
		AddMenuItem(CubeMenu, "7", "Skin: Red");
		AddMenuItem(CubeMenu, "8", "Skin: Green Stripes");
		AddMenuItem(CubeMenu, "9", "Skin: White");
		AddMenuItem(CubeMenu, "10", "Skin: Disk");
		AddMenuItem(CubeMenu, "11", "Skin: Sky");
		AddMenuItem(CubeMenu, "12", "Skin: Peace");
		AddMenuItem(CubeMenu, "13", "Skin: Red Stripes");
		AddMenuItem(CubeMenu, "14", "Skin: USA");
	}

		
	SetMenuExitButton(CubeMenu, true);
	DisplayMenu(CubeMenu, client, MENU_TIME_FOREVER);
}

public Menu_ans(Handle:menu, MenuAction:action, client, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		if(EntRefToEntIndex(ClientCube[client]) != -1)
		{
			if(args == 0)
			{
				decl Float:Pos[3];
				decl Float:Ang[3];
				GetClientEyePosition(client, Pos);
				GetEntPropVector(client, Prop_Data, "m_angRotation", Ang);
				
				new Handle:trace = INVALID_HANDLE;
				decl Float:EndPos[3];
				
				trace = TR_TraceRayFilterEx(Pos, Ang, MASK_SOLID, RayType_Infinite, TraceEntityFilterEntities, client);		
				if (!TR_DidHit(trace)) 
				{
					CloseHandle(trace);
					OpenPortalCubeMenu(client, 0);
					return;
				}
				
				TR_GetEndPosition(EndPos, trace);
				CloseHandle(trace);
				
				if(GetVectorDistance(EndPos, Pos, false) < 90.0)
				{
					PrintToChat(client, "[PM_Cube] There is not the place to spawn your cube!");
					return;
				}
	
				decl Float:Posfinal[3];
				Posfinal[0] = 50.0 * Cosine((Ang[0]) * FLOAT_PI / 180) * Cosine((Ang[1]) * FLOAT_PI / 180) ;
				Posfinal[1] = 50.0 * Cosine((Ang[0]) * FLOAT_PI / 180) * Sine((Ang[1]) * FLOAT_PI / 180);
				Posfinal[2] = 50.0 * -Sine((Ang[0]) * FLOAT_PI / 180);
				Posfinal[0] += Pos [0];
				Posfinal[1] += Pos [1];
				Posfinal[2] += Pos [2];
					
				TeleportEntity(EntRefToEntIndex(ClientCube[client]), Posfinal, NULL_VECTOR, NULL_VECTOR);
			}
			else
			{
				RemovePortalCube(client);
			}
		}
		else
		{
			SpawnPortalCube(client, args);
		}
	}
}

SpawnPortalCube(client, SkinChoice)
{	
	if(!IsValidClient(client)) return;

	new ClientTeam =  GetClientTeam(client) -2;
	if(ClientTeam > 1 || ClientTeam < 0)
	{
		PrintToChat(client, "[PM_Cube] Go in BLU or RED team to use this command!");
		return;
	}
	
	decl Float:Pos[3];
	decl Float:Ang[3];
	GetClientEyePosition(client, Pos);
	GetEntPropVector(client, Prop_Data, "m_angRotation", Ang);
	
	new Handle:trace = INVALID_HANDLE;
	decl Float:EndPos[3];
	
	trace = TR_TraceRayFilterEx(Pos, Ang, MASK_SOLID, RayType_Infinite, TraceEntityFilterEntities, client);		
	if (!TR_DidHit(trace)) 
	{
		CloseHandle(trace);
		return;
	}
	
	TR_GetEndPosition(EndPos, trace);
	CloseHandle(trace);
	
	if(GetVectorDistance(EndPos, Pos, false) < 90.0)
	{
		PrintToChat(client, "[PM_Cube] There is not the place to spawn your cube!");
		OpenPortalCubeMenu(client, 0);
		return;
	}
	
	decl Float:Posfinal[3];
	Posfinal[0] = 50.0 * Cosine((Ang[0]) * FLOAT_PI / 180) * Cosine((Ang[1]) * FLOAT_PI / 180) ;
	Posfinal[1] = 50.0 * Cosine((Ang[0]) * FLOAT_PI / 180) * Sine((Ang[1]) * FLOAT_PI / 180);
	Posfinal[2] = 50.0 * -Sine((Ang[0]) * FLOAT_PI / 180);
	Posfinal[0] += Pos [0];
	Posfinal[1] += Pos [1];
	Posfinal[2] += Pos [2];
	
	
	new Ent = CreateEntityByName("prop_physics");        
	if (Ent == -1) 
	{ 
		LogMessage("Failed to create a Portal Cube.");
		PrintToChat(client, "[PM_Cube] There is something wrong, during the creation of your cube.");
		return;
	}
	
	DispatchKeyValue(Ent, "model", CUBE);
	SetEntProp(Ent, Prop_Send, "m_nSkin", SkinChoice);
	DispatchSpawn(Ent);
		
	TeleportEntity(Ent, Posfinal, NULL_VECTOR, NULL_VECTOR);
	ClientCube[client] = EntIndexToEntRef(Ent);
	PrintToChat(client, "[PM_Cube] This companion cube, is now your best friend!");
}

public bool:TraceEntityFilterEntities(entity, contentsMask, any:data) 
{
	return entity > MaxClients;
}

RemovePortalCube(client)
{
	if(EntRefToEntIndex(ClientCube[client]) != -1)
	{
		RemoveEdict(EntRefToEntIndex(ClientCube[client]));
		ClientCube[client] = -1;
		
		if(IsValidClient(client))
			PrintToChat(client, "[PM_Cube] Cube removed. (You are a monster)");
	}
}

stock bool:IsValidClient(iClient)
{
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	return IsClientInGame(iClient);
}