#pragma semicolon 1

#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <csgocolors>

public Plugin myinfo = {
	name = "Poly Zones",
	author = "Deathknife",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

/* ZONE STUFF */

#define MAXZONES 100
#define MAXPOINTS 100

//Zone Variables
float gZonePoints[MAXZONES][MAXPOINTS][3];	//Store points
int gZonePointsNum[MAXZONES];				//Store amount of points
float gZoneHeight[MAXZONES];				//The height of the zone
float gZoneMaxDistance[MAXZONES];			//Max distance - used to get ray outside of zone

//Helps in optimization as we can check if client is inside this 'box'.
float gZoneMin[MAXZONES][3];
float gZoneMax[MAXZONES][3];

//Amount of zones
int gZonesNum = 0;

//Client stuff
bool bInZone[MAXPLAYERS + 1][MAXZONES];
ArrayList alClientPoints[MAXPLAYERS + 1] = null;

int gBeamModel = 0;

public void OnPluginStart() {
	RegConsoleCmd("sm_startzone", Cmd_StartZone);
	RegConsoleCmd("sm_endzone", Cmd_EndZone);
	RegConsoleCmd("sm_deletelast", Cmd_DeleteLast);
	
	HookEvent("bullet_impact", Event_BulletImpact);
}

public void OnMapStart() {
	gBeamModel = PrecacheModel("materials/sprites/bluelaser1.vmt");
	AddFileToDownloadsTable("materials/sprites/bluelaser1.vmt");
	CreateTimer(0.1, CreateDevSprite, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(1.0, CreateMapSprite, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public void OnClientDisconnect(int client) {
	if(alClientPoints[client] != null) {
		delete alClientPoints[client];
	}
}

public Action Cmd_StartZone(int client, int argc) {
	if(alClientPoints[client] != null) {
		delete alClientPoints[client];
	}
	alClientPoints[client] = new ArrayList(3);
	ReplyToCommand(client, "Shoot to make points");
}

public Action Cmd_EndZone(int client, int argc) {
	if(alClientPoints[client] == null) {
		ReplyToCommand(client, "Not creating zone");
		return;
	}
	
	CreateZoneFromArray(alClientPoints[client], 256.0);
	
	delete alClientPoints[client];
	ReplyToCommand(client, "Created");
}

public Action Cmd_DeleteLast(int client, int argc) {
	if(alClientPoints[client] == null) {
		ReplyToCommand(client, "Not creating zone");
		return;
	}
	
	int size = alClientPoints[client].Length;
	if(size > 0) {
		ResizeArray(alClientPoints[client], size - 1);
	}
}

static int devcolor[4] =  { 34, 255, 25, 128 };
public Action CreateDevSprite(Handle timer) {
	//Loop through clients
	for (new x = 1; x <= MaxClients; x++)
	{
		if(IsValidClient(x) && alClientPoints[x] != null && alClientPoints[x].Length > 2) {
			for(int i = 0; i < alClientPoints[x].Length; i++) {
				float point[3];
				point[0] = alClientPoints[x].Get(i, 0);
				point[1] = alClientPoints[x].Get(i, 1);
				point[2] = alClientPoints[x].Get(i, 2);
				
				float nextpoint[3];
				int index = 0;
				if(i + 1 == alClientPoints[x].Length) {
					index = 0;
				}else {
					index = i + 1;
				}
				nextpoint[0] = alClientPoints[x].Get(index, 0);
				nextpoint[1] = alClientPoints[x].Get(index, 1);
				nextpoint[2] = alClientPoints[x].Get(index, 2);
				
				TE_SetupBeamPoints(
					point,
					nextpoint,
					gBeamModel,
					gBeamModel,
					10,
					10,
					1.1,
					6.0,
					6.0,
					0,
					0.0,
					devcolor,
					10
				);
				TE_SendToAll();
			}
		}
	}
}

stock bool IsValidClient(int client, bool bAlive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bAlive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}

public Action CreateMapSprite(Handle timer) {
	//Loop through zones
	float point[3];
	float nextpoint[3];
	for (new x = 0; x < gZonesNum; x++) {
		for(int i = 0; i < gZonePointsNum[x]; i++) {
			if(gZonePointsNum[x] == (i + 1)) {
				point = gZonePoints[x][i];
				nextpoint = gZonePoints[x][0];
				point[2] += 10.0;
				nextpoint[2] += 10.0;
			}else {
				point = gZonePoints[x][i];
				nextpoint = gZonePoints[x][i + 1];
				point[2] += 10.0;
				nextpoint[2] += 10.0;
			}
			TE_SetupBeamPoints(
				point,
				nextpoint,
				gBeamModel,
				gBeamModel,
				10,
				10,
				1.1,
				6.0,
				6.0,
				0,
				0.0,
				devcolor,
				10
			);
			TE_SendToAll();
			
			
			point[2] += gZoneHeight[x];
			nextpoint[2] += gZoneHeight[x];
			
			TE_SetupBeamPoints(
				point,
				nextpoint,
				gBeamModel,
				gBeamModel,
				10,
				10,
				1.1,
				6.0,
				6.0,
				0,
				0.0,
				devcolor,
				10
			);
			TE_SendToAll();
		}
	}
}

public Action Event_BulletImpact(Handle event,const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid")); //Attacker
	if(alClientPoints[client] == null) return Plugin_Continue;

	float pos[3];
	pos[0] = GetEventFloat(event, "x");
	pos[1] = GetEventFloat(event, "y");
	pos[2] = GetEventFloat(event, "z");
	
	int size = alClientPoints[client].Length;
	ResizeArray(alClientPoints[client], size+1);
	SetArrayCell(alClientPoints[client], size, pos[0], 0);
	SetArrayCell(alClientPoints[client], size, pos[1], 1);
	SetArrayCell(alClientPoints[client], size, pos[2], 2);

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3]) {
	if(!IsPlayerAlive(client)) return;
	
	float origin[3];
	GetClientAbsOrigin(client, origin);
	
	//Increasing origin height helps so we dont check floot lvl
	origin[2] += 42.5;
	
	float clientpoints[4][3];
	clientpoints[0] = origin;
	static float offset = 16.5;
	clientpoints[0][0] -= offset;
	clientpoints[0][1] -= offset;

	clientpoints[1] = origin;
	clientpoints[1][0] += offset;
	clientpoints[1][1] -= offset;

	clientpoints[2] = origin;
	clientpoints[2][0] -= offset;
	clientpoints[2][1] += offset;

	clientpoints[3] = origin;
	clientpoints[3][0] += offset;
	clientpoints[3][1] += offset;
	
	
	for(int zone = 0; zone < gZonesNum; zone++) {
		bool wasInZone = bInZone[client][zone];
		bInZone[client][zone] = false;
		for(int i = 0; i < 4; i++) {
			if(IsPointInZone(clientpoints[i], zone)) {
				bInZone[client][zone] = true;
				break;
			}
		}
		
		if(wasInZone && !bInZone[client][zone]) {
			PrintToChat(client, "Left zone %i", zone);
		}else if(!wasInZone && bInZone[client][zone]) {
			PrintToChat(client, "Enter zone %i", zone);
		}
	}
}

public void CreateZoneFromArray(ArrayList points, float height) {
	float greatdiff = 0.0;
	float tempMin[3];
	float tempMax[3];
	
	gZoneHeight[gZonesNum] = height;
	gZonePointsNum[gZonesNum] = 0;
	
	for(int i = 0; i < points.Length; i++) {
		gZonePoints[gZonesNum][i][0] = points.Get(i, 0);
		gZonePoints[gZonesNum][i][1] = points.Get(i, 1);
		gZonePoints[gZonesNum][i][2] = points.Get(i, 2);
		gZonePointsNum[gZonesNum]++;
		
		//Calculate min/max 
		for(int j=0 ; j < 3; j++) {
			if(tempMin[j] == 0.0 || tempMin[j] > gZonePoints[gZonesNum][i][j]) {
				tempMin[j] = gZonePoints[gZonesNum][i][j];
			}
			if(tempMax[j] == 0.0 || tempMax[j] < gZonePoints[gZonesNum][i][j]) {
				tempMax[j] = gZonePoints[gZonesNum][i][j];
			}
		}
		
		float diff = CalculateHorizontalDistance(gZonePoints[gZonesNum][0], gZonePoints[gZonesNum][i], false);
		if(diff > greatdiff) {
			greatdiff = diff;
		}
	}
	
	for(int y = 0; y < 3; y++) {
		gZoneMin[gZonesNum][y] = tempMin[y];
		gZoneMax[gZonesNum][y] = tempMax[y];
	}

	gZoneMaxDistance[gZonesNum] = greatdiff;
	gZonesNum++;
}

public bool IsPointInZone(float point[3], int zone) {
	//Check if point is in the zone
	if(!IsOriginInBox(point, zone)) return false;
	//Get a ray outside of the polygon
	float ray[3];
	ray = point;
	ray[1] += gZoneMaxDistance[zone] + 50.0;
	ray[2] = point[2];
	
	//Store the x and y intersections of where the ray hits the line
	float xint, yint;
	
	//Intersections for base bottom and top(2)
	float baseY, baseZ;
	float baseY2, baseZ2;
	
	//Calculate equation for x + y
	float eq[2];
	eq[0] = point[0] - ray[0];
	eq[1] = point[2] - ray[2];
	
	//This is for checking if the line intersected the base
	//The method is messy, came up with it myself, and might not work 100% of the time.
	//Should work though.
	
	//Bottom
	int lIntersected[64];
	float fIntersect[64][3];
	
	//Top
	int lIntersectedT[64];
	float fIntersectT[64][3];
	
	//Count amount of intersetcions
	int intersections = 0;
	
	//Count amount of intersection for BASE
	int lIntNum = 0;
	int lIntNumT = 0;
	
	//Get slope
	float lSlope = (ray[2] - point[2]) / (ray[1] - point[1]);
	float lEq = (lSlope & ray[0]) - ray[2];
	lEq = -lEq;
	
	//Get second slope
	//float lSlope2 = (ray[1] - point[1]) / (ray[0] - point[0]);
	//float lEq2 = (lSlope2 * point[0]) - point[1];
	//lEq2 = -lEq2;
	
	//Loop through every point of the zone
	for(int i = 0; i < gZonePointsNum[zone]; i++) {
		//Get current & next point
		float currentpoint[3];
		float nextpoint[3];
		
		//Check if its the last point, if it is, join it with the first
		if(gZonePointsNum[zone] == i + 1) {
			currentpoint = gZonePoints[zone][i];
			nextpoint = gZonePoints[zone][0];
		}else {
			currentpoint = gZonePoints[zone][i];
			nextpoint = gZonePoints[zone][i + 1];
		}
		
		//Check if the ray intersects the point
		//Ignore the height parameter as we will check against that later
		bool didinter = get_line_intersection(ray[0], ray[1], point[0], point[1], currentpoint[0], currentpoint[1], nextpoint[0], nextpoint[1], xint, yint);
		
		//Get intersections of the bottom
		bool baseInter = get_line_intersection(ray[1], ray[2], point[1], point[2], currentpoint[1], currentpoint[2], nextpoint[1], nextpoint[2], baseY, baseZ);
		
		//Get intersections of the top
		bool baseInter2 = get_line_intersection(ray[1], ray[2], point[1], point[2], currentpoint[1] + gZoneHeight[zone], currentpoint[2] + gZoneHeight[zone], nextpoint[1] + gZoneHeight[zone], nextpoint[2] + gZoneHeight[zone], baseY2, baseZ2);
		
		//If base intersected, store the line for later
		if(baseInter && lIntNum < sizeof(fIntersect)) {
			lIntersected[lIntNum] = i;
			fIntersect[lIntNum][1] = baseY;
			fIntersect[lIntNum][2] = baseZ;
			lIntNum++;
		}
		
		if(baseInter2 && lIntNumT < sizeof(fIntersectT)) {
			lIntersectedT[lIntNumT] = i;
			fIntersectT[lIntNumT][1] = baseY2;
			fIntersectT[lIntNum][2] = baseZ2;
			lIntNumT++;
		}
		
		//If ray intersected line, check against height
		if(didinter) {
			//Get the height of intersection
			
			//Get slope of line it hit
			float m1 = (nextpoint[2] - currentpoint[2]) / (nextpoint[0] - currentpoint[0]);
			
			//Equation y = mx + c | mx - y = -c
			float l1 = (m1 * currentpoint[0]) - currentpoint[2];
			l1 = -l1;
			
			float y2 = (m1 * xint) + l1;
			
			//Get slope of ray
			float y = (lSlope * xint) + lEq;
			
			if(y > y2 && y < y2 + 128.0 + gZoneHeight[zone]) {
				//The ray intersected the line and is within the height
				intersections++;
			}
		}
	}
	
	//Now we check for base hitting
	//This method is weird, but works most of the time
	for(int k = 0; k < lIntNum; k++) {
		for(int l = k + 1; l < lIntNum; l++) {
			if(l == k) continue;
			int i = lIntersected[k];
			int j = lIntersected[l];
			if(i == j) continue;
			
			float currentpoint[2][3];
			float nextpoint[2][3];
			
			if(gZonePointsNum[zone] == i + 1) {
				currentpoint[0] = gZonePoints[zone][i];
				nextpoint[0] = gZonePoints[zone][0];
			}else {
				currentpoint[0] = gZonePoints[zone][i];
				nextpoint[0] = gZonePoints[zone][i + 1];
			}
			
			if(gZonePointsNum[zone] == j + 1) {
				currentpoint[1] = gZonePoints[zone][j];
				nextpoint[1] = gZonePoints[zone][0];
			}else {
				currentpoint[1] = gZonePoints[zone][j];
				nextpoint[1] = gZonePoints[zone][j + 1];
			}
			
			//Get equation of both lines then find slope of them
			float m1 = (nextpoint[0][1] - currentpoint[0][1]) / (nextpoint[0][0] - currentpoint[0][0]);
			float m2 = (nextpoint[1][1] - currentpoint[1][1]) / (nextpoint[1][0] - currentpoint[1][0]);
			float lEq1 = (m1 * currentpoint[0][0]) - currentpoint[0][1];
			float lEq2 = (m2 * currentpoint[1][0]) - currentpoint[1][1];
			lEq1 = -lEq1;
			lEq2 = -lEq2;
			
			//Get x point of intersection
			float xPoint1 = ((fIntersect[k][1] - lEq1) / m1);
			float xPoint2 = ((fIntersect[l][1] - lEq2 / m2));
			
			if(xPoint1 > point[0] > xPoint2 || xPoint1 < point[0] < xPoint2) {
				intersections++;
			}
		}
	}
	for(int k = 0; k < lIntNumT; k++) {
		for(int l = k + 1; l < lIntNumT; l++) {
			if(l == k) continue;
			int i = lIntersectedT[k];
			int j = lIntersectedT[l];
			if(i == j) continue;
			
			float currentpoint[2][3];
			float nextpoint[2][3];
			
			if(gZonePointsNum[zone] == i + 1) {
				currentpoint[0] = gZonePoints[zone][i];
				nextpoint[0] = gZonePoints[zone][0];
			}else {
				currentpoint[0] = gZonePoints[zone][i];
				nextpoint[0] = gZonePoints[zone][i + 1];
			}
			
			if(gZonePointsNum[zone] == j + 1) {
				currentpoint[1] = gZonePoints[zone][j];
				nextpoint[1] = gZonePoints[zone][0];
			}else {
				currentpoint[1] = gZonePoints[zone][j];
				nextpoint[1] = gZonePoints[zone][j + 1];
			}
			
			//Get equation of both lines then find slope of them
			float m1 = (nextpoint[0][1] - currentpoint[0][1]) / (nextpoint[0][0] - currentpoint[0][0]);
			float m2 = (nextpoint[1][1] - currentpoint[1][1]) / (nextpoint[1][0] - currentpoint[1][0]);
			float lEq1 = (m1 * currentpoint[0][0]) - currentpoint[0][1];
			float lEq2 = (m2 * currentpoint[1][0]) - currentpoint[1][1];
			lEq1 = -lEq1;
			lEq2 = -lEq2;
			
			//Get x point of intersection
			float xPoint1 = ((fIntersectT[k][1] - lEq1) / m1);
			float xPoint2 = ((fIntersectT[l][1] - lEq2 / m2));
			
			if(xPoint1 > point[0] > xPoint2 || xPoint1 < point[0] < xPoint2) {
				intersections++;
			}
		}
	}
	if(intersections <= 0 || intersections % 2 == 0) {
		return false;
	}else {
		return true;
	}
}

//Stock that checks if point is inside zone's min and max
stock bool IsOriginInBox(float origin[3], int zone) {
	if(origin[0] >= gZoneMin[zone][0] && origin[1] >= gZoneMin[zone][1] && origin[2] >= gZoneMin[zone][2] && origin[0] <= gZoneMax[zone][0] + gZoneHeight[zone] && origin[1] <= gZoneMax[zone][1] + gZoneHeight[zone] && origin[2] <= gZoneMax[zone][2] + gZoneHeight[zone]) {
		return true;
	}
	return false;
}


//Stolen from stackoverflow
bool get_line_intersection(float p0_x, float p0_y, float p1_x, float p1_y, float p2_x, float p2_y, float p3_x, float p3_y, float &i_x, float &i_y) {
    float s1_x, s1_y, s2_x, s2_y;
    s1_x = p1_x - p0_x;     s1_y = p1_y - p0_y;
    s2_x = p3_x - p2_x;     s2_y = p3_y - p2_y;

    float s, t;
    s = (-s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) / (-s2_x * s1_y + s1_x * s2_y);
    t = ( s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) / (-s2_x * s1_y + s1_x * s2_y);

    if (s >= 0 && s <= 1 && t >= 0 && t <= 1) {
        // Collision detected
        i_x = p0_x + (t * s1_x);
        i_y = p0_y + (t * s1_y);
        return true;
    }

    return false; // No collision
}

stock float CalculateHorizontalDistance(float vec1[3], float vec2[3], bool squared = false) {
	if(squared) {
		if(vec1[0] < 0.0) vec1[0] *= -1;
		if(vec1[1] < 0.0) vec1[1] *= -1;
		vec1[0] = SquareRoot(vec1[0]);
		vec1[1] = SquareRoot(vec1[1]);

		if(vec2[0] < 0.0) vec2[0] *= -1;
		if(vec2[1] < 0.0) vec2[1] *= -1;
		vec2[0] = SquareRoot(vec2[0]);
		vec2[1] = SquareRoot(vec2[1]);
	}
	return SquareRoot( Pow((vec1[0] - vec2[0]), 2.0) +  Pow((vec1[1] - vec2[1]), 2.0) );
}