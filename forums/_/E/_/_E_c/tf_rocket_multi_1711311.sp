#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define VERSION "1.11"

public Plugin:myinfo = {
	name = "Multiple Rocket",
	author = "[E]c",
	description = "Allows soldier to shoot multiple projectile.",
	version = VERSION,
	url = ""
};

new Handle:cvarRandom;
new Handle:cvarEnable;
new Handle:cvarDamageMul;
new Handle:cvarAdminOnly;
new Handle:cvarAmount;

new bool:isenable[MAXPLAYERS+1];

new Handle:cvarAdminFlag;

new AdminFlag:cflag;


public OnPluginStart()
{	
	LoadTranslations("common.phrases");


	CreateConVar("sm_multirocket_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_multirocket_toggle", CMD_Toggle, ADMFLAG_SLAY, "Toggle on targeted user");

	cvarAdminOnly = CreateConVar("sm_multirocket_admin_only", "1", "Only admin can have additional rocket", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarAmount = CreateConVar("sm_multirocket_amount", "3", "Amount of additional rocket", FCVAR_NONE, true, 0.0, false);
	cvarDamageMul = CreateConVar("sm_multirocket_damage_mul", "0.3", "Damage multiplier for additional rocket", FCVAR_NONE, true, 0.0, false);
	cvarEnable = CreateConVar("sm_multirocket_enable", "1", "Turn on/off multiple rocket", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarRandom = CreateConVar("sm_multirocket_random", "7.0", "", FCVAR_NONE, true, 0.0, false);

	cvarAdminFlag = CreateConVar("sm_multirocket_admin_flag", "f", "Access required to be recognized as admin", FCVAR_NONE, true, 0.0, false);

	HookConVarChange(cvarAdminOnly, OnAdminOnlyChange);
	
	new String:flagcvar[1];
	GetConVarString(cvarAdminFlag, flagcvar, sizeof(flagcvar));
	FindFlagByChar(flagcvar[0], cflag);

}

public OnClientPostAdminCheck(client)
{
	if (GetConVarBool(cvarAdminOnly))
	{
		new AdminId:admin_id = GetUserAdmin(client);
		if (GetAdminFlag(admin_id, cflag, AdmAccessMode:Access_Effective) && admin_id != INVALID_ADMIN_ID)
		{
			isenable[client] = true;
		}
		else
		{
			isenable[client] = false;
		}
	}
	else
	{
		isenable[client] = true;
	}
}

public OnAdminOnlyChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal) == 1)
	{
		for (new i = 1; i < MAXPLAYERS+1; i++)
		{
			if (IsClientInGame(i))
			{
				new AdminId:admin_id = GetUserAdmin(i);
				if (GetAdminFlag(admin_id, cflag, AdmAccessMode:Access_Effective) && admin_id != INVALID_ADMIN_ID)
				{
					isenable[i] = true;
				}
				else
				{
					isenable[i] = false;
				}
			}
		}
	}
	else
	{
		for (new i = 1; i < MAXPLAYERS+1; i++)
		{
			if (IsClientInGame(i))
			{
				isenable[i] = true;
			}
		}
	}
}
		

public Action:CMD_Toggle(client, args)
{
	if (args < 1)
	{
		PrintToConsole(client, "Usage: sm_multirocket_toggle <name>");
		return Plugin_Handled;
	}
	new String:target[50];
	GetCmdArg(1, target, sizeof(target));
	new targetid = FindTarget(client, target, false, false);
	if (isenable[targetid] == true) 
	{
		isenable[targetid] = false;
	}
	else 
	{
		isenable[targetid] = true;
	}
	// PrintToChatAll
	return Plugin_Handled;
}



public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (GetConVarBool(cvarEnable))
	{
		if (isenable[client])
		{
			if (StrEqual(weaponname, "tf_weapon_rocketlauncher", false) == true)
			{
				
				new Float:vAngles[3]; // pass
				new Float:vAngles2[3]; // original
				new Float:vPosition[3]; // pass
				new Float:vPosition2[3]; // original
				new Amount = GetConVarInt(cvarAmount);
				new ClientTeam = GetClientTeam(client);
				new Float:Random = GetConVarFloat(cvarRandom);
				new Float:DamageMul = GetConVarFloat(cvarDamageMul);
	
				GetClientEyeAngles(client, vAngles2);
				GetClientEyePosition(client, vPosition2);
				
				vPosition[0] = vPosition2[0];
				vPosition[1] = vPosition2[1];
				vPosition[2] = vPosition2[2];

				new Float:Random2 = Random*-1;
				new counter = 0;
				for (new i = 0; i < Amount; i++)
				{
					vAngles[0] = vAngles2[0] + GetRandomFloat(Random2,Random);
					vAngles[1] = vAngles2[1] + GetRandomFloat(Random2,Random);
					// avoid unwanted collision
					new i2 = i%4;
					switch(i2)
					{
						case 0:
						{
							counter++;
							vPosition[0] = vPosition2[0] + counter;
						}
						case 1:
						{	
							vPosition[1] = vPosition2[1] + counter;
						}
						case 2:
						{
							vPosition[0] = vPosition2[0] - counter;
						}
						case 3:
						{
							vPosition[1] = vPosition2[1] - counter;
						}
					}
					fireProjectile(vPosition, vAngles, 1100.0, 90.0*DamageMul, ClientTeam, client);
				}
			}
		}
	}
	return Plugin_Continue;
}



fireProjectile(Float:vPosition[3], Float:vAngles[3] = NULL_VECTOR, Float:flSpeed = 1100.0, Float:flDamage = 90.0, iTeam, client)
{
	new String:strClassname[32] = "";
	new String:strEntname[32] = "";

	strClassname = "CTFProjectile_Rocket";
	strEntname = "tf_projectile_rocket";

	new iRocket = CreateEntityByName(strEntname);
	
	if(!IsValidEntity(iRocket))
		return -1;
	
	decl Float:vVelocity[3];
	decl Float:vBuffer[3];
	
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	
	vVelocity[0] = vBuffer[0]*flSpeed;
	vVelocity[1] = vBuffer[1]*flSpeed;
	vVelocity[2] = vBuffer[2]*flSpeed;
	
	SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iRocket,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iRocket,    Prop_Send, "m_iTeamNum",     iTeam, 1);
	SetEntData(iRocket, FindSendPropOffs(strClassname, "m_nSkin"), (iTeam-2), 1, true);

	SetEntDataFloat(iRocket, FindSendPropOffs(strClassname, "m_iDeflected") + 4, flDamage, true); // set damage
	TeleportEntity(iRocket, vPosition, vAngles, vVelocity);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iRocket);
	
	return iRocket;
}