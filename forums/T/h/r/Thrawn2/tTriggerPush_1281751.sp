#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"1.0"

new g_iLaserSprite;
new String:g_sPushModel[64] = "models/props_2fort/frog.mdl";

public Plugin:myinfo =
{
	name = "tTriggerPush",
	author = "Thrawn",
	description = "Provides zones, that pushes players out",
	version = PLUGIN_VERSION,
	url = "http://aaa.wallbash.com"
}

public OnPluginStart() {
	// Create ConVars
	CreateConVar("sm_ttriggerpush_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY);

	RegConsoleCmd("sm_push", Cmd_SpawnPush);
}

public OnMapStart() {
	PrecacheModel(g_sPushModel);
	g_iLaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public Action:Cmd_SpawnPush(iClient, iArgs) {
	new Float:min[3] = {-100.0, -100.0, 0.0};
	new Float:max[3] = {100.0, 100.0, 500.0};

	PlaceTriggerPush(iClient, min, max);
	CubeWithLasers(iClient, min, max);
}

stock CubeWithLasers(client, Float:min[3], Float:max[3]) {
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);

	new Float:aBase[3];
	GetClientEyeAngles(client, aBase);   // Direction client is looking.
	aBase[0] = 0.0;

	//Calculate Vectors
	// - The cross
	new Float:vFront[3];
	new Float:vRight[3];
	new Float:vBack[3];
	new Float:vLeft[3];
	GetAngleVectors(aBase, vFront, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vFront, 100.0);

	aBase[1] -= 90.0;
	GetAngleVectors(aBase, vRight, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vRight, 100.0);

	aBase[1] += 180.0;
	GetAngleVectors(aBase, vLeft, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vLeft, 100.0);

	aBase[1] += 90.0;
	GetAngleVectors(aBase, vBack, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vBack, 100.0);

	// - The corners
	new Float:vFrontRight[3];
	new Float:vFrontLeft[3];
	new Float:vBackRight[3];
	new Float:vBackLeft[3];
	AddVectors(vFront, vRight, vFrontRight);
	AddVectors(vFront, vLeft, vFrontLeft);
	AddVectors(vBack, vRight, vBackRight);
	AddVectors(vBack, vLeft, vBackLeft);

	//Calculate Points
	// - The cross
	new Float:pFront[3];
	new Float:pRight[3];
	new Float:pBack[3];
	new Float:pLeft[3];
	AddVectors(vFront, pos, pFront);
	AddVectors(vRight, pos, pRight);
	AddVectors(vBack, pos, pBack);
	AddVectors(vLeft, pos, pLeft);

	// - The corners
	new Float:pFrontRight[3];
	new Float:pFrontLeft[3];
	new Float:pBackRight[3];
	new Float:pBackLeft[3];
	AddVectors(vFrontRight, pos, pFrontRight);
	AddVectors(vFrontLeft, pos, pFrontLeft);
	AddVectors(vBackRight, pos, pBackRight);
	AddVectors(vBackLeft, pos, pBackLeft);

	//Drawing
	new bool:bDrawCross = false;
	if(bDrawCross) {
		DrawLineToClient(client, pos, pLeft);
		DrawLineToClient(client, pos, pRight);
		DrawLineToClient(client, pos, pFront);
		DrawLineToClient(client, pos, pBack);
		DrawLineToClient(client, pos, pFrontRight);
		DrawLineToClient(client, pos, pFrontLeft);
		DrawLineToClient(client, pos, pBackRight);
		DrawLineToClient(client, pos, pBackLeft);
	}

	DrawLineToClient(client, pFrontLeft, pFrontRight);
	DrawLineToClient(client, pBackLeft, pFrontLeft);
	DrawLineToClient(client, pFrontRight, pBackRight);
	DrawLineToClient(client, pBackRight, pBackLeft);
}


stock DrawLineToClient(client, Float:start[3], Float:end[3]) {
	new color[4] = {255, 0, 0, 255};

	TE_SetupBeamPoints(start, end, g_iLaserSprite, 0, 0, 0,	120.0,2.0, 2.0, 1, 0.0, color, 0);
	TE_SendToClient(client);
}

stock RotateVector(Float:vector[3], Float:rotation) {
	new Float:rVector[3];
	rVector = vector;
	rVector[0] = vector[0] * Cosine(rotation) - vector[1] * Sine(rotation);
	rVector[1] = vector[0] * Sine(rotation) + vector[1] * Cosine(rotation);
	vector = rVector;
}

stock PlaceTriggerPush(client, Float:minbounds[3], Float:maxbounds[3]) {
	new Float:playerpos[3];
	GetClientAbsOrigin(client, playerpos);

	new entindex = CreateEntityByName("trigger_push");
	if (entindex != -1)
	{
		DispatchKeyValue(entindex, "pushdir", "-90 0 0");
		DispatchKeyValue(entindex, "speed", "900");
		DispatchKeyValue(entindex, "spawnflags", "64");
	}

	DispatchSpawn(entindex);
	ActivateEntity(entindex);

	new Float:aBase[3];
	GetClientEyeAngles(client, aBase);   // Direction client is looking.
	aBase[0] = 0.0;

	SetEntityModel(entindex, g_sPushModel);

	//LogMessage("Your bounding min: {%.2f,%.2f,%.2f}", minbounds[0], minbounds[1], 0.0);
	//LogMessage("Your bounding max: {%.2f,%.2f,%.2f}", maxbounds[0], maxbounds[1], 200.0);

	RotateVector(minbounds, aBase[1]);
	RotateVector(maxbounds, aBase[1]);

	//LogMessage("Your bounding min: {%.2f,%.2f,%.2f}", minbounds[0], minbounds[1], 0.0);
	//LogMessage("Your bounding max: {%.2f,%.2f,%.2f}", maxbounds[0], maxbounds[1], 200.0);

	SetEntPropVector(entindex, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(entindex, Prop_Send, "m_vecMaxs", maxbounds);

	SetEntProp(entindex, Prop_Send, "m_nSolidType", 2);

	new enteffects = GetEntProp(entindex, Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(entindex, Prop_Send, "m_fEffects", enteffects);

	TeleportEntity(entindex, playerpos, aBase, NULL_VECTOR);
}

/*
stock CubeWithLasers3(client, Float:min[3], Float:max[3]) {
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);

	new Float:aBase[3];
	GetClientEyeAngles(client, aBase);   // Direction client is looking.
	aBase[0] = 0.0;

	//0 == X (width)
	//1 == Y (depth)
	//2 == Z (height)
	//min = front
	//max = back
	new Float:dFL = SquareRoot(Pow(min[0],2.0) + Pow(min[1],2.0));
	new Float:dFR = SquareRoot(Pow(min[0],2.0) + Pow(max[1],2.0));
	new Float:dBR = SquareRoot(Pow(max[0],2.0) + Pow(max[1],2.0));
	new Float:dBL = SquareRoot(Pow(max[0],2.0) + Pow(min[1],2.0));
	new Float:toTop[3];
	toTop[2] = FloatAbs(max[2]-min[2]);

	new Float:aBotFL[3];
	aBotFL = aBase;
	aBotFL[1] += 45.0;

	new Float:aBotFR[3];
	aBotFR = aBase;
	aBotFR[1] -= 45.0;

	new Float:aBotBL[3];
	aBotBL = aBase;
	aBotBL[1] += 135.0;

	new Float:aBotBR[3];
	aBotBR = aBase;
	aBotBR[1] -= 135.0;


	new Float:vBotFL[3];
	new Float:vBotFR[3];
	new Float:vBotBL[3];
	new Float:vBotBR[3];
	GetAngleVectors(aBotFR, vBotFR, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(aBotFL, vBotFL, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(aBotBR, vBotBR, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(aBotBL, vBotBL, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vBotFL, dFL);
	ScaleVector(vBotFR, dFR);
	ScaleVector(vBotBL, dBL);
	ScaleVector(vBotBR, dBR);

	new Float:BotFL[3];
	new Float:BotFR[3];
	new Float:BotBL[3];
	new Float:BotBR[3];
	AddVectors(vBotFR, pos, BotFR);
	AddVectors(vBotFL, pos, BotFL);
	AddVectors(vBotBR, pos, BotBR);
	AddVectors(vBotBL, pos, BotBL);



	new Float:TopFL[3];
	new Float:TopFR[3];
	new Float:TopBL[3];
	new Float:TopBR[3];
	AddVectors(BotFL, toTop, TopFL);
	AddVectors(BotFR, toTop, TopFR);
	AddVectors(BotBL, toTop, TopBL);
	AddVectors(BotBR, toTop, TopBR);


	new Float:tmp[3];
	tmp = BotFR;
	tmp[0] += 5.0;
	tmp[1] += 5.0;
	tmp[2] += 5.0;

	DrawLineToClient(client, BotFR, BotFL);
	DrawLineToClient(client, TopFR, TopFL);
	DrawLineToClient(client, TopFR, BotFR);
	DrawLineToClient(client, TopFL, BotFL);

	DrawLineToClient(client, BotBR, BotBL);
	DrawLineToClient(client, TopBR, TopBL);
	DrawLineToClient(client, TopBR, BotBR);
	DrawLineToClient(client, TopBL, BotBL);

	DrawLineToClient(client, BotBR, BotFR);
	DrawLineToClient(client, BotBL, BotFL);
	DrawLineToClient(client, TopBR, TopFR);
	DrawLineToClient(client, TopBL, TopFL);

}

*/


/*
	new Float:mina[3];
	mina[0] = FloatAbs(vFrontLeft[0]) * -1;
	mina[1] = FloatAbs(vBackRight[1]) * -1;
	mina[2] = 0.0;

	new Float:maxa[3];
	maxa[0] = FloatAbs(vBackRight[0]);
	maxa[1] = FloatAbs(vFrontLeft[1]);
	maxa[2] = 200.0;

	LogMessage("Your bounding min: {%.2f,%.2f,%.2f}", mina[0], mina[1], 0.0);
	LogMessage("Your bounding max: {%.2f,%.2f,%.2f}", maxa[0], maxa[1], 200.0);

*/