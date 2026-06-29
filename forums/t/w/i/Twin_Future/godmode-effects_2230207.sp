#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define SOUND_GODMODE		"vo/scout_invincible01.wav"
#define COLOR_BLACK			{200,200,200,192}
#define COLOR_NORMAL		{255,255,255,255}
new g_Ent[MAXPLAYERS+1]
new Handle:g_hCvarBuddah;
new bool:g_GodMode[MAXPLAYERS+1] = false;
new g_Ent1[MAXPLAYERS+1]
new g_Ent2[MAXPLAYERS+1]

enum g_ePlayerInfo
{
	g_iPlayerColor[4],
	Handle:g_hPlayerEntities
};
new g_nPlayerData[MAXPLAYERS+1][g_ePlayerInfo];
new g_iOffsetDecaps;

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Godmode with Effects!",
	author = "Twin_Future",
	description = "Godmode with particle effects on user, makes you Invulnerable to bullets, falling, and map traps.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_efx_godmode_version", PLUGIN_VERSION, "Plugin Version",  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_godmode", God_Mode, ADMFLAG_KICK, "sm_godmode <#userid|name> - Invulnerability to bullets, falling, and map traps.");
	g_hCvarBuddah = CreateConVar("sm_godmode_buddah", "1", "Set to 1 to make godmode give you buddah (takes dmg blast). Set to 0 to give you normal godmode.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	LookupOffset(g_iOffsetDecaps, "CTFPlayer", "m_iDecapitations");
}
public OnMapStart()
{
	ClearPlayerData();
	PrecacheSound(SOUND_GODMODE);
}
public Action:God_Mode(client, args)
{	
	//validate args
	if (args < 1)
	{
		new String:cname[MAX_NAME_LENGTH];
		GetClientName(client, cname, sizeof(cname));
		
		if(g_GodMode[client])
		{
			SetGodmode(client, false);
			ColorizePlayer(client, COLOR_NORMAL);
			DeleteParticle(g_Ent1[client]);
			DeleteParticle(g_Ent2[client]);
			DeleteParticle(g_Ent[client]);
			DeleteParticle(g_Ent[client]);
			DeleteParticle(g_Ent[client]);
			DeleteParticle(g_Ent[client]);
			DeleteParticle(g_Ent[client]);
			DeleteParticle(g_Ent[client]);
			DeleteParticle(g_Ent[client]);
			DeleteParticle(g_Ent[client]);
			DeleteParticle(g_Ent[client]);
			g_GodMode[client] = false;
			ShowActivity2(client, "[SM] ", "%s Has Disabled Godmode", cname);
			return Plugin_Handled;
		}
		else
		{
			SetGodmode(client, true);
			EmitSoundToAll(SOUND_GODMODE, client);
			ColorizePlayer(client, COLOR_BLACK);
			AddEntityToClient(client, AttachParticle1(client, "utaunt_beams_sparks_yellow", _, 0.0));
			AddEntityToClient(client, AttachParticle2(client, "eyeboss_doorway_vortex", _, 30.0));
			AddEntityToClient(client, AttachParticle(client, "drg_cow_explosioncore_normal", _, 30.0));
			AddEntityToClient(client, AttachParticle(client, "drg_cow_explosioncore_charged", _, 30.0));
			AddEntityToClient(client, AttachParticle(client, "god_rays_fog", _, 30.0));
			AddEntityToClient(client, AttachParticle(client, "god_rays", _, 30.0));
			AddEntityToClient(client, AttachParticle(client, "skull_island_explosion", _, 30.0));
			AddEntityToClient(client, AttachParticle(client, "Explosion_ShockWave_01", _, 30.0));
			AddEntityToClient(client, AttachParticle(client, "mvm_loot_explosion", _, 30.0));
			AddEntityToClient(client, AttachParticle(client, "bl_killtaunt_explosion_ring", _, 30.0));
			AddEntityToClient(client, AttachParticle(client, "burningplayer_rainbow_stars04", _, 10.0));
			g_GodMode[client] = true;
			ShowActivity2(client, "[SM] ", "%s Has Enabled Godmode", cname);
			return Plugin_Handled;
		}
	}
	else if (args == 1)
	{
		decl String:target[32];
		decl String:target_name[MAX_NAME_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		
		//get argument
		GetCmdArg(1, target, sizeof(target));		
		
		//get target(s)
		if ((target_count = ProcessTargetString(
				target,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (new i = 0; i < target_count; i++)
		{
			if(g_GodMode[target_list[i]])
			{
				SetGodmode(target_list[i], false);
				ColorizePlayer(target_list[i], COLOR_NORMAL);
				DeleteParticle(g_Ent1[target_list[i]]);
				DeleteParticle(g_Ent2[target_list[i]]);
				DeleteParticle(g_Ent[target_list[i]]);
				DeleteParticle(g_Ent[target_list[i]]);
				DeleteParticle(g_Ent[target_list[i]]);
				DeleteParticle(g_Ent[target_list[i]]);
				DeleteParticle(g_Ent[target_list[i]]);
				DeleteParticle(g_Ent[target_list[i]]);
				DeleteParticle(g_Ent[target_list[i]]);
				DeleteParticle(g_Ent[target_list[i]]);
				DeleteParticle(g_Ent[target_list[i]]);
				g_GodMode[target_list[i]] = false;
				ShowActivity2(target_list[i], "[SM] ", "%s Has Disabled Godmode", target_name);
				return Plugin_Handled;
			}
			else
			{
				SetGodmode(target_list[i], true);
				EmitSoundToClient(target_list[i], SOUND_GODMODE);
				ColorizePlayer(target_list[i], COLOR_BLACK);
				AddEntityToClient(target_list[i], AttachParticle1(target_list[i], "utaunt_beams_sparks_yellow", _, 0.0));
				AddEntityToClient(target_list[i], AttachParticle2(target_list[i], "eyeboss_doorway_vortex", _, 30.0));
				AddEntityToClient(target_list[i], AttachParticle(target_list[i], "drg_cow_explosioncore_normal", _, 30.0));
				AddEntityToClient(target_list[i], AttachParticle(target_list[i], "drg_cow_explosioncore_charged", _, 30.0));
				AddEntityToClient(target_list[i], AttachParticle(target_list[i], "god_rays_fog", _, 30.0));
				AddEntityToClient(target_list[i], AttachParticle(target_list[i], "god_rays", _, 30.0));
				AddEntityToClient(target_list[i], AttachParticle(target_list[i], "skull_island_explosion", _, 30.0));
				AddEntityToClient(target_list[i], AttachParticle(target_list[i], "Explosion_ShockWave_01", _, 30.0));
				AddEntityToClient(target_list[i], AttachParticle(target_list[i], "mvm_loot_explosion", _, 30.0));
				AddEntityToClient(target_list[i], AttachParticle(target_list[i], "bl_killtaunt_explosion_ring", _, 30.0));
				AddEntityToClient(target_list[i], AttachParticle(target_list[i], "burningplayer_rainbow_stars04", _, 10.0));
				g_GodMode[target_list[i]] = true;
				ShowActivity2(target_list[i], "[SM] ", "%s Has Enabled Godmode", target_name);
				return Plugin_Handled;
			}
		}
	}	
	return Plugin_Handled;
}

stock SetGodmode(client, bool:bEnabled)
{
	new iGodmode = GetConVarInt(g_hCvarBuddah) ? 1 : 0;
	return SetEntProp(client, Prop_Data, "m_takedamage", bEnabled ? iGodmode : 2, 1);
}

stock ColorizePlayer(client, iColor[4])
{
	g_nPlayerData[client][g_iPlayerColor] = iColor;
	
	SetEntityColor(client, iColor);
	
	for(new i=0; i<3; i++)
	{
		new iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon > MaxClients && IsValidEntity(iWeapon))
		{
			SetEntityColor(iWeapon, iColor);
		}
	}
	
	decl String:strClass[20];
	for(new i=MaxClients+1; i<GetMaxEntities(); i++)
	{
		if(IsValidEntity(i))
		{
			GetEdictClassname(i, strClass, sizeof(strClass));
			if((strncmp(strClass, "tf_wearable", 11) == 0 || strncmp(strClass, "tf_powerup", 10) == 0) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityColor(i, iColor);
			}
		}
	}

	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
	if(iWeapon > MaxClients && IsValidEntity(iWeapon))
	{
		SetEntityColor(iWeapon, iColor);
	}
	
	// Player is recognized as invisible
	if(iColor[3] == 0)
	{
		if(GetDecaps(client) > 0 && TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
		{
			TF2_RemoveCondition(client, TFCond_DemoBuff);
		}
	}else{
		if(GetDecaps(client) > 0 && !TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
		{
			TF2_AddCondition(client, TFCond_DemoBuff, 1000.0);
		}
	}
}
stock SetEntityColor(iEntity, iColor[4])
{
	SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iEntity, iColor[0], iColor[1], iColor[2], iColor[3]);
}
GetDecaps(client)
{
	return GetEntData(client, g_iOffsetDecaps);
}
LookupOffset(&iOffset, const String:strClass[], const String:strProp[])
{
	iOffset = FindSendPropInfo(strClass, strProp);
	if(iOffset <= 0)
	{
		SetFailState("Could not locate offset for %s::%s!", strClass, strProp);
	}
}
AddEntityToClient(client, iEntity)
{
	if(iEntity > MaxClients)
	{
		if(g_nPlayerData[client][g_hPlayerEntities] == INVALID_HANDLE)
		{
			g_nPlayerData[client][g_hPlayerEntities] = CreateArray();
		}
		
		PushArrayCell(g_nPlayerData[client][g_hPlayerEntities], EntIndexToEntRef(iEntity));
	}
}
AttachParticle(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flOffsetZ=0.0)
{
	new iParticle = CreateEntityByName("info_particle_system");
	if(iParticle > MaxClients && IsValidEntity(iParticle))
	{
		new Float:flPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] += flOffsetZ;
		
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect);
		DispatchSpawn(iParticle);
		
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", iEntity);
		ActivateEntity(iParticle);
		
		if(strlen(strAttachPoint))
		{
			SetVariantString(strAttachPoint);
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset");
		}
		
		AcceptEntityInput(iParticle, "start");
		g_Ent[iEntity] = iParticle;
		return iParticle;
	}
	
	return 0;
}
AttachParticle1(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flOffsetZ=0.0)
{
	new iParticle = CreateEntityByName("info_particle_system");
	if(iParticle > MaxClients && IsValidEntity(iParticle))
	{
		new Float:flPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] += flOffsetZ;
		
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect);
		DispatchSpawn(iParticle);
		
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", iEntity);
		ActivateEntity(iParticle);
		
		if(strlen(strAttachPoint))
		{
			SetVariantString(strAttachPoint);
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset");
		}
		
		AcceptEntityInput(iParticle, "start");
		g_Ent1[iEntity] = iParticle;
		return iParticle;
	}
	
	return 0;
}
AttachParticle2(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flOffsetZ=0.0)
{
	new iParticle = CreateEntityByName("info_particle_system");
	if(iParticle > MaxClients && IsValidEntity(iParticle))
	{
		new Float:flPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] += flOffsetZ;
		
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect);
		DispatchSpawn(iParticle);
		
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", iEntity);
		ActivateEntity(iParticle);
		
		if(strlen(strAttachPoint))
		{
			SetVariantString(strAttachPoint);
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset");
		}
		
		AcceptEntityInput(iParticle, "start");
		g_Ent2[iEntity] = iParticle;
		return iParticle;
	}
	
	return 0;
}
DeleteParticle(any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[256]
        GetEdictClassname(particle, classname, sizeof(classname))
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle)
        }
    }
}
ClearPlayerData(client=0)
{
	if(client != 0)
	{
		KillEntities(client);
		g_nPlayerData[client][g_iPlayerColor] = {0, 0, 0, 0};
	}
	else
	{
		for(new i=0; i<MAXPLAYERS+1; i++)
		{
			KillEntities(i);
			g_nPlayerData[i][g_iPlayerColor] = {0, 0, 0, 0};
		}
	}
}
KillEntities(client)
{
	new Handle:hArray = g_nPlayerData[client][g_hPlayerEntities];
	if(hArray != INVALID_HANDLE)
	{
		for(new i=0; i<GetArraySize(hArray); i++)
		{
			new iRef = GetArrayCell(hArray, i);
			if(iRef != 0)
			{
				new iEntity = EntRefToEntIndex(iRef);
				if(iEntity > MaxClients && IsValidEntity(iEntity))
				{
					AcceptEntityInput(iEntity, "Kill");
				}
			}
		}
		CloseHandle(hArray);
	}
	g_nPlayerData[client][g_hPlayerEntities] = INVALID_HANDLE;
}