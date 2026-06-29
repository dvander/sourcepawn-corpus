/*
 * This is not a very practical plugin to use.
 * It was made to be used as an example for doing simmilar calculations.
 */
#pragma semicolon 1
#pragma newdecls required

#include <sdktools_engine>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

static const float RADIUS = 50.0;

int
	iBeam,
	iSprite,
	iColor[4];
float
	fClientPos[3],
	fTargetPos[3],
	fVec[3],
	fAng[3],
	fMin[3],
	fMax[3],
	fMult;

public Plugin myinfo =
{
	name		= "Simple Healthbar",
	version		= "1.0.1",
	description	= "Displays a healthbar on top of other players.",
	author		= "lugui",
	url			= "https://forums.alliedmods.net/showthread.php?t=330447"
}

public void OnMapStart()
{
	iBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	iSprite = PrecacheModel("sprites/redglow3.vmt");

	CreateTimer(0.1, Timer_Render, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Render(Handle timer)
{
	for(int client = 1, i; client < MaxClients; client++) if(isValidClient(client))
	{
		GetClientEyePosition(client, fClientPos);

		for(i = 1; i < MaxClients; i++) if(i != client && isValidClient(i, true) && IsPlayerAlive(i))
		{
			// Everyone will see everyone's bar, axept for its own.
			GetClientEyePosition(i, fTargetPos);
			fTargetPos[2] += 10.0;
			MakeVectorFromPoints(fTargetPos, fClientPos, fVec);
			GetVectorAngles(fVec, fAng);

			// To avoid getting the pointer instead of the actual value (IDK if that is right)

			// Left
			fAng[1] += 90.0;
			fMax = fTargetPos;
			fMax[0] += RADIUS * Cosine(DegToRad(fAng[1]));
			fMax[1] += RADIUS * Sine(DegToRad(fAng[1]));

			// Right Max
			fAng[1] -= 180.0;
			fMin = fTargetPos;
			fMin[0] += RADIUS * Cosine(DegToRad(fAng[1]));
			fMin[1] += RADIUS * Sine(DegToRad(fAng[1]));

			// Current
			fMult = GetClientHealth(i) / (GetEntProp(i, Prop_Data, "m_iMaxHealth") + 0.0);

			iColor[0] = RoundToCeil(255 * (1 - fMult));
			iColor[1] = RoundToCeil(255 * fMult);
			iColor[2] = 0;
			iColor[3] = 255;

			fTargetPos[0] = (fMult * (fMax[0] - fMin[0])) + fMin[0];
			fTargetPos[1] = (fMult * (fMax[1] - fMin[1])) + fMin[1];

			TE_SetupBeamPoints(fMin, fTargetPos, iBeam, 0, 0, 0, 0.1, 1.0, 1.0, 1, 0.0, iColor, 1000);
			TE_SendToClient(client);
			TE_SetupGlowSprite(fMin, iSprite, 0.1, 0.1, 128);
			TE_SendToClient(client);
			TE_SetupGlowSprite(fMax, iSprite, 0.1, 0.1, 128);
			TE_SendToClient(client);
		}
	}

	return Plugin_Continue;
}

stock bool isValidClient(int client, bool allowBot = false)
{
	return IsClientInGame(client) && (allowBot && !IsClientSourceTV(client) && !IsClientReplay(client) || !IsFakeClient(client));
}