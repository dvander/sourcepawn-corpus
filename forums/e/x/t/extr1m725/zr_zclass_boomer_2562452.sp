#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>
#include <zr_tools>
#include <emitsoundany>

public Plugin myinfo =
{
	name        	= "[ZR] Zombie Class: Boomer",
	author      	= "Extr1m (Michail)",
	description 	= "Add zombie class",
	version     	= "1.0",
	url         	= "https://sourcemod.net/"
}

#define VMT_CODE "r_screenoverlay \"{MODEL}\""

// Cvars
ConVar gCV_PEnabled = null;
ConVar gCV_PVomitDistance = null;
ConVar gCV_PVomitRadius = null;
ConVar gCV_PResetOverlay = null;
ConVar gCV_PResetVomit = null;
ConVar gCV_PSound_mp3 = null;
ConVar gCV_PVomit_VMT = null;
ConVar gCV_PSound_VTF = null;

// Cached cvars
bool 	gB_PEnabled = true;
float 	gF_PVomitDistance;
float 	gF_PVomitRadius;
float 	gF_PResetOverlay;
float 	gF_PResetVomit;

new bool:g_VomitClassEnable[MAXPLAYERS + 1]

new Handle:VomitClients,
EmitDecals[MAXPLAYERS+1],
bool:ZVomitActive[MAXPLAYERS+1],
bool:ZVomitPlayer[MAXPLAYERS+1],
bool:induck[MAXPLAYERS+1];

char SoundMP3[PLATFORM_MAX_PATH];
char VomitVMT[PLATFORM_MAX_PATH];
char VomitVTF[PLATFORM_MAX_PATH];

char sVMT[PLATFORM_MAX_PATH];
char sVMT_Old[PLATFORM_MAX_PATH];
char sClientVMT[PLATFORM_MAX_PATH] = VMT_CODE;

public void OnPluginStart()
{
	gCV_PEnabled 			= 	CreateConVar("sm_boomer_enabled", "1", "Responsible for the operation of the class on the server", 0, true, 0.0, true, 1.0);
	gCV_PVomitDistance		= 	CreateConVar("sm_boomer_distance", "280.0", "The distance at which the ability", 0, true, 0.0, true, 1000.0);
	gCV_PVomitRadius		= 	CreateConVar("sm_boomer_radius", "80.0", "The radius on which the ability", 0, true, 0.0, true, 360.0);
	gCV_PResetOverlay		= 	CreateConVar("sm_boomer_resetovelay", "15.0", "Time through which the player's overlay will be removed", 0, true, 0.0, true, 60.0);
	gCV_PResetVomit			= 	CreateConVar("sm_boomer_resetvomit", "15.0", "Cooldown ability", 0, true, 0.0, true, 60.0);
	gCV_PSound_mp3			= 	CreateConVar("sm_boomer_sound", "zr/bv1.mp3", "Way to the sound");
	gCV_PVomit_VMT			= 	CreateConVar("sm_boomer_vomit_vmt", "materials/overlays/zrblyvota.vtf", "Way to the VMT");
	gCV_PSound_VTF			= 	CreateConVar("sm_boomer_vomit_vtf", "materials/overlays/zrblyvota.vmt", "Way to the VTF");
	
	gCV_PEnabled.AddChangeHook(ConVarChange);
	gCV_PVomitDistance.AddChangeHook(ConVarChange);
	gCV_PVomitRadius.AddChangeHook(ConVarChange);
	gCV_PResetOverlay.AddChangeHook(ConVarChange);
	gCV_PResetVomit.AddChangeHook(ConVarChange);
	gCV_PSound_mp3.AddChangeHook(ConVarChange);
	gCV_PVomit_VMT.AddChangeHook(ConVarChange);
	gCV_PSound_VTF.AddChangeHook(ConVarChange);
	
	gB_PEnabled = gCV_PEnabled.BoolValue;
	gF_PVomitDistance = gCV_PVomitDistance.FloatValue;
	gF_PVomitRadius = gCV_PVomitRadius.FloatValue;
	gF_PResetOverlay = gCV_PResetOverlay.FloatValue;
	gF_PResetVomit = gCV_PResetVomit.FloatValue;
	
	AutoExecConfig(true, "zr_class_boomer", "zombiereloaded");
	
	gCV_PSound_mp3.GetString(SoundMP3, sizeof(SoundMP3));
	gCV_PVomit_VMT.GetString(VomitVMT, sizeof(VomitVMT));
	gCV_PSound_VTF.GetString(VomitVTF, sizeof(VomitVTF));
	
	if(VomitClients != INVALID_HANDLE)
		VomitClients = INVALID_HANDLE

	VomitClients = CreateArray();
}

