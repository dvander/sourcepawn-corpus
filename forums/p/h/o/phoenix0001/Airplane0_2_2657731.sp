#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>

#define SOUND_PASS1			"animation/c130_flyby.wav"

#define MAXLIST 17

int gIndexCrate[2048+1];
ConVar cTankChance;

public Plugin myinfo =
{
	name = "[L4D2] Airdrop",
	author = "BHaType",
	description = "Admin can call airdrop.",
	version = "0.2",
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=BHaType&description=&search=1"
}


static const char gModeList[3][] =
{
    "models/props_vehicles/c130.mdl",
    "models/props_crates/supply_crate02.mdl",
    "models/props_crates/supply_crate02_gib1.mdl"
};

static const char gItemsList[MAXLIST][] =
{
	"weapon_pipe_bomb",
    "weapon_molotov",
    "weapon_vomijar",
	"weapon_first_aid_kit",
	"weapon_pain_pills",
    "weapon_defibrillator",
    "weapon_adrenaline",
	"weapon_fireworkcrate",
	"weapon_gascan",
    "weapon_oxygentank",
    "weapon_propanetank",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary",
    "weapon_gnome",
	"weapon_grenade_launcher",
	"weapon_sniper_awp",
	"weapon_pistol"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_a6c91", CallAirdrop, ADMFLAG_ROOT);
	//HookEvent("tank_spawn", EventTank);
	HookEvent("tank_killed", EventTank);
	
	cTankChance = CreateConVar("airdrop_tank_chance", "50", "空投获得补给物品几率", FCVAR_NONE);
}

public Action EventTank(Event event, const char[] name, bool dontbroadcast)
{
	if(GetRandomInt(0, 100) <= GetConVarInt(cTankChance))
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		AirPlane(client);
	}
}

public void OnMapStart()
{
	PrecacheSound(SOUND_PASS1, true);
	for (int i = 0; i < MAXLIST - 14; i++)
	{
		PrecacheModel(gModeList[i], true);
	}
}

public Action CallAirdrop(int client, int args)
{
	AirPlane(client);
	PrintToChatAll("\x05『空投』\x04%N \x03呼叫了空投AC130运输机", client);
}

