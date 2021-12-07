#pragma semicolon 1
#pragma newdecls required

#include <sdktools>

static const char	PLUGIN_NAME[]		= "Values of the properties",
					PLUGIN_VERSION[]	= "1.0.0";

static const int	iBoxColor[]			= {255, 165, 0, 255};
static const float	fTime				= 1.0;

int iBeamSprite;

public Plugin myinfo = 
{
	name		= PLUGIN_NAME,
	author		= "Grey83",
	description	= "Shows/Changes the properties of entities",
	version		= PLUGIN_VERSION,
	url			= "http://steamcommunity.com/groups/grey83ds"
};

public void OnPluginStart()
{
	RegAdminCmd("val", Cmd_PlayerProperty, ADMFLAG_ROOT);
	RegAdminCmd("vale", Cmd_EntityProperty, ADMFLAG_ROOT);
}

public void OnMapStart()
{
	Handle gameConfig = LoadGameConfigFile("funcommands.games");
	if(gameConfig == null) return;
	char sBeam[PLATFORM_MAX_PATH];
	if(GameConfGetKeyValue(gameConfig, "SpriteBeam", sBeam, sizeof(sBeam)) && sBeam[0]) iBeamSprite = PrecacheModel(sBeam);
	CloseHandle(gameConfig);
}

public Action Cmd_PlayerProperty(int client, int args)
{
	if (!client) PrintToServer("[SM] Command is in-game only");
	else if(0 < client <= MaxClients && IsClientInGame(client))
	{
		if(args < 2) PrintToChat(client, "\x03[SM] \x04val <name> <type([d|s][i|f|b|s|h|v])> [<value>]");	// нужно добавить тип 'table'
		else
		{
			char name[32], type[3];
			PropType ptype;
			GetCmdArg(1, name, sizeof(name));
			GetCmdArg(2, type, sizeof(type));
			switch(type[0])
			{
				case 'd':	ptype = Prop_Data;
				case 's':	ptype = Prop_Send;
				default:
				{
					PrintToChat(client, "\x03[SM] Unknown property type \x04%s'", type);
					return Plugin_Handled;
				}
			}
			if(!HasEntProp(client, ptype, name))
			{
				PrintToChat(client, "\x03[SM] Property \x04%s '%s' \x03does not exist", type[0] == 'd' ? "Prop_Data" : "Prop_Send", name);
				return Plugin_Handled;
			}
			if(args > 2)
			{
				char value[3][32];
				GetCmdArg(3, value[0], sizeof(value[]));
				if(args > 3) GetCmdArg(4, value[1], sizeof(value[]));
				if(args > 4) GetCmdArg(5, value[2], sizeof(value[]));
				SetValue(client, client, name, ptype, type[1], value[0], value[1], value[2]);
			}
			else ShowValue(client, client, name, ptype, type[1]);
		}
	}
	return Plugin_Handled;
}

public Action Cmd_EntityProperty(int client, int args)
{
	if (!client) PrintToServer("[SM] Command is in-game only");
	else if(0 < client <= MaxClients && IsClientInGame(client))
	{
		if(args < 2) PrintToChat(client, "\x03[SM] \x04vale <name> <type([d|s][i|f|b|s|h|v])> [<value>]");	// нужно добавить тип 'table'
		else
		{
			char name[64], type[3];
			PropType ptype;
			GetCmdArg(1, name, sizeof(name));
			GetCmdArg(2, type, sizeof(type));
			switch(type[0])
			{
				case 'd':	ptype = Prop_Data;
				case 's':	ptype = Prop_Send;
				default:
				{
					PrintToChat(client, "\x03[SM] Unknown property type \x04%s'", type);
					return Plugin_Handled;
				}
			}
			int target = GetClientAimTarget(client, false);
			if(target < 0)
			{
				PrintToChat(client, "\x03[SM] No entity is being aimed!");
				return Plugin_Handled;
			}
			else
			{
				if(!IsValidEntity(target))
				{
					PrintToChat(client, "\x03[SM] Entity %i isn't valid!", target);
					return Plugin_Handled;
				}
				char class[64];
				GetEntityClassname(target, class, sizeof(class));
				PrintToChat(client, "\x03[SM] Entity '\x04%s\x03' (%i) is being aimed!", class, target);
				if(iBeamSprite) HighlightEntity(client, target);
			}
			if(!HasEntProp(target, ptype, name))
			{
				PrintToChat(client, "\x03[SM] Property \x04%s '%s' \x03does not exist", type[0] == 'd' ? "Prop_Data" : "Prop_Send", name);
				return Plugin_Handled;
			}
			if(args > 2)
			{
				char value[3][32];
				GetCmdArg(3, value[0], sizeof(value[]));
				if(args > 3) GetCmdArg(4, value[1], sizeof(value[]));
				if(args > 4) GetCmdArg(5, value[2], sizeof(value[]));
				SetValue(client, target, name, ptype, type[1], value[0], value[1], value[2]);
			}
			else ShowValue(client, target, name, ptype, type[1]);
		}
	}
	return Plugin_Handled;
}