public void ConVarChange(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	gB_PEnabled = gCV_PEnabled.BoolValue;
	gF_PVomitDistance = gCV_PVomitDistance.FloatValue;
	gF_PVomitRadius = gCV_PVomitRadius.FloatValue;
	gF_PResetOverlay = gCV_PResetOverlay.FloatValue;
	gF_PResetVomit = gCV_PResetVomit.FloatValue;

	gCV_PSound_mp3.GetString(SoundMP3, sizeof(SoundMP3));
	gCV_PVomit_VMT.GetString(VomitVMT, sizeof(VomitVMT));
	gCV_PSound_VTF.GetString(VomitVTF, sizeof(VomitVTF));
	
	decl String:buffer[PLATFORM_MAX_PATH]; 
	Format(buffer, sizeof(buffer), "sound/%s", SoundMP3);

	AddFileToDownloadsTable(buffer);
	AddFileToDownloadsTable(VomitVMT);
	AddFileToDownloadsTable(VomitVTF);

	PrecacheSoundAny(SoundMP3); 
	PrecacheGeneric(VomitVMT, true);
	PrecacheGeneric(VomitVTF, true);
}

 public OnMapStart()
{
	decl String:buffer[PLATFORM_MAX_PATH]; 
	Format(buffer, sizeof(buffer), "sound/%s", SoundMP3);

	AddFileToDownloadsTable(buffer);
	AddFileToDownloadsTable(VomitVMT);
	AddFileToDownloadsTable(VomitVTF);

	PrecacheSoundAny(SoundMP3); 
	PrecacheGeneric(VomitVMT, true);
	PrecacheGeneric(VomitVTF, true);
}
 
 public OnClientPutInServer(client) 
{
	ZVomitActive[client] = false;
	ZVomitPlayer[client] = false;
	EmitDecals[client] = 0;
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	decl String:buffer[64];
	ZRT_GetClientAttributeString(client, "class_zombie", buffer, sizeof(buffer));
	
	if(StrEqual(buffer, "boomer", false))
		g_VomitClassEnable[client] = true;
	else
		g_VomitClassEnable[client] = false;
}

public OnGameFrame()
{
	if(GetArraySize(VomitClients) > 0)
	{
		for (new x = 0; x < GetArraySize(VomitClients); x++)
		{
			new client = GetArrayCell(VomitClients, x);
			if(IsValidClient(client))
			{
				if(IsPlayerAlive(client))
				{
					teleportemit(client);
				}
			}
		}
	}
}

