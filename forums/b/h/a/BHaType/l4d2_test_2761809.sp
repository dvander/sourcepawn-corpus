#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <left4dhooks>

int g_iTank;

/* These is real tank mins & maxs (GetClient Mins/Maxs)*/
static const float g_vMins[3] = { -16.000000, -16.000000, 0.000000 };
static const float g_vMaxs[3] = { 16.000000, 16.000000, 71.000000 };

public void OnPluginStart()
{
	RegConsoleCmd("sm_spawntank", sm_spawntank);
	RegConsoleCmd("sm_teleporttank", sm_teleport);
}

public Action sm_spawntank( int client, int args )
{
	float vSpawn[3], vAngles[3];
		
	if ( L4D_GetRandomPZSpawnPosition(client, 8, 5, vSpawn) )
	{
		g_iTank = L4D2_SpawnTank(vSpawn, vAngles);
	}
}	

public Action sm_teleport( int client, int args )
{
	if ( !g_iTank )
		return;
	
	static const float distance = 50.0; 		// preferred distance
	static const float min_distance = 40.0; 	// minimum valid distance between start and calculated position, actually useless without vischeck but still...
	static const bool recompute = true; 		// will use distance to recompute calculated position
	static const bool vischeck = false; 		// checks for visibility
	
	float vOrigin[3];
	
	if ( GetOriginAlongside(client, distance, min_distance, recompute, vischeck, vOrigin) )
	{
		PrintToChatAll("Teleported tank to %.1f %.1f %.1f", vOrigin[0], vOrigin[1], vOrigin[2]);
		TeleportEntity(g_iTank, vOrigin, NULL_VECTOR, NULL_VECTOR);
	}
	else
	{
		PrintToChatAll("Can't teleport");
	}
}

bool GetOriginAlongside( int client, const float distance, const float min_distance, bool recompute, bool vischeck, float out[3] )
{
	float vOrigin[3];
	GetClientAbsOrigin(client, vOrigin);
	
	Address area = view_as<Address>(L4D_GetNearestNavArea(vOrigin));
	
	if ( !area )
		return false;
	
	ArrayList areas = GetAdjacentAreas(area);
	
	if ( !areas.Length )
	{
		delete areas;
		return false;
	}
	
	float vAreaOrigin[3], vDir[3], vEnd[3];
	
	area = areas.Get(GetRandomInt(0, areas.Length - 1));
	
	GetClosestPointOnArea(area, vOrigin, vAreaOrigin); 
	vEnd = vAreaOrigin;
	
	if ( recompute )
	{
		MakeVectorFromPoints(vOrigin, vAreaOrigin, vDir);
		NormalizeVector(vDir, vDir);
		ScaleVector(vDir, distance);
		AddVectors(vOrigin, vDir, vEnd);
	}
	
	if ( vischeck )
	{
		TR_TraceRayFilter(vOrigin, vEnd, MASK_SHOT, RayType_EndPoint, __TraceFilter);
	
		if ( !TR_DidHit() )
			return false;
			
		TR_GetEndPosition(vEnd);
	}
	
	float mins[3], maxs[3];
	
	AddVectors(mins, g_vMins, mins); 
	AddVectors(maxs, g_vMaxs, maxs); 
	
	if ( !IsSpaceEmpty(vEnd, mins, maxs) )
		return false;
	
	out = vEnd;
	
	delete areas;
	return (GetVectorDistance(vOrigin, vEnd) >= min_distance);
}

public bool __TraceFilter( int entity, int mask )
{
	return ( !entity || entity > MaxClients );
}

ArrayList GetAdjacentAreas( Address area )
{
	ArrayList list = new ArrayList();
	int count;
	
	for (int i; i < 4; i++)
	{
		Address areas = LoadFromAddress(area + view_as<Address>(0x58 + 4 * i), NumberType_Int32);
		count = LoadFromAddress(areas, NumberType_Int32);
		
		for (int l; l < count; l++)
		{
			list.Push(LoadFromAddress(areas + view_as<Address>(l * 8 + 4), NumberType_Int32));
		}
	}
	
	return list;
}

void GetClosestPointOnArea( const Address area, const float vOrigin[3], float point[3] ) 
{
	float m_nwCorner[3], m_seCorner[3];
	GetCorners(area, m_nwCorner, m_seCorner);

	point[0] = fsel(vOrigin[0] - m_nwCorner[0], vOrigin[0], m_nwCorner[0]);
	point[0] = fsel(point[0] - m_seCorner[0], m_seCorner[0], point[0]);
	
	point[1] = fsel(vOrigin[1] - m_nwCorner[1], vOrigin[1], m_nwCorner[1]);
	point[1] = fsel(point[1] - m_seCorner[1], m_seCorner[1], point[1]);

	point[2] = GetZ(area, point[0], point[1]);
}

