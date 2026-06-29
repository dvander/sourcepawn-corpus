#include <sourcemod>
#include <sdktools>
#include <dhooks>
#define PLUGIN_VERSION	"3.2.5"
#define BellsNumber 10

new Handle:hShootPosition;
new Handle:hFwd;
new Handle:JingleVolume;
new Handle:JinglePitch;
new String:BellsSound[BellsNumber][]=
{
	"player/sleigh_bells/tf_xmas_sleigh_bells_01.wav",
	"player/sleigh_bells/tf_xmas_sleigh_bells_02.wav",
	"player/sleigh_bells/tf_xmas_sleigh_bells_03.wav",
	"player/sleigh_bells/tf_xmas_sleigh_bells_04.wav",
	"player/sleigh_bells/tf_xmas_sleigh_bells_05.wav",
	"player/sleigh_bells/tf_xmas_sleigh_bells_06.wav",
	"player/sleigh_bells/tf_xmas_sleigh_bells_07.wav",
	"player/sleigh_bells/tf_xmas_sleigh_bells_08.wav",
	"player/sleigh_bells/tf_xmas_sleigh_bells_09.wav",
	"player/sleigh_bells/tf_xmas_sleigh_bells_10.wav"
}

public Plugin:myinfo = 
{
	name = "Jingle Bell Festives",
	author = "Matt_ (MattTheSpy)",
	description = "Jingle bells, jingle bells, jingle all the way",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/profiles/76561198060352651"
}

public OnPluginStart()
{
	CreateConVar("jinglebells_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY);
	JingleVolume = CreateConVar("jinglebells_volume", "1.0", "Jingle Bells volume, from 1.0 to 0.0", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	JinglePitch = CreateConVar("jinglebells_pitch", "100.0", "Jingle Bells pitch, from 125.0 to 85.0", FCVAR_PLUGIN, true, 85.0, true, 125.0)
	PrecacheTheJingling()
	HookEvent("player_chargedeployed", ChargeDeployed);
	HookEvent("deploy_buff_banner", BannerDeployed); 
	new Handle:temp = LoadGameConfigFile("jinglebells.tf");
	new offset = GameConfGetOffset(temp, "CBasePlayer::Weapon_ShootPosition()");
	if(temp == INVALID_HANDLE) 
	{
		SetFailState("Gamedata not found");
	}
	hShootPosition = DHookCreate(offset, HookType_Entity, ReturnType_Vector, ThisPointer_CBaseEntity, Weapon_ShootPosition);
	CloseHandle(temp);
	hFwd = CreateGlobalForward("OnClientWeaponShootPosition", ET_Ignore, Param_Cell, Param_Array);
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)) 
		{
			HookPlayer(i);
		}
	}
}

public OnMapStart()
{
	PrecacheTheJingling()
}

public OnClientPutInServer(client) 
{
	HookPlayer(client);
}

HookPlayer(client) 
{
    DHookEntity(hShootPosition, true, client, RemovalCB);
}

public MRESReturn:Weapon_ShootPosition(this, Handle:hReturn) 
{
	new Float:fShootPos[3];
	DHookGetReturnVector(hReturn, fShootPos);

	Call_StartForward(hFwd);
	Call_PushCell(this);
	Call_PushArray(fShootPos, 3);
	Call_Finish();

	return MRES_Ignored;
}

public RemovalCB(hookid) {}

public OnClientWeaponShootPosition(client, Float:position[3])
{
new MyWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
switch (GetEntProp(MyWeapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		case 654,658,660,661,662,669,999,1000,1003,1004,1005,1006,1007,1078,1079,1081,1082,1083,1084,1085:
		{
			EmitSoundClient(BellsSound[GetRandomInt(0,BellsNumber-1)], client);
		}
		default:
		{
		}
	}
}
public Action:ChargeDeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new MyWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	switch (GetEntProp(MyWeapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		case 663:
		{
			CreateTimer(0.45, DoJingles, client, TIMER_REPEAT);
		}
		default:
		{
		}
	}
	return Plugin_Handled;
}

public Action:BannerDeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "buff_owner"));
	new MyWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	switch (GetEntProp(MyWeapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		case 1001:
		{
			CreateTimer(0.45, DoJingles, client, TIMER_REPEAT);
		}
		default:
		{
		}
	}
	return Plugin_Handled;
} 

stock EmitSoundClient(String:sound[], client)
{
	new Float:JingleSoundVolume = GetConVarFloat(JingleVolume)
	new JingleSoundPitch = GetConVarInt(JinglePitch)
	decl Float:clientvecposition[3];	
	GetClientAbsOrigin(client, clientvecposition);	
	EmitAmbientSound(sound, clientvecposition, client, _, _, JingleSoundVolume, JingleSoundPitch, _)
}

stock IsValidClient(client)
{
	if (client == 0)
	{
		return false;
	}
	if (!IsClientConnected(client))
	{
		return false;
	}
	if (!IsClientInGame(client))
	{
		return false;
	}
	if (!IsPlayerAlive(client))
	{
		return false;
	}
	return true;
}

PrecacheTheJingling()
{
	PrecacheSound("player/sleigh_bells/tf_xmas_sleigh_bells_01.wav", true);
	PrecacheSound("player/sleigh_bells/tf_xmas_sleigh_bells_02.wav", true);
	PrecacheSound("player/sleigh_bells/tf_xmas_sleigh_bells_03.wav", true);
	PrecacheSound("player/sleigh_bells/tf_xmas_sleigh_bells_04.wav", true);
	PrecacheSound("player/sleigh_bells/tf_xmas_sleigh_bells_05.wav", true);
	PrecacheSound("player/sleigh_bells/tf_xmas_sleigh_bells_06.wav", true);
	PrecacheSound("player/sleigh_bells/tf_xmas_sleigh_bells_07.wav", true);
	PrecacheSound("player/sleigh_bells/tf_xmas_sleigh_bells_08.wav", true);
	PrecacheSound("player/sleigh_bells/tf_xmas_sleigh_bells_09.wav", true);
	PrecacheSound("player/sleigh_bells/tf_xmas_sleigh_bells_10.wav", true);
}

public Action:DoJingles(Handle:timer, any:client)
{
	static TimesJingled = 0;
//	May make a cvar to change the amount of times it jingles after activating...
	if (TimesJingled >= 16)
	{
		TimesJingled = 0;
		return Plugin_Stop;
	}
 	EmitSoundClient(BellsSound[GetRandomInt(0,BellsNumber-1)], client);
	TimesJingled++;
 
	return Plugin_Continue;
}

//---------------------------------------------
//	Sticking these here so I don't forget
//
//	659 = Festive Flamethrower
//	664 = Festive Sniper Rifle
//	665 = Festive Knife
//	1002 = Festive Sandvich
//	1086 = Festive Wrangler
//	1080 = Festive Sapper
//---------------------------------------------