stock teleportemit(client)
{
	if(EmitDecals[client] != 0)
	{
		new String:classname[256];
		if(IsValidEdict(EmitDecals[client]))
			GetEdictClassname(EmitDecals[client], classname, sizeof(classname));

		if (StrEqual(classname, "info_particle_system", false))
		{
			decl Float:Cposition[3], Float:Cangles[3], Float:endpos[3], Float:angles[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Cposition);
			GetEntPropVector(client, Prop_Send, "m_angRotation", Cangles);	

			if(induck[client] == false)
			{
				Cposition[2] += 63.3;
			}
			else
			{
				Cposition[2] += 45.3;
			}
			
			GetClientAbsAngles(client, angles);
			GetAngleVectors(angles, endpos, NULL_VECTOR, NULL_VECTOR); 			
			endpos[0] = Cposition[0] + endpos[0] * 14.5;
			endpos[1] = Cposition[1] + endpos[1] * 14.5;
			endpos[2] = Cposition[2] + endpos[2] * 14.5;		
			TeleportEntity(EmitDecals[client], endpos, Cangles, NULL_VECTOR);
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapontochange)
{
	if(gB_PEnabled && IsValidClient(client) && IsPlayerAlive(client))
	{		
		if(ZR_IsClientZombie(client) && g_VomitClassEnable[client])
		{
			if(ZVomitActive[client] == false && IsPlayerAlive(client) && buttons & IN_RELOAD)
			{
				ZVomitActive[client] = true;
				PushArrayCell(VomitClients, client);
				EmitDecals[client] = VomitEmit(client);

				decl Float:start[3]; 
				GetClientEyePosition(client, start);

				float fOriginClient[3];
				GetClientAbsOrigin( client, fOriginClient );
				
				EmitAmbientSoundAny(SoundMP3, fOriginClient);
				ZVomitPlayer[client] = true;
				CreateTimer(18.0, resetvomit, client);
			}
			else if(ZVomitActive[client] == true && IsPlayerAlive(client) && ZVomitPlayer[client] == true)
			{
				if(buttons & IN_DUCK)
				{
					induck[client] = true;
				}
				else
				{
					induck[client] = false;
				}
				decl Float:endpos[3], Float:angless[3];
				GetClientEyePosition(client, endpos); 
				GetClientEyeAngles(client, angless);
				TR_TraceRayFilter(endpos, angless, MASK_SOLID, RayType_Infinite, RayDontHitSelf, client);
				if(TR_DidHit(INVALID_HANDLE)) 
				{
					decl Float:end[3];
					TR_GetEndPosition(end, INVALID_HANDLE);
					new Float:vecdis = GetVectorDistance(endpos, end, false);
					if(vecdis <= gF_PVomitDistance)
					{
						VomitPlayerScreen(end);
						ZVomitPlayer[client] = false;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

VomitPlayerScreen(Float:Coord[3])
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if(IsValidClient(i) && ZVomitPlayer[i] == false)
		{
			if(IsPlayerAlive(i))
			{
				decl Float:Pos[3];
				GetClientAbsOrigin(i, Pos);
				if(GetVectorDistance(Coord,Pos) <= gF_PVomitRadius)
				{
					if(ZR_IsClientHuman(i))
					{						
						Format(sVMT_Old, sizeof(sVMT_Old), "%s", VomitVMT);
						ReplaceString(sVMT_Old, sizeof(sVMT_Old), "materials/", "");
						
						Format(sVMT, sizeof(sVMT), "%s", VomitVMT);
						ReplaceString(sClientVMT, sizeof(sClientVMT), "{MODEL}", sVMT_Old);
						
						ClientCommand(i, sClientVMT);
						PrintHintText(i, "На вас блеванул зомби")
						ZVomitPlayer[i] = true;
						CreateTimer(gF_PResetOverlay, ResetScreen, i);
					}
				}
			}
		} 
	} 
}

public Action:ResetScreen(Handle:Timer, any:data)
{
	if(IsValidClient(data))
	{
		ClientCommand(data, "r_screenoverlay \"\"");
		ZVomitPlayer[data] = false;
	}
}

public bool:RayDontHitSelf(entity, contentsMask, any:data) 
{ 
	return (entity!=data);
}

stock VomitEmit(client)
{
	new particle = CreateEntityByName("info_particle_system");
	if(IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", "chicken_gone_crumble_halloween");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		CreateTimer(10.0, delparticle, particle);
		CreateTimer(gF_PResetVomit, deleffect, client);
	}
	
	return particle;
}

public Action:resetvomit(Handle:Timer, any:client)
{
	ZVomitActive[client] = false;
	ZVomitPlayer[client] = false;
}

public Action:deleffect(Handle:Timer, any:client)
{
	EmitDecals[client] = 0;
	ZVomitPlayer[client] = false;
	for (new x = 0; x < GetArraySize(VomitClients); x++)
    {
		if(GetArrayCell(VomitClients, x) == client)
		{
			RemoveFromArray(VomitClients, x);
		}
	}
}

public Action:delparticle(Handle:Timer, any:particle)
{
	if(IsValidEntity(particle))
	{
		new String:classname[256];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}
}

bool:IsValidClient(client)
{
	if(!(1<= client<=MaxClients) || !IsClientInGame(client) || client == 0)
	{ 
		return false; 
	}
	return true; 
}