stock void HighlightEntity(int client, int target)
{
		float origin[3], angles[3], min[3], max[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", origin);
		GetEntPropVector(target, Prop_Data, "m_angRotation", angles);
		GetEntPropVector(target, Prop_Data, "m_vecMins", min);
		GetEntPropVector(target, Prop_Data, "m_vecMaxs", max);
		Effect_DrawBeamBoxRotatable(client, origin, min, max, angles);
		Effect_DrawAxisOfRotation(client, origin, angles, max);
}

stock void Effect_DrawBeamBoxRotatable(int client, const float origin[3], const float mins[3], const float maxs[3], const float angles[3])
{
	// Create the additional corners of the box
	static float corners[8][3];
	static int i;
	for(i = 0; i < 3; i++) corners[0][i] = mins[i];

	for(i = 1; i < 6; i++)
	{
		corners[i][0] = maxs[0];
		corners[i][1] = mins[1];
		corners[i][2] = mins[2];
	}

	for(i = 0; i < 3; i++) corners[6][i] = maxs[i];

	corners[7][0] = mins[0];
	corners[7][1] = maxs[1];
	corners[7][2] = maxs[2];

	// Rotate all edges
	for(i = 0; i < sizeof(corners); i++) Math_RotateVector(corners[i], angles, corners[i]);

	// Apply world offset (after rotation)
	for(i = 0; i < sizeof(corners); i++) AddVectors(origin, corners[i], corners[i]);

	// Draw all the edges
	// Horizontal Lines
	// Bottom
	for(i = 0; i < 4; i++)
	{
		TE_SetupBeamPoints(corners[i], corners[i == 3 ? 0 : i+1], iBeamSprite, 0, 0, 0, fTime, 1.0, 1.0, 1, 0.0, iBoxColor, 0);
		TE_SendToClient(client);
	}

	// Top
	for(i = 4; i < 8; i++)
	{
		TE_SetupBeamPoints(corners[i], corners[i == 7 ? 4 : i+1], iBeamSprite, 0, 0, 0, fTime, 1.0, 1.0, 1, 0.0, iBoxColor, 0);
		TE_SendToClient(client);
	}

	// All Vertical Lines
	for(i = 0; i < 4; i++)
	{
		TE_SetupBeamPoints(corners[i], corners[i+4], iBeamSprite, 0, 0, 0, fTime, 1.0, 1.0, 1, 0.0, iBoxColor, 0);
		TE_SendToClient(client);
	}
}

stock void Effect_DrawAxisOfRotation(int client, const float origin[3], const float angles[3], const float length[3])
{
	float xAxis[3], yAxis[3], zAxis[3];
	xAxis[0] = length[0] + 5.0;
	yAxis[1] = length[1] + 5.0;
	zAxis[2] = length[2] + 5.0;

	Math_RotateVector(xAxis, angles, xAxis);
	Math_RotateVector(yAxis, angles, yAxis);
	Math_RotateVector(zAxis, angles, zAxis);

	AddVectors(origin, xAxis, xAxis);
	AddVectors(origin, yAxis, yAxis);
	AddVectors(origin, zAxis, zAxis);

	// X - Red
	TE_SetupBeamPoints(origin, xAxis, iBeamSprite, 0, 0, 0, fTime, 1.0, 1.0, 1, 0.0, {255, 0, 0, 255}, 0);
	TE_SendToClient(client);
	// Y - Green
	TE_SetupBeamPoints(origin, yAxis, iBeamSprite, 0, 0, 0, fTime, 1.0, 1.0, 1, 0.0, {0, 255, 0, 255}, 0);
	TE_SendToClient(client);
	// Z - Blue
	TE_SetupBeamPoints(origin, zAxis, iBeamSprite, 0, 0, 0, fTime, 1.0, 1.0, 1, 0.0, {0, 0, 255, 255}, 0);
	TE_SendToClient(client);
}

stock void Math_RotateVector(const float vec[3], const float angles[3], float result[3])
{
	// First the angle/radiant calculations
	float rad[3];
	// I don't really know why, but the alpha, beta, gamma order of the angles are messed up...
	// 2 = xAxis
	// 0 = yAxis
	// 1 = zAxis
	rad[0] = DegToRad(angles[2]);
	rad[1] = DegToRad(angles[0]);
	rad[2] = DegToRad(angles[1]);

	// Pre-calc function calls
	float cosAlpha = Cosine(rad[0]), sinAlpha = Sine(rad[0]), cosBeta = Cosine(rad[1]), sinBeta = Sine(rad[1]), cosGamma = Cosine(rad[2]), sinGamma = Sine(rad[2]);

	// 3D rotation matrix for more information: http://en.wikipedia.org/wiki/Rotation_matrix#In_three_dimensions
	float x = vec[0], y = vec[1], z = vec[2], newX, newY, newZ;
	newY = cosAlpha*y - sinAlpha*z;
	newZ = cosAlpha*z + sinAlpha*y;
	y = newY;
	z = newZ;

	newX = cosBeta*x + sinBeta*z;
	newZ = cosBeta*z - sinBeta*x;
	x = newX;
	z = newZ;

	newX = cosGamma*x - sinGamma*y;
	newY = cosGamma*y + sinGamma*x;
	x = newX;
	y = newY;

	// Store everything...
	result[0] = x;
	result[1] = y;
	result[2] = z;
}

stock void ShowValue(const int client, const int target, const char[] name, const PropType ptype, const int type)
{
	switch(type)
	{
		case 'b':	PrintToChat(client, "\x04%s \x01value is \x04%s", name, !GetEntProp(target, ptype, name) ? "false" : "true");
		case 'f':	PrintToChat(client, "\x04%s \x01value is \x04%.2f", name, GetEntPropFloat(target, ptype, name));
		case 'h':	PrintToChat(client, "\x04%s \x01value is \x04%i", name, GetEntPropEnt(target, ptype, name));
		case 'i':	PrintToChat(client, "\x04%s \x01value is \x04%i", name, GetEntProp(target, ptype, name));
		case 's':
		{
			char value[32];
			GetEntPropString(target, ptype, name, value, sizeof(value));
			PrintToChat(client, "\x04%s \x01value is \x04%ы", name, value);
		}
		case 'v':
		{
			float vec[3];
			GetEntPropVector(target, ptype, name, vec);
			PrintToChat(client, "\x04%s \x01values is \x04%.2f %.2f %.2f", name, vec[0], vec[1], vec[2]);
		}
		default:	PrintToChat(client, "\x03[SM] Unknown type value \x04%s", type);
	}
}

stock void SetValue(const int client, const int target, const char[] name, const PropType ptype, const int type, const char[] value1, const char[] value2, const char[] value3)
{
	switch(type)
	{
		case 'b':	SetEntProp(target, ptype, name, StringToInt(value1) == 0 ? 0 : 1);
		case 'f':	SetEntPropFloat(target, ptype, name, StringToFloat(value1));
		case 'h':	SetEntPropEnt(target, ptype, name, StringToInt(value1));
		case 'i':	SetEntProp(target, ptype, name, StringToInt(value1));
		case 's':	SetEntPropString(target, ptype, name, value1);
		case 'v':
		{
			float vec[3];
			vec[0] = StringToFloat(value1);
			if(value2[0]) vec[1] = StringToFloat(value2);
			if(value3[0]) vec[2] = StringToFloat(value3);
			SetEntPropVector(client, ptype, name, vec);
		}
		default:	PrintToChat(client, "\x03[SM] Unknown value type \x04%s", type);
	}
}