// code taken from kztimer

#include <sourcemod>
#include <sdktools>

new Float:g_fLastAngles[MAXPLAYERS + 1][3];
new Float:g_fVelocityModifierLastChange[MAXPLAYERS+1];

new Float:g_PrestrafeVelocity[MAXPLAYERS+1] = {1.0};

new g_PrestrafeFrameCounter[MAXPLAYERS+1];

bool g_bOnGround[MAXPLAYERS + 1];

public OnClientPutInServer(client)
{
	g_PrestrafeVelocity[client] = 1.0;
	g_PrestrafeFrameCounter[client] = 0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if (!IsValidClient(client, true))
		return Plugin_Continue;

	if(GetEntityFlags(client) & FL_ONGROUND)
	{
		g_bOnGround[client] = true;
	}

	else
	{
		g_bOnGround[client] = false;
	}

	float ang[3];
	GetClientEyeAngles(client, ang);

	Prestrafe(client, ang[1], buttons);

	g_fLastAngles[client] = ang;

	return Plugin_Continue;
}

public Prestrafe(client, Float: ang, &buttons)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || !(g_bOnGround[client]))
		return;

	decl bool: turning_right;
	turning_right = false;
	decl bool: turning_left;
	turning_left = false;

	if( ang < g_fLastAngles[client][1])
		turning_right = true;
	else
		if( ang > g_fLastAngles[client][1])
			turning_left = true;


	decl String:classname[64];
	decl MaxFrameCount;
	GetClientWeapon(client, classname, 64);
	decl Float: IncSpeed, Float: DecSpeed;
	decl Float:  speed;
	speed = GetSpeed(client);
	decl bool: bForward;

	//direction
	if (GetClientMovingDirection(client,false) > 0.0)
		bForward=true;
	else
		bForward=false;


	//no mouse movement?
	if (!turning_right && !turning_left)
	{
		decl Float: diff;
		diff = GetEngineTime() - g_fVelocityModifierLastChange[client]
		if (diff > 0.2)
		{
			if(StrEqual(classname, "weapon_hkp2000"))
				g_PrestrafeVelocity[client] = 1.042;
			else
				g_PrestrafeVelocity[client] = 1.0;
			g_fVelocityModifierLastChange[client] = GetEngineTime();
			SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", g_PrestrafeVelocity[client]);
		}
		return;
	}

	if ((g_bOnGround[client]) && ((buttons & IN_MOVERIGHT) || (buttons & IN_MOVELEFT)) && speed > 249.0)
	{
		//tickrate depending values
		MaxFrameCount = 75;
		IncSpeed = 0.0009;
		if ((g_PrestrafeVelocity[client] > 1.08 && StrEqual(classname, "weapon_hkp2000")) || (g_PrestrafeVelocity[client] > 1.04 && !StrEqual(classname, "weapon_hkp2000")))
			IncSpeed = 0.001;
		DecSpeed = 0.005;

		if (((buttons & IN_MOVERIGHT && turning_right || turning_left && !bForward)) || ((buttons & IN_MOVELEFT && turning_left || turning_right && !bForward)))
		{
			g_PrestrafeFrameCounter[client]++;
			//Add speed if Prestrafe frames are less than max frame count

			if (g_PrestrafeFrameCounter[client] < MaxFrameCount)
			{
				//increase speed
				g_PrestrafeVelocity[client]+= IncSpeed;

				//usp
				if(StrEqual(classname, "weapon_hkp2000"))
				{
					if (g_PrestrafeVelocity[client] > 1.15)
						g_PrestrafeVelocity[client]-=0.007;
				}
				else
					if (g_PrestrafeVelocity[client] > 1.104)
						g_PrestrafeVelocity[client]-=0.007;

				g_PrestrafeVelocity[client]+= IncSpeed;
			}
			else
			{
				//decrease speed
				g_PrestrafeVelocity[client]-= DecSpeed;

				//usp reset 250.0 speed
				if(StrEqual(classname, "weapon_hkp2000"))
				{
					if (g_PrestrafeVelocity[client]< 1.042)
					{
						g_PrestrafeFrameCounter[client] = 0;
						g_PrestrafeVelocity[client]= 1.042;
					}
				}
				else
					//knife reset 250.0 speed
					if (g_PrestrafeVelocity[client]< 1.0)
					{
						g_PrestrafeFrameCounter[client] = 0;
						g_PrestrafeVelocity[client]= 1.0;
					}
				g_PrestrafeFrameCounter[client] = g_PrestrafeFrameCounter[client] - 2;
			}
		}
		else
		{
			//no prestrafe
			g_PrestrafeVelocity[client] -= 0.04;
			if(StrEqual(classname, "weapon_hkp2000"))
			{
				if (g_PrestrafeVelocity[client]< 1.042)
					g_PrestrafeVelocity[client]= 1.042;
			}
			else
			if (g_PrestrafeVelocity[client]< 1.0)
				g_PrestrafeVelocity[client]= 1.0;
		}
	}
	else
	{
		if(StrEqual(classname, "weapon_hkp2000"))
			g_PrestrafeVelocity[client] = 1.042;
		else
			g_PrestrafeVelocity[client] = 1.0;
		g_PrestrafeFrameCounter[client] = 0;
	}

	//Set VelocityModifier
	SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", g_PrestrafeVelocity[client]);
	g_fVelocityModifierLastChange[client] = GetEngineTime();
}

public Float:GetSpeed(client)
{
	decl Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	new Float:speed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0));
	return speed;
}
stock Float:GetClientMovingDirection(client, bool:ladder)
{
	new Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);

	new Float:fEyeAngles[3];
	GetClientEyeAngles(client, fEyeAngles);

	if(fEyeAngles[0] > 70.0) fEyeAngles[0] = 70.0;
	if(fEyeAngles[0] < -70.0) fEyeAngles[0] = -70.0;

	new Float:fViewDirection[3];

	if (ladder)
		GetEntPropVector(client, Prop_Send, "m_vecLadderNormal", fViewDirection);
	else
		GetAngleVectors(fEyeAngles, fViewDirection, NULL_VECTOR, NULL_VECTOR);

	NormalizeVector(fVelocity, fVelocity);
	NormalizeVector(fViewDirection, fViewDirection);

	new Float:direction = GetVectorDotProduct(fVelocity, fViewDirection);
	if (ladder)
		direction = direction * -1;
	return direction;
}

stock bool IsValidClient(int client, bool bAlive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && (!bAlive || IsPlayerAlive(client)));
}