stock void AirPlane(int client)
{
	float vPos[3], vAng[3], direction;
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vPos);
	vPos[2] += 64;
	GetEntPropVector(client, Prop_Send, "m_angRotation", vAng);
	direction = vAng[1];
			
	float vSkybox[3];
	vAng[0] = 0.0;
	vAng[1] = direction;
	vAng[2] = 0.0;
	
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vSkybox);

	int entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "targetname", "ac130");
	DispatchKeyValue(entity, "disableshadows", "1");
	DispatchKeyValue(entity, "model", gModeList[0]);
	DispatchSpawn(entity);
	float height = vPos[2] + 1150.0;
	if( height > vSkybox[2] - 200 )
		vPos[2] = vSkybox[2] - 200;
	else
		vPos[2] = height;

	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	EmitSoundToAll(SOUND_PASS1, entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
	SetVariantString("airport_intro_flyby");
	AcceptEntityInput(entity, "SetAnimation");
	AcceptEntityInput(entity, "Enable");

	SetVariantString("OnUser1 !self:Kill::20.20.0:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
	CreateTimer(7.0, TimerDropAirDrop, EntIndexToEntRef(entity));
}

public Action TimerDropAirDrop(Handle timer, any entity)
{
	entity = EntRefToEntIndex(entity);
	if(entity != INVALID_ENT_REFERENCE)
	{
		float vPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
		CreateCrates(vPos);
	}
}

void CreateCrates(float vPos[3])
{
	int entity = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(entity, "targetname", "SupplyDrop");
	DispatchKeyValueVector(entity, "origin", vPos);
	SetEntityModel(entity, gModeList[1]);
	DispatchSpawn(entity);
	
	int iTrigger = CreateEntityByName("func_button_timed");
	DispatchKeyValueVector(iTrigger, "origin", vPos);
	DispatchKeyValue(iTrigger, "use_string", "正在打开物资中……");//Open...
	DispatchKeyValue(iTrigger, "use_time", "3");
	DispatchKeyValue(iTrigger, "auto_disable", "1");
	DispatchSpawn(iTrigger);
	ActivateEntity(iTrigger);
	
	SetEntPropVector(iTrigger, Prop_Send, "m_vecMins", view_as<float>({-75.0, -75.0, -75.0}));
	SetEntPropVector(iTrigger, Prop_Send, "m_vecMaxs", view_as<float>({75.0, 75.0, 75.0}));
	HookSingleEntityOutput(iTrigger, "OnTimeUp", OnTimeUp);
	gIndexCrate[iTrigger] = EntIndexToEntRef(entity);
	SetEntityModel(iTrigger, gModeList[2]);
	SetEntityRenderMode(iTrigger, RENDER_NONE);
	SetVariantString("!activator");
	AcceptEntityInput(iTrigger, "SetParent", entity);
	char sColor[16];
	Format(sColor, sizeof sColor, "255 255 255");
	SetEntProp(entity, Prop_Send, "m_nGlowRange", 5000);//空投物品发光距离
	SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", GetColor(sColor));
	
	SetEntProp(iTrigger, Prop_Data, "m_takedamage", 0, 1);
	SetEntProp(entity, Prop_Data, "m_takedamage", 0, 1);
	//SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	PrintToChatAll("\x05『空投』\x04AC130运输机空投坐标 \x03%.2f %.2f %.2f", vPos[0], vPos[1], vPos[2]);
}

public void OnTimeUp(const char[] output, int caller, int activator, float delay)
{
	if (activator > 0 && IsClientInGame(activator))
	{
		int entity = gIndexCrate[caller];
		if((entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(caller, "kill");
			float vPos[3], vAng[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
			GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
			
			int OpenedCrate = CreateEntityByName("prop_physics_override");
			DispatchKeyValueVector(OpenedCrate, "origin", vPos);
			DispatchKeyValueVector(OpenedCrate, "angles", vAng);
			SetEntityModel(OpenedCrate, gModeList[2]);
			DispatchSpawn(OpenedCrate);
			
			AcceptEntityInput(entity, "kill");
			int SupplyItem = CreateEntityByName(gItemsList[GetRandomInt(0, 16)]);
			if(IsValidEntity(SupplyItem))
			{
				DispatchSpawn(SupplyItem);
				vPos[2] += 5.0;
				TeleportEntity(SupplyItem, vPos, vAng, NULL_VECTOR);
			}
			PrintToChatAll("\x05『空投』\x04%N \x03打开了空投物资", activator);
		}
	}
}
/*
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)  
{
	if(IsValidEntity(victim) && attacker > 0 && GetClientTeam(attacker) == 2)
	{
		char sModel[126];
		GetEntityClassname(victim, sModel, sizeof sModel);
		if(strcmp(sModel, gModeList[1]) == 0)
		{
			float vPos[3], vAng[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", vPos);
			GetEntPropVector(victim, Prop_Send, "m_angRotation", vAng);
			
			int OpenedCrate = CreateEntityByName("prop_physics_override");
			DispatchKeyValueVector(OpenedCrate, "origin", vPos);
			DispatchKeyValueVector(OpenedCrate, "angles", vAng);
			SetEntityModel(OpenedCrate, gModeList[2]);
			DispatchSpawn(OpenedCrate);
			AcceptEntityInput(victim, "kill");
			int SupplyItem = CreateEntityByName(gItemsList[GetRandomInt(0, 16)]);
			if(IsValidEntity(SupplyItem))
			{
				DispatchSpawn(SupplyItem);
				vPos[2] += 5.0;
				TeleportEntity(SupplyItem, vPos, vAng, NULL_VECTOR);
			}
			PrintToChatAll("\x05『空投』\x04%N \x03打破了空投物资", attacker);
		}
	}
}
*/
int GetColor(char[] sTemp)
{
	if( StrEqual(sTemp, "") )
		return 0;
 
	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, 3, 4);
 
	if( color != 3 )
		return 0;
 
	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);
 
	return color;
}