float GetZ( const Address area, float x, float y )
{
	float m_nwCorner[3], m_seCorner[3], m_invDxCorners, m_invDyCorners, m_neZ, m_swZ;
	
	GetCorners(area, m_nwCorner, m_seCorner);
	
	m_invDxCorners = view_as<float>(LoadFromAddress(area + view_as<Address>(28), NumberType_Int32));
	m_invDyCorners = view_as<float>(LoadFromAddress(area + view_as<Address>(32), NumberType_Int32));
	
	m_neZ = view_as<float>(LoadFromAddress(area + view_as<Address>(36), NumberType_Int32));
	m_swZ = view_as<float>(LoadFromAddress(area + view_as<Address>(40), NumberType_Int32));
	
	if ( m_invDxCorners == 0.0 || m_invDyCorners == 0.0 )
		return m_neZ;

	float u = (x - m_nwCorner[0]) * m_invDxCorners;
	float v = (y - m_nwCorner[1]) * m_invDyCorners;

	u = fsel( u, u, 0.0 );				// u >= 0 ? u : 0
	u = fsel( u - 1.0, 1.0, u );			// u >= 1 ? 1 : u

	v = fsel( v, v, 0.0 );				// v >= 0 ? v : 0
	v = fsel( v - 1.0, 1.0, v );			// v >= 1 ? 1 : v

	float northZ = m_nwCorner[2] + u * (m_neZ - m_nwCorner[2]);
	float southZ = m_swZ + u * (m_seCorner[2] - m_swZ);

	return northZ + v * (southZ - northZ);
}

stock void GetRandomAreaPoint( const Address area, float out[3] )
{
	float extent[2][3];
	GetAreaExtent(area, extent);

	out[0] = GetRandomFloat(extent[0][0], extent[1][0]); 
	out[1] = GetRandomFloat(extent[0][1], extent[1][1]);
	out[2] = GetZ(area, out[0], out[1]);
}

stock void GetAreaExtent( const Address area, float extent[2][3] )
{
	float m_nwCorner[3], m_seCorner[3], m_neZ, m_swZ;

	GetCorners(area, m_nwCorner, m_seCorner);
	
	m_neZ = view_as<float>(LoadFromAddress(area + view_as<Address>(36), NumberType_Int32));
	m_swZ = view_as<float>(LoadFromAddress(area + view_as<Address>(40), NumberType_Int32));
	
	extent[0] = m_nwCorner;
	extent[1] = m_seCorner;

	extent[0][2] = MIN( extent[0][2], m_nwCorner[2] );
	extent[0][2] = MIN( extent[0][2], m_seCorner[2] );
	extent[0][2] = MIN( extent[0][2], m_neZ );
	extent[0][2] = MIN( extent[0][2], m_swZ );

	extent[1][2] = MAX( extent[1][2], m_nwCorner[2] );
	extent[1][2] = MAX( extent[1][2], m_seCorner[2] );
	extent[1][2] = MAX( extent[1][2], m_neZ );
	extent[1][2] = MAX( extent[1][2], m_swZ );
}

void GetCorners( const Address area, float m_nwCorner[3], float m_seCorner[3] )
{
	m_nwCorner[0] = view_as<float>(LoadFromAddress(area + view_as<Address>(4), NumberType_Int32));
	m_nwCorner[1] = view_as<float>(LoadFromAddress(area + view_as<Address>(8), NumberType_Int32));
	m_nwCorner[2] = view_as<float>(LoadFromAddress(area + view_as<Address>(12), NumberType_Int32));
	
	m_seCorner[0] = view_as<float>(LoadFromAddress(area + view_as<Address>(16), NumberType_Int32));
	m_seCorner[1] = view_as<float>(LoadFromAddress(area + view_as<Address>(20), NumberType_Int32));
	m_seCorner[2] = view_as<float>(LoadFromAddress(area + view_as<Address>(24), NumberType_Int32));
}

bool IsSpaceEmpty( const float vOrigin[3], const float vMins[3], const float vMaxs[3] )
{
	float vHalf[3], vCenter[3];
	
	SubtractVectors(vMaxs, vMins, vHalf);
	ScaleVector(vHalf, 0.5);
	AddVectors(vMins, vHalf, vCenter);
	AddVectors(vCenter, vOrigin, vCenter);
	vCenter[2] += 5.0;
	
	float nVHalf[3];
	nVHalf = vHalf;
	NegateVector(nVHalf);
	
	TR_TraceHullFilter(vCenter, vCenter, nVHalf, vHalf, MASK_SOLID, __TraceFilter);
	
	bool bClear = ( TR_GetFraction() == 1 && TR_AllSolid() != true && (TR_StartSolid() != true) );
	return bClear;
}

stock float MIN( float left, float right )
{
	return ( left < right ? left : right );
}

stock float MAX( float left, float right )
{
	return ( left > right ? left : right );
}

float fsel( float c, float x, float y )
{
	return ( c >= 0.0 ? x : y